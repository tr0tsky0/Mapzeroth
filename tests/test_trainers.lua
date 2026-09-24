addon.World:Build()

local function find(pred)
    for _, node in ipairs(addon.Nodes.Pois) do if pred(node) then return node end end
end
local function relevant(node, overrides) return addon.Trainers:IsRelevant(node, makeCtx(overrides)) end

-- 1. Class trainers: your class only.
local mage = find(function(n) return n.trainer == "MAGE" and n.city == "stormwind" end)
check(relevant(mage, { class = "MAGE" }), "a mage sees the mage trainer")
check(not relevant(mage, { class = "DRUID" }), "a druid doesn't")

-- 2. Weapon masters: only when they teach a weapon your class can learn and you lack.
local stormwind = find(function(n) return n.trainer == "WEAPON" and n.city == "stormwind" end)  -- polearms, swords, staves, daggers, crossbows
local darnassus = find(function(n) return n.trainer == "WEAPON" and n.city == "darnassus" end)  -- staves, bows, daggers, thrown, fist
check(relevant(stormwind, { class = "MAGE" }), "a mage can learn swords, staves and daggers in Stormwind")
check(relevant(darnassus, { class = "MAGE" }), "and staves and daggers in Darnassus")
check(relevant(stormwind, { class = "PALADIN" }), "a paladin can learn polearms and swords in Stormwind")
check(not relevant(darnassus, { class = "PALADIN" }), "but nothing in Darnassus (staves, bows, daggers, thrown, fist)")
-- ...and drops out once you have everything it teaches that you could learn.
check(not relevant(stormwind, { class = "MAGE", spells = { 201, 227, 1180 } }),
    "a mage who knows swords, staves and daggers is done with Stormwind")
check(relevant(stormwind, { class = "MAGE", spells = { 227, 1180 } }), "one weapon still to learn keeps it")

-- 3. Professions: a profession you have, until you outgrow the trainer.
local tailor = find(function(n) return n.trainer == "TAILORING" and n.city == "stormwind" end)
check(not relevant(tailor, { class = "MAGE" }), "no tailoring, no tailoring trainers")
check(relevant(tailor, { class = "MAGE", spells = { 3908 } }), "an Apprentice tailor sees the trainers")
-- The Stormwind tailoring node holds trainers that teach up to Journeyman and up to Expert.
check(relevant(tailor, { class = "MAGE", spells = { 3908, 3909 } }), "a Journeyman still has the Expert rank to learn")
check(not relevant(tailor, { class = "MAGE", spells = { 3908, 3909, 3910 } }), "an Expert has outgrown them all")

-- The place holding a given trainer NPC, and that NPC's record.
local function findNPC(id)
    for _, node in ipairs(addon.Nodes.Pois) do
        for _, npc in ipairs(node.npcs or {}) do
            if npc.id == id then return node, npc end
        end
    end
end
local function relevantIDs(node, overrides)
    local ids = {}
    for _, npc in ipairs(addon.Trainers:RelevantNPCs(node, makeCtx(overrides))) do ids[npc.id or 0] = true end
    return ids
end

-- Master-tier trainers teach the last rank, which an Expert hasn't got yet.
local master = findNPC(11052)   -- Timothy Worthington, Master Tailor: 3908, 3909, 3910, 12180
check(master and relevant(master, { class = "MAGE", spells = { 3908, 3909, 3910 } }), "an Expert tailor still has Artisan to learn")
check(master and not relevant(master, { class = "MAGE", spells = { 3908, 3909, 3910, 12180 } }), "an Artisan is done")

-- A trainer won't talk to a player whose rank is well below its top rank: Timothy's is Artisan (4). An Apprentice (1)
-- is told they need more training; from Journeyman (2) on he talks to them, and teaches the next rank.
check(master and not relevant(master, { class = "MAGE", spells = { 3908 } }), "the Artisan trainer isn't offered to an Apprentice: he won't talk to them")
check(master and relevant(master, { class = "MAGE", spells = { 3908, 3909 } }), "a Journeyman can talk to him: he teaches Expert")
-- The trainers an Apprentice can use are the ones that teach Journeyman and talk to them.
check(relevant(tailor, { class = "MAGE", spells = { 3908 } }), "an Apprentice still has Stormwind's Journeyman and Expert trainers")

