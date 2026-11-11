"""Game data for the Leveling Codex: what WoW: Forever itself says about talents and spells.

    python tools/gamedata.py update             # after a game patch or hotfix: everything below in one go
    python tools/gamedata.py fetch [--build B]  # download the client tables for the newest (or a given) Forever build
    python tools/gamedata.py build [--build B]  # write tools/reference/forever.json from them
    python tools/gamedata.py diff OLD.json [NEW.json]   # what changed between two references
    python tools/gamedata.py audit [-k CLASS] [-v]       # check Data.lua against the reference
    python tools/gamedata.py review CLASS       # the talent plan next to each talent's real tooltip
    python tools/gamedata.py packet CLASS       # everything about one class's guide next to the game, for a manual review
    python tools/gamedata.py tree CLASS         # the class's talent tree as the game lays it out
    python tools/gamedata.py spells CLASS [NAME]   # class spells with rank and level
    python tools/gamedata.py recipes PROFESSION [NAME]   # guided profession recipes: colours, reagents, icon, plan, tool
    python tools/gamedata.py profs [PROFESSION]   # ProfessionData.lua audited, each route step next to the game

Source: wago.tools serves every table of every client build as CSV. Forever is the product "wowf".
The tables are cached in tools/.cache/<build>/ (not committed). The reference built from them,
tools/reference/forever.json, is committed: the harness checks Data.lua against it offline, and
`git diff` on it after an update is the list of game changes the guides have to follow.

What the client tables can't tell: trainer gold costs, quest-only spells, server-side tuning that
only lives in hotfix notes. Those still come from the patch notes (see tools/UPDATING.md).
"""
import argparse
import collections
import csv
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".cache")
REF = os.path.join(ROOT, "tools", "reference", "forever.json")
API = "https://wago.tools"
PRODUCT = "wowf"
UA = "LevelingCodex-gamedata/1.0"

TABLES = [
    "ChrClasses", "SkillLine", "SkillRaceClassInfo", "SkillLineAbility", "SkillLineXTraitTree", "TalentTab",
    "TraitNode", "TraitNodeEntry", "TraitDefinition", "TraitNodeXTraitNodeEntry", "TraitEdge", "TraitCond",
    "TraitNodeGroupXTraitNode", "TraitNodeGroupXTraitCond", "TraitDefinitionEffectPoints", "Curve", "CurvePoint",
    "SpellName", "Spell", "SpellLevels", "SpellMisc", "SpellEffect", "SpellDuration", "SpellRadius",
    "SpellAuraOptions", "SpellCooldowns", "SpellPower", "ManifestInterfaceData", "SpellShapeshift", "SpellCategories",
    # professions: reagents, items, the plans that teach recipes, recipe categories
    "SpellReagents", "ItemSparse", "Item", "ItemEffect", "ItemXItemEffect", "TradeSkillCategory",
    # Enchanting: the tool (rod) a recipe needs, rod categories and masks, disenchanting level bands
    "SpellTotems", "TotemCategory", "ItemDisenchantLoot",
    # Engineering and Cooking use crafting stations.
    "SpellCastingRequirements", "SpellFocusObject",
    # Quest IDs, navigation and the small subset of quests with client POIs.
    "QuestV2", "UiMap", "UiMapAssignment", "TaxiNodes", "QuestLine", "QuestLineXQuest",
    "QuestPOIBlob", "QuestPOIPoint",
    "Lock", "AreaTable",
]

# Professions with a guide (ProfessionData.lua): name -> skill line.
PROFESSIONS = {
    "Blacksmithing": 164, "Mining": 186, "Tailoring": 197, "Enchanting": 333, "Herbalism": 182,
    "Skinning": 393, "Leatherworking": 165, "Alchemy": 171, "Engineering": 202, "First Aid": 129, "Cooking": 185,
    "Fishing": 356,
}

# Standard herb item IDs from the Forever node catalog. Lock rows supply the
# possible minimum skills; the client does not link these named nodes to locks.
HERBALISM_ITEMS = {
    "2447", "765", "2449", "785", "2450", "3820", "2453", "3355", "3369", "3356", "3357", "3818", "3821",
    "3358", "3819", "4625", "8831", "8836", "8838", "8839", "8845", "8846", "13464", "13463", "13465",
    "13466", "13467", "13468",
}

CLASSES = ["DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"]
WARLOCK_PETS = {"Imp", "Voidwalker", "Succubus", "Felhunter", "Infernal", "Doomguard", "Felguard"}
# Abilities every character has without a trainer.
INNATE = {"Attack", "Shoot", "Auto Shot", "Throw"}
# SpellShapeshift masks: bit (form - 1)
FORMS = {1: "Cat Form", 2: "Tree of Life", 3: "Travel Form", 4: "Aquatic Form", 5: "Bear Form", 8: "Dire Bear Form",
         16: "Ghost Wolf", 17: "Battle Stance", 18: "Defensive Stance", 19: "Berserker Stance", 28: "Shadowform",
         30: "Stealth", 31: "Moonkin Form"}
# Talent/spell names in guide text that are just English words, not mentions.
COMMON = {"Enrage", "Dash", "Prowl", "Growl", "Bite", "Claw", "Charge", "Shoot", "Attack", "Fade", "Stealth"}


# ---------------------------------------------------------------------------
# Fetching
# ---------------------------------------------------------------------------

def http_get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as r:
        return r.read()


def latest_build():
    builds = json.loads(http_get(API + "/api/builds"))
    versions = [b["version"] for b in builds.get(PRODUCT, [])]
    if not versions:
        sys.exit("wago.tools lists no builds for product '%s'" % PRODUCT)
    return max(versions, key=lambda v: tuple(int(x) for x in v.split(".")))


def fetch(build, quiet=False):
    d = os.path.join(CACHE, build)
    os.makedirs(d, exist_ok=True)
    for t in TABLES:
        p = os.path.join(d, t + ".csv")
        if os.path.exists(p) and os.path.getsize(p) > 0:
            continue
        if not quiet:
            print("  fetching %s ..." % t)
        data = http_get("%s/db2/%s/csv?build=%s" % (API, t, build))
        if data.lstrip().startswith(b"{"):
            sys.exit("%s: wago.tools says %s" % (t, data[:200].decode("utf-8", "replace")))
        with open(p + ".part", "wb") as f:
            f.write(data)
        os.replace(p + ".part", p)
    return d


class Tables:
    def __init__(self, d):
        self.d = d
        self._c = {}

    def __getattr__(self, t):
        if t.startswith("_"):
            raise AttributeError(t)
        if t not in self._c:
            with open(os.path.join(self.d, t + ".csv"), encoding="utf-8-sig", newline="") as f:
                self._c[t] = list(csv.DictReader(f))
        return self._c[t]


# ---------------------------------------------------------------------------
# Tooltip text
# ---------------------------------------------------------------------------

def num(v):
    v = float(v)
    if abs(v - round(v)) < 1e-6:
        return str(int(round(v)))
    return ("%.2f" % v).rstrip("0").rstrip(".")


def secs(ms):
    s = float(ms) / 1000.0
    if s >= 60 and abs(s / 60 - round(s / 60)) < 1e-6:
        m = int(round(s / 60))
        return "%d min" % m
    return "%s sec" % num(s)


