# Questie Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Codex quest guide works side by side with Questie (no auto-questing clashes, one hold-back key, step window beside Questie's tracker) and, when QuestieDB is installed, its arrow leads to the nearest spawn of an objective once you reach a step's camp.

**Architecture:** A new module `QuestieSupport.lua` (`ns.questie`) reads Questie's settings and tracker frame and QuestieDB's public `LibQuestieDB` API at call time, every call guarded. `QuestGuide.lua` consults it in its auto-questing handlers, its window placement and its arrow painter; `Window.lua` adds the setting and notes; `Init.lua` adds its debug lines.

**Tech Stack:** WoW Forever addon Lua 5.1; headless harness (Python + lupa) in `tests/`.

**Spec:** `docs/superpowers/specs/2026-11-11-questie-compatibility-design.md`

## Global Constraints

- Lua 5.1 (WoW flavour): no `goto`, no `//`, no integer division.
- All runtime text is ASCII; route names and QuestieDB names through `ns.plain()`.
- No new globals. `QuestieSupport.lua` only reads `Questie`, `Questie_BaseFrame`, `LibQuestieDB`.
- Every optional API and every Questie/QuestieDB call goes through `ns.try`/`pcall` and type checks.
- Both `.toc` files stay byte-identical and keep `## Version: @project-version@`.
- Constants: `CAMP_ENTER = 200`, `CAMP_LEAVE = 300`, `SPAWN_RANGE = 400` yards; "nearby" within `Q.arrived()` (35).
- Window offsets beside Questie's tracker: `TOPRIGHT` to its `TOPLEFT` (-12, -40), or `TOPLEFT` to its `TOPRIGHT` (12, -40). Default spot unchanged: `RIGHT`, `UIParent`, `RIGHT`, -48, 80.
- `LibQuestieDB.RequireContract(1)`; setting key `db.noNearestSpawn` (unset = on).
- Exact copy: setting "Point the arrow at the nearest objective (QuestieDB)"; notes "Questie's auto-accept is on, so Questie accepts quests." and "Questie's auto-complete is on, so Questie turns quests in."; arrow captions `"<name> - <N> yd"` and `"<name> nearby"`.
- Run `python tests/run.py` before every commit: no Lua errors, no non-ASCII runtime text, no leaked globals.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push a tag.

## Review Focus

- Questie loaded but its `db` not built yet (early login): read as "off", no error. Test in Task 1 (`Questie = {}`).
- Questie's tracker exists but has no position yet (`GetCenter` returns nil): keep the default spot. Test in Task 2.
- A non-English client or a Forever-renamed objective: no log line matches a QuestieDB name, so every objective counts. Test in Task 4 (log "Gnoll Pelt 0/5").
- An objective entity with no spawns at all (`NpcDB.spawns` nil): skipped without error. Test in Task 4 (NPC 999 "Ghost").
- The guide moving to another step: no stale nearest target. Test in Task 4 (quest 7 turned in).

## Test geometry (used in Task 4)

Elwynn Forest (map 1429, AreaId 12) extents 3470.833 x 2314.583 yd: 1% x = 34.708 yd, 1% y = 23.146 yd. The quest 7 step (Kobold Camp Cleanup) is at C = (48.8, 36.4). Kobold Vermin (NPC 6) spawns on AreaId 12: V1 (50.0, 38.0), V2 (47.0, 34.0), V3 (48.9, 40.6, phase 5), V4 (48.8, 54.0) (407 yd from C); on AreaId 40 (Westfall): (48.8, 44.0). Kobold Worker (NPC 257): W1 (44.0, 36.4). Player positions:

| Position | From C | Expected arrow |
|---|---|---|
| P1 (48.8, 50.0) | 315 yd | outside the camp: "315 yd" |
| P2 (48.8, 44.0) | 176 yd | enters: V1 "Kobold Vermin - 145 yd" (V3 phased, V4 out of range, Westfall ignored) |
| P3 (48.8, 48.0) | 268 yd | still inside after P2: V1 "Kobold Vermin - 235 yd" (V4 would be 139); fresh from outside: "268 yd" |
| P4 (50.0, 38.5) | 64 yd | "Kobold Vermin nearby" (V1 at 12 yd) |

