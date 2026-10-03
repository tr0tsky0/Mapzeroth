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
    [1453] = 1.5, -- Stormwind City: two samples, 1.7 (210s walked vs 123s predicted straight-line, flight master to harbor) and 1.34 (90s over 611 yd at 9.1 yd/s, flight master to druid trainer); routes through the city differ, so this sits between them
    [1429] = 1.06, -- Elwynn Forest: 79s over 526 yd (Stormwind gates to Goldshire inn) along the main road, which is nearly straight. Winding or hilly roads will be higher.
    [1454] = 1.5, -- Orgrimmar: set to match Stormwind (not measured)
    [1456] = 1.5, -- Thunder Bluff: set to match Stormwind (not measured)
    [1458] = 1.9, -- Undercity: set by hand, as annoying to walk around as Ironforge or more (not measured)
    [1455] = 1.98, -- Ironforge: 45s over 162 yd (flight master to tram entrance). One short, near-worst-case sample (the route loops around the Great Forge); expect this to come down with more measurements.
}
