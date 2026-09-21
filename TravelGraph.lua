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
        }
    end

    -- You can't fly to a flight point you haven't found, and until a flight master's
    -- window has told us, we don't know: better to leave a flight out than to promise
    -- one that can't be taken. (A context with no flightNodeFound applies no such rule.)
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
        if addon:MeetsRequirements(edge.requirements, ctx) then
            local a, b = World:GetNode(edge.from), World:GetNode(edge.to)
            local cost = edge.cost
            if cost == nil and a and b then
                local dist = TravelGraph.DistanceProvider(a, b)
                local speed = addon:GetGroundSpeed(World:GetNodeContainer(a.id), ctx)
                cost = dist and (dist * pathFactor(a, b) / speed)
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
                local dist = TravelGraph.DistanceProvider(list[i], list[j])
                if dist then
                    local cost = dist * pathFactor(list[i], list[j]) / speed
                    link(list[i].id, list[j].id, cost, "walk")
                    link(list[j].id, list[i].id, cost, "walk")
                end
            end
        end
    end)

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
function TravelGraph:AddStart(graph, ctx, start)
    local container = addon.World:GetContainerForMap(start.mapID)
    if not container then return false end
    local speed = addon:GetGroundSpeed(container, ctx)
    local list = graph.adjacency[start.id]
    if not list then list = {}; graph.adjacency[start.id] = list end
    for _, node in ipairs(container.nodes) do
        local dist = TravelGraph.DistanceProvider(start, node)
        if dist then
            list[#list + 1] = {
                from = start.id, to = node.id, method = "walk",
                cost = dist * pathFactor(start, node) / speed,
            }
        end
    end
    return true
end
