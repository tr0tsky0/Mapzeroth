# Roads and city streets

Walks are drawn (and walking times worked out) along roads instead of straight lines. There are two kinds of data,
both Forever only:

| What | Shipped file | Made by | Source |
|---|---|---|---|
| Zone roads | `Data/Forever/Roads.lua` | `gen_roads.py` | the game's own terrain (road textures) |
| Capital streets | `Data/Forever/CityPaths.lua` | `city/gen_city_paths.py` | lines you drew, `city/<city>.json` |
| Steep ground | `Data/Forever/Steep.lua` | `gen_steep.py` (after `gen_roads.py`) | the game's own terrain (heights) |

After changing any of them, run `python tools/dump_geometry.py` (about 2 minutes), because walking times between
nodes are worked out from the roads. It writes `Data/Forever/Geometry.lua` exactly as `/mzr dumpgeometry` would in
game, placing maps from the game files' own map table. Each map's road factor comes from the walks, and walks without
a road use the factors already in the file, so after a big change run it twice; the second run settles them.

## Adding a missing road link in a zone

Some ways aren't painted on the terrain: bridges and paths that are models. Draw them by hand and `gen_roads.py`
adds them to that continent's roads. Zones with an editor are listed in `links/zones.py` (Zephras Isle so far).

1. Build the editor: `python tools/roads/links/make_editor.py zephras`. The picture is the zone's minimap, with
   today's roads in cyan; they're only shown, not edited.
2. Open it: ask Claude to start the "road-links" preview, or serve `tools/roads/links/editors` on any port.
3. Draw the missing links in red, the same way as city streets. A line's end within 25 yd of a cyan road joins it
   there, so start and end each link on the road it joins.
4. Save `.json` to `tools/roads/links/zephras.json` (or ask Claude to read it from the page), then run
   `python tools/roads/gen_roads.py --only 2991`, which rebuilds Zephras alone in a few seconds.

### Roads that shouldn't be there

Some textures on the list also paint riverbanks or odd patches, and these come out as roads. Build the remove page
with `python tools/roads/links/make_editor.py <zone> --drop` and draw a closed shape round each false road: every
stretch of road inside one is dropped (`<zone>_drop.json`). Draw only shapes there; links go on the zone's own page.

### Big water

A big lake that walks shouldn't run straight across: build the water page with
`python tools/roads/links/make_editor.py zephras --water`, trace each shore round and back to its first point, and
save as `tools/roads/links/zephras_water.json`. `gen_roads.py` writes the shapes into `Roads.lua` (`addon.RoadWater`).
Open ground through water scores `RoadNet.WATER` (3) times normal open ground in choosing the way, and a swum yard
counts `RoadNet.SWIM` (1.5) yards of time. Leave rivers and streams out: they're crossed in a moment.

## Fixing a city's streets

The six capitals' streets were drawn by hand over each city's world map art (Stormwind, Ironforge, Darnassus,
Orgrimmar, Thunder Bluff, Undercity). To change one:

1. **If the editors aren't there yet** (`city/editors/` is empty, such as on a fresh clone or the laptop), build them.
   This needs WoW: Forever installed at `D:\World of Warcraft`.

   ```
   python tools/roads/city/mapart.py stormwind
   python tools/roads/city/make_editor.py stormwind
   ```

   The city names are `stormwind`, `ironforge`, `darnassus`, `orgrimmar`, `thunder_bluff` and `undercity`. The art
   and the editor pages are Blizzard's art, so they're gitignored and never pushed.
2. **Open the editor.** In the Claude app, ask Claude to start the "city-streets" preview; it's in
   `.claude/launch.json` in the Mapzeroth folder. Or serve the folder yourself:

   ```
   python -m http.server 8765 --directory tools/roads/city/editors
   ```

   Then go to `http://localhost:8765/editor_<city>.html`.
