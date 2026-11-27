-- Sharing ley line sightings with Skyborne Ley Line & Convergence Marker (LeyShare.lua): the wire format both addons
-- speak (no phases since WoW: Forever's 1.60.1 hotfix), the channel handling, and the nearest-ley-line pick.

useTestDistances()
addon.World:Build()

local LS = addon.LeyShare

-- A Skyborne Alliance character in Arathi, sharing on, on a client with the channel joined as /5.
local now, clock = 1800000000, 1000
function GetServerTime() return now end
function GetTime() return clock end
function UnitRace() return "Skyborne", "Skyborne", 99 end
function UnitFactionGroup() return "Alliance" end
function strsplit(sep, text, limit)
    local out, start = {}, 1
    while true do
        if limit and #out == limit - 1 then out[#out + 1] = text:sub(start) break end
        local i = text:find(sep, start, true)
        if not i then out[#out + 1] = text:sub(start) break end
        out[#out + 1] = text:sub(start, i - 1)
        start = i + 1
    end
    return unpack(out)
end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function IsInInstance() return false end
local loaded = {}
C_AddOns = { IsAddOnLoaded = function(name) return loaded[name] or false end }
local mapNow = 1417
C_Map = {
    GetMapInfo = function(id) return { name = "map " .. id } end,
    GetBestMapForUnit = function() return mapNow end,
    -- 2500 x 1700 yards a map, like useTestDistances; each map its own continent, so maps never meet.
    GetWorldPosFromMapPos = function(id, v) return id, CreateVector2D(v.x * 2500, v.y * 1700) end,
}
local timers, delays = {}, {}
C_Timer = { After = function(delay, fn) timers[#timers + 1] = fn; delays[#delays + 1] = delay end }
local function runTimers()
    for _ = 1, 50 do
        local list = timers
        timers = {}
        if #list == 0 then return end
        for _, fn in ipairs(list) do fn() end
    end
end
local sent = {}
local echo = true          -- the server echoes what we send back (false: it drops it)
C_ChatInfo = { SendAddonMessage = function(prefix, msg, kind, id)
    check(prefix == "SLLCM" and kind == "CHANNEL" and id == 5, "sent on SLLCM's prefix to the channel")
    sent[#sent + 1] = msg
    if echo then C_Timer.After(0.3, function() addon.LeyShare:OnHeard() end) end
    return 0
end }
function GetChannelName(name) return name == "SLLCMShareA" and 5 or 0 end
MapzerothRebuildDB = {}
addon.Options:Set("shareSightings", true)

local function reset()
    LS:ResetForTests()
    sent, timers, delays = {}, {}, {}
end

check(LS:Networking(), "a Skyborne with sharing on joins in")
UnitRace = function() return "Human", "Human", 1 end
check(not LS:Networking(), "anyone else doesn't")
UnitRace = function() return "Skyborne", "Skyborne", 99 end
addon.Options:Set("shareSightings", false)
check(not LS:Networking(), "nor with sharing off")
addon.Options:Set("shareSightings", true)

-- Our own find goes out at once, phase 0 (no phases since Forever's 1.60.1 hotfix), with the cast's time.
reset()
LS:OnConfirmed(1417, 0.48, 0.605, now - 3)
check(sent[1] == "R:1:A:0:1417:4800:6050:" .. (now - 3), "an own find goes out at once, phase 0: " .. tostring(sent[1]))
LS:OnConfirmed(1417, 0.2, 0.2, now)
runTimers()
check(sent[2] == "R:1:A:0:1417:2000:2000:" .. now, "and the next, 1.25 s later")
check(MapzerothRebuildDB.sightings == nil, "nothing is kept")

-- A minimap blip (LeyScan.lua) isn't sent again for 10 minutes once we sent that node.
reset()
addon.Options:Set("detectMinimapNodes", true)
LS:OnMinimapNode(1417, 0.48, 0.605)
LS:OnMinimapNode(1417, 0.481, 0.606)
runTimers()
check(#sent == 1, "a blip sent once, not again within 10 min: " .. #sent)
now = now + 601
LS:OnMinimapNode(1417, 0.48, 0.605)
runTimers()
check(#sent == 2, "and again after: " .. #sent)
now = now - 601

-- What others send is not kept, and a Q is never answered.
reset()
local function r(x, y, t) return ("R:1:A:3104:1417:%d:%d:%d"):format(x, y, t) end
check(LS.OnMessage == nil, "no message handler: nothing heard is kept")
LS:OnHeard()
runTimers()
check(#sent == 0 and MapzerothRebuildDB.sightings == nil, "hearing the channel sends nothing")

-- The pick's places come from SLLCM (SLLCM_GetNodes): two in Arathi. It goes to the nearest.
local sllcmNodes = { [1417] = { { 0.253, 0.300 }, { 0.480, 0.605 } } }
local askedFaction
function SLLCM_GetNodes(faction)
    askedFaction = faction
    local out = {}
    for mapID, list in pairs(sllcmNodes) do
        out[mapID] = {}
        for i, q in ipairs(list) do out[mapID][i] = { q[1], q[2] } end
    end
    return out
end
C_Spell = { GetSpellInfo = function(id) return { name = "Profession " .. id } end }   -- a route's steps may name a trainer
C_TaxiMap = C_TaxiMap or { GetTaxiNodesForMap = function() return {} end }            -- or a flight master
local playerAt = { 0.47, 0.60 }
C_Map.GetPlayerMapPosition = function() return CreateVector2D(playerAt[1], playerAt[2]) end
local WEST, CLOSE = "LEY_A_1417_2530_3000", "LEY_A_1417_4800_6050"
local J = addon.Journey
local pick = { name = "Nearest Ley Line", pick = true, group = "leyline", nodeIDs = {} }
local both = LS:PlaceIDs(pick)
check(#both == 2 and both[1] == CLOSE and both[2] == WEST and askedFaction == "Alliance",
    "the pick's places are SLLCM's nodes for our faction, nearest first: " .. table.concat(both, " "))
check(LS:GetPlace(WEST).name == "map 1417 Ley Line", "named like a ley line")
local session = J:Build(makeCtx({ faction = "Alliance" }), { id = "YOU_ley", mapID = 1417, x = 0.47, y = 0.60 }, J:ExtrasOf(pick))
local plan = J:PlanEntry(session, pick)
check(plan and plan.goal == CLOSE, "the route goes to the nearest: " .. tostring(plan and plan.goal))
check(plan.steps[#plan.steps].text:find("map 1417 Ley Line", 1, true), "and the step names it: " .. plan.steps[#plan.steps].text)
local round, trip = J:PlanRoundTrip(session, pick)
check(round and round.goal == CLOSE and trip.placeChosen, "a round trip too, and keeps to it")
check(#J:ExtrasOf(trip) == 2, "the chosen trip still carries the pick's places, for planning again part way")

-- The places: SLLCM's 25 nodes nearest the player on their continent, chosen once for a pick.
reset()
local savedNodes = sllcmNodes
sllcmNodes = { [1417] = {}, [1418] = { { 0.5, 0.5 } } }      -- 1418 is another continent (each test map is one)
for i = 1, 30 do sllcmNodes[1417][i] = { 0.02 + i * 0.03, 0.60 } end   -- 75 yards apart, along the player's row
local places = LS:NearbyPlaces()
local onOther, farthest = false, 0
for _, place in ipairs(places) do
    if place.mapID ~= 1417 then onOther = true end
    farthest = math.max(farthest, math.abs(place.x - 0.47))
end
check(#places == 25 and not onOther, "the 25 nearest on the player's continent: " .. #places)
check(farthest < 0.40, "and not the farthest five: " .. farthest)
local pick2 = { name = "Nearest Ley Line", pick = true, group = "leyline", nodeIDs = {} }
local kept = LS:PlacesFor(pick2)
playerAt = { 0.9, 0.9 }
check(LS:PlacesFor(pick2) == kept and #LS:PlaceIDs(pick2) == 25, "a pick keeps the places it was given")
playerAt = { 0.47, 0.60 }
sllcmNodes = savedNodes
UnitFactionGroup = function() return "Horde" end
check(LS:NearbyPlaces()[1].id:find("^LEY_H_") and askedFaction == "Horde", "a Horde player asks for and gets convergences")
UnitFactionGroup = function() return "Alliance" end
-- What the picker offers.
check(LS:PickMode() == "route", "a Skyborne with SLLCM: the pick")
local getNodes = SLLCM_GetNodes
SLLCM_GetNodes = nil
check(LS:PickMode() == "hint" and #LS:NearbyPlaces() == 0, "without it: the row pointing to SLLCM, and no places")
addon.Options:Set("hideSllcmHint", true)
check(LS:PickMode() == nil, "nothing once that's dismissed")
LS.forceHint = true
check(LS:PickMode() == "hint", "unless /mzr sllcm asks for it")
LS.forceHint = nil
addon.Options:Set("hideSllcmHint", false)
SLLCM_GetNodes = getNodes
UnitRace = function() return "Human", "Human", 1 end
check(#LS:NearbyPlaces() == 0, "anyone not Skyborne: no places")
UnitRace = function() return "Skyborne", "Skyborne", 99 end

-- Throttled: the message waits and goes again.
reset()
local refuse = 1
local realSend = C_ChatInfo.SendAddonMessage
C_ChatInfo.SendAddonMessage = function(...)
    if refuse > 0 then refuse = refuse - 1 return 8 end
    return realSend(...)
end
LS:OnConfirmed(1417, 0.3, 0.3, now)
check(#sent == 0, "refused by the channel throttle")
runTimers()
check(#sent == 1 and sent[1]:find("^R:"), "sent after the pause")

-- InvalidChannel just after joining: retried; still invalid, the channel is revived (/chatwho, then a fresh join).
reset()
refuse = 4
local listed, joins = 0, 0
function ListChannelByName() listed = listed + 1 end
function JoinTemporaryChannel() joins = joins + 1 end
C_ChatInfo.SendAddonMessage = function(...)
    if refuse > 0 then refuse = refuse - 1 return 7 end
    return realSend(...)
end
LS:OnConfirmed(1417, 0.3, 0.3, now)
runTimers()
check(listed == 1 and #sent == 1 and sent[1]:find("^R:"), "three retries, a revive, then it goes: " .. listed .. " " .. #sent)
C_ChatInfo.SendAddonMessage = realSend
ListChannelByName, JoinTemporaryChannel = nil, nil

-- A greyed-out channel (full, it seems: ~200 members): on to SLLCMShareA2 at once, then A3 and A4; from the last back
-- to the first at the revive pace. The one left behind is /chatwho'd, which makes the client drop it.
local chans, full, joinedNames = {}, {}, {}      -- the client's list (name = greyed out), the channels that are full
local function overflow(fullOnes)
    reset()
    chans, full, joinedNames = { SLLCMShareA = true }, {}, {}
    for _, name in ipairs(fullOnes) do full[name] = true end
end
local savedChannelName = GetChannelName
function GetChannelName(name) return chans[name] ~= nil and 5 or 0 end
function GetChannelList()
    local out = {}
    for name, grey in pairs(chans) do out[#out + 1] = 5; out[#out + 1] = name; out[#out + 1] = grey end
    return unpack(out)
end
function ListChannelByName(name) if chans[name] then chans[name] = nil end end
function JoinTemporaryChannel(name) joinedNames[#joinedNames + 1] = name; chans[name] = full[name] or false end
overflow({ "SLLCMShareA", "SLLCMShareA2" })
LS:OnChannelNotice("SUSPENDED")
runTimers()
check(LS:Stats().channelName == "SLLCMShareA3" and table.concat(joinedNames, " ") == "SLLCMShareA2 SLLCMShareA3"
    and chans.SLLCMShareA == nil and chans.SLLCMShareA2 == nil,
    "greyed out: on through the full ones to A3, the greyed ones dropped: " .. table.concat(joinedNames, " "))
LS:OnConfirmed(1417, 0.3, 0.3, now)
runTimers()
check(#sent == 1, "and sends there")
overflow({ "SLLCMShareA", "SLLCMShareA2", "SLLCMShareA3", "SLLCMShareA4" })
LS:OnChannelNotice("SUSPENDED")
runTimers()
check(table.concat(joinedNames, " ") == "SLLCMShareA2 SLLCMShareA3 SLLCMShareA4 SLLCMShareA SLLCMShareA2 SLLCMShareA3 SLLCMShareA4",
    "all full: back to the first once, then it waits for the revive pace: " .. table.concat(joinedNames, " "))
full.SLLCMShareA = nil
clock = clock + 16
LS:OnChannelNotice("SUSPENDED")
runTimers()
check(LS:Stats().channelName == "SLLCMShareA" and chans.SLLCMShareA == false, "later, the first lets us in again")
clock = clock - 16
-- A channel joined a moment ago shows greyed out until the server answers (SLLCM 1.6.1): not taken for full then.
overflow({})
chans = {}
LS:OnChannelNotice("YOU_LEFT")
timers[#timers]()                                    -- the recheck: not in the channel, so it joins
check(table.concat(joinedNames, " ") == "SLLCMShareA", "joined the first: " .. table.concat(joinedNames, " "))
chans.SLLCMShareA = true                             -- the server hasn't answered yet
LS:OnChannelNotice("SUSPENDED")
timers[#timers]()                                    -- a recheck 3 s on, inside the 5 s
check(LS:Stats().channelName == "SLLCMShareA" and #joinedNames == 1, "a fresh join isn't judged while it settles")
chans.SLLCMShareA = false                            -- the server lets us in
runTimers()
check(LS:Stats().channelName == "SLLCMShareA" and #joinedNames == 1, "and stays once it has: " .. table.concat(joinedNames, " "))
GetChannelName, GetChannelList, ListChannelByName, JoinTemporaryChannel = savedChannelName, nil, nil, nil
LS:ResetForTests()

-- Forever's refusal: no echo within 15 s, or NOT_ALLOWED_IN_CHANNEL, pauses sending for 10 minutes; then the next
-- message is the probe, and anything heard on the channel ends the pause.
reset()
sent, echo = {}, false
LS:OnConfirmed(1417, 0.3, 0.3, now)
runTimers()
check(LS:Stats().paused, "no echo: paused")
check(LS:Stats().held == 1, "the unheard sighting is held: " .. LS:Stats().held)
LS:OnConfirmed(1417, 0.4, 0.4, now)
runTimers()
check(#sent == 1 and LS:Stats().held == 2, "nothing goes while paused; that one is held too")
clock = clock + 601
LS:OnConfirmed(1417, 0.5, 0.5, now)
check(#sent == 2 and sent[2] == "R:1:A:0:1417:3000:3000:" .. now,
    "ten minutes on, the held ones go first, the oldest as the probe: " .. tostring(sent[2]))
check(LS:Stats().held == 0, "none held once they're on their way")
echo = true
LS:OnHeard()
check(not LS:Stats().paused, "heard: not paused")
LS:OnChannelNotice("NOT_ALLOWED_IN_CHANNEL")
check(LS:Stats().paused, "the server's refusal notice pauses too")
LS:OnHeard()
runTimers()
clock = clock - 601

-- A held sighting too old for receivers (90 min) by the time the channel carries is dropped; turning sharing off
-- forgets the rest.
reset()
sent, echo = {}, false
LS:OnConfirmed(1417, 0.3, 0.3, now - 90 * 60 + 30)
runTimers()
check(LS:Stats().paused and LS:Stats().held == 1, "an old one held")
clock = clock + 601
echo = true
LS:OnConfirmed(1417, 0.6, 0.6, now)
runTimers()
check(#sent == 2 and sent[2] == "R:1:A:0:1417:6000:6000:" .. now, "the old one is dropped, the new one goes: " .. #sent)
echo = false
LS:OnChannelNotice("NOT_ALLOWED_IN_CHANNEL")
LS:OnConfirmed(1417, 0.7, 0.7, now)
check(LS:Stats().held >= 1, "held while paused")
addon.Options:Set("shareSightings", false)
LS:OnSettingChanged(false)
check(LS:Stats().held == 0, "sharing off forgets them")
addon.Options:Set("shareSightings", true)
echo = true
LS:ResetForTests()
clock = clock - 601

-- With SLLCM loaded, Mapzeroth sends nothing: SLLCM does the sharing.
reset()
loaded.SkyborneLeyLineConvergenceMarker = true
check(not LS:Networking() and LS:SllcmLoaded(), "SLLCM loaded: Mapzeroth stays off the channel")
LS:OnConfirmed(1417, 0.3, 0.3, now)
check(#sent == 0, "and sends nothing")
check(not LS:ShouldAsk(), "and Mapzeroth doesn't ask: SLLCM asks its own question")
loaded.SkyborneLeyLineConvergenceMarker = nil

-- The question is asked once per account, of Skyborne only; either answer settles it.
addon.Options:Set("shareSightings", false)
addon.Options:Set("shareAsked", false)
check(LS:ShouldAsk(), "a Skyborne who was never asked is asked")
UnitRace = function() return "Human", "Human", 1 end
check(not LS:ShouldAsk(), "nobody else is")
UnitRace = function() return "Skyborne", "Skyborne", 99 end
addon.SharePrompt:Answer(false)
check(not LS:ShouldAsk() and not addon.Options:Get("shareSightings"), "Leave Off: asked no more, still off")

-- Channel numbers: joined ahead of the channels people chat in (the game's, and custom ones shown in a chat window),
-- ours moves past them. Another addon's channel (hidden from chat) is never touched, so one doing the same as us
-- can't swap back and forth with ours.
local slots = { [1] = "SLLCMShareA", [2] = "General", [3] = "OtherAddon", [4] = "GuildChat", [5] = "Trade" }
local custom = { SLLCMShareA = true, OtherAddon = true, GuildChat = true }
function GetChatWindowChannels(i)
    if i == 1 then return "General", 1, "Trade", 2, "guildchat", 0 end
end
local savedName, savedChat = GetChannelName, C_ChatInfo
local swaps = 0
function GetNumDisplayChannels() return 11 end           -- a header, then a row for each of the 10 numbers
function GetChannelDisplayInfo(i)
    if i == 1 then return "World", true end
    local n, name = i - 1, slots[i - 1]
    if not name then return nil, false, false, nil end
    return name, false, false, n, 0, true, custom[name] and "CHANNEL_CATEGORY_CUSTOM" or "CHANNEL_CATEGORY_WORLD"
end
function GetChannelName(name)
    for n, v in pairs(slots) do if v == name then return n end end
    return 0
end
C_ChatInfo = { SwapChatChannelsByChannelIndex = function(a, b)
    slots[a], slots[b] = slots[b], slots[a]
    swaps = swaps + 1
end }
LS:ResetForTests()
LS:KeepChannelLast()
check(swaps == 0, "no swaps outside a join's allowance")
LS:ResetForTests(10)
LS:KeepChannelLast()
check(slots[1] == "General" and slots[2] == "GuildChat" and slots[3] == "OtherAddon" and slots[4] == "Trade"
    and slots[5] == "SLLCMShareA", "ours goes past the game's channels and the shown one; the other addon's stays /3: "
    .. tostring(slots[1]) .. " " .. tostring(slots[2]) .. " " .. tostring(slots[3]) .. " " .. tostring(slots[5]))
swaps = 0
LS:KeepChannelLast()
check(swaps == 0, "already past them: nothing moves")
slots = { [1] = "SLLCMShareA", [2] = "General", [3] = "Trade" }
LS:ResetForTests(1)
LS:KeepChannelLast()
check(slots[1] == "General" and slots[2] == "SLLCMShareA", "the allowance runs out, and it stops")
C_ChatInfo = {}
slots = { [1] = "SLLCMShareA", [2] = "General" }
LS:ResetForTests(10)
LS:KeepChannelLast()
check(slots[1] == "SLLCMShareA", "a client without the swap is left alone")
GetChannelName, C_ChatInfo, GetNumDisplayChannels, GetChannelDisplayInfo, GetChatWindowChannels =
    savedName, savedChat, nil, nil, nil