class Spells:
    """Spell lookups and a tooltip renderer good enough to check guide text against."""

    def __init__(self, T):
        self.name = {r["ID"]: r["Name_lang"] for r in T.SpellName}
        self.spell = {r["ID"]: r for r in T.Spell}
        self.misc = {}
        for r in T.SpellMisc:
            if r["DifficultyID"] == "0":
                self.misc.setdefault(r["SpellID"], r)
        self.eff = collections.defaultdict(dict)
        for r in T.SpellEffect:
            if r["DifficultyID"] == "0":
                self.eff[r["SpellID"]][int(r["EffectIndex"])] = r
        self.level = {}
        for r in T.SpellLevels:
            if r["DifficultyID"] == "0":
                self.level[r["SpellID"]] = int(r["BaseLevel"]) or int(r["SpellLevel"])
        self.duration = {r["ID"]: r for r in T.SpellDuration}
        self.radius = {r["ID"]: r for r in T.SpellRadius}
        self.aura = {}
        for r in T.SpellAuraOptions:
            if r["DifficultyID"] == "0":
                self.aura[r["SpellID"]] = r
        self.cooldown = {}
        for r in T.SpellCooldowns:
            if r["DifficultyID"] == "0":
                self.cooldown[r["SpellID"]] = r
        self.stances = {}
        for r in T.SpellShapeshift:
            m = int(r["ShapeshiftMask_0"] or 0)
            if m:
                self.stances[r["SpellID"]] = [FORMS.get(b + 1, "form %d" % (b + 1)) for b in range(32) if m >> b & 1]
        self.category = {}
        for r in T.SpellCategories:
            if r["DifficultyID"] == "0" and r["Category"] not in ("", "0"):
                self.category[r["SpellID"]] = r["Category"]
        self.power = collections.defaultdict(list)
        for r in T.SpellPower:
            self.power[r["SpellID"]].append(r)
        self.icons = {}
        for r in T.ManifestInterfaceData:
            if r["FilePath"].lower().replace("/", "\\") == "interface\\icons\\":
                self.icons[r["ID"]] = re.sub(r"\.+blp$", "", r["FileName"], flags=re.I).lower()

    def rank(self, sid):
        m = re.match(r"Rank (\d+)", (self.spell.get(sid) or {}).get("NameSubtext_lang") or "")
        return int(m.group(1)) if m else None

    def icon(self, sid, override="0"):
        fid = override if override not in ("", "0") else (self.misc.get(sid) or {}).get("SpellIconFileDataID", "0")
        return self.icons.get(fid)

    def value(self, sid, idx, over=None):
        if over and idx in over:
            return over[idx]
        e = self.eff.get(sid, {}).get(idx)
        return float(e["EffectBasePointsF"]) if e else 0.0

    def dur_ms(self, sid):
        di = (self.misc.get(sid) or {}).get("DurationIndex", "0")
        d = self.duration.get(di)
        return float(d["Duration"]) if d else 0.0

    def token(self, sid, key, idx, over):
        """One $-token. idx is 1-based as written in tooltips."""
        i = (idx or 1) - 1
        e = self.eff.get(sid, {}).get(i)
        if key in "smMSw":
            return abs(self.value(sid, i, over))
        if key == "o":
            per = float(e["EffectAuraPeriod"]) if e else 0
            ticks = self.dur_ms(sid) / per if per else 1
            return abs(self.value(sid, i, over)) * ticks
        if key == "t":
            return float(e["EffectAuraPeriod"]) / 1000.0 if e else 0
        if key == "d":
            return self.dur_ms(sid)
        if key in "aA":
            r = self.radius.get(e["EffectRadiusIndex_0"]) if e else None
            return float(r["Radius"]) if r else 0
        if key == "h":
            a = self.aura.get(sid)
            return float(a["ProcChance"]) if a else 0
        if key == "n":
            a = self.aura.get(sid)
            return float(a["ProcCharges"]) if a else 0
        if key == "u":
            a = self.aura.get(sid)
            return float(a["CumulativeAura"]) if a else 0
        if key == "x":
            return float(e["EffectChainTargets"]) if e else 0
        if key == "b":
            return float(e["EffectPointsPerResource"]) if e else 0
        if key == "e":
            return float(e["EffectAmplitude"]) if e else 0
        return None

    TOK = re.compile(r"\$(?:(?P<op>[/*])(?P<k>[\d.]+);)?(?P<sid>\d+)?(?P<key>[a-zA-Z])(?P<idx>\d)?")

    def render(self, sid, over=None, text=None, depth=0):
        """Tooltip of spell sid; over = {effect index: value} for talent ranks."""
        text = text if text is not None else (self.spell.get(sid) or {}).get("Description_lang") or ""
        if depth > 2:
            return text

        def desc(m):
            return self.render(m.group(1), None, None, depth + 1)
        text = re.sub(r"\$@spelldesc(\d+)", desc, text)
        text = re.sub(r"\$@spellname(\d+)", lambda m: self.name.get(m.group(1), "?"), text)
        text = re.sub(r"\$[lL]([^:;]*):([^;]*);", lambda m: m.group(2), text)
        text = re.sub(r"\$[gG]([^:;]*):([^;]*);", lambda m: m.group(1), text)
        # $?s123[yes][no] and friends: keep the first branch, mark it
        text = re.sub(r"\$\?[^\[]*\[([^\]]*)\](?:\[([^\]]*)\])?", lambda m: m.group(1), text)

        def tok(m, as_number=False):
            s = m.group("sid") or sid
            key, idx = m.group("key"), int(m.group("idx")) if m.group("idx") else None
            v = self.token(s, key, idx, over if s == sid else None)
            if v is None:
                return m.group(0)
            if m.group("op") == "/":
                v = v / float(m.group("k"))
            elif m.group("op") == "*":
                v = v * float(m.group("k"))
            if as_number:
                return num(v)
            return secs(v) if key == "d" else num(v)

        def expr(m):
            inner = self.TOK.sub(lambda x: tok(x, True), m.group(1))
            fmt = m.group(2)
            try:
                v = eval(inner, {"__builtins__": {}}, {})  # digits and + - * / only after substitution
                return ("%." + fmt[1:] + "f") % v if fmt else num(v)
            except Exception:
                return "{" + inner + "}"
        text = re.sub(r"\$\{([^}]*)\}(\.\d)?", expr, text)
        text = self.TOK.sub(tok, text)
        text = re.sub(r"\|[cC][0-9a-fA-F]{8}|\|[rR]", "", text)
        return re.sub(r"\s+", " ", text).strip()


# ---------------------------------------------------------------------------
# Reference
# ---------------------------------------------------------------------------

def clusters(xs, k):
    """Split sorted distinct x positions into k groups at the k-1 widest gaps."""
    xs = sorted(set(xs))
    if len(xs) <= k:
        return [[x] for x in xs]
    gaps = sorted(range(1, len(xs)), key=lambda i: xs[i] - xs[i - 1], reverse=True)[:k - 1]
    out, start = [], 0
    for cut in sorted(gaps):
        out.append(xs[start:cut])
        start = cut
    out.append(xs[start:])
    return out


