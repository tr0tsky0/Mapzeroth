addon.World:Build()

-- Client APIs are absent headless, so stand-ins for the few the names use.
local maps = {
    [1411] = { name = "Durotar", mapType = 3, parentMapID = 1414 },
    [1413] = { name = "The Barrens", mapType = 3, parentMapID = 1414 },
    [1454] = { name = "Orgrimmar", mapType = 3, parentMapID = 1414 },
    [1414] = { name = "Kalimdor", mapType = 2, parentMapID = 947 },
    [947]  = { name = "Azeroth", mapType = 1, parentMapID = 0 },
}
C_Map = { GetMapInfo = function(id) return maps[id] end }
Enum = { UIMapType = { Continent = 2 } }
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 1414 then return { { nodeID = 23, name = "Orgrimmar, Durotar" } } end
    return {}
end }

addon:ClearNodeNameCache()

-- 1. Names we gave: explicit locale strings.
check(addon:GetNodeName("DOCK_STORMWIND") == "Stormwind Harbor", "explicit name: " .. addon:GetNodeName("DOCK_STORMWIND"))

-- 2. Flight masters at a city or town we know take its name ("Orgrimmar Flight Master"), not the
-- client's raw taxi-point name, which reads as a zone label rather than a destination.
check(addon:GetNodeName("TAXI_23") == "Orgrimmar Flight Master", "taxi name: " .. addon:GetNodeName("TAXI_23"))
-- ...unless we override what the client says (a node with no real taxi id).
check(addon:GetNodeName("TAXI_POWDERFUSE") == "Powderfuse Port, Riverglades", "override for a taxi-style node")

-- 3. Border crossings are built from the two zones' names.
check(addon:GetNodeName("BORDER_DUROTAR_TO_THE_BARRENS") == "Durotar / The Barrens border",
    "border name: " .. addon:GetNodeName("BORDER_DUROTAR_TO_THE_BARRENS"))

-- 4. A node with no string falls back to a kind pattern over the zone name.
addon:RegisterLocale("enUS", {}) -- no-op; keeps the API exercised
table.insert(addon.Nodes.Kalimdor, { id = "DOCK_TESTONLY", container = "kalimdor.durotar", mapID = 1411, x = 0.5, y = 0.5 })
table.insert(addon.Nodes.Kalimdor, { id = "INSTANCE_67", container = "kalimdor.durotar", mapID = 1411, x = 0.5, y = 0.5 })
addon.World:Build()
addon:ClearNodeNameCache()
check(addon:GetNodeName("DOCK_TESTONLY") == "Durotar Harbor", "kind fallback: " .. addon:GetNodeName("DOCK_TESTONLY"))
check(addon:GetNodeName("NOT_A_NODE") == "NOT_A_NODE", "unknown id falls back to itself")

-- A dungeon/raid entrance (Modern only so far) is named from the client's own Dungeon
-- Journal by its journalInstanceID, not a kind pattern -- there's no settlement or zone
-- name that would say "The Stonecore" on its own.
EJ_GetInstanceInfo = function(id) if id == 67 then return "The Stonecore" end end
check(addon:GetNodeName("INSTANCE_67") == "The Stonecore", "instance name: " .. addon:GetNodeName("INSTANCE_67"))
EJ_GetInstanceInfo = nil
addon:ClearNodeNameCache()
check(addon:GetNodeName("INSTANCE_67") == "INSTANCE_67", "and falls back to the raw id without that API")

-- 5. Locales: a translation wins, and anything untranslated falls back to English.
addon:RegisterLocale("deDE", { NODE_DOCK_STORMWIND = "Hafen von Sturmwind" })
GetLocale = function() return "deDE" end
addon:ClearNodeNameCache()
check(addon:GetNodeName("DOCK_STORMWIND") == "Hafen von Sturmwind", "translated name")
check(addon:GetNodeName("DOCK_RATCHET") == "Ratchet Harbor", "untranslated name falls back to English")
GetLocale = function() return "enUS" end

