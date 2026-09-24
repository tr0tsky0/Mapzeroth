"""Headless test harness: loads the addon's TOC files in order into a Lua 5.1
runtime (lupa) with just enough WoW API stubbed, then runs Lua test files.

    python tests/harness.py                     # run every tests/test_*.lua (Forever)
    python tests/harness.py test_world           # run one
    python tests/harness.py --toc <name>.toc t1 t2   # run named files against a different TOC
                                                       # (e.g. the Modern data-conversion smoke
                                                       # test, which isn't named test_*.lua so
                                                       # the default run above never picks it up:
                                                       # python tests/harness.py --toc Mapzeroth-Rebuild_Mainline.toc modern_smoke)
"""
import pathlib
import sys

from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOC = ROOT / "Mapzeroth-Rebuild.toc"

STUBS = r"""
function GetLocale() return "enUS" end
function GetBuildInfo() return "1.60.1", "16001", "Sep 1 2026", 16001 end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
function CreateVector2D(x, y) return { x = x, y = y, GetXY = function(self) return self.x, self.y end } end
SlashCmdList = {}
function hooksecurefunc() end
-- Tests override these to play different characters.
function UnitFactionGroup() return "Alliance" end
function UnitClass() return "Druid", "DRUID" end
function UnitRace() return "Human", "Human", 1 end
function UnitLevel() return 20 end
function IsPlayerSpell() return false end
"""


PRELUDE = r"""
function check(cond, msg)
    if not cond then error("CHECK FAILED: " .. tostring(msg), 2) end
end

-- A player context. overrides: faction, class, race, level, spells = {id, ...}
function makeCtx(overrides)
    overrides = overrides or {}
    local known, items, toys = {}, {}, {}
    for _, id in ipairs(overrides.spells or {}) do known[id] = true end
    for _, id in ipairs(overrides.items or {}) do items[id] = true end
    for _, id in ipairs(overrides.toys or {}) do toys[id] = true end
    local equippable, equipped = {}, {}
    for _, id in ipairs(overrides.equippable or {}) do equippable[id] = true end
    for _, id in ipairs(overrides.equipped or {}) do equipped[id] = true end
    return {
        faction = overrides.faction or "Alliance",
        class = overrides.class or "MAGE",
        race = overrides.race or "Human",
        level = overrides.level or 20,
        knowsSpell = function(id) return known[id] or false end,
        hasItem = function(id) return items[id] or false end,
        hasToy = function(id) return toys[id] or false end,
        isEquippable = function(id) return equippable[id] or false end,
        isEquipped = function(id) return equipped[id] or false end,
        cooldownRemaining = function(id) return (overrides.cooldowns or {})[id] or 0 end,
        itemCooldownRemaining = function(id) return (overrides.itemCooldowns or {})[id] or 0 end,
        hearthNode = overrides.hearthNode,
        questCompleted = function(id) return (overrides.quests or {})[id] or false end,
        holidayActive = function(key) return (overrides.holidays or {})[key] or false end,
        loadingScreenTax = overrides.loadingScreenTax or 15,
    }
end

-- Rough yards between nodes: no client here, so zone maps are treated as
-- 2500 x 1700 yards and unrelated maps as a flat 3000 yards apart.
function useTestDistances()
    addon.TravelGraph.DistanceProvider = function(a, b)
        if a.mapID == b.mapID then
            return math.sqrt(((a.x - b.x) * 2500) ^ 2 + ((a.y - b.y) * 1700) ^ 2)
        end
        return 3000
    end
end

-- Route from startID to goalID as this player; returns the result or nil.
function route(ctx, startID, goalID)
    addon.World:Build()
    local graph = addon.TravelGraph:Build(ctx)
    return addon.Pathfinder:FindPath(graph, startID, goalID)
end

function methods(result)
    local out = {}
    for _, step in ipairs(result.steps) do out[#out + 1] = step.method end
    return table.concat(out, ",")
end
"""


def toc_files(toc=None):
    files = []
    for line in (toc or TOC).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        files.append(line.replace("\\", "/"))
    return files


def compile_chunk(loadstring, source, name):
    """loadstring returns a function on success, or (nil, message) on failure."""
    result = loadstring(source, "@" + name)
    if isinstance(result, tuple):
        raise SystemExit(f"syntax error in {name}: {result[1]}")
    return result


def new_runtime(toc=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    addon = lua.eval("{}")
    loadstring = lua.eval("loadstring")
    for name in toc_files(toc):
        path = ROOT / name
        chunk = compile_chunk(loadstring, path.read_text(encoding="utf-8"), name)
        chunk("MapzerothRebuild", addon)
    # Test support that isn't part of the addon: the data validator.
    support = ROOT / "tests" / "Validator.lua"
    compile_chunk(loadstring, support.read_text(encoding="utf-8"), support.name)("MapzerothRebuild", addon)
    lua.globals().addon = addon
    return lua


def run_test(name, toc=None):
    lua = new_runtime(toc)
    path = ROOT / "tests" / f"{name}.lua"
    lua.execute(PRELUDE)
    chunk = compile_chunk(lua.eval("loadstring"), path.read_text(encoding="utf-8"), path.name)
    outcome = lua.eval("pcall")(chunk)
    # pcall gives a bare true on success, (false, message) on failure.
    ok, result = outcome if isinstance(outcome, tuple) else (outcome, None)
    print(f"{'PASS' if ok else 'FAIL'} {name}" + ("" if ok else f": {result}"))
    return bool(ok)


def main():
    args = sys.argv[1:]
    toc = None
    if args[:1] == ["--toc"]:
        toc = ROOT / args[1]
        args = args[2:]
    names = args or sorted(p.stem for p in (ROOT / "tests").glob("test_*.lua"))
    results = [run_test(n, toc) for n in names]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
