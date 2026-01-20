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

-----------------------------------------------------------
-- FIND NODE IN HIERARCHICAL GRAPH
-----------------------------------------------------------
-- Helper function to locate a node anywhere in the hierarchy.
-- Used by Dijkstra and augmented graph building.

local function findNodeInHierarchy(hierarchicalGraph, nodeIdentifier)
    -- Fast path: try as direct ID lookup
    for traversalGroup, groupData in pairs(hierarchicalGraph.nodes) do
        if groupData and groupData[nodeIdentifier] then
            return groupData[nodeIdentifier], nodeIdentifier
        end
    end

    -- Slow path: search by name (case-insensitive)
    local searchName = nodeIdentifier:lower()
    for traversalGroup, groupData in pairs(hierarchicalGraph.nodes) do
        if groupData then
            for nodeID, nodeData in pairs(groupData) do
                if nodeData.name and nodeData.name:lower() == searchName then
                    return nodeData, nodeID
                end
            end
        end
    end

    return nil, nil
end

-----------------------------------------------------------
-- BUILD AUGMENTED GRAPH WITH SYNTHETIC EDGES
-----------------------------------------------------------
-- This keeps the hierarchy intact and just adds synthetic edges.
-- Synthetic edges get attached to their source nodes.

local function buildAugmentedGraph(baseGraph, syntheticEdges)
    local augmented = {
        nodes = {}
    }

    -- Copy references to all base nodes (still hierarchical)
    for traversalGroup, groupData in pairs(baseGraph.nodes) do
        augmented.nodes[traversalGroup] = {}
        for nodeID, node in pairs(groupData) do
            -- Shallow copy the node to preserve the original
            local nodeCopy = {
                id = node.id,
                name = node.name,
                traversalGroup = node.traversalGroup,
                faction = node.faction or "NEUTRAL",
                mapID = node.mapID,
                x = node.x,
                y = node.y,
                edges = {}
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
    local endNode, resolvedEndID = findNodeInHierarchy(augmented, endNodeID)

    -- Validate inputs
    if not startNode then
        return nil, string.format("Start node '%s' not found", startNodeID)
    end
    if not endNode then
        return nil, string.format("End node '%s' not found", endNodeID)
    end

    endNodeID = resolvedEndID

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
                    if addon:CheckEdgeRequirements(edge) then

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
                                        itemType = edge.itemType,
                                        spellID = edge.spellID
                                    }
                                    pq:push(neighborID, newDist)
                                end
                            end
                        elseif not neighborNode then
                            if addon.DEBUG then
                                print(string.format(
                                    "[Mapzeroth] WARNING: Edge from '%s' points to non-existent node '%s'", currentID,
                                    neighborID))
                            end
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
-- OPTIMIZE CONSECUTIVE MOVEMENT STEPS
-----------------------------------------------------------
function addon:OptimizeConsecutiveMovement(steps)
    if not steps or #steps == 0 then
        return steps
    end

    local optimized = {}
    local i = 1

    while i <= #steps do
        local step = steps[i]

        -- Check if this is a collapsible movement step
        if step.method == "walk" or step.method == "fly" then
            -- Find end of consecutive same-method chain
            local chainEnd = i
            while chainEnd < #steps and steps[chainEnd + 1].method == step.method do
                chainEnd = chainEnd + 1
            end

            if chainEnd > i then
                -- Try to collapse it
                local startStep = steps[i]
                local endStep = steps[chainEnd]

                -- Get start node
                local startNode = addon:GetTravelNode(startStep.nodeID)
                local canOptimize = false
                local directTime, endNodeID, collapsedStep

                if startNode then
                    -- Get end node (either regular node or waypoint)
                    if endStep.nodeID == "_WAYPOINT_DESTINATION" then
                        -- Waypoint destination
                        endNodeID = "_WAYPOINT_DESTINATION"
                        directTime = addon:GetTravelTime(startNode, endStep.waypointData, step.method)
                        canOptimize = (directTime ~= nil)
                    else
                        -- Regular node
                        endNodeID = endStep.nodeID
                        local endNode = addon:GetTravelNode(endNodeID)
                        if endNode then
                            directTime = addon:GetTravelTime(startNode, endNode, step.method)
                            canOptimize = (directTime ~= nil)
                        end
                    end
                end

                if canOptimize then
                    if addon.DEBUG then
                        print(string.format("[Mapzeroth] Optimizing chain: %s -> %s, directTime=%.0fs", startNode.id,
                            endNodeID, directTime))
                    end
                    -- Create collapsed step
                    collapsedStep = {
                        num = #optimized + 1,
                        method = step.method,
                        destination = endStep.destination,
                        time = directTime,
                        nodeID = endNodeID,
                        collapsedFrom = chainEnd - i + 1
                    }

                    -- Preserve waypoint data if this is a waypoint destination
                    if endStep.waypointData then
                        collapsedStep.waypointData = endStep.waypointData
                    end

                    table.insert(optimized, collapsedStep)
                else
                    -- Can't optimize, keep original chain
                    for j = i, chainEnd do
                        steps[j].num = #optimized + 1
                        table.insert(optimized, steps[j])
                    end
                end

                i = chainEnd + 1
            else
                -- Single step, keep as-is
                step.num = #optimized + 1
                table.insert(optimized, step)
                i = i + 1
            end
        else
            -- Non-movement step (portal, hearthstone, etc.), keep as-is
            step.num = #optimized + 1
            table.insert(optimized, step)
            i = i + 1
        end
    end

    -- Calculate new total cost
    local newCost = 0
    for _, step in ipairs(optimized) do
        newCost = newCost + (step.time or 0)
    end

    return optimized, newCost
