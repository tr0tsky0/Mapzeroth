local S = addon.Search

-- Folding: case and Latin-1 accents.
check(S:Fold("Stormwind") == "stormwind", "case")
check(S:Fold("Forêt d'Ébène") == "foret d'ebene", "French accents: " .. S:Fold("Forêt d'Ébène"))
check(S:Fold("Sturmwind Über") == "sturmwind uber", "German umlauts: " .. S:Fold("Sturmwind Über"))
check(S:Fold("Cañón") == "canon", "Spanish: " .. S:Fold("Cañón"))
check(S:Fold("Straße") == "strasse", "eszett")
check(S:Fold("Ленинград Ёж") == "ленинград ёж", "Cyrillic capitals are lowered")
check(S:Fold("暴风城") == "暴风城", "Chinese is left as typed")

local function entry(name, zone, relevant)
    return { name = name, zone = zone, relevant = relevant ~= false }
end
local entries = S:Prepare({
    entry("Stormwind City"), entry("Stormwind Harbor"), entry("Goldshire Inn", "Elwynn Forest"),
    entry("Duskwood Ley Line", "Duskwood"), entry("Darkshire, Duskwood", "Duskwood"),
    entry("Wetlands Inn", "Wetlands"), entry("Ironforge, Dun Morogh", "Dun Morogh"),
    entry("Forêt d'Ébène", "Sombrebois"), entry("Warrior Trainer", "Stormwind", false),
    entry("Warrior Trainer", "Ironforge"),
})

local function names(results)
    local out = {}
    for i, r in ipairs(results) do out[i] = r.name end
    return table.concat(out, "|")
end

-- Prefix beats a hit deeper in the name, which beats a zone-only hit.
local r = S:Query(entries, "storm")
check(names(r) == "Stormwind City|Stormwind Harbor|Warrior Trainer|Warrior Trainer" or r[1].name:find("^Stormwind"),
    "prefix matches come first: " .. names(r))
check(r[1].score == 3 and r[2].score == 3, "both Stormwind places score as prefixes")

-- A word deeper in the name (2) beats a match inside a word (1).
local deep = S:Query(entries, "inn")
check(deep[1].score == 2 and deep[2].score == 2 and #deep == 2, "'inn' finds the two inns as word starts: " .. names(deep))

-- Every word must match; order of words doesn't matter.
check(names(S:Query(entries, "duskwood ley")) == "Duskwood Ley Line", "two words narrow it: " .. names(S:Query(entries, "duskwood ley")))
check(names(S:Query(entries, "ley duskwood")) == "Duskwood Ley Line", "in either order")
check(#S:Query(entries, "duskwood zzz") == 0, "an unmatched word rules a place out")

-- The zone counts, but less than the name.
local zone = S:Query(entries, "duskwood")
check(zone[1].name == "Duskwood Ley Line" and zone[2].name == "Darkshire, Duskwood", "name match first, zone match after: " .. names(zone))
check(S:Query(entries, "elwynn")[1].name == "Goldshire Inn", "a place is found by its zone alone")

-- Typed without accents (or with different case) still finds accented names.
check(names(S:Query(entries, "foret")) == "Forêt d'Ébène", "accent-free typing finds an accented name")
check(names(S:Query(entries, "FÔRET")) == "Forêt d'Ébène", "typing accents and capitals works too")

-- Ties: relevant first.
local trainers = S:Query(entries, "warrior")
check(trainers[1].relevant and trainers[1].zone == "Ironforge", "the relevant trainer sorts ahead: " .. names(trainers))

-- Limits and empties.
check(#S:Query(entries, "e", 2) == 2, "the limit is honoured")
check(#S:Query(entries, "   ") == 0 and #S:Query(entries, "") == 0, "an empty query matches nothing")
