-- Movement.lua (Modern) -- HAND-MAINTAINED. How fast a Modern character is taken to travel.
--
-- Modern has no riding-skill data (Forever's Data/Forever/RidingSkills.lua lists the skill spells), so
-- instead of reading the player's skills every character is taken to have a ground mount: +100% run speed
-- outdoors (14 yards a second on the 7 of WALK_SPEED), the Master Riding figure. Indoors nobody mounts, so a
-- walk there stays at 7 (MovementSpeed.lua). Flying is addon.FLY_SPEED (Constants.lua: +750% with skyriding).
-- Deliberate: characters level fast on Modern and the riding skills are nearly free, so a per-character check
-- (and the spell ids it would need) is not worth it.

local addonName, addon = ...

addon.DEFAULT_MOUNT_BONUS = 1.0
