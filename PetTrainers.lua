-- PetTrainers.lua
-- Hardcoded Pet Battle trainer locations for multi-destination routing.
-- Used by the "Route Pet Trainers" feature on the main GUI.
--
-- Coordinates are in WoW map fraction format (0.0–1.0), converted from
-- /way coordinates by dividing by 100.
-- Format: { name, mapID, x, y }
local addonName, addon = ...

addon.PetTrainers = {

    -----------------------------------------------------------
    -- KALIMDOR
    -- 12 trainers
    -----------------------------------------------------------
    KALIMDOR = {
        { name = "Zunta",            mapID = 1,   x = 0.438, y = 0.288 },
        { name = "Dagra the Fierce", mapID = 10,  x = 0.586, y = 0.530 },
        { name = "Analynn",          mapID = 63,  x = 0.202, y = 0.296 },
        { name = "Zonya the Sadist", mapID = 65,  x = 0.596, y = 0.716 },
        { name = "Merda Stronghoof", mapID = 66,  x = 0.572, y = 0.458 },
        { name = "Traitor Gluk",     mapID = 69,  x = 0.596, y = 0.496 },
        { name = "Elena Flutterfly", mapID = 80,  x = 0.460, y = 0.604 },
        { name = "Cassandra Kaboom", mapID = 199, x = 0.396, y = 0.792 },
        { name = "Grazzle the Great",mapID = 70,  x = 0.538, y = 0.748 },
        { name = "Zoltan",           mapID = 77,  x = 0.400, y = 0.566 },
        { name = "Kela Grimtotem",   mapID = 64,  x = 0.318, y = 0.328 },
        { name = "Stone Cold Trixxy",mapID = 83,  x = 0.656, y = 0.644 },
    },

    -----------------------------------------------------------
    -- EASTERN KINGDOMS
    -- 12 trainers
    -----------------------------------------------------------
    EASTERN_KINGDOMS = {
        { name = "Julia Stevens",     mapID = 37,  x = 0.416, y = 0.836 },
        { name = "Old MacDonald",     mapID = 52,  x = 0.608, y = 0.184 },
        { name = "Lindsay",           mapID = 49,  x = 0.332, y = 0.526 },
        { name = "Eric Davidson",     mapID = 47,  x = 0.198, y = 0.448 },
        { name = "Steven Lisbane",    mapID = 50,  x = 0.460, y = 0.404 },
        { name = "Bill Buckler",      mapID = 210, x = 0.514, y = 0.732 },
        { name = "David Kosse",       mapID = 26,  x = 0.628, y = 0.546 },
        { name = "Deiza Plaguehorn",  mapID = 23,  x = 0.6655,y = 0.5699},
        { name = "Kortas Darkhammer", mapID = 32,  x = 0.354, y = 0.274 },
        { name = "Durin Darkhammer",  mapID = 36,  x = 0.256, y = 0.476 },
        { name = "Everessa",          mapID = 51,  x = 0.766, y = 0.414 },
        { name = "Lydia Accoste",     mapID = 42,  x = 0.402, y = 0.764 },
    },

    -----------------------------------------------------------
    -- NORTHREND
    -- 5 trainers
    -----------------------------------------------------------
    NORTHREND = {
        { name = "Beegle Blastfuse",    mapID = 117, x = 0.286, y = 0.338 },
        { name = "Okrut Dragonwaste",   mapID = 115, x = 0.590, y = 0.770 },
        { name = "Major Payne",         mapID = 118, x = 0.774, y = 0.196 },
        { name = "Nearly Headless Jacob",mapID = 127, x = 0.502, y = 0.590 },
        { name = "Gutretch",            mapID = 121, x = 0.132, y = 0.668 },
    },
}

addon.Skyriding = {
    -----------------------------------------------------------
    -- OUTLAND
    -- 13 races
    -----------------------------------------------------------
    OUTLAND = {
        { name = "Hellfire Hustle",        mapID = 100, x = 0.760, y = 0.430 },
        { name = "Coilfang Caper",         mapID = 102, x = 0.370, y = 0.370 },
        { name = "Fel Pit Fracas",         mapID = 104, x = 0.520, y = 0.400 },
        { name = "Shadowmoon Slam",        mapID = 104, x = 0.620, y = 0.490 },
        { name = "Blade's Edge Brawl",     mapID = 105, x = 0.610, y = 0.280 },
        { name = "Telaar Tear",            mapID = 107, x = 0.590, y = 0.760 },
        { name = "Warmaul Wingding",       mapID = 107, x = 0.300, y = 0.250 },
        { name = "Auchindoun Coaster",     mapID = 108, x = 0.420, y = 0.680 },
        { name = "Razorthorn Rise Rush",   mapID = 108, x = 0.600, y = 0.050 },
        { name = "Skettis Scramble",       mapID = 108, x = 0.670, y = 0.660 },
        { name = "Eco-Dome Excursion",     mapID = 109, x = 0.510, y = 0.420 },
        { name = "Tempest Keep Sweep",     mapID = 109, x = 0.690, y = 0.480 },
        { name = "Shattrath City Sashay",  mapID = 111, x = 0.720, y = 0.710 },
    }
}
