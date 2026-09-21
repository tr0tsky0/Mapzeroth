local addonName, addon = ...

-- What the main window offers before anything is typed: sections that open like an accordion.
--
--   Personally relevant  "Nearest ..." picks for what matters to this character: the nearest ley
--                        line (Skyborne), class trainer (and pet or demon trainer), a trainer for each
--                        profession they have that still teaches them something, a weapon master that
--                        teaches a weapon they can learn and don't have
--   Cities               their faction's (and neutral) cities
--   Towns                the same for towns
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

-- Returns { { id, title, items }, ... } for this player's entries (from Destinations:Build) and context.
-- `index` (by node id) is set on the result for Price.
function Sections:Build(entries, ctx)
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
        elseif entry.group == "place" and entry.relevant then
            table.insert(entry.kind == "city" and cities or towns, entry)
            entry.eta, entry.nearest = nil, nil
        end
    end

    local picks = {}
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
    add("cities", L["SECTION_CITIES"], cities)
    add("towns", L["SECTION_TOWNS"], towns)
    return sections
end

-- Fills in each item's travel time (`eta`, seconds, nil if there is no way there) and, for a pick, which
-- place is the nearest (`nearest` = the node id, `where` = its name). Places are listed nearest first.
-- session: from Journey:Build.
function Sections:Price(sections, session)
    for _, section in ipairs(sections) do
        for _, item in ipairs(section.items) do
            local nearest, cost = addon.Journey:Nearest(session, item.nodeIDs)
            item.nearest, item.eta = nearest, cost
            local place = item.pick and nearest and sections.index[nearest]
            item.where = place and place.name or nil
        end
        if section.id ~= "relevant" then
            table.sort(section.items, function(a, b)
                if (a.eta ~= nil) ~= (b.eta ~= nil) then return a.eta ~= nil end
                if a.eta ~= b.eta then return a.eta < b.eta end
                return a.name < b.name
            end)
        end
    end
end