def build_reference(build):
    T = Tables(os.path.join(CACHE, build))
    S = Spells(T)
    classes = {r["ID"]: r["Filename"] for r in T.ChrClasses}
    bit_to_class = {1 << (int(i) - 1): tok for i, tok in classes.items()}
    skill = {r["ID"]: r for r in T.SkillLine}

    # class spell lines: class (7) and class-only secondary (9: Poisons, Lockpicking) skill lines of one class
    class_lines = collections.defaultdict(set)
    for r in T.SkillRaceClassInfo:
        cls = bit_to_class.get(int(r["ClassMask"]))
        s = skill.get(r["SkillID"])
        if cls and s and s["CategoryID"] in ("7", "9") and not s["DisplayName_lang"].startswith("Pet - "):
            class_lines[cls].add(r["SkillID"])
    # lines the class table misses (Forever's second Poisons line): every ability on them is for one class
    by_line = collections.defaultdict(set)
    for r in T.SkillLineAbility:
        by_line[r["SkillLine"]].add(int(r["ClassMask"] or 0))
    for line, masks in by_line.items():
        s = skill.get(line)
        if s and s["CategoryID"] in ("7", "9") and len(masks) == 1 and bit_to_class.get(next(iter(masks))):
            class_lines[bit_to_class[next(iter(masks))]].add(line)
    pet_lines = {}
    for s in skill.values():
        if s["CategoryID"] == "7" and s["DisplayName_lang"].startswith("Pet - "):
            fam = s["DisplayName_lang"][6:]
            pet_lines[s["ID"]] = ("WARLOCK" if fam in WARLOCK_PETS else "HUNTER", fam)

    # trait tables
    nodes_by_tree = collections.defaultdict(list)
    for n in T.TraitNode:
        nodes_by_tree[n["TraitTreeID"]].append(n)
    entry = {r["ID"]: r for r in T.TraitNodeEntry}
    tdef = {r["ID"]: r for r in T.TraitDefinition}
    node_entries = collections.defaultdict(list)
    for r in sorted(T.TraitNodeXTraitNodeEntry, key=lambda r: int(r["_Index"])):
        node_entries[r["TraitNodeID"]].append(entry[r["TraitNodeEntryID"]])
    node_groups = collections.defaultdict(list)
    for r in T.TraitNodeGroupXTraitNode:
        node_groups[r["TraitNodeID"]].append(r["TraitNodeGroupID"])
    cond = {r["ID"]: r for r in T.TraitCond}
    group_conds = collections.defaultdict(list)
    for r in T.TraitNodeGroupXTraitCond:
        group_conds[r["TraitNodeGroupID"]].append(cond[r["TraitCondID"]])
    # TraitEdge.Type: 0 = drawn line only, 2 = sufficient for availability, 3 = required for availability
    edges_in = collections.defaultdict(list)
    for r in T.TraitEdge:
        if r["Type"] != "0":
            edges_in[r["RightTraitNodeID"]].append((r["LeftTraitNodeID"], r["Type"]))
    curve_pts = collections.defaultdict(list)
    for r in T.CurvePoint:
        curve_pts[r["CurveID"]].append((float(r["Pos_0"]), float(r["Pos_1"])))
    def_curves = collections.defaultdict(dict)
    for r in T.TraitDefinitionEffectPoints:
        def_curves[r["TraitDefinitionID"]][int(r["EffectIndex"])] = sorted(curve_pts[r["CurveID"]])

    def curve_at(pts, x):
        for px, py in pts:
            if abs(px - x) < 1e-6:
                return py
        return pts[-1][1] if pts else 0.0

    tree_of = {}
    for r in T.SkillLineXTraitTree:
        for cls, lines in class_lines.items():
            if r["SkillLineID"] in lines:
                tree_of[cls] = r["TraitTreeID"]

    out = {"build": build, "product": PRODUCT, "source": API, "classes": {}}
    for cls in CLASSES:
        bit = [b for b, c in bit_to_class.items() if c == cls][0]
        tabs = [t["Name_lang"] for t in sorted((t for t in T.TalentTab if int(t["ClassMask"]) == bit),
                                               key=lambda t: int(t["OrderIndex"]))]
        nodes = nodes_by_tree.get(tree_of.get(cls), [])
        # The client parks talents it took out far off the canvas (x or y ten times the rest): skip those.
        def p90(vals):
            vals = sorted(vals)
            return vals[int(0.9 * (len(vals) - 1))] if vals else 0
        mx_x, mx_y = 2 * p90(int(n["PosX"]) for n in nodes), 2 * p90(int(n["PosY"]) for n in nodes)
        hidden = sorted(S.name.get((tdef.get((node_entries.get(n["ID"]) or [{}])[0].get("TraitDefinitionID")) or {}).get("SpellID"), "?")
                        for n in nodes if int(n["PosX"]) > mx_x or int(n["PosY"]) > mx_y)
        nodes = [n for n in nodes if int(n["PosX"]) <= mx_x and int(n["PosY"]) <= mx_y]
        groups = clusters([int(n["PosX"]) for n in nodes], len(tabs))
        tab_of_x = {x: tabs[i] for i, g in enumerate(groups) for x in g}
        talents, by_node = {}, {}
        talent_spells = set()
        for tab in tabs:
            tn = [n for n in nodes if tab_of_x[int(n["PosX"])] == tab]
            ys = sorted(set(int(n["PosY"]) for n in tn))
            xs = sorted(set(int(n["PosX"]) for n in tn))
            for n in tn:
                ents = node_entries.get(n["ID"]) or []
                if not ents:
                    continue
                e = ents[0]
                d = tdef.get(e["TraitDefinitionID"]) or {}
                sid = d.get("SpellID", "0")
                name = d.get("OverrideName_lang") or S.name.get(sid) or "?"
                req = 0
                for g in node_groups.get(n["ID"], []):
                    for c in group_conds.get(g, []):
                        if c["CondType"] == "0" and int(c["SpentAmountRequired"] or 0) > 0:
                            req = max(req, int(c["SpentAmountRequired"]))
                mx = int(e["MaxRanks"])
                curves = def_curves.get(d.get("ID"), {})
                ranks = []
                for r in range(1, mx + 1):
                    over = {i: curve_at(p, r) for i, p in curves.items()}
                    ranks.append(S.render(sid, over, d.get("OverrideDescription_lang") or None))
                talent_spells.add(sid)
                t = {"tab": tab, "row": ys.index(int(n["PosY"])) + 1, "col": xs.index(int(n["PosX"])) + 1,
                     "max": mx, "req": req, "spell": int(sid), "icon": S.icon(sid, d.get("OverrideIcon", "0")),
                     "ranks": ranks, "node": int(n["ID"])}
                if name in talents:
                    name = "%s (%s)" % (name, tab)
                talents[name] = t
                by_node[n["ID"]] = name
        # prereq: any one of these maxed opens the talent (edge type 2); requires: all of these maxed (type 3)
        for n in nodes:
            if n["ID"] in by_node:
                ins = [(by_node[x], t) for x, t in edges_in.get(n["ID"], []) if x in by_node]
                talents[by_node[n["ID"]]]["prereq"] = sorted(x for x, t in ins if t != "3")
                if any(t == "3" for _, t in ins):
                    talents[by_node[n["ID"]]]["requires"] = sorted(x for x, t in ins if t == "3")

        spells = collections.defaultdict(list)
        pets = collections.defaultdict(list)
        seen = set()
        for r in T.SkillLineAbility:
            sid = r["Spell"]
            name = S.name.get(sid)
            if not name or (r["SkillLine"], sid) in seen:
                continue
            # AcquireMethod 3: internal copies the player never learns (effects, rune-era leftovers)
            if r["AcquireMethod"] == "3" and sid not in talent_spells:
                continue
            seen.add((r["SkillLine"], sid))
            lvl = S.level.get(sid, 0)
            item = {"id": int(sid), "rank": S.rank(sid), "level": lvl}
            if r["SkillLine"] in class_lines[cls]:
                if sid in talent_spells:
                    item["talent"] = True
                item["line"] = skill[r["SkillLine"]]["DisplayName_lang"]
                cost = [p for p in S.power.get(sid, []) if p["OrderIndex"] == "0"]
                pct = lambda pc: float(pc["PowerCostPct"] or 0)
                if cost and (float(cost[0]["ManaCost"] or 0) or pct(cost[0])):
                    pc = cost[0]
                    item["cost"] = ("%s%%" % num(pct(pc))) if pct(pc) else \
                        num(float(pc["ManaCost"]) / (10.0 if pc["PowerType"] == "1" else 1.0))
                    item["power"] = {"0": "Mana", "1": "Rage", "3": "Energy", "2": "Focus"}.get(pc["PowerType"], pc["PowerType"])
                cd = S.cooldown.get(sid)
                if cd and int(cd["RecoveryTime"] or 0) + int(cd["CategoryRecoveryTime"] or 0) > 0:
                    item["cooldown"] = secs(max(int(cd["RecoveryTime"] or 0), int(cd["CategoryRecoveryTime"] or 0)))
                item["icon"] = S.icon(sid)
                if sid in S.stances:
                    item["stances"] = S.stances[sid]
                cd = S.cooldown.get(sid)
                if cd and int(cd["CategoryRecoveryTime"] or 0) and sid in S.category:
                    item["cdgroup"] = int(S.category[sid])
                item["desc"] = S.render(sid)
                spells[name].append(item)
            elif r["SkillLine"] in pet_lines and pet_lines[r["SkillLine"]][0] == cls:
                item["pet"] = pet_lines[r["SkillLine"]][1]
                item["desc"] = S.render(sid)
                pets[name].append(item)
        for d in (spells, pets):
            for name in d:
                d[name].sort(key=lambda i: (i["rank"] or 0, i["level"], i["id"]))
        # spells that share one cooldown (same category with a category cooldown)
        groups = collections.defaultdict(set)
        for name, rows in spells.items():
            for r in rows:
                if r.get("cdgroup"):
                    groups[r["cdgroup"]].add(name)
        for name, rows in spells.items():
            for r in rows:
                g = r.pop("cdgroup", None)
                others = sorted(groups.get(g, set()) - {name})
                if others:
                    r["shares_cooldown"] = others
        out["classes"][cls] = {"tabs": tabs, "hidden": hidden, "talents": dict(sorted(talents.items())),
                               "spells": dict(sorted(spells.items())), "pet": dict(sorted(pets.items()))}
    out["professions"] = build_professions(T, S)
    out["professions"]["Herbalism"]["gathering"] = build_herbalism(T, S, skill["182"])
    out["rods"] = build_rods(T)
    out["quests"] = build_quests(T)
    return out


def build_quests(tables):
    maps = {int(row["ID"]): {"name": row["Name_lang"]} for row in tables.UiMap}
    extents = {}
    for row in tables.UiMapAssignment:
        map_id = int(row["UiMapID"])
        if map_id not in maps or int(row["OrderIndex"]) != 0:
            continue
        if [float(row[key]) for key in ("UiMin_0", "UiMin_1", "UiMax_0", "UiMax_1")] != [0, 0, 1, 1]:
            continue
        south, east, north, west = (float(row[f"Region_{i}"]) for i in (0, 1, 3, 4))
        if north > south and west > east:
            maps[map_id].update(width=round(west - east, 3), height=round(north - south, 3))
            extents[map_id] = (int(row["MapID"]), south, east, north, west)

    lines = {int(row["ID"]): {"name": row["Name_lang"], "ids": []} for row in tables.QuestLine}
    for row in sorted(tables.QuestLineXQuest, key=lambda row: int(row["OrderIndex"])):
        line = lines.get(int(row["QuestLineID"]))
        if line is not None:
            line["ids"].append(int(row["QuestID"]))

    points = collections.defaultdict(list)
    for row in tables.QuestPOIPoint:
        points[row["QuestPOIBlobID"]].append((float(row["X"]), float(row["Y"])))
    pois = collections.defaultdict(list)
    for row in tables.QuestPOIBlob:
        map_id = int(row["UiMapID"])
        if map_id not in extents:
            continue
        world, south, east, north, west = extents[map_id]
        if world != int(row["MapID"]):
            continue
        xy = [[round(100 * (west - y) / (west - east), 2),
               round(100 * (north - x) / (north - south), 2)] for x, y in points[row["ID"]]]
        pois[int(row["QuestID"])].append({"map": map_id, "objective": int(row["ObjectiveIndex"]), "points": xy})
    return {
        "ids": sorted(int(row["ID"]) for row in tables.QuestV2),
        "maps": maps,
        "flights": sorted({row["Name_lang"] for row in tables.TaxiNodes if row["Name_lang"]}),
        "lines": lines,
        "pois": dict(pois),
    }


def build_rods(T):
    """The Enchanting rods: TotemCategory rows of type 3, with the mask that says which lower rods a rod
    also counts as (a rod's mask holds the lower rods' bits) and the item of that category."""
    item_of = {r["TotemCategoryID"]: int(r["ID"]) for r in T.ItemSparse if r.get("TotemCategoryID") not in (None, "", "0")}
    rods = {}
    for r in T.TotemCategory:
        if r["TotemCategoryType"] == "3":
            rods[r["Name_lang"]] = {"category": int(r["ID"]), "mask": int(r["TotemCategoryMask"]), "item": item_of.get(r["ID"])}
    return dict(sorted(rods.items(), key=lambda kv: kv[1]["category"]))


def build_herbalism(T, S, skill_line):
    icons = {r["ID"]: S.icons.get(r["IconFileDataID"]) for r in T.Item if r["ID"] in HERBALISM_ITEMS}
    items = {r["ID"]: {"name": r["Display_lang"], "icon": icons.get(r["ID"])}
             for r in T.ItemSparse if r["ID"] in HERBALISM_ITEMS}
    locks = {}
    for row in T.Lock:
        skills = {int(row[f"Skill_{i}"]) for i in range(8)
                  if row[f"Type_{i}"] == "2" and row[f"_Index_{i}"] == "2"}
        if skills:
            locks[row["ID"]] = sorted(skills)
    areas = sorted({r["AreaName_lang"] for r in T.AreaTable if r["ParentAreaID"] == "0" and r["AreaName_lang"]})
    return {"icon": S.icons.get(skill_line["SpellIconFileID"]), "items": dict(sorted(items.items(), key=lambda p: int(p[0]))),
            "lockSkills": dict(sorted(locks.items(), key=lambda p: int(p[0]))), "areas": areas}


