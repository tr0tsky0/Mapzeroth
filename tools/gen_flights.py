"""Generates Data/Forever/Flights.lua: the classic flight network as single legs.

Which pairs are legs comes from the game's own flight table (tools/flight_source/taxipath_classic_1.15.9.txt,
Classic Era's TaxiPath): each row is one flight master flying straight to another, whatever the flyer
has found. How long a leg takes comes from InFlight's recorded ticket times
(tools/flight_source/inflight_tickets.lua). A ticket between two points that are a leg is the leg's own
time; tickets between points that are not a leg pass through others and are only used to check the result.

The planner chains legs over the points the player has found and takes FLIGHT_CHAIN_SAVING (a fraction of the
leg's time) off each extra leg (a through-ticket doesn't land and take off again).

Where InFlight has no time for a leg in either direction, the time is estimated from the distance between
the two points (at the median speed of the timed legs on that continent; about 16% off on legs we can
check), and the report says so.

    python tools/gen_flights.py
"""
import heapq
import json
import math
import pathlib
import re
import statistics

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "tools" / "flight_source"
DATA = ROOT / "Data" / "Forever"

CHAIN_SAVING = 0.10             # fraction of an extra leg's time saved; keep equal to addon.FLIGHT_CHAIN_SAVING

# Fare 0 marks ship, zeppelin and dialog paths in the game's table, and these two pairs are the ones between
# flight points that we keep as legs anyway: the Teldrassil ferry, which InFlight timed at 84 and 86 s.
FARE_ZERO_LEGS = {(26, 27), (27, 26)}


def read_names():
    names = {}
    for name in ("Nodes_EasternKingdoms.lua", "Nodes_Kalimdor.lua"):
        text = (DATA / name).read_text(encoding="utf-8")
        for m in re.finditer(r'id = "(TAXI_\d+)".*?-- (.+)$', text, flags=re.M):
            names[m.group(1)] = re.sub(r"\s*\(.*", "", m.group(2)).strip()
    return names


def read_positions():
    """{TAXI id: (continent, x, y)} on the continent map, from each node's own zone map and position."""
    grids = json.loads((ROOT / "tools" / "grids.json").read_text(encoding="utf-8"))
    out = {}
    for name, continent in (("Nodes_EasternKingdoms.lua", "1415"), ("Nodes_Kalimdor.lua", "1414")):
        text = (DATA / name).read_text(encoding="utf-8")
        for m in re.finditer(r'id = "(TAXI_\d+)".*?mapID = (\d+), x = ([\d.]+), y = ([\d.]+) \}', text):
            info = grids[continent]["maps"].get(m.group(2))
            if info and info.get("rect"):
                left, right, top, bottom = info["rect"]
                out[m.group(1)] = (continent, left + float(m.group(3)) * (right - left),
                                   top + float(m.group(4)) * (bottom - top))
    return out


def read_tickets():
    """{(from, to, faction): seconds}"""
    tickets = {}
    text = (SRC / "inflight_tickets.lua").read_text(encoding="utf-8")
    for m in re.finditer(r'from = "(TAXI_\d+)", to = "(TAXI_\d+)", method = "flight", cost = (\d+), '
                         r'requirements = \{ faction = "(\w+)" \}', text):
        tickets[(m.group(1), m.group(2), m.group(4))] = int(m.group(3))
    return tickets


def read_taxipath():
    """{(from, to, faction): fare} for every direct flight the game lists between two flight points."""
    text = (SRC / "taxipath_classic_1.15.9.txt").read_text(encoding="utf-8")
    flags = {}
    for m in re.finditer(r"^NODE (\d+)\|\d\|[^|]*\|(\d)$", text, flags=re.M):
        flags[int(m.group(1))] = int(m.group(2))
    legs = {}
    for part in re.search(r"^PATHS (.+)$", text, flags=re.M).group(1).split(";"):
        a, b, fare = map(int, part.split())
        if fare == 0 and (a, b) not in FARE_ZERO_LEGS:
            continue
        fa, fb = flags.get(a), flags.get(b)
        if not fa or not fb:
            continue
        for faction, mine in (("Alliance", (1, 3)), ("Horde", (2, 3))):
            if fa in mine and fb in mine:
                legs[(f"TAXI_{a}", f"TAXI_{b}", faction)] = fare
    return legs


