# Profession Guides (Mining and Blacksmithing 1-300) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Mining and Blacksmithing 1-300 guides to the Codex: route data checked against Forever's game tables, a Professions tab, a crafting window trace and a skill-up card.

**Architecture:** `tools/gamedata.py` adds every Mining/Blacksmithing recipe to `tools/reference/forever.json`; a hand-written `ProfessionData.lua` holds the routes and the harness audits it against that reference. At runtime `Professions.lua` reads skills and does the lookups, `ProfessionTab.lua` draws a new window tab through helpers Window.lua exports, `ProfessionGuide.lua` traces the recipe in the crafting window, and Banner.lua's card gets a generic entry point for skill-up cards.

**Tech Stack:** Lua 5.1 (WoW: Forever, Interface 16001), Python 3 + lupa for the harness and tools.

**Spec:** `docs/superpowers/specs/2026-11-07-profession-guides-design.md` (read it first; route tables, data shape and rules live there).

## Global Constraints

- Lua 5.1 only: no `goto`, no `//`, no `\u{}`; every runtime string ASCII (guide text through `ns.plain()`).
- No new globals except `LevelingCodexProfessions` and frames named `LevelingCodex*` (the mock allows any `LevelingCodex*` name).
- Every event beyond PLAYER_LOGIN / PLAYER_LEVEL_UP is registered with `pcall`; every non-core API is existence-checked and `pcall`ed.
- Nothing may depend on SavedVariables: skill history is per session; settings default to on when `LevelingCodexDB` is empty.
- Icons through `ns.setIcon`; texture paths with doubled backslashes in Lua source.
- Both `.toc` files stay byte-identical; new files go in this order: `Data.lua, ProfessionData.lua, Theme.lua, Art.lua, Guide.lua, Professions.lua, Macros.lua, Banner.lua, Window.lua, ProfessionTab.lua, Minimap.lua, Tracking.lua, TalentGuide.lua, ProfessionGuide.lua, Init.lua`.
- Guide facts from the game: `yellow`, `grey`, `mats`, `spell`, `icon` in `ProfessionData.lua` must equal `forever.json`; learn levels, tiers and zones are the spec's values.
- Expected crafts per point: `1` below yellow, `(grey - s) / (grey - yellow)` from yellow, impossible at grey; shown rounded up as "about N".
- Work on a branch, `profession-guides`, created from `main` before Task 1 (`git switch -c profession-guides`); the spec, plan and `.pkgmeta` change go in Task 8's docs commit.
- Run `python tests/run.py` before every commit; it must print `PASSED`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push a tag.

## Review Focus

- A skill jump that crosses two boundaries at once (e.g. a trainer bonus, or the first reading after a long craft queue): one card listing both, not two cards or none. Test in Task 5.
- Professions the guide doesn't cover (Herbalism, Skinning): no card, no error, and the tab still opens on Blacksmithing/Mining. Test in Task 5.
- Skill 300 (and 300+ from bonuses): the tab says the route is done and shows no step, no division by zero in counts. Test in Task 4.
- Crafting rows whose text carries a count or colour code (`Copper Chain Belt [12]`, `|cff...|r`): still matched. Test in Task 6.
- A theme switch rebuilds the window: the added Professions tab must still be there. Test in Task 4.

---

### Task 1: Profession recipes in the game reference

**Files:**
- Modify: `tools/gamedata.py` (TABLES, `build_reference`, `diff`, `main`, new `recipe_list`)
- Modify: `tests/run.py` (`game_checks`)
- Regenerate: `tools/reference/forever.json`

