local addonName, addon = ...

-- What the main window offers before anything is typed: sections that open like an accordion.
--
--   Personally relevant  the waypoint they have set on the map, if any; "Nearest ..." picks for what
--                        matters to this character: the nearest ley
--                        line (Skyborne), class trainer (and pet or demon trainer), a trainer for each
--                        profession they have that still teaches them something, a weapon master that
--                        teaches a weapon they can learn and don't have
--   Cities               their faction's (and neutral) cities
--   Towns                the same for towns
--
-- Modern (addon.CURRENT_EXPANSION is set, Data/Modern/Places.lua) has too many places for that, so the page
-- shows the current expansion and what is used every day:
--   Cities               the current expansion's, and the hub cities of any expansion
--   Dungeons             the current expansion's, and the older ones in this season's Mythic+ pool
--   Raids                the current expansion's
--   Older content        one section for each earlier expansion, newest first, holding its cities, dungeons and raids
-- (a section can hold sections; searching finds everything wherever it is filed).
--
-- The other faction's places are not listed here; searching still finds them. A section is
-- built without any travel times: Price fills them in, and the panel only calls it when a section is
-- first opened, so opening the window does no route search.
--
-- Each item is shaped like a destination entry (name, nodeID, nodeIDs, group, ...), so choosing one plans
-- a route as usual; a pick's nodeIDs are every place of its kind and the nearest is worked out when priced
-- or chosen.

local Sections = {}
addon.Sections = Sections

local L = addon.L

local function pick(name, group, nodeIDs)
    return { name = name, nodeID = nodeIDs[1], nodeIDs = nodeIDs, group = group, relevant = true, pick = true }
end

local function expansionName(rev)
    return _G["EXPANSION_NAME" .. (rev - 1)] or L["SECTION_EXPANSION"]:format(rev)
end

local function find(sections, id)
    for _, section in ipairs(sections) do
        if section.id == id then return section end
    end
end