def build_professions(T, S):
    """Every recipe of each guided profession: colours, reagents, what it makes, its icon and plan.

    SkillLineAbility: TrivialSkillLineRankLow = turns yellow, TrivialSkillLineRankHigh = turns grey
    (green starts halfway). The skill a trainer teaches a recipe at is server-side, not in here."""
    item_name = {r["ID"]: r["Display_lang"] for r in T.ItemSparse}
    plan_skill = {r["ID"]: int(r["RequiredSkillRank"] or 0) for r in T.ItemSparse}
    item_icon = {r["ID"]: S.icons.get(r["IconFileDataID"]) for r in T.Item}
    reag = {r["SpellID"]: r for r in T.SpellReagents}
    cats = {r["ID"]: r["Name_lang"] for r in T.TradeSkillCategory}
    totem_name = {r["ID"]: r["Name_lang"] for r in T.TotemCategory}
    totems = {r["SpellID"]: r for r in T.SpellTotems}
    focus_name = {r["ID"]: r["Name_lang"] for r in T.SpellFocusObject}
    stations = {r["SpellID"]: focus_name.get(r["RequiresSpellFocus"]) for r in T.SpellCastingRequirements}
    makes, learns = {}, collections.defaultdict(list)
    for sid, effs in S.eff.items():
        for e in effs.values():
            if e["Effect"] == "24" and sid not in makes:
                makes[sid] = (e["EffectItemType"], int(round(float(e["EffectBasePointsF"] or 1))) or 1)
            elif e["Effect"] == "36":
                learns[sid].append(e["EffectTriggerSpell"])
    effect = {r["ID"]: r for r in T.ItemEffect}
    plans = collections.defaultdict(list)  # recipe spell -> plan items
    for r in T.ItemXItemEffect:
        e = effect.get(r["ItemEffectID"])
        if not e:
            continue
        # a plan names its recipe in an effect with trigger 6 (learn spell); older data in a
        # learn-spell effect of the spell the item casts
        taught = [e["SpellID"]] if e["TriggerType"] == "6" else learns.get(e["SpellID"], [])
        for t in taught:
            if r["ItemID"] not in plans[t]:
                plans[t].append(r["ItemID"])
    out = {}
    for prof, line in PROFESSIONS.items():
        rows = sorted((r for r in T.SkillLineAbility if r["SkillLine"] == str(line)
                       and int(r["TrivialSkillLineRankHigh"] or 0) > 0), key=lambda r: int(r["Spell"]))
        recipes, items, spells = {}, {}, collections.defaultdict(list)
        for r in rows:
            sid = r["Spell"]
            name = S.name.get(sid)
            if name and int(sid) not in spells[name]:
                spells[name].append(int(sid))
            if prof == "Cooking" and sid == "818":
                continue  # the Forever crafting recipe makes a kit (spell 1229737)
            if not name or name in recipes:
                continue  # a name clash keeps the lowest spell ID (all of them are in "clashes")
            y, g = int(r["TrivialSkillLineRankLow"] or 0), int(r["TrivialSkillLineRankHigh"])
            mats = []
            rg = reag.get(sid)
            for k in range(8):
                if rg and rg["Reagent_%d" % k] not in ("", "0"):
                    it = rg["Reagent_%d" % k]
                    mats.append([item_name.get(it, "item %s" % it), int(rg["ReagentCount_%d" % k])])
                    items[mats[-1][0]] = item_icon.get(it)
            made = makes.get(sid)
            rec = {"spell": int(sid), "yellow": y, "green": (y + g) // 2, "grey": g, "mats": mats,
                   "makes": [item_name.get(made[0], "item %s" % made[0]), made[1]] if made else None,
                   "icon": (item_icon.get(made[0]) if made else None) or S.icon(sid),
                   "category": cats.get(r["TradeSkillCategoryID"], "")}
            # the client sets a learn level on a few recipes; not always the trainer's (Heavy
            # Sharpening Stone says 125 but goes grey at 115), so it's a warning, not a fact
            if int(r["MinSkillLineRank"] or 0) > 1:
                rec["min"] = int(r["MinSkillLineRank"])
            totem = totems.get(sid, {})
            tool = totem_name.get(totem.get("RequiredTotemCategoryID_0"))
            if tool:
                rec["tool"] = tool  # e.g. Runed Silver Rod (or a better rod, see "rods")
            if prof == "Engineering":
                required_tools = [totem_name[totem[k]] for k in ("RequiredTotemCategoryID_0", "RequiredTotemCategoryID_1")
                                  if totem.get(k) in totem_name]
                if required_tools:
                    rec["tools"] = required_tools
            if prof in ("Engineering", "Cooking") and stations.get(sid):
                rec["station"] = stations[sid]
            if r.get("AcquireMethod") == "1":
                rec["auto"] = True  # learned with the profession
            if int(r.get("NumSkillUps") or 0) != 1:
                rec["skillups"] = int(r.get("NumSkillUps") or 0)  # points per craft (the counts assume 1)
            if made:
                items[rec["makes"][0]] = item_icon.get(made[0])
            for p in sorted(plans.get(sid, []), key=int):
                if p in item_name:
                    rec["plan"] = {"item": item_name[p], "skill": plan_skill.get(p, 0)}
                    break
            recipes[name] = rec
        out[prof] = {"skillLine": line, "recipes": dict(sorted(recipes.items())), "items": dict(sorted(items.items())),
                     "clashes": {n: ids for n, ids in sorted(spells.items()) if len(ids) > 1}}
    return out


def write_reference(ref, path=REF):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(ref, f, indent=1, ensure_ascii=False, sort_keys=False)
        f.write("\n")


def load_reference(path=REF):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Diff between two references
# ---------------------------------------------------------------------------

def diff(old, new):
    lines = ["Game data %s -> %s" % (old.get("build"), new.get("build"))]
    for cls in CLASSES:
        a, b = old["classes"].get(cls, {}), new["classes"].get(cls, {})
        out = []
        ta, tb = a.get("talents", {}), b.get("talents", {})
        for n in sorted(set(ta) - set(tb)):
            out.append("  talent removed: %s (%s row %d)" % (n, ta[n]["tab"], ta[n]["row"]))
        for n in sorted(set(tb) - set(ta)):
            t = tb[n]
            out.append("  talent new: %s (%s row %d col %d, %d rank(s), needs %d points): %s"
                       % (n, t["tab"], t["row"], t["col"], t["max"], t["req"], t["ranks"][-1] if t["ranks"] else ""))
        for n in sorted(set(ta) & set(tb)):
            x, y = ta[n], tb[n]
            for k in ("tab", "row", "col", "max", "req", "prereq", "requires", "icon"):
                if x.get(k) != y.get(k):
                    out.append("  talent %s: %s %s -> %s" % (n, k, x.get(k), y.get(k)))
            if x.get("ranks") != y.get("ranks"):
                out.append("  talent %s text: %s\n      now: %s" % (n, (x["ranks"] or [""])[-1], (y["ranks"] or [""])[-1]))
        for kind in ("spells", "pet"):
            sa, sb = a.get(kind, {}), b.get(kind, {})
            for n in sorted(set(sa) - set(sb)):
                out.append("  %s removed: %s" % (kind[:-1] if kind == "spells" else "pet spell", n))
            for n in sorted(set(sb) - set(sa)):
                out.append("  %s new: %s (level %s)" % ("spell" if kind == "spells" else "pet spell", n,
                                                       ", ".join(str(i["level"]) for i in sb[n])))
            for n in sorted(set(sa) & set(sb)):
                ra = {(i["rank"], i["id"]): i for i in sa[n]}
                rb = {(i["rank"], i["id"]): i for i in sb[n]}
                la = sorted((i["rank"] or 0, i["level"]) for i in sa[n])
                lb = sorted((i["rank"] or 0, i["level"]) for i in sb[n])
                if la != lb:
                    out.append("  %s ranks/levels: %s -> %s" % (n, la, lb))
                for key in set(ra) & set(rb):
                    for k in ("cost", "cooldown", "desc", "stances", "shares_cooldown"):
                        if ra[key].get(k) != rb[key].get(k):
                            out.append("  %s%s %s: %s -> %s" % (n, " (Rank %s)" % key[0] if key[0] else "", k,
                                                               ra[key].get(k), rb[key].get(k)))
        if out:
            lines.append(cls)
            lines.extend(out)
    if len(lines) == 1:
        lines.append("no class changes")
    for prof in PROFESSIONS:
        prev = (old.get("professions") or {}).get(prof) or {}
        curr = (new.get("professions") or {}).get(prof) or {}
        a, b = prev.get("recipes", {}), curr.get("recipes", {})
        out = []
        if not a and b:
            out.append("  first profession data: %d recipes" % len(b))
        else:
            for n in sorted(set(a) - set(b)):
                out.append("  recipe removed: %s" % n)
            for n in sorted(set(b) - set(a)):
                out.append("  recipe new: %s (yellow %d, grey %d)" % (n, b[n]["yellow"], b[n]["grey"]))
            for n in sorted(set(a) & set(b)):
                for k in ("yellow", "grey", "mats", "makes"):
                    if a[n].get(k) != b[n].get(k):
                        out.append("  recipe %s %s: %s -> %s" % (n, k, a[n].get(k), b[n].get(k)))
        if prof == "Herbalism":
            out.extend(diff_herbalism(prev.get("gathering"), curr.get("gathering")))
        if out:
            lines.append(prof.upper())
            lines.extend(out)
    return "\n".join(lines)


