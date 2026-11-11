# Horde Warrior and Paladin class quests, levels 10-30

`QuestHordeClassWarriorPaladin.lua` adds 12 side guides to the Horde route: 8 for Warriors (Orc, Troll, Tauren, Undead, Windshaper Skyborne) and 4 for Undead Paladins. Nothing is inserted inline. The Undead stance quests (1818-1820) and the Paladin 1-12 chain were already inline in `QuestHordeTirisfal.lua`. The Skyborne stance quest 94003 comes over from the Alliance Zephras steps into `valanaar`.

## Evidence

- Quest IDs, givers, turn-ins, positions, prerequisites, race and class masks: `tools/questfacts.py quest|item|npc` on the cached Forever QuestieDB data. Every scripted ID is in `tools/reference/forever.json` `quests.ids`. RestedXP (`forever/Horde-01-14_Undead.lua`, `forever/Horde-01-12_Durotar.lua`, classic `RestedXP Horde 13-23 Barrens.lua` and `RestedXP Horde 20-30.lua`) was used only for order and waypoints. All step text is ours.
- Web: [questing.wiki Warrior](https://questing.wiki/wow-forever/classes/warrior/) (Path of Defense and Ulag the Cleaver teach Defensive Stance; the Horde level 20 list), [questing.wiki Paladin](https://questing.wiki/wow-forever/classes/paladin/) (the Forsaken Paladin quest list), [Bind on Forever 91858](https://bindonforever.com/quest/91858) (Paladin only, Horde, from level 18), [Bind on Forever 94441](https://bindonforever.com/quest/94441) (part 7 of A Lesson in Divinity), [Conquest Capped weapon guide](https://conquestcapped.com/guides/wow-forever/wow-forever-paladin-weapon-quest/) (the Wolfsbane chain, materials, the level 20 gate from A Moon-Kissed Blade on). Icy Veins' Warrior page returned 403.

## Warrior

| Side guide | Levels | Races | Quests |
|---|---|---|---|
| `warrior-defense-barrens` Warrior: Defensive Stance (Barrens) | 10-12 | Orc, Troll, Tauren | 1505 (Tarshaw in Razor Hill for Orc/Troll, Krang in Bloodhoof for Tauren, as race-filtered accepts), 1498 (Singed Scales on Thunder Ridge; teaches Defensive Stance) |
| `warrior-forged-steel` Warrior: Forged Steel | 10-14 | Orc, Troll, Tauren | 1502, 1503 (Stolen Iron Chest in the Razormane camp by Thun'grim; weapon choice) |
| `warrior-agamand-heirlooms` Warrior: Agamand Heirlooms | 10-13 | Undead | 1821 (four weapon racks in the Agamand family crypt, Tirisfal 52, 26), 1822 (weapon choice). Follows the inline 1820. |
| `warrior-field-of-giants` Warrior: Trial at the Field of Giants | 20-22 | all | 1823 (Sorek, Orgrimmar), 1824 (5 Twitching Antennae; they expire after 15 minutes), 1825 |
| `warrior-brutal-hauberk` Warrior: Brutal Hauberk | 25-30 | all | 1838 (15 Smoky Iron Ingots from Windshear kobolds, 10 Powdered Azurite from Hillsbrad Miners, 10 Iron Bars, Vial of Phlogiston from Roogug in Razorfen Kraul), 1848 |
| `warrior-brutal-gauntlets` Warrior: Brutal Gauntlets | 28-30 | all | 1839, 1842 (Xavian satyr hooves, Ashenvale), 1843 |
| `warrior-brutal-helm` Warrior: Brutal Helm | 28-30 | all | 1840, 1844 (Galvanized Horn from the Chimaera Matriarch, Charred Vale), 1845 |
| `warrior-brutal-legguards` Warrior: Brutal Legguards | 28-30 | all | 1841, 1846 (Sturdy Dragonmaw Shinbones, Wetlands), 1847 |
| `warrior-berserker-stance` Warrior: Berserker Stance | 30 | all five | 1718 (race-filtered accepts: Sorek for Orc/Troll/Skyborne, Torm Ragetotem for Tauren, Baltus Fowler for Undead), 1719 (Berserker Stance and Intercept) |

- 1505 is exclusive with 1818 (`exclusiveTo`), so the Barrens stance chain is limited to Orc, Troll and Tauren. The file sets `quest[1505].race` (the quest record is defined in `QuestHordeMulgore.lua` with no steps). RestedXP's Orc/Troll Tirisfal path abandons 1505 and does 1818 instead; our Durotar route stays in Kalimdor.
- Skyborne Warriors: 94003 covers the stance. Their race bit is in the 1505-1503 mask, so they may also be able to take the Forged Steel weapon chain through Uzzek. Not routed until that is checked in game.
- The Brutal quests have quest level 30 and a minimum of 20, with no race split for the three armour pieces (all have the full Horde race mask). The Dragonmaw shinbone drop has no Forever or classic drop record in the cache. The Dragonmaw Raider, Bonewarder, Swamprunner and Centurion spawns cluster at Angerfang Encampment (Wetlands 45-53, 45-54), so the waypoint is there. The guide adds Wetlands extents to the Horde route for that one step.
- Left out: The Windwatcher 1791 and the Whirlwind Weapon chain (level 30 entry but the quests run to 40, as on the Alliance side). Weapons of Choice 893 is a general Barrens quest, not a class quest.

## Paladin (Undead)

| Side guide | Levels | Quests |
|---|---|---|
| `paladin-redemption-undead` Paladin: Redemption | 12-14 | 94427 (Danitha Morr), 94434 (10 Linen Cloth to Tanis Alderwood, Undercity), 94435, 94436 (Billmuth), 94438 (Symbol of Life 6866 on Deathguard Falgan, Venomweb Vale), 94440 (Scarlet Crusade Attack Plans), 94441 (Redemption) |
| `paladin-lumina-windsinger` Paladin: Lumina Windsinger | 19-24 | 91858 (Danitha, from 18), 91859, 91860 (Charred Remains on Fenris Isle), 91861, 91862 (Fenris Isle Key from Rot Hide Gnolls), 96204 (escort), 95034 |
| `paladin-wolfsbane` Paladin: Wolfsbane | 24-30 | 95036 (lumber from the Deadmines, silver ingot from Arugal's room in Shadowfang Keep, Kor Gem through Ulric Frostveil), 95111, 95125 (Ott in Tarren Mill), 95126 (Moonsilver Blade), 95140 (Old Fire-Eye, level 25 elite, Greymane Wall; reward Wolfsbane) |

- The Forever traces give no levels for these quests. Minimums: 12 for A Lesson in Divinity (Bind on Forever), 18 for Diplomatic Incident through The Debt, and 20 from A Moon-Kissed Blade on (Conquest Capped). 94427's prerequisite is set to The Tarnished 91317, which offers it at the same NPC. The other prerequisites follow the chain order.
- Seeking the Kor Gem 95042 (Ulric Frostveil, Zoram'gar) is not in the 70862 client index, so it is described in the 95036 objective text and not scripted, like Bailor's and Thundris's errands on the Alliance side.
- The Symbol of Life use is on the 94438 turn-in step (`withItem(6866, ...)`), since that quest has no log objective.
- No Horde Sense Undead or Divine Storm cloak quest was found. The cloak chain 78088-78093 is Alliance-only (Human/Dwarf in `QuestClassData.lua`).

## Check in game

- The Tarshaw and Krang referrals at level 10, that Path of Defense teaches Defensive Stance, and whether a Skyborne Warrior is offered Veteran Uzzek.
- The Agamand weapon racks: inside the crypt or outside it, and which mobs guard them.
- The Twitching Antennae timer, and the Dragonmaw shinbone drop in the Wetlands.
- Velora Nitely's and Orm Stonehoof's exact spots (the step text names the Trade Quarter ring and Thunder Bluff's central mesa).
- A Lesson in Divinity: offered with The Tarnished turn-in or after it, and Redemption on the 94441 turn-in. Falgan's body and the use-item button.
- The Wolfsbane materials (Deadmines lumber for Horde, Ulric's errand still offered), the escort's end point, and that the Moonsilver Blade must be equipped for Old Fire-Eye.
