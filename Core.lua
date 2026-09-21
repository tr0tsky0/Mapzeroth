local addonName, addon = ...

local PREFIX = "|cff66ccff[Mapzeroth]|r"

local function say(fmt, ...)
    print(PREFIX .. " " .. fmt:format(...))
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("HEARTHSTONE_BOUND")
frame:SetScript("OnEvent", function(_, event)
    if event == "HEARTHSTONE_BOUND" then
        -- You bind at an inn, so this is where the inn is.
        local mapID = C_Map.GetBestMapForUnit("player")
        local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local x, y = pos:GetXY()
            addon:SaveBind(mapID, x, y, GetBindLocation and GetBindLocation() or nil)
        end
        return
    end
    addon.World:Build()
    local nodeCount, containerCount, continents = addon.World:GetStats()
    say("%s ruleset: %d nodes in %d containers (%s).",
        addon:GetRuleset(), nodeCount, containerCount, table.concat(continents, ", "))
end)

-- Development commands. The real /mz commands come with the UI layer.
SLASH_MAPZEROTHREBUILD1 = "/mzr"
SlashCmdList["MAPZEROTHREBUILD"] = function(msg)
    local cmd = msg:match("^(%S+)")

    if cmd == "validate" then
        local issues = addon:ValidateData()
        local errors, warnings = 0, 0
        for _, issue in ipairs(issues) do
            if issue.level == "error" then errors = errors + 1 else warnings = warnings + 1 end
            if errors + warnings <= 25 then
                say("%s: %s", issue.level, issue.message)
            end
        end
        say("validation: %d error(s), %d warning(s).", errors, warnings)

    elseif cmd == "world" then
        addon.World:ForEachContainer(function(c)
            say("%s%s  (%d nodes)", ("  "):rep(c.depth - 1), c.path, #c.nodes)
        end)

    elseif cmd == "route" then
        -- /mzr route <fromNodeID> <toNodeID> [alliance|horde]
        local from, to, faction = msg:match("^route%s+(%S+)%s+(%S+)%s*(%S*)")
        if not from then
            say("usage: /mzr route <fromNodeID> <toNodeID> [alliance|horde]")
            return
        end
        if not addon.World:GetNode(from) or not addon.World:GetNode(to) then
            say("unknown node id (use ids like TAXI_2 or DOCK_STORMWIND)")
            return
        end
        local ctx = addon:GetPlayerContext()
        if faction:lower() == "alliance" then ctx.faction = "Alliance"
        elseif faction:lower() == "horde" then ctx.faction = "Horde" end

        local graph = addon.TravelGraph:Build(ctx)
        local result = addon.Pathfinder:FindPath(graph, from, to)
        if not result then
            say("no route from %s to %s as %s.", from, to, tostring(ctx.faction))
            return
        end
        say("%s -> %s as %s: %d min %d s", addon:GetNodeName(from), addon:GetNodeName(to),
            ctx.faction, math.floor(result.cost / 60), result.cost % 60)
        for _, step in ipairs(addon.Pathfinder:CollapseSteps(result.steps)) do
            say("  %-9s %s -> %s (%ds)", step.method, addon:GetNodeName(step.from),
                addon:GetNodeName(step.to), step.cost)
        end

    elseif cmd == "walktime" then
        -- Calibration: walk between two spots and get the path factor for
        -- Data/Forever/PathFactors.lua. Start and stop where you would actually
        -- travel, in the state you'd travel in (mounted or not).
        local sub = msg:match("^walktime%s+(%S+)")
        local function here()
            local mapID = C_Map.GetBestMapForUnit("player")
            local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
            if not pos then return nil end
            local x, y = pos:GetXY()
            return mapID, x, y
        end

        if sub == "start" then
            local mapID, x, y = here()
            if not mapID then say("can't read your position here"); return end
            local _, runSpeed = GetUnitSpeed("player")
            addon.walkStopwatch = { time = GetTime(), mapID = mapID, x = x, y = y, speed = runSpeed }
            say("stopwatch started on map %d at (%.1f, %.1f), run speed %.1f yd/s. Walk to the other spot, then /mzr walktime stop.",
                mapID, x * 100, y * 100, runSpeed)

        elseif sub == "stop" then
            local start = addon.walkStopwatch
            local mapID, x, y = here()
            if not start then say("no stopwatch running; /mzr walktime start first"); return end
            if not mapID then say("can't read your position here"); return end
            addon.walkStopwatch = nil

            local elapsed = GetTime() - start.time
            -- DistanceProvider caches by id, so give the two spots throwaway ids.
            local stamp = tostring(start.time)
            local dist = addon.TravelGraph.DistanceProvider(
                { id = "WT_A" .. stamp, mapID = start.mapID, x = start.x, y = start.y },
                { id = "WT_B" .. stamp, mapID = mapID, x = x, y = y })
            if not dist or dist <= 0 then say("couldn't measure the distance between the two spots"); return end

            say("%ds over %d yd straight-line at %.1f yd/s: path factor %.2f (maps %d -> %d)",
                elapsed, dist, start.speed, elapsed * start.speed / dist, start.mapID, mapID)
        else
            say("usage: /mzr walktime start | stop")
        end

    elseif cmd == "name" then
        -- /mzr name <nodeID> [nodeID...]: how each node resolves to a display name.
        for id in msg:gmatch("%S+") do
            if id ~= "name" then say("%s = %s", id, addon:GetNodeName(id)) end
        end

    elseif cmd == "hearth" then
        local bind = addon:GetBind()
        if bind then
            say("saved bind: map %s at (%s, %s), '%s'", tostring(bind.mapID),
                bind.x and ("%.3f"):format(bind.x) or "?", bind.y and ("%.3f"):format(bind.y) or "?", tostring(bind.name))
        else
            say("no saved bind (it's recorded when you bind at an inn); bind location text is '%s'",
                GetBindLocation and GetBindLocation() or "?")
        end
        local node = addon:GetBoundInnNode()
        say("hearthstone goes to: %s", node and (addon:GetNodeName(node) .. " (" .. node .. ")") or "unknown")

    elseif cmd == "speed" then
        local ctx = addon:GetPlayerContext()
        -- The client can name a spell whether or not you know it, which is how
        -- we check an ID points at the right spell without owning it.
        local function spellName(id)
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
            return info and info.name or "NO SUCH SPELL"
        end
        for _, skill in ipairs(addon.RidingSkills or {}) do
            say("riding %d '%s' (+%d%%): %s", skill.spellID, spellName(skill.spellID),
                skill.bonus * 100, ctx.knowsSpell(skill.spellID) and "known" or "not known")
        end
        for _, form in ipairs(addon.Abilities.GroundForms or {}) do
            say("form %d '%s' (+%d%%): %s", form.spellID, spellName(form.spellID),
                form.bonus * 100, ctx.knowsSpell(form.spellID) and "known" or "not known")
        end
        say("ground speed outdoors: %.1f yd/s (base %d)",
            addon:GetGroundSpeed("kalimdor.mulgore", ctx), addon.WALK_SPEED)

    else
        say("/mzr validate  - check the loaded data for broken references")
        say("/mzr world     - list the container tree")
        say("/mzr route <from> <to> [alliance|horde] - route between node ids")
        say("/mzr name <id> - the display name a node resolves to")
        say("/mzr walktime start|stop - time a walk to measure a path factor")
        say("/mzr hearth    - where your hearthstone goes")
        say("/mzr speed     - which riding/form spells are recognized, and your ground speed")
    end
end
