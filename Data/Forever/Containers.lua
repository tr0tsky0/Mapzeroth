-- Containers.lua (Forever)
--
-- Per-container flag overrides. The container TREE itself is derived from the
-- dotted `container` paths on the nodes (see World.lua); this file only holds
-- what a container overrides. A flag not set on a container is inherited from
-- the nearest ancestor that sets it, and the root ("") sets the defaults.
--
--   fly    - flying mounts allowed. Forever has no flying at all.
--   indoor - mounts / outdoor-only speed forms unusable inside.
--   phaseGroup / phaseSide - phased zones (none exist in Forever).

local addonName, addon = ...

addon.Containers = addon.Containers or {}

addon.Containers[""] = { fly = false, indoor = false }
