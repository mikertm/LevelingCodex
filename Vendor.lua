-- Vendor.lua: at a vendor, the Codex sells your grey items (one every 0.15 s, keeping anything a
-- guide step names and the Hearthstone), then repairs your gear with your own money. Neither starts
-- in combat or while Alt is held when the vendor opens (Settings > Vendor turns each off). A card
-- beside the vendor lists what your coming steps need that this vendor sells, with one Buy button
-- (nothing is bought until you click it). Every call is guarded: a client without the container or
-- merchant calls just gets nothing.
local _, ns = ...
local Q = ns.quests
local function try(...) return Q.try(...) end

local V = { selling = false }
ns.vendor = V

local HEARTHSTONE = 6948
local STEP = 0.15 -- seconds between two sales, and before the first
local merchantOpen = false
local run -- this visit's selling run: { queue, sold, total, visit }
local seen = { visits = 0, sold = 0, total = 0 } -- for /codex debug
local visit -- the last visit, for /codex debug: { at, window, note, greys, sold, total, stopped, repair }
local WINDOW_WAIT = 3 -- seconds a visit waits for the vendor window after MERCHANT_SHOW
local events

-- Hook points: Stats.lua files the money these announce (called just before it moves).
function V.onSold(copper) if ns.stats then ns.stats.expect("junk", copper) end end
function V.onRepaired(copper) if ns.stats then ns.stats.expect("repair", copper) end end
function V.onBought(copper) if ns.stats then ns.stats.expect("buys", copper) end end

local function numSlots(bag)
  local C = C_Container
  local n
  if C and type(C.GetContainerNumSlots) == "function" then n = try(C.GetContainerNumSlots, bag)
  else n = try(GetContainerNumSlots, bag) end
  return tonumber(n) or 0
end

-- itemID, count, quality, noValue, locked, link of a bag slot (nil when empty or unreadable).
local function slotInfo(bag, slot)
  local C = C_Container
  if C and type(C.GetContainerItemInfo) == "function" then
    local info = try(C.GetContainerItemInfo, bag, slot)
    if type(info) ~= "table" then return end
    return info.itemID, info.stackCount or 1, info.quality, info.hasNoValue, info.isLocked, info.hyperlink
  end
  if type(GetContainerItemInfo) == "function" then
    local _, count, locked, quality, _, _, link, _, noValue, id = try(GetContainerItemInfo, bag, slot)
    return id, count or 1, quality, noValue, locked, link
  end
end

local function useItem(bag, slot)
  local C = C_Container
  if C and type(C.UseContainerItem) == "function" then return try(C.UseContainerItem, bag, slot) end
  return try(UseContainerItem, bag, slot)
end

-- Items to keep even when grey: the Hearthstone, anything a route step names, vendor-only quest items.
local shopItems
local function kept(id)
  if id == HEARTHSTONE or Q.routeItems()[id] then return true end
  if not shopItems and type(ns.questShop) == "table" then
    shopItems = {}
    for _, list in pairs(ns.questShop) do
      for _, pair in ipairs(list) do shopItems[pair[1]] = true end
    end
  end
  return shopItems and shopItems[id] or false
end
V.kept = kept

