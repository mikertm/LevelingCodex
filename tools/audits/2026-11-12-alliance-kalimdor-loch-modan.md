# 2026-11-12: Loch Modan, Darkshore, Ashenvale and Stonetalon: loops and gaps

Sections: the alternate chapters `loch-modan` and `darkshore` in `QuestData.lua`, and `ashenvale-early`, `stonetalon` and `ashenvale-late` in `QuestAlternateData.lua`. Same method as `2026-11-12-wetlands-early-dig.md`: group the loops so the route doesn't zig-zag, and look for quests the route walks past. All five chapters stay unverified.

Earlier decisions kept unless noted: `2026-11-09-alliance-alternates.md`, `2026-11-09-alliance-route-expansion.md`, `2026-11-10-starter-gaps.md`, `2026-11-10-darkshore-ashenvale-wetlands-gaps.md`, `2026-11-10-guide-cross-reference.md`, `2026-11-10-route-audit-pass-2.md`.

## Sources

- **Loop check**: `tools/questloops.py` extended to walk each alternate chapter on its own and to flag late pickups (an accept the route could take at an earlier visit to the same spot while it walks through that quest's objective area in between). Run for Human, Dwarf, Night Elf and Skyborne with Warrior, Hunter and Priest.
- **Guide A** (RXP Forever, local copy). Only quest IDs, grouping, order and positions were used, never its text:
  - "11-13 Loch Modan" (Human), "12-14 Loch Modan (Dwarf/Gnome)", "11-13 Loch Modan (Hunter)", "15-16 Loch Modan". The 15-16 chapter ends with the Ironband report to Jern, takes Report to Ironforge (301), flies to Ironforge and hands it to Stormpike.
  - "14-16 Darkshore", "16-19 Darkshore", "19-21 Darkshore/Ashenvale", "20-21 Darkshore/Ashenvale". The 14-16 chapter takes The Blackwood Corrupted (4763) at the Cliffspring sample hand-in (4762), and Cave Mushrooms (947) on the first Auberdine visit for Night Elves at 12+.
  - The Mage AoE Darkshore and Loch Modan chapters (no extra quest IDs in these zones).
  - RestedXP-Skyborne.lua "21-23 Ashenvale/Stonetalon", "21-23 Stonetalon/Ashenvale" and "29-30 Ashenvale" (speedrun and dungeon-guide versions). The first Astranaar visit takes Culling the Threat (1054) with Raene's Cleansing (991). The 29-30 chapter takes the Gleaming Crescent Pendant (98027) between Fallen Sky Lake and Felfire Hill.
- **Zygor Forever guides (quest-ID gap check only)**: `gaps-zygor-alliance.txt` (quests Zygor's 1-30 guides accept that no route step uses). In these zones it lists only quests that are also on guide A's list: 301, 994, 952, 1032, 1039, 1073 (plus 683/686/689 Sara Balloo and 1179 Brassbolts, filed under its Ashenvale 29-30 chapter but outside these zones). Its "Loch Modan (18-19)" chapter was opened only to see where it takes 301: at the end of the chapter, right after 298. No Zygor text, order or code was used.
- **Bind on Forever** (Forever quest and zone pages):
  - [Gerenzo's Orders 1090](https://bindonforever.com/quest/1090): both factions, Piznik at 71.9, 60.0 inside Windshear Mine, level 22, from level 17, kobold waves while he mines. Its free route takes it at 21.
  - [One Shot. One Kill. 5713](https://bindonforever.com/quest/5713): Alliance, level 15, from 10. Aynasha at 45.9, 90.3 is poisoned; Blackwood Trackers (14-15) and Marosh the Devious (16) attack. Turned in to Onaeya at Maestra's Post. Its free route takes it at 19.
  - [Darkshore zone route](https://bindonforever.com/zones/darkshore): takes 5713 right after Escape Through Stealth (995).
  - [Never Coming Back 98251](https://bindonforever.com/quest/98251): Horde only.
  - [Slowing the Orc Advance 86757](https://bindonforever.com/quest/86757): Alliance, level 30, from 27; no drop sources listed.
- [Wowhead Classic, Supplies to Auberdine 976](https://www.wowhead.com/classic/quest=976/supplies-to-auberdine): Feero's escort heads for Auberdine; the turn-in is back at Maestra's Post.
- [Wowhead Classic, Gerenzo's Orders 1090](https://www.wowhead.com/classic/quest=1090/gerenzos-orders): guard Piznik while he mines; the ore goes to Ziz.
- `tools/questfacts.py` (QuestieDB Forever): levels, prerequisites, races, NPC and object positions. Notable facts:
  - Gaffer Jack (6717) and Electropeller (6718) have no drop source, so Wizbang's 1579/1580 can't be done.
  - Sentinel Selarin (3694, Trek to Ashenvale 990) has no spawn.
  - Ol' Sooty (Vyrin's Revenge 271/531) is a single level 20 bear at 37.9, 63.4.
- `tools/reference/forever.json`: 95042 Seeking the Kor Gem is not in the client (as the class audit already found).

## What was wrong

The loop check found nine spots in these chapters, all re-checked by hand:

| Chapter | Finding | Cause |
|---|---|---|
| loch-modan | Banner of the Fallen (86585) taken on the second trip into the Stonesplinter valley, though the first trip stands 40 yd from Ylva | Pickup placed with its objective |
| darkshore | First Auberdine visit: Gwennyth (3524), the poster (98025), Tharnariun (2118) visited out of order: flight point, inn, north to Gorbold (optional), back to Gwennyth beside the flight point, east to Terenthis, back to the poster, east again | Town order |
| darkshore | Cave Mushrooms (947) at Barithras as a separate stop after the turtle swim | Pickup placed after the swim |
| darkshore | The Blackwood Corrupted (4763) taken two Auberdine visits after its prerequisite (4762) was handed to the same NPC | Pickup delayed |
| ashenvale-early | First Astranaar visit: flight point, inn, back west to Shindrell (1008), east again to Raene (991) | Town order |
| ashenvale-early | Culling the Threat (1054) as a separate stop at Raene on the second circuit | Pickup delayed |
| ashenvale-late | Kayneth Stillwind (4581) at Shindrell, beside the flight point, only after the inn and Raene | Town order |

Two more the check can't see:

- **ashenvale-late, the pendant (98027)**: after Felfire Hill the route went back north-east to Kayneth, then about 1,650 yd south-west to the pendant at 63.0, 71.6 and 1,100 yd north to Shael'dryn, instead of 1,830 yd straight west. This was also the chapter's only distance warning in the route audit. The pendant lies between Fallen Sky Lake and Night Run, which the last circuit walks anyway.
- **darkshore, the town visits after Ameth'Aran and after the north loop**: each crossed Auberdine two or three times (Terenthis, north to Thundris, west, south, east to Glynda and Elissa, north to Gorbold, then out north-west; and Glynda, Tharnariun, Barithras, north to Thundris and Gorbold, south to Gwennyth, north to Hollee, south to Gubber).

## Findings

Status: added, reordered, or left out (with the reason). "A" = guide A routes it, "Z" = on Zygor's gap list, "B" = QuestieDB only.

| Quest | Src | Status |
|---|---|---|
| 86585 Banner of the Fallen | loop | **Reordered**: taken on the first valley trip beside the Seers, planted on the second |
| 3524, 98025, 2118, 984, 983 (first Auberdine visit) | loop | **Reordered**: one pass through town |
| 947 Cave Mushrooms | loop | **Reordered**: second visit, between the moonwell and Cerellean. Not the first visit: it needs level 12, the chapter's floor, and Night Elves can arrive at 11. Guide A takes it on the first visit only for Night Elves at 12+ |
| 4763 The Blackwood Corrupted | loop | **Reordered**: taken at the 4762 hand-in, as guide A does. Same level 15 gate as 729, 1138 and 4740 on that visit |
| Third and fourth Auberdine visits | walk | **Reordered** (see the data changes) |
| 1008, 991 (first Astranaar visit) | loop | **Reordered** |
| 1054 Culling the Threat | loop, A | **Reordered**: first Astranaar visit, as guide A does. The hunt stays on the second circuit |
| 4581 Kayneth Stillwind | loop | **Reordered**: right after the flight point |
| 98027 Gleaming Crescent Necklace | walk, A | **Reordered**: last circuit, Fallen Sky Lake to Night Run; turned in after the last hearth |
| 301 Report to Ironforge | A, Z | **Added**: end of `loch-modan`, on the way out through Ironforge. The 11-10 audit left out 301 and 302 together because 302 brings you back. 301 alone is a free hand-in on the usual way to the tram, and both guides end their Loch Modan chapters with it |
| 302 Powder to Ironband, then 273, 454, 309 | A (302 only, Gnome Mage AoE), B | Left out: back to Thelsamar from Ironforge, then the south-shore ambush and escort. Only for a second Loch Modan visit |
| 1645 The Tome of Divinity (Dwarf Paladin) | A | Reported only: not in the Forever client (11-11 class audit); class quests belong to the class files |
| 1641 Tome of Divinity, 95065 Fishin' Time, 399 Humble Beginnings | A | Not these chapters: Stormwind errands, decided in `2026-11-10-starter-gaps.md` |
| 255 Mercenaries | B | Left out: Bluntnose in Thelsamar from level 15, but the route is in Thelsamar at 15+ only at the very end; 12 Mo'grosh ogres of 17-20 in the north-east |
| 256 WANTED: Chok'sul | B | Left out: level 22 ogre |
| 271, 531 Vyrin's Revenge | B | Left out: Ol' Sooty (20) is at 37.9, 63.4, near Thelsamar, and both hand-ins are at Farstrider Lodge, which the route has left by then |
| 161, 274, 278, 280, 283 A Dark Threat Looms (Forever follow-ups) | B | Left out: 161 sends you to Dun Modr in the Wetlands at 18; the rest follow it |
| 468 Report to Mountaineer Rockgar | B | Left out: level 21 (min 19), above the chapter; noted in the 11-11 Wetlands audit as a possible Loch Modan exit |
| 1578 Supplying the Front | B | Left out: Blacksmithing items |
| 5713 One Shot. One Kill. | B | **Added** to `ashenvale-early`: Aynasha is south-east of the Glaive, where the chapter frees Therylune; turned in to Onaeya beside Liladris at Maestra's Post, where Kerlonian's escort ends. About 460 yd and a short event (attackers 14-16) for a level 15 quest at 18-19. Bind on Forever routes it at 19 |
| 994 Escape Through Force | A, Z | Left out: exclusive with 995, which `darkshore` routes |
| 97914 Expanding Horizons | A | Left out (11-10 decision kept): Thundris to Baros in Stormwind. The chapter ends at the Menethil ship, so a Night Elf would carry it with nowhere to hand it in. It fits the Teldrassil route's Auberdine ship to Stormwind |
| 730 Trouble In Darkshore?, 952 Grove of the Ancients | A, Z (952) | Left out (11-10 decision kept): Darnassus breadcrumbs. The chapter reaches Darnassus only after 729 and the grove are done |
| 990 Trek to Ashenvale | B | Left out: its giver, Sentinel Selarin, has no spawn |
| 1579 Gaffer Jacks, 1580 Electropellers | B | Left out: the items have no drop source (unused, as in classic) |
| 1133 Journey to Astranaar | B | Left out: starts in Theramore |
| 1442 Seeking the Kor Gem (Paladin), 95042 Seeking the Kor Gem | B | Left out: 1442 is not in the client; 95042 is not in the client and its giver is at Zoram'gar |
| 1167, 1143, 981 The Tower of Althalaxx | B | Left out (11-10 decision kept): level 28-31, back to Balthule |
| 961 Onu is meditating | B | Left out: a dummy entry |
| 976 Supplies to Auberdine | B | Left out: Feero's escort heads north for Auberdine and the hand-in is back at Maestra's Post, while the chapter goes south after the tower |
| 98251 Never Coming Back, 98252 A Void Path | B | Left out: Horde only (the Horde route has them) |
| 86757 Slowing the Orc Advance | B | Left out: level 30, from 27, and no drop source for the orc swords and daggers in the data. Shandrina is at Silverwind Refuge, which the late chapter passes at 24-25 |
| 1017 Mage Summoner | B | Left out (11-09 decision kept): Sarilus Foulborne takes you into the Barrens |
| 1032 Satyr Slaying! | A, Z | Left out (11-10 decision kept): level 32, needs a second eastern trip after the 1031 hand-in |
| 1039 The Barrens Port | A, Z | Left out: Ratchet |
| 1090, 1092 Gerenzo's Orders | B | **Added** to `stonetalon`: Piznik's tunnel at 71.9, 60.0 lies on the way back from the Venture Co. machines to Ziz, who takes the ore with Super Reaper 6000. About 50 yd more walking plus a few minutes of guarding. Both factions; Bind on Forever routes it at 21 |
| 1073, 1074 Ineptitude + Chemicals = Fun | A, Z (1073) | Left out (11-10 decision kept): potions from an alchemist |
| 1094 Further Instructions | A | Left out: Ratchet; guide A gives it to Warlocks only |
| 1059 Reclaiming the Charred Vale (2) | A | Left out: Feralas border |
| 1076, 1077, 1078 Mauren's errands; 1079, 1080, 1091, 1082, 1083, 1084, 1081 | A (1076, 1078), B | Left out: they start in Stormwind (Mauren) after the chapter ends, or need 1074 and 1077 first |
| 2931 Castpipe's Task | B | Left out: Gaxim offers it from 25, but the chapter is at Gaxim only at about 22 |
| 1095, 1096 | B | Left out: follow 1094 from Ratchet |
| 86576 Bloodfury Trinkets | B | Left out: Maggran Earthbinder is at Sun Rock Retreat (Horde) |

## Data changes (for mirroring into the guide pages)

### `QuestData.lua`, `loch-modan`

1. New `q(301, "Report to Ironforge", 15, 10)`, deliberately without its prerequisite (298). With the chain, catch-up counted Ironband's report as needed by a later pickup, so a player resumed at Bingles or the dam without 298 was sent back to the dig (the `questLochBingles` and `questLochReady` scenarios caught it). The game still requires 298, which the route hands in to Jern just before; the pickup says to use Next if Jern has nothing.
2. Second valley visit: `accept(86585, ylva)` moves from after Wallbang's objective (263) to right after the Skullthumper and Seer objective (237): "Ylva waits in the small upper cave beside the Seers. Take her banner quest now and plant it on your next trip here." The banner step stays after 263's objective and now starts "On the way back, plant the Banner of Ironforge by Ylva."
3. End of the chapter, after `finish(298, jern)`:
   - `accept(301, jern)`;
   - `taxi("fly", gryth, "Ironforge, Dun Morogh")`: fly from Thorgrum, or take the road west without that flight path;
   - `finish(301, Prospector Stormpike, Ironforge 74.64, 11.74)`: Hall of Explorers; leave his follow-up (302) unless staying in Loch Modan;
   - then the optional `finish(1338, Furen Longbeard)` as before.

### `QuestData.lua`, `darkshore`

1. First Auberdine visit, new order: flight point; Gwennyth (3524); bind at the inn; Wizbang (983); poster (98025); Glynda (4811); Tharnariun (2118); Terenthis (984); Gorbold (optional 97894 hand-in); Alanndarian (optional 2178); Thundris (97926 for non-Night Elves, 954); Gubber (optional 1141) on the way south.
2. Second visit: Barithras's `accept(947)` moves from after the turtle swim to right after the moonwell (4812). The optional pier fishing and Gubber (1141) move from after Thundris to after Cerellean, next to the pier.
3. Third visit (after Ameth'Aran), new order: Terenthis (985, 986); Elissa (965); Glynda (98025); Gwennyth (4722); Cerellean (963); Gorbold (982); Thundris (958); then north to the coast.
4. Fourth visit (after the north loop), new order: Tharnariun (2138); Glynda (4813); Barithras (947, 948); Hollee (729); Gorbold (982); Thundris (4762, then **`accept(4763)`**, moved here from the visit after the south loop); Gwennyth (4723, 4725, 4727); Gubber (1138); poster (4740) last, so the Druid's Earthroot step (inlined after 4740) still comes on the way out.
5. The visit after the south loop no longer takes 4763 (Thundris is still visited there for 98042). The moonwell fill stays before the last northern trip.

### `QuestAlternateData.lua`, `ashenvale-early`

1. New `q(5713, "One Shot. One Kill.", 15, 10)`.
2. After Therylune's escort: `accept(5713)` and `objective(5713)` at Sentinel Aynasha (Darkshore 45.94, 90.29), then Kerlonian as before. After Liladris: `finish(5713, Sentinel Onaeya, Ashenvale 26.6, 36.73)`.
3. First Astranaar visit, new order: flight point; Shindrell (1008); bind at the inn; Raene (991); **Raene (1054)**, moved here from the second circuit: "Take it now: the hunt waits for the second circuit." The Thistlefur hunt and the hand-in are unchanged.

### `QuestAlternateData.lua`, `stonetalon`

1. New `q(1090, "Gerenzo's Orders", 22, 17)` and `q(1092, "Gerenzo's Orders", 22, 17, 1090)`.
2. After the Venture Co. objectives, on the way back: `accept(1090)`, `objective(1090)` (guard Piznik through the kobold waves), `finish(1090)` and `accept(1092)`, all at Piznik (71.87, 60.0). At Ziz: `finish(1093)`, then **`finish(1092)`**, then Gaxim as before.

### `QuestAlternateData.lua`, `ashenvale-late`

1. Start: `accept(4581, shindrell)` moves from after Raene's pickups to right after the flight point, before the bind.
2. The pendant (98027) leaves the first eastern circuit (it was after the Kayneth hand-in). Its pickup is now on the last circuit, after the Shadethicket Oracle and before the Night Run circle. Its hand-in to Maliynn moves from after the first hearth to after the last one, between Raene (1046) and Pelturas (1035).

Unchanged: every chapter ID, title, level range and `suggest` list.

## Gaps seen outside this scope

- **97914 Expanding Horizons** (Night Elf, Thundris to Baros): fits where the Teldrassil route takes the Auberdine ship to Stormwind.
- **Camping 101: Blacksmithing, Engineering, Mining** (97939, 97941, 97948): Teldrassil pickups handed in at Auberdine. They belong to the Teldrassil route as optional steps.
- **683, 686, 689** (Sara Balloo, King Magni, Marblesten): on Zygor's list under its Ashenvale 29-30 chapter. They follow 637 from the Wetlands route's Ironforge stop.
- **The guide A Wailing Caverns detour** (959, 1486, 1487, 6981), which its 21-23 Ashenvale/Stonetalon chapters run from Ratchet: dungeon scope.
- **Vyrin's Revenge (271, 531)**: would fit a Loch Modan chapter that came back to Farstrider Lodge at 20.
- **2931 Castpipe's Task**: needs a Gaxim visit at 25+, which no chapter makes.

## Check in game

- Loch Modan:
  - Ylva offers Banner of the Fallen during the 237 hunt (about level 14-15).
  - Jern offers Report to Ironforge right after the Ironband report.
  - Prospector Stormpike's spot in the Hall of Explorers.
  - Without the Ironforge flight path, the fly step's road hint.
- Darkshore:
  - The new town orders feel like one pass.
  - Barithras offers Cave Mushrooms on the second visit.
  - Thundris offers The Blackwood Corrupted at the 4762 hand-in, and the empty bowl keeps until the last northern trip.
- Ashenvale early:
  - Aynasha's spot and the event at 18-19, and that Onaeya stands beside Liladris.
  - Raene offers Culling the Threat on the first visit at 18-19.
- Stonetalon:
  - Piznik's tunnel and the length of the guarding at 21-22.
  - Ziz takes the ore.
- Ashenvale late:
  - Shindrell offers Kayneth Stillwind on arrival at 24 (a player coming straight from the early chapter at 22-23 may need to come back).
  - The pendant at 63.0, 71.6 on the way from Fallen Sky Lake to Night Run.
  - Maliynn takes it at the end.

## Results

- `tools/questroute.py audit`: passed (5,460 steps). Warning changes in these chapters:
  - New: `ashenvale-early`, "Culling the Threat is more than 5 levels above the section's current target". Dal Bloodclaw is level 25; the pickup now comes on the first Astranaar visit, as in guide A, where the audit's target is still 18. The hunt itself stays on the second circuit, so the warning stays.
  - Gone: `ashenvale-late`, "1646 yd from the prior waypoint with no travel step" (the pendant).
  - The `darkshore` warning for 4763 moved with the pickup (same text).
  - The other warnings are unchanged: the level warnings in `loch-modan` and `darkshore`, `ashenvale-early` step 2 and `stonetalon` step 31 distances.
- Loop check (Human, Dwarf, Night Elf and Skyborne; Warrior, Hunter and Priest):

| Chapter | Before | After |
|---|---|---|
| loch-modan | 15,855 yd (16,713 Dwarf), 1 late pickup | 15,883 yd (16,741), clean |
| darkshore | 29,121 yd, 4 hub lines, 1 late pickup | 27,894 yd, clean |
| ashenvale-early | 18,148 yd, 3 hub lines | 18,297 yd (Aynasha added), clean |
| stonetalon | 12,900 yd, clean | 12,953 yd (Piznik added), clean |
| ashenvale-late | 27,533 yd, 1 hub line | 26,486 yd, clean |

- `tools/questmobs.py --check`: up to date. The new quests are deliveries and events, with no creatures to target.
- `tests/run.py`: everything passed except `WARRIOR/full/blocked-report` ("FAILED: 1 run(s) failed"), which fails in any `.claude/worktrees/...` checkout because it wants a folder named `LevelingCodex`. The first run also failed `questLochBingles` ("Bingles starts at the wrench camp") and `questLochReady` ("a client-complete delivery resumes at the barrel") because of the 301 chain; both pass with the fix above, and no scenario was changed.
