# Dungeon runs: bosses, entering and the way in

This pass makes the dungeon guides useful inside the dungeon. The step window now walks the bosses in order, and zoning in opens the right guide. The awkward entrances get a path the arrow follows.

Every boss and instance fact comes from the Forever client (build 1.60.1.70888). `tools/gamedata.py` now fetches the `Map` and `DungeonEncounter` tables, and `tools/reference/forever.json` lists each dungeon under `quests.instances`, with its name and its normal-difficulty encounters in the game's order. `tools/questroute.py audit` then checks the guides against that list:

- a guide's `instanceID` must be a dungeon in the client;
- a boss's `encounter` must belong to that dungeon;
- it warns about game encounters a guide doesn't list.

QuestieDB Forever confirmed the NPC ID and level of every boss in the classic dungeons. It has no records for the Forever-only dungeons (Hall of Thanes, Ruins of Lordaeron, Excavation Site, City of Dalaran), so their names come from the client and the published Forever guides below. All tips and step text are original.

## Boss data (`bosses` in QuestDungeonData.lua and QuestHordeDungeons.lua)

- **Encounter IDs:** every boss the game lists now has `encounter = <DungeonEncounter ID>`. ENCOUNTER_END and BOSS_KILL report these, so a boss step ticks off when the boss dies. Rares and summoned bosses have no encounter in the client and are matched by name or NPC ID in the combat log:
  - Miner Johnson does have one (3676);
  - none: Deviate Faerie Dragon, Deathsworn Captain, Bruegal Ironknuckle, Dark Iron Ambassador, Blind Hunter, Earthcaller Halmgar, Ironspine, Fallen Champion, Azshir the Sleepless and Baron Aquanis.
- **Names that differ from the game's encounter names.** Our names stay; the encounter ID links them:
  - Hall of Thanes, Magmatus = encounter "Infurnus" (3495). wowforeverinfo.com notes that "Infurnus" is the game's internal name for this fight, and dlonem.com also lists Magmatus.
  - Ruins of Lordaeron, The Baron = encounter "The Butcher" (3355). wowforeverinfo.com says the same.
  - City of Dalaran, Arcanic Enigma = encounter "Mana Elemental" (3301), NPC 246016. The client's quest 92489 "Power Overwhelming" asks you to slay the Mana Elemental, and its objective is named Arcanic Enigma (kami-labs.fr, read from the beta client; wowforevertalents.com, read from build 1.60.1.70888, says the same and gives the NPC ID). Every walkthrough of the dungeon (method.gg, warcrafttavern.com, wow.gg) describes the Arcanic Enigma fight with its two Mana Phantoms and none names a Mana Elemental.
  - City of Dalaran NPC IDs from wowforevertalents.com: Atrexis the Grave Knight 247126, Fel Ancient 246003, Shade of the Archmage 246020. They back up the encounter IDs when a kill is matched in the combat log.
  - Deadmines, Sneed's Shredder = encounter "Sneed" (2742). Blackfathom Deeps, Gelihast = encounter "Geilhast" (2914): that's the game's spelling for normal difficulty.
- **Added:**
  - Blackfathom Deeps (both factions): Lorgus Jett (encounter 2913, NPC 12902, level 26 in QuestieDB), after Gelihast. He is a normal-difficulty encounter the list was missing.
  - Ruins of Lordaeron (Horde): Lordaeron Captain (rare, encounter 3408), last. wowforeverinfo.com describes him as a rare who can appear in the west once the other bosses are dead, friendly to the Alliance. The Alliance list leaves him out on purpose (the audit warns about it).
