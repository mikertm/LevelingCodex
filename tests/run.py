"""Headless test harness for Leveling Codex.

    python tests/run.py            # everything
    python tests/run.py -k WARRIOR # only runs whose name contains WARRIOR
    python tests/run.py -v         # also print data-lint warnings in full

Needs: pip install lupa   (uses lupa's bundled Lua 5.1, the WoW dialect)

Loads the files listed in LevelingCodex.toc into a mocked WoW: Forever client (tests/wowmock.lua)
for all 9 classes plus an unsupported one, with the full API and with optional APIs removed,
and runs tests/scenarios.lua. Fails on any Lua error, failed assertion, non-ASCII runtime text,
or macro over the client's limits.
"""
import multiprocessing
import os
import re
import sys
import time

try:
    import lupa.lua51 as lupa
except ImportError:
    sys.exit("lupa is missing: pip install lupa")

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
# Abilities you have without a trainer (weapon attacks): never flagged by the castsequence lint.
INNATE = {"Attack", "Shoot", "Auto Shot", "Throw"}
CLASSES = ["WARRIOR", "MAGE", "HUNTER", "ROGUE", "PRIEST", "PALADIN", "SHAMAN", "WARLOCK", "DRUID"]
UNSUPPORTED = "DEATHKNIGHT"

# Scenario sequences. Each runs in a fresh Lua state.
MAIN = ["makeTalentWindow:name", "talentBeforeLogin", "login", "talentBeforeLoginCheck", "levelups",
        "bannerMouse", "bannerTest", "browse", "everyButton", "settings", "minimap", "slash", "macros",
        "macroAutoUpdate", "combatLevelUp", "ownMacroSameName", "talentByName", "talentGuideOff", "talentFinderCost",
        "talentPooledButtons", "talentCloseDirect", "copyMacro", "scrollMemory", "gamepadClose", "binding",
        "noFalseLostNote"]
ICON = ["makeTalentWindow:icon:ClassTalentFrame", "login", "talentByIcon", "talentFinderCost", "talentCloseDirect",
        "lateTalentUI"]
PERSISTED = ["persist", "login", "browse", "settings", "bannerTest", "minimap"]
LOST = ["lost", "login", "lostSavedVariables"]

PERSISTED_DB = """
LevelingCodexDB = { theme = "codex", pad = "ps", toastPos = { "TOP", "TOP", 10, -100 }, toastScale = 1.3,
  windowPos = { "CENTER", "CENTER", 50, 0 }, windowScale = 0.9, minimapAngle = 45, quiet = true, noAutoMacros = true }
LevelingCodexCharDB = { made = { Fight = true } }
"""

# Saved variables didn't load, but last session's macros (made at level 25) are still there.
LOST_DB = """
MOCK.level = 25
MOCK.macros[1] = { name = "MyOwn", icon = 1, body = "/say mine", perChar = true }
for _, m in ipairs(LevelingCodexData[MOCK.class].macros) do
  if 25 >= m.lo and 25 <= m.hi then
    MOCK.macros[#MOCK.macros + 1] = { name = m.name, icon = 134400, body = m.body, perChar = true }
  end
end
"""


def toc_files():
    """Files the client would load, and problems with the .toc files."""
    problems = []
    a = open(os.path.join(ROOT, "LevelingCodex.toc"), "rb").read()
    b = open(os.path.join(ROOT, "LevelingCodex_Camelot.toc"), "rb").read()
    if a != b:
        problems.append("toc: LevelingCodex.toc and LevelingCodex_Camelot.toc differ")
    text = a.decode("utf-8")
    if "## Version: @project-version@" not in text:
        problems.append("toc: '## Version: @project-version@' missing")
    if "## Interface: 16001" not in text:
        problems.append("toc: '## Interface: 16001' missing")
    files = []
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            path = os.path.join(ROOT, line.replace("\\", os.sep))
            if not os.path.exists(path):
                problems.append("toc: listed file missing: " + line)
            files.append(path)
    return files, problems


