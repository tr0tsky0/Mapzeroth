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
-- A city or town is an entry of its own (group "place"). A town routes to its centre node.
-- A city is enclosed, so it routes to whichever of its entrances is nearest, or to its
-- centre node until entrances have been captured for it.

local Destinations = {}
addon.Destinations = Destinations

local TRANSPORT = { DOCK = true, ZEPPELIN = true, TRAM = true, PORTAL = true, TELEPORT = true }

-- What sort of destination a node is, or nil for one that isn't offered (border crossings
-- are plumbing between zones, not places).
local function groupOf(node)
    -- A settlement's centre and a city's entrances are how a place is arrived at, not
    -- destinations of their own: they are offered through the city or town's entry.
    if node.kind == "settlement" or node.kind == "entrance" then return nil end
    if node.kind then return node.kind end
    local prefix = node.id:match("^(%u+)_")
    if prefix == "TAXI" then return "flight" end
    if prefix == "BORDER" then return nil end
    if TRANSPORT[prefix] then return "transport" end
    return "other"
end

-- The nodes that count as arriving at a settlement.
local function arrivalNodes(key, field)
    local centre = field:upper() .. "_" .. key:upper()
    if field == "city" then
        local entrances = {}
        for _, node in ipairs(addon.Nodes and addon.Nodes.Pois or {}) do
            if node.kind == "entrance" and node.city == key then entrances[#entrances + 1] = node.id end
        end
        if #entrances > 0 then return entrances end
    end
    if addon.World:GetNode(centre) then return { centre } end
end

-- Builds the list for this player (ctx from addon:GetPlayerContext()), prepared for Search.
function Destinations:Build(ctx)
    local World = addon.World
    local entries = {}

    World:ForEachNode(function(node)
        local group = groupOf(node)
        if not group then return end
        local name = addon:GetNodeName(node.id)
        if not name or name == node.id then return end   -- no name yet: leave it out
        entries[#entries + 1] = {
            nodeID = node.id, nodeIDs = { node.id }, name = name, group = group, kind = node.kind,
            zone = addon:GetZoneName(node.mapID),
            relevant = addon.Relevance:IsRelevant(node, ctx),
        }
    end)

    local function addSettlements(list, getName, field, label)
        for key, settlement in pairs(list or {}) do
            local name = getName(addon, key)
            local nodeIDs = name and arrivalNodes(key, field)
            if nodeIDs then
                entries[#entries + 1] = {
                    nodeID = nodeIDs[1], nodeIDs = nodeIDs, name = name, group = "place", kind = label,
                    zone = addon:GetZoneName(settlement.mapID), relevant = true,
                }
            end
        end
    end
    addSettlements(addon.Cities, addon.GetCityName, "city", "city")
    addSettlements(addon.Towns, addon.GetTownName, "town", "town")

    table.sort(entries, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.nodeID < b.nodeID
    end)
    return addon.Search:Prepare(entries)
end

-- The entry for a node, or nil. A city and its flight master share a node, so a group
-- ("place", "flight", ...) can say which is meant.
function Destinations:Find(entries, nodeID, group)
    for _, entry in ipairs(entries) do
        if entry.nodeID == nodeID and (not group or entry.group == group) then return entry end
    end
end
