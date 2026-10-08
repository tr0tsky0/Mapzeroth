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

-- The player's current skill in a profession (a key of addon.Professions), or nil when the client can't say.
-- The client names a profession as its first-rank spell does.
local function professionSkill(token)
    local firstRank = addon.Professions and addon.Professions[token]
    local spell = firstRank and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(firstRank)
    if not (spell and spell.name and GetProfessions and GetProfessionInfo) then return nil end
    for _, index in pairs({ GetProfessions() }) do
        local name, _, skill = GetProfessionInfo(index)
        if name == spell.name then return skill end
    end
    return nil
end

-- Points spent in the talent that teaches this spell (0 when none, or when the client has no talent tree).
-- A talent is one spell with its rank on a trait node, so knowing the spell can't say how many points. The
-- tree is walked once per call; callers ask once per speed calculation.
local function talentRank(spellID)
    local cfg = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    local config = cfg and C_Traits and C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(cfg)
    if not config then return 0 end
    for _, treeID in ipairs(config.treeIDs or {}) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
            local node = C_Traits.GetNodeInfo(cfg, nodeID)
            for _, entryID in ipairs(node and node.entryIDs or {}) do
                local entry = C_Traits.GetEntryInfo(cfg, entryID)
                local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
                if def and def.spellID == spellID then return node.currentRank or 0 end
            end
        end
    end
    return 0
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

-- The one item-cooldown rule, for the planner and for the navigator's "ready in" text.
function addon:ItemCooldownRemaining(itemID)
    return itemCooldownRemaining(itemID)
end

local function isQuestCompleted(questID)
    return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
end

-- Is a seasonal event (addon.HOLIDAYS key) live right now, cached per key for the session
-- (a snapshot is a snapshot; a holiday doesn't start or end mid-search). No holidays are
-- gated on in Forever's own data yet, so this only does real work for Modern.
-- The client's calendar has nothing to say until it has been opened and has answered (CALENDAR_UPDATE_EVENT_LIST,
-- Core.lua): until then nothing is live, and that is not cached, so the first real answer is the one kept.
local holidayCache = {}

function addon:ResetHolidayCache()
    holidayCache = {}
end

local function isHolidayActive(key)
    if not addon.calendarReady then return false end
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

-- The maxCooldown setting in seconds, or nil at the top of its range: that reads "8+ h", no limit at all.
function addon:MaxCooldownSeconds()
    local hours = addon.Options:Get("maxCooldown")
    local _, top = addon.Options:Range("maxCooldown")
    if hours >= top then return nil end
    return hours * 3600
end

