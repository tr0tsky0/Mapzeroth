-- Containers.lua (Modern) -- hand-maintained. First converted from the 1.x addon's data (2026-09); edited here since 2026-10-16.
-- Container flags: `fly = false` for no-fly zones (ground mounts only), `indoor = true` for interiors, and
-- `{ phaseGroup, phaseSide, phaseMap }` for the sides of a Zidormi zone, `pastOnly = true` for a map only the past
-- has. A changed fly flag changes
-- Geometry.lua: run /mzr dumpgeometry in Retail afterwards.

local addonName, addon = ...
if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern's (Constants.lua)

addon.Containers = addon.Containers or {}
addon.Containers[""] = { fly = true, indoor = false }   -- Modern has flying broadly, unlike Forever

addon.Containers["argus_antoran_wastes.map885"] = { fly = false } -- Antoran Wastes
addon.Containers["argus_eredath.map882"] = { fly = false } -- Eredath
addon.Containers["argus_krokuun.map830"] = { fly = false } -- Krokuun
addon.Containers["argus_vindicaar.map883"] = { fly = false } -- Vindicaar, Argus
addon.Containers["darkmoon_faire.map407"] = { fly = false } -- Darkmoon Island
addon.Containers["draenei_home.map103"] = { fly = false } -- Exodar
addon.Containers["draenei_home.map106"] = { fly = false } -- Bloodmyst Isle
addon.Containers["draenei_home.map97"] = { fly = false } -- Azuremyst Isle
addon.Containers["ek_overworld.map2509"] = { fly = false } -- Coiled Isle / Vaults of Atal'Utek (12.1) -- mount-only, no flying
addon.Containers["queldanas.map122"] = { fly = false } -- Isle of Quel'Danas
addon.Containers["quelthalas.map110"] = { fly = false } -- Silvermoon City
addon.Containers["quelthalas.map94"] = { fly = false } -- Eversong Woods
addon.Containers["quelthalas.map95"] = { fly = false } -- Ghostlands
addon.Containers["sl_oribos.map1670"] = { fly = false } -- Oribos
addon.Containers["sl_oribos.map1671"] = { fly = false } -- Oribos (Ring)
addon.Containers["sl_the_maw.map1543"] = { fly = false } -- The Maw
addon.Containers["timeless_isle.map554"] = { fly = false } -- Timeless Isle
addon.Containers["timeways.map2266"] = { fly = false } -- The Timeways -- ground mounts, no flying
addon.Containers["tol_barad.map244"] = { fly = false } -- Tol Barad -- ground mounts, no flying
addon.Containers["tol_barad.map245"] = { fly = false } -- Tol Barad Peninsula -- ground mounts, no flying (reported in game 2026-10-16)
addon.Containers["undermine.map2346"] = { fly = false } -- Undermine (11.1)

addon.Containers["broken_isles.map715.interior"] = { indoor = true } -- 9 interior node(s)
addon.Containers["broken_isles.map734.interior"] = { indoor = true } -- 1 interior node(s)
addon.Containers["ek_overworld.map35.interior"] = { indoor = true } -- 2 interior node(s)
addon.Containers["ek_overworld.map84.interior"] = { indoor = true } -- 17 interior node(s)
addon.Containers["ek_overworld.map84.mage_tower"] = { indoor = true } -- Mage Tower stairwell: street door up to the portal floor's teleport doorway
addon.Containers["kalimdor_overworld.map85.interior"] = { indoor = true } -- 17 interior node(s)
addon.Containers["ek_overworld.map2649"] = { indoor = true } -- interior
addon.Containers["deeprun_tram"] = { indoor = true } -- interior
addon.Containers["ek_overworld.map2393.interior"] = { indoor = true } -- interior
addon.Containers["brawlgar_arena"] = { indoor = true } -- interior
addon.Containers["ek_overworld.map30"] = { indoor = true } -- interior
addon.Containers["ek_overworld.map30.upper"] = { indoor = true } -- interior

