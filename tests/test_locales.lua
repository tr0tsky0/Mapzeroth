-- Translations: every key is one English has, and every string keeps English's placeholders
-- in the same order, since format fills them by position (and a mismatch errors in game).

local LOCALES = { "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

local english = addon:GetLocaleStrings("enUS")
check(english, "English strings are registered")

-- The conversions in a format string, in order, ignoring flags and widths ("%02d" is "d").
-- A positional "%1$s" doesn't match, so it shows up as a mismatch.
local function conversions(text)
    local out = {}
    for spec in text:gmatch("%%[%-%d%.]*[%a%%]") do
        if spec ~= "%%" then out[#out + 1] = spec:sub(-1) end
    end
    return table.concat(out, ",")
end

for _, locale in ipairs(LOCALES) do
    local strings = addon:GetLocaleStrings(locale)
    check(strings, locale .. " is registered")
    for key, value in pairs(strings) do
        check(english[key] ~= nil, locale .. " has a key English doesn't: " .. key)
        check(type(value) == "string" and value ~= "", locale .. " " .. key .. " is empty")
        check(conversions(value) == conversions(english[key]),
            locale .. " " .. key .. " placeholders '" .. conversions(value) .. "' but English has '"
            .. conversions(english[key]) .. "'")
    end
end

-- Completeness: every interface string English has, each locale has too, bar the brand name (kept in
-- English) and the search aliases (language-specific: a copied English alias would be wrong).
local NOT_TRANSLATED = { PANEL_TITLE = true, OPT_TITLE = true }
local uiKeys = addon:GetUIStringKeys()
check(next(uiKeys), "the interface strings are known")
for _, locale in ipairs(LOCALES) do
    local strings = addon:GetLocaleStrings(locale)
    for key in pairs(uiKeys) do
        if not NOT_TRANSLATED[key] and not key:find("^SKILL_ALIAS_") then
            check(strings[key] ~= nil, locale .. " lacks " .. key)
        end
    end
end

-- The client's locale picks the table, and a key it lacks still falls back to English.
local realGetLocale = GetLocale
GetLocale = function() return "deDE" end
check(addon.L["NAV_STOP"] == "Stopp", "deDE string: " .. addon.L["NAV_STOP"])
check(addon.L["PANEL_TITLE"] == "Mapzeroth", "deDE falls back to English")
GetLocale = realGetLocale
check(addon.L["NAV_STOP"] == "Stop", "back to English")
