-- Commands.lua
-- Slash command handling
local addonName, addon = ...
local GUI_ENABLED = true -- Toggle for testing

local function tableCount(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-----------------------------------------------------------
-- SLASH COMMAND HANDLER
-----------------------------------------------------------

SLASH_MAPZEROTH1 = "/mapzeroth"
SLASH_MAPZEROTH2 = "/mz"

SlashCmdList["MAPZEROTH"] = function(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "" or command == "help" then
        print("[Mapzeroth] Commands:")
        print("  /mz route <destination> - Find route to destination node")
        print("  /mz waypoint (or wp) - Route to active waypoint")
        print("  /mz sethearth (or sh) - Manually save your hearthstone destination (auto-detected otherwise)")
        print("  /mz toggle - Toggle Mapzeroth GUI")
        print("  /mz minimap - Toggle minimap button visibility")
        return
    end

    if command == "waypoint" or command == "wp" then
        addon:FindRoute("_WAYPOINT_DESTINATION")
        return
    end

    if command == "sethearth" or command == "sh" then
        addon:SetHearthstoneLocation()
        return
    end

    if command == "route" then
        if arg == "" then
            print("[Mapzeroth] Usage: /mapzeroth route <destination_node_id>")
            print("Use /mapzeroth nodes to see available destinations")
            return
        end

        addon:FindRoute(arg)
        return
    end

    -- GUI Commands
    if command == "show" then
        addon:ShowGUI()
        return
    end

    if command == "hide" then
        addon:HideGUI()
        return
    end

    if command == "toggle" or command == "gui" then
        addon:ToggleGUI()
        return
    end

    -- Minimap button command
    if command == "minimap" then
        addon:ToggleMinimapButton()
        if MapzerothDB.minimap.hide then
            print("[Mapzeroth] Minimap button hidden")
        else
            print("[Mapzeroth] Minimap button shown")
        end
        return
    end

    -- Debug Commands

    if command == "map" then
        addon:ShowMapInfo()
        return
    end

    if command == "nodes" then
        addon:ListNodes()
        return
    end

    if command == "stats" then
        addon:ShowStats()
        return
    end

    if command == "debug" then
        addon.DEBUG = not addon.DEBUG
        print(string.format("[Mapzeroth] Debug mode: %s", addon.DEBUG and "ON" or "OFF"))
        return
    end

    if command == "debug-groups" then
        print("[Mapzeroth] Traversal groups in graph:")
        local groups = {}
        for nodeID, node in pairs(addon.TravelGraph.nodes) do
            local key = node.traversalGroup or "UNKNOWN"
            groups[key] = (groups[key] or 0) + 1
        end
        for group, count in pairs(groups) do
            print(string.format("  %s: %d nodes", group, count))
        end
        return
    end

    if command == "debug-edges" then
        if arg == "" then
            print("[Mapzeroth] Usage: /mz debug-edges <nodeID>")
            return
        end

        local node = addon:GetTravelNode(arg)
        if not node then
            print("[Mapzeroth] Node not found: " .. arg)
            return
        end

        print(string.format("[Mapzeroth] Edges from %s:", node.name))
        for _, edge in ipairs(node.edges) do
            local targetNode = addon:GetTravelNode(edge.to)
            local targetName = targetNode and targetNode.name or edge.to
            print(string.format("  -> %s (%s, %.0fs)", targetName, edge.method, edge.cost))
        end
        return
    end

    if command == "verify_nodes" or command == "verify" then
        local results = addon:VerifyNodeReferences()

        print(string.format("[Mapzeroth] Verified %d base edges and %d abilities", results.edgeCount,
            results.abilityCount))

        if results.valid then
            print("[Mapzeroth] All node references are valid!")
        else
            print(string.format("[Mapzeroth] Found %d invalid node references:", results.errorCount))

            for _, entry in ipairs(results.missingNodes) do
                print(string.format("  - %s (referenced %d times in %s)", entry.id, entry.count, entry.type))
            end
        end
        return
    end

    print("[Mapzeroth] Unknown command. Type /mapzeroth help for usage.")
end

-----------------------------------------------------------
-- COMMAND: List All Nodes
-----------------------------------------------------------

function addon:ListNodes()
    print("[Mapzeroth] Available destination nodes:")

    for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
        print(string.format("  %s:", traversalGroup))
        for nodeID, node in pairs(groupData) do
            print(string.format("    - %s (id: %s)", node.displayName or node.name, node.id))
        end
    end
end

-----------------------------------------------------------
-- BuildStepList
-----------------------------------------------------------
local function BuildStepList(path, totalCost, previous, waypoint)
    local steps = {}

    for i, nodeID in ipairs(path) do
        local node = addon:GetTravelNode(nodeID)
        local prevInfo = previous[nodeID]

        if addon.DEBUG and prevInfo then
            print(string.format("[Mapzeroth] Step %d: %s <- %s (method=%s, cost=%.0f)", i, nodeID,
                prevInfo.fromNode or "?", prevInfo.method, prevInfo.cost))
        end

        if not prevInfo then
            -- Skip nodes without previous info (shouldn't happen)
            if addon.DEBUG then
                print(string.format("[Mapzeroth] WARNING: No previous info for node %s", nodeID))
            end
        elseif nodeID == "_INITIAL_STEP" then
            -- Initial walk/fly step
            table.insert(steps, {
                num = #steps + 1,
                method = prevInfo.method,
                destination = prevInfo.destination,
                time = prevInfo.cost,
                nodeID = prevInfo.nodeID,
                fromNodeID = prevInfo.fromNode
            })
        elseif nodeID == "_WAYPOINT_DESTINATION" then
            -- Waypoint destination
            table.insert(steps, {
                num = #steps + 1,
                method = prevInfo.method,
                destination = "Waypoint",
                time = prevInfo.cost,
                abilityName = prevInfo.abilityName,
                destinationName = prevInfo.destinationName,
                itemID = prevInfo.itemID,
                spellID = prevInfo.spellID,
                nodeID = nodeID,
                fromNodeID = prevInfo.fromNode,
                waypointData = waypoint
            })
        elseif node then
            -- Regular node
            table.insert(steps, {
                num = #steps + 1,
                method = prevInfo.method,
                destination = node.displayName or node.name,
                time = prevInfo.cost,
                abilityName = prevInfo.abilityName,
                destinationName = prevInfo.destinationName,
                itemID = prevInfo.itemID,
                spellID = prevInfo.spellID,
                nodeID = nodeID,
                fromNodeID = prevInfo.fromNode
            })
        end
    end

    return steps
end

-----------------------------------------------------------
-- UTILITY: Format Optimized Steps for Chat Display
-----------------------------------------------------------
local function FormatPathFromSteps(steps, totalCost)
    if not steps or #steps == 0 then
        return "No path found"
    end

    local output = {}
    table.insert(output, string.format("[Mapzeroth] Route found (%.0f seconds):", totalCost))

    for i, step in ipairs(steps) do
        local actionText

        if step.abilityName then
            -- Ability-based travel (portals, hearthstone, etc.)
            if step.destinationName then
                actionText = string.format("Use %s to %s", step.abilityName, step.destinationName)
            else
                actionText = string.format("Use %s", step.abilityName)
            end
        else
            -- Regular movement or other methods
            local methodText = addon.METHOD_DISPLAY_TEXT[step.method] or "Travel to"
            actionText = string.format("%s %s", methodText, step.destination)
        end

        -- Add collapse indicator only in debug mode
        if addon.DEBUG and step.collapsedFrom and step.collapsedFrom > 1 then
            actionText = actionText .. string.format(" (direct, collapsed %d hops)", step.collapsedFrom)
        end

        table.insert(output, string.format("  %d. %s (%.0fs)", i, actionText, step.time))
    end

    return table.concat(output, "\n")
end

-----------------------------------------------------------
-- COMMAND: Find Route
-----------------------------------------------------------

function addon:FindRoute(destinationID)
    local waypoint

    if destinationID == "_WAYPOINT_DESTINATION" then
        local err
        waypoint, err = addon:GetActiveWaypoint()
        if not waypoint then
            print("[Mapzeroth] " .. err)
            print("[Mapzeroth] Set a waypoint using Shift+Click on the map, or use TomTom")
            return
        end
    end

    if not addon.bagsFullyLoaded then
        print(
            "[Mapzeroth] |cFFFFAA00Warning: Bags still loading - route may not include all travel items. Try again in a moment!|r")
        -- Continue anyway—route will just be suboptimal
    end

    local playerAbilities = addon:GetAvailableTravelAbilities()
    local location = addon:GetPlayerLocation() -- Can be nil in instances

    -- Build ALL synthetic edges (abilities + walking, if location exists)
    local synthetic = addon:BuildSyntheticEdges(location, playerAbilities, waypoint)

    -- Find path
    local path, cost, previous = addon:FindPath("_PLAYER_POSITION", destinationID, playerAbilities, synthetic)

    if addon.DEBUG then
        print("[Mapzeroth] Path nodes:")
        for i, nodeID in ipairs(path) do
            print(string.format("  %d: %s", i, nodeID))
        end
    end

    if not path then
        print("[Mapzeroth] " .. cost)
        return
    end

    -- Output
    local steps = BuildStepList(path, cost, previous, waypoint)
    local optimizedSteps, optimizedCost = addon:OptimizeConsecutiveMovement(steps)
    addon:ShowGPSNavigator(optimizedSteps, optimizedCost)

    if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
        addon:ShowRouteExecutionFrame(optimizedSteps, optimizedCost)
    else
        print(FormatPathFromSteps(optimizedSteps, optimizedCost))
    end
end

-----------------------------------------------------------
-- COMMAND: Show Graph Statistics
-----------------------------------------------------------

function addon:ShowStats()
    local graph = self.TravelGraph

    print("[Mapzeroth] Graph Statistics:")
    print(string.format("  Total Nodes: %d", graph.nodeCount))
    print(string.format("  Total Edges: %d", graph.edgeCount))

    -- Count edges by method (iterate hierarchy directly)
    local methodCounts = {}
    for traversalGroup, groupData in pairs(graph.nodes) do
        for nodeID, node in pairs(groupData) do
            for _, edge in ipairs(node.edges) do
                methodCounts[edge.method] = (methodCounts[edge.method] or 0) + 1
            end
        end
    end

    print("  Edges by method:")
    for method, count in pairs(methodCounts) do
        print(string.format("    %s: %d", method, count))
    end

    -- Find most connected node (iterate hierarchy directly)
    local maxEdges = 0
    local maxNode = nil
    for traversalGroup, groupData in pairs(graph.nodes) do
        for nodeID, node in pairs(groupData) do
            if #node.edges > maxEdges then
                maxEdges = #node.edges
                maxNode = node
            end
        end
    end

    if maxNode then
        print(string.format("  Most connected: %s (%d connections)", maxNode.name, maxEdges))
    end
end

function addon:ShowMapInfo()
    local mapID = C_Map.GetBestMapForUnit("player")

    if not mapID then
        print("[Mapzeroth] Could not determine current map")
        return
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    local mapName = mapInfo and mapInfo.name or "Unknown"

    local position = C_Map.GetPlayerMapPosition(mapID, "player")

    if not position then
        print(string.format("[Mapzeroth] Map: %s (ID: %d)", mapName, mapID))
        print("  Could not determine coordinates")
        return
    end

    local x, y = position:GetXY()

    print("[Mapzeroth] Current Map Info:")
    print(string.format("  Name: %s", mapName))
    print(string.format("  Map ID: %d", mapID))
    print(string.format("  Coordinates: %.3f, %.3f", x, y))
    print("")
    print("-- Copy-paste template for Mapzeroth_Data.lua:")
    print(string.format("NEW_NODE_ID = {"))
    print(string.format("    id = \"NEW_NODE_ID\","))
    print(string.format("    name = \"%s\",", mapName))
    print(string.format("    kind = \"zone\","))
    print(string.format("    continent = \"UNKNOWN\","))
    print(string.format("    traversalGroup = \"UNKNOWN\","))
    print(string.format("    faction = \"NEUTRAL\","))
    print(string.format("    mapID = %d,", mapID))
    print(string.format("    x = %.3f,", x))
    print(string.format("    y = %.3f,", y))
    print(string.format("},"))
end

-----------------------------------------------------------
-- COMMAND: VERIFY NODE REFERENCES
-----------------------------------------------------------
-- Returns: { valid = boolean, edgeCount = number, abilityCount = number, 
--            errorCount = number, missingNodes = table }

function addon:VerifyNodeReferences()
    local missingNodes = {}
    local edgeCount = 0
    local errorCount = 0

    -- Check base graph edges
    if self.Edges then
        for _, edge in ipairs(self.Edges) do
            edgeCount = edgeCount + 1

            -- Check 'from' node
            if not self:GetTravelNode(edge.from) then
                local key = edge.from
                if not missingNodes[key] then
                    missingNodes[key] = {
                        count = 0,
                        type = "edge"
                    }
                end
                missingNodes[key].count = missingNodes[key].count + 1
                errorCount = errorCount + 1
            end

            -- Check 'to' node
            if not self:GetTravelNode(edge.to) then
                local key = edge.to
                if not missingNodes[key] then
                    missingNodes[key] = {
                        count = 0,
                        type = "edge"
                    }
                end
                missingNodes[key].count = missingNodes[key].count + 1
                errorCount = errorCount + 1
            end
        end
    end

    -- Helper to check destinations
    local function checkDestination(dest, sourceType)
        if dest and not self:GetTravelNode(dest) then
            if not missingNodes[dest] then
                missingNodes[dest] = {
                    count = 0,
                    type = sourceType
                }
            end
            missingNodes[dest].count = missingNodes[dest].count + 1
            errorCount = errorCount + 1
        end
    end

    local abilityCount = 0

    -- TravelItems (toys, hearthstones)
    if self.TravelItems then
        for _, item in pairs(self.TravelItems) do
            abilityCount = abilityCount + 1
            checkDestination(item.destination, "ability")
            if item.destinations then
                for _, dest in ipairs(item.destinations) do
                    checkDestination(dest, "ability")
                end
            end
        end
    end

    -- ClassTeleports
    if self.ClassTeleports then
        for _, spell in pairs(self.ClassTeleports) do
            abilityCount = abilityCount + 1
            checkDestination(spell.destination, "ability")
            if spell.destinations then
                for _, dest in ipairs(spell.destinations) do
                    checkDestination(dest, "ability")
                end
            end
        end
    end

    -- RacialAbilities
    if self.RacialAbilities then
        for _, racial in pairs(self.RacialAbilities) do
            abilityCount = abilityCount + 1
            checkDestination(racial.destination, "ability")
            if racial.destinations then
                for _, dest in ipairs(racial.destinations) do
                    checkDestination(dest, "ability")
                end
            end
        end
    end

    -- DungeonTeleports
    if self.DungeonTeleports then
        for _, teleport in pairs(self.DungeonTeleports) do
            abilityCount = abilityCount + 1
            checkDestination(teleport.destination, "ability")
            if teleport.destinations then
                for _, dest in ipairs(teleport.destinations) do
                    checkDestination(dest, "ability")
                end
            end
        end
    end

    -- Sort by count (most referenced first)
    local sortedMissing = {}
    for nodeID, data in pairs(missingNodes) do
        table.insert(sortedMissing, {
            id = nodeID,
            count = data.count,
            type = data.type
        })
    end
    table.sort(sortedMissing, function(a, b)
        return a.count > b.count
    end)

    return {
        valid = (errorCount == 0),
        edgeCount = edgeCount,
        abilityCount = abilityCount,
        errorCount = errorCount,
        missingNodes = sortedMissing
    }
end
