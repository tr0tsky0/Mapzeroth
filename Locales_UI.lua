local addonName, addon = ...

-- Strings for the route and the panel. The destination's name inside them is already in the
-- client's language; only our own words are here, and they are the only ones to translate.

addon:RegisterLocale("enUS", {
    -- One step of a route. %s is the place the step goes to.
    STEP_WALK        = "Walk to %s",
    STEP_FLIGHT      = "Fly to %s",
    STEP_FLIGHT_VIA  = "Fly to %s (via %s)",
    STEP_SHIP        = "Take the boat to %s",
    STEP_ZEPPELIN    = "Take the zeppelin to %s",
    STEP_TRAM        = "Take the tram to %s",
    STEP_PORTAL      = "Use %s",
    STEP_TELEPORT    = "Teleport to %s",
    STEP_HEARTHSTONE = "Use your Hearthstone to go to %s",
    STEP_OTHER       = "Go to %s",

    -- Times.
    TIME_SECONDS = "%ds",
    TIME_MINUTES = "%dm %02ds",
    TIME_HOURS   = "%dh %02dm",
    TIME_ABOUT   = "~%s",

    -- Why a route is longer than it could be. First %s is a flight point, second a time saved.
    HINT_UNFOUND = "You haven't found %s yet. Unlock it and this trip would take %s less.",
    HINT_UNKNOWN = "Open a flight master's window so Mapzeroth can see which flight points you have found. Flying could save %s here.",

    -- The panel.
    PANEL_TITLE       = "Mapzeroth",
    SEARCH_HINT       = "Where to?",
    SEARCH_EMPTY      = "Type a town, flight master, inn, trainer, dungeon or anything else.",
    NO_RESULTS        = "Nothing matches.",
    QUICK_LEYLINE     = "Nearest ley line",
    ROUTE_BACK        = "Back",
    ROUTE_START       = "Start",
    ROUTE_TOTAL       = "%s in total",
    ROUTE_ALREADY     = "You're already here.",
    ROUTE_NONE        = "No route found from here.",
    NOWHERE           = "Mapzeroth can't tell where you are right now (instances aren't covered).",
    -- The settings page.
    OPT_TITLE         = "Mapzeroth",
    OPT_TAX           = "Loading screen time",
    OPT_TAX_DESC      = "How long a loading screen (a portal, teleport, hearthstone or tram) counts for when Mapzeroth times a route.",
    OPT_SCALE         = "Scale",
    OPT_SCALE_DESC    = "The size of the panel beside the map and of the trip window.",
    OPT_THEME         = "Theme",
    OPT_THEME_DESC    = "How the panel and the trip window look.",
    OPT_SECONDS       = "%d s",
    OPT_PERCENT       = "%d%%",

    -- Following a route (the navigator).
    NAV_STEP_OF       = "Step %d of %d",
    NAV_STOP          = "Stop",
    NAV_CLOSE         = "Close",
    NAV_ARRIVED       = "Destination reached",
    NAV_LEFT          = "%s left in total",
    NAV_DISTANCE      = "%d yards",
    MONEY_GOLD        = "%dg",
    MONEY_SILVER      = "%ds",
    MONEY_COPPER      = "%dc",
    ROUTE_FARES       = "%s in fares",
    HINT_BROKE        = "You can't afford this route: the flights cost %s and you have %s.",
    HINT_QUICKER      = "The quickest route would save %s but its flights cost %s. This is the fastest you can afford.",
    NAV_OFFROUTE      = "Flying to %s. The route updates when you land.",
    NAV_REROUTED      = "Route updated",
    NAV_WAIT_FLIGHT   = "Speak to the flight master",
    NAV_FLYING        = "In flight",
    NAV_LONGER        = "Taking longer than planned",
    NAV_WAIT_BOARD    = "Board and wait to depart",
    NAV_UNDERWAY      = "Underway",
    NAV_PORTAL        = "Walk into the portal",
    NAV_COMBAT        = "Can't be used in combat",

    -- What sort of place a search result is, shown under its name.
    -- Other words a player types for a weapon skill whose name (from the client) doesn't contain them,
    -- searched along with it: "Staves" is a staff, "Thrown" is throwing weapons.
    SKILL_ALIAS_227   = "staff staffs",
    SKILL_ALIAS_2567  = "throwing throwing weapons",
    GROUP_place       = "Town or city",
    GROUP_flight      = "Flight master",
    GROUP_transport   = "Transport",
    GROUP_instance    = "Dungeon or raid",
    GROUP_inn         = "Inn",
    GROUP_bank        = "Bank",
    GROUP_auction     = "Auction house",
    GROUP_battlemaster = "Battlemaster",
    GROUP_stable      = "Stable master",
    GROUP_trainer     = "Trainer",
    GROUP_entrance    = "City entrance",
    GROUP_leyline     = "Ley line",
    GROUP_other       = "Place",
})
