local addonName, addon = ...

-- The public API other addons call: the global MapzerothAPI. Callers test `if MapzerothAPI then` and need no
-- OptionalDeps. Everything here goes through the panel, as the quest arrow and the waypoint prompt do.
--
-- MapzerothAPI.RouteTo(points, name, options)
--   points:  { mapID = n, x = 0-1, y = 0-1, name = "optional" }, or a list of them. Several points are visited in the
--            quickest order (the tour planner), as pasted /way lines are.
--   name:    the route's title (optional).
--   options: { start = true } starts the trip as soon as it is planned; otherwise the route waits for Start.
--            { onArrive = function() end } is called once, when the trip's last step is done (for several points, at
--            the end of the tour). Not called if the trip is stopped or another route replaces it.
--   Returns true, or false and why ("no points", "bad point N", "too many points": MAX_POINTS at most).
--
-- MapzerothAPI.TimeTo(points)
--   points:  as for RouteTo. Seconds from where the player stands to each point, by the quickest route Mapzeroth knows
--            for this character: a list in the points' order, or a number for a single point. A point that can't be
--            reached (or is on a map Mapzeroth has no data for) is nil, so read the list 1 to #points. Each call is one route search: call it when
--            the caller's list changes, not every frame.
--   Returns nil and why ("no points", "bad point N", "too many points", "no position": in an instance, say).

local API = { version = 2, MAX_POINTS = 50 }    -- more stops than that would plan for a very long time
MapzerothAPI = API

local L = addon.L

-- One point checked and copied: nil when it isn't a map and a 0-1 position.
local function readPoint(p)
    if type(p) ~= "table" then return nil end
    local mapID, x, y = tonumber(p.mapID), tonumber(p.x), tonumber(p.y)
    if not (mapID and x and y) or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return { mapID = mapID, x = x, y = y, name = type(p.name) == "string" and p.name ~= "" and p.name or nil }
end

-- The points checked and copied: a list, or nil and why.
local function readPoints(points)
    if type(points) ~= "table" then return nil, "no points" end
    if points.mapID then points = { points } end               -- a single point
    if #points > API.MAX_POINTS then return nil, "too many points" end
    local list = {}
    for i, p in ipairs(points) do
        local point = readPoint(p)
        if not point then return nil, "bad point " .. i end
        list[i] = point
    end
    if #list == 0 then return nil, "no points" end
    return list
end

function API.RouteTo(points, name, options)
    local list, why = readPoints(points)
    if not list then return false, why end

    if type(name) ~= "string" or name == "" then
        name = #list == 1 and (list[1].name or L["ROUTE_STOP_UNNAMED"]:format(1)) or L["TOUR_STOPS"]:format(#list)
    end
    if #list == 1 and not list[1].name then list[1].name = name end     -- its stop reads as the route, not "Stop 1"
    local start = type(options) == "table" and options.start
    local onArrive = type(options) == "table" and type(options.onArrive) == "function" and options.onArrive or nil
    addon.Panel:RouteToPoints(name, list, start, onArrive)
    return true
end

function API.TimeTo(points)
    local list, why = readPoints(points)
    if not list then return nil, why end
    local start = addon:GetPlayerStart()
    if not start then return nil, "no position" end
    local places, ids = {}, {}
    for i, point in ipairs(list) do
        local place = addon:PlaceAt(point.mapID, point.x, point.y, "API")
        if place and not ids[place.id] then
            places[#places + 1] = place
            ids[place.id] = true
        end
        list[i] = place
    end
    local session = addon.Journey:Build(addon:GetPlayerContext(), start, places)
    if not session then return nil, "no position" end
    local costs = next(ids) and addon.Journey:CostsTo(session, ids) or {}
    local times = {}                                -- may have holes: read it 1 to #points
    for i = 1, #list do
        times[i] = list[i] and costs[list[i].id] or nil
    end
    if points.mapID then return times[1] end
    return times
end