---

### Task 1: Questie settings, auto-questing and the hold-back key

**Files:**
- Create: `QuestieSupport.lua`
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (add `## OptionalDeps: Questie, QuestieDB` after `## SavedVariablesPerCharacter`; list `QuestieSupport.lua` right after `Quests.lua`)
- Modify: `QuestGuide.lua:594-646` (`interact`, `pickFromList`)
- Modify: `Window.lua:1165-1168` (auto tickboxes)
- Modify: `Init.lua:162` (debug lines)
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces (in `QuestieSupport.lua`, all at call time, never erroring):
  - `ns.questie.loaded() -> boolean`: `Questie` is a table with a `db.profile` table.
  - `ns.questie.autoAccept() -> boolean`: `profile.autoAccept.enabled == true`, or `profile.autoaccept == true` (older Questie).
  - `ns.questie.autoComplete() -> boolean`: `profile.autocomplete == true`.
  - `ns.questie.keyName() -> "Shift"|"Ctrl"|nil`: from `profile.autoModifier` (`"shift"`, `"ctrl"`); nil when not loaded, `"alt"`, `"disabled"` or anything else.
  - `ns.questie.modifierHeld() -> boolean`: Questie's key is down (`IsShiftKeyDown`, `IsControlKeyDown`, `IsAltKeyDown` through `ns.try`); false for `"disabled"`/unknown.
  - `ns.questieDebugLines() -> string[]`: first line `"Questie: not loaded"` or `"Questie: loaded (version V), auto-accept on|off, auto-complete on|off, key Shift|Ctrl|Alt|none"` (V from `C_AddOns.GetAddOnMetadata` or `GetAddOnMetadata`, else `"?"`). Later tasks append lines.
- Test mocks produced (in `tests/wowmock.lua`):
  - `MOCK.makeQuestie(opts)`: sets the global `Questie = { db = { profile = { autoAccept = { enabled = opts.autoAccept == true }, autocomplete = opts.autocomplete == true, autoModifier = opts.modifier or "shift" } } }`; with `opts.legacyAccept` the profile has `autoaccept = true` and no `autoAccept` table. Unless `opts.tracker == false`, it shows a frame `Questie_BaseFrame` (parent `UIParent`, size 280 x 400, `_cx = opts.cx or 1700`, `_cy = 700`), reusing an existing one. With `opts.tracker == false` an existing tracker is hidden.
  - `MOCK.shift`, `MOCK.ctrl` drive `IsShiftKeyDown`/`IsControlKeyDown` (default false).
  - `ALLOWED_GLOBALS` gains `Questie`, `Questie_BaseFrame`, `LibQuestieDB` (made by scenarios).

- [ ] **Step 1: Add the mocks** to `tests/wowmock.lua` as listed above.

- [ ] **Step 2: Write the failing scenario** in `tests/scenarios.lua` and add `"questQuestieAuto"` to the WARRIOR full quest scenario list in `tests/run.py`.

