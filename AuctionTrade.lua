-- AuctionTrade.lua: selling and deals at the auction house, shown on the Codex tab's Deals and
-- Selling pages (AuctionPanel.lua).
-- QUICK SELL: what's worth selling from your bags, priced under the lowest listing (Gold tab:
-- Undercut by), with two protections: never below what a vendor pays (after the auction house's
-- 5% cut), and a second click before a post far under the usual price (Gold tab: Warn under).
-- DEALS: listings a vendor pays more for, and listings far under their usual price (flips: the
-- profit after the 5% cut). Buying searches the item, shows the total, then buys on a click.
-- Every post and purchase is one click on a Codex button (the game only allows these calls from a
-- click): nothing runs by itself. Needs the modern C_AuctionHouse API (what Forever has).
local _, ns = ...
local Q = ns.quests
local try = Q.try

local T = {}
ns.auctionTrade = T

T.CUT = 0.05             -- the auction house keeps 5% of a sale
T.UNDERCUTS = { { "1c", 0, 1 }, { "1%", 1 }, { "5%", 5 }, { "10%", 10 } }
T.WARNS = { { "20%", 20 }, { "30%", 30 }, { "50%", 50 }, { "Off", 0 } }
T.FLIPS = { { "20%", 20 }, { "30%", 30 }, { "50%", 50 } }
T.DURATIONS = { { "12 h", 1 }, { "24 h", 2 }, { "48 h", 3 } }
T.MINPROFITS = { { "Any", 0 }, { "1s", 100 }, { "10s", 1000 }, { "25s", 2500 }, { "1g", 10000 } }
T.MAXBUYS = { { "No cap", 0 }, { "10s", 1000 }, { "1g", 10000 }, { "5g", 50000 }, { "25g", 250000 } }
T.SORTS = { { "Profit", "profit" }, { "ROI %", "roi" }, { "Price", "low" }, { "Newest", "age" } }
T.BUDGETS = { { "No cap", 0 }, { "1g", 10000 }, { "5g", 50000 }, { "25g", 250000 }, { "100g", 1000000 } }
local MIN_STEPS = { 0, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000, 250000, 500000 }
local HEARTHSTONE = 6948

local function has(t, name) return type(t) == "table" and type(t[name]) == "function" end
local function api() return type(C_AuctionHouse) == "table" and C_AuctionHouse or nil end
local function now() return GetTime and GetTime() or 0 end
local function vendorPrice(id, p)
  local v = tonumber((select(11, ns.itemInfo(id))))
  if v == nil and p then v = p.vendor end
  v = ns.auction.vendorValue(id, v)
  return v and v > 0 and v or nil
end
T.vendorPrice = vendorPrice

-- Confirmed merchant refusals can disagree with the sell price in item data (e.g. Blinding Powder).
local noVendorDeals = {
  [5530] = true, -- Blinding Powder
  [7676] = true, -- Thistle Tea
  [6265] = true, -- Soul Shard
  [5512] = true, [5511] = true, [5509] = true, [5510] = true, [9421] = true, -- Healthstones
}
local notesVersion = 0
local dealCache = {}
function T.dealVendorBlocked(id)
  id = tonumber(id)
  if not id then return true end
  if noVendorDeals[id] then return true end
  local s = ns.auction and ns.auction.store and ns.auction.store()
  local nv = type(s) == "table" and type(s.trade) == "table" and type(s.trade.noVendor) == "table" and s.trade.noVendor
  return nv and nv[id] == true or false
end

function T.markNoVendor(id)
  id = tonumber(id)
  if not id then return end
  noVendorDeals[id] = true
  T.notes().noVendor[id] = true
  T.clearLiveDeal(id)
  dealCache.key, dealCache.filterKey = nil, nil
end

-- nil = blocked (a vendor won't take it, or it can't be traded); 0 = no known vendor price, which
-- still allows a flip
local function dealVendorPrice(id, p)
  if not T.dealVendorBlocked(id) then return vendorPrice(id, p) or 0 end
end

local function readNoVendorItems()
  local C = C_Container
  if not (has(C, "GetContainerNumSlots") and has(C, "GetContainerItemInfo")) then return false end
  local changed = false
  local nv = T.notes().noVendor
  for bag = 0, 4 do
    for slot = 1, tonumber(try(C.GetContainerNumSlots, bag)) or 0 do
      local info = try(C.GetContainerItemInfo, bag, slot)
      local id = type(info) == "table" and tonumber(info.itemID)
      if id and info.hasNoValue and not noVendorDeals[id] then
        noVendorDeals[id], changed = true, true
        local rawSell = tonumber((select(11, ns.itemInfo(id))))
        if rawSell and rawSell > 0 then nv[id] = true end
      end
    end
  end
  if changed then notesVersion = notesVersion + 1 end
  return changed
end

-- The client can post and buy from here.
function T.available()
  local C = api()
  return has(C, "PostCommodity") and has(C, "PostItem") and has(C, "SendSearchQuery") and type(ItemLocation) == "table"
end

local function setting(list, value, default)
  for _, e in ipairs(list) do if e[2] == value then return e end end
  for _, e in ipairs(list) do if e[2] == default then return e end end
end
function T.undercut() return setting(T.UNDERCUTS, ns.db().auctionUndercut, 0) end
function T.warnPct() return setting(T.WARNS, ns.db().auctionWarnPct, 30)[2] end
function T.flipPct() return setting(T.FLIPS, ns.db().auctionFlipPct, 30)[2] end
function T.duration() return setting(T.DURATIONS, ns.db().auctionDuration, 2)[2] end
function T.minProfit()
  local v = tonumber(ns.db().auctionMinProfit)
  return v and v > 0 and math.floor(v) or 0
end
function T.maxBuy()
  local v = tonumber(ns.db().auctionMaxBuy)
  return v and v > 0 and math.floor(v) or 0
end
function T.budget()
  local v = tonumber(ns.db().auctionBudget)
  return v and v > 0 and math.floor(v) or 0
end
function T.skipRisky() return ns.db().auctionSkipRisky and true or false end
function T.dealSort()
  local s = ns.db().auctionDealSort
  for _, e in ipairs(T.SORTS) do if e[2] == s then return s end end
  return "profit"
end

----------------------------------------------------------------------------
-- Quick Sell: live price checks
----------------------------------------------------------------------------

-- How Quick Sell prices a post: Undercut = under the lowest listing; Smart = the same, but never
-- under 80% of a usual price of two days or more (a dumped market waits for you); Usual = the usual
-- price (a patient seller), else the undercut.
T.PRICINGS = { { "Undercut", "under" }, { "Smart", "smart" }, { "Usual", "usual" } }
T.SMART_FLOOR = 0.8
T.SELL_FRESH = 600     -- a live check is trusted for 10 minutes
T.SELL_GAP = 1.2       -- seconds between two live checks
T.SELL_AUTO = 30       -- items checked when Quick Sell opens
T.LONE_UNDER = 0.7     -- a listing under 70% of the next price ...
T.LONE_SHARE = 0.1     -- ... holding at most a tenth of what's listed is a lone listing
function T.pricing() return setting(T.PRICINGS, ns.db().auctionPricing, "under")[2] end
function T.skipLone() return not ns.db().auctionKeepLone end
function T.liveFirst() return not ns.db().auctionNoLiveCheck end

-- live[id] = { at, cheapest, depth, second, listed, mine, mineQty }: what a search for the item saw,
-- others' listings and yours apart (cheapest / second = others' two lowest prices, depth = how many
-- of them at the cheapest, mine = your own lowest).
local sellq = { queue = {}, waiting = nil, live = {}, total = 0, done = 0, tried = {} }
T.sellLive = sellq.live

function T.liveCheck(id)
  local l = id and sellq.live[id]
  if l and now() - l.at < T.SELL_FRESH then return l end
end
function T.sellCheckWaiting() return sellq.waiting end
function T.sellCheckState() return sellq.done, #sellq.queue + (sellq.waiting and 1 or 0), sellq.waiting end
function T.sellChecking(id) if sellq.waiting == id then return true end
  for _, q in ipairs(sellq.queue) do if q == id then return true end end
  return false
end

local function sellSearchable() return has(api(), "SendSearchQuery") and ns.auction.isOpen() end

local stepSell
local function nextSell()
  sellq.waiting = nil
  sellq.done = sellq.done + 1
  ns.after(T.SELL_GAP, stepSell)
end
stepSell = function()
  if sellq.waiting then return end
  if not sellSearchable() then sellq.queue = {}; return end
  local id = sellq.queue[1]
  if not id then T.refresh(); return end
  local _, left = T.recheckState()
  if ns.auction.busy() or T.busyBuying() or left > 0 or T.mine.checking then ns.after(0.3, stepSell); return end
  local C = api()
  if has(C, "IsThrottledMessageSystemReady") and try(C.IsThrottledMessageSystemReady) == false then ns.after(0.3, stepSell); return end
  table.remove(sellq.queue, 1)
  sellq.tried[id] = now()
  local key = has(C, "MakeItemKey") and try(C.MakeItemKey, id) or { itemID = id }
  local enum = type(Enum) == "table" and type(Enum.AuctionHouseSortOrder) == "table" and Enum.AuctionHouseSortOrder
  local sorts = enum and enum.Price and { { sortOrder = enum.Price, reverseSort = false } } or {}
  sellq.waiting = id
  if not pcall(C.SendSearchQuery, key, sorts, false) then sellq.queue = {}; sellq.waiting = nil; T.refresh(); return end
  ns.after(5, function()
    if sellq.waiting == id then nextSell(); T.refresh() end
  end)
end

