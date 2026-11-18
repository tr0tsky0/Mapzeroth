local addonName, addon = ...

-- A route arrow on each quest in a quest tracker: Mapzeroth's own arrow, tilted to the upper right (the usual
-- "navigate"). A click routes to the quest and starts the trip; it is dim until the mouse is on its quest, as the
-- tracker lights the quest then.
--   * Daylight UI's tracker (UI/DaylightPlugin.lua): the plain arrow under the quest's icon, beside its first line
--     below the title, where that tracker leaves room.
--   * The game's own tracker (below): the arrow in a box at the title's right end, the look of Spoken's Play box there
--     (the quest log's checkbox: a thin yellow outline on black), left of Spoken's box when it has one for the quest,
--     else in its place. The left side has no room: the quest's map pin is big and glows on the quest you follow.
--
-- The game's tracker is only hooked after the fact (hooksecurefunc, HookScript) and nothing of ours is written on its
-- frames: the arrows are kept in our own table, so its code never reads anything of ours. No room is made for the
-- arrow either: changing a block's right edge from addon code taints the quest item button beside it (Spoken found the
-- same), so like Spoken's box it can cover the end of a long title.

local L = addon.L

local QuestArrow = {}
addon.QuestArrow = QuestArrow

-- The two looks. size: the button; glyph: the arrow in it; dim: the arrow's alpha until the mouse is on its quest.
QuestArrow.PLAIN = { size = 16, glyph = 12, dim = 0.55 }
QuestArrow.BOX = { size = 14, glyph = 10, dim = 0.85, box = true }
QuestArrow.SIZE = QuestArrow.PLAIN.glyph
QuestArrow.GAP = 17                 -- the plain arrow's centre, left of where the line's text starts: under the icon
QuestArrow.BOX_ATLAS = "QuestLog-icon-ticksquare"     -- the quest log's checkbox, as Spoken's Play box draws it
QuestArrow.YELLOW = { 1, 0.82, 0 }  -- the tracker's quest titles
QuestArrow.SPOKEN = 14              -- Spoken's Play box on the tracker, and the gap between it and ours
QuestArrow.SPOKEN_GAP = 4
local TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Arrow"

-- A click on a quest's arrow: the route to it, or a word on why there isn't one.
function QuestArrow.Route(questID)
    if type(questID) ~= "number" then return end
    if addon.Panel:RouteToQuest(questID) then return end
    if UIErrorsFrame then UIErrorsFrame:AddMessage(L["QUEST_NO_SPOT"], 1, 0.1, 0.1) end
end

-- Lit while the mouse is on its quest (its hover frame) or on the arrow. Moving between the two leaves one and enters
-- the other while the mouse is still over one of them, so it stays lit. A box stays; only its arrow dims.
local function light(b)
    local over = b.hover:IsMouseOver() or b:IsMouseOver()
    local alpha = over and 1 or b.look.dim
    if b.look.box then b.tex:SetAlpha(alpha) else b:SetAlpha(alpha) end
end

local function hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

