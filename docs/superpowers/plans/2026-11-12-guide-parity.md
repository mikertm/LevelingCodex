# Guide Feature Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor helper, Stats tab, movable animated arrow with minimap/world-map pins, and a completion bar plus a sub-tabbed Quests tab, in four phases that each ship to the owner's game.

**Architecture:** Four new modules (`Vendor.lua`, `Stats.lua`, `QuestMap.lua`, generated `QuestShopData.lua` from `tools/questshop.py`) plus changes to `QuestGuide.lua` (arrow, bar, flashes), `QuestTab.lua` (sub-tabs), `Quests.lua` (`items` on buy steps, progress), `Window.lua` (settings, tab fit). Every module reads the client through guarded calls and talks to others through `ns.*` at call time.

**Tech Stack:** WoW addon Lua 5.1 (Forever, Interface 16001); test harness `tests/run.py` (Python + lupa) with the strict client mock `tests/wowmock.lua` and player-level scenarios in `tests/scenarios.lua`; QuestieDB cache tools in `tools/`.

**Spec:** `docs/superpowers/specs/2026-11-12-guide-parity-design.md`

## Global Constraints

- Lua 5.1 only: no `goto`, no `//`, no `\u{}`. All runtime text ASCII (route guide text through `Q.plain`/`ns.plain`).
- No new globals except named frames `LevelingCodex*` (the harness fails on leaks).
- Register every event beyond the core ones with `pcall` (an unknown event aborts the file in Forever). Add each new event to the mock's known and optional lists.
- Guard every non-core API (`type(fn) == "function"`, `ns.try`/`Q.try`); the minimal mock run removes optional APIs.
- Textures: probe with `ns.art.hasFile` (or `ns.setIcon`); a missing file must never render green.
- Never touch `COMBAT_LOG_EVENT_UNFILTERED`, never accept/hide Blizzard popups, never change secure frames in combat.
- Settings that default on use `db.no<Name>` keys; off-by-default ones use positive keys.
- Never depend on SavedVariables loading back: everything works with empty `LevelingCodexDB`/`LevelingCodexCharDB`.
- `LevelingCodex.toc` and `LevelingCodex_Camelot.toc` stay byte-identical; keep `## Version: @project-version@`.
- Before every commit: `python tests/run.py` passes except `WARRIOR/full/blocked-report`, which always fails in a `.claude/worktrees` checkout (the folder isn't named LevelingCodex).
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Install for in-game tests with `python tools/install.py`, after checking that the installed build's commit (the `-g<hash>` in the installed `.toc` `## Version`) is an ancestor of HEAD (`git merge-base --is-ancestor <hash> HEAD`). If it isn't, stop and ask the owner.
- Never push a tag.

## Review Focus

1. The bag changes between the junk scan and a sale (the slot now holds another item): that slot is skipped, never a non-grey sold. Test in Task 1.
2. A grey whose `GetItemInfo` isn't cached yet: skipped, no error. Test in Task 1.
3. Saved stats of the wrong shape (`LevelingCodexCharDB.stats = "x"` or an old version): replaced by a fresh table, no error. Test in Task 7.
4. A minimap with no usable scale (view radius 0, no zoom API): pins hidden, no error. Test in Task 12.
5. A saved arrow scale out of bounds (9): applied as 2.0. Test in Task 10.

---

## Phase 1: Vendor helper

### Task 1: Sell junk at vendors

**Files:**
- Create: `Vendor.lua`
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (add `Vendor.lua` after `TrainerGuide.lua`), `Init.lua` (call `ns.startVendor()` after `ns.startTrainerGuide()`; add `ns.vendorDebugLines()` to `/codex debug`), `Quests.lua` (`Q.routeItems`), `Window.lua` (Settings > VENDOR, above QUEST GUIDE)
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces: `ns.startVendor()`; `ns.vendor.selling` (true while a run is going); `ns.vendor.onSold(copper)` hook point used by Task 7 (call `ns.stats.expect("junk", copper)` there once Stats exists); `Q.routeItems() -> { [itemID] = true }`: every item a route step names (`item`, each `items[i][1]`, `startItem`), built in `buildRoute`; `ns.vendorDebugLines() -> { string }`.
- Mock produces: `MOCK.merchant = { items = { { id, name, price, per = 1, stock = -1, maxStack = 20 } }, canRepair = false, repairCost = 0 }`, `MOCK.openMerchant(m)`, `MOCK.closeMerchant()`, `MOCK.setMoney(copper)` (fires PLAYER_MONEY), `MOCK.sold` (list of `{ id, count }`), `MOCK.bought`, `MOCK.repaired`, global `MerchantFrame` (hidden frame). `MOCK.bagItems[i]` gains `id`, `sell` (per unit), `count`, `locked`, `empty`.

- [ ] **Step 1: Extend the mock**

In `tests/wowmock.lua`:
- Add `MERCHANT_SHOW`, `MERCHANT_CLOSED`, `MERCHANT_UPDATE`, `PLAYER_MONEY` to the known + optional event loop.
- `C_Container.GetContainerItemInfo(bag, slot)` returns `nil` for an `empty` slot, else `{ itemID = it.id or 90000 + slot, hyperlink = bagLink(slot), stackCount = it.count or 1, quality = it.quality, hasNoValue = (it.sell == 0), isLocked = it.locked or false }`.
- `GetItemInfo` skips `empty` entries and returns `it.sell or 1` as the 11th value.
- Add `C_Container.UseContainerItem(bag, slot)`: when `MerchantFrame:IsShown()` and the slot holds an item, record `{ id, count }` in `MOCK.sold`, set the slot to `{ empty = true }`, and `MOCK.setMoney(money + sell * count)`.
- Add the merchant API reading `MOCK.merchant`:
  - `GetMerchantNumItems`, `GetMerchantItemID(i)`, `GetMerchantItemLink(i)`.
  - `GetMerchantItemInfo(i)` returns name, 134400, price, per, stock, true, true, false.
  - `GetMerchantItemMaxStack(i)`.
  - `BuyMerchantItem(i, n)`: records `{ id, n or per }`, adds to `MOCK.bags[id]`, takes the money.
  - `CanMerchantRepair()`, `GetRepairAllCost()` returns cost, cost > 0.
  - `RepairAllItems()`: `MOCK.repaired = cost`, takes the money, sets `repairCost = 0`.
- Add the merchant API names and `MerchantFrame` to `OPTIONAL`.

- [ ] **Step 2: Write the failing scenario**

```lua
-- Vendor: greys sell one by one when a vendor opens, guide items and the Hearthstone are kept.
function S.vendorJunk()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "collect", item = 3301, count = 1, name = "Kept Fang", text = "Keep it." })
    end
  end
  S.login()
  MOCK.money = 0
  MOCK.bagItems = {
    { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 12, count = 3 },
    { name = "Linen Cloth", id = 2589, quality = 1, level = 1, sell = 13 },
    { name = "Kept Fang", id = 3301, quality = 0, level = 1, sell = 5 },
    { name = "Hearthstone", id = 6948, quality = 0, level = 1, sell = 5 },
    { name = "Odd Rag", id = 3302, quality = 0, level = 1, sell = 4, loaded = false },
    { name = "Torn Ear", id = 3303, quality = 0, level = 1, sell = 0 },
    { name = "Chipped Claw", id = 3304, quality = 0, level = 1, sell = 7 },
  }
  MOCK.openMerchant({ items = {} })
  if MOCK.minimal then
    MOCK.advance(2)
    check(#MOCK.sold == 0, "no selling without the container APIs")
    return
  end
  MOCK.advance(0.2)
  check(#MOCK.sold == 1 and MOCK.sold[1][1] == 3300, "the first grey sells right after the vendor opens")
  MOCK.bagItems[7] = { name = "Silk Cloth", id = 4306, quality = 1, level = 1, sell = 150 }
  MOCK.advance(2)
  check(#MOCK.sold == 1, "a slot that changed since the scan is skipped (Silk Cloth stays)")
  check(MOCK.money == 36 and chatHas("Sold 1 grey item for 36c%."), "one chat line with the total")
  MOCK.closeMerchant()
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 12 },
    { name = "Chipped Claw", id = 3304, quality = 0, level = 1, sell = 7 } }
  MOCK.sold = {}
  MOCK.openMerchant({ items = {} })
  MOCK.advance(0.2)
  MOCK.closeMerchant()
  MOCK.advance(2)
  check(#MOCK.sold == 1 and chatHas("the vendor closed"), "closing the vendor stops the run and says so")
  MOCK.sold, MOCK.alt = {}, true
  MOCK.openMerchant({ items = {} })
  MOCK.advance(2)
  check(#MOCK.sold == 0, "Alt holds selling back")
  MOCK.alt = false
  MOCK.closeMerchant()
  LevelingCodexDB.noAutoSell = true
  MOCK.openMerchant({ items = {} })
  MOCK.advance(2)
  check(#MOCK.sold == 0, "Settings can turn selling off")
end
```

In `tests/run.py`, add `runs.append(("WARRIOR/%s/vendor-junk" % variant, "WARRIOR", minimal, ["vendorJunk"]))` next to the class-trainer run, so it covers both variants.

- [ ] **Step 3: Run it and see it fail**

Run: `python tests/run.py -k vendor`
Expected: FAIL in `vendorJunk`, "the first grey sells right after the vendor opens".

- [ ] **Step 4: Implement `Vendor.lua` junk selling**

- On MERCHANT_SHOW: if `db.noAutoSell`, `InCombatLockdown()` or `IsAltKeyDown()`, skip; else scan bags 0-4 into a queue of `{ bag, slot, id, count, sell }`.
  - Junk: quality 0 (from the container info, else `GetItemInfo` 3rd).
  - It must have a sell price > 0 (`GetItemInfo` 11th; `hasNoValue` means 0) and not be locked.
  - Skip `id == 6948`, any `Q.routeItems()[id]`, and any `ns.questShop` item (`ns.questShop` may be nil until Task 4).
  - Skip an item whose `GetItemInfo` is nil.
- Selling: one queued slot per `ns.after(0.15, ...)` step, the first 0.15 s after MERCHANT_SHOW.
  - Before each sale, re-read the slot and skip it if its `itemID` or count changed.
  - Call `ns.vendor.onSold(sell * count)` (a no-op for now) just **before** the sale. Stats files the PLAYER_MONEY that follows, and the mock fires it inside the sell call.
  - Sell with `C_Container.UseContainerItem` (else the classic `UseContainerItem`), and add `sell * count` to the run's total.
- MERCHANT_CLOSED (or `MerchantFrame` hidden at the next step) ends the run.
- At the end, if anything sold: `ns.say("Sold N grey item(s) for " .. ns.money(total) .. ".")`. If the vendor closed mid-run, add `" (the vendor closed)"` before the full stop.
- Settings, in `Window.lua`: `head("VENDOR")`, then the tick "Sell grey items at vendors" (`noAutoSell`). Tooltip: "When you open a vendor, grey items with a sell price are sold one by one. Items a guide step needs and your Hearthstone are kept. Hold Alt to stop it."

- [ ] **Step 5: Run it and see it pass**

Run: `python tests/run.py -k vendor`
Expected: both `vendor-junk` runs PASS.

- [ ] **Step 6: Full harness, then commit**

Run: `python tests/run.py`. Expected: everything passes except `WARRIOR/full/blocked-report`.

```bash
git add Vendor.lua LevelingCodex.toc LevelingCodex_Camelot.toc Init.lua Quests.lua Window.lua tests/wowmock.lua tests/scenarios.lua tests/run.py
git commit -m "Vendor: sell grey items when a vendor opens, keeping guide items"
```

### Task 2: Repair at vendors

**Files:**
- Modify: `Vendor.lua`, `Window.lua`
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: the junk run's end from Task 1.
- Produces: `ns.vendor.onRepaired(copper)` hook point (Task 7 wires it to `ns.stats.expect("repair", copper)`).

- [ ] **Step 1: Write the failing scenario**

```lua
function S.vendorRepair()
  S.login()
  if MOCK.minimal then return end
  MOCK.money = 150
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 100 } }
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(2)
  check(MOCK.repaired == 210 and chatHas("Repaired for 2s 10c%."), "repairs after the junk money comes in")
  MOCK.closeMerchant()
  MOCK.repaired, MOCK.money, MOCK.bagItems = nil, 100, {}
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(not MOCK.repaired and chatHas("Not enough money to repair %(2s 10c%)%."), "says when money is short")
  MOCK.closeMerchant()
  MOCK.money, MOCK.alt = 1000, true
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(not MOCK.repaired, "Alt holds repairing back")
  MOCK.alt = false
  MOCK.closeMerchant()
  LevelingCodexDB.noAutoRepair = true
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(not MOCK.repaired, "Settings can turn repairing off")
end
```

Add the run `"WARRIOR/%s/vendor-repair"` with `["vendorRepair"]`.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k vendor-repair`. Expected: FAIL, "repairs after the junk money comes in".

- [ ] **Step 3: Implement repair**

When the junk run ends (or at once when the queue is empty):
- Skip it with `db.noAutoRepair`, combat or Alt held at open, or when `CanMerchantRepair()` isn't true.
- `local cost = GetRepairAllCost()`; with `cost > 0`:
  - if `GetMoney() >= cost`: `ns.vendor.onRepaired(cost)` (before the call), then `RepairAllItems()` and `ns.say("Repaired for " .. ns.money(cost) .. ".")`;
  - else `ns.say("Not enough money to repair (" .. ns.money(cost) .. ").")`.
- Settings: the tick "Repair at vendors" (`noAutoRepair`). Tooltip: "Repairs all your gear with your own money when you open a vendor that repairs. Hold Alt to stop it."

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k vendor`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Vendor.lua Window.lua tests/scenarios.lua tests/run.py
git commit -m "Vendor: repair with your own money after selling junk"
```

### Task 3: Item IDs on buy steps

**Files:**
- Modify: `Quests.lua` (`haveItems`, collect-item registration, `Q.routeItems`), `QuestData3040.lua:291,386,1288`, `QuestHorde3040.lua:767,1180`, `QuestHorde5060.lua:215`
- Create: `tools/audits/2026-11-12-vendor-steps.md`
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces: a buy or collect step may carry `items = { { itemID, count }, ... }` (with or without `item`). It is done once the bags hold every listed count. `Q.routeItems()` includes these items.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.questBuyItems()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "buy", items = { { 2320, 1 }, { 3713, 2 } }, name = "Thread and spices",
        text = "Buy Fine Thread and two Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  MOCK.bags[2320] = 1
  S.login()
  local frame = questViewer()
  check(questText(frame, "Buy - Thread and spices"), "a buy step with two items waits for both")
  MOCK.bags[3713] = 2
  MOCK.event("BAG_UPDATE_DELAYED")
  check(not questText(frame, "Buy - Thread and spices"), "it ticks off once the bags hold every item")
end
```

Add `"questBuyItems"` to the `WARRIOR/full/quests-*` list in `tests/run.py`.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k questBuyItems`. Expected: FAIL, "it ticks off once the bags hold every item".

- [ ] **Step 3: Implement `items` support**

- `haveItems(s)`: true when every `{ id, n }` in `s.items` has `Q.itemCount(id) >= n` (and `s.item` as today, when present).
- `buildRoute`: register each `s.items` id in `collectItems` and in the `Q.routeItems` set.
- The bag-count goal rows in `QuestGuide.lua`'s `itemCounts` show the first missing item of `items`.

- [ ] **Step 4: Add the item IDs to the route data**

Check each ID and count with `tools/.cache/quest-venv/Scripts/python.exe -I tools/questfacts.py item <id>`, and the quest's objective text with `questfacts.py quest <id>`. Then set:

| File and line | Item IDs and counts |
|---|---|
| `QuestData3040.lua:291` (Micha Yance) | Fine Thread 2320 and Soothing Spices 3713; counts from quest 555 and the Fine Thread quest the step serves |
| `QuestData3040.lua:386` and `:1288` | `{ item = 3713, count = 3 }` (quest 1218) |
| `QuestHorde3040.lua:1180` | `{ item = 3713, count = 3 }` |
| `QuestHorde5060.lua:215` | add Junglevine Wine (confirm its ID) as `items = { { 4457, 10 }, { <wine>, 5 } }` |

Leave the Auction House steps (`QuestData3040.lua:1096`, `QuestData4050.lua:570`, `QuestData5060.lua:207`, `QuestSpecialData.lua:359`) text-only. Write `tools/audits/2026-11-12-vendor-steps.md`: one row per changed step, with before, after and the source of each ID and count, so the owner can mirror them in the guide pages.

- [ ] **Step 5: Run the harness and the route audit**

Run: `python tests/run.py`, then `tools/.cache/quest-venv/Scripts/python.exe tools/questroute.py audit` (without `-I`). Expected: PASS, and no new audit errors.

- [ ] **Step 6: Commit**

```bash
git add Quests.lua QuestGuide.lua QuestData3040.lua QuestHorde3040.lua QuestHorde5060.lua tools/audits/2026-11-12-vendor-steps.md tests/scenarios.lua tests/run.py
git commit -m "Buy steps: item IDs and counts, and steps that list several items"
```

### Task 4: Generated vendor-only quest items (`QuestShopData.lua`)

**Files:**
- Create: `tools/questshop.py`, `QuestShopData.lua` (generated)
- Modify: `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` (after `QuestMobData.lua`), `tests/run.py` (`quest_shop_checks()` added beside `quest_mob_checks()` in `data_checks`'s return)

**Interfaces:**
- Produces: `ns.questShop[questID] = { { itemID, count }, ... }`.
- Tool functions:
  - `route_quests(data) -> set[int]`: every quest any route step names, of any step type.
  - `shop_for(quest, items) -> list[tuple[int, int]]`
  - `build() -> str`
  - `main()` with `--check`

- [ ] **Step 1: Write the failing harness check**

`quest_shop_checks()` in `tests/run.py` loads `QuestShopData.lua` the way `quest_mob_checks()` loads its file and fails on:
- a missing file, or no `ns.questShop`;
- a key that isn't an int;
- an entry list outside 1-6 entries;
- an item ID that isn't an int > 0;
- a count outside 1-100.

It also requires `questShop[1218]` to hold `{ 3713, 3 }`, which proves the generator reads vendors and counts.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k nothing`. The data checks still run. Expected: `FAIL quest shop: QuestShopData.lua missing`.

- [ ] **Step 3: Write `tools/questshop.py`**

Model it on `tools/questmobs.py`: same imports, `HEADER`, `render`, `--check`, `OUT = ROOT / "QuestShopData.lua"`. For each route quest:
- take its QuestieDB item objectives (`objectives[3]`);
- keep items with `vendors` and none of `npcDrops`, `objectDrops`, `itemDrops`;
- count = the first match of `(\d+)\s+<item name>` (case-insensitive) in the quest's `objectivesText` lines, else 1.

Output lines read `  [1218] = { { 3713, 3 } },`.

- [ ] **Step 4: Generate the file and see the check pass**

Run: `tools/.cache/quest-venv/Scripts/python.exe -I tools/questshop.py`, then `python tests/run.py`. Expected: "Wrote QuestShopData.lua: N quests." and all checks PASS. Read the generated list and drop nothing by hand. Note in the audit file any entry that looks wrong (an item the quest gives you, for example) for the owner.

- [ ] **Step 5: Commit**

```bash
git add tools/questshop.py QuestShopData.lua LevelingCodex.toc LevelingCodex_Camelot.toc tests/run.py tools/audits/2026-11-12-vendor-steps.md
git commit -m "Generated list of vendor-only quest items for the shopping card"
```

### Task 5: Shopping card at the vendor

**Files:**
- Modify: `Vendor.lua`, `Window.lua`
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: `ns.questShop` (Task 4), `items` on steps (Task 3), `Q.rows()`, `Q.current()`, `Q.log(id)`, `Q.itemCount(id)`, `ns.placeByWindow(card, MerchantFrame, place)`.
- Produces:
  - `ns.vendor.needs() -> { { item = id, need = n, forText = string }, ... }`, in route order.
  - The named frame `LevelingCodexShopCard`; its buy button is labelled "Buy for <money>" or "Need <money> more".
  - `ns.vendor.onBought(copper)` hook point (Task 7 files it as buys through PLAYER_MONEY context).

- [ ] **Step 1: Write the failing scenario**

```lua
function S.vendorShopping()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 2, { type = "buy", item = 3713, count = 3, name = "Soothing Spices",
        text = "Buy 3 Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  S.login()
  if MOCK.minimal then return end
  MOCK.money = 1000
  local spices = { id = 3713, name = "Soothing Spices", price = 50, per = 1, stock = -1, maxStack = 20 }
  MOCK.openMerchant({ items = { { id = 159, name = "Refreshing Spring Water", price = 5 }, spices } })
  MOCK.advance(0.5)
  local card = _G.LevelingCodexShopCard
  check(card and card:IsShown() and questText(card, "3 x Soothing Spices"), "the card lists a coming step's item")
  check(not questText(card, "Spring Water"), "items no step needs are left out")
  click(card, "Buy for 1s 50c")
  check(#MOCK.bought == 1 and MOCK.bought[1][1] == 3713 and MOCK.bought[1][2] == 3, "Buy buys the count")
  check(chatHas("Bought 3 Soothing Spices for 1s 50c%."), "chat says what it bought")
  MOCK.event("BAG_UPDATE_DELAYED")
  check(not card:IsShown(), "the card hides once nothing is left to buy")
  MOCK.closeMerchant()
  MOCK.bags[3713], MOCK.bought, MOCK.money = 0, {}, 100
  MOCK.openMerchant({ items = { spices } })
  MOCK.advance(0.5)
  check(findButton(card, function(l) return l == "Need 50c more" end), "short of gold: the button says how much")
  click(card, "Need 50c more")
  check(#MOCK.bought == 0, "and buys nothing")
  MOCK.closeMerchant()
  spices.stock, MOCK.money = 2, 1000
  MOCK.openMerchant({ items = { spices } })
  MOCK.advance(0.5)
  check(questText(card, "only 2 in stock"), "limited stock is noted")
  click(card, "Buy for 1s")
  check(MOCK.bought[1][2] == 2, "and only the stock is bought")
  MOCK.closeMerchant()
  check(not card:IsShown(), "closing the vendor hides the card")
end
```

Add a second scenario, `S.vendorShoppingQuest`. It uses `routeAt` to put a Human level 35 at the Theramore buy step (Dustwallow Marsh, map 1445, 66.4, 51.5), with quest 1218 in the log as `{ questID = 1218, title = "Soothing Spices", objectives = { { text = "Soothing Spices: 0/3", finished = false } } }`. It asserts that the card lists "3 x Soothing Spices" exactly once, because the buy step and quest 1218 must not add up to 6. Add both runs as `"WARRIOR/%s/vendor-shopping"`.

- [ ] **Step 2: Run them and see them fail**

Run: `python tests/run.py -k vendor-shopping`. Expected: FAIL, "the card lists a coming step's item".

- [ ] **Step 3: Implement `ns.vendor.needs()`**

- The window: from `Q.current()`'s index forward through `Q.rows()`, pending rows only, until the second section after the current one begins.
- The sources:
  - (a) buy and collect steps' `item`/`count` and `items`;
  - (b) `ns.questShop[row.step.quest]` for quests not turned in. Once the quest is in the log, use its objective whose text names the item: remaining = need − have, and 0 when finished.
- Per item: need = max(sum of step counts, sum of quest counts) − `Q.itemCount(id)`; drop the item when need ≤ 0.
- `forText`: the turn-in step's `npc` for a quest source, else the quest's name, else "a step ahead".

- [ ] **Step 4: Implement the card**

- Build `LevelingCodexShopCard` like `TrainerGuide.lua`'s `makeCard`: tooltip backdrop, flat fallback, `FULLSCREEN_DIALOG` strata, `EnableMouse(true)`. Label "FOR YOUR GUIDE".
- Up to 6 rows. Each row: the item icon (`GetItemIcon(id)` via `ns.setIcon`, fallback `INV_Misc_Bag_10`), "N x Name" on the left, the price on the right, and "for <forText>" under it in dim. Add "  (only N in stock)" when the stock is smaller than the need.
- One button (`ns.art.button`):
  - "Buy for <total>" when `GetMoney() >= total`;
  - else "Need <total - money> more", which does nothing when clicked.
- Merchant scan:
  - item ID from `GetMerchantItemID(i)`, else the ID in `GetMerchantItemLink(i)`;
  - `GetMerchantItemInfo(i)`, else `C_MerchantFrame.GetItemInfo(i)` (a table: price, stackCount, numAvailable, hasExtendedCost);
  - skip items with an extended cost.
- Cost: `price * n` when `per == 1`, else `price * ceil(n / per)`.
- Buying:
  - first call `ns.vendor.onBought(cost)`, before any purchase;
  - `per == 1`: `BuyMerchantItem(i, k)` in chunks of `GetMerchantItemMaxStack(i)` (else 20);
  - else `BuyMerchantItem(i)` `ceil(n / per)` times;
  - cap by the stock when it isn't −1;
  - then `ns.say("Bought N Name for <cost>.")`.
- Refresh on MERCHANT_SHOW (and 0.3 s later), MERCHANT_UPDATE and BAG_UPDATE_DELAYED while the vendor is open. Hide on MERCHANT_CLOSED and on `MerchantFrame`'s OnHide. Place with `ns.placeByWindow(card, MerchantFrame, place)`.
- Controller: `ns.gamepad.attach(card, { popup = true })`.
- Settings: the tick "Show what to buy for the guide" (`noShopCard`). Tooltip: "At a vendor, a card lists items your coming steps need that this vendor sells, with one button to buy them. Nothing is bought until you click it."

- [ ] **Step 5: Run them and see them pass**

Run: `python tests/run.py -k vendor`, then `python tests/run.py -k pad`. Expected: PASS. The controller runs show no new focus problems.

- [ ] **Step 6: Commit**

```bash
git add Vendor.lua Window.lua tests/scenarios.lua tests/run.py
git commit -m "Vendor: a shopping card for the items your coming steps need"
```

### Task 6: Phase 1 checkpoint (install and in-game list)

**Files:**
- Modify: `CLAUDE.md` (files table: `Vendor.lua`, `QuestShopData.lua`/`tools/questshop.py`; a module entry "7e. `Vendor.lua`" after TrainerGuide; the Tests section: the merchant mock and the `vendor*` scenarios)

- [ ] **Step 1: Update CLAUDE.md**, following the style of its existing module entries. One paragraph covers: the events, junk rules, pacing, repair, the needs window and dedupe, the card, the settings keys and the hook points.
- [ ] **Step 2: Full harness.** Run: `python tests/run.py`. Expected: PASS except `blocked-report`.
- [ ] **Step 3: Check what's installed.** Read `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\LevelingCodex\LevelingCodex.toc` `## Version`, take the hash after `-g`, and run `git merge-base --is-ancestor <hash> HEAD`. If it fails, stop and ask the owner.
- [ ] **Step 4: Install.** Run: `python tools/install.py`. Expected: every file verified.
- [ ] **Step 5: Commit** the CLAUDE.md change. Then tell the owner to restart the client (the .toc changed) and give them the Phase 1 in-game list:
  - greys sell at any vendor, with one chat line;
  - no Blizzard "blocked" message appears;
  - repair works;
  - the shopping card at a trade supplier with the Soothing Spices steps ahead;
  - the card's placement next to the vendor window;
  - Alt holds selling and repairing back.

---

## Phase 2: Stats tab

### Task 7: Stats counters (`Stats.lua`)

**Files:**
- Create: `Stats.lua`
- Modify: both `.toc` files (`Stats.lua` after `QuestTab.lua`), `Init.lua` (`ns.startStats()` after `ns.startPace()`), `Pace.lua`, `Vendor.lua` (hook points from Tasks 1, 2 and 5 call `ns.stats.expect`), `QuestGuide.lua` (the TakeTaxiNode hook calls `ns.stats.count("flights")`; landing in `tickFlight` calls `ns.stats.flightTime(seconds)`), `Quests.lua` (`Q.enteredDungeon`'s new instance calls `ns.stats.count("dungeons")`; `Q.bossDown` calls `ns.stats.count("bosses")`)
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces:
  - `ns.startStats()`
  - `ns.stats.xp(kind, amount)`, where kind is `"total"`, `"quest"` or `"kill"`
  - `ns.stats.count(name, n)`, where name is `"quests"`, `"kills"`, `"deaths"`, `"flights"`, `"hearths"`, `"dungeons"` or `"bosses"`, and n defaults to 1
  - `ns.stats.flightTime(seconds)`
  - `ns.stats.expect(source, copper)`, where source is `"junk"`, `"repair"` or `"buys"`
  - `ns.stats.data() -> session, saved` (`saved` is nil when `LevelingCodexCharDB` isn't loaded)
  - `ns.stats.reset()`
- Tree shape, the same for `session` and `saved` (`saved` lives at `LevelingCodexCharDB.stats`, `version = 1`):
  - `levels[lvl] = { seconds, xp, questXP, killXP, rested, quests, kills, deaths, goldIn = { quest, loot, junk, sales, other }, goldOut = { repair, training, flights, buys, other } }`
  - `zones[mapID] = { name, seconds, xp, quests }`
  - `totals = { quests, kills, deaths, flights, flightSeconds, hearths, dungeons, bosses, goldIn = {...}, goldOut = {...} }`
  - `played = { total, level, at }`
  - `started = time()`
- Mock produces:
  - events `LOOT_OPENED`, `LOOT_CLOSED`, `TIME_PLAYED_MSG`, `UNIT_SPELLCAST_SUCCEEDED` (known + optional);
  - `MOCK.mapInfo[id] = { name, mapType, parentMapID }`, read by `C_Map.GetMapInfo`, with 1429 Elwynn Forest type 3, 1453 Stormwind City type 3 and 1433 kept;
  - `MOCK.rested` changes are read by `GetXPExhaustion`.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.statsCounters()
  LevelingCodexCharDB = LevelingCodexCharDB or {}
  LevelingCodexCharDB.stats = "x" -- a broken saved shape is replaced, not used
  S.login()
  if MOCK.minimal then MOCK.advance(2); return end
  local lvl = MOCK.level
  local st = LevelingCodexCharDB.stats
  check(type(st) == "table" and st.version == 1, "broken saved stats start fresh")
  local L = function() return st.levels[lvl] end
  MOCK.setMoney(1000)
  MOCK.event("QUEST_TURNED_IN", 783, 120, 500)
  MOCK.setMoney(1500)
  check(L().goldIn.quest == 500 and L().quests == 1 and L().questXP == 120, "a turn-in: quest gold, count and XP")
  MOCK.event("LOOT_OPENED"); MOCK.setMoney(1600); MOCK.event("LOOT_CLOSED")
  check(L().goldIn.loot == 100, "money while looting is loot")
  MOCK.event("TRAINER_SHOW"); MOCK.setMoney(1400); MOCK.event("TRAINER_CLOSED")
  check(L().goldOut.training == 200, "money spent at a trainer is training")
  MOCK.setMoney(1350)
  check(L().goldOut.other == 50, "anything else is other")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Vermin dies, you gain 45 experience.")
  check(L().killXP == 45 and L().kills == 1, "a kill's XP and count")
  MOCK.event("PLAYER_DEAD")
  check(L().deaths == 1 and st.totals.deaths == 1, "a death")
  MOCK.event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 8690)
  check(st.totals.hearths == 1, "a hearthstone use")
  MOCK.event("TIME_PLAYED_MSG", 3600, 600)
  check(st.played.total == 3600 and st.played.level == 600, "/played is remembered")
  local before = L().seconds
  MOCK.advance(3)
  check(L().seconds >= before + 3 and st.zones[1429] and st.zones[1429].seconds >= 3, "time goes to the level and the zone")
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 40 } }
  MOCK.openMerchant({ items = {} })
  MOCK.advance(1)
  MOCK.closeMerchant()
  check(L().goldIn.junk == 40, "the Codex's junk sales are junk, not sales")
