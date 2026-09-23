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

-- Seconds until a spell can be used again (0 when ready).
local function cooldownRemaining(spellID)
    local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID)
    if not info or not info.startTime or info.startTime == 0 then return 0 end
    -- The global cooldown isn't a real cooldown.
    if info.duration <= 1.5 then return 0 end
    return math.max(0, info.startTime + info.duration - GetTime())
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
        cooldownRemaining = cooldownRemaining,
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
-- know, and the hearthstone if they carry it and have a bind. Each entry says where it
-- goes and what it costs; abilities on cooldown are left out.
function addon:GetKnownTeleports(ctx)
    local known = {}
    local abilities = addon.Abilities or {}

    local function ready(ability)
        return not ability.spellID or (ctx.cooldownRemaining(ability.spellID) or 0) <= 0
    end
    local function add(ability, to)
        known[#known + 1] = {
            to = to, cost = ability.cost or 0, method = ability.method or "teleport",
            loadingScreens = ability.loadingScreens, ability = ability,
        }
    end

    for _, ability in ipairs(abilities.Teleports or {}) do
        if ability.spellID and ctx.knowsSpell(ability.spellID) and ready(ability) then
            add(ability, ability.to)
        end
    end
    for _, ability in ipairs(abilities.Hearthstones or {}) do
        if ability.itemID and ctx.hasItem(ability.itemID) and ctx.hearthNode and ready(ability) then
            add(ability, ctx.hearthNode)
        end
    end
    return known
end
