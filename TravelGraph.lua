-- TravelGraph.lua
-- Builds optimised adjacency list for pathfinding
-- Nodes kept in hierarchical structure (traversalGroup → nodeID)
local addonName, addon = ...

local TravelGraph = {}
TravelGraph.__index = TravelGraph

local rawNodes = addon.Nodes or {}
local rawEdges = addon.Edges or {}

-- Constants
local TRAVEL_COSTS = addon.TRAVEL_COSTS
local WALK_SPEED = addon.WALK_SPEED
local FLY_SPEED = addon.FLY_SPEED
local MAP_SCALE = addon.MAP_SCALE
local MAX_AUTO_EDGE_DISTANCE = addon.MAX_AUTO_EDGE_DISTANCE
local NO_FLY_MAPS = addon.NO_FLY_MAPS

-----------------------------------------------------------
-- STANDALONE HELPERS (used during graph building)
-----------------------------------------------------------

local function getNodeByID(graph, nodeID)
    for traversalGroup, groupData in pairs(graph.nodes) do
        if groupData[nodeID] then
            return groupData[nodeID]
        end
    end
    return nil
end

local function calculateDistanceToCoords(node, targetMapID, targetX, targetY)
    -- Validate inputs first
    if not node.x or not node.y or not targetX or not targetY then
        return nil
    end

    -- Both on same map? Use map-space distance (fast path)
    if node.mapID == targetMapID then
        local dx = (targetX - node.x) * MAP_SCALE
        local dy = (targetY - node.y) * MAP_SCALE
        return math.sqrt(dx * dx + dy * dy)
    end

    -- Different maps — try world coordinates
    local nodeVector = CreateVector2D(node.x, node.y)
    local targetVector = CreateVector2D(targetX, targetY)

    if not nodeVector or not targetVector then
        return nil
    end

    local success1, pos1 = C_Map.GetWorldPosFromMapPos(node.mapID, nodeVector)
    local success2, pos2 = C_Map.GetWorldPosFromMapPos(targetMapID, targetVector)

    -- If EITHER conversion failed, these maps don't share a world coordinate system
    if not pos1 or not pos2 then
        return nil
    end

    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Keep the old node-to-node version (used during graph building)
local function calculateDistance(node1, node2)
    return calculateDistanceToCoords(node1, node2.mapID, node2.x, node2.y)
end

local function calculateTravelTime(node1, node2, method)
    if not node1.x or not node1.y or not node2.x or not node2.y then
        return TRAVEL_COSTS[method] or 30
    end

    -- Walking only works on same map
    if method == "walk" and node1.mapID ~= node2.mapID then
        return nil
    end

    local success1, pos1 = C_Map.GetWorldPosFromMapPos(node1.mapID, CreateVector2D(node1.x, node1.y))
    local success2, pos2 = C_Map.GetWorldPosFromMapPos(node2.mapID, CreateVector2D(node2.x, node2.y))

    if not pos1 or not pos2 then
        return TRAVEL_COSTS[method] or 30
    end

    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local distance = math.sqrt(dx * dx + dy * dy)

    local speed = (method == "fly") and FLY_SPEED or WALK_SPEED
    local time = math.ceil(distance / speed / 5) * 5
    return math.max(10, math.min(300, time))
end

local function edgeExists(node, targetID)
    for _, edge in ipairs(node.edges) do
        if edge.to == targetID then
            return true
        end
    end
    return false
end

-----------------------------------------------------------
-- TRAVELGRAPH METHODS
-----------------------------------------------------------
function TravelGraph:CalculateDistanceToCoords(node, mapID, x, y)
    return calculateDistanceToCoords(node, mapID, x, y)
end

function TravelGraph:GetNodeByID(nodeID)
    return getNodeByID(self, nodeID)
end

function TravelGraph:GetNodesByTraversalGroup(traversalGroup)
    local result = {}
    if not self.nodes[traversalGroup] then
        return result
    end
    for nodeID, node in pairs(self.nodes[traversalGroup]) do
        table.insert(result, node)
    end
    return result
end

function TravelGraph:GetNodesByMapID(mapID)
    local result = {}
    for traversalGroup, groupData in pairs(self.nodes) do
        for nodeID, node in pairs(groupData) do
            if node.mapID == mapID then
                table.insert(result, node)
            end
        end
    end
    return result
end

-----------------------------------------------------------
-- GRAPH BUILDING
-----------------------------------------------------------