end
```

Add the run `"WARRIOR/%s/stats-counters"` with `["statsCounters"]`. The scenario must set `LevelingCodexCharDB.stats` before `S.login()`, so check how the runs create `LevelingCodexCharDB` (see `PERSISTED`) and set it the same way.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k stats`. Expected: FAIL, "broken saved stats start fresh".

- [ ] **Step 3: Implement `Stats.lua`**

**Storage**
- `fresh()` builds the tree.
- `saved()` returns `LevelingCodexCharDB.stats` when it's a table with `version == 1`, else writes `fresh()` there, provided `LevelingCodexCharDB` is a table.
- Every `add` updates both trees.

**Events** (each registered with `pcall`): PLAYER_MONEY, QUEST_TURNED_IN, LOOT_OPENED, LOOT_CLOSED, MERCHANT_SHOW, MERCHANT_CLOSED, TRAINER_SHOW, TRAINER_CLOSED, PLAYER_DEAD, TIME_PLAYED_MSG, UNIT_SPELLCAST_SUCCEEDED (`unit == "player"` and spell 8690).

**Gold filing, per PLAYER_MONEY delta**
- Increase:
  - pending quest money from QUEST_TURNED_IN's third argument is quest;
  - while looting it's loot;
  - expected junk is junk;
  - other increases while a vendor is open are sales;
  - the rest is other.
