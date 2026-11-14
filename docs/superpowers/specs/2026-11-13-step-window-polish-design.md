# Step window polish: a richer step card, themed buttons and window comfort

Date: 2026-11-13. Follows `2026-11-13-polish-pass-design.md`. The owner asked for the step window
(`LevelingCodexQuestViewer`) to feel special and fun, and for missing features. Of four idea groups
(celebrate progress, richer step card, window comfort, guide pacing) the owner chose **richer step
card** and **window comfort**, then asked to **upgrade the buttons** too. Mockups shown in the
session and approved: the step card (kill and turn-in steps, compact mode, settings) and button row
A in the Forever colours.

## What we agreed

| Topic | Decision |
|---|---|
| Step types | Colour-coded: a chip before the title, the title in that colour, a 3 px stripe on the window's left edge |
| Goals | Each goal row gets a fill bar; a finished goal turns green and says "done" |
| Up next | Each row gets its step icon and the distance (or zone) at the right |
| Turn-in XP | "+2,100 XP" chip, "levels you up" when it would |
| Portrait | A small 3D model of the step's NPC or target in a gold ring, with a generated NPC data file; the step icon when it can't load |
| Buttons | Option A: a wide themed "Next step" button, small icon buttons for Back, Quests and Hide |
| Theme | Buttons follow the active theme: Forever teal (default), Codex gold |
| Comfort | Window size and background opacity steppers, fade in combat (on by default), a compact mode |
| Not in this pass | Celebrations (stamps, chapter cards, guide-complete scroll) and pacing (time left, turn-in XP strip, session tally) |

## Global constraints

- WoW: Forever, `## Interface: 16001`, Lua 5.1; runtime text ASCII only; no new globals beyond
  `LevelingCodex*` frames; both .toc files stay byte-identical.
- Guard every non-core API (`Q.try`, existence checks); probe art with `ns.art.hasFile` and fall
  back to flat colour; `pcall` non-core events. Works with empty SavedVariables.
- The step window never joins Forever's controller navigation (CLAUDE.md); it stays mouse-driven
  and the Quests tab keeps the controller step controls.
- Secure buttons (item, target) never change in combat; nothing here touches them in combat.
- Every clickable keeps a `codexLabel`: the buttons keep today's labels ("Back", "Next" / "Skip",
  "Quests", "Hide") so the harness and anything else that finds them still does.
- Harness passes (`python tests/run.py`); `WARRIOR/full/blocked-report` fails only in worktrees.

## 1. The step card

### 1.1 Step types

`ns.questStepKind(step)` (QuestMap.lua, next to `ns.questIcon`) returns one kind, and
`ns.questKindStyle(kind)` its chip label and colour:

