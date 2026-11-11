# Starter gaps: starting zones, Loch Modan and city errands (1-15)

Quests that another Forever leveling guide routes in the Human, Dwarf/Gnome, Night Elf and Skyborne starter chapters (and the 11-16 Loch Modan and Stormwind visits) but that the Codex had nowhere. Facts come from `tools/questfacts.py` (QuestieDB Forever 0f7d8ad) and the Forever client tables (`ItemSparse` for the rare-head items). Both reference guides were read only for order and grouping. Every ID below is in the client reference.

A new pattern: **optional** steps (`quest[id].optional = true`, or step `optional`) show only with Settings > Show optional quests. They are used for profession intros, the skinning errand and pickups that sit outside Loch Modan's own map (see Loch Modan below).

## Added

### Elwynn Forest (`elwynn`)

| Quest | Where | Why there |
|---|---|---|
| Camping 101: Skinning 97924, Herbalism 97921, Mining 97923 (optional) | Accepted from Sam after Camping 101: Cooking. Skinning turned in to Helene Peltskinner (46.2, 62.2) right away; Herbalism to Herbalist Pomeroy (40.0, 48.4) on the road to Stormwind; Mining to Gelman Stonehand (Stormwind 59.3, 37.8) beside Elmore. | Only needs the profession (`requiredSkill` 1). Each turn-in sits on a road the route already uses. |
| Rough Wolf Pelts 91751 (optional, Skinning) | Accept at Helene with the Skinning lesson, skin Prowlers during the Eastvale loop (`along` Protect the Frontier), turn in at the level 10 Goldshire stop. | Eastvale's Prowlers are the wolves the route already kills. |
| Croaky's Head 91740 | Item 247826 (`startItem`). Accept after Ormin's tools on the river south of the bridge, turn in to Merell Ross at Ridgepoint Tower (84.8, 79.3) before going back to Ormin. | Croaky (level 11 elite per the reference guide, spawns 74-80, 76-87) shares the riverbank with Ormin's tools. The steps only appear with the head in bags. |
| Elmpaw's Head 91746 | Item 247862. Accept after the enchanting supplies (gnoll camps), turn in to Helene at the level 10 Goldshire stop. | Elmpaw (level 12) spawns 71-78, 36-43, next to that objective. |
| Elmore's Task 1097 | Accept from Smith Argus at the level 10 Goldshire stop, turn in to Grimand Elmore (Stormwind 59.7, 33.8) on the existing Stormwind visit. | Free XP on a trip the route already makes. Stormpike's Delivery (353) is left to the Loch Modan branch. |

The Croaky and Elmpaw objective texts now mention the rares so players know the heads start quests.

### Dun Morogh (`dunmorogh`)

| Quest | Where | Why there |
|---|---|---|
| Camping 101: Cooking 96629 | Accept from Eric Brighthammer after The Great Outdoors, turn in to Gremlock Pilsnor (47.7, 52.3) right after binding in the distillery. | Matches Elwynn, Teldrassil and Zephras, which already route their Cooking intro. |
| Protecting the Herd 314 | Accept from Rudra with Never Saddle on Quality; kill Vagash (62.6, 46.0) and turn in when you come back for the pelts. | The reference guide pulls Vagash to the ranch guards. The text says so and allows Next. |
| Deeprun Rat Roundup 6661, Me Brother, Nipsy 6662 | On the tram ride to Stormwind at the end of the section: Monty on the Ironforge platform, Nipsy on the Stormwind platform. | The route already takes the tram. The tram has no map in the client reference, so these steps carry no waypoint. |

### Teldrassil (`teldrassil`)

| Quest | Where | Why there |
|---|---|---|
| The Moss-twined Heart 927 -> Planting the Heart 941 | Item 5179 drops from Blackmoss the Fetid (level 13, 44.0, 30.2), next to the Mossy Tumors objective. Accept there with the heart in bags; turn in to Denalan and plant it in his planter (60.8, 68.6) on the existing Denalan visit. | `startItem` keeps both hidden unless the heart drops; 941's chain inherits the filter. |
| Philmor's Favor 97220 -> Gatehouse Goods 97222 | Philmor (Stormwind 30.4, 28.9) on the harbor's north docks when the Auberdine ship lands; Elaine Trias (66.6, 73.4) just west of Dungar's flight point. | Two level 15 deliveries on the walk from the harbor to the flight master. |

### Zephras Isle (`shendar`, `valanaar`)

