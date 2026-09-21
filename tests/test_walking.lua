-- Walking between zones works through the border crossings, and only where
-- crossings exist. Flights, boats etc. are removed so only feet remain.
useTestDistances()

local walkOnly = {}
for _, edge in ipairs(addon.Edges) do
    if edge.method == "walk" or edge.method == "transition" then walkOnly[#walkOnly + 1] = edge end
end
local allEdges = addon.Edges
addon.Edges = walkOnly

local ali = makeCtx({ faction = "Alliance" })
local function walks(from, to) return route(ali, from, to) ~= nil end

-- Kalimdor: Orgrimmar reaches most of the continent on foot...
check(walks("TAXI_23", "TAXI_25"), "Orgrimmar -> Crossroads")
check(walks("TAXI_23", "TAXI_22"), "Orgrimmar -> Thunder Bluff (via the Barrens)")
check(walks("TAXI_23", "TAXI_28"), "Orgrimmar -> Astranaar")
check(walks("TAXI_23", "TAXI_26"), "Orgrimmar -> Auberdine (via Ashenvale)")
check(walks("TAXI_23", "TAXI_49"), "Orgrimmar -> Moonglade")
check(walks("TAXI_23", "TAXI_39"), "Orgrimmar -> Gadgetzan")
check(walks("TAXI_23", "TAXI_72"), "Orgrimmar -> Cenarion Hold")
-- ...but Teldrassil is an island, and Rut'theran is cut off inside it.
check(not walks("TAXI_23", "TAXI_27"), "no walking route to Rut'theran")

-- Eastern Kingdoms: Stormwind reaches Ironforge only the long way round.
check(walks("TAXI_2", "TAXI_6"), "Stormwind -> Ironforge on foot")
check(walks("TAXI_2", "TAXI_45"), "Stormwind -> Nethergarde Keep")
check(walks("TAXI_2", "TAXI_11"), "Stormwind -> Undercity")
check(walks("TAXI_2", "TAXI_19"), "Stormwind -> Booty Bay (via Duskwood)")

-- Continents never connect by feet.
check(not walks("TAXI_2", "TAXI_23"), "no walking route between continents")

-- Stonewrought Pass needs the Key to Searing Gorge (quest 3201).
local function passOpen(ctx)
    addon.World:Build()
    local graph = addon.TravelGraph:Build(ctx)
    for _, step in ipairs(graph.adjacency["BORDER_LOCH_MODAN_TO_SEARING_GORGE"] or {}) do
        if step.to == "BORDER_SEARING_GORGE_TO_LOCH_MODAN" then return true end
    end
    return false
end
check(not passOpen(makeCtx({})), "Stonewrought Pass is closed without the key")
check(passOpen(makeCtx({ quests = { [3201] = true } })), "Stonewrought Pass opens with quest 3201 done")

-- Blackrock Mountain is an interior between Burning Steppes and Searing Gorge: its
-- instances are reachable from either side, and the mountain is a way through.
check(walks("TAXI_70", "INSTANCE_MOLTEN_CORE"), "Flame Crest (Burning Steppes) -> Molten Core")
check(walks("TAXI_75", "INSTANCE_BLACKROCK_DEPTHS"), "Thorium Point (Searing Gorge) -> Blackrock Depths")
check(walks("TAXI_75", "INSTANCE_BLACKWING_LAIR"), "Searing Gorge side reaches Blackwing Lair too")
check(addon.World:GetNodeContainer("INSTANCE_MOLTEN_CORE").path == "easternkingdoms.blackrock_mountain",
    "Molten Core is in the mountain interior")

addon.Edges = allEdges
