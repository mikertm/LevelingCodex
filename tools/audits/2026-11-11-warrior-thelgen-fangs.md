# Warrior: Fire Hardened Mail fangs at Thelgen Rock

Owner's in-game tip (2026-11-11): a Warrior can collect Fire Hardened Mail's spider fangs while doing Alchemical Hazards in the Wetlands.

- **Facts.** Fire Hardened Mail (1701, Warrior, level 28, from 20, after The Shieldsmith 1702) objective 1 is item 6838 Scorched Spider Fang. QuestieDB Forever 0f7d8ad lists it from Leech Stalker (1111) and Cave Stalker (4040), both levels 21-22 on map 1437; the Leech Stalkers cluster around 54.3, 63.8 and 47.3, 62.4: Thelgen Rock. Alchemical Hazards (98282) sends you to the same stalkers for an Unruptured Stalker Gland. The class guide already said "kill Leech and Cave Stalkers around 50, 62 for 50 fangs".
- **Change.** `QuestClassData.lua` inlines an objective step for 1701 (objective 1, "50 Scorched Spider Fangs") right after the 98282 objective in `wetlands-early` (52.6, 62.9) and `wetlands` (48.7, 62.4). The step has `logOnly = true`, so it shows only while 1701 is in the log; the quest's `class = WARRIOR` keeps it out of every other class's route.
- **Why `logOnly`.** Fire Hardened Mail is picked up from Furen in Stormwind (the class guide). A leveling-section step for a quest not in the log would otherwise become the current step; `optional` would still show it with Settings > Show optional quests on.
- **Check in game:** a Warrior with the quest at Thelgen Rock gets the fang step after the gland, and both stalker kinds drop fangs on Forever.
