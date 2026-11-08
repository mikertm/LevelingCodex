# Controller Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Codex window, its copy box, the crafting card and the banners usable with a
controller in WoW: Forever, through Forever's own navigation with the Codex's own as a backup.

**Architecture:** A new module `Gamepad.lua` attaches to a Codex frame and picks a mode each time it
shows: not in use, Forever navigation (`GamepadMode.FrameControlsManager` + `SmartNavigation`), or Codex
navigation (the frame takes D-pad/A/B/LB/RB/right stick itself). Window.lua tags its widgets and hands
the module a list of focusable pieces with logical positions. Banner.lua remembers what the last banner
was about. ProfessionGuide.lua auto-selects the recipe once per opening while the controller is in use.

**Tech Stack:** Lua 5.1 (WoW addon), Python + lupa harness (`tests/run.py`, `tests/wowmock.lua`,
`tests/scenarios.lua`).

**Spec:** `docs/superpowers/specs/2026-11-07-controller-support-design.md`

## Global Constraints

- Lua 5.1: no `goto`, no `//`, no integer division.
- All runtime text ASCII (route guide text through `ns.plain`).
- No new globals except frames named `LevelingCodex*` (the harness fails on leaks).
- Every non-core API behind an existence check and `pcall`; register events beyond the core ones with
  `pcall`.
- Forever's functions, mode changes and `SetPropagateGamePadInput` are only called out of combat
  (`InCombatLockdown()` false). In combat B is left to the game, as today.
- Never swallow a controller button the Codex doesn't use: per-press `SetPropagateGamePadInput(false)`
  only for buttons it acts on.
- Minimal client (no gamepad APIs) behaves exactly as today.
- Both `.toc` files stay byte-identical; `Gamepad.lua` goes after `ProfessionTab.lua`.
- Harness passes before every commit (`python tests/run.py` → `PASSED: 0 run(s) failed`); install with
  `python tools/install.py`.
- Button names: `PADDUP`, `PADDDOWN`, `PADDLEFT`, `PADDRIGHT`, `PAD1` (A), `PAD2` (B), `PADBACK`,
  `PADLSHOULDER` (LB), `PADRSHOULDER` (RB).
- Setting: `db.padNative` (nil = on, `false` = Codex navigation only); Settings head `CONTROLLER`, tick
  label `Use Forever's controller navigation`.
- Debug line: `controller: Forever navigation`, `controller: Codex navigation (<why>)` or
  `controller: not in use`.
- Banner memory lasts 60 s.

## Review Focus

1. A theme switch rebuilds the window while Forever owns it: the old frame must be handed back
   (`FrameHidden`) and the new one handed over. Test in Task 1.
2. The window closed by Esc or its X (not B): `FrameHidden` still runs and propagation is restored.
   Test in Task 1.
3. Combat starting while the window is open in Codex mode: the D-pad goes to the game and the focus
   doesn't move. Test in Task 2.
4. Pooled widgets reused across tabs: a `hit` strip that has a click on one tab and none on another
   must flip its ignored mark each redraw. Test in Task 1.
5. Picking up the controller while the window is open (`GAME_PAD_ACTIVE_CHANGED`): the window becomes
   controller-ready without reopening. Test in Task 1.

---

### Task 1: Gamepad.lua core, Forever navigation, LB/RB tabs

