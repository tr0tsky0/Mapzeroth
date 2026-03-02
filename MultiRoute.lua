-- MultiRoute.lua
-- Multi-destination routing: distance matrix builder + brute-force TSP solver.
-- Used by the Pet Trainer routing feature (and future multi-stop routes).
--
-- Flow:
--   1. BuildDistanceMatrixAsync  — runs FindPath for every pair of locations,
--                                  spread across frame ticks to avoid freezing
--   2. SolveTSP / SolveNearestNeighbour — find cheapest visit order
--   3. RouteMultiDestination     — entry point called by GUI buttons;
--                                  stitches per-leg steps into one master list
local addonName, addon = ...

-- How many Dijkstra pairs to compute per frame tick.
-- Lower = smoother client, longer wall-clock time.
-- At ~40ms per pair, 2 pairs/frame = ~80ms/frame = still interactive.
local MATRIX_BATCH_SIZE = 2
-----------------------------------------------------------
-- GET TOMTOM WAYPOINTS
-- Reads all active TomTom waypoints and returns them in
-- the standard pointList format: { name, mapID, x, y }
-- Returns nil + message if TomTom isn't loaded or has no waypoints.
-----------------------------------------------------------
function addon:GetTomTomWaypoints()
    if not TomTom or not TomTom.waypoints then
        return nil, "TomTom is not installed or has no waypoints table."
    end

    local points = {}

    for mapID, waypointsOnMap in pairs(TomTom.waypoints) do
        for _, waypointData in pairs(waypointsOnMap) do
            -- TomTom stores { [1]=mapID, [2]=x, [3]=y, title="..." }
            -- x/y are already fractional (0.0–1.0)
            if waypointData[1] and waypointData[2] and waypointData[3] then
                table.insert(points, {
                    name = waypointData.title or ("Waypoint on " .. tostring(mapID)),
                    mapID = waypointData[1],
                    x = waypointData[2],
                    y = waypointData[3]
                })
            end
        end
    end

    if #points == 0 then
        return nil, "TomTom has no active waypoints."
    end

    return points
end

-----------------------------------------------------------
-- HELPER: FILTER OUT COOLDOWN ABILITIES
-- Returns a copy of playerAbilities with any ability that
-- has a meaningful cooldown removed.
-- Used so the distance matrix is based only on always-available
-- travel methods, giving a consistent and honest visit order.
-----------------------------------------------------------

local function FilterCooldownAbilities(playerAbilities)
    local filtered = {}
    for _, ability in ipairs(playerAbilities) do
        if not ability.cooldown or ability.cooldown == 0 then
            table.insert(filtered, ability)
        end
    end
    return filtered
end

-----------------------------------------------------------
-- HELPER: CONSUME USED COOLDOWN ABILITIES
-- After building a leg's steps, remove any ability that was
-- consumed (has a cooldown and appeared in a step) so it
-- isn't offered again on subsequent legs.
-----------------------------------------------------------

local function ConsumeUsedAbilities(playerAbilities, legSteps)
    local usedItemIDs = {}
    local usedSpellIDs = {}
    for _, step in ipairs(legSteps) do
        if step.itemID then
            usedItemIDs[step.itemID] = true
        end
        if step.spellID then
            usedSpellIDs[step.spellID] = true
        end
    end

    local remaining = {}
    for _, ability in ipairs(playerAbilities) do
        local wasUsed = (ability.itemID and usedItemIDs[ability.itemID]) or
                            (ability.spellID and usedSpellIDs[ability.spellID])
        -- Only consume if it has a meaningful cooldown
        if wasUsed and ability.cooldown and ability.cooldown > 0 then
            -- Drop it — it's on cooldown for the rest of this route
        else
            table.insert(remaining, ability)
        end
    end

    return remaining
end

