-- Game.lua (Forever) -- HAND-MAINTAINED. Facts about the game this dataset is for that aren't places or
-- travel: the classes it has, the perks that change how fast a trip is, and how the picker lays out its page.

local addonName, addon = ...
if addon.RULESET ~= "forever" then return end   -- one addon for both games: this data is Forever's (Constants.lua)

-- The classes a trainer can be for; their names come from the client.
addon.CLASS_TOKENS = {
    WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
    SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}

-- The "Frequent Flier" legacy perk: 50% off flight-path fares (already covered for free by FlightKnowledge's
-- empirically-learned FareFactor -- it measures the client's actual shown price against the base fare, so
-- whatever the real stacking rule with reputation is, the observed ratio already reflects it) and a 20% faster
-- flight-path mount, which none of our baked-in flight `cost` seconds account for on their own -- see
-- addon:GetFlightSpeedMultiplier (MovementSpeed.lua). Optional: a dataset without it has no such perk.
addon.FREQUENT_FLIER = { spellID = 1225490, speedBonus = 0.20 }

-- The picker's main page lists cities and towns (Sections.lua), not Modern's expansions.
addon.PICKER_LAYOUT = "settlements"
