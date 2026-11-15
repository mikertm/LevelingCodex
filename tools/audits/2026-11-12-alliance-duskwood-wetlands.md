# 2026-11-12: Duskwood and Wetlands (21-30) loop and gap audit

Sections:

- `duskwood` (21-27) and `wetlands` (26-30) in `QuestData.lua`.
- `duskwood-late` (25-30) and `southshore` (27-30) in `QuestAlternateData.lua`.

`wetlands-early` (20-25) was audited this morning (`2026-11-12-wetlands-early-dig.md`) and is not changed here. All four sections stay unverified until someone plays them.

This pass follows the model of the Wetlands dig audit. It looks for two things:

- **Loops:** walking that a different order removes.
- **Gaps:** quests at NPCs or places the route already visits, which the route never offers.

Earlier decisions in `2026-11-08-duskwood.md`, `2026-11-08-wetlands.md`, `2026-11-10-westfall-redridge-duskwood-gaps.md`, `2026-11-10-darkshore-ashenvale-wetlands-gaps.md`, `2026-11-11-wetlands-early.md` and `2026-11-12-wetlands-early-dig.md` are kept unless noted below.

## Sources

- **Guide A** (the local RXP Forever copy; see `2026-11-10-guide-cross-reference.md`). Only quest IDs, grouping, order and positions were used, never its text. Chapters read:
  - "24-27 Duskwood/Redridge" and "24-27 Duskwood/Redridge/Stockades"
  - "27-29 Wetlands/Hillsbrad" and "27-29 Wetlands/Excavation Site"
  - "29-32 Duskwood" and "30-32 Duskwood/Gnomeregan"
  - the Mage AoE "21-22 Duskwood", "22-26 Wetlands" and "26-31 Duskwood Part 2"
