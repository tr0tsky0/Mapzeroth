# Mapzeroth Rebuild — Design Draft

Status: draft for review. Nothing here is locked in — this is meant to surface decisions and get reactions, not to be the final word.

## Goals

1. One engine, multiple datasets — support Modern (retail) and Forever (Classic+) without forking the codebase. No interest in original Classic API support.
2. Minimize literal strings in shipped data, for localization.
3. QoL/UX improvements on top of the redesign.

## 1. Ruleset detection

Forever reports `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` (confirmed in beta — it is *not* a distinct project constant like the Classic re-releases get). It does report a distinct interface/build version: `1.60.1` / tocversion `16001`, versus retail's `11.x.x` / six-digit tocversions (`110107` and climbing). Expansion-level APIs (`GetServerExpansionLevel`, `GetExpansionLevel`, `GetAccountExpansionLevel`) all returned `0` (`LE_EXPANSION_CLASSIC`) on the Forever beta — a real signal, but too blunt to build on (it can't distinguish anything finer than "base tier").

**Decision: detect ruleset from interface version, with a manual override.**

```lua
-- Constants.lua
addon.RULESET_INTERFACE_THRESHOLD = 20000

local _, _, _, interfaceVersion = GetBuildInfo()
addon.Ruleset = (addon.Config and addon.Config.rulesetOverride)
    or (interfaceVersion < addon.RULESET_INTERFACE_THRESHOLD and "forever" or "modern")
```

