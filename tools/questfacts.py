"""Look up quest facts from the cached QuestieDB sources.

    python -I tools/questfacts.py quest 7
    python -I tools/questfacts.py zone Elwynn --flavor classic

Forever uses its own base and player trace additions. Missing fields and
unobserved eligibility are left for published sources and in-game verification.
"""
import argparse
import json
import re
from pathlib import Path
from urllib.request import urlopen

from lupa.lua51 import LuaRuntime, lua_type


REV = "0f7d8adc92b28ac6594f4ad8745257f4d9784edf"
ROOT = Path(__file__).resolve().parent
CACHE = ROOT / ".cache" / f"questiedb-{REV[:7]}"
BASE = f"https://raw.githubusercontent.com/Questie/QuestieDB/{REV}/"
ZONES = {
    "Northshire": (9, 1429), "Elwynn": (12, 1429), "Westfall": (40, 1436),
    "Redridge": (44, 1433), "Stormwind": (1519, 1453), "Duskwood": (10, 1431),
    "Dun Morogh": (1, 1426), "Loch Modan": (38, 1432), "Wetlands": (11, 1437),
    "Darkshore": (148, 1439), "Teldrassil": (141, 1438),
}


def download(path):
    CACHE.mkdir(parents=True, exist_ok=True)
    file = CACHE / Path(path).name
    if not file.exists():
        with urlopen(BASE + path, timeout=30) as response:
            data = response.read()
        temp = file.with_suffix(".part")
        temp.write_bytes(data)
        temp.replace(file)
    return file.read_text(encoding="utf-8-sig")


def lua_reader():
    lua = LuaRuntime(register_eval=False, register_builtins=False, max_memory=96 * 1024 * 1024)
    read = lua.eval("""function(source, env)
        local chunk = assert(loadstring(source))
        setfenv(chunk, env)
        debug.sethook(function() error("data exceeded the instruction limit") end, "", 10000000)
        local ok, result = pcall(chunk)
        debug.sethook()
        assert(ok, result)
        return result
    end""")
    return lua, read


def to_python(value):
    if lua_type(value) == "table":
        return {key: to_python(item) for key, item in value.items()}
    return value


def entity(lu, read, flavor, kind):
    src = download(f"data/{flavor.title()}/{flavor}{kind.title()}DB.lua")
    key_block = re.search(rf"QuestieDB\.{kind}Keys = (\{{.*?\n\}})", src, re.S)
    data = re.search(rf"QuestieDB\.{kind}Data = \[\[(return \{{.*?\n\}})\]\]", src, re.S)
    if not key_block or not data:
        raise ValueError(f"{flavor} {kind} layout changed at {REV}")
    keys = to_python(read("return " + key_block[1], lu.table()))
    rows = read(data[1], lu.table())
    traces = None
    if flavor == "forever":
        name = "Npc" if kind == "npc" else kind.title()
        src = download(f"src/corrections/Forever/traces/forever{name}Traces.lua")
        data = re.search(r"(return \{.*?\n    \})\s*end\s*$", src, re.S)
        if not data:
            raise ValueError(f"Forever {kind} trace layout changed at {REV}")
        env = lu.table()
        fields = set(re.findall(rf"{kind}Keys\.(\w+)", data[1]))
        env[kind + "Keys"] = lu.table_from({field: field for field in fields})
        traces = read(data[1], env)
    return keys, rows, traces


def record(source, id_):
    keys, rows, traces = source
    row = rows[id_]
    result = {key: to_python(row[index]) for key, index in keys.items()
              if row is not None and row[index] is not None}
    trace = traces[id_] if traces is not None else None
    if trace:
        for key, value in trace.items():
            field = key.removesuffix("_add")
            if field != key and field in result:
                continue
            result[field] = to_python(value)
    return result


def endpoints(value, npcs, objects):
    result = []
    maps = {area: map_id for area, map_id in ZONES.values()}
    for kind, source in enumerate((npcs, objects, None), 1):
        for id_ in value.get(kind, {}).values():
            entry = record(source, id_) if source else {}
            positions = [
                {"area": area, "map": maps.get(area), "x": xy[1], "y": xy[2]}
                for area, coords in entry.get("spawns", {}).items()
                for xy in coords.values()
            ]
            result.append({"kind": ("npc", "object", "item")[kind - 1], "id": id_,
                           "name": entry.get("name"), "positions": positions})
    return result


def lookup(quests, npcs, objects, id_):
    q = record(quests, id_)
    if not q:
        return None
    q["id"] = id_
    q["start"] = endpoints(q.get("startedBy", {}), npcs, objects)
    q["finish"] = endpoints(q.get("finishedBy", {}), npcs, objects)
    return q


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("quest", "zone"))
    parser.add_argument("value")
    parser.add_argument("--flavor", choices=("classic", "forever"), default="forever")
    args = parser.parse_args()
    lu, read = lua_reader()
    quests, npcs, objects = (entity(lu, read, args.flavor, kind) for kind in ("quest", "npc", "object"))
    if args.command == "quest":
        result = lookup(quests, npcs, objects, int(args.value))
        if not result:
            parser.error(f"quest {args.value} is absent from {args.flavor} source and trace records")
    else:
        name = args.value.casefold()
        area = next((area for zone, (area, _) in ZONES.items() if zone.casefold() == name), None)
        if area is None:
            parser.error("known zones: " + ", ".join(ZONES))
        _, base, traces = quests
        ids = set(base.keys())
        if traces is not None:
            ids.update(traces.keys())
        result = []
        alliance = 0x10000004D
        for id_ in ids:
            q = record(quests, id_)
            if q.get("requiredRaces") and not q["requiredRaces"] & alliance:
                continue
            start = endpoints(q.get("startedBy", {}), npcs, objects)
            if q.get("zoneOrSort") == area or any(
                p["area"] == area for entry in start for p in entry["positions"]
            ):
                result.append({"id": id_, "level": q.get("questLevel"), "min": q.get("requiredLevel"),
                               "name": q.get("name"), "start": [entry["name"] for entry in start]})
        result.sort(key=lambda q: (q["level"] or 0, q["id"]))
    print(json.dumps(result, indent=2, ensure_ascii=True))


if __name__ == "__main__":
    main()
