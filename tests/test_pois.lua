addon.World:Build()

local function find(pred)
    for _, node in ipairs(addon.Nodes.Pois) do if pred(node) then return node end end
end
local function teaches(npc, spellID)
    for _, id in ipairs(npc.teaches or {}) do if id == spellID then return true end end
    return false
end

-- Merging NPCs into one routing node keeps every NPC, so nothing is lost.
local ironforge = find(function(n) return n.trainer == "WEAPON" and n.city == "ironforge" end)
check(ironforge and #ironforge.npcs == 2, "Ironforge's two weapon masters share a node but both are kept")
local axes, daggers = false, false
for _, npc in ipairs(ironforge.npcs) do
    axes = axes or teaches(npc, 196)      -- One-Handed Axes
    daggers = daggers or teaches(npc, 1180) -- Daggers
end
check(axes and daggers, "the Ironforge weapon masters between them teach axes and daggers")

-- Different cities teach different weapons.
local stormwind = find(function(n) return n.trainer == "WEAPON" and n.city == "stormwind" end)
check(teaches(stormwind.npcs[1], 200), "Stormwind teaches Polearms")
check(not teaches(stormwind.npcs[1], 196), "Stormwind does not teach axes")

-- Every weapon master says what it teaches.
for _, node in ipairs(addon.Nodes.Pois) do
    if node.trainer == "WEAPON" then
        for _, npc in ipairs(node.npcs) do
            check(#(npc.teaches or {}) > 0, "weapon master " .. npc.id .. " has a teaches list")
        end
    end
end

-- Class trainers in a hall are all kept, with no teaches list needed.
local paladins = find(function(n) return n.trainer == "PALADIN" and n.city == "stormwind" end)
check(paladins and #paladins.npcs >= 2, "Stormwind's Paladin trainers are all kept")

-- Dalaran is a city (one way in, walled), so it has an entrance place named after it,
-- and its trainers, inns and stable master are city places rather than town ones.
local entrance = find(function(n) return n.kind == "entrance" and n.city == "dalaran" end)
check(entrance and entrance.mapID == 1416, "Dalaran has an entrance")
check(addon.Cities.dalaran and addon.Cities.dalaran.area == 279, "Dalaran is a city, named by area 279")
check(not addon.Towns.dalaran, "and no longer a town")
local dalaranInns = 0
for _, n in ipairs(addon.Nodes.Pois) do
    if n.kind == "inn" and n.city == "dalaran" then dalaranInns = dalaranInns + 1 end
end
check(dalaranInns == 2, "Dalaran's four innkeepers make two inns (two buildings)")

-- Ironforge's gate was captured in the subzone "Gates of Ironforge" (area 809): both sides carry it,
-- so the client names them, and nothing else picks up an area by accident.
for _, id in ipairs({ "ENTRANCE_C1455_152_857", "ENTRANCE_C1426_534_350" }) do
    local node = addon.World:GetNode(id)
    check(node and node.area == 809, "the Ironforge gate node " .. id .. " carries area 809")
end
check(addon.World:GetNode("ENTRANCE_C1453_741_922").area == nil, "an entrance captured without an area has none")

-- Stormwind's bank is where the player stood at it; Wowhead's bankers, which the game showed to be wrong, are left out.
local bank = addon.World:GetNode("BANK_C1453_638_808")
check(bank and bank.kind == "bank" and bank.city == "stormwind" and math.abs(bank.x - 0.638) < 1e-9, "Stormwind's bank is the captured one")
check(addon.World:GetNode("BANK_2455") == nil, "and Wowhead's listing of it (ignored_npcs.tsv) is gone")
local stormwindBanks = 0
for _, n in ipairs(addon.Nodes.Pois) do
    if n.kind == "bank" and n.city == "stormwind" then stormwindBanks = stormwindBanks + 1 end
end
check(stormwindBanks == 1, "so Stormwind has one bank: " .. stormwindBanks)
for _, n in ipairs(addon.Nodes.Pois) do
    if n.kind == "inn" then check(n.area == nil, "an inn never takes an area (it would lose its name): " .. n.id) end
end
