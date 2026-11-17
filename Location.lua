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
    -- A broader map than ours (a waypoint set with the continent map showing): down to the zone under the spot.
    local child = C_Map.GetMapInfoAtPosition and C_Map.GetMapInfoAtPosition(mapID, x, y)
    if child and child.mapID and child.mapID ~= mapID and continent then
        local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, child.mapID)
        if pos then
            local cx, cy = pos:GetXY()
            return knownMap(child.mapID, cx, cy)
        end
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
    return addon:PlaceAt(point.uiMapID, x, y, "WAYPOINT")
end

-- Where a quest is on the map: mapID, x, y, or nil. A world quest has its own spot; a log quest its map pin (the
-- objective area, or the turn-in once it is done); failing both, the game's next waypoint for it (on the way there,
-- such as a portal), as its arrow shows.
local function questSpot(questID)
    local task = C_TaskQuest
    if task and task.GetQuestZoneID and task.GetQuestLocation then
        local mapID = task.GetQuestZoneID(questID)
        if mapID and mapID > 0 then
            local x, y = task.GetQuestLocation(questID, mapID)
            if x and y then return mapID, x, y end
        end
    end
    local log = C_QuestLog
    if not log then return nil end
    local maps = {}
    if type(GetQuestUiMapID) == "function" then maps[#maps + 1] = GetQuestUiMapID(questID) end
    maps[#maps + 1] = C_Map.GetBestMapForUnit("player")
    for _, mapID in ipairs(maps) do
        if mapID and mapID > 0 and log.GetQuestsOnMap then
            for _, info in ipairs(log.GetQuestsOnMap(mapID) or {}) do
                if info.questID == questID and info.x and info.y then return mapID, info.x, info.y end
            end
        end
    end
    if log.GetNextWaypoint then
        local mapID, x, y = log.GetNextWaypoint(questID)
        if mapID and x and y then return mapID, x, y end
    end
end

-- The quest the player is following (the one the game's arrow points to) as a destination node
-- { id, mapID, x, y, questID, title }, or nil when none is followed or it has no spot we can place.
function addon:GetQuestTarget()
    local track = C_SuperTrack
    local questID = track and track.GetSuperTrackedQuestID and track.GetSuperTrackedQuestID()
    if not questID or questID == 0 then return nil end
    local mapID, x, y = questSpot(questID)
    local place = mapID and addon:PlaceAt(mapID, x, y, "QUEST")
    if not place then return nil end
    place.questID = questID
    place.title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID) or nil
    return place
end

-- A position (a map and 0-1 coordinates) as a place the planner can route to, { id, mapID, x, y }, or nil when it is on
-- a map we can't place (no nodes on it or any map above it). The id is `prefix` and the spot, rounded, so the same spot
-- always has the same id (distances are cached by id).
function addon:PlaceAt(mapID, x, y, prefix)
    local knownID, kx, ky = knownMap(mapID, x, y)
    if not knownID then return nil end
    local id = ("%s_%d_%d_%d"):format(prefix, knownID, math.floor(kx * 2000 + 0.5), math.floor(ky * 2000 + 0.5))
    return { id = id, mapID = knownID, x = kx, y = ky }
end

-- The waypoints TomTom has set, as points { mapID, x, y, name } (x and y 0-1), or nil when TomTom isn't loaded
-- (another addon's data: read only, never changed). TomTom keeps them by map, each { mapID, x, y, title = ... }.
function addon:GetTomTomPoints()
    local waypoints = type(TomTom) == "table" and type(TomTom.waypoints) == "table" and TomTom.waypoints
    if not waypoints then return nil end
    local points = {}
    for _, onMap in pairs(waypoints) do
        if type(onMap) == "table" then
            for _, point in pairs(onMap) do
                if type(point) == "table" and point[1] and point[2] and point[3] then
                    points[#points + 1] = { mapID = point[1], x = point[2], y = point[3], name = point.title }
                end
            end
        end
    end
    -- TomTom's tables have no order: by map, then from top to bottom, so the same waypoints always read the same.
    table.sort(points, function(a, b)
        if a.mapID ~= b.mapID then return a.mapID < b.mapID end
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    return points
end

-- The map a zone name means ("Elwynn Forest", any case), for /way lines that name the zone instead of giving "#37":
-- among the maps we have nodes on, by the client's name for each. Nil when none is called that.
local mapsByName
function addon:MapByName(name)
    if not (name and C_Map and C_Map.GetMapInfo) then return nil end
    if not mapsByName then
        mapsByName = {}
        addon.World:ForEachNode(function(node)
            local info = node.mapID and C_Map.GetMapInfo(node.mapID)
            local key = info and info.name and info.name:lower()
            if key and not mapsByName[key] then mapsByName[key] = node.mapID end
        end)
    end
    return mapsByName[name:lower():gsub("^%s+", ""):gsub("%s+$", "")]
end
