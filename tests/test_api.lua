-- The public API (API.lua): MapzerothAPI.RouteTo checks another addon's points and hands them to the panel, which
-- plans a tour through them and starts it only when asked to.

check(MapzerothAPI and MapzerothAPI.version == 2, "MapzerothAPI is global, version 2")

local calls = {}
local Panel = addon.Panel
local realRoute = Panel.RouteToPoints
Panel.RouteToPoints = function(_, name, points, start, onArrive)
    calls[#calls + 1] = { name = name, points = points, start = start, onArrive = onArrive }
end

local ok, why = MapzerothAPI.RouteTo(nil)
check(not ok and why == "no points", "nothing given: no points")
ok, why = MapzerothAPI.RouteTo({})
check(not ok and why == "no points", "an empty list: no points")
ok, why = MapzerothAPI.RouteTo({ { mapID = 1453, x = 0.4, y = 0.3 }, { mapID = 1453, x = 45, y = 30 } })
check(not ok and why == "bad point 2", "coordinates past 1 (0-100 by mistake): " .. tostring(why))
local many = {}
for i = 1, MapzerothAPI.MAX_POINTS + 1 do many[i] = { mapID = 1453, x = 0.5, y = 0.5 } end
ok, why = MapzerothAPI.RouteTo(many)
check(not ok and why == "too many points", "more than MAX_POINTS: refused before planning")
ok, why = MapzerothAPI.RouteTo({ { x = 0.4, y = 0.3 } })
check(not ok and why == "bad point 1", "no map: bad point")
check(#calls == 0, "nothing reaches the panel when a point is bad")

ok = MapzerothAPI.RouteTo({ mapID = 1453, x = 0.4, y = 0.3, name = "Copper Vein" })
check(ok and #calls == 1, "a single point is routed")
check(calls[1].name == "Copper Vein" and #calls[1].points == 1 and not calls[1].start, "named for its point, waits for Start")

ok = MapzerothAPI.RouteTo({ { mapID = 1453, x = 0.4, y = 0.3 }, { mapID = 1455, x = 0.5, y = 0.5 } }, "Ore run", { start = true })
check(ok and calls[2].name == "Ore run" and #calls[2].points == 2 and calls[2].start, "a list, its name and start")
MapzerothAPI.RouteTo({ { mapID = 1453, x = 0.4, y = 0.3 }, { mapID = 1455, x = 0.5, y = 0.5 } })
check(calls[3].name == addon.L["TOUR_STOPS"]:format(2), "unnamed list: \"2 stops\"")
MapzerothAPI.RouteTo({ mapID = 1453, x = 0.4, y = 0.3 }, "Test")
check(calls[4].points[1].name == "Test", "an unnamed single point's stop takes the route's name")

-- The panel side: the window comes up, the tour's entry is shown, and the trip starts only with start.
Panel.RouteToPoints = realRoute
local shown, started, toggled
local realToggle, realShow, realStart = Panel.Toggle, Panel.ShowRoute, Panel.StartRoute
local MR, realEntry = addon.MultiRoute, addon.MultiRoute.Entry
MR.Entry = function(_, name, points) return { name = name, points = points, stops = {} } end
Panel.Toggle = function() toggled = true end
Panel.ShowRoute = function(_, entry, onReady) shown = entry; if onReady then onReady({ steps = { 1 } }) end end
Panel.StartRoute = function() started = true end
Panel:RouteToPoints("Ore run", { { mapID = 1453, x = 0.4, y = 0.3 } }, false)
check(toggled and shown and shown.name == "Ore run" and shown.points, "the window comes up with the tour")
check(not started, "without start the route waits")
Panel:RouteToPoints("Ore run", { { mapID = 1453, x = 0.4, y = 0.3 } }, true)
check(started, "with start the trip starts once planned")
Panel.Toggle, Panel.ShowRoute, Panel.StartRoute = realToggle, realShow, realStart
MR.Entry = realEntry

-- onArrive: handed through to the panel, which puts it on the trip's entry.
local function arrive() end
Panel.RouteToPoints = function(_, name, points, start, onArrive)
    calls[#calls + 1] = { name = name, points = points, start = start, onArrive = onArrive }
end
MapzerothAPI.RouteTo({ mapID = 1453, x = 0.4, y = 0.3 }, "Test", { onArrive = arrive })
check(calls[5].onArrive == arrive, "onArrive reaches the panel")
MapzerothAPI.RouteTo({ mapID = 1453, x = 0.4, y = 0.3 }, "Test", { onArrive = "not a function" })
check(calls[6].onArrive == nil, "an onArrive that isn't a function is dropped")
Panel.RouteToPoints = realRoute
MR.Entry = function(_, name, points) return { name = name, points = points, stops = {} } end
Panel.Toggle, Panel.ShowRoute = function() end, function(_, entry) shown = entry end
Panel:RouteToPoints("Ore run", { { mapID = 1453, x = 0.4, y = 0.3 } }, false, arrive)
check(shown.onArrive == arrive, "and the trip's entry carries it")
Panel.Toggle, Panel.ShowRoute = realToggle, realShow
MR.Entry = realEntry

-- TimeTo: seconds from the player to each point, by the planner's quickest route.
useTestDistances()
addon.World:Build()
local maps = {
    [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 },
    [1455] = { name = "Ironforge", mapType = 3, parentMapID = 1415 },
    [1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
C_Map = { GetMapInfo = function(id) return maps[id] end, GetWorldPosFromMapPos = function() return nil end }
Enum = { UIMapType = { Continent = 2 } }
CreateVector2D = function(x, y) return { x = x, y = y, GetXY = function() return x, y end } end
C_TaxiMap = { GetTaxiNodesForMap = function() return {} end }
C_Spell = { GetSpellInfo = function(id) return { name = "Spell " .. id } end }
addon:ClearNodeNameCache()

local ctx = makeCtx({ faction = "Alliance" })
local here = { id = "YOU_api", mapID = 1453, x = 0.60, y = 0.60 }
addon.GetPlayerStart = function() return here end
addon.GetPlayerContext = function() return ctx end

local near, far, nowhere = { mapID = 1453, x = 0.40, y = 0.30 }, { mapID = 1455, x = 0.5, y = 0.5 }, { mapID = 99999, x = 0.5, y = 0.5 }
local times = MapzerothAPI.TimeTo({ near, far, nowhere })
check(type(times) == "table" and times[1] and times[1] > 0, "a point in the same city has a time: " .. tostring(times and times[1]))
check(times[2] and times[2] > times[1], "another city takes longer: " .. tostring(times[2]))
check(times[3] == nil, "a map we have no data for: nil")
check(MapzerothAPI.TimeTo(near) == times[1], "a single point gives a number, the same one")
check(select(2, MapzerothAPI.TimeTo({ far, far })) == nil and MapzerothAPI.TimeTo({ far, far })[2] == times[2], "a point given twice is timed twice")

-- The search that stops once the points are priced agrees with the one over the whole map.
local place = addon:PlaceAt(far.mapID, far.x, far.y, "API")
local session = addon.Journey:Build(ctx, here, { place })
check(addon.Journey:Cost(session, place.id) == times[2], "the same time as a full search: " .. tostring(addon.Journey:Cost(session, place.id)))

local t, why = MapzerothAPI.TimeTo({ { mapID = 1453, x = 40, y = 30 } })
check(t == nil and why == "bad point 1", "bad points are refused as for RouteTo")
t, why = MapzerothAPI.TimeTo(nil)
check(t == nil and why == "no points", "nothing given: no points")
addon.GetPlayerStart = function() return nil, "no position" end
t, why = MapzerothAPI.TimeTo(near)
check(t == nil and why == "no position", "nowhere to start from (an instance): no position")
addon.GetPlayerStart = function() return here end

-- onArrive is called once, when the trip's last step is done, and an error in it doesn't stop the trip ending.
local N = addon.Navigation
local stop = addon:PlaceAt(near.mapID, near.x, near.y, "STOP")
local arrived = 0
local entry = { name = "Vein", dest = stop, nodeIDs = { stop.id }, onArrive = function() arrived = arrived + 1 end }
local plan = addon.Journey:PlanEntry(addon.Journey:Build(ctx, here, { stop }), entry)
check(plan, "a plan to the point")
N:Start(entry, plan)
N:Update({ mapID = 1453, x = 0.60, y = 0.60, now = 0 })
check(arrived == 0, "not called on the way")
local m = N:Update({ mapID = 1453, x = stop.x + 0.001, y = stop.y, now = 5 })
check(m.finished and arrived == 1, "called on arriving")
N:Update({ mapID = 1453, x = stop.x, y = stop.y, now = 6 })
check(arrived == 1, "and only once")
N:Stop()

local reported
geterrorhandler = function() return function(err) reported = err end end
entry = { name = "Vein", dest = stop, nodeIDs = { stop.id }, onArrive = function() error("theirs") end }
N:Start(entry, plan)
N:Update({ mapID = 1453, x = 0.60, y = 0.60, now = 0 })
m = N:Update({ mapID = 1453, x = stop.x + 0.001, y = stop.y, now = 5 })
check(m.finished and reported and tostring(reported):find("theirs"), "an error in it is reported and the trip still ends")
N:Stop()

entry = { name = "Vein", dest = stop, nodeIDs = { stop.id }, onArrive = function() arrived = arrived + 1 end }
N:Start(entry, plan)
N:Update({ mapID = 1453, x = 0.60, y = 0.60, now = 0 })
N:Stop()
check(arrived == 1, "a trip stopped on the way isn't an arrival")
