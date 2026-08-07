-- Locales.lua
-- Translation table for Mapzeroth.
--
-- English is the base. Every other locale only overrides the keys it
-- wants translated, and a missing key falls back to the key itself via
-- the metatable at the bottom, so a lookup can never return nil and a
-- half finished translation can never blank out the UI.
--
-- Note what is deliberately NOT in here: the names of zones, dungeons,
-- flight masters and portals. Those come from the client at runtime -
-- see NodeNames.lua - because the client already knows them in every
-- language Blizzard ships, and a hand written list of 1000 place names
-- goes stale with every patch.

local addonName, addon = ...

local L = {}
addon.L = L

-----------------------------------------------------------
-- enUS / base
-----------------------------------------------------------

-- Node name patterns. These reproduce the wording used in the travel
-- data, so an English client sees exactly what it saw before.
L["NODE_PORTAL_TO"]    = "Portal to %s"
L["NODE_TELEPORT_TO"]  = "Teleport to %s"
L["NODE_ZEPPELIN_TO"]  = "Zeppelin to %s"
L["NODE_SHIP_TO"]      = "Ship to %s"
L["NODE_BOAT_TO"]      = "Boat to %s"
L["NODE_FLIGHT_MASTER"] = "%s Flight Master"
L["NODE_MAGE"]         = "%s Mage"
L["NODE_ENTRANCE"]     = "%s Entrance"

-- "Goldshire, Elwynn Forest"
L["NODE_WITH_ZONE"]    = "%s, %s"

-- travel methods (Constants.lua METHOD_DISPLAY_TEXT)
L["METHOD_PORTAL"]      = "Take portal to"
L["METHOD_SHIP"]        = "Take ship to"
L["METHOD_TRAM"]        = "Take tram to"
L["METHOD_FLIGHT"]      = "Take flight path to"
L["METHOD_FLY"]         = "Fly to"
L["METHOD_WALK"]        = "Walk to"
L["METHOD_TELEPORT"]    = "Teleport to"
L["METHOD_HEARTHSTONE"] = "Hearth to"
L["METHOD_RACIAL"]      = "Use"
L["METHOD_PHASESWITCH"] = "Change time phase to"

-- destination picker
L["CAT_ALL"]           = "All"
L["CAT_CITIES"]        = "Cities"
L["CAT_DUNGEONS"]      = "Dungeons"
L["CAT_RAIDS"]         = "Raids"
L["SEARCH_ALL"]        = "Search destinations..."
L["SEARCH_CITIES"]     = "Search cities..."
L["SEARCH_DUNGEONS"]   = "Search dungeons..."
L["SEARCH_RAIDS"]      = "Search raids..."

-- main window
L["UI_ABOUT"]          = "About Mapzeroth"
L["UI_DESTINATION"]    = "Destination:"
L["UI_ACTIVE_WAYPOINT"] = "[WAYPOINT] Active Waypoint"
L["UI_CHOOSE_DEST"]    = "Choose Destination"
L["UI_NAVIGATE"]       = "Navigate"
L["UI_SHOW_ROUTE"]     = "Show Route"
L["UI_CLEAR_ROUTE"]    = "Clear Route"
L["UI_MULTIROUTE"]     = "Multiroute:"
L["UI_PET_KALIMDOR"]   = "KL Pet"
L["UI_PET_EK"]         = "EK Pet"
L["UI_PET_NORTHREND"]  = "NR Pet"
L["UI_SKY_OUTLAND"]    = "OL Sky"
L["UI_BY_AUTHOR"]      = "by %s"
L["UI_LINKS_HEADER"]   = "Community & Support"
L["UI_SHARE"]          = "Share:"
L["UI_SUPPORT"]        = "Support:"
L["UI_CHAT"]           = "Chat:"
L["UI_COMING_SOON"]    = "Coming soon!"

