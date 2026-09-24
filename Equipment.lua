local addonName, addon = ...

-- Putting on a teleport item that has to be worn (a cloak, ring, trinket, tabard...) and putting back what was
-- there. The route has an "Equip <item>" step before "Use <item>" (Journey.lua); this is what the navigator's
-- button does for the first, and what runs once the trip has moved on from the second.
--
-- Equipping an item is not a protected action, so we do it ourselves out of combat (EquipItemByName). Using it
-- is: that is the navigator's secure button, and one click of ours can never do both. Before putting the item on
-- we note what was in its slot (and the offhand, for a two-handed weapon); Restore puts it back, or takes the
-- item off into the backpack when the slot was empty.

local Equipment = {}
addon.Equipment = Equipment

-- INVTYPE_ token -> the slots it can go in; we use the first.
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 }, INVTYPE_TABARD = { 19 },
}
local OFFHAND = 17

local function equipLocOf(itemID)
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, loc = C_Item.GetItemInfoInstant(itemID)
        return loc
    end
    if GetItemInfoInstant then
        local _, _, _, loc = GetItemInfoInstant(itemID)
        return loc
    end
end

-- The slot the item goes in, or nil when we don't know what it is.
function Equipment:SlotFor(itemID)
    local slots = SLOTS[equipLocOf(itemID) or ""]
    return slots and slots[1] or nil
end

-- What is put away: { itemID (ours), slot, previous (what was there, or nil), twoHand, previousOffhand }, or nil.
Equipment.saved = nil

-- Puts the item on, remembering what it replaces. False (and why) if it can't be done now.
function Equipment:Equip(itemID)
    if InCombatLockdown and InCombatLockdown() then return false, "combat" end
    if IsEquippedItem and IsEquippedItem(itemID) then return true end
    local slot = self:SlotFor(itemID)
    if not slot then return false, "slot" end
    if not (self.saved and self.saved.itemID == itemID) then
        local twoHand = equipLocOf(itemID) == "INVTYPE_2HWEAPON"
        self.saved = {
            itemID = itemID, slot = slot, previous = GetInventoryItemID("player", slot), twoHand = twoHand,
            previousOffhand = twoHand and GetInventoryItemID("player", OFFHAND) or nil,
        }
    end
    EquipItemByName(itemID, slot)
    return true
end

-- Puts back what the item replaced. Only when our item is still the one in the slot (if the player has changed
-- it since, it isn't ours to undo). In combat it waits for the next call. True once nothing is left to restore.
function Equipment:Restore()
    local saved = self.saved
    if not saved then return true end
    if InCombatLockdown and InCombatLockdown() then return false end
    if GetInventoryItemID("player", saved.slot) == saved.itemID then
        if saved.previous then
            EquipItemByName(saved.previous, saved.slot)
        else
            PickupInventoryItem(saved.slot)             -- the slot was empty: the item goes to the backpack
            PutItemInBackpack()
        end
        if saved.twoHand and saved.previousOffhand then EquipItemByName(saved.previousOffhand, OFFHAND) end
    end
    self.saved = nil
    return true
end

-- Called on every update of the trip with its model (nil once it is stopped): once the trip is on a step that
-- isn't about the item we put on -- the teleport is done and the player has arrived, or the trip has ended --
-- put things back.
function Equipment:Sync(model)
    local saved = self.saved
    if not saved then return end
    local step = model and not model.finished and model.step
    local aboutIt = step and step.source and step.source.itemID == saved.itemID
    if not aboutIt then self:Restore() end
end

-- Seconds until the item can be used, 0 when it can be (an item just put on has a cooldown).
function Equipment:CooldownLeft(itemID)
    return addon:ItemCooldownRemaining(itemID)
end
