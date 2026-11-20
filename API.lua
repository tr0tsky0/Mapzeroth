local addonName, addon = ...

-- The public API other addons call: the global MapzerothAPI. Callers test `if MapzerothAPI then` and need no
-- OptionalDeps. Everything here goes through the panel, as the quest arrow and the waypoint prompt do.
--
-- MapzerothAPI.RouteTo(points, name, options)
--   points:  { mapID = n, x = 0-1, y = 0-1, name = "optional" }, or a list of them. Several points are visited in the
--            quickest order (the tour planner), as pasted /way lines are.
--   name:    the route's title (optional).
--   options: { start = true } starts the trip as soon as it is planned; otherwise the route waits for Start.
--   Returns true, or false and why ("no points", "bad point N", "too many points": MAX_POINTS at most).

local API = { version = 1, MAX_POINTS = 50 }    -- more stops than that would plan for a very long time
MapzerothAPI = API

local L = addon.L

-- One point checked and copied: nil when it isn't a map and a 0-1 position.
local function readPoint(p)
    if type(p) ~= "table" then return nil end
    local mapID, x, y = tonumber(p.mapID), tonumber(p.x), tonumber(p.y)
    if not (mapID and x and y) or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return { mapID = mapID, x = x, y = y, name = type(p.name) == "string" and p.name ~= "" and p.name or nil }
end

function API.RouteTo(points, name, options)
    if type(points) ~= "table" then return false, "no points" end
    if points.mapID then points = { points } end               -- a single point
    if #points > API.MAX_POINTS then return false, "too many points" end
    local list = {}
    for i, p in ipairs(points) do
        local point = readPoint(p)
        if not point then return false, "bad point " .. i end
        list[i] = point
    end
    if #list == 0 then return false, "no points" end

    if type(name) ~= "string" or name == "" then
        name = #list == 1 and (list[1].name or L["ROUTE_STOP_UNNAMED"]:format(1)) or L["TOUR_STOPS"]:format(#list)
    end
    if #list == 1 and not list[1].name then list[1].name = name end     -- its stop reads as the route, not "Stop 1"
    local start = type(options) == "table" and options.start
    addon.Panel:RouteToPoints(name, list, start)
    return true
end
