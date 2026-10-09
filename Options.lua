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
    loadingScreenTax = { default = addon.DEFAULT_LOADING_SCREEN_TAX, min = 0, max = 20, step = 1 },   -- seconds a loading screen costs a route
    maxCooldown = { default = 8, min = 1, max = 8, step = 1 },          -- hours: a longer cooldown isn't routed through; the top (8+) is no limit
    scale = { default = 1, min = 0.7, max = 1.5, step = 0.05 },           -- size of our windows
    theme = { default = "moderndark" },
    showRouteOnMap = { default = true, boolean = true },                  -- the route drawn on the world map
    showRouteOnMinimap = { default = true, boolean = true },              -- and on the minimap, while following a trip
    assumeFlightsFound = { default = true, boolean = true },              -- a flight point Mapzeroth hasn't seen a flight master's window about counts as found (FlightKnowledge.lua)
    docked = { default = true, boolean = true },                          -- the panel: docked beside the map, or free-floating (UI/Panel.lua)
    hideSllcmHint = { default = false, boolean = true },                  -- the picker's pointer to Skyborne Ley Line & Convergence Marker, dismissed (UI/Panel.lua)
    hideMinimapButton = { default = false, boolean = true },              -- the button on the minimap rim (UI/MinimapButton.lua)
    roundTrip = { default = false, boolean = true },                      -- routes are there and back to here (UI/Panel.lua's choice on a route)
    stepMarkers = { default = "icon" },                                   -- a route step shows how it travels: "icon" (a picture) or "chip" (a coloured bar)
}

-- "showPick_<key>": whether the picker offers that pick (a top pick or one of the trainers) (Sections.lua names the
-- keys; the profession ones depend on the dataset, so they aren't listed above). All shown until turned off.
local PICK_PREFIX = "showPick_"
local pickDefinition = { default = true, boolean = true }

local function definition(key)
    return definitions[key] or (type(key) == "string" and key:sub(1, #PICK_PREFIX) == PICK_PREFIX and pickDefinition) or nil
end

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
    local d = definition(key)
    return d and d.default
end

-- Whether the picker pick named `key` (Sections.lua) is shown.
function Options:ShowsPick(key)
    return self:Get(PICK_PREFIX .. key) ~= false
end

function Options:SetShowsPick(key, shown)
    return self:Set(PICK_PREFIX .. key, shown)
end

-- min, max, step of a numeric setting.
function Options:Range(key)
    local d = definition(key)
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
    local d = definition(key)
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
    local picks = {}
    for key in pairs(store(false) or {}) do
        if definition(key) == pickDefinition then picks[#picks + 1] = key end
    end
    for _, key in ipairs(picks) do self:Set(key, true) end
end

-- fn(key, value) runs after any setting changes.
function Options:OnChange(fn)
    listeners[#listeners + 1] = fn
end
