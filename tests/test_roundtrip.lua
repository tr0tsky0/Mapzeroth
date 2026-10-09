-- Round trips (a route's "Round Trip" choice): there and back, with a cooldown ability spent by one leg unavailable
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

-- Planning a round trip to an entry: its quickest place there and back, and the entry that is followed (that one place,
-- and the abilities each way leaves alone, so Navigation can plan it again part way).
do
    local entry = { name = "Druid Trainer", pick = true, group = "trainer", nodeIDs = { stormwindDruid } }
    local plan, followed = J:PlanRoundTrip(J:Build(druid, westfall), entry)
    check(plan and plan.back and plan.back.cost > 0, "a round-trip plan has its way back")
    check(followed and followed ~= entry and followed.nodeIDs[1] == stormwindDruid and #followed.nodeIDs == 1,
        "and the entry followed is the one place it goes to")
    check(followed.banned and followed.backBanned and followed.name == entry.name, "with each way's abilities, under the same name")
    check(entry.banned == nil, "the entry chosen is left as it was")
    local again = J:PlanEntry(J:Build(druid, westfall), followed)
    check(again and again.back and math.abs(again.cost + again.back.cost - (plan.cost + plan.back.cost)) < 1e-6,
        "planning the followed entry again gives the same trip")
    check(J:PlanRoundTrip(J:Build(druid, westfall), { name = "Nowhere", nodeIDs = { "NOT_A_NODE" } }) == nil,
        "no way there and back is no plan")
end
