-- Following a route: which step the player is on, how far along it is, and when it moves on.
-- Yards in these tests: on one map, 0.01 of x is 25 yards and 0.01 of y is 17.
useTestDistances()
addon.World:Build()

local N = addon.Navigation

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
    step("flight", "TAXI_2", "TAXI_6", 200),
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
local timed = N:Timings()
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
local twoFlights = { steps = { step("flight", "TAXI_2", "TAXI_6", 200), step("flight", "TAXI_6", "TAXI_4", 100) } }
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
timed = N:Timings()
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
