local addonName, addon = ...

-- What the player's class trainer can teach them now, for the picker's tooltip. Every trainer of a class teaches
-- the same abilities at fixed levels (addon.ClassSpells, Data/Forever/ClassSpells.lua), so this is worked out from
-- the player's level, race and what they already know; no trainer visit is needed. An ability can be learned when:
--   * the player's level is at least its level, and their race is one it's for (racial abilities);
--   * they don't know it yet;
--   * the rank before it is known or learnable now (`after`: both can be bought in one visit), or, when the rank
--     before comes from a talent or a quest (`owned`), they already have the ability.

local ClassTraining = {}
addon.ClassTraining = ClassTraining

local function raceAllowed(mask, raceID)
    if not mask or not raceID then return true end
    return math.floor(mask / 2 ^ (raceID - 1)) % 2 == 1
end

local function spellName(spellID)
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if info then return info.name end
    return GetSpellInfo and (GetSpellInfo(spellID)) or nil
end

-- The names of every spell in the player's spellbook (the "do they have this ability at all" test for `owned`).
local function spellbookNames()
    local names = {}
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
            for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local name = C_SpellBook.GetSpellBookItemName(i, bank)
                if name then names[name] = true end
            end
        end
    elseif GetNumSpellTabs then
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for i = offset + 1, offset + count do
                local name = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
                if name then names[name] = true end
            end
        end
    end
    return names
end

-- nil when there's no data for this class (Modern, where class abilities aren't trained). Otherwise
--   { learnable = { { id, level, cost }, ... } (by level), cost = <their total, copper>,
--     nextLevel = <the next level that brings something, or nil> }
-- `owns(name)` (tests) says whether the player has an ability by name; by default, their spellbook.
function ClassTraining:Status(ctx, owns)
    local list = addon.ClassSpells and addon.ClassSpells[ctx.class]
    if not list then return nil end
    local book
    owns = owns or function(name)
        book = book or spellbookNames()
        return book[name] == true
    end
    local byID, nextRank, verdict = {}, {}, {}
    for _, spell in ipairs(list) do
        byID[spell[1]] = spell
        if spell.after then nextRank[spell.after] = spell[1] end
    end
    -- Knowing a later rank means having had this one, whether or not the client still counts it.
    local function knows(id)
        while id do
            if ctx.knowsSpell(id) then return true end
            id = nextRank[id]
        end
        return false
    end

    local function hasPrerequisite(spell)
        if spell.owned then
            local name = spellName(spell[1])
            return name ~= nil and owns(name)
        end
        return true
    end
    -- Can be learned now (memoised: `after` chains are walked once).
    local function learnable(spell)
        local id = spell[1]
        if verdict[id] == nil then
            local ok = spell[2] <= ctx.level and raceAllowed(spell.races, ctx.raceID) and not knows(id)
                and hasPrerequisite(spell)
            if ok and spell.after then
                local before = byID[spell.after]
                ok = knows(spell.after) or (before ~= nil and learnable(before))
            end
            verdict[id] = ok
        end
        return verdict[id]
    end

    local result, cost, nextLevel = {}, 0, nil
    for _, spell in ipairs(list) do
        if learnable(spell) then
            result[#result + 1] = spell
            cost = cost + (spell[3] or 0)
        elseif spell[2] > ctx.level and raceAllowed(spell.races, ctx.raceID) and not knows(spell[1])
            and hasPrerequisite(spell) and (not nextLevel or spell[2] < nextLevel) then
            nextLevel = spell[2]
        end
    end
    table.sort(result, function(a, b) return a[2] < b[2] end)
    return { learnable = result, cost = cost, nextLevel = nextLevel }
end

-- An ability's name for the tooltip: the client's name and rank ("Frostbolt (Rank 4)"), or its name alone while the
-- client hasn't the rank to hand.
function ClassTraining:Label(spellID)
    local name = spellName(spellID)
    if not name then
        if C_Spell and C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(spellID) end
        return nil
    end
    local rank = (C_Spell and C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID))
        or (GetSpellSubtext and GetSpellSubtext(spellID))
    if rank and rank ~= "" then return name .. " (" .. rank .. ")" end
    return name
end
