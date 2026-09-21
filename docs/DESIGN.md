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

**Cities have entrances.** Cities are enclosed, with one or a few ways in, while towns are open on all sides, so a city gets `entrance` places ("Dalaran Entrance") as destinations for getting to the city itself. Dalaran is the first: a city on a zone map (Alterac Mountains), named by area 279, with one entrance. The six capitals are on their own maps and their gates are already the border crossings between city and zone. Those crossings could serve as their entrances, or entrances could be captured for them.

**Two layers for trainers.** The routing node is one *place* (a cluster of trainers of one type: "Stormwind Tailoring Trainer"). Under it, `npcs` lists each real trainer NPC with the spell IDs they teach. Nothing is merged in the data; the grouping is only how the picker lays it out and how routing picks a stop.

**What a trainer teaches decides who needs it:**

- Class trainers teach class abilities to their own class only. Weapon skills are taught only by weapon masters (a Wowhead map's "weapon trainer" flag is not the same thing).
- Profession trainers are identified by the highest rank they teach (Apprentice → Artisan), read from the rank spells they teach.

**Picker default (`Trainers.lua`, `Trainers:IsRelevant(node, ctx)`).** The picker shows a trainer place by default only if it can still do something for this player:

| Trainer | Shown by default when |
|---|---|
| Class | it is the player's own class |
| Weapon master | some NPC teaches a weapon skill the player's class may learn (`addon.ClassWeapons`) and the player doesn't know it |
| Profession | the player has the profession and some NPC there teaches a rank they don't know yet, so an Expert leaves a Journeyman trainer behind |
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

## 6. Multi-route performance (your #6)

Not a data-model question, so deferred until the schema above is settled and we know real graph sizes per ruleset — Forever's graph will likely be much smaller than Modern's, which changes how much this actually needs solving for that ruleset. Flagging now so it doesn't get lost: worth profiling the current TSP-ish approach at 20-30 destinations before deciding whether to swap in a different heuristic (nearest-neighbor + 2-opt, or capping exact search and falling back to heuristic past some N).

## 7. Route-execution UX (your #7, #8)

Both are pathfinder-agnostic UI layer work, sit on top of whatever `RouteExecutionFrame`/`GPSNavigator` become in the rebuild:

- **Equip → use → re-equip**: a route step needs an `equipSlot` concept — remember what was in the slot before, equip the item, let the player use it, restore the original item after. Needs a small state machine per step, not a data-model change.
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