def binding_bodies():
    """The Lua each key binding in Bindings.xml runs (the client loads the file by itself)."""
    import xml.etree.ElementTree as ET
    path = os.path.join(ROOT, "Bindings.xml")
    if not os.path.exists(path):
        return []
    root = ET.parse(path).getroot()
    return [(b.text or "").strip() for b in root.iter("Binding")]


def lua_path(p):
    return p.replace("\\", "/")


def new_state(cls, minimal, files, pre=None):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding=None)
    g = lua.globals()
    lua.execute(b'dofile("' + lua_path(os.path.join(HERE, "wowmock.lua")).encode() + b'")')
    setup = lua.eval(b"function(c, m) MOCK.setup({ class = c, minimal = m }) end")
    setup(cls.encode(), minimal)
    lua.execute(b'dofile("' + lua_path(os.path.join(HERE, "scenarios.lua")).encode() + b'")')
    if pre:
        lua.execute(pre.encode())
    bodies = binding_bodies()
    lua.execute(("BINDING_BODIES = {" + ",".join("%r" % b for b in bodies) + "}").encode())
    lua.execute(b"MOCK.snapshotGlobals()")
    for f in files:
        err = lua.eval(b"function(p) return MOCK.try(MOCK.loadFile, p) end")(lua_path(f).encode())
        if err:
            return lua, "load %s: %s" % (os.path.basename(f), err.decode("utf-8", "replace"))
    return lua, None


def run_sequence(name, cls, minimal, files, steps):
    pre = PERSISTED_DB if "persist" in steps else None
    lua, err = new_state(cls, minimal, files, pre)
    if not err and "lost" in steps:
        lua.execute(LOST_DB.encode())
    failures = []
    if err:
        return [err], []
    try_ = lua.eval(b"function(name, ...) return MOCK.try(SCENARIOS[name], ...) end")
    for step in steps:
        if step in ("persist", "lost"):
            continue
        parts = step.split(":")
        args = [p.encode() for p in parts[1:]]
        err = try_(parts[0].encode(), *args)
        if err:
            failures.append("%s: %s" % (parts[0], err.decode("utf-8", "replace")))
    lua.execute(b"MOCK.checkGlobals()")
    problems = [p.decode("utf-8", "replace") for p in lua.eval(b"MOCK.problems").values()]
    return failures, problems


# ---------------------------------------------------------------------------
# Static data checks (Data.lua)
# ---------------------------------------------------------------------------

def strip_rank(s):
    return re.sub(r"\s*\(Rank \d+\)\s*$", "", s).strip()