local function buildGraph(hierarchicalNodes, edgeList)
    local graph = {
        nodes = {},
        nodeCount = 0,
        edgeCount = 0
    }

    -- Initialize hierarchy
    for traversalGroup, groupData in pairs(hierarchicalNodes) do
        graph.nodes[traversalGroup] = {}
        for nodeID, nodeData in pairs(groupData) do
            graph.nodes[traversalGroup][nodeID] = {
                id = nodeID,
                name = nodeData.name,
                category = nodeData.category,
                traversalGroup = traversalGroup,
                faction = nodeData.faction,
                mapID = nodeData.mapID,
                x = nodeData.x,
                y = nodeData.y,
                edges = {}
            }
            graph.nodeCount = graph.nodeCount + 1
        end
    end

    -- Process edges
    for _, edgeData in ipairs(edgeList) do
        local fromNode = getNodeByID(graph, edgeData.from)
        local toNode = getNodeByID(graph, edgeData.to)

        if not fromNode then
            print(string.format("[Mapzeroth] WARNING: Edge from '%s' unknown", edgeData.from))
        elseif not toNode then
            print(string.format("[Mapzeroth] WARNING: Edge to '%s' unknown", edgeData.to))
        else
            local cost = edgeData.cost
            if not cost then
                if edgeData.method == "walk" or edgeData.method == "fly" then
                    cost = calculateTravelTime(fromNode, toNode, edgeData.method)
                end
                cost = cost or TRAVEL_COSTS[edgeData.method] or 10
            end
            table.insert(fromNode.edges, {
                to = edgeData.to,
                method = edgeData.method,
                cost = cost,
                requirements = edgeData.requirements
            })
            graph.edgeCount = graph.edgeCount + 1

            if edgeData.oneway ~= true then
                table.insert(toNode.edges, {
                    to = edgeData.from,
                    method = edgeData.method,
                    cost = cost,
                    requirements = edgeData.requirements
                })
                graph.edgeCount = graph.edgeCount + 1
            end
        end
    end

    return graph
end

-----------------------------------------------------------
-- AUTO-TRAVERSAL EDGES
-----------------------------------------------------------

local function injectAutoTraversalEdges(graph)
    local edgesAdded = 0

    for traversalGroup, groupData in pairs(graph.nodes) do
        local nodesInGroup = {}

        -- Collect all nodes with valid coords in this traversal group
        for nodeID, node in pairs(groupData) do
            if node.x and node.y then
                table.insert(nodesInGroup, node)
            end
        end

        -- Connect them if they're within range, regardless of mapID
        for i = 1, #nodesInGroup do
            for j = i + 1, #nodesInGroup do
                local n1, n2 = nodesInGroup[i], nodesInGroup[j]
                if not edgeExists(n1, n2.id) and not edgeExists(n2, n1.id) then
                    local distance = calculateDistance(n1, n2)
                    if distance and distance <= MAX_AUTO_EDGE_DISTANCE then
                        -- NEW: Determine correct method based on no-fly zones
                        local method = "fly"
                        if NO_FLY_MAPS[n1.mapID] or NO_FLY_MAPS[n2.mapID] then
                            method = "walk"
                        end

                        local cost = calculateTravelTime(n1, n2, method)
                        if cost then
                            table.insert(n1.edges, {
                                to = n2.id,
                                method = method,
                                cost = cost
                            })
                            table.insert(n2.edges, {
                                to = n1.id,
                                method = method,
                                cost = cost
                            })
                            edgesAdded = edgesAdded + 2
                        end
                    end
                end
            end
        end
    end

    if addon.DEBUG then
        print(string.format("[Mapzeroth] Added %d automatic traversal edges", edgesAdded))
    end

end

-----------------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------------

local instance = buildGraph(rawNodes, rawEdges)
setmetatable(instance, TravelGraph)
addon.TravelGraph = instance
injectAutoTraversalEdges(addon.TravelGraph)

if addon.DEBUG then
    print(string.format("[Mapzeroth] Loaded %d nodes and %d edges", addon.TravelGraph.nodeCount,
        addon.TravelGraph.edgeCount))
end

function addon:GetTravelNode(nodeID)
    return self.TravelGraph:GetNodeByID(nodeID)
end

function addon:GetTravelTime(node1, node2, method)
    return calculateTravelTime(node1, node2, method)
end