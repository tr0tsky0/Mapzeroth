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
    end
    return true
end
