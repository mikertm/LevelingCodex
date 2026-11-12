# Class objectives on the route (pairings from the class quest audit)

Follow-up to `2026-11-11-class-quest-audit.md`; the owner asked to add the pairings. Every step is in the block at the end of `QuestClassData.lua` (Alliance through `inline`, Horde through `B.hordeInline`) and is `logOnly`: only that class's route has it, and only while the class quest is in the log.

## What went in (19 steps)

| Faction | Class quest | Section, after | Kind |
|---|---|---|---|
| Alliance | Call of Earth 94373 (Dwarf Shaman) | `coldridge`, complete 218 | objective 1 |
| Alliance | Call of Fire 94465 hand-in, 94466 Fire Tar and Reagent Pouch | `loch-modan`: turnin 267; complete 307; complete 237 | hand-in, objectives 1 and 2 |
| Alliance | Surena Caledon 1688 (Warlock) | `westfall`, accept 65 (the walk east past Brackwell) | objective 1 |
| Alliance | Call of Water 94499 (Dwarf Shaman, red waterskin) | `redridge-late`, complete 169 | objective 1, item button |
| Alliance | Redridge Rendezvous 2281 hand-in, Alther's Mill 2282 (Rogue) | `lakeshire`: accept 127; complete 98386; `redridge-late`: complete 150 | hand-in, objective 1 (twice) |
| Alliance | Mathias and the Defias 2360 hand-in, Klaven's Tower 2359 (Rogue) | `duskwood`, accept 268 | hand-in, all objectives |
| Alliance | Trial of the Sea Lion 272 (Druid) | `darkshore` complete 87760; `westfall` turnin 104 | arrival stops |
| Alliance | The Principal Source 6122, Gathering the Cure 6123, Body and Heart 6001 (Druid) | `darkshore` complete 947, accept 4740, complete 4811; `teldrassil` accept 6343 | objectives, item buttons |
| Alliance | Destiny Calls 2242 (NE Rogue) | `teldrassil`, accept 940 | objective 1 |
| Alliance | Heartswood 1738 (Warlock) | `ashenvale-early`, complete 970 | objective 1 |
| Horde | Call of Fire 1525 (Shaman) | `northern-durotar` complete 835; `crossroads` complete 871 | objectives 2 and 1 |
| Horde | Path of Defense 1498 (Warrior) | `northern-durotar`, complete 97282 | objective 1 |
| Horde | Trial at the Field of Giants 1824 (Warrior) | `camp-taurajo`, complete 97250 | objective 1 |
| Horde | Plundering the Plunderers 2381 (Rogue) | `barrens-south`, accept 1069 | objective 1, item button |
| Horde | Call of Water 1536 and 1534 (Shaman) | `hillsbrad` accept 501; `ashenvale-splintertree` accept 23 | objectives, item buttons |
| Horde | Trial of the Sea Lion 30, Silverpine half (Druid) | `sepulcher`, turnin 264 | arrival stop |

**Skipped:**
- Paladin Tome of Valor on the Westfall coast: the coast comes at about 16 and the chain opens at 20.
- Gathering the Cure's Earthroot: an herb node away from the bears, and steps can't be limited to Herbalists.
- Rogue Mission: Possible with the Druid pendant: the route's Sludge Fen trip is at 15-16 and the quest needs 20.
- The Druid pendant's Barrens half.
- Undead Paladin A Lesson in Divinity: it is only given in the Undercity, after the Tomb Weed stop.

## Changes made while implementing the proposals below

- The pendant halves are not quest-log objectives (the log only tracks the joined pendant). Instead of objective steps that would wait for Next, they are arrival stops: `B.logOnlyGoto` makes a `goto` step with the quest's class, which completes on arrival.
- The proposals' hand-in steps (Braldir 94465, Lucius 2281, Kearnen 2360) are kept: each hands the player the quest the next step works on, right there. They use the same `logOnly` gate.
- Gathering the Cure's Lunar Fungus (6123, objective 2) was offered as an option and is in. The Herbalist note about Earthroot is left out.
- `tools/questroute.py audit` fails a `logOnly` step that isn't a class quest's complete, turnin or goto step. The route audit warnings are unchanged by the new steps.

**Check in game:**
- Every new step shows only for its class with the quest in the log.
- The coordinates.
- The Field of Giants antennae timer.
- Whether Braldir, Lucius and Kearnen hand over the next quest at once.

---

## Class objectives on the Alliance Eastern Kingdoms route (research, no repo edits)

Worktree read: `QuestData.lua`, `QuestAlternateData.lua`, `QuestDungeonData.lua`, `QuestSpecialData.lua`,
`QuestClassData.lua` (the thelgen pattern now calls `B.logOnlyPart`, defined in `QuestHordeData.lua`).
Facts: `tools/questfacts.py` (QuestieDB Forever 0f7d8ad), the Forever client item names
(`tools/.cache/1.60.1.70888/ItemSparse.csv`), `UiMapAssignment.csv` (70862) for cross-map distances.
`Quests.lua` `included()`: `logOnly` works on any step type (`log[step.quest] ~= nil`), so a turn-in can
be log-only too; only an accept can't.

Summary

| # | Pairing | Verdict | Insert |
|---|---|---|---|
| 1 | Shaman Call of Earth 94373 | ADD | `coldridge`, after `complete 218` (not 182: see below) |
| 2 | Shaman Call of Fire 94466 | ADD (2 steps) | `loch-modan`, after `complete 307` (Fire Tar) and `complete 237` (Reagent Pouch) |
| 3 | Warlock Surena Caledon 1688 | ADD (moved) | `westfall`, after `accept 65` (the level-15 walk east to Redridge). Not Elwynn's Red Linen Goods. |
| 4 | Shaman Call of Water (really 94499) | ADD | `redridge-late`, after `complete 169` |
| 5 | Paladin Tome of Valor 1650/1651 | SKIP | Westfall coast is passed at 16-17, the chain starts at 20 |
| 6 | Rogue Alther's Mill 2282 | ADD | `lakeshire`, after `complete 98386`; optional 2nd copy in `redridge-late` after `complete 150` |
| 7 | Rogue Klaven's Tower 2359 | ADD (moved) | `duskwood`, after `accept 268` (Raven Hill), with a log-only 2360 turn-in at Kearnen |

---

### 1. Dwarf Shaman: Call of Earth 94373 (Coldridge)

1. **Quest**: 94373 Call of Earth, level 4, **requiredLevel 4**, from Teo Hammerstorm inside Anvilmar
   (28.79, 66.18). One objective (index 1): item 264356, client name **Iceclaw Bear Pendant** x2 (quest
   text says "Frostmane Bear Pendants"; side guide `shaman-earth-totem` already uses the client name).
2. **Facts**: no Forever drop record for 264356. Drop source from our side guide, the 2026-11-08
   druid/shaman audit (azeroth.wiki), RXP and Zygor: Frostmane Troll Whelps and Frostmane Novices.
   QuestieDB spawns: Frostmane Troll Whelp (npc 706, level 3-4) Dun Morogh 24.4, 78.4 (n 33), **27.5, 80.9
   (n 23)**, 30.5, 81.0; Frostmane Novice (npc 946) 29.0, 82.0 and 30.2, 81.2 (inside the cave).
3. **Route**: `coldridge` (QuestData.lua `dm.coldridge`). The Troll Cave 182 (`objectiveAt(182, dm(nil,
   24.4, 78.4))`) comes **before** the level-4 training (`action("train", ..., { level = 4 })`, which is
   Teo for Shamans: `coldridgeTrainers` lists `{ "SHAMAN", teo }`). So at 182 a Shaman can't have 94373
   yet (level 4 + Teo in Anvilmar). The route returns to the same cave after that training:
   `along(objectiveAt(3361, ...), 218)` outside, then `along(objectiveAt(218, dm(nil, 30.5, 80.2), ...), 3361)`
   through the cave to Grik'nir. Insert after `complete 218` (same anchor as the Warlock's Beginnings
   charms), the player walks back out through both whelp and novice spawns to Grelin.
4. **Verdict**: ADD (after 218; an insert after 182 would never show in practice).
5. **Lua** (Druid/Shaman block of QuestClassData.lua, after the `shaman-earth-totem` side; locals `at`, `maps`):

