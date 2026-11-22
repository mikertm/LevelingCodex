-- Auction.lua: the auction tools. Prices from your own scans (a full scan, and quick searches for
-- what your guide needs), a price history per realm with a trend, price lines on item tooltips, a
-- card at the auction house, and a sell helper that fills in a price when you click it.
-- Read-only toward the auction house: it never buys, bids or posts. You press Post yourself.
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
local SEARCH_GAP, SEARCH_WAIT, CHUNK, ROWS = 1.5, 5, 400, 6

local function now() return tonumber(time and time()) or 0 end
local function today(t) return math.floor((t or now()) / 86400) end
local function realm()
  local r = try(GetRealmName)
  return type(r) == "string" and r ~= "" and r or "Realm"
end
local function api() return type(C_AuctionHouse) == "table" and C_AuctionHouse or nil end
local function has(t, name) return type(t) == "table" and type(t[name]) == "function" end

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
  it.n, it.at = tonumber(n) or 0, now()
  local d = today()
  if low then
    it.low, it.med, it.high = low, med or it.med, high or it.high
    local rec = it.days[d]
    if type(rec) ~= "table" then rec = {}; it.days[d] = rec end
    rec.low = rec.low and math.min(rec.low, low) or low
    if med then rec.med = med end
  end
  for k in pairs(it.days) do
    if type(k) ~= "number" or k <= d - A.DAYS then it.days[k] = nil end
  end
end

-- What the history says about an item: { name, low, med, high, n, at, usual, trend, days }.
-- usual = the median of the daily values (median, else lowest); trend = the last day against the
-- usual of the days before it, in percent (two days or more).
function A.price(id)
  local it = tonumber(id) and A.store().items[tonumber(id)]
  if type(it) ~= "table" then return end
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
    usual = usual, trend = trend, days = #all }
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
      if not acc[id] and type(it) == "table" then it.n, it.at = 0, now() end
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
    if w.prof or (p and (p.n > 0 or p.usual)) or (not p and open and not searched[w.name:lower()]) then
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
    if open and not ns.db().noAuctionSearch and not searched[w.name:lower()] then return "searching" end
    return "not seen yet"
  end
  local s
  if p.n > 0 and p.low then s = ns.money(p.low) .. " each" else s = "none listed" end
  if p.usual and p.usual ~= p.low then s = s .. ", usual " .. ns.money(p.usual) end
  local t = A.trendText(p)
  if t then s = s .. ", " .. t end
  return s
end
A.rowPrice = rowPrice

local function queueNeeds()
  if ns.db().noAuctionSearch then return end
  for _, w in ipairs(A.needs()) do
    local id = w.id or A.idFor(w.name)
    local p = id and A.price(id)
    if not (p and p.at and now() - p.at < A.FRESH) then A.search(w.name) end
  end
  A.pump()
end

----------------------------------------------------------------------------
-- The sell helper
----------------------------------------------------------------------------

-- The item in Blizzard's sell frame: { id, name, count, frame, modern }.
function A.sellItem()
  local f = type(AuctionHouseFrame) == "table" and AuctionHouseFrame
  if f then
    for _, key in ipairs({ "CommoditiesSellFrame", "ItemSellFrame" }) do
      local sf = f[key]
      if type(sf) == "table" and has(sf, "IsShown") and sf:IsShown() and has(sf, "GetItem") then
        local loc = try(sf.GetItem, sf)
        local id = loc and type(C_Item) == "table" and try(C_Item.GetItemID, loc)
        if id then
          local p = A.price(id)
          return { id = id, name = ns.itemInfo(id) or (p and p.name), count = 1, frame = sf, modern = true }
        end
      end
    end
  end
  if type(GetAuctionSellItemInfo) == "function" then
    local name, _, count, _, _, _, _, _, _, id = try(GetAuctionSellItemInfo)
    if type(name) == "string" then return { id = tonumber(id) or A.idFor(name), name = name, count = math.max(1, tonumber(count) or 1) } end
  end
end

-- The price to ask each: one copper under the lowest listing, else the usual price. Also the
-- vendor's price when it pays more.
function A.suggest(id)
  local p = A.price(id)
  if not p then return end
  local price = p.n > 0 and p.low and p.low - 1 or p.usual
  if not price or price < 1 then return end
  local vendor = tonumber((select(11, ns.itemInfo(id))))
  return price, vendor and vendor > price and vendor or nil
end

