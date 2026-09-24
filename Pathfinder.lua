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
-- present side regardless). An edge with `inPhase = { group, side }` can only be
-- taken on that side (the portal at the Dark Portal goes to Outland in the past,
-- to Draenor in the present), wherever its ends are.
-- A group the start state doesn't name (the client couldn't tell which side the
-- player is on) is open: either side can be entered, and nothing is recorded (it
-- is already as open as a state can be, so a switch there changes nothing either).
-- A route takes at most one phase switch (a known group changing side): every
-- switch is a new state the whole graph is searched in again, and nobody needs
-- two Zidormi conversations in one trip. So a search holds at most one state per
-- known group, plus the start's.

-- Flights are single legs (Data/Forever/Flights.lua), and the game sells tickets over them. A ticket
-- from A to B may fly through other flight points without landing (each extra leg saves
-- FLIGHT_CHAIN_SAVING of that leg's time), except that when there is a direct leg from A to B the game always
-- sells that one, however much quicker a chain would be. So a state in the air remembers the
-- ticket's origin and whether it is still its first leg: the ticket can end (land, walk on, reach the
-- goal) at a point only if it is that first leg or has no direct leg from its origin to that point.
-- Otherwise it must go on, or the plan lands earlier and takes a new ticket from there. And the player
-- doesn't choose a ticket's stops: for a destination with no direct leg the game sells its own quickest chain,
-- so a ticket that flies through other points is only one if it is that chain (a route the game wouldn't
-- sell, say one avoiding a dear leg, has to be bought as separate tickets, with no through-ticket saving).

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

-- Is there a direct flight leg from a to b in this graph? (Built on first use.)
local function hasDirectLeg(graph, a, b)
    if not graph.directLegs then
        graph.directLegs = {}
        for from, steps in pairs(graph.adjacency) do
            for _, step in ipairs(steps) do
                if step.method == "taxi" then
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
-- The quickest chain of legs from `origin` to each flight point in the graph (each leg after the first
-- less the chain saving, a fraction of the leg): the route the game sells a ticket along. Built per origin on first use.
local function gameTicketTimes(graph, origin)
    graph.ticketTimes = graph.ticketTimes or {}
    local times = graph.ticketTimes[origin]
    if times then return times end
    times = {}
    local saving = addon.FLIGHT_CHAIN_SAVING
    local best, heap = { [origin .. "|0"] = 0 }, {}
    heapPush(heap, { 0, { id = origin, started = false } })
    while #heap > 0 do
        local item = heapPop(heap)
        local d, node = item[1], item[2]
        local key = node.id .. (node.started and "|1" or "|0")
        if best[key] == d then
            if node.started and (times[node.id] == nil or d < times[node.id]) then times[node.id] = d end
            for _, step in ipairs(graph.adjacency[node.id] or {}) do
                if step.method == "taxi" then
                    -- The saving is a fraction of the leg, so it can't take more than the leg costs; the max
                    -- is only a guard: a leg that ran the clock backwards would make a loop cheaper every
                    -- lap, and this search would never finish (it did, with a flat 10 s and 8 s legs).
                    local nd = math.max(d, d + step.cost * (1 - (node.started and saving or 0)))
                    local nkey = step.to .. "|1"
                    if best[nkey] == nil or nd < best[nkey] then
                        best[nkey] = nd
                        heapPush(heap, { nd, { id = step.to, started = true } })
                    end
                end
            end
        end
    end
    graph.ticketTimes[origin] = times
    return times
end

local function canLand(graph, node)
    if node.origin == nil or node.single then return true end
    if hasDirectLeg(graph, node.origin, node.id) then return false end
    -- A ticket through other points is the game's chain to here, or not a ticket at all.
    local game = gameTicketTimes(graph, node.origin)[node.id]
    return game ~= nil and node.d - node.startD <= game + 1e-6
end

