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
import glob
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
        "bannerMouse", "bannerTest", "browse", "everyButton", "settings", "minimap", "compartment", "slash", "macros",
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
PROF_UPS = ["login", "profSkillUps", "profLevelTier", "tailorSkillUps", "enchantSkillUps"]
# Enchanting: rods, Motes as Strange Dust, the disenchanting section and the bag scan.
ENCHANT = ["skills:EN;150;225:professions", "login", "enchantDebug", "enchantTab", "enchantTabCases", "enchantBags"]
ENCHANT_LINES = ["skills:EN;150;225:skilllines", "login", "enchantDebug"]
# Tailoring: the shopping list in cloth, the cloth section, the classic skill list.
TAILOR = ["skills:TA;150;225:professions", "login", "tailorDebug", "tailorTab", "tailorTabCases"]
TAILOR_ONLY = ["skills:TA;20;75:professions", "login", "tailorOnly"]
TAILOR_LINES = ["skills:TA;150;225:skilllines", "login", "tailorDebug"]
TAILOR_CLOSED = ["skills:TA;150;225:skilllines", "skillsClosed", "login", "tailorClosed"]
PROF_BANNER = ["login", "bannerOpensTarget"]
HERBALISM = ["skills:HE;1;75:professions:Alliance:Human", "login"]
# The controller: Forever's navigation, the Codex's own as a backup.
PAD = ["login", "gamepadClose", "padForever", "padThemeRebuild", "padTabs", "padCombatOpen", "padPickUp", "padBackup", "padBackupScroll",
       "padBackupCombat", "padCopyBox", "padForeverCombat", "padTalents", "padForeverFocus", "padForeverActive",
       "padStickKeepsFocus"]
# The crafting window: classic trade skill calls, or retail's C_TradeSkillUI.
CRAFT = ["makeCraftWindow", "login", "craftTrace", "craftEventFirst", "craftNotLearned", "craftFiltered", "craftClassicStubs", "craftGrey",
         "craftScrolled", "craftHandsOff", "craftRowBackoff", "craftOnHide", "craftHintClearsBar", "craftGuideOff", "craftSmelting", "craftSmeltingCases", "craftTailoring", "craftEnchanting", "debugReport"]
CRAFT_RETAIL = ["makeCraftWindow:retail", "login", "craftTrace", "craftScrolled", "craftHandsOff", "craftTailoring", "craftEnchanting"]
# Forever's own crafting window: a ScrollBox list (anonymous pooled rows, no FauxScrollFrame).
CRAFT_SCROLLBOX = ["makeCraftWindow:scrollbox", "login", "craftScrolled", "craftHandsOff"]

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


def bindings_checks():
    """Bindings.xml: a header is declared once, on its first binding (the bindings after it fall
    under it); a second declaration logs "Binding header X was attempted to be loaded more than
    once" at every load. Binding names are unique."""
    import xml.etree.ElementTree as ET
    problems = []
    root = ET.parse(os.path.join(ROOT, "Bindings.xml")).getroot()
    headers, names = set(), set()
    for b in root.iter("Binding"):
        header, name = b.get("header"), b.get("name")
        if header:
            if header in headers:
                problems.append("Bindings.xml: header %s declared again on %s (declare it on the first binding only)"
                                % (header, name))
            headers.add(header)
        if name in names:
            problems.append("Bindings.xml: binding %s listed twice" % name)
        names.add(name)
    return problems


def binding_bodies():
    """The Lua each key binding in Bindings.xml runs (the client loads the file by itself)."""
    import xml.etree.ElementTree as ET
    path = os.path.join(ROOT, "Bindings.xml")
    if not os.path.exists(path):
        return []
    root = ET.parse(path).getroot()
    # CLICK bindings have no body: the client clicks the named button.
    return [(b.text or "").strip() for b in root.iter("Binding") if (b.text or "").strip()]


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
    choice_errors, choice_warnings = quest_choice_checks()
    return (errors + prof_errors + game_errors + quest_mob_checks() + quest_shop_checks() + quest_danger_checks()
            + quest_flight_checks() + choice_errors + release_notes_checks(), warnings + prof_warnings + game_warnings + choice_warnings)


