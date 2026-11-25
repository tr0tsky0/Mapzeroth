-- Adds "[<Addon> <Version>]" to the end of this addon's errors in BugGrabber,
-- so BugSack reports say which version threw them. Master copy lives in
-- WoW Addons\shared\; copy it unchanged and list it first in the .toc.
-- The tag goes on err.stack, never err.message: BugGrabber matches repeats by message.

local addonName = ...
if not (EventRegistry and C_AddOns and C_AddOns.GetAddOnMetadata) then return end

local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
local tag = "[" .. addonName .. " " .. version .. "]"
-- Stack and message paths can be long ("Interface/AddOns/<Addon>/x.lua") or short
-- ("[<Addon>/x.lua]", as Blizzard addons show), so match the folder either way.
local needles = {
    "/" .. addonName .. "/",
    "[" .. addonName .. "/",
    "'" .. addonName .. "'",
}

local function mentionsUs(text)
    if text:sub(1, #addonName + 1) == addonName .. "/" then return true end
    for i = 1, #needles do
        if text:find(needles[i], 1, true) then return true end
    end
    return false
end

local function findError(id)
    local grabber = BugGrabber
    local db = grabber and grabber.GetDB and grabber:GetDB()
    if type(db) ~= "table" then return end
    for i = #db, 1, -1 do
        if tostring(db[i]) == id then return db[i] end
    end
end

local function onGrabbed(_, id)
    local err = findError(id)
    if not err or type(err.message) ~= "string" then return end
    local stack = type(err.stack) == "string" and err.stack or ""
    if stack:find(tag, 1, true) then return end
    if mentionsUs(err.message) or mentionsUs(stack) then
        err.stack = (stack ~= "" and stack .. "\n" or "") .. tag
    end
end

EventRegistry:RegisterCallback("BugGrabber.BugGrabbed", onGrabbed, {})
