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
        "talentPooledButtons", "talentCloseDirect", "talentPoints", "talentShape", "copyMacro", "scrollMemory",
        "gamepadClose", "binding", "debugReport", "artUsed", "talentTree", "traitLayoutTree", "macroMockups",
        "tabGlow", "keycapsLight", "bannerBuiltIn", "talentHintOnScreen", "talentTraceThemed", "controllerSides", "bannerFindsDisplay", "noFalseLostNote"]
ICON = ["makeTalentWindow:icon:ClassTalentFrame", "login", "talentByIcon", "talentFinderCost", "talentCloseDirect",
        "talentPoints", "talentShape", "lateTalentUI"]
# The client has every API but none of the Blizzard art files: everything falls back.
NOART = ["skills:BS;97;150,MI;140;225:professions", "makeTalentWindow:name", "login", "profTab", "levelups", "browse", "everyButton", "settings", "talentByName",
         "talentPoints", "talentShape", "copyMacro", "debugReport", "artUsed", "talentTree", "macroMockups"]
PERSISTED = ["persist", "login", "browse", "settings", "bannerTest", "minimap"]
LOST = ["lost", "login", "lostSavedVariables"]
# Gathering tracking (Find Herbs / Find Minerals) that the client drops at login and loading screens.
TRACK = ["trackKnown:herbs,minerals", "login", "trackRestored", "trackLoadingScreen", "trackDeath", "trackCombat",
         "trackOtherChoice", "trackSettingOff", "trackDebug"]
TRACK_MULTI = ["trackKnown:herbs,minerals,multi", "login", "trackRestored", "trackLoadingScreen"]
TRACK_KICK = ["trackKnown:herbsOn", "login", "trackKick", "trackLoadingScreen"]
TRACK_LEARN = ["trackKnown", "login", "trackLearn"]
# Professions: skills read through GetProfessions or only the classic skill list, or none at all.
PROF = ["skills:BS;97;150,MI;140;225:professions", "login", "profDebug", "profTab", "profTabCases", "profTabAfterTheme", "trainerReqs"]
PROF_LINES = ["skills:BS;97;150,MI;140;225:skilllines", "login", "profDebug", "profCollapsed"]
PROF_CLOSED = ["skills:BS;97;150,MI;140;225:skilllines", "skillsClosed", "login", "profCollapsedCold"]
PROF_NONE = ["login", "profNone"]
PROF_UPS = ["login", "profSkillUps", "profLevelTier"]
# The crafting window: classic trade skill calls, or retail's C_TradeSkillUI.
CRAFT = ["makeCraftWindow", "login", "craftTrace", "craftEventFirst", "craftNotLearned", "craftFiltered", "craftClassicStubs", "craftGrey",
         "craftScrolled", "craftRowBackoff", "craftOnHide", "craftHintClearsBar", "craftGuideOff", "craftSmelting", "craftSmeltingCases", "debugReport"]
CRAFT_RETAIL = ["makeCraftWindow:retail", "login", "craftTrace", "craftScrolled"]
# Forever's own crafting window: a ScrollBox list (anonymous pooled rows, no FauxScrollFrame).
CRAFT_SCROLLBOX = ["makeCraftWindow:scrollbox", "login", "craftShowItScrollBox"]

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


def art_files():
    """Every Blizzard art path Art.lua uses (for the no-art run)."""
    src = open(os.path.join(ROOT, "Art.lua"), encoding="utf-8").read()
    block = src[src.index("A.FILES = {"):]
    block = block[:block.index("\n}")]
    return [p.replace("\\\\", "\\") for p in re.findall(r'"(Interface[^"]+)"', block)]


def new_state(cls, minimal, files, pre=None, noart=False):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding=None)
    lua.execute(b'dofile("' + lua_path(os.path.join(HERE, "wowmock.lua")).encode() + b'")')
    setup = lua.eval(b"function(c, m, noart) MOCK.setup({ class = c, minimal = m, noArt = noart }); MOCK.noArt = noart end")
    setup(cls.encode(), minimal, lua.table_from([p.encode() for p in art_files()]) if noart else None)
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
    lua, err = new_state(cls, minimal, files, pre, noart=steps is NOART)
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
    prof_errors, prof_warnings = prof_shape_checks()
    game_errors, game_warnings = game_checks()
    return errors + prof_errors + game_errors, warnings + prof_warnings + game_warnings


