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

-- The player's own spots (start, map waypoint) are one-off ids: caching them would only grow the cache.
local function uncached(node)
    local id = node.id
    return node.nocache or (type(id) == "string" and (id:find("^YOU_") or id:find("^WAYPOINT_")))
end

local function worldPos(node)
    if not node.mapID then return nil end     -- a synthetic point built from an unplaceable sample
    local world = node.world                  -- the player's spot, already projected this tick (Navigation)
    if world then return world.x, world.y, world.continent end
    local nocache = uncached(node)
    local cached = not nocache and worldPosCache[node.id]
    if cached then return cached[1], cached[2], cached[3] end
    local continent, pos = C_Map.GetWorldPosFromMapPos(node.mapID, CreateVector2D(node.x, node.y))
    if not pos then return nil end
    local x, y = pos:GetXY()
    if not nocache then worldPosCache[node.id] = { x, y, continent } end   -- the player moves: never cache
    return x, y, continent
end

-- Yards between two nodes. Uses the client's world-space projection, so nodes
-- on different maps compare correctly. Replaceable for tests.
function TravelGraph.DistanceProvider(a, b)
    local ax, ay, ac = worldPos(a)
    local bx, by, bc = worldPos(b)
    if not (ax and bx) then return nil end
    -- World coordinates are per continent: Eversong and Hyjal can have the same x/y, yards apart on
    -- paper and two continents apart in fact. No distance at all is the honest answer between them.
    if ac ~= nil and bc ~= nil and ac ~= bc then return nil end
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
        screens = addon:Method(edge.method).screens
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
            local faction = edge.method == "taxi" and edge.requirements and edge.requirements.faction
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

