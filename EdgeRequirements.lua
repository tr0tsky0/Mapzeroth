local addonName, addon = ...

-- Data-driven requirement checks. An edge's `requirements` table is ANDed:
-- every key must pass. Each checker is (value, ctx) -> boolean, where ctx is
-- a player context (see PlayerAbilities.lua). Adding a requirement type is
-- adding one entry here.

local checkers
checkers = {
    faction  = function(value, ctx) return ctx.faction == value end,
    class    = function(value, ctx) return ctx.class == value end,
    race     = function(value, ctx) return ctx.race == value end,
    minLevel = function(value, ctx) return (ctx.level or 0) >= value end,
    maxLevel = function(value, ctx) return (ctx.level or 0) <= value end,
    quest    = function(value, ctx) return ctx.questCompleted(value) end,
    notQuest = function(value, ctx) return not ctx.questCompleted(value) end,

    -- anyOf = { quest = 123, faction = "Horde" }: true if any one entry passes.
    anyOf = function(value, ctx)
        for key, v in pairs(value) do
            local check = checkers[key]
            if check and check(v, ctx) then return true end
        end
        return false
    end,
}

addon.RequirementCheckers = checkers

function addon:MeetsRequirements(requirements, ctx)
    if not requirements then return true end
    for key, value in pairs(requirements) do
        local check = checkers[key]
        -- An unknown requirement can't be shown to hold, so it fails closed;
        -- the validator reports these.
        if not check or not check(value, ctx) then
            return false
        end
    end
    return true
end
