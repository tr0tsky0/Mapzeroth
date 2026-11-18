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
-- The client's text can be longer than our name for the place ("Stormwind City" for "Stormwind"), or shorter.
check(addon:FindHearthNode({ name = "Goldshire Village" }) == "INN_295", "bind text that continues the town's name still finds it")
check(addon:FindHearthNode({ name = "GOLDSHIRE" }) == "INN_295", "whatever its case")
check(addon:FindHearthNode({ name = "Gold" }) == nil, "but part of a word is no match")

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

-- 5. The bind is per character: each one keeps their own, and the old account-wide one is only a fallback.
local realName = "Realm"
UnitName = function() return "Alice" end
GetRealmName = function() return realName end
MapzerothRebuildDB = nil
check(addon:GetBind() == nil, "no saved bind at all")

MapzerothRebuildDB = { hearthstone = { mapID = 1429, x = 0.5, y = 0.5, name = "Legacy" } }
check(addon:GetBind().name == "Legacy", "a character that hasn't bound since gets the legacy bind")
check(MapzerothRebuildDB.hearthstones == nil, "and the legacy bind is not copied into their own")

addon:SaveBind(1429, 0.1, 0.2, "Goldshire")
check(MapzerothRebuildDB.hearthstone == nil, "a bind removes the legacy account-wide key")
check(addon:GetBind().name == "Goldshire", "Alice has her own bind")

UnitName = function() return "Bob" end
check(addon:GetBind() == nil, "Bob does not inherit Alice's bind")
addon:SaveBind(1429, 0.3, 0.4, "Lakeshire")
check(addon:GetBind().name == "Lakeshire", "Bob has his own bind")
UnitName = function() return "Alice" end
check(addon:GetBind().name == "Goldshire", "and Alice's is untouched")
check(MapzerothRebuildDB.hearthstones["Alice-Realm"].name == "Goldshire" and MapzerothRebuildDB.hearthstones["Bob-Realm"].name == "Lakeshire",
    "both are saved under their characters")
MapzerothRebuildDB = nil

-- 6. An entry in the Hearthstones list that doesn't say its method is still a hearthstone (Modern's data doesn't).
do
    local realList = addon.Abilities.Hearthstones
    addon.Abilities.Hearthstones = { { itemID = 6948, cost = 10 } }
    local known = addon:GetKnownTeleports(makeCtx({ items = { 6948 }, hearthNode = "INN_295" }))
    check(#known == 1 and known[1].method == "hearthstone", "a Hearthstones entry with no method is a hearthstone: "
        .. tostring(known[1] and known[1].method))
    local r2 = route(makeCtx({ faction = "Horde", items = { 6948 }, hearthNode = "INN_295" }), "TAXI_23", "INN_295")
    check(r2 and r2.steps[1].method == "hearthstone", "and the route's step says so")
    addon.Abilities.Hearthstones = realList
end

-- 7. A mage teleport uses up a Rune of Teleportation: with none in the bags it isn't offered.
do
    local function toStormwind(ctx)
        for _, entry in ipairs(addon:GetKnownTeleports(ctx)) do
            if entry.ability.spellID == 3561 then return true end
        end
        return false
    end
    check(not toStormwind(makeCtx({ class = "MAGE", spells = { 3561 } })), "Teleport: Stormwind without a rune is not offered")
    check(toStormwind(makeCtx({ class = "MAGE", spells = { 3561 }, items = { 17031 } })), "with a rune it is")
    for _, t in ipairs(addon.Abilities.Teleports) do
        if t.spellID >= 3561 and t.spellID <= 3567 then
            check(t.reagent == 17031, "mage teleport " .. t.spellID .. " needs a rune")
        end
    end
end

-- 8. A rune costs money, so a teleport that spends one has to save the reagentSaving setting over the best route without
-- it (a player in Stormwind isn't told to teleport to Stormwind). With the Reagent Economy perk it's free: no rune
-- needed, and any saving will do. The route's time is the real one either way.
do
    local function plan(from, to, extra)
        local o = { faction = "Alliance", class = "MAGE" }
        for k, v in pairs(extra or {}) do o[k] = v end
        return route(makeCtx(o), from, to)
    end
    local MIN = addon.DEFAULT_REAGENT_SAVING
    check(MIN and MIN > 0, "a reagent teleport has a minimum saving")
    local withRune = { spells = { 3561 }, items = { 17031 } }
    local perk = { spells = { 3561 }, reagentFree = true }

    -- Across Stormwind: walking is far less than the cast, a loading screen and the minimum saving.
    local walk = plan("TAXI_2", "CITY_STORMWIND")
    local tele = 10 + 15
    check(walk and walk.cost < tele + MIN, "the Stormwind walk is short enough for this check: " .. tostring(walk and walk.cost))
    local r = plan("TAXI_2", "CITY_STORMWIND", withRune)
    check(r and r.steps[1].method ~= "teleport", "no rune spent teleporting across Stormwind: " .. (r and methods(r) or "nil"))
    check(r and math.abs(r.cost - walk.cost) < 1e-6, "and its time is the walk's")
    if walk.cost > tele + 1 then
        -- The setting lowered to 1 s: then even this short a saving is worth a rune.
        local low = plan("TAXI_2", "CITY_STORMWIND", { spells = { 3561 }, items = { 17031 }, reagentSaving = 1 })
        check(low and low.steps[1].method == "teleport", "with the setting at 1 s the rune is spent: " .. (low and methods(low) or "nil"))
    end
    if walk.cost > tele then
        local free = plan("TAXI_2", "CITY_STORMWIND", perk)
        check(free and free.steps[1].method == "teleport", "with the perk the free teleport wins: " .. (free and methods(free) or "nil"))
    end

    -- From far away the saving is easily worth a rune, and the time shown has no minimum saving in it.
    local far = plan("TAXI_23", "CITY_STORMWIND", withRune)
    check(far and far.steps[1].method == "teleport", "from far off the mage teleports: " .. (far and methods(far) or "nil"))
    check(far and far.cost < tele + MIN, "the time shown is the teleport's own: " .. tostring(far and far.cost))

    -- The perk: no rune in the bags, still offered.
    local known = addon:GetKnownTeleports(makeCtx({ class = "MAGE", spells = { 3561 }, reagentFree = true }))
    local found = false
    for _, e in ipairs(known) do if e.ability.spellID == 3561 then found = e.bias < 1 end end
    check(found, "with Reagent Economy Teleport: Stormwind needs no rune and carries no minimum saving")
    check(addon.REAGENT_ECONOMY and #addon.REAGENT_ECONOMY > 0, "Forever knows the Reagent Economy perk's spells")
end