def diff_herbalism(old, new):
    if not old:
        return ["  first Herbalism gathering data"] if new else []
    if not new:
        return ["  Herbalism gathering data removed"]
    out = []
    if old["icon"] != new["icon"]:
        out.append(f"  Herbalism icon: {old['icon']} -> {new['icon']}")
    for key, label in (("items", "herb item"), ("lockSkills", "herbalism lock")):
        before, after = old[key], new[key]
        for record in sorted(before.keys() | after.keys(), key=int):
            if before.get(record) != after.get(record):
                out.append(f"  {label} {record}: {before.get(record)} -> {after.get(record)}")
    before, after = set(old["areas"]), set(new["areas"])
    out.extend("  area added: " + name for name in sorted(after - before))
    out.extend("  area removed: " + name for name in sorted(before - after))
    return out


def recipe_list(ref, prof, name=None, *, exact=False):
    """One line per recipe of a profession, by the skill it turns yellow at."""
    P = (ref.get("professions") or {}).get(prof)
    if not P:
        return "no profession '%s' in the reference (have: %s)" % (prof, ", ".join(ref.get("professions") or {}))
    out = []
    for n, r in sorted(P["recipes"].items(), key=lambda kv: (kv[1]["yellow"], kv[1]["grey"], kv[0])):
        if name and (n != name if exact else name.lower() not in n.lower()):
            continue
        mats = ", ".join("%d %s" % (c, it) for it, c in r["mats"])
        plan = (" plan: %s (%d)" % (r["plan"]["item"], r["plan"]["skill"])) if r.get("plan") else ""
        tools = " tools: " + ", ".join(r["tools"]) if r.get("tools") else ""
        station = " station: " + r["station"] if r.get("station") else ""
        out.append("y%-3d g%-3d gr%-3d %-34s [%s]  spell %d  icon %s%s%s%s" %
                   (r["yellow"], r["green"], r["grey"], n, mats, r["spell"], r.get("icon"), plan, tools, station))
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Audit: Data.lua against the reference
# ---------------------------------------------------------------------------

def load_lua_global(path, name):
    """Run one or more data files in load order and read a global as Python data."""
    import lupa.lua51 as lupa
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    for one in (path if isinstance(path, (list, tuple)) else [path]):
        with open(one, encoding="utf-8") as f:
            lua.execute(f.read())

    def conv(t):
        if lupa.lua_type(t) != "table":
            return t
        keys = list(t.keys())
        if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
            return [conv(t[k]) for k in sorted(keys)]
        if not keys:
            return []
        return {str(k): conv(v) for k, v in t.items()}
    return conv(lua.globals()[name])


def load_data(path=os.path.join(ROOT, "Data.lua")):
    return load_lua_global(path, "LevelingCodexData")


PROFDATA = os.path.join(ROOT, "ProfessionData.lua")


def load_profdata(path=PROFDATA):
    """ProfessionData.lua's LevelingCodexProfessions, or None when the file isn't there."""
    if not os.path.exists(path):
        return None
    return load_lua_global(path, "LevelingCodexProfessions")


def expected_crafts(a, b, yellow, grey):
    """Expected crafts from skill a to b: one per point below yellow, then (grey - s) / (grey - yellow).
    None when the recipe is grey before b (it can't get you there)."""
    total = 0.0
    for s in range(a, b):
        if s >= grey:
            return None
        total += 1.0 if s < yellow else (grey - yellow) / float(grey - s)
    return total


def _mats(m):
    return [[x[0], int(x[1])] for x in (m or [])]


def audit_herbalism(guide, reference, add):
    gathering = reference.get("gathering")
    if not gathering:
        add("error", "missing Herbalism gathering evidence in the reference")
        return
    if guide.get("skillLine") != reference["skillLine"] or guide.get("icon") != gathering["icon"]:
        add("error", "Herbalism skill line or icon differs from the client")
    lock_skills = {skill for skills in gathering["lockSkills"].values() for skill in skills}
    areas = set(gathering["areas"])
    herbs = {}
    for herb in guide.get("herbs") or []:
        name = herb["name"]
        item = gathering["items"].get(str(herb.get("item"))) or {}
        if item.get("name") != name:
            add("error", f"{name} item {herb.get('item')} does not match the client")
        if not item.get("icon") or item["icon"] != herb.get("icon"):
            add("error", f"{name} icon does not match the client")
        if herb.get("skill") not in lock_skills:
            add("error", f"{name} skill {herb.get('skill')} has no client herbalism lock")
        cuts = tuple(herb.get(k) for k in ("skill", "yellow", "green", "grey"))
        if not (all(isinstance(n, int) for n in cuts) and cuts[0] <= cuts[1] <= cuts[2] < cuts[3]):
            add("error", f"{name} has invalid difficulty thresholds: {cuts}")
            continue
        herbs[name] = herb
        for zones in herb["zones"].values():
            for zone in zones:
                if zone not in areas:
                    add("error", f"{name}: {zone} is absent from the client's top-level areas")

    for step in guide.get("steps") or []:
        nodes = [herbs[name] for name in step.get("herbs", []) if name in herbs]
        for faction in ("Alliance", "Horde"):
            available = [h for h in nodes if h["zones"].get("All") or h["zones"].get(faction)]
            for skill in range(step["from"], step["to"]):
                if not any(h["skill"] <= skill < h["grey"] for h in available):
                    add("error", f"step {step['from']}-{step['to']}: no usable herb at skill {skill} for {faction}")
                    break