- Decrease:
  - expected repair is repair;
  - expected buys are buys;
  - while a vendor is open it's buys;
  - while a trainer is open it's training;
  - within 5 s of `ns.stats.count("flights")` it's flights;
  - the rest is other.
- Expected amounts are used up as they are matched, and expire 5 s after `expect`, so a sale the client blocked doesn't misfile later money.

**XP and the tick**
- `Pace.lua` calls `ns.stats.xp("total", gained)` in `onXP`, `ns.stats.xp("quest", b)` and `ns.stats.count("quests")` at QUEST_TURNED_IN, and `ns.stats.xp("kill", n)` and `ns.stats.count("kills")` at a kill.
- Stats does not parse these events again.
- Rested: in `xp("total")`, a drop in `GetXPExhaustion()` since the last reading is added to `rested`.
- Time: `ns.every(1, tick)` adds 1 s to `levels[UnitLevel]` and, when not on a taxi and not dead, to the current zone.
  - The zone: walk `C_Map.GetMapInfo(map).parentMapID` while `mapType > 3`; a missing `mapType` keeps the map.
  - The zone `name` is the map info's name.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k stats`, then `python tests/run.py -k pace`. Expected: PASS. The pace card is unchanged.

- [ ] **Step 5: Commit**

```bash
git add Stats.lua LevelingCodex.toc LevelingCodex_Camelot.toc Init.lua Pace.lua Vendor.lua QuestGuide.lua Quests.lua tests/wowmock.lua tests/scenarios.lua tests/run.py
git commit -m "Stats: leveling, gold, activity and zone counters, per session and saved"
```

