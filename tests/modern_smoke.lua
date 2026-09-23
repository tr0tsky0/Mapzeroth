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
check(addon.World:GetNode("INSTANCE_67"), "The Stonecore carried its real journal instance id through the rename")
EJ_GetInstanceInfo = function(id) if id == 67 then return "The Stonecore" end end
check(addon:GetNodeName("INSTANCE_67") == "The Stonecore",
    "a renamed dungeon entrance resolves via the Dungeon Journal, not its raw id: " .. addon:GetNodeName("INSTANCE_67"))

local total, containers = 0, {}
addon.World:ForEachNode(function(node)
    total = total + 1
    local c = addon.World:GetNodeContainer(node.id)
    check(c, "every node resolves to a container: " .. node.id)
    containers[c.path] = (containers[c.path] or 0) + 1
end)
check(total == 1216, "every converted node made it into the tree (1215 converted + 1 hand-added): " .. total)
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
local toBoralus = addon.Pathfinder:FindPath(graph, "STORMWIND_BORALUS_PORTAL", "BORALUS")
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

-- A phase-gated edge (inert `mapArtID`, see CONVERSION_NOTES.md) never passes, even when
-- every requirement the new engine DOES understand is satisfied -- an unrecognized
-- requirement key fails closed by design (EdgeRequirements.lua), which is exactly the
-- "unreachable until it's done properly" safety net this conversion is relying on.
local horde = makeCtx({ faction = "Horde", quests = { [34378] = false } })
check(not addon:MeetsRequirements({ faction = "Horde", notQuest = 34378, mapArtID = { 17, 18 } }, horde),
    "a phase-gated edge stays closed even when its other requirements are met")

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
check(addon.World:GetNode("INSTANCE_67"), "The Stonecore (from the earlier instance-rename pass) still exists")
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
        if e.method == "fly" and (from == "MAGISTERS_SILVERMOON_PORTAL" or e.to == "MAGISTERS_SILVERMOON_PORTAL") then flyIntoLycaneum = true end
        if from == "LYCANEUM_ENTRANCE" and e.to == "MAGISTERS_SILVERMOON_PORTAL" and e.method == "walk" and e.cost > 0 then walkOut = true end
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
