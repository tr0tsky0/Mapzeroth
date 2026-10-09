local addonName, addon = ...

-- What the main window offers before anything is typed: a few picks of their own at the top, then sections that open
-- like an accordion.
--
--   (top, no heading)    the waypoint they have set on the map, if any; the nearest ley line or convergence
--                        (Skyborne); tours: TomTom's waypoints when there are any, and pasted coordinates
--   Your Nearest Trainers  their class trainer (and pet or demon trainer), a trainer for each profession they have that
--                        still teaches them something, a weapon master that teaches a weapon they can learn and
--                        don't have
--   Cities               their faction's (and neutral) cities
--   Towns                the same for towns
--   Dungeons             those at or below their level by the client's group finder (its suggested range, read live;
--   Raids                else the dungeon finder's minimum), highest first, then by name; one line each, no time
-- Each pick can be turned off on the settings page (PickChoices).
--
-- Which page a dataset gets is declared by its addon.PICKER_LAYOUT: "settlements" (Forever, Data/Forever/Game.lua)
-- is the page above. Modern's is "expansions" (Data/Modern/Places.lua): it has too many places for that, so the page
-- shows the current expansion and what is used every day:
--   Cities               the current expansion's, and the hub cities of any expansion
--   Towns                the current expansion's
--   Dungeons             the current expansion's, and the older ones in this season's Mythic+ pool
--   Raids                the current expansion's
--   Older content        one section for each earlier expansion, newest first, holding its cities, towns, dungeons and raids
-- (a section can hold sections; searching finds everything wherever it is filed).
--
-- The other faction's places are not listed here; searching still finds them. Places are built without any travel
-- times: Price fills them in, and the panel only calls it when a section of places is first opened, so opening the
-- window does no route search. A pick never has a time: which of its places it goes to, and whether one way or there
-- and back, is worked out when it is chosen (the route's own one way / round trip choice).
--
-- Each item is shaped like a destination entry (name, nodeID, nodeIDs, group, ...), so choosing one plans
-- a route as usual; a pick's nodeIDs are every place of its kind and the nearest is worked out when priced
-- or chosen.

local Sections = {}
addon.Sections = Sections

local L = addon.L

-- key: which setting on the settings page's picker page shows or hides it (Options:ShowsPick; Sections:PickChoices lists them).
local function pick(name, group, nodeIDs, key)
    return { name = name, nodeID = nodeIDs[1], nodeIDs = nodeIDs, group = group, relevant = true, pick = true, key = key }
end

local PET_PICKS = { PET = "PICK_PET", DEMON = "PICK_DEMON" }
local PET_CLASSES = { HUNTER = "PET", WARLOCK = "DEMON" }

-- The professions this dataset has trainers for, { token, name } in alphabetical order of the client's name for them.
-- only: a set of tokens to keep (nil for all).
local function professionList(only)
    local list = {}
    for token in pairs(addon.Professions or {}) do
        if not only or only[token] then list[#list + 1] = { token = token, name = addon:GetTrainerTypeName(token) or token } end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- The picks a player can show or hide on the settings page, in the order the picker lists them:
-- { { key, label }, ... }. class and faction are this character's (a pet or demon trainer only for the classes
-- that have one, and the ley line or convergence pick by faction); TomTom only when it is loaded.
function Sections:PickChoices(class, faction, hasTomTom)
    local choices = { { key = "waypoint", label = L["PICK_WAYPOINT"] } }
    if addon.LeyLineSpell then
        choices[#choices + 1] = { key = "leyline", label = L[faction == "Horde" and "PICK_CONVERGENCE" or "PICK_LEYLINE"] }
    end
    if hasTomTom then choices[#choices + 1] = { key = "tomtom", label = L["OPT_PICK_TOMTOM"] } end
    choices[#choices + 1] = { key = "paste", label = L["PICK_PASTE"] }
    if addon.Professions then                    -- a dataset with trainers (Forever)
        choices[#choices + 1] = { key = "class", label = L["PICK_CLASS"] }
        local pet = PET_CLASSES[class]
        if pet then choices[#choices + 1] = { key = "pet", label = L[PET_PICKS[pet]] } end
        for _, profession in ipairs(professionList()) do
            choices[#choices + 1] = { key = "prof_" .. profession.token, label = L["PICK_PROFESSION"]:format(profession.name) }
        end
        choices[#choices + 1] = { key = "weapon", label = L["PICK_WEAPON"] }
    end
    return choices
end

local function expansionName(rev)
    return addon:GetExpansionName(rev)
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
    local cities, towns, dungeons, raids = {}, {}, {}, {}
    local older = {}                                      -- expansion -> { cities, towns, dungeons, raids } lists
    for _, entry in ipairs(entries) do
        local rev = entry.expansion
        if rev and entry.relevant ~= false then
            local kind
            if entry.group == "place" then kind = entry.kind == "city" and "cities" or "towns"
            elseif entry.group == "instance" then kind = entry.raid and "raids" or "dungeons" end
            if kind then
                entry.eta, entry.nearest = nil, nil
                if rev == current or (kind == "cities" and entry.hub) or (kind == "dungeons" and seasonal[entry.instanceID]) then
                    table.insert(({ cities = cities, towns = towns, raids = raids, dungeons = dungeons })[kind], entry)
                end
                if rev < current then
                    older[rev] = older[rev] or { cities = {}, towns = {}, dungeons = {}, raids = {} }
                    table.insert(older[rev][kind], entry)
                end
            end
        end
    end
    local byName = function(a, b) return a.name < b.name end
    for _, list in ipairs({ cities, towns, dungeons, raids }) do table.sort(list, byName) end
    add("cities", L["SECTION_CITIES"], cities)
    add("towns", L["SECTION_TOWNS"], towns)
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
            for _, list in ipairs({ group.cities, group.towns, group.dungeons, group.raids }) do
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

-- Returns { { id, title, items, children? }, ... } for this player's entries (from Destinations:Build) and context, with
-- `top` (the picks above the sections, in order) and `index` (by node id, for Price) set on it.
-- tomtomCount: how many waypoints TomTom has (nil when it isn't loaded). The last top picks are tours (MultiRoute.lua):
-- TomTom's waypoints when there are any, and coordinates pasted in. They have an `action` for the panel instead of a
-- place, and no time until they are planned.
function Sections:Build(entries, ctx, waypoint, tomtomCount)
    local byExpansion = addon.PICKER_LAYOUT == "expansions"
    local leylines, convergences, cities, towns, dungeons, raids = {}, {}, {}, {}, {}, {}
    local trainers, tokens = {}, {}            -- token -> node ids of trainers worth going to
    local index = {}
    for _, entry in ipairs(entries) do
        if entry.group == "leyline" and entry.relevant then
            leylines[#leylines + 1] = entry.nodeID
            index[entry.nodeID] = entry
        elseif entry.group == "convergence" and entry.relevant then
            convergences[#convergences + 1] = entry.nodeID
            index[entry.nodeID] = entry
        elseif entry.group == "trainer" and entry.relevant and entry.trainer then
            if not trainers[entry.trainer] then
                trainers[entry.trainer] = {}
                tokens[#tokens + 1] = entry.trainer
            end
            table.insert(trainers[entry.trainer], entry.nodeID)
            index[entry.nodeID] = entry
        elseif entry.group == "place" and entry.relevant and not byExpansion then
            table.insert(entry.kind == "city" and cities or towns, entry)
            entry.eta, entry.nearest = nil, nil
        elseif entry.group == "instance" and not byExpansion and entry.minLevel and entry.minLevel <= (ctx.level or 0) then
            table.insert(entry.raid and raids or dungeons, entry)
        end
    end

    local top, picks = {}, {}
    -- The waypoint they set on the map, when they have one: where they are heading, so first.
    if waypoint then
        index[waypoint.id] = { name = addon:GetZoneName(waypoint.mapID) or "" }
        top[#top + 1] = {
            name = L["PICK_WAYPOINT"], nodeID = waypoint.id, nodeIDs = { waypoint.id }, group = "waypoint",
            relevant = true, pick = true, dest = waypoint, key = "waypoint",
        }
    end
    if #leylines > 0 then top[#top + 1] = pick(L["PICK_LEYLINE"], "leyline", leylines, "leyline") end
    if #convergences > 0 then top[#top + 1] = pick(L["PICK_CONVERGENCE"], "convergence", convergences, "leyline") end
    if tomtomCount and tomtomCount > 0 then
        top[#top + 1] = { name = L["PICK_TOMTOM"]:format(tomtomCount), group = "waypoint",
                          relevant = true, pick = true, action = "tomtom", key = "tomtom" }
    end
    top[#top + 1] = { name = L["PICK_PASTE"], group = "waypoint",
                      relevant = true, pick = true, action = "paste", key = "paste" }

    if trainers[ctx.class] then picks[#picks + 1] = pick(L["PICK_CLASS"], "trainer", trainers[ctx.class], "class") end
    for token, key in pairs(PET_PICKS) do
        if trainers[token] then picks[#picks + 1] = pick(L[key], "trainer", trainers[token], "pet") end
    end
    -- One pick per profession they have, in alphabetical order of the client's name for it.
    local have = {}
    for _, token in ipairs(tokens) do have[token] = true end
    for _, profession in ipairs(professionList(have)) do
        picks[#picks + 1] = pick(L["PICK_PROFESSION"]:format(profession.name), "trainer", trainers[profession.token],
            "prof_" .. profession.token)
    end
    if trainers.WEAPON then picks[#picks + 1] = pick(L["PICK_WEAPON"], "trainer", trainers.WEAPON, "weapon") end
    -- What the player turned off on the settings page.
    local function shown(list)
        local out = {}
        for _, item in ipairs(list) do
            if addon.Options:ShowsPick(item.key) then out[#out + 1] = item end
        end
        return out
    end
    top, picks = shown(top), shown(picks)

    local byName = function(a, b) return a.name < b.name end
    table.sort(cities, byName)
    table.sort(towns, byName)
    local byLevel = function(a, b)
        if a.minLevel ~= b.minLevel then return a.minLevel > b.minLevel end
        return a.name < b.name
    end
    table.sort(dungeons, byLevel)
    table.sort(raids, byLevel)

    local sections = { index = index, top = top }
    local function add(id, title, items)
        if #items > 0 then sections[#sections + 1] = { id = id, title = title, items = items } end
    end
    add("trainers", L["SECTION_TRAINERS"], picks)
    if byExpansion then
        modernSections(entries, add, sections)
    else
        add("cities", L["SECTION_CITIES"], cities)
        add("towns", L["SECTION_TOWNS"], towns)
        -- Listed by level, one line each: no time to price, so opening them searches no routes (NeedsPricing).
        add("dungeons", L["SECTION_DUNGEONS"], dungeons)
        add("raids", L["SECTION_RAIDS"], raids)
        for _, id in ipairs({ "dungeons", "raids" }) do
            local section = find(sections, id)
            if section then section.untimed = true end
        end
    end
    return sections
end

-- Whether opening the section `id` needs times: it (or a section inside it) holds places, not just picks, and isn't
-- one listed without times.
function Sections:NeedsPricing(sections, id)
    local function places(section)
        if section.untimed then return false end
        for _, item in ipairs(section.items) do
            if not item.pick then return true end
        end
        for _, child in ipairs(section.children or {}) do
            if places(child) then return true end
        end
        return false
    end
    local function find(list)
        for _, section in ipairs(list) do
            if section.id == id then return section end
            local inner = find(section.children or {})
            if inner then return inner end
        end
    end
    local section = find(sections or {})
    return section ~= nil and places(section)
end

-- Fills in each place's travel time (`eta`, seconds, nil if there is no way there) and lists them nearest first.
-- Picks are left alone (no time until chosen) and keep their order. session: from Journey:Build.
function Sections:Price(sections, session)
    for _, section in ipairs(sections) do
        for _, child in ipairs(section.children or {}) do self:Price({ child, index = sections.index }, session) end
        for _, item in ipairs(section.items) do
            if not item.pick and not section.untimed then
                item.eta = select(2, addon.Journey:Nearest(session, item.nodeIDs or { item.nodeID }))
            end
        end
        if section.id ~= "trainers" and not section.untimed then
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