-- Phase groups (Zidormi's zones): phaseSide is the side's map art id, phaseMap the map whose art shows it.
addon.Containers["ek_overworld.map17_art18"] = { phaseGroup = "blasted_lands", phaseSide = 18, phaseMap = 17 }
addon.Containers["ek_overworld.map17_art628"] = { phaseGroup = "blasted_lands", phaseSide = 628, phaseMap = 17 }
addon.Containers["ek_overworld.map18_art19"] = { phaseGroup = "tirisfal", phaseSide = 19, phaseMap = 18 }
-- Map 18's art follows Tirisfal's time from outside the zone too (19 / 1136, seen 2026-10-19); 2070 always shows 1136
addon.Containers["ek_overworld.map2070_art1136"] = { phaseGroup = "tirisfal", phaseSide = 1136, phaseMap = 18 }
-- Undercity is only there in the past: its own map, on the past side (phaseMap stays 18, the map that tells the side).
-- `pastOnly`: a waypoint on the map is pinned to the past, as a holiday stop is (TravelGraph:AddDestination). The way in
-- is the gate (the walls stop flights across it) and an elevator down from the ruins (map90.ruins, Nodes_EK.lua), as in
-- Forever. Flying works in the city below; the ruins are left out of the fly mesh so no flight skips the elevators.
addon.Containers["ek_overworld.map90"] = { phaseGroup = "tirisfal", phaseSide = 19, phaseMap = 18, pastOnly = true }
addon.Containers["ek_overworld.map90.ruins"] = { fly = false }
-- Uldum is Silithus's setting (switching either switches both): its sides are Silithus's, told by Silithus's map 81
addon.Containers["kalimdor_overworld.map1527_art260"] = { phaseGroup = "silithus", phaseSide = 962, phaseMap = 81 }
addon.Containers["kalimdor_overworld.map249_art289"] = { phaseGroup = "silithus", phaseSide = 86, phaseMap = 81 }
addon.Containers["kalimdor_overworld.map62_art1176"] = { phaseGroup = "darkshore", phaseSide = 1176, phaseMap = 62 }
addon.Containers["kalimdor_overworld.map62_art67"] = { phaseGroup = "darkshore", phaseSide = 67, phaseMap = 62 }
addon.Containers["kalimdor_overworld.map70_art498"] = { phaseGroup = "dustwallow", phaseSide = 498, phaseMap = 70 }
addon.Containers["kalimdor_overworld.map70_art75"] = { phaseGroup = "dustwallow", phaseSide = 75, phaseMap = 70 }
addon.Containers["kalimdor_overworld.map81_art86"] = { phaseGroup = "silithus", phaseSide = 86, phaseMap = 81 }
addon.Containers["kalimdor_overworld.map81_art962"] = { phaseGroup = "silithus", phaseSide = 962, phaseMap = 81 }
addon.Containers["pandaria.map1530_art1342"] = { phaseGroup = "vale", phaseSide = 1342, phaseMap = 1530 }
addon.Containers["pandaria.map390_art402"] = { phaseGroup = "vale", phaseSide = 402, phaseMap = 390 }
addon.Containers["teldrassil.map57_art67"] = { phaseGroup = "darkshore", phaseSide = 67, phaseMap = 62 }
addon.Containers["teldrassil.map89_art67"] = { phaseGroup = "darkshore", phaseSide = 67, phaseMap = 62 }
-- Arathi has three sides; only Zidormi is on them (Refuge Pointe and Hammerfall are there in all three). The Fourth War
-- (art 1137 on map 14) is where a character starts. Before the war, map 14 shows art 15 as the present does, so that
-- side is told by its flag (addon.PhaseTimes), not art. The present is map 2372, whose art is always 1137: its side
-- is numbered after the map, and it is what is left when neither art nor flag says otherwise.
addon.Containers["ek_overworld.map14_art15"] = { phaseGroup = "arathi", phaseSide = 15 }
addon.Containers["ek_overworld.map14_art1137"] = { phaseGroup = "arathi", phaseSide = 1137, phaseMap = 14 }
addon.Containers["ek_overworld.map2372"] = { phaseGroup = "arathi", phaseSide = 2372 }

-- Each group's past and present side. Holiday stops are pinned to the past (TravelGraph:AddDestination). Where map
-- art can't tell a group's side (Tirisfal and the Vale: each side's map always shows its own art), Zidormi's hidden
-- past flag does: `quest` done = the past side. Without it the group is in the present, unless the character lacks
-- every `unlock` quest (no Zidormi yet), which leaves them in the past with the flag unset.
addon.PhaseTimes = {
    blasted_lands = { past = 18, present = 628 },
    darkshore = { past = 67, present = 1176 },
    dustwallow = { past = 75, present = 498 },
    tirisfal = { past = 19, present = 1136, quest = 52758, unlock = { 50769, 47098 } },
    vale = { past = 402, present = 1342, quest = 59024, unlock = { 58506 } },
    silithus = { past = 86, present = 962, quest = 50659 },                     -- Silithus and Uldum
    arathi = { past = 15, present = 2372, quest = 52781 },                       -- the past is before the war
}