PROF_KEYS = ("BLACKSMITHING", "MINING")


def prof_shape_checks():
    """ProfessionData.lua: the fields the addon reads, ASCII text, Mining steps naming real veins and smelts."""
    errors, warnings = [], []
    path = os.path.join(ROOT, "ProfessionData.lua")
    if not os.path.exists(path):
        return ["professions: ProfessionData.lua missing"], warnings
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import gamedata
    data = gamedata.load_profdata(path)
    if not isinstance(data, dict):
        return ["professions: ProfessionData.lua sets no LevelingCodexProfessions"], warnings

    def strings(x, where):
        if isinstance(x, str):
            if any(ord(c) > 127 for c in x):
                errors.append("professions %s: non-ASCII text: %s" % (where, x[:60]))
        elif isinstance(x, dict):
            for k, v in x.items():
                strings(v, where)
        elif isinstance(x, list):
            for v in x:
                strings(v, where)
    for key in PROF_KEYS:
        P = data.get(key)
        if not isinstance(P, dict):
            errors.append("professions: no %s" % key)
            continue
        strings(P, key)
        for f in ("name", "skillLine", "icon", "tiers", "steps"):
            if not P.get(f):
                errors.append("professions %s: missing %s" % (key, f))
        for t in P.get("tiers") or []:
            for f in ("name", "cap", "skill", "level", "where"):
                if t.get(f) in (None, ""):
                    errors.append("professions %s: tier %s missing %s" % (key, t.get("name"), f))
            # banner rows are one line (about 60 characters): a longer `where` needs a `short`
            if len(t.get("short") or t.get("where") or "") > 60:
                errors.append("professions %s: tier %s: banner text over 60 characters, add a short `short`" %
                              (key, t.get("name")))
        veins = {v.get("name") for v in P.get("veins") or []}
        smelts = {s.get("name") for s in P.get("smelt") or []}
        for s in P.get("steps") or []:
            where = "professions %s step %s-%s" % (key, s.get("from"), s.get("to"))
            if not isinstance(s.get("from"), int) or not isinstance(s.get("to"), int) or s["from"] >= s["to"]:
                errors.append(where + ": needs from < to")
            if key == "MINING":
                if not s.get("title"):
                    errors.append(where + ": missing title")
                for v in s.get("veins") or []:
                    if v not in veins:
                        errors.append(where + ": vein '%s' is not in the veins list" % v)
                for v in s.get("smelt") or []:
                    if v not in smelts:
                        errors.append(where + ": smelt '%s' is not in the smelt list" % v)
            else:
                for f in ("name", "spell", "icon", "yellow", "grey", "mats", "learn", "source"):
                    if s.get(f) in (None, ""):
                        errors.append(where + ": missing %s" % f)
        for v in P.get("veins") or []:
            for f in ("name", "skill", "ore", "icon", "zones"):
                if not v.get(f):
                    errors.append("professions %s vein %s: missing %s" % (key, v.get("name"), f))
    return errors, warnings