-- Only the rank after yours: a trainer that teaches nothing you can learn next isn't useful, however high it goes.
local function synthetic(teaches) return { kind = "trainer", trainer = "TAILORING", npcs = { { id = 1, teaches = teaches } } } end
check(not relevant(synthetic({ 12180 }), { class = "MAGE", spells = { 3908, 3909 } }), "a trainer of only Artisan has nothing for a Journeyman, who needs Expert first")
check(relevant(synthetic({ 12180 }), { class = "MAGE", spells = { 3908, 3909, 3910 } }), "but an Expert is ready for it")
check(not relevant(synthetic({ 3909 }), { class = "MAGE", spells = { 3908, 3909 } }), "and one that teaches only what you know has nothing")
check(relevant(synthetic({ 3909, 3910 }), { class = "MAGE", spells = { 3908 } }), "an Expert-tier trainer talks to an Apprentice and teaches Journeyman")
check(not relevant(synthetic({ 3909, 3910, 12180 }), { class = "MAGE", spells = { 3908 } }), "an Artisan-tier one doesn't, even though it lists Journeyman")

-- A page that lists another profession's ranks doesn't make a trainer relevant to it.
local telathir, telathirNPC = findNPC(5500)   -- Journeyman Alchemist
check(telathir and #telathirNPC.teaches == 1 and telathirNPC.teaches[1] == 2259, "Tel'Athir teaches only alchemy ranks")
check(not relevantIDs(telathir, { class = "MAGE", spells = { 2366 } })[5500], "so a herbalist doesn't need him")
check(not relevantIDs(telathir, { class = "MAGE", spells = { 2259 } })[5500], "and an alchemist has already learned all he teaches (Apprentice)")
local marsh = findNPC(4609)   -- Doctor Marsh, Expert Alchemist: Apprentice and Journeyman
check(relevantIDs(marsh, { class = "MAGE", spells = { 2259 } })[4609], "an Apprentice alchemist needs Journeyman from Doctor Marsh")
check(not relevantIDs(marsh, { class = "MAGE", spells = { 2259, 3101 } })[4609], "a Journeyman has outgrown him")

-- Specialization trainers stay in the drill-down.
local shadoweave = findNPC(9584)
check(shadoweave and not relevant(shadoweave, { class = "MAGE", spells = { 3908 } }), "Shadoweave tailoring isn't shown by default")

-- No rank data isn't the same as teaching nothing.
local melynn = findNPC(4159)   -- Expert Tailor with no rank list from Wowhead
check(melynn and relevant(melynn, { class = "MAGE", spells = { 3908, 3909, 3910 } }), "unknown teaching: shown to anyone with the profession")
check(melynn and not relevant(melynn, { class = "MAGE" }), "but not to someone without it")
check(relevant(find(function(n) return n.trainer == "RIDING" and n.city == "orgrimmar" end), { class = "MAGE" }),
    "a riding instructor with no teach list is still shown")

-- 4. Riding and pets.
local riding = find(function(n) return n.trainer == "RIDING" and n.mapID == 1426 end)
check(relevant(riding, { class = "MAGE" }), "riding ranks you don't know are worth showing")
check(relevant(riding, { class = "MAGE", spells = { 33388 } }), "Journeyman Riding still to learn")
check(not relevant(riding, { class = "MAGE", spells = { 33388, 33391 } }), "both riding ranks known, nothing left")
local pet = find(function(n) return n.trainer == "PET" end)
check(pet and relevant(pet, { class = "HUNTER" }), "pet trainers are for hunters")
check(pet and not relevant(pet, { class = "WARLOCK" }), "not warlocks")
local demon = find(function(n) return n.trainer == "DEMON" and n.city == "stormwind" end)
check(demon, "Stormwind has a demon trainer place")
check(demon and relevant(demon, { class = "WARLOCK" }), "demon trainers are for warlocks")
check(demon and not relevant(demon, { class = "HUNTER" }), "not hunters")
-- Pet trainers are their own NPCs, not the hunter class trainers.
local karrina = find(function(n) return n.trainer == "PET" and n.city == "stormwind" end)
check(karrina and karrina.npcs and karrina.npcs[1].id == 2879, "Karrina Mekenda is Stormwind's pet trainer")
check(not find(function(n) return n.trainer == "HUNTER" and n.npcs and n.npcs[1].id == 2879 end), "and no longer a hunter class trainer")

-- 5. Anything that isn't a trainer is always relevant.
local inn = find(function(n) return n.kind == "inn" end)
check(relevant(inn, { class = "MAGE" }), "an inn is not filtered")

-- Finding 8: Forever's own classes, perks and (no) holidays come from Data/Forever/Game.lua.
local classCount = 0
for _ in pairs(addon.CLASS_TOKENS) do classCount = classCount + 1 end
check(classCount == 9 and not addon.CLASS_TOKENS.DEATHKNIGHT, "Forever has its nine classes")
check(addon.FREQUENT_FLIER and addon.FREQUENT_FLIER.spellID == 1225490, "Forever has the Frequent Flier perk")
check(addon.HOLIDAYS == nil, "Forever has no holiday table")
