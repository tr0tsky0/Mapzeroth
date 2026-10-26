-- Stable masters (Data/Modern/Stables.lua): a hunter's "Nearest Stable Master" pick under Personally Relevant
-- (Sections.lua), of their faction's stables, turned off on the settings page's Picker page; no hunter, or the pick
-- off, and the section isn't there at all.
--   python tests/harness.py --modern modern_stables
-- Stand-in stables, so the test doesn't follow the scraped data: one in Stormwind, one in Orgrimmar, one for both.
addon.Nodes.Stables = {
    { id = "STABLE_TEST_SW", container = "ek_overworld.map84", mapID = 84, x = 0.56, y = 0.46, kind = "stable",
      city = "stormwind", faction = "Alliance", npcs = { { id = 1 } } },
    { id = "STABLE_TEST_ORG", container = "kalimdor_overworld.map85", mapID = 85, x = 0.48, y = 0.62, kind = "stable",
      city = "orgrimmar", faction = "Horde", npcs = { { id = 2 } } },
    { id = "STABLE_TEST_BOTH", container = "ek_overworld.map84", mapID = 84, x = 0.50, y = 0.50, kind = "stable",
      npcs = { { id = 3 } } },
}
useTestDistances()
addon.World:Build()
C_Map = { GetMapInfo = function(id) return { name = "Zone " .. id, mapType = 3, parentMapID = 13 } end }
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function() return {} end }
addon.GetZoneName = function(_, mapID) return "Zone " .. tostring(mapID) end
addon.GetCityName = function(_, key) return key end
EJ_GetInstanceInfo = function(id) return "Instance " .. id end

check(addon.STABLE_PICK, "Modern offers the stable master pick (Data/Modern/Places.lua)")
check(addon:GetNodeName("STABLE_TEST_SW") == "stormwind Stable Master", "a city's stable is named for the city: "
    .. tostring(addon:GetNodeName("STABLE_TEST_SW")))
check(addon:GetNodeName("STABLE_TEST_BOTH") == "Zone 84 Stable Master", "one of no town for its zone: "
    .. tostring(addon:GetNodeName("STABLE_TEST_BOTH")))

local function build(class, faction)
    local ctx = makeCtx({ class = class, faction = faction })
    return addon.Sections:Build(addon.Destinations:Build(ctx), ctx)
end
local function personal(sections)
    for _, s in ipairs(sections) do if s.id == "trainers" then return s end end
end
local function set(list)
    local out = {}
    for _, id in ipairs(list) do out[id] = true end
    return out
end

-- An Alliance hunter: the section, titled Personally Relevant, with the nearest of their faction's and the shared one.
local sections = build("HUNTER", "Alliance")
local section = personal(sections)
check(section and section.title == "Personally Relevant", "a hunter gets Personally Relevant")
check(sections[1] == section, "first, above the expansion's places")
local stable = section.items[1]
check(#section.items == 1 and stable.name == "Nearest Stable Master" and stable.group == "stable" and stable.pick,
    "holding Nearest Stable Master")
local ids = set(stable.nodeIDs)
check(ids.STABLE_TEST_SW and ids.STABLE_TEST_BOTH and not ids.STABLE_TEST_ORG,
    "to their faction's stables and the shared one, not the Horde's")
check(not addon.Sections:NeedsPricing(sections, "trainers"), "a pick: no route search to open it")
local horde = set(personal(build("HUNTER", "Horde")).items[1].nodeIDs)
check(horde.STABLE_TEST_ORG and horde.STABLE_TEST_BOTH and not horde.STABLE_TEST_SW, "and the Horde's for a Horde hunter")

-- Anyone else: no stables, so no section at all. Searching still finds them, after what is relevant.
check(not personal(build("MAGE", "Alliance")), "a mage has no Personally Relevant")
local entries = addon.Destinations:Build(makeCtx({ class = "MAGE" }))
local found = addon.Destinations:Find(entries, "STABLE_TEST_SW")
check(found and found.group == "stable" and found.relevant == false, "a mage still finds stable masters by searching")

-- The pick is a setting on the Picker page, for hunters only; off, and the section goes with it.
local function choices(class)
    local keys = {}
    for _, choice in ipairs(addon.Sections:PickChoices(class, "Alliance")) do keys[choice.key] = choice.label end
    return keys
end
check(choices("HUNTER").stable == "Nearest Stable Master", "the Picker page offers it to a hunter")
check(not choices("MAGE").stable, "and not to a mage")
addon.Options:SetShowsPick("stable", false)
check(not personal(build("HUNTER", "Alliance")), "turned off: no Personally Relevant")
addon.Options:SetShowsPick("stable", true)
check(personal(build("HUNTER", "Alliance")), "on again: back")

-- The nearest of them is where the pick goes.
local ctx = makeCtx({ class = "HUNTER", faction = "Alliance" })
local trip = route(ctx, "CITY_STORMWIND", stable.nodeIDs)
check(trip and ids[trip.goal], "the pick routes to one of its stables: " .. tostring(trip and trip.goal))
