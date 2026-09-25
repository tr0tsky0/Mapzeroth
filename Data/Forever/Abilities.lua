-- Abilities.lua (Forever)
--
-- Things a player can do from ANYWHERE to reach a node: class teleports,
-- hearthstone-style items, etc. They are "Anywhere -> Node" edges: the
-- engine builds a real edge from the player's current location to `to` when
-- the ability is usable, so there's no `from` here.
--
-- Usability is detected by checking whether the player knows the spell
-- (or has the item), NOT by hard-coding a required level. `cost` is the
-- cast time in seconds; `cooldown` is in seconds (0 = none). Loading-screen
-- tax for teleports depends on where you cast from, so it's derived by the
-- engine, not stored here.

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

addon.Abilities = addon.Abilities or {}

-- Skyborne racial "Read Ley Line" (2 s cast, 2 min cooldown): Health and Mana regeneration
-- +100% for 15 min at a ley line, 15 s anywhere else. Only Skyborne have it, so knowing
-- it is what makes ley line places relevant (Relevance.lua). It has no bearing on travel.
addon.LeyLineSpell = 1259705

-- Class forms that raise ground speed without a mount. `indoorCapable` says
-- whether the bonus still applies indoors. Spell IDs are the Classic ones and
-- were confirmed to name "Travel Form" and "Ghost Wolf" on the Forever beta
-- (`/mzr speed`); "known" detection is still untested. Ghost Wolf becomes
-- indoor-capable with the Improved Ghost Wolf talent; that needs its own
-- spell ID before we can model it.
addon.Abilities.GroundForms = {
    { spellID = 783,  bonus = 0.40, indoorCapable = false }, -- Druid: Travel Form
    { spellID = 2645, bonus = 0.40, indoorCapable = false }, -- Shaman: Ghost Wolf
}

addon.Abilities.Teleports = {
    -- Druid: Teleport: Moonglade. 10s cast, no cooldown (confirmed live).
    -- Landing spot captured live as TELEPORT_MOONGLADE.
    -- spellID 18960 confirmed live.
    -- No class requirement: only a druid can know the spell, so knowing it is the check.
    { spellID = 18960, to = "TELEPORT_MOONGLADE", cost = 10, cooldown = 0 },

    -- Mage: the six Classic city teleports (10 s cast, no cooldown, a Rune of Teleportation each). Spell ids are
    -- Classic's, confirmed on Forever (/mzdump spells, 2026-09-24). PROVISIONAL landing:
    -- each city's centre node until the real arrival spot is captured in game (Stormwind's map was redrawn, so
    -- Classic's spots can't be trusted). Only a mage knows these, so knowing the spell is the check.
    { spellID = 3561, to = "CITY_STORMWIND", cost = 10, cooldown = 0 },     -- Teleport: Stormwind
    { spellID = 3562, to = "CITY_IRONFORGE", cost = 10, cooldown = 0 },     -- Teleport: Ironforge
    { spellID = 3565, to = "CITY_DARNASSUS", cost = 10, cooldown = 0 },     -- Teleport: Darnassus
    { spellID = 3563, to = "CITY_UNDERCITY", cost = 10, cooldown = 0 },     -- Teleport: Undercity
    { spellID = 3566, to = "CITY_THUNDER_BLUFF", cost = 10, cooldown = 0 }, -- Teleport: Thunder Bluff
    { spellID = 3567, to = "CITY_ORGRIMMAR", cost = 10, cooldown = 0 },     -- Teleport: Orgrimmar
}

-- The hearthstone takes you to the inn you're bound at, which isn't fixed data: it is
-- wherever the player last bound (see Hearth.lua), so there is no `to` here and `bind`
-- says so. It's an item you must carry. 10s cast; the 3600s cooldown is the Classic
-- value and UNVERIFIED for Forever (the live cooldown is what routing actually reads).
addon.Abilities.Hearthstones = {
    { itemID = 6948, spellID = 8690, bind = true, cost = 10, cooldown = 3600, method = "hearthstone" },
    -- Shaman: Astral Recall (spell 556, confirmed on Forever), the same bound inn on its own cooldown (10 s cast, 15 min:
    -- Classic's values; routing reads the live cooldown anyway). A spell, so no itemID: knowing it is the check.
    { spellID = 556, cost = 10, cooldown = 900, method = "hearthstone" },
}
