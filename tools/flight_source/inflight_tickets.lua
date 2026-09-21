-- inflight_tickets.lua -- the flight times from InFlight's global_classic table (Defaults.lua lines
-- 21026-22106 of the InFlight addon), one line per ticket: 881 in all. Each is the time of a whole
-- ticket between two flight masters, as timed by some player. Between two points that are a single
-- leg (tools/flight_source/taxipath_classic_1.15.9.txt) it is the leg's own time; otherwise the ticket
-- flew through other flight points, which ones depending on what that player had found.
-- tools/gen_flights.py reads this file and writes Data/Forever/Flights.lua. Not loaded by the addon.
--
{ from = "TAXI_10", to = "TAXI_13", method = "flight", cost = 95, requirements = { faction = "Horde" } }, -- The Sepulcher -> Tarren Mill
{ from = "TAXI_10", to = "TAXI_17", method = "flight", cost = 212, requirements = { faction = "Horde" } }, -- The Sepulcher -> Hammerfall
{ from = "TAXI_10", to = "TAXI_18", method = "flight", cost = 863, requirements = { faction = "Horde" } }, -- The Sepulcher -> Booty Bay
{ from = "TAXI_10", to = "TAXI_20", method = "flight", cost = 782, requirements = { faction = "Horde" } }, -- The Sepulcher -> Grom'gol
{ from = "TAXI_10", to = "TAXI_21", method = "flight", cost = 471, requirements = { faction = "Horde" } }, -- The Sepulcher -> Kargath
{ from = "TAXI_10", to = "TAXI_56", method = "flight", cost = 751, requirements = { faction = "Horde" } }, -- The Sepulcher -> Stonard
{ from = "TAXI_10", to = "TAXI_68", method = "flight", cost = 299, requirements = { faction = "Horde" } }, -- The Sepulcher -> Light's Hope Chapel
{ from = "TAXI_10", to = "TAXI_70", method = "flight", cost = 556, requirements = { faction = "Horde" } }, -- The Sepulcher -> Flame Crest
{ from = "TAXI_10", to = "TAXI_75", method = "flight", cost = 526, requirements = { faction = "Horde" } }, -- The Sepulcher -> Thorium Point
{ from = "TAXI_10", to = "TAXI_76", method = "flight", cost = 289, requirements = { faction = "Horde" } }, -- The Sepulcher -> Revantusk Village
{ from = "TAXI_11", to = "TAXI_10", method = "flight", cost = 106, requirements = { faction = "Horde" } }, -- Undercity -> The Sepulcher
{ from = "TAXI_11", to = "TAXI_17", method = "flight", cost = 301, requirements = { faction = "Horde" } }, -- Undercity -> Hammerfall
{ from = "TAXI_11", to = "TAXI_18", method = "flight", cost = 880, requirements = { faction = "Horde" } }, -- Undercity -> Booty Bay
{ from = "TAXI_11", to = "TAXI_20", method = "flight", cost = 800, requirements = { faction = "Horde" } }, -- Undercity -> Grom'gol
{ from = "TAXI_11", to = "TAXI_21", method = "flight", cost = 488, requirements = { faction = "Horde" } }, -- Undercity -> Kargath
{ from = "TAXI_11", to = "TAXI_56", method = "flight", cost = 768, requirements = { faction = "Horde" } }, -- Undercity -> Stonard
{ from = "TAXI_11", to = "TAXI_68", method = "flight", cost = 261, requirements = { faction = "Horde" } }, -- Undercity -> Light's Hope Chapel
{ from = "TAXI_11", to = "TAXI_70", method = "flight", cost = 573, requirements = { faction = "Horde" } }, -- Undercity -> Flame Crest
{ from = "TAXI_11", to = "TAXI_76", method = "flight", cost = 284, requirements = { faction = "Horde" } }, -- Undercity -> Revantusk Village
{ from = "TAXI_13", to = "TAXI_10", method = "flight", cost = 99, requirements = { faction = "Horde" } }, -- Tarren Mill -> The Sepulcher
{ from = "TAXI_13", to = "TAXI_11", method = "flight", cost = 139, requirements = { faction = "Horde" } }, -- Tarren Mill -> Undercity
{ from = "TAXI_13", to = "TAXI_17", method = "flight", cost = 118, requirements = { faction = "Horde" } }, -- Tarren Mill -> Hammerfall
{ from = "TAXI_13", to = "TAXI_18", method = "flight", cost = 768, requirements = { faction = "Horde" } }, -- Tarren Mill -> Booty Bay
{ from = "TAXI_13", to = "TAXI_20", method = "flight", cost = 688, requirements = { faction = "Horde" } }, -- Tarren Mill -> Grom'gol
{ from = "TAXI_13", to = "TAXI_21", method = "flight", cost = 376, requirements = { faction = "Horde" } }, -- Tarren Mill -> Kargath
{ from = "TAXI_13", to = "TAXI_56", method = "flight", cost = 656, requirements = { faction = "Horde" } }, -- Tarren Mill -> Stonard
{ from = "TAXI_13", to = "TAXI_68", method = "flight", cost = 329, requirements = { faction = "Horde" } }, -- Tarren Mill -> Light's Hope Chapel
{ from = "TAXI_13", to = "TAXI_70", method = "flight", cost = 462, requirements = { faction = "Horde" } }, -- Tarren Mill -> Flame Crest
{ from = "TAXI_13", to = "TAXI_75", method = "flight", cost = 431, requirements = { faction = "Horde" } }, -- Tarren Mill -> Thorium Point
{ from = "TAXI_13", to = "TAXI_76", method = "flight", cost = 195, requirements = { faction = "Horde" } }, -- Tarren Mill -> Revantusk Village
{ from = "TAXI_17", to = "TAXI_10", method = "flight", cost = 215, requirements = { faction = "Horde" } }, -- Hammerfall -> The Sepulcher
{ from = "TAXI_17", to = "TAXI_11", method = "flight", cost = 259, requirements = { faction = "Horde" } }, -- Hammerfall -> Undercity
{ from = "TAXI_17", to = "TAXI_13", method = "flight", cost = 117, requirements = { faction = "Horde" } }, -- Hammerfall -> Tarren Mill
{ from = "TAXI_17", to = "TAXI_18", method = "flight", cost = 651, requirements = { faction = "Horde" } }, -- Hammerfall -> Booty Bay
{ from = "TAXI_17", to = "TAXI_20", method = "flight", cost = 571, requirements = { faction = "Horde" } }, -- Hammerfall -> Grom'gol
{ from = "TAXI_17", to = "TAXI_21", method = "flight", cost = 259, requirements = { faction = "Horde" } }, -- Hammerfall -> Kargath
{ from = "TAXI_17", to = "TAXI_56", method = "flight", cost = 539, requirements = { faction = "Horde" } }, -- Hammerfall -> Stonard
{ from = "TAXI_17", to = "TAXI_68", method = "flight", cost = 229, requirements = { faction = "Horde" } }, -- Hammerfall -> Light's Hope Chapel
{ from = "TAXI_17", to = "TAXI_70", method = "flight", cost = 344, requirements = { faction = "Horde" } }, -- Hammerfall -> Flame Crest
{ from = "TAXI_17", to = "TAXI_75", method = "flight", cost = 314, requirements = { faction = "Horde" } }, -- Hammerfall -> Thorium Point
{ from = "TAXI_17", to = "TAXI_76", method = "flight", cost = 91, requirements = { faction = "Horde" } }, -- Hammerfall -> Revantusk Village
{ from = "TAXI_18", to = "TAXI_10", method = "flight", cost = 882, requirements = { faction = "Horde" } }, -- Booty Bay -> The Sepulcher
{ from = "TAXI_18", to = "TAXI_11", method = "flight", cost = 903, requirements = { faction = "Horde" } }, -- Booty Bay -> Undercity
{ from = "TAXI_18", to = "TAXI_13", method = "flight", cost = 783, requirements = { faction = "Horde" } }, -- Booty Bay -> Tarren Mill
{ from = "TAXI_18", to = "TAXI_17", method = "flight", cost = 668, requirements = { faction = "Horde" } }, -- Booty Bay -> Hammerfall
{ from = "TAXI_18", to = "TAXI_20", method = "flight", cost = 102, requirements = { faction = "Horde" } }, -- Booty Bay -> Grom'gol
{ from = "TAXI_18", to = "TAXI_21", method = "flight", cost = 406, requirements = { faction = "Horde" } }, -- Booty Bay -> Kargath
{ from = "TAXI_18", to = "TAXI_56", method = "flight", cost = 267, requirements = { faction = "Horde" } }, -- Booty Bay -> Stonard
{ from = "TAXI_18", to = "TAXI_68", method = "flight", cost = 896, requirements = { faction = "Horde" } }, -- Booty Bay -> Light's Hope Chapel
{ from = "TAXI_18", to = "TAXI_70", method = "flight", cost = 464, requirements = { faction = "Horde" } }, -- Booty Bay -> Flame Crest
{ from = "TAXI_18", to = "TAXI_75", method = "flight", cost = 462, requirements = { faction = "Horde" } }, -- Booty Bay -> Thorium Point
{ from = "TAXI_18", to = "TAXI_76", method = "flight", cost = 757, requirements = { faction = "Horde" } }, -- Booty Bay -> Revantusk Village
{ from = "TAXI_20", to = "TAXI_10", method = "flight", cost = 802, requirements = { faction = "Horde" } }, -- Grom'gol -> The Sepulcher
{ from = "TAXI_20", to = "TAXI_11", method = "flight", cost = 823, requirements = { faction = "Horde" } }, -- Grom'gol -> Undercity
{ from = "TAXI_20", to = "TAXI_13", method = "flight", cost = 704, requirements = { faction = "Horde" } }, -- Grom'gol -> Tarren Mill
{ from = "TAXI_20", to = "TAXI_17", method = "flight", cost = 588, requirements = { faction = "Horde" } }, -- Grom'gol -> Hammerfall
{ from = "TAXI_20", to = "TAXI_18", method = "flight", cost = 81, requirements = { faction = "Horde" } }, -- Grom'gol -> Booty Bay
{ from = "TAXI_20", to = "TAXI_21", method = "flight", cost = 327, requirements = { faction = "Horde" } }, -- Grom'gol -> Kargath
{ from = "TAXI_20", to = "TAXI_56", method = "flight", cost = 205, requirements = { faction = "Horde" } }, -- Grom'gol -> Stonard
{ from = "TAXI_20", to = "TAXI_68", method = "flight", cost = 816, requirements = { faction = "Horde" } }, -- Grom'gol -> Light's Hope Chapel
{ from = "TAXI_20", to = "TAXI_70", method = "flight", cost = 402, requirements = { faction = "Horde" } }, -- Grom'gol -> Flame Crest
{ from = "TAXI_20", to = "TAXI_75", method = "flight", cost = 382, requirements = { faction = "Horde" } }, -- Grom'gol -> Thorium Point
{ from = "TAXI_20", to = "TAXI_76", method = "flight", cost = 677, requirements = { faction = "Horde" } }, -- Grom'gol -> Revantusk Village
{ from = "TAXI_21", to = "TAXI_10", method = "flight", cost = 477, requirements = { faction = "Horde" } }, -- Kargath -> The Sepulcher
{ from = "TAXI_21", to = "TAXI_11", method = "flight", cost = 497, requirements = { faction = "Horde" } }, -- Kargath -> Undercity
{ from = "TAXI_21", to = "TAXI_13", method = "flight", cost = 379, requirements = { faction = "Horde" } }, -- Kargath -> Tarren Mill
{ from = "TAXI_21", to = "TAXI_17", method = "flight", cost = 263, requirements = { faction = "Horde" } }, -- Kargath -> Hammerfall
{ from = "TAXI_21", to = "TAXI_18", method = "flight", cost = 417, requirements = { faction = "Horde" } }, -- Kargath -> Booty Bay
{ from = "TAXI_21", to = "TAXI_20", method = "flight", cost = 313, requirements = { faction = "Horde" } }, -- Kargath -> Grom'gol
{ from = "TAXI_21", to = "TAXI_56", method = "flight", cost = 280, requirements = { faction = "Horde" } }, -- Kargath -> Stonard
{ from = "TAXI_21", to = "TAXI_70", method = "flight", cost = 87, requirements = { faction = "Horde" } }, -- Kargath -> Flame Crest
{ from = "TAXI_21", to = "TAXI_75", method = "flight", cost = 56, requirements = { faction = "Horde" } }, -- Kargath -> Thorium Point
{ from = "TAXI_21", to = "TAXI_68", method = "flight", cost = 491, requirements = { faction = "Horde" } }, -- Kargath -> Light's Hope Chapel
{ from = "TAXI_21", to = "TAXI_76", method = "flight", cost = 352, requirements = { faction = "Horde" } }, -- Kargath -> Revantusk Village
{ from = "TAXI_22", to = "TAXI_23", method = "flight", cost = 207, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Orgrimmar
{ from = "TAXI_22", to = "TAXI_25", method = "flight", cost = 159, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Crossroads
{ from = "TAXI_22", to = "TAXI_29", method = "flight", cost = 182, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Sun Rock Retreat
{ from = "TAXI_22", to = "TAXI_30", method = "flight", cost = 204, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Freewind Post
{ from = "TAXI_22", to = "TAXI_44", method = "flight", cost = 269, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Valormok
{ from = "TAXI_22", to = "TAXI_53", method = "flight", cost = 398, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Everlook
{ from = "TAXI_22", to = "TAXI_55", method = "flight", cost = 239, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Brackenwall Village
{ from = "TAXI_22", to = "TAXI_58", method = "flight", cost = 389, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Zoram'gar Outpost
{ from = "TAXI_22", to = "TAXI_61", method = "flight", cost = 296, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Splintertree Post
{ from = "TAXI_22", to = "TAXI_69", method = "flight", cost = 532, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Moonglade
{ from = "TAXI_22", to = "TAXI_72", method = "flight", cost = 381, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Cenarion Hold
{ from = "TAXI_22", to = "TAXI_77", method = "flight", cost = 87, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Camp Taurajo
{ from = "TAXI_22", to = "TAXI_79", method = "flight", cost = 397, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Marshal's Refuge
{ from = "TAXI_22", to = "TAXI_80", method = "flight", cost = 210, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Ratchet
{ from = "TAXI_22", to = "TAXI_48", method = "flight", cost = 411, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Bloodvenom Post
{ from = "TAXI_23", to = "TAXI_22", method = "flight", cost = 224, requirements = { faction = "Horde" } }, -- Orgrimmar -> Thunder Bluff
{ from = "TAXI_23", to = "TAXI_25", method = "flight", cost = 110, requirements = { faction = "Horde" } }, -- Orgrimmar -> Crossroads
{ from = "TAXI_23", to = "TAXI_29", method = "flight", cost = 260, requirements = { faction = "Horde" } }, -- Orgrimmar -> Sun Rock Retreat
{ from = "TAXI_23", to = "TAXI_30", method = "flight", cost = 294, requirements = { faction = "Horde" } }, -- Orgrimmar -> Freewind Post
{ from = "TAXI_23", to = "TAXI_38", method = "flight", cost = 385, requirements = { faction = "Horde" } }, -- Orgrimmar -> Shadowprey Village
{ from = "TAXI_23", to = "TAXI_40", method = "flight", cost = 417, requirements = { faction = "Horde" } }, -- Orgrimmar -> Gadgetzan
{ from = "TAXI_23", to = "TAXI_42", method = "flight", cost = 361, requirements = { faction = "Horde" } }, -- Orgrimmar -> Camp Mojache
{ from = "TAXI_23", to = "TAXI_44", method = "flight", cost = 99, requirements = { faction = "Horde" } }, -- Orgrimmar -> Valormok
{ from = "TAXI_23", to = "TAXI_53", method = "flight", cost = 319, requirements = { faction = "Horde" } }, -- Orgrimmar -> Everlook
{ from = "TAXI_23", to = "TAXI_55", method = "flight", cost = 229, requirements = { faction = "Horde" } }, -- Orgrimmar -> Brackenwall Village
{ from = "TAXI_23", to = "TAXI_58", method = "flight", cost = 250, requirements = { faction = "Horde" } }, -- Orgrimmar -> Zoram'gar Outpost
{ from = "TAXI_23", to = "TAXI_61", method = "flight", cost = 89, requirements = { faction = "Horde" } }, -- Orgrimmar -> Splintertree Post
{ from = "TAXI_23", to = "TAXI_69", method = "flight", cost = 361, requirements = { faction = "Horde" } }, -- Orgrimmar -> Moonglade
{ from = "TAXI_23", to = "TAXI_72", method = "flight", cost = 492, requirements = { faction = "Horde" } }, -- Orgrimmar -> Cenarion Hold
{ from = "TAXI_23", to = "TAXI_77", method = "flight", cost = 200, requirements = { faction = "Horde" } }, -- Orgrimmar -> Camp Taurajo
{ from = "TAXI_23", to = "TAXI_79", method = "flight", cost = 494, requirements = { faction = "Horde" } }, -- Orgrimmar -> Marshal's Refuge
{ from = "TAXI_23", to = "TAXI_80", method = "flight", cost = 161, requirements = { faction = "Horde" } }, -- Orgrimmar -> Ratchet
{ from = "TAXI_23", to = "TAXI_48", method = "flight", cost = 252, requirements = { faction = "Horde" } }, -- Orgrimmar -> Bloodvenom Post
{ from = "TAXI_25", to = "TAXI_22", method = "flight", cost = 182, requirements = { faction = "Horde" } }, -- Crossroads -> Thunder Bluff
{ from = "TAXI_25", to = "TAXI_23", method = "flight", cost = 142, requirements = { faction = "Horde" } }, -- Crossroads -> Orgrimmar
{ from = "TAXI_25", to = "TAXI_29", method = "flight", cost = 150, requirements = { faction = "Horde" } }, -- Crossroads -> Sun Rock Retreat
{ from = "TAXI_25", to = "TAXI_30", method = "flight", cost = 184, requirements = { faction = "Horde" } }, -- Crossroads -> Freewind Post
{ from = "TAXI_25", to = "TAXI_38", method = "flight", cost = 342, requirements = { faction = "Horde" } }, -- Crossroads -> Shadowprey Village
{ from = "TAXI_25", to = "TAXI_40", method = "flight", cost = 303, requirements = { faction = "Horde" } }, -- Crossroads -> Gadgetzan
{ from = "TAXI_25", to = "TAXI_42", method = "flight", cost = 252, requirements = { faction = "Horde" } }, -- Crossroads -> Camp Mojache
{ from = "TAXI_25", to = "TAXI_44", method = "flight", cost = 168, requirements = { faction = "Horde" } }, -- Crossroads -> Valormok
{ from = "TAXI_25", to = "TAXI_53", method = "flight", cost = 297, requirements = { faction = "Horde" } }, -- Crossroads -> Everlook
{ from = "TAXI_25", to = "TAXI_55", method = "flight", cost = 162, requirements = { faction = "Horde" } }, -- Crossroads -> Brackenwall Village
{ from = "TAXI_25", to = "TAXI_58", method = "flight", cost = 231, requirements = { faction = "Horde" } }, -- Crossroads -> Zoram'gar Outpost
{ from = "TAXI_25", to = "TAXI_61", method = "flight", cost = 162, requirements = { faction = "Horde" } }, -- Crossroads -> Splintertree Post
{ from = "TAXI_25", to = "TAXI_77", method = "flight", cost = 90, requirements = { faction = "Horde" } }, -- Crossroads -> Camp Taurajo
{ from = "TAXI_25", to = "TAXI_79", method = "flight", cost = 384, requirements = { faction = "Horde" } }, -- Crossroads -> Marshal's Refuge
{ from = "TAXI_25", to = "TAXI_48", method = "flight", cost = 253, requirements = { faction = "Horde" } }, -- Crossroads -> Bloodvenom Post
{ from = "TAXI_25", to = "TAXI_72", method = "flight", cost = 382, requirements = { faction = "Horde" } }, -- Crossroads -> Cenarion Hold
{ from = "TAXI_29", to = "TAXI_22", method = "flight", cost = 175, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Thunder Bluff
{ from = "TAXI_29", to = "TAXI_23", method = "flight", cost = 290, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Orgrimmar
{ from = "TAXI_29", to = "TAXI_38", method = "flight", cost = 143, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Shadowprey Village
{ from = "TAXI_29", to = "TAXI_42", method = "flight", cost = 339, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Camp Mojache
{ from = "TAXI_29", to = "TAXI_55", method = "flight", cost = 312, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Brackenwall Village
{ from = "TAXI_29", to = "TAXI_58", method = "flight", cost = 380, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Zoram'gar Outpost
{ from = "TAXI_29", to = "TAXI_61", method = "flight", cost = 311, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Splintertree Post
{ from = "TAXI_29", to = "TAXI_80", method = "flight", cost = 200, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Ratchet
{ from = "TAXI_29", to = "TAXI_30", method = "flight", cost = 333, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Freewind Post
{ from = "TAXI_29", to = "TAXI_44", method = "flight", cost = 318, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Valormok
{ from = "TAXI_29", to = "TAXI_48", method = "flight", cost = 403, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Bloodvenom Post
{ from = "TAXI_29", to = "TAXI_53", method = "flight", cost = 447, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Everlook
{ from = "TAXI_29", to = "TAXI_72", method = "flight", cost = 469, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Cenarion Hold
{ from = "TAXI_29", to = "TAXI_77", method = "flight", cost = 240, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Camp Taurajo
{ from = "TAXI_29", to = "TAXI_79", method = "flight", cost = 534, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Marshal's Refuge
{ from = "TAXI_30", to = "TAXI_22", method = "flight", cost = 225, requirements = { faction = "Horde" } }, -- Freewind Post -> Thunder Bluff
{ from = "TAXI_30", to = "TAXI_23", method = "flight", cost = 335, requirements = { faction = "Horde" } }, -- Freewind Post -> Orgrimmar
{ from = "TAXI_30", to = "TAXI_25", method = "flight", cost = 194, requirements = { faction = "Horde" } }, -- Freewind Post -> Crossroads
{ from = "TAXI_30", to = "TAXI_38", method = "flight", cost = 323, requirements = { faction = "Horde" } }, -- Freewind Post -> Shadowprey Village
{ from = "TAXI_30", to = "TAXI_40", method = "flight", cost = 93, requirements = { faction = "Horde" } }, -- Freewind Post -> Gadgetzan
{ from = "TAXI_30", to = "TAXI_42", method = "flight", cost = 124, requirements = { faction = "Horde" } }, -- Freewind Post -> Camp Mojache
{ from = "TAXI_30", to = "TAXI_55", method = "flight", cost = 315, requirements = { faction = "Horde" } }, -- Freewind Post -> Brackenwall Village
{ from = "TAXI_30", to = "TAXI_29", method = "flight", cost = 343, requirements = { faction = "Horde" } }, -- Freewind Post -> Sun Rock Retreat
{ from = "TAXI_30", to = "TAXI_44", method = "flight", cost = 362, requirements = { faction = "Horde" } }, -- Freewind Post -> Valormok
{ from = "TAXI_30", to = "TAXI_58", method = "flight", cost = 424, requirements = { faction = "Horde" } }, -- Freewind Post -> Zoram'gar Outpost
{ from = "TAXI_30", to = "TAXI_61", method = "flight", cost = 356, requirements = { faction = "Horde" } }, -- Freewind Post -> Splintertree Post
{ from = "TAXI_30", to = "TAXI_69", method = "flight", cost = 568, requirements = { faction = "Horde" } }, -- Freewind Post -> Moonglade
{ from = "TAXI_30", to = "TAXI_72", method = "flight", cost = 252, requirements = { faction = "Horde" } }, -- Freewind Post -> Cenarion Hold
{ from = "TAXI_30", to = "TAXI_77", method = "flight", cost = 137, requirements = { faction = "Horde" } }, -- Freewind Post -> Camp Taurajo
{ from = "TAXI_30", to = "TAXI_79", method = "flight", cost = 200, requirements = { faction = "Horde" } }, -- Freewind Post -> Marshal's Refuge
{ from = "TAXI_30", to = "TAXI_80", method = "flight", cost = 245, requirements = { faction = "Horde" } }, -- Freewind Post -> Ratchet
{ from = "TAXI_38", to = "TAXI_22", method = "flight", cost = 178, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Thunder Bluff
{ from = "TAXI_38", to = "TAXI_23", method = "flight", cost = 385, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Orgrimmar
{ from = "TAXI_38", to = "TAXI_25", method = "flight", cost = 337, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Crossroads
{ from = "TAXI_38", to = "TAXI_30", method = "flight", cost = 382, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Freewind Post
{ from = "TAXI_38", to = "TAXI_40", method = "flight", cost = 468, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Gadgetzan
{ from = "TAXI_38", to = "TAXI_55", method = "flight", cost = 416, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Brackenwall Village
{ from = "TAXI_38", to = "TAXI_58", method = "flight", cost = 566, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Zoram'gar Outpost
{ from = "TAXI_38", to = "TAXI_61", method = "flight", cost = 474, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Splintertree Post
{ from = "TAXI_38", to = "TAXI_69", method = "flight", cost = 709, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Moonglade
{ from = "TAXI_38", to = "TAXI_79", method = "flight", cost = 417, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Marshal's Refuge
{ from = "TAXI_38", to = "TAXI_80", method = "flight", cost = 388, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Ratchet
{ from = "TAXI_38", to = "TAXI_44", method = "flight", cost = 447, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Valormok
{ from = "TAXI_38", to = "TAXI_48", method = "flight", cost = 590, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Bloodvenom Post
{ from = "TAXI_38", to = "TAXI_53", method = "flight", cost = 576, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Everlook
{ from = "TAXI_38", to = "TAXI_72", method = "flight", cost = 326, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Cenarion Hold
{ from = "TAXI_38", to = "TAXI_77", method = "flight", cost = 265, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Camp Taurajo
{ from = "TAXI_40", to = "TAXI_23", method = "flight", cost = 350, requirements = { faction = "Horde" } }, -- Gadgetzan -> Orgrimmar
{ from = "TAXI_40", to = "TAXI_25", method = "flight", cost = 301, requirements = { faction = "Horde" } }, -- Gadgetzan -> Crossroads
{ from = "TAXI_40", to = "TAXI_29", method = "flight", cost = 429, requirements = { faction = "Horde" } }, -- Gadgetzan -> Sun Rock Retreat
{ from = "TAXI_40", to = "TAXI_30", method = "flight", cost = 87, requirements = { faction = "Horde" } }, -- Gadgetzan -> Freewind Post
{ from = "TAXI_40", to = "TAXI_38", method = "flight", cost = 400, requirements = { faction = "Horde" } }, -- Gadgetzan -> Shadowprey Village
{ from = "TAXI_40", to = "TAXI_42", method = "flight", cost = 200, requirements = { faction = "Horde" } }, -- Gadgetzan -> Camp Mojache
{ from = "TAXI_40", to = "TAXI_53", method = "flight", cost = 669, requirements = { faction = "Horde" } }, -- Gadgetzan -> Everlook
{ from = "TAXI_40", to = "TAXI_55", method = "flight", cost = 222, requirements = { faction = "Horde" } }, -- Gadgetzan -> Brackenwall Village
{ from = "TAXI_40", to = "TAXI_58", method = "flight", cost = 510, requirements = { faction = "Horde" } }, -- Gadgetzan -> Zoram'gar Outpost
{ from = "TAXI_40", to = "TAXI_61", method = "flight", cost = 439, requirements = { faction = "Horde" } }, -- Gadgetzan -> Splintertree Post
{ from = "TAXI_40", to = "TAXI_69", method = "flight", cost = 653, requirements = { faction = "Horde" } }, -- Gadgetzan -> Moonglade
{ from = "TAXI_40", to = "TAXI_77", method = "flight", cost = 223, requirements = { faction = "Horde" } }, -- Gadgetzan -> Camp Taurajo
{ from = "TAXI_40", to = "TAXI_79", method = "flight", cost = 108, requirements = { faction = "Horde" } }, -- Gadgetzan -> Marshal's Refuge
{ from = "TAXI_40", to = "TAXI_80", method = "flight", cost = 331, requirements = { faction = "Horde" } }, -- Gadgetzan -> Ratchet
{ from = "TAXI_40", to = "TAXI_44", method = "flight", cost = 448, requirements = { faction = "Horde" } }, -- Gadgetzan -> Valormok
{ from = "TAXI_40", to = "TAXI_48", method = "flight", cost = 532, requirements = { faction = "Horde" } }, -- Gadgetzan -> Bloodvenom Post
{ from = "TAXI_40", to = "TAXI_72", method = "flight", cost = 233, requirements = { faction = "Horde" } }, -- Gadgetzan -> Cenarion Hold
{ from = "TAXI_42", to = "TAXI_23", method = "flight", cost = 406, requirements = { faction = "Horde" } }, -- Camp Mojache -> Orgrimmar
{ from = "TAXI_42", to = "TAXI_25", method = "flight", cost = 263, requirements = { faction = "Horde" } }, -- Camp Mojache -> Crossroads
{ from = "TAXI_42", to = "TAXI_29", method = "flight", cost = 400, requirements = { faction = "Horde" } }, -- Camp Mojache -> Sun Rock Retreat
{ from = "TAXI_42", to = "TAXI_30", method = "flight", cost = 107, requirements = { faction = "Horde" } }, -- Camp Mojache -> Freewind Post
{ from = "TAXI_42", to = "TAXI_40", method = "flight", cost = 201, requirements = { faction = "Horde" } }, -- Camp Mojache -> Gadgetzan
{ from = "TAXI_42", to = "TAXI_55", method = "flight", cost = 421, requirements = { faction = "Horde" } }, -- Camp Mojache -> Brackenwall Village
{ from = "TAXI_42", to = "TAXI_58", method = "flight", cost = 494, requirements = { faction = "Horde" } }, -- Camp Mojache -> Zoram'gar Outpost
{ from = "TAXI_42", to = "TAXI_61", method = "flight", cost = 426, requirements = { faction = "Horde" } }, -- Camp Mojache -> Splintertree Post
{ from = "TAXI_42", to = "TAXI_69", method = "flight", cost = 638, requirements = { faction = "Horde" } }, -- Camp Mojache -> Moonglade
{ from = "TAXI_42", to = "TAXI_79", method = "flight", cost = 222, requirements = { faction = "Horde" } }, -- Camp Mojache -> Marshal's Refuge
{ from = "TAXI_42", to = "TAXI_80", method = "flight", cost = 315, requirements = { faction = "Horde" } }, -- Camp Mojache -> Ratchet
{ from = "TAXI_42", to = "TAXI_44", method = "flight", cost = 432, requirements = { faction = "Horde" } }, -- Camp Mojache -> Valormok
{ from = "TAXI_42", to = "TAXI_48", method = "flight", cost = 517, requirements = { faction = "Horde" } }, -- Camp Mojache -> Bloodvenom Post
{ from = "TAXI_42", to = "TAXI_72", method = "flight", cost = 132, requirements = { faction = "Horde" } }, -- Camp Mojache -> Cenarion Hold
{ from = "TAXI_42", to = "TAXI_77", method = "flight", cost = 244, requirements = { faction = "Horde" } }, -- Camp Mojache -> Camp Taurajo
{ from = "TAXI_44", to = "TAXI_22", method = "flight", cost = 257, requirements = { faction = "Horde" } }, -- Valormok -> Thunder Bluff
{ from = "TAXI_44", to = "TAXI_23", method = "flight", cost = 121, requirements = { faction = "Horde" } }, -- Valormok -> Orgrimmar
{ from = "TAXI_44", to = "TAXI_25", method = "flight", cost = 172, requirements = { faction = "Horde" } }, -- Valormok -> Crossroads
{ from = "TAXI_44", to = "TAXI_53", method = "flight", cost = 131, requirements = { faction = "Horde" } }, -- Valormok -> Everlook
{ from = "TAXI_44", to = "TAXI_61", method = "flight", cost = 94, requirements = { faction = "Horde" } }, -- Valormok -> Splintertree Post
{ from = "TAXI_44", to = "TAXI_80", method = "flight", cost = 223, requirements = { faction = "Horde" } }, -- Valormok -> Ratchet
{ from = "TAXI_44", to = "TAXI_30", method = "flight", cost = 357, requirements = { faction = "Horde" } }, -- Valormok -> Freewind Post
{ from = "TAXI_44", to = "TAXI_38", method = "flight", cost = 416, requirements = { faction = "Horde" } }, -- Valormok -> Shadowprey Village
{ from = "TAXI_44", to = "TAXI_42", method = "flight", cost = 423, requirements = { faction = "Horde" } }, -- Valormok -> Camp Mojache
{ from = "TAXI_44", to = "TAXI_48", method = "flight", cost = 232, requirements = { faction = "Horde" } }, -- Valormok -> Bloodvenom Post
{ from = "TAXI_44", to = "TAXI_55", method = "flight", cost = 335, requirements = { faction = "Horde" } }, -- Valormok -> Brackenwall Village
{ from = "TAXI_44", to = "TAXI_58", method = "flight", cost = 253, requirements = { faction = "Horde" } }, -- Valormok -> Zoram'gar Outpost
{ from = "TAXI_44", to = "TAXI_69", method = "flight", cost = 264, requirements = { faction = "Horde" } }, -- Valormok -> Moonglade
{ from = "TAXI_44", to = "TAXI_72", method = "flight", cost = 553, requirements = { faction = "Horde" } }, -- Valormok -> Cenarion Hold
{ from = "TAXI_44", to = "TAXI_77", method = "flight", cost = 263, requirements = { faction = "Horde" } }, -- Valormok -> Camp Taurajo
{ from = "TAXI_44", to = "TAXI_79", method = "flight", cost = 556, requirements = { faction = "Horde" } }, -- Valormok -> Marshal's Refuge
{ from = "TAXI_48", to = "TAXI_22", method = "flight", cost = 423, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Thunder Bluff
{ from = "TAXI_48", to = "TAXI_23", method = "flight", cost = 259, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Orgrimmar
{ from = "TAXI_48", to = "TAXI_25", method = "flight", cost = 241, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Crossroads
{ from = "TAXI_48", to = "TAXI_29", method = "flight", cost = 390, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Sun Rock Retreat
{ from = "TAXI_48", to = "TAXI_30", method = "flight", cost = 426, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Freewind Post
{ from = "TAXI_48", to = "TAXI_38", method = "flight", cost = 533, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Shadowprey Village
{ from = "TAXI_48", to = "TAXI_40", method = "flight", cost = 518, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Gadgetzan
{ from = "TAXI_48", to = "TAXI_42", method = "flight", cost = 493, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Camp Mojache
{ from = "TAXI_48", to = "TAXI_44", method = "flight", cost = 241, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Valormok
{ from = "TAXI_48", to = "TAXI_53", method = "flight", cost = 190, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Everlook
{ from = "TAXI_48", to = "TAXI_55", method = "flight", cost = 404, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Brackenwall Village
{ from = "TAXI_48", to = "TAXI_58", method = "flight", cost = 471, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Zoram'gar Outpost
{ from = "TAXI_48", to = "TAXI_61", method = "flight", cost = 333, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Splintertree Post
{ from = "TAXI_48", to = "TAXI_69", method = "flight", cost = 166, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Moonglade
{ from = "TAXI_48", to = "TAXI_72", method = "flight", cost = 623, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Cenarion Hold
{ from = "TAXI_48", to = "TAXI_77", method = "flight", cost = 331, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Camp Taurajo
{ from = "TAXI_48", to = "TAXI_79", method = "flight", cost = 625, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Marshal's Refuge
{ from = "TAXI_48", to = "TAXI_80", method = "flight", cost = 292, requirements = { faction = "Horde" } }, -- Bloodvenom Post -> Ratchet
{ from = "TAXI_53", to = "TAXI_22", method = "flight", cost = 529, requirements = { faction = "Horde" } }, -- Everlook -> Thunder Bluff
{ from = "TAXI_53", to = "TAXI_23", method = "flight", cost = 304, requirements = { faction = "Horde" } }, -- Everlook -> Orgrimmar
{ from = "TAXI_53", to = "TAXI_25", method = "flight", cost = 307, requirements = { faction = "Horde" } }, -- Everlook -> Crossroads
{ from = "TAXI_53", to = "TAXI_29", method = "flight", cost = 456, requirements = { faction = "Horde" } }, -- Everlook -> Sun Rock Retreat
{ from = "TAXI_53", to = "TAXI_30", method = "flight", cost = 491, requirements = { faction = "Horde" } }, -- Everlook -> Freewind Post
{ from = "TAXI_53", to = "TAXI_40", method = "flight", cost = 584, requirements = { faction = "Horde" } }, -- Everlook -> Gadgetzan
{ from = "TAXI_53", to = "TAXI_42", method = "flight", cost = 558, requirements = { faction = "Horde" } }, -- Everlook -> Camp Mojache
{ from = "TAXI_53", to = "TAXI_44", method = "flight", cost = 135, requirements = { faction = "Horde" } }, -- Everlook -> Valormok
{ from = "TAXI_53", to = "TAXI_55", method = "flight", cost = 470, requirements = { faction = "Horde" } }, -- Everlook -> Brackenwall Village
{ from = "TAXI_53", to = "TAXI_58", method = "flight", cost = 388, requirements = { faction = "Horde" } }, -- Everlook -> Zoram'gar Outpost
{ from = "TAXI_53", to = "TAXI_69", method = "flight", cost = 134, requirements = { faction = "Horde" } }, -- Everlook -> Moonglade
{ from = "TAXI_53", to = "TAXI_77", method = "flight", cost = 397, requirements = { faction = "Horde" } }, -- Everlook -> Camp Taurajo
{ from = "TAXI_53", to = "TAXI_80", method = "flight", cost = 357, requirements = { faction = "Horde" } }, -- Everlook -> Ratchet
{ from = "TAXI_53", to = "TAXI_38", method = "flight", cost = 550, requirements = { faction = "Horde" } }, -- Everlook -> Shadowprey Village
{ from = "TAXI_53", to = "TAXI_48", method = "flight", cost = 195, requirements = { faction = "Horde" } }, -- Everlook -> Bloodvenom Post
{ from = "TAXI_53", to = "TAXI_72", method = "flight", cost = 688, requirements = { faction = "Horde" } }, -- Everlook -> Cenarion Hold
{ from = "TAXI_53", to = "TAXI_79", method = "flight", cost = 691, requirements = { faction = "Horde" } }, -- Everlook -> Marshal's Refuge
{ from = "TAXI_55", to = "TAXI_22", method = "flight", cost = 224, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Thunder Bluff
{ from = "TAXI_55", to = "TAXI_23", method = "flight", cost = 217, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Orgrimmar
{ from = "TAXI_55", to = "TAXI_29", method = "flight", cost = 311, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Sun Rock Retreat
{ from = "TAXI_55", to = "TAXI_30", method = "flight", cost = 347, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Freewind Post
{ from = "TAXI_55", to = "TAXI_38", method = "flight", cost = 383, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Shadowprey Village
{ from = "TAXI_55", to = "TAXI_40", method = "flight", cost = 222, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Gadgetzan
{ from = "TAXI_55", to = "TAXI_42", method = "flight", cost = 414, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Camp Mojache
{ from = "TAXI_55", to = "TAXI_53", method = "flight", cost = 445, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Everlook
{ from = "TAXI_55", to = "TAXI_61", method = "flight", cost = 306, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Splintertree Post
{ from = "TAXI_55", to = "TAXI_77", method = "flight", cost = 252, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Camp Taurajo
{ from = "TAXI_55", to = "TAXI_80", method = "flight", cost = 214, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Ratchet
{ from = "TAXI_55", to = "TAXI_44", method = "flight", cost = 316, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Valormok
{ from = "TAXI_55", to = "TAXI_48", method = "flight", cost = 415, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Bloodvenom Post
{ from = "TAXI_55", to = "TAXI_72", method = "flight", cost = 430, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Cenarion Hold
{ from = "TAXI_55", to = "TAXI_79", method = "flight", cost = 329, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Marshal's Refuge
{ from = "TAXI_56", to = "TAXI_10", method = "flight", cost = 761, requirements = { faction = "Horde" } }, -- Stonard -> The Sepulcher
{ from = "TAXI_56", to = "TAXI_11", method = "flight", cost = 782, requirements = { faction = "Horde" } }, -- Stonard -> Undercity
{ from = "TAXI_56", to = "TAXI_13", method = "flight", cost = 663, requirements = { faction = "Horde" } }, -- Stonard -> Tarren Mill
{ from = "TAXI_56", to = "TAXI_17", method = "flight", cost = 547, requirements = { faction = "Horde" } }, -- Stonard -> Hammerfall
{ from = "TAXI_56", to = "TAXI_18", method = "flight", cost = 260, requirements = { faction = "Horde" } }, -- Stonard -> Booty Bay
{ from = "TAXI_56", to = "TAXI_20", method = "flight", cost = 189, requirements = { faction = "Horde" } }, -- Stonard -> Grom'gol
{ from = "TAXI_56", to = "TAXI_21", method = "flight", cost = 285, requirements = { faction = "Horde" } }, -- Stonard -> Kargath
{ from = "TAXI_56", to = "TAXI_68", method = "flight", cost = 774, requirements = { faction = "Horde" } }, -- Stonard -> Light's Hope Chapel
{ from = "TAXI_56", to = "TAXI_70", method = "flight", cost = 197, requirements = { faction = "Horde" } }, -- Stonard -> Flame Crest
{ from = "TAXI_56", to = "TAXI_75", method = "flight", cost = 341, requirements = { faction = "Horde" } }, -- Stonard -> Thorium Point
{ from = "TAXI_56", to = "TAXI_76", method = "flight", cost = 636, requirements = { faction = "Horde" } }, -- Stonard -> Revantusk Village
{ from = "TAXI_58", to = "TAXI_22", method = "flight", cost = 410, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Thunder Bluff
{ from = "TAXI_58", to = "TAXI_23", method = "flight", cost = 256, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Orgrimmar
{ from = "TAXI_58", to = "TAXI_25", method = "flight", cost = 228, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Crossroads
{ from = "TAXI_58", to = "TAXI_29", method = "flight", cost = 378, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Sun Rock Retreat
{ from = "TAXI_58", to = "TAXI_40", method = "flight", cost = 504, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Gadgetzan
{ from = "TAXI_58", to = "TAXI_55", method = "flight", cost = 391, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Brackenwall Village
{ from = "TAXI_58", to = "TAXI_61", method = "flight", cost = 167, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Splintertree Post
{ from = "TAXI_58", to = "TAXI_69", method = "flight", cost = 517, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Moonglade
{ from = "TAXI_58", to = "TAXI_80", method = "flight", cost = 279, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Ratchet
{ from = "TAXI_58", to = "TAXI_30", method = "flight", cost = 412, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Freewind Post
{ from = "TAXI_58", to = "TAXI_44", method = "flight", cost = 256, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Valormok
{ from = "TAXI_58", to = "TAXI_48", method = "flight", cost = 481, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Bloodvenom Post
{ from = "TAXI_58", to = "TAXI_53", method = "flight", cost = 384, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Everlook
{ from = "TAXI_58", to = "TAXI_77", method = "flight", cost = 318, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Camp Taurajo
{ from = "TAXI_58", to = "TAXI_79", method = "flight", cost = 611, requirements = { faction = "Horde" } }, -- Zoram'gar Outpost -> Marshal's Refuge
{ from = "TAXI_61", to = "TAXI_22", method = "flight", cost = 321, requirements = { faction = "Horde" } }, -- Splintertree Post -> Thunder Bluff
{ from = "TAXI_61", to = "TAXI_23", method = "flight", cost = 96, requirements = { faction = "Horde" } }, -- Splintertree Post -> Orgrimmar
{ from = "TAXI_61", to = "TAXI_29", method = "flight", cost = 310, requirements = { faction = "Horde" } }, -- Splintertree Post -> Sun Rock Retreat
{ from = "TAXI_61", to = "TAXI_38", method = "flight", cost = 453, requirements = { faction = "Horde" } }, -- Splintertree Post -> Shadowprey Village
{ from = "TAXI_61", to = "TAXI_40", method = "flight", cost = 436, requirements = { faction = "Horde" } }, -- Splintertree Post -> Gadgetzan
{ from = "TAXI_61", to = "TAXI_42", method = "flight", cost = 412, requirements = { faction = "Horde" } }, -- Splintertree Post -> Camp Mojache
{ from = "TAXI_61", to = "TAXI_44", method = "flight", cost = 96, requirements = { faction = "Horde" } }, -- Splintertree Post -> Valormok
{ from = "TAXI_61", to = "TAXI_53", method = "flight", cost = 224, requirements = { faction = "Horde" } }, -- Splintertree Post -> Everlook
{ from = "TAXI_61", to = "TAXI_55", method = "flight", cost = 323, requirements = { faction = "Horde" } }, -- Splintertree Post -> Brackenwall Village
{ from = "TAXI_61", to = "TAXI_58", method = "flight", cost = 166, requirements = { faction = "Horde" } }, -- Splintertree Post -> Zoram'gar Outpost
{ from = "TAXI_61", to = "TAXI_69", method = "flight", cost = 356, requirements = { faction = "Horde" } }, -- Splintertree Post -> Moonglade
{ from = "TAXI_61", to = "TAXI_80", method = "flight", cost = 212, requirements = { faction = "Horde" } }, -- Splintertree Post -> Ratchet
{ from = "TAXI_61", to = "TAXI_30", method = "flight", cost = 345, requirements = { faction = "Horde" } }, -- Splintertree Post -> Freewind Post
{ from = "TAXI_61", to = "TAXI_48", method = "flight", cost = 327, requirements = { faction = "Horde" } }, -- Splintertree Post -> Bloodvenom Post
{ from = "TAXI_61", to = "TAXI_72", method = "flight", cost = 541, requirements = { faction = "Horde" } }, -- Splintertree Post -> Cenarion Hold
{ from = "TAXI_61", to = "TAXI_77", method = "flight", cost = 250, requirements = { faction = "Horde" } }, -- Splintertree Post -> Camp Taurajo
{ from = "TAXI_61", to = "TAXI_79", method = "flight", cost = 544, requirements = { faction = "Horde" } }, -- Splintertree Post -> Marshal's Refuge
{ from = "TAXI_68", to = "TAXI_10", method = "flight", cost = 294, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> The Sepulcher
{ from = "TAXI_68", to = "TAXI_11", method = "flight", cost = 262, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Undercity
{ from = "TAXI_68", to = "TAXI_13", method = "flight", cost = 301, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Tarren Mill
{ from = "TAXI_68", to = "TAXI_17", method = "flight", cost = 234, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Hammerfall
{ from = "TAXI_68", to = "TAXI_18", method = "flight", cost = 884, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Booty Bay
{ from = "TAXI_68", to = "TAXI_20", method = "flight", cost = 804, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Grom'gol
{ from = "TAXI_68", to = "TAXI_56", method = "flight", cost = 773, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Stonard
{ from = "TAXI_68", to = "TAXI_70", method = "flight", cost = 578, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Flame Crest
{ from = "TAXI_68", to = "TAXI_75", method = "flight", cost = 547, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Thorium Point
{ from = "TAXI_68", to = "TAXI_76", method = "flight", cost = 141, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Revantusk Village
{ from = "TAXI_68", to = "TAXI_21", method = "flight", cost = 492, requirements = { faction = "Horde" } }, -- Light's Hope Chapel -> Kargath
{ from = "TAXI_69", to = "TAXI_22", method = "flight", cost = 532, requirements = { faction = "Horde" } }, -- Moonglade -> Thunder Bluff
{ from = "TAXI_69", to = "TAXI_23", method = "flight", cost = 395, requirements = { faction = "Horde" } }, -- Moonglade -> Orgrimmar
{ from = "TAXI_69", to = "TAXI_29", method = "flight", cost = 502, requirements = { faction = "Horde" } }, -- Moonglade -> Sun Rock Retreat
{ from = "TAXI_69", to = "TAXI_53", method = "flight", cost = 142, requirements = { faction = "Horde" } }, -- Moonglade -> Everlook
{ from = "TAXI_69", to = "TAXI_58", method = "flight", cost = 528, requirements = { faction = "Horde" } }, -- Moonglade -> Zoram'gar Outpost
{ from = "TAXI_69", to = "TAXI_61", method = "flight", cost = 369, requirements = { faction = "Horde" } }, -- Moonglade -> Splintertree Post
{ from = "TAXI_69", to = "TAXI_30", method = "flight", cost = 537, requirements = { faction = "Horde" } }, -- Moonglade -> Freewind Post
{ from = "TAXI_69", to = "TAXI_38", method = "flight", cost = 645, requirements = { faction = "Horde" } }, -- Moonglade -> Shadowprey Village
{ from = "TAXI_69", to = "TAXI_40", method = "flight", cost = 629, requirements = { faction = "Horde" } }, -- Moonglade -> Gadgetzan
{ from = "TAXI_69", to = "TAXI_44", method = "flight", cost = 275, requirements = { faction = "Horde" } }, -- Moonglade -> Valormok
{ from = "TAXI_69", to = "TAXI_48", method = "flight", cost = 157, requirements = { faction = "Horde" } }, -- Moonglade -> Bloodvenom Post
{ from = "TAXI_69", to = "TAXI_55", method = "flight", cost = 515, requirements = { faction = "Horde" } }, -- Moonglade -> Brackenwall Village
{ from = "TAXI_69", to = "TAXI_72", method = "flight", cost = 734, requirements = { faction = "Horde" } }, -- Moonglade -> Cenarion Hold
{ from = "TAXI_69", to = "TAXI_77", method = "flight", cost = 443, requirements = { faction = "Horde" } }, -- Moonglade -> Camp Taurajo
{ from = "TAXI_69", to = "TAXI_79", method = "flight", cost = 736, requirements = { faction = "Horde" } }, -- Moonglade -> Marshal's Refuge
{ from = "TAXI_70", to = "TAXI_10", method = "flight", cost = 576, requirements = { faction = "Horde" } }, -- Flame Crest -> The Sepulcher
{ from = "TAXI_70", to = "TAXI_11", method = "flight", cost = 597, requirements = { faction = "Horde" } }, -- Flame Crest -> Undercity
{ from = "TAXI_70", to = "TAXI_13", method = "flight", cost = 477, requirements = { faction = "Horde" } }, -- Flame Crest -> Tarren Mill
{ from = "TAXI_70", to = "TAXI_17", method = "flight", cost = 361, requirements = { faction = "Horde" } }, -- Flame Crest -> Hammerfall
{ from = "TAXI_70", to = "TAXI_18", method = "flight", cost = 472, requirements = { faction = "Horde" } }, -- Flame Crest -> Booty Bay
{ from = "TAXI_70", to = "TAXI_20", method = "flight", cost = 401, requirements = { faction = "Horde" } }, -- Flame Crest -> Grom'gol
{ from = "TAXI_70", to = "TAXI_21", method = "flight", cost = 99, requirements = { faction = "Horde" } }, -- Flame Crest -> Kargath
{ from = "TAXI_70", to = "TAXI_56", method = "flight", cost = 213, requirements = { faction = "Horde" } }, -- Flame Crest -> Stonard
{ from = "TAXI_70", to = "TAXI_68", method = "flight", cost = 589, requirements = { faction = "Horde" } }, -- Flame Crest -> Light's Hope Chapel
{ from = "TAXI_70", to = "TAXI_75", method = "flight", cost = 72, requirements = { faction = "Horde" } }, -- Flame Crest -> Thorium Point
{ from = "TAXI_70", to = "TAXI_76", method = "flight", cost = 451, requirements = { faction = "Horde" } }, -- Flame Crest -> Revantusk Village
{ from = "TAXI_72", to = "TAXI_22", method = "flight", cost = 389, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Thunder Bluff
{ from = "TAXI_72", to = "TAXI_23", method = "flight", cost = 535, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Orgrimmar
{ from = "TAXI_72", to = "TAXI_25", method = "flight", cost = 394, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Crossroads
{ from = "TAXI_72", to = "TAXI_29", method = "flight", cost = 529, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Sun Rock Retreat
{ from = "TAXI_72", to = "TAXI_30", method = "flight", cost = 236, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Freewind Post
{ from = "TAXI_72", to = "TAXI_38", method = "flight", cost = 330, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Shadowprey Village
{ from = "TAXI_72", to = "TAXI_40", method = "flight", cost = 241, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Gadgetzan
{ from = "TAXI_72", to = "TAXI_42", method = "flight", cost = 129, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Camp Mojache
{ from = "TAXI_72", to = "TAXI_44", method = "flight", cost = 562, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Valormok
{ from = "TAXI_72", to = "TAXI_48", method = "flight", cost = 648, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Bloodvenom Post
{ from = "TAXI_72", to = "TAXI_53", method = "flight", cost = 691, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Everlook
{ from = "TAXI_72", to = "TAXI_55", method = "flight", cost = 425, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Brackenwall Village
{ from = "TAXI_72", to = "TAXI_61", method = "flight", cost = 556, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Splintertree Post
{ from = "TAXI_72", to = "TAXI_69", method = "flight", cost = 768, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Moonglade
{ from = "TAXI_72", to = "TAXI_77", method = "flight", cost = 373, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Camp Taurajo
{ from = "TAXI_72", to = "TAXI_79", method = "flight", cost = 97, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Marshal's Refuge
{ from = "TAXI_72", to = "TAXI_80", method = "flight", cost = 445, requirements = { faction = "Horde" } }, -- Cenarion Hold -> Ratchet
{ from = "TAXI_75", to = "TAXI_10", method = "flight", cost = 545, requirements = { faction = "Horde" } }, -- Thorium Point -> The Sepulcher
{ from = "TAXI_75", to = "TAXI_11", method = "flight", cost = 566, requirements = { faction = "Horde" } }, -- Thorium Point -> Undercity
{ from = "TAXI_75", to = "TAXI_13", method = "flight", cost = 447, requirements = { faction = "Horde" } }, -- Thorium Point -> Tarren Mill
{ from = "TAXI_75", to = "TAXI_17", method = "flight", cost = 331, requirements = { faction = "Horde" } }, -- Thorium Point -> Hammerfall
{ from = "TAXI_75", to = "TAXI_18", method = "flight", cost = 462, requirements = { faction = "Horde" } }, -- Thorium Point -> Booty Bay
{ from = "TAXI_75", to = "TAXI_20", method = "flight", cost = 382, requirements = { faction = "Horde" } }, -- Thorium Point -> Grom'gol
{ from = "TAXI_75", to = "TAXI_21", method = "flight", cost = 70, requirements = { faction = "Horde" } }, -- Thorium Point -> Kargath
{ from = "TAXI_75", to = "TAXI_56", method = "flight", cost = 350, requirements = { faction = "Horde" } }, -- Thorium Point -> Stonard
{ from = "TAXI_75", to = "TAXI_68", method = "flight", cost = 559, requirements = { faction = "Horde" } }, -- Thorium Point -> Light's Hope Chapel
{ from = "TAXI_75", to = "TAXI_70", method = "flight", cost = 77, requirements = { faction = "Horde" } }, -- Thorium Point -> Flame Crest
{ from = "TAXI_75", to = "TAXI_76", method = "flight", cost = 420, requirements = { faction = "Horde" } }, -- Thorium Point -> Revantusk Village
{ from = "TAXI_76", to = "TAXI_10", method = "flight", cost = 257, requirements = { faction = "Horde" } }, -- Revantusk Village -> The Sepulcher
{ from = "TAXI_76", to = "TAXI_11", method = "flight", cost = 284, requirements = { faction = "Horde" } }, -- Revantusk Village -> Undercity
{ from = "TAXI_76", to = "TAXI_13", method = "flight", cost = 159, requirements = { faction = "Horde" } }, -- Revantusk Village -> Tarren Mill
{ from = "TAXI_76", to = "TAXI_17", method = "flight", cost = 93, requirements = { faction = "Horde" } }, -- Revantusk Village -> Hammerfall
{ from = "TAXI_76", to = "TAXI_18", method = "flight", cost = 743, requirements = { faction = "Horde" } }, -- Revantusk Village -> Booty Bay
{ from = "TAXI_76", to = "TAXI_20", method = "flight", cost = 663, requirements = { faction = "Horde" } }, -- Revantusk Village -> Grom'gol
{ from = "TAXI_76", to = "TAXI_56", method = "flight", cost = 631, requirements = { faction = "Horde" } }, -- Revantusk Village -> Stonard
{ from = "TAXI_76", to = "TAXI_68", method = "flight", cost = 139, requirements = { faction = "Horde" } }, -- Revantusk Village -> Light's Hope Chapel
{ from = "TAXI_76", to = "TAXI_70", method = "flight", cost = 437, requirements = { faction = "Horde" } }, -- Revantusk Village -> Flame Crest
{ from = "TAXI_76", to = "TAXI_75", method = "flight", cost = 407, requirements = { faction = "Horde" } }, -- Revantusk Village -> Thorium Point
{ from = "TAXI_76", to = "TAXI_21", method = "flight", cost = 351, requirements = { faction = "Horde" } }, -- Revantusk Village -> Kargath
{ from = "TAXI_77", to = "TAXI_22", method = "flight", cost = 114, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Thunder Bluff
{ from = "TAXI_77", to = "TAXI_23", method = "flight", cost = 221, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Orgrimmar
{ from = "TAXI_77", to = "TAXI_25", method = "flight", cost = 79, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Crossroads
{ from = "TAXI_77", to = "TAXI_42", method = "flight", cost = 248, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Camp Mojache
{ from = "TAXI_77", to = "TAXI_55", method = "flight", cost = 242, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Brackenwall Village
{ from = "TAXI_77", to = "TAXI_79", method = "flight", cost = 325, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Marshal's Refuge
{ from = "TAXI_77", to = "TAXI_29", method = "flight", cost = 229, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Sun Rock Retreat
{ from = "TAXI_77", to = "TAXI_30", method = "flight", cost = 125, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Freewind Post
{ from = "TAXI_77", to = "TAXI_38", method = "flight", cost = 273, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Shadowprey Village
{ from = "TAXI_77", to = "TAXI_40", method = "flight", cost = 218, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Gadgetzan
{ from = "TAXI_77", to = "TAXI_44", method = "flight", cost = 248, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Valormok
{ from = "TAXI_77", to = "TAXI_48", method = "flight", cost = 333, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Bloodvenom Post
{ from = "TAXI_77", to = "TAXI_58", method = "flight", cost = 309, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Zoram'gar Outpost
{ from = "TAXI_77", to = "TAXI_61", method = "flight", cost = 242, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Splintertree Post
{ from = "TAXI_77", to = "TAXI_72", method = "flight", cost = 378, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Cenarion Hold
{ from = "TAXI_77", to = "TAXI_80", method = "flight", cost = 130, requirements = { faction = "Horde" } }, -- Camp Taurajo -> Ratchet
{ from = "TAXI_79", to = "TAXI_23", method = "flight", cost = 462, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Orgrimmar
{ from = "TAXI_79", to = "TAXI_25", method = "flight", cost = 392, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Crossroads
{ from = "TAXI_79", to = "TAXI_38", method = "flight", cost = 513, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Shadowprey Village
{ from = "TAXI_79", to = "TAXI_40", method = "flight", cost = 113, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Gadgetzan
{ from = "TAXI_79", to = "TAXI_42", method = "flight", cost = 312, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Camp Mojache
{ from = "TAXI_79", to = "TAXI_53", method = "flight", cost = 689, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Everlook
{ from = "TAXI_79", to = "TAXI_55", method = "flight", cost = 333, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Brackenwall Village
{ from = "TAXI_79", to = "TAXI_80", method = "flight", cost = 443, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Ratchet
{ from = "TAXI_79", to = "TAXI_29", method = "flight", cost = 542, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Sun Rock Retreat
{ from = "TAXI_79", to = "TAXI_30", method = "flight", cost = 200, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Freewind Post
{ from = "TAXI_79", to = "TAXI_44", method = "flight", cost = 559, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Valormok
{ from = "TAXI_79", to = "TAXI_48", method = "flight", cost = 645, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Bloodvenom Post
{ from = "TAXI_79", to = "TAXI_58", method = "flight", cost = 622, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Zoram'gar Outpost
{ from = "TAXI_79", to = "TAXI_61", method = "flight", cost = 551, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Splintertree Post
{ from = "TAXI_79", to = "TAXI_69", method = "flight", cost = 766, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Moonglade
{ from = "TAXI_79", to = "TAXI_72", method = "flight", cost = 100, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Cenarion Hold
{ from = "TAXI_79", to = "TAXI_77", method = "flight", cost = 336, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Camp Taurajo
{ from = "TAXI_80", to = "TAXI_22", method = "flight", cost = 250, requirements = { faction = "Horde" } }, -- Ratchet -> Thunder Bluff
{ from = "TAXI_80", to = "TAXI_23", method = "flight", cost = 210, requirements = { faction = "Horde" } }, -- Ratchet -> Orgrimmar
{ from = "TAXI_80", to = "TAXI_25", method = "flight", cost = 69, requirements = { faction = "Horde" } }, -- Ratchet -> Crossroads
{ from = "TAXI_80", to = "TAXI_30", method = "flight", cost = 252, requirements = { faction = "Horde" } }, -- Ratchet -> Freewind Post
{ from = "TAXI_80", to = "TAXI_38", method = "flight", cost = 360, requirements = { faction = "Horde" } }, -- Ratchet -> Shadowprey Village
{ from = "TAXI_80", to = "TAXI_40", method = "flight", cost = 345, requirements = { faction = "Horde" } }, -- Ratchet -> Gadgetzan
{ from = "TAXI_80", to = "TAXI_42", method = "flight", cost = 320, requirements = { faction = "Horde" } }, -- Ratchet -> Camp Mojache
{ from = "TAXI_80", to = "TAXI_53", method = "flight", cost = 366, requirements = { faction = "Horde" } }, -- Ratchet -> Everlook
{ from = "TAXI_80", to = "TAXI_55", method = "flight", cost = 231, requirements = { faction = "Horde" } }, -- Ratchet -> Brackenwall Village
{ from = "TAXI_80", to = "TAXI_58", method = "flight", cost = 299, requirements = { faction = "Horde" } }, -- Ratchet -> Zoram'gar Outpost
{ from = "TAXI_80", to = "TAXI_61", method = "flight", cost = 231, requirements = { faction = "Horde" } }, -- Ratchet -> Splintertree Post
{ from = "TAXI_80", to = "TAXI_77", method = "flight", cost = 158, requirements = { faction = "Horde" } }, -- Ratchet -> Camp Taurajo
{ from = "TAXI_80", to = "TAXI_79", method = "flight", cost = 452, requirements = { faction = "Horde" } }, -- Ratchet -> Marshal's Refuge
{ from = "TAXI_80", to = "TAXI_44", method = "flight", cost = 236, requirements = { faction = "Horde" } }, -- Ratchet -> Valormok
{ from = "TAXI_80", to = "TAXI_48", method = "flight", cost = 321, requirements = { faction = "Horde" } }, -- Ratchet -> Bloodvenom Post
{ from = "TAXI_80", to = "TAXI_72", method = "flight", cost = 450, requirements = { faction = "Horde" } }, -- Ratchet -> Cenarion Hold
{ from = "TAXI_2", to = "TAXI_4", method = "flight", cost = 78, requirements = { faction = "Alliance" } }, -- Stormwind -> Sentinel Hill
{ from = "TAXI_2", to = "TAXI_6", method = "flight", cost = 259, requirements = { faction = "Alliance" } }, -- Stormwind -> Ironforge
{ from = "TAXI_2", to = "TAXI_7", method = "flight", cost = 343, requirements = { faction = "Alliance" } }, -- Stormwind -> Menethil Harbor
{ from = "TAXI_2", to = "TAXI_8", method = "flight", cost = 317, requirements = { faction = "Alliance" } }, -- Stormwind -> Thelsamar
{ from = "TAXI_2", to = "TAXI_16", method = "flight", cost = 450, requirements = { faction = "Alliance" } }, -- Stormwind -> Refuge Pointe
{ from = "TAXI_2", to = "TAXI_19", method = "flight", cost = 245, requirements = { faction = "Alliance" } }, -- Stormwind -> Booty Bay
{ from = "TAXI_2", to = "TAXI_43", method = "flight", cost = 508, requirements = { faction = "Alliance" } }, -- Stormwind -> Aerie Peak
{ from = "TAXI_2", to = "TAXI_66", method = "flight", cost = 506, requirements = { faction = "Alliance" } }, -- Stormwind -> Chillwind Camp
{ from = "TAXI_2", to = "TAXI_67", method = "flight", cost = 563, requirements = { faction = "Alliance" } }, -- Stormwind -> Light's Hope Chapel
{ from = "TAXI_2", to = "TAXI_71", method = "flight", cost = 157, requirements = { faction = "Alliance" } }, -- Stormwind -> Morgan's Vigil
{ from = "TAXI_2", to = "TAXI_74", method = "flight", cost = 247, requirements = { faction = "Alliance" } }, -- Stormwind -> Thorium Point
{ from = "TAXI_2", to = "TAXI_14", method = "flight", cost = 443, requirements = { faction = "Alliance" } }, -- Stormwind -> Southshore
{ from = "TAXI_4", to = "TAXI_2", method = "flight", cost = 86, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Stormwind
{ from = "TAXI_4", to = "TAXI_5", method = "flight", cost = 130, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Lakeshire
{ from = "TAXI_4", to = "TAXI_6", method = "flight", cost = 331, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Ironforge
{ from = "TAXI_4", to = "TAXI_7", method = "flight", cost = 414, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Menethil Harbor
{ from = "TAXI_4", to = "TAXI_8", method = "flight", cost = 389, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Thelsamar
{ from = "TAXI_4", to = "TAXI_12", method = "flight", cost = 97, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Darkshire
{ from = "TAXI_4", to = "TAXI_19", method = "flight", cost = 185, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Booty Bay
{ from = "TAXI_4", to = "TAXI_45", method = "flight", cost = 186, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Nethergarde Keep
{ from = "TAXI_4", to = "TAXI_67", method = "flight", cost = 636, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Light's Hope Chapel
{ from = "TAXI_4", to = "TAXI_71", method = "flight", cost = 191, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Morgan's Vigil
{ from = "TAXI_4", to = "TAXI_74", method = "flight", cost = 282, requirements = { faction = "Alliance" } }, -- Sentinel Hill -> Thorium Point
{ from = "TAXI_5", to = "TAXI_2", method = "flight", cost = 113, requirements = { faction = "Alliance" } }, -- Lakeshire -> Stormwind
{ from = "TAXI_5", to = "TAXI_4", method = "flight", cost = 133, requirements = { faction = "Alliance" } }, -- Lakeshire -> Sentinel Hill
{ from = "TAXI_5", to = "TAXI_6", method = "flight", cost = 357, requirements = { faction = "Alliance" } }, -- Lakeshire -> Ironforge
{ from = "TAXI_5", to = "TAXI_7", method = "flight", cost = 441, requirements = { faction = "Alliance" } }, -- Lakeshire -> Menethil Harbor
{ from = "TAXI_5", to = "TAXI_8", method = "flight", cost = 416, requirements = { faction = "Alliance" } }, -- Lakeshire -> Thelsamar
{ from = "TAXI_5", to = "TAXI_12", method = "flight", cost = 60, requirements = { faction = "Alliance" } }, -- Lakeshire -> Darkshire
{ from = "TAXI_5", to = "TAXI_16", method = "flight", cost = 550, requirements = { faction = "Alliance" } }, -- Lakeshire -> Refuge Pointe
{ from = "TAXI_5", to = "TAXI_19", method = "flight", cost = 317, requirements = { faction = "Alliance" } }, -- Lakeshire -> Booty Bay
{ from = "TAXI_5", to = "TAXI_45", method = "flight", cost = 148, requirements = { faction = "Alliance" } }, -- Lakeshire -> Nethergarde Keep
{ from = "TAXI_5", to = "TAXI_66", method = "flight", cost = 484, requirements = { faction = "Alliance" } }, -- Lakeshire -> Chillwind Camp
{ from = "TAXI_5", to = "TAXI_67", method = "flight", cost = 540, requirements = { faction = "Alliance" } }, -- Lakeshire -> Light's Hope Chapel
{ from = "TAXI_5", to = "TAXI_71", method = "flight", cost = 61, requirements = { faction = "Alliance" } }, -- Lakeshire -> Morgan's Vigil
{ from = "TAXI_5", to = "TAXI_74", method = "flight", cost = 153, requirements = { faction = "Alliance" } }, -- Lakeshire -> Thorium Point
{ from = "TAXI_6", to = "TAXI_4", method = "flight", cost = 274, requirements = { faction = "Alliance" } }, -- Ironforge -> Sentinel Hill
{ from = "TAXI_6", to = "TAXI_5", method = "flight", cost = 201, requirements = { faction = "Alliance" } }, -- Ironforge -> Lakeshire
{ from = "TAXI_6", to = "TAXI_7", method = "flight", cost = 128, requirements = { faction = "Alliance" } }, -- Ironforge -> Menethil Harbor
{ from = "TAXI_6", to = "TAXI_12", method = "flight", cost = 260, requirements = { faction = "Alliance" } }, -- Ironforge -> Darkshire
{ from = "TAXI_6", to = "TAXI_16", method = "flight", cost = 253, requirements = { faction = "Alliance" } }, -- Ironforge -> Refuge Pointe
{ from = "TAXI_6", to = "TAXI_19", method = "flight", cost = 440, requirements = { faction = "Alliance" } }, -- Ironforge -> Booty Bay
{ from = "TAXI_6", to = "TAXI_43", method = "flight", cost = 298, requirements = { faction = "Alliance" } }, -- Ironforge -> Aerie Peak
{ from = "TAXI_6", to = "TAXI_45", method = "flight", cost = 373, requirements = { faction = "Alliance" } }, -- Ironforge -> Nethergarde Keep
{ from = "TAXI_6", to = "TAXI_66", method = "flight", cost = 294, requirements = { faction = "Alliance" } }, -- Ironforge -> Chillwind Camp
{ from = "TAXI_6", to = "TAXI_67", method = "flight", cost = 349, requirements = { faction = "Alliance" } }, -- Ironforge -> Light's Hope Chapel
{ from = "TAXI_6", to = "TAXI_71", method = "flight", cost = 173, requirements = { faction = "Alliance" } }, -- Ironforge -> Morgan's Vigil
{ from = "TAXI_6", to = "TAXI_74", method = "flight", cost = 87, requirements = { faction = "Alliance" } }, -- Ironforge -> Thorium Point
{ from = "TAXI_6", to = "TAXI_14", method = "flight", cost = 265, requirements = { faction = "Alliance" } }, -- Ironforge -> Southshore
{ from = "TAXI_7", to = "TAXI_2", method = "flight", cost = 261, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Stormwind
{ from = "TAXI_7", to = "TAXI_4", method = "flight", cost = 324, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Sentinel Hill
{ from = "TAXI_7", to = "TAXI_5", method = "flight", cost = 359, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Lakeshire
{ from = "TAXI_7", to = "TAXI_12", method = "flight", cost = 362, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Darkshire
{ from = "TAXI_7", to = "TAXI_19", method = "flight", cost = 490, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Booty Bay
{ from = "TAXI_7", to = "TAXI_43", method = "flight", cost = 176, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Aerie Peak
{ from = "TAXI_7", to = "TAXI_45", method = "flight", cost = 423, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Nethergarde Keep
{ from = "TAXI_7", to = "TAXI_67", method = "flight", cost = 324, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Light's Hope Chapel
{ from = "TAXI_7", to = "TAXI_71", method = "flight", cost = 221, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Morgan's Vigil
{ from = "TAXI_7", to = "TAXI_74", method = "flight", cost = 135, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Thorium Point
{ from = "TAXI_7", to = "TAXI_14", method = "flight", cost = 107, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Southshore
{ from = "TAXI_8", to = "TAXI_2", method = "flight", cost = 279, requirements = { faction = "Alliance" } }, -- Thelsamar -> Stormwind
{ from = "TAXI_8", to = "TAXI_4", method = "flight", cost = 342, requirements = { faction = "Alliance" } }, -- Thelsamar -> Sentinel Hill
{ from = "TAXI_8", to = "TAXI_5", method = "flight", cost = 267, requirements = { faction = "Alliance" } }, -- Thelsamar -> Lakeshire
{ from = "TAXI_8", to = "TAXI_12", method = "flight", cost = 380, requirements = { faction = "Alliance" } }, -- Thelsamar -> Darkshire
{ from = "TAXI_8", to = "TAXI_19", method = "flight", cost = 508, requirements = { faction = "Alliance" } }, -- Thelsamar -> Booty Bay
{ from = "TAXI_8", to = "TAXI_45", method = "flight", cost = 441, requirements = { faction = "Alliance" } }, -- Thelsamar -> Nethergarde Keep
{ from = "TAXI_8", to = "TAXI_66", method = "flight", cost = 285, requirements = { faction = "Alliance" } }, -- Thelsamar -> Chillwind Camp
{ from = "TAXI_8", to = "TAXI_74", method = "flight", cost = 152, requirements = { faction = "Alliance" } }, -- Thelsamar -> Thorium Point
{ from = "TAXI_8", to = "TAXI_14", method = "flight", cost = 250, requirements = { faction = "Alliance" } }, -- Thelsamar -> Southshore
{ from = "TAXI_12", to = "TAXI_4", method = "flight", cost = 93, requirements = { faction = "Alliance" } }, -- Darkshire -> Sentinel Hill
{ from = "TAXI_12", to = "TAXI_6", method = "flight", cost = 333, requirements = { faction = "Alliance" } }, -- Darkshire -> Ironforge
{ from = "TAXI_12", to = "TAXI_7", method = "flight", cost = 417, requirements = { faction = "Alliance" } }, -- Darkshire -> Menethil Harbor
{ from = "TAXI_12", to = "TAXI_8", method = "flight", cost = 391, requirements = { faction = "Alliance" } }, -- Darkshire -> Thelsamar
{ from = "TAXI_12", to = "TAXI_16", method = "flight", cost = 524, requirements = { faction = "Alliance" } }, -- Darkshire -> Refuge Pointe
{ from = "TAXI_12", to = "TAXI_19", method = "flight", cost = 171, requirements = { faction = "Alliance" } }, -- Darkshire -> Booty Bay
{ from = "TAXI_12", to = "TAXI_43", method = "flight", cost = 582, requirements = { faction = "Alliance" } }, -- Darkshire -> Aerie Peak
{ from = "TAXI_12", to = "TAXI_66", method = "flight", cost = 544, requirements = { faction = "Alliance" } }, -- Darkshire -> Chillwind Camp
{ from = "TAXI_12", to = "TAXI_71", method = "flight", cost = 120, requirements = { faction = "Alliance" } }, -- Darkshire -> Morgan's Vigil
{ from = "TAXI_12", to = "TAXI_74", method = "flight", cost = 212, requirements = { faction = "Alliance" } }, -- Darkshire -> Thorium Point
{ from = "TAXI_12", to = "TAXI_14", method = "flight", cost = 517, requirements = { faction = "Alliance" } }, -- Darkshire -> Southshore
{ from = "TAXI_14", to = "TAXI_2", method = "flight", cost = 367, requirements = { faction = "Alliance" } }, -- Southshore -> Stormwind
{ from = "TAXI_14", to = "TAXI_4", method = "flight", cost = 430, requirements = { faction = "Alliance" } }, -- Southshore -> Sentinel Hill
{ from = "TAXI_14", to = "TAXI_6", method = "flight", cost = 206, requirements = { faction = "Alliance" } }, -- Southshore -> Ironforge
{ from = "TAXI_14", to = "TAXI_7", method = "flight", cost = 110, requirements = { faction = "Alliance" } }, -- Southshore -> Menethil Harbor
{ from = "TAXI_14", to = "TAXI_8", method = "flight", cost = 244, requirements = { faction = "Alliance" } }, -- Southshore -> Thelsamar
{ from = "TAXI_14", to = "TAXI_12", method = "flight", cost = 468, requirements = { faction = "Alliance" } }, -- Southshore -> Darkshire
{ from = "TAXI_14", to = "TAXI_16", method = "flight", cost = 74, requirements = { faction = "Alliance" } }, -- Southshore -> Refuge Pointe
{ from = "TAXI_14", to = "TAXI_19", method = "flight", cost = 597, requirements = { faction = "Alliance" } }, -- Southshore -> Booty Bay
{ from = "TAXI_14", to = "TAXI_43", method = "flight", cost = 71, requirements = { faction = "Alliance" } }, -- Southshore -> Aerie Peak
{ from = "TAXI_14", to = "TAXI_66", method = "flight", cost = 81, requirements = { faction = "Alliance" } }, -- Southshore -> Chillwind Camp
{ from = "TAXI_14", to = "TAXI_67", method = "flight", cost = 219, requirements = { faction = "Alliance" } }, -- Southshore -> Light's Hope Chapel
{ from = "TAXI_14", to = "TAXI_74", method = "flight", cost = 242, requirements = { faction = "Alliance" } }, -- Southshore -> Thorium Point
{ from = "TAXI_16", to = "TAXI_2", method = "flight", cost = 386, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Stormwind
{ from = "TAXI_16", to = "TAXI_4", method = "flight", cost = 448, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Sentinel Hill
{ from = "TAXI_16", to = "TAXI_6", method = "flight", cost = 271, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Ironforge
{ from = "TAXI_16", to = "TAXI_12", method = "flight", cost = 485, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Darkshire
{ from = "TAXI_16", to = "TAXI_19", method = "flight", cost = 614, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Booty Bay
{ from = "TAXI_16", to = "TAXI_43", method = "flight", cost = 72, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Aerie Peak
{ from = "TAXI_16", to = "TAXI_45", method = "flight", cost = 547, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Nethergarde Keep
{ from = "TAXI_16", to = "TAXI_14", method = "flight", cost = 86, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Southshore
{ from = "TAXI_19", to = "TAXI_2", method = "flight", cost = 220, requirements = { faction = "Alliance" } }, -- Booty Bay -> Stormwind
{ from = "TAXI_19", to = "TAXI_4", method = "flight", cost = 181, requirements = { faction = "Alliance" } }, -- Booty Bay -> Sentinel Hill
{ from = "TAXI_19", to = "TAXI_5", method = "flight", cost = 230, requirements = { faction = "Alliance" } }, -- Booty Bay -> Lakeshire
{ from = "TAXI_19", to = "TAXI_6", method = "flight", cost = 464, requirements = { faction = "Alliance" } }, -- Booty Bay -> Ironforge
{ from = "TAXI_19", to = "TAXI_7", method = "flight", cost = 548, requirements = { faction = "Alliance" } }, -- Booty Bay -> Menethil Harbor
{ from = "TAXI_19", to = "TAXI_8", method = "flight", cost = 523, requirements = { faction = "Alliance" } }, -- Booty Bay -> Thelsamar
{ from = "TAXI_19", to = "TAXI_12", method = "flight", cost = 175, requirements = { faction = "Alliance" } }, -- Booty Bay -> Darkshire
{ from = "TAXI_19", to = "TAXI_16", method = "flight", cost = 655, requirements = { faction = "Alliance" } }, -- Booty Bay -> Refuge Pointe
{ from = "TAXI_19", to = "TAXI_43", method = "flight", cost = 715, requirements = { faction = "Alliance" } }, -- Booty Bay -> Aerie Peak
{ from = "TAXI_19", to = "TAXI_45", method = "flight", cost = 266, requirements = { faction = "Alliance" } }, -- Booty Bay -> Nethergarde Keep
{ from = "TAXI_19", to = "TAXI_66", method = "flight", cost = 712, requirements = { faction = "Alliance" } }, -- Booty Bay -> Chillwind Camp
{ from = "TAXI_19", to = "TAXI_67", method = "flight", cost = 769, requirements = { faction = "Alliance" } }, -- Booty Bay -> Light's Hope Chapel
{ from = "TAXI_19", to = "TAXI_71", method = "flight", cost = 291, requirements = { faction = "Alliance" } }, -- Booty Bay -> Morgan's Vigil
{ from = "TAXI_19", to = "TAXI_74", method = "flight", cost = 382, requirements = { faction = "Alliance" } }, -- Booty Bay -> Thorium Point
{ from = "TAXI_19", to = "TAXI_14", method = "flight", cost = 649, requirements = { faction = "Alliance" } }, -- Booty Bay -> Southshore
{ from = "TAXI_26", to = "TAXI_27", method = "flight", cost = 84, requirements = { faction = "Alliance" } }, -- Auberdine -> Rut'theran Village
{ from = "TAXI_26", to = "TAXI_28", method = "flight", cost = 176, requirements = { faction = "Alliance" } }, -- Auberdine -> Astranaar
{ from = "TAXI_26", to = "TAXI_32", method = "flight", cost = 675, requirements = { faction = "Alliance" } }, -- Auberdine -> Theramore
{ from = "TAXI_26", to = "TAXI_33", method = "flight", cost = 181, requirements = { faction = "Alliance" } }, -- Auberdine -> Stonetalon Peak
{ from = "TAXI_26", to = "TAXI_37", method = "flight", cost = 291, requirements = { faction = "Alliance" } }, -- Auberdine -> Nijel's Point
{ from = "TAXI_26", to = "TAXI_41", method = "flight", cost = 473, requirements = { faction = "Alliance" } }, -- Auberdine -> Feathermoon
{ from = "TAXI_26", to = "TAXI_49", method = "flight", cost = 151, requirements = { faction = "Alliance" } }, -- Auberdine -> Moonglade
{ from = "TAXI_26", to = "TAXI_52", method = "flight", cost = 281, requirements = { faction = "Alliance" } }, -- Auberdine -> Everlook
{ from = "TAXI_26", to = "TAXI_65", method = "flight", cost = 190, requirements = { faction = "Alliance" } }, -- Auberdine -> Talonbranch Glade
{ from = "TAXI_26", to = "TAXI_80", method = "flight", cost = 435, requirements = { faction = "Alliance" } }, -- Auberdine -> Ratchet
{ from = "TAXI_26", to = "TAXI_39", method = "flight", cost = 689, requirements = { faction = "Alliance" } }, -- Auberdine -> Gadgetzan
{ from = "TAXI_26", to = "TAXI_64", method = "flight", cost = 301, requirements = { faction = "Alliance" } }, -- Auberdine -> Talrendis Point
{ from = "TAXI_26", to = "TAXI_73", method = "flight", cost = 629, requirements = { faction = "Alliance" } }, -- Auberdine -> Cenarion Hold
{ from = "TAXI_27", to = "TAXI_26", method = "flight", cost = 86, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Auberdine
{ from = "TAXI_27", to = "TAXI_28", method = "flight", cost = 261, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Astranaar
{ from = "TAXI_27", to = "TAXI_31", method = "flight", cost = 711, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Thalanaar
{ from = "TAXI_27", to = "TAXI_32", method = "flight", cost = 617, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Theramore
{ from = "TAXI_27", to = "TAXI_33", method = "flight", cost = 267, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Stonetalon Peak
{ from = "TAXI_27", to = "TAXI_37", method = "flight", cost = 376, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Nijel's Point
{ from = "TAXI_27", to = "TAXI_39", method = "flight", cost = 774, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Gadgetzan
{ from = "TAXI_27", to = "TAXI_49", method = "flight", cost = 236, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Moonglade
{ from = "TAXI_27", to = "TAXI_52", method = "flight", cost = 365, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Everlook
{ from = "TAXI_27", to = "TAXI_65", method = "flight", cost = 274, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Talonbranch Glade
{ from = "TAXI_27", to = "TAXI_73", method = "flight", cost = 714, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Cenarion Hold
{ from = "TAXI_27", to = "TAXI_79", method = "flight", cost = 946, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Marshal's Refuge
{ from = "TAXI_27", to = "TAXI_80", method = "flight", cost = 520, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Ratchet
{ from = "TAXI_27", to = "TAXI_64", method = "flight", cost = 385, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Talrendis Point
{ from = "TAXI_28", to = "TAXI_26", method = "flight", cost = 148, requirements = { faction = "Alliance" } }, -- Astranaar -> Auberdine
{ from = "TAXI_28", to = "TAXI_27", method = "flight", cost = 231, requirements = { faction = "Alliance" } }, -- Astranaar -> Rut'theran Village
{ from = "TAXI_28", to = "TAXI_32", method = "flight", cost = 381, requirements = { faction = "Alliance" } }, -- Astranaar -> Theramore
{ from = "TAXI_28", to = "TAXI_33", method = "flight", cost = 153, requirements = { faction = "Alliance" } }, -- Astranaar -> Stonetalon Peak
{ from = "TAXI_28", to = "TAXI_37", method = "flight", cost = 279, requirements = { faction = "Alliance" } }, -- Astranaar -> Nijel's Point
{ from = "TAXI_28", to = "TAXI_41", method = "flight", cost = 511, requirements = { faction = "Alliance" } }, -- Astranaar -> Feathermoon
{ from = "TAXI_28", to = "TAXI_52", method = "flight", cost = 327, requirements = { faction = "Alliance" } }, -- Astranaar -> Everlook
{ from = "TAXI_28", to = "TAXI_65", method = "flight", cost = 337, requirements = { faction = "Alliance" } }, -- Astranaar -> Talonbranch Glade
{ from = "TAXI_28", to = "TAXI_80", method = "flight", cost = 931, requirements = { faction = "Alliance" } }, -- Astranaar -> Ratchet
{ from = "TAXI_28", to = "TAXI_64", method = "flight", cost = 150, requirements = { faction = "Alliance" } }, -- Astranaar -> Talrendis Point
{ from = "TAXI_31", to = "TAXI_32", method = "flight", cost = 159, requirements = { faction = "Alliance" } }, -- Thalanaar -> Theramore
{ from = "TAXI_31", to = "TAXI_39", method = "flight", cost = 171, requirements = { faction = "Alliance" } }, -- Thalanaar -> Gadgetzan
{ from = "TAXI_31", to = "TAXI_41", method = "flight", cost = 179, requirements = { faction = "Alliance" } }, -- Thalanaar -> Feathermoon
{ from = "TAXI_31", to = "TAXI_49", method = "flight", cost = 693, requirements = { faction = "Alliance" } }, -- Thalanaar -> Moonglade
{ from = "TAXI_31", to = "TAXI_73", method = "flight", cost = 334, requirements = { faction = "Alliance" } }, -- Thalanaar -> Cenarion Hold
{ from = "TAXI_31", to = "TAXI_79", method = "flight", cost = 274, requirements = { faction = "Alliance" } }, -- Thalanaar -> Marshal's Refuge
{ from = "TAXI_31", to = "TAXI_80", method = "flight", cost = 274, requirements = { faction = "Alliance" } }, -- Thalanaar -> Ratchet
{ from = "TAXI_31", to = "TAXI_27", method = "flight", cost = 729, requirements = { faction = "Alliance" } }, -- Thalanaar -> Rut'theran Village
{ from = "TAXI_31", to = "TAXI_28", method = "flight", cost = 545, requirements = { faction = "Alliance" } }, -- Thalanaar -> Astranaar
{ from = "TAXI_31", to = "TAXI_37", method = "flight", cost = 405, requirements = { faction = "Alliance" } }, -- Thalanaar -> Nijel's Point
{ from = "TAXI_31", to = "TAXI_64", method = "flight", cost = 393, requirements = { faction = "Alliance" } }, -- Thalanaar -> Talrendis Point
{ from = "TAXI_32", to = "TAXI_26", method = "flight", cost = 620, requirements = { faction = "Alliance" } }, -- Theramore -> Auberdine
{ from = "TAXI_32", to = "TAXI_27", method = "flight", cost = 619, requirements = { faction = "Alliance" } }, -- Theramore -> Rut'theran Village
{ from = "TAXI_32", to = "TAXI_28", method = "flight", cost = 606, requirements = { faction = "Alliance" } }, -- Theramore -> Astranaar
{ from = "TAXI_32", to = "TAXI_31", method = "flight", cost = 162, requirements = { faction = "Alliance" } }, -- Theramore -> Thalanaar
{ from = "TAXI_32", to = "TAXI_33", method = "flight", cost = 540, requirements = { faction = "Alliance" } }, -- Theramore -> Stonetalon Peak
{ from = "TAXI_32", to = "TAXI_37", method = "flight", cost = 334, requirements = { faction = "Alliance" } }, -- Theramore -> Nijel's Point
{ from = "TAXI_32", to = "TAXI_39", method = "flight", cost = 157, requirements = { faction = "Alliance" } }, -- Theramore -> Gadgetzan
{ from = "TAXI_32", to = "TAXI_41", method = "flight", cost = 341, requirements = { faction = "Alliance" } }, -- Theramore -> Feathermoon
{ from = "TAXI_32", to = "TAXI_52", method = "flight", cost = 414, requirements = { faction = "Alliance" } }, -- Theramore -> Everlook
{ from = "TAXI_32", to = "TAXI_79", method = "flight", cost = 261, requirements = { faction = "Alliance" } }, -- Theramore -> Marshal's Refuge
{ from = "TAXI_32", to = "TAXI_80", method = "flight", cost = 115, requirements = { faction = "Alliance" } }, -- Theramore -> Ratchet
{ from = "TAXI_32", to = "TAXI_49", method = "flight", cost = 535, requirements = { faction = "Alliance" } }, -- Theramore -> Moonglade
{ from = "TAXI_32", to = "TAXI_64", method = "flight", cost = 235, requirements = { faction = "Alliance" } }, -- Theramore -> Talrendis Point
{ from = "TAXI_32", to = "TAXI_65", method = "flight", cost = 518, requirements = { faction = "Alliance" } }, -- Theramore -> Talonbranch Glade
{ from = "TAXI_32", to = "TAXI_73", method = "flight", cost = 354, requirements = { faction = "Alliance" } }, -- Theramore -> Cenarion Hold
{ from = "TAXI_33", to = "TAXI_26", method = "flight", cost = 177, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Auberdine
{ from = "TAXI_33", to = "TAXI_28", method = "flight", cost = 154, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Astranaar
{ from = "TAXI_33", to = "TAXI_37", method = "flight", cost = 126, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Nijel's Point
{ from = "TAXI_33", to = "TAXI_27", method = "flight", cost = 261, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Rut'theran Village
{ from = "TAXI_33", to = "TAXI_31", method = "flight", cost = 700, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Thalanaar
{ from = "TAXI_33", to = "TAXI_32", method = "flight", cost = 434, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Theramore
{ from = "TAXI_33", to = "TAXI_79", method = "flight", cost = 597, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Marshal's Refuge
{ from = "TAXI_33", to = "TAXI_80", method = "flight", cost = 436, requirements = { faction = "Alliance" } }, -- Stonetalon Peak -> Ratchet
{ from = "TAXI_37", to = "TAXI_26", method = "flight", cost = 282, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Auberdine
{ from = "TAXI_37", to = "TAXI_27", method = "flight", cost = 367, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Rut'theran Village
{ from = "TAXI_37", to = "TAXI_28", method = "flight", cost = 273, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Astranaar
{ from = "TAXI_37", to = "TAXI_32", method = "flight", cost = 308, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Theramore
{ from = "TAXI_37", to = "TAXI_33", method = "flight", cost = 120, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Stonetalon Peak
{ from = "TAXI_37", to = "TAXI_39", method = "flight", cost = 464, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Gadgetzan
{ from = "TAXI_37", to = "TAXI_41", method = "flight", cost = 232, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Feathermoon
{ from = "TAXI_37", to = "TAXI_73", method = "flight", cost = 387, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Cenarion Hold
{ from = "TAXI_37", to = "TAXI_31", method = "flight", cost = 472, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Thalanaar
{ from = "TAXI_37", to = "TAXI_49", method = "flight", cost = 433, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Moonglade
{ from = "TAXI_37", to = "TAXI_64", method = "flight", cost = 421, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Talrendis Point
{ from = "TAXI_39", to = "TAXI_27", method = "flight", cost = 846, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Rut'theran Village
{ from = "TAXI_39", to = "TAXI_28", method = "flight", cost = 540, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Astranaar
{ from = "TAXI_39", to = "TAXI_31", method = "flight", cost = 177, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Thalanaar
{ from = "TAXI_39", to = "TAXI_32", method = "flight", cost = 154, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Theramore
{ from = "TAXI_39", to = "TAXI_33", method = "flight", cost = 692, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Stonetalon Peak
{ from = "TAXI_39", to = "TAXI_37", method = "flight", cost = 480, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Nijel's Point
{ from = "TAXI_39", to = "TAXI_41", method = "flight", cost = 712, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Feathermoon
{ from = "TAXI_39", to = "TAXI_52", method = "flight", cost = 566, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Everlook
{ from = "TAXI_39", to = "TAXI_65", method = "flight", cost = 670, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Talonbranch Glade
{ from = "TAXI_39", to = "TAXI_79", method = "flight", cost = 104, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Marshal's Refuge
{ from = "TAXI_39", to = "TAXI_80", method = "flight", cost = 262, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Ratchet
{ from = "TAXI_39", to = "TAXI_49", method = "flight", cost = 688, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Moonglade
{ from = "TAXI_39", to = "TAXI_64", method = "flight", cost = 388, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Talrendis Point
{ from = "TAXI_41", to = "TAXI_26", method = "flight", cost = 468, requirements = { faction = "Alliance" } }, -- Feathermoon -> Auberdine
{ from = "TAXI_41", to = "TAXI_27", method = "flight", cost = 551, requirements = { faction = "Alliance" } }, -- Feathermoon -> Rut'theran Village
{ from = "TAXI_41", to = "TAXI_28", method = "flight", cost = 645, requirements = { faction = "Alliance" } }, -- Feathermoon -> Astranaar
{ from = "TAXI_41", to = "TAXI_31", method = "flight", cost = 155, requirements = { faction = "Alliance" } }, -- Feathermoon -> Thalanaar
{ from = "TAXI_41", to = "TAXI_32", method = "flight", cost = 314, requirements = { faction = "Alliance" } }, -- Feathermoon -> Theramore
{ from = "TAXI_41", to = "TAXI_33", method = "flight", cost = 648, requirements = { faction = "Alliance" } }, -- Feathermoon -> Stonetalon Peak
{ from = "TAXI_41", to = "TAXI_37", method = "flight", cost = 227, requirements = { faction = "Alliance" } }, -- Feathermoon -> Nijel's Point
{ from = "TAXI_41", to = "TAXI_39", method = "flight", cost = 326, requirements = { faction = "Alliance" } }, -- Feathermoon -> Gadgetzan
{ from = "TAXI_41", to = "TAXI_52", method = "flight", cost = 748, requirements = { faction = "Alliance" } }, -- Feathermoon -> Everlook
{ from = "TAXI_41", to = "TAXI_73", method = "flight", cost = 159, requirements = { faction = "Alliance" } }, -- Feathermoon -> Cenarion Hold
{ from = "TAXI_41", to = "TAXI_80", method = "flight", cost = 429, requirements = { faction = "Alliance" } }, -- Feathermoon -> Ratchet
{ from = "TAXI_41", to = "TAXI_49", method = "flight", cost = 619, requirements = { faction = "Alliance" } }, -- Feathermoon -> Moonglade
{ from = "TAXI_43", to = "TAXI_2", method = "flight", cost = 429, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Stormwind
{ from = "TAXI_43", to = "TAXI_4", method = "flight", cost = 492, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Sentinel Hill
{ from = "TAXI_43", to = "TAXI_5", method = "flight", cost = 527, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Lakeshire
{ from = "TAXI_43", to = "TAXI_6", method = "flight", cost = 256, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Ironforge
{ from = "TAXI_43", to = "TAXI_7", method = "flight", cost = 176, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Menethil Harbor
{ from = "TAXI_43", to = "TAXI_8", method = "flight", cost = 245, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Thelsamar
{ from = "TAXI_43", to = "TAXI_12", method = "flight", cost = 531, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Darkshire
{ from = "TAXI_43", to = "TAXI_19", method = "flight", cost = 658, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Booty Bay
{ from = "TAXI_43", to = "TAXI_66", method = "flight", cost = 54, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Chillwind Camp
{ from = "TAXI_43", to = "TAXI_67", method = "flight", cost = 164, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Light's Hope Chapel
{ from = "TAXI_43", to = "TAXI_74", method = "flight", cost = 303, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Thorium Point
{ from = "TAXI_43", to = "TAXI_14", method = "flight", cost = 68, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Southshore
{ from = "TAXI_45", to = "TAXI_2", method = "flight", cost = 189, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Stormwind
{ from = "TAXI_45", to = "TAXI_4", method = "flight", cost = 183, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Sentinel Hill
{ from = "TAXI_45", to = "TAXI_6", method = "flight", cost = 382, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Ironforge
{ from = "TAXI_45", to = "TAXI_7", method = "flight", cost = 467, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Menethil Harbor
{ from = "TAXI_45", to = "TAXI_8", method = "flight", cost = 482, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Thelsamar
{ from = "TAXI_45", to = "TAXI_12", method = "flight", cost = 91, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Darkshire
{ from = "TAXI_45", to = "TAXI_19", method = "flight", cost = 260, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Booty Bay
{ from = "TAXI_45", to = "TAXI_43", method = "flight", cost = 673, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Aerie Peak
{ from = "TAXI_45", to = "TAXI_66", method = "flight", cost = 631, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Chillwind Camp
{ from = "TAXI_45", to = "TAXI_67", method = "flight", cost = 687, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Light's Hope Chapel
{ from = "TAXI_45", to = "TAXI_71", method = "flight", cost = 207, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Morgan's Vigil
{ from = "TAXI_45", to = "TAXI_74", method = "flight", cost = 455, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Thorium Point
{ from = "TAXI_49", to = "TAXI_26", method = "flight", cost = 142, requirements = { faction = "Alliance" } }, -- Moonglade -> Auberdine
{ from = "TAXI_49", to = "TAXI_27", method = "flight", cost = 226, requirements = { faction = "Alliance" } }, -- Moonglade -> Rut'theran Village
{ from = "TAXI_49", to = "TAXI_28", method = "flight", cost = 318, requirements = { faction = "Alliance" } }, -- Moonglade -> Astranaar
{ from = "TAXI_49", to = "TAXI_32", method = "flight", cost = 537, requirements = { faction = "Alliance" } }, -- Moonglade -> Theramore
{ from = "TAXI_49", to = "TAXI_37", method = "flight", cost = 433, requirements = { faction = "Alliance" } }, -- Moonglade -> Nijel's Point
{ from = "TAXI_49", to = "TAXI_39", method = "flight", cost = 896, requirements = { faction = "Alliance" } }, -- Moonglade -> Gadgetzan
{ from = "TAXI_49", to = "TAXI_41", method = "flight", cost = 614, requirements = { faction = "Alliance" } }, -- Moonglade -> Feathermoon
{ from = "TAXI_49", to = "TAXI_52", method = "flight", cost = 131, requirements = { faction = "Alliance" } }, -- Moonglade -> Everlook
{ from = "TAXI_49", to = "TAXI_65", method = "flight", cost = 61, requirements = { faction = "Alliance" } }, -- Moonglade -> Talonbranch Glade
{ from = "TAXI_49", to = "TAXI_73", method = "flight", cost = 771, requirements = { faction = "Alliance" } }, -- Moonglade -> Cenarion Hold
{ from = "TAXI_49", to = "TAXI_79", method = "flight", cost = 798, requirements = { faction = "Alliance" } }, -- Moonglade -> Marshal's Refuge
{ from = "TAXI_49", to = "TAXI_80", method = "flight", cost = 854, requirements = { faction = "Alliance" } }, -- Moonglade -> Ratchet
{ from = "TAXI_49", to = "TAXI_31", method = "flight", cost = 701, requirements = { faction = "Alliance" } }, -- Moonglade -> Thalanaar
{ from = "TAXI_49", to = "TAXI_33", method = "flight", cost = 323, requirements = { faction = "Alliance" } }, -- Moonglade -> Stonetalon Peak
{ from = "TAXI_49", to = "TAXI_64", method = "flight", cost = 305, requirements = { faction = "Alliance" } }, -- Moonglade -> Talrendis Point
{ from = "TAXI_52", to = "TAXI_26", method = "flight", cost = 262, requirements = { faction = "Alliance" } }, -- Everlook -> Auberdine
{ from = "TAXI_52", to = "TAXI_27", method = "flight", cost = 346, requirements = { faction = "Alliance" } }, -- Everlook -> Rut'theran Village
{ from = "TAXI_52", to = "TAXI_28", method = "flight", cost = 327, requirements = { faction = "Alliance" } }, -- Everlook -> Astranaar
{ from = "TAXI_52", to = "TAXI_32", method = "flight", cost = 408, requirements = { faction = "Alliance" } }, -- Everlook -> Theramore
{ from = "TAXI_52", to = "TAXI_37", method = "flight", cost = 553, requirements = { faction = "Alliance" } }, -- Everlook -> Nijel's Point
{ from = "TAXI_52", to = "TAXI_39", method = "flight", cost = 564, requirements = { faction = "Alliance" } }, -- Everlook -> Gadgetzan
{ from = "TAXI_52", to = "TAXI_41", method = "flight", cost = 734, requirements = { faction = "Alliance" } }, -- Everlook -> Feathermoon
{ from = "TAXI_52", to = "TAXI_49", method = "flight", cost = 122, requirements = { faction = "Alliance" } }, -- Everlook -> Moonglade
{ from = "TAXI_52", to = "TAXI_65", method = "flight", cost = 122, requirements = { faction = "Alliance" } }, -- Everlook -> Talonbranch Glade
{ from = "TAXI_52", to = "TAXI_73", method = "flight", cost = 762, requirements = { faction = "Alliance" } }, -- Everlook -> Cenarion Hold
{ from = "TAXI_52", to = "TAXI_79", method = "flight", cost = 668, requirements = { faction = "Alliance" } }, -- Everlook -> Marshal's Refuge
{ from = "TAXI_52", to = "TAXI_80", method = "flight", cost = 309, requirements = { faction = "Alliance" } }, -- Everlook -> Ratchet
{ from = "TAXI_52", to = "TAXI_31", method = "flight", cost = 572, requirements = { faction = "Alliance" } }, -- Everlook -> Thalanaar
{ from = "TAXI_52", to = "TAXI_64", method = "flight", cost = 176, requirements = { faction = "Alliance" } }, -- Everlook -> Talrendis Point
{ from = "TAXI_64", to = "TAXI_26", method = "flight", cost = 301, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Auberdine
{ from = "TAXI_64", to = "TAXI_27", method = "flight", cost = 384, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Rut'theran Village
{ from = "TAXI_64", to = "TAXI_28", method = "flight", cost = 153, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Astranaar
{ from = "TAXI_64", to = "TAXI_32", method = "flight", cost = 241, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Theramore
{ from = "TAXI_64", to = "TAXI_37", method = "flight", cost = 432, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Nijel's Point
{ from = "TAXI_64", to = "TAXI_39", method = "flight", cost = 391, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Gadgetzan
{ from = "TAXI_64", to = "TAXI_41", method = "flight", cost = 574, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Feathermoon
{ from = "TAXI_64", to = "TAXI_49", method = "flight", cost = 301, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Moonglade
{ from = "TAXI_64", to = "TAXI_52", method = "flight", cost = 178, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Everlook
{ from = "TAXI_64", to = "TAXI_65", method = "flight", cost = 283, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Talonbranch Glade
{ from = "TAXI_64", to = "TAXI_73", method = "flight", cost = 588, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Cenarion Hold
{ from = "TAXI_64", to = "TAXI_79", method = "flight", cost = 494, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Marshal's Refuge
{ from = "TAXI_64", to = "TAXI_80", method = "flight", cost = 135, requirements = { faction = "Alliance" } }, -- Talrendis Point -> Ratchet
{ from = "TAXI_65", to = "TAXI_26", method = "flight", cost = 188, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Auberdine
{ from = "TAXI_65", to = "TAXI_27", method = "flight", cost = 272, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Rut'theran Village
{ from = "TAXI_65", to = "TAXI_28", method = "flight", cost = 363, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Astranaar
{ from = "TAXI_65", to = "TAXI_32", method = "flight", cost = 515, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Theramore
{ from = "TAXI_65", to = "TAXI_37", method = "flight", cost = 478, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Nijel's Point
{ from = "TAXI_65", to = "TAXI_39", method = "flight", cost = 671, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Gadgetzan
{ from = "TAXI_65", to = "TAXI_41", method = "flight", cost = 660, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Feathermoon
{ from = "TAXI_65", to = "TAXI_52", method = "flight", cost = 121, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Everlook
{ from = "TAXI_65", to = "TAXI_73", method = "flight", cost = 817, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Cenarion Hold
{ from = "TAXI_65", to = "TAXI_79", method = "flight", cost = 776, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Marshal's Refuge
{ from = "TAXI_65", to = "TAXI_80", method = "flight", cost = 417, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Ratchet
{ from = "TAXI_65", to = "TAXI_31", method = "flight", cost = 678, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Thalanaar
{ from = "TAXI_65", to = "TAXI_64", method = "flight", cost = 282, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Talrendis Point
{ from = "TAXI_66", to = "TAXI_2", method = "flight", cost = 432, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Stormwind
{ from = "TAXI_66", to = "TAXI_4", method = "flight", cost = 495, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Sentinel Hill
{ from = "TAXI_66", to = "TAXI_5", method = "flight", cost = 423, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Lakeshire
{ from = "TAXI_66", to = "TAXI_6", method = "flight", cost = 261, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Ironforge
{ from = "TAXI_66", to = "TAXI_7", method = "flight", cost = 193, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Menethil Harbor
{ from = "TAXI_66", to = "TAXI_8", method = "flight", cost = 308, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Thelsamar
{ from = "TAXI_66", to = "TAXI_12", method = "flight", cost = 481, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Darkshire
{ from = "TAXI_66", to = "TAXI_19", method = "flight", cost = 662, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Booty Bay
{ from = "TAXI_66", to = "TAXI_43", method = "flight", cost = 66, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Aerie Peak
{ from = "TAXI_66", to = "TAXI_45", method = "flight", cost = 595, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Nethergarde Keep
{ from = "TAXI_66", to = "TAXI_67", method = "flight", cost = 147, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Light's Hope Chapel
{ from = "TAXI_66", to = "TAXI_71", method = "flight", cost = 395, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Morgan's Vigil
{ from = "TAXI_66", to = "TAXI_74", method = "flight", cost = 309, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Thorium Point
{ from = "TAXI_66", to = "TAXI_14", method = "flight", cost = 85, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Southshore
{ from = "TAXI_67", to = "TAXI_12", method = "flight", cost = 591, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Darkshire
{ from = "TAXI_67", to = "TAXI_16", method = "flight", cost = 233, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Refuge Pointe
{ from = "TAXI_67", to = "TAXI_19", method = "flight", cost = 770, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Booty Bay
{ from = "TAXI_67", to = "TAXI_43", method = "flight", cost = 163, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Aerie Peak
{ from = "TAXI_67", to = "TAXI_45", method = "flight", cost = 704, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Nethergarde Keep
{ from = "TAXI_67", to = "TAXI_66", method = "flight", cost = 150, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Chillwind Camp
{ from = "TAXI_67", to = "TAXI_71", method = "flight", cost = 503, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Morgan's Vigil
{ from = "TAXI_67", to = "TAXI_74", method = "flight", cost = 417, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Thorium Point
{ from = "TAXI_67", to = "TAXI_2", method = "flight", cost = 540, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Stormwind
{ from = "TAXI_67", to = "TAXI_4", method = "flight", cost = 604, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Sentinel Hill
{ from = "TAXI_67", to = "TAXI_6", method = "flight", cost = 369, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Ironforge
{ from = "TAXI_67", to = "TAXI_7", method = "flight", cost = 333, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Menethil Harbor
{ from = "TAXI_67", to = "TAXI_14", method = "flight", cost = 226, requirements = { faction = "Alliance" } }, -- Light's Hope Chapel -> Southshore
{ from = "TAXI_71", to = "TAXI_2", method = "flight", cost = 151, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Stormwind
{ from = "TAXI_71", to = "TAXI_5", method = "flight", cost = 64, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Lakeshire
{ from = "TAXI_71", to = "TAXI_6", method = "flight", cost = 396, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Ironforge
{ from = "TAXI_71", to = "TAXI_7", method = "flight", cost = 270, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Menethil Harbor
{ from = "TAXI_71", to = "TAXI_8", method = "flight", cost = 245, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Thelsamar
{ from = "TAXI_71", to = "TAXI_12", method = "flight", cost = 121, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Darkshire
{ from = "TAXI_71", to = "TAXI_16", method = "flight", cost = 378, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Refuge Pointe
{ from = "TAXI_71", to = "TAXI_19", method = "flight", cost = 288, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Booty Bay
{ from = "TAXI_71", to = "TAXI_43", method = "flight", cost = 436, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Aerie Peak
{ from = "TAXI_71", to = "TAXI_45", method = "flight", cost = 210, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Nethergarde Keep
{ from = "TAXI_71", to = "TAXI_66", method = "flight", cost = 435, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Chillwind Camp
{ from = "TAXI_71", to = "TAXI_67", method = "flight", cost = 491, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Light's Hope Chapel
{ from = "TAXI_71", to = "TAXI_74", method = "flight", cost = 104, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Thorium Point
{ from = "TAXI_71", to = "TAXI_14", method = "flight", cost = 371, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Southshore
{ from = "TAXI_73", to = "TAXI_27", method = "flight", cost = 726, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Rut'theran Village
{ from = "TAXI_73", to = "TAXI_31", method = "flight", cost = 329, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Thalanaar
{ from = "TAXI_73", to = "TAXI_39", method = "flight", cost = 189, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Gadgetzan
{ from = "TAXI_73", to = "TAXI_41", method = "flight", cost = 175, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Feathermoon
{ from = "TAXI_73", to = "TAXI_49", method = "flight", cost = 792, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Moonglade
{ from = "TAXI_73", to = "TAXI_52", method = "flight", cost = 755, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Everlook
{ from = "TAXI_73", to = "TAXI_65", method = "flight", cost = 831, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Talonbranch Glade
{ from = "TAXI_73", to = "TAXI_79", method = "flight", cost = 92, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Marshal's Refuge
{ from = "TAXI_73", to = "TAXI_80", method = "flight", cost = 450, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Ratchet
{ from = "TAXI_73", to = "TAXI_32", method = "flight", cost = 342, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Theramore
{ from = "TAXI_73", to = "TAXI_33", method = "flight", cost = 521, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Stonetalon Peak
{ from = "TAXI_73", to = "TAXI_64", method = "flight", cost = 576, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Talrendis Point
{ from = "TAXI_74", to = "TAXI_2", method = "flight", cost = 220, requirements = { faction = "Alliance" } }, -- Thorium Point -> Stormwind
{ from = "TAXI_74", to = "TAXI_6", method = "flight", cost = 94, requirements = { faction = "Alliance" } }, -- Thorium Point -> Ironforge
{ from = "TAXI_74", to = "TAXI_7", method = "flight", cost = 178, requirements = { faction = "Alliance" } }, -- Thorium Point -> Menethil Harbor
{ from = "TAXI_74", to = "TAXI_8", method = "flight", cost = 152, requirements = { faction = "Alliance" } }, -- Thorium Point -> Thelsamar
{ from = "TAXI_74", to = "TAXI_12", method = "flight", cost = 183, requirements = { faction = "Alliance" } }, -- Thorium Point -> Darkshire
{ from = "TAXI_74", to = "TAXI_19", method = "flight", cost = 350, requirements = { faction = "Alliance" } }, -- Thorium Point -> Booty Bay
{ from = "TAXI_74", to = "TAXI_43", method = "flight", cost = 343, requirements = { faction = "Alliance" } }, -- Thorium Point -> Aerie Peak
{ from = "TAXI_74", to = "TAXI_45", method = "flight", cost = 265, requirements = { faction = "Alliance" } }, -- Thorium Point -> Nethergarde Keep
{ from = "TAXI_74", to = "TAXI_66", method = "flight", cost = 342, requirements = { faction = "Alliance" } }, -- Thorium Point -> Chillwind Camp
{ from = "TAXI_74", to = "TAXI_67", method = "flight", cost = 398, requirements = { faction = "Alliance" } }, -- Thorium Point -> Light's Hope Chapel
{ from = "TAXI_74", to = "TAXI_71", method = "flight", cost = 96, requirements = { faction = "Alliance" } }, -- Thorium Point -> Morgan's Vigil
{ from = "TAXI_74", to = "TAXI_14", method = "flight", cost = 279, requirements = { faction = "Alliance" } }, -- Thorium Point -> Southshore
{ from = "TAXI_79", to = "TAXI_27", method = "flight", cost = 875, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Rut'theran Village
{ from = "TAXI_79", to = "TAXI_28", method = "flight", cost = 856, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Astranaar
{ from = "TAXI_79", to = "TAXI_32", method = "flight", cost = 257, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Theramore
{ from = "TAXI_79", to = "TAXI_39", method = "flight", cost = 104, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Gadgetzan
{ from = "TAXI_79", to = "TAXI_41", method = "flight", cost = 458, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Feathermoon
{ from = "TAXI_79", to = "TAXI_52", method = "flight", cost = 670, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Everlook
{ from = "TAXI_79", to = "TAXI_65", method = "flight", cost = 774, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Talonbranch Glade
{ from = "TAXI_79", to = "TAXI_73", method = "flight", cost = 94, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Cenarion Hold
{ from = "TAXI_79", to = "TAXI_80", method = "flight", cost = 364, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Ratchet
{ from = "TAXI_79", to = "TAXI_31", method = "flight", cost = 280, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Thalanaar
{ from = "TAXI_79", to = "TAXI_37", method = "flight", cost = 485, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Nijel's Point
{ from = "TAXI_79", to = "TAXI_64", method = "flight", cost = 492, requirements = { faction = "Alliance" } }, -- Marshal's Refuge -> Talrendis Point
{ from = "TAXI_80", to = "TAXI_27", method = "flight", cost = 516, requirements = { faction = "Alliance" } }, -- Ratchet -> Rut'theran Village
{ from = "TAXI_80", to = "TAXI_28", method = "flight", cost = 284, requirements = { faction = "Alliance" } }, -- Ratchet -> Astranaar
{ from = "TAXI_80", to = "TAXI_31", method = "flight", cost = 268, requirements = { faction = "Alliance" } }, -- Ratchet -> Thalanaar
{ from = "TAXI_80", to = "TAXI_32", method = "flight", cost = 106, requirements = { faction = "Alliance" } }, -- Ratchet -> Theramore
{ from = "TAXI_80", to = "TAXI_39", method = "flight", cost = 261, requirements = { faction = "Alliance" } }, -- Ratchet -> Gadgetzan
{ from = "TAXI_80", to = "TAXI_41", method = "flight", cost = 446, requirements = { faction = "Alliance" } }, -- Ratchet -> Feathermoon
{ from = "TAXI_80", to = "TAXI_49", method = "flight", cost = 432, requirements = { faction = "Alliance" } }, -- Ratchet -> Moonglade
{ from = "TAXI_80", to = "TAXI_52", method = "flight", cost = 310, requirements = { faction = "Alliance" } }, -- Ratchet -> Everlook
{ from = "TAXI_80", to = "TAXI_65", method = "flight", cost = 415, requirements = { faction = "Alliance" } }, -- Ratchet -> Talonbranch Glade
{ from = "TAXI_80", to = "TAXI_73", method = "flight", cost = 459, requirements = { faction = "Alliance" } }, -- Ratchet -> Cenarion Hold
{ from = "TAXI_80", to = "TAXI_79", method = "flight", cost = 366, requirements = { faction = "Alliance" } }, -- Ratchet -> Marshal's Refuge
{ from = "TAXI_80", to = "TAXI_33", method = "flight", cost = 437, requirements = { faction = "Alliance" } }, -- Ratchet -> Stonetalon Peak
{ from = "TAXI_80", to = "TAXI_64", method = "flight", cost = 132, requirements = { faction = "Alliance" } }, -- Ratchet -> Talrendis Point

-- The last 54 lines were missing from the first extraction and were added from the InFlight table.
{ from = "TAXI_2", to = "TAXI_5", method = "flight", cost = 113, requirements = { faction = "Alliance" } }, -- Stormwind -> Lakeshire
{ from = "TAXI_2", to = "TAXI_12", method = "flight", cost = 116, requirements = { faction = "Alliance" } }, -- Stormwind -> Darkshire
{ from = "TAXI_2", to = "TAXI_45", method = "flight", cost = 176, requirements = { faction = "Alliance" } }, -- Stormwind -> Nethergarde Keep
{ from = "TAXI_6", to = "TAXI_2", method = "flight", cost = 210, requirements = { faction = "Alliance" } }, -- Ironforge -> Stormwind
{ from = "TAXI_6", to = "TAXI_8", method = "flight", cost = 101, requirements = { faction = "Alliance" } }, -- Ironforge -> Thelsamar
{ from = "TAXI_7", to = "TAXI_6", method = "flight", cost = 89, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Ironforge
{ from = "TAXI_7", to = "TAXI_8", method = "flight", cost = 163, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Thelsamar
{ from = "TAXI_7", to = "TAXI_16", method = "flight", cost = 113, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Refuge Pointe
{ from = "TAXI_7", to = "TAXI_66", method = "flight", cost = 186, requirements = { faction = "Alliance" } }, -- Menethil Harbor -> Chillwind Camp
{ from = "TAXI_8", to = "TAXI_6", method = "flight", cost = 109, requirements = { faction = "Alliance" } }, -- Thelsamar -> Ironforge
{ from = "TAXI_8", to = "TAXI_7", method = "flight", cost = 153, requirements = { faction = "Alliance" } }, -- Thelsamar -> Menethil Harbor
{ from = "TAXI_8", to = "TAXI_16", method = "flight", cost = 164, requirements = { faction = "Alliance" } }, -- Thelsamar -> Refuge Pointe
{ from = "TAXI_8", to = "TAXI_43", method = "flight", cost = 234, requirements = { faction = "Alliance" } }, -- Thelsamar -> Aerie Peak
{ from = "TAXI_12", to = "TAXI_2", method = "flight", cost = 88, requirements = { faction = "Alliance" } }, -- Darkshire -> Stormwind
{ from = "TAXI_12", to = "TAXI_5", method = "flight", cost = 60, requirements = { faction = "Alliance" } }, -- Darkshire -> Lakeshire
{ from = "TAXI_12", to = "TAXI_45", method = "flight", cost = 97, requirements = { faction = "Alliance" } }, -- Darkshire -> Nethergarde Keep
{ from = "TAXI_16", to = "TAXI_7", method = "flight", cost = 126, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Menethil Harbor
{ from = "TAXI_16", to = "TAXI_8", method = "flight", cost = 171, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Thelsamar
{ from = "TAXI_16", to = "TAXI_66", method = "flight", cost = 122, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Chillwind Camp
{ from = "TAXI_16", to = "TAXI_67", method = "flight", cost = 233, requirements = { faction = "Alliance" } }, -- Refuge Pointe -> Light's Hope Chapel
{ from = "TAXI_27", to = "TAXI_41", method = "flight", cost = 557, requirements = { faction = "Alliance" } }, -- Rut'theran Village -> Feathermoon
{ from = "TAXI_37", to = "TAXI_80", method = "flight", cost = 422, requirements = { faction = "Alliance" } }, -- Nijel's Point -> Ratchet
{ from = "TAXI_39", to = "TAXI_73", method = "flight", cost = 197, requirements = { faction = "Alliance" } }, -- Gadgetzan -> Cenarion Hold
{ from = "TAXI_43", to = "TAXI_16", method = "flight", cost = 75, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Refuge Pointe
{ from = "TAXI_43", to = "TAXI_45", method = "flight", cost = 591, requirements = { faction = "Alliance" } }, -- Aerie Peak -> Nethergarde Keep
{ from = "TAXI_45", to = "TAXI_5", method = "flight", cost = 150, requirements = { faction = "Alliance" } }, -- Nethergarde Keep -> Lakeshire
{ from = "TAXI_65", to = "TAXI_49", method = "flight", cost = 67, requirements = { faction = "Alliance" } }, -- Talonbranch Glade -> Moonglade, Alliance flight master
{ from = "TAXI_66", to = "TAXI_16", method = "flight", cost = 138, requirements = { faction = "Alliance" } }, -- Chillwind Camp -> Refuge Pointe
{ from = "TAXI_71", to = "TAXI_4", method = "flight", cost = 195, requirements = { faction = "Alliance" } }, -- Morgan's Vigil -> Sentinel Hill
{ from = "TAXI_73", to = "TAXI_37", method = "flight", cost = 402, requirements = { faction = "Alliance" } }, -- Cenarion Hold -> Nijel's Point
{ from = "TAXI_80", to = "TAXI_37", method = "flight", cost = 439, requirements = { faction = "Alliance" } }, -- Ratchet -> Nijel's Point
{ from = "TAXI_10", to = "TAXI_11", method = "flight", cost = 112, requirements = { faction = "Horde" } }, -- The Sepulcher -> Undercity
{ from = "TAXI_11", to = "TAXI_13", method = "flight", cost = 141, requirements = { faction = "Horde" } }, -- Undercity -> Tarren Mill
{ from = "TAXI_11", to = "TAXI_75", method = "flight", cost = 543, requirements = { faction = "Horde" } }, -- Undercity -> Thorium Point
{ from = "TAXI_22", to = "TAXI_38", method = "flight", cost = 159, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Shadowprey Village
{ from = "TAXI_22", to = "TAXI_40", method = "flight", cost = 290, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Gadgetzan
{ from = "TAXI_22", to = "TAXI_42", method = "flight", cost = 252, requirements = { faction = "Horde" } }, -- Thunder Bluff -> Camp Mojache
{ from = "TAXI_25", to = "TAXI_80", method = "flight", cost = 52, requirements = { faction = "Horde" } }, -- Crossroads -> Ratchet
{ from = "TAXI_29", to = "TAXI_25", method = "flight", cost = 150, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Crossroads
{ from = "TAXI_29", to = "TAXI_40", method = "flight", cost = 426, requirements = { faction = "Horde" } }, -- Sun Rock Retreat -> Gadgetzan
{ from = "TAXI_38", to = "TAXI_29", method = "flight", cost = 199, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Sun Rock Retreat
{ from = "TAXI_38", to = "TAXI_42", method = "flight", cost = 196, requirements = { faction = "Horde" } }, -- Shadowprey Village -> Camp Mojache
{ from = "TAXI_40", to = "TAXI_22", method = "flight", cost = 304, requirements = { faction = "Horde" } }, -- Gadgetzan -> Thunder Bluff
{ from = "TAXI_42", to = "TAXI_22", method = "flight", cost = 259, requirements = { faction = "Horde" } }, -- Camp Mojache -> Thunder Bluff
{ from = "TAXI_42", to = "TAXI_38", method = "flight", cost = 201, requirements = { faction = "Horde" } }, -- Camp Mojache -> Shadowprey Village
{ from = "TAXI_44", to = "TAXI_29", method = "flight", cost = 322, requirements = { faction = "Horde" } }, -- Valormok -> Sun Rock Retreat
{ from = "TAXI_53", to = "TAXI_61", method = "flight", cost = 228, requirements = { faction = "Horde" } }, -- Everlook -> Splintertree Post
{ from = "TAXI_55", to = "TAXI_25", method = "flight", cost = 162, requirements = { faction = "Horde" } }, -- Brackenwall Village -> Crossroads
{ from = "TAXI_61", to = "TAXI_25", method = "flight", cost = 160, requirements = { faction = "Horde" } }, -- Splintertree Post -> Crossroads
{ from = "TAXI_69", to = "TAXI_25", method = "flight", cost = 353, requirements = { faction = "Horde" } }, -- Moonglade, Horde flight master -> Crossroads
{ from = "TAXI_69", to = "TAXI_42", method = "flight", cost = 604, requirements = { faction = "Horde" } }, -- Moonglade, Horde flight master -> Camp Mojache
{ from = "TAXI_69", to = "TAXI_80", method = "flight", cost = 404, requirements = { faction = "Horde" } }, -- Moonglade, Horde flight master -> Ratchet
{ from = "TAXI_79", to = "TAXI_22", method = "flight", cost = 416, requirements = { faction = "Horde" } }, -- Marshal's Refuge -> Thunder Bluff
{ from = "TAXI_80", to = "TAXI_29", method = "flight", cost = 218, requirements = { faction = "Horde" } }, -- Ratchet -> Sun Rock Retreat
