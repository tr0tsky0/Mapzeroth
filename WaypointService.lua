-- WaypointService.lua
-- Handles player waypoints and routing to arbitrary locations
local addonName, addon = ...

local GetTraversalGroupForMap = addon.GetTraversalGroupForMap
local superTrackingMap = nil

-----------------------------------------------------------
-- SAVE SUPER TRACKING MAP
-----------------------------------------------------------
function addon:UpdateSuperTrackingMap()
    if WorldMapFrame and WorldMapFrame:IsShown() then
        superTrackingMap = WorldMapFrame:GetMapID()

        if addon.DEBUG then
            local pinType, typeID = C_SuperTrack.GetSuperTrackedMapPin()
            if pinType then
                print(string.format("[Mapzeroth] DEBUG: Supertracked %s (ID: %d) on map %d", tostring(pinType),
                    typeID or 0, superTrackingMap or 0))
            end
        end
    else
        superTrackingMap = nil

        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: Supertracking cleared (map not open)")
        end
    end
end

-----------------------------------------------------------
-- GET ACTIVE WAYPOINT
-----------------------------------------------------------
function addon:GetActiveWaypoint()
    -- Check for supertracked map pin
    local pinType, typeID = C_SuperTrack.GetSuperTrackedMapPin()

    if pinType and typeID then
        -- Dispatch based on pin type
        if pinType == Enum.SuperTrackingMapPinType.AreaPOI then
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(nil, typeID)

            if poiInfo and poiInfo.position and superTrackingMap then
                return {
                    mapID = superTrackingMap,
                    x = poiInfo.position.x,
                    y = poiInfo.position.y,
                    name = poiInfo.name or "Area POI",
                    source = "area_poi"
                }
            end

        elseif pinType == Enum.SuperTrackingMapPinType.TaxiNode then
            if superTrackingMap then
                local taxiNodes = C_TaxiMap.GetTaxiNodesForMap(superTrackingMap)

                if addon.DEBUG then
                    print("[Mapzeroth] DEBUG: Looking for taxi node", typeID, "on map", superTrackingMap)
                    print("[Mapzeroth] DEBUG: Found", taxiNodes and #taxiNodes or 0, "taxi nodes on this map")
                    if taxiNodes then
                        for i, node in ipairs(taxiNodes) do
                            print(string.format("  [%d] nodeID=%s, name=%s", i, tostring(node.nodeID),
                                node.name or "nil"))
                        end
                    end
                end

                for _, node in ipairs(taxiNodes or {}) do
                    if node.nodeID == typeID then
                        return {
                            mapID = superTrackingMap,
                            x = node.position.x,
                            y = node.position.y,
                            name = node.name or "Flight Path",
                            source = "taxi_node"
                        }
                    end
                end

                if self.DEBUG then
                    print("[Mapzeroth] DEBUG: Taxi node", typeID, "not found in list, falling through")
                end
            end

        elseif pinType == Enum.SuperTrackingMapPinType.QuestOffer then
            -- Quest POIs - ignore for now

        elseif pinType == Enum.SuperTrackingMapPinType.DigSite then
            -- Archaeology - ignore for now

        elseif pinType == Enum.SuperTrackingMapPinType.HousingPlot then
            -- Housing PLots - ignore for now
        end
    end

    -- Fallback: Check for user waypoint (Ctrl+click placed pin)
    local waypoint = C_Map.GetUserWaypoint()
    if waypoint and waypoint.uiMapID and waypoint.position then
        return {
            mapID = waypoint.uiMapID,
            x = waypoint.position.x,
            y = waypoint.position.y,
            name = "User Waypoint",
            source = "user_waypoint"
        }
    end

    -- Fallback: TomTom if installed
    if TomTom and TomTom.waypoints then
        for mapID, waypointsOnMap in pairs(TomTom.waypoints) do
            for uid, waypointData in pairs(waypointsOnMap) do
                if waypointData[1] and waypointData[2] and waypointData[3] then
                    return {
                        mapID = waypointData[1],
                        x = waypointData[2],
                        y = waypointData[3],
                        name = waypointData.title or "TomTom Waypoint",
                        source = "tomtom"
                    }
                end
            end
        end
    end

    return nil, "No active waypoint found."
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
            return nil
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
        return nil
    end

    -- Calculate time based on distance
    local canFly = not addon.NO_FLY_MAPS[mapID]
    local speed = canFly and addon.FLY_SPEED or addon.WALK_SPEED
    local time = math.ceil(distance / speed / 5) * 5
    return math.max(1.5, math.min(300, time)), canFly and "fly" or "walk"
end
