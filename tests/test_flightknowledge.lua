-- What the client reported at Stormwind's flight master on the Forever beta, for a
-- character that had found only Stormwind, Sentinel Hill, Ironforge and Menethil Harbor
-- (Enum.FlightPathState: Current 0, Reachable 1, Unreachable 2). Node ids are ours.
useTestDistances()
addon.World:Build()

local CURRENT, REACHABLE, UNREACHABLE = 0, 1, 2
local capture = {
    { nodeID = 2, state = CURRENT },                        -- Stormwind
    { nodeID = 4, state = REACHABLE },                      -- Sentinel Hill
    { nodeID = 6, state = REACHABLE },                      -- Ironforge
    { nodeID = 7, state = REACHABLE },                      -- Menethil Harbor
    { nodeID = 5, state = UNREACHABLE },                    -- Lakeshire
    { nodeID = 8, state = UNREACHABLE },                    -- Thelsamar
    { nodeID = 12, state = UNREACHABLE },                   -- Darkshire (Sentinel Hill, Ironforge and Menethil fly there)
    { nodeID = 14, state = UNREACHABLE },                   -- Southshore
    { nodeID = 16, state = UNREACHABLE },                   -- Refuge Pointe
    { nodeID = 19, state = UNREACHABLE },                   -- Booty Bay
    { nodeID = 43, state = UNREACHABLE },                   -- Aerie Peak
    { nodeID = 45, state = UNREACHABLE },                   -- Nethergarde Keep
    { nodeID = 66, state = UNREACHABLE },                   -- Chillwind Camp
    { nodeID = 67, state = UNREACHABLE },                   -- Light's Hope Chapel
    { nodeID = 71, state = UNREACHABLE },                   -- Morgan's Vigil
    { nodeID = 74, state = UNREACHABLE },                   -- Thorium Point
}

local FK = addon.FlightKnowledge
local ali = makeCtx({ faction = "Alliance" })

FK:Reset()
check(FK:IsFound("TAXI_6") == nil, "nothing is known before a flight map opens")
FK:Record(capture, ali)

-- Reachable and current points are found.
for _, id in ipairs({ "TAXI_2", "TAXI_4", "TAXI_6", "TAXI_7" }) do
    check(FK:IsFound(id) == true, id .. " is found")
end
-- Points a found point has a flight leg to, that came back Unreachable, are not found: had one been
-- found, that leg would have made it Reachable. Every one of these has a leg from Stormwind, Ironforge
-- or Menethil Harbor.
for _, id in ipairs({ "TAXI_5", "TAXI_8", "TAXI_12", "TAXI_14", "TAXI_16", "TAXI_19", "TAXI_43", "TAXI_45",
                      "TAXI_66", "TAXI_67", "TAXI_71", "TAXI_74" }) do
    check(FK:IsFound(id) == false, id .. " is not found")
end
-- Aerie Peak and Chillwind Camp have no leg from Sentinel Hill (they are reached through Ironforge or
-- Southshore), so from there nothing says either way.
FK:Reset()
FK:Record({ { nodeID = 4, state = CURRENT }, { nodeID = 43, state = UNREACHABLE }, { nodeID = 66, state = UNREACHABLE } }, ali)
check(FK:IsFound("TAXI_43") == nil and FK:IsFound("TAXI_66") == nil, "points with no leg from a found point stay unknown")
FK:Reset()
FK:Record(capture, ali)
-- A point nothing found flies to is left unknown (here, an Orgrimmar entry on the wrong continent).
local mixed = { { nodeID = 2, state = CURRENT }, { nodeID = 23, state = UNREACHABLE } }
FK:Record(mixed, ali)
check(FK:IsFound("TAXI_23") == nil, "a point no found point flies to stays unknown")

-- Horde edges don't count for an Alliance player, so a Horde-only neighbour isn't judged.
FK:Reset()
FK:Record({ { nodeID = 23, state = CURRENT }, { nodeID = 22, state = UNREACHABLE } }, makeCtx({ faction = "Horde" }))
check(FK:IsFound("TAXI_22") == false, "Thunder Bluff is a direct Horde flight from Orgrimmar, and not found")
FK:Reset()
FK:Record({ { nodeID = 23, state = CURRENT }, { nodeID = 22, state = UNREACHABLE } }, ali)
check(FK:IsFound("TAXI_22") == nil, "an Alliance player has no such flight, so nothing is learned about it")

