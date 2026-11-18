local addonName, addon = ...

-- Which places the destination picker shows this player by default. One rule per kind of
-- place; anything without a rule is always shown. Everything else goes to a drill-down,
-- still reachable.

local Relevance = {}
addon.Relevance = Relevance

function Relevance:IsRelevant(node, ctx)
    if node.kind == "trainer" then
        return addon.Trainers:IsRelevant(node, ctx)
    elseif node.kind == "leyline" then
        -- Alliance Skyborne only: the ones who can Read Ley Line.
        return ctx.faction == "Alliance" and addon.LeyLineSpell ~= nil and ctx.knowsSpell(addon.LeyLineSpell)
    elseif node.kind == "convergence" then
        -- Horde Skyborne only: the ones with Skysight.
        return ctx.faction == "Horde" and addon.SkysightSpell ~= nil and ctx.knowsSpell(addon.SkysightSpell)
    elseif node.kind == "stable" then
        -- Hunters, at a stable master of their faction (or one who serves both: no `faction`).
        return ctx.class == "HUNTER" and (not node.faction or not ctx.faction or node.faction == ctx.faction)
    elseif node.kind == "reagent" then
        return self:SellsReagentsTo(node, ctx.class, ctx.faction)
    end
    return true
end

-- Whether a reagent vendor place (Forever's Pois.lua) has an NPC that sells `class` its reagents (an NPC's `classes`)
-- and serves `faction` (its `faction`; none: both). No faction given: any.
function Relevance:SellsReagentsTo(node, class, faction)
    for _, npc in ipairs(node.npcs or {}) do
        if not npc.faction or not faction or npc.faction == faction then
            for _, token in ipairs(npc.classes or {}) do
                if token == class then return true end
            end
        end
    end
    return false
end
