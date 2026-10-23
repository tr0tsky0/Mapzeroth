local function meets(req, overrides) return addon:MeetsRequirements(req, makeCtx(overrides)) end

check(meets(nil), "no requirements always pass")
check(meets({ faction = "Alliance" }), "faction match")
check(not meets({ faction = "Horde" }), "faction mismatch")
check(meets({ faction = "Alliance", class = "MAGE" }), "AND of two matches")
check(not meets({ faction = "Alliance", class = "DRUID" }), "AND fails when one fails")
check(meets({ race = "Skyborne" }, { race = "Skyborne" }), "race match")
check(not meets({ race = "Skyborne" }), "race mismatch")
check(meets({ minLevel = 10, maxLevel = 30 }), "level in range")
check(not meets({ minLevel = 40 }), "level too low")
check(meets({ quest = 5 }, { quests = { [5] = true } }), "quest completed")
check(not meets({ quest = 5 }), "quest not completed")
check(meets({ notQuest = 5 }), "notQuest passes when not completed")
check(not meets({ notQuest = 5 }, { quests = { [5] = true } }), "notQuest fails when completed")
check(meets({ anyOf = { faction = "Horde", class = "MAGE" } }), "anyOf passes on one match")
check(not meets({ anyOf = { faction = "Horde", class = "DRUID" } }), "anyOf fails on none")
check(meets({ anyQuest = { 5, 6 } }, { quests = { [6] = true } }), "anyQuest passes when either is done")
check(not meets({ anyQuest = { 5, 6 } }), "anyQuest fails when neither is")
check(meets({ holiday = "love_is_in_the_air" }, { holidays = { love_is_in_the_air = true } }), "holiday live")
check(not meets({ holiday = "love_is_in_the_air" }), "holiday not live")
check(not meets({ bogus = 1 }), "unknown requirement fails closed")

-- Holidays as the real context answers them: nothing before the calendar has loaded (and that isn't
-- remembered), then the calendar's answer, kept for the session.
do
    local realHolidays, realDate, realCalendar, realReady = addon.HOLIDAYS, C_DateAndTime, C_Calendar, addon.calendarReady
    addon.HOLIDAYS = { test_fair = { 111, 222 } }
    C_DateAndTime = { GetCurrentCalendarTime = function() return { monthDay = 15 } end }
    local events, queries = { { calendarType = "HOLIDAY", iconTexture = 222 } }, 0
    C_Calendar = {
        GetNumDayEvents = function() queries = queries + 1; return #events end,
        GetDayEvent = function(_, _, i) return events[i] end,
    }
    local holidayActive = addon:GetPlayerContext().holidayActive

    addon.calendarReady = nil
    local loaded = events
    events = {}
    check(holidayActive("test_fair") == false, "a holiday isn't live before the calendar has loaded")
    check(queries == 1 and not addon.calendarReady, "an empty calendar isn't taken as an answer")

    events = loaded
    check(holidayActive("test_fair") == true,
          "live once the calendar has events, even unannounced (after a /reload): the earlier no was not cached")
    check(addon.calendarReady == true, "and events there count as the calendar's answer")
    events = {}
    check(holidayActive("test_fair") == true, "and the answer is kept for the session")
    addon:ResetHolidayCache()
    check(holidayActive("test_fair") == false, "until the calendar reports again (the cache is reset)")
    check(holidayActive("no_such_holiday") == false, "an unknown holiday is never live")

    -- The calendar left showing another month (the calendar window, another addon): today is read at its offset.
    C_DateAndTime.GetCurrentCalendarTime = function() return { year = 2026, month = 10, monthDay = 23 } end
    local byOffset = { [-1] = { { calendarType = "HOLIDAY", iconTexture = 111 } }, [0] = {} }
    C_Calendar = {
        GetMonthInfo = function() return { year = 2026, month = 11 } end,
        GetNumDayEvents = function(offset) return #(byOffset[offset] or {}) end,
        GetDayEvent = function(offset, _, i) return byOffset[offset][i] end,
    }
    addon:ResetHolidayCache()
    check(holidayActive("test_fair") == true, "today's events are found while the calendar shows next month")

    -- An unanswered calendar is asked again (each time the panel is filled); an answered one is left alone.
    local opens = 0
    C_Calendar.OpenCalendar = function() opens = opens + 1 end
    addon.calendarReady = nil
    addon:RequestCalendar()
    addon:RequestCalendar()
    check(opens == 2, "the calendar is asked again while it hasn't answered")
    addon.calendarReady = true
    addon:RequestCalendar()
    check(opens == 2, "and not once it has")

    addon.HOLIDAYS, C_DateAndTime, C_Calendar, addon.calendarReady = realHolidays, realDate, realCalendar, realReady
    addon:ResetHolidayCache()
end