end

-----------------------------------------------------------
-- BUILD SYNTHETIC EDGES FOR A GIVEN SEARCH
-----------------------------------------------------------
-- Given player position (optional), abilities, and optional waypoint,
-- create temporary edges to add to the graph.
-- This keeps the main graph pure while allowing dynamic routing.

function addon:BuildSyntheticEdges(playerLocation, playerAbilities, optionalWaypoint)
    local synthetic = {
        nodes = {},
        edges = {}
    }
    local VIRTUAL_START = "_PLAYER_POSITION"

    -- maxCooldownValue is in hours, multiply by 3600 for seconds
    local maxCooldownSeconds = MapzerothDB.settings.maxCooldownValue * 3600
    local acceptableCooldown = false

    synthetic.nodes[VIRTUAL_START] = true

    -- Collect all coordinate-based destinations (hearthstone, waypoint, etc.)
    local coordDestinations = {}

    if optionalWaypoint then
        local method = "walk"
        if not addon.NO_FLY_MAPS[optionalWaypoint.mapID] then
            method = "fly"
        end
        table.insert(coordDestinations, {
            nodeID = "_WAYPOINT_DESTINATION",
            coords = optionalWaypoint,
            method = method,
            fromPlayer = false
        })
    end

    if playerAbilities then
        for _, ability in ipairs(playerAbilities) do
            acceptableCooldown = not ability.cooldown or ability.cooldown <= maxCooldownSeconds

            if ability.isHearthstone and ability.hearthstone then
                local cost = ability.castTime

                -- Prefer longer cooldowns
                if ability.cooldown and ability.cooldown > 0 then
                    cost = cost - (ability.cooldown / 100000)
                end

                if acceptableCooldown then
                    table.insert(coordDestinations, {
                        nodeID = "_HEARTHSTONE_DESTINATION",
                        coords = ability.hearthstone,
                        method = "hearthstone",
                        fromPlayer = true,
                        cost = cost,
                        abilityName = ability.name,
                        itemID = ability.itemID,
                        itemType = ability.type
                    })
                end

                -- Multi-destination teleports
            elseif ability.destinations then
                for _, dest in ipairs(ability.destinations) do
                    local destNode = self:GetTravelNode(dest)
                    if destNode then
                        local cost = ability.castTime

                        -- Prefer longer cooldowns
                        if ability.cooldown and ability.cooldown > 0 then
                            cost = cost - (ability.cooldown / 100000)
                        end

                        if acceptableCooldown then
                            table.insert(synthetic.edges, {
                                from = VIRTUAL_START,
                                to = dest,
                                method = "teleport",
                                cost = cost,
                                abilityName = ability.name,
                                destinationName = destNode.name,
                                isSynthetic = true,
                                itemID = ability.itemID,
                                itemType = ability.type,
                                spellID = ability.spellID
                            })
                        end
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

                    if acceptableCooldown then
                        table.insert(synthetic.edges, {
                            from = VIRTUAL_START,
                            to = ability.destination,
                            method = "teleport",
                            cost = cost,
                            abilityName = ability.name,
                            isSynthetic = true,
                            itemID = ability.itemID,
                            itemType = ability.type,
                            spellID = ability.spellID
                        })
                    end
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
                itemType = dest.type
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

    -----------------------------------------------------------
    -- ADD WALKING/FLYING EDGES TO NEARBY NODES
    -----------------------------------------------------------
    -- Only if valid player location (nil in instances)

    if playerLocation then
        local MAX_PLAYER_RANGE = 2.0

        for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
            for nodeID, node in pairs(groupData) do
                if node.mapID == playerLocation.mapID and node.x and node.y and not node.interior then
                    local dx = node.x - playerLocation.x
                    local dy = node.y - playerLocation.y
                    local dist = math.sqrt(dx * dx + dy * dy)

                    if dist <= MAX_PLAYER_RANGE then
                        local travelTime, travelMethod = addon:CalculateTravelToNode(dist, playerLocation.mapID)
                        table.insert(synthetic.edges, {
                            from = VIRTUAL_START,
                            to = nodeID,
                            method = travelMethod,
                            cost = travelTime,
                            isSynthetic = true
                        })
                    end
                end
            end
        end
    else
        -- No location (instance, special map, etc.) - skip walking edges
        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: No location data (possibly in instance), using abilities only")
        end
    end

    return synthetic
end
