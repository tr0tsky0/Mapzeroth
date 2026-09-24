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

-- The fraction of an extra flight leg's own time saved by flying straight through: a through-ticket
-- doesn't land and take off again. Measured 15-45 s per ticket in game; 0.10 is a cautious start (10 s off
-- a 100 s leg, 30 s off a 300 s one). A fraction, not a flat number of seconds, so a short leg can never
-- be saved down to nothing (or below: a flat 10 s made a loop of 8 s legs cheaper every lap).
-- Keep equal to CHAIN_SAVING in tools/gen_flights.py.
addon.FLIGHT_CHAIN_SAVING = 0.10

-- A profession trainer won't talk to a player whose rank is too far below the trainer's top rank: an
-- Artisan (rank 4) trainer told an Apprentice (rank 1) "you need more training". Observed for that one
-- case; a trainer whose top rank is at most this many above the player's own is taken to talk to them
-- (so an Apprentice can learn Journeyman from an Expert-tier trainer, and then talk to the Artisan).
addon.PROFESSION_TRAINER_REACH = 2

-- The classes a trainer can be for; their names come from the client.
addon.CLASS_TOKENS = {
    WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
    SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}

-- Auto-generated `fly` edges (only where a ruleset has flying) connect nodes
-- within this many yards of each other, continent-wide.
addon.MAX_AUTO_EDGE_DISTANCE = 3000

-- Flying from where the player stands (TravelGraph:AddStart), when they start in the open where flying is allowed:
-- getting on the mount takes MOUNT_SECONDS, and a flight that would take under MIN_FLY_SECONDS isn't offered (it
-- is a short walk). FLY_SPEED is yards a second: at the +750% a skyriding player really covers ground (a flying
-- mount without skyriding is +410%, 35.7 yards a second), on the 7 yards a second of WALK_SPEED.
addon.FLY_SPEED = addon.WALK_SPEED * (1 + 7.50)
addon.MOUNT_SECONDS = 1.5
addon.MIN_FLY_SECONDS = 3

-- Using an equippable teleport item (a cloak, ring, trinket, tabard...) that isn't worn takes an equip step first.
-- Seconds that step is priced at unless the item's own `equipCooldown` (Data/Modern/Abilities.lua, from
-- tools/modern_manual.py's EQUIP_COOLDOWNS) says otherwise: most items can be used the moment they are put on
-- (checked in game for the ones we have), so 0; the odd one has a cooldown after equipping.
addon.DEFAULT_EQUIP_SECONDS = 0

-- What an authored walk edge with no cost of its own takes when the distance between its ends can't be
-- measured (two maps the client won't project onto one another: Oribos and its Ring). The edge says the
-- walk exists, so it is kept at a plausible price, not dropped and the places beyond it cut off.
addon.UNMEASURED_WALK_SECONDS = 20

-- Loading screens an edge incurs when it doesn't say (edge.loadingScreens
-- overrides). Anything not listed defaults to 0.
addon.DEFAULT_LOADING_SCREENS = { portal = 1, teleport = 1, hearthstone = 1, tram = 2 }

-- Seasonal-event portals (a `requirements = { holiday = "..." }` edge, Modern only so
-- far): each key is the set of calendar iconTexture ids the event's day entry can show,
-- matched by PlayerAbilities.lua's ctx.holidayActive against C_Calendar's day events.
addon.HOLIDAYS = {
    love_is_in_the_air = { 235466, 235467, 235468 },
    darkmoon_faire = { 235446, 235447, 235448 },
    feast_of_winters_veil = { 235482, 235484, 235485 },
}

-- Forever's "Frequent Flier" legacy perk: 50% off flight-path fares (already covered for
-- free by FlightKnowledge's empirically-learned FareFactor -- it measures the client's
-- actual shown price against the base fare, so whatever the real stacking rule with
-- reputation is, the observed ratio already reflects it) and a 20% faster flight-path
-- mount, which none of our baked-in flight `cost` seconds account for on their own -- see
-- addon:GetFlightSpeedMultiplier (MovementSpeed.lua).
addon.FREQUENT_FLIER = { spellID = 1225490, speedBonus = 0.20 }

-- Tool-facing API (MapzerothDataTools' /mzr world calls GetRuleset); the addon itself doesn't use
-- either: each toc loads its own dataset.
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
