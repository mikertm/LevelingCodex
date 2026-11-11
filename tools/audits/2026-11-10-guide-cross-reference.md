# 2026-11-10: Alliance 1-30 cross-reference with another Forever leveling guide

## Method

- **Reference copies.** The owner supplied local copies of two published Forever leveling guides: guide A (its Forever Alliance guides and dungeon guides) and guide B, a paid guide add-on. Guide A's text is never copied. We use quest IDs, which quests a chapter groups together and in what order, and the dungeon handling. Guide B is paid and licensed, so it was read only to compare features, never for route data or code.
- **Quest diff.** A script parsed every accept, turn-in and complete step in guide A's Alliance chapters and compared the quest IDs with every section of our route. That covers `QuestData.lua`, `QuestAlternateData.lua`, `QuestDungeonData.lua`, `QuestSpecialData.lua` and `QuestClassData.lua`. Each missing ID was resolved with `tools/questfacts.py` (cached QuestieDB, Forever traces) to its name, level, races, start and end NPCs, and prerequisites, and checked against the Forever client reference. The script lives in the session scratchpad. Its rules are simple enough to rerun: parse each guide block, skip Horde blocks, and collect quest IDs per chapter name.
- **Gap filling.** The gaps were filled area by area, each with its own audit file:
  - `2026-11-10-starter-gaps.md`: starting zones, Loch Modan and the Stormwind and Ironforge errands, levels 1-15.
  - `2026-11-10-westfall-redridge-duskwood-gaps.md`: levels 12-30.
  - `2026-11-10-darkshore-ashenvale-wetlands-gaps.md`: Darkshore, Ashenvale, Stonetalon, Wetlands and Southshore.
  - `2026-11-10-dungeon-bosses.md`: boss order and tips for the dungeon checklists.

## "Swamplands at level 20"

No zone of that name exists. The Forever client's `AreaTable` has no area called Swamplands. The only swamp zones are Swamp of Sorrows (8, classic 35-45) and Swamplight Manor (a Dustwallow sub-area). Neither reference add-on has the name. Forever's new levelling zones are Zephras Isle (1-12), Riverglades (35-45), Shen'dralas (40-53, sources disagree) and Mount Hyjal (60).

The new Forever content that starts at about level 20 for the Alliance is the reworked **Wetlands**. It has 25+ new quests, the Excavation Site dungeon and the Auberdine to Menethil to Southshore boat line. Guide A routes it in two chapters, "23-24 Wetlands" and "27-29 Wetlands / Excavation Site". That area is treated as the one meant. Its new quests are covered in the Darkshore/Ashenvale/Wetlands audit.

