# Darkshore, Ashenvale, Stonetalon, Wetlands and Southshore: reference guide gap fill

This pass routes the quests that another Forever leveling guide uses between levels 12 and 30 in Darkshore, Ashenvale, Stonetalon and the Wetlands, where our route didn't have them. The gaps come from its chapters 14-16 and 16-19 Darkshore, 19-21 and 20-21 Darkshore/Ashenvale, both copies of 21-23 Ashenvale/Stonetalon, 23-24 Wetlands (including the Hunter variant), 27-29 Wetlands/Hillsbrad, 27-29 Wetlands/Excavation Site and 29-30 Ashenvale. Every added quest ID is in the Forever client reference (build 1.60.1.70862). Levels, prerequisites, races, NPC and object positions come from `tools/questfacts.py`. Both reference guides were used only for quest order, grouping and the positions of Forever-only objects (one guide's world-yard coordinates were converted to map percentages using two known NPCs per map). All step text is original.

**"The new Forever area at level 20."** The client has no zone named Swamplands. The match is Forever's reworked Wetlands: more than 25 new quests from about level 20, the Excavation Site dungeon, and the Auberdine to Menethil to Southshore boat line. This pass completes the Wetlands coverage in the main `wet` route (26-30) and the early `wetlands-early` chapter (20-25).

Sections touched: QuestData.lua `ds` (Darkshore) and `wet` (Wetlands), QuestAlternateData.lua `ashenvale-early`, `stonetalon`, `ashenvale-late` and `wetlands-early`. `southshore` is unchanged (see Skipped). Two harness scenarios were updated because the Wetlands route now starts and ends differently (see the end of this file).

## Added

### Darkshore (`ds`, alternate 12-20)

