"""Hand-set inn data for tools/gen_modern_pois.py (Data/Modern/Pois.lua): what Wowhead's innkeeper list
(tools/modern_source/innkeepers.tsv) gets wrong or can't say. The rest of Modern's data is edited in Data/Modern itself.

NODE_KINDS  { node id: kind }: a node in Data/Modern that is itself an inn, standing for the innkeepers there.
INN_FLOORS  { (zone area id, floor): map id, city key, or None }: innkeepers Wowhead gives as a zone and floor.
CITY_ZONE_MAPS, INN_DROP, INN_PHASE, INN_TOWNS, INN_CITIES, INN_PLACES, CATACLYSM_ZONES: see each one's comment.
STABLE_DROP, STABLE_PHASE, STABLE_CITIES: the same for stable masters (tools/gen_modern_stables.py), which also use
INN_FLOORS and CITY_ZONE_MAPS.
"""

NODE_KINDS = {
    "SILVERMOON_INN": "inn",
}

# Inns (tools/gen_modern_pois.py). Wowhead gives some innkeepers as a zone and a floor, not a map: the map each is
# (None: left out -- a duplicate of a row that does give a map, or a place the Modern data doesn't have).
INN_FLOORS = {
    (139, "0"): 23,         # Eastern Plaguelands (Light's Hope Chapel)
    (139, "20"): None,
    (4395, "1"): 125,       # Dalaran (Northrend)
    (4395, "2"): None,      # the Underbelly (map 126: no nodes)
    (6611, "0"): None, (6611, "1"): None, (6611, "2"): None,     # Dalaran (Northrend) again
    (7502, "10"): 627,      # Dalaran (Broken Isles)
    (7503, "0"): 650,       # Highmountain
    (7503, "31"): None,     # Thunder Totem (map 750: no nodes)
    (10565, "1"): 1670,     # Oribos
    # The Shrines (a city's name: the inn stands at the city's centre; a bind there is found by the city's name).
    (5840, "1"): "shrine_of_two_moons", (5840, "2"): "shrine_of_two_moons",
    (5840, "3"): "shrine_of_seven_stars", (5840, "0"): None,
    (6141, "1"): None, (6141, "2"): None, (6142, "3"): None,     # the same innkeepers again
    # Places the Modern data has no nodes for, or that aren't a hearthstone's: garrisons, the Vindicaar's decks,
    # covenant sanctums, scenarios.
    (6720, "0"): None, (6720, "1"): None, (6720, "2"): None, (6738, "4"): None,
    (8574, "0"): None, (8574, "1"): None, (8701, "0"): None, (8701, "3"): None,
    (8899, "0"): None, (8899, "5"): None, (8899, "6"): None,
    (12858, "1"): None, (14753, "1"): None,
    (4714, ""): None, (9598, ""): None, (1584, ""): None, (12876, ""): None, (11012, ""): None,
    (15177, ""): None, (15716, ""): None, (15921, ""): None,
}
# Maps a city shares with the zone around it (Pandaria's shrines are on the Vale's): an inn there is the city's only
# when it stands within CITY_RADIUS of the city's centre.
CITY_ZONE_MAPS = [390]
# NPC ids to leave out (listed as innkeepers, but not ones a player binds with), or (NPC id, map id) for one map only.
INN_DROP = [
    (123395, 882), (123395, 885),   # the Vindicaar's innkeeper: the ship is on all three Argus maps, Krokuun's stands for it
    186012, 186013,                 # Innkeeper Renee in present Tirisfal: Brill has no inn there now (past Tirisfal's is 5688)
]
# An inn on a map whose nodes are all on one side of a phase group or the other: which side, by NPC id.
INN_PHASE = {
    143442: "kalimdor_overworld.map62_art1176",    # Krekthi: Darkshore as it is now
    43420: "kalimdor_overworld.map62_art67",       # Innkeeper Kyteran (Lor'danel): Darkshore before the burning
    5688: "ek_overworld.map18_art19",              # Innkeeper Renee (Brill): past Tirisfal only
}
# Towns named by hand, by the lead innkeeper's NPC id: (key, area id), or None for an inn that is no town's (out in
# the world, or a camp too small to list). From the review of the inns the generator couldn't place (2026-10-06).
INN_TOWNS = {
    5688: ("brill", 159),                       # Innkeeper Renee (past Tirisfal)
    15174: ("cenarion_hold", 3425),             # Calandrath
    240404: ("the_den", 15921),                 # Yinaa (inside The Den, far from its flight master on the cave's map)
    18907: ("cenarion_refuge", 3565),           # Innkeeper Coryth Stoktron (not Swamprat Post)
    21088: ("mok_nathal_village", 3844),        # Matron Varah
    23143: ("netherwing_ledge", 3759),          # Horus
    29904: ("k3", 4418),                        # Smilin' Slirk Brassknob
    30005: ("brunnhildar_village", 4422),       # Lodge-Matron Embla (not Dun Niffelem)
    41618: ("legion_s_fate", 5052),             # Erunak Stonespeaker
    43946: ("grol_dom_farm", 1704),             # Innkeeper Kerntis
    44006: ("swiftgear_station", 5304),         # Innkeeper Daughny
    44309: ("dreadmaul_hold", 1437),            # Innkeeper Grak
    44334: ("surwich", 5084),                   # Donna Berrymore
    45272: ("freewind_post", 484),              # Innkeeper Abeqwa
    45300: ("temple_of_earth", 5303),           # Caretaker Nuunwa
    49498: ("dragonmaw_port", 5136),            # Innkeeper Lutz
    49574: ("kirthaven", 5143),                 # Vaughn Blusterbeard
    49747: ("crushblow", 5471),                 # Innkeeper Krum
    49762: ("bloodgulch", 5138),                # Innkeeper Turk
    49783: ("the_krazzworks", 5137),            # Innkeeper Geno
    62869: ("crane_wing_refuge", 6049),         # Ni the Merciful
    67668: ("dawnseeker_promontory", 6584),     # Uda the Beast
    70182: ("violet_rise", 6583),               # Isirami Fairwind
    73622: ("the_celestial_court", 6830),       # Graceful Swan
    79758: ("telaari_station", 7081),           # Caregiver Felaani
    82110: ("admiral_taylor_s_garrison", 6999), # Alice Finn
    98945: ("temple_of_five_dawns", 7903),      # Lao Shu (the Legion Wandering Isle)
    129354: ("atul_aman", 8960),                # Rhan'ka
    133695: ("suramar_city", 8148),             # Maribeth (not the Nighthold)
    171015: ("dreamsong_fenn", 11519),          # Flitterbit
    187403: ("wingrest_embassy", 13939),        # Sil'nori Crestshade
    187412: ("wingrest_embassy", 13939),        # Happy Hal
    191025: ("ruby_life_pools", 13728),         # Lifecaller Tzadrak
    203293: ("loamm", 14520),                   # Floressa
    206947: ("bel_ameth", 15115),               # Willa Stronghinge: Bel'ameth's second inn
    210940: ("stormglen_village", 5714),        # Willa Arnes
    217167: ("gilneas_city", 5435),             # Gwen Armstead
    240404: ("the_den", 15921),                 # Yinaa
    249879: ("tranquillien", 16001),            # Innkeeper Areyn: Tranquillien's second inn
    # No town's.
    92001: None, 99207: None, 100746: None, 109304: None, 112864: None, 115002: None, 163252: None, 164722: None,
    168758: None, 175621: None, 59405: None, 65976: None, 84237: None, 85830: None, 86994: None,
}
# Inns that are a city's, though they stand on another map than the city's own (by NPC id: city key).
INN_CITIES = {
    62996: "shrine_of_two_moons",       # Madam Vee Luo, on the present Vale's map
    64149: "shrine_of_seven_stars",     # Matron Vi Vinh, the same
    137331: "dazaralor",                # Shado, on Zuldazar's map (the Great Seal)
}
# Where an innkeeper really stands, when Wowhead has it wrong: NPC id -> (map id, x, y), 0-100, and Wowhead's map as
# a fourth value when it lists them on another map.
INN_PLACES = {
    46271: (18, 83.0, 71.8),            # Provisioner Elda: at the Bulwark (Wowhead puts her at 26.4, 59.2)
    # Yinaa: inside The Den, a cave with its own map (user, 2026-10-27). Wowhead's 2413 (50.8, 55.5) carried onto 2576 by
    # the two cave mouths' capture pairs (about 8x); not captured in game.
    240404: (2576, 43.6, 72.4, 2413),
}
# The zones Cataclysm added to the old world (uiMap ids): a town in one is Cataclysm's, whatever its name.
CATACLYSM_ZONES = [174, 194, 198, 201, 203, 204, 205, 207, 217, 241, 244, 245, 249, 1527]

