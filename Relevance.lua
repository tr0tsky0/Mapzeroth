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
        -- Only players who can Read Ley Line (all Skyborne, and only Skyborne, today).
        return addon.LeyLineSpell ~= nil and ctx.knowsSpell(addon.LeyLineSpell)
    end
    return true
end
