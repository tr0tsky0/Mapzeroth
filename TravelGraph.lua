local addonName, addon = ...

-- Builds the adjacency list the pathfinder searches, for one player context:
--   * authored edges (addon.Edges) the player meets the requirements for;
--   * auto-generated walk edges between nodes that share the SAME container
--     (zone-scoped, never across a zone border or into an interior/sub-area);
--   * auto-generated fly edges continent-wide, but only between nodes whose
--     containers allow flying (none exist in Forever);
--   * "Anywhere -> Node" abilities (teleports), kept separately for the
--     pathfinder to seed the search with.
-- Costs are seconds and already include the loading-screen tax.

local TravelGraph = {}
addon.TravelGraph = TravelGraph

local worldPosCache = {}

-- Yards between two nodes. Uses the client's world-space projection, so nodes
-- on different maps compare correctly. Replaceable for tests.
function TravelGraph.DistanceProvider(a, b)
    local function worldPos(node)
        local cached = not node.nocache and worldPosCache[node.id]
        if cached then return cached[1], cached[2] end
        local _, pos = C_Map.GetWorldPosFromMapPos(node.mapID, CreateVector2D(node.x, node.y))
        if not pos then return nil end
        local x, y = pos:GetXY()
        if not node.nocache then worldPosCache[node.id] = { x, y } end   -- the player moves: never cache
        return x, y
    end

    local ax, ay = worldPos(a)
    local bx, by = worldPos(b)
    if not (ax and bx) then return nil end
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

-- How much longer the real walk is than the straight line, averaged over the
-- two ends (a city and open country differ a lot).
local function pathFactor(a, b)
    local factors = addon.PathFactors or {}
    local fa = factors[a.mapID] or addon.DEFAULT_PATH_FACTOR
    local fb = factors[b.mapID] or addon.DEFAULT_PATH_FACTOR
    return (fa + fb) / 2
end

local function loadingCost(edge, ctx)
    local screens = edge.loadingScreens
    if screens == nil then
        screens = addon.DEFAULT_LOADING_SCREENS[edge.method] or 0
    end
    return screens * ctx.loadingScreenTax
end

