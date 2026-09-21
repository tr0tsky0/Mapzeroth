local addonName, addon = ...

-- Where the player is, as a starting node for the route planner. The only client-reading
-- piece of the planner, kept apart so the rest can be tested headless.

-- Our nodes cover zones, not every map (a subzone or a cave has none), so a position on a map
-- with no nodes is carried up to the nearest parent map that has some.
local function knownMap(mapID, x, y)
    local World = addon.World
    if World:GetContainerForMap(mapID) then return mapID, x, y end

    local continent, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    local info = C_Map.GetMapInfo(mapID)
    local parent = info and info.parentMapID
    while parent and parent ~= 0 do
        if World:GetContainerForMap(parent) then
            local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, parent)
            if pos then
                local px, py = pos:GetXY()
                return parent, px, py
            end
        end
        local up = C_Map.GetMapInfo(parent)
        parent = up and up.parentMapID
    end
end

-- The player as a start node { id, mapID, x, y }, or nil and a reason ("no map",
-- "no position", "unknown map") when we can't say where they are (inside an instance, say).
function addon:GetPlayerStart()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil, "no map" end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil, "no position" end
    local x, y = pos:GetXY()
    if not x or (x == 0 and y == 0) then return nil, "no position" end

    local knownID, kx, ky = knownMap(mapID, x, y)
    if not knownID then return nil, "unknown map" end
    -- The id names the spot (distances are cached by id), rounded so standing still reuses it.
    local id = ("YOU_%d_%d_%d"):format(knownID, math.floor(kx * 2000 + 0.5), math.floor(ky * 2000 + 0.5))
    return { id = id, mapID = knownID, x = kx, y = ky }
end
