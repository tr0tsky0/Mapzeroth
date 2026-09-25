-- WeaponSkills.lua (Forever)
--
-- The weapon skills each class can learn, as the skill spell ids weapon masters teach:
--   196 One-Handed Axes    197 Two-Handed Axes   198 One-Handed Maces   199 Two-Handed Maces
--   200 Polearms           201 One-Handed Swords 202 Two-Handed Swords  227 Staves
--   264 Bows               266 Guns              1180 Daggers           2567 Thrown
--   5011 Crossbows         15590 Fist Weapons
--
-- Only weapon masters teach these (class trainers teach class abilities, armor and
-- Dual Wield, not weapons). The lists are the Classic proficiencies from memory and are
-- UNVERIFIED for Forever: the picker uses them to hide weapon masters that can't teach
-- your class anything, so a wrong entry hides a useful trainer or shows a useless one.
-- Check by opening a weapon master's window on each class.

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

addon.ClassWeapons = {
    WARRIOR = { 196, 197, 198, 199, 200, 201, 202, 227, 264, 266, 1180, 2567, 5011, 15590 },
    PALADIN = { 196, 197, 198, 199, 200, 201, 202 },
    HUNTER  = { 196, 197, 200, 201, 202, 227, 264, 266, 1180, 2567, 5011, 15590 },
    ROGUE   = { 198, 201, 264, 266, 1180, 2567, 5011, 15590 },
    PRIEST  = { 198, 227, 1180 },
    SHAMAN  = { 196, 197, 198, 199, 227, 1180, 15590 },
    MAGE    = { 201, 227, 1180 },
    WARLOCK = { 201, 227, 1180 },
    DRUID   = { 198, 199, 200, 227, 1180, 15590 },
}
