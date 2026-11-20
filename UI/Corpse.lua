local addonName, addon = ...

-- Back to the corpse: with the routeToCorpse setting on, releasing your spirit brings up the route from the graveyard
-- to where you died and starts it. The ghost only walks (TravelGraph:Build reads ctx.ghost). Coming back to life ends
-- that trip. A death inside an instance isn't routed: the corpse is in the dungeon, past its entrance.

local Corpse = {}
addon.Corpse = Corpse

Corpse.DELAY = 1                -- seconds after release: the ghost is at the graveyard (maybe after a loading screen)

local died                      -- where the player died this session: { mapID, x, y }, or nil

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

-- Released (PLAYER_ALIVE as a ghost).
function Corpse:OnReleased()
    if not addon.Options:Get("routeToCorpse") or inInstance() then return end
    C_Timer.After(Corpse.DELAY, function()
        if not (UnitIsGhost and UnitIsGhost("player")) then return end      -- brought back in the meantime
        addon.Panel:RouteToCorpse()
    end)
end

-- Alive again (at the corpse, or a spirit healer): the run back is over.
function Corpse:OnAlive()
    died = nil
    if headingToCorpse() then addon.Navigation:Stop() end
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
