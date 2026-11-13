-- Vendor.lua: at a vendor, the Codex sells your grey items (one every 0.15 s, keeping anything a
-- guide step names and the Hearthstone). Selling doesn't start in combat or while Alt is held when
-- the vendor opens (Settings > Vendor turns it off). Every call is guarded: a client without the
-- container or merchant calls just gets nothing.
local _, ns = ...
local Q = ns.quests
local function try(...) return Q.try(...) end

local V = { selling = false }
ns.vendor = V

local HEARTHSTONE = 6948
local STEP = 0.15 -- seconds between two sales, and before the first
local merchantOpen = false
local run -- this visit's selling run: { queue, sold, total }
local seen = { visits = 0, sold = 0, total = 0 } -- for /codex debug
local events

-- Hook points: Stats.lua files the money these announce (called just before it moves).
function V.onSold() end

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

-- Grey items with a sell price, in bag order.
local function scan()
  local queue = {}
  for bag = 0, 4 do
    for slot = 1, numSlots(bag) do
      local id, count, quality, noValue, locked, link = slotInfo(bag, slot)
      if id and not locked and not kept(id) then
        local name, _, q, _, _, _, _, _, _, _, price = try(GetItemInfo, link or id)
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

local function finish(stopped)
  local r = run
  if not r then return end
  run, V.selling = nil, false
  seen.sold, seen.total = seen.sold + r.sold, seen.total + r.total
  if r.sold > 0 then
    ns.say("Sold " .. r.sold .. " grey item" .. (r.sold == 1 and "" or "s") .. " for " .. ns.money(r.total)
      .. (stopped and " (the vendor closed)" or "") .. ".")
  end
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

local function onShow()
  merchantOpen = true
  seen.visits = seen.visits + 1
  if run then finish(true) end
  local held = try(InCombatLockdown) or try(IsAltKeyDown)
  if held or ns.db().noAutoSell then return end
  local r = { queue = scan(), sold = 0, total = 0 }
  if #r.queue == 0 then return end
  run, V.selling = r, true
  ns.after(STEP, function() sellNext(r) end)
end

local function onClose()
  merchantOpen = false
  finish(true)
end

function ns.startVendor()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED" }) do pcall(events.RegisterEvent, events, ev) end
  events:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then onShow() elseif event == "MERCHANT_CLOSED" then onClose() end
  end)
end

function ns.vendorDebugLines()
  return { "vendor: " .. seen.visits .. " visits this session, sold " .. seen.sold .. " grey items for "
    .. ns.money(seen.total) .. (V.selling and ", selling now" or "") }
end
