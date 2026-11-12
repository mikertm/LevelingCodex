# Horde Riverglades, Shen'dralas and Krol'dok Stronghold (2026-11-12)

File `QuestHordeRiverglades.lua`: four Horde alternate routes (three in the Riverglades, one in
Shen'dralas), the barge and Valley of Bones roads, and the Horde Krol'dok Stronghold guide, which
replaces the placeholder built from the Alliance guide.

## Sources

- **Neither reference guide has Horde Riverglades or Shen'dralas chapters** (reference guide A has only
  an Alliance Riverglades group; reference guide B's Horde quest cache has no Riverglades entry). Nothing
  here comes from them.
- **QuestieDB** (the cached Forever data used by `tools/questfacts.py`, and the newest Forever data
  commit on GitHub, 2026-10-26) has none of these quests.
- **Givers, enders and their positions**: bindonforever.com quest pages,
  `https://bindonforever.com/quest/<id>` for every quest ID below. The site states its givers,
  positions and chains are QuestieDB-format data for client build 1.60.1.70888 (Nov 10), not yet
  checked in game.
- **Creature positions**: bindonforever.com NPC pages, `https://bindonforever.com/npc/<id>`, reached
  from [the Riverglades NPC list](https://bindonforever.com/npcs/riverglades). Each page shows a
  handful of spawn points; objective spots in the steps are their centre.
- **Objectives, levels, minimum levels, sides, elite flags, quest descriptions and ForeverDB's quest
  lines**: ForeverDB quest pages, `https://www.foreverdb.app/en/forever/quests/<id>`, and its zone and
  dungeon lists: [Riverglades quests](https://www.foreverdb.app/en/forever/zones/riverglades/quests),
  [Shen'dralas quests](https://www.foreverdb.app/en/forever/zones/shen-dralas/quests),
  [Krol'dok Stronghold quests](https://www.foreverdb.app/en/forever/dungeons-raids/krol-dok-stronghold/quests).
- **Zone facts and travel**: [bindonforever Riverglades](https://bindonforever.com/zones/riverglades),
  [bindonforever Shen'dralas](https://bindonforever.com/zones/shendralas),
  [warcraft.wiki.gg Riverglades](https://warcraft.wiki.gg/wiki/Riverglades),
  [warcraft.wiki.gg Powderfuse Port](https://warcraft.wiki.gg/wiki/Powderfuse_Port),
  [method.gg travel routes](https://www.method.gg/wow-forever/all-travel-routes-in-wow-forever-boats-zeppelins),
  [timesaver.gg Riverglades](https://timesaver.gg/blog/wow-forever-riverglades-zone-guide),
  [worstguidesever Riverglades](https://worstguidesever.com/wow-forever-riverglades-guide/),
  [warcraftmaps Riverglades guide](https://warcraftmaps.com/guides/riverglades-guide),
  [metabot Riverglades](https://metabot.gg/en/wow-forever/zones/riverglades).
- **Krol'dok**: [bindonforever dungeon page](https://bindonforever.com/dungeons/kroldok-stronghold),
  [warcrafttavern guide](https://www.warcrafttavern.com/forever/guides/kroldok-stronghold/) (entrance).
- **Client** (`tools/reference/forever.json` and the cached build 1.60.1.70888 tables): every quest ID
  is in `quests.ids`; Rog'mar (node 3203, 59.6 45.1, links Hammerfall, Kargath, Stonard, Flame Crest)
  and the Horde Powderfuse Port node (3274, 79.0 52.3, no links); Krol'dok is instance 3039 with
  encounters 3450 Slavecrusher Grox, 3452 Twilight Commander Zarmok, 3453 Handler Ashka, 3449
  Nar'gurk, 3451 Overseer Mugg; `ItemSparse.StartQuestID`: Krol'dok Moulding 267137 starts the Horde
  94973 (267138 the Alliance 94980), Farholde Scouting Report 263930 starts 93971, Head of Scaldaron
  271613 starts 95936, and the Shen'dralas items 259461, 259893, 260347.
- wowhead.com/forever answers scripts with a 403 and its zone page lists render client-side;
  questing.wiki has no Riverglades pages. Neither was used.

## Main route

None: everything here is an alternate route or a dungeon guide.

## Alternates

| Section | Levels | Steps | Content | Reached from (in this file) |
|---|---|---|---|---|
| `riverglades-rogmar` | 36-41 | 71 | Way in (barge or overland), Rog'mar flight path and inn, Krom'rosh, Kreza, Tan'jani, Neza, Gorg; the plains, Turner's Logging Camp, Meadowsbrook, the Bristle Hills; ends with Kreza's blade at Powderfuse Port | none yet (main route sections, see below) |
| `riverglades-bolderok` | 41-46 | 117 | Tran'gul and Sunnyglade (Fuzzle, Clubtoe's ogres, Chogg'Zac), Bolder'ok (Clugfist, the Bloodmaster's Ring chain, Jom-jom, Klunk, Scoutmaster Vargas), the Twilight's Shroud (Da'grosh, Crag'rog, Morg, Kilgar); tags the three Krol'dok pickups | `riverglades-rogmar`, `riverglades-eastsea` |
| `riverglades-eastsea` | 41-45 | 55 | Powderfuse Port: Trapclaw, the murloc shore and Old Rot-Chum, Argo's sea monster, the Eastsea pirates and Admiral Lamora, Friz's smuggling errand to Windstead | `riverglades-rogmar`, `riverglades-bolderok` |
| `shendralas-pylons` | 41-46 | 26 | From Shadowprey Village: the pylon chain to Magister Kirandis, Biraxas' crystal heart, the three item quests | `riverglades-eastsea` |

Dungeon guide: `dungeon-krol-dok-stronghold` (40-45, 17 steps, instance 3039 with the five encounter
IDs). Prepare: Eye of Mugg (94968, Krom'rosh), Tome of Twilight (94972, Tran'gul), A Token of
Vengeance (94975, Da'grosh), entrance cave at 37.5, 37.3. Inside: 15 Cultist Ears, the tome
(Nar'gurk), Mugg's eye, the Krol'dok Moulding drop (94973). After: Da'grosh, Krom'rosh, Tran'gul,
Kreza (moulding, then Key Ingredients 94974: 4 Thick Leather and 12 Iron Bars for the Krol'dok
Compound Key).

Roads added: Tanaris to the Riverglades and back by the goblin barge (Wharfmaster Steamfizzle,
Steamwheedle Port 67.6, 23.1; Wharfmaster Whizzbuzz at Powderfuse Port), Desolace to Shen'dralas
through the Valley of Bones (Desolace 58.6, 88.8 = Nerlokh's spot on the Shen'dralas map).

## Quest facts and chains

Prerequisites (`chain`) follow ForeverDB's quest lines where the next quest's giver is the previous
one's ender, or where the quest text plainly continues the last one: 93786 > 93787 > 94480 > 94481;
93788 > 93976; 96107 > 96108 > 96109; 96103 > 96104 > 96105; 95951 > 95955; 94680 > 94727;
95417 > 95601 > 95427 > 95418 > 95420; 95424 > 95428 > 94744; the ring 94668 > 94669 > 94670 > 94739 >
94962 > 94964 > 94733 > 94734 > 94737 > 94965 > 95063; 95431 > 95432 > 95433; 94745 + 94748 > 94768 >
95278; 95288 > 95293 > 95294; 95260 > 95261 > 95267 (already registered by the Alliance file);
92914 > 96010 > 96018 > 93016 > 93394; 99257 > 99258; 94973 > 94974. ForeverDB's longer "quest lines"
(Rumblings of Discontent, Rise Up! and Unworthy Champion all leading into The Purple Ones; Fetch 'n'
Fletch leading into the Alliance's Fit for a Princess) look like next-quest pointers rather than
requirements and were not used as prerequisites.

Neutral quests the Alliance file registered first (95118-95124, 95165, 95254, 95260, 95261, 95267,
95288, 94961, 94963, the Shen'dralas pylon quests) keep its records (`H.need`).

## Gaps and decisions

- **Way in.** The barge from Steamwheedle Port (Tanaris) to Powderfuse Port is in several sources and
  is the only road added. Rog'mar's flight path links Kargath, Stonard, Hammerfall and Flame Crest, but
  the first visit is on foot or by barge: the overland ways from the Badlands (north of the Twilight's
  Shroud) and the Swamp of Sorrows are named in zone notes without positions, so the first step only
  describes them (`uncertain`). The Horde Powderfuse Port flight point exists in the client with no
  routes, and a creator found no flight master there on the beta: both `getfp` steps are `uncertain`.
- **Hearth.** `riverglades-rogmar` binds at Innkeeper Toka; the bind name "Rog'mar" is assumed.
- **Left out (Riverglades)**: Step Two: More Rock (96026, needs 10 Heavy Weightstones from
  Blacksmithing); Paletusk Harvesting and Drive Them Back (95162, 95163: the paletusk spawns found are
  in the Bristle Hills, near Krol'dok and inside Bolder'ok, none clearly the quest's); Twilight Scouting
  Report (95181: Azka's position is not published, and the client has no item that starts it); Farholde
  Scouting Report (93971, item 263930: drop source not published, level 45); Hail the Dragonslayer
  (95936, from Scaldaron, a level 43 rare elite in the Bristle Hills dragon cave); Armory of Sunnyglade
  (97884, from Mirelle Tremayne in the Undercity: the tome's spot in Sunnyglade is not published);
  Gaseous Gold and Rock 'em and Sock 'em (96063, 96067, Sleebo Fizzlespout at 68.2, 48.6: objective
  spots not published); Not My Circus (95982, needs 10 Briny Seafood Stew); Clear 'em Out and Proof of
  Profit (95792, 95934, Gelinda Coppergleam: level 42 work in the 36-41 Bristle Hills trip); the Booty
  Bay contact chain (95295, 95322, 95325, 95326, 95327) and the Tanaris smuggling chain (95296, 95383,
  95312, 95321, 95472), both cross-continent errands.
- **Optional:** On the Other Side (95033, Tan'jani, level 41 min 40) is an optional pickup at the end of
  `riverglades-rogmar`; its turn-in is Witch Doctor Uzer'i at Camp Mojache (74.4, 43.4) in Feralas.
- **Elite or group work** (all `uncertain`): Snargl (40), Ombassa (41), Ghostmaw (42), Chogg'Zac,
  Scoutmaster Vargas (43), Old Rot-Chum (42), Executioner Morg (46), Overlord Kilgar (46), Admiral
  Lamora, and the six Bloodmaster's Ring fights, which ForeverDB flags elite.
- **Objectives without a published spot** (`uncertain`): Feed Satchels, Peasant Woodpiles and the
  fletching, Stolen Ore, the ritual circles under Sunnyglade, Good Rocks, Sweetberry and Riverweed,
  the Rog'mar Scouts' cages, how the Ogre Miners are recruited, Smuggled Goods, Beast Entrails and
  Rotflesh Mushrooms, the powder kegs, the three Eastsea boats, the bait spot, the pylon fragment and
  shard, the mana sparks, the rift and the protector spots in Shen'dralas.
- **Klunk's weapon** is "Skullthumper" in one source's quest log and "Skullbasher" in the other's
  required item.
- **Key Ingredients counts**: 4 Thick Leather and 12 Iron Bars in one source and in the item list,
  12 and 4 in one objective line.
- **Shen'dralas**: the Horde can quest there. The pylon, temple, Vindael and Forlorn Gardens quests
  are for both factions; Checking Things Out (93122, Nerlokh) is Horde-only. Left out: the Gelkis line
  (93034, 93035, 93037, 93041, 93058, 93062, 93122, 93125) and the Magram line (92841, 92844, 92846,
  92847, 92873, 92893, 92894, 93066, 93072, 93129, 93188), which keep Desolace standing and start in
  Desolace; Vindael's sword chain (93450, 93546, 96060) and Mithera's garden chain (93341, 93362, 93594,
  93404, 93601, 93604, 93606, 93609), whose objective spots and middle steps are not published. No
  flight point in Shen'dralas: the route flies to Shadowprey Village and rides.
- **Krol'dok**: no Horde quest needs the Alliance chain (Twilight Mementos, Krol'dok No More!,
  Vengeance of the Highborne and the Alliance Eye of Mugg / Tome of Twilight / moulding are
  Alliance-only). Bossman Toof is not one of the game's encounters and is left out of the boss list.

## For the Alliance guides (not changed here)

- `dungeon-krol-dok-stronghold` (Alliance) can take `instanceID = 3039` and the encounter IDs above;
  the game names the bosses Handler Ashka and Overseer Mugg.
- `shendralas` (Alliance) uses Checking Things Out (93122), which bindonforever marks Horde-only.
- Whizzbuzz's quest texts imply an order (Unfriendly Competition, then Unchecked Expansion and A Blast
  Ye Scurvy Dogs! (95123, not in the Alliance route), then See Ya, Scallywags! and Admiral Lamora);
  `riverglades-shroud` takes four of them at once.

## Loop check

`tools/questloops.py` only walks the main route; its `check()` run on each alternate on its own
flagged two Rog'mar pickups split by the flight path and hearth steps and Friz's pickup split by the
port flight point; both reordered. Nothing left.

## Check in game

- The barge from Steamwheedle Port, the dock spots, and whether the port has a Horde flight master.
- The overland ways in from Kargath and Stonard, and how dangerous the Shroud edge is at 36.
- Rog'mar: Innkeeper Toka's bind name, every giver's spot, whether Show Them How It's Done needs a
  prerequisite.
- Every `uncertain` objective above; whether the spear (Stick 'Em), stew (A Serving of Strength) and
  Tallstrider Call are item-button uses.
- The Bloodmaster's Ring fights (solo or group, the deposit fee) and the order of the ring chain.
- Clubtoe: does Digging for Answers have to come first?
- Da'grosh: are his quests available without The Wayward Warrior?
- Krol'dok: the entrance cave, which boss drops the Tome of Twilight, where the moulding drops.
- Shen'dralas: the road south from the Valley of Bones, Biraxas' first quest, the fragment camps.
