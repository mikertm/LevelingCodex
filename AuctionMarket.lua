-- AuctionMarket.lua: the market view of the price store (ns.auctionMarket, M), for the Market tab
-- at the auction house: movers (biggest gainers and losers), hot items, a buy/sell signal per
-- item, the ticker, and the trade record (wins and losses) from AuctionTrade.lua's log.
-- Read-only: it never searches, posts or buys.
local _, ns = ...
local Q = ns.quests
local try = Q.try

local M = {}
ns.auctionMarket = M

local function now() return tonumber(time and time()) or 0 end
local function clock() return tonumber(GetTime and GetTime()) or 0 end
local function A() return ns.auction end
local function T() return ns.auctionTrade end

local GREEN, RED, ORANGE, GOLD = { 0.3, 0.9, 0.35 }, { 1, 0.38, 0.32 }, { 1, 0.6, 0.2 }, { 1, 0.82, 0 }
local TEAL, SOFT = { 0.35, 0.8, 0.85 }, { 0.62, 0.62, 0.62 }
M.GREEN, M.RED, M.ORANGE, M.GOLD, M.TEAL, M.SOFT = GREEN, RED, ORANGE, GOLD, TEAL, SOFT

-- Market > Price at least: items cheaper than this stay off the movers lists (a 1c item that goes to
-- 2c isn't a 100% opportunity).
M.MINPRICES = { { "Any", 0 }, { "1s", 100 }, { "10s", 1000 }, { "1g", 10000 } }
function M.minPrice()
  local v = ns.db().auctionMarketMin
  for _, e in ipairs(M.MINPRICES) do if e[2] == v then return v end end
  return 100
end

-- The signal for an item: key -> { tag, colour, why }.
M.SIGNALS = {
  buy = { "BUY", GREEN, "Listed well under its usual price" },
  sell = { "SELL", GOLD, "Listed well over its usual price: a good time to sell yours" },
  hot = { "HOT", ORANGE, "Rising while the supply dries up" },
  rising = { "RISING", GREEN, "The price is climbing" },
  falling = { "FALLING", RED, "The price is dropping: sell soon, or wait to buy" },
  wild = { "SWINGS", TEAL, "The price swings a lot: buy the dips, sell the peaks" },
  steady = { "STEADY", SOFT, "Near its usual price" },
  new = { "NEW", SOFT, "Too little history to say" },
}

local function pct(a, b)
  if not a or not b or b <= 0 then return nil end
  return math.floor((a - b) * 100 / b + 0.5)
end

local function isGreyItem(id, it)
  local q = type(it) == "table" and it.q
  if q ~= nil then return q == 0 end
  local base = ns.lootData and ns.lootData.items and ns.lootData.items[id]
  if base and base.quality ~= nil then
    if type(it) == "table" then it.q = base.quality end
    return base.quality == 0
  end
  return false
end

-- One item's market row, or nil without a price now:
-- { id, name, last, n, usual, days, trend (% vs the days before), move (% since the reading before),
--   moveAge (seconds), supply (% change in listed quantity), vol (spread of the daily prices, 0-1),
--   change (trend, else move), basis ("days"/"scan"), hot (score), signal (key) }
function M.row(id, bulk)
  local p = A().price(id)
  if not p or p.source or not p.low or p.low <= 0 or (p.n or 0) <= 0 then return end
  local it = A().store().items[id]
  if isGreyItem(id, it) then return end
  local name = p.name or (not bulk and A().nameOf(id))
    or (ns.lootData and ns.lootData.items and ns.lootData.items[id] and ns.lootData.items[id].name)
    or ("item " .. id)
  if not p.name and name and not name:find("^item %d+$") and type(it) == "table" then it.name = name end
  local r = { id = id, name = name, last = p.low, n = p.n, usual = p.usual, days = p.days or 0,
    trend = p.days and p.days >= 2 and p.trend or nil, vendor = p.vendor, at = p.at }
  -- Read the last two ticks directly from it.tk without allocating a full ticks array per item
  local tk = type(it) == "table" and type(it.tk) == "table" and it.tk or nil
  local tkLen = tk and #tk or 0
  if tkLen >= 6 then
    local aT, aLow, aN = tonumber(tk[tkLen - 5]), tonumber(tk[tkLen - 4]), tonumber(tk[tkLen - 3])
    local bT, bLow, bN = tonumber(tk[tkLen - 2]), tonumber(tk[tkLen - 1]), tonumber(tk[tkLen])
    if aT and bT and aLow and bLow and (bT - aT <= 2 * 86400) then
      r.move, r.moveAge = pct(bLow, aLow), bT - aT
      r.wasN = aN or 0
      if aN and aN > 0 then r.supply = pct(bN or 0, aN) end
    end
  end
  -- Compute daily volatility directly from it.days without sorting or allocating a history array
  if type(it) == "table" and type(it.days) == "table" and (r.days or 0) >= 2 then
    local dToday = math.floor(now() / 86400)
    local cur = (tonumber(it.n) or 0) > 0 and tonumber(it.low) or nil
    local sum, cnt = 0, 0
    for d, rec in pairs(it.days) do
      if type(d) == "number" and type(rec) == "table" then
        local v = (d == dToday and (cur or rec.last)) or rec.med or rec.low
        if v then sum, cnt = sum + v, cnt + 1 end
      end
    end
    if cnt >= 2 and sum > 0 then
      local mean, var = sum / cnt, 0
      for d, rec in pairs(it.days) do
        if type(d) == "number" and type(rec) == "table" then
          local v = (d == dToday and (cur or rec.last)) or rec.med or rec.low
          if v then var = var + (v - mean) ^ 2 end
        end
      end
      r.vol = math.sqrt(var / cnt) / mean
    end
  end
  if r.trend then r.change, r.basis = r.trend, "days"
  elseif r.move then r.change, r.basis = r.move, "scan" end
  r.live = T().isLive and T().isLive(id) or false
  r.fresh = r.at and (now() - r.at <= 120) or false
  local c, s = r.change or 0, r.supply or 0
  r.hot = math.abs(c) + math.max(0, -s) / 2 + math.abs(r.move or 0) / 2 + (r.vol or 0) * 20
  -- the signal
  local key = "new"
  if r.usual and r.days >= 2 then
    if r.last <= r.usual * 0.75 then key = "buy"
    elseif r.last >= r.usual * 1.2 then key = "sell"
    elseif c >= 10 and s <= -25 then key = "hot"
    elseif c >= 10 then key = "rising"
    elseif c <= -10 then key = "falling"
    elseif (r.vol or 0) >= 0.25 then key = "wild"
    else key = "steady" end
  elseif r.move then
    if r.move >= 15 and s <= -25 then key = "hot"
    elseif r.move >= 10 then key = "rising"
    elseif r.move <= -10 then key = "falling"
    else key = "steady" end
  end
  r.signal = key
  return r
end

-- Every row passing Price at least, not hidden, excluding grey vendor trash (quality 0).
-- Incrementally updates only the items in A().dirtyIDs during live sniper sweeps instead of
-- recomputing all 7,000+ realm items on every page!
local cache = { key = nil, rows = nil, byID = nil, storeRef = nil, at = 0, version = nil }
local askedQuality = {}
function M.rows()
  local store = A().store()
  local items = store.items
  local key = table.concat({ M.minPrice(), T().hiddenCount(), A().realmKey and A().realmKey() or "" }, ":")
  local version = A().version or 0
  if cache.rows and cache.storeRef == items and cache.key == key
    and (cache.version == version or clock() - cache.at < 1.2 or A().scanning()) then
    return cache.rows
  end
  local notes, min = T().notes(), math.max(1, M.minPrice())
  if cache.rows and cache.byID and cache.storeRef == items and cache.key == key
    and not A().dirtyFull and A().recordVersion == version then
    local dirty = A().dirtyIDs or {}
    local byID, rows = cache.byID, cache.rows
    for id in pairs(dirty) do
      local it = items[id]
      local r
      if type(it) == "table" and not notes.hidden[id] and (tonumber(it.n) or 0) > 0 and (tonumber(it.low) or 0) >= min then
        r = M.row(id, true)
      end
      local idx = byID[id]
      if r then
        if idx then rows[idx] = r
        else idx = #rows + 1; rows[idx] = r; byID[id] = idx end
      elseif idx then
        local lastIdx = #rows
        local moved = rows[lastIdx]
        rows[lastIdx] = nil
        byID[id] = nil
        if idx < lastIdx and moved then
          rows[idx] = moved
          byID[moved.id] = idx
        end
      end
      dirty[id] = nil
    end
    cache.at, cache.version = clock(), version
    return rows
  end
  local out, byID = {}, {}
  for id, it in pairs(items) do
    if type(it) == "table" and not notes.hidden[id] and (tonumber(it.n) or 0) > 0 and (tonumber(it.low) or 0) >= min then
      if it.q == nil and not askedQuality[id] then
        -- once a session per item: an uncached item asks the server, and 30,000 asks per rebuild
        -- flooded the client while the sniper ran
        askedQuality[id] = true
        local _, _, q = ns.itemInfo(id)
        if q ~= nil then it.q = q end
      end
      if not isGreyItem(id, it) then
        local r = M.row(id, true)
        if r then
          local idx = #out + 1
          out[idx] = r
          byID[id] = idx
        end
      end
    end
  end
  A().dirtyFull, A().dirtyIDs = false, {}
  cache.key, cache.rows, cache.byID, cache.storeRef, cache.at, cache.version = key, out, byID, items, clock(), version
  return out
end

local function isVanitySpike(r)
  return (r.change or 0) > 1500 and (r.n or 0) <= 2 and (r.usual or 0) < 2500
end

-- Keeps the best `cap` entries { r, s } of a bucket, best first (score high, then item ID low), by
-- insertion: picking the top few of 30,000 rows never builds and sorts a table per row (the sniper
-- redraws the ticker while it runs, and that churn crashed the client once).
local function better(a, b)
  if a.s ~= b.s then return a.s > b.s end
  return a.r.id < b.r.id
end
local function keep(bucket, r, s, cap)
  local n = #bucket
  if n >= cap then
    local worst = bucket[n]
    if not better({ r = r, s = s }, worst) then return end
    bucket[n] = nil
    n = n - 1
  end
  local e = { r = r, s = s }
  local i = n
  while i >= 1 and better(e, bucket[i]) do bucket[i + 1] = bucket[i]; i = i - 1 end
  bucket[i + 1] = e
end
M.keepTop = keep

local function top(filter, score, n)
  local cap = tonumber(n)
  if not cap then
    local list = {}
    for _, r in ipairs(M.rows()) do if filter(r) then list[#list + 1] = r end end
    table.sort(list, function(a, b)
      local sa, sb = score(a), score(b)
      if sa ~= sb then return sa > sb end
      return a.id < b.id
    end)
    return list
  end
  local best = {}
  if cap < 1 then return best end
  for _, r in ipairs(M.rows()) do
    if filter(r) then
      local s = score(r)
      if s == s then keep(best, r, s, cap) end
    end
  end
  local out = {}
  for i, e in ipairs(best) do out[i] = e.r end
  return out
end

function M.gainers(n)
  return top(function(r) return (r.change or 0) >= 3 and not isVanitySpike(r) end, function(r) return r.change end, n)
end
function M.losers(n) return top(function(r) return (r.change or 0) <= -3 end, function(r) return -r.change end, n) end
function M.hot(n)
  return top(function(r) return r.hot >= 5 and r.signal ~= "steady" and r.signal ~= "new" and not isVanitySpike(r) end, function(r) return r.hot end, n)
end
function M.signals(n)
  return top(function(r) return (r.signal == "buy" or r.signal == "sell") and not isVanitySpike(r) end,
    function(r) return math.abs(pct(r.last, r.usual) or 0) * math.max(1, math.log10(r.last)) end, n)
end

-- The live ticker: prioritizes verified live deals and freshly scanned items (sniper sweeps &
-- searches) ahead of older market movers, with outlier capping so +12,000% 1-item vanity posts
-- never freeze the ticker.
function M.ticker(n)
  local limit = n or 16
  local tnow = now()
  local sniperOn = A().sniper and A().sniper.on
  local tier1, tier2, tier3, tier4 = {}, {}, {}, {}
  for _, r in ipairs(M.rows()) do
    local age = r.at and math.max(0, tnow - r.at) or 999999
    local absC = r.change and math.abs(r.change) or 0
    local capped = math.min(absC, 400)
    local volWeight = math.max(1, math.log10((r.n or 1) + 1))
    if r.live then
      keep(tier1, r, 1e9 + capped * 10 - age, limit)
    elseif not isVanitySpike(r) then
      if age <= 180 and absC >= 1 then
        keep(tier2, r, (180 - age) * 1000 + capped * volWeight, limit)
      elseif sniperOn and age <= 75 and not (T().dealVendorBlocked and T().dealVendorBlocked(r.id)) then
        keep(tier3, r, (75 - age) * 1000 + (r.n or 0), limit)
      elseif absC >= 1 then
        keep(tier4, r, capped * volWeight - math.min(age, 7200) * 0.02, limit)
      end
    end
  end
  local out = {}
  local function takeFrom(b, maxTake)
    local taken = 0
    for _, e in ipairs(b) do
      if #out >= limit or (maxTake and taken >= maxTake) then break end
      out[#out + 1] = e.r
      taken = taken + 1
    end
  end
  takeFrom(tier1)
  takeFrom(tier2, sniperOn and #tier3 > 0 and math.max(8, limit - 4) or limit)
  if sniperOn then takeFrom(tier3, 6) end
  takeFrom(tier2)
  takeFrom(tier4)
  return out
end

-- A change as "+12%" / "-8%" / "0%".
function M.pctText(v)
  if not v then return "--" end
  if v > 0 then return "+" .. v .. "%" end
  return v .. "%"
end
function M.pctColor(v)
  if not v or math.abs(v) < 3 then return SOFT end
  return v > 0 and GREEN or RED
end

----------------------------------------------------------------------------
-- The trade record: wins and losses
----------------------------------------------------------------------------

-- Worked out from the log (oldest first): a sale of something the Codex bought (on the AH or to an
-- NPC vendor) closes its cost basis as a flip/snipe win or loss; a sale of your own loot is income;
-- an expired or cancelled post loses its deposit.
-- { flips = { { t, id, name, qty, cost, got, profit, via } } newest first, profit, vendorProfit,
--   income, earned, spent, winAmount, lossAmount, lost, wins, losses, best, worst,
--   holdings = { { id, name, qty, each, worth, pnl, via } }, openByID, bought, sales, vendorSales }
local recordCache = {}
local TOTALS = { "profit", "vendorProfit", "income", "earned", "spent", "winAmount", "lossAmount", "lost",
  "wins", "losses", "bought", "sales", "vendorSales", "pending", "otherVendor" }

-- One log entry into a running record { totals..., basis = { [id] = { qty, cost, name, kind, vendor } },
-- flips (optional), best, worst }. M.record() runs every entry through it; entries the log trims
-- go through it into notes.carry (M.fold), so trimming never changes the totals and a sale whose
-- purchase was trimmed still knows what it cost.
local function apply(st, e)
  local basis = st.basis
  local cut = T().CUT or 0.05
  local function add(k, v) st[k] = (st[k] or 0) + v end
  local function closeBasis(id, qty, got, via)
    local b = id and basis[id]
    if b and b.qty > 0 then
      local q = math.min(qty, b.qty)
      local cost = math.floor(b.cost * q / b.qty + 0.5)
      local share = math.floor(got * q / qty)
      b.cost, b.qty = math.max(0, b.cost - cost), b.qty - q
      if b.qty <= 0 then basis[id] = nil end
      local f = { t = e.t, id = id, name = e.name or b.name, qty = q, cost = cost, got = share, profit = share - cost, via = via }
      if st.flips then table.insert(st.flips, 1, f) end
      add("profit", f.profit)
      if via == "vendor" then add("vendorProfit", f.profit) end
      if f.profit >= 0 then
        add("wins", 1); add("winAmount", f.profit)
      else
        add("losses", 1); add("lossAmount", -f.profit)
      end
      if not st.best or f.profit > st.best.profit then st.best = { name = f.name, profit = f.profit, id = id } end
      if not st.worst or f.profit < st.worst.profit then st.worst = { name = f.name, profit = f.profit, id = id } end
      got = got - share
    end
    if got > 0 then
      -- the rest: an auction sale of your own items is income; a vendor sale of loot that shares
      -- an ID with a snipe isn't the auction house's money, so it stays out of the record
      if via == "vendor" then add("otherVendor", got) else add("income", got) end
    end
  end
  local id, qty, each = e.id, math.max(1, tonumber(e.qty) or 1), tonumber(e.each)
  if e.k == "buy" and id and (each or e.total) then
    local totalCost = tonumber(e.total) or ((each or 0) * qty)
    local b = basis[id] or { qty = 0, cost = 0, name = e.name }
    b.qty, b.cost, b.name = b.qty + qty, b.cost + totalCost, e.name or b.name
    if e.dealKind == "vendor" or not b.kind then b.kind = e.dealKind or b.kind end
    if e.vendor and e.vendor > 0 then b.vendor = e.vendor end
    basis[id] = b
    add("bought", qty); add("spent", totalCost)
  elseif e.k == "vendor" and (each or e.total) then
    local got = tonumber(e.total) or ((each or 0) * qty)
    add("sales", 1); add("vendorSales", 1); add("earned", got)
    closeBasis(id, qty, got, "vendor")
  elseif e.k == "sold" and not each then
    -- a sale the chat reported for something not posted through the Codex: its price comes
    -- with the mailbox's invoice (until then it counts as a sale but no money)
    add("sales", 1)
    if not st.folding then add("pending", 1) end
  elseif e.k == "sold" then
    add("sales", 1)
    local got = math.floor(each * qty * (1 - cut))
    add("earned", got)
    closeBasis(id, qty, got, "ah")
  elseif e.k == "clear" and id and basis[id] and basis[id].qty > 0 then
    local b = basis[id]
    local q = math.min(qty, b.qty)
    local cost = math.floor(b.cost * q / b.qty + 0.5)
    b.cost, b.qty = math.max(0, b.cost - cost), b.qty - q
    if b.qty <= 0 then basis[id] = nil end
  elseif (e.k == "expired" or e.k == "cancel") and e.dep then
    add("lost", e.dep); add("lossAmount", e.dep)
  end
end

-- The carried record: what the log has trimmed (notes.carry, kept with the trade notes).
function M.carry()
  local notes = T().notes()
  local c = notes.carry
  if type(c) ~= "table" then c = { basis = {} }; notes.carry = c end
  if type(c.basis) ~= "table" then c.basis = {} end
  return c
end
-- An entry leaving the log (AuctionTrade.lua's T.logTrade) goes into the carried record.
function M.fold(e)
  if type(e) ~= "table" then return end
  local c = M.carry()
  c.folding = true
  apply(c, e)
  c.folding = nil
  c.n = (c.n or 0) + 1
end

-- Starts the record over: the log and the carried totals go; what you still hold from Codex
-- purchases (notes.paid) stays as cost, so selling it later still counts against what it cost.
function M.resetRecord()
  local notes = T().notes()
  local basis = {}
  for id, pd in pairs(notes.paid or {}) do
    id = tonumber(id)
    local qty = type(pd) == "table" and tonumber(pd.qty) or 0
    if id and qty > 0 then
      basis[id] = { qty = qty, cost = tonumber(pd.cost) or qty * (tonumber(pd.each) or 0), name = pd.name, kind = pd.kind, vendor = pd.vendor }
    end
  end
  notes.log, notes.carry = {}, { basis = basis }
  T().logVersion = (T().logVersion or 0) + 1
  recordCache.value = nil
end

function M.record()
  local logVer, priceVer, tnow = T().logVersion or 0, A().version or 0, clock()
  if recordCache.value and recordCache.logVer == logVer
    and (recordCache.priceVer == priceVer or #recordCache.value.holdings == 0 or tnow - (recordCache.at or 0) < 3) then
    return recordCache.value
  end
  local carry = M.carry()
  local out = { flips = {}, holdings = {}, openByID = {}, basis = {}, carried = carry.n or 0 }
  for _, k in ipairs(TOTALS) do out[k] = tonumber(carry[k]) or 0 end
  out.best, out.worst = carry.best, carry.worst
  for id, b in pairs(carry.basis) do
    out.basis[id] = { qty = b.qty, cost = b.cost, name = b.name, kind = b.kind, vendor = b.vendor }
  end
  for _, e in ipairs(T().notes().log) do apply(out, e) end
  if out.pending == 0 then out.pending = nil end
  local basis = out.basis
  local cut = T().CUT or 0.05
  for id, b in pairs(basis) do
    if b.qty > 0 then
      local p = A().price(id)
      local vendor = (p and p.vendor and p.vendor > 0 and p.vendor) or b.vendor or (T().vendorPrice and T().vendorPrice(id, p))
      vendor = A().vendorValue(id, vendor)
      local each = math.floor(b.cost / b.qty + 0.5)
      local h = { id = id, name = b.name or A().nameOf(id) or ("item " .. id), qty = b.qty, cost = b.cost,
        each = each, kind = b.kind, vendor = vendor }
      if b.kind == "vendor" and vendor and vendor > 0 then
        h.worth, h.via = vendor, "vendor"
      else
        local ahEach
        if p then
          if p.days and p.days >= 2 and p.usual and p.usual > 0 then
            -- guard against a lone absurd listing after buying out the cheap ones
            ahEach = (p.n and p.n > 0 and p.low and p.low <= p.usual * 2) and p.low or p.usual
          else
            ahEach = (p.n and p.n > 0 and p.low) or p.usual
          end
        end
        local ahWorth = ahEach and math.floor(ahEach * (1 - cut)) or nil
        if vendor and vendor > 0 and (not ahWorth or vendor >= ahWorth) then
          h.worth, h.via = vendor, "vendor"
        elseif ahWorth then
          h.worth, h.via = ahWorth, "ah"
        end
      end
      if h.worth then h.pnl = h.worth * b.qty - b.cost end
      out.holdings[#out.holdings + 1] = h
      out.openByID[id] = h
    end
  end
  table.sort(out.holdings, function(a, b) return (a.pnl or 0) > (b.pnl or 0) end)
  out.unrealized = 0
  for _, h in ipairs(out.holdings) do out.unrealized = out.unrealized + (h.pnl or 0) end
  out.net = out.profit + out.income - out.lost
  local closed = out.wins + out.losses
  out.winRate = closed > 0 and math.floor(out.wins * 100 / closed + 0.5) or nil
  recordCache.logVer, recordCache.priceVer, recordCache.at, recordCache.value = logVer, priceVer, tnow, out
  return out
end

function M.openCost(id, qty)
  local h = id and M.record().openByID[id]
  if not h or h.qty <= 0 then return nil end
  local q = math.min(math.max(1, tonumber(qty) or 1), h.qty)
  return math.floor(h.cost * q / h.qty + 0.5)
end

-- The newest log entries (newest first), for the trade list: { e }.
function M.recent(n)
  local log, out = T().notes().log, {}
  for i = #log, math.max(1, #log - (n or 30) + 1), -1 do out[#out + 1] = log[i] end
  return out
end

----------------------------------------------------------------------------
-- Sales and expiries from the system chat
----------------------------------------------------------------------------

local patterns = {}
local function pattern(global, fallback)
  if patterns[global] == nil then
    local fmt = type(_G[global]) == "string" and _G[global] or fallback
    local p = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%%d%%%$s", "(.+)")
    patterns[global] = "^" .. p .. "$"
  end
  return patterns[global]
end
local function itemName(s)
  if type(s) ~= "string" then return end
  return s:match("|h%[(.-)%]|h") or s:match("^%[(.-)%]$") or s
end

function M.onSystem(text)
  if type(text) ~= "string" then return end
  local name = text:match(pattern("ERR_AUCTION_SOLD_S", "A buyer has been found for your auction of %s."))
  local kind = "sold"
  if not name then
    name = text:match(pattern("ERR_AUCTION_EXPIRED_S", "Your auction of %s has expired."))
    kind = "expired"
  end
  name = itemName(name)
  if not name then return end
  local e = T().closePost(name, kind)
  if e then e.chat = true end
  if ns.auctionPanel then ns.auctionPanel.refresh() end
end

----------------------------------------------------------------------------
-- Sales from the mailbox: every "Auction successful" mail carries an invoice (item, the price it
-- sold for, the deposit, the house's cut, how many), whoever posted it (Blizzard's Sell tab,
-- Auctionator, the Codex) and whether you were online when it sold.
----------------------------------------------------------------------------

-- A mail can't be told apart from an identical one, so the record keeps how many of each
-- (item, price, deposit, cut, count) it has seen in the inbox: more in the box = new sales; fewer
-- (taken out) lowers the count, so the next identical sale counts again.
local prevInbox -- the last inbox read this visit (nil = none yet)
function M.readInbox()
  local count = ns.mailbox and ns.mailbox.countFn() -- Forever: GetInboxNumItems
  if not count or type(GetInboxInvoiceInfo) ~= "function" then return 0 end
  local notes = T().notes()
  notes.mail = type(notes.mail) == "table" and notes.mail or {}
  local seen = notes.mail
  local inbox, sales = {}, {}
  local okN, n = pcall(count)
  n = okN and tonumber(n) or 0
  for i = 1, n do
    local ok, kind, item, _, bid, _, deposit, cut, _, _, _, count = pcall(GetInboxInvoiceInfo, i)
    if ok and kind == "seller" and type(item) == "string" and tonumber(bid) then
      count = math.max(1, tonumber(count) or 1)
      local key = table.concat({ item, bid, tonumber(deposit) or 0, tonumber(cut) or 0, count }, "|")
      inbox[key] = (inbox[key] or 0) + 1
      if inbox[key] > (seen[key] or 0) then
        sales[#sales + 1] = { item = item, bid = tonumber(bid), deposit = tonumber(deposit), cut = tonumber(cut), count = count }
      end
    end
  end
  -- a taken mail lowers the count, but only once two reads in a row agree: the first read after
  -- the mailbox opens can see a half-loaded inbox, and lowering on it counted every sale still in
  -- the box again on the next read
  if prevInbox then
    for key, had in pairs(seen) do
      local now = math.max(inbox[key] or 0, prevInbox[key] or 0)
      if now < had then seen[key] = now > 0 and now or nil end
    end
  end
  prevInbox = inbox
  for key, c in pairs(inbox) do if c > (seen[key] or 0) then seen[key] = c end end
  for _, v in ipairs(sales) do M.mailSale(v) end
  if #sales > 0 and ns.auctionPanel then ns.auctionPanel.refresh() end
  return #sales
end

-- One invoice into the record: it fills a sale the chat already logged without a price (the same
-- item, within two days), else it closes that item's oldest open post, else it's a sale of its own.
function M.mailSale(v)
  local log, lower = T().notes().log, v.item:lower()
  local each = math.floor(v.bid / v.count + 0.5)
  local t = tonumber(time and time()) or 0
  for _, e in ipairs(log) do
    -- a sale the chat logged (with or without the post's price) that no invoice has filled yet
    if e.k == "sold" and e.chat and not e.mail and type(e.name) == "string" and e.name:lower() == lower
      and t - (e.t or 0) < 2 * 86400 then
      e.each, e.qty, e.mail = each, v.count, true
      if v.deposit and not e.dep then e.dep = v.deposit end
      T().logVersion = (T().logVersion or 0) + 1
      return e
    end
  end
  local e = T().closePost(v.item, "sold", nil, v.count, each)
  if e then
    e.each, e.qty, e.mail = each, v.count, true
    T().logVersion = (T().logVersion or 0) + 1
  end
  return e
end

local events
function ns.startAuctionMarket()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "CHAT_MSG_SYSTEM", "MAIL_SHOW", "MAIL_INBOX_UPDATE", "MAIL_CLOSED" }) do pcall(events.RegisterEvent, events, ev) end
  events:SetScript("OnEvent", function(_, ev, text)
    if ev == "CHAT_MSG_SYSTEM" then M.onSystem(text)
    elseif ev == "MAIL_CLOSED" then prevInbox = nil
    else
      if ev == "MAIL_SHOW" then prevInbox = nil end
      ns.after(0.2, M.readInbox)
    end
  end)
end

function ns.auctionMarketDebugLines()
  local r = M.record()
  local rows = M.rows()
  return { "auction market: " .. #rows .. " items moving at " .. ns.money(M.minPrice()) .. " or more, "
    .. #M.gainers() .. " up, " .. #M.losers() .. " down, " .. #M.hot() .. " hot; trades logged " .. #T().notes().log
    .. ", flips " .. (r.wins + r.losses) .. " (" .. r.wins .. " won), net " .. ns.money(math.max(0, r.net))
    .. (r.net < 0 and (" lost " .. ns.money(-r.net)) or "") }
end