```lua
function S.questQuestieAuto()
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - A Threat Within"), "fresh route starts with an accept")
  LevelingCodexDB.questAutoAccept = true
  MOCK.gossipAvailable = { { questID = 783, title = "A Threat Within" } }
  Questie = {} -- loaded, settings not built yet
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == 783, "Questie without settings leaves auto-accept to the Codex")
  MOCK.gossipPicked = nil
  MOCK.makeQuestie({ autoAccept = true })
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == nil, "Questie's auto-accept handles gossip lists")
  MOCK.interactionQuest = 783
  MOCK.event("QUEST_DETAIL")
  check(not MOCK.questAccepted, "Questie's auto-accept handles the quest window")
  MOCK.makeQuestie({ legacyAccept = true })
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == nil, "an older Questie's autoaccept counts too")
  slash("quests")
  click(win(), "Settings")
  check(questText(win(), "Questie's auto-accept is on, so Questie accepts quests."), "the tickbox says Questie handles it")

  MOCK.makeQuestie({}) -- auto-accept off, key Shift
  click(win(), "Settings")
  local box = findButton(win(), function(l) return l == "Auto-accept the current guide quest" end)
  MOCK.fire(box, "OnEnter")
  check(table.concat(GameTooltip._lines or {}, " "):find("Hold Alt or Shift to stop it.", 1, true),
    "the tooltip names Questie's key")
  MOCK.shift = true
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("QUEST_DETAIL")
  check(MOCK.gossipPicked == nil and not MOCK.questAccepted, "Questie's key holds the Codex back")
  MOCK.shift, MOCK.alt = false, true
  MOCK.event("QUEST_DETAIL")
  check(not MOCK.questAccepted, "Alt holds back the quest window too")
  MOCK.alt = false
  MOCK.event("QUEST_DETAIL")
  check(MOCK.questAccepted == 783, "the Codex accepts when Questie's auto-accept is off and no key is held")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Questie: loaded %(version .-%), auto%-accept off, auto%-complete off, key Shift"),
    "debug reports Questie's settings")

  local objective = { text = "Speak to McBride 1/1", numFulfilled = 1, numRequired = 1, finished = true }
  MOCK.questLog = { { questID = 783, title = "A Threat Within", objectives = { objective } } }
  MOCK.event("QUEST_ACCEPTED", 783)
  MOCK.event("QUEST_LOG_UPDATE")
  LevelingCodexDB.questAutoTurnin, MOCK.questChoices = true, 0
  MOCK.makeQuestie({ autocomplete = true })
  MOCK.event("QUEST_COMPLETE")
  check(not MOCK.questRewarded, "Questie's auto-complete handles turn-ins")
  click(win(), "Settings")
  check(questText(win(), "Questie's auto-complete is on, so Questie turns quests in."), "the turn-in tickbox says so")
  MOCK.makeQuestie({})
  MOCK.event("QUEST_COMPLETE")
  check(MOCK.questRewarded == 783, "the Codex turns in when Questie's auto-complete is off")
end
```

- [ ] **Step 3: Run it and see it fail**

Run: `python tests/run.py -k questQuestieAuto`
Expected: FAIL, `ASSERT: Questie's auto-accept handles gossip lists`.

- [ ] **Step 4: Implement**
  - `QuestieSupport.lua`: `local _, ns = ...; local M = {}; ns.questie = M` (not `Q`: that name means `ns.quests` everywhere else) with the functions in Interfaces, and `ns.questieDebugLines()`.
  - `QuestGuide.lua`: a local `heldBack()` = `try(IsAltKeyDown) == true or ns.questie.modifierHeld()`. `interact` returns early when `heldBack()`; its accept branch also needs `not ns.questie.autoAccept()`, its turn-in branch `not ns.questie.autoComplete()`. `pickFromList` uses `heldBack()` in place of the Alt check and the same two conditions in `accept`/`turnin`.
  - `Window.lua`: both auto tooltips end `"Hold Alt" .. (key and (" or " .. key) or "") .. " to stop it."` with `key = ns.questie.keyName()`. Under each tickbox, while `ns.questie.autoAccept()` / `ns.questie.autoComplete()`, draw its note with `T(..., "body", C.dim)` and advance `y`.
  - `Init.lua`: append `ns.questieDebugLines()` after `ns.questDebugLines()`.
  - Both `.toc` files as listed under Files.

- [ ] **Step 5: Run it and see it pass**

Run: `python tests/run.py -k questQuestieAuto` then `python tests/run.py -k quests`
Expected: both PASS (the existing `questGossip` and `questRecorder` still pass).

- [ ] **Step 6: Commit**

```bash
git add QuestieSupport.lua QuestGuide.lua Window.lua Init.lua LevelingCodex.toc LevelingCodex_Camelot.toc tests/wowmock.lua tests/scenarios.lua tests/run.py
git commit -m "Let Questie's auto-questing and hold-back key take precedence"
```

### Task 2: Step window beside Questie's tracker

