local addonName, addon = ...

-- A snapshot of the player: who they are and what they can use. Everything
-- that decides whether an edge or ability is available reads this instead of
-- calling client APIs directly, so the pathfinder can be run "as" any
-- character (a Horde druid, a level 10 mage...) by handing it a different
-- context. Tests build contexts by hand.

local function isSpellKnown(spellID)
    if IsPlayerSpell then
        return IsPlayerSpell(spellID) and true or false
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID) and true or false
    end
    return false
end

local function hasItem(itemID)
    if C_Item and C_Item.GetItemCount then
        return (C_Item.GetItemCount(itemID) or 0) > 0
    end
    return (GetItemCount and (GetItemCount(itemID) or 0) > 0) or false
end

-- Is this toy usable by the player? A toy sits in the toy box, not the bags, so an item count can't
-- see it (Personal Key to the Arcantina and most of Modern's teleport toys).
local function hasToy(itemID)
    if not PlayerHasToy or not PlayerHasToy(itemID) then return false end
    if C_ToyBox and C_ToyBox.IsToyUsable then return C_ToyBox.IsToyUsable(itemID) and true or false end
    return true
end

-- Seconds until a spell can be used again (0 when ready).
local function cooldownRemaining(spellID)
    local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID)
    if not info or not info.startTime or info.startTime == 0 then return 0 end
    -- The global cooldown isn't a real cooldown.
    if info.duration <= 1.5 then return 0 end
    return math.max(0, info.startTime + info.duration - GetTime())
end

-- Seconds until an ITEM can be used again (0 when ready). Items don't share the spell
-- cooldown API even when their effect is functionally a spell, so a teleport toy/trinket
-- (Modern's fixed-destination items, addon.Abilities.Items) needs its own check.
local function itemCooldownRemaining(itemID)
    local start, duration
    if C_Item and C_Item.GetItemCooldown then
        start, duration = C_Item.GetItemCooldown(itemID)
    elseif GetItemCooldown then
        start, duration = GetItemCooldown(itemID)
    end
    if not start or start == 0 or not duration or duration <= 1.5 then return 0 end
    return math.max(0, start + duration - GetTime())
end

local function isQuestCompleted(questID)
    return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
end

-- Is a seasonal event (addon.HOLIDAYS key) live right now, cached per key for the session
-- (a snapshot is a snapshot; a holiday doesn't start or end mid-search). No holidays are
-- gated on in Forever's own data yet, so this only does real work for Modern.
local holidayCache = {}
local function isHolidayActive(key)
    if holidayCache[key] ~= nil then return holidayCache[key] end
    local icons = addon.HOLIDAYS and addon.HOLIDAYS[key]
    local active = false
    if icons and C_DateAndTime and C_Calendar and C_Calendar.GetNumDayEvents then
        local today = C_DateAndTime.GetCurrentCalendarTime()
        for i = 1, C_Calendar.GetNumDayEvents(0, today.monthDay) do
            local event = C_Calendar.GetDayEvent(0, today.monthDay, i)
            if event and event.calendarType == "HOLIDAY" and event.iconTexture then
                for _, icon in ipairs(icons) do
                    if event.iconTexture == icon then active = true end
                end
            end
        end
    end
    holidayCache[key] = active
    return active
end

function addon:GetPlayerContext()
    local _, classToken = UnitClass("player")
    local _, raceToken = UnitRace("player")
    return {
        faction = UnitFactionGroup("player"),
        class = classToken,
        race = raceToken,
        level = UnitLevel("player"),
        knowsSpell = isSpellKnown,
        hasItem = hasItem,
        hasToy = hasToy,
        cooldownRemaining = cooldownRemaining,
        itemCooldownRemaining = itemCooldownRemaining,
        hearthNode = addon:GetBoundInnNode(),
        questCompleted = isQuestCompleted,
        holidayActive = isHolidayActive,
        flightNodeFound = function(nodeID) return addon.FlightKnowledge:IsFound(nodeID) end,
        loadingScreenTax = addon.Options:Get("loadingScreenTax"),
        money = GetMoney and GetMoney() or nil,                          -- copper, for what flights cost
        fareFactor = function(nodeID) return addon.FlightKnowledge:FareFactor(nodeID) end,   -- what they pay, per flight master
    }
end

-- The "Anywhere -> Node" abilities the player can use right now: class teleports they
-- know, an item-based teleport (a toy/trinket to a fixed spot, addon.Abilities.Items) they
-- carry, and the hearthstone if they carry it and have a bind. Each entry says where it
-- goes and what it costs; abilities on cooldown, or restricted to the other faction, are
-- left out. An ability with several possible landing spots the player picks between
-- (`toList` instead of a single `to` -- Modern's Mole Machine is the first of these) is
-- expanded into one candidate per spot; the search picks whichever is actually cheapest.
function addon:GetKnownTeleports(ctx)
    local known = {}
    local abilities = addon.Abilities or {}

    local function factionOk(ability)
        return not ability.faction or ability.faction == ctx.faction
    end
    local function spellReady(ability)
        return not ability.spellID or (ctx.cooldownRemaining(ability.spellID) or 0) <= 0
    end
    local function itemReady(ability)
        return not ability.itemID or not ctx.itemCooldownRemaining
            or (ctx.itemCooldownRemaining(ability.itemID) or 0) <= 0
    end
    local function add(ability, to)
        known[#known + 1] = {
            to = to, cost = ability.cost or 0, method = ability.method or "teleport",
            loadingScreens = ability.loadingScreens, ability = ability,
        }
    end
    local function addAll(ability, to)
        if ability.toList then
            for _, dest in ipairs(ability.toList) do add(ability, dest) end
        else
            add(ability, to)
        end
    end

    for _, ability in ipairs(abilities.Teleports or {}) do
        if ability.spellID and factionOk(ability) and ctx.knowsSpell(ability.spellID) and spellReady(ability) then
            addAll(ability, ability.to)
        end
    end
    for _, ability in ipairs(abilities.Hearthstones or {}) do
        -- Almost always the item (the Hearthstone itself); a class spell that goes to the
        -- same wherever-you're-bound place instead (Astral Recall, Modern-only so far) has
        -- no itemID, so it's known the normal spell way.
        local owns = ability.itemID and ctx.hasItem(ability.itemID)
            or (not ability.itemID and ability.spellID and ctx.knowsSpell(ability.spellID))
        if owns and ctx.hearthNode and spellReady(ability) and itemReady(ability) then
            add(ability, ctx.hearthNode)
        end
    end
    for _, ability in ipairs(abilities.Items or {}) do
        local owns = ability.toy and ctx.hasToy and ctx.hasToy(ability.itemID) or ctx.hasItem(ability.itemID)
        if ability.itemID and factionOk(ability) and owns and itemReady(ability) then
            addAll(ability, ability.to)
        end
    end
    return known
end
