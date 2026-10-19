# Changelog

## Unreleased (Retail)

### Added
- Deepholm's Temple of Earth candy bucket on the Eastern Kingdoms Hallow's End route.

### Fixed
- Teleport: Undercity lands by Zidormi in present Tirisfal, so routes into Undercity now include talking to her.
- Deepholm's portal to Orgrimmar lands in the portal room, not at the Earthshrine.
- Teleport: Stonard was thought to land in Azshara, so routes after it had no arrow or map lines.
- Zephyr's port from Shattrath to the Caverns of Time is only used at Revered with the Keepers of Time.

## 2.0.2 (Retail)

### Fixed
- Multi-stop routes (and round trips) could use two dungeon teleports, but they share one cooldown: now a trip uses one at most.
- The Abundant Beacon takes you to Loaknit Den in Zul'Aman; routes thought it landed in Harandar.

## 2.0.1 (Retail)

### Added
- **Tricks and Treats of Midnight:** a Hallow's End route through Midnight's 15 candy buckets, with Slayer's Rise for your faction.
- **Holiday Routes skip the candy buckets you've already done this year,** so you can stop partway and pick the route up later.
- Hallow's End routes are drawn in orange on the map, with pumpkin pails for stops.
- **An About page** on the settings page, with the Discord link.

### Changed
- Hallow's End routes only visit the buckets the Tricks and Treats achievements need: Dragonmaw Port, Theramore Isle and Stonetalon Peak are gone.

### Fixed
- Stormwind's Mage Tower: routes out of the portal room now go down the stairwell and out of the tower's door, and the navigator waits until you're at the door.

## 0.8.2

### Added
- **More ley lines and convergences:** 4 more ley lines and 21 more convergences, 81 ley lines and 76 convergences in all.
- **The flight map marks where you're flying to:** a pulsing ring round the flight point your route takes.
- **An About page** on the settings page, with the Discord link.
- Ley line sharing takes in Skyborne Compass's "not there any more" reports, so routes skip a node someone found gone. Sightings now last 90 minutes.

### Fixed
- Minimap detection of ley lines stopped working when the game renamed the minimap's "Ley Line" dot to "Leyline". It finds both now.
- The minimap button no longer shows its ring when another addon gathers it off the minimap.
- "You're already here" only shows for a few seconds of walking or flying, not for a quick trip by teleport.

## 2.0.0 (Retail)

Mapzeroth has been rebuilt from the ground up, on the same engine as Mapzeroth for WoW: Forever. If you've tried it in the Forever Beta, it'll be very familiar.

All settings are back to their defaults, so make any changes you need after you load in. Favourites from 1.x don't carry over. Mapzeroth reads where your hearthstone is bound from the game. If your routes don't use your hearthstone when you think it should, bind it again at your inn and it'll know exactly where it leads.

### Added
- **Multi-stop routes.** Paste `/way` lines, or use your existing TomTom waypoints, and it plans the quickest order through every stop. The navigator takes you through them one stop at a time. The routing algorithm has been greatly improved since its initial release.
- **Holiday Routes.** Ready-made routes that show up while a holiday is on. Hallow's End's candy buckets are first, split by continent and faction. More updates to this before this year's event (hopefully)
- **Saved routes.** Save a route under a name, then edit its stops or delete it later. The pet battle tamer routes come ready-saved as samples which I was using for testing, you can delete them if they're not useful.
- **The route on your map and minimap:** dotted lines on foot, dashed for flights, and a ring with an arrow where a teleport leaves and lands.
- **A new navigator** with an arrow pointing to your next step, a Cast / Use button showing the spell or item's icon, and a Recalculate button. Shortcuts (should) count: cut across a field and it moves on to the next step.
- **Zidormi phases.** Routes (should) know which time phase you're in for Darkshore, Blasted Lands, Tirisfal, Uldum, Dustwallow, Silithus and the Vale of Eternal Blossoms, and use Zidormi when the other one is quicker.
- **Teleport gear.** Cloaks, tabards, rings and other wearable teleports have their own steps to equip and use, including buttons to do so on the navigator.
- **Hearthstone to your inn**, and Vulpera's Return to Camp to wherever you last made camp.
- **Themes:** Classic, Modern Dark and Cartographer. Potentially more to follow based on feedback.
- **Shift-click a place in the picker to share it in chat** with the game's own map pin.
- **Addon compartment.** With the minimap button hidden, Mapzeroth is listed in the minimap's addon menu.
- Starter translations for German, Spanish, French, Italian, Korean, Portuguese, Russian and Chinese.

### Changed
- **The picker** leads with the current expansion, the capital cities and this season's dungeons. Everything else sits under "Older content", by expansion.
- Flight masters are only used where you can't fly yourself, such as between Oribos and other zones in Shadowlands.

## 0.8.1

