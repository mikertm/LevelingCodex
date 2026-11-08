# Quest guide design

Leveling Codex guides Alliance players through a single ordered route. The first playable milestone covers the Human start through the road to Westfall. Additional racial starts and shared sections use the same data and renderer. Dungeon prerequisites stay on the main route. Dungeon runs and their dependent objectives and turn-ins respect the dungeon setting.

## Route data and research

Each faction has a table of racial starts and an ordered list of sections. Sections carry stable IDs, level ranges, maps, verification state and sources. Each step contains one action with quest ID, objective labels, position, filters and prerequisite IDs where applicable. Client QuestV2, UiMap, UiMapAssignment and TaxiNodes validate IDs and distances. QuestLine and quest points help locate new chains. Client IDs alone establish presence in the build. Published Forever quest pages and recorder observations establish who offers a quest and how it works. Classic data fills gaps with provenance.

The local facts tool reads specific QuestieDB records from an ignored cache. Route authors compare free guides, write their own instructions and log their sources and routing choices in the audit. Route data ships with the addon. The route remains marked unverified until tested in game.

## Player flow

Quest completion and the live quest log drive progress. Use modern APIs first and fall back to classic calls. A later quest step can establish that earlier travel happened. Manual travel and other actions can be acknowledged, and skip and back work for reviewing a route. Section selection starts from the race and player level when no route activity is known, then retains the selected section for the session. Characters past the available route see the coverage limit and can jump to an earlier section.

Westfall and Lakeshire are shared Alliance sections. At overlapping levels, the current zone takes priority and active quest history breaks ties. Resume active quest keeps the earlier chain steps that later pickups depend on and lists deferred pickups under Missed quests. Ready to turn in comes directly from the live log and can show a waypoint without moving the normal route forward.

The movable step window shows the active action, live objective counts and two upcoming actions. The Quests tab shows section status, earlier eligible unfinished quests and controls for the viewer. Settings control dungeon steps, arrow, lock and optional automation. The arrow uses map extents for distance, facing for rotation and a compass label as fallback. Its pin action can use native waypoints and TomTom. All optional API calls and event registrations are guarded. Quest automation acts only on the current guide quest, outside combat and with zero reward choices for automatic rewards.

The recorder is opt-in per session. It captures quest, objective and travel observations locally and supports both copy-box export and SavedVariables import. The importer emits draft steps for review. Recorder observations may be incomplete when the client omits an API or event.

## Verification

The offline audit checks data types, IDs, maps, bounds, flight paths, action order, prerequisites, ASCII and peak active quests by race and class. The Lua 5.1 harness exercises live quest state, missing APIs, movement, controller, automation and recorder behavior. Run the full harness before commits and verify the installation in the Forever AddOns folder.