-- Grey items with a sell price, in bag order.
local function scan()
  local queue = {}
  for bag = 0, 4 do
    for slot = 1, numSlots(bag) do
      local id, count, quality, noValue, locked, link = slotInfo(bag, slot)
      if id and not locked and not kept(id) then
        local name, _, q, _, _, _, _, _, _, _, price = ns.itemInfo(link or id)
        quality = quality or q
        price = (noValue and 0) or tonumber(price) or 0
        if name and quality == 0 and price > 0 then
          queue[#queue + 1] = { bag = bag, slot = slot, id = id, count = count, value = price * count }
        end
      end
    end
  end
  return queue
end

local function isOpen()
  if not merchantOpen then return false end
  local frame = MerchantFrame
  return not (type(frame) == "table" and type(frame.IsShown) == "function") or frame:IsShown() and true or false
end

local function noteRepair(text) if visit then visit.repair = text end end

-- After the junk money is in: repair everything, if this vendor repairs and you can pay for it.
local function repair()
  if ns.db().noAutoRepair then noteRepair("repair off"); return end
  local can = try(CanMerchantRepair)
  if can ~= true and can ~= 1 then noteRepair("no repair here (CanMerchantRepair " .. tostring(can) .. ")"); return end
  local cost = tonumber((try(GetRepairAllCost))) or 0
  if cost <= 0 then noteRepair("nothing to repair"); return end
  local money = tonumber(try(GetMoney)) or 0
  if money < cost then
    noteRepair("not enough money for " .. ns.money(cost))
    ns.say("Not enough money to repair (" .. ns.money(cost) .. ").")
    return
  end
  V.onRepaired(cost)
  try(RepairAllItems)
  noteRepair("repaired for " .. ns.money(cost))
  ns.say("Repaired for " .. ns.money(cost) .. ".")
end

-- The junk money comes after a server round trip: when only that money makes the repair
-- affordable, the repair waits for PLAYER_MONEY (or 3 s, then says what's short).
local pendingRepair
local function repairWhenPaid(total)
  local cost = tonumber((try(GetRepairAllCost))) or 0
  local money = tonumber(try(GetMoney)) or 0
  if total <= 0 or cost <= money or cost > money + total then repair(); return end
  noteRepair("waiting for the junk money")
  local token = {}
  pendingRepair = token
  ns.after(3, function()
    if pendingRepair ~= token then return end
    pendingRepair = nil
    if isOpen() then repair() end
  end)
end

local function moneyArrived()
  if not (pendingRepair and isOpen()) then return end
  local cost = tonumber((try(GetRepairAllCost))) or 0
  if (tonumber(try(GetMoney)) or 0) >= cost then
    pendingRepair = nil
    repair()
  end
end

local function finish(stopped)
  local r = run
  if not r then return end
  run, V.selling = nil, false
  seen.sold, seen.total = seen.sold + r.sold, seen.total + r.total
  if r.visit then r.visit.sold, r.visit.total, r.visit.stopped = r.sold, r.total, stopped end
  if r.sold > 0 then
    ns.say("Sold " .. r.sold .. " grey item" .. (r.sold == 1 and "" or "s") .. " for " .. ns.money(r.total)
      .. (stopped and " (the vendor closed)" or "") .. ".")
  end
  if not stopped then repairWhenPaid(r.total) end
end

local function sellNext(r)
  if run ~= r then return end
  if not isOpen() then finish(true); return end
  local item = table.remove(r.queue, 1)
  if item then
    -- The bag may have changed since the scan: only sell the same item and count.
    local id, count = slotInfo(item.bag, item.slot)
    if id == item.id and count == item.count then
      V.onSold(item.value)
      useItem(item.bag, item.slot)
      r.sold, r.total = r.sold + 1, r.total + item.value
    end
  end
  if #r.queue == 0 then finish(false) else ns.after(STEP, function() sellNext(r) end) end
end

----------------------------------------------------------------------------
-- What your coming steps need: pending rows from the current step to the end of the next section.
-- Buy and collect steps count their items; quests with vendor-only items (QuestShopData.lua) count
-- theirs, from the quest log's objective once you have the quest. Per item the larger of the two
-- totals counts (a buy step and the quest it buys for name the same spices), less what you carry.
----------------------------------------------------------------------------

local function windowRows()
  local rows = Q.rows()
  local _, i = Q.current()
  local out = {}
  if not i then return out end
  local seenSections, last = 0, nil
  for n = i, #rows do
    local row = rows[n]
    if row.section ~= last then
      last, seenSections = row.section, seenSections + 1
      if seenSections > 2 then break end
    end
    if row.state == "pending" then out[#out + 1] = row end
  end
  return out
end

-- How many of `item` the quest still asks for: its log objective naming the item (0 once finished),
-- else the generated count.
local function questWants(id, name, generated)
  local entry = Q.log(id)
  if not entry then return generated end
  for _, obj in ipairs(entry.objectives or {}) do
    local text = type(obj.text) == "string" and obj.text
    if text and name and text:lower():find(name:lower(), 1, true) then
      if obj.finished == true or obj.finished == 1 then return 0 end
      return tonumber(obj.numRequired) or tonumber(text:match("%d+%s*/%s*(%d+)")) or generated
    end
  end
  return generated
end

local function itemName(item, names)
  local name = names and names[item]
  if name then return name end
  name = ns.itemInfo(item)
  return type(name) == "string" and name or nil
end

-- { { item, need, forText }, ... } in route order, then your profession steps' supplies.
-- names: item -> name (the vendor's list). wantAll = item -> { n, forText }: what the route ahead
-- wants in all, before your bags (Quick Sell keeps that many back).
function V.needs(names, wantAll)
  local steps, quests, order, forText, counted, turnins = {}, {}, {}, {}, {}, {}
  local function note(item, text, better)
    if not forText[item] then order[#order + 1] = item; forText[item] = text
    elseif better and forText[item] == "a step ahead" then forText[item] = text end
  end
  local rows = windowRows()
  for _, row in ipairs(rows) do
    local s = row.step
    if s.type == "turnin" and s.quest and s.npc then turnins[s.quest] = turnins[s.quest] or s.npc end
  end
  for _, row in ipairs(rows) do
    local s = row.step
    if s.type == "buy" or s.type == "collect" then
      if s.item then steps[s.item] = (steps[s.item] or 0) + (s.count or 1); note(s.item, "a step ahead") end
      for _, pair in ipairs(type(s.items) == "table" and s.items or {}) do
        steps[pair[1]] = (steps[pair[1]] or 0) + (pair[2] or 1)
        note(pair[1], "a step ahead")
      end
    end
    local shop = s.quest and not counted[s.quest] and type(ns.questShop) == "table" and ns.questShop[s.quest]
    if shop then
      counted[s.quest] = true
      local who = turnins[s.quest] or s.name or (Q.log(s.quest) or {}).title or "a quest ahead"
      for _, pair in ipairs(shop) do
        local item = pair[1]
        quests[item] = (quests[item] or 0) + questWants(s.quest, itemName(item, names), pair[2] or 1)
        note(item, who, true)
      end
    end
  end
  -- Profession supplies (Professions.lua) come by name: only what this vendor sells can be matched.
  local prof, profName = {}, {}
  if names and not ns.db().noProfShop and ns.profSupplies then
    local idOf = {}
    for id, name in pairs(names) do idOf[name] = id end
    for _, row in ipairs(ns.profSupplies()) do
      local id = idOf[row.name]
      if id then
        prof[id], profName[id] = (prof[id] or 0) + row.n, row.name
        note(id, row.label)
      end
    end
  end
  if wantAll then
    local out = {}
    for _, item in ipairs(order) do
      local n = math.max(steps[item] or 0, quests[item] or 0)
      if n > 0 then out[item] = { n = n, forText = Q.plain(forText[item]) } end
    end
    return out
  end
  local out = {}
  for _, item in ipairs(order) do
    local have = Q.itemCount(item)
    if profName[item] then have = math.max(have, Q.itemCount(profName[item])) end
    local need = math.max(steps[item] or 0, quests[item] or 0) + (prof[item] or 0) - have
    if need > 0 then out[#out + 1] = { item = item, need = need, forText = Q.plain(forText[item]) } end
  end
  return out
end
function V.wanted() return V.needs(nil, true) end

----------------------------------------------------------------------------
-- The shopping card
----------------------------------------------------------------------------

local card, place = nil, {}
local ROWS = 6
local CONFIRM = 5 -- seconds a purchase waits for its items before it's called failed
-- The last purchase until its items reach your bags: { rows = { { id, name, n, cost, before } } }.
-- Until then the card says Buying... and another click buys nothing.
local buying

local function goods()
  local list, names = {}, {}
  for i = 1, tonumber(try(GetMerchantNumItems)) or 0 do
    local id = try(GetMerchantItemID, i)
    if not id then
      local link = try(GetMerchantItemLink, i)
      id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    end
    local name, icon, price, per, stock, _, _, extended = try(GetMerchantItemInfo, i)
    if name == nil and type(C_MerchantFrame) == "table" and type(C_MerchantFrame.GetItemInfo) == "function" then
      local info = try(C_MerchantFrame.GetItemInfo, i)
      if type(info) == "table" then
        name, icon, price, per, stock, extended = info.name, info.texture, info.price, info.stackCount,
          info.numAvailable, info.hasExtendedCost
      end
    end
    price = tonumber(price)
    if id and type(name) == "string" and price and not extended and not list[id] then
      list[id] = { id = id, index = i, name = name, icon = icon, price = price, per = math.max(1, tonumber(per) or 1),
        stock = tonumber(stock) or -1 }
      names[id] = name
    end
  end
  return list, names
end

-- The rows the card shows: needed items this vendor sells, capped by its stock.
local function shopping()
  local list, names = goods()
  local rows, total = {}, 0
  for _, want in ipairs(V.needs(names)) do
    local g = list[want.item]
    if g and #rows < ROWS then
      local n = want.need
      local short = g.stock ~= -1 and g.stock < n
      if short then n = g.stock end
      if n > 0 then
        local cost = g.per == 1 and g.price * n or g.price * math.ceil(n / g.per)
        rows[#rows + 1] = { good = g, n = n, cost = cost, forText = want.forText, short = short }
        total = total + cost
      end
    end
  end
  return rows, total
end

local SNIPE_ROWS = 4
local snipeWatch

local function bagCountOf(targetID)
  local total, vendor, foundName, foundIcon = 0, nil, nil, nil
  for bag = 0, 4 do
    for slot = 1, numSlots(bag) do
      local id, count, _, noValue, _, link = slotInfo(bag, slot)
      if id == targetID then
        total = total + (tonumber(count) or 1)
        if not vendor or not foundName then
          local name, _, _, _, _, _, _, _, _, icon, price = ns.itemInfo(link or id)
          if name and not foundName then foundName = name end
          if icon and not foundIcon then foundIcon = icon end
          price = (noValue and 0) or tonumber(price)
          if price and price > 0 and not vendor then vendor = price end
        end
      end
    end
  end
  return total, vendor, foundName, foundIcon
end

local function equippedCountOf(targetID)
  if type(GetInventoryItemLink) ~= "function" then return 0 end
  local n = 0
  for s = 1, 19 do
    local link = try(GetInventoryItemLink, "player", s)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if id == targetID then n = n + 1 end
  end
  return n
end

-- Snapshots bag counts of any item the Codex bought on the AH so selling them to a vendor (either
-- manually by right-clicking or with the Sell snipes button) logs a completed trade win/loss.
local function snapshotSnipes()
  if not (ns.auctionTrade and ns.auctionMarket and ns.auctionMarket.record) then snipeWatch = nil; return end
  local open = ns.auctionMarket.record().openByID or {}
  local paid = ns.auctionTrade.notes and ns.auctionTrade.notes().paid or {}
  local watch, any = {}, false
  local ids = {}
  for id in pairs(open) do ids[id] = true end
  for id in pairs(paid) do if tonumber(id) then ids[tonumber(id)] = true end end
  for id in pairs(ids) do
    local h, p = open[id], paid[id]
    local bagN, seenVendor, seenName = bagCountOf(id)
    if bagN > 0 or h or p then
      local v = seenVendor or (h and h.vendor) or (type(p) == "table" and p.vendor)
        or (ns.auctionTrade.vendorPrice and ns.auctionTrade.vendorPrice(id, ns.auction and ns.auction.price(id)))
      watch[id] = {
        bag = bagN,
        eq = equippedCountOf(id),
        name = seenName or (h and h.name) or (type(p) == "table" and p.name),
        vendor = ns.auction.vendorValue(id, v),
      }
      any = true
    end
  end
  snipeWatch = any and watch or nil
end

local function checkSnipeSales()
  if not snipeWatch or not (ns.auctionTrade and ns.auctionTrade.recordVendorSale) then return end
  for id, w in pairs(snipeWatch) do
    local nowBag, seenVendor, seenName = bagCountOf(id)
    local nowEq = equippedCountOf(id)
    if seenVendor and seenVendor > 0 and not w.vendor then w.vendor = seenVendor end
    if seenName and not w.name then w.name = seenName end
    if nowBag > w.bag then
      w.bag, w.eq = nowBag, nowEq
    elseif nowBag < w.bag then
      local eqDelta = math.max(0, nowEq - w.eq)
      local soldQty = (w.bag - nowBag) - eqDelta
      w.bag, w.eq = nowBag, nowEq
      if soldQty > 0 and w.vendor and w.vendor > 0 then
        ns.auctionTrade.recordVendorSale(id, w.name, soldQty, w.vendor)
      end
    else
      w.eq = nowEq
    end
  end
end

-- Finds sniped under-vendor items currently in your bags for the vendor card's 1-click Sell snipes button.
local function snipeBagQueue()
  if not (ns.auctionTrade and ns.auctionMarket and ns.auctionMarket.record) then return {}, {}, 0, 0, 0 end
  local open = ns.auctionMarket.record().openByID or {}
  local paid = ns.auctionTrade.notes and ns.auctionTrade.notes().paid or {}
  local rows, byID, slots = {}, {}, {}
  local leftByID = {}
  local grossTotal, profitTotal, totalCount = 0, 0, 0
  for bag = 0, 4 do
    for slot = 1, numSlots(bag) do
      local id, count, quality, noValue, locked, link = slotInfo(bag, slot)
      count = tonumber(count) or 1
      if id and not locked and not noValue and not kept(id) then
        local h, p = open[id], paid[id]
        if h or type(p) == "table" then
          local name, _, q, _, _, _, _, _, _, icon, sell = ns.itemInfo(link or id)
          quality = quality or q or 1
          local v = tonumber(sell) or (h and h.vendor) or (type(p) == "table" and p.vendor)
            or (ns.auction and ns.auction.price(id) and ns.auction.price(id).vendor)
          v = ns.auction.vendorValue(id, v) or 0
          local eachPaid = (h and h.each) or (type(p) == "table" and tonumber(p.each)) or 0
          local isVendorSnipe = (h and (h.kind == "vendor" or h.via == "vendor"))
            or (type(p) == "table" and p.kind == "vendor")
            or (v > 0 and eachPaid > 0 and v > eachPaid)
          if quality >= 1 and v > 0 and isVendorSnipe then
            if leftByID[id] == nil then
              leftByID[id] = (h and h.qty) or (type(p) == "table" and tonumber(p.qty)) or count
            end
            if leftByID[id] >= count and leftByID[id] > 0 then
              leftByID[id] = leftByID[id] - count
              local gross = v * count
              local profit = (v - eachPaid) * count
              slots[#slots + 1] = { bag = bag, slot = slot, id = id, count = count, value = gross }
              local r = byID[id]
              if not r then
                r = { id = id, name = name or (h and h.name) or ("item " .. id),
                  icon = icon or (ns.auction and ns.auction.iconOf(id)), n = 0, gross = 0, profit = 0 }
                byID[id] = r
                rows[#rows + 1] = r
              end
              r.n, r.gross, r.profit = r.n + count, r.gross + gross, r.profit + profit
              grossTotal, profitTotal, totalCount = grossTotal + gross, profitTotal + profit, totalCount + count
            end
          end
        end
      end
    end
  end
  return rows, slots, grossTotal, profitTotal, totalCount
end

local function makeCard()
  local A, C = ns.art, ns.C
  local h = A.frame("Frame", "LevelingCodexShopCard", UIParent)
  h:SetSize(300, 100)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:Hide()
  A.cardChrome(h) -- the tooltip border, flat edges, or external UI's panel behind it (painted in refreshCard)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", 12, -10)
  h.label:SetText("FOR YOUR GUIDE")
  h.rows = {}
  for i = 1, ROWS do
    local r = {}
    local top = -26 - (i - 1) * 30
    r.icon = h:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.icon:SetPoint("TOPLEFT", 12, top)
    r.name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("TOPLEFT", 38, top)
    r.name:SetWidth(190)
    r.name:SetJustifyH("LEFT")
    r.price = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.price:SetPoint("TOPRIGHT", -12, top)
    r.price:SetJustifyH("RIGHT")
    r.sub = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 38, top - 13)
    r.sub:SetWidth(250)
    r.sub:SetJustifyH("LEFT")
    h.rows[i] = r
  end
  h.buy = A.button(h, 276, 22)
  h.buy:SetScript("OnClick", function() V.buy() end)
  h.snipeHead = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.snipeHead:SetText("SNIPED FOR VENDOR")
  h.snipeRows = {}
  for i = 1, SNIPE_ROWS do
    local r = {}
    r.icon = h:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetWidth(190)
    r.name:SetJustifyH("LEFT")
    r.price = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.price:SetJustifyH("RIGHT")
    r.sub = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetWidth(250)
    r.sub:SetJustifyH("LEFT")
    h.snipeRows[i] = r
  end
  h.sellSnipes = A.button(h, 276, 22)
  h.sellSnipes:SetScript("OnClick", function() V.sellSnipes() end)
  -- Never attached to the controller (ns.gamepad): the card shows up by itself at every vendor, and
  -- as a controller popup it took the focus from the vendor window, so A bought its items.
  return h
end

local function hideCard()
  if card then card:Hide() end
  place.edgeRoot = nil
end

local function refreshCard()
  if ns.db().noShopCard or not isOpen() then hideCard(); return end
  local rows, total = shopping()
  local snipes, _, snipeGross, snipeProfit, snipeCount = snipeBagQueue()
  if #rows == 0 and #snipes == 0 then hideCard(); return end
  if not card then card = makeCard() end
  ns.art.paintCard(card)
  local y = 10
  card.label:SetShown(#rows > 0)
  for i, r in ipairs(card.rows) do
    local row = rows[i]
    local shown = row ~= nil
    r.icon:SetShown(shown); r.name:SetShown(shown); r.price:SetShown(shown); r.sub:SetShown(shown)
    if row then
      local top = -(y + 16 + (i - 1) * 30)
      r.icon:ClearAllPoints(); r.icon:SetPoint("TOPLEFT", 12, top)
      r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", 38, top)
      r.price:ClearAllPoints(); r.price:SetPoint("TOPRIGHT", -12, top)
      r.sub:ClearAllPoints(); r.sub:SetPoint("TOPLEFT", 38, top - 13)
      ns.setIcon(r.icon, row.good.icon or "INV_Misc_Bag_10")
      r.name:SetText(Q.plain(row.n .. " x " .. row.good.name))
      r.price:SetText(ns.money(row.cost))
      r.sub:SetText(Q.plain("for " .. row.forText .. (row.short and ("  (only " .. row.n .. " in stock)") or "")))
    end
  end
  if #rows > 0 then
    local money = tonumber(try(GetMoney)) or 0
    local label = money >= total and ("Buy for " .. ns.money(total)) or ("Need " .. ns.money(total - money) .. " more")
    if buying then label = "Buying..." end
    card.buy:SetLabel(label)
    card.buy.codexLabel = label
    card.buy:ClearAllPoints()
    card.buy:SetPoint("TOPLEFT", 12, -(y + 20 + #rows * 30))
    card.buy:Show()
    y = y + 20 + #rows * 30 + 28
  else
    card.buy:Hide()
  end
  card.snipeHead:SetShown(#snipes > 0)
  if #snipes > 0 then
    card.snipeHead:ClearAllPoints()
    card.snipeHead:SetPoint("TOPLEFT", 12, -y)
    local showN = math.min(#snipes, SNIPE_ROWS)
    for i, r in ipairs(card.snipeRows) do
      local s = i <= showN and snipes[i] or nil
      local shown = s ~= nil
      r.icon:SetShown(shown); r.name:SetShown(shown); r.price:SetShown(shown); r.sub:SetShown(shown)
      if s then
        local top = -(y + 16 + (i - 1) * 30)
        r.icon:ClearAllPoints(); r.icon:SetPoint("TOPLEFT", 12, top)
        r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", 38, top)
        r.price:ClearAllPoints(); r.price:SetPoint("TOPRIGHT", -12, top)
        r.sub:ClearAllPoints(); r.sub:SetPoint("TOPLEFT", 38, top - 13)
        ns.setIcon(r.icon, s.icon or "INV_Misc_Coin_01")
        r.name:SetText(Q.plain(s.n .. " x " .. s.name))
        r.price:SetText(ns.money(s.gross))
        r.sub:SetText(Q.plain((s.profit >= 0 and "+" or "-") .. ns.money(math.abs(s.profit)) .. " snipe profit"))
        r.sub:SetTextColor(0.3, 0.9, 0.35)
      end
    end
    local slabel = "Sell " .. snipeCount .. (snipeCount == 1 and " snipe for " or " snipes for ") .. ns.money(snipeGross)
      .. (snipeProfit > 0 and (" (+" .. ns.money(snipeProfit) .. ")") or "")
    card.sellSnipes:SetLabel(slabel)
    card.sellSnipes.codexLabel = "Sell snipes"
    card.sellSnipes:ClearAllPoints()
    card.sellSnipes:SetPoint("TOPLEFT", 12, -(y + 20 + showN * 30))
    card.sellSnipes:Show()
    y = y + 20 + showN * 30 + 28
  else
    for _, r in ipairs(card.snipeRows) do r.icon:Hide(); r.name:Hide(); r.price:Hide(); r.sub:Hide() end
    card.sellSnipes:Hide()
  end
  card:SetHeight(y + 6)
  local root = MerchantFrame
  if type(root) == "table" and type(root.IsShown) == "function" then
    ns.placeByWindow(card, root, place)
    if not place.hooked and type(root.HookScript) == "function" then
      place.hooked = true
      pcall(root.HookScript, root, "OnHide", hideCard)
    end
  else
    card:ClearAllPoints()
    card:SetPoint("TOP", UIParent, "TOP", 0, -100)
  end
  card:Show()
end

-- Whether the client can count your bags; without it a purchase is taken on trust.
local function canCount()
  return type(C_Item) == "table" and type(C_Item.GetItemCount) == "function" or type(GetItemCount) == "function"
end

-- Say what the last purchase brought once it's in your bags. `final` (the wait is over): what never
-- came is called failed (the game says why: full bags, ...).
local function settle(final)
  if not buying then return end
  local waiting = {}
  for _, r in ipairs(buying.rows) do
    local got = canCount() and Q.itemCount(r.id) - r.before or r.n
    if got >= r.n then
      ns.say(Q.plain("Bought " .. r.n .. " " .. r.name .. " for " .. ns.money(r.cost) .. "."))
    elseif final and got > 0 then
      ns.say(Q.plain("Bought " .. got .. " of " .. r.n .. " " .. r.name .. "."))
    elseif final then
      ns.say(Q.plain("Couldn't buy " .. r.n .. " " .. r.name .. "."))
    else
      waiting[#waiting + 1] = r
    end
  end
  buying.rows = waiting
  if final or #waiting == 0 then buying = nil end
end

-- Buy everything the card lists (only when you can pay for all of it).
function V.sellSnipes()
  if not isOpen() then hideCard(); return 0 end
  snapshotSnipes()
  local _, slots = snipeBagQueue()
  local sold = 0
  for _, s in ipairs(slots) do
    local id, count, _, _, locked = slotInfo(s.bag, s.slot)
    if id == s.id and count == s.count and not locked then
      V.onSold(s.value)
      useItem(s.bag, s.slot)
      sold = sold + count
    end
  end
  checkSnipeSales()
  refreshCard()
  return sold
end

function V.buy()
  if not isOpen() then hideCard(); return end
  -- the items arrive after a server round trip: until then another click must not buy them again
  if buying then return end
  local rows, total = shopping()
  if #rows == 0 or (tonumber(try(GetMoney)) or 0) < total then refreshCard(); return end
  V.onBought(total)
  local this = { rows = {} }
  for _, row in ipairs(rows) do
    local g = row.good
    this.rows[#this.rows + 1] = { id = g.id, name = g.name, n = row.n, cost = row.cost, before = Q.itemCount(g.id) }
  end
  buying = this
  for _, row in ipairs(rows) do
    local g = row.good
    if g.per == 1 then
      local chunk = math.max(1, tonumber(try(GetMerchantItemMaxStack, g.index)) or 20)
      local left = row.n
      while left > 0 do
        local k = math.min(chunk, left)
        try(BuyMerchantItem, g.index, k)
        left = left - k
      end
    else
      for _ = 1, math.ceil(row.n / g.per) do try(BuyMerchantItem, g.index) end
    end
  end
  settle(false)
  ns.after(CONFIRM, function()
    if buying == this then settle(true); if isOpen() then refreshCard() end end
  end)
  refreshCard()
end

-- The window is there: sell the greys, then repair.
local function begin(v)
  local r = { queue = ns.db().noAutoSell and {} or scan(), sold = 0, total = 0, visit = v }
  v.greys = ns.db().noAutoSell and "selling off" or #r.queue
  if #r.queue == 0 then repair(); return end
  run, V.selling = r, true
  ns.after(STEP, function() sellNext(r) end)
end

-- Forever fires MERCHANT_SHOW before the vendor window shows (reference guide B's Forever build says so too),
-- and a run that started then found the window "closed" and stopped before its first sale: the
-- visit waits for the window (up to WINDOW_WAIT), then sells and repairs. Alt and combat are read
-- as the vendor opens.
local function onShow()
  merchantOpen = true
  seen.visits = seen.visits + 1
  snapshotSnipes()
  if run then finish(true) end
  local v = { at = GetTime() }
  visit = v
  if try(InCombatLockdown) then v.note = "held back (combat)"; return end
  if try(IsAltKeyDown) then v.note = "held back (Alt)"; return end
  local function wait()
    if visit ~= v or not merchantOpen then return end
    if isOpen() then
      v.window = GetTime() - v.at
      begin(v)
      if v.window > 0 then refreshCard() end
      return
    end
    if GetTime() - v.at >= WINDOW_WAIT then v.note = "the vendor window never showed"; return end
    ns.after(0.1, wait)
  end
  wait()
end

-- A purchase still on its way is kept: its items can arrive after the window closes.
local function onClose()
  checkSnipeSales()
  snipeWatch = nil
  merchantOpen, pendingRepair = false, nil
  if visit and not visit.window and not visit.note then visit.note = "closed before its window showed" end
  finish(true)
  hideCard()
end

function ns.startVendor()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_MONEY" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
      onShow()
      refreshCard()
      -- the window can open just after the event: place the card against it once it's there
      ns.after(0.3, function() if isOpen() then refreshCard() end end)
    elseif event == "MERCHANT_CLOSED" then
      onClose()
    elseif event == "PLAYER_MONEY" then
      if merchantOpen then checkSnipeSales(); refreshCard() end
      moneyArrived()
    else
      if event == "BAG_UPDATE_DELAYED" then
        settle(false)
        if merchantOpen then checkSnipeSales() end
      end
      if merchantOpen then refreshCard() end
    end
  end)
end

local function visitLine()
  local v = visit
  if not v then return "vendor: last visit: none this session" end
  local parts = {}
  if v.window then parts[#parts + 1] = string.format("window %.1f s after MERCHANT_SHOW", v.window) end
  if v.note then parts[#parts + 1] = v.note end
  if v.greys == 0 then parts[#parts + 1] = "no greys to sell"
  elseif type(v.greys) == "string" then parts[#parts + 1] = v.greys end
  if v.sold then
    parts[#parts + 1] = "sold " .. v.sold .. " grey item" .. (v.sold == 1 and "" or "s") .. " for "
      .. ns.money(v.total) .. (v.stopped and " (stopped: the window closed)" or "")
  end
  if v.repair then parts[#parts + 1] = v.repair end
  return "vendor: last visit: " .. (#parts > 0 and table.concat(parts, "; ") or "nothing done yet")
end

function ns.vendorDebugLines()
  return { "vendor: " .. seen.visits .. " visits this session, sold " .. seen.sold .. " grey items for "
    .. ns.money(seen.total) .. (V.selling and ", selling now" or ""), visitLine() }
end
