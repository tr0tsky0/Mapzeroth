-- Round trips for the picker's "Nearest ..." picks: there and back, with a cooldown ability spent by one leg unavailable
-- to the other.
addon.World:Build()
useTestDistances()
addon.GetNodeName = function(_, id) return "Place " .. id end     -- names come from the client
addon.HasNodeName = function() return true end
local J = addon.Journey
local HEARTH = 6948

local function usesHearth(plan)
    for _, step in ipairs(plan and plan.raw or {}) do
        if step.method == "hearthstone" then return true end
    end
    return false
end

-- A druid in Westfall, bound at the Stormwind inn, with Teleport: Moonglade.
local stormwindDruid
for _, node in ipairs(addon.Nodes.Pois) do
    if node.trainer == "DRUID" and node.city == "stormwind" then stormwindDruid = node.id end
end
local westfall = { id = "YOU_westfall", mapID = 1436, x = 0.5, y = 0.5 }
local druid = makeCtx({ class = "DRUID", faction = "Alliance", spells = { 18960 }, items = { HEARTH }, hearthNode = "INN_6740" })
local session = J:Build(druid, westfall)
check(stormwindDruid, "Stormwind has a druid trainer")

-- A banned ability isn't used.
local free = J:Plan(session, stormwindDruid)
local banned = J:Plan(session, stormwindDruid, { [HEARTH] = true })
check(usesHearth(free), "from Westfall the hearthstone is the way to Stormwind")
check(banned and not usesHearth(banned) and banned.cost > free.cost, "banned, the trip walks and takes longer")

-- A round trip adds the way back, and the legs share the one-use hearthstone.
local trip = J:RoundTrip(session, { stormwindDruid })
check(trip and trip.nodeID == stormwindDruid, "a round trip to the only place there is")
check(trip and math.abs(trip.total - (trip.out + trip.back)) < 1e-6, "its total is there plus back")
check(trip and trip.total > J:Cost(session, stormwindDruid), "and takes longer than going one way")
local function pathCost(from, to, ban)
    return addon.Pathfinder:FindPath(session.graph, from, to, session.graph.phase, { banned = ban }).cost
end
if trip.banned[HEARTH] then
    check(math.abs(trip.back - pathCost(stormwindDruid, session.returnID, nil)) < 1e-6, "a way there that leaves the hearthstone alone has it for the way back")
else
    check(math.abs(trip.back - pathCost(stormwindDruid, session.returnID, { [HEARTH] = true })) < 1e-6, "a way there that uses the hearthstone leaves none for the way back")
end

-- Planning the way back as well: the plan carries it, ending where the player started, and the way there is as before.
local both = J:Plan(session, stormwindDruid, trip.banned, trip.backBanned)
check(both.back and math.abs(both.back.cost - trip.back) < 1e-6, "a round-trip plan carries the way back, as quick as the search found")
local lastBack = both.back.steps[#both.back.steps]
check(lastBack.nodeID == session.returnID and lastBack.name:find(addon.L["PLACE_START"], 1, true), "which ends where the player started: " .. tostring(lastBack.name))
check(math.abs(both.cost - trip.out) < 1e-6 and J:Plan(session, stormwindDruid, trip.banned).back == nil, "and a plain plan has no way back")

-- Planned again from somewhere else (a flight went astray), the way back still ends where the trip began.
local astray = J:Build(druid, { id = "YOU_elsewhere", mapID = 1429, x = 0.5, y = 0.5 })
astray.returnTo = westfall
local again = J:Plan(astray, stormwindDruid, trip.banned, trip.backBanned)
check(again and again.back and again.returnTo == westfall and again.back.steps[#again.back.steps].nodeID == astray.returnID, "a session told where to return takes the way back there")
check(astray.returnID == "RETURN_YOU_westfall", "not to where it now starts: " .. tostring(astray.returnID))

-- Hearthing once is not hearthing twice: back from the same place, with the hearthstone spent, can't be quicker than with it.
check(pathCost(stormwindDruid, session.returnID, { [HEARTH] = true }) >= pathCost(stormwindDruid, session.returnID, nil), "spending the hearthstone never helps the way back")

-- No way back is no round trip.
local nowhere = J:RoundTrip(J:Build(druid, westfall), { "NOT_A_NODE" })
check(nowhere == nil, "an unknown place has no round trip")

-- A pick lists its round trip as well when that goes somewhere other than the nearest place and beats the nearest's own.
local nearestStub, tripStub = J.Nearest, J.RoundTrip
local function priced(nearestID, bestTrip, ownTrip, nodeIDs)
    J.Nearest = function() return nearestID, 10 end
    J.RoundTrip = function(_, _, ids) if #ids == 1 then return ownTrip end return bestTrip end
    local item = { name = "Nearest Thing", pick = true, nodeIDs = nodeIDs or { "A", "B" } }
    addon.Sections:Price({ index = { A = { name = "Aville" }, B = { name = "Bville" } }, { id = "relevant", items = { item } } }, {})
    return item
end
local item = priced("A", { nodeID = "B", out = 60, back = 40, total = 100 }, { total = 300 })
check(item.roundTrip and item.roundTrip.nearest == "B" and item.roundTrip.where == "Bville" and item.roundTrip.eta == 100, "a quicker round trip elsewhere is listed")
check(priced("A", { nodeID = "A", out = 10, back = 10, total = 20 }, { total = 20 }).roundTrip == nil, "the same place both ways is one row")
check(priced("A", { nodeID = "B", out = 60, back = 40, total = 100 }, { total = 100.5 }).roundTrip == nil, "a tie isn't worth a second row")
check(priced("A", { nodeID = "B", out = 60, back = 40, total = 100 }, nil).roundTrip, "the nearest having no way back gives the other")
check(priced("A", { nodeID = "B", out = 60, back = 40, total = 100 }, { total = 300 }, { "A" }).roundTrip == nil, "a pick with one place has no choice to show")
J.Nearest, J.RoundTrip = nearestStub, tripStub
