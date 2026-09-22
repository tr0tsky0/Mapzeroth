local addonName, addon = ...

-- Every string the addon shows that WE wrote lives here (or in a data file's
-- own locale table), keyed, never inline. Text the client already localizes
-- (zone names, flight master names, spell names) is read from the client and
-- never appears here.
--
-- addon.L["KEY"] resolves the active client locale first, then English, then
-- the key itself, so a missing translation can never blank the UI.

local strings = {}

function addon:RegisterLocale(locale, tbl)
    local target = strings[locale]
    if not target then
        target = {}
        strings[locale] = target
    end
    for key, value in pairs(tbl) do
        target[key] = value
    end
end

local function lookup(key)
    local active = strings[GetLocale()]
    local value = active and active[key]
    if value ~= nil then return value end
    local english = strings.enUS
    return english and english[key]
end

-- True if some locale actually defines this key (L[key] alone can't tell,
-- since it falls back to returning the key).
function addon:HasString(key)
    return lookup(key) ~= nil
end

addon.L = setmetatable({}, {
    __index = function(_, key)
        local value = lookup(key)
        if value ~= nil then return value end
        return key
    end,
})

addon:RegisterLocale("enUS", {
    -- Patterns for naming nodes that have no explicit name and no client name.
    -- %s is a zone name the client already localized.
    NODE_KIND_DOCK     = "%s Harbor",
    NODE_KIND_ZEPPELIN = "%s Zeppelin Tower",
    NODE_KIND_TRAM     = "%s Tram Entrance",
    NODE_KIND_PORTAL   = "%s Portal",
    NODE_KIND_TELEPORT = "%s Teleport Landing",
    NODE_KIND_BORDER   = "%s / %s border",

    -- Places in a town; %s is the town's name.
    NODE_KIND_INN      = "%s Inn",
    NODE_KIND_BANK     = "%s Bank",
    NODE_KIND_AUCTION  = "%s Auction House",
    NODE_KIND_BATTLEMASTER = "%s Battlemaster",
    NODE_KIND_STABLE   = "%s Stable Master",
    NODE_KIND_ENTRANCE = "%s Entrance",
    NODE_KIND_LEYLINE  = "%s Ley Line",
    -- A flight master, named for the city or town it stands in rather than the client's
    -- raw taxi-point name ("Stormwind, Elwynn"), which doesn't read as a destination.
    NODE_KIND_FLIGHTMASTER = "%s Flight Master",
    NODE_KIND_SETTLEMENT = "%s",
    -- First %s is the settlement (or zone), second is what it trains.
    NODE_KIND_TRAINER  = "%s %s Trainer",

    -- Trainer types that aren't a class (class names come from the client).
    TRAINER_WEAPON     = "Weapon",
    TRAINER_RIDING     = "Riding",
    TRAINER_PET        = "Pet",
    TRAINER_DEMON      = "Demon",
})