`/mz ruleset forever|modern|auto` writes `rulesetOverride` to SavedVariables, for when detection needs a manual escape hatch (beta churn, a future ruleset this heuristic doesn't anticipate, etc).

**Packaging consequence:** Blizzard's client refuses to load an addon whose `.toc` declares an `## Interface` it doesn't recognize. Since `16001` and `110107`-ish will never collide, this needs **two `.toc` files** shipped in the same folder — `Mapzeroth_Mainline.toc` and `Mapzeroth_Forever.toc` — both loading the same engine Lua files, same convention as existing multi-flavor Classic addons. (Open question below: whether CurseForge's packager already recognizes a "Forever" flavor keyword.)

**Data layout follows the same split.** Rather than tagging individual node/edge/ability entries with a ruleset field, each ruleset gets its own data folder, and each `.toc` only lists its own:

```
Data/
  Modern/
    Nodes_EasternKingdoms.lua, Nodes_Kalimdor.lua, ..., Edges.lua, Abilities.lua, RidingSkills.lua
  Forever/
    Nodes_EasternKingdoms.lua, Nodes_Kalimdor.lua, ..., Edges.lua, Abilities.lua, RidingSkills.lua
```

No runtime filtering needed anywhere — the `.toc`'s file list *is* the ruleset gate. This also settles how ability/item data (class teleports, hearthstones, toys — which ones even exist pre-Cataclysm) varies by ruleset: it's just a different file, not a shared table with per-entry ruleset flags.

## 2. Container hierarchy

Today: nodes carry a flat `traversalGroup` string, an `interior` boolean, a `mapArtID`/`phaseCheckMapID` pair threaded through the pathfinder as live search state, and a separate global `NO_FLY_MAPS` lookup table. Four different mechanisms solving variations of one problem: *which nodes are allowed to auto-connect to which, and under what movement rules*.

**Decision: replace all four with one nested container tree, but auto-edges operate at the Continent level, not the Zone level.**

```
World
 └─ Continent            (e.g. "Eastern Kingdoms", "Kalimdor", "Outland")
     └─ Zone             (e.g. "Elwynn Forest", "Darkshore — Past", "Darkshore — Present")
         └─ Interior      (optional — e.g. "Stormwind Keep", a dungeon, a mage tower)
             └─ Node
```

Zone is still a real level in the tree — it's where `fly`/`indoor` overrides and a node's phase identity live. Whether it's *also* an auto-edge boundary depends on the travel method, corrected after actually thinking through what "no flying" means for Forever specifically:

- **`fly` auto-edges** (only exist where a ruleset has flying at all) ignore zone boundaries — a flying mount doesn't care about terrain, so these stay continent-wide, distance-gated by `MAX_AUTO_EDGE_DISTANCE`, exactly matching what `traversalGroup` already did today.
- **Ground auto-edges (walk/mount) are zone-scoped only.** Straight-line distance is not a safe proxy for walkability — Darkshore and Felwood are adjacent on the map but blocked by terrain; the real path detours through Ashenvale. Forever has no flying at all, so this isn't a rare edge case for it — it's the *only* way ground travel works, for every zone boundary in the game. Auto-generation cannot know which zone-adjacencies are actually walkable without terrain data we don't have, so it doesn't try: **Zone ↔ Zone always requires an explicit edge for ground travel**, authored where a real path exists (and omitted where it doesn't, like Darkshore↔Felwood directly).

So the full explicit-edge list (`portal`, `teleport`, `ship`, `flight`, `phaseswitch`, plain `walk`/`fly` where hand-authored, etc) is:

- **Continent ↔ Continent** — different landmasses.
- **Zone ↔ Zone**, for any ground method — covered above.
- **Zone/Continent ↔ Interior** (and Interior ↔ Interior) — an interior's coordinates aren't part of the outdoor world's contiguous space.
- **A zone's own phase-states, to each other** — Darkshore-Past ↔ Darkshore-Present is a `phaseswitch` edge (talk to Zidormi), not a walk, even though the two occupy the same physical spot.

This also simplifies the phase-sibling story: since *no* zone-to-zone ground connection is ever auto-generated now, there's no longer a special case needed to stop Darkshore-Past and Darkshore-Present from *auto*-connecting to each other via a shared neighbor — that was already prevented, now for free, by the same rule that prevents any two zones from auto-connecting at all. The `phaseGroup` mechanism is still doing real work, just narrower than before: it's needed for the *search-time* gating (§ below — which explicit edges are usable given the player's current simulated phase), not for excluding auto-edges, since there are none to exclude.

Practically, Zone↔Zone ground connectivity for Forever is a real, sizeable data-authoring task — every real walkable zone boundary needs a hand-confirmed edge, the same way flights/boats/zeppelins got collected. Worth seeding it the same way we seeded the flight mesh: auto-generate a *candidate* edge between geographically-close zone-border nodes as an explicit **UNVERIFIED** placeholder, then confirm (or delete) each one by actually walking it in-game, rather than either trusting unverified guesses or requiring every connection to be discovered from scratch with no starting point.

This absorbs the old special cases:

- **Phasing** (your point #3): a phase-variant zone is two sibling `Zone` containers sharing a `phaseGroup` tag, linked to *each other* only by an explicit `phaseswitch` edge, while each still auto-connects normally to its actual geographic neighbors like any other zone.

  A headless prototype of this (see §9) initially claimed phase needed *no* search-time state at all — wrong, and worth recording why. Zidormi's flag is sticky per phaseGroup (confirmed): it persists regardless of where you walk, until you talk to her again. That means a neutral zone bordering *both* phase-siblings (Ashenvale borders both Darkshore states) lets Dijkstra "launder" a phase change for free — duck into Ashenvale, walk back into whichever sibling is cheaper — unless something remembers which side you're actually on. So a small `{phaseGroup: side}` state does travel through the search after all, just scoped to only the phaseGroups that exist in the data (Forever has none, so it costs nothing there) rather than the sprawl of `mapArtID`/`phaseCheckMapID` checks the original threaded through multiple files. This fixes the original's `visited[currentID]` bug directly: dedup keys on `(nodeID, phaseState)`, not `nodeID` alone, so it's correct by construction instead of by luck.

  An edge into a phase-tagged container normally requires the *current* simulated side to already match the destination's side; an edge can declare `overrides_phase = {"darkshore"}` to bypass that check and force the state instead — this is exactly what a Zidormi conversation is, but it's *also* what handles the one confirmed exception: **Teleport: Undercity always lands present-side Tirisfal regardless of the caster's current phase.** That's not a special case requiring its own logic — it's a second edge with the same `overrides_phase` mechanism, just attached to a `teleport`-method edge instead of a `phaseswitch`-method one. Any other teleport/portal into a phase-tagged zone that *doesn't* declare an override is correctly gated like a normal edge.
- **Interiors** (your point #4): not a boolean flag anymore, just another container level, always reached by an explicit entry/exit edge — nothing interior-specific in the pathfinder. "Interior" here means any nested container that isn't walkably connected to its parent, not only a separate map: Rut'theran Village (`kalimdor.teldrassil.ruttheran`) shares Teldrassil's map but can't be walked to from Darnassus, so it's an isolated child container reached only by the ferry, flight or the Darnassus transition edge.
- **Zones that hang directly off the World map** (found live: Zephras Isle, mapID 2521, is `mapType=3` Zone with `parent=947` Azeroth — no continent between). The tree assumes World → Continent → Zone, so these get a **synthetic single-zone Continent wrapper** (`zephras_isle.zephras_isle`) rather than teaching the engine a second shape. Nothing is lost: ground auto-edges are zone-scoped anyway, and `fly` is off in Forever, so the wrapper never changes which edges auto-generate. It's authored by hand in data, not derived from `C_Map` parents.- **Continents** (your point #5): `traversalGroup` string tags become real container objects — still the actual auto-edge domain, unchanged from today — now with a place to hold metadata (display name resolution, which ruleset it belongs to) instead of being an implicit string match.

**Two inherited traversal flags replace `NO_FLY_MAPS` and the old `interior` boolean:**

```
Kalimdor
 - Zones
     - Felwood                       -- traversal = { fly = false }
         - Nodes
         - Interiors
             - Dark Tower             -- traversal = { indoor = true }  (default for any Interior)
                 - Nodes
```

- `fly` — independent of everything else. Confirmed there are plenty of outdoor, mountable zones where flying is specifically disallowed (Eversong Woods, Oribos, The Maw, the Argus zones today), so this stays its own flag, inherited down the tree, overridable at any level. A cross-zone `fly` auto-edge only gets created if *both* zones allow flying (irrelevant for within-zone ground edges, which don't check `fly` at all — flying and walking are just different auto-edge passes over the same node pool, zone-scoped for the ground pass, continent-scoped for the fly pass). For Forever it's simply `false` at the World root, once, since flying doesn't exist there at all — no per-zone overrides ever needed, and no cross-zone auto-edges of any kind.
- `indoor` — replaces the old `interior` boolean *and* subsumes what a separate `mounted` flag would have done. Confirmed mounting is purely an indoor/outdoor distinction (no case where an outdoor area disallows mounting, or an indoor one allows it by default), so one flag covers both "does this container get auto-edges as its own leaf" and "can you mount here." Defaults to `true` for any `Interior` container, `false` otherwise; overridable for the rare exception (a large indoor space where mounting is actually allowed).

**Phase-only areas nest under the phase-sibling that leads to them.** Past Darkshore connects to Teldrassil; Present Darkshore doesn't (Teldrassil burned down — there is no "Present Teldrassil" to connect to). Teldrassil nests as a *child* zone under "Darkshore — Past" (not a flat merge, so it can still override `fly`/`indoor` for itself if needed), inheriting Darkshore-Past's `phaseGroup` membership the same way it would inherit `fly`/`indoor`. The explicit edge from Darkshore-Past into Teldrassil is authored like any other Zone↔Zone ground connection now (per the correction above); nesting's remaining job is just making sure the *search-time* phase gate gets inherited too, so Teldrassil is correctly unreachable while simulated state says "present." Display naming is untouched by this: Teldrassil's nodes keep their own real `mapID`, so name resolution still shows "Teldrassil," not "Darkshore" — container nesting is a pathing-domain concept only, it never leaks into what the player sees. General rule for future data authoring: **an area whose only physical connection point exists inside one specific phase-sibling's terrain nests as a child of that phase-sibling**, rather than being modeled as an independent top-level Zone.

**Ruleset tie-in:** a "ruleset" is just which set of `Continent`/`Zone` data files get loaded into this tree (see §1). Forever's dataset is close kin to the "past"-phase halves that already exist for Darkshore/Blasted Lands/Uldum today, generalized to the whole world instead of ~7 zones — the container model was arguably already half-built for this without realizing it.

## 3. Ground speed resolution

Forever has no flying, planned or otherwise — so unlike Modern (where flying dominates and ground-speed nuance barely affects route costs), Forever's routing accuracy depends entirely on getting mounted-ground speed right. Today's `WALK_SPEED = 7` constant is really "100% run speed," with no tier above it. That's not enough on its own anymore.

**Decision: `WALK_SPEED` stays as the base unit; a resolver computes the best available multiplier on top of it, container-aware.**

Confirmed numbers (Forever beta):

```lua
-- Data/Forever/RidingSkills.lua
{ spellID = <apprentice riding>, bonus = 0.60 },  -- skill 75
{ spellID = <journeyman riding>, bonus = 1.00 },  -- skill 150
```

```lua
-- Data/Forever/Abilities.lua (ground-speed forms — same detection style as
-- today's PlayerAbilities.lua, just a new category alongside teleports/hearthstones)
{ spellID = <druid travel form>, bonus = 0.40, indoorCapable = false },
{ spellID = <shaman ghost wolf>, bonus = 0.40, indoorCapable = false },
-- indoorCapable flips to true for a shaman with Improved Ghost Wolf known
```

```lua
function addon:GetGroundSpeed(container)
  local indoor = container:Get("indoor")  -- walks up the inherited tree
  local best = 1.0                        -- base run, as a multiplier on WALK_SPEED
  if not indoor then
    best = math.max(best, 1.0 + addon:GetBestRidingSkillBonus())
  end
  for _, form in ipairs(addon:GetKnownGroundSpeedForms()) do
    if not indoor or form.indoorCapable then
      best = math.max(best, 1.0 + form.bonus)
    end
  end
  return addon.WALK_SPEED * best
end
```

Speeds are stored as bonus multipliers, not absolute yards/sec, so nothing breaks if `WALK_SPEED` itself is ever corrected. `fly` eligibility for the `fly` auto-edge method is checked independently per §2 — flying is never available indoors regardless of any flag, so no interaction with `indoor` is needed there. Modern's `Data/Modern/RidingSkills.lua` is trivial (ground mount speed is normalized and fast once a character can ride at all in current retail) — this machinery mostly exists for Forever's benefit, but both rulesets go through the same resolver.

## 4. Node and edge schema

**Decision: nodes are pure location data. Everything about availability lives on edges.**

```lua
-- Node — no name, no faction, no interior flag
Node = {
  id = "stormwind_mage_tower",
  container = "eastern_kingdoms.stormwind",   -- leaf container path
  mapID = 84,
  x = 0.213,
  y = 0.672,
}
```

```lua
-- Edge — unchanged in spirit from today's model, faction now lives here exclusively
Edge = {
  from = "stormwind_mage_tower",
  to   = "orgrimmar_portal_room",
  method = "portal",              -- portal | teleport | hearthstone | racial | ship |
                                   -- zeppelin | tram | flight | fly | walk | phaseswitch
  cost = 2,                       -- seconds; omit to auto-calc from distance within a leaf container
  oneway = true,
  requirements = { faction = "Alliance" },   -- see below
  overridesPhase = { "darkshore" },          -- optional, see §2 — Zidormi conversations and the
                                              -- rare "always lands on one side" teleport/portal
}
```

Your point #1 — you can walk up to the enemy flightmaster, you just can't fly with him — is exactly what this fixes. A node never claims to be faction-restricted; only the edge that would use it does. `EdgeRequirements.lua`'s data-driven `requirementCheckers` table (faction, quest, class, reputation, covenant-or-Forever-equivalent, holiday, level, `anyOf`) is a pattern that already works well and carries forward unchanged.

## 4a. Discovered flight points

You can only fly to a flight point you have found. The Forever client won't say which ones without help: `C_TaxiMap.GetTaxiNodesForMap` returns every point on the continent with no state and "undiscovered" always false. While a flight master's window is open, `C_TaxiMap.GetAllTaxiNodes(mapID)` returns each point as Current, Reachable or Unreachable (`Enum.FlightPathState` 0, 1, 2), and the old slot list agrees (CURRENT, REACHABLE, DISTANT). Confirmed on a character that had found four points: Reachable meant found and directly connected, and everything else, found or not, came back Unreachable.

`FlightKnowledge.lua` turns that into a per-point answer, one window at a time:

- Current or Reachable: **found**.
- Unreachable, although one of our flight edges joins it to a found point: **not found**. Had it been found, that edge would have made it Reachable. Reachable covers multi-stop trips (Menethil is Reachable from Stormwind by way of Ironforge), so any found point can vouch, not just the flight master you're at.
- Anything else: **unknown**. Routing only flies into a point known to be found, so a route never promises a flight that can't be taken. Until a character has opened a flight master's window once, that means routes use no flights, and the UI should say so and ask them to open one.

The graph builder drops a flight leg into a point known not to be found (`ctx.flightNodeFound`). A new-flight-path message clears the "not found" answers, because we aren't told which point was learned. Knowledge is saved per character, but SavedVariables are wiped on reload on the beta for now, so it lasts a session. The same check works in reverse as data verification: on a character that has found everything, the Reachable list at each flight master should equal our direct flight edges from it.

This is the basis for the panel's "not discovered, so the route walks there" note and for a "unlock it and save N minutes" hint (route with and without the point).

## 5. Name resolution (localization)

Today, node names are literal English strings in the data files, plus an unmerged PR (#25) that resolves them at runtime from client APIs instead (`C_TaxiMap`, `C_AreaPoiInfo`, `C_Map` position-matching against the node's own coordinates), with a `Locales.lua` string table for UI text and a metatable fallback so a missing translation key never blanks the UI.

**Decision: promote PR #25's approach from optional patch to the only way node names exist.** Nodes never carry a `name` field in ground-truth data at all — name resolution is purely a presentation-layer step:

- Flight masters, portals, POIs, dungeon entrances: resolved from client APIs by matching the node's `mapID`/`x`/`y` against what the client reports, in whatever language the client is running.
- Pattern names ("Portal to Valdrakken"): rebuilt from the destination node's resolved name, not hand-translated.
- The rare node the client genuinely can't name: a small `NodeNameOverrides` table keyed by node ID (stable), not by English name (which changes).
- All other UI strings (buttons, tooltips, settings, chat messages) go through `L["KEY"]` from `Locales.lua`, same pattern as today.

Diagnostic output (unresolved-name counts, `/mz names`) stays gated behind `addon.DEBUG` rather than always writing to `MapzerothDB` — per the existing project convention that SavedVariables holds user settings only, never diagnostic state. (This was a real PR #25 review comment on the original patch — worth not re-introducing.)

## 5a. Destinations (POIs) and the picker's relevance rules

Things a player wants to go *to* — as opposed to transport nodes — are POI nodes in `addon.Nodes.Pois`, generated by `tools/gen_pois.py` from captured in-game data and Wowhead listings (`tools/poi_source/`). They follow the same rules as §5: no name field; names come from the client (area names, flight-master names, class and profession spell names) or from pattern strings.

**Settlements.** *Cities* are the six faction capitals (Stormwind, Ironforge, Darnassus, Thunder Bluff, Undercity, Orgrimmar); every other place with an inn is a *town*. A settlement is named from its area (`C_Map.GetAreaInfo`), else from its flight master's name minus the zone suffix, so nothing is hand-translated. Services (inn, bank, auction house, battlemaster, stable master, trainer) attach to a settlement, or to none. Services more than a few steps apart are separate places, so a city with three inns has three inn destinations. Instance entrances are POIs too, named from the instance's area ID.

**Flight masters read as a destination, not a zone label.** A `TAXI_` node's raw client name ("Stormwind, Elwynn") is the taxi point's own zone-suffixed label, not something a "Walk to..." step can name a place with — a player who hasn't found that point yet has no way to tell what it is. So `NodeNames` looks the point up against the settlement it belongs to (`Cities`/`Towns`, by their `taxi` field) and names it "Stormwind Flight Master" instead; a flight point with no settlement on record (Thorium Point, and other Forever-only points not yet in `Pois.lua`) still falls back to the client's raw name.

**Cities have entrances, and every settlement has a centre.** Cities are enclosed, with one or a few ways in, while towns are open on all sides. A city gets `entrance` places ("Dalaran Entrance"), and "go to <city>" routes to whichever of its entrances is nearest (one search over several goals). A town has no entrance; "go to <town>" routes to its centre. So that a settlement never borrows another place's node, every city and town also has a node of its own at its centre (`CITY_<KEY>` / `TOWN_<KEY>`, kind `settlement`, named simply by the settlement). A city with no entrances captured yet falls back to its centre. Dalaran has one entrance. The six capitals have none yet: their maps are folded into their zone's container, so there are no city-gate border nodes to reuse (an earlier version of this doc said there were). Their entrances need capturing in game.

**Two layers for trainers.** The routing node is one *place* (a cluster of trainers of one type: "Stormwind Tailoring Trainer"). Under it, `npcs` lists each real trainer NPC with the spell IDs they teach. Nothing is merged in the data; the grouping is only how the picker lays it out and how routing picks a stop.

**What a trainer teaches decides who needs it:**

- Class trainers teach class abilities to their own class only. Weapon skills are taught only by weapon masters (a Wowhead map's "weapon trainer" flag is not the same thing).
- Profession trainers are identified by the highest rank they teach (Apprentice → Artisan), read from the rank spells they teach.

**Picker default (`Trainers.lua`, `Trainers:IsRelevant(node, ctx)`).** The picker shows a trainer place by default only if it can still do something for this player:

| Trainer | Shown by default when |
|---|---|
| Class | it is the player's own class |
| Weapon master | some NPC teaches a weapon skill the player's class may learn (`addon.ClassWeapons`) and the player doesn't know it |
| Profession | the player has the profession and some NPC there teaches the rank right after their highest (so an Expert leaves a Journeyman trainer behind) and will talk to them: a trainer won't talk to a player whose rank is well below its top rank (an Artisan trainer tells an Apprentice they need more training), taken as more than `PROFESSION_TRAINER_REACH` (2) ranks above; that reach is inferred from that one case |
| Riding | it teaches a riding rank the player doesn't know |
| Pet | the player is a hunter (Pet Trainer) |
| Demon | the player is a warlock (Demon Trainer; none in the data yet) |

Everything else goes into a "More trainers" drill-down alongside all other non-relevant trainers, still reachable. Non-trainer POIs are never filtered.

The test runs per NPC (`Trainers:RelevantNPCs`), and a place is relevant if any of its NPCs is, so the picker can point at the trainer who teaches the missing rank or weapon rather than just the hall.

Two rules cover the gaps in the data:

- An NPC with no `teaches` list is one we couldn't get data for (Wowhead lists no rank spells for about 30 profession trainers, and Kildar's wolf riding page is empty). That isn't the same as teaching nothing, so it is shown whenever its type is relevant: a profession the player has, or any weapon or riding trainer.
- Specialization trainers (Dragonscale, Elemental, Tribal, Shadoweave, Goblin, Gnome; marked `specialty` in the data) teach only to players who chose that specialization, so they stay in the drill-down until specializations are modelled.

A profession trainer's teaches list is limited to its own profession's ranks. In the data a trainer's title is one step above what it teaches: "Journeyman" trainers teach only Apprentice, "Expert" ones up to Journeyman, "Artisan" ones up to Expert, and "Master" ones up to Artisan. Gathering-profession trainers teach every rank. This is worth confirming in game.

**Ley lines.** The Skyborne racial Read Ley Line (spell 1259705, 2 min cooldown) raises Health and Mana regeneration by 100% for 15 minutes at a ley line and 15 seconds anywhere else. The buff has no effect on travel, so ley lines are plain destinations, not pathfinding inputs. They are `leyline` places out in the world: they never belong to a settlement and are named after their zone ("Zephras Isle Ley Line"). The picker shows them only to a player who knows the spell, which today means Skyborne and only Skyborne. The pathfinder can search for the cheapest of several goals (`FindPath` takes a list of node ids and returns the one it reached), so "nearest ley line" is one search. `Relevance.lua` is the single entry point (`Relevance:IsRelevant(node, ctx)`) that sends trainers to the trainer rules, ley lines to this one, and shows everything else.

`addon.ClassWeapons` is a Classic recollection and is unverified for Forever, and `addon.ProfessionRanks` lacks the higher-rank spell IDs no trainer has been seen teaching. Both are flagged in their data files.

## 5b. The destination panel and themes

The first slice of the UI is a panel docked to the World Map's right edge (inside the map's edge when the map is maximised): a search box, matching places with the time to each, and a chosen destination's route as steps. Lines on the map, the pop-out window and the collapsed strip come later. The pieces:

- `Destinations.lua` builds the list (flight masters, POIs, transport, instances, and each city and town), with names from the client, and marks what is relevant to this player (section 5a).
- `Search.lua` matches typed words against names, with accents folded by hand (deDE, frFR, esES, ptBR, ruRU) and every word required. Names beat the zone, word starts beat mid-word hits, and relevant places sort first. A place can also carry `details` that a search hits and the list shows: a weapon master lists the weapon skills its trainers teach (the client's names for the skill spells, plus a localized alias where the client's word differs from what people type, like "staff" for Staves), so "sword" or "staff" finds the right cities and the row says which weapons matched.
- `Location.lua` turns the player's position into a start node, carrying a subzone up to the zone we cover. The graph then adds walking edges from that node to the nodes in its container (`TravelGraph:AddStart`).
- `Journey.lua` prices every node from that start in one search (`Pathfinder:FindCosts`, so each result shows a time), then plans the chosen destination as readable steps and, if a flight we can't use would be faster, a hint that names the flight point and what unlocking it saves.
- `UI/Panel.lua` lays it out. Frames are built on first use and never at load.

**Themable.** The UI is themable from the start because the addon serves two rulesets and players differ in taste. All styling goes through `UI/Theme.lua`: the panel asks it for widgets (panel, button, edit box, row, text) and it skins them from the current theme, remembering each so a switch re-skins what is on screen. A theme is one file under `UI/Themes/` giving colours, font objects, backdrops, the button style (flat, or Blizzard's red panel button), and colours by travel method and kind of place. Two ship: **Classic** (dialog-box frames, red buttons, Blizzard's gold and white) and **Modern Dark** (the design mock-ups' slate, brass and verdigris, and the default). `/mzr theme [id]` switches, and the panel's theme button cycles. Fonts are Blizzard's own font objects; the mock-ups' typefaces are not shipped.

**Development tooling is not part of the addon.** Everything that reports on, measures or pokes at the engine lives in MapzerothDataTools (outside this repo), so the addon ships without it and says nothing in chat on its own. The engine shares its table as the global `MapzerothAddon` (`Core.lua`) and leaves two hooks open that do nothing unless a tool sets them: `Navigation.onTiming` (how long a flight or boat really took) and `FlightKnowledge.onFares` (the prices a flight window showed). MapzerothDataTools' `Dev.lua` records what they hand it and owns the `/mzr` commands: `flights`, `timings`, `fares`, `ticket`, `nav`, `theme`, `dist`, `world`, `route`, `name`, `walktime`, `hearth`, `speed`. A player has `/mapzeroth` (or `/mz`) with `ui` and `settings`. The data validator is headless, so it lives with the tests (`tests/Validator.lua`, loaded by the harness) and no in-game command is needed.

**The map waypoint is a destination.** A character with a waypoint set on the world map (the game's own, `C_Map.GetUserWaypoint`; TomTom is not read) gets "Your Waypoint" as the first pick under Personally relevant, priced like the others. It isn't one of our nodes, so `addon:GetWaypoint()` makes a destination `{ id, mapID, x, y }` (a position on a map with no nodes is carried up to a parent map, as for the player's start), `TravelGraph:AddDestination` links every node of its container to it on foot, `Journey:Build` takes it as an extra, and `Navigation` resolves it through the entry's `dest` since `World` doesn't know it. The panel follows `USER_WAYPOINT_UPDATED` (registered defensively) so setting or clearing it updates the accordion.

**The route on the map** (the design's "route on the map" board). Each readable step keeps `path`, the points it goes through as `{ mapID, x, y }` on their own maps (Journey: a merged walk's stops, a through-ticket's stops, the player's start, the waypoint). `MapRoute.lua` is the geometry with no frames: it carries each point onto the map the player has open through world coordinates (`Navigation.MapPoint`), breaks the line where a point can't be placed there, styles each piece (on foot dotted with a faint halo, a flight dashed, a boat, zeppelin or tram solid, a teleport, hearthstone or portal dotted in the accent colour), lists where each step starts and where the route ends, and cuts dashes and dots along a path (`Pattern`). `UI/RouteLines.lua` draws that on a frame filling the map's canvas, so it pans and zooms with the map: pooled `Line`s (a dash or dot is a short line), numbered badges at each step's start with the current one filled and the finished ones faded, and a marker at the end. Sizes are worked out against the canvas' scale so they look the same at any zoom, colours are the theme's method colours, and a failure while drawing never reaches the map. Only a trip that has been started is drawn (the navigator hands the plan and current step to `RouteLines:Follow` as the trip updates, as it does for the minimap); a route that is only being looked at in the panel is not, and the lines stay up while the trip goes on, whatever page the panel is on, until it ends or is stopped. The map redraws them when it changes map or zoom (`OnMapChanged`, `OnCanvasScaleChanged`). Still to do from the board: the legend, the "flight path not found" note on the map, a setting to turn the lines off. Which map and drawing APIs the beta has is checked with MapzerothDataTools' `/mzr mapapi`, `/mzr waypoint` and `/mzr drawtest`.

**The route on the minimap** (`UI/MinimapLines.lua`) follows the trip being followed (the navigator hands over the plan and the current step, so it shows with the map closed) and is drawn round the player with the same looks as on the map, thinner. The minimap is a round window on the world centred on the player, north up unless the player set it to rotate; how many yards it spans depends on its zoom and on whether the player is indoors (separate scales, and no call to ask which, so it is found by nudging the zoom and seeing which CVar follows, redone on `MINIMAP_UPDATE_ZOOM`). Each piece of the route is worked out in yards on the map the player is on and dashes are cut along it there (`MapRoute.Pattern`), so they stay put on the ground as the player moves; every 0.1 s the dashes are shifted to the player, turned by `-GetPlayerFacing()` when `rotateMinimap` is on, scaled to pixels and clipped to the circle (`MapRoute.ClipCircle`). `IsAvailable` says whether the client can do it (the settings page greys the option out and says so if not), and a failure while drawing never reaches the minimap. `/mzr minimapapi` and `/mzr minimaptest` check it in the client.

**A route with more steps than fit scrolls, like the search results list.** The panel shows 7 step rows; a route with more only hinted "+N" below them with no way to see the rest (a real 8-step route reported this way). Now the mouse wheel moves a `stepOffset` window over `plan.steps` (`Panel:RenderSteps`, `Panel:Scroll`, same pattern as the results list's `offset`), and once a trip is under way, reaching a step currently scrolled out of sight scrolls it back into view (`Panel:MarkCurrentStep`) so the highlighted current step is never lost on a long route.

**Cities are enclosed.** A city with a map of its own and an entrance pair on record (one gate node on its map, one on the zone's, captured at the same gate) is walled (`TravelGraph`): walking edges never join an inside node to an outside one, the two sides of a gate are joined by a zero-cost walk, and the player's start and a waypoint respect the same wall. So a route into Stormwind reads "walk to the Stormwind Entrance", then on to the bank, not a straight line through the wall. A city with no entrance pair (Dalaran, whose map is its zone's) isn't walled, so it can't be cut off. Wowhead listings the game showed to be wrong are dropped through `tools/poi_source/ignored_npcs.tsv`, and a place captured in person stands in their place.

**A building within a city walls the same way, by container instead of map.** A whole city's wall works because its inner and outer gate nodes sit on two different `mapID`s; a room or building inside a city shares its map with everywhere else in it, so there's nothing to key a wall off. The Wizard's Sanctum in Stormwind (where the Dalaran Skyborne portal exits) is the first case: its nodes sit in a container nested under Stormwind's own (`easternkingdoms.elwynn_forest.stormwind_wizards_sanctum`), so `World`'s per-container walking-edge pass (§ walking, in `TravelGraph:Build`) never joins them to the rest of the city on its own — a plain node in one container never gets a walking edge to a node in another. A single authored zero-cost `walk` edge between its entrance pair (`ENTRANCE_SW_WIZARDS_SANCTUM_OUTER`/`_INNER`, both `kind = "entrance"` so `CollapseSteps` never merges through them) is the door. No change to `TravelGraph`'s city-wall code was needed; this reuses the container tree and authored edges exactly as they already work, rather than generalizing `insideCity` to something keyed off containers.

**The main window before anything is typed** is an accordion (`Sections.lua`, drawn by the panel): *Personally relevant*, *Cities* and *Towns*, all closed each time the window opens. Personally relevant holds "Nearest ..." picks, each one entry over every place of its kind so the nearest is what the route goes to: Ley Line (for those who can read one), Class Trainer, Pet or Demon Trainer (hunters, warlocks), one trainer for each profession the character has that still teaches them a rank, and Weapon Trainer (a weapon master that teaches a weapon their class can learn and they don't know). Cities and Towns are the player's own faction's plus neutral ones; the other faction's are still found by searching, just not relevant by default. Whose a place is comes from `tools/poi_source/settlement_factions.tsv` through the generator (`faction` on each city and town). Nothing is priced when the window opens: the first time a section is opened the panel works out where the player stands and prices everything in one search, and each item then shows its travel time (a pick also names the nearest place; cities and towns sort nearest first). Riding instructors are not offered yet. **Hostile flight masters** (a point only the other faction's flights touch, `addon:GetFlightOwner`) are never routed through, whatever an edge says, and are not offered as destinations.

**Nothing is priced until a destination is chosen.** The search list shows names only. Choosing a destination plans it from where the player stands (one search over that destination's nodes, so a city routes to its nearest entrance and "nearest ley line" is a single entry over every ley line). The accordion's Nearest Ley Line pick is that entry, for those who can Read Ley Line; there is no "Home", since the hearthstone is a step of a route.

**Following a route (`Navigation.lua`, `UI/Navigator.lua`).** Start hands the plan to the navigator, a small draggable window that follows the trip even with the map closed. Navigation takes samples of the player (map position, whether they are on a taxi) and tracks the current step; what it shows depends on the step: distance on foot; for a flight, "speak to the flight master" and then a bar over the planned time from the moment the taxi leaves until it lands; for a boat, waiting to board, then a bar from how far along the way to the far dock the player is (or elapsed time when positions can't be read at sea); for a hearthstone or teleport, a secure button that uses the item or spell (attributes can't change in combat); for a portal, "walk into it". A step ends when the player is within a small radius of its destination (30 yards on foot, 60 for the rest), when a flight lands, or, for a teleport or portal, when the player suddenly appears far away (a bind point can be well off the inn node). Reaching a later step's destination skips the ones before it, and the trip ends with "Destination reached". A flight or boat that runs past its planned time says so. Measured flight and boat durations are kept for the session (`/mzr timings`) to check the data against. A started route stays pinned in the panel (with the current step marked) when the map is closed and reopened, and the search page returns on Stop, arrival, Back or a new search.

**Which flight was taken.** The navigator hooks `TakeTaxiNode` (a post-hook, so nothing is tainted) and reads the game's own route for the slot that was clicked: `GetNumRoutes` and `TaxiGetNodeSlot` give every stop, matched to our nodes through `C_TaxiMap.GetAllTaxiNodes` (each entry has its `slotIndex`). It applies the choice once the taxi is seen moving, so a flight that never starts (no money) changes nothing, and forgets it after 15 seconds. A ticket that ends where a later step of the route ends is the flight being flown, over all the steps it covers (one bar, timed as their total); one that ends somewhere the route doesn't go is treated as a mis-click: the window says where the flight goes, and on landing the route is planned again from there to the same destination, with a short "Route updated". A player who really wants somewhere else stops the trip and picks again. While on a taxi the navigator no longer skips ahead to a later stop it happens to fly over.

**Fares.** Every flight leg carries its base fare in copper (from the game's flight table, in `Flights.lua`), and a ticket costs the sum of its legs (Lakeshire to Ironforge, three legs at 8s 30c, was charged 23s 66c: 95%). What the player pays is a fraction of that: flight masters give the same reputation discount as vendors, by the faction of the flight master the ticket is bought at (Lakeshire's is Stormwind's: a character Friendly with Stormwind paid 95% there and, being Neutral with Ironforge, full price at Ironforge's). So the factor is learned per departure point from the flight window: `TaxiNodeCost(slot)` for each reachable destination against our fares along the game's route to it, kept per character (`FlightKnowledge:FareFactor(nodeID)`, MapzerothDataTools' `/mzr fares` prints the prices it read); a flight master not seen yet gets the highest factor of those that were (the least discount: a route the player can't pay for must never be offered), and 1 before any. A later step could seed it from the character's reputations once each flight master's faction is in the data. A route the player can't pay for isn't a route: `Journey` knows their money (`GetMoney`), and the search (`Pathfinder`, option `budget`) carries the fare paid alongside the time and keeps a slower label only if it paid less, so the route is exactly the quickest one within their means (a weighting of fares in seconds was tried and rejected: it cannot find a route like Refuge Pointe to Ironforge direct at 530c, which sits between two others). It only runs when the quickest route is too dear. The plan reports its fare ("in fares"), says when a quicker route exists that costs more than they have, and when no route is within their means says so and offers no Start button. Flight points Forever adds have no fare data yet and count as free.

**What counts as one walk.** The search walks through unrelated nodes on the way (a trainer along the road), which costs the same as walking straight, so consecutive walks read as one "walk to X" (`Pathfinder:CollapseSteps`). A walk still ends where a person would mark the route: at a zone border (`BORDER_` nodes), at a city entrance, and wherever it goes from one container into another (out of an interior, into a city). So Ironforge's flight master to Thelsamar reads "walk to the Dun Morogh / Loch Modan border", then "walk to Thelsamar", and the navigator's arrow always points at the end of the step it shows. Flights merge into one ticket only.

**Flights are single legs, chained by the planner.** A flight ticket flies through other flight points without landing, and which ones depends on which points the flyer has found (captured with `/mzroutes`; Lakeshire to Ironforge is one ticket through Morgan's Vigil and Thorium Point once Thorium Point is found, and through Stormwind before). So a whole-ticket time, like the ones InFlight recorded, is right only for a player with the same found points as its flyer. The network is therefore stored as single legs (`Data/Forever/Flights.lua`, generated by `tools/gen_flights.py`), each with its own time per direction (they differ), and the planner chains legs over the points the player has found, taking `FLIGHT_CHAIN_SAVING` (10 s) off for each extra leg flown straight through, because a through-ticket doesn't land and take off again (measured 15-45 s per ticket). Consecutive flights are shown as one ticket, "Fly to Ironforge (via Thorium Point)". One rule of the game's shapes this: when there is a direct leg from a ticket's start to its destination, the game always sells that direct ticket, even if a chain of legs would be quicker (Refuge Pointe to Ironforge is 271 s direct, though flying through Menethil Harbor would take about 205 s; every one of the 44 routes we captured obeys this). So the search remembers each ticket's origin and only lets a ticket end where it is a direct leg or has no direct leg from its origin; otherwise it continues, or lands earlier and takes a new ticket (which costs the full leg times, no saving). `tests/test_gameroutes.lua`, generated from the captured routes, replays every capture through the planner as one ticket.

Which pairs are legs is the game's own flight table: Classic Era's `TaxiPath` (build 1.15.9, from wago.tools, saved as `tools/flight_source/taxipath_classic_1.15.9.txt`), where every row is one flight master flying straight to another, regardless of what anyone has found. Every leg the game ever reported to us through `/mzroutes` is a row in it, and none of the multi-leg routes we saw is. A row with a fare of 0 is a ship, zeppelin or dialog path and isn't a flight (the one exception kept is the Teldrassil ferry, Auberdine and Rut'theran, which InFlight timed). The leg's time is InFlight's ticket time for that pair and direction (a missing direction mirrors the other). InFlight's classic table (881 tickets) has a time for every leg in both directions; if a future leg has none, the generator estimates it from the distance between the points and says so. Chained back together, the legs reproduce InFlight's whole-ticket times with a median error of about 1-3%, 89-96% of them within 10%. Flight points Forever adds (Rog'mar, Farholde Keep, the Hyjal points) aren't in that build's table and keep their hand-written placeholder legs in `Edges.lua`. A later step is for the addon to learn legs from the player's own flight windows.

**Settings (`Options.lua`, `UI/OptionsPanel.lua`).** Five settings, kept in `MapzerothRebuildDB.settings`: how many seconds a loading screen counts for in a route (0 to 20, default 10), the scale of our windows (70% to 150%, default 100%), the theme, and two on/off ones (both on by default): show the route on the world map, and show it on the minimap. Options holds the values, limits and change listeners; the page is built from the same themed widgets as the rest of the UI and handed to the game's Settings window as a canvas (Game Menu > Options > AddOns > Mapzeroth, or `/mapzeroth settings`). The theme is chosen there, not on the main window, and changes live. The loading screen time feeds the player context, so it applies to the next route planned.

## 6. Multi-route performance (your #6)

Not a data-model question, so deferred until the schema above is settled and we know real graph sizes per ruleset — Forever's graph will likely be much smaller than Modern's, which changes how much this actually needs solving for that ruleset. Flagging now so it doesn't get lost: worth profiling the current TSP-ish approach at 20-30 destinations before deciding whether to swap in a different heuristic (nearest-neighbor + 2-opt, or capping exact search and falling back to heuristic past some N).

## 7. Route-execution UX (your #7, #8)

Both are pathfinder-agnostic UI layer work, sit on top of whatever `RouteExecutionFrame`/`GPSNavigator` become in the rebuild:

- **Equip → use → re-equip**: a route step needs an `equipSlot` concept — remember what was in the slot before, equip the item, let the player use it, restore the original item after. Needs a small state machine per step, not a data-model change. Confirmed a real, not just theoretical, need once actual data went through `tools/gen_modern_abilities.py`: about a dozen of `Data/Modern/Abilities.lua`'s `Items` entries are worn equipment (Cloak of Coordination, Shroud of Cooperation, Wrap of Unity, the three faction tabards, Violet Seal of the Grand Magus, Signet of the Kirin Tor, the Pugilist's rings…) rather than a bag-usable toy/trinket like a hearthstone or consumable, which is all `GetKnownTeleports`'s current `Items` handling actually models — so right now those specific entries are converted as if simply carrying them is enough to use them, which isn't true until this step type exists. Not fixed as part of that pass (flagged, not silently left broken): which items on the list actually need the equip step, as opposed to being usable straight from a bag, needs checking per item, not assumed from the old `type` field.
- **Live progress indicator**: needs a per-frame (or throttled) distance-to-target read from whatever `LocationService` becomes, feeding a progress bar/arrow. Also UI-layer only.

Both are fine to design in detail once the core engine exists to build them against.

## 8. File & module map

```
Mapzeroth/
  Mapzeroth_Mainline.toc      -- Interface 120100+, loads Data/Modern/*
  Mapzeroth_Forever.toc       -- Interface  16001+, loads Data/Forever/*

  Libs/                        -- unchanged (LibStub, CallbackHandler, LibDataBroker, LibDBIcon)

  Constants.lua                -- ruleset detection (interfaceVersion check + override) at top;
                                   WALK_SPEED, TRAVEL_COSTS, TRAVEL_ICONS, HOLIDAYS.
                                   NO_FLY_MAPS removed (now a container flag, see World.lua below);
                                   display-text strings removed (now in Locales.lua)

  Locales.lua                  -- promoted from PR #25. All UI strings, incl. today's
                                   METHOD_DISPLAY_TEXT table
  NodeNames.lua                -- promoted from PR #25. Client-API name resolution for nodes
  MapNames.lua                 -- kept as-is. BuildDisplayName(name, mapID) zone-suffix enrichment

  World.lua                    -- NEW. Builds the Continent→Zone→Interior container tree from
                                   each node's `container` path; resolves inherited fly/indoor
                                   flags (walks up the tree, nearest override wins)
  MovementSpeed.lua             -- NEW. GetGroundSpeed(container); combines riding-skill rank +
                                   known ground-speed forms (from PlayerAbilities) with the
                                   container's indoor flag
  PlayerAbilities.lua           -- kept, extended: riding-skill rank, Travel Form / Ghost Wolf +
                                   Improved Ghost Wolf detection, alongside existing spell/toy/
                                   mount detection for teleports/hearthstones

  TravelGraph.lua               -- kept, rewritten: builds adjacency using World.lua (which nodes
                                   share a leaf container) + MovementSpeed (edge cost) + explicit
                                   Data edges. No more mapArtID/phaseCheckMapID special-casing.
  EdgeRequirements.lua           -- kept as-is — the requirementCheckers pattern already works
  Pathfinder.lua                 -- kept, mostly simplified: nodeID-keyed Dijkstra, plus a small
                                   {phaseGroup: side} state (only for phaseGroups that actually
                                   exist in the loaded data — none in Forever) threaded through
                                   the search and folded into the visited-dedup key. See §2.
  MultiRoute.lua                 -- kept; performance pass deferred (§6)

  LocationService.lua            -- kept
  WaypointService.lua            -- kept

  StepUtils.lua                  -- kept, extended: equip→use→re-equip step type (§7)
  GPSNavigator.lua                -- kept, extended: live progress-to-target indicator (§7)
  RouteExecutionFrame.lua          -- kept, extended: equip/use UI
  SettingsPanel.lua                 -- kept
  DestinationSelector.lua            -- kept
  GUI.lua                              -- kept
  MinimapButton.lua                    -- kept
  Commands.lua                          -- kept; add `/mz ruleset forever|modern|auto`
  Mapzeroth.lua                          -- kept; PLAYER_LOGIN init, SavedVariables setup

  Data/
    Modern/
      Nodes_EasternKingdoms.lua, Nodes_Kalimdor.lua, Nodes_Outland.lua, Nodes_Northrend.lua,
      Nodes_Pandaria.lua, Nodes_BrokenIsles.lua, Nodes_Draenor.lua, Nodes_DragonIsles.lua,
      Nodes_KhazAlgar.lua, Nodes_Shadowlands.lua, Nodes_Zandalar.lua, Nodes_Argus.lua,
      Nodes_BfA.lua, Nodes_IsolatedMaps.lua
        -- each file holds addon.Nodes[...] entries (id, container, mapID, x, y — no name/
        -- faction) AND addon.Containers[...] flag overrides (fly/indoor) for that continent's
        -- zones/interiors, since they're authored and edited together
      Edges.lua                 -- all edges for Modern, incl. requirements (faction lives here)
      Abilities.lua              -- class teleports, hearthstones, toys valid in Modern
      RidingSkills.lua           -- trivial/near-constant — ground speed is normalized in retail

    Forever/
      Nodes_EasternKingdoms.lua, Nodes_Kalimdor.lua, ...   -- pre-Cataclysm geometry; likely
        fewer continents active at launch, growing as Forever's own content phases ship
      Edges.lua
      Abilities.lua               -- whatever teleports/hearthstones/toys actually exist pre-Cata
      RidingSkills.lua            -- Apprentice (+60%) / Journeyman (+100%) — confirmed values
```

**New files:** `World.lua`, `MovementSpeed.lua` — the two pieces of engine logic that didn't exist in any form before (container tree + inherited flags, and ground-speed resolution).

**Promoted from unmerged branch:** `NodeNames.lua`, `Locales.lua` (PR #25) — now core, not optional.

**Simplified:** `TravelGraph.lua` loses the `mapArtID`/`phaseCheckMapID` special-casing entirely — auto-edge generation doesn't know phase exists. `Pathfinder.lua` keeps a phase-state, but small and scoped (§2) instead of sprawled across files; the composite-state dedup bug is fixed by construction, not patched. `Constants.lua` loses `NO_FLY_MAPS` and the display-text strings.

**Unchanged in spirit:** `EdgeRequirements.lua`, `MultiRoute.lua`, `LocationService.lua`, `WaypointService.lua`, and the UI layer (`SettingsPanel.lua`, `DestinationSelector.lua`, `GUI.lua`, `MinimapButton.lua`, `Commands.lua`, `Mapzeroth.lua`) — these carry forward with no structural change from this pass, only consuming the new node/edge/name-resolution shapes.

## 9. Headless pathfinding prototype

Before writing any real Lua or game data, the container/graph/pathfinder model got built as a standalone Python harness under `prototype/` — no WoW client, no Lua interpreter needed on this machine, just the logic. It mirrors the eventual file split (`world.py` ~ `World.lua`, `graph.py` ~ `TravelGraph.lua`, `pathfinder.py` ~ `Pathfinder.lua`, `movement.py` ~ `MovementSpeed.lua`), plus `scenario.py` with a small hand-built dataset (two continents, the Darkshore/Teldrassil phase wrinkle, an interior, a continent crossing) and a set of pass/fail assertions.

Run it with:

```bash
python prototype/scenario.py
```

It caught two real bugs before either would have reached actual game data: the reverse-edge helper in the graph builder wasn't propagating `overridesPhase` (Zidormi's edge would have silently lost its override in one direction), and the phase-as-a-place model was missing search-time state entirely (§2's neutral-zone-detour finding). All checks pass as of this pass; worth re-running and extending as more of the model gets nailed down, before it ever becomes real Lua.

## Open questions

1. **CurseForge packaging** — does the packager already recognize a "Forever" flavor keyword for multi-toc builds, or does that need a manual/custom toc setup? Not urgent — check when ready to publish.
2. **Modern needs at least inn data for the hearthstone/Astral Recall bind to mean anything.** `addon:FindHearthNode` (used to build `ctx.hearthNode`) snaps a bind position or name to a known settlement/inn node; Modern's converted data has none of Forever's POI pipeline (no inns, banks, trainers — see docs/DESIGN.md section 5a, which is Forever-only so far), so `ctx.hearthNode` can never resolve for a Modern character and the two abilities in `Data/Modern/Abilities.lua`'s `Hearthstones` list (the real Hearthstone item, Astral Recall) are consequently unusable in practice even though they convert cleanly. Doesn't need Forever's whole Wowhead-scrape pipeline — just enough settlement/inn data to give `FindHearthNode` something to snap to.
