local addonName, addon = ...

-- The route on the minimap, for the trip being followed (Navigator hands it over): the same looks as on the
-- world map (dots on foot, dashes for flights, solid for boats, each on a dark casing in the theme's map colours,
-- and the same markers: where steps start, teleports, stops and the end), smaller, drawn round the player. Lines and
-- markers are drawn with RouteLines' own pieces (textured runs, badges).
--
-- The minimap is a window on the world, centred on the player, north up unless the player has set it to rotate:
-- round, unless a minimap addon has made it square or square in some corners (it says so through the global
-- GetMinimapShape(), as minimap buttons read it). How many yards it spans depends on its zoom and on whether the player is indoors (the client
-- has separate zoom scales for each, and no call to ask which, so it is found by nudging the zoom and seeing
-- which of its two settings follows, falling back to IsIndoors()). Each piece of the route is worked out in yards on the
-- map the player is on, with how far along it each point is (so the dots stay put on the ground as the player
-- moves), and every 0.1 s its runs are shifted to the player, turned if the minimap rotates, scaled to pixels
-- and clipped to its shape. A marker past the rim isn't shown (the navigator's arrow already points the way).
-- It draws nothing if the client can't do this (IsAvailable), or the setting is
-- off. Colours come from the theme.

local MinimapLines = {}
addon.MinimapLines = MinimapLines

local Theme = addon.Theme
local MapRoute = addon.MapRoute

-- How many yards the minimap spans across, by zoom level (0 furthest out).
local SIZES = {
    indoor = { [0] = 300, 240, 180, 120, 80, 50 },
    outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
}

local SCALE = 0.7              -- lines and markers, against their size on a zone map
local MARGIN = 3               -- keep the route off the rim
local INTERVAL = 0.1           -- seconds between redraws
local DONE_ALPHA = 0.35        -- steps already done fade

local state = { plan = nil, current = nil, lines = {}, used = 0, casings = {}, casingsUsed = 0, badges = {}, badgesUsed = 0,
                indoors = false, built = nil, pieces = {}, markers = {} }
MinimapLines.state = state     -- for tests and tools

-- Can this client draw on the minimap? (The settings page says so when it can't.)
function MinimapLines:IsAvailable()
    return Minimap ~= nil and type(Minimap.GetZoom) == "function" and type(Minimap.GetWidth) == "function"
        and type(GetPlayerFacing) == "function" and C_Map ~= nil and type(C_Map.GetPlayerMapPosition) == "function"
        and type(C_Map.GetBestMapForUnit) == "function" and type(CreateFrame) == "function"
end

local function enabled()
    return addon.Options:Get("showRouteOnMinimap")
end

-- Find out whether the minimap is on its indoor or outdoor zoom scale (see the top of the file). The client
-- keeps one zoom setting (CVar) for each and changes the one for the mode it is in when the zoom changes,
-- so: nudge the zoom to a level neither setting has, see which setting followed, and put it back. If neither
-- did (a client that updates them later), the game's own IsIndoors() decides, and failing that, outdoors.
local function refreshIndoors()
    if not (GetCVar and Minimap.SetZoom) then return end
    local zoom = Minimap:GetZoom()
    local outdoorBefore, indoorBefore = tonumber(GetCVar("minimapZoom")), tonumber(GetCVar("minimapInsideZoom"))
    local target
    for level = 0, 5 do
        if level ~= zoom and level ~= outdoorBefore and level ~= indoorBefore then target = level break end
    end
    local indoors
    if target then
        Minimap:SetZoom(target)
        local outdoorAfter, indoorAfter = tonumber(GetCVar("minimapZoom")), tonumber(GetCVar("minimapInsideZoom"))
        Minimap:SetZoom(zoom)
        if outdoorAfter ~= outdoorBefore then indoors = false
        elseif indoorAfter ~= indoorBefore then indoors = true end
    end
    if indoors == nil then indoors = IsIndoors ~= nil and IsIndoors() and true or false end
    state.indoors = indoors
    state.built = nil
end

local function yardsAcross()
    local scale = SIZES[state.indoors and "indoor" or "outdoor"]
    return scale[Minimap:GetZoom()] or scale[3]
end

-- How many yards the minimap spans now, and whether that is taken from the indoor scale (for the tools).
function MinimapLines:YardsAcross()
    if not self:IsAvailable() then return nil end
    return yardsAcross(), state.indoors
end

-- The zoom and zone events only matter while a trip is drawn: listen for them then, and not the rest of the session.
local function watchIndoors(on)
    local frame = state.frame
    if not frame or state.watching == on then return end
    state.watching = on
    local method = on and frame.RegisterEvent or frame.UnregisterEvent
    if not method then return end
    pcall(method, frame, "MINIMAP_UPDATE_ZOOM")
    pcall(method, frame, "ZONE_CHANGED_NEW_AREA")
end

local function ensureFrame()
    if state.frame then return state.frame end
    local frame = CreateFrame("Frame", nil, Minimap)
    frame:SetAllPoints(Minimap)
    frame:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 2)
    frame:SetScript("OnUpdate", function(_, elapsed)
        state.since = (state.since or 0) + elapsed
        if state.since >= INTERVAL then
            state.since = 0
            MinimapLines:Update()
        end
    end)
    frame:SetScript("OnEvent", function() refreshIndoors() end)
    state.frame = frame
    watchIndoors(state.plan ~= nil)
    refreshIndoors()
    return frame
