local addonName, addon = ...

-- Where the player is, as a starting node for the route planner. The only client-reading
-- piece of the planner, kept apart so the rest can be tested headless.

-- Our nodes cover zones, not every map (a subzone or a cave has none), so a position on a map
-- with no nodes is carried up to the nearest parent map that has some.
local function knownMap(mapID, x, y)
    local World = addon.World
    if World:GetContainerForMap(mapID) then return mapID, x, y end

    local continent, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    local info = C_Map.GetMapInfo(mapID)
    local parent = info and info.parentMapID
    while parent and parent ~= 0 do
        if World:GetContainerForMap(parent) then
            local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, parent)
            if pos then
                local px, py = pos:GetXY()
                return parent, px, py
            end
        end
        local up = C_Map.GetMapInfo(parent)
        parent = up and up.parentMapID
    end
end

-- The player as a start node { id, mapID, x, y }, or nil and a reason ("no map",
-- "no position", "unknown map") when we can't say where they are (inside an instance, say).
function addon:GetPlayerStart()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil, "no map" end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil, "no position" end
    local x, y = pos:GetXY()
    if not x or (x == 0 and y == 0) then return nil, "no position" end

    local knownID, kx, ky = knownMap(mapID, x, y)
    if not knownID then return nil, "unknown map" end
    -- The id names the spot (distances are cached by id), rounded so standing still reuses it.
    local id = ("YOU_%d_%d_%d"):format(knownID, math.floor(kx * 2000 + 0.5), math.floor(ky * 2000 + 0.5))
    return { id = id, mapID = knownID, x = kx, y = ky }
end

-- The waypoint the player has set on the map (the game's own, not an addon's) as a destination node
-- { id, mapID, x, y }, or nil when there is none, the client has no such API, or it sits on a map we
-- can't place (a position on a map with no nodes is carried up to a parent map that has some, as for the
-- player). The id names the spot, rounded, so distances to it are cached like any other node's.
function addon:GetWaypoint()
    local map = C_Map
    if not (map and map.HasUserWaypoint and map.GetUserWaypoint and map.HasUserWaypoint()) then return nil end
    local point = map.GetUserWaypoint()
    local position = point and point.position
    if not (point and point.uiMapID and position) then return nil end
    local x, y
    if position.GetXY then x, y = position:GetXY() else x, y = position.x, position.y end
    if not (x and y) then return nil end
    local knownID, kx, ky = knownMap(point.uiMapID, x, y)
    if not knownID then return nil end
    local id = ("WAYPOINT_%d_%d_%d"):format(knownID, math.floor(kx * 2000 + 0.5), math.floor(ky * 2000 + 0.5))
    return { id = id, mapID = knownID, x = kx, y = ky }
end
