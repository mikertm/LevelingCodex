# Horde dungeon guides, levels 30-50 (2026-11-12)

`QuestHordeDungeons3045.lua` replaces the ten Horde placeholders (Alliance facts, entrance only) with full Horde
guides: Gnomeregan, Excavation Site: Wetlands, City of Dalaran, the four Scarlet Monastery wings, Razorfen Downs,
Uldaman and Zul'Farrak. Each keeps its fixed ID, the client's instance ID and English instance name, and is
`verified = false`. Every guide is self-contained for the route audit (its own pickups and lead-in chains; each
turn-in has its accept earlier in the same guide). The leveling band files tag the outdoor pickups with
`H.dungeon(...)` on their own; the pickups per guide are listed below for that check.

## Sources

- Order and grouping: reference guide A (its Horde dungeon chapters for Gnomeregan, the Excavation Site, City of
  Dalaran, Razorfen Downs, Scarlet Monastery, Uldaman and Zul'Farrak, and the dungeon-flavoured Horde leveling
  chapters around them) and reference guide B (its Horde "Dungeon Quests" guides for the same dungeons), read for
  quest IDs, order and grouping only. All step text is our own; no coordinates come from either.
- Quest facts (givers, enders, levels, minimums, races, prerequisites, objectives, item drops, NPC and object
  spawns): QuestieDB Forever at 0f7d8ad via `tools/questfacts.py`; every quest ID is in the client reference's
  `quests.ids`, every `taxi()` name is a client taxi node, and the encounter IDs come from `quests.instances`.
