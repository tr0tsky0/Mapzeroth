-- Tours.lua (Modern) -- HAND-MAINTAINED. Starter routes: added to a player's saved routes the first time (MultiRoute.lua),
-- after which they are the player's own to change or delete. Each is { name, way }: the stops as /way lines, each naming
-- its map.

local addonName, addon = ...
if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern's (Constants.lua)

addon.SampleRoutes = {
    { name = "Pet Tamers: Kalimdor", way = [[
/way #1 43.8 28.8 Zunta
/way #10 58.6 53.0 Dagra the Fierce
/way #63 20.2 29.6 Analynn
/way #65 59.6 71.6 Zonya the Sadist
/way #66 57.2 45.8 Merda Stronghoof
/way #69 59.6 49.6 Traitor Gluk
/way #80 46.0 60.4 Elena Flutterfly
/way #199 39.6 79.2 Cassandra Kaboom
/way #70 53.8 74.8 Grazzle the Great
/way #77 40.0 56.6 Zoltan
/way #64 31.8 32.8 Kela Grimtotem
/way #83 65.6 64.4 Stone Cold Trixxy
]] },
    { name = "Pet Tamers: Eastern Kingdoms", way = [[
/way #37 41.6 83.6 Julia Stevens
/way #52 60.8 18.4 Old MacDonald
/way #49 33.2 52.6 Lindsay
/way #47 19.8 44.8 Eric Davidson
/way #50 46.0 40.4 Steven Lisbane
/way #210 51.4 73.2 Bill Buckler
/way #26 62.8 54.6 David Kosse
/way #23 66.55 56.99 Deiza Plaguehorn
/way #32 35.4 27.4 Kortas Darkhammer
/way #36 25.6 47.6 Durin Darkhammer
/way #51 76.6 41.4 Everessa
/way #42 40.2 76.4 Lydia Accoste
]] },
    { name = "Pet Tamers: Outland", way = [[
/way #100 64.4 49.2 Nicki Tinytech
/way #102 17.2 50.6 Ras'an
/way #107 61.0 49.4 Narrok
/way #111 59.0 70.6 Morulu The Elder
/way #104 30.6 41.8 Bloodknight Antari
]] },
    { name = "Pet Tamers: Northrend", way = [[
/way #117 28.6 33.8 Beegle Blastfuse
/way #115 59.0 77.0 Okrut Dragonwaste
/way #118 77.4 19.6 Major Payne
/way #127 50.2 59.0 Nearly Headless Jacob
/way #121 13.2 66.8 Gutretch
]] },
    { name = "Pet Tamers: Cataclysm", way = [[
/way #198 61.4 32.8 Brok
/way #207 49.8 57.0 Bordin Steadyfist
/way #241 56.6 56.8 Goz Banefury
/way #1527 54.4 37.6 Obalis
]] },
}
