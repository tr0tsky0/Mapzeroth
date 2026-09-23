-- Geometry.lua (Forever) -- precomputed static travel geometry (walk/gate/fly edges): generate
-- with /mzr dumpgeometry in-game (MapzerothDataTools' Dev.lua) and paste the export box's
-- contents in place of this file. See TravelGraph.lua's own comment for the format and why this
-- exists: it lets the client skip computing this from scratch on the first route of every
-- session (a smaller win here than for Modern -- Forever has no fly containers at all, and small
-- walk-containers -- but the same idea, and the same workflow either way).
--
-- Left empty (addon.Geometry unset) is safe -- TravelGraph falls back to computing it live (and
-- caching that for the rest of the session) whenever addon.Geometry isn't set, or its recorded
-- node count doesn't match what's actually loaded (a stale dump after a data change, caught
-- rather than silently served). Regenerate this before every version pushed to CurseForge that
-- touches node or container data.

local addonName, addon = ...