def quest_choice_checks():
    """Each faction has a leveling guide for every level 30-60, and the owner asked for at least three
    choices (main route plus alternates) at each of those levels: a gap fails, fewer than three warns."""
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import gamedata
    import questroute
    data = gamedata.load_lua_global(questroute.ROUTES, "LevelingCodexQuests")
    errors, warnings = [], []
    for faction in ("ALLIANCE", "HORDE"):
        sections = [s for s in data[faction]["sections"] if not s.get("side")]
        for level in range(30, 61):
            count = sum(1 for s in sections if s["levels"][0] <= level <= s["levels"][1])
            if count == 0:
                errors.append("quest route %s: no leveling guide covers level %d" % (faction, level))
            elif count < 3:
                warnings.append("quest route %s: only %d leveling guide(s) cover level %d" % (faction, count, level))
    return errors, warnings


def release_notes_checks():
    """Every CHANGELOG.md version section converts to clean release notes (tools/release_notes.py)."""
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import release_notes
    return ["release notes: " + p for p in release_notes.check()]


def quest_flight_checks():
    """QuestFlightData.lua (tools/questflights.py): matches the game reference; every flight point stands on a
    map with a world position, links to known flight points and names a faction; the route's flight names exist."""
    path = os.path.join(ROOT, "QuestFlightData.lua")
    if not os.path.exists(path):
        return ["quest flights: QuestFlightData.lua missing"]
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import questflights
    errors = []
    if open(path, encoding="utf-8").read().replace("\r\n", "\n") != questflights.build():
        errors.append("quest flights: QuestFlightData.lua is out of date: run tools/questflights.py")
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    ns = lua.table()
    lua.execute("local f = ...; f('LevelingCodex', select(2, ...))",
                lua.eval("loadstring")(open(path, encoding="utf-8").read()), ns)
    nodes, world = ns["questFlightNodes"], ns["questWorld"]
    if lupa.lua_type(nodes) != "table" or lupa.lua_type(world) != "table":
        return errors + ["quest flights: QuestFlightData.lua sets no ns.questFlightNodes / ns.questWorld"]
    names = set()
    for node, d in nodes.items():
        where = "quest flights %s" % node
        name = d[1]
        if not isinstance(name, str) or any(ord(c) > 127 for c in name):
            errors.append(where + ": bad name")
        names.add(name)
        if d[2] not in ("A", "H", "AH"):
            errors.append(where + ": bad faction %r" % (d[2],))
        if world[d[3]] is None:
            errors.append(where + ": map %s has no world position" % d[3])
        if not all(isinstance(v, (int, float)) and 0 <= v <= 100 for v in (d[4], d[5])):
            errors.append(where + ": position outside the map")
        for link in d[6].values():
            if nodes[link] is None:
                errors.append(where + ": links to unknown flight point %s" % link)
    # The route's flight steps name flight points as the flight map shows them.
    for path in sorted(set(glob.glob(os.path.join(ROOT, "Quest*Data.lua")) + glob.glob(os.path.join(ROOT, "QuestData*.lua"))
                           + glob.glob(os.path.join(ROOT, "QuestDungeonData*.lua")) + glob.glob(os.path.join(ROOT, "QuestHorde*.lua")))):
        text = open(path, encoding="utf-8").read()
        for m in re.finditer(r'taxi\("(?:getfp|fly)", [^,]+, "([^"]+)"', text):
            if m.group(1) not in names:
                errors.append("quest flights: %s names flight point %r, which the game doesn't have"
                              % (os.path.basename(path), m.group(1)))
    return errors


def quest_danger_checks():
    """QuestDangerData.lua (tools/questdanger.py): map -> { name, low, high, kind, friendly, spots = { x, y, ... } }."""
    errors = []
    path = os.path.join(ROOT, "QuestDangerData.lua")
    if not os.path.exists(path):
        return ["quest danger: QuestDangerData.lua missing"]
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    ns = lua.table()
    lua.execute("local f = ...; f('LevelingCodex', select(2, ...))",
                lua.eval("loadstring")(open(path, encoding="utf-8").read()), ns)
    danger = ns["questDanger"]
    if lupa.lua_type(danger) != "table":
        return ["quest danger: QuestDangerData.lua sets no ns.questDanger"]
    for map_id, entries in danger.items():
        if not isinstance(map_id, int) or lupa.lua_type(entries) != "table":
            errors.append("quest danger %s: expected [mapID] = { creatures }" % map_id)
            continue
        for d in entries.values():
            where = "quest danger %s %s" % (map_id, d[1])
            name, low, high, kind, friendly, spots = d[1], d[2], d[3], d[4], d[5], d["spots"]
            if not isinstance(name, str) or not name.strip() or any(ord(c) > 127 for c in name):
                errors.append(where + ": bad name")
            if not (isinstance(low, int) and isinstance(high, int) and 1 <= low <= high <= 60):
                errors.append(where + ": bad levels")
            if kind not in ("elite", "rareelite", "boss", "rare"):
                errors.append(where + ": bad kind %r" % (kind,))
            if not isinstance(friendly, str) or set(friendly) - set("AH"):
                errors.append(where + ": bad faction letters")
            values = list(spots.values()) if lupa.lua_type(spots) == "table" else []
            if not values or len(values) % 2 or any(not isinstance(v, (int, float)) or not 0 <= v <= 100 for v in values):
                errors.append(where + ": spots must be x, y pairs in 0-100")
    return errors


