useTestDistances()

-- 1. A simple flight: Stormwind -> Ironforge. The direct flight is 259s; the
-- tram (walk in, 120s, 2 loading screens, walk out) competes with it.
local ali = makeCtx({ faction = "Alliance" })
local r = route(ali, "TAXI_2", "TAXI_6")
check(r, "Alliance can get Stormwind -> Ironforge")
print(("Stormwind -> Ironforge: %.0fs via %s"):format(r.cost, methods(r)))

-- 2. Faction gating: Horde must never use Alliance-only edges. With the
-- Alliance flight and tram closed to them, the only way is on foot.
local horde = makeCtx({ faction = "Horde" })
local h = route(horde, "TAXI_2", "TAXI_6")
check(h, "Horde can still walk from Stormwind to Ironforge")
for _, step in ipairs(h.steps) do
    local req = step.source and step.source.requirements
    check(not (req and req.faction == "Alliance"), "Horde route used an Alliance-only edge: " .. step.from .. " -> " .. step.to)
end
check(not methods(h):find("tram"), "Horde must not take the tram")
check(h.cost > r.cost * 3, "walking is far slower than the flight")

-- 3. Zeppelins are Horde-only.
local z = route(horde, "ZEPPELIN_ORGRIMMAR", "ZEPPELIN_GROMGOL")
check(z and z.steps[1].method == "zeppelin", "Horde takes the zeppelin")
-- Alliance can still cross (the neutral Booty Bay-Ratchet ship), just never by zeppelin.
local az = route(ali, "ZEPPELIN_ORGRIMMAR", "ZEPPELIN_GROMGOL")
check(az and not methods(az):find("zeppelin"), "Alliance can't use zeppelins: " .. (az and methods(az) or "nil"))

-- 4. The Auberdine-Menethil-Southshore loop: the pass-through edge (488s + a
-- loading screen) exists, so the route can never cost more than that. The
-- search may find something cheaper (ship to Menethil, then fly), and does.
local loop = route(ali, "DOCK_AUBERDINE_MENETHIL", "DOCK_SOUTHSHORE")
check(loop, "loop: Southshore is reachable from the Auberdine pier")
check(loop.cost <= 488 + 15 + 1e-6, "loop: never worse than the through edge, got " .. loop.cost)
print(("Auberdine pier -> Southshore dock: %.0fs via %s"):format(loop.cost, methods(loop)))

-- 5. Rut'theran is isolated: no auto walk edge to Darnassus's portal, only
-- the explicit transition edge.
local walkToDarn = route(ali, "TAXI_27", "PORTAL_DARNASSUS_RUTTHERAN")
check(walkToDarn, "Rut'theran can reach Darnassus")
local used = methods(walkToDarn)
check(used:find("transition"), "the way into Darnassus is the transition edge: " .. used)

-- 6. Teleports seed the search from anywhere: a druid who knows Teleport:
-- Moonglade reaches Moonglade's flight master from Stormwind via the spell.
local druid = makeCtx({ faction = "Alliance", class = "DRUID", spells = { 18960 } })
local t = route(druid, "TAXI_2", "TAXI_49")
check(t and t.steps[1].method == "teleport", "druid teleports to Moonglade: " .. (t and methods(t) or "nil"))
local noSpell = route(makeCtx({ faction = "Alliance", class = "DRUID" }), "TAXI_2", "TAXI_49")
check(noSpell and noSpell.steps[1].method ~= "teleport", "no spell, no teleport")
print(("Stormwind -> Moonglade: %.0fs via %s (druid), %.0fs via %s (no spell)"):format(
    t.cost, methods(t), noSpell.cost, methods(noSpell)))

-- 7. Race-gated portal: Skyborne only.
local sky = makeCtx({ faction = "Alliance", race = "Skyborne" })
check(route(sky, "PORTAL_DALARAN_STORMWIND", "PORTAL_STORMWIND_DALARAN"), "Skyborne can use the portal")
local plain = route(ali, "PORTAL_DALARAN_STORMWIND", "PORTAL_STORMWIND_DALARAN")
check(not plain or methods(plain):find("portal") == nil, "non-Skyborne must not use the Skyborne portal")

-- 8. Consecutive walk steps collapse into one for display, keeping the total and the parts.
local steps = {
    { from = "A", to = "B", cost = 10, method = "walk" },
    { from = "B", to = "C", cost = 20, method = "walk" },
    { from = "C", to = "D", cost = 5, method = "flight" },
    { from = "D", to = "E", cost = 7, method = "walk" },
}
local shown = addon.Pathfinder:CollapseSteps(steps)
check(#shown == 3, "walk, walk, flight, walk collapses to 3 steps, got " .. #shown)
check(shown[1].from == "A" and shown[1].to == "C" and shown[1].cost == 30 and #shown[1].parts == 2, "the two walks merge")
check(shown[2].method == "flight" and shown[3].to == "E", "other steps stay as they are")
check(steps[1].to == "B" and steps[1].cost == 10, "the original steps are not modified")
