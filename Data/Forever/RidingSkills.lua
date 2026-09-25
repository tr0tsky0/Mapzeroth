-- RidingSkills.lua (Forever)
--
-- Ground mount speed by riding skill. `bonus` is a multiplier on top of base
-- run speed (0.60 = +60%). Values confirmed on the Forever beta:
-- Apprentice (skill 75) = +60%, Journeyman (skill 150) = +100%.
--
-- The spell IDs are the Classic ones. `/mzr speed` confirmed on the Forever
-- beta that both resolve to the right spells ("Apprentice Riding", "Journeyman
-- Riding"). Not yet confirmed: that a character who has learned one reports it
-- as known, since nothing tested so far is high enough level.

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

-- Riding data decides mounted speed when a dataset has it: a character is mounted only as fast as the skills
-- they know. So Forever has no flat mount bonus (Modern's Data/Modern/Movement.lua sets one instead of skills).
addon.DEFAULT_MOUNT_BONUS = nil

addon.RidingSkills = {
    { spellID = 33388, bonus = 0.60 }, -- Apprentice Riding (skill 75)
    { spellID = 33391, bonus = 1.00 }, -- Journeyman Riding (skill 150)
}