### Added
- **Detect nodes on the minimap** (Skyborne, while sharing sightings). Mapzeroth finds ley line and elemental convergence dots on your minimap without you pointing at them, and shares them like a sighting from your racial. It works with a rotating or square minimap, and never runs in combat, in instances, or while your mouse is on the minimap. On by default; turn it off on the settings page. If you use Skyborne Ley Line & Convergence Marker, it does this instead.
- **More ley lines and convergences:** 12 more of each, 76 ley lines and 56 convergences in all.

### Changed
- "How it works" now sits under the sharing setting's title, since it covers both sharing settings.

### Fixed
- Ley line sharing could take chat channel /1 when it joined before the game's channels, pushing General and Trade to /2 and /3. General, Trade and your own chat channels now keep their numbers.

## 0.8.0

### Added
- **Shortcuts count.** The navigator moves on to the next step as soon as you're closer to where it goes next than the current step's end is. That includes cutting across a field instead of following the road, or jumping off a boat before it docks. A walk to a zone border also counts as done once you're in the next zone, however you crossed (swimming a river instead of taking the bridge, say).
- **Recalculate button** on the navigator. Plans the rest of the trip again from where you are, keeping the remaining stops of a multi-stop route and the way back of a round trip.
- **Shift-click a place in the picker to share it in chat.** It puts the place's name, zone and coordinates in your chat box, along with the game's own map pin, so anyone who clicks it gets the spot as their waypoint. Shift-clicking a "Nearest..." pick shares the nearest one.
- **"How it works"** on the ley line sharing question and on its setting. Point at it to see exactly what is sent, an example message, what it's used for, and how to turn it off.

### Changed
- If you hide the window while it's docked to the map, it now stays hidden after a reload or login.
- Ley line sharing asks the channel less often and answers more politely, matching Skyborne Ley Line & Convergence Marker.
- Starter translations for the new text in all supported languages.

## 0.7.0

### Added
- **Multi-stop routes.** Paste `/way` lines, or use your TomTom waypoints, and Mapzeroth plans the quickest order through every stop. The navigator takes you through them one stop at a time.
- **Saved routes.** Save a pasted or TomTom route under a name, then edit its stops or delete it later. Saved routes appear in a "Saved Routes" section of the picker on every character.
- **Share ley line and convergence sightings** (Skyborne, off unless you choose it). When your racial confirms a ley line or elemental convergence, Mapzeroth can share where it is and which phase you're in with players using Skyborne Ley Line & Convergence Marker, and receive theirs. "Nearest Ley Line" / "Nearest Elemental Convergence" then goes to one seen in your phase in the last hour ("Seen in your phase 12 min ago"), including spots shared by other players that Mapzeroth doesn't list yet. You're asked once; the setting is on the settings page. If you use Skyborne Ley Line & Convergence Marker, it does the sharing and Mapzeroth uses its sightings.
- **Dungeons and Raids sections** in the picker: the ones at or below your level by the game's own group finder range, highest first.
- **Your route on the map before you start.** A route shows on the world map as soon as you pick it, not only once you press Start.
- **New theme: Cartographer**, a dark parchment look.
- **Time bar.** A bar under a route's total shows how the time splits between walking, flights, boats and teleports.
- **Picker settings page.** A checkbox for each pick at the top of the list (Waypoint, Nearest Ley Line, your trainers...), to hide the ones you don't use.
- **Undercity's two levels.** The gate leads into the ruins above; routes take one of the three elevators down into the city.
- **More ley lines and convergences:** 28 more ley lines and 14 more convergences, 64 and 44 in all.
- **Addon compartment.** With the minimap button hidden, Mapzeroth is listed in the minimap's addon menu instead.
- Tooltips on the Nearest Ley Line / Elemental Convergence picks and on routes.
- **Discord button** on the settings page, for questions and support for tr0tsky's addons. It gives you the invite link to copy.

### Changed
- **The route on the map is redrawn:** smooth dotted lines on foot and dashed for flights, colours that stand out on the map, small dots where steps begin, and a ring with an arrow where a teleport leaves and lands. Lines and markers scale with the map's zoom. Opening the map with a long route no longer stutters.
- The minimap shows the same lines and markers as the world map.
- **Navigator:** a new arrow that turns smoothly as you move, and the Cast / Use button shows the spell's or item's icon.
- **The picker opens instantly:** picks are one line each, and the travel time is worked out when you choose one. One Way / Round Trip is now a choice on the route itself (remembered), instead of separate "(one way)" and "(round trip)" entries.
- Modern Dark numbers the stops of a multi-stop route and colours each step's time by how you travel.
- New characters: flight points are no longer assumed found until a flight master shows which ones you have. The "Assume flight points are found" setting brings back the old behaviour.
- Mulgore now borders Stonetalon Mountains and Desolace, and the Tirisfal Glades / Silverpine Forest crossing has moved.
- The entrances to Dalaran and the Excavation Site are in new positions.
- Starter translations for the new text in all supported languages.

