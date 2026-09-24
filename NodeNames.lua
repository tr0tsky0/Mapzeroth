local addonName, addon = ...

-- Nodes carry no name in the data. A name is worked out here, in the client's
-- language, in this order:
--   1. an explicit locale string "NODE_<nodeID>" (names WE gave a node, or a
--      correction to what the client says);
--   2. flight masters (TAXI_<id>): the client's own taxi node name;
--   3. a kind pattern filled with client-localized zone names ("%s Harbor",
--      "<zone> / <zone> border");
--   4. the node id, as a last resort, so a gap is visible rather than blank.

local L = addon.L

local nameCache = {}
local taxiNames    -- nodeID -> client-supplied name, loaded on first use
local borderPartners
local taxiSettlements -- TAXI_ nodeID -> "city" or "town" key it belongs to

local function zoneName(mapID)
    local info = mapID and C_Map.GetMapInfo(mapID)
    return info and info.name
end

-- The client's name for a map (a zone, a city).
function addon:GetZoneName(mapID)
    return zoneName(mapID)
end

local function continentOf(mapID)
    local id = mapID
    while id and id ~= 0 do
        local info = C_Map.GetMapInfo(id)
        if not info then return nil end
        if info.mapType == Enum.UIMapType.Continent then return id end
        id = info.parentMapID
    end
end