| Quest | Where |
|---|---|
| Camping 101: Mining 97970, Skinning 97971, Herbalism 97968 (optional) | Accepted from Raan with the Cooking intro. Mining (Messana Crestwind 44.8, 44.6) and Skinning (Mendalass Tattermend 43.3, 43.4) are turned in in Shen'dar right away; Herbalism at Syriel Nightrain (57.9, 75.5) on arrival in Valanaar. These match Dalia's gathering choice. |

### Loch Modan (`loch-modan`)

| Quest | Where | Notes |
|---|---|---|
| Honor Students 6387 -> Ride to Ironforge 6391 -> Gryth Thurden 6388 -> Return to Brock 6392 (Dwarf/Gnome) | Right after the Thelsamar pickups: Brock (37.0, 47.8), Thorgrum, fly to Ironforge, Golnir Bouldertoe (51.5, 26.3), Gryth Thurden, fly back, Brock. | The reference guide does it on arrival. It needs the Ironforge flight path (Dwarf/Gnome learn it at the end of Dun Morogh); the first step says to use Next without it, and Next on the accept skips the whole chain. |
| Stormpike's Delivery 353 (Human, optional) | Accept from Grimand Elmore by the Stormwind tram, turn in to Stormpike with Mountaineer Stormpike's Task. | Needs Elmore's Task from Elwynn. |
| Stormpike's Order 1338 (optional) | Accept from Stormpike after Filthy Paws, turn in to Furen Longbeard (Stormwind 64.6, 37.2) as the section's last step. | Only worth it when the next zone is reached through Stormwind. |
| Deeprun Rat Roundup 6661 (Human/Night Elf/Skyborne, optional) | On the Ironforge platform of the tram on the way in. Me Brother, Nipsy (6662) is left for a later tram ride. | |
| Find Bingles 2039 (Human/Night Elf/Skyborne, optional) | Gnoarn in Tinker Town (69.2, 50.5) on the way in; turned in to Bingles just before Bingles' Missing Supplies. `breadcrumb(2039, 2038)`. | Level 12 minimum. |
| Stout to Kadrell 414 (Dwarf/Gnome, optional) | Mountaineer Barleybrew at South Gate Outpost on the way in, Kadrell in Thelsamar. | Needs Shimmer Stout from Dun Morogh. |

