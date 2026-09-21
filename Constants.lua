local addonName, addon = ...

-- Yards per second at 100% run speed. Everything faster is a bonus multiplier
-- on top of this (see the design doc, section 3).
addon.WALK_SPEED = 7

-- Roads wind: real walking distance is longer than the straight line between
-- two points. Walk costs multiply the straight-line distance by this, or by a
-- per-map value from addon.PathFactors (measured; see Data/Forever/PathFactors.lua).
-- 1.15 is a guess for open country, nudged down from 1.3 after Elwynn's main
-- road measured 1.06 (cities measured 1.7-2.0). Refine with more samples.
addon.DEFAULT_PATH_FACTOR = 1.15

-- Seconds added per loading screen when totalling a route.
addon.DEFAULT_LOADING_SCREEN_TAX = 10     -- the player can change it (Options.lua)

-- Seconds taken off for each extra flight leg flown straight through: a through-ticket doesn't land
-- and take off again. Measured 15-45 s per ticket in game; 10 s is a cautious per-leg start.
-- Keep equal to CHAIN_SAVING in tools/gen_flights.py.
addon.FLIGHT_CHAIN_SAVING = 10

-- The classes a trainer can be for; their names come from the client.
addon.CLASS_TOKENS = {
    WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
    SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}

-- Auto-generated `fly` edges (only where a ruleset has flying) connect nodes
-- within this many yards of each other, continent-wide.
addon.MAX_AUTO_EDGE_DISTANCE = 3000

-- Loading screens an edge incurs when it doesn't say (edge.loadingScreens
-- overrides). Anything not listed defaults to 0.
addon.DEFAULT_LOADING_SCREENS = { portal = 1, teleport = 1, hearthstone = 1, tram = 2 }

-- Forever reports WOW_PROJECT_ID == WOW_PROJECT_MAINLINE, so the interface
-- version is the only reliable discriminator: 16001 for Forever vs a six-digit
-- number for Modern.
addon.RULESET_INTERFACE_THRESHOLD = 20000

-- override is "forever" | "modern" | nil (auto-detect).
function addon:GetRuleset(override)
    if override == "forever" or override == "modern" then
        return override
    end
    local _, _, _, interfaceVersion = GetBuildInfo()
    return (interfaceVersion < addon.RULESET_INTERFACE_THRESHOLD) and "forever" or "modern"
end