**Files:**
- Modify: `QuestieSupport.lua`
- Modify: `QuestGuide.lua:30-35` (`place`), `:83-88` (`OnDragStop`), `:425-433` (`ns.questRefresh`)
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: `MOCK.makeQuestie` (Task 1), `ns.questieDebugLines` (Task 1).
- Produces:
  - `ns.questie.trackerSide() -> frame, "left"|"right" | nil`: `Questie_BaseFrame` when it is shown and `GetCenter` returns a number; `"left"` (our window to its left) when its centre x times its effective scale is greater than half of `UIParent:GetWidth()` times `UIParent`'s effective scale (missing scales read as 1).
  - `ns.questViewerPlacement() -> "saved position"|"beside Questie's tracker"|"default spot"` (QuestGuide.lua).
  - `ns.questieDebugLines()` adds `"Step window: " .. ns.questViewerPlacement()`.

- [ ] **Step 1: Write the failing scenario** and add `"questQuestieTracker"` to `tests/run.py`.

```lua
function S.questQuestieTracker()
  S.login()
  local viewer = questViewer()
  local p, rel, rp, x, y = viewer:GetPoint()
  check(p == "RIGHT" and rel == UIParent and x == -48 and y == 80, "default spot without Questie")
  MOCK.makeQuestie({ cx = 1700 }) -- Questie builds its tracker after login
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(p == "TOPRIGHT" and rel == Questie_BaseFrame and rp == "TOPLEFT" and x == -12 and y == -40,
    "beside a right-hand tracker, on its left")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Step window: beside Questie's tracker"), "debug names the placement")
  Questie_BaseFrame._cx = 200
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(p == "TOPLEFT" and rel == Questie_BaseFrame and rp == "TOPRIGHT" and x == 12 and y == -40,
    "beside a left-hand tracker, on its right")
  Questie_BaseFrame.GetCenter = function() return nil end
  MOCK.event("QUEST_LOG_UPDATE")
  check(select(2, viewer:GetPoint()) == UIParent, "a tracker without a position yet is ignored")
  Questie_BaseFrame.GetCenter = nil
  Questie_BaseFrame:Hide()
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(p == "RIGHT" and rel == UIParent and x == -48 and y == 80, "a hidden tracker restores the default spot")
  MOCK.drag(viewer, -30, 0)
  Questie_BaseFrame:Show()
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(rel == UIParent and x == -78, "a dragged position wins over Questie's tracker")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Step window: saved position"), "debug names the saved position")
end
```

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k questQuestieTracker`
Expected: FAIL, `ASSERT: beside a right-hand tracker, on its left`.

- [ ] **Step 3: Implement**
  - `QuestieSupport.lua`: `trackerSide()` and the debug line.
  - `QuestGuide.lua`: `place()` computes a key (`"saved"`, `"questie-left"`, `"questie-right"`, `"default"`) from `db.questPosition` then `ns.questie.trackerSide()`, and only calls `ClearAllPoints`/`SetPoint` when the key differs from the last one applied (kept in a local `placedBy`). `OnDragStop` clears `placedBy` after saving, so the next `place()` re-applies the saved point relative to `UIParent`. `ns.questRefresh()` calls `place()` right after `if not viewer then makeViewer() end`. `ns.questViewerPlacement()` maps the key to the three strings.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k quests`
Expected: PASS, including `questLayout` and the persisted runs (`python tests/run.py -k persisted`).

- [ ] **Step 5: Commit**

```bash
git add QuestieSupport.lua QuestGuide.lua tests/scenarios.lua tests/run.py
git commit -m "Place the step window beside Questie's tracker"
```

### Task 3: QuestieDB access, setting and failure reasons

