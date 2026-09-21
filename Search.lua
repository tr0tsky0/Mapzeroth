local addonName, addon = ...

-- Matching what the player types against place names. Pure text work, no client calls.
--
-- Text is folded before comparing: lower case with the Latin-1 accents removed, so
-- "Zul'Gurub" and "zul'gurub" match, and so do "Sturmwind" and a typed "sturmwind" in
-- deDE or "Forêt" and "foret" in frFR. It is done by hand because string.lower depends
-- on the platform's locale and can corrupt the bytes of a UTF-8 letter. Cyrillic capitals
-- are lowered too (ruRU); Chinese and Korean have no case and are compared as typed.
--
-- Every word the player types must match, and each is scored by where it hits: the start
-- of the name best, the start of a word in it next, anywhere in it after that, and the
-- start of a word in the zone last. Results sort by score, then relevant places first,
-- then shorter names.

local Search = {}
addon.Search = Search

-- U+00C0..U+00FF are the two bytes 0xC3 0x80..0xBF, so the second byte is the code point
-- minus 0x40.
local folded = {}
do
    local function set(from, to, ascii)
        for cp = from, to do folded[cp - 0x40] = ascii end
    end
    set(0xC0, 0xC5, "a"); folded[0xC6 - 0x40] = "ae"; set(0xC7, 0xC7, "c")
    set(0xC8, 0xCB, "e"); set(0xCC, 0xCF, "i"); set(0xD0, 0xD0, "d"); set(0xD1, 0xD1, "n")
    set(0xD2, 0xD6, "o"); set(0xD8, 0xD8, "o"); set(0xD9, 0xDC, "u"); set(0xDD, 0xDD, "y")
    folded[0xDE - 0x40] = "th"; folded[0xDF - 0x40] = "ss"
    set(0xE0, 0xE5, "a"); folded[0xE6 - 0x40] = "ae"; set(0xE7, 0xE7, "c")
    set(0xE8, 0xEB, "e"); set(0xEC, 0xEF, "i"); set(0xF0, 0xF0, "d"); set(0xF1, 0xF1, "n")
    set(0xF2, 0xF6, "o"); set(0xF8, 0xF8, "o"); set(0xF9, 0xFC, "u"); set(0xFD, 0xFD, "y")
    folded[0xFE - 0x40] = "th"; folded[0xFF - 0x40] = "y"
end

local lowerASCII = {}
for c = 65, 90 do lowerASCII[string.char(c)] = string.char(c + 32) end

-- Cyrillic: U+0410..U+042F are 0xD0 0x90..0xAF and their lower case is U+0430..U+044F,
-- which are 0xD0 0xB0..0xBF and 0xD1 0x80..0x8F; Ё (0xD0 0x81) becomes ё (0xD1 0x91).
local function lowerCyrillic(second)
    local b = second:byte()
    if b == 0x81 then return "\209\145" end
    if b <= 0x9F then return "\208" .. string.char(b + 32) end
    return "\209" .. string.char(b - 32)
end

function Search:Fold(text)
    text = text:gsub("\195([\128-\191])", function(second)
        return folded[second:byte()]
    end)
    text = text:gsub("\208([\129\144-\175])", lowerCyrillic)
    return (text:gsub("[A-Z]", lowerASCII))
end

-- Where `token` hits in the folded `text`: 3 at the start, 2 at the start of a later word,
-- 1 anywhere else, 0 not at all. Plain finds, so punctuation in either is harmless.
local function hit(text, token)
    local at = text:find(token, 1, true)
    if not at then return 0 end
    if at == 1 then return 3 end
    local before = text:sub(at - 1, at - 1)
    if before:match("[%s%-'/,]") then return 2 end
    -- Something later in the text may start a word even if the first hit doesn't.
    local from = at + 1
    while true do
        local later = text:find(token, from, true)
        if not later then return 1 end
        if text:sub(later - 1, later - 1):match("[%s%-'/,]") then return 2 end
        from = later + 1
    end
end

-- Adds .key (folded name) and .zoneKey (folded zone) to each entry. Call again if names change.
function Search:Prepare(entries)
    for _, entry in ipairs(entries) do
        entry.key = self:Fold(entry.name or "")
        entry.zoneKey = self:Fold(entry.zone or "")
    end
    return entries
end

-- The best `limit` entries for what was typed, best first; each gets a .score.
-- An empty query matches nothing.
function Search:Query(entries, text, limit)
    local tokens = {}
    for token in self:Fold(text or ""):gmatch("%S+") do tokens[#tokens + 1] = token end
    if #tokens == 0 then return {} end

    local results = {}
    for _, entry in ipairs(entries) do
        local score = 0
        for _, token in ipairs(tokens) do
            local best = hit(entry.key, token)
            if best == 0 then
                -- A zone match counts for less than any hit in the name.
                best = hit(entry.zoneKey or "", token) > 0 and 0.5 or 0
            end
            if best == 0 then score = 0; break end
            score = score + best
        end
        if score > 0 then
            entry.score = score
            results[#results + 1] = entry
        end
    end

    table.sort(results, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.relevant ~= b.relevant then return a.relevant and not b.relevant end
        if #a.name ~= #b.name then return #a.name < #b.name end
        return a.name < b.name
    end)

    if limit and #results > limit then
        for i = #results, limit + 1, -1 do results[i] = nil end
    end
    return results
end