- **Zygor Forever guides (quest-ID gap check only).** We used the owner's prepared list of quest IDs that Zygor's 1-30 guides accept and our route does not, and the level band of each guide. We used no text, step order or code. None of the Zygor-only IDs ("also in RXP: no") are in these zones.
- [Wowhead Forever](https://www.wowhead.com/forever/) quest pages for [98216](https://www.wowhead.com/forever/quest=98216), [98230](https://www.wowhead.com/forever/quest=98230), [98240](https://www.wowhead.com/forever/quest=98240), [98059](https://www.wowhead.com/forever/quest=98059) and [98071](https://www.wowhead.com/forever/quest=98071), and the item page for [Soothing Spices](https://www.wowhead.com/forever/item=3713/soothing-spices).
  - 98240 is listed in a series after Crocs of the Sky (98072).
  - 98071's case goes to the fireplace at the bottom of the Dun Garok fort.
- [questing.wiki Forever](https://questing.wiki/wow-forever/quests/) pages: [469](https://questing.wiki/wow-forever/quests/469/), [683](https://questing.wiki/wow-forever/quests/683/), [686](https://questing.wiki/wow-forever/quests/686/), [225](https://questing.wiki/wow-forever/quests/225/), [227](https://questing.wiki/wow-forever/quests/227/), [343](https://questing.wiki/wow-forever/quests/343/), [538](https://questing.wiki/wow-forever/quests/538/), [555](https://questing.wiki/wow-forever/quests/555/), [98071](https://questing.wiki/wow-forever/quests/98071/), [98230](https://questing.wiki/wow-forever/quests/98230/) and [98240](https://questing.wiki/wow-forever/quests/98240/). They give XP rewards, minimum levels and prerequisites:
  - 98240 requires Crocs of the Sky (98072).
  - 98071 is Alliance, with a minimum level of 23 and a 2,200 XP reward.
- [Bind on Forever: Hillsbrad Foothills](https://bindonforever.com/zones/hillsbrad-foothills) lists Hillsbrad's Hoard (98059) and Brewer's Trade (98071) as Alliance level 27 quests, without positions.
- `tools/questfacts.py` (QuestieDB Forever) gives levels, givers and spawns:
  - Leech and Cave Stalkers inside Thelgen Rock (46-51, 58-63).
  - Fen Creepers, Fenrunners and Trappers.
  - Einar Stonegrip (49.92, 39.37) and Harlo Barnaby.
  - Foggy MacKreel (Arathi 43.24, 92.64) and Captain McManus (Hillsbrad 46.43, 50.2).
  - The Dun Garok guards (69-73, 74-82) and the Hillsbrad Town Registry (29.52, 41.53, in the Hillsbrad Fields town hall).
  - Snapjaws (Hillsbrad 66-68, 16-36, levels 30-31).
- `tools/questloops.py` with the late-pickup and alternate-chapter checks (the extended copy from the coordinating worktree), and `tools/questroute.py audit`.

## What was wrong

1. **Stormwind, Duskwood to Wetlands.** The Duskwood route turned in Seeking Wisdom (269) to Farthing in the Cathedral, then An Old History Book (337) at the Keep library. The Wetlands route then sent you back to Farthing for The Doomed Fleet (270) before the tram, which is beside the Keep. With the book, that meant about 1,360 yd (Cathedral, Keep, Cathedral, tram) instead of about 660. The 337 turn-in now follows 270 at the start of `wetlands`.
   - It doesn't sit at the end of `duskwood` because a pickup after Duskwood's hearth step breaks the catch-up. `questDuskwoodHandoff` marks every Duskwood quest done. A turned-in pickup after the hearth then marks the hearth as passed: a run with 270 there failed with "ASSERT: at level 26 the route leads back to the flight path".
2. **Menethil, first visit.**
   - Fitzsimmons' mead (288) was taken after the bind at the inn, and the route came back to the inn later to buy the mead.
   - The harbor timber, the young crocolisks and the murlocs were three separate trips out of town, each returning to Valstag, Halloran or Karl. The early chapter already does them in one loop. The return between them cost about 1,070 yd.
3. **Howin, twice.** Howin offers Death to the Dragonmaw (98291) as soon as both Razormaw quests are turned in (guide A takes it there). The route took it on a separate stop between Angerfang and Ironbeard's Tomb, about 140 yd out of the way.
4. **Thelgen Rock, out of order.** After Dun Modr the route went south past the Green Belt to Thelgen Rock, back north to Rethiel and Dragonmaw Retreat, then west to Howin. The cave is on the road between the retreat and Howin, so doing it last saves about 460 yd. Its waypoint (48.7, 62.4) is inside the cave, and the arrow led there over the rock. It now goes through the mouth at 52.6, 62.9, the spot the early chapter uses, with `path`.
5. **The Greenwarden (463), steps 8 and 9.** The optional pickup sat between Howin and Rethiel. With Show optional quests on, a player coming in from Dun Algaz was sent about 1,660 yd west to Menethil and 1,950 yd back. These were the two old route-audit warnings.
6. **Last Menethil visit.** It went from Glorin to Tarrel on the north bridge, then back into the keep and out to the north gate. Taking Caitlin, Sida and the keep first, then Tarrel and the north gate, saves about 170 yd.
7. **Southshore.** The chapter starts at 27, but its first quest wanted level 29, so a player arriving at 27-28 had nothing to do. Down the Coast was also taken after the level check, a second stop at Farren.
8. **Gaps on the walk:**
   - Daily Delivery (469): Einar stands 80 yd from Howin.
   - The optional Goaz Warder quest (98216) sits beside Sarltooth.
   - MacKreel's Moonshine (647): MacKreel stands beside the Waterlogged Letter.
   - Sara Balloo's two Ironforge errands (683, 686) follow the letter route already takes.
   - The two Ladimore talk quests (225, 227) are on the last Raven Hill pass.
   - Captain Stoutfist's statuette for Bolvar (98190) is carried from the early chapter.
   - Speaking of Fortitude (343): Brother Kristoff stands on the walk from the Stormwind gryphons to Farthing.

## Findings

| Quest | Status | Reason | RXP | Zygor |
|---|---|---|---|---|
| 269, 270, 337 (Stormwind) | Reordered | Duskwood ends at Farthing (269). The Wetlands route starts with 270 at the same spot, then 337 at the Keep library on the way to the tram (fix 1) | yes | in route |
| 343 Speaking of Fortitude | Added, optional | Coordinator's suggestion, checked: Brother Kristoff (Stormwind 55.04, 54.16) is on the walk from the gryphons to Farthing (about 2 yd out of the way), and Milton Sheaf takes it at the library. Only 195 XP, and players without the history book have no other reason to visit the library (about 310 yd more), so it is optional, like the other Stormwind library errand (97234). The pickup ends `duskwood` and the turn-in opens `wetlands`. Its follow-ups (344-347: Northshire, Redridge, the Rethban Caverns) stay out | yes | yes |
| 288 The Third Fleet (loop finding) | Reordered | Fitzsimmons first, then bind and buy the mead in one inn visit (fix 2) | yes | in route |
| 98197, 279, 484 (coast) | Reordered | One loop: timber, murlocs, young crocolisks, then the three turn-ins (fix 2) | yes | in route |
| 98291 Death to the Dragonmaw (loop finding) | Reordered | Taken at Howin after the Razormaw turn-ins; the Angerfang stop is gone (fix 3) | yes | in route |
| 98282 Alchemical Hazards | Reordered | After Dragonmaw Retreat, on the road to Howin; arrow through the cave mouth (fix 4) | yes | in route |
| 463 The Greenwarden (route-audit warnings) | Pickup removed | Only the optional turn-in at Rethiel stays, for a player who brings the note (fix 5) | yes | in route |
| 472 Fall of Dun Modr (loop finding) | Left in place | Moving it to the first visit saves 77 yd but puts the audit's worst quest log at 21 of 20 on the coast trips (see Results) | yes | in route |
| 98208 Bloom of the Heavens (loop finding) | Left in place | The finding is the inn being within 150 yd of the bay. The route never enters the bay before the last visit, where Nord'el and the Osprey chest are one trip. Taking it earlier holds a log slot and saves nothing | yes | in route |
| 469 Daily Delivery | Added (earlier decision revised) | Einar is 80 yd from Howin; Halloran is on the first Menethil visit. Level 21 (830 XP base), not grey at 26-27. The 11-10 and 11-11 audits left it out because guide A "marks it skip in every version", but its "22-26 Wetlands Mage AoE" chapter takes it. questing.wiki lists it in the series 469, 484, 471, ahead of the skins quest whose offer the early chapter already doubts. The step says to use Next if Einar has nothing | yes (AoE) | no |
| 98216 Understanding Our Present | Added, optional | Group quest (guide A: group of 4, skip without one). Pickup after 299 at Whelgar; the Goaz Warder (35.0, 52.5) is beside Sarltooth, and the turn-in is after Ormer's | yes | no |
| 647 MacKreel's Moonshine | Added, optional | MacKreel (Arathi 43.24, 92.64) is beside the Waterlogged Letter. Optional pickup in `wetlands`, carried turn-in in `southshore` (the audit skips a carried optional turn-in) | yes | no |
| 683 Sara Balloo's Plea, 686 A King's Tribute | Added | Talk quests in Ironforge, 1,200 XP each, after Sully's letter (shown only to players with the letter). About 590 yd inside Ironforge | yes | yes |
| 689 A King's Tribute (3) | Left out | Wants 5 Alterac Granite from the Alterac Mountains | yes | yes |
| 98190 A Friend of the Family (carried from `wetlands-early`) | Added stop | A `note` step at Bolvar after the library, before the tram. It shows only while 98190 is in the log (`ifOnQuest`), and it passes once you are in Ironforge, Dun Morogh, Loch Modan or the Wetlands (`skipOn`). See the note below on why it is this kind of step | - | - |
| 225 The Weathered Grave, 227 Morgan Ladimore | Added (`duskwood-late`) | The grave (17.73, 29.08) is about 190 yd from the Plague Spreader mausoleum on the second loop, which comes after the level 28 check. Both turn-ins are at Darkshire NPCs the chapter already visits. 690 + 275 XP | yes | yes |
| 228 Mor'Ladim, 229, 231 | Left out | Mor'Ladim is a level 35 elite; 229 and 231 follow him | yes | 228 no |
| 253 Bride of the Embalmer | Left out, unchanged | Level 30 group fight (Eliza and guards) | yes | no |
| 55 Morbent Fel | Left out, unchanged | Level 32 elite past 30; 325 is only taken | yes | no |
| 98059 Hillsbrad's Hoard, 98071 Brewer's Trade | Added (`southshore`), marked check in game | Alliance level 27 quests from Southshore NPCs, at the chapter's start level. The table spot comes from the Hillsbrad Town Registry in the same town hall; the Dun Garok spot is the middle of the fort's guards. Each is about 1,550 yd there and back | no | no |
| 536 Down the Coast (loop finding, after the additions) | Reordered | Taken at Farren beside Bilger before the level 29 check, not on a separate stop after it | - | in route |
| 555 Soothing Turtle Bisque | Left out | Level 31, minimum 28. Snapjaws (30-31) are on Lordamere's east shore near Tarren Mill, about 1,300 yd there and back from Southshore. It needs Soothing Spices from a vendor. Better in a 30+ Hillsbrad chapter | yes | yes |
| 98230 This Land Was Their Land | Left out | Stoutfist to Howin. No source records its prerequisites, and neither guide takes it. It reads as a breadcrumb to Howin, whom the route meets first | no | no |
| 98240 Crimson Crate Delivery | Left out | Needs Crocs of the Sky (98072), handed in on the last Menethil visit, after the route's last pass by Howin | no | no |
| 98459 A Lack of Virtue | Left out | Level 21, Southshore to Menethil, grey by the time players reach Southshore | no | no |
| 538 Southshore | Left out | 710 XP. It needs the history book drop and would hold a log slot through the whole Wetlands for a Southshore NPC | yes | yes |
| 465, 474 Nek'rosh, 98223 Old Habits | Left out, unchanged | 465 opens after 464, which is handed in on the last Menethil visit. Nek'rosh is level 32, and the spellbook is in his camp | yes | 465 yes |
| 98283 Carnage | Left out, unchanged | Level 30 summoned elite, group | yes | no |
| 304, 88756 (Dun Modr) | Left out, unchanged | Levels 32-34, Dark Iron camps | yes | no |
| 634 Plea To The Alliance | Left out, unchanged | Leads to Refuge Pointe in Arathi | yes | yes |
| 583, 185, 190, 215 (Stranglethorn) | Left out | Level 30-33, minimum 28-30, at Nesingwary's camp in Stranglethorn, which the route never enters. Both guides take them at 29-32 or 30-32, so they belong to a 30+ Stranglethorn chapter | yes | yes |
| 1301, 1302 James Hyal | Left out | Minimum level 30; the chain leads to Dustwallow | yes | yes |
| 1076, 1078 (Collin Mauren) | Left out, unchanged | Stonetalon chain, see `2026-11-10-darkshore-ashenvale-wetlands-gaps.md` | yes | no |
| 343-347, 143-146 (Mage AoE) | Left out, unchanged | See `2026-11-10-westfall-redridge-duskwood-gaps.md` | yes | 343 yes |

**Why the 98190 stop is a `note`.** Three other step kinds don't work here:

- **A turn-in fails the route audit.** `duskwood` and `wetlands` are one path, and an optional turn-in counts as carried only when the path never picks the quest up. `wetlands` picks 98190 up at Stoutfist, so the audit reports "turn-in before its accept".
- **A `goto` would never show.** It counts as passed as soon as any later step in its section is done, and a player from the early chapter has already done many later Wetlands steps.
- **A step without `skipOn`** would send a carrier standing in Menethil back to Stormwind.

So the stop is a `note` with `ifOnQuest = 98190` and `skipOn` on the maps past the tram. Everyone else never sees it.

Checked with throwaway harness scenarios, not committed:

- A carrier at Farthing gets Accept The Doomed Fleet, then "Note - A Friend of the Family". The note goes once 98190 is turned in.
- A carrier in Menethil never gets the note.
- HEAD has no Bolvar stop at all.

For that player, the Wetlands route's own 98190 steps then show as done. They still take 98191 from Bolvar at the end of the route.

## Data changes (for mirroring into the guide pages)

### `duskwood` (QuestData.lua)

- Registration: `q(343, "Speaking of Fortitude", 24, 20)`, optional.
- The Stormwind end, in order:
  1. Fly to Stormwind.
  2. **Brother Kristoff (55.04, 54.16): accept 343 (optional).**
  3. Farthing: 269.
  4. `finish(337, Milton Sheaf)` **moved to the start of `wetlands`**. Duskwood now ends at Farthing.

### `wetlands` (QuestData.lua)

Registrations:

- `q(469, "Daily Delivery", 21, 18)`
- `q(98216, "Understanding Our Present", 31, nil, 299, true)`, optional
- `q(647, "MacKreel's Moonshine", 30, 28)`, optional
- `q(683, "Sara Balloo's Plea", 30, 25, 637)`
- `q(686, "A King's Tribute", 30, 25, 683)`

Steps in route order (new or moved ones in bold):

1. Stormwind:
   - Fly in.
   - Farthing: 270 (unchanged).
   - **Milton Sheaf: 343 (optional) and 337 (book holders), moved from `duskwood`.**
   - **The Bolvar note (80.21, 38.35):** `ifOnQuest = 98190`, `skipOn` Ironforge, Dun Morogh, Loch Modan and the Wetlands.
   - The tram.
2. Ironforge and Thelsamar flight paths.
3. Howin: 98245, 98246.
4. **Einar Stonegrip (49.92, 39.37): accept 469.**
5. Rethiel: 463's optional turn-in only (the Menethil pickup is gone), then 276. Mosshide camps, Rethiel (277), Fenrunners, Rethiel (275), Raptor Ridge, Howin turn-ins.
6. **Howin: accept 98291** (moved from between Angerfang and Ironbeard's Tomb).
7. Dig: 294, 299. Raptors, Fen Creepers.
8. Menethil first visit, in this order:
   - Shellei (flight path).
   - **Fitzsimmons: accept 288.**
   - Helbrek: bind, **then buy the Flagon of Dwarven Honeymead** (the label now matches the early chapter).
   - Glorin: 270.
   - **Fitzsimmons: 288 in, 289 out.**
   - Caitlin: 98282, **plus 95647 for dungeon planners** (moved up from after Halloran).
   - Sida: 470.
   - Valstag: 98197, 473.
   - Stoutfist: 473, 464, 98221.
   - **Karl: 279.**
   - **Halloran: 469 in**, 484.
   - Tarrel: 98461, 305.
9. **First trip north, one loop:** the timber (12.1, 52.5), then the murlocs (279, shown with 484), then the young crocolisks. Back in town: Halloran (484 in, 471 out), Valstag (98197 in), Karl (279 in, 281 out).
10. Second trip north, unchanged: the crates and the cursed wreck. Second town visit, unchanged: Karl, Stoutfist, Fitzsimmons, Halloran, and Harlo (472 stays here). Then the Intrepid.
11. Dig: Merrin, Ormer, the fragments, Whelgar (299 in), then **an optional accept of 98216**. Ormer (295 in, 296 out), Sarltooth, then **the optional Goaz Warder step (35.0, 52.5), with item 279996, the Goaz Stone**. Ormer (296 in), then **Whelgar for the optional 98216 turn-in**.
12. Angerfang: 98221 and 464. The Howin stop for 98291 is gone. Then Ironbeard's Tomb, Dun Modr and the Thandol Span.
13. **On the Arathi shore: Foggy MacKreel (Arathi 43.24, 92.64), optional accept of 647.** Then the cache, the letter (637), Rhag.
14. Rethiel (275 in, 95646). Then Dragonmaw Retreat: 98293, 98291, 98072.
15. **Thelgen Rock moved here:** 98282 at 48.7, 62.4, with `path` through the mouth at 52.6, 62.9, the objective label "Unruptured Stalker Gland" and new text. The Warrior's fang step from QuestClassData.lua follows it, as before.
16. Howin: 98291 in. Hearth.
17. Menethil last visit:
    - Glorin: 292, 293, 321.
    - **Caitlin (98282) and Sida (470).**
    - **Stoutfist: 464, 98221, 98293.**
    - **Tarrel: 306.**
    - Halloran: 98072.
    - Sylessa: 98208.
    - The Osprey, Nord'el, the Raiders, Glorin, Sylessa: unchanged.
18. Ironforge:
    - Fly in.
    - **Gerrig, the optional Blackfathom Deeps pickup** (moved before Sara).
    - Sara (637).
    - **Sara: 683. Magni (39.09, 56.2): 683 in, 686 out. Marblesten (39.04, 88.05): 686 in.** He mentions his granite quest (689) as one to leave.
19. Stormwind and Auberdine: unchanged.

Text changes:

- 289's pickup text no longer says "second trip north". A player from the early chapter has done the first trip.
- The Thelgen Rock and Howin texts now describe the new order.

### `duskwood-late` (QuestAlternateData.lua)

- Registrations: `q(225, "The Weathered Grave", 35, 28)` and `q(227, "Morgan Ladimore", 35, 28, 225)`.
- After the Plague Spreaders (58): **accept 225 at A Weathered Grave (17.73, 29.08)**, with a warning about Mor'Ladim. Then Abercrombie, whose text now says "east of the cemetery".
- At Sirra, after Merrick's Bow: **turn in 225 and accept 227.** After Ello's 252: **turn in 227 to Althea.** The text says to leave Mor'Ladim (228).

### `southshore` (QuestAlternateData.lua)

- Registrations: `q(98059, "Hillsbrad's Hoard", 27, nil, nil, true)` and `q(98071, "Brewer's Trade", 27, 23, nil, true)`. New local: `bilger` (52.13, 58.74). Two Wowhead source URLs were added.
- New steps after the flight path, in order:
  1. Captain McManus (46.43, 50.2): accept 98059.
  2. The Hillsbrad Fields town hall table (29.5, 41.5): 98059's objective.
  3. McManus: turn in 98059.
  4. Bilger: the optional turn-in of 647, then accept 98071.
  5. Dun Garok (71.6, 80.0): 98071's objective.
  6. Bilger: turn in 98071.

  Every new pickup and objective is marked `check` (live verification note).
- Farren's 98219 turn-in and the **536 pickup now come before the level 29 check**, which moved from Darla to Farren.

### `tests/scenarios.lua`

- Unchanged. An earlier draft moved 270 into `duskwood` and had to edit `questWetlandsTravel`. That draft also failed `questDuskwoodHandoff` (see fix 1), so the Stormwind pickups and turn-ins after Farthing went to the start of `wetlands` instead, and both scenarios pass unedited.

## Gaps outside this scope

- **The catch-up skips most of the 26-30 route for a player from `wetlands-early` (Quests.lua; it was already like this before this pass).**
  - What happens: `markPassed` defers any pickup you never took once you have turned in a quest that the same section picks up later. The early chapter turns in many of `wetlands`' quests: 276, 277, 279, 281-286, 288, 294, 295, 299, 305, 306 and 98189.
  - The test: a throwaway harness run of a level 26 with those quests turned in, standing in Menethil. At HEAD these pickups are "deferred" (Missed quests): Howin's Razormaw Needling and Trying Times (98245, 98246), Blisters on the Land (275), War Banners and From the Ashes (464, 98221), Apprentice's Duties (471), Crocs of the Sky (98072) and Fall of Dun Modr (472).
  - With this pass: Daily Delivery (469) and Death to the Dragonmaw (98291) join them. 98291 now sits before the dig pickups, and it needs Howin's two quests, which are already deferred.
  - The current step is then The Doomed Fleet in Stormwind. Accept 321 needs it, so it stays.
  - So the 26-30 route mostly does not "simply show those steps as done" for that player. It drops the Green Belt and the first Menethil pickups.
  - Possible engine fixes: count `progress` only from quests no other leveling section routes, or skip quests turned in through an alternate section. The owner should decide; this pass didn't change Quests.lua.
- **`wetlands-early`:**
  - Daily Delivery (469) also fits there. The eastern trip passes Einar at the crossroads, and Halloran is a few steps from Tarrel on the last Menethil visit.
  - The Excavation Site dungeon guide's note about Einar still holds.
- **Route audit (`tools/questroute.py`):**
  - The Westfall Deadmines pickups (166, 167, 168, 214, 2040, 92753) are normal accepts, but their turn-ins are dungeon-only. In the audit's no-dungeon pass they stay in the log for the rest of the route. With the Skyborne Druid's Moonglade quest, the first Menethil coast trip sits at 20 of 20.
  - That is why 472 stays on the second visit. Making those Westfall pickups `forDungeon` (owner's choice, Westfall section) would free six slots.
- **Loop tool (`questloops.py`):** it ignores `ifOnQuest`, so it walks the Bolvar note (about 530 yd) for every player, in the `wetlands` total.
- **Speaking of Fortitude (343)** is also a candidate in the Westfall/Redridge audit. Only one section should accept it, or the main-path audit fails with "accepted twice".
- **`QuestClassData.lua`:** the Warrior fang step at Thelgen Rock (48.7, 62.4) has no `path`. It shows right after our step, so the arrow is already inside.

## Check in game

- Einar Stonegrip offers Daily Delivery at 26-27, and Halloran takes the bundle.
- Howin offers Death to the Dragonmaw right after Razormaw Needling and Trying Times.
- Farthing offers The Doomed Fleet in the same visit as Seeking Wisdom.
- With A Friend of the Family in the log, the Wetlands route's Stormwind start leads to Bolvar after the library. Without it, the note never shows; in Ironforge or the Wetlands it passes by itself.
- Brother Kristoff offers Speaking of Fortitude at 26, and Milton takes it.
- Thelgen Rock: the arrow goes to the mouth at 52.6, 62.9, then to the stalkers inside.
- The Goaz Warder: group size, its spot on the ledge (35.0, 52.5), and the Goaz Stone's item ID (279996, from guide A).
- Foggy MacKreel's spot on the Arathi shore, and that he offers the moonshine at 28-29.
- Sara Balloo offers Sara Balloo's Plea after the letter. Check the Magni and Marblesten positions.
- Southshore:
  - McManus and Bilger offer 98059 and 98071 to the Alliance at 27.
  - Where the bookkeeping table is in the Hillsbrad Fields town hall, and the Dun Garok fireplace.
  - The XP of 98059.
- The Weathered Grave at 28 (QuestieDB's minimum), and Mor'Ladim's patrol around it.
- Your quest log on the first Menethil visit. The audit's worst case is 20 of 20.
- Levels at each Menethil visit and at the end of `wetlands`, and in `southshore` after the two level 27 errands (the level 29 check follows them).

## Results

- **`tools/questroute.py audit`: passed** (5,470 steps; it was 5,449).
  - The `wetlands` step 8 and 9 distance warnings are gone.
  - New warnings: `duskwood-late` steps 32 and 46, "The Weathered Grave / Morgan Ladimore is more than 5 levels above the section's current target". QuestieDB gives these talk quests level 35 with a minimum of 28, and the chapter's level target is 28 after its grind check. They stay, like the existing Ghoulish Effigy and Proving Your Worth warnings.
- **Loop check** (extended, every Alliance race with Warrior, Hunter and Priest):
  - Before:
    - `wetlands` 23,622 yd.
    - Hubs: 472, 98291.
    - Late pickups: 288, 98208.
    - The two audit warnings.
  - After:
    - `wetlands` 22,337 yd. That includes about 530 yd for the Bolvar note, which only carriers see; about 370 yd of the new Ironforge errands, walked only with the letter; and the Einar stop. So a player without the statuette or the letter walks about 2,200 yd less in the Wetlands.
    - Left: hub 472, kept for the quest log (see above).
    - Left: late pickup 98208, explained above.
  - `duskwood`: 15,176 yd, unchanged. Its Stormwind walk ends at Farthing. Book holders save about 700 yd in Stormwind; everyone else's Stormwind walk is unchanged.
  - `duskwood-late` and `southshore`: no findings. The 536 hub that the Southshore additions created is fixed.
- **Quest log** (the audit's worst case, a Skyborne Druid who never ran the Deadmines): 20 of 20 on the first coast trip, as before plus 98291. Moving 472 forward as well made it 21, and the audit failed.
- **`tools/questmobs.py --check`:** up to date.
- **`tests/run.py`:** "FAILED: 1 run(s) failed": only `WARRIOR/full/blocked-report`, which fails in any `.claude/worktrees` checkout. Every other run passed (263 ok), including:
  - `questDuskwood`, `questDuskwoodHandoff`, `questDuskwoodZoneEntry` and `questDuskwoodDagger`
  - `questWetlands`, `questWetlandsTravel`, `questWetlandsEarly`, `questWetlandsDig` and `questWetlandsEnd`
  - `questLoginWetlandsLocal` and the Thelgen Rock Warrior scenarios
