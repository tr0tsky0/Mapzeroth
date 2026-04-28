-- EdgeRequirements.lua
-- Handles all requirement checking for fixed edges in mapzeroth_data
local addonName, addon = ...

-- ============================================================================
-- HOLIDAY DETECTION SYSTEM
-- ============================================================================

local holidayCache = {} -- Just { [holidayName] = boolean }
local calendarReady = false

-- ============================================================================
-- INTERNAL FUNCTIONS (local)
-- ============================================================================

local function IsHolidayActive(holidayKey)
    -- Return cached result
    if holidayCache[holidayKey] ~= nil then
        return holidayCache[holidayKey]
    end

    if not calendarReady then
        return false
    end

    local icons = addon.HOLIDAYS[holidayKey]
    if not icons then
        -- Invalid key, bail early
        holidayCache[holidayKey] = false
        return false
    end

    local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
    local numEvents = C_Calendar.GetNumDayEvents(0, currentCalendarTime.monthDay)

    for i = 1, numEvents do
        local event = C_Calendar.GetDayEvent(0, currentCalendarTime.monthDay, i)

        if event and event.calendarType == "HOLIDAY" and event.iconTexture then
            -- Check if icon matches any in the array
            for _, iconID in ipairs(icons) do
                if event.iconTexture == iconID then
                    holidayCache[holidayKey] = true
                    return true
                end
            end
        end
    end

    holidayCache[holidayKey] = false
    return false
end

function addon:OnCalendarReady()
    calendarReady = true
    holidayCache = {}
end

-- ============================================================================
-- REQUIREMENT CHECKER FUNCTIONS
-- ============================================================================

local requirementCheckers = {
    -- Holiday requirement
    holiday = function(requiredHoliday)
        return IsHolidayActive(requiredHoliday)
    end,

    -- Quest completion
    quest = function(questID)
        return C_QuestLog.IsQuestFlaggedCompleted(questID)
    end,

    questNotCompleted = function(questID)
        return not C_QuestLog.IsQuestFlaggedCompleted(questID)
    end,

    -- Minimum character level
    minLevel = function(level)
        return UnitLevel("player") >= level
    end,

    -- Maximum character level
    maxLevel = function(level)
        return UnitLevel("player") <= level
    end,

    -- Class requirement
    class = function(requiredClass)
        local _, classToken = UnitClass("player")
        return classToken == requiredClass
    end,

    -- Faction requirement
    faction = function(requiredFaction)
        local playerFaction = UnitFactionGroup("player")
        return playerFaction == requiredFaction
    end,

    -- Reputation requirement
    reputation = function(repReq)
        local factionData = C_Reputation.GetFactionDataByID(repReq.factionID)
        if not factionData then
            return false
        end
        return factionData.reaction >= repReq.standing
    end,

    -- Covenant requirement
    covenant = function(covenantID)
        return C_Covenants.GetActiveCovenantID() == covenantID
    end,

    -- Time phase requirement: { mapArtID = { mapID, artID } }
    -- Checks whether the given mapID is currently showing the expected art phase.
    -- simulatedPhases overrides live values during phase-aware Dijkstra routing.
    mapArtID = function(param, simulatedPhases)
        local checkMapID    = param[1] or param.mapID
        local requiredArtID = param[2] or param.artID
        if checkMapID == nil then return false end
        local currentArtID = (simulatedPhases and simulatedPhases[checkMapID])
                          or C_Map.GetMapArtID(checkMapID)
        return currentArtID == requiredArtID
    end,

    -- Any quest in a list completed (for faction-specific quest variants)
    anyQuest = function(questList)
        for _, questID in ipairs(questList) do
            if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                return true
            end
        end
        return false
    end,

    -- Multiple requirements (ANY)
    anyOf = function(subRequirements, simulatedPhases)
        for requirementType, value in pairs(subRequirements) do
            local checker = requirementCheckers[requirementType]
            if checker and checker(value, simulatedPhases) then
                return true
            end
        end
        return false
    end
}

-- ============================================================================
-- PUBLIC API (on addon table)
-- ============================================================================

-- Called when calendar is ready
function addon:OnCalendarReady()
    calendarReady = true
    holidayCache = {}
end

-- Main checker: evaluates all requirements on an edge.
-- simulatedPhases is an optional { [mapID] = artID } table used during
-- phase-aware Dijkstra routing to override live C_Map.GetMapArtID values.
function addon:CheckEdgeRequirements(edge, simulatedPhases)
    if not edge.requirements then
        return true
    end

    for requirementType, value in pairs(edge.requirements) do
        local checker = requirementCheckers[requirementType]

        if not checker then
            print(string.format("[Mapzeroth] WARNING: Unknown requirement type '%s' on edge %s -> %s", requirementType,
                edge.from or "?", edge.to or "?"))
            return false
        end

        if not checker(value, simulatedPhases) then
            return false
        end
    end

    return true
end

-- Debug helper: explain why an edge passed/failed
function addon:ExplainEdgeRequirements(edge)
    if not edge.requirements then
        return "No requirements"
    end

    local reasons = {}
    for requirementType, value in pairs(edge.requirements) do
        local passed = false

        if requirementType == "holiday" then
            passed = IsHolidayActive(value)
        elseif requirementType == "quest" then
            passed = C_QuestLog.IsQuestFlaggedCompleted(value)
        elseif requirementType == "minLevel" then
            passed = UnitLevel("player") >= value
        elseif requirementType == "maxLevel" then
            passed = UnitLevel("player") <= value
        elseif requirementType == "class" then
            passed = UnitClass("player") == value
        elseif requirementType == "faction" then
            passed = UnitFactionGroup("player") == value
        elseif requirementType == "reputation" then
            local factionData = C_Reputation.GetFactionDataByID(value.factionID)
            passed = factionData and factionData.reaction >= value.standing
        elseif requirementType == "covenant" then
            passed = C_Covenants.GetActiveCovenantID() == value
        elseif requirementType == "mapArtID" then
            local checkMapID   = value[1] or value.mapID
            local requiredArtID = value[2] or value.artID
            passed = checkMapID ~= nil and C_Map.GetMapArtID(checkMapID) == requiredArtID
        end

        table.insert(reasons, string.format("%s: %s", requirementType, passed and "✓" or "✗"))
    end

    return table.concat(reasons, ", ")
end