**Files:**
- Modify: `QuestieSupport.lua`
- Modify: `Window.lua` (after the "Show the quest arrow" tick)
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: Task 1 debug lines.
- Produces:
  - `ns.questie.usable() -> boolean, reason|nil`. Not installed (`LibQuestieDB` not a table): `false, "not installed"`, never cached. Otherwise the result is cached per `LibQuestieDB` table: `RequireContract(1)` must return true (else `"contract check failed"`); `Support.Get("ZoneDB").private.areaIdToUiMapId` must compile to a non-empty AreaId -> UiMapID table (else `"no zone table"`). Each source string: `loadstring`, `setfenv(fn, {})`, `pcall(fn)`; keep only number keys with number values; `areaIdToUiMapIdOverride` (optional) wins; a value of `0` drops the area.
  - `ns.questie.mapFor(areaId) -> uiMapId|nil` (zone table lookup; Task 4 uses it).
  - `ns.questie.disable(reason)`: turns QuestieDB use off for this `LibQuestieDB` table with that reason (Task 4 uses it for read errors).
  - Debug line: `"QuestieDB: not installed"`, `"QuestieDB: off (<reason>)"`, or `"QuestieDB: contract <contractVersion> (<readMode>), <n> zone maps, arrow: <state>"` (state from Task 4; `"waiting"` until then).
- Test mock produced: `MOCK.makeQuestieDB(opts)` sets `LibQuestieDB` to a new table on every call (so the per-table cache re-checks) with `contractVersion = opts.contract or 4`, `readMode = "baked"`, `RequireContract(n)` true when `1 <= n <= contractVersion`; entity tables `Quest.objectives(id)` (`opts.quests[id].objectives`), `Npc.name`/`Npc.spawns`, `Object.name`/`Object.spawns`, `Item.name`/`Item.npcDrops`/`Item.objectDrops` from `opts.npcs`, `opts.objects`, `opts.items` (unknown id: nil); every entity getter raises `"mock read error"` while `MOCK.questieDBError` is true; `Support.Get("ZoneDB")` returns `{ private = { areaIdToUiMapId = opts.zones or "return { [12] = 1429, [40] = 1436 }", areaIdToUiMapIdOverride = "return { [0] = 0 }" } }`, or nil with `opts.noZones`.

- [ ] **Step 1: Add `MOCK.makeQuestieDB`** to `tests/wowmock.lua`.

- [ ] **Step 2: Write the failing scenarios** and register them in `tests/run.py`: `"questQuestieDB"` in the WARRIOR full list, and in the minimal branch `runs.append(("WARRIOR/minimal/questie", "WARRIOR", True, ["questQuestieMinimal"]))`. Put the shared fixture before both.

```lua
local function koboldDB(opts)
  opts = opts or {}
  MOCK.makeQuestieDB({
    contract = opts.contract, noZones = opts.noZones,
    quests = { [7] = { objectives = opts.objectives or { [1] = { { 6, nil, 0 }, { 257, nil, 0 }, { 999, nil, 0 } } } } },
    npcs = {
      [6] = { name = "Kobold Vermin", spawns = {
        [12] = { { 50.0, 38.0 }, { 47.0, 34.0 }, { 48.9, 40.6, 5 }, { 48.8, 54.0 } },
        [40] = { { 48.8, 44.0 } } } },
      [257] = { name = "Kobold Worker", spawns = { [12] = { { 44.0, 36.4 } } } },
      [999] = { name = "Ghost" },
    },
    objects = opts.objects, items = opts.items,
  })
end

function S.questQuestieDB()
  S.login()
  slash("quests")
  click(win(), "Settings")
  check(not questText(win(), "Point the arrow at the nearest objective (QuestieDB)"), "no setting without QuestieDB")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Questie: not loaded") and chatHas("QuestieDB: not installed"), "debug names what is missing")
  koboldDB({ contract = 0 })
  MOCK.chat = {}
  slash("debug")
  check(chatHas("QuestieDB: off %(contract check failed%)"), "an incompatible QuestieDB is refused")
  koboldDB({ noZones = true })
  MOCK.chat = {}
  slash("debug")
  check(chatHas("QuestieDB: off %(no zone table%)"), "QuestieDB without its zone table is refused")
  koboldDB()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("QuestieDB: contract 4 %(baked%), 2 zone maps, arrow: "), "a usable QuestieDB is reported")
  click(win(), "Settings")
  check(questText(win(), "Point the arrow at the nearest objective (QuestieDB)"), "the setting shows with QuestieDB")
end

function S.questQuestieMinimal()
  MOCK.makeQuestie({ autoAccept = true })
  koboldDB()
  S.login()
  slash("quests")
  click(win(), "Settings")
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("QUEST_DETAIL")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Questie: loaded") and chatHas("QuestieDB: contract 4"), "the Questie block works on a minimal client")
end
```

