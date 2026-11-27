# Stranglethorn 35-38 audit, both factions (2026-11-27)

The owner saw the Alliance step window at Baron Revilgaz with the next pickup 44 yd away and the one after
2884 yd away, and asked for the Booty Bay hubs to be walked in one pass. Checked `stv-36` (Alliance) and
`stv-35` (Horde) against Zygor's Forever chapters (Alliance Stranglethorn 34-35 and 37-38, Horde 36-37;
comparison only) and the quest database (every giver and finisher spot, every hunting spot against the
creature's spawn clusters).

Givers and finishers: all match the database (within a yard). Quest chains and level gates: no change.

## Alliance (stv-36)
- First Booty Bay visit. Before: Gyll's flight path (the platform above the inn), back down to Lozgil on
  the docks, Ruzzgot, the inn, Drizzlik next door, back up to Revilgaz. After: Lozgil and Ruzzgot on the
  docks, Crank, the bind, the bar, Krazek and Kebok, Revilgaz, Drizzlik, Gyll, fly (Zygor's order).
- Hearth return. Before: Crank, Kebok, Krazek, Drizzlik, Revilgaz, Aransas, Lozgil. After: Crank, Krazek,
  Kebok, Revilgaz, Drizzlik, Aransas, Lozgil (by the tunnel north).
- Second loop. Before: Mistvale, Lake Nazferiti, Lashtails, Sin'Dall, the Haunted Isle, Nesingwary. After:
  Mistvale, Lake Nazferiti, Lashtails, the Haunted Isle, Sin'Dall, Nesingwary (the shortest order; about
  190 yd less, more with the Lashtail fix). Section walk 15698 -> 15402 yd.
- Spots (database clusters): Lashtail Raptors 31.4, 22.3 -> 34.5, 24.0 (they live north of Grom'gol;
  the text said the west coast); Panthers 29.8, 11.2 -> 28.8, 14.1; Elder Stranglethorn Tigers 31.9, 19.9
  -> 33.5, 18.4; Stranglethorn Raptors 27.2, 16.1 -> 25.8, 16.1 (also in the `stv-30` alternate);
  Shadowmaw Panthers 36.1, 37.3 -> 37.6, 36.4; Water Elementals 21.1, 22.8 -> 21.2, 23.3.
- Singing Blue Shards text: Crystal Spine Basilisks (the ones east of the compound), not Stone Maw.
- Kept: the Rebel Camp visit at the end of the second loop for Troll Witchery (205) and Colonel Kurzen
  (202). Taking them at the first loop's Rebel Camp visits puts 21 quests in the log at the hearth (the
  route audit fails), so the 340 yd detour stays.
- Kept: Rebel Camp, compound, Rebel Camp, compound order of the first loop: Special Forces needs both
  Rebel Camp quests turned in, and the current order is the shortest of the ones tried (3870 yd against
  3960-4190).

## Horde (stv-35)
- First Booty Bay visit (on foot from Grom'gol). Before: Gringer's flight path, Scooty, down to Lozgil,
  up to Revilgaz, down to Crank, Kebok, Krazek, Drizzlik. After: Lozgil by the tunnel, Crank, Kebok and
  Krazek, Revilgaz, Drizzlik, Scooty, Gringer's flight path, fly.
- Second visit (flying in to Gringer): Revilgaz first (below the flight master), then Kebok and Krazek,
  Crank, Drizzlik, Aransas, hearth. Section walk 17403 -> 17224 yd.
- Hunting spots all match the database.

## Danger warnings
`tools/questdanger.py` now leaves out flight masters (`npcFlags` 8): the Alliance step at Revilgaz warned
"Watch out here: Elite Gringer (55)", the Horde flight master next door. 59 flight masters dropped.
