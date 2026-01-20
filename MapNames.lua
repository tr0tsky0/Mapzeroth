-- MapNames.lua
-- Automatically enriches node names with zone information
-- e.g. "Goldshire" becomes "Goldshire, Elwynn Forest"
local addonName, addon = ...

local MapNames = {}

-----------------------------------------------------------
-- GET ZONE NAME FROM MAP ID
-----------------------------------------------------------

-- Returns the most appropriate zone name for a given mapID
-- Handles micro-maps, dungeons, and parent zone lookups
local function GetZoneNameForMap(mapID)
    if not mapID then return nil end
    
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then return nil end
    
    if mapInfo.mapType == Enum.UIMapType.Micro or 
       mapInfo.mapType == Enum.UIMapType.Dungeon then
        local parentInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
        if parentInfo then
            return parentInfo.name
        end
    end
    
    return mapInfo.name
end

-----------------------------------------------------------
-- FORMAT DISPLAY NAME
-----------------------------------------------------------

-- Combines node name and zone name intelligently
-- Avoids redundancy like "Stormwind, Stormwind City"
local function FormatDisplayName(nodeName, zoneName)
    if not nodeName then return zoneName end
    if not zoneName then return nodeName end
    
    -- Check if the node name already contains the zone name
    -- This handles cases like "Mage Tower, Stormwind" or "Lunarfall, Shadowmoon Valley"
    if nodeName:find(zoneName, 1, true) then
        return nodeName
    end
    
    -- Check if zone name is already in the node name (case-insensitive)
    local lowerNodeName = nodeName:lower()
    local lowerZoneName = zoneName:lower()
    if lowerNodeName:find(lowerZoneName, 1, true) then
        return nodeName
    end
    
    -- Avoid "Stormwind Harbour, Stormwind City" → just "Stormwind Harbour"
    -- Extract the first word from node name and check against zone name
    local firstWord = nodeName:match("^([%w']+)")
    if firstWord and lowerZoneName:find(firstWord:lower(), 1, true) then
        return nodeName
    end
    
    -- Default: append zone name
    return string.format("%s, %s", nodeName, zoneName)
end

-----------------------------------------------------------
-- ENRICH ALL NODES
-----------------------------------------------------------

function MapNames:EnrichNodes(nodesTable)
    local enrichedCount = 0
    local skippedCount = 0
    
    for traversalGroup, groupData in pairs(nodesTable) do
        for nodeID, nodeData in pairs(groupData) do
            -- Skip if already has a displayName
            if nodeData.displayName then
                skippedCount = skippedCount + 1
            else
                local zoneName = GetZoneNameForMap(nodeData.mapID)
                
                if zoneName then
                    nodeData.displayName = FormatDisplayName(nodeData.name, zoneName)
                    enrichedCount = enrichedCount + 1
                else
                    -- Fallback: use the node name as-is
                    nodeData.displayName = nodeData.name
                    if addon.DEBUG then
                        print(string.format("[Mapzeroth] WARNING: No zone found for mapID %d (%s)", 
                            nodeData.mapID or 0, nodeData.name or "unknown"))
                    end
                end
            end
        end
    end
    
    if addon.DEBUG then
        print(string.format("[Mapzeroth] MapNames: Enriched %d nodes, skipped %d (already had displayName)", 
            enrichedCount, skippedCount))
    end
end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

addon.MapNames = MapNames