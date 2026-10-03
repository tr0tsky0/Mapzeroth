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

-- The multiplier on base speed that wins in this container, and the form behind it (nil: none, or a mount).
local function bestMultiplier(container, ctx)
    local indoor = addon.World:GetFlag(container, "indoor")
    local best, winner = 1.0, nil

    if not indoor then
        -- Riding data wins when a dataset has it (Forever: the skills the character knows, none known is no mount).
        -- A dataset without it (Modern) declares a flat addon.DEFAULT_MOUNT_BONUS instead; the validator stops both.
        local riding
        if addon.RidingSkills then riding = bestRidingBonus(ctx) else riding = addon.DEFAULT_MOUNT_BONUS end
        if riding then best = math.max(best, 1.0 + riding) end
    end

    for _, form in ipairs(addon.Abilities and addon.Abilities.GroundForms or {}) do
        if ctx.knowsSpell(form.spellID) and (not indoor or form.indoorCapable) then
            -- A form's bonus is either flat or earned per rank of a talent (Cat Form's Feral Swiftness).
            local bonus = form.bonus or (form.talent.perRank * ctx.talentRank(form.talent.spellID))
            if 1.0 + bonus > best then best, winner = 1.0 + bonus, form end
        end
    end

    return best, winner
end

local iconSources = {}      -- spellID -> { spellID }, one table per form so edges share it

-- container is a World container object or a path. The second result is what a walking step shows as its
-- picture: the spell of the form that sets the speed ({ spellID }), or nil when on foot or on a mount (mounts
-- get their own picture later: a horse or a wolf).
function addon:GetGroundSpeed(container, ctx)
    local multiplier, winner = bestMultiplier(container, ctx)
    local source
    if winner then
        source = iconSources[winner.spellID]
        if not source then
            source = { spellID = winner.spellID }
            iconSources[winner.spellID] = source
        end
    end
    return addon.WALK_SPEED * multiplier, source
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