### Task 8: Stats tab

**Files:**
- Modify: `Stats.lua` (renderer and `ns.addTab("stats", "Stats", render)`), `Window.lua` (tab-row fit after the tabs are built)
- Test: `tests/scenarios.lua` (the `TABS` list at line ~3148 gains `"Stats"` before `"Settings"`; new `S.statsTab`, `S.statsTabLost`), `tests/run.py`

**Interfaces:**
- Consumes: `ns.stats.data()`, `ns.stats.reset()`, `ns.paceRows()`, `ns.ui` (`T`, `box`, `btn`, `sectionTitle`, `refresh`), `ns.money`.

- [ ] **Step 1: Write the failing scenarios**

```lua
function S.statsTab()
  S.login()
  MOCK.event("QUEST_TURNED_IN", 783, 120, 0)
  MOCK.advance(2)
  openAt(MOCK.level, "Stats")
  local text = MOCK.textUnder(win())
  for _, head in ipairs({ "THIS SESSION", "LEVEL SPLITS", "GOLD", "ACTIVITY", "ZONES" }) do
    check(text:find(head, 1, true), "the Stats tab has " .. head)
  end
  check(questText(win(), "Quests turned in") and questText(win(), "Elwynn Forest"), "counts and zones show")
  click(win(), "Reset stats")
  click(win(), "Click again to reset")
  check(LevelingCodexCharDB.stats.totals.quests == 0, "two clicks reset the saved stats")
end

function S.statsTabLost()
  openAt(MOCK.level, "Stats")
  check(questText(win(), "Counting since you logged in"), "without saved data the tab says what it counts")
end
```

