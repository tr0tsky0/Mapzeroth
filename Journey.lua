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

-- A flight costs its fare, and a route the player can't pay for isn't a route: with the player's money
-- known (ctx.money, copper) the search only takes routes whose flights it covers, and picks the
-- quickest of those. With no money known, fares are only reported.
local function searchOptions(session, budget)
    return { fareFactor = session.ctx.fareFactor or 1, budget = budget }
end

local function costs(session)
    if session.costs then return session.costs end
    local money = session.ctx.money
    local quickest, fares = addon.Pathfinder:FindCosts(session.graph, session.start.id, nil, searchOptions(session, nil))
    session.costs = quickest
    if money then
        -- The exact search that keeps every trade of time against fare is dearer, so it only runs when some
        -- place's quickest route is one the player can't pay for (and then covers the whole map at once).
        for _, fare in pairs(fares) do
            if fare > money then
                session.costs = addon.Pathfinder:FindCosts(session.graph, session.start.id, nil, searchOptions(session, money))
                break
            end
        end
    end
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

local function stepText(method, name, via)
    if via and #via > 0 then
        return L["STEP_FLIGHT_VIA"]:format(name, table.concat(via, ", "))
    end
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
            -- A flight ticket that passes through other flight points names them.
            local via
            if step.method == "flight" and #step.parts > 1 then
                via = {}
                for i = 1, #step.parts - 1 do via[#via + 1] = addon:GetNodeName(step.parts[i].to) end
            end
            steps[#steps + 1] = {
                method = step.method, nodeID = step.to, fromID = step.from, source = step.source,
                seconds = step.cost, name = name, via = via,
                text = stepText(step.method, name, via),
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
-- node reached), fare (copper the flights cost), steps = {{method, nodeID, seconds, name, text,
-- approx}}, hint = {nodeID, name, saves, known} or nil }. With the player's money known, it is the
-- quickest route they can pay for: `quickest` = { fare, saves } if a dearer route would be quicker,
-- and `unaffordable` if no route is within their means (then it is the cheapest there is).
-- Returns nil if there is no way there.
function Journey:Plan(session, goalID)
    local money = session.ctx.money
    local fastest = addon.Pathfinder:FindPath(session.graph, session.start.id, goalID, nil, searchOptions(session, nil))
    if not fastest then return nil end
    local chosen = fastest
    if money and fastest.fare > money then
        chosen = addon.Pathfinder:FindPath(session.graph, session.start.id, goalID, nil, searchOptions(session, money))
    end
    local plan = { cost = (chosen or fastest).cost, steps = readableSteps(chosen or fastest), goal = (chosen or fastest).goal,
                   fare = (chosen or fastest).fare, money = money }
    if not chosen then
        plan.unaffordable = true                           -- no way there within their means: show the quickest anyway
    elseif chosen ~= fastest and fastest.cost + 1 < chosen.cost then
        plan.quickest = { fare = fastest.fare, saves = chosen.cost - fastest.cost }
    end
    plan.hint = flightHint(session, goalID, plan)
    return plan
end

function Journey:PlanEntry(session, entry)
    return self:Plan(session, goalsOf(entry))
end

-- "1g 20s 5c" for an amount in copper.
function Journey:FormatMoney(copper)
    copper = math.floor((copper or 0) + 0.5)
    local gold, silver, rest = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = L["MONEY_GOLD"]:format(gold) end
    if silver > 0 then parts[#parts + 1] = L["MONEY_SILVER"]:format(silver) end
    if rest > 0 or #parts == 0 then parts[#parts + 1] = L["MONEY_COPPER"]:format(rest) end
    return table.concat(parts, " ")
end

-- What a plan says about its fares beyond the total: that it can't be paid for, or that it is not the
-- quickest way because that costs more than the player has. Nil when there is nothing to say.
function Journey:FareText(plan)
    if not plan then return nil end
    if plan.unaffordable then
        return L["HINT_BROKE"]:format(self:FormatMoney(plan.fare), self:FormatMoney(plan.money))
    end
    if plan.quickest then
        return L["HINT_QUICKER"]:format(self:FormatTime(plan.quickest.saves), self:FormatMoney(plan.quickest.fare))
    end
end

-- The route to a destination entry from where the player is now (nil if there is none).
function Journey:PlanFromHere(entry)
    local start = addon:GetPlayerStart()
    local session = start and self:Build(addon:GetPlayerContext(), start)
    return session and self:PlanEntry(session, entry) or nil
end

-- The sentence for a hint, in our own words around the client's names.
function Journey:HintText(hint)
    if not hint then return nil end
    if hint.known then
        return L["HINT_UNFOUND"]:format(hint.name, self:FormatTime(hint.saves))
    end
    return L["HINT_UNKNOWN"]:format(self:FormatTime(hint.saves))
end