def audit_professions(profdata, ref):
    """[(PROFESSION, 'error'|'warn', message)]: ProfessionData.lua against the game reference."""
    res = []
    refp = ref.get("professions") or {}
    for key, P in sorted((profdata or {}).items()):
        def add(level, msg):
            res.append((key, level, msg))
        R = refp.get(P.get("name"))
        if not R:
            add("error", "no profession '%s' in the game reference" % P.get("name"))
            continue
        if P.get("skillLine") != R["skillLine"]:
            add("error", "skill line does not match the client")
        recipes, items = R["recipes"], R["items"]
        if key == "HERBALISM":
            audit_herbalism(P, R, add)

        def check_recipe(where, x, name):
            r = recipes.get(name)
            if not r:
                add("error", "%s: '%s' is not a %s recipe in game" % (where, name, P["name"]))
                return None
            if x.get("spell") != r["spell"]:
                add("error", "%s: %s is spell %s in game, data says %s" % (where, name, r["spell"], x.get("spell")))
            if (x.get("yellow"), x.get("grey")) != (r["yellow"], r["grey"]):
                add("error", "%s: %s is yellow %d / grey %d in game, data says %s / %s" %
                    (where, name, r["yellow"], r["grey"], x.get("yellow"), x.get("grey")))
            if _mats(x.get("mats")) != r["mats"]:
                add("error", "%s: %s takes %s in game, data says %s" % (where, name, r["mats"], _mats(x.get("mats"))))
            if key == "ENGINEERING":
                if (x.get("tools") or []) != (r.get("tools") or []):
                    add("error", f"{where}: {name} needs tools {r.get('tools')}, guide says {x.get('tools')}")
            if key in ("ENGINEERING", "COOKING"):
                if x.get("station") != r.get("station"):
                    add("error", f"{where}: {name} needs station {r.get('station')}, guide says {x.get('station')}")
            if isinstance(x.get("makes"), list) and [x["makes"][0], int(x["makes"][1])] != r.get("makes"):
                add("error", "%s: %s makes %s in game, data says %s" % (where, name, r.get("makes"), x["makes"]))
            if x.get("icon") and r.get("icon") and x["icon"].lower() != r["icon"]:
                add("warn", "%s: %s icon is %s in game, data uses %s" % (where, name, r["icon"], x["icon"]))
            clash = (R.get("clashes") or {}).get(name)
            if clash:
                add("warn", "%s: the game has %d recipes named %s (spells %s): the reference keeps the lowest, "
                    "check it's the one trainers teach" % (where, len(clash), name, ", ".join(str(c) for c in clash)))
            if r.get("skillups", 1) != 1:
                add("warn", "%s: %s gives %d points per craft in game; the craft counts assume 1" % (where, name, r["skillups"]))
            source = (x.get("source") or "").lower()
            if source and r.get("auto") and "known when you learn" not in source:
                add("warn", "%s: %s is learned with %s in game, data says: %s" % (where, name, P["name"], x["source"]))
            if source and not r.get("auto") and "known when you learn" in source:
                add("warn", "%s: %s isn't learned with %s in game: a trainer or a plan teaches it" % (where, name, P["name"]))
            plan = r.get("plan")
            if plan and "trainer" in source:
                add("warn", "%s: %s is taught by %s (skill %d) in game, data says a trainer teaches it" %
                    (where, name, plan["item"], plan["skill"]))
            if plan and x.get("learn") and plan["skill"] and x["learn"] != plan["skill"]:
                add("warn", "%s: %s: %s asks for skill %d, data says learned at %d" %
                    (where, name, plan["item"], plan["skill"], x["learn"]))
            if r.get("min") and x.get("learn") and x["learn"] < r["min"]:
                add("warn", "%s: %s: the client says it's learned at %d, data says %d (check at a trainer, /codex debug)" %
                    (where, name, r["min"], x["learn"]))
            return r

        steps = P.get("steps") or []
        if not steps or steps[0]["from"] != 1 or steps[-1]["to"] != 300:
            add("error", "steps must run from 1 to 300 (have %s-%s)" %
                (steps[0]["from"] if steps else "?", steps[-1]["to"] if steps else "?"))
        for a, b in zip(steps, steps[1:]):
            if a["to"] != b["from"]:
                add("error", "steps %d-%d and %d-%d leave a gap or overlap" % (a["from"], a["to"], b["from"], b["to"]))
        tiers = P.get("tiers") or []
        for t, n in zip(tiers, tiers[1:]):
            if n["skill"] > t["cap"]:
                add("error", "tier %s needs %d but %s stops at %d" % (n["name"], n["skill"], t["name"], t["cap"]))
        if tiers and steps and tiers[-1]["cap"] < steps[-1]["to"]:
            add("error", "the last tier stops at %d, the route goes to %d" % (tiers[-1]["cap"], steps[-1]["to"]))
        # Crafted inputs need a part or an earlier step, unless the route gathers them directly.
        own = {r["makes"][0] for r in recipes.values() if r.get("makes")}
        gathered = set(P.get("gathered") or [])
        for item in sorted(gathered - set(items)):
            add("error", f"gathered material {item} does not match a client item")
        provided = {(p.get("makes") or [p.get("name")])[0] for p in P.get("parts") or []}
        for s in steps:
            where = "step %d-%d" % (s["from"], s["to"])
            for m in s.get("mats") or []:
                item = _mats([m])[0][0]
                if item in own and item not in provided and item not in gathered:
                    add("error", "%s: %s is made by a %s recipe: add it to parts or a step's makes" % (where, item, P["name"]))
            if isinstance(s.get("makes"), list):
                provided.add(s["makes"][0])
            if s.get("name"):  # a crafting step
                r = check_recipe(where, s, s["name"])
                if r and P.get("rods") and r.get("tool") != s.get("rod"):  # professions with rods: each step names its own
                    add("error", "%s: %s needs %s in game, data says %s" % (where, s["name"], r.get("tool"), s.get("rod")))
                if not r:
                    continue
                if expected_crafts(s["from"], s["to"], r["yellow"], r["grey"]) is None:
                    add("error", "%s: %s turns grey at %d, before the step ends" % (where, s["name"], r["grey"]))
                else:
                    green = sum(1 for k in range(s["from"], s["to"]) if k >= r["green"])
                    if green * 2 > s["to"] - s["from"]:
                        add("warn", "%s: %s is green for %d of its %d points" % (where, s["name"], green, s["to"] - s["from"]))
                if s.get("learn") and s["learn"] > s["from"]:
                    add("warn", "%s: %s is learned at %d, after the step starts" % (where, s["name"], s["learn"]))
        for sm in P.get("smelt") or []:
            check_recipe("smelt", sm, sm["name"])
        for camp in P.get("camp") or []:
            name = camp["name"]
            recipe = recipes.get(name)
            spell = camp.get("spell")
            legacy = spell is None and key in ("BLACKSMITHING", "MINING")
            if not recipe or (not legacy and spell != recipe["spell"]):
                add("error", f"{name}: camp recipe spell does not match the client")
                continue
            plan = recipe.get("plan")
            if plan and camp["skill"] != plan["skill"]:
                # Blizzard's Nov 6 server hotfix still overrides the client (140 in builds up to 1.60.1.70888).
                if key == "LEATHERWORKING" and name == "Tanning Rack" and (camp["skill"], plan["skill"]) == (125, 140):
                    continue
                add("error", f"{name}: {plan['item']} needs {plan['skill']}, guide says {camp['skill']}")
        for p in P.get("parts") or []:
            r = check_recipe("part", p, p["name"])
            if r and P.get("rods") and r.get("tool") != p.get("rod"):
                add("error", "part %s needs %s in game, data says %s" % (p["name"], r.get("tool"), p.get("rod")))
        rods = ref.get("rods") or {}
        for rod in P.get("rods") or []:
            check_recipe("rod", rod, rod["name"])
            want = rods.get(rod["name"])
            if not want:
                add("error", "rod %s: not a rod in game" % rod["name"])
            elif (rod.get("category"), rod.get("mask")) != (want["category"], want["mask"]):
                add("error", "rod %s: category %s mask %s in game, data says %s / %s" %
                    (rod["name"], want["category"], want["mask"], rod.get("category"), rod.get("mask")))
        for b in ((P.get("disenchant") or {}).get("bands") or []):
            for f in ("dust", "essence", "shard", "epic"):
                if b.get(f) and b[f] not in items:
                    add("error", "disenchant: %s is not an %s material" % (b[f], P["name"]))
        for c in P.get("cloth") or []:
            if c.get("name") not in items:
                add("error", "cloth %s: no %s recipe uses it" % (c.get("name"), P["name"]))
            elif c.get("icon") and items[c["name"]] and c["icon"].lower() != items[c["name"]]:
                add("warn", "cloth %s: icon is %s in game, data uses %s" % (c["name"], items[c["name"]], c["icon"]))
        for v in P.get("veins") or []:
            want = items.get(v.get("ore"))
            if want and v.get("icon") and v["icon"].lower() != want:
                add("warn", "vein %s: %s icon is %s in game, data uses %s" % (v["name"], v["ore"], want, v["icon"]))
            elif v.get("ore") and v["ore"] not in items:
                add("warn", "vein %s: no recipe uses '%s'" % (v["name"], v["ore"]))
    return res


def full_audit(ref, only=None):
    """What `update` and `audit` report: Data.lua against the game, and ProfessionData.lua unless
    -k names a class (-k BLACKSMITHING shows one profession)."""
    only = (only or "").upper() or None
    res = audit(load_data(), ref, only) if not only or only in CLASSES else []
    if not only or only not in CLASSES:
        res += [r for r in audit_professions(load_profdata() or {}, ref) if not only or r[0] == only]
    if not only or only == "QUESTS":
        res += audit_quests(ref)
    return res


def audit_quests(ref):
    from questroute import ROUTE, ROUTES, audit

    if not ROUTE.exists():
        return []
    return audit(load_lua_global(ROUTES, "LevelingCodexQuests"), ref)


def groups(res):
    """The classes, then any profession, in the order reports list them."""
    return CLASSES + sorted({c for c, _, _ in res if c not in CLASSES})


ROMAN = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
RANKED = re.compile(r"^(.*?)\s*\(Rank (\d+)\)\s*$")


def split_rank(s):
    m = RANKED.match(s.strip())
    return (m.group(1).strip(), int(m.group(2))) if m else (s.strip(), None)


def first_level(rows):
    """Lowest level among a name's spell IDs; IDs at level 0 are internal copies (unless all are)."""
    lv = [r["level"] for r in rows if r["level"] > 0]
    return min(lv) if lv else 1


def is_sentence(s):
    """Guide text in a spell list rather than a spell name (also "New level-20 spells", the race-spell slot)."""
    return s.rstrip().endswith(".") or len(s.split()) > 5 or bool(re.match(r"New level-\d+ spells$", s.strip()))


def macro_spells(body):
    """(command, spell) for every spell a macro casts or shows."""
    out = []
    for line in body.split("\n"):
        line = line.strip()
        m = re.match(r"#show(?:tooltip)?\s+(.*)", line)
        if m:
            if m.group(1).strip():
                out.append(("#show", m.group(1).strip()))
            continue
        m = re.match(r"/(cast|castsequence|use|castrandom)\s+(.*)", line)
        if not m:
            continue
        cmd, rest = m.group(1), m.group(2)
        for clause in rest.split(";"):
            clause = re.sub(r"\[[^\]]*\]", "", clause).strip()
            clause = re.sub(r"^reset=\S+\s*", "", clause)
            parts = clause.split(",") if cmd in ("castsequence", "castrandom") else [clause]
            for p in parts:
                p = p.strip().lstrip("!").strip()
                if p and not p.isdigit() and not re.match(r"^\d+\s+\d+$", p):
                    out.append((cmd, p))
    return out