def data_checks():
    """Hard errors and soft warnings about the generated guide data."""
    errors, warnings = [], []
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    lua.execute(open(os.path.join(ROOT, "Data.lua"), encoding="utf-8").read())
    data = lua.globals().LevelingCodexData
    for cls in CLASSES:
        d = data[cls]
        if d is None:
            errors.append("data: no guide for " + cls)
            continue
        for key in ("spec", "guide", "plan", "train", "br", "macros"):
            if d[key] is None:
                errors.append("data %s: missing %s" % (cls, key))
        # talent plan: one point per level 10-60, ranks within max
        seen, ranks = {}, {}
        for p in d.plan.values():
            for lvl in range(p["from"], p["to"] + 1):
                if lvl in seen:
                    errors.append("data %s: two talents at level %d" % (cls, lvl))
                seen[lvl] = p.name
            ranks[p.name] = ranks.get(p.name, 0) + (p["to"] - p["from"] + 1)
            if ranks[p.name] > p.max:
                errors.append("data %s: %s gets %d points, max %d" % (cls, p.name, ranks[p.name], p.max))
            if not p.icon:
                errors.append("data %s: %s has no icon" % (cls, p.name))
        missing = [lvl for lvl in range(10, 61) if lvl not in seen]
        if missing:
            errors.append("data %s: no talent at levels %s" % (cls, missing))
        # when each spell is first available (trainer or talent)
        learned = {}
        for t in d.train.values():
            for s in t.spells.values():
                n = strip_rank(s)
                learned[n] = min(learned.get(n, 99), t.level)
        for p in d.plan.values():
            learned[p.name] = min(learned.get(p.name, 99), p["from"])
        for m in d.macros.values():
            where = "data %s: macro %s (%d-%d)" % (cls, m.name, m.lo, m.hi)
            if len(m.name.encode()) > 16:
                errors.append(where + ": name over 16 characters")
            if len(m.body.encode()) > 255:
                errors.append(where + ": body is %d characters (max 255)" % len(m.body.encode()))
            if any(ord(c) > 127 for c in m.body + m.name):
                errors.append(where + ": non-ASCII in name or body")
            # /castsequence stalls on a step you haven't learned yet
            for line in m.body.split("\n"):
                mt = re.match(r"/castsequence\s+(?:\[[^\]]*\]\s*)?(?:reset=\S+\s+)?(.*)", line)
                if not mt:
                    continue
                for step in mt.group(1).split(","):
                    step = re.sub(r"^\s*!?", "", step).strip()
                    if not step or step in INNATE:
                        continue
                    at = learned.get(step)
                    if at is None:
                        warnings.append(where + ": castsequence step '%s' is not in the trainer list or talent plan" % step)
                    elif at > m.lo:
                        warnings.append(where + ": castsequence step '%s' is only learned at %d, so the sequence stalls at levels %d-%d"
                                        % (step, at, m.lo, at - 1))
    return errors, warnings


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    args = sys.argv[1:]
    verbose = "-v" in args
    only = args[args.index("-k") + 1] if "-k" in args else None
    t0 = time.time()
    files, problems = toc_files()
    errors, warnings = data_checks()
    failed = list(problems) + list(errors)
    for p in problems + errors:
        print("FAIL", p)

    runs = []
    for minimal in (False, True):
        variant = "minimal" if minimal else "full"
        for cls in CLASSES + [UNSUPPORTED]:
            runs.append(("%s/%s/main" % (cls, variant), cls, minimal, MAIN))
        for cls in CLASSES:
            runs.append(("%s/%s/icon" % (cls, variant), cls, minimal, ICON))
        runs.append(("WARRIOR/%s/persisted" % variant, "WARRIOR", minimal, PERSISTED))
        runs.append(("MAGE/%s/persisted" % variant, "MAGE", minimal, PERSISTED))
        for cls in CLASSES:
            if not minimal:  # needs GetMacroInfo to recognise last session's macros
                runs.append(("%s/%s/lost-savedvars" % (cls, variant), cls, minimal, LOST))

    runs = [r for r in runs if not only or only in r[0]]
    jobs = [(name, cls, minimal, files, steps) for name, cls, minimal, steps in runs]
    with multiprocessing.Pool(min(len(jobs), os.cpu_count() or 4) or 1) as pool:
        results = pool.starmap(run_sequence, jobs)
    for (name, _, _, _), (failures, probs) in zip(runs, results):
        uniq = sorted(set(probs))
        status = "ok" if not failures and not uniq else "FAIL"
        print("%-4s %s" % (status, name))
        for f in failures:
            print("     " + f.replace("\n", "\n     "))
        for p in uniq[:15]:
            print("     problem: " + p)
        if len(uniq) > 15:
            print("     ... and %d more problems" % (len(uniq) - 15))
        if status != "ok":
            failed.append(name)

    if warnings:
        print("\n%d data warning(s) (not failures):" % len(warnings))
        for w in (warnings if verbose else warnings[:12]):
            print("  warn", w)
        if not verbose and len(warnings) > 12:
            print("  ... run with -v for all")
    print("\n%s: %d run(s) failed, %.1fs" % ("FAILED" if failed else "PASSED", len(failed), time.time() - t0))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