| Quest | Where | Why there |
| --- | --- | --- |
| 98025 WANTED: Jai'vhanel (Forever) | Poster in the first Auberdine pickups. The owl (44.3, 57.7) is killed with `along` 953/958 at Ameth'Aran. Turned in to Glynda on the return. | The owl lives on the slope you cross on the way into the ruins. |
| 982 Deep Ocean, Vast Sea | Gorbold in the third Auberdine stop. Both lockboxes (38.2, 28.8 and 39.6, 27.5) go `along` with the Thresher Eyes on the north coast. Turned in on the north-loop return. | Same stretch of water as Buzzbox 411. |
| 4740 WANTED: Murkdeep! | Poster at the south-loop pickups (min 15). Murkdeep spawns at the huts (36.5, 76.6) between the beached creature and Onu. Turned in after the hearth. | On the road south, next to 4728. |
| 731 The Absent Minded Prospector (escort) | Taken right after 729 at Remtravel and turned in to Hollee after the hearth. | The escort starts where 729 ends. |
| 741, 942 The Absent Minded Prospector | 741 from Hollee. A Darnassus leg after Volcor (flight or ferry to Rut'theran, portal, Greywhisker) gives 942. The chapter then ends with the Menethil ship and the 942 hand-in to Flagongut. | Both reference guides carry the fossil through Darnassus to the Wetlands. The Wetlands chapters start in Menethil, so the section now ends there. |
| 968 The Powers Below | `startItem = 5352`. A `withItem` accept after the Peerless Eye (Twilight Disciples and Thugs drop the book) and the last step of the section, Gerrig in Ironforge. | Item-started, so both steps stay hidden unless you have the book or the quest. |
| 2078 Gyromast's Revenge | Right after 2098 at Gelkak. The robot is at 55.8, 18.3. | Same spot as its prerequisite. |
| 97926 Making Do (Forever) | Race-limited (Human, Dwarf, Gnome, Skyborne): Baros in Stormwind before the ship, Thundris at the first Auberdine stop. | The section already starts with the Stormwind ship. Night Elves arrive from Teldrassil and never pass Baros. |
| 2178 Easy Strider Living, 1141 The Family and the Fishing Pole | Marked `optional` (Settings > Show optional quests). Strider meat near the bear trap (46, 33), grouper from the Auberdine pier. | Cooking 10 and Fishing gate these. The reference guide marks them as auction-house or skill steps. |

### Ashenvale early (`ashenvale-early`, 18-24)

- 945 Therylune's Escape and 5321 The Sleeper Has Awakened: both escorts now run on the road south from Auberdine. Therylune at the Master's Glaive first, then Kerlonian from the grove to Liladris at Maestra's Post. 945 is turned in at the Shrine of Aessina on the Teronis trip. The whole quest stays in one chapter because the route audit treats each alternate as its own path.
- 1009 Ruuzel: taken from Talen after 1007. Ruuzel (7.2, 13.1, level 22) is on the island off the strand, and the step goes `along` with the Wrathtail heads.

### Stonetalon (`stonetalon`, 22-28)

- 1072 An Old Colleague and 1075 A Scroll from Mauren: taken at Gaxim after 1071. The chapter now ends with a delivery leg: flight to Auberdine, the Stormwind ship, Collin Mauren (Stormwind 53.0, 86.6), then the tram to Lomac Gearstrip (Ironforge 72.1, 51.9). The turn-ins are in this chapter because a turn-in in another path fails the route audit, and putting them in the main Wetlands route would show them to every player.

### Ashenvale late (`ashenvale-late`, 24-30)

The last circuit is reworked into one sweep, following the reference guide's 29-30 chapter.

1. Fallen Sky Lake (1035) is taken from Pelturas at the Astranaar stop before the level 28 check.
2. After that check: the Shrine of Aessina (1022 hand-in moved here, plus Velinde Starsong 1037 and Vile Satyr! 1021 from Illiyana), then Maestra's Post (1140 from Delgren).
3. The rod chain at Krolg and Ran Bloodtooth.
4. The Shadethicket Oracle at Fallen Sky Lake (66.7, 82.2).
5. The Night Run soul (66.6, 57.0, objective 1).
6. Anilia in Xavian (1021 to 1031), then Geltharis (78.0, 42.4, level 32).
7. The Satyrnaar soul (81.6, 48.6, objective 2).
8. Hearth for the Astranaar turn-ins, then Illiyana and Delgren.
9. A Darnassus leg for 1037 and 1038 (Velinde's Locker at 62.3, 83.3).

- Chain note: the game requires The Ruins of Stardust (1034) for 1035 and The Tower of Althalaxx (973) for 1140. Both finish in `ashenvale-early`. As `redridge-late` already does, this chapter registers 1035 and 1140 without a chain, and their pickups say to use Next if they aren't offered.

### Wetlands main (`wet`, 26-30)

1. **Stormwind:** after the flight, 270 The Doomed Fleet from Bishop Farthing. The Duskwood route now turns in 269 just before.
2. **First Menethil visit:** 270 is handed to Glorin, and 484 Young Crocolisk Skins is added because 471 requires it (done already for players from the coast chapter). The young crocodiles (19.2, 47.1) come after the timber, then 484 goes back to Halloran and 471 Apprentice's Duties is taken.
3. **First north trip:** the Giant Wetlands Crocolisks (17.5, 26.2) go `along` with the cursed wreck (289).
4. **Second Menethil visit:** 290 Lifting the Curse after 289, 471 handed in, 98072 Crocs of the Sky taken, and 472 Fall of Dun Modr taken.
5. **Second north trip:** Captain Halyndor on the Intrepid (15.5, 23.6, level 30) and the strongbox give 290 and 292.
6. **Eastern sweep, added parts:**
   - 98291 Death to the Dragonmaw from Howin as you pass Angerfang.
   - Dun Modr after Ironbeard's Tomb: 472, then The Thandol Span 631, 632 and 633. The cache is on the Arathi side (map 1417, 48.8, 88.0). The Waterlogged Letter for 637 is mentioned in the 633 step.
   - After Rethiel: 98293 Forced Disarmament from the Dragonmaw Armaments (58.8, 45.1), with 98291, 98293 and 98072 (whelps, 63.0, 41.8) grouped by `along` in Dragonmaw Retreat (about 64, 46).
7. **Last Menethil visit:** 98293, 98072 and 292 handed in, 293 taken, then the Flying Osprey chest (12.1, 64.2) for 321 and 324, Nord'el (98208) beside it, Bluegill Raiders for the ingots, 322, and 98208 then 98209.
8. **Ironforge:** 637 Sara Balloo (hidden unless you have the letter).
9. **Stormwind:** Grimand 322, then 325 Armed and Ready (taken only: Morbent Fel is level 32), Benedictus 293, then Bolvar 98190.
10. **Auberdine:** the Stormwind ship, then Thundris for 98209. The section now ends in Auberdine, next to the Southshore boat and Ashenvale.
11. **Moved to keep the quest log under 20:** 321 is now taken on the last visit and 472 on the second.

### Wetlands early (`wetlands-early`, 20-25)

- 943 The Absent Minded Prospector is taken at Flagongut on the first Menethil visit. It has no chain here, because 942 finishes in Darkshore. After the coast, a Whelgar leg runs 294 Ormer's Revenge (raptors at 26.3, 46.1), the Stone of Relu from the same raptors (objective 1) and Flagongut's Fossil at the dig (38.9, 52.2, objective 2), then a hearth back to Flagongut. The main route's 294 shows as done for these players.

### Dungeon pickups (`forDungeon`)

- Excavation Site, all on `wet`:
  - 95647 from Caitlin, first Menethil visit.
  - 98815 Highland Hides from Halloran, after 471.
  - 95646 from Rethiel, after 275.
- Blackfathom Deeps, all on `wet`:
  - 971 from Gerrig in Ironforge.
  - 3765 from Argos in Stormwind.
  - 3765 handed in and 1275 taken at Gershala in Auberdine.
- Researching the Corruption (1275) needs 3765 from Stormwind, so it can't be tagged in the Darkshore section.

## Skipped

| Quest | Reason |
| --- | --- |
| 994 Escape Through Force | Exclusive with 995 Escape Through Stealth, which `ds` already routes. The 995 step tells players who chose Force to skip. |
| 730 Trouble In Darkshore? | A Darnassus breadcrumb to 729, which the reference guide gives to Night Elf Druids only. It belongs to the Teldrassil and Darnassus flow. `ds` takes 729 straight from Hollee. |
| 952 Grove of the Ancients | A Night Elf breadcrumb from Fandral in Darnassus (requires 940) to Onu. The Darkshore section never visits Darnassus before the grove, and a hand-in without its pickup in the same path fails the audit. Belongs to the Teldrassil route if wanted. |
| 97914 Expanding Horizons | Night Elf letter from Thundris to Baros in Stormwind. The Darkshore section's exits are Ashenvale and Menethil, not Stormwind. Better placed where the Teldrassil route takes the Auberdine ship to Stormwind. |
| 1073 and 1074 Ineptitude + Chemicals = Fun | Needs 4 Minor Mana Potions and 2 Elixirs of Minor Fortitude (alchemy or the auction house), then a trip back to Stonetalon. The 1072 hand-in mentions it. |
| 1076 Devils in Westfall, 1078 Retrieval for Mauren | Follow from 1075 at Collin Mauren. 1076 needs Dust Devil Debris from Westfall Dust Devils (18-19, for example 44, 46 and 36, 65). It belongs to the Westfall owner but needs 1075 from Stonetalon first, so it would be grey by then. 1078 has no prerequisite and is taken from Mauren in Stormwind. Its Crystalized Scales come from Stonetalon basilisks (Blackened 23-24 around 36, 48 and 45, 44; Singed and Scorched 25-28 in the Charred Vale). It fits a Stormwind stop before the `stonetalon` chapter. |
| 1059 Reclaiming the Charred Vale (follow-up) | Sends you to Falfindel on the Feralas and Thousand Needles border, outside this route. |
| 1094 Further Instructions | Ziz Fizziks to Sputtervalve in Ratchet. The reference guide uses it only for Warlocks already going to the Barrens. |
| 1032 Satyr Slaying! | Level 32. It needs a second trip to Xavian after 1031 is handed in at the Shrine. Leave it for 30 and up. |
| 1039 The Barrens Port, 1081 Reception from Tyrande | Ratchet, and the reference guide skips them. |
| 1167 The Tower of Althalaxx (after 1140) | Goes back to Balthule in Darkshore at 28+ and continues past 30. |
| 463 The Greenwarden | Breadcrumb from Fitzsimmons to Rethiel. Both Wetlands chapters reach Rethiel before Menethil, so it would only add a trip. |
| 469 Daily Delivery | One reference guide marks it skip and the other omits it. It may be unavailable in Forever. The Excavation Site checklist already points to Einar if Halloran has no offer. |
| 98216 Understanding Our Present | Level 31. The Goaz Warder fight is a group fight (a reference guide says to skip it without a group). |
| 98283 Carnage | Carnage is a level 30 elite you summon in the Raptor Ridge cave (4300 HP, calls for help). Group quest. |
| 465 Nek'rosh's Gambit, 474 Defeat Nek'rosh, 98223 Old Habits | 465 opens only after 464 is handed in on the last Menethil visit, so it would need a third eastern trip. Nek'rosh is level 32 and the reference guide routes him for Hunters, Warlocks and Mages only. The spellbook for 98223 sits in his camp. |
| 304 A Grim Task, 88756 Bring Back a Bang, 87318, 88757 and 88758 (Villard chain) | Levels 32-34. Dun Modr's Dark Iron camps and the elite saboteurs in the span. |
| 634 Plea To The Alliance | Leads to Refuge Pointe in Arathi. The 633 hand-in step says to leave it. |
| 647 MacKreel's Moonshine | Picked up in Arathi by the span and handed in at Southshore. `southshore` is a separate path, so the hand-in can't go there (the audit requires the pickup in the same path). Taking it in `wet` would leave a quest with no route. |
| 337 An Old History Book, 538 Southshore | 337 belongs to Duskwood (already in `dusk`). 538 is level 38. |
| 55 Morbent Fel | Past 30. 325 is only taken. |

## Facts that disagree between sources

- Apprentice's Duties (471): QuestieDB Forever lists 484 as its prerequisite, and the other reference guide takes 471 without 484. The route does 484 first. That costs little: the skins are next to town.
- The Powers Below (968): The reference guide shows it as an accept step for Shamans only. The quest data says an item drop (Book: The Powers Below from Twilight Disciples and Thugs) for all races. It is routed as item-started.
- Fall of Dun Modr (472): requires level 25 and has quest level 25. Both reference guides turn it in at the start of the Dun Modr trip, so it sits with the Thandol Span (min 28) at the end of the eastern sweep.
- Velinde Starsong (1037): Melyria is at the Shrine of Aessina in the Forever spawn data. Classic placed her at Forest Song. Illiyana is also at the shrine (21.7, 53.3), not in Forest Song.

## Check in game

- Darkshore:
  - Jai'vhanel's spawn on the slope north of Ameth'Aran.
  - The two lockbox wrecks and their depth.
  - Murkdeep's waves at 36.5, 76.6.
  - Remtravel's escort with the dig cleared.
  - The Threshwackonator path.
  - The Rut'theran portal and Greywhisker's spot.
  - That the 968 steps stay hidden without the book.
  - Making Do is offered to non-Night Elves in Stormwind.
- Ashenvale early: Therylune, then Kerlonian's escort (does the horn come from the chest?), and Ruuzel's island at 18-22.
- Stonetalon: Gaxim offers 1072 and 1075 after 1071, Mauren's position in Forever's Stormwind (53.0, 86.6), and Lomac in Tinker Town.
- Ashenvale late:
  - Pelturas offers 1035 after The Ruins of Stardust.
  - Delgren offers 1140 after 973.
  - The Night Run and Satyrnaar circles and their objective order (1 = Night Run, 2 = Satyrnaar).
  - Geltharis solo at 29.
  - Velinde's Locker in Darnassus.
- Wetlands:
  - Farthing offers 270 right after Seeking Wisdom.
  - Halloran's offer order (484, 471, 98072, 98815).
  - Halyndor on the Intrepid at 28-29.
  - The Thandol Span stairs and the elite saboteurs.
  - The cache and Waterlogged Letter on the Arathi side.
  - The Dragonmaw Retreat kill counts and the armament pick-up.
  - The whelp scales.
  - Nord'el beside the Osprey chest.
  - The Auberdine ship and Thundris at the end.
- Wetlands early: Flagongut's 943 after the fossil, the Stone of Relu drop rate from Mottled raptors, and the fossil at 38.9, 52.2.
- Record the level at each Menethil visit and at the end of `wet` with the new quests (the route was 26-30 before this pass).

## Harness scenarios updated

- `questWetlandsTravel`: the Wetlands route now has Bishop Farthing's 270 pickup in Stormwind between the flight and the tram. The scenario steps through it and still checks that the tram follows.
- `questWetlandsEnd`: the route now ends in Auberdine with Bloom of the Heavens (98209) after the Stormwind turn-ins. The scenario resumes at that final turn-in on the Darkshore map and keeps every end-of-guide check (last step label, ending card, no dead Next button, reopen and Back).

Results: `tools/questroute.py audit` passed (2941 steps, no new warnings in these sections). `tests/run.py` passed (0 runs failed).
