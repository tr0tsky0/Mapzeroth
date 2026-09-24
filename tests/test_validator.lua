-- The shipped Forever data has no broken references (the same check as /mzr validate).
useTestDistances()
addon.World:Build()

local issues = addon:ValidateData()
for i = 1, math.min(#issues, 10) do
    print(issues[i].level .. ": " .. issues[i].message)
end
check(#issues == 0, "the data validates with no errors or warnings (" .. #issues .. " issue(s))")

-- Finding 7: the declarations the engine reads instead of guessing are checked.
do
    local function errorsWith(fn)
        local saved = { addon.PICKER_LAYOUT, addon.CURRENT_EXPANSION, addon.DEFAULT_MOUNT_BONUS }
        fn()
        local found = {}
        for _, issue in ipairs(addon:ValidateData()) do
            if issue.level == "error" then found[#found + 1] = issue.message end
        end
        addon.PICKER_LAYOUT, addon.CURRENT_EXPANSION, addon.DEFAULT_MOUNT_BONUS = saved[1], saved[2], saved[3]
        return table.concat(found, "; ")
    end
    check(errorsWith(function() addon.PICKER_LAYOUT = nil end):find("PICKER_LAYOUT is nil"), "a missing picker layout is an error")
    check(errorsWith(function() addon.PICKER_LAYOUT = "expansions" end):find("CURRENT_EXPANSION is not set"),
        "an expansion page without a current expansion is an error")
    check(errorsWith(function() addon.DEFAULT_MOUNT_BONUS = 1.0 end):find("both RidingSkills and DEFAULT_MOUNT_BONUS"),
        "a flat mount bonus next to riding data is an error")
    check(#addon:ValidateData() == 0, "and the data is clean again afterwards")
end