def audit(data, ref, only=None):
    """[(class, 'error'|'warn'|'info', message)]. Errors: the game says the guide can't be done as written."""
    res = []
    for cls in CLASSES:
        if only and only.upper() != cls:
            continue
        d, R = data.get(cls), ref["classes"].get(cls)
        if not d or not R:
            continue

        def add(level, msg):
            res.append((cls, level, msg))
        talents, spells, pets = R["talents"], R["spells"], R["pet"]
        tl = {n.lower(): n for n in talents}
        sl = {n.lower(): n for n in spells}
        pl = {n.lower(): n for n in pets}

        # --- talent plan, point by point in level order
        points = []
        for p in d["plan"]:
            for lvl in range(p["from"], p["to"] + 1):
                points.append((lvl, p))
        points.sort(key=lambda x: x[0])
        in_tab, taken = collections.Counter(), collections.Counter()
        learned = {}
        for p in d["plan"]:
            n = tl.get(p["name"].lower())
            if not n:
                add("error", "plan: talent '%s' is not in the %s tree" % (p["name"], cls))
                continue
            t = talents[n]
            if p["tree"] != t["tab"]:
                add("error", "plan: %s is in %s, not %s" % (n, t["tab"], p["tree"]))
            if p["max"] != t["max"]:
                add("error", "plan: %s has %d rank(s), not %d" % (n, t["max"], p["max"]))
            if t.get("icon") and p.get("icon") and p["icon"].lower() != t["icon"]:
                add("warn", "plan: %s icon is %s in game, guide uses %s" % (n, t["icon"], p["icon"]))
        for lvl, p in points:
            n = tl.get(p["name"].lower())
            if not n:
                continue
            t = talents[n]
            if in_tab[t["tab"]] < t["req"]:
                add("error", "plan: level %d %s needs %d points in %s, only %d spent" %
                    (lvl, n, t["req"], t["tab"], in_tab[t["tab"]]))
            pre = t.get("prereq", [])
            if pre and not any(taken[x] >= talents[x]["max"] for x in pre):
                add("error", "plan: level %d %s needs %s maxed first" % (lvl, n, " or ".join(
                    "%s %d/%d (has %d)" % (x, talents[x]["max"], talents[x]["max"], taken[x]) for x in pre)))
            for x in t.get("requires", []):
                if taken[x] < talents[x]["max"]:
                    add("error", "plan: level %d %s needs %s %d/%d first (has %d)" %
                        (lvl, n, x, talents[x]["max"], talents[x]["max"], taken[x]))
            in_tab[t["tab"]] += 1
            taken[n] += 1
            learned.setdefault(n, lvl)
        for n, k in taken.items():
            if k > talents[n]["max"]:
                add("error", "plan: %s gets %d points, max %d" % (n, k, talents[n]["max"]))

        def spell_level(name, rank=None):
            """Level a name is first usable at, or None if the game doesn't know it."""
            low = name.lower()
            if name in INNATE:
                return 1
            if low in tl:
                n = tl[low]
                return learned.get(n, 99)
            if low in sl:
                rows = spells[sl[low]]
                if rank:
                    rows = [r for r in rows if r["rank"] == rank]
                    if not rows:
                        return None
                talent = any(r.get("talent") for r in spells[sl[low]])
                lv = first_level(rows)
                if talent and sl[low].lower() in tl:
                    return max(lv, learned.get(tl[sl[low].lower()], 99))
                return lv
            if low in pl:
                return first_level(pets[pl[low]])
            return None

        # --- trainer visits
        mentioned = set()
        for v in d["train"]:
            for s in v["spells"]:
                if is_sentence(s):
                    for n in spells:
                        if re.search(r"\b%s\b" % re.escape(n), s):
                            mentioned.add(n)
                    continue
                name, rank = split_rank(s)
                low = name.lower()
                if low in sl:
                    n = sl[low]
                    mentioned.add(n)
                    rows = spells[n]
                    if rank:
                        rr = [r for r in rows if r["rank"] == rank]
                        roman = "%s %s" % (n, ROMAN[rank]) if rank < len(ROMAN) else None
                        if not rr and roman in spells:
                            add("warn", "trainer %d: the game calls %s '%s'" % (v["level"], s, roman))
                            mentioned.add(roman)
                            rr = spells[roman]
                        if not rr:
                            add("error", "trainer %d: %s has no Rank %d (ranks %s)" %
                                (v["level"], n, rank, [r["rank"] for r in rows]))
                            continue
                        lv = first_level(rr)
                    else:
                        lv = first_level(rows)
                    if lv > v["level"]:
                        add("error", "trainer %d: %s%s is level %d in game" % (v["level"], s, "", lv))
                    elif lv < v["level"] and lv > 0:
                        add("warn", "trainer %d: %s is available from level %d" % (v["level"], s, lv))
                elif low in tl:
                    add("warn", "trainer %d: %s is a talent in game, not a trainer spell" % (v["level"], name))
                elif low in pl:
                    lv = first_level(pets[pl[low]])
                    if lv > v["level"]:
                        add("error", "trainer %d: pet spell %s is level %d in game" % (v["level"], name, lv))
                elif low.endswith("s") and any(n.lower().startswith(low[:-1]) for n in spells):
                    pass  # "Teleports", "Portals": shorthand for a family of spells
                else:
                    add("warn", "trainer %d: '%s' is not a %s spell in game" % (v["level"], s, cls))
        # new abilities (rank 1 or unranked) the trainer list never mentions
        for n, rows in spells.items():
            real = [r for r in rows if r["level"] > 0]
            if not real or real[0].get("talent") or real[0]["level"] > 60 or (real[0]["rank"] or 1) != 1:
                continue
            if n not in mentioned and n.lower() not in tl:
                add("info", "trainer: %s (level %d) is never listed" % (n, real[0]["level"]))

        # --- macros
        for m in d["macros"]:
            where = "macro %s (%d-%d)" % (m["name"], m["lo"], m["hi"])
            for cmd, s in macro_spells(m["body"]):
                name, rank = split_rank(s.replace("(Rank", " (Rank"))
                lv = spell_level(name, rank)
                if lv is None:
                    if cmd == "use":
                        add("info", "%s: uses '%s' (an item?)" % (where, s))
                    else:
                        add("error", "%s: '%s' is not a spell this class has" % (where, s))
                elif lv > m["hi"]:
                    add("error", "%s: %s is only learned at %d, after the macro's levels" % (where, name, lv))
                elif lv > m["lo"]:
                    if cmd == "castsequence":
                        add("error", "%s: castsequence step %s is learned at %d: the sequence stalls at %d-%d" %
                            (where, name, lv, m["lo"], lv - 1))
                    else:
                        add("info", "%s: %s is learned at %d (skipped before)" % (where, name, lv))

        # --- text: "Name (NN)" level mentions and "Name N/M" ranks
        texts = []
        for p in d["plan"]:
            texts += [("plan %d %s" % (p["from"], p["name"]), p.get("why") or ""), ("plan %d %s more" % (p["from"], p["name"]), p.get("more") or "")]
        for v in d["train"]:
            texts += [("trainer %d note" % v["level"], x) for x in v.get("notes") or []]
        for b in d["br"]:
            texts += [("tips %s" % b["range"], b.get("intro") or "")] + [("tips %s" % b["range"], x) for x in b["steps"]]
        for m in d["macros"]:
            texts += [("macro %s (%d-%d) tip" % (m["name"], m["lo"], m["hi"]), x) for x in m.get("tips") or []]
        names = sorted(set(spells) | set(talents) | set(pets), key=len, reverse=True)
        pat = re.compile(r"(?<![\w'])(%s) \((\d+)\)" % "|".join(re.escape(n) for n in names)) if names else None
        rk = re.compile(r"(?<![\w'])(%s) (\d)/(\d)" % "|".join(re.escape(n) for n in talents)) if talents else None
        for where, text in texts:
            for mm in (pat.finditer(text) if pat else []):
                n, at = mm.group(1), int(mm.group(2))
                lv = spell_level(n)
                if lv is not None and lv != at and lv != 99:
                    add("warn", "%s: says %s (%d), game/plan has it at %d" % (where, n, at, lv))
                elif lv == 99:
                    add("warn", "%s: says %s (%d) but the plan never takes it" % (where, n, at))
            for mm in (rk.finditer(text) if rk else []):
                n, mx = mm.group(1), int(mm.group(3))
                if talents[n]["max"] != mx:
                    add("warn", "%s: says %s %s/%d, it has %d rank(s)" % (where, n, mm.group(2), mx, talents[n]["max"]))
    return res


def review(data, ref, cls):
    d, R = data[cls], ref["classes"][cls]
    tl = {n.lower(): n for n in R["talents"]}
    taken = collections.Counter()
    out = []
    for p in sorted(d["plan"], key=lambda p: p["from"]):
        n = tl.get(p["name"].lower())
        a = taken[n] + 1
        b = taken[n] + p["to"] - p["from"] + 1
        taken[n] = b
        out.append("L%d-%d  %s %d/%d -> %d/%d  [%s]" % (p["from"], p["to"], p["name"], a - 1, p["max"], b, p["max"], p["tree"]))
        out.append("   why : " + (p.get("why") or ""))
        if p.get("more"):
            out.append("   more: " + p["more"])
        if n:
            t = R["talents"][n]
            out.append("   GAME: %s row %d col %d, needs %d, prereq %s" % (t["tab"], t["row"], t["col"], t["req"],
                       " or ".join(t.get("prereq") or []) + " and ".join(t.get("requires") or []) or "-"))
            out.append("   r%d  : %s" % (a, t["ranks"][a - 1] if a - 1 < len(t["ranks"]) else "?"))
            if b != a:
                out.append("   r%d  : %s" % (b, t["ranks"][b - 1] if b - 1 < len(t["ranks"]) else "?"))
        else:
            out.append("   GAME: not in the tree")
    return "\n".join(out)


