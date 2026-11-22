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
local SEARCH_GAP, SEARCH_WAIT, CHUNK = 1.5, 5, 400

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

-- Files a reading. med/high only when the reading had every listing (a full scan or a search page).
function A.record(id, name, low, n, med, high)
  id = tonumber(id)
  if not id then return end
  local s = A.store()
  local it = s.items[id]
  if type(it) ~= "table" then it = {}; s.items[id] = it end
  if type(it.days) ~= "table" then it.days = {} end
  if type(name) == "string" and name ~= "" then
    it.name = name
    if indexFor == s then nameIndex[name:lower()] = id end
  end
  it.n, it.at, it.ator = tonumber(n) or 0, now(), nil
  -- the vendor price, kept for the deal finder (the item cache may not hold every listed item)
  local vendor = tonumber((select(11, ns.itemInfo(id))))
  if vendor and vendor > 0 then it.vendor = vendor end
  local d = today()
  if low then
    it.low, it.med, it.high = low, med or it.med, high or it.high
    local rec = it.days[d]
    if type(rec) ~= "table" then rec = {}; it.days[d] = rec end
    if rec.ator then rec.low, rec.med, rec.ator = nil, nil, nil end -- the Codex's own reading wins the day
    rec.low = rec.low and math.min(rec.low, low) or low
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
  local vendor = tonumber((select(11, ns.itemInfo(id))))
  if vendor and vendor > 0 then it.vendor = vendor end
  for k in pairs(it.days) do
    if type(k) ~= "number" or k <= today() - A.DAYS then it.days[k] = nil end
  end
  ator.filed = (ator.filed or 0) + 1
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
      at = days and (now() - days * 86400) or nil }
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
  local trend = base and base > 0 and last and math.floor((last - base) * 100 / base + 0.5) or nil
  return { name = it.name, low = it.low, med = it.med, high = it.high, n = tonumber(it.n) or 0, at = it.at,
    usual = usual, trend = trend, days = #all, vendor = tonumber(it.vendor), source = it.ator and "Auctionator" or nil }
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
end

-- low, median (by quantity), high (90th percentile: one silly listing doesn't count) and quantity
-- from { { unitPrice, quantity }, ... }.
local function summary(list)
  table.sort(list, function(a, b) return a[1] < b[1] end)
  local n = 0
  for _, e in ipairs(list) do n = n + e[2] end
  if n == 0 then return end
  local med, high, run = nil, nil, 0
  for _, e in ipairs(list) do
    run = run + e[2]
    if not med and run >= n / 2 then med = e[1] end
    if not high and run >= n * 0.9 then high = e[1] end
  end
  return list[1][1], n, med, high or list[#list][1]
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

local function finished(kind)
  if kind == "full" and ns.refreshTab then ns.refreshTab("gold") end
  if refreshCard then refreshCard() end
end

-- Whether a full scan can start now: ok, reason.
function A.canFullScan()
  if not open then return false, "Open the auction house first." end
  if job and job.kind == "full" then return false, "Scanning..." end
  local fullAt = tonumber(A.store().fullAt)
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

local function readModern(i)
  local C = api()
  local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = try(C.GetReplicateItemInfo, i)
  local name
  if has(C, "GetReplicateItemLink") then
    local link = try(C.GetReplicateItemLink, i)
    name = type(link) == "string" and link:match("%[(.-)%]")
    itemID = itemID or linkID(link)
  end
  return itemID, name, count, buyout
end
local function readClassic(i)
  local name, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = try(GetAuctionItemInfo, "list", i)
  return itemID or linkID(try(GetAuctionItemLink, "list", i)), name, count, buyout
end

-- Rows from..to into acc[itemID] = { name, list }.
local function collect(acc, read, from, to)
  for i = from, to do
    local id, name, count, buyout = read(i)
    id, count, buyout = tonumber(id), math.max(1, tonumber(count) or 1), tonumber(buyout)
    if id and buyout and buyout > 0 then
      local e = acc[id]
      if not e then e = { list = {} }; acc[id] = e end
      if type(name) == "string" and name ~= "" then e.name = name end
      e.list[#e.list + 1] = { math.floor(buyout / count + 0.5), count }
    end
  end
end

-- A list of rows filed as prices: every item gets its low/median/high; a full scan also marks
-- items it didn't see as none listed.
local function file(acc, full)
  local items = 0
  for id, e in pairs(acc) do
    local low, n, med, high = summary(e.list)
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

local function readFull()
  local j = job
  if not j or j.kind ~= "full" or j.reading then return end
  j.reading = true
  local total
  if j.modern then total = tonumber(try(api().GetNumReplicateItems)) or 0
  else total = tonumber(try(GetNumAuctionItems, "list")) or 0 end
  j.total = total
  local first = j.modern and 0 or 1
  local stop = j.modern and total - 1 or total
  local acc, read = {}, j.modern and readModern or readClassic
  local function chunk(from)
    if job ~= j then return end
    local to = math.min(stop, from + CHUNK - 1)
    collect(acc, read, from, to)
    j.done = to - first + 1
    if to < stop then
      j.chunks = (j.chunks or 0) + 1
      if refreshCard and j.chunks % 10 == 1 then refreshCard() end -- the scan's progress on the button
      ns.after(0, function() chunk(to + 1) end)
      return
    end
    local items = file(acc, true)
    A.store().fullAt = now()
    job = nil
    last.full = { at = now(), listings = total, items = items }
    ns.say("Full scan: " .. ns.thousands(total) .. " listings, " .. ns.thousands(items) .. " items priced.")
    finished("full")
    ns.after(SEARCH_GAP, A.pump)
  end
  chunk(first)
end

function A.fullScan()
  local ok, why = A.canFullScan()
  if not ok then ns.say(why); return false end
  local C = api()
  local j = { kind = "full", started = now(), modern = has(C, "ReplicateItems") }
  job = j
  local sent
  if j.modern then sent = pcall(C.ReplicateItems)
  else sent = pcall(QueryAuctionItems, "", nil, nil, 0, nil, nil, true, false) end
  if not sent then
    job = nil
    ns.say("The auction house refused the full scan.")
    finished("full")
    return false
  end
  ns.say("Full scan started: the auction house can take a minute to answer.")
  ns.after(90, function()
    if job == j and not j.reading then
      job = nil
      last.full = { at = now(), failed = "no answer" }
      ns.say("The full scan got no answer from the auction house. Try again in a few minutes.")
      finished("full")
    end
  end)
  finished("start")
  return true
end

-- Quick searches: one name at a time, a short gap between them.
function A.search(name)
  if type(name) ~= "string" or searched[name:lower()] then return end
  for _, n in ipairs(queue) do if n == name then return end end
  queue[#queue + 1] = name
end

local function sendSearch(name)
  local C = api()
  if has(C, "SendBrowseQuery") then
    local order = type(Enum) == "table" and type(Enum.AuctionHouseSortOrder) == "table" and Enum.AuctionHouseSortOrder.Price or 0
    return pcall(C.SendBrowseQuery, { searchString = name, sorts = { { sortOrder = order, reverseSort = false } }, filters = {} }), true
  end
  if type(QueryAuctionItems) == "function" then
    if try(CanSendAuctionQuery) == false then return nil end
    return pcall(QueryAuctionItems, name, nil, nil, 0, nil, nil, false, true), false
  end
  return false
end

function A.pump()
  if not open or job or #queue == 0 then return end
  local name = table.remove(queue, 1)
  local sent, modern = sendSearch(name)
  if sent == nil then -- the classic auction house isn't ready: try again shortly
    table.insert(queue, 1, name)
    ns.after(SEARCH_GAP, A.pump)
    return
  end
  searched[name:lower()] = true
  if not sent then ns.after(SEARCH_GAP, A.pump); return end
  local j = { kind = "search", name = name, modern = modern, at = now() }
  job = j
  ns.after(SEARCH_WAIT, function()
    if job == j then
      job = nil
      last.search = { name = name, at = now(), failed = "no answer" }
      ns.after(SEARCH_GAP, A.pump)
    end
  end)
end

local function searchDone(results)
  local j = job
  job = nil
  last.search = { name = j.name, at = now(), results = results }
  -- searched but not listed: the item is known and there is none for sale
  local id = A.idFor(j.name)
  if id and results == 0 then A.record(id, j.name, nil, 0) end
  finished("search")
  ns.after(SEARCH_GAP, A.pump)
end

local function readBrowse()
  local j = job
  if not j or j.kind ~= "search" or not j.modern then return end
  local C = api()
  local list = try(C.GetBrowseResults)
  local n = 0
  for _, r in ipairs(type(list) == "table" and list or {}) do
    local key = type(r) == "table" and r.itemKey
    local id = type(key) == "table" and tonumber(key.itemID)
    local low = tonumber(r.minPrice)
    if id and low and low > 0 then
      local name
      if has(C, "GetItemKeyInfo") then
        local info = try(C.GetItemKeyInfo, key)
        name = type(info) == "table" and info.itemName
      end
      name = name or ns.itemInfo(id)
      -- a browse result only has the lowest price: the old median stays until a full scan
      A.record(id, name, low, tonumber(r.totalQuantity) or 1)
      n = n + 1
    end
  end
  searchDone(n)
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
function A.queued()
  return #queue, job and job.kind == "search" and job.name or nil
end
function A.fullProgress()
  if job and job.kind == "full" then return job.done or 0, job.total end
end

local function queueNames(names)
  local n = 0
  for _, name in ipairs(names) do
    searched[name:lower()] = nil
    local before = #queue
    A.search(name)
    if #queue > before then n = n + 1 end
  end
  A.pump()
  if refreshCard then refreshCard() end
  return n
end

-- Searches every item in your bags you could sell whose price is older than 30 minutes.
-- Returns how many it queued.
function A.scanBags()
  if not open then return 0 end
  local names = {}
  local T = ns.auctionTrade
  for _, row in ipairs(T and T.sellable(true, true) or {}) do
    local p = A.price(row.id)
    if not (p and not p.source and p.at and now() - p.at < A.FRESH) then names[#names + 1] = row.name end
  end
  return queueNames(names)
end

-- Searches what your guide needs now, even with Auctionator loaded. Returns how many it queued.
function A.scanNeeds()
  if not open then return 0 end
  local names = {}
  for _, w in ipairs(A.needs()) do names[#names + 1] = w.name end
  return queueNames(names)
end

-- One item now (the Scan page's look-up).
function A.searchNow(name)
  if not open or type(name) ~= "string" or name == "" then return false end
  return queueNames({ name }) > 0 or (job and job.kind == "search" and job.name == name) or false
end

-- Drops the searches still waiting (a running one finishes).
function A.stopSearches() queue = {}; if refreshCard then refreshCard() end end

-- The daily values, oldest first: { { day, low, med } } (up to A.DAYS).
function A.history(id)
  local it = tonumber(id) and A.store().items[tonumber(id)]
  local out = {}
  if type(it) ~= "table" or type(it.days) ~= "table" then return out end
  for d, rec in pairs(it.days) do
    if type(d) == "number" and type(rec) == "table" and (rec.low or rec.med) then
      out[#out + 1] = { day = d, low = rec.low, med = rec.med }
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
refreshCard = function() if ns.auctionPanel then ns.auctionPanel.refresh() end end
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
  local vendor = tonumber((select(11, ns.itemInfo(id))))
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
end

local function onClose()
  open = false
  job, queue = nil, {}
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
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_ITEM_LIST_UPDATE", "BAG_UPDATE_DELAYED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then onShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then onClose()
    elseif not open then return
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then readFull()
    elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then readBrowse()
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
    .. ", full scan " .. A.age(A.store().fullAt) .. (open and ", open" or "")
  if A.auctionator() then
    out[#out + 1] = "auction: Auctionator loaded, " .. ator.found .. " of " .. ator.reads .. " price reads answered, "
      .. ator.searches .. " searches sent" .. (ator.last and (" (last " .. ator.last .. ")") or "")
      .. ", " .. (ator.filed or 0) .. " prices filed into the history"
      .. "; the Codex's own searches are off"
  end
  if last.full then
    out[#out + 1] = "auction full scan: " .. (last.full.failed or (last.full.listings .. " listings, " .. last.full.items .. " items"))
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
  local count, fullAt = A.count(), A.store().fullAt
  U.T(fullAt and ("Full scan " .. A.age(fullAt)) or "", 14, y, W - 28, "small", C.light, "RIGHT")
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
  tick("Add a Codex tab to the auction house", not db.noAuctionCard, function()
    db.noAuctionCard = not db.noAuctionCard
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