- [ ] **Step 3: Run them and see them fail**

Run: `python tests/run.py -k questie`
Expected: FAIL in `questQuestieDB` (`debug names what is missing`); `questQuestieMinimal` fails on `QuestieDB: contract 4`.

- [ ] **Step 4: Implement** `usable`, `mapFor`, `disable`, the debug line, and in `Window.lua` (only while `ns.questie.usable()`):
  `tick("Point the arrow at the nearest objective (QuestieDB)", not db.noNearestSpawn, function() db.noNearestSpawn = not db.noNearestSpawn; ns.questRefresh() end, "Near a kill or collect step's camp, the arrow leads to the closest mob or object you still need. The spawns come from your QuestieDB addon.")`

- [ ] **Step 5: Run them and see them pass**

Run: `python tests/run.py -k questie`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add QuestieSupport.lua Window.lua tests/wowmock.lua tests/scenarios.lua tests/run.py
git commit -m "Read QuestieDB through LibQuestieDB with contract and zone checks"
```

### Task 4: Last-mile arrow

**Files:**
- Modify: `QuestieSupport.lua`
- Modify: `QuestGuide.lua:157-189` (`paintArrow`)
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: `ns.questie.usable()`, `ns.questie.mapFor(areaId)`, `ns.questie.disable(reason)` (Task 3); `Q.vector(step, map, x, y)`, `Q.log(id)` (entry `{ objectives = { { text, finished } }, ready }`), `Q.arrived()`, `ns.quests` (Quests.lua).
- Produces: `ns.questie.nearest(step, map, x, y) -> spawn|nil, name|nil`, `spawn = { map = step.map, x = number, y = number }`, and the debug arrow state.

- [ ] **Step 1: Write the failing scenarios** and add `"questQuestieNearest"`, `"questQuestieNearestItem"`, `"questQuestieNearestPart"`, `"questQuestieNearestError"` to the WARRIOR full list.

```lua
local function koboldCamp(objectives, x, y)
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = objectives } }
  MOCK.questMap, MOCK.questX, MOCK.questY = 1429, x, y
  S.login()
end

local function moveTo(x, y)
  MOCK.questX, MOCK.questY = x, y
  MOCK.advance(0.25)
end

function S.questQuestieNearest()
  koboldDB()
  local vermin = { text = "Kobold Vermin 4/10", finished = false }
  koboldCamp({ vermin }, 48.8, 50.0)
  local arrow = LevelingCodexQuestArrow
  local art = arrow:GetRegions()
  check(questText(arrow, "315 yd") and not questText(arrow, "Kobold Vermin"), "outside the camp the arrow leads to the camp")
  moveTo(48.8, 44.0)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "inside the camp: the nearest unphased spawn on this map")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("arrow: inside the camp, 2 spawns, nearest Kobold Vermin"), "debug reports the candidates")
  moveTo(48.8, 48.0)
  check(questText(arrow, "Kobold Vermin - 235 yd"), "still inside before CAMP_LEAVE; spawns past SPAWN_RANGE ignored")
  moveTo(48.8, 50.0)
  check(questText(arrow, "315 yd"), "leaving the camp returns to the camp point")
  moveTo(48.8, 48.0)
  check(questText(arrow, "268 yd"), "no re-entry before CAMP_ENTER")
  moveTo(50.0, 38.5)
  check(questText(arrow, "Kobold Vermin nearby") and not art:IsShown(), "next to a spawn: nearby, no arrow art")
  moveTo(48.8, 44.0)
  LevelingCodexDB.noNearestSpawn = true
  MOCK.advance(0.25)
  check(questText(arrow, "176 yd") and not questText(arrow, "Kobold Vermin"), "the setting turns it off")
  LevelingCodexDB.noNearestSpawn = nil
  local worker = { text = "Kobold Worker 0/5", finished = false }
  MOCK.questLog = { { questID = 7, objectives = { vermin, worker } } }
  MOCK.event("QUEST_LOG_UPDATE")
  moveTo(48.8, 44.0)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "two objectives: the nearest of both")
  vermin.text, vermin.finished = "Kobold Vermin 10/10", true
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  check(questText(arrow, "Kobold Worker - 242 yd"), "a finished objective drops its spawns")
  MOCK.questLog = { { questID = 7, objectives = { { text = "Gnoll Pelt 0/5", finished = false } } } }
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "no name match: every objective counts, spawnless ones skipped")
  MOCK.questDone[7], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 7)
  MOCK.advance(0.25)
  check(not questText(arrow, "Kobold Vermin"), "a new step drops the old nearest target")
