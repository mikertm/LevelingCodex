# Step Window Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the step window richer and friendlier: colour-coded step kinds, goal bars, up-next distances, a turn-in XP chip, NPC portraits, a themed button row, and size/opacity/fade/compact comfort settings.

**Architecture:** Step kinds and their styles live beside `ns.questIcon` in QuestMap.lua; the step window (QuestGuide.lua) draws the chip, stripe, bars, rows, XP chip and buttons and owns the comfort behaviours; the portrait is its own small module (QuestPortrait.lua) fed by a generated `QuestNPCData.lua`; the themed icon and primary buttons are Art.lua pieces.

**Tech Stack:** WoW: Forever add-on (Interface 16001, Lua 5.1); `tests/` (Python + lupa, `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`); `tools/` generators run with `tools/.cache/quest-venv/Scripts/python.exe -I`.

**Spec:** `docs/superpowers/specs/2026-11-13-step-window-polish-design.md`

## Global Constraints

- Lua 5.1; runtime text ASCII only; no new globals beyond `LevelingCodex*` frames; both .toc files byte-identical.
- Guard every non-core API (`Q.try`, existence checks); probe art with `ns.art.hasFile` and fall back to flat colour; `pcall` non-core events; works with empty SavedVariables.
- The step window never joins Forever's controller navigation; secure buttons (item, target) never change in combat and nothing here touches them.
- Buttons keep `codexLabel`s "Back", "Next" (or "Skip"), "Quests", "Hide".
- Test commands: `python tests/run.py -k <filter>` (case-sensitive substring of the run name); full suite `python tests/run.py` (`WARRIOR/full/blocked-report` fails in every worktree, not a regression).
- Install after the final harness: the installed `.toc` version's commit must be an ancestor of HEAD, then `python tools/install.py`; a .toc change needs a client restart.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. A theme switch while the window shows: the chip, stripe, Next button and icon buttons repaint in the new palette (Task 6 `stepButtons` switches theme).
2. The minimal client (no textures, no `PlayerModel`, no `GetQuestLogRewardXP`): plain plates and labels, the icon in the portrait ring, no XP chip, no error (Tasks 4, 5, 6 run minimal too).
3. A quest started by an object or item (no `start` NPC) and a kill step without a target ID: the ring shows the step icon (Task 5 `questPortrait`).
4. No player position (inside an instance or a loading screen): up-next rows show the zone name or nothing, no error (Task 3 `stepUpNext` clears `MOCK.questX`).
5. Compact mode on a step with no goals and no spot (a note step): the title row shows no count or distance and the window still draws (Task 7 `stepCompactNote`).

---

### Task 1: Step kinds, chip, stripe and title

**Files:**
- Modify: `QuestMap.lua` (new `ns.questStepKind`, `ns.questKindStyle`, next to `ns.questIcon`)
- Modify: `QuestGuide.lua` (`makeViewer`: `viewer.stripe`, `viewer.chip`; `ns.questRefresh`: chip, title colour and text)
- Test: `tests/scenarios.lua` (new `S.stepKinds`), `tests/run.py` (add to the quest list)

**Interfaces:**
- Produces: `ns.questStepKind(step) -> "accept"|"turnin"|"kill"|"collect"|"travel"|"dungeon"|"other"`; `ns.questKindStyle(kind, step) -> { label = string, color = { r, g, b } }` (label for "other" = the step type's word: "Note", "Train", "Grind", "Abandon"; "dungeon" = "Boss" for `boss` steps, else "Dungeon"); `viewer.stripe` (3 px texture, LEFT edge), `viewer.chip` (frame with `.plate` texture and `.text` font string).

Kind rules and colours exactly as the spec's table (1.1). Kill = `complete` whose `ns.questIcon(step)` is the Attack cursor (reuse QuestMap.lua's local `kills(step)` test).

- [ ] **Step 1: Write the failing test**

