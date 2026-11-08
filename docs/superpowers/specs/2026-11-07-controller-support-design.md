# Controller support: design

Date: 7 Nov 2026. Branch: `controller-support` (from `profession-guides`).

## Goal

Make the Codex usable with a controller in WoW: Forever, with the same look and buttons as
Forever's own windows.

**What the owner asked for:**
- Move around the Codex window: switch tabs, browse levels, press buttons (macro setup, Settings, the
  Professions route).
- Scroll the long tabs.
- Use the cards and banners: the crafting card's "Show it", and clicking the level-up and skill-up
  banners.
- Opening the Codex with the mouse or keyboard is fine (not in scope).

**Assumptions (agreed):**
- Out of combat only: the game blocks the needed changes in combat. In combat the window stays as it is
  and B still closes it.
- The crafting card shouldn't need a button press with a controller: the recipe is selected and
  scrolled into view when the crafting window opens.
- Banners keep fading on their own; opening the Codex shortly after one replaces clicking it.

**Success:** with only the controller you can reach every tab, press every button, scroll every list and
close the window, and it looks and behaves like Forever's windows (gold focus glow, D-pad, A, B, right
stick).

## What Forever offers (from its UI source)

Forever's interface code is published (Gethe/wow-ui-source, branch `forever`).

- `GamepadMode.FrameControlsManager` (built from `GamepadFrameControlsManagerMixin`,
  `Blizzard_GamepadSharedUtility/FrameControlsManager.lua`) manages controller focus between windows.
  Its own notes: "A frame can subscribe to this by either being a part of ShowUIPanel or by manually
  calling FrameShown on their OnShow event." It has `FrameShown(frame, isPopup, shouldFocusFrame)` and
  `FrameHidden(frame)`, and does nothing unless `InputUtil.IsGamepadUIEnabled()`.
- `SmartNavigation` (a global frame, `Blizzard_GamepadSmartNavigation`) moves the gold focus glow:
  - Focusable pieces are Buttons, EditBoxes, and frames with OnMouseUp/OnMouseDown scripts
    (`SmartNavigation_CanFocusFrame`).
  - Focusing runs a piece's OnEnter (tooltips show).
  - The D-pad moves spatially.
  - The right stick scrolls the panel's scroll frame (`SmartNavigation:SetScrollFrameForFrame`).
  - `SmartNavigation:RefreshButtonGroups(panel)` re-reads a panel's buttons.
  - `SmartNavigation_MarkFrameIgnored(frame)` hides a frame (and its children) from the focus.
- Its `SecureHelper` lets addon code call the wrapped functions when not in combat
  (`issecure() or not IsAddOnRestrictionActive(CombatAddOnRestriction)`). Some internal functions still
  require a secure call, so whether an addon window really gets focus is only known in game.
- The triggers (LT/RT) move focus between open windows. The shoulders (LB/RB) are free at window level.
- `IsUsingGamepad()` and the `GAME_PAD_ACTIVE_CHANGED` event tell whether the controller is in use.

## Design

### Gamepad.lua (new module, loaded after Window.lua and ProfessionTab.lua)

One job: give a Codex frame controller support. Interface:
- `ns.gamepad.attach(frame, opts)`:
  - `opts.scroll`: the frame that scrolls;
  - `opts.popup`: true for the copy box;
  - `opts.onTab(delta)`: LB/RB handler.
- `ns.gamepad.refresh(frame)`: call after a frame redraws its widgets.
- `ns.gamepad.mode(frame)` returns `"forever"`, `"codex"` or `nil`, and `ns.gamepad.debugLines()`.

Each time an attached frame shows, it picks a mode:

1. **Not in use**: no controller UI (`InputUtil.IsGamepadUIEnabled` missing or false, and
   `IsUsingGamepad` missing or false) → nothing changes.
2. **Forever navigation** (preferred), when `GamepadMode.FrameControlsManager.FrameShown` exists and
   not in combat:
   - pcall `FrameShown(frame, opts.popup)`;
   - register the scroll frame;
   - mark decorative pieces ignored;
   - `RefreshButtonGroups` after every redraw;
   - on hide, pcall `FrameHidden(frame)`.

   If the call errors, or no focus lands on a piece of the frame within 0.5 s
   (`SmartNavigation:GetCurrentButton()` is not inside it), it switches to the backup and records why.