-- The sections of the Modern page (see the top of this file), from the destination entries.
local function modernSections(entries, add, sections)
    local current, seasonal = addon.CURRENT_EXPANSION, {}
    for _, id in ipairs(addon.SEASONAL_DUNGEONS or {}) do seasonal[id] = true end
    local cities, dungeons, raids = {}, {}, {}
    local older = {}                                      -- expansion -> { cities, dungeons, raids } lists
    for _, entry in ipairs(entries) do
        local rev = entry.expansion
        if rev and entry.relevant ~= false then
            local kind
            if entry.group == "place" and entry.kind == "city" then kind = "cities"
            elseif entry.group == "instance" then kind = entry.raid and "raids" or "dungeons" end
            if kind then
                entry.eta, entry.nearest = nil, nil
                if rev == current or (kind == "cities" and entry.hub) or (kind == "dungeons" and seasonal[entry.instanceID]) then
                    table.insert(kind == "cities" and cities or kind == "raids" and raids or dungeons, entry)
                end
                if rev < current then
                    older[rev] = older[rev] or { cities = {}, dungeons = {}, raids = {} }
                    table.insert(older[rev][kind], entry)
                end
            end
        end
    end
    local byName = function(a, b) return a.name < b.name end
    for _, list in ipairs({ cities, dungeons, raids }) do table.sort(list, byName) end
    add("cities", L["SECTION_CITIES"], cities)
    add("dungeons", L["SECTION_DUNGEONS"], dungeons)
    add("raids", L["SECTION_RAIDS"], raids)
    -- This season's dungeons lead the Dungeons list, ahead of the rest, however near those are.
    for _, entry in ipairs(dungeons) do entry.seasonal = seasonal[entry.instanceID] or nil end
    local section = find(sections, "dungeons")
    if section then section.seasonalFirst = true end

    local children = {}
    for rev = current - 1, 1, -1 do
        local group = older[rev]
        if group then
            local items = {}
            for _, list in ipairs({ group.cities, group.dungeons, group.raids }) do
                table.sort(list, byName)
                for _, entry in ipairs(list) do items[#items + 1] = entry end
            end
            if #items > 0 then children[#children + 1] = { id = "expansion" .. rev, title = expansionName(rev), items = items } end
        end
    end
    if #children > 0 then
        sections[#sections + 1] = { id = "older", title = L["SECTION_OLDER"], items = {}, children = children }
    end
end

-- Returns { { id, title, items, children? }, ... } for this player's entries (from Destinations:Build) and context.
-- `index` (by node id) is set on the result for Price.
function Sections:Build(entries, ctx, waypoint)
    local leylines, cities, towns = {}, {}, {}
    local trainers, tokens = {}, {}            -- token -> node ids of trainers worth going to
    local index = {}
    for _, entry in ipairs(entries) do
        if entry.group == "leyline" and entry.relevant then
            leylines[#leylines + 1] = entry.nodeID
            index[entry.nodeID] = entry
        elseif entry.group == "trainer" and entry.relevant and entry.trainer then
            if not trainers[entry.trainer] then
                trainers[entry.trainer] = {}
                tokens[#tokens + 1] = entry.trainer
            end
            table.insert(trainers[entry.trainer], entry.nodeID)
            index[entry.nodeID] = entry
        elseif entry.group == "place" and entry.relevant and not addon.CURRENT_EXPANSION then
            table.insert(entry.kind == "city" and cities or towns, entry)
            entry.eta, entry.nearest = nil, nil
        end
    end

    local picks = {}
    -- The waypoint they set on the map, when they have one: where they are heading, so first.
    if waypoint then
        index[waypoint.id] = { name = addon:GetZoneName(waypoint.mapID) or "" }
        picks[#picks + 1] = {
            name = L["PICK_WAYPOINT"], nodeID = waypoint.id, nodeIDs = { waypoint.id }, group = "waypoint",
            relevant = true, pick = true, dest = waypoint,
        }
    end
    if #leylines > 0 then picks[#picks + 1] = pick(L["PICK_LEYLINE"], "leyline", leylines) end
    if trainers[ctx.class] then picks[#picks + 1] = pick(L["PICK_CLASS"], "trainer", trainers[ctx.class]) end
    for token, key in pairs({ PET = "PICK_PET", DEMON = "PICK_DEMON" }) do
        if trainers[token] then picks[#picks + 1] = pick(L[key], "trainer", trainers[token]) end
    end
    -- One pick per profession they have, in alphabetical order of the client's name for it.
    local professions = {}
    for _, token in ipairs(tokens) do
        if addon.Professions and addon.Professions[token] then
            professions[#professions + 1] = { token = token, name = addon:GetTrainerTypeName(token) or token }
        end
    end
    table.sort(professions, function(a, b) return a.name < b.name end)
    for _, profession in ipairs(professions) do
        picks[#picks + 1] = pick(L["PICK_PROFESSION"]:format(profession.name), "trainer", trainers[profession.token])
    end
    if trainers.WEAPON then picks[#picks + 1] = pick(L["PICK_WEAPON"], "trainer", trainers.WEAPON) end

    local byName = function(a, b) return a.name < b.name end
    table.sort(cities, byName)
    table.sort(towns, byName)

    local sections = { index = index }
    local function add(id, title, items)
        if #items > 0 then sections[#sections + 1] = { id = id, title = title, items = items } end
    end
    add("relevant", L["SECTION_RELEVANT"], picks)
    if addon.CURRENT_EXPANSION then
        modernSections(entries, add, sections)
    else
        add("cities", L["SECTION_CITIES"], cities)
        add("towns", L["SECTION_TOWNS"], towns)
    end
    return sections
end

-- Fills in each item's travel time (`eta`, seconds, nil if there is no way there) and, for a pick, which
-- place is the nearest (`nearest` = the node id, `where` = its name). Places are listed nearest first.
-- session: from Journey:Build.
function Sections:Price(sections, session)
    for _, section in ipairs(sections) do
        for _, child in ipairs(section.children or {}) do self:Price({ child, index = sections.index }, session) end
        for _, item in ipairs(section.items) do
            local nearest, cost = addon.Journey:Nearest(session, item.nodeIDs)
            item.nearest, item.eta = nearest, cost
            local place = item.pick and nearest and sections.index[nearest]
            item.where = place and place.name or nil
        end
        if section.id ~= "relevant" then
            table.sort(section.items, function(a, b)
                if section.seasonalFirst and (a.seasonal ~= nil) ~= (b.seasonal ~= nil) then return a.seasonal ~= nil end
                if (a.eta ~= nil) ~= (b.eta ~= nil) then return a.eta ~= nil end
                if a.eta ~= b.eta then return a.eta < b.eta end
                return a.name < b.name
            end)
        end
    end
end

-- How many places a section holds, counting the sections inside it.
function Sections:Count(section)
    local n = #section.items
    for _, child in ipairs(section.children or {}) do n = n + self:Count(child) end
    return n
end