- Forever changes and Horde access: questing.wiki/wow-forever dungeon pages
  ([Gnomeregan quests](https://questing.wiki/wow-forever/dungeons/gnomeregan/quests/),
  [Excavation Site](https://questing.wiki/wow-forever/dungeons/excavation-site-wetlands/),
  [City of Dalaran](https://questing.wiki/wow-forever/dungeons/city-of-dalaran/),
  [Scarlet Monastery quests](https://questing.wiki/wow-forever/dungeons/scarlet-monastery/quests/),
  [Razorfen Downs quests](https://questing.wiki/wow-forever/dungeons/razorfen-downs/quests/),
  [Uldaman quests](https://questing.wiki/wow-forever/dungeons/uldaman/quests/),
  [Zul'Farrak quests](https://questing.wiki/wow-forever/dungeons/zul-farrak/quests/)),
  [warcrafttavern Gnomeregan quests](https://www.warcrafttavern.com/forever/guides/gnomeregan-quests/) and
  [Gnomeregan](https://www.warcrafttavern.com/forever/guides/gnomeregan/) (the Booty Bay transporter, Rig Wars
  before Sovik's errand), [wowhead Forever NPC 13155](https://www.wowhead.com/forever/npc=13155) (the Deathstalker
  Agent: Wetlands, no coordinates), [wowhead Forever quest 96800](https://www.wowhead.com/forever/quest=96800)
  (Past Due, see Left out).
- Boss lists: the Alliance guides' lists and tips (`H.bosses`), copied with the client's encounter IDs added where the
  Alliance list has none (Library, Armory, Cathedral, Razorfen Downs, Uldaman, Zul'Farrak) and the Excavation Site's
  Highland Horror relabelled for the Horde. Copies, so the Alliance lists are unchanged.

## Guides

| ID | Levels | Steps (prepare / inside / after) | Horde quests |
|---|---|---|---|
| `dungeon-gnomeregan` | 30-38 (Alliance 29-38) | 27 (10 / 9 / 8) | 2841, 2842, 2843, 2951, 2904, 2945, 2949, 2950 |
| `dungeon-excavation-site` | 28-33 (Alliance 26-31) | 24 (9 / 5 / 10) | 95697, 95663, 95682, 95664, 98823 |
| `dungeon-city-of-dalaran` | 30-36 (Alliance 28-33) | 38 (24 / 6 / 8) | 96988, 544, 93680, 96986, 545, 92434, 96984, 96987, 97287 |
| `dungeon-scarlet-monastery-graveyard` | 30-38 | 14 (3 / 4 / 7) | 1113 (after 1109), 1051 |
| `dungeon-scarlet-monastery-library` | 33-40 | 16 (6 / 4 / 6) | 1049 (Orc, Tauren, Troll), 1048, 1160 (carried) |
| `dungeon-scarlet-monastery-armory` | 35-42 | 8 (4 / 2 / 2) | 1048 |
| `dungeon-scarlet-monastery-cathedral` | 37-44 | 9 (4 / 3 / 2) | 1048 |
| `dungeon-razorfen-downs` | 37-42 (Alliance 35-42) | 21 (10 / 6 / 5) | 3341, 6521 (after 6522), 6626, 3523, 3525 |
| `dungeon-uldaman` | 40-47 (Alliance 38-47) | 63 (23 / 6 / 34) | 2342, 2258, 2202, 2418, 709, 728, 2283, 2284, 2318, 2338, 2339, 2340, 2341, 2278, 2280, 2440 |
| `dungeon-zul-farrak` | 44-50 (Alliance 42-48) | 65 (42 / 7 / 16) | 2933, 2934, 2935, 2936, 2864, 2865, 2846, 2768, 3042, 2770, 3520, 3527 |

Level changes follow the Horde quests: Gnomeregan's Orgrimmar quests are level 35; the Tarren Mill chain into
Dalaran needs level 30 (Prison Break In, Dalaran Patrols); Bring the End needs 37; the Horde Uldaman quests are
39-47 (necklace chain minimum 37); the Zul'Farrak quests are 44-50 (minimum 40).

## Outdoor pickups (for the band files' `H.dungeon` tags)

| Guide | Quest | Giver | Where |
|---|---|---|---|
| Gnomeregan | 2841 Rig Wars | Nogg | Orgrimmar, Valley of Honor (76.0, 25.4) |
| Gnomeregan | 2842 Chief Engineer Scooty (needs 2841 in the log) | Sovik | Orgrimmar (75.5, 25.4) |
| Gnomeregan | 2843 Gnomer-gooooone! (after 2842) | Scooty | Booty Bay (27.6, 77.5) |
| Excavation Site | 95697 Changing Tastes | Borstan | Orgrimmar (57.2, 53.3) |
| Excavation Site | 95663 Dragonmaw Rumors | Zaruk | Hammerfall, Arathi (74.5, 35.6) |
| Excavation Site | 95682 Open the Maw | Deathstalker Agent | Wetlands, at the upper dig (no spawn data) |
| City of Dalaran | 96988 Source of Power | Doctor Martin Felben | Undercity, Apothecarium (46.6, 74.1) |
| City of Dalaran | 544 Prison Break In, 93680 Key to the City, then 545 and 92434 | Magus Wordeen Voidglare | Tarren Mill (61.6, 20.9) |
| City of Dalaran | 96986 The Grave Knight | Melisara | Tarren Mill (62.6, 20.7) |
| City of Dalaran | 96984 Heart of Disruption (after 92434) | Image of Archmage Modera | Alterac, Lordamere shore (14.3, 59.6) |
| SM Graveyard | 1113 Hearts of Zeal (after 1109) | Master Apothecary Faranell | Undercity (48.8, 69.3) |
| SM Library | 1049 Compendium of the Fallen (Orc, Tauren, Troll) | Sage Truthseeker | Thunder Bluff (34.4, 46.9) |
| SM Library / Armory / Cathedral | 1048 Into The Scarlet Monastery | Varimathras | Undercity, Royal Quarter (56.2, 92.2) |
| Razorfen Downs | 3341 Bring the End (minimum 37) | Andrew Brownell | Undercity (74.1, 33.3) |
| Razorfen Downs | 6521 An Unholy Alliance (after 6522) | Varimathras | Undercity (56.2, 92.2) |
| Razorfen Downs | 6626 A Host of Evil | Myriam Moonsinger | Barrens, below the Downs (49.0, 94.9) |
| Uldaman | 2342 Reclaimed Treasures | Patrick Garrett | Undercity (62.3, 48.6) |
| Uldaman | 2258 Badlands Reagent Run, then 2202 Uldaman Reagent Run | Jarkal Mossmeld | Kargath, Badlands (2.4, 46.1) |
| Uldaman | 2418 Power Stones | Rigglefuzz | Badlands (42.4, 52.9) |
| Uldaman | 709 Solution to Doom | Theldurin the Lost | Badlands (51.4, 76.9) |
| Uldaman | 2283 Necklace Recovery (Shattered Necklace from the dig), then 2284 | Dran Droffers | Orgrimmar (59.5, 36.6) |
| Zul'Farrak | 2933 Venom Bottles | Venom Bottle (object) | Hinterlands (23.5, 58.8) |
| Zul'Farrak | 2934, then 2935 | Apothecary Lydon | Tarren Mill (61.4, 19.1) |
| Zul'Farrak | 2936 The Spider God (after 2935) | Master Gadrin | Sen'jin Village, Durotar (56.0, 74.7) |
| Zul'Farrak | 2864 Tran'rek | Krazek | Booty Bay inn (26.9, 77.2) |
| Zul'Farrak | 2846 Tiara of the Deep | Tabetha | Dustwallow Marsh (46.1, 57.1) |
| Zul'Farrak | 2865 Scarab Shells (after 2864), 2768 Divino-matic Rod, 3042 Troll Temper | Tran'rek, Chief Engineer Bilgewhizzle, Trenton Lighthammer | Gadgetzan (51.6, 26.8 / 52.5, 28.5 / 51.4, 28.8) |
| Zul'Farrak | 2770 Gahz'rilla | Wizzle Brassbolts | Shimmering Flats (78.1, 77.1) |
| Zul'Farrak | 3520 Screecher Spirits, then 3527 | Yeh'kinya | Steamwheedle Port, Tanaris (67.0, 22.4) |

## Gnomeregan

Horde access, checked: Forever keeps the classic Horde way in. Nogg's Rig Wars must be in the log before Sovik offers
Chief Engineer Scooty (warcrafttavern; QuestieDB lists no prerequisite, so the step uses `ifOnQuest = 2841`).
Scooty's Gnomer-gooooone! calibrates the Goblin Transponder; with it, the transporter beside Scooty in Booty Bay
sets you down outside Gnomeregan and works both ways. QuestieDB places the Dun Morogh pad ("Transpolyporter", object
142175) at 21.4, 37.1, among the Caverndeep trogg spawns of the outer tunnels, west of the front lift (24.3, 39.8):
neither source walks through the airfield, the lift or the back door. The back door is the Workshop door, opened
with the key from Electrocutioner 6000 inside; it is an exit, not the Horde way in. So the guide has no `path`; the
pad is the last travel step and the portal is described as a short walk (marked `uncertain`). Two roads were added:
Booty Bay to Dun Morogh by the transporter, and back.

Inside: The Sparklematic 5200! (2951, `startItem` 9308 Grime-Encrusted Object, three silver), A Fine Mess (2904,
Kernobee escort, hand-in to Scooty; its accept is `sticky`, so it shows as "On the way" beside the boss rows instead
of stopping the guide at the door), Grime-Encrusted Ring (2945, Dark Iron Agent drop) to Return of the Ring
(2949, Horde) and Nogg's Ring Redo (2950: Silver Bar, Moss Agate, 30 silver), Rig Wars (Thermaplugg's combination and
safe). Alliance-only quests (Techbot, Gnogaine, Data Rescue, Grand Betrayal, Essential Artificials,
Gyrodrillmatic) stay in the Alliance guide.

## Excavation Site: Wetlands

Borstan's Changing Tastes is 95697 (QuestieDB: Borstan, raptor meat; reference guide B's 97249 is Borstan's level-15
Favorite Food). Zaruk's Dragonmaw Rumors (95663) ends at the Deathstalker Agent, who gives Open the Maw (95682). The
agent has no QuestieDB spawn (wowhead lists only "Wetlands"); both references put him by the portal, so the steps use
the portal spot with an `uncertain` note and a one-point `path` up from the uphill road (53.3, 65.8). Elder Knowledge
(95664) starts from the Horde Titan Relic, item 270866 (QuestieDB's required item for 95664), ends with Bashana
Runetotem; Earthen Echo (98823, given prerequisite 95664) ends with Muln Earthfury on the Skywatcher Plateau
(Mulgore 33.4, 22.6). Highland Hides (Menethil Harbor), Songblade Search (Lakeshire), Lost in the Thicket Things,
Horrors in the Highland and the Lost Relic Carry chain are Alliance or sit in Alliance towns: left out. Two roads
were added: Arathi to the Wetlands over the Thandol Span, and back.

## City of Dalaran

The Tarren Mill chain is the Horde lead-in: Prison Break In (544: four bloodstones, Kegan Darkmar upstairs with Warden
Belamoore) and Key to the City (93680: the Grimy Key from the warden's footlocker), then Dalaran Patrols (545) and
Blood in the Streets (92434) to the Image of Archmage Modera, who gives the Horde Heart of Disruption (96984, back to
Wordeen) and the sewer entrance. Shrewd Negotiations (97287) goes from Wordeen to Archmage Celindra by Modera's image.
Felben's Source of Power (96988), Melisara's The Grave Knight (96986) and Rexxie Copperclutch's Opportunistic
Education (96987, given inside) complete the set.

- QuestieDB has no prerequisites for the Forever quests. 92434 is given {545, 93680} (reference guide A offers it
  only after both), 96984 after 92434 and 97287 after 96984; marked `uncertain` where it matters.
- 96984's hand-in: QuestieDB says Wordeen in Tarren Mill (reference guide A agrees); reference guide B turns it in at
  Modera's image. The guide follows QuestieDB.
- Stone Tokens and Bracers of Binding (556, 557) are Tarren Mill side quests, not lead-ins: left to the band files.
- Places use the Alterac map (Modera 14.3, 59.6 and Celindra 14.2, 60.0 from QuestieDB); `zone` is Alterac.

## Scarlet Monastery

- Graveyard: Vorrel's Revenge (1051) starts inside from Vorrel Sengutz; the ring is Nancy Vishas's drop in Alterac
  (32.3, 32.8), handed to Monika Sengutz in Tarren Mill. Hearts of Zeal (1113) needs Going, Going, Guano! (1109),
  which the Razorfen Kraul guide turns in: its steps drop the `chain` and use `ifDone = 1109`, so they show only once
  1109 is done (the same pattern as the Alliance route's `carried`).
- Library: Compendium of the Fallen (1049) is limited to Orc, Tauren and Troll (QuestieDB requiredRaces 162;
  `H.limit`). Parqual Fintallas's Test of Lore (1160) ends a long Thousand Needles chain (1149-1159), so its book and
  hand-in are carried steps (optional, shown only while 1160 is in the log); the text names the follow-ups (6628,
  1394). The Scarlet Key from Doan's strongbox is a note.
- Into The Scarlet Monastery (1048) spans three wings. The Library, Armory and Cathedral guides each accept it, do
  their own leader as an `objectiveIndex` part and end with its hand-in, which stays blocked until all four leaders
  are dead, so the wings can be run in any order.
- Encounter IDs: SM is one instance (189); each wing's list warns about the other wings' encounters. Mograine and
  Whitemane both carry encounter 450 (the client lists Whitemane's encounter only).

## Razorfen Downs

Andrew Brownell's Bring the End (3341, minimum 37), Varimathras's An Unholy Alliance (6521; needs Charlga's scroll
6522 from the Razorfen Kraul guide: `ifDone = 6522` like Hearts of Zeal), Myriam Moonsinger's A Host of Evil (6626,
outdoor counts at 47.8, 92.3 and 47.1, 88.8) and Belnistrasz's Scourge of the Downs / Extinguishing the Idol (3523,
3525; brazier hand-in). Ambassador Malcin's four spawns cluster at 47.7, 92.3. Bring the Light is Alliance.

## Uldaman

Two runs, as the necklace chain demands. Prepare: Patrick Garrett (2342), Jarkal's Badlands Reagent Run (2258:
rock elementals 21.7, 45.7; buzzards 15.5, 62.1; coyotes 12.8, 65.6 as `objectiveIndex` parts) to Uldaman Reagent
Run (2202), Rigglefuzz (2418), Theldurin (709); at the dig, a `collect` step for the Shattered Necklace (item 7666,
Shadowforge drops at the dig and in the outer caves; `unlessDone = 2283` so it stays done after the hand-in), the
Tablet of Ryun'eh and the Garrett Family Chest in the outer caves (QuestieDB places both chests on the Loch Modan
map: 38.6, 93.2 and 33.9, 93.0, so the steps carry no place), then Dran Droffers in Orgrimmar (2283 accepted and
handed in together, 2284). Run 1: the Remains of a Paladin (2284 to 2318), caps and power stones. After: Jarkal
(2318, 2338, 2339), run 2 for the three gems (parts 3, 1, 2) and Archaedas's power source (part 4), the Platinum
Discs (2278 to 2280), then Rigglefuzz, Theldurin (709 to 728), Jarkal (2202, 2339 to 2340), Dran (2340 to 2341),
Thunder Bluff (2280 to Sage Truthseeker, 2440 to Bena Winterhoof), the Undercity (2342, 728 to Keeper Bel'dugur) and
Jarkal (2341). The second visit is a `goto` to the dig, not a second `dungeon` step (a dungeon step is only done
while you are inside).

- Why the gems sit in the after phase: their quest (2339) is accepted from Jarkal between the runs, and the route
  audit needs the accept before its objectives. On the second entry the guide opens at the inside phase, where the
  boss rows come before the after-phase gem parts, so the inside phase ends with a "Second run" note gated on
  `ifOnQuest = 2339` that names the urn, the cache, Grimlok, Archaedas and the Discs. The "First run" note is
  `unlessDone = 2318`, so it no longer shows on the second entry.

- The Uldum chain from Sage Truthseeker (2965 onward, level 50, minimum 45) and Bel'dugur's follow-up (736) are left
  for the 40-50 band; the 2440 hand-in text mentions the Uldum chain.
- Badlands Reagent Run II (2203, minimum 40) is a Badlands quest, not Uldaman: left to the band file.
- No `path` into the outer caves: the portal's position inside the caves is not in any source we can use, and a wrong
  path is worse than none (open question below).

## Zul'Farrak

Prepare follows the Horde Spider God chain: the Venom Bottles (2933, Hinterlands object) to Apothecary Lydon,
Undamaged Venom Sac (2934, Witherbark Broodguards at Shadra'Alor 32.7, 72.9), Consult Master Gadrin (2935) and The
Spider God (2936, read the Tablet of Theka inside). Then Krazek's Tran'rek referral (2864, required for Scarab Shells
2865 per QuestieDB), Tabetha (2846), Gadgetzan (2865, 2768, 3042), Wizzle Brassbolts (2770) and Yeh'kinya's Screecher
Spirits (3520: screecher clusters as `points` with `nearest`) to The Prophecy of Mosh'aru (3527). The Mallet of
Zul'Farrak (Qiaga the Keeper at 48.6, 68.2, then the Jintha'Alor altar) is an optional note: one per group, level 50
elites. After: Gadgetzan, Steamwheedle Port, the Shimmering Flats, Tabetha, Gadrin. Summoning Shadra (2937, level 55)
and the Ancient Egg (4787) are mentioned, not routed. Alliance-only: Nekrum's Medallion chain (2988-2992).

## Left out

- Past Due (96800, Magus Olvek in Alterac, book from Arcanist Doan): no published hand-in, Horde access unconfirmed
  and the giver is off every Horde path to the monastery. The Alliance Library guide keeps it as `uncertain`.
- Rituals of Power (1951) and Power in Uldaman (1956): mage class quests for the class files.
- Stone Tokens / Bracers of Binding (556, 557), Badlands Reagent Run II (2203), the Uldum chain (2965-2968),
  Summoning Shadra (2937): outdoor follow-ups for the band files.

## Route audit

`python tools/questroute.py audit` passes. Remaining warnings on these guides, all expected:
- Encounters not in the boss list: the SM wings (other wings' encounters), City of Dalaran (Mana Wraith, already on
  the Alliance list) and Zul'Farrak (Shadowpriest Sezz'ziz, who shares the pyramid row with Nekrum).
- Quest more than 5 levels above the start: Into The Scarlet Monastery (42, minimum 33) in the Library and Armory
  guides, the Platinum Discs (47, minimum 40) in Uldaman, Gahz'rilla (50, minimum 40) in Zul'Farrak. Each can be
  taken at its minimum; the guides start at the level the rest of their quests suit.

`python tests/run.py -k full/quests` passes. The full harness fails one run, WARRIOR/full/blocked-report (a blocked
call's `where` comes back nil); it fails the same way with the scaffold's placeholder file, so it is not caused by
these guides (likely the long worktree path in `debugstack`).

## Check in game

- Gnomeregan: where the transporter pad sets you down and how far the portal is; whether Sovik needs Rig Wars in the
  log; whether Scooty hands out a new transponder.
- Excavation Site: where the Deathstalker Agent stands; whether Open the Maw needs Dragonmaw Rumors; the Horde relic
  item (270866) and the way up to Muln Earthfury on the Skywatcher Plateau.
- City of Dalaran: whether Blood in the Streets needs Key to the City too; who needs the sewer key; the footlocker
  spot; where Archmage Celindra takes Shrewd Negotiations.
- Scarlet Monastery: the entrance building (82.7, 32.9); that Hearts of Zeal and An Unholy Alliance stay hidden until
  their Razorfen Kraul prerequisites are done; the way to Nancy Vishas's house.
- Uldaman: where the Remains of a Paladin lie; that the necklace collect step stays done after the hand-in; the
  outer-cave chest spots.
- Zul'Farrak: the Venom Bottles spot and the Witherbark Broodguards; that Krazek's referral is needed for Scarab
  Shells; the screecher spawns.
