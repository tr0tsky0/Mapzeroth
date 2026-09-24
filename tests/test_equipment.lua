-- Using an equippable teleport item that isn't worn: an "Equip" step first (priced at the item's equip cooldown),
-- then the "Use" step (the rest); Equipment puts back what the item replaced once the trip has moved on.
useTestDistances()
addon.World:Build()
addon.GetNodeName = function(_, id) return "Place " .. id end     -- names come from the client
addon.HasNodeName = function() return true end

local stormwind = addon.World:GetNode("TAXI_2")
local start = { id = "START_STORMWIND", mapID = stormwind.mapID, x = stormwind.x, y = stormwind.y }
addon.Abilities = { Items = {
    { itemID = 9001, to = "TAXI_6", cost = 5, equipCooldown = 20 },              -- worn to use, with its own cooldown
    { itemID = 9002, to = "TAXI_6", cost = 5 },                                  -- worn to use, the default cooldown
} }

local function planFor(overrides)
    local ctx = makeCtx(overrides)
    return addon.Journey:Plan(addon.Journey:Build(ctx, start), "TAXI_6"), ctx
end

-- Not worn: two steps.
local plan = planFor({ items = { 9001 }, equippable = { 9001 } })
check(plan.steps[1].method == "equip" and plan.steps[2].method == "teleport", "an unworn item is put on, then used: " ..
    plan.steps[1].method .. "," .. plan.steps[2].method)
check(plan.steps[1].seconds == 20, "the equip step costs the item's own equip cooldown: " .. tostring(plan.steps[1].seconds))
check(plan.steps[1].source.itemID == 9001 and plan.steps[2].source.itemID == 9001, "and both steps know the item")
check(math.abs(plan.steps[1].seconds + plan.steps[2].seconds - plan.cost) < 1e-6, "the two steps add up to the route's cost")
check(plan.steps[2].seconds == 5 + makeCtx({}).loadingScreenTax, "the use step is the cast plus the loading screen: " .. tostring(plan.steps[2].seconds))

-- No cooldown of its own: the default.
local defaulted = planFor({ items = { 9002 }, equippable = { 9002 } })
check(defaulted.steps[1].seconds == addon.DEFAULT_EQUIP_SECONDS, "an item with no equip cooldown of its own gets the default")

-- Already worn, or not something you wear: one step.
local worn = planFor({ items = { 9001 }, equippable = { 9001 }, equipped = { 9001 } })
check(worn.steps[1].method == "teleport", "an item that is already worn is just used")
local carried = planFor({ items = { 9001 } })
check(carried.steps[1].method == "teleport", "and one that isn't equippable at all is just used")

-- Navigation: the equip step is done when the item is worn, not by being somewhere.
local nav = addon.Navigation
local entry = { name = "Ironforge" }
nav:Start(entry, plan)
local function at(node, extra)
    local s = { now = 0, mapID = stormwind.mapID, x = stormwind.x, y = stormwind.y, equipped = function() return false end }
    for k, v in pairs(extra or {}) do s[k] = v end
    return s
end
local model = nav:Update(at())
check(model.index == 1 and model.step.method == "equip", "the trip begins on the equip step")
model = nav:Update(at())
check(model.index == 1, "and stays there while the item isn't worn, though the player is at the step's node")
model = nav:Update(at(nil, { equipped = function(id) return id == 9001 end }))
check(model.index == 2 and model.step.method == "teleport", "worn: on to using it")
nav:Stop()

-- Equipment: what it puts on, what it puts back.
local worn, calls = { [15] = 555 }, {}
GetInventoryItemID = function(_, slot) return worn[slot] end
IsEquippedItem = function(id) for _, v in pairs(worn) do if v == id then return true end end return false end
InCombatLockdown = function() return false end
C_Item = { GetItemInfoInstant = function(id) return id, "Armor", "Cloth", "INVTYPE_CLOAK" end }
EquipItemByName = function(id, slot) calls[#calls + 1] = "equip " .. id .. "@" .. slot; worn[slot] = id end
PickupInventoryItem = function(slot) calls[#calls + 1] = "pickup " .. slot; worn[slot] = nil end
PutItemInBackpack = function() calls[#calls + 1] = "backpack" end

local E = addon.Equipment
check(E:SlotFor(9001) == 15, "a cloak goes in the cloak slot")
check(E:Equip(9001) and worn[15] == 9001, "it is put on")
check(E.saved.previous == 555 and E.saved.slot == 15, "remembering what it replaced")
E:Sync({ finished = false, step = plan.steps[2] })
check(worn[15] == 9001, "while the trip is still on the item, it stays on")
E:Sync({ finished = false, step = { method = "walk", source = nil } })
check(worn[15] == 555 and E.saved == nil, "once the trip is on to something else, what was there is put back")

worn[15] = nil                                   -- the slot was empty this time
E:Equip(9001)
E:Sync(nil)                                      -- the trip was stopped
check(worn[15] == nil and calls[#calls] == "backpack", "an empty slot is emptied again, the item to the backpack")

E:Equip(9001)
worn[15] = 777                                   -- the player put something else on since
E:Sync(nil)
check(worn[15] == 777 and E.saved == nil, "if the player changed the slot themselves it isn't ours to undo")

InCombatLockdown = function() return true end
worn[15] = 555
InCombatLockdown = function() return false end
E:Equip(9001)
InCombatLockdown = function() return true end
E:Sync(nil)
check(E.saved ~= nil and worn[15] == 9001, "in combat it waits")
InCombatLockdown = function() return false end
E:Sync(nil)
check(E.saved == nil and worn[15] == 555, "and puts things back after it")
