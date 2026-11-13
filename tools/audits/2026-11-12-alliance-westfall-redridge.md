# 2026-11-12: Westfall, Lakeshire and late Redridge: loops and gaps

Sections: `westfall` and `lakeshire` in `QuestData.lua`, and `redridge-late` in `QuestAlternateData.lua`. This pass follows `2026-11-08-westfall-lakeshire.md`, `2026-11-10-westfall-redridge-duskwood-gaps.md` and `2026-11-10-route-audit-pass-2.md`. It uses the same method as `2026-11-12-wetlands-early-dig.md`: the extended loop check (late pickups, alternate chapters), the gap lists, and the reference routes. All three sections are still unverified.

## Why

The owner found two problems in the early Wetlands:

- a quest from an NPC the route already stood next to was never offered;
- a pickup came after the route had already walked through that quest's objective area.

This pass looks for the same two problems in Westfall and Redridge. The loop check flagged four lines, and the gap lists named several candidates (both listed below). One finding was not a loop at all: Lakeshire's gnoll quest sent the player to the wrong camp.

## Sources

- **Loop check:** `tools/questloops.py` from commit 80ebf63, which walks the alternate chapters and flags late pickups. It was run for Human, Dwarf, Gnome, Night Elf and Skyborne with every class.
- **Gap lists** (session scratchpad): `gaps-alliance.txt`, where list A holds quests guide A routes and we don't, and list B holds QuestieDB-only quests. `gaps-zygor-alliance.txt` was also used.
- **Guide A** (the local RXP Forever copy; see `2026-11-10-guide-cross-reference.md`). Only quest IDs, grouping, order and positions were used, never its text:
  - `Alliance-11-20.lua`: "13-15 Westfall" and "19-20 Redridge";
  - `dungeon/Alliance-11-20.lua`: "13-15 Westfall";
  - `Alliance-ADV-AoE-Mage-1-22.lua`: "16-18 ADV Westfall Mage AoE" and "20-22 ADV Redridge 1 Mage AoE";
  - `Alliance-Mage-12-21.lua`: "18-21 Redridge Mage AoE";
  - `RestedXP-Skyborne.lua`: "24-27 Duskwood/Redridge" and "24-27 Duskwood/Redridge/Stockades".