-- GPS / navigation window
L["GPS_TITLE"]         = "Navigation"
L["GPS_NO_ROUTE"]      = "No active route"
L["GPS_NO_ROUTE_HINT"] = "Run navigation to start"
L["GPS_NO_STEP"]       = "No active step"
L["GPS_STEP_COUNT"]    = "Step %d/%d"
L["GPS_NO_POSITION"]   = "Player location unavailable"
L["GPS_OTHER_MAP"]     = "Target on another map"
L["GPS_COMPLETE_STEP"] = "Complete current step"
L["GPS_TOGGLE_LIST"]   = "Toggle Route List"
L["GPS_NEXT_STEP"]     = "Next step"
L["GPS_PREVIOUS_STEP"] = "Previous step"
L["GPS_CLOSE"]         = "Close"
L["GPS_WAYPOINT"]      = "Waypoint"
L["GPS_USE_TO"]        = "Use %s to %s"
L["GPS_USE"]           = "Use %s"
L["GPS_GO_TO"]         = "Go to"
L["GPS_DESTINATION"]   = "destination"
L["GPS_DIST_KM"]       = "%.1f km"
L["GPS_DIST_YD"]       = "%.0f yd"

-- route window
L["ROUTE_TITLE"]       = "Route"
L["ROUTE_COMPLETED"]   = "Route completed"
L["ROUTE_ALL_DONE"]    = "All steps done"
L["ROUTE_HINT"]        = "Click steps with items/spells to use them instantly"
L["ROUTE_TOGGLE_GPS"]  = "Toggle GPS Navigator"
L["ROUTE_TARGET"]      = "Target"
L["ROUTE_WAYPOINT"]    = "Mapzeroth Waypoint"
L["ROUTE_TT_PORTAL"]   = "Use portal to %s"
L["ROUTE_TT_FLIGHT"]   = "Take flight path to %s"
L["ROUTE_TT_WAYPOINT"] = "Click to set waypoint to %s"
L["ROUTE_TT_USE"]      = "Click to use %s"
L["ROUTE_ABILITY"]     = "ability"
L["ROUTE_TOTAL_MS"]    = "Total Time: %dm %.0fs"
L["ROUTE_TOTAL_S"]     = "Total Time: %.0fs"
L["ROUTE_TOTAL_NA"]    = "Total Time: N/A"
L["ROUTE_USE_CURRENT"] = "Use the current ability/item"
L["ROUTE_MANUAL_STEP"] = "Complete this step manually"

-- waypoint importer
L["UI_PASTE_TITLE"]    = "Paste Waypoints"
L["UI_PASTE_HINT"]     = "Paste waypoints below. Supports TomTom /way format.\nBest results with ~20 or fewer destinations."
L["UI_ROUTE_WAYPOINTS"] = "Route Waypoints"
L["UI_CLEAR"]          = "Clear"

-- settings panel
L["OPT_TITLE"]         = "Mapzeroth Settings"
L["OPT_SUBTITLE"]      = "Configure travel routing preferences"
L["OPT_TAX"]           = "Loading Screen Delay"
L["OPT_TAX_TIP"]       = "Add extra time to routes that trigger loading screens (portals, ships, hearthstones, etc). Adjust based on your PC's load times. Higher values favor walking/flying over teleports."
L["OPT_SECONDS"]       = "%d seconds"
L["OPT_COOLDOWN"]      = "Max Usable Cooldown"
L["OPT_COOLDOWN_TIP"]  = "Set the maximum cooldown length to be considered for routing. Any items or abilities with higher cooldown will be ignored"
L["OPT_HOURS"]         = "%d hours"
L["OPT_SCALE"]         = "Window Scale"
L["OPT_SCALE_TIP"]     = "Adjust the size of all Mapzeroth windows. Changes take effect immediately."
L["OPT_MINIMAP"]       = "Show Minimap Button"
L["OPT_MAPCLICK"]      = "Map Click Navigation"
L["OPT_CURRENT"]       = "Current: %s"
L["OPT_CHANGE_MOD"]    = "Change Modifier"
L["OPT_CHANGE_MOUSE"]  = "Change Mouse"

