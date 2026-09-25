-- PathFactors.lua (Forever)
--
-- Measured ratio of real walking distance to straight-line distance, by map.
-- Walk costs multiply the straight line by this (default
-- addon.DEFAULT_PATH_FACTOR for maps not listed). Measure with:
--   /mzr walktime start   (at one spot)
--   /mzr walktime stop    (at the other, after walking the way you would)
-- and add the printed mapID and factor here.

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

addon.PathFactors = {
    [1453] = 1.7, -- Stormwind City: 210s walked vs 123s predicted straight-line (flight master to harbor)
    [1429] = 1.06, -- Elwynn Forest: 79s over 526 yd (Stormwind gates to Goldshire inn) along the main road, which is nearly straight. Winding or hilly roads will be higher.
    [1455] = 1.98, -- Ironforge: 45s over 162 yd (flight master to tram entrance). One short, near-worst-case sample (the route loops around the Great Forge); expect this to come down with more measurements.
}
