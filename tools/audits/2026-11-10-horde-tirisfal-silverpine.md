# Horde route: Tirisfal Glades and Silverpine Forest (Undead 1-15)

`QuestHordeTirisfal.lua`: three Undead-only sections (`start = "SCOURGE"`, `route.starts.SCOURGE = "deathknell"`), then the zeppelin to Durotar and the walk to Far Watch Post in the Barrens. All facts (IDs, NPCs, positions, levels, prerequisites) come from QuestieDB Forever 0f7d8ad via `tools/questfacts.py` and the client reference; every quest ID is in `tools/reference/forever.json`. RestedXP Forever (`forever/Horde-01-14_Undead.lua`, chapters "1-6 Tirisfal Glades", "6-12 Tirisfal Glades", "12-14 Silverpine Forest") gave the order and grouping; the dungeon variant (`forever/dungeon/Horde-01-14_Undead.lua`) only includes those chapters. All step text is our own.

Web sources: bindonforever.com/zones/tirisfal-glades, bindonforever.com/zones/silverpine-forest (Forever-only quests, the Undead Paladin chain, Camping 101).

## Sections

| Section | Levels | Steps (after trainer expansion) | RestedXP chapter |
|---|---|---|---|
| `deathknell` | 1-6 | 74 | 1-6 Tirisfal Glades |
| `tirisfal` | 6-12 | 220 | 6-12 Tirisfal Glades |
| `silverpine` | 12-15 | 89 | 12-14 Silverpine Forest |

Trainers: Deathknell (Dannal Stern, Aramis Hammerhand, David Trias, Dark Cleric Duesten, Isabella, Maximillion) at 2, 4, 6; Brill (Austil de Mon, Shari Stilwell, Marion Call, Dark Cleric Beryl, Cain Firesong, Rupert Boch) at 6, 8, 10, 12 and 14 (the last on the way to the zeppelin). Undead classes in Forever per RestedXP filters: Warrior, Paladin, Rogue, Priest, Mage, Warlock.