-- The box: black behind (the tracker sits on the world, not a panel), the quest log's checkbox outline over it, and
-- the outline again, added over itself, under the pointer. A client without that art gets a drawn yellow outline.
local function dressBox(b)
    local back = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    back:SetPoint("TOPLEFT", 1, -1)
    back:SetPoint("BOTTOMRIGHT", -1, 1)
    back:SetColorTexture(0, 0, 0, 0.6)
    if hasAtlas(QuestArrow.BOX_ATLAS) then
        local border = b:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetAtlas(QuestArrow.BOX_ATLAS)
        local lit = b:CreateTexture(nil, "HIGHLIGHT")
        lit:SetAllPoints()
        lit:SetAtlas(QuestArrow.BOX_ATLAS)
        lit:SetBlendMode("ADD")
        lit:SetAlpha(0.5)
        return
    end
    local r, g, bl = unpack(QuestArrow.YELLOW)
    local edges = { { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
                    { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }
    for _, e in ipairs(edges) do
        local t = b:CreateTexture(nil, "BORDER")
        t:SetPoint(e[1])
        t:SetPoint(e[2])
        if e[3] then t:SetWidth(e[3]) else t:SetHeight(e[4]) end
        t:SetColorTexture(r, g, bl, 1)
    end
end

-- A new arrow button on parent. hover: the frame whose hover lights it (the quest's row, or its title); its own
-- scripts are kept, ours run after them. look: PLAIN (the default) or BOX.
function QuestArrow.Make(parent, hover, look)
    look = look or QuestArrow.PLAIN
    local b = CreateFrame("Button", nil, parent)
    b.hover, b.look = hover, look
    b:SetSize(look.size, look.size)
    if look.box then dressBox(b) end
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetSize(look.glyph, look.glyph)
    b.tex:SetPoint("CENTER")
    b.tex:SetTexture(TEXTURE, "CLAMP", "CLAMP", "TRILINEAR")
    b.tex:SetRotation(-math.pi / 4)                   -- ours points up: tilted to the right
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function(self) QuestArrow.Route(self.questID) end)
    b:SetScript("OnEnter", function(self)
        light(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["PANEL_TITLE"])
        GameTooltip:AddLine(L["QUEST_ROUTE_TIP"], 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        light(self)
        if GameTooltip then GameTooltip:Hide() end
    end)
    hover:HookScript("OnEnter", function() light(b) end)
    hover:HookScript("OnLeave", function() light(b) end)
    light(b)
    return b
end

-- Puts the arrow for questID: its `point` at `relPoint` of `anchor`, offset x, y; the arrow in color r, g, b.
function QuestArrow.Place(b, questID, point, anchor, relPoint, x, y, r, g, bl)
    b.questID = questID
    b:ClearAllPoints()
    b:SetPoint(point, anchor, relPoint, x, y)
    if r then b.tex:SetVertexColor(r, g, bl) end
    light(b)
    b:Show()
end

-- ---------------------------------------------------------------------------------------
-- The game's own quest tracker

-- Its modules that list quests in the quest log, by global name: the normal quests, and Retail's campaign quests.
-- (World quests, bonus objectives and the like aren't quests you carry to a spot the same way.)
QuestArrow.MODULES = { "QuestObjectiveTracker", "CampaignQuestObjectiveTracker" }

local blockArrows = setmetatable({}, { __mode = "k" })    -- a quest's block -> our arrow on it
local hooked = {}                                         -- module -> true once hooked

-- Spoken_Quests' quest part. Its files run in their own environment (setfenv to the global VoiceOver), so its
-- QuestOverlayUI is on that table, not a global.
local function spokenUI()
    local vo = _G.VoiceOver
    local ui = type(vo) == "table" and vo.QuestOverlayUI or nil
    return type(ui) == "table" and ui or nil
end

-- Whether Spoken (Spoken_Quests) puts its Play box on this quest in the tracker: it does for a quest it has a voice
-- line for, while its tracker button is on. Its own answer, read safely; no Spoken, no box.
function QuestArrow.SpokenShows(questID)
    local ui = spokenUI()
    if not ui or type(ui.ShowsTrackerButton) ~= "function" then return false end
    local ok, shows = pcall(ui.ShowsTrackerButton, ui, questID)
    return ok and shows == true
end

-- The arrow on one of the tracker's quest blocks, after it is laid out. A block lists one quest (its id) and is reused
-- for another later. Where Spoken puts its box: the block's top right corner, or under the quest's item (or group)
-- button when it has one; ours goes there, or just left of Spoken's box.
function QuestArrow.OnBlock(block)
    local b = blockArrows[block]
    local questID = block.id
    if not (type(questID) == "number" and block.used) then
        if b then b:Hide() end
        return
    end
    if not b then
        b = QuestArrow.Make(block, block.HeaderButton or block, QuestArrow.BOX)
        b:SetFrameLevel(block:GetFrameLevel() + 3)
        blockArrows[block] = b
    end
    local anchor, relPoint, y = block, "TOPRIGHT", 0
    local edge = block.rightEdgeFrame
    if edge and edge:IsShown() then anchor, relPoint, y = edge, "BOTTOMRIGHT", -2 end
    local x = QuestArrow.SpokenShows(questID) and -(QuestArrow.SPOKEN + QuestArrow.SPOKEN_GAP) or 0
    QuestArrow.Place(b, questID, "TOPRIGHT", anchor, relPoint, x, y, unpack(QuestArrow.YELLOW))
end

-- Each layout of a module ends with EndLayout (the blocks no longer shown already freed): every block on show gets its
-- arrow then. An error of ours is reported (BugSack and the like) without stopping the other blocks.
local function onLayout(module)
    if type(module.EnumerateActiveBlocks) ~= "function" then return end
    module:EnumerateActiveBlocks(function(block)
        local ok, err = pcall(QuestArrow.OnBlock, block)
        if not ok then geterrorhandler()(err) end
    end)
end

function QuestArrow.HookTracker()
    for _, name in ipairs(QuestArrow.MODULES) do
        local module = _G[name]
        if type(module) == "table" and not hooked[module] and type(module.EndLayout) == "function" then
            hooked[module] = true
            hooksecurefunc(module, "EndLayout", onLayout)
            onLayout(module)                          -- already laid out before we loaded
        end
    end
end

-- Every arrow placed again, outside a layout of the tracker.
function QuestArrow.Refresh()
    for module in pairs(hooked) do onLayout(module) end
end

-- Spoken puts its boxes on or takes them off without the tracker laying out again: when its voice packs load after
-- login, when its quest part is switched, when its settings change. Ours move with them. It loads after us (its name
-- sorts later), so this waits for login.
function QuestArrow.FollowSpoken()
    local S = _G.Spoken
    if type(S) == "table" and type(S.RegisterCallback) == "function" then
        pcall(S.RegisterCallback, S, "VOICE_PACKS_LOADED", QuestArrow.Refresh)
        pcall(S.RegisterCallback, S, "PART_SWITCHED", QuestArrow.Refresh)
    end
    local ui = spokenUI()
    if ui and type(ui.UpdateTrackerButtons) == "function" then
        hooksecurefunc(ui, "UpdateTrackerButtons", QuestArrow.Refresh)
    end
    QuestArrow.Refresh()
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded("Blizzard_ObjectiveTracker", QuestArrow.HookTracker)
else
    QuestArrow.HookTracker()
end
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    QuestArrow.FollowSpoken()
end)
