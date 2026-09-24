-- Places.lua (Modern) -- HAND-MAINTAINED. What the picker's main page shows for Modern, and how the rest is filed
-- under "Older content" (see Sections.lua). Expansions are numbered by major version: Classic 1, The Burning
-- Crusade 2, ... The War Within 11, Midnight 12.

local addonName, addon = ...

-- The picker's main page is laid out by expansion (Sections.lua), not as Forever's cities and towns.
addon.PICKER_LAYOUT = "expansions"

-- Change when a new expansion launches: the main page shows this expansion's cities, dungeons and raids.
addon.CURRENT_EXPANSION = 12

-- Change each Mythic+ season: the older dungeons in the season's pool, listed on the main page with the
-- current expansion's own (by journal instance id; the name is only a note).
addon.SEASONAL_DUNGEONS = {
    1322,   -- Altar of Fangs
    1304,   -- Murder Row
    1313,   -- Voidscar Arena
    1311,   -- Den of Nalorakk
    1309,   -- The Blinding Vale
    1202,   -- Ruby Life Pools
    1041,   -- King's Rest
    1030    -- Temple of Sethraliss
}

-- A dungeon or raid node's journal instance is a field on the node (`journal`, and `faction` for an entrance only one
-- faction has): tools/modern_ids.py and tools/modern_manual.py's INSTANCE_JOURNALS.

-- The cities are in Settlements.lua, generated from tools/modern_manual.py's CITIES (Forever's addon.Cities shape).