-- Queues live checks for ids (front = first, for a click). Returns how many were queued.
function T.checkSellPrices(ids, front)
  if not sellSearchable() then return 0 end
  local n = 0
  for _, id in ipairs(ids or {}) do
    id = tonumber(id)
    if id and not T.sellChecking(id) then
      if front then table.insert(sellq.queue, 1 + n, id) else sellq.queue[#sellq.queue + 1] = id end
      n = n + 1
    end
  end
  if n > 0 then
    if sellq.done >= sellq.total then sellq.done, sellq.total = 0, 0 end
    sellq.total = sellq.total + n
    stepSell()
    T.refresh()
  end
  return n
end

-- Checks the bag items Quick Sell lists that have no fresh live check (all = also fresh ones).
function T.checkBagPrices(all)
  local ids = {}
  for _, row in ipairs(T.sellable(true, false)) do
    if #ids >= T.SELL_AUTO then break end
    local tried = sellq.tried[row.id]
    if all or (not T.liveCheck(row.id) and not (tried and now() - tried < 60)) then ids[#ids + 1] = row.id end
  end
  return T.checkSellPrices(ids)
end
function T.stopSellChecks() sellq.queue = {}; T.refresh() end
function T.resetSellChecks() sellq.queue, sellq.waiting, sellq.done, sellq.total = {}, nil, 0, 0 end

-- tiers = { { unit, others, own } } from a search: files what it saw.
local function sellRead(id, tiers)
  if sellq.waiting ~= id then return end
  table.sort(tiers, function(a, b) return a.unit < b.unit end)
  local l = { at = now(), listed = 0, depth = 0 }
  for _, t in ipairs(tiers) do
    if t.own > 0 and (not l.mine or t.unit < l.mine) then l.mine = t.unit end
    if t.own > 0 then l.mineQty = (l.mineQty or 0) + t.own end
    if t.others > 0 then
      l.listed = l.listed + t.others
      if not l.cheapest then l.cheapest, l.depth = t.unit, t.others
      elseif t.unit == l.cheapest then l.depth = l.depth + t.others
      elseif not l.second then l.second = t.unit end
    end
  end
  sellq.live[id] = l
  if l.cheapest then ns.auction.record(id, nil, l.cheapest, l.listed)
  elseif not l.mine then ns.auction.record(id, nil, nil, 0) end
  nextSell()
  T.refresh()
end
T.sellRead = sellRead -- for the readers below

-- After a post your own listing is the price to match.
local function notePosted(id, unit, qty)
  local l = sellq.live[id]
  if not l then return end
  if not l.mine or unit < l.mine then l.mine = unit end
  l.mineQty = (l.mineQty or 0) + (qty or 1)
end
T.notePosted = notePosted

-- Parses a user-entered coin string ("25s", "1g 50s", "1.5g", "50c", "0", "any") into copper, or nil if invalid.
function T.parseMoney(raw)
  if type(raw) ~= "string" then return nil end
  local s = raw:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if s == "" or s == "any" or s == "none" or s == "off" or s == "no cap" or s == "0" then return 0 end
  local total, matched = 0, false
  for num, unit in s:gmatch("(%d+%.?%d*)%s*([gsc])") do
    local v = tonumber(num)
    if v then
      matched = true
      local mult = unit == "g" and 10000 or (unit == "s" and 100 or 1)
      total = total + math.floor(v * mult + 0.5)
    end
  end
  if matched then
    local stripped = s:gsub("%d+%.?%d*%s*[gsc]", ""):gsub("[%s,]+", "")
    if stripped == "" then return math.min(99999 * 10000, math.max(0, total)) end
    return nil
  end
  local bare = tonumber(s)
  if bare and bare >= 0 then return math.min(99999 * 10000, math.floor(bare + 0.5)) end
  return nil
end

function T.setMinProfit(copper)
  local v = math.max(0, math.min(99999 * 10000, math.floor(tonumber(copper) or 0)))
  ns.db().auctionMinProfit = v > 0 and v or 0
  if ns.auction and ns.auction.retarget then ns.auction.retarget(ns.auction.sniper and ns.auction.sniper.kind) end
  T.refresh()
  return v
end

function T.stepMinProfit(dir)
  local cur = T.minProfit()
  if dir > 0 then
    for _, st in ipairs(MIN_STEPS) do
      if st > cur then return T.setMinProfit(st) end
    end
    return T.setMinProfit(cur + 100000)
  else
    for i = #MIN_STEPS, 1, -1 do
      if MIN_STEPS[i] < cur then return T.setMinProfit(MIN_STEPS[i]) end
    end
    return T.setMinProfit(0)
  end
end

function T.setMaxBuy(copper)
  local v = math.max(0, math.min(99999 * 10000, math.floor(tonumber(copper) or 0)))
  ns.db().auctionMaxBuy = v > 0 and v or nil
  if ns.auction and ns.auction.retarget then ns.auction.retarget(ns.auction.sniper and ns.auction.sniper.kind) end
  T.refresh()
  return v
end

-- This realm's trading notes, kept with its prices: hidden[id] (left out of Selling and Deals),
-- watch[id] (pinned onto the Sniper's Watch list), noVendor[id] (merchants refuse to buy it),
-- set[id] (a price you nudged, copper each) are the realm's, shared by your characters.
-- What one character did is its own (Michael, 2026-11-25: the paladin showed the warrior's wins):
-- paid[id] = { each, qty } (what the Codex bought it for), log and carry (the trade record),
-- mail (invoices counted), owned (auctions seen) and relist live in trade.chars[<name>].
-- T.notes() returns one table that reads and writes both, so callers never tell them apart.
T.CHAR_KEYS = { paid = true, log = true, carry = true, mail = true, owned = true, relist = true }
local REALM_KEYS = { "hidden", "watch", "noVendor", "set" }
local CHAR_TABLES = { "paid", "log", "relist" }
local proxies = setmetatable({}, { __mode = "k" })
function T.charKey()
  local _, n = ns.try(UnitName, "player")
  return type(n) == "string" and n ~= "" and n or "?"
end
function T.realmNotes()
  local s = ns.auction.store()
  if type(s.trade) ~= "table" then s.trade = {} end
  local t = s.trade
  for _, k in ipairs(REALM_KEYS) do if type(t[k]) ~= "table" then t[k] = {} end end
  if type(t.chars) ~= "table" then t.chars = {} end
  return t
end
function T.charNotes()
  local t = T.realmNotes()
  local key = T.charKey()
  local c = t.chars[key]
  if type(c) ~= "table" then c = {}; t.chars[key] = c end
  for _, k in ipairs(CHAR_TABLES) do if type(c[k]) ~= "table" then c[k] = {} end end
  return c
end
function T.notes()
  local t = T.realmNotes()
  local c = T.charNotes()
  local byChar = proxies[t]
  if not byChar then byChar = {}; proxies[t] = byChar end
  local p = byChar[c]
  if not p then
    p = setmetatable({}, {
      __index = function(_, k) if T.CHAR_KEYS[k] then return c[k] end return t[k] end,
      __newindex = function(_, k, v) if T.CHAR_KEYS[k] then c[k] = v else t[k] = v end end,
    })
    byChar[c] = p
  end
  return p
end

-- The record from before it was kept per character (v0.34.1 and older): it sits on the realm's
-- notes until a character claims it (Market > Your trades).
local function nonEmpty(v) return type(v) == "table" and next(v) ~= nil end
function T.legacyRecord()
  local t = T.realmNotes()
  if not (nonEmpty(t.log) or nonEmpty(t.paid) or (type(t.carry) == "table" and (tonumber(t.carry.n) or 0) > 0)) then return end
  return { trades = type(t.log) == "table" and #t.log or 0, carried = type(t.carry) == "table" and tonumber(t.carry.n) or 0 }
end
function T.claimLegacy()
  local t = T.realmNotes()
  if not T.legacyRecord() then return false end
  local c = T.charNotes()
  -- the log: both, in time order; what runs over the size goes into the carried totals
  local log = {}
  for _, e in ipairs(type(t.log) == "table" and t.log or {}) do log[#log + 1] = e end
  for _, e in ipairs(c.log) do log[#log + 1] = e end
  table.sort(log, function(a, b) return (tonumber(a.t) or 0) < (tonumber(b.t) or 0) end)
  -- the carried record: take the old one, adding this character's own when it has one
  local old = type(t.carry) == "table" and t.carry or nil
  if old then
    local mine = c.carry
    if type(mine) == "table" then
      for k, v in pairs(mine) do
        if type(v) == "number" and k ~= "best" and k ~= "worst" then old[k] = (tonumber(old[k]) or 0) + v end
      end
      old.basis = type(old.basis) == "table" and old.basis or {}
      for id, b in pairs(type(mine.basis) == "table" and mine.basis or {}) do
        local o = old.basis[id]
        if o then o.qty = (o.qty or 0) + (b.qty or 0); o.cost = (o.cost or 0) + (b.cost or 0) else old.basis[id] = b end
      end
    end
    c.carry = old
  end
  c.log = {}
  for i = math.max(1, #log - T.LOG_SIZE + 1), #log do c.log[#c.log + 1] = log[i] end
  if #log > T.LOG_SIZE and ns.auctionMarket and ns.auctionMarket.fold then
    for i = 1, #log - T.LOG_SIZE do ns.auctionMarket.fold(log[i]) end
  end
  for id, pd in pairs(type(t.paid) == "table" and t.paid or {}) do
    local o = c.paid[id]
    if type(o) == "table" and type(pd) == "table" then
      local q1, q2 = tonumber(o.qty) or 0, tonumber(pd.qty) or 0
      local cost = q1 * (tonumber(o.each) or 0) + q2 * (tonumber(pd.each) or 0)
      o.qty = q1 + q2
      o.each = o.qty > 0 and math.floor(cost / o.qty + 0.5) or o.each
      if o.cost or pd.cost then o.cost = (tonumber(o.cost) or 0) + (tonumber(pd.cost) or 0) end
    else
      c.paid[id] = pd
    end
  end
  for _, k in ipairs({ "relist", "owned", "mail" }) do
    if type(t[k]) == "table" then
      c[k] = type(c[k]) == "table" and c[k] or {}
      for key, v in pairs(t[k]) do if c[k][key] == nil then c[k][key] = v end end
    end
  end
  for k in pairs(T.CHAR_KEYS) do t[k] = nil end
  T.logVersion = (T.logVersion or 0) + 1
  return true
end
function T.isHidden(id) return T.notes().hidden[id] and true or false end
function T.hide(id, on) T.notes().hidden[id] = on and true or nil; notesVersion = notesVersion + 1; T.refresh() end
function T.hiddenCount()
  local n = 0
  for _ in pairs(T.notes().hidden) do n = n + 1 end
  return n
end
function T.isWatched(id) return id and T.notes().watch[tonumber(id)] and true or false end
function T.watchCount()
  local n = 0
  for _ in pairs(T.notes().watch) do n = n + 1 end
  return n
end
function T.toggleWatch(id, name, on)
  id = tonumber(id)
  if not id then return false end
  local w = T.notes().watch
  if on == nil then on = not w[id] end
  w[id] = on and true or nil
  if on and type(name) == "string" and name ~= "" then
    local items = ns.auction.store().items
    if type(items[id]) == "table" and not items[id].name then items[id].name = name end
  end
  notesVersion = notesVersion + 1
  if ns.auction and ns.auction.retarget then ns.auction.retarget(ns.auction.sniper and ns.auction.sniper.kind) end
  T.refresh()
  return on and true or false
end

----------------------------------------------------------------------------
-- Prices and protections
----------------------------------------------------------------------------

local function location(row)
  if type(ItemLocation) ~= "table" or not has(ItemLocation, "CreateFromBagAndSlot") then return end
  return try(ItemLocation.CreateFromBagAndSlot, ItemLocation, row.bag, row.slot)
end

local function isCommodity(loc)
  local C = api()
  local status = has(C, "GetItemCommodityStatus") and try(C.GetItemCommodityStatus, loc)
  local enum = type(Enum) == "table" and type(Enum.ItemCommodityStatus) == "table" and Enum.ItemCommodityStatus
  local commodity = enum and enum.Commodity or 2
  return status == commodity
end

-- The price to post one at: { price, base, usual, vendor, floor, blocked, warn, ... }.
-- base = the price to beat: a fresh live check's cheapest listing that isn't yours (a lone listing
-- far under the next one is passed over: skipped = { price, qty }), else the stored lowest, else
-- the usual price. Your own listing at or under it is matched, never undercut (matched = true).
-- price = base minus the undercut, then the pricing mode (Smart keeps it at 80% of usual or more,
-- Usual posts at the usual price); a nudged price wins. floor = the least that pays more than a
-- vendor after the 5% cut: below it the post is blocked. warn = percent under the usual price when
-- that passes the Warn under setting. live = the live check used, if any.
function T.sellPrice(id)
  local p = ns.auction.price(id)
  local l = T.liveCheck(id)
  if not p and not l then return nil, "No price seen yet: scan or search first." end
  p = p or { n = 0 }
  local usual = p.days and p.days >= 2 and p.usual or nil
  local base, skipped, matched
  if l then
    base = l.cheapest
    if base and l.second and T.skipLone() and base < l.second * T.LONE_UNDER
      and l.depth <= math.max(1, math.floor(l.listed * T.LONE_SHARE)) then
      skipped = { price = base, qty = l.depth }
      base = l.second
    end
    if l.mine and (not base or l.mine <= base) then base, matched = l.mine, true end
    if not base then base = p.usual end
  else
    base = p.n > 0 and p.low or p.usual
  end
  if not base or base < 1 then return nil, "No price seen yet: scan or search first." end
  local price = base
  if not matched then
    local u = T.undercut()
    price = u[2] > 0 and math.floor(base * (100 - u[2]) / 100) or base - (u[3] or 1)
  end
  local mode = T.pricing()
  if usual and mode == "usual" then price = usual
  elseif usual and mode == "smart" then price = math.max(price, math.floor(usual * T.SMART_FLOOR)) end
  if price < 1 then price = 1 end
  local notes = T.notes()
  local set = tonumber(notes.set[id])
  if set and set >= 1 then price = set end
  local low = l and l.cheapest or (p.n > 0 and p.low or nil)
  local out = { price = price, base = base, usual = p.usual, vendor = vendorPrice(id, p), source = p.source,
    custom = set and true or nil, low = low, n = l and l.listed or p.n, live = l, skipped = skipped, matched = matched,
    mode = mode }
  local paid = type(notes.paid[id]) == "table" and tonumber(notes.paid[id].each)
  if paid and paid > 0 then out.paid = paid end
  if out.vendor then
    out.floor = math.ceil(out.vendor / (1 - T.CUT))
    if price < out.floor then
      out.blocked = "A vendor pays " .. ns.money(out.vendor) .. " each: sell it there."
    end
  end
  local warn = T.warnPct()
  if not out.blocked and warn > 0 and usual and usual > 0 then
    local under = math.floor((usual - price) * 100 / usual + 0.5)
    if under >= warn then out.warn = under end
  end
  -- a flip you'd sell for less than you paid, once the cut is taken
  if not out.blocked and out.paid and math.floor(price * (1 - T.CUT)) < out.paid then out.loss = out.paid end
  return out
end

-- What a post of qty at sell.price leaves you: { gross, cut, deposit, net, vendor (what a vendor
-- pays for them all), gain (net minus vendor) }. deposit may be nil when the client doesn't say.
function T.sellNet(row, sell, qty)
  sell = sell or (row and T.sellPrice(row.id))
  if not row or not sell then return nil end
  qty = qty or row.count or 1
  local gross = sell.price * qty
  local cut = math.ceil(gross * T.CUT)
  local deposit = row.deposit
  if deposit == nil then
    local loc = location(row)
    if loc then
      local com = isCommodity(loc)
      deposit = T.deposit(row, loc, com, com and qty or 1)
      if deposit and not com then deposit = deposit * qty end
    end
    row.deposit = deposit or false
  end
  if deposit == false then deposit = nil end
  local net = gross - cut - (deposit or 0)
  local vendor = sell.vendor and sell.vendor * qty or 0
  return { gross = gross, cut = cut, deposit = deposit, net = net, vendor = vendor, gain = net - vendor }
end

-- A nudged price: dir -1 / +1 moves it by 5% (at least a copper); nil forgets it.
function T.nudge(id, dir)
  local notes = T.notes()
  if not dir then notes.set[id] = nil; T.refresh(); return end
  local s = T.sellPrice(id)
  if not s then return end
  local step = math.max(1, math.floor(s.price * 0.05))
  notes.set[id] = math.max(1, s.price + dir * step)
  T.refresh()
end

-- How the market looks for selling this item: key, label, colour { r, g, b }.
-- The fourth return is a short tag for the Quick Sell rows (the label goes in its tooltip).
T.STATUS = {
  vendor = { "Vendor pays more", { 1, 0.35, 0.3 }, "VENDOR IT" },
  none = { "None listed: name your price", { 1, 0.82, 0 }, "NONE LISTED" },
  high = { "Above usual: sell now", { 0.3, 0.9, 0.35 }, "SELL NOW" },
  few = { "Few listed: good spot", { 0.3, 0.9, 0.35 }, "FEW LISTED" },
  fair = { "Fair price", { 0.85, 0.85, 0.85 }, "FAIR" },
  falling = { "Falling: sell soon", { 1, 0.82, 0 }, "FALLING" },
  low = { "Below usual: hold?", { 1, 0.55, 0.2 }, "BELOW USUAL" },
  new = { "New: little history", { 0.6, 0.6, 0.6 }, "NEW" },
}
function T.status(id, sell)
  sell = sell or T.sellPrice(id)
  local p = ns.auction.price(id)
  local key = "new"
  if not sell or not p then key = "new"
  elseif sell.blocked then key = "vendor"
  elseif p.n == 0 then key = "none"
  elseif p.usual and p.days and p.days >= 2 and p.usual > 0 then
    local r = sell.base / p.usual
    if r >= 1.1 then key = "high"
    elseif r <= 0.8 then key = "low"
    elseif p.trend and p.trend <= -10 then key = "falling"
    elseif p.n <= 3 then key = "few"
    else key = "fair" end
  end
  local e = T.STATUS[key]
  return key, e[1], e[2], e[3]
end

----------------------------------------------------------------------------
-- Quick sell: your bags
----------------------------------------------------------------------------

local function needed()
  local names = {}
  for _, w in ipairs(type(ns.profSupplies) == "function" and ns.profSupplies() or {}) do
    if w.name then
      local k = w.name:lower()
      local e = names[k] or { n = 0 }
      e.n, e.label = e.n + (tonumber(w.n) or 0), e.label or w.label
      names[k] = e
    end
  end
  return names
end

-- { { id, name, count, bag, slot, icon, sell = T.sellPrice } }, the most valuable first: items you
-- can trade (not bound, not grey, not the Hearthstone) with a price from the auction house.
-- unpriced = also those without a price (sell = nil); hidden = also the ones you hid.
-- What your route ahead (buy/collect steps, vendor quest items) or your profession's current step
-- still needs is held back: count = the spare ones, have = all you carry, need / needFor = what's
-- kept and why. An item needed in full stays in the list with kept = true (Post asks first and posts
-- them all), so nothing in your bags silently goes missing.
function T.sellable(unpriced, hidden)
  local C = type(C_Container) == "table" and C_Container
  if not has(C, "GetContainerNumSlots") or not has(C, "GetContainerItemInfo") then return {} end
  local keep, byID, out = needed(), {}, {}
  local route = ns.vendor and ns.vendor.wanted and ns.vendor.wanted() or {}
  local notes = T.notes()
  for bag = 0, 4 do
    for slot = 1, tonumber(try(C.GetContainerNumSlots, bag)) or 0 do
      local info = try(C.GetContainerItemInfo, bag, slot)
      local id = type(info) == "table" and tonumber(info.itemID)
      if id and not info.isBound and (tonumber(info.quality) or 1) >= 1 and id ~= HEARTHSTONE then
        local name = ns.itemInfo(id) or (type(info.hyperlink) == "string" and info.hyperlink:match("%[(.-)%]"))
        if name and (hidden or not notes.hidden[id]) then
          local e = byID[id]
          if not e then
            local sell = T.sellPrice(id)
            if sell or unpriced then
              local _, _, _, _, _, _, _, _, _, icon = ns.itemInfo(id)
              e = { id = id, name = name, count = 0, bag = bag, slot = slot, icon = icon or info.iconFileID, sell = sell,
                relist = T.isRelist(id) or nil }
              byID[id] = e
              out[#out + 1] = e
            end
          end
          if e then e.count = e.count + (tonumber(info.stackCount) or 1) end
        end
      end
    end
  end
  for _, e in ipairs(out) do
    local r, p = route[e.id], keep[e.name:lower()]
    local need = (r and r.n or 0) + (p and p.n or 0)
    if need > 0 then
      e.have, e.need = e.count, need
      e.needFor = Q.plain((r and r.forText or "") .. ((r and p) and " and " or "") .. (p and p.label or ""))
      if e.count > need then e.count = e.count - need else e.kept = true end
    end
  end
  table.sort(out, function(a, b)
    if (a.kept or false) ~= (b.kept or false) then return not a.kept end
    local va, vb = a.sell and a.sell.price * a.count or -1, b.sell and b.sell.price * b.count or -1
    if va ~= vb then return va > vb end
    return a.name < b.name
  end)
  return out
end

local last = { posts = 0, buys = 0, posted = 0, deposits = 0, spent = 0, cancels = 0, vendored = 0, vendorEarned = 0, vendorProfit = 0, est = 0 }
-- This visit to the auction house: what the Codex spent (the budget counts it).
local visit = { spent = 0, buys = 0, est = 0 }
T.visit = visit
-- The budget left for this visit, or nil without one.
function T.budgetLeft()
  local cap = T.budget()
  if cap <= 0 then return nil end
  return math.max(0, cap - visit.spent)
end
-- This session at the auction house: { posts, posted (value), deposits, buys, spent, cancels, vendored, vendorEarned, vendorProfit }.
function T.ledger() return last end

-- The trade record, kept with the realm's prices (AuctionMarket.lua reads wins and losses from it):
-- notes.log = { { t, k = "post"|"buy"|"sold"|"expired"|"cancel", id, name, qty, each, dep, done } },
-- oldest first, at most T.LOG_SIZE. A post is open until a sale, an expiry or a cancel closes it
-- (done = that kind).
T.LOG_SIZE = 400
T.VENDOR_RUN = 300 -- seconds: vendor sales of one item this close together are one sale
local function stamp() return tonumber(time and time()) or 0 end
T.logVersion = 0
function T.logTrade(kind, id, name, qty, each, dep)
  local log = T.notes().log
  log[#log + 1] = { t = stamp(), k = kind, id = tonumber(id), name = type(name) == "string" and name or nil,
    qty = math.max(1, tonumber(qty) or 1), each = tonumber(each), dep = tonumber(dep) }
  while #log > T.LOG_SIZE do
    -- the oldest entry leaves the log, but its money stays in the record (AuctionMarket.lua's carry)
    local gone = table.remove(log, 1)
    if ns.auctionMarket and ns.auctionMarket.fold then ns.auctionMarket.fold(gone) end
  end
  T.logVersion = T.logVersion + 1
  return log[#log]
end

-- Closes the oldest open post of that name (a sale, an expiry or a cancel) and logs it with the
-- post's quantity, price and deposit; without one it logs what it was given.
function T.closePost(name, kind, id, qty, each)
  if type(name) ~= "string" then return end
  local lower = name:lower()
  for _, e in ipairs(T.notes().log) do
    if e.k == "post" and not e.done and type(e.name) == "string" and e.name:lower() == lower then
      e.done = kind
      return T.logTrade(kind, e.id, e.name, e.qty, e.each, e.dep)
    end
  end
  return T.logTrade(kind, id or (ns.auction.idFor and ns.auction.idFor(name)), name, qty, each)
end
local armed = {} -- key -> time of the first click of a two-click action

local function arm(key)
  if armed[key] and now() - armed[key] < 5 then armed[key] = nil; return true end
  armed[key] = now()
  return false
end
function T.armed(key) return armed[key] and now() - armed[key] < 5 end

-- The deposit for posting row (nil when the client doesn't say).
function T.deposit(row, loc, commodity, qty)
  local C = api()
  if commodity and has(C, "CalculateCommodityDeposit") then
    return tonumber(try(C.CalculateCommodityDeposit, row.id, T.duration(), qty))
  elseif not commodity and has(C, "CalculateItemDeposit") then
    return tonumber(try(C.CalculateItemDeposit, loc, T.duration(), qty))
  end
end

-- Posts row (a T.sellable() entry) on a click: the whole stack of a commodity at the unit price, or
-- one piece of an item. A post far under the usual price needs a second click within 5 s.
-- Returns what happened: "posted", "armed", "blocked", "failed".
-- With live checks on (the default) a row without a fresh one is checked first: that click
-- searches it ("checking"), the next one posts at the price it found.
function T.needsCheck(row)
  return row and T.liveFirst() and sellSearchable() and not T.liveCheck(row.id) and not T.notes().set[row.id] and true or false
end
function T.post(row)
  if T.needsCheck(row) then
    if not T.sellChecking(row.id) then T.checkSellPrices({ row.id }, true) end
    ns.say("Checking what " .. Q.plain(row.name) .. " sells for right now: click again once the price is in.")
    return "checking"
  end
  local sell = row and T.sellPrice(row.id)
  if not sell then return "failed" end
  if sell.blocked then ns.say(sell.blocked); return "blocked" end
  if row.kept and not arm("post:" .. row.id) then
    ns.say(Q.plain(row.name) .. ": " .. (row.needFor ~= "" and row.needFor or "your guide") .. " needs " .. row.need
      .. ". Click Post again within 5 s to post all " .. row.count .. " anyway.")
    return "armed"
  end
  if not row.kept and (sell.warn or sell.loss) and not arm("post:" .. row.id) then
    if sell.loss then
      ns.say(Q.plain(row.name) .. ": " .. ns.money(sell.price) .. " each is less than the " .. ns.money(sell.loss)
        .. " you paid, after the 5% cut. Click Post again within 5 s to post it anyway.")
    else
      ns.say(Q.plain(row.name) .. ": " .. ns.money(sell.price) .. " is " .. sell.warn .. "% under the usual "
        .. ns.money(sell.usual) .. ". Click Post again within 5 s to post it anyway.")
    end
    return "armed"
  end
  local loc = location(row)
  local C = api()
  if not loc or not C then ns.say("This client can't post from the Codex card."); return "failed" end
  local commodity = isCommodity(loc)
  local qty = commodity and row.count or 1
  local ok
  if commodity then ok = pcall(C.PostCommodity, loc, T.duration(), qty, sell.price)
  else ok = pcall(C.PostItem, loc, T.duration(), qty, nil, sell.price) end
  armed["post:" .. row.id] = nil
  if not ok then ns.say("The auction house didn't take the post for " .. Q.plain(row.name) .. "."); return "failed" end
  local deposit = T.deposit(row, loc, commodity, qty)
  last.posts = last.posts + 1
  last.posted = last.posted + sell.price * qty
  last.deposits = last.deposits + (deposit or 0)
  local notes = T.notes()
  local paid = notes.paid[row.id]
  if type(paid) == "table" then
    paid.qty = (tonumber(paid.qty) or 0) - qty
    if paid.qty <= 0 then notes.paid[row.id] = nil end
  end
  last.post = { name = row.name, qty = qty, price = sell.price, deposit = deposit }
  T.logTrade("post", row.id, row.name, qty, sell.price, deposit)
  notePosted(row.id, sell.price, qty)
  notes.relist[row.id] = nil
  ns.say("Posted " .. qty .. " " .. Q.plain(row.name) .. " at " .. ns.money(sell.price) .. " each"
    .. (deposit and deposit > 0 and (" (deposit " .. ns.money(deposit) .. ")") or "") .. ".")
  return "posted"
end

-- The first row Post next would post (not blocked), or nil.
function T.nextPost()
  for _, row in ipairs(T.sellable()) do
    if not row.sell.blocked and not row.kept then return row end
  end
end
function T.postNext()
  local row = T.nextPost()
  if not row then ns.say("Nothing priced to post from your bags."); return "failed" end
  return T.post(row)
end

----------------------------------------------------------------------------
-- Deals: under vendor and flips
----------------------------------------------------------------------------

-- { { id, name, kind = "vendor"|"flip", low, worth, profit, n } }, the biggest profit per unit
-- first: listings a vendor pays more for (profit = vendor - low), and listings at least Flip at
-- under the usual price of two days or more (profit = usual after the 5% cut - low).
-- kind = "vendor" / "flip" keeps one kind; hidden = also the ones you hid. Deals under the Min
-- profit setting (per item) are left out.
-- How sure a flip is to resell at its usual price: key ("safe" / "fair" / "risky"), score, why.
-- More days of history, more listed, steady daily prices count for it; a single listing, prices
-- that swing, and a discount so deep the usual price may be a fluke count against it. Under-vendor
-- deals are always safe: a vendor pays a fixed price.
T.CONFIDENCE = {
  safe = { "SAFE", { 0.3, 0.9, 0.35 }, "Safe flip" },
  fair = { "FAIR", { 1, 0.82, 0 }, "Fair flip" },
  risky = { "RISKY", { 1, 0.55, 0.2 }, "Risky flip" },
}
function T.confidence(id, kind, days, listed, pct)
  if kind == "vendor" then return "safe", 9, { "a vendor pays a fixed price" } end
  local score, why = 0, {}
  days = tonumber(days) or 0
  if days >= 5 then score = score + 2; why[#why + 1] = days .. " days of prices"
  elseif days >= 3 then score = score + 1; why[#why + 1] = days .. " days of prices"
  else why[#why + 1] = "only " .. days .. " days of prices" end
  listed = tonumber(listed) or 0
  if listed >= 10 then score = score + 2; why[#why + 1] = listed .. " listed: it trades a lot"
  elseif listed >= 4 then score = score + 1; why[#why + 1] = listed .. " listed"
  elseif listed <= 1 then score = score - 1; why[#why + 1] = "a single listing" end
  local vals = {}
  local today = math.floor((tonumber(time and time()) or 0) / 86400)
  for _, h in ipairs(ns.auction.history and ns.auction.history(id) or {}) do
    if h.day ~= today and tonumber(h.med or h.low) then vals[#vals + 1] = tonumber(h.med or h.low) end
  end
  if #vals >= 2 then
    table.sort(vals)
    local mid = vals[math.floor((#vals + 1) / 2)]
    local spread = mid > 0 and (vals[#vals] - vals[1]) / mid or 0
    if spread < 0.25 then score = score + 1; why[#why + 1] = "steady price"
    elseif spread > 0.6 then score = score - 1; why[#why + 1] = "the price swings a lot" end
  end
  if (tonumber(pct) or 0) > 150 then score = score - 1; why[#why + 1] = "so cheap the usual price may be a fluke" end
  return score >= 4 and "safe" or (score >= 2 and "fair" or "risky"), score, why
end

local function dealAt(id, p, low, qty, vendor, kind, maxBuy)
  vendor = tonumber(vendor) or 0
  if not low or low <= 0 or qty <= 0 or (maxBuy > 0 and low > maxBuy) then return end
  local dealKind, worth, profit
  if vendor > low then
    dealKind, worth, profit = "vendor", vendor, vendor - low
  elseif p.usual and p.days >= 2 and low <= p.usual * (100 - T.flipPct()) / 100 then
    dealKind, worth = "flip", p.usual
    profit = math.floor(worth * (1 - T.CUT)) - low
  end
  if not profit or profit <= 0 or profit < T.minProfit() or (kind and kind ~= dealKind) then return end
  local pct = math.floor(profit * 100 / low + 0.5)
  local conf, score, why = T.confidence(id, dealKind, p.days, qty, pct)
  if conf == "risky" and T.skipRisky() then return end
  return { id = id, name = p.name or ns.auction.nameOf(id) or ("item " .. id), kind = dealKind,
    low = low, worth = worth, vendor = vendor and vendor > 0 and vendor or nil, usual = p.usual, days = p.days,
    profit = profit, n = qty, source = p.source, at = p.at, pct = pct, conf = conf, confScore = score, confWhy = why }
end

-- An item's price seen through one gear variant (its own low and usual), or with the item's
-- mixed usual taken out when it has variants but this listing names none: a flip on random-enchant
-- gear is only judged against prices of the same suffix.
local function variantView(id, p, suffix)
  local A = ns.auction
  if not (A.hasVariants and (suffix or A.hasVariants(id))) then return p end
  local q = {}
  for k, v in pairs(p) do q[k] = v end
  local vp = suffix and A.variantPrice(id, suffix)
  if vp and (vp.days or 0) >= 2 and vp.usual then
    q.usual, q.days = vp.usual, vp.days
  else
    q.usual, q.days = nil, 0
  end
  q.variant = suffix and vp or nil
  return q
end
local function variantKey(id, suffix, ilvl)
  return { itemID = id, itemSuffix = suffix, itemLevel = tonumber(ilvl) or 0, battlePetSpeciesID = 0 }
end

local function buildDealForID(id, it, kind, hidden, maxBuy, notes)
  if type(it) ~= "table" or T.dealVendorBlocked(id) or (not hidden and notes.hidden[id]) then return end
  local n = tonumber(it.n) or 0
  local low = tonumber(it.low)
  if not low or low <= 0 or n <= 0 or (maxBuy > 0 and low > maxBuy) then return end
  local p = ns.auction.price(id)
  if not p then return end
  local base = variantView(id, p)
  local d = dealAt(id, base, p.low, p.n, p.vendor, kind, maxBuy)
  if d then
    local vendor = dealVendorPrice(id, p)
    if vendor ~= p.vendor then d = dealAt(id, base, p.low, p.n, vendor, kind, maxBuy) end
  end
  -- gear variants: a flip per suffix against that suffix's own usual price, searched exactly
  if base ~= p and (not kind or kind == "flip") then
    local it2 = ns.auction.store().items[id]
    for suffix in pairs(type(it2) == "table" and type(it2.vars) == "table" and it2.vars or {}) do
      local vp = ns.auction.variantPrice(id, suffix)
      if vp and vp.low and (vp.n or 0) > 0 then
        local vd = dealAt(id, variantView(id, p, suffix), vp.low, vp.n, dealVendorPrice(id, p), "flip", maxBuy)
        if vd and (not d or vd.profit > d.profit) then
          vd.suffix, vd.exactKey = suffix, variantKey(id, suffix, vp.ilvl)
          d = vd
        end
      end
    end
  end
  return d
end

function T.deals(kind, hidden, fresh)
  local A = ns.auction
  local store = A.store()
  local items = store.items
  local maxBuy, sortBy = T.maxBuy(), T.dealSort()
  local filterKey = table.concat({ notesVersion, kind or "", hidden and 1 or 0, T.flipPct(), T.minProfit(), maxBuy, T.skipRisky() and 1 or 0,
    A.realmKey and A.realmKey() or "" }, ":")
  local key = filterKey .. ":" .. sortBy
  local version, t = A.version or 0, tonumber(GetTime and GetTime()) or 0
  -- the same choices: new prices are looked at every 1 s at most (or immediately when fresh = true),
  -- and not at all while a full scan is filing thousands
  if not fresh and dealCache.key == key and dealCache.storeRef == items
    and (dealCache.version == version or A.scanning() or t - (dealCache.at or 0) < 1) then
    return dealCache.list
  end
  local notes = T.notes()
  local byID = dealCache.byID
  if not fresh and byID and dealCache.filterKey == filterKey and dealCache.storeRef == items
    and not A.dealDirtyFull and A.recordVersion == version then
    local dirty = A.dealDirtyIDs or {}
    for id in pairs(dirty) do
      byID[id] = buildDealForID(id, items[id], kind, hidden, maxBuy, notes)
      dirty[id] = nil
    end
  else
    byID = {}
    for id, it in pairs(items) do
      byID[id] = buildDealForID(id, it, kind, hidden, maxBuy, notes)
    end
    A.dealDirtyFull, A.dealDirtyIDs = false, {}
  end
  local kept = {}
  for _, d in pairs(byID) do kept[#kept + 1] = d end
  table.sort(kept, function(a, b)
    local la, lb = T.isLive(a.id), T.isLive(b.id)
    if la ~= lb then return la end
    if sortBy == "roi" and a.pct ~= b.pct then return a.pct > b.pct end
    if sortBy == "low" and a.low ~= b.low then return a.low < b.low end
    if sortBy == "age" and (a.at or 0) ~= (b.at or 0) then return (a.at or 0) > (b.at or 0) end
    local pa, pb = T.potential(a), T.potential(b)
    if pa ~= pb then return pa > pb end
    if a.profit ~= b.profit then return a.profit > b.profit end
    return a.id < b.id
  end)
  dealCache.key, dealCache.filterKey, dealCache.byID, dealCache.storeRef = key, filterKey, byID, items
  dealCache.list, dealCache.version, dealCache.at = kept, version, t
  return kept
end

-- Browse prices can include bids, owned listings, and auctions that are already gone.
-- Use them to pick an exact search, and announce only a verified buyout.
local alerted = {}
T.live = {}

function T.sniperCandidate(id, name, low, qty, vkey)
  if T.isHidden(id) then return end
  local p = ns.auction.price(id) or { name = name }
  local vendor = dealVendorPrice(id, p)
  if not vendor then return end
  local kind, maxBuy = ns.auction.sniper.kind, T.maxBuy()
  local suffix = type(vkey) == "table" and tonumber(vkey.itemSuffix) or nil
  if suffix == 0 then suffix = nil end
  local pv = variantView(id, p, suffix)
  local d = dealAt(id, pv, low, qty, vendor, kind, maxBuy)
  if d and suffix then d.suffix, d.exactKey = suffix, vkey end
  -- Refresh previously confirmed deals even when the browse price has gone up.
  return d or (T.live[id] and dealAt(id, pv, p.low, p.n or 0, vendor, kind, maxBuy))
end

function T.clearLiveDeal(id)
  T.live[id], alerted[id] = nil, nil
  local b = T.buying[id]
  if b and b.stage == "ready" then T.buying[id] = nil end
  dealCache.at = 0
end

local function announceSniperDeal(b, low, qty)
  if not b.sniper then return end
  local id, snipe = b.deal.id, ns.auction.sniper
  local p = ns.auction.price(id)
  if not snipe.on then return end
  local vendor = p and dealVendorPrice(id, p)
  local d = vendor and not T.isHidden(id) and dealAt(id, variantView(id, p, b.deal.suffix), low, qty, vendor, snipe.kind, T.maxBuy())
  if not d or b.stage ~= "ready" then
    T.clearLiveDeal(id)
    return
  end
  T.live[id] = now()
  dealCache.at = 0
  if alerted[id] == d.low then return end
  alerted[id] = d.low
  snipe.found = (snipe.found or 0) + 1
  if ns.auction.snipeNote then ns.auction.snipeNote("alerts") end
  if not ns.db().noSnipeSound and type(PlaySound) == "function" then pcall(PlaySound, 18019, "SFX") end
  T.popupSkipped[id] = nil
  if T.refreshPopup then T.refreshPopup() end
  local est, n = b.estAll or b.est, b.allQty or b.qty
  ns.say("Deal: " .. Q.plain(d.name) .. " listed at " .. ns.money(d.low) .. ", +" .. ns.money(d.profit) .. " each"
    .. (est and n and n > 1 and est > 0 and (" (est. +" .. ns.money(est) .. " for " .. n .. ")") or "") .. ".")
end

-- What a deal could make: amount, qty, exact, lots. Once checked, every listing under the limit
-- bought and resold at its worth (after the cut for a flip); before that, one at the lowest price.
function T.potential(d)
  local b = T.buying[d.id]
  local net = d.kind == "vendor" and d.worth or math.floor(d.worth * (1 - T.CUT))
  if b and (b.stage == "ready" or b.stage == "confirm" or b.stage == "pricing" or b.stage == "buying") then
    local qty = b.commodity == false and (b.allQty or b.qty) or b.qty
    local total = b.commodity == false and (b.allTotal or b.total) or b.total
    local lots = b.commodity == false and (b.lots and #b.lots or 1) or nil
    if qty and total and qty > 0 then
      if b.resaleNet then net = b.resaleNet end
      return math.max(0, net * qty - total), qty, true, lots
    end
  end
  return d.profit, 1, false, nil
end

-- The live deals the sniper found this session: count, potential profit in all, the best one.
function T.sniperHaul()
  local n, total, best = 0, 0, nil
  for _, d in ipairs(T.deals(ns.auction.sniper.kind)) do
    if T.isLive(d.id) then
      local amount = T.potential(d)
      n, total = n + 1, total + amount
      if not best or amount > best.amount then best = { name = d.name, amount = amount } end
    end
  end
  return n, total, best
end
function T.isLive(id) return T.live[id] and now() - T.live[id] < 120 or false end

-- The buying state per item:
--   commodity: { stage = "search"|"ready"|"pricing"|"confirm"|"buying"|"none", commodity = true,
--                qty, fullQty, total, fullTotal, maxUnit, tiers = { { unit, qty } }, limit, deal }
--   item:      { stage = "search"|"ready"|"buying"|"none", commodity = false,
--                lots = { { auction, total, qty, unit } }, qty, total, auction, allQty, allTotal, limit, deal }
local buying = {}
T.buying = buying

-- Price protection: a quote older than T.QUOTE_TTL seconds is searched again before Buy spends
-- anything, and a server price lock older than T.LOCK_TTL is let go and searched again.
T.QUOTE_TTL, T.LOCK_TTL = 45, 30
function T.quoteAge(id)
  local b = buying[id]
  local at = b and (b.stage == "confirm" and b.lockedAt or b.quotedAt)
  return at and math.max(0, now() - at) or nil
end
function T.quoteStale(id)
  local b, age = buying[id], T.quoteAge(id)
  if not (b and age) then return false end
  if b.stage == "ready" then return age > T.QUOTE_TTL end
  if b.stage == "confirm" then return age > T.LOCK_TTL end
  return false
end

-- What one bought unit nets when sold on: a vendor's price, or for a flip the resale price after
-- the 5% cut (b.resale: just under the next listing you aren't buying, at most the usual price).
local function netEach(b)
  local d = b.deal
  if d.kind == "vendor" then return d.worth end
  return b.resaleNet or math.floor(d.worth * (1 - T.CUT))
end
T.netEach = netEach
-- The estimated profit of a checked quote: est (the next click's purchase), estAll (every listing
-- under the limit; for item lots all of them).
local function quoteEst(b)
  if not b or not b.deal then return end
  local each = netEach(b)
  if b.qty and b.total then b.est = each * b.qty - b.total end
  local q, t = b.allQty or b.qty, b.allTotal or b.total
  if q and t then b.estAll = each * q - t end
end
T.quoteEst = quoteEst

-- Resale guard for a flip: after you buy everything under the limit, the cheapest listing left is
-- what you'll compete with. units = { { unit, qty }, ... } cheapest first (trimmed in place from the
-- dear end while a unit wouldn't keep Worth at least once resold just under that listing).
-- Returns resale (each, before the cut), its net after the cut, the next listing, units dropped.
local function resaleFit(deal, units, above)
  local minP = math.max(1, T.minProfit())
  local nextAt, dropped = above, 0
  while #units > 0 do
    local resale = math.min(deal.worth, nextAt and (nextAt - 1) or deal.worth)
    local net = math.floor(resale * (1 - T.CUT))
    local last = units[#units]
    if net - last.unit >= minP then return resale, net, nextAt, dropped end
    nextAt = math.min(nextAt or last.unit, last.unit)
    dropped = dropped + (last.qty or 1)
    table.remove(units)
  end
  return nil, nil, nextAt, dropped
end
T.resaleFit = resaleFit

local function purchasePending()
  for _, b in pairs(buying) do
    if b.stage == "buying" or b.stage == "buyingItem" then return true end
  end
  return false
end

-- True while a deal search, price lock or purchase is in flight (the sniper pauses for it).
function T.busyBuying()
  for _, b in pairs(buying) do
    if b.stage == "search" or b.stage == "pricing" or b.stage == "confirm" or b.stage == "buying" or b.stage == "buyingItem" then return true end
  end
  return false
end

-- The most to pay for one: a vendor deal keeps a profit of at least max(1c, Worth at least); a flip
-- stops at the Flip at % discount under usual AND leaves at least Worth at least after the 5% cut.
local function limitFor(deal)
  local minP = math.max(1, T.minProfit())
  local lim
  if deal.kind == "vendor" then
    lim = deal.worth - minP
  else
    local afterCut = math.floor(deal.worth * (1 - T.CUT)) - minP
    local discounted = math.floor(deal.worth * (100 - T.flipPct()) / 100)
    lim = math.min(afterCut, discounted)
  end
  local maxB = T.maxBuy()
  if maxB > 0 and maxB < lim then lim = maxB end
  return lim
end
T.limitFor = limitFor

-- Recalculates a checked commodity deal's total and max unit price for a chosen quantity (e.g. a
-- smaller stack when the player's gold or preference caps it).
local function capCommodity(b, wantQty)
  local tiers = b and b.tiers
  if type(tiers) ~= "table" or #tiers == 0 then return end
  wantQty = math.max(1, math.min(b.fullQty or 1, math.floor(tonumber(wantQty) or b.fullQty or 1)))
  local qty, total, maxUnit = 0, 0, 0
  for _, tr in ipairs(tiers) do
    if qty >= wantQty then break end
    local take = math.min(wantQty - qty, tr.qty)
    if take > 0 then
      qty = qty + take
      total = total + take * tr.unit
      maxUnit = math.max(maxUnit, tr.unit)
    end
  end
  if qty > 0 then
    b.qty, b.total, b.maxUnit = qty, total, maxUnit
    quoteEst(b)
  end
end

-- Adjusts how many of a checked commodity deal to buy: factor 0 = all under the limit, 0.5 = half,
-- 1 = a single stack/piece, or "afford" = as many as current gold covers.
function T.setDealQty(id, mode)
  local b = buying[id]
  if not (b and b.commodity and b.stage == "ready" and b.fullQty) then return false end
  if mode == "all" then
    capCommodity(b, b.fullQty)
  elseif mode == "one" then
    capCommodity(b, 1)
  elseif mode == "half" then
    capCommodity(b, math.max(1, math.floor(b.fullQty / 2)))
  elseif mode == "afford" or mode == "budget" then
    local m, qty = (tonumber(try(GetMoney)) or 0), 0
    if mode == "budget" then m = math.min(m, T.budgetLeft() or m) end
    for _, tr in ipairs(b.tiers or {}) do
      if tr.unit > 0 and m >= tr.unit then
        local take = math.min(tr.qty, math.floor(m / tr.unit))
        qty, m = qty + take, m - take * tr.unit
      else break end
    end
    if qty > 0 then capCommodity(b, qty) end
  elseif type(mode) == "number" then
    capCommodity(b, mode)
  end
  T.refresh()
  return true
end

-- Batch recheck of deals via exact item searches (SendSearchQuery), so every row gets its exact
-- live listings, how many are under the limit, and Gone deals drop off right away.
local recheck = { queue = {}, total = 0, done = 0, active = nil }
function T.recheckState() return recheck.done, #recheck.queue + (recheck.active and 1 or 0) end

local function stepRecheck()
  if not ns.auction.isOpen() then recheck.queue, recheck.active = {}, nil; return end
  if recheck.active then return end
  if #recheck.queue == 0 then T.refresh(); return end
  if T.busyBuying() or ns.auction.busy() then ns.after(0.25, stepRecheck); return end
  local d = table.remove(recheck.queue, 1)
  local C = api()
  if has(C, "IsThrottledMessageSystemReady") and try(C.IsThrottledMessageSystemReady) == false then
    table.insert(recheck.queue, 1, d)
    ns.after(0.25, stepRecheck)
    return
  end
  recheck.active = d.id
  if not T.check(d, true) then
    recheck.active = nil
    recheck.done = recheck.done + 1
    ns.after(0.1, stepRecheck)
  end
end

local function finishCheck(id)
  local b = id and buying[id]
  local doneCb = b and b.onDone
  if b then b.onDone = nil end
  if recheck.active == id then
    recheck.active = nil
    recheck.done = recheck.done + 1
    dealCache.at = 0
    ns.after(0.2, stepRecheck)
  end
  if type(doneCb) == "function" then doneCb(id, b) end
end

function T.recheckDeals(rows)
  local C = api()
  if not ns.auction.isOpen() then return 0 end
  if not has(C, "SendSearchQuery") then
    local names = {}
    for i = 1, math.min(30, #(rows or {})) do if rows[i].name then names[#names + 1] = rows[i].name end end
    return ns.auction.searchNames(names, true)
  end
  recheck.queue, recheck.done, recheck.active = {}, 0, nil
  local seen = {}
  for _, d in ipairs(rows or {}) do
    if #recheck.queue >= 25 then break end
    if d.id and not seen[d.id] then
      seen[d.id] = true
      recheck.queue[#recheck.queue + 1] = d
    end
  end
  recheck.total = #recheck.queue
  stepRecheck()
  T.refresh()
  return recheck.total
end

-- First click: search the item's listings (waits briefly if the client hasn't cached its itemKey yet).
function T.check(deal, fromBatch, browseKey, onDone)
  local C = api()
  if not deal or not deal.id or not has(C, "SendSearchQuery") or purchasePending()
    or not dealVendorPrice(deal.id, deal) then return false end
  if not fromBatch and recheck.active and recheck.active ~= deal.id then
    recheck.queue, recheck.active = {}, nil
  end
  -- A new search replaces any unconfirmed commodity quote.
  for _, ob in pairs(buying) do
    if ob.stage == "pricing" or ob.stage == "confirm" then
      try(C.CancelCommoditiesPurchase)
      ob.stage, ob.why = "none", "cancelled"
    end
  end
  local previous = buying[deal.id]
  local exactKey = browseKey or (previous and previous.exactKey) or deal.exactKey
  local key = exactKey or (has(C, "MakeItemKey") and try(C.MakeItemKey, deal.id)) or { itemID = deal.id }
  local b = { stage = "search", limit = limitFor(deal), deal = deal, key = key, exactKey = exactKey,
    at = now(), tries = 0, sniper = browseKey ~= nil, onDone = onDone }
  buying[deal.id] = b
  local function send()
    if buying[deal.id] ~= b or b.stage ~= "search" then return end
    if ns.auction.busy() or purchasePending() then ns.after(0.25, send); return end
    if has(C, "IsThrottledMessageSystemReady") and try(C.IsThrottledMessageSystemReady) == false and b.tries < 8 then
      b.tries = b.tries + 1
      ns.after(0.25, send)
      return
    end
    if has(C, "GetItemKeyInfo") and not try(C.GetItemKeyInfo, key) and b.tries < 6 then
      b.tries = b.tries + 1
      if type(C_Item) == "table" and has(C_Item, "RequestLoadItemDataByID") then pcall(C_Item.RequestLoadItemDataByID, deal.id) end
      ns.after(0.2, send)
      return
    end
    local enum = type(Enum) == "table" and type(Enum.AuctionHouseSortOrder) == "table" and Enum.AuctionHouseSortOrder
    local sorts = enum and enum.Price and { { sortOrder = enum.Price, reverseSort = false } } or {}
    b.sent = true
    if not pcall(C.SendSearchQuery, key, sorts, false) then
      buying[deal.id] = nil
      finishCheck(deal.id)
      T.refresh()
      return
    end
    ns.after(5, function()
      local cur = buying[deal.id]
      if cur == b and cur.stage == "search" then
        cur.stage, cur.why = "none", "no answer"
        finishCheck(deal.id)
        T.refresh()
      end
    end)
  end
  send()
  T.refresh()
  return true
end

----------------------------------------------------------------------------
-- Your auctions: undercuts and cancelling
----------------------------------------------------------------------------

-- list = { { auction, id, name, qty, unit, timeLeft, sold } } from the last owned-auctions read;
-- cheapest[id] = { unit, at } = the cheapest listing that isn't yours, from Check undercuts.
local mine = { list = {}, cheapest = {}, queue = {}, waiting = nil, asked = false }
T.mine = mine

function T.queryOwned()
  local C = api()
  if not has(C, "QueryOwnedAuctions") then return false end
  mine.asked = true
  return pcall(C.QueryOwnedAuctions, {})
end

local function readOwned()
  local C = api()
  local list = {}
  for i = 1, tonumber(try(C.GetNumOwnedAuctions)) or 0 do
    local r = try(C.GetOwnedAuctionInfo, i)
    if type(r) == "table" and r.auctionID then
      local id = type(r.itemKey) == "table" and tonumber(r.itemKey.itemID) or nil
      local link = type(r.itemLink) == "string" and r.itemLink or nil
      local name = (link and link:match("%[(.-)%]")) or (id and ns.itemInfo(id)) or ("item " .. tostring(id))
      list[#list + 1] = { auction = r.auctionID, id = id, name = name, qty = math.max(1, tonumber(r.quantity) or 1),
        unit = tonumber(r.buyoutAmount), timeLeft = tonumber(r.timeLeftSeconds), sold = r.status == 1 }
    end
  end
  table.sort(list, function(a, b)
    if a.sold ~= b.sold then return not a.sold end
    return a.name < b.name
  end)
  mine.list, mine.at = list, now()
  T.notePosts(list)
  T.refresh()
end

-- Auctions posted outside the Codex (Blizzard's Sell tab, Auctionator) join the trade record the
-- first time your auctions list shows them, so their sales close a post like the Codex's own. A
-- Codex post is matched to its listing (same item and quantity, open, under two days old) instead.
function T.notePosts(list)
  local notes = T.notes()
  notes.owned = type(notes.owned) == "table" and notes.owned or {}
  local known, keep = notes.owned, {}
  for _, row in ipairs(list) do
    local key = tostring(row.auction)
    keep[key] = true
    if not known[key] and not row.sold then
      known[key] = true
      local linked
      for _, e in ipairs(notes.log) do
        if e.k == "post" and not e.done and not e.auction and e.id == row.id and e.qty == row.qty
          and stamp() - (e.t or 0) < 2 * 86400 then
          e.auction, linked = key, true
          break
        end
      end
      if not linked then
        local e = T.logTrade("post", row.id, row.name, row.qty, row.unit)
        e.auction, e.outside = key, true
      end
    end
  end
  -- listings that left (sold, expired, cancelled) are forgotten: their IDs never come back
  if #list > 0 then for key in pairs(known) do if not keep[key] then known[key] = nil end end end
end

-- "undercut" (someone lists for less), "cheapest", "sold", or nil before a check.
function T.ownedState(row)
  if row.sold then return "sold" end
  local c = row.id and mine.cheapest[row.id]
  if not c or not row.unit then return nil end
  if c.unit and c.unit < row.unit then return "undercut", c.unit end
  return "cheapest", c.unit
end

function T.undercutCount()
  local n = 0
  for _, row in ipairs(mine.list) do if T.ownedState(row) == "undercut" then n = n + 1 end end
  return n
end

local function nextUndercut()
  local C = api()
  mine.waiting = nil
  local id = table.remove(mine.queue, 1)
  if not id then mine.checking = nil; T.refresh(); return end
  local key = has(C, "MakeItemKey") and try(C.MakeItemKey, id) or { itemID = id }
  mine.waiting, mine.checking = id, true
  if not pcall(C.SendSearchQuery, key, {}, false) then
    mine.waiting, mine.checking, mine.queue = nil, nil, {}
    ns.say("The auction house didn't take the search.")
    T.refresh()
    return
  end
  ns.after(5, function() if mine.waiting == id then nextUndercut() end end)
end

-- Searches each item you have listed for the cheapest listing that isn't yours.
function T.checkUndercuts()
  local C = api()
  if not has(C, "SendSearchQuery") then return false end
  local seen = {}
  mine.queue = {}
  for _, row in ipairs(mine.list) do
    if row.id and not row.sold and not seen[row.id] then seen[row.id] = true; mine.queue[#mine.queue + 1] = row.id end
  end
  if #mine.queue == 0 then ns.say("You have nothing listed to check."); return false end
  nextUndercut()
  T.refresh()
  return true
end

local function undercutRead(id, unit)
  if mine.waiting ~= id then return end
  mine.cheapest[id] = { unit = unit, at = now() }
  ns.after(1, nextUndercut)
end

-- Cancels one of your auctions on a click; the first click arms it (the deposit is lost).
function T.cancel(row)
  local C = api()
  if not row or not row.auction or not has(C, "CancelAuction") then return "failed" end
  if not arm("cancel:" .. row.auction) then
    ns.say("Cancel " .. Q.plain(row.name) .. "? The deposit is lost and the item comes back by mail. Click Cancel again within 5 s.")
    T.refresh()
    return "armed"
  end
  if not pcall(C.CancelAuction, row.auction) then ns.say("The auction house didn't cancel it."); return "failed" end
  last.cancels = last.cancels + 1
  T.closePost(row.name, "cancel", row.id, row.qty, row.unit)
  if row.id then T.notes().relist[row.id] = stamp() end
  ns.say("Cancelled " .. Q.plain(row.name) .. ": it comes back by mail. Relist it from Quick Sell once it's in your bags.")
  ns.after(1, T.queryOwned)
  return "cancelled"
end

-- The undercut auctions, the most valuable first.
function T.undercutRows()
  local out = {}
  for _, row in ipairs(mine.list) do if T.ownedState(row) == "undercut" then out[#out + 1] = row end end
  table.sort(out, function(a, b) return (a.unit or 0) * (a.qty or 1) > (b.unit or 0) * (b.qty or 1) end)
  return out
end

-- Cancel undercut: one click per auction, the most valuable first. The first click arms it; while
-- armed (5 s, renewed by every cancel for 15 s) each click cancels the next. Cancelled items come
-- back by mail and Quick Sell tags them RELIST.
local walker = { until_ = 0 }
function T.cancelUndercutArmed() return now() < walker.until_ end
function T.cancelNextUndercut()
  local C = api()
  local row = T.undercutRows()[1]
  if not row or not row.auction or not has(C, "CancelAuction") then ns.say("None of your auctions is undercut."); return "none" end
  if now() >= walker.until_ then
    walker.until_ = now() + 5
    local n = #T.undercutRows()
    ns.say(n .. " of your auctions " .. (n == 1 and "is" or "are") .. " undercut. Each click of Cancel undercut cancels one, "
      .. "the most valuable first (its deposit is lost). Click again within 5 s to start.")
    T.refresh()
    return "armed"
  end
  if not pcall(C.CancelAuction, row.auction) then ns.say("The auction house didn't cancel it."); return "failed" end
  walker.until_ = now() + 15
  last.cancels = last.cancels + 1
  T.closePost(row.name, "cancel", row.id, row.qty, row.unit)
  if row.id then T.notes().relist[row.id] = stamp() end
  for i, r in ipairs(mine.list) do if r == row then table.remove(mine.list, i); break end end
  local left = #T.undercutRows()
  ns.say("Cancelled " .. row.qty .. " " .. Q.plain(row.name) .. ": it comes back by mail."
    .. (left > 0 and (" " .. left .. " more undercut: click again.") or " That was the last undercut one."))
  ns.after(1, T.queryOwned)
  T.refresh()
  return "cancelled"
end
function T.isRelist(id)
  local t = id and tonumber(T.notes().relist[id])
  return t and stamp() - t < 7 * 86400 or false
end

-- What a deal's search saw goes into the prices: a deal that is gone (none listed, or none cheap
-- enough any more) leaves the Deals list instead of staying as "Gone".
local function observed(id, b, cheapest, listed)
  if not id then return end
  if cheapest then ns.auction.record(id, b.deal.name, cheapest, listed)
  else ns.auction.record(id, nil, nil, 0) end
  if b.stage ~= "ready" then T.clearLiveDeal(id) end
  announceSniperDeal(b, cheapest, listed)
  dealCache.at = 0
end

-- Updates an item-lot queue's current head (the next single auction PlaceBid will buy).
local function syncItemLots(b)
  if not b or not b.lots or #b.lots == 0 then
    if b then b.stage, b.why, b.qty, b.total, b.auction, b.allQty, b.allTotal = "none", "gone", nil, nil, nil, nil, nil end
    return false
  end
  local allQty, allTotal = 0, 0
  for _, lot in ipairs(b.lots) do
    allQty = allQty + lot.qty
    allTotal = allTotal + lot.total
  end
  local first = b.lots[1]
  b.stage = "ready"
  b.qty, b.total, b.auction, b.unit = first.qty, first.total, first.auction, first.unit
  b.allQty, b.allTotal = allQty, allTotal
  quoteEst(b)
  return true
end

-- Search results: how many cost no more than the limit, and what they come to.
local function readCommodity(id)
  local C, b = api(), buying[id]
  if id and T.sellCheckWaiting() == id and not (has(C, "HasFullCommoditySearchResults")
    and try(C.HasFullCommoditySearchResults, id) == false and (tonumber(try(C.GetNumCommoditySearchResults, id)) or 0) == 0) then
    local tiers = {}
    for i = 1, tonumber(try(C.GetNumCommoditySearchResults, id)) or 0 do
      local r = try(C.GetCommoditySearchResultInfo, id, i)
      local unit = type(r) == "table" and tonumber(r.unitPrice)
      local all = type(r) == "table" and tonumber(r.quantity) or 0
      local own = type(r) == "table" and (r.containsAccountItem and all or tonumber(r.numOwnerItems) or (r.containsOwnerItem and all or 0)) or 0
      if unit and unit > 0 then tiers[#tiers + 1] = { unit = unit, others = math.max(0, all - own), own = own } end
    end
    T.sellRead(id, tiers)
  end
  if mine.waiting == id then
    local best
    for i = 1, tonumber(try(C.GetNumCommoditySearchResults, id)) or 0 do
      local r = try(C.GetCommoditySearchResultInfo, id, i)
      local unit = type(r) == "table" and tonumber(r.unitPrice)
      local others = type(r) == "table" and ((tonumber(r.quantity) or 0) - (tonumber(r.numOwnerItems) or (r.containsOwnerItem and r.quantity or 0)))
      if unit and others and others > 0 and (not best or unit < best) then best = unit end
    end
    undercutRead(id, best)
  end
  if not b or b.stage ~= "search" or not b.sent then return end
  -- if the client says more commodity results are still arriving and 0 are loaded yet, wait for them
  if has(C, "HasFullCommoditySearchResults") and try(C.HasFullCommoditySearchResults, id) == false
    and (tonumber(try(C.GetNumCommoditySearchResults, id)) or 0) == 0 then
    return
  end
  local qty, total, cheapest, listed, maxUnit = 0, 0, nil, 0, 0
  local tiers, above = {}, nil
  for i = 1, tonumber(try(C.GetNumCommoditySearchResults, id)) or 0 do
    local r = try(C.GetCommoditySearchResultInfo, id, i)
    local unit = type(r) == "table" and tonumber(r.unitPrice)
    local rawN = type(r) == "table" and tonumber(r.quantity) or 0
    local ownN = type(r) == "table" and (tonumber(r.numOwnerItems) or (r.containsOwnerItem and rawN or 0)) or 0
    local n = rawN - ownN
    if unit and unit > 0 and n > 0 and not r.containsAccountItem then
      listed = listed + n
      if not cheapest or unit < cheapest then cheapest = unit end
      if unit <= b.limit then
        tiers[#tiers + 1] = { unit = unit, qty = n }
      elseif not above or unit < above then
        above = unit
      end
    end
  end
  table.sort(tiers, function(x, y) return x.unit < y.unit end)
  local found = #tiers
  if found > 0 and b.deal.kind ~= "vendor" then
    b.resale, b.resaleNet, b.nextListing, b.trimmed = resaleFit(b.deal, tiers, above)
  else
    b.resale, b.resaleNet, b.nextListing, b.trimmed = nil, nil, above, 0
  end
  for _, tr in ipairs(tiers) do
    qty, total = qty + tr.qty, total + tr.unit * tr.qty
    if tr.unit > maxUnit then maxUnit = tr.unit end
  end
  b.commodity, b.tiers, b.fullQty, b.fullTotal = true, tiers, qty, total
  if qty > 0 then
    b.stage, b.qty, b.total, b.maxUnit, b.quotedAt = "ready", qty, total, maxUnit, now()
    b.allQty, b.allTotal = nil, nil
    quoteEst(b)
  else
    b.stage, b.why = "none", found > 0 and "no margin" or "gone"
  end
  observed(id, b, cheapest, listed)
  finishCheck(id)
  T.refresh()
end

-- Non-stackable item results can group multiple copies at the same price.
-- The auction ID and buyout still describe one purchasable copy.
local function itemLotQuantity(result, maxStack)
  local qty = math.max(1, tonumber(result.quantity) or 1)
  if qty == 1 or maxStack == 1 then return 1 end
  if maxStack and qty <= maxStack then return qty end
end

local function sameItemVariant(a, b)
  return (a.itemLevel or 0) == (b.itemLevel or 0)
    and (a.itemSuffix or 0) == (b.itemSuffix or 0)
    and (a.battlePetSpeciesID or 0) == (b.battlePetSpeciesID or 0)
end

local function readItems(key)
  local C = api()
  local id = type(key) == "table" and tonumber(key.itemID)
  if not id then return end
  local maxStack = tonumber((select(8, ns.itemInfo(id))))
  if T.sellCheckWaiting() == id then
    local tiers = {}
    for i = 1, tonumber(try(C.GetNumItemSearchResults, key)) or 0 do
      local r = try(C.GetItemSearchResultInfo, key, i)
      local buyout = type(r) == "table" and tonumber(r.buyoutAmount)
      local qty = buyout and buyout > 0 and itemLotQuantity(r, maxStack)
      if qty then
        local own = (r.containsOwnerItem or r.containsAccountItem) and qty or 0
        tiers[#tiers + 1] = { unit = math.ceil(buyout / qty), others = qty - own, own = own }
      end
    end
    T.sellRead(id, tiers)
  end
  if id and mine.waiting == id then
    local best
    for i = 1, tonumber(try(C.GetNumItemSearchResults, key)) or 0 do
      local r = try(C.GetItemSearchResultInfo, key, i)
      local buyout = type(r) == "table" and tonumber(r.buyoutAmount)
      if buyout and buyout > 0 and not r.containsOwnerItem and not r.containsAccountItem then
        local qty = itemLotQuantity(r, maxStack)
        if qty then
          local unit = math.ceil(buyout / qty)
          if not best or unit < best then best = unit end
        end
      end
    end
    undercutRead(id, best)
  end
  local b = id and buying[id]
  if not b or b.stage ~= "search" or not b.sent then return end
  if b.exactKey and not sameItemVariant(b.exactKey, key) then return end
  local searchKey = b.key or key
  local totalResults = tonumber(try(C.GetNumItemSearchResults, searchKey)) or 0
  if totalResults == 0 and searchKey ~= key then
    searchKey = key
    totalResults = tonumber(try(C.GetNumItemSearchResults, searchKey)) or 0
  end
  if has(C, "HasFullItemSearchResults") and try(C.HasFullItemSearchResults, searchKey) == false then
    if totalResults == 0 then return end
    if has(C, "RequestMoreItemSearchResults") and (b.pages or 0) < 3 then
      b.pages = (b.pages or 0) + 1
      pcall(C.RequestMoreItemSearchResults, searchKey)
      return
    end
  end
  local lots, seen, cheapest, listed, above = {}, {}, nil, 0, nil
  for i = 1, totalResults do
    local r = try(C.GetItemSearchResultInfo, searchKey, i)
    local buyout = type(r) == "table" and tonumber(r.buyoutAmount)
    local n = type(r) == "table" and itemLotQuantity(r, maxStack)
    local auctionID = type(r) == "table" and tonumber(r.auctionID)
    if n and buyout and buyout > 0 and auctionID and auctionID > 0 and not seen[auctionID]
      and not r.containsOwnerItem and not r.containsAccountItem then
      seen[auctionID] = true
      local unit = math.ceil(buyout / n)
      listed = listed + n
      if not cheapest or unit < cheapest then cheapest = unit end
      if unit <= b.limit then
        lots[#lots + 1] = { auction = auctionID, total = buyout, qty = n, unit = unit }
      elseif not above or unit < above then
        above = unit
      end
    end
  end
  table.sort(lots, function(x, y)
    if x.unit ~= y.unit then return x.unit < y.unit end
    if x.total ~= y.total then return x.total < y.total end
    return (tonumber(x.auction) or 0) < (tonumber(y.auction) or 0)
  end)
  local found = #lots
  if found > 0 and b.deal.kind ~= "vendor" then
    b.resale, b.resaleNet, b.nextListing, b.trimmed = resaleFit(b.deal, lots, above)
  else
    b.resale, b.resaleNet, b.nextListing, b.trimmed = nil, nil, above, 0
  end
  b.commodity, b.lots = false, lots
  if syncItemLots(b) then b.quotedAt = now()
  elseif found > 0 then b.why = "no margin" end
  observed(id, b, cheapest, listed)
  finishCheck(id)
  T.refresh()
end

local function money() return tonumber(try(GetMoney)) or 0 end

-- A purchase: the session ledger, and what you paid (a later post under it asks twice).
local function boughtFor(id, deal, qty, total, moreLeft, each, note)
  qty = math.max(1, tonumber(qty) or 1)
  total = math.max(0, tonumber(total) or 0)
  each = tonumber(each) or (deal.kind == "vendor" and deal.worth or math.floor(deal.worth * (1 - T.CUT)))
  local net = each * qty - total
  last.buys = last.buys + 1
  last.spent = last.spent + total
  last.est = (last.est or 0) + net
  visit.spent, visit.buys, visit.est = visit.spent + total, visit.buys + 1, (visit.est or 0) + net
  last.buy = { name = deal.name, qty = qty, total = total, est = net }
  -- a buy of a deal the sniper found (live, or bought while it runs) counts in its session record
  local A = ns.auction
  if A.snipeNote and (T.live[id] or (buying[id] and buying[id].sniper) or (A.sniper and A.sniper.on)) then
    A.snipeNote("buys"); A.snipeNote("spent", total); A.snipeNote("est", net, deal.name)
  end
  local e = T.logTrade("buy", id, deal.name, qty, math.floor(total / qty + 0.5))
  e.total, e.dealKind, e.vendor, e.est = total, deal.kind, deal.vendor, net
  local notes = T.notes()
  local old = type(notes.paid[id]) == "table" and notes.paid[id]
  local sumQty, cost = qty, total
  if old and tonumber(old.qty) and tonumber(old.each) then
    local oldCost = tonumber(old.cost) or (old.qty * old.each)
    sumQty, cost = sumQty + old.qty, cost + oldCost
  end
  notes.paid[id] = {
    each = math.ceil(cost / sumQty),
    cost = cost,
    qty = sumQty,
    name = deal.name,
    kind = (deal.kind == "vendor" or (old and old.kind == "vendor")) and "vendor" or deal.kind,
    vendor = deal.vendor or (old and old.vendor),
  }
  local gain = net > 0 and (" (+" .. ns.money(net) .. (deal.kind == "vendor" and " at vendor)" or " est. flip)")) or ""
  local tail = moreLeft and moreLeft > 0 and (" " .. moreLeft .. " more under the limit - click Buy again.") or ""
  ns.say("Bought " .. qty .. " " .. Q.plain(deal.name) .. " for " .. ns.money(total) .. gain .. "." .. tail .. (note or ""))
end

-- Records a vendor sale of an item the Codex bought (either when sold at a merchant or marked from Holdings).
function T.recordVendorSale(id, name, qty, eachCopper, quiet)
  id = tonumber(id)
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  local p = id and ns.auction.price(id)
  eachCopper = ns.auction.vendorValue(id, tonumber(eachCopper) or (id and vendorPrice(id, p))) or 0
  if not id or eachCopper <= 0 then return nil end
  name = type(name) == "string" and name ~= "" and name or (p and p.name) or ns.auction.nameOf(id) or ("item " .. id)
  -- only what the Codex bought counts: your own loot of the same item isn't sniping money
  local market = ns.auctionMarket
  local open = market and market.record and market.record().openByID[id]
  local held = open and tonumber(open.qty) or 0
  local paidNote = type(T.notes().paid[id]) == "table" and tonumber(T.notes().paid[id].qty) or 0
  held = math.max(held, paidNote)
  if held <= 0 then return nil end
  qty = math.min(qty, held)
  local total = eachCopper * qty
  local notes = T.notes()
  local paid = type(notes.paid[id]) == "table" and notes.paid[id]
  local costBasis
  if paid and (tonumber(paid.qty) or 0) > 0 then
    local take = math.min(qty, tonumber(paid.qty) or qty)
    local paidTotal = tonumber(paid.cost) or (paid.qty * (tonumber(paid.each) or 0))
    costBasis = math.floor(paidTotal * take / paid.qty + 0.5)
    paid.qty = paid.qty - take
    paid.cost = math.max(0, paidTotal - costBasis)
    if paid.qty <= 0 then notes.paid[id] = nil end
  elseif ns.auctionMarket and ns.auctionMarket.openCost then
    costBasis = ns.auctionMarket.openCost(id, qty)
  end
  -- one sale run: right-clicking a stack slot by slot is one sale (one win), not one per slot
  local log = notes.log
  local e = log[#log]
  if e and e.k == "vendor" and e.id == id and e.each == eachCopper and stamp() - (tonumber(e.t) or 0) <= T.VENDOR_RUN then
    e.qty = (tonumber(e.qty) or 0) + qty
    e.total = (tonumber(e.total) or 0) + total
    e.t = stamp()
    T.logVersion = T.logVersion + 1
  else
    e = T.logTrade("vendor", id, name, qty, eachCopper)
    e.total = total
  end
  last.vendored = (last.vendored or 0) + qty
  last.vendorEarned = (last.vendorEarned or 0) + total
  if costBasis then
    local profit = total - costBasis
    last.vendorProfit = (last.vendorProfit or 0) + profit
    if not quiet then
      local sign = profit >= 0 and "+" or "-"
      ns.say("Vendored " .. qty .. " " .. Q.plain(name) .. " for " .. ns.money(total)
        .. " (" .. sign .. ns.money(math.abs(profit)) .. " snipe " .. (profit >= 0 and "profit" or "loss") .. ").")
    end
  elseif not quiet then
    ns.say("Vendored " .. qty .. " " .. Q.plain(name) .. " for " .. ns.money(total) .. ".")
  end
  T.refresh()
  return e
end

-- Resolves an open holding from Market > Your trades ("vendor" logs a vendor sale; "clear" removes used/kept items).
function T.resolveHolding(id, name, qty, how)
  id = tonumber(id)
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  if not id then return false end
  if how == "vendor" then
    local v = vendorPrice(id, ns.auction.price(id))
    if not v or v <= 0 then
      ns.say(Q.plain(name or "That item") .. " has no known vendor price yet: hover or equip/bag it once first.")
      return false
    end
    T.recordVendorSale(id, name, qty, v)
    return true
  end
  local notes = T.notes()
  notes.paid[id] = nil
  T.logTrade("clear", id, name, qty, 0)
  T.refresh()
  return true
end

-- Completes an in-flight single-auction item purchase once verified (by AUCTION_HOUSE_PURCHASE_COMPLETED,
-- ERR_AUCTION_WON_S, or a money/auction fallback when an event is absent).
-- Item buys the 2.5 s wait gave up on: auctionID -> { id, deal, qty, total, purse, at, each },
-- watched for T.LATE_WATCH seconds for AUCTION_HOUSE_PURCHASE_COMPLETED or the purse dropping by
-- the buyout.
T.lateBuys = {}
T.LATE_WATCH = 60
local function lateBought(auction)
  local l = T.lateBuys[auction]
  T.lateBuys[auction] = nil
  if not l or now() - l.at > T.LATE_WATCH then return end
  boughtFor(l.id, l.deal, l.qty, l.total, nil, l.each, " (confirmed late)")
  T.refresh()
end

local function finishItemBuy(id, ok, why)
  local b = buying[id]
  if not b or b.stage ~= "buyingItem" then return end
  local p = b.pendingLot
  b.pendingLot = nil
  if not ok or not p then
    b.stage, b.why = "ready", why or "failed"
    syncItemLots(b)
    ns.say("Couldn't buy " .. Q.plain(b.deal.name) .. (why and (": " .. why) or ": that listing may already be gone."))
    T.refresh()
    return
  end
  if b.lots and b.lots[1] and b.lots[1].auction == p.auction then
    table.remove(b.lots, 1)
  else
    for i, lot in ipairs(b.lots or {}) do
      if lot.auction == p.auction then table.remove(b.lots, i); break end
    end
  end
  local more = b.lots and #b.lots or 0
  boughtFor(id, b.deal, p.qty, p.total, more, netEach(b))
  if more > 0 then
    syncItemLots(b)
  else
    buying[id] = nil
    -- check if the deal has other listings or should drop off the Deals list (keep pStore.low intact for history)
    local pStore = ns.auction.store().items[id]
    if type(pStore) == "table" then
      pStore.n = math.max(0, (tonumber(pStore.n) or 1) - p.qty)
      ns.auction.version = (ns.auction.version or 0) + 1
    end
    dealCache.at = 0
  end
  T.refresh()
end

-- Second click (and third for a commodity): buy what the search found, with strict price verification.
function T.buy(id)
  local C, b = api(), buying[id]
  if not b or not C or purchasePending() or ns.auction.scanning() then return false end
  if b.stage ~= "ready" and b.stage ~= "confirm" then return false end
  local liveVendor = dealVendorPrice(id, ns.auction.price(id) or b.deal)
  if not liveVendor or (b.deal.kind == "vendor" and liveVendor <= 0) then
    T.cancelBuy(id)
    ns.say(Q.plain(b.deal.name) .. ": excluded from Deals without an eligible NPC sell price.")
    return false
  end
  -- a vendor deal is only as good as what the vendor pays today
  if b.deal.kind == "vendor" and liveVendor < b.deal.worth then
    local d = {}
    for k, v in pairs(b.deal) do d[k] = v end
    d.worth, d.vendor, d.profit = liveVendor, liveVendor, liveVendor - d.low
    b.deal = d
    quoteEst(b)
  end
  -- an old quote or price lock: search again before any gold moves
  if T.quoteStale(id) then
    local age = math.floor(T.quoteAge(id) or 0)
    if b.stage == "confirm" then try(C.CancelCommoditiesPurchase) end
    ns.say(Q.plain(b.deal.name) .. ": that price is " .. age .. " s old, so the Codex is checking the listings again. Click Buy once it shows.")
    T.check(b.deal)
    return false
  end
  local unit = math.ceil(b.total / math.max(1, b.qty))
  local limit = math.min(b.limit, limitFor(b.deal))
  if math.max(unit, b.maxUnit or 0) > limit then
    if b.stage == "confirm" then try(C.CancelCommoditiesPurchase) end
    b.stage, b.why = "none", "over limit"
    ns.say(Q.plain(b.deal.name) .. ": above your current deal limit (" .. ns.money(math.max(0, limit)) .. "). Check listings again.")
    T.refresh()
    return false
  end
  if b.stage == "ready" then
    for _, other in pairs(buying) do
      if other.stage == "pricing" or other.stage == "confirm" then return false end
    end
    if b.total > money() then
      if b.commodity and b.qty > 1 then
        T.setDealQty(id, "afford")
        if b.total <= money() and b.qty >= 1 then
          ns.say("Adjusted quantity to " .. b.qty .. " " .. Q.plain(b.deal.name) .. " (" .. ns.money(b.total) .. ") to fit your gold. Click Buy again.")
          return false
        end
      end
      ns.say("Not enough money: " .. ns.money(b.total) .. " needed.")
      return false
    end
    local budgetLeft = T.budgetLeft()
    if budgetLeft and b.total > budgetLeft then
      if b.commodity and b.qty > 1 then
        local before = b.qty
        T.setDealQty(id, "budget")
        if b.total <= budgetLeft and b.qty >= 1 and b.qty < before then
          ns.say("Cut to " .. b.qty .. " " .. Q.plain(b.deal.name) .. " (" .. ns.money(b.total) .. ") to stay in your budget. Click Buy again.")
          return false
        end
      end
      ns.say("That's over your budget for this visit: " .. ns.money(budgetLeft) .. " left of " .. ns.money(T.budget())
        .. ". Raise it on the Deals page.")
      return false
    end
    -- full bags: the purchase would go to the mailbox (or fail) and the checks after it misread it
    local free = ns.mailbox and ns.mailbox.freeSlots and ns.mailbox.freeSlots()
    if free and free <= 0 then
      ns.say("Your bags are full: make room before buying " .. Q.plain(b.deal.name) .. ".")
      return false
    end
    if b.commodity then
      if not pcall(C.StartCommoditiesPurchase, id, b.qty) then return false end
      b.stage, b.expect, b.expectUnit = "pricing", b.total, unit
      ns.after(5, function()
        local x = buying[id]
        if x == b and x.stage == "pricing" then
          try(C.CancelCommoditiesPurchase)
          x.stage, x.why = "none", "no price"
          T.refresh()
        end
      end)
      T.refresh()
      return true
    end
    -- Item auction: verify auctionID still exists in current search results if readable, and buy ONLY this 1 auction
    if has(C, "GetAuctionInfoByID") then
      local info = try(C.GetAuctionInfoByID, b.auction)
      if type(info) == "table" and info.buyoutAmount and tonumber(info.buyoutAmount) ~= b.total then
        b.stage, b.why = "none", "price went up"
        ns.say(Q.plain(b.deal.name) .. ": listing buyout changed to " .. ns.money(info.buyoutAmount) .. ". Blocked.")
        T.refresh()
        return false
      end
    end
    local purseBefore = money()
    if not pcall(C.PlaceBid, b.auction, b.total) then
      ns.say("Couldn't buy " .. Q.plain(b.deal.name) .. ": the auction house refused the bid.")
      return false
    end
    if ns.stats then ns.stats.expect("buys", b.total) end
    b.stage = "buyingItem"
    b.pendingLot = { auction = b.auction, qty = b.qty, total = b.total, purse = purseBefore, at = now() }
    -- If PlaceBid already settled synchronously (e.g. instant purse drop on some clients / tests), finish right away;
    -- Otherwise wait for the auction event or a deduction matching the full buyout.
    if money() == purseBefore - b.total then
      finishItemBuy(id, true)
    else
      local lotAuction = b.auction
      ns.after(2.5, function()
        local cur = buying[id]
        if cur == b and cur.stage == "buyingItem" and cur.pendingLot and cur.pendingLot.auction == lotAuction then
          local pl = cur.pendingLot
          -- the purse fell by the buyout (other money moved too): it went through
          if money() <= pl.purse - pl.total then finishItemBuy(id, true); return end
          if cur.lots and cur.lots[1] and cur.lots[1].auction == lotAuction then table.remove(cur.lots, 1) end
          -- still watched for a while: a late completion is logged as the buy it was, so the item
          -- never sells later as if it had cost nothing
          T.lateBuys[lotAuction] = { id = id, deal = cur.deal, qty = pl.qty, total = pl.total, purse = pl.purse, at = now(),
            each = netEach(cur) }
          finishItemBuy(id, false, "not confirmed yet (it's logged if it comes through)")
        end
      end)
    end
    T.refresh()
    return true
  elseif b.stage == "confirm" then
    if b.total > money() then
      try(C.CancelCommoditiesPurchase)
      b.stage, b.why = "none", "not enough gold"
      ns.say("Not enough money: " .. ns.money(b.total) .. " needed.")
      T.refresh()
      return false
    end
    if not pcall(C.ConfirmCommoditiesPurchase, id, b.qty) then return false end
    if ns.stats then ns.stats.expect("buys", b.total) end
    b.stage, b.purse = "buying", money()
    ns.after(6, function()
      local x = buying[id]
      if x == b and x.stage == "buying" then x.stage, x.why = "none", "timed out"; T.refresh() end
    end)
    T.refresh()
    return true
  end
  return false
end

-- Cancels an unconfirmed commodity purchase or clears a checked state.
function T.cancelBuy(id)
  local b = id and buying[id]
  if not b then return end
  if b.stage == "pricing" or b.stage == "confirm" then try(api().CancelCommoditiesPurchase) end
  buying[id] = nil
  T.refresh()
end

-- Strict price safeguard for a started commodity purchase:
-- Cancels immediately if the server's total exceeds the exact price shown on the Buy button OR if
-- the unit price crosses the deal's profitable ceiling (never allows a silent 2% creep or loss!).
local function priced(unit, total)
  for id, b in pairs(buying) do
    if b.stage == "pricing" then
      total, unit = tonumber(total), tonumber(unit)
      local avgUnit = total and b.qty and b.qty > 0 and math.ceil(total / b.qty) or unit
      if not total or total > b.expect or (b.limit and avgUnit and avgUnit > b.limit) then
        try(api().CancelCommoditiesPurchase)
        b.stage, b.why = "none", "price went up"
        ns.say(Q.plain(b.deal.name) .. ": server quoted " .. ns.money(total or 0) .. " (was " .. ns.money(b.expect)
          .. "), so the Codex cancelled it to protect your gold.")
      else
        b.stage, b.total, b.lockedAt = "confirm", total, now()
        quoteEst(b)
      end
      T.refresh()
      return
    end
  end
end

local function bought(ok)
  for id, b in pairs(buying) do
    if b.stage == "buying" then
      if ok then
        -- what the purse actually lost, when it has moved by now (else the locked total)
        local cost, note = b.total, nil
        local drop = b.purse and (b.purse - money()) or 0
        if drop > 0 and drop ~= b.total then
          cost = drop
          if drop > b.total then
            note = " Charged " .. ns.money(drop - b.total) .. " more than the quote: check the mailbox."
          end
        end
        boughtFor(id, b.deal, b.qty, cost, nil, netEach(b), note)
        buying[id] = nil
        -- recheck if any remain or clear stale count (keep pStore.low intact for history)
        local pStore = ns.auction.store().items[id]
        if type(pStore) == "table" then
          pStore.n = math.max(0, (tonumber(pStore.n) or b.qty) - b.qty)
          ns.auction.version = (ns.auction.version or 0) + 1
        end
        dealCache.at = 0
      else
        b.stage, b.why = "none", "failed"
        ns.say("Couldn't buy " .. Q.plain(b.deal.name) .. ": the game says why.")
      end
      T.refresh()
      return
    end
  end
end

-- Quick-action helper: returns the best actionable deal on the page ("confirm" first, then "ready",
-- then the top unchecked deal), and the label for the header's quick-snipe action button.
function T.nextDealAction(kind, hidden)
  local rows = T.deals(kind, hidden)
  for _, d in ipairs(rows) do
    local b = buying[d.id]
    if b and b.stage == "confirm" then return d, "confirm", b end
  end
  -- A filter can remove a quoted row while the server is still holding its lock.
  for _, b in pairs(buying) do
    if b.stage == "pricing" or b.stage == "confirm" then return b.deal, "cancel", b end
  end
  for _, d in ipairs(rows) do
    local b = buying[d.id]
    if b and b.stage == "ready" then return d, "buy", b end
  end
  for _, d in ipairs(rows) do
    local b = buying[d.id]
    if not b or b.stage == "none" then return d, "check", b end
  end
end

-- The deal button's label for an item.
function T.dealLabel(id)
  local b = buying[id]
  if not b then return "Check" end
  if b.stage == "search" then return "Looking..." end
  if (b.stage == "ready" or b.stage == "confirm") and T.quoteStale(id) then return "Recheck price" end
  if b.stage == "ready" then
    if b.commodity == false and b.lots and #b.lots > 1 then
      return "Buy " .. b.qty .. " for " .. ns.money(b.total) .. " (1/" .. #b.lots .. ")"
    end
    return "Buy " .. b.qty .. " for " .. ns.money(b.total)
  end
  if b.stage == "pricing" then return "Locking..." end
  if b.stage == "confirm" then return "Confirm " .. ns.money(b.total) end
  if b.stage == "buying" or b.stage == "buyingItem" then return "Buying..." end
  if b.why == "price went up" then return "Price rose" end
  if b.why == "no answer" then return "Retry check" end
  if b.why == "over limit" then return "Check again" end
  if b.why == "no margin" then return "No margin" end
  return "Gone"
end

-- The basket: every checked deal on the list that is ready to buy (or locked to confirm):
-- n, cost of the next click on each, estimated profit of those clicks, cost and profit of every
-- listing under the limit.
function T.basket(kind, hidden)
  local n, cost, est, costAll, estAll = 0, 0, 0, 0, 0
  for _, d in ipairs(T.deals(kind, hidden)) do
    local b = buying[d.id]
    if b and (b.stage == "ready" or b.stage == "confirm") and b.total and not T.quoteStale(d.id) then
      n = n + 1
      cost, est = cost + b.total, est + (b.est or 0)
      costAll, estAll = costAll + (b.allTotal or b.total), estAll + (b.estAll or b.est or 0)
    end
  end
  return { n = n, cost = cost, est = est, costAll = costAll, estAll = estAll }
end

-- Redraws the Codex tab (AuctionPanel.lua) when it shows.
----------------------------------------------------------------------------
-- The snipe pop-up: a live deal the sniper found, with its Buy button, over the auction house
-- whichever page is open (db.noSnipePopup). Buying stays a click: the button only runs T.buy /
-- T.check from its own OnClick.
----------------------------------------------------------------------------

local popup, popupID
T.popupSkipped = {} -- id -> the listed price skipped (shown again only below it)
local popupPlace = {}

local function popupEst(b)
  return b and (b.est or b.estAll)
end
-- The live deals ready to buy, best estimate first.
function T.popupDeals()
  local out = {}
  for id in pairs(T.live) do
    local b = buying[id]
    if T.isLive(id) and b and (b.stage == "ready" or b.stage == "confirm" or b.stage == "pricing" or b.stage == "buying"
      or b.stage == "buyingItem") and not (T.popupSkipped[id] and (b.deal.low or 0) >= T.popupSkipped[id]) then
      out[#out + 1] = id
    end
  end
  table.sort(out, function(a, c)
    local ea, ec = popupEst(buying[a]) or 0, popupEst(buying[c]) or 0
    if ea ~= ec then return ea > ec end
    return a < c
  end)
  return out
end

local function makePopup()
  local A = ns.art
  local h = A.frame("Frame", "LevelingCodexSnipeAlert", UIParent)
  h:SetSize(270, 104)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:Hide()
  A.cardChrome(h)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", 12, -9)
  h.icon = h:CreateTexture(nil, "ARTWORK")
  h.icon:SetSize(28, 28)
  h.icon:SetPoint("TOPLEFT", 12, -24)
  h.name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  h.name:SetPoint("TOPLEFT", 46, -24)
  h.name:SetWidth(212)
  h.name:SetJustifyH("LEFT")
  h.name:SetWordWrap(false)
  h.line = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.line:SetPoint("TOPLEFT", 46, -40)
  h.line:SetWidth(212)
  h.line:SetJustifyH("LEFT")
  h.buy = A.button(h, 170, 24)
  h.buy:SetPoint("BOTTOMLEFT", 12, 10)
  h.buy:SetScript("OnClick", function()
    local id = popupID
    local b = id and buying[id]
    if not b then return end
    if b.stage == "ready" or b.stage == "confirm" then T.buy(id) elseif b.stage == "none" then T.check(b.deal) end
    T.refresh()
  end)
  h.buy.tipTitle = "Buy this deal"
  h.buy.tip = "Buys at the checked price (a commodity asks once more to confirm). The Codex checks the price again first when the quote is old."
  h.skip = A.button(h, 70, 24)
  h.skip:SetPoint("BOTTOMRIGHT", -12, 10)
  h.skip:SetLabel("Skip")
  h.skip.codexLabel = "Skip deal"
  h.skip.tipTitle = "Skip this deal"
  h.skip.tip = "Hides it here until it's listed cheaper. It stays on the Deals page."
  h.skip:SetScript("OnClick", function()
    local b = popupID and buying[popupID]
    if b then T.popupSkipped[popupID] = b.deal.low or 0 end
    T.refreshPopup()
  end)
  h.elapsed = 0
  h:SetScript("OnUpdate", function(self, el)
    self.elapsed = self.elapsed + (tonumber(el) or 0)
    if self.elapsed >= 0.5 then self.elapsed = 0; T.refreshPopup() end
  end)
  return h
end

function T.refreshPopup()
  local root = _G.AuctionHouseFrame
  local list = (not ns.db().noSnipePopup and root and root.IsShown and root:IsShown()) and T.popupDeals() or {}
  if #list == 0 then
    popupID = nil
    if popup then popup:Hide() end
    return
  end
  local keep = false
  for _, id in ipairs(list) do if id == popupID then keep = true end end
  if not keep then popupID = list[1] end
  local b = buying[popupID]
  if not popup then popup = makePopup() end
  ns.art.paintCard(popup)
  local d = b.deal
  local idx = 1
  for i, id in ipairs(list) do if id == popupID then idx = i end end
  popup.label:SetText("SNIPE DEAL" .. (#list > 1 and ("  (" .. idx .. " of " .. #list .. ")") or ""))
  ns.setIcon(popup.icon, ns.auction.iconOf and ns.auction.iconOf(popupID) or nil)
  popup.name:SetText(Q.plain(d.name or ("item " .. popupID)))
  local est = popupEst(b)
  popup.line:SetText("Listed " .. ns.money(d.low or 0) .. ", " .. (d.kind == "vendor" and "vendor pays " or "usual ")
    .. ns.money(d.worth or 0) .. (est and ("\nEst. " .. (est >= 0 and "+" or "-") .. ns.money(math.abs(est)) .. " for " .. (b.qty or 1)) or ""))
  local label = T.dealLabel(popupID)
  popup.buy:SetLabel(label)
  popup.buy.codexLabel = "Buy deal"
  popup.buy:SetEnabled(b.stage == "ready" or b.stage == "confirm")
  ns.placeByWindow(popup, root, popupPlace)
  popup:Show()
end

function T.refresh()
  if ns.auctionPanel then ns.auctionPanel.refresh() end
  if popup or next(T.live) then T.refreshPopup() end
end

----------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------

local events
function ns.startAuctionTrade()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "BAG_UPDATE_DELAYED", "COMMODITY_SEARCH_RESULTS_UPDATED",
    "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED", "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE",
    "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASE_FAILED", "AUCTION_HOUSE_PURCHASE_COMPLETED", "PLAYER_MONEY",
    "AUCTION_HOUSE_AUCTION_CREATED", "REPLICATE_ITEM_LIST_UPDATE", "OWNED_AUCTIONS_UPDATED", "AUCTION_CANCELED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, a, b)
    if event == "AUCTION_HOUSE_SHOW" then
      if readNoVendorItems() then dealCache.key = nil; T.refresh() end
      for k in pairs(buying) do buying[k] = nil end
      recheck.queue, recheck.active, recheck.done, recheck.total = {}, nil, 0, 0
      mine.list, mine.queue, mine.waiting, mine.checking = {}, {}, nil, nil
      T.resetSellChecks()
      visit.spent, visit.buys, visit.est = 0, 0, 0
      ns.after(0.5, T.queryOwned)
    elseif event == "AUCTION_HOUSE_CLOSED" then
      if popup then popup:Hide() end
      popupID = nil
      for _, x in pairs(buying) do
        if x.stage == "pricing" or x.stage == "confirm" then try(api().CancelCommoditiesPurchase) end
      end
      for k in pairs(buying) do buying[k] = nil end
      recheck.queue, recheck.active, recheck.done, recheck.total = {}, nil, 0, 0
      mine.queue, mine.waiting, mine.checking = {}, nil, nil
      T.resetSellChecks()
    elseif event == "BAG_UPDATE_DELAYED" then
      if readNoVendorItems() then dealCache.key = nil end
      if ns.auction.isOpen() then T.refresh() end
    elseif not ns.auction.isOpen() then return
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then readCommodity(tonumber(a))
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED" then readItems(a)
    elseif event == "COMMODITY_PRICE_UPDATED" then priced(a, b)
    elseif event == "COMMODITY_PRICE_UNAVAILABLE" then
      for _, x in pairs(buying) do
        if x.stage == "pricing" then
          try(api().CancelCommoditiesPurchase)
          x.stage, x.why = "none", "gone"
        end
      end
      T.refresh()
    elseif event == "COMMODITY_PURCHASE_SUCCEEDED" then bought(true)
    elseif event == "COMMODITY_PURCHASE_FAILED" then bought(false)
    elseif event == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
      local auctionID = tonumber(a)
      for id, x in pairs(buying) do
        if x.stage == "buyingItem" and x.pendingLot and (not auctionID or x.pendingLot.auction == auctionID) then
          finishItemBuy(id, true)
          return
        end
      end
      if auctionID and T.lateBuys[auctionID] then lateBought(auctionID) end
    elseif event == "PLAYER_MONEY" then
      for id, x in pairs(buying) do
        if x.stage == "buyingItem" and x.pendingLot and money() == x.pendingLot.purse - x.pendingLot.total then
          finishItemBuy(id, true)
          return
        end
      end
      for auction, l in pairs(T.lateBuys) do
        if money() == l.purse - l.total then lateBought(auction); break end
      end
      T.refresh()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then ns.after(2, T.refresh) -- the full scan has filed its prices by then
    elseif event == "OWNED_AUCTIONS_UPDATED" then readOwned()
    elseif event == "AUCTION_CANCELED" or event == "AUCTION_HOUSE_AUCTION_CREATED" then ns.after(0.5, T.queryOwned); T.refresh()
    else T.refresh() end
  end)
end

function ns.auctionTradeDebugLines()
  local out = { "auction trade: " .. (T.available() and "post and buy" or "no modern auction API") .. ", " .. last.posts
    .. " posts, " .. last.buys .. " buys this session; undercut " .. T.undercut()[1] .. ", warn " .. T.warnPct()
    .. "%, flips " .. T.flipPct() .. "%; " .. #mine.list .. " of yours listed, " .. T.undercutCount() .. " undercut, "
    .. last.cancels .. " cancelled, " .. T.hiddenCount() .. " hidden" }
  if last.post then
    out[#out + 1] = "auction last post: " .. last.post.qty .. " " .. Q.plain(last.post.name) .. " at " .. ns.money(last.post.price)
  end
  if last.buy then
    out[#out + 1] = "auction last buy: " .. last.buy.qty .. " " .. Q.plain(last.buy.name) .. " for " .. ns.money(last.buy.total)
  end
  return out
end

----------------------------------------------------------------------------
-- The Gold tab's settings
----------------------------------------------------------------------------

ns.gold.addSection(20, function(y)
  local U, C = ns.ui, ns.C
  local W = U.W
  local db = ns.db()
  local top = y
  y = y + 10
  U.T("SELLING AND DEALS", 14, y, W - 28, "label", C.gold)
  y = y + 20
  y = y + U.T("At the auction house the Codex tabs (Codex, Market, Deals, Quick Sell, Scan) chart the market, list what to sell from your bags and deals to buy, and keep your wins and losses. Every post and purchase is one click on its button. It never posts below what a vendor pays.",
    14, y, W - 28, "small", C.light) + 8
  local function row(label, list, current, key)
    U.T(label, 14, y + 5, 110, "small", C.light)
    local labels, lit = {}, nil
    for i, e in ipairs(list) do labels[i] = e[1]; if e[2] == current then lit = i end end
    y = y + U.segments(130, y, W - 144, labels, lit, function(i) db[key] = list[i][2]; U.refresh(); T.refresh() end) + 6
  end
  row("Undercut by", T.UNDERCUTS, T.undercut()[2], "auctionUndercut")
  row("Warn under usual", T.WARNS, T.warnPct(), "auctionWarnPct")
  row("Flip deals at", T.FLIPS, T.flipPct(), "auctionFlipPct")
  row("Post for", T.DURATIONS, T.duration(), "auctionDuration")
  row("Deals worth at least", T.MINPROFITS, T.minProfit(), "auctionMinProfit")
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end)