function A.usePrice()
  local s = A.sellItem()
  local price = s and s.id and A.suggest(s.id)
  if not price then return false end
  local ok = false
  if s.modern then
    local input = s.frame.PriceInput
    if has(s.frame, "SetPrice") then ok = pcall(s.frame.SetPrice, s.frame, price)
    elseif has(input, "SetAmount") then ok = pcall(input.SetAmount, input, price) end
  elseif type(MoneyInputFrame_SetCopper) == "function" then
    if type(StartPrice) == "table" then ok = pcall(MoneyInputFrame_SetCopper, StartPrice, price * s.count) end
    if type(BuyoutPrice) == "table" then ok = pcall(MoneyInputFrame_SetCopper, BuyoutPrice, price * s.count) or ok end
  end
  last.sell = { item = s.name, price = price, ok = ok }
  if ok then ns.say("Price set to " .. ns.money(price) .. " each. Check it, then press Post yourself.")
  else ns.say("Couldn't fill in the price here: type " .. ns.money(price) .. " each.") end
  return ok
end

----------------------------------------------------------------------------
-- The card at the auction house
----------------------------------------------------------------------------

local card, place, sellSeen = nil, {}, nil

local function makeCard()
  local Art = ns.art
  local h = Art.frame("Frame", "LevelingCodexAuctionCard", UIParent)
  h:SetSize(320, 100)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:Hide()
  Art.cardChrome(h)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", 12, -10)
  h.label:SetText("CODEX PRICES")
  h.status = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  h.status:SetPoint("TOPRIGHT", -12, -10)
  h.status:SetJustifyH("RIGHT")
  h.rows = {}
  for i = 1, ROWS do
    local r = {}
    r.icon = h:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetWidth(250)
    r.name:SetJustifyH("LEFT")
    r.sub = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetWidth(270)
    r.sub:SetJustifyH("LEFT")
    h.rows[i] = r
  end
  h.empty = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  h.empty:SetWidth(296)
  h.empty:SetJustifyH("LEFT")
  h.sell = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.sell:SetWidth(296)
  h.sell:SetJustifyH("LEFT")
  h.use = Art.button(h, 296, 22)
  h.use:SetScript("OnClick", function() A.usePrice() end)
  h.scan = Art.button(h, 296, 22)
  h.scan:SetScript("OnClick", function() A.fullScan() end)
  -- Never attached to the controller (ns.gamepad): like the vendor card, a popup that shows by
  -- itself must not take the focus from Blizzard's window.
  return h
end

local function hideCard()
  if card then card:Hide() end
  place.edgeRoot = nil
end

