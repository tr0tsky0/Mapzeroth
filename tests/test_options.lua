local O = addon.Options

-- Defaults: a loading screen counts for 10 s, windows are full size, Modern Dark.
check(O:Get("loadingScreenTax") == 10, "loading screen time defaults to 10 s")
check(O:Get("scale") == 1, "scale defaults to 100%")
check(O:Get("theme") == "moderndark", "the theme defaults to Modern Dark")
local min, max, step = O:Range("loadingScreenTax")
check(min == 0 and max == 20 and step == 1, "loading screen time runs 0 to 20 s")
check(O:Get("nonsense") == nil, "an unknown setting is nil")

-- Values are forced into range and to whole steps.
check(O:Set("loadingScreenTax", 30) == 20 and O:Get("loadingScreenTax") == 20, "over the top is clamped to 20")
check(O:Set("loadingScreenTax", -5) == 0, "and under to 0")
check(O:Set("loadingScreenTax", 7.4) == 7, "a fractional number of seconds rounds to a whole one")
check(O:Set("loadingScreenTax", "12") == 12, "a number typed as text works")
check(O:Set("loadingScreenTax", "abc") == 10, "junk falls back to the default")
check(math.abs(O:Set("scale", 0.1) - 0.7) < 1e-9 and math.abs(O:Set("scale", 9) - 1.5) < 1e-9, "scale stays between 70% and 150%")
check(math.abs(O:Set("scale", 0.853) - 0.85) < 1e-9, "scale moves in 5% steps: " .. O:Get("scale"))

-- Saved where the game keeps settings, so they survive a reload once saving works.
check(MapzerothRebuildDB.settings.loadingScreenTax == 10 and math.abs(MapzerothRebuildDB.settings.scale - 0.85) < 1e-9,
    "settings are kept in MapzerothRebuildDB.settings")

-- Listeners hear about changes, but not about setting the same value again.
local heard = {}
O:OnChange(function(key, value) heard[#heard + 1] = key .. "=" .. tostring(value) end)
O:Set("loadingScreenTax", 5)
O:Set("loadingScreenTax", 5)
check(#heard == 1 and heard[1] == "loadingScreenTax=5", "a change is announced once: " .. table.concat(heard, ","))
O:Store("loadingScreenTax", 6)
check(#heard == 1 and O:Get("loadingScreenTax") == 6, "Store saves without announcing")

-- Reset puts everything back.
O:Reset()
check(O:Get("loadingScreenTax") == 10 and O:Get("scale") == 1 and O:Get("theme") == "moderndark", "Reset restores the defaults")

-- The routing reads the setting: a loading screen costs what the player chose.
check(addon:GetPlayerContext().loadingScreenTax == 10, "the player context uses the default")
O:Set("loadingScreenTax", 3)
check(addon:GetPlayerContext().loadingScreenTax == 3, "and follows the setting")

-- The theme follows the setting, both at start and live.
local Theme = addon.Theme
O:Set("theme", "classic")
Theme:Init("moderndark")
check(Theme:Current().id == "classic", "a saved theme is used at start")
O:Set("theme", "moderndark")
check(Theme:Current().id == "moderndark", "picking a theme in the settings changes it live")
Theme:Set("classic")
check(O:Get("theme") == "classic", "changing theme another way is remembered too")
