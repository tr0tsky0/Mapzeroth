-- The route arrow on the game's own quest tracker (UI/QuestArrow.lua), with a stand-in for its quest module: after each
-- layout every quest block on show gets a boxed arrow at its title's right end, where Spoken puts its Play box (under
-- the item button when there is one), or just left of Spoken's box when it shows one; it lights with the title's
-- hover; nothing is written on the game's frames.

local QA = addon.QuestArrow
check(QA, "the quest arrow loads")

local function region()
    local r = { shown = true, scripts = {}, points = {}, hooks = {}, level = 5 }
    function r:SetSize(w, h) self.w, self.h = w, h end
    function r:SetWidth(w) self.w = w end
    function r:SetHeight(h) self.h = h end
    function r:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function r:SetAllPoints() end
    function r:ClearAllPoints() self.points = {} end
    function r:SetScript(k, fn) self.scripts[k] = fn end
    function r:HookScript(k, fn) self.hooks[k] = fn end
    function r:SetAlpha(a) self.alpha = a end
    function r:Show() self.shown = true end
    function r:Hide() self.shown = false end
    function r:IsShown() return self.shown end
    function r:RegisterForClicks() end
    function r:SetTexture(t) self.texture = t end
    function r:SetColorTexture(...) self.fill = { ... } end
    function r:SetAtlas(a) self.atlas = a end
    function r:SetBlendMode() end
    function r:SetRotation(a) self.rotation = a end
    function r:SetVertexColor(...) self.color = { ... } end
    function r:SetFrameLevel(l) self.level = l end
    function r:GetFrameLevel() return self.level end
    function r:CreateTexture(_, layer) local t = region(); t.layer = layer; self.textures = self.textures or {}
        table.insert(self.textures, t); return t end
    function r:IsMouseOver() return self.over == true end
    return r
end