-- slash commands
L["CMD_HEADER"]        = "Commands:"
L["CMD_ROUTE"]         = "  /mz route <destination> - Find route to destination node"
L["CMD_WAYPOINT"]      = "  /mz waypoint (or wp) - Route to active waypoint"
L["CMD_TOGGLE"]        = "  /mz toggle (or show/hide) - Toggle Mapzeroth GUI"
L["CMD_MINIMAP"]       = "  /mz minimap - Toggle minimap button visibility"
L["CMD_NAMES"]         = "  /mz names - Show how many node names came from the client"

-- minimap button
L["MM_TAGLINE"]        = "Google Maps for Azeroth"
L["MM_LEFTCLICK"]      = "|cffaaaaaa< Left-Click >|r Toggle window"
L["MM_RIGHTCLICK"]     = "|cffaaaaaa< Right-Click >|r Settings (coming soon)"
L["MM_DRAG"]           = "|cffaaaaaa< Drag >|r Move button"

-- routing messages
L["ROUTE_NO_DEST"]     = "No destinations in list."
L["ROUTE_NOT_FOUND"]   = "Could not find a valid route. Are you on the right continent?"
L["ROUTE_NO_STEPS"]    = "Route produced no steps."

-- messages to the player
L["MSG_USAGE_ROUTE"]   = "Usage: /mapzeroth route <destination_node_id>"
L["MSG_USAGE_NODES"]   = "Use /mapzeroth nodes to see available destinations"
L["MSG_UNKNOWN_CMD"]   = "Unknown command. Type /mapzeroth help for usage."
L["MSG_NODE_NOT_FOUND"] = "Node not found: %s"
L["MSG_MINIMAP_ON"]    = "Minimap button shown"
L["MSG_MINIMAP_OFF"]   = "Minimap button hidden"
L["MSG_NO_WAYPOINT"]   = "Set a waypoint using Shift+Click on the map, or use TomTom"
L["MSG_NO_MAP"]        = "Could not determine current map"
L["MSG_PICK_DEST"]     = "Please select a destination"
L["MSG_WAYPOINT_FAIL"] = "Failed to set waypoint"
L["MSG_BAD_COORDS"]    = "Error: Invalid coordinates"
L["MSG_NO_WP_DATA"]    = "Error: No waypoint data"
L["MSG_SETTINGS_RESET"] = "Settings reset to defaults"
L["UI_LINKS_TIP"]      = "Click for community links and info"

-- chat
L["LOADED"]            = "Loaded successfully! Type /mapzeroth help for commands."
L["NAMES_HEADER"]      = "Node names resolved from the client:"
L["NAMES_LINE"]        = "  %-12s %4d"
L["NAMES_TOTAL"]       = "%d of %d nodes carry a name from the client (%d%%)."
L["NAMES_UNRESOLVED"]  = "Still on the English name (%d). First %d:"
L["NAMES_RERUN"]       = "Re-resolving node names..."

