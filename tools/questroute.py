"""Validate the shipped routes or turn recorder observations into draft steps.

    python tools/questroute.py audit
    python tools/questroute.py import [SavedVariables-file ...]
"""
import argparse
import json
import math
import os
from itertools import product
from pathlib import Path


QUEST_TYPES = {"accept", "complete", "turnin"}
TRAVEL_TYPES = {"goto", "fly", "getfp", "sethearth", "hearth", "boat"}
STEP_TYPES = QUEST_TYPES | TRAVEL_TYPES | {"train", "buy", "use", "grind", "dungeon", "note"}
STEP_FIELDS = {"type", "bind", "item", "startItem", "breadcrumb", "quest", "name", "npc", "map", "x", "y", "level", "min", "text",
               "class", "race", "optional", "dungeon", "chain", "forever", "objectives", "objectiveIndex", "flight", "suggest", "also"}
ROOT = Path(__file__).resolve().parent.parent
ROUTE = ROOT / "QuestData.lua"
CLASS_ROUTE = ROOT / "QuestClassData.lua"


def matches(value, token):
    """A section/step filter: None = everyone, a token, or a list of tokens."""
    return value is None or (token in value if isinstance(value, list) else token == value)


def audit(data, ref, cap=20):
    messages = []

    def fail(where, message):
        messages.append(("QUESTS", "error", f"{where}: {message}"))

    def warn(where, message):
        messages.append(("QUESTS", "warn", f"{where}: {message}"))

    def ascii_text(value):
        return isinstance(value, str) and value.isascii() and all(32 <= ord(c) < 127 for c in value)

    def coord(value):
        return type(value) in (float, int) and 0 <= value <= 100

    game = ref.get("quests")
    if not game:
        return [("QUESTS", "error", "client reference is missing quest data")]
    ids, maps, flights = set(game["ids"]), game["maps"], set(game["flights"])
    for faction, route in data.items():
        sections = route["sections"]
        route_quests = {step.get("quest") for section in sections for step in section["steps"] if step.get("quest")}
        known_sections = {section["id"] for section in sections}
        route_sections = {section["id"] for section in sections if not section.get("side")}
        if len(known_sections) != len(sections):
            fail(faction, "duplicate section IDs")
        for race, start in route["starts"].items():
            if not any(s["id"] == start and matches(s.get("start"), race) for s in sections):
                fail(faction, f"{race} start does not match a section")
        for key, extent in route.get("extents", {}).items():
            mapped = maps.get(key, {})
            if extent != [mapped.get("width"), mapped.get("height")]:
                fail(faction, f"map {key} extents differ from the client")

        def check_suggestions(suggestions, section_id, where):
            if not isinstance(suggestions, list) or not suggestions or any(
                not isinstance(target, str) or target not in route_sections or target == section_id
                for target in suggestions
            ):
                fail(where, "suggest must list other leveling section IDs")

        rows, main_rows, alternates = [], [], {}
        for section in sections:
            label = section["id"]
            if not ascii_text(section.get("title")) or not ascii_text(label):
                fail(faction, "section needs an ASCII ID and title")
            if str(section.get("zone")) not in maps:
                fail(label, "unknown section map")
            if type(section.get("verified")) is not bool:
                fail(label, "verified must be a boolean")
            if "alternate" in section and (type(section["alternate"]) is not bool or section.get("side")):
                fail(label, "alternate must be a boolean on a leveling section")
            if "suggest" in section:
                check_suggestions(section["suggest"], label, label)
            start, end = section["levels"]
            if not 1 <= start <= end <= 60:
                fail(label, "section levels must be in order and in 1-60")
            if not section.get("sources"):
                warn(label, "no sources listed")
            previous = None
            level = start
            for i, step in enumerate(section["steps"], 1):
                where = f"{label} step {i}"
                kind, quest = step.get("type"), step.get("quest")
                if kind not in STEP_TYPES or set(step) - STEP_FIELDS:
                    fail(where, f"unknown action or fields ({kind}, {sorted(set(step) - STEP_FIELDS)})")
                    continue
                if not step.get("text") or not ascii_text(step["text"]):
                    fail(where, "step text must be non-empty printable ASCII")
                if "suggest" in step:
                    check_suggestions(step["suggest"], label, where)
                if "also" in step:
                    also = step["also"]
                    if not isinstance(also, list) or not also or any(
                        type(id_) is not int or id_ not in route_quests or id_ == quest for id_ in also
                    ) or len(set(also)) != len(also):
                        fail(where, "also must list distinct other route quest IDs")
                follow = step.get("breadcrumb")
                if follow is not None and follow not in route_quests:
                    fail(where, f"breadcrumb follow-up {follow} isn't a quest in the route")
                item = step.get("item")
                if item is not None and not (type(item) is int and item > 0 or ascii_text(item)):
                    fail(where, "item must be an item ID or an ASCII item name")
                if "startItem" in step and (not quest or type(step["startItem"]) is not int or step["startItem"] <= 0):
                    fail(where, "startItem must be a positive item ID on a quest step")
                if kind in ("sethearth", "hearth") and not step.get("bind"):
                    warn(where, f"{kind} step has no bind town (GetBindLocation name)")
                for key in ("name", "npc", "flight", "dungeon", "bind"):
                    if key in step and not ascii_text(step[key]):
                        fail(where, f"{key} must be printable ASCII")
                for key in ("level", "min"):
                    if key in step and (type(step[key]) is not int or not 1 <= step[key] <= 60):
                        fail(where, f"{key} must be an integer from 1 to 60")
                for key in ("optional", "forever"):
                    if key in step and type(step[key]) is not bool:
                        fail(where, f"{key} must be a boolean")
                for key in ("class", "race"):
                    value = step.get(key)
                    if value is not None and not (ascii_text(value) or isinstance(value, list) and all(map(ascii_text, value))):
                        fail(where, f"{key} must be a token or a list of tokens")
                if "objectives" in step and not (isinstance(step["objectives"], list)
                                                  and all(map(ascii_text, step["objectives"]))):
                    fail(where, "objectives must be a list of ASCII labels")
                if "objectiveIndex" in step:
                    index = step["objectiveIndex"]
                    if kind != "complete" or type(index) is not int or index < 1:
                        fail(where, "objectiveIndex must be a positive quest log objective index on a complete step")
                chain = step.get("chain", [])
                if not isinstance(chain, list) or any(type(q) is not int or q not in ids for q in chain):
                    fail(where, "chain has an unknown prerequisite")
                    continue
                if (quest is not None or kind in QUEST_TYPES) and (type(quest) is not int or quest not in ids):
                    fail(where, f"unknown quest ID {quest}")
                    continue
                if kind in {"fly", "getfp"} and step.get("flight") not in flights:
                    fail(where, f"unknown flight path {step.get('flight')!r}")
                map_id = step.get("map")
                if map_id is not None and str(map_id) not in maps:
                    fail(where, f"unknown map {map_id}")
                if "x" in step or "y" in step:
                    x, y = step.get("x"), step.get("y")
                    if not (map_id and coord(x) and coord(y)):
                        fail(where, "coordinates require a map and two percentages in 0-100")
                    else:
                        extent = maps.get(str(map_id), {})
                        if previous and previous["map"] == map_id and extent.get("width"):
                            distance = math.hypot((x - previous["x"]) * extent["width"] / 100,
                                                  (y - previous["y"]) * extent["height"] / 100)
                            if distance >= 1250 and kind not in TRAVEL_TYPES and previous["type"] not in TRAVEL_TYPES:
                                warn(where, f"{round(distance)} yd from the prior waypoint with no travel step")
                        previous = step
                elif kind in TRAVEL_TYPES:
                    previous = None
                quest_level = step.get("level")
                if kind == "grind" and type(quest_level) is int:
                    level = max(level, quest_level)
                if kind == "accept" and type(quest_level) is int:
                    if quest_level > level + 5:
                        warn(where, f"{step.get('name')} is more than 5 levels above the section's current target")
                    if quest_level <= level - (5 + level // 10):
                        warn(where, f"{step.get('name')} is grey for level {level}")
                rows.append((section, step, where))
                path = alternates.setdefault(label, []) if section.get("alternate") else main_rows
                path.append((section, step, where))

        # Run the actual filtered route for each player shape. Dungeon steps may
        # appear on top of the main route, so also check the combined log.
        # Check shared sections on a character who has no published racial start.
        races = {""} | set(route["starts"])
        classes = {None}
        for section, step, _ in rows:
            if isinstance(section.get("class"), str):
                classes.add(section["class"])
            for key, values in (("race", races), ("class", classes)):
                rule = step.get(key)
                if isinstance(rule, list):
                    values.update(v for v in rule if isinstance(v, str))
                elif isinstance(rule, str):
                    values.add(rule)
        for race in sorted(races or {""}):
            for class_ in sorted(classes, key=lambda token: token or ""):
                for path, dungeons in product([main_rows, *alternates.values()], (False, True)):
                    active, finished = set(), set()
                    for section, step, where in path:
                        if not (matches(section.get("start"), race) and matches(step.get("race"), race)
                                and matches(section.get("class"), class_) and matches(step.get("class"), class_)) or (step.get("optional") and not dungeons):
                            continue
                        kind, quest = step["type"], step.get("quest")
                        if kind == "accept":
                            for required in step.get("chain", []):
                                if required not in finished:
                                    fail(where, f"quest {quest} accepted before prerequisite {required} was turned in")
                            if quest in active or quest in finished:
                                fail(where, f"quest {quest} accepted twice")
                            active.add(quest)
                            if len(active) > cap:
                                fail(where, f"quest log has {len(active)} quests (cap {cap})")
                        elif kind in {"complete", "turnin"}:
                            if quest not in active:
                                fail(where, f"{kind} for quest {quest} before its accept")
                            if kind == "turnin":
                                active.discard(quest)
                                finished.add(quest)
    return list(dict.fromkeys(messages))


def recorder_rows(file):
    from lupa.lua51 import LuaRuntime

    if file.stat().st_size > 8 * 1024 * 1024:
        raise ValueError(f"{file} exceeds the SavedVariables size limit")
    lua = LuaRuntime(register_eval=False, register_builtins=False, max_memory=64 * 1024 * 1024)
    reader = lua.eval("""function(source)
        local env = {}
        local chunk = assert(loadstring(source))
        setfenv(chunk, env)
        debug.sethook(function() error("saved variables exceeded instruction limit") end, "", 10000000)
        local ok, err = pcall(chunk)
        debug.sethook()
        assert(ok, err)
        return env.LevelingCodexDB and env.LevelingCodexDB.rec
    end""")
    rows = reader(file.read_text(encoding="utf-8-sig"))
    if rows:
        for i in range(1, len(rows) + 1):
            yield dict(rows[i].items())


def draft_steps(rows):
    detail = {}
    for row in rows:
        kind, quest = row.get("type"), row.get("quest")
        if kind == "detail":
            if quest:
                detail[quest] = row
            continue
        if kind not in STEP_TYPES:
            continue
        if kind == "accept" and quest in detail:
            offer = detail.pop(quest)
            row = {**row, **{k: v for k, v in offer.items() if k != "type" and v}}
        draft = {k: v for k, v in row.items() if k in STEP_FIELDS and v != ""}
        if kind in {"fly", "getfp"} and row.get("name"):
            draft["flight"] = row["name"]
        for key in ("x", "y"):
            if key in draft:
                draft[key] = round(draft[key], 2)
        draft["text"] = draft.get("text") or "Review this observation and write the route instruction."
        yield draft


def main():
    from gamedata import load_lua_global, load_reference

    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    audit_parser = commands.add_parser("audit")
    audit_parser.add_argument("--cap", type=int, default=20)
    importer = commands.add_parser("import")
    importer.add_argument("files", nargs="*", type=Path)
    args = parser.parse_args()
    if args.command == "audit":
        if args.cap < 1:
            parser.error("--cap must be positive")
        data = load_lua_global([ROUTE, CLASS_ROUTE], "LevelingCodexQuests")
        results = audit(data, load_reference(), args.cap)
        for _, severity, message in results:
            print(f"{severity}: {message}")
        if any(severity == "error" for _, severity, _ in results):
            return 1
        print(f"Route audit passed ({sum(len(s['steps']) for route in data.values() for s in route['sections'])} steps).")
    else:
        wow = Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "World of Warcraft"
        files = args.files or sorted(wow.glob("_forever_/WTF/Account/*/SavedVariables/LevelingCodex.lua"))
        if not files:
            parser.error("no recorder files found; pass the path to LevelingCodex.lua")
        drafts = [step for file in files for step in draft_steps(recorder_rows(file))]
        print(json.dumps(drafts, indent=2, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
