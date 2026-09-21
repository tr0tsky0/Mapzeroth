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
local fareFactor        -- what the player pays as a fraction of the base fares, typically, once seen
local originFactors = {}    -- the same for tickets bought at one flight master: "TAXI_<id>" -> factor

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
    fareFactor, originFactors = nil, {}
end

-- What the player pays for a ticket as a fraction of the game's base fares. It is probably a
-- reputation discount, which depends on the flight master's faction, so it is learned per departure
-- point (nodeID) from that flight master's window; a place not seen yet gets the highest seen (the
-- least discount, to stay on the safe side), and 1 (no discount) until any window has shown us a price.
function FlightKnowledge:FareFactor(nodeID)
    return (nodeID and originFactors[nodeID]) or fareFactor or 1
end


local legFares       -- "TAXI_a|TAXI_b" -> base fare in copper, from the flight edges

local function baseFare(from, stops)
    if not legFares then
        legFares = {}
        for _, edge in ipairs(addon.Edges or {}) do
            if edge.method == "flight" and edge.fare then legFares[edge.from .. "|" .. edge.to] = edge.fare end
        end
    end
    local total, at = 0, from
    for _, id in ipairs(stops) do
        local fare = legFares[at .. "|" .. id]
        if not fare then return nil end
        total, at = total + fare, id
    end
    return total
end

-- The client's price for each reachable destination, next to what our fares add up to for that route,
-- gives the player's discount. entries: { { nodeID, state, slotIndex }, ... } as for Record. The prices
-- read, { { to = nodeID, paid = copper, base = copper }, ... }, go to FlightKnowledge.onFares(from, samples)
-- if a tool has set one (MapzerothDataTools does); nothing is kept or shown here.
function FlightKnowledge:LearnFares(entries)
    local current, reachable = states()
    local from
    for _, entry in ipairs(entries) do
        if entry.nodeID and entry.state == current then from = "TAXI_" .. entry.nodeID end
    end
    if not (from and TaxiNodeCost) then return end
    local ratios = {}
    local samples = {}
    for _, entry in ipairs(entries) do
        if entry.state == reachable and entry.slotIndex then
            local ok, cost = pcall(TaxiNodeCost, entry.slotIndex)
            local stops = ok and cost and cost > 0 and self:StopsForSlot(entry.slotIndex)
            local base = stops and baseFare(from, stops)
            if base and base > 0 then
                ratios[#ratios + 1] = cost / base
                samples[#samples + 1] = { to = stops[#stops], paid = cost, base = base }
            end
        end
    end
    if self.onFares then self.onFares(from, samples) end
    if #ratios == 0 then return end
    table.sort(ratios)
    originFactors[from] = ratios[math.ceil(#ratios / 2)]
    -- For places whose flight master we haven't seen: the highest seen, that is the smallest discount,
    -- so an unseen flight master is never assumed cheaper than it may be (a route the player can't pay
    -- for must not be offered).
    fareFactor = nil
    for _, factor in pairs(originFactors) do
        if fareFactor == nil or factor > fareFactor then fareFactor = factor end
    end
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

-- The flight points a chosen flight lands at, in order, the last being where it ends, as node ids: the
-- game's own route for the slot the player clicked (the same GetNumRoutes / TaxiGetNodeSlot reading as
-- /mzroutes). Nil when it can't be read.
function FlightKnowledge:StopsForSlot(slot)
    local mapID = taxiMapID()
    local nodes = mapID and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and C_TaxiMap.GetAllTaxiNodes(mapID)
    if not (nodes and slot) then return nil end
    local bySlot = {}
    for _, node in ipairs(nodes) do
        if node.slotIndex and node.nodeID then bySlot[node.slotIndex] = "TAXI_" .. node.nodeID end
    end
    local stops = {}
    local okHops, hops = pcall(GetNumRoutes, slot)
    if okHops and type(hops) == "number" then
        for hop = 1, hops do
            local okSlot, landing = pcall(TaxiGetNodeSlot, slot, hop, false)
            local id = okSlot and bySlot[landing]
            if not id then return nil end
            stops[#stops + 1] = id
        end
    end
    if #stops == 0 and bySlot[slot] then stops[1] = bySlot[slot] end
    return #stops > 0 and stops or nil
end

-- Call when the flight map opens.
function FlightKnowledge:OnTaxiMapOpened(ctx)
    local mapID = taxiMapID()
    local nodes = mapID and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and C_TaxiMap.GetAllTaxiNodes(mapID)
    if not nodes then return end
    local entries = {}
    for _, node in ipairs(nodes) do
        entries[#entries + 1] = { nodeID = node.nodeID, state = node.state, slotIndex = node.slotIndex }
    end
    local yes, no = self:Record(entries, ctx or addon:GetPlayerContext())
    self:LearnFares(entries)
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
    MapzerothRebuildDB.fareFactors = MapzerothRebuildDB.fareFactors or {}
    local origins = {}
    for id, factor in pairs(originFactors) do origins[id] = factor end
    MapzerothRebuildDB.fareFactors[characterKey()] = { typical = fareFactor, origins = origins }
end

function FlightKnowledge:Load()
    local saved = MapzerothRebuildDB and MapzerothRebuildDB.flights and MapzerothRebuildDB.flights[characterKey()]
    found = {}
    for id, value in pairs(saved or {}) do found[id] = value end
    local factors = MapzerothRebuildDB and MapzerothRebuildDB.fareFactors and MapzerothRebuildDB.fareFactors[characterKey()]
    fareFactor, originFactors = factors and factors.typical or nil, {}
    for id, factor in pairs(factors and factors.origins or {}) do originFactors[id] = factor end
end
