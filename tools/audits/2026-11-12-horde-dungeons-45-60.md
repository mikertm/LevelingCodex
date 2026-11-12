# Horde dungeon guides, levels 46-60 (2026-11-12)

`QuestHordeDungeons4560.lua` replaces the ten Horde placeholders (Alliance facts, entrance only) with full Horde
guides, and adds five Horde attunement and key guides (`category = "special"`). Every guide is self-contained for the
route audit (each turn-in has its accept earlier in the same guide, prerequisites come first), keeps its fixed ID, and
stays `verified = false`.

## Sources

- **Order and grouping**: reference guide A's Horde dungeon chapters (Maraudon to Dire Maul North, plus its 49-50
  Maraudon and 56-57 Blackrock Depths leveling chapters) and reference guide B's Horde dungeon walk-throughs and
  "Dungeon Quests" guides, read for quest IDs and order only. All step text and new boss tips are written here; no
  coordinates come from either guide.
- **Quest facts** (names, levels, minimum levels, Horde/Alliance race masks, prerequisites, givers, enders, provided
  items, objective order): the QuestieDB Forever cache through `tools/questfacts.py`. Every quest ID is in the client
  quest list (`tools/reference/forever.json`, checked by `tools/questroute.py audit`).
- **Places**: QuestieDB Forever NPC and object spawns, mob spawn clusters for kill and loot objectives (bloodpetals,
  War Reavers, broodlings, Chillwind chimaeras, Shadowshard golems, Andorhal skeletons and the four tower markers,
  the skull drakes), flight masters at the client's taxi nodes. Dungeon doors that QuestieDB can't place are the
  Alliance guides' points (Maraudon cave, Sunken Temple, Dire Maul, Caer Darrow), flagged where uncertain.
