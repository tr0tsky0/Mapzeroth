-- The shipped Forever data has no broken references (the same check as /mzr validate).
useTestDistances()
addon.World:Build()

local issues = addon:ValidateData()
for i = 1, math.min(#issues, 10) do
    print(issues[i].level .. ": " .. issues[i].message)
end
check(#issues == 0, "the data validates with no errors or warnings (" .. #issues .. " issue(s))")