def quest_mob_checks():
    """QuestMobData.lua (tools/questmobs.py): quest ID -> 1-6 ASCII creature names a macro can target."""
    errors = []
    path = os.path.join(ROOT, "QuestMobData.lua")
    if not os.path.exists(path):
        return ["quest mobs: QuestMobData.lua missing"]
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    ns = lua.table()
    lua.execute("local f = ...; f('LevelingCodex', select(2, ...))",
                lua.eval("loadstring")(open(path, encoding="utf-8").read()), ns)
    mobs = ns["questMobs"]
    if lupa.lua_type(mobs) != "table":
        return ["quest mobs: QuestMobData.lua sets no ns.questMobs"]
    for quest, names in mobs.items():
        where = "quest mobs %s" % quest
        if not isinstance(quest, int) or lupa.lua_type(names) != "table":
            errors.append(where + ": expected [questID] = { names }")
            continue
        values = list(names.values())
        if not 1 <= len(values) <= 6:
            errors.append(where + ": %d names (1-6 expected)" % len(values))
        for name in values:
            if not isinstance(name, str) or not name.strip() or any(ord(c) > 127 for c in name) or re.search(r"[\n/;]", name):
                errors.append(where + ": bad creature name %r" % (name,))
    return errors


def quest_shop_checks():
    """QuestShopData.lua (tools/questshop.py): quest ID -> 1-6 { itemID, count } vendor-only items."""
    errors = []
    path = os.path.join(ROOT, "QuestShopData.lua")
    if not os.path.exists(path):
        return ["quest shop: QuestShopData.lua missing"]
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    ns = lua.table()
    lua.execute("local f = ...; f('LevelingCodex', select(2, ...))",
                lua.eval("loadstring")(open(path, encoding="utf-8").read()), ns)
    shop = ns["questShop"]
    if lupa.lua_type(shop) != "table":
        return ["quest shop: QuestShopData.lua sets no ns.questShop"]
    for quest, items in shop.items():
        where = "quest shop %s" % quest
        if not isinstance(quest, int) or lupa.lua_type(items) != "table":
            errors.append(where + ": expected [questID] = { { itemID, count } }")
            continue
        pairs = list(items.values())
        if not 1 <= len(pairs) <= 6:
            errors.append(where + ": %d items (1-6 expected)" % len(pairs))
        for pair in pairs:
            values = list(pair.values()) if lupa.lua_type(pair) == "table" else []
            if (len(values) != 2 or not isinstance(values[0], int) or values[0] < 1
                    or not isinstance(values[1], int) or not 1 <= values[1] <= 100):
                errors.append(where + ": bad item entry %r" % (values,))
    spices = shop[1218]
    if lupa.lua_type(spices) != "table" or [list(p.values()) for p in spices.values()] != [[3713, 3]]:
        errors.append("quest shop: quest 1218 (Soothing Spices) should hold { 3713, 3 }")
    return errors


