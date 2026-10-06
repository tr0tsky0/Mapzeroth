-- Movement.lua (Modern) -- HAND-MAINTAINED. How fast a Modern character is taken to travel.
--
-- Modern has no riding-skill data (Forever's Data/Forever/RidingSkills.lua lists the skill spells), so
-- instead of reading the player's skills every character is taken to have a ground mount: +100% run speed
-- outdoors (14 yards a second on the 7 of WALK_SPEED), the Master Riding figure. Indoors nobody mounts, so a
-- walk there stays at 7 (MovementSpeed.lua). Flying is addon.FLY_SPEED (Constants.lua: +750% with skyriding).
-- Deliberate: characters level fast on Modern and the riding skills are nearly free, so a per-character check
-- (and the spell ids it would need) is not worth it.

local addonName, addon = ...
if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern's (Constants.lua)

addon.DEFAULT_MOUNT_BONUS = 1.0

-- Class forms that raise run speed, as Forever's GroundForms (Data/Forever/Abilities.lua; read by MovementSpeed.lua):
-- `bonus` is the form's own, and each of `talents` adds perRank for every point the character has in it (ctx.talentRank
-- reads the talent tree). Outdoors the assumed mount is faster than any of these, so they only matter indoors, where
-- both work. Travel Form is outdoor-only and no faster than the mount; Aspect of the Cheetah is a short burst on a
-- cooldown here, not a constant aspect as on Forever, so neither is listed. Values given by the player (2026-10-06).
addon.Abilities = addon.Abilities or {}
addon.Abilities.GroundForms = {
    -- A talent that also speeds up the character out of the form (Feline Swiftness always; Winds of Al'Akir is +3%
    -- always and +5% more in Ghost Wolf) is counted as all form speed: a walk long enough to matter is taken in the
    -- form anyway, so its out-of-form share never decides anything.
    -- Druid: Cat Form, +30%; Feline Swiftness +15%.
    { spellID = 768, bonus = 0.30, talents = { { spellID = 131768, perRank = 0.15 } }, indoorCapable = true },
    -- Shaman: Ghost Wolf, +30%; Winds of Al'Akir +8% a rank (2 ranks), Spirit Wolf +20%.
    { spellID = 2645, bonus = 0.30, talents = { { spellID = 382215, perRank = 0.08 }, { spellID = 260878, perRank = 0.20 } },
      indoorCapable = true },
}
