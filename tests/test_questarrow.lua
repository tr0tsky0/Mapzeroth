-- The route arrow on the game's own quest tracker (UI/QuestArrow.lua), with a stand-in for its quest module: after each
-- layout every quest block on show gets an arrow beside its first line below the title, for that block's quest; a block
-- with no lines has none; the arrow lights with the title's hover; nothing is written on the game's frames.

local QA = addon.QuestArrow
check(QA, "the quest arrow loads")

local function region()
    local r = { shown = true, scripts = {}, points = {}, hooks = {} }
    function r:SetSize() end
    function r:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function r:ClearAllPoints() self.points = {} end
    function r:SetScript(k, fn) self.scripts[k] = fn end
    function r:HookScript(k, fn) self.hooks[k] = fn end
    function r:SetAlpha(a) self.alpha = a end
    function r:Show() self.shown = true end
    function r:Hide() self.shown = false end
    function r:RegisterForClicks() end
    function r:SetTexture(t) self.texture = t end
    function r:SetRotation(a) self.rotation = a end
    function r:SetVertexColor(...) self.color = { ... } end
    function r:CreateTexture() return region() end
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

-- A quest block as the tracker keeps it: its quest's id, its title and title button, its lines by objective key.
local function block(id, lines)
    local b = region()
    b.id, b.used, b.usedLines = id, true, lines or { o1 = {} }
    b.HeaderText = region()
    b.HeaderText.GetFont = function() return "font", 12 end
    b.HeaderButton = region()
    return b
end
local blocks = { block(101), block(102, {}) }
local layouts = 0
QuestObjectiveTracker = {
    lineSpacing = 4,
    EndLayout = function() layouts = layouts + 1 end,
    EnumerateActiveBlocks = function(self, fn) for _, b in ipairs(blocks) do fn(b) end end,
}

QA.HookTracker()
check(#made == 1, "hooking it places arrows on what is already shown, and only on blocks with lines")
local arrow = made[1]
check(arrow.kind == "Button" and arrow.parent == blocks[1] and arrow.questID == 101, "on the quest's block, for its quest")
local p = arrow.points[1]
check(p[1] == "CENTER" and p[2] == blocks[1].HeaderText and p[3] == "BOTTOMLEFT" and p[4] == -QA.GAP and p[5] == -10,
      "under the quest's map pin, level with its first line (4 below the title, half the 12 px font): "
      .. tostring(p[4]) .. "," .. tostring(p[5]))
check(arrow.tex.rotation < 0 and arrow.tex.texture:find("Media\\Arrow$"), "our arrow, tilted")
check(blocks[1].mzArrow == nil and blocks[1].arrow == nil, "nothing of ours is written on the game's block")

QuestObjectiveTracker:EndLayout()
check(layouts == 1 and #made == 1, "the tracker's own layout runs first, and a block keeps its one arrow")
QA.HookTracker()
QuestObjectiveTracker:EndLayout()
check(layouts == 2, "hooked once only")

-- The block is reused for another quest; another loses its lines (an objective done and the list shortened).
blocks[1].id = 205
blocks[2].usedLines = { o1 = {} }
QuestObjectiveTracker:EndLayout()
check(arrow.questID == 205, "a reused block's arrow routes to its new quest")
check(#made == 2 and made[2].questID == 102, "a block that gains a line gets its arrow")
blocks[1].usedLines = {}
QuestObjectiveTracker:EndLayout()
check(not arrow.shown, "a block with no lines below its title hides its arrow")
blocks[1].usedLines = { o1 = {} }
QuestObjectiveTracker:EndLayout()
check(arrow.shown, "and shows it again")

-- Lit with the title's hover, as the tracker lights the title.
local dim = arrow.alpha
check(dim < 1, "dim until the mouse is on its quest's title")
blocks[1].HeaderButton.over = true; blocks[1].HeaderButton.hooks.OnEnter()
check(arrow.alpha == 1, "the mouse on the title lights it")
blocks[1].HeaderButton.over = false; blocks[1].HeaderButton.hooks.OnLeave()
check(arrow.alpha == dim, "off it, dim again")

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
broken.HeaderText.GetFont = function() error("boom") end
table.insert(blocks, 1, broken)
arrow.questID = nil
QuestObjectiveTracker:EndLayout()
check(reported and tostring(reported):find("boom"), "an error of ours is reported")
check(arrow.questID == 205, "the other blocks still get theirs")

addon.Panel.RouteToQuest, geterrorhandler = realRouteToQuest, realHandler
CreateFrame, hooksecurefunc, QuestObjectiveTracker = realCreateFrame, realHook, nil
