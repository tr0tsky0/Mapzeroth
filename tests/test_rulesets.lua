-- One .toc loads both games' data, and each data file skips itself unless it is this client's (Constants.lua's
-- addon.RULESET, from the client version: Forever and retail can't be told apart by .toc name).

-- Every data file the .toc lists carries its game's guard right after the header line, so a regenerated file that
-- lost it (a generator not writing it) fails here, not in the other game's client.
local GUARD = {
    Forever = 'if addon.RULESET ~= "forever" then return end',
    Modern = 'if addon.RULESET ~= "modern" then return end',
}
local toc = assert(io.open(ADDON_ROOT .. "/Mapzeroth-Rebuild.toc", "r"))
local checked = { Forever = 0, Modern = 0 }
for line in toc:lines() do
    line = line:gsub("\r$", "")
    local folder = line:match("^Data[\\/](%a+)[\\/]")
    if folder then
        local f = assert(io.open(ADDON_ROOT .. "/" .. line:gsub("\\", "/"), "r"))
        local text = f:read("*a")
        f:close()
        local after = text:match("local addonName, addon = %.%.%.\r?\n([^\r\n]*)")
        check(after and after:sub(1, #GUARD[folder]) == GUARD[folder], line .. " starts with its game's guard")
        checked[folder] = checked[folder] + 1
    end
end
toc:close()
check(checked.Forever > 10 and checked.Modern > 10, "both games' data are in the .toc: " .. checked.Forever .. ", " .. checked.Modern)

-- This run is a Forever client: Forever's data loaded, none of Modern's.
check(addon.RULESET == "forever", "the harness plays Forever")
check(addon.RidingSkills and addon.PICKER_LAYOUT == "settlements", "Forever's data is loaded")
check(addon.CURRENT_EXPANSION == nil and addon.Instances == nil and addon.HOLIDAYS == nil, "and none of Modern's")
check(addon.Nodes.EK == nil and addon.Nodes.Pois ~= nil, "no Modern node group")
