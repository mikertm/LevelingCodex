# 2026-11-10: Horde 1-30 audit (loops, zig-zags, reference coverage, alternates)

The pass ran four checks over the Horde route: a loop check, a map check, a RestedXP coverage diff, and an alternate-route review.

## 1. Loop check (`tools/questloops.py`, new)

`python tools/questloops.py HORDE ORC,TAUREN,SCOURGE,SKYBORNE WARRIOR,SHAMAN,...` walks each race and class through the main route. It groups consecutive steps at one spot into visits and reports two things:
- **Hub visits:** a visit made only of pickups and turn-ins that could all have been done at an earlier visit within 45 yards. That means turn-ins already ready, pickups' prerequisites turned in, and the character at the quest's minimum level by the section's level range. Only visits that cost extra walking are reported.
- **Zig-zags:** an objective area the route leaves and comes back to, within 150 yards, when the quest was already in the log on the first pass and the return costs more than 300 yards.

The first version (scratchpad) flagged 107 spots. Most were pickups gated by level or prerequisites, or towns the route revisits anyway, so the tool now weighs whole visits and their walking cost.

**Fixed:**

| Where | Problem | Fix |
|---|---|---|
| **Undead route** (deathknell, tirisfal, silverpine) | **46 objective steps were on the Elwynn Forest map (1429).** `B.objective(id, x, y)` places steps on the Alliance default map, so the arrow would have said "Travel to Elwynn Forest". | Each block uses `objectiveOn(map)`. The coordinates were already Tirisfal and Silverpine ones. A new route-audit warning catches this. |
| Crossroads arrival | Devrak, the inn, Sergra, Tonga, Thork, Helbrim, Gazrog, Zargh, Devrak, Jahan, Devrak: three laps of town. | One loop: Devrak (flight path), Helbrim, Thork, Sergra, Tonga, then Gazrog, the inn, Zargh, Jahan and back to Devrak. Every race's arrival turn-ins are on the way. |
| Crossroads, back from Ratchet | Landing by Thork, walking out to the zhevra, then back to Thork. | Thork's two turn-ins come right after landing. |
| Northern Durotar | Misha's farm, then north to Rezlak and the ravine, then back south-west to Fizzle Darkstorm, then north to Orgrimmar. | Fizzle comes right after Misha, about 400 yards less. |
| Valley of Trials | The peons are woken next to Thazz'ril, but the turn-in waited for a trip north and back. | Turn in Lazy Peons and take Thazz'ril's Pick right after the peons. Warlocks take Ruzan's imp quest on arrival; he stands next to Kaltunk. |
| Deathknell | Sarvis and Elreth's next quests were taken on a second chapel visit after the class letters. | Taken with the zombie turn-in. |
| Thunder Bluff (Mulgore) | Preparation for Ceremony was taken on the second Thunder Bluff visit, though Eyahn stands at the lift on the first. | Taken on the first visit. |
| Thunder Bluff (Barrens trip) | Shamans trained by Zamah, climbed to Clarice, then came back down to Zamah. | Zamah first, then Clarice. The Priest pickups from Miles Welsh follow Zamah. |
| Freewind Post | Inn, Longhorn, Rau, Jandia (south side), then back north to Hagar and Elu. | One pass from north to south: Nyse, Elu, Hagar, Longhorn, the poster, the inn, Rau, Jandia. |

**Reviewed and left as they are** (the tool still lists them):
- Dark Storms (Orgnil) is taken at level 10 rather than on the first Razor Hill visit, so a level 12 quest doesn't sit in the log for hours.
- Sun Rock's Maggran and Tsunaman quests (levels 25-26) aren't taken at level 21, when they would be red.
- The Chill of Death (minimum level 7) isn't taken on the first Brill visit.
- Burning Blade Medallion is gated by Vile Familiars. The tool can't see that prerequisite, because it is either of two quests.

Walking per race, main route: Orc 138.3k yards, Tauren 136.8k, Undead 143.3k, Skyborne 108.9k. The Undead number is higher than before only because their objective steps are now on their real map. The town fixes save a few hundred yards each; the Fizzle reorder saves about 400.

## 2. Map check (`tools/questroute.py`, new warning)

On a leveling route, a step on another map between two steps on the same map, with no travel step around it, now gives the warning "hops to map X and back". It would have flagged the Elwynn steps above. Side guides (class and dungeon) go out and back by design, so they are skipped. Both factions' leveling routes are clean.

