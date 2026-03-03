-- StepUtils.lua
-- Shared math and step-resolution utilities used by GPSNavigator and RouteExecutionFrame.
local addonName, addon = ...

addon.StepUtils = {}
local S = addon.StepUtils

-- atan2 polyfill for Lua 5.1 (math.atan2 may not exist)
function S.Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end

    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end

    return 0
end

-- Convert normalised map coords to world-space position vector.
function S.GetWorldPosition(mapID, x, y)
    if not mapID or not x or not y then
        return nil
    end

    local mapPos = CreateVector2D(x, y)
    if not mapPos then
        return nil
    end

    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapID, mapPos)
    return worldPos
end

-- Returns distance (yards) and heading (radians) between two map positions.
-- Returns nil, nil if the positions cannot be compared.
function S.GetDistanceAndHeading(fromMap, fromX, fromY, toMap, toX, toY)
    if not fromMap or not fromX or not fromY or not toMap or not toX or not toY then
        return nil, nil
    end

    local fromWorld = S.GetWorldPosition(fromMap, fromX, fromY)
    local toWorld   = S.GetWorldPosition(toMap,   toX,   toY)

    local dx, dy

    if fromWorld and toWorld then
        dx = toWorld.x - fromWorld.x
        dy = toWorld.y - fromWorld.y
    elseif fromMap == toMap then
        dx = (toX - fromX) * addon.MAP_SCALE
        dy = (toY - fromY) * addon.MAP_SCALE
    else
        return nil, nil
    end

    local distance = math.sqrt(dx * dx + dy * dy)
    local heading  = S.Atan2(dy, dx)
    return distance, heading
end

-- Format a yard distance for display.
function S.FormatDistance(distance)
    if not distance then
        return "Target on another map"
    end

    if distance >= 1000 then
        return string.format("%.1f km", distance / 1000)
    end

    return string.format("%.0f yd", distance)
end

-- Build a one-line description of a route step for UI display.
function S.GetStepActionText(stepData)
    if not stepData then
        return "No active step"
    end

    if stepData.abilityName then
        if stepData.destinationName then
            return string.format("Use %s to %s", stepData.abilityName, stepData.destinationName)
        end
        return string.format("Use %s", stepData.abilityName)
    end

    local methodPrefix = addon.METHOD_DISPLAY_TEXT[stepData.method] or "Go to"
    return string.format("%s %s", methodPrefix, stepData.destination or "destination")
end

-- Look up a node by ID and return a position table, or nil if not found.
function S.ResolveNodeTarget(nodeID)
    if not nodeID then
        return nil
    end

    local node = addon.TravelGraph:GetNodeByID(nodeID)
    if not node or not node.mapID or not node.x or not node.y then
        return nil
    end

    return {
        mapID = node.mapID,
        x     = node.x,
        y     = node.y,
        name  = node.displayName or node.name or "Target"
    }
end

-- Build a /cast or /use macro string for a step, or nil if not applicable.
function S.BuildStepMacro(stepData)
    if stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        if spellInfo then
            return string.format("/cast %s", spellInfo.name)
        end
        return string.format("/cast %d", stepData.spellID)
    end

    if stepData.itemID then
        local itemName = C_Item.GetItemInfo(stepData.itemID)
        if itemName then
            return string.format("/use %s", itemName)
        end
        return string.format("/use %d", stepData.itemID)
    end

    return nil
end

-- Return the icon texture for a step (spell icon, item icon, or method fallback).
function S.GetStepActionIcon(stepData)
    if not stepData then
        return nil
    end

    if stepData.spellID then
        local spellInfo = C_Spell.GetSpellInfo(stepData.spellID)
        if spellInfo and spellInfo.iconID then
            return spellInfo.iconID
        end
    end

    if stepData.itemID then
        local itemIcon = C_Item.GetItemIconByID(stepData.itemID)
        if itemIcon then
            return itemIcon
        end
    end

    return addon.TRAVEL_ICONS[stepData.method] or addon.TRAVEL_ICONS.walk
end
