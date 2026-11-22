-- AuctionPanel.lua: the Codex tab in the auction house's tab row (ns.auctionPanel, P).
-- One tab button after the last tab hanging under the auction house (Blizzard's, Auctionator's),
-- and a panel over the auction house's content with four pages: Overview, Deals, Selling, Scan.
-- Taint: the Codex never calls Blizzard's SetDisplayMode, never hides Blizzard's frames and never
-- joins its Tabs list. Clicking another tab (an OnClick hook) or the auction house changing mode
-- (hooksecurefunc on SetDisplayMode) hides the panel. Every post, purchase and cancel is one click
-- on a button here (AuctionTrade.lua); nothing runs by itself.
local _, ns = ...
local Q = ns.quests
local try = Q.try

local P = {}
ns.auctionPanel = P

P.PAGES = { { "overview", "Overview" }, { "deals", "Deals" }, { "selling", "Selling" }, { "scan", "Scan" } }
local page, reopen, picked = "overview", false, false
local root, tab, panel, body, lookupBox
local hooked = {}
local offsets, wheelKey = {}, nil
local view = { deals = nil, hidden = false, lookup = nil }
local forgetAt

local function has(t, name) return type(t) == "table" and type(t[name]) == "function" end
local function now() return tonumber(time and time()) or 0 end
local function A() return ns.auction end
local function T() return ns.auctionTrade end

function P.enabled() return not ns.db().noAuctionCard end
function P.shown() return panel ~= nil and panel:IsShown() and root ~= nil and root:IsShown() and true or false end
function P.page() return page end

----------------------------------------------------------------------------
-- The tab button
----------------------------------------------------------------------------