-- A city with a map of its own is walled: getting in or out on foot goes through its gate. Each such city
-- has entrance nodes on its own map (inside) and on the zone's (outside), captured at the same gate. Walking
-- edges never join an inside node to an outside one; the two sides of a gate are joined by a zero-cost walk,
-- so a route says "walk to the gates" and not a straight line through the wall. (A city with no entrance
-- pair on record isn't walled, so it can't be cut off. Dalaran's map is its zone's, so it isn't either.)
local walls
local function cityWalls()
    if walls then return walls end
    walls = {}
    local gates = {}
    for _, node in ipairs(addon.Nodes and addon.Nodes.Pois or {}) do
        if node.kind == "entrance" and node.city then
            gates[node.city] = gates[node.city] or {}
            table.insert(gates[node.city], node)
        end
    end
    for key, city in pairs(addon.Cities or {}) do
        local inner, outer = {}, {}
        for _, node in ipairs(gates[key] or {}) do table.insert(node.mapID == city.mapID and inner or outer, node) end
        if #inner > 0 and #outer > 0 then walls[city.mapID] = { city = key, inner = inner, outer = outer } end
    end
    return walls
end

-- Which walled city a node or position is inside (its map is the city's own), or nil.
local function insideCity(place)
    local wall = place and cityWalls()[place.mapID]
    return wall and wall.city or nil
end

-- Which faction a flight point belongs to, when only one faction's flights touch it ("Alliance" or
-- "Horde"; nil for a point both use, or one no faction-bound flight reaches). A flight master of the other
-- faction is hostile and can't be spoken to, so no flight into or out of it is ever used.
local flightOwners
function addon:GetFlightOwner(nodeID)
    if not flightOwners then
        local seen = {}
        for _, edge in ipairs(addon.Edges or {}) do
            local faction = edge.method == "flight" and edge.requirements and edge.requirements.faction
            if faction then
                for _, id in ipairs({ edge.from, edge.to }) do
                    seen[id] = seen[id] or {}
                    seen[id][faction] = true
                end
            end
        end
        flightOwners = {}
        for id, factions in pairs(seen) do
            local only, count = nil, 0
            for faction in pairs(factions) do only, count = faction, count + 1 end
            if count == 1 then flightOwners[id] = only end
        end
    end
    return flightOwners[nodeID]
end

function TravelGraph:Build(ctx)
    local World = addon.World
    local adjacency = {}

    local function link(from, to, cost, method, source, overridesPhase)
        local list = adjacency[from]
        if not list then
            list = {}
            adjacency[from] = list
        end
        list[#list + 1] = {
            from = from, to = to, cost = cost, method = method,
            source = source, overridesPhase = overridesPhase,
            fare = source and source.fare,           -- copper, for a flight
        }
    end

    -- You can't fly to a flight point you haven't found, and until a flight master's
    -- window has told us, we don't know: better to leave a flight out than to promise
    -- one that can't be taken. (A context with no flightNodeFound applies no such rule.)
    -- A flight into or out of a hostile faction's flight master can't be taken, whatever else the edge says
    -- (placeholders and hand-written edges may have no faction of their own).
    local function hostile(edge)
        if edge.method ~= "flight" or not ctx.faction then return false end
        local a, b = addon:GetFlightOwner(edge.from), addon:GetFlightOwner(edge.to)
        return (a ~= nil and a ~= ctx.faction) or (b ~= nil and b ~= ctx.faction)
    end

    local function unfound(edge, toID)
        return edge.method == "flight" and ctx.flightNodeFound and ctx.flightNodeFound(toID) ~= true
    end

    -- Authored edges. The reverse direction is generated here, carrying the same requirements
    -- and phase override, unless the reverse is authored itself: flight times differ by
    -- direction (Lakeshire -> Ironforge is 357 s, Ironforge -> Lakeshire 201 s), and generating
    -- a reverse next to an authored one would let the search take the cheaper of the two.
    local authored = {}
    for _, edge in ipairs(addon.Edges or {}) do
        authored[edge.from .. "|" .. edge.to .. "|" .. edge.method] = true
    end
    for _, edge in ipairs(addon.Edges or {}) do
        if addon:MeetsRequirements(edge.requirements, ctx) and not hostile(edge) then
            local a, b = World:GetNode(edge.from), World:GetNode(edge.to)
            local cost = edge.cost
            if cost == nil and a and b then
                local dist = TravelGraph.DistanceProvider(a, b)
                local speed = addon:GetGroundSpeed(World:GetNodeContainer(a.id), ctx)
                cost = dist and (dist * pathFactor(a, b) / speed)
            elseif cost and edge.method == "flight" then
                cost = cost / addon:GetFlightSpeedMultiplier(ctx)
            end
            if cost then
                cost = cost + loadingCost(edge, ctx)
                if not unfound(edge, edge.to) then
                    link(edge.from, edge.to, cost, edge.method, edge, edge.overridesPhase)
                end
                local reverseAuthored = authored[edge.to .. "|" .. edge.from .. "|" .. edge.method]
                if not edge.oneway and not reverseAuthored and not unfound(edge, edge.from) then
                    link(edge.to, edge.from, cost, edge.method, edge, edge.overridesPhase)
                end
            end
        end
    end

    -- Walking: every pair of nodes in one container.
    World:ForEachContainer(function(container)
        local list = container.nodes
        if #list < 2 then return end
        local speed = addon:GetGroundSpeed(container, ctx)
        for i = 1, #list - 1 do
            for j = i + 1, #list do
                local dist = insideCity(list[i]) == insideCity(list[j]) and TravelGraph.DistanceProvider(list[i], list[j])
                if dist then
                    local cost = dist * pathFactor(list[i], list[j]) / speed
                    link(list[i].id, list[j].id, cost, "walk")
                    link(list[j].id, list[i].id, cost, "walk")
                end
            end
        end
    end)

    -- The two sides of each city gate: a step through it takes no time of its own.
    for _, wall in pairs(cityWalls()) do
        for _, inner in ipairs(wall.inner) do
            local nearest, best
            for _, outer in ipairs(wall.outer) do
                local dist = TravelGraph.DistanceProvider(inner, outer) or 0
                if not best or dist < best then nearest, best = outer, dist end
            end
            if nearest and World:GetNode(inner.id) and World:GetNode(nearest.id) then
                link(inner.id, nearest.id, 0, "walk")
                link(nearest.id, inner.id, 0, "walk")
            end
        end
    end

    -- Flying: continent-wide, only between flyable, outdoor nodes.
    local flyable = {}
    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            local c = World:GetNodeContainer(node.id)
            if c and World:GetFlag(c, "fly") and not World:GetFlag(c, "indoor") then
                local continent = World:GetContinent(c)
                local key = continent and continent.path
                if key then
                    flyable[key] = flyable[key] or {}
                    table.insert(flyable[key], node)
                end
            end
        end
    end
    for _, nodes in pairs(flyable) do
        for i = 1, #nodes - 1 do
            for j = i + 1, #nodes do
                local dist = TravelGraph.DistanceProvider(nodes[i], nodes[j])
                if dist and dist <= addon.MAX_AUTO_EDGE_DISTANCE then
                    local cost = dist / (addon.FLY_SPEED or 50)
                    link(nodes[i].id, nodes[j].id, cost, "fly")
                    link(nodes[j].id, nodes[i].id, cost, "fly")
                end
            end
        end
    end

    -- Teleports and the like: available from wherever the player stands.
    local anywhere = {}
    for _, entry in ipairs(addon:GetKnownTeleports(ctx)) do
        if World:GetNode(entry.to) then
            local screens = entry.loadingScreens or addon.DEFAULT_LOADING_SCREENS[entry.method] or 0
            anywhere[#anywhere + 1] = {
                to = entry.to,
                cost = entry.cost + screens * ctx.loadingScreenTax,
                method = entry.method,
                source = entry.ability,
            }
        end
    end

    return { adjacency = adjacency, anywhere = anywhere }
end

-- Adds the player's own position to a graph as a node that can only be left: it walks to
-- every node in its container, the way any two nodes there are joined. `start` is
-- { id, mapID, x, y }; its id must be unique to that spot (distances are cached by id).
-- Returns false if we have no nodes on the start's map to walk to.
-- A place that isn't one of our nodes but somewhere to go (the player's map waypoint): { id, mapID, x, y }.
-- Walking edges lead to it from every node in its container, and from the start if that is in the same one.
function TravelGraph:AddDestination(graph, ctx, dest, start)
    local container = addon.World:GetContainerForMap(dest.mapID)
    if not container then return false end
    local speed = addon:GetGroundSpeed(container, ctx)
    local function link(from)
        local dist = TravelGraph.DistanceProvider(from, dest)
        if not dist then return end
        local list = graph.adjacency[from.id]
        if not list then list = {}; graph.adjacency[from.id] = list end
        list[#list + 1] = { from = from.id, to = dest.id, method = "walk", cost = dist * pathFactor(from, dest) / speed }
    end
    for _, node in ipairs(container.nodes) do
        if insideCity(node) == insideCity(dest) then link(node) end
    end
    if start and addon.World:GetContainerForMap(start.mapID) == container and insideCity(start) == insideCity(dest) then link(start) end
    return true
end

function TravelGraph:AddStart(graph, ctx, start)
    local container = addon.World:GetContainerForMap(start.mapID)
    if not container then return false end
    local speed = addon:GetGroundSpeed(container, ctx)
    local list = graph.adjacency[start.id]
    if not list then list = {}; graph.adjacency[start.id] = list end
    for _, node in ipairs(container.nodes) do
        local dist = insideCity(node) == insideCity(start) and TravelGraph.DistanceProvider(start, node)
        if dist then
            list[#list + 1] = {
                from = start.id, to = node.id, method = "walk",
                cost = dist * pathFactor(start, node) / speed,
            }
        end
    end
    return true
end