-----------------------------------------------------------
-- ASYNC DISTANCE MATRIX BUILDER
--
-- Computes cost[i][j] = travel cost from point i to point j,
-- spread across multiple frame ticks via C_Timer.After(0, ...).
--
-- pointList:       array of { name, mapID, x, y }
-- matrixAbilities: cooldown-filtered abilities (no cooldown items)
-- playerLocation:  current player coords (index 0), may be nil
-- onComplete:      callback(costMatrix) fired when all pairs done
-----------------------------------------------------------

function addon:BuildDistanceMatrixAsync(pointList, matrixAbilities, playerLocation, onComplete)
    local n = #pointList

    -- Build the points lookup: 0 = player, 1..n = destinations
    local points = {}
    points[0] = playerLocation
    for i = 1, n do
        points[i] = {
            mapID = pointList[i].mapID,
            x = pointList[i].x,
            y = pointList[i].y
        }
    end

    -- Pre-generate all (i, j) pairs we need to compute.
    -- Skip j=0 (never route back to player start) and i==j.
    local pairs = {}
    for i = 0, n do
        for j = 1, n do
            if i ~= j then
                table.insert(pairs, {
                    i = i,
                    j = j
                })
            end
        end
    end

    local totalPairs = #pairs

    -- Initialise cost matrix: diagonal = 0, everything else = huge
    local cost = {}
    for i = 0, n do
        cost[i] = {}
        for j = 0, n do
            cost[i][j] = (i == j) and 0 or math.huge
        end
    end

    local pairIndex = 1
    local lastProgress = 0

    local function processBatch()
        for _ = 1, MATRIX_BATCH_SIZE do
            if pairIndex > totalPairs then
                -- All pairs done — fire the completion callback
                onComplete(cost)
                return
            end

            local pair = pairs[pairIndex]
            local i, j = pair.i, pair.j
            pairIndex = pairIndex + 1

            local synthetic = addon:BuildSyntheticEdges(points[i], matrixAbilities, points[j])

            local _, routeCost = addon:FindPath("_PLAYER_POSITION", "_WAYPOINT_DESTINATION", matrixAbilities, synthetic)

            cost[i][j] = (type(routeCost) == "number") and routeCost or math.huge
        end

        -- Report progress at 25% increments so chat isn't spammed
        local progress = math.floor((pairIndex - 1) / totalPairs * 4) * 25
        if progress > lastProgress and progress < 100 then
            lastProgress = progress
            print(string.format("[Mapzeroth] Calculating... %d%%", progress))
        end

        -- Yield for one frame tick then resume
        C_Timer.After(0, processBatch)
    end

    processBatch()
end

-----------------------------------------------------------
-- TSP: BRUTE-FORCE PERMUTATION SOLVER
-- Only suitable for n <= 10. For larger sets use heuristic.
-----------------------------------------------------------

local function permute(arr, start, results)
    if start > #arr then
        local copy = {}
        for i = 1, #arr do
            copy[i] = arr[i]
        end
        table.insert(results, copy)
        return
    end
    for i = start, #arr do
        arr[start], arr[i] = arr[i], arr[start]
        permute(arr, start + 1, results)
        arr[start], arr[i] = arr[i], arr[start]
    end
end

function addon:SolveTSP(costMatrix, destinationCount)
    local indices = {}
    for i = 1, destinationCount do
        indices[i] = i
    end

    local allPerms = {}
    permute(indices, 1, allPerms)

    local bestCost = math.huge
    local bestOrder = nil

    for _, perm in ipairs(allPerms) do
        local totalCost = costMatrix[0][perm[1]]

        for i = 2, #perm do
            totalCost = totalCost + costMatrix[perm[i - 1]][perm[i]]
            if totalCost >= bestCost then
                break
            end
        end

        if totalCost < bestCost then
            bestCost = totalCost
            bestOrder = perm
        end
    end

    return bestOrder, bestCost
end

-----------------------------------------------------------
-- NEAREST-NEIGHBOUR HEURISTIC
-- Fallback for n > 10.
-----------------------------------------------------------

