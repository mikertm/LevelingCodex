# Tailoring Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Tailoring 1-300 guide in the Codex (Professions tab, crafting window, cards), with the
shopping list in raw cloth, bolts outlined first when you only have cloth, and a cloth section.

**Architecture:** Tailoring is data in `ProfessionData.lua` like Blacksmithing; the existing
profession code runs it once `"TAILORING"` is in `ns.PROF_ORDER`. Two generic additions: `parts`
(in-profession items such as bolts: the shopping list counts their materials, the crafting
window makes them first) and `cloth` (a section like Mining's veins, zones through
`ns.profZones`). The game-data tool learns skill line 197 and audits parts and cloth.

**Tech Stack:** Lua 5.1 (WoW: Forever client, Interface 16001), Python 3 harness with lupa
(`tests/run.py`, `tests/wowmock.lua`, `tests/scenarios.lua`), `tools/gamedata.py` (wago.tools
tables, cached build 1.60.1.70862).

**Spec:** `docs/superpowers/specs/2026-11-07-tailoring-guide-design.md` (route table, tiers,
parts, cloth table: copy values from there).

## Global Constraints

- Lua 5.1: no `goto`, `//`, integer division or `\u{}`. No new globals (the harness fails on leaks).
- All runtime text is ASCII and guide text goes through `ns.plain()`.
- Any non-core API may be missing (the minimal client removes `GetItemCount`): guard it; the tab
  must render without "you have" counts, and the crafting pick falls back to the step's recipe.
- Recipe `spell`, `yellow`, `grey`, `mats`, `icon`, `makes` must equal `tools/reference/forever.json`
  (copy them from `python tools/gamedata.py recipes Tailoring NAME`); `learn`, `source`, `note`,
  `alt`, tiers and zones are guide text from the spec.
- Tier banner text (`short`, else `where`) is 60 characters or fewer.
- No `.toc` change (no new files). Both `.toc` files stay identical.
- Run `python tests/run.py` before every commit; it must pass with no Lua errors.
- Never push a tag. Install for the owner with `python tools/install.py` at the end.
- Blacksmithing and Mining behaviour and texts stay unchanged except where a step says so.

## Review Focus

1. Minimal client (no `GetItemCount`): Tailoring tab renders, no "you have" text, no Lua error;
   crafting window not run there (`craftReady`). Pinned by `tailorTab` running in the minimal
   variant (Task 2).
2. The bolt recipe missing from the window list (filtered, closed heading, not learned) while you
   have the cloth: the guide stays on the step's recipe rather than pointing at an invisible bolt.
   Pinned by `craftTailoring` (Task 3).
3. Tailoring not learned, and Tailoring at 300: the tab opens without errors; at 300 "ROUTE DONE"
   and no "you need this now". Pinned by `tailorTabCases` (Task 2).
4. Far more bolts in bags than the route needs: the need stays as computed, "you have" grows, no
   negative counts. Pinned by `tailorTabCases` (Task 2).
5. Only Tailoring learned: the tab opens on Tailoring without a click (`current()` picks the first
   profession you have). Pinned by `tailorOnly` (Task 2).

---

### Task 1: Game reference, audit and the Tailoring data

**Files:**
- Modify: `tools/gamedata.py` (`PROFESSIONS`, the `recipes` help line, `audit_professions`)
- Modify: `tools/reference/forever.json` (regenerated)
- Modify: `tests/run.py` (`PROF_KEYS`, `prof_shape_checks`, `game_checks` reference rows)
- Modify: `ProfessionData.lua` (add `TAILORING`)
- Create: `tools/audits/2026-11-07-tailoring.md`
- Modify: `CLAUDE.md` (the `ProfessionData.lua` row and the Game checks line)