-- A node the fly mesh can use: its container exists, allows flying and is outdoors. Returns the container.
-- A phase-tagged node (Zidormi's past or present) is flyable too: the search only lets a route into it on the
-- side the player is on (Pathfinder.lua), and the fly pass never joins two sides of one group (see below).
local function isFlyable(node)
    local World = addon.World
    local c = World:GetNodeContainer(node.id)
    if c and World:GetFlag(c, "fly") and not World:GetFlag(c, "indoor") then
        return c
    end
    return nil
end

-- Two containers that are different sides of one phase group: the same ground in two states, never
-- a flight apart (Zidormi is the way between them).
local function otherSide(a, b)
    local World = addon.World
    local groupA, sideA = World:GetPhase(a)
    if not groupA then return false end
    local groupB, sideB = World:GetPhase(b)
    return groupA == groupB and sideA ~= sideB
end

-- The geometry-only part of the graph: walk edges (container-scoped), city-gate joins and fly
-- edges (continent-wide). None of it depends on the player (ctx) -- only on node positions --
-- so it doesn't need computing at all client-side, ideally: node/edge data only ever changes
-- through a new version, so this can be generated once (via /mzr dumpgeometry, MapzerothDataTools'
-- Dev.lua) and shipped as Data/<ruleset>/Geometry.lua, the same way Flights.lua/Pois.lua are
-- generated from live client data rather than re-derived at runtime. addon.Geometry (if present
-- and its addon.GeometryMeta.nodeCount still matches the loaded node count -- a forgotten
-- regeneration after a data change is caught this way, not served silently) is used as-is, no
-- computation at all; otherwise this falls back to computing it live, once, cached (keyed on
-- World.generation, so a World:Build() invalidates it) rather than redone on every single route
-- request. Fly edges alone are an O(n^2) pairwise check per continent (Eastern Kingdoms has ~200
-- outdoor nodes); redoing that on every graph build -- which used to happen twice over for one
-- click, once to price the picker's sections and again to plan the chosen route -- is what
-- "script ran too long" was actually coming from, not the search itself.
--
-- Each entry is { to, dtf, kind } (a plain array, not named fields -- shipped-file size adds up
-- across thousands of edges): `dtf` is distance * path factor for a "walk" edge (ground speed is
-- the only ctx-dependent piece left, a single per-container divide applied cheaply in Build
-- below, not a reason to redo the O(n^2) distance pass), 0 for a "gate" edge (no time at any
-- speed), or the already-finished cost for a "fly" edge (FLY_SPEED is a flat constant, no
-- ctx-dependent piece at all).
local staticGeometry, staticGeneration

TravelGraph.staticBuildCount = 0    -- for tests: how many times the expensive geometry pass actually ran

local function buildStaticGeometry()
    TravelGraph.staticBuildCount = TravelGraph.staticBuildCount + 1
    local World = addon.World
    local geometry = {}

    local function link(from, to, dtf, kind)
        local list = geometry[from]
        if not list then list = {}; geometry[from] = list end
        list[#list + 1] = { to, dtf, kind }
    end

    -- Walking: every pair of nodes in one container.
    World:ForEachContainer(function(container)
        local list = container.nodes
        if #list < 2 then return end
        for i = 1, #list - 1 do
            for j = i + 1, #list do
                local dist = insideCity(list[i]) == insideCity(list[j]) and TravelGraph.DistanceProvider(list[i], list[j])
                if dist then
                    local dtf = dist * pathFactor(list[i], list[j])
                    link(list[i].id, list[j].id, dtf, "walk")
                    link(list[j].id, list[i].id, dtf, "walk")
                end
            end
        end
    end)

    -- The two sides of each city gate: a step through it takes no time of its own, at any speed.
    for _, wall in pairs(cityWalls()) do
        for _, inner in ipairs(wall.inner) do
            local nearest, best
            for _, outer in ipairs(wall.outer) do
                local dist = TravelGraph.DistanceProvider(inner, outer) or 0
                if not best or dist < best then nearest, best = outer, dist end
            end
            if nearest and World:GetNode(inner.id) and World:GetNode(nearest.id) then
                link(inner.id, nearest.id, 0, "gate")
                link(nearest.id, inner.id, 0, "gate")
            end
        end
    end

    -- Flying: continent-wide, only between flyable, outdoor nodes, and never between two sides of a phase group.
    local flyable = {}
    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            local c = isFlyable(node)
            if c then
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
        -- Every pair, however many nodes: the pass is cheap (positions are cached per node, so a pair is
        -- plain arithmetic; about 0.05 s for Modern's whole node set). It was once capped per continent
        -- (2026-09-23), but a continent over the cap got no fly edges at all, so a stale Geometry.lua
        -- made whole regions unreachable ("no route") to save time that was never being spent.
        for i = 1, #nodes - 1 do
            for j = i + 1, #nodes do
                local dist = not otherSide(World:GetNodeContainer(nodes[i].id), World:GetNodeContainer(nodes[j].id))
                    and TravelGraph.DistanceProvider(nodes[i], nodes[j])
                if dist and dist <= addon.MAX_AUTO_EDGE_DISTANCE then
                    local cost = dist / (addon.FLY_SPEED)
                    link(nodes[i].id, nodes[j].id, cost, "fly")
                    link(nodes[j].id, nodes[i].id, cost, "fly")
                end
            end
        end
    end

    return geometry
end

local function countNodes()
    local n = 0
    addon.World:ForEachNode(function() n = n + 1 end)
    return n
end

local function staticGeometryFor()
    if staticGeometry and staticGeneration == addon.World.generation then
        return staticGeometry
    end
    local shipped = addon.Geometry
    if shipped and addon.GeometryMeta and addon.GeometryMeta.nodeCount == countNodes() then
        staticGeometry = shipped
    else
        staticGeometry = buildStaticGeometry()
    end
    staticGeneration = addon.World.generation
    return staticGeometry
end

-- For /mzr dumpgeometry: always computes fresh (never the shipped file, even if one is loaded),
-- since the whole point of that command is to regenerate it.
function TravelGraph:BuildFreshGeometry()
    return buildStaticGeometry()
end

-- The static geometry as finished edge tables, per (World.generation, outdoor ground speed, indoor ground
-- speed): { [from] = { edge, ... } }. Ground speed depends on nothing in a context but whether the container is
-- indoors, so a context has two speeds at most and a session a handful of distinct keys (riding skill, forms).
-- Kept to a few entries, oldest evicted. Edges from this cache are SHARED by every graph built with the key and
-- are read-only: the search copies a step before changing it and nothing else touches one.
local MAX_EDGE_CACHES = 4
local edgeCaches, edgeCacheKeys = {}, {}
TravelGraph.materialiseCount = 0    -- for tests: how many times a geometry was turned into edge tables (cache misses)

-- What is true of a World generation whatever the context: the authored-edge set, and an outdoor and an
-- indoor container (nil where there is none) to ask ground speed of.
local worldFacts, worldFactsGeneration

local function factsForWorld()
    if worldFacts and worldFactsGeneration == addon.World.generation then return worldFacts end
    local World = addon.World
    local authored = {}
    for _, edge in ipairs(addon.Edges or {}) do
        authored[edge.from .. "|" .. edge.to .. "|" .. edge.method] = true
    end
    local outdoor, indoor
    World:ForEachContainer(function(container)
        if World:GetFlag(container, "indoor") then
            indoor = indoor or container
        else
            outdoor = outdoor or container
        end
    end)
    worldFacts = { authored = authored, outdoor = outdoor, indoor = indoor }
    worldFactsGeneration = addon.World.generation
    return worldFacts
end

-- The cached edge tables for this context's ground speeds, made on first use from the static geometry.
local function edgesFor(outdoorSpeed, indoorSpeed)
    local key = ("%d|%.6f|%.6f"):format(addon.World.generation, outdoorSpeed, indoorSpeed or 0)
    local cached = edgeCaches[key]
    if cached then return cached end

    TravelGraph.materialiseCount = TravelGraph.materialiseCount + 1
    local World = addon.World
    cached = {}
    for from, list in pairs(staticGeometryFor()) do
        local edges = {}
        local speed
        for _, e in ipairs(list) do
            local to, dtf, kind = e[1], e[2], e[3]
            if kind == "fly" then
                edges[#edges + 1] = { from = from, to = to, cost = dtf, method = "fly" }
            elseif kind == "gate" then
                edges[#edges + 1] = { from = from, to = to, cost = 0, method = "walk" }
            else
                speed = speed or (World:GetFlag(World:GetNodeContainer(from), "indoor") and indoorSpeed or outdoorSpeed)
                edges[#edges + 1] = { from = from, to = to, cost = dtf / speed, method = "walk" }
            end
        end
        cached[from] = edges
    end

    edgeCaches[key] = cached
    edgeCacheKeys[#edgeCacheKeys + 1] = key
    if #edgeCacheKeys > MAX_EDGE_CACHES then edgeCaches[table.remove(edgeCacheKeys, 1)] = nil end
    return cached
end

function TravelGraph:Build(ctx)
    local World = addon.World
    local adjacency = {}

    local function link(from, to, cost, method, source, overridesPhase, inPhase)
        local list = adjacency[from]
        if not list then
            list = {}
            adjacency[from] = list
        end
        list[#list + 1] = {
            from = from, to = to, cost = cost, method = method,
            source = source, overridesPhase = overridesPhase, inPhase = inPhase,
            fare = source and source.fare,           -- copper, for a flight
        }
    end

    -- You can't fly to a flight point you haven't found: ctx.flightUsable says which ones they can (see
    -- FlightKnowledge.Usable for the rule, and what "not known either way" counts as).
    -- A flight into or out of a hostile faction's flight master can't be taken, whatever else the edge says
    -- (placeholders and hand-written edges may have no faction of their own).
    local function hostile(edge)
        if edge.method ~= "taxi" or not ctx.faction then return false end
        local a, b = addon:GetFlightOwner(edge.from), addon:GetFlightOwner(edge.to)
        return (a ~= nil and a ~= ctx.faction) or (b ~= nil and b ~= ctx.faction)
    end

    local function unfound(edge, toID)
        return edge.method == "taxi" and not ctx.flightUsable(toID)
    end

    -- Authored edges. The reverse direction is generated here, carrying the same requirements
    -- and phase override, unless the reverse is authored itself: flight times differ by
    -- direction (Lakeshire -> Ironforge is 357 s, Ironforge -> Lakeshire 201 s), and generating
    -- a reverse next to an authored one would let the search take the cheaper of the two.
    local facts = factsForWorld()
    local authored = facts.authored
    for _, edge in ipairs(addon.Edges or {}) do
        if addon:MeetsRequirements(edge.requirements, ctx) and not hostile(edge) then
            local a, b = World:GetNode(edge.from), World:GetNode(edge.to)
            local cost = edge.cost
            if cost == nil and a and b then
                local dist = TravelGraph.DistanceProvider(a, b)
                local speed = addon:GetGroundSpeed(World:GetNodeContainer(a.id), ctx)
                cost = dist and (dist * pathFactor(a, b) / speed) or (edge.method == "walk" and addon.UNMEASURED_WALK_SECONDS or nil)
            elseif cost and edge.method == "taxi" then
                cost = cost / addon:GetFlightSpeedMultiplier(ctx)
            end
            if cost then
                cost = cost + loadingCost(edge, ctx)
                if not unfound(edge, edge.to) then
                    link(edge.from, edge.to, cost, edge.method, edge, edge.overridesPhase, edge.inPhase)
                end
                local reverseAuthored = authored[edge.to .. "|" .. edge.from .. "|" .. edge.method]
                if not edge.oneway and not reverseAuthored and not unfound(edge, edge.from) then
                    link(edge.to, edge.from, cost, edge.method, edge, edge.overridesPhase, edge.inPhase)
                end
            end
        end
    end

    -- Walking, city gates and flying: the cached geometry, as edge tables already finished for this context's
    -- ground speeds (the outdoor one and, if any container is indoors, the indoor one) and shared between
    -- graphs: appended by reference, never copied or changed.
    local outdoorSpeed = addon:GetGroundSpeed(facts.outdoor, ctx)
    local indoorSpeed = facts.indoor and addon:GetGroundSpeed(facts.indoor, ctx) or nil
    for from, edges in pairs(edgesFor(outdoorSpeed, indoorSpeed)) do
        local list = adjacency[from]
        if not list then
            list = {}
            adjacency[from] = list
        end
        for i = 1, #edges do list[#list + 1] = edges[i] end
    end

    -- Teleports and the like: available from wherever the player stands.
    local anywhere = {}
    for _, entry in ipairs(addon:GetKnownTeleports(ctx)) do
        if World:GetNode(entry.to) then
            local screens = entry.loadingScreens or addon:Method(entry.method).screens
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
    local World = addon.World
    local container = World:GetContainerForMap(dest.mapID, graph.phase)
    local function add(from, cost, method)
        local list = graph.adjacency[from.id]
        if not list then list = {}; graph.adjacency[from.id] = list end
        list[#list + 1] = { from = from.id, to = dest.id, method = method, cost = cost }
    end

    -- Flying to it: from any flyable, outdoor node within range, the same rule the fly mesh between
    -- nodes uses -- so "portal to Nordrassil, fly to the waypoint" is a route, and so is a waypoint on
    -- a map none of our nodes are on (walking has no node to start from there).
    local flyable = not container or (World:GetFlag(container, "fly") and not World:GetFlag(container, "indoor"))
    local flew = false
    if flyable then
        World:ForEachNode(function(node)
            if isFlyable(node) and insideCity(node) == insideCity(dest) then
                local dist = TravelGraph.DistanceProvider(node, dest)
                if dist and dist <= addon.MAX_AUTO_EDGE_DISTANCE then
                    add(node, dist / (addon.FLY_SPEED), "fly")
                    flew = true
                end
            end
        end)
    end

    if not container then return flew end
    local speed = addon:GetGroundSpeed(container, ctx)
    local function walk(from)
        local dist = TravelGraph.DistanceProvider(from, dest)
        if dist then add(from, dist * pathFactor(from, dest) / speed, "walk") end
    end
    for _, node in ipairs(container.nodes) do
        if insideCity(node) == insideCity(dest) then walk(node) end
    end
    if start and World:GetContainerForMap(start.mapID, graph.phase) == container and insideCity(start) == insideCity(dest) then walk(start) end
    return true
end

-- On a map split between phases the player walks among the nodes of the side they are on (graph.phase, the
-- live phases Journey:Build set).
function TravelGraph:AddStart(graph, ctx, start)
    local container = addon.World:GetContainerForMap(start.mapID, graph.phase)
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

    -- In the open where flying is allowed the player can also mount up and fly to any outdoor node in range, the
    -- same rule the fly mesh uses; but only for a flight worth the mount (at least MIN_FLY_SECONDS in the air), or
    -- a short walk would read as "fly".
    local World = addon.World
    if World:GetFlag(container, "fly") and not World:GetFlag(container, "indoor") then
        local flySpeed = addon.FLY_SPEED
        World:ForEachNode(function(node)
            if isFlyable(node) and insideCity(node) == insideCity(start) then
                local dist = TravelGraph.DistanceProvider(start, node)
                if dist and dist <= addon.MAX_AUTO_EDGE_DISTANCE and dist / flySpeed >= addon.MIN_FLY_SECONDS then
                    list[#list + 1] = {
                        from = start.id, to = node.id, method = "fly",
                        cost = addon.MOUNT_SECONDS + dist / flySpeed,
                    }
                end
            end
        end)
    end
    return true
end
