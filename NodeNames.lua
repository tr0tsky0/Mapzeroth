local addonName, addon = ...

-- Nodes carry no name in the data. A name is worked out here, in the client's
-- language, in this order:
--   1. an explicit locale string "NODE_<nodeID>" (names WE gave a node, or a
--      correction to what the client says);
--   2. flight masters (TAXI_<id>): the client's own taxi node name;
--   3. a kind pattern filled with client-localized zone names ("%s Harbor",
--      "<zone> / <zone> border");
--   4. the node id, as a last resort, so a gap is visible rather than blank.

local L = addon.L

local nameCache = {}
local taxiNames    -- nodeID -> client-supplied name, loaded on first use
local borderPartners

local function zoneName(mapID)
    local info = mapID and C_Map.GetMapInfo(mapID)
    return info and info.name
end

-- The client's name for a map (a zone, a city).
function addon:GetZoneName(mapID)
    return zoneName(mapID)
end

local function continentOf(mapID)
    local id = mapID
    while id and id ~= 0 do
        local info = C_Map.GetMapInfo(id)
        if not info then return nil end
        if info.mapType == Enum.UIMapType.Continent then return id end
        id = info.parentMapID
    end
end

-- The taxi API returns a continent's whole network in one call, so each
-- continent our flight-master nodes sit on is queried once.
local function loadTaxiNames()
    taxiNames = {}
    local queried = {}
    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            if node.id:find("^TAXI_%d+$") then
                local continent = continentOf(node.mapID)
                if continent and not queried[continent] then
                    queried[continent] = true
                    local ok, entries = pcall(C_TaxiMap.GetTaxiNodesForMap, continent)
                    if ok and type(entries) == "table" then
                        for _, entry in ipairs(entries) do
                            if entry.nodeID and entry.name then
                                taxiNames[entry.nodeID] = entry.name
                            end
                        end
                    end
                end
            end
        end
    end
end

local function taxiNameOf(nodeID)
    local id = nodeID and nodeID:match("^TAXI_(%d+)$")
    if not id then return nil end
    if not taxiNames then loadTaxiNames() end
    return taxiNames[tonumber(id)]
end

-- The name of a city or town, in the client's language. A settlement has no
-- name of its own in the data; it takes one from, in order: the client's name
-- for its area, the client's name for its flight master (minus the ", Zone"
-- suffix), or a locale string CITY_<KEY> / TOWN_<KEY>.
local function settlementName(settlements, key, stringPrefix)
    local settlement = settlements and settlements[key]
    if not settlement then return nil end

    if settlement.area and C_Map.GetAreaInfo then
        local name = C_Map.GetAreaInfo(settlement.area)
        if name then return name end
    end
    local taxiName = taxiNameOf(settlement.taxi)
    if taxiName then
        return (taxiName:gsub(",.*$", ""))
    end
    local stringKey = stringPrefix .. key:upper()
    if addon:HasString(stringKey) then
        return L[stringKey]
    end
end

function addon:GetTownName(key) return settlementName(addon.Towns, key, "TOWN_") end
function addon:GetCityName(key) return settlementName(addon.Cities, key, "CITY_") end

-- A spell's name and rank text ("Tailoring", "Journeyman"), in the client's language.
-- Rank text is loaded lazily: the first lookup can return a name with no rank, so this
-- asks the client to load the spell data and the caller should look again on
-- SPELL_DATA_LOAD_RESULT. That is why a rank spell showed its tier on the second try.
function addon:GetSpellLabel(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    local rank = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
    if rank == "" then rank = nil end
    if (not info or not rank) and C_Spell.RequestLoadSpellData then
        C_Spell.RequestLoadSpellData(spellID)
    end
    return info and info.name, rank
end

-- What a trainer trains, in the client's language: a class name from the client,
-- or one of our own strings (weapons, riding).
local function trainerTypeName(token)
    if addon.CLASS_TOKENS[token] and LOCALIZED_CLASS_NAMES_MALE then
        return LOCALIZED_CLASS_NAMES_MALE[token]
    end
    -- A profession is named by the client's name for its first-rank spell.
    local professionSpell = addon.Professions and addon.Professions[token]
    if professionSpell then
        local info = C_Spell.GetSpellInfo(professionSpell)
        return info and info.name
    end
    local key = "TRAINER_" .. tostring(token)
    if addon:HasString(key) then return L[key] end
end

-- The node on the other side of a border crossing.
local function borderPartner(nodeID)
    if not borderPartners then
        borderPartners = {}
        for _, edge in ipairs(addon.Edges or {}) do
            if edge.from:find("^BORDER_") and edge.to:find("^BORDER_") then
                borderPartners[edge.from] = edge.to
                borderPartners[edge.to] = edge.from
            end
        end
    end
    return borderPartners[nodeID]
end

local function resolve(nodeID)
    local key = "NODE_" .. nodeID
    if addon:HasString(key) then
        return L[key]
    end

    local node = addon.World:GetNode(nodeID)
    if not node then return nil end

    -- A node inside a named area (Valanaar's skydocks) takes the client's name for it.
    if node.area and C_Map.GetAreaInfo then
        local name = C_Map.GetAreaInfo(node.area)
        if name then return name end
    end

    -- Places ("Goldshire Inn", "Stormwind Mage Trainer"): a kind pattern over the name
    -- of the city or town they belong to, or of their zone if they belong to neither.
    if node.kind then
        local where
        if node.city then
            where = addon:GetCityName(node.city)
        elseif node.town then
            where = addon:GetTownName(node.town)
        else
            where = zoneName(node.mapID)
        end
        local pattern = "NODE_KIND_" .. node.kind:upper()
        if not (where and addon:HasString(pattern)) then return nil end
        if node.kind == "trainer" then
            local what = trainerTypeName(node.trainer)
            return what and L[pattern]:format(where, what) or nil
        end
        return L[pattern]:format(where)
    end

    if nodeID:match("^TAXI_%d+$") then
        return taxiNameOf(nodeID)
    end

    local kind = nodeID:match("^(%u+)_")
    if kind == "BORDER" then
        local partner = addon.World:GetNode(borderPartner(nodeID) or "")
        local here, there = zoneName(node.mapID), partner and zoneName(partner.mapID)
        if here and there then
            return L["NODE_KIND_BORDER"]:format(here, there)
        end
    elseif kind then
        local pattern = "NODE_KIND_" .. kind
        local zone = zoneName(node.mapID)
        if zone and addon:HasString(pattern) then
            return L[pattern]:format(zone)
        end
    end
end

-- Returns a display name for a node, in the client's language.
function addon:GetNodeName(nodeID)
    local cached = nameCache[nodeID]
    if cached then return cached end

    local name = resolve(nodeID)
    if name then
        nameCache[nodeID] = name
        return name
    end
    return nodeID
end

-- Forget resolved names, e.g. after a locale change or in tests.
function addon:ClearNodeNameCache()
    nameCache, taxiNames, borderPartners = {}, nil, nil
end