**Interfaces:**
- Produces: `LevelingCodexProfessions.TAILORING = { name = "Tailoring", skillLine = 197,
  icon = "trade_tailoring", tiers, steps, parts, cloth }`.
  - `parts[i] = { name, plural, spell, icon, yellow, grey, mats = { { cloth, n } }, makes = { bolt, 1 }, learn, source }`
    (`plural`: "Bolts of Silk Cloth").
  - `cloth[i] = { name, icon, levels = "27-39", zones = { All = {...}, Alliance = {...}, Horde = {...} } }`
    (lists only where the spec's table has zones; `levels` is the mob level text).
  - Bolt steps carry `makes = { "Bolt of ...", 1 }`.
- Produces (tool): `gamedata.PROFESSIONS["Tailoring"] == 197`; the reference has
  `professions.Tailoring`.

- [ ] **Step 1: Write the failing checks**

In `tests/run.py`:
- `PROF_KEYS = ("BLACKSMITHING", "MINING", "TAILORING")`.
- In `prof_shape_checks`, for any profession: each `parts` entry has `name`, `plural`, `spell`,
  `icon`, `yellow`, `grey`, `mats`, `makes`, `learn`, `source` (error "professions KEY part NAME:
  missing F"). Each `cloth` entry has `name`, `icon`, `levels`, `zones` and every zone list holds
  strings. When a profession has `cloth`, each part's first material must be a cloth name (error
  "...: part NAME: CLOTH is not in the cloth list").
- In `game_checks`, add to `want`:
  `("Tailoring", "Bolt of Silk Cloth", 110, 120, [["Silk Cloth", 4]])` and
  `("Tailoring", "Runecloth Belt", 225, 255, [["Bolt of Runecloth", 3], ["Rune Thread", 1]])`,
  and an error unless `profs["Tailoring"]["recipes"]["Linen Bag"]["auto"]` is true.

In `tools/gamedata.py`:
- `PROFESSIONS = {"Blacksmithing": 164, "Mining": 186, "Tailoring": 197}`; the `recipes` usage
  line says "Blacksmithing / Mining / Tailoring".
- `audit_professions`: `check_recipe("part", p, p["name"])` for each part. For each cloth: error
  "cloth NAME: no PROFESSION recipe uses it" when the name isn't in `items`, warn on an icon that
  differs (as veins do). For each crafting step, error when a material is made by a recipe of
  this profession (`makes` of any reference recipe) unless an earlier step's `makes` or a part
  makes it: "step A-B: ITEM is made by a PROFESSION recipe: add it to parts or a step's makes".
  (Blacksmithing passes: its only such material, Heavy Grinding Stone, is an earlier step's `makes`.)

- [ ] **Step 2: Run to see them fail**

Run: `python tests/run.py -k prof`
Expected: FAIL with "professions: no TAILORING" and "reference: Tailoring Bolt of Silk Cloth should be yellow 110 grey 120".

- [ ] **Step 3: Regenerate the reference**

Run: `git show HEAD:tools/reference/forever.json > "$TMP/old.json"; python tools/gamedata.py build --build 1.60.1.70862; python tools/gamedata.py diff "$TMP/old.json"`
(use the session scratchpad for `$TMP`).
Expected: the diff lists only Tailoring (new profession, its recipes); no class or Blacksmithing/Mining change.

- [ ] **Step 4: Write `TAILORING` in `ProfessionData.lua`**

Values from the spec. Tiers (exact):
- `{ name = "Apprentice", cap = 75, skill = 1, level = 1, where = "Any Tailoring trainer" }`
- `{ name = "Journeyman", cap = 150, skill = 50, level = 10, short = "An Expert, Master or Artisan Tailor (not Journeyman ones)", where = "An Expert, Master or Artisan Tailor, Lawrence Schneider (Stormwind) or the Zephras Isle tailors: Sellandus (Stormwind), Jormund Stonebrow (Ironforge), Me'lynn (Darnassus), Magar (Orgrimmar), Tepa (Thunder Bluff), Rhiannon Davis (Undercity), Mahani (The Barrens) or Grarnik Goodstitch (Booty Bay)" }`
- `{ name = "Expert", cap = 225, skill = 125, level = 20, short = "Georgio Bolero (Stormwind) or Josef Gregorian (Undercity)", where = "Alliance: Georgio Bolero or Lawrence Schneider (Stormwind), Charles Worth (Alterac Mountains), Timothy Worthington (Theramore). Horde: Josef Gregorian (Undercity), Daryl Stack (Tarren Mill, Hillsbrad Foothills)" }`
- `{ name = "Artisan", cap = 300, skill = 200, level = 35, short = "Timothy Worthington (Theramore) or Daryl Stack (Tarren Mill)", where = "Timothy Worthington, Theramore Isle (Dustwallow Marsh), for the Alliance, or Daryl Stack, Tarren Mill (Hillsbrad Foothills), for the Horde: the only Artisan trainers" }`

Steps: the spec's 23 rows in order, `from`/`to`/`name`/`learn`/`note`/`alt` from the table, recipe
fields from the tool. Sources (exact): "Known when you learn Tailoring" (1-37); "Tailoring trainer"
(37-235); "Pattern: Runecloth Gloves, sold by Qia (Everlook, Winterspring), 1g68, limited stock";
"Pattern: Runecloth Cuffs, sold by Pexmit (Mount Hyjal), 10g"; "Pattern: Venomspew Gloves, sold by
Mishta (Cenarion Hold, Silithus), 7g50"; "Pattern: Venomspew Cord, sold by Mishta (Cenarion Hold,
Silithus), 7g50". The five bolt steps (1-37, 75-77, 100-110, 140-147, 210-212) get
`makes = { "Bolt of ...", 1 }`.

Parts: the five bolts (spec *Parts*), `learn` 1/55/100/140/210, `source` as their route step,
`plural` "Bolts of Linen Cloth" / "Bolts of Woolen Cloth" / "Bolts of Silk Cloth" /
"Bolts of Mageweave" / "Bolts of Runecloth".

Cloth: the spec's table (Linen, Wool, Silk, Mageweave, Runecloth), icons from the reference
`items` (the bolt recipes' reagents).

- [ ] **Step 5: Audit Tailoring alone**

Run: `python tools/gamedata.py profs TAILORING`
Expected: no errors. Warnings only of these kinds: a recipe name the game has twice (Earthen Vest,
Black Mageweave Vest and any other route recipe in `clashes`). Fix anything else in the data.

- [ ] **Step 6: Run the whole harness**

Run: `python tests/run.py`
Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 7: Audit file and CLAUDE.md, then commit**

`tools/audits/2026-11-07-tailoring.md`: every Tailoring fact with its source (client table or
Wowhead page and date), the five differences from Wowhead's route, the clash warnings and why
they stand, the in-game checks from the spec. CLAUDE.md: the `ProfessionData.lua` row adds
`TAILORING`, `parts` (in-profession items: shopping list counts their materials) and `cloth`
(levels, zones); the Game checks line adds parts, cloth names and "a step material the
profession makes must come from parts or an earlier `makes`".

```bash
git add tools/gamedata.py tools/reference/forever.json tests/run.py ProfessionData.lua tools/audits/2026-11-07-tailoring.md CLAUDE.md
git commit -m "Tailoring: game reference, audit and the 1-300 route data"
```

---

### Task 2: Shopping list in cloth, the Tailoring tab and cards

**Files:**
- Modify: `Professions.lua` (`ns.PROF_ORDER`, `ns.profShopping`, new `ns.profPart`, `ns.profHave`, `ns.profClothFor`)
- Modify: `ProfessionTab.lua` (switch, subtitle, step card part lines, shopping rows, cloth section)
- Modify: `tests/scenarios.lua` (`S.skills` names, new scenarios, `profNone`/`profDebug` expectations)
- Modify: `tests/run.py` (new sequences and runs)
- Modify: `CHANGELOG.md` (v0.12.0), `README.md`, `CURSEFORGE_DESCRIPTION.md`, `CLAUDE.md` (modules 2b, 5b; tests)

**Interfaces:**
- Consumes: `TAILORING.parts`, `TAILORING.cloth` (Task 1).
- Produces:
  - `ns.PROF_ORDER = { "BLACKSMITHING", "MINING", "TAILORING" }`.
  - `ns.profPart(key, item) -> part|nil`: the part whose `makes[1]` is `item`.
  - `ns.profHave(key, item) -> number|nil`: `GetItemCount(item)` plus, for each part whose
    materials include `item`, `GetItemCount(part.makes[1]) * count / part.makes[2]`; nil when
    `GetItemCount` is missing.
  - `ns.profClothFor(key, step) -> name|nil`: a cloth named in the step's materials, else the
    first material of the first part the step uses.
  - `ns.profShopping(key, skill)` rows `{ item, n, via = { part = name, n = parts } }`: no row is
    a part; `via.n` counts every part of that kind still to make (bolt steps' crafts plus the
    leftover need).

- [ ] **Step 1: Write the failing scenarios**

In `tests/scenarios.lua`: `S.skills` names gain `TA = "Tailoring"`. New scenarios (each `if not D() then return end`):
- `S.tailorTab()` (skills `TA;150;225`): open Professions, click "Tailoring".
  - `profText()` has "Tailoring 150 / 225", "Earthen Vest", "SHOPPING LIST TO 300", "CLOTH".
  - No "%d+ Bolt of" in the shopping list part of the text (text after "SHOPPING LIST TO 300", before "CLOTH").
  - `(%d+) Runecloth %(for (%d+) bolts` matches with first == 5 * second.
  - "make them from Silk Cloth %(4 each%)" on the step card.
  - "Silk Cloth" appears before "Linen Cloth" in the cloth section, and "you need this now" right after "Silk Cloth".
  - "Humanoids level 27%-39".
  - With `GetItemCount` present: set `MOCK.bags["Mageweave Cloth"] = 20`, refresh; the Mageweave row reads "you have 20". Set `MOCK.bags["Bolt of Mageweave"] = 10`, refresh; it reads "you have 70". Without `GetItemCount`: no "you have" anywhere in the text.
  - Three buttons labelled Blacksmithing, Mining, Tailoring (`MOCK.buttons(win())`). After hide and reopen the tab still shows Tailoring.
  - `MOCK.staleUnder(win(), "Professions")`.
- `S.tailorTabCases()`:
  - Faction: default Alliance cloth rows include "Westfall" and not "Durotar". After `MOCK.faction = "Horde"` and a refresh, "Durotar" and not "Westfall". After `MOCK.race = "Skyborne"`, its faction's zones, no "Zephras Isle". Reset both.
  - `MOCK.bags["Bolt of Runecloth"] = 999`: no "-%d" count in the shopping list, and the Runecloth "for N bolts" N is unchanged.
  - `MOCK.setSkill("Tailoring", 260, 300)`: "Runecloth Cuffs", "Pexmit", and "Runecloth" is the first cloth row with "you need this now".
  - `MOCK.setSkill("Tailoring", 300, 300)`: "ROUTE DONE", no "you need this now".
- `S.tailorOnly()` (skills `TA;20;75`): opening Professions without a click shows "Tailoring 20 / 75" and "Bolt of Linen Cloth"; Linen Cloth first in the cloth section.
- `S.tailorNone()` (no skills): click "Tailoring": "Tailoring: not learned"; the cloth section lists "Linen Cloth" first.
- `S.tailorSkillUps()`: `MOCK.setSkill("Tailoring", 159, 225)`, advance 1.2; then `MOCK.setSkill("Tailoring", 160, 225)`, advance 1.2. Toast title "Tailoring 160", its text has "Crimson Silk Vest". Then `MOCK.level = 9`, `MOCK.setSkill("Tailoring", 60, 75)`, advance; level up to 10 (as `profLevelTier`). Banner has "TRAIN JOURNEYMAN TAILORING" and "An Expert, Master or Artisan Tailor".
- `S.tailorDebug()`: `/codex debug` chat has "profession: Tailoring 150/225, step 147%-160 Earthen Vest".
- `S.tailorClosed()`: with the heading closed from the start, chat has "profession: Tailoring not seen".
- `S.profNone` also checks "profession: Tailoring not learned".

In `tests/run.py`:
- `TAILOR = ["skills:TA;150;225:professions", "login", "tailorDebug", "tailorTab", "tailorTabCases"]`
- `TAILOR_ONLY = ["skills:TA;20;75:professions", "login", "tailorOnly"]`
- `TAILOR_LINES = ["skills:TA;150;225:skilllines", "login", "tailorDebug"]`
- `TAILOR_CLOSED = ["skills:TA;150;225:skilllines", "skillsClosed", "login", "tailorClosed"]`
- `PROF_NONE` gains `"tailorNone"`; `PROF_UPS` gains `"tailorSkillUps"`.
- Runs per variant: `WARRIOR/%s/tailor`, `MAGE/%s/tailor-only`, `PALADIN/%s/tailor-skilllines`, `PALADIN/%s/tailor-closed-heading`.

- [ ] **Step 2: Run to see them fail**

Run: `python tests/run.py -k tailor`
Expected: FAIL. "Tailoring 150 / 225" is not found because there's no Tailoring button, and the debug line is missing.

- [ ] **Step 3: Implement in `Professions.lua`**

`PROF_ORDER`, `ns.profPart`, `ns.profHave`, `ns.profClothFor` as in Interfaces. `profShopping`: unchanged
walk, then replace each part row by its materials. Crafts = `ceil(n / makes[2])`. Each material row
adds `count * crafts` and sets `via`. Bolt steps' crafts also add to their part's `via.n`, since a
step's `makes` item is a part. The sort is unchanged.

- [ ] **Step 4: Implement in `ProfessionTab.lua`**

- **Switch:** loops `PROF_ORDER` (three buttons, as now).
- **Subtitle:** the names from `PROF_ORDER` joined with ", " and " and ", plus " 1-300 for WoW: Forever".
- **Step card:** under a material that `ns.profPart` knows, add the line "make them from CLOTH (N each): your H make F", where `H = ns.profHave(key, CLOTH)` and `F = floor(H / N)`. Leave out ": your H make F" when H is nil.
- **Shopping row with `via`:** "N ITEM (for B bolts, you have H)", dropping ", you have H" when nil.
  - "bolts" is "parts" when the part's name doesn't start with "Bolt".
- **Cloth section** (after the shopping list, when `P.cloth`): title "CLOTH".
  - Rows: icon, name, "Humanoids level LEVELS", "Where: " plus `ns.profZones(c)`.
  - The `ns.profClothFor(key, step)` row comes first, followed by "  -  you need this now".
  - Close with the line "Thread, dyes and Bleach: Tailoring and trade supply vendors (most trainers have one nearby)."

- [ ] **Step 5: Run the Tailoring scenarios**

Run: `python tests/run.py -k tailor`
Expected: PASS.

- [ ] **Step 6: Run the whole harness**

Run: `python tests/run.py`
Expected: `PASSED: 0 run(s) failed` (Blacksmithing/Mining scenarios unchanged).

- [ ] **Step 7: Docs, then commit**

- **CHANGELOG v0.12.0:** a Tailoring bullet (the route summary from the spec, Forever's trainer changes, patterns from 235) and the cloth section.
- **README and CURSEFORGE_DESCRIPTION:** "Mining, Blacksmithing and Tailoring".
- **CLAUDE.md:** modules 2b (`profPart`, `profHave`, `profClothFor`, `via`) and 5b (cloth section); Profession scenarios (`TA`).

```bash
git add Professions.lua ProfessionTab.lua tests/scenarios.lua tests/run.py CHANGELOG.md README.md CURSEFORGE_DESCRIPTION.md CLAUDE.md
git commit -m "Tailoring: shopping list in cloth, the tab's cloth section, Tailoring in every profession list"
```

---

### Task 3: Crafting window: bolts first

**Files:**
- Modify: `ProfessionGuide.lua` (`pickFor`, the card line in `tick`, header comment)
- Modify: `Window.lua:1124` (Settings text)
- Modify: `tests/scenarios.lua`, `tests/run.py` (`CRAFT`, `CRAFT_RETAIL`)
- Modify: `CHANGELOG.md`, `CURSEFORGE_DESCRIPTION.md`, `CLAUDE.md` (module 7a)

**Interfaces:**
- Consumes: `ns.profPart(key, item)` (Task 2). Bag counts come straight from `GetItemCount`, not `ns.profHave`: here a held bolt counts as a bolt.
- Produces: `pickFor(key, skill)` may return a part pick
  `{ name, spell, icon, yellow, grey, learn, mats, partOf = step, plural, cloth, have, canMake }`,
  where `have` is `GetItemCount(cloth)` and `canMake` is `floor(have / cloth per part)`.
  - It returns one when all of these hold:
    - a step material is a part;
    - `GetItemCount(part)` is below that material's per-craft count;
    - `GetItemCount(cloth)` is at least the part's cloth per craft;
    - `findRecipe(part.name)` finds it in the window.
  - Otherwise it returns the step, as now. The trace, Show it and the controller auto-select already work from `pick.name`.

- [ ] **Step 1: Write the failing scenarios**

`S.craftTailoring()` (`if not craftReady() then return end`):
- **Setup:** save `MOCK.trade` like `craftSmelting`. Then `MOCK.setSkill("Tailoring", 150, 225)`, and set `line, rank, max = "Tailoring", 150, 225`.
  - Recipes: `{ "Bolt of Silk Cloth", "trivial", 11 }`, `{ "Crimson Silk Vest", "optimal", 0 }`, `{ "Earthen Vest", "medium", 0 }`.
  - Bags: `MOCK.bags = { ["Silk Cloth"] = 46 }`. Then layout and `openCraft()`.
- **Bolts first:** the hint text has "Make Bolts of Silk Cloth first: your 46 Silk Cloth make 11.", and the trace is on `TradeSkillSkill1`.
- **Back to the step:** `MOCK.bags["Bolt of Silk Cloth"] = 11`, advance 1. The hint names "Earthen Vest", has no "first", and the trace is on `TradeSkillSkill3`.
- **No bolts, no cloth:** `MOCK.bags = {}`, advance 1. The hint names "Earthen Vest" and has no "first".
- **Bolt recipe not in the list:** `MOCK.bags = { ["Silk Cloth"] = 46 }`, remove the bolt recipe, layout, advance 1. The hint names "Earthen Vest" and has no "first".
- **Teardown:** `closeCraft()`, then restore `MOCK.trade` and `MOCK.bags = {}`.

`S.craftTailoringPad()` (`if not craftReady() or not GamepadMode then return end`):
- **Setup:** the same setup with the cloth only, and 10 filler recipes before the bolt (like `craftPadAutoSelect`). Then `MOCK.gamepad = true`, `openCraft()`.
- **Auto-select:** `MOCK.trade.selected` is the bolt's index.
- **Teardown:** clean up as `craftPadAutoSelect` does.

`tests/run.py`: add `"craftTailoring", "craftTailoringPad"` to `CRAFT` (before `"debugReport"`) and `"craftTailoring"` to `CRAFT_RETAIL`.

- [ ] **Step 2: Run to see them fail**

Run: `python tests/run.py -k craft`
Expected: FAIL with "Make Bolts of Silk Cloth first" not found (the card shows Earthen Vest).

- [ ] **Step 3: Implement**

`pickFor` as in Interfaces. In `tick`, a part pick's card line is
"Make PLURAL first: your HAVE CLOTH make CANMAKE." in place of "About N more to X"; the rest of the
card (colour status, Show it, trace) is unchanged. Header comment: "(Blacksmithing, Smelting,
Tailoring)". `Window.lua:1124`: "When you open Blacksmithing, Smelting or Tailoring, ...".

- [ ] **Step 4: Run the crafting scenarios**

Run: `python tests/run.py -k craft`
Expected: PASS.

- [ ] **Step 5: Run the whole harness**

Run: `python tests/run.py`
Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 6: Docs, commit, install**

CHANGELOG (crafting window bullet: Tailoring, bolts first), CURSEFORGE_DESCRIPTION (crafting
window line), CLAUDE.md module 7a (the part-first pick and its conditions).

```bash
git add ProfessionGuide.lua Window.lua tests/scenarios.lua tests/run.py CHANGELOG.md CURSEFORGE_DESCRIPTION.md CLAUDE.md
git commit -m "Tailoring: the crafting window outlines bolts first when you only have the cloth"
python tools/install.py
```
Expected: install reports every file copied and verified. Tell the owner to `/reload` (no `.toc` change).