```lua
  -- Call of Earth's Iceclaw Bear Pendants drop from the Frostmane Troll Whelps and Novices of the
  -- Coldridge troll cave (QuestieDB: whelps 24.4, 78.4 and 27.5, 80.9; novices 29.0, 82.0). The quest
  -- needs level 4 from Teo, the Shaman trainer the level-4 training visits, so it is in the log on the
  -- second cave trip (Grik'nir), not during The Troll Cave's whelps.
  inline("coldridge", "complete", 218, {
    B.logOnlyPart(94373, 1, at(nil, 27.5, 80.9, maps.dunMorogh),
      "Shamans with Call of Earth: the Frostmane Troll Whelps and Novices in this cave also drop Iceclaw Bear Pendants. Collect two on your way back out to Grelin.",
      "2 Iceclaw Bear Pendants"),
  })
```

---

### 2. Dwarf Shaman: Call of Fire 94466 (Loch Modan)

1. **Quest**: 94466 Call of Fire, level 14, requiredLevel 10, from Braldir Ashmantle (Loch Modan 32.17,
   65.97). Objectives in log order: **1 = Fire Tar** (item 5026), **2 = Reagent Pouch** (item 6652).
2. **Facts**: QuestieDB only lists the Horde drops for both items (Razormane in the Barrens, Burning
   Blade Cultists in Durotar). The Dwarf version's sources (side guide `shaman-fire-totem`, audit
   2026-11-08 citing bindonforever.com/quest/94466, RXP, Zygor): Tunnel Rat Geomancers and Stonesplinter
   Seers. Spawns: Tunnel Rat Geomancer (npc 1174, level 12-13) Loch Modan **35.8, 23.8** (n 10, the Silver
   Stream Mine, with Tunnel Rat Diggers 35.7, 23.9). Stonesplinter Seer (npc 1166, level 13-14) **34.7, 85.3**
   (n 16), 28.6, 84.4 (n 11), 48.6, 25.5 (n 11, Bingles' island).
   Two different spots (north mine, south valley): two steps.
3. **Route**: section `loch-modan` (QuestData.lua, `alternate = true`, 11-18). Order: first Valley of Kings
   loop (224/267 at 26.7, 56.9, turn-ins at the tower 23.2, 73.7), snow, Norric, Algaz Station, then
   `along(objectiveAt(307, mine, ...), 416)` with `mine = loch(nil, 35.9, 22.6)` (Silver Stream Mine,
   Filthy Paws) = the Geomancers' spot. Later the second valley loop:
   `objectiveAt(237, loch(nil, 32.9, 85.0), ..., "10 Stonesplinter Skullthumpers", "10 Stonesplinter Seers")`
   = the route already kills 10 Seers. Braldir is on the hill ~225 yards from the first loop, so a
   Shaman who stops there during the first loop carries 94466 into the mine.
4. **Verdict**: ADD, two steps. (Zygor's anchors 436/298 are travel neighbours; our route's own Geomancer and
   Seer stops are 307 and 237.)
5. **Lua** (Druid/Shaman block, after `shaman-fire-totem`):

```lua
  -- Call of Fire's reagents (bindonforever.com/quest/94466; QuestieDB has only the Horde drops):
  -- Fire Tar from the Tunnel Rat Geomancers in Silver Stream Mine (npc 1174: 35.8, 23.8), where Filthy
  -- Paws sends the route; Reagent Pouch from the Stonesplinter Seers (npc 1166: 34.7, 85.3) that In
  -- Defense of the King's Lands (237) already hunts.
  inline("loch-modan", "complete", 307, {
    B.logOnlyPart(94466, 1, at(nil, 35.8, 23.8, maps.lochModan),
      "Shamans with Call of Fire: the Tunnel Rat Geomancers in this mine drop Fire Tar. Kill them until you have one.",
      "Fire Tar"),
  })
  inline("loch-modan", "complete", 237, {
    B.logOnlyPart(94466, 2, at(nil, 34.7, 85.3, maps.lochModan),
      "Shamans with Call of Fire: the Stonesplinter Seers you hunt here also drop the Reagent Pouch. Keep at them until one drops.",
      "Reagent Pouch"),
  })
```

Optional companion (owner's call): the Fire Tar step only shows if the Shaman already went up to Braldir.
A log-only turn-in of 94465 (the torch delivery) right after the tower turn-ins makes that likely:

```lua
  local braldirStop = finish(94465, braldir,
    "Shamans with Call of Fire: Braldir waits up the stone-marked trail north-east of this tower. Give him the torch and take Call of Fire before you go north.")
  braldirStop.logOnly = true
  inline("loch-modan", "turnin", 267, { braldirStop })
```

---

### 3. Human/Gnome Warlock: Surena Caledon 1688

1. **Quest**: 1688 Surena Caledon, level 10, requiredLevel 10, from Gakin the Darkbinder (Stormwind
   39.22, 85.23). One objective (index 1): item 6810 Surena's Choker.
2. **Facts**: item 6810 drops from Surena Caledon (npc 881, level 9), Elwynn **71.0, 80.8** (Brackwell
   Pumpkin Patch).
3. **Route**:
   - Human `elwynn`: Red Linen Goods `along(objective(83, 70.9, 80.1, ...), 88)` is at Brackwell, but the
     route reaches it around level 9, **before** the level-10 training and the Stormwind trip where Gakin
     gives 1688 (`action("train", ..., { level = 10 })` then `action("goto", ..., "Follow the road through
     the gates into Stormwind.")`). After Stormwind it goes Goldshire, Hogger, Westfall: never Brackwell again.
     A log-only step after 83 would essentially never show.
   - Dwarf/Gnome `dunmorogh`: ends with the tram to Stormwind (Gakin reachable ~12) and the road through
     Goldshire to Westfall; never near Brackwell. Our route has no Manhunt 147 (RXP's D/G anchor) at all.
   - **`westfall`** (all races): after the level-15 grind, `accept(65, gryan)` then
     `action("goto", ariena, "Follow the road east through Goldshire to Redridge ...")`, a walk along the
     Elwynn east road. Brackwell lies ~200 yards south of that road between the Tower of Azora (65, 69.8)
     and the Eastvale bridge (Guard Thomas 73.97, 72.18). Inserting after `accept 65` puts the stop before
     the walk. Level gap: player 15, quest 10 (5, not over 5).
4. **Verdict**: ADD, but in `westfall` after `accept 65`, not after Elwynn's 83. Mostly helps Gnome Warlocks
   who took 1688 on the tram trip and Humans who put it off.
5. **Lua** (Priest/Mage/Warlock block, after `warlock-voidwalker`; locals `at`, `m`):

```lua
  -- Surena Caledon (npc 881 at Brackwell, Elwynn 71.0, 80.8). Gakin gives the quest at level 10 in
  -- Stormwind: Humans pass Brackwell (Red Linen Goods) before that, Dwarves and Gnomes never do. The
  -- level-15 walk from Westfall to Redridge runs along the Elwynn road just north of it.
  inline("westfall", "accept", 65, {
    B.logOnlyPart(1688, 1, at(nil, 71.0, 80.8, m.elwynn),
      "Warlocks with Surena Caledon: the walk east to Redridge passes Brackwell Pumpkin Patch, just south of the road before the Eastvale bridge. Defeat Surena among the Defias there and loot her choker.",
      "Surena's Choker"),
  })
```

Check in game: the arrow leg from Sentinel Hill to Elwynn (cross-map) and that the Elwynn section doesn't take
over when a level-15 Human enters Elwynn (its range is 6-12, so it shouldn't).

---

### 4. Dwarf Shaman: Call of Water, Stonewatch Falls (Redridge)

**ID correction**: the audit row says 94497, but 94497 is the **brown** waterskin at the pool below
Hervdana's cave in the Wetlands (64.8, 74.8). Stonewatch Falls is **94499** ("Fill the Empty Red Waterskin
at Stonewatch Falls near the Nightcrawler Murlocs"), which is also what the RXP notes pair with Fangore 180.

1. **Quest**: 94499 Call of Water, level 22, requiredLevel 20, from Hervdana Saegrund (Wetlands 65.76,
   76.52) after 94497. One objective (index 1): item 265748 **Full Red Waterskin** (use item 265747
   Unfilled Red Waterskin, as in the side guide's `withItem`).
2. **Facts**: no item drop (it's a use-item at the water). Forever NPC data: Murloc Nightcrawler (npc 544)
   Redridge 75.7-76.7, 58.5-60.1. Our side guide pins 73.7, 61.6 (ForG; the 2026-11-08 audit lists
   Wowhead 74.9, 63.0 and BoF 66.3, 62.9).
3. **Route**: Fangore 180 is in `redridge-late` (QuestAlternateData.lua) at 75.07, 37.82, north of the lake,
   ~345 yards from the falls. The same chapter's Stonewatch Keep stops are closer: `along(objective(115,
   63.2, 55.7))`, `along(check(objective(19, Tharil'zun 64.4, 59.4)))`, `along(objective(169, Gath'Ilzogg
   64.5, 55.8))`, then `objective(95999, Gar'im 72.8, 86.3)` in Render's Valley. The falls (~215 yards east of
   the keep) sit on the way from the keep to Render's Valley: insert after `complete 169`.
   `lakeshire` (17-22) only skirts Render's Valley from the south and a Shaman there rarely has 94499
   (needs the level-20 Ironforge, Loch Modan, Wetlands legs first); `wetlands-early` (20-25) suggests
   `redridge-late` next, which is when a Shaman would carry it.
4. **Verdict**: ADD (94499, `redridge-late` after `complete 169`).
5. **Lua** (Druid/Shaman block, after `shaman-water-totem`; locals `withItem`, `at`, `maps`):

```lua
  -- Call of Water's red waterskin (94499; the audit row's 94497 is the brown skin in the Wetlands).
  -- Stonewatch Falls lies just east of Stonewatch Keep, where Lakeshire: Shadowhide and Blackrock fights
  -- Gath'Ilzogg (Murloc Nightcrawlers at 75.7-76.7, 58.5-60.1; the side guide pins 73.7, 61.6).
  inline("redridge-late", "complete", 169, {
    withItem(265747, B.logOnlyPart(94499, 1, at(nil, 73.7, 61.6, maps.redridge),
      "Shamans with Call of Water: Stonewatch Falls is a short way east of the keep. Use the Unfilled Red Waterskin in the water by the Nightcrawler Murlocs.",
      "Full Red Waterskin")),
  })
```

Side note (not asked): `wetlands-early`'s Mosshide camps (`objective(276, wet(nil, 63, 66.1))`, "more camps lie
south near 62, 72") are next to Hervdana's cave; a log-only turn-in of 94495 there would be the natural
companion if the owner wants the whole Water chain on the route.

---

### 5. Paladin: The Tome of Valor (Westfall coast)

1. **Quests**: 1649 (tome item 6776, level 20, Stormwind) > **1650** "Find Daphne Stilwell" (level 23,
   requiredLevel 20, Duthorian > Daphne; a delivery, no objective) > **1651** "Defend Daphne Stilwell from
   the Defias attack" (level 25, event at Daphne 41.69, 89.24) > 1652 (back to Duthorian). None of them kills
   a named coast mob: the Westfall stop is Daphne's house on the south coast above the Deadmines back exit.
2. **Facts**: Daphne Stilwell (npc 6182) Westfall 41.69, 89.24.
3. **Route**: `westfall` (12-18) does The Coastal Menace 104 (`objectiveAt(104, wf("Old Murk-Eye", 29.3, 76))`,
   Grayson at the lighthouse 30.01, 86.02) at about level 16, before the level-17 grind. 1649 needs level
   20 and a Stormwind visit, so no Paladin can carry 1650 there (RXP does this coast trip at 19-20, Zygor at
   25-27). After Westfall the route never returns to the Westfall coast (`duskwood` stays in Duskwood).
4. **Verdict**: SKIP (route order / level: the coast is passed at ~16, the chain opens at 20).
   - Only place our data passes Daphne at 20+: the Deadmines back exit (`exitAlba` 38.68, 83.7, ~165 yards
     from Daphne) in the `dungeon-deadmines` checklist's "after" phase (levels 17-26). If the owner wants it:
     `inline("dungeon-deadmines", "turnin", 92753, { ... })` with log-only `finish(1650, daphne)`,
     `B.logOnlyPart(1651, nil, daphne, ...)` and log-only `finish(1651, daphne)`, each with
     `step.phase = "after"` (inline doesn't set it; `add()` does for its own steps). Check first how
     `Q.sectionProgress` / `Q.readyRun` count log-only steps in a dungeon checklist. Not recommended blind.

---

### 6. Rogue: Alther's Mill 2282 (Redridge)

1. **Quest**: 2282 Alther's Mill, level 20, requiredLevel 16, from Lucius (Redridge 22.97, 52.04) after
   2281. One objective (index 1): item 7871 **Token of Thievery**.
2. **Facts**: item 7871 from object Lucius's Lockbox (121264) Redridge **46.95, 44.69**. Practice Lockbox
   objects (178244, 178246) at 46.65-47.16, 44.92-45.49, right beside it (Pick Lock practice to skill 25,
   per our side guide).
3. **Route**: `lakeshire` (QuestData.lua): `along(objectiveAt(124, rr(nil, 34.5, 31.5)))` (A Baying of
   Gnolls), turn-ins in town, then `accept(98386, oslow)` and `along(objectiveAt(98386, rr(nil, 46.5, 37.5),
   "Kill Greater Tarantulas and crush eggs at the mill ..."))` = Forever quest 98386, also named "Alther's
   Mill". That is the route's stop at the mill. A Rogue can have 2282 by then: Renzik (SI:7) is in the
   building the Westfall section's Stormwind trip visits for Shaw (finish 135), and Lucius is on the Lakeshire
   dock. Secondary: `redridge-late` walks the north shore past the mill (`objective(150, rr(nil, 35.9, 47.4))`
   then `action("goto", rr(nil, 62.2, 44.2), ...)`).
4. **Verdict**: ADD (`lakeshire` after `complete 98386`); the `redridge-late` copy is optional (harmless,
   covers a late Rogue, quest level 20 vs chapter 23).
5. **Lua** (Hunter/Rogue block, after `rogue-lockpicking`; locals `at`, `finish`, `maps`, `lucius`):

```lua
  -- Lucius's Lockbox (object 121264: 46.95, 44.69) sits among the Practice Lockboxes at Alther's Mill,
  -- the mill Lakeshire's route clears for Oslow (98386) and Shadowhide and Blackrock passes on the
  -- north shore road.
  local function altherBox()
    return B.logOnlyPart(2282, 1, at(nil, 46.95, 44.69, maps.redridge),
      "Rogues with Alther's Mill: Lucius's Lockbox and the practice lockboxes are at this mill. Pick the practice boxes until your Lockpicking reaches 25, then open Lucius's Lockbox for the token.",
      "Token of Thievery")
  end
  inline("lakeshire", "complete", 98386, { altherBox() })
  inline("redridge-late", "complete", 150, { altherBox() })
```

Optional companion: a log-only turn-in of Redridge Rendezvous 2281 at Lucius when the route reaches the
Lakeshire docks:

```lua
  local luciusStop = finish(2281, lucius,
    "Rogues with Redridge Rendezvous: Lucius waits on the dock just west of the bridge. Hand in Renzik's orders and take Alther's Mill.")
  luciusStop.logOnly = true
  inline("lakeshire", "accept", 127, { luciusStop })
```

Aside: QuestieDB gives 98386 (and 98387) `requiredRaces = DWARF + NIGHT_ELF + GNOME + SKYBORNE`, no Human;
our `q(98386, ...)` has no race. Out of scope here, but the Rogue text above doesn't depend on 98386.

---

### 7. Rogue: Klaven's Tower 2359 (Westfall)

1. **Quests**: 2360 Mathias and the Defias (level 20, Shaw in SI:7 > Agent Kearnen, a delivery) > **2359**
   Klaven's Tower (level 24, requiredLevel 20, from Kearnen, turned in to Shaw). 2359 objectives in **log
   order: 1 = Klaven Mortwake's Journal (item 7908), 2 = Defias Tower Key (item 7923)** (the side guide lists
   them the other way round; labels are display only).
2. **Facts**: Agent Kearnen (npc 7024) Westfall 68.49, 70.08. Key from Malformed Defias Drone (npc 7051,
   level 23-24) 69.5, 74.0; journal from object Duskwood Chest (123214) **70.4, 73.9**.
3. **Route**:
   - The Legend of Stalvan 67/68 is not on the leveling route: it is the special side section
     `legend-of-stalvan` (QuestSpecialData.lua); 67/68 are at the Moonbrook schoolhouse footlocker (Westfall
     41.51, 66.73), ~1050 yards west of the tower.
   - `westfall` (12-18) is too early (2360 needs 20) and its closest stop, the Dust Plains camps
     (`objectiveAt(14, wf(nil, 55.4, 76.8))`), is ~530 yards away.
   - `duskwood` (21-27) never enters Westfall, but Raven Hill is on the Westfall road: converted with the
     client map regions, Kearnen = Duskwood (7.9, 73.3) and the tower = Duskwood (10.4, 78.2), i.e. ~415 and
     ~450 yards from Jitters' house (18.38, 56.37). The route's second Raven Hill visit (~level 24) is
     `finish(240, jitters)`, `finish(453, jitters)`, `accept(268, jitters)`, then the cemetery. Insert
     after `accept 268`.
   - 2359 alone would only show to a Rogue who already met Kearnen (i.e. who was already at the tower),
     so the useful part is a log-only 2360 turn-in at Kearnen, then the 2359 objective once accepted.
4. **Verdict**: ADD in `duskwood` after `accept 268` (2360 turn-in + 2359 objective, both log-only).
5. **Lua** (Hunter/Rogue block, after `rogue-poisons`; locals `at`, `finish`, `maps`, `kearnen`):

```lua
  -- Klaven's Tower: Agent Kearnen (68.49, 70.08) and the Defias tower (Malformed Defias Drone 69.5, 74.0;
  -- Duskwood Chest 70.4, 73.9) stand by the road from Raven Hill into Westfall, about 400 yards from
  -- Jitters' house, which Duskwood's route visits around level 24. The 2360 turn-in brings the Rogue
  -- there; the tower step then shows once Klaven's Tower is accepted.
  local kearnenStop = finish(2360, kearnen,
    "Rogues with Mathias and the Defias: follow the road south-west out of Raven Hill into Westfall, where Agent Kearnen waits in Stealth by a tree south of the road. Hand in Shaw's orders and take Klaven's Tower.")
  kearnenStop.logOnly = true
  inline("duskwood", "accept", 268, {
    kearnenStop,
    B.logOnlyPart(2359, nil, at(nil, 70.41, 73.93, maps.westfall),
      "Rogues with Klaven's Tower: the Defias tower stands just past Kearnen. Pick Pocket the Malformed Defias Drone outside for the key, then pick the lock on the Duskwood Chest upstairs for Klaven's journal.",
      "Klaven Mortwake's Journal"),
  })
```

(Two `objectivePart`s, index 2 key at 69.5, 74.0 then index 1 journal at 70.41, 73.93, would also work; the
two spots are ~25 yards apart, so one step with `index = nil` is enough.)
Optional extra: the same pair after `accept 67` in `legend-of-stalvan` for Rogues who walk the west road to
the schoolhouse; it would also pull a Rogue who flies to Sentinel Hill ~1000 yards east, so not recommended.

---

### Notes for the implementer

- Log-only **turn-ins** (Braldir 94465, Lucius 2281, Kearnen 2360) need `step.logOnly = true` set by hand
  (`B.logOnlyPart` only builds objectives). Check whether `tools/questroute.py audit` flags a turn-in whose
  quest the path never picks up (it skips optional ones; it may need the same skip for `logOnly`).
- Cross-map log-only steps (Surena's Elwynn step inside `westfall`, the Westfall steps inside `duskwood`):
  check the arrow's road/flight leg and that zone-entry switching doesn't pick the other section (Elwynn
  6-12 and Westfall 12-18 are both below the player's level there).
- Text is ASCII, starts with "<Class>s with <Quest>:", written for this file (no RXP/Zygor wording).
- In game: confirm the Dwarf drops (pendants from whelps/novices, Fire Tar from Geomancers, Reagent Pouch
  from Seers) and the Stonewatch Falls spot; none of them is in QuestieDB's Forever drop data.

## Pairings: Alliance Druid, Rogue, Warlock (Kalimdor plus one Westfall stop)

Research only, no repo edits. Facts: `questfacts.py` (QuestieDB Forever 0f7d8ad cache) and the raw
`foreverObjectDB.lua`. Route anchors were checked by grep in the worktree. Each anchor is the only
step of that type and quest in its section, so `inline` lands where intended.
`B.logOnlyPart(id, index, place, text, label)` is already in `QuestHordeData.lua` (lines 31-35), with
the signature the brief gives.

Distances use the route's yard extents: Darkshore 6550 x 4367, Westfall 3500 x 2333,
Teldrassil 5092 x 3394, Ashenvale 5767 x 3844.

| # | Quest | Verdict | Section, insert after |
|---|---|---|---|
| 1a | 272 Darkshore half | ADD | `darkshore`, complete 87760 |
| 1b | 272 Westfall half | ADD | `westfall`, turnin 104 |
| 2a | 6122 Cliffspring sample | ADD | `darkshore`, complete 947 |
| 2b | 6123 Earthroot with Cleansing of the Infected 2138 (RXP) | SKIP | - |
| 2c | 6123 Lunar Fungus (my alternative) | ADD (owner's call) | `darkshore`, accept 4740 |
| 3a | 6001 Lunaclaw, NE route's Auberdine stop | ADD | `teldrassil`, accept 6343 |
| 3b | 6001 Lunaclaw, Darkshore red crystal | ADD (second chance) | `darkshore`, complete 4811 |
| 4 | 2242 Sethir's Journal | ADD | `teldrassil`, accept 940 |
| 5 | 1738 Heartswood | ADD | `ashenvale-early`, complete 970 |

---

### 1. Druid: Trial of the Sea Lion 272 (Night Elf and Skyborne)

**Objectives.** Neither half is a quest-log objective. QuestieDB 272 has a single item objective,
index 1 = 15885 Pendant of the Sea Lion. You get it by joining the halves at the Shrine of Remulos.
The halves are only `requiredSourceItems`:
- 15883 Half Pendant of Aquatic **Agility**: Strange Lockbox, object 177792, Darkshore **48.9, 11.3**.
- 15882 Half Pendant of Aquatic **Endurance**: Strange Lockbox, object 177844, Westfall **17.9, 33.2**.

The Horde boxes (177794 in the Barrens, 177790 in Silverpine) belong to quest 30.

So these steps can't complete themselves: they end with Next, or when the pendant is joined. Our side
guide `druid-aquatic-form` already works this way ("press Next"). Index: nil. Index 1 would behave the
same, because objective 1 only finishes at the shrine. Both steps show to every druid carrying 272,
even one who already has that half. That is why each text says to use Next.

#### 1a. Darkshore half: ADD
- Route: `darkshore`, later north loop, `objectiveAt(87760, shore(nil, 49.4, 14.4), ...)` (Holy Diver:
  "Swim out to the rock spire off the north shore", QuestData.lua:2782). The next step is the hearth
  to Auberdine.
- The lockbox is about 140 yards past the spire, further out to sea. The player is already swimming
  there.
- Level: this loop is about 18-20 and 272 needs 16. The first north loop (4725/4727, about 15-16) is
  400-500 yards from the box, and at that level few druids have 272 yet. Use one anchor only: a second
  copy would show again after Next on the first.

#### 1b. Westfall half: ADD
- Route: `westfall`, `finish(104, Captain Grayson)` at the lighthouse (QuestData.lua:707), right
  before "Follow the road north-east back to Sentinel Hill".
- The box is about 1.3 km up the coast from the lighthouse. It costs about 1.6 km extra against
  riding straight back. Other anchors:
  - After complete 104 (Old Murk-Eye): about 2.1 km extra, because you come back south to Grayson.
  - The Gold Coast Quarry stop (92745 part 2): only about 1.1 km extra, but it comes at about 14-15,
    before a druid can hold 272.
- Level: 104 comes at about 16-17. No later Alliance section returns to Westfall.

```lua
-- QuestClassData.lua, "Druid and Shaman" block (locals at, maps), after the druid-aquatic-form side(...)
  -- The halves are not quest-log objectives (the log only tracks the joined Pendant of the Sea
  -- Lion, made at the Shrine of Remulos), so these steps end with Next. QuestieDB: Strange Lockbox
  -- 177792 (Darkshore 48.9, 11.3) and 177844 (Westfall 17.9, 33.2).
  inline("darkshore", "complete", 87760, {
    B.logOnlyPart(272, nil, at(nil, 48.87, 11.32, maps.darkshore),
      "Druids with Trial of the Sea Lion: swim on past the rock spire to the Strange Lockbox between the rock pillars to the north (48.9, 11.3) for the Half Pendant of Aquatic Agility. Use Next once you have it, or if you already do.",
      "Half Pendant of Aquatic Agility"),
  })
  inline("westfall", "turnin", 104, {
    B.logOnlyPart(272, nil, at(nil, 17.94, 33.18, maps.westfall),
      "Druids with Trial of the Sea Lion: before you head back to Sentinel Hill, follow the coast north past Gold Coast Quarry and dive to the Strange Lockbox offshore (17.9, 33.2) for the Half Pendant of Aquatic Endurance. Use Next once you have it, or if you already do.",
      "Half Pendant of Aquatic Endurance"),
  })
```

Check in game: whether Forever's log lists the halves as objectives. If it does, give each step that
index so it completes on its own.

---

### 2. Druid cure poison chain 6121 > 6122 > 6123 > 6124 > 6125

#### 2a. The Principal Source 6122: ADD
- Objective index 1 = 15845 Filled Cliffspring Falls Sampler, the only objective. You fill it by using
  15844 Empty Cliffspring Falls Sampler "at the mouth of the cave by the falls".
- Route: `darkshore`, first north loop, `objectiveAt(947, shore("Cliffspring Falls Cave Mouth", 54.92, 33.31), ...)`
  (Cave Mushrooms, QuestData.lua:2699). It is the same cave mouth as our side guide's spot
  (55, 33.5). RestedXP does the sample with 947.
- Zygor's anchor, after Gyromast's Retrieval 2098, is our later north loop. Our cave visit is 947 in
  the first loop, so 947 is the anchor.
- Level: 6122 needs 14, and this loop is about 15-16.

#### 2b. Gathering the Cure 6123, Earthroot with Cleansing of the Infected 2138 (RestedXP): SKIP
- Objectives (QuestieDB order): **1 = 5 Earthroot (2449), 2 = 12 Lunar Fungus (15851)**. Our side
  guide lists the labels the other way round ("12 Lunar Fungus", "5 Earthroot"). Only the log index
  matters.
- In our order, the 2138 bear kills (47.4, 33.2) come right after the 947 sample. 6123 only starts
  when you hand 6122 to Alanndarian in Auberdine, which is later. So 6123 can't be in the log there.
- Earthroot is a Herbalism node (object 1619). QuestieDB has no nodes near the bears. The Darkshore
  clusters are 36.1, 84.9 (Master's Glaive), 43.2, 65.9 and 44.0, 86.7, all in the south.
- Steps have no profession filter, so an Earthroot step would hold non-herbalists until Next.

#### 2c. Gathering the Cure 6123, Lunar Fungus (my alternative): ADD, owner's call
- Lunar Fungal Bloom (object 177750) grows in two moonkin caves: 11 nodes at 44.4, 51.5 and 9 at
  44.5, 46.9 (the second is the Moonkin Stone cave). Anyone can gather them, and the step completes
  itself at 12.
- After the 6122 hand-in, the route next leaves Auberdine on the south loop, so the anchor is the last
  Auberdine pickup before it: `accept(4740, board, ...)` (QuestData.lua:2715). The next step is
  "Follow the south road" to 4728 at 36.0, 70.9.
- The caves sit about 300 yards east of the road, about 500 yards extra. The text also points
  herbalists at the Earthroot by the Master's Glaive, which this loop visits.

```lua
-- QuestClassData.lua, "Additional Druid and Shaman unlocks" block (locals at, m), after the druid-cure-poison side(...)
  -- The Principal Source fills at the mouth of the Cliffspring Falls cave, the Cave Mushrooms (947)
  -- cave. Gathering the Cure: Lunar Fungal Blooms (QuestieDB object 177750) in the moonkin caves at
  -- 44.4, 51.5 and 44.5, 46.9; objective 1 is Earthroot, 2 is Lunar Fungus.
  inline("darkshore", "complete", 947, {
    B.withItem(15844, B.logOnlyPart(6122, 1, at(nil, 54.92, 33.31, m.darkshore),
      "Druids with The Principal Source: use the Empty Cliffspring Falls Sampler at the mouth of this same cave to draw the water sample for Alanndarian.",
      "Filled Cliffspring Falls Sampler")),
  })
  inline("darkshore", "accept", 4740, {
    B.logOnlyPart(6123, 2, at(nil, 44.4, 51.5, m.darkshore),
      "Druids with Gathering the Cure: on the way south, stop at the moonkin caves east of the road (44.4, 51.5 and 44.5, 46.9) and pick 12 Lunar Fungus from the fungal blooms. Herbalists can pick the 5 Earthroot around the Master's Glaive later in this loop.",
      "12 Lunar Fungus"),
  })
```

Check in game:
- Lunar Fungus is objective 2. If it is 1, change the index.
- Using the sampler at the 947 cave mouth fills it.

---

### 3. Druid Body and Heart 6001 (Night Elf; Skyborne use Ursera 94006/94638)

- Objectives: QuestieDB has none. It is a scripted event (`specialFlags` 2): use 15208 Cenarion
  Moondust on the Moonkin Stone, kill Lunaclaw (npc 12138, level 12, summoned, no spawn record), then
  speak to his spirit. Index: nil (the step ends when the quest is ready).
- Place: Moonkin Stone, object 177525, Darkshore **43.5, 46.0**. That is the moonkin cave east of
  Auberdine. Our side guide says "near Bashal'Aran", but Bashal'Aran is about 10 points further
  north. The text should be "east of Auberdine".
- **3a. Route:** `teldrassil` (Night Elf only), the Flight to Auberdine stop. In order:
  finish 6342 at Laird, then `accept(6343, te.laird, ...)` (QuestData.lua:2214), getfp at Caylais,
  then fly back to Nessa.
  - Laird to the stone is about 450 yards.
  - Level about 12. 6001 needs 10, Lunaclaw is level 12.
  - This is Zygor's spot. RestedXP uses the red crystal (3b).
- **3b. Route:** `darkshore`, first loop, `objectiveAt(4811, crystal 47.32, 48.68, ...)`
  (QuestData.lua:2617). The stone is about 280 yards west of the crystal. It is a second chance for a
  druid still carrying 6001 into Darkshore. Once the first step completes, the second is done too.

```lua
-- QuestClassData.lua, "Druid and Shaman" block (locals at, maps, withItem), after the druid-bear-form side(...)
  -- Lunaclaw: the Moonkin Stone (QuestieDB object 177525, Darkshore 43.5, 46.0). The quest has no
  -- item objective, so the step ends when the quest is ready.
  local function lunaclaw(text)
    return withItem(15208, B.logOnlyPart(6001, nil, at("Moonkin Stone", 43.5, 45.97, maps.darkshore), text,
      "Speak with Lunaclaw's spirit"))
  end
  inline("teldrassil", "accept", 6343, { lunaclaw(
    "Druids with Body and Heart: the Moonkin Stone is in the moonkin cave a short run east of Auberdine (43.5, 46.0). Use the Cenarion Moondust there, defeat Lunaclaw and speak to his spirit before you fly back.") })
  inline("darkshore", "complete", 4811, { lunaclaw(
    "Druids with Body and Heart: the Moonkin Stone is in the moonkin cave just west of the red crystal (43.5, 46.0). Use the Cenarion Moondust there, defeat Lunaclaw and speak to his spirit.") })
```

Check in game: talking to the spirit marks 6001 complete in the log, so the step clears without Next.

---

### 4. Night Elf Rogue: Destiny Calls 2242

- Objective index 1 = 7737 Sethir's Journal (only objective; picked from his pocket, so no drop
  record).
- Sethir the Ancient: npc 6909, level 12, Teldrassil **37.1, 22.8**.
- Our quest: `takeIntro` moves 2241 out of the `teldrassil` route into the side guide
  `rogue-blade-night-elf`. So a rogue only has 2242 if they took it from Syurna during the route's
  Darnassus visit (QuestData.lua:2145-2152). The Oracle Glade comes right after that visit.
- Route: `teldrassil`. The harpy loop ends at the Oracle Tree Bark with `accept(940, te.bark, ...)`
  (QuestData.lua:2166, bark at 36.97, 34.04). Next is `along(objectiveAt(2518, Lady Sathrah 44.2, 25.5), 923)`.
  - Bark to Sethir to Sathrah costs about 290 yards extra.
  - After the harpy leaders (98392, Arysa at 35.0, 28.2) it would be about 340 yards.
  - Between 2518 and 923 (Zygor's slot) it would be about 700 yards, out from Wellspring Lake and
    back.
- Level: about 11. 2242 needs 10, and Sethir is 12. Our side guide already says to try again at 12.

```lua
-- QuestClassData.lua, "Hunter and Rogue" block (locals at, maps), after the rogue-blade-night-elf side(...)
  -- Sethir the Ancient (QuestieDB npc 6909, Teldrassil 37.1, 22.8) is north of the Oracle Glade, on
  -- the way from the Oracle Tree Bark to Wellspring Lake.
  inline("teldrassil", "accept", 940, {
    B.logOnlyPart(2242, 1, at("Sethir the Ancient", 37.1, 22.8, maps.teldrassil),
      "Rogues with Destiny Calls: Sethir the Ancient is just north of the Oracle Glade (37.1, 22.8), a short detour on the way to Wellspring Lake. Approach in Stealth and pickpocket Sethir's Journal.",
      "Sethir's Journal"),
  })
```

---

### 5. Warlock: Heartswood 1738

- Objective index 1 = 6912 Heartswood (only objective).
- QuestieDB: the Heartswood object at Ashenvale **31.5, 31.5**. Dark Strand Excavators (npc 3730,
  level 19-20, 5 spawns at 31.6, 31.2) are listed as droppers too, which is likely the guards around
  the object.
- Route: `ashenvale-early`, second circuit, `objective(970, ash(nil, 31.39, 30.62), "Clear cultists around the ruins northeast of the post. Loot the Glowing Soul Gem.")`
  (QuestAlternateData.lua:138). These are the same Ordil'Aran ruins, about 35 yards away.
  - Zygor's "after The Tower of Althalaxx 973" is the 973 pickup at Delgren. 973's own objective is at
    Fire Scar Shrine, so 970 is the place that matches.
  - `ashenvale-late` never goes back to Ordil'Aran.
- Level: this circuit starts after "Reach level 20", and 1738 needs 20. A warlock has 1738 here only
  after the Takar trip (side guide `warlock-sayaad`, by way of the Barrens), so the step will be rare
  but cheap.

```lua
-- QuestClassData.lua, "Priest, Mage, Warlock" block (locals at, ashenvale = 1440), after the warlock-sayaad side(...)
  -- Heartswood (QuestieDB object at Ashenvale 31.5, 31.5) lies in the Ordil'Aran ruins where
  -- ashenvale-early takes the Glowing Soul Gem (970).
  inline("ashenvale-early", "complete", 970, {
    B.logOnlyPart(1738, 1, at("Heartswood", 31.53, 31.52, ashenvale),
      "Warlocks with Heartswood: the Heartswood lies at the roots of the tree in these same ruins, among the Dark Strand Excavators. Loot it before you move on to Bathran's Haunt.",
      "Heartswood"),
  })
```

Related (not assigned to me): What Is Love? 65602 (also from Takar, objective 190309 Wooden
Figurine) is at Ashenvale 26, 22. The nearest route step is the 1010 Bathran's Hair step
(31.46, 22.81), about 320 yards east. The figurine also needs a torch and a burned cart, so it is not
a clean pairing.

---

### Optional extras (turn-ins, beyond the brief)

A `finish` step with `logOnly = true` would also bring the hand-in onto the route. But it shows while
the quest is in the log even when unfinished, so a player who skipped the objective has to press Next.

- 6001: after `turnin 6343` (Nessa, Rut'theran), `finish(6001, mathrengyl, ...)` for the portal up to
  Darnassus.
- 2242: after `turnin 923` (Rellian), `finish(2242, syurna, ...)`. Syurna is in the same Cenarion
  Enclave.
- 6122: after `turnin 4762` (Thundris, 37.4, 40.1), `finish(6122, alanndarian, ...)`. Alanndarian is
  next door at 37.7, 40.7, and the hand-in starts 6123.

### Notes for the implementer
- None of these quests is picked up on the route path (all come from side guides). `questroute.py
  audit` must accept a logOnly step whose quest that path never picks up, as it does for the Warrior
  fangs (1701).
- All texts are printable ASCII. The apostrophes in Rut'theran, Ordil'Aran and Bathran's are plain
  `'`.

## Horde pairings: class objectives on the route (logOnly steps)

Research only, no repo edits. Facts from `questfacts.py` (QuestieDB Forever 0f7d8ad) and the client tables in
`tools/.cache/1.60.1.70888` (`ItemSparse`, `AreaTable`). Route anchors read from the Horde route files.

**Checked:** every snippet below was run in a scratch lupa load of the quest data files (the .toc order QuestData.lua
through QuestClassData.lua, with the snippets run right after QuestHordeClassDruidShaman.lua and a stand-in
`B.logOnlyPart` = `objectivePart` + `logOnly = true`). Script: `check_pairings.py` in the scratchpad.
- Every anchor matched. Each step landed between the intended route steps (listed per pairing).
- Each step picked up its quest's `class` (and `race` for 1498).
- All text is printable ASCII.
- `questroute.py`'s `audit()` passes with 0 errors. It gives one new warning, explained under pairing 7.

**Where to paste:** put each snippet **after** that quest's `q()`/`call()`/`w()` record in its file. `questAction`
copies `quest[id]` (`class`, `race`) into the step when the step is built, so the record has to exist first. In practice,
put each snippet after the matching `B.hordeSide{...}`. Locals named in the snippets (`at`, `m`/`M`, `ba`, `withItem`)
are already defined in that `do` block.

| # | Pairing | Verdict |
|---|---|---|
| 1 | Shaman Call of Fire 1525 | ADD x2 (Reagent Pouch in northern-durotar, Fire Tar in crossroads) |
| 2 | Warrior Path of Defense 1498 | ADD (northern-durotar, after Stormy Potential) |
| 3 | Warrior Trial at the Field of Giants 1824 | ADD (camp-taurajo, at the **end** of the loop: the antennae decay) |
| 4 | Rogue Plundering the Plunderers 2381 | ADD (barrens-south, before Stolen Booty) |
| 5 | Rogue Mission 2478 + Druid pendant, one Sludge Fen trip | SKIP |
| 6 | Shaman Call of Water 1536 / 1534 | ADD x2 (hillsbrad, ashenvale-splintertree) |
| 7 | Druid Trial of the Sea Lion 30 halves | ADD Silverpine half (sepulcher); SKIP the Barrens half |
| 8 | Undead Paladin A Lesson in Divinity 94434 | SKIP |

---

### 1. Shaman: Call of Fire 1525 (Fire Tar, Reagent Pouch)

- **Quest:** 1525 (level 12, needs level 10, after 1524). Log order: **1 = Fire Tar** (item 5026), **2 = Reagent Pouch**
  (item 6652). This matches our class guide's `part(1525, 1/2, ...)`. Given by Telf Joolam in Durotar (38.55, 58.96).
- **Facts:**
  - Fire Tar drops only from Barrens Razormane:
    - Water Seeker (lvl 10-11) at 54.8, 26.2.
    - Thornweaver (lvl 10-11) at 55.0, 26.0.
    - Geomancer (lvl 12-13) at 58.0, 24.7.
    - Mystic (lvl 13-14) at 58.5, 26.8.
  - **The Durotar Razormane of Encroachment 837 do not drop it** (Quilboar, Scout, Dustrunner, Battleguard), so the
    brief's 837/840 placement is wrong for Fire Tar.
  - Reagent Pouch drops only from Burning Blade Cultist 3199 (lvl 10-11): 7 spawns at 52.4, 25.5 in Durotar, Dustwind
    Cave (AreaTable 371). Fizzle's Thunder Ridge camp for Dark Storms 806 (42.1, 26.7) has no cultists that drop it.
- **Route:**
  - Reagent Pouch: northern-durotar (Orc/Troll, 10-12), after `complete 835` (Dustwind Savages and Storm Witches at
    54.0, 23.7). This is the route step closest to the cave: about 2.4 map units (~130 yd) south-west of it. The
    other ravine stop, `complete 834` at 49.7, 21.9, is twice as far.
  - Fire Tar: crossroads (all races, 12-15), after `complete 871` (Disrupt the Attacks at 53.6, 24.5). That step kills
    the same Water Seekers and Thornweavers.
  - Scratch check:
    - northern-durotar #44: `complete 835` -> **1525 pouch** -> `turnin 835`.
    - crossroads #26: `complete 871` -> **1525 tar** -> `accept 819`.
- **Verdict: ADD (two steps).**
  - Tauren Shamans never walk northern-durotar, so they get the pouch only from the class guide.
  - The quest is in the log only if the Shaman went to Telf through the class guide (2983 -> Kranal Fiss -> Telf) and
    returned to leveling.
- **Lua** (QuestHordeClassDruidShaman.lua, Shaman block, after the `shaman-fire-totem-horde` side guide):

```lua
  -- Call of Fire's two drops are on the route: Burning Blade Cultists in Dustwind Cave (QuestieDB: 3199, 52.4, 25.5)
  -- next to Securing the Lines' harpies, and Fire Tar from the Barrens Razormane of Disrupt the Attacks.
  B.hordeInline("northern-durotar", "complete", 835, {
    B.logOnlyPart(1525, 2, at(nil, 52.4, 25.5, m.durotar),
      "Shamans with Call of Fire: the Burning Blade Cultists in Dustwind Cave, just south-west of these harpies, drop the Reagent Pouch. Kill them until one drops.",
      "Reagent Pouch"),
  })
  B.hordeInline("crossroads", "complete", 871, {
    B.logOnlyPart(1525, 1, at(nil, 54.9, 26.1, m.barrens),
      "Shamans with Call of Fire: the Razormane Water Seekers and Thornweavers here also drop Fire Tar. Keep killing them until one drops.",
      "Fire Tar"),
  })
```

### 2. Warrior: Path of Defense 1498 (Singed Scales)

- **Quest:** 1498 (level 10, after Veteran Uzzek 1505), from Uzzek at Far Watch Post (Barrens 61.38, 21.12). Single
  objective: **1 = 5 Singed Scale** (item 6486). Our record limits it to Orc/Troll/Tauren.
- **Facts:** Singed Scale drops in Durotar:
  - Thunder Lizard (lvl 9-10) at 39.3, 28.1; 40.4, 28.9; 39.1, 30.7.
  - Lightning Hide (lvl 10-11) at 42.1, 24.3; 39.3, 24.6.
  - Stormy Potential 97282's organs come from the same Lightning Hides.
- **Route:**
  - northern-durotar, after `complete 97282` (39.4, 25.3, "Kill Lightning Hides in Thunder Ridge").
  - Scratch check #49: `complete 97282` -> **1498** -> `accept 96877`. The step carries race ORC/TROLL/TAUREN.
- **Verdict: ADD.**
  - Only Orc/Troll Warriors can see it. The route reaches Uzzek only at the end of the section, so they have 1498 here
    only if they took the class guide's Far Watch trip at 10.
  - Tauren never pass Thunder Ridge, so the class guide covers them.
- **Lua** (QuestHordeClassWarriorPaladin.lua, Warrior block, after the `warrior-defense-barrens` side guide):

```lua
  -- Path of Defense's Singed Scales drop from Thunder Ridge's Lightning Hides (Stormy Potential's lizards) and the
  -- Thunder Lizards just south of them (QuestieDB item 6486).
  B.hordeInline("northern-durotar", "complete", 97282, {
    B.logOnlyPart(1498, 1, at(nil, 39.6, 27.8, M.durotar),
      "Warriors with Path of Defense: the Lightning Hides here and the Thunder Lizards just south of them also drop Singed Scales. Stay until you have all 5.",
      "5 Singed Scales"),
  })
```

### 3. Warrior: Trial at the Field of Giants 1824

- **Quest:** 1824 (level 20, needs 20, after Speak with Ruga 1823 from Sorek in Orgrimmar). Given and turned in by
  Ruga Ragetotem at Camp Taurajo (44.67, 59.42). Single objective: **1 = 5 Twitching Antenna** (item 7119).
- **Facts:**
  - Antennae drop from Field of Giants silithid:
    - Creeper (20-21) at 45.2, 71.3 / 45.3, 69.5.
    - Grub (20) at 45.0, 71.3 / 44.5, 69.7.
    - Swarmer (21-22) at 44.9, 71.3 / 45.5, 69.5.
    - Harvester (24) and Protector (18-19), one spawn each.
  - **The client gives item 7119 `DurationInInventory = 900` (15 minutes).**
- **Route:**
  - camp-taurajo (25-26) goes to the Field of Giants first (`complete 868` Egg Hunt at 42.9, 69.9), then south to Gann,
    Bael Modan and the Dustwallow border. Antennae from that first visit would decay long before the route returns.
  - So the step goes after `complete 97250` (the Dustwallow border, 49.08, 76.97), the last step before "Ride north
    back to Camp Taurajo". The Field of Giants is on that ride, and Ruga stands beside Jorn, where the route turns in
    next.
  - Scratch check #24: `complete 97250` -> **1824** -> `goto` (Ride north back to Camp Taurajo).
- **Verdict: ADD.**
  - The section is 5-6 levels above the quest, but this is the route's first pass of Camp Taurajo after level 20.
    RestedXP does 1824 at exactly this stop ("Camp Taurajo after Wrongly Blamed").
  - The mobs (20-22) are easy at 25.
- **Lua** (QuestHordeClassWarriorPaladin.lua, Warrior block, after the `warrior-field-of-giants` side guide):

```lua
  -- Trial at the Field of Giants: the antennae (QuestieDB item 7119, silithid around 45, 71) last 15 minutes
  -- (client DurationInInventory 900), so the step sits on the ride back north to Ruga, not on the first Egg Hunt visit.
  B.hordeInline("camp-taurajo", "complete", 97250, {
    B.logOnlyPart(1824, 1, at(nil, 45.1, 70.8, M.barrens),
      "Warriors with Trial at the Field of Giants: on the ride north, stop at the Egg Hunt mounds and kill Silithid Creepers, Grubs and Swarmers for antennae. They decay after 15 minutes, so hand them to Ruga Ragetotem in Camp Taurajo right away.",
      "5 Twitching Antennae"),
  })
```

### 4. Rogue: Plundering the Plunderers 2381

- **Quest:** 2381 (level 18, needs 16, after Wrenix of Ratchet 2382). Given and turned in by Wrenix the Wretched in
  Ratchet (63.07, 36.32), beside the flight master. Single objective: **1 = Southsea Treasure** (item 7968).
- **Facts:**
  - The treasure drops from Polly (npc 7167, level 18).
  - Polly appears from The Jewel of the Southsea (object 123462, Barrens 64.95, 45.44) on the Tide Razor.
  - The Buccaneer's Strongboxes are around 65.05, 45.45.
  - E.C.A.C. = item 7970.
- **Route:**
  - barrens-south (16-18) flies to Ratchet, does its pickups (last: `accept 1069`, Mebok), then `complete 888` Stolen
    Booty at the pirate camps (63.1, 49.4).
  - The ship lies between Ratchet and that camp, so the step goes after `accept 1069` (Zygor's "before Stolen Booty").
  - Scratch check #23: `accept 1069` -> **2381** -> `complete 888`.
- **Verdict: ADD.** Level matches (Pick Lock at 16 is trained at the end of barrens-north).
- **Lua** (QuestHordeClassHunterRogue.lua, Rogue side-guide block, after the `rogue-lockpicking-horde` side guide):

```lua
  -- Plundering the Plunderers: the Tide Razor (Jewel of the Southsea, QuestieDB object 123462) lies between Ratchet
  -- and the camp of Stolen Booty, so Rogues carrying it board the ship on the way south.
  B.hordeInline("barrens-south", "accept", 1069, {
    withItem(7970, B.logOnlyPart(2381, 1, ba("The Jewel of the Southsea", 64.95, 45.44),
      "Rogues with Plundering the Plunderers: the Tide Razor is moored off the pirate camps ahead. Below deck, pick the Buccaneer's Strongboxes for Lockpicking, then open The Jewel of the Southsea, use the E.C.A.C. on Polly and kill her for the treasure.",
      "Southsea Treasure")),
  })
```

### 5. Rogue Mission: Possible But Not Probable 2478 + Druid pendant (one Sludge Fen trip)

- **Quest:** 2478 (level 24, needs 20, after The Shattered Salute 2460 and Deep Cover 2458 from Shenthul in
  Orgrimmar). It has three kill objectives (npcs 7310, 7307, 7308) and three items (Silixiz's Tower Key 8072,
  Gallywix's Head 8074, Cache 8073).
- **Facts:** Grand Foreman Puzik Gallywix (level 23 elite) and his lockbox are at 54.8, 5.6, the Venture Co. tower by
  the Sludge Fen.
- **Route:**
  - The route passes the tower only in barrens-north, at 15-16: the drill site (Ignition 858, The Escape 863 around
    55.5-56.5, 7-8) and the Boulder Lode Mine. That is 4-9 levels before 2478 can be taken.
  - No later section returns. The nearest is the Mor'shan road at the start of ashenvale-splintertree (26), about
    700 yd west of the tower. Its first step is a `goto`, so `hordeInline` (insert after a step) can't put anything
    before it.
- **Verdict: SKIP.**
  - The Rogue part is a full detour with an elite, so it stays in the class guide.
  - For the Druid half at the Sludge Fen, see pairing 7 (also SKIP).

### 6. Shaman: Call of Water 1536 (red waterskin) and 1534 (blue waterskin)

- **Quests:** both given and turned in by Brine (southern Barrens 43.42, 77.41).
  - 1536: level 22, needs 20, after 1535. Single objective: 1 = Filled Red Waterskin (7771). Use the Empty Red Waterskin
    (7768) at the Tarren Mill well.
  - 1534: level 23, needs 20, after 1536. Single objective: 1 = Filled Blue Waterskin (7770). Use the Empty Blue
    Waterskin (7767) at the Ruins of Stardust (AreaTable 418).
  - The use spots (62.17, 20.82 Hillsbrad; 33.5, 67.5 Ashenvale) are our class guide's coordinates. QuestieDB has no
    record for these spell-focus spots.
- **Route:**
  - 1536: hillsbrad (23-25). The first Tarren Mill stop is getfp -> Lydon (`turnin 1065`, `accept 1066/496/501`) ->
    Darthalia. The well (62.17, 20.82) is between Lydon (61.44, 19.06) and Darthalia (62.33, 20.45), so the step goes
    after `accept 501`, Lydon's last pickup. Brief's anchor was 498 (The Rescue); this is earlier, at the same well.
    - Scratch check #8: `accept 501` -> **1536** -> `turnin 494`.
  - 1534: ashenvale-splintertree (26-28). The closest route point to the ruins is Ursangous (`accept 23`, 43.78, 68.86),
    the west end of the Mystral Lake loop, about 10 map units (~600 yd) east of the ruins. The route then rides north
    to Thistlefur.
    - The brief's anchor, Thistlefur 216 (36.2, 36.0), is ~31 units (~1,800 yd) north of the ruins, and the route goes
      east from there.
    - Scratch check #20: `accept 23` -> **1534** -> `goto` Thistlefur.
- **Verdict: ADD (two steps).**
  - Shamans normally carry 1536 into Hillsbrad (the route only visits Eastern Kingdoms at 22-25).
  - camp-taurajo passes Gann and Sulhasa (45.9-47.9, 77), a few steps from Brine, so 1534 is usually in the log by
    Ashenvale.
- **Lua** (QuestHordeClassDruidShaman.lua, Shaman block, after the `shaman-water-totem-horde` side guide):

```lua
  -- Call of Water's waterskins on the route: the Tarren Mill well beside Lydon, and the Ruins of Stardust west of
  -- Ursangous at the end of the Mystral Lake loop.
  B.hordeInline("hillsbrad", "accept", 501, {
    withItem(7768, B.logOnlyPart(1536, 1, at(nil, 62.17, 20.82, m.hillsbrad),
      "Shamans with Call of Water: use the Empty Red Waterskin at the town well, a few steps from Lydon.",
      "Filled Red Waterskin")),
  })
  B.hordeInline("ashenvale-splintertree", "accept", 23, {
    withItem(7767, B.logOnlyPart(1534, 1, at(nil, 33.5, 67.5, m.ashenvale),
      "Shamans with Call of Water: from Ursangous, ride west to the Ruins of Stardust south of Astranaar and use the Empty Blue Waterskin in the pool among the ruins. Watch for Alliance guards.",
      "Filled Blue Waterskin")),
  })
```

### 7. Druid: Trial of the Sea Lion 30 (pendant halves)

- **Quest:** 30 (level 16, needs 16, Druid; after 28 at Moonglade). The **only log objective is 1 = Pendant of the Sea
  Lion** (15885, the joined pendant). The halves are `requiredSourceItems` (15883 Agility, 15882 Endurance), not log
  objectives.
  - So a half step can't complete itself: like our class guide, it needs Next (`objectiveIndex` nil).
  - The engine has no bag-item completion for steps (`Q.itemCount` is only used for start items and the item button).
- **Facts:**
  - Half Pendant of Aquatic Agility: Strange Lockbox 177794 at Barrens 56.7, 8.3, the Sludge Fen (the Darkshore box
    177792 is the Alliance one).
  - Half Pendant of Aquatic Endurance: Strange Lockbox 177790 at Silverpine 29.6, 29.2 (west coast). The Westfall box
    177844 is the Alliance one.
- **Silverpine half: ADD.**
  - sepulcher (22-23), after `turnin 264` (Yuriv's Tombstone, 44.19, 42.67). That is the route's westernmost Sepulcher
    step, about 720 yd south-east of the lockbox, and the last stop before the road south.
  - RestedXP and Zygor both take this half on the 22-24 Hillsbrad trip, the first Eastern Kingdoms visit. Druids who
    don't want a zeppelin trip at 16-18 will carry 30 until then.
  - Scratch check #13: `turnin 264` -> **30** -> `complete 530` (Valdred).
  - **One new audit warning:** "sepulcher step 14: 1677 yd from the prior waypoint with no travel step". The Valdred
    step is now measured from the lockbox, not the tombstone.
    - It is only a warning (the harness passes).
    - To silence it, `questroute.py` could skip logOnly steps when it sets `previous`, since they are conditional.
      That is the implementer's call.
- **Barrens half: SKIP.**
  - The route passes the lockbox itself only in barrens-north at 15-16 (the drill site steps are within 50 yd). Quest 30
    needs 16 plus the Moonglade parts, so it can't be in the log then.
  - The nearest later point is Echeyakee (`complete 881`, barrens-south, 55.8, 17.0), ~880 yd south of the box.
  - Our class guide sends druids to the Sludge Fen first. Without a bag-item check, a logOnly step there would also
    show to druids who already hold this half and only deferred Silverpine.
  - Revisit if steps get an item-held completion. In that case the anchor is `B.hordeInline("barrens-south", "complete",
    881, ...)` at `at(nil, 56.7, 8.3, m.barrens)`.
- **Lua** (QuestHordeClassDruidShaman.lua, Druid block, after the `druid-aquatic-form-horde` side guide):

```lua
  -- Trial of the Sea Lion's Silverpine half (QuestieDB Strange Lockbox 177790, 29.6, 29.2): the closest route point is
  -- the Sepulcher graveyard on the 22-23 visit. The half isn't a log objective, so the step waits for Next.
  B.hordeInline("sepulcher", "turnin", 264, {
    B.logOnlyPart(30, nil, at(nil, 29.6, 29.2, m.silverpine),
      "Druids with Trial of the Sea Lion: before heading south, go north-west from the graveyard to the coast and swim out to the bubbling fissure. Loot the Half Pendant of Aquatic Endurance from the Strange Lockbox beside it and press Next.",
      "Half Pendant of Aquatic Endurance"),
  })
```

### 8. Undead Paladin: A Lesson in Divinity 94434 (10 Linen Cloth)

- **Quest:** 94434 (level 12). Objective 1 = 10 Linen Cloth (2589). **Given by Tanis Alderwood in the Undercity**
  (65.48, 37.49) when you turn in 94427. 94427 is a talk-to quest that Danitha Morr (Bandarion Keep) offers only after
  The Tarnished 91317.
- **Facts:**
  - Bleeding Horror (9-10) at 76.3, 61.6 / 76.1, 59.5 and Wandering Spirit (10-11) at 76.0, 61.1 / 76.5, 58.8 drop
    linen at Balnir Farmstead.
  - Many Tirisfal humanoids drop it too (Scarlet Zealots and Friars and others).
  - Linen Cloth is a normal drop, not a quest drop.
- **Route:**
  - tirisfal does Balnir Farmstead (`complete 1882`, `complete 99142` Tomb Weed at 75.0, 59.4, `complete 356`) **before**
    Bandarion Keep (`accept 91317` ... `turnin 91317`), and the Undercity comes after that.
  - So 94434 can't be in the log at Tomb Weed. Zygor solves this by collecting the linen in advance (its `|future`
    tag), which logOnly can't do: logOnly only shows while the quest is in the log.
- **Verdict: SKIP.**
  - The class guide's 94427 turn-in already says "Bring 10 Linen Cloth", and most characters have 10 linen by level 12.
  - If the owner wants a pre-collect hint, it belongs in that class-guide text (or a future "keep this item" note
    type), not a logOnly step.

---

### Follow-ups (not part of the snippets; owner's call)

- Some logOnly steps fire only for players who already did the class guide's hand-off. In three cases the route already
  stands next to the giver:
  - Ruga (Camp Taurajo: 1823 -> 1824) is beside Mangletooth and Logmar, where camp-taurajo starts.
  - Wrenix (2382 -> 2381) is beside the Ratchet flight master in barrens-south.
  - Brine (1536 -> 1534) is beside Gann's camp in camp-taurajo.
  - Optional inline turn-ins of the previous part (`optional` steps show only while that quest is in the log) would make
    these steps fire for more players. Accept steps can't be logOnly (`questroute.py` requires complete + quest + class),
    so an inline accept would need another gate.
- All coordinates are QuestieDB clusters except the two waterskin spots, which come from our class guide. Check in
  game:
  - The Tarren Mill well.
  - The Ruins of Stardust pool.
  - That Dustwind Cave's cultists are reachable from the 835 ravine.
  - The Silverpine lockbox swim.

