# Night Elf 1-12 quest route audit (Shadowglen and Teldrassil)

Draft snippet: `te` table (one main-chunk local), sections `shadowglen` (1-6) and `teldrassil` (6-12), `start = "NIGHTELF"`, hearth bind `Dolanaar`. Facts come from `tools/questfacts.py` (QuestieDB Forever base, traces and fixes) and the committed client reference; every quest ID is in `forever.json` `quests.ids`, and the flight names match `quests.flights`. The combined file (current QuestData.lua plus this snippet, the two sections, the `NIGHTELF` start and three extents) passes `questroute.audit` with no errors or warnings, including the 20-quest log cap for every class. The route leaves no quest in the log when it reaches Westfall.

## Sources

- Route order: [Bind on Forever Teldrassil](https://bindonforever.com/zones/teldrassil) and [ForG Teldrassil](https://forg.gg/en/forever/zones/teldrassil). [Judgement's Classic route](https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/) has no Night Elf start, so it only supports leaving at 11-12.
- Quest pages: [Nature's Call](https://bindonforever.com/quest/97977) (the totems are ground objects at 54.5, 43.8), [The Goddess Provides](https://bindonforever.com/quest/97979) (Priest only), [The Great Tree Provides](https://bindonforever.com/quest/99050) (Lasher Sproutlings drop the fronds; the vial comes from Narret and the water from the innkeeper), and [Eyes of the Sentinels](https://bindonforever.com/quest/98067) (the Lunar Pendant is used at four places).
- QuestieDB Forever fixes add the following links: 97977 after 458, 97979 after 456, 96630 after 921 (a breadcrumb for 96606), 98403 after 932, and 99046 as a breadcrumb for 99047. The Byancie chain runs 99047 -> 99050 -> 99073. The Oracle Glade chain runs 937 -> 98392 -> 98398 -> 940, where Teldrassil (940) now starts from the Oracle Tree Bark. Crown of the Earth continues 935 -> 98046 (Fandral -> Lariia) -> 98065 (-> Tyrande). 98391 is a breadcrumb for 2519.

## Why this order

- Shadowglen: Melithar and Tarindrella come before Ilthalaine's first kills so that grells and totems share the same ground. Next come the sigils and training, then a run north that covers 457, Iverron and the cave venom. A second cave visit does the egg and Githyiss, after the timed antidote. The Crystal Phial goes in last, and the journal (which needs 921) is picked up on the way out.
- Dolanaar has four loops. Lake Al'Ameth comes first (Denalan). Starbreeze is second (Zenn's parts, pelts, the dresser and the Jade Phial). Fel Rock and the Gnarlpine camp come third, with fel cones on the way back. Ban'ethil is fourth: Oben's two quests, the relics, Lynessa's escort, the Tourmaline Phial and the Glowing Fruit. After that the route hearths back.
- At 10, the class quests that lead to Darnassus are picked up in Dolanaar and handed in on the first city visit. Hunters do the three taming quests from Dazalar before leaving. The Oracle Glade comes next: Eralya, the harpies, Mist, the three new harpy leaders, the Oracle Tree, the Amethyst Phial, the frond, Lady Sathrah and the tumors. The city turn-ins follow, then a hearth for Byancie, Denalan, Oakenscowl and the lashers. The last city visit covers the Crown of the Earth ending, Eyes of the Sentinels and Nessa's chain.

## Forever additions included

The route includes Nature's Call 97977, The Goddess Provides 97979 (Priest), Fang of Githyiss 97236, The Adventurer 96630, The Great Outdoors 96606, Camping 101: Cooking 96634, Soft Saber Pelts 87288, The Sisterhood of Elune 98391, The Lost Runner 99046, Not Dead Yet 99047, The Great Tree Provides 99050 and Easing Suffering 99073. It also has Escaping Ban'ethil 99053, Twisted Hatred 98403, Darkness in the Glade 98392, The Oracle Tree 98398, Crown of the Earth 98046 and 98065, and Eyes of the Sentinels 98067.

## Getting to Stormwind (finding)

Patch 1.60.1 (2026-11-04) added a ship between Auberdine and Stormwind Harbor. [Warcraft Wiki: Idrieth Mossgrove](https://warcraft.wiki.gg/wiki/Idrieth_Mossgrove) describes a Forever-only Night Elf at Stormwind Harbor who says the dock connects Stormwind to Auberdine and that the boat comes often. QuestieDB Forever traces place her at Stormwind City 22.7-29.6, 46.7-55.7, with the main cluster at 26.2, 53.2. New harbor NPCs (Stormwind Harbor Guard, Dockhand, Cannoneer) also exist in the traces. Forever's Stormwind map is the larger one that includes the harbor: the moonwell has moved from Classic's 20.4, 52.9 to 35.5, 65.4.

The chosen route is the Darnassus portal to Rut'theran, then the Rut'theran - Auberdine boat (a taxi node in the client), then the new ship to Stormwind Harbor. After that the player learns Dungar's flight path and walks to Farmer Furlbrow. Flight to Auberdine (6342) is handed in to Laird along the way, and the player learns the Auberdine and Rut'theran flight paths. Some details are still unknown:

- Which Auberdine pier the ship uses. The route points at Thamarian, the dock guide, at 32.67, 42.11.
- Whether the client lists the Stormwind ship as a transport node. It has no `Transport, ...` entry in `TaxiNodes`, so the boat step carries only a display `name`.
- The Rut'theran pier coordinates. The boat step points at Nessa Shadowsong on the pier.

## Left out, and why

- Ursal the Mauler 486 (level 12, far south-west after the relics) and The Moss-twined Heart 927 / Planting the Heart 941 (Blackmoss is level 13, from a random drop) are left out.
- Recipe of the Kaldorei 4161 is left out: Forever data shows no Teldrassil source for the spider legs. Elixirs for the Bladeleafs 1581 needs alchemy.
- Grove of the Ancients 952 and Return to Nessa 6343 are left out because they would stay in the log after the route leaves for Westfall. The second step of each class chain is also left out: Vorlus Vilehoof 1683, Destiny Calls 2242, Moonglade 5921 and Stars of Elune 5627.
- Divine Grace 94775 is for Human Priests. Bounty: Gnarlpine Furbolg 490 is not in the Forever records.

## Check in game

- Confirm the Forever-only NE classes. Trainers are listed only for Warrior, Hunter, Rogue, Priest and Druid. If Forever allows other NE classes, add them.
- Check that 97977's totems, 97236's fang drop, and 97979's Elune's Light all work as written.
- Check that Teldrassil 940 is offered by the Oracle Tree Bark after 98398.
- Check that 98391 and 2519 are open to every class.
- Check whether Eyes of the Sentinels needs an earlier quest.
- Check the place where the spinnerets are used for 2520 (a guess, 39.0, 85.0 in the temple).
- Find the Darnassus portal (no coordinates yet), the Rut'theran pier, the Auberdine ship pier and how long the crossing takes, and Idrieth's spot in the harbor.
- Check the XP at Darnassus and at Furlbrow. A level 12 grind check comes before the last city visit.
- Check the escorts (Mist, Lynessa) and Oakenscowl and Lady Sathrah solo at 11-12.
