local addonName, addon = ...

-- The player's settings: what they are, their defaults and limits, and who to tell when one
-- changes. They live in MapzerothRebuildDB.settings (per account). Nothing here draws anything;
-- UI/OptionsPanel.lua is the page that edits them.
--
-- (Named Options, not Settings: Settings is the game's own settings API.)

local Options = {}
addon.Options = Options

-- key -> { default, min, max, step } for numbers; text settings have only a default; on/off ones say boolean.
local definitions = {
    loadingScreenTax = { default = addon.DEFAULT_LOADING_SCREEN_TAX or 10, min = 0, max = 20, step = 1 },   -- seconds a loading screen costs a route
    scale = { default = 1, min = 0.7, max = 1.5, step = 0.05 },           -- size of our windows
    theme = { default = "moderndark" },
    showRouteOnMap = { default = true, boolean = true },                  -- the route drawn on the world map
    showRouteOnMinimap = { default = true, boolean = true },              -- and on the minimap, while following a trip
}

local listeners = {}

local function store(create)
    if not MapzerothRebuildDB then
        if not create then return nil end
        MapzerothRebuildDB = {}
    end
    if not MapzerothRebuildDB.settings then
        if not create then return nil end
        MapzerothRebuildDB.settings = {}
    end
    return MapzerothRebuildDB.settings
end

function Options:Default(key)
    return definitions[key] and definitions[key].default
end

-- min, max, step of a numeric setting.
function Options:Range(key)
    local d = definitions[key]
    return d and d.min, d and d.max, d and d.step
end

function Options:Get(key)
    local saved = store(false)
    local value = saved and saved[key]
    if value == nil then return self:Default(key) end
    return value
end

-- A value forced into a setting's limits, and to a whole number of steps for numbers.
local function clean(key, value)
    local d = definitions[key]
    if not d then return nil end
    if d.boolean then return value and true or false end
    if d.min then
        value = tonumber(value)
        if not value then return d.default end
        value = math.max(d.min, math.min(d.max, value))
        -- Round to the nearest step (the tiny addition keeps 0.85 from rounding down).
        value = d.min + math.floor((value - d.min) / d.step + 0.5 + 1e-9) * d.step
        return math.max(d.min, math.min(d.max, value))
    end
    return value
end

-- Change a setting. Returns the value actually kept.
function Options:Set(key, value)
    value = clean(key, value)
    if value == nil then return nil end
    if value == self:Get(key) then return value end
    store(true)[key] = value
    for _, fn in ipairs(listeners) do fn(key, value) end
    return value
end

-- Save a setting without telling anyone (for whoever just applied it themselves).
function Options:Store(key, value)
    value = clean(key, value)
    if value ~= nil then store(true)[key] = value end
end

function Options:Reset()
    for key, d in pairs(definitions) do self:Set(key, d.default) end
end

-- fn(key, value) runs after any setting changes.
function Options:OnChange(fn)
    listeners[#listeners + 1] = fn
end
