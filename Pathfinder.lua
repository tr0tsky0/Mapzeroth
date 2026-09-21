local addonName, addon = ...

-- Dijkstra over the graph from TravelGraph:Build.
--
-- Search state is (nodeID, phaseState), not just nodeID. Zidormi-style phase
-- flags are sticky per phaseGroup, so without the phase state the search
-- could "launder" a phase change for free by detouring through a neutral
-- zone that borders both phase siblings. phaseState is a small
-- { phaseGroup = side } table, and only phase groups that exist in the
-- loaded data ever enter it, so a ruleset without phasing (Forever) pays
-- nothing.
--
-- An edge into a phase-tagged container normally requires the current
-- simulated side to match that container's side. An edge listing the group in
-- `overridesPhase` skips that check and forces the state to the destination's
-- side instead (a Zidormi conversation, or Teleport: Undercity landing on the
-- present side regardless).

local Pathfinder = {}
addon.Pathfinder = Pathfinder

-- Binary min-heap of { priority, payload }.
local function heapPush(heap, item)
    heap[#heap + 1] = item
    local i = #heap
    while i > 1 do
        local parent = math.floor(i / 2)
        if heap[parent][1] <= heap[i][1] then break end
        heap[parent], heap[i] = heap[i], heap[parent]
        i = parent
    end
end

local function heapPop(heap)
    local top = heap[1]
    local last = table.remove(heap)
    if #heap > 0 then
        heap[1] = last
        local i, n = 1, #heap
        while true do
            local left, right, smallest = i * 2, i * 2 + 1, i
            if left <= n and heap[left][1] < heap[smallest][1] then smallest = left end
            if right <= n and heap[right][1] < heap[smallest][1] then smallest = right end
            if smallest == i then break end
            heap[smallest], heap[i] = heap[i], heap[smallest]
            i = smallest
        end
    end
    return top
end

local function phaseKey(state)
    local groups = {}
    for group in pairs(state) do groups[#groups + 1] = group end
    if #groups == 0 then return "" end
    table.sort(groups)
    for i, group in ipairs(groups) do
        groups[i] = group .. "=" .. state[group]
    end
    return table.concat(groups, ",")
end

-- Returns the state after taking `step` into its destination, or nil if the
-- edge isn't allowed given the current simulated phases.
local function nextPhaseState(state, step)
    local World = addon.World
    local group, side = World:GetPhase(World:GetNodeContainer(step.to))
    if not group then return state end

    if step.overridesPhase then
        for _, g in ipairs(step.overridesPhase) do
            if g == group then
                if state[group] == side then return state end
                local copy = {}
                for k, v in pairs(state) do copy[k] = v end
                copy[group] = side
                return copy
            end
        end
    end
    if state[group] ~= side then return nil end
    return state
end

-- graph: from TravelGraph:Build. goalID is a node id, or a list of node ids to reach
-- whichever is cheapest ("the nearest ley line"). initialPhase: optional { group = side }.
-- Returns { cost = seconds, goal = the node reached, steps = { {from, to, cost, method,
-- source}, ... } } or nil when no goal can be reached.
function Pathfinder:FindPath(graph, startID, goalID, initialPhase)
    local goals = {}
    if type(goalID) == "table" then
        for _, id in ipairs(goalID) do goals[id] = true end
    else
        goals[goalID] = true
    end

    local startState = {}
    for k, v in pairs(initialPhase or {}) do startState[k] = v end

    local dist, prev, visited = {}, {}, {}
    local heap = {}

    local startKey = startID .. "|" .. phaseKey(startState)
    dist[startKey] = 0
    heapPush(heap, { 0, { key = startKey, id = startID, state = startState } })

    -- Abilities usable from anywhere seed the search alongside the start node.
    for _, ability in ipairs(graph.anywhere or {}) do
        local state = nextPhaseState(startState, { to = ability.to, overridesPhase = ability.source.overridesPhase })
        if state then
            local key = ability.to .. "|" .. phaseKey(state)
            if not dist[key] or ability.cost < dist[key] then
                dist[key] = ability.cost
                prev[key] = { key = startKey, step = {
                    from = startID, to = ability.to, cost = ability.cost,
                    method = ability.method, source = ability.source,
                } }
                heapPush(heap, { ability.cost, { key = key, id = ability.to, state = state } })
            end
        end
    end

    local goalKey, reached
    while #heap > 0 do
        local item = heapPop(heap)
        local d, node = item[1], item[2]
        if not visited[node.key] then
            visited[node.key] = true
            if goals[node.id] then
                goalKey, reached = node.key, node.id
                break
            end

            for _, step in ipairs(graph.adjacency[node.id] or {}) do
                local state = nextPhaseState(node.state, step)
                if state then
                    -- A flight leg taken straight after another doesn't land and take off between.
                    local flight = step.method == "flight"
                    local nd = d + step.cost - ((flight and node.air) and (addon.FLIGHT_CHAIN_SAVING or 0) or 0)
                    local key = step.to .. "|" .. phaseKey(state) .. (flight and "|air" or "")
                    if not dist[key] or nd < dist[key] then
                        dist[key] = nd
                        prev[key] = { key = node.key, step = step }
                        heapPush(heap, { nd, { key = key, id = step.to, state = state, air = flight } })
                    end
                end
            end
        end
    end

    if not goalKey then return nil end

    local steps = {}
    local key = goalKey
    while key ~= startKey do
        local link = prev[key]
        table.insert(steps, 1, link.step)
        key = link.key
    end
    return { cost = dist[goalKey], goal = reached, steps = steps }
end

-- The cheapest cost in seconds from startID to every node it can reach, as
-- { [nodeID] = seconds }: one search for a whole list of results.
function Pathfinder:FindCosts(graph, startID, initialPhase)
    local startState = {}
    for k, v in pairs(initialPhase or {}) do startState[k] = v end

    local dist, visited, heap = {}, {}, {}
    local costs = {}
    local startKey = startID .. "|" .. phaseKey(startState)
    dist[startKey] = 0
    heapPush(heap, { 0, { key = startKey, id = startID, state = startState } })

    for _, ability in ipairs(graph.anywhere or {}) do
        local state = nextPhaseState(startState, { to = ability.to, overridesPhase = ability.source.overridesPhase })
        if state then
            local key = ability.to .. "|" .. phaseKey(state)
            if not dist[key] or ability.cost < dist[key] then
                dist[key] = ability.cost
                heapPush(heap, { ability.cost, { key = key, id = ability.to, state = state } })
            end
        end
    end

    while #heap > 0 do
        local item = heapPop(heap)
        local d, node = item[1], item[2]
        if not visited[node.key] then
            visited[node.key] = true
            if costs[node.id] == nil or d < costs[node.id] then costs[node.id] = d end
            for _, step in ipairs(graph.adjacency[node.id] or {}) do
                local state = nextPhaseState(node.state, step)
                if state then
                    local flight = step.method == "flight"
                    local nd = d + step.cost - ((flight and node.air) and (addon.FLIGHT_CHAIN_SAVING or 0) or 0)
                    local key = step.to .. "|" .. phaseKey(state) .. (flight and "|air" or "")
                    if not dist[key] or nd < dist[key] then
                        dist[key] = nd
                        heapPush(heap, { nd, { key = key, id = step.to, state = state, air = flight } })
                    end
                end
            end
        end
    end
    costs[startID] = nil
    return costs
end

-- Presentation: what a person sees. The search happily walks through unrelated nodes
-- on the way (a trainer that happens to lie along the road), which costs the same as
-- walking straight there, so consecutive walk steps read as one "walk to X", and
-- consecutive flights as one ticket "fly to X". Returns
-- a new list; the result's own steps are untouched, and each merged step keeps the
-- pieces it was made from in `parts`.
function Pathfinder:CollapseSteps(steps)
    local collapsed = {}
    for _, step in ipairs(steps) do
        local last = collapsed[#collapsed]
        -- Consecutive walks are one walk; consecutive flights are one ticket (in game you buy a
        -- ticket to the far flight point and fly through the stops without landing).
        local joins = last and step.method == last.method and (step.method == "walk" or step.method == "flight")
        if joins then
            last.to = step.to
            last.cost = last.cost + step.cost - (step.method == "flight" and (addon.FLIGHT_CHAIN_SAVING or 0) or 0)
            last.parts[#last.parts + 1] = step
        else
            collapsed[#collapsed + 1] = {
                from = step.from, to = step.to, cost = step.cost, method = step.method,
                source = step.source, parts = { step },
            }
        end
    end
    return collapsed
end
