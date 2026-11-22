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
T.MINPROFITS = { { "Any", 0 }, { "10c", 10 }, { "1s", 100 }, { "10s", 1000 }, { "1g", 10000 } }
local HEARTHSTONE = 6948

local function has(t, name) return type(t) == "table" and type(t[name]) == "function" end
local function api() return type(C_AuctionHouse) == "table" and C_AuctionHouse or nil end
local function now() return GetTime and GetTime() or 0 end
local function vendorPrice(id, p)
  local v = tonumber((select(11, ns.itemInfo(id))))
  if (not v or v <= 0) and p then v = p.vendor end
  return v and v > 0 and v or nil
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
function T.minProfit() return setting(T.MINPROFITS, ns.db().auctionMinProfit, 0)[2] end

-- This realm's trading notes, kept with its prices: hidden[id] (left out of Selling and Deals),
-- set[id] (a price you nudged, copper each), paid[id] = { each, qty } (what the Codex bought it for).
function T.notes()
  local s = ns.auction.store()
  if type(s.trade) ~= "table" then s.trade = {} end
  local t = s.trade
  for _, k in ipairs({ "hidden", "set", "paid" }) do if type(t[k]) ~= "table" then t[k] = {} end end
  return t
end
function T.isHidden(id) return T.notes().hidden[id] and true or false end
function T.hide(id, on) T.notes().hidden[id] = on and true or nil; T.refresh() end
function T.hiddenCount()
  local n = 0
  for _ in pairs(T.notes().hidden) do n = n + 1 end
  return n
end

----------------------------------------------------------------------------
-- Prices and protections
----------------------------------------------------------------------------

