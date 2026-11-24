-- Auction.lua: the auction tools. Prices from your own scans (a full scan, and quick searches for
-- what your guide needs and what's in your bags), a price history per realm with a trend, and the
-- price block on item tooltips. The Codex tab at the auction house is AuctionPanel.lua.
-- This file never buys, bids or posts: AuctionTrade.lua's buttons do that, one click each.
-- Built for the modern C_AuctionHouse API (what other Forever add-ons use), with the classic
-- QueryAuctionItems calls as a fallback. Saved prices may not load back on Forever: everything
-- works with an empty history, and the Gold tab says so.
local _, ns = ...
local Q = ns.quests
local try = Q.try

local A = {}
ns.auction = A

A.FULL_COOLDOWN = 15 * 60 -- seconds between full scans (the server throttles them too)
A.DAYS = 14               -- days of history kept per item
A.FRESH = 30 * 60         -- a price younger than this isn't searched again
local SEARCH_GAP, SEARCH_WAIT = 1.5, 5

local function now() return tonumber(time and time()) or 0 end
local function today(t) return math.floor((t or now()) / 86400) end
local function realm()
  local r = try(GetRealmName)
  return type(r) == "string" and r ~= "" and r or "Realm"
end
local function api() return type(C_AuctionHouse) == "table" and C_AuctionHouse or nil end
local function has(t, name) return type(t) == "table" and type(t[name]) == "function" end

----------------------------------------------------------------------------
-- Auctionator: when it is loaded, the Codex reads its prices through its public External API
-- (Auctionator.API.v1, the only calls it supports for other add-ons) and leaves the auction house's
-- searches to it, so the two never send queries over each other.
----------------------------------------------------------------------------

A.CALLER = "LevelingCodex"
local ator = { reads = 0, found = 0, searches = 0 }

-- Auctionator's API table while it is loaded, else nil.
function A.auctionator()
  local a = type(Auctionator) == "table" and Auctionator
  local v1 = a and type(a.API) == "table" and a.API.v1
  if has(v1, "GetAuctionPriceByItemID") then return v1 end
end

-- Auctionator's price for an item: copper, and its age in days when it says (nil = unknown).
function A.auctionatorPrice(id)
  local v1 = A.auctionator()
  id = tonumber(id)
  if not v1 or not id then return end
  ator.reads = ator.reads + 1
  local ok, v = pcall(v1.GetAuctionPriceByItemID, A.CALLER, id)
  v = ok and tonumber(v) or nil
  if not v or v <= 0 then return end
  ator.found = ator.found + 1
  local days
  if has(v1, "GetAuctionAgeByItemID") then
    local okAge, d = pcall(v1.GetAuctionAgeByItemID, A.CALLER, id)
    days = okAge and tonumber(d) or nil
  end
  return v, days
end

-- Shows the names in Auctionator's search results (the auction house must be open).
function A.searchAuctionator(names)
  local v1 = A.auctionator()
  if not has(v1, "MultiSearch") or type(names) ~= "table" or #names == 0 then return false end
  local ok, err = pcall(v1.MultiSearch, A.CALLER, names)
  ator.searches = ator.searches + 1
  ator.last = ok and (#names .. (#names == 1 and " item" or " items")) or ("failed: " .. tostring(err))
  return ok
end

----------------------------------------------------------------------------
-- The price store: LevelingCodexDB.auction.realms[realm] = { fullAt, items = { [itemID] =
-- { name, low, med, high, n, at, days = { [day] = { low, med } } } } }
----------------------------------------------------------------------------

local nameIndex, indexFor -- lower(name) -> itemID, for the store it was built from

function A.store()
  local db = ns.db()
  if type(db.auction) ~= "table" or db.auction.version ~= 1 or type(db.auction.realms) ~= "table" then
    db.auction = { version = 1, realms = {} }
  end
  local key = realm()
  local s = db.auction.realms[key]
  if type(s) ~= "table" or type(s.items) ~= "table" then
    s = { items = {} }
    db.auction.realms[key] = s
  end
  return s
end

local function index()
  local s = A.store()
  if indexFor ~= s then
    nameIndex, indexFor = {}, s
    for id, it in pairs(s.items) do
      if type(it) == "table" and type(it.name) == "string" then nameIndex[it.name:lower()] = id end
    end
  end
  return nameIndex
end

local function linkID(link) return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil end

-- The item ID for a name: the price store, else the client's item cache.
function A.idFor(name)
  if type(name) ~= "string" then return end
  local id = index()[name:lower()]
  if id then return id end
  local _, link = ns.itemInfo(name)
  return linkID(link)
end

function A.count()
  local n = 0
  for _ in pairs(A.store().items) do n = n + 1 end
  return n
end

-- Recent readings for the market view (AuctionMarket.lua): it.tk = { t, low, n, t, low, n, ... },
-- oldest first, at most A.TICKS readings; a reading within A.TICK_GAP of the newest one replaces
-- its price and quantity, so two readings are always that far apart (a move "since the last scan").
-- readings for the chart's intervals (1m ... 12h): a minute apart at least, the same price within
-- A.TICK_SAME adds none, up to A.TICKS kept for A.TICK_KEEP
A.TICK_GAP, A.TICKS, A.TICK_SAME, A.TICK_KEEP = 60, 40, 30 * 60, 7 * 86400
local function tick(it, low, n)
  local tk = type(it.tk) == "table" and it.tk or {}
  it.tk = tk
  local t, k = now(), #tk
  local lastT, lastLow = tonumber(tk[k - 2]), tonumber(tk[k - 1])
  if k >= 6 and lastLow == low and lastT and t - lastT < 2 * 3600 then
    -- already have an earlier reading to compare against: refresh time & supply without erasing the last price move
    tk[k - 2], tk[k] = t, n
  elseif k >= 3 and lastLow == low and lastT and t - lastT < A.TICK_SAME then
    tk[k] = n -- the same price again soon: the reading stands, its count follows
  elseif k >= 6 and lastT and t - lastT < A.TICK_GAP then
    -- a reading soon after the last replaces it (time too), as long as an earlier one stays to compare with
    tk[k - 2], tk[k - 1], tk[k] = t, low, n
  else
    tk[k + 1], tk[k + 2], tk[k + 3] = t, low, n
  end
  while #tk > A.TICKS * 3 or (#tk > 6 and t - (tonumber(tk[1]) or t) > A.TICK_KEEP) do
    table.remove(tk, 1); table.remove(tk, 1); table.remove(tk, 1)
  end
end

-- The recent readings, oldest first: { { t, low, n } }.
function A.ticks(id)
  local it = tonumber(id) and A.store().items[tonumber(id)]
  local out = {}
  local tk = type(it) == "table" and type(it.tk) == "table" and it.tk or {}
  for i = 1, #tk - 2, 3 do
    local t, low, n = tonumber(tk[i]), tonumber(tk[i + 1]), tonumber(tk[i + 2])
    if t and low then out[#out + 1] = { t = t, low = low, n = n or 0 } end
  end
  return out
end

-- Blizzard's November 2026 Forever hotfixes. Correct pre-hotfix readings from
-- saved scans and the client cache, while accepting other current client values.
local vendorHotfixes = {
  [4390] = { old = 500, current = 125 }, -- Iron Grenade
  [247754] = { old = 25, current = 5 }, -- Minor Arcane Elixir
}

function A.vendorValue(id, value)
  local copper = tonumber(value)
  local hotfix = vendorHotfixes[tonumber(id)]
  if hotfix and (copper == nil or copper == hotfix.old) then return hotfix.current end
  return copper
end

-- Files a reading. med/high only when the reading had every listing (a full scan or a search page).
A.version = 0 -- bumped by every change to the prices (for caches)
A.recordVersion = 0 -- bumped by A.record / A.absorb / A.fillVendors so direct store edits fall back to full rebuild
A.liveUpdates = 0
A.lastLiveAt = nil
A.dirtyIDs = {}
A.dealDirtyIDs = {}
A.dirtyFull = true
A.dealDirtyFull = true
function A.liveStats() return A.liveUpdates or 0, A.lastLiveAt end
function A.markAllDirty()
  A.dirtyFull, A.dealDirtyFull = true, true
  A.dirtyIDs, A.dealDirtyIDs = {}, {}
end

function A.record(id, name, low, n, med, high)
  id = tonumber(id)
  if not id then return end
  A.version = A.version + 1
  A.recordVersion = A.version
  if A.scanning() then
    A.dirtyFull, A.dealDirtyFull = true, true
  else
    if not A.dirtyFull then A.dirtyIDs[id] = true end
    if not A.dealDirtyFull then A.dealDirtyIDs[id] = true end
    A.liveUpdates = (A.liveUpdates or 0) + 1
    A.lastLiveAt = now()
  end
  local s = A.store()
  local it = s.items[id]
  if type(it) ~= "table" then it = {}; s.items[id] = it end
  if type(it.days) ~= "table" then it.days = {} end
  if type(name) == "string" and name ~= "" then
    it.name = name
    if indexFor == s then nameIndex[name:lower()] = id end
  end
  local oldLow, oldAt, oldN = tonumber(it.low), tonumber(it.at), tonumber(it.n)
  it.n, it.at, it.ator = tonumber(n) or 0, now(), nil
  -- the vendor price and quality, kept for the deal finder and market filters;
  -- a full scan or wide page sweep leaves uncached items for later (A.recordFast)
  if not A.recordFast then
    local _, _, q, _, _, _, _, _, _, _, v = ns.itemInfo(id)
    if q ~= nil then it.q = q end
    it.vendor = A.vendorValue(id, v or it.vendor)
  else
    it.vendor = A.vendorValue(id, it.vendor)
  end
  local d = today()
  if low then
    -- an item priced before the readings were kept: its last price is the first reading
    if type(it.tk) ~= "table" and oldLow and oldAt and oldAt < now() then
      it.tk = { oldAt, oldLow, oldN or 0 }
    end
    tick(it, low, tonumber(n) or 0)
    it.low, it.med, it.high = low, med or it.med, high or it.high
    local rec = it.days[d]
    if type(rec) ~= "table" then rec = {}; it.days[d] = rec end
    if rec.ator then rec.low, rec.med, rec.ator = nil, nil, nil end -- the Codex's own reading wins the day
    rec.low = rec.low and math.min(rec.low, low) or low
    rec.last = low
    if med then rec.med = med end
  end
  for k in pairs(it.days) do
    if type(k) ~= "number" or k <= d - A.DAYS then it.days[k] = nil end
  end
end

-- Auctionator's prices in the history: once a session per item, its last scanned price is filed
-- for the day Auctionator scanned it (its age when it says, else today), never over a day the
-- Codex read itself. An item the Codex never scanned takes that price (ator = true, source
-- "Auctionator") until a scan of its own. Only the public API: Auctionator hands over no history.
local absorbed = {}
function A.absorb(id)
  id = tonumber(id)
  if not id or absorbed[id] or not A.auctionator() then return end
  absorbed[id] = true
  local v, age = A.auctionatorPrice(id)
  if not v then return end
  age = math.max(0, math.floor(tonumber(age) or 0))
  local s = A.store()
  local it = s.items[id]
  if type(it) ~= "table" then
    local name = ns.itemInfo(id)
    it = { name = name, n = 1, ator = true, days = {} }
    s.items[id] = it
    if type(name) == "string" and indexFor == s then nameIndex[name:lower()] = id end
  end
  if type(it.days) ~= "table" then it.days = {} end
  local d = today() - age
  local rec = it.days[d]
  if type(rec) ~= "table" then it.days[d] = { low = v, med = v, ator = true }
  elseif rec.ator then rec.low, rec.med = v, v end
  if it.ator then it.low, it.at = v, now() - age * 86400 end
  local _, _, q, _, _, _, _, _, _, _, vendor = ns.itemInfo(id)
  if q ~= nil then it.q = q end
  it.vendor = A.vendorValue(id, tonumber(vendor) or it.vendor)
  for k in pairs(it.days) do
    if type(k) ~= "number" or k <= today() - A.DAYS then it.days[k] = nil end
  end
  ator.filed = (ator.filed or 0) + 1
  if not A.dirtyFull then A.dirtyIDs[id] = true end
  if not A.dealDirtyFull then A.dealDirtyIDs[id] = true end
  A.version = A.version + 1
  A.recordVersion = A.version
end

-- What the history says about an item: { name, low, med, high, n, at, usual, trend, days }.
-- usual = the median of the daily values (median, else lowest); trend = the last day against the
-- usual of the days before it, in percent (two days or more).
-- Without a record of your own, Auctionator's price stands in ({ source = "Auctionator" }).
function A.price(id)
  if tonumber(id) and A.auctionator() then A.absorb(id) end
  local it = tonumber(id) and A.store().items[tonumber(id)]
  if type(it) ~= "table" then
    local v, days = A.auctionatorPrice(id)
    if not v then return end
    return { name = (ns.itemInfo(tonumber(id))), low = v, usual = v, n = 1, days = 0, source = "Auctionator",
      at = days and (now() - days * 86400) or nil, vendor = A.vendorValue(id) }
  end
  local values, lastDay, last = {}, nil, nil
  for d, rec in pairs(type(it.days) == "table" and it.days or {}) do
    local v = type(rec) == "table" and (rec.med or rec.low)
    if v then
      values[#values + 1] = { d, v }
      if not lastDay or d > lastDay then lastDay, last = d, v end
    end
  end
  local function median(list)
    if #list == 0 then return end
    table.sort(list)
    return list[math.ceil(#list / 2)]
  end
  local all, before = {}, {}
  for _, e in ipairs(values) do
    all[#all + 1] = e[2]
    if e[1] ~= lastDay then before[#before + 1] = e[2] end
  end
  local usual, base = median(all), median(before)
  local current = ((tonumber(it.n) or 0) > 0 and tonumber(it.low)) or last
  local trend = base and base > 0 and current and math.floor((current - base) * 100 / base + 0.5) or nil
  return { name = it.name, low = it.low, med = it.med, high = it.high, n = tonumber(it.n) or 0, at = it.at,
    usual = usual, trend = trend, days = #all, vendor = A.vendorValue(id, it.vendor), source = it.ator and "Auctionator" or nil }
end

function A.age(t)
  t = tonumber(t)
  if not t then return "never" end
  local s = math.max(0, now() - t)
  if s < 90 then return "just now" end
  if s < 3600 then return math.floor(s / 60 + 0.5) .. " min ago" end
  if s < 86400 * 2 then return math.floor(s / 3600 + 0.5) .. " h ago" end
  return math.floor(s / 86400 + 0.5) .. " days ago"
end

function A.trendText(p)
  if not p or not p.trend then return end
  if math.abs(p.trend) <= 5 then return "steady" end
  return (p.trend > 0 and "up " or "down ") .. math.abs(p.trend) .. "%"
end

function A.forget()
  local db = ns.db()
  if type(db.auction) == "table" and type(db.auction.realms) == "table" then db.auction.realms[realm()] = nil end
  indexFor = nil
  absorbed = {}
  A.markAllDirty()
  A.version = A.version + 1
end

-- low, median (by quantity), high (90th percentile: one silly listing doesn't count) and quantity
-- from { { unitPrice, quantity }, ... }.
-- e = { q = { [price] = quantity }, prices = { distinct prices } }: one table per item, not one
-- per listing (a full scan has ~200,000 listings: a table each made the garbage collector stall)
local function summary(e)
  local prices, q = e.prices, e.q
  if not prices or #prices == 0 then return end
  table.sort(prices)
  local n = 0
  for _, pr in ipairs(prices) do n = n + q[pr] end
  if n == 0 then return end
  local med, high, run = nil, nil, 0
  for _, pr in ipairs(prices) do
    run = run + q[pr]
    if not med and run >= n / 2 then med = pr end
    if not high and run >= n * 0.9 then high = pr end
  end
  return prices[1], n, med, high or prices[#prices]
end

----------------------------------------------------------------------------
-- Scanning
----------------------------------------------------------------------------

local open, root = false, nil
local job               -- { kind = "full"/"search", ... } while the auction house is busy for us
local queue, searched = {}, {} -- names to search; names searched this visit
local last = {}         -- what the last scan and search did, for the Gold tab and /codex debug
local refreshCard

function A.isOpen() return open end
function A.busy() return job end
-- A full or paged scan is running: the market and deal lists keep their last answer until it ends.
function A.scanning() return job and (job.kind == "full" or job.kind == "paged") and true or false end

local function finished(kind)
  if kind == "full" and ns.refreshTab then ns.refreshTab("gold") end
  if refreshCard then refreshCard() end
end

-- Whether a full scan can start now: ok, reason.
function A.canFullScan()
  if not open then return false, "Open the auction house first." end
  if A.scanning() then return false, "Scanning..." end
  if job or (ns.auctionTrade and ns.auctionTrade.busyBuying()) then
    return false, "Waiting for the current auction action."
  end
  -- the cooldown runs from the last scan that was asked for, answered or not: the server counts
  -- the request (another addon's too), so asking again sooner only gets no answer
  local s = A.store()
  local fullAt = math.max(tonumber(s.fullAt) or 0, tonumber(s.fullTriedAt) or 0)
  if fullAt == 0 then fullAt = nil end
  local wait = fullAt and fullAt + A.FULL_COOLDOWN - now()
  if wait and wait > 0 then return false, "Next full scan in " .. math.max(1, math.ceil(wait / 60)) .. " min" end
  local C = api()
  if has(C, "ReplicateItems") then return true end
  if type(QueryAuctionItems) == "function" then
    local _, all = try(CanSendAuctionQuery)
    if all == false then return false, "The auction house allows one full scan every 15 min." end
    return true
  end
  return false, "This client has no full scan."
end

-- A replicate row: the client gives the name first and the item ID last; the link (slow: it
-- builds a hyperlink and can load the item) only when the ID is missing.
local function readModern(i)
  local C = api()
  local ok, name, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = pcall(C.GetReplicateItemInfo, i)
  if not ok then return end
  if not itemID and has(C, "GetReplicateItemLink") then
    local link = try(C.GetReplicateItemLink, i)
    itemID = linkID(link)
    if type(name) ~= "string" and type(link) == "string" then name = link:match("%[(.-)%]") end
  end
  return itemID, name, count, buyout
end
local function readClassic(i)
  local name, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = try(GetAuctionItemInfo, "list", i)
  return itemID or linkID(try(GetAuctionItemLink, "list", i)), name, count, buyout
end

-- How much of a frame a full scan may use, in milliseconds (Scan > Scan speed: Smooth, Balanced,
-- Fast). Without debugprofilestop it reads A.ROWS_NO_CLOCK rows a frame.
A.SPEEDS = { { "Smooth", 4 }, { "Balanced", 8 }, { "Fast", 16 } }
A.ROWS_NO_CLOCK = 250
A.SLOW_FRAME, A.MIN_BUDGET = 40, 1.5 -- ms: a client frame this long cuts the next slice to MIN_BUDGET
A.CAP_START, A.CAP_MIN, A.CAP_MAX = 300, 50, 20000
A.BREATHER = 0.1 -- s without reading after a slow client frame -- rows per slice, adapted to how the client keeps up
function A.budget()
  local want = ns.db().auctionScanSpeed
  for _, e in ipairs(A.SPEEDS) do if e[2] == want then return e[2] end end
  return 8
end
local function clock() return type(debugprofilestop) == "function" and debugprofilestop() or nil end

-- One row into acc[itemID] = { name, list }.
local function collectRow(acc, id, name, count, buyout)
  id, count, buyout = tonumber(id), math.max(1, tonumber(count) or 1), tonumber(buyout)
  if id and buyout and buyout > 0 then
    local e = acc[id]
    if not e then e = { q = {}, prices = {} }; acc[id] = e end
    if not e.name and type(name) == "string" and name ~= "" then e.name = name end
    local unit = math.floor(buyout / count + 0.5)
    local had = e.q[unit]
    if had then e.q[unit] = had + count else e.q[unit] = count; e.prices[#e.prices + 1] = unit end
  end
end
local function collect(acc, read, from, to)
  for i = from, to do collectRow(acc, read(i)) end
end

-- A list of rows filed as prices: every item gets its low/median/high; a full scan also marks
-- items it didn't see as none listed.
local function file(acc, full)
  local items = 0
  for id, e in pairs(acc) do
    local low, n, med, high = summary(e)
    if low then
      A.record(id, e.name or ns.itemInfo(id), low, n, med, high)
      items = items + 1
    end
  end
  if full then
    for id, it in pairs(A.store().items) do
      if not acc[id] and type(it) == "table" then it.n, it.at, it.ator = 0, now(), nil end
    end
  end
  return items
end

-- Runs step(i) for i = from..to a frame at a time inside the time budget, then done().
local function spread(j, from, to, step, done)
  local i = from
  local lastEnd
  local function frame()
    if job ~= j then return end
    j.beat, j.resume = GetTime and GetTime() or now(), frame
    local start, budget = clock(), A.budget()
    -- the time between our slices is the client's own frame; reading rows makes it load item data,
    -- and when that frame runs long (over A.SLOW_FRAME ms) the next slice is cut to A.MIN_BUDGET,
    -- so the game keeps drawing
    if start and lastEnd then
      local gap = start - lastEnd
      j.gap = gap
      j.gapSum, j.gapN = (j.gapSum or 0) + gap, (j.gapN or 0) + 1
      if gap > (j.worstGap or 0) then j.worstGap = gap end
      if gap > A.SLOW_FRAME then
        budget = A.MIN_BUDGET
        j.slow = (j.slow or 0) + 1
        j.cap = math.max(A.CAP_MIN, math.floor((j.cap or A.CAP_START) / 2))
        -- and a breather: the client still has the item data our rows asked for to load
        if not j.rested then
          j.rested = true
          lastEnd = nil
          ns.after(A.BREATHER, frame)
          return
        end
      elseif gap < A.SLOW_FRAME / 2 then
        j.cap = math.min(A.CAP_MAX, math.floor((j.cap or A.CAP_START) * 1.25))
      end
    end
    -- rows a slice may read: halved after every slow client frame, grown again while frames are quick
    local cap = start and (j.cap or A.CAP_START) or A.ROWS_NO_CLOCK
    local rows = 0
    while i <= to do
      -- one row or item that errors is skipped, never the end of the scan (an error here once left
      -- a scan stuck at "Saving prices 4,025 of 6,900")
      local ok, err = pcall(step, i)
      if not ok then
        j.errors = (j.errors or 0) + 1
        if not j.firstError then j.firstError = "row " .. i .. ": " .. tostring(err) end
        last.scanError = j.firstError
      end
      i, rows = i + 1, rows + 1
      if rows >= cap then break end
      if start then
        -- the clock every row: one row that loads an item can take a millisecond or more
        if clock() - start >= budget then break end
      elseif rows >= A.ROWS_NO_CLOCK then break end
    end
    j.rested = nil
    lastEnd = clock()
    if start then
      local took = lastEnd - start
      if took > (j.worstSlice or 0) then j.worstSlice = took end
    end
    if i <= to then
      j.frames = (j.frames or 0) + 1
      -- the scan's progress (pcall'd: an error in a redraw stopped the chain and left the scan
      -- "Reading" forever)
      if refreshCard and j.frames % 15 == 1 then pcall(refreshCard) end
      ns.after(0, frame)
    else
      local ok, err = pcall(done)
      if not ok then
        -- the end of a scan must still let go of the job, or every later scan waits on it
        last.scanError = "finishing: " .. tostring(err)
        if job == j then job = nil end
        A.recordFast = nil
        ns.say("The scan hit an error while finishing; the prices read so far are kept.")
        finished("full")
      end
    end
  end
  frame()
end

-- A full scan: wait until the row count stops growing (the rows arrive over several updates),
-- read the rows a slice of each frame, then file the items a slice of each frame (vendor prices
-- are left for later, so the item cache isn't asked thousands of times at once).
local function readFull()
  local j = job
  -- rows that arrive with no scan of ours running: another addon's full scan (Auctionator's),
  -- read and filed all the same
  if not j and open and has(api(), "GetNumReplicateItems") then
    local n = tonumber(try(api().GetNumReplicateItems)) or 0
    local lp = last.passive
    if n > 0 and not (lp and lp.n == n and now() - lp.at < 300) then
      last.passive = { n = n, at = now() }
      j = { kind = "full", started = now(), modern = true, passive = true, loads0 = ns.loot and ns.loot.itemEvents or 0 }
      job = j
    end
  end
  if not j or j.kind ~= "full" or j.reading then return end
  j.reading = true
  local function count()
    if j.modern then return tonumber(try(api().GetNumReplicateItems)) or 0 end
    return tonumber(try(GetNumAuctionItems, "list")) or 0
  end
  local seen, still, waited = count(), 0, 0
  local function settle()
    if job ~= j then return end
    local n = count()
    if n == seen then still = still + 1 else seen, still = n, 0 end
    waited = waited + 1
    j.total = n
    if still < 2 and waited < 40 then ns.after(0.25, settle); return end
    local total = n
    local first = j.modern and 0 or 1
    local acc, read = {}, j.modern and readModern or readClassic
    j.phase = "reading"
    spread(j, first, j.modern and total - 1 or total, function(i)
      collectRow(acc, read(i))
      j.done = i - first + 1
    end, function()
      local ids = {}
      for id in pairs(acc) do ids[#ids + 1] = id end
      j.phase, j.filing, j.filed = "filing", #ids, 0
      local items = 0
      A.recordFast = true
      spread(j, 1, #ids, function(k)
        local e = acc[ids[k]]
        local low, qty, med, high = summary(e)
        if low then A.record(ids[k], e.name, low, qty, med, high); items = items + 1 end
        j.filed = k
      end, function()
        A.recordFast = nil
        for id, it in pairs(A.store().items) do
          if not acc[id] and type(it) == "table" then it.n, it.at, it.ator = 0, now(), nil end
        end
        A.markAllDirty()
        A.store().fullAt = now()
        job = nil
        last.full = { at = now(), listings = total, items = items, seconds = now() - (j.started or now()), frames = j.frames or 0,
          slow = j.slow or 0, worstSlice = j.worstSlice, worstGap = j.worstGap,
          avgGap = j.gapN and j.gapN > 0 and j.gapSum / j.gapN or nil,
          passive = j.passive, how = j.how,
          loads = ns.loot and ns.loot.itemEvents and (ns.loot.itemEvents - (j.loads0 or 0)) or nil }
        ns.say((j.passive and "Read another addon's full scan: " or "Full scan: ") .. ns.thousands(total) .. " listings, "
          .. ns.thousands(items) .. " items priced.")
        finished("full")
        A.fillVendors()
        ns.after(SEARCH_GAP, A.pump)
      end)
    end)
  end
  settle()
end

A.FULL_WAIT = 60 -- seconds the instant scan waits for an answer before the paged scan takes over

-- A watchdog: a scan whose frame chain stopped (nothing read for A.STALL seconds) starts again
-- where it was, so a scan can't sit at "Reading" for good.
A.STALL = 8
function A.watchdog()
  local j = job
  if not (j and j.resume and j.beat) then return end
  local t = GetTime and GetTime() or now()
  if t - j.beat >= A.STALL then
    j.stalls = (j.stalls or 0) + 1
    last.stall = "a scan stopped for " .. math.floor(t - j.beat) .. " s and was restarted (" .. tostring(j.phase) .. ", row " .. (j.done or 0) .. ")"
    j.beat = t
    j.resume()
  end
end
if ns.every then ns.every(2, function() pcall(A.watchdog) end) end

function A.fullScan()
  local ok, why = A.canFullScan()
  if not ok then ns.say(why); return false end
  local C = api()
  local j = { kind = "full", started = now(), modern = has(C, "ReplicateItems"), polls = 0, loads0 = ns.loot and ns.loot.itemEvents or 0 }
  job = j
  local before = j.modern and tonumber(try(C.GetNumReplicateItems)) or 0
  local sent
  if j.modern then sent = pcall(C.ReplicateItems)
  else sent = pcall(QueryAuctionItems, "", nil, nil, 0, nil, nil, true, false) end
  if not sent then
    job = nil
    last.full = { at = now(), failed = "refused" }
    ns.say("The auction house refused the full scan.")
    finished("full")
    return false
  end
  A.store().fullTriedAt = now()
  ns.say("Full scan started: the auction house can take a minute to answer.")
  -- the answer is REPLICATE_ITEM_LIST_UPDATE, but the client doesn't always send it: the row count
  -- is checked every second too (a new count = the answer)
  local function poll()
    if job ~= j or j.reading then return end
    j.polls = j.polls + 1
    local n = j.modern and tonumber(try(C.GetNumReplicateItems)) or 0
    if n > 0 and n ~= before then j.how = "polled"; readFull(); return end
    if now() - j.started < A.FULL_WAIT then ns.after(1, poll); return end
    job = nil
    last.full = { at = now(), failed = "no answer in " .. A.FULL_WAIT .. " s (" .. j.polls .. " checks, " .. n .. " rows)" }
    last.instantFailed = last.full
    finished("full")
    if A.canPagedScan() then
      ns.say("The full scan got no answer (the server allows one every 15 min, and other addons' scans count). Reading page by page instead.")
      A.pagedScan()
    else
      ns.say("The full scan got no answer from the auction house. Try again in a few minutes.")
    end
  end
  ns.after(1, poll)
  finished("start")
  return true
end

-- The paged scan (what Scan all does while the instant scan cools down, like Auctioneer's
-- repeatable scan): a browse search for everything, page after page (RequestMoreBrowseResults until
-- HasFullBrowseResults), each page filed a slice of a frame. A browse row has the lowest price and
-- how many are listed for each item, so the median and high stay from the last instant scan. No
-- cooldown; it takes longer than the instant scan.
function A.canPagedScan()
  local C = api()
  if not open then return false, "Open the auction house first." end
  if A.scanning() then return false, "Scanning..." end
  if job or (ns.auctionTrade and ns.auctionTrade.busyBuying()) then
    return false, "Waiting for the current auction action."
  end
  if not (has(C, "SendBrowseQuery") and has(C, "RequestMoreBrowseResults")) then return false, "This client has no paged scan." end
  return true
end

-- No page for A.PAGE_RETRY seconds (a busy or throttled server drops a request without a word):
-- ask again, up to A.PAGE_TRIES times, before giving up.
A.PAGE_RETRY, A.PAGE_TRIES = 6, 3
local function browseQuery(text, order)
  return { searchString = text, sorts = { { sortOrder = order, reverseSort = false } }, filters = {}, itemClassFilters = {} }
end
local function pagedTimeout(j)
  local asked = j.asked or 0
  ns.after(A.PAGE_RETRY, function()
    if job ~= j or j.reading or (j.asked or 0) ~= asked then return end
    if now() - (j.lastPage or j.started) < A.PAGE_RETRY then return end
    if (j.retries or 0) >= A.PAGE_TRIES then
      job = nil
      last.full = { at = now(), failed = "the auction house stopped answering after " .. j.pages .. " pages", paged = true }
      ns.say("The paged scan stopped: the auction house didn't answer. Prices so far are kept.")
      finished("full")
      ns.after(SEARCH_GAP, A.pump)
      return
    end
    j.retries = (j.retries or 0) + 1
    j.asked = (j.asked or 0) + 1
    local C = api()
    if j.pages == 0 then
      pcall(C.SendBrowseQuery, browseQuery("", j.order))
    else
      j.waiting = true
      pcall(C.RequestMoreBrowseResults)
    end
    pagedTimeout(j)
  end)
end
function A.pagedScan()
  local ok, why = A.canPagedScan()
  if not ok then ns.say(why); return false end
  queue = {}
  local C = api()
  local order = type(Enum) == "table" and type(Enum.AuctionHouseSortOrder) == "table" and Enum.AuctionHouseSortOrder.Name or 1
  local j = { kind = "paged", started = now(), pages = 0, done = 0, seen = {}, items = 0, order = order }
  job = j
  if not pcall(C.SendBrowseQuery, browseQuery("", order)) then
    job = nil
    ns.say("The auction house refused the paged scan.")
    finished("full")
    return false
  end
  ns.say("Paged scan started: the Codex reads the auction house page by page.")
  pagedTimeout(j)
  finished("start")
  return true
end

-- Scan all: the instant scan when the server allows one, else the paged scan.
-- Scan all's kind (db.auctionScanAll, Settings on the Scan page): "paged" (the default: smooth,
-- no cooldown) or "instant" (the instant scan when the server allows one, else the paged one).
function A.scanAllKind() return ns.db().auctionScanAll == "instant" and "instant" or "paged" end
function A.scanAll()
  if A.scanAllKind() == "instant" and A.canFullScan() then return A.fullScan() end
  return A.pagedScan()
end
function A.canScanAll()
  local ok, why = A.canFullScan()
  if ok and A.scanAllKind() == "instant" then return true, "instant" end
  if A.scanAllKind() == "paged" then
    local okPaged, whyPaged = A.canPagedScan()
    if okPaged then return true, "paged" end
    return false, nil, whyPaged
  end
  local okPaged = A.canPagedScan()
  if okPaged then return true, "paged", why end
  return false, nil, why
end

-- The newest scan of either kind.
function A.lastScanAt()
  local s = A.store()
  local a, b = tonumber(s.fullAt), tonumber(s.pagedAt)
  if a and b then return math.max(a, b) end
  return a or b
end

local function readPage(rows)
  local j = job
  if not j or j.kind ~= "paged" or j.reading then return end
  -- one reading per page: the client may send both UPDATED and ADDED for it
  if j.pages > 0 and not j.waiting then return end
  local C = api()
  j.reading, j.waiting, j.lastPage = true, false, now()
  j.pages = j.pages + 1
  rows = type(rows) == "table" and rows or {}
  local n = #rows
  A.recordFast = true
  spread(j, 1, n, function(i)
    local r = rows[i]
    local key = type(r) == "table" and r.itemKey
    local id = type(key) == "table" and tonumber(key.itemID)
    local low = tonumber(r and r.minPrice)
    if id and low and low > 0 and not j.seen[id] then
      j.seen[id] = true
      local it = A.store().items[id]
      local name = type(it) == "table" and it.name or nil
      if not name and has(C, "GetItemKeyInfo") then
        local info = try(C.GetItemKeyInfo, key)
        name = type(info) == "table" and info.itemName or nil
      end
      A.record(id, name, low, tonumber(r.totalQuantity) or 1)
      j.items = j.items + 1
    end
    j.done = j.done + 1
  end, function()
    A.recordFast = nil
    j.reading = false
    if job ~= j then return end
    if has(C, "HasFullBrowseResults") and try(C.HasFullBrowseResults) == false then
      ns.after(0.3, function()
        if job ~= j then return end
        j.waiting, j.retries = true, 0
        j.asked = (j.asked or 0) + 1
        if not pcall(C.RequestMoreBrowseResults) then j.stuck = true end
        pagedTimeout(j)
      end)
      refreshCard()
      return
    end
    for id, it in pairs(A.store().items) do
      if not j.seen[id] and type(it) == "table" then it.n, it.at, it.ator = 0, now(), nil end
    end
    A.markAllDirty()
    A.store().pagedAt = now()
    job = nil
    last.full = { at = now(), listings = j.done, items = j.items, seconds = now() - j.started, frames = j.frames or 0, paged = true, pages = j.pages }
    ns.say("Paged scan: " .. ns.thousands(j.items) .. " items priced in " .. j.pages .. (j.pages == 1 and " page." or " pages."))
    finished("full")
    A.fillVendors()
    ns.after(SEARCH_GAP, A.pump)
  end)
end

-- Quick searches: one name at a time, respecting C_AuctionHouse.IsThrottledMessageSystemReady when
-- available, else a short gap between them.
A.FAST_GAP = 0.25
local function serverReady()
  local C = api()
  if not has(C, "IsThrottledMessageSystemReady") then return nil end
  local ok, r = pcall(C.IsThrottledMessageSystemReady)
  return ok and r and true or false
end
local function nextGap(fast)
  local r = serverReady()
  if r ~= nil then return fast and A.FAST_GAP or 0.35 end
  return fast and 0.6 or SEARCH_GAP
end

function A.search(name, front)
  if type(name) ~= "string" or searched[name:lower()] then return end
  for i, n in ipairs(queue) do
    if n == name then
      if front and i > 1 then table.remove(queue, i); table.insert(queue, 1, name) end
      return
    end
  end
  if front then table.insert(queue, 1, name) else queue[#queue + 1] = name end
end

local function sendSearch(name)
  local C = api()
  if has(C, "SendBrowseQuery") then
    local r = serverReady()
    if r == false then return nil end
    local order = type(Enum) == "table" and type(Enum.AuctionHouseSortOrder) == "table" and Enum.AuctionHouseSortOrder.Price or 0
    return pcall(C.SendBrowseQuery, browseQuery(name, order)), true
  end
  if type(QueryAuctionItems) == "function" then
    if try(CanSendAuctionQuery) == false then return nil end
    return pcall(QueryAuctionItems, name, nil, nil, 0, nil, nil, false, true), false
  end
  return false
end

-- The deal sniper (Deals > Snipe deals): three modes (snipe.mode):
--   "watch"  searches the items on its smart watch list (pinned targets first, then active deals,
--            proven past winners, realistic near-floor items, and high-turnover trade goods);
--   "newest" walks the first A.NEWEST_PAGES pages of newest and cheapest server listings, catching
--            brand-new 12h/24h/48h under-vendor and flip posts;
--   "sweep"  walks continuously page by page through the entire auction house (RequestMoreBrowseResults),
--            finding snipes on every page and updating market price histories as it goes.
-- Buying always stays a click; while you check or buy a deal, the sniper yields so its queries
-- never step on your search or purchase.
A.SNIPE_GAP, A.SNIPE_NEWEST_GAP, A.SNIPE_PAGE_GAP, A.SNIPE_SIZE, A.NEWEST_PAGES = 0.55, 1.8, 0.35, 250, 4
local snipe = {
  on = false, mode = "watch", list = {}, i = 0, checked = 0, laps = 0, kind = nil,
  page = 0, priced = 0, verify = {}, seen = {}, seenPage = {},
}
A.sniper = snipe
local function clk() return GetTime and GetTime() or now() end

-- Smart Watch List builder: prioritizes (1) user-starred items, (2) active deals on the board,
-- (3) proven past snipe/flip winners from your trade log, (4) items whose market price actually
-- trades near vendor/flip range, and (5) high-volume items, while demoting 100g epics that never
-- drop near vendor price.
function A.snipeList()
  local T = ns.auctionTrade
  local notes = T and T.notes and T.notes() or {}
  local hidden = notes.hidden or {}
  local watched = notes.watch or {}
  local kind, minProfit = snipe.kind, T and T.minProfit() or 0
  local active, pastWins = {}, {}
  for _, d in ipairs(T and T.deals and T.deals(kind) or {}) do active[d.id] = d.profit end
  for _, e in ipairs(notes.log or {}) do
    local id = tonumber(e.id)
    if id then
      if e.k == "buy" then pastWins[id] = (pastWins[id] or 0) + 1000
      elseif e.k == "vendor" or e.k == "sold" then pastWins[id] = (pastWins[id] or 0) + 5000 + (tonumber(e.each) or 0) end
    end
  end
  local rows = {}
  for id, it in pairs(A.store().items) do
    if type(it) == "table" and type(it.name) == "string" and not hidden[id]
      and (not T or not T.dealVendorBlocked(id)) then
      local days = 0
      for _ in pairs(type(it.days) == "table" and it.days or {}) do days = days + 1 end
      local vendor = A.vendorValue(id, it.vendor or (watched[id] and (select(11, ns.itemInfo(id))) or nil))
      vendor = vendor and vendor > 0 and vendor or nil
      local usual = days >= 2 and tonumber(it.med or it.low) or nil
      local worth
      if kind == "vendor" then worth = vendor
      elseif kind == "flip" then worth = usual and math.floor(usual * 0.95)
      else worth = math.max(vendor or 0, usual and math.floor(usual * 0.95) or 0) end
      if watched[id] and (vendor or (kind ~= "vendor" and usual)) then
        rows[#rows + 1] = { it.name, 2e12 + (active[id] or worth or usual or vendor or 1) }
      elseif vendor and worth and worth > minProfit then
        local low = tonumber(it.low)
        local vol = math.min(100, tonumber(it.n) or 0)
        local score
        if active[id] then
          score = 1e12 + active[id]
        elseif pastWins[id] then
          score = 5e9 + pastWins[id] + worth
        elseif low and low > 0 and low <= worth * 2.5 then
          score = 1e8 + math.floor(worth * 100 / math.max(1, low)) * 1000 + vol * 250
        elseif low and low > worth * 8 then
          score = math.max(1, math.floor(worth / 20)) + vol * 10
        else
          score = worth + vol * 120
        end
        rows[#rows + 1] = { it.name, score }
      end
    end
  end
  table.sort(rows, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
  local out, seen = {}, {}
  for _, r in ipairs(rows) do
    if #out >= A.SNIPE_SIZE then break end
    if not seen[r[1]] then seen[r[1]] = true; out[#out + 1] = r[1] end
  end
  return out
end

function A.snipeAvailable() return has(api(), "SendBrowseQuery") end

local function normalizeSnipeMode(m)
  if m == "newest" or m == "sweep" then return m end
  return "watch"
end

function A.setSnipeMode(mode)
  snipe.pending, snipe.moreMode, snipe.verify, snipe.page = nil, nil, {}, 0
  snipe.seen, snipe.verifiedAt = {}, {}
  snipe.mode = normalizeSnipeMode(mode)
  ns.db().auctionSnipeMode = snipe.mode ~= "watch" and snipe.mode or nil
  if snipe.on then
    snipe.list, snipe.i = A.snipeList(), 0
    A.pump()
  end
  refreshCard()
end

function A.snipeMode()
  snipe.mode = normalizeSnipeMode(ns.db().auctionSnipeMode or snipe.mode)
  return snipe.mode
end

function A.toggleSnipe(on)
  if on == nil then on = not snipe.on end
  if not on then
    snipe.on, snipe.pending, snipe.moreMode, snipe.verify = false, nil, nil, {}
    refreshCard()
    return false
  end
  if not open or not A.snipeAvailable() then ns.say("Open the auction house first."); return false end
  local mode = A.snipeMode()
  snipe.list, snipe.i, snipe.checked, snipe.laps, snipe.found = A.snipeList(), 0, 0, 0, 0
  snipe.page, snipe.priced, snipe.moreMode, snipe.verify, snipe.seen, snipe.verifiedAt, snipe.seenPage = 0, 0, nil, {}, {}, {}, {}
  if mode == "watch" and #snipe.list == 0 then
    ns.say("Nothing to watch yet: Scan all first, or switch the sniper to Newest or Pages.")
    return false
  end
  snipe.on = true
  if mode == "sweep" then
    ns.say("Sniping deals (page scanner): walking auction house pages for deals and updating live prices.")
  elseif mode == "newest" then
    ns.say("Sniping deals (newest listings): sweeping recent and low-priced pages on the auction house.")
  else
    ns.say("Sniping deals: watching " .. #snipe.list .. " items. Buying stays a click.")
  end
  A.pump()
  refreshCard()
  return true
end

-- A choice on the Deals page changed (kind, Worth at least, Flip at, hiding): a running sniper
-- watches the new list from its start.
function A.retarget(kind)
  snipe.kind, snipe.pending, snipe.seen, snipe.verifiedAt = kind, nil, {}, {}
  if not snipe.on then return end
  snipe.list, snipe.i = A.snipeList(), 0
  if snipe.mode == "watch" and #snipe.list == 0 then
    snipe.on = false
    ns.say("Sniper stopped: nothing matches those choices yet.")
  end
  refreshCard()
end

local function sendBrowseSweep(mode)
  local C = api()
  if not has(C, "SendBrowseQuery") then return false end
  local r = serverReady()
  if r == false then return nil end
  local enum = type(Enum) == "table" and type(Enum.AuctionHouseSortOrder) == "table" and Enum.AuctionHouseSortOrder
  local byPrice
  if mode == "sweep" then
    byPrice = ((snipe.laps or 0) % 2) == 0
  else
    byPrice = ((snipe.checked or 0) % 3) == 2
  end
  local order, reverse
  if byPrice then
    order, reverse = (enum and enum.Price) or 0, false
  else
    order, reverse = (enum and (enum.TimeRemaining or enum.Price)) or 4, true
  end
  local q = { searchString = "", sorts = { { sortOrder = order, reverseSort = reverse } }, filters = {}, itemClassFilters = {} }
  return pcall(C.SendBrowseQuery, q), byPrice and "cheapest" or "newest"
end

local function stepSniperVerify()
  if not open or not snipe.on then snipe.verify = {}; return end
  local T = ns.auctionTrade
  if job or (T and T.busyBuying and T.busyBuying()) then
    ns.after(0.25, stepSniperVerify)
    return
  end
  local c = table.remove(snipe.verify, 1)
  if not c then
    ns.after(0.15, A.pump)
    return
  end
  local ok = T and T.check(c.deal, false, c.key, function(id, bAfter)
    snipe.verifiedAt = snipe.verifiedAt or {}
    if bAfter and bAfter.stage ~= "ready" then
      snipe.seen[id] = { low = c.low, at = clk() }
      snipe.verifiedAt[id] = { low = c.low, at = clk() }
    elseif id then
      snipe.seen[id] = nil
      snipe.verifiedAt[id] = { low = c.low, at = clk() }
    end
    ns.after(0.2, stepSniperVerify)
  end)
  if not ok then ns.after(0.05, stepSniperVerify) end
end

function A.pump()
  if not open or job then return end
  local T = ns.auctionTrade
  if T and T.busyBuying and T.busyBuying() then
    ns.after(0.4, A.pump)
    return
  end
  if snipe.on and #queue == 0 and #snipe.verify > 0 then
    stepSniperVerify()
    return
  end
  local fromSniper = false
  if #queue == 0 then
    if not snipe.on then return end
    local mode = A.snipeMode()
    if mode == "newest" or mode == "sweep" then
      local C = api()
      -- Advance to the next page of the active multi-page sweep when more results remain
      if snipe.moreMode == mode and has(C, "RequestMoreBrowseResults")
        and has(C, "HasFullBrowseResults") and try(C.HasFullBrowseResults) == false then
        if serverReady() == false then ns.after(0.25, A.pump); return end
        snipe.moreMode = nil
        if pcall(C.RequestMoreBrowseResults) then
          local nextP = (snipe.page or 1) + 1
          snipe.current = (snipe.sortTag or "page") .. " p." .. nextP
          local j = { kind = "search", name = "", morePage = true, sweep = mode == "sweep", newest = mode == "newest", modern = true, at = now() }
          job = j
          ns.after(2.8, function()
            if job == j then
              job = nil
              snipe.page = 0
              finished("search")
              ns.after(0.3, A.pump)
            end
          end)
          refreshCard()
          return
        end
      end
      if mode == "sweep" and (snipe.page or 0) > 0 then
        snipe.laps = (snipe.laps or 0) + 1
      end
      local sent, sortTag = sendBrowseSweep(mode)
      if sent == nil then ns.after(0.3, A.pump); return end
      if not sent then ns.after(A.SNIPE_NEWEST_GAP, A.pump); return end
      snipe.page, snipe.seenPage, snipe.moreMode, snipe.sortTag = 0, {}, nil, sortTag
      snipe.checked = snipe.checked + 1
      snipe.current = sortTag .. " p.1"
      local j = { kind = "search", name = "", sweep = mode == "sweep", newest = mode == "newest", modern = true, at = now() }
      job = j
      ns.after(SEARCH_WAIT, function()
        if job == j then
          job = nil
          last.search = { name = mode == "sweep" and "page sweep" or "newest listings", at = now(), failed = "no answer" }
          finished("search")
          ns.after(A.SNIPE_NEWEST_GAP, A.pump)
        end
      end)
      return
    end
    if not snipe.pending then
      snipe.i = snipe.i % math.max(1, #snipe.list) + 1
      if snipe.i == 1 and snipe.checked > 0 then snipe.list, snipe.laps = A.snipeList(), snipe.laps + 1 end
      snipe.pending = snipe.list[snipe.i]
      if not snipe.pending then snipe.on = false; refreshCard(); return end
    end
    fromSniper = true
  end
  local name = fromSniper and snipe.pending or queue[1]
  local sent, modern = sendSearch(name)
  if sent == nil then -- retry without moving a watch query into the ordinary refresh queue
    ns.after(0.35, A.pump)
    return
  end
  if fromSniper then
    snipe.pending = nil
    snipe.checked, snipe.current = snipe.checked + 1, name
  else
    table.remove(queue, 1)
  end
  searched[name:lower()] = true
  if not sent then ns.after(nextGap(true), A.pump); return end
  local j = { kind = "search", name = name, modern = modern, snipe = fromSniper, at = now() }
  job = j
  ns.after(SEARCH_WAIT, function()
    if job == j then
      job = nil
      last.search = { name = name, at = now(), failed = "no answer" }
      if not j.snipe then A.searchCount = A.searchCount + 1 end
      finished("search")
      ns.after(nextGap(false), A.pump)
    end
  end)
end

local function searchDone(results, exactMatch)
  local j = job
  job = nil
  local isSniper = j.snipe or j.newest or j.sweep
  if not isSniper then A.searchCount = A.searchCount + 1 end
  last.search = { name = j.sweep and ("page " .. (snipe.page or 1)) or (j.newest and "newest listings" or j.name), at = now(), results = results }
  -- searched by name and no exact match came back: the item is known and there is none for sale
  if not (j.newest or j.sweep) then
    local id = A.idFor(j.name)
    if id and (results == 0 or exactMatch == false) then
      A.record(id, j.name, nil, 0)
      if j.snipe and ns.auctionTrade then ns.auctionTrade.clearLiveDeal(id) end
    end
  end
  finished("search")
  if snipe.on and #queue == 0 and #snipe.verify > 0 then
    ns.after(0.1, stepSniperVerify)
  elseif snipe.on and #queue == 0 and snipe.moreMode then
    ns.after(A.SNIPE_PAGE_GAP, A.pump)
  elseif j.newest then
    ns.after(snipe.on and #queue == 0 and A.SNIPE_NEWEST_GAP or nextGap(true), A.pump)
  elseif j.sweep then
    ns.after(snipe.on and #queue == 0 and 0.8 or nextGap(true), A.pump)
  elseif snipe.on and #queue == 0 then
    ns.after(serverReady() ~= nil and A.SNIPE_GAP or 1, A.pump)
  else
    ns.after(nextGap(#queue > 0), A.pump)
  end
end

local function variantRowKey(key, id)
  if type(key) ~= "table" then return tostring(id) end
  return table.concat({ id, key.itemLevel or 0, key.itemSuffix or 0, key.battlePetSpeciesID or 0 }, ":")
end

local function readBrowse(added)
  if job and job.kind == "paged" then
    -- the first page arrives as UPDATED (the whole list), later pages as ADDED (only the new rows)
    readPage(added or try(api().GetBrowseResults))
    return
  end
  local j = job
  if not j or j.kind ~= "search" or not j.modern then return end
  local C = api()
  local list = (j.morePage and type(added) == "table" and #added > 0) and added or try(C.GetBrowseResults)
  local n, exact = 0, false
  local T = ns.auctionTrade
  local wideSweep = j.newest or j.sweep
  local sniperSearch = j.snipe or wideSweep
  local candidates, byItem = {}, {}
  local needVendors = false
  local want = not wideSweep and type(j.name) == "string" and j.name:lower() or nil
  if wideSweep then
    snipe.page = (snipe.page or 0) + 1
    snipe.current = (snipe.sortTag or "page") .. " p." .. snipe.page
  end
  local seenPage = wideSweep and (snipe.seenPage or {}) or nil
  local nowClk = clk()
  local storeItems = A.store().items
  for _, r in ipairs(type(list) == "table" and list or {}) do
    local key = type(r) == "table" and r.itemKey
    local id = type(key) == "table" and tonumber(key.itemID)
    local low = tonumber(r and r.minPrice)
    local qty = tonumber(r and r.totalQuantity) or 0
    local vKey = id and variantRowKey(key, id)
    if id and not (seenPage and seenPage[vKey]) then
      if seenPage then seenPage[vKey] = true end
      local saved = storeItems[id]
      local name = type(saved) == "table" and saved.name or nil
      if not name and has(C, "GetItemKeyInfo") then
        local info = try(C.GetItemKeyInfo, key)
        name = type(info) == "table" and info.itemName
      end
      if not name then
        name = ns.itemInfo(id) or (not wideSweep and A.nameOf(id) or nil)
      end
      local matches = want and type(name) == "string" and name:lower() == want
      if matches then exact = true end
      if low and low > 0 and qty > 0 then
        local agg = byItem[id]
        if not agg then
          agg = { name = name, low = low, qty = qty }
          byItem[id] = agg
        else
          agg.low = math.min(agg.low, low)
          agg.qty = agg.qty + qty
          if not agg.name and name then agg.name = name end
        end
        if sniperSearch then
          local inspect = snipe.on and T and (wideSweep or matches)
          local deal = inspect and T.sniperCandidate(id, name, low, qty) or nil
          local seenFalse = snipe.seen and snipe.seen[id]
          if seenFalse and (nowClk - seenFalse.at) >= 45 then
            snipe.seen[id], seenFalse = nil, nil
          end
          local ver = wideSweep and snipe.verifiedAt and snipe.verifiedAt[id]
          if ver and (nowClk - ver.at) >= 25 then
            snipe.verifiedAt[id], ver = nil, nil
          end
          if deal then
            agg.candidate = true
            if not T.isLive(id) and seenFalse and low >= seenFalse.low then
              deal = nil -- skip re-checking known bid-bait on this sweep
            elseif wideSweep and ver and low >= ver.low then
              deal = nil -- already verified within the last 25s: keep advancing pages
            end
          end
          if deal then
            local previous = T.buying[id]
            local at = previous and previous.at or -1
            candidates[#candidates + 1] = { deal = deal, key = key, low = low, at = at }
          end
        end
        n = n + 1
      elseif qty == 0 and matches then
        A.record(id, name, nil, 0)
        if sniperSearch and T then T.clearLiveDeal(id) end
      end
    end
  end
  -- Record aggregated prices per itemID into the price history database so charts, movers,
  -- tooltips and the LIVE ticker update in real time without letting unverified bid-bait overwrite buyouts.
  local fast = type(list) == "table" and #list > 25 or nil
  local uncachedIDs
  for id, agg in pairs(byItem) do
    if sniperSearch then
      local seenFalse = snipe.seen and snipe.seen[id]
      if not agg.candidate and not (seenFalse and agg.low <= seenFalse.low)
        and not (T and (T.isLive(id) or T.buying[id])) then
        A.recordFast = fast
        A.record(id, agg.name, agg.low, agg.qty)
        A.recordFast = nil
        snipe.priced = (snipe.priced or 0) + 1
        local st = storeItems[id]
        if type(st) == "table" and st.vendor == nil then
          if not uncachedIDs then uncachedIDs = {} end
          uncachedIDs[#uncachedIDs + 1] = id
        end
      end
    else
      A.record(id, agg.name, agg.low, agg.qty)
    end
  end
  if uncachedIDs then ns.after(0.4, function() A.fillVendors(0, uncachedIDs) end) end
  if wideSweep and snipe.on then
    local hasMore = has(C, "HasFullBrowseResults") and try(C.HasFullBrowseResults) == false
    if j.sweep and hasMore then
      snipe.moreMode = "sweep"
    elseif j.newest and hasMore and (snipe.page or 1) < A.NEWEST_PAGES then
      snipe.moreMode = "newest"
    else
      snipe.moreMode = nil
    end
  end
  if #candidates > 0 and snipe.on then
    table.sort(candidates, function(a, b)
      if a.at ~= b.at then return a.at < b.at end
      return a.deal.profit > b.deal.profit
    end)
    local cap, usedID = math.min(#candidates, 6), {}
    for i = 1, #candidates do
      if #snipe.verify >= cap then break end
      local cid = candidates[i].deal.id
      if not usedID[cid] then
        usedID[cid] = true
        snipe.verify[#snipe.verify + 1] = candidates[i]
      end
    end
  end
  searchDone(n, want == nil or exact)
end

local function readClassicSearch()
  local j = job
  if not j or j.kind ~= "search" or j.modern then return end
  local acc = {}
  collect(acc, readClassic, 1, tonumber(try(GetNumAuctionItems, "list")) or 0)
  searchDone(file(acc, false))
end

----------------------------------------------------------------------------
-- What your guide needs, priced
----------------------------------------------------------------------------

-- { { id, name, need, forText, prof } }: your route's buy/collect items and quest items (Vendor.lua's
-- list) and your profession steps' materials (Settings > Vendor > Include profession supplies).
function A.needs()
  local names, extra = {}, {}
  if not ns.db().noProfShop and ns.profSupplies then
    for _, row in ipairs(ns.profSupplies()) do
      local id = A.idFor(row.name)
      if id then names[id] = row.name else extra[#extra + 1] = row end
    end
  end
  local out = {}
  local V = ns.vendor
  for _, w in ipairs(V and V.needs and V.needs(names) or {}) do
    local p = A.price(w.item)
    local name = names[w.item] or (p and p.name) or ns.itemInfo(w.item)
    if type(name) == "string" then
      out[#out + 1] = { id = w.item, name = name, need = w.need, forText = w.forText, prof = names[w.item] ~= nil }
    end
  end
  for _, row in ipairs(extra) do
    local need = row.n - Q.itemCount(row.name)
    if need > 0 then out[#out + 1] = { name = row.name, need = need, forText = Q.plain(row.label), prof = true } end
  end
  return out
end

-- The rows worth showing: profession materials, and route items the auction house has had.
local function pricedNeeds()
  local rows = {}
  for _, w in ipairs(A.needs()) do
    local id = w.id or A.idFor(w.name)
    local p = id and A.price(id)
    if w.prof or (p and (p.n > 0 or p.usual)) or (not p and open and (A.auctionator() or not searched[w.name:lower()])) then
      w.id, w.p = id, p
      rows[#rows + 1] = w
    end
  end
  return rows
end
A.pricedNeeds = pricedNeeds

-- The price line for a row: "12s each, usual 14s" / "none listed, usual 14s" / "searching" / "not seen yet".
local function rowPrice(w)
  local p = w.p
  if not p then
    if open and not ns.db().noAuctionSearch and not A.auctionator() and not searched[w.name:lower()] then return "searching" end
    return A.auctionator() and "not in Auctionator yet" or "not seen yet"
  end
  local s
  if p.source == "Auctionator" then
    return ns.money(p.low) .. " each (Auctionator" .. (p.at and (", " .. A.age(p.at)) or "") .. ")"
  end
  if p.n > 0 and p.low then s = ns.money(p.low) .. " each" else s = "none listed" end
  if p.usual and p.usual ~= p.low then s = s .. ", usual " .. ns.money(p.usual) end
  local t = A.trendText(p)
  if t then s = s .. ", " .. t end
  return s
end
A.rowPrice = rowPrice

local function queueNeeds()
  if ns.db().noAuctionSearch or A.auctionator() then return end
  for _, w in ipairs(A.needs()) do
    local id = w.id or A.idFor(w.name)
    local p = id and A.price(id)
    if not (p and p.at and now() - p.at < A.FRESH) then A.search(w.name) end
  end
  A.pump()
end

----------------------------------------------------------------------------
-- For the Codex tab
----------------------------------------------------------------------------

-- The price to ask each: one copper under the lowest listing, else the usual price.
function A.suggest(id)
  local p = A.price(id)
  if not p then return end
  local price = p.n > 0 and p.low and p.low - 1 or p.usual
  if price and price >= 1 then return price end
end

-- The searches still waiting, and the one running: n, name.
-- A quick refresh's progress (the header buttons: Update, Recheck deals, Reprice bags...):
-- A.startBatch(key) after the click queued its searches; A.batchProgress(key) -> done, total,
-- finished (true once nothing it queued is waiting or running, nor an undercut check).
A.searchCount = 0
local function stampNow() return GetTime and GetTime() or now() end
function A.startBatch(key, extra)
  local waiting = #queue + (job and job.kind == "search" and not (job.snipe or job.newest or job.sweep) and 1 or 0) + (tonumber(extra) or 0)
  A.batch = { key = key, base = A.searchCount, total = waiting, at = stampNow() }
  return A.batch
end
function A.batchProgress(key)
  local b = A.batch
  if not b or b.key ~= key then return end
  local T = ns.auctionTrade
  local checkLeft, checkDone = 0, 0
  if T and T.recheckState then checkDone, checkLeft = T.recheckState() end
  local running = job and job.kind == "search" and not (job.snipe or job.newest or job.sweep)
  local busy = #queue > 0 or running or checkLeft > 0 or (T and T.mine and T.mine.checking)
  local done = math.min(b.total, (A.searchCount - b.base) + checkDone)
  if not busy and not b.doneAt then b.doneAt = stampNow() end
  if b.doneAt and busy then b.doneAt = nil end
  return done, b.total, b.doneAt ~= nil, b.doneAt
end
function A.endBatch() A.batch = nil end

function A.queued()
  return #queue, job and job.kind == "search" and job.name or nil
end
-- Vendor prices for the items the store doesn't know one for, 40 every 0.1 s (a full scan files
-- thousands of items: asking the item cache for all of them at once stutters the game). 0 = the
-- item sells for nothing; an item the cache hasn't loaded is asked again next time.
local filling
-- An item's name: the store's, else the item cache's (kept once it loads), else nil. A page-by-page
-- scan or another addon's scan files items by ID only, so their names come from here.
function A.nameOf(id)
  id = tonumber(id)
  local it = id and A.store().items[id]
  if type(it) == "table" and type(it.name) == "string" and it.name ~= "" then return it.name end
  local name = id and ns.itemInfo(id)
  if type(name) == "string" and name ~= "" then
    if type(it) == "table" then it.name = name end
    if indexFor == A.store() then nameIndex[name:lower()] = id end
    return name
  end
  if id and type(C_Item) == "table" and type(C_Item.RequestLoadItemDataByID) == "function" then
    pcall(C_Item.RequestLoadItemDataByID, id)
  end
end

-- An item's icon without waiting for the item cache (GetItemIconByID knows every item).
function A.iconOf(id)
  id = tonumber(id)
  if not id then return end
  local f = type(C_Item) == "table" and C_Item.GetItemIconByID or GetItemIconByID
  local icon = type(f) == "function" and try(f, id) or nil
  if icon then return icon end
  local _, _, _, _, _, _, _, _, _, path = ns.itemInfo(id)
  return path
end

function A.fillVendors(again, idsList)
  if filling then return end
  local ids = idsList or {}
  if not idsList then
    for id, it in pairs(A.store().items) do
      if type(it) == "table" and (it.vendor == nil or not it.name) then ids[#ids + 1] = id end
    end
  end
  if #ids == 0 then return end
  filling = true
  local k, missing, changed = 0, 0, false
  local function step()
    for _ = 1, 25 do
      k = k + 1
      local id = ids[k]
      if not id then
        filling = nil
        if changed then
          A.version = A.version + 1
          A.recordVersion = A.version
          refreshCard()
        end
        -- items the cache was asked to load: their names come a moment later
        again = (again or 0) + 1
        if missing > 0 and again <= 2 and not snipe.on then ns.after(5, function() A.fillVendors(again) end) end
        return
      end
      local it = A.store().items[id]
      if type(it) == "table" then
        local name, _, q, _, _, _, _, _, _, _, v = ns.itemInfo(id)
        if q ~= nil then it.q = q end
        local nv = A.vendorValue(id, v or it.vendor)
        if nv ~= it.vendor then
          it.vendor, changed = nv, true
          if not A.dirtyFull then A.dirtyIDs[id] = true end
          if not A.dealDirtyFull then A.dealDirtyIDs[id] = true end
        end
        if not it.name then
          if type(name) == "string" and name ~= "" then
            it.name, changed = name, true
            if not A.dirtyFull then A.dirtyIDs[id] = true end
            if not A.dealDirtyFull then A.dealDirtyIDs[id] = true end
            if indexFor == A.store() then nameIndex[name:lower()] = id end
          elseif not snipe.on then
            missing = missing + 1
            A.nameOf(id)
          end
        end
      end
    end
    ns.after(0.12, step)
  end
  step()
end

-- done, total, phase ("reading" / "filing"; nil while the auction house hasn't answered).
function A.fullProgress()
  if job and job.kind == "full" then
    if job.phase == "filing" then return job.filed or 0, job.filing, "filing" end
    return job.done or 0, job.total, job.phase
  end
  if job and job.kind == "paged" then return job.items, nil, "paged", job.pages end
end

local function queueNames(names, front)
  local n = 0
  for i = front and #names or 1, front and 1 or #names, front and -1 or 1 do
    local name = names[i]
    searched[name:lower()] = nil
    local before = #queue
    A.search(name, front)
    if #queue > before then n = n + 1 end
  end
  A.pump()
  if refreshCard then refreshCard() end
  return n
end

-- Searches every item in your bags you could sell whose price is older than 30 minutes.
-- Returns how many it queued.
-- force = every one of them, however fresh (the page Refresh buttons).
function A.scanBags(force)
  if not open then return 0 end
  local names = {}
  local T = ns.auctionTrade
  for _, row in ipairs(T and T.sellable(true, true) or {}) do
    local p = A.price(row.id)
    if force or not (p and not p.source and p.at and now() - p.at < A.FRESH) then names[#names + 1] = row.name end
  end
  return queueNames(names)
end

-- Searches these names again now (the Market and Deals Refresh buttons). Returns how many it queued.
function A.searchNames(names, front)
  if not open then return 0 end
  return queueNames(names or {}, front)
end

-- Searches what your guide needs now, even with Auctionator loaded. Returns how many it queued.
function A.scanNeeds()
  if not open then return 0 end
  local names = {}
  for _, w in ipairs(A.needs()) do names[#names + 1] = w.name end
  return queueNames(names)
end

-- One item now (the Scan page's look-up, or refreshing a single row).
function A.searchNow(name)
  if not open or type(name) ~= "string" or name == "" then return false end
  return queueNames({ name }, true) > 0 or (job and job.kind == "search" and job.name == name) or false
end

-- Drops the searches still waiting (a running one finishes).
function A.stopSearches() queue = {}; if refreshCard then refreshCard() end end

-- The daily values, oldest first: { { day, low, med, last } } (up to A.DAYS).
function A.history(id)
  local it = tonumber(id) and A.store().items[tonumber(id)]
  local out = {}
  if type(it) ~= "table" or type(it.days) ~= "table" then return out end
  local dToday = today()
  local cur = (tonumber(it.n) or 0) > 0 and tonumber(it.low) or nil
  for d, rec in pairs(it.days) do
    if type(d) == "number" and type(rec) == "table" and (rec.low or rec.med) then
      local med = rec.med
      if d == dToday and (cur or rec.last) then
        -- Today's live point reflects the latest sniper/search reading rather than a frozen morning median
        med = cur or rec.last
      end
      out[#out + 1] = { day = d, low = rec.low, med = med, last = rec.last }
    end
  end
  table.sort(out, function(a, b) return a.day < b.day end)
  return out
end

-- An item by link, ID or (part of a) name: id, name.
function A.find(text)
  if type(text) ~= "string" then return end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then return end
  local fromLink = linkID(text)
  if fromLink then return fromLink, (text:match("%[(.-)%]")) or ns.itemInfo(fromLink) end
  local id = tonumber(text) or A.idFor(text)
  if id then
    local p = A.price(id)
    return id, (p and p.name) or ns.itemInfo(id) or text
  end
  local lower, best, bestName = text:lower(), nil, nil
  for iid, it in pairs(A.store().items) do
    if type(it) == "table" and type(it.name) == "string" and it.name:lower():find(lower, 1, true)
      and (not bestName or #it.name < #bestName) then
      best, bestName = iid, it.name
    end
  end
  return best, bestName
end

-- The Codex tab redraws when prices change.
-- Prices arrive a search at a time (the sniper: one a second), so the redraws they ask for are
-- folded into one 0.2 s later; a click still redraws at once (AuctionPanel.lua's buttons).
local redrawDue = false
refreshCard = function()
  if redrawDue or not ns.auctionPanel then return end
  redrawDue = true
  local delay = A.scanning() and 2 or ((snipe.on and #queue == 0) and 0.45 or 0.2)
  ns.after(delay, function() redrawDue = false; ns.auctionPanel.refresh() end)
end
A.refresh = function() refreshCard() end

----------------------------------------------------------------------------
-- Item tooltips
----------------------------------------------------------------------------

-- The tooltip's price block: { { left, right, lc, rc } } (right nil = one line across).
-- A gold heading with its age, the lowest price now, the usual one, the trend as a coloured
-- percentage with the last days as small bars, what a vendor pays, and a one-line verdict.
-- Shift adds low / median / high and how many were listed.
local GOLD, SOFT, INK = { 1, 0.82, 0 }, { 0.62, 0.62, 0.62 }, { 0.92, 0.88, 0.78 }
local GREEN, RED, ORANGE = { 0.3, 0.9, 0.35 }, { 1, 0.38, 0.32 }, { 1, 0.6, 0.2 }
local BAR = "Interface\\Buttons\\WHITE8X8"

-- Coin icons where the client draws them (the game's own sell price line), else coloured text.
function A.coins(copper)
  if type(GetCoinTextureString) == "function" then
    local ok, text = pcall(GetCoinTextureString, math.max(0, math.floor(tonumber(copper) or 0)))
    if ok and type(text) == "string" and text ~= "" then return text end
  end
  return ns.coins(copper)
end

-- The last days as little bars (inline textures, the newest gold): nil with fewer than two days.
function A.sparkline(id, days)
  local hist = A.history(id)
  local from = math.max(1, #hist - (days or 7) + 1)
  local vals = {}
  for i = from, #hist do vals[#vals + 1] = hist[i].med or hist[i].low end
  if #vals < 2 then return end
  local lo, hi = math.huge, 0
  for _, v in ipairs(vals) do lo, hi = math.min(lo, v), math.max(hi, v) end
  local parts, top = {}, 12
  for i, v in ipairs(vals) do
    local h = hi > lo and math.floor(3 + (top - 3) * (v - lo) / (hi - lo) + 0.5) or 7
    local c = i == #vals and { 255, 209, 0 } or { 110, 190, 180 }
    parts[#parts + 1] = string.format("|T%s:%d:4:0:%d:8:8:0:8:0:8:%d:%d:%d|t", BAR, h, math.floor((h - top) / 2), c[1], c[2], c[3])
  end
  return table.concat(parts, " ")
end

-- The verdict line for an item with a price: text, colour.
function A.verdict(p, vendor)
  local low = p.n > 0 and p.low or nil
  if vendor and vendor > 0 and low and vendor >= math.floor(low * 0.95) then
    return "Vendor it: a vendor pays more than a sale here", RED
  end
  if p.n == 0 then return "None listed: you set the price", GOLD end
  if p.usual and p.days and p.days >= 2 and low then
    if low >= p.usual * 1.1 then return "Above usual: a good time to sell", GREEN end
    if low <= p.usual * 0.7 then return "Cheap now: buy, or hold yours", ORANGE end
    if p.trend and p.trend <= -10 then return "Falling: sell soon", ORANGE end
    return "Near its usual price", SOFT
  end
end

function A.tooltipLines(id, shift)
  local out = {}
  local p = A.price(id)
  local vendor = A.vendorValue(id, (select(11, ns.itemInfo(id))))
  -- Auctionator draws its own auction and vendor lines: the Codex leaves out the vendor line and,
  -- when the price is Auctionator's, the lowest price; it adds the usual price, the trend and the
  -- verdict from the history (which Auctionator's scans feed too)
  local fromAtor = p and p.source == "Auctionator"
  if A.auctionator() then vendor = nil end
  local function add(l, r, lc, rc) out[#out + 1] = { l, r, lc or INK, rc or INK } end
  if p then
    add("|T" .. "Interface\\Icons\\" .. ns.ADDON_ICON .. ":14:14:0:0:64:64:5:59:5:59|t Codex prices", A.age(p.at)
      .. (fromAtor and " (Auctionator)" or ""), GOLD, SOFT)
    if fromAtor then -- Auctionator shows it
    elseif p.n > 0 and p.low then add("  Lowest now", A.coins(p.low)) else add("  Lowest now", "none listed", nil, SOFT) end
    if p.usual and p.usual ~= p.low then add("  Usual" .. (p.days and p.days > 1 and (" (" .. p.days .. " days)") or ""), A.coins(p.usual)) end
    if p.trend then
      local spark = A.sparkline(id) or ""
      local t = math.abs(p.trend) <= 5 and "steady" or ((p.trend > 0 and "+" or "-") .. math.abs(p.trend) .. "%")
      add("  Trend", (spark ~= "" and (spark .. "  ") or "") .. t, nil, math.abs(p.trend) <= 5 and SOFT or (p.trend > 0 and GREEN or RED))
    end
    if vendor and vendor > 0 then add("  Vendor pays", A.coins(vendor)) end
    local v, vc = A.verdict(p, vendor)
    if v then add("  " .. v, nil, vc) end
    if shift then
      if p.low then
        add("  Low / median / high", ns.coins(p.low) .. " / " .. ns.coins(p.med or p.low) .. " / " .. ns.coins(p.high or p.low), SOFT)
      end
      add("  Listed at the last look", ns.thousands(p.n), SOFT)
    end
  elseif shift and not A.auctionator() then
    add("|T" .. "Interface\\Icons\\" .. ns.ADDON_ICON .. ":14:14:0:0:64:64:5:59:5:59|t Codex prices", "not seen yet", GOLD, SOFT)
    if vendor and vendor > 0 then add("  Vendor pays", A.coins(vendor)) end
    add("  Scan at the auction house to start.", nil, SOFT)
  elseif vendor and vendor > 0 and shift then
    add("  Vendor pays", A.coins(vendor))
  end
  if #out == 1 then return {} end -- a heading alone says nothing
  return out
end

local hooked = {}
local function annotate(tip, ref)
  if ns.db().noPriceTooltip or not tip then return end
  local _, link = try(tip.GetItem, tip)
  link = link or ref
  local id = linkID(link) or tonumber(link)
  if not id then return end
  local key = tostring(link)
  if tip.codexPriceKey == key then return end
  tip.codexPriceKey = key
  local lines = A.tooltipLines(id, IsShiftKeyDown and IsShiftKeyDown() and true or false)
  if #lines == 0 then return end
  tip:AddLine(" ")
  for _, e in ipairs(lines) do
    local l, r, lc, rc = e[1], e[2], e[3], e[4]
    if r and has(tip, "AddDoubleLine") then
      tip:AddDoubleLine(l, r, lc[1], lc[2], lc[3], rc[1], rc[2], rc[3])
    else
      tip:AddLine(r and (l .. "  " .. r) or l, lc[1], lc[2], lc[3])
    end
  end
  if has(tip, "Show") then pcall(tip.Show, tip) end -- resizes it to the new lines
end

local function hookTip(tip)
  if type(tip) ~= "table" or hooked[tip] then return end
  hooked[tip] = true
  local function clear(self) self.codexPriceKey = nil end
  if has(tip, "HookScript") then
    pcall(tip.HookScript, tip, "OnTooltipSetItem", function(self) pcall(annotate, self) end)
    pcall(tip.HookScript, tip, "OnTooltipCleared", clear)
    pcall(tip.HookScript, tip, "OnHide", clear)
  end
  if type(hooksecurefunc) == "function" then
    for _, method in ipairs({ "SetBagItem", "SetInventoryItem", "SetHyperlink", "SetLootItem", "SetLootRollItem",
      "SetQuestItem", "SetQuestLogItem", "SetMerchantItem", "SetTradeSkillItem", "SetCraftItem",
      "SetAuctionItem", "SetAuctionSellItem" }) do
      if has(tip, method) then pcall(hooksecurefunc, tip, method, function(self) pcall(annotate, self) end) end
    end
  end
end

----------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------

local function onShow()
  open = true
  queue, searched = {}, {}
  root = (type(AuctionHouseFrame) == "table" and AuctionHouseFrame) or (type(AuctionFrame) == "table" and AuctionFrame) or nil
  if ns.auctionPanel then ns.auctionPanel.onShow(root) end
  ns.after(1, function() if open then queueNeeds(); refreshCard() end end)
  ns.after(3, function() if open then A.fillVendors() end end)
end

local function onClose()
  open = false
  job, queue = nil, {}
  snipe.on, snipe.pending, snipe.moreMode, snipe.verify = false, nil, nil, {}
  if ns.auctionPanel then ns.auctionPanel.onClose() end
end

local events
function ns.startAuction()
  if events then return end
  hookTip(GameTooltip)
  hookTip(ItemRefTooltip)
  if type(TooltipDataProcessor) == "table" and has(TooltipDataProcessor, "AddTooltipPostCall")
    and type(Enum) == "table" and type(Enum.TooltipDataType) == "table" then
    pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, function(tip, data)
      pcall(annotate, tip, data and data.id)
    end)
  end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "REPLICATE_ITEM_LIST_UPDATE",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", "AUCTION_ITEM_LIST_UPDATE",
    "AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "AUCTION_HOUSE_BROWSE_FAILURE", "BAG_UPDATE_DELAYED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, arg)
    if event == "AUCTION_HOUSE_SHOW" then onShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then onClose()
    elseif not open then return
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then if job then job.how = job.how or "event" end; readFull()
    elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then readBrowse()
    elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
      if job and (job.kind == "paged" or job.morePage) then readBrowse(arg) end
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
      if not job and (#queue > 0 or snipe.on) then ns.after(0.05, A.pump) end
    elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" then
      if job and job.kind == "search" then
        local j = job
        job = nil
        last.search = { name = j.sweep and "page sweep" or (j.newest and "newest listings" or j.name), at = now(), failed = "browse failure" }
        if not (j.snipe or j.newest or j.sweep) then A.searchCount = A.searchCount + 1 end
        finished("search")
        ns.after(SEARCH_GAP, A.pump)
      end
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
      if job and job.kind == "full" and not job.modern then readFull() else readClassicSearch() end
    elseif event == "BAG_UPDATE_DELAYED" then refreshCard()
    end
  end)
end

function ns.auctionDebugLines()
  local out = {}
  local C = api()
  out[#out + 1] = "auction: " .. (has(C, "ReplicateItems") and "C_AuctionHouse" or type(QueryAuctionItems) == "function"
    and "classic QueryAuctionItems" or "no auction API") .. ", " .. A.count() .. " prices on " .. realm()
    .. ", full scan " .. A.age(A.store().fullAt) .. ", paged scan " .. A.age(A.store().pagedAt) .. (open and ", open" or "")
  if A.auctionator() then
    out[#out + 1] = "auction: Auctionator loaded, " .. ator.found .. " of " .. ator.reads .. " price reads answered, "
      .. ator.searches .. " searches sent" .. (ator.last and (" (last " .. ator.last .. ")") or "")
      .. ", " .. (ator.filed or 0) .. " prices filed into the history"
  end
  if snipe.on or snipe.checked > 0 then
    out[#out + 1] = "auction sniper: " .. (snipe.on and ("on (" .. A.snipeMode() .. ")") or "off") .. ", " .. #snipe.list .. " watched, " .. snipe.checked
      .. " searches, " .. (snipe.found or 0) .. " deals"
      .. (A.auctionator() and "; the Codex's automatic startup searches are off" or "")
  end
  if last.scanError then out[#out + 1] = "auction scan error: " .. ns.plain(tostring(last.scanError)) end
  if last.stall then out[#out + 1] = "auction scan watchdog: " .. last.stall end
  if last.full then
    out[#out + 1] = "auction " .. (last.full.paged and "paged" or "full") .. " scan: " .. (last.full.failed or (last.full.listings .. " listings, " .. last.full.items .. " items, "
      .. (last.full.frames or 0) .. " frames (" .. (last.full.slow or 0) .. " slow), " .. (last.full.seconds or 0) .. " s"
      .. (last.full.worstSlice and string.format("; longest slice %d ms, game frames %d ms on average, longest %d ms",
        last.full.worstSlice, last.full.avgGap or 0, last.full.worstGap or 0) or "")
      .. (last.full.loads and ("; " .. last.full.loads .. " item data loads") or "")
      .. (last.full.pages and (", " .. last.full.pages .. " pages") or "")
      .. (last.full.passive and ", another addon's scan" or last.full.how and (", answer by " .. last.full.how) or "")))
  end
  if A.store().fullTriedAt then
    out[#out + 1] = "auction full scan last asked for " .. A.age(A.store().fullTriedAt)
      .. (last.instantFailed and last.instantFailed ~= last.full and ("; the last unanswered one: " .. last.instantFailed.failed .. ", " .. A.age(last.instantFailed.at)) or "")
  end
  if job and (job.kind == "full" or job.kind == "paged") then
    local secs = now() - (job.started or now())
    out[#out + 1] = "auction scan running: " .. job.kind .. ", " .. secs .. " s, "
      .. (job.kind == "paged" and (job.pages .. " pages, " .. (job.retries or 0) .. " retries") or ((job.polls or 0) .. " checks, phase " .. tostring(job.phase)))
      .. string.format(", %d rows, %d frames (%d slow), %d rows a slice now, %d restarts",
        job.done or 0, job.frames or 0, job.slow or 0, job.cap or A.CAP_START, job.stalls or 0)
  end
  if last.search then
    out[#out + 1] = "auction search: " .. Q.plain(last.search.name) .. " - " .. (last.search.failed or (last.search.results .. " results"))
  end
  return out
end

----------------------------------------------------------------------------
-- The Gold tab's AUCTION HOUSE card
----------------------------------------------------------------------------

local forgetAt
ns.gold.addSection(10, function(y)
  local U, C = ns.ui, ns.C
  local W = U.W
  local db = ns.db()
  local top = y
  y = y + 10
  U.T("AUCTION HOUSE", 14, y, W - 28, "label", C.gold)
  local count, fullAt = A.count(), A.lastScanAt()
  U.T(fullAt and ("Last scan " .. A.age(fullAt)) or "", 14, y, W - 28, "small", C.light, "RIGHT")
  y = y + 22
  if count == 0 and A.auctionator() then
    y = y + U.T("Auctionator is loaded: the Codex reads its prices, and Scan all adds a history of your own for the trend.",
      14, y, W - 28, "small", C.light) + 6
  elseif count == 0 then
    y = y + U.T("No price history yet: open the auction house and press Scan all to start. Prices come from your own scans.",
      14, y, W - 28, "small", C.dim) + 6
  else
    local note = ns.thousands(count) .. (count == 1 and " item" or " items") .. " priced on " .. Q.plain(realm()) .. "."
    if ns.settingsLost then note = note .. " Counting since you logged in: Forever didn't load your saved prices." end
    y = y + U.T(note, 14, y, W - 28, "small", C.light) + 6
  end
  -- what your guide needs, with today's price
  local rows = pricedNeeds()
  if #rows > 0 then
    U.T("FOR YOUR GUIDE", 14, y, W - 28, "small", C.gold)
    y = y + 16
    local total, unknown = 0, 0
    for i, w in ipairs(rows) do
      if i > 8 then break end
      U.T(Q.plain(w.need .. " x " .. w.name), 14, y, 220, "body", C.light)
      U.T(Q.plain(rowPrice(w)), 240, y, W - 254, "small", C.dim)
      local each = w.p and ((w.p.n > 0 and w.p.low) or w.p.usual)
      if each then total = total + each * w.need else unknown = unknown + 1 end
      y = y + 18
    end
    if total > 0 then
      y = y + U.T("About " .. ns.money(total) .. " at the auction house" .. (unknown > 0 and (", " .. unknown .. " not priced yet") or "") .. ".",
        14, y, W - 28, "small", C.light) + 4
    end
    y = y + 4
  end
  -- settings
  local function tick(label, on, flip, tip)
    U.check(label, 14, y, on, function() flip(); U.refresh() end, tip)
    y = y + 24
  end
  tick("Price lines on item tooltips", not db.noPriceTooltip, function() db.noPriceTooltip = not db.noPriceTooltip end,
    "The lowest price seen, the usual price, the trend and the vendor price. Hold Shift for low, median, high and how many were listed.")
  tick("Add the Codex tabs to the auction house", not db.noAuctionTabs, function()
    db.noAuctionTabs = not db.noAuctionTabs
    if ns.auctionPanel and open then ns.auctionPanel.onShow(root) end
  end, "Its pages: Overview, Deals, Selling and Scan.")
  tick("Search for my guide's items when I open it", not db.noAuctionSearch, function() db.noAuctionSearch = not db.noAuctionSearch end,
    "Quick searches for what your guide needs, one at a time, when you open the auction house.")
  if A.auctionator() then
    y = y + U.T("With Auctionator loaded the Codex leaves searching to it: use Search in Auctionator on the Codex tab.",
      14, y, W - 28, "small", C.dim) + 6
  end
  if count > 0 then
    local armed = forgetAt and now() - forgetAt < 5
    local b = U.btn(armed and "Click again to forget" or "Forget prices", 14, y + 4, 180, function()
      if forgetAt and now() - forgetAt < 5 then A.forget(); forgetAt = nil else forgetAt = now() end
      U.refresh()
    end, false, "Forget this realm's price history.")
    b.codexLabel = "Forget prices"
    y = y + 34
  end
  y = y + 4
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end)