### Fixed
- An error in combat when a route used a teleport (the game hides cooldowns from addons in combat).
- "Your Waypoint" sometimes didn't appear: a waypoint set with a continent map showing, or set while a route or a search was on screen, now shows in the picker.
- Flight steps show the flight master's boot icon; it was blank.
- The route on the minimap follows square minimaps.
- Navigator: a boat or zeppelin you're already on counts down the ride, not the average wait plus ride.
- Flight prices: fares learned before you got Frequent Flier are forgotten, so prices are right afterwards.

## 0.6.1

### Added
- **The shorter cooldown goes first.** When two routes are equally quick and differ only in the teleport they use, Mapzeroth picks the one with the shorter cooldown, so a shaman uses Astral Recall before the Hearthstone. Items that are used up come last.
- **"Longest cooldown to use" setting** (1 to 8 hours, or 8+ for no limit, the default): abilities and items with a longer cooldown are left out of routes.
- **Hearthstone to a place Mapzeroth has no inn for.** If you bind somewhere Mapzeroth doesn't know an inn, routes still use your hearthstone and take you to the spot where you bound.

### Fixed
- Darnassus: the gates between Rut'theran Village and the city are in their measured places, and the step reads "Use" the gate rather than "Go to" it.
- Dalaran's two inns are one entry in the picker, going to whichever is nearer.

### Changed
- Smaller download: the travel data ships in a compact form (the zip is about a third smaller).
- Starter translations for the new text in all supported languages.

## 0.6.0

### Added
- **Round trips for "Nearest ..." picks.** When the quickest way there and back is somewhere other than the nearest place, the picker lists both: "(one way)" and "(round trip)", with the round trip's total time. The route shows the way there, then the way back to where you started, and the navigator follows both. A hearthstone (or Astral Recall) is used by one leg only; teleports without a cooldown can be used both ways.
- **A pointer to Skyborne Ley Line & Convergence Marker** under the route to a ley line or convergence, for the addon that shows where they have been found. Choosing it offers the address to copy (the game can't open links). It doesn't show if you already have the addon, and you can dismiss it for good from that popup.
- **More known ley lines and convergences:** 10 more ley lines (Elwynn Forest, Redridge Mountains, Westfall and Darkshore) and one more convergence (Mulgore), 36 and 30 in all.
- **Profession trainers by tier.** Journeyman, Expert, Artisan and Master trainers each cover a range of skill, and show while your skill is inside it (so at 76 tailoring you are sent to the Expert tailor, not the Artisan). The trainer tooltip names the tier and its range.

### Fixed
- Stormwind's Expert tailor (Sellandus) has a place of his own, not merged with the other tailors. Profession trainers of different tiers are no longer merged into one averaged spot.
- The Stormwind walk scale is now 1.5, the average of two measured routes (it was 1.7); Orgrimmar and Thunder Bluff follow.
- A hearthstone bound before the addon was installed is found when the client's text for the place is longer than ours ("Stormwind City" for "Stormwind").
- A round trip's fares are counted for both ways, and no longer run off the edge of the window.

### Changed
- Starter translations for the new text in all supported languages.

## 0.5.1

### Added
- **Minimap button.** Left-click shows or hides the Mapzeroth window, right-click opens the settings, and you can drag it round the minimap: it remembers where you left it. There is a new setting, "Hide minimap button" (off by default).
- **Show/hide from anywhere.** `/mz` (or the minimap button) shows or hides the window. Docked beside the map, it shows or hides the panel; with the map closed, the window opens on its own and docks beside the map when you open it. Popped out, the window is independent of the map. Mapzeroth never opens or closes the map itself, which avoids the map errors some players hit when opening it in combat.
- **Horde Skyborne: Nearest Elemental Convergence**, beside the Alliance's Nearest Ley Line. It shows only to Horde characters who know Skysight. Includes 29 known convergence points (Durotar, Mulgore, The Barrens, Stonetalon Mountains, Arathi Highlands, Wetlands, Thousand Needles and Zephras Isle).
- **Trainer tooltips** in the picker: your profession rank, the weapons you can still learn, and the class abilities a trainer can teach you now with their cost and the next level that brings more. Trainers respect your faction.
- **Route step icons.** Steps can show a picture of how you travel, or the coloured bars (new setting, "Route step markers").
- **Mage city teleports and the shaman's Astral Recall**, with their Forever spell ids confirmed in game.
- **More entrances.** Orgrimmar's second gate (the one toward the Barrens) and Thunder Bluff's four lift gates.

### Fixed
- Profession trainers: a character with any rank of a profession now counts as having it (the trainer pick vanished for Journeymen). Herbalism, mining and skinning trainers teach every rank to anyone.
- Zone crossings: the Durotar/The Barrens crossing had its Durotar side in the wrong place; the Hillsbrad Foothills/The Hinterlands crossing was listed under Arathi Highlands.
- The Ratchet <-> Booty Bay boat now uses its measured time (250 s on average) instead of a placeholder.
- A popped-out window no longer opens or closes with the map.

### Changed
- Smaller download: explanatory comments moved out of the shipped data files.
- Starter translations for the new text in all supported languages.
