# Horde 30-60: integration (2026-11-12)

The Horde 30-60 route was written in seven parts at once, each in its own file and audit:
`2026-11-12-horde-30-40.md`, `-horde-40-50.md`, `-horde-50-60.md`, `-horde-riverglades.md`,
`-horde-dungeons-30-45.md`, `-horde-dungeons-45-60.md` and `-horde-class-30-60.md`. This file records what
changed when they were put together, and two fixes to the Alliance 30-60 data found on the way.

## Base

- Branch `claude/horde-30-60` = main + the Alliance 30-60 branch (`claude/alliance-quest-guide-30-60-0238d1`,
  never merged before) + the Horde 30-60 scaffold (`QuestHorde3040.lua`'s shared setup and the `B.horde` helpers).
- Merge conflicts were wording in the audits and docs (main's kept) and both sides adding scenarios, quest
  facts zones and step fields (both kept).
- `Quests.lua` `localSection`: zone entry only jumps one level ahead into a zone's later chapter. With
  Darkshire 30 in the route, a level 28 entering Duskwood was pulled past the Wetlands chapter
  (scenario `questTravelFlight`).

## Fixes between the band files

| Where | Problem | Change |
|---|---|---|
| `swamp-41` | Hand-ins for Stinky's Escape (1270) and The Black Shield (1276), already handed in by `dustwallow-37` | Removed from `swamp-41` |
| `desolace-41` | The Corrupter (1484) accepted again (done in `desolace-34`) | `desolace-41` starts at Takata with The Corrupter (1488) |
| `blasted-50` | Rescue OOX-22/FE (2767) handed in again (done in `stv-44`) | Removed from `blasted-50` |
| 40-50 file | A race limit on Larion and Muigin (4145) listing every Horde race hid it from the audit's generic character, so Marvon's Workshop (4147) looked early in three places | Limit removed (the route is Horde-only anyway) |
| `scholomance-key-horde` | Scarlet Diversions (5096) needs any one of the three race-town calls to arms (5093-5095); the 50-60 file registered it with 5095 only, the guide takes 5094 | The guide registers 5096 with 5094 |
| `tanaris-46`, `hinterlands-48` | With every dungeon planned, the log reached 21 (Scarlet Monastery, Razorfen Downs and Uldaman pickups still held) | Clean-up notes: drop 1048 and 3341 at 46, 2202 at 48 |

## Links

At the end of `QuestHordeRiverglades.lua` (loaded after every band file):

- 30-40 to 40-50: `badlands-39` and `badlands-37` suggest `stv-40` (and `dustwallow-40`).
- 40-50 to 50-60: `feralas-49` suggests `blasted-50`, `searing-alt`, `ungoro-alt`, `azshara-alt`; the late-40s
  alternates suggest `blasted-50`.
- The Riverglades: `stv-35`, `dustwallow-37`, `arathi-38`, `badlands-39` offer `riverglades-rogmar`; `stv-40` and
  `swamp-41` offer `riverglades-bolderok`; `swamp-41` and `tanaris-41` offer `riverglades-eastsea`;
  `desolace-41`, `tanaris-41` and `feralas-43` offer `shendralas-pylons`. They hand back to `stv-40`, `swamp-41`,
  `tanaris-41`, `feralas-43`, `stv-44` and `swamp-45`.
- `feralas-43` hands in On the Other Side (95033, Tan'jani's breadcrumb from Rog'mar) at Witch Doctor Uzer'i,
  shown only while you carry it.
- `QuestHorde22to30.lua`: `thousand-needles` and `shimmering-flats` offer `stv-30` and `desolace-31`;
  `shimmering-flats` also leads to `hillsbrad-30`.

The harness now checks that every level 30-60 has a leveling guide for each faction and warns below three
(`quest_choice_checks` in `tests/run.py`). Both factions have three or more at every level.

## Class objectives on the route

From the class audit's list, 18 objectives are copied from the class guides onto the route as `logOnly` steps
(only that class, only while the quest is in the log), after the closest step on the same map: Cyclonian's
Bloodscalp tusks (`stv-35`); the four Twisted Totems (`desolace-34`, `dustwallow-37`, `badlands-39`,
`swamp-41`); the Infernal Orb for mages and warlocks (`desolace-34`); the Felhas Ruby (`desolace-41`); Warrior
Kinship and War on the Shadowsworn (`blasted-50`); the Azshara errands for hunters, priests, mages and rogues
(`azshara-52`); the Ichor of Undeath (`plaguelands-56`). Hand-ins stay in the class guides.

## Alliance fixes

- **Eastern Plaguelands frame.** Forever redrew the map: QuestieDB Forever has Tirion Fordring at 5.2, 35.6
  where classic has 7.6, 43.7 (a fit over four NPCs: x' = 0.899x - 1.58, y' = 0.898y - 3.65). The Alliance
  50-60 file had classic points for Tirion (three steps) and the Symbol of Lost Honor (now 62.5, 26.8, the
  item's Forever spawn), and the Stratholme guide had Tirion and the gate (now 26.5, 10.4, converted). Every
  other Alliance Eastern Plaguelands point already matched Forever. A check of 30 NPCs across the 30-60 zones
  found no other map that differs (Stormwind Keep's Lady Katrana moved too, 1-30 data).
- **Krol'dok Stronghold**: the Alliance guide gets the client's instance (3039) and encounter IDs, and the
  game's names Handler Ashka and Overseer Mugg.

## Not done

- Dungeon pickups left to the dungeon guides (not tagged on the route, to keep the log at 20): most of the
  Blackrock Depths, Stratholme and Sunken Temple outdoor pickups. Each guide lists them in its prepare phase.
- Blackrock Mountain, Maraudon and the Sunken Temple have no `path` into the instance: QuestieDB has no
  positions inside the mountain or the caves.
- Mount Hyjal: no Horde quest could be confirmed.
- Undead paladins: no 30-60 class quest could be confirmed.

## Check in game

Each part's audit has its own list. Across the whole route: the hand-offs between bands (Kargath to Grom'gol at
40, Booty Bay at 50), the clean-up notes at 46 and 48, and the class objective steps showing for the right
class only.
