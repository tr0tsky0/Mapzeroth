useTestDistances()
local ali = makeCtx({ faction = "Alliance" })

-- Stormwind flight master -> harbor: both on the Stormwind City map (1453),
-- which has a measured factor of 1.7.
local r = route(ali, "TAXI_2", "DOCK_STORMWIND")
local a, b = addon.World:GetNode("TAXI_2"), addon.World:GetNode("DOCK_STORMWIND")
local straight = addon.TravelGraph.DistanceProvider(a, b)
local expected = straight * addon.PathFactors[1453] / addon.WALK_SPEED
check(math.abs(r.cost - expected) < 1e-6, ("city walk uses its own factor: %.1f vs %.1f"):format(r.cost, expected))

-- The other capitals are set by hand: Orgrimmar and Thunder Bluff as Stormwind, Undercity as a worse Ironforge.
check(addon.PathFactors[1454] == addon.PathFactors[1453] and addon.PathFactors[1456] == addon.PathFactors[1453],
    "Orgrimmar and Thunder Bluff walk like Stormwind")
check(addon.PathFactors[1458] == 1.9, "Undercity is 1.9")

-- A map with no factor falls back to the default: two places inside Darnassus, on its own map.
local c, d
addon.World:ForEachNode(function(n)
    if n.mapID == 1457 then
        if not c then c = n elseif not d then d = n end
    end
end)
check(c and d and addon.PathFactors[c.mapID] == nil, "Darnassus has no factor")
local r2 = route(ali, c.id, d.id)
local expected2 = addon.TravelGraph.DistanceProvider(c, d)
    * ((addon.DEFAULT_PATH_FACTOR + (addon.PathFactors[d.mapID] or addon.DEFAULT_PATH_FACTOR)) / 2) / addon.WALK_SPEED
check(math.abs(r2.cost - expected2) < 1e-6, ("default factor applies: %.1f vs %.1f"):format(r2.cost, expected2))
