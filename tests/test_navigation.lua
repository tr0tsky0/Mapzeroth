-- Following a route: which step the player is on, how far along it is, and when it moves on.
-- Yards in these tests: on one map, 0.01 of x is 25 yards and 0.01 of y is 17.
useTestDistances()
addon.World:Build()

local N = addon.Navigation
-- What was measured on the trips below: the engine hands each measurement to a tool and keeps none.
local timed = {}
N.onTiming = function(record) timed[#timed + 1] = record end

local function at(nodeID, dx, dy, extra)
    local node = addon.World:GetNode(nodeID)
    local sample = { mapID = node.mapID, x = node.x + (dx or 0), y = node.y + (dy or 0), now = 0, onTaxi = false }
    for k, v in pairs(extra or {}) do sample[k] = v end
    return sample
end
local function step(method, from, to, seconds, source)
    return { method = method, fromID = from, nodeID = to, seconds = seconds, source = source, text = method .. " " .. to }
end
local entry = { name = "Test destination" }

check(not N:IsActive() and N:Update(at("TAXI_2")) == nil, "nothing happens with no trip")

-- Walk to Stormwind's flight master, fly to Ironforge, then a hearthstone-style jump to Sentinel Hill.
local plan = { steps = {
    step("walk", "YOU", "TAXI_2", 60),
    step("taxi", "TAXI_2", "TAXI_6", 200),
    step("hearthstone", "TAXI_6", "TAXI_4", 25, { itemID = 6948 }),
} }

-- Walking: distance shows and shrinks; within 30 yards moves on.
N:Start(entry, plan)
check(N:IsActive(), "a trip is active once started")
local m = N:Update(at("TAXI_2", 0.08, 0))        -- 200 yards away
check(m.index == 1 and m.total == 3 and m.kind == "walk", "starts on the walk")
check(math.abs(m.distance - 200) < 1, "200 yards to go: " .. tostring(m.distance))
check(math.abs(m.remaining - (60 + 200 + 25)) < 1e-6, "time left at the start is the whole trip: " .. m.remaining)
local nearer = N:Update(at("TAXI_2", 0.04, 0))   -- 100 yards
check(nearer.distance < m.distance and nearer.remaining < m.remaining, "closer means less to go")
check(N:Update(at("TAXI_2", 0.02, 0)).index == 1, "at 50 yards it is still the walk (the radius is small)")
m = N:Update(at("TAXI_2", 0.008, 0))             -- 20 yards
check(m.index == 2 and m.kind == "flight", "within the radius the trip moves to the flight")

-- Flight: waiting until they are on the taxi, then a bar over the planned time, done on landing.
check(m.phase == "waiting" and m.progress == 0, "waiting to take off")
m = N:Update(at("TAXI_2", 0, 0, { now = 10 }))
check(m.phase == "waiting", "standing at the flight master is still waiting")
m = N:Update(at("TAXI_2", 0.5, 0, { now = 20, onTaxi = true }))
check(m.phase == "flying" and m.progress == 0, "on the taxi: flying, and the clock starts when they left")
m = N:Update(at("TAXI_2", 0.5, 0, { now = 120, onTaxi = true }))
check(math.abs(m.progress - 0.5) < 1e-9, "half the flight time later, half the bar: " .. m.progress)
m = N:Update(at("TAXI_2", 0.5, 0, { now = 900, onTaxi = true }))
check(m.progress < 1, "the bar never reaches full before landing")
check(m.overrun == true, "a flight past its planned time says so")
m = N:Update(at("TAXI_2", 0.5, 0, { now = 120, onTaxi = true }))
check(m.overrun == false, "and a flight within it doesn't")
m = N:Update(at("TAXI_6", 0.002, 0, { now = 230, onTaxi = false }))
check(m.index == 3 and m.kind == "ability", "landing ends the flight step")
check(#timed == 1 and timed[1].kind == "flight" and timed[1].planned == 200 and math.abs(timed[1].actual - 210) < 1e-9,
    "the flight was timed from take-off to landing (planned 200, took 210)")

-- Ability: a button, and done once they arrive.
check(m.phase == "use" and m.step.source.itemID == 6948, "the hearthstone step carries its item")
check(N:Update(at("TAXI_6", 0.002, 0, { now = 240 })).index == 3, "still at the landing: not done")
m = N:Update(at("TAXI_4", 0.004, 0, { now = 260 }))
check(m.finished and m.total == 3, "arriving at the last destination ends the trip")
check(N:Update(at("TAXI_2", 5, 5)).finished, "a finished trip stays finished")

-- Skipping ahead: at a later step's destination means the ones before it are done.
local longer = { steps = { plan.steps[1], plan.steps[2], plan.steps[3], step("walk", "TAXI_4", "TAXI_8", 90) } }
N:Start(entry, longer)
m = N:Update(at("TAXI_4", 0.004, 0))
check(m.index == 4, "standing at Sentinel Hill jumps past the walk, flight and hearthstone: " .. tostring(m.index))

-- A player we can't place (an instance): keep the step, no distance, no false progress.
N:Start(entry, plan)
m = N:Update({ now = 0, onTaxi = false })
check(m.index == 1 and m.distance == nil and m.remaining > 0, "no position: no distance")

-- Losing position mid-trip (a loading screen, an instance) must not error even though the last
-- known position is still on hand -- the jump check used to build a "where are they now" node
-- straight from the sample's (possibly missing) mapID/x/y and hand it to the real distance
-- provider unguarded.
N:Start(entry, plan)
N:Update(at("TAXI_2", 0.08, 0))            -- a real position, so active.last gets set
local ok, midTrip = pcall(N.Update, N, { now = 5, onTaxi = false })
check(ok, "losing position mid-trip doesn't error: " .. tostring(midTrip))
check(midTrip.index == 1, "and just keeps the step it was on")

-- Transport: two places on the Stormwind map, 577 yards apart.
local ship = { steps = { step("ship", "TAXI_2", "PORTAL_STORMWIND_DALARAN", 100) } }
N:Start(entry, ship)
m = N:Update(at("TAXI_2", 0.004, 0, { now = 0 }))
check(m.kind == "transport" and m.phase == "waiting" and m.progress == 0, "waiting to board")
m = N:Update(at("TAXI_2", -0.002, 0, { now = 5 }))
check(m.phase == "waiting", "a few yards from the dock is still waiting")
m = N:Update(at("TAXI_2", -0.1, 0, { now = 20 }))       -- 250 yards off
check(m.phase == "underway" and m.progress > 0 and m.progress < 0.99, "away from the dock it is underway: " .. tostring(m.progress))
local before = m.progress
m = N:Update(at("PORTAL_STORMWIND_DALARAN", 0.1, 0, { now = 40 }))
check(m.progress > before, "nearer the far dock, more of the bar")
m = N:Update({ now = 60, onTaxi = false })
check(m.phase == "underway" and math.abs(m.progress - 0.4) < 1e-9, "position unreadable: by elapsed time since it left: " .. tostring(m.progress))
m = N:Update(at("PORTAL_STORMWIND_DALARAN", 0.004, 0, { now = 90 }))
check(m.finished, "arriving at the far dock ends the trip")

-- A ship we never saw depart, that the player is now at the far end of, is also done.
N:Start(entry, ship)
N:Update(at("TAXI_2", 0.004, 0, { now = 0 }))
check(N:Update(at("PORTAL_STORMWIND_DALARAN", 0.004, 0, { now = 30 })).finished, "arriving without having been seen to leave still ends it")

-- Once underway, a zeppelin is timed by its ride alone: the step's 300 s is the plan's average, wait included.
local zeppelin = { steps = { step("zeppelin", "TAXI_2", "PORTAL_STORMWIND_DALARAN", 300, { ride = 120 }) } }
N:Start(entry, zeppelin)
N:Update(at("TAXI_2", 0.004, 0, { now = 0 }))
N:Update(at("TAXI_2", -0.1, 0, { now = 10 }))           -- left the dock
m = N:Update({ now = 70, onTaxi = false })                -- out of sight at sea: by time
check(math.abs(m.progress - 0.5) < 1e-9, "60 s into a 120 s ride is half the bar: " .. tostring(m.progress))
check(math.abs(m.remaining - 60) < 1e-6 and not m.overrun, "60 s left, not the rest of the 300: " .. tostring(m.remaining))
local count = #timed
N:Update(at("PORTAL_STORMWIND_DALARAN", 0.004, 0, { now = 135 }))
check(#timed == count + 1 and timed[#timed].planned == 120, "the measured ride is compared with the ride")

for _, edge in ipairs(addon.Edges or {}) do
    if edge.ride then
        check(edge.cost and edge.ride <= edge.cost, "a ride can't take longer than the wait and ride together: " .. edge.from)
    end
end

-- A hearthstone lands at the bind point, which can be well away from the inn node we have for
-- it: the sudden move is what ends the step, not arriving at the node.
local hearth = { steps = { step("hearthstone", "YOU", "TAXI_4", 25, { itemID = 6948 }), step("walk", "TAXI_4", "TAXI_8", 60) } }
N:Start(entry, hearth)
m = N:Update(at("TAXI_2", 0.2, 0, { now = 0 }))
check(m.index == 1 and m.kind == "ability", "waiting to use the hearthstone")
m = N:Update(at("TAXI_2", 0.2, 0, { now = 1 }))
check(m.index == 1, "standing still doesn't end it")
m = N:Update(at("TAXI_6", 0.3, 0, { now = 20 }))      -- somewhere else entirely, but not at TAXI_4
check(m.index == 2 and m.kind == "walk", "appearing somewhere far away ends the ability step: " .. tostring(m.index))
-- ...and that one jump ends only one step.
local twoAbilities = { steps = { step("hearthstone", "YOU", "TAXI_4", 25, { itemID = 6948 }), step("portal", "TAXI_4", "TAXI_8", 20) } }
N:Start(entry, twoAbilities)
N:Update(at("TAXI_2", 0.2, 0, { now = 0 }))
m = N:Update(at("TAXI_6", 0.3, 0, { now = 20 }))
check(m.index == 2, "one jump ends one step, not two: " .. tostring(m.index))

-- A portal lands where we have it: taking another one from the same room (somewhere far from this one's landing)
-- doesn't end the step; landing at its own end does.
local portalTrip = { steps = { step("portal", "YOU", "TAXI_4", 10), step("walk", "TAXI_4", "TAXI_8", 60) } }
N:Start(entry, portalTrip)
N:Update(at("TAXI_2", 0, 0, { now = 0 }))
m = N:Update(at("TAXI_6", 0, 0, { now = 5 }))
check(m.index == 1, "the wrong portal doesn't end the portal step: " .. tostring(m.index))
m = N:Update(at("TAXI_4", 0, 0, { now = 10 }))
check(m.index == 2, "arriving at its landing does: " .. tostring(m.index))

-- A teleport into somewhere the client can't measure from where we were (an interior that is a map of its own): the
-- map changing is what ends the step, not a distance.
local realDistance = addon.TravelGraph.DistanceProvider
addon.TravelGraph.DistanceProvider = function(a, b)
    if a.mapID ~= b.mapID then return nil end
    return realDistance(a, b)
end
local interior = { steps = { step("teleport", "YOU", "TAXI_4", 10, { itemID = 144391 }), step("walk", "TAXI_4", "TAXI_8", 60) } }
N:Start(entry, interior)
m = N:Update(at("TAXI_2", 0, 0, { now = 0 }))
check(m.index == 1 and m.kind == "ability", "waiting to use the ring")
m = N:Update({ mapID = 500, x = 0.51, y = 0.27, now = 5, onTaxi = false })         -- landed on a map we can't measure to
check(m.index == 2, "landing on another map ends the step even with no distance to read: " .. tostring(m.index))
addon.TravelGraph.DistanceProvider = realDistance

-- Heading: which way to turn to face a node. 0 is straight ahead, positive is left (the game
-- measures facing counter-clockwise from north), negative is right. TAXI_2 is the target.
local target = addon.World:GetNode("TAXI_2")
local function player(dx, dy, facing)
    return { mapID = target.mapID, x = target.x + dx, y = target.y + dy, facing = facing, now = 0 }
end
local NORTH, WEST, SOUTH, EAST = 0, math.pi / 2, math.pi, 3 * math.pi / 2
local function near(a, b) return math.abs(a - b) < 1e-6 end
-- The player is due south of the target, so the target is due north.
check(near(N:Heading(player(0, 0.1, NORTH), target), 0), "facing north with the target due north: straight ahead")
check(near(N:Heading(player(0, 0.1, WEST), target), -math.pi / 2), "facing west, the target north is 90 degrees to the right")
check(near(N:Heading(player(0, 0.1, EAST), target), math.pi / 2), "facing east, it is 90 degrees to the left")
check(near(math.abs(N:Heading(player(0, 0.1, SOUTH), target)), math.pi), "facing south, it is directly behind")
-- The player is due west of the target, so the target is due east.
check(near(N:Heading(player(-0.1, 0, NORTH), target), -math.pi / 2), "target due east while facing north: turn right")
check(near(N:Heading(player(-0.1, 0, EAST), target), 0), "facing east, it is straight ahead")
-- The map isn't square: 0.1 east and 0.1 south are different distances, and the angle follows yards.
local skew = N:Heading(player(-0.1, 0.1, NORTH), target)      -- 250 yd east, 170 yd north
check(near(skew, -math.atan2(250, 170)), "the angle is worked out in yards, not map units: " .. skew)
check(N:Heading({ mapID = target.mapID, x = 0.5, y = 0.5, now = 0 }, target) == nil, "no facing, no heading")
-- It rides along in the walk step's model.
N:Start(entry, { steps = { step("walk", "YOU", "TAXI_2", 60) } })
m = N:Update(player(0, 0.1, WEST))
check(m.kind == "walk" and near(m.heading, -math.pi / 2), "a walk step carries its heading")

-- Which flight was chosen. Two flights on the route, Stormwind > Ironforge > Sentinel Hill.
local twoFlights = { steps = { step("taxi", "TAXI_2", "TAXI_6", 200), step("taxi", "TAXI_6", "TAXI_4", 100) } }
local far = { x = 0.5, y = 0.5 }
local function flying(id, now) return at(id, far.x, far.y, { now = now, onTaxi = true }) end

-- The player buys one ticket straight to the last stop: that is the flight being flown, over both steps.
N:Start(entry, twoFlights)
N:Update(at("TAXI_2"))
N:OnTakeTaxi({ "TAXI_6", "TAXI_4" }, 5)
m = N:Update(at("TAXI_2", 0, 0, { now = 6 }))
check(m.index == 1 and m.phase == "waiting", "a chosen flight takes effect once the taxi moves, not before")
m = N:Update(flying("TAXI_2", 10))
check(m.index == 2 and m.phase == "flying" and not m.offRoute, "a ticket to a later stop skips to that step")
check(math.abs(m.remaining - 300) < 1e-9, "and is timed as both flights: " .. tostring(m.remaining))
m = N:Update(flying("TAXI_2", 160))
check(math.abs(m.progress - 0.5) < 1e-9, "the bar runs over both: half way at 150 of 300 s")
m = N:Update(at("TAXI_4", 0.002, 0, { now = 320 }))
check(m.finished, "landing at the end finishes the trip")
check(timed[#timed].planned == 300 and math.abs(timed[#timed].actual - 310) < 1e-9, "and the flight is timed against the ticket, not one step")
check(timed[#timed].from == "TAXI_2" and timed[#timed].to == "TAXI_4", "and is labelled with where the ticket began, not where the skipped-to step did")

-- The player takes the flight the route said: nothing changes.
N:Start(entry, twoFlights)
N:Update(at("TAXI_2"))
N:OnTakeTaxi({ "TAXI_6" }, 5)
m = N:Update(flying("TAXI_2", 10))
check(m.index == 1 and m.phase == "flying" and not m.offRoute, "the flight the route asked for is just followed")

-- The wrong destination: say so while flying, and plan again on landing.
N:Start(entry, twoFlights)
N:Update(at("TAXI_2"))
N:OnTakeTaxi({ "TAXI_8" }, 5)
m = N:Update(flying("TAXI_2", 10))
check(m.offRoute and m.flyingTo == "TAXI_8" and m.index == 1, "a flight to somewhere off the route is flagged, with where it goes")
m = N:Update(flying("TAXI_2", 100))
check(m.offRoute and not m.finished, "and stays flagged in the air, even passing over a stop of the route")
m = N:Update(at("TAXI_8", 0.002, 0, { now = 200 }))
check(m.replan and m.entry == entry, "landing asks for a new route to the same destination")
check(not N:IsActive(), "and the old trip is done with")

-- A flight that never leaves (no money, cancelled) changes nothing.
N:Start(entry, twoFlights)
N:Update(at("TAXI_2"))
N:OnTakeTaxi({ "TAXI_8" }, 5)
m = N:Update(at("TAXI_2", 0, 0, { now = 40 }))
check(m.index == 1 and not m.offRoute, "a flight that hasn't started in 15 seconds is forgotten")
m = N:Update(flying("TAXI_2", 50))
check(not m.offRoute and m.index == 1, "and doesn't count when a flight starts later")

-- Flying over a later stop is not arriving there.
N:Start(entry, twoFlights)
N:Update(at("TAXI_2"))
m = N:Update(at("TAXI_4", 0.001, 0, { now = 10, onTaxi = true }))
check(m.index == 1 and not m.finished, "passing over a later stop in the air doesn't skip the trip ahead")

-- A note ("Route updated") is shown for a few seconds.
N:Start(entry, twoFlights, "NAV_REROUTED")
check(N:Update(at("TAXI_2", 0, 0, { now = 100 })).notice == "NAV_REROUTED", "a note is on the model at first")
check(N:Update(at("TAXI_2", 0, 0, { now = 105 })).notice == "NAV_REROUTED", "still there a few seconds on")
check(N:Update(at("TAXI_2", 0, 0, { now = 120 })).notice == nil, "and gone after that")

N:Stop()
check(not N:IsActive() and N:Model() == nil, "stopping clears the trip")

-- Finding 5: an update makes at most one distance call per later step (the skip loop), one for the jump check,
-- one for the current step's arrival and one for the model -- steps + 2 at most, whatever the number of steps.
do
    local six = { steps = {
        step("walk", "YOU", "TAXI_2", 60), step("taxi", "TAXI_2", "TAXI_6", 200), step("walk", "TAXI_6", "TAXI_4", 30),
        step("walk", "TAXI_4", "TAXI_8", 30), step("walk", "TAXI_8", "TAXI_6", 30), step("walk", "TAXI_6", "TAXI_2", 30),
    } }
    local provider = addon.TravelGraph.DistanceProvider
    local calls = 0
    addon.TravelGraph.DistanceProvider = function(a, b) calls = calls + 1; return provider(a, b) end
    N:Start(entry, six)
    N:Update(at("TAXI_2", 0.08, 0))              -- the first update also begins the step
    calls = 0
    m = N:Update(at("TAXI_2", 0.06, 0, { now = 1 }))
    print(("provider calls in one update over %d steps: %d"):format(#six.steps, calls))
    check(calls <= #six.steps + 2, "one update, " .. #six.steps .. " steps: at most steps + 2 distance calls, got " .. calls)
    check(m.index == 1 and m.kind == "walk" and math.abs(m.distance - 150) < 1, "the model's distance is as before: " .. tostring(m.distance))
    check(m.heading == nil and math.abs(m.remaining - (60 * 150 / 200 + 200 + 30 * 4)) < 1e-6,
        "and so is the time left: " .. tostring(m.remaining))
    -- The scratch nodes leave nothing behind: a later update from elsewhere is measured from there.
    m = N:Update(at("TAXI_2", 0.02, 0, { now = 2 }))
    check(math.abs(m.distance - 50) < 1, "the next update measures from the new spot: " .. tostring(m.distance))
    addon.TravelGraph.DistanceProvider = provider
    N:Stop()
end

-- A round trip is followed there and back as one trip. The way back ends where the player started, so looking ahead for
-- "already at a later step's place" must not run past the way there until it is over (or the trip would end at once).
local home = { id = "YOU_home", mapID = addon.World:GetNode("TAXI_2").mapID, x = 0.5, y = 0.5 }
local tripPlan = {
    steps = { step("walk", "YOU_home", "TAXI_2", 60), step("taxi", "TAXI_2", "TAXI_6", 200) },
    back = { cost = 100, steps = { step("taxi", "TAXI_6", "TAXI_2", 100), step("walk", "TAXI_2", "RETURN_YOU_home", 60) } },
    returnTo = home,
}
N:Start(entry, tripPlan)
m = N:Update({ mapID = home.mapID, x = home.x, y = home.y, now = 0, onTaxi = false })
check(m.index == 1 and m.total == 4 and not m.finished, "standing where the trip started doesn't end it: the way back's last step ends there")
check(#tripPlan.steps == 2 and N:CurrentPlan().steps[4].nodeID == "RETURN_YOU_home", "the trip holds both legs; the plan it was given is left alone")
m = N:Update(at("TAXI_2", 0.002, 0, { now = 5 }))
check(m.index == 2, "the way there goes on as usual")
m = N:Update(at("TAXI_6", 0.002, 0, { now = 100 }))
check(m.index == 3 and m.kind == "flight", "reaching the destination moves on to the way back")
m = N:Update(at("TAXI_2", 0.002, 0, { now = 300 }))
check(m.index == 4, "and the way back is followed to its end")
m = N:Update({ mapID = home.mapID, x = home.x, y = home.y, now = 400, onTaxi = false })
check(m.finished, "arriving where it started ends the trip")

-- Planned again part way, the way back still goes to where the trip began.
N:Start(entry, tripPlan)
N:Update(at("TAXI_2"))
N:OnTakeTaxi({ "TAXI_8" }, 5)
N:Update(flying("TAXI_2", 10))
m = N:Update(at("TAXI_8", 0.002, 0, { now = 200 }))
check(m.replan and m.returnTo and m.returnTo.id == "YOU_home", "a new route is asked for with the original return point")

-- Passing a step without reaching its end. Places of our own on one map (a tour's stops are the trip's extra places):
-- S, then A 250 yards east of it, then B 170 yards north of A. The route goes S > A > B, an L.
do
    local mapID = addon.World:GetNode("TAXI_2").mapID
    local function place(id, x, y) return { id = id, mapID = mapID, x = x, y = y } end
    local S, A, B, O = place("P_S", 0.30, 0.50), place("P_A", 0.40, 0.50), place("P_B", 0.40, 0.40), place("P_O", 0.10, 0.50)
    local places = { name = "Passing", stops = { { place = S }, { place = A }, { place = B }, { place = O } } }
    local function spot(x, y, now) return { mapID = mapID, x = x, y = y, now = now or 0, onTaxi = false } end

    local corner = { steps = { step("walk", "P_S", "P_A", 60), step("walk", "P_A", "P_B", 40) } }
    N:Start(places, corner)
    m = N:Update(spot(0.30, 0.50))
    check(m.index == 1, "starts on the walk to the corner")
    m = N:Update(spot(0.33, 0.49, 1))           -- 232 yards from B, B is 170 from the corner
    check(m.index == 1, "not past the corner yet: still the walk to it")
    m = N:Update(spot(0.36, 0.46, 2))           -- across the field: 121 yards from the corner, 143 from B
    check(m.index == 2 and m.step.nodeID == "P_B", "cutting across, nearer B than the corner is: on to B: " .. tostring(m.index))

    -- Starting already nearer B than the corner is (B just over a ridge): the corner is the way round, so it isn't
    -- passed, only reached.
    N:Start(places, corner)
    m = N:Update(spot(0.45, 0.42))              -- 129 yards from B
    m = N:Update(spot(0.43, 0.43, 1))
    check(m.index == 1, "starting near B in a straight line doesn't skip the corner")
    m = N:Update(spot(0.405, 0.50, 2))
    check(m.index == 2, "reaching the corner still moves on")

    -- The next step not a walk (the corner is a flight master): never passed, the flight needs the corner.
    N:Start(places, { steps = { step("walk", "P_S", "P_A", 60), step("taxi", "P_A", "P_B", 40) } })
    N:Update(spot(0.30, 0.50))
    m = N:Update(spot(0.36, 0.46, 1))
    check(m.index == 1, "a walk to a flight master is not passed")

    -- A boat from O to the dock at A, then a walk to the flight master at B. Jumping off and swimming ashore short of
    -- the dock passes the boat; it isn't timed, as it never reached the dock.
    local boat = { steps = { step("ship", "P_O", "P_A", 100), step("walk", "P_A", "P_B", 40) } }
    N:Start(places, boat)
    N:Update(spot(0.10, 0.50, 0))
    m = N:Update(spot(0.20, 0.50, 10))
    check(m.phase == "underway", "the boat has left")
    local count = #timed
    m = N:Update(spot(0.36, 0.44, 40))          -- ashore: 143 yards from the dock, 121 from B
    check(m.index == 2 and m.kind == "walk", "ashore short of the dock: on to the walk: " .. tostring(m.index))
    check(#timed == count, "and the ride isn't measured")

    -- Not seen leaving: the boat isn't passed (it may not have left at all).
    N:Start(places, boat)
    N:Update(spot(0.10, 0.50, 0))
    m = N:Update(spot(0.11, 0.50, 5))           -- 25 yards: still at the dock
    check(m.index == 1 and m.phase == "waiting", "waiting at the dock is not passing the boat")

    -- A walk to a zone border is passed once the player is in the zone beyond it, however they crossed (by the river,
    -- not the road). BORDER_DUROTAR_TO_THE_BARRENS is on Durotar's map; its pair on the Barrens'.
    local durotarSide = addon.World:GetNode("BORDER_DUROTAR_TO_THE_BARRENS")
    local barrens = addon.World:GetNode("BORDER_THE_BARRENS_TO_DUROTAR").mapID
    local wp = { id = "P_WP", mapID = barrens, x = 0.55, y = 0.10 }
    local crossing = { name = "Crossing", stops = { { place = wp } } }
    N:Start(crossing, { steps = { step("walk", "YOU", "BORDER_DUROTAR_TO_THE_BARRENS", 140), step("walk", "BORDER_DUROTAR_TO_THE_BARRENS", "P_WP", 110) } })
    m = N:Update({ mapID = durotarSide.mapID, x = 0.46, y = 0.10, now = 0, onTaxi = false })
    check(m.index == 1, "in Durotar: walking to the border")
    m = N:Update({ mapID = durotarSide.mapID, x = 0.40, y = 0.15, now = 1, onTaxi = false })
    check(m.index == 1, "still in Durotar, away from the border: still walking to it")
    m = N:Update({ mapID = barrens, x = 0.60, y = 0.12, now = 2, onTaxi = false })
    check(m.index == 2 and m.step.nodeID == "P_WP", "across the river into the Barrens: on to the waypoint: " .. tostring(m.index))

    -- Planning again keeps the destination; a tour, its stops still to come.
    check(N:ReplanTarget() == crossing, "recalculating plans again to the same destination")
    N:Stop()
    check(N:ReplanTarget() == nil, "and with no trip there is nothing to plan")
end

-- The flight to mark on the flight master's map: the end of the flights that leave this flight master one after
-- another (one ticket), and none from a flight master the route doesn't fly from.
do
    N:Start(entry, { steps = {
        step("walk", "YOU", "TAXI_2", 60),
        step("taxi", "TAXI_2", "TAXI_6", 200),
        step("taxi", "TAXI_6", "TAXI_7", 150),
        step("walk", "TAXI_7", "TAXI_8", 90),
        step("taxi", "TAXI_8", "TAXI_9", 120),
    } })
    check(N:FlightTarget("TAXI_2") == "TAXI_7", "from Stormwind: through Ironforge to the end of the run of flights")
    check(N:FlightTarget("TAXI_6") == "TAXI_7", "from the middle of the run: its end")
    check(N:FlightTarget("TAXI_8") == "TAXI_9", "a later flight, after a walk, is its own ticket")
    check(N:FlightTarget("TAXI_4") == nil, "no flight from a flight master the route doesn't fly from")
    check(N:FlightTarget(nil) == nil, "and none when where the player is isn't known")
    N:Stop()
    check(N:FlightTarget("TAXI_2") == nil, "no trip, nothing to mark")
end

-- Out of an interior (the Wizard's Sanctum): an indoor walk is done only at the door, not 30 yards short of it.
do
    N:Start(entry, { steps = {
        step("walk", "PORTAL_STORMWIND_DALARAN", "ENTRANCE_SW_WIZARDS_SANCTUM_INNER", 10),
        step("walk", "ENTRANCE_SW_WIZARDS_SANCTUM_INNER", "ENTRANCE_SW_WIZARDS_SANCTUM_OUTER", 2),
        step("walk", "ENTRANCE_SW_WIZARDS_SANCTUM_OUTER", "TAXI_2", 60),
    } })
    local m = N:Update(at("ENTRANCE_SW_WIZARDS_SANCTUM_INNER", 0.008, 0))     -- 20 yards inside
    check(m.index == 1, "20 yards from the door, inside, it is still the walk to the door: step " .. m.index)
    m = N:Update(at("ENTRANCE_SW_WIZARDS_SANCTUM_INNER", 0.002, 0))           -- 5 yards
    check(m.index >= 2, "at the door it moves on: step " .. m.index)
    m = N:Update(at("ENTRANCE_SW_WIZARDS_SANCTUM_OUTER", 0, 0))
    check(m.index == 3, "out of the door, the walk on to the flight master: step " .. m.index)
    N:Stop()
end
