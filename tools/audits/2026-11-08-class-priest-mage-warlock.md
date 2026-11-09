# Alliance Priest, Mage and Warlock class quests, levels 10-30

QuestClassData.lua contains 18 side guides, the inline Stars of Elune quest and the two starter Imp quests. Human and Gnome Imp quests (1598 and 1599) share the existing vineyard and troll cave loops; see the [Forever Warlock quest index](https://questing.wiki/wow-forever/classes/warlock/).

## Evidence

- Client build 1.60.1.70862. The committed `tools/reference/forever.json` validates every added quest ID and map. The snippet supplies yard extents for seven additional maps from that reference. Client ID presence establishes that a record exists. Server offers, quest conditions and turn-ins also need quest records or live evidence. [Forever client tables](https://wago.tools/db2/QuestV2?build=1.60.1.70862)
- Reused scratch `class/pml_list.py` and `class/pml_facts.py`, plus the pinned local QuestieDB Forever records, traces, base and fixes for masks, prerequisites, endpoints and item sources. Some newer quests are in the base or fixes and absent from the compact `questfacts.py` output. Quest instructions were written for this handoff using the sources below. [QuestieDB data at 0f7d8ad](https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever)
- Blizzard's launch matrix gives Priest to Human, Dwarf, Night Elf and Gnome, Mage to Human, Gnome and Alliance High Order Skyborne, and Warlock to Human and Gnome. Warlock cache mask 4294967373 is broader than the playable Alliance Warlock roster. [Blizzard race and class matrix](https://news.blizzard.com/en-us/article/24304075/create-the-hero-you-want-to-be-in-world-of-warcraft-forever)

## Priest

| Race | Level | Quest IDs and placement |
| --- | --- | --- |
| Human | 10 / 20 | Side. Divine Grace (94773) and Arcane Feedback (5676), both at Laurena in Stormwind. |
| Dwarf | 10 / 20 | Side. Desperate Prayer (5639) and Chastise (5641), both at Rohan in Ironforge. |
| Gnome | 10 / 20 | Side. Confounding Flash (94817) and Contingency Plan (94818), both at Mims in Ironforge. |
| Night Elf | 10 / 20 | Inline Stars of Elune (5627) after Returning Home (5629). Side Elune's Grace (5674), from Astarii to Alathea in the same temple. |

- Forever uses the old 5639 and 5641 IDs for Dwarf-only unlocks at Rohan. The compact cache still sends 5639 to Laurena and labels 5641 A Lack of Fear. The newer quest records identify Desperate Prayer and Chastise. Fear Ward and Devouring Plague are baseline at 20. [Desperate Prayer](https://db.icy-veins.com/wow-forever/quests/5639) [Chastise quest and pickup](https://questing.wiki/wow-forever/quests/5641/) [Blizzard Priest changes](https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior)
- Arcane Feedback (5676) is a direct Laurena quest in the Forever record. The compact cache and one legacy location listing still show Brother Joshua as the giver. Gnome Contingency Plan (94818) is a direct quest at Mims confirmed by the Forever database and missing from the compact lookup. [Arcane Feedback source comparison](https://questing.wiki/wow-forever/quests/5676/) [Contingency Plan](https://db.icy-veins.com/wow-forever/quests/94818)
- Each racial unlock uses one route. Alternate starter referrals can share the same quest title and reward under other IDs. The direct side guide will still track its own ID if an alternate completed the unlock. Night Elf Returning Home (5629) and the earlier 5622/5621 chain already live in the route. Other Returning Home IDs are alternate entries. [Priest unlocks and alternate trainers](https://www.icy-veins.com/wow-forever/priest-class-quests)

## Mage

| Races | Level | Quest IDs and placement |
| --- | --- | --- |
| Human | 10 | Side. Mirror Lake (1860, 1861). |
| Gnome | 10 | Side. Mage-tastic Gizmonitor (1879, 1880). |
| Skyborne | 10 | Existing inline. Speak with Belann and Boughs in the Wind (93791, 93797) grant Windbough Wand. |
| Human, Gnome, Skyborne | 15 | Side. Manaweave Robe (1920, 1921, 1941). |
| Human, Gnome, Skyborne | Suggested 15-20 | Side. One book route, Rumi of Gnomeregan (79093), followed by Research Access (97286) for Study. |
| Human, Gnome, Skyborne | 26 | Side. Astral Knot Garment (1939, 1938, 1940, 1942). |
| Human, Gnome, Skyborne | Unlocks at 30 | Side. Mage's Wand (1947, 1948, 1949, 1950, 1951, 1952). Bring a group for the Library and help for higher-level enemies. |

- Use Jennea directly for Manaweave. Report to Jennea (1919) is an optional referral according to the Forever route guide. The compact cache lists it under `preQuestSingle`. The cache also carries Human/Gnome masks for the 15 and 26 chains. The current guide routes both on Skyborne and Blizzard's live Armory shows a level-23 High Order Skyborne with the quest-only Manaweave Robe. Astral Knot on Skyborne is supported by the guide and remains a live test item. [Forever Mage routes](https://www.icy-veins.com/wow-forever/mage-class-quests) [Skyborne Manaweave character](https://worldofwarcraft.blizzard.com/en-us/forever/us/armory/character/havoc-manabrew/) [Manaweave mask caveat](https://questing.wiki/wow-forever/quests/1941/)
- Study accepts any eligible book donation. The snippet uses one nearby book example, with no hard-coded prerequisite for that specific book. The breadcrumb drops from the guide once Research Access is in the log or finished. The November 6 hotfix and current quest reward identify Study as the spell. [Library book locations](https://www.warcrafttavern.com/forever/guides/library-books) [Research Access](https://www.wowhead.com/forever/quest=97286/research-access) [Blizzard hotfix](https://news.blizzard.com/en-gb/article/24315281/wow-forever-hotfixes-november-6-2026)
- The two Skyborne Mage quests now use minimum level 10 from the public Forever database. The cache's in-tower waypoint for Ur's Treatise is 73.77, 47.61 in Redridge. Icy Veins gives a looser tower location of 79, 49. [Forever Mage quest levels](https://db.icy-veins.com/wow-forever/quests/mage/) [Forever Mage route](https://www.icy-veins.com/wow-forever/mage-class-quests)

## Warlock

| Races | Level | Quest IDs and placement |
| --- | --- | --- |
| Human, Gnome | 10 | Side. Voidwalker (Human 1685 or Gnome 1715, then 1688, 1689). |
| Human, Gnome | 20 | Side. Shared Sayaad trip with Gnome referral 1717, shared 1716, then Succubus 1738/1739 and Incubus 65602/65603. |
| Human, Gnome | 20 minimum | Side. The Orb of Soran'ruk (1740), with two dungeon objectives. |
| Human, Gnome | 25 minimum | Side. Dread Mage Hat (335, 336, 397). |
| Human, Gnome | 30 | Side. Felhunter (1798, 1758, 1802, 1804, 1795). |

- The level-10 Human and Gnome referrals converge at Gakin. The level-20 forks share Devourer of Souls and the trip to Takar. The instructions cover each branch's pickup, field objective, ritual item and separate Binding. Use Next on an unwanted fork's accept step. Shared data stays in one section so a player can do both during one trip. The Succubus route uses Heartswood in Ashenvale. Hearts of the Pure is the Undercity route. [Human and Gnome pet routes](https://www.icy-veins.com/wow-forever/warlock-class-quests) [Forever Devourer of Souls](https://kovarel.com/wow-forever/quests/1716-devourer-of-souls) [Incubus quest](https://db.icy-veins.com/wow-forever/quests/65602) [Torch and figurine details](https://conquestcapped.com/guides/wow-forever/wow-forever-warlock-quests/)
- Used the Forever Stormwind-Auberdine boat for the level-20 crossing, then the Talondeep Path via Stonetalon to avoid the guarded main Barrens gate. The Felhunter route uses the neutral Booty Bay-Ratchet ship. [Forever transport routes](https://wowforeverclasses.com/articles/wow-forever-boats-zeppelins-flight-paths) [Talondeep Path](https://questcorehq.com/wowdb/forever/quest/1056/journey-to-stonetalon-peak) [Felhunter objectives and ritual](https://mobalytics.gg/wow-forever/classes/affliction-warlock-guide-progress?ws-ngf5-5=activeVariantId%2C2) [Dread Mage Hat chain](https://polestar.guide/guides/class/warlock/dread-mage-hat)
- The early Priest garment rewards are outside this pass. Playing with Fire (96020) is in the client and opens at 29, but is a level-35 quest with an unverified pickup and ritual route. It stays out of this handoff. Wish You Were Here (65610) sends the player to Orgrimmar. The Bloodrobe chain opens at 31. [Playing with Fire](https://db.icy-veins.com/wow-forever/quests/96020) [Warlock quest index](https://questing.wiki/wow-forever/classes/warlock/)

## In-game checks after integration

- At levels 10 and 20, confirm Laurena, Rohan, Mims and Alathea give the expected spell rewards. Check that Night Elf Stars of Elune follows the existing 5629 turn-in and that an already-finished alternate Priest referral can be handled from the quest UI.
- On a Skyborne Mage, verify the level-10 offer threshold and both Stormwind robe chains, especially Andromath at 26. Confirm the Blue Recluse coffer capture and Study after a first book donation or an earlier donation.
- On a Human and a Gnome Warlock, verify the two level-10 referrals, Gakin's three bindings in the Stormwind crypt, Takar's two offers and the torch interaction. Confirm a chain resumes the main route on its last turn-in.
