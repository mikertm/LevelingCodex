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

-- One item's market row, or nil without a price now:
-- { id, name, last, n, usual, days, trend (% vs the days before), move (% since the reading before),
--   moveAge (seconds), supply (% change in listed quantity), vol (spread of the daily prices, 0-1),
--   change (trend, else move), basis ("days"/"scan"), hot (score), signal (key), hist, ticks }
function M.row(id)
  local p = A().price(id)
  if not p or p.source or not p.low or p.low <= 0 or (p.n or 0) <= 0 then return end
  local r = { id = id, name = p.name or A().nameOf(id) or ("item " .. id), last = p.low, n = p.n, usual = p.usual, days = p.days or 0,
    trend = p.days and p.days >= 2 and p.trend or nil, vendor = p.vendor, at = p.at }
  local ticks = A().ticks(id)
  local k = #ticks
  if k >= 2 then
    local a, b = ticks[k - 1], ticks[k]
    if b.t - a.t <= 2 * 86400 then
      r.move, r.moveAge = pct(b.low, a.low), b.t - a.t
      r.wasN = a.n
      if a.n and a.n > 0 then r.supply = pct(b.n, a.n) end
    end
  end
  local hist = A().history(id)
  if #hist >= 2 then
    local sum, n = 0, 0
    for _, d in ipairs(hist) do sum, n = sum + (d.med or d.low), n + 1 end
    local mean, var = sum / n, 0
    for _, d in ipairs(hist) do var = var + ((d.med or d.low) - mean) ^ 2 end
    r.vol = mean > 0 and math.sqrt(var / n) / mean or 0
  end
  if r.trend then r.change, r.basis = r.trend, "days"
  elseif r.move then r.change, r.basis = r.move, "scan" end
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