- [Icy Veins: new levelling zones](https://www.icy-veins.com/wow-forever/news/new-leveling-zones-in-wow-forever-riverglades-mount-hyjal/)
- [Warcraft Tavern: all new zones](https://www.warcrafttavern.com/forever/news/all-new-zones-areas-in-wow-forever-revealed-at-blizzcon/)
- [Wetlands levelling guide](https://games.gg/world-of-warcraft/guides/wow-forever-wetlands-leveling-guide/)

## Gap summary (before this pass)

These are guide A's Alliance chapters up to level 30, counted as quest IDs we had nowhere. Duplicates across chapters are counted once in the totals.

| Area | Guide A chapters | Missing | Main themes |
|---|---|---|---|
| Starting zones | Human 6-11, Dwarf/Gnome 5-11, Night Elf 6-11, Zephras 1-13 | about 40, with the Zephras ones mostly Horde | Camping 101 profession intros, Elmore/Stormpike, Deeprun rats, Honor Students flight chain, Thunderbrew rivals, Moss-twined Heart |
| City errands | 11-16 chapters | 8 | Humble Beginnings, Philmor's Favor, Gatehouse Goods, Fishin' Time, Exploring the Alliance, Making Do |
| Westfall / Redridge | 13-15 Westfall, 19-20 Redridge | 20 | Coastal Menace, Keeper of the Flame, Murloc Poachers, Watchful Eye, Tharil'zun, Shadow Magic, Gath'Ilzogg, the Kristoff/Paxton ink chain, Messenger to Darkshire |
| Darkshore / Ashenvale / Stonetalon | 14-21, 21-23, 29-30 | 30 | Murkdeep and Jai'vhanel boards, Absent Minded Prospector, Sleeper, Therylune, Mauren scrolls, Fallen Sky Lake, Velinde, Vile Satyr |
| Duskwood | 24-27, 29-32 | 25 | Look to the Stars, Wolf Kabobs, Sven's Morbent Fel chain, Ogre Thieves to the Embalmer, Sirra's Forever item turn-ins |
| Wetlands (new Forever content) | 23-24, 27-29 | 30 | Greenwarden, Apprentice's Duties, Fall of Dun Modr, Lifting the Curse / Eye of Paleth, Nek'rosh, Bloom of the Heavens, Crocs of the Sky, Dragonmaw set, Thandol Span, the Villards, the Doomed Fleet chain |
| Dungeons | Stockade, Gnomeregan | 10 | The Stormwind chain after the Stockade riots (392-396, 350, 2745, 2746, 434), now added to the Stockade checklist's after-run phase. Gnome Improvement is level 35 and was left out. |

## Result

Across guide A's Alliance chapters up to level 30 (excluding the Mage AoE variants), the unique quest IDs we lacked went from **213 to 105**, so **108 were added**. Of the 105 left, 36 are Horde-only (Zephras Isle Horde steps). The other 69 were skipped on purpose; each area audit gives the reason. They are:

- quests not in the Forever client (308, 1641, 1645, 117);
- level 31+ links (Southshore 538, Morbent Fel 55, Weathered Grave, the Villards, Nek'rosh);
- group fights (253, 98216, 98283, Gar'im is optional);
- detours that cost more than they give (Messenger to Darkshire 143-146, Kristoff 343-347, Thunderbrew rivals 310/311);
- items you need to make first (1073/1074 potions, Dry Times' keg);
- breadcrumbs our route doesn't need.

Route audit: 2941 steps, passes. Full harness: passes.

Everything from about level 31 up (Thousand Needles onward) is outside this pass. The same script shows the size of that work, with each guide A chapter at 30-60 missing nearly all its quests.

## How the two add-ons handle dungeon quests

| | Guide A | Guide B | Leveling Codex before | Leveling Codex now |
|---|---|---|---|---|
| Choosing dungeons | Settings list per dungeon, with "recommended" scored by travel, quest XP and class value. Leveling steps tagged with a dungeon appear only for chosen ones. | An in-route "Run X later" confirm sets a flag. Dungeon pickups then show only when that flag is set. | One switch, "Show dungeon steps", wired only to the Deadmines run | Per-dungeon plans: Quests > Guide library > Dungeons has Plan recommended/all/none and a toggle on each dungeon page. Any route step tagged `forDungeon(step, id)` follows its dungeon's plan. Settings > "Plan every dungeon run" sets the default. |
| When to run | The dungeon chapter is placed in the chapter sequence (e.g. 17-18 Hall of Thanes) | "Begin finding a dungeon group" step when the pickups are done, then "Starting dungeon run" | Nothing. The player opened the checklist. | `Q.readyRun()` triggers when a planned run is in your level range with its pickups done, or with three of its quests in your log. The step window then offers "Run <dungeon>" and says once in chat to find a group. |
| Inside | Steps per quest objective | Boss-by-boss steps with mechanics tips | Prepare, inside and after checklist with quest objectives and notes | Same checklist, plus a BOSSES IN ORDER list with a short tip each (`section.bosses`) |
| Quest chains | Quest-turned-in conditions | Full chain and breadcrumb data | Prerequisites (`chain`), breadcrumbs, catch-up | Plus "Chain: part N of M, leads to <dungeon>" in the step text |
| After the run | Turn-in steps in the next chapter | Turn-ins in the route | After-run phase | Same. The Stockade's after-run phase now runs the Lescovar chain to King Varian. |

## Questing features compared

| Feature | Guide A | Guide B | Codex |
|---|---|---|---|
| Waypoint arrow, flight and boat legs | yes | yes | yes |
| Auto accept / turn in, gossip picking | yes | yes | yes |
| Quest item button | yes | yes | yes |
| Target the step's NPC (macro button) | yes | yes (target macros) | **new**: `LevelingCodexQuestTarget`, key-bindable |
| Quest chain position | partial | yes | **new** |
| Dungeon choice, find a group, boss tips | yes, partly | yes | **new** (above) |
| Full quest log warning | yes | yes | **new**: "Your quest log is full (N/M)" on a pickup, and N/M on Active quests |
| Optional side errands toggle | profession filters | conditional steps | **new**: Settings > Show optional quests (e.g. Camping 101) |
| Missed quests / catch-up | partial | yes | yes |
| Hearthstone binding logic | HS batching | yes | yes (bind steps tick off, Skip binding) |
| World map pins for steps | yes | yes | no (candidate follow-up) |
| Rare and dangerous mob warnings | yes (DB) | partial | no (candidate follow-up) |
| Junk selling, gear upgrades | yes | yes | no (out of scope for a guide add-on) |
| XP-per-hour / level tracker | yes | yes | no |

## Things to check in game

- Quests > Guide library > Dungeons: Plan recommended picks sensible runs for your character, and a planned run's pickups appear in the route. For example, Deadmines pickups in Westfall show only while the Deadmines is planned.
- Once a planned run's pickups are done at the right level, the step window shows "Run <dungeon>" and chat says to find a group, once per session.
- Step text shows "Chain: part N of M" on multi-part chains, such as the Westfall Defias chain.
- The target button appears below the item button on accept and turn-in steps, and targets the NPC. Binding it to a key works out of combat.
- A full quest log adds the warning to pickup steps. Check the maximum Forever reports (25 expected).
- Stockade checklist, after the run: the Lescovar chain from Warden Thelwater to Lady Prestor, including Clara's apples west of Goldshire.
