# Quest guide milestone 1

Design: [Quest guide design](../specs/2026-11-08-quest-guide-design.md)

1. Create `quest-guide` from the main branch with Enchanting included. Add harness cases for quest start, quest log progress, travel, controller, recorder and absent APIs. Confirm the new scenarios fail before implementation.
2. Extend `tools/gamedata.py` with client quest IDs, zone extents, flight nodes, questline order and mapped client POIs. Regenerate the committed reference against its current build.
3. Build `tools/questfacts.py` on the current QuestieDB layout. Inspect one quest or an Alliance zone, prioritizing Forever records and supporting a Classic comparison. Keep downloaded Lua in the ignored cache and evaluate table data in an isolated Lua environment.
4. Compare Northshire and Elwynn route sources. Author batched quest, training and travel steps in `QuestData.lua`. Include sourced Forever additions and document uncertain objectives, availability and map positions in the dated audit.
5. Implement progress in `Quests.lua`, the window, arrow and recorder in `QuestGuide.lua`, and the route browser in `QuestTab.lua`. Wire the settings, debug output, recorder command and identical manifests. Include arrow art in the installer and package.
6. Implement `tools/questroute.py` for route checks and recorder drafts. Connect the audit to the offline harness and daily game-data checks.
7. Run the full harness, verify the copied build with `tools/install.py`, and stop for in-game testing of the Human 1-12 route.

## Milestone 2

1. Reproduce the missing route on a level 19 Alliance Skyborne and test dungeon filtering.
2. Add shared Westfall and Lakeshire sections from Forever quest facts and free route guides. Record the source and travel choices in the dated audit.
3. Choose a level-appropriate section at login, preferring the character's current zone when ranges overlap. Reuse the existing viewer and dungeon setting.
4. Audit the solo and dungeon paths and run the full harness before committing and installing.
