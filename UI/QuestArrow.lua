local addonName, addon = ...

-- A route arrow beside each quest in a quest tracker: Mapzeroth's own arrow, tilted to the upper right (the usual
-- "navigate"), under the quest's icon beside its first line below the title, where trackers leave room (their lines
-- start further in than the title). Dim until the mouse is on the quest, as the tracker lights the quest then; a click
-- routes to the quest and starts the trip. Daylight UI's tracker gets it from UI/DaylightPlugin.lua; the game's own
-- tracker from below.
--
-- The game's tracker is only hooked after the fact (hooksecurefunc, HookScript) and nothing of ours is written on its
-- frames: the arrows are kept in our own table, so its code never reads anything of ours. Quests with an item have a
-- secure button on the same block; our arrow is a plain button beside it and never touches it.

local L = addon.L

local QuestArrow = {}
addon.QuestArrow = QuestArrow

QuestArrow.SIZE = 12                -- the arrow, in pixels: about a quest icon's
QuestArrow.HIT = 16                 -- the button around it, a little bigger to hit
QuestArrow.GAP = 17                 -- its centre, left of where the line's text starts: under the quest's icon
QuestArrow.DIM = 0.55               -- its alpha until the mouse is on its quest
local TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Arrow"

-- A click on a quest's arrow: the route to it, or a word on why there isn't one.
function QuestArrow.Route(questID)
    if type(questID) ~= "number" then return end
    if addon.Panel:RouteToQuest(questID) then return end
    if UIErrorsFrame then UIErrorsFrame:AddMessage(L["QUEST_NO_SPOT"], 1, 0.1, 0.1) end
end

-- Lit while the mouse is on its quest (its hover frame) or on the arrow. Moving between the two leaves one and enters
-- the other while the mouse is still over one of them, so it stays lit.
local function light(b)
    local over = b.hover:IsMouseOver() or b:IsMouseOver()
    b:SetAlpha(over and 1 or QuestArrow.DIM)
end

-- A new arrow button on parent. hover: the frame whose hover lights it (the quest's row, or its title); its own
-- scripts are kept, ours run after them.
function QuestArrow.Make(parent, hover)
    local b = CreateFrame("Button", nil, parent)
    b.hover = hover
    b:SetSize(QuestArrow.HIT, QuestArrow.HIT)
    b.tex = b:CreateTexture(nil, "OVERLAY")
    b.tex:SetSize(QuestArrow.SIZE, QuestArrow.SIZE)
    b.tex:SetPoint("CENTER")
    b.tex:SetTexture(TEXTURE, "CLAMP", "CLAMP", "TRILINEAR")
    b.tex:SetRotation(-math.pi / 4)                   -- ours points up: tilted to the right
    b:SetAlpha(QuestArrow.DIM)
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
    return b
end

-- Puts the arrow for questID with its centre at `point` of `anchor`, GAP to the left and y down, in color r, g, b.
function QuestArrow.Place(b, questID, anchor, point, y, r, g, bl)
    b.questID = questID
    b:ClearAllPoints()
    b:SetPoint("CENTER", anchor, point, -QuestArrow.GAP, y)
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

-- The arrow on one of the tracker's quest blocks, after it is laid out. A block lists one quest (its id) and is reused
-- for another later. Its first line hangs just below the title (HeaderText), lineSpacing down, in the title's font.
function QuestArrow.OnBlock(block, lineSpacing)
    local b = blockArrows[block]
    local title = block.HeaderText
    local questID = block.id
    if not (title and type(questID) == "number" and block.used and next(block.usedLines or {})) then
        if b then b:Hide() end
        return
    end
    if not b then
        b = QuestArrow.Make(block, block.HeaderButton or block)
        blockArrows[block] = b
    end
    local _, size = title:GetFont()
    local y = -((tonumber(lineSpacing) or 0) + (tonumber(size) or QuestArrow.SIZE) / 2)
    QuestArrow.Place(b, questID, title, "BOTTOMLEFT", y, addon.Theme:Color("accent"))
end

-- Each layout of a module ends with EndLayout (the blocks no longer shown already freed): every block on show gets its
-- arrow then. An error of ours is reported (BugSack and the like) without stopping the other blocks.
local function onLayout(module)
    if type(module.EnumerateActiveBlocks) ~= "function" then return end
    module:EnumerateActiveBlocks(function(block)
        local ok, err = pcall(QuestArrow.OnBlock, block, module.lineSpacing)
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

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded("Blizzard_ObjectiveTracker", QuestArrow.HookTracker)
else
    QuestArrow.HookTracker()
end
