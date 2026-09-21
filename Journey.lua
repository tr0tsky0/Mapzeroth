local addonName, addon = ...

-- Planning a trip from where the player stands, for the panel: a session holds the graph
-- and the cost of getting everywhere (so each search result can show a time), and a plan is
-- the route to one destination, as steps a person can read.

local Journey = {}
addon.Journey = Journey

local L = addon.L

-- "3m 54s", "45s", "1h 05m". `seconds` may be fractional.
function Journey:FormatTime(seconds)
    seconds = math.floor(seconds + 0.5)
    if seconds >= 3600 then
        return L["TIME_HOURS"]:format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
    elseif seconds >= 60 then
        return L["TIME_MINUTES"]:format(math.floor(seconds / 60), seconds % 60)
    end
    return L["TIME_SECONDS"]:format(seconds)
end

-- Builds the graph for this player from `start` (see TravelGraph:AddStart). Nothing is
-- priced yet: a plan searches for one destination, and Cost prices everywhere on first use.
-- Returns nil, "nowhere" if we have no nodes on the start's map.
function Journey:Build(ctx, start)
    local graph = addon.TravelGraph:Build(ctx)
    if not addon.TravelGraph:AddStart(graph, ctx, start) then return nil, "nowhere" end
    return { ctx = ctx, start = start, graph = graph }
end

local function costs(session)
    session.costs = session.costs or addon.Pathfinder:FindCosts(session.graph, session.start.id)
    return session.costs
end

-- Seconds to reach a node, or nil if it can't be reached.
function Journey:Cost(session, nodeID)
    return costs(session)[nodeID]
end

local function goalsOf(entry)
    return entry.nodeIDs or { entry.nodeID }
end

-- The cheapest of several nodes to reach, and its cost ("nearest ley line").
function Journey:Nearest(session, nodeIDs)
    local best, bestCost
    for _, id in ipairs(nodeIDs) do
        local cost = costs(session)[id]
        if cost and (not bestCost or cost < bestCost) then best, bestCost = id, cost end
    end
    return best, bestCost
end

-- Seconds to reach a destination entry (the nearest of its nodes), or nil.
function Journey:EntryCost(session, entry)
    local _, cost = self:Nearest(session, goalsOf(entry))
    return cost
end

local function stepText(method, name)
    local key = "STEP_" .. tostring(method):upper()
    return (addon:HasString(key) and L[key] or L["STEP_OTHER"]):format(name)
end

-- The route as a person reads it: one entry per leg, walking legs merged.
local TRIVIAL_WALK = 4     -- seconds: a walk this short is standing where you already are

local function readableSteps(result)
    local steps = {}
    local legs = addon.Pathfinder:CollapseSteps(result.steps)
    for _, step in ipairs(legs) do
        if not (step.method == "walk" and step.cost < TRIVIAL_WALK and #legs > 1) then
            -- A portal node is named for where it leads, so the step names the one you take
            -- (where you stand), not the one you come out of.
            local name = addon:GetNodeName(step.method == "portal" and step.from or step.to)
            steps[#steps + 1] = {
                method = step.method, nodeID = step.to, fromID = step.from, source = step.source,
                seconds = step.cost, name = name,
                text = stepText(step.method, name),
                approx = step.method == "walk",     -- a walk is an estimate
            }
        end
    end
    return steps
end

-- With no rule about found flight points, would a flight we can't use get there faster?
-- Then say which point would help, and by how much.
local function flightHint(session, goalID, plan)
    local ctx = session.ctx
    if not ctx.flightNodeFound then return nil end
    local free = {}
    for k, v in pairs(ctx) do free[k] = v end
    free.flightNodeFound = nil
    session.free = session.free or Journey:Build(free, session.start)
    if not session.free then return nil end
    local result = addon.Pathfinder:FindPath(session.free.graph, session.start.id, goalID)
    if not result or result.cost + 1 >= plan.cost then return nil end
    for _, step in ipairs(result.steps) do
        if step.method == "flight" and ctx.flightNodeFound(step.to) ~= true then
            return {
                nodeID = step.to, name = addon:GetNodeName(step.to), saves = plan.cost - result.cost,
                -- known: a flight master's window said it isn't found; otherwise we just haven't looked
                known = ctx.flightNodeFound(step.to) == false,
            }
        end
    end
end

-- The route to goalID (a node id, or a list of them for the nearest): { cost, goal (the
-- node reached), steps = {{method, nodeID, seconds, name, text, approx}}, hint = {nodeID,
-- name, saves, known} or nil }. Returns nil if there is no way there.
function Journey:Plan(session, goalID)
    local result = addon.Pathfinder:FindPath(session.graph, session.start.id, goalID)
    if not result then return nil end
    local plan = { cost = result.cost, steps = readableSteps(result), goal = result.goal }
    plan.hint = flightHint(session, goalID, plan)
    return plan
end

-- The route to a destination entry.
function Journey:PlanEntry(session, entry)
    return self:Plan(session, goalsOf(entry))
end

-- The sentence for a hint, in our own words around the client's names.
function Journey:HintText(hint)
    if not hint then return nil end
    if hint.known then
        return L["HINT_UNFOUND"]:format(hint.name, self:FormatTime(hint.saves))
    end
    return L["HINT_UNKNOWN"]:format(self:FormatTime(hint.saves))
end
