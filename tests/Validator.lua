local addonName, addon = ...

-- Static consistency checks over the loaded dataset. Pure Lua, no client
-- APIs, so it also runs headless. Returns a list of { level, message } issues;
-- level is "error" for anything the engine would trip over and "warn" for
-- data that is merely incomplete.

local function isPlaceholder(container)
    return container == nil or container == "" or container == "TODO"
end

function addon:ValidateData()
    local issues = {}
    local function add(level, message)
        issues[#issues + 1] = { level = level, message = message }
    end

    local World = addon.World
    for _, id in ipairs(World:GetDuplicateNodeIDs()) do
        add("error", "duplicate node id: " .. id)
    end

    for _, list in pairs(addon.Nodes or {}) do
        for _, node in ipairs(list) do
            if isPlaceholder(node.container) then
                add("warn", "node has no real container: " .. tostring(node.id))
            end
            if not node.mapID or not node.x or not node.y then
                add("error", "node missing mapID/x/y: " .. tostring(node.id))
            end
            -- Flight masters are named by the client and border crossings by their
            -- zones; everything else we created needs a locale string.
            local id = tostring(node.id)
            if node.kind == "instance" then
                -- An instance entrance is named by the client (its area) or by a string of ours.
                if not (node.area or addon:HasString("NODE_" .. id)) then
                    add("warn", "instance has no name source (area id or NODE_ string): " .. id)
                end
            elseif node.kind then
                -- A place in a city or town is named from its kind and its settlement.
                -- A place outside any settlement is named after its zone instead.
                local isCity = node.city ~= nil
                local key = node.city or node.town
                if key then
                    local settlement = (isCity and addon.Cities or addon.Towns or {})[key]
                    -- (A settlement always has a name: failing its area, flight master and a locale string, the
                    -- client's name for its map. NodeNames.lua's settlementName.)
                    if not settlement then
                        add("error", ("node %s: unknown %s '%s'"):format(id, isCity and "city" or "town", tostring(key)))
                    end
                end
                if node.kind == "trainer" and not (addon.CLASS_TOKENS[node.trainer]
                        or (addon.Professions and addon.Professions[node.trainer])
                        or addon:HasString("TRAINER_" .. tostring(node.trainer))) then
                    add("error", ("node %s: unknown trainer type '%s'"):format(id, tostring(node.trainer)))
                end
                if not addon:HasString("NODE_KIND_" .. node.kind:upper()) then
                    add("error", ("node %s: no name pattern for kind '%s'"):format(id, node.kind))
                end
            elseif not node.area and not id:find("^TAXI_%d+$") and not id:find("^BORDER_")
                    and not addon:HasString("NODE_" .. id) then
                add("warn", "node has no name string (NODE_" .. id .. ")")
            end
        end
    end

    -- An edge repeated with the same requirements is a duplicate (a pair that differs only in its
    -- requirements, one per faction, is not).
    -- A requirement value can be a table ({ 17, 628 } for mapArtID, lists for anyQuest/anyOf): serialise it
    -- by content, so two edges with the same gate compare equal.
    local function serialise(value)
        if type(value) ~= "table" then return tostring(value) end
        local parts = {}
        for key, item in pairs(value) do parts[#parts + 1] = tostring(key) .. "=" .. serialise(item) end
        table.sort(parts)
        return "{" .. table.concat(parts, ",") .. "}"
    end
    local function requirementsKey(requirements)
        local parts = {}
        for key, value in pairs(requirements or {}) do parts[#parts + 1] = key .. "=" .. serialise(value) end
        table.sort(parts)
        return table.concat(parts, ",")
    end
    local seenEdges = {}
    for i, edge in ipairs(addon.Edges or {}) do
        local edgeKey = tostring(edge.from) .. "|" .. tostring(edge.to) .. "|" .. tostring(edge.method)
            .. "|" .. requirementsKey(edge.requirements)
        if seenEdges[edgeKey] then
            add("warn", ("edge %d (%s -> %s, %s): duplicates edge %d"):format(
                i, tostring(edge.from), tostring(edge.to), tostring(edge.method), seenEdges[edgeKey]))
        else
            seenEdges[edgeKey] = i
        end
        if not World:GetNode(edge.from) then
            add("error", ("edge %d: unknown from node %s"):format(i, tostring(edge.from)))
        end
        if not World:GetNode(edge.to) then
            add("error", ("edge %d: unknown to node %s"):format(i, tostring(edge.to)))
        end
        if not edge.method then
            add("error", ("edge %d (%s -> %s): missing method"):format(i, tostring(edge.from), tostring(edge.to)))
        elseif not addon.METHODS[edge.method] then
            add("error", ("edge %d (%s -> %s): method '%s' is not in addon.METHODS"):format(
                i, tostring(edge.from), tostring(edge.to), tostring(edge.method)))
        end
        for key in pairs(edge.requirements or {}) do
            if not addon.RequirementCheckers[key] then
                add("error", ("edge %d (%s -> %s): unknown requirement '%s'"):format(
                    i, tostring(edge.from), tostring(edge.to), key))
            end
        end
        local holiday = edge.requirements and edge.requirements.holiday
        if holiday and not (addon.HOLIDAYS and addon.HOLIDAYS[holiday]) then
            add("error", ("edge %d (%s -> %s): unknown holiday '%s'"):format(
                i, tostring(edge.from), tostring(edge.to), tostring(holiday)))
        end
        -- A phase switch between containers with no phase group changes nothing the search can see.
        if edge.method == "phaseswitch" and World:GetNode(edge.from) and World:GetNode(edge.to)
                and not World:GetPhase(World:GetNodeContainer(edge.from))
                and not World:GetPhase(World:GetNodeContainer(edge.to)) then
            add("warn", ("edge %d (%s -> %s): phaseswitch between containers with no phaseGroup"):format(
                i, tostring(edge.from), tostring(edge.to)))
        end
        -- A phase an edge names must be a side of a group the containers define.
        local groups = World:GetPhaseGroups()
        if edge.inPhase and not (groups[edge.inPhase[1]] and groups[edge.inPhase[1]][edge.inPhase[2]] ~= nil) then
            add("error", ("edge %d (%s -> %s): inPhase names no phase side (%s %s)"):format(
                i, tostring(edge.from), tostring(edge.to), tostring(edge.inPhase[1]), tostring(edge.inPhase[2])))
        end
        for _, group in ipairs(edge.overridesPhase or {}) do
            if not groups[group] then
                add("error", ("edge %d (%s -> %s): overridesPhase names no phase group '%s'"):format(
                    i, tostring(edge.from), tostring(edge.to), tostring(group)))
            end
        end
        -- A walk edge without a cost is a tunnel: the engine derives its cost
        -- from the distance between its ends.
        if edge.cost == nil and edge.method ~= "walk" then
            add("warn", ("edge %d (%s -> %s): no cost"):format(i, tostring(edge.from), tostring(edge.to)))
        end
    end

    -- What a dataset declares instead of the engine guessing from which tables happen to be loaded.
    if addon.PICKER_LAYOUT ~= "settlements" and addon.PICKER_LAYOUT ~= "expansions" then
        add("error", ("PICKER_LAYOUT is %s, not \"settlements\" or \"expansions\""):format(tostring(addon.PICKER_LAYOUT)))
    elseif addon.PICKER_LAYOUT == "expansions" and not addon.CURRENT_EXPANSION then
        add("error", "PICKER_LAYOUT is \"expansions\" but CURRENT_EXPANSION is not set")
    end
    if addon.RidingSkills and addon.DEFAULT_MOUNT_BONUS then
        add("error", "both RidingSkills and DEFAULT_MOUNT_BONUS are set: riding data wins, so the bonus is never used")
    end

    local abilities = addon.Abilities or {}
    for category, list in pairs(abilities) do
        for i, ability in ipairs(list) do
            if ability.method and not addon.METHODS[ability.method] then
                add("error", ("ability %s[%d]: method '%s' is not in addon.METHODS"):format(category, i, ability.method))
            end
            if not ability.spellID and not ability.itemID then
                add("error", ("ability %s[%d]: needs a spellID or itemID"):format(category, i))
            end
            if ability.to and not World:GetNode(ability.to) then
                add("error", ("ability %s[%d]: unknown destination node %s"):format(category, i, tostring(ability.to)))
            end
            for _, dest in ipairs(ability.toList or {}) do
                if not World:GetNode(dest) then
                    add("error", ("ability %s[%d]: unknown destination node %s"):format(category, i, tostring(dest)))
                end
            end
        end
    end

    return issues
end