# Stable masters (tools/gen_modern_stables.py), as the inns' tables above: NPC ids (or (NPC id, map id)) to leave out,
# which phase side a stable on a phase-split map is on, and stables that are a city's though on another map.
STABLE_DROP = [
    9983,                   # Kelsuwa <Former Stable Master>: Camp Taurajo, burnt
    174599,                 # Stable Master Hail <House Briarbane>: hostile to both
    # Places the Modern data has no nodes for (as INN_FLOORS): garrisons, Thunder Totem, Exile's Reach, Blackrock
    # Depths, a Bastion scenario.
    79860, 85963, 86052,    # Zagara (Frostwall), Orville Manfred and Ujia (the garrisons' stables)
    97854,                  # Liza Galestride (Thunder Totem)
    161666, 167215,         # Austin Huxworth, Mithdran Dawntracker (Exile's Reach)
    144119,                 # Kasea Angerforge (Blackrock Depths)
    (174580, 0),            # Beastkeeper Krista's second spawn, given only as a zone (her Bastion one stays)
    136233,                 # Klause Fairwind <Former Stable Master> (his Tiragarde self, 136142, stays)
    27236, 28555, 28683,    # Stable Masters Mercer and Kitrik: a Dragonblight quest NPC, the Scarlet Enclave's
    86808, 87006,           # Keegan Firebeard, Tormak the Scarred: the garrison Stables' quest givers out in Draenor
    # Spawns Wowhead gives only as a zone (garrisons, class halls, covenant sanctums, the Wandering Isle and Gilneas
    # starts, scenarios): the other spawns of each, on a map, stay.
    (68986, 0), (68993, 0), (70184, 0), (73632, 0), (77381, 0), (79816, 0), (86973, 0), (86979, 0), (113337, 0),
    (151106, 0), (159000, 0), (161100, 0), (177489, 0), (180291, 0), (194778, 0), (222432, 0), (223027, 0),
]
STABLE_PHASE = {
    10085: "kalimdor_overworld.map62_art67",       # Jaelysia (Lor'danel): Darkshore before the burning
}
STABLE_CITIES = {}
