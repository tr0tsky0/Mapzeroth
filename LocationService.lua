-- LocationService.lua
-- Handles player position detection and node matching
local addonName, addon = ...

-- Import traversal data from Mapzeroth_Data
local GetTraversalGroupForMap = addon.GetTraversalGroupForMap

-----------------------------------------------------------
-- GET PLAYER'S CURRENT MAP AND COORDINATES
-----------------------------------------------------------

function addon:GetPlayerLocation()
    local mapID = C_Map.GetBestMapForUnit("player")

    if not mapID then
        return nil, "Could not determine current map"
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")

    if not position then
        return nil, "Could not determine position on map"
    end

    local x, y = position:GetXY()

    return {
        mapID = mapID,
        x = x,
        y = y
    }
end

-----------------------------------------------------------
-- AUTOMATIC HEARTHSTONE LOCATION UPDATE
-----------------------------------------------------------

function addon:UpdateHearthstoneLocation()
    -- Get the hearthstone bind location name
    local bindLoc = GetBindLocation()

    if not bindLoc or bindLoc == "" then
        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: No hearthstone bind location found")
        end
        return
    end

    -- Get current player location
    local location, err = self:GetPlayerLocation()

    if not location then
        if addon.DEBUG then
            print("[Mapzeroth] DEBUG: Could not get player location for hearthstone: " .. (err or "unknown error"))
        end
        return
    end

    -- Store the hearthstone location with coordinates
    MapzerothDB = MapzerothDB or {}
    MapzerothDB.hearthstone = {
        mapID = location.mapID,
        x = location.x,
        y = location.y,
        locationName = bindLoc,
        setAt = time()
    }

    if addon.DEBUG then
        local mapName = self:GetMapName(location.mapID)
        print(string.format("[Mapzeroth] Hearthstone location automatically updated: %s", bindLoc))
        print(string.format("[Mapzeroth] DEBUG: Hearthstone coords: %s (%.3f, %.3f)", mapName, location.x, location.y))
    end
end

-----------------------------------------------------------
-- GET PLAYER FACTION
-----------------------------------------------------------

function addon:GetPlayerFaction()
    local faction = UnitFactionGroup("player")
    -- Returns "Alliance", "Horde", or "Neutral"
    -- Normalize to uppercase to match node data
    if faction == "Alliance" then
        return "ALLIANCE"
    elseif faction == "Horde" then
        return "HORDE"
    else
        return "NEUTRAL"
    end
end

-----------------------------------------------------------
-- FIND NEAREST NODE TO PLAYER
-----------------------------------------------------------