end

local function acquire(frame, pool, used, layer)
    state[used] = state[used] + 1
    local line = state[pool][state[used]]
    if not line then
        line = frame:CreateLine(nil, layer)
        state[pool][state[used]] = line
    end
    line:Show()
    return line
end

-- One run, on its casing.
local function run(frame, look, x1, y1, x2, y2, from, to, thickness, r, g, b, alpha)
    local place = addon.RouteLines.PlaceRun
    local cr, cg, cb, ca = Theme:MapColor("casing", state.plan and state.plan.holiday)
    place(acquire(frame, "casings", "casingsUsed", "ARTWORK"), look, true, frame, "CENTER", x1, y1, x2, y2, from, to,
        thickness, cr, cg, cb, ca * alpha)
    place(acquire(frame, "lines", "used", "OVERLAY"), look, false, frame, "CENTER", x1, y1, x2, y2, from, to,
        thickness, r, g, b, alpha)
end

local function acquireBadge(frame)
    state.badgesUsed = state.badgesUsed + 1
    local badge = state.badges[state.badgesUsed]
    if not badge then
        badge = addon.RouteLines.NewBadge(frame)
        state.badges[state.badgesUsed] = badge
    end
    badge:Show()
    return badge
end

local function hideAll()
    for i = 1, state.used do state.lines[i]:Hide() end
    for i = 1, state.casingsUsed do state.casings[i]:Hide() end
    for i = 1, state.badgesUsed do state.badges[i]:Hide() end
    state.used, state.casingsUsed, state.badgesUsed = 0, 0, 0
end