| Kind | Steps | Chip | Colour (r, g, b) |
|---|---|---|---|
| accept | `accept` | Accept | gold 1, 0.82, 0 |
| turnin | `turnin` | Turn in | green 0.45, 0.85, 0.4 |
| kill | `complete` whose objectives say slain/killed, or that `ns.questMobs` lists with no item objective (the same rule as `ns.questIcon`'s Attack cursor) | Kill | red 0.95, 0.45, 0.4 |
| collect | any other `complete`, `collect`, `buy` | Collect | orange 0.95, 0.65, 0.25 |
| travel | `goto`, `fly`, `getfp`, `boat`, `hearth`, `sethearth` | Travel | blue 0.4, 0.7, 1 |
| dungeon | `dungeon`, `boss`, `plan` | Dungeon / Boss | purple 0.7, 0.55, 1 |
| other | `note`, `train`, `grind`, `abandon` and anything else | the step type's word ("Note", "Train", "Grind", "Abandon") | the theme accent (`C.accent`) |

The window gets a 3 px stripe down its left edge in that colour; the title row starts with the chip
(a small plate in a dark shade of the colour, its label in a light shade) and the title is drawn in
the colour. The title drops the "Accept - " / "Turn in - " / "Complete - " prefix the chip now says
(`Q.label` stays as it is for every other place it's used).

### 1.2 Goal bars

Every goal row in the step detail (quest objectives, item counts, sticky goals) gets a 4 px bar under
its text, filled count / total in the step kind's colour on a dark track. A finished goal shows its
count as "done" in green with a full green bar. Goals under "Also on this loop" use orange bars. A row
without a count (no `n/m`) gets no bar. The existing flash when a count rises stays.

### 1.3 Up next

Each UP NEXT row starts with its step's icon (`ns.questIcon`, 12 px; a gold dot without the art) and
shows at the right the distance to its spot when it's on your map ("340 yd", from `Q.vector`), else
the spot's zone name (`C_Map.GetMapInfo`), else nothing. The distances are refreshed by the window's
existing 0.25 s tick without a full redraw.

### 1.4 Turn-in XP

On a `turnin` step whose quest is in your log, a chip "+N XP" (`ns.thousands`) from
`GetQuestLogRewardXP(questID)` sits under the title, followed by "levels you up" when
`UnitXP + N >= UnitXPMax` and you're below 60. No chip when the API is missing, returns 0 or the
quest isn't in the log.

### 1.5 The portrait

- A 44 px ring left of the title: a `PlayerModel` frame (portrait camera) inside a gold ring texture.
  For accept steps it shows the quest's giver, for turn-in steps its finisher, for kill steps its
  first target creature; other kinds have no portrait (the title starts at the left as today).
- NPC IDs come from a new generated file, `QuestNPCData.lua` (`tools/questnpcs.py`, like
  `QuestMobData.lua`): `ns.questNPCs[questID] = { start = npcID, finish = npcID, mob = npcID }`,
  each only when QuestieDB names a creature (a quest started by an object or an item has no `start`).
  `--check` fails when stale; the harness checks its shape. Loaded in the .toc after
  `QuestMobData.lua`.
- When the model hasn't loaded 1 s after `SetCreature`, there is no ID, or the client has no
  `PlayerModel`, the ring shows the step's icon instead. Settings > Show the NPC portrait
  (`db.noQuestPortrait`).

## 2. Buttons

- Back: a 28 x 24 icon button with the spellbook's previous-page arrow
  (`Interface\Buttons\UI-SpellbookIcon-PrevPage-Up`); Quests: a book icon; Hide: a hide icon. Each
  is a dark plate (`C.btnOff`) with a 1 px theme edge (`C.edge`), the icon in the theme's light ink,
  a hover highlight and a tooltip with its name. Without the art, a "<" / "Q" / "x" label.
- Next: the wide primary button between them, filled with `C.btnOn`, label "Next step" in
  `C.btnOnInk` with a ">" arrow, a 1 px light edge; "Skip run" on a Dungeon-ahead step as today.
  Forever theme = teal, Codex theme = gold (both from the palette, so a theme switch repaints them).
- `codexLabel`s stay "Back", "Next" (or "Skip"), "Quests", "Hide".
- The window's offer button (Return to leveling, Run <dungeon>, Plan <guide>, Set up the guide) gets
  the same primary plate.

## 3. Window comfort

- **Size** (small screens such as laptops): Settings > Step window size, a stepper 50% to 150% in
  10% steps (`db.questViewerScale`, default 100%), applied with `SetScale`; the arrow keeps its own
  size. Ctrl+mouse wheel over the window changes the same setting (the window takes the wheel only
  while Ctrl is held over it, like the arrow, so the wheel zooms the camera otherwise). The guide
  setup card (Quests tab) gets a "Step window" row with the same size stepper and a Compact check
  box, so a player on a small screen meets both on first run. No size is guessed from the screen:
  the game's default UI scale gives every screen the same height, so a laptop can't be told apart.
- **Background opacity**: Settings > Step window background, 20% to 100% (`db.questViewerAlpha`,
  default 100%), applied to the window's background and border only; text, bars and buttons stay
  opaque.
- **Fade in combat**: Settings > Fade the step window in combat (`db.noQuestFade`; on by default).
  PLAYER_REGEN_DISABLED fades the window to 30% over 0.3 s; while in combat the mouse over the window
  brings it back to 100% and leaving fades it again; PLAYER_REGEN_ENABLED restores 100%. Only the
  window's alpha changes (no secure frames, nothing protected), and the item and target buttons are
  separate frames, so they stay as they are.
- **Compact mode**: a small chevron in the window's top-right corner and Settings > Compact step
  window (`db.questCompact`). Compact shows the title row (chip, title, the first unfinished goal's
  count, else the distance), a thin progress bar and the button row; it hides the step text, goals,
  also-on-this-loop, danger warnings, up next, tracked quests and party lines. The window's height
  follows its content, as today.

## 4. Testing

Player-level scenarios in `tests/scenarios.lua`, each failing first:

- Step kinds: an accept, turn-in, kill, collect, travel and dungeon step each show their chip label,
  title colour and stripe colour; the title has no "Complete - " prefix.
- Goal bars: a 6/15 goal's bar is 40% of its track; a finished goal says "done" with a green full bar;
  a goal without a count has no bar.
- Up next: rows show their icon and a distance that changes when you move; a step on another map
  shows its zone name (with `MOCK.mapInfo`).
- XP chip: with `MOCK.rewardXP[id]` a turn-in shows "+N XP", and "levels you up" when
  `MOCK.xp + N >= MOCK.xpMax`; none without the quest in the log.
- Portrait: the mock's `PlayerModel` records `SetCreature`; an accept step shows its giver's ID, a
  kill step its target's; with `MOCK.modelFails` the ring shows the step icon after 1 s; the setting
  hides it; the minimal client (no `PlayerModel`) draws the icon.
- Buttons: the four `codexLabel`s exist and click as before; Next shows "Next step" / "Skip run";
  tooltips name the icon buttons; a theme switch repaints Next.
- Comfort: the size stepper scales the window down to 50%; Ctrl+wheel over the window resizes it and
  the wheel is the camera's otherwise; the setup card's Step window row sets size and compact; the
  opacity stepper changes the background alpha only;
  PLAYER_REGEN_DISABLED fades to 0.3, OnEnter restores 1, OnLeave fades again, PLAYER_REGEN_ENABLED
  restores 1; with the setting off nothing fades; compact mode hides the detail rows and the chevron
  toggles it.
- Data: `QuestNPCData.lua` shape (positive integers, only `start`/`finish`/`mob` keys), and
  `questnpcs.py --check` passes.

## Out of scope

- Celebrations and pacing (not chosen this pass).
- Joining Forever's controller navigation with the step window (CLAUDE.md forbids it).
- Any change to the item and target buttons.
