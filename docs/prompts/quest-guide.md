# Prompt: build the Alliance quest guide (step-by-step 1-60 route)

Paste everything below the line into a new Claude Code session opened in this repo.

---

Build a step-by-step questing guide into Leveling Codex: a Zygor-style route that tells an Alliance player
exactly what to do next (accept, kill, loot, turn in, travel, fly, hearth, train) so they level 1-60 the
efficient way without missing quests. Read `CLAUDE.md` first and follow every rule in it (Lua 5.1, ASCII
runtime text, guarded APIs, `pcall` RegisterEvent, no globals, both .toc identical, harness before every
commit, `tools/install.py` after, never push a tag).

The decisions below are made. Don't ask them again. Ask me only about what this prompt leaves open, and use
`AskUserQuestion` for it. I have limited usage, so work in milestones and stop at the end of each one with a
summary, test results and an in-game checklist.

## Decisions already made

1. **Route source: research.** Build the route by researching published leveling guides and quest databases
   and merging them into the most efficient order. The classic quests are all in Forever. Forever's new
   quests get added as we find data (from the recorder below and from Forever guide sites).
2. **First routes: Human, levels 1-12** (Northshire, Elwynn Forest), **then Westfall and Lakeshire**
   (Redridge Mountains). The rest of the Alliance route to 60 comes later. The data shape must allow
   Dwarf/Gnome, Night Elf and Skyborne starts to be added later without changing code.
3. **New Forever zones: use them where they're faster** than the classic zone for that level range
   (Riverglades at about 35-45 is the obvious one). One route, not two.
4. **Dungeons are optional side steps**, but the route still does a dungeon's quest chain prerequisites
   (the solo pickups and lead-in chains), so a player who decides to run the dungeon already has its quests.
   The run itself, the in-dungeon objectives and the turn-ins that only exist because of the dungeon are
   optional steps that a Settings switch shows or hides. The main route never depends on a dungeon.
5. **Zygor-style UI:** a small always-on step window, a direction arrow, and a Quests tab in `/codex`.

## What's already researched (don't redo it)

**What the client files hold** (wago.tools, product `wowf`, build 1.60.1.70862; `tools/gamedata.py` already
downloads tables from there):
- `QuestV2` has quest IDs only (about 6,600 rows, no names, levels or NPCs). About 2,900 IDs are above 9300,
  and most of those are Forever's new quests. Use it to check that every quest ID in the route exists.
- `QuestObjective` doesn't exist for this product. `QuestPOIBlob`/`QuestPOIPoint` cover only about 25 new
  quests, so the client can't place objectives. Quest names, givers, positions and objectives come from
  research and the recorder.
- Useful tables: `UiMap` (zone IDs: Elwynn 1429, Westfall 1436, Stormwind 1453, Ironforge 1455, Duskwood 1431,
  Redridge 1433, Loch Modan 1432, Wetlands 1437, Darkshore 1439, Riverglades 2548, Shen'dralas 2652,
  Mount Hyjal 2482, Zephras Isle 2521), `UiMapAssignment` (world extents per map, so you can turn map % into
  yards and compute distances without `C_Map.GetWorldPosFromMapPos`), `TaxiNodes` (flight path names and
  positions), `AreaTable`, `AreaPOI`, `QuestSort` (includes Forever's "Camping", "Nightmare Incursions",
  "Blackrock Eruption", "The High Order"), `QuestLine`/`QuestLineXQuest` (for example "Toxic Soil",
  quests 92742-92819, in Westfall/Elwynn/Stormwind).

**What Forever changed for leveling** (from Forever news and guide sites):
- XP curve is unchanged from Classic. More than 1,000 new quests in total.
- Every race's starting zone has new quests, Northshire included. The Wetlands has entirely new questlines.
  There are class weapon quests.
- Camping: the quest "The Great Outdoors" appears around level 5, sends you to a campfire, then to train
  Cooking. Campfires give rest, vendors, repairs and buffs.
