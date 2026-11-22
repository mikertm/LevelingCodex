# Travel resume audit after Sentinel Hill

Reviewed all 80 authored boat, zeppelin and airship steps across the 173 Alliance and 153 Horde chapters at `v0.28.1`. For each crossing, checked the departure, the landing map, the next quest or travel leg, and any later return on the same transport. Earlier work already gave 38 crossings an arrival check. This follow-up gives 41 more a destination check. Feathermoon's ferry keeps its manual step because both docks use the same Feralas map. The audit also traced onward flights and walking steps where the next stop proves an earlier crossing is finished. [Previous chapter coverage](2026-11-18-quest-route-coverage.md) · [Second-pass handoffs](2026-11-18-quest-route-second-pass.md) · [Forever travel reference](https://www.wowhead.com/forever/guide/flight-points-zeppelins-and-ships)

| Faction | Chapters | Change |
| --- | --- | --- |
| Alliance | `darkshire-30`, `valanaar` | Keep the Sentinel Hill overland approach. At the Dalaran dock, the Skyborne route goes straight to Denaaris. |
| Alliance | `desolace-40`, `hinterlands-48`, `winterspring-55`, `silithus-59` | Advance through the already completed parts of the linked road, ship and flight legs when following the chapter from Ironforge, Refuge Pointe or Everlook. |
| Horde | `hillsbrad`, `swamp-41`, `cozy-sleeping-bag-horde` | Continue the local Thunder Bluff errands after either earlier crossing. Start on the Westfall coast without going back to Grom'gol if carrying the sleeping bag quest. |
| Horde | `mage-study-horde`, `mage-spellfire-robes`, `warrior-whirlwind-weapon-horde`, `shaman-tempests-weapons-horde` | Advance the class-guide crossings on the appropriate side of the sea. |
| Horde | `dungeon-ragefire-chasm`, `dungeon-razorfen-kraul`, `dungeon-gnomeregan`, `dungeon-excavation-site`, `dungeon-scarlet-monastery-library`, `dungeon-razorfen-downs`, `dungeon-zul-farrak`, `dungeon-sunken-temple`, `dungeon-blackrock-depths`, `dungeon-lower-blackrock-spire`, `dungeon-upper-blackrock-spire` | Advance the outdoor preparation and post-run crossings on arrival. Use the landing zone or the adjoining capital for each Durotar and Tirisfal leg. |
| Horde | `attunement-onyxia-horde`, `scholomance-key-horde` | Advance each city-to-city or Grom'gol crossing at its own destination while keeping the later return crossings. |

Five player-facing replays failed on `v0.28.1` and passed with the route changes. They start Valanaar at the Dalaran dock, follow Ragefire from the Undercity back to Thrall, join Cozy Sleeping Bag on the Westfall coast, and reopen the Winterspring and Hillsbrad chapters from Ironforge and Thunder Bluff respectively. The existing Sentinel Hill reload and Wetlands-to-Auberdine tests also passed. The route audit passed all 12,807 steps with 336 advisory warnings.

The full harness passed 502 addon scenarios and 41 loot unit tests. The installer verified all 86 files in the Forever AddOns folder as `v0.28.1-dirty`.

In game, check the Skyborne hand-in at Denaaris after docking and the two Ragefire preparation legs with Varimathras in between. Check Feathermoon at the mainland dock and use Next to finish the same-map ferry step.
