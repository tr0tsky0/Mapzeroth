-- Game.lua (Modern) -- HAND-MAINTAINED. Facts about the game this dataset is for that aren't places or
-- travel: the classes it has and its seasonal events.

local addonName, addon = ...
if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern's (Constants.lua)

-- The classes a trainer can be for; their names come from the client.
addon.CLASS_TOKENS = {
    WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true, DEATHKNIGHT = true,
    SHAMAN = true, MAGE = true, WARLOCK = true, MONK = true, DRUID = true, DEMONHUNTER = true, EVOKER = true,
}

-- Seasonal-event portals (a `requirements = { holiday = "..." }` edge): each key is the set of calendar
-- iconTexture ids the event's day entry can show, matched by PlayerAbilities.lua's ctx.holidayActive against
-- C_Calendar's day events. Keep the keys equal to HOLIDAY_KEYS in tools/gen_modern_edges.py. Optional: a dataset
-- without it has no holiday edges.
addon.HOLIDAYS = {
    love_is_in_the_air = { 235466, 235467, 235468 },
    darkmoon_faire = { 235446, 235447, 235448 },
    feast_of_winters_veil = { 235482, 235484, 235485 },
}