- New zones: Riverglades (about 35-45, between Burning Steppes, Redridge and Swamp of Sorrows; Alliance works
  with the Brotherhood of the Horse; its dungeon Krol'dok Stronghold is 40-45), Shen'dralas (between Desolace
  and Feralas, with quests for Maraudon and Razorfen Downs), Mount Hyjal (level range unconfirmed),
  Zephras Isle (Skyborne 1-12). Nine new dungeons, including the Drowned City off Stranglethorn. Every
  classic dungeon got a new loot table.
- Travel: Stormwind Harbor, a ship between Auberdine and Stormwind Harbor, a new Hillsbrad boat stop on the
  Wetlands-Darkshore route.
- Existing Forever quest addons on CurseForge: **ForeverQuest** (Questie-style helper: tracker, map markers,
  minimap guidance, a bundled database of about 3,800 legacy Classic quests) and **AllyRoute**. Look at their
  CurseForge pages to see what players already have. Never copy their code or data.

## Research rules

- **Sources for the order:** free Classic Alliance leveling guides (for example Judgement's Alliance guide on
  warcrafttavern.com, the Wowhead and Icy Veins Classic leveling guides) and Forever route pages
  (warcrafttavern.com/forever/guides/leveling, mobalytics.gg zone level ranges, icy-veins.com/wow-forever).
  Compare several guides per level range and pick the order with the least travel and the most XP per hour.
- **Sources for the facts:** wowhead.com/classic quest pages and warcraft.wiki.gg for quest ID, giver, turn-in
  NPC, coordinates, level, required level, prerequisites, chains, and which race/class can take it.
- Facts (IDs, NPC names, coordinates, levels) are fine to use. **Write every step's text yourself**; never
  paste a guide's prose. Never use paid guides (Zygor, RestedXP), and that includes the Zygor copy under
  `C:\Dev\Starbreak\reference\`: don't open it. Never ship or bulk-import another addon's database (Questie is
  GPL, ForeverQuest and RXP have their own terms); looking up the facts for the quests in our route is fine.
- Write down the sources for each section in `tools/audits/<date>-quests.md`, like the profession audits.
- Classic facts may be stale where Forever changed a zone (all starting zones, Wetlands). Mark those
  sections `verified = false` until I've played them with the recorder, and show "unverified" in the UI.

### How to build the route

1. **A facts tool first:** `tools/questfacts.py`. It downloads Questie's Classic database into `tools/.cache/`
   (not committed, not packaged) and prints facts: `questfacts.py quest 7` (name, level, required level,
   races/classes, giver and turn-in NPC with coordinates, objectives, prerequisites, next in chain) and
   `questfacts.py zone Elwynn` (every Alliance quest that starts there, by level). Questie is
   github.com/Questie/Questie; the field order is `questKeys`/`npcKeys`/`objectKeys` in `Database/QuestieDB.lua`.
   The quest/NPC/object files have moved: `Database/Classic/classicQuestDB.lua` on `master` was a 404 on
   2026-11-08, so find their current path in the repo tree first. Its zone IDs are AreaTable IDs (Elwynn 12,
   Westfall 40, Redridge 44, Stormwind 1519, Duskwood 10) with 0-100 coordinates; map them to our UiMap IDs.
   Parse the data with an empty Lua environment (no io/os), and run Python on downloads with `-I`.
2. **The order:** for each zone, compare at least two free guides (Judgement's Alliance guide on
   warcrafttavern.com, Wowhead's and Icy Veins' Classic guides, plus any Forever route page) and pick the order
   with the least walking: batch pickups, kill objectives together, turn in on the way. Note where the guides
   disagree and why you chose what you did, in the audit file.
3. **The steps:** take each quest's facts from the tool, cross-check anything odd on wowhead.com/classic, and
   write the step text yourself. Include race/class filters (Human class quests in Northshire), the
   Deadmines lead-in chain (Westfall's Defias quests) in the main route and the run itself as optional
   dungeon steps, flight paths (Stormwind, Sentinel Hill, Lakeshire), hearth binds and trainer visits.
4. **Forever's additions in these zones:** the client's `QuestLine` table has "Toxic Soil" (quests
   92742-92819) across Westfall, Elwynn and Stormwind, with objective areas in `QuestPOIBlob`/`QuestPOIPoint`
   (convert with `UiMapAssignment`). "The Great Outdoors" (camping) starts around level 5. Northshire has new
   quests no site lists yet. Add what the client and the Forever sites give you as `forever = true` steps,
   and leave a `note` where the recorder has to fill in the rest.
5. **Check:** every quest ID must be in `QuestV2` (a classic quest missing there was removed from Forever:
   drop it and say so), and the audit must pass.

## Design

Write this up as a short spec in `docs/superpowers/specs/<date>-quest-guide-design.md` (the profession guide
spec there is the model), then a plan in `docs/superpowers/plans/`, then build. Change the design only where
the code or the game says it can't work, and tell me when you do.

### Data: `QuestData.lua` (hand-written, like ProfessionData.lua)

`LevelingCodexQuests = { ALLIANCE = { starts = { HUMAN = "northshire" }, sections = { ... } } }`. A section is
`{ id, title, zone (UiMapID), levels = { from, to }, start (race key or nil = shared), verified, sources,
steps = { ... } }`. A step is one action:

- `type`: `accept`, `complete` (do the objectives), `turnin`, `goto`, `fly` (flight path, named as in
  `TaxiNodes`), `getfp` (learn a flight path), `sethearth`, `hearth`, `boat`, `train` (uses the class guide's
  `train[]` for that level), `buy`, `use`, `grind` (to a level or % of a level), `dungeon` (optional run),
  `note`.
- Fields: `quest` (ID), `name`, `npc`, `map`, `x`, `y` (0-100), `level` (quest level), `min` (required
  level), `text` (ASCII guide text in your own words), `class`/`race` filters (class tokens as in Data.lua),
  `optional`, `dungeon` (name, for the dungeon switch), `chain` (prerequisite quest IDs), `forever = true` for
  quests Forever added, `objectives` (short ASCII labels, used only when the quest log can't tell us).

### Runtime

- **Progress comes from the game, not SavedVariables** (they may not load back). At login and on
  QUEST_ACCEPTED, QUEST_TURNED_IN, QUEST_REMOVED, QUEST_LOG_UPDATE, PLAYER_LEVEL_UP, ZONE_CHANGED_NEW_AREA,
  TAXIMAP_OPENED, work out every step's state: turned in = the quest is flagged complete; accept done = in the
  log or turned in; complete done = objectives finished; goto done = within range, or any later step done.
  The current step is the first one that isn't done, skipped or filtered out. Skips live in `charDB` but
  everything works without them.
- **APIs to guard** (Forever mixes retail and classic; probe both and don't assume either): `C_QuestLog`
  (`IsQuestFlaggedCompleted`, `GetNumQuestLogEntries`, `GetInfo`, `GetQuestIDForLogIndex`,
  `GetQuestObjectives`, `GetMaxNumQuestsCanAccept`), the classic globals (`GetQuestLogTitle` with the quest ID
  at position 8, `GetQuestLogLeaderBoard`, `IsQuestFlaggedCompleted`, `GetQuestsCompleted`), `C_Map`
  (`GetBestMapForUnit`, `GetPlayerMapPosition`, which is nil in instances), `GetPlayerFacing` (nil in
  instances), `C_Map.SetUserWaypoint`/`C_SuperTrack` (use the built-in waypoint pin when it exists),
  `TomTom` (add a waypoint when it's installed). Add a `/codex debug` section listing which of these exist,
  so I can screenshot it from the game.
- **New modules** (add them to both .toc files, `CLAUDE.md`'s file table and module list, and the harness's
  allowed globals): `Quests.lua` (data lookups and step state), `QuestGuide.lua` (the step window
  `LevelingCodexQuestViewer` and the arrow `LevelingCodexQuestArrow`), `QuestTab.lua` (`ns.addTab`).
- **Step window:** movable and lockable, Codex look (parchment, double border, Morpheus heading, `ns.art`
  pieces). Shows the current step with its objectives from the quest log ("Kobold Vermin 4/10"), the next two
  steps, and the section title with level range. Click skips, right-click goes back a step, and a button opens
  the Quests tab. Hides in combat only if I ask for it later. Registered with `ns.gamepad`.
- **Arrow:** points at the current step's coordinates, with distance in yards (from `UiMapAssignment` extents
  generated into the data) and "arrived" when close. Ship the arrow art as a TGA in `media/` and rotate it with
  `SetRotation`; when the texture or `GetPlayerFacing` is missing, show a text direction ("NE, 120 yd")
  instead. Different zone: point at the travel step.
- **Quests tab:** the whole route by section with done/current/next marks, jump to a section (for players who
  are ahead or behind), and a **Missed quests** list: quests from earlier sections that aren't turned in and
  aren't grey yet, so nothing gets missed. Settings: show dungeon steps, show the arrow, lock the window,
  auto-accept and auto-turn-in of guide quests (both off by default; never pick a reward when there's a
  choice, never act in combat).
- **Tie-ins:** a `train` step uses `ns.trainAt`/`nextTrain` so trainer reminders line up with the route, and
  the profession guides' camp objects can show at "The Great Outdoors".

### Recorder (for Forever's new quests and for checking positions)

`/codex record` toggles it. It logs to `LevelingCodexDB.rec`: on QUEST_DETAIL the giver (`UnitName("npc")`)
and your map position; on QUEST_ACCEPTED the quest ID, title, level and objectives; objective progress with
your position when a count goes up (kill and loot areas); QUEST_TURNED_IN with the NPC and position; flight
paths learned and taken; hearth set. SavedVariables are written on exit even if they don't load back, so add
`python tools/questroute.py import` that reads
`<WoW>\_forever_\WTF\Account\*\SavedVariables\LevelingCodex.lua` and prints the log as draft steps. Also
offer the log in the copy box (`ns.showMacroCopy`) as a backup.

### Checks (`tools/questroute.py audit`, also run from the harness through `tools/reference/forever.json`)

Add the quest IDs from `QuestV2`, the UiMap IDs, the TaxiNodes names and the map extents to the reference
(`gamedata.py` TABLES and `build`). Fail on: a quest ID the client doesn't have, an unknown UiMap or flight
path, coordinates outside 0-100, a turn-in before its accept, an accept before its prerequisite is turned in,
more quests in the log at once than the cap (20 unless the game says otherwise), non-ASCII text, a step type
or field that doesn't exist. Warn on: a quest more than 5 levels above you when it's accepted, a step whose
level is grey for the section, a section without sources, a long walk between steps with no travel step.
Harness scenarios (with mock quest log, completed quests, map position and facing in `tests/wowmock.lua`, and
the quest events added to the mock's known events): fresh character at level 1, a character partway through
with quests in the log, a level 25 starting fresh (jumps to a fitting section), skip and back, the arrow with
and without `GetPlayerFacing`, `minimal = true` (most quest APIs missing: the window still shows steps and
never errors), combat, recorder on and off, controller mode.

## Milestones (stop after each one)

1. **Engine and 1-12.** Data shape, `Quests.lua`, step window, arrow, Quests tab, recorder,
   `questfacts.py`, `questroute.py` (import and audit), the reference additions, harness scenarios, and the
   route for levels 1-12: Northshire, then Elwynn Forest up to leaving for Westfall. Run the harness, install,
   and give me an in-game checklist (including a `/codex debug` screenshot of the quest APIs and a recorder
   run).
2. **Westfall and Lakeshire:** Westfall, then Redridge Mountains, with the Deadmines lead-in chain in the main
   route and the run as optional dungeon steps. Note in the audit where Loch Modan or Darkshore would fit,
   for later.
3. **20-30:** Duskwood, the reworked Wetlands, Ashenvale, Stranglethorn, Hillsbrad, as research says.
4. **30-40:** Riverglades where it beats the classic zones, Arathi, Desolace, Shen'dralas, Stranglethorn,
   Dustwallow.
5. **40-50:** Tanaris, Feralas, the Hinterlands, Searing Gorge, Riverglades' end, as research says.
6. **50-60:** Un'Goro, Felwood, Burning Steppes, Western/Eastern Plaguelands, Winterspring, Silithus,
   Mount Hyjal if it's a leveling zone.
7. Release prep: `CHANGELOG.md`, `CURSEFORGE_DESCRIPTION.md`, README. Don't tag without my go-ahead.

Work on a new branch `quest-guide` from `main`. If `enchanting-guide` isn't merged into `main` yet, ask me
whether to branch from it instead.
