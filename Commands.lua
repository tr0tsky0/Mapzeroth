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

    print("[Mapzeroth] Unknown command. Type /mapzeroth help for usage.")
end

-----------------------------------------------------------
-- COMMAND: List All Nodes
-----------------------------------------------------------

function addon:ListNodes()
    print("[Mapzeroth] Available destination nodes:")

    local nodesByMap = {}

    -- Group nodes by map
    for nodeID, node in pairs(self.TravelGraph.nodes) do
        local mapName = self:GetMapName(node.mapID)

        if not nodesByMap[mapName] then
            nodesByMap[mapName] = {}
        end

        table.insert(nodesByMap[mapName], {
            id = nodeID,
            name = node.name
        })
    end

    -- Print grouped by map
    for mapName, nodes in pairs(nodesByMap) do
        print(string.format("  %s:", mapName))
        for _, node in ipairs(nodes) do
            print(string.format("    - %s (id: %s)", node.name, node.id))
        end
    end
end

-----------------------------------------------------------
-- BuildStepList
-----------------------------------------------------------
function addon:BuildStepList(path, totalCost, previous, waypoint)
    local steps = {}

    for i, nodeID in ipairs(path) do
        local node = self.TravelGraph:GetNodeByID(nodeID)
        local prevInfo = previous[nodeID]

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
                nodeID = prevInfo.nodeID
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
                waypointData = waypoint
            })
        elseif node then
            -- Regular node
            table.insert(steps, {
                num = #steps + 1,
                method = prevInfo.method,
                destination = node.name,
                time = prevInfo.cost,
                abilityName = prevInfo.abilityName,
                destinationName = prevInfo.destinationName,
                itemID = prevInfo.itemID,
                spellID = prevInfo.spellID,
                nodeID = nodeID
            })
        end
    end

    return steps
end

-----------------------------------------------------------
-- COMMAND: Find Route
-----------------------------------------------------------

function addon:FindRoute(destinationID)
    local waypoint

    if destinationID == "_WAYPOINT_DESTINATION" then
        local err
        waypoint, err = self:GetActiveWaypoint()
        if not waypoint then
            print("[Mapzeroth] " .. err)
            print("[Mapzeroth] Set a waypoint using Shift+Click on the map, or use TomTom")
            return
        end
    end

    local playerAbilities = self:GetAvailableTravelAbilities()
    local location = self:GetPlayerLocation()

    -- Build synthetic edges (includes waypoint node)
    local synthetic = self:BuildSyntheticEdges(location, playerAbilities, waypoint)

    -- Add edges from player to nearby nodes
    local MAX_PLAYER_RANGE = 2.0
    for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
        for nodeID, node in pairs(groupData) do
            if node.mapID == location.mapID and node.x and node.y then
                local dx = node.x - location.x
                local dy = node.y - location.y
                local dist = math.sqrt(dx * dx + dy * dy)

                if dist <= MAX_PLAYER_RANGE then
                    local travelTime, travelMethod = self:CalculateTravelToNode(dist, location.mapID)
                    table.insert(synthetic.edges, {
                        from = "_PLAYER_POSITION",
                        to = nodeID,
                        method = travelMethod,
                        cost = travelTime,
                        isSynthetic = true
                    })
                end
            end
        end
    end

    -- Find path
    local path, cost, previous = self:FindPath("_PLAYER_POSITION", destinationID, playerAbilities, synthetic)
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

    -- Output (simplified!)
    if addon.MapzerothFrame and addon.MapzerothFrame:IsShown() then
        local steps = self:BuildStepList(path, cost, previous, waypoint)
        self:ShowRouteExecutionFrame(steps, cost)
    else
        print(self:FormatPath(path, cost, previous))
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

function addon:ListNodes()
    print("[Mapzeroth] Available destination nodes:")

    for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
        print(string.format("  %s:", traversalGroup))
        for nodeID, node in pairs(groupData) do
            print(string.format("    - %s (id: %s)", node.name, node.id))
        end
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
