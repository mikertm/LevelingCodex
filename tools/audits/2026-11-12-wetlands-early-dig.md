# 2026-11-12: Early Wetlands (20-25), second pass: the dig

Section: `wetlands-early` in `QuestAlternateData.lua` ("Wetlands: The Green Belt and Coast", levels 20-25). Follows `2026-11-11-wetlands-early.md`. The chapter is still unverified.

## Why

The owner sent a screenshot from the Whelgar Excavation Site. Their level 24 Warrior had just turned in In Search of The Excavation Team (305) and taken Ormer's Revenge (294), and Prospector Whelgar offered **Uncovering the Past (299)**. The chapter didn't route it. The 11-11 audit had left it out because QuestieDB gives it required level 25 (quest level 28). The game offered it at 24, so that minimum is wrong for Forever.

## Sources

- **In game** (owner's screenshot, 2026-11-12): Whelgar offers 299 to a level 24.
- **Guide A** (local copy, see `2026-11-10-guide-cross-reference.md`). Only quest IDs, grouping, order and object positions were used, never its text.
  - Its Hunter versions of "23-24 Wetlands" (the speedrun and the dungeon guide) take 299 at the dig on arrival, then 294, 295 with the fragments, Sarltooth (296), and both turn-ins.
  - "22-26 Wetlands Mage AoE" takes 295 and 299 at about 25.
  - The non-Hunter speedrun leaves 295, 296 and 299 for "27-29 Wetlands/Excavation Site". That chapter also routes Whelgar's Forever follow-up, Understanding Our Present (98216), and marks it as needing a group.
- [games.gg Wetlands guide](https://games.gg/world-of-warcraft/guides/wow-forever-wetlands-leveling-guide/): Uncovering the Past and Ormer's Revenge at "about 24-27", the Scytheclaws and Razormaws together with the relics.
- [Bind on Forever: Wetlands](https://bindonforever.com/zones/wetlands): lists 299 (level 27), 295 (27) and 296 (29), but routes none of them. It gives no minimum levels.
- [Wowhead Forever, quest 299](https://www.wowhead.com/forever/quest=299/uncovering-the-past): the follow-up is Understanding Our Present. It gives no minimum level.
- `tools/questfacts.py` (QuestieDB Forever):
  - Fragments, all inside the dig: Ados (Ancient Relic, 34.7, 48.3 and 34.2, 50.4), Modr (Ancient Relic, 34.3, 45.1 and 35.2, 51.5), Golm (Ancient Relic, 35.0, 46.1) and Neru (Loose Soil, 34.0, 45.7 and 33.3, 51.4).
  - Raptors in the dig: Mottled Scytheclaws (25-26, 14 spawns from 32.0 to 35.7, 44 to 51) and Mottled Razormaws (26-27, 9 spawns around 33.6, 48.1).
  - Sarltooth (29), a normal mob, at 33.3, 51.5.

## Full gap check (20-26 Wetlands quests against the chapter)

Every Alliance Wetlands quest from `questfacts.py zone Wetlands` with quest level 26 or lower, plus the ones at the dig:

| Quest | Status |
|---|---|
| 463, 276, 277, 279, 281, 284, 285, 286, 98189, 98197, 98282, 470, 484, 305, 306, 294, 288, 943, 98461 | In the chapter (11-11 pass) |
| **299 Uncovering the Past** | **Added** (this pass) |
| **295 Ormer's Revenge (2)** | **Added** (this pass). Same NPC as 294, same dig as the fragments |
| 296 Ormer's Revenge (3), Sarltooth | Left for the 26-30 route: Sarltooth is level 29 |
| 98216 Understanding Our Present (Forever, 31) | Left out: guide A marks the Goaz Warder as a group fight. Also missing from the 26-30 route (see below) |
| 275 Blisters on the Land (26) | Left out, unchanged. Its Fen Creepers are by the raptors, but the turn-in is Rethiel in the east, and the chapter ends in Menethil. The 26-30 route takes it |
| 471 Apprentice's Duties (26) | Left out, unchanged. Its Giant Crocolisks (25-26) sit by the cursed wreck, which the 26-30 route visits |
| 98190 A Friend of the Family (25) | Left out, unchanged. The owner took it: it ends with Bolvar in Stormwind, and the 26-30 route turns it in there. A turn-in at the end of the Duskwood route (which also ends in Stormwind) needs the route audit to understand a quest the main route picks up later, so it waits |
| 98245, 98246 Howin (29) | Left out, unchanged: Raptor Ridge is 27-29 |
| 469 Daily Delivery | Left out, unchanged: guide A marks it skip in every version |
| 468, 455, 98459, 1132, 274 | Left out, unchanged: they start outside the Wetlands or run the wrong way (274 starts at Dun Modr, needs a Loch Modan quest and ends in Loch Modan) |

## Data changes (for mirroring into the guide pages)

`QuestData.lua`:

- `q(299, "Uncovering the Past", 28, 25)` becomes `q(299, "Uncovering the Past", 28, 24)`, with a comment: QuestieDB says 25, but the game offered it at 24. The 26-30 route is unaffected: it takes 299 at 26 or later.

`QuestAlternateData.lua`, `wetlands-early`, at the dig. Steps in route order (new ones in bold):

1. `accept(294, ormer)`, then `finish(305, merrin)` and `accept(306, merrin)` (unchanged).
2. **`accept(299, whelgar)`**, on arrival: Whelgar stands beside Merrin in the cave, and the dig lies on the way west to the raptors. New local `whelgar` (38.81, 52.39).
3. Flagongut's Fossil in the same cave (unchanged).
4. Ormer's first hunt at the raptor fields now also shows 299's progress. The text says to loot any Ancient Relic or Loose Soil passed on the way through the dig, and that the rest wait for Ormer's next hunt.
5. The raptor-field grind check is now level 24 (was 22, for The Third Fleet): Ormer's next hunt and the rest of the fragments are among level 25-27 raptors. The Third Fleet's level 22 is still covered.
6. `finish(294, ormer)`: if Whelgar had no quest on the way in (299 needs level 24), take it from him now.
7. **`accept(295, ormer)`**: the Scytheclaws (25-26) and Razormaws (26-27) are in the dig itself.
8. **`objective(299)`** at 34.6, 47.5 for the fragments still needed, with four tour `points` (34.6, 45.6; 34.7, 48.3; 34.2, 50.4; 35.2, 51.4), shown with 295's progress. The arrow visits the relic spots in turn. The text warns that Sarltooth (29) roams the south end near 33, 51. The Neru spot at 33.3, 51.4 is left off the tour because Sarltooth stands there.
9. **`objective(295)`** at 33.9, 47.5, shown with 299's progress.
10. **`finish(295, ormer)`**: his last hunt, Sarltooth, is for the later chapter. Ormer is nearer the dig than the cave, so he comes first.
11. **`finish(299, whelgar)`** in the cave: his next quest needs a group, so leave it. The hearth follows.

- New helper `tour(step, ...)`: sets a step's `points`. This is the first route data to use `points`.
- Unchanged: the chapter ID, title, levels (20-25), `suggest` list, the hearth leg and the final level 23 check.

**Order fix (same day, owner's report).** The first version took 299 only after Ormer's first hunt, so a player who had just stood beside Whelgar walked back to the cave for it, and crossed the dig twice without the quest. The pickup now comes on arrival, fragments passed on the way west count, and Ormer's turn-in comes before Whelgar's on the way out.

Cost: the second dig round is about 760 yd of walking (Ormer, the four relic spots, the raptor centre, Ormer, Whelgar), plus about 20 kills of level 25-27 raptors, fewer if fragments came on the first pass. It adds two quests worth roughly 2,200 XP each at 24 (the screenshot shows 2,266 for 299), so a player who reaches the dig at 24 should leave it at about 25.

## Gaps noticed in the 26-30 route (not changed here)

- **98216 Understanding Our Present** (Forever, level 31, Whelgar): use the Goaz Stone (item 279996) near the Goaz Warder, on the lower ledge behind Sarltooth (about 35.0, 52.5), kill it and bring back the Titanic Keystone. Guide A routes it in its 27-29 chapter and says to skip it without a group. If added, it should be an optional step after `finish(299, whelgar)`.
- **98190 A Friend of the Family** can come from this chapter as well as the 26-30 route (see the table). A player who carries it into Duskwood passes Bolvar at that route's Stormwind stop.

## Check in game

- The lowest level at which Whelgar offers 299. The route uses 24, as observed; guide A's Hunter chapter suggests 23.
- Whether 295's Razormaws (26-27) are fair at 24-25 for melee classes. If not, raise the grind check to 25, or move 295 to the 26-30 chapter and keep 299.
- The four relic spots on the tour, and whether the Ancient Relics and the Loose Soil respawn quickly.
- Your level when you leave the dig, and at the end of the chapter.

## Results

- `tools/questroute.py audit`: passed (5,449 steps). One new warning: `wetlands-early` step 42, "Uncovering the Past is more than 5 levels above the section's current target". The audit's target level starts at the chapter's 20 and rises only at grind steps, and there is none before the dig. Players reach the dig at 23-24 (the owner was 24), and 299 needs 24, so the warning stays rather than a forced grind before the pickup. The other Wetlands notes are the pre-existing `wetlands` step 8 and 9 distances.
- `tools/questmobs.py --check`: up to date. 295's creatures come from the quest data.
- `tests/run.py`: everything passed except `WARRIOR/full/blocked-report`, which also fails on the unchanged files in this worktree. It matches `LevelingCodex/<file>.lua` in the call stack, and a `.claude/worktrees/<name>` checkout has no `LevelingCodex/` folder.
- New scenario `questWetlandsDig`, from the owner's screenshot (level 24, 294 and 306 just taken). It checks, in order: Accept Uncovering the Past; the raptor hunt showing the fragments; Turn in Ormer's Revenge; Accept Ormer's Revenge (295); the fragment step with the Sarltooth warning; and Ormer's turn-in before Whelgar's. It fails on the chapter before this pass.