PROF_KEYS = ("BLACKSMITHING", "MINING", "TAILORING", "ENCHANTING", "HERBALISM", "SKINNING", "LEATHERWORKING", "ALCHEMY",
             "ENGINEERING", "FIRST_AID", "COOKING", "FISHING")


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
        herbs = P.get("herbs") or []
        herb_names = {h.get("name") for h in herbs}
        if key == "HERBALISM":
            if len(herbs) != 28 or len(herb_names) != 28:
                errors.append("professions HERBALISM: expected 28 distinct standard herbs")
            if [(t.get("skill"), t.get("cap"), t.get("level")) for t in P.get("tiers") or []] != [
                (1, 75, 1), (50, 150, 1), (125, 225, 1), (200, 300, 1)
            ]:
                errors.append("professions HERBALISM: incorrect training tiers")
            if {c.get("name") for c in P.get("camp") or []} != {"Incense Candle", "Greenhouse", "Seed Hybridizer"}:
                errors.append("professions HERBALISM: missing camp objects")
            for h in herbs:
                if not all(h.get(f) for f in ("name", "item", "icon", "skill", "yellow", "green", "grey", "zones")):
                    errors.append("professions HERBALISM: incomplete herb %s" % h.get("name"))
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
            elif key == "HERBALISM":
                if not s.get("title") or not s.get("herbs") or any(h not in herb_names for h in s["herbs"]):
                    errors.append(where + ": requires a title and known herbs")
            elif key in ("SKINNING", "FISHING"):
                if not all(s.get(f) for f in ("title", "icon", "zones", "note")):
                    errors.append(where + ": requires a title, icon, zones and note")
                zones = s.get("zones") or {}
                if not zones.get("All") and not (zones.get("Alliance") and zones.get("Horde")):
                    errors.append(where + ": missing a route for one or both factions")
            else:
                for f in ("name", "spell", "icon", "yellow", "grey", "mats", "learn", "source"):
                    if s.get(f) in (None, ""):
                        errors.append(where + ": missing %s" % f)
        for v in P.get("veins") or []:
            for f in ("name", "skill", "ore", "icon", "zones"):
                if not v.get(f):
                    errors.append("professions %s vein %s: missing %s" % (key, v.get("name"), f))
        # parts: items the profession makes for its own recipes (Tailoring's bolts)
        for p in P.get("parts") or []:
            for f in ("name", "plural", "spell", "icon", "yellow", "grey", "mats", "makes", "learn", "source"):
                if p.get(f) in (None, ""):
                    errors.append("professions %s part %s: missing %s" % (key, p.get("name"), f))
        # rods (Enchanting): the tool each step needs
        rods = {r.get("name") for r in P.get("rods") or []}
        for r in P.get("rods") or []:
            for f in ("name", "category", "mask", "spell", "icon", "yellow", "grey", "mats", "learn", "source"):
                if r.get(f) in (None, ""):
                    errors.append("professions %s rod %s: missing %s" % (key, r.get("name"), f))
        for p in P.get("parts") or []:
            if p.get("rod") and p["rod"] not in rods:
                errors.append("professions %s part %s: rod %s is not in the rods list" % (key, p.get("name"), p["rod"]))
        for s in P.get("steps") or []:
            if s.get("rod") and s["rod"] not in rods:
                errors.append("professions %s step %s-%s: rod %s is not in the rods list" % (key, s.get("from"), s.get("to"), s["rod"]))
        bands = (P.get("disenchant") or {}).get("bands") or []
        if P.get("disenchant"):
            at = 5
            for b in bands:
                if b.get("from") != at or not isinstance(b.get("to"), int) or b["to"] < b["from"]:
                    errors.append("professions %s: disenchant item levels must run 5-99 without gaps (at %s)" % (key, b.get("from")))
                    break
                for f in ("dust", "essence"):
                    if not b.get(f):
                        errors.append("professions %s: disenchant band %s-%s missing %s" % (key, b.get("from"), b.get("to"), f))
                at = b["to"] + 1
            if at != 100:
                errors.append("professions %s: disenchant item levels must run 5-99 without gaps (end %s)" % (key, at - 1))
        cloth = P.get("cloth") or []
        for c in cloth:
            for f in ("name", "icon", "levels", "zones"):
                if not c.get(f):
                    errors.append("professions %s cloth %s: missing %s" % (key, c.get("name"), f))
            for side, zones in (c.get("zones") or {}).items():
                if not isinstance(zones, list) or not all(isinstance(z, str) for z in zones):
                    errors.append("professions %s cloth %s: zones %s must be a list of names" % (key, c.get("name"), side))
        if cloth:
            names = {c.get("name") for c in cloth}
            for p in P.get("parts") or []:
                first = (p.get("mats") or [[None]])[0][0]
                if first not in names:
                    errors.append("professions %s: part %s: %s is not in the cloth list" % (key, p.get("name"), first))
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
            ("Mining", "Smelt Bronze", 65, 115, [["Copper Bar", 1], ["Tin Bar", 1]]),
            ("Tailoring", "Bolt of Silk Cloth", 110, 120, [["Silk Cloth", 4]]),
            ("Tailoring", "Runecloth Belt", 225, 255, [["Bolt of Runecloth", 3], ["Rune Thread", 1]]),
            ("Enchanting", "Dust to Motes", 10, 15, [["Strange Dust", 1]]),
            ("Enchanting", "Enchant Shield - Greater Stamina", 285, 325, [["Dream Dust", 6]]),
            ("Herbalism", "Incense Candle", 20, 25, [["Peacebloom", 1], ["Silverleaf", 1]]),
            ("Herbalism", "Greenhouse", 140, 145, [["Simple Wood", 2], ["Arthas' Tears", 1], ["Purple Lotus", 1]]),
            ("Herbalism", "Seed Hybridizer", 300, 300, [["Mountain Silversage", 4], ["Crystal Vial", 1], ["Runecloth", 2]])]
    for prof, name, y, g, mats in want:
        r = (profs.get(prof) or {}).get("recipes", {}).get(name)
        if not r or (r["yellow"], r["grey"], r["mats"]) != (y, g, mats):
            errors.append("%s reference: %s %s should be yellow %d grey %d %s, is %s" % (tag, prof, name, y, g, mats, r))
    # the client's own learn level (SkillLineAbility.MinSkillLineRank) where it sets one
    bs = (profs.get("Blacksmithing") or {}).get("recipes", {})
    if (bs.get("Rough Bronze Leggings") or {}).get("min") != 95 or "min" in (bs.get("Rough Sharpening Stone") or {"min": 0}):
        errors.append("%s reference: Rough Bronze Leggings should carry the client's min 95, Rough Sharpening Stone none" % tag)
    # learned with the profession (SkillLineAbility.AcquireMethod 1)
    if not ((profs.get("Tailoring") or {}).get("recipes", {}).get("Linen Bag") or {}).get("auto"):
        errors.append("%s reference: Tailoring's Linen Bag should be learned with the profession (auto)" % tag)
    # rods: a better rod counts for the lower ones (mask); Superior Defense needs only the Truesilver rod
    tsr = (ref.get("rods") or {}).get("Runed Truesilver Rod") or {}
    sd = ((profs.get("Enchanting") or {}).get("recipes", {}).get("Enchant Cloak - Superior Defense") or {})
    if (tsr.get("category"), tsr.get("mask")) != (376, 15) or sd.get("tool") != "Runed Truesilver Rod":
        errors.append("%s reference: Runed Truesilver Rod should be category 376 mask 15 and Superior Defense need it (%s, %s)" %
                      (tag, tsr, sd.get("tool")))
    profdata = gamedata.load_profdata()
    herbs = profs.get("Herbalism") or {}
    gathering = herbs.get("gathering") or {}
    if (herbs.get("skillLine") != 182 or gathering.get("icon") != "trade_herbalism"
            or gathering.get("items", {}).get("2447", {}).get("name") != "Peacebloom"
            or gathering.get("lockSkills", {}).get("29") != [1]
            or gathering.get("lockSkills", {}).get("1124") != [300]
            or not {"Zephras Isle", "Riverglades"} <= set(gathering.get("areas", []))):
        errors.append("%s reference: missing or incorrect Herbalism client evidence" % tag)
    for name, spell in (("Incense Candle", 1229705), ("Greenhouse", 1262980), ("Seed Hybridizer", 1263070)):
        if herbs.get("recipes", {}).get(name, {}).get("spell") != spell:
            errors.append("%s reference: %s should be spell %d" % (tag, name, spell))
    if profdata:
        for p, lvl, m in gamedata.audit_professions(profdata, ref):
            (errors if lvl == "error" else warnings).append("%s %s: %s" % (tag, p, m))
    errors += tool_checks(gamedata, ref, profdata, tag)
    for area, lvl, message in gamedata.audit_quests(ref):
        (errors if lvl == "error" else warnings).append("%s %s: %s" % (tag, area, message))
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
    if profdata and profdata.get("HERBALISM") and ref.get("professions", {}).get("Herbalism", {}).get("gathering"):
        errors.extend(herbalism_tool_checks(gamedata, ref, profdata["HERBALISM"], tag))
    return errors


