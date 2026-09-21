-- Professions.lua (Forever)
--
-- Each profession's first-rank spell. A profession trainer's `trainer` token is one of
-- these keys, and its display name is the client's own name for the spell, so it is in
-- the player's language with no string of ours. The spell ids match the rank spells
-- Wowhead lists for the profession trainers (for example 8613 is Skinning).

local addonName, addon = ...

addon.Professions = {
    ALCHEMY        = 2259,
    BLACKSMITHING  = 2018,
    COOKING        = 2550,
    ENCHANTING     = 7411,
    ENGINEERING    = 4036,
    FIRSTAID       = 3273,
    FISHING        = 7620,
    HERBALISM      = 2366,
    LEATHERWORKING = 2108,
    MINING         = 2575,
    SKINNING       = 8613,
    TAILORING      = 3908,
}

-- Every rank spell we've seen a trainer teach, lowest rank first (Apprentice, Journeyman,
-- Expert, Artisan). A player "has" a profession if they know its first rank, and their
-- rank is the highest of these they know. Only ranks some trainer teaches are listed:
-- Cooking, First Aid, Fishing and Enchanting have higher ranks (from books and quests)
-- that no trainer teaches, so they are missing here and don't need to be.
-- tools/gen_pois.py reads this table too, so keep it one entry per line.
addon.ProfessionRanks = {
    ALCHEMY        = { 2259, 3101, 3464, 11611 },
    BLACKSMITHING  = { 2018, 3100, 3538, 9785 },
    COOKING        = { 2550, 3102 },
    ENCHANTING     = { 7411, 7412, 7413 },
    ENGINEERING    = { 4036, 4037, 4038, 12656 },
    FIRSTAID       = { 3273, 3274 },
    FISHING        = { 7620, 7731 },
    HERBALISM      = { 2366, 2368, 3570, 11993 },
    LEATHERWORKING = { 2108, 3104, 3811, 10662 },
    MINING         = { 2575, 2576, 3564, 10248 },
    SKINNING       = { 8613, 8617, 8618, 10768 },
    TAILORING      = { 3908, 3909, 3910, 12180 },
}
