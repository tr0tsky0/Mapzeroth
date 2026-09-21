-- Personally relevant places: Skyborne see ley lines (Read Ley Line, and only Skyborne
-- have it); everyone else has them in the drill-down. No ley line is in the data yet, so
-- a stand-in node is used.
local leyline = { kind = "leyline", mapID = 2521, x = 0.5, y = 0.5 }
local skyborne = makeCtx({ class = "MAGE", spells = { addon.LeyLineSpell } })
check(addon.LeyLineSpell == 1259705, "Read Ley Line is spell 1259705")
check(addon.Relevance:IsRelevant(leyline, skyborne), "a player who knows Read Ley Line sees ley lines")
check(not addon.Relevance:IsRelevant(leyline, makeCtx({ class = "MAGE" })), "anyone else doesn't")

-- Other kinds go through their own rules, or are always shown.
local inn = { kind = "inn" }
check(addon.Relevance:IsRelevant(inn, makeCtx({ class = "MAGE" })), "an inn is always shown")
local druidTrainer = { kind = "trainer", trainer = "DRUID" }
check(not addon.Relevance:IsRelevant(druidTrainer, makeCtx({ class = "MAGE" })), "trainers follow the trainer rules")
check(addon.Relevance:IsRelevant(druidTrainer, makeCtx({ class = "DRUID" })), "a druid sees the druid trainer")

-- "Where's the nearest one?": the pathfinder can search for the cheapest of several goals.
useTestDistances()
local ali = makeCtx({ faction = "Alliance" })
local nearest = route(ali, "TAXI_2", { "TAXI_23", "TAXI_6" })   -- Orgrimmar or Ironforge, from Stormwind
check(nearest and nearest.goal == "TAXI_6", "the nearer of two goals wins: " .. tostring(nearest and nearest.goal))
local alone = route(ali, "TAXI_2", "TAXI_6")
check(alone and alone.goal == "TAXI_6" and alone.cost == nearest.cost, "a single goal still works and costs the same")
check(route(ali, "TAXI_2", { "NOT_A_NODE" }) == nil, "no reachable goal gives nil")
