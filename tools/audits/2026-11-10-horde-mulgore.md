# Horde route: Mulgore (Tauren 1-12)

`QuestHordeMulgore.lua` adds the Tauren start to `LevelingCodexQuests.HORDE`: `camp-narache` (1-6) and `mulgore` (6-12), both `start = "TAUREN"`, with `route.starts.TAUREN = "camp-narache"`. Quest order follows the RestedXP Forever chapters "1-6 Mulgore" and "6-12 Mulgore" (`RXP\forever\Horde-1-12_Mulgore.lua`; the dungeon copy in `RXP\forever\dungeon\` is the same chapters with Ragefire Chasm enabled). Facts come from `tools/questfacts.py` (QuestieDB Forever 0f7d8ad), the Forever client tables (`QuestV2`, `ItemSparse`, `UiMapAssignment` for the waypoint conversion) and bindonforever.com. Step texts are our own. Every quest ID is in the client reference; the route audit and the harness pass.

Tauren classes in Forever: Warrior, Hunter, Shaman, Druid (no new combinations for Tauren: mobalytics.gg, warcrafttavern.com). The trainer lists (`naracheTrainers`, `bloodhoofTrainers`) cover those four.

## Camp Narache (`camp-narache`, 1-6)

| Part | Notes |
|---|---|
| The Hunt Begins 747, A Humble Task 752/753 | Plainstriders on the way to the well; Greatmother Hawkwind's turn-in shows 747 progress. |
| Class notes 3091-3094 | From Grull after 747 (QuestieDB: prerequisite 747), handed in with the level 4 training. Class and race on the quest. |
| The Hunt Continues 750, Rites of the Earthmother 755, Rite of Strength 757 | Cougars on the way south to Seer Graytongue. |
| Grace of An'she and Mu'sha 95805 (Forever) | Timed 10 minutes. **Changed from RXP:** cougars are finished before Graytongue, so the incense is taken last and the route goes straight back to camp (750 turn-in, 780/3376 pickups, notes, training) and then east to the Ritual Fire with Battleboars on the way. RXP accepts it and then still finishes cougars and grinds first. |
| Brambleblade Ravine | Break Sharptusk! 3376, Attack on Camp Narache 781 (Dirt-stained Map 4851 on the ground), belts, Ritual Salve. Hearth to Camp Narache (`bind = "Camp Narache"`). |
| Call of Earth 1519 -> 1520 -> 1521 (Shaman) | Inline as in RXP: Earth Sapta (6635) at Kodo Rock. 94375/1518 are the Dwarf and Orc/Troll versions, not used. |
| The Adventurer 96659 (Forever), A Task Unfinished 1656 | Picked up last; lead into Bloodhoof. |

Training: levels 4 and 6.

## Mulgore (`mulgore`, 6-12)

| Part | Notes |
|---|---|
| Kaga Wildhoof: The Great Outdoors 96605, Camping 101: Cooking 96661 | Done on the way into the village (RXP's hardcore order); Cooking handed to Pyall Silentstride on the first village pass. |
| Camping 101: Skinning 97936, Herbalism 97933, Mining 97935 (optional) | Not in RXP. Same idea as the Alliance intros. Skinning goes to Yonn Deepcut (Bloodhoof 45.0, 61.4) right away, Herbalism to Komin Winterhoof (TB 50.0, 40.4) and Mining to Brek Stonehoof (TB 34.4, 57.9) on the first Thunder Bluff visit. |
| Village pickups | Sharing the Land 745, Rite of Vision 767/771/772, Dwarven Digging 746, Mazzranache 766, Chakuyak 96130, Kyle's Gone Missing! 99411, Swoop Hunting 761, Sparring Match 99108, Poison Water 748, Longwalker Malah 99079, Dangers of the Windfury 743. Hearth bound at Bloodhoof. |
| South loop | Paws/talons and Ambercorns, Winterhoof well (754), Well Stones. Kyle is fed (Tender Strider Meat: Forever item 287505, not RXP's 33009) back in the village. |
| East loop 1 | The Ravaged Caravan 749/751, Malah (99079 -> Grim Tidings 99081), Thunderhorn Totem 756 claws. |
| West loop | Chakuyak, Palemane gnolls, The Longwalkers 98430 escort (Forever). Then Our Ancient Enemy 99101 -> Drive Them Out 99080. |
| North loop 1 | Thunderhorn well (758), Bael'dun picks (746), Windfury talons (743), Seer Wiserunner (772 -> 773). Thunder Bluff: Stalk With The Earthmother 76156, bind, flight path. Red Rocks: A Sacred Burial 833, Ancestral Spirit (773 -> 775), swoops and Mazzranache leftovers. |
| The Demon Scarred Cloak 770 | `startItem = 4854` (Ghost Howl, level 12, spawns 34.7,34.2 / 47.1,47.8 / 46.7,25.5): only shows with the cloak in bags. |
| Level 10 village stop | Class quests (below), The Hunter's Way 861 (all classes, as RXP). |
| East loop 2 | Morin's Venture Co. 764/765, Fizsprocket's Notes 98424 (Forever, from the Mulgore Expansion Plans 281031; three pages as `objectivePart`), Seaforium charges for 76156, Drive Them Out (centaurs, Herak), Wildmane Totem 759. |
| Thunder Bluff visits 2 and 3 | Hearth in; 76156/76160/76240, 6089 (hunters), Preparation for Ceremony 744, Cairne (775 -> 776, 99082, 98430). North loop 2: feathers and Windfury Cones (Pine Salve), Wildmane well 760, Arra'chea 776, prowler claws 861. Back in TB: 776, 744, 76160 -> 76240 (Raw Brilliant Smallfish from the auction house or the pond), 861 -> Sergra Darkthorn 860. |
| Leaving | Wildmane Cleansing 760 at Mull, Thunderhorn's Report 98435 (Forever, not in RXP), level 12 training, east road, Camp Taurajo flight path, Journey to the Crossroads 854, road north to the Crossroads. |

Training: levels 8, 10, 12 in Bloodhoof Village.

### Class quests

| Quest | Handling |
|---|---|
| Veteran Uzzek 1505 (Warrior) | Accept at Krang; turn-in carried to the Barrens file. |
| Call of Fire 2984 (Shaman) | Accept at Narm Skychaser; turn-in carried to the Barrens file. |
| Taming the Beast 6061/6087/6088 -> Training the Beast 6089 (Hunter) | Inline (short and local), 6089 at Holt Thunderhorn on the second TB visit. |
| Heeding the Call 5926 (Druid) | Accept at Gennia, turn in to Turak on Elder Rise. **Check in game:** QuestieDB gives Gennia 5926 (5927 = Gart Mistrunner, 5928 = Innkeeper Pala, all exclusive), RXP uses 5928 at Gennia. The step says to use Next if Gennia has nothing. Moonglade 5922 -> Great Bear Spirit 5930 -> Back to Thunder Bluff 5932 -> Body and Heart 6002 are left for the class-quest pass. |
| The Barrens Oases 886 | Druids only (as RXP), accepted beside Turak. |

## CARRY (for the Barrens file / integration)

- turnin 860 Sergra Darkthorn at Sergra Darkthorn, Crossroads (all classes).
- turnin 854 Journey to the Crossroads at Thork, Crossroads (Tauren).
- turnin 886 The Barrens Oases at Tonga Runetotem, Crossroads (druids).
- turnin 1505 Veteran Uzzek at Uzzek, Far Watch Post (warriors).
- turnin 2984 Call of Fire at Kranal Fiss, the Barrens (shamans).
- turnin 98435 Thunderhorn's Report at Arch Druid Hamuul Runetotem, Thunder Bluff (next TB visit, e.g. Ride to Thunder Bluff 6362).
- Ragefire Chasm pickups 5722 and 5723 (Rahauro, `forDungeon`) are turned in by the dungeon guide.

## Skipped

| Quest | Reason |
|---|---|
| Ceasing Operations 98427 | Group quest (elite Clearcutter); not in RXP. |
| Traditions of the Bluff 97485 | Buy four vendor items in TB and sprinkle incense off Hunter Rise: reputation, costs money. Candidate optional step. |
| Gathering Leather 768, Kodo Hide Bag 769 | Skinning/leatherworking errands (RXP: auction house only). |
| Earth Sapta 1462 | Not in the client. |
| Camping 101 crafting intros 97927-97932, 97934, 97937 | Same reasoning as the Alliance starter audit. |
| Druid Moonglade chain | Class-quest pass (see above). |

## Check in game

- Positions: QuestieDB places Morin Cloudstalker at 54.8, 64.3; RXP finds him walking near 53.0, 63.8. Seer Wiserunner at 34.3, 43.3 (the converted RXP waypoint and QuestieDB agree; the RXP map comments use the older map frame).
- The Thunder Bluff lift waypoint (Mulgore 37.3, 38.4) is converted from RXP's lift approach; the TB-side waypoint is 35.3, 63.3.
- The Grace of An'she incense order (10 minutes) and whether Graytongue gives a new incense if it runs out.
- Thunderhorn's Report 98435: assumed to follow Wildmane Cleansing 760.
- Heeding the Call quest ID at Gennia (5926 vs 5928).
- Bind names: "Camp Narache", "Bloodhoof Village", "Thunder Bluff".

## Sources

- https://bindonforever.com/zones/mulgore
- https://www.warcrafttavern.com/forever/guides/tauren/
- https://mobalytics.gg/wow-forever/guides/wow-forever-race-class-combinations
- QuestieDB Forever 0f7d8ad, Forever client build 1.60.1.70862