## 3. RestedXP coverage

The script parsed every Horde-applicable quest ID in RestedXP's Forever Horde chapters (Durotar, Undead, Mulgore, Barrens and its dungeon variant, and the 22-30 and Zephras chapters inside the Skyborne file). It compared them with every Horde section: route, dungeons and class guides. Most chapters have 0 to 5 quests we don't route; the 28-30 Thousand Needles chapter has 23, mostly its level 31+ tail. Each was checked. The reasons:

- **Not in the Forever client:** 813, 926, 972.
- **Level 31+, or the start of a 31+ chain:** the Thousand Needles chapter's tail (Shimmering Flats 1111-1112 and 1175, Alliance Relations, the Swarm Grows, Rig Wars, Wet Job, Eagle's Fist), and ...and that note you found 79007 with its later Stepping Stones / Scramble (79192, 79980). That chain starts with a note in Westfall and continues into Desolace at 33+.
- **Alliance or Undead-only, or on the other faction's island path:** 92481, 93949, 93791 and 93797 (High Order and Mage).
- **Optional professions:** the Camping 101 crafting intros, and Gathering Leather 768.
- **Skipped on purpose:**
  - Exploring the Horde 93739: RestedXP comments it out too, because it can't be finished before 22-23, when it gives no XP.
  - A Grand Adventure 92708 and Unwelcome Spirits 93736: switched off in RestedXP.
  - Wayward Weapons 97279: RestedXP's note says it isn't worth it.
  - Need for a Cure 812: needs the missing 813.
- **Not routed, to keep the log at 20:**
  - Mahren Skyseer and Isha Awak (874, 873; Ratchet coast, level 27).
  - Report to Kadrak 6541 and The Runed Scroll 3513 (north Barrens tower, off the route).
  - The Lost Pages 6504 (level 30).
  - Dangerous! 567 (a level 28 bounty on several named Hillsbrad NPCs).
- **Alternative IDs for the same pickup:** Heeding the Call 5928, Hex/Touch of Weakness 5652 and 5660, Devouring Plague 5679 (Forever renamed it Dark Sacrifice 5644, which is routed).
- 103 and 104 appear in RestedXP's Barrens chapter, but they are Westfall quests.

## 4. Alternate routes

Before this pass the Horde had one alternate, Shimmering Flats at 29-31. Dungeon runs are already handled by dungeon plans: RestedXP's dungeon chapters become planned-run pickups and checklists.

**New: Tirisfal and Silverpine (`silverpine-early`, levels 12-15, Orcs, Trolls, Tauren, Skyborne).** This is RestedXP's Forever route for Kalimdor races who go to Silverpine at 12 before the Barrens:
1. The zeppelin to Tirisfal, then Brill: Delivery to Silverpine, The Argent Emissary, Rear Guard Patrol, and Hadric's The Cult of the Damned and Remnants of War.
2. The Undercity flight path.
3. The whole Silverpine loop (Erland's escort, the Yoricks, the Sepulcher chains, the Dead Fields, the Decrepit Ferry, Arugal's Folly, Border Crossings).
4. The Undercity turn-ins and the Engraved Ring in Brill.
5. The zeppelin back to Durotar and the road to the Crossroads.

The steps are copied from the Undead `silverpine` and `tirisfal` sections, without Supplying the Sepulcher (Undead only) or the Rogue chain. Prerequisites and `also` lists are trimmed to the quests the alternate has.
- The sections `northern-durotar`, `mulgore` and `valanaar` suggest it alongside the Crossroads.
- Its Sample for Helbrim gets an optional turn-in at the Crossroads.
- `questroute.py` now lets an optional turn-in for a quest the path never picked up pass, the same rule as on main.

Not added:
- **A Kalimdor-first path for the Undead.** RestedXP has none in Forever, and Silverpine is on their way.
- **Classic RestedXP's 20-30 "JJ" order.** It visits the same zones in a different order and has no Forever quests.

## Things to check in game

- The Undead objective arrows in Deathknell, Tirisfal and Silverpine now point on the right map.
- Crossroads arrival as one loop. Freewind as one pass.
- Silverpine alternate:
  - the Orgrimmar zeppelin tower in Durotar (50.8, 13.8);
  - that an Orc, Troll, Tauren or Skyborne can take Delivery to Silverpine, The Argent Emissary and Rear Guard Patrol in Brill;
  - the Engraved Ring turn-in for non-Undead.
