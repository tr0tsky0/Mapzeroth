-- Constants.lua
-- Single source of truth for travel speeds, restrictions, and calculations
-- Used by TravelGraph, LocationService, WaypointService, and pathfinding

local addonName, addon = ...

-----------------------------------------------------------
-- TRAVEL SPEEDS (yards per second)
-----------------------------------------------------------
-- Based on actual WoW player movement speeds:
-- - Base run speed: ~12 yards/sec
-- - Flying mount (skyriding): ~60 yards/sec

addon.WALK_SPEED = 12
addon.FLY_SPEED = 60

-----------------------------------------------------------
-- DISTANCE CALCULATIONS
-----------------------------------------------------------

addon.MAP_SCALE = 1000 -- yards per map coordinate unit
addon.MAX_AUTO_EDGE_DISTANCE = 3000 -- Maximum distance for auto-generated traversal edges

-----------------------------------------------------------
-- NO-FLY ZONES
-----------------------------------------------------------
-- Maps where flying mounts are disabled or impractical
-- Used by both static graph generation and synthetic edge creation

addon.NO_FLY_MAPS = {
    -- Burning Crusade
    [94] = true, -- Eversong Woods
    [95] = true, -- Ghostlands
    [110] = true, -- Silvermoon City
    [122] = true, -- Isle of Quel'Danas

    -- Shadowlands
    [1670] = true, -- Oribos
    [1671] = true, -- Oribos (Ring)
    [1543] = true, -- The Maw
    
    -- Legion (Argus)
    [830] = true,  -- Krokuun
    [882] = true,  -- Eredath
    [883] = true,  -- Vindicaar, Argus
    [885] = true,  -- Antoran Wastes
    
    -- Mists of Pandaria
    [554] = true,  -- Timeless Isle
    
    -- The War Within
    [2346] = true, -- Undermine (11.1)
    
    -- Misc
    [407] = true,  -- Darkmoon Island
}

-----------------------------------------------------------
-- FALLBACK TRAVEL COSTS (seconds)
-----------------------------------------------------------
-- Used when distance calculation fails
-- These are estimates based on typical travel times
-- Portal/teleport costs should be instant (cast time only)

addon.TRAVEL_COSTS = {
    portal = 0,      -- Instant (cast time tracked separately)
    teleport = 0,    -- Instant (cast time tracked separately)
    hearthstone = 0, -- Cast time tracked separately
    racial = 0,      -- Cast time tracked separately
    ship = 60,       -- ~1 minute boat ride
    zeppelin = 60,   -- ~1 minute zeppelin ride
    tram = 90,       -- ~1.5 minute tram ride
    flight = 120,    -- ~2 minute flight path (average)
    walk = 30,       -- Fallback if distance calc fails
    fly = 10,        -- Fallback if distance calc fails
}

-- Travel method icons and text
addon.TRAVEL_ICONS = {
    portal = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar",
    ship = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
    tram = "Interface\\Icons\\INV_Misc_EngGizmos_20",
    flight = "Interface\\Icons\\Ability_Mount_JungleTiger",
    fly = "Interface\\Icons\\Ability_Druid_FlightForm",
    walk = "Interface\\Icons\\Ability_Rogue_Sprint",
    teleport = "Interface\\Icons\\Spell_Arcane_Teleportorgrimmar",
    hearthstone = "Interface\\Icons\\INV_Misc_Rune_01",
    racial = "Interface\\Icons\\INV_Misc_Gear_01"
}

addon.METHOD_DISPLAY_TEXT = {
    portal = "Take portal to",
    ship = "Take ship to",
    tram = "Take tram to",
    flight = "Take flight path to",
    fly = "Fly to",
    walk = "Walk to",
    teleport = "Teleport to",
    hearthstone = "Hearth to",
    racial = "Use"
}