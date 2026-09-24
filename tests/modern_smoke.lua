-- A structural smoke test for the Modern conversion pass (tools/gen_modern_nodes.py,
-- gen_modern_edges.py, match_modern_taxi_nodes.py): not a real coverage suite (no
-- Abilities/POI data yet -- see Data/Modern/CONVERSION_NOTES.md), just "does the data load
-- into the real engine without falling over, and does grouping/routing/naming look sane."
-- Run against the Modern TOC, not the default one:
--   python tests/harness.py --toc Mapzeroth-Rebuild_Mainline.toc modern_smoke

useTestDistances()
addon.World:Build()

-- The whole point of renaming a flight master to TAXI_<realID> (tools/match_modern_taxi_nodes.py):
-- it should get a free, properly-localized name from the client, the same as Forever's,
-- instead of showing its raw id. Ironforge's flight master matched with high confidence
-- (see tools/modern_source/flight_node_matches.tsv) and became TAXI_6.
local ironforgeFlight = addon.World:GetNode("TAXI_6")
check(ironforgeFlight, "Ironforge's flight master carried its real taxi id through the rename")
local maps = {
    [87] = { name = "Elwynn Forest", mapType = 3, parentMapID = 13 },
    [13] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 946 },
    [946] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
C_Map = { GetMapInfo = function(id) return maps[id] end }
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 13 then return { { nodeID = 6, name = "Ironforge, Dun Morogh" } } end
    return {}
end }
check(addon:GetNodeName("TAXI_6") == "Ironforge Flight Master",
    "a renamed flight master resolves to the client's own name (place without its zone), not its raw id: " .. addon:GetNodeName("TAXI_6"))

-- Same idea for a dungeon entrance (tools/match_modern_instance_nodes.py, matched by name
-- against the real JournalInstance table): The Stonecore matched to journalInstanceID 67.
check(addon.World:GetNode("INSTANCE_THE_STONECORE"), "The Stonecore carried its real journal instance id through the rename")
EJ_GetInstanceInfo = function(id) if id == 67 then return "The Stonecore" end end
check(addon:GetNodeName("INSTANCE_THE_STONECORE") == "The Stonecore",
    "a renamed dungeon entrance resolves via the Dungeon Journal, not its raw id: " .. addon:GetNodeName("INSTANCE_THE_STONECORE"))

local total, containers = 0, {}
addon.World:ForEachNode(function(node)
    total = total + 1
    local c = addon.World:GetNodeContainer(node.id)
    check(c, "every node resolves to a container: " .. node.id)
    containers[c.path] = (containers[c.path] or 0) + 1
end)
check(total == 1257, "every node made it into the tree (1213 converted + 20 hand-added + 24 city centres): " .. total)
check(#addon.World:GetDuplicateNodeIDs() == 0, "no id collided going into the flat node table: "
    .. table.concat(addon.World:GetDuplicateNodeIDs(), ", "))

-- Stormwind (map 84) is a real one to eyeball: several outdoor nodes plus its own interior
-- container (the several portal rooms grouped together, per the conversion's known
-- simplification -- see CONVERSION_NOTES.md).
check(containers["ek_overworld.map84"] and containers["ek_overworld.map84"] > 1,
    "Stormwind's outdoor container holds more than one node")
check(containers["ek_overworld.map84.interior"] == 17, "and its interior container holds the 17 interior nodes: "
    .. tostring(containers["ek_overworld.map84.interior"]))