- **Encounters**: `quests.instances` in the client reference (DungeonEncounter IDs per instance).
- **Forever changes**: [wowhead Forever quest 5214](https://www.wowhead.com/forever/quest=5214) (the quest is
  "The Great Ezra Grimm" and the boss Ezra Grimm, not Fras Siabi; the client's Stratholme encounter list agrees).
- Section `sources` list wowhead Forever zone pages and questing.wiki/wow-forever dungeon quest pages.

## Dungeon guides

| Guide | Levels | Steps (prepare / inside / after) | Horde quests |
|---|---|---|---|
| `dungeon-maraudon` | 46-52 (was 44-52) | 36 (15 / 11 / 10) | 7068 Uthel'nay (Orgrimmar), 7029 Vark Battlescar and 7064 Selendra (Shadowprey), 7067 Centaur Pariah, 7028 Willow, 7044 Cavindra -> 7046, 7066 Zaetar's Spirit -> Remulos (Moonglade) |
| `dungeon-sunken-temple` | 50-56 (was 47-54) | 53 (36 / 8 / 9) | 3380 Uzer'i (Camp Mojache) -> 3444 Marvon -> 3446, 3447; 4145 Larion -> 4147 -> 4146 Liv Rizzlefix (Ratchet); 1424 Fel'zerul (Stonard) -> 1429 -> 1444 + 1446 Atal'ai Exile -> 1445; 3373 Essence of Eranikus; 3528 carried |
| `dungeon-blackrock-depths` | 52-60 (was 50-58) | 69 (26 / 16 / 27) | 4133 Zinge (Undercity) -> 4134 + 7201 Vivian Lagrave; 3906 -> 3907 Thunderheart; 4081 -> 4082 posters; 4061 -> 4062 -> 4063 Theodora/Lotwil; 3981 Galamav -> 3982 -> 4001 -> 4002 -> 4003 -> 4004 Thrall; 4123 Maxwort; 3801 -> 3802 Franclorn; 4024 and 4136 carried |
| `dungeon-lower-blackrock-spire` | 55-60 | 34 (9 / 14 / 11) | 4903 Goretooth -> 4941 Thrall; 4981 Lexlort -> 4982 -> 4983; 4724 Galamav; 4862, 4729 Kibler; 4866 Ragged John; 4867 Warosh |
| `dungeon-upper-blackrock-spire` | 58-60 | 57 (34 / 7 / 16) | 4769 Zinge -> 4768 Vivian; 4903 -> 4941 -> 4974 Thrall; 4726 Tinkee -> 4808 -> 4809 -> 4810 Felnok (Everlook) -> 4734 -> 4735; 7761 (item); 5160 Awbee -> Haleh; 5047 Finkle -> Malyfous; 6821 carried |
| `dungeon-dire-maul-east` | 55-60 | 22 (14 / 3 / 5) | 7492 Gorlach (Orgrimmar) -> 7489 Talo Thornhoof; 7441 Azj'Tordin; 5527 -> 5526 Rabine Saturna (Moonglade, Silithus reliquary) |
| `dungeon-dire-maul-west` | 57-60 | 11 (4 / 6 / 1) | 7461 -> 7877 Shen'dralar Ancient (inside) |
| `dungeon-dire-maul-north` | 57-60 | 20 (6 / 11 / 3) | 7481 Sage Korolusk (Camp Mojache); 5525, 5518 Knot Thimblejack; 5528 Kreeg; 7703 Kromcrush |
| `dungeon-scholomance` | 57-60 | 47 (9 / 10 / 28) | 5529 Betina; 5341 Alexi Barov (the Bulwark); 5382 -> 5515 -> 5384 Eva Sarkhoff; 5461 -> 5466 Ras Frostwhisper chain (Stromgarde, Light's Hope, Stratholme); 4771 carried |
| `dungeon-stratholme` | 57-60 | 41 (10 / 8 / 23) | 5281 Alen -> 5282 Egan; 5251 -> 5262 (item) -> 5263 -> 5264 -> 5265 Zverenhoff/Tyrosus; 5212 -> 5213 Betina; 5214 Smokey; 5243 Leonid; 6163 and 5848 carried |

Level ranges: Maraudon starts at 46 so the level 51 quests are within five levels of the start; the Temple's Horde
quests are 50-53 and the guide follows the reference guides' 50+ range; Blackrock Depths keeps 52-60 (its 4063,
4003 and 4004 are for later runs and stay as audit warnings).

## Special guides

| Guide | Levels | Steps | Chain |
|---|---|---|---|
| `attunement-onyxia-horde` | 55-60 | 65 | 4903 -> 4941 -> 4974 (Lower and Upper Spire runs) -> 6566 -> 6567 Rexxar -> 6568 Myranda -> 6569 (dragonspawn eyes) -> 6570 Emberstrife -> 6582/6583/6584 (Scryer, Somnus, Chronalis) -> 6585 (Axtroz, Grim Batol) -> 6601 Rexxar -> 6602 (Drakkisath's blood) |
| `ubrs-seal-horde` | 57-60 | 12 | 4742 -> 4743 Vaelan, Emberstrife from Brackenwall Village |
| `molten-core-attunement-horde` | 55-60 | 5 | 7848 Lothos Riftwaker |
| `shadowforge-key-horde` | 52-60 | 7 | 3801 -> 3802 Franclorn Forgewright |
| `scholomance-key-horde` | 55-60 | 35 | 5094 Balthazad (Undercity) -> 5096 -> 5098 (four Andorhal towers, one waypoint each) -> 838 -> 964 Dithers -> 5514 Krinkle (Gadgetzan) -> 5802 (Fire Plume Ridge) -> 5804 (Araj) -> 5511 Derrington |

The dungeon guides link these (`links`, and `guide` on the Seal, Skeleton Key and For The Horde! steps).

## Decisions

- **Boss lists** reuse the Alliance lists (`B.horde.bosses`) through a local `bosses()` that copies each row and adds the
  client's encounter ID, so ENCOUNTER_END marks rows whose names differ from the game's (Kirtonos, Ras Frostwhisper,
  combined rows such as "Halycon and Gizrul the Slavener", mapped to the boss that dies last). Rows added for encounters
  the Alliance lists leave out: Marduk Blackpool and Vectus (Scholomance), Ezra Grimm and Magistrate Barthilas
  (Stratholme). Combined rows leave one encounter each unlisted (audit warnings).
- **Carried quests**: a quest whose start is a long outdoor chain from another guide keeps only its objective and
  hand-in here, shown while it is in your log (`optional`; the audit skips them when the guide never picks the quest
  up): 3528 The God Hakkar (needs Zul'Farrak's 3527 and 4787), 4024 A Taste of Flame (Kalaran's Searing Gorge chain to
  3481, then Cyrus's 4022), 4136 Ribbly Screwspigot (Yorba's 4324 in Tanaris), 6821 Eye of the Emberseer (Duke
  Hydraxis's 6804 and 6805), 4771 Dawn's Gambit (Tinkee's eggs to Leonid and Betina, 5522 -> 5531), 6163 Ramstein
  (Nathanos's chain to 6135), 5848 Of Love and Family (Tirion's chain). The Nathanos hand-in's ride is a `goto` with
  `ifOnQuest = 6163`.
- **Quest records**: `B.q(3444)` sets The Stone Circle's prerequisite to the Horde's 3380 (the Alliance record has
  3445; steps built earlier keep theirs). `B.q(5214)` renames it to the Forever name, The Great Ezra Grimm. Everything
  else uses `H.need` (fills gaps only). Prerequisites with a choice in QuestieDB (3444, 5096) use the Horde one.
- **Upper Spire needs Warlord's Command**: For The Horde! (4974) needs 4941, which needs 4903 from a Lower Spire run,
  so the Upper Spire guide and the Onyxia guide repeat 4903 -> 4941 (done quests show as done).
- **Elven Legends** (7481) is in the North guide (Kariel Winthalus in the Gordok library, as reference guide B has
  it; reference guide A completes it in the West wing): flagged uncertain.
- **Blackrock Mountain**: QuestieDB has no positions inside the mountain. The Alliance guides' gate on the Searing
  Gorge map (34.8, 85.3) is converted to the Burning Steppes map through the client's world coordinates (28.4, 17.3),
  since the Horde arrives from Flame Crest. In-mountain steps (Franclorn, Lothos, Pyron, Vaelan, the Quartermaster)
  have no waypoint.
- **Eastern Plaguelands map frame**: Forever's map of the Eastern Plaguelands is framed differently from classic's
  (QuestieDB Forever vs classic for the same NPCs: Egan 11.4, 26.6 vs 14.4, 33.7; Betina 71.7, 49.9 vs 81.5, 59.7;
  Tirion 5.2, 35.6 vs 7.6, 43.7). A fit over four NPCs gives x' = 0.899 x - 1.58, y' = 0.898 y - 3.65. The other maps
  used here match classic. The Stratholme gate (Alliance guide: 31.2, 15.6, a classic-map point) becomes 26.5, 10.4.
- **Left out**: 4201 The Love Potion (outdoor gathering in Azshara and Un'Goro), 5065/4788 the Mosh'aru tablets
  (need 3528), 5161/5162/5164 Haleh's follow-ups, 5522/5531 the egg delivery, 5582 Healthy Dragon Scale and 5122 The
  Medallion of Faith (not in Forever's quest list; 5125 needs 5122), 7429 Free Knot! (not in Forever's list; 5525 is
  used), the Alliance-only quests, and the class quests in these dungeons (Temple: 8410/8412/8413, 8417/8423-8425,
  8233-8236, 8250-8253, 8254-8257, 8151/8153/8231/8232, 8419/8421/8422, 9051-9053; Dire Maul: 7463; Scholomance:
  8258), which belong to the class files.
- **Roads added** (`H.road`): Undercity and Tirisfal to the Western Plaguelands past the Bulwark; Arathi and the
  Wetlands across Thandol Span (the Alliance's points).

## Outdoor pickups for the leveling bands

Tag these with `H.dungeon(...)` where the route passes the giver (quest, giver, place):

- maraudon: 7068 Uthel'nay (Orgrimmar), 7029 Vark Battlescar and 7064 Selendra (Shadowprey Village), 7067 Centaur
  Pariah (southern Desolace), 7028 Willow (central Desolace), 7044 Cavindra (Maraudon's outer cave).
- sunken-temple: 3380 Witch Doctor Uzer'i (Camp Mojache), 3444/3446/3447 Marvon Rivetseeker (Tanaris), 4145/4147
  Larion (Marshal's Refuge), 4146 Liv Rizzlefix (Ratchet), 1424/1429/1445 Fel'zerul (Stonard), 1444/1446 Atal'ai
  Exile (Hinterlands).
- blackrock-depths: 4133 Apothecary Zinge (Undercity), 4134/7201 Shadowmage Vivian Lagrave, 3906/3907 Thunderheart,
  4081/4082 Kargath's posters, 4061/4062 Hierophant Theodora Mulvadania, 3981 Galamav the Marksman (all Kargath),
  4063 Lotwil Veriatus (Badlands), 4123 Maxwort Uberglint (Flame Crest).
- lower-blackrock-spire: 4903 Warlord Goretooth, 4981 Lexlort, 4724 Galamav (Kargath); 4862/4729 Kibler, 4866 Ragged
  John (Flame Crest).
- upper-blackrock-spire: 4769 Apothecary Zinge (Undercity), 4768 Vivian Lagrave (Kargath), 4726/4734 Tinkee Steamboil
  (Flame Crest), 4809/4810 Felnok Steelspring (Everlook), 4974 Thrall (Orgrimmar).
- dire-maul-east: 7492 Warcaller Gorlach (Orgrimmar), 7489 Talo Thornhoof (Camp Mojache), 7441 Azj'Tordin (Lariss
  Pavilion), 5527/5526 Rabine Saturna (Nighthaven).
- dire-maul-north: 7481 Sage Korolusk (Camp Mojache).
- scholomance: 5529 Betina Bigglezink (Light's Hope), 5341 Alexi Barov (the Bulwark), 5382 Eva Sarkhoff (Caer Darrow).
- stratholme: 5281 Caretaker Alen, 5251 Duke Nicholas Zverenhoff, 5212 Betina Bigglezink, 5214 Smokey LaRue, 5243
  Leonid Barthalomew (Light's Hope), 5282 Egan (west of Stratholme).

## Check in game

- Maraudon: which khan spirits are outside the portals; that the orange crystal pool is outside the orange portal.
- Sunken Temple: the statue order and where the Idol of Hakkar appears; The God Hakkar event order.
- Blackrock Mountain: the arrow from Flame Crest to the mountain gate; the Depths and Spire portal spots; Franclorn's
  ghost-only rule; how the Vault opens; where the Scarshield Quartermaster stands.
- Warlord Goretooth: whether he must stand at the top of Kargath's tower to offer Warlord's Command.
- Upper Spire: where the Darkstone Tablet lies, where Awbee waits, whether Finkle needs a skinner.
- Dire Maul: the three wing doors (classic-map points); where Kariel Winthalus lies; where the Gauntlet of Gordok
  Might is.
- Stratholme: the converted gate spot and Egan's spot (QuestieDB puts him well south-west of the gate).
- Onyxia chain: Rexxar's patrol, Grim Batol's guards around Axtroz.
- Seal of Ascension: Emberstrife's guards and the seal and orb order.
