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
    local isEquipped = addon.ItemFn("IsEquippedItem")
    if isEquipped and isEquipped(itemID) then return true end
    local slot = self:SlotFor(itemID)
    if not slot then return false, "slot" end
    if not (self.saved and self.saved.itemID == itemID) then
        local twoHand = equipLocOf(itemID) == "INVTYPE_2HWEAPON"
        self.saved = {
            itemID = itemID, slot = slot, previous = GetInventoryItemID("player", slot), twoHand = twoHand,
            previousOffhand = twoHand and GetInventoryItemID("player", OFFHAND) or nil,
        }
    end
    addon.ItemFn("EquipItemByName")(itemID, slot)
    return true
end

-- One go at putting things back. True once they are, or once the slot holds something else (the player has
-- changed it since: it isn't ours to undo).
local function putBack(saved)
    local worn = GetInventoryItemID("player", saved.slot)
    if worn == saved.itemID then
        if saved.previous then
            addon.ItemFn("EquipItemByName")(saved.previous, saved.slot)
        else
            PickupInventoryItem(saved.slot)             -- the slot was empty: the item goes to the backpack
            PutItemInBackpack()
        end
        worn = GetInventoryItemID("player", saved.slot)
        if worn == saved.itemID then return false end   -- not taken yet (the swap lands later, or was refused)
    end
    if worn ~= saved.previous then return true end
    -- The two-hander is off: the offhand back in its empty slot.
    if saved.twoHand and saved.previousOffhand and GetInventoryItemID("player", OFFHAND) == nil then
        addon.ItemFn("EquipItemByName")(saved.previousOffhand, OFFHAND)
        return GetInventoryItemID("player", OFFHAND) ~= nil
    end
    return true
end

-- Tries a second apart while putting back hasn't taken: just out of a loading screen the client refuses gear
-- swaps for a moment, and the navigator (which calls Restore on every update) may be closed by then.
-- With the navigator's updates as well, 30 tries is some 10-30 seconds.
local RETRY_SECONDS, TRIES = 1, 30

-- Puts back what the item replaced. In combat it waits. True once nothing is left to restore.
function Equipment:Restore()
    local saved = self.saved
    if not saved then return true end
    if not (InCombatLockdown and InCombatLockdown()) then
        saved.tries = (saved.tries or 0) + 1
        if putBack(saved) or saved.tries >= TRIES then
            self.saved = nil
            return true
        end
    end
    if not saved.retrying and C_Timer and C_Timer.After then
        saved.retrying = true
        C_Timer.After(RETRY_SECONDS, function()
            saved.retrying = false
            if self.saved == saved then self:Restore() end
        end)
    end
    return false
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