-- Every row passing Price at least, not hidden. Cached by the prices' version and the settings; while
-- the sniper files a price a second it is worked out again at most every 10 s.
local cache = { key = nil, rows = nil, at = 0, version = nil }
function M.rows()
  local key = table.concat({ M.minPrice(), T().hiddenCount(), A().realmKey and A().realmKey() or "" }, ":")
  local version = A().version or 0
  if cache.rows and cache.key == key and (cache.version == version or clock() - cache.at < 10) then return cache.rows end
  local out, notes, min = {}, T().notes(), M.minPrice()
  for id, it in pairs(A().store().items) do
    if type(it) == "table" and not notes.hidden[id] and (tonumber(it.n) or 0) > 0 and (tonumber(it.low) or 0) >= math.max(1, min) then
      local r = M.row(id)
      if r then out[#out + 1] = r end
    end
  end
  cache.key, cache.rows, cache.at, cache.version = key, out, clock(), version
  return out
end

local function top(filter, score, n)
  local list = {}
  for _, r in ipairs(M.rows()) do if filter(r) then list[#list + 1] = r end end
  table.sort(list, function(a, b)
    local sa, sb = score(a), score(b)
    if sa ~= sb then return sa > sb end
    return a.id < b.id
  end)
  local out = {}
  for i = 1, math.min(n or #list, #list) do out[i] = list[i] end
  return out
end

function M.gainers(n) return top(function(r) return (r.change or 0) >= 3 end, function(r) return r.change end, n) end
function M.losers(n) return top(function(r) return (r.change or 0) <= -3 end, function(r) return -r.change end, n) end
function M.hot(n)
  return top(function(r) return r.hot >= 5 and r.signal ~= "steady" and r.signal ~= "new" end, function(r) return r.hot end, n)
end
function M.signals(n)
  return top(function(r) return r.signal == "buy" or r.signal == "sell" end,
    function(r) return math.abs(pct(r.last, r.usual) or 0) * math.max(1, math.log10(r.last)) end, n)
end

-- The ticker: the biggest moves either way, as { r } rows (up to n).
function M.ticker(n)
  return top(function(r) return r.change and math.abs(r.change) >= 1 end, function(r) return math.abs(r.change) end, n or 16)
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

-- Worked out from the log (oldest first): a sale of something the Codex bought is a flip (its
-- profit = what the sale brings after the 5% cut minus what those pieces cost, average cost);
-- a sale of your own loot is income; an expired or cancelled post loses its deposit.
-- { flips = { { t, id, name, qty, cost, got, profit } } newest first, profit, income, lost, wins,
--   losses, best, worst, holdings = { { id, name, qty, each, worth, pnl } }, bought, sales }
local recordCache = {}
function M.record()
  local key = (T().logVersion or 0) .. ":" .. (A().version or 0)
  if recordCache.key == key and recordCache.value then return recordCache.value end
  local out = { flips = {}, profit = 0, income = 0, lost = 0, wins = 0, losses = 0, bought = 0, spent = 0, sales = 0, holdings = {} }
  local basis = {}
  local cut = T().CUT or 0.05
  for _, e in ipairs(T().notes().log) do
    local id, qty, each = e.id, tonumber(e.qty) or 1, tonumber(e.each)
    if e.k == "buy" and id and each then
      local b = basis[id] or { qty = 0, cost = 0, name = e.name }
      b.qty, b.cost, b.name = b.qty + qty, b.cost + each * qty, e.name or b.name
      basis[id] = b
      out.bought, out.spent = out.bought + qty, out.spent + each * qty
    elseif e.k == "sold" then
      out.sales = out.sales + 1
      local got = each and math.floor(each * qty * (1 - cut)) or 0
      local b = id and basis[id]
      if b and b.qty > 0 then
        local q = math.min(qty, b.qty)
        local cost = math.floor(b.cost * q / b.qty + 0.5)
        local share = math.floor(got * q / qty)
        b.cost, b.qty = b.cost - cost, b.qty - q
        local f = { t = e.t, id = id, name = e.name or b.name, qty = q, cost = cost, got = share, profit = share - cost }
        table.insert(out.flips, 1, f)
        out.profit = out.profit + f.profit
        if f.profit >= 0 then out.wins = out.wins + 1 else out.losses = out.losses + 1 end
        if not out.best or f.profit > out.best.profit then out.best = f end
        if not out.worst or f.profit < out.worst.profit then out.worst = f end
        out.income = out.income + (got - share)
      else
        out.income = out.income + got
      end
    elseif (e.k == "expired" or e.k == "cancel") and e.dep then
      out.lost = out.lost + e.dep
    end
  end
  for id, b in pairs(basis) do
    if b.qty > 0 then
      local p = A().price(id)
      local nowEach = p and ((p.n > 0 and p.low) or p.usual)
      local each = math.floor(b.cost / b.qty + 0.5)
      local h = { id = id, name = b.name or A().nameOf(id) or ("item " .. id), qty = b.qty, each = each }
      if nowEach then
        h.worth = math.floor(nowEach * (1 - cut))
        h.pnl = (h.worth - each) * b.qty
      end
      out.holdings[#out.holdings + 1] = h
    end
  end
  table.sort(out.holdings, function(a, b) return (a.pnl or 0) > (b.pnl or 0) end)
  out.unrealized = 0
  for _, h in ipairs(out.holdings) do out.unrealized = out.unrealized + (h.pnl or 0) end
  out.net = out.profit + out.income - out.lost
  local closed = out.wins + out.losses
  out.winRate = closed > 0 and math.floor(out.wins * 100 / closed + 0.5) or nil
  recordCache.key, recordCache.value = key, out
  return out
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
  T().closePost(name, kind)
  if ns.auctionPanel then ns.auctionPanel.refresh() end
end

local events
function ns.startAuctionMarket()
  if events then return end
  events = CreateFrame("Frame")
  pcall(events.RegisterEvent, events, "CHAT_MSG_SYSTEM")
  events:SetScript("OnEvent", function(_, _, text) M.onSystem(text) end)
end

function ns.auctionMarketDebugLines()
  local r = M.record()
  local rows = M.rows()
  return { "auction market: " .. #rows .. " items moving at " .. ns.money(M.minPrice()) .. " or more, "
    .. #M.gainers() .. " up, " .. #M.losers() .. " down, " .. #M.hot() .. " hot; trades logged " .. #T().notes().log
    .. ", flips " .. (r.wins + r.losses) .. " (" .. r.wins .. " won), net " .. ns.money(math.max(0, r.net))
    .. (r.net < 0 and (" lost " .. ns.money(-r.net)) or "") }
end
