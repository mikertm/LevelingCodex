-- AuctionTrade.lua: selling and deals at the auction house, on the card LevelingCodexTradeCard
-- under the Codex prices card.
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
T.ROWS, T.DEALS = 4, 4
T.UNDERCUTS = { { "1c", 0, 1 }, { "1%", 1 }, { "5%", 5 }, { "10%", 10 } }
T.WARNS = { { "20%", 20 }, { "30%", 30 }, { "50%", 50 }, { "Off", 0 } }
T.FLIPS = { { "20%", 20 }, { "30%", 30 }, { "50%", 50 } }
T.DURATIONS = { { "12 h", 1 }, { "24 h", 2 }, { "48 h", 3 } }
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
  local out = { price = price, base = base, usual = p.usual, vendor = vendorPrice(id, p), source = p.source }
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
  return out
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
-- price from the auction house.
function T.sellable()
  local C = type(C_Container) == "table" and C_Container
  if not has(C, "GetContainerNumSlots") or not has(C, "GetContainerItemInfo") then return {} end
  local keep, byID, out = needed(), {}, {}
  for bag = 0, 4 do
    for slot = 1, tonumber(try(C.GetContainerNumSlots, bag)) or 0 do
      local info = try(C.GetContainerItemInfo, bag, slot)
      local id = type(info) == "table" and tonumber(info.itemID)
      if id and not info.isBound and (tonumber(info.quality) or 1) >= 1 and id ~= HEARTHSTONE
        and not (ns.vendor and ns.vendor.kept and ns.vendor.kept(id)) then
        local name = ns.itemInfo(id) or (type(info.hyperlink) == "string" and info.hyperlink:match("%[(.-)%]"))
        if name and not keep[name:lower()] then
          local e = byID[id]
          if not e then
            local sell = T.sellPrice(id)
            if sell then
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
    local va, vb = a.sell.price * a.count, b.sell.price * b.count
    if va ~= vb then return va > vb end
    return a.name < b.name
  end)
  return out
end

local last = { posts = 0, buys = 0 }
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
  if sell.warn and not arm("post:" .. row.id) then
    ns.say(Q.plain(row.name) .. ": " .. ns.money(sell.price) .. " is " .. sell.warn .. "% under the usual "
      .. ns.money(sell.usual) .. ". Click Post again within 5 s to post it anyway.")
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
  last.post = { name = row.name, qty = qty, price = sell.price, deposit = deposit }
  ns.say("Posted " .. qty .. " " .. Q.plain(row.name) .. " at " .. ns.money(sell.price) .. " each"
    .. (deposit and deposit > 0 and (" (deposit " .. ns.money(deposit) .. ")") or "") .. ".")
  return "posted"
end

----------------------------------------------------------------------------
-- Deals: under vendor and flips
----------------------------------------------------------------------------

-- { { id, name, kind = "vendor"|"flip", low, worth, profit, n } }, the biggest profit per unit
-- first: listings a vendor pays more for (profit = vendor - low), and listings at least Flip at
-- under the usual price of two days or more (profit = usual after the 5% cut - low).
function T.deals()
  local out = {}
  local items = ns.auction.store().items
  local flip = T.flipPct()
  for id, it in pairs(items) do
    local p = type(it) == "table" and ns.auction.price(id)
    if p and p.n > 0 and p.low and p.low > 0 then
      local vendor = vendorPrice(id, p)
      if vendor and vendor > p.low then
        out[#out + 1] = { id = id, name = p.name or ("item " .. id), kind = "vendor", low = p.low, worth = vendor,
          profit = vendor - p.low, n = p.n }
      elseif p.usual and p.days and p.days >= 2 and p.low <= p.usual * (100 - flip) / 100 then
        local profit = math.floor(p.usual * (1 - T.CUT)) - p.low
        if profit > 0 then
          out[#out + 1] = { id = id, name = p.name or ("item " .. id), kind = "flip", low = p.low, worth = p.usual,
            profit = profit, n = p.n }
        end
      end
    end
  end
  table.sort(out, function(a, b)
    if a.profit ~= b.profit then return a.profit > b.profit end
    return a.id < b.id
  end)
  return out
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

