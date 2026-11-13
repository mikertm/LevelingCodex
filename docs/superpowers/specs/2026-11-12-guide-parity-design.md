# Guide feature parity design

The two other Forever leveling guides the owner keeps locally (guide A, the free one, and guide B,
the paid one; the same names as `tools/audits/2026-11-10-guide-cross-reference.md`) offer vendor
helpers, map and minimap navigation, an animated arrow, a progress bar and leveling statistics.
This design brings those to the Codex in four phases, each looking like Forever's own UI: Blizzard
frame art, gossip and cursor icons, the Codex's parchment cards.

Owner decisions (2026-11-12):
- One spec, four phases, built and installed one at a time so each can be tested in game.
- Vendor: grey items sell and gear repairs by themselves when a vendor opens (on by default, Alt
  holds them back); guide purchases wait for one click on a card beside the vendor window.
- A Stats tab with leveling splits, gold, activity and per-zone stats.
- Minimap: pins for the current and next steps plus a dotted line toward the current one; the same
  pins on the world map.
- Arrow: draggable anywhere, Ctrl+wheel to resize; on arrival it turns into the step's icon,
  bobbing, over a gold ring that pulses once.
- Quests tab: a fixed top (step card with the completion bar, one row of step buttons) and four
  sub-tabs: Step, Route, Guides, Quest log.

Left out on purpose: gear scoring and auto-equip (a project of its own), deleting junk when bags
are full (needs hardware-event hooks), buying at the class trainer (the Codex never buys there),
hearthstone batching (Forever blocks addons from confirming the bind popup).

## How the two guides do it (features only, nothing copied)

| Feature | Guide A | Guide B |
|---|---|---|
| Sell junk | On MERCHANT_SHOW after a short delay, greys and a personal list, all in one pass, prints the total | Greys only (quest items skipped), one item per 0.1 s with `C_Container.UseContainerItem`, aborts if the vendor closes, a "Sell Grays" button on the vendor |
| Repair | none | One frame after MERCHANT_SHOW, own money or guild funds, off by default |
| Buy for later | Silent auto-buy of a step's `buy` items, capped by stock, in max-stack chunks | One-click card right of the vendor listing the step's buy goals and the total, with a Buy button |
| Minimap | Step pins (HereBeDragons), floating on the edge | Pins, an edge arrow when out of range, an animated travel line clipped to the round minimap |
| Arrow | Movable, scalable, no arrival effect | Movable, Ctrl+wheel scale, a bouncing "here" sprite on arrival, ETA |
| Progress | none | A thin bar under the steps (steps, quests or XP), animated with an ease-out |
| Stats | Level splits, XP by quests/mobs per zone, deaths | Gold tools (not leveling stats) |

## Phase 1: Vendor helper

New module `Vendor.lua` (`ns.vendor`), loaded after `TrainerGuide.lua`. Events: MERCHANT_SHOW,
MERCHANT_CLOSED, MERCHANT_UPDATE, BAG_UPDATE_DELAYED, PLAYER_MONEY (each registered with `pcall`).
Selling and repairing don't start in combat or while Alt is held when the vendor opens; the
shopping card still shows (it only buys on a click).

### Selling junk (`db.noAutoSell`, Settings > Vendor > "Sell grey items at vendors", on)

- Junk: bag items (bags 0-4) of Poor quality with a sell price above 0, read with
  `C_Container.GetContainerItemInfo` (quality, `hasNoValue`, `itemID`, `stackCount`, `isLocked`)
  else the classic `GetContainerItemInfo` returns, and `GetItemInfo`'s sell price. Kept: the
  Hearthstone (6948), any item a pending route step names (`collect`/`buy` items, `startItem`s,
  `ns.questShop` items), locked items.
- Sells one stack every 0.15 s (`ns.after` chain) with `C_Container.UseContainerItem`, else
  `UseContainerItem`. Stops when MERCHANT_CLOSED fires or `MerchantFrame` hides; a stopped run says
  how much it sold so far.
