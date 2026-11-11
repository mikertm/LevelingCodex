# 2026-11-11: Early Wetlands (20-25) route audit

Section: `wetlands-early` in `QuestAlternateData.lua` ("Wetlands: The Green Belt and Coast", levels 20-25). The 26-30 `wet` route in `QuestData.lua` is unchanged. The chapter is still unverified until someone plays it with the recorder.

## Sources

- **Guide A** (local copy, see `2026-11-10-guide-cross-reference.md`): its "23-24 Wetlands" chapter in four versions (speedrun, Hunter, dungeon and Mage AoE), plus "27-29 Wetlands" to see what it leaves for later. We used only quest IDs, how quests are grouped and in what order, and the positions of Forever-only objects. Its world-yard coordinates were converted to map percentages from the Wetlands extents (4135.417 x 2756.25 yd). Two known NPCs check the conversion: Shellei and Rethiel land within 0.01.
- [Bind on Forever: Wetlands](https://bindonforever.com/zones/wetlands): the quest list with Forever IDs, and its Dwarf/Gnome visit order (visit 2 at 22-24, visit 3 at 24).
- [games.gg Wetlands guide](https://games.gg/world-of-warcraft/guides/wow-forever-wetlands-leveling-guide/): recommends arriving by ship at 20-21 and binding in Menethil. Its quest grouping, by area, matches ours.
- `tools/questfacts.py` (QuestieDB Forever plus traces): every level, minimum level, prerequisite, giver and mob spawn below. Every quest ID is in the Forever client reference.
- No public source gives a step-by-step 20-25 order. Several guides note that Forever's new Wetlands quests are missing from the public databases.

## What was wrong

1. **It started in the wrong place.** The chapter opened at Rethiel in the Green Belt, then walked west to Menethil for the flight path and bind. The Darkshore chapter ends in Menethil, with the Auberdine ship and Flagongut's fossil, and both reference routes start there. So a player arriving by ship crossed the zone three times: east to Rethiel, back west to Menethil, then east again to the dig.
2. **Fire Taboo had its own round trip.** The Fenrunners south-east of Rethiel (62.8, 57.1) needed a separate 1,060 yd trip from Rethiel and back.
3. **Quests on the way were missing.** Menethil gives several 20-25 quests whose targets lie on the route we already walk. None were taken:
   - Alchemical Hazards (98282, Forever, level 22): the Thelgen Rock stalkers, 21-22.
   - Digging Through the Ooze (470, level 24): oozes at Ironbeard's Tomb, 23-25.
   - In Search of The Excavation Team (305 and 306, level 24): a delivery to Merrin at the dig, then a reply back to Tarrel.
   - The Third Fleet (288, level 27, minimum 22): buy a mead and hand it in. A large reward for level 22-24.
   - Return the Statuette (98189, Forever): Karl to Captain Stoutfist, in the same town as 286.
   - Unrequited Love (98461, Forever): Hollee's note from the Darkshore chapter, handed to Tarrel.
   The 26-30 route took these at 27-29, five or more levels later.
4. **The Greenwarden was hidden.** The 26-30 route marks it optional, because that route reaches Menethil late. Now that this chapter starts in Menethil, the breadcrumb is free XP on a walk we take anyway.

## New order

1. **Menethil (20).** Flight path, bind, then the pickups in walking order: Flagongut (943, only if 942 was turned in), Fitzsimmons (463), Caitlin (98282), Sida (470), Valstag (98197), Karl (279), Halloran (484), and Tarrel (98461 if carried, then 305).
2. **First coast loop (20-21).** The harbor timber (12.1, 52.5) by Tarrel's bridge, then the Bluegill murlocs and Gobbler (15, 39). The young crocolisks (19.2, 47.1, with more at 15.4, 53.6) on the way back. Turn in 484, 98197, 279, and take 281.
3. **Second coast loop (21-22).** The three murloc-hut containers, then Karl (286 and 98189) and Stoutfist (98189).
4. **The eastern trip (22-23):**
   - Take the road east to Rethiel: 463 in, 276 out.
   - Thelgen Rock (98282, cave mouth 52.6, 62.9). The step's target button targets Leech and Cave Stalkers, because the gland is a Forever drop the data doesn't list.
   - The Mosshide camps (276, 63, 66).
   - Rethiel: 276 in, 277 out.
   - North-west, north of Angerfang, to the Mosshide camp at 44.3, 34.0 for the flint (277). Fenrunners, Trappers and Mistweavers all drop it.
   - Ironbeard's Tomb, just north (470, 44.9, 26.1).
   - Rethiel: 277 in.
5. **Back west (23).** At the dig: Ormer (294), Merrin (305 in, 306 out) and the fossil. Then the raptors west of the dig (294 and the Stone of Relu), a level 22 check for The Third Fleet, and Ormer (294 in).
6. **Hearth (23-24).** Flagongut (943), then Fitzsimmons and Helbrek (288, the mead), Caitlin (98282), Sida (470) and Tarrel (306). The chapter ends with the existing level 23 check.

Why each group is where it is:

- **The Fire Taboo flint moved** to the north-west camp, so it shares one trip with the oozes (Rethiel, the camp, the tomb, then back to Rethiel: 1,365 yd). The old route did the flint alone (1,063 yd) and had no oozes at all.
- **Thelgen Rock and the Mosshide camps share one loop** from Rethiel (about 1,840 yd).
- **The dig comes on the way back**, not on the way out. That puts Ormer's Screechers (24-25) at about 23 instead of 21-22. The trip from the dig to the raptors and back (about 1,020 yd) can't be avoided: Ormer stands east of his raptors, and every reference guide makes the same trip.
- **The murloc huts stay a second coast trip.** Reclaiming Goods (281) needs Claws from the Deep (279) handed in first. We considered crossing the north marsh from the huts straight east, but it runs through level 22-24 gnoll camps, so the route returns to town and takes the road.

Walking distance, as straight lines between waypoints with hearths counted as free:

| | Arriving by ship | Arriving from Dun Algaz | Quests turned in |
|---|---|---|---|
| Before | 12,320 yd | 11,142 yd | 12 |
| After | 10,482 yd | 12,334 yd | 19 |

Per quest, that is about 1,030 yd before and 550 yd after by ship, or 930 yd before and 650 yd after from Dun Algaz. A player walking in from Loch Modan now crosses the Green Belt on the way to Menethil and comes back later. That costs them about 1,200 yd more than before, in exchange for seven more quests. It is still the better trade, because every eastern quest except Rethiel's starts in Menethil.

## Data changes (QuestAlternateData.lua, for mirroring into the guide pages)

- Step order rewritten as above. New steps:
  - Pickups: 463 (now a normal step via `always`), 98282, 470, 305, 98189, 288.
  - Turn-ins: 98461 (optional, only while it's in your log), 98189 at Stoutfist, 306.
  - Objectives: 98282 (Thelgen Rock, `mobs` = Leech Stalker, Cave Stalker), 470 (Ironbeard's Tomb) and 288 (the mead).
  - Grind: level 22 at the raptor field, before Fitzsimmons' quest.
- Moved:
  - Fire Taboo's objective, from 62.8, 57.1 to 44.3, 34.0.
  - The dig (294, 943's fossil), from an outbound stop to the return leg.
  - The flight path and bind, from mid-chapter to the start.
- New locals: Stoutfist, Fitzsimmons, Caitlin, Sida, Tarrel, Merrin, plus the helpers `always` (clears a quest's global `optional` for one step) and `targets` (sets a step's `mobs`).
- Sources: added the games.gg Wetlands guide.
- Unchanged: the chapter's ID, title, levels (20-25) and section `suggest` list, and the final level 23 check with its suggestions.

## Left out, and why

| Quest | Reason |
|---|---|
| 98245 Razormaw Needling, 98246 Trying Times (Howin) | Guide A takes them from level 21, but Raptor Ridge's Highland (27-28) and Elder (29) Razormaws are 26-30 content. The 26-30 route does them. |
| 275 Blisters on the Land | Level 26, against Fen Creepers (24-25). The 26-30 route takes it after 277. |
| 471 Apprentice's Duties, 98815 Highland Hides, 98072 Crocs of the Sky | Levels 26-28 (Giant Crocolisks, Excavation Site, whelps). Halloran's step text says his next order is for the later chapter. |
| 295, 296 Ormer's Revenge; 299 Uncovering the Past | Levels 27-29; 299 needs level 25. |
| 289 The Cursed Crew | Level 29, the cursed wreck. Fitzsimmons offers it after 288. The later chapter takes it. |
| 98190 A Friend of the Family | Ends with Bolvar in Stormwind. The 26-30 route takes it at Stoutfist and ends in Stormwind. |
| 473 Report to Captain Stoutfist, 464 War Banners, 98221 From the Ashes | Minimum 23 and Angerfang (26-29). They are in the 26-30 route. |
| 472 Fall of Dun Modr | Minimum 25, and it ends at Dun Modr in the far north. |
| 469 Daily Delivery | Guide A marks it skip in every version. It may not be offered in Forever (see the 2026-11-10 gap audit). |
| 468 Report to Mountaineer Rockgar, 455 The Algaz Gauntlet | Level 21. The chain starts with Kadrell in Thelsamar and Rockgar at Algaz Station, then kills 8 Dragonmaw Scouts and 6 Grunts at Dun Algaz (48, 76) and ends at Valstag. Only players who walk in from Loch Modan pass it. The chapter can't show a Thelsamar pickup to walkers alone: with Show optional quests on, players arriving by ship would be sent back to Loch Modan. Worth adding to a Loch Modan exit if that route ever reaches level 19. |
| 98459 A Lack of Virtue (Forever) | Tom "Half-fish" Wilson in Southshore, delivered to Bart Tidewater in Menethil. It starts outside this chapter. |
| 1132 Fiora Longears | Runs from Menethil to Auberdine, the wrong direction for this chapter. |
| Excavation Site pickups (95647, 95646, 98815) and Seeking Caitlin (95737) | The dungeon guide is 26-31, and its quests are level 31 with minimum 24. The 26-30 route and the dungeon checklist offer them. Seeking Caitlin has its own special guide. |
| 94495-94501 Call of Water (Shaman) | A class side section (`QuestClassData.lua`). Hervdana's cave is next to the Mosshide camps, so Shamans can take it on the eastern trip. |

## Gaps noticed in the 26-30 route (not changed here)

- **98230 This Land Was Their Land and 98240 Crimson Crate Delivery** (Forever, level 29). Stoutfist and Halloran send them to Howin. Neither our route nor guide A routes them. Their prerequisites aren't in the data. Check in game whether they are offered on the first Menethil visit at 26+; if so, they ride the eastern trip for free.
- **The Thelgen Rock waypoint.** The 26-30 route's Thelgen Rock step points at 48.7, 62.4, above the cave. Guide A and the games.gg guide both put the mouth at 52.5-53.2, 62.8-62.9. This chapter uses 52.6, 62.9.
- **The Greenwarden pickup.** The route audit flags steps 8 and 9 of `wetlands` (the optional pickup in Menethil, between Howin and Rethiel, about 1,660 yd and 1,950 yd). The steps only show with Show optional quests on, or once the quest is in your log, so they cause no detour by default. This was already there before this pass.

## Check in game

- The fastest arrival from Lakeshire or Duskwood at 20-22: walking through Dun Algaz, or two ships by way of Auberdine.
- Halloran offers 484 on the first visit (the step's existing uncertain note).
- Tarrel offers 305 to a player who never brought Hollee's note. QuestieDB lists no prerequisite.
- Thelgen Rock: the cave mouth at 52.6, 62.9, and which stalkers drop the Unruptured Stalker Gland.
- The north-west Mosshide camp (44.3, 34.0): the flint drop rate, and whether walking north of Angerfang is safe at 22.
- The Sida's Bag drop rate at Ironbeard's Tomb.
- Your level at each Menethil return. The estimate is about 21 after the first coast loop, 22 after the second, 23 after the eastern trip and 23-24 at the end.
- The mead's name in the quest log ("Flagon of Dwarven Honeymead", following guide A and the harness log).

## Results

- `tools/questroute.py audit`: passed (2,986 steps). No warnings in `wetlands-early`. The only Wetlands notes are the two pre-existing `wetlands` step 8 and 9 distance warnings described above.
- `tests/run.py`: passed, 0 runs failed. The new scenario `questWetlandsEarly` checks that a level 21 Night Elf in Menethil follows this chapter, starts at the Menethil flight master, gets the pickups after binding, and sees The Greenwarden as a normal step.
