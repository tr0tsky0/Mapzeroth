local addonName, addon = ...

-- Ground speed for a container: base run speed times the best multiplier the
-- player has available. Mounting and outdoor-only forms turn off when the
-- container is indoor; a form flagged indoorCapable keeps working there.

local function bestRidingBonus(ctx)
    local best
    for _, skill in ipairs(addon.RidingSkills or {}) do
        if ctx.knowsSpell(skill.spellID) and (not best or skill.bonus > best) then
            best = skill.bonus
        end
    end
    return best
end

-- container is a World container object or a path.
function addon:GetGroundSpeed(container, ctx)
    local indoor = addon.World:GetFlag(container, "indoor")
    local best = 1.0

    if not indoor then
        local riding = bestRidingBonus(ctx)
        if riding then best = math.max(best, 1.0 + riding) end
    end

    for _, form in ipairs(addon.Abilities and addon.Abilities.GroundForms or {}) do
        if ctx.knowsSpell(form.spellID) and (not indoor or form.indoorCapable) then
            best = math.max(best, 1.0 + form.bonus)
        end
    end

    return addon.WALK_SPEED * best
end