def game_checks():
    """Data.lua against what the game client says (tools/reference/forever.json, built by tools/gamedata.py).

    Errors: the guide asks for something the game won't allow (a talent that isn't in the tree, a point
    before its tab or prerequisite is open, a cast sequence step not learned yet, a rank that doesn't exist).
    Warnings: probably wrong (a level or icon that differs from the game)."""
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import gamedata
    if not os.path.exists(gamedata.REF):
        return [], ["game: no tools/reference/forever.json yet (python tools/gamedata.py build)"]
    ref = gamedata.load_reference()
    res = gamedata.audit(gamedata.load_data(), ref)
    tag = "game %s" % ref.get("build")
    errors = ["%s %s: %s" % (tag, c, m) for c, lvl, m in res if lvl == "error"]
    warnings = ["%s %s: %s" % (tag, c, m) for c, lvl, m in res if lvl == "warn"]
    # the profession part of the reference: a few recipes whose colours and reagents are known
    profs = ref.get("professions") or {}
    want = [("Blacksmithing", "Rough Sharpening Stone", 15, 55, [["Rough Stone", 1]]),
            ("Blacksmithing", "Runed Copper Belt", 85, 125, [["Copper Bar", 10]]),
            ("Mining", "Smelt Gold", 170, 185, [["Gold Ore", 1]]),
            ("Mining", "Smelt Bronze", 65, 115, [["Copper Bar", 1], ["Tin Bar", 1]])]
    for prof, name, y, g, mats in want:
        r = (profs.get(prof) or {}).get("recipes", {}).get(name)
        if not r or (r["yellow"], r["grey"], r["mats"]) != (y, g, mats):
            errors.append("%s reference: %s %s should be yellow %d grey %d %s, is %s" % (tag, prof, name, y, g, mats, r))
    # the client's own learn level (SkillLineAbility.MinSkillLineRank) where it sets one
    bs = (profs.get("Blacksmithing") or {}).get("recipes", {})
    if (bs.get("Rough Bronze Leggings") or {}).get("min") != 95 or "min" in (bs.get("Rough Sharpening Stone") or {"min": 0}):
        errors.append("%s reference: Rough Bronze Leggings should carry the client's min 95, Rough Sharpening Stone none" % tag)
    profdata = gamedata.load_profdata()
    if profdata:
        for p, lvl, m in gamedata.audit_professions(profdata, ref):
            (errors if lvl == "error" else warnings).append("%s %s: %s" % (tag, p, m))
    errors += tool_checks(gamedata, ref, profdata, tag)
    return errors, warnings


