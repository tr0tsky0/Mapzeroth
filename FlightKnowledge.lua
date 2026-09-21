local addonName, addon = ...

-- Which flight points this character has found. You can only fly to a point you have
-- found, and the client only says so while a flight master's window is open: then every
-- point on the continent comes back Current (where you are), Reachable (found, and you
-- can get there from here) or Unreachable (anything else, found or not).
--
-- The client has two answers per point: Reachable means you can fly there from here (one
-- leg or several: Menethil comes back Reachable from Stormwind, by way of Ironforge), and
-- Unreachable means it isn't found, or isn't linked to where you are. We can only be sure
-- it's the first of those when a found point has a flight edge to it, so, one window at a
-- time, per point:
--   true   found (it was Current or Reachable at some window)
--   false  not found: it came back Unreachable although one of our flight edges joins it
--          to a found point. Had it been found, that edge would have made it Reachable.
--   nil    unknown: nothing has told us yet.
-- Routing only flies into a point that is known found, so a route never promises a flight
-- that can't be taken; until the player has opened a flight master's window once, that
-- means no flights at all. Confirmed on the Forever beta with a character that had found
-- four points.

local FlightKnowledge = {}
addon.FlightKnowledge = FlightKnowledge

local found = {}    -- "TAXI_<id>" -> true | false

-- Enum.FlightPathState on the beta: Current = 0, Reachable = 1, Unreachable = 2.
local function states()
    local enum = Enum and Enum.FlightPathState or {}
    return enum.Current or 0, enum.Reachable or 1, enum.Unreachable or 2
end

function FlightKnowledge:IsFound(nodeID)
    return found[nodeID]
end

function FlightKnowledge:Reset()
    found = {}
end

-- The points in `wanted` (a set) that some flight edge this player could take joins to a
-- point in `via` (a set), in the direction via -> wanted.
local function flightsFrom(via, wanted, ctx)
    local hit = {}
    for _, edge in ipairs(addon.Edges or {}) do
        if edge.method == "flight" and addon:MeetsRequirements(edge.requirements, ctx) then
            if via[edge.from] and wanted[edge.to] then hit[edge.to] = true end
            if not edge.oneway and via[edge.to] and wanted[edge.from] then hit[edge.from] = true end
        end
    end
    return hit
end

-- entries: { { nodeID = 6, state = 1 }, ... } as the client reports them for one open
-- flight map. Returns how many points are now known found and not found.
function FlightKnowledge:Record(entries, ctx)
    local current, reachable, unreachable = states()
    local usable, unusable = {}, {}       -- found this window / came back Unreachable
    for _, entry in ipairs(entries) do
        if entry.nodeID then
            local id = "TAXI_" .. entry.nodeID
            if entry.state == current or entry.state == reachable then
                found[id] = true
                usable[id] = true
            elseif entry.state == unreachable then
                unusable[id] = true
            end
        end
    end
    -- Something found earlier stays found: a mismatch then means our edge is wrong.
    for id in pairs(flightsFrom(usable, unusable, ctx)) do
        if found[id] ~= true then found[id] = false end
    end
    local yes, no = 0, 0
    for _, value in pairs(found) do
        if value then yes = yes + 1 else no = no + 1 end
    end
    return yes, no
end

-- A new flight path was learned but not which one, so drop every "not found".
function FlightKnowledge:ForgetNotFound()
    for id, value in pairs(found) do
        if value == false then found[id] = nil end
    end
end

-- The map the open flight window is showing: its own id if the client has one, else the
-- continent above the player.
local function taxiMapID()
    if GetTaxiMapID then
        local id = GetTaxiMapID()
        if id then return id end
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    while mapID do
        local info = C_Map.GetMapInfo(mapID)
        if not info then return nil end
        if info.mapType == 2 then return mapID end     -- Enum.UIMapType.Continent
        mapID = info.parentMapID
    end
end

-- Call when the flight map opens.
function FlightKnowledge:OnTaxiMapOpened(ctx)
    local mapID = taxiMapID()
    local nodes = mapID and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and C_TaxiMap.GetAllTaxiNodes(mapID)
    if not nodes then return end
    local entries = {}
    for _, node in ipairs(nodes) do
        entries[#entries + 1] = { nodeID = node.nodeID, state = node.state }
    end
    local yes, no = self:Record(entries, ctx or addon:GetPlayerContext())
    self:Save()
    return yes, no
end

-- SavedVariables, per character. (They are wiped on reload on the Forever beta at
-- the moment, so for now this only lasts a session.)
local function characterKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "")
end

function FlightKnowledge:Save()
    MapzerothRebuildDB = MapzerothRebuildDB or {}
    MapzerothRebuildDB.flights = MapzerothRebuildDB.flights or {}
    local copy = {}
    for id, value in pairs(found) do copy[id] = value end
    MapzerothRebuildDB.flights[characterKey()] = copy
end

function FlightKnowledge:Load()
    local saved = MapzerothRebuildDB and MapzerothRebuildDB.flights and MapzerothRebuildDB.flights[characterKey()]
    found = {}
    for id, value in pairs(saved or {}) do found[id] = value end
end

-- For /mzr flights: found and not-found ids, sorted.
function FlightKnowledge:List()
    local yes, no = {}, {}
    for id, value in pairs(found) do
        table.insert(value and yes or no, id)
    end
    table.sort(yes)
    table.sort(no)
    return yes, no
end