**Files:**
- Create: `Gamepad.lua`
- Modify: `Window.lua`:
  - widget helpers `icon`, `btn`, `check` (around lines 217-250) and `hit` (around line 1171);
  - `refresh` (around line 1196);
  - `closeWithGamepad` (around line 1282, removed and replaced by `ns.gamepad.attach`);
  - `makeFrame` (around line 1300);
  - `ns.rebuildForTheme` (around line 1503).
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (add `Gamepad.lua` after `ProfessionTab.lua`).
- Modify: `Init.lua` `ns.debugLines` (append `ns.gamepad.debugLines()`).
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`.

**Interfaces:**
- Produces (Gamepad.lua):
  - `ns.gamepad.inUse() -> boolean`: `InputUtil.IsGamepadUIEnabled()` or `IsUsingGamepad()` (each
    pcall'd, missing = false).
  - `ns.gamepad.attach(frame, opts)`. `opts` fields:
    - `popup`: boolean;
    - `scroll`: ScrollFrame or nil;
    - `focusables`: function returning `{ { frame = f, x = number, y = number }, ... }` in logical
      content coordinates, y growing downwards;
    - `onTab`: function(delta: -1 or 1) or nil.

    Hooks OnShow/OnHide and sets the frame's OnGamePadButtonDown (replacing `closeWithGamepad`).
  - `ns.gamepad.refresh(frame)`: Window calls it at the end of every `refresh`.
  - `ns.gamepad.mode(frame) -> "forever" | "codex" | nil, why: string|nil`
  - `ns.gamepad.debugLines() -> { string }` (one line for the main window).
- Produces (Window.lua):
  - widget tags: `w.padSkip = true` on `icon` widgets and on `hit` strips without onClick, else nil;
  - logical position on `btn`, `check`, `hit`: `w.padX = x + width / 2`, `w.padY = y + height / 2`
    (content coordinates).

- [ ] **Step 1: Mock Forever's controller pieces in `tests/wowmock.lua`**

  Add, all removed in the minimal client (OPTIONAL list):
  - `GamepadMode = { FrameControlsManager = { shown = {} } }` with:
    - `FrameShown(self, f, popup)`: errors `"refused"` when `MOCK.padRefuse`; returns false when
      `InputUtil.IsGamepadUIEnabled()` is false; else appends `f`, sets `f._padPopup = popup` and
      returns true;
    - `FrameHidden(self, f)`: removes `f` and sets `MOCK.padHidden[f] = true`;
    - both call `problem("gamepad", ...)` when `MOCK.combat`.
  - A named mock frame `SmartNavigation` with:
    - `RefreshButtonGroups(self, p)`: appends `p` to `MOCK.padRefreshed`;
    - `SetScrollFrameForFrame(self, p, s)`: sets `p._padScroll = s`;
    - `GetCurrentButton(self)`: nil when `MOCK.padNoFocus`, else the first shown Button descendant of
      the last frame in `shown`.
  - `SmartNavigation_MarkFrameIgnored(f)` sets `f._padIgnored = true`; `SmartNavigation_ClearIgnoreStatus(f)`
    clears it.
  - `InputUtil = { IsGamepadUIEnabled = function() return MOCK.gamepadUI == true end }` and
    `IsUsingGamepad = function() return MOCK.gamepad == true end`.
  - `GAME_PAD_ACTIVE_CHANGED` in `MOCK.knownEvents` and `MOCK.optionalEvents`.
  - `OnGamePadStick` in SCRIPTS, and `Frame:EnableGamePadStick(on)` (removed in minimal like
    `EnableGamePadButton`).
  - Reset `MOCK.padHidden = {}` and `MOCK.padRefreshed = {}` in setup.

- [ ] **Step 2: Write the failing scenarios in `tests/scenarios.lua`**

```lua
local function pad(f, b) MOCK.fire(f, "OnGamePadButtonDown", b) end
local function nav() return GamepadMode.FrameControlsManager end

-- Forever's controller UI on: the window joins its navigation.
function S.padForever()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Settings")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "window handed to Forever's window manager")
  check(win()._padScroll ~= nil, "scroll area registered")
  -- tooltip-only icons ignored, clickable pieces not
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and b.padSkip then check(b._padIgnored, "tooltip-only piece ignored") end
    if b:IsShown() and not b.padSkip then check(not b._padIgnored, "clickable piece not ignored: " .. tostring(b.tipTitle)) end
  end
  local n = #MOCK.padRefreshed
  click(win(), "Professions")
  check(#MOCK.padRefreshed > n, "buttons re-read after a redraw")
  -- (Review 4) after switching tabs the marks follow each strip's click
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() then check((b._padIgnored == true) == (b.padSkip == true), "mark follows the strip after a tab switch") end
  end
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: Forever navigation"), "debug line")
  win():Hide()
  check(MOCK.padHidden[win()], "closing hands it back (Review 2: Hide/Esc path)")
  check(win()._padPropagate ~= false, "input passes through once closed")
  MOCK.gamepadUI = nil
end

-- (Review 1) a theme switch rebuilds the window: the old one is handed back, the new one joins.
function S.padThemeRebuild()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Settings")
  local old = win()
  click(win(), "Codex (gold)")
  check(MOCK.padHidden[old], "old frame handed back")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown and win() ~= old, "the rebuilt window is handed over")
  click(win(), "Forever (teal)")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- LB/RB switch tabs (both modes), keeping B-to-close.
