-- NodeNames.lua
-- Gives every travel node the name the client itself uses for that place.
--
-- The travel data ships English node names ("Goldshire", "Stormwind
-- Flight Master", "Portal to Valdrakken"). On a non-English client those
-- read as a foreign language sitting next to zone names that ARE
-- translated, because MapNames.lua pulls those from C_Map.
--
-- Rather than maintain a thousand hand written translations per locale -
-- which would be guesswork and would go stale every patch - this asks
-- the client. Every node already carries a mapID and normalised x/y, and
-- the client publishes localised, positioned names for exactly the kind
-- of places the travel graph is made of:
--
--   * flight masters      C_TaxiMap.GetTaxiNodesForMap
--   * portals, POIs       C_AreaPoiInfo
--   * dungeons, cities    C_Map.GetMapInfoAtPosition
--
-- Whatever is left keeps its English name, and a locale can pin those
-- few by node ID in addon.NodeNameOverrides. On an English client the
-- result is the same wording as before.
--
-- This has to run after PLAYER_LOGIN: at ADDON_LOADED, when the travel
-- graph is built, none of those APIs answer reliably yet. So it rewrites
-- the graph's node copies in place, which is what every consumer reads.

local addonName, addon = ...
local L = addon.L

local NodeNames = {}

-- How close a client POI has to sit to a node before we call it the same
-- place, in normalised map units. 0.015 is roughly 1.5% of a map edge -
-- tight enough that two neighbouring flight masters never swap names,
-- loose enough to absorb the hand placed coordinates in the travel data.
local MATCH_TOLERANCE = 0.015
local TOLERANCE_SQUARED = MATCH_TOLERANCE * MATCH_TOLERANCE

-- Patterns in the shipped English names. The capture is the destination,
-- which is itself a node we can usually name, so "Portal to Valdrakken"
-- can be rebuilt in any language instead of translated.
local ENGLISH_PATTERNS = {
    { pattern = "^Portal to (.+)$",    key = "NODE_PORTAL_TO"     },
    { pattern = "^Teleport to (.+)$",  key = "NODE_TELEPORT_TO"   },
    { pattern = "^Zeppelin to (.+)$",  key = "NODE_ZEPPELIN_TO"   },
    { pattern = "^Ship to (.+)$",      key = "NODE_SHIP_TO"       },
    { pattern = "^Boat to (.+)$",      key = "NODE_BOAT_TO"       },
    { pattern = "^(.+) Flight Master$", key = "NODE_FLIGHT_MASTER" },
    { pattern = "^(.+) Mage$",         key = "NODE_MAGE"          },
}

local stats, unresolved

-----------------------------------------------------------
-- CLIENT LOOKUPS (cached per map, every call guarded)
-----------------------------------------------------------

local taxiCache, poiCache = {}, {}

local function GetTaxiNodes(mapID)
    if taxiCache[mapID] ~= nil then return taxiCache[mapID] end

    local ok, nodes = pcall(function()
        return C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap
               and C_TaxiMap.GetTaxiNodesForMap(mapID)
    end)

    taxiCache[mapID] = (ok and type(nodes) == "table" and nodes) or false
    return taxiCache[mapID]
end

-- Dungeon and raid entrances.
--
-- These are the single biggest group the other sources cannot name. An
-- instance node does NOT carry the instance's own mapID - it sits at the
-- entrance, out in the open zone - so looking up "the map this node is
-- on" yields the zone, and the Encounter Journal is the only place that
-- pairs a localised instance name with a position in that zone.
local entranceCache = {}

local function GetDungeonEntrances(mapID)
    if entranceCache[mapID] ~= nil then return entranceCache[mapID] end

    local ok, entrances = pcall(function()
        return C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap
               and C_EncounterJournal.GetDungeonEntrancesForMap(mapID)
    end)

    entranceCache[mapID] = (ok and type(entrances) == "table" and #entrances > 0 and entrances) or false
    return entranceCache[mapID]
end

-- Area POIs cover portals, town markers and dungeon entrances. The API
-- has changed shape more than once, so both known forms are accepted.
local function GetAreaPOIs(mapID)
    if poiCache[mapID] ~= nil then return poiCache[mapID] end

    local list = {}
    local ok = pcall(function()
        if not C_AreaPoiInfo then return end

        local ids = C_AreaPoiInfo.GetAreaPOIForMap and C_AreaPoiInfo.GetAreaPOIForMap(mapID)
        if type(ids) ~= "table" then return end

        for _, poiID in ipairs(ids) do
            local info = C_AreaPoiInfo.GetAreaPOIInfo and C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
            if info and info.name and info.position then
                list[#list + 1] = { name = info.name, position = info.position }
            end
        end
    end)

    poiCache[mapID] = (ok and #list > 0 and list) or false
    return poiCache[mapID]
end

-----------------------------------------------------------
-- POSITION MATCHING
-----------------------------------------------------------

local function DistanceSquared(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

-- Nearest entry of `list` to (x, y), or nil when nothing is close
-- enough. Entries expose `position` as a Vector2D-ish table.
local function NearestNamed(list, x, y, tolerance)
    if not list then return nil end

    local limit = (tolerance or MATCH_TOLERANCE) ^ 2
    local bestName, bestDistance

    for _, entry in ipairs(list) do
        local position = entry.position
        local px = position and (position.x or (position.GetXY and select(1, position:GetXY())))
        local py = position and (position.y or (position.GetXY and select(2, position:GetXY())))

        if px and py then
            local distance = DistanceSquared(x, y, px, py)
            if distance <= limit and (not bestDistance or distance < bestDistance) then
                bestName, bestDistance = entry.name, distance
            end
        end
    end

    return bestName
end

-- The node's OWN map, when that map is the place the node represents.
--
-- A dungeon node carries the dungeon's mapID, so the dungeon map already
-- holds its localised name - "Ara-Kara, City of Echoes" is right there in
-- C_Map. The trap is cities: half a dozen nodes share one city map, and
-- naming them all "Valdrakken" would be worse than English. So this only
-- fires for a dungeon, or when the node is the only one on its map.
local function OwnMapName(node, nodeCountByMap)
    local ok, info = pcall(function()
        return C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(node.mapID)
    end)
    if not ok or not info or not info.name then return nil end

    local kinds = Enum and Enum.UIMapType
    if not kinds then return nil end

    if info.mapType == kinds.Dungeon then
        return info.name
    end

    if (nodeCountByMap[node.mapID] or 0) == 1
       and (info.mapType == kinds.Micro or info.mapType == kinds.Zone) then
        return info.name
    end

    return nil
end

-- A node sitting on top of a dungeon or a city gets that place's name.
-- Restricted to those two map types on purpose: a plain zone map would
-- replace a precise node name ("Goldshire") with a vague one ("Elwynn
-- Forest"), which reads worse than leaving it in English.
local function MapNameAtPosition(mapID, x, y)
    local ok, info = pcall(function()
        return C_Map and C_Map.GetMapInfoAtPosition
               and C_Map.GetMapInfoAtPosition(mapID, x, y)
    end)

    if not ok or not info or not info.name or info.mapID == mapID then return nil end

    local kinds = Enum and Enum.UIMapType
    if not kinds then return nil end
    if info.mapType ~= kinds.Dungeon and info.mapType ~= kinds.Micro then return nil end

    return info.name
end

-----------------------------------------------------------
-- RESOLUTION
-----------------------------------------------------------

-- Pass one: anything the client can name from position alone. Ordered
-- most precise first, so a flight master keeps its own name instead of
-- being flattened into the name of the city it stands in.
local function ResolveFromClient(node, nodeCountByMap)
    local override = addon.NodeNameOverrides and addon.NodeNameOverrides[node.id]
    if override then return override, "override" end

    if not node.mapID then return nil end

    if node.x and node.y then
        local taxiName = NearestNamed(GetTaxiNodes(node.mapID), node.x, node.y)
        if taxiName then return taxiName, "taxi" end

        local entranceName = NearestNamed(GetDungeonEntrances(node.mapID), node.x, node.y)
        if entranceName then return entranceName, "entrance" end

        local poiName = NearestNamed(GetAreaPOIs(node.mapID), node.x, node.y)
        if poiName then return poiName, "poi" end

        local mapName = MapNameAtPosition(node.mapID, node.x, node.y)
        if mapName then return mapName, "map" end
    end

    local ownName = OwnMapName(node, nodeCountByMap)
    if ownName then return ownName, "ownmap" end

    return nil
end

-- Second chance for what nothing claimed at the tight tolerance.
--
-- The coordinates in the travel data are placed by hand and can sit a
-- fair way off the client's own marker - a flight master pin is a point,
-- the spot a player walks to is not. Widening only for nodes that are
-- still nameless keeps precise matches precise: by the time this runs,
-- every node that had a close match already took it.
local WIDE_TOLERANCE = 0.045

local function ResolveWidened(node)
    if node.localizedName then return nil end
    if not node.mapID or not node.x or not node.y then return nil end

    local taxiName = NearestNamed(GetTaxiNodes(node.mapID), node.x, node.y, WIDE_TOLERANCE)
    if taxiName then return taxiName, "taxi_wide" end

    local entranceName = NearestNamed(GetDungeonEntrances(node.mapID), node.x, node.y, WIDE_TOLERANCE)
    if entranceName then return entranceName, "entrance_wide" end

    return nil
end

-- What should "Portal to ..." be pointing at? The destination's MAP, not
-- the node we happen to land on. A node can resolve to something very
-- local - "Portal Room of Valdrakken" - and threading that through the
-- pattern produces "Portal to Portal Room of Valdrakken". The map name
-- is the place a player means when they say where a portal goes.
local function DestinationName(targetNode, localizedByID)
    if targetNode and targetNode.mapID then
        local ok, info = pcall(function()
            return C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(targetNode.mapID)
        end)
        if ok and info and info.name then
            return info.name
        end
    end

    return targetNode and localizedByID[targetNode.id] or nil
end

-- Pass two: names that are a sentence about another node. Runs after
-- pass one so the destination it points at is already localised.
local function ResolveFromPattern(node, localizedByID, nodesByID, edgesByFrom)
    if node.localizedName then return nil end
    if not node.name then return nil end

    for _, entry in ipairs(ENGLISH_PATTERNS) do
        if node.name:match(entry.pattern) then
            -- The destination this node leads to names it far more
            -- reliably than the English text does.
            local outgoing = edgesByFrom[node.id]
            local target = outgoing and nodesByID[outgoing]
            local destination = DestinationName(target, localizedByID)

            if destination then
                return string.format(L[entry.key], destination), "pattern"
            end
            return nil
        end
    end

    return nil
end

-----------------------------------------------------------
-- PUBLIC
-----------------------------------------------------------

function NodeNames:Resolve()
    if not addon.TravelGraph or not addon.TravelGraph.nodes then return end

    taxiCache, poiCache, entranceCache = {}, {}, {}
    stats = { override = 0, taxi = 0, entrance = 0, poi = 0, map = 0, ownmap = 0,
              taxi_wide = 0, entrance_wide = 0, pattern = 0, english = 0 }
    unresolved = {}

    -- Flatten once; the graph is a two level hierarchy.
    local allNodes, nodesByID, nodeCountByMap = {}, {}, {}
    for _, groupData in pairs(addon.TravelGraph.nodes) do
        for _, node in pairs(groupData) do
            allNodes[#allNodes + 1] = node
            if node.id then nodesByID[node.id] = node end
            if node.mapID then
                nodeCountByMap[node.mapID] = (nodeCountByMap[node.mapID] or 0) + 1
            end
        end
    end

    -- Pass one
    local localizedByID = {}
    for _, node in ipairs(allNodes) do
        local name, source = ResolveFromClient(node, nodeCountByMap)
        if name then
            node.localizedName = name
            localizedByID[node.id] = name
            stats[source] = stats[source] + 1
        end
    end

    -- Pass one and a half: retry the leftovers with a wider radius.
    for _, node in ipairs(allNodes) do
        local name, source = ResolveWidened(node)
        if name then
            node.localizedName = name
            localizedByID[node.id] = name
            stats[source] = stats[source] + 1
        end
    end

    -- Where does each node lead? Used to rebuild "Portal to X" names.
    local edgesByFrom = {}
    for _, edge in ipairs(addon.Edges or {}) do
        if edge.from and edge.to and not edgesByFrom[edge.from] then
            edgesByFrom[edge.from] = edge.to
        end
    end

    -- Pass two
    for _, node in ipairs(allNodes) do
        local name, source = ResolveFromPattern(node, localizedByID, nodesByID, edgesByFrom)
        if name then
            node.localizedName = name
            localizedByID[node.id] = name
            stats[source] = stats[source] + 1
        end
    end

    -- Commit: the localised name becomes the node's name, and the zone
    -- suffix is recomputed from it so both halves are the same language.
    local stillEnglish = {}

    for _, node in ipairs(allNodes) do
        if node.localizedName then
            node.name = node.localizedName
        else
            stats.english = stats.english + 1
            unresolved[#unresolved + 1] = string.format("%s (%s)", node.name or "?", node.id or "?")
            stillEnglish[#stillEnglish + 1] = {
                id = node.id, name = node.name, mapID = node.mapID,
                x = node.x, y = node.y,
            }
        end

        if addon.MapNames and addon.MapNames.BuildDisplayName then
            node.displayName = addon.MapNames:BuildDisplayName(node.name, node.mapID)
        else
            node.displayName = node.name
        end
    end

    -- Park the leftovers in the saved variables. The chat frame cannot be
    -- copied out of, and a few hundred names is not something anybody is
    -- going to retype - this way the list lands on disk at logout and can
    -- be turned into NodeNameOverrides entries.
    MapzerothDB = MapzerothDB or {}
    MapzerothDB.unresolvedNodeNames = stillEnglish
    MapzerothDB.nodeNameStats = { total = #allNodes, resolved = #allNodes - stats.english,
                                  bySource = stats, locale = GetLocale() }

    self.total = #allNodes
    return stats
end

-- /mapzeroth names
function NodeNames:Report()
    if not stats then
        print("[Mapzeroth] " .. L["NAMES_RERUN"])
        self:Resolve()
    end
    if not stats then return end

    local total = self.total or 0
    local fromClient = total - (stats.english or 0)

    print("[Mapzeroth] " .. L["NAMES_HEADER"])
    for _, source in ipairs({ "taxi", "entrance", "poi", "map", "ownmap",
                              "taxi_wide", "entrance_wide", "pattern", "override" }) do
        if (stats[source] or 0) > 0 then
            print(string.format(L["NAMES_LINE"], source, stats[source]))
        end
    end
    print(string.format("[Mapzeroth] " .. L["NAMES_TOTAL"],
        fromClient, total, total > 0 and math.floor(fromClient / total * 100) or 0))

    if #unresolved > 0 then
        local show = math.min(#unresolved, 25)
        print(string.format("[Mapzeroth] " .. L["NAMES_UNRESOLVED"], stats.english, show))
        for index = 1, show do
            print("    " .. unresolved[index])
        end
    end
end

function NodeNames:GetUnresolved()
    return unresolved or {}
end

-----------------------------------------------------------
-- WIRING
-----------------------------------------------------------

-- PLAYER_LOGIN is the earliest point where the taxi and POI APIs answer
-- for maps the player has not visited this session.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    NodeNames:Resolve()
    self:UnregisterEvent("PLAYER_LOGIN")
end)

addon.NodeNames = NodeNames