end

function S.questQuestieNearestItem()
  koboldDB({
    objectives = { [3] = { { 1001, nil, 0 } } },
    items = { [1001] = { name = "Large Candle", npcDrops = { 6 }, objectDrops = { 50 } } },
    objects = { [50] = { name = "Candle Box", spawns = { [12] = { { 47.5, 42.0 } } } } },
  })
  koboldCamp({ { text = "Large Candle: 2/8", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "Candle Box - 65 yd"), "item objectives lead to whatever drops them")
  moveTo(47.5, 42.5)
  check(questText(arrow, "Candle Box nearby"), "nearby an item source")
end

function S.questQuestieNearestPart()
  MOCK.makeQuestieDB({
    quests = { [92745] = { objectives = { [1] = { { 1101, nil, 0 }, { 1102, nil, 0 } } } } },
    npcs = {
      [1101] = { name = "Kobold Digger", spawns = { [40] = { { 46.5, 22.0 } } } },
      [1102] = { name = "Riverpaw Miner", spawns = { [40] = { { 45.3, 22.5 } } } },
    },
  })
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 15, 1436, 45.3, 22.0
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "westfall" then
      for _, step in ipairs(section.steps) do
        if step.quest == 92745 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 92745, objectives = {
    { text = "Kobold Diggers 0/4", finished = false }, { text = "Riverpaw Miners 0/6", finished = false } } } }
  S.login()
  slash("quests")
  click(win(), "Resume active quest")
  MOCK.advance(0.25)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "Kobold Digger - 42 yd") and not questText(arrow, "Riverpaw"),
    "an objective-part step only uses its own objective")
end

function S.questQuestieNearestError()
  koboldDB()
  MOCK.questieDBError = true
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "176 yd") and not questText(arrow, "Kobold Vermin"), "a read error keeps today's arrow")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("QuestieDB: off %(read failed"), "debug names the read error")
  MOCK.questieDBError = false
  MOCK.advance(0.25)
  check(questText(arrow, "176 yd"), "no retry in the same session")