def packet(data, ref, cls):
    """Everything about one class's guide next to what the game says: the input for a manual review."""
    d, R = data[cls], ref["classes"][cls]
    spells, talents, pets = R["spells"], R["talents"], R["pet"]
    sl = {n.lower(): n for n in spells}
    pl = {n.lower(): n for n in pets}

    def about(name):
        name, rank = split_rank(name)
        low = name.lower()
        if low in sl:
            rows = spells[sl[low]]
            if rank:
                rows = [r for r in rows if r["rank"] == rank] or rows
            real = [r for r in rows if r["level"] > 0] or rows
            r = real[0] if not rank else real[-1]
            extra = ", ".join(x for x in [("%s %s" % (r.get("cost"), r.get("power"))) if r.get("cost") else "",
                                          ("cd " + r["cooldown"]) if r.get("cooldown") else "",
                                          ("shares cd with " + ", ".join(r["shares_cooldown"])) if r.get("shares_cooldown") else "",
                                          ("only in " + " / ".join(r["stances"])) if r.get("stances") else ""] if x)
            ranks = ", ".join("%s%d" % ("r%d@" % x["rank"] if x["rank"] else "", x["level"]) for x in real)
            return "%s [%s]%s: %s" % (sl[low], ranks, (" (" + extra + ")") if extra else "", r.get("desc", ""))
        if low in pl:
            r = pets[pl[low]][0]
            return "%s [pet %s, level %d]: %s" % (pl[low], r["pet"], r["level"], r.get("desc", ""))
        for n, t in talents.items():
            if n.lower() == low:
                return "%s [talent, %s row %d]: %s" % (n, t["tab"], t["row"], t["ranks"][-1])
        return "%s: NOT FOUND in game data for %s" % (name, cls)

    out = ["#### %s: %s (%s) vs WoW: Forever build %s" % (cls, d["guide"], d["spec"], ref["build"]), ""]
    out.append("## Automatic audit (error = impossible in game, warn = likely wrong, info = worth a look)")
    out += ["  %-5s %s" % (l, m) for c, l, m in audit(data, ref, cls)] or ["  (nothing)"]
    out += ["", "## Talent plan vs the game's tooltips (rN = tooltip at that rank)", review(data, ref, cls)]
    out += ["", "## The whole talent tree in game", tree(ref, cls)]
    if R.get("hidden"):
        out.append("(hidden in game, not takeable: %s)" % ", ".join(R["hidden"]))
    out += ["", "## Trainer visits (guide text, then the game)"]
    for v in d["train"]:
        out.append("L%d" % v["level"])
        for i, s in enumerate(v["spells"]):
            note = (v.get("notes") or [""] * len(v["spells"]))[i] if i < len(v.get("notes") or []) else ""
            out.append("  - %s  // note: %s" % (s, note))
            if not is_sentence(s):
                out.append("      GAME: " + about(s)[:400])
    out += ["", "## Macros"]
    for m in d["macros"]:
        out.append("[%s] '%s' levels %d-%d  pad %s  key %s  icon %s" % (m["name"], m["title"], m["lo"], m["hi"], m["pad"], m["kb"], m["icon"]))
        out += ["    " + l for l in m["body"].split("\n")]
        out += ["    tip: " + t for t in m.get("tips") or []]
        seen = set()
        for cmd, s in macro_spells(m["body"]):
            if s not in seen:
                seen.add(s)
                out.append("    GAME: " + about(s)[:400])
    out += ["", "## Tip chapters"]
    for b in d["br"]:
        out.append("[%s] %s (icon %s)" % (b["range"], b["title"], b.get("icon")))
        out.append("  intro: " + (b.get("intro") or ""))
        out += ["  - " + s for s in b["steps"]]
    out += ["", "## Every class spell in game (name [rank@level ...])", spell_list(ref, cls)]
    return "\n".join(out)


def tree(ref, cls):
    R = ref["classes"][cls]
    out = []
    for tab in R["tabs"]:
        out.append("== " + tab)
        ts = sorted(((t["row"], t["col"], n, t) for n, t in R["talents"].items() if t["tab"] == tab))
        for row, col, n, t in ts:
            pre = (" <- " + " or ".join(t["prereq"])) if t.get("prereq") else ""
            pre += (" <- needs " + " and ".join(t["requires"])) if t.get("requires") else ""
            out.append("  r%d c%d %-32s %d rank(s), needs %2d%s :: %s" % (row, col, n, t["max"], t["req"], pre, t["ranks"][-1] if t["ranks"] else ""))
    return "\n".join(out)


def spell_list(ref, cls, name=None):
    R = ref["classes"][cls]
    out = []
    for kind in ("spells", "pet"):
        for n, rows in sorted(R[kind].items(), key=lambda kv: (kv[1][0]["level"], kv[0])):
            if name and name.lower() not in n.lower():
                continue
            lv = ", ".join("%s%d" % ("r%d@" % r["rank"] if r["rank"] else "", r["level"]) for r in rows)
            extra = " [talent]" if rows[0].get("talent") else (" [pet: %s]" % rows[0]["pet"] if kind == "pet" else "")
            out.append("%-28s %s%s" % (n, lv, extra))
            if name:
                for r in rows:
                    out.append("    r%s L%d id %d %s%s%s%s: %s" % (r["rank"], r["level"], r["id"],
                               ("cost %s %s " % (r.get("cost"), r.get("power"))) if r.get("cost") else "",
                               ("cd %s" % r.get("cooldown")) if r.get("cooldown") else "",
                               (" shares cd with " + ", ".join(r["shares_cooldown"])) if r.get("shares_cooldown") else "",
                               (" only in " + "/".join(r["stances"])) if r.get("stances") else "", r.get("desc", "")))
    return "\n".join(out)


# ---------------------------------------------------------------------------

def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["update", "fetch", "build", "diff", "audit", "review", "tree", "spells", "packet", "recipes", "profs"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("--build")
    ap.add_argument("--report", help="update: also write a markdown report (game changes + audit) to this file")
    ap.add_argument("-k", dest="only")
    ap.add_argument("-v", action="store_true", dest="verbose")
    a = ap.parse_args()

    if a.cmd in ("fetch", "build", "update"):
        build = a.build or latest_build()
        print("Forever build %s" % build)
        fetch(build)
        if a.cmd == "fetch":
            return 0
        old = load_reference() if os.path.exists(REF) else None
        new = build_reference(build)
        write_reference(new)
        print("wrote %s" % os.path.relpath(REF, ROOT))
        changes = diff(old, new) if old else "first reference, nothing to compare"
        print(changes)
        if a.cmd == "update":
            res = full_audit(new)
            if a.report:
                write_report(a.report, old, new, changes, res)
            return report(res, a.verbose)
        return 0
    if a.cmd == "diff":
        old = load_reference(a.args[0])
        new = load_reference(a.args[1]) if len(a.args) > 1 else load_reference()
        print(diff(old, new))
        return 0
    ref = load_reference()
    if a.cmd == "audit":
        return report(full_audit(ref, a.only), a.verbose)
    if a.cmd == "profs":
        data = load_profdata() or {}
        want = (a.args[0] if a.args else "").upper()
        res = audit_professions(data, ref)
        for key, P in sorted(data.items()):
            if want and key != want and P["name"].upper() != want:
                continue
            print("#### %s vs WoW: Forever build %s" % (P["name"], ref["build"]))
            print("\n".join("  %-5s %s" % (l, m) for k, l, m in res if k == key) or "  (audit: nothing)")
            for s in P.get("steps") or []:
                label = s.get("name") or s.get("title")
                print("%3d-%3d  %s  (learn %s)" % (s["from"], s["to"], label, s.get("learn", "-")))
                if s.get("name"):
                    print("         GAME: " + (recipe_list(ref, P["name"], s["name"], exact=True) or "not found"))
            print()
        return 1 if any(l == "error" for _, l, _ in res) else 0
    if a.cmd == "recipes":
        names = {p.lower(): p for p in PROFESSIONS}
        prof = names.get((a.args[0] if a.args else "").lower())
        if not prof:
            sys.exit("name a profession: " + ", ".join(PROFESSIONS))
        print(recipe_list(ref, prof, a.args[1] if len(a.args) > 1 else None))
        return 0
    cls = (a.args[0] if a.args else a.only or "").upper()
    if cls not in CLASSES:
        sys.exit("name a class: " + ", ".join(CLASSES))
    if a.cmd == "review":
        print(review(load_data(), ref, cls))
    elif a.cmd == "packet":
        print(packet(load_data(), ref, cls))
    elif a.cmd == "tree":
        print(tree(ref, cls))
    elif a.cmd == "spells":
        print(spell_list(ref, cls, a.args[1] if len(a.args) > 1 else None))
    return 0


def write_report(path, old, new, changes, res):
    """Markdown for a pull request: what the game changed and what in the guides now needs a look."""
    counts = collections.Counter(l for _, l, _ in res)
    lines = ["# WoW: Forever %s -> %s" % ((old or {}).get("build", "?"), new["build"]), "",
             "Built by `python tools/gamedata.py update`. Follow tools/UPDATING.md: fix Data.lua (and the guide "
             "pages) for every change below, run the harness, then merge.", "",
             "## What the game changed", "", "```", changes[:30000], "```", "",
             "## Guide data against the new build: %d error(s), %d warning(s)" % (counts["error"], counts["warn"]), ""]
    for cls in groups(res):
        rows = [(l, m) for c, l, m in res if c == cls and l != "info"]
        if rows:
            lines.append("**%s**" % cls)
            lines += ["- %s %s" % ("ERROR" if l == "error" else "warn", m) for l, m in rows]
            lines.append("")
    lines += ["## Also check by hand", "",
              "- Blizzard's hotfix and development notes since the last update (server-side changes are not in the client tables).",
              "- `python tools/gamedata.py packet CLASS` for each class above, to re-read its talent reasons and macro tips.",
              "- `python tools/gamedata.py profs` for a profession above, to re-read its route next to the game.", ""]
    text = "\n".join(lines)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text[:60000])


def report(res, verbose):
    counts = collections.Counter(l for _, l, _ in res)
    for cls in groups(res):
        rows = [(l, m) for c, l, m in res if c == cls and (verbose or l != "info")]
        if rows:
            print("\n" + cls)
            for l, m in rows:
                print("  %-5s %s" % (l, m))
    print("\n%d error(s), %d warning(s), %d note(s)%s" % (counts["error"], counts["warn"], counts["info"],
                                                       "" if verbose else " (-v shows notes)"))
    return 1 if counts["error"] else 0


if __name__ == "__main__":
    sys.exit(main())