function S.padTabs()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level")
  pad(win(), "PADRSHOULDER")
  check(MOCK.textUnder(win()):find("Talent tree") and win()._padPropagate == false, "RB: next tab (Talents), button kept")
  pad(win(), "PADLSHOULDER"); pad(win(), "PADLSHOULDER")
  check(MOCK.textUnder(win()):find("Minimap button"), "LB twice from Talents wraps to Settings")
  pad(win(), "PAD1")
  check(win()._padPropagate == true, "A is Forever's in Forever mode")
  pad(win(), "PAD2")
  check(not win():IsShown(), "B closes")
  MOCK.gamepadUI = nil
end

-- Opened in combat: Forever's functions wait until combat ends (the mock flags any call in combat).
function S.padCombatOpen()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  MOCK.combat = true
  openAt(30, "Settings")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(not shown, "not handed over in combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.6)
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "handed over once combat ends")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- (Review 5) picking up the controller while the window is open.
function S.padPickUp()
  if not D() or not GamepadMode then return end
  openAt(30, "Settings")
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: not in use"), "no controller: not in use")
  MOCK.gamepadUI = true
  MOCK.event("GAME_PAD_ACTIVE_CHANGED", true)
  MOCK.advance(0.6)
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "joins Forever's navigation without reopening")
  win():Hide()
  MOCK.gamepadUI = nil
end
```

  Add `PAD = ["login", "gamepadClose", "padForever", "padThemeRebuild", "padTabs", "padCombatOpen", "padPickUp"]` to
  `tests/run.py`, run as `WARRIOR/<variant>/pad` and `MAGE/<variant>/pad`. The scenarios return early
  in the minimal client, where `GamepadMode` is gone.

- [ ] **Step 3: Run to verify they fail**

  Run: `python tests/run.py -k /pad`
  Expected: FAIL. `padForever` stops at "window handed to Forever's window manager"; `padTabs` stops at
  "RB: next tab".

- [ ] **Step 4: Implement**

  - **`Gamepad.lua`:** the interface above.
    - `attach` stores per-frame state `{ opts, mode, why, focus }`.
    - OnShow (and `GAME_PAD_ACTIVE_CHANGED` while shown, registered with pcall) calls
      `pick(frame)`. In combat it only notes the frame and picks again at `PLAYER_REGEN_ENABLED`
      (registered with pcall) if the frame is still shown. Out of combat:
      - when not `inUse()`: mode nil;
      - when the manager exists and `db.padNative ~= false`: pcall `FrameShown(frame, opts.popup)`. A
        true result gives mode "forever"; pcall `SmartNavigation:SetScrollFrameForFrame(frame,
        opts.scroll)`; apply the marks; schedule the 0.5 s focus check (Task 2 adds the backup);
      - otherwise: mode "codex" (Task 2).
    - OnHide: pcall `FrameHidden(frame)` when mode is "forever"; restore propagation.
    - `refresh(frame)`, in Forever mode: for every shown child Button/EditBox of the frame (recursive),
      call `SmartNavigation_MarkFrameIgnored` when `padSkip`, else `SmartNavigation_ClearIgnoreStatus`;
      then pcall `SmartNavigation:RefreshButtonGroups(frame)`.
    - The OnGamePadButtonDown handler, out of combat only:
      - PAD2/PADBACK close (as today);
      - PADLSHOULDER/PADRSHOULDER call `opts.onTab(-1 / 1)` when a mode is set;
      - everything else propagates.
  - **`Window.lua`:**
    - set `padSkip` and `padX`/`padY` in the helpers;
    - `makeFrame` calls `ns.gamepad.attach(frame, { scroll = scroll, focusables = listFocusables,
      onTab = cycleTab })`;
    - `refresh` ends with `ns.gamepad.refresh(frame)`;
    - `cycleTab(delta)` moves `activeTab` through `TABS` with wrap-around and calls `refresh()`;
    - `listFocusables` returns the used `btn`/`check`/`hit` widgets that aren't `padSkip`, plus the
      chrome:
      - header row at y = -40: prev arrow x = W*0.6, now button x = W*0.75, next arrow x = W*0.9,
        close x = W + 20;
      - tabs at y = content height + 40, x = i * W / #TABS;
    - `ns.rebuildForTheme` hides the old frame before dropping it (so OnHide hands it back);
    - remove `closeWithGamepad`.
  - **Load order:** add `Gamepad.lua` to both `.toc` files; debug line in `Init.lua`.

- [ ] **Step 5: Run the pad runs, then the whole suite**

  Run: `python tests/run.py -k /pad`, then `python tests/run.py`
  Expected: `PASSED: 0 run(s) failed`. `gamepadClose` still passes: A passes through when not in use,
  B closes, and B is left to the game in combat.

- [ ] **Step 6: Docs and commit**

  CLAUDE.md:
  - new module line `5c. Gamepad.lua` (modes, attach/refresh, Forever names);
  - allowed globals unchanged;
  - test note for `MOCK.gamepadUI` / `MOCK.gamepad` / `MOCK.padRefuse` / `MOCK.padNoFocus`.

```bash
git add Gamepad.lua Window.lua Init.lua LevelingCodex.toc LevelingCodex_Camelot.toc tests/wowmock.lua tests/scenarios.lua tests/run.py CLAUDE.md
git commit -m "Controller: join Forever's navigation, LB/RB switch tabs"
```

---

### Task 2: Codex navigation (backup), the copy box, and the setting

**Files:**
- Modify: `Gamepad.lua`, `Window.lua` (Settings head and tick; copy box attach in `makeCopy`, around
  line 1400).
- Test: `tests/scenarios.lua`, `tests/run.py`.

**Interfaces:**
- Consumes: Task 1's `attach` / `opts.focusables` / `padSkip` / `padX` / `padY`.
- Produces:
  - the focus highlight frame `LevelingCodexPadFocus` (field `target` = focused widget);
  - the copy box attached with `{ popup = true, focusables = copyFocusables }`, where
    `copyFocusables` returns the edit box and the box's shown Buttons on one row (y = 0, x = 100 * i).

- [ ] **Step 1: Write the failing scenarios**

```lua
local function focusLabel()
  local t = LevelingCodexPadFocus and LevelingCodexPadFocus.target
  return t and (t.label and t.label:GetText() or t.tipTitle or (t.GetText and t:GetText())) or ""
