# Skyborne (High Order) 1-13 route audit: Zephras Isle

Draft snippet: three sections, `zephras` (Thendal Grove, 1-5), `shendar` (Shen'dar Village, 5-8) and `valanaar` (Valanaar, 8-13), all `start = "SKYBORNE"` on UiMap 2521. 103 quests, every ID present in the Forever client reference (`forever.json` `quests.ids`, build 1.60.1.70862). All unverified.

## Race token and faction

The client's ChrRaces has two Skyborne rows sharing `ClientFileString = "Skyborne"`: 95 "High Order Skyborne" (Alliance, Common) and 96 "Windshaper Skyborne" (Horde, Orcish). `UnitRace` therefore returns `Skyborne` for both, and Quests.lua upper-cases it to `SKYBORNE`. The route sits under `ALLIANCE`, so only the High Order plays it. Add `SKYBORNE = "zephras"` to `starts`.

## Sources

- Quest facts (givers, turn-ins, coordinates, objectives, levels): the QuestieDB Forever cache through `tools/questfacts.py`. The data has no minimum levels and no prerequisite fields for these quests, so `min = 1` everywhere and the chains follow the NPC hand-offs in the published route.
- Order and faction split: [Bind on Forever, Zephras Isle](https://bindonforever.com/zones/zephras-isle) (its High Order route, trainer list, innkeeper Donaal Downbreeze at 62.2, 72.6, and the leyline, cave, Vulgara and Shrine notes). Step text was written fresh.
- Leaving the island: [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/how-to-get-to-ironforge-from-the-zephras-isle/), [Gamer Guides](https://gamer-guides.com/warcraft-forever/zephras-isle-to-stormwind-orgrimmar/), [All Things How](https://allthings.how/how-to-complete-the-magical-city-of-dalaran-in-wow-forever/).
- Mob places: `questfacts.py npc` spawn clusters (Vuldren, Cirrusflies, Converts, Ursera, Al'Aketh camps, hippogryphs, bandits, Stormcallers, Assassins, Wind Hollows, Shrine guards).

## Why this order

Three hubs, each with its own class trainers, so each is a section (withTrainers takes one trainer list per section; two sections would need a custom trainer helper). The order follows the published High Order route because the zone is a strict story chain: Thendal Grove's opening and class letters, the stones and converts north-east, the ursera cave west, Hanaa's temple, then The Next Step to Shen'dar. Shen'dar runs the High Order welcome, a north-east loop (bandit cave) and a south-west loop (Seers, hippogryph nests, Vulgara), then Falaath and the western watchtower. Valanaar binds the hearth, does the Shriekling Den and Windfield Orchard first (hearth back), then the Overlook stones, eastern watchtower, the north-west highlands and Shadowgale Forest in one sweep (hearth back), then the finale at the Shrine of Akir and Rohashi Spires.

Class quests: Rorian's letters for Mage 92481, Hunter 92482, Rogue 92483, Druid 92485, Warrior 92532 (no class bits in the data; matched by the trainer each one points to). Valanaar class quests: Mage 93791/93797, Druid 94006/94638, Warrior 94003, Hunter 94978 > 94979 > 94013 > 94050 (order from the published route; the IDs' objectives are crawler, galestrider, Vuldren Alpha).

## How Skyborne leave the island

There is no flight path on Zephras Isle in the client (`TaxiNodes` only has a quest path). The Alliance leaves on The Magical City of Dalaran (94946): the skycutter from the south-east dock in Valanaar to Dalaran, turn in to Denaaris Stargale (QuestieDB; one guide names "Denara's Vanguard"), then the Stormwind portal in Dalaran's portal room, which lands in the Mage Quarter. No Ironforge or tram trip is needed. The route then learns the Stormwind flight path (Dungar) and walks to the Furlbrow farm in Westfall, where the shared `westfall` section starts. The player arrives around 13, a level over Westfall's start.

## Left out and why

- Windshaper/Horde branch: 92514, 92595, 94411, 92598, 92708, 92871, 92646, 93836, 93090, 95349, 92579, and the Shaman quests 92484, 92466-92468 (High Order has no Shaman).
- Camping 101 profession variants (only Cooking is on the main path), Engineering 98285, the hunter breadcrumb 94007 (offered at 10, after Shen'dar), More Al'Aketh Ears 93459 (not in the client), and Dalaran's follow-up "Welcome to Azeroth" (not in the data).
- Vendor stops (arrows, weapons, water) are not steps.

## Check in game

- `GetBindLocation()` at Donaal Downbreeze: the route assumes "Valanaar".
- Skycutter dock coordinates (65.7, 83.2 from one guide; others say "south-east" or "far end past the flightmaster"), and whether Valanaar has a flight master after all.
- Denaaris Stargale's position in Dalaran and the portal room location; the quest turns in on a map the reference lacks (Dalaran is continent 2959), so the step has no arrow.
- Whether class letters appear only after Harmony in Balance, and whether Rathiril credit for Welcome to Shen'dar Village lands before The High Order is offered.
- Hunter Taming the Beast order, Ripped Missive dropping from Commander Haalien, Desperate Times' scene location (around Elaadrin, 66.5, 79.9).
- Quest log size during the Shadowgale sweep (about 15), Vulgara (level 8 elite) and Hyusaa (13) difficulty, actual level on boarding.
