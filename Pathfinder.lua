-- Pathfinder.lua
-- Dijkstra's algorithm implementation for travel routing
-- Works with hierarchical graph structure (traversalGroup → nodeID → node)
local addonName, addon = ...

-----------------------------------------------------------
-- UTILITY: Count table entries
-----------------------------------------------------------

local function tableCount(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-----------------------------------------------------------
-- PRIORITY QUEUE (Min-Heap Implementation)
-----------------------------------------------------------

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue:new()
    local obj = {
        heap = {},
        size = 0
    }
    setmetatable(obj, PriorityQueue)
    return obj
end

function PriorityQueue:push(item, priority)
    self.size = self.size + 1
    self.heap[self.size] = {
        item = item,
        priority = priority
    }
    self:bubbleUp(self.size)
end

function PriorityQueue:pop()
    if self.size == 0 then
        return nil
    end

    local min = self.heap[1]
    self.heap[1] = self.heap[self.size]
    self.heap[self.size] = nil
    self.size = self.size - 1

    if self.size > 0 then
        self:bubbleDown(1)
    end

    return min.item, min.priority
end

function PriorityQueue:bubbleUp(index)
    while index > 1 do
        local parentIndex = math.floor(index / 2)
        if self.heap[index].priority >= self.heap[parentIndex].priority then
            break
        end
        self.heap[index], self.heap[parentIndex] = self.heap[parentIndex], self.heap[index]
        index = parentIndex
    end
end

function PriorityQueue:bubbleDown(index)
    while true do
        local leftChild = index * 2
        local rightChild = index * 2 + 1
        local smallest = index

        if leftChild <= self.size and self.heap[leftChild].priority < self.heap[smallest].priority then
            smallest = leftChild
        end
        if rightChild <= self.size and self.heap[rightChild].priority < self.heap[smallest].priority then
            smallest = rightChild
        end

        if smallest == index then
            break
        end

        self.heap[index], self.heap[smallest] = self.heap[smallest], self.heap[index]
        index = smallest
    end
end

function PriorityQueue:isEmpty()
    return self.size == 0
end

local METHOD_DISPLAY_TEXT = {
    portal = "Take portal to",
    ship = "Take ship to",
    tram = "Take tram to",
    flight = "Take flight path to",
    fly = "Fly to",
    walk = "Walk to",
    teleport = "Teleport to",
    hearthstone = "Hearth to",
    racial = "Use" -- Will be "Use Mole Machine"
}

-----------------------------------------------------------
-- FIND NODE IN HIERARCHICAL GRAPH
-----------------------------------------------------------
-- Helper function to locate a node anywhere in the hierarchy.
-- Used by Dijkstra and augmented graph building.

local function findNodeInHierarchy(hierarchicalGraph, nodeID)
    for traversalGroup, groupData in pairs(hierarchicalGraph.nodes) do
        if groupData and groupData[nodeID] then
            return groupData[nodeID]
        end
    end
    return nil
end

-----------------------------------------------------------
-- BUILD AUGMENTED GRAPH WITH SYNTHETIC EDGES
-----------------------------------------------------------
-- This keeps the hierarchy intact and just adds synthetic edges.
-- We create a new graph object with .nodes property that holds the hierarchy.
-- Synthetic edges get attached to their source nodes.

local function buildAugmentedGraph(baseGraph, syntheticEdges)
    local augmented = {
        nodes = {}
    }

    -- Copy references to all base nodes (still hierarchical)
    for traversalGroup, groupData in pairs(baseGraph.nodes) do
        augmented.nodes[traversalGroup] = {}
        for nodeID, node in pairs(groupData) do
            -- Shallow copy the node so we don't mutate the original
            local nodeCopy = {
                id = node.id,
                name = node.name,
                traversalGroup = node.traversalGroup,
                faction = node.faction or "NEUTRAL",
                mapID = node.mapID,
                x = node.x,
                y = node.y,
                edges = {} -- Fresh edge list
            }

            -- Copy all existing edges from the original
            for _, edge in ipairs(node.edges) do
                table.insert(nodeCopy.edges, edge)
            end

            augmented.nodes[traversalGroup][nodeID] = nodeCopy
        end
    end

    -- Create synthetic node containers if needed
    for syntheticID, _ in pairs(syntheticEdges.nodes or {}) do
        if not augmented.nodes._SYNTHETIC then
            augmented.nodes._SYNTHETIC = {}
        end
        augmented.nodes._SYNTHETIC[syntheticID] = {
            edges = {},
            id = syntheticID,
            name = syntheticID
        }
    end

    -- Add synthetic edges to their source nodes
    for _, edge in ipairs(syntheticEdges.edges or {}) do
        local sourceNode = findNodeInHierarchy(augmented, edge.from)

        if not sourceNode then
            -- Create synthetic node if it doesn't exist yet
            if not augmented.nodes._SYNTHETIC then
                augmented.nodes._SYNTHETIC = {}
            end
            augmented.nodes._SYNTHETIC[edge.from] = {
                edges = {},
                id = edge.from,
                name = edge.from
            }
            sourceNode = augmented.nodes._SYNTHETIC[edge.from]
        end

        table.insert(sourceNode.edges, edge)
    end

    return augmented
end

-----------------------------------------------------------
-- DIJKSTRA'S ALGORITHM
-----------------------------------------------------------

function addon:FindPath(startNodeID, endNodeID, playerAbilities, syntheticEdges)
    -- syntheticEdges is optional and contains temporary edges to add
    syntheticEdges = syntheticEdges or {
        nodes = {},
        edges = {}
    }

    local baseGraph = self.TravelGraph
    local augmented = buildAugmentedGraph(baseGraph, syntheticEdges)

    -- Find start and end nodes in the hierarchy
    local startNode = findNodeInHierarchy(augmented, startNodeID)
    local endNode = findNodeInHierarchy(augmented, endNodeID)

    -- Validate inputs
    if not startNode then
        return nil, string.format("Start node '%s' not found", startNodeID)
    end
    if not endNode then
        return nil, string.format("End node '%s' not found", endNodeID)
    end

    -- Early exit if start == end
    if startNodeID == endNodeID then
        return {startNodeID}, 0, {}
    end

    -- Run Dijkstra
    local distances = {}
    local previous = {}
    local visited = {}
    local pq = PriorityQueue:new()

    distances[startNodeID] = 0
    pq:push(startNodeID, 0)

    while not pq:isEmpty() do
        local currentID, currentDist = pq:pop()

        if not visited[currentID] then
            visited[currentID] = true

            if currentID == endNodeID then
                break
            end

            local currentNode = findNodeInHierarchy(augmented, currentID)
            if currentNode and currentNode.edges then
                for _, edge in ipairs(currentNode.edges) do
                    local neighborID = edge.to
                    local neighborNode = findNodeInHierarchy(augmented, neighborID)

                    if neighborNode then
                        local playerFaction = addon:GetPlayerFaction()
                        local nodeFaction = neighborNode.faction

                        local oppositeFaction
                        if playerFaction == "ALLIANCE" then
                            oppositeFaction = "HORDE"
                        else
                            oppositeFaction = "ALLIANCE"
                        end

                        -- Flight nodes are always accessible for pathfinding purposes
                        local isFlightNode = neighborNode.id:match("_FLIGHT$")

                        -- Only process if faction matches
                        if nodeFaction ~= oppositeFaction or isFlightNode then
                            -- Add loading tax for teleportation methods
                            local edgeCost = edge.cost
                            if edge.method == "portal" or edge.method == "teleport" or edge.method == "hearthstone" or
                                edge.method == "racial" then
                                if MapzerothDB and MapzerothDB.settings and MapzerothDB.settings.loadingScreenTax then
                                    edgeCost = edgeCost + MapzerothDB.settings.loadingScreenTax
                                end
                            end

                            local newDist = currentDist + edgeCost
                            local currentNeighborDist = distances[neighborID] or math.huge

                            if newDist < currentNeighborDist then
                                distances[neighborID] = newDist
                                previous[neighborID] = {
                                    node = currentID,
                                    method = edge.method,
                                    cost = edgeCost,
                                    abilityName = edge.abilityName,
                                    destinationName = edge.destinationName,
                                    isSynthetic = edge.isSynthetic,
                                    itemID = edge.itemID,
                                    spellID = edge.spellID
                                }
                                pq:push(neighborID, newDist)
                            end
                        end
                    elseif not neighborNode then
                        if addon.DEBUG then
                            print(string.format("[Mapzeroth] WARNING: Edge from '%s' points to non-existent node '%s'",
                                currentID, neighborID))
                        end
                    end
                end
            end
        end
    end

    -- No path found
    if (distances[endNodeID] or math.huge) == math.huge then
        return nil, string.format("No path found from '%s' to '%s'", startNodeID, endNodeID)
    end

    -- Reconstruct path
    local path = {}
    local current = endNodeID

    while current and current ~= startNodeID do
        table.insert(path, 1, current)
        local prev = previous[current]
        current = prev and prev.node
    end

    return path, distances[endNodeID], previous
end

-----------------------------------------------------------
-- UTILITY: Format Path for Display
-----------------------------------------------------------

function addon:FormatPath(path, totalCost, previous, atNode, initialTime, initialMethod, startNodeName, usedTeleport)
    if not path then
        return "No path found"
    end

    local fullCost = totalCost
    local output = {}
    local stepNum = 1

    if usedTeleport then
        local firstPrev = previous[path[1]]
        table.insert(output, string.format("[Mapzeroth] Route found (%.0f seconds):", fullCost))

        local methodText
        if firstPrev.destinationName then
            methodText = string.format("Use %s to %s", firstPrev.abilityName, firstPrev.destinationName)
        else
            methodText = firstPrev.abilityName or "Teleport to"
        end

        table.insert(output, string.format("  %d. %s (%.0fs)", stepNum, methodText, firstPrev.cost))
        stepNum = stepNum + 1
    else
        if not atNode then
            fullCost = fullCost + initialTime
        end

        table.insert(output, string.format("[Mapzeroth] Route found (%.0f seconds):", fullCost))

        if not atNode then
            local methodText = initialMethod == "fly" and "Fly to" or "Run to"
            table.insert(output, string.format("  %d. %s %s (%.0fs)", stepNum, methodText, startNodeName, initialTime))
            stepNum = stepNum + 1
        end
    end

    -- Add path steps
    for i = 1, #path do
        local nodeID = path[i]
        local node = self.TravelGraph:GetNodeByID(nodeID)

        if node then
            if i == 1 and usedTeleport then
            elseif i == 1 and atNode then
                table.insert(output, string.format("  %d. Start: %s", stepNum, node.name))
                stepNum = stepNum + 1
            elseif i > 1 then
                local prevInfo = previous[nodeID]
                local actionText
                if prevInfo.abilityName then
                    if prevInfo.destinationName then
                        actionText = string.format("Use %s to %s", prevInfo.abilityName, prevInfo.destinationName)
                    else
                        actionText = string.format("Use %s", prevInfo.abilityName)
                    end
                else
                    local methodText = METHOD_DISPLAY_TEXT[prevInfo.method] or "Travel to"
                    actionText = string.format("%s %s", methodText, node.name)
                end

                table.insert(output, string.format("  %d. %s (%.0fs)", stepNum, actionText, prevInfo.cost))
                stepNum = stepNum + 1
            end
        else
            -- Synthetic node (like _WAYPOINT_DESTINATION)
            if nodeID == "_WAYPOINT_DESTINATION" then
                local prevInfo = previous[nodeID]
                if prevInfo then
                    local actionText
                    if prevInfo.abilityName then
                        if prevInfo.destinationName then
                            actionText = string.format("Use %s to waypoint", prevInfo.abilityName)
                        else
                            actionText = string.format("Travel to waypoint")
                        end
                    else
                        local methodText = METHOD_DISPLAY_TEXT[prevInfo.method] or "Travel to"
                        actionText = string.format("%s waypoint", methodText)
                    end

                    table.insert(output, string.format("  %d. %s (%.0fs)", stepNum, actionText, prevInfo.cost))
                    stepNum = stepNum + 1
                end
            end
        end
    end

    return table.concat(output, "\n")
end

-----------------------------------------------------------
-- BUILD SYNTHETIC EDGES FOR A GIVEN SEARCH
-----------------------------------------------------------
-- Given player position, abilities, and optional waypoint,
-- create temporary edges to add to the graph.
-- This keeps the main graph pure while allowing dynamic routing.

function addon:BuildSyntheticEdges(playerLocation, playerAbilities, optionalWaypoint)
    local synthetic = {
        nodes = {},
        edges = {}
    }
    local VIRTUAL_START = "_PLAYER_POSITION"

    synthetic.nodes[VIRTUAL_START] = true

    -- Collect all coordinate-based destinations (hearthstone, waypoint, etc.)
    local coordDestinations = {}

    if optionalWaypoint then
        table.insert(coordDestinations, {
            nodeID = "_WAYPOINT_DESTINATION",
            coords = optionalWaypoint,
            method = "fly",
            fromPlayer = false
        })
    end

    if playerAbilities then
        for _, ability in ipairs(playerAbilities) do
            if ability.isHearthstone and ability.hearthstone then
                local cost = ability.castTime

                -- Prefer longer cooldowns
                if ability.cooldown and ability.cooldown > 0 then
                    cost = cost - (ability.cooldown / 100000)
                end

                table.insert(coordDestinations, {
                    nodeID = "_HEARTHSTONE_DESTINATION",
                    coords = ability.hearthstone,
                    method = "hearthstone",
                    fromPlayer = true,
                    cost = cost,
                    abilityName = ability.name,
                    itemID = ability.itemID
                })

                -- Multi-destination teleports
            elseif ability.destinations then
                for _, dest in ipairs(ability.destinations) do
                    local destNode = self:GetTravelNode(dest)
                    if destNode then
                        local cost = ability.castTime

                        -- Prefer shorter cooldowns
                        if ability.cooldown and ability.cooldown > 0 then
                            cost = cost + (ability.cooldown / 100000)
                        end

                        table.insert(synthetic.edges, {
                            from = VIRTUAL_START,
                            to = dest,
                            method = "teleport",
                            cost = cost,
                            abilityName = ability.name,
                            destinationName = destNode.name,
                            isSynthetic = true,
                            itemID = ability.itemID,
                            spellID = ability.spellID
                        })
                    end
                end

                -- Single-destination teleports
            elseif ability.destination then
                if self:GetTravelNode(ability.destination) then
                    local cost = ability.castTime

                    -- Prefer longer cooldowns
                    if ability.cooldown and ability.cooldown > 0 then
                        cost = cost - (ability.cooldown / 100000)
                    end

                    table.insert(synthetic.edges, {
                        from = VIRTUAL_START,
                        to = ability.destination,
                        method = "teleport",
                        cost = cost,
                        abilityName = ability.name,
                        isSynthetic = true,
                        itemID = ability.itemID,
                        spellID = ability.spellID
                    })
                end
            end
        end
    end

    -- Now handle all coordinate destinations uniformly
    for _, dest in ipairs(coordDestinations) do
        synthetic.nodes[dest.nodeID] = true

        if dest.fromPlayer then
            -- Player → coordinate destination (hearthstone)
            table.insert(synthetic.edges, {
                from = VIRTUAL_START,
                to = dest.nodeID,
                method = dest.method,
                cost = dest.cost,
                abilityName = dest.abilityName,
                isSynthetic = true,
                itemID = dest.itemID
            })
        end

        -- Coordinate destination → nearby nodes (both directions)
        for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
            for nodeID, node in pairs(groupData) do
                local travelTime, travelMethod = self:CalculateTravelToCoords(node, dest.coords.mapID, dest.coords.x,
                    dest.coords.y)

                if travelTime then
                    if dest.fromPlayer then
                        -- Hearthstone: edges FROM destination TO nodes
                        table.insert(synthetic.edges, {
                            from = dest.nodeID,
                            to = nodeID,
                            method = travelMethod,
                            cost = travelTime,
                            isSynthetic = true
                        })
                    else
                        -- Waypoint: edges FROM nodes TO destination
                        table.insert(synthetic.edges, {
                            from = nodeID,
                            to = dest.nodeID,
                            method = travelMethod,
                            cost = travelTime,
                            isSynthetic = true
                        })
                    end
                end
            end
        end
    end

    return synthetic
end