function addon:SolveNearestNeighbour(costMatrix, destinationCount)
    local visited = {}
    local order = {}
    local current = 0
    local totalCost = 0

    for _ = 1, destinationCount do
        local bestNext = nil
        local bestCost = math.huge

        for j = 1, destinationCount do
            if not visited[j] and costMatrix[current][j] < bestCost then
                bestCost = costMatrix[current][j]
                bestNext = j
            end
        end

        if not bestNext then
            break
        end

        visited[bestNext] = true
        table.insert(order, bestNext)
        totalCost = totalCost + bestCost
        current = bestNext
    end

    -- Warn if any destinations were unreachable
    if #order < destinationCount then
        print(string.format("[Mapzeroth] |cFFFFAA00Warning: %d/%d stops unreachable and skipped.|r",
            destinationCount - #order, destinationCount))
    end

    return order, totalCost
end

-----------------------------------------------------------
-- STITCH LEGS INTO ONE STEP LIST (ASYNC)
-- Same logic as StitchLegs but yields between each leg to
-- avoid hitting WoW's per-frame CPU execution limit on large
-- routes (50+ stops). Fires onComplete(allSteps, totalCost)
-- when all legs are processed, or onComplete(nil, nil) on error.
-----------------------------------------------------------

local function StitchLegsAsync(trainerList, bestOrder, playerAbilities, onComplete)
    local allSteps = {}
    local totalCost = 0
    local remainingAbilities = playerAbilities
    local legIndex = 1

    local function processLeg()
        if legIndex > #bestOrder then
            onComplete(allSteps, totalCost)
            return
        end

        local i = legIndex
        local idx = bestOrder[i]
        legIndex = legIndex + 1

        local trainer = trainerList[idx]
        local waypoint = {
            mapID = trainer.mapID,
            x = trainer.x,
            y = trainer.y,
            name = trainer.name
        }

        local fromCoords
        if i == 1 then
            fromCoords = addon:GetPlayerLocation()
        else
            local prev = trainerList[bestOrder[i - 1]]
            fromCoords = {
                mapID = prev.mapID,
                x = prev.x,
                y = prev.y
            }
        end

        local synthetic = addon:BuildSyntheticEdges(fromCoords, remainingAbilities, waypoint)
        local path, legCost, previous = addon:FindPath("_PLAYER_POSITION", "_WAYPOINT_DESTINATION", remainingAbilities,
            synthetic)

        if not path then
            print(string.format("[Mapzeroth] Could not route to %s: %s", trainer.name, legCost or "unknown error"))
            onComplete(nil, nil)
            return
        end

        local legSteps = addon:BuildStepList(path, legCost, previous, waypoint)
        local optimisedLeg, optimisedCost = addon:OptimizeConsecutiveMovement(legSteps)

        totalCost = totalCost + optimisedCost
        remainingAbilities = ConsumeUsedAbilities(remainingAbilities, optimisedLeg)

        for _, step in ipairs(optimisedLeg) do
            step.num = #allSteps + 1
            table.insert(allSteps, step)
        end

        C_Timer.After(0, processLeg)
    end

    processLeg()
end

-----------------------------------------------------------
-- ENTRY POINT
-- Called by GUI buttons. Async — returns immediately and
-- fires the display pipeline via callback when ready.
-----------------------------------------------------------

function addon:RouteMultiDestination(trainerList, label)
    local n = #trainerList

    if n == 0 then
        print("[Mapzeroth] No destinations in list.")
        return
    end

    if not addon.bagsFullyLoaded then
        print("[Mapzeroth] |cFFFFAA00Warning: Bags still loading - route may be missing travel items.|r")
    end

    print(string.format("[Mapzeroth] Calculating optimal route for %s (%d stops)...", label, n))

    local playerAbilities = addon:GetAvailableTravelAbilities()
    local matrixAbilities = FilterCooldownAbilities(playerAbilities)
    local playerLocation = addon:GetPlayerLocation()

    addon:BuildDistanceMatrixAsync(trainerList, matrixAbilities, playerLocation, function(costMatrix)

        local bestOrder
        if n <= 10 then
            bestOrder = addon:SolveTSP(costMatrix, n)
        else
            bestOrder = addon:SolveNearestNeighbour(costMatrix, n)
        end

        if not bestOrder then
            print("[Mapzeroth] Could not find a valid route. Are you on the right continent?")
            return
        end

        -- Stitch legs with full abilities, consuming cooldowns as used
        StitchLegsAsync(trainerList, bestOrder, playerAbilities, function(allSteps, totalCost)
            if not allSteps or #allSteps == 0 then
                print("[Mapzeroth] Route produced no steps.")
                return
            end

            print(string.format("[Mapzeroth] %s (%d stops, est. %.0fs):", label, n, totalCost))
            for i, idx in ipairs(bestOrder) do
                print(string.format("  %d. %s", i, trainerList[idx].name))
            end

            addon:ShowGPSNavigator(allSteps, totalCost)

            if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
                addon:ShowRouteExecutionFrame(allSteps, totalCost)
            end
        end)
    end)
end

-----------------------------------------------------------
-- V2: ANCHOR-AWARE MULTI-DESTINATION ROUTING
--
-- Same as RouteMultiDestination, but considers all instant
-- teleport options (hearthstones, tabards, class ports) as
-- candidate starting anchors. Picks whichever anchor produces
-- the cheapest complete tour, not just the cheapest first hop.
--
-- Cost: one matrix build (same as V1) + n × numAnchors extra
-- Dijkstra calls for the anchor cost vectors. Typically <50%
-- overhead vs V1, no additional full matrix passes.
-----------------------------------------------------------

-----------------------------------------------------------
-- HELPER: NODE COORDINATE LOOKUP
-- Searches addon.Nodes (all traversal groups) for a nodeID.
-- Returns the node table, or nil if not found.
-----------------------------------------------------------

local function NodeLookup(nodeID)
    for traversalGroup, groupData in pairs(addon.Nodes) do
        if groupData[nodeID] then
            return groupData[nodeID], traversalGroup
        end
    end
    return nil, nil
end

-----------------------------------------------------------
-- HELPER: COLLECT INSTANT-TELEPORT ANCHORS
-- Returns a list of { name, mapID, x, y } for every available
-- ability that teleports to a fixed, known node. Deduplicates
-- by destination so two toys going to the same place only
-- produce one anchor candidate.
--
-- allowedGroups: set of traversal group keys to permit.
-- Any anchor whose destination lives in a different group
-- is skipped — it's on the wrong continent and would only
-- add Dijkstra overhead without a realistic chance of winning.
-----------------------------------------------------------

local function GetInstantTeleportAnchors(playerAbilities, allowedGroups)
    local anchors = {}
    local seen = {}

    for _, ability in ipairs(playerAbilities) do
        if ability.destination and not seen[ability.destination] then
            local node, group = NodeLookup(ability.destination)
            if node and node.mapID and node.x and node.y and (not allowedGroups or allowedGroups[group]) then
                seen[ability.destination] = true
                table.insert(anchors, {
                    name = (ability.name or "?") .. " → " .. (node.name or ability.destination),
                    mapID = node.mapID,
                    x = node.x,
                    y = node.y
                })
            end
        end
    end

    return anchors
end

-----------------------------------------------------------
-- HELPER: BUILD ANCHOR COST VECTORS (ASYNC)
-- For each anchor in anchorList, runs FindPath to every
-- destination in pointList and stores the cost.
--
-- Returns: anchorVectors[anchorIdx][destIdx] = cost
-- Same batching strategy as the main matrix builder.
-----------------------------------------------------------

local function BuildAnchorCostVectorsAsync(anchorList, pointList, matrixAbilities, onComplete)
    local numAnchors = #anchorList
    local numDests = #pointList

    if numAnchors == 0 then
        onComplete({})
        return
    end

    -- Pre-build the point coord table for destinations
    local destPoints = {}
    for j = 1, numDests do
        destPoints[j] = {
            mapID = pointList[j].mapID,
            x = pointList[j].x,
            y = pointList[j].y
        }
    end

    -- Initialise result table
    local vectors = {}
    for i = 1, numAnchors do
        vectors[i] = {}
        for j = 1, numDests do
            vectors[i][j] = math.huge
        end
    end

    -- Flatten into a simple work queue: { anchorIdx, destIdx }
    local workQueue = {}
    for i = 1, numAnchors do
        for j = 1, numDests do
            table.insert(workQueue, {
                i = i,
                j = j
            })
        end
    end

    local totalWork = #workQueue
    local workIndex = 1

    local function processAnchorBatch()
        for _ = 1, MATRIX_BATCH_SIZE do
            if workIndex > totalWork then
                onComplete(vectors)
                return
            end

            local item = workQueue[workIndex]
            local anchor = anchorList[item.i]
            workIndex = workIndex + 1

            local synthetic = addon:BuildSyntheticEdges({
                mapID = anchor.mapID,
                x = anchor.x,
                y = anchor.y
            }, matrixAbilities, destPoints[item.j])

            local _, routeCost = addon:FindPath("_PLAYER_POSITION", "_WAYPOINT_DESTINATION", matrixAbilities, synthetic)

            vectors[item.i][item.j] = (type(routeCost) == "number") and routeCost or math.huge
        end

        C_Timer.After(0, processAnchorBatch)
    end

    processAnchorBatch()
end

-----------------------------------------------------------
-- HELPER: NEAREST-NEIGHBOUR FROM AN EXTERNAL COST VECTOR
-- Like SolveNearestNeighbour, but the "from start" costs
-- come from a provided vector rather than costMatrix[0].
-- After the first hop, inter-node costs come from costMatrix
-- as normal.
-----------------------------------------------------------

local function SolveNNFromVector(firstHopCosts, costMatrix, destinationCount)
    local visited = {}
    local order = {}
    local totalCost = 0

    -- First hop: cheapest destination reachable from anchor
    local bestNext = nil
    local bestCost = math.huge
    for j = 1, destinationCount do
        if firstHopCosts[j] < bestCost then
            bestCost = firstHopCosts[j]
            bestNext = j
        end
    end

    if not bestNext then
        return nil, math.huge
    end

    visited[bestNext] = true
    table.insert(order, bestNext)
    totalCost = totalCost + bestCost
    local current = bestNext

    -- Subsequent hops: standard nearest-neighbour on costMatrix
    for _ = 2, destinationCount do
        bestNext = nil
        bestCost = math.huge
        for j = 1, destinationCount do
            if not visited[j] and costMatrix[current][j] < bestCost then
                bestCost = costMatrix[current][j]
                bestNext = j
            end
        end
        if not bestNext then
            break
        end

        visited[bestNext] = true
        table.insert(order, bestNext)
        totalCost = totalCost + bestCost
        current = bestNext
    end

    return order, totalCost
end

-----------------------------------------------------------
-- ENTRY POINT V2
-- Drop-in replacement for RouteMultiDestination.
-- Identical interface; add anchorDebug=true to trainerList
-- metadata if you want the winning anchor printed to chat.
-----------------------------------------------------------

function addon:RouteMultiDestinationV2(trainerList, label)
    local n = #trainerList

    if n == 0 then
        print("[Mapzeroth] No destinations in list.")
        return
    end

    if not addon.bagsFullyLoaded then
        print("[Mapzeroth] |cFFFFAA00Warning: Bags still loading - route may be missing travel items.|r")
    end

    print(string.format("[Mapzeroth] Calculating anchor-aware route for %s (%d stops)...", label, n))

    local playerAbilities = addon:GetAvailableTravelAbilities()
    local matrixAbilities = FilterCooldownAbilities(playerAbilities)
    local playerLocation = addon:GetPlayerLocation()

    -- Build the set of traversal groups represented in this route.
    -- Any instant-teleport anchor outside these groups is on the wrong
    -- continent and gets filtered before the expensive async phase.
    local allowedGroups = {}
    for _, trainer in ipairs(trainerList) do
        local group = addon.GetTraversalGroupForMap(trainer.mapID)
        if group then
            allowedGroups[group] = true
        end
    end

    -- Phase 1: build the main NxN distance matrix (same as V1)
    addon:BuildDistanceMatrixAsync(trainerList, matrixAbilities, playerLocation, function(costMatrix)

        -- Phase 2: collect instant-teleport anchors and build their cost vectors.
        -- We include ALL playerAbilities here (not just cooldown-filtered) because
        -- hearthstones/tabards ARE cooldown items — they're exactly what we're after.
        -- Only anchors in the same traversal group(s) as the route are considered.
        local anchors = GetInstantTeleportAnchors(playerAbilities, allowedGroups)

        BuildAnchorCostVectorsAsync(anchors, trainerList, matrixAbilities, function(anchorVectors)

            -- Phase 3: evaluate every candidate starting point and pick the best tour.
            -- Candidate 0 = player's current position (row 0 of costMatrix, V1 behaviour).
            -- Candidates 1..numAnchors = instant-teleport destinations.

            local bestOrder = nil
            local bestCost = math.huge
            local bestAnchorName = "current position"

            -- Evaluate from player's current position (V1 parity)
            local playerOrder, playerCost
            if n <= 10 then
                playerOrder, playerCost = addon:SolveTSP(costMatrix, n)
            else
                playerOrder, playerCost = addon:SolveNearestNeighbour(costMatrix, n)
            end

            if playerOrder and playerCost < bestCost then
                bestCost = playerCost
                bestOrder = playerOrder
                bestAnchorName = "current position"
            end

            -- Evaluate from each instant-teleport anchor
            for i, anchor in ipairs(anchors) do
                local anchorOrder, anchorCost = SolveNNFromVector(anchorVectors[i], costMatrix, n)
                if anchorOrder and anchorCost < bestCost then
                    bestCost = anchorCost
                    bestOrder = anchorOrder
                    bestAnchorName = anchor.name
                end
            end

            if not bestOrder then
                print("[Mapzeroth] Could not find a valid route. Are you on the right continent?")
                return
            end

            -- Report which stops were dropped
            if #bestOrder < n then
                local visited = {}
                for _, idx in ipairs(bestOrder) do
                    visited[idx] = true
                end
                for i = 1, n do
                    if not visited[i] then
                        print(string.format("[Mapzeroth] |cFFFFAA00  Skipped: %s|r", trainerList[i].name))
                    end
                end
            end

            print(string.format("[Mapzeroth] Best start: %s (est. %.0fs total)", bestAnchorName, bestCost))

            -- Phase 4: stitch legs — identical to V1 from here
            StitchLegsAsync(trainerList, bestOrder, playerAbilities, function(allSteps, totalCost)
                if not allSteps or #allSteps == 0 then
                    print("[Mapzeroth] Route produced no steps.")
                    return
                end

                print(string.format("[Mapzeroth] %s (%d stops, est. %.0fs):", label, n, totalCost))
                for i, idx in ipairs(bestOrder) do
                    print(string.format("  %d. %s", i, trainerList[idx].name))
                end

                addon:ShowGPSNavigator(allSteps, totalCost)

                if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
                    addon:ShowRouteExecutionFrame(allSteps, totalCost)
                end
            end)
        end)
    end)
end