- **Zygor Forever guides (quest-ID gap check only).** Its "Westfall (13-15)" and "Redridge & Westfall (19-20)" guides were used for quest IDs and level bands only. No text, step order or code was used.
- **Bind on Forever:**
  - [Assessing the Threat](https://bindonforever.com/quest/246) and [Show of Force](https://bindonforever.com/quest/98407): both give one objective point, 10.7, 63.2 ("Three Corners"). Show of Force lists no prerequisite and starts at level 11.
  - [Humble Beginnings](https://bindonforever.com/quest/399): level 15, from level 10, Baros Alexston in Cathedral Square, compass at Alexston Farmstead (36.5, 54.5).
- **`tools/questfacts.py`** (QuestieDB Forever):
  - Redridge Thrashers (14-15): 6 at 11.0, 64.6, 4 at 9.6, 64.6 and 2 at 23.0, 80.9.
  - Redridge Mongrels (15-16): 7 at 26.3, 83.1, 4 at 11.0, 63.9 and 3 at 37.6, 72.1.
  - Redridge Poachers (16-17): 9 at 26.7, 83.0, 4 at 37.6, 71.4 and 3 at 25.5, 79.5. There are none at 10.7, 63.2.
  - Goulash ingredients:
    - Great Goretusks at 24.8, 75.0 and 25.9, 63.8, on the way south from Feldon;
    - Tarantulas at 16.5, 66.3, 6.4, 76.7 and 6.2, 83.9, around Guard Parker;
    - Dire Condors at 54.0, 76.2 and in the mill area.
  - Alexston's Chest is at 36.2, 54.5, and Baros Alexston at 57.74, 47.86 in Stormwind.
  - Flasks of Oil (item 814) drop from Harvest Golems, Watchers, Reapers and Foe Reapers. The nearest drop to the 142 step is the golems at 46.9, 67.2.
- **Client reference** (`tools/reference/forever.json`, QuestV2): has 116, 143-146, 343-347, 399, 1076, 1078, 95065 and 152. It doesn't have 117 (Thunderbrew Lager), 1641 or 1793.

## What was wrong

1. **Lakeshire, Assessing the Threat (246), wrong camp.** The objective pointed at the south-west camp (10.7, 63.2), where QuestieDB has only Thrashers and four Mongrels and no Poachers. The Mongrels and Poachers are mostly at the camp south of Feldon (26.5, 83). Guide A's gnoll loop covers both camps. The 10.7, 63.2 point comes from Bind on Forever's single objective marker.
2. **Lakeshire, Show of Force (98407), late pickup** (from the loop check). Feldon stands next to the gryphon master where the section starts, but the route took his quest only after the Guard Parker trip. The route then walked back west to the Thrasher camp it had just passed.
3. **Lakeshire hub** (not flagged by the tool). From the inn, the route went west, then south to the dock and Shawn by the bridge, then north-east to Oslow, Verner and Solomon, then all the way back south over the bridge. It now sweeps once and ends at the bridge. Later, Hilary's turn-in (by the bridge) came before Oslow and Baren in town, and then the route left over the bridge. She now comes last, on the way out.
4. **Late Redridge, town hub** (from the loop check). The route went from the gryphon master to the inn, back south to Guard Howe beside the gryphon master, and then north again. The Fangore poster sits a few steps from the inn but was read after the walk south. At the end, Howe (south of the bridge) came between Marris and Verner in town.

## Loop check (before / after)

| Line | Before | After |
|---|---|---|
| late pickup: lakeshire 98407 could be taken at westfall step 68 (via 10.7, 63.2) | yes | gone |
| hub: redridge-late 128 could be done at step 2 (360 yd) | yes | gone |
| hub: redridge-late 180 could be done at step 3 (107 yd) | yes | gone |
| hub: lakeshire 20 and 98387 (Marris) could be done earlier (222 yd) | step 57 vs step 9 | step 58 vs step 28, kept (see below) |

**Walk (tool, straight lines).**
- `lakeshire`: 8,203 yd before, 8,068 after (Human Warrior); 8,298 before, 8,276 after for the other classes. The old figure leaves out the Poacher hunt: a player following the old step still had to find Poachers at the south camp, about 670 yd there and back.
- `redridge-late`: 5,555 yd before, 4,802 after.
- `westfall`: unchanged. The new steps are optional, and the tool leaves optional steps out.

**Marris line, kept.** Blackrock Menace and Blackrock Blockade need level 18, and the route gates them with the "Reach level 18" grind step. The tool's level estimate is a straight line across the section, so it thinks Marris could be visited at an earlier town stop. The 222 yd comes from the grind step's position at the northern gnolls. In practice the section's turn-ins carry a level 17 player past 18 by Alther's Mill, so the grind step is usually already done and Marris is 30 yd from Oslow. Moving the grind check before the Alther's Mill turn-in would make players grind for XP they are about to get, so the order stays.

**Considered, not changed.**
- Westfall's Stormwind trip goes Old Town (Shaw), Dwarven District (Sprite), Old Town (Jasper Fel), Dwarven District (Sprite). Taking Sprite's chain first and Old Town once saves about 290 yd, but only for players who bring 10 Coarse Dynamite. Players who use Next past the dynamite would walk about 700 yd more. Most leveling players skip it, so the order stays.
- The westfall walk into Redridge passes Guard Parker at level 15. Taking Encroaching Gnolls (244) there would save Lakeshire a Feldon visit. But Lakeshire must still work alone (a level 19 Skyborne starts there), and the audit fails on a quest accepted in both sections, so 244 stays in Lakeshire.

## Gap check

RXP = guide A routes it in a 1-30 chapter. Zygor = in `gaps-zygor-alliance.txt` (Zygor accepts it, we didn't).

| Quest | Status | Reason | RXP | Zygor |
|---|---|---|---|---|
| 98407 Show of Force | **Reordered** | Taken at arrival beside the gryphon master; collars on the walk to Guard Parker | yes (route had it) | yes (route had it) |
| 246 Assessing the Threat | **Moved** | Objective now at the south camp (26.5, 82.5), with the 37.6, 72 group named | yes | yes |
| 399 Humble Beginnings | **Added, optional** | See Westfall below. The 11-10 pass-2 reason ("never passes the farmstead between two Stormwind visits") was wrong: Westfall visits Stormwind at 15-16 and Lakeshire at 18 | yes | no |
| 116 Dry Times | Left out (unchanged) | Its Keg of Thunderbrew Lager comes from 117, and the other three drinks are vendor items from other zones | Mage AoE only | no |
| 117 Thunderbrew Lager | Left out (unchanged) | Not in the client reference (QuestV2), so the route audit rejects it | Mage AoE only | no |
| 143, 144 Messenger to Westfall; 145, 146 Messenger to Darkshire | Left out (unchanged) | 143 opens only after Lakeshire's 121 turn-in at about 19. It would cost a Lakeshire-Sentinel Hill flight both ways for two level-14 deliveries, and 145 needs 144 | Mage AoE only (teleports) | no |
| 343 Speaking of Fortitude | Left out here | Needs level 20; Lakeshire's Stormwind trip is at 17-19. **Recommended for the `duskwood` section's Stormwind end:** Brother Kristoff (55.04, 54.16) is next to Bishop Farthing (269), and Milton Sheaf takes it with An Old History Book (337) | Mage AoE | yes (19-20) |
| 344-347 (Kristoff chain) | Left out (unchanged) | Northshire twice, Lakeshire and the Rethban Caverns | Mage AoE only | no |
| 1076 Devils in Westfall | Left out (unchanged) | Needs 1075 from Stonetalon. Our Westfall section ends at 17-18, before Stonetalon | 24-27 | no |
| 1078 Retrieval for Mauren | Left out (unchanged) | Stonetalon basilisk scales for a Stormwind NPC: the Stonetalon helper's | 24-27 | no |
| 95065 Fishin' Time | Left out (unchanged) | Stormwind harbor (26, 47) is off every Stormwind walk here. It needs a bauble and nightcrawlers from a vendor | 13-15 | no |
| 152 The Coast Isn't Clear | Left out | Four murloc kinds along the whole coast. The Coastrunners are only on the north shore, which the route finishes at 12-13 before meeting Grayson, and the Tidehunters are 18-19 | no | no |
| 136-140 Captain Sander's Hidden Treasure | Left out | Random map drop, then four stops across Westfall | no | no |
| 92911 Harvesting the Harvesters | Left out | The Engineering-parts version of 92909, which we route | no | no |
| 92109, 92110 Odd Child (Moonbrook barn) | Left out | Level 10, needs Silverleaf, Peacebloom and Empty Vials | no | no |
| 93928 Of Mice and Milk | Left out | Turned in to Nesingwary in Stranglethorn | no | no |
| 178 Theocritus' Retrieval | Left out | Item-started, with no known drop source in QuestieDB Forever. The turn-in is back at the Elwynn tower | no | no |
| 249 Morganth | Left out | Needs a second trip to the lion statue after the jar, then Morganth (26) in the Tower of Ilgalar, then Theocritus in Elwynn | no | no |
| 93963 Exploring the Alliance | Left out | A tour of the other capitals | no | no |
| 95772 Songblade Search, 386 What Comes Around... | Already routed | Excavation Site and Stockade dungeon guides | yes | no |
| 1641, 1793 Tome of Divinity / Valor (Paladin) | Out of scope | Class quests, and neither is in the client reference | 1641 | 1793 (19-20) |
| 2358 Horns of Nez'ra (Hunter) | Out of scope | Class quest | no | no |

## Data changes (for mirroring into the guide pages)

### `QuestData.lua`, quest registrations

- New: `q(399, "Humble Beginnings", 15, 10)` with `quest[399].optional = true`. It follows Settings > Show optional quests, like the Stormwind library errand it is handed in beside.

### `westfall`

1. Stormwind trip: after Shaw (135 turn-in, 141 pickup), **optional `accept(399, Baros Alexston 57.74, 47.86)`** on the way north to Sprite in the Dwarven District.
2. The Defias Messenger step (142, 44.5, 69.6) now adds: short of 5 Flasks of Oil for the lighthouse? The Harvest Golems just east of here drop them. Without the hint, a player without flasks walked lighthouse, Moonbrook, beach, lighthouse.
3. After the Grayson turn-ins (103, 104): **optional `objective(399)` at Alexston's Chest (36.2, 54.5)**, "A Simple Compass", on the way back to Sentinel Hill. This adds about 200 yd. For Druids it comes after the Strange Lockbox class step.

### `lakeshire`

New order of the first part (new or moved steps in bold):

1. getfp Ariena (unchanged).
2. **`accept(98407, feldon)`**: Feldon stands beside the gryphon master.
3. Bind at the inn (unchanged). Then the hub in one sweep that ends at the bridge: Darcy (129), Breanna (92), **Baren (127)**, then **Solomon (120), Verner (118) and Oslow (125)**, then Shawn (3741) by the bridge. The old order was Darcy, Breanna, Baren, Shawn, Oslow, Verner, Solomon. The Rogue's Lucius step still follows Baren.
4. **`objective(98407)` at the Thrasher camp, 10.5, 64.6** (was 10.7, 63.2). It now shows Redridge Goulash (92) alongside, for spider meat from tarantulas.
5. Guard Parker: 129 turn-in, 130 and 244 pickups (unchanged).
6. Feldon: 244 turn-in, **98407 turn-in**, then 246 pickup.
7. **`objective(246)` at the south camp, 26.5, 82.5** (was 10.7, 63.2), with 92 alongside for Great Goretusk snouts. The text names the second group at 37.6, 72.
8. **`finish(246, feldon)`**, then Martie and Darcy (unchanged).
9. The 98407 objective step that was paired with 246 at the same camp is replaced by step 4.

After the lake:

- Order is now Oslow (125 turn-in, 89 pickup), Baren (127), then **Hilary (3741) by the bridge**. It was Hilary, Oslow, Baren.
- The Goldshire step now says to cross the bridge first.

Stormwind trip:

- **Optional `finish(399, Baros Alexston)`** between Roy Lewells (97234 pickup) and Donyal Tovald. Cathedral Square lies between the park and the library. Without optional quests, neither step shows.

### `redridge-late` (`QuestAlternateData.lua`)

New hub order:

1. Theocritus (optional) and getfp (unchanged).
2. **Guard Howe (128)**, a few steps from the gryphon master.
3. **Marris (19, 115)**, then **Verner (126)**.
4. **The Gath'Ilzogg and Gar'im posters**, then **Conacher (91)**.
5. **Bind at the inn**, then **the Fangore poster (180)** a few steps south of the inn.
6. **Baren (150)**, then Martie (34) and Bellygrub.

The old order was getfp, bind, Howe, Conacher, Fangore poster, the two posters, Baren, Marris, Verner, Martie. Poster texts now name each poster instead of "second" and "third".

End of the chapter: **Marris (219), Verner (126), then Guard Howe (128)** by the gryphon master. It was Marris, Howe, Verner.

### `tests/scenarios.lua`

`S.questBind` and `S.questTravelBind` pinned "the bind step follows the flight path". Each now first checks "Accept - Show of Force" after the flight path and clicks Next once more. The rest of both scenarios is unchanged.

## Gaps seen outside this scope

- **343 Speaking of Fortitude** belongs at the `duskwood` section's Stormwind end. Kristoff stands beside Bishop Farthing, and Milton Sheaf takes it together with 337.
- **399 Humble Beginnings, cheaper version.** If a pre-Westfall Stormwind visit took 399 instead (`elwynn`, `dunmorogh`, `teldrassil`, `valanaar` all cross the city at 10-12), the compass would fit Westfall's Alexston step (the 13 objective at 36.4, 54.4) and the turn-in Westfall's Stormwind trip. That would mean:
  - moving this pass's optional accept out of `westfall`, since the audit fails on a quest accepted twice in one path;
  - moving the compass step to the 13 objective;
  - moving the turn-in from `lakeshire` to `westfall`.
- **147 Manhunt** (Elwynn, guide A's Dwarf/Gnome 11-12 chapter): for the `elwynn` auditor.
- **1793 The Tome of Valor** (Paladin, Zygor 19-20): not in the client reference, so it can't be routed.

## Check in game

- **Show of Force (98407):** Feldon offers it with no earlier quest at 17. Check the Thrasher camp at 10.5, 64.6 and how many collars drop from about ten Thrashers.
- **Assessing the Threat (246):** the Mongrels and Poachers are at the south camp (26.5, 82.5) and around 37.6, 72, and not at 10.7, 63.2. If the south-west camp does hold Poachers in Forever, the old spot was right and the Feldon round trip to the south camp is extra.
- **Lakeshire bridge:** the walk from town to the west road and to the south camp crosses the bridge at Feldon, as the new order assumes. Also check that the road to Goldshire leaves from the south end of the bridge.
- **Humble Beginnings (399),** with Show optional quests on:
  - Baros in Cathedral Square offers it at 15-16;
  - Alexston's Chest gives the compass;
  - Baros takes it on Lakeshire's Stormwind trip at about 18.
- **Westfall lighthouse:** players who skipped the flasks get them from the golems east of Moonbrook before the lighthouse.
- **Late Redridge:** Guard Howe's spot (26.45, 57.86) is next to the gryphon master. The Fangore poster is a few steps from the inn.

## Results

- `tools/questroute.py audit`: passed (5,452 steps). There are no warnings in `westfall`, `lakeshire` or `redridge-late`, before or after this pass.
- `tools/questmobs.py --check`: up to date.
- Loop check (80ebf63's `questloops.py`, Alliance, all races and classes): the four flagged lines are handled. Three are gone. The Marris line stays, for the reason above. No new lines appear in these sections.
- `tests/run.py`: everything passes except `WARRIOR/full/blocked-report` ("a blocked call names the Codex lines right above it"). That run fails in any `.claude/worktrees/...` checkout, because it wants a folder named `LevelingCodex`.
  - Among the passes are `questBind`, `questTravelBind` (both updated, see above), `questLayout`, `questSkyborne`, `questRedridgeOverlap`, `questLakeshireHandoff`, `questDungeonChoice` and `questWindowExtras`.