3. **Codex navigation** (backup), used when the controller is in use but the manager is missing, it
   refused the frame, or Settings turned Forever's navigation off. The frame takes the controller buttons itself while shown and out of
   combat, using the existing per-press pattern (`EnableGamePadButton`, then `SetPropagateGamePadInput`
   off only for the buttons it uses).
   - **D-pad:** moves a gold highlight (Forever's default focus colour) to the nearest focusable piece in
     that direction, picked by screen centres the same way as SmartNavigation, with a direction cone and
     distance score. Moving to a piece outside the visible scroll area scrolls it into view.
   - **A (PAD1):** clicks the focused piece.
   - **B (PAD2) and Back:** close, as today.
   - **Right stick:** scrolls (`OnGamePadStick` when the client has it, else the D-pad edge scroll alone).
   - Focus shows the piece's tooltip (runs its OnEnter/OnLeave).
   - Buttons it doesn't use pass through to the game.

**In both modes:** LB/RB (PADLSHOULDER/PADRSHOULDER) switch tabs through `opts.onTab`, keeping each
tab's scroll memory. In Forever mode the window catches only these two buttons (per-press propagation);
everything else stays Forever's.

**Combat:** no mode changes, `FrameShown`/`RefreshButtonGroups` or propagation changes in combat. Work is
queued to `PLAYER_REGEN_ENABLED` like the macro queue. B-to-close keeps working as today.

### What the focus stops on

- **Focusable:** tabs, the close button, level arrows, "Back to your level", every `btn` (macro setup,
  Settings ticks and resets, Professions switch), `hit` areas that have an onClick (route steps, talent
  tree nodes), the copy box's text and close button.
- **Skipped** (marked ignored in Forever mode, left out in Codex mode): `icon` widgets and `hit` areas
  with only a tooltip, controller and keyboard mockups, decorative textures.
- Window.lua tags its widgets when it creates them: `f.padSkip = true` for tooltip-only ones.
  Gamepad.lua reads the tag; it doesn't guess.

### Cards and banners

- **Crafting card** (ProfessionGuide.lua): when `IsUsingGamepad()` is true at TRADE_SKILL_SHOW (or the
  first tick after), the guide's recipe is selected and scrolled into view once per window opening,
  with the same code as Show it. It doesn't repeat after the player scrolls away. Mouse users keep
  Show it.
- **Talent card:** no buttons; unchanged.
- **Level-up banner and skill-up cards:** never take controller focus. `ns.showCard`/`ns.showToast`
  remember `{ tab, key, time }` for what the banner was about (skill-up → Professions + profession;
  level-up → This Level at that level). If the Codex is opened within 60 s, it opens there; clicking a
  banner works as before. This applies to mouse openings too.
- **Copy box:** attached with `popup = true`.

### Settings and /codex debug

- Settings gets a CONTROLLER head with one tick, "Use Forever's controller navigation" (default on;
  `db.padNative = false` turns it off and forces Codex navigation).
- `/codex debug`:
  - `controller: Forever navigation | Codex navigation (<why>) | not in use`
  - the last error the backup caught.

## Testing

Mock client (`tests/wowmock.lua`), all optional APIs (gone in the minimal client):
- `GamepadMode.FrameControlsManager` with `FrameShown`/`FrameHidden` recording frames, and a switch
  that makes `FrameShown` error.
- `SmartNavigation` with `RefreshButtonGroups`, `SetScrollFrameForFrame`, `GetCurrentButton` (the first
  focusable child of the last shown frame), and a switch for "focus never lands".
- `SmartNavigation_MarkFrameIgnored` recording frames.
- `InputUtil.IsGamepadUIEnabled`, `IsUsingGamepad` (`MOCK.gamepad`), `GAME_PAD_ACTIVE_CHANGED`.
- `MOCK.press(frame, button)` fires OnGamePadButtonDown, honouring propagation.

Scenarios, every class, full and minimal:
1. **Forever mode:**
   - opening calls `FrameShown(window)`;
   - a tab switch refreshes the button groups;
   - the scroll frame is registered;
   - tooltip-only widgets are ignored and buttons aren't;
   - closing calls `FrameHidden`;
   - debug says "Forever navigation".
2. **Backup:** with `FrameShown` erroring, and again with focus never landing:
   - the D-pad moves the highlight to the expected button;
   - A on Settings ticks a box;
   - moving past the bottom scrolls;
   - LB/RB switch tabs;
   - B closes;
   - debug gives the reason.
3. **Not in use:** no calls into the mocks; existing mouse scenarios unchanged.
4. **Combat:** opening in combat makes no protected calls; mode set up after `PLAYER_REGEN_ENABLED`.
5. **Crafting:** with `MOCK.gamepad`, the recipe is selected and scrolled once per opening and not
   again after scrolling away; without it, nothing automatic.
6. **Banners:** open within 60 s of a skill-up card → Professions tab on that profession; after 60 s →
   normal.
7. **Copy box:** attached as a popup in Forever mode; backup works too.

In game (offline tests can't prove Forever accepts an addon window):
- turn on the controller UI;
- open the Codex and look for the gold glow on it;
- D-pad around, A on tabs and buttons, LB/RB, right stick, B;
- open the crafting window on the controller;
- send a `/codex debug` screenshot showing the mode.

## Risks

- Forever's controller code is Blizzard's and may change between builds: the backup covers a missing or
  refusing manager; `/codex debug` shows which mode ran and why.
- Taint: Forever's functions are only called out of combat and through pcall. If the game still shows
  "action blocked" messages in testing, untick "Use Forever's controller navigation" in Settings (Codex
  navigation only), and the default can flip in a later release.
- Two navigations fighting over the D-pad: in Forever mode the Codex catches only LB/RB; in Codex mode
  Forever never gets the frame.

## Out of scope

- Opening and closing the Codex from the controller beyond the existing key binding.
- Controller support for the minimap button and addon compartment.
- Focus on banners and cards (they'd steal focus from the character mid-fight).