**Interfaces:**
- Produces: `ref["professions"][PROF]` for `PROF` in `"Blacksmithing"`, `"Mining"`: `{ "skillLine": int, "recipes": { name: {"spell": int, "yellow": int, "green": int, "grey": int, "mats": [[item, n], ...], "makes": [item, n] | None, "icon": str | None, "category": str, "plan": {"item": str, "skill": int} (only when a plan teaches it)} }, "items": { itemName: icon } }` (items = every mat and product of that profession's recipes).
- Produces: `gamedata.PROFESSIONS = {"Blacksmithing": 164, "Mining": 186}`, `gamedata.recipe_list(ref, prof, name=None) -> str`.

- [ ] **Step 1: Write the failing reference check** in `tests/run.py` `game_checks()` (after loading `ref`):

```python
    profs = ref.get("professions") or {}
    want = [("Blacksmithing", "Rough Sharpening Stone", 15, 55, [["Rough Stone", 1]]),
            ("Blacksmithing", "Runed Copper Belt", 85, 125, [["Copper Bar", 10]]),
            ("Mining", "Smelt Gold", 170, 185, [["Gold Ore", 1]]),
            ("Mining", "Smelt Bronze", 65, 115, [["Copper Bar", 1], ["Tin Bar", 1]])]
    for prof, name, y, g, mats in want:
        r = (profs.get(prof) or {}).get("recipes", {}).get(name)
        if not r or (r["yellow"], r["grey"], r["mats"]) != (y, g, mats):
            errors.append("%s reference: %s %s should be yellow %d grey %d %s, is %s" % (tag, prof, name, y, g, mats, r))
```

- [ ] **Step 2: Run** `python tests/run.py -k nothing` (data checks only). Expected: `FAIL game ... reference: Blacksmithing Rough Sharpening Stone ...` and `FAILED`.

- [ ] **Step 3: Implement in `tools/gamedata.py`**
  - Add `"SpellReagents", "ItemSparse", "Item", "ItemEffect", "ItemXItemEffect", "TradeSkillCategory"` to `TABLES`.
  - `build_reference`: for each `PROFESSIONS` line, every `SkillLineAbility` row with `TrivialSkillLineRankHigh > 0`; `yellow = TrivialSkillLineRankLow`, `grey = TrivialSkillLineRankHigh`, `green = (yellow + grey) // 2`; mats from `SpellReagents` (item names via `ItemSparse.Display_lang`); `makes` from the `SpellEffect` row with `Effect == "24"` (`EffectItemType`, `EffectBasePointsF`); `icon` = the made item's `Item.IconFileDataID` through `Spells.icons`, else `Spells.icon(spell)`; `category` = `TradeSkillCategory.Name_lang`; `plan` = item(s) whose `ItemXItemEffect` -> `ItemEffect.SpellID` has a `SpellEffect` with `Effect == "36"` and `EffectTriggerSpell == spell`, with `ItemSparse.RequiredSkillRank`. Name clash: keep the lowest spell ID. `items`: icon per mat/product name.
  - `diff`: add per profession `recipe new/removed` and `recipe X: yellow/grey/mats a -> b`.
  - `recipe_list(ref, prof, name=None)`: one line per recipe sorted by yellow: `y15 g35 gr55  Rough Sharpening Stone  [1 Rough Stone]  icon inv_stone_sharpening_01  plan: ...`; with `name`, only recipes containing it.
  - `main`: new command `recipes PROF [NAME]` (PROF case-insensitive).

- [ ] **Step 4: Rebuild and run.** `python tools/gamedata.py build --build 1.60.1.70862` (prints `no class changes` for classes), then `python tests/run.py -k nothing`. Expected: no `reference:` failure; `PASSED`.

- [ ] **Step 5: Spot-check** `python tools/gamedata.py recipes mining` lists Smelt Copper `y25 g47 gr70` through Smelt Heavy Thorium `y300 ... gr315`.

- [ ] **Step 6: Commit** `tools/gamedata.py tests/run.py tools/reference/forever.json` — "Game data: Mining and Blacksmithing recipes in the Forever reference".

### Task 2: Route data and its audit

**Files:**
- Create: `ProfessionData.lua`
- Modify: `tools/gamedata.py` (`load_lua_global`, `load_profdata`, `audit_professions`, `profs` command, `report` prints profession rows)
- Modify: `tests/run.py` (`data_checks` calls `prof_shape_checks()`; `game_checks` adds `audit_professions` results)
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (add `ProfessionData.lua` after `Data.lua`)

**Interfaces:**
- Consumes: Task 1's `ref["professions"]`.
- Produces: global `LevelingCodexProfessions` with keys `BLACKSMITHING`, `MINING` in exactly the spec's shape (*Data: ProfessionData.lua*): profession `{ name, skillLine, icon, tiers[], steps[], notes }`; BS step `{ from, to, name, spell, icon, yellow, grey, mats = {{item, n}}, learn, source, note, alt }`; Mining adds `veins[] = { name, skill, ore, icon, zones = { Alliance = {...}, Horde = {...}, Skyborne = {...} } }`, `smelt[] = { name, spell, learn, yellow, grey, mats, makes, icon }`, `camp[] = { name, skill, source, text }`, and Mining steps `{ from, to, title, veins = {names}, smelt = {names}, note }`. Tier `{ name, cap, skill, level, where }`.
- Produces: `gamedata.audit_professions(profdata, ref) -> [(prof, "error"|"warn", msg)]`.

- [ ] **Step 1: Write the failing checks.**
  - `tests/run.py` `prof_shape_checks()` -> `(errors, warnings)`: errors when `ProfessionData.lua` is missing or `LevelingCodexProfessions` lacks `BLACKSMITHING`/`MINING`; a step without `from`, `to`, and (`name` for BS, `title` for Mining); non-ASCII in any string; a Mining step naming a vein or smelt not in its lists; a tier without `name, cap, skill, level, where`.
  - `gamedata.audit_professions` errors (spec, *Game reference and checks*): recipe not in `ref["professions"][prof]["recipes"]`; `yellow`/`grey`/`mats`/`spell` differ; `expected crafts` impossible (grey reached before `to`); steps not contiguous from 1 to 300 (`steps[1].from == 1`, `steps[i].to == steps[i+1].from`, last `to == 300`); a step with `to > tier.cap` where the next tier's `skill > tier.cap`; the same for Mining smelts (`yellow`, `grey`, `mats`). Warnings: green for more than half the step; `icon` differs from the recipe's (or, for a vein, from `items[ore]`); `learn > from`.
  - Call both from the harness; with no data file yet, `python tests/run.py -k nothing` must FAIL with `ProfessionData.lua missing`.

- [ ] **Step 2: Run** `python tests/run.py -k nothing`. Expected: FAIL `... ProfessionData.lua missing`.

- [ ] **Step 3: Write `ProfessionData.lua`** from the spec's route tables: 20 Blacksmithing steps (1-25 ... 290-300; the 185-210 row is two steps, 185-200 and 200-210, both Heavy Mithril Gauntlet), the four tiers per profession with the spec's trainers (Mining `where`: Apprentice "Any Mining trainer", Journeyman and Expert "Mining trainers in the capitals", Artisan "Mining trainers in the capitals, or Pikkle in Tanaris"), Mining's 7 steps, veins (Copper 1, Tin 65, Silver 75, Iron 125, Gold 155, Mithril 175, Truesilver 230, Dark Iron 230, Small Thorium 245, Rich Thorium 275), the 7 smelts that give points plus Mithril/Truesilver/Dark Iron/Thorium/Azerothium (marked no points), camp objects. Copy `spell`, `yellow`, `grey`, `mats`, `icon` from `python tools/gamedata.py recipes blacksmithing` / `recipes mining`. Notes and alternatives from the spec; Imperial Plate steps' `source` names Derotain Mudsipper (Tanaris) and the Thorium Bars each quest takes (20/20/40/60). Header comment: hand-written, checked against `tools/reference/forever.json`.

- [ ] **Step 4: Add `profs [PROF]`** to `gamedata.py`: the audit rows, then each step with the game's recipe line (`recipe_list` format) under it.

- [ ] **Step 5: Run** `python tests/run.py -k nothing` then `python tools/gamedata.py profs`. Expected: `PASSED`, no profession errors; warnings only for `learn > from` if any (there should be none) and green-heavy steps (Iron Buckle 125-130 is expected).

- [ ] **Step 6: Commit** `ProfessionData.lua tools/gamedata.py tests/run.py *.toc` — "Professions: Mining and Blacksmithing 1-300 routes, audited against the game".

### Task 3: Skills and lookups (`Professions.lua`)

**Files:**
- Create: `Professions.lua` (toc: after `Guide.lua`)
- Modify: `tests/wowmock.lua` (skills, faction, race, bags, new optional events, minimal list)
- Modify: `tests/scenarios.lua` (`S.skills`, `S.profDebug`)
- Modify: `tests/run.py` (new sequences)
- Modify: `Init.lua` (`start()` calls `ns.startProfessions()`; `ns.debugLines()` appends `ns.profDebugLines()`)

**Interfaces:**
- Consumes: `LevelingCodexProfessions`.
- Produces (all nil-safe, no errors without data or APIs):
  - `ns.P` = `LevelingCodexProfessions` (set at load), `ns.PROF_ORDER = { "BLACKSMITHING", "MINING" }`.
  - `ns.profSkill(key) -> skill:number|nil, cap:number|nil`.
  - `ns.profStep(key, skill) -> step|nil, index|nil` (step with `from <= skill < to`; nil at 300+).
  - `ns.profNext(key, skill) -> step|nil`.
  - `ns.expectedCrafts(step, fromSkill) -> number` (from `max(fromSkill, step.from)` to `step.to`; 0 when done; `math.huge` if grey before `to`).
  - `ns.profShopping(key, skill) -> { {item, n}, ... }` (sorted by n desc; each remaining step's crafts rounded up times mats; the current step from `skill`).
  - `ns.profTier(key, skill, cap) -> tier`: the trained tier, i.e. the tier whose `cap` equals `cap` when `cap` is known, else the lowest tier with `tier.cap >= skill`.
  - `ns.profTierDue(key, skill, cap, level) -> "train"|"cap"|nil, nextTier`: with `next` = the tier after `ns.profTier`: `"train"` when `next` exists, `skill >= next.skill` and `level >= next.level`; otherwise `"cap"` when `next` exists and `skill >= trained.cap`; otherwise nil. (87/150 at level 30 -> nil; 150/150 at level 30 -> "train" Expert; 150/150 at level 15 -> "cap".)
  - `ns.veinsFor(skill) -> { {vein, color} }` with color `"orange"` below `skill+25`... (gathering rule: orange `< vein.skill + 25`, yellow `< + 50`, green `< + 100`, else `"grey"`; `"red"` when `skill < vein.skill`).
  - `ns.profFaction() -> "Alliance"|"Horde"|nil`, `ns.profZones(vein) -> {zone names}` (faction list, plus `Skyborne` list when `UnitRace` says Skyborne).
  - `ns.startProfessions()`, `ns.profDebugLines() -> {strings}` (one line per profession: `"profession: Blacksmithing 87/150, step 85-100 Rough Bronze Leggings, about 13 more"` or `"profession: Mining not learned"`, plus `"profession skills read from: professions|skill lines|nothing"`).
- Mock (`tests/wowmock.lua`): `MOCK.skills = {}` list of `{ name, rank, max }`; `MOCK.skillAPI = "professions"` (`GetProfessions`/`GetProfessionInfo` exist) or `"skilllines"` (only `GetNumSkillLines`/`GetSkillLineInfo`); `MOCK.setSkill(name, rank, max)` updates and fires `SKILL_LINES_CHANGED` then `CHAT_MSG_SKILL` with `"Your skill in <name> has increased to <rank>."`; `UnitFactionGroup` -> `MOCK.faction or "Alliance"`; `UnitRace` -> `MOCK.race or "Human"`, race file string; `GetItemCount(name)` -> `MOCK.bags[name] or 0`. Known events add `SKILL_LINES_CHANGED, CHAT_MSG_SKILL, TRADE_SKILL_SHOW, TRADE_SKILL_UPDATE, TRADE_SKILL_CLOSE, TRAINER_SHOW, TRAINER_CLOSED` (all optional). `OPTIONAL` adds `GetProfessions, GetProfessionInfo, GetItemCount` (minimal keeps the classic skill-line calls).

- [ ] **Step 1: Write the failing scenarios** in `tests/scenarios.lua`:

```lua
-- skills:BS;87;150,MI;140;225:professions[:Horde[:Skyborne]]  (the step parser splits on ":")
function S.skills(list, api, faction, race)
  MOCK.skillAPI = api or "professions"
  if MOCK.skillAPI ~= "professions" then GetProfessions, GetProfessionInfo = nil, nil end
  MOCK.faction, MOCK.race = faction, race
  local names = { BS = "Blacksmithing", MI = "Mining", HE = "Herbalism" }
  for part in (list or ""):gmatch("[^,]+") do
    local k, r, m = part:match("(%a+);(%d+);(%d+)")
    MOCK.setSkill(names[k], tonumber(r), tonumber(m))
  end
end

function S.profDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing 87/150, step 85%-100 Rough Bronze Leggings, about 13 more"), "BS step in debug")
  check(chatHas("profession: Mining 140/225, step 125%-175"), "Mining step in debug")
  local via = (GetProfessions and "professions") or "skill lines"
  check(chatHas("profession skills read from: " .. via), "skills read from " .. via)
end

function S.profNone()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing not learned") and chatHas("profession: Mining not learned"), "no professions")
end
```

  `tests/run.py`: `PROF = ["skills:BS;87;150,MI;140;225:professions", "login", "profDebug"]`, `PROF_LINES = ["skills:BS;87;150,MI;140;225:skilllines", "login", "profDebug"]`, `PROF_NONE = ["login", "profNone"]`; runs `WARRIOR/<variant>/prof`, `PALADIN/<variant>/prof-skilllines`, `MAGE/<variant>/prof-none` for full and minimal (minimal has no `GetProfessions`, so `profDebug` expects "skill lines" there).

- [ ] **Step 2: Run** `python tests/run.py -k prof`. Expected: FAIL (`MOCK.setSkill` nil / no profession lines).

- [ ] **Step 3: Implement** the mock additions, then `Professions.lua` (functions above; skill read order `GetProfessions` -> `GetProfessionInfo(i)` name match, else `GetNumSkillLines` -> `GetSkillLineInfo(i)` with `isHeader` false and name match; `ns.startProfessions()` records the first reading per key in a local `last` table and registers the optional events with `pcall` on its own frame, handling them in Task 5), toc entries, Init hooks.

- [ ] **Step 4: Run** `python tests/run.py`. Expected: all runs `ok`, `PASSED` (the existing 6-tab scenarios still pass).

- [ ] **Step 5: Commit** — "Professions: skill reading and route lookups".

### Task 4: The Professions tab

**Files:**
- Modify: `Window.lua` (export `ns.ui`, add `ns.addTab`)
- Create: `ProfessionTab.lua` (toc: after `Window.lua`)
- Modify: `tests/scenarios.lua` (`TABS` gets `"Professions"` before `"Settings"`; new `S.profTab*`)
- Modify: `tests/run.py` (sequences)

**Interfaces:**
- Consumes: Task 3 lookups.
- Produces: `ns.ui = { W, T, rect, box, plate, icon, btn, check, hit, sectionTitle, goldRuleAt, refresh }` where `hit(x, y, w, h, tipTitle, tipText, onClick)` is the existing invisible row button; `ns.addTab(key, label, renderer)` inserts `{ key, label }` before `"settings"` in `TABS` and sets `renderers[key] = renderer` (renderer gets `(viewLevel)` and returns the content height); `ns.openTab("professions")` works; `ns.profTabShow(key)` selects the profession shown.
- Renderer content (exact labels the tests read): switch buttons `"Blacksmithing"` / `"Mining"`; header `"<Name> <skill> / <cap>"` or `"<Name>: not learned"` with the line `"Learn <Name> from any <Name> trainer (no level needed)."`; Now card label `"DO THIS NOW"`, recipe name, `"about N more to <to>"`, `"Learn at <learn>"` + source, `"Instead: <alt>"`, materials as `"<need> <item> (you have <have>)"`; training card `"TRAIN <TIER>"` + `where`, or `"AT YOUR CAP"` + `"Train <Tier> at <skill> (level <level>) to go past <cap>."`; `"NEXT"` strip; `"THE WHOLE ROUTE"` rows `"<from>-<to>  <name>"` (click selects the step for the Now card); `"SHOPPING LIST TO 300"`; at 300+: `"ROUTE DONE"`; Mining: veins rows `"<vein>  <skill>  <color>"` and `"Where: <zones>"`, smelt line `"Smelt for points: ..."`.

- [ ] **Step 1: Write the failing scenarios:**

```lua
local function profText() return MOCK.textUnder(win()) end

function S.profTab()
  if not D() then return end
  openAt(30, "Professions")
  click(win(), "Blacksmithing")
  local t = profText()
  check(t:find("Blacksmithing 87 / 150"), "skill header")
  check(t:find("Rough Bronze Leggings") and t:find("about 13 more to 100"), "now card")
  check(t:find("Learn at 80"), "learn level")
  check(t:find("SHOPPING LIST TO 300"), "shopping list")
  check(t:find("TRAIN EXPERT") == nil, "Expert not due at 87")
  click(win(), "Mining")
  t = profText()
  check(t:find("Mining 140 / 225") and t:find("Iron Deposit") and t:find("Arathi Highlands"), "mining header, vein, zones")
  MOCK.staleUnder(win(), "Professions")
  win():Hide()
end

-- S.profTabAt("BS;150;150", 30) etc.: tier card, cap card, done, not learned, Skyborne zones
function S.profTabCases()
  if not D() then return end
  MOCK.setSkill("Blacksmithing", 150, 150)
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("TRAIN EXPERT") and profText():find("Bengus Deepforge"), "Expert due at 150, level 30")
  MOCK.setSkill("Blacksmithing", 300, 300)
  click(win(), "Blacksmithing")
  check(profText():find("ROUTE DONE"), "route done at 300")
  MOCK.skills = {}
  click(win(), "Blacksmithing")
  check(profText():find("Blacksmithing: not learned"), "not learned")
  MOCK.setSkill("Mining", 30, 75)
  MOCK.faction, MOCK.race = "Alliance", "Human"
  click(win(), "Mining")
  check(profText():find("Elwynn Forest") and not profText():find("Durotar"), "Alliance copper zones only")
  MOCK.faction, MOCK.race = "Horde", "Orc"
  click(win(), "Mining")
  check(profText():find("Durotar") and not profText():find("Elwynn Forest"), "Horde copper zones only")
  MOCK.race = "Skyborne"
  click(win(), "Mining")
  check(profText():find("Zephras Isle"), "Skyborne starting isle for Copper")
  win():Hide()
end

function S.profTabAfterTheme()
  if not D() then return end
  openAt(30, "Settings"); click(win(), "Codex (gold)")
  click(win(), "Professions")
  check(profText():find("Blacksmithing") or profText():find("Mining"), "Professions tab survives a theme rebuild")
  click(win(), "Settings"); click(win(), "Forever (teal)")
  win():Hide()
end
```

  Add `"Professions"` to scenarios' `TABS` (so `browse` and `everyButton` cover it). `tests/run.py`: `PROF` sequence gets `"profTab", "profTabCases", "profTabAfterTheme"`; also add `"profTab"` to `NOART`.

- [ ] **Step 2: Run** `python tests/run.py -k prof`. Expected: FAIL `no button 'Professions'`.

- [ ] **Step 3: Implement** `ns.ui` / `ns.addTab` in Window.lua (TABS and renderers stay module-level so `makeFrame` after a theme rebuild picks the tab up), then `ProfessionTab.lua` (selected profession: the first in `ns.PROF_ORDER` you have, else Blacksmithing; selected step resets when the profession or skill changes; all guide strings through `plain()`; icons via `ns.ui.icon`). Window width: the 7 tabs must fit below the 640 px frame—check `A.tab` widths and shorten the label to `"Professions"` only.

- [ ] **Step 4: Run** `python tests/run.py`. Expected: `PASSED` (browse/everyButton now include the Professions tab for every class, full and minimal, no stale fonts).

- [ ] **Step 5: Commit** — "Professions tab: your step, training, the route and a shopping list".

### Task 5: Skill-up card

**Files:**
- Modify: `Banner.lua` (generic `ns.showCard`, click target)
- Modify: `Professions.lua` (skill-change handling)
- Modify: `Window.lua` (Settings: `"PROFESSIONS"` head, tick `"Profession skill-up cards"` -> `db.noProfCards`)
- Modify: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces: `ns.showCard(title:string, sub:string, rows:{{icon, label, text}}, onClick:function|nil)` — shows the existing toast immediately with these rows (max 5), same fade/hover/drag/scale/position; left-click runs `onClick` (default `ns.toggleWindow`), right-click dismisses; does nothing while the banner is unlocked for moving. `ns.showToast` builds its rows and calls the same fill code.
- Consumes: Task 4's `ns.profTabShow(key)` (the card's click calls it, then `ns.openTab("professions")`).
- Produces: `ns.profCardRows(key, old, new, cap, level) -> rows` (pure): `{ step.icon, "NEXT STEP", "<name>  -  about N to <to>" }` for each step with `old < from <= new` (Mining: `{ vein icon, "NEXT STEP", title }`); `{ prof.icon, "TRAIN <TIER>", where }` when the next tier's `skill` is crossed and level allows; `{ prof.icon, "AT YOUR CAP", "Train <Tier> to go past <cap>" }` when `new >= cap` and `old < cap`; Mining `{ vein.icon, "NEW VEIN", "<vein> (<skill>)" }` for each vein with `old < skill <= new`. Card title `"<Name> <new>"`, sub `"Leveling Codex"`; click opens `ns.openTab("professions")` on that profession. Chat (unless `db.quiet`): `"<Name> <new>: <text of first row>"`.

- [ ] **Step 1: Write the failing scenario:**

```lua
function S.profSkillUps()
  if not D() then return end
  local t
  MOCK.setSkill("Blacksmithing", 84, 150)       -- first reading this session: no card
  MOCK.advance(0.5)
  check(not (toast() and toast():IsShown()), "no card for the first reading")
  MOCK.setSkill("Blacksmithing", 85, 150)       -- step boundary 85
  MOCK.advance(0.5); t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Blacksmithing 85", "card at a new step")
  check(MOCK.textUnder(t):find("Rough Bronze Leggings"), "card names the next recipe")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5)
  MOCK.setSkill("Blacksmithing", 86, 150)       -- ordinary point
  MOCK.advance(0.5)
  check(not t:IsShown(), "no card for an ordinary point")
  MOCK.setSkill("Blacksmithing", 112, 150)      -- jumps over 100 and 112: one card, both steps
  MOCK.advance(0.5)
  local text = MOCK.textUnder(t)
  check(t:IsShown() and text:find("Heavy Grinding Stone") and text:find("Rough Bronze Leggings"), "one card for two boundaries")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5)
  MOCK.level = 30
  MOCK.setSkill("Blacksmithing", 125, 150)      -- Expert trainable
  MOCK.advance(0.5)
  check(MOCK.textUnder(t):find("TRAIN EXPERT"), "Expert card at 125")
  MOCK.fire(t, "OnMouseUp", "LeftButton"); MOCK.advance(1.5)
  check(win() and win():IsShown() and MOCK.textUnder(win()):find("Blacksmithing 125"), "click opens the Professions tab")
  win():Hide()
  MOCK.setSkill("Mining", 64, 75); MOCK.setSkill("Mining", 65, 75)
  MOCK.advance(0.5)
  check(MOCK.textUnder(t):find("Tin Vein"), "new vein card")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5)
  MOCK.setSkill("Herbalism", 1, 75); MOCK.setSkill("Herbalism", 50, 75)
  MOCK.advance(0.5)
  check(not t:IsShown(), "no card for a profession the guide doesn't cover")
  LevelingCodexDB.noProfCards = true
  MOCK.setSkill("Blacksmithing", 140, 150); MOCK.advance(0.5)
  check(not t:IsShown(), "cards off in Settings")
  LevelingCodexDB.noProfCards = nil
end
```

  Every `MOCK.advance(0.5)` above is `MOCK.advance(1.2)` in the file: the minimal client has no `CHAT_MSG_SKILL`/`SKILL_LINES_CHANGED`, so cards there come from the 1 s skill poll. `tests/run.py`: `PROF_UPS = ["login", "profSkillUps"]` for WARRIOR and HUNTER, full and minimal. Add `"noProfCards"` to `everyButton`'s reset list.

- [ ] **Step 2: Run** `python tests/run.py -k prof`. Expected: FAIL `card at a new step`.

- [ ] **Step 3: Implement** `ns.showCard` (refactor `showToast`'s row filling into a local `fill(title, sub, rows, hint)`; keep `showToast`'s waiting logic and its title/sub), `toast.onClick` used by the OnMouseUp handler, `ns.profCardRows`, the event handler in `Professions.lua` (on `SKILL_LINES_CHANGED`, `CHAT_MSG_SKILL`, `TRADE_SKILL_UPDATE`, and a 1 s `ns.every` poll only when no event registered; compare with `last[key]`, update it, build rows, show), and the Settings tick.

- [ ] **Step 4: Run** `python tests/run.py`. Expected: `PASSED`.

- [ ] **Step 5: Commit** — "Professions: skill-up card at new steps, training and new veins".

### Task 6: Crafting window trace (`ProfessionGuide.lua`)

**Files:**
- Create: `ProfessionGuide.lua` (toc: after `TalentGuide.lua`)
- Modify: `tests/wowmock.lua` (trade skill API: classic and retail styles)
- Modify: `tests/scenarios.lua` (`S.makeCraftWindow`, `S.craft*`)
- Modify: `tests/run.py`, `Init.lua` (start), `Window.lua` (Settings tick `"Trace my recipe in the crafting window"` -> `db.noCraftGuide`)

**Interfaces:**
- Consumes: `ns.profStep`, `ns.expectedCrafts`, `ns.profNext`, `ns.P`.
- Produces: frames `LevelingCodexCraftTrace` (outline around the row, theme accent, no mouse; its first anchor is `TOPLEFT` on the row button) and `LevelingCodexCraftHint` (card beside the window: label `"LEVELING CODEX  -  <NAME> <skill>"`, name `"<recipe>"`, line `"About N more to <to>  -  you have materials for M"`, live colour word `orange|yellow|green|grey`; not learned: `"Not learned yet: learn it at a <Name> trainer (<learn>)."`; grey: `"Grey now: next is <next name>."`; a `"Show it"` button when the row isn't visible); `ns.startCraftGuide()`; `ns.craftDebugLines()` (`"crafting window: <name|not open>"`, `"crafting pick: <recipe> by row|not shown|not learned"`).
- Mock: `MOCK.trade = { line = "Blacksmithing", rank = 87, max = 150, recipes = { {name, type, numAvailable} }, selected = 0, style = "classic"|"retail" }`; classic: `GetTradeSkillLine()`, `GetNumTradeSkills()`, `GetTradeSkillInfo(i)` -> `name, type, numAvailable, isExpanded`, `SelectTradeSkill(i)` (records `MOCK.trade.selected` and calls `MOCK.trade.layout()` if set), `GetTradeSkillSelectionIndex()`; retail: `C_TradeSkillUI.GetBaseProfessionInfo()` -> `{ professionName, skillLevel, maxSkillLevel }`, `C_TradeSkillUI.GetAllRecipeIDs()`, `C_TradeSkillUI.GetRecipeInfo(id)` -> `{ name, learned, numAvailable, relativeDifficulty }` (0 optimal, 1 medium, 2 easy, 3 trivial), `C_TradeSkillUI.SetRecipeItemNameFilter`/none. Minimal removes both styles.

- [ ] **Step 1: Write the failing scenarios:**

```lua
-- A crafting window: TradeSkillFrame with 8 visible rows TradeSkillSkill1..8 showing recipes
-- from `offset`. Row text may carry a count, like the game: "Copper Chain Belt [3]".
function S.makeCraftWindow(style)
  local f = CreateFrame("Frame", "TradeSkillFrame", UIParent); f:SetSize(384, 512); f:Hide()
  MOCK.trade = { line = "Blacksmithing", rank = 87, max = 150, style = style or "classic", offset = 0, selected = 0, rows = {},
    recipes = { { "Rough Sharpening Stone", "trivial", 5 }, { "Copper Chain Belt", "trivial", 3 }, { "Runed Copper Belt", "easy", 1 },
                { "Rough Bronze Leggings", "optimal", 4 } } }
  for i = 1, 8 do
    local b = CreateFrame("Button", "TradeSkillSkill" .. i, f); b:SetSize(300, 16)
    MOCK.trade.rows[i] = b
  end
  MOCK.trade.layout = function()
    for i, b in ipairs(MOCK.trade.rows) do
      local r = MOCK.trade.recipes[i + MOCK.trade.offset]
      -- orange recipes carry a colour code, like some clients draw them
      local name = r and (r[2] == "optimal" and ("|cffff8040" .. r[1] .. "|r") or r[1])
      if r then b:SetText(name .. (r[3] > 0 and (" [" .. r[3] .. "]") or "")); b:Show() else b:Hide() end
    end
  end
  if style == "retail" then GetTradeSkillLine, GetNumTradeSkills, GetTradeSkillInfo = nil, nil, nil end
  MOCK.trade.layout()
  return f
end

local function openCraft() TradeSkillFrame:Show(); MOCK.event("TRADE_SKILL_SHOW"); MOCK.advance(0.6) end
local function closeCraft() TradeSkillFrame:Hide(); MOCK.event("TRADE_SKILL_CLOSE"); MOCK.advance(0.6) end

function S.craftTrace()
  if not D() or MOCK.minimal then return end
  MOCK.setSkill("Blacksmithing", 87, 150)
  openCraft()
  local tr, h = _G.LevelingCodexCraftTrace, _G.LevelingCodexCraftHint
  check(h and h:IsShown(), "card beside the crafting window")
  local text = MOCK.textUnder(h)
  check(text:find("Rough Bronze Leggings") and text:find("About 13 more to 100") and text:find("materials for 4"), "card text")
  check(tr and tr:IsShown(), "row traced")
  local p = { tr:GetPoint(1) }
  check(p[2] == TradeSkillSkill4, "trace on the Rough Bronze Leggings row (row text has a count)")
  closeCraft()
  check(not tr:IsShown() and not h:IsShown(), "trace and card hide with the window")
end

function S.craftNotLearned()
  if not D() or MOCK.minimal then return end
  table.remove(MOCK.trade.recipes, 4); MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Not learned yet") and not LevelingCodexCraftTrace:IsShown(), "not learned")
  closeCraft()
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 4 })
end

function S.craftGrey()
  if not D() or MOCK.minimal then return end
  MOCK.trade.recipes[4][2] = "trivial"; MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Grey now: next is Heavy Grinding Stone"), "grey: move on")
  closeCraft()
  MOCK.trade.recipes[4][2] = "optimal"
end

function S.craftScrolled()
  if not D() or MOCK.minimal then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.trade.layout()
  openCraft()
  local h = LevelingCodexCraftHint
  check(h:IsShown() and not LevelingCodexCraftTrace:IsShown(), "card without a trace when the row is off screen")
  click(h, "Show it")
  check(MOCK.trade.selected == 14, "Show it selects the recipe")
  closeCraft()
end
```

  The mock's `SelectTradeSkill(i)` (and the retail mock's `C_TradeSkillUI.OpenRecipe(id)` / `SetSelectedRecipe`) sets `MOCK.trade.offset = math.max(0, i - 4)` before `layout()`, so after "Show it" the next tick can trace the row; add `check(LevelingCodexCraftTrace:IsShown(), "traced after Show it")` after one `MOCK.advance(0.6)`. In the mock's `ALLOWED_GLOBALS`, allow the scenario-made `TradeSkillFrame` and `TradeSkillSkill1`..`TradeSkillSkill8`. `tests/run.py`: `CRAFT = ["makeCraftWindow", "login", "craftTrace", "craftNotLearned", "craftGrey", "craftScrolled", "debugReport"]` (WARRIOR and PRIEST full; WARRIOR minimal, where the scenarios skip their checks and the run only has to be free of Lua errors) and `CRAFT_RETAIL = ["makeCraftWindow:retail", "login", "craftTrace", "craftScrolled"]` (WARRIOR full: same assertions through `C_TradeSkillUI`).

- [ ] **Step 2: Run** `python tests/run.py -k craft`. Expected: FAIL `card beside the crafting window`.

- [ ] **Step 3: Implement `ProfessionGuide.lua`**: window finder (`TradeSkillFrame`, `ProfessionsFrame`, `CraftFrame`, then shown frames named `*TradeSkill*`/`*Profession*` at least 300x300 via `EnumerateFrames`, never `LevelingCodex*`); profession from `GetTradeSkillLine()` or `C_TradeSkillUI.GetBaseProfessionInfo()` matched to `ns.P[key].name` (Mining's window may be called "Smelting": match both); recipe info from either API style; row finder walks the window's shown buttons and font strings and compares text with `|c........`/`|r` and a trailing ` [N]` stripped; the trace reuses TalentGuide's look in a box form (copy `makeTrace`'s box edges and halo, not the shape copying); card styled like `LevelingCodexTalentHint` and placed with the same above/below/inside rule; ticker 0.25 s only while a crafting window is visible (start on `TRADE_SKILL_SHOW`, stop on hide); "Show it" calls `SelectTradeSkill(i)` and, when they exist, `TradeSkillFrame_SetSelection(i)` and `TradeSkillFrame_Update()` in `pcall`. Settings tick and `db.noCraftGuide`. `ns.craftDebugLines()` into `/codex debug`. Add `"noCraftGuide"` to `everyButton`'s reset list.

- [ ] **Step 4: Run** `python tests/run.py`. Expected: `PASSED`.

- [ ] **Step 5: Commit** — "Crafting window guide: trace the recipe to make now".

### Task 7: Learn levels from the trainer in `/codex debug`

**Files:**
- Modify: `Professions.lua` (TRAINER_SHOW handler, `ns.trainerDebugLines()`), `Init.lua` (debug lines)
- Modify: `tests/wowmock.lua` (trainer API), `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces: on `TRAINER_SHOW`, for each service `GetTrainerServiceInfo(i)` -> `name, subText, category` and `GetTrainerServiceSkillReq(i)` -> `skillName, skillLevel, hasReq`: when `skillName` is a guide profession's name and `name` is a route step (or smelt) whose `learn ~= skillLevel`, remember `{ name, skillLevel, learn }`. `ns.trainerDebugLines()`: `"trainer: <name> needs <skillLevel> (guide says <learn>)"` per difference, or `"trainer: no differences seen"` / `"trainer: not visited"`.
- Mock: `MOCK.trainer = { {name, skillName, skillLevel} }`, `GetNumTrainerServices`, `GetTrainerServiceInfo(i)` -> `name, "", "available"`, `GetTrainerServiceSkillReq(i)` -> `skillName, skillLevel, true`; all in `OPTIONAL`.

- [ ] **Step 1: Write the failing scenario:**

```lua
function S.trainerReqs()
  if not D() or MOCK.minimal then return end
  MOCK.trainer = { { "Rough Bronze Leggings", "Blacksmithing", 95 }, { "Runed Copper Belt", "Blacksmithing", 75 },
                   { "Copper Bracers", "Blacksmithing", 1 } }
  MOCK.event("TRAINER_SHOW")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("trainer: Rough Bronze Leggings needs 95 %(guide says 80%)"), "difference reported")
  check(not chatHas("Runed Copper Belt needs"), "matching values not reported")
