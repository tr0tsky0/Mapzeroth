-- Sharing ley line sightings with Skyborne Ley Line & Convergence Marker (LeyShare.lua): the wire format both addons
-- speak, phase reading, and the nearest-ley-line pick going to a node seen up in the player's phase.

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
    MapzerothRebuildDB.sightings, MapzerothRebuildDB.sightingsGone = nil, nil
    MapzerothRebuildDB.sightingQueries = nil
    sent, timers, delays = {}, {}, {}
end

-- A sighting held in Arathi (another phase): a Q goes out only for a zone with one.
local function holdOne()
    MapzerothRebuildDB.sightings = { A = { [1417] = { { phase = "1", x = 0.1, y = 0.1, t = now } } } }
end

check(LS:Networking(), "a Skyborne with sharing on joins in")
UnitRace = function() return "Human", "Human", 1 end
check(not LS:Networking(), "anyone else doesn't")
UnitRace = function() return "Skyborne", "Skyborne", 99 end
addon.Options:Set("shareSightings", false)
check(not LS:Networking(), "nor with sharing off")
addon.Options:Set("shareSightings", true)

-- Phase: the first creature read is used at once; a second kind agreeing confirms it; then a new phase needs two
-- kinds of NPC agreeing; players and pets don't count.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
check(LS:Phase() == "3104" and #sent == 0, "no Q in a zone where nothing has been seen (no node list of our own)")
reset()
holdOne()
LS:ReadGUID("Player-1-0ABC")
check(LS:Phase() == nil, "a player's GUID says nothing")
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
local p, tentative = LS:Phase()
check(p == "3104" and tentative, "the first creature gives the phase, tentatively")
check(#sent == 1 and sent[1] == "Q:1:A:3104", "and it asks what's known there (a sighting is held in Arathi): " .. tostring(sent[1]))
LS:ReadGUID("Creature-0-1-2-3104-5678-0002")
p, tentative = LS:Phase()
check(p == "3104" and not tentative, "a second kind agreeing confirms it")
LS:ReadGUID("Creature-0-1-2-4200-1111-0003")
LS:ReadGUID("Creature-0-1-2-4200-1111-0004")
check(LS:Phase() == "3104", "one kind of NPC elsewhere isn't enough to move a confirmed phase")
LS:ReadGUID("Vehicle-0-1-2-4200-2222-0005")
check(LS:Phase() == "4200", "two kinds are")
clock = clock + 5
LS:ReadGUID("Creature-0-1-2-3104-1234-0006")
LS:ReadGUID("Creature-0-1-2-3104-5678-0007")
runTimers()
check(LS:Phase() == "3104" and #sent == 2, "messages go out 1.25 s apart; a phase is asked about once a session: " .. #sent)

-- Receiving: R, the same node again (newer kept), a stale one, one from the future, the other faction, a bad version.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
local function r(x, y, t, fac, v)
    return ("R:%s:%s:3104:1417:%d:%d:%d"):format(v or "1", fac or "A", x, y, t)
end
LS:OnMessage(r(2530, 3000, now - 600))
LS:OnMessage(r(2540, 3010, now - 60))            -- 25 x 17 yards off: the same node
LS:OnMessage(r(4800, 6050, now - 5500))          -- older than 90 minutes
LS:OnMessage(r(4800, 6050, now + 120))           -- two minutes in the future
LS:OnMessage(r(4800, 6050, now, "H"))
LS:OnMessage(r(4800, 6050, now, "A", "2"))
local held = MapzerothRebuildDB.sightings.A[1417]
check(#held == 1 and held[1].t == now - 60, "one sighting kept, the newer of the two: " .. #held)
check(math.abs(held[1].x - 0.254) < 1e-9, "at the newer position")

-- Step two: the pick's places come from SLLCM (SLLCM_GetNodes): two in Arathi. It goes to the node seen up, not the
-- nearer one that wasn't.
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
local playerAt = { 0.47, 0.60 }
C_Map.GetPlayerMapPosition = function() return CreateVector2D(playerAt[1], playerAt[2]) end
local WEST, CLOSE = "LEY_A_1417_2530_3000", "LEY_A_1417_4800_6050"
local J = addon.Journey
local pick = { name = "Nearest Ley Line", pick = true, group = "leyline", nodeIDs = {} }
local both = LS:PlaceIDs(pick)
check(#both == 2 and both[1] == CLOSE and both[2] == WEST and askedFaction == "Alliance",
    "the pick's places are SLLCM's nodes for our faction, nearest first: " .. table.concat(both, " "))
check(LS:GetPlace(WEST).name == "map 1417 Ley Line", "named like a ley line")
local seen, count = LS:SeenAmong(both)
check(count == 1 and seen[WEST] == 60, "SeenAmong finds the sighted node and its age")
local session = J:Build(makeCtx({ faction = "Alliance" }), { id = "YOU_ley", mapID = 1417, x = 0.47, y = 0.60 }, J:ExtrasOf(pick))
local plan = J:PlanEntry(session, pick)
check(plan and plan.goal == WEST and plan.seenAge == 60, "the route goes to the one seen: " .. tostring(plan and plan.goal))
check(plan.steps[#plan.steps].text:find("map 1417 Ley Line", 1, true), "and the step names it: " .. plan.steps[#plan.steps].text)
local round, trip = J:PlanRoundTrip(session, pick)
check(round and round.goal == WEST and round.seenAge == 60 and trip.placeChosen, "a round trip too, and keeps to it")
check(#J:ExtrasOf(trip) == 2, "the chosen trip still carries the pick's places, for planning again part way")
LS:ReadGUID("Creature-0-1-2-9999-1-1")
LS:ReadGUID("Creature-0-1-2-9999-2-1")
plan = J:PlanEntry(session, pick)
check(plan.goal == CLOSE and plan.seenAge == nil, "in another phase, the nearest of them all")

-- "Not there" (Skyborne Compass's XM / XS): per node and phase the newest report wins, and the pick skips a node
-- reported not there in the player's phase.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
runTimers()
sent = {}
local function xm(x, y, t) return ("XM:1:A:3104:1417:%d:%d:%d"):format(x, y, t) end
LS:OnMessage(xm(4800, 6050, now - 30))
local gone, goneCount = LS:GoneAmong(both)
check(goneCount == 1 and gone[CLOSE] == 30, "an XM marks the node not there")
check(LS:SeenAmong(both) == nil, "and it isn't seen")
plan = J:PlanEntry(session, pick)
check(plan.goal == WEST and plan.seenAge == nil, "the pick skips it for the next nearest: " .. tostring(plan.goal))
LS:OnMessage(r(4800, 6050, now - 100))
check(LS:SeenAmong(both) == nil and LS:GoneAmong(both), "a sighting older than the XM changes nothing")
LS:OnMessage(r(4800, 6050, now - 10))
seen = LS:SeenAmong(both)
check(seen and seen[CLOSE] == 10 and LS:GoneAmong(both) == nil, "a newer sighting ends the not there")
plan = J:PlanEntry(session, pick)
check(plan.goal == CLOSE and plan.seenAge == 10, "and the pick goes there again")
LS:OnMessage(("XS:1:A:3104:1417,4800,6050,%d;1417,2530,3000,%d"):format(now, now))
gone, goneCount = LS:GoneAmong(both)
check(goneCount == 2 and LS:SeenAmong(both) == nil, "an XS's entries are not-theres too, and a newer one ends the sighting")
plan = J:PlanEntry(session, pick)
check(plan.goal == CLOSE, "with every node not there, the nearest of them all")
LS:OnMessage(xm(9000, 9000, now))
check(#LS:NearbyPlaces() == 2, "an XM never adds a place")
LS:OnMessage(("XM:1:A:3104:1417:4800:6050:%d"):format(now - 5500))
check(#MapzerothRebuildDB.sightingsGone.A[1417] == 3, "a stale XM isn't kept (two nodes, and the far spot)")
-- An XS doesn't answer a Q's sightings part: our S still goes out.
LS:OnMessage(r(6000, 2000, now - 5))
sent, timers = {}, {}
LS:OnMessage("Q:1:A:3104")
LS:OnMessage(("XS:1:A:3104:1417,100,100,%d"):format(now))
runTimers()
check(#sent == 1 and sent[1]:find("^S:1:A:3104:1417,6000,2000,"), "an XS doesn't cancel our answer: " .. tostring(sent[1]))
-- Continent positions (Skyborne Compass has sent Kalimdor's) move to the zone at that spot.
local savedInfo, savedEnum = C_Map.GetMapInfo, Enum
Enum = { UIMapType = { Continent = 2, Zone = 3 } }
C_Map.GetMapInfo = function(id) return { name = "map " .. id, mapType = id == 1415 and 2 or 3 } end
C_Map.GetMapInfoAtPosition = function(id, x, y) return id == 1415 and x < 0.9 and { mapID = 1417, mapType = 3 } or nil end
C_Map.GetMapPosFromWorldPos = function(_, world) return nil, CreateVector2D(world.x / 2500, world.y / 1700) end
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
LS:OnMessage(("R:1:A:3104:1415:2530:3000:%d"):format(now))
LS:OnMessage(("R:1:A:3104:1415:9500:9500:%d"):format(now))
check(MapzerothRebuildDB.sightings.A[1415] == nil and #MapzerothRebuildDB.sightings.A[1417] == 1,
    "a continent sighting is kept on the zone there, and one with no zone there is dropped")
C_Map.GetMapInfo, Enum, C_Map.GetMapInfoAtPosition, C_Map.GetMapPosFromWorldPos = savedInfo, savedEnum, nil, nil
MapzerothRebuildDB.sightingsGone = nil

-- The places: SLLCM's 25 nodes nearest the player on their continent, and any seen up in their phase however far;
-- chosen once for a pick.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
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
LS:OnMessage(("R:1:A:3104:1418:5000:5000:%d"):format(now - 120))
LS:OnMessage(("R:1:A:7777:1417:%d:%d:%d"):format(9800, 9800, now - 30))           -- another phase
LS:OnMessage(r(4700, 6000, now - 30))                                               -- at one of the 25
places = LS:NearbyPlaces()
check(#places == 26 and places[26].id == "LEY_A_1418_5000_5000",
    "a node seen up in our phase joins them, however far; not one in another phase, nor a second of one there: " .. #places)
local pick2 = { name = "Nearest Ley Line", pick = true, group = "leyline", nodeIDs = {} }
local kept = LS:PlacesFor(pick2)
playerAt = { 0.9, 0.9 }
check(LS:PlacesFor(pick2) == kept and #LS:PlaceIDs(pick2) == 26, "a pick keeps the places it was given")
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

-- Q and S: a Q for a phase we hold is answered after a wait, unless someone else's S comes first.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
sent = {}
for i = 1, 10 do LS:OnMessage(r(500 + i * 400, 1000, now - i)) end    -- ten nodes 1000 yards apart
LS:OnMessage("Q:1:A:3104")
runTimers()
check(#sent == 2, "ten sightings answer in two messages: " .. #sent)
local _, entries = sent[1]:match("^S:1:A:3104:(.*)$"):gsub(";", ";")
check(sent[1]:find("^S:1:A:3104:1417,") and entries == 8 and sent[2]:find("^S:1:A:3104:[^;]+$"),
    "nine in the first, one in the second: " .. sent[1])
sent = {}
local function sEntries(from, to, age)
    local list = {}
    for i = from, to do list[#list + 1] = ("1417,%d,1000,%d"):format(500 + i * 400, now - i - (age or 0)) end
    return table.concat(list, ";")
end
LS:OnMessage("Q:1:A:3104")
LS:OnMessage("S:1:A:3104:" .. sEntries(1, 9))
LS:OnMessage("S:1:A:3104:" .. sEntries(10, 10))
runTimers()
check(#sent == 0, "someone else's answers had all of ours: we stay quiet: " .. tostring(sent[1]))
LS:OnMessage("Q:1:A:3104")
LS:OnMessage("S:1:A:3104:" .. sEntries(1, 7))
runTimers()
check(#sent == 1 and select(2, sent[1]:gsub(";", ";")) == 2 and sent[1]:find("4100,1000", 1, true),
    "an answer with only some of them: we send the other three: " .. tostring(sent[1]))
sent = {}
LS:OnMessage("Q:1:A:3104")
LS:OnMessage("S:1:A:3104:" .. sEntries(1, 9, 100) .. ";1417,4500,1000," .. (now - 10))
runTimers()
check(#sent == 1 and select(2, sent[1]:gsub(";", ";")) == 8,
    "an older answer for the same nodes doesn't cover our newer sightings: " .. tostring(sent[1]))
sent = {}
LS:OnMessage("Q:1:A:3104")
LS:OnMessage("S:1:A:3104:1417,2530,3000," .. (now - 5))
LS:OnMessage("Q:1:A:5555")
runTimers()
check(#sent == 2 and not sent[1]:find("2530", 1, true), "a phase we hold nothing for isn't answered: " .. #sent)
check(#MapzerothRebuildDB.sightings.A[1417] == 11, "the S's entry was kept as a new node")
-- A new Q while ours goes out: that asker missed the parts already sent, so the rest starts over.
sent = {}
LS:OnMessage("Q:1:A:3104")
local first = table.remove(timers)
first()                                                   -- the wait is over: the first part goes out
LS:OnMessage("Q:1:A:3104")
runTimers()
check(#sent == 3, "nine, then all eleven again for the new asker: " .. #sent)

-- How long before answering: 9-15 s holding only others' sightings, 1-8 s holding one of our own (so whoever saw it
-- usually answers). One wait per phase: a Q for another phase doesn't replace it, an S for another doesn't cancel it.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
LS:OnMessage(r(2530, 3000, now - 60))                                   -- someone else's, in 3104
LS:OnMessage("R:1:A:5555:1417:2530:3000:" .. (now - 60))               -- and in 5555
runTimers()
sent, delays = {}, {}
LS:OnMessage("Q:1:A:3104")
check(#delays == 1 and delays[1] >= 9 and delays[1] <= 15, "only others' sightings: a 9-15 s wait: " .. tostring(delays[1]))
LS:OnMessage("Q:1:A:3104")
check(#delays == 1, "a second Q for the same phase while waiting adds no second answer")
LS:OnMessage("Q:1:A:5555")
check(#delays == 2, "a Q for another phase gets its own wait")
LS:OnMessage("S:1:A:5555:1417,2530,3000," .. (now - 5))
runTimers()
check(#sent == 1 and sent[1]:find("^S:1:A:3104:"), "an S for 5555 cancels only 5555's answer: " .. tostring(sent[1]))
LS:OnConfirmed(1417, 0.48, 0.605, now)                                  -- our own find, in 3104
runTimers()
sent, delays = {}, {}
LS:OnMessage("Q:1:A:3104")
check(#delays == 1 and delays[1] >= 1 and delays[1] <= 8, "holding our own: a 1-8 s wait: " .. tostring(delays[1]))
runTimers()
check(#sent == 1 and sent[1]:find("4800,6050", 1, true), "and the answer carries it: " .. tostring(sent[1]))

-- Asking: once a session per phase, and not after the first 90 minutes on the channel.
reset()
holdOne()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
runTimers()
check(#sent == 1 and sent[1] == "Q:1:A:3104", "a new phase is asked about")
clock = clock + 120
LS:ReadGUID("Creature-0-1-2-4200-1111-0003")
LS:ReadGUID("Vehicle-0-1-2-4200-2222-0005")
LS:ReadGUID("Creature-0-1-2-3104-1234-0006")
LS:ReadGUID("Creature-0-1-2-3104-5678-0007")
runTimers()
check(#sent == 2 and sent[2] == "Q:1:A:4200" and LS:Phase() == "3104",
    "4200 is asked about once, and back in 3104 minutes later, 3104 isn't again: " .. #sent)
clock = clock + 5400
LS:ReadGUID("Creature-0-1-2-6000-1111-0008")
LS:ReadGUID("Vehicle-0-1-2-6000-2222-0009")
runTimers()
check(LS:Phase() == "6000" and #sent == 2, "after 90 minutes on the channel nothing is asked: every R and S since has been heard")

-- Someone else's Q for a phase does for ours: we hear its answers. So does one from just before a /reload, for 5 min.
reset()
holdOne()
LS:OnMessage("Q:1:A:3104")
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
runTimers()
check(#sent == 0, "a phase someone else asked about isn't asked about again: " .. tostring(sent[1]))
LS:ResetForTests()                                  -- a /reload: the session's memory goes, the saved file stays
now = now + 240
LS:ReadGUID("Creature-0-1-2-3104-1234-0002")
runTimers()
check(#sent == 0, "nor after a /reload 4 minutes later")
LS:ResetForTests()
now = now + 120
LS:ReadGUID("Creature-0-1-2-3104-1234-0003")
runTimers()
check(#sent == 1 and sent[1] == "Q:1:A:3104", "but 6 minutes after the last Q it is: " .. tostring(sent[1]))
LS:ResetForTests()
now = now + 60
LS:ReadGUID("Creature-0-1-2-3104-1234-0004")
runTimers()
check(#sent == 1, "and our own Q counts the same way after a /reload")
now = now - 420

-- Our own find: before the phase is known it waits, and goes out once it is (in the same zone).
reset()
LS:OnConfirmed(1417, 0.48, 0.605, now - 3)
check(#sent == 0, "no phase yet: nothing sent")
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
check(sent[1] == "R:1:A:3104:1417:4800:6050:" .. (now - 3), "sent once the phase is read, with the cast's time: " .. tostring(sent[1]))
runTimers()
check(sent[2] == "Q:1:A:3104", "then the question")
LS:OnConfirmed(1417, 0.2, 0.2, now)
runTimers()
check(sent[3] == "R:1:A:3104:1417:2000:2000:" .. now, "with the phase known, at once")

-- Throttled: the message waits and goes again.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
sent = {}
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
holdOne()                                           -- so the Q goes out first, as before
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
runTimers()
sent = {}
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

-- Forever's refusal: no echo within 15 s, or NOT_ALLOWED_IN_CHANNEL, pauses sending for 10 minutes; then the next
-- message is the probe, and anything heard on the channel ends the pause.
reset()
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
runTimers()
sent, echo = {}, false
LS:OnConfirmed(1417, 0.3, 0.3, now)
runTimers()
check(LS:Stats().paused, "no echo: paused")
LS:OnConfirmed(1417, 0.4, 0.4, now)
runTimers()
check(#sent == 1, "nothing goes while paused")
clock = clock + 601
LS:OnConfirmed(1417, 0.5, 0.5, now)
check(#sent == 2, "ten minutes on, the next is the probe")
echo = true
LS:OnHeard()
check(not LS:Stats().paused, "heard: not paused")
LS:OnChannelNotice("NOT_ALLOWED_IN_CHANNEL")
check(LS:Stats().paused, "the server's refusal notice pauses too")
LS:OnHeard()
runTimers()
clock = clock - 601

-- With SLLCM loaded, Mapzeroth sends nothing and reads SLLCM's sightings instead.
reset()
loaded.SkyborneLeyLineConvergenceMarker = true
check(not LS:Networking() and LS:SllcmLoaded(), "SLLCM loaded: Mapzeroth stays off the channel")
LS:ReadGUID("Creature-0-1-2-3104-1234-0001")
LS:OnConfirmed(1417, 0.3, 0.3, now)
check(#sent == 0, "and sends nothing")
-- SLLCM 0.3.1 keeps them by faction: only this faction's count.
SkyborneMarkerDB = { crowdReports = {
    A = { [1417] = { { phase = "3104", x = 0.48, y = 0.605, t = now - 300 } } },
    H = { [1417] = { { phase = "3104", x = 0.253, y = 0.30, t = now - 30 } } },
} }
seen, count = LS:SeenAmong({ WEST, CLOSE })
check(count == 1 and seen[CLOSE] == 300, "SLLCM's sightings for this faction are what the pick uses")
SkyborneMarkerDB = { crowdReports = { A = {} } }
check(LS:SeenAmong({ WEST, CLOSE }) == nil, "none held for this faction: none seen")
-- 0.3.0: one list for both factions, by map.
SkyborneMarkerDB = { crowdReports = { [1417] = { { phase = "3104", x = 0.48, y = 0.605, t = now - 300 } } } }
seen, count = LS:SeenAmong({ WEST, CLOSE })
check(count == 1 and seen[CLOSE] == 300, "SLLCM 0.3.0's single list is still read")
check(not LS:ShouldAsk(), "and Mapzeroth doesn't ask: SLLCM asks its own question")
SkyborneMarkerDB = { crowdReports = { A = { [1417] = { { phase = "3104", x = 0.45, y = 0.58, t = now - 30 } } } } }
local pick3 = { name = "Nearest Ley Line", pick = true, group = "leyline", nodeIDs = {} }
seen, count = LS:SeenAmong(LS:PlaceIDs(pick3))
check(#LS:PlaceIDs(pick3) == 3 and count == 1 and seen["LEY_A_1417_4500_5800"] == 30,
    "a spot only SLLCM's sightings know is one of the pick's places too, and counts as seen")
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
