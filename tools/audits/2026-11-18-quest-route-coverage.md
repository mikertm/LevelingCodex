# Alliance and Horde quest-route audit

Baseline: `ff73536` (fetched main, including `c49dd98`). The chapter table records each guide by its advertised entry level. An overlapping chapter is listed once, with its full level range, and its exit is checked again when the next band reaches that handoff.

## Sources

- **Client**: committed Forever quest IDs, map sizes and taxi nodes in [forever.json](../reference/forever.json). These establish client presence and geometry. They do not establish every server-side offer condition.
- **QDB**: [QuestieDB Forever base and player traces at 4f628e8](https://github.com/Questie/QuestieDB/tree/4f628e8328ed8923ffba169c8b432996e0a7a326). Inventory includes client-present quests by zone and pickup spawn. An empty class, faction or prerequisite field on a Forever trace leaves eligibility open.
- **RXP / Z**: supplied Nov 10 RestedXP `Guides/forever` and Zygor `Guides-Forever` files. Compared IDs, ordering and clustering. Codex directions use original wording.
- **Classic**: [Wowhead Classic zone order and inherited routes](https://www.wowhead.com/classic/guide/classic-wow-leveling) and Classic quest/creature records for individual findings.

Existing chapter reports remain evidence for prior work. In particular, the [Alliance Stranglethorn audit](2026-11-17-alliance-stranglethorn-vale.md) covers the Rebel Camp, Stockpile, Booty Bay and level-50 return in depth. The [Alliance travel audit](2026-11-17-alliance-travel-handoffs.md) and [Horde travel audit](2026-11-17-horde-travel-handoffs.md) document mock reproductions of the auto-resume problems. The [Alliance](2026-11-14-alliance-1-60-audit.md) and [Horde](2026-11-14-horde-1-60-audit.md) coverage summaries and their linked band reports record earlier route, class and dungeon work.

## Checkpoints

| Entry levels | Routes reviewed in this pass | Verification |
| --- | --- | --- |
| 1–12 | All racial starts, level-10 class follow-ups, and entry to Westfall, Loch Modan, Darkshore, Silverpine and the Crossroads. | Route audit passed, 12,770 steps at checkpoint. 21 focused scenarios passed. Five focused scenarios and the 12,806-step route audit passed again after the Valley of Trials pickup-order correction. |
| 13–29 | First shared chapters through the Wetlands, Hillsbrad and Thousand Needles, with their alternate and side routes. Rechecked the exits of the chapters that started at 11–12. | Route audit passed, 12,773 steps. 21 focused scenarios passed, including the new Harlo regression. |
| 30–39 | Duskwood return, Theramore/Flats, Desolace, both north Stranglethorn circuits, Arathi/Alterac, Badlands and the 36+ Riverglades entries. | Route audit passed, 12,777 steps. 13 focused scenarios passed, including Theramore arrival, elite skipping, Stockpile and independent zone catch-up. |
| 40–49 | Central and southern Stranglethorn, Marsh, Tanaris, both Feralas and Hinterlands routes, first Un'Goro visit, Riverglades entrances/exits, Shen'dralas and the nearby side guides. The final continuity scan revisited Uldaman. | Route audit passed, 12,781 steps at checkpoint. 14 focused guide, dungeon preparation, elite and resume scenarios passed. |
| 50–60 | Booty Bay return, Searing Gorge, Burning Steppes, Un'Goro, Felwood, Azshara, Winterspring, the Plaguelands, Silithus and late side guides. | Route audit passed, 12,806 steps after the final carry scan. 21 focused scenarios passed, including MacKinley's handoff and a conflicting ready turn-in at a flight stop. |

The baseline and final route audits each report 336 advisory warnings. Updated NPC and objective coordinates changed the measured distance on three existing warnings in the Krol'dok and Hinterlands chapters. The final revision passed 36 focused scenarios covering starter and class routes, transport, reload, alternates, elite skips and dungeon prep.

The full harness passed 496 scenario runs and 41 loot unit tests. The repository TOCs are byte-identical and retain `@project-version@`. The installer verified all 86 files in the Forever AddOns folder as `v0.27.0-28-gff73536-dirty`.

## Levels 1–12

The inventory compared 106 Elwynn, 101 Dun Morogh, 94 Teldrassil, 106 Durotar, 82 Mulgore and 107 Tirisfal entries through quest level 15, including quest pickups with spawns in each zone. Zephras produced 129 Alliance and 134 Horde candidates. Counts can overlap across zone boundaries. Profession lessons, seasonal quests, mutually exclusive trainer referrals and open-world group quests account for many omissions.

- **Valley of Trials.** Gornek's class letters and Galgar's Cactus Apple Surprise (4402) now follow Cutting Teeth (788), using the existing return to the Den. QDB and both supplied guides agree on the pickup order. Take optional Wayward Weapons (97279) before the boar hunt and collect stragglers beside the cactuses on the later pass. The weapon quest awards reputation. Its record lists no prerequisite. Confirm that Gornek offers it during the initial visit. [Wayward Weapons record](https://www.wowhead.com/forever/quest=97279/wayward-weapons)
- **Durotar.** Gar'Thok offers From The Wreckage.... (825) after Vanquish the Betrayers (784) in the current record and both Forever references. Finish the keep and return to Razor Hill first. Swim to the wreck on the way south, take the Bloodtalon Matriarch's eggs (97223) as the route passes her nest, and clear the Echo Isles before looping through the Razormane camps. The Razor Hill return hands in 825, eggs (815) and pears (96825). Northern Durotar still finishes the other half of Encroachment (837). Both halves have distinct camps. [Forever Durotar route and quest list](https://forevermastery.com/en/guides/leveling/durotar)
- **Teldrassil to Darkshore.** After Teldrassil (940), Night Elves now have the option to take Fandral's message (952) on the last visit to Darnassus. The Auberdine-to-Stormwind card already links to Darkshore. Onu takes the message when the alternate reaches the Grove. A character joining Darkshore without it can pick up the Grove's other work as usual. Entering Westfall with the message shows a quest-log cleanup note. Carrying it through 41 alongside all dungeon pickups otherwise exceeds 20 slots in the offline walk. [Forever Teldrassil route](https://games.gg/world-of-warcraft/guides/wow-forever-teldrassil-leveling/) · [Inherited 952 pickup and delivery](https://www.wowhead.com/classic/quest=952/grove-of-the-ancients)
- **Main-route omissions.** The collector's order (123) drops from gnolls on the last Elwynn loop. Its follow-up Manhunt (147) would send the route east across Elwynn after the Westfall exit. The route keeps the separate Warlock farmhouse objective with the eastern bandanas. The Dun Morogh ale swap (310/311) requires a separate Brewnall return. Check whether the guarded barrel interaction still works in Forever before routing that loop. Shimmer Stout (413) is already accepted from Rejold and handed off toward Loch Modan. In Durotar the timed Need for a Cure (812) still has an auxiliary 813 record without a corresponding ID in the committed client snapshot. The northern naga (99051) open after the first coast trip and require returning to Razor Hill after the second, or a later return from the Barrens. The elite follow-up (99052) and Mulgore's elite Clearcutter (98427) remain group content. Tirisfal's 357/366/409/411 adds successive legs between the Undercity and Gunther's island after the final city visit. Z routes those legs through extra city visits. Return to Podrig (6324) likewise requires a bat ride back to Sepulcher before Brill and the Durotar zeppelin. [Durotar Forever spawns and route](https://bindonforever.com/zones/durotar) · [Inherited starter-zone ordering](https://www.wowhead.com/classic/guide/classic-wow-leveling)
- **Source discrepancies.** RXP accepts 3903 after 18, whereas QDB lists 33. The Codex completes both before the pickup. Both references place Hex of Weakness (5654) on the Durotar-to-Orgrimmar circuit. QDB assigns 5654 to Var'jun and 5655 to Tai'jin. QDB lists Father Lankester for the start of 5658 and Laurena for the finish of 5639. The supplied Forever routes put their hand-ins at Aelthalyste and Rohan respectively. Confirm the exact offers before changing those trainer steps. The Horde Skyborne departure works through Ayessa's 93738, Alaana's 95350 and Thrall's 98024. The catalog also lists 92708, 92871, 93836 and 95349 at Ayessa, but the reference routing and records leave their offer conditions unclear. Confirm which appear after 93738 and whether 95349 appears on the same departure.
- **Travel.** The Human route gets the Stormwind flight point and returns via the Goldshire bind. Dun Morogh ends through Ironforge and its flight point, with Loch Modan offered before committing to the tram. Night Elf flight training includes an Auberdine–Rut'theran return for 6343 before the outbound choice. The two Skyborne departures go to different continents and the Horde route continues via Thunder Bluff and Thrall. Verify that the two starter hearth trips can be made at the recommended points and that an independent guide switch lands on the local hub. RXP and the Codex use the Oracle Tree Bark for 940 after 98398. QDB lists Sentinel Arynia and 937 instead. Confirm the object offer after the revised Forever harpy chain.

## Levels 13–29

- **Wetlands and Darkshore.** Flagongut takes fossil 942 at Menethil. Darkshore's ship step now completes on the Wetlands map so the fossil row can remain current after landing. In the 26–30 Wetlands chapter Harlo's 472 moves to the first north-gate stop beside 484. Longbraid remains beside Rhag (631). The level-29 Skyborne report also reproduced after moving the route data, so the engine now recovers this marked pickup within interaction distance, in the current chapter, after ordinary catch-up defers it. The regression reserves completion history for the raptor quests and checks that a manual Skip still applies. The observed level-24 offer for 299 takes precedence over QDB's level-25 record. [Nearby pickup findings](2026-11-16-alliance-nearby-pickups.md) · [Earlier boat handoff](2026-11-16-wetlands-boat-handoff.md)
- **Silverpine and Hillsbrad.** Added 479 to Allister after 482, including the case where the earlier Silverpine alternate completed 482. Players joining without 482 still take Watching the Roads (95981). The route finishes the Beren's Peril cave before moving north through Ambermill. The Watchers and Wizards for 95981 and the Protectors, Mages and Conjurors for 479 are neighboring groups with separate credit. Allister takes both on the scheduled post-Hillsbrad stop. Moving 501 to the Elixir of Suffering return keeps the initial Tarren Mill pickup within 20 quests and still gets the quest before the westbound lion hunt. 480 would require a second journey to Ambermill after 479. Confirm 479 after 482 and check whether 95981 also gates 480. [Forever Silverpine route and quest series](https://questing.wiki/wow-forever/leveling/silverpine/) · [Forever Watchers and Wizards route](https://bindonforever.com/zones/silverpine-forest)
- **Westfall, Redridge and Duskwood.** Kept the split gnoll camps for 246 and the earlier Feldon pickup for 98407. The 143/144/145/146 messenger series would add a Westfall return followed by a new Lakeshire stop. The 178 pendant goes to the Tower of Azora, outside the late Redridge circuit. Westfall's 92911 still requires four crafted Copper Modulators and a Crude Scope. The lighthouse's 152 and Captain Sander's treasure scatter along the far coast and stay off the Sentinel Hill itinerary. The Duskwood Flanks, Morbent and Thandol bridge routes remain under their earlier audits. [Polestar Alliance routes](https://polestar.guide/guides/alliance) · [Westfall and Redridge pass](2026-11-12-alliance-westfall-redridge.md) · [Duskwood and Wetlands pass](2026-11-12-alliance-duskwood-wetlands.md)
- **Barrens, Stonetalon and Ashenvale.** Kept the camp split for 872 and 5041, after confirming that RXP picks up 5041 together with 871 despite the base QDB prerequisite. Both Silverpine routes keep the 91921 prerequisite for 425, established by the Forever correction. The 3921–3924 follow-ups would require crossing back to Sludge Fen and later fighting the elite Venture Co. operators in the northern Barrens. Troll Charm (6462) has its cave objective and Zoram'gar turn-in if carried. Making it a normal pickup on the earlier Zoram'gar visit would occupy a slot through Camp Taurajo's full dungeon-plan path. The 6541/6542/6543 chain's scattered contacts require a fresh return to Kadrak after the Ashenvale run. [Barrens Forever route](https://bindonforever.com/zones/the-barrens) · [Horde 12–22 pass](2026-11-12-horde-12-22.md) · [Horde 22–30 pass](2026-11-12-horde-22-30.md)
- **Class, special and dungeon handoffs.** The class checks retain the separate Aquatic Form IDs used by the two factions, despite QDB's inverted base 26/27 and 28/29 giver assignments. The carried Elune and water-totem objectives appear when that class has the quest. Ruins of Lordaeron retains 447→450→451→95216, with Tabitha picked up during the Sepulcher preparation. The Alliance Gnomeregan escort 2904 and Razorfen Kraul escort 1144 now have their recorded minimums of 24 and 23. The two Cozy Sleeping Bag guides retain opposite faction starts and the shared dam and Thoradin's Wall legs. [Forever dungeon quest guide](https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location) · [Cozy Sleeping Bag route](https://www.warcrafttavern.com/forever/guides/cozy-sleeping-bag/) · [Class pairings](2026-11-11-class-pairings.md)
- **Silverpine entry discrepancy.** Both supplied guides put Wild Hearts (429) on the Yorick farm visit before the Sepulcher. QDB lists Lost Deathstalkers (428) from Hadrec as a prerequisite, which would require going south past the farm and backtracking. Keep the farm-first route and check whether Rane offers 429 without 428 after Escorting Erland, and separately when the escort was skipped.

## Levels 30–39

- **Stranglethorn.** The Alliance chapters retain the separate exploration and combat visits, plus the Stockpile and Booty Bay groupings from the 11-17 pass. Applied the verified Stockpile findings to Horde's Wendel step. The Compound Cage Key comes from the lower-level Elites or Subchiefs. The uniform comes from the supply crate. The Horde route now says how to get Cozzle's key before opening his footlocker, and uses the current spawn records for Wendel, Aransas, Zimmix, Gemmil and the weeds. The 36+ Horde Riverglades start keeps its carried 95141 and 95143 turn-ins. Players going to Rog'mar can ask Commander Aggro'gosh or Tor'gan on the way. Their minimum offer levels are still unpublished in QDB. The alternate runs from Kargath/Stonard or Powderfuse Port for a character arriving without either. [Alliance Stranglethorn pass](2026-11-17-alliance-stranglethorn-vale.md) · [Horde Riverglades pass](2026-11-12-horde-riverglades.md) · [Forever STV inventory](https://forever-xp.com/quests/zone/stranglethorn-vale/)
- **Arathi.** Added Wanted! Marez Cowl (684). The same board starts Otto and Falconcrest (685). Clear the eastern Syndicate ruins for Marez before leaving for the last binding stone and the cove, then hand both in to Captain Nials. Both use the existing elite choice. The all-pickups path reaches the log limit with 684. 682 also fits the camp but would add a slot through Faldir's Cove when taking both elite hunts. 696 opens only after the last scheduled Stromgarde visit and would send the player back for three chests. [684 board and target](https://questing.wiki/wow-forever/quests/684/) · [682 sources and turn-in](https://questing.wiki/wow-forever/quests/682/) · [Earlier capacity and route comparison](2026-11-16-alliance-nearby-30-45.md)
- **Travel.** The three Alliance Menethil–Theramore crossings now pass at arrival. The mock previously switched the Shimmering Flats route to the optional marsh route at the dock even with the data gate. Travel arrival now preserves the current guide when it passes a boat row via its destination gate. Independent zone entry still uses catch-up. The Horde Silverpine, Hillsbrad and Arathi departures for Tirisfal likewise pass on the landing map or inside the Undercity. [Alliance mock reproductions](2026-11-17-alliance-travel-handoffs.md) · [Horde mock reproductions](2026-11-17-horde-travel-handoffs.md)
- **Other loops and side routes.** The 30 Duskwood return uses Morbent Fel's level-20 minimum, consistent with the shared record. The key city hand-ins remain outside the dungeon run. For Shrewd Negotiations (97287), QDB and the objective text name Modera, but several current endpoint records list Celindra at 14.2, 60.0. Keep the current direction and confirm whose turn-in is lit in game. The Desolace Gelkis/Magram alternatives remain reputation circuits. Faldir's Cove salvage and goggles stay in one dive, and the last sample travels to Booty Bay. The Horde guide leaves the last Stranglethorn crocolisk chain out because of the order of Drizzlik's 575 hand-in and the route's next lake visit. [ForeverTavern Horde route ordering](https://forevertavern.net/guides/leveling/horde) · [97287 endpoint discrepancy](https://wofwforever.com/en/guides/wow-forever-city-of-dalaran-dungeon/) · [Alliance 30–40 pass](2026-11-14-alliance-30-40.md) · [Horde 30–40 pass](2026-11-14-horde-30-40.md)

## Levels 40–49

- **Hinterlands.** An optional totem order (86616) now starts at Maret Firetend when the Alliance returns from the Witherbark cages. The existing second sweep reaches the Vilebranch area after the coast. Look for the totems north of the Altar of Zul and hand them in on the last Aerie Peak stop. Check whether all 12 can be picked up in that pass. The Horde chapter retains Revantusk's grouping with Lard's basket, Rin'ji and Cortello's treasure, and a separate Jintha'alor group visit. The last Wildhammer message would add another round trip from Revantusk to an Alliance town. [86616 quest and totem position](https://www.forever-xp.com/quests/86616/) · [Forever Hinterlands trip order](https://games.gg/world-of-warcraft/guides/wow-forever-hinterlands-leveling/)
- **Stranglethorn and shipments.** Horde now looks below deck for Cortello's item starter (4056) if carrying the captain quest, rather than hunting pirates for it. Gorlash is a sea giant on the mainland shore, consistent with the Alliance level-50 correction. The 49–50 entries now finish the Ratchet boat on the Stranglethorn map. Alliance's deliveries stay in the 49 chapter when the boat docks. Horde's final crossing continues into the MacKinley handoff. Check the arrow and current step before using Next. In the Badlands, Sigrun gives and takes 718 in the same camp as Ryedol. [Cortello's inherited scroll record](https://www.wowhead.com/classic/quest=624/cortellos-riddle) · [Horde travel audit](2026-11-17-horde-travel-handoffs.md)
- **Riverglades and Krol'dok.** Current records specify five Twilight Pages for 94879. The Alliance checklist uses the current quest levels, coordinates and endpoints for 94980/94981 and 94997/94998. 94926 now ends at Demar Brant, with the Maul's drop location still a live check. Keep the four Thick Leather and twelve Iron Bars on the preparation list if completing the key. The Horde moulding item is 267137 and starts 94973. Alliance uses 267138 and 94980. Preserve both upon switching guides. Both Shen'dralas guides run the temple/pylon chain. QDB now lists other chains at Nerlokh, Orgrul, Hagiak and Mithera. Their relationship to the competing Desolace reputation paths and the temple route needs a separate eligibility check. [Riverglades and Krol'dok Horde source pass](2026-11-12-horde-riverglades.md) · [Forever dungeon checklist sources](https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location)
- **Travel, route splits and log constraints.** The Theramore–Menethil return and the Horde Hinterlands Tirisfal inbound now skip on arrival. The classic escort and tablet chains remain in the dungeon guides. Feralas keeps the island and mainland sweeps with the Feathermoon ferry, or Camp Mojache for Horde. The Faerie Dragon pet chain (3841 onward) starts after returning to Tyrande, so it means another Feralas trip plus the Flats and Aerie Peak. Safety First (1189) sends players from Gadgetzan back to the Flats after the last scheduled raceway visit. The Sunken Temple chain waits for its Feralas screecher, Rhapsody and Zul'Farrak prerequisites. [Polestar Horde Feralas and Tanaris](https://polestar.guide/guides/horde/40-50/02-feralas) · [Alliance 40–50 pass](2026-11-14-alliance-40-50.md) · [Horde 40–50 pass](2026-11-14-horde-40-50.md)
- **Uldaman follow-up.** The final continuity scan found one accepted quest with neither a turn-in nor cleanup anywhere in either faction's route. After giving Talvash the necklace (2198), Alliance now brings five Silver Bars and turns in Lore for a Price (2199) at the same NPC. 2200 requires another Uldaman run and remains an explicit decision at that point. [Inherited Lore for a Price record](https://www.wowhead.com/classic/quest=2199/lore-for-a-price)

## Levels 50–60

- **Booty Bay and Stonard.** Level-50 boat cards now pass on arrival and direct entry in Booty Bay. The new Horde scenario takes the boat with 2874 ready and checks the turn-in through a subsequent quest-log event. Horde also uses Mok'rash for the Monogrammed Sash (8552), checks for the ten cooked Buzzard Wings and five Junglevine Wine for Negolash, and opens the Half-Buried Bottle on the mainland for 594 before swimming to Poobah. This carries through the corresponding Alliance Stranglethorn corrections. The Bulwark zeppelin skips from either the landing map or the Undercity. [Alliance southern-shore pass](2026-11-17-alliance-stranglethorn-vale.md) · [Horde travel reproduction](2026-11-17-horde-travel-handoffs.md)
- **Flight arrivals.** A flight taken using the guide's marked destination now keeps the current route on landing. The regression reproduces Sven's delivery remaining active in flight but being replaced by Red Leather Bandanas on landing at Sentinel Hill. It now holds the delivery through arrival. Independently taking a different flight or entering a new zone still uses ordinary catch-up. Check this at Stonard with Cortello and the Blasted Lands turn-in both active. [Alliance travel reproduction](2026-11-17-alliance-travel-handoffs.md) · [Horde travel reproduction](2026-11-17-horde-travel-handoffs.md)
- **Winterspring.** Both factions now finish 969 at Mau'ari and speak to her again for 975. Horde collects the shards on the existing hot-spring trip. The Alliance Winterspring alternate carries the same follow-up. QDB's Forever objective text says four shards, while an early published Forever walkthrough says ten. Use the live objective count. Both main routes add Evie's optional 92859 near Everlook, with the chimaera and owl hunt west of town and Darkwhisper road directions. Repeatable 98462 stays with Evie for players who need extra potions. Some contemporary sources have players reaching Hyjal before 60. The approach is documented here, and neither faction has a full Codex chapter for the interior. [Mau'ari chain](https://questing.wiki/wow-forever/quests/series/969/) · [Frostmaul count discrepancy](https://urgametips.com/wow-forever/quest-guides/luck-be-with-you-frostmaul-shards-frostwhisper/) · [Evie quest](https://www.wowhead.com/forever/quest=92859/shroud-of-the-winter-wilds) · [Forever Hyjal access](https://wofwforever.com/en/guides/wow-forever-mount-hyjal-access/)
- **Plaguelands.** The finishers for the cauldron campaign now appear next to the last cauldron delivery. Current QDB and the published Forever record place 5238 at Ashlam after 5226, and QDB places 5237 at Derrington after 5236. The supplied Z guides show the opposite ID pair, and some Classic-derived pages disagree. Confirm the ID of the offered quest on both factions before marking the chapters live-verified. The cleanups, commissions, Andorhal timers and the Bulwark/Chillwind faction splits remain in place. Darrowshire's extended group defense stays off the leveling itinerary because it needs additional work after both item quests return to Carlin. [Alliance 5238 record](https://senseos.gg/wiki/wow-forever/quests/5238/mission-accomplished/) · [Prior source discrepancy](2026-11-16-alliance-nearby-45-60.md)
- **Un'Goro, Felwood, Azshara and Silithus.** The Alliance Pterrordax pickup now points to the sign next to Spraggle. Prior work carries the Mithril Casing, collects the hive sample with the Gorishi loop and escorts Ringo on the volcano return. The Advanced Pylons and Torwa's far-north ape follow-ups remain separate excursions. Felwood retains the purified water and Shadow Hold handoff, including the return after the escort opens Retribution of the Light. The Azshara class visits stay in the same Naga/Satyr circuits where available. Both Silithus routes still start at the ramp and Southwind before Cenarion Hold, sharing the Twilight camps with the lexicon and papers. Raid and reputation turn-ins remain separate. [Polestar library, level 50–60 entries](https://polestar.guide/guides?shelf=more&view=all) · [Alliance 50–60 pass](2026-11-14-alliance-50-60.md) · [Horde 50–60 pass](2026-11-14-horde-50-60.md)

## Coverage summary

| Faction | Main | Alternate | Class | Dungeon | Special | Total | Chapter data changed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Alliance | 43 | 20 | 70 | 31 | 9 | 173 | 22 |
| Horde | 49 | 21 | 50 | 27 | 6 | 153 | 18 |

The checkpoints combine earlier chapter walkthroughs with current endpoint, prerequisite, inventory, capacity and handoff checks. The final continuity scan found a turn-in or explicit cleanup in the same faction's catalog for every accepted quest ID, including quests carried across chapters. The cap check simulates each race and class with and without planned dungeon and optional quests. The player scenarios check selected join, skip, arrival and reload cases. Live confirmation is still needed where the table lists a specific discrepancy.

| Player path | What the audit checked |
| --- | --- |
| Full route with dungeon pickups | The capacity simulation follows carried hand-ins and cleanup. Night Elves entering Westfall can retire 952, and moving 501 to the next Tarren Mill visit leaves room for 479 and the planned dungeon quests. |
| Join in the middle or from an alternate | Harlo's pickup can recover after raptor completion. The Shimmering Flats guide can start at Theramore. The Sepulcher chapter takes 479 only when the player has finished 482, regardless of which Silverpine entry they took. |
| Skip an optional quest or elite fight | The ship route proceeds without Cortello's scroll. The Arathi group option covers both wanted quests and the later cove circuit continues after a skip. |
| Reload or travel with another quest ready | The mock scenarios cover a late quest log after login, alternate switches after a manual skip, Booty Bay with 2874 ready, and Sven's delivery while 153 is ready at the same flight destination. |

## First live checks

- At Menethil's north gate, load in as a level-29 Skyborne with 472 unaccepted and the raptor work finished. Verify Harlo appears, and Next still advances past him.
- Land at Theramore on the Flats guide and at Booty Bay with 2874 ready. From Booty Bay, take the guide-marked flight into Stonard while both Cortello's clue and the Blasted Lands turn-in are active.
- Check Mau'ari's live objective count for 969 and the offer for 975. Check whether the last cauldron delivery opens 5238 at Ashlam and 5237 at Derrington.
- At the Krol'dok return, confirm Komuk's Warmaul drop, Brant's hand-in, and Dumas's materials. The chapter table carries the other outstanding offer and spawn checks.

## Zone inventory

Counts include client-present quest IDs with a listed quest level from 1 through 60, grouped by quest zone or by a recorded starter spawn. A quest can count in more than one zone. Candidate counts include class, profession, seasonal, group and repeatable entries. The faction filter uses recorded race masks, so absent masks can leave faction-specific entries in both columns. Routed counts match any chapter in the faction's catalog, including optional quests and quests delivered in another zone. Use the band notes for route decisions and the live column for unresolved eligibility.

| Zone | Alliance candidates | Alliance routed | Horde candidates | Horde routed |
| --- | ---: | ---: | ---: | ---: |
| Northshire | 12 | 12 | 0 | 0 |
| Elwynn | 117 | 99 | 36 | 0 |
| Westfall | 57 | 42 | 13 | 1 |
| Redridge | 51 | 41 | 6 | 0 |
| Stormwind | 272 | 162 | 66 | 11 |
| Duskwood | 79 | 76 | 5 | 1 |
| Dun Morogh | 124 | 90 | 43 | 0 |
| Loch Modan | 60 | 41 | 8 | 1 |
| Wetlands | 84 | 63 | 24 | 0 |
| Darkshore | 85 | 76 | 8 | 0 |
| Teldrassil | 113 | 90 | 34 | 0 |
| Zephras Isle | 132 | 105 | 137 | 86 |
| Ironforge | 245 | 81 | 57 | 8 |
| Darnassus | 92 | 45 | 25 | 6 |
| Durotar | 23 | 2 | 116 | 90 |
| Mulgore | 25 | 1 | 99 | 74 |
| Barrens | 64 | 25 | 197 | 148 |
| Tirisfal | 42 | 0 | 145 | 111 |
| Silverpine | 18 | 5 | 72 | 52 |
| Orgrimmar | 70 | 9 | 250 | 89 |
| Thunder Bluff | 28 | 6 | 113 | 57 |
| Undercity | 53 | 8 | 161 | 75 |
| Stonetalon | 28 | 12 | 38 | 30 |
| Ashenvale | 77 | 48 | 36 | 22 |
| Hillsbrad | 45 | 34 | 66 | 49 |
| Thousand Needles | 47 | 27 | 73 | 57 |
| Alterac | 80 | 23 | 77 | 10 |
| Arathi | 73 | 26 | 81 | 28 |
| Desolace | 77 | 31 | 78 | 34 |
| Dustwallow | 54 | 39 | 64 | 48 |
| Stranglethorn | 195 | 101 | 193 | 83 |
| Swamp of Sorrows | 32 | 15 | 43 | 26 |
| Badlands | 40 | 21 | 53 | 35 |
| Tanaris | 131 | 47 | 133 | 49 |
| Feralas | 64 | 43 | 52 | 42 |
| Hinterlands | 23 | 16 | 39 | 30 |
| Searing Gorge | 33 | 24 | 25 | 18 |
| Blasted Lands | 34 | 13 | 30 | 10 |
| Burning Steppes | 46 | 31 | 28 | 14 |
| Western Plaguelands | 70 | 53 | 65 | 48 |
| Eastern Plaguelands | 107 | 34 | 113 | 38 |
| Felwood | 48 | 32 | 58 | 33 |
| Winterspring | 56 | 29 | 54 | 31 |
| Azshara | 77 | 18 | 88 | 28 |
| Un'Goro | 47 | 32 | 46 | 38 |
| Silithus | 86 | 19 | 86 | 17 |
| Moonglade | 33 | 20 | 33 | 20 |
| Riverglades | 140 | 91 | 123 | 83 |
| Shen'dralas | 36 | 7 | 36 | 7 |
| Mount Hyjal | 137 | 0 | 131 | 0 |
| Deadwind Pass | 0 | 0 | 0 | 0 |

## Chapter coverage

The table credits prior chapter work where a new check left the route intact. Live checks describe specific remaining observations. The database and mock passes do not certify live availability.

| Faction | Chapter ID | Levels | Sources checked | Fixes or prior work retained | Live checks |
| --- | --- | --- | --- | --- | --- |
| Alliance | `northshire` | 1–5 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the Echo Ridge and vineyard circuits and the original book drop. | 3903 offer before or after 18 on a character with 33 done |
| Alliance | `coldridge` | 1–6 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the western circuit, Ironforge flight point and Shimmer Stout handoff. | Check Brewnall's 413 offer and Loch Modan entrance |
| Alliance | `shadowglen` | 1–6 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the cave circuit and Dolanaar handoff. | Check the handoff from a partially completed Shadowglen |
| Alliance | `zephras` | 1–5 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the faction-specific starter chains and village handoff. | Level at the delayed tower pickups |
| Alliance | `shaman-earth-totem` | 4–6 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `shendar` | 5–8 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the faction-specific starter chains and village handoff. | Level at the delayed tower pickups |
| Alliance | `priest-garments-elwynn` | 5–6 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-garments-dun-morogh` | 5–6 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `elwynn` | 6–12 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the Fargodeep and Jasperlode passes and the Goldshire/Stormwind handoff. | Check hearth cooldown on fast completion of the eastern loop |
| Alliance | `dunmorogh` | 6–12 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the western circuit, Ironforge flight point and Shimmer Stout handoff. | Check Brewnall's 413 offer and Loch Modan entrance |
| Alliance | `teldrassil` | 6–12 | Client, QDB, Forever guides, [prior pass](2026-11-12-alliance-1-12.md) | Added optional 952 from Fandral after 940 for the Darkshore handoff. | 952 offer after 940 |
| Alliance | `valanaar` | 8–13 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained the forest and cultist circuits and Stormwind handoff. | Valanaar bind name and skycutter arrival |
| Alliance | `warrior-defense-human` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-haggards-weapon` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-defense-ironforge` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-grey-iron-weapons` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-defense-nightelf` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-weapons-of-elunite` | 10–13 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `hunter-taming-dwarf` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `hunter-taming-human` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-blade-human` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-blade-dun-morogh` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-blade-night-elf` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-divine-grace` | 10–10 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-desperate-prayer` | 10–10 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the Rohan route from the supplied Forever guide. | Confirm exact 5639 turn-in and trainer |
| Alliance | `priest-confounding-flash` | 10–10 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `mage-mirror-lake` | 10–10 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `mage-gizmonitor` | 10–10 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-voidwalker` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `druid-bear-form` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `druid-moonglade-skyborne` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `shaman-fire-totem` | 10–14 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `loch-modan` | 11–18 | Client, QDB, RXP, Z, [prior pass](2026-11-12-alliance-1-12.md) | Retained separate entrances and carried 413/1097 errands. | Fresh arrival at Thelsamar from another alternate |
| Alliance | `westfall` | 12–18 | Client, QDB, Forever guides, [prior pass](2026-11-12-alliance-1-12.md) | Added log cleanup for carried 952 at entry. | Westfall entry with 952 carried |
| Alliance | `darkshore` | 12–20 | Client, QDB, Forever guides, [prior pass](2026-11-12-alliance-1-12.md) | Added Onu's 952 delivery and automated the Menethil arrival with 942 carried. | Onu's delivery on a direct join and Flagongut's 942 after docking |
| Alliance | `paladin-redemption-human` | 12–14 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `paladin-redemption-dwarf` | 12–14 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `valley-of-trials` | 1–6 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Moved the class letters and 4402 after 788. Added optional 97279 to the boar circuit. | Initial 97279 offer and Kzan's turn-in on a fresh Orc or Troll |
| Horde | `camp-narache` | 1–6 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained Bloodhoof and the grouped Thunder Bluff errands. | Traditions vendors and Incense Burner |
| Horde | `deathknell` | 1–6 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the Brill, Agamand and Undercity circuits. | Chill of Death offer at second Brill stop and 5658 giver |
| Horde | `zephras` | 1–5 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the faction-specific starter chains and village handoff. | Level at the delayed tower pickups |
| Horde | `shendar` | 5–9 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the faction-specific starter chains and village handoff. | Level at the delayed tower pickups |
| Horde | `durotar` | 6–10 | Client, QDB, Forever guides, [prior pass](2026-11-12-horde-1-12.md) | Set 825 after 784 and grouped the wreck, eggs and pear objectives on the existing southbound trip. | 825 offer after 784 and wreck crates on the coast pass |
| Horde | `mulgore` | 6–12 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained Bloodhoof and the grouped Thunder Bluff errands. | Traditions vendors and Incense Burner |
| Horde | `tirisfal` | 6–12 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the Brill, Agamand and Undercity circuits. | Chill of Death offer at second Brill stop and 5658 giver |
| Horde | `valanaar` | 9–12 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the Broken Construct and Shaman fire circuit, and the Mulgore–Thrall handoff. | Ayessa's final offers, Thunder Bluff taxi availability |
| Horde | `northern-durotar` | 10–12 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the crocolisk/Thunder Ridge loop and the Far Watch handoff. | Exact 5654/5655 offer at Tai'jin and timed power stone on guide switch |
| Horde | `warrior-defense-barrens` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warrior-forged-steel` | 10–14 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warrior-agamand-heirlooms` | 10–13 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `mage-ju-ju-heaps` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `mage-study-horde` | 10–24 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `druid-bear-form-tauren` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `druid-moonglade-skyborne-horde` | 10–12 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `shaman-fire-totem-horde` | 10–13 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `silverpine` | 12–15 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Retained the road and zeppelin entry paths and Forsaken/other-race filters. | 429 offer without 428, 425 offer after 91921/430 |
| Horde | `silverpine-early` | 12–15 | Client, QDB, Forever guides, [prior pass](2026-11-12-horde-1-12.md) | Advance the zeppelin on arrival. 482 here unlocks the later Ambermill pickup. | Complete 482 and check Allister on the later Sepulcher visit |
| Horde | `crossroads` | 12–15 | Client, QDB, RXP, Z, [prior pass](2026-11-12-horde-1-12.md) | Confirmed four racial delivery paths and Dreadmist's timed handoff. | 5041 availability before 871 turn-in |
| Horde | `paladin-redemption-undead` | 12–14 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `dungeon-hall-of-thanes` | 13–18 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-ragefire-chasm` | 13–18 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `cozy-sleeping-bag` | 14–32 | Client, QDB, [prior pass](2026-11-09-special-quests.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `druid-cure-poison` | 14–16 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `dungeon-ruins-of-lordaeron` | 15–20 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `mage-manaweave-robe` | 15–17 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `mage-research-access` | 15–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-lockpicking` | 16–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `druid-aquatic-form` | 16–18 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `lakeshire` | 17–22 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `dungeon-deadmines` | 17–26 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-wailing-caverns` | 17–25 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `ashenvale-early` | 18–24 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `wetlands-early` | 20–25 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `warrior-furens-favor` | 20–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `paladin-sense-undead` | 20–25 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-poisons` | 20–26 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-horn-of-xelthos` | 20–26 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-feedback` | 20–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-chastise` | 20–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-contingency-plan` | 20–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-elunes-grace` | 20–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-sayaad` | 20–24 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-orb-of-soranruk` | 20–28 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `shaman-water-totem` | 20–23 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `druid-cat-night-elf` | 20–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `druid-cat-skyborne` | 20–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `duskwood` | 21–27 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `stonetalon` | 22–28 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `dungeon-shadowfang-keep` | 22–30 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-stockade` | 22–30 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `legend-of-stalvan` | 22–35 | Client, QDB, [prior pass](2026-11-09-special-quests.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `paladin-verigans-fist` | 22–28 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `redridge-late` | 23–29 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `ashenvale-late` | 24–30 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `dungeon-blackfathom-deeps` | 24–32 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `seeking-caitlin` | 24–31 | Client, QDB, [prior pass](2026-11-09-special-quests.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `rogue-ravenholdt-manor` | 24–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-syndicate-sabotage` | 24–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `duskwood-late` | 25–30 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `warrior-fire-hardened-mail` | 25–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `paladin-divine-storm-cloak` | 25–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-dread-mage-hat` | 25–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `wetlands` | 26–30 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-1-60-audit.md) | Moved Harlo's 472 beside 484 and fixed recovery for his deferred pickup. | Level-29 Skyborne after reload. Confirm the observed level-24 299 offer. |
| Alliance | `dungeon-excavation-site` | 26–31 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `mage-astral-knot` | 26–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `southshore` | 27–30 | Client, QDB, [prior pass](2026-11-14-alliance-1-60-audit.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `dungeon-city-of-dalaran` | 28–33 | Client, QDB, [prior pass](2026-11-09-dungeon-routes.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `missing-diplomat` | 28–38 | Client, QDB, [prior pass](2026-11-09-special-quests.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `warrior-fire-hardened-coif` | 28–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-fire-hardened-gauntlets` | 28–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-fire-hardened-leggings` | 28–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `dungeon-gnomeregan` | 29–38 | Client, QDB, quest records, [prior pass](2026-11-09-dungeon-routes.md) | Set the 2904 escort minimum to 24. | Escort offer at level 24 |
| Alliance | `dungeon-razorfen-kraul` | 29–38 | Client, QDB, quest records, [prior pass](2026-11-09-dungeon-routes.md) | Set the 1144 escort minimum to 23. | Escort offer at level 23 |
| Horde | `dungeon-ragefire-chasm` | 13–18 | Client, QDB, [prior pass](2026-11-10-horde-dungeons.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `cozy-sleeping-bag-horde` | 14–32 | Client, QDB, [prior pass](2026-11-09-special-quests.md) | Retained the special chain and checked entry and delivery links. | — |
| Horde | `druid-cure-poison-horde` | 14–16 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `barrens-north` | 15–16 | Client, QDB, [prior pass](2026-11-12-horde-12-22.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `mage-spellfire-robes` | 15–17 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `barrens-south` | 16–18 | Client, QDB, [prior pass](2026-11-12-horde-12-22.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `rogue-lockpicking-horde` | 16–20 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-tools-of-the-trade` | 16–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `druid-aquatic-form-horde` | 16–18 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `dungeon-ruins-of-lordaeron` | 17–22 | Client, QDB, [prior pass](2026-11-10-horde-dungeons.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-wailing-caverns` | 17–25 | Client, QDB, [prior pass](2026-11-10-horde-dungeons.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `sun-rock` | 18–21 | Client, QDB, [prior pass](2026-11-12-horde-12-22.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `paladin-lumina-windsinger` | 19–24 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warrior-field-of-giants` | 20–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-poisons-horde` | 20–26 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-horn-of-xelthos-horde` | 20–26 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warlock-sayaad-horde` | 20–27 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warlock-orb-horde` | 20–28 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `druid-cat-form-tauren` | 20–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `druid-cat-form-skyborne-horde` | 20–22 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `shaman-water-totem-horde` | 20–25 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `zoramgar` | 21–22 | Client, QDB, [prior pass](2026-11-12-horde-12-22.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `sepulcher` | 22–23 | Client, QDB, Forever guides, [prior pass](2026-11-12-horde-22-30.md) | Advance the zeppelin and group 479 with 95981 and Beren's Peril. | 479 after 482. Check the separate pendant and kill-credit camps. |
| Horde | `dungeon-shadowfang-keep` | 22–30 | Client, QDB, [prior pass](2026-11-10-horde-dungeons.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `hillsbrad` | 23–25 | Client, QDB, Forever guides, [prior pass](2026-11-12-horde-22-30.md) | Moved 501 to the second Tarren Mill visit and added the 479 hand-in on the existing Sepulcher return. | Quest-log slots with dungeon prep. Verify 480's requirements. |
| Horde | `paladin-wolfsbane` | 24–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-ravenholdt-horde` | 24–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-syndicate-sabotage-horde` | 24–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `camp-taurajo` | 25–26 | Client, QDB, [prior pass](2026-11-12-horde-22-30.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `stonetalon-sunrock` | 25–27 | Client, QDB, [prior pass](2026-11-12-horde-22-30.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `dungeon-blackfathom-deeps` | 25–32 | Client, QDB, [prior pass](2026-11-10-horde-dungeons.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `warrior-brutal-hauberk` | 25–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `ashenvale-splintertree` | 26–28 | Client, QDB, [prior pass](2026-11-12-horde-22-30.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `mage-nether-lace` | 26–28 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `thousand-needles` | 28–30 | Client, QDB, [prior pass](2026-11-12-horde-22-30.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `dungeon-excavation-site` | 28–33 | Client, QDB, [prior pass](2026-11-10-horde-dungeons.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `warrior-brutal-gauntlets` | 28–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warrior-brutal-helm` | 28–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warrior-brutal-legguards` | 28–30 | Client, QDB, [prior pass](2026-11-11-class-quest-audit.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `shimmering-flats` | 29–31 | Client, QDB, [prior pass](2026-11-12-horde-22-30.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `darkshire-30` | 30–32 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-30-40.md) | Set the minimum for Morbent Fel (55) to 20 and preserved Sven's guide-selected flight handoff. | Sentinel Hill with Sven and another turn-in ready |
| Alliance | `stv-30` | 30–35 | Client, QDB, Forever guides, [prior pass](2026-11-17-alliance-stranglethorn-vale.md) | Kept the c49dd98 Rebel Camp sweep and the fuller 36–38 return. | See the prior Stranglethorn live checks |
| Alliance | `dungeon-scarlet-monastery-graveyard` | 30–38 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `warrior-berserker-stance` | 30–30 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-eye-of-bhossca` | 30–30 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `mage-wand` | 30–30 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-felhunter` | 30–30 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `shaman-air-totem` | 30–30 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warrior-whirlwind-weapon` | 30–40 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `hillsbrad-32` | 31–34 | Client, QDB, [prior pass](2026-11-14-alliance-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `needles-33` | 33–35 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-30-40.md) | Advance the Menethil ship at Theramore and resume at the docks. | Theramore arrival with an older objective ready |
| Alliance | `theramore-33` | 33–37 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-30-40.md) | Advance the Menethil ship at Theramore before the docks flight point. | Direct join at Theramore |
| Alliance | `dungeon-scarlet-monastery-library` | 33–40 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `desolace-35` | 35–37 | Client, QDB, [prior pass](2026-11-14-alliance-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `dungeon-drowned-city` | 35–40 | Client, QDB, quest records, [prior pass](2026-11-17-alliance-stranglethorn-vale.md) | Kept the c49dd98 side guide and optional dungeon handoff. | See the prior Stranglethorn live checks |
| Alliance | `dungeon-scarlet-monastery-armory` | 35–42 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-razorfen-downs` | 35–42 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `riverglades-farholde` | 36–41 | Client, QDB, [prior pass](2026-11-14-alliance-30-40.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `stv-36` | 36–38 | Client, QDB, Forever guides, [prior pass](2026-11-17-alliance-stranglethorn-vale.md) | Kept the c49dd98 Rebel Camp, Stockpile and Booty Bay order. | 97047 lower-level key and supply crate |
| Alliance | `dungeon-scarlet-monastery-cathedral` | 37–44 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `swamp-38` | 38–39 | Client, QDB, [prior pass](2026-11-14-alliance-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `dungeon-uldaman` | 38–47 | Client, QDB, quest records, [prior pass](2026-11-10-dungeons-30-60.md) | Closed 2199 with five Silver Bars at Talvash. 2200 remains a separate run. | Talvash's offer after 2198 |
| Alliance | `mage-celestial-power` | 38–42 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-orb-of-orahil` | 38–41 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `arathi-39` | 39–40 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-30-40.md) | Added elite 684 at the 685 board and grouped the ruins objective and delivery. | 684 offer and east-side spawn. Skip both elites into the cove. |
| Horde | `hillsbrad-30` | 30–33 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-30-40.md) | Advance the zeppelin before the Undercity pickup for 1164. | Undercity entry after the zeppelin |
| Horde | `stv-30` | 30–34 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-razorfen-kraul` | 30–38 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Applied Willix's shared 1144 minimum of 23. | Willix's offer at level 23 |
| Horde | `dungeon-gnomeregan` | 30–38 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Applied Kernobee's shared 2904 minimum of 24. Scooty still takes the report. | Kernobee's offer at level 24 |
| Horde | `dungeon-city-of-dalaran` | 30–36 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-scarlet-monastery-graveyard` | 30–38 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `warrior-berserker-stance` | 30–30 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-eye-of-bhossca-horde` | 30–30 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `mage-wand-horde` | 30–30 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warlock-felhunter-horde` | 30–30 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `shaman-air-totem-horde` | 30–30 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `desolace-31` | 31–36 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `flats-33` | 33–34 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `dustwallow-33` | 33–37 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-scarlet-monastery-library` | 33–40 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `desolace-34` | 34–36 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `stv-35` | 35–37 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-30-40.md) | Corrected the Stockpile key, crate and nearby spawns. Explained Cozzle's key. | 97047 key and crate, and 97048 at Aransas |
| Horde | `dungeon-scarlet-monastery-armory` | 35–42 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `warrior-whirlwind-weapon-horde` | 35–40 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `mage-celestial-power-horde` | 35–40 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warlock-orb-of-orahil-horde` | 35–40 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `shaman-tempests-weapons-horde` | 35–40 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `riverglades-rogmar` | 36–41 | Client, QDB, [prior pass](2026-11-12-horde-riverglades.md) | Kept the Highlands or Powderfuse entry and verified carried 95141 and 95143. | Minimum levels for Aggro'gosh and Tor'gan's offers |
| Horde | `dustwallow-37` | 37–38 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `badlands-37` | 37–40 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-scarlet-monastery-cathedral` | 37–44 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-razorfen-downs` | 37–42 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `arathi-38` | 38–39 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-30-40.md) | Advance the zeppelin and keep Calder's carried 97985 after landing. | Undercity arrival with 97985 ready |
| Horde | `badlands-39` | 39–40 | Client, QDB, [prior pass](2026-11-14-horde-30-40.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `riverglades-shroud` | 40–46 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Corrected the quest level and five-page objective for 94879. | Five pages and Ashe's pickup in the Sunnyglade loop |
| Alliance | `dustwallow-40` | 40–41 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-40-50.md) | Advance the inbound ship before the Theramore inn bind. | Theramore arrival after the Arathi flight |
| Alliance | `desolace-40` | 40–41 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `shendralas` | 40–46 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Kept the pylon and temple chain. | Eligibility for the ambient quests and Desolace reputation prerequisites |
| Alliance | `dungeon-krol-dok-stronghold` | 40–45 | Client, QDB, quest records, [prior pass](2026-11-10-dungeons-30-60.md) | Updated the 94926 hand-in, the 94980–81 key follow-up and 94997–98 endpoints. | Warmaul drop source, Dumas's materials and Brant's hand-in |
| Alliance | `badlands-41` | 41–42 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-40-50.md) | Corrected the 718 pickup to Sigrun during Uldaman prep. | 718 offer at Sigrun |
| Alliance | `stv-41` | 41–43 | Client, QDB, Forever guides, [prior pass](2026-11-17-alliance-stranglethorn-vale.md) | Kept the c49dd98 southern ship route and Cortello handoff. | Cortello scroll below deck among the Bloodsail ships |
| Alliance | `dungeon-zul-farrak` | 42–48 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `tanaris-43` | 43–44 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `feralas-44` | 44–48 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `dungeon-maraudon` | 44–52 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `searing-gorge` | 45–50 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `blasted-lands-47` | 47–50 | Client, QDB, [prior pass](2026-11-14-alliance-40-50.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `dungeon-sunken-temple` | 47–54 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `hinterlands-48` | 48–49 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-40-50.md) | Added optional 86616 to the Altar of Zul circuit and automated Menethil arrival. | Maret's offer and 12 totems along the altar approach |
| Alliance | `ungoro-49` | 49–50 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-40-50.md) | Advance at Booty Bay on the Ratchet crossing. | Boat arrival with 2874 ready |
| Horde | `stv-40` | 40–41 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `dustwallow-40` | 40–46 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-krol-dok-stronghold` | 40–45 | Client, QDB, [prior pass](2026-11-12-horde-riverglades.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-uldaman` | 40–47 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `warlock-felsteed-horde` | 40–40 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `swamp-41` | 41–42 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `desolace-41` | 41–41 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `tanaris-41` | 41–43 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `riverglades-bolderok` | 41–46 | Client, QDB, [prior pass](2026-11-12-horde-riverglades.md) | Kept the Bolderok hub and Krol'dok referral. | Moulding drop and faction-specific starter ID |
| Horde | `riverglades-eastsea` | 41–45 | Client, QDB, [prior pass](2026-11-12-horde-riverglades.md) | Kept the Powderfuse and coastal alternate. | Independent join without the Rog'mar introductions |
| Horde | `shendralas-pylons` | 41–46 | Client, QDB, [prior pass](2026-11-12-horde-riverglades.md) | Kept the pylon and temple chain. | Eligibility for the ambient quests and Desolace reputation prerequisites |
| Horde | `feralas-43` | 43–45 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `stv-44` | 44–45 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-40-50.md) | Corrected Gorlash and added the Cortello scroll to the 608 ship hunt. | Gorlash on the beach and 4056 below deck |
| Horde | `dungeon-zul-farrak` | 44–50 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-30-45.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `swamp-45` | 45–46 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `searing-45` | 45–50 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `tanaris-46` | 46–48 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `dungeon-maraudon` | 46–52 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `blasted-47` | 47–50 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `hinterlands-48` | 48–49 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-40-50.md) | Advance at Tirisfal before the Undercity pickup. | 2995 after the crossing |
| Horde | `ungoro-48` | 48–50 | Client, QDB, [prior pass](2026-11-14-horde-40-50.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `feralas-49` | 49–50 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-40-50.md) | Advance at Booty Bay before MacKinley's 2874. | Arrival followed by a quest-log refresh |
| Alliance | `stv-50` | 50–50 | Client, QDB, Forever guides, [prior pass](2026-11-17-alliance-stranglethorn-vale.md) | Kept the c49dd98 Jaguero circuit. Advance the inbound boat at the docks. | Join from Ratchet and directly from Booty Bay |
| Alliance | `searing-50` | 50–51 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `azshara-alt` | 50–54 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `searing-alt` | 50–56 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `dungeon-blackrock-depths` | 50–58 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `blasted-51` | 51–51 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `wpl-51` | 51–52 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `felwood-52` | 52–52 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `feralas-52` | 52–53 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `shadowforge-key` | 52–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `warrior-voodoo-feathers` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `paladin-mightstone` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `hunter-green-drake` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `priest-blood-of-morphaz` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `rogue-azure-key` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `mage-destroy-morphaz` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `warlock-trolls-of-a-feather` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `druid-better-ingredient` | 52–54 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `azshara-53` | 53–53 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `ungoro-53` | 53–54 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-50-60.md) | Moved the 4501 pickup to the sign beside Spraggle. | 4501 offer from the sign |
| Alliance | `winterspring-54` | 54–55 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `onyxia-attunement` | 54–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `warlock-kroshius` | 54–56 | Client, QDB, [prior pass](2026-11-10-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Alliance | `winterspring-55` | 55–56 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-50-60.md) | Added Mau'ari's 975 and Evie's optional 92859 toward Hyjal. | 969 shard count and 92859 offer at 55 |
| Alliance | `winterspring-alt` | 55–60 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-50-60.md) | Added 975 to the alternate's Frostmaul circuit. | 975 after 969 on an alternate join |
| Alliance | `silithus-alt` | 55–60 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Alliance | `dungeon-lower-blackrock-spire` | 55–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-dire-maul-east` | 55–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `molten-core-attunement` | 55–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `scholomance-key` | 55–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `steppes-56` | 56–57 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `plaguelands-57` | 57–58 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `dungeon-dire-maul-west` | 57–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-dire-maul-north` | 57–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-scholomance` | 57–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `dungeon-stratholme` | 57–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `ubrs-seal` | 57–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Alliance | `plaguelands-58` | 58–59 | Client, QDB, Forever guides, [prior pass](2026-11-14-alliance-50-60.md) | Added Ashlam's cauldron finisher after 5226. | Confirm Ashlam offers 5238 |
| Alliance | `dungeon-upper-blackrock-spire` | 58–60 | Client, QDB, [prior pass](2026-11-10-dungeons-30-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Alliance | `silithus-59` | 59–59 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Alliance | `silithus-60` | 59–60 | Client, QDB, [prior pass](2026-11-14-alliance-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `blasted-50` | 50–51 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-50-60.md) | Fixed the boat arrival, Mok'rash sash, Negolash bait and Jaguero note. Preserve the selected flight handoff. | Stonard with 624 and a Blasted Lands turn-in ready |
| Horde | `searing-alt` | 50–53 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `ungoro-alt` | 50–56 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-sunken-temple` | 50–56 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `searing-51` | 51–52 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `azshara-alt` | 51–54 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `azshara-52` | 52–53 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `felwood-alt` | 52–56 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-blackrock-depths` | 52–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `shadowforge-key-horde` | 52–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Horde | `warrior-voodoo-feathers-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `hunter-green-drake-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `priest-blood-of-morphaz-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `rogue-azure-key-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `mage-destroy-morphaz-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `warlock-trolls-of-a-feather-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `druid-better-ingredient-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `shaman-da-voodoo-horde` | 52–54 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `felwood-53` | 53–54 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `plaguelands-alt` | 53–58 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-50-60.md) | Added Derrington's cauldron finisher to the alternate. | Check 5237 on direct join after 5236 |
| Horde | `ungoro-54` | 54–55 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `warlock-kroshius-horde` | 54–56 | Client, QDB, [prior pass](2026-11-12-horde-class-30-60.md) | Retained the class chain and checked pickup and delivery links. | — |
| Horde | `winterspring-55` | 55–56 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-50-60.md) | Added 969 and 975 to the hot-spring leg and optional 92859 toward Hyjal. | 969 shard count and 92859 offer at 55 |
| Horde | `silithus-alt` | 55–60 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `winterspring-alt` | 55–60 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained entry and return paths. Checked carries against the main route. | — |
| Horde | `dungeon-lower-blackrock-spire` | 55–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-dire-maul-east` | 55–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `attunement-onyxia-horde` | 55–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Horde | `molten-core-attunement-horde` | 55–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Horde | `scholomance-key-horde` | 55–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Horde | `plaguelands-56` | 56–57 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-50-60.md) | Advance the zeppelin before Bulwark prep. | Direct join from Undercity |
| Horde | `plaguelands-57` | 57–58 | Client, QDB, Forever guides, [prior pass](2026-11-14-horde-50-60.md) | Added Derrington's cauldron finisher after 5236. | Confirm Derrington offers 5237 |
| Horde | `dungeon-dire-maul-west` | 57–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-dire-maul-north` | 57–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-scholomance` | 57–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `dungeon-stratholme` | 57–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `ubrs-seal-horde` | 57–60 | Client, QDB, [prior pass](2026-11-10-attunements.md) | Retained the special chain and checked entry and delivery links. | — |
| Horde | `silithus-58` | 58–59 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
| Horde | `dungeon-upper-blackrock-spire` | 58–60 | Client, QDB, [prior pass](2026-11-12-horde-dungeons-45-60.md) | Retained the dungeon route and checked prep and hand-in links. | — |
| Horde | `silithus-59` | 59–60 | Client, QDB, [prior pass](2026-11-14-horde-50-60.md) | Retained the prior circuit and checked adjacent handoffs. | — |
