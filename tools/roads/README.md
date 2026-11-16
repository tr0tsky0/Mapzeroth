# Roads and city streets

Walks are drawn (and walking times worked out) along roads instead of straight lines. There are two kinds of data,
both Forever only:

| What | Shipped file | Made by | Source |
|---|---|---|---|
| Zone roads | `Data/Forever/Roads.lua` | `gen_roads.py` | the game's own terrain (road textures) |
| Capital streets | `Data/Forever/CityPaths.lua` | `city/gen_city_paths.py` | lines you drew, `city/<city>.json` |

After changing either one, run `/mzr dumpgeometry` in game and paste the export over `Data/Forever/Geometry.lua`,
because walking times between nodes are worked out from the roads.

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

## In game

- `/mzr roads` shows the nearest road to you (a few yards when you stand on one) and every road and city graph.
- `/mzr roads <nodeA> <nodeB>` shows the road way between two nodes.
- The **Walking routes** setting (from across country to roads) only changes how walks are drawn. Their shown times
  follow the drawn line; routes are still chosen on the shipped times.