end
```

- [ ] **Step 2: Run them and see them fail**

Run: `python tests/run.py -k questQuestieNearest`
Expected: FAIL, `ASSERT: inside the camp: the nearest unphased spawn on this map` (and the item/part equivalents); `questQuestieNearestError` fails on `debug names the read error`.

- [ ] **Step 3: Implement `ns.questie.nearest(step, map, x, y)` in `QuestieSupport.lua`**

Returns nil (state recorded for debug) unless: `usable()`; `not ns.db().noNearestSpawn` (state `"setting off"`); `step.type == "complete"` with `quest`, `map`, `x`, `y`; `map == step.map`; `Q.log(step.quest)` exists and is not `ready`. Camp state: module locals `campStep`, `inCamp`; a different `step` table resets `inCamp = false`; distance to the step from `ns.quests.vector(step, map, x, y)`; enter at `<= CAMP_ENTER`, leave at `> CAMP_LEAVE` (state `"outside the camp"`).

Candidates, rebuilt only when `step` or the set of unfinished log objective indices changes (cache key: `tostring(step) .. ":" .. table.concat(unfinished, ",")`), inside `pcall`; on error call `disable("read failed: " .. message)` (message cut to 80 characters) and return nil:

1. Needed: the log entry's objectives whose `finished` is neither `true` nor `1`; with `step.objectiveIndex`, only that index.
2. Entries from `LibQuestieDB.Quest.objectives(quest)` (nil or non-table: no candidates): group 1 `{ npcId, text }` -> name `text or Npc.name(npcId)`, sources `{ npc npcId }`; group 2 `{ objectId, text }` -> `Object.name`, `{ object objectId }`; group 3 `{ itemId, text }` -> `Item.name`, sources every `Item.npcDrops` npc and `Item.objectDrops` object; group 5 `{ npcIds, baseNpcId, text }` -> `Npc.name(baseNpcId)`, sources every id in `npcIds`. Groups 4 and 6 are skipped.
3. An entry is needed when its lower-cased `ns.plain` name is found (plain `string.find`) in a needed objective's lower-cased `ns.plain` text. If any needed objective matches no entry, every entry counts.
4. For each source: `spawns = Npc.spawns(id)` or `Object.spawns(id)`; skip non-tables; keep coordinates of areas where `ns.questie.mapFor(areaId) == step.map`; drop tuples with a non-zero third element unless the source has no unphased tuple on this map; keep those within `SPAWN_RANGE` of the step (`ns.quests.vector(step, step.map, sx, sy)`). Each kept spawn carries its source's `ns.plain` name.

Inside the camp, return the candidate nearest the player (`ns.quests.vector(candidate, map, x, y)`); state `"inside the camp, <n> spawns, nearest <name>"`, or `"inside the camp, no spawns"` returning nil.

- [ ] **Step 4: Use it in `paintArrow`** (`QuestGuide.lua`): after `Q.destination`, when `step == goal`, call `ns.questie.nearest(goal, map, x, y)`. With a result: `Q.vector(spawn, map, x, y)`; within `Q.arrived()` set the text `name .. " nearby"` with the art hidden; otherwise draw the arrow with the caption `name .. " - " .. math.floor(yards + 0.5) .. " yd"`. Without a result, the existing code runs unchanged.

- [ ] **Step 5: Run them and see them pass**

Run: `python tests/run.py -k questQuestie` then `python tests/run.py -k quests`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add QuestieSupport.lua QuestGuide.lua tests/scenarios.lua tests/run.py
git commit -m "Lead the arrow to the nearest objective spawn from QuestieDB"
```

### Task 5: Docs, full harness and install

**Files:**
- Modify: `CLAUDE.md` (Files table and module list: `QuestieSupport.lua` after `Quests.lua` with its functions; Tests: `MOCK.makeQuestie`, `MOCK.makeQuestieDB`, `MOCK.shift`/`MOCK.ctrl`, `MOCK.questieDBError`, `-k questie`)
- Modify: `CHANGELOG.md` (new top section `## Unreleased` -> `### Questie compatibility`: auto-questing defers to Questie's, Questie's key holds the Codex back and Alt now also stops the quest window, the step window sits beside Questie's tracker, the last-mile arrow with QuestieDB and its setting)
- Modify: `README.md`, `CURSEFORGE_DESCRIPTION.md` (one line each: works with Questie; with QuestieDB installed the arrow finds the nearest objective once you reach a camp)

- [ ] **Step 1: Write the docs** listed above.

- [ ] **Step 2: Run the full harness**

Run: `python tests/run.py`
Expected: every run PASS, no Lua errors, no non-ASCII runtime text, no leaked globals, both .toc files identical.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md CHANGELOG.md README.md CURSEFORGE_DESCRIPTION.md
git commit -m "Document Questie compatibility"
```

- [ ] **Step 4: Install into the game** after checking the installed build: compare `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\LevelingCodex\LevelingCodex.toc` `## Version` and its `.lua` list with this checkout; if the installed build is newer than this branch's base (`v0.18.0`), stop and tell the owner. Then run `python tools/install.py`.
Expected: every file copied and verified; the owner restarts the client (the .toc changed).
