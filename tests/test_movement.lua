addon.World:Build()
local function speed(spells, container)
    return addon:GetGroundSpeed(container or "kalimdor.mulgore", makeCtx({ spells = spells }))
end

check(speed({}) == 7, "no riding, no forms: base speed, got " .. speed({}))
check(math.abs(speed({ 33388 }) - 7 * 1.6) < 1e-9, "apprentice riding +60%")
check(math.abs(speed({ 33388, 33391 }) - 7 * 2.0) < 1e-9, "journeyman beats apprentice")
check(math.abs(speed({ 783 }) - 7 * 1.4) < 1e-9, "travel form +40% outdoors")
check(math.abs(speed({ 783, 33388 }) - 7 * 1.6) < 1e-9, "best bonus wins, they don't stack")

-- Indoors, mounts and outdoor-only forms are off.
addon.Containers["kalimdor.testhall"] = { indoor = true }
addon.World:Build()
check(speed({ 33388, 783 }, "kalimdor.testhall") == 7, "indoor: base speed")

-- Cat Form: its speed is Feral Swiftness' 15% a rank, and it works indoors.
local function catSpeed(points, container)
    return addon:GetGroundSpeed(container or "kalimdor.mulgore",
        makeCtx({ spells = { 768, 17002 }, talents = { [17002] = points } }))
end
check(catSpeed(0) == 7, "Cat Form without Feral Swiftness: base speed")
check(math.abs(catSpeed(1) - 7 * 1.15) < 1e-9, "Feral Swiftness rank 1: +15%")
check(math.abs(catSpeed(2, "kalimdor.testhall") - 7 * 1.3) < 1e-9, "Feral Swiftness rank 2: +30%, even indoors")
check(math.abs(addon:GetGroundSpeed("kalimdor.mulgore",
    makeCtx({ spells = { 768, 783 }, talents = { [17002] = 2 } })) - 7 * 1.4) < 1e-9, "Travel Form outdoors beats Cat Form")

check(math.abs(speed({ 5118 }) - 7 * 1.3) < 1e-9, "Aspect of the Cheetah +30%")
check(math.abs(speed({ 5118 }, "kalimdor.testhall") - 7 * 1.3) < 1e-9, "and indoors")

-- Frequent Flier: +20% flight-path mount speed, nothing without it.
check(addon:GetFlightSpeedMultiplier(makeCtx({})) == 1, "no Frequent Flier: no change")
check(math.abs(addon:GetFlightSpeedMultiplier(makeCtx({ spells = { 1225490 } })) - 1.2) < 1e-9,
      "Frequent Flier: +20% flight speed")

-- End to end: a real flight edge's cost (TAXI_2 -> TAXI_4, Stormwind -> Sentinel Hill, 78s) shrinks
-- by the same factor, and its fare is untouched (FareFactor already covers the gold discount
-- separately -- see Constants.lua).
useTestDistances()
local without = route(makeCtx({}), "TAXI_2", "TAXI_4")
local with = route(makeCtx({ spells = { 1225490 } }), "TAXI_2", "TAXI_4")
check(math.abs(without.cost - 78) < 1e-6, "base flight cost unchanged: " .. without.cost)
check(math.abs(with.cost - 78 / 1.2) < 1e-6, "Frequent Flier speeds up the flight: " .. with.cost)
check(with.fare == without.fare, "fare untouched by the speed perk: " .. with.fare)