function addon:GetPlayerContext()
    local _, classToken = UnitClass("player")
    local _, raceToken, raceID = UnitRace("player")
    local inn = addon:GetBoundInnNode()
    local hearthPlace = addon:GetHearthPlace(inn)       -- the bound spot, when no inn of ours is there
    return {
        faction = UnitFactionGroup("player"),
        class = classToken,
        race = raceToken,
        raceID = raceID,          -- for abilities only some races learn (ClassSpells' race masks)
        level = UnitLevel("player"),
        knowsSpell = isSpellKnown,
        professionSkill = professionSkill,    -- current skill points, nil if unknown (no gate then)
        talentRank = talentRank,
        hasItem = hasItem,
        hasToy = hasToy,
        cooldownRemaining = cooldownRemaining,
        itemCooldownRemaining = itemCooldownRemaining,
        hearthNode = inn or (hearthPlace and hearthPlace.id),   -- where the hearthstone lands
        hearthPlace = hearthPlace,
        campPlace = addon:GetCampPlace(),                   -- where Return to Camp goes (Vulpera), when a camp was made
        questCompleted = isQuestCompleted,
        holidayActive = isHolidayActive,
        isEquippable = function(itemID) return IsEquippableItem ~= nil and IsEquippableItem(itemID) and true or false end,
        isEquipped = function(itemID) return IsEquippedItem ~= nil and IsEquippedItem(itemID) and true or false end,
        -- Every context carries both. flightUsable (can they fly to this point? FlightKnowledge.Usable) is the one
        -- routing predicate; flightNodeFound (true, false, or nil: no window has said) is the raw fact, for hints.
        flightNodeFound = function(nodeID) return addon.FlightKnowledge:IsFound(nodeID) end,
        flightUsable = function(nodeID)
            return addon.FlightKnowledge.Usable(addon.FlightKnowledge:IsFound(nodeID), addon.Options:Get("assumeFlightsFound"))
        end,
        -- The art id the client shows for a map: which side of a phase group (Zidormi) the player is on.
        mapArtID = function(mapID) return C_Map and C_Map.GetMapArtID and C_Map.GetMapArtID(mapID) or nil end,
        loadingScreenTax = addon.Options:Get("loadingScreenTax"),
        maxCooldown = addon:MaxCooldownSeconds(),                        -- nil: no limit
        money = GetMoney and GetMoney() or nil,                          -- copper, for what flights cost
        fareFactor = function(nodeID) return addon.FlightKnowledge:FareFactor(nodeID) end,   -- what they pay, per flight master
    }
end

-- Between routes that take the same time, which ability to spend: one with a short cooldown, then a long
-- one, then one that is used up (`consumable`). A bias in seconds far under anything the search times, so it
-- only decides ties; Pathfinder adds it to the seed and takes it back out of the trip's time.
local BIAS = 1e-4
function addon:AbilityBias(ability)
    local cooldown = ability.cooldown or 0
    local bias = BIAS * cooldown / (cooldown + 3600)       -- grows with the cooldown, never reaching BIAS
    if ability.consumable then bias = bias + BIAS end
    return bias
end

-- (`cooldown` on an ability in the data files is its full cooldown: it ranks abilities (AbilityBias) and is
-- held against the maxCooldown setting, but whether one is ready now is asked of the live cooldown APIs
-- through the context. `bind` on Forever's hearthstone is documentation only.)
-- The "Anywhere -> Node" abilities the player can use right now: class teleports they
-- know, an item-based teleport (a toy/trinket to a fixed spot, addon.Abilities.Items) they
-- carry, the hearthstone if they carry it and have a bind, and Return to Camp if they made one. Each entry says where it
-- goes and what it costs; abilities on cooldown, with a cooldown over the maxCooldown
-- setting, or restricted to the other faction, are left out. An ability with several possible landing spots the player picks between
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
    -- An equippable item that isn't worn is put on first (its own step, priced at its equip cooldown), then used.
    local function equipSeconds(ability)
        if not ability.itemID or ability.toy then return nil end
        if not (ctx.isEquippable and ctx.isEquippable(ability.itemID)) then return nil end
        if ctx.isEquipped and ctx.isEquipped(ability.itemID) then return nil end
        return ability.equipCooldown or addon.DEFAULT_EQUIP_SECONDS or 0
    end
    local function add(ability, to, defaultMethod)
        if ctx.maxCooldown and (ability.cooldown or 0) > ctx.maxCooldown then return end
        local wait = equipSeconds(ability)
        local source = ability
        if wait then
            source = {}
            for k, v in pairs(ability) do source[k] = v end
            source.equipSeconds = wait                       -- the route's steps read this to make a step of it
        end
        known[#known + 1] = {
            to = to, cost = (ability.cost or 0) + (wait or 0), method = ability.method or defaultMethod or "teleport",
            loadingScreens = ability.loadingScreens, ability = source, bias = addon:AbilityBias(ability),
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
            add(ability, ctx.hearthNode, "hearthstone")
        end
    end
    -- Return to Camp: to the spot the player last made camp (ctx.campPlace), not a fixed one.
    for _, ability in ipairs(abilities.Camps or {}) do
        if ctx.campPlace and ctx.knowsSpell(ability.spellID) and spellReady(ability) then
            add(ability, ctx.campPlace.id)
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