def read_blocks(names):
    """The routes the game reported through /mzroutes, in blocks that share a set of found flight
    points (a `FOUND:` line in the file): [{"found": [ids], "routes": [[stop ids]]}]."""
    def node_id(text):
        base = text.split(",")[0].strip()
        return next((k for k, v in names.items() if v.startswith(base)), None)
    blocks = []
    for line in (SRC / "game_routes.txt").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("FOUND:"):
            found = [node_id(x) for x in line[len("FOUND:"):].split(",")]
            blocks.append({"found": [f for f in found if f], "routes": []})
            continue
        m = re.match(r"(.+?) -> (.+?): (\d+) leg\(s\): (.+)$", line)
        if m and blocks:
            stops = [node_id(s) for s in m.group(4).split(" > ")]
            if None not in stops:
                blocks[-1]["routes"].append(stops)
    return blocks


def read_truth(names):
    """Every route the game reported: a list of stop lists."""
    return [route for block in read_blocks(names) for route in block["routes"]]


def write_route_test(blocks):
    """tests/test_gameroutes.lua: the planner must pick each route the game reported, given the flight
    points that had been found when it was captured."""
    body = []
    for block in blocks:
        found = ", ".join(f'"{f}"' for f in block["found"])
        routes = ",\n".join("            { " + ", ".join(f'"{x}"' for x in r) + " }" for r in block["routes"])
        body.append(f"    {{\n        found = {{ {found} }},\n        routes = {{\n{routes},\n        }},\n    }},")
    text = """-- tests/test_gameroutes.lua -- GENERATED by tools/gen_flights.py from tools/flight_source/game_routes.txt.
-- The routes the game itself reported (/mzroutes) are ground truth: given the flight points the capturing
-- character had found, the planner (flights only, one ticket) must pick the same stops.
useTestDistances()
addon.World:Build()

local blocks = {
""" + "\n".join(body) + """
}

local ali = makeCtx({ faction = "Alliance" })
local checked, wrong = 0, 0
for _, block in ipairs(blocks) do
    local found = {}
    for _, id in ipairs(block.found) do found[id] = true end
    ali.flightNodeFound = function(id) return found[id] == true end
    local graph = addon.TravelGraph:Build(ali)
    local flightsOnly = { adjacency = {}, anywhere = {} }              -- the game's routes are flights
    for id, steps in pairs(graph.adjacency) do
        for _, step in ipairs(steps) do
            if step.method == "taxi" then
                flightsOnly.adjacency[id] = flightsOnly.adjacency[id] or {}
                table.insert(flightsOnly.adjacency[id], step)
            end
        end
    end
    for _, stops in ipairs(block.routes) do
        local result = addon.Pathfinder:FindPath(flightsOnly, stops[1], stops[#stops], nil, { oneTicket = true })
        local ours = { stops[1] }
        for _, step in ipairs(result and result.steps or {}) do ours[#ours + 1] = step.to end
        checked = checked + 1
        if table.concat(ours, ">") ~= table.concat(stops, ">") then
            wrong = wrong + 1
            check(false, "the game flew " .. table.concat(stops, ">") .. " but we plan " .. table.concat(ours, ">"))
        end
    end
end
check(checked > 40, "the captured routes were checked: " .. checked)
check(wrong == 0, "the planner picks the game's route every time")
"""
    (ROOT / "tests" / "test_gameroutes.lua").write_text(text, encoding="utf-8")


def leg_times(taxi, tickets, positions):
    """({(a, b, faction): seconds}, [estimated keys])."""
    def distance(a, b):
        (_, x0, y0), (_, x1, y1) = positions[a], positions[b]
        return math.hypot(x1 - x0, y1 - y0)

    known = {}
    for (a, b, f) in taxi:
        t = tickets.get((a, b, f), tickets.get((b, a, f)))     # a missing direction mirrors the other
        if t is not None:
            known[(a, b, f)] = t
    speed = {}
    for (a, b, f), t in known.items():
        speed.setdefault(positions[a][0], []).append(distance(a, b) / t)
    speed = {c: statistics.median(v) for c, v in speed.items()}
    times, estimated = dict(known), []
    for (a, b, f) in taxi:
        if (a, b, f) not in times:
            times[(a, b, f)] = round(distance(a, b) / speed[positions[a][0]])
            estimated.append((a, b, f))
    return times, estimated


