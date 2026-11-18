-- The public API (API.lua): MapzerothAPI.RouteTo checks another addon's points and hands them to the panel, which
-- plans a tour through them and starts it only when asked to.

check(MapzerothAPI and MapzerothAPI.version == 1, "MapzerothAPI is global, version 1")

local calls = {}
local Panel = addon.Panel
local realRoute = Panel.RouteToPoints
Panel.RouteToPoints = function(_, name, points, start) calls[#calls + 1] = { name = name, points = points, start = start } end

local ok, why = MapzerothAPI.RouteTo(nil)
check(not ok and why == "no points", "nothing given: no points")
ok, why = MapzerothAPI.RouteTo({})
check(not ok and why == "no points", "an empty list: no points")
ok, why = MapzerothAPI.RouteTo({ { mapID = 1453, x = 0.4, y = 0.3 }, { mapID = 1453, x = 45, y = 30 } })
check(not ok and why == "bad point 2", "coordinates past 1 (0-100 by mistake): " .. tostring(why))
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