function refreshCard()
  if ns.db().noAuctionCard or not open then hideCard(); return end
  if not card then card = makeCard() end
  ns.art.paintCard(card)
  local y = -28
  local rows = pricedNeeds()
  for i, r in ipairs(card.rows) do
    local w = rows[i]
    local shown = w ~= nil
    r.icon:SetShown(shown); r.name:SetShown(shown); r.sub:SetShown(shown)
    if w then
      r.icon:ClearAllPoints(); r.icon:SetPoint("TOPLEFT", 12, y)
      r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", 38, y)
      r.sub:ClearAllPoints(); r.sub:SetPoint("TOPLEFT", 38, y - 13)
      local _, _, _, _, _, _, _, _, _, icon = ns.itemInfo(w.id or w.name)
      ns.setIcon(r.icon, icon or "INV_Misc_Bag_10")
      r.name:SetText(Q.plain(w.need .. " x " .. w.name .. "  -  " .. rowPrice(w)))
      r.sub:SetText(Q.plain("for " .. (w.forText or "your guide")))
      y = y - 30
    end
  end
  card.empty:SetShown(#rows == 0)
  if #rows == 0 then
    card.empty:ClearAllPoints(); card.empty:SetPoint("TOPLEFT", 12, y)
    card.empty:SetText("Your guide needs nothing from the auction house right now.")
    y = y - 20
  end
  -- selling
  local s = A.sellItem()
  local key = s and (tostring(s.id) .. ":" .. tostring(s.name)) or nil
  if key ~= sellSeen then
    sellSeen = key
    if s and s.name then
      local p = s.id and A.price(s.id)
      if not (p and p.at and now() - p.at < 5 * 60) then A.search(s.name); A.pump() end
    end
  end
  local price, vendor = nil, nil
  if s and s.id then price, vendor = A.suggest(s.id) end
  card.sell:SetShown(s ~= nil)
  card.use:SetShown(price ~= nil)
  if s then
    y = y - 4
    card.sell:ClearAllPoints(); card.sell:SetPoint("TOPLEFT", 12, y)
    local p = s.id and A.price(s.id)
    local text = "SELLING " .. Q.plain(s.name or "this item") .. ": "
    if price then
      text = text .. rowPrice({ name = s.name or "", p = p })
      if vendor then text = text .. ". A vendor pays " .. ns.money(vendor) .. "." end
    elseif job and job.kind == "search" then text = text .. "searching"
    else text = text .. "no price seen yet" end
    card.sell:SetText(text)
    y = y - 30
    if price then
      card.use:ClearAllPoints(); card.use:SetPoint("TOPLEFT", 12, y)
      local label = "Use " .. ns.money(price) .. " each"
      card.use:SetLabel(label)
      card.use.codexLabel = label
      y = y - 26
    end
  end
  -- status and the full scan
  local ok, why = A.canFullScan()
  local label
  if job and job.kind == "full" then
    label = job.total and ("Scanning " .. ns.thousands(job.done or 0) .. " of " .. ns.thousands(job.total)) or "Scanning..."
  else label = ok and "Scan all" or why end
  card.scan:SetLabel(label)
  card.scan.codexLabel = "Scan all"
  card.scan:SetEnabled(ok)
  card.scan:ClearAllPoints(); card.scan:SetPoint("TOPLEFT", 12, y - 4)
  y = y - 32
  local fullAt = A.store().fullAt
  card.status:SetText(fullAt and ("Full scan " .. A.age(fullAt)) or (A.count() > 0 and (A.count() .. " prices") or "No prices yet"))
  card:SetHeight(-y + 8)
  if type(root) == "table" and has(root, "IsShown") then
    ns.placeByWindow(card, root, place)
    if not place.hooked and has(root, "HookScript") then
      place.hooked = true
      pcall(root.HookScript, root, "OnHide", hideCard)
    end
  else
    card:ClearAllPoints()
    card:SetPoint("TOP", UIParent, "TOP", 0, -100)
  end
  card:Show()
end

----------------------------------------------------------------------------
-- Item tooltips
----------------------------------------------------------------------------

-- The lines for an item: the auction price, its trend, the vendor price; Shift adds low / median /
-- high and how many were listed.
function A.tooltipLines(id, shift)
  local out = {}
  local p = A.price(id)
  local vendor = tonumber((select(11, ns.itemInfo(id))))
  if p then
    local line = p.n > 0 and p.low and ("Codex AH: " .. ns.coins(p.low)) or "Codex AH: none listed"
    if p.usual and p.usual ~= p.low then line = line .. "  usual " .. ns.coins(p.usual) end
    out[#out + 1] = line .. "  (" .. A.age(p.at) .. ")"
    local t = A.trendText(p)
    if t then out[#out + 1] = "Codex trend: " .. t .. " (" .. p.days .. " days)" end
  end
  if vendor and vendor > 0 and (p or shift) then out[#out + 1] = "Codex vendor: " .. ns.coins(vendor) end
  if shift and p then
    if p.low then
      out[#out + 1] = "Codex AH low / median / high: " .. ns.coins(p.low) .. " / " .. ns.coins(p.med or p.low)
        .. " / " .. ns.coins(p.high or p.low)
    end
    out[#out + 1] = "Codex AH listed: " .. ns.thousands(p.n) .. " at the last look"
  elseif shift then
    out[#out + 1] = "Codex AH: not seen yet. Scan at the auction house to start."
  end
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
  for _, line in ipairs(A.tooltipLines(id, IsShiftKeyDown and IsShiftKeyDown() and true or false)) do
    tip:AddLine(line, 0.85, 0.78, 0.55)
  end
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

local ticker
local function onShow()
  open = true
  queue, searched, sellSeen = {}, {}, nil
  root = (type(AuctionHouseFrame) == "table" and AuctionHouseFrame) or (type(AuctionFrame) == "table" and AuctionFrame) or nil
  refreshCard()
  ns.after(1, function() if open then queueNeeds(); refreshCard() end end)
  if ticker then ticker:Cancel() end
  ticker = ns.every(0.5, function()
    if not open then return end
    local s = A.sellItem()
    local key = s and (tostring(s.id) .. ":" .. tostring(s.name)) or nil
    if key ~= sellSeen then refreshCard() end
  end)
end

local function onClose()
  open = false
  job, queue = nil, {}
  if ticker then ticker:Cancel(); ticker = nil end
  hideCard()
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
  if last.full then
    out[#out + 1] = "auction full scan: " .. (last.full.failed or (last.full.listings .. " listings, " .. last.full.items .. " items"))
  end
  if last.search then
    out[#out + 1] = "auction search: " .. Q.plain(last.search.name) .. " - " .. (last.search.failed or (last.search.results .. " results"))
  end
  if last.sell then
    out[#out + 1] = "auction sell: " .. Q.plain(last.sell.item or "?") .. " at " .. ns.money(last.sell.price) .. (last.sell.ok and "" or " (not filled)")
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
  if count == 0 then
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
  tick("Show the Codex card at the auction house", not db.noAuctionCard, function() db.noAuctionCard = not db.noAuctionCard end,
    "Lists what your guide still needs with today's price, the Scan all button, and a price for the item you're selling. The Codex never buys or posts.")
  tick("Search for my guide's items when I open it", not db.noAuctionSearch, function() db.noAuctionSearch = not db.noAuctionSearch end,
    "Quick searches for the items on the card, one at a time, when you open the auction house.")
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
