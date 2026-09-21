useTestDistances()
local ali = makeCtx({ faction = "Alliance" })

-- Stormwind flight master -> harbor: both on the Stormwind City map (1453),
-- which has a measured factor of 1.7.
local r = route(ali, "TAXI_2", "DOCK_STORMWIND")
local a, b = addon.World:GetNode("TAXI_2"), addon.World:GetNode("DOCK_STORMWIND")
local straight = addon.TravelGraph.DistanceProvider(a, b)
local expected = straight * addon.PathFactors[1453] / addon.WALK_SPEED
check(math.abs(r.cost - expected) < 1e-6, ("city walk uses its own factor: %.1f vs %.1f"):format(r.cost, expected))

-- A map with no measurement falls back to the default: two places inside Orgrimmar, on its own map.
local c = addon.World:GetNode("TAXI_23")
local d
addon.World:ForEachNode(function(n) if not d and n.mapID == c.mapID and n.id ~= c.id then d = n end end)
check(addon.PathFactors[c.mapID] == nil and d, "Orgrimmar has no measured factor")
local r2 = route(ali, "TAXI_23", d.id)
local expected2 = addon.TravelGraph.DistanceProvider(c, d)
    * ((addon.DEFAULT_PATH_FACTOR + (addon.PathFactors[d.mapID] or addon.DEFAULT_PATH_FACTOR)) / 2) / addon.WALK_SPEED
check(math.abs(r2.cost - expected2) < 1e-6, ("default factor applies: %.1f vs %.1f"):format(r2.cost, expected2))