- Chat, once per visit: "Sold 7 grey items for 1s 42c." (`ns.money`). Nothing when nothing sold.

### Repair (`db.noAutoRepair`, "Repair at vendors", on)

- After the junk run (or at once with no junk): `CanMerchantRepair()`, `GetRepairAllCost()`; with a
  cost above 0 and `GetMoney()` at least the cost, `RepairAllItems()` (own money: Forever has no
  guild bank). Chat: "Repaired for 2s 10c." or "Not enough money to repair (2s 10c)."

### Shopping card (`db.noShopCard`, "Show what to buy for the guide", on)

- `ns.vendor.needs()`: items the route needs soon. "Soon" = pending rows from the current step to
  the end of the next section on the route (`Q.upcoming`). Sources:
  - `buy` and `collect` steps with `item` (and `count`, default 1) or `items = { {id, count}, ... }`;
  - quests in those rows with `ns.questShop[questID]` entries (below), while the quest is not turned
    in and its item objective is not finished. Once the quest is in the log, the log's objective
    ("0/3 Soothing Spices") gives the count; before that, the generated count.
  Need = count minus `GetItemCount`. The same item for different steps adds up.
- On MERCHANT_SHOW (and MERCHANT_UPDATE, BAG_UPDATE_DELAYED while open) the card scans the vendor:
  `GetMerchantNumItems`, `GetMerchantItemID(i)` (else the ID from `GetMerchantItemLink`),
  `GetMerchantItemInfo(i)` (else `C_MerchantFrame.GetItemInfo(i)`): price, units per purchase,
  stock (`-1` = unlimited), extended cost (skipped).
- The card `LevelingCodexShopCard`: dialog backdrop, "FOR YOUR GUIDE", one row per item (icon,
  "3 x Soothing Spices", the price on the right, "for Swamp Eye Jarl" under it), then one button:
  "Buy for 1s 50c", or a disabled "Need 1s 50c more" when gold is short, or "Only 2 in stock" noted
  on the row. Placed with `ns.placeByWindow(card, MerchantFrame)` like the trainer card; hidden at
  MERCHANT_CLOSED and on `MerchantFrame`'s OnHide; empty = hidden.
