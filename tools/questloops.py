"""Loop check for the quest routes: redundant hub visits and zig-zags.

    python tools/questloops.py HORDE ORC,TAUREN [WARRIOR]
    python tools/questloops.py ALLIANCE HUMAN

Walks the main route (no side or alternate sections) for each race and class and groups
consecutive steps at one spot into visits. It reports:

- hub visits: a visit made only of pickups and turn-ins that could all have been done at an
  earlier visit within 45 yards (turn-ins ready, pickups' prerequisites turned in, the character
  at the quest's minimum level by the section's level range), when it costs extra walking;
- zig-zags: an objective area the route leaves and comes back to (within 150 yards), when its
  quest was already in the log on the first pass and the return costs more than 300 yards.

Level gates come only from the step's `min` and section levels, so a pickup that the game
offers later than that (or a quest kept out of the log on purpose) can still show up: review
each line. Walking distance per section is printed as a baseline.
"""
import argparse
import math

from gamedata import load_lua_global
from questroute import ROUTES, matches

NEAR, AREA = 45, 150
TRAVEL = {"fly", "boat", "hearth"}


def check(route, race, class_):
    extents = {int(k): v for k, v in route["extents"].items()}

    def dist(a, b):
        if not a or not b or a[0] != b[0] or a[0] not in extents:
            return None
        width, height = extents[a[0]]
        return math.hypot((a[1] - b[1]) * width / 100, (a[2] - b[2]) * height / 100)

    rows = []
    for section in route["sections"]:
        if section.get("side") or section.get("alternate") or not matches(section.get("start"), race):
            continue
        # Optional steps and item-started quests (shown only with the item) are not part of the walk.
        steps = [s for s in section["steps"] if matches(s.get("race"), race) and matches(s.get("class"), class_)
                 and not s.get("optional") and not s.get("startItem")]
        low, high = section["levels"]
        for i, step in enumerate(steps):
            rows.append((section["id"], section["steps"].index(step) + 1, step,
                         low + (high - low) * i / max(1, len(steps) - 1)))
    accepted, done, last_complete = {}, {}, {}
    for k, (_, _, step, _) in enumerate(rows):
        quest = step.get("quest")
        if step["type"] == "accept":
            accepted.setdefault(quest, k)
        elif step["type"] == "turnin":
            done.setdefault(quest, k)
        elif step["type"] == "complete":
            last_complete[quest] = k

    visits, current = [], None
    walked, previous = {}, None
    for k, (section_id, _, step, _) in enumerate(rows):
        pos = (step.get("map"), step.get("x"), step.get("y")) if step.get("x") is not None else None
        if pos and previous and step["type"] not in TRAVEL and dist(previous, pos) is not None:
            walked[section_id] = walked.get(section_id, 0) + dist(previous, pos)
        if step["type"] in TRAVEL or not pos:
            previous = None if step["type"] in TRAVEL else previous
            if current:
                visits.append(current)
                current = None
            continue
        previous = pos
        if current and dist(current["pos"], pos) is not None and dist(current["pos"], pos) <= NEAR:
            current["rows"].append(k)
        else:
            if current:
                visits.append(current)
            current = {"pos": pos, "rows": [k]}
    if current:
        visits.append(current)

    def possible(k, at, level):
        step = rows[k][2]
        quest = step.get("quest")
        if step["type"] == "turnin":
            return accepted.get(quest, at) < at and last_complete.get(quest, -1) < at
        if step["type"] == "accept":
            return (step.get("min") or 0) <= level + 0.5 and all(done.get(c, at) < at for c in step.get("chain") or [])
        if step["type"] == "complete":
            return accepted.get(quest, at) < at
        return False

    def cost(index, pos):
        before = visits[index - 1]["pos"] if index > 0 else None
        after = visits[index + 1]["pos"] if index + 1 < len(visits) else None
        legs = dist(before, pos), dist(pos, after), dist(before, after)
        return None if None in legs else legs[0] + legs[1] - legs[2]

    findings = []
    for index, visit in enumerate(visits):
        kinds = {rows[k][2]["type"] for k in visit["rows"]}
        zigzag = "complete" in kinds
        for earlier_index, earlier in enumerate(visits[:index]):
            gap = dist(earlier["pos"], visit["pos"])
            if gap is None or gap > (AREA if zigzag else NEAR) or (zigzag and index - earlier_index < 3):
                continue
            at = earlier["rows"][-1] + 1
            if all(possible(k, at, rows[earlier["rows"][-1]][3]) for k in visit["rows"]):
                extra = cost(index, visit["pos"])
                if extra is not None and extra > (300 if zigzag else 30):
                    first, seen = rows[visit["rows"][0]], rows[earlier["rows"][-1]]
                    what = ", ".join(f'{rows[k][2]["type"]} {rows[k][2].get("quest")}' for k in visit["rows"])
                    findings.append(f'{"zig-zag" if zigzag else "hub"}: {first[0]} step {first[1]} ({what}) '
                                    f'could be done at {seen[0]} step {seen[1]}; {round(extra)} yd extra')
            break
    return walked, findings


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("faction", choices=("ALLIANCE", "HORDE"))
    parser.add_argument("races", help="comma-separated race tokens, e.g. ORC,TAUREN,SCOURGE")
    parser.add_argument("classes", nargs="?", default="WARRIOR", help="comma-separated class tokens")
    args = parser.parse_args()
    route = load_lua_global(ROUTES, "LevelingCodexQuests")[args.faction]
    for race in args.races.split(","):
        for class_ in args.classes.split(","):
            walked, findings = check(route, race, class_)
            print(f"== {race} {class_}: {round(sum(walked.values()))} yd walked")
            for section_id, yards in walked.items():
                print(f"   {section_id}: {round(yards)} yd")
            for finding in findings:
                print("   " + finding)


if __name__ == "__main__":
    main()
