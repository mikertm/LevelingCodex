# Polish Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Act on the owner's in-game feedback: a minimap line through known waypoints with no second line and no double edge arrow, one step-based progress measure, a readable Quests tab, accurate pace figures and a visual Stats tab.

**Architecture:** Each phase changes one area: QuestMap.lua (+ small Quests/QuestGuide accessors) for the minimap; Quests.lua, QuestGuide.lua and QuestTab.lua for progress and the Quests tab, with two new drawing helpers in Window.lua/Art.lua; Stats.lua becomes the single source of per-level figures that Pace.lua and the This Level card read; the Stats tab is redrawn from the same records.

**Tech Stack:** WoW: Forever add-on (Interface 16001, Lua 5.1); tests in `tests/` (Python + lupa, `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`).

**Spec:** `docs/superpowers/specs/2026-11-13-polish-pass-design.md`

## Global Constraints

- Lua 5.1; runtime text ASCII only (no tick or arrow characters: textures or ASCII); colour codes (`|cffRRGGBB...|r`) are ASCII and allowed.
- No new globals beyond `LevelingCodex*` frames; `pcall` every non-core `RegisterEvent`; guard every non-core API; probe art with `ns.art.hasFile` and fall back to flat colour.
- Everything works with empty SavedVariables (`ns.settingsLost`) and in the minimal mock client.
- Every clickable keeps a `codexLabel` (the harness's `findButton`/`click` and controller navigation use it); pooled widgets must reset any field they set.
- Keep the guide's look: Codex cards, Morpheus headings, Forever teal theme, Blizzard pieces where they exist.
- Test commands: `python tests/run.py -k <filter>` (substring of the run name, case-sensitive); full suite `python tests/run.py` (2.5-7.5 min here; `WARRIOR/full/blocked-report` fails in every worktree and is not a regression).
- Install after the final harness: check the installed version's commit is an ancestor of HEAD, then `python tools/install.py`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. Lost SavedVariables: the This Level card and the Stats tab must say they count from login and hide the session/character switch, not show empty "This character" figures. (Task 7 `paceCardLost`, Task 8 `statsTabLost`.)
2. A level record with zero time and zero XP (just created) must draw its split row and pace card without dividing by zero. (Task 8 `statsTab` seeds one; Task 7 `paceCard` views a level with an empty record.)
3. The minimal client (no textures, no `SetMouseClickEnabled`, no `C_Map` waypoint): segments, rows, fold headers and bars draw from flat colour and text; the minimap shows its own edge arrow because no game waypoint exists. (Tasks 3-5 and 8 run their scenarios in minimal too, or check the minimal branch.)
4. Long guide titles ("Stranglethorn Early: Rebel Camp and Nesingwary") must stay on one line inside their row, clear of the range and tag. (Task 5 `guideRowsLong`.)
5. A way-in path whose next point is on the continent map or another zone map: the chain skips segments it can't measure instead of erroring. (Task 2 `minimapPath` walks onto the continent map.)

---

### Task 1: One progress measure (steps)

**Files:**
- Modify: `Quests.lua:1083-1118` (`Q.sectionProgress`, new `Q.turninProgress`, `Q.sectionStatus`)
- Modify: `QuestGuide.lua:222-232` (the step bar's tooltip)
- Test: `tests/scenarios.lua` (`S.stepProgress`, `S.questGrey`'s band check)

**Interfaces:**
- Produces: `Q.sectionProgress(section) -> passed, total` (steps, same as `Q.stepProgress`); `Q.turninProgress(section) -> done, total` (the old turn-in count); `Q.sectionStatus(section, suggested) -> status, passed, total` with "done" = `total > 0 and passed == total`.

- [ ] **Step 1: Write the failing test** — in `S.stepProgress`, replace the hover check with:

```lua
  MOCK.fire(bar, "OnEnter")
  local l = GameTooltip._lines
  check(l[1] and l[1]:find(" steps done (", 1, true) and l[2] and l[2]:find(" quests turned in", 1, true)
    and l[3] == "Click to see the route.", "the tooltip counts steps, then turn-ins: " .. tostring(l[1]))
  MOCK.fire(bar, "OnLeave")
  local pct = MOCK.textUnder(bar):match("(%d+)%%")
  click(win(), "Guides")
  check(pct and questText(win(), pct .. "% done"), "the guide list shows the bar's percentage")
```
(`click(win(), "Guides")` needs the window open: `bar:Click()` earlier in the scenario opens it; move these lines after that click.)

- [ ] **Step 2: Run it to make sure it fails** — `python tests/run.py -k stepProgress`. Expected: FAIL on "the tooltip counts steps".
- [ ] **Step 3: Implement** the three functions above and the tooltip lines `"<Guide>: N of M steps done (P%)"`, `"T of U quests turned in"`, `"Click to see the route."` (`<Guide>` as today: the short name).
- [ ] **Step 4: Run** `python tests/run.py -k stepProgress` and `-k questGrey` and `-k questTab`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Progress counts steps everywhere; the bar's tooltip adds turn-ins"`.

### Task 2: The minimap line through known waypoints, no second line

**Files:**
- Modify: `Quests.lua` (new `Q.pathRest` after `pathWaypoint`, ~line 1470)
- Modify: `QuestMap.lua` (minimap section: chain, bends, remove `pins.ahead`)
- Test: `tests/scenarios.lua` (`S.minimapRoute`, new `S.minimapPath`), `tests/run.py` (add `"minimapPath"` to the quest scenario list after `"minimapRoute"`)

**Interfaces:**
- Consumes: `ns.questArrowGoal()` (exists).
- Produces: `Q.pathRest(step) -> { spot... }`: the step's path points after the one `Q.waypoint(step)` last returned (`pointAt[step]`), each `{ map = p[3] or step.map, x, y, world = true }`, then `step` itself; `{}` when the step has no path or you're past it. `pins.bends` (pool of 5 px textures).

- [ ] **Step 1: Write the failing tests** — in `S.minimapRoute` replace the two "dots go on past the current step" checks with `check(pins.ahead == nil, "no second line")` and keep `#line > 0`. Add:

```lua
-- Minimap: the line bends through a step's way-in points to the step itself.
function S.minimapPath()
  -- the questEntrancePath step: tunnel points (48, 43) and (50, 45), the cave at (52, 47)
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 1, { type = "goto", text = "Go down the tunnel to the cave.", map = 1429,
    x = 52, y = 47, path = { { 48, 43 }, { 50, 45 } } })
  MOCK.questX, MOCK.questY, MOCK.viewRadius = 44, 41, 400
  S.login()
  if MOCK.minimal then return end
  local pins = _G.LevelingCodexMinimapPins
  MOCK.advance(0.5)
  local function shown(list) local n = 0; for _, t in ipairs(list) do if t:IsShown() then n = n + 1 end end; return n end
  check(shown(pins.bends) == 2, "a bend dot at the second tunnel point and at the cave")
  local _, _, _, px, py = pins.current:GetPoint()
  local far = 0
  for _, d in ipairs(pins.dots) do
    if d:IsShown() then local _, _, _, x, y = d:GetPoint(); far = math.max(far, math.sqrt(x * x + y * y)) end
  end
  check(far > math.sqrt(px * px + py * py) + 5, "dots go on past the pin, through the tunnel")
  MOCK.questX, MOCK.questY = 48, 43
  MOCK.advance(0.5)
  check(shown(pins.bends) == 1, "past the first point, one bend is left")
  MOCK.questMap, MOCK.questX, MOCK.questY = 1415, 46.02, 70.09 -- on the continent map
  MOCK.advance(0.5) -- an error in the minimap's OnUpdate fails the scenario here
end
```

- [ ] **Step 2: Run** `python tests/run.py -k minimap`. Expected: FAIL ("no second line", "a bend dot ...").
- [ ] **Step 3: Implement** `Q.pathRest`; in QuestMap: remove `AHEAD`, `AHEAD_ALPHA`, `pins.ahead` and the ahead loop; build `chain = { goal.spot }` plus `Q.pathRest(goal.step)` when `goal.kind == "step"` and the goal spot is a path point (`goal.spot.world` and `goal.step.path`); dots from you to the pin, then along each chain segment (skip a segment whose ends `screen()` can't place); a bend texture (5 px gold, alpha 1, `ARTWORK` above the dots, pool of 6) at every chain point after the first that is inside 95% of the radius; arrival (no dots) only when `#chain == 1`, else keep dots from the goal on. Add the chain's points to the layout key.
- [ ] **Step 4: Run** `python tests/run.py -k minimap` and `-k questEntrancePath`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Minimap line bends through way-in points; the second line is gone"`.

### Task 3: No double edge arrow

**Files:**
- Modify: `QuestGuide.lua` (`updateMapPin` area: new `ns.questMapPinSpot`)
- Modify: `QuestMap.lua` (`layout`: hide `pins.edge`)
- Test: `tests/scenarios.lua` (`S.minimapPins` edge block)

**Interfaces:**
- Produces: `ns.questMapPinSpot() -> { map, x, y } | nil` (0-1 coordinates of the user waypoint the Codex set, only while `userWaypoint()` still matches it).

- [ ] **Step 1: Write the failing test** — in `S.minimapPins`, before the existing edge checks:

```lua
  MOCK.questY = 60 -- 394 yd south of Willem: off the minimap, no trip
  MOCK.advance(0.2)
  check(not pins.edge:IsShown() and not pins.current:IsShown() and dots() > 0,
    "the game's own waypoint arrow marks the rim, so ours stays off; the dots still run there")
  LevelingCodexDB.noQuestMapPin = true
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.2)
  check(pins.edge:IsShown(), "without the map pin, our edge arrow shows")
```
then keep the existing `questY = 80` rim checks (they now run with `noQuestMapPin` on) and set `LevelingCodexDB.noQuestMapPin = nil` before "no usable scale".

- [ ] **Step 2: Run** `python tests/run.py -k minimapPins`. Expected: FAIL on "the game's own waypoint arrow".
- [ ] **Step 3: Implement** `ns.questMapPinSpot` (return a copy of `pinned` when `userWaypoint()` matches it, else nil) and in `layout`: when `out` and `goal.kind == "step"` and the pin spot equals the goal (`map` equal, `|x - spot.x / 100| <= 0.0001`, same for y), show neither `pins.edge` nor `pins.current`; dots unchanged.
- [ ] **Step 4: Run** `python tests/run.py -k minimap` and `-k questMapPin`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Minimap: our edge arrow gives way to the game's waypoint arrow"`.

### Task 4: Segments and the setup card

**Files:**
- Modify: `Art.lua` (new `A.segment(parent)`, near `A.button`)
- Modify: `Window.lua` (new `U.segments`; export in `ns.ui`)
- Modify: `QuestTab.lua:497-533` (`renderSetup`; new local `dungeonState()`)
- Test: `tests/scenarios.lua` (`S.questSetup`)

**Interfaces:**
- Produces: `A.segment(parent) -> Button` with `SetLabel(s)`, `SetLook(on)`; `U.segments(x, y, w, labels, lit, onPick, tips) -> 24` (height): one pooled segment per label, gap 4 px, equal widths; each gets `codexLabel = label`, `codexOn = (i == lit)`, OnClick `onPick(i)`, tooltip `tips and tips[i]`. `dungeonState() -> "recommended" | "all" | "none" | "picks", plannedCount`.

`A.segment` look: built on `A.button` (the red panel button; flat fallback as `A.button` does). Lit: alpha 1, `LockHighlight`, gold label (1, 0.82, 0), four 1 px gold inner-edge textures shown, and a 14 px tick texture `Interface\Buttons\UI-CheckBox-Check` at LEFT +4 (probed with `A.hasFile`; hidden when missing). Unlit: button alpha 0.6, `UnlockHighlight`, label (0.75, 0.75, 0.75), edges and tick hidden.

- [ ] **Step 1: Write the failing test** — extend `S.questSetup` after `click(frame, "Set up the guide")`:

```lua
  local function seg(name) return findButton(win(), function(l) return l == name end) end
  check(seg("Fastest").codexOn and not seg("Every quest").codexOn, "a fresh setup lights Fastest")
  check(seg("Recommended") and seg("All") and seg("None"), "dungeons are three choices")
  click(win(), "None")
  check(seg("None").codexOn and not seg("Recommended").codexOn, "None lights once nothing is planned")
  click(win(), "Recommended")
  check(seg("Recommended").codexOn, "Recommended lights the recommended plan")
  LevelingCodexDB.questKeepGrey, LevelingCodexDB.questOptional = true, false
  slash("quests")
  check(not seg("Fastest").codexOn and not seg("Every quest").codexOn and questText(win(), "Custom: see Settings"),
    "a mixed pace lights neither and says so")
  local accept = seg("Auto-accept")
  check(accept and accept.GetChecked and not accept:GetChecked(), "helpers are check boxes")
```
(keep the scenario's later `click(win(), "Every quest")` / `"Auto-accept"` / `"Fastest"` checks; add `check(accept:GetChecked(), ...)` after the Auto-accept click.) Also add a "Your picks" check: set `LevelingCodexDB.questDungeonPlan = { ["dungeon-deadmines"] = true }` with `questDungeons` off and a level where Deadmines isn't recommended (Human level 5 at login: recommended runs are empty), `slash("quests")`, then `check(seg("Your picks (1)") and seg("Your picks (1)").codexOn, "a hand-made plan shows as your picks")`.

- [ ] **Step 2: Run** `python tests/run.py -k questSetup`. Expected: FAIL on "a fresh setup lights Fastest".
- [ ] **Step 3: Implement** `A.segment`, `U.segments`, `dungeonState()` (all = `db.questDungeons`; none = no `Q.planned(id)` among `Q.dungeons()` and not all; recommended = the planned set equals `Q.recommendedRuns()`; else picks with the planned count) and the card's three rows (label column 92 px, "Pace", "Dungeons", "Helpers"; segments from x = 108; the picks segment appended only for "picks"; the Custom note under the Pace row; helpers as `U.check` at x = 108, 108 + 150, 108 + 300) and the Done button.
- [ ] **Step 4: Run** `python tests/run.py -k questSetup` and `-k quest` (the whole quest list). Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Quests tab setup: lit choices and check boxes"`.

### Task 5: Guide rows, fold headers and dungeon choices

**Files:**
- Modify: `Window.lua` (`hit`: optional 8th parameter `label` sets `hb.codexLabel`, nil clears it; new `U.fold(open, x, y)` drawing `Interface\Buttons\UI-PlusButton-Up` / `UI-MinusButton-Up` 16 px, probed, else a "+"/"-" font string)
- Modify: `QuestTab.lua` (`guideButtons` -> `guideRows`, band headers, the dungeon plan buttons -> `U.segments`, dungeon and special rows)
- Test: `tests/scenarios.lua` (`S.questGrey` band check, the two `"Plan recommended"` checks at ~977 and ~3019, new `S.guideRowsLong`), `tests/run.py` (add `"guideRowsLong"`)

**Interfaces:**
- Consumes: `Q.sectionStatus` (Task 1), `U.segments`, `dungeonState()` (Task 4).
- Produces: guide rows as `U.hit` strips with `codexLabel = section.title`; band rows with `codexLabel` in today's format (`"+ LEVELS 20-30: 8 guides, 1 done"` / `"- ..."`).

Row layout (36 px, full width W): left edge 3 px (gold current, `C.accent` suggested); current wash `C.accent` at alpha 0.12; title at x 12, width `W - 200`, one line (`SetWordWrap(false)` on the returned font string), gold / `C.light` / `C.dim` by status; range "Levels a-b" right-aligned in `[W - 186, W - 96]`; tag plate in `[W - 90, W - 6]` with the text Current / Suggested / Side / Later / Done / Outleveled and `" N%"` for Current, Side and Later when N > 0; progress track 4 px at y + 22 from x 12 to `W - 200` (dark `{0.14, 0.21, 0.23, 1}`, fill `C.accent`). Click does what the button did (`Q.jump(section)`, show the viewer); tooltip "Follow this section in the step window.". Dungeon rows: tag Planned / Not planned, click as today; special quest chains and Class quests use the same rows (tag by their status as for guides). Band header: `U.fold` at x 0, "LEVELS a-b" in gold at x 22, "N guides, M done" in `C.dim` after it, a `U.hit` over the row (24 px) with the label.

- [ ] **Step 1: Write the failing tests** — in `S.stepProgress` change Task 1's guide-list check to `questText(win(), "Current " .. pct .. "%") or (pct == "0" and questText(win(), "Current"))`; in `S.questGrey` replace `questText(win(), "0% done")` with `questText(win(), "Current")` and add `check(not findButton(win(), function(l) return l:find("% done", 1, true) end), "guides are rows, not buttons")`; change the two `"Plan recommended"` lookups to `"Recommended"`; add:

```lua
-- A long guide title stays on one line inside its row.
function S.guideRowsLong()
  MOCK.race, MOCK.level = "Human", 32
  S.login()
  slash("quests")
  local title = "Stranglethorn Early: Rebel Camp and Nesingwary"
  local row = guideButton(title)
  check(row and row._type == "Button" and not row.SetLook, "a guide is a row, not a panel button")
  local function find(f)
    for _, r in ipairs({ f:GetRegions() }) do if r._text == title and r:IsShown() then return r end end
    for _, c in ipairs({ f:GetChildren() }) do local hit = c:IsShown() and find(c); if hit then return hit end end
  end
  local fs = find(win())
  check(fs and fs:GetWidth() <= row:GetWidth() - 190, "the title keeps clear of the range and the tag")
end
```
(The rows' `U.hit` strip is the full row width W, so `row:GetWidth() - 190` is the space left of the range.)

Also add minimal runs so the flat fallbacks are drawn: `("WARRIOR/minimal/quests-setup", "WARRIOR", True, ["questSetup"])` and `("WARRIOR/minimal/guide-rows", "WARRIOR", True, ["guideRowsLong"])` next to the stats runs; where a check needs an API the minimal client lacks, guard that check with `MOCK.minimal`, not the drawing.

- [ ] **Step 2: Run** `python tests/run.py -k questGrey` and `-k guideRowsLong`. Expected: FAIL.
- [ ] **Step 3: Implement** the rows, headers and the dungeon segments as above.
- [ ] **Step 4: Run** `python tests/run.py -k quest` (all quest scenarios, including `guideButton`/`clickGuide` users) and `-k pad`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Quests tab: guides as rows with progress, folding level bands"`.

### Task 6: Pace data you can trust

**Files:**
- Modify: `Pace.lua` (kill pattern, `ns.paceRate`, `ns.paceDebugLines`)
- Modify: `Stats.lua` (`levelOf`: `fromPct`; new `S.levelRecord`, `S.earlierLevels`)
- Modify: `Init.lua:223-227` (add `ns.paceDebugLines()`)
- Modify: `Theme.lua` (new `ns.thousands(n)`)
- Test: `tests/scenarios.lua` (new `S.paceKills`, `S.statsFromPct`), `tests/run.py` (stats runs, both variants)

**Interfaces:**
- Produces: `ns.paceRate() -> xpPerHour | nil` (session XP / session hours; nil before any gain); `ns.paceDebugLines() -> { "pace: last XP line \"...\" -> kill N XP" | "... -> not counted" | "pace: no XP line yet" }`; `S.levelRecord(lvl) -> record | nil` (the saved tree's, or the session's with `ns.settingsLost`; never creates); `S.earlierLevels(lvl, n) -> { { level, record }... }` (up to n records below lvl, newest first); record field `fromPct` (whole percent, only when > 2); `ns.thousands(n) -> "21,400"`.

Kill pattern (built at the first XP line and cached, so a client string set before login is used): from `COMBATLOG_XPGAIN_FIRSTPERSON` when it's a string: escape Lua magic characters except `%`, then `%s` (and `%1$s`) -> `(.+)`, `%d` (and `%2$d`) -> `([%d,%.]+)`, not anchored at the end; else `"(.+) dies, you gain ([%d,%.]+) experience"`. The number drops `,` and `.` before `tonumber`. A line that doesn't match is not a kill.

- [ ] **Step 1: Write the failing tests:**

```lua
-- Pace: kill XP lines with rested or group text and in the client's own words; the debug line.
function S.paceKills()
  S.login()
  if MOCK.minimal then return end
  local st, lvl = LevelingCodexCharDB.stats, MOCK.level
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Vermin dies, you gain 1,250 experience. (+625 exp Rested bonus)")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Worker dies, you gain 40 experience. (+8 exp Group bonus)")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "You gain 300 experience.")
  check(st.levels[lvl].killXP == 1290 and st.levels[lvl].kills == 2, "rested and group lines count, a plain gain doesn't")
  MOCK.chat = {}
  slash("debug")
  check(chatHas('pace: last XP line "You gain 300 experience." %-> not counted'), "debug names the last XP line")
end

-- Pace: the kill line in another client language.
function S.paceKillsLocale()
  COMBATLOG_XPGAIN_FIRSTPERSON = "%s stirbt, Ihr bekommt %d Erfahrung."
  S.login()
  if MOCK.minimal then COMBATLOG_XPGAIN_FIRSTPERSON = nil; return end
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 75 Erfahrung.")
  local l = LevelingCodexCharDB.stats.levels[MOCK.level]
  COMBATLOG_XPGAIN_FIRSTPERSON = nil
  check(l.killXP == 75 and l.kills == 1, "the client's own wording counts")
end

-- Stats: a level first counted partway in remembers where counting began.
function S.statsFromPct()
  MOCK.level, MOCK.xp, MOCK.xpMax = 5, 400, 1000
  S.login()
  if MOCK.minimal then return end
  MOCK.advance(2)
  local st = LevelingCodexCharDB.stats
  check(st.levels[5].fromPct == 40, "level 5 counted from 40%")
  MOCK.level, MOCK.xp = 6, 0
  MOCK.event("PLAYER_LEVEL_UP", 6)
  MOCK.advance(2)
  check(st.levels[6] and st.levels[6].fromPct == nil, "a level seen from its start has no mark")
end
```
Add runs `("WARRIOR/%s/pace-kills" % variant, ..., ["paceKills", ...])` in both variants (each scenario in its own run: `paceKills`, `paceKillsLocale`, `statsFromPct`).

- [ ] **Step 2: Run** `python tests/run.py -k pace-kills` and `-k stats`. Expected: FAIL.
- [ ] **Step 3: Implement** the pattern, the last-line record (`{ text, n }`), `ns.paceRate`, `ns.paceDebugLines`, `fromPct` in `levelOf` (only when `lvl == level()` and the record is new: `math.floor(UnitXP / UnitXPMax * 100)`, kept when > 2), `S.levelRecord`, `S.earlierLevels`, `ns.thousands`.
- [ ] **Step 4: Run** `python tests/run.py -k pace` and `-k stats`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Pace: kills from the client's own wording, levels counted from partway in"`.

### Task 7: The This Level pace card

**Files:**
- Modify: `Window.lua:724-738` (the pace card)
- Modify: `Pace.lua` (remove `ns.paceRows`, `finishLevel`, the `level` counts and `charDB.paceLog` writing; keep session XP and the forwards to `ns.stats`)
- Test: `tests/scenarios.lua` (`S.paceCard` rewritten, new `S.paceCardLost`), `tests/run.py` (`paceCardLost` with `LOST`)

**Interfaces:**
- Consumes: `S.levelRecord`, `S.earlierLevels`, `ns.paceRate`, `ns.thousands` (Task 6); `ns.money`.

Card (shown level `lvl`; "current" = your own level):
- current: an XP bar (full width - 32, 12 px): track dark, XP fill (0.58, 0.31, 0.75) to `UnitXP / UnitXPMax`, rested (0.25, 0.4, 0.85) from there for `GetXPExhaustion` (capped at the end); above left `"Level 25: 21,400 / 34,000 XP"`, above right `"Level 26 in about 41 min"` (from `ns.paceRate()`; omitted without a rate).
- line: `"<duration> on this level (all sessions)"` (or `" (counted from N%)"` appended, or `"since you logged in"` instead of `"(all sessions)"` with `ns.settingsLost`), and for current `"<rate> XP per hour this session"` plus `", <rested> rested"` when rested > 0.
- chips: `"Quests <XP> XP, <n> turned in"`, `"Kills <XP> XP, <n> kills"` (`"1 kill"`), `"Other <XP> XP"` (xp - questXP - killXP, only when > 0), each with a 9 px colour square (0.88, 0.7, 0.29 / 0.77, 0.33, 0.29 / 0.36, 0.45, 0.46).
- "Last levels": up to 3 from `S.earlierLevels(lvl, 3)`: `"Level 24"`, a bar scaled to the longest of the three, `"1 h 24 min, 9 quests, 70 kills"` (`", 1 death"` when deaths > 0).
- a viewed level without a record: `"No stats for level N yet."`.

- [ ] **Step 1: Write the failing tests:**

```lua
function S.paceCard()
  MOCK.level, MOCK.xp, MOCK.xpMax, MOCK.rested = 5, 400, 1000, 150
  local function rec(seconds, xp, q, k, quests, kills)
    return { seconds = seconds, xp = xp, questXP = q, killXP = k, rested = 0, quests = quests, kills = kills, deaths = 0,
      goldIn = {}, goldOut = {} }
  end
  -- what an earlier session (or a /reload) saved
  LevelingCodexCharDB = { stats = { version = 1, zones = {}, totals = { goldIn = {}, goldOut = {} },
    levels = { [3] = rec(0, 0, 0, 0, 0, 0), [4] = rec(3900, 900, 600, 250, 4, 9), [5] = rec(1800, 300, 200, 100, 2, 3) } } }
  S.login()
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Vermin dies, you gain 50 experience.")
  MOCK.xp = 450
  MOCK.event("PLAYER_XP_UPDATE", "player")
  slash("")
  click(win(), "This Level")
  if MOCK.minimal then check(questText(win(), "YOUR PACE"), "the card shows without the XP calls"); return end
  check(questText(win(), "Level 5: 450 / 1,000 XP") and questText(win(), "Level 6 in about"), "the XP bar's figures")
  check(questText(win(), "30 min on this level (all sessions)"), "time on the level survives a reload")
  check(questText(win(), "Quests 200 XP, 2 turned in") and questText(win(), "Kills 150 XP, 4 kills"), "XP by source")
  check(questText(win(), "Level 4") and questText(win(), "1 h 5 min, 4 quests, 9 kills"), "the last levels")
  click(win(), "<")
  click(win(), "<")
  check(questText(win(), "0 min on this level"), "an empty record draws without dividing by zero")
  click(win(), "<")
  check(questText(win(), "No stats for level 2 yet."), "a level without stats says so")
end

function S.paceCardLost()
  slash("")
  click(win(), "This Level")
  check(questText(win(), "since you logged in"), "without saved data the card says what it counts")
end
```
(`S.paceCardLost` runs after `LOST`; the level arrows' codexLabels are "<" and ">".)

- [ ] **Step 2: Run** `python tests/run.py -k pace`. Expected: FAIL.
- [ ] **Step 3: Implement** the card; remove the old pace rows and log.
- [ ] **Step 4: Run** `python tests/run.py -k pace` and `-k lost` and `-k persisted`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "This Level: the pace card reads the saved stats, with an XP bar and last levels"`.

### Task 8: The Stats tab

**Files:**
- Modify: `Stats.lua` (the renderer)
- Modify: `Theme.lua` (new `ns.coins(copper)`: `ns.money` with each part in its coin colour: g `|cffffd100`, s `|cffc7c7cf`, c `|cffeda55f`, each closed with `|r`)
- Test: `tests/scenarios.lua` (`S.statsTab`, `S.statsTabLost`)

**Interfaces:**
- Consumes: `U.segments` (Task 4), `S.levelRecord` (Task 6), `ns.paceRate`, `ns.thousands`.

Layout, top to bottom (dark cards `U.box(..., C.panel, C.edge)`, headings in "label" style `C.gold`):
- header: `U.sectionTitle("Stats", 0)` and `U.segments(W - 260, 0, 260, { "This session", "This character" }, ...)` (character by default, a module-local remembered for the session); with `ns.settingsLost` no switch, the note `"Counting since you logged in: Forever didn't load your saved stats."`.
- four tiles (equal widths, gap 8, 58 px): `"Level N so far"` / duration / `"all sessions"`; `"XP per hour"` / `ns.thousands(rate)` or `"-"` / `"this session"`; `"Next level in"` / `"about <duration>"` or `"-"` / `"<XP> XP to go"`; `"Gold per hour"` / `ns.coins(net per hour)` (prefixed "-" when negative) / `"net, this session"`.
- Other XP everywhere (splits, tooltips, the pace card) is `math.max(0, xp - questXP - killXP)`: a turn-in's quest XP can be filed before its PLAYER_XP_UPDATE.
- LEVEL SPLITS (from the chosen tree): legend squares Quests / Kills / Other; per level (last 10, `Show all levels` button as today): label `"25 now"` or `"24"`, a stacked bar (length = seconds / longest shown, at least 2 px when seconds > 0; segments questXP, killXP, rest), duration at the right; a `U.hit` over the row (label `"Level N"`) whose tooltip lines are the duration, `"Quest XP n, kill XP n, other n"`, `"n quests, n kills, n deaths"`, `"Net gold <coins>"`, and `"Counted from N%"` when set.
- GOLD EARNED (+total) and GOLD SPENT (-total) side by side: a row per source with copper > 0 (names as today's `GOLD_NAMES`), a bar against that column's largest (gold `{0.88, 0.7, 0.29}` / red `{0.77, 0.33, 0.29}`), `ns.coins` at the right; `"Nothing yet."` for an empty column.
- ACTIVITY tiles, four per row: Quests, Kills, Deaths, Flights (`"Flights, <duration>"` label with time in the air), Hearthstone, Dungeon runs, Bosses, Played (`/played` total, or `"-"`).
- ZONES: top 8 (`Show all zones`), bar against the longest (`C.accent`), `"<duration>, N quests"` at the right.
- `Reset stats` as today.

- [ ] **Step 1: Write the failing tests** — rewrite `S.statsTab`:

```lua
function S.statsTab()
  MOCK.mapInfo, MOCK.money = STATS_MAPS, 1000 -- money known at login, so the reward's change is filed
  LevelingCodexCharDB = { stats = { version = 1, zones = {}, totals = { goldIn = {}, goldOut = {} },
    levels = { [MOCK.level + 1] = { seconds = 0, xp = 0, questXP = 0, killXP = 0, rested = 0, quests = 0, kills = 0,
      deaths = 0, goldIn = {}, goldOut = {} } } } } -- an empty record: drawn without dividing by zero
  S.login()
  MOCK.event("QUEST_TURNED_IN", 783, 120, 500)
  MOCK.setMoney(1500)
  MOCK.advance(2)
  slash("")
  click(win(), "Stats")
  for _, head in ipairs({ "LEVEL SPLITS", "GOLD EARNED", "GOLD SPENT", "ACTIVITY", "ZONES", "XP per hour",
      "Next level in", "Gold per hour" }) do
    check(questText(win(), head), "the Stats tab has " .. head)
  end
  local function seg(name) return findButton(win(), function(l) return l == name end) end
  if not MOCK.minimal then
    check(seg("This character") and seg("This character").codexOn, "the character's figures by default")
  end
  check(questText(win(), "Quest rewards") and not questText(win(), "Repairs"), "only sources that moved money")
  local split = findButton(win(), function(l) return l == "Level " .. MOCK.level end)
  check(split, "each level split is hoverable")
  MOCK.fire(split, "OnEnter")
  check(GameTooltip._lines and GameTooltip._lines[2] and GameTooltip._lines[2]:find("Quest XP 120", 1, true),
    "hovering a split gives its XP by source")
  MOCK.fire(split, "OnLeave")
  check(MOCK.minimal or questText(win(), "Elwynn Forest"), "zones show (the minimal client has no map API)")
  click(win(), "Reset stats")
  click(win(), "Click again to reset")
  check(LevelingCodexCharDB.stats.totals.quests == 0, "two clicks reset the saved stats")
end
```
and in `S.statsTabLost` add `check(not findButton(win(), function(l) return l == "This character" end), "no switch without saved data")`.

- [ ] **Step 2: Run** `python tests/run.py -k stats-tab` and `-k stats-lost`. Expected: FAIL.
- [ ] **Step 3: Implement** the renderer and `ns.coins`.
- [ ] **Step 4: Run** `python tests/run.py -k stats` and `-k tabRowFits` (in the stats-tab run). Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Stats tab: tiles, split and gold bars, activity tiles, zone bars, a session switch"`.

### Task 9: Docs, the full harness and the install

**Files:**
- Modify: `CLAUDE.md` (QuestMap minimap paragraph: chain, bends, no `pins.ahead`, edge hiding with `ns.questMapPinSpot`; Quests section: `Q.sectionProgress` = steps, `Q.turninProgress`, setup segments, guide rows; 7d Pace: `ns.paceRate`, kill pattern, `ns.paceDebugLines`, no `paceLog`; 7f Stats: `fromPct`, `S.levelRecord`, `S.earlierLevels`, the new tab; Window helpers `U.segments`, `U.fold`, `hit`'s label; Theme `ns.thousands`, `ns.coins`; test notes for the new scenarios)
- Modify: `docs/superpowers/specs/2026-11-13-polish-pass-design.md` (2.2: clicking a guide row follows it in the step window, as the button did; the spec said "opens the guide's page")

- [ ] **Step 1: Run the full harness** — `python tests/run.py > <scratchpad>/full.txt 2>&1` (in the background; read its tail). Expected: only `WARRIOR/full/blocked-report` fails.
- [ ] **Step 2: Update the docs** listed above.
- [ ] **Step 3: Commit** — `git commit -m "CLAUDE.md: the polish pass"`.
- [ ] **Step 4: Install** — check the installed `.toc` version's commit is an ancestor of HEAD (`git merge-base --is-ancestor <sha> HEAD`), then `python tools/install.py`. Expected: "all copies verified".
