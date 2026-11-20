local addonName, addon = ...

-- Where the hearthstone goes. You can only bind at an inn, so the destination is the
-- inn node nearest the position saved when the player bound (the HEARTHSTONE_BOUND
-- event, see Core.lua). A character bound before this addon was installed has no saved
-- position; for those the bind location's text ("Goldshire") is matched against the
-- names of our towns and cities instead.

-- How close (in map units, 0-1) the saved bind has to be to an inn node to count as it.
local SNAP_RADIUS = 0.06

-- Who is playing, for the things saved per character (the bind here, found flights in FlightKnowledge.lua).
-- On Forever, UnitName gives the first name and the surname apart. A full name is unique in the region, and the
-- client no longer tells addons the realm (GetRealmName gives ""), so the key is the full name alone
-- ("Soni Locksdottir"). Retail gives no second part for the player: its keys are "Name-Realm".
function addon:CharacterKey()
    local name, surname = UnitName("player")
    if surname and surname ~= "" then return (name or "?") .. " " .. surname end
    return (name or "?") .. "-" .. (GetRealmName and GetRealmName() or "")
end

local function startsWith(s, prefix)
    return type(s) == "string" and s:sub(1, #prefix) == prefix
end

-- Forever keys up to 1.4.1 held the realm ("Soni Locksdottir-Realm", or "Soni Locksdottir-" once the realm read
-- blank). They are this character's, so the newest of them moves to the key without the realm and the others go.
function addon:ClaimRealmKey(all)
    local name, surname = UnitName("player")
    if not (all and surname and surname ~= "") then return end
    local key = addon:CharacterKey()
    local prefix = key .. "-"
    local olds = {}
    for k in pairs(all) do
        if startsWith(k, prefix) then olds[#olds + 1] = k end
    end
    if #olds == 0 then return end
    if all[key] == nil then
        local pick = olds[1]
        for _, k in ipairs(olds) do
            if k == prefix then pick = k end     -- saved since the realm went blank: newer than any with a realm
        end
        all[key] = all[pick]
    end
    for _, k in ipairs(olds) do all[k] = nil end
end

-- The key before surnames were in it (Forever up to 1.4.0): first name and realm ("Soni-Realm"), so shared by every
-- character with that first name on the realm. The realm can't be read any more, so this is the first such key in
-- `all` that `accept(value)` takes (any, without it). Nil on Retail, or when there is none.
function addon:OldCharacterKey(all, accept)
    local name, surname = UnitName("player")
    if not (all and surname and surname ~= "") then return nil end
    local prefix = (name or "?") .. "-"
    for k, v in pairs(all) do
        if startsWith(k, prefix) and (not accept or accept(v)) then return k end
    end
    return nil
end

-- Whether a saved bind is the one the game has now: the client's bind name, when it gives one, must match. It doesn't
-- when the bind was saved for another character (the old shared key) or the player bound somewhere without us seeing.
local function current(bind)
    if not bind then return false end
    local now = GetBindLocation and GetBindLocation()
    return not (now and now ~= "" and bind.name and bind.name ~= "" and bind.name ~= now)
end

-- The bind is per character (MapzerothRebuildDB.hearthstones). Before that it was one account-wide
-- `hearthstone`, whatever character bound last. A bind saved under the old shared key, or the account-wide
-- one, is only taken when its name is this character's bind, and the next bind of any character removes the
-- account-wide one.
function addon:GetBind()
    local db = MapzerothRebuildDB
    if not db then return nil end
    local binds = db.hearthstones
    if binds then
        addon:ClaimRealmKey(binds)
        local own = binds[addon:CharacterKey()]
        if own then return current(own) and own or nil end
        local oldKey = addon:OldCharacterKey(binds, function(b) return current(b) and b.name end)
        local old = oldKey and binds[oldKey]
        if old then
            binds[addon:CharacterKey()] = old
            return old
        end
    end
    return db.hearthstone and db.hearthstone.name and current(db.hearthstone) and db.hearthstone or nil
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

-- Vulpera's camp (Modern): Make Camp sets it wherever the player stands, Return to Camp goes back to it. Like the bound
-- spot above it is a place of its own, not one of our nodes: the position saved when Make Camp was cast (Core.lua,
-- the Camps abilities' `setSpellID`), per character. A character who made camp before this addon was installed has
-- none until they make camp again: the client can't be asked where the camp is.
addon.CAMP_PLACE_ID = "CAMP"

function addon:GetCamp()
    local db = MapzerothRebuildDB
    return db and db.camps and db.camps[addon:CharacterKey()]
end

function addon:SaveCamp(mapID, x, y)
    MapzerothRebuildDB = MapzerothRebuildDB or {}
    MapzerothRebuildDB.camps = MapzerothRebuildDB.camps or {}
    MapzerothRebuildDB.camps[addon:CharacterKey()] = { mapID = mapID, x = x, y = y }
end

-- Is spellID one that makes camp (a Camps ability's setSpellID)?
function addon:IsMakeCamp(spellID)
    for _, ability in ipairs(addon.Abilities and addon.Abilities.Camps or {}) do
        if ability.setSpellID == spellID then return true end
    end
    return false
end

function addon:GetCampPlace()
    local camp = addon:GetCamp()
    if not (camp and camp.mapID and camp.x and camp.y) then return nil end
    return { id = addon.CAMP_PLACE_ID, mapID = camp.mapID, x = camp.x, y = camp.y, nocache = true }
end

-- The places of the player's own an ability lands at that aren't our nodes (the bound spot, the camp), from a context.
function addon:OwnPlaces(ctx)
    local places = {}
    if ctx.hearthPlace then places[#places + 1] = ctx.hearthPlace end
    if ctx.campPlace then places[#places + 1] = ctx.campPlace end
    return places
end
