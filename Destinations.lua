local addonName, addon = ...

-- The places a player can pick as a destination, with the name to show and search on.
-- Each entry is:
--   nodeID     the node to route to (the first of nodeIDs)
--   nodeIDs    every node that counts as arriving; the trip goes to whichever is cheapest
--   name       the client-language display name
--   zone       the zone's name (for the second line and for searching)
--   group      what sort of place: "place" (a city or town), "flight", "transport",
--              "instance", or a place kind ("inn", "bank", "trainer", "leyline", ...)
--   relevant   false for things this player has little use for by default (other classes'
--              trainers and the like); they are still found by searching
--   expansion  for a city, dungeon or raid whose data says (Modern's): its expansion (by major version, Classic 1 ...
--   raid       Modern instances: true for a raid, nil for a dungeon
--   details    optional, what a place offers that a search can hit and the list shows: for a
--              weapon master, { { text = "One-Handed Swords", alias = "..." }, ... } (the weapon skills
--              its trainers teach, in the client's names)
-- A city or town is an entry of its own (group "place"). A town routes to its centre node.
-- A city is enclosed, so it routes to whichever of its entrances is nearest, or to its
-- centre node until entrances have been captured for it.

local Destinations = {}
addon.Destinations = Destinations

local L = addon.L

-- Every weapon skill any class can learn: what a weapon master might teach.
local function weaponSkills()
    local set = {}
    for _, list in pairs(addon.ClassWeapons or {}) do
        for _, spellID in ipairs(list) do set[spellID] = true end
    end
    return set
end

-- The weapon skills the trainers at a weapon master teach, as search details, in skill order.
local function weaponDetails(node, skills)
    local taught = {}
    for _, npc in ipairs(node.npcs or {}) do
        for _, spellID in ipairs(npc.teaches or {}) do
            if skills[spellID] then taught[spellID] = true end
        end
    end
    local ids = {}
    for spellID in pairs(taught) do ids[#ids + 1] = spellID end
    table.sort(ids)
    local details = {}
    for _, spellID in ipairs(ids) do
        local name = addon:GetSkillName(spellID)
        if name then
            local alias = "SKILL_ALIAS_" .. spellID
            details[#details + 1] = { text = name, alias = addon:HasString(alias) and L[alias] or nil }
        end
    end
    return #details > 0 and details or nil
end

local TRANSPORT = { DOCK = true, ZEPPELIN = true, TRAM = true, PORTAL = true, TELEPORT = true }
local FLIGHT = { TAXI = true, FLIGHT = true }

-- What sort of destination a node is, or nil for one that isn't offered (border crossings
-- are plumbing between zones, not places).
local function groupOf(node)
    -- A settlement's centre and a city's entrances are how a place is arrived at, not
    -- destinations of their own: they are offered through the city or town's entry.
    if node.kind == "settlement" or node.kind == "entrance" then return nil end
    if node.kind then return node.kind end
    local kind = addon:NodeKindFromID(node.id)       -- <KIND>_<PLACE>, in both flavours
    if FLIGHT[kind] then return "flight" end
    if kind == "BORDER" then return nil end
    if kind == "INSTANCE" then return "instance" end
    if TRANSPORT[kind] then return "transport" end
    -- A spot inside a city or town with no kind of its own (where a teleport lands, a portal room) is part of the
    -- settlement, offered through the settlement's entry rather than listed again under its own name.
    if node.city or node.town then return nil end
    return "other"
end

-- The nodes that count as arriving at a settlement: a walled city's entrances (Forever: no flying, so a city is
-- entered through its gates), otherwise its centre node (CITY_<KEY> / TOWN_<KEY>). `entrances` is from entrancesByCity.
local function arrivalNodes(key, field, entrances)
    local centre = field:upper() .. "_" .. key:upper()
    if field == "city" and entrances[key] then return entrances[key] end
    if addon.World:GetNode(centre) then return { centre } end
end

-- city key -> { entrance node ids }, from every node of kind "entrance".
local function entrancesByCity()
    local byCity = {}
    addon.World:ForEachNode(function(node)
        if node.kind == "entrance" and node.city then
            byCity[node.city] = byCity[node.city] or {}
            table.insert(byCity[node.city], node.id)
        end
    end)
    for _, list in pairs(byCity) do table.sort(list) end
    return byCity
end

-- The client's name for an expansion by major version (Classic 1 ... Midnight 12), or "Expansion N" when it has none.
function addon:GetExpansionName(rev)
    return _G["EXPANSION_NAME" .. (rev - 1)] or L["SECTION_EXPANSION"]:format(rev)
end

-- The name of the continent a map is on, for telling two cities of one name apart when they carry no expansion.
local function continentName(mapID)
    local continent = addon:GetContinentMapID(mapID)
    local info = continent and C_Map.GetMapInfo(continent)
    return info and info.name
end

-- Builds the list for this player (ctx from addon:GetPlayerContext()), prepared for Search.
function Destinations:Build(ctx)
    local World = addon.World
    local entries = {}
    local skills = weaponSkills()
    local byInstance = {}                       -- journal instance id -> its entry

    World:ForEachNode(function(node)
        local group = groupOf(node)
        if not group then return end
        -- The other faction's flight masters can't be spoken to: not a place to go.
        if group == "flight" then
            local owner = addon:GetFlightOwner(node.id)
            if owner and ctx.faction and owner ~= ctx.faction then return end
        end
        local name = addon:GetNodeName(node.id)
        if not name or name == node.id then return end   -- no name yet: leave it out
        local instanceID, instanceFaction = nil, nil
        if group == "instance" then instanceID, instanceFaction = addon:GetInstanceRef(node.id) end
        -- An entrance only one faction can use isn't offered to the other; two entrances to one instance
        -- (a faction's each, or a rotating pair) are one destination, reached by whichever is cheaper.
        if instanceFaction and ctx.faction and instanceFaction ~= ctx.faction then return end
        local shared = instanceID and byInstance[instanceID]
        if shared then
            table.insert(shared.nodeIDs, node.id)
            return
        end
        local instance = instanceID and addon.Instances and addon.Instances[instanceID]
        entries[#entries + 1] = {
            instanceID = instanceID, expansion = instance and instance[1], raid = instance and instance[2] or nil,
            nodeID = node.id, nodeIDs = { node.id }, name = name, group = group, kind = node.kind,
            zone = addon:GetZoneName(node.mapID),
            relevant = addon.Relevance:IsRelevant(node, ctx),
            details = node.kind == "trainer" and node.trainer == "WEAPON" and weaponDetails(node, skills) or nil,
            trainer = node.trainer,
        }
        if instanceID then byInstance[instanceID] = entries[#entries] end
    end)

    -- Whose a place is: its faction's, or both's (or nobody's on record). The other faction's are still
    -- found by searching, but aren't listed by default.
    local function ours(settlement)
        return settlement.faction == nil or settlement.faction == "Both" or ctx.faction == nil or settlement.faction == ctx.faction
    end

    -- Two settlements the client gives the same name (Modern's two Dalarans, the Burning Crusade and the Midnight
    -- Silvermoon) are told apart by their expansion ("Silvermoon City (Midnight)"), or by their continent when the data
    -- gives no expansion.
    local entrances, made, names = entrancesByCity(), {}, {}
    local function addSettlements(list, getName, field, label)
        for key, settlement in pairs(list or {}) do
            local name = getName(addon, key)
            local nodeIDs = name and arrivalNodes(key, field, entrances)
            if nodeIDs then
                made[#made + 1] = {
                    nodeID = nodeIDs[1], nodeIDs = nodeIDs, name = name, group = "place", kind = label,
                    zone = addon:GetZoneName(settlement.mapID), relevant = ours(settlement), faction = settlement.faction,
                    expansion = settlement.expansion, hub = settlement.hub, mapID = settlement.mapID,
                }
                names[name] = (names[name] or 0) + 1
            end
        end
    end
    addSettlements(addon.Cities, addon.GetCityName, "city", "city")
    addSettlements(addon.Towns, addon.GetTownName, "town", "town")
    for _, entry in ipairs(made) do
        if names[entry.name] > 1 then
            local which = entry.expansion and addon:GetExpansionName(entry.expansion) or continentName(entry.mapID)
            if which then entry.name = entry.name .. " (" .. which .. ")" end
        end
        entry.mapID = nil
        entries[#entries + 1] = entry
    end

    table.sort(entries, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.nodeID < b.nodeID
    end)
    return addon.Search:Prepare(entries)
end

-- Tests only.
-- The entry for a node, or nil. A city and its flight master share a node, so a group
-- ("place", "flight", ...) can say which is meant.
function Destinations:Find(entries, nodeID, group)
    for _, entry in ipairs(entries) do
        if entry.nodeID == nodeID and (not group or entry.group == group) then return entry end
    end
end
