# Enchanting Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An Enchanting 1-300 guide in the Codex: the route with its rods, Mote of Magic counted as
Strange Dust, a disenchanting section that reads your bags, and a crafting window that outlines a missing
rod or Motes first.

**Architecture:** Enchanting is data in `ProfessionData.lua` on the existing profession code (as
Tailoring). New: `rods` (each step names its rod; a better rod counts, from the game's totem masks),
`disenchant` (bands by required level), a new `Disenchant.lua` (band lookup, bag scan), and a rod-first
pick ahead of the parts-first pick. Mote of Magic is a `part`.

**Tech Stack:** Lua 5.1 (WoW: Forever, Interface 16001), Python 3 harness with lupa, `tools/gamedata.py`
(wago.tools tables, cached build 1.60.1.70862).

**Spec:** `docs/superpowers/specs/2026-11-08-enchanting-guide-design.md` (route table, tiers, rods,
disenchant table, texts: copy values from there).

## Global Constraints

- Lua 5.1: no `goto`, `//`, integer division, `\u{}`; no `bit` library assumed. No new globals.
- Runtime text ASCII; guide text through `ns.plain()`.
- Guard every optional API: `GetItemCount`, `C_Container`, `GetContainerNumSlots`, `GetContainerItemInfo`,
  `GetItemInfo` may be missing (the minimal client removes them).
- Recipe `spell`, `yellow`, `grey`, `mats`, `icon`, `makes` equal `tools/reference/forever.json`; a step's
  `rod` equals its recipe's `tool`; rods' `category`/`mask` equal the reference. `learn`, sources, notes,
  tiers and the disenchant table are guide text from the spec.
- Tier banner text (`short`, else `where`) is 60 characters or fewer.
- `Disenchant.lua` is a new file: add it to both `.toc` files after `Professions.lua`, byte-identical. The
  owner must restart the client.
- Blacksmithing, Mining and Tailoring texts and behaviour stay unchanged (their scenarios must pass as they are).
- Run `python tests/run.py` before every commit. Never push a tag. Install with `python tools/install.py`.

## Review Focus

1. Minimal client (no `GetItemCount`, no bag APIs, no `GetItemInfo`): the Enchanting tab renders the rod
   line without "you have"/"you need", the table without a bag list, no Lua error. Pinned by `enchantTab`
   in the minimal variant (Task 2).
2. Bag items the client hasn't loaded (`GetItemInfo` returns nil), white items, and non-weapon/armour items:
   left out of the bag list. Pinned by `enchantBags` (Task 2).
3. A better rod in the bags (Truesilver at 150): counts as the Silver rod, so the card says "you have it"
   and the crafting window doesn't ask for a rod. Pinned by `enchantTabCases` (Task 2) and
   `craftEnchanting` (Task 3).
4. A rod that's grey but still needed (skill 270, no rod): the crafting window outlines the rod, not
   "Grey now". Pinned by `craftEnchanting` (Task 3).
5. Enchanting not learned, and at 300: the tab renders; at 300 no "you need this now". Pinned by
   `enchantTabCases` (Task 2).

---

### Task 1: Game reference, audit and the Enchanting data

**Files:**
- Modify: `tools/gamedata.py` (`PROFESSIONS`, `TABLES`, `build_professions`, `build_reference`, `audit_professions`, usage line)
- Modify: `tools/reference/forever.json` (regenerated)
- Modify: `tests/run.py` (`PROF_KEYS`, `prof_shape_checks`, `game_checks` reference rows)
- Modify: `ProfessionData.lua` (add `ENCHANTING`)
- Create: `tools/audits/2026-11-08-enchanting.md`
- Modify: `CLAUDE.md` (the `ProfessionData.lua` row, the `tools/gamedata.py` row, Game checks)

**Interfaces:**
- Produces (reference): each recipe needing a tool has `tool` (the TotemCategory name, e.g.
  "Runed Silver Rod"; Blacksmithing's hammer recipes get "Blacksmith Hammer" or the client's name).
  `ref["rods"] = { "Runed Copper Rod": { "category": 373, "mask": 1, "item": 6218 }, ... }` for
  TotemCategory type 3 (the five Runed rods).
- Produces (data): `LevelingCodexProfessions.ENCHANTING = { name = "Enchanting", skillLine = 333,
  icon = "trade_engraving", tiers, steps, parts, rods, disenchant }`.
  - `steps[i].rod`: the rod's name, on every step whose recipe has a `tool`.
  - `parts = { { name = "Dust to Motes", plural = "Motes of Magic", unit = "motes", spell, icon, yellow,
    grey, mats = { { "Strange Dust", 1 } }, makes = { "Mote of Magic", 3 }, learn = 1, source } }`.
  - `rods[i] = { name, category, mask, spell, icon, yellow, grey, mats, learn, source }` for Copper (373, 1,
    learn 1, "Known when you learn Enchanting"), Silver (374, 3, 100), Golden (375, 7, 150), Truesilver
    (376, 15, 200; "Enchanting trainer").
  - `disenchant = { note = <text>, bands = { { from, to, dust, essence, shard }, ... } }`: the spec's 11
    bands (1-10 has no `shard`). `note` = "Disenchant any green or blue weapon or armour, at any skill:
    green armour mostly gives dust, green weapons mostly essence, blue items a shard."

- [ ] **Step 1: Write the failing checks**

`tests/run.py`:
- `PROF_KEYS` gains `"ENCHANTING"`.
- `prof_shape_checks`, any profession:
  - each `rods` entry has `name`, `category`, `mask`, `spell`, `icon`, `yellow`, `grey`, `mats`, `learn`, `source`;
  - each step's `rod` is a `rods` name ("...: rod X is not in the rods list");
  - `disenchant.bands` run from 1 to 60 with no gap or overlap ("...: disenchant bands must run 1-60 without gaps"), each with `dust` and `essence`.
- `game_checks` `want` gains `("Enchanting", "Dust to Motes", 10, 15, [["Strange Dust", 1]])` and
  `("Enchanting", "Enchant Shield - Greater Stamina", 285, 325, [["Dream Dust", 6]])`; an error unless
  `ref["rods"]["Runed Truesilver Rod"]` is `{"category": 376, "mask": 15, ...}` and the reference recipe
  "Enchant Cloak - Superior Defense" has `tool == "Runed Truesilver Rod"`.

`tools/gamedata.py`:
- `PROFESSIONS` gains `"Enchanting": 333`; `TABLES` gains `"TotemCategory"`, `"ItemDisenchantLoot"`; usage
  line "Blacksmithing / Mining / Tailoring / Enchanting".
- `build_professions`: `rec["tool"]` from `SpellTotems.RequiredTotemCategoryID_0` → `TotemCategory.Name_lang`.
- `build_reference`: `ref["rods"]` from `TotemCategory` rows with `TotemCategoryType == "3"`, the item
  from `ItemSparse.TotemCategoryID`.
- `audit_professions`:
  - error "step A-B: NAME needs TOOL in game, data says ROD" when `rod` differs from the recipe's `tool`, including a missing `rod`;
  - `check_recipe("rod", r, r["name"])` for each rod, plus an error when its `category`/`mask` differ from `ref["rods"]`;
  - error "disenchant: ITEM is not an Enchanting material" for any band's dust, essence or shard that isn't in `items`.

- [ ] **Step 2: Run to see them fail**

Run: `python tests/run.py -k prof`
Expected: FAIL with "professions: no ENCHANTING" and "reference: Enchanting Dust to Motes should be yellow 10 grey 15".

- [ ] **Step 3: Regenerate the reference**

Run: `python tools/gamedata.py fetch --build 1.60.1.70862` (downloads the two new tables), then
`git show HEAD:tools/reference/forever.json > "$TMP/old.json"; python tools/gamedata.py build --build 1.60.1.70862; python tools/gamedata.py diff "$TMP/old.json"`
(`$TMP` = the session scratchpad).
Expected: the diff names Enchanting as a new profession and no class change; `git diff --stat` shows
additions only. The added `tool` fields on existing recipes and `rods` are the only other changes. Check
with `git diff tools/reference/forever.json | grep '^-' | grep -v '^---' | head`, which should be empty.

- [ ] **Step 4: Write `ENCHANTING` in `ProfessionData.lua`**

Generate the recipe fields from the reference (as for Tailoring) and the guide text from the spec. Tiers (exact):
- `{ name = "Apprentice", cap = 75, skill = 1, level = 1, where = "Any Enchanting trainer" }`
- `{ name = "Journeyman", cap = 150, skill = 50, level = 10, short = "An Expert, Master or Artisan Enchanter", where = "An Expert, Master or Artisan Enchanter (Lucan Cordell (Stormwind), Gimble Thistlefuzz (Ironforge), Taladan (Darnassus), Godan (Orgrimmar), Teg Dawnstrider (Thunder Bluff), Lavinia Crowe (Undercity), Xylinnia Starshine (Feralas), Kitta Firewind (Elwynn Forest), Hgarth (Stonetalon Mountains), Annora (Uldaman)), Vanessa Sellers (Alterac Mountains) or Melanie Sable (Riverglades); not the Journeyman Enchanters or the Zephras Isle trainers" }`
- `{ name = "Expert", cap = 225, skill = 125, level = 20, short = "Kitta Firewind (Elwynn) or Hgarth (Stonetalon)", where = "Alliance: Kitta Firewind (Elwynn Forest) or Vanessa Sellers (Alterac Mountains). Horde: Hgarth (Stonetalon Mountains). Both: Melanie Sable (Riverglades) or Annora (inside Uldaman)" }`
- `{ name = "Artisan", cap = 300, skill = 200, level = 35, short = "Annora, inside Uldaman (the only Artisan trainer)", where = "Annora, inside the Uldaman dungeon (Badlands): the only Artisan Enchanting trainer" }`

Steps: the spec's 18 rows; `rod` per the table ("Runed Copper Rod" ... "Runed Truesilver Rod"); `learn` from
the table. Sources (exact):
- "Known when you learn Enchanting" (1-10, 10-20);
- "Enchanting trainer" (trainer rows, rod rows);
- "Formula: Enchant Cloak - Minor Agility, sold by Dalria (Ashenvale) or Kulwia (Stonetalon Mountains), 8s42";
- "Formula: Enchant Shield - Greater Stamina, sold by Mythrin'dir (Darnassus) or Daniel Bartlett (Undercity), about 1g, one at a time".

Each enchant step's `note` starts with what to enchant:
- "Enchant your own SLOT again and again: each enchant replaces the last.", with SLOT = bracers / chest / cloak / boots / gloves;
- the shield step: "Enchant any shield again and again (a cheap vendor one is fine): each enchant replaces the last.";
- then the spec's note column.

The 1-10 step gets `makes = { "Mote of Magic", 3 }`; the 10-20 step `extra = { { "Copper Rod", 1 } }`; `alt` from the table.

- [ ] **Step 5: Audit Enchanting alone**

Run: `python tools/gamedata.py profs ENCHANTING`
Expected: no errors; at most "green for N of its M points" or icon warnings. Fix anything else.

- [ ] **Step 6: Run the whole harness**

Run: `python tests/run.py`
Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 7: Audit file and CLAUDE.md, then commit**

`tools/audits/2026-11-08-enchanting.md`: every fact with its source (client table, Wowhead page and date,
wow-professions), the six differences from Wowhead's route, the in-game checks. CLAUDE.md: the
`ProfessionData.lua` row (`ENCHANTING`, `rods`, step `rod`, `disenchant`, part `unit`), the gamedata row
(`tool`, `rods`, the two new tables), Game checks (rod vs tool, rods, disenchant materials).

```bash
git add tools/gamedata.py tools/reference/forever.json tests/run.py ProfessionData.lua tools/audits/2026-11-08-enchanting.md CLAUDE.md
git commit -m "Enchanting: game reference with rods and tools, audit, the 1-300 route data"
```

---

### Task 2: Rods, the disenchanting section and the Enchanting tab

**Files:**
- Create: `Disenchant.lua`
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (add `Disenchant.lua` after `Professions.lua`)
- Modify: `Professions.lua` (`PROF_ORDER`, `ns.profRod`, `ns.profHasRod`)
- Modify: `ProfessionTab.lua` (rod line, `via` unit, disenchanting section)
- Modify: `tests/wowmock.lua` (bags and item info), `tests/scenarios.lua`, `tests/run.py`
- Modify: `CHANGELOG.md`, `README.md`, `CURSEFORGE_DESCRIPTION.md`, `CLAUDE.md` (modules 2b, 2c `Disenchant.lua`, 5b; tests)

**Interfaces:**
- Consumes: `ENCHANTING.rods`, `steps[i].rod`, `disenchant`, part `unit` (Task 1).
- Produces:
  - `ns.PROF_ORDER = { "BLACKSMITHING", "MINING", "TAILORING", "ENCHANTING" }`.
  - `ns.profRod(key, step) -> rod|nil`.
  - `ns.profHasRod(key, rod) -> true|false|nil`. True when any rod `r` in `P.rods` with `GetItemCount(r.name) > 0` has every bit of `rod.mask` set in `r.mask`. The bit test is arithmetic: for each power of two `p` up to `rod.mask`, `floor(rod.mask / p) % 2 == 1` requires `floor(r.mask / p) % 2 == 1`. Nil without `GetItemCount`.
  - `ns.deBand(key, level) -> band|nil` (levels below 1 count as 1).
  - `ns.deNeeded(key, step) -> { [name] = true }`. These are the step's materials that are some band's dust, essence or shard, plus the first material of each part the step uses.
  - `ns.deBagItems(key) -> list|nil`.
    - Each entry is `{ name, level, quality, weapon, gives = { names } }`.
    - Bags 0-4 through `C_Container.GetContainerNumSlots/GetContainerItemInfo` (table return: `.hyperlink`), else the global `GetContainerNumSlots/GetContainerItemInfo` (classic returns: link 7th).
    - Then `GetItemInfo(link)`: name 1st, quality 3rd, required level 5th, classID 12th (2 weapon, 4 armour).
    - Quality 2: weapon gives essence then dust, armour dust then essence. Quality 3-4: the band's shard, or its essence when the band has none.
    - Skipped: not loaded (nil), quality < 2 or > 4, other classes.
    - Returns nil when neither bag API exists or `GetItemInfo` is missing.
- Mock (`tests/wowmock.lua`, all optional, removed in minimal):
  - `MOCK.bagItems = {}`, a list of `{ name, quality, level, class = "Armor"|"Weapon"|"Trade Goods", loaded }` in bag 0.
  - `C_Container.GetContainerNumSlots(bag)`, `C_Container.GetContainerItemInfo(bag, slot)`.
  - `GetItemInfo(link)` returns nil when `loaded == false`.

- [ ] **Step 1: Write the failing scenarios**

`S.skills` names gain `EN = "Enchanting"`. New scenarios (`if not D() then return end`):
- `S.enchantTab()` (skills `EN;150;225`): open Professions, click "Enchanting".
  - The text has "Enchanting 150 / 225", "Enchant Bracer - Lesser Stamina", "about 5 more to 155", "Enchant your own bracers", "DISENCHANTING".
  - With `GetItemCount`: "Rod: Runed Silver Rod %- you need it". After `MOCK.bags["Runed Silver Rod"] = 1`, "Rod: Runed Silver Rod %(you have it%)". Without it: "Rod: Runed Silver Rod" and no "you need it".
  - No "%d+ Mote of Magic" in the shopping list text.
  - The "Level 26%-30: Soul Dust" band row is marked "you need this now", and sits above "Level 1%-10" (by `textY`).
  - "3 Lesser make 1 Greater".
  - Without the bag API: no "IN YOUR BAGS". The tab still renders.
  - Four profession buttons. `MOCK.staleUnder(win(), "Professions")`.
- `S.enchantTabCases()`:
  - With `MOCK.bags = { ["Runed Truesilver Rod"] = 1 }` at 150: "Rod: Runed Silver Rod %(you have it%)" (a better rod counts).
  - Skill 1: "Dust to Motes", a Strange Dust row "for %d+ motes", no Mote row. The "Level 1%-10: Strange Dust" band is marked.
  - Skill 265: "Enchant Shield - Greater Stamina", "Mythrin'dir", "any shield".
  - Skill 300: "ROUTE DONE", no "you need this now".
- `S.enchantBags()` (`if not D() or not C_Container then return end`):
  - `MOCK.bagItems`:
    - Ironforge Boots: quality 2, level 22, Armor;
    - Rusty Sword: 2, 8, Weapon;
    - Blue Cloak: 3, 33, Armor;
    - Linen Shirt: 1, 5, Armor;
    - Copper Ore: 1, 1, Trade Goods;
    - Unseen Gloves: 2, 30, Armor, loaded = false.
  - The tab text has "IN YOUR BAGS", "Ironforge Boots %(level 22%): Soul Dust or Greater Astral Essence", "Rusty Sword %(level 8%): Lesser Magic Essence or Strange Dust", "Blue Cloak %(level 33%): Large Glowing Shard".
  - It has no "Linen Shirt", "Copper Ore" or "Unseen Gloves".
  - At 150 the Soul Dust item comes first (by `textY`).
  - With 12 green items, at most 8 rows.
- `S.enchantSkillUps()`:
  - 159 → 160 gives toast "Enchanting 160" naming "Enchant Boots - Lesser Agility".
  - Level 9 → 10 at 60/75 gives "TRAIN JOURNEYMAN ENCHANTING" and "An Expert, Master or Artisan Enchanter".
- `S.enchantDebug()`: "profession: Enchanting 150/225, step 135%-155 Enchant Bracer %- Lesser Stamina".
- `S.profNone` also checks "profession: Enchanting not learned".

`tests/run.py`:
- `ENCHANT = ["skills:EN;150;225:professions", "login", "enchantDebug", "enchantTab", "enchantTabCases", "enchantBags"]`.
- `ENCHANT_LINES = ["skills:EN;150;225:skilllines", "login", "enchantDebug"]`.
- `PROF_UPS` gains `"enchantSkillUps"`.
- Runs per variant: `WARRIOR/%s/enchant` and `PRIEST/%s/enchant-skilllines`.

- [ ] **Step 2: Run to see them fail**

Run: `python tests/run.py -k enchant`
Expected: FAIL. There's no "Enchanting" button, and the debug line is missing.

- [ ] **Step 3: Implement `Professions.lua`, `Disenchant.lua`, the .toc files and `ProfessionTab.lua`**

- **Functions:** as in Interfaces.
- **Step card:** after "Learn at ...", when `ns.profRod(key, step)`, one line:
  - "Rod: NAME (you have it)";
  - or "Rod: NAME - you need it: MATS (learn at L)", where MATS is the rod's materials as "N Item" joined with ", ";
  - or "Rod: NAME" when `ns.profHasRod` is nil.
- **Shopping row `via`:** the unit is `part.unit` when set, else "bolts" when the part's name starts with "Bolt", else "parts".
- **Disenchanting section** (after the shopping list, when `P.disenchant`; title "DISENCHANTING"):
  - the `note` line;
  - the band rows "Level A-B: DUST, ESSENCE, SHARD", where the bands that give a `ns.deNeeded` material come first and get "  -  you need this now";
  - "3 Lesser make 1 Greater, and back: right-click the essence.";
  - then, when `ns.deBagItems` isn't nil, "IN YOUR BAGS" with up to 8 rows "NAME (level L): G1 or G2", needed first, then by level, lowest first. With an empty list: "No green or blue weapons or armour in your bags."

- [ ] **Step 4: Run the Enchanting scenarios**

Run: `python tests/run.py -k enchant`
Expected: PASS.

- [ ] **Step 5: Run the whole harness**

Run: `python tests/run.py`
Expected: `PASSED: 0 run(s) failed`. The Tailoring "for N bolts" texts are unchanged.

- [ ] **Step 6: Docs, then commit**

- **CHANGELOG v0.12.0:** an Enchanting bullet (the route summary, rods, Motes, the disenchanting section and bag list, Annora as the only Artisan trainer).
- **README and CurseForge text:** add Enchanting.
- **CLAUDE.md:** modules 2b (`profRod`, `profHasRod`), a new 2c `Disenchant.lua`, and 5b (rod line, disenchanting section); tests (`EN`, `MOCK.bagItems`).

```bash
git add Disenchant.lua LevelingCodex.toc LevelingCodex_Camelot.toc Professions.lua ProfessionTab.lua tests/wowmock.lua tests/scenarios.lua tests/run.py CHANGELOG.md README.md CURSEFORGE_DESCRIPTION.md CLAUDE.md
git commit -m "Enchanting: rods per step, the disenchanting section with your bags, Enchanting in every profession list"
```

---

### Task 3: Crafting window: rod first, Motes first

**Files:**
- Modify: `ProfessionGuide.lua` (`rodFirst`, `partFirst`'s count, `pickFor`, the card line, grey branch, status)
- Modify: `Window.lua` (Settings texts: crafting window and skill-up cards name Enchanting)
- Modify: `tests/scenarios.lua`, `tests/run.py` (`CRAFT`, `CRAFT_RETAIL`)
- Modify: `CHANGELOG.md`, `CURSEFORGE_DESCRIPTION.md`, `CLAUDE.md` (module 7a)

**Interfaces:**
- Consumes: `ns.profRod`, `ns.profHasRod` (Task 2), `ns.profPart` (existing).
- Produces:
  - A rod pick `{ name, spell, icon, yellow, grey, learn, mats, from, to, rodOf = step }` when all of these hold:
    - the step has a `rod`;
    - `ns.profHasRod(key, rod) == false`;
    - the step's recipe and the rod's recipe are both in the window (`findRecipe`).
  - `pickFor` order: rod pick, then part pick, then the step.
  - A part pick's `canMake` becomes `floor(have / cloth per craft) * makes per craft`. Bolts make 1, so Tailoring's text is unchanged.

- [ ] **Step 1: Write the failing scenarios**

`S.craftEnchanting()` (`if not craftReady() then return end`). Save and restore `MOCK.trade` as `tailorWindow` does.
- **Setup:** `MOCK.setSkill("Enchanting", 150, 225)`, line "Enchanting".
  - Recipes: `{ "Runed Silver Rod", "easy", 0 }`, `{ "Enchant Bracer - Lesser Stamina", "optimal", 0 }`, `{ "Dust to Motes", "trivial", 3 }`.
  - Bags: `MOCK.bags = {}`.
- **Rod first:** the hint has "Make your Runed Silver Rod first: every enchant from here needs it.", and the trace is on `TradeSkillSkill1`.
- **A better rod counts:** `MOCK.bags["Runed Truesilver Rod"] = 1`, advance 1. The hint names "Enchant Bracer - Lesser Stamina" with no "first", and the trace is on `TradeSkillSkill2`.
- **Step recipe missing:** `MOCK.bags = {}`, remove the bracer recipe, advance 1. The hint has "Not learned yet" and no "first".
- **Grey rod still needed:** skill 270 (`MOCK.trade.rank = 270` and `MOCK.setSkill`).
  - Recipes: `{ "Runed Truesilver Rod", "trivial", 0 }`, `{ "Enchant Shield - Greater Stamina", "optimal", 0 }`.
  - The hint has "Make your Runed Truesilver Rod first", the trace is shown, and there's no "Grey now".
- **Motes first:** skill 12, `MOCK.bags = { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 5 }`.
  - Recipes: `{ "Dust to Motes", "trivial", 5 }`, `{ "Enchant Bracer - Inferior Stamina", "optimal", 0 }`.
  - The hint has "Make Motes of Magic first: your 5 Strange Dust make 15."
- **Teardown:** restore.

`tests/run.py`: `"craftEnchanting"` in `CRAFT` (before `"debugReport"`) and `CRAFT_RETAIL`.

- [ ] **Step 2: Run to see it fail**

Run: `python tests/run.py -k craft`
Expected: FAIL. "Make your Runed Silver Rod first" is not found.

- [ ] **Step 3: Implement**

- **`rodFirst(key, step)`:** as in Interfaces, placed before `partFirst`.
- **Card line:** a rod pick's card line is "Make your NAME first: every enchant from here needs it."
- **Shared handling:** rod and part picks both skip the "Grey now" branch and drop the colour prefix in the status, so test `pick.partOf or pick.rodOf`.
- **`canMake`:** multiply by `part.makes[2]`.
- **Settings texts:** "Blacksmithing, Smelting, Tailoring or Enchanting" and "Mining, Blacksmithing, Tailoring or Enchanting".

- [ ] **Step 4: Run the crafting scenarios**

Run: `python tests/run.py -k craft`
Expected: PASS.

- [ ] **Step 5: Run the whole harness**

Run: `python tests/run.py`
Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 6: Docs, commit, install**

- **CHANGELOG:** the crafting window bullet names Enchanting and the rod/Motes-first picks.
- **CurseForge text:** the crafting window line.
- **CLAUDE.md:** module 7a (`rodFirst` and the pick order).

```bash
git add ProfessionGuide.lua Window.lua tests/scenarios.lua tests/run.py CHANGELOG.md CURSEFORGE_DESCRIPTION.md CLAUDE.md
git commit -m "Enchanting: the crafting window outlines a missing rod, then Motes, first"
python tools/install.py
```
Expected: every file copied and verified. Tell the owner to **restart the client** (a `.toc` changed).
