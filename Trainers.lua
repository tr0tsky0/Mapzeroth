local addonName, addon = ...

-- Which trainers matter to this player right now. The destination picker shows the
-- relevant ones by default and puts every other trainer in a drill-down. A trainer only trains
-- its own faction (an NPC's `faction`, from Wowhead's reactions or its town's; none: anyone's), so
-- the other faction's never count. Beyond that:
--   * class trainer: yours only;
--   * weapon master: teaches a weapon your class can learn and you don't have;
--   * profession trainer: for a profession you have, teaches the NEXT rank (the one above your
--     highest) and talks to you, that is its top rank isn't too far above yours
--     (addon.PROFESSION_TRAINER_REACH): an Artisan trainer won't talk to an Apprentice (gathering
--     professions' trainers talk to anyone: addon.GatheringProfessions). So it drops
--     out once you have outgrown it, and doesn't show until you are close enough;
--   * riding instructor: teaches a riding rank you don't know;
--   * pet trainer: hunters; demon trainer: warlocks.
-- It works from the spell ids each NPC teaches and from what the player knows.
--
-- An NPC with no teaches list is one we couldn't get the data for. That is not the same
-- as teaching nothing, so it is shown when its type is relevant at all (a profession you
-- have, any weapon master or riding instructor). Specialization trainers (`specialty`)
-- are the exception: they only matter once you've chosen the specialization, so they
-- stay in the drill-down until that is modelled.

local Trainers = {}
addon.Trainers = Trainers

-- Trainer types that belong to one class's pets: hunters' Pet Trainers and warlocks'
-- Demon Trainers.
local PET_TRAINER_CLASS = { PET = "HUNTER", DEMON = "WARLOCK" }

local function asSet(list)
    local set = {}
    for _, id in ipairs(list or {}) do set[id] = true end
    return set
end

-- Does this NPC teach something in `wanted` (a set, or nil for anything) that the
-- player doesn't know?
local function teachesUnknown(npc, ctx, wanted)
    for _, spellID in ipairs(npc.teaches) do
        if (not wanted or wanted[spellID]) and not ctx.knowsSpell(spellID) then
            return true
        end
    end
    return false
end

-- Returns `eligible`, `wanted`, `gate`: whether this kind of trainer is of any use to the player
-- at all, which taught spells count (a set, or nil for any), and for a profession its ranks and the
-- player's own (`gate`, see talksTo).
local function needFor(node, ctx)
    local token = node.trainer
    if addon.CLASS_TOKENS[token] then
        return token == ctx.class, nil
    end
    if PET_TRAINER_CLASS[token] then
        return PET_TRAINER_CLASS[token] == ctx.class, nil
    end
    if token == "WEAPON" then
        return true, asSet(addon.ClassWeapons and addon.ClassWeapons[ctx.class])
    end
    if token == "RIDING" then
        local ranks = {}
        for _, skill in ipairs(addon.RidingSkills or {}) do ranks[skill.spellID] = true end
        return true, ranks
    end
    local firstRank = addon.Professions and addon.Professions[token]
    if firstRank then
        -- Only a profession you have, and only the next rank up from your highest.
        local ranks = addon.ProfessionRanks and addon.ProfessionRanks[token] or {}
        local known = 0
        for i, spellID in ipairs(ranks) do
            if ctx.knowsSpell(spellID) then known = i end
        end
        local wanted = {}
        if ranks[known + 1] then wanted[ranks[known + 1]] = true end
        return ctx.knowsSpell(firstRank), wanted,
            { ranks = ranks, known = known, anyone = addon.GatheringProfessions and addon.GatheringProfessions[token] }
    end
    return true, nil
end

-- Will this profession trainer talk to the player? Its top rank (the highest rank it teaches) mustn't be
-- more than PROFESSION_TRAINER_REACH above the player's own. A trainer whose ranks we don't know, or that
-- teaches none of this profession's rank spells, is given the benefit of the doubt. A gathering profession's
-- trainers (herbalism, mining, skinning) teach every rank to anyone.
local function talksTo(npc, gate)
    if not gate or gate.anyone then return true end
    local teaches = asSet(npc.teaches)
    for i = #gate.ranks, 1, -1 do
        if teaches[gate.ranks[i]] then
            return i - gate.known <= addon.PROFESSION_TRAINER_REACH
        end
    end
    return true
end

-- Does this NPC train the player's faction? An NPC with no faction on record trains anyone.
local function serves(npc, ctx)
    return not npc.faction or not ctx.faction or npc.faction == ctx.faction
end

