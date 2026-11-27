local addonName, addon = ...

-- What the main window offers before anything is typed: a few picks of their own at the top, then sections that open
-- like an accordion.
--
--   (top, no heading)    the waypoint they have set on the map, if any; the quest they follow; the nearest ley line or convergence
--                        (Skyborne); tours: TomTom's waypoints when there are any, and pasted coordinates
--   Nearest              picks in three sections of their own (one with nothing in it isn't there):
--     Trainers           their class trainer (and pet or demon trainer), a riding instructor that teaches a rank they
--                        don't know, a weapon master that teaches a weapon they can learn and don't have, a trainer
--                        for each profession they have that still teaches them something (else, for Cooking, First
--                        Aid and Fishing, where the next rank's book is sold or quest given)
--     Vendors            a reagent vendor (a poison vendor for rogues; neither for classes with no reagents), an
--                        innkeeper
--     Other              an auction house, a bank, a stable master (hunters), a flight master
--                        Inns, banks and auction houses are their faction's settlements' and neutral ones; each pick
--                        is there only when the dataset has places of its kind (Modern: no trainers, banks or
--                        auction houses)
--   Cities               their faction's (and neutral) cities
--   Towns                the same for towns
--   Dungeons             those at or below their level by the client's group finder (its suggested range, read live;
--   Raids                else the dungeon finder's minimum), highest first, then by name; one line each, no time
-- Each pick can be turned off on the settings page (PickChoices).
--
-- Which page a dataset gets is declared by its addon.PICKER_LAYOUT: "settlements" (Forever, Data/Forever/Game.lua)
-- is the page above. Modern's is "expansions" (Data/Modern/Places.lua): it has too many places for that, so the page
-- shows the current expansion and what is used every day (after Personally Relevant, above):
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

-- The "Your Waypoint" pick for the map waypoint `waypoint` (addon:GetWaypoint): on the list, and what the question on
-- a new waypoint routes to (UI/WaypointPrompt.lua).
function Sections.WaypointPick(waypoint)
    local entry = pick(L["PICK_WAYPOINT"], "waypoint", { waypoint.id }, "waypoint")
    entry.dest = waypoint
    return entry
end

-- The pick for a quest (addon:GetQuestTarget), named by its title.
function Sections.QuestPick(quest)
    return {
        name = quest.title and L["PICK_QUEST_NAMED"]:format(quest.title) or L["PICK_QUEST"], nodeID = quest.id,
        nodeIDs = { quest.id }, group = "waypoint", relevant = true, pick = true, dest = quest, key = "quest",
    }
end

-- The pick for the player's corpse (addon:GetCorpseTarget), for the run back as a ghost.
function Sections.CorpsePick(corpse)
    return {
        name = L["PICK_CORPSE"], nodeID = corpse.id, nodeIDs = { corpse.id }, group = "waypoint", relevant = true,
        pick = true, dest = corpse, key = "corpse",
    }
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

-- The service picks (Nearest's Vendors and Other): node kind -> { key, label, group }, in the order listed. `class`:
-- only for that class; `notClass`: for anyone else. A reagent vendor (Forever) sells a rogue poison ingredients, so
-- for rogues it is the Poison Vendor; for the other classes whose reagents it sells, the Reagent Vendor
-- (Relevance.lua: which of them sell this class's).
local SERVICE_PICKS = {
    { kind = "reagent", key = "reagent", label = "PICK_REAGENT", group = "vendors", notClass = "ROGUE" },
    { kind = "reagent", key = "poison", label = "PICK_POISON", group = "vendors", class = "ROGUE" },
    { kind = "inn", key = "inn", label = "PICK_INN", group = "vendors" },
    { kind = "auction", key = "auction", label = "PICK_AUCTION", group = "other" },
    { kind = "bank", key = "bank", label = "PICK_BANK", group = "other" },
    { kind = "stable", key = "stable", label = "PICK_STABLE", group = "other", class = "HUNTER" },
}

local function forClass(service, class)
    return (not service.class or service.class == class) and (not service.notClass or service.notClass ~= class)
end

-- Whether this dataset has a node of `kind` (and `trainer`, for a trainer); for a reagent vendor, one that sells
-- `class` its reagents.
local function hasKind(kind, trainer, class)
    local found = false
    addon.World:ForEachNode(function(node)
        if node.kind == kind and (not trainer or node.trainer == trainer)
            and (kind ~= "reagent" or addon.Relevance:SellsReagentsTo(node, class)) then
            found = true
        end
    end)
    return found
end

-- The picks a player can show or hide on the settings page, in the order the picker lists them:
-- { { key, label }, ... }. class and faction are this character's (a pet or demon trainer only for the classes
-- that have one, a stable master for hunters, and the ley line or convergence pick by faction); TomTom only when it
-- is loaded; the Nearest picks only when the dataset has places of their kind.
function Sections:PickChoices(class, faction, hasTomTom)
    local choices = { { key = "waypoint", label = L["PICK_WAYPOINT"] }, { key = "quest", label = L["PICK_QUEST"] } }
    if addon.LeyLineSpell then
        choices[#choices + 1] = { key = "leyline", label = L[faction == "Horde" and "PICK_CONVERGENCE" or "PICK_LEYLINE"] }
    end
    if hasTomTom then choices[#choices + 1] = { key = "tomtom", label = L["OPT_PICK_TOMTOM"] } end
    choices[#choices + 1] = { key = "paste", label = L["PICK_PASTE"] }
    if addon.Professions then                    -- a dataset with trainers (Forever)
        choices[#choices + 1] = { key = "class", label = L["PICK_CLASS"] }
        local pet = PET_CLASSES[class]
        if pet then choices[#choices + 1] = { key = "pet", label = L[PET_PICKS[pet]] } end
        if hasKind("trainer", "RIDING") then choices[#choices + 1] = { key = "riding", label = L["PICK_RIDING"] } end
        choices[#choices + 1] = { key = "weapon", label = L["PICK_WEAPON"] }
        for _, profession in ipairs(professionList()) do
            choices[#choices + 1] = { key = "prof_" .. profession.token, label = L["PICK_PROFESSION"]:format(profession.name) }
        end
    end
    for _, service in ipairs(SERVICE_PICKS) do
        if forClass(service, class) and hasKind(service.kind, nil, class) then
            choices[#choices + 1] = { key = service.key, label = L[service.label] }
        end
    end
    choices[#choices + 1] = { key = "flight", label = L["PICK_FLIGHT"] }
    return choices
end

-- Whose settlement a place (an inn, bank, auction house) stands in: true when it is theirs, both factions', or no
-- one's on record (a place in no settlement too).
local function oursAt(node, faction)
    local settlement = (node.city and addon.Cities and addon.Cities[node.city])
        or (node.town and addon.Towns and addon.Towns[node.town])
    local owner = settlement and settlement.faction
    return not owner or owner == "Both" or not faction or owner == faction
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
-- quest: the quest they follow (addon:GetQuestTarget), or nil.
function Sections:Build(entries, ctx, waypoint, tomtomCount, quest)
    local byExpansion = addon.PICKER_LAYOUT == "expansions"
    local flights, cities, towns, dungeons, raids = {}, {}, {}, {}, {}
    local trainers, tokens = {}, {}            -- token -> node ids of trainers worth going to
    local sources = {}                         -- token -> { group = "book" | "rankquest", ids } (no trainer has the rank)
    local index = {}
    for _, entry in ipairs(entries) do
        if entry.group == "flight" then
            flights[#flights + 1] = entry.nodeID   -- the other faction's aren't entries (Destinations:Build)
            index[entry.nodeID] = entry
        elseif entry.group == "trainer" and entry.relevant and entry.trainer then
            if not trainers[entry.trainer] then
                trainers[entry.trainer] = {}
                tokens[#tokens + 1] = entry.trainer
            end
            table.insert(trainers[entry.trainer], entry.nodeID)
            index[entry.nodeID] = entry
        elseif (entry.group == "book" or entry.group == "rankquest") and entry.relevant and entry.trainer then
            -- Where the next rank of a profession comes from when no trainer teaches it: one kind at a time.
            sources[entry.trainer] = sources[entry.trainer] or { group = entry.group, ids = {} }
            table.insert(sources[entry.trainer].ids, entry.nodeID)
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
        top[#top + 1] = Sections.WaypointPick(waypoint)
    end
    -- The quest the game's arrow points to, named by its title.
    if quest then
        index[quest.id] = { name = addon:GetZoneName(quest.mapID) or "" }
        top[#top + 1] = Sections.QuestPick(quest)
    end
    -- The nearest ley line or convergence (Skyborne): its places come from SLLCM when it is planned (LeyShare:PlacesFor).
    -- Without SLLCM the row points to it instead (action "sllcm"), until the player dismisses that.
    local horde = ctx.faction == "Horde"
    local leyKind = horde and "convergence" or "leyline"
    local leyMode = addon.LeyShare and addon.Relevance:IsRelevant({ kind = leyKind }, ctx) and addon.LeyShare:PickMode()
    if leyMode then
        local ley = pick(L[horde and "PICK_CONVERGENCE" or "PICK_LEYLINE"], leyKind, {}, "leyline")
        if leyMode == "hint" then ley.action = "sllcm" end
        top[#top + 1] = ley
    end
    if tomtomCount and tomtomCount > 0 then
        top[#top + 1] = { name = L["PICK_TOMTOM"]:format(tomtomCount), group = "waypoint",
                          relevant = true, pick = true, action = "tomtom", key = "tomtom" }
    end
    top[#top + 1] = { name = L["PICK_PASTE"], group = "waypoint",
                      relevant = true, pick = true, action = "paste", key = "paste" }

    local trainerPicks, vendorPicks, otherPicks = {}, {}, {}
    local function push(list, item) list[#list + 1] = item end
    if trainers[ctx.class] then push(trainerPicks, pick(L["PICK_CLASS"], "trainer", trainers[ctx.class], "class")) end
    for token, key in pairs(PET_PICKS) do
        if trainers[token] then push(trainerPicks, pick(L[key], "trainer", trainers[token], "pet")) end
    end
    if trainers.RIDING then push(trainerPicks, pick(L["PICK_RIDING"], "trainer", trainers.RIDING, "riding")) end
    if trainers.WEAPON then push(trainerPicks, pick(L["PICK_WEAPON"], "trainer", trainers.WEAPON, "weapon")) end
    -- One pick per profession they have, in alphabetical order of the client's name for it: its trainer, or when no
    -- trainer teaches the next rank, where its book is sold or its quest given (the same setting hides either).
    local have = {}
    for _, token in ipairs(tokens) do have[token] = true end
    for token in pairs(sources) do have[token] = true end
    for _, profession in ipairs(professionList(have)) do
        local token, source = profession.token, sources[profession.token]
        if trainers[token] then
            push(trainerPicks, pick(L["PICK_PROFESSION"]:format(profession.name), "trainer", trainers[token], "prof_" .. token))
        else
            table.sort(source.ids)
            push(trainerPicks, pick(L[source.group == "book" and "PICK_PROF_BOOK" or "PICK_PROF_QUEST"]:format(profession.name),
                source.group, source.ids, "prof_" .. token))
        end
    end
    -- Inns, banks, auction houses of their faction's settlements and neutral ones; stable masters for hunters and
    -- vendors of this class's reagents, of their faction (Relevance). Read from the nodes, not the entries: Modern's
    -- inns are their towns' entries.
    local services = {}                         -- kind -> node ids, sorted so the pick is the same each time
    addon.World:ForEachNode(function(node)
        local kind = node.kind
        local wanted
        if kind == "stable" or kind == "reagent" then wanted = addon.Relevance:IsRelevant(node, ctx)
        elseif kind == "inn" or kind == "bank" or kind == "auction" then wanted = oursAt(node, ctx.faction) end
        if wanted then
            services[kind] = services[kind] or {}
            table.insert(services[kind], node.id)
        end
    end)
    for _, service in ipairs(SERVICE_PICKS) do
        local ids = services[service.kind]
        if ids and forClass(service, ctx.class) then
            table.sort(ids)
            push(service.group == "vendors" and vendorPicks or otherPicks, pick(L[service.label], service.kind, ids, service.key))
        end
    end
    if #flights > 0 then
        table.sort(flights)
        local flightPick = pick(L["PICK_FLIGHT"], "flight", flights, "flight")
        flightPick.ownWay = true                       -- the nearest without teleporting (Journey's OWN_WAY)
        push(otherPicks, flightPick)
    end
    -- What the player turned off on the settings page.
    local function shown(list)
        local out = {}
        for _, item in ipairs(list) do
            if addon.Options:ShowsPick(item.key) then out[#out + 1] = item end
        end
        return out
    end
    top = shown(top)

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
    -- The picks for this character, under Nearest. A group with none (or all turned off) isn't there, nor is Nearest
    -- without any.
    local nearest = {}
    for _, group in ipairs({ { "nearest_trainers", "SECTION_NEAREST_TRAINERS", trainerPicks },
                             { "nearest_vendors", "SECTION_NEAREST_VENDORS", vendorPicks },
                             { "nearest_other", "SECTION_NEAREST_OTHER", otherPicks } }) do
        local items = shown(group[3])
        if #items > 0 then nearest[#nearest + 1] = { id = group[1], title = L[group[2]], items = items, picks = true } end
    end
    if #nearest > 0 then
        sections[#sections + 1] = { id = "nearest", title = L["SECTION_NEAREST"], items = {}, children = nearest, picks = true }
    end
    local holiday = Sections:HolidayRoutes(ctx)
    if holiday then sections[#sections + 1] = holiday end
    local routes = Sections:Routes()
    if routes then sections[#sections + 1] = routes end
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

-- The holiday routes on now for this player (MultiRoute:HolidayRoutes) as a section, or nil: one line each, no time.
function Sections:HolidayRoutes(ctx)
    local items = {}
    for _, offer in ipairs(addon.MultiRoute:HolidayRoutes(ctx)) do
        items[#items + 1] = { name = offer.route.name, group = "waypoint", action = "holidayroute", points = offer.points,
                              holiday = offer.route.holiday,
                              sub = L["TOUR_STOPS"]:format(#offer.points) }
    end
    if #items == 0 then return nil end
    return { id = "holiday_routes", title = L["SECTION_HOLIDAY_ROUTES"], items = items, untimed = true }
end

-- The player's saved routes (MultiRoute:SavedRoutes) as a section, or nil when there are none: one line each, no time
-- (a tour is planned when chosen).
function Sections:Routes()
    local items = {}
    for _, route in ipairs(addon.MultiRoute:SavedRoutes()) do
        items[#items + 1] = { name = route.name, group = "waypoint", action = "route", routeID = route.id,
                              sub = L["TOUR_STOPS"]:format(#addon.MultiRoute:RoutePoints(route)) }
    end
    if #items == 0 then return nil end
    return { id = "routes", title = L["SECTION_ROUTES"], items = items, untimed = true }
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
                item.eta = select(2, addon.Journey:Nearest(session, item.nodeIDs or { item.nodeID }, item.ownWay))
            end
        end
        if not section.picks and not section.untimed then
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