-- Routing only flies into points known to be found. Unknown is not enough.
FK:Reset()
local withKnowledge = makeCtx({ faction = "Alliance" })
withKnowledge.flightNodeFound = function(id) return FK:IsFound(id) end

local function flights(result)
    local n = 0
    for _, step in ipairs(result.steps) do if step.method == "flight" then n = n + 1 end end
    return n
end
local nothingYet = route(withKnowledge, "TAXI_2", "TAXI_6")
check(nothingYet and flights(nothingYet) == 0, "before any flight map has been read, routes use no flights")

FK:Record(capture, ali)

local function flownInto(result, nodeID)
    for _, step in ipairs(result.steps) do
        if step.method == "flight" and step.to == nodeID then return true end
    end
    return false
end
local without = route(ali, "TAXI_2", "TAXI_8")
check(without and flownInto(without, "TAXI_8"), "with no knowledge the route flies to Thelsamar")
local knowing = route(withKnowledge, "TAXI_2", "TAXI_8")
check(knowing and not flownInto(knowing, "TAXI_8"), "knowing Thelsamar isn't found, the route doesn't fly to it")
check(knowing.cost > without.cost, "and it takes longer")

local toIronforge = route(withKnowledge, "TAXI_2", "TAXI_6")
check(toIronforge and methods(toIronforge) == "flight", "Ironforge is found, so it is still a single flight")
local toDarkshire = route(withKnowledge, "TAXI_2", "TAXI_12")
check(toDarkshire and not flownInto(toDarkshire, "TAXI_12"), "Darkshire isn't found: reached on foot, or by flying to Sentinel Hill first")
check(flights(toDarkshire) == 0 or flownInto(toDarkshire, "TAXI_4"), "the only flight it may use is one into a found point")

-- A continent the flight map hasn't been read for stays unusable (the capture was Eastern Kingdoms).
local horde = makeCtx({ faction = "Horde" })
horde.flightNodeFound = function(id) return FK:IsFound(id) end
local orgToTB = route(horde, "TAXI_23", "TAXI_22")
check(orgToTB and not flownInto(orgToTB, "TAXI_22"), "Thunder Bluff is unknown, so no flight into it")

-- The far end of a flight must be found too: Thelsamar -> Stormwind is a valid flight
-- to a found point, but the player can't be standing at Thelsamar's flight master
-- without having found it, so that direction is left alone.
local fromThelsamar = route(withKnowledge, "TAXI_8", "TAXI_2")
check(fromThelsamar and flownInto(fromThelsamar, "TAXI_2"), "flying out of an unfound point into a found one is allowed")

-- Found beats not found, and a new flight path clears the not-founds.
FK:Record({ { nodeID = 8, state = CURRENT }, { nodeID = 2, state = REACHABLE } }, ali)
check(FK:IsFound("TAXI_8") == true, "standing at Thelsamar's flight master marks it found")
FK:ForgetNotFound()
check(FK:IsFound("TAXI_19") == nil and FK:IsFound("TAXI_8") == true, "a new flight path forgets the not-founds, not the founds")

-- Reading it from the client, as the flight map opens.
FK:Reset()
UnitName = function() return "Tester" end
GetRealmName = function() return "Realm" end
GetTaxiMapID = function() return 1415 end
C_TaxiMap = C_TaxiMap or {}
C_TaxiMap.GetAllTaxiNodes = function(mapID)
    check(mapID == 1415, "asks about the flight map's own map")
    return capture
end
FK:OnTaxiMapOpened(ali)
check(FK:IsFound("TAXI_7") == true and FK:IsFound("TAXI_8") == false, "OnTaxiMapOpened records what the client reports")
GetTaxiMapID = nil

-- Saved per character and loaded back.
check(MapzerothRebuildDB.flights["Tester-Realm"]["TAXI_7"] == true, "saved under the character")
FK:Reset()
check(FK:IsFound("TAXI_7") == nil, "reset forgets")
FK:Load()
check(FK:IsFound("TAXI_7") == true and FK:IsFound("TAXI_8") == false, "load restores it")
