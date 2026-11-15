# 2026-11-14: Alliance 1-60 loop and gap audit: overview

The owner asked for the Alliance route to get the pass the Horde route had the same day (`2026-11-14-horde-1-60-audit.md`): loops that fit together and are walked smartly, quests the guide misses, optional quests, dungeon chains, and the vendor or Auction House items quests need. Levels 1-30 had a full pass on 11-12 (`2026-11-12-1-30-loops-gaps.md` and the four `2026-11-12-alliance-*` files); 30-60 was written on 11-10 (`2026-11-10-alliance-30-40.md`, `-40-50.md`, `-50-60.md`) and fixed in the Horde merge (`2026-11-12-horde-30-60-integration.md`), but never had the loop check. The same pass adds a feature for both factions: the step window asks before a quest whose target is an elite. Every chapter is still unverified until played.

## Method

- **Loop check.** `tools/questloops.py ALLIANCE` for all five races and all nine classes, main route and every alternate chapter.
- **Gap list.** Every quest the Alliance chapters of the two references accept, against every quest any Alliance section names (route, alternates, dungeon, class and special guides):
  - Reference guide A (RXP's Forever guides, the Nov 10 copy): the Alliance-*.lua chapters and the "(A)" groups of RestedXP-Skyborne.lua (the 21-60 speedrun and dungeon chapters, the Riverglades standalone chapters, the dungeon quest guides). Parsed from the `RegisterGuide` blocks, their `<< Alliance` headers and `.accept` lines; steps or lines filtered `<< Horde` dropped. Used for quest IDs, grouping, order and positions, never its text.
  - Zygor Forever guides (quest-ID gap check only): `accept Name##ID` lines of the Alliance leveling file. No text, order or code taken.
  - Horde-only quests dropped with QuestieDB `requiredRaces`.
  - Result: 420 quests no Alliance section names. 219 are level 60 raid, Ahn'Qiraj, Naxxramas, cloth-donation, level 60 class chains or Season of Discovery copies (out of scope). The rest went to the band that owns their zone, each with the earlier audits that already gave it a verdict.
- **Vendor and Auction House.** Every guide A buy or Auction House step and every Zygor `buy` line in the Alliance chapters, against our `buy`/`collect` steps and `QuestShopData.lua`; plus every Alliance route quest's QuestieDB item objectives, sorted into vendor-only, vendor or drop, and no source (crafted, Auction House or quest-given).
- **Elite list.** Every Alliance route quest whose kill target or item dropper QuestieDB ranks elite, rare elite or boss, for the new elite question.
- **Three band audits ran in parallel**, each limited to its own file:

| Band | Sections | Audit file |
|---|---|---|
| 30-40 | darkshire-30, hillsbrad-32, needles-33, desolace-35, stv-36, swamp-38, arathi-39, dustwallow-40 and the stv-30, theramore-33 alternates | `2026-11-14-alliance-30-40.md` |
| 40-50 and the Riverglades | desolace-40, badlands-41, stv-41, tanaris-43, feralas-44, hinterlands-48, ungoro-49 and the riverglades-farholde, riverglades-shroud, shendralas, searing-gorge, blasted-lands-47 alternates | `2026-11-14-alliance-40-50.md` |
| 50-60 | stv-50 to silithus-60 and the azshara-alt, searing-alt, winterspring-alt, silithus-alt alternates | `2026-11-14-alliance-50-60.md` |

Levels 1-30, the dungeon, special and class guides, the elite feature and the moves between band files were done here.

## Levels 1-30

The loop findings are the thirteen explained on 11-12 (`2026-11-12-1-30-loops-gaps.md`, `2026-11-12-alliance-1-12.md`): level gates (Northshire 18, Coldridge 3361, Zephras 94414 and 92474), escorts and objectives inside one area (Teldrassil 99053, Zephras 92481 and 93552, Loch Modan 86585, Coldridge 97277), the log (Wetlands 472) and small costs a move would only shift (Lakeshire 20/98387, Teldrassil 490, Wetlands 98208). None is new.

Every gap-list quest at 1-30 already had a verdict from 11-10 or 11-12, and those verdicts stand (none was "the log" or "missing data" with an optional step that now fits). The two that had none:

- **The Barrens Port chain (1039 > 1040 > 1041 > 1042 > 1043)** starts at Thyn'tel in Darnassus, where `ashenvale-late` ends, and runs through Ratchet, Booty Bay and Darkshire in the thirties. Passed to the 30-40 band (its verdict is in `2026-11-14-alliance-30-40.md`).
- **Pristine Pesterhide Pelts (98155)**, a Forever quest Zygor files under Thousand Needles at 33: passed to the 30-40 band.

Carnage (98283, Rethiel, a summoned level 30 elite) stays out: the 11-10 reason was the group, and the Wetlands log is at 20 of 20 on its coast trip. The elite question could carry it now if the owner wants it (open decisions).

### Data changes (for mirroring into the guide pages)

| Section | Step | Before | After | Reason |
|---|---|---|---|---|
| `elwynn` | WANTED: "Hogger" (176) | plain pickup | elite quest (Hogger): the route asks at the poster | Hogger is a level 11 elite (QuestieDB) |
| `dunmorogh` | Protecting the Herd (314) | plain | elite quest (Vagash) | Vagash, level 11 elite |
| `teldrassil` | Oakenscowl (2499) | "Bring help or use Next" | elite quest (Oakenscowl); text "Kill elite Oakenscowl southwest of the lake, then head to Gnarlpine Hold." | level 9 elite |
| `darkshore` | Gyromast's Revenge (2078) | plain | elite quest (The Threshwackonator 4100) | level 20 elite at the end of the escort |
| `wetlands` | Death to the Dragonmaw (98291) | plain | elite quest (the Dragonmaw at Dragonmaw Retreat) | Forever quest: 16 kills of level 29-30 elites |
| `redridge-late` | Tharil'zun (19), Shadow Magic (115), Wanted: Gath'Ilzogg (169) | plain | elite quests (Tharil'zun; the Blackrock Shadowcasters of Stonewatch Keep; Gath'Ilzogg) | Stonewatch Keep's orcs are elite (QuestieDB) |
| `lakeshire` | Stormwind visit, before the flight path | - | optional buy step: Stormwind Seasoning Herbs (item 2665) from Felicia Gump (Stormwind 69.3, 71.3) | Seasoned Wolf Kabobs (90) in Darkshire needs them; only Felicia sells them (QuestieDB vendors) |
| `duskwood` | Seasoned Wolf Kabobs (90) pickup | "Buy Stormwind Seasoning Herbs from a cooking supplies vendor." | "He also wants Stormwind Seasoning Herbs: Felicia Gump in Stormwind sells them, and so does the Auction House." | Darkshire has no such vendor |
| `duskwood-late`, `ashenvale-late`, `southshore` | section `suggest` | 1-30 chapters only | `darkshire-30` first | each ends at 30; darkshire-30 is the main route's next chapter (its first step is the Auberdine ship, where ashenvale-late ends) |

### Vendor items (1-30)

- Beer Basted Boar Ribs (384, Rhapsody Malt), The Great Tree Provides (99050, Empty Vial), The Third Fleet (288, Flagon of Dwarven Honeymead): already right, the objective step stands at the vendor and the shopping card offers to buy.
- Seasoned Wolf Kabobs (90): fixed above.
- Look To The Stars (174, Bronze Tube): left as text (an engineer's item; Herble in Darkshire or the Auction House), as before.
- The Touch of Zanzil (2609, rogue): left as text in the class guide (three Stormwind vendors named in the step).

### Class objectives on the route (1-30)

Placed after a named step (`inline`, QuestClassData.lua's end block). The Horde rule (before the anchor step when that saves 50 yd or more) moved three:

| Section | Class quest | Before | After | Saved |
|---|---|---|---|---|
| `coldridge` | Shaman: Call of Earth (94373) pendants | after Grik'nir's journal (218), "on your way back out" | after Felix's box (3361), "on your way in to Grik'nir" | 228 yd |
| `darkshore` | Druid: Trial of the Sea Lion (272) lockbox | after the spire's Beastmistress (87760) | after Gelkak's turn-in (2078), then on to the spire | 57 yd |
| `ashenvale-early` | Warlock: Heartswood (1738) | after the Glowing Soul Gem (970) | after Orendil's pickup (1010), as you reach the ruins | 53 yd |

The other 18 placements are within 50 yd of their best spot.

## Dungeon guides

Each guide's quests were compared with guide A's "Dungeon Quests (A)" chapter for that dungeon. Nearly all were already in our guides (or in the class and special guides: the Sunken Temple class quests, the Onyxia, Molten Core and Shadowforge chains). The Horde guides had four chains the Alliance guides lacked; they are added with the same steps (the NPCs are neutral) and two more from guide A:

| Guide | Added | Steps | Source |
|---|---|---|---|
| Uldaman | Power Stones (2418) | prepare: Rigglefuzz (Badlands 42.39, 52.93) after Ryedol's pickups; inside: 8 Dentrium and 8 An'Alleum Power Stones from the Shadowforge dwarves; after: Rigglefuzz between Ryedol and Theldurin | guide A's Uldaman chapter, the Horde guide, QuestieDB |
| Sunken Temple | The Ancient Egg (4787) and The God Hakkar (3528) | prepare: Yeh'kinya (Tanaris 66.99, 22.36) at the Tanaris stop, shown once Zul'Farrak's Prophecy of Mosh'aru (3527) is turned in; the egg in Jintha'alor (Hinterlands 57.6, 86.8, QuestieDB object); hand-in and the Egg of Hakkar after the Un'Goro stop; inside: the altar event and the Avatar of Hakkar (`uncertain`); after: Yeh'kinya | guide A, the Horde guide, QuestieDB |
| Blackrock Depths | A Taste of Flame (4024) | prepare: Cyrus Therepentous (Burning Steppes 95.09, 31.56), shown once the route's 4022 is turned in; inside: Bael'Gar and the Altered Black Dragonflight Molt (11231); after: Cyrus | guide A, the Horde guide |
| Stratholme | The Argent Hold (5265) | after: Lord Maxwell Tyrosus opens the hold at Light's Hope (71.96, 48.41) | guide A, the Horde guide, QuestieDB |
| Gnomeregan | Gnome Improvement (2948) | after: Talvash improves the Return of the Ring ring for a Silver Bar, a Moss Agate (Auction House) and 30 silver | guide A |

`afterDone(id, step)` (QuestDungeonData3060.lua) shows a pickup once a quest from another guide or the route is turned in (`ifDone`, no `chain`), so each guide still runs on its own and the route audit can simulate it alone.

Left out:

- **Healthy Dragon Scale (5582)**, Scholomance: not in the client's quest list (forever.json).
- **The Final Tablets and Confront Yeh'kinya (4788, 8181)**, Lower Blackrock Spire: they need The Lost Tablets of Mosh'aru (5065), which no Alliance guide reaches; level 58.
- **Return to the Hinterlands (2993)**, Zul'Farrak's last step from Thadius to Talonaxe: its follow-ups run past the guide and the Hinterlands chapter.
- **Upper Blackrock Spire:** Egg Freezing and Egg Collection (4734, 4735, level 60), the Hydraxis chain (6804, 6805, 6821: the Molten Core attunement) and Blackhand's Command (7761: Blackwing Lair). Raid chains and level 60.
- **Arcane Refreshment (7463)**, Dire Maul: a level 60 Mage quest.

No game-enforced dungeon prerequisite missing from QuestieDB turned up on the Alliance side (the Horde's was The New Plague).

## Moves between band files (made during the merge)

| Where | Problem | Change |
|---|---|---|
| 30-40 / 40-50 | desolace-40, stv-41 and tanaris-43 held hand-ins with no pickup anywhere (Nesingwary's hunts, Colonel Kurzen, Troll Witchery, Ansirem's Key, Sunken Treasure, ... and Bugs, Goblin Sponsorship, Rhapsody's Kalimdor Kocktail): optional steps that never showed | The 30-40 chapters give 193, 196, 202, 205, 603, 669, 1183, 1258 and 1452 where the route already stands; the 40-50 steps are required and accept none of them. Dead steps went: Ongeku and the Valley of Bones chain (1373, 1374, 93034-93128), Kravel's later chain (1116-1122), 95315 |
| 30-40 / 50-60 | Reassignment (563) had no hand-in: it sat in the log from 32 to 60 | Handed in to Major Samuelson on swamp-38's Stormwind Keep stop |
| 40-50 / 50-60 | Stranglethorn Fever (348) was accepted in both stv-41 and stv-50 | stv-41 only (with the gorilla fangs and Mokk); out of stv-50 |
| 40-50 / 50-60 | Super Sticky (4504), Expedition Salvation (3881), The Captain's Chest (8551) late pickups | Kept where they are by agreement: each would hold a slot through 49-53 (see the 50-60 file) |
| 40-50 | The Riverglades crates (93443, 94929) from stv-36 and swamp-38 have their only hand-ins in the Farholde chapter | Clean-up note at the start of badlands-41 (a player heading for Farholde keeps them) |
| Sunken Temple guide | It accepted Rhapsody's Tale (1469) itself and copied hinterlands-48's pickup, which the route now really takes | Its own accept went |
| `tools/questroute.py` | The Skyborne druid's Moonglade (94914) is picked up on the route and handed in by a class guide, so the log simulation held it to 60 (one slot at every 30-60 peak) | A class quest the route picks up and a class guide hands in retires past that guide's last level + 3, like a dungeon pickup |

## Class objectives on the 30-60 route (new)

The Horde has had copies of the class guides' objective steps on its 30-60 route since 11-12 (`passing()` in QuestHordeClass3060.lua); the Alliance had none. A matching block at the end of QuestClassData.lua now places them after the closest step on the same map, or before it when that saves 50 yd or more (other classes' steps placed there don't count as neighbours). Each shows only to its class and only while the quest is in your log.

| Section | Class quest | Distance from the nearest route step |
|---|---|---|
| `stv-36` | Warrior: Cyclonian (1712), 30 Bloodscalp Tusks | 94 yd |
| `desolace-40` | Mage: The Infernal Orb (1954); Warlock: Fragments of the Orb of Orahil (1799), Shard of a Felhound (4962) | 186, 186, 329 yd |
| `blasted-51` | Warrior: Warrior Kinship (8423, Helboars), War on the Shadowsworn (8424) | 410, 158 yd |
| `azshara-53` | Hunter: Courser Antlers (8153); Priest: Of Coursers We Know (8255); Mage: Magic Dust (8251), The Siren's Coral (8252); Rogue: Sealed Azure Bag (8234), Encoded Fragments (8235) | 231, 231, 24, 357, 481, 130 yd |
| `plaguelands-57` | Priest: The Ichor of Undeath (8256) | 42 yd (wpl-51 is closer, but 8256 needs Azshara's 8255 first) |

Left out: the Hunter's Wavethrashing (8231): the Wavethrashers are on Azshara's east coast, 1,600 yd from the route.

## Loop check, before and after

Distinct findings (main route), five races with nine classes, by the finding's own section:

| | Before | After |
|---|---|---|
| Levels 1-30 | 13 | 13 (unchanged, explained 11-12) |
| Levels 30-40 | 8 | 6 |
| Levels 40-50 | 8 | 6 |
| Levels 50-60 | 10 | 7 |
| All | 39 | 32 |

The band agents also walked each alternate chapter: 40-50's two (farholde and searing-gorge zig-zags) are gone; the others had none.

New in the list, explained:
- **blasted-51 hub (the five bloodmage hand-ins)**: an artefact of the new Auction House `collect` step, which makes the tool count the parts as ready at the pickup. A player who bought them hands in right away and uses Next past the hunting note; one who didn't walks the hunt as before.
- **stv-41 hub for Keep An Eye Out (576)**: moved to a later Booty Bay visit on purpose to keep stv-41 at 20 (40-50 file).

The rest are level gates, log choices and cross-band agreements, each in its band file. Walking grew with the added quests: a Human Warrior walks about 425,200 yd, up from 404,600 (Night Elf Druid 433,300, up from 414,000). Reordered chapters are shorter: badlands-41 -2,564 yd, stv-36 -1,780, arathi-39 -1,206, ungoro-49 -1,007, searing-gorge -367.

## Quest log

At 20 or fewer everywhere, with every dungeon planned and optional and elite steps on (the route audit's pass). The peaks: stv-36, arathi-39, badlands-41 and stv-41 at exactly 20; every 50-60 section at 18 or fewer.

## Vendor and Auction House items

Quests that need a bought item say where to get it at a step before the trip (details in the band files):
- **Vendor `buy` steps:** Stormwind Seasoning Herbs (Felicia Gump, for Seasoned Wolf Kabobs), Gregan's Bait, the Riverglades goods (Goes Down Smooth, Marla Bell's candles, the Powderfuse goods), the Soothing Spices (already there).
- **Auction House `collect` steps or notes:** Hillman's Cloak and Bolts of Woolen Cloth (Ironforge, for Bartolo's Yeti Fur Cloak), an Elixir of Water Breathing, a Moonsteel Broadsword (Jarl Needs a Blade), Silk Cloth, the five bloodmage parts, the Mithril Casing, the Evoroot, Gnome Improvement's Silver Bar and Moss Agate; text for Jungle Remedies and a Catseye Elixir.
- **Already right:** Rhapsody Malt, the Empty Vial for The Great Tree Provides, the Flagon of Dwarven Honeymead (each objective stands at its vendor).
- **Left as text:** Look To The Stars' Bronze Tube (an engineer's item), The Touch of Zanzil's three Stormwind vendors (rogue class guide).
- `QuestShopData.lua` is regenerated (still 10 quests). Two Riverglades quests with vendor items, 95988 and 95613, have no QuestieDB record, so their buy steps carry the item IDs.

## Generated files

`QuestMobData.lua` (871 quests) and `QuestNPCData.lua` (2,692 quests) are regenerated for the new route quests; `QuestShopData.lua` is unchanged.

## Open decisions for the owner

- **The Barrens Port chain (1039-1043).** It starts where `ashenvale-late` ends (Thyn'tel in Darnassus) and the 30-40 route passes every hand-in (Ratchet, Booty Bay, Darkshire), but stv-36 is already at 20 of 20 with everything on. It fits only if stv-36 frees a slot.
- **Carnage (98283, Wetlands).** Left out on 11-10 as a group quest; the elite question could carry it now, but the Wetlands coast trip is at 20 of 20.
- **Shared quest records.** Both factions share a quest's record, and steps copy its flags when they're built. The Alliance flags on 193, 197, 202, 208, 7701 and 95120 therefore reach the Horde steps too (as intended). The Alliance `stv-50` leaves The Captain's Chest (8551) unflagged at 50 (Gorlash is 47), while the Horde's `stv-44` asks at 44. Say if both should ask.
- **Fastest pace.** It doesn't set Always skip: an elite quest is often good XP with a group. Say if Fastest should skip them.
- **Dragonkin Menace (4182)** is flagged (black dragonkin elites): skipping it also passes The True Masters chain that follows it in `steppes-56`. The Onyxia attunement guide is a special guide and isn't affected.

## Check in game (top items; each band file has its full list)

- The elite question:
  - at Hogger's poster in Elwynn: the question, Take it and Skip, Back after Skip, the Quests tab's Step buttons with a controller;
  - Settings > Elite quests and the setup card row;
  - a Horde one: King Bangalash at Hemet, or the Swamp Talker at Bengor (A Tale of Sorrow passes with it).
- Reassignment handed in to Major Samuelson in Stormwind Keep.
- Stranglethorn's Nesingwary and Rebel Camp hunts picked up at 36-38 and handed in at 41-43.
- The Riverglades chains in the game's order (the 40-50 file's list).
- Dungeon guides: Rigglefuzz's Power Stones, Yeh'kinya's egg and The God Hakkar's altar event, Bael'Gar and the molt, the Argent Hold, Talvash's ring, Return to the Hinterlands.
- Class objectives: a Warrior's Bloodscalp tusks in Stranglethorn, the Desolace orbs, the Azshara steps.
- Coldridge: a Shaman's pendants on the way into the troll cave.
- Felicia Gump beside Stormwind's gryphons (optional, Show optional quests).

## Results

- `tools/questroute.py audit`: "Route audit passed (12646 steps)" (12,427 before). New warnings are level and long-ride notes, listed in the band files' Results.
- `questmobs.py --check`, `questnpcs.py --check`, `questshop.py --check`: up to date.
- `tools/questloops.py`: as above.
- Full harness: 350 runs, all pass. WARRIOR/full/blocked-report fails in the worktree (it needs a folder named LevelingCodex) and passes from a copy in one.

## Elite quests ask first (new, both factions)

The 11-14 Horde pass made elite quests optional (owner's decision that day). The owner then asked for a question instead: when the route reaches the pickup of a quest that needs an elite killed, the step window asks.

- **Data.** `B.elite(id, "Name")` (QuestData.lua `elite`) sets `quest[id].elite`, which every step built from the quest copies. A follow-up that needs the same elite again gets the same flag; a talk or hand-in follow-up gets none (the skip passes it through its `chain`).
- **The question.** Before each leveling pickup of an elite quest, `buildRoute` puts an "Elite quest" row at the pickup's spot (the arrow and map pins lead there). The step window shows "<quest> means fighting <elite> (elite): bring a group or a strong partner", **Take it** as the primary button and Next labelled **Skip**. The Quests tab's Step view has Take it and Skip it, for controller players.
- **Skip** passes the quest's steps and every quest whose prerequisite it is (2801 after the Swamp Talker, 7847 after Hitah'ya...), and says so in chat. **Back** on the next step brings the question back.
- **Never asked** when the quest is in your log or turned in, or while its pickup isn't the next thing (done, grey, missed, not for your class or race).
- **Saved per character** (`LevelingCodexCharDB.questElite`). With lost SavedVariables the guide just asks again.
- **Settings > Elite quests** and the setup card's Elite quests row: Ask (default), Always take, Always skip (`LevelingCodexDB.questEliteMode`). The Fastest pace doesn't change it: an elite quest is often the best XP in a zone with a group, so the pace row leaves that choice to this row.
- **Route audit.** `questroute.py` knows `elite` (ASCII, on a quest step). Its log simulation leaves elite quests and the quests that need them out of the plain pass and counts them in the optional/dungeon pass, as it did for the optional ones.
- **Tests.** `questEliteAsk` (Hogger's poster: the question, both windows' buttons, Skip, Back, Take it), `questEliteInLog`, `questEliteModes` (Settings and the setup card), `questEliteChain` (a fixture: Skip it in the Quests tab passes the follow-up, Take it continues), `questEliteFresh` (no quest-log or map APIs and nothing saved; also on the minimal client).

### Horde quests switched from optional to the flag

| Quest | Elite | Where | Before | After |
|---|---|---|---|---|
| Big Game Hunter (208) | King Bangalash | `stv-44` | pickup, kill, hand-in optional | required, asked at Hemet |
| The Captain's Chest (8551) | Gorlash | `stv-44` | optional | asked at Smotts |
| The Bloodsail Buccaneers (608) | the three Bloodsail captains | `stv-44` | optional | asked at Seahorn |
| The Swamp Talker (2623), A Tale of Sorrow (2801) | the Swamp Talker | `swamp-45` | both optional | 2623 asked at Bengor; 2801 required, passed with a skipped 2623 |
| Wanted: Vile Priestess Hexx (7861) | Vile Priestess Hexx | `hinterlands-48` | optional | asked at the Call to Arms board |
| Recover the Key! (7846), Return to Primal Torntusk (7847) | Hitah'ya the Keeper | `hinterlands-48` | both optional | 7846 asked at the elder; 7847 required, passed with a skipped 7846 |
| WANTED: Overseer Maltorius (7701) | Overseer Maltorius | `searing-45`, `searing-51` (and `searing-alt`, which copies searing-51's required steps, so it has 7701 again) | optional | asked at the board |
| Foul Magics (673), The Real Threat (680) | Marez Cowl, Or'Kalar | `arathi-38` | optional | asked at Tor'gan and Korin Fel |

The pickups' "Take it if you have a group/partner" sentences went: the question says it. Gammerita (7816) stays an optional side trip, as asked.