- Buy: for each row, `BuyMerchantItem(i, n)` in chunks of `GetMerchantItemMaxStack(i)` (else the
  item's stack size, else 20), capped by stock. Chat: "Bought 3 Soothing Spices for 1s 50c." The
  later buy step ticks itself off through the existing bag count (`haveItems`).
- Controller: the card is attached with `ns.gamepad.attach(card, { popup = true })` so Buy is
  reachable.

### Route data

- Existing buy steps get item IDs (checked with `questfacts.py item`): Fine Thread, Soothing Spices
  (Alliance and Horde), Barbecued Buzzard Wings and Junglevine Wine (Smotts' Cutlass). Steps that
  point at the Auction House stay text-only.
- `tools/questshop.py` writes the generated `QuestShopData.lua` (`ns.questShop[questID] =
  { { item, count }, ... }`), loaded after `QuestMobData.lua`: for every route quest (both
  factions, `questroute.ROUTES`), its QuestieDB item objectives whose item has `vendors` and no
  `npcDrops`/`objectDrops`/`itemDrops`. The count comes from the quest's objective text ("Bring 3
  Soothing Spices"); when the text doesn't name a count for the item, the count is 1 and the card
  waits for the quest log. `--check` fails when stale; the harness checks the shape.
- Every buy step added or changed is listed in `tools/audits/2026-11-12-vendor-steps.md`.

## Phase 2: Stats tab

New module `Stats.lua` (`ns.stats`), loaded after `QuestTab.lua` so the tab sits after Quests;
`ns.addTab("stats", "Stats", render)`.

### Storage

- `ns.stats.session` (always) and `ns.charDB().stats` (when saved data loads; `version = 1`), both
  updated by `ns.stats.add(path, amount)`. With `ns.settingsLost`, the tab heads its cards with
  "Counting since you logged in".
- `stats.levels[level] = { seconds, questXP, killXP, otherXP, rested, quests, kills, deaths,
  goldIn = { quest, loot, junk, sales, other }, goldOut = { repair, training, flights, buys, other } }`
- `stats.zones[mapID] = { name, seconds, xp, quests }` (the zone-level map: `C_Map.GetMapInfo`
  parents walked up to a Zone map)
- `stats.totals = { quests, kills, deaths, flights, flightSeconds, hearths, dungeons, bosses }`
- `stats.played = { total, level, at }` from TIME_PLAYED_MSG when the player types `/played` (the
  Codex never calls `RequestTimePlayed`, which prints to chat).

### What feeds it

- XP: `Pace.lua` already splits gains into quest, kill and other; it calls `ns.stats.xp(kind,
  amount)` where it classifies them. Rested used: drops in `GetXPExhaustion()` between XP updates.
- Time: one `ns.every(1)` tick adds a second to the level and the current zone (not while dead or on
  a taxi for zones: a flight's time goes to `flightSeconds`).
- Gold: PLAYER_MONEY deltas, filed by context: a QUEST_TURNED_IN money reward (third argument) =
  quest; a loot window open (LOOT_OPENED/LOOT_CLOSED) = loot; the Vendor module's own sales = junk;
  other increases while a vendor is open = sales; the Vendor module's repairs and drops in
  `GetRepairAllCost()` = repair; other decreases at a vendor = buys; decreases while a trainer is
  open = training; a decrease within 5 s of TakeTaxiNode = flights; everything else = other.
- Activity: QUEST_TURNED_IN, Pace's kill count, PLAYER_DEAD, the TakeTaxiNode hook and the flight
  timer in QuestGuide.lua (`ns.stats.flight(seconds)` on landing), UNIT_SPELLCAST_SUCCEEDED for the
  Hearthstone spell (8690, registered with `pcall`), `Q.enteredDungeon` for a new instance and
  `Q.bossDown` for a boss.

### Layout (parchment cards, `ns.ui`)

1. THIS SESSION: time, XP per hour, gold per hour, quests, kills, deaths.
2. LEVEL SPLITS: a table of the last 10 levels (level, time, quest/kill XP share, kills, deaths, net
   gold), with Show all; the current level marked. Played time from the last `/played`.
3. GOLD: in and out by source, this session and all saved, net per level.
4. ACTIVITY: the totals.
5. ZONES: the top 8 zones by time with XP and quests, Show all.
6. Reset stats (two clicks within 5 s, like Abandon).

The Codex's tab row gains a ninth tab. When the row of tabs is wider than the window (summed
`GetWidth()` after layout), every tab gets the same smaller width so the row fits; checked in game.

## Phase 3: Navigation

### Step icons

`ns.questIcon(step)` returns a texture path for a step, used by the arrow, the minimap, the world map
and the step window: accept `Interface\GossipFrame\AvailableQuestIcon`, turn-in
`ActiveQuestIcon`, kill objective `Interface\Cursor\Attack`, item objective `Interface\Cursor\LootAll`
(kill or item from the objective text: "slain"/"killed" or a kill-credit list in `ns.questMobs`
with no item), flight path and Fly `TaxiGossipIcon`, bind and hearth `BinderGossipIcon`, buy
`VendorGossipIcon`, train `TrainerGossipIcon`, boss and dungeon
`Interface\TargetingFrame\UI-TargetingFrame-Skull`, everything else the gold ring. Each file is
probed once (`A.hasFile`); a missing one falls back to a gold dot drawn with a colour texture.

### Arrow

- `LevelingCodexQuestArrow` moves to UIParent. Without `db.questArrowPos` it keeps today's anchor
  (BOTTOM to the step window's TOP, 6 px); the window keeps its clamp insets only while the arrow is
  anchored to it. It shows and hides with the step window.
- A 48 x 48 handle over the arrow art takes the mouse: left-drag moves the arrow (not with
  `db.questArrowLocked`) and saves `db.questArrowPos`; Ctrl+mouse wheel sets `db.questArrowScale`
  (0.6-2.0, steps of 0.1). The rest of the frame, with its text, ignores the mouse.
- Arrival state (`db.noArrowBounce` turns the animation off): when the waypoint is within
  `Q.arrived()`, or QuestieDB's nearest spawn is "nearby", or the corpse is here. The arrow art
  hides; the step icon (36 px) shows and loops a Translation animation (8 px up, 0.4 s, BOUNCE);
  the ring (`Interface\TaxiFrame\UI-Taxi-Icon-Highlight`, additive, gold) plays once: scale 0.6 to
  1.4 and alpha 1 to 0 over 0.6 s. The text reads the step's NPC over "Arrived" (path stops:
  "Arrived (way in 2 of 3)"); QuestieDB's spawn keeps its "<mob> nearby" and the corpse its "Your
  corpse is here". Entering the state starts the animations; leaving it stops them and
  shows the arrow again. Missing animation support: the icon shows without moving.
- Settings: Lock the arrow, Arrow size -/+, Reset arrow (clears the position and scale), Animate the
  arrow on arrival.

### Minimap (new `QuestMap.lua`, `ns.questMap`, loaded after `QuestGuide.lua`)

- Pins are textures on a frame parented to `Minimap` (frame level above Blizzard's): the current
  step's icon pin (16 px) and the next two steps' pins (10 px, 60% alpha, a small number), on the
  same map (`Q.vector`) or across a zone border (`Q.worldVector`). Steps without a spot get no pin.
- Placement: east and north yards times pixels per yard, where pixels per yard = half the minimap's
  width / its view radius. View radius: `C_Minimap.GetViewRadius()` when present, else the classic
  diameters by `Minimap:GetZoom()`, outdoor 466.7/400/333.3/266.7/200/133.3 yd and indoor (by
  `IsIndoors()`) 300/240/180/120/80/50 yd. With the `rotateMinimap` CVar on, the offset turns by the
  player's facing.
- Out of range: a round minimap (`GetMinimapShape()` nil or "ROUND") clips at 95% of the radius, a
  square one at the box's edge. The current pin then becomes a 14 px edge arrow (the arrow texture
  turned toward the step); the next-step pins hide.
- Dotted line (`db.noMinimapLine`): gold dots (3 px, 70% alpha) every 10 px from 8 px off the
  centre to the current pin or the rim, drifting 10 px per second toward the pin.
- Updates every 0.05 s while the minimap and the step window are shown; it rebuilds the pin list
  only when the step changes. Hidden in instances where `Q.position` gives no coordinates.
- Settings: Show steps on the minimap (`db.noMinimapSteps`), Dotted line to the step.

### World map

- The same pins (current 20 px, next ones 14 px with a number) on a frame on
  `WorldMapFrame.ScrollContainer.Child`, for steps on the map the world map shows
  (`WorldMapFrame:GetMapID()`), redrawn on the map's OnShow, after `WorldMapFrame.OnMapChanged`
  (hooked with `hooksecurefunc` when it exists) and on refresh. Hovering a pin shows its label and
  text in a tooltip. The game's own waypoint stays on the current step (`db.noQuestMapPin`).
- Setting: Show steps on the world map (`db.noWorldMapSteps`).

## Phase 4: Step window and Quests tab

### Completion bar

- `Q.stepProgress(section)` = (steps passed, steps counted): rows of the section that aren't
  `filtered`, grey or hidden optional; passed = done, skipped or deferred.
- In the step window, under the title: a 6 px bar, full content width, dark track and 1 px edge,
  the theme accent as fill (`Interface\TargetingFrame\UI-StatusBar`, else a colour texture), "62%"
  at its right end. A new value slides over 0.5 s with an ease-out (OnUpdate while it moves).
  Tooltip: "<guide>: 18 of 29 steps, 7 of 12 quests turned in" (`Q.sectionProgress`). Click opens
  Quests > Route. Setting: Show the completion bar (`db.noStepBar`).

### Step window polish

- The step's icon (16 px) before the title.
- A goal row whose count rose since the last draw flashes: a gold highlight fading from 0.6 to 0
  over 0.5 s.
- A step the game finished (the existing completion-sound moment) flashes the window's edge: a
  gold border glow fading over 0.4 s.

### Quests tab

- Fixed top: "Quest Guide" and a small Setup button on the right (the setup card still opens by
  itself for new characters); the step card with the completion bar; one row: Previous step,
  Next step, Show on map, Hide step window / Show step window (today's labels).
- Sub-tabs (selected-state buttons, remembered for the session):
  - Step: Plan/Skip run, Run <dungeon>, Plan <related guide>, route options for your level,
    Resume active quest or Return to leveling, Nearest flight master; a footer with Report this
    step and Copy recorder log.
  - Route: this guide's steps and Show all steps.
  - Guides: the search box; level bands with yours and the next open and the others folded into a
    clickable one-line header ("LEVELS 1-12: 5 guides, all done"); Dungeons with Plan
    recommended/all/none; Special quest chains; Class quests. A guide's page opens here with a Back
    link.
  - Quest log: Active quests (N/M) with Show and Track, Ready to turn in, Missed quests,
    Outleveled, Quest log cleanup.
- `ns.openQuestGuide(section)` opens Guides at that guide; the step window's Quests button opens
  Step.

## Testing

- Mock additions (`tests/wowmock.lua`): a merchant (`MOCK.merchant = { items = { {id, name, price,
  per, stock, maxStack} }, repairCost, canRepair }`, records `MOCK.bought`, `MOCK.sold`,
  `MOCK.repaired`; MERCHANT_* events; `MerchantFrame`), bag item quality and sell price, money
  changes (`MOCK.money` fires PLAYER_MONEY), `GetXPExhaustion`, TIME_PLAYED_MSG, LOOT_OPENED and
  LOOT_CLOSED, `rotateMinimap`, `Minimap:GetZoom`, `IsIndoors`, `C_Minimap.GetViewRadius`
  (absent in `minimal`), a `WorldMapFrame` with `ScrollContainer.Child` and `GetMapID`, animation
  types Translation, Scale and Alpha with `IsPlaying`, and mouse wheel scripts.
- Scenarios: `vendorJunk` (sells greys one by one, keeps guide items and the Hearthstone, stops when
  the vendor closes, Alt holds it back), `vendorRepair`, `vendorShopping` (the card lists a coming
  quest's vendor item, buys it in stacks, the buy step ticks off), `statsCounters` (XP, gold by
  source, activity), `statsTab` (renders with and without saved data, Reset), `arrowMove` (drag
  saves, wheel scales, lock, reset), `arrowArrival` (enters and leaves the state, animations play),
  `minimapPins` (offset for a known vector, rotation, edge clamp round and square, the line),
  `worldMapPins`, `stepProgress` (bar value and tween end), `questTabViews` (each sub-tab draws, the
  library opens in Guides). Each runs in the full, minimal and controller runs.
- The harness checks the shape of `ns.questShop` (like QuestMobData); `tools/questshop.py --check`
  reports staleness when run by hand after route changes.
- Each phase ends with `python tests/run.py`, `python tools/install.py` and a list of things to
  check in game.

## To check in game

- Selling, buying and repairing are allowed for addons on Forever (a block shows in chat and in
  `/codex debug`).
- Whether the game's own waypoint already shows on the minimap (two pins for the current step).
- The icon files exist on Forever (a missing one shows a gold dot).
- Nine tabs fit under the Codex window.
