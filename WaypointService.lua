-- WaypointService.lua
-- Handles player waypoints and routing to arbitrary locations
local addonName, addon = ...

local GetTraversalGroupForMap = addon.GetTraversalGroupForMap

-----------------------------------------------------------
-- GET ACTIVE WAYPOINT
-----------------------------------------------------------

function addon:GetActiveWaypoint()
    -- Try Blizzard's native waypoint first
    local waypoint = C_Map.GetUserWaypoint()

    if waypoint and waypoint.uiMapID and waypoint.position then
        return {
            mapID = waypoint.uiMapID,
            x = waypoint.position.x,
            y = waypoint.position.y,
            source = "native"
        }
    end

    -- Try TomTom if installed
    if TomTom and TomTom.waypoints then
        -- Iterate through all map tables
        for mapID, waypointsOnMap in pairs(TomTom.waypoints) do
            for uid, waypoint in pairs(waypointsOnMap) do
                -- TomTom stores coords as [1]=mapID, [2]=x, [3]=y
                if waypoint[1] and waypoint[2] and waypoint[3] then
                    return {
                        mapID = waypoint[1],
                        x = waypoint[2],
                        y = waypoint[3],
                        source = "tomtom"
                    }
                end
            end
        end
    end

    return nil, "No active waypoint found"
end

-----------------------------------------------------------
-- FIND NEAREST NODE TO ARBITRARY COORDINATES
-----------------------------------------------------------

function addon:FindNearestNodeToCoords(mapID, x, y)
    -- First, try to find nodes on the exact mapID
    local exactMapNodes = {}
    for nodeID, node in pairs(self.TravelGraph.nodes) do
        if node.mapID == mapID and node.x and node.y then
            table.insert(exactMapNodes, node)
        end
    end

    if #exactMapNodes > 0 then
        return self:FindClosestNodeInList(exactMapNodes, x, y)
    end

    -- Fall back to traversal group matching
    local traversalGroup = addon.GetTraversalGroupForMap(mapID)

    if not traversalGroup then
        return nil, string.format("No travel nodes found near map %d", mapID)
    end

    local traversalNodes = {}
    for nodeID, node in pairs(self.TravelGraph.nodes) do
        if node.traversalGroup == traversalGroup and node.x and node.y then
            table.insert(traversalNodes, node)
        end
    end

    if #traversalNodes == 0 then
        return nil, string.format("No travel nodes in %s", traversalGroup)
    end

    return self:FindClosestNodeInList(traversalNodes, x, y)
end

-----------------------------------------------------------
-- CALCULATE TRAVEL TIME TO ARBITRARY COORDS
-----------------------------------------------------------

function addon:CalculateTravelToCoords(fromNode, toMapID, toX, toY)
    -- First, check traversal groups if both are known
    if fromNode.traversalGroup then
        local toTraversalGroup = addon.GetTraversalGroupForMap(toMapID)
        if toTraversalGroup and fromNode.traversalGroup ~= toTraversalGroup then
            return nil -- Different traversal groups, no route
        end
    end

    -- Try to calculate distance
    local distance = self.TravelGraph:CalculateDistanceToCoords(fromNode, toMapID, toX, toY)

    if not distance then
        -- If we're in the same traversal group but coords failed, give a fallback
        local toTraversalGroup = addon.GetTraversalGroupForMap(toMapID)
        if toTraversalGroup and fromNode.traversalGroup == toTraversalGroup then
            return 45, "fly"
        end
        return nil -- Can't route at all
    end

    -- Calculate time based on distance
    local canFly = not self.TravelGraph.NO_FLY_MAPS[toMapID]
    local speed = canFly and self.TravelGraph.FLY_SPEED or self.TravelGraph.WALK_SPEED
    local time = math.ceil(distance / speed / 5) * 5
    return math.max(1.5, math.min(300, time)), canFly and "fly" or "walk"
end