end

local function reachSkillUpTick()
  for _ = 1, 80 do
    if focusLabel():find("Profession skill%-up cards") then return true end
    pad(win(), "PADDDOWN")
  end
end

-- Backup when Forever refuses: the D-pad, A, scrolling, B.
function S.padBackup()
  if not D() or not GamepadMode then return end
  for _, how in ipairs({ "error", "no focus", "setting", "no manager" }) do
    MOCK.gamepadUI = true
    local saved = GamepadMode
    if how == "error" then MOCK.padRefuse = true end
    if how == "no focus" then MOCK.padNoFocus = true end
    if how == "setting" then LevelingCodexDB.padNative = false end
    if how == "no manager" then GamepadMode = nil; MOCK.gamepad = true end
    openAt(30, "Settings")
    MOCK.advance(0.6)
    check(LevelingCodexPadFocus and LevelingCodexPadFocus:IsShown(), "highlight shown (" .. how .. ")")
    check(reachSkillUpTick(), "D-pad reaches the skill-up tick (" .. how .. ")")
    check(GameTooltip:IsOwned(LevelingCodexPadFocus.target), "focusing shows its tooltip")
    check(win()._padPropagate == false, "the D-pad is the Codex's in this mode")
    pad(win(), "PAD1")
    check(LevelingCodexDB.noProfCards == true, "A ticks it (" .. how .. ")")
    pad(win(), "PAD1")
    check(not LevelingCodexDB.noProfCards, "A unticks it")
    MOCK.chat = {}; slash("debug")
    check(chatHas("controller: Codex navigation %("), "debug says why (" .. how .. ")")
    pad(win(), "PAD2")
    check(not win():IsShown() and not LevelingCodexPadFocus:IsShown(), "B closes, highlight goes")
    MOCK.padRefuse, MOCK.padNoFocus, LevelingCodexDB.padNative, MOCK.gamepad = nil, nil, nil, nil
    GamepadMode = saved
    MOCK.gamepadUI = nil
  end