-- Search results: how many cost no more than the limit, and what they come to.
local function readCommodity(id)
  local C, b = api(), buying[id]
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
    last.buys = last.buys + 1
    last.buy = { name = b.deal.name, qty = b.qty, total = b.total }
    ns.say("Bought " .. b.qty .. " " .. Q.plain(b.deal.name) .. " for " .. ns.money(b.total) .. ".")
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
        last.buys = last.buys + 1
        last.buy = { name = b.deal.name, qty = b.qty, total = b.total }
        ns.say("Bought " .. b.qty .. " " .. Q.plain(b.deal.name) .. " for " .. ns.money(b.total) .. ".")
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

----------------------------------------------------------------------------
-- The card
----------------------------------------------------------------------------

local card, place = nil, {}

local function makeRow(h)
  local r = {}
  r.icon = h:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(20, 20)
  r.name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.name:SetWidth(196)
  r.name:SetJustifyH("LEFT")
  r.sub = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  r.sub:SetWidth(196)
  r.sub:SetJustifyH("LEFT")
  r.btn = ns.art.button(h, 86, 20)
  return r
end

local function makeCard()
  local h = ns.art.frame("Frame", "LevelingCodexTradeCard", UIParent)
  h:SetSize(320, 100)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:Hide()
  ns.art.cardChrome(h)
  h.sellHead = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.sellHead:SetText("QUICK SELL")
  h.dealHead = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.dealHead:SetText("DEALS")
  h.note = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  h.note:SetWidth(296)
  h.note:SetJustifyH("LEFT")
  h.dealNote = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  h.dealNote:SetWidth(296)
  h.dealNote:SetJustifyH("LEFT")
  h.sells, h.deals = {}, {}
  for i = 1, T.ROWS do h.sells[i] = makeRow(h) end
  for i = 1, T.DEALS do h.deals[i] = makeRow(h) end
  -- Never attached to the controller, like the other auction house cards.
  return h
end

local function placeRow(r, y, shown)
  r.icon:SetShown(shown); r.name:SetShown(shown); r.sub:SetShown(shown); r.btn:SetShown(shown)
  if not shown then return end
  r.icon:ClearAllPoints(); r.icon:SetPoint("TOPLEFT", 12, y)
  r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", 38, y)
  r.sub:ClearAllPoints(); r.sub:SetPoint("TOPLEFT", 38, y - 13)
  r.btn:ClearAllPoints(); r.btn:SetPoint("TOPRIGHT", -12, y)
end

local function hide()
  if card then card:Hide() end
end

