# Horde Druid and Shaman class quests (1-30)

`QuestHordeClassDruidShaman.lua` adds the Horde Druid and Shaman class chains as side guides (`B.hordeSide`), modelled on the Alliance `QuestClassData.lua` guides (`2026-11-08-class-druid-shaman.md`). No inline insertions: the only candidate (Skyborne Moonglade 94913 at Turak after Child of Nature) pushed the simulated Skyborne Druid log to 21 in Camp Taurajo and Splintertree, so it opens its own side guide instead. Facts come from `tools/questfacts.py` (QuestieDB Forever 0f7d8ad). The RestedXP Forever guides (`Horde-01-12_Durotar`, `Horde-1-12_Mulgore`, `Horde-12-22_Barrens`, `dungeon/Horde-12-22_Barrens`) and the classic `RestedXP Horde 20-30` / `Classic-0.5` guides were used for IDs, order and waypoints only. All step text is ours. Every ID is in `tools/reference/forever.json`.

Already in the route, not touched: Shaman Call of Earth (Durotar 1516-1518, Mulgore 1519-1521, Zephras 92466-92468), Skyborne Call of Fire 97243-97257 (Zephras), Skyborne Bear Form 94006/94638 (shared Valanaar steps), Tauren Heeding the Call 5926 (Mulgore, ends at Turak), The Barrens Oases 886.

## Druid

| Guide | Levels | Races | Quests | Notes |
|---|---|---|---|---|
| `druid-bear-form-tauren` Druid: Bear Form | 10-12 | Tauren | 5922 > 5930 > 5932 > 6002 | Starts at Turak, where the inline 5926 ends. Moonkin Stone at Barrens 42.0, 60.86 (RXP Forever Mulgore). Bunthen Plainswind (Moonglade 44.3, 45.9) flies druids home; a `roadTo[thunderBluff][1450]` leg points the arrow at him. |
| `druid-moonglade-skyborne-horde` Druid: Moonglade (Skyborne) | 10-12 | Skyborne | 94913 | Turak's Moonglade introduction after Child of Nature 94911. RXP Forever turns it in at Dendrite; nothing follows it there. |
| `druid-cure-poison-horde` Druid: Cure Poison | 14-16 | Tauren, Skyborne | 6126 > 6127 > 6128 > 6129 > 6130 | Dreadmist Peak pool (47.9, 15.2) is approximate: the summit's Burning Blade spawns. Kodo Horns from Lost Barrens Kodos (53.8, 43.2), gazelles north of the Crossroads (48.8, 23.8). Polestar tags the Horde chain for Tauren and Skyborne. 6131 is not in the client. |
| `druid-aquatic-form-horde` Druid: Aquatic Form | 16-18 | Tauren, Skyborne | 27 > 28 > 30 > 31 | Forever swaps 26 and 27 (see the Alliance notes): 27 is the Horde opener from Turak. QuestieDB still lists 28's prerequisite as 26 and 27's giver as Mathrengyl; the guide uses Turak and chains 28 to 27. Horde lockboxes: Barrens Sludge Fen 56.7, 8.3 (Agility, object 177794) and Silverpine west coast 29.6, 29.2 (Endurance, 177790). |
| `druid-cat-form-tauren` / `druid-cat-form-skyborne-horde` Druid: Cat Form | 20-22 | Tauren / Skyborne | 98340 > 98405 > 98342 > 98739 > 98362 (Tauren); 98340 > 98341 > 98404 > 98738 > 98362 (Skyborne) | From RXP Forever's Barrens chapter (`<< !Skyborne` / `<< Skyborne`). 98341/98404/98738 are the same Skyborne spirit quests the Alliance Skyborne guide uses. Barrow Dens entrance as in the Alliance guide (72.4, 66.0). |

## Shaman