```lua
-- The step window colours each step by kind: a chip, the title in that colour, a stripe down the left.
function S.stepKinds()
  local kind = MOCK.ns.questStepKind
  check(kind({ type = "accept" }) == "accept" and kind({ type = "turnin" }) == "turnin"
    and kind({ type = "fly" }) == "travel" and kind({ type = "boss" }) == "dungeon"
    and kind({ type = "note" }) == "other" and kind({ type = "buy" }) == "collect", "step kinds")
  check(MOCK.ns.questKindStyle("other", { type = "train" }).label == "Train", "other kinds use the step's word")
  S.login()
  local frame = questViewer()
  local function near(c, r, g, b) return math.abs(c[1] - r) < 0.01 and math.abs(c[2] - g) < 0.01 and math.abs(c[3] - b) < 0.01 end
  check(frame.chip.text._text == "Accept" and questText(frame, "A Threat Within")
    and not questText(frame, "Accept - A Threat Within"), "an accept step: chip, title without the prefix")
  local sr, sg, sb = frame.stripe:GetVertexColor()
  check(near({ sr, sg, sb }, 1, 0.82, 0), "the stripe is gold for a pickup")
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  check(frame.chip.text._text == "Turn in", "a turn-in step's chip")
end
```
(The stripe uses `SetColorTexture` in the minimal client and `SetVertexColor` on the white texture otherwise; give the mock texture a `GetVertexColor` returning what either call set if it lacks one.)

- [ ] **Step 2: Run** `python tests/run.py -k stepKinds`. Expected: FAIL (`questStepKind` is nil).
- [ ] **Step 3: Implement** the two functions and the window pieces: chip at the title's left (plate in the colour at 30% brightness, label in the colour lightened 50%), title starts after the chip, title text = `step.name or step.flight` when the step has one (else `Q.label(step)`), title colour = the kind colour; stripe 3 px wide inside the window's left border, full height.
- [ ] **Step 4: Run** `python tests/run.py -k stepKinds`, `-k stepPolish`, `-k quest`. Expected: PASS (fix tests that read the old "Accept - X" title from the window by checking the chip and name instead; `Q.label` is unchanged everywhere else).
- [ ] **Step 5: Commit** — `git commit -m "Step window: colour-coded step kinds with a chip and a stripe"`.

### Task 2: Goal bars

**Files:**
- Modify: `QuestGuide.lua` (`makers.row`: `r.track`, `r.bar`; `putGoal`)
- Test: `tests/scenarios.lua` (`S.stepPolish`, new checks)

