# Dwarf and Gnome 1-12 quest route audit

Client reference: WoW Forever 1.60.1.70862 (`tools/reference/forever.json`). Every quest ID in the two sections is in QuestV2, and both flight names (`Ironforge, Dun Morogh`, `Stormwind, Elwynn`) match the reference. Givers, turn-ins, levels, prerequisites, race masks and mob or object spawn clusters come from `tools/questfacts.py` (QuestieDB Forever data and player traces). The new Forever quests have no item or object data in that cache, so their objective points come from the Bind on Forever quest pages. Guide order comes from [Bind on Forever Dun Morogh](https://bindonforever.com/zones/dun-morogh) and [ForG Dun Morogh](https://forg.gg/en/forever/zones/dun-morogh). [Judgement's Classic route](https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/) has no Dun Morogh section: non-Humans join it in Loch Modan, so it gave no order to compare. The step text is original.

Gnomes start in Coldridge Valley with the Dwarves. Tidegear Coast is a neutral flight point in the north-west, not a start area. Both sections use `start = { "DWARF", "GNOME" }`.

## Coldridge Valley (1-6)

Dwarven Outfitters (179) unlocks A New Threat, the mail and the class letters. The class letters go to the trainers inside Anvilmar, so letters and the level 2 training come next. The trogg kills run west to Talin's camp, where the Burly Troggs gather. The route does the boars and Talin's mail, then goes to Grelin. Nori's Scalding Mornbrew (min level 4) has a five-minute timer and leads back to Anvilmar. That trip also covers Balir's turn-in, Felix, Grund and the level 4 training. One more southern trip covers the whelps, the Mug return, Felix's three items and Grik'nir's cave. The section ends with Felix and Grund's camp north-west of Anvilmar, then Thalos and Hands at the tunnel.

Class letters: Dwarf runes 3106 Warrior, 3107 Paladin, 3108 Hunter, 3109 Rogue, 3110 Priest and 98581 Shaman (new). Gnome memoranda 3112 Warrior, 3113 Rogue, 3114 Mage, 3115 Warlock and 98574 Priest (new). Each is filtered by class and by race (requiredRaces 4 = Dwarf, 64 = Gnome; Bind on Forever gives the same races for the two new letters).

Forever additions: Archaic Rune (98581), Hallowed Memorandum (98574), Grund and Gozwin (97277) and The Adventurer (96628).

## Dun Morogh (6-12)

The route has three loops out of Kharanos, the order Bind on Forever uses.
1. South: Gretchen, the Rumbleshot ammo crate (in the same place), boars and bears, Hegnar, then the turn-ins and the malt purchase in Kharanos.
2. West: Brewnall, Frostmane Hold, the Leper Gnomes, the northern hills and the Shimmerweed camp. The loop comes back through the Grizzled Den for Stonegear's manes, Flintfire's crates, Cornelius and Frosthowl, then returns to Brewnall for its turn-ins.
3. East: Misty Pine Refuge (Father Gavin's chain), Amberstill, Farsen, Gol'Bolar Quarry and Helm's Bed Lake, the North Gate and Mangeclaw, then the turn-ins on the way back.

Hearth to Kharanos to train for level 12, then go to Ironforge for The Reports and the flight path. From there the route takes the tram to Stormwind, learns the Stormwind flight path and walks to the Furlbrow farm, where the shared Westfall section starts.

Forever additions: The Great Outdoors (96608), Camping 101: Cooking (96629), Flintfire's Shipment (98321), Secure the Mountain (98322, 98319, 98323), Frosthowl (98326), Dawn in the Mountains (99158), Finding Warmth (99159), Rime's Wrath (99160, 99161), Treacherous Cold (99162), Never Saddle on Quality (95212), Stolen Blasting Powder (95214, plus the item-started 95213), A Visitor to Dun Morogh (96408), Farsen's Watch (96392) and Nip 'Em in the Bud (96390).

## Left out

- Bitter Rivals (310) / Return to Marleth (311): its helpers Guarded Thunderbrew Barrel (403) and Distracting Jarven (308) are not in the Forever client, so the barrel swap may not work.
- Stout to Kadrell (414), Search for Incendicite, and the other Loch Modan follow-ups: this route goes to Westfall instead.
- The Quarry's Smith (95217): it needs 12 Copper Bars (Mining or the auction house).
- Tundra MacGrann's Stolen Stash (312): the locker is in Old Icebeard's (level 11) cave.
- Protecting the Herd (314): ForG marks Vagash as elite.
- Rejold's New Brew (415): it only leads to Shimmer Stout, which Rejold offers directly after The Perfect Stout.
- Class quests (Call of Earth/Fire, Beginnings, Tome of Divinity, Taming the Beast, Speak with Bink, Road to Salvation, Confounding Flash and the priest quests), Old Ironforge Incursion (96393, level 16), Underground Map and Data Hoarders (Gnomeregan).

## Uncertain, check in game

- The bind name for the Kharanos inn is set to `Thunderbrew Distillery`. Check what GetBindLocation returns. If it says "Kharanos", change `kharanosHearth`.
- Bind on Forever marks Felix (3361) and the Mornbrew pair (3364, 3365) as Paladin, Hunter, Shaman, Mage and Warlock only. QuestieDB has no class mask. The route follows Bind on Forever: check them on a Warrior or Rogue.
- Grund Drokda is "UNUSED" in the quest data. His position (28.7, 67.5) and Gozwin's camp (27.3, 62.9) come from Bind on Forever.
- Ingrid Dunwald (Kharanos, 47.54, 51.96) is used as the Shaman trainer, and Teo Hammerstorm as the Coldridge one. Confirm both.
- Prerequisites not in the data: The Adventurer (none set), The Great Outdoors (after 96628), Finding Warmth (no link to Dawn in the Mountains), Farsen's Watch (no link to A Visitor to Dun Morogh). Record the actual gates.
- Stolen Blasting Powder: Bind on Forever lists 95213 (the rare Empty Powder Keg from Rockjaw Ambushers) before 95214. QuestieDB lists no prerequisite. Check whether Thesten offers 95214 without the keg.
- Check the objective points for the Forever quests: firewood, the three rifles, Avala, Cornelius, Frosthowl at the west end of the den, the Pristine Leopard Pelts and the Dark Iron Spies.
- Record the level at Kharanos (expected 6), after the west loop (10) and at Ironforge. The level 11 grind step is a placeholder.
