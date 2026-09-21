-- Nodes_ZephrasIsle.lua (Forever)
--
-- Zephras Isle: the Skyborne starting island (new in Forever). Not in the
-- Atlas map or any historical addon data, so everything here is captured
-- live with `/mzdump here <name>` (exact positions, not calibrated
-- estimates).
--
-- `/mzdump root` shows Zephras Isle (mapID 2521) is a Zone (mapType 3)
-- whose parent is Azeroth (947, the World map) directly -- no continent in
-- between. Modeled as a synthetic single-zone continent wrapper
-- ("zephras_isle.zephras_isle") so it fits the World -> Continent -> Zone
-- tree; see the design doc's note on World-parented zones.

local addonName, addon = ...

addon.Nodes = addon.Nodes or {}

addon.Nodes.ZephrasIsle = {
    { id = "DOCK_VALANAAR", container = "zephras_isle.zephras_isle", mapID = 2521, x = 0.5791, y = 0.8078, area = 16628 }, -- Valanaar Harbor (Horde ship to Skywatcher Plateau, Mulgore)
    { id = "DOCK_ZEPHRAS_ALLIANCE", container = "zephras_isle.zephras_isle", mapID = 2521, x = 0.6581, y = 0.8341 }, -- Alliance ship to Dalaran (in-game dock name unknown -- rename once seen)
}
