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