-- A phase-tagged pair (Darkshore) landed in two different containers, not one -- the whole
-- point of the _art<N> suffix (see the script's docstring): nothing should claim they're
-- walkably joined.
local darkshorePresent = addon.World:GetNodeContainer("DARKSHORE_ZIDORMI_PRESENT")
local darkshorePast = addon.World:GetNodeContainer("DARKSHORE_ZIDORMI_PAST")
check(darkshorePresent and darkshorePast and darkshorePresent.path ~= darkshorePast.path,
    "Darkshore's two phase-states are different containers: " .. tostring(darkshorePresent and darkshorePresent.path)
    .. " vs " .. tostring(darkshorePast and darkshorePast.path))

-- The fly/indoor container flags this pass wrote (Data/Modern/Containers.lua) actually
-- resolve where expected.
check(addon.World:GetFlag(addon.World:GetContainer("quelthalas.map110"), "fly") == false,
    "Silvermoon City is marked no-fly")
check(addon.World:GetFlag(addon.World:GetContainer("ek_overworld.map84.interior"), "indoor") == true,
    "Stormwind's interior is marked indoor")
check(addon.World:GetFlag(addon.World:GetContainer("ek_overworld.map15"), "fly") ~= false,
    "an ordinary outdoor zone is not marked no-fly")

-- With no Edges data yet, the graph builder shouldn't error -- and geometry alone already
-- gives real ground-walk connectivity within a shared container (no authored edges needed
-- for two nodes on the same map to imply a walk between them).
local ctx = makeCtx({ faction = "Alliance" })
local graph = addon.TravelGraph:Build(ctx)
check(graph and graph.adjacency, "the graph builds with no edges data at all")
local stormwindNeighbors = graph.adjacency["STORMWIND_MAGE_TOWER_ENTRANCE"]
check(stormwindNeighbors and #stormwindNeighbors > 0,
    "a Stormwind outdoor node walks to at least one other Stormwind outdoor node, from geometry alone")

-- A real portal route: cost 0 + the loading tax, per the edge-conversion cost rules.
local toBoralus = addon.Pathfinder:FindPath(graph, "PORTAL_STORMWIND_BORALUS", "BORALUS")
check(toBoralus and #toBoralus.steps == 1 and toBoralus.steps[1].method == "portal",
    "a converted portal edge actually routes")
check(math.abs(toBoralus.cost - ctx.loadingScreenTax) < 0.01,
    "cost 0 plus the loading tax, nothing extra: " .. tostring(toBoralus and toBoralus.cost))

-- The two new requirement checkers this pass needed (EdgeRequirements.lua): holiday and
-- anyQuest, exercised directly rather than only through a route.
local noHoliday = makeCtx({})
local inHoliday = makeCtx({ holidays = { love_is_in_the_air = true } })
check(not addon:MeetsRequirements({ holiday = "love_is_in_the_air" }, noHoliday), "holiday gate closed by default")
check(addon:MeetsRequirements({ holiday = "love_is_in_the_air" }, inHoliday), "and open when ctx says it's live")
local neitherQuest = makeCtx({})
local oneQuest = makeCtx({ quests = { [47098] = true } })
check(not addon:MeetsRequirements({ anyQuest = { 50769, 47098 } }, neitherQuest), "anyQuest: neither done, closed")
check(addon:MeetsRequirements({ anyQuest = { 50769, 47098 } }, oneQuest), "anyQuest: either one is enough")

-- The old `mapArtID` gate is not a requirement any more: the generator turns it into the edge's `inPhase`.
do
    local gated = 0
    for _, edge in ipairs(addon.Edges) do
        check(not (edge.requirements and edge.requirements.mapArtID), "no edge keeps a mapArtID requirement")
        if edge.inPhase then gated = gated + 1 end
    end
    check(gated == 18, "18 edges are gated on a phase: " .. gated)
end

-- Abilities (tools/gen_modern_abilities.py): a real converted Mage teleport seeds the
-- search from anywhere, exactly like Forever's own Moonglade teleport does.
local mage = makeCtx({ faction = "Alliance", class = "MAGE", spells = { 3561 } })
local mageGraph = addon.TravelGraph:Build(mage)
local viaTeleport = addon.Pathfinder:FindPath(mageGraph, "IRONFORGE", "STORMWIND_PORTAL_ROOM_LOWER")
check(viaTeleport and viaTeleport.steps[1].method == "teleport",
    "a Mage teleports to Stormwind from anywhere: " .. tostring(viaTeleport and viaTeleport.steps[1].method))
local noSpellGraph = addon.TravelGraph:Build(makeCtx({ faction = "Alliance", class = "MAGE" }))
local noTeleport = addon.Pathfinder:FindPath(noSpellGraph, "IRONFORGE", "STORMWIND_PORTAL_ROOM_LOWER")
check(not noTeleport or noTeleport.steps[1].method ~= "teleport", "without the spell, no teleport")

-- A dungeon-teleport toy (an Item, itemID-gated, fixed destination) that only made it into
-- the data because its old destination got renamed to a real INSTANCE_<id> first.
check(addon.World:GetNode("INSTANCE_THE_STONECORE"), "The Stonecore (from the earlier instance-rename pass) still exists")
local karazhanSeal = makeCtx({ faction = "Alliance", items = { 142469 } })
local viaItem = addon.Pathfinder:FindPath(addon.TravelGraph:Build(karazhanSeal), "IRONFORGE", "KARAZHAN")
check(viaItem and viaItem.steps[1].method == "teleport",
    "an Item ability (Violet Seal of the Grand Magus) routes to a fixed destination too")

print(string.format("modern_smoke: %d nodes, %d distinct containers", total, (function()
    local n = 0
    for _ in pairs(containers) do n = n + 1 end
    return n
end)()))

-- Hand additions (tools/modern_manual.py): the Lycaneum's portal room is an interior, reached on foot from
-- its outside entrance, not by a 2 s hop from the dungeon entrance next door.
check(addon.World:GetNode("LYCANEUM_ENTRANCE"), "the hand-added Lycaneum entrance is in the tree")
check(addon.World:GetFlag(addon.World:GetContainer("ek_overworld.map2649"), "indoor") == true, "the Lycaneum is marked indoor")
local lycGraph = addon.TravelGraph:Build(makeCtx({ faction = "Alliance" }))
local flyIntoLycaneum, walkOut = false, false
for from, list in pairs(lycGraph.adjacency) do
    for _, e in ipairs(list) do
        if e.method == "fly" and (from == "PORTAL_MAGISTERS_SILVERMOON" or e.to == "PORTAL_MAGISTERS_SILVERMOON") then flyIntoLycaneum = true end
        if from == "LYCANEUM_ENTRANCE" and e.to == "PORTAL_MAGISTERS_SILVERMOON" and e.method == "walk" and e.cost > 0 then walkOut = true end
    end
end
check(not flyIntoLycaneum, "nothing flies to or from the Lycaneum's portal room (an interior: no 2 s hop into it)")
check(walkOut, "the way in is a walk from its outside door, costed from distance")

-- A toy is owned through the toy box, not the bags (the old data's type = "toy", carried through as
-- toy = true): Personal Key to the Arcantina is one, and the bag-count check never saw it.
local withKey = addon.TravelGraph:Build(makeCtx({ faction = "Alliance", toys = { 253629 } }))
local keyRoute = addon.Pathfinder:FindPath(withKey, "IRONFORGE", "ARCANTINA_ENTRANCE")
check(keyRoute and keyRoute.steps[1].method == "teleport" and keyRoute.steps[1].source.itemID == 253629,
    "a character who owns the toy can use it from anywhere: " .. tostring(keyRoute and keyRoute.steps[1].method))
-- (An unlearned toy still in the bags is an ordinary usable item, so the bag count still counts too.)

-- The live geometry pass (used whenever the shipped Geometry.lua is stale) must still link a continent with
-- hundreds of flyable nodes: it once skipped any continent over a cap, so a stale file left Silvermoon with no
-- way to fly to Eversong or Zul'Aman ("no route" to Windrunner Spire, Den of Nalorakk, Maisara Caverns).
addon.Geometry, addon.GeometryMeta = nil, nil
addon.World:Build()
local live = addon.TravelGraph:Build(makeCtx({ faction = "Alliance" }))
local function flies(from, to)
    for _, e in ipairs(live.adjacency[from] or {}) do
        if e.to == to and e.method == "fly" then return true end
    end
    return false
end
check(flies("PORTAL_SILVERMOON_ARCANTINA", "INSTANCE_WINDRUNNER_SPIRE") or flies("PORTAL_SILVERMOON_ARCANTINA", "PORTAL_EVERSONG_HARANDAR"),
    "the live pass gives Eastern Kingdoms its fly edges, however many flyable nodes it has")

-- Oribos: the flight master is on the Ring, a floor (map) of its own, reached by the pad on the main floor. The old
-- data's one "walk" between the two maps couldn't be measured and was dropped; the pad route replaces it, so the
-- flights out of Oribos (to Maldraxxus, Bastion, Ardenweald, Revendreth) are reachable.
addon.World:Build()
useTestDistances()
local oribos = addon.TravelGraph:Build(makeCtx({ faction = "Alliance" }))
local direct, padCost = false, nil
for _, e in ipairs(oribos.adjacency["ORIBOS"] or {}) do
    if e.to == "TAXI_2395" then direct = true end
end
for _, e in ipairs(oribos.adjacency["ORIBOS_TRANSFERENCE_PAD"] or {}) do
    if e.to == "ORIBOS_TRANSFERENCE_RING" and e.method == "portal" then padCost = e.cost end
end
check(not direct, "no one-hop walk from the Oribos entrance to the flight master any more")
check(padCost == 3, "the pad is a short hop with no loading screen: " .. tostring(padCost))
local plaguefall = addon.Pathfinder:FindPath(oribos, "ORIBOS", "INSTANCE_PLAGUEFALL")
local viaPad = false
for _, step in ipairs(plaguefall and plaguefall.steps or {}) do
    if step.to == "ORIBOS_TRANSFERENCE_RING" then viaPad = true end
end
check(plaguefall and viaPad, "Plaguefall from Oribos goes up by the pad, then the flight master")

-- No route because of a flight we can't be sure the player has found: the panel says which, not just "no route".
local unsure = makeCtx({ faction = "Alliance" })
setFlights(unsure, function() return nil end)
local session = addon.Journey:Build(unsure, { id = "ORIBOS", mapID = 1670, x = 0.203, y = 0.503 })
local plan, why = addon.Journey:Plan(session, "INSTANCE_CASTLE_NATHRIA")
check(plan == nil and why and why.nodeID and not why.known, "no route, with the flight in the way named: " .. tostring(why and why.nodeID))
check(addon.Journey:HintText(why):find("flight"), "and a sentence for it: " .. tostring(addon.Journey:HintText(why)))
setFlights(unsure, function(id) if id == "TAXI_2514" then return false end return true end)
session = addon.Journey:Build(unsure, { id = "ORIBOS", mapID = 1670, x = 0.203, y = 0.503 })
local _, known = addon.Journey:Plan(session, "INSTANCE_CASTLE_NATHRIA")
check(known and known.known and known.nodeID == "TAXI_2514", "a flight a window said isn't found is named as such")

-- "Assume flight points are found" (ctx.flightUsable): a flight point no window has said anything about is used, and
-- the route says so; one a window reported as not found never is.
local assuming = makeCtx({ faction = "Alliance" })
setFlights(assuming, function(id) if id == "TAXI_2519" then return false end return nil end, true)
local start = { id = "ORIBOS", mapID = 1670, x = 0.203, y = 0.503 }
local assumedPlan = addon.Journey:Plan(addon.Journey:Build(assuming, start), "INSTANCE_CASTLE_NATHRIA")
check(assumedPlan and assumedPlan.assumed and #assumedPlan.assumed >= 1, "an unconfirmed flight is used, and the plan says which")
check(addon.Journey:AssumedText(assumedPlan):find("flight master"), "with a line telling the player how to confirm it")
local blocked = addon.Journey:Plan(addon.Journey:Build(assuming, start), "INSTANCE_SPIRES_OF_ASCENSION")      -- Spires of Ascension: only via TAXI_2519
check(blocked == nil, "but a flight a window said isn't found is never taken, however the setting reads")

-- A waypoint on Stormwind's map (the Trade District) is out in the open, not among the portal rooms: a map's
-- container prefers an outdoor one, though the portal rooms outnumber the streets. Teleport in, walk out of the
-- Mage Tower, fly to the waypoint -- not one "walk to the waypoint" from the portal room.
addon.World:Build()
local streets = addon.World:GetContainerForMap(84)
check(streets and not addon.World:GetFlag(streets, "indoor"), "Stormwind's map is the outdoor city: " .. tostring(streets and streets.path))
local waypoint = { id = "WAYPOINT_TEST", mapID = 84, x = 0.58, y = 0.70 }
local mageCtx = makeCtx({ faction = "Alliance", class = "MAGE", spells = { 3561 } })
local ironforgeNode = addon.World:GetNode("IRONFORGE")
local from = { id = "START_IF", mapID = ironforgeNode.mapID, x = ironforgeNode.x, y = ironforgeNode.y }
local session = addon.Journey:Build(mageCtx, from, { waypoint })
local trip = addon.Journey:Plan(session, "WAYPOINT_TEST")
local kinds = {}
for _, step in ipairs(trip and trip.steps or {}) do kinds[#kinds + 1] = step.method end
check(trip and kinds[#kinds] == "fly", "the last leg to a waypoint in Stormwind is a flight: " .. table.concat(kinds, ","))
check(trip and #kinds >= 3 and kinds[1] == "teleport" and kinds[2] == "walk", "teleport, walk out of the tower, then fly: " .. table.concat(kinds, ","))

-- Bizmo's Brawlpub (where the Pugilist's ring lands you) is on a map of its own inside the Deeprun Tram's: walk to the
-- door, through to the tram (no loading screen), along to the stairs, up to Stormwind (one loading screen), then fly.
-- Nothing flies out of the interiors, and the ring's destination is where you actually land.
addon.World:Build()
local landing = addon.World:GetNode("BIZMOS_BRAWLPUB")
check(landing and landing.mapID == 500 and addon.World:GetFlag(addon.World:GetNodeContainer("BIZMOS_BRAWLPUB"), "indoor") == true,
    "Bizmo's Brawlpub is an indoor map of its own")
local brawlCtx = makeCtx({ faction = "Alliance" })
local brawlGraph = addon.TravelGraph:Build(brawlCtx)
local flyOutOfInterior = false
for _, id in ipairs({ "BIZMOS_BRAWLPUB", "TRAM_BIZMOS_TO", "TRAM_TO_BIZMOS", "DEEPRUN_TRAM_TO_STORMWIND" }) do
    for _, e in ipairs(brawlGraph.adjacency[id] or {}) do
        if e.method == "fly" then flyOutOfInterior = true end
    end
end
check(not flyOutOfInterior, "nothing flies out of the tram or the brawlpub")
local brawlStart = { id = "START_BRAWLPUB", mapID = landing.mapID, x = landing.x, y = landing.y }
local brawlTrip = addon.Journey:Plan(addon.Journey:Build(brawlCtx, brawlStart, { { id = "WAYPOINT_SW", mapID = 84, x = 0.58, y = 0.70 } }), "WAYPOINT_SW")
local brawlKinds = {}
for _, step in ipairs(brawlTrip and brawlTrip.steps or {}) do brawlKinds[#brawlKinds + 1] = step.method end
check(brawlTrip and brawlKinds[#brawlKinds] == "fly" and brawlKinds[1] == "walk", "out through the tram, then a flight: " .. table.concat(brawlKinds, ","))
-- Exactly one loading screen on the way (the tram to Stormwind; Bizmo's to the tram has none): the same trip priced
-- with the loading screens free is one tax cheaper.
local freeCtx = makeCtx({ faction = "Alliance", loadingScreenTax = 0 })
local freeTrip = addon.Journey:Plan(addon.Journey:Build(freeCtx, brawlStart, { { id = "WAYPOINT_SW", mapID = 84, x = 0.58, y = 0.70 } }), "WAYPOINT_SW")
check(math.abs((brawlTrip.cost - freeTrip.cost) - brawlCtx.loadingScreenTax) < 1e-6,
    "one loading screen on the way out: " .. tostring(brawlTrip.cost - freeTrip.cost))

-- A portal we have no name for is named for where it leads (the client's name for the map beyond), so the walk
-- to it reads "Walk to Orgrimmar Portal", not the name of the map it stands in; a room of several portals isn't.
maps[85] = { name = "Orgrimmar", mapType = 3, parentMapID = 12 }
maps[2393] = { name = "Silvermoon City", mapType = 3, parentMapID = 13 }
addon:ClearNodeNameCache()
check(addon:GetNodeName("PORTAL_SILVERMOON_ORGRIMMAR") == "Orgrimmar Portal",
    "a one-way-out portal is named for its destination: " .. addon:GetNodeName("PORTAL_SILVERMOON_ORGRIMMAR"))
check(addon:HasNodeName("PORTAL_SILVERMOON_ORGRIMMAR") == false, "though that isn't a name of its own, so the portal step still reads 'Take the portal to ...'")
check(addon:GetNodeName("SILVERMOON_PORTAL_ROOM") == "Silvermoon City", "a portal room with no single destination keeps its map's name: " .. addon:GetNodeName("SILVERMOON_PORTAL_ROOM"))

-- Silvermoon's portal room (Stormwind, Orgrimmar and where their portals arrive) is an interior with one door: in the
-- open you can fly up to the door, not into the room.
addon.World:Build()
local room = addon.World:GetNodeContainer("PORTAL_SILVERMOON_ORGRIMMAR")
check(room and addon.World:GetFlag(room, "indoor") == true, "the portal room is indoor")
check(addon.World:GetNodeContainer("SILVERMOON_PORTAL_ROOM").path == room.path
    and addon.World:GetNodeContainer("SILVERMOON_PORTAL_ROOM_EXIT").path == room.path, "with its arrival point and inner door")
check(not addon.World:GetFlag(addon.World:GetNodeContainer("PORTAL_SILVERMOON_HARANDAR"), "indoor"), "the street's other portals stay outside")
local roomGraph = addon.TravelGraph:Build(makeCtx({ faction = "Horde" }))
local flyIntoRoom = false
for from, list in pairs(roomGraph.adjacency) do
    for _, e in ipairs(list) do
        if e.method == "fly" and (addon.World:GetNodeContainer(e.to) == room or addon.World:GetNodeContainer(from) == room) then flyIntoRoom = true end
    end
end
check(not flyIntoRoom, "nothing flies into or out of the portal room")
local streetStart = { id = "START_SILVERMOON", mapID = 2393, x = 0.60, y = 0.75 }
local toRoom = addon.Journey:Plan(addon.Journey:Build(makeCtx({ faction = "Horde" }), streetStart), "PORTAL_SILVERMOON_ORGRIMMAR")
local roomKinds = {}
for _, step in ipairs(toRoom and toRoom.steps or {}) do roomKinds[#roomKinds + 1] = step.method end
check(toRoom and roomKinds[#roomKinds] == "walk", "the last stretch to the portal is on foot, through the door: " .. table.concat(roomKinds, ","))

-- Where the player starts, in the open where flying is allowed: mount up and fly to an outdoor node in range (the mount
-- takes MOUNT_SECONDS), but only for a flight of at least MIN_FLY_SECONDS; a nearer node is a walk.
local sw = addon.World:GetNode("STORMWIND_MAGE_TOWER_ENTRANCE")
local openStart = { id = "START_OPEN", mapID = sw.mapID, x = sw.x, y = sw.y }
local openGraph = addon.TravelGraph:Build(makeCtx({ faction = "Alliance" }))
addon.TravelGraph:AddStart(openGraph, makeCtx({ faction = "Alliance" }), openStart)
local flyTo, walkTo = {}, {}
for _, e in ipairs(openGraph.adjacency["START_OPEN"]) do
    if e.method == "fly" then flyTo[e.to] = e.cost else walkTo[e.to] = e.cost end
end
check(walkTo["STORMWIND_MAGE_TOWER_ENTRANCE"] and not flyTo["STORMWIND_MAGE_TOWER_ENTRANCE"], "standing at a node, it is a walk: no flight of a second or so")
local far = addon.World:GetNode("TAXI_2")
local farDistance = addon.TravelGraph.DistanceProvider(openStart, far)
check(farDistance / addon.FLY_SPEED >= addon.MIN_FLY_SECONDS and flyTo["TAXI_2"] ~= nil, "a node worth flying to is offered as a flight")
check(math.abs(flyTo["TAXI_2"] - (addon.MOUNT_SECONDS + farDistance / addon.FLY_SPEED)) < 1e-9, "priced at the mount plus the flight: " .. tostring(flyTo["TAXI_2"]))
check(addon.World:GetContainerForMap(2393) and not addon.World:GetFlag(addon.World:GetContainerForMap(2393), "indoor"), "a position on Silvermoon's map is out on the street")

-- Brawl'gar Arena (the Horde ring's destination) is an interior map of its own off Orgrimmar's street: the ring lands
-- you where you arrive, and the way out is one door to the street (a loading screen), then a flight.
addon.World:Build()
local arena = addon.World:GetNode("BRAWLGAR_ARENA")
check(arena and arena.mapID == 503 and addon.World:GetFlag(addon.World:GetNodeContainer("BRAWLGAR_ARENA"), "indoor") == true,
    "Brawl'gar Arena is an indoor map of its own")
local hordeCtx = makeCtx({ faction = "Horde" })
local arenaGraph = addon.TravelGraph:Build(hordeCtx)
local arenaFly = false
for _, id in ipairs({ "BRAWLGAR_ARENA", "BRAWLGAR_TO_ORGRIMMAR" }) do
    for _, e in ipairs(arenaGraph.adjacency[id] or {}) do
        if e.method == "fly" then arenaFly = true end
    end
end
check(not arenaFly, "nothing flies out of the arena")
local arenaStart = { id = "START_ARENA", mapID = arena.mapID, x = arena.x, y = arena.y }
local arenaTrip = addon.Journey:Plan(addon.Journey:Build(hordeCtx, arenaStart, { { id = "WAYPOINT_ORG", mapID = 85, x = 0.5, y = 0.6 } }), "WAYPOINT_ORG")
local arenaKinds = {}
for _, step in ipairs(arenaTrip and arenaTrip.steps or {}) do arenaKinds[#arenaKinds + 1] = step.method end
check(arenaTrip and arenaKinds[1] == "walk" and arenaKinds[#arenaKinds] == "fly", "walk out of the arena, then fly: " .. table.concat(arenaKinds, ","))

-- Speeds: a Modern character is taken to ride a ground mount outdoors (+100%: 14 yards a second) and to walk indoors
-- (7); flying is +750% (skyriding), 59.5 yards a second.
addon.World:Build()
local speedCtx = makeCtx({})
check(addon.WALK_SPEED == 7 and math.abs(addon.FLY_SPEED - 59.5) < 1e-9, "flying is 59.5 yards a second: " .. tostring(addon.FLY_SPEED))
check(math.abs(addon:GetGroundSpeed(addon.World:GetContainerForMap(84), speedCtx) - 14) < 1e-9, "mounted on the street: 14 yards a second")
check(math.abs(addon:GetGroundSpeed(addon.World:GetNodeContainer("SILVERMOON_PORTAL_ROOM"), speedCtx) - 7) < 1e-9, "on foot indoors: 7")

-- Phases (finding 3): Zidormi's zones are phase groups; the search follows the side the player is on.
do
    local World, PF = addon.World, addon.Pathfinder
    local function phaseOf(id) return World:GetPhase(World:GetNodeContainer(id)) end
    local g, s = phaseOf("DARKSHORE_ZIDORMI_PAST")
    check(g == "darkshore" and s == 67, "Zidormi's past Darkshore is darkshore side 67: " .. tostring(g) .. " " .. tostring(s))
    g, s = phaseOf("TAXI_27")
    check(g == "darkshore" and s == 67, "Rut'theran (Teldrassil) is on Darkshore's past side")
    check(phaseOf("TIRISFAL_ZIDORMI_PAST") == "tirisfal" and phaseOf("TIRISFAL_ZIDORMI_PRESENT") == "tirisfal",
        "past and present Tirisfal (two maps) are one group")
    local groups = 0
    for _ in pairs(World:GetPhaseGroups()) do groups = groups + 1 end
    check(groups == 7, "seven phase groups, one per Zidormi: " .. groups)

    -- The live side: one map's art decides it; past and present Tirisfal each always show their own art, so unknown.
    local arts = { [62] = 1176, [17] = 628, [18] = 19, [2070] = 1136 }
    local live = World:LivePhases(function(id) return arts[id] end)
    check(live.darkshore == 1176 and live.blasted_lands == 628, "Darkshore and Blasted Lands read as present")
    check(live.tirisfal == nil and live.uldum == nil, "a group the client can't tell apart stays unknown")

    -- Routes, as an Alliance player standing in Stormwind.
    local start = { id = "YOU_phase", mapID = 84, x = 0.50, y = 0.60 }
    local function route(art, goal)
        local ctx = makeCtx({ faction = "Alliance", mapArt = art })
        local session = addon.Journey:Build(ctx, start)
        return PF:FindPath(session.graph, start.id, goal, session.graph.phase), session.graph.phase
    end
    local function uses(r, method)
        for _, step in ipairs(r and r.steps or {}) do if step.method == method then return true end end
        return false
    end
    local function takes(r, from, to)
        for _, step in ipairs(r and r.steps or {}) do if step.from == from and step.to == to then return true end end
        return false
    end
    local past, phase = route({ [62] = 67 }, "DARNASSUS")
    check(phase.darkshore == 67, "the session starts on Darkshore's past side")
    check(past and not uses(past, "phaseswitch"), "Darnassus with Darkshore in the past: no Zidormi needed")
    local present = route({ [62] = 1176 }, "DARNASSUS")
    check(present and uses(present, "phaseswitch"), "Darnassus with Darkshore in the present: through Zidormi")
    check(not takes(present, "PORTAL_STORMWIND_DARNASSUS", "PORTAL_RUTTHERAN_EXODAR"),
        "and not by the Rut'theran portal, which only exists in the past")
    local unknown = route({}, "DARNASSUS")
    check(unknown and not uses(unknown, "phaseswitch"), "an unknown phase is open: no switch needed")

    -- inPhase on an edge whose ends aren't phased: the Stormwind portal to the Dark Portal goes to Outland in the past.
    local pastBL = route({ [17] = 18 }, "DARK_PORTAL_OUTLANDS")
    check(takes(pastBL, "STORMWIND_DARK_PORTAL_BL_NPC", "DARK_PORTAL_OUTLANDS"), "past Blasted Lands: the portal goes to Outland")
    local presentBL = route({ [17] = 628 }, "DARK_PORTAL_OUTLANDS")
    check(not takes(presentBL, "STORMWIND_DARK_PORTAL_BL_NPC", "DARK_PORTAL_OUTLANDS"), "present Blasted Lands: it doesn't")

    -- One switch per route at most: two Zidormi conversations would be a second phase state for the whole graph.
    local twice = false
    for _, r in ipairs({ past, present, unknown, pastBL, presentBL }) do
        local n = 0
        for _, step in ipairs(r and r.steps or {}) do if step.method == "phaseswitch" then n = n + 1 end end
        if n > 1 then twice = true end
    end
    check(not twice, "no route talks to Zidormi twice")

    -- The fly pass never joins two sides of one group, and does reach phased nodes. Checked on the geometry the
    -- client computes; the shipped Geometry.lua still has none into phased nodes until it is re-dumped.
    local function sidesJoined(graph)
        local bad, reach = {}, 0
        for from, steps in pairs(graph.adjacency) do
            for _, step in ipairs(steps) do
                if step.method == "fly" then
                    local ga, sa = phaseOf(from)
                    local gb, sb = phaseOf(step.to)
                    if gb then reach = reach + 1 end
                    if ga and ga == gb and sa ~= sb then bad[#bad + 1] = from .. " -> " .. step.to end
                end
            end
        end
        return bad, reach
    end
    local shipped, shippedMeta = addon.Geometry, addon.GeometryMeta
    addon.Geometry, addon.GeometryMeta = nil, nil
    World:Build()
    local bad, reach = sidesJoined(addon.TravelGraph:Build(makeCtx({ faction = "Alliance" })))
    check(#bad == 0, "no fly step joins two sides of a phase group: " .. tostring(bad[1]))
    check(reach > 0, "the computed fly mesh reaches phased nodes")
    addon.Geometry, addon.GeometryMeta = shipped, shippedMeta
    World:Build()
end

-- Finding 4a: a second build reuses the materialised geometry, and a route over it is the one the first build
-- gave (the flight hint builds a second graph for every click).
do
    local TG = addon.TravelGraph
    local plan = makeCtx({ faction = "Alliance" })
    local function portalRoomToIronforge(graph)
        local r = addon.Pathfinder:FindPath(graph, "STORMWIND_PORTAL_ROOM_LOWER", "IRONFORGE")
        check(r, "Stormwind's portal room reaches Ironforge")
        local out = {}
        for _, step in ipairs(r.steps) do out[#out + 1] = step.method .. ">" .. tostring(step.to) end
        return r.cost, table.concat(out, ",")
    end
    local first = TG:Build(plan)
    local costBefore, stepsBefore = portalRoomToIronforge(first)
    local materialised = TG.materialiseCount
    local second = TG:Build(plan)
    check(TG.materialiseCount == materialised, "the second build materialised nothing")
    local costAfter, stepsAfter = portalRoomToIronforge(second)
    check(costBefore == costAfter and stepsBefore == stepsAfter,
        "Stormwind portal room -> Ironforge is identical on the second build: " .. stepsBefore .. " vs " .. stepsAfter)
end

-- Finding 8: each flavour's classes, holidays and perks come from its own Data/<flavour>/Game.lua.
do
    local count = 0
    for _ in pairs(addon.CLASS_TOKENS) do count = count + 1 end
    check(count == 13 and addon.CLASS_TOKENS.EVOKER and addon.CLASS_TOKENS.DEATHKNIGHT, "Modern has its 13 classes")
    check(addon.HOLIDAYS and addon.HOLIDAYS.darkmoon_faire, "Modern knows the Darkmoon Faire")
    check(addon.FREQUENT_FLIER == nil, "Modern has no Frequent Flier perk")
    check(addon:GetFlightSpeedMultiplier(makeCtx({})) == 1, "and so no flight speed bonus")
end

-- Finding 7: Modern declares the expansion page and a flat mount bonus with no riding data.
check(addon.PICKER_LAYOUT == "expansions" and addon.CURRENT_EXPANSION, "Modern declares the expansion page")
check(addon.RidingSkills == nil and addon.DEFAULT_MOUNT_BONUS == 1.0, "Modern has a flat mount bonus, no riding data")

-- Finding 6: Modern's cities are Forever's shape. Each has a centre node in an outdoor container of its own map (Darnassus's
-- on Darkshore's past side), is routed to by that centre (no entrances: Modern flies), and can be reached.
do
    local World = addon.World
    for key, city in pairs(addon.Cities) do
        local centre = World:GetNode("CITY_" .. key:upper())
        check(centre and centre.kind == "settlement" and centre.city == key and centre.mapID == city.mapID,
            "city " .. key .. " has its centre node")
        check(not World:GetFlag(World:GetNodeContainer(centre.id), "indoor"), "and it is outdoors: " .. key)
    end
    check(World:GetPhase(World:GetNodeContainer("CITY_DARNASSUS")) == "darkshore", "Darnassus's centre is on Darkshore's past side")
    local ctx = makeCtx({ faction = "Alliance" })
    local session = addon.Journey:Build(ctx, { id = "YOU_city", mapID = 84, x = 0.5, y = 0.6 })
    local costs = addon.Pathfinder:FindCosts(session.graph, "YOU_city", session.graph.phase, {})
    for _, key in ipairs({ "ironforge", "exodar", "dalaran_broken_isles", "valdrakken", "dornogal", "boralus", "oribos" }) do
        check(costs["CITY_" .. key:upper()], "an Alliance player in Stormwind can reach " .. key)
    end
end

-- Nameless nodes matched to an area (tools/match_modern_area_nodes.py) are named by the client, like Forever's.
do
    local node = addon.World:GetNode("ZARALEK_CAVERN_MOLE")
    check(node and node.area == 14655, "the Zaralek Cavern mole machine spot is Obsidian Rest's area")
    local realAreaInfo = C_Map.GetAreaInfo
    C_Map.GetAreaInfo = function(id) if id == 14655 then return "Obsidian Rest" end end
    addon:ClearNodeNameCache()
    check(addon:GetNodeName("ZARALEK_CAVERN_MOLE") == "Obsidian Rest", "and named by it: " .. addon:GetNodeName("ZARALEK_CAVERN_MOLE"))
    C_Map.GetAreaInfo = realAreaInfo
    addon:ClearNodeNameCache()
end

-- Spots inside a city (where a teleport lands, a portal room) are tagged with it, as Forever's city POIs are, and
-- offered through the city instead of listed again. Silvermoon's inn is an inn: the hearthstone can go there.
do
    local World = addon.World
    check(World:GetNode("STORMWIND_PORTAL_ROOM_LOWER").city == "stormwind" and World:GetNode("BORALUS").city == "boralus",
        "spots inside a city carry its key")
    check(World:GetNode("SHRINE_OF_TWO_MOONS").city == "shrine_of_two_moons" and World:GetNode("TAXI_2544").city == nil,
        "a city on a zone's map takes only its own nodes, not the rest of the Vale")
    local listed = {}
    for _, entry in ipairs(addon.Destinations:Build(makeCtx({ faction = "Alliance" }))) do listed[entry.nodeID] = true end
    check(not listed.STORMWIND_PORTAL_ROOM_LOWER and not listed.BORALUS, "and they aren't listed on their own")
    local inn = World:GetNode("SILVERMOON_INN")
    check(inn.kind == "inn" and inn.city == "silvermoon", "Silvermoon's inn is an inn of the city")
    local realGetMapInfo = C_Map.GetMapInfo
    C_Map.GetMapInfo = function(id) if id == 2393 then return { name = "Silvermoon City" } end return realGetMapInfo(id) end
    addon:ClearNodeNameCache()
    check(addon:FindHearthNode({ name = "Silvermoon City" }) == "SILVERMOON_INN", "a hearthstone bound in Silvermoon goes to its inn")
    C_Map.GetMapInfo = realGetMapInfo
    addon:ClearNodeNameCache()
end