end

-- Moving past the bottom scrolls; the right stick scrolls.
function S.padBackupScroll()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  reachSkillUpTick()
  check(LevelingCodexPadFocus.target:IsShown(), "focused piece visible")
  check(MOCK.scrollOf(win()) > 0, "scrolled to bring a lower piece into view")
  local before = MOCK.scrollOf(win())
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 1)
  MOCK.advance(0.5)
  check(MOCK.scrollOf(win()) < before, "right stick up scrolls up")
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 0)
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- (Review 3) combat starts while the window is open in Codex mode.
function S.padBackupCombat()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  local t = LevelingCodexPadFocus.target
  MOCK.combat = true
  pad(win(), "PADDDOWN")
  check(LevelingCodexPadFocus.target == t and win()._padPropagate == true, "in combat the D-pad goes to the game")
  MOCK.combat = false
  pad(win(), "PADDDOWN")
  check(LevelingCodexPadFocus.target ~= t, "after combat the D-pad moves the focus again")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- The copy box: a popup for Forever, the backup otherwise.
function S.padCopyBox()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  S.copyOpen()
  local copy = _G.LevelingCodexCopy
  local shown = false
  for _, f in ipairs(nav().shown) do if f == copy then shown = copy._padPopup == true end end
  check(shown, "copy box joins as a popup")
  pad(copy, "PAD2"); check(not copy:IsShown(), "B closes the copy box")
  LevelingCodexDB.padNative = false
  S.copyOpen()
  check(LevelingCodexPadFocus:IsShown() and LevelingCodexPadFocus.target == copy.edit, "backup focuses the text first")
  pad(copy, "PADDRIGHT")
  check(LevelingCodexPadFocus.target ~= copy.edit, "D-pad moves to the box's buttons")
  pad(copy, "PAD2")
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end
```

  Add `MOCK.scrollOf(frame)` to the mock: the `_scroll` of the first
  ScrollFrame descendant. Append `"padBackup", "padBackupScroll", "padBackupCombat", "padCopyBox"` to
  `PAD`, and add `padNative` to `everyButton`'s reset list.

- [ ] **Step 2: Run to verify they fail**

  Run: `python tests/run.py -k /pad`
  Expected: FAIL at "highlight shown (error)".

- [ ] **Step 3: Implement**

  - **Backup trigger:** use mode "codex" with `why` set to:
    - `"Forever refused the window"`: FrameShown errored or returned false;
    - `"no focus from Forever"`: 0.5 s after FrameShown, `SmartNavigation:GetCurrentButton()` is not a
      descendant of the frame; first pcall `FrameHidden`;
    - `"turned off in Settings"`: `db.padNative == false`;
    - `"no Forever navigation"`: manager missing while `inUse()`.
  - **Codex mode, on enter:**
    - pcall `EnableGamePadStick(true)`;
    - focus the first focusable in reading order (lowest y, then x);
    - show `LevelingCodexPadFocus`: a 2-px gold border (r, g, b = 1, 0.82, 0) anchored around the
      target, frame strata `FULLSCREEN_DIALOG`;
    - run the target's OnEnter (and the previous target's OnLeave on every move).
  - **D-pad:** pick the next focusable in the direction (algorithm below), refocus, and scroll it into
    view. Its y must lie within `[off, off + visible]`, where `visible = scroll:GetHeight()`, or 480 when
    the client says 0. Otherwise set `scroll:SetVerticalScroll(clamp(y - visible / 2, 0,
    GetVerticalScrollRange()))`.
  - **Buttons:**
    - PAD1 calls `target:Click()` (pcall), then `ns.gamepad.refresh` keeps the focus on the same
      position (nearest focusable to the old x, y);
    - the D-pad and PAD1 set propagation to false, everything else to true.
  - **Right stick:** `OnGamePadStick(self, stick, x, y)` with stick `"Right"` or `"Camera"` stores y;
    an OnUpdate scrolls by `-y * 600 * elapsed` while `math.abs(y) > 0.2`.
  - **Leaving Codex mode** (hide, combat start, mode change): hide the highlight, propagation back to
    true, `EnableGamePadStick(false)`.
  - **Settings:** after the GATHERING head, `head("CONTROLLER")` and
    `tick("Use Forever's controller navigation", db.padNative ~= false, toggle, "Off: the Codex moves its own highlight with the D-pad instead of Forever's focus glow. Turn it off if Forever's controller navigation misbehaves in the Codex.")`.
    The toggle sets `db.padNative = (db.padNative == false) and nil or false`.
  - **Copy box:** `makeCopy` calls `ns.gamepad.attach(copy, { popup = true, focusables = copyFocusables })`.

  Direction algorithm (not determined by the tests). For direction (dx, dy), from (x, y) to a candidate
  (cx, cy):

```lua
local vx, vy = cx - x, cy - y
local along = vx * dx + vy * dy            -- must be > 0
local across = math.abs(vx * dy - vy * dx) -- must be <= along * 2
local score = along + 2 * across           -- lowest wins
```

- [ ] **Step 4: Run the pad runs, then the whole suite**

  Run: `python tests/run.py -k /pad`, then `python tests/run.py`
  Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 5: Docs and commit**

  CLAUDE.md: the `5c` line gains the backup, `LevelingCodexPadFocus`, `db.padNative`.
  CHANGELOG: a v0.12.0 line "Controller support: the Codex window works with Forever's controller
  navigation (D-pad, A, B, LB/RB tabs, right stick), with its own as a backup (Settings > Controller)."

```bash
git add Gamepad.lua Window.lua tests/wowmock.lua tests/scenarios.lua tests/run.py CLAUDE.md CHANGELOG.md
git commit -m "Controller: Codex navigation as a backup, copy box, Settings switch"
```

---

### Task 3: Crafting card selects the recipe on the controller

**Files:**
- Modify: `ProfessionGuide.lua`: `hideGuide` (around line 281) and the out-of-view branch of `tick`
  (around line 540).
- Test: `tests/scenarios.lua`, `tests/run.py`.

**Interfaces:**
- Consumes: `ns.gamepad.inUse()` (Task 1); `selectRecipe(found, pick, root)` (existing,
  ProfessionGuide.lua).
- Produces: `guide.autoDone` (per opening), reset in `hideGuide`.

- [ ] **Step 1: Write the failing scenario**

```lua
-- On the controller the recipe is selected and scrolled into view once per opening.
function S.craftPadAutoSelect()
  if not craftReady() or not GamepadMode then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.trade.offset, MOCK.trade.selected = 0, 0
  MOCK.trade.layout()
  MOCK.gamepad = true
  openCraft()
  check(MOCK.trade.selected > 0 and LevelingCodexCraftTrace:IsShown(), "selected and outlined on opening")
  MOCK.trade.offset = 0; MOCK.trade.layout()   -- the player scrolls away
  MOCK.advance(3)
  check(not LevelingCodexCraftTrace:IsShown() and MOCK.trade.offset == 0, "not pulled back after scrolling away")
  closeCraft()
  MOCK.trade.selected = 0
  openCraft()
  check(MOCK.trade.selected > 0, "again on the next opening")
  closeCraft()
  MOCK.gamepad = nil
  MOCK.trade.offset, MOCK.trade.selected = 0, 0
  MOCK.trade.layout()
  openCraft()
  check(MOCK.trade.selected == 0, "mouse: nothing automatic")
  closeCraft()
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.layout()
end
```

  Add `"craftPadAutoSelect"` to `CRAFT` in `tests/run.py`, after `craftScrolled`.

- [ ] **Step 2: Run to verify it fails**

  Run: `python tests/run.py -k /craft`
  Expected: FAIL at "selected and outlined on opening".

- [ ] **Step 3: Implement**

  In `tick`, once a pick and `found` exist: if not `guide.autoDone`, set it true, and when
  `ns.gamepad and ns.gamepad.inUse()` and the row isn't found, call `selectRecipe(found, pick, root)`.
  `hideGuide` sets `guide.autoDone = nil`.

- [ ] **Step 4: Run the craft runs, then the whole suite**

  Run: `python tests/run.py -k /craft`, then `python tests/run.py`
  Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 5: Docs and commit**

  CLAUDE.md 7a: "with the controller in use, Show it runs once by itself per opening".
  CHANGELOG: append to the controller line.

```bash
git add ProfessionGuide.lua tests/scenarios.lua tests/run.py CLAUDE.md CHANGELOG.md
git commit -m "Controller: the crafting card selects the recipe on opening"
```

---

### Task 4: Opening the Codex after a banner opens what it was about

**Files:**
- Modify:
  - `Banner.lua`: `ns.showToast` (around line 347), `ns.showCard` (around line 376);
  - `Professions.lua`: the `ns.showCard` call in `checkSkills`;
  - `Window.lua`: `ns.toggleWindow` (around line 1494).
- Test: `tests/scenarios.lua`, `tests/run.py`.

**Interfaces:**
- Produces:
  - `ns.showCard(title, sub, rows, onClick, target)`, where `target` is `{ tab = string, key = string|nil }`;
  - `ns.lastBanner = { tab, key, at = GetTime() }`, set when a banner is shown:
    - level-up: `{ tab = "level" }`;
    - skill-up: `{ tab = "professions", key = key }`;
  - `ns.toggleWindow` applies `ns.lastBanner` when opening within 60 s (`activeTab = tab`,
    `ns.profTabShow(key)` when key), then clears it.

- [ ] **Step 1: Write the failing scenario**

```lua
-- Opening the Codex within a minute of a banner opens what it was about.
function S.bannerOpensTarget()
  if not D() then return end
  openAt(30, "Settings"); win():Hide()          -- last tab: Settings
  MOCK.setSkill("Blacksmithing", 94, 150); MOCK.advance(1.2)
  MOCK.setSkill("Blacksmithing", 95, 150); MOCK.advance(1.2)   -- skill-up card
  slash("")
  check(MOCK.textUnder(win()):find("Blacksmithing 95 / 150"), "opens on the profession the card was about")
  win():Hide()
  slash("")
  check(MOCK.textUnder(win()):find("Blacksmithing 95 / 150"), "used once: reopening keeps the tab you were on")
  click(win(), "Settings"); win():Hide()
  MOCK.setSkill("Blacksmithing", 100, 150); MOCK.advance(1.2)
  MOCK.advance(61)
  slash("")
  check(MOCK.textUnder(win()):find("Minimap button"), "after a minute it opens as usual")
  win():Hide()