Why the Loch Modan pickups outside Loch Modan are optional: the viewer skips the way there (travel steps before the section's first step on its own map) once you are in Loch Modan, but not quest steps. A required pickup in Stormwind, the tram or at South Gate would send a player who is already in Loch Modan back (the `questAlternateRoutes` scenario checks this for a Dwarf). The prerequisites for 353 (1097, Elwynn) and 414 (413, Dun Morogh) are done in the racial start sections, which the route audit doesn't follow into an alternate, so those two accept steps drop their `chain` (the game still enforces it; the text says to use Next if it isn't offered).

### Class quests (QuestClassData.lua)

| Quest | Where |
|---|---|
| Divine Grace 94774 (Human Priest) | Inline in Elwynn: accept from Priestess Josetta at the level 10 Goldshire stop, turn in to High Priestess Laurena on the Stormwind visit. Exclusive with Laurena's own 94773, so the Divine Grace side guide now treats 94773 as a breadcrumb of 94774 (skipped once 94774 is taken). |
| Tome of Divinity 2998 (Human Paladin), 2999 (Dwarf Paladin) | First steps of the two Redemption side guides: Brother Wilhelm (Goldshire) -> Duthorian Rall, and Brandur Ironhammer (Ironforge 23.1, 6.1) -> Tiza Battleforge. Their classic follow-ups 1641/1645 aren't in the client; each is a breadcrumb of the first tome quest (1642/1646). |
| Moonglade 94914 (Skyborne Druid) | Inline in Valanaar's Stormwind leg: accept from Sheldras Moontree right after Child of Nature. New side guide `druid-moonglade-skyborne` holds the hand-in to Dendrite Starblaze (Teleport: Moonglade). |

## Skipped

| Quest | Reason |
|---|---|
| Bitter Rivals 310 -> Return to Marleth 311 | The barrel is in Kharanos, Marleth in Brewnall; the route leaves Brewnall for good before the next Kharanos visit, so 311 means an extra round trip west. The reference guide doesn't route them either. |
| Distracting Jarven 308, The Tome of Divinity 1641/1645 | Not in the Forever client. |
| Report to Ironforge 301 -> Powder to Ironband 302 | Ironforge and back from Jern at the very end of the branch, then more dig-site work at 15+. Better on a second Loch Modan visit (the reference guide does it in its 15-16 chapter). |
| Exploring the Alliance 93963 (Skyborne follow-up of Welcome to Azeroth) | Reputation tour of Ironforge and Darnassus (Alliance, Stormwind, Gnomeregan, Darnassus rep); the reference guide accepts it and never finishes it. Off the Westfall route. |
| Heeding the Call 5925 | Exclusive with 5923 (Kal in Dolanaar), which the Teldrassil route already gives. |
| Grove of the Ancients 952 | Fandral (Darnassus) -> Onu at Darkshore's Grove of the Ancients (43.5, 76.3). The route audit can't carry a quest from Teldrassil into the Darkshore alternate. **For the Darkshore helper:** if the Darkshore section ever starts with a Darnassus stop, 952 fits there and is turned in on the Grove loop. |
| Expanding Horizons 97914 -> Making Do 97926 | Thundris Windweaver (Auberdine) -> Baros Alexston (Stormwind) -> back to Thundris, levels 13+. Both ends are Darkshore/Stormwind: **for the Darkshore helper**, it fits a Darkshore section that uses the Stormwind ship. |
| Humble Beginnings 399 | Baros Alexston (Stormwind cathedral) -> his compass in Westfall -> back. **For the Westfall helper** (the objective is in Westfall). |
| Fishin' Time 95065 | 900 XP, but needs a Shiny Bauble and 3 Nightcrawlers from Catherine Leland in the Canals (55.1, 69.8) and a return to Gilbert Gray at the harbor (26.1, 47.1); a back-track on every starter's Stormwind visit. The reference guide routes it for Hunters only. |
| Philmor's Favor / Gatehouse Goods for Skyborne and Humans | Skyborne arrive by portal in the Mage Quarter and Humans through the main gate; the harbor is a detour for both. |
| Manhunt 147 (Warlock) | Handled in the warlock class guides. |
| Camping 101 crafting intros on Zephras (First Aid 97965, Fishing 97967, Alchemy 97963, Blacksmithing 97964, Tailoring 97973, Enchanting 98286, Leatherworking 97969, Engineering 98285) | All cheap Shen'dar turn-ins (Engineering is the Strange Hermit), but a level 6 character rarely has a crafting profession yet. Candidates for more optional steps. |
| Camping 101 gathering intros in Dun Morogh (96046 Mining -> Yarr Hammerstone, 96056 Skinning -> Balthus Stoneflayer in Ironforge, Herbalism) and Teldrassil (97948 Mining -> Auberdine, 97949 Skinning -> Radnaal Maneweaver, Herbalism) | Not in the reference guide's list; same idea as Elwynn's. Add as optional steps if the owner wants parity. |
| Horde quests in the Zephras chapters (Call of Earth, The Gift of Skysight, Shen'dar Village welcome, The Grand Skyseer, Call of Fire, Thrall's quests...) | Horde only. |

## Disagreements and uncertainties

- Croaky is a level 11 elite in the reference guide's notes; QuestieDB doesn't say. Vagash's strength is described from its kiting advice.
- Monty and Nipsy have no coordinates in QuestieDB and the tram has no UiMap in the reference, so those steps have no arrow.
- Whether 2998/2999 lead straight to the Tome (1642/1646) in Forever, with 1641/1645 missing, is unverified.
- What follows Moonglade 94914 for Skyborne druids (Great Bear Spirit?) is unknown; the side guide says to ask Dendrite.
- Philmor's dock position (30.4, 28.9) is from QuestieDB; the Auberdine ship's landing point may differ.

## Check in game

1. Elwynn: with Show optional quests on and Skinning learned, the three Camping 101 pickups at Sam, the Helene turn-in and the pelt objective in Eastvale. Kill Croaky or Elmpaw and check the accept step appears only with the head in bags.
2. Elwynn level 10 stop: Argus's Elmore's Task, Elmore in the Dwarven District; a Human Priest gets Josetta's Divine Grace and Laurena's turn-in, and the Divine Grace side guide shows as done.
3. Dun Morogh: Gremlock's Cooking turn-in, Vagash at the ranch, the rat round-up and Nipsy on the tram.
4. Teldrassil: Blackmoss's heart and the planter; Philmor on the harbor docks and the Gatehouse Goods stairs in Elaine's shop.
5. Zephras: the Shen'dar Camping turn-ins, Syriel in Valanaar.
6. Loch Modan as a Dwarf with the Ironforge flight path: the Honor Students flights. Without it, one Next on Brock's accept should skip the chain. With optional quests on, the tram and South Gate errands.
