# Questie compatibility design

Many Forever players run Questie next to the Codex. Today the two can fight over the same NPC
windows, and the Codex's step window likely sits on top of Questie's tracker. Questie's database
also knows where every quest mob and object spawns, which the Codex's arrow does not. This design
makes the two addons work side by side and uses Questie's database for a last-mile arrow.

Owner decisions (2026-11-11): side by side plus Questie's data; of the data uses, only the
last-mile arrow (not filling steps that have no position, not an owner audit in `/codex debug`).

## What Questie offers on Forever

- **Questie** (`Questie_Forever.toc`, Interface 16001) has a tracker (`Questie_BaseFrame`, placed
  at Forever's `ObjectiveTrackerFrame` point by default), map and minimap pins, tooltips and
  auto-questing. Auto-accept (`Questie.db.profile.autoAccept.enabled`) and auto-complete
  (`Questie.db.profile.autocomplete`) are off by default; its hold-back key
  (`Questie.db.profile.autoModifier`) is `"shift"` by default (`"ctrl"`, `"alt"`, `"disabled"`).
  Its stable API (`Questie.API`) only offers a ready callback and quest-update callbacks, which
  the Codex does not need: it already refreshes on the quest log events.
- **QuestieDB** is a separate addon that Questie requires. It publishes `LibQuestieDB`, a
  documented library with a contract version (4 today, oldest supported 1):
  `LibQuestieDB.Quest/Npc/Item/Object` (also the globals `QuestDB`, `NpcDB`, `ItemDB`,
  `ObjectDB`) with named getters, `LibQuestieDB.RequireContract(n)`, and
  `LibQuestieDB.Support.Get("ZoneDB").private.areaIdToUiMapId` (a Lua source string that returns
  the AreaId -> UiMapID table; `areaIdToUiMapIdOverride` holds Questie's aliases). Its Forever
  spawns are already in Forever map coordinates (0-100 per zone, keyed by AreaId), the same frame
  the route data uses.

Shapes used here (from QuestieDB's `src/types`):

| Read | Returns |
|---|---|
| `QuestDB.objectives(id)` | `{ [1] = {{npcId, text?, icon}}, [2] = {{objectId, text?, icon}}, [3] = {{itemId, text?, icon}}, [4] = rep, [5] = {{npcIds, baseNpcId, text?, index}}, [6] = spell }`, `{}` when none, nil for an unknown quest |
| `NpcDB.spawns(id)`, `ObjectDB.spawns(id)` | `{ [areaId] = { {x, y, phase?}, ... } }` or nil |
| `ItemDB.npcDrops(id)`, `ItemDB.objectDrops(id)` | id lists or nil |
| `NpcDB.name`, `ObjectDB.name`, `ItemDB.name` | string or nil |

Every table read is a fresh copy. Numeric fields read `0`, not nil, for a known entity.

## Approach

- **Data:** the public `LibQuestieDB` API, read while the player plays. Nothing from QuestieDB is
  shipped or bulk-imported, which keeps to the rule in `docs/prompts/quest-guide.md`. Questie's
  internal modules (richer, already filtered) were rejected because Questie changes them freely;
  shipping a spawn list built from the cached QuestieDB was rejected because it ships GPL data.
- **Step window placement:** beside Questie's tracker while the window is at its default spot.
  A different fixed default when Questie is on was rejected: the tracker grows with the number of
  tracked quests and can still reach it.

## 1. Side by side (Questie loaded)

A new module, `QuestieSupport.lua` (`ns.questie`), reads Questie's state at call time. "Loaded"
means `Questie` is a table with a `db.profile` table. Every read is type-checked; a setting that
is missing or has another shape reads as off.

### Auto-accept and auto-turn-in

- `ns.questie.autoAccept()` is true when `profile.autoAccept` is a table with `enabled == true`,
  or (older Questie) `profile.autoaccept == true`.
- `ns.questie.autoComplete()` is true when `profile.autocomplete == true`.
- In `QuestGuide.lua`, the Codex's accept handling (gossip and greeting picks, `AcceptQuest` on
  `QUEST_DETAIL`) does nothing while `autoAccept()` is true, and its turn-in handling (picks,
  `CompleteQuest`, `GetQuestReward`) does nothing while `autoComplete()` is true. Questie then
  handles the quest; the two never pick different quests from one list.
- The Settings tickboxes stay as they are and add a line under each while Questie handles it:
  "Questie's auto-accept is on, so Questie accepts quests." /
  "Questie's auto-complete is on, so Questie turns quests in."

### Hold-back key

- `ns.questie.modifierHeld()` is true when Questie is loaded and its `autoModifier` key is down
  (`IsShiftKeyDown`, `IsControlKeyDown`, `IsAltKeyDown`; `"disabled"` or anything else: false).
- The Codex holds back when Alt is down or `modifierHeld()` is true, in the list picks **and**
  in `QUEST_DETAIL` / `QUEST_PROGRESS` / `QUEST_COMPLETE`. Today Alt only stops the list picks,
  although both tickbox tooltips already say "Hold Alt to stop it"; this makes them true.
- The tooltips add "(or Questie's key)" while Questie is loaded.

### Step window placement

- `place()` in `QuestGuide.lua` keeps its order: a saved `db.questPosition` wins. Without one,
  if `Questie_BaseFrame` exists and is shown, the window anchors beside it:
  - tracker centre right of the screen centre: window `TOPRIGHT` to the tracker's `TOPLEFT`,
    offset (-12, -40);
  - otherwise: window `TOPLEFT` to the tracker's `TOPRIGHT`, offset (12, -40).
  The 40 px drop keeps the arrow (drawn above the window) beside the tracker header. The window
  stays clamped to the screen. Otherwise the old default applies (`RIGHT`, -48, 80).
- Questie builds its tracker some seconds after login, so placement is re-checked whenever the
  quest guide refreshes, only while there is no saved position, and only re-anchors when the
  result changes (Questie tracker shown/hidden, side). Dragging the window saves a position as
  today and ends this.
- Anchoring to the tracker means the window follows when the player moves Questie's tracker.
  The item and target buttons are placed from the window's screen position, so they catch up at
  the next refresh (as after a drag today).
- The anchor only goes from our frame to Questie's; Questie never anchors to ours, so no loop.

## 2. Last-mile arrow (QuestieDB usable)

### When it applies

All of these hold:

- `LibQuestieDB` is a table, `RequireContract(1)` returns true, the zone table loaded, and
  `db.noNearestSpawn` is not set (Settings > "Point the arrow at the nearest objective
  (QuestieDB)", shown only when QuestieDB is usable; on by default).
- The arrow's goal is a `complete` step with `quest`, `map`, `x`, `y`, the quest is in the log
  and not ready to turn in, and `Q.destination` returns the step itself (no travel leg): the
  player is on the step's map.

### Camp state

- Constants: `CAMP_ENTER = 200`, `CAMP_LEAVE = 300`, `SPAWN_RANGE = 400` yards (first guesses,
  tuned after in-game testing). Distances use the existing `Q.vector` (route extents, else
  `C_Map.GetMapWorldSize`).
- The player enters the camp within `CAMP_ENTER` yards of the step's point and leaves it beyond
  `CAMP_LEAVE` (hysteresis, so the arrow doesn't flip at the edge). The state resets when the
  current step changes.
- Outside the camp the arrow points at the step's point exactly as today.
- Inside the camp the arrow points at the nearest candidate spawn: caption
  `"<name> - <N> yd"`, or the text `"<name> nearby"` without the arrow art within
  `Q.arrived()` (35) yards. With no candidates the arrow behaves as today.

### Candidates

Built once per (step, set of unfinished objective indices) and cached; the 0.25 s ticker only
measures distances.

1. **Needed objectives:** the quest log's unfinished objectives for the quest; for a step with
   `objectiveIndex`, only that one (if it is finished, none).
2. **Database objectives:** from `QuestDB.objectives(quest)`, one entry per row with a display
   name and a list of spawning entities:
   - creature `[1]`: name = row text or `NpcDB.name(npcId)`; spawns of that NPC;
   - object `[2]`: name = row text or `ObjectDB.name(objectId)`; spawns of that object;
   - item `[3]`: name = row text or `ItemDB.name(itemId)`; spawns of every NPC in
     `ItemDB.npcDrops` and every object in `ItemDB.objectDrops`, each labelled with its own name;
   - kill credit `[5]`: name = row text or `NpcDB.name(baseNpcId)`; spawns of every NPC listed.
   Reputation and spell rows have no spawns and are skipped.
3. **Matching:** a database entry is needed when its name (plain, lower case) appears in the
   text of a needed log objective. If any needed log objective matches no entry, every entry
   counts (better a wider search than none).
4. **Spawns:** for each entity, the spawn lists whose AreaId maps to the step's UiMapID (the
   override table wins; a mapping of `0` means no map). Spawns with a non-zero phase are dropped
   unless that entity has no other spawn on the map. Only spawns within `SPAWN_RANGE` yards of
   the step's point are kept, so the arrow stays in the guide's camp.
5. **Caption name:** the spawning NPC or object's name (for an item, who drops it), through
   `ns.plain`.

The AreaId -> UiMapID tables are read once per session: each string is compiled with
`loadstring`, given an empty environment with `setfenv`, and run under `pcall`; anything other
than a table of numbers is ignored.

### Failure

Every LibQuestieDB call goes through `pcall`. The first error, a failed contract check or a
missing zone table turns the last-mile arrow off for the session and records the reason; the
arrow then behaves exactly as today. Nothing is retried in a loop.

## 3. Debug and load order

- `/codex debug` gains a Questie block (`ns.questieDebugLines()`): Questie loaded or not and its
  version (`C_AddOns.GetAddOnMetadata` or `GetAddOnMetadata`), auto-accept / auto-complete,
  hold-back key, tracker found and the window's placement (saved, beside Questie's tracker,
  default); QuestieDB contract and read mode, zone table size, last-mile state (off and why,
  outside the camp, or inside with the candidate count and nearest name).
- Both .toc files get `## OptionalDeps: Questie, QuestieDB` and list `QuestieSupport.lua` after
  `Quests.lua`. They stay byte-identical.
- No new globals. `QuestieSupport.lua` only reads `Questie`, `Questie_BaseFrame` and
  `LibQuestieDB`.

## 4. Testing

- `tests/wowmock.lua` gains an opt-in mock Questie (`Questie.db.profile` with the three settings,
  a `Questie_BaseFrame` that can be shown, hidden and moved) and an opt-in mock `LibQuestieDB`
  (entities with named getters, `RequireContract`, `Support.Get("ZoneDB")` with both strings, a
  switch that makes reads error), plus modifier key state for Shift/Ctrl/Alt.
- Scenarios (`tests/scenarios.lua`), driving only events, clicks and named frames:
  - Questie auto-accept on: no gossip pick, no `AcceptQuest`; off: the Codex acts as today.
    Same for auto-complete and turn-ins.
  - Questie's key (Shift) held: the Codex holds back in lists and the quest window; Alt still
    holds it back with and without Questie.
  - Step window: beside Questie's tracker on the correct side; back to the default spot when
    the tracker is hidden; a dragged position wins; Questie's tracker appearing after login
    moves the window.
  - Last mile: outside the camp the arrow targets the step's point; inside, the nearest spawn
    with its name; leaving past `CAMP_LEAVE` returns to the point; a finished objective drops
    its spawns; an `objectiveIndex` step only uses its objective; item objectives use droppers;
    spawns beyond `SPAWN_RANGE` and on other maps are ignored; the setting turns it off.
  - QuestieDB missing, contract refused, zone table missing, a read that errors: the arrow
    behaves as today and `/codex debug` names the reason; no Lua errors.
  - Every existing run (full/minimal x main/icon/persisted/lost-savedvars) passes without the
    mocks.
- `python tests/run.py` passes with no Lua errors, no non-ASCII runtime text and no leaked
  globals; then `python tools/install.py`.

## Out of scope

- Positions for steps that have none, and positions for Missed quests.
- An owner audit comparing route NPC positions with QuestieDB.
- Questie's map pins, tracker focus, `Questie.API` callbacks and TomTom.
- Changing any Questie setting from the Codex.

## Docs

`CLAUDE.md` (module list, test mocks), `CHANGELOG.md` (next release section), `README.md` and
`CURSEFORGE_DESCRIPTION.md` (one line: works with Questie; with QuestieDB the arrow finds the
nearest objective).
