local addonName, addon = ...

-- Following a route. Once the player starts a trip, this tracks which step they are on and
-- how far along it is, from samples of where they are:
--   sample = { mapID, x, y, onTaxi, now }     (mapID nil when we can't tell, as in an instance)
-- It knows nothing about frames; the navigator shows what Model() says, and tests feed it
-- samples directly.
--
-- What "progress" means depends on the step:
--   walk       distance left to the step's destination (yards), and time left scaled from it;
--   flight     waiting until the player is actually on the taxi, then a bar over the flight's
--              planned time, done when they land;
--   transport  (boat, zeppelin, tram) waiting until the player has moved off the boarding
--              point, then a bar from how much of the way to the far dock is covered (or from
--              elapsed time when positions aren't readable at sea), done on arrival;
--   ability    (hearthstone, teleport) a button to use it; done when the player arrives;
--   portal     walk into it; done when the player arrives.
-- A step is done when the player is within a small radius of its destination (a landing or a
-- ship's arrival counts too; a teleport or portal also counts the moment the player is suddenly
-- somewhere else, since a bind point can be well away from the inn node we have for it). If they get to a later step's destination, the steps between are
-- skipped, and finishing the last step ends the trip.

local Navigation = {}
addon.Navigation = Navigation

local WALK_RADIUS = 30       -- yards
local ARRIVE_RADIUS = 60     -- yards, for everything that isn't walking: a landing spot is looser
local DEPART_RADIUS = 40     -- yards moved from the boarding point before a ship counts as underway
local JUMP = 300             -- yards between two updates that can only be a teleport or a portal

local KINDS = {
    walk = "walk", transition = "walk", flight = "flight",
    ship = "transport", zeppelin = "transport", tram = "transport",
    teleport = "ability", hearthstone = "ability", portal = "portal",
}

local function kindOf(method)
    return KINDS[method] or "walk"
end

local active       -- the trip: { entry, plan, steps, index, state, finished, model }

-- What was measured on trips this session: { kind, from, to, planned, actual } in seconds. A flight
-- is timed from take-off to landing; a boat from leaving the dock to arriving (the plan's number
-- also includes waiting for it, so that comparison is only rough). Read with Navigation:Timings().
local timings = {}

local function nodeOf(id)
    return id and addon.World:GetNode(id)
end

-- Yards from the sample to a node, or nil if we can't say.
local function distance(sample, node)
    if not (sample and sample.mapID and node) then return nil end
    return addon.TravelGraph.DistanceProvider(
        { id = "YOU_NOW", nocache = true, mapID = sample.mapID, x = sample.x, y = sample.y }, node)
end

local function radiusOf(step)
    return kindOf(step.method) == "walk" and WALK_RADIUS or ARRIVE_RADIUS
end

local function arrived(step, sample)
    local d = distance(sample, nodeOf(step.nodeID))
    return d ~= nil and d <= radiusOf(step)
end

local function beginStep(sample)
    local step = active.steps[active.index]
    local node = nodeOf(step.nodeID)
    local state = { startedAt = sample.now, startDistance = distance(sample, node) }
    if kindOf(step.method) == "transport" then
        state.origin = nodeOf(step.fromID)
        state.routeLength = state.origin and node and addon.TravelGraph.DistanceProvider(state.origin, node)
    end
    active.state = state
end

local function advance(sample)
    active.index = active.index + 1
    if active.index > #active.steps then
        active.finished = true
        active.state = nil
    else
        beginStep(sample)
    end
end

-- True once the current step is done. Also watches for boarding and take-off as it goes.
local function completed(step, sample)
    local kind, state = kindOf(step.method), active.state
    -- A flight or a ship that started far from where it ends and finds the player there is
    -- done, even if we never saw it depart (positions can be unreadable at sea).
    local farStart = state.startDistance == nil or state.startDistance > 2 * ARRIVE_RADIUS

    if kind == "flight" then
        if sample.onTaxi then
            state.flying = true
            state.flightStart = state.flightStart or sample.now
            return false
        end
        if state.flying then
            timings[#timings + 1] = { kind = "flight", from = step.fromID, to = step.nodeID,
                                      planned = step.seconds, actual = sample.now - state.flightStart }
            return true
        end
        return farStart and arrived(step, sample)
    elseif kind == "transport" then
        if not state.underway then
            local d = state.origin and distance(sample, state.origin)
            if d and d > DEPART_RADIUS then
                state.underway = true
                state.departedAt = sample.now
            end
        end
        if (state.underway or farStart) and arrived(step, sample) then
            if state.underway then
                timings[#timings + 1] = { kind = step.method, from = step.fromID, to = step.nodeID,
                                          planned = step.seconds, actual = sample.now - state.departedAt }
            end
            return true
        end
        return false
    end
    if kind == "ability" or kind == "portal" then
        return arrived(step, sample) or active.jumped == true
    end
    return arrived(step, sample)
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

-- What the navigator shows for the current step.
local function buildModel(sample)
    local steps = active.steps
    if active.finished then
        return { finished = true, total = #steps, destination = active.entry and active.entry.name }
    end

    local step, state = steps[active.index], active.state
    local kind = kindOf(step.method)
    local model = {
        finished = false, index = active.index, total = #steps, step = step, kind = kind,
        destination = active.entry and active.entry.name,
    }
    local left = step.seconds

    if kind == "walk" then
        model.distance = distance(sample, nodeOf(step.nodeID))
        if model.distance and state.startDistance and state.startDistance > 0 then
            left = step.seconds * clamp(model.distance / state.startDistance, 0, 1)
        end
    elseif kind == "flight" then
        if state.flying then
            model.phase = "flying"
            model.overrun = (sample.now - state.flightStart) > step.seconds      -- longer than the data says
            model.progress = clamp((sample.now - state.flightStart) / step.seconds, 0, 0.99)
            left = step.seconds * (1 - model.progress)
        else
            model.phase = "waiting"
            model.progress = 0
        end
    elseif kind == "transport" then
        if state.underway then
            model.phase = "underway"
            local d = distance(sample, nodeOf(step.nodeID))
            if d and state.routeLength and state.routeLength > 0 then
                model.progress = clamp(1 - d / state.routeLength, 0, 0.99)
            else
                model.progress = clamp((sample.now - state.departedAt) / step.seconds, 0, 0.99)
            end
            model.overrun = (sample.now - state.departedAt) > step.seconds
            left = step.seconds * (1 - model.progress)
        else
            model.phase = "waiting"
            model.progress = 0
        end
    else
        model.phase = "use"
    end

    for i = active.index + 1, #steps do left = left + steps[i].seconds end
    model.remaining = left
    return model
end

-- ---------------------------------------------------------------------------------------

-- Begin following a plan (from Journey:PlanEntry) to a destination entry.
function Navigation:Start(entry, plan)
    active = { entry = entry, plan = plan, steps = plan.steps, index = 1, finished = false, jumped = false }
end

function Navigation:Stop()
    active = nil
end

function Navigation:Timings()
    return timings
end

function Navigation:IsActive()
    return active ~= nil
end

-- The latest model, or nil when no trip is being followed.
function Navigation:Model()
    return active and active.model
end

-- Feed a sample of the player. Returns the model (nil when no trip).
function Navigation:Update(sample)
    if not active then return nil end
    if not active.finished then
        if not active.state then beginStep(sample) end

        -- Already at a later step's destination: skip everything before it.
        for j = #active.steps, active.index + 1, -1 do
            if arrived(active.steps[j], sample) then
                active.index = j
                beginStep(sample)
                advance(sample)
                break
            end
        end
        -- Did the player just appear somewhere far from where they were a moment ago?
        local jump = active.last and distance(active.last, { id = "JUMP", nocache = true, mapID = sample.mapID, x = sample.x, y = sample.y })
        active.jumped = jump ~= nil and jump > JUMP
        while not active.finished and completed(active.steps[active.index], sample) do
            advance(sample)
            active.jumped = false           -- one jump ends one step
        end
    end
    active.last = sample.mapID and { mapID = sample.mapID, x = sample.x, y = sample.y } or active.last
    active.model = buildModel(sample)
    return active.model
end

-- Where the player is right now, as a sample (needs the client).
function Navigation:Sample()
    local sample = { now = GetTime(), onTaxi = UnitOnTaxi and UnitOnTaxi("player") or false }
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        local x, y = pos:GetXY()
        if x and not (x == 0 and y == 0) then
            sample.mapID, sample.x, sample.y = mapID, x, y
        end
    end
    return sample
end
