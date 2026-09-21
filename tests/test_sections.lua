-- The accordion on the main window: what each section holds for a character, and its travel times.
useTestDistances()
addon.World:Build()

-- Names come from the client; stand-ins that keep every place named.
addon.GetNodeName = function(_, id) return "Place " .. id end
addon.GetZoneName = function(_, mapID) return "Zone " .. tostring(mapID) end
addon.GetCityName = function(_, key) return "City " .. key end
addon.GetTownName = function(_, key) return "Town " .. key end
addon.GetTrainerTypeName = function(_, token) return token:sub(1, 1) .. token:sub(2):lower() end
addon.GetSkillName = function(_, id) return "Skill " .. id end

local function sectionsFor(overrides)
    local ctx = makeCtx(overrides)
    local entries = addon.Destinations:Build(ctx)
    return addon.Sections:Build(entries, ctx), entries, ctx
end
local function section(sections, id)
    for _, s in ipairs(sections) do if s.id == id then return s end end
end
local function picks(sections)
    local names = {}
    for _, item in ipairs(section(sections, "relevant") and section(sections, "relevant").items or {}) do
        names[item.name] = item
    end
    return names
end

-- A mage: their class trainer and a weapon master (they can learn weapons), no pets, no ley lines.
local sections, entries = sectionsFor({ class = "MAGE", faction = "Alliance" })
check(#sections == 3 and sections[1].id == "relevant" and sections[2].id == "cities" and sections[3].id == "towns",
    "personally relevant, cities, towns, in that order")
local mage = picks(sections)
check(mage["Nearest Class Trainer"] and #mage["Nearest Class Trainer"].nodeIDs >= 2, "a mage has a class trainer pick over every mage trainer")
check(mage["Nearest Weapon Trainer"], "and a weapon master that teaches something they can learn")
check(not mage["Nearest Pet Trainer"] and not mage["Nearest Demon Trainer"] and not mage["Nearest Ley Line"], "no pet or demon trainers, no ley lines")
for _, item in ipairs(section(sections, "relevant").items) do
    check(item.nodeIDs and #item.nodeIDs > 0 and item.nodeID == item.nodeIDs[1], "each pick can be routed to: " .. item.name)
end

-- Only the professions they have, by the client's name for each.
local alchemist = picks((sectionsFor({ class = "MAGE", faction = "Alliance", spells = { addon.Professions.ALCHEMY } })))
check(alchemist["Nearest Alchemy Trainer"], "a known profession gets its trainer")
check(not alchemist["Nearest Mining Trainer"], "an unknown one doesn't")
check(not mage["Nearest Alchemy Trainer"], "and a character with no professions has none")

-- Pet trainers for hunters, demon trainers for warlocks.
check(picks((sectionsFor({ class = "HUNTER", faction = "Alliance" })))["Nearest Pet Trainer"], "a hunter has a pet trainer")
check(picks((sectionsFor({ class = "WARLOCK", faction = "Alliance" })))["Nearest Demon Trainer"], "a warlock has a demon trainer")
check(not picks((sectionsFor({ class = "WARRIOR", faction = "Alliance" })))["Nearest Pet Trainer"], "a warrior has neither")

-- Ley lines for Skyborne (whoever can read them).
local skyborne = picks((sectionsFor({ class = "DRUID", faction = "Alliance", spells = { 1259705 } })))
check(skyborne["Nearest Ley Line"] and #skyborne["Nearest Ley Line"].nodeIDs >= 4, "a Skyborne has the nearest ley line, over all of them")

-- Weapons already known aren't offered again: a character who knows all of a weapon master's skills gets no pick.
local knowsAll = {}
for _, class in pairs(addon.ClassWeapons) do for _, id in ipairs(class) do knowsAll[#knowsAll + 1] = id end end
check(not picks((sectionsFor({ class = "MAGE", faction = "Alliance", spells = knowsAll })))["Nearest Weapon Trainer"],
    "a character with every weapon skill has no weapon trainer pick")

-- Cities and towns are the player's own faction's, and neutral ones. The other faction's are still in the
-- list a search reads, just not relevant.
local function factions(items)
    local out = {}
    for _, item in ipairs(items) do out[item.faction or "none"] = (out[item.faction or "none"] or 0) + 1 end
    return out
end
local cities = factions(section(sections, "cities").items)
check(cities.Alliance and cities.Alliance >= 3 and not cities.Horde, "an Alliance player's cities are Alliance ones: " .. tostring(cities.Alliance))
local towns = factions(section(sections, "towns").items)
check(towns.Alliance and towns.Alliance > 5 and towns.Both and towns.Both >= 3 and not towns.Horde, "and their towns are Alliance and neutral, no Horde")
local hordeFound = 0
for _, entry in ipairs(entries) do
    if entry.group == "place" and entry.faction == "Horde" and entry.relevant == false then hordeFound = hordeFound + 1 end
end
check(hordeFound >= 10, "the Horde ones are still there for searching, marked not relevant: " .. hordeFound)
local horde = sectionsFor({ class = "WARRIOR", faction = "Horde" })
local hordeCities = factions(section(horde, "cities").items)
check(hordeCities.Horde and hordeCities.Horde >= 3 and not hordeCities.Alliance, "a Horde player gets theirs")
check(section(sections, "cities").items[1].faction ~= nil, "settlement entries say whose they are")

-- Nothing is priced until asked; then every item has a time (or none if there is no way there), a pick knows
-- the nearest place of its kind, and cities and towns are nearest first.
check(section(sections, "cities").items[1].eta == nil and mage["Nearest Class Trainer"].eta == nil, "unpriced to begin with")
local ctx = makeCtx({ class = "MAGE", faction = "Alliance" })
local start = { id = "YOU_sections", mapID = addon.World:GetNode("TAXI_2").mapID, x = 0.55, y = 0.55 }
local session = addon.Journey:Build(ctx, start)
check(session, "a session builds where the player stands")
addon.Sections:Price(sections, session)
local classPick = picks(sections)["Nearest Class Trainer"]
check(classPick.eta and classPick.nearest and classPick.where and classPick.where:find("Place "), "a pick has a time and the nearest place: " .. tostring(classPick.eta) .. " " .. tostring(classPick.where))
local last = -1
for _, item in ipairs(section(sections, "cities").items) do
    if item.eta then
        check(item.eta >= last, "cities are listed nearest first")
        last = item.eta
    end
end
check(last > 0, "and at least one city is reachable")
