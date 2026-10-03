-- The picker's tooltip on a trainer: a profession trainer's rank, what a weapon master can still teach your
-- class, and what your class trainer has left for you (remembered from the last visit, ClassTraining.lua).
addon.World:Build()
local L = addon.L
C_Spell = { GetSpellInfo = function(id) return { name = "Skill " .. id } end }

local function findNode(pred)
    for _, node in ipairs(addon.Nodes.Pois) do if pred(node) then return node end end
end
local function texts(lines)
    local out = {}
    for _, line in ipairs(lines or {}) do out[#out + 1] = line[1] end
    return table.concat(out, "\n")
end
local function has(lines, text) return texts(lines):find(text, 1, true) ~= nil end
local function entryFor(node) return { name = "Place", group = "trainer", nodeID = node.id } end

-- 1. Weapon masters: only the weapons your class can learn and hasn't.
local stormwind = findNode(function(n) return n.trainer == "WEAPON" and n.city == "stormwind" end) -- 200 201 202 227 1180 5011
local info = addon.Trainers:Describe(stormwind, makeCtx({ class = "MAGE", spells = { 227 } }))
check(info.kind == "weapon", "a weapon master")
check(#info.learnable == 2 and info.learnable[1] == 201 and info.learnable[2] == 1180, "a mage with staves can still learn swords and daggers")
local lines = addon.Panel.TooltipLines(entryFor(stormwind), makeCtx({ class = "MAGE", spells = { 227 } }))
check(has(lines, "Skill 201") and has(lines, "Skill 1180") and not has(lines, "Skill 227") and not has(lines, "Skill 200"),
    "the tooltip lists swords and daggers, not staves (known) or polearms (not a mage's)")
lines = addon.Panel.TooltipLines(entryFor(stormwind), makeCtx({ class = "MAGE", spells = { 201, 227, 1180 } }))
check(has(lines, L["TIP_NOTHING_NEW"]), "nothing left: says so")

-- 2. Profession trainers: each trainer's rank and the skill it trains up to; yours.
local master = findNode(function(n)
    for _, npc in ipairs(n.npcs or {}) do if npc.id == 11052 then return true end end   -- Master tailor (tier 4, recipes up to 300)
end)
info = addon.Trainers:Describe(master, makeCtx({ spells = { 3908, 3909, 3910 } }))
check(info.kind == "profession" and info.rank == 3 and info.has, "an Expert tailor")
local artisan
for _, npc in ipairs(info.npcs) do if npc.top == 5 then artisan = npc end end
check(artisan and artisan.useful, "the Master trainer is useful to an Expert")
lines = addon.Panel.TooltipLines(entryFor(master), makeCtx({ spells = { 3908, 3909, 3910 } }))
check(has(lines, L["TIP_PROF_YOUR_RANK"]:format(L["PROF_RANK_3"])), "shows your rank")
check(has(lines, L["TIP_PROF_TRAINER"]:format(L["PROF_RANK_5"], 300)), "and the trainer's: its title tier, Master, up to 300")
lines = addon.Panel.TooltipLines(entryFor(master), makeCtx({}))
check(has(lines, L["TIP_PROF_NOT_KNOWN"]), "a player without tailoring is told so")
lines = addon.Panel.TooltipLines(entryFor(master), makeCtx({ spells = { 3908, 3909, 3910, 12180 } }))
check(has(lines, L["TIP_NOTHING_NEW"]), "an Artisan has nothing to learn there")

-- 3. Class trainers: from the class's abilities by level (Data/Forever/ClassSpells.lua), no visit needed.
local mage = findNode(function(n) return n.trainer == "MAGE" and n.city == "stormwind" end)
local druid = findNode(function(n) return n.trainer == "DRUID" end)
local function spellIn(class, pred)
    for _, spell in ipairs(addon.ClassSpells[class]) do if pred(spell) then return spell end end
end
local function learnableIDs(status)
    local ids = {}
    for _, spell in ipairs(status.learnable) do ids[spell[1]] = true end
    return ids
end
local noneOwned = function() return false end
check(addon.Panel.TooltipLines(entryFor(druid), makeCtx({ class = "MAGE" })) == nil, "another class's trainer has no tooltip")

-- Frostbolt: Rank 1 (116) at 4, Rank 2 after it.
local frost2 = spellIn("MAGE", function(s) return s.after == 116 end)
check(frost2, "Frostbolt Rank 2 follows Rank 1")
local status = addon.ClassTraining:Status(makeCtx({ class = "MAGE", level = 4 }), noneOwned)
check(learnableIDs(status)[116] and not learnableIDs(status)[frost2[1]], "a level 4 mage can learn Frostbolt, not Rank 2 yet")
check(status.nextLevel and status.nextLevel > 4, "and is told when more comes")
check(not learnableIDs(addon.ClassTraining:Status(makeCtx({ class = "MAGE", level = 4, spells = { 116 } }), noneOwned))[116],
    "not once it's known")
status = addon.ClassTraining:Status(makeCtx({ class = "MAGE", level = frost2[2] }), noneOwned)
check(learnableIDs(status)[116] and learnableIDs(status)[frost2[1]], "both ranks in one visit, when neither is known")
status = addon.ClassTraining:Status(makeCtx({ class = "MAGE", level = frost2[2], spells = { frost2[1] } }), noneOwned)
check(not learnableIDs(status)[116], "knowing Rank 2 means Rank 1 was learned, whatever the client says of it")
check(status.cost >= 0, "a total cost")

-- A rank whose first comes from a talent: only for players who have the ability.
C_Spell = { GetSpellInfo = function(id) return { name = "Spell " .. id } end }
local bloodthirst = spellIn("WARRIOR", function(s) return s[1] == 23892 end)
check(bloodthirst and bloodthirst.owned, "Bloodthirst Rank 2 needs the talent")
check(not learnableIDs(addon.ClassTraining:Status(makeCtx({ class = "WARRIOR", level = 60 }), noneOwned))[23892],
    "not offered without it")
check(learnableIDs(addon.ClassTraining:Status(makeCtx({ class = "WARRIOR", level = 60 }),
    function(name) return name == "Spell 23892" end))[23892], "offered with it")

-- Racial abilities: only the race's own (Divine Grace is human on Forever).
local grace = spellIn("PRIEST", function(s) return s[1] == 1277372 end)
check(grace and grace.races == 1, "Divine Grace Rank 3 is for humans")
local owns = function(name) return name == "Spell 1277371" or name == "Spell 1277372" end
check(learnableIDs(addon.ClassTraining:Status(makeCtx({ class = "PRIEST", level = 60, raceID = 1 }), owns))[1277372], "a human priest")
check(not learnableIDs(addon.ClassTraining:Status(makeCtx({ class = "PRIEST", level = 60, raceID = 3 }), owns))[1277372], "not a dwarf")

-- The tooltip: what to learn, the cost, when more comes.
lines = addon.Panel.TooltipLines(entryFor(mage), makeCtx({ class = "MAGE", level = 4 }))
check(has(lines, "Spell 116") and has(lines, "Cost:"), "lists Frostbolt, and what it all costs")
check(has(lines, L["TIP_CLASS_NEXT"]:format(addon.ClassTraining:Status(makeCtx({ class = "MAGE", level = 4 }), noneOwned).nextLevel)),
    "and the next level")
lines = addon.Panel.TooltipLines(entryFor(mage), makeCtx({ class = "MAGE", level = 1, spells = { 133, 168 } }))
check(lines and #lines >= 2, "a tooltip at level 1 too")

-- The "Nearest Class Trainer" pick needs no route to say this; a profession pick describes the nearest one.
lines = addon.Panel.TooltipLines({ name = "Nearest Class Trainer", group = "trainer", pick = true, nodeIDs = { mage.id } },
    makeCtx({ class = "MAGE", level = 4 }))
check(has(lines, "Spell 116"), "the class pick has the tooltip before pricing")
check(addon.Panel.TooltipLines({ name = "Nearest", group = "trainer", pick = true, nodeIDs = { master.id } },
    makeCtx({ spells = { 3908 } })) == nil, "a profession pick with no nearest yet has none")
lines = addon.Panel.TooltipLines({ name = "Nearest", group = "trainer", pick = true, nodeIDs = { master.id },
    nearest = master.id, where = "Stormwind Tailoring" }, makeCtx({ spells = { 3908, 3909 } }))
check(lines and lines[1][1] == "Stormwind Tailoring", "a priced pick is titled with the place it goes to")

-- The other faction's trainers: says so, and nothing about what they'd teach.
FACTION_HORDE = "Horde"
local durotarMage = findNode(function(n) return n.trainer == "MAGE" and n.mapID == 1411 and not n.city end)
lines = addon.Panel.TooltipLines(entryFor(durotarMage), makeCtx({ class = "MAGE", level = 12, faction = "Alliance" }))
check(#lines == 2 and lines[2][1] == L["TIP_OTHER_FACTION"]:format("Horde"), "an Alliance mage is told the Durotar trainer is the Horde's")
lines = addon.Panel.TooltipLines(entryFor(durotarMage), makeCtx({ class = "MAGE", level = 4, faction = "Horde" }))
check(has(lines, "Spell 116"), "a Horde mage gets the list")
local orgWeapons = findNode(function(n) return n.trainer == "WEAPON" and n.city == "orgrimmar" end)
lines = addon.Panel.TooltipLines(entryFor(orgWeapons), makeCtx({ class = "MAGE", faction = "Alliance" }))
check(has(lines, L["TIP_OTHER_FACTION"]:format("Horde")) and not has(lines, L["TIP_WEAPON_LEARN"]), "and at the Horde's weapon masters")
FACTION_HORDE = nil

-- Not a trainer: no tooltip.
check(addon.Panel.TooltipLines({ name = "Goldshire", group = "place", nodeID = "TOWN_GOLDSHIRE" }, makeCtx()) == nil, "places have none")

C_Spell = nil
