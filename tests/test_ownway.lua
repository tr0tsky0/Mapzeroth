-- Nearest Flight Master is the nearest without teleporting (Journey's OWN_WAY): on foot, riding or flying, never a
-- hearthstone, portal or boat, unless no flight master can be reached that way.
useTestDistances()
addon.World:Build()

addon.GetNodeName = function(_, id) return "Place " .. id end
addon.GetZoneName = function(_, mapID) return "Zone " .. tostring(mapID) end
addon.GetCityName = function(_, key) return "City " .. key end
addon.GetTownName = function(_, key) return "Town " .. key end
addon.GetTrainerTypeName = function(_, token) return token end
addon.GetSkillName = function(_, id) return "Skill " .. id end

-- An Alliance character in Elwynn Forest (no flight master on its map: every walk to one is 3000 yd with the test
-- distances), bound in Booty Bay with the hearthstone ready.
local ctx = makeCtx({ faction = "Alliance", items = { 6948 }, hearthNode = "INN_6807" })
local start = { id = "YOU_ownway", mapID = 1429, x = 0.50, y = 0.50 }
local session = addon.Journey:Build(ctx, start)
check(session, "a session builds")

local entries = addon.Destinations:Build(ctx)
local flightPick
for _, item in ipairs(addon.Sections:Build(entries, ctx).top or {}) do if item.key == "flight" then flightPick = item end end
if not flightPick then
    local sections = addon.Sections:Build(entries, ctx)
    for _, s in ipairs(sections) do
        for _, child in ipairs(s.children or {}) do
            for _, item in ipairs(child.items) do if item.key == "flight" then flightPick = item end end
        end
    end
end
check(flightPick and flightPick.ownWay, "the flight master pick goes the player's own way")

local function methods(plan)
    local out = {}
    for _, step in ipairs(plan and plan.raw or {}) do out[#out + 1] = step.method end
    return table.concat(out, ",")
end

-- Every way: the hearthstone to Booty Bay and its flight master is quicker than any walk.
local anyWay = {}
for k, v in pairs(flightPick) do anyWay[k] = v end
anyWay.ownWay = nil
local quick = addon.Journey:PlanEntry(session, anyWay)
check(quick and methods(quick):find("hearthstone"), "every way, it hearths: " .. methods(quick))

-- Its own way: a walk to another flight master, nothing else.
local own = addon.Journey:PlanEntry(session, flightPick)
check(own and own.goal ~= quick.goal, "its own way it's another one: " .. tostring(own and own.goal))
for _, step in ipairs(own and own.raw or {}) do
    check(step.method == "walk" or step.method == "fly", "only walking or flying: " .. methods(own))
end
local id, eta = addon.Journey:Nearest(session, flightPick.nodeIDs, true)
check(id == own.goal and math.abs(eta - own.cost) < 120, "the picker's time is for that one: " .. tostring(id) .. " " .. tostring(eta))
check(select(2, addon.Journey:Nearest(session, flightPick.nodeIDs)) < eta, "quicker every way, as before")

-- A round trip goes there its own way too, and back by any way.
local plan, trip = addon.Journey:PlanRoundTrip(session, flightPick)
check(plan and trip and trip.nodeID == own.goal and plan.back and not methods(plan):find("hearthstone"),
    "a round trip goes there on foot: " .. methods(plan))