end
```

  `tests/run.py`: append `"trainerReqs"` to `PROF`.

- [ ] **Step 2: Run** `python tests/run.py -k prof`. Expected: FAIL `difference reported`.
- [ ] **Step 3: Implement** the handler (registered with `pcall`) and debug lines.
- [ ] **Step 4: Run** `python tests/run.py`. Expected: `PASSED`.
- [ ] **Step 5: Commit** — "Professions: compare trainer requirements with the guide in /codex debug".

### Task 8: Docs, release notes, install

**Files:**
- Modify: `CLAUDE.md` (files table: `ProfessionData.lua`; module list entries for `Professions.lua`, `ProfessionTab.lua`, `ProfessionGuide.lua`; Tests bullets for the new checks; `gamedata.py recipes|profs`)
- Modify: `tools/UPDATING.md` (step 3: `python tools/gamedata.py profs` after an update; profession diffs)
- Modify: `CHANGELOG.md` (new `## v0.12.0` section: the features and the routes in brief, and that learn levels should be checked at a trainer with `/codex debug`)
- Modify: `CURSEFORGE_DESCRIPTION.md` (Professions section), `README.md` (one line)

- [ ] **Step 1: Write the docs** (all facts from the spec; no new claims).
- [ ] **Step 2: Run** `python tests/run.py`. Expected: `PASSED`.
- [ ] **Step 3: Install** `python tools/install.py`. Expected: every file copied and verified, `ProfessionData.lua`, `Professions.lua`, `ProfessionTab.lua`, `ProfessionGuide.lua` among them.
- [ ] **Step 4: Commit** docs with the spec and plan (`docs/superpowers/...`, `.pkgmeta`) — "Docs: profession guides".
- [ ] **Step 5: Hand-off for in-game testing**: tell the owner to restart the client (the .toc changed) and check: the Professions tab for each profession they have; open Blacksmithing and Smelting windows (trace and card, "Show it"); make an item across a step boundary (card); visit a Blacksmithing and a Mining trainer, then `/codex debug` and send the screenshot.