function T.refresh()
  if not card and (ns.db().noTradeCard or not ns.auction.isOpen()) then return end
  if ns.db().noTradeCard or not ns.auction.isOpen() or not T.available() then hide(); return end
  if not card then card = makeCard() end
  ns.art.paintCard(card)
  local y = -10
  card.sellHead:ClearAllPoints(); card.sellHead:SetPoint("TOPLEFT", 12, y)
  y = y - 18
  local rows = T.sellable()
  for i, r in ipairs(card.sells) do
    local row = rows[i]
    placeRow(r, y, row ~= nil)
    if row then
      local s = row.sell
      ns.setIcon(r.icon, row.icon or "INV_Misc_Bag_10")
      r.name:SetText(Q.plain(row.count .. " x " .. row.name))
      local sub = ns.money(s.price) .. " each"
      if s.usual and s.usual ~= s.price then sub = sub .. ", usual " .. ns.money(s.usual) end
      if s.blocked then sub = "Vendor pays " .. ns.money(s.vendor) .. ": sell it there"
      elseif s.warn then sub = sub .. " (" .. s.warn .. "% under)" end
      r.sub:SetText(Q.plain(sub))
      local key = "post:" .. row.id
      local label = s.blocked and "Vendor it" or (T.armed(key) and "Post anyway" or "Post")
      r.btn:SetLabel(label)
      r.btn.codexLabel = "Post " .. row.name
      r.btn:SetEnabled(not s.blocked)
      r.btn:SetScript("OnClick", function() T.post(row); T.refresh() end)
      y = y - 30
    end
  end
  card.note:SetShown(#rows == 0)
  if #rows == 0 then
    card.note:ClearAllPoints(); card.note:SetPoint("TOPLEFT", 12, y)
    card.note:SetText("Nothing priced to sell in your bags. Scan all prices what you carry.")
    y = y - 20
  end
  y = y - 6
  card.dealHead:ClearAllPoints(); card.dealHead:SetPoint("TOPLEFT", 12, y)
  y = y - 18
  local deals = T.deals()
  for i, r in ipairs(card.deals) do
    local d = deals[i]
    placeRow(r, y, d ~= nil)
    if d then
      local _, _, _, _, _, _, _, _, _, icon = ns.itemInfo(d.id)
      ns.setIcon(r.icon, icon or "INV_Misc_Coin_01")
      r.name:SetText(Q.plain(d.name))
      local sub = d.kind == "vendor"
        and ("Listed " .. ns.money(d.low) .. ", vendor pays " .. ns.money(d.worth) .. ": +" .. ns.money(d.profit) .. " each")
        or ("Listed " .. ns.money(d.low) .. ", usual " .. ns.money(d.worth) .. ": about +" .. ns.money(d.profit) .. " each")
      r.sub:SetText(Q.plain(sub))
      local label = T.dealLabel(d.id)
      local b = buying[d.id]
      r.btn:SetLabel(label)
      r.btn.codexLabel = "Deal " .. d.name
      r.btn:SetEnabled(not b or b.stage == "ready" or b.stage == "confirm" or b.stage == "none")
      r.btn:SetScript("OnClick", function()
        local x = buying[d.id]
        if not x or x.stage == "none" then T.check(d) else T.buy(d.id) end
        T.refresh()
      end)
      y = y - 30
    end
  end
  card.dealNote:SetShown(#deals == 0)
  if #deals == 0 then
    card.dealNote:ClearAllPoints(); card.dealNote:SetPoint("TOPLEFT", 12, y)
    card.dealNote:SetText("No deals in your prices yet. Scan all finds listings under vendor price and far under their usual price.")
    y = y - 30
  end
  card:SetHeight(-y + 8)
  local above = _G.LevelingCodexAuctionCard
  card:ClearAllPoints()
  if above and above:IsShown() then
    card:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -4)
  else
    local root = type(AuctionHouseFrame) == "table" and AuctionHouseFrame or nil
    if root then ns.placeByWindow(card, root, place) else card:SetPoint("TOP", UIParent, "TOP", 0, -100) end
  end
  card:Show()
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
    "COMMODITY_PURCHASE_FAILED", "AUCTION_HOUSE_AUCTION_CREATED", "REPLICATE_ITEM_LIST_UPDATE" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, a, b)
    if event == "AUCTION_HOUSE_SHOW" then
      for k in pairs(buying) do buying[k] = nil end
      -- after the prices card has placed itself
      ns.after(0, T.refresh)
    elseif event == "AUCTION_HOUSE_CLOSED" then
      for k in pairs(buying) do buying[k] = nil end
      hide()
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
    else T.refresh() end
  end)
end

function ns.auctionTradeDebugLines()
  local out = { "auction trade: " .. (T.available() and "post and buy" or "no modern auction API") .. ", " .. last.posts
    .. " posts, " .. last.buys .. " buys this session; undercut " .. T.undercut()[1] .. ", warn " .. T.warnPct()
    .. "%, flips " .. T.flipPct() .. "%" }
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
  y = y + U.T("At the auction house the Codex lists what to sell from your bags and deals to buy. Every post and purchase is one click on its card. It never posts below what a vendor pays.",
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
  U.check("Show the Quick sell and Deals card", 14, y, not db.noTradeCard, function()
    db.noTradeCard = not db.noTradeCard; U.refresh(); T.refresh()
  end, "The card under the Codex prices card at the auction house.")
  y = y + 28
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end)
