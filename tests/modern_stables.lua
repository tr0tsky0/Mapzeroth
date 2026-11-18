-- Stable masters (Data/Modern/Stables.lua): a hunter's "Stable Master" pick under Nearest's Other (Sections.lua), of
-- their faction's stables, turned off on the settings page's Picker page; no hunter, or the pick off, and it isn't there.
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

check(addon:GetNodeName("STABLE_TEST_SW") == "stormwind Stable Master", "a city's stable is named for the city: "
    .. tostring(addon:GetNodeName("STABLE_TEST_SW")))
check(addon:GetNodeName("STABLE_TEST_BOTH") == "Zone 84 Stable Master", "one of no town for its zone: "
    .. tostring(addon:GetNodeName("STABLE_TEST_BOTH")))

local function build(class, faction)
    local ctx = makeCtx({ class = class, faction = faction })
    return addon.Sections:Build(addon.Destinations:Build(ctx), ctx)
end
-- The stable master pick, or nil.
local function personal(sections)
    for _, s in ipairs(sections) do
        if s.id == "nearest" then
            for _, child in ipairs(s.children) do
                for _, item in ipairs(child.id == "nearest_other" and child.items or {}) do
                    if item.key == "stable" then return item end
                end
            end
        end
    end
end
local function set(list)
    local out = {}
    for _, id in ipairs(list) do out[id] = true end
    return out
end

-- An Alliance hunter: the pick under Nearest, with the nearest of their faction's and the shared one.
local sections = build("HUNTER", "Alliance")
local stable = personal(sections)
check(stable and sections[1].id == "nearest", "a hunter gets the pick, under Nearest, above the expansion's places")
check(stable.name == "Stable Master" and stable.group == "stable" and stable.pick, "named Stable Master")
local ids = set(stable.nodeIDs)
check(ids.STABLE_TEST_SW and ids.STABLE_TEST_BOTH and not ids.STABLE_TEST_ORG,
    "to their faction's stables and the shared one, not the Horde's")
check(not addon.Sections:NeedsPricing(sections, "nearest"), "a pick: no route search to open it")
local horde = set(personal(build("HUNTER", "Horde")).nodeIDs)
check(horde.STABLE_TEST_ORG and horde.STABLE_TEST_BOTH and not horde.STABLE_TEST_SW, "and the Horde's for a Horde hunter")

-- Anyone else: no stables. Searching still finds them, after what is relevant.
check(not personal(build("MAGE", "Alliance")), "a mage has no stable master pick")
local entries = addon.Destinations:Build(makeCtx({ class = "MAGE" }))
local found = addon.Destinations:Find(entries, "STABLE_TEST_SW")
check(found and found.group == "stable" and found.relevant == false, "a mage still finds stable masters by searching")

-- The pick is a setting on the Picker page, for hunters only.
local function choices(class)
    local keys = {}
    for _, choice in ipairs(addon.Sections:PickChoices(class, "Alliance")) do keys[choice.key] = choice.label end
    return keys
end
check(choices("HUNTER").stable == "Stable Master", "the Picker page offers it to a hunter")
check(not choices("MAGE").stable, "and not to a mage")
addon.Options:SetShowsPick("stable", false)
check(not personal(build("HUNTER", "Alliance")), "turned off: not there")
addon.Options:SetShowsPick("stable", true)
check(personal(build("HUNTER", "Alliance")), "on again: back")

-- The nearest of them is where the pick goes.
local ctx = makeCtx({ class = "HUNTER", faction = "Alliance" })
local trip = route(ctx, "CITY_STORMWIND", stable.nodeIDs)
check(trip and ids[trip.goal], "the pick routes to one of its stables: " .. tostring(trip and trip.goal))
