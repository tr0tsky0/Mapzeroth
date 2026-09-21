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

-- Flights are single legs (Data/Forever/Flights.lua), and the game sells tickets over them. A ticket
-- from A to B may fly through other flight points without landing (each extra leg saves
-- FLIGHT_CHAIN_SAVING seconds), except that when there is a direct leg from A to B the game always
-- sells that one, however much quicker a chain would be. So a state in the air remembers the
-- ticket's origin and whether it is still its first leg: the ticket can end (land, walk on, reach the
-- goal) at a point only if it is that first leg or has no direct leg from its origin to that point.
-- Otherwise it must go on, or the plan lands earlier and takes a new ticket from there.

local Pathfinder = {}
addon.Pathfinder = Pathfinder

-- Is there a direct flight leg from a to b in this graph? (Built on first use.)
local function hasDirectLeg(graph, a, b)
    if not graph.directLegs then
        graph.directLegs = {}
        for from, steps in pairs(graph.adjacency) do
            for _, step in ipairs(steps) do
                if step.method == "flight" then
                    graph.directLegs[from] = graph.directLegs[from] or {}
                    graph.directLegs[from][step.to] = true
                end
            end
        end
    end
    return graph.directLegs[a] ~= nil and graph.directLegs[a][b] == true
end

-- May the search stop, land or walk on from this state? Only if it isn't part way along a ticket that
-- the game wouldn't sell (see the top of the file).
local function canLand(graph, node)
    return node.origin == nil or node.single or not hasDirectLeg(graph, node.origin, node.id)
end

-- What taking `step` from `node` can mean: a list of { cost, origin, single, through } for a flight (a
-- flight after a flight can go on along the same ticket, or land and start a new one), or nil when the
-- step can't be taken from here (a non-flight step from part way along a ticket that can't end).
local function expandStep(graph, node, step, d, oneTicket)
    if step.method ~= "flight" then
        if node.origin and not canLand(graph, node) then return nil end
        return { { d + step.cost } }
    end
    if not node.origin then
        return { { d + step.cost, node.id, true, false } }
    end
    local options = { { d + step.cost - (addon.FLIGHT_CHAIN_SAVING or 0), node.origin, false, true } }
    if canLand(graph, node) and not oneTicket then
        options[#options + 1] = { d + step.cost, node.id, true, false }
    end
    return options
end

local function airKey(option)
    return option[2] and ("|air:" .. option[2] .. (option[3] and "1" or "0")) or ""
end

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
-- oneTicket: optional, never land part way along a flight and take a new ticket (what the game
-- would sell for a destination when clicked at a flight master, not the best plan).
-- Returns { cost = seconds, goal = the node reached, steps = { {from, to, cost, method,
-- source}, ... } } or nil when no goal can be reached.
function Pathfinder:FindPath(graph, startID, goalID, initialPhase, oneTicket)
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
            if goals[node.id] and canLand(graph, node) then
                goalKey, reached = node.key, node.id
                break
            end

            for _, step in ipairs(graph.adjacency[node.id] or {}) do
                local state = nextPhaseState(node.state, step)
                if state then
                    for _, option in ipairs(expandStep(graph, node, step, d, oneTicket) or {}) do
                        local nd = option[1]
                        local key = step.to .. "|" .. phaseKey(state) .. airKey(option)
                        if not dist[key] or nd < dist[key] then
                            dist[key] = nd
                            prev[key] = { key = node.key, step = step, through = option[4] }
                            heapPush(heap, { nd, { key = key, id = step.to, state = state,
                                                   origin = option[2], single = option[3] } })
                        end
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
        local step = link.step
        if link.through then                        -- goes on along the ticket the last flight began
            local copy = {}
            for k, v in pairs(step) do copy[k] = v end
            copy.through = true
            step = copy
        end
        table.insert(steps, 1, step)
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
            if canLand(graph, node) and (costs[node.id] == nil or d < costs[node.id]) then costs[node.id] = d end
            for _, step in ipairs(graph.adjacency[node.id] or {}) do
                local state = nextPhaseState(node.state, step)
                if state then
                    for _, option in ipairs(expandStep(graph, node, step, d, oneTicket) or {}) do
                        local nd = option[1]
                        local key = step.to .. "|" .. phaseKey(state) .. airKey(option)
                        if not dist[key] or nd < dist[key] then
                            dist[key] = nd
                            heapPush(heap, { nd, { key = key, id = step.to, state = state,
                                                   origin = option[2], single = option[3] } })
                        end
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
-- flights along one ticket (see the top of the file) as "fly to X". A walk still stops where a person would
-- mark the route: at a zone border or a city entrance, and where it goes from one container
-- into another (out of an interior, into a city), so those stay steps of their own.
-- Returns a new list; the result's own steps are untouched, and each merged step keeps the
-- pieces it was made from in `parts`.
function Pathfinder:CollapseSteps(steps)
    local collapsed = {}
    for _, step in ipairs(steps) do
        local last = collapsed[#collapsed]
        -- Consecutive walks are one walk; consecutive flights are one ticket (in game you buy a
        -- ticket to the far flight point and fly through the stops without landing).
        local joins = last and step.method == last.method
            and (step.method == "walk" or (step.method == "flight" and step.through))
        if joins and step.method == "walk" then
            local World = addon.World
            joins = not World:IsMilestone(last.to)
                and World:GetNodeContainer(last.to) == World:GetNodeContainer(step.to)
        end
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