def herbalism_tool_checks(gamedata, ref, guide, tag):
    import copy
    errors = []
    fake = copy.deepcopy(ref)
    herbalism = fake["professions"]["Herbalism"]
    gathering = herbalism["gathering"]
    gathering["items"]["2447"] = {"name": "Wrong name", "icon": "wrong_icon"}
    gathering["lockSkills"]["29"] = [2]
    gathering["areas"].remove("Zephras Isle")
    del herbalism["recipes"]["Incense Candle"]
    herbalism["recipes"]["Greenhouse"]["plan"]["skill"] = 141
    messages = [msg for _, level, msg in gamedata.audit_professions({"HERBALISM": guide}, fake) if level == "error"]
    for needle in ("Peacebloom item", "Peacebloom icon", "Peacebloom skill", "Zephras Isle", "Incense Candle", "Greenhouse"):
        if not any(needle in msg for msg in messages):
            errors.append("%s Herbalism audit missed %s" % (tag, needle))
    changes = gamedata.diff(ref, fake)
    if not all(text in changes for text in ("HERBALISM", "herb item 2447", "herbalism lock 29", "Zephras Isle")):
        errors.append("%s Herbalism diff misses changed gathering evidence" % tag)
    del herbalism["gathering"]
    if "first Herbalism gathering data" not in gamedata.diff(fake, ref):
        errors.append("%s Herbalism diff misses initial gathering evidence" % tag)
    broken = copy.deepcopy(guide)
    broken["steps"][0]["herbs"] = ["Earthroot"]
    if not any(level == "error" and "no usable herb at skill 1" in msg
               for _, level, msg in gamedata.audit_professions({"HERBALISM": broken}, ref)):
        errors.append("%s Herbalism audit misses a gap within a gathering step" % tag)
    return errors


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    args = sys.argv[1:]
    verbose = "-v" in args
    only = args[args.index("-k") + 1] if "-k" in args else None
    t0 = time.time()
    files, problems = toc_files()
    problems += bindings_checks()
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
        runs.append(("WARRIOR/%s/quests" % variant, "WARRIOR", minimal, ["login", "questStart"]))
        if minimal:
            runs.append(("WARRIOR/minimal/questie", "WARRIOR", True, ["questQuestieMinimal"]))
        if not minimal:
            for scenario in ("questProgress", "questClassic", "questPastRoute", "questNavigation", "questTravelArrow",
                             "questRedridgeOverlap", "questObjectiveWaypoints", "questDuskwoodHandoff", "questDuskwoodZoneEntry",
                             "questDuskwoodDagger",
                             "questRecorder",
                             "questController", "questControllerBackup", "questSkyborne", "questWestfall", "questCatchup", "questLayout",
                             "questBind", "questGossip", "questFlights", "questDuskwood", "questLakeshireHandoff", "questItem",
                             "questRace", "questRaceHuman", "questPassed", "questBreadcrumb",
                             "questWetlands", "questWetlandsTravel", "questWetlandsEnd", "questWetlandsEarly", "questRouteEnd", "questStranglethornRoad", "questWetlandsDig", "questStepChecklist", "questWetlandsAfterEarly", "questNoCheckNotes",
                             "questStartDwarf", "questStartGnome", "questStartNightElf", "questStartSkyborne",
                             "questStartHordeOrc", "questStartHordeTroll", "questStartHordeTauren", "questStartHordeScourge", "questStartHordeSkyborne", "questHordeSkyborne", "questHordeBarrens", "questHordeSilverpine", "questHordeStranglethorn", "questHordeRouteEnd", "questHordeDungeon",
                             "questClassSide", "questClassCatchup", "questWestfallDeed", "questQuarryKeg",
                             "questDetour", "questCrossZoneResume", "questZoneResume", "questLoginResume",
                             "questHistoryResume", "questAlternateRoutes", "questLochHistory", "questLochReady",
                             "questLochFlight", "questLochBingles", "questWestfallDetour", "questDetourLibrary",
                             "questDungeonContent", "questDungeonPlan", "questGrey", "questLoginWetlandsLocal", "questAlternateSharedPickup", "questPinCapacity", "questLibraryResume",
                             "questQuestieAuto", "questQuestieTracker", "questQuestieDB", "questQuestieNearest",
                             "questQuestieNearestItem", "questQuestieNearestPart", "questQuestieNearestError",
                             "questQuestieTrackerLive", "questQuestieNearestFallback", "questQuestieNearestCleared",
                             "questQuestieArrowClamp", "questQuestieNearestRetext", "questQuestieNearestLateData",
                             "questQuestieRecheck", "questQuestieNearestEmptyText", "questQuestieNearestEmptyName",
                             "questQuestieNearestNoRows", "questQuestieNearestNoScale", "questQuestieNearestRoundTrip",
                             "questCorpse", "questTravelFlight", "questTravelBind", "questGrind", "questCleanup", "questReward", "questMobTarget",
                             "questMapPin", "questWarriorFangs", "questWarriorFangsNotTaken",
                             "questCarriedTurninNotTaken", "questCarriedTurninCarried",
                             "questStepTypes", "questBuyItems", "arrowMove", "arrowArrival", "minimapPins", "worldMapPins", "stepProgress", "stepPolish", "questTabViews", "questWaypoints", "questWindowExtras",
                             "questArrowTimes", "questTracker", "questSetup", "questDanger", "questParty",
                             "questFlightPlan", "questFlightLearn", "questFlightHub", "questDungeonChoice",
                             "questBossSteps", "questEntrancePath"):
                runs.append(("WARRIOR/full/quests-" + scenario, "WARRIOR", False, [scenario]))
            runs.append(("WARRIOR/full/blocked-report", "WARRIOR", False, ["blockedReport"]))
            for cls, scenario in (("HUNTER", "questHunterGuides"), ("SHAMAN", "questShamanGuides"),
                                  ("HUNTER", "questHordeHunter"), ("SHAMAN", "questHordeShaman"), ("MAGE", "questWarriorFangsOtherClass"), ("DRUID", "questClassAlongDruid"), ("DRUID", "questClassAlongDruidNotTaken"), ("SHAMAN", "questClassAlongShaman"), ("SHAMAN", "questClassAlongShamanNotTaken")):
                runs.append((cls + "/full/quests-" + scenario, cls, False, [scenario]))
        for cls in CLASSES + [UNSUPPORTED]:
            runs.append(("%s/%s/main" % (cls, variant), cls, minimal, MAIN))
        for cls in CLASSES:
            runs.append(("%s/%s/icon" % (cls, variant), cls, minimal, ICON))
        runs.append(("WARRIOR/%s/warrior-macros" % variant, "WARRIOR", minimal, ["login", "warriorPackMacros"]))
        if not minimal:
            runs.append(("WARRIOR/full/warrior-macros-upgrade", "WARRIOR", False, ["login", "warriorMacroUpgrade"]))
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
        runs.append(("WARRIOR/%s/class-trainer" % variant, "WARRIOR", minimal, ["login", "classTrainer"]))
        runs.append(("WARRIOR/%s/vendor-junk" % variant, "WARRIOR", minimal, ["vendorJunk"]))
        runs.append(("WARRIOR/%s/vendor-repair" % variant, "WARRIOR", minimal, ["vendorRepair"]))
        runs.append(("WARRIOR/%s/vendor-shopping" % variant, "WARRIOR", minimal, ["vendorShopping"]))
        if not minimal:
            runs.append(("WARRIOR/full/vendor-shopping-quest", "WARRIOR", False, ["vendorShoppingQuest"]))
            runs.append(("WARRIOR/full/vendor-server", "WARRIOR", False, ["vendorServer"]))
            runs.append(("WARRIOR/full/vendor-pad", "WARRIOR", False, ["vendorPad"]))
            runs.append(("WARRIOR/full/vendor-buy-fails", "WARRIOR", False, ["vendorBuyFails"]))
        runs.append(("WARRIOR/%s/stats-counters" % variant, "WARRIOR", minimal, ["statsCounters"]))
        runs.append(("WARRIOR/%s/stats-level-up" % variant, "WARRIOR", minimal, ["statsLevelUp"]))
        if minimal:
            runs.append(("WARRIOR/minimal/minimap-pins", "WARRIOR", True, ["minimapPins"]))
        runs.append(("WARRIOR/%s/stats-tab" % variant, "WARRIOR", minimal, ["statsTab", "tabRowFits"]))
        if not minimal:
            runs.append(("WARRIOR/full/stats-lost", "WARRIOR", False, LOST + ["statsTabLost"]))
        runs.append(("WARRIOR/%s/pace" % variant, "WARRIOR", minimal, ["paceCard"]))
        runs.append(("PALADIN/%s/prof-skilllines" % variant, "PALADIN", minimal, PROF_LINES))
        runs.append(("PALADIN/%s/prof-closed-heading" % variant, "PALADIN", minimal, PROF_CLOSED))
        runs.append(("MAGE/%s/prof-none" % variant, "MAGE", minimal, PROF_NONE))
        runs.append(("WARRIOR/%s/prof-learned-switch" % variant, "WARRIOR", minimal, ["login", "profLearnedSwitch"]))
        runs.append(("WARRIOR/%s/prof-reader" % variant, "WARRIOR", minimal, ["login", "profReaderRecovery"]))
        runs.append(("WARRIOR/%s/prof-reader-open" % variant, "WARRIOR", minimal, ["login", "profReaderRecoversAfterOpen"]))
        runs.append(("WARRIOR/%s/prof-reader-closed-weapons" % variant, "WARRIOR", minimal,
                     ["skills:MI;30;75:skilllines", "login", "profOpenHeadingWithClosedWeapons"]))
        runs.append(("WARRIOR/%s/prof-herbalism" % variant, "WARRIOR", minimal, HERBALISM + ["herbalismTab"]))
        runs.append(("WARRIOR/%s/prof-herbalism-cards" % variant, "WARRIOR", minimal, HERBALISM + ["herbalismCards"]))
        skills_api = "skilllines" if minimal else "professions"
        runs.append(("WARRIOR/%s/prof-skinning-leatherworking" % variant, "WARRIOR", minimal,
                     ["skills:SK;1;75,LW;1;75:%s:Alliance:Human" % skills_api, "login", "skinningLeatherworkingTab"]))
        runs.append(("WARRIOR/%s/prof-alchemy" % variant, "WARRIOR", minimal,
                     ["skills:HE;1;75,AL;1;75:%s:Alliance:Human" % skills_api, "login", "alchemyTab"]))
        runs.append(("WARRIOR/%s/prof-engineering" % variant, "WARRIOR", minimal,
                     ["skills:MI;1;75,EG;1;75:%s:Alliance:Gnome" % skills_api, "login", "engineeringTab"]))
        runs.append(("WARRIOR/%s/prof-first-aid" % variant, "WARRIOR", minimal,
                     ["skills:MI;1;75,EG;1;75,FA;1;75:%s:Alliance:Human" % skills_api, "login", "firstAidTab"]))
        runs.append(("WARRIOR/%s/prof-cooking" % variant, "WARRIOR", minimal,
                     ["skills:MI;1;75,CO;1;75:%s:Alliance:Human" % skills_api, "login", "cookingTab"]))
        side, race = ("Horde", "Orc") if minimal else ("Alliance", "Human")
        runs.append(("WARRIOR/%s/prof-fishing" % variant, "WARRIOR", minimal,
                     ["skills:MI;1;75,EG;1;75,CO;1;75,FA;1;75,FI;1;75:%s:%s:%s" % (skills_api, side, race),
                      "login", "fishingTab"]))
        if not minimal:
            runs.append(("WARRIOR/full/craft-leatherworking", "WARRIOR", False,
                         ["skills:SK;20;75,LW;235;300:professions", "makeCraftWindow", "login", "craftLeatherworking"]))
            runs.append(("WARRIOR/full/craft-alchemy", "WARRIOR", False,
                         ["skills:AL;265;300:professions", "makeCraftWindow", "login", "craftAlchemy"]))
            runs.append(("WARRIOR/full/craft-engineering", "WARRIOR", False,
                         ["skills:EG;285;300:professions", "makeCraftWindow", "login", "craftEngineering"]))
            runs.append(("WARRIOR/full/craft-first-aid", "WARRIOR", False,
                         ["skills:FA;180;225:professions", "makeCraftWindow", "login", "craftFirstAid"]))
        runs.append(("WARRIOR/%s/tailor" % variant, "WARRIOR", minimal, TAILOR))
        runs.append(("MAGE/%s/tailor-only" % variant, "MAGE", minimal, TAILOR_ONLY))
        runs.append(("PALADIN/%s/tailor-skilllines" % variant, "PALADIN", minimal, TAILOR_LINES))
        runs.append(("PALADIN/%s/tailor-closed-heading" % variant, "PALADIN", minimal, TAILOR_CLOSED))
        runs.append(("WARRIOR/%s/enchant" % variant, "WARRIOR", minimal, ENCHANT))
        runs.append(("PRIEST/%s/enchant-skilllines" % variant, "PRIEST", minimal, ENCHANT_LINES))
        for cls in ("WARRIOR", "HUNTER"):
            runs.append(("%s/%s/prof-skillups" % (cls, variant), cls, minimal, PROF_UPS))
        for cls in ("WARRIOR", "MAGE"):
            runs.append(("%s/%s/pad" % (cls, variant), cls, minimal, PAD))
        runs.append(("WARRIOR/%s/banner-target" % variant, "WARRIOR", minimal, PROF_BANNER))
        for shortcut in ("slash", "click"):
            runs.append(("WARRIOR/%s/banner-target-%s" % (variant, shortcut), "WARRIOR", minimal,
                         ["login", "profRemovedBanner:" + shortcut]))
        runs.append(("WARRIOR/%s/craft" % variant, "WARRIOR", minimal, CRAFT))
        if not minimal:
            runs.append(("PRIEST/full/craft", "PRIEST", False, CRAFT))
            runs.append(("WARRIOR/full/craft-retail", "WARRIOR", False, CRAFT_RETAIL))
            runs.append(("WARRIOR/full/craft-scrollbox", "WARRIOR", False, CRAFT_SCROLLBOX))
            for mode in ("classic", "retail"):
                runs.append(("WARRIOR/full/craft-herbalism-" + mode, "WARRIOR", False,
                             ["makeCraftWindow:" + mode, "login", "craftHerbalism"]))

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
