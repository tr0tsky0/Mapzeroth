local addonName, addon = ...

-- The container tree: World -> Continent -> Zone -> Interior/sub-area.
-- The tree is derived from each node's dotted `container` path
-- ("kalimdor.teldrassil.ruttheran"); addon.Containers only supplies flag
-- overrides. A flag is resolved by walking up to the nearest container that
-- sets it, so the root ("") holds the ruleset defaults.

local World = {}
addon.World = World

local ROOT = ""

local containers = {}      -- path -> container
local nodes = {}           -- nodeID -> node
local nodeContainer = {}   -- nodeID -> container
local duplicates = {}      -- nodeIDs seen more than once
local mapContainer = {}    -- uiMapID -> the container most of that map's nodes are in
local mapPhased = {}       -- uiMapID -> { container, ... }: its outdoor phase-tagged containers (one per side)
local phaseGroups = {}     -- phaseGroup -> { [side] = phaseMap }: the map whose art tells that side is live

local function parentPath(path)
    return path:match("^(.*)%.[^.]+$") or ROOT
end

local function ensureContainer(path)
    local c = containers[path]
    if c then return c end

    c = {
        path = path,
        own = addon.Containers and addon.Containers[path] or nil,
        children = {},
        nodes = {},
        depth = 0,
    }
    containers[path] = c

    if path ~= ROOT then
        local parent = ensureContainer(parentPath(path))
        c.parent = parent
        c.depth = parent.depth + 1
        parent.children[#parent.children + 1] = c
    end
    return c
end

-- Rebuilds the tree from addon.Nodes / addon.Containers. Safe to call again. Bumps
-- World.generation, so anything caching work derived from the tree (TravelGraph's geometry
-- pass) knows to redo it rather than serve a stale cache.
function World:Build()
    containers, nodes, nodeContainer, duplicates, mapContainer = {}, {}, {}, {}, {}
    mapPhased, phaseGroups = {}, {}
    World.generation = (World.generation or 0) + 1
    local mapCounts = {}    -- uiMapID -> { [container] = node count }

    ensureContainer(ROOT)
    -- Containers that carry flags but no nodes of their own still exist.
    for path in pairs(addon.Containers or {}) do
        ensureContainer(path)
    end

    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            if nodes[node.id] then
                duplicates[#duplicates + 1] = node.id
            else
                nodes[node.id] = node
                local c = ensureContainer(node.container or ROOT)
                c.nodes[#c.nodes + 1] = node
                nodeContainer[node.id] = c
                if node.mapID then
                    local counts = mapCounts[node.mapID]
                    if not counts then counts = {}; mapCounts[node.mapID] = counts end
                    counts[c] = (counts[c] or 0) + 1
                end
            end
        end
    end

    -- A city map sits inside its zone's container, so a map can be looked up by the
    -- container most of its nodes are in (ties go to the earlier path, to stay stable). A place on a map
    -- (the player, a waypoint) is out in the open unless the map has nothing but interiors, so a container
    -- that isn't indoor wins over an indoor one whatever the counts: Stormwind's portal rooms outnumber its
    -- streets, and a waypoint in the Trade District was being placed inside them.
    for mapID, counts in pairs(mapCounts) do
        local best, bestOutdoor
        for c, n in pairs(counts) do
            local function better(current) return not current or n > counts[current] or (n == counts[current] and c.path < current.path) end
            if better(best) then best = c end
            if not World:GetFlag(c, "indoor") and better(bestOutdoor) then bestOutdoor = c end
        end
        mapContainer[mapID] = bestOutdoor or best
        for c in pairs(counts) do
            if c.own and c.own.phaseGroup and not World:GetFlag(c, "indoor") then
                local list = mapPhased[mapID] or {}
                mapPhased[mapID] = list
                list[#list + 1] = c
            end
        end
    end

    -- Phase groups (Zidormi's zones, Modern only): each side of a group is a container tagged
    -- { phaseGroup, phaseSide = the map art id of that side, phaseMap = the map whose art shows it }.
    for _, c in pairs(containers) do
        local own = c.own
        if own and own.phaseGroup then
            phaseGroups[own.phaseGroup] = phaseGroups[own.phaseGroup] or {}
            phaseGroups[own.phaseGroup][own.phaseSide] = own.phaseMap
        end
    end
end

function World:GetNode(nodeID)
    return nodes[nodeID]
end

-- Tests only.
function World:GetContainer(path)
    return containers[path]
end

-- The container a map's nodes live in (nil for a map we have no nodes on). A map split between the sides of
-- a phase group (Darkshore past and present are one map) gives the side in `phases` ({ group = side }, the
-- player's live phases) when it names one.
function World:GetContainerForMap(mapID, phases)
    local c = mapContainer[mapID]
    local group, side = self:GetPhase(c)
    if phases and group and phases[group] ~= nil and phases[group] ~= side then
        for _, other in ipairs(mapPhased[mapID] or {}) do
            local g, s = self:GetPhase(other)
            if g == group and s == phases[group] then return other end
        end
    end
    return c
end

-- The side the player is on in each phase group, as { group = side }, for the search to start from (see
-- Pathfinder.lua). mapArtID(mapID) is the client's art id for a map (ctx.mapArtID). A group is left out when
-- the client can't tell: no answer, or more than one side's art showing (past and present Tirisfal are two maps,
-- each always with its own art); the search then takes whichever side a route first enters.
function World:LivePhases(mapArtID)
    local live = {}
    if not mapArtID then return live end
    for group, sides in pairs(phaseGroups) do
        local found, count = nil, 0
        for side, phaseMap in pairs(sides) do
            if mapArtID(phaseMap) == side then found, count = side, count + 1 end
        end
        if count == 1 then live[group] = found end
    end
    return live
end

-- Tests and the validator: { group = { [side] = phaseMap } }.
function World:GetPhaseGroups()
    return phaseGroups
end

-- Calls fn(node) for every node.
function World:ForEachNode(fn)
    for _, node in pairs(nodes) do
        fn(node)
    end
end

function World:GetNodeContainer(nodeID)
    return nodeContainer[nodeID]
end

-- Is this node one a person marks a route by: a crossing from one zone to the next, or a
-- city's entrance?
function World:IsMilestone(nodeID)
    local node = nodes[nodeID]
    return (type(nodeID) == "string" and nodeID:find("^BORDER_") ~= nil) or (node ~= nil and node.kind == "entrance")
end

function World:GetDuplicateNodeIDs()
    return duplicates
end

-- Depth 1 is the continent; returns nil for the root itself.
function World:GetContinent(container)
    while container and container.depth > 1 do
        container = container.parent
    end
    if container and container.depth == 1 then
        return container
    end
end

-- Resolves an inherited flag for a container (or path) by walking up the tree.
-- Returns nil if nothing on the way up sets it.
function World:GetFlag(container, flag)
    if type(container) == "string" then
        container = containers[container]
    end
    while container do
        local own = container.own
        if own and own[flag] ~= nil then
            return own[flag]
        end
        container = container.parent
    end
end

-- The {phaseGroup, phaseSide} a container belongs to, or nil if it isn't phased.
function World:GetPhase(container)
    if type(container) == "string" then
        container = containers[container]
    end
    while container do
        local own = container.own
        if own and own.phaseGroup then
            return own.phaseGroup, own.phaseSide
        end
        container = container.parent
    end
end

-- Calls fn(container) for every container in path order (parents before
-- children); the root is skipped.
function World:ForEachContainer(fn)
    local paths = {}
    for path in pairs(containers) do
        if path ~= ROOT then paths[#paths + 1] = path end
    end
    table.sort(paths)
    for _, path in ipairs(paths) do
        fn(containers[path])
    end
end
