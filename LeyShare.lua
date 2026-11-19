local addonName, addon = ...

-- Ley line and elemental convergence sightings, shared with Skyborne Ley Line & Convergence Marker (SLLCM, the
-- player's other addon) on its hidden channel. When a Skyborne character's racial confirms a node, where it is and when
-- go out to everyone on the channel, so SLLCM users learn the location. No phases: WoW: Forever's 1.60.1 hotfix
-- obfuscates creature GUIDs, so the layer can't be compared between players any more (SLLCM 1.5.0 dropped them too).
-- Nothing heard is kept: Mapzeroth has no node list of its own, and the "Nearest Ley Line" / "Nearest Elemental
-- Convergence" picks need SLLCM loaded (the nodes come from its SLLCM_GetNodes).
--
-- SLLCM's Comm.lua is the reference; both addons must stay wire-compatible (protocol version "1"):
--   R:1:fac:phase:mapID:x:y:t          one sighting (x, y = map position x 10000, 0-9999; t = GetServerTime()).
--                                      phase is sent as 0: older clients still parse it, and never match it
-- fac is A or H. Everything else on the channel (older clients' Q / S, Skyborne Compass's XM / XS, SLLCM's F / L /
-- VQ / V) is only proof that the channel carries.
--
-- Rules: off until the player says yes (Options "shareSightings", asked once per account by UI/SharePrompt.lua);
-- Skyborne characters only; and when SLLCM itself is loaded, Mapzeroth sends nothing and joins nothing, so no sighting
-- goes out twice. Nothing here prints. Sightings come from the racial only. OnMinimapNode is for LeyScan.lua, which is
-- out of the .toc since 2026-11-16: Forever gives addons minimap tooltips as secret values, so it finds nothing. Kept in
-- case Blizzard reverts.

local LeyShare = {}
addon.LeyShare = LeyShare

local PREFIX = "SLLCM"
local CHANNEL_BASE = "SLLCMShare"    -- + A / H
local VERSION = "1"
local NO_PHASE = "0"                  -- the R's phase field, kept so older clients still parse it
local SAME_YARDS = 70                -- two places closer than this are the same node: the racial works from up to
                                     -- ~30 yd, so two casts at one node can be 60 yd apart
-- Forever's channel allowance is about 10 at once, then ~0.8 a second, and retrying while refused keeps it refusing.
local SEND_GAP = 1.25
local THROTTLE_PAUSE = 5
local CHANNEL_RETRIES = 3            -- InvalidChannel just after joining (the join not through yet): retry this often
local WHO_WAIT = 4                   -- a greyed-out channel: /chatwho it, and look again this many seconds later...
local FRESHEN_WAIT = 2               -- ...still listed: leave it, and join again this many seconds later...
local FRESHEN_QUICK, FRESHEN_QUICK_GAP = 2, 15   -- ...the first 2 a session at most 15 s apart...
local FRESHEN_GAP = 120              -- ...the rest at most this often...
local FRESHEN_MAX = 6                -- ...and this many a session
local PAUSE_SECONDS = 600            -- refused: nothing is sent this long, then the next message goes as a probe
local ECHO_SECONDS = 15              -- the server echoes our channel messages back: none this long after, it was dropped
local RECHECK_SECONDS = 3            -- after a notice that we may be out of the channel, look again this much later
local JOIN_GAP = 5                   -- a join is never sent again sooner than this (a notice and a rejoin racing)
local REJOIN_SECONDS = 60
local SETTLE_SECONDS, SETTLE_MAX = 3, 30
local REORDER_SECONDS = 60           -- after joining, game channels arriving above ours get moved below it this long
local MAX_SWAPS = 10                 -- channel swaps allowed per join (the game has about 10 channels)
-- The racials, and the buff each gives: 15 minutes standing on a node, 15-30 s anywhere else.
local RACIALS = { [1259705] = true, [1259686] = true }   -- Read Ley Line (Alliance), Skysight (Horde)
local BUFFS = { 1259691, 1270893 }                        -- Attuned (Alliance), Charged (Horde): 60 min
local MIN_BUFF = 60
local CHECK_TRIES, CHECK_GAP = 4, 0.5
-- A minimap blip isn't sent when we sent that node this recently: a scan passes the same node every 30 yards or
-- minute, and every R reaches the whole faction (SLLCM's scans use the same gap).
local MINIMAP_GAP = 10 * 60

local pending            -- a racial whose buff couldn't be read (combat): checked when combat ends
local recent = {}        -- our own sightings sent lately: { { mapID, x, y, t }, ... }, for OnMinimapNode
local queue, sending = {}, false
local channelRetries = 0 -- InvalidChannel retries spent on queue[1]
local pausedUntil        -- GetTime() until which nothing is sent: the server refused our messages on the channel
local awaitingEcho       -- GetTime() of the oldest send whose echo hasn't come back yet
local freshened, freshenedAt, freshening = 0, nil, nil    -- channel revives this session, the last one's time, one under way
local whoUntil           -- GetTime() until which a /chatwho answer about our channel is ours, kept out of chat
local lastJoinAt         -- GetTime() of the last join sent
local recheckPending     -- a channel notice's look again is due
local joinStarted
local reorderUntil       -- GetTime() until which our channel is kept numbered after the game's
local swapsLeft = 0      -- channel swaps still allowed in that time

-- nil for a secret value (encounters, combat) or a failed read.
local function clean(v)
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, v)
        if not ok or secret then return nil end
    end
    return v
end

local function isLoaded(name)
    local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return fn and fn(name) and true or false
end

-- SLLCM does the sharing itself when it is loaded.
function LeyShare:SllcmLoaded()
    for _, folder in ipairs(addon.SLLCM_FOLDERS) do
        if isLoaded(folder) then return true end
    end
    return false
end

local function skyborne()
    return addon.LeyLineSpell ~= nil and UnitRace ~= nil and select(2, UnitRace("player")) == "Skyborne"
end

local function factionTag()
    return UnitFactionGroup("player") == "Horde" and "H" or "A"
end

local function channelName()
    return CHANNEL_BASE .. factionTag()
end

-- Whether this character joins the channel, sends and receives.
function LeyShare:Networking()
    return addon.Options:Get("shareSightings") and skyborne() and not self:SllcmLoaded()
end


local function playerMap()
    return C_Map.GetBestMapForUnit("player")
end

---------------------------------------------------------------------------
-- Saved data from before phases went: per-phase sightings, "not there"s, Q times and the saved phase. Also the
-- sightings at places our data lacked, from before SLLCM_GetNodes.
---------------------------------------------------------------------------

local function forgetOld()
    local db = MapzerothRebuildDB
    if type(db) ~= "table" then return end
    db.sightings, db.sightingsGone, db.sightingQueries, db.sightingPhase, db.sharedNodes = nil, nil, nil, nil, nil
end

local function worldPos(mapID, x, y)
    local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if not ok or not pos then return nil end
    local wx, wy = pos:GetXY()
    return wx, wy, continent
end

-- A map's width and height in yards, nil when the client can't place it (LeyScan.lua). World axes are swapped
-- relative to the map's.
function LeyShare:ZoneSizeYards(mapID)
    local ax, ay = worldPos(mapID, 0, 0)
    local bx, by = worldPos(mapID, 1, 1)
    if not (ax and bx) then return nil end
    return math.abs(by - ay), math.abs(bx - ax)
end

local function yardsApart(ax, ay, ac, bx, by, bc)
    if not (ax and bx) or ac ~= bc then return nil end
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

local function near(mapID, x1, y1, x2, y2)
    local ax, ay, ac = worldPos(mapID, x1, y1)
    local bx, by, bc = worldPos(mapID, x2, y2)
    local d = yardsApart(ax, ay, ac, bx, by, bc)
    return d ~= nil and d < SAME_YARDS
end

---------------------------------------------------------------------------
-- Nodes: Mapzeroth has no list of its own. Skyborne Leyline & Convergence Marker's SLLCM_GetNodes gives every place it
-- knows (its data, self-found, and learned from sightings), so the "Nearest" pick is only offered while SLLCM is
-- loaded. A pick goes to the PLACE_COUNT nodes nearest the player on their continent. They are put in the graph only
-- when that pick is planned (Journey:ExtrasOf), and held on the pick's entry, so a plan and its replans keep to the same
-- ones (the picker builds a new entry each time it opens).
---------------------------------------------------------------------------

local PLACE_COUNT = 25
local placeByID = {}     -- every place made this session, by id (ids are the same for the same spot)

local function sllcmNodes()
    return type(SLLCM_GetNodes) == "function"
end

-- What the picker offers a Skyborne (Sections asks Relevance who is one): "route" with SLLCM loaded, "hint" without it
-- (the row offers its link instead) until the player dismisses that, else nil. forceHint: /mzr sllcm (MapzerothDataTools).
function LeyShare:PickMode()
    if sllcmNodes() and not self.forceHint then return "route" end
    if addon.Options:Get("hideSllcmHint") and not self.forceHint then return nil end
    return "hint"
end

local function placeAt(mapID, x, y)
    local tag = factionTag()
    local id = ("LEY_%s_%d_%d_%d"):format(tag, mapID, math.floor(x * 10000 + 0.5), math.floor(y * 10000 + 0.5))
    local place = placeByID[id]
    if not place then
        local kindKey = tag == "H" and "NODE_KIND_CONVERGENCE" or "NODE_KIND_LEYLINE"
        place = {
            id = id, mapID = mapID, x = x, y = y,
            leave = true,          -- somewhere to leave as well as reach (Journey:Build), for a round trip's way back
            name = addon.L[kindKey]:format(addon:GetZoneName(mapID) or ""),
        }
        placeByID[id] = place
    end
    return place
end

-- The places a pick can go to, chosen now: { { id, mapID, x, y, name, leave }, ... } (see above).
function LeyShare:NearbyPlaces()
    if not (skyborne() and sllcmNodes()) then return {} end
    local ok, byMap = pcall(SLLCM_GetNodes, factionTag() == "H" and "Horde" or "Alliance")
    if not ok or type(byMap) ~= "table" then return {} end
    local here = playerMap()
    local okPos, pos = pcall(C_Map.GetPlayerMapPosition, here or 0, "player")
    local px, py, pc
    if here and okPos and pos then px, py, pc = worldPos(here, pos.x, pos.y) end

    local nearby = {}
    if px then
        for mapID, list in pairs(byMap) do
            if type(mapID) == "number" and type(list) == "table" then
                for _, p in ipairs(list) do
                    local x, y = p[1], p[2]
                    if type(x) == "number" and type(y) == "number" then
                        local wx, wy, wc = worldPos(mapID, x, y)
                        if wx and wc == pc then
                            nearby[#nearby + 1] = { (wx - px) ^ 2 + (wy - py) ^ 2, mapID, x, y, wx, wy, wc }
                        end
                    end
                end
            end
        end
        table.sort(nearby, function(a, b) return a[1] < b[1] end)
    end

    local places, taken = {}, {}
    local function take(mapID, x, y, wx, wy, wc)
        if not wx then wx, wy, wc = worldPos(mapID, x, y) end
        if not wx then return end
        for _, w in ipairs(taken) do
            local d = yardsApart(wx, wy, wc, w[1], w[2], w[3])
            if d and d < SAME_YARDS then return end
        end
        taken[#taken + 1] = { wx, wy, wc }
        places[#places + 1] = placeAt(mapID, x, y)
    end
    for i = 1, math.min(PLACE_COUNT, #nearby) do
        local n = nearby[i]
        take(n[2], n[3], n[4], n[5], n[6], n[7])
    end
    return places
end

-- A pick's places, chosen the first time they are asked for and then kept on the entry (a round trip's copy shares them).
function LeyShare:PlacesFor(entry)
    if not entry.leyPlaces then entry.leyPlaces = self:NearbyPlaces() end
    return entry.leyPlaces
end

-- Their ids, for the pick's goals.
function LeyShare:PlaceIDs(entry)
    local ids = {}
    for _, place in ipairs(self:PlacesFor(entry)) do ids[#ids + 1] = place.id end
    return ids
end

function LeyShare:GetPlace(id)
    return placeByID[id]
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------

local function channelIndex()
    local id = GetChannelName(channelName())
    return type(id) == "number" and id > 0 and id or nil
end

-- A chat channel call made the way the game's own UI makes it (securecall: the chat system stays untainted), errors
-- caught. True if it ran.
local function chatCall(fn, ...)
    if type(fn) ~= "function" then return false end
    if type(securecall) == "function" then return (pcall(securecall, fn, ...)) end
    return (pcall(fn, ...))
end

-- The client's channel list as { name lowercased = disabled flag } (GetChannelList: id, name, disabled, ...).
local function channelList()
    local list, out = { pcall(GetChannelList) }, {}
    if not list[1] then return out end
    for i = 2, #list, 3 do
        local n = clean(list[i + 1])
        if type(n) == "string" then out[n:lower()] = clean(list[i + 2]) == true end
    end
    return out
end

-- Forever greys custom channels out: still listed and numbered, but the server refuses everything on it (sends answer
-- InvalidChannel, /leave NOT_ALLOWED_IN_CHANNEL, /chatwho INVALID_NAME). It's per channel, not custom channels as a
-- whole (SLLCM, 11 Nov 2026), and a /chatwho cleared it: the client dropped the channel, and a fresh join carried.
local function greyedOut()
    return channelList()[channelName():lower()] == true
end

local join -- (below, with the channel)

-- Revive the channel: /chatwho it, which on a greyed-out one makes the client drop it, then join fresh. Still listed
-- after that: leave it and join again. Rate-limited; true if it went out.
local function freshen(why)
    local now = GetTime()
    local gap = freshened < FRESHEN_QUICK and FRESHEN_QUICK_GAP or FRESHEN_GAP
    if freshened >= FRESHEN_MAX or (freshenedAt and now - freshenedAt < gap) then return false end
    freshened, freshenedAt, freshening = freshened + 1, now, true
    whoUntil = now + WHO_WAIT + 2
    chatCall(ListChannelByName, channelName())
    C_Timer.After(WHO_WAIT, function()
        freshening = nil
        if not LeyShare:Networking() then return end
        if not channelIndex() then
            join()
        elseif greyedOut() or why ~= "greyed out" then
            chatCall(LeaveChannelByName, channelName())
            C_Timer.After(FRESHEN_WAIT, function() join(true) end)
        end
    end)
    return true
end

local function paused()
    return pausedUntil ~= nil and GetTime() < pausedUntil
end

-- Forever's servers refuse addon messages on custom channels at times (since launch, 4 Nov 2026; other addons see it
-- too): a send returns Success, then NOT_ALLOWED_IN_CHANNEL comes, and no echo. Nothing client side changes that, so
-- nothing is sent for PAUSE_SECONDS and the next message after is the probe. Only a message heard on the channel (our
-- echo or anyone's) proves it carries again.
local function refused()
    awaitingEcho = nil
    pausedUntil = GetTime() + PAUSE_SECONDS
    wipe(queue)
end

-- Something came in on the channel: it carries.
function LeyShare:OnHeard()
    awaitingEcho, pausedUntil = nil, nil
end

local function drain()
    local msg, id = queue[1], channelIndex()
    if not msg or not id or not LeyShare:Networking() or paused() then
        sending = false
        return
    end
    local ok, r = pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "CHANNEL", id)
    -- Older clients return a boolean, newer ones Enum.SendAddonMessageResult (0 = success).
    if ok and (r == nil or r == true or r == 0) then
        table.remove(queue, 1)
        channelRetries = 0
        -- Taken, not delivered: wait for the echo.
        if not awaitingEcho then
            local sentAt = GetTime()
            awaitingEcho = sentAt
            C_Timer.After(ECHO_SECONDS, function()
                if awaitingEcho == sentAt then refused() end
            end)
        end
        C_Timer.After(SEND_GAP, drain)
    elseif ok and (r == 3 or r == 8) then          -- AddonMessageThrottle, ChannelThrottle: wait it out
        C_Timer.After(THROTTLE_PAUSE, drain)
    elseif ok and r == 7 and channelRetries < CHANNEL_RETRIES then     -- InvalidChannel: the join may not be through
        channelRetries = channelRetries + 1
        C_Timer.After(THROTTLE_PAUSE, drain)
    elseif ok and r == 7 and freshen(greyedOut() and "greyed out" or "refused") then
        -- The client still lists the channel, so joining again does nothing: revive it, then try this one again.
        channelRetries = 0
        C_Timer.After(WHO_WAIT + FRESHEN_WAIT + THROTTLE_PAUSE, drain)
    elseif ok and r == 7 then                       -- still invalid after reviving
        channelRetries, sending = 0, false
        refused()
    else
        table.remove(queue, 1)
        channelRetries = 0
        C_Timer.After(SEND_GAP, drain)
    end
end

local function send(msg)
    if not LeyShare:Networking() or paused() then return end
    queue[#queue + 1] = msg
    if not sending then
        sending = true
        drain()
    end
end

local function coord(v)
    return math.floor(v * 10000 + 0.5)
end

-- An own sighting, position and server time taken at the cast.
function LeyShare:OnConfirmed(mapID, x, y, t)
    if not (skyborne() and self:Networking()) then return end
    recent[#recent + 1] = { mapID, x, y, t }
    send(("R:%s:%s:%s:%d:%d:%d:%d"):format(VERSION, factionTag(), NO_PHASE, mapID, coord(x), coord(y), t))
end

-- A node blip found on the minimap (LeyScan.lua), which shows only while the node is up: sent like a racial's
-- sighting, unless we sent that node in the last MINIMAP_GAP seconds.
function LeyShare:OnMinimapNode(mapID, x, y)
    if not (self:Networking() and addon.Options:Get("detectMinimapNodes")) then return end
    local now = GetServerTime()
    for i = #recent, 1, -1 do
        local r = recent[i]
        if now - r[4] >= MINIMAP_GAP then
            table.remove(recent, i)
        elseif r[1] == mapID and near(mapID, r[2], r[3], x, y) then
            return
        end
    end
    self:OnConfirmed(mapID, x, y, now)
end

---------------------------------------------------------------------------
-- Detecting a confirmed node: the racial's buff lasts a minute or more only when cast on one.
---------------------------------------------------------------------------

local function hasNodeBuff(since)
    for _, id in ipairs(BUFFS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(id)
        if aura and aura.duration >= MIN_BUFF and aura.expirationTime - aura.duration >= since then return true end
    end
    return false
end

function LeyShare:OnRacialCast()
    if not self:Networking() then return end
    local mapID = playerMap()
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    local x, y = pos:GetXY()
    local castTime, serverTime, tries = GetTime() - 1, GetServerTime(), 0
    local function check()
        tries = tries + 1
        local ok, found = pcall(hasNodeBuff, castTime)
        if ok and found then
            LeyShare:OnConfirmed(mapID, x, y, serverTime)
        elseif ok and tries < CHECK_TRIES and not InCombatLockdown() then
            C_Timer.After(CHECK_GAP, check)
        elseif not ok or InCombatLockdown() then
            -- Auras are secret in combat: look again when it ends.
            pending = { mapID = mapID, x = x, y = y, castTime = castTime, serverTime = serverTime }
        end
    end
    C_Timer.After(0.2, check)
end

local function checkPending()
    local p = pending
    pending = nil
    if not p then return end
    local ok, found = pcall(hasNodeBuff, p.castTime)
    if ok and found then
        LeyShare:OnConfirmed(p.mapID, p.x, p.y, p.serverTime)
    elseif not ok then
        pending = p
    end
end


---------------------------------------------------------------------------
-- Channel
---------------------------------------------------------------------------

local function hideFromChat()
    local name = channelName()
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame and frame.RemoveChannel then
            chatCall(frame.RemoveChannel, frame, name)
        elseif frame and ChatFrame_RemoveChannel then
            chatCall(ChatFrame_RemoveChannel, frame, name)
        end
    end
end

-- Channel names shown in any chat window, lowercased.
local function shownChannels()
    local shown = {}
    if not GetChatWindowChannels then return shown end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local list = { GetChatWindowChannels(i) }      -- name, zone for each channel
        for j = 1, #list, 2 do
            if type(list[j]) == "string" then shown[list[j]:lower()] = true end
        end
    end
    return shown
end

-- The numbers of the channels people chat in, lowest first: the game's own (General, Trade, Services...) and custom
-- ones shown in a chat window. A custom channel shown nowhere is an addon's, as ours is: we never move one, so an
-- addon doing the same as us can't swap back and forth with ours.
local function chatChannelNumbers()
    local out = {}
    if not (GetNumDisplayChannels and GetChannelDisplayInfo) then return out end
    local shown = shownChannels()
    for i = 1, GetNumDisplayChannels() or 0 do
        local name, header, _, number, _, _, category = GetChannelDisplayInfo(i)
        local chat = category == "CHANNEL_CATEGORY_WORLD"
            or (category == "CHANNEL_CATEGORY_CUSTOM" and type(name) == "string" and shown[name:lower()])
        if not header and type(number) == "number" and number > 0 and chat then
            out[#out + 1] = number
        end
    end
    table.sort(out)
    return out
end

-- Move our channel past every chat channel numbered above it, one swap at a time, so General, Trade, a player's
-- guild-alliance channel and the rest keep /1, /2, /3. A new channel takes the lowest free number, so joining before
-- they come in (a slow login, a rejoin racing them after a loading screen) takes /1. Each swap moves ours up and a
-- chat channel down, so it stops; the budget is for an addon that rearranges channels itself, or one that leaves
-- its own channel showing in chat (it looks like a chat channel, and might move back past ours).
function LeyShare:KeepChannelLast()
    local swap = C_ChatInfo and C_ChatInfo.SwapChatChannelsByChannelIndex
    local ours = channelIndex()
    if not swap or not ours then return end
    for _, n in ipairs(chatChannelNumbers()) do
        if n > ours then
            if swapsLeft <= 0 or not chatCall(swap, ours, n) then return end
            swapsLeft = swapsLeft - 1
            ours = n
        end
    end
end

-- force: join even though the client lists the channel (just left it, and the client may not have caught up).
join = function(force)
    if not LeyShare:Networking() or clean(IsInInstance()) then return end
    if channelIndex() and not force then
        if greyedOut() then freshen("greyed out") end
        return
    end
    local now = GetTime()
    if lastJoinAt and now - lastJoinAt < JOIN_GAP then return end
    -- GetChannelName has missed a channel SLLCM was on and hearing (11 Nov 2026): trust the channel list too.
    if not force and channelList()[channelName():lower()] ~= nil then return end
    lastJoinAt = now
    reorderUntil, swapsLeft = now + REORDER_SECONDS, MAX_SWAPS
    chatCall(JoinTemporaryChannel, channelName())
    -- The chat frames pick the channel up a moment after joining.
    C_Timer.After(1, hideFromChat)
    C_Timer.After(5, hideFromChat)
end

-- The server's word on our channel. NOT_ALLOWED_IN_CHANNEL is it refusing a message we sent (see refused): rejoining
-- doesn't help. The rest mean we may be out of it, or in a greyed-out one: look again a moment later and rejoin, or
-- revive it. (Leaving it ourselves sends YOU_LEFT too: with sharing off, or the revive's join already sent, nothing
-- more happens.)
local RECHECK_NOTICES = { YOU_LEFT = true, INVALID_NAME = true, SUSPENDED = true, NOT_MEMBER = true }
function LeyShare:OnChannelNotice(notice)
    if not self:Networking() then return end
    if notice == "NOT_ALLOWED_IN_CHANNEL" then
        if not paused() then refused() end
        return
    end
    if not RECHECK_NOTICES[notice] or recheckPending then return end
    recheckPending = true
    C_Timer.After(RECHECK_SECONDS, function()
        recheckPending = nil
        if not LeyShare:Networking() then return end
        if not channelIndex() then
            join()
        elseif greyedOut() and not freshening then        -- a revive under way looks again itself
            freshen("greyed out")
        end
    end)
end

-- A revive's /chatwho is ours, not the player's: its answer about our channel (the member list, or "invalid channel
-- name") stays out of chat for a few seconds after it goes out. A /chatwho of their own later shows.
local function oursToHide(_, _, ...)
    if not (whoUntil and GetTime() < whoUntil) then return false end
    local base = clean(select(9, ...))
    return type(base) == "string" and base:lower() == channelName():lower()
end
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LIST", oursToHide)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE_USER", oursToHide)
end

-- Start once, the first time sharing is on for a Skyborne. At login the game's own channels (General, Trade...) come
-- in first: a new channel takes the lowest free number, and taking /1 would send a player's "/1 hello" into ours.
local function start(atLogin)
    if not LeyShare:Networking() then return end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
    if joinStarted then
        join()
        return
    end
    joinStarted = true
    local function begin()
        swapsLeft = MAX_SWAPS
        LeyShare:KeepChannelLast()                     -- still on it from before a /reload, perhaps as /1
        join()
        -- Rejoin if kicked, /left, or lost to a client hiccup. (Not NewTicker(..., join): the ticker is passed in, and
        -- join would take it as force.)
        C_Timer.NewTicker(REJOIN_SECONDS, function() join() end)
    end
    if not atLogin then
        begin()
        return
    end
    local started, changedAt, last = GetTime(), GetTime(), -1
    local ticker
    ticker = C_Timer.NewTicker(1, function()
        local now, count = GetTime(), select("#", GetChannelList())
        if count ~= last then last, changedAt = count, now end
        -- Quiet for a moment once the first channel is in: an empty list for a few seconds is the login, not settled.
        if (count > 0 and now - changedAt >= SETTLE_SECONDS) or now - started >= SETTLE_MAX then
            ticker:Cancel()
            begin()
        end
    end)
end

-- The player turned sharing on or off (the settings page or the first-run question).
function LeyShare:OnSettingChanged(on)
    addon.Options:Store("shareAsked", true)
    -- A fresh start either way: turning sharing back on is how a player says "try again now".
    pausedUntil, awaitingEcho, freshened, freshenedAt, freshening, lastJoinAt = nil, nil, 0, nil, nil, nil
    if on then
        start(false)
    else
        wipe(queue)
        if channelIndex() then chatCall(LeaveChannelByName, channelName()) end
    end
end

-- Whether to ask the player (once per account): a Skyborne, never asked, and SLLCM not doing it already.
function LeyShare:ShouldAsk()
    return skyborne() and not addon.Options:Get("shareAsked") and not self:SllcmLoaded()
end

-- How things stand, for the dev tools: whether we network, the channel, messages waiting to go.
function LeyShare:Stats()
    return { networking = self:Networking(), sllcm = self:SllcmLoaded(), channel = channelIndex(), queued = #queue,
             greyed = channelIndex() ~= nil and greyedOut(), paused = paused(), revives = freshened }
end

-- Tests only: forget everything held in memory, and allow this many channel swaps (none if omitted).
function LeyShare:ResetForTests(swaps)
    reorderUntil, swapsLeft = nil, swaps or 0
    pending = nil
    wipe(recent)
    wipe(queue)
    sending = false
    channelRetries, pausedUntil, awaitingEcho, whoUntil, lastJoinAt, recheckPending = 0, nil, nil, nil, nil, nil
    freshened, freshenedAt, freshening = 0, nil, nil
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("CHANNEL_UI_UPDATE")
events:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
events:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        if not LeyShare:Networking() then return end
        local prefix, _, kind = ...
        -- our echo or anyone's: the channel carries (nothing heard is kept)
        if clean(prefix) == PREFIX and clean(kind) == "CHANNEL" then LeyShare:OnHeard() end
    elseif event == "CHANNEL_UI_UPDATE" then             -- a channel joined or left (our own swaps fire it too)
        if reorderUntil and GetTime() < reorderUntil then LeyShare:KeepChannelLast() end
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_NOTICE_USER" then
        local notice, _, _, _, _, _, _, _, baseName = ...
        notice, baseName = clean(notice), clean(baseName)
        if type(baseName) == "string" and baseName:lower() == channelName():lower() then
            LeyShare:OnChannelNotice(notice)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if RACIALS[spellID] then LeyShare:OnRacialCast() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        checkPending()
    elseif event == "PLAYER_LOGIN" then
        forgetOld()
        addon.Options:OnChange(function(key, value)
            if key == "shareSightings" then LeyShare:OnSettingChanged(value) end
        end)
        start(true)
    end
end)
