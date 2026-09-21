local addonName, addon = ...

local PREFIX = "|cff66ccff[Mapzeroth]|r"

local function say(fmt, ...)
    print(PREFIX .. " " .. fmt:format(...))
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("HEARTHSTONE_BOUND")
frame:RegisterEvent("TAXIMAP_OPENED")
frame:RegisterEvent("UI_INFO_MESSAGE")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        -- The world map may load after us; attach the panel when it does.
        if (...) == "Blizzard_WorldMap" then addon.Panel:Init() end
        return
    elseif event == "TAXIMAP_OPENED" then
        addon.FlightKnowledge:OnTaxiMapOpened()
        return
    elseif event == "UI_INFO_MESSAGE" then
        -- "New flight path discovered": we aren't told which, so forget the "not found"s.
        local _, message = ...
        if ERR_NEWTAXIPATH and message == ERR_NEWTAXIPATH then
            addon.FlightKnowledge:ForgetNotFound()
        end
        return
    end
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
    addon.FlightKnowledge:Load()
    addon.Theme:Init("moderndark")
    addon.OptionsPanel:Register()
    addon.Panel:Init()
    -- Which flight was chosen: the navigator wants to know where it goes (a post-hook: it changes nothing).
    if type(TakeTaxiNode) == "function" and not addon.takeTaxiHooked then
        addon.takeTaxiHooked = true
        hooksecurefunc("TakeTaxiNode", function(slot)
            local stops = addon.FlightKnowledge:StopsForSlot(slot)
            addon.lastTicket = { slot = slot, stops = stops, at = GetTime() }      -- for /mzr ticket
            addon.Navigation:OnTakeTaxi(stops, GetTime())
        end)
    end
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

    elseif cmd == "flights" then
        -- Which flight points we know this character has (not) found; open a flight
        -- master's window to add to it.
        local yes, no = addon.FlightKnowledge:List()
        local function names(list)
            local out = {}
            for i, id in ipairs(list) do out[i] = addon:GetNodeName(id) or id end
            return #out > 0 and table.concat(out, "; ") or "none"
        end
        say("found (%d): %s", #yes, names(yes))
        say("not found (%d): %s", #no, names(no))
        if #yes == 0 then
            say("nothing learned yet. Open a flight master's window and Mapzeroth will read it; until then routes use no flights (or add allflights to /mzr route).")
        end

    elseif cmd == "timings" then
        -- Flights and boat rides timed while following trips this session, against the data.
        local list = addon.Navigation:Timings()
        if #list == 0 then say("nothing timed yet: follow a trip with a flight or boat and it is measured") end
        for _, t in ipairs(list) do
            say("%s %s -> %s: measured %ds, data %ds (%+d)", t.kind, addon:GetNodeName(t.from), addon:GetNodeName(t.to),
                t.actual, t.planned, t.actual - t.planned)
        end

    elseif cmd == "fares" then
        -- What routes assume about money: how much the player has, and the discount learned from the
        -- flight window's prices (1 until a flight master's window has been opened).
        say("money %s, typical fare factor %.3f (%s)", addon.Journey:FormatMoney(GetMoney and GetMoney() or 0),
            addon.FlightKnowledge:FareFactor(), TaxiNodeCost and "prices readable" or "TaxiNodeCost missing")
        local samples = addon.FlightKnowledge:FareSamples()
        if #samples == 0 then
            say("no prices read yet: open a flight master's window")
        end
        for _, sample in ipairs(samples) do
            say("  to %s: paid %d, base %d (%.3f)", addon:GetNodeName(sample.to), sample.paid, sample.base, sample.paid / sample.base)
        end

    elseif cmd == "ticket" then
        -- The last flight chosen, as the hook saw it, and what the trip made of it.
        local t = addon.lastTicket
        if not t then
            say("no flight chosen yet this session (or the TakeTaxiNode hook isn't firing)")
        else
            local names = {}
            for _, id in ipairs(t.stops or {}) do names[#names + 1] = addon:GetNodeName(id) end
            say("slot %s, %.0fs ago: %s", tostring(t.slot), GetTime() - t.at,
                #names > 0 and table.concat(names, " > ") or "stops unreadable")
        end
        local model = addon.Navigation:Model()
        say("trip: %s", model and (model.offRoute and ("off route, flying to " .. addon:GetNodeName(model.flyingTo))
            or model.finished and "arrived" or ("step %d of %d"):format(model.index, model.total)) or "none")

    elseif cmd == "nav" then
        -- /mzr nav [stop]: where the trip being followed is, or drop it.
        if msg:match("^nav%s+stop") then
            addon.Navigator:Stop()
            say("trip stopped")
        else
            local model = addon.Navigation:Model()
            say("%s", model and (model.finished and "arrived" or ("step %d of %d"):format(model.index, model.total)) or "no trip")
        end

    elseif cmd == "ui" then
        say("panel %s", addon.Panel:Toggle() and "shown" or "hidden")

    elseif cmd == "theme" then
        -- /mzr theme [id]: switch theme (no id cycles). Ids: classic, moderndark.
        local id = msg:match("^theme%s+(%S+)")
        if id then
            if not addon.Theme:Set(id) then say("unknown theme '%s'", id) end
        else
            addon.Theme:Cycle()
        end
        say("theme: %s", addon.Theme:Current().id)

    elseif cmd == "settings" then
        if not addon.OptionsPanel:Open() then say("the game's settings window isn't available here") end

    elseif cmd == "dist" then
        -- /mzr dist <nodeA> <nodeB>: straight-line yards between two nodes as the graph measures
        -- them, and each node's world position. Used to check that a city's own map and its
        -- zone's map line up (two ends of the same gate should be close).
        local a, b = msg:match("^dist%s+(%S+)%s+(%S+)")
        local nodeA, nodeB = a and addon.World:GetNode(a), b and addon.World:GetNode(b)
        if not (nodeA and nodeB) then
            say("usage: /mzr dist <nodeA> <nodeB> (node ids such as ENTRANCE_C1455_145_861)")
            return
        end
        local function world(node)
            local _, pos = C_Map.GetWorldPosFromMapPos(node.mapID, CreateVector2D(node.x, node.y))
            if not pos then return "?" end
            local x, y = pos:GetXY()
            return ("%.0f, %.0f"):format(x, y)
        end
        local dist = addon.TravelGraph.DistanceProvider(nodeA, nodeB)
        say("%s (map %d) world %s | %s (map %d) world %s | %s yd", a, nodeA.mapID, world(nodeA),
            b, nodeB.mapID, world(nodeB), dist and ("%.0f"):format(dist) or "?")

    elseif cmd == "world" then
        addon.World:ForEachContainer(function(c)
            say("%s%s  (%d nodes)", ("  "):rep(c.depth - 1), c.path, #c.nodes)
        end)

    elseif cmd == "route" then
        -- /mzr route <fromNodeID> <toNodeID> [alliance|horde] [allflights]
        -- Flights are only used into points a flight master's window has confirmed found;
        -- allflights ignores that.
        local from, to, rest = msg:match("^route%s+(%S+)%s+(%S+)%s*(.*)")
        if not from then
            say("usage: /mzr route <fromNodeID> <toNodeID> [alliance|horde] [allflights]")
            return
        end
        local faction = rest:match("alliance") or rest:match("horde") or ""
        local allFlights = rest:find("allflights") ~= nil
        if not addon.World:GetNode(from) or not addon.World:GetNode(to) then
            say("unknown node id (use ids like TAXI_2 or DOCK_STORMWIND)")
            return
        end
        local ctx = addon:GetPlayerContext()
        if faction:lower() == "alliance" then ctx.faction = "Alliance"
        elseif faction:lower() == "horde" then ctx.faction = "Horde" end
        if allFlights then ctx.flightNodeFound = nil end

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