local made = {}
local realCreateFrame, realHook = CreateFrame, hooksecurefunc
CreateFrame = function(kind, name, parent)
    local b = region()
    b.kind, b.parent = kind, parent
    made[#made + 1] = b
    return b
end
hooksecurefunc = function(t, key, post)
    local original = t[key]
    t[key] = function(...) original(...); post(...) end
end

-- A quest block as the tracker keeps it: its quest's id, its title button, and the item button on its right edge.
local function block(id)
    local b = region()
    b.id, b.used = id, true
    b.HeaderButton = region()
    return b
end
local blocks = { block(101), block(102) }
local layouts = 0
QuestObjectiveTracker = {
    EndLayout = function() layouts = layouts + 1 end,
    EnumerateActiveBlocks = function(self, fn) for _, b in ipairs(blocks) do fn(b) end end,
}

QA.HookTracker()
check(#made == 2, "hooking it places arrows on the quests already shown")
local arrow = made[1]
check(arrow.kind == "Button" and arrow.parent == blocks[1] and arrow.questID == 101, "on the quest's block, for its quest")
local p = arrow.points[1]
check(p[1] == "TOPRIGHT" and p[2] == blocks[1] and p[3] == "TOPRIGHT" and p[4] == 0 and p[5] == 0,
      "at the title's right end, where Spoken's box would be")
check(arrow.level == blocks[1].level + 3, "drawn over the block, as Spoken's box is")
check(arrow.tex.rotation < 0 and arrow.tex.texture:find("Media\\Arrow$") and arrow.tex.color[1] == 1
      and arrow.tex.color[2] == QA.YELLOW[2], "our arrow, tilted, in the tracker's yellow")
local back, edges = nil, 0
for _, t in ipairs(arrow.textures) do
    if t.layer == "BACKGROUND" then back = t elseif t.layer == "BORDER" and t.fill and t.fill[2] == QA.YELLOW[2] then edges = edges + 1 end
end
check(back and back.fill[1] == 0 and back.fill[4] == 0.6 and edges == 4,
      "in a box: black behind, a thin yellow outline (drawn, without the checkbox art)")
check(blocks[1].mzArrow == nil and blocks[1].arrow == nil, "nothing of ours is written on the game's block")

QuestObjectiveTracker:EndLayout()
check(layouts == 1 and #made == 2, "the tracker's own layout runs first, and a block keeps its one arrow")
QA.HookTracker()
QuestObjectiveTracker:EndLayout()
check(layouts == 2, "hooked once only")

-- An item button on the quest: under it, as Spoken goes. Spoken's box on the quest: ours just left of it.
local item = region()
blocks[1].rightEdgeFrame = item
QuestObjectiveTracker:EndLayout()
p = arrow.points[1]
check(p[2] == item and p[3] == "BOTTOMRIGHT" and p[5] == -2, "under the quest's item button")
-- Spoken_Quests keeps its quest part on the VoiceOver table (its files run in that environment), not as a global.
QuestOverlayUI = { ShowsTrackerButton = function() return true end }
QuestObjectiveTracker:EndLayout()
check(arrow.points[1][4] == 0, "a global QuestOverlayUI isn't Spoken's: Spoken's is on VoiceOver")
QuestOverlayUI = nil
local packsLoaded = false
local overlay = { ShowsTrackerButton = function(_, id) return packsLoaded and id == 101 end }
local sweeps = 0
overlay.UpdateTrackerButtons = function() sweeps = sweeps + 1 end
VoiceOver = { QuestOverlayUI = overlay }
local callbacks = {}
Spoken = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end }
QA.FollowSpoken()
check(callbacks.VOICE_PACKS_LOADED and callbacks.PART_SWITCHED, "it follows Spoken's packs loading and its part switching")
check(arrow.points[1][4] == 0, "before Spoken's packs load, Spoken shows no box: ours takes the place")
packsLoaded = true
callbacks.VOICE_PACKS_LOADED()
p = arrow.points[1]
check(p[2] == item and p[4] == -(QA.SPOKEN + QA.SPOKEN_GAP),
      "once they load, without the tracker laying out again, ours moves left of Spoken's box")
check(made[2].points[1][4] == 0, "a quest Spoken has no box for keeps ours in the place")
packsLoaded = false
overlay.UpdateTrackerButtons()
check(sweeps == 1 and arrow.points[1][4] == 0, "Spoken's own redraw (its settings) moves ours too, after its own")
packsLoaded = true
QuestObjectiveTracker:EndLayout()
overlay.ShowsTrackerButton = function() error("Spoken changed") end
QuestObjectiveTracker:EndLayout()
check(arrow.points[1][4] == 0, "a Spoken that errors is taken as no box")
VoiceOver, Spoken = nil, nil

-- The block is reused for another quest, or stops being used.
blocks[1].id = 205
QuestObjectiveTracker:EndLayout()
check(arrow.questID == 205, "a reused block's arrow routes to its new quest")
blocks[2].used = nil
QuestObjectiveTracker:EndLayout()
check(not made[2].shown, "a block no longer used hides its arrow")

-- The arrow dims, the box stays; lit with the title's hover, as the tracker lights the title.
local dim = arrow.tex.alpha
check(dim < 1 and arrow.alpha == nil, "the arrow is dim until the mouse is on its quest's title; the box isn't")
blocks[1].HeaderButton.over = true; blocks[1].HeaderButton.hooks.OnEnter()
check(arrow.tex.alpha == 1, "the mouse on the title lights it")
blocks[1].HeaderButton.over = false; blocks[1].HeaderButton.hooks.OnLeave()
check(arrow.tex.alpha == dim, "off it, dim again")

-- A click routes.
local routed
local realRouteToQuest = addon.Panel.RouteToQuest
addon.Panel.RouteToQuest = function(_, id) routed = id; return true end
arrow.scripts.OnClick(arrow)
check(routed == 205, "a click routes to the block's quest")

-- One bad block doesn't stop the rest, and the error is reported.
local reported
local realHandler = geterrorhandler
geterrorhandler = function() return function(err) reported = err end end
local broken = block(300)
broken.GetFrameLevel = function() error("boom") end
table.insert(blocks, 1, broken)
arrow.questID = nil
QuestObjectiveTracker:EndLayout()
check(reported and tostring(reported):find("boom"), "an error of ours is reported")
check(arrow.questID == 205, "the other blocks still get theirs")

addon.Panel.RouteToQuest, geterrorhandler = realRouteToQuest, realHandler
CreateFrame, hooksecurefunc, QuestObjectiveTracker = realCreateFrame, realHook, nil