Runs:
- `"WARRIOR/%s/stats-tab"` with `["statsTab"]`;
- `"WARRIOR/full/stats-lost"` with `LOST + ["statsTabLost"]`, reusing the lost-SavedVariables setup steps of the `LOST` list.

- [ ] **Step 2: Run them and see them fail**

Run: `python tests/run.py -k stats`. Expected: FAIL, "no button 'Stats'".

- [ ] **Step 3: Implement the tab**

Parchment cards (`U.box`), top to bottom:

1. THIS SESSION: time, XP/hour, gold/hour, quests, kills, deaths, all from `session`.
2. LEVEL SPLITS: the last 10 levels of `saved or session` as one row each (level, time, quest XP %, kills, deaths, net gold), the current level marked "now", a "Show all levels" toggle, and "Played: <total> (from your last /played)" when `played` is set.
3. GOLD: two columns, in and out by source, each with session and saved figures, and "Net this level".
4. ACTIVITY: the totals, with "Time in the air".
5. ZONES: the top 8 by seconds, with XP and quests, and a "Show all zones" toggle.
6. "Reset stats", a two-click confirm within 5 s (the `confirmAbandon` pattern in `QuestTab.lua`) with the label "Click again to reset".

With `ns.settingsLost` (or `saved == nil`), every card heading gets " (counting since you logged in)", and the first card says "Counting since you logged in: Forever didn't load your saved stats."

`Window.lua`: after the tab loop, sum the tab widths minus 12 per overlap. If that exceeds `frame:GetWidth() - 32`, set every tab's width to `floor((frame:GetWidth() - 32 + 12 * (n - 1)) / n)`.

- [ ] **Step 4: Run them and see them pass**

Run: `python tests/run.py -k stats`, then `python tests/run.py`. Expected: PASS. Tab-cycling scenarios pass with the updated `TABS`.

- [ ] **Step 5: Commit**

```bash
git add Stats.lua Window.lua tests/scenarios.lua tests/run.py
git commit -m "Stats tab: session, level splits, gold, activity and zones"
```

### Task 9: Phase 2 checkpoint

- [ ] **Step 1:** CLAUDE.md: a module entry for `Stats.lua` (API, tree, gold filing rules, tab), the `.toc` order, and the stats mock notes.
- [ ] **Step 2:** `python tests/run.py`, the install check, `python tools/install.py`, commit.
- [ ] **Step 3:** In-game list for the owner:
  - the ninth tab fits (no overlap under the window);
  - gold sorts into the right sources after a quest, looting, a vendor, a trainer and a flight;
  - `/played` fills Played;
  - zones roll up subzones;
  - stats survive a `/reload` when Forever loads saved data.

---

## Phase 3: Navigation

### Task 10: A movable, resizable arrow

**Files:**
- Modify: `QuestGuide.lua` (`makeViewer`, `place`, `questRefresh`, viewer OnHide), `Window.lua` (Settings > QUEST GUIDE arrow rows)
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces:
  - `LevelingCodexQuestArrow`: 48 x 48, parented to UIParent, movable, mouse and wheel enabled, clamped to screen.
  - Its first region stays the arrow art (`questNavigation` reads `arrow:GetRegions()`), and its regions still hold the caption text.
  - Saved settings: `db.questArrowPos = { point, relativePoint, x, y }`, `db.questArrowScale`, `db.questArrowLocked`.
  - `ns.placeQuestArrow()`.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.arrowMove()
  LevelingCodexDB = LevelingCodexDB or {}
  LevelingCodexDB.questArrowScale = 9
  S.login()
  local arrow, frame = _G.LevelingCodexQuestArrow, questViewer()
  check(arrow:GetParent() == UIParent and arrow:IsShown(), "the arrow lives on its own")
  check(math.abs(arrow:GetScale() - 2) < 0.001, "a saved scale out of bounds is held at 200%")
  slash("")
  click(win(), "Settings")
  click(win(), "Reset arrow")
  win():Hide()
  local _, rel = arrow:GetPoint()
  check(rel == frame and math.abs(arrow:GetScale() - 1) < 0.001, "unmoved, it sits above the step window at 100%")
  check(select(3, frame:GetClampRectInsets()) >= 76, "the window keeps room for it on screen")
  MOCK.drag(arrow, 100, 50)
  local p = LevelingCodexDB.questArrowPos
  _, rel = arrow:GetPoint()
  check(p and rel == UIParent, "dragging puts it anywhere and saves the spot")
  check(select(3, frame:GetClampRectInsets()) == 0, "a moved arrow no longer pads the window")
  MOCK.ctrl = true
  MOCK.fire(arrow, "OnMouseWheel", 1)
  check(math.abs(arrow:GetScale() - 1.1) < 0.001 and LevelingCodexDB.questArrowScale, "Ctrl+wheel resizes it")
  MOCK.fire(arrow, "OnMouseWheel", -1)
  MOCK.ctrl = false
  MOCK.fire(arrow, "OnMouseWheel", 1)
  check(math.abs(arrow:GetScale() - 1) < 0.001, "the wheel alone leaves the size")
  LevelingCodexDB.questArrowLocked = true
  local x = p[3]
  MOCK.drag(arrow, 30, 30)
  check(LevelingCodexDB.questArrowPos[3] == x, "a locked arrow stays put")
  click(frame, "Hide")
  check(not arrow:IsShown(), "it hides with the step window")
end
```

Add `"arrowMove"` to the `quests-*` list.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k arrowMove`. Expected: FAIL, "the arrow lives on its own".

- [ ] **Step 3: Implement**

**The frame**
- Arrow frame 48 x 48, art `SetAllPoints`, created first.
- Caption FontString: `TOP` at the arrow's `BOTTOM` (0, −2), width 320.

**`ns.placeQuestArrow()`**
- Saved position: `SetPoint(p[1], UIParent, p[2], p[3], p[4])`; the viewer's clamp insets become `0, 0, 0, 0`.
- Else: `SetPoint("BOTTOM", viewer, "TOP", 0, 28)`, and the viewer's insets stay `0, 0, 76, 0`.
- Scale: `db.questArrowScale` clamped to 0.6-2.0, default 1.

