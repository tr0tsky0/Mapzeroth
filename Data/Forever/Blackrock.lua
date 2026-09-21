-- Blackrock.lua (Forever)
--
-- Blackrock Mountain sits between Burning Steppes and Searing Gorge, and its four
-- instances (Blackrock Depths and Spire, Molten Core, Blackwing Lair) are an interior area
-- of their own, container "easternkingdoms.blackrock_mountain": you reach them through
-- the mountain from either side, or you cross it to get to the other zone. The two
-- doors are the border crossing nodes on each side (see Borders.lua). Nothing here has a
-- fixed cost: each walk is worked out from the distance between its two ends.
--
-- Captured in person (Burning Steppes map, area 254 Blackrock Mountain): the way in from the
-- south is at 29.4, 38.5 (Burning Steppes) and the way out to Searing Gorge is at 28.5, 19.1 on
-- the same map, arriving at 34.9, 87.0 on Searing Gorge's. The crossing between the two doors is
-- costed by the straight line between them, which the passage follows closely, so the interior
-- points aren't nodes; they're here in case that assumption needs checking.
--
-- The instance positions are Wowhead's markers, in the middle of the mountain, so these
-- walks are approximations until someone captures the real entrances.

local addonName, addon = ...

addon.Edges = addon.Edges or {}

local doors = {
    "BORDER_BURNING_STEPPES_TO_SEARING_GORGE",
    "BORDER_SEARING_GORGE_TO_BURNING_STEPPES",
}
local instances = {
    "INSTANCE_BLACKROCK_DEPTHS", "INSTANCE_BLACKROCK_SPIRE",
    "INSTANCE_MOLTEN_CORE", "INSTANCE_BLACKWING_LAIR",
}

for _, door in ipairs(doors) do
    for _, instance in ipairs(instances) do
        table.insert(addon.Edges, { from = door, to = instance, method = "walk" })
    end
end