| Guide | Levels | Races | Quests | Notes |
|---|---|---|---|---|
| `shaman-fire-totem-horde` Shaman: Fire Totem | 10-13 | Orc, Troll, Tauren | 2983 (Swart, Orc/Troll) or 2984 (Narm, Tauren) > 1524 > 1525 > 1526 > 1527 | 1522 (Searn) and 1523 (Beram) are the same opener from the city trainers; all four are exclusive. 2983/2984 are `breadcrumb`s to 1524 so a player who took another opener sees them clear once Kranal's quest is in the log; the text says to use Next. 1524 has no `chain` (four possible openers). Reagent Pouch from Burning Blade Cultists in Dustwind Cave (Durotar 52.4, 25.5); Fire Tar from Razormane south of Kranal (Barrens 55.0, 26.0). Telf's trail starts at Durotar 36.74, 57.78 (RXP). Forever's 94468 is the Dwarf ending (Bruegs Kindleborn), not Horde. |
| `shaman-water-totem-horde` Shaman: Water Totem | 20-25 | Orc, Troll, Tauren, Skyborne | 1528 (Searn, Orc/Troll) or 1529 (Xanis, Tauren/Skyborne) > 1530 > 1535 > 1536 > 1534 > 220 > 63 > 100 > 96 | 2985 (Swart) and 2986 (Narm) are the other exclusive openers. Brown skin at the pool below Brine (44.2, 76.8, from RXP), red at the Tarren Mill well (Hillsbrad 62.17, 20.82), blue at the Ruins of Stardust (Ashenvale 33.5, 67.5). The Silverpine ritual climbs the slope at 41.83, 41.16 west of the Sepulcher, then the Corrupt Minor Manifestation (38.5, 44.46, needs the Water Sapta) and the Brazier of Everfount (38.26, 44.56). Islen hands out the Sapta (repeatable 972 if lost, not routed). Skyborne: QuestieDB's race mask is the full Horde mask (includes Skyborne) and no Skyborne Water quest exists in the client list; conquestcapped's beta notes say Orc/Tauren/Troll only. Included for Skyborne, **check in game**. |
| `shaman-air-totem-horde` Shaman: Air Totem | 30 | Orc, Troll, Tauren | 1531 (Searn) or 1532 (Xanis) > Prate Cloudseer (Thousand Needles 53.54, 42.65) | Single trip, rewards the Air Totem. |

## Dropped

- **Skyborne Call of Air 96136**: in the client list, but no giver in QuestieDB or the web sources (Wowhead's page has no NPCs). Add when its giver is seen in game.
- **Skyborne Call of Fire backup 98517** (back to Zephras by skycutter, per conquestcapped): the island chain is on the main Zephras route, so a second accept would duplicate it.
- **Call of Water / Call of Fire city variants** (1522, 1523, 2985, 2986): exclusive copies of the routed openers, mentioned in the step text instead.
- **Water Sapta 972**: repeatable replacement, mentioned in the 63 accept text.

## Sources

- [conquestcapped: WoW Forever shaman totem quests](https://conquestcapped.com/guides/wow-forever/wow-forever-shaman-totem-quests/) (Horde chains unchanged in Forever; Skyborne Water/Air gaps)
- [Polestar: Cure Poison](https://polestar.guide/guides/class/druid/cure-poison), [Cat Form](https://polestar.guide/guides/class/druid/cat-form)
- [Wowhead Forever: Call of Air 96136](https://www.wowhead.com/forever/quest=96136), [Call of Water 1529](https://www.wowhead.com/forever/quest=1529/call-of-water)
- [efficient.games: Aquatic Form chain](https://efficient.games/wowf/quests/id5061) (Forever's 26/27 swap)

## Check in game

- Tauren Druid at 10: Turak offers 5922 after Heeding the Call; the Moonkin Stone spot and Lunaclaw's spirit advance 6002.
- Skyborne Druid at 10: Turak offers 94913 after Child of Nature; Dendrite takes it.
- Druid at 14: the Dreadmist Peak pool position; Skyborne get 6126 from Turak.
- Druid at 16: Turak offers 27 (not 26); Dendrite offers 28 after it; both Horde lockboxes (Sludge Fen, Silverpine coast) are where the guide says.
- Druid at 20: Tauren get 98405/98342/98739, Skyborne 98341/98404/98738; both end with 98362 at Turak.
- Shaman at 10: Swart offers 2983 and Narm 2984; the guide's 2983/2984 steps clear when the player took another opener and accepted 1524.
- Shaman at 20: a Skyborne shaman can take 1529 from Xanis. If not, remove `skyborne` from the Water guide's `start` and from 1529's race.
- Shaman at 30: Prate Cloudseer's exact spot near Freewind Post.