3. **Edit.**
   - Draw mode (D): click to place points, then Enter. Start or end a line on an existing one to join them.
   - Edit mode (E): drag points, select a line and press Delete, right-click a point to remove it, or Shift-click on a
     line to add a point.
   - Ctrl+Z undoes.
   - Edits save in that browser by themselves.
   - Lines join only where they share a point. Crossings without one don't join, which suits a bridge over a path or
     two levels of a city. They show as magenta rings (the Crossings box toggles them); in Edit mode, click a ring to
     join the two lines there.
   - A yellow ring marks a place that's almost as near a second street (dashed line) as its nearest one, where the two
     streets only meet a long way round. A walk could start on the wrong side of a wall, so draw a spoke from the street
     you'd really reach it by.
   - Grey markers are places whose walks don't use the streets (Undercity's ruins entrance and lift tops); they're never
     ringed, and nothing needs drawing to them.
   - Mapzeroth's own places on that map show as markers (the Nodes box toggles them): orange for entrances, lifts,
     flight masters, docks and portals, blue for the rest. Lines should reach them. A lift goes straight up, so its top
     is at its marker too: join the lift marker to the path it arrives on.
4. **Save.** Press **Save .json** and put the file in `tools/roads/city/` as `<city>.json`, replacing the old one.
   Or ask Claude to read the lines straight from the open page.
5. **Regenerate**, then do the geometry dump in game:

   ```
   python tools/roads/city/gen_city_paths.py
   ```

Drawing tips:

- Draw the ways people walk: rings, lanes through districts, and above all the bridges, tunnels, gates and lifts that
  join them.
- In a big open room, draw one line through it between its doors (a cross or star for more doors), not a loop. A walk
  leaves the line and goes straight to a spot that's off it.

**Watch out:** an editor opens with whatever that browser saved last, and only falls back to `<city>.json` when it has
nothing saved. If the `.json` changed somewhere else (on the laptop, say), press **Reset to seed** to load it.

**Walking times in cities:** a city with a measured factor in `Data/Forever/PathFactors.lua` (Stormwind, Ironforge,
Undercity, Thunder Bluff, Orgrimmar) keeps that factor for its walking times. Its streets are only drawn. In two live
checks, street lengths came out well short of the real walk: Stormwind flight master to the harbour was ×1.15 against
a measured ×1.70, and Ironforge flight master to the tram ×1.00 against ×1.98. Darnassus has no measurement, so its
walks are timed by its streets.

**Undercity:** draw the underground only. Walks in the Ruins of Lordaeron above it skip the streets (`SKIP_CONTAINERS`
in `city/cities.py`).

## Zone roads

`python tools/roads/gen_roads.py` rebuilds `Roads.lua` from the terrain. It takes about 7 minutes and writes a report
to `tools/roads_report.txt`.

It covers Eastern Kingdoms, Kalimdor and Zephras Isle (its own world, instance 2991). A new world goes into `CONTINENTS` in `gen_roads.py`; its terrain file (WDT) is listed in the game's Map table (see `road_textures.json`).

Which ground textures count as road is set per continent in `road_textures.json`. That list was made with `autopick.py`
(it scores each texture by how thin its painted shape is) and `review.py` (it renders the shortlist over the minimap),
then checked by eye. Lava, cliff edges and riverbanks are thin too, so that check is needed.

## Steep ground

`python tools/roads/gen_steep.py` rebuilds `Steep.lua` from the terrain's heights: ground over `LIMIT` (50) degrees,
hilltops ringed by it filled in, specks dropped, and a corridor along every road kept clear (so run it after
`gen_roads.py`). Open ground over steep cells scores `RoadNet.STEEP` (10) times normal open ground in choosing the
way, so walks go round mountains by road or valley instead of over them. Only the terrain is seen: walls, rocks and
buildings are models.

`python tools/roads/gen_steep.py --view 31 37 40 45 0` renders those tiles of a continent (here Dun Morogh) with the
steep cells in red and roads in cyan to `tools/roads/steep_view.png`.

## In game

- `/mzr roads` shows the nearest road to you (a few yards when you stand on one) and every road and city graph.
- `/mzr roads <nodeA> <nodeB>` shows the road way between two nodes.
- In a capital, a walk joins the street nearest each end and keeps to the streets: they are the only ways through, so
  neither open-ground shortcuts nor the Walking routes setting apply there.
- The **Walking routes** setting (from across country to roads) only changes how walks are drawn. Their shown times
  follow the drawn line; routes are still chosen on the shipped times.