-- 6. Every node we created has a name string (the validator warns otherwise).
local missing = {}
for _, list in pairs(addon.Nodes) do
    for _, node in ipairs(list) do
        local id = node.id
        if id ~= "DOCK_TESTONLY" and not node.kind and not node.area
                and not id:find("^TAXI_%d+$") and not id:find("^INSTANCE_%d+$") and not id:find("^BORDER_")
                and not addon:HasString("NODE_" .. id) then
            missing[#missing + 1] = id
        end
    end
end
check(#missing == 0, "nodes with no name string: " .. table.concat(missing, ", "))

-- 7. Places in a town: kind pattern over the town's name.
-- Kharanos has neither a flight master nor an area id, so its name is a locale string.
local function inn(town)
    for _, node in ipairs(addon.Nodes.Pois) do
        if node.town == town and node.kind == "inn" then return node.id end
    end
end
local kharanosInn, goldshireInn = inn("kharanos"), inn("goldshire")
check(kharanosInn, "there is a Kharanos inn")
check(addon.Towns.goldshire and not addon.Cities.goldshire, "Goldshire is a town, not a city")
check(addon.Cities.stormwind and not addon.Towns.stormwind, "Stormwind is a city, not a town")
check(addon:GetNodeName(kharanosInn) == "Kharanos Inn", "town-string name: " .. addon:GetNodeName(kharanosInn))

-- Ratchet has a flight master, so its town takes the client's name for it, minus the zone.
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 1414 then return { { nodeID = 80, name = "Ratchet, The Barrens" } } end
    return {}
end }
addon:ClearNodeNameCache()
local ratchetBank
for _, node in ipairs(addon.Nodes.Pois) do
    if node.town == "ratchet" and node.kind == "bank" then ratchetBank = node.id end
end
check(ratchetBank, "there is a Ratchet bank")
check(addon:GetNodeName(ratchetBank) == "Ratchet Bank", "flight-master town name: " .. addon:GetNodeName(ratchetBank))

-- A town with an area id (Goldshire is area 87) uses the client's area name.
check(addon.Towns.goldshire.area == 87, "Goldshire is named by its area")
C_Map.GetAreaInfo = function(id) if id == 87 then return "Goldshire (client)" end end
addon:ClearNodeNameCache()
check(addon:GetNodeName(goldshireInn) == "Goldshire (client) Inn", "area-based town name")

-- A node inside a named area takes the client's name for it (Valanaar's skydocks).
C_Map.GetAreaInfo = function(id) if id == 16628 then return "Valanaar Skydocks (client)" end end
addon:ClearNodeNameCache()
check(addon:GetNodeName("DOCK_VALANAAR") == "Valanaar Skydocks (client)", "area-named dock: " .. addon:GetNodeName("DOCK_VALANAAR"))

-- 8. Cities name their places the same way: Stormwind takes its flight master's name.
maps[1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 }
maps[1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 }
C_TaxiMap = { GetTaxiNodesForMap = function(id)
    if id == 1415 then return { { nodeID = 2, name = "Stormwind, Elwynn" } } end
    return {}
end }
addon:ClearNodeNameCache()
local stormwindInn
for _, node in ipairs(addon.Nodes.Pois) do
    if node.city == "stormwind" and node.kind == "inn" then stormwindInn = node.id end
end
check(stormwindInn, "there is a Stormwind inn")
check(addon:GetNodeName(stormwindInn) == "Stormwind Inn", "city place name: " .. addon:GetNodeName(stormwindInn))

-- 9. Trainers: class names come from the client, weapon/riding from our strings, and a
-- trainer outside any settlement is named after its zone.
LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage" }
maps[1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 1415 }
local function find(pred)
    for _, node in ipairs(addon.Nodes.Pois) do if pred(node) then return node.id end end
end
local mage = find(function(n) return n.kind == "trainer" and n.trainer == "MAGE" and n.city == "stormwind" end)
check(mage and addon:GetNodeName(mage) == "Stormwind Mage Trainer", "class trainer name: " .. tostring(mage and addon:GetNodeName(mage)))
local weapon = find(function(n) return n.kind == "trainer" and n.trainer == "WEAPON" and n.city == "stormwind" end)
check(weapon and addon:GetNodeName(weapon) == "Stormwind Weapon Trainer", "weapon trainer name: " .. tostring(weapon and addon:GetNodeName(weapon)))
local riding = find(function(n) return n.kind == "trainer" and n.trainer == "RIDING" and not n.city and not n.town and n.mapID == 1429 end)
check(riding and addon:GetNodeName(riding) == "Elwynn Forest Riding Trainer", "zone-named trainer: " .. tostring(riding and addon:GetNodeName(riding)))

-- 10. Professions are named by the client's name for their first-rank spell.
C_Spell = { GetSpellInfo = function(id) if id == 3908 then return { name = "Tailoring" } end end }
local tailor = find(function(n) return n.kind == "trainer" and n.trainer == "TAILORING" and n.city == "stormwind" end)
check(tailor and addon:GetNodeName(tailor) == "Stormwind Tailoring Trainer", "profession trainer name: " .. tostring(tailor and addon:GetNodeName(tailor)))

-- 11. Rank text loads lazily: the first look has a name but no rank, and asks for a load.
local loadRequests, loaded = {}, false
C_Spell = {
    GetSpellInfo = function(id) return { name = "Tailoring" } end,
    GetSpellSubtext = function(id) return loaded and "Journeyman" or nil end,
    RequestLoadSpellData = function(id) loadRequests[#loadRequests + 1] = id end,
}
local name1, rank1 = addon:GetSpellLabel(3909)
check(name1 == "Tailoring" and rank1 == nil, "first look: name but no rank yet")
check(loadRequests[1] == 3909, "first look requests the spell data")
loaded = true
local name2, rank2 = addon:GetSpellLabel(3909)
check(name2 == "Tailoring" and rank2 == "Journeyman", "second look: rank text is there")
check(#loadRequests == 1, "no further load request once it has loaded")
