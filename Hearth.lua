local addonName, addon = ...

-- Where the hearthstone goes. You can only bind at an inn, so the destination is the
-- inn node nearest the position saved when the player bound (the HEARTHSTONE_BOUND
-- event, see Core.lua). A character bound before this addon was installed has no saved
-- position; for those the bind location's text ("Goldshire") is matched against the
-- names of our towns and cities instead.

-- How close (in map units, 0-1) the saved bind has to be to an inn node to count as it.
local SNAP_RADIUS = 0.06

-- Who is playing, for the things saved per character (the bind here, found flights in FlightKnowledge.lua).
function addon:CharacterKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "")
end

-- The bind is per character (MapzerothRebuildDB.hearthstones). Before that it was one account-wide
-- `hearthstone`, whatever character bound last: it is still the best guess for a character that hasn't
-- bound since (not copied: it may be another character's), and the next bind of any character removes it.
function addon:GetBind()
    local db = MapzerothRebuildDB
    if not db then return nil end
    local own = db.hearthstones and db.hearthstones[addon:CharacterKey()]
    return own or db.hearthstone
end

function addon:SaveBind(mapID, x, y, name)
    MapzerothRebuildDB = MapzerothRebuildDB or {}
    MapzerothRebuildDB.hearthstones = MapzerothRebuildDB.hearthstones or {}
    MapzerothRebuildDB.hearthstones[addon:CharacterKey()] = { mapID = mapID, x = x, y = y, name = name }
    MapzerothRebuildDB.hearthstone = nil
end

-- The first inn node belonging to a city or town.
local function innOf(settlementKey, isCity)
    local found
    addon.World:ForEachNode(function(node)
        local owner = isCity and node.city or node.town
        if node.kind == "inn" and owner == settlementKey then
            found = found or node.id
        end
    end)
    return found
end

-- bind is { mapID, x, y, name }; the position and the name are each optional.
function addon:FindHearthNode(bind)
    if not bind then return nil end

    if bind.mapID and bind.x and bind.y then
        local best, bestDistance
        addon.World:ForEachNode(function(node)
            if node.kind == "inn" and node.mapID == bind.mapID then
                local d = math.sqrt((node.x - bind.x) ^ 2 + (node.y - bind.y) ^ 2)
                if d <= SNAP_RADIUS and (not bestDistance or d < bestDistance) then
                    best, bestDistance = node.id, d
                end
            end
        end)
        if best then return best end
    end

    if bind.name and bind.name ~= "" then
        -- The client's text for a bind needn't be the name we give the place ("Stormwind City" for "Stormwind"): an exact
        -- match wins, else the longest name that starts the other, as a whole word, in either direction.
        local wanted = bind.name:lower()
        local best, bestScore
        local function consider(name, key, isCity)
            if not name then return end
            local lower = name:lower()
            local score = lower == wanted and math.huge
                or ((wanted:sub(1, #lower + 1) == lower .. " " or lower:sub(1, #wanted + 1) == wanted .. " ") and #lower)
            if score and (not bestScore or score > bestScore) and innOf(key, isCity) then
                best, bestScore = innOf(key, isCity), score
            end
        end
        for key in pairs(addon.Cities or {}) do consider(addon:GetCityName(key), key, true) end
        for key in pairs(addon.Towns or {}) do consider(addon:GetTownName(key), key, false) end
        return best
    end
end

-- The inn node the player's hearthstone goes to, or nil if it can't be worked out.
function addon:GetBoundInnNode()
    local bind = addon:GetBind()
    if not bind and GetBindLocation then
        bind = { name = GetBindLocation() }
    end
    return addon:FindHearthNode(bind)
end

-- When no inn of ours stands where the player bound (one the data lacks), the hearthstone still lands there: the
-- bound spot itself, as a place of its own, { id, mapID, x, y, name }. Nil when there's an inn, or no position.
addon.HEARTH_PLACE_ID = "HEARTH_BIND"
function addon:GetHearthPlace(innNode)
    if innNode then return nil end
    local bind = addon:GetBind()
    if not (bind and bind.mapID and bind.x and bind.y) then return nil end
    return { id = addon.HEARTH_PLACE_ID, mapID = bind.mapID, x = bind.x, y = bind.y, name = bind.name, nocache = true }
end
