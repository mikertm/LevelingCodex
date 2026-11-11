# Horde Hunter and Rogue class quests, levels 10-30

`QuestHordeClassHunterRogue.lua` adds the Orc and Troll taming chain and the Orc and Troll Shattered Hand chain to the Horde route as inline steps, and seven Rogue side guides for levels 16-30.

## Sources

- RestedXP Forever `Horde-01-12_Durotar.lua` ("6-10 Durotar" and "10-12 Durotar") and `Horde-12-22_Barrens.lua` ("12-17 The Barrens", "17-22 Stonetalon/Barrens/Ashenvale"). These gave the order and the class stops only. The text is ours.
- QuestieDB Forever, through `tools/questfacts.py`, for givers, turn-ins, races, prerequisites, item drops and spawn clusters.
- Web:
  - [questing.wiki Forever Hunter quests](https://questing.wiki/wow-forever/classes/hunter/). No Horde-only Forever Hunter quest is listed below 35. The new taming routes are Human (Elwynn) and Skyborne (Valanaar).
  - [zockify: Horde poison quest](https://www.zockify.com/forever/rogue/poison-quest/). It gives the order, the level-20 start, the Silixiz-first warning and the lockbox needing 80. Poisons come from the second Hinott's Assistance.
  - [zockify: Lockpicking](https://www.zockify.com/forever/rogue/lockpicking/). It covers the Tide Razor practice boxes, the Gizmotronic Apparatus, the E.C.A.C. on Polly and a beta bug in the apparatus, fixed in 1.60.1.70291.
  - The Forever-wide Rogue jobs reuse the Alliance guide's sources: zockify Shadowfang Keep and Scarlet Monastery, wowhead Forever, senseos.gg and azeroth.wiki.
  - icy-veins' Forever Rogue class quest page returned 403.

Who can be what: Orc and Troll can be Hunters and Rogues. Tauren can be Hunters, Undead can be Rogues, and Windshaper Skyborne can be both.

## Hunter

| Where | Races | Quests |
|---|---|---|
| Inline, `northern-durotar` after Encroachment 837 (Razor Hill, after the first Orgrimmar visit) | Orc, Troll | 6062 Dire Mottled Boar -> 6083 Surf Crawler -> 6082 Armored Scorpid -> 6081 Training the Beast |
| Inline, `northern-durotar` after Halikor's Hoof 96877 (second Orgrimmar visit, Valley of Honor) | Orc, Troll | 6081 turn-in at Ormak Grimshot |

- **Placement.** RestedXP tames at the end of its 6-10 chapter. We start at the Razor Hill stop after the first Orgrimmar visit, because every quest in the chain needs level 10. By then everyone has it.
- **Tame areas** come from the QuestieDB spawn clusters closest to Razor Hill:
  - boars at 54.5, 45.9, just east of town;
  - Surf Crawlers at 59.8, 25.4, the small north-east coast group, which matches RestedXP's loop;
  - Armored Scorpids at 54.7, 34.1.
- **Already in the route:**
  - Tauren: 6061/6087/6088/6089, in `QuestHordeMulgore.lua`.
  - Skyborne: 94978/94979/94013/94050, in `valanaar`.
  - The starting letters 3087/3082/3092 and The Way of the Hunter 92482.
- **Not added:**
  - The Hunter's Path referrals 6065-6070. Jen'shan (Valley of Trials), Sian'dur (Orgrimmar) and Thotar's referral to Mulgore are optional pointers to a trainer the route already visits, and they exclude each other. The Alliance guides leave them out too.
  - Wenikee Boltbucket 3921 and Report to Kadrak 6541 are not class quests: QuestieDB has no class filter on them. RestedXP only times them differently for Hunters.
  - Horns of Frenzy 2754 needs level 32.

## Rogue

| Section | Type | Levels | Races | Quests |
|---|---|---|---|---|
| `northern-durotar` after Conscript of the Horde 840 | inline | 10 | Orc | 1859 Therzok (Kaplak) |
| `northern-durotar` after the Orgrimmar flight path | inline | 10 | Orc / Orc, Troll | 1859 turn-in, 1963 The Shattered Hand (Therzok) |
| `crossroads` after Southsea Freebooters 887 | inline | 13 | Orc, Troll | 1963 Tazan's Satchel (Tazan at the first Southsea camp) |
| `barrens-north` after Slaying the Beast 5761 (Orgrimmar visit) | inline | 15-16 | Orc, Troll | 1963 turn-in, 1858 The Shattered Hand (Pick Lock the satchel, or pick pocket Gamon in the inn) |
| `rogue-lockpicking-horde` "Rogue: Lockpicking" | side | 16-20 | all | 2379 Zando'zan -> 2382 Wrenix of Ratchet -> 2381 Plundering the Plunderers |
| `rogue-poisons-horde` "Rogue: Poisons" | side | 20-26 | all | 2460 -> 2458 -> 2478 -> 2479 -> 2480 |
| `rogue-tools-of-the-trade` "Rogue: Tools of the Trade" | side | 16-22 | Undead | 1998 Fenwick Thatros -> 1999 Tools of the Trade |
| `rogue-horn-of-xelthos-horde` "Rogue: The Horn of Xelthos" | side | 20-26 | all | 78261 -> 78307 |
| `rogue-ravenholdt-horde` "Rogue: Ravenholdt Invitation" | side | 24-30 | all | 6681 |
| `rogue-syndicate-sabotage-horde` "Rogue: Syndicate Sabotage" | side | 24-30 | all | 96779 |
| `rogue-eye-of-bhossca-horde` "Rogue: The Eye of Bhossca" | side | 30 | all | 78676 -> 78699 |

- **The Shattered Hand prerequisites.** QuestieDB has 1963 needing Therzok 1859, but 1859 is Orc-only (race mask 2). RestedXP's Forever guide has Orc and Troll rogues accept 1963 straight from Therzok. So 1963 has no prerequisite here, and 1859 is a breadcrumb for Orcs, picked up from Kaplak at the start of `northern-durotar`.
- **Tazan.** He is a lone level 13 pirate. QuestieDB puts him at 63.1, 44.3. We use RestedXP's 64.3, 44.1, where he walks up the hill from the first camp. His step sits beside the route's Southsea Freebooters kills.
- **Tazan's Logbook (1858).** Either Pick Lock opens the satchel, or the Tazan's Key pickpocketed from Gamon in the Valley of Strength inn (54.0, 68.0) does. Both come from RestedXP. The step points at Gamon because that works before level 16.
- **Lockpicking.** RestedXP takes Zando'zan 2379 straight from Shenthul. QuestieDB lists To Orgrimmar! 2380 (Kaplak) and Find the Shattered Hand 2378 (Mennet Carkad) before it. The route passes neither giver at 16, so they aren't tracked; Shenthul's step tells players to hand one in if they carry it. 2379 has no prerequisite here.
  - The practice boxes are the Buccaneer's Strongboxes on the Tide Razor at 65.06, 45.45. The Jewel of the Southsea is at 64.95, 45.44.
  - RestedXP aims for skill 70 before the Jewel.
- **Poisons.** The chain is from zockify:
  - Salute Shenthul, then fire two flares within sight of the tower.
  - Salute Fizzule before anything else.
  - Pick pocket Silixiz first, because the lockbox's Touch of Zanzil blocks Stealth.
  - Kill two each of drones, patrollers and lookouts, then Gallywix (level 23 elite).
  - Open the lockbox, which needs Lockpicking 80. Mission gives Thistle Tea.
  - Hinott's cure teaches Poisons. Positions are from QuestieDB.
- **Tools of the Trade (Undead).** These are Mennet Carkad's level 16 jobs: Fenwick Thatros at Silverpine 59.6, 33.9, and the Ambermill Strongbox at 63.71, 65.24 for the Dalaran Status Report. RestedXP's Forever guides don't route them. Their rewards are not confirmed for Forever.
- **Forever-wide jobs.** The Horn, Ravenholdt, Syndicate Sabotage and the Eye use the same quest IDs and the same flow as the Alliance guides in `QuestClassData.lua` (see `2026-11-08-class-hunter-rogue.md`). The text is rewritten for the Horde, and the payment letters arrive in a Horde capital.
- **Left out:**
  - The Deathstalkers 1885-1978 (Undead, level 10) are already inline in `QuestHordeTirisfal.lua` and the Undercity stop.
  - The starting letters 3083/3088/3096 and At Home in the Shadows 92483 are in their starting routes.
  - Syndicate Emblems 6701 is level 60 and not in the client.
  - Horns of Nez'ra 2358 is Alliance (Redridge).
  - Deathstalkers in Shadowfang is a general quest, not a Rogue one.

## Checks

- `tools/questroute.py audit` passes. In these sections there is one new warning: rogue-poisons-horde step 12 (Hinott's Assistance 2479, quest level 26, above the guide's early target). Crossroads step 55 (Miner's Fortune) was already there.
- `tests/run.py` PASSED.

## Things to check in game

1. Orc and Troll Hunters at Razor Hill:
   - Thotar is inside the bunker.
   - The three tame spots have the beasts: boars east of town, Surf Crawlers on the north-east coast at 59.8, 25.4, scorpids north of town.
   - Ormak takes Training the Beast in the Valley of Honor.
2. Troll Rogue:
   - Therzok offers The Shattered Hand 1963 without Therzok 1859.
   - On an Orc, Kaplak offers 1859 at level 10.
   - Tazan's patrol near the first Southsea camp.
   - Gamon is in the Valley of Strength inn and his key opens the satchel.
3. Shenthul offers Zando'zan 2379 without a referral.
   - The Gizmotronic Apparatus gives the E.C.A.C. and Thieves' Tools.
   - The Tide Razor strongboxes skill up to about 70.
   - The skill The Jewel of the Southsea needs.
4. Poisons:
   - Both salutes and the two-flare signal.
   - The Lockpicking skill Gallywix's lockbox needs (80 reported).
   - Poisons are taught at the second Hinott's Assistance.
5. Undead Rogue: Mennet offers Fenwick Thatros at 16, Fenwick's position, and the Ambermill Strongbox lock.
6. Horde Rogues get C's letters and Ravenholdt's Elegant Letter in the mail, and the payment letters arrive in a Horde capital.