-- Tab buttons hanging under the auction house: its Tabs list and named children with "Tab".
local function tabsOf(r)
  local list, seen = {}, {}
  local function add(b)
    if type(b) == "table" and b ~= tab and not seen[b] and has(b, "IsShown") then seen[b] = true; list[#list + 1] = b end
  end
  if type(r.Tabs) == "table" then for _, b in ipairs(r.Tabs) do add(b) end end
  if has(r, "GetChildren") then
    for _, c in ipairs({ r:GetChildren() }) do
      local name = has(c, "GetName") and c:GetName()
      local kind = has(c, "GetObjectType") and c:GetObjectType()
      if type(name) == "string" and name:lower():find("tab", 1, true) and kind == "Button"
        and not name:find("^LevelingCodex") then add(c) end
    end
  end
  return list
end

local function edges(b)
  local l = tonumber((try(b.GetLeft, b)))
  if not l then return end
  local r = has(b, "GetRight") and tonumber((try(b.GetRight, b)))
  return l, r or (l + (tonumber((try(b.GetWidth, b))) or 0))
end

-- Right of the rightmost shown tab, with the same gap as the two before it.
local function place()
  if not tab or not root then return end
  local shown = {}
  for _, b in ipairs(tabsOf(root)) do
    if b:IsShown() then
      local l, r = edges(b)
      if l and r then shown[#shown + 1] = { b = b, l = l, r = r } end
    end
  end
  table.sort(shown, function(a, b) return a.r < b.r end)
  tab:ClearAllPoints()
  local last, prev = shown[#shown], shown[#shown - 1]
  if last then
    local gap = prev and math.max(-20, math.min(10, last.l - prev.r)) or 0
    tab:SetPoint("LEFT", last.b, "RIGHT", gap, 0)
  else
    tab:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 12, 2)
  end
end

local function hookTabs()
  for _, b in ipairs(tabsOf(root)) do
    if not hooked[b] and has(b, "HookScript") then
      hooked[b] = true
      pcall(b.HookScript, b, "OnClick", function(self) picked = true; P.close(self) end)
    end
  end
  if not hooked[root] and has(root, "SetDisplayMode") and type(hooksecurefunc) == "function" then
    hooked[root] = true
    pcall(hooksecurefunc, root, "SetDisplayMode", function() P.close() end)
  end
end

local function makeTab()
  tab = ns.art.tab(root, "Codex")
  tab.codexLabel = "Codex"
  tab.tipTitle = "Leveling Codex"
  tab.tipText = "Deals, quick selling, undercuts and price scans."
  tab:SetScript("OnClick", function() picked = true; P.open() end)
  if has(tab, "HookScript") then
    tab:HookScript("OnEnter", ns.art.showTip)
    tab:HookScript("OnLeave", ns.art.hideTip)
  end
end

----------------------------------------------------------------------------
-- The panel and its pooled widgets
----------------------------------------------------------------------------

local pools = {}
local function take(kind, make)
  local p = pools[kind]
  if not p then p = { list = {}, used = 0, make = make }; pools[kind] = p end
  p.used = p.used + 1
  local w = p.list[p.used]
  if not w then w = p.make(); p.list[p.used] = w end
  w:ClearAllPoints()
  w:Show()
  return w
end
local function releaseAll()
  for _, p in pairs(pools) do
    for i = 1, #p.list do p.list[i]:Hide() end
    p.used = 0
  end
  if lookupBox then lookupBox:Hide() end
end

local FONTS = { title = "GameFontNormalLarge", head = "GameFontNormal", body = "GameFontHighlight",
  small = "GameFontHighlightSmall", dim = "GameFontDisableSmall" }

-- Text at x, y (y grows down) in width w; returns its height.
local function text(s, x, y, w, kind, color, justify, wrap)
  local font = FONTS[kind] or FONTS.small
  local f = take("fs:" .. font, function() return body:CreateFontString(nil, "OVERLAY", font) end)
  f:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
  f:SetWidth(w or 0)
  f:SetJustifyH(justify or "LEFT")
  f:SetWordWrap(wrap and true or false)
  f:SetText(s or "")
  local c = color or ns.C.light
  f:SetTextColor(c[1], c[2], c[3], c[4] or 1)
  return wrap and math.max(12, tonumber(f:GetStringHeight()) or 12) or 14
end

local function rect(x, y, w, h, color, layer)
  local t = take("rect:" .. (layer or "BACKGROUND"), function() return body:CreateTexture(nil, layer or "BACKGROUND") end)
  t:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
  t:SetSize(math.max(1, w), math.max(1, h))
  t:SetColorTexture(ns.rgba(color))
  return t
end

-- A card: a filled box with a 1 px edge and a heading.
local function card(x, y, w, h, title, right)
  rect(x, y, w, h, ns.C.panel)
  local e = ns.C.edge
  local edge = { e[1], e[2], e[3], 0.55 }
  rect(x, y, w, 1, edge, "BORDER"); rect(x, y + h - 1, w, 1, edge, "BORDER")
  rect(x, y, 1, h, edge, "BORDER"); rect(x + w - 1, y, 1, h, edge, "BORDER")
  if title then
    text(title, x + 12, y + 10, w - 24, "head", ns.C.gold)
    if right then text(right, x + 12, y + 11, w - 24, "dim", ns.C.dim, "RIGHT") end
  end
end

local function icon(path, x, y, size)
  local t = take("icon", function() return body:CreateTexture(nil, "ARTWORK") end)
  t:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
  t:SetSize(size, size)
  ns.setIcon(t, path or "INV_Misc_QuestionMark")
  return t
end

-- A button: label, codexLabel (what tests and the controller name it), tooltip, enabled.
local function button(label, x, y, w, onClick, opts)
  opts = opts or {}
  local b = take("btn", function() return ns.art.button(body, 80, 22) end)
  b:SetSize(w, opts.h or 22)
  b:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
  b:SetLabel(label)
  b.codexLabel = opts.label or label
  b.tipTitle, b.tipText = opts.tip, opts.tipText
  b:SetEnabled(opts.enabled ~= false)
  if b.SetLook then b:SetLook(opts.lit and true or false) end
  b:SetScript("OnClick", function() onClick(); P.refresh() end)
  return b
end

-- A row of choices; returns the height used.
local function segments(x, y, w, labels, lit, onPick, prefix)
  local n = #labels
  local bw = math.floor((w - (n - 1) * 4) / n)
  for i, label in ipairs(labels) do
    local b = take("seg", function() return ns.art.segment(body) end)
    b:SetSize(bw, 22)
    b:SetPoint("TOPLEFT", body, "TOPLEFT", x + (i - 1) * (bw + 4), -y)
    b:SetLabel(label)
    b.codexLabel = (prefix or "") .. label
    b.codexOn = i == lit or nil
    b.tipTitle, b.tipText = nil, nil
    b:SetEnabled(true)
    b:SetLook(i == lit)
    b:SetScript("OnClick", function() onPick(i); P.refresh() end)
  end
  return 22
end

local function check(label, x, y, on, onClick, tip)
  local cb = take("check", function() return ns.art.check(body) end)
  cb:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
  cb:SetLabel(label)
  cb.codexLabel = label
  cb.tipTitle, cb.tipText = label, tip
  cb:SetLook(on)
  cb:SetScript("OnClick", function() onClick(); P.refresh() end)
  return 26
end

-- A bar: the share pct of w filled.
local function bar(x, y, w, h, pct, color)
  rect(x, y, w, h, { 0, 0, 0, 0.5 })
  if pct > 0 then rect(x, y, math.max(1, math.floor(w * math.min(1, pct))), h, color or ns.C.accent, "BORDER") end
end

-- A paged list: rows from offsets[key], as many as fit in height; returns the height used.
-- The mouse wheel scrolls the page's main list (the last one drawn with more rows than fit).
local function list(key, rows, x, y, w, rowH, height, draw)
  local fit = math.max(1, math.floor((height - 26) / rowH))
  if #rows <= math.floor(height / rowH) then fit = #rows end
  local first = math.max(0, math.min(offsets[key] or 0, math.max(0, #rows - fit)))
  offsets[key] = first
  for i = 1, fit do
    local r = rows[first + i]
    if not r then break end
    local ry = y + (i - 1) * rowH
    if i % 2 == 0 then rect(x, ry, w, rowH - 2, { 1, 1, 1, 0.03 }) end
    draw(r, x, ry, w, first + i)
  end
  local used = math.min(#rows, fit) * rowH
  if #rows > fit then
    wheelKey = key
    local py = y + fit * rowH + 2
    button("<", x, py, 26, function() offsets[key] = math.max(0, first - fit) end,
      { label = "Previous " .. key, enabled = first > 0 })
    button(">", x + 30, py, 26, function() offsets[key] = first + fit end,
      { label = "Next " .. key, enabled = first + fit < #rows })
    text((first + 1) .. "-" .. math.min(#rows, first + fit) .. " of " .. #rows .. "  (mouse wheel scrolls)", x + 64, py + 4, w - 64, "dim", ns.C.dim)
    used = used + 26
  end
  return used
end

local function wheel(delta)
  if not wheelKey then return end
  offsets[wheelKey] = math.max(0, (offsets[wheelKey] or 0) - delta * 3)
  P.refresh()
end

local function makePanel()
  panel = CreateFrame("Frame", "LevelingCodexAHPanel", root)
  panel:SetPoint("TOPLEFT", root, "TOPLEFT", 4, -24)
  panel:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -4, 26)
  panel:SetFrameLevel((tonumber((try(root.GetFrameLevel, root))) or 1) + 100)
  panel:EnableMouse(true)
  panel:EnableMouseWheel(true)
  panel:SetScript("OnMouseWheel", function(_, delta) wheel(delta) end)
  panel.base = panel:CreateTexture(nil, "BACKGROUND")
  panel.base:SetAllPoints()
  panel.base:SetColorTexture(0, 0, 0, 0.97)
  body = CreateFrame("Frame", nil, panel)
  body:SetAllPoints()
  body.tint = body:CreateTexture(nil, "BACKGROUND")
  body.tint:SetAllPoints()
  panel:Hide()
end

----------------------------------------------------------------------------
-- Pieces the pages share
----------------------------------------------------------------------------

local GREEN, RED, ORANGE = { 0.3, 0.9, 0.35 }, { 1, 0.38, 0.32 }, { 1, 0.6, 0.2 }

local function money(c) return ns.auction.coins(c) end

-- How old the last full scan is, and its colour.
local function scanAge()
  local at = tonumber(A().store().fullAt)
  if not at then return "never", RED end
  local s = now() - at
  return A().age(at), s < 3600 and GREEN or (s < 86400 and ns.C.gold or ORANGE)
end

local function itemIcon(id)
  local _, _, _, _, _, _, _, _, _, path = ns.itemInfo(id)
  return path or "INV_Misc_QuestionMark"
end

----------------------------------------------------------------------------
-- Overview
----------------------------------------------------------------------------

local pages = {}

function pages.overview(W, top, H)
  local lw = math.floor((W - 48) / 2)
  local lx, rx = 16, 16 + lw + 16
  local L = T().ledger()
  -- this visit
  local y = top
  card(lx, y, lw, 128, "THIS VISIT", "gold now " .. ns.money(tonumber(try(GetMoney)) or 0))
  local ly = y + 34
  local function line(label, value, color)
    text(label, lx + 14, ly, 150, "small", ns.C.dim)
    text(value, lx + 160, ly, lw - 174, "small", color or ns.C.light, "RIGHT")
    ly = ly + 18
  end
  line("Posted", L.posts .. (L.posts == 1 and " auction, " or " auctions, ") .. money(L.posted))
  line("Deposits paid", money(L.deposits))
  line("Bought", L.buys .. " for " .. money(L.spent))
  if ns.gold and ns.gold.fund then
    local f = ns.gold.fund()
    if f.have then
      line("Mount fund", ns.money(f.have) .. " of " .. ns.money(f.goal) .. " (" .. f.pct .. "%)", f.ready and GREEN)
      bar(lx + 14, ly + 2, lw - 28, 6, f.pct / 100, f.ready and GREEN or ns.C.accent)
    end
  end
  -- market data
  y = y + 140
  local age, ageColor = scanAge()
  card(lx, y, lw, 112, "MARKET DATA")
  text(ns.thousands(A().count()) .. " items priced on " .. Q.plain(GetRealmName and GetRealmName() or "this realm"), lx + 14, y + 34, lw - 28, "small")
  text("Full scan:", lx + 14, y + 52, 80, "small", ns.C.dim)
  text(age, lx + 90, y + 52, lw - 104, "small", ageColor)
  local ok, why = A().canFullScan()
  button(ok and "Scan all" or why, lx + 14, y + 76, math.floor((lw - 36) / 2), function() A().fullScan() end,
    { label = "Scan all", enabled = ok, tip = "Scan all", tipText = "Reads every listing at once. The auction house allows one every 15 minutes." })
  button("Scan my bags", lx + 22 + math.floor((lw - 36) / 2), y + 76, math.floor((lw - 36) / 2), function()
    ns.say("Searching " .. A().scanBags() .. " items from your bags.")
  end, { tip = "Scan my bags", tipText = "Searches each item you could sell whose price is older than 30 minutes." })
  -- opportunities
  y = top
  local deals = T().deals()
  local sells = T().sellable()
  local worth = 0
  for _, r in ipairs(sells) do if not r.sell.blocked then worth = worth + r.sell.price * r.count end end
  card(rx, y, lw, 128, "MONEY TO MAKE")
  local oy = y + 34
  if #deals > 0 then
    text(#deals .. (#deals == 1 and " deal" or " deals") .. ": best +" .. ns.money(deals[1].profit) .. " each on " .. Q.plain(deals[1].name),
      rx + 14, oy, lw - 120, "small", GREEN)
  else
    text("No deals in your prices yet.", rx + 14, oy, lw - 120, "small", ns.C.dim)
  end
  button("Deals", rx + lw - 100, oy - 4, 86, function() page = "deals" end, { label = "See deals" })
  oy = oy + 28
  if #sells > 0 then
    text(#sells .. (#sells == 1 and " item" or " items") .. " to sell, about " .. ns.money(worth), rx + 14, oy, lw - 120, "small")
  else
    text("Nothing priced to sell in your bags.", rx + 14, oy, lw - 120, "small", ns.C.dim)
  end
  button("Selling", rx + lw - 100, oy - 4, 86, function() page = "selling" end, { label = "See selling" })
  oy = oy + 28
  local mine, under = T().mine.list, T().undercutCount()
  if #mine > 0 then
    text(#mine .. " of yours listed" .. (under > 0 and (", " .. under .. " undercut") or ""), rx + 14, oy, lw - 120, "small", under > 0 and RED or ns.C.light)
  else
    text("You have nothing listed.", rx + 14, oy, lw - 120, "small", ns.C.dim)
  end
  button("Undercuts", rx + lw - 100, oy - 4, 86, function() page = "selling"; T().checkUndercuts() end,
    { label = "Check undercuts", enabled = #mine > 0 })
  -- for your guide
  y = y + 140
  local needs = A().pricedNeeds()
  local gh = H - (y - top)
  card(rx, y, lw, gh, "FOR YOUR GUIDE")
  local gy = y + 32
  if #needs == 0 then
    text("Your guide needs nothing from the auction house right now.", rx + 14, gy, lw - 28, "small", ns.C.dim, nil, true)
  else
    local total, unknown = 0, 0
    for i, w in ipairs(needs) do
      if gy + 32 > y + gh - 40 then break end
      icon(w.id and itemIcon(w.id) or "INV_Misc_Bag_10", rx + 14, gy, 22)
      text(Q.plain(w.need .. " x " .. w.name), rx + 42, gy, lw - 56, "small")
      text(Q.plain(A().rowPrice(w)), rx + 42, gy + 13, lw - 56, "dim", ns.C.dim)
      gy = gy + 30
    end
    for _, w in ipairs(needs) do
      local each = w.p and ((w.p.n > 0 and w.p.low) or w.p.usual)
      if each then total = total + each * w.need else unknown = unknown + 1 end
    end
    if total > 0 then
      text("About " .. ns.money(total) .. " in all" .. (unknown > 0 and (", " .. unknown .. " not priced yet") or ""), rx + 14, gy, lw - 28, "small", ns.C.gold)
      gy = gy + 18
    end
    local v1 = A().auctionator()
    if v1 and has(v1, "MultiSearch") then
      button("Search in Auctionator", rx + 14, gy, lw - 28, function()
        local names = {}
        for _, w in ipairs(needs) do names[#names + 1] = w.name end
        if A().searchAuctionator(names) then
          ns.say("Searching Auctionator for " .. #names .. (#names == 1 and " item" or " items") .. " your guide needs.")
        end
      end)
    else
      button("Search them now", rx + 14, gy, lw - 28, function()
        ns.say("Searching " .. A().scanNeeds() .. " items your guide needs.")
      end)
    end
  end
end

----------------------------------------------------------------------------
-- Deals
----------------------------------------------------------------------------

local KINDS = { { "All deals", nil }, { "Under vendor", "vendor" }, { "Flips", "flip" } }

function pages.deals(W, top, H)
  local x, w = 16, W - 32
  local db = ns.db()
  local lit = 1
  for i, k in ipairs(KINDS) do if k[2] == view.deals then lit = i end end
  local labels = {}
  for i, k in ipairs(KINDS) do labels[i] = k[1] end
  segments(x, top, 330, labels, lit, function(i) view.deals = KINDS[i][2]; offsets.deals = 0 end)
  local mins, minLit = {}, nil
  for i, e in ipairs(T().MINPROFITS) do mins[i] = e[1]; if e[2] == T().minProfit() then minLit = i end end
  text("Worth at least", x + 350, top + 4, 100, "small", ns.C.dim)
  segments(x + 450, top, w - 450, mins, minLit, function(i) db.auctionMinProfit = T().MINPROFITS[i][2] end, "At least ")
  local y = top + 30
  local flips, flipLit = {}, nil
  for i, e in ipairs(T().FLIPS) do flips[i] = e[1]; if e[2] == T().flipPct() then flipLit = i end end
  text("A flip is listed under its usual by", x, y + 4, 210, "small", ns.C.dim)
  segments(x + 214, y, 170, flips, flipLit, function(i) db.auctionFlipPct = T().FLIPS[i][2] end, "Flip at ")
  local rows = T().deals(view.deals, view.hidden)
  local profit = 0
  for _, d in ipairs(rows) do profit = profit + d.profit end
  text(#rows .. (#rows == 1 and " deal" or " deals") .. (#rows > 0 and (", about +" .. ns.money(profit) .. " buying one of each") or ""),
    x + 400, y + 4, w - 400, "small", #rows > 0 and GREEN or ns.C.dim, "RIGHT")
  y = y + 30
  text("Check searches the listings, Buy shows the total first, a commodity asks you to confirm. Profits count the 5% cut.",
    x, y, w, "dim", ns.C.dim)
  y = y + 20
  local bottom = top + H - 30
  if #rows == 0 then
    text("No deals in your prices yet. Scan all on the Scan page finds listings under vendor price and far under their usual price.",
      x, y + 6, w, "small", ns.C.dim, nil, true)
  else
    list("deals", rows, x, y, w, 40, bottom - y, function(d, rx, ry, rw)
      icon(itemIcon(d.id), rx + 6, ry + 5, 28)
      local name = Q.plain(d.name)
      text(name, rx + 42, ry + 5, 230, "body")
      local vendor = d.kind == "vendor"
      text(vendor and "UNDER VENDOR" or "FLIP", rx + 280, ry + 7, 110, "dim", vendor and GREEN or ns.C.accent)
      local sub = "Listed " .. ns.money(d.low) .. (vendor and ", vendor pays " or ", usual ") .. ns.money(d.worth)
        .. "  -  " .. (vendor and "+" or "about +") .. ns.money(d.profit) .. " each (" .. d.pct .. "%)" .. "  -  " .. ns.thousands(d.n) .. " listed"
      text(sub, rx + 42, ry + 21, rw - 270, "dim", ns.C.dim)
      local b = T().buying[d.id]
      button(T().dealLabel(d.id), rx + rw - 216, ry + 9, 150, function()
        local x2 = T().buying[d.id]
        if not x2 or x2.stage == "none" then T().check(d) else T().buy(d.id) end
      end, { label = "Deal " .. d.name, enabled = not b or b.stage == "ready" or b.stage == "confirm" or b.stage == "none",
        tip = d.name, tipText = "Check searches its listings; then Buy, and Confirm for a commodity." })
      local hidden = T().isHidden(d.id)
      button(hidden and "Unhide" or "Hide", rx + rw - 60, ry + 9, 56, function() T().hide(d.id, not hidden) end,
        { label = (hidden and "Unhide " or "Hide ") .. d.name, tip = "Hide", tipText = "Leave it out of Deals and Selling." })
    end)
  end
  local n = T().hiddenCount()
  if n > 0 or view.hidden then
    button(view.hidden and "Hide hidden" or ("Show hidden (" .. n .. ")"), x, bottom + 4, 160, function() view.hidden = not view.hidden end,
      { label = view.hidden and "Hide hidden" or "Show hidden" })
  end
end

----------------------------------------------------------------------------
-- Selling
----------------------------------------------------------------------------

local OWNED_STATES = { undercut = { "UNDERCUT", RED }, cheapest = { "CHEAPEST", GREEN }, sold = { "SOLD", { 1, 0.82, 0 } } }

function pages.selling(W, top, H)
  local db = ns.db()
  local rw = 290
  local lw = W - 48 - rw
  local x, rx = 16, 16 + lw + 16
  local bottom = top + H - 30
  -- settings
  local cuts, cutLit = {}, nil
  for i, e in ipairs(T().UNDERCUTS) do cuts[i] = e[1]; if e[2] == T().undercut()[2] then cutLit = i end end
  text("Undercut", x, top + 4, 60, "small", ns.C.dim)
  segments(x + 62, top, 200, cuts, cutLit, function(i) db.auctionUndercut = T().UNDERCUTS[i][2] end, "Undercut ")
  local durs, durLit = {}, nil
  for i, e in ipairs(T().DURATIONS) do durs[i] = e[1]; if e[2] == T().duration() then durLit = i end end
  text("Post for", x + 276, top + 4, 56, "small", ns.C.dim)
  segments(x + 334, top, lw - 334, durs, durLit, function(i) db.auctionDuration = T().DURATIONS[i][2] end, "Post for ")
  local y = top + 30
  local nextRow = T().nextPost()
  button(nextRow and ("Post next: " .. nextRow.count .. " x " .. Q.plain(nextRow.name) .. " at " .. ns.money(nextRow.sell.price))
    or "Nothing to post", x, y, lw, function() T().postNext() end,
    { label = "Post next", enabled = nextRow ~= nil and T().available(), h = 26, tip = "Post next",
      tipText = "Posts the most valuable item in the list. Click again for the next one." })
  y = y + 34
  local rows = T().sellable(false, view.hidden)
  if #rows == 0 then
    text("Nothing priced to sell in your bags. Scan my bags prices what you carry.", x, y + 4, lw, "small", ns.C.dim, nil, true)
  else
    list("selling", rows, x, y, lw, 44, bottom - y, function(row, ix, iy, iw)
      local s = row.sell
      icon(row.icon or itemIcon(row.id), ix + 6, iy + 6, 30)
      text(Q.plain(row.count .. " x " .. row.name), ix + 44, iy + 5, 170, "body")
      local _, label, color = T().status(row.id, s)
      text(label, ix + 216, iy + 7, iw - 216 - 176, "dim", color)
      local sub
      if s.blocked then sub = "A vendor pays " .. ns.money(s.vendor) .. " each: sell it there"
      else
        sub = ns.money(s.price) .. " each" .. (s.custom and " (your price)" or "")
        if s.low then sub = sub .. ", lowest " .. ns.money(s.low) end
        if s.usual and s.usual ~= s.low then sub = sub .. ", usual " .. ns.money(s.usual) end
        sub = sub .. "  -  " .. ns.money(s.price * row.count) .. " in all"
        if s.paid then sub = sub .. "  -  paid " .. ns.money(s.paid) end
      end
      text(sub, ix + 44, iy + 23, iw - 44 - 176, "dim", s.blocked and RED or (s.loss and ORANGE or ns.C.dim))
      local bx = ix + iw - 172
      if s.custom then
        button("Auto", bx - 46, iy + 11, 42, function() T().nudge(row.id, nil) end,
          { label = "Reset " .. row.name, tip = "Auto price", tipText = "Back to the undercut price." })
      end
      button("-", bx, iy + 11, 24, function() T().nudge(row.id, -1) end,
        { label = "Lower " .. row.name, enabled = not s.blocked, tip = "Lower the price", tipText = "5% less each click. It never goes under the vendor floor: below it the post is blocked." })
      button("+", bx + 26, iy + 11, 24, function() T().nudge(row.id, 1) end,
        { label = "Raise " .. row.name, enabled = not s.blocked, tip = "Raise the price", tipText = "5% more each click." })
      local armed = T().armed("post:" .. row.id)
      button(s.blocked and "Vendor it" or (armed and "Post anyway" or "Post"), bx + 54, iy + 11, 70, function() T().post(row) end,
        { label = "Post " .. row.name, enabled = not s.blocked and T().available(), lit = armed })
      local hidden = T().isHidden(row.id)
      button(hidden and "Unhide" or "Hide", bx + 126, iy + 11, 46, function() T().hide(row.id, not hidden) end,
        { label = (hidden and "Unhide " or "Hide ") .. row.name, tip = "Hide", tipText = "Leave it out of Selling and Deals." })
    end)
  end
  local n = T().hiddenCount()
  if n > 0 or view.hidden then
    button(view.hidden and "Hide hidden" or ("Show hidden (" .. n .. ")"), x, bottom + 4, 160, function() view.hidden = not view.hidden end,
      { label = view.hidden and "Hide hidden" or "Show hidden" })
  end
  local unpriced = #T().sellable(true, false) - #T().sellable(false, false)
  if unpriced > 0 then
    text(unpriced .. " more " .. (unpriced == 1 and "has" or "have") .. " no price yet", x + 170, bottom + 8, lw - 300, "dim", ns.C.dim)
    button("Scan my bags", x + lw - 120, bottom + 4, 120, function()
      ns.say("Searching " .. A().scanBags() .. " items from your bags.")
    end)
  end
  -- your auctions
  local mine = T().mine
  card(rx, top, rw, H, "YOUR AUCTIONS")
  button(mine.checking and "Checking..." or "Check undercuts", rx + 12, top + 32, 160, function() T().checkUndercuts() end,
    { label = "Check undercuts", enabled = not mine.checking and #mine.list > 0, tip = "Check undercuts",
      tipText = "Searches each item you have listed for the cheapest listing that isn't yours." })
  button("Refresh", rx + 178, top + 32, rw - 190, function() T().queryOwned() end)
  local under = T().undercutCount()
  text(#mine.list == 0 and (mine.at and "You have nothing listed." or "Reading your auctions...")
    or (#mine.list .. " listed" .. (under > 0 and (", " .. under .. " undercut") or "")), rx + 12, top + 62, rw - 24, "small",
    under > 0 and RED or ns.C.light)
  local oy = top + 82
  list("mine", mine.list, rx + 6, oy, rw - 12, 38, top + H - 46 - oy, function(row, ix, iy, iw)
    text(Q.plain(row.qty .. " x " .. row.name), ix + 6, iy + 4, iw - 80, "small")
    local state, cheapest = T().ownedState(row)
    local st = state and OWNED_STATES[state]
    local sub = row.unit and ("yours " .. ns.money(row.unit)) or ""
    if state == "undercut" or state == "cheapest" then sub = sub .. ", cheapest " .. ns.money(cheapest) end
    text(sub, ix + 6, iy + 19, iw - 140, "dim", ns.C.dim)
    if st then text(st[1], ix + iw - 140, iy + 19, 66, "dim", st[2], "RIGHT") end
    if not row.sold then
      local armed = T().armed("cancel:" .. row.auction)
      button(armed and "Sure?" or "Cancel", ix + iw - 66, iy + 8, 62, function() T().cancel(row) end,
        { label = "Cancel " .. row.name, lit = armed, tip = "Cancel", tipText = "Two clicks. The deposit is lost; the item comes back by mail." })
    end
  end)
  text("Cancelling loses the deposit; the item comes back by mail.", rx + 12, top + H - 22, rw - 24, "dim", ns.C.dim)
end

----------------------------------------------------------------------------
-- Scan
----------------------------------------------------------------------------

local function lookup(textIn)
  local id, name = A().find(textIn)
  view.lookup = { text = textIn, id = id, name = name or textIn }
end

local function makeLookupBox()
  local ok, eb = pcall(CreateFrame, "EditBox", "LevelingCodexAHLookup", body, "InputBoxTemplate")
  if not ok or not eb then eb = CreateFrame("EditBox", "LevelingCodexAHLookup", body) end
  eb:SetAutoFocus(false)
  eb:SetSize(200, 22)
  eb:SetScript("OnEnterPressed", function(self) lookup(self:GetText()); self:ClearFocus(); P.refresh() end)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  lookupBox = eb
  -- Shift-clicking an item while the box has focus puts it in the box (the game hands the link to
  -- chat; the Codex only reads it)
  local function took(link)
    if type(link) == "string" and lookupBox:IsVisible() and lookupBox:HasFocus() then
      lookupBox:SetText(link)
      lookup(link)
      lookupBox:ClearFocus()
      P.refresh()
    end
  end
  if type(hooksecurefunc) == "function" then
    if type(ChatEdit_InsertLink) == "function" then pcall(hooksecurefunc, "ChatEdit_InsertLink", took) end
    if type(ChatFrameUtil) == "table" and type(ChatFrameUtil.InsertLink) == "function" then
      pcall(hooksecurefunc, ChatFrameUtil, "InsertLink", took)
    end
  end
end

-- The item's days as bars, with the low and high marked.
local function chart(id, x, y, w, h)
  local hist = A().history(id)
  rect(x, y, w, h, { 0, 0, 0, 0.35 })
  if #hist < 1 then
    text("No days recorded yet.", x + 8, y + h / 2 - 6, w - 16, "dim", ns.C.dim)
    return
  end
  local lo, hi = math.huge, 0
  for _, d in ipairs(hist) do local v = d.med or d.low; lo, hi = math.min(lo, v), math.max(hi, v) end
  local n = #hist
  local slot = math.floor((w - 8) / math.max(n, 7))
  for i, d in ipairs(hist) do
    local v = d.med or d.low
    local bh = hi > lo and math.floor(6 + (h - 28) * (v - lo) / (hi - lo)) or math.floor((h - 20) / 2)
    local c = i == n and ns.C.gold or ns.C.accent
    rect(x + 4 + (i - 1) * slot + 1, y + h - 14 - bh, math.max(2, slot - 3), bh, { c[1], c[2], c[3], 0.9 }, "BORDER")
  end
  text("high " .. ns.money(hi), x + 6, y + 3, w - 12, "dim", ns.C.dim, "RIGHT")
  text(n .. (n == 1 and " day" or " days") .. ", low " .. ns.money(lo), x + 6, y + h - 13, w - 12, "dim", ns.C.dim)
end

function pages.scan(W, top, H)
  local db = ns.db()
  local lw = math.floor((W - 48) / 2)
  local lx, rx = 16, 16 + lw + 16
  -- full scan
  local age, ageColor = scanAge()
  card(lx, top, lw, 132, "FULL SCAN")
  text("Last full scan:", lx + 14, top + 34, 110, "small", ns.C.dim)
  text(age, lx + 124, top + 34, lw - 138, "small", ageColor)
  text(ns.thousands(A().count()) .. " items priced", lx + 14, top + 52, lw - 28, "small")
  local done, total = A().fullProgress()
  if done then
    bar(lx + 14, top + 72, lw - 28, 8, total and total > 0 and done / total or 0, ns.C.accent)
  end
  local ok, why = A().canFullScan()
  local label = done and (total and ("Scanning " .. ns.thousands(done) .. " of " .. ns.thousands(total)) or "Waiting for the auction house...")
    or (ok and "Scan all" or why)
  button(label, lx + 14, top + 90, lw - 28, function() A().fullScan() end,
    { label = "Scan all", enabled = ok, tip = "Scan all", tipText = "Reads every listing at once. The auction house allows one every 15 minutes." })
  -- quick searches
  local y = top + 144
  local waiting, running = A().queued()
  card(lx, y, lw, 132, "QUICK SEARCHES")
  text(running and ("Searching " .. Q.plain(running) .. ", " .. waiting .. " waiting") or (waiting > 0 and (waiting .. " waiting") or "Nothing waiting."),
    lx + 14, y + 34, lw - 28, "small", (running or waiting > 0) and ns.C.light or ns.C.dim)
  local half = math.floor((lw - 36) / 2)
  button("Scan my bags", lx + 14, y + 56, half, function() ns.say("Searching " .. A().scanBags() .. " items from your bags.") end,
    { tip = "Scan my bags", tipText = "Each item you could sell whose price is older than 30 minutes, one at a time." })
  button("Scan guide items", lx + 22 + half, y + 56, half, function() ns.say("Searching " .. A().scanNeeds() .. " items your guide needs.") end,
    { tip = "Scan guide items", tipText = "What your route and professions still need." })
  if waiting > 0 then button("Stop", lx + 14, y + 84, lw - 28, function() A().stopSearches() end, { label = "Stop searches" }) end
  if A().auctionator() then
    text("Auctionator is loaded: the Codex doesn't search by itself, only when you click.", lx + 14, y + 110, lw - 28, "dim", ns.C.dim)
  end
  -- settings
  y = y + 144
  card(lx, y, lw, H - (y - top), "SETTINGS")
  local sy = y + 32
  sy = sy + check("Price block on item tooltips", lx + 10, sy, not db.noPriceTooltip, function() db.noPriceTooltip = not db.noPriceTooltip end,
    "Lowest now, usual, trend, vendor price and a verdict. Hold Shift for more.")
  sy = sy + check("Search my guide's items when I open it", lx + 10, sy, not db.noAuctionSearch, function() db.noAuctionSearch = not db.noAuctionSearch end)
  if A().count() > 0 then
    local armed = forgetAt and now() - forgetAt < 5
    button(armed and "Click again to forget" or "Forget prices", lx + 14, sy + 4, 180, function()
      if forgetAt and now() - forgetAt < 5 then A().forget(); forgetAt = nil; view.lookup = nil else forgetAt = now() end
    end, { label = "Forget prices", tip = "Forget prices", tipText = "Forget this realm's price history." })
  end
  -- look up an item
  card(rx, top, lw, H, "LOOK UP AN ITEM")
  if not lookupBox then makeLookupBox() end
  lookupBox:ClearAllPoints()
  lookupBox:SetPoint("TOPLEFT", body, "TOPLEFT", rx + 18, -(top + 34))
  lookupBox:SetWidth(lw - 120)
  lookupBox:Show()
  button("Look up", rx + lw - 96, top + 34, 82, function() lookup(lookupBox:GetText()) end)
  text("Type a name or Shift-click an item.", rx + 14, top + 60, lw - 28, "dim", ns.C.dim)
  local v = view.lookup
  if not v then return end
  local ly = top + 82
  if not v.id or not A().price(v.id) then
    text("Not seen yet: " .. Q.plain(v.name or ""), rx + 14, ly, lw - 28, "small", ns.C.dim)
    button("Search it now", rx + 14, ly + 20, lw - 28, function()
      if A().searchNow(v.name) then ns.say("Searching " .. Q.plain(v.name) .. ".") end
    end, { enabled = A().isOpen() })
    return
  end
  local p = A().price(v.id)
  icon(itemIcon(v.id), rx + 14, ly, 32)
  text(Q.plain(p.name or v.name), rx + 54, ly, lw - 68, "body", ns.C.gold)
  text("seen " .. A().age(p.at) .. (p.source and (" (" .. p.source .. ")") or ""), rx + 54, ly + 17, lw - 68, "dim", ns.C.dim)
  ly = ly + 42
  local function row(label, value, color)
    text(label, rx + 14, ly, 130, "small", ns.C.dim)
    text(value, rx + 140, ly, lw - 154, "small", color or ns.C.light, "RIGHT")
    ly = ly + 17
  end
  row("Lowest now", p.n > 0 and p.low and money(p.low) or "none listed")
  if p.usual then row("Usual (" .. p.days .. (p.days == 1 and " day)" or " days)"), money(p.usual)) end
  if p.med or p.high then row("Median / high", ns.money(p.med or p.low or 0) .. " / " .. ns.money(p.high or p.low or 0)) end
  row("Listed", ns.thousands(p.n))
  local vendor = p.vendor or tonumber((select(11, ns.itemInfo(v.id))))
  if vendor and vendor > 0 then row("Vendor pays", money(vendor)) end
  if p.trend then
    row("Trend", math.abs(p.trend) <= 5 and "steady" or ((p.trend > 0 and "+" or "-") .. math.abs(p.trend) .. "%"),
      math.abs(p.trend) <= 5 and ns.C.dim or (p.trend > 0 and GREEN or RED))
  end
  local verdict, vc = A().verdict(p, vendor)
  if verdict then text(verdict, rx + 14, ly + 2, lw - 28, "small", vc); ly = ly + 20 end
  local ch = math.min(110, top + H - ly - 44)
  if ch > 40 then chart(v.id, rx + 14, ly + 4, lw - 28, ch); ly = ly + ch + 10 end
  button("Search it now", rx + 14, ly, lw - 28, function()
    if A().searchNow(p.name or v.name) then ns.say("Searching " .. Q.plain(p.name or v.name) .. ".") end
  end, { enabled = A().isOpen() })
end

----------------------------------------------------------------------------
-- Drawing, opening and closing
----------------------------------------------------------------------------

function P.refresh()
  if not P.shown() then return end
  releaseAll()
  wheelKey = nil
  local C = ns.C
  body.tint:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 0.92)
  local W = math.max(600, (tonumber((try(root.GetWidth, root))) or 800) - 8)
  local H = math.max(300, (tonumber((try(root.GetHeight, root))) or 538) - 50)
  -- header: the title, your gold, the pages
  icon(ns.ADDON_ICON, 16, 8, 22)
  text("LEVELING CODEX", 44, 11, 200, "title", C.gold)
  text(money(tonumber(try(GetMoney)) or 0), W - 316, 12, 300, "body", C.light, "RIGHT")
  local labels, lit = {}, 1
  for i, pg in ipairs(P.PAGES) do labels[i] = pg[2]; if pg[1] == page then lit = i end end
  segments(16, 36, 440, labels, lit, function(i) page = P.PAGES[i][1] end)
  local age, ageColor = scanAge()
  text("Full scan " .. age, W - 316, 41, 300, "dim", ageColor, "RIGHT")
  rect(16, 64, W - 32, 1, { C.edge[1], C.edge[2], C.edge[3], 0.4 }, "BORDER")
  local top = 74
  local draw = pages[page] or pages.overview
  local ok, err = pcall(draw, W, top, H - top - 4)
  if not ok then
    P.lastError = tostring(err)
    text("The Codex couldn't draw this page: " .. Q.plain(tostring(err)), 16, top, W - 32, "small", RED, nil, true)
  end
end

function P.open(name)
  if not root or not P.enabled() then return end
  if name then page = name end
  if not panel then makePanel() end
  panel:Show()
  if tab then tab:SetSelected(true) end
  local deselect = PanelTemplates_DeselectTab
  if type(deselect) == "function" and type(root.Tabs) == "table" then
    for _, b in ipairs(root.Tabs) do pcall(deselect, b) end
  end
  P.refresh()
end

function P.close(clicked)
  if panel and panel:IsShown() then panel:Hide() end
  if tab then tab:SetSelected(false) end
  local selectTab = PanelTemplates_SelectTab
  if clicked and type(selectTab) == "function" and type(root) == "table" and type(root.Tabs) == "table" then
    for _, b in ipairs(root.Tabs) do if b == clicked then pcall(selectTab, b) end end
  end
end

-- AUCTION_HOUSE_SHOW (Auction.lua): the tab, and the Codex tab again when it was open last time.
function P.onShow(r)
  root = r
  if type(root) ~= "table" then return end
  if not P.enabled() then
    if tab then tab:Hide() end
    P.close()
    return
  end
  if not tab then makeTab() end
  tab:Show()
  hookTabs()
  place()
  -- Auctionator and other add-ons add their tabs a moment later
  ns.after(1, function() if root and root:IsShown() and tab then hookTabs(); place() end end)
  picked = false
  if reopen then
    P.open()
    -- the auction house opens on Buy (SetDisplayMode) and may do it after this event
    ns.after(0.3, function()
      if reopen and not picked and root:IsShown() and not P.shown() then P.open() end
    end)
  else
    P.close()
  end
end

function P.onClose()
  reopen = panel ~= nil and panel:IsShown() and P.enabled()
  P.close()
end

function ns.auctionPanelDebugLines()
  return { "auction tab: " .. (tab and "made" or "not made") .. (P.shown() and (", showing " .. page) or "")
    .. (P.enabled() and "" or ", turned off") .. (reopen and ", reopens" or "")
    .. (P.lastError and (", last error: " .. Q.plain(P.lastError)) or "") }
end
