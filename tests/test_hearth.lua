useTestDistances()
addon.World:Build()

-- Matching a bind's text walks the settlements' names, some of which come from the
-- client's map and taxi data. None of that exists headless, so it answers "unknown".
C_Map = {
    GetMapInfo = function() return nil end,
    GetAreaInfo = function(id) if id == 87 then return "Goldshire" end end,  -- Goldshire's area
}
C_TaxiMap = { GetTaxiNodesForMap = function() return {} end }
Enum = { UIMapType = { Continent = 2 } }

-- 1. A bind saved at an inn snaps to that inn's node.
local goldshire = addon.World:GetNode("INN_295")
check(goldshire and goldshire.mapID == 1429, "the Goldshire inn is in the data")
check(addon:FindHearthNode({ mapID = 1429, x = goldshire.x + 0.004, y = goldshire.y - 0.003 }) == "INN_295",
    "a bind a few steps from the Goldshire inn snaps to it")
check(addon:FindHearthNode({ mapID = 1429, x = 0.90, y = 0.10 }) == nil, "a bind far from any inn snaps to nothing")

-- 2. A character bound before the addon has no position: match the bind text to a town.
check(addon:FindHearthNode({ name = "Goldshire" }) == "INN_295", "bind text 'Goldshire' finds the Goldshire inn")
check(addon:FindHearthNode({ name = "Nowhere" }) == nil, "unknown bind text finds nothing")

-- 3. With the item and a bind, the hearthstone is a 10s cast plus a loading screen.
local hearth = makeCtx({ faction = "Horde", items = { 6948 }, hearthNode = "INN_295" })
local r = route(hearth, "TAXI_23", "INN_295")
check(r and r.steps[1].method == "hearthstone", "hearthstone is the first step: " .. (r and methods(r) or "nil"))
check(math.abs(r.cost - 25) < 1e-6, "cost is the cast plus one loading screen, got " .. r.cost)

-- 4. Without the item, on cooldown, or with no bind, it is not offered.
local function firstMethod(ctx)
    local result = route(ctx, "TAXI_23", "INN_295")
    return result and result.steps[1].method
end
check(firstMethod(makeCtx({ faction = "Horde", hearthNode = "INN_295" })) ~= "hearthstone", "no item, no hearthstone")
check(firstMethod(makeCtx({ faction = "Horde", items = { 6948 }, hearthNode = "INN_295", cooldowns = { [8690] = 900 } })) ~= "hearthstone",
    "on cooldown, no hearthstone")
check(firstMethod(makeCtx({ faction = "Horde", items = { 6948 } })) ~= "hearthstone", "no bind, no hearthstone")
