# Polish pass: minimap line, progress, Quests tab, pace and Stats

Date: 2026-11-13. Follows `2026-11-12-guide-parity-design.md`, from the owner's in-game screenshots
of v0.21.1-24-ge32a049 (Duskwood, level 25 Protection Warrior).

## What the owner asked, and what we agreed

| Feedback | Decision |
|---|---|
| The minimap line is straight; can it route? | Add-ons can't read the game's terrain or pathing. Zygor routes through a hand-made graph (zone border crossings, boats, inns, flight paths) and draws straight dots between those points; RXP draws lines its writers traced by hand. We draw the line through every waypoint the route already knows (way-in points, a trip's flight master, road legs). A road-waypoint network is out of scope here. |
| The fainter second line is confusing | Removed. The numbered next-step pins stay. |
| Our edge arrow sits on the game's own waypoint arrow | Ours hides while the game's waypoint marks the same spot. |
| "11 of 89 steps, 0 of 33 quests turned in": right? | Both are right; they measure different things. Every progress figure now counts steps; turn-ins stay as a second line in the bar's tooltip. |
| Hard to tell which setup options are on | Setup rows become lit choices (segments) and checkboxes. |
| The guide list is a wall of buttons | Guides become quest-log rows with a step progress bar and one status tag. |
| Stats needs a big visual upgrade | Headline tiles, bars for level splits, gold and zones, activity tiles, one session/character switch. |
| Pace may be inaccurate | Found: every /reload restarts the level as "(part)", This Level and Stats count separately, and kills depend on an English chat line. Fixed by reading Stats' saved per-level records, marking a level counted from partway in, and building the kill pattern from the client's own string. |

Mockups shown in the session and approved: the Quests tab (setup rows and guide rows), the Stats tab and
the This Level pace card. Phase order approved: 1 minimap and progress, 2 Quests tab, 3 pace accuracy
and the This Level card, 4 Stats tab visuals.

## Global constraints

- WoW: Forever client, `## Interface: 16001`, Lua 5.1; runtime text ASCII only (no check-mark or
  arrow characters: use textures or ASCII); no new globals beyond `LevelingCodex*` frames.
- `pcall` every non-core `RegisterEvent`; guard every non-core API; probe art with `ns.art.hasFile`
  and fall back to flat colour; never touch the combat log or Blizzard popups.
- Everything works with empty SavedVariables (`ns.settingsLost`).
- Keep the guide's look: Codex cards, Morpheus headings, the Forever teal theme; Blizzard pieces
  where they exist (red panel buttons, the check box, quest-log style rows, the XP bar's colours).
- The step window and controller navigation keep working: every clickable keeps a `codexLabel`, so
  the harness and Forever's navigation find it.
- Harness passes (`python tests/run.py`); `blocked-report` fails only in worktrees.

## Phase 1: the minimap line and progress

### 1.1 The line through known waypoints

The current pin and its dots follow `ns.questArrowGoal()` as today. The line becomes a chain:

- goal `kind == "step"` and the step has a `path` whose current point is the goal: the goal, then
  the path's remaining points in order, then the step's own spot. A new `Q.pathRest(step)` (Quests.lua)
  returns those spots after the current point, ending with the step (`{}` when the step has no path
  or you're past it).
- `kind == "leg"` (a flight master or a road waypoint), `"spawn"`, `"corpse"`, or a step without a
  path: just the goal.

Dots: 3 px gold every 10 px along each segment from you through the chain, alpha 0.85, fading over
the last 20 px before the rim and hidden beyond it; the glow (every fourth dot bright, the rest at
60%, six steps a second) runs along the whole chain. Each bend (an intermediate point that is on the
minimap) gets a 5 px gold dot at alpha 1. A segment entirely outside the rim draws nothing. Arrival:
when you're within `Q.arrived()` of the chain's last spot (not a `leg`), no dots, and the pin pulses
once as today; near an intermediate point the arrow moves on to the next point by itself.

### 1.2 No second line

`pins.ahead` and its 48 dots go. The next two steps keep their 10 px numbered pins (alpha 0.8 on the
minimap, 0.4 on the rim when off it), with their hover tooltips.

### 1.3 No double edge arrow

QuestGuide.lua exposes `ns.questMapPinSpot()`: `{ map, x, y }` (0-1 coordinates) of the user
waypoint the Codex set, while it is still the game's user waypoint; else nil. Our edge arrow
(`pins.edge`) hides when the goal is a `kind == "step"` goal and that spot equals the goal's
(same map, |dx| and |dy| <= 0.0001): the game's own waypoint arrow already sits on the rim there. The
dots still run to the rim. Ours shows for a flight master, a nearest spawn, a corpse, with
Settings > Pin the step on the map off, or when the player placed their own waypoint. The on-minimap
pin stays in every case (it carries the step's icon).

### 1.4 One progress measure

- `Q.sectionProgress(section)` returns steps: `Q.stepProgress(section)` (passed = done, skipped or
  deferred; total = rows not filtered, grey or cut). A new `Q.turninProgress(section)` keeps the
  old turn-in count.
- `Q.sectionStatus` "done" = total > 0 and passed == total.
- The guide list's "% done", band headers' "M done" and the Guides page use steps.
- The step bar's tooltip: line 1 `"<Guide>: N of M steps done (P%)"`, line 2
  `"T of U quests turned in"`, line 3 `"Click to see the route."`.

## Phase 2: the Quests tab

### 2.1 Setup card

Three labelled rows (label column 92 px) above the Done button:

- **Pace**: segments `Fastest | Every quest`. Fastest is lit when `questKeepGrey` and `questOptional`
  are both off, Every quest when both are on; mixed lights neither and adds the note
  "Custom: see Settings".
- **Dungeons**: segments `Recommended | All | None`, plus a fourth lit segment `Your picks (N)` shown
  only when the plan matches none of the three. All = `db.questDungeons`; None = no run planned and
  `questDungeons` off; Recommended = the planned set equals `Q.recommendedRuns()`; N = planned runs.
  Picking a segment does what the buttons do now (`setPlans`, `db.questDungeons`).
- **Helpers**: three check boxes (`U.check`): Auto-accept, Auto turn-in, Auto-fly and bind, each
  showing its `db` key.

A new widget `U.segments(x, y, w, labels, lit, onPick, tips)` (Window.lua) draws one row: a lit
segment is the red panel button kept lit with a 1 px gold inner edge, gold label and the game's
check-box tick texture (`Interface\Buttons\UI-CheckBox-Check`, probed; without it the label alone)
at its left; an unlit segment is a flat dim plate (`C.btnOff`) with soft ink and a hover highlight.
Each segment is a pooled Button with `codexLabel` = its label.

### 2.2 Guide rows

The Guides sub-tab lists each guide as a row 36 px tall instead of a button:

- a 3 px left edge: gold for the current guide, teal for a suggested one, none otherwise; the current
  row also gets a faint accent wash;
- the title (gold current, white open or suggested, grey later, done or outleveled), the level range
  right-aligned, a 4 px step progress bar under the title (teal fill on a dark track);
- one tag at the right: Current, Suggested, Side (alternate), Later, Done, Outleveled, with the
  percentage for Current, Side and Later when above 0;
- the row is a pooled Button (`codexLabel` = the guide title, hover highlight, tooltip as today);
  clicking opens the guide's page as today.

Band headers become a fold row: the game's plus/minus button texture
(`Interface\Buttons\UI-PlusButton-Up` / `UI-MinusButton-Up`, probed; else "+"/"-" text), "LEVELS 20-30"
in gold and "8 guides, 1 done" in soft ink; `codexLabel` keeps today's text
("+ LEVELS 20-30: 8 guides, 1 done") for the harness and controllers. Dungeons, Special quest chains
and Class quests use the same rows (dungeon tags: Planned / Not planned); the dungeon plan buttons
become `U.segments` (Recommended | All | None).

## Phase 3: pace accuracy and the This Level card

### 3.1 One source

The This Level tab's YOUR PACE card reads `ns.stats` per-level records (`levels[lvl]`: seconds, xp,
questXP, killXP, rested, quests, kills, deaths) for the level it shows. Pace.lua keeps only this
session's XP rate (`ns.paceRate()` = XP per hour since login, nil before any gain) and stops writing
`charDB.paceLog`. With `ns.settingsLost` the card says "Counting since you logged in".

### 3.2 Levels counted from partway in

When Stats first creates a level record while you're already into that level (`UnitXP / UnitXPMax`
above 2%), it stores `fromPct` (whole percent). Splits and the card show "(counted from N%)".

### 3.3 Kills from the client's own words

Pace builds its kill pattern from `COMBATLOG_XPGAIN_FIRSTPERSON` (e.g. "%s dies, you gain %d
experience."): magic characters escaped, `%s` -> `(.+)`, `%d` -> `([%d,%.]+)`, not anchored at the end
(rested and group-bonus text follow). Without that global: the English "(.+) dies, you gain ([%d,%.]+)
experience". `/codex debug` adds `pace: last XP line "<text>" -> kill N XP` or `-> not counted`.

### 3.4 The card

- An XP bar (the game's XP purple 0.58, 0.31, 0.75; rested in blue 0.25, 0.4, 0.85 from the current XP
  up to `GetXPExhaustion`, capped at the level's end), "Level 25: 21,400 / 34,000 XP" above left and
  "Level 26 in about 41 min" above right (from `ns.paceRate()`; hidden without a rate).
- Under it: "32 min on this level (all sessions)" and "18,400 XP per hour this session, 4,100 rested".
- Three chips: Quests (XP, turn-ins), Kills (XP, kills), Other (XP), each with its colour square
  (quests 0.88, 0.7, 0.29; kills 0.77, 0.33, 0.29; other 0.36, 0.45, 0.46).
- "Last levels": up to three earlier levels with a time bar (scaled to the longest of the three) and
  "1 h 24, 9 quests, 70 kills".
- Viewing another level with the arrows shows that level's record (no XP bar or rate), or "No stats
  for level N yet."

## Phase 4: the Stats tab

- Header: "Stats" and a `U.segments` switch `This session | This character` (character by default,
  remembered for the session); with `ns.settingsLost` the switch is replaced by the note.
- Four tiles: Level N so far (time, all sessions), XP per hour (this session), Next level in (with XP
  to go), Gold per hour (net this session, in coin colours).
- LEVEL SPLITS: the last 10 levels (Show all levels), each a row "25 now" / "24", a stacked bar whose
  length is its time against the longest shown and whose segments are quest, kill and other XP (the
  chip colours), the time at the right; a legend line above; hover: time, XP by source, quests,
  kills, deaths, net gold, "(counted from N%)".
- GOLD EARNED and GOLD SPENT side by side, each with its total; one row per source that moved money,
  a bar against the column's largest, the amount in coin colours; "Nothing yet" when empty.
- ACTIVITY: tiles four to a row: Quests, Kills, Deaths, Flights (with time in the air), Hearthstone,
  Dungeon runs, Bosses, Played (from your last /played, when known).
- ZONES: the top 8 (Show all zones), a bar against the longest, "1 h 10, 9 quests" at the right.
- Reset stats stays at the bottom (two clicks within 5 s).
- Dark Codex cards (`U.box` with a dark fill) so the bars read; section headings in the label style.

## Testing

Player-level scenarios in `tests/scenarios.lua` (TDD, each failing first):

- Phase 1: the dots bend through a step's way-in points (`questEntrancePath`'s step) and a bend dot
  shows; no `pins.ahead`; the edge arrow hides while the Codex's map pin marks the goal and shows with
  `noQuestMapPin`; guide list % and the bar tooltip use steps with the turn-in line.
- Phase 2: segments light the matching option for each `db` state (including Custom and Your picks),
  clicking a segment sets it; check boxes reflect the helpers; guide rows carry the title, range,
  tag and bar; band fold rows keep their labels; the minimal client still draws (no textures).
- Phase 3: a `/reload` (fresh Lua state with the same SavedVariables) keeps the level's time and
  counts; a level started partway shows "counted from"; kill lines with rested and group text and a
  non-English `COMBATLOG_XPGAIN_FIRSTPERSON` count; the debug line; lost SavedVariables say so.
- Phase 4: the switch changes the figures; tiles, splits with segments and hover, gold columns hiding
  zero sources, activity tiles, zones, reset; the tab row still fits.

## Out of scope

- A road and mountain-pass waypoint network (Zygor-style border crossings for every zone pair),
  which would be our own data recorded in game; true terrain pathfinding (not possible for add-ons).
- Changing or replacing the game's own waypoint or minimap icons.