-- What taking `step` from `node` can mean: a list of { cost, origin, single, through, fare } for a flight
-- (a flight after a flight can go on along the same ticket, or land and start a new one), or nil when the
-- step can't be taken from here (a non-flight step from part way along a ticket that can't end).
-- opts: oneTicket (never land part way and start a new ticket), fareFactor (what the player pays as a
-- fraction of base fares: a number, or a function of the flight point the ticket is bought at).
local function expandStep(graph, node, step, d, opts)
    if step.method ~= "taxi" then
        if node.origin and not canLand(graph, node) then return nil end
        return { { d + step.cost, nil, nil, nil, 0 } }
    end
    -- A ticket's fare is its legs' fares at the discount of the flight point it was bought at: this
    -- ticket's own origin if the flight goes on along it, or here if it starts a new one.
    local function fareBoughtAt(origin)
        local factor = opts.fareFactor or 1
        if type(factor) == "function" then factor = factor(origin) end
        return (step.fare or 0) * factor
    end
    local base = d + step.cost
    if not node.origin then
        return { { base, node.id, true, false, fareBoughtAt(node.id), d } }
    end
    -- (Never below d: see gameTicketTimes -- the clock must not run backwards.)
    local options = { { math.max(d, d + step.cost * (1 - addon.FLIGHT_CHAIN_SAVING)), node.origin, false, true, fareBoughtAt(node.origin), node.startD } }
    if canLand(graph, node) and not opts.oneTicket then
        options[#options + 1] = { base, node.id, true, false, fareBoughtAt(node.id), d }
    end
    return options
end

local function phaseKey(state)
    if next(state) == nil then return "" end
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
local phaseMemo, phaseMemoGeneration = {}, nil

-- A node's phase group and side (or false), looked up once per World build: walking a container's
-- ancestors for every edge the search relaxes was a large share of its time.
local function phaseOf(nodeID)
    local World = addon.World
    if phaseMemoGeneration ~= World.generation then
        phaseMemo, phaseMemoGeneration = {}, World.generation
    end
    local memo = phaseMemo[nodeID]
    if memo == nil then
        local group, side = World:GetPhase(World:GetNodeContainer(nodeID))
        memo = group and { group, side } or false
        phaseMemo[nodeID] = memo
    end
    return memo
end

local SWITCHED = "~"          -- in a phase state: this route has used its one phase switch

local function nextPhaseState(state, step)
    local need = step.inPhase
    if need then
        local current = state[need[1]]
        if current ~= nil and current ~= need[2] then return nil end
    end
    local memo = phaseOf(step.to)
    if not memo then return state end
    local group, side = memo[1], memo[2]
    local current = state[group]
    if current == nil or current == side then return state end

    if step.overridesPhase and not state[SWITCHED] then
        for _, g in ipairs(step.overridesPhase) do
            if g == group then
                local copy = {}
                for k, v in pairs(state) do copy[k] = v end
                copy[group], copy[SWITCHED] = side, 1
                return copy
            end
        end
    end
    return nil
end

-- A label is one way of having got to a search state (a node, and what came with arriving: the
-- phases, and the ticket in the air): the seconds it took and the fare paid. A state keeps every label
-- that isn't beaten. Without a budget only time matters, so the quickest label is the only one. With a
-- budget, a slower label survives if it paid less, so that the quickest route within the player's
-- money is found exactly, not just the quickest overall.
local function addLabel(store, label, useFare)
    local list = store[label.key]
    if not list then
        list = {}
        store[label.key] = list
    end
    for _, other in ipairs(list) do
        if other.d <= label.d and (not useFare or other.paid <= label.paid) then return false end
    end
    for i = #list, 1, -1 do
        local other = list[i]
        if label.d <= other.d and (not useFare or label.paid <= other.paid) then
            other.dead = true
            table.remove(list, i)
        end
    end
    list[#list + 1] = label
    return true
end

-- The search itself: labels are settled quickest first, and visit(label) is called for each; it returns
-- true to stop, and that label is returned. opts as for FindPath.
local function run(graph, startID, initialPhase, opts, visit)
    local useFare, budget = opts.budget ~= nil, opts.budget
    local startState = {}
    for k, v in pairs(initialPhase or {}) do startState[k] = v end

    local store, heap = {}, {}
    local startPK = phaseKey(startState)
    local startKey = startID .. "|" .. startPK
    local start = { key = startKey, pk = startPK, id = startID, state = startState, d = 0, paid = 0 }
    addLabel(store, start, useFare)
    heapPush(heap, { 0, start })

    -- Abilities usable from anywhere seed the search alongside the start node.
    for _, ability in ipairs(graph.anywhere or {}) do
        local state = nextPhaseState(startState, { to = ability.to, overridesPhase = ability.source.overridesPhase })
        if state then
            local pk = phaseKey(state)
            local label = {
                key = ability.to .. "|" .. pk, pk = pk, id = ability.to, state = state, d = ability.cost, paid = 0,
                prev = start, step = { from = startID, to = ability.to, cost = ability.cost,
                                       method = ability.method, source = ability.source },
            }
            if addLabel(store, label, useFare) then heapPush(heap, { label.d, label }) end
        end
    end

    -- One way of reaching step.to: skipped without allocating anything when (no budget: only time
    -- matters) a label at least as quick already holds that state.
    local function relax(label, step, state, pk, d, paid, origin, single, through, startD)
        local key = step.to .. "|" .. pk .. (origin and ("|air:" .. origin .. (single and "1" or "0")) or "")
        if not useFare then
            local list = store[key]
            if list then
                for i = 1, #list do
                    if list[i].d <= d then return end
                end
            end
        end
        local next = {
            key = key, pk = pk, id = step.to, state = state,
            d = d, paid = paid, origin = origin, single = single, startD = startD,
            prev = label, step = step, through = through,
        }
        if addLabel(store, next, useFare) then heapPush(heap, { d, next }) end
    end

    while #heap > 0 do
        local label = heapPop(heap)[2]
        if not label.dead and not label.done then
            label.done = true
            if visit(label) then return label end
            local labelPK = label.pk
            for _, step in ipairs(graph.adjacency[label.id] or {}) do
                local state = nextPhaseState(label.state, step)
                if state then
                    local pk = state == label.state and labelPK or phaseKey(state)
                    if step.method ~= "taxi" and not label.origin then
                        -- The common case (walking, portals, a flight not in the air): no ticket to track.
                        relax(label, step, state, pk, label.d + step.cost, label.paid, nil, nil, nil, nil)
                    else
                        for _, option in ipairs(expandStep(graph, label, step, label.d, opts) or {}) do
                            local paid = label.paid + (option[5] or 0)
                            if not budget or paid <= budget then
                                relax(label, step, state, pk, option[1], paid, option[2], option[3], option[4], option[6])
                            end
                        end
                    end
                end
            end
        end
    end
end

-- graph: from TravelGraph:Build. goalID is a node id, or a list of node ids to reach
-- whichever is cheapest ("the nearest ley line"). initialPhase: optional { group = side }.
-- opts (optional): oneTicket = never land part way along a flight and take a new ticket (what the game
-- would sell for a destination when clicked at a flight master, not the best plan); fareFactor = the
-- player's fare discount (1 for none); budget = copper the player has: the route is then the quickest
-- whose flights they can pay for (nil ignores fares).
-- Returns { cost = seconds, fare = copper the flights cost, goal = the node reached, steps = { {from,
-- to, cost, method, source}, ... } } or nil when no goal can be reached.
function Pathfinder:FindPath(graph, startID, goalID, initialPhase, opts)
    opts = opts or {}
    local goals = {}
    if type(goalID) == "table" then
        for _, id in ipairs(goalID) do goals[id] = true end
    else
        goals[goalID] = true
    end

    local goal = run(graph, startID, initialPhase, opts, function(label)
        return goals[label.id] and canLand(graph, label)
    end)
    if not goal then return nil end

    local steps = {}
    local label = goal
    while label.prev do
        local step = label.step
        if label.through then                       -- goes on along the ticket the last flight began
            local copy = {}
            for k, v in pairs(step) do copy[k] = v end
            copy.through = true
            step = copy
        end
        table.insert(steps, 1, step)
        label = label.prev
    end
    return { cost = goal.d, fare = goal.paid, goal = goal.id, steps = steps }
end

-- The cheapest cost in seconds from startID to every node it can reach, as
-- { [nodeID] = seconds }: one search for a whole list of results. opts as for FindPath. The second
-- result is what the flights on each of those routes cost, { [nodeID] = copper }.
function Pathfinder:FindCosts(graph, startID, initialPhase, opts)
    local costs, fares = {}, {}
    run(graph, startID, initialPhase, opts or {}, function(label)
        if costs[label.id] == nil and canLand(graph, label) then
            costs[label.id], fares[label.id] = label.d, label.paid
        end
        return false
    end)
    costs[startID], fares[startID] = nil, nil
    return costs, fares
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
            and (step.method == "walk" or (step.method == "taxi" and step.through))
        if joins and step.method == "walk" then
            local World = addon.World
            joins = not World:IsMilestone(last.to)
                and World:GetNodeContainer(last.to) == World:GetNodeContainer(step.to)
        end
        if joins then
            last.to = step.to
            last.cost = last.cost + step.cost * (1 - (step.method == "taxi" and addon.FLIGHT_CHAIN_SAVING or 0))
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
