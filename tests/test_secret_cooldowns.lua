-- In combat the client answers cooldown queries with "secret" numbers that addon code can't compare or
-- add. The cooldown checks must not touch them: they fall back to the last readable answer.
-- A table stands in for a secret here, since comparing one with a number errors just like the real thing.
local SECRET = { secret = true }
issecretvalue = function(v) return v == SECRET end

local now = 1000
GetTime = function() return now end

local spellAnswer, itemAnswer
C_Spell = C_Spell or {}
C_Spell.GetSpellCooldown = function() return spellAnswer end
C_Item = C_Item or {}
C_Item.GetItemCooldown = function() return itemAnswer[1], itemAnswer[2] end

local spellCooldown = addon:GetPlayerContext().cooldownRemaining

-- 1. Out of combat: read as usual, and remembered.
spellAnswer = { startTime = 900, duration = 1800, isEnabled = true }
check(spellCooldown(8690) == 1700, "a readable spell cooldown is read: " .. tostring(spellCooldown(8690)))
itemAnswer = { 950, 300 }
check(addon:ItemCooldownRemaining(6948) == 250, "a readable item cooldown is read")

-- 2. In combat: secret numbers fall back to what was remembered, counting down.
now = 1100
spellAnswer = { startTime = SECRET, duration = SECRET, isEnabled = true }
itemAnswer = { SECRET, SECRET }
local ok, left = pcall(spellCooldown, 8690)
check(ok and left == 1600, "a secret spell cooldown uses the remembered one: " .. tostring(left))
ok, left = pcall(addon.ItemCooldownRemaining, addon, 6948)
check(ok and left == 150, "a secret item cooldown uses the remembered one: " .. tostring(left))

-- 3. Never seen outside combat: taken as ready.
ok, left = pcall(spellCooldown, 556)
check(ok and left == 0, "a secret cooldown with nothing remembered is ready: " .. tostring(left))

-- 4. A cooldown seen ready forgets the old one.
now = 1200
spellAnswer = { startTime = 0, duration = 0, isEnabled = true }
check(spellCooldown(8690) == 0, "ready out of combat")
spellAnswer = { startTime = SECRET, duration = SECRET, isEnabled = true }
check(spellCooldown(8690) == 0, "and still ready once it turns secret")

-- 5. A ghost's run speed can be secret too (unit stats restricted): type() says "number", so a number stands in here,
-- marked secret; it must not be used (or compared). Walking speed then.
local SECRET_SPEED = 12.25
issecretvalue = function(v) return v == SECRET or v == SECRET_SPEED end
UnitIsGhost = function() return true end
local speedAnswer = SECRET_SPEED
GetUnitSpeed = function() return 0, speedAnswer, speedAnswer, speedAnswer end
local okCtx, ctx = pcall(addon.GetPlayerContext, addon)
check(okCtx and ctx.ghost and ctx.ghostSpeed == nil, "a secret ghost speed is no answer: " .. tostring(okCtx and ctx.ghostSpeed or ctx))
speedAnswer = 9
check(addon:GetPlayerContext().ghostSpeed == 9, "a readable one is used")
UnitIsGhost, GetUnitSpeed = nil, nil

issecretvalue = nil
