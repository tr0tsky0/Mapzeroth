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
    local usedItemIDs  = {}
    local usedSpellIDs = {}
    for _, step in ipairs(legSteps) do
        if step.itemID  then usedItemIDs[step.itemID]   = true end
        if step.spellID then usedSpellIDs[step.spellID] = true end
    end

    local remaining = {}
    for _, ability in ipairs(playerAbilities) do
        local wasUsed = (ability.itemID  and usedItemIDs[ability.itemID]) or
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
            x     = pointList[i].x,
            y     = pointList[i].y,
        }
    end

    -- Pre-generate all (i, j) pairs we need to compute.
    -- Skip j=0 (never route back to player start) and i==j.
    local pairs = {}
    for i = 0, n do
        for j = 1, n do
            if i ~= j then
                table.insert(pairs, { i = i, j = j })
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

    local pairIndex    = 1
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

            local synthetic = addon:BuildSyntheticEdges(
                points[i],
                matrixAbilities,
                points[j]
            )

            local _, routeCost = addon:FindPath(
                "_PLAYER_POSITION",
                "_WAYPOINT_DESTINATION",
                matrixAbilities,
                synthetic
            )

            cost[i][j] = routeCost or math.huge
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
        for i = 1, #arr do copy[i] = arr[i] end
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
    for i = 1, destinationCount do indices[i] = i end

    local allPerms = {}
    permute(indices, 1, allPerms)

    local bestCost  = math.huge
    local bestOrder = nil

    for _, perm in ipairs(allPerms) do
        local totalCost = costMatrix[0][perm[1]]

        for i = 2, #perm do
            totalCost = totalCost + costMatrix[perm[i-1]][perm[i]]
            if totalCost >= bestCost then break end
        end

        if totalCost < bestCost then
            bestCost  = totalCost
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
    local visited   = {}
    local order     = {}
    local current   = 0
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

        if not bestNext then break end

        visited[bestNext] = true
        table.insert(order, bestNext)
        totalCost = totalCost + bestCost
        current   = bestNext
    end

    return order, totalCost
end

-----------------------------------------------------------
-- STITCH LEGS INTO ONE STEP LIST
-- Routes each leg using full playerAbilities (including
-- cooldowns), consuming each cooldown ability after the
-- leg that uses it so it isn't reused on later legs.
-----------------------------------------------------------

local function StitchLegs(trainerList, bestOrder, playerAbilities)
    local allSteps           = {}
    local totalCost          = 0
    local remainingAbilities = playerAbilities

    for i, idx in ipairs(bestOrder) do
        local trainer = trainerList[idx]
        local waypoint = {
            mapID = trainer.mapID,
            x     = trainer.x,
            y     = trainer.y,
            name  = trainer.name,
        }

        local fromCoords
        if i == 1 then
            fromCoords = addon:GetPlayerLocation()
        else
            local prev = trainerList[bestOrder[i - 1]]
            fromCoords = { mapID = prev.mapID, x = prev.x, y = prev.y }
        end

        local synthetic = addon:BuildSyntheticEdges(fromCoords, remainingAbilities, waypoint)
        local path, legCost, previous = addon:FindPath(
            "_PLAYER_POSITION",
            "_WAYPOINT_DESTINATION",
            remainingAbilities,
            synthetic
        )

        if not path then
            print(string.format("[Mapzeroth] Could not route to %s: %s",
                trainer.name, legCost or "unknown error"))
            return nil, nil
        end

        local legSteps = addon:BuildStepList(path, legCost, previous, waypoint)
        local optimisedLeg, optimisedCost = addon:OptimizeConsecutiveMovement(legSteps)

        totalCost = totalCost + optimisedCost

        -- Remove any cooldown abilities consumed in this leg
        remainingAbilities = ConsumeUsedAbilities(remainingAbilities, optimisedLeg)

        -- Append to master list with sequential step numbers
        for _, step in ipairs(optimisedLeg) do
            step.num = #allSteps + 1
            table.insert(allSteps, step)
        end
    end

    return allSteps, totalCost
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
    local playerLocation  = addon:GetPlayerLocation()

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
        local allSteps, totalCost = StitchLegs(trainerList, bestOrder, playerAbilities)

        if not allSteps or #allSteps == 0 then
            print("[Mapzeroth] Route produced no steps.")
            return
        end

        -- Print the visit order for reference
        print(string.format("[Mapzeroth] %s (%d stops, est. %.0fs):", label, n, totalCost))
        for i, idx in ipairs(bestOrder) do
            print(string.format("  %d. %s", i, trainerList[idx].name))
        end

        -- Hand off to the existing display pipeline
        addon:ShowGPSNavigator(allSteps, totalCost)

        if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
            addon:ShowRouteExecutionFrame(allSteps, totalCost)
        end
    end)
end