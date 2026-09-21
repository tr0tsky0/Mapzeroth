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

-- Rebuilds the tree from addon.Nodes / addon.Containers. Safe to call again.
function World:Build()
    containers, nodes, nodeContainer, duplicates = {}, {}, {}, {}

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
            end
        end
    end
end

function World:GetNode(nodeID)
    return nodes[nodeID]
end

function World:GetContainer(path)
    return containers[path]
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

function World:GetStats()
    local nodeCount, containerCount, continents = 0, 0, {}
    for _ in pairs(nodes) do nodeCount = nodeCount + 1 end
    for path, c in pairs(containers) do
        if path ~= ROOT then containerCount = containerCount + 1 end
        if c.depth == 1 then continents[#continents + 1] = c.path end
    end
    table.sort(continents)
    return nodeCount, containerCount, continents
end
