-- NodeNames_enUS.lua (Modern)
--
-- English names for the nodes WE created that nothing else names well (the client's area or map name would
-- say the wrong thing). Keyed "NODE_<nodeID>", as Forever's (Data/Forever/NodeNames_enUS.lua).

local addonName, addon = ...
if addon.RULESET ~= "modern" then return end   -- one addon for both games: this data is Modern's (Constants.lua)

addon:RegisterLocale("enUS", {
    NODE_UNDERCITY_SEWER_INNER = "Undercity Sewer",
    NODE_UNDERCITY_SEWER_OUTER = "Undercity Sewer Entrance",
})