**Interfaces:**
- Consumes: `ns.questStepKind`, `ns.questKindStyle` (Task 1).
- Produces: goal rows with `r.track` / `r.bar` textures (4 px, under the row's text).

A row whose block has a count gets the bar: track `{ 0.1, 0.13, 0.15, 0.9 }` over the row's width minus 16, fill = have / need of it; colour = the current step's kind colour for main goals, orange `{ 0.95, 0.65, 0.25 }` for `b.small` goals; a done goal = green `{ 0.45, 0.85, 0.4 }` full bar and count text "done". The row's height grows by 6.

- [ ] **Step 1: Write the failing test** — in `S.stepPolish` after the window opens (Kobold Vermin 4/10):

```lua
  local row
  for _, c in ipairs({ frame:GetChildren() }) do
    if c.count and c.count._text == "4/10" and c:IsShown() then row = c end
  end
  check(row and row.bar and row.bar:IsShown()
    and math.abs(row.bar:GetWidth() - 0.4 * row.track:GetWidth()) < 1, "a 4/10 goal fills 40% of its bar")
```
and after the objective reaches 10/10: `check(questText(frame, "done"), "a finished goal says done")`.

- [ ] **Step 2: Run** `python tests/run.py -k stepPolish`. Expected: FAIL.
- [ ] **Step 3: Implement** in `makers.row` and `putGoal` (bars hidden when the block has no count; pooled rows reset the bar's shown state, width and colour on every draw).
- [ ] **Step 4: Run** `-k stepPolish` and `-k quest`. Expected: PASS (update any test that expects "10/10" on a finished row to "done").
- [ ] **Step 5: Commit** — `git commit -m "Step window: goal bars that fill and say done"`.

### Task 3: Up next with icons and distances

**Files:**
- Modify: `QuestGuide.lua` (`addPreview` emits one `{ kind = "upnext", step = s, text = label }` block per row; new `putNext`; the 0.25 s tick refreshes distances)
- Test: `tests/scenarios.lua` (new `S.stepUpNext`), `tests/run.py`

**Interfaces:**
- Produces: up-next rows `{ icon (12 px texture), name (font string), dist (right-aligned font string) }`; `ns.questNextDistances()` (re-reads the shown rows' distances; the tick calls it).

Distance: the row step's `Q.waypoint` spot on your map → `Q.vector` yards, `math.floor(yd + 0.5) .. " yd"`; on another map → `C_Map.GetMapInfo(spot.map).name` (ASCII via `Q.plain`); else "".

- [ ] **Step 1: Write the failing test**

```lua
-- Up next rows: the step's icon and how far it is, updating as you move.
function S.stepUpNext()
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 3, { type = "goto", text = "Look in on Stormwind.", map = 1453, x = 50, y = 50 })
  MOCK.mapInfo = { [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 } }
  MOCK.questX, MOCK.questY = 44, 41
  S.login()
  local frame = questViewer()
  local function dist()
    for _, c in ipairs({ frame:GetRegions() }) do
      if c:IsShown() and type(c._text) == "string" and c._text:match("^%d+ yd$") then return c._text end
    end
  end
  local before = dist()
  check(before, "an up-next row shows its distance")
  check(questText(frame, "Stormwind City"), "a step on another map shows its zone")
  MOCK.questX = 47
  MOCK.advance(0.5)
  check(dist() and dist() ~= before, "and it updates as you move")
  MOCK.questX, MOCK.questY = nil, nil -- no position (an instance)
  MOCK.advance(0.5)
  check(not dist(), "no position: no distances, no error")
end
```

- [ ] **Step 2: Run** `python tests/run.py -k stepUpNext`. Expected: FAIL.
- [ ] **Step 3: Implement** (the old single "next" text block goes; "Next section: X" and the last-step note stay as notes).
- [ ] **Step 4: Run** `-k stepUpNext`, `-k quest`. Expected: PASS (tests reading UP NEXT text still find each label).
- [ ] **Step 5: Commit** — `git commit -m "Step window: up next rows with icons and distances"`.

### Task 4: Turn-in XP chip

**Files:**
- Modify: `QuestGuide.lua` (`makeViewer`: `viewer.xp` = plate + font string under the title; `ns.questRefresh`)
- Test: `tests/scenarios.lua` (new `S.stepXP`; run in both variants)

**Interfaces:**
- Consumes: `ns.thousands` (Theme.lua).
- Produces: `viewer.xp` (shown only on a turn-in step with XP).

- [ ] **Step 1: Write the failing test**

```lua
-- A turn-in step shows the XP it gives, and when it levels you up.
function S.stepXP()
  MOCK.questDone[783] = nil
  MOCK.xp, MOCK.xpMax = 100, 400
  MOCK.rewardXP = { [783] = 350 }
  S.login()
  local frame = questViewer()
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  if MOCK.minimal then check(not questText(frame, " XP"), "no XP API: no chip"); return end
  check(questText(frame, "+350 XP") and questText(frame, "levels you up"), "the turn-in's XP chip")
  MOCK.rewardXP[783] = 100
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "+100 XP") and not questText(frame, "levels you up"), "not enough to level")
end
```
(If the minimal client keeps `GetQuestLogRewardXP`, remove it there in the mock's minimal list.)

- [ ] **Step 2: Run** `python tests/run.py -k stepXP`. Expected: FAIL.
- [ ] **Step 3: Implement** (`GetQuestLogRewardXP` via `Q.try`; chip shown only for kind "turnin" with the quest in the log and XP > 0; "levels you up" when `UnitXP + xp >= UnitXPMax` and level < 60; the detail starts below it).
- [ ] **Step 4: Run** `-k stepXP` (both variants run) and `-k quest`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Step window: the XP a turn-in gives"`.

### Task 5: NPC portraits and QuestNPCData.lua

**Files:**
- Create: `tools/questnpcs.py` (like `tools/questmobs.py`), `QuestNPCData.lua` (generated), `QuestPortrait.lua`
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (`QuestNPCData.lua` after `QuestMobData.lua`; `QuestPortrait.lua` after `QuestMap.lua`), `QuestGuide.lua` (title row shifts right when the portrait shows), `Window.lua` (Settings > Show the NPC portrait, `db.noQuestPortrait`), `tests/wowmock.lua` (`PlayerModel`), `tests/run.py` (`quest_npc_checks()` with the other data checks; scenario list)
- Test: `tests/scenarios.lua` (new `S.questPortrait`, both variants)

**Interfaces:**
- Produces: `ns.questNPCs[questID] = { start = n, finish = n, mob = n }` (positive integers, keys optional); `ns.makeQuestPortrait(parent) -> frame` with `frame:ShowFor(step, kind) -> boolean` (true when the ring shows, model or icon) and `frame.model` (the PlayerModel or nil), `frame.icon` (texture), `frame.creature` (the ID it asked for).

Generator: for each route quest (accept, turnin and complete steps), `start` = first NPC in QuestieDB `startedBy[1]`, `finish` = first in `finishedBy[1]`, `mob` = first creature objective (`objectives[1]`), else the first kill-credit creature (`objectives[5]`). `--check` like questmobs.py.
Portrait: 44 px; `PlayerModel` created with `pcall(CreateFrame, "PlayerModel", nil, parent)`; `SetCreature(id)`, portrait camera (`SetPortraitZoom(1)` when present); a gold ring texture over it (`Interface\Minimap\MiniMap-TrackingBorder` probed, else a 1 px gold square edge); 1 s after `SetCreature`, a model whose `GetModelFileID()` is nil or 0 is hidden and the icon (`ns.questIcon(step)`) shows. Accept uses `start`, turn-in `finish`, kill `mob`; with no ID for those kinds the ring shows the icon straight away; any other kind: `ShowFor` returns false, the ring hides and the title stays at the left. QuestGuide keeps it as `viewer.portrait`.

- [ ] **Step 1: Write the failing test** (the mock's `PlayerModel` records `_creature`, returns `GetModelFileID()` = `MOCK.modelFails and nil or 123`; the minimal client has no `PlayerModel` type)

```lua
-- A small 3D portrait of the step's NPC, the step's icon when the model can't show.
function S.questPortrait()
  MOCK.ns.questNPCs[783] = { start = 197, finish = 823 }
  S.login()
  local frame = questViewer()
  local p = frame.portrait
  if MOCK.minimal then
    check(p and p:IsShown() and p.icon:IsShown() and not (p.model and p.model:IsShown()), "no models: the icon")
    return
  end
  check(p:IsShown() and p.creature == 197 and p.model:IsShown(), "an accept step shows its giver")
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  check(p.creature == 823, "a turn-in shows its finisher")
  MOCK.modelFails = true
  MOCK.ns.questNPCs[783].finish = 824
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(1.2)
  check(p.icon:IsShown() and not p.model:IsShown(), "a model that doesn't load gives way to the icon")
  MOCK.modelFails = nil
  MOCK.ns.questNPCs[783] = nil -- a quest started by an object or item: no NPC to show
  MOCK.event("QUEST_LOG_UPDATE")
  check(p:IsShown() and p.icon:IsShown() and not p.model:IsShown(), "no NPC ID: the ring shows the icon")
  LevelingCodexDB.noQuestPortrait = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not p:IsShown(), "the setting hides it")
end
```
Plus `quest_npc_checks()`: `ns.questNPCs` is a table of `[int] = { start/finish/mob = positive int }` with no other keys, and quest 783 has `start` and `finish`.

- [ ] **Step 2: Run** `python tests/run.py -k questPortrait`. Expected: FAIL.
- [ ] **Step 3: Implement** the generator (write the file with `tools/.cache/quest-venv/Scripts/python.exe -I tools/questnpcs.py`), the module, the .toc lines, the mock class, the setting and the title shift (portrait at TOPLEFT 12, -24; chip and title start at 64 when it shows).
- [ ] **Step 4: Run** `-k questPortrait` (both variants), `-k quest`, and `tools/.cache/quest-venv/Scripts/python.exe -I tools/questnpcs.py --check`. Expected: PASS, "up to date".
- [ ] **Step 5: Commit** — `git commit -m "Step window: NPC portraits from generated QuestNPCData.lua"`.

### Task 6: Themed button row

**Files:**
- Modify: `Art.lua` (new `A.iconButton(parent, file, fallback)`, `A.primaryButton(parent)`; `A.FILES.questBook = "Interface\\QuestFrame\\UI-QuestLog-BookIcon"`), `QuestGuide.lua` (`makeViewer` buttons; theme repaint in `ns.questRefresh`)
- Test: `tests/scenarios.lua` (new `S.stepButtons`, both variants)

**Interfaces:**
- Produces: `A.iconButton(parent, file, fallback) -> Button` (28 x 24, dark plate `C.btnOff`, 1 px `C.edge`, the art 16 px or the fallback text, hover highlight, `:Repaint()`); `A.primaryButton(parent) -> Button` (`C.btnOn` fill, `C.btnOnInk` label + ">" , 1 px light edge, `:SetLabel(s)`, `:Repaint()`).

Layout (window 350 wide): Back icon at x 12 (`A.FILES.prevUp`, fallback "<"), Next primary at x 44 width 222, Quests icon at x 270 (`questBook`, fallback "Q"), Hide icon at x 302 (`A.FILES.minusUp`, fallback "x"); tooltips "Back", "Quests", "Hide"; Next's label "Next step" or "Skip run" (codexLabel "Next" / "Skip"). The offer button (`suggestionButton`) becomes a primary button. `ns.questRefresh`'s theme branch calls `:Repaint()` on all five.

- [ ] **Step 1: Write the failing test**

```lua
-- The step window's buttons: a wide themed Next, small icon buttons with tooltips.
function S.stepButtons()
  S.login()
  local frame = questViewer()
  local nextB = findButton(frame, function(l) return l == "Next" end)
  check(nextB and nextB.label and nextB.label._text:find("^Next step") and nextB:GetWidth() > 200, "a wide Next step")
  for _, name in ipairs({ "Back", "Quests", "Hide" }) do
    local b = findButton(frame, function(l) return l == name end)
    check(b and b:GetWidth() <= 30, name .. " is an icon button")
    MOCK.fire(b, "OnEnter")
    check(GameTooltip._lines[1] == name, name .. " names itself on hover")
    MOCK.fire(b, "OnLeave")
  end
  local before = { nextB.fill:GetVertexColor() }
  MOCK.ns.useTheme("codex")
  MOCK.event("QUEST_LOG_UPDATE")
  check(({ nextB.fill:GetVertexColor() })[1] ~= before[1], "a theme switch repaints Next")
end
```

- [ ] **Step 2: Run** `python tests/run.py -k stepButtons`. Expected: FAIL.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** `-k stepButtons` (both variants), `-k quest`, `-k pad`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Step window: a themed Next step button and icon buttons"`.

### Task 7: Window comfort

**Files:**
- Modify: `QuestGuide.lua` (scale, background alpha, combat fade, compact mode, the corner chevron), `Window.lua` (Settings rows: "Step window size" stepper 70-150%, "Step window background" stepper 20-100%, "Fade the step window in combat", "Compact step window")
- Test: `tests/scenarios.lua` (new `S.stepComfort`), `tests/run.py`

**Interfaces:**
- Produces: `db.questViewerScale` (0.7-1.5, step 0.1), `db.questViewerAlpha` (0.2-1.0, step 0.1), `db.noQuestFade`, `db.questCompact`; the chevron button `codexLabel` "Compact" / "Expand"; `viewer.background` (the window's background texture, whose alpha the background stepper sets).

Fade: register PLAYER_REGEN_DISABLED (pcall); a tween moves `viewer:GetAlpha()` to its target over 0.3 s (OnUpdate on the viewer); in combat the target is 0.3, 1 while the mouse is over the window (OnEnter/OnLeave hooks), and 1 again at PLAYER_REGEN_ENABLED. Background alpha: the backdrop's colours (`SetBackdropColor` / `SetBackdropBorderColor` with alpha) and `flatBackground`'s alpha. Compact: `ns.questRefresh` draws only the title row (chip, title, at the right the first unfinished goal's count, else the current up-next-style distance to the step, else nothing), the bar and the buttons.

- [ ] **Step 1: Write the failing test**

```lua
-- Step window comfort: size, background, fading in combat, compact mode.
function S.stepComfort()
  S.login()
  local frame = questViewer()
  slash("")
  click(win(), "Settings")
  for _ = 1, 2 do click(win(), "Step window size +") end
  check(math.abs(frame:GetScale() - 1.2) < 0.001, "the size stepper scales the window")
  local textAlpha = frame:GetAlpha()
  for _ = 1, 3 do click(win(), "Step window background -") end
  check(frame.background and math.abs(frame.background:GetAlpha() - 0.7) < 0.01 and frame:GetAlpha() == textAlpha,
    "the background stepper fades the background only")
  MOCK.event("PLAYER_REGEN_DISABLED")
  MOCK.advance(0.5)
  check(math.abs(frame:GetAlpha() - 0.3) < 0.01, "combat fades the window")
  MOCK.fire(frame, "OnEnter"); MOCK.advance(0.5)
  check(math.abs(frame:GetAlpha() - 1) < 0.01, "the mouse brings it back")
  MOCK.fire(frame, "OnLeave"); MOCK.advance(0.5)
  check(frame:GetAlpha() < 0.5, "leaving fades it again")
  MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.5)
  check(math.abs(frame:GetAlpha() - 1) < 0.01, "after combat it's back")
  local tall = frame:GetHeight()
  click(frame, "Compact")
  check(frame:GetHeight() < tall and not questText(frame, "UP NEXT") and findButton(frame, function(l) return l == "Expand" end),
    "compact mode keeps only the title row, the bar and the buttons")
  click(frame, "Expand")
  check(questText(frame, "UP NEXT"), "and expands again")
end

-- Compact mode on a step with no goals and no spot draws the title row alone.
function S.stepCompactNote()
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 1, { type = "note", text = "Read this first." })
  LevelingCodexDB = { questCompact = true }
  S.login()
  local frame = questViewer()
  check(frame:IsShown() and frame.chip.text._text == "Note" and not questText(frame, " yd"),
    "a compact note step: chip and title, no count or distance")
end
```
(The stepper buttons' codexLabels are "Step window size -" / "Step window size +" and "Step window background -" / "Step window background +"; the window's background (the backdrop and `flatBackground`) is reachable as `viewer.background` for the alpha check. Add `stepCompactNote` to the run list too.)

- [ ] **Step 2: Run** `python tests/run.py -k stepComfort`. Expected: FAIL.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** `-k stepComfort`, `-k quest`, `-k pad`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Step window: size, background, fade in combat and compact mode"`.

### Task 8: Docs, the full harness and the install

**Files:**
- Modify: `CLAUDE.md` (QuestGuide.lua step window: kinds, chip, stripe, goal bars, up next, XP chip, buttons, comfort settings; new rows for `QuestNPCData.lua` / `tools/questnpcs.py` and `QuestPortrait.lua` in the Files table and the quest module list; test notes for the new scenarios and mock pieces)

- [ ] **Step 1: Run the full harness** — `python tests/run.py` (in the background; read its tail). Expected: only `WARRIOR/full/blocked-report` fails.
- [ ] **Step 2: Update CLAUDE.md** as listed.
- [ ] **Step 3: Commit** — `git commit -m "CLAUDE.md: the step window polish"`.
- [ ] **Step 4: Install** — check the installed version's commit is an ancestor of HEAD, then `python tools/install.py`. Expected: "all copies verified". Tell the owner a client restart is needed (the .toc changed).
