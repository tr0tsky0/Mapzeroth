# Changelog

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
