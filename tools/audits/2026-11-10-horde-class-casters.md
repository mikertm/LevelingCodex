# 2026-11-10: Horde Priest, Mage and Warlock class quests (1-30)

`QuestHordeClassCasters.lua`. Inline insertions into the Horde route plus seven side guides. Model: the Alliance
casters in `QuestClassData.lua` (`2026-11-08-class-priest-mage-warlock.md`). Facts come from `tools/questfacts.py`
(QuestieDB Forever 0f7d8ad), and every quest ID is in `tools/reference/forever.json`. RestedXP gave the order
only, from its Forever `Horde-01-12_Durotar.lua`, `Horde-01-14_Undead.lua` and `Horde-12-22_Barrens.lua` and
the classic `RestedXP Horde 1-13 Troll-Orc.lua` and `RestedXP Horde 20-30.lua`. All step text is ours. Every
section is `verified = false`.

Races (Forever): Priest is Troll and Undead. Mage and Warlock are Orc, Troll and Undead (Orc Mage and Troll
Warlock are new in Forever).

## Priest (inline, no side guides)

| Quest | Race | Where it goes |
|---|---|---|
| Hex of Weakness 5654 | Troll | Accept from Tai'jin in `durotar`, right after For Honor's turn-in (before the level-10 Razor Hill training). Turn in to Ur'kyo in `northern-durotar`, after Hidden Enemies is accepted on the first Orgrimmar visit. |
| Touch of Weakness 5658 | Undead | Accept from Aelthalyste and turn it in to her, in `tirisfal` on the level-12 Undercity visit (after Whispering Horror Residue at Father Lankester). |
| Shadowguard 5642 | Troll | Accept from Miles Welsh on the level-20 Thunder Bluff visit (`sun-rock`, after Clarice Foster). Turn in to Ur'kyo when you fly into Orgrimmar at 22 (`zoramgar`). |
| Dark Sacrifice 5644 | Undead | Same Miles Welsh pickup. Turn in to Aelthalyste on the level-24 Undercity visit (`hillsbrad`, after Raleigh). |

- **Two sources disagree on IDs.** QuestieDB has Tai'jin giving 5655 and Var'jun giving 5654. The Forever quest
  record on questing.wiki and every RestedXP guide have Tai'jin giving 5654, so we use 5654. For the Undead the
  quest record makes 5658 a direct quest from Aelthalyste. QuestieDB says Father Lankester, who stands next to
  her. The step text covers both.