Travel: hearth bound in Brill on arrival, moved to the Undercity at the end of `tirisfal`; flight paths The Sepulcher (Karos Razok) and Undercity (Michael Garrett, learned with Michael Garrett 6322). Zeppelin: the tower between Brill and the Undercity, Tirisfal 60.96, 58.63 (converted from RestedXP's world coordinates; RXP's last `-1` waypoint at 60.9, 46.4 is the zeppelin's path, not the tower). `route.roadTo` gains Tirisfal/Undercity -> tower and Silverpine -> Sepulcher flight master legs for Durotar, the Barrens and Orgrimmar (only where no other file set one).

## Forever quests included

Deathknell: A Difficult Path 98601 -> Rediscovering the Light 90902 -> Coming to Terms 91208 / Continue Your Training 91209 (Paladin), A Light in the Darkness 98389 (everyone, Aramis Hammerhand), The Adventurer 96656. Brill: Sticks and Bones 86784, The Great Outdoors 96607, Camping 101: Cooking 96658 (plus optional Herbalism 97957 -> Faruza, Mining 97959 -> Brom Killian in the Undercity, Skinning 97960 -> Rand Rhobart), Discipline 99134 (Executor's Motivator 286176), Patience 99141 (three reports as objective parts: Dillinger, Kristof, Gordo), Hides for the Forsaken 97558, Seeking Refuge 99144, That Shadowvale Green Elixir 95314, Tomb Weed 99142, The Argent Emissary 96895 -> The Cult of the Damned 96897 / Remnants of War 96898 -> Bandarion Keep 96899 -> A Righteous Cause 96896 -> Leonid's Letter 98545 (Glix Xizzix, Undercity), As Above, So Below 99152, The One That Got Away 99153, Whispering Horror Residue 95328 (item 268812 from an elite, `startItem`). Silverpine: Wild Eyes 91920, Return to Quinn (Again) 91921. Undercity: Prompt Potion Runner 97891.

Chains on Forever quests are not in QuestieDB; they follow the order the givers offer them in RestedXP (for example 96899 after 96897 and 96898, 91282 after 91209).

## Class quests

Inline (short, on the route): Warlock Piercing the Veil 1470 and Halgar's Summons 1478 -> Creature of the Void 1473 -> The Binding 1471 (Voidwalker); Priest In Favor of Darkness 5651 -> Garments of Darkness 5650; Warrior Speak with Dillinger 1818 -> Ulag the Cleaver 1819 -> Speak with Coleman 1820; Mage Speak with Anastasia 1881 -> The Balnir Farmstead 1882; Rogue Mennet Carkad 1885 -> The Deathstalkers 1886/1898/1899/1978 (Astor Hadren on the Silverpine road; the rest in the Undercity before the zeppelin); Paladin A Second Home 91282 -> Murlocs at the Gates 91285 -> Touring the Grounds 91294 -> Making Repairs 91316 / The Tarnished 91317 -> A Token of Good Faith 95803 (Sylvanas). The starting letters 3095-3099 and 98601 carry `class`.

A Warlock/Mage/Rogue-only Undercity stop at level 10 (class-filtered goto steps) matches RestedXP; RestedXP uses the sewer exit to Solliden Farmstead, we use the front elevator.

Left for a later class-quest pass: the Paladin A Lesson in Divinity chain 94427 -> 94434 -> 94435 -> 94436 -> 94438 -> 94440 -> 94441 (Danitha Morr, Tanis Alderwood in the Undercity, Deathguard Billmuth, Deathguard Falgan at Tirisfal 86.7, 47.7; RestedXP labels its end "RessComplete", so it likely teaches Redemption), Priest Touch of Weakness 5658/5663, the Warrior Agamand Heirlooms 1821/1822 follow-ups, and Diplomatic Incident 91858 (Paladin, 22+).

## Dropped or changed against RestedXP

- Vendor, water and weapon purchase steps, grind-to-XP steps, profession training, Mining/First Aid/Blacksmithing training.
- The Prodigal Lich 405 is accepted by everyone (RestedXP: Mage/Warlock only) and turned in on the Undercity visit at the end of `tirisfal`, which everyone makes.
- Seeking Refuge 99144 is turned in to Shari Stilwell by everyone. RestedXP turns it in only on its Paladin steps, though everyone accepts and completes it.
- The Engraved Ring 440: RestedXP accepts it and never turns it in; Magistrate Sevren is on the way to the zeppelin tower, so we turn it in there.
- Wild Hearts 429: QuestieDB lists Lost Deathstalkers 428 as its prerequisite, but RestedXP takes it from Rane Yorick right after the Erland escort. No `chain` on 429.
- Return to Podrig 6324 is skipped (would need another trip to the Sepulcher).
- Marla's Last Wish 6395 needs Samuel Fipps (36.7, 61.7) killed first; RestedXP has it as a `.collect` step.

## Dungeon pickups

- Ruins of Lordaeron (`dungeon-ruins-of-lordaeron`): Rear Guard Patrol 99156 (Riptear, level 13 elite, Tirisfal 84.1, 43.8), RestedXP tags it `.dungeon [ROL]`.
- Ragefire Chasm (`dungeon-ragefire-chasm`): The Power to Destroy... 5725 from Varimathras on the last Undercity visit (turn-in left to the dungeon guide).
- Not added: A Frightened Request 92401 (Tabitha Heartweaver, the Sepulcher, quest level 22, RestedXP only at 15+) investigates the Ruins of Lordaeron; it belongs in the dungeon guide's prepare phase. Hidden Enemies 5726 (Thrall) is in Orgrimmar, off this route.

## Carried into other files

- CARRY turnin 1358 Sample for Helbrim: Apothecary Helbrim, the Crossroads.
- CARRY turnin 842 Crossroads Conscription: Sergra Darkthorn, the Crossroads (840 accepted at Razor Hill and turned in at Far Watch Post in this file).
- CARRY turnin 5725 The Power to Destroy...: Varimathras, after Ragefire Chasm.

## Check in game

- `GetBindLocation()` at Innkeeper Renee: the route assumes "Gallows' End Tavern" (the inn's own area in AreaTable, like Thunderbrew Distillery). If it says "Brill", change `town.brillBind`. The Undercity inn is assumed to report "Undercity".
- Whether non-Paladins can turn in Seeking Refuge 99144 to Shari Stilwell, and whether A Light in the Darkness 98389 is offered to every class.
- The zeppelin tower position (60.96, 58.63) and the Ulag the Cleaver crypt (59.16, 48.51).
- The audit warns that the level 12 Forever quests (Argent Emissary chain, Bandarion Keep, Shadowvale) are more than 5 levels above the section start (6); RestedXP does them at 10-12.