-- The price to post one at: { price, base, usual, vendor, floor, blocked, warn }.
-- base = the lowest listing (else the usual price); price = base minus the undercut; floor = the
-- least that pays more than a vendor once the 5% cut is taken; blocked = a reason not to post;
-- warn = percent under the usual price when that passes the Warn under setting.
function T.sellPrice(id)
  local p = ns.auction.price(id)
  if not p then return nil, "No price seen yet: scan or search first." end
  local base = p.n > 0 and p.low or p.usual
  if not base or base < 1 then return nil, "No price seen yet: scan or search first." end
  local u = T.undercut()
  local price = u[2] > 0 and math.floor(base * (100 - u[2]) / 100) or base - (u[3] or 1)
  if price < 1 then price = 1 end
  local notes = T.notes()
  local set = tonumber(notes.set[id])
  if set and set >= 1 then price = set end
  local out = { price = price, base = base, usual = p.usual, vendor = vendorPrice(id, p), source = p.source,
    custom = set and true or nil, low = p.n > 0 and p.low or nil, n = p.n }
  local paid = type(notes.paid[id]) == "table" and tonumber(notes.paid[id].each)
  if paid and paid > 0 then out.paid = paid end
  if out.vendor then
    out.floor = math.ceil(out.vendor / (1 - T.CUT))
    if price < out.floor then
      out.blocked = "A vendor pays " .. ns.money(out.vendor) .. " each: sell it there."
    end
  end
  local warn = T.warnPct()
  if not out.blocked and warn > 0 and p.usual and p.usual > 0 and p.days and p.days >= 2 then
    local under = math.floor((p.usual - price) * 100 / p.usual + 0.5)
    if under >= warn then out.warn = under end
  end
  -- a flip you'd sell for less than you paid, once the cut is taken
  if not out.blocked and out.paid and math.floor(price * (1 - T.CUT)) < out.paid then out.loss = out.paid end
  return out
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
T.STATUS = {
  vendor = { "Vendor pays more", { 1, 0.35, 0.3 } },
  none = { "None listed: name your price", { 1, 0.82, 0 } },
  high = { "Above usual: sell now", { 0.3, 0.9, 0.35 } },
  few = { "Few listed: good spot", { 0.3, 0.9, 0.35 } },
  fair = { "Fair price", { 0.85, 0.85, 0.85 } },
  falling = { "Falling: sell soon", { 1, 0.82, 0 } },
  low = { "Below usual: hold?", { 1, 0.55, 0.2 } },
  new = { "New: little history", { 0.6, 0.6, 0.6 } },
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
  return key, e[1], e[2]
end

----------------------------------------------------------------------------
-- Quick sell: your bags
----------------------------------------------------------------------------

local function needed()
  local names = {}
  for _, w in ipairs(type(ns.profSupplies) == "function" and ns.profSupplies() or {}) do
    if w.name then names[w.name:lower()] = true end
  end
  return names
end

-- { { id, name, count, bag, slot, icon, sell = T.sellPrice } }, the most valuable first: items you
-- can trade (not bound, not grey, not something your route or your professions still need) with a
-- price from the auction house. unpriced = also those without a price (sell = nil); hidden = also
-- the ones you hid.
function T.sellable(unpriced, hidden)
  local C = type(C_Container) == "table" and C_Container
  if not has(C, "GetContainerNumSlots") or not has(C, "GetContainerItemInfo") then return {} end
  local keep, byID, out = needed(), {}, {}
  local notes = T.notes()
  for bag = 0, 4 do
    for slot = 1, tonumber(try(C.GetContainerNumSlots, bag)) or 0 do
      local info = try(C.GetContainerItemInfo, bag, slot)
      local id = type(info) == "table" and tonumber(info.itemID)
      if id and not info.isBound and (tonumber(info.quality) or 1) >= 1 and id ~= HEARTHSTONE
        and not (ns.vendor and ns.vendor.kept and ns.vendor.kept(id)) then
        local name = ns.itemInfo(id) or (type(info.hyperlink) == "string" and info.hyperlink:match("%[(.-)%]"))
        if name and not keep[name:lower()] and (hidden or not notes.hidden[id]) then
          local e = byID[id]
          if not e then
            local sell = T.sellPrice(id)
            if sell or unpriced then
              local _, _, _, _, _, _, _, _, _, icon = ns.itemInfo(id)
              e = { id = id, name = name, count = 0, bag = bag, slot = slot, icon = icon or info.iconFileID, sell = sell }
              byID[id] = e
              out[#out + 1] = e
            end
          end
          if e then e.count = e.count + (tonumber(info.stackCount) or 1) end
        end
      end
    end
  end
  table.sort(out, function(a, b)
    local va, vb = a.sell and a.sell.price * a.count or -1, b.sell and b.sell.price * b.count or -1
    if va ~= vb then return va > vb end
    return a.name < b.name
  end)
  return out
end

local last = { posts = 0, buys = 0, posted = 0, deposits = 0, spent = 0, cancels = 0 }
-- This session at the auction house: { posts, posted (value), deposits, buys, spent, cancels }.
function T.ledger() return last end
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

-- Posts row (a T.sellable() entry) on a click: the whole stack of a commodity at the unit price, or
-- one piece of an item. A post far under the usual price needs a second click within 5 s.
-- Returns what happened: "posted", "armed", "blocked", "failed".
function T.post(row)
  local sell = row and T.sellPrice(row.id)
  if not sell then return "failed" end
  if sell.blocked then ns.say(sell.blocked); return "blocked" end
  if (sell.warn or sell.loss) and not arm("post:" .. row.id) then
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
  ns.say("Posted " .. qty .. " " .. Q.plain(row.name) .. " at " .. ns.money(sell.price) .. " each"
    .. (deposit and deposit > 0 and (" (deposit " .. ns.money(deposit) .. ")") or "") .. ".")
  return "posted"
end

-- The first row Post next would post (not blocked), or nil.
function T.nextPost()
  for _, row in ipairs(T.sellable()) do
    if not row.sell.blocked then return row end
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
function T.deals(kind, hidden)
  local out = {}
  local items = ns.auction.store().items
  local flip, minProfit, notes = T.flipPct(), T.minProfit(), T.notes()
  for id, it in pairs(items) do
    local p = type(it) == "table" and (hidden or not notes.hidden[id]) and ns.auction.price(id)
    if p and p.n > 0 and p.low and p.low > 0 then
      local vendor = vendorPrice(id, p)
      if vendor and vendor > p.low then
        out[#out + 1] = { id = id, name = p.name or ("item " .. id), kind = "vendor", low = p.low, worth = vendor,
          profit = vendor - p.low, n = p.n, source = p.source, at = p.at }
      elseif p.usual and p.days and p.days >= 2 and p.low <= p.usual * (100 - flip) / 100 then
        local profit = math.floor(p.usual * (1 - T.CUT)) - p.low
        if profit > 0 then
          out[#out + 1] = { id = id, name = p.name or ("item " .. id), kind = "flip", low = p.low, worth = p.usual,
            profit = profit, n = p.n, source = p.source, at = p.at }
        end
      end
    end
  end
  local kept = {}
  for _, d in ipairs(out) do
    d.pct = d.low > 0 and math.floor(d.profit * 100 / d.low + 0.5) or 0
    if d.profit >= minProfit and (not kind or d.kind == kind) then kept[#kept + 1] = d end
  end
  table.sort(kept, function(a, b)
    if a.profit ~= b.profit then return a.profit > b.profit end
    return a.id < b.id
  end)
  return kept
end

-- The buying state per item: { stage = "search"|"ready"|"pricing"|"confirm"|"none", qty, total, unit,
-- auction, commodity, limit }.
local buying = {}
T.buying = buying

-- The most to pay for one: a vendor deal keeps a profit of at least a copper; a flip stops at the
-- price that still leaves a profit after the cut.
local function limitFor(deal)
  if deal.kind == "vendor" then return deal.worth - 1 end
  return math.floor(deal.worth * (1 - T.CUT)) - 1
end

-- First click: search the item's listings.
function T.check(deal)
  local C = api()
  if not has(C, "SendSearchQuery") then return false end
  local key = has(C, "MakeItemKey") and try(C.MakeItemKey, deal.id) or { itemID = deal.id }
  buying[deal.id] = { stage = "search", limit = limitFor(deal), deal = deal, key = key, at = now() }
  local ok = pcall(C.SendSearchQuery, key, {}, false)
  if not ok then buying[deal.id] = nil; return false end
  ns.after(5, function()
    local b = buying[deal.id]
    if b and b.stage == "search" then b.stage = "none"; b.why = "no answer"; T.refresh() end
  end)
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
  T.refresh()
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
  ns.say("Cancelled " .. Q.plain(row.name) .. ": it comes back by mail. Relist it from Selling once it's in your bags.")
  ns.after(1, T.queryOwned)
  return "cancelled"
end

-- Search results: how many cost no more than the limit, and what they come to.
local function readCommodity(id)
  local C, b = api(), buying[id]
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
  if not b or b.stage ~= "search" then return end
  local qty, total = 0, 0
  for i = 1, tonumber(try(C.GetNumCommoditySearchResults, id)) or 0 do
    local r = try(C.GetCommoditySearchResultInfo, id, i)
    local unit, n = type(r) == "table" and tonumber(r.unitPrice), type(r) == "table" and tonumber(r.quantity)
    if unit and n and unit <= b.limit and not r.containsOwnerItem then
      qty, total = qty + n, total + unit * n
    end
  end
  b.commodity = true
  if qty > 0 then b.stage, b.qty, b.total = "ready", qty, total else b.stage, b.why = "none", "gone" end
  T.refresh()
end

local function readItems(key)
  local C = api()
  local id = type(key) == "table" and tonumber(key.itemID)
  if id and mine.waiting == id then
    local best
    for i = 1, tonumber(try(C.GetNumItemSearchResults, key)) or 0 do
      local r = try(C.GetItemSearchResultInfo, key, i)
      local buyout = type(r) == "table" and tonumber(r.buyoutAmount)
      if buyout and not r.containsOwnerItem then
        local unit = buyout / math.max(1, tonumber(r.quantity) or 1)
        if not best or unit < best then best = math.floor(unit) end
      end
    end
    undercutRead(id, best)
  end
  local b = id and buying[id]
  if not b or b.stage ~= "search" then return end
  local best
  for i = 1, tonumber(try(C.GetNumItemSearchResults, key)) or 0 do
    local r = try(C.GetItemSearchResultInfo, key, i)
    local buyout = type(r) == "table" and tonumber(r.buyoutAmount)
    local n = type(r) == "table" and math.max(1, tonumber(r.quantity) or 1)
    if buyout and buyout / n <= b.limit and not r.containsOwnerItem and (not best or buyout / n < best.unit) then
      best = { auction = r.auctionID, total = buyout, qty = n, unit = buyout / n }
    end
  end
  b.commodity = false
  if best then b.stage, b.qty, b.total, b.auction = "ready", best.qty, best.total, best.auction
  else b.stage, b.why = "none", "gone" end
  T.refresh()
end

local function money() return tonumber(try(GetMoney)) or 0 end

-- A purchase: the session ledger, and what you paid (a later post under it asks twice).
local function boughtFor(id, b)
  last.buys = last.buys + 1
  last.spent = last.spent + b.total
  last.buy = { name = b.deal.name, qty = b.qty, total = b.total }
  local notes = T.notes()
  local old = type(notes.paid[id]) == "table" and notes.paid[id]
  local qty, cost = b.qty, b.total
  if old and tonumber(old.qty) and tonumber(old.each) then
    qty, cost = qty + old.qty, cost + old.qty * old.each
  end
  notes.paid[id] = { each = math.ceil(cost / qty), qty = qty }
  ns.say("Bought " .. b.qty .. " " .. Q.plain(b.deal.name) .. " for " .. ns.money(b.total) .. ".")
end

-- Second click (and third for a commodity): buy what the search found.
function T.buy(id)
  local C, b = api(), buying[id]
  if not b or not C then return false end
  if b.stage == "ready" then
    if b.total > money() then ns.say("Not enough money: " .. ns.money(b.total) .. " needed."); return false end
    if b.commodity then
      if not pcall(C.StartCommoditiesPurchase, id, b.qty) then return false end
      b.stage, b.expect = "pricing", b.total
      ns.after(5, function()
        local x = buying[id]
        if x and x.stage == "pricing" then x.stage, x.why = "none", "no price"; T.refresh() end
      end)
      T.refresh()
      return true
    end
    if not pcall(C.PlaceBid, b.auction, b.total) then return false end
    if ns.stats then ns.stats.expect("buys", b.total) end
    boughtFor(id, b)
    buying[id] = nil
    T.refresh()
    return true
  elseif b.stage == "confirm" then
    if not pcall(C.ConfirmCommoditiesPurchase, id, b.qty) then return false end
    if ns.stats then ns.stats.expect("buys", b.total) end
    b.stage = "buying"
    T.refresh()
    return true
  end
  return false
end

-- The server's price for a started commodity purchase: cancel when it went up by more than 2%.
local function priced(unit, total)
  for id, b in pairs(buying) do
    if b.stage == "pricing" then
      total = tonumber(total)
      if not total or total > b.expect * 1.02 then
        try(api().CancelCommoditiesPurchase)
        b.stage, b.why = "none", "price went up"
        ns.say(Q.plain(b.deal.name) .. ": the price went up to " .. ns.money(total or 0) .. ", so the Codex cancelled it.")
      else
        b.stage, b.total = "confirm", total
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
        boughtFor(id, b)
        buying[id] = nil
      else
        b.stage, b.why = "none", "failed"
        ns.say("Couldn't buy " .. Q.plain(b.deal.name) .. ": the game says why.")
      end
      T.refresh()
      return
    end
  end
end

-- The deal button's label for an item.
function T.dealLabel(id)
  local b = buying[id]
  if not b then return "Check" end
  if b.stage == "search" then return "Looking..." end
  if b.stage == "ready" then return "Buy " .. b.qty .. " for " .. ns.money(b.total) end
  if b.stage == "pricing" then return "Pricing..." end
  if b.stage == "confirm" then return "Confirm " .. ns.money(b.total) end
  if b.stage == "buying" then return "Buying..." end
  return b.why == "price went up" and "Price went up" or "Gone"
end

-- Redraws the Codex tab (AuctionPanel.lua) when it shows.
function T.refresh()
  if ns.auctionPanel then ns.auctionPanel.refresh() end
end

----------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------

local events
function ns.startAuctionTrade()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "BAG_UPDATE_DELAYED", "COMMODITY_SEARCH_RESULTS_UPDATED",
    "ITEM_SEARCH_RESULTS_UPDATED", "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE", "COMMODITY_PURCHASE_SUCCEEDED",
    "COMMODITY_PURCHASE_FAILED", "AUCTION_HOUSE_AUCTION_CREATED", "REPLICATE_ITEM_LIST_UPDATE", "OWNED_AUCTIONS_UPDATED",
    "AUCTION_CANCELED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, a, b)
    if event == "AUCTION_HOUSE_SHOW" then
      for k in pairs(buying) do buying[k] = nil end
      mine.list, mine.queue, mine.waiting, mine.checking = {}, {}, nil, nil
      ns.after(0.5, T.queryOwned)
    elseif event == "AUCTION_HOUSE_CLOSED" then
      for k in pairs(buying) do buying[k] = nil end
      mine.queue, mine.waiting, mine.checking = {}, nil, nil
    elseif not ns.auction.isOpen() then return
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then readCommodity(tonumber(a))
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then readItems(a)
    elseif event == "COMMODITY_PRICE_UPDATED" then priced(a, b)
    elseif event == "COMMODITY_PRICE_UNAVAILABLE" then
      for _, x in pairs(buying) do if x.stage == "pricing" then x.stage, x.why = "none", "gone" end end
      T.refresh()
    elseif event == "COMMODITY_PURCHASE_SUCCEEDED" then bought(true)
    elseif event == "COMMODITY_PURCHASE_FAILED" then bought(false)
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
  y = y + U.T("At the auction house the Codex tab lists what to sell from your bags and deals to buy. Every post and purchase is one click on its button. It never posts below what a vendor pays.",
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
