local addonName, addon = ...

-- Roads: walking along the road instead of in a straight line.
--
-- addon.RoadData (Data/Forever/Roads.lua, generated from the game's own terrain by tools/roads/gen_roads.py) holds
-- each continent's road centre-lines in world yards. They are a layer beside the travel graph, never part of it:
-- the pathfinder still walks node to node, and only two things ask for a road:
--   * /mzr dumpgeometry prices each walk between two nodes by its road (TravelGraph's buildStaticGeometry), so the
--     shipped Geometry.lua carries real walking distances, at no cost to routing;
--   * the map draws a walk step along the road (MapRoute).
--
-- The way: in choosing it, a yard of road scores 1 and a yard of open ground OFFROAD, a preference for roads (players
-- keep to them, and the road knows the bridges and passes a straight line doesn't). A walk is the best-scoring mix:
-- straight across open ground onto the road wherever it pays to join it, along the road, and off it again where it
-- pays to leave for the goal (at the angle that scores best, not square to the road); or, when no road helps,
-- straight there. So a goal off the road is walked to along the road as far as it goes the right way, then across.
-- What the walk costs in time is its real length, road and open ground alike: OFFROAD only picks the way.
-- The player picks OFFROAD on the settings page ("roadPreference", LEVELS below, from across country to roads);
-- the middle one, 1.8, follows Westfall's road from the Elwynn bridge through Sentinel Hill to Duskwood, 1.57 times
-- the straight line, where 1.4 walked straight down the river. Walk times shipped in Geometry.lua are always
-- worked out at the middle one, whatever the person running /mzr dumpgeometry has picked.
--
-- Each continent's graph is built the first time it is asked for: vertices joined where polylines share an end, and
-- a grid of segments for finding road near a point.

local RoadNet = {}
addon.RoadNet = RoadNet

-- In choosing the way, a yard of open ground scores this many yards of road, by the "roadPreference" setting.
RoadNet.LEVELS = { 1.25, 1.5, 1.8, 2.4, 3.5 }
RoadNet.DEFAULT_LEVEL = 3
RoadNet.MIN_WALK = 60        -- yards: a shorter walk is a straight line
RoadNet.MAX_SNAP = 600       -- yards: road farther than this from either end isn't joined

local CELL = 250             -- grid cell, yards

local graphs = {}

local function cellKey(cx, cy) return (cx + 20000) * 40000 + (cy + 20000) end

-- A graph's key is a continent (the terrain's roads, addon.RoadData) or "city:<mapID>" (a capital's own streets,
-- addon.CityPaths, in its map's coordinates: each point is put into the world through its map, so a city's streets
-- sit in the same yards as everything else but in a graph of their own, apart from roads above or around it).
local function build(key)
    local data, place
    local mapID = type(key) == "string" and tonumber(key:match("^city:(%d+)$"))
    if mapID then
        data = addon.CityPaths and addon.CityPaths[mapID]
        local spot = { mapID = mapID }
        place = function(x, y)
            spot.x, spot.y = x, y
            local wx, wy = addon.TravelGraph.WorldPosition(spot)
            return wx, wy
        end
    else
        data = addon.RoadData and addon.RoadData[key]
    end
    if not data then return false end
    local vx, vy, adj, index = {}, {}, {}, {}
    local sa, sb, grid = {}, {}, {}
    local failed = false
    local function vertex(x, y)
        local id = x .. ":" .. y                     -- the same point as given joins, before any placing
        local i = index[id]
        if not i then
            i = #vx + 1
            if place then
                local wx, wy = place(x, y)
                if not wx then failed = true; wx, wy = 0, 0 end
                x, y = wx, wy
            end
            vx[i], vy[i], adj[i] = x, y, {}
            index[id] = i
        end
        return i
    end
    for _, line in ipairs(data) do
        local prev = vertex(line[1], line[2])
        for k = 3, #line - 1, 2 do
            local cur = vertex(line[k], line[k + 1])
            if cur ~= prev then
                local d = math.sqrt((vx[cur] - vx[prev]) ^ 2 + (vy[cur] - vy[prev]) ^ 2)
                local a, b = adj[prev], adj[cur]
                a[#a + 1] = cur; a[#a + 1] = d
                b[#b + 1] = prev; b[#b + 1] = d
                local s = #sa + 1
                sa[s], sb[s] = prev, cur
                local x0, x1 = math.floor(math.min(vx[prev], vx[cur]) / CELL), math.floor(math.max(vx[prev], vx[cur]) / CELL)
                local y0, y1 = math.floor(math.min(vy[prev], vy[cur]) / CELL), math.floor(math.max(vy[prev], vy[cur]) / CELL)
                for cx = x0, x1 do
                    for cy = y0, y1 do
                        local key = cellKey(cx, cy)
                        local list = grid[key]
                        if not list then list = {}; grid[key] = list end
                        list[#list + 1] = s
                    end
                end
            end
            prev = cur
        end
    end
    if failed then return false end                  -- a city the client can't place (yet): no streets
    return { vx = vx, vy = vy, adj = adj, sa = sa, sb = sb, grid = grid }
end

local function graphFor(key)
    if key == nil then return nil end
    local g = graphs[key]
    if g == nil then
        g = build(key)
        graphs[key] = g
    end
    return g or nil
end

-- OFFROAD as the player has set it (or the middle level), and the shipped one.
function RoadNet:Offroad()
    local level = addon.Options and addon.Options:Get("roadPreference")
    return self.LEVELS[level] or self.LEVELS[self.DEFAULT_LEVEL]
end

function RoadNet:DefaultOffroad() return self.LEVELS[self.DEFAULT_LEVEL] end

-- For tests (a different RoadData): forget the built graphs.
function RoadNet:Reset() graphs = {} end

-- Every segment with some part within `radius` of (x, y) (by grid cell: a few more, never fewer).
local function segmentsNear(g, x, y, radius)
    local out, seen = {}, {}
    local x0, x1 = math.floor((x - radius) / CELL), math.floor((x + radius) / CELL)
    local y0, y1 = math.floor((y - radius) / CELL), math.floor((y + radius) / CELL)
    for cx = x0, x1 do
        for cy = y0, y1 do
            local list = g.grid[cellKey(cx, cy)]
            if list then
                for _, s in ipairs(list) do
                    if not seen[s] then seen[s] = true; out[#out + 1] = s end
                end
            end
        end
    end
    return out
end

-- The point q on the road from (ax, ay) to (bx, by) where coming across open ground from P and going on along the
-- road to b costs least: OFFROAD * |Pq| + |qb|. It lies past the foot of the perpendicular from P, towards b, by
-- (distance from the road) / sqrt(OFFROAD^2 - 1): joining at a slant, not square on. Returns qx, qy, the cost, and
-- how far along from a q is.
local function join(k, px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local L = math.sqrt(dx * dx + dy * dy)
    if L == 0 then
        return ax, ay, k * math.sqrt((px - ax) ^ 2 + (py - ay) ^ 2), 0
    end
    local ux, uy = dx / L, dy / L
    local foot = (px - ax) * ux + (py - ay) * uy
    local perp = math.abs((px - ax) * uy - (py - ay) * ux)
    local s = foot + perp / math.sqrt(k * k - 1)
    if s < 0 then s = 0 elseif s > L then s = L end
    local qx, qy = ax + ux * s, ay + uy * s
    return qx, qy, k * math.sqrt((px - qx) ^ 2 + (py - qy) ^ 2) + (L - s), s
end

-- The nearest point of road to (x, y), within MAX_SNAP: distance and the point.
local function nearest(g, x, y)
    local best, bx, by, bs
    for _, s in ipairs(segmentsNear(g, x, y, RoadNet.MAX_SNAP)) do
        local ax, ay = g.vx[g.sa[s]], g.vy[g.sa[s]]
        local dx, dy = g.vx[g.sb[s]] - ax, g.vy[g.sb[s]] - ay
        local l2 = dx * dx + dy * dy
        local t = l2 > 0 and ((x - ax) * dx + (y - ay) * dy) / l2 or 0
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        local px, py = ax + dx * t, ay + dy * t
        local d = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
        if d <= RoadNet.MAX_SNAP and (not best or d < best) then best, bx, by, bs = d, px, py, s end
    end
    return best, bx, by, bs
end

-- The nearest road to a world point: distance and the point on the road, or nil (none within MAX_SNAP).
function RoadNet:Nearest(continent, x, y)
    local g = graphFor(continent)
    if not g then return nil end
    local d, px, py = nearest(g, x, y)
    return d, px, py
end

-- Each continent's graph size, building them all (for /mzr roads).
function RoadNet:Stats()
    local out = {}
    for continent in pairs(addon.RoadData or {}) do
        local g = graphFor(continent)
        if g then out[continent] = { vertices = #g.vx, segments = #g.sa } end
    end
    for mapID in pairs(addon.CityPaths or {}) do
        local g = graphFor("city:" .. mapID)
        if g then out["city:" .. mapID] = { vertices = #g.vx, segments = #g.sa } end
    end
    return out
end

-- A small binary heap of (priority, vertex).
local function push(h, p, v)
    local n = #h + 1
    h[n] = { p, v }
    while n > 1 do
        local parent = math.floor(n / 2)
        if h[parent][1] <= h[n][1] then break end
        h[parent], h[n] = h[n], h[parent]
        n = parent
    end
end

local function pop(h)
    local top = h[1]
    local last = h[#h]
    h[#h] = nil
    if #h > 0 then
        h[1] = last
        local n, size = 1, #h
        while true do
            local l, r, m = 2 * n, 2 * n + 1, n
            if l <= size and h[l][1] < h[m][1] then m = l end
            if r <= size and h[r][1] < h[m][1] then m = r end
            if m == n then break end
            h[m], h[n] = h[n], h[m]
            n = m
        end
    end
    return top[1], top[2]
end

-- A city's walk: its streets are the only ways through (walls, water and buildings lie between them), so each end
-- joins the street nearest to it, and the walk keeps to the streets between: no open-ground shortcuts, and the
-- Walking routes setting doesn't come into it. Returns as Route does; nil when the streets don't join the two.
local function streetsOnly(g, ax, ay, bx, by, straight)
    local vx, vy, adj, sa, sb = g.vx, g.vy, g.adj, g.sa, g.sb
    local d1, p1x, p1y, s1 = nearest(g, ax, ay)
    local d2, p2x, p2y, s2 = nearest(g, bx, by)
    if not (d1 and d2) then return nil end
    local function from(px, py, v) return math.sqrt((vx[v] - px) ^ 2 + (vy[v] - py) ^ 2) end
    local best, bestPoints, bestVia
    if s1 == s2 then
        best = d1 + math.sqrt((p1x - p2x) ^ 2 + (p1y - p2y) ^ 2) + d2
        bestPoints = { { x = p1x, y = p1y }, { x = p2x, y = p2y } }
    end
    local goal = { [sa[s2]] = from(p2x, p2y, sa[s2]) + d2, [sb[s2]] = from(p2x, p2y, sb[s2]) + d2 }
    local dist, prev, heap, closed = {}, {}, {}, {}
    local function h(v) return math.sqrt((vx[v] - p2x) ^ 2 + (vy[v] - p2y) ^ 2) end
    for _, v in ipairs({ sa[s1], sb[s1] }) do
        local c = d1 + from(p1x, p1y, v)
        if not dist[v] or c < dist[v] then dist[v] = c; push(heap, c + h(v), v) end
    end
    while #heap > 0 do
        local f, u = pop(heap)
        if best and f >= best then break end
        if not closed[u] then
            closed[u] = true
            local du = dist[u]
            if goal[u] and (not best or du + goal[u] < best) then best, bestVia, bestPoints = du + goal[u], u, nil end
            local list = adj[u]
            for n = 1, #list, 2 do
                local v, w = list[n], list[n + 1]
                local nd = du + w
                if not closed[v] and (not dist[v] or nd < dist[v]) then
                    dist[v], prev[v] = nd, u
                    push(heap, nd + h(v), v)
                end
            end
        end
    end
    if not best then return nil end
    if not bestPoints then
        local chain, v = {}, bestVia
        while v do table.insert(chain, 1, v); v = prev[v] end
        bestPoints = { { x = p1x, y = p1y } }
        for _, c in ipairs(chain) do bestPoints[#bestPoints + 1] = { x = vx[c], y = vy[c] } end
        bestPoints[#bestPoints + 1] = { x = p2x, y = p2y }
    end
    return best, straight, bestPoints
end

-- The way from world point A to B on one continent when some road scores better than straight across: its length in
-- yards (A onto the road, along it, off it to B), the straight line's length, and the points to draw between A and
-- B ({ x, y } each: where it joins the road, along it, where it leaves). nil when no road helps.
-- `continent`: which graph, a continent or "city:<mapID>" (a city's walk keeps to its streets: streetsOnly).
function RoadNet:Route(continent, ax, ay, bx, by, k)
    k = k or self:Offroad()
    local straight = math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
    if straight < self.MIN_WALK then return nil end
    local g = graphFor(continent)
    if not g then return nil end
    if type(continent) == "string" then return streetsOnly(g, ax, ay, bx, by, straight) end
    local vx, vy, adj, sa, sb = g.vx, g.vy, g.adj, g.sa, g.sb
    local direct = k * straight
    local best, bestPoints, bestVia, bestExit = direct, nil, nil, nil

    -- Onto the road: every segment near A, joined towards each of its ends. A segment can also be joined and left
    -- again without reaching either end (both ends of the walk beside one stretch of road).
    local dist, prev, entry, heap, closed = {}, {}, {}, {}, {}
    local function h(v) return math.sqrt((vx[v] - bx) ^ 2 + (vy[v] - by) ^ 2) end
    local radius = math.min(self.MAX_SNAP, straight)
    for _, s in ipairs(segmentsNear(g, ax, ay, radius)) do
        local i, j = sa[s], sb[s]
        for pass = 1, 2 do
            local from, to = i, j
            if pass == 2 then from, to = j, i end
            local qx, qy, cost, along = join(k, ax, ay, vx[from], vy[from], vx[to], vy[to])
            if cost < direct and (not dist[to] or cost < dist[to]) then
                dist[to], entry[to], prev[to] = cost, { x = qx, y = qy }, nil
                push(heap, cost + h(to), to)
            end
            -- Left again on the same stretch, further along it towards `to`.
            local ox, oy, back, outAlong = join(k, bx, by, vx[to], vy[to], vx[from], vy[from])
            local L = cost - k * math.sqrt((ax - qx) ^ 2 + (ay - qy) ^ 2)     -- road from the join to `to`
            local segLen = along + L
            local outFromStart = segLen - outAlong
            if outFromStart > along then
                local total = k * math.sqrt((ax - qx) ^ 2 + (ay - qy) ^ 2) + (outFromStart - along)
                    + k * math.sqrt((bx - ox) ^ 2 + (by - oy) ^ 2)
                if total < best then
                    best, bestVia, bestExit = total, nil, nil
                    bestPoints = { { x = qx, y = qy }, { x = ox, y = oy } }
                end
            end
        end
    end

    -- Along the road, A*: at each vertex, and part way along each segment out of it, the way off to B is tried.
    while #heap > 0 do
        local f, u = pop(heap)
        if f >= best then break end
        if not closed[u] then
            closed[u] = true
            local du = dist[u]
            local off = du + k * h(u)
            if off < best then best, bestVia, bestExit, bestPoints = off, u, nil, nil end
            local list = adj[u]
            for n = 1, #list, 2 do
                local v, w = list[n], list[n + 1]
                -- Leaving part way along u -> v.
                local ox, oy, cost = join(k, bx, by, vx[v], vy[v], vx[u], vy[u])
                if du + cost < best then best, bestVia, bestExit, bestPoints = du + cost, u, { x = ox, y = oy }, nil end
                local nd = du + w
                if not closed[v] and (not dist[v] or nd < dist[v]) and nd < best then
                    dist[v], prev[v], entry[v] = nd, u, nil
                    push(heap, nd + h(v), v)
                end
            end
        end
    end
    if best >= direct then return nil end
    if not bestPoints then
        local chain = {}
        local v = bestVia
        while v do
            table.insert(chain, 1, v)
            if entry[v] then break end
            v = prev[v]
        end
        bestPoints = { entry[chain[1]] }
        for _, c in ipairs(chain) do bestPoints[#bestPoints + 1] = { x = vx[c], y = vy[c] } end
        if bestExit then bestPoints[#bestPoints + 1] = bestExit end
    end
    local length, px, py = 0, ax, ay
    for _, p in ipairs(bestPoints) do
        length = length + math.sqrt((p.x - px) ^ 2 + (p.y - py) ^ 2)
        px, py = p.x, p.y
    end
    length = length + math.sqrt((bx - px) ^ 2 + (by - py) ^ 2)
    return length, straight, bestPoints
end

-- The same between two places (nodes, or route points { mapID, x, y }), through their world positions.
-- Places the terrain's roads have nothing to do with: a capital's own map (its streets are buildings, not painted
-- road, and Undercity lies under Tirisfal's roads), and indoors. A capital on a zone's map (Dalaran, with an `area`)
-- is just part of that zone. A capital's walks go by its own streets where they have been drawn (CityPaths.lua);
-- otherwise they keep the measured city factors (PathFactors.lua).
local function containerOf(place)
    local World = addon.World
    return place.id and World and World.GetNodeContainer and World:GetNodeContainer(place.id) or nil
end

local function indoors(place)
    local container = containerOf(place)
    return container and addon.World:GetFlag(container, "indoor") and true or false
end

-- A place on a city's map its streets aren't for (CityPathsSkip: Undercity's ruins, drawn above its streets).
local function skipsStreets(place)
    local container = containerOf(place)
    return container and addon.CityPathsSkip and addon.CityPathsSkip[container.path] or false
end

local function offRoads(place)
    for _, city in pairs(addon.Cities or {}) do
        if city.mapID == place.mapID and not city.area then return true end
    end
    return indoors(place)
end

-- `k`: OFFROAD to choose with (the player's setting when nil). A walk with both ends on a capital's map goes by its
-- streets (when drawn); one with an end in a city, otherwise, or indoors, has none. Returns the way's length, the
-- straight line's, the points to draw, the continent, and drawOnly: true when the way is only to draw (a measured
-- city's streets), not to time the walk by.
function RoadNet:Between(a, b, k)
    if indoors(a) or indoors(b) then return nil end
    local key
    local streets = a.mapID and a.mapID == b.mapID and addon.CityPaths and addon.CityPaths[a.mapID]
        and not skipsStreets(a) and not skipsStreets(b)
    if streets then
        key = "city:" .. a.mapID
    elseif offRoads(a) or offRoads(b) then
        return nil
    end
    local ax, ay, ac = addon.TravelGraph.WorldPosition(a)
    local bx, by, bc = addon.TravelGraph.WorldPosition(b)
    if not (ax and bx) or ac == nil or ac ~= bc then return nil end
    local cost, straight, points = self:Route(key or ac, ax, ay, bx, by, k)
    -- A city whose walking was measured in game (PathFactors.lua) keeps that for its walking times: its streets are
    -- flat lines, and real city walking (stairs, ramps, corners) measured well above their length. They are drawn.
    local drawOnly = key ~= nil and addon.PathFactors and addon.PathFactors[a.mapID] ~= nil or false
    if cost then return cost, straight, points, ac, drawOnly end
end

-- The points to draw a walk through, with the road's way put in between each two: the path's own points stay
-- (they are where the step starts, turns and ends), and the road's are { world = { x, y, continent } }.
function RoadNet:Expand(path)
    if not (addon.RoadData and path and #path >= 2) then return path end
    local out = { path[1] }
    for i = 2, #path do
        local _, _, points, continent = self:Between(path[i - 1], path[i])
        if points then
            for _, p in ipairs(points) do
                out[#out + 1] = { world = { x = p.x, y = p.y, continent = continent } }
            end
        end
        out[#out + 1] = path[i]
    end
    return out
end
