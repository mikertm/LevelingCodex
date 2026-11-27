"""Find turn-ins the route can reach without having you gather what they ask for.

    python -I tools/questgaps.py            (both factions)
    python -I tools/questgaps.py --vague    (also list step text such as "if you brought them")

For every turn-in of a quest whose quest database objectives name creatures, objects or items, the
route needs one of: an objective (`complete`) step for that quest, a `collect`/`buy` step for its
items, `ifReady` on the turn-in (it shows only once the quest log says the quest is ready), an
item that starts or comes with the quest (`startItem`, the quest's source item). Anything else is
listed: the route would stop at a hand-in with nothing to hand in. A few are items an earlier
step hands you (The Morrow Stone's stone, the Excavation Site relic): check each line. Also lists accepts whose quest
database prerequisite the route never turns in before them (review these: some are known
differences, see tools/audits). Needs the cached quest database (questfacts.py) and Lupa.
"""
import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import questfacts as qf  # noqa: E402
from gamedata import load_lua_global  # noqa: E402
from questroute import ROUTES  # noqa: E402

VAGUE = re.compile(r"\bif you (brought|have|got|found|kept|carry|picked)\b|\bif you can spare\b|\buse next if\b|\bif short\b", re.I)


def objectives(record):
    out = []
    for kind, entries in (record.get("objectives") or {}).items():
        if isinstance(entries, dict):
            out += [(int(kind), e[1]) for e in entries.values() if isinstance(e, dict) and 1 in e]
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vague", action="store_true")
    args = parser.parse_args()
    data = load_lua_global(ROUTES, "LevelingCodexQuests")
    lu, read = qf.lua_reader()
    quests = qf.entity(lu, read, "forever", "quest")
    items = qf.entity(lu, read, "forever", "item")
    found = 0
    for faction, route in data.items():
        rows = [(section, step) for section in route["sections"] for step in section["steps"]]
        complete, gathered, done = set(), set(), {}
        for i, (_, step) in enumerate(rows):
            quest, kind = step.get("quest"), step["type"]
            if kind == "complete" and quest:
                complete.add(quest)
            if kind == "turnin" and quest:
                done.setdefault(quest, i)
            if step.get("item"):  # an item a step has you use is in your bags by then
                gathered.add(step["item"])
            if kind in ("collect", "buy"):
                gathered.add(step.get("item"))
                gathered.update(p[0] for p in step.get("items") or [])
        for i, (section, step) in enumerate(rows):
            quest, kind, text = step.get("quest"), step["type"], step.get("text") or ""
            where = f"{faction} {section['id']} {kind} {quest or ''} {step.get('name') or ''}".rstrip()
            if args.vague and VAGUE.search(text):
                print(f"vague: {where}: {text}")
            if not quest:
                continue
            record = qf.record(quests, quest)
            if not record:
                continue
            if kind == "turnin" and not step.get("ifReady") and quest not in complete:
                wanted = objectives(record)
                given = {step.get("startItem"), record.get("sourceItemId")}
                given.update(((record.get("startedBy") or {}).get(3) or {}).values())
                left = [(k, v) for k, v in wanted if not (k == 3 and (v in given or v in gathered))]
                if left:
                    found += 1
                    names = ", ".join((qf.record(items, v) or {}).get("name") or f"item {v}" if k == 3 else f"objective {k}:{v}"
                                      for k, v in left)
                    print(f"gap: {where}: nothing gathers {names}")
            if kind == "accept":
                pre = list((record.get("preQuestSingle") or {}).values())
                if pre and not any(done.get(p, len(rows)) < i for p in pre):
                    print(f"prerequisite: {where}: the quest database wants one of {pre} turned in first")
    print(f"{found} turn-ins without a way to gather their objectives.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