-- The taxi API returns a continent's whole network in one call, so each
-- continent our flight-master nodes sit on is queried once.
local function loadTaxiNames()
    taxiNames = {}
    local queried = {}
    local function query(mapID)
        if not mapID or queried[mapID] then return end
        queried[mapID] = true
        local ok, entries = pcall(C_TaxiMap.GetTaxiNodesForMap, mapID)
        if ok and type(entries) == "table" then
            for _, entry in ipairs(entries) do
                if entry.nodeID and entry.name then
                    taxiNames[entry.nodeID] = entry.name
                end
            end
        end
    end
    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            if node.id:find("^TAXI_%d+$") then query(continentOf(node.mapID)) end
        end
    end
    -- What the continents didn't return: ask for the node's own map (some maps, like the Vaults of
    -- Atal'Utek, hang off no continent, or list their flight masters on their own).
    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            local id = node.id:match("^TAXI_(%d+)$")
            if id and not taxiNames[tonumber(id)] then query(node.mapID) end
        end
    end
end

local function taxiNameOf(nodeID)
    local id = nodeID and nodeID:match("^TAXI_(%d+)$")
    if not id then return nil end
    if not taxiNames then loadTaxiNames() end
    return taxiNames[tonumber(id)]
end

-- The city or town this flight master stands in, if any ("Walk to the Stormwind Flight Master"
-- is clearer than the client's own raw name for the point, "Stormwind, Elwynn").
local function taxiSettlementName(nodeID)
    if not taxiSettlements then
        taxiSettlements = {}
        for _, kind in ipairs({ "city", "town" }) do
            for key, settlement in pairs(addon[kind == "city" and "Cities" or "Towns"] or {}) do
                if settlement.taxi then
                    taxiSettlements[settlement.taxi] = { kind = kind, key = key }
                end
            end
        end
    end
    local settlement = taxiSettlements[nodeID]
    if not settlement then return nil end
    if settlement.kind == "city" then return addon:GetCityName(settlement.key) end
    return addon:GetTownName(settlement.key)
end

-- The name of a city or town, in the client's language. A settlement has no
-- name of its own in the data; it takes one from, in order: the client's name
-- for its area, the client's name for its flight master (minus the ", Zone"
-- suffix), or a locale string CITY_<KEY> / TOWN_<KEY>.
local function settlementName(settlements, key, stringPrefix)
    local settlement = settlements and settlements[key]
    if not settlement then return nil end

    if settlement.area and C_Map.GetAreaInfo then
        local name = C_Map.GetAreaInfo(settlement.area)
        if name then return name end
    end
    local taxiName = taxiNameOf(settlement.taxi)
    if taxiName then
        return (taxiName:gsub(",.*$", ""))
    end
    local stringKey = stringPrefix .. key:upper()
    if addon:HasString(stringKey) then
        return L[stringKey]
    end
end

function addon:GetTownName(key) return settlementName(addon.Towns, key, "TOWN_") end
function addon:GetCityName(key) return settlementName(addon.Cities, key, "CITY_") end

-- Tests only.
-- A spell's name and rank text ("Tailoring", "Journeyman"), in the client's language.
-- Rank text is loaded lazily: the first lookup can return a name with no rank, so this
-- asks the client to load the spell data and the caller should look again on
-- SPELL_DATA_LOAD_RESULT. That is why a rank spell showed its tier on the second try.
function addon:GetSpellLabel(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    local rank = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
    if rank == "" then rank = nil end
    if (not info or not rank) and C_Spell.RequestLoadSpellData then
        C_Spell.RequestLoadSpellData(spellID)
    end
    return info and info.name, rank
end

-- A skill spell's name (a weapon skill: "One-Handed Swords", "Staves"), in the client's language, or
-- nil until the client has loaded it.
function addon:GetSkillName(spellID)
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if info and info.name and info.name ~= "" then return info.name end
    if C_Spell and C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(spellID) end
end

-- What a trainer trains, in the client's language: a class name from the client,
-- or one of our own strings (weapons, riding).
local function trainerTypeName(token)
    if addon.CLASS_TOKENS[token] and LOCALIZED_CLASS_NAMES_MALE then
        return LOCALIZED_CLASS_NAMES_MALE[token]
    end
    -- A profession is named by the client's name for its first-rank spell.
    local professionSpell = addon.Professions and addon.Professions[token]
    if professionSpell then
        local info = C_Spell.GetSpellInfo(professionSpell)
        return info and info.name
    end
    local key = "TRAINER_" .. tostring(token)
    if addon:HasString(key) then return L[key] end
end

-- What a trainer of this type is called in the client's language ("Alchemy", "Mage").
function addon:GetTrainerTypeName(token) return trainerTypeName(token) end

-- The node on the other side of a border crossing.
local function borderPartner(nodeID)
    if not borderPartners then
        borderPartners = {}
        for _, edge in ipairs(addon.Edges or {}) do
            if edge.from:find("^BORDER_") and edge.to:find("^BORDER_") then
                borderPartners[edge.from] = edge.to
                borderPartners[edge.to] = edge.from
            end
        end
    end
    return borderPartners[nodeID]
end

local function resolve(nodeID)
    if nodeID:find("^WAYPOINT_") then return L["WAYPOINT_NAME"] end       -- the player's map waypoint
    local key = "NODE_" .. nodeID
    if addon:HasString(key) then
        return L[key]
    end

    local node = addon.World:GetNode(nodeID)
    if not node then return nil end

    -- A node inside a named area (Valanaar's skydocks) takes the client's name for it.
    if node.area and C_Map.GetAreaInfo then
        local name = C_Map.GetAreaInfo(node.area)
        if name then return name end
    end

    -- Places ("Goldshire Inn", "Stormwind Mage Trainer"): a kind pattern over the name
    -- of the city or town they belong to, or of their zone if they belong to neither.
    if node.kind then
        local where
        if node.city then
            where = addon:GetCityName(node.city)
        elseif node.town then
            where = addon:GetTownName(node.town)
        else
            where = zoneName(node.mapID)
        end
        local pattern = "NODE_KIND_" .. node.kind:upper()
        if not (where and addon:HasString(pattern)) then return nil end
        if node.kind == "trainer" then
            local what = trainerTypeName(node.trainer)
            return what and L[pattern]:format(where, what) or nil
        end
        return L[pattern]:format(where)
    end

    if nodeID:match("^TAXI_%d+$") then
        local place = taxiSettlementName(nodeID)
        local raw = taxiNameOf(nodeID)
        if not place and raw then place = (raw:gsub(",.*$", "")) end
        if place and place ~= "" and addon:HasString("NODE_KIND_FLIGHTMASTER") then
            return L["NODE_KIND_FLIGHTMASTER"]:format(place)
        end
        return raw
    end

    -- A dungeon or raid entrance, named from the client's own Dungeon Journal (Modern only
    -- so far: tools/match_modern_instance_nodes.py renamed it INSTANCE_<journalInstanceID>).
    local instanceID = addon:GetInstanceRef(nodeID)
    if instanceID and EJ_GetInstanceInfo then
        local name = EJ_GetInstanceInfo(instanceID)
        if name and name ~= "" then return name end
    end

    local kind = nodeID:match("^(%u+)_")
    if kind == "BORDER" then
        local partner = addon.World:GetNode(borderPartner(nodeID) or "")
        local here, there = zoneName(node.mapID), partner and zoneName(partner.mapID)
        if here and there then
            return L["NODE_KIND_BORDER"]:format(here, there)
        end
    elseif kind then
        local pattern = "NODE_KIND_" .. kind
        local zone = zoneName(node.mapID)
        if zone and addon:HasString(pattern) then
            return L[pattern]:format(zone)
        end
    end
end

-- Returns a display name for a node, in the client's language.
-- A portal we have no name for is described by where it leads: "Orgrimmar Portal", from the client's name for
-- the map on its far side. Only when it leads to one place: a portal room with several is not any one of them.
local portalDestinations
local function portalName(nodeID)
    if not portalDestinations then
        portalDestinations = {}
        for _, edge in ipairs(addon.Edges or {}) do
            if edge.method == "portal" then
                local from, to = addon.World:GetNode(edge.from), addon.World:GetNode(edge.to)
                if from and to and from.mapID ~= to.mapID then
                    local list = portalDestinations[edge.from] or {}
                    portalDestinations[edge.from] = list
                    list[to.mapID] = true
                end
            end
        end
    end
    local maps, only = portalDestinations[nodeID], nil
    for mapID in pairs(maps or {}) do
        if only then return nil end
        only = mapID
    end
    local zone = only and zoneName(only)
    return zone and addon:HasString("NODE_PORTAL_ZONE") and L["NODE_PORTAL_ZONE"]:format(zone) or nil
end

function addon:GetNodeName(nodeID)
    local cached = nameCache[nodeID]
    if cached then return cached end

    local name = resolve(nodeID)
    if not name then
        -- Nothing names this node: the client's name for its map says where it is (an arrival, or
        -- a teleport's destination, reads "The Arcantina"), which beats showing a raw id.
        local node = addon.World:GetNode(nodeID)
        name = portalName(nodeID) or (node and zoneName(node.mapID))
    end
    if name then
        nameCache[nodeID] = name
        return name
    end
    return nodeID
end

-- Does something name this node (as opposed to only its map standing in for a name)? A portal we
-- can name is described by that name; one we can't is described by where it comes out.
function addon:HasNodeName(nodeID)
    return resolve(nodeID) ~= nil
end

-- Forget resolved names, e.g. after a locale change or in tests.
function addon:ClearNodeNameCache()
    nameCache, taxiNames, borderPartners, taxiSettlements, portalDestinations = {}, nil, nil, nil, nil
end

-- The journal instance a dungeon or raid node stands for, and the faction that can use it (nil: either).
-- Hand-listed in Data/Modern/Places.lua (addon.InstanceNodeAliases: [nodeID] = journalInstanceID, or
-- { journalInstanceID, faction = "Alliance" }) for entrances whose node id doesn't say, and first, so a
-- node can be pointed at a different instance than its id names; else INSTANCE_<id> carries it.
function addon:GetInstanceRef(nodeID)
    local alias = addon.InstanceNodeAliases and addon.InstanceNodeAliases[nodeID]
    if type(alias) == "table" then return alias[1], alias.faction end
    if alias then return alias end
    local id = nodeID:match("^INSTANCE_(%d+)$")
    return id and tonumber(id) or nil
end