-----------------------------------------------------------
-- deDE
-----------------------------------------------------------
if GetLocale() == "deDE" then
    L["NODE_PORTAL_TO"]    = "Portal nach %s"
    L["NODE_TELEPORT_TO"]  = "Teleport nach %s"
    L["NODE_ZEPPELIN_TO"]  = "Zeppelin nach %s"
    L["NODE_SHIP_TO"]      = "Schiff nach %s"
    L["NODE_BOAT_TO"]      = "Boot nach %s"
    L["NODE_FLIGHT_MASTER"] = "Flugmeister von %s"
    L["NODE_MAGE"]         = "Magier von %s"
    L["NODE_ENTRANCE"]     = "Eingang zu %s"

    L["NODE_WITH_ZONE"]    = "%s, %s"

    L["METHOD_PORTAL"]      = "Portal nehmen nach"
    L["METHOD_SHIP"]        = "Schiff nehmen nach"
    L["METHOD_TRAM"]        = "Bahn nehmen nach"
    L["METHOD_FLIGHT"]      = "Flugroute nehmen nach"
    L["METHOD_FLY"]         = "Fliegen nach"
    L["METHOD_WALK"]        = "Laufen nach"
    L["METHOD_TELEPORT"]    = "Teleportieren nach"
    L["METHOD_HEARTHSTONE"] = "Heimstein nach"
    L["METHOD_RACIAL"]      = "Benutzen"
    L["METHOD_PHASESWITCH"] = "Zeitphase wechseln nach"

    L["CAT_ALL"]           = "Alle"
    L["CAT_CITIES"]        = "St\195\164dte"
    L["CAT_DUNGEONS"]      = "Dungeons"
    L["CAT_RAIDS"]         = "Schlachtz\195\188ge"
    L["SEARCH_ALL"]        = "Ziele suchen..."
    L["SEARCH_CITIES"]     = "St\195\164dte suchen..."
    L["SEARCH_DUNGEONS"]   = "Dungeons suchen..."
    L["SEARCH_RAIDS"]      = "Schlachtz\195\188ge suchen..."

    L["UI_ABOUT"]          = "\195\156ber Mapzeroth"
    L["UI_DESTINATION"]    = "Ziel:"
    L["UI_ACTIVE_WAYPOINT"] = "[WEGPUNKT] Aktiver Wegpunkt"
    L["UI_CHOOSE_DEST"]    = "Ziel w\195\164hlen"
    L["UI_NAVIGATE"]       = "Navigieren"
    L["UI_SHOW_ROUTE"]     = "Route anzeigen"
    L["UI_CLEAR_ROUTE"]    = "Route l\195\182schen"
    L["UI_MULTIROUTE"]     = "Multiroute:"
    L["UI_PET_KALIMDOR"]   = "KL Tiere"
    L["UI_PET_EK"]         = "\195\150K Tiere"
    L["UI_PET_NORTHREND"]  = "NR Tiere"
    L["UI_SKY_OUTLAND"]    = "SW Himmel"
    L["UI_BY_AUTHOR"]      = "von %s"
    L["UI_LINKS_HEADER"]   = "Community & Unterst\195\188tzung"
    L["UI_SHARE"]          = "Teilen:"
    L["UI_SUPPORT"]        = "Unterst\195\188tzen:"
    L["UI_CHAT"]           = "Chat:"
    L["UI_COMING_SOON"]    = "Bald verf\195\188gbar!"

    L["GPS_TITLE"]         = "Navigation"
    L["GPS_NO_ROUTE"]      = "Keine aktive Route"
    L["GPS_NO_ROUTE_HINT"] = "Navigation starten"
    L["GPS_NO_STEP"]       = "Kein aktiver Schritt"
    L["GPS_STEP_COUNT"]    = "Schritt %d/%d"
    L["GPS_NO_POSITION"]   = "Spielerposition nicht verf\195\188gbar"
    L["GPS_OTHER_MAP"]     = "Ziel auf einer anderen Karte"
    L["GPS_COMPLETE_STEP"] = "Aktuellen Schritt abschlie\195\159en"
    L["GPS_TOGGLE_LIST"]   = "Routenliste umschalten"
    L["GPS_NEXT_STEP"]     = "N\195\164chster Schritt"
    L["GPS_PREVIOUS_STEP"] = "Vorheriger Schritt"
    L["GPS_CLOSE"]         = "Schlie\195\159en"
    L["GPS_WAYPOINT"]      = "Wegpunkt"
    L["GPS_USE_TO"]        = "%s benutzen nach %s"
    L["GPS_USE"]           = "%s benutzen"
    L["GPS_GO_TO"]         = "Gehen nach"
    L["GPS_DESTINATION"]   = "Ziel"
    L["GPS_DIST_KM"]       = "%.1f km"
    L["GPS_DIST_YD"]       = "%.0f m"

    L["ROUTE_TITLE"]       = "Route"
    L["ROUTE_COMPLETED"]   = "Route abgeschlossen"
    L["ROUTE_ALL_DONE"]    = "Alle Schritte erledigt"
    L["ROUTE_HINT"]        = "Schritte mit Gegenst\195\164nden/Zaubern anklicken, um sie sofort zu nutzen"
    L["ROUTE_TOGGLE_GPS"]  = "GPS-Navigator umschalten"
    L["ROUTE_TARGET"]      = "Ziel"
    L["ROUTE_WAYPOINT"]    = "Mapzeroth-Wegpunkt"
    L["ROUTE_TT_PORTAL"]   = "Portal nutzen nach %s"
    L["ROUTE_TT_FLIGHT"]   = "Flugroute nehmen nach %s"
    L["ROUTE_TT_WAYPOINT"] = "Klicken, um Wegpunkt nach %s zu setzen"
    L["ROUTE_TT_USE"]      = "Klicken, um %s zu benutzen"
    L["ROUTE_ABILITY"]     = "F\195\164higkeit"
    L["ROUTE_TOTAL_MS"]    = "Gesamtzeit: %dm %.0fs"
    L["ROUTE_TOTAL_S"]     = "Gesamtzeit: %.0fs"
    L["ROUTE_TOTAL_NA"]    = "Gesamtzeit: n. v."
    L["ROUTE_USE_CURRENT"] = "Aktuelle F\195\164higkeit/Gegenstand benutzen"
    L["ROUTE_MANUAL_STEP"] = "Diesen Schritt manuell abschlie\195\159en"

    L["UI_PASTE_TITLE"]    = "Wegpunkte einf\195\188gen"
    L["UI_PASTE_HINT"]     = "Wegpunkte unten einf\195\188gen. Unterst\195\188tzt das TomTom-Format /way.\nBeste Ergebnisse mit etwa 20 Zielen oder weniger."
    L["UI_ROUTE_WAYPOINTS"] = "Route berechnen"
    L["UI_CLEAR"]          = "Leeren"

    L["OPT_TITLE"]         = "Mapzeroth-Einstellungen"
    L["OPT_SUBTITLE"]      = "Einstellungen f\195\188r die Routenberechnung"
    L["OPT_TAX"]           = "Ladebildschirm-Zuschlag"
    L["OPT_TAX_TIP"]       = "Rechnet Routen mit Ladebildschirm (Portale, Schiffe, Heimsteine usw.) zus\195\164tzliche Zeit an. Richte den Wert an den Ladezeiten deines PCs aus. H\195\182here Werte bevorzugen Laufen und Fliegen gegen\195\188ber Teleports."
    L["OPT_SECONDS"]       = "%d Sekunden"
    L["OPT_COOLDOWN"]      = "Maximal nutzbare Abklingzeit"
    L["OPT_COOLDOWN_TIP"]  = "Legt fest, bis zu welcher Abklingzeit Gegenst\195\164nde und F\195\164higkeiten f\195\188r Routen ber\195\188cksichtigt werden. Alles dar\195\188ber wird ignoriert."
    L["OPT_HOURS"]         = "%d Stunden"
    L["OPT_SCALE"]         = "Fenstergr\195\182\195\159e"
    L["OPT_SCALE_TIP"]     = "\195\132ndert die Gr\195\182\195\159e aller Mapzeroth-Fenster. Wirkt sofort."
    L["OPT_MINIMAP"]       = "Minimap-Button anzeigen"
    L["OPT_MAPCLICK"]      = "Navigation per Kartenklick"
    L["OPT_CURRENT"]       = "Aktuell: %s"
    L["OPT_CHANGE_MOD"]    = "Zusatztaste \195\164ndern"
    L["OPT_CHANGE_MOUSE"]  = "Maustaste \195\164ndern"

    L["CMD_HEADER"]        = "Befehle:"
    L["CMD_ROUTE"]         = "  /mz route <Ziel> - Route zu einem Zielknoten suchen"
    L["CMD_WAYPOINT"]      = "  /mz waypoint (oder wp) - Route zum aktiven Wegpunkt"
    L["CMD_TOGGLE"]        = "  /mz toggle (oder show/hide) - Mapzeroth-Fenster umschalten"
    L["CMD_MINIMAP"]       = "  /mz minimap - Minimap-Button ein-/ausblenden"
    L["CMD_NAMES"]         = "  /mz names - Zeigt, wie viele Knotennamen aus dem Client stammen"

    L["MM_TAGLINE"]        = "Google Maps f\195\188r Azeroth"
    L["MM_LEFTCLICK"]      = "|cffaaaaaa< Linksklick >|r Fenster umschalten"
    L["MM_RIGHTCLICK"]     = "|cffaaaaaa< Rechtsklick >|r Einstellungen (bald verf\195\188gbar)"
    L["MM_DRAG"]           = "|cffaaaaaa< Ziehen >|r Button verschieben"

    L["ROUTE_NO_DEST"]     = "Keine Ziele in der Liste."
    L["ROUTE_NOT_FOUND"]   = "Keine g\195\188ltige Route gefunden. Bist du auf dem richtigen Kontinent?"
    L["ROUTE_NO_STEPS"]    = "Die Route ergab keine Schritte."

    L["MSG_USAGE_ROUTE"]   = "Verwendung: /mapzeroth route <Ziel-Knoten-ID>"
    L["MSG_USAGE_NODES"]   = "Mit /mapzeroth nodes siehst du die verf\195\188gbaren Ziele"
    L["MSG_UNKNOWN_CMD"]   = "Unbekannter Befehl. Tippe /mapzeroth help f\195\188r die \195\156bersicht."
    L["MSG_NODE_NOT_FOUND"] = "Knoten nicht gefunden: %s"
    L["MSG_MINIMAP_ON"]    = "Minimap-Button eingeblendet"
    L["MSG_MINIMAP_OFF"]   = "Minimap-Button ausgeblendet"
    L["MSG_NO_WAYPOINT"]   = "Setze einen Wegpunkt mit Shift+Klick auf der Karte, oder nutze TomTom"
    L["MSG_NO_MAP"]        = "Aktuelle Karte konnte nicht ermittelt werden"
    L["MSG_PICK_DEST"]     = "Bitte w\195\164hle ein Ziel"
    L["MSG_WAYPOINT_FAIL"] = "Wegpunkt konnte nicht gesetzt werden"
    L["MSG_BAD_COORDS"]    = "Fehler: Ung\195\188ltige Koordinaten"
    L["MSG_NO_WP_DATA"]    = "Fehler: Keine Wegpunktdaten"
    L["MSG_SETTINGS_RESET"] = "Einstellungen auf Standard zur\195\188ckgesetzt"
    L["UI_LINKS_TIP"]      = "Klicken f\195\188r Community-Links und Infos"


    L["LOADED"]            = "Erfolgreich geladen! Tippe /mapzeroth help f\195\188r Befehle."
    L["NAMES_HEADER"]      = "Aus dem Client aufgel\195\182ste Knotennamen:"
    L["NAMES_LINE"]        = "  %-12s %4d"
    L["NAMES_TOTAL"]       = "%d von %d Knoten tragen einen Namen aus dem Client (%d%%)."
    L["NAMES_UNRESOLVED"]  = "Noch auf dem englischen Namen (%d). Erste %d:"
    L["NAMES_RERUN"]       = "L\195\182se Knotennamen neu auf..."
end

-----------------------------------------------------------
-- Hand written node name overrides
--
--  Keyed by nodeID, which is a stable internal identifier, NOT by the
--  English name - names change, IDs do not. Only needed for the few
--  nodes the client cannot name on its own (see /mapzeroth names for
--  the current list). Empty is a perfectly good state.
-----------------------------------------------------------
addon.NodeNameOverrides = {}

if GetLocale() == "deDE" then
    addon.NodeNameOverrides = {
        -- ["SOME_NODE_ID"] = "Deutscher Name",
    }
end

-----------------------------------------------------------
-- Never return nil for a missing key
-----------------------------------------------------------
setmetatable(L, { __index = function(_, key) return key end })