-- The route in yards on map `mapID` (x east, y south): each piece's points with how far along it they are, and the
-- markers.
local function rebuild(mapID)
    state.pieces, state.markers = {}, {}
    state.built = { mapID = mapID, plan = state.plan }
    local xScale, yScale = addon.Navigation.YardsPerUnit(mapID)
    if not xScale then return end
    local pieces, markers = MapRoute:Pieces(state.plan, mapID)
    for _, piece in ipairs(pieces) do
        local points, along = {}, 0
        for i, p in ipairs(piece.points) do
            local x, y = p.x * xScale, p.y * yScale
            if i > 1 then along = along + math.sqrt((x - points[i - 1].x) ^ 2 + (y - points[i - 1].y) ^ 2) end
            points[i] = { x = x, y = y, along = along }
        end
        state.pieces[#state.pieces + 1] = { style = piece.style, step = piece.step, points = points }
    end
    for _, marker in ipairs(markers) do
        local copy = {}
        for k, v in pairs(marker) do copy[k] = v end
        copy.x, copy.y = marker.x * xScale, marker.y * yScale
        state.markers[#state.markers + 1] = copy
    end
end

local function draw(frame)
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or (px == 0 and py == 0) then return end

    local width = Minimap:GetWidth()
    if not width or width <= 0 then return end
    local radius = width / 2 - MARGIN
    -- Round unless a minimap addon has made it square (or square in some corners) and says so.
    local shape = type(GetMinimapShape) == "function" and GetMinimapShape() or "ROUND"
    local quarters = MapRoute.MINIMAP_SHAPES[shape] or MapRoute.MINIMAP_SHAPES.ROUND
    local ypp = yardsAcross() / width
    local built = state.built
    if not built or built.mapID ~= mapID or built.plan ~= state.plan then rebuild(mapID) end
    local xScale, yScale = addon.Navigation.YardsPerUnit(mapID)
    if not xScale then return end
    local playerX, playerY = px * xScale, py * yScale

    -- The minimap turns with the player if they have set it to.
    local angle = 0
    if GetCVar and GetCVar("rotateMinimap") == "1" then angle = -(GetPlayerFacing() or 0) end
    local function toPixels(x, y)
        local east, north = x - playerX, -(y - playerY)
        if angle ~= 0 then east, north = MapRoute.Rotate(east, north, angle) end
        return east / ypp, north / ypp
    end

    local unit = 1
    local mine, ui = frame:GetEffectiveScale(), UIParent and UIParent:GetEffectiveScale()
    if mine and ui and mine > 0 then unit = ui / mine end

    local LOOK = addon.RouteLines.LOOK
    for _, piece in ipairs(state.pieces) do
        local look = LOOK[piece.style] or LOOK.foot
        local thickness = look.thickness * SCALE * unit
        local r, g, b = Theme:MapColor(LOOK[piece.style] and piece.style or "foot", state.plan and state.plan.holiday)
        local alpha = (state.current and piece.step < state.current) and DONE_ALPHA or 1
        for i = 1, #piece.points - 1 do
            local p, q = piece.points[i], piece.points[i + 1]
            local ax, ay = toPixels(p.x, p.y)
            local bx, by = toPixels(q.x, q.y)
            if bx ~= ax or by ~= ay then
                for _, part in ipairs(MapRoute.ClipShape(ax, ay, bx, by, radius, quarters)) do
                    -- Where the clipped run starts and ends along the line, in pixels, so the pattern stays on the ground.
                    local x1, y1, x2, y2 = part[1], part[2], part[3], part[4]
                    local start = p.along / ypp
                    local from = start + math.sqrt((x1 - ax) ^ 2 + (y1 - ay) ^ 2)
                    local to = start + math.sqrt((x2 - ax) ^ 2 + (y2 - ay) ^ 2)
                    run(frame, look, x1, y1, x2, y2, from, to, thickness, r, g, b, alpha)
                end
            end
        end
    end

    for _, marker in ipairs(state.markers) do
        local x, y = toPixels(marker.x, marker.y)
        if MapRoute.InsideShape(x, y, radius, quarters) then
            local badge = acquireBadge(frame)
            badge:SetScale(unit * SCALE)
            badge:ClearAllPoints()
            badge:SetPoint("CENTER", frame, "CENTER", x / (unit * SCALE), y / (unit * SCALE))
            addon.RouteLines.StyleBadge(badge, marker, state.current, state.plan and state.plan.holiday)
        end
    end
end

-- Draw the route for where the player is now. Never raises an error into the minimap.
function MinimapLines:Update()
    hideAll()
    if not (state.plan and enabled() and self:IsAvailable()) then return end
    local frame = ensureFrame()
    local ok, err = pcall(draw, frame)
    if not ok then
        state.error = err
        hideAll()
    end
end

-- Follow this plan (the trip being followed) and its current step; nil stops. Called as the trip updates.
function MinimapLines:Follow(plan, current)
    state.current = current
    if plan == state.plan then
        if state.frame and not plan then hideAll() end
        return
    end
    state.plan = plan
    state.built = nil
    watchIndoors(plan ~= nil)
    if not plan then
        hideAll()
        if state.frame then state.frame:Hide() end
        return
    end
    if enabled() and self:IsAvailable() then
        ensureFrame():Show()
        self:Update()
    end
end

-- The settings: switching it on or off takes effect at once.
addon.Options:OnChange(function(key)
    if key ~= "showRouteOnMinimap" then return end
    if enabled() and state.plan and MinimapLines:IsAvailable() then
        ensureFrame():Show()
        MinimapLines:Update()
    else
        hideAll()
        if state.frame then state.frame:Hide() end
    end
end)