**Mouse**
- OnDragStart: unless `db.questArrowLocked`, `StartMoving()`.
- OnDragStop: `StopMovingOrSizing()`, save `{ point, relativePoint, x, y }` from `GetPoint()` (as the step window's own OnDragStop does), then `ns.placeQuestArrow()`, which re-anchors it to UIParent.
- OnMouseWheel: only with `IsControlKeyDown()`, scale ± 0.1, saved rounded to 0.1.
- OnEnter tooltip: "Quest arrow" / "Drag to move it. Ctrl+mouse wheel changes its size."

**Visibility**
- Hide the arrow wherever the viewer hides: the questRefresh hide branch and the viewer's OnHide hook.

**Settings**
- Tick "Lock the arrow" (`questArrowLocked`).
- Row "Arrow size" with −/+ and the percent between (like the banner size row).
- Button "Reset arrow": clears the position and scale, then `ns.placeQuestArrow()`.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k quests`. Expected: PASS, including `questNavigation`, `questCorpse` and `questQuestieArrowClamp` (unmoved arrow).

- [ ] **Step 5: Commit**

```bash
git add QuestGuide.lua Window.lua tests/scenarios.lua tests/run.py
git commit -m "Quest arrow: drag it anywhere, Ctrl+wheel to resize, lock and reset"
```

### Task 11: Step icons and the arrival animation

**Files:**
- Create: `QuestMap.lua` (for now only `ns.questIcon`; the pins come in Tasks 12-13)
- Modify: both `.toc` files (`QuestMap.lua` after `QuestGuide.lua`), `QuestGuide.lua` (`paintArrow`, `paintCorpse`), `Window.lua` (the tick "Animate the arrow on arrival", `noArrowBounce`)
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces: `ns.questIcon(step) -> path` (a probed file, or nil, which means draw the gold dot). Icon by step type:

| Step | Icon file |
|---|---|
| `accept` | `Interface\\GossipFrame\\AvailableQuestIcon` |
| `turnin` | `Interface\\GossipFrame\\ActiveQuestIcon` |
| `complete` with a kill objective | `Interface\\Cursor\\Attack` |
| other `complete` | `Interface\\Cursor\\LootAll` |
| `fly`, `getfp` | `Interface\\GossipFrame\\TaxiGossipIcon` |
| `sethearth`, `hearth` | `Interface\\GossipFrame\\BinderGossipIcon` |
| `buy` | `Interface\\GossipFrame\\VendorGossipIcon` |
| `train` | `Interface\\GossipFrame\\TrainerGossipIcon` |
| `boss`, `dungeon`, `plan` | `Interface\\TargetingFrame\\UI-TargetingFrame-Skull` |
| everything else | `Interface\\TaxiFrame\\UI-Taxi-Icon-Highlight` |

  A kill objective means the quest log or the step's `objectives` text contains "slain" or "killed", or the quest has `ns.questMobs` entries and no item objective.
- Arrow regions added after the art and caption: `arrow.here` (36 px icon) and `arrow.ring` (`UI-Taxi-Icon-Highlight`, ADD blend, gold).
- Animation groups: `arrow.bob` (Translation 0, 8 over 0.4 s, BOUNCE) and `arrow.pulse` (Scale 0.6 to 1.4 and Alpha 1 to 0, 0.6 s, `OnFinished` hides the ring).

- [ ] **Step 1: Write the failing scenario**

```lua
function S.arrowArrival()
  S.login()
  local arrow = _G.LevelingCodexQuestArrow
  MOCK.questX, MOCK.questY = 48.17, 42.94 -- Deputy Willem, the first step
  MOCK.advance(0.5)
  check(questText(arrow, "Deputy Willem") and questText(arrow, "Arrived"), "arrival names the step's NPC")
  check(arrow.here:IsShown() and not arrow:GetRegions():IsShown(), "the arrow turns into the step's icon")
  check(arrow.here._path == "Interface\\GossipFrame\\AvailableQuestIcon", "a pickup shows the yellow !")
  check(arrow.bob:IsPlaying() and arrow.pulse:IsPlaying(), "the icon bobs and the ring pulses")
  MOCK.advance(1)
  check(not arrow.pulse:IsPlaying() and arrow.bob:IsPlaying(), "the ring pulses once, the bob goes on")
  MOCK.questX, MOCK.questY = 60, 60
  MOCK.advance(0.5)
  check(not arrow.here:IsShown() and not arrow.bob:IsPlaying() and arrow:GetRegions():IsShown(),
    "leaving the spot brings the arrow back")
  LevelingCodexDB.noArrowBounce = true
  MOCK.questX, MOCK.questY = 48.17, 42.94
  MOCK.advance(0.5)
  check(arrow.here:IsShown() and not arrow.bob:IsPlaying(), "with the animation off the icon stays still")
end
```

Add `"arrowArrival"` to the `quests-*` list. The full run only: the minimal client has no `C_Map`, so it never has a position to arrive at.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k arrow`. Expected: FAIL, "arrival names the step's NPC".

- [ ] **Step 3: Implement**

`QuestMap.lua` holds `ns.questIcon`, with each path probed once through `ns.art.hasFile`.

In `QuestGuide.lua`, `arrival(key, icon, text)` and `leave()`:
- `key` = `row.key` .. the path point. Entering with a new key:
  - hides the art;
  - sets `here` to the icon, or the colour dot (`SetColorTexture(1, 0.82, 0)` at 12 px) when the icon is nil;
  - shows `here` and the ring, plays `pulse`, and plays `bob` unless `db.noArrowBounce`.
- `leave()`: stops both groups, hides `here` and the ring.

Captions:
- step arrival: `(goal.npc and plain(goal.npc) .. "\n" or "") .. "Arrived" .. which`;
- spawn arrival: `"<name> nearby"`, as today;
- corpse: `"Your corpse is here"`, as today, with the gold-ring icon.
- `travel` captions at arrival are unchanged and use no icon.

Settings tick: "Animate the arrow on arrival" (`noArrowBounce`).

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k quests`, then `python tests/run.py -k arrow`. Expected: PASS. Existing "Arrived" and "nearby" checks still pass.

- [ ] **Step 5: Commit**

```bash
git add QuestMap.lua QuestGuide.lua Window.lua LevelingCodex.toc LevelingCodex_Camelot.toc tests/scenarios.lua tests/run.py
git commit -m "Quest arrow: the step's icon bobs over a gold ring when you arrive"
```

### Task 12: Minimap pins, edge arrow and dotted line

**Files:**
- Modify: `QuestMap.lua`, `QuestGuide.lua` (`questRefresh` calls `ns.questMap.refresh()`), `Init.lua` (`ns.questMap.start()`), `Window.lua` (ticks "Show steps on the minimap" `noMinimapSteps` and "Dotted line to the step" `noMinimapLine`)
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: `Q.current()`, `Q.upcoming(i, 2)`, `Q.waypoint(step)`, `Q.position()`, `Q.vector`, `Q.worldVector`, `ns.questIcon`.
- Produces:
  - `ns.questMap.start()`, `ns.questMap.refresh()`.
  - Frame `LevelingCodexMinimapPins` on `Minimap`, with `.current`, `.next = { t1, t2 }`, `.edge` and `.dots`: every visible pin is anchored `"CENTER", Minimap, "CENTER", x, y`.
  - `QuestMap.lua`'s local `screenOffset(bearing, yards, ppy, rotate, facing) -> x, y`: angle = bearing (+ facing when rotating), x = sin(angle) · yards · ppy, y = cos(angle) · yards · ppy.
- Mock produces:
  - `Minimap:GetZoom()` reads `MOCK.minimapZoom or 0`;
  - `IsIndoors()` reads `MOCK.indoors`;
  - `GetCVar(name)` reads `MOCK.cvars[name]`;
  - `C_Minimap.GetViewRadius()` reads `MOCK.viewRadius`, and is absent in the minimal run, where `C_Minimap` is gone.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.minimapPins()
  S.login()
  local pins = _G.LevelingCodexMinimapPins
  if MOCK.minimal then
    MOCK.advance(0.5)
    check(not (pins and pins:IsShown()), "no map API: no pins, no error")
    return
  end
  MOCK.viewRadius = 200
  -- Five percent south of Deputy Willem: about 116 yd (Elwynn is 2314.6 yd tall), 40 px out.
  MOCK.questX, MOCK.questY = 48.17, 47.94
  MOCK.advance(0.2)
  check(pins and pins.current:IsShown(), "the current step gets a minimap pin")
  local _, _, _, x, y = pins.current:GetPoint()
  check(math.abs(x) < 0.5 and y > 0, "north is up")
  check(#pins.next >= 1 and pins.next[1]:IsShown(), "the next steps get small pins")
  local dots = 0
  for _, d in ipairs(pins.dots) do if d:IsShown() then dots = dots + 1 end end
  check(dots > 0, "a dotted line leads to the step")
  MOCK.cvars = { rotateMinimap = "1" }
  MOCK.facing = math.pi / 2 -- facing west: north is to the right
  MOCK.advance(0.2)
  _, _, _, x, y = pins.current:GetPoint()
  check(x > 0 and math.abs(y) < 0.5, "a rotating minimap turns the pins with you")
  MOCK.cvars, MOCK.facing = {}, 0
  MOCK.questY = 80
  MOCK.advance(0.2)
  check(not pins.current:IsShown() and pins.edge:IsShown(), "out of range the pin becomes an edge arrow")
  _, _, _, x, y = pins.edge:GetPoint()
  check(math.abs(math.sqrt(x * x + y * y) - 66.5) < 0.6, "on the rim of a round minimap")
  MOCK.minimapShape = "SQUARE"
  MOCK.advance(0.2)
  _, _, _, x, y = pins.edge:GetPoint()
  check(math.abs(math.max(math.abs(x), math.abs(y)) - 66.5) < 0.6, "on the edge of a square minimap")
  MOCK.minimapShape, MOCK.viewRadius = nil, 0
  MOCK.advance(0.2)
  check(not pins.current:IsShown() and not pins.edge:IsShown(), "no usable scale: no pins")
  MOCK.viewRadius = 200
  LevelingCodexDB.noMinimapLine = true
  MOCK.questY = 47.94
  MOCK.advance(0.2)
  dots = 0
  for _, d in ipairs(pins.dots) do if d:IsShown() then dots = dots + 1 end end
  check(dots == 0, "the line can be turned off")
  LevelingCodexDB.noMinimapSteps = true
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.2)
  check(not pins:IsShown(), "and the pins")
end
```

Add `"minimapPins"` to the `quests-*` list, and the run `"WARRIOR/minimal/minimap-pins"` with `["login", "minimapPins"]`. In the minimal run there is no `C_Map`, so there are no pins. In the full run, with `MOCK.viewRadius` nil, the radius falls back to the zoom table: outdoor zoom 0 = 466.7 yd.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k minimap`. Expected: FAIL, "the current step gets a minimap pin".

- [ ] **Step 3: Implement**

**Scale**
- Half = `Minimap:GetWidth() / 2`.
- Radius = `C_Minimap.GetViewRadius()` when it's a function returning a number > 0. Otherwise half the diameter for `Minimap:GetZoom()`:
  - outdoor `{ 466.67, 400, 333.33, 266.67, 200, 133.33 }`;
  - indoor (`IsIndoors()`) `{ 300, 240, 180, 120, 80, 50 }`.
- No usable half or radius: hide everything.
- Pixels per yard = half / radius.

**Rotation**
- Rotate when `GetCVar("rotateMinimap") == "1"`, `GetPlayerFacing()` is a number, and `not (issecretvalue and issecretvalue(facing))`.

**Pins and the edge arrow**
- Limit: round = 0.95 · half on the radius; square = 0.95 · half on max(|x|, |y|), scaled along the vector.
- In range: the current pin at (x, y), 16 px, `ns.questIcon`. Next pins: 10 px, alpha 0.6, with a GameFontHighlightSmall "1" or "2".
- Out of range: the current pin hides and `edge` (the quest-arrow texture, 14 px) shows at the clamped point, with `SetRotation(-angle)` when available. The next pins hide when out of range.

**Dotted line**
- Up to 40 pooled 3 px gold dots (alpha 0.7).
- Every 10 px from 8 px out to min(distance, limit), offset by `(GetTime() * 10) % 10`.

**Updates**
- OnUpdate, throttled to 0.05 s, on `LevelingCodexMinimapPins`.
- Shown only while the step window shows, `noMinimapSteps` is off, and `Q.position()` gives coordinates.
- The pin targets are rebuilt in `refresh()`, not every tick.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k minimap`, then `python tests/run.py -k quests`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add QuestMap.lua QuestGuide.lua Init.lua Window.lua tests/wowmock.lua tests/scenarios.lua tests/run.py
git commit -m "Minimap: pins for the current and next steps, an edge arrow and a dotted line"
```

### Task 13: World map pins

**Files:**
- Modify: `QuestMap.lua`, `Window.lua` (tick "Show steps on the world map", `noWorldMapSteps`)
- Test: `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces: frame `LevelingCodexWorldMapPins` on `WorldMapFrame.ScrollContainer.Child`, with `.current` and `.next[1..2]` as Buttons anchored `"CENTER", child, "TOPLEFT", x% · width, −y% · height`.
- Mock produces:
  - `WorldMapFrame`, a hidden frame with `ScrollContainer.Child` sized 1002 x 668;
  - `WorldMapFrame:GetMapID()` reads `MOCK.worldMapID`;
  - `WorldMapFrame:OnMapChanged()`, a no-op method;
  - `WorldMapFrame` is added to `OPTIONAL`.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.worldMapPins()
  S.login()
  if MOCK.minimal then return end
  MOCK.worldMapID = 1429
  WorldMapFrame:Show()
  local pins = _G.LevelingCodexWorldMapPins
  check(pins and pins.current:IsShown(), "the current step shows on the world map")
  local _, _, _, x, y = pins.current:GetPoint()
  check(math.abs(x - 482.66) < 1 and math.abs(y + 286.84) < 1, "at the step's spot on the map")
  MOCK.fire(pins.current, "OnEnter")
  check(GameTooltip._lines[1] and GameTooltip._lines[1]:find("A Threat Within", 1, true), "hovering names the step")
  MOCK.fire(pins.current, "OnLeave")
  MOCK.worldMapID = 1453
  WorldMapFrame:OnMapChanged()
  check(not pins.current:IsShown(), "another map hides the pins")
  MOCK.worldMapID = 1429
  LevelingCodexDB.noWorldMapSteps = true
  WorldMapFrame:OnMapChanged()
  check(not pins:IsShown(), "the setting turns them off")
end
```

Add `"worldMapPins"` to the `quests-*` list.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k worldMapPins`. Expected: FAIL, "the current step shows on the world map".

- [ ] **Step 3: Implement**

- Build the frame lazily the first time `WorldMapFrame` exists. Hook `WorldMapFrame`'s OnShow with `HookScript`, and `OnMapChanged` with `hooksecurefunc(WorldMapFrame, "OnMapChanged", ...)` when both exist.
- `ns.questMap.refresh()` also redraws while the map is shown.
- Pins: the current one 20 px; the next ones 14 px with a number; all `ns.questIcon`.
- Only steps whose spot map equals `WorldMapFrame:GetMapID()` are shown.
- Tooltip: `Q.label(step)` as the title, then `Q.plain(step.text)` wrapped.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k quests`. Expected: PASS, including `questMapPin` (the game's waypoint is unchanged).

- [ ] **Step 5: Commit**

```bash
git add QuestMap.lua Window.lua tests/wowmock.lua tests/scenarios.lua tests/run.py
git commit -m "World map: numbered pins for the current and next steps"
```

### Task 14: Phase 3 checkpoint

- [ ] **Step 1:** Update CLAUDE.md:
  - the QuestGuide paragraph: the arrow is detached, movable, scalable and has the arrival state;
  - a module entry for `QuestMap.lua` (icons, minimap math, world map);
  - the mock notes (`MOCK.viewRadius`, `MOCK.cvars`, `MOCK.minimapZoom`, `MOCK.indoors`, `MOCK.worldMapID`).
- [ ] **Step 2:** `python tests/run.py`, the install check, `python tools/install.py`, commit.
- [ ] **Step 3:** In-game list:
  - drag and Ctrl+wheel the arrow;
  - the arrival bob at an NPC, a kill camp (QuestieDB) and a flight master;
  - whether the icons all show (a gold dot means a missing file);
  - minimap pins line up with the game's own waypoint while you walk and turn, with rotate-minimap on and off;
  - whether the game already draws its waypoint on the minimap (two pins);
  - world map pins on the right spots.

---

## Phase 4: Step window and Quests tab

### Task 15: Completion bar

**Files:**
- Modify: `Quests.lua` (`Q.stepProgress`), `QuestGuide.lua` (the bar in `makeViewer`/`questRefresh`), `QuestTab.lua` (`ns.openQuestRoute()`), `Window.lua` (tick "Show the completion bar", `noStepBar`)
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Produces:
  - `Q.stepProgress(section) -> passed, total`: rows of the section not `filtered`, not `row.grey` and not `row.cut`; passed = state `done`, `skipped` or `deferred`.
  - Button `LevelingCodexQuestBar` in the step window, with `.fill` and `.pct`.
  - `ns.openQuestRoute()`: opens Quests at its Route view. In Task 17 it switches the sub-tab to Route.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.stepProgress()
  S.login()
  local bar, frame = _G.LevelingCodexQuestBar, questViewer()
  check(bar and bar:IsShown() and questText(bar, "0%"), "a fresh guide starts at 0%")
  click(frame, "Next")
  click(frame, "Next")
  MOCK.advance(0.1)
  local mid = bar.fill:GetWidth()
  MOCK.advance(0.6)
  check(bar.fill:GetWidth() > mid and not questText(bar, "0%"), "skipped steps fill the bar, sliding")
  MOCK.fire(bar, "OnEnter")
  check(GameTooltip._lines[1] and GameTooltip._lines[1]:find("steps", 1, true), "hovering gives the counts")
  MOCK.fire(bar, "OnLeave")
  bar:Click()
  check(win() and win():IsShown() and findButton(win(), function(l) return l == "Show all steps" end),
    "clicking opens the route")
  LevelingCodexDB.noStepBar = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not bar:IsShown(), "the bar can be turned off")
end
```

Add `"stepProgress"` to the `quests-*` list.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k stepProgress`. Expected: FAIL, "a fresh guide starts at 0%".

- [ ] **Step 3: Implement**

**Layout**
- The bar sits under the title, at `cursor`, 318 x 6: a dark track `(0, 0, 0, 0.6)` with a 1 px edge in `C.edge`.
- `fill`: `Interface\\TargetingFrame\\UI-StatusBar` tinted `C.accent` when `hasFile`, else a colour texture.
- `pct`: "N%" in GameFontHighlightSmall, right of the bar. The bar's width leaves room for it.
- `cursor` grows by 12.
- Hidden when total is 0, with `noStepBar`, or with no current row.

**Animation**
- A new target starts a 0.5 s tween: width = from + (to − from) · (1 − (1 − t)³), driven by the bar's OnUpdate, which is cleared at t = 1.

**Hover and click**
- Tooltip title: "<section title>: P of T steps, Q of N quests turned in" (`Q.sectionProgress`).
- Click: `ns.openQuestRoute()`.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k quests`. Expected: PASS. The `questLayout` checks still pass; if a height check fails, the 12 px are expected, so update its numbers there.

- [ ] **Step 5: Commit**

```bash
git add Quests.lua QuestGuide.lua QuestTab.lua Window.lua tests/scenarios.lua tests/run.py
git commit -m "Step window: an animated completion bar for the current guide"
```

### Task 16: Step icon, progress flash and completion glow

**Files:**
- Modify: `QuestGuide.lua` (title icon, `putGoal` flash, `completionSound` glow)
- Test: `tests/scenarios.lua`, `tests/run.py`

**Interfaces:**
- Consumes: `ns.questIcon` (Task 11).
- Produces:
  - `viewer.titleIcon` (16 px at TOPLEFT 16, −28; the title moves 20 px right while it shows);
  - each goal row's `row.flash` texture with `row.flashAnim` (Alpha 0.6 to 0, 0.5 s);
  - `viewer.glowAnim` on four 2 px gold ADD edge textures inset 4 px (Alpha 1 to 0, 0.4 s).

- [ ] **Step 1: Write the failing scenario**

```lua
function S.stepPolish()
  -- The questProgress setup: Kobold Vermin (quest 7) in progress after the first Northshire quests.
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = { { text = "Kobold Vermin 4/10", numFulfilled = 4 } } } }
  S.login()
  local frame = questViewer()
  check(frame.titleIcon:IsShown() and frame.titleIcon._path == "Interface\\Cursor\\Attack",
    "a kill step shows the sword before its title")
  MOCK.questLog[1].objectives[1] = { text = "Kobold Vermin 5/10", numFulfilled = 5 }
  MOCK.event("QUEST_LOG_UPDATE")
  local flashing = false
  for g in pairs(MOCK.anims) do if g._owner and g._owner._isFlash then flashing = true end end
  check(flashing, "a rising count flashes its row")
  MOCK.questLog[1].objectives[1] = { text = "Kobold Vermin 10/10", numFulfilled = 10, finished = true }
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(frame.glowAnim:IsPlaying(), "a step the game finished makes the window's edge glow")
end
```

Mark the flash textures with `_isFlash = true` (a plain field, read only by the test). Add `"stepPolish"` to the `quests-*` list.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k stepPolish`. Expected: FAIL, "the step's icon sits before its title".

- [ ] **Step 3: Implement**

- Title icon: `ns.questIcon(row.step)`. With no icon, the title keeps its old anchor.
- Flash:
  - `lastCounts[key] = have`, where key = the row's quest .. ":" .. goal text, set on each draw;
  - the row flashes when `have` is greater than the stored value;
  - the table resets when the step changes.
- Glow: play `viewer.glowAnim` in `completionSound` where `done` is true. It is not tied to the `questNoSound` setting.

- [ ] **Step 4: Run it and see it pass**

Run: `python tests/run.py -k quests`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add QuestGuide.lua tests/scenarios.lua tests/run.py
git commit -m "Step window: step icon, a flash on objective progress, a glow on completion"
```

### Task 17: Quests tab with sub-tabs

**Files:**
- Modify: `QuestTab.lua` (restructure `render`), `QuestGuide.lua` (the step window's Quests button calls `ns.openQuestStep()`)
- Test: `tests/scenarios.lua` (new `S.questTabViews`; update the existing scenarios that click moved buttons), `tests/run.py`

**Interfaces:**
- Consumes: `Q.stepProgress` (Task 15) and everything `QuestTab.lua` uses today.
- Produces:
  - Session state `sub`: `"step"`, `"route"`, `"guides"` or `"log"`, default `"step"`.
  - `ns.openQuestStep()`, `ns.openQuestRoute()` (sub = route), `ns.openQuestGuide(section)` (sub = guides with that guide's page).
  - Button labels:
    - top row: "Setup", "Previous step", "Next step", "Show on map", "Hide step window" / "Show step window";
    - sub-tabs: "Step", "Route", "Guides", "Quest log";
    - the guide page's back button: "Back to guides";
    - band headers: "LEVELS a-b: N guides, all done" / "..., M done" / "..., M%".
  - Every other label is kept as today.

- [ ] **Step 1: Write the failing scenario**

```lua
function S.questTabViews()
  S.login()
  openAt(MOCK.level, "Quests")
  for _, name in ipairs({ "Setup", "Previous step", "Next step", "Show on map", "Step", "Route", "Guides", "Quest log" }) do
    check(findButton(win(), function(l) return l == name end), "the Quests tab has " .. name)
  end
  check(findButton(win(), function(l) return l == "Resume active quest" end), "Step is the first sub-tab")
  click(win(), "Route")
  check(findButton(win(), function(l) return l == "Show all steps" end), "Route lists the guide's steps")
  click(win(), "Guides")
  check(findButton(win(), function(l) return l == "Search" end) and questText(win(), "LEVELS 1-12"),
    "Guides has the search and the level bands")
  local folded = findButton(win(), function(l) return l:find("^LEVELS 30%-40") end)
  check(folded, "a band far from your level is folded")
  folded:Click()
  check(questText(win(), "Levels 30-"), "clicking a folded band opens it")
  click(win(), "Plan recommended")
  check(questText(win(), "Dungeons") or questText(win(), "DUNGEONS"), "dungeons live under Guides")
  click(win(), "Quest log")
  check(questText(win(), "Ready to turn in") and questText(win(), "Missed quests"), "Quest log holds the queues")
  click(win(), "Step")
  check(findButton(win(), function(l) return l == "Report this step" end), "the step tools sit under Step")
end
```

Add `"questTabViews"` to the `quests-*` list.

- [ ] **Step 2: Run it and see it fail**

Run: `python tests/run.py -k questTabViews`. Expected: FAIL, "the Quests tab has Setup".

- [ ] **Step 3: Restructure `render()`**

- Fixed top:
  - `U.sectionTitle("Quest Guide")` with a small "Setup" button on the right (toggles `setupOpen`);
  - the setup card;
  - `stepCard`, plus a U-drawn bar: track and fill rects, and "N%" from `Q.stepProgress`;
  - one row of four buttons.
- Then the four sub-tab buttons (`U.btn` with the selected state) and the chosen view:
  - `renderStepView`: Plan/Skip, Run, Plan related, route options, Resume active quest / Return to leveling, Nearest flight master, and a footer with "Report this step" and "Copy recorder log".
  - `renderRoute`: unchanged.
  - `renderGuides`:
    - the search box;
    - the bands, folded except the band holding your level and the next one (`openBands`, a session set, toggled by the header buttons);
    - Dungeons with Plan recommended/all/none and the list;
    - Special quest chains;
    - Class quests (when shown);
    - with `librarySection` set, the guide page with "Back to guides".
  - `renderLog`: Active quests (N/M) with Show/Track; "Ready to turn in (N)" and "Missed quests (N)" as section titles with their rows; Outleveled; Quest log cleanup.
- Remove the old Guide library toggle and the view buttons.

- [ ] **Step 4: Update the existing scenarios**

Run: `python tests/run.py -k quests`. For each failure that reads "no button 'X'", click the sub-tab that now holds X just before it:
- `"Guide library"` becomes `click(win(), "Guides")` (9 places);
- `"Show all steps"` needs `click(win(), "Route")` first (5);
- `"Guide setup"` becomes `"Setup"`;
- band guide buttons and the Dungeons buttons need `"Guides"`;
- `Track ...` / `Show ...` / `Abandon ...` need `"Quest log"`;
- `"Resume active quest"` after another sub-tab needs `"Step"`.

`questQueue(name)` becomes: click "Quest log", then check that the heading `name .. " (N)"` shows. Change only navigation clicks, never assertions about behaviour. If a behaviour assertion fails, fix the code.

- [ ] **Step 5: Run the harness and see it pass**

Run: `python tests/run.py`, then `python tests/run.py -k pad`. Expected: PASS except `blocked-report`. Controller navigation reaches the sub-tab buttons.

- [ ] **Step 6: Commit**

```bash
git add QuestTab.lua QuestGuide.lua tests/scenarios.lua tests/run.py
git commit -m "Quests tab: a fixed step card and Step, Route, Guides and Quest log sub-tabs"
```

### Task 18: Phase 4 checkpoint

- [ ] **Step 1:** Update CLAUDE.md:
  - the QuestTab paragraph: sub-tabs, `ns.openQuestStep`/`ns.openQuestRoute`/`ns.openQuestGuide`, folded bands;
  - the QuestGuide paragraph: the bar, the icon, the flash and the glow;
  - `Q.stepProgress`;
  - the scenario list.
- [ ] **Step 2:** `python tests/run.py`, the install check, `python tools/install.py`, commit.
- [ ] **Step 3:** In-game list:
  - the bar fills and slides as steps finish;
  - the hover counts are right;
  - the flash on a kill or loot count;
  - the edge glow with the map ping;
  - each Quests sub-tab with the mouse and with the controller;
  - folded bands;
  - the guide page and Back to guides;
  - Plan buttons still plan runs.