def tool_checks(gamedata, ref, profdata, tag):
    """tools/gamedata.py itself: what `update` and the daily pull request report cover."""
    import copy
    import tempfile
    errors = []
    # `update` and `audit` run the profession audit too, and the report lists its rows
    full = getattr(gamedata, "full_audit", None)
    res = full(ref) if full else []
    if not any(c in PROF_KEYS for c, _, _ in res):
        errors.append("%s tools: update/audit leave out the profession audit" % tag)
    fd, path = tempfile.mkstemp(suffix=".md")
    os.close(fd)
    try:
        gamedata.write_report(path, ref, ref, "nothing", [("BLACKSMITHING", "warn", "a profession row")])
        text = open(path, encoding="utf-8").read()
    finally:
        os.remove(path)
    if "BLACKSMITHING" not in text or "a profession row" not in text:
        errors.append("%s tools: the daily report leaves out the profession audit" % tag)
    # recipe names the game gives to more than one spell are kept, and a step naming one is flagged
    bs = (ref.get("professions") or {}).get("Blacksmithing") or {}
    coif = (bs.get("clashes") or {}).get("Golden Scale Coif") or []
    if 3503 not in coif or len(coif) < 2:
        errors.append("%s reference: Blacksmithing clashes should list Golden Scale Coif's spells (3503 and more), have %s" %
                      (tag, coif))
    # plans: the item that teaches a recipe (ItemEffect trigger 6) and the skill it asks for
    rec = bs.get("recipes") or {}
    for name, item, skill in (("Imperial Plate Belt", "Plans: Imperial Plate Belt", 240),
                              ("Heavy Mithril Pants", "Plans: Heavy Mithril Pants", 185)):
        if (rec.get(name) or {}).get("plan") != {"item": item, "skill": skill}:
            errors.append("%s reference: %s should be taught by %s (skill %d), has %s" %
                          (tag, name, item, skill, (rec.get(name) or {}).get("plan")))
    # learned with the profession (SkillLineAbility.AcquireMethod 1), and points per craft when not 1
    if not (rec.get("Rough Sharpening Stone") or {}).get("auto") or (rec.get("Rough Bronze Leggings") or {}).get("auto"):
        errors.append("%s reference: Rough Sharpening Stone should be marked auto (learned with Blacksmithing), "
                      "Rough Bronze Leggings not" % tag)
    if profdata:
        fake = copy.deepcopy(ref)
        fr = fake["professions"]["Blacksmithing"]["recipes"]
        fr["Rough Bronze Leggings"]["skillups"] = 2
        fr["Rough Sharpening Stone"].pop("auto", None)
        fr["Rough Grinding Stone"]["auto"] = True
        msgs = [m for _, lvl, m in gamedata.audit_professions(profdata, fake) if lvl == "warn"]
        for name, what in (("Rough Bronze Leggings", "2 points"), ("Rough Sharpening Stone", "trainer"),
                           ("Rough Grinding Stone", "learned with")):
            if not any(name in m and what in m for m in msgs):
                errors.append("%s tools: the audit doesn't flag %s (%s)" % (tag, name, what))
    if profdata:
        fake = copy.deepcopy(ref)
        fake["professions"]["Blacksmithing"]["recipes"]["Rough Bronze Leggings"]["plan"] = {"item": "Plans: X", "skill": 90}
        msgs = [m for _, lvl, m in gamedata.audit_professions(profdata, fake) if lvl == "warn" and "Rough Bronze Leggings" in m]
        if not any("Plans: X" in m and "trainer" in m for m in msgs):
            errors.append("%s tools: a 'trainer' step whose recipe comes from a plan isn't flagged" % tag)
        if not any("Plans: X" in m and "90" in m for m in msgs):
            errors.append("%s tools: a step whose learn level differs from its plan's skill isn't flagged" % tag)
    if profdata:
        fake = copy.deepcopy(ref)
        fake["professions"]["Blacksmithing"]["clashes"] = {"Rough Bronze Leggings": [2668, 999999]}
        if not any(lvl == "warn" and "Rough Bronze Leggings" in m and "999999" in m
                   for _, lvl, m in gamedata.audit_professions(profdata, fake)):
            errors.append("%s tools: a step naming a recipe the game has twice isn't flagged" % tag)
    return errors


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    args = sys.argv[1:]
    verbose = "-v" in args
    only = args[args.index("-k") + 1] if "-k" in args else None
    t0 = time.time()
    files, problems = toc_files()
    # "Interface\Icons" in Lua source is "InterfaceIcons" at runtime: paths need doubled backslashes
    for f in files:
        for n, line in enumerate(open(f, encoding="utf-8").read().splitlines(), 1):
            if re.search(r'"(Interface|Fonts)\\(?!\\)', line):
                problems.append("%s:%d: texture/font path needs \\\\ (doubled backslash)" % (os.path.basename(f), n))
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
        for cls in ("WARRIOR", "HUNTER", UNSUPPORTED):
            runs.append(("%s/%s/tracking" % (cls, variant), cls, minimal, TRACK))
        if not minimal:
            runs.append(("ROGUE/full/tracking-multi", "ROGUE", False, TRACK_MULTI))
            runs.append(("PRIEST/full/tracking-login-on", "PRIEST", False, TRACK_KICK))
            runs.append(("DRUID/full/tracking-learn", "DRUID", False, TRACK_LEARN))
        for cls in CLASSES:
            if not minimal:  # needs GetMacroInfo to recognise last session's macros
                runs.append(("%s/%s/lost-savedvars" % (cls, variant), cls, minimal, LOST))
        if not minimal:
            for cls in ("WARRIOR", "PRIEST", "DRUID"):
                runs.append(("%s/full/no-art" % cls, cls, False, NOART))
        runs.append(("WARRIOR/%s/prof" % variant, "WARRIOR", minimal, PROF))
        runs.append(("PALADIN/%s/prof-skilllines" % variant, "PALADIN", minimal, PROF_LINES))
        runs.append(("PALADIN/%s/prof-closed-heading" % variant, "PALADIN", minimal, PROF_CLOSED))
        runs.append(("MAGE/%s/prof-none" % variant, "MAGE", minimal, PROF_NONE))
        for cls in ("WARRIOR", "HUNTER"):
            runs.append(("%s/%s/prof-skillups" % (cls, variant), cls, minimal, PROF_UPS))
        runs.append(("WARRIOR/%s/craft" % variant, "WARRIOR", minimal, CRAFT))
        if not minimal:
            runs.append(("PRIEST/full/craft", "PRIEST", False, CRAFT))
            runs.append(("WARRIOR/full/craft-retail", "WARRIOR", False, CRAFT_RETAIL))
            runs.append(("WARRIOR/full/craft-scrollbox", "WARRIOR", False, CRAFT_SCROLLBOX))

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