def reconstruction(legs, tickets, faction):
    """How well chaining these legs (with the chain saving) reproduces the original ticket times."""
    adjacency = {}
    for (a, b, f), t in legs.items():
        if f == faction:
            adjacency.setdefault(a, []).append((b, t))

    def shortest(source):
        best, heap, out = {(source, 0): 0}, [(0, source, 0)], {}
        while heap:
            d, u, chained = heapq.heappop(heap)
            if best.get((u, chained), 1e18) < d:
                continue
            out[u] = min(out.get(u, 1e18), d)
            for v, t in adjacency.get(u, []):
                nd = d + t * (1 - (CHAIN_SAVING if chained else 0))
                if nd < best.get((v, 1), 1e18):
                    best[(v, 1)] = nd
                    heapq.heappush(heap, (nd, v, 1))
        return out

    errors, unreachable = [], 0
    for a in sorted({x for (x, _, f) in legs if f == faction}):
        reach = shortest(a)
        for (x, b, f), t in tickets.items():
            if x != a or f != faction:
                continue
            if b not in reach:
                unreachable += 1
            else:
                errors.append(reach[b] / t - 1)
    return errors, unreachable


def main():
    names = read_names()
    tickets = read_tickets()
    taxi = read_taxipath()
    missing_nodes = sorted({x for (a, b, f) in taxi for x in (a, b) if x not in names})
    taxi = {k: v for k, v in taxi.items() if k[0] in names and k[1] in names}
    times, estimated = leg_times(taxi, tickets, read_positions())

    report = []
    if missing_nodes:
        report.append(f"flight points in the game table that we have no node for: {missing_nodes}")
    blocks = read_blocks(names)
    write_route_test(blocks)
    for stops in read_truth(names):                              # what the game reported must be in its table
        for a, b in zip(stops, stops[1:]):
            if not any((a, b, f) in taxi for f in ("Alliance", "Horde")):
                report.append(f"WARNING: game-reported leg {names[a]} -> {names[b]} is not in the table")

    lines = []
    for faction in ("Alliance", "Horde"):
        legs = {k: v for k, v in times.items() if k[2] == faction}
        errors, unreachable = reconstruction(times, tickets, faction)
        within = lambda p: sum(1 for e in errors if abs(e) <= p) / len(errors)
        report.append(f"{faction}: {len(legs)} directed legs, {sum(1 for k in estimated if k[2] == faction)} with an "
                      f"estimated time; rebuilt vs {len(errors)} InFlight tickets: within 5% {within(.05):.0%}, "
                      f"10% {within(.10):.0%}, 20% {within(.20):.0%}, median {statistics.median(errors):+.1%}, "
                      f"{unreachable} unreachable")
    for k in sorted(estimated):
        report.append(f"  estimated {times[k]}s: {names[k[0]]} -> {names[k[1]]} ({k[2]})")

    for (a, b, f), t in sorted(times.items(), key=lambda kv: (kv[0][2], int(kv[0][0][5:]), int(kv[0][1][5:]))):
        note = " (estimated from distance)" if (a, b, f) in estimated else ""
        lines.append(f'    {{ from = "{a}", to = "{b}", method = "taxi", cost = {t}, fare = {taxi[(a, b, f)]}, '
                     f'requirements = {{ faction = "{f}" }} }}, -- {names[a]} -> {names[b]}{note}')

    header = '''-- Flights.lua (Forever) -- GENERATED by tools/gen_flights.py, do not hand-edit.
--
-- The classic flight network as SINGLE LEGS: one flight master to the next, with the leg's own time.
-- The planner chains legs itself, over the flight points the player has found (FlightKnowledge), and
-- takes addon.FLIGHT_CHAIN_SAVING (a fraction) off each extra leg flown through, since a through-ticket
-- doesn't land and take off again. Consecutive flights are shown as one ticket.
--
-- Why not whole tickets: a ticket flies through other flight points, and which ones depends on
-- which points the flyer had found, so the same ticket takes a different route and time for a player
-- with a different set. Leg times don't have that problem.
--
-- Sources: which pairs are legs, and each leg's `fare` (copper, before any discount), is the game's own
-- flight table (Classic Era TaxiPath, tools/flight_source/taxipath_classic_1.15.9.txt); the times are
-- InFlight's per-direction ticket times for those pairs (tools/flight_source/inflight_tickets.lua).
-- Directions are separate: they differ. A ticket costs the sum of its legs' fares.

local addonName, addon = ...

addon.Edges = addon.Edges or {}

for _, edge in ipairs({
'''
    footer = "\n}) do\n    table.insert(addon.Edges, edge)\nend\n"
    (DATA / "Flights.lua").write_text(header + "\n".join(lines) + footer, encoding="utf-8")
    print("\n".join(report))
    print(f"wrote Data/Forever/Flights.lua: {len(lines)} legs")


if __name__ == "__main__":
    main()
