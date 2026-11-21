local addonName, addon = ...

-- Back to the corpse: with the routeToCorpse setting on, releasing your spirit brings up the route from the graveyard
-- to where you died and starts it. The ghost only walks (TravelGraph:Build reads ctx.ghost). Coming back to life ends
-- that trip, and takes up again the one it replaced. A death inside an instance isn't routed: the corpse is in the
-- dungeon, past its entrance.
--
-- With TomTom loaded, the corpseWith setting says who takes the ghost back: Mapzeroth's route, TomTom's arrow, or both
-- ("ask": the question on release, UI/WaypointPrompt.lua). For TomTom, its own corpse waypoint is used when that's on
-- in TomTom; otherwise we set one through TomTom:AddWaypoint and take it away again once alive.

local Corpse = {}
addon.Corpse = Corpse

Corpse.DELAY = 1                -- seconds after release: the ghost is at the graveyard (maybe after a loading screen)

local died                      -- where the player died this session: { mapID, x, y }, or nil
local tomtomUid                 -- the TomTom waypoint we set for the corpse, or nil
local putAside                  -- the trip the run back replaced: { entry, returnTo }, taken up again once alive

local function playerSpot()
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end
    local x, y = pos:GetXY()
    return { mapID = mapID, x = x, y = y }
end

local function inInstance()
    return type(IsInInstance) == "function" and IsInInstance() and true or false
end

-- The corpse as a place to route to ({ id, mapID, x, y, corpse = true }), or nil. The game's own position for it on the
-- map the ghost is on, else where the player was when they died.
function addon:GetCorpseTarget()
    local spot
    local info = C_DeathInfo
    local here = C_Map.GetBestMapForUnit("player")
    if info and info.GetCorpseMapPosition and here then
        local pos = info.GetCorpseMapPosition(here)
        if pos then
            local x, y = pos:GetXY()
            if x and y and (x > 0 or y > 0) then spot = { mapID = here, x = x, y = y } end
        end
    end
    spot = spot or died
    local place = spot and addon:PlaceAt(spot.mapID, spot.x, spot.y, "CORPSE")
    if place then place.corpse = true end
    return place
end

-- Whether the trip being followed goes to the corpse.
local function headingToCorpse()
    local entry = addon.Navigation:IsActive() and addon.Navigation:ReplanTarget()
    return entry and entry.dest and entry.dest.corpse or false
end

function Corpse:OnDead()
    died = not inInstance() and playerSpot() or nil
end

local function tomtomLoaded()
    return type(TomTom) == "table" and type(TomTom.AddWaypoint) == "function"
end

-- TomTom's own "set a waypoint when I die" (another addon's setting: read only).
local function tomtomOwnArrow()
    local profile = TomTom.profile
    return type(profile) == "table" and type(profile.general) == "table" and profile.general.corpse_arrow == true
end

-- Take the ghost back: with = "mapzeroth", "tomtom" or "both".
function Corpse:Lead(with)
    if with ~= "tomtom" then
        local entry, returnTo = addon.Navigation:ReplanTarget()
        if entry and not (entry.dest and entry.dest.corpse) then putAside = { entry = entry, returnTo = returnTo } end
        addon.Panel:RouteToCorpse()
    end
    if with == "mapzeroth" or not tomtomLoaded() or tomtomOwnArrow() or tomtomUid then return end
    local corpse = addon:GetCorpseTarget()
    if corpse then
        tomtomUid = TomTom:AddWaypoint(corpse.mapID, corpse.x, corpse.y,
            { title = addon.L["PICK_CORPSE"], persistent = false, from = "Mapzeroth" })
    end
end

-- Released (PLAYER_ALIVE as a ghost).
function Corpse:OnReleased()
    if not addon.Options:Get("routeToCorpse") or inInstance() then return end
    C_Timer.After(Corpse.DELAY, function()
        if not (UnitIsGhost and UnitIsGhost("player")) then return end      -- brought back in the meantime
        local with = tomtomLoaded() and addon.Options:Get("corpseWith") or "mapzeroth"
        if with == "ask" then addon.WaypointPrompt:ShowCorpse() else Corpse:Lead(with) end
    end)
end

-- Alive again (at the corpse, or a spirit healer): the run back is over, and the trip it replaced (if any) carries on,
-- planned again from here: the run back may still be going (a spirit healer), have got there, or be over. Only a trip
-- the player started on the way back is left as it is.
function Corpse:OnAlive()
    died = nil
    local resume = putAside
    putAside = nil
    local entry = addon.Navigation:ReplanTarget()                   -- nil once the run back has got there
    local other = entry ~= nil and not (entry.dest and entry.dest.corpse)
    if resume and not other then
        addon.Navigator:Resume(resume.entry, resume.returnTo)
    elseif headingToCorpse() then
        addon.Navigation:Stop()
    end
    if addon.WaypointPrompt:IsCorpseShown() then addon.WaypointPrompt:Hide() end
    if tomtomUid then
        if tomtomLoaded() and type(TomTom.RemoveWaypoint) == "function" then TomTom:RemoveWaypoint(tomtomUid) end
        tomtomUid = nil
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_DEAD" then
        Corpse:OnDead()
    elseif event == "PLAYER_ALIVE" then
        -- Fires on release (now a ghost) and on being brought back before releasing.
        if UnitIsGhost and UnitIsGhost("player") then Corpse:OnReleased() else Corpse:OnAlive() end
    else
        Corpse:OnAlive()
    end
end)
