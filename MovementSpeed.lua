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
        -- Without riding-skill data (Modern has none) the player is taken to have a mount: addon.DEFAULT_MOUNT_BONUS.
        local riding = bestRidingBonus(ctx) or (not addon.RidingSkills and addon.DEFAULT_MOUNT_BONUS) or nil
        if riding then best = math.max(best, 1.0 + riding) end
    end

    for _, form in ipairs(addon.Abilities and addon.Abilities.GroundForms or {}) do
        if ctx.knowsSpell(form.spellID) and (not indoor or form.indoorCapable) then
            best = math.max(best, 1.0 + form.bonus)
        end
    end

    return addon.WALK_SPEED * best
end

-- Multiplier on a flight-path mount's speed from perks that make it faster (currently just
-- Forever's Frequent Flier legacy perk; always 1.0 on Modern, where the perk doesn't exist).
-- A flight edge's baked-in `cost` seconds divides by this in TravelGraph:Build, the same way
-- a walk edge's divides by GetGroundSpeed above.
function addon:GetFlightSpeedMultiplier(ctx)
    local perk = addon.FREQUENT_FLIER
    if perk and ctx.knowsSpell(perk.spellID) then
        return 1 + perk.speedBonus
    end
    return 1
end
