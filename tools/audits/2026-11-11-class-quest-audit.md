# Class quest audit: our guides against RestedXP and Zygor (levels 1-30)

The owner asked (2026-11-11), before pushing the Warrior Thelgen Rock step, for an audit of every class quest and of how RestedXP and Zygor handle them. The owner pointed at their local copies (`C:\Dev\Starbreak\reference\Upload Nov 10 6_50 PM\RXPGuides`: RestedXP `Guides/forever` and Zygor `Guides-Forever/Leveling`) and allowed using them for facts. Only quest IDs, placement and structure were taken. None of their wording or code is in the addon.

## Method

- **Ours:** every step with a class (or in a class side section) in the shipped route data, loaded through the test mock: 236 Alliance and 237 Horde class-quest entries.
- **Theirs:** three readers listed every class quest up to 30 in RestedXP Alliance, RestedXP Horde and Zygor (both factions plus the shared Skyborne starter), with where each sits and what it is done alongside.
- **Checks:** every ID they have and we don't went through `questfacts.py` (QuestieDB Forever 0f7d8ad) and both client quest tables (`QuestV2.csv`, builds 1.60.1.70862 and 70888).

## Coverage

Distinct class quests up to 30 (ours counts every race's version):

| Class | Alliance: ours / RXP / Zygor | Horde: ours / RXP / Zygor |
|---|---|---|
| Warrior | 38 / 13 / 15 | 32 / 18 / 15 |
| Paladin | 33 / 26 / 33 | 29 / 17 / 12 |
| Hunter | 20 / 20 / 16 | 17 / 16 / 11 |
| Rogue | 30 / 13 / 17 | 29 / 19 / 19 |
| Priest | 21 / 14 / 16 | 11 / 12 / 12 |
| Mage | 24 / 13 / 13 | 25 / 5 / 16 |
| Warlock | 23 / 15 / 17 | 29 / 17 / 25 |
| Shaman | 19 / 21 / 9 | 36 / 32 / 25 |
| Druid | 28 / 27 / 15 | 29 / 23 / 16 |

**No class quest is missing on our side.** Every ID they have and we don't is one of these:

| IDs | What they are | Verdict |
|---|---|---|
| 1641, 1645 (Tome of Divinity), 1793, 1794 (Tome of Valor), 1655 (Bailor's Ore Shipment), 1442 (Seeking the Kor Gem), 972 (Water Sapta) | Classic quests both add-ons carry over | Not in either Forever client build. Our side guides describe these errands in prose, as decided in `2026-11-08-class-warrior-paladin.md`. Keep. **Check in game:** if the client offers them, add them as steps. |
| 5635, 5637 (Desperate Prayer referrals), 6071 (The Hunter's Path), 1919 (Report to Jennea) | Breadcrumbs to a trainer | Our class guides go straight to the trainer (`2026-11-10-route-audit-pass-2.md`). Optional to add. |
| 5925, 5928 (Heeding the Call), 5652 (Hex of Weakness), 5643 (Shadowguard), 5672 (Elune's Grace), 5679 (Devouring Plague) | Exclusive alternatives from another giver | We route 5923/5926, 5654, 5642, 5674 and Dark Sacrifice 5644. Keep. Gennia's 5926 vs 5928 is still to check in game. |
| 92466-92468, 97243-97257 (Alliance Skyborne Shaman), 93791/93797 (Horde Skyborne Mage) | Zygor lists the Skyborne starter for both factions; RestedXP gives an Alliance Skyborne Shaman the first pickup | High Order Skyborne can't be Shamans and Windshaper Skyborne can't be Mages (Blizzard's race/class matrix). Not a gap. |
| 1791 (The Windwatcher), 4738 (In Search of Menara Voidrender) | Level 30-31 chains finished at 33+ | Past our route. |
| 77573 (Zygor's NE Rogue) | A Season of Discovery ID | Not a Forever quest. |

Where we have more: Mage and Warlock chains on both factions, the Forever race/class combos (Human Hunter, Dwarf Shaman, Gnome Priest, Orc Mage, Troll Warlock, Undead Paladin) and Skyborne. Zygor's class guides don't cover the Forever combos at all.

## How each add-on places class quests

| | RestedXP | Zygor | Leveling Codex |
|---|---|---|---|
| Where | Everything inline in the zone guides, tagged by class and race. No class guides. | A separate "Class Quests" guide per class (a level-gated catch-up checklist, no hand-back) plus inline steps in the leveling guides. | Short quests inline on the route. Longer chains are class guides in the Quests tab and Missed quests, and you return to leveling afterwards. |
| Quest-in-log gating | Checks a quest is in the log, available or turned in before a step shows (e.g. Orc/Troll Warriors and Warlocks do their level-10 chains in Tirisfal). | "Sticky" objectives that stay open across several route steps; items collected before the quest is in the log. | `also` lists live progress for accepted quests. New: `logOnly` steps show only while the quest is in the log (Thelgen Rock fangs). |
| Race variants | One line per race and class | Its own ID in the same step | `race` on the quest, one side guide per race group |

## Pairings: class objectives done alongside route quests

Both add-ons send you after class objectives while the route is already at those mobs or places. In the starting zones we already do the same inline:
- Horde: Deathknell 1470 and 91208, Tirisfal 1473, 1882, 91285, 91294 and 91316, the Valley of Trials 1516 and 1485, Camp Narache 1519, northern Durotar 1501 and 1963.
- Alliance: Coldridge 1599.

From level 10 up, these class objectives live only in our class guides. The route passes the same spot, but nothing on it says so. They are the candidates for `logOnly` objective steps like the Warrior fangs (shown only to that class, and only while the quest is in the log):

| # | Class quest (ours) | Do it with | Source |
|---|---|---|---|
| 1 | Dwarf Shaman Call of Earth 94373 (side `shaman-earth-totem`) | The Troll Cave 182, Coldridge | RXP + Zygor |
| 2 | Dwarf Shaman Call of Fire 94466 (Fire Tar, Reagent Pouch) | Rat Catching / Ironband's Excavation 436 (Tunnel Rat Geomancers), Excavation Progress Report 298 (Stonesplinter Seers), Loch Modan | RXP + Zygor |
| 3 | Human/Gnome Warlock Surena Caledon 1688 | Red Linen Goods 83, Elwynn (Dwarf/Gnome: Manhunt) | RXP + Zygor |
| 4 | Druid Trial of the Sea Lion 272 (pendant halves) | Darkshore north coast; Westfall coast after The Coastal Menace | RXP + Zygor |
| 5 | Horde Shaman Call of Fire 1525 (Fire Tar, Reagent Pouch) | Razormane camps (Conscript 840, Encroachment 837); Burning Blade with Dark Storms 806 | RXP + Zygor |
| 6 | Dwarf Shaman Call of Water 94497 | Lieutenant Fangore at Stonewatch Falls, Redridge | RXP |
| 7 | Paladin Tome of Valor (Verigan's Fist chain) | Westfall coast stops with the Druid pendant | RXP + Zygor |
| 8 | Druid cure poison 6123 (Earthroot) | Cleansing of the Infected, Darkshore | RXP |
| 9 | Druid Lunaclaw, Body and Heart 6001 | First Darkshore stop after Flight to Auberdine | Zygor |
| 10 | Druid The Principal Source 6122 | Cliffspring, after Gyromast's Retrieval 2098 | Zygor |
| 11 | NE Rogue Destiny Calls 2242 | Teldrassil, between Tears of the Moon 2518 and Tumors 923 | Zygor |
| 12 | Rogue Alther's Mill 2282 | Redridge, before A Baying of Gnolls 124 | Zygor |
| 13 | Rogue Klaven's Tower 2359 | Westfall, with The Legend of Stalvan 67/68 | Zygor |
| 14 | Warlock Heartswood 1738 | Ashenvale, after The Tower of Althalaxx 973 | Zygor |
| 15 | Horde Warrior Path of Defense 1498 (Singed Scales) | Stormy Potential 97282, same Thunder Lizards | Zygor |
| 16 | Horde Warrior Trial at the Field of Giants 1824 | The Field of Giants quests 884, 897 | RXP |
| 17 | Horde Rogue Plundering the Plunderers 2381 | Southsea camp, before Stolen Booty 888 | Zygor |
| 18 | Horde Rogue Mission: Possible 2478 + Tauren Druid pendant | One Sludge Fen trip | RXP |
| 19 | Horde Shaman Call of Water 1536 / 1534 (waterskins) | Hillsbrad after The Rescue 498; Ashenvale after Between a Rock and a Thistlefur 216 | Zygor |
| 20 | Tauren Druid Trial of the Sea Lion 30 | Barrens north coast; Silverpine coast | Zygor |
| 21 | Undead Paladin A Lesson in Divinity 94434 (10 Linen Cloth) | Bleeding Horrors beside Tomb Weed 99142, Tirisfal | Zygor |

Each needs the same check as the fangs before it goes in: QuestieDB drops or spawns for the objective, and the route section that passes the spot.

## Errors in the other add-ons (don't copy)

- **RestedXP:**
  - A Dwarf Priest Desperate Prayer step never shows (race typo).
  - Touch of Zanzil is tagged with an unknown class.
  - The Dwarf/Gnome Priest's 5626 has no turn-in.
  - The Skyborne Druid's Moonglade 94914 is picked up but never turned in.
- **Zygor:**
  - A Lesson to Learn's Alliance and Horde IDs (26/27) are swapped against the Forever captures, and so are the Skyborne Druid IDs (94911-94914). RestedXP matches ours there (Alliance 94912/94914).
  - The level-30 Warlock chain points at 1471 and 1758.
  - It lists 77573, a Season of Discovery ID.
- **Both:** they script Classic IDs that aren't in Forever's client.