end
```

  Add `PROF_BANNER = ["login", "bannerOpensTarget"]` as `WARRIOR/<variant>/banner-target` in
  `tests/run.py`.

- [ ] **Step 2: Run to verify it fails**

  Run: `python tests/run.py -k banner-target`
  Expected: FAIL at "opens on the profession the card was about".

- [ ] **Step 3: Implement** the interface above. The `checkSkills` card passes
  `{ tab = "professions", key = key }`. `ns.showToast` sets `ns.lastBanner` only when it actually
  presents (not test mode).

- [ ] **Step 4: Run the banner-target run, then the whole suite**

  Run: `python tests/run.py -k banner-target`, then `python tests/run.py`
  Expected: `PASSED: 0 run(s) failed`.

- [ ] **Step 5: Docs and commit**

  CLAUDE.md module 4 (Banner): `ns.lastBanner`, the 60 s rule. CHANGELOG: one line.

```bash
git add Banner.lua Professions.lua Window.lua tests/scenarios.lua tests/run.py CLAUDE.md CHANGELOG.md
git commit -m "Opening the Codex after a banner opens what it was about"
```

---

### Task 5: Install and the in-game checklist

- [ ] **Step 1:** Run `python tests/run.py` and expect `PASSED: 0 run(s) failed`. Then run
  `python tools/install.py` and expect "all copies verified".
- [ ] **Step 2:** Tell the owner to restart the client (the `.toc` changed) and check:
  - Forever's controller UI on, open the Codex: the gold glow lands on it.
  - D-pad through a tab; A on a tab button, a Settings tick, a route step; LB/RB; right stick; B.
  - Settings > Controller unticked: the Codex's own highlight does the same.
  - The crafting window opened on the controller selects the recipe.
  - A skill-up card, then open the Codex: it shows that profession.
  - `/codex debug` screenshot (the `controller:` line).