function addon:FindNearestNode()
    local location, err = self:GetPlayerLocation()

    if not location then
        return nil, err
    end

    if addon.DEBUG then
        print(string.format("[Mapzeroth] DEBUG: Player at map %d, coords %.3f, %.3f", location.mapID, location.x,
            location.y))
        print(string.format("[Mapzeroth] DEBUG: Total nodes in graph: %d", self.TravelGraph.nodeCount))
    end

    local x = location.x
    local y = location.y
    local mapID = location.mapID

    -- Step 1: Try exact mapID match (fast path)
    -- Iterate through hierarchy to find all nodes on this mapID
    local exactMapNodes = {}
    for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
        for nodeID, node in pairs(groupData) do
            if node.mapID == mapID then
                table.insert(exactMapNodes, node)
            end
        end
    end

    if #exactMapNodes > 0 then
        return self:FindClosestNodeInList(exactMapNodes, x, y)
    end

    -- Step 2: Fall back to traversal group
    local playerTraversalGroup = addon.GetTraversalGroupForMap(mapID)

    if addon.DEBUG then
        print(string.format("[Mapzeroth] DEBUG: Traversal group for map %d: %s", mapID, playerTraversalGroup or "nil"))
    end

    if not playerTraversalGroup then
        return nil, string.format("No travel nodes found in this area (map %d)", mapID)
    end

    -- Find nodes in same traversal group (iterate hierarchy)
    local traversalNodes = {}
    for traversalGroup, groupData in pairs(self.TravelGraph.nodes) do
        if traversalGroup == playerTraversalGroup then
            for nodeID, node in pairs(groupData) do
                table.insert(traversalNodes, node)
            end
        end
    end

    if addon.DEBUG then
        print(string.format("[Mapzeroth] DEBUG: Found %d nodes in traversal group", #traversalNodes))
    end

    if #traversalNodes == 0 then
        return nil, string.format("No travel nodes found in %s", playerTraversalGroup)
    end

    return self:FindClosestNodeInList(traversalNodes, x, y)
end

function addon:FindClosestNodeInList(nodes, x, y)
    local closestNode = nil
    local minDistance = math.huge

    for _, node in ipairs(nodes) do
        if node.x and node.y then
            local dx = node.x - x
            local dy = node.y - y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance < minDistance then
                minDistance = distance
                closestNode = node
            end
        end
    end

    if not closestNode then
        if addon.DEBUG then
            print(string.format("[Mapzeroth] WARNING: No nodes with valid coordinates in list of %d nodes", #nodes))
        end
        return nil, "No nodes with coordinates found"
    end

    return closestNode, minDistance
end

-----------------------------------------------------------
-- CALCULATE TIME TO REACH NEAREST NODE
-----------------------------------------------------------

function addon:CalculateTravelToNode(distance, mapID)
    local yards = distance * addon.MAP_SCALE
    local canFly = not addon.NO_FLY_MAPS[mapID]
    local speed = canFly and addon.FLY_SPEED or addon.WALK_SPEED

    local time = yards / speed

    time = math.ceil(time / 2) * 2

    -- Clamp between 5 and 300 seconds
    time = math.max(2, math.min(300, time))

    return time, canFly and "fly" or "walk"
end

-----------------------------------------------------------
-- PLAYER ABILITY DETECTION
-----------------------------------------------------------

function addon:GetAvailableTravelAbilities()
    local available = {}
    local playerClass = select(2, UnitClass("player"))
    local playerFaction = UnitFactionGroup("player")

    -- Check toys/items
    for id, item in pairs(self.TravelItems) do
        local hasItem = false
        local onCooldown = false
        local isHearthstone = false
        local hearthDest = nil

        if item.type == "toy" then
            hasItem = PlayerHasToy(item.itemID) and C_ToyBox.IsToyUsable(item.itemID)
            if hasItem then
                local startTime, duration, enable = C_Item.GetItemCooldown(item.itemID)
                if startTime and duration and startTime > 0 and duration > 0 then
                    onCooldown = true
                end
            end
        elseif item.type == "inventory_item" then
            hasItem = (GetItemCount(item.itemID) > 0) and C_Item.IsUsableItem(item.itemID)
            if hasItem then
                local startTime, duration, enable = C_Item.GetItemCooldown(item.itemID)
                if startTime and duration and startTime > 0 and duration > 0 then
                    onCooldown = true
                end
            end
        end

        -- Add to available list (handles both single and multi-destination)
        if hasItem and not onCooldown and (item.destination or item.destinations or isHearthstone) then
            local abilityData = {
                id = id,
                name = item.name,
                castTime = item.castTime,
                cooldown = item.cooldown,
                destination = item.destination,
                destinations = item.destinations,
                type = item.type,
                itemID = item.itemID
            }

            table.insert(available, abilityData)
        end
    end

    -- Check class abilities
    for id, spell in pairs(self.ClassTeleports) do
        if spell.class == playerClass then
            local hasSpell = IsPlayerSpell(spell.spellID)

            if spell.faction and spell.faction ~= playerFaction then
                hasSpell = false
            end

            if hasSpell then
                local cooldownInfo = C_Spell.GetSpellCooldown(spell.spellID)
                local onCooldown = false

                if cooldownInfo and cooldownInfo.startTime > 0 and cooldownInfo.duration > 1.5 then
                    onCooldown = true
                end
                if not onCooldown then
                    table.insert(available, {
                        id = id,
                        name = spell.name,
                        destination = spell.destination,
                        destinations = spell.destinations,
                        castTime = spell.castTime,
                        cooldown = spell.cooldown,
                        type = "spell",
                        isHearthstone = (spell.type == "hearthstone"),
                        spellID = spell.spellID
                    })
                end
            end
        end
    end

    -- Check racial abilities
    for id, racial in pairs(self.RacialAbilities) do
        local playerRace = select(2, UnitRace("player"))

        if racial.race == playerRace then
            local hasRacial = IsPlayerSpell(racial.spellID)

            if hasRacial then
                local cooldownInfo = C_Spell.GetSpellCooldown(racial.spellID)
                local onCooldown = false

                if cooldownInfo and cooldownInfo.startTime > 0 and cooldownInfo.duration > 1.5 then
                    onCooldown = true
                end

                if not onCooldown then
                    local abilityData = {
                        id = id,
                        name = racial.name,
                        castTime = racial.castTime,
                        cooldown = racial.cooldown,
                        destination = racial.destination,
                        destinations = racial.destinations,
                        type = "racial",
                        spellID = racial.spellID
                    }

                    table.insert(available, abilityData)
                end
            end
        end
    end

    -- Check dungeon teleports
    for id, spell in pairs(self.DungeonTeleports) do
        local hasSpell = IsPlayerSpell(spell.spellID)

        if hasSpell then
            local cooldownInfo = C_Spell.GetSpellCooldown(spell.spellID)
            local onCooldown = false

            if cooldownInfo and cooldownInfo.startTime > 0 and cooldownInfo.duration > 1.5 then
                onCooldown = true
            end

            if not onCooldown then
                table.insert(available, {
                    id = id,
                    name = spell.name,
                    destination = spell.destination,
                    castTime = spell.castTime,
                    cooldown = spell.cooldown,
                    type = "spell",
                    spellID = spell.spellID
                })
            end
        end
    end

    -- Check for hearthstone (any variant)
    local hearthstoneSpellID = 8690
    local cooldownInfo = C_Spell.GetSpellCooldown(hearthstoneSpellID)

    if cooldownInfo then
        local onCooldown = false

        if cooldownInfo.startTime > 0 and cooldownInfo.duration > 1.5 then
            onCooldown = true
        end

        if not onCooldown then
            local hearthDest = addon:GetHearthstoneDestination()

            if hearthDest then
                table.insert(available, {
                    id = "HEARTHSTONE",
                    name = "Hearthstone",
                    castTime = 10,
                    cooldown = 1200,
                    type = "item",
                    itemID = 6948, -- Just for display icon purposes
                    isHearthstone = true,
                    hearthstone = hearthDest
                })
            end
        end
    end

    return available
end

-----------------------------------------------------------
-- MANUAL HEARTHSTONE LOCATION SETTING
-----------------------------------------------------------

function addon:SetHearthstoneLocation()
    local location, err = self:GetPlayerLocation()

    if not location then
        print("[Mapzeroth] Error: " .. err)
        return
    end

    -- Store the raw coordinates
    MapzerothDB = MapzerothDB or {}
    MapzerothDB.hearthstone = {
        mapID = location.mapID,
        x = location.x,
        y = location.y,
        setAt = time()
    }

    local mapName = self:GetMapName(location.mapID)
    print(string.format("[Mapzeroth] Hearthstone location set to: %s (%.3f, %.3f)", mapName, location.x, location.y))
end

function addon:GetHearthstoneDestination()
    -- Return the stored coordinates, or nil if not set
    if MapzerothDB and MapzerothDB.hearthstone then
        return MapzerothDB.hearthstone
    end

    return nil
end

-----------------------------------------------------------
-- UTILITY: Get Map Name
-----------------------------------------------------------

function addon:GetMapName(mapID)
    if not mapID then
        return "Unknown"
    end
    local mapInfo = C_Map.GetMapInfo(mapID)
    return mapInfo and mapInfo.name or "Unknown"
end