-- The NPCs at a place that will train this player: those of their faction. `other` is the faction of the place's
-- trainers when none of them will (every one belongs to the other faction), else nil.
local function servingNPCs(node, ctx)
    local npcs, other = {}, nil
    for _, npc in ipairs(node.npcs or {}) do
        if serves(npc, ctx) then npcs[#npcs + 1] = npc else other = npc.faction end
    end
    if #npcs > 0 then other = nil end
    return npcs, other
end

-- The NPCs at a trainer place worth visiting, in data order. A place with no NPC
-- records at all (a bare capture) counts as one NPC we know nothing about.
function Trainers:RelevantNPCs(node, ctx)
    local result = {}
    if node.kind ~= "trainer" then return result end
    local eligible, wanted, gate = needFor(node, ctx)
    if not eligible then return result end
    if addon.CLASS_TOKENS[node.trainer] or PET_TRAINER_CLASS[node.trainer] then
        -- These teach their whole class/pet skill set; being the right class is enough.
        local npcs, other = servingNPCs(node, ctx)
        if other then return result end         -- the other faction's
        for _, npc in ipairs(npcs) do result[#result + 1] = npc end
        if #result == 0 then result[1] = {} end
        return result
    end
    local npcs, other = servingNPCs(node, ctx)
    if other then return result end
    if #npcs == 0 then npcs = { {} } end
    for _, npc in ipairs(npcs) do
        if not npc.specialty then
            if npc.teaches and #npc.teaches > 0 then
                if teachesUnknown(npc, ctx, wanted) and talksTo(npc, gate) then result[#result + 1] = npc end
            else
                result[#result + 1] = npc      -- nothing known about what it teaches
            end
        end
    end
    return result
end

-- True if this place is worth showing this player by default.
function Trainers:IsRelevant(node, ctx)
    if node.kind ~= "trainer" then return true end
    return #self:RelevantNPCs(node, ctx) > 0
end

-- What the picker's tooltip says about a trainer place, as data (the UI words it). One of:
--   { kind = "profession", rank = <the player's rank index, 0 for none>, has = <they have the profession>,
--     npcs = { { top = <highest rank index it teaches, or nil if unknown>, specialty = true?, useful = bool }, ... } }
--   { kind = "weapon", learnable = { spellID, ... } }   the weapons it teaches that the class can learn and doesn't know
--   { kind = "class", own = <the player's class> }       what's left to learn comes from ClassTraining
-- or nil for any other kind of trainer. Any of them carries `otherFaction` (and nothing else about what it teaches)
-- when every trainer there belongs to the other faction: they won't train this player.
function Trainers:Describe(node, ctx)
    if not node or node.kind ~= "trainer" then return nil end
    local token = node.trainer
    local serving, other = servingNPCs(node, ctx)
    if addon.CLASS_TOKENS[token] then
        return { kind = "class", own = token == ctx.class, otherFaction = other }
    end
    if token == "WEAPON" then
        if other then return { kind = "weapon", otherFaction = other } end
        local wanted, learnable, seen = asSet(addon.ClassWeapons and addon.ClassWeapons[ctx.class]), {}, {}
        for _, npc in ipairs(serving) do
            for _, spellID in ipairs(npc.teaches or {}) do
                if wanted[spellID] and not seen[spellID] and not ctx.knowsSpell(spellID) then
                    seen[spellID] = true
                    learnable[#learnable + 1] = spellID
                end
            end
        end
        table.sort(learnable)
        return { kind = "weapon", learnable = learnable }
    end
    if addon.Professions and addon.Professions[token] then
        local eligible, wanted, gate = needFor(node, ctx)
        local info = { kind = "profession", rank = gate.known, has = eligible, npcs = {}, otherFaction = other }
        if other then return info end
        local useful, byKey = {}, {}
        for _, npc in ipairs(self:RelevantNPCs(node, ctx)) do useful[npc] = true end
        for _, npc in ipairs(serving) do
            local teaches, top = asSet(npc.teaches), nil
            for i, spellID in ipairs(gate.ranks) do
                if teaches[spellID] then top = i end
            end
            -- Two trainers of one rank at a place are one line.
            local key = npc.specialty and "specialty" or (top or "unknown")
            local same = byKey[key]
            if same then
                same.useful = same.useful or useful[npc] == true
            else
                byKey[key] = { top = not npc.specialty and top or nil, specialty = npc.specialty, useful = useful[npc] == true }
                info.npcs[#info.npcs + 1] = byKey[key]
            end
        end
        -- Lowest rank first; specialization trainers and ones we know nothing about after.
        table.sort(info.npcs, function(a, b) return (a.top or 99) < (b.top or 99) end)
        return info
    end
    return nil
end