- **Instance IDs added:** City of Dalaran = 2959 and Scarlet Monastery (Graveyard) = 189, from the client's `Map` table. Before this, entering them went unnoticed. All four Scarlet Monastery wings share map 189, so the Graveyard guide opens in any wing.
- **Check in game:**
  - City of Dalaran: the client also lists "Mana Wraith" (3312). No walkthrough describes it, wowclassicforever.info says no source identifies it, and forever.azerpug.com has a page for it with no position or abilities. It stays out of the boss steps until someone meets it in game (the route audit's warning is the reminder).
  - Blackfathom Deeps: Lorgus Jett's position.
  - Ruins of Lordaeron: Lordaeron Captain's position.

## The way in (`path`, new step field)

A step's `path = { {x, y}, ... }` is the way in through tunnels or a cave. The arrow leads through the points in order, then to the step's own spot. Points are converted from world yards using the zone's position in the client (`ns.questWorld`). The continent maps are included, because the client may report one in uninstanced tunnels.

| Guide | Step | Before | After | Sources |
| --- | --- | --- | --- | --- |
| Deadmines (Alliance) | Enter the portal | no spot (the arrow was hidden) | portal at Westfall 38.15, 77.47; path 40.79, 79.3 then 39.98, 77.89 | Another Forever leveling guide's tunnel waypoints (world yards, converted). QuestieDB puts the tunnel undead (Skeletal Miner, 41.2, 81.9) and Foreman Thistlenettle (42.2, 82.6) on the same stretch. |
| Westfall route (tagged Deadmines) | 168 Collecting Memories | no spot | Westfall 41.2, 81.9 (QuestieDB Skeletal Miner cluster); path 43.2, 79.7 (bottom of the ramps) | QuestieDB spawns; the other guide's first tunnel point |
| Westfall route (tagged Deadmines) | 167 Oh Brother. . . | no spot | Foreman Thistlenettle, Westfall 42.2, 82.6 | QuestieDB spawn |
| Wailing Caverns (both factions) | Enter the portal | "approach" 46.0, 36.5 | portal at Barrens 47.76, 34.86; path 46.0, 36.5 (cave mouth), 46.2, 34.96, 45.91, 33.29, 46.12, 32.53, 47.29, 32.86 | The other guide's cave waypoints (converted). wowforeverinfo.com puts the mouth at about 46.0, 36.3. QuestieDB puts Mad Magglish (outer cave) at 45.7, 33.6. |
| Hall of Thanes | Enter the portal | portal 27.98, 47.78 | same portal; path 43.5, 52.0 (passage from the High Seat), 38.1, 52.9 (stairs), 32.2, 44.44 (Thom's bridge) | dlonem.com (passage, stairs, portal near 28.4, 47.8); the other guide (Thom Filch, portal 27.78, 47.89) |

The other dungeons keep their single entrance point. The published guides only give one point for those (Razorfen Kraul 42, 90; Scarlet Monastery 82.6, 33.8; Gnomeregan 24, 40; Blackfathom Deeps 14.5, 14.6; Excavation Site 47.8, 56.3), so a path for them needs to be recorded in game.

**Check in game:**
- Whether the arrow follows the Deadmines tunnels and the Wailing Caverns cave without pointing through walls.
- Whether the client reports Westfall or the continent map down in the Deadmines tunnels. Both are handled.
- Whether the Hall of Thanes stairs are the way to Thom's bridge.

## How the guide uses it (runtime)

- **Boss steps:** each boss is a step (`type = "boss"`, its tip as the text) in the inside part of the guide, shown only while you're in that dungeon.
  - It ticks off on ENCOUNTER_END with success, on BOSS_KILL, or on the combat log's UNIT_DIED by NPC ID or name. Next passes it.
  - The combat log is only listened to inside a dungeon.
  - The quest objectives inside show under the boss as "On the way". The item button uses the first of them with a quest item, and the target button targets the boss.
- **Zoning in:** entering a dungeon that has a guide opens it at its inside part, even without Run <dungeon> (Settings > Open a dungeon's guide when you enter it).
  - Leaving doesn't force anything: the boss steps drop out, and the guide moves on to its turn-ins or ends.
  - Dying and running back in keeps the bosses already down. A different dungeon starts a new count.
