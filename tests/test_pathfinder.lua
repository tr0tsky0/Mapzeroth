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

-- A walk still stops where a person would mark the route: a zone border, a city entrance, and going
-- from one container into another (out of an interior, into a city).
local function walkTo(from, to, cost) return { from = from, to = to, cost = cost, method = "walk" } end
local BORDER_OUT, BORDER_IN = "BORDER_DUN_MOROGH_TO_LOCH_MODAN", "BORDER_LOCH_MODAN_TO_DUN_MOROGH"
local pre                                        -- a node in the border's own zone, to walk past on the way there
local outContainer = addon.World:GetNodeContainer(BORDER_OUT)
addon.World:ForEachNode(function(node)
    if node.id ~= BORDER_OUT and addon.World:GetNodeContainer(node.id) == outContainer then pre = pre or node.id end
end)
check(pre, "the border's zone has another node")
local viaBorder = addon.Pathfinder:CollapseSteps({
    walkTo("A", pre, 10), walkTo(pre, BORDER_OUT, 50), walkTo(BORDER_OUT, BORDER_IN, 0), walkTo(BORDER_IN, "TAXI_8", 30),
})
check(#viaBorder == 3 and viaBorder[1].to == BORDER_OUT and viaBorder[1].cost == 60, "a walk ends at the zone border (the pass-through node before it merges)")
check(viaBorder[3].from == BORDER_IN and viaBorder[3].to == "TAXI_8", "and the walk on from the border is its own step")
check(addon.World:IsMilestone(BORDER_OUT) and not addon.World:IsMilestone("TAXI_8"), "a border is a milestone, a flight master is not")
local gate
addon.World:ForEachNode(function(node) if node.kind == "entrance" then gate = gate or node end end)
check(gate and addon.World:IsMilestone(gate.id), "a city entrance is a milestone")
local viaGate = addon.Pathfinder:CollapseSteps({ walkTo("A", gate.id, 20), walkTo(gate.id, "C", 40) })
check(#viaGate == 2 and viaGate[1].to == gate.id and viaGate[2].to == "C", "a walk ends at a city entrance and the next starts there")
local same, other
addon.World:ForEachNode(function(node)
    local c = addon.World:GetNodeContainer(node.id)
    if node.id:find("^TAXI_") and c then
        same = same or {}
        same[c] = same[c] or {}
        table.insert(same[c], node.id)
    end
end)
local pair
for _, ids in pairs(same or {}) do if #ids >= 2 then pair = ids break end end
check(pair, "two flight nodes share a container")
local within = addon.Pathfinder:CollapseSteps({ walkTo("A", pair[1], 10), walkTo(pair[1], pair[2], 20) })
check(#within == 1, "walking between nodes of one container stays one step")
local across = addon.Pathfinder:CollapseSteps({ walkTo("A", "TAXI_2", 10), walkTo("TAXI_2", "TAXI_4", 20) })
check(addon.World:GetNodeContainer("TAXI_2") ~= addon.World:GetNodeContainer("TAXI_4") and #across == 2,
    "walking on into another container starts a new step")

-- Flights are single legs, chained by the planner. A leg's time differs by direction (Morgan's Vigil ->
-- Thorium Point 104 s, back 96 s), each direction's own time is used, and taking a leg straight after
-- another saves FLIGHT_CHAIN_SAVING seconds (a through-ticket doesn't land and take off again).
do
    useTestDistances()
    addon.World:Build()
    local ali = makeCtx({ faction = "Alliance" })
    local graph = addon.TravelGraph:Build(ali)
    local function flightCosts(from, to)
        local costs = {}
        for _, link in ipairs(graph.adjacency[from] or {}) do
            if link.to == to and link.method == "flight" then costs[#costs + 1] = link.cost end
        end
        return costs
    end
    local there, back = flightCosts("TAXI_71", "TAXI_74"), flightCosts("TAXI_74", "TAXI_71")
    check(#there == 1 and there[1] == 104 and #back == 1 and back[1] == 96, "each direction of a leg has its own time: " .. table.concat(there, ",") .. " / " .. table.concat(back, ","))
    check(#flightCosts("TAXI_5", "TAXI_6") == 0, "Lakeshire to Ironforge is not a leg of its own")

    -- ...it is three legs chained: Lakeshire > Morgan's Vigil > Thorium Point > Ironforge.
    local saving = addon.FLIGHT_CHAIN_SAVING
    local trip = route(ali, "TAXI_5", "TAXI_6")
    check(trip and #trip.steps == 3 and methods(trip) == "flight,flight,flight", "three flights: " .. tostring(trip and methods(trip)))
    check(math.abs(trip.cost - (61 + 104 + 94 - 2 * saving)) < 1e-6, "priced as the legs less the saving for each extra one: " .. tostring(trip.cost))
    local collapsed = addon.Pathfinder:CollapseSteps(trip.steps)
    check(#collapsed == 1 and math.abs(collapsed[1].cost - trip.cost) < 1e-6, "shown as one ticket that costs the whole trip")

    -- A walk between two flights is two tickets and takes no saving.
    check(saving > 0, "the chain saving is set")
    local oneWay = 0
    for _, link in ipairs(graph.adjacency["TAXI_2"] or {}) do
        if link.method == "flight" then oneWay = oneWay + 1 end
    end
    check(oneWay >= 5, "an ordinary flight master still has its legs: " .. oneWay)

    -- When there is a direct leg to the destination the game sells that ticket, whatever a chain of legs would
    -- take. Refuge Pointe to Ironforge is a direct leg (271 s), so flying on through Menethil Harbor is not a
    -- ticket the game sells; landing there and taking a new ticket is (126 + 89 s, with nothing saved).
    local toMenethil, menethilToIronforge = flightCosts("TAXI_16", "TAXI_7")[1], flightCosts("TAXI_7", "TAXI_6")[1]
    local viaStop = route(ali, "TAXI_16", "TAXI_6")
    check(viaStop and methods(viaStop) == "flight,flight" and viaStop.cost == toMenethil + menethilToIronforge,
        "Refuge Pointe to Ironforge: land at Menethil Harbor and take another ticket, no saving: " .. tostring(viaStop and viaStop.cost))
    check(viaStop.steps[1].to == "TAXI_7" and not viaStop.steps[2].through, "the second flight is a new ticket, not the same one")
    check(#addon.Pathfinder:CollapseSteps(viaStop.steps) == 2, "and it is shown as two flights")
    -- No direct leg to Stormwind, so the same stops can be one ticket (Ironforge is passed through, not landed at).
    local toStormwind = route(ali, "TAXI_16", "TAXI_2")
    check(toStormwind and #toStormwind.steps == 3 and toStormwind.steps[2].through and toStormwind.steps[3].through,
        "Refuge Pointe to Stormwind flies through Menethil Harbor and Ironforge on one ticket")
    check(#addon.Pathfinder:CollapseSteps(toStormwind.steps) == 1, "shown as one ticket")
end

-- Flights along one ticket are shown as one step, like consecutive walks are one walk: in game you buy a
-- ticket to the far flight point and fly through the stops without landing. The search marks a flight
-- that goes on along the ticket the last one began with `through`; a flight without it is a new ticket.
do
    local function step(method, from, to, cost) return { method = method, from = from, to = to, cost = cost } end
    local function through(from, to, cost) local s = step("flight", from, to, cost); s.through = true; return s end
    local merged = addon.Pathfinder:CollapseSteps({
        step("walk", "A", "B", 10), step("flight", "B", "C", 100), through("C", "D", 50), step("walk", "D", "E", 5),
    })
    check(#merged == 3, "walk, one ticket, walk: " .. #merged)
    check(merged[2].method == "flight" and merged[2].from == "B" and merged[2].to == "D" and merged[2].cost == 150 - addon.FLIGHT_CHAIN_SAVING,
    "the ticket runs B to D and costs both legs less the saving for the extra one")
    check(#merged[2].parts == 2 and merged[2].parts[1].to == "C", "and remembers the stop it passes through")
    local separate = addon.Pathfinder:CollapseSteps({ step("flight", "A", "B", 10), step("ship", "B", "C", 20), step("flight", "C", "D", 30) })
    check(#separate == 3, "a flight, a boat, a flight are three steps")
    local twoTickets = addon.Pathfinder:CollapseSteps({ step("flight", "A", "B", 10), step("flight", "B", "C", 20) })
    check(#twoTickets == 2, "two flights that land between are two tickets")
end
