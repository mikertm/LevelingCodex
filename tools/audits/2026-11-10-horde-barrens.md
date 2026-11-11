# Horde route: The Barrens, Stonetalon and Ashenvale (12-22)

`QuestHordeBarrens.lua`. The shared Horde route that every race joins after its starting zone. Quest facts come from `tools/questfacts.py` (QuestieDB Forever 0f7d8ad) and the Forever client reference; every quest ID and flight name is in `tools/reference/forever.json`. RestedXP was used only for quest grouping and order. All step text is our own.

## Sources

- RestedXP Forever `Horde-12-22_Barrens.lua`: "12-17 The Barrens" and "17-22 Stonetalon/Barrens/Ashenvale" (the backbone).
- RestedXP Forever dungeon variant `dungeon/Horde-12-22_Barrens.lua` ("16-17 Ragefire Chasm", "18-21 The Barrens", "21-22 Wailing Caverns"), to tell dungeon pickups from solo ones.
- RestedXP Forever starters (`Horde-01-12_Durotar.lua`, `Horde-1-12_Mulgore.lua`, `Horde-01-14_Undead.lua`), to see what each race carries in.
- bindonforever.com/zones/the-barrens, /stonetalon-mountains, /ashenvale: Forever additions (Vrang Wildgore and Walton in the Dry Hills, Her Name Is Olgra, Chol'aruk the Ravener as a group quest, Parts and Pieces, WANTED: Bruuz as an elite, Va'xug Firefure's two quests). No moved NPCs or new flight paths are reported for these zones.

## Sections

| ID | Title | Zone | Levels | RestedXP part |
|---|---|---|---|---|
| `crossroads` | The Crossroads | Barrens | 12-15 | 12-17 chapter up to the first Ratchet loop and the Tauren hides errand |
| `barrens-north` | Northern Barrens | Barrens | 15-16 | Regthar, Forgotten Pools, Witchwing, Dry Hills (Vrang/Walton), Samophlange, Venture Co. drill site, Boulder Lode Mine, Orgrimmar |
| `barrens-south` | Southern Barrens | Barrens | 16-18 | Crossroads turn-ins, Echeyakee, Ratchet, Stagnant Oasis, Camp Taurajo, Hezrul, Counterattack, harpy lieutenants, Seereth |
| `sun-rock` | Sun Rock and Camp Taurajo | Barrens | 18-21 | 17-22 chapter up to Serena Bloodfeather |
| `zoramgar` | Stonetalon and Ashenvale | Stonetalon | 21-22 | 17-22 chapter from the second Stonetalon trip to the end in Orgrimmar |

Trainer visits: Orgrimmar at 16 and 22, Thunder Bluff at 20 (`withTrainers`). Druids and paladins have no Orgrimmar trainer and train at the Thunder Bluff stop; warlocks have none in Thunder Bluff.

Hearth: the Crossroads (first section), Camp Taurajo (from the southern loop, used from Stonetalon), Thunder Bluff (from the level 20 visit, used from Zoram'gar).

## Arrivals

Orcs, Trolls and Undead reach the Barrens through Far Watch Post (Kargal Battlescar: Conscript of the Horde 840 -> Crossroads Conscription 842), Tauren from Camp Taurajo. The section starts with a lead-in `goto` to the Crossroads (skipped once you are in the Barrens), then the flight path and hearth. Nothing here needs a race filter on travel. Race-limited quests carry the race on the quest:

- Orc/Troll: Meats to Orgrimmar 6365 -> Ride to Orgrimmar 6384 (held until the level 16 Orgrimmar visit) -> Doras 6385 -> Return to the Crossroads 6386.
- Tauren: A Bundle of Hides 6361 -> Ride to Thunder Bluff 6362 -> Tal 6363 -> Return to Jahan 6364, flown at the end of `crossroads` (Tauren-only fly steps).

## Dungeon pickups (`forDungeon`)

| Quest | Where | Dungeon |
|---|---|---|
| Slaying the Beast 5761 | Neeru Fireblade, Orgrimmar visit at 16; optional turn-in at the level 22 Orgrimmar visit | `dungeon-ragefire-chasm` |
| Smart Drinks 1491, Trouble at the Docks 959 | Mebok and Bigglefuzz, second Ratchet visit (~19) | `dungeon-wailing-caverns` |
| Chol'aruk the Ravener 97003 | Gur'ak, Crossroads (~20). Forever group quest; RestedXP turns it in after Wailing Caverns | `dungeon-wailing-caverns` |
| Serpentbloom 962 | Apothecary Zamah, Thunder Bluff (Apothecary Zamah 853 is its breadcrumb and stays in the main route) | `dungeon-wailing-caverns` |
| Leaders of the Fang 914 | Nara Wildmane, Thunder Bluff (after the solo Hamuul Runetotem 1489 -> Nara Wildmane 1490) | `dungeon-wailing-caverns` |
| The Essence of Aku'Mai 6563 | Je'neu Sancrea, Zoram'gar | `dungeon-blackfathom-deeps` |

Solo lead-ins kept in the main route: Raptor Horns 865 and Deepmoss Spider Eggs 1069 (Mebok), Apothecary Zamah 853, Hamuul Runetotem 1489 / Nara Wildmane 1490, Trouble in the Deeps 6562. Pickups left to the dungeon checklist: Deviate Hides 1486 / Deviate Eradication 1487 (at the cave mouth), Hidden Enemies 5726 (Thrall; RestedXP takes it in the Durotar/Undead chapters), Searching for the Lost Satchel 5722 / Testing an Enemy's Strength 5723 (Rahauro, Thunder Bluff). Nothing on this route passes the Ruins of Lordaeron pickups (Undercity/Tirisfal).

## Dropped or simplified

- Class quests: Shaman Call of Fire 1524-1527 and Call of Water 1528/1530/1535/1536, Warrior 1498/1502/1503/1823, Rogue 1963/1858/2379/2382/2381/2460/2458/2478/2479, Warlock 1507-1513/1515/1511, Hunter 3921/6541/6382/6383/6544/3513/6284 timing, Druid 27/28/30/98340-98739/98362, Priest 5642/5644. Left for a class-quest pass.
- Repeated RestedXP blocks (the Vrang/Walton chain and the Regthar turn-ins appear in both chapters for players who skipped them): done once, in `barrens-north` and `barrens-south`.
- ... and that note you found 79007 (Burned-Out Remains near Camp Taurajo): its chain ends in Westfall; RestedXP picks it up and never turns it in.
- Wenikee Boltbucket 3921: RestedXP only takes it for hunters on their way to Kadrak.
- High-level pickups RestedXP leaves open for much later, dropped to keep the quest log under 20 (with dungeons planned the simulated log peaks at 18): Mahren Skyseer 874 (27), Elemental War 6393 (25), Gerenzo Wrenchwhistle 1096 (27), Troll Charm 6462 (24), Chief Engineer Scooty 2842 (35). The 22-30 route can take them when it passes those NPCs.
- Supplies for the Crossroads 5041: QuestieDB lists Disrupt the Attacks 871 as its prerequisite, but RestedXP accepts both together from Thork, so the route does too (no `chain`). Check in game.
- Ziz Fizziks 1483 is a breadcrumb of Super Reaper 6000 1093 (`breadcrumb`), Apothecary Zamah 853 of Serpentbloom 962.
- Vendor, profession, first aid and weapon-skill steps, grind-to-XP steps and hunter pet steps are left out.

## Optional and opportunistic

- WANTED: Bruuz 92706 (elite shark off the Ratchet docks): optional.
- Lakota'mani 883 (item 5099) and Owatanka 884 (item 5102): `startItem`, shown only when the rare's drop is in your bags.

## CARRY (open at the edges)

Turned in here, accepted in other files (the integrator adds these turn-ins at the marked comments):
- 842 Crossroads Conscription -> Sergra Darkthorn (non-Tauren, from Far Watch Post).
- 860 Sergra Darkthorn -> Sergra; 886 The Barrens Oases -> Tonga; 854 Journey to the Crossroads -> Thork (Tauren, Mulgore).
- 98024 Journey to the Crossroads -> Thork (from Thrall).
- 1358 Sample for Helbrim -> Apothecary Helbrim (Undead).
- 924 The Demon Seed: Altar of Fire (47.97, 19.07) and Ak'Zeloth at Far Watch Post (Orc/Troll; accepted in the Durotar file).

Left open for the 22-30 route: 3301 Mura Runetotem (Silverpine), 264 Until Death Do Us Part (Silverpine), 1065 Journey to Tarren Mill (Hillsbrad), 868 Egg Hunt (southern Barrens), 1058 Jin'Zil's Forest Magic, 6301 Cycle of Rebirth, 1068 Shredding Machines (XT:9 done, XT:4 left), 1092 Gerenzo's Orders (Stonetalon), 216 Between a Rock and a Thistlefur (Ashenvale).

## Check in game

- The bind names "The Crossroads", "Camp Taurajo", "Thunder Bluff" (GetBindLocation).
- Supplies for the Crossroads 5041 offered together with Disrupt the Attacks 871.
- The Orgrimmar west gate from the Boulder Lode Mine path (the step has no waypoint).
- The Talondeep Path entrance in Stonetalon (78.2, 42.3, from memory) used as the arrow's road hint into Ashenvale.
- Druid and paladin trainers in Thunder Bluff (Turak Runetotem, Alodan the Hopeful), the rogue trainer Boarton Shadetotem and the priest trainer Miles Welsh.
- Va'xug Firefure's spot (40.5, 61.4) relative to the Talondeep exit; bindonforever lists it under Astranaar.
- Chol'aruk the Ravener: where the target is (RestedXP turns it in after Wailing Caverns).
- Whether non-Tauren can reach Thunder Bluff before they know its flight path (the step says to ride through Mulgore).