- **Forever renamed 5644** from Devouring Plague to Dark Sacrifice. It now teaches the new Undead spell, and
  Devouring Plague and Fear Ward are baseline at 20 (Blizzard's Priest deep dive). Shadowguard, Hex of Weakness and
  Touch of Weakness are unchanged.
- The racial quests are exclusive groups, five IDs at 10 and three at 20. A player who takes a different
  trainer's copy can hand it in at the same NPC, and our step for the other ID ends up under Missed quests.
- No other Horde Priest quests exist below 30 in the QuestieDB data or on questing.wiki's Forever Priest list.
  Garments of Spirituality and Garments of Darkness were already in the route.

## Mage

| Section / insertion | Quests | Levels | Races |
|---|---|---|---|
| `mage-ju-ju-heaps` "Mage: Ju-Ju Heaps" (side) | 1883 Speak with Un'thuwa (Uthel'nay, Orgrimmar) -> 1884 Ju-Ju Heaps (Echo Isles, Un'Thuwa in Sen'jin) | 10-12 | Orc, Troll |
| Inline `tirisfal` | Loot The Apothecary's Metaphysical Primer in Carolai's shop in Brill (a goto step after That Shadowvale Green Elixir), then on the level-12 Undercity visit 79095 at Owen Thadd -> Research Access 97286 (Study) | 6-12 | Undead |
| `mage-study-horde` "Mage: Study" (side) | The Lessons of Ta'zo 79094 (painted rock, Valley of Spirits) -> Owen Thadd -> Research Access 97286 | 10-24 | Orc, Troll |
| `mage-spellfire-robes` "Mage: Spellfire Robes" (side) | 1959 Report to Anastasia (Orc/Troll breadcrumb from Uthel'nay) -> 1960 Investigate the Alchemist Shop -> 1961 Gathering Materials (Dalaran Mana Gems in Silverpine) -> 1962 Spellfire Robes | 15-17 | all three |
| `mage-nether-lace` "Mage: Nether-lace Garment" (side) | 1943 Speak with Deino (Anastasia, Undercity) -> 1944 Waters of Xavian -> 1945 Laughing Sisters -> 1946 Nether-lace Garment (Kil'hala, Crossroads) | 26-28 | all three |
| `mage-wand-horde` "Mage: Mage's Wand" (side) | 1947 Journey to the Marsh (Deino's copy) -> 1948, 1949, 1950, 1951 -> 1952 | 30 | all three |

- The Undead 10 chain (Speak with Anastasia 1881, The Balnir Farmstead 1882) was already inline in Tirisfal.
  1883 and 1881 are exclusive.
- **Orc Mage race masks.** QuestieDB masks 1883/1884, 1959-1962 and 1943-1946 as Troll and Undead (144). That
  is the classic mask. Forever added Orc Mages, so the guides include Orcs. **Check in game** that an Orc Mage
  is offered Speak with Un'thuwa and Report to Anastasia.
- Report to Anastasia (1959) is a breadcrumb for 1960, as Report to Jennea is on the Alliance side. QuestieDB
  lists it as 1960's prerequisite. Undead go straight to Anastasia.
- Study: Owen Thadd in the Undercity's Magic Quarter takes the library books for the Horde. The book locations
  come from Warcraft Tavern's library list, and Owen's position from QuestieDB (npc 211022). The book is looted
  from a shelf or rock, and QuestieDB has no giver for the book quests. So a goto step marks the book, and the
  quest is accepted and turned in at Owen. That matches RestedXP, which turns the Primer in without an accept.
- Waters of Xavian: the waterfall at Ashenvale 76, 41 comes from warcraft.wiki.gg (one source). Laughing Sisters
  spawn around Ashenvale 59, 56 (QuestieDB). Rift Spawns for 1960 are at Undercity 53.0, 74.7 (QuestieDB spawns).
  Dalaran Apprentices for the gems are at Silverpine 52.6, 65.1.
- The Mage's Wand text follows the Alliance chain. The Horde start is Deino. Tabetha, Tirth, Arathi and the
  Scarlet Monastery Library are shared.

## Warlock

| Section / insertion | Quests | Levels | Races |
|---|---|---|---|
| Inline `northern-durotar` | 1506 Gan'rul's Summons (Ophek, Razor Hill, after Dark Storms) -> 1501 Creature of the Void (accepted after Hidden Enemies; Tablet of Verga in the right-hand passage of Skull Rock, after the Lieutenant's Insignia) -> 1504 The Binding (Cleft of Shadow, after Ak'Zeloth is accepted from Neeru) | 10-12 | Orc, Troll |
| `warlock-sayaad-horde` "Warlock: Succubus and Incubus" (side) | 1507 -> 1508 -> 1509 -> 1510 (Ken'zigla, Malaka'jin) -> 1511 -> 1515 -> 1512 -> 1513 (Succubus); 65601 Love Hurts -> 65610 Wish You Were Here (Withered Scarf, Fallen Sky Lake) -> 65604 The Binding (Incubus) | 20-27 | all three |
| `warlock-orb-horde` "Warlock: The Orb of Soran'ruk" (side, `links` to `dungeon-blackfathom-deeps` and `dungeon-shadowfang-keep`) | 1740 | 20-28 | all three |
| `warlock-felhunter-horde` "Warlock: Felhunter" (side) | 2996 Seeking Strahad (Gan'rul) -> 1801 -> 1803 (Moldy Tome in Hillsbrad, Tattered Manuscript in Splithoof Hold) -> 1805 (Rods of Channeling, Wetlands) -> 1795 | 30 | all three |

- Undead Voidwalker (1478, 1473, 1471) was already inline in Tirisfal. QuestieDB limits 1473 and 1471 to the
  Undead, so Orcs and Trolls take the Orgrimmar chain. The order comes from the classic RestedXP Troll-Orc guide,
  which fits our Kalimdor route: Ophek at the level-10 Razor Hill stop, Gan'rul on the first Orgrimmar visit,
  the tablet during Skull Rock, the binding on the second Orgrimmar visit. The Forever RestedXP guide sends Orc
  and Troll warlocks to Tirisfal for 1478 instead. We keep the Kalimdor route.
- **Dropped:** the Undercity Succubus and Incubus (Devourer of Souls 1472 -> Hearts of the Pure 1476 -> The
  Binding 1474, and Hearts of the Lovers 65593 -> The Binding 65597). They are exclusive with Gan'rul's 1507.
  Their hearts come from Silverpine and the Wetlands, while the Gan'rul chain runs through the Barrens, where
  every Horde race is at 20. Also dropped: Seeking Strahad 3001 (Carendin Halgar's exclusive copy; the step text
  mentions it), the Bloodrobe chain (31+) and the Orb of Orahil (35+).
- Wish You Were Here 65610 is quest level 27 (QuestieDB), so the Incubus part is done later. The audit warns about
  this; it is expected.
- The Withered Scarf drop area and the binding spot in the Cleft of Shadow (49.43, 50.0) come from RestedXP's
  classic 20-30 waypoints.
- Felhunter: the Moldy Tome is in Alliance territory (Hillsbrad murloc huts, 27.8, 72.8). The rods come from
  Dragonmaw in the Wetlands, reached from Hammerfall over Thandol Span. The Wetlands extents were added to the
  Horde route.

## Sources

- QuestieDB Forever data (via `tools/questfacts.py`); the Forever client reference for IDs.
- https://questing.wiki/wow-forever/classes/priest/, /mage/, /warlock/ and the quest pages for 5642, 5644,
  5652, 5654, 5658, 5679, 5680 (quest record vs Everything Quests pickups).
- https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior
- https://www.warcrafttavern.com/forever/guides/library-books
- https://warcraft.wiki.gg/wiki/Waters_of_Xavian
- https://bindonforever.com/quest/1883, https://www.wowhead.com/forever/quest=1884/ju-ju-heaps
- RestedXP guides supplied by the owner (order and IDs only).

## Check in game

- Troll Priest: does Tai'jin offer Hex of Weakness at 10, and which ID? (Our step tracks 5654.)
- Undead Priest: does Aelthalyste offer Touch of Weakness 5658 herself, and does Dark Cleric Beryl offer a copy at 10?
- Miles Welsh offers Shadowguard and Dark Sacrifice at 20, and Dark Sacrifice teaches the new spell.
- Orc Mage: are Speak with Un'thuwa, Report to Anastasia and Speak with Deino offered? (The classic masks exclude Orcs.)
- The Primer shelf in Brill and the Ta'zo rock in the Valley of Spirits. Does looting either book start a quest,
  or does Owen Thadd offer it? Research Access teaches Study.
- The alchemy shop for the Rift Spawns (Undercity 53, 75) and the Dalaran Apprentice camp at Silverpine 52, 65.
- Orc/Troll Warlock: the Burning Blade Stash at the end of Skull Rock's right-hand passage, and the Glyphs of
  Summoning working in the Cleft of Shadow.
- Grunt Dogran's spot (43, 48) and whether guards stand around him. The Withered Scarf drop from the Shadethicket at Fallen Sky Lake.
