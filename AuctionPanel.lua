-- AuctionPanel.lua: the Codex tabs in the auction house's tab row (ns.auctionPanel, P).
-- Five tab buttons after the last tab hanging under the auction house (Blizzard's, Auctionator's):
-- Codex (the overview), Market (movers, hot items, charts, your trades), Deals, Quick Sell and Scan,
-- each showing its page on a panel over the auction house's content. The header carries the
-- page's quick refresh, Scan all and the ticker on every page.
-- Taint: the Codex never calls Blizzard's SetDisplayMode, never hides Blizzard's frames and never
-- joins its Tabs list. Clicking another tab (an OnClick hook) or the auction house changing mode
-- (hooksecurefunc on SetDisplayMode) hides the panel. Every post, purchase and cancel is one click
-- on a button here (AuctionTrade.lua); nothing runs by itself.
local _, ns = ...
local Q = ns.quests
local try = Q.try

local P = {}
ns.auctionPanel = P

P.PAGES = {
  { "overview", "Codex", "Your visit, market data and what your guide needs." },
  { "market", "Market", "Biggest movers, hot items, price charts and your wins and losses." },
  { "deals", "Deals", "Listings under vendor price or far under their usual price, and the deal sniper." },
  { "selling", "Quick Sell", "Post your bags at the right price, and watch your auctions for undercuts." },
  { "scan", "Scan", "Full and paged scans, quick searches, settings and item look-up." },
}
local page, reopen, picked = "overview", false, false
local root, panel, body, lookupBox
local tabs, ours = {}, {}
local placedAfter, shows = nil, 0 -- tabs[i] = the button for P.PAGES[i]; ours[button] = true
local hooked = {}
local offsets, wheelKey = {}, nil
local view = { deals = nil, hidden = false, lookup = nil, market = nil, marketMode = "movers" }
local ticker
local forgetAt
local GREEN, RED, ORANGE = { 0.3, 0.9, 0.35 }, { 1, 0.38, 0.32 }, { 1, 0.6, 0.2 }
local function M() return ns.auctionMarket end

local function has(t, name) return type(t) == "table" and type(t[name]) == "function" end
local function now() return tonumber(time and time()) or 0 end
local function A() return ns.auction end
local function T() return ns.auctionTrade end

function P.enabled() return not ns.db().noAuctionTabs end
function P.shown() return panel ~= nil and panel:IsShown() and root ~= nil and root:IsShown() and true or false end
function P.page() return page end

----------------------------------------------------------------------------
-- The tab button
----------------------------------------------------------------------------

-- Tab buttons hanging under the auction house: its Tabs list, named children with "Tab", and any
-- button in the row under it, however deep (Auctionator puts its tabs on a frame of its own, so
-- they were missed and drew over the Codex tabs).
local function inRow(r, b)
  local bottom = tonumber((try(r.GetBottom, r)))
  local t = has(b, "GetTop") and tonumber((try(b.GetTop, b)))
  if not (bottom and t) then return nil end
  return t >= bottom - 40 and t <= bottom + 12
end

local function tabsOf(r)
  local list, seen = {}, {}
  local function add(b)
    if type(b) == "table" and not ours[b] and not seen[b] and has(b, "IsShown") then seen[b] = true; list[#list + 1] = b end
  end
  if type(r.Tabs) == "table" then for _, b in ipairs(r.Tabs) do add(b) end end
  local function walk(f, depth)
    if not has(f, "GetChildren") or depth > 3 then return end
    for _, c in ipairs({ f:GetChildren() }) do
      if not ours[c] and c ~= panel then
        local name = has(c, "GetName") and c:GetName()
        local kind = has(c, "GetObjectType") and c:GetObjectType()
        local button = kind == "Button" or kind == "CheckButton"
        local named = type(name) == "string" and name:lower():find("tab", 1, true) and not name:find("^LevelingCodex")
        if button and ((depth == 1 and named) or inRow(r, c)) then add(c)
        elseif not button and has(c, "IsShown") and c:IsShown() then walk(c, depth + 1) end
      end
    end
  end
  walk(r, 1)
  return list
end

local function edges(b)
  local l = tonumber((try(b.GetLeft, b)))
  if not l then return end
  local r = has(b, "GetRight") and tonumber((try(b.GetRight, b)))
  return l, r or (l + (tonumber((try(b.GetWidth, b))) or 0))
end

-- Side tabs: with Auctionator's tabs the row is full, so the Codex tabs stand in a rail fixed to
-- the auction house's right edge (the dialog's gold border, its left edge over the window's), each
-- a full-width plate with an icon and its label; the open one lit with a gold bar. The bottom-tab
-- art (A.tab's) is faded out while they're side tabs and back when they return to the row.
local SIDE_ICONS = { overview = ns.ADDON_ICON, market = "INV_Scroll_03", deals = "INV_Misc_Coin_01",
  selling = "INV_Misc_Bag_10", scan = "INV_Misc_Spyglass_03" }
local SIDE_W, SIDE_H, SIDE_GAP, SIDE_PAD = 128, 28, 3, 13
local rail
local function sideParts(tab, i)
  if tab.side then return tab.side end
  local sd = {}
  sd.bg = tab:CreateTexture(nil, "BACKGROUND")
  sd.bg:SetAllPoints()
  sd.edge = tab:CreateTexture(nil, "BORDER")
  sd.edge:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
  sd.edge:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
  sd.edge:SetHeight(1)
  sd.bar = tab:CreateTexture(nil, "ARTWORK")
  sd.bar:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
  sd.bar:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
  sd.bar:SetWidth(3)
  sd.icon = tab:CreateTexture(nil, "ARTWORK")
  sd.icon:SetSize(18, 18)
  sd.icon:SetPoint("LEFT", tab, "LEFT", 8, 0)
  ns.setIcon(sd.icon, SIDE_ICONS[P.PAGES[i][1]] or ns.ADDON_ICON)
  sd.hl = tab:CreateTexture(nil, "HIGHLIGHT")
  sd.hl:SetAllPoints()
  sd.hl:SetColorTexture(1, 0.82, 0, 0.1)
  tab.side = sd
  return sd
end
local function sideStyle(tab, i, side, on)
  local own = {}
  if tab.side then for _, t in pairs(tab.side) do own[t] = true end end
  for _, r in ipairs(tab.artRegions or {}) do
    if has(r, "SetAlpha") then r:SetAlpha(side and 0 or 1) end
  end
  if not side then
    if tab.side then for _, t in pairs(tab.side) do t:Hide() end end
    return
  end
  local sd = sideParts(tab, i)
  for _, t in pairs(sd) do t:Show() end
  local C = ns.C
  sd.bg:SetColorTexture(on and 0.2 or 0.06, on and 0.16 or 0.05, on and 0.08 or 0.04, on and 0.95 or 0.9)
  sd.edge:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.25)
  sd.bar:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
  sd.bar:SetShown(on and true or false)
  sd.icon:SetDesaturated(not on)
  sd.icon:SetAlpha(on and 1 or 0.75)
  tab.label:ClearAllPoints()
  tab.label:SetPoint("LEFT", tab, "LEFT", 32, 0)
  if on then tab.label:SetTextColor(1, 1, 1) else tab.label:SetTextColor(1, 0.82, 0) end
end
local function makeRail()
  if rail then return rail end
  rail = ns.art.frame("Frame", "LevelingCodexAHTabRail", root)
  rail.fill = rail:CreateTexture(nil, "BACKGROUND")
  rail.fill:SetPoint("TOPLEFT", rail, "TOPLEFT", 4, -4)
  rail.fill:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", -4, 4)
  rail.fill:SetColorTexture(0.03, 0.03, 0.03, 0.96)
  rail.border = ns.art.backdrop(rail, "dialog", { 0, 0, 0, 0 }, { 1, 1, 1, 1 })
  if not rail.border then
    rail.edges = {}
    for k = 1, 4 do rail.edges[k] = rail:CreateTexture(nil, "BORDER") end
    rail.edges[1]:SetPoint("TOPLEFT"); rail.edges[1]:SetPoint("TOPRIGHT"); rail.edges[1]:SetHeight(2)
    rail.edges[2]:SetPoint("BOTTOMLEFT"); rail.edges[2]:SetPoint("BOTTOMRIGHT"); rail.edges[2]:SetHeight(2)
    rail.edges[3]:SetPoint("TOPRIGHT"); rail.edges[3]:SetPoint("BOTTOMRIGHT"); rail.edges[3]:SetWidth(2)
    rail.edges[4]:SetPoint("TOPLEFT"); rail.edges[4]:SetPoint("BOTTOMLEFT"); rail.edges[4]:SetWidth(2)
    for _, e in ipairs(rail.edges) do e:SetColorTexture(ns.C.gold[1], ns.C.gold[2], ns.C.gold[3], 0.8) end
  end
  return rail
end

-- The first Codex tab right of the rightmost shown tab, with the same gap as the two before it;
-- the others in a row after it.
local placedBelow -- true while the tabs sit in their own row under the others
local function place()
  local tab = tabs[1]
  if not tab or not root then return end
  -- only buttons in the row under the auction house (a stray "*Tab*" button elsewhere would
  -- carry the Codex tabs off with it)
  local shown, level = {}, 0
  for _, b in ipairs(tabsOf(root)) do
    local visible = has(b, "IsVisible") and b:IsVisible() or (not has(b, "IsVisible") and b:IsShown())
    if visible and inRow(root, b) ~= false then
      local l, r = edges(b)
      if l and r then shown[#shown + 1] = { b = b, l = l, r = r } end
      level = math.max(level, tonumber((try(b.GetFrameLevel, b))) or 0)
    end
  end
  table.sort(shown, function(a, b) return a.r < b.r end)
  placedAfter = shown[#shown] and shown[#shown].b or nil
  -- above every other tab, so nothing that lands on the row later can cover them
  for _, t in ipairs(tabs) do if has(t, "SetFrameLevel") then pcall(t.SetFrameLevel, t, level + 2) end end
  tab:ClearAllPoints()
  local last, prev = shown[#shown], shown[#shown - 1]
  -- a row too long to take them (Auctionator adds four tabs): a column on the auction house's
  -- right edge, up from its bottom right corner
  local width = 0
  for i, t in ipairs(tabs) do width = width + (tonumber((try(t.GetWidth, t))) or 90) - (i > 1 and 8 or 0) end
  local rootRight, rootBottom = tonumber((try(root.GetRight, root))), tonumber((try(root.GetBottom, root)))
  local rowBottom
  for _, e in ipairs(shown) do
    local b = tonumber((try(e.b.GetBottom, e.b)))
    if b then rowBottom = math.min(rowBottom or b, b) end
  end
  placedBelow = nil
  if last and rootRight and rootBottom and rowBottom and last.r + 10 + width > rootRight + 4 then
    -- a column up the auction house's right edge from its bottom corner, Codex on top
    placedBelow = true
    local n = #tabs
    local r = makeRail()
    r:ClearAllPoints()
    r:SetSize(SIDE_W + 2 * SIDE_PAD, n * SIDE_H + (n - 1) * SIDE_GAP + 2 * SIDE_PAD)
    r:SetPoint("BOTTOMLEFT", root, "BOTTOMRIGHT", -7, 0)
    pcall(r.SetFrameLevel, r, level + 1)
    r:Show()
    for i = 1, n do
      tabs[i]:ClearAllPoints()
      tabs[i]:SetSize(SIDE_W, SIDE_H)
      tabs[i]:SetPoint("TOPLEFT", r, "TOPLEFT", SIDE_PAD, -SIDE_PAD - (i - 1) * (SIDE_H + SIDE_GAP))
      sideStyle(tabs[i], i, true, tabs[i].lit)
    end
    return
  end
  if rail then rail:Hide() end
  for i, t in ipairs(tabs) do
    if t.side then
      t:SetSize(t.rowW or 90, 32)
      sideStyle(t, i, false)
      t:SetSelected(t.lit or false)
    end
  end
  if last then
    local gap = prev and math.max(-20, math.min(10, last.l - prev.r)) or 0
    tab:SetPoint("LEFT", last.b, "RIGHT", gap, 0)
  else
    tab:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 12, 2)
  end
  for i = 2, #tabs do
    tabs[i]:ClearAllPoints()
    tabs[i]:SetPoint("LEFT", tabs[i - 1], "RIGHT", -8, 0)
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

local function makeTabs()
  for i, pg in ipairs(P.PAGES) do
    local tab = ns.art.tab(root, pg[2])
    tab.codexLabel = pg[2]
    tab.tipTitle = i == 1 and "Leveling Codex" or ("Codex: " .. pg[2])
    tab.tipText = pg[3]
    tab:SetScript("OnClick", function() picked = true; P.open(pg[1]) end)
    if has(tab, "HookScript") then
      tab:HookScript("OnEnter", ns.art.showTip)
      tab:HookScript("OnLeave", ns.art.hideTip)
    end
    tab.artRegions = {}
    for _, r in ipairs({ tab:GetRegions() }) do
      if r ~= tab.label then tab.artRegions[#tab.artRegions + 1] = r end
    end
    tab.rowW = tonumber((try(tab.GetWidth, tab))) or 90
    tabs[i], ours[tab] = tab, true
  end
end

-- Lights the tab of the page showing (none when the panel is closed).
local function lightTabs(on)
  for i, tab in ipairs(tabs) do
    tab.lit = on and P.PAGES[i][1] == page or false
    tab:SetSelected(tab.lit)
    if placedBelow then sideStyle(tab, i, true, tab.lit) end
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

-- A line from x1, y1 to x2, y2 (y grows down): the client's Line where it has one, else dots.
local function seg(x1, y1, x2, y2, color, thick)
  local r, g, b, a = color[1], color[2], color[3], color[4] or 1
  if has(body, "CreateLine") then
    local l = take("line", function() return body:CreateLine(nil, "ARTWORK") end)
    l:SetStartPoint("TOPLEFT", body, x1, -y1)
    l:SetEndPoint("TOPLEFT", body, x2, -y2)
    l:SetThickness(thick or 2)
    l:SetColorTexture(r, g, b, a)
    return
  end
  local dx, dy = x2 - x1, y2 - y1
  local steps = math.max(1, math.floor(math.sqrt(dx * dx + dy * dy) / 2))
  for i = 0, steps do
    rect(math.floor(x1 + dx * i / steps), math.floor(y1 + dy * i / steps), thick or 2, thick or 2, { r, g, b, a }, "ARTWORK")
  end
end

-- An invisible button over x, y, w, h: a tooltip, and a click when onClick is given.
local function hit(x, y, w, h, title, tipText, onClick, label)
  local b = take("hit", function()
    local f = CreateFrame("Button", nil, body)
    f:SetScript("OnEnter", ns.art.showTip)
    f:SetScript("OnLeave", ns.art.hideTip)
    return f
  end)
  b:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
  b:SetSize(math.max(1, w), math.max(1, h))
  b:SetFrameLevel(body:GetFrameLevel() + 3)
  b.tipTitle, b.tipText, b.codexLabel = title, tipText, label
  b:SetScript("OnClick", onClick and function() onClick(); P.refresh() end or nil)
  return b
end

-- A tag: text on a faint plate of its colour, w wide (centred).
local function pill(s, x, y, w, color)
  local c = color or ns.C.accent
  rect(x, y, w, 16, { c[1], c[2], c[3], 0.16 }, "BORDER")
  rect(x, y, 2, 16, { c[1], c[2], c[3], 0.9 }, "ARTWORK")
  text(s, x + 3, y + 2, w - 4, "dim", c, "CENTER")
end

-- A line chart of points = { { v, label, sub } } (oldest first) in x, y, w, h.
-- opts: usual (a dashed line), mini (no labels, grid or hover), color, title (hover heading).
local function lineChart(points, x, y, w, h, opts)
  opts = opts or {}
  local n = #points
  if not opts.mini then rect(x, y, w, h, { 0, 0, 0, 0.35 }) end
  if n < 2 then
    if not opts.mini then text(opts.empty or (n == 1 and "One reading so far: scan again later to draw a line." or "No prices recorded yet."),
      x + 8, y + h / 2 - 6, w - 16, "dim", ns.C.dim, "CENTER") end
    return
  end
  local lo, hi = math.huge, 0
  for _, pt in ipairs(points) do lo, hi = math.min(lo, pt.v), math.max(hi, pt.v) end
  if opts.usual then lo, hi = math.min(lo, opts.usual), math.max(hi, opts.usual) end
  if hi == lo then hi, lo = hi + math.max(1, hi * 0.05), math.max(0, lo - math.max(1, lo * 0.05)) end
  local padL, padR, padT, padB = 4, opts.mini and 4 or 66, opts.mini and 2 or 10, opts.mini and 2 or 18
  local cw, chh = w - padL - padR, h - padT - padB
  local function px(i) return x + padL + math.floor(cw * (i - 1) / (n - 1) + 0.5) end
  local function py(v) return y + padT + math.floor(chh * (hi - v) / (hi - lo) + 0.5) end
  local up = points[n].v >= points[1].v
  local color = opts.color or (up and GREEN or RED)
  if not opts.mini then
    -- grid and price labels
    for k = 0, 3 do
      local gy = y + padT + math.floor(chh * k / 3 + 0.5)
      rect(x + padL, gy, cw, 1, { 1, 1, 1, 0.06 }, "BORDER")
      text(ns.money(math.floor(hi - (hi - lo) * k / 3 + 0.5)), x + w - padR + 6, gy - 6, padR - 8, "dim", ns.C.dim)
    end
    -- the area under the line
    local slot = math.max(1, math.floor(cw / (n - 1)))
    for i = 1, n do
      local top = py(points[i].v)
      local cx = px(i) - (i == 1 and 0 or math.floor(slot / 2))
      local cw2 = (i == 1 or i == n) and math.ceil(slot / 2) or slot
      rect(cx, top, math.max(1, cw2), y + padT + chh - top, { color[1], color[2], color[3], 0.10 }, "BORDER")
    end
  end
  if opts.usual then
    local uy = py(opts.usual)
    for dx = 0, cw - 6, 10 do rect(x + padL + dx, uy, 6, 1, { 1, 0.82, 0, opts.mini and 0.35 or 0.55 }, "ARTWORK") end
    if not opts.mini then text("usual", x + padL + 4, uy - 12, 60, "dim", ns.C.gold) end
  end
  for i = 2, n do seg(px(i - 1), py(points[i - 1].v), px(i), py(points[i].v), color, opts.mini and 1.5 or 2) end
  if opts.mini then return end
  for i = 1, n do
    local last = i == n
    local sz = last and 6 or 4
    rect(px(i) - sz / 2, py(points[i].v) - sz / 2, sz, sz, last and ns.C.gold or color, "OVERLAY")
    local slot = math.max(6, math.floor(cw / (n - 1)))
    hit(px(i) - slot / 2, y, slot, h, points[i].label, ns.money(points[i].v) .. (points[i].sub and ("\n" .. points[i].sub) or ""))
  end
  text(points[1].label or "", x + padL, y + h - 14, 120, "dim", ns.C.dim)
  text(points[n].label or "", x + w - padR - 124, y + h - 14, 120, "dim", ns.C.dim, "RIGHT")
end

-- An item's points for a chart: its days (two or more), else its readings since the first scan.
local function daysAgo(day)
  local d = math.floor(now() / 86400) - day
  return d <= 0 and "today" or (d == 1 and "yesterday" or (d .. " days ago"))
end
-- The chart's intervals, like a trading chart's: each point is the last price seen in that slice
-- of time (the newest slices, up to 30); 1d reads the daily history. Auto = days once there are
-- two, else every reading.
P.INTERVALS = { { "Auto" }, { "1m", 60 }, { "5m", 300 }, { "15m", 900 }, { "1h", 3600 }, { "12h", 43200 }, { "1d", 86400 } }
local function spanText(sec)
  if sec < 3600 then return math.floor(sec / 60 + 0.5) .. " min" end
  if sec < 86400 * 2 then return math.floor(sec / 3600 + 0.5) .. " h" end
  return math.floor(sec / 86400 + 0.5) .. " days"
end
local function chartPoints(id, interval)
  local hist, pts = A().history(id), {}
  if interval == 86400 or (not interval and #hist >= 2) then
    for _, d in ipairs(hist) do
      pts[#pts + 1] = { v = d.med or d.low, label = daysAgo(d.day),
        sub = d.low and d.med and d.low ~= d.med and ("lowest " .. ns.money(d.low)) or nil }
    end
    return pts, "days"
  end
  local ticks = A().ticks(id)
  -- the price on file now counts as the newest reading
  local it = A().store().items[id]
  local at, low = type(it) == "table" and tonumber(it.at), type(it) == "table" and tonumber(it.low)
  if at and low and (tonumber(it.n) or 0) > 0 and (#ticks == 0 or ticks[#ticks].t < at) then
    ticks[#ticks + 1] = { t = at, low = low, n = tonumber(it.n) or 0 }
  end
  if not interval then
    for _, t in ipairs(ticks) do
      pts[#pts + 1] = { v = t.low, label = A().age(t.t), sub = t.n and (ns.thousands(t.n) .. " listed") or nil }
    end
    return pts, "scans"
  end
  local nowB = math.floor(now() / interval)
  local byB = {}
  for _, t in ipairs(ticks) do
    local b = math.floor(t.t / interval)
    if nowB - b < 30 then byB[b] = t end -- the last reading in the slice is its price
  end
  for b = nowB - 29, nowB do
    local t = byB[b]
    if t then pts[#pts + 1] = { v = t.low, label = A().age(t.t), sub = t.n and (ns.thousands(t.n) .. " listed") or nil } end
  end
  return pts, "interval"
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
  -- the ticker: a market strip across the whole panel (edge to edge), the biggest moves scrolling
  -- past as icon, name, price, arrow and change; hovering it stops it, a click charts the item.
  -- Clipped where the client can clip a frame, else it stands still and shows what fits.
  ticker = CreateFrame("Frame", nil, body)
  ticker:SetHeight(24)
  ticker:SetFrameLevel(body:GetFrameLevel() + 2)
  ticker.base = ticker:CreateTexture(nil, "BACKGROUND")
  ticker.base:SetAllPoints()
  ticker.base:SetColorTexture(0.02, 0.02, 0.03, 0.92)
  ticker.lineT = ticker:CreateTexture(nil, "BORDER")
  ticker.lineT:SetPoint("TOPLEFT", ticker, "TOPLEFT", 0, 0)
  ticker.lineT:SetPoint("TOPRIGHT", ticker, "TOPRIGHT", 0, 0)
  ticker.lineT:SetHeight(1)
  ticker.lineB = ticker:CreateTexture(nil, "BORDER")
  ticker.lineB:SetPoint("BOTTOMLEFT", ticker, "BOTTOMLEFT", 0, 0)
  ticker.lineB:SetPoint("BOTTOMRIGHT", ticker, "BOTTOMRIGHT", 0, 0)
  ticker.lineB:SetHeight(1)
  ticker.plate = ticker:CreateTexture(nil, "BORDER")
  ticker.plate:SetPoint("TOPLEFT", ticker, "TOPLEFT", 0, -1)
  ticker.plate:SetPoint("BOTTOMLEFT", ticker, "BOTTOMLEFT", 0, 1)
  ticker.plate:SetWidth(84)
  ticker.plateEdge = ticker:CreateTexture(nil, "ARTWORK")
  ticker.plateEdge:SetPoint("TOPLEFT", ticker, "TOPLEFT", 84, -1)
  ticker.plateEdge:SetPoint("BOTTOMLEFT", ticker, "BOTTOMLEFT", 84, 1)
  ticker.plateEdge:SetWidth(2)
  ticker.dot = ticker:CreateTexture(nil, "OVERLAY")
  ticker.dot:SetSize(7, 7)
  ticker.dot:SetPoint("LEFT", ticker, "LEFT", 9, 0)
  ticker.label = ticker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ticker.label:SetPoint("LEFT", ticker, "LEFT", 21, 0)
  ticker.label:SetText("MARKET")
  ticker.strip = CreateFrame("Frame", nil, ticker)
  ticker.strip:SetPoint("TOPLEFT", ticker, "TOPLEFT", 90, -1)
  ticker.strip:SetPoint("BOTTOMRIGHT", ticker, "BOTTOMRIGHT", -2, 1)
  if has(ticker.strip, "SetClipsChildren") and pcall(ticker.strip.SetClipsChildren, ticker.strip, true) then ticker.clips = true end
  ticker.empty = ticker.strip:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ticker.empty:SetPoint("LEFT", ticker.strip, "LEFT", 6, 0)
  ticker.empty:SetWordWrap(false)
  ticker.tracks = {}
  for i = 1, 2 do
    local t = CreateFrame("Frame", nil, ticker.strip)
    t:SetHeight(22)
    t.items = {}
    ticker.tracks[i] = t
  end
  ticker.off = 0
  ticker:SetScript("OnUpdate", function(self, elapsed)
    local tnow = tonumber(GetTime and GetTime()) or 0
    -- the live dot breathes (drawn from the clock, never a looping animation)
    if self.live then
      self.dot:SetAlpha(0.45 + 0.55 * (0.5 + 0.5 * math.cos(tnow * 3)))
    else
      self.dot:SetAlpha(0.6)
    end
    if not self.wide or not self.clips then return end
    local over = false
    if self.strip.IsMouseOver then
      local ok, r = pcall(self.strip.IsMouseOver, self.strip)
      over = ok and r and true or false
    end
    self.paused = over
    if over then return end
    self.off = ((self.off or 0) + (tonumber(elapsed) or 0) * 34) % self.wide
    local a, b = self.tracks[1], self.tracks[2]
    a:ClearAllPoints(); a:SetPoint("LEFT", self.strip, "LEFT", -self.off, 0)
    b:ClearAllPoints(); b:SetPoint("LEFT", self.strip, "LEFT", self.wide - self.off, 0)
  end)
  panel:Hide()
end

----------------------------------------------------------------------------
-- Pieces the pages share
----------------------------------------------------------------------------


local function money(c) return ns.auction.coins(c) end

-- How old the last scan (instant or paged) is, and its colour.
local function scanAge()
  local at = A().lastScanAt()
  if not at then return "never", RED end
  local s = now() - at
  return A().age(at), s < 3600 and GREEN or (s < 86400 and ns.C.gold or ORANGE)
end

-- The Scan all button: the instant scan when the server allows one, else the paged scan.
local function scanAllButton(label, x, y, w)
  local ok, how, why = A().canScanAll()
  local tipText = how == "paged"
    and ("The instant scan is cooling down (" .. tostring(why or "") .. "). This reads the auction house page by page instead: no cooldown, a little slower.")
    or "Reads every listing at once. The server allows that once every 15 minutes; in between, Scan all reads page by page."
  if not label then label = ok and (how == "paged" and "Scan all (paged)" or "Scan all") or why end
  button(label, x, y, w, function() A().scanAll() end, { label = "Scan all", enabled = ok, tip = "Scan all", tipText = tipText })
end

local function itemIcon(id)
  return A().iconOf(id) or "INV_Misc_QuestionMark"
end

----------------------------------------------------------------------------
-- Overview
----------------------------------------------------------------------------

local pages = {}

local function signed(c)
  c = math.floor(tonumber(c) or 0)
  return (c < 0 and "-" or "+") .. ns.money(math.abs(c))
end

-- Opens the Market page with an item charted.
local function chartItem(id, mode)
  view.market = id
  if mode then view.marketMode = mode end
  P.open("market")
end

-- A mover's tooltip: now, usual, the change and its basis, supply, the signal.
local function moverTip(r)
  local lines = { "Now " .. ns.money(r.last) .. (r.usual and (", usual " .. ns.money(r.usual)) or "") }
  if r.trend then lines[#lines + 1] = "Against earlier days: " .. M().pctText(r.trend) end
  if r.move then lines[#lines + 1] = "Since the reading " .. A().age(now() - (r.moveAge or 0)):gsub(" ago$", "") .. " before: " .. M().pctText(r.move) end
  lines[#lines + 1] = ns.thousands(r.n) .. " listed" .. (r.supply and (" (" .. M().pctText(r.supply) .. ")") or "")
  local sig = M().SIGNALS[r.signal]
  if sig then lines[#lines + 1] = sig[1] .. ": " .. sig[3] end
  lines[#lines + 1] = "Click to chart it."
  return table.concat(lines, "\n")
end

-- One mover: icon, name, a little line, the price and the change as a tag (22 px).
local function moverRow(r, x, y, w, opts)
  opts = opts or {}
  local sel = view.market == r.id and P.page() == "market"
  if sel then rect(x, y, w, 21, { ns.C.accent[1], ns.C.accent[2], ns.C.accent[3], 0.14 }, "BORDER") end
  icon(itemIcon(r.id), x + 4, y + 3, 16)
  local right = opts.compact and 56 or 196
  text(Q.plain(r.name), x + 24, y + 4, w - 24 - right, "small", sel and ns.C.gold or ns.C.light)
  if not opts.compact then
    lineChart((chartPoints(r.id)), x + w - 190, y + 3, 58, 15, { mini = true })
    text(ns.money(r.last), x + w - 126, y + 4, 70, "small", ns.C.light, "RIGHT")
  end
  if opts.tag then
    local sig = M().SIGNALS[r.signal] or M().SIGNALS.new
    pill(sig[1], x + w - 52, y + 3, 50, sig[2])
  else
    pill(M().pctText(r.change), x + w - 52, y + 3, 50, M().pctColor(r.change))
  end
  hit(x, y, w, 21, r.name, moverTip(r), function() chartItem(r.id) end, "Chart " .. r.name)
end

function pages.overview(W, top, H)
  local lw = math.floor((W - 48) / 2)
  local lx, rx = 16, 16 + lw + 16
  local L = T().ledger()
  -- this visit
  local y = top
  card(lx, y, lw, 112, "THIS VISIT", "gold now " .. ns.money(tonumber(try(GetMoney)) or 0))
  local ly = y + 32
  local function line(label, value, color)
    text(label, lx + 14, ly, 150, "small", ns.C.dim)
    text(value, lx + 160, ly, lw - 174, "small", color or ns.C.light, "RIGHT")
    ly = ly + 17
  end
  line("Posted", L.posts .. (L.posts == 1 and " auction, " or " auctions, ") .. money(L.posted))
  line("Deposits paid", money(L.deposits))
  line("Bought", L.buys .. " for " .. money(L.spent))
  if ns.gold and ns.gold.fund then
    local f = ns.gold.fund()
    if f.have then
      line("Mount fund", ns.money(f.have) .. " of " .. ns.money(f.goal) .. " (" .. f.pct .. "%)", f.ready and GREEN)
      bar(lx + 14, ly + 1, lw - 28, 5, f.pct / 100, f.ready and GREEN or ns.C.accent)
    end
  end
  -- market data
  y = y + 124
  local age, ageColor = scanAge()
  card(lx, y, lw, 96, "MARKET DATA")
  text(ns.thousands(A().count()) .. " items priced on " .. Q.plain(GetRealmName and GetRealmName() or "this realm"), lx + 14, y + 32, lw - 28, "small")
  text("Last scan:", lx + 14, y + 49, 80, "small", ns.C.dim)
  text(age, lx + 90, y + 49, lw - 104, "small", ageColor)
  scanAllButton(nil, lx + 14, y + 68, math.floor((lw - 36) / 2))
  button("Scan my bags", lx + 22 + math.floor((lw - 36) / 2), y + 68, math.floor((lw - 36) / 2), function()
    ns.say("Searching " .. A().scanBags() .. " items from your bags.")
  end, { tip = "Scan my bags", tipText = "Searches each item you could sell whose price is older than 30 minutes." })
  -- your trades
  y = y + 108
  local rec = M().record()
  local th = top + H - y
  card(lx, y, lw, th, "YOUR TRADES", "kept between visits")
  button("See trades", lx + lw - 104, y + 6, 92, function() view.marketMode = "trades"; P.open("market") end, { label = "See trades" })
  local ty = y + 34
  if #T().notes().log == 0 then
    text("Buys from Deals, posts from Quick Sell and every sale the game reports are kept here, with your wins and losses.",
      lx + 14, ty, lw - 28, "small", ns.C.dim, nil, true)
  else
    local third = math.floor((lw - 28) / 3)
    local function stat(i, label, value, color)
      text(label, lx + 14 + (i - 1) * third, ty, third - 6, "dim", ns.C.dim)
      text(value, lx + 14 + (i - 1) * third, ty + 13, third - 6, "body", color or ns.C.light)
    end
    stat(1, "Net", signed(rec.net), rec.net >= 0 and GREEN or RED)
    stat(2, "Flips won", rec.winRate and (rec.winRate .. "%  (" .. rec.wins .. " of " .. (rec.wins + rec.losses) .. ")") or "none sold yet")
    stat(3, "Still holding", #rec.holdings > 0 and signed(rec.unrealized) or "nothing", rec.unrealized >= 0 and GREEN or RED)
    if rec.best and ty + 40 < y + th - 8 then
      text("Best flip: " .. Q.plain(rec.best.name) .. " " .. signed(rec.best.profit), lx + 14, ty + 36, lw - 28, "dim", GREEN)
    end
  end
  -- money to make
  y = top
  local deals = T().deals()
  local sells = T().sellable()
  local worth = 0
  for _, r in ipairs(sells) do if not r.sell.blocked then worth = worth + r.sell.price * r.count end end
  card(rx, y, lw, 112, "MONEY TO MAKE")
  local oy = y + 32
  if #deals > 0 then
    text(#deals .. (#deals == 1 and " deal" or " deals") .. ": best +" .. ns.money(deals[1].profit) .. " each on " .. Q.plain(deals[1].name),
      rx + 14, oy, lw - 120, "small", GREEN)
  else
    text("No deals in your prices yet.", rx + 14, oy, lw - 120, "small", ns.C.dim)
  end
  button("Deals", rx + lw - 100, oy - 4, 86, function() P.open("deals") end, { label = "See deals" })
  oy = oy + 26
  if #sells > 0 then
    text(#sells .. (#sells == 1 and " item" or " items") .. " to sell, about " .. ns.money(worth), rx + 14, oy, lw - 120, "small")
  else
    text("Nothing priced to sell in your bags.", rx + 14, oy, lw - 120, "small", ns.C.dim)
  end
  button("Quick Sell", rx + lw - 100, oy - 4, 86, function() P.open("selling") end, { label = "See selling" })
  oy = oy + 26
  local mine, under = T().mine.list, T().undercutCount()
  if #mine > 0 then
    text(#mine .. " of yours listed" .. (under > 0 and (", " .. under .. " undercut") or ""), rx + 14, oy, lw - 120, "small", under > 0 and RED or ns.C.light)
  else
    text("You have nothing listed.", rx + 14, oy, lw - 120, "small", ns.C.dim)
  end
  button("Undercuts", rx + lw - 100, oy - 4, 86, function() P.open("selling"); T().checkUndercuts() end,
    { label = "Check undercuts", enabled = #mine > 0 })
  -- market movers
  y = y + 124
  card(rx, y, lw, 112, "MARKET MOVERS")
  button("Market", rx + lw - 100, y + 6, 86, function() view.marketMode = "movers"; P.open("market") end, { label = "See market" })
  local half = math.floor((lw - 34) / 2)
  local ups, downs = M().gainers(4), M().losers(4)
  if #ups == 0 and #downs == 0 then
    text("Nothing moving yet: a price moves here once it has been scanned twice. Scan all, and again later.",
      rx + 14, y + 34, lw - 28, "small", ns.C.dim, nil, true)
  else
    text("UP", rx + 14, y + 30, half, "dim", GREEN)
    text("DOWN", rx + 20 + half, y + 30, half, "dim", RED)
    for i, r in ipairs(ups) do moverRow(r, rx + 10, y + 42 + (i - 1) * 17 - 2, half, { compact = true }) end
    for i, r in ipairs(downs) do moverRow(r, rx + 20 + half, y + 42 + (i - 1) * 17 - 2, half, { compact = true }) end
  end
  -- for your guide
  y = y + 124
  local needs = A().pricedNeeds()
  local gh = top + H - y
  card(rx, y, lw, gh, "FOR YOUR GUIDE")
  local gy = y + 30
  if #needs == 0 then
    text("Your guide needs nothing from the auction house right now.", rx + 14, gy, lw - 28, "small", ns.C.dim, nil, true)
  else
    local total, unknown = 0, 0
    for _, w in ipairs(needs) do
      local each = w.p and ((w.p.n > 0 and w.p.low) or w.p.usual)
      if each then total = total + each * w.need else unknown = unknown + 1 end
    end
    local room = gh - 30 - 50
    for _, w in ipairs(needs) do
      if gy + 26 > y + 30 + room then break end
      icon(w.id and itemIcon(w.id) or "INV_Misc_Bag_10", rx + 14, gy, 20)
      text(Q.plain(w.need .. " x " .. w.name), rx + 40, gy, lw - 54, "small")
      text(Q.plain(A().rowPrice(w)), rx + 40, gy + 12, lw - 54, "dim", ns.C.dim)
      gy = gy + 26
    end
    if total > 0 then
      text("About " .. ns.money(total) .. " in all" .. (unknown > 0 and (", " .. unknown .. " not priced yet") or ""), rx + 14, gy, lw - 28, "small", ns.C.gold)
      gy = gy + 16
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
-- Market
----------------------------------------------------------------------------

local MARKET_VIEWS = { { "movers", "Movers" }, { "hot", "Hot and signals" }, { "trades", "Your trades" } }

-- The chart card: the item, its signal, a line of its days (or readings), and its numbers.
local function chartCard(x, y, w, h, id)
  card(x, y, w, h, "PRICE CHART")
  if not id then
    text("Click an item on the left to chart it.", x + 14, y + 36, w - 28, "small", ns.C.dim, nil, true)
    return
  end
  local p = A().price(id)
  local r = M().row(id)
  icon(itemIcon(id), x + 14, y + 30, 28)
  local name = (p and p.name) or A().nameOf(id) or (r and r.name) or ("item " .. id)
  text(Q.plain(name), x + 50, y + 30, w - 150, "body", ns.C.gold)
  local sig = M().SIGNALS[r and r.signal or "new"]
  pill(sig[1], x + w - 92, y + 30, 78, sig[2])
  hit(x + w - 92, y + 30, 78, 16, sig[1], sig[3])
  local now1 = r and r.last or (p and p.low)
  text((now1 and ("Now " .. ns.money(now1)) or "None listed") .. (p and p.usual and ("  -  usual " .. ns.money(p.usual)) or "")
    .. (p and ("  -  " .. ns.thousands(p.n) .. " listed") or ""), x + 50, y + 46, w - 64, "dim", ns.C.dim)
  -- the interval, like a trading chart's
  local labels, lit, sec = {}, 1, nil
  for k, e in ipairs(P.INTERVALS) do labels[k] = e[1]; if e[2] == view.interval then lit = k end end
  sec = view.interval
  segments(x + 12, y + 64, w - 24, labels, lit, function(k) view.interval = P.INTERVALS[k][2] end, "Interval ")
  local pts, kind = chartPoints(id, sec)
  local ch = math.max(60, h - 94 - 104)
  local empty = sec and sec < 86400 and ("Fewer than two prices in the last " .. spanText(sec * 30)
    .. ": Search it now, again a little later, or pick a longer interval.") or nil
  lineChart(pts, x + 12, y + 94, w - 24, ch, { usual = p and p.days and p.days >= 2 and p.usual or nil, empty = empty })
  local sy = y + 94 + ch + 8
  local col = math.floor((w - 28) / 2)
  local i = 0
  local function stat(label, value, color)
    local cx = x + 14 + (i % 2) * col
    local cy = sy + math.floor(i / 2) * 16
    text(label, cx, cy, 86, "dim", ns.C.dim)
    text(value, cx + 86, cy, col - 90, "small", color or ns.C.light)
    i = i + 1
  end
  local lo, hi
  for _, pt in ipairs(pts) do lo, hi = math.min(lo or pt.v, pt.v), math.max(hi or pt.v, pt.v) end
  stat("Against days", r and r.trend and M().pctText(r.trend) or "--", M().pctColor(r and r.trend))
  -- "Since last look" and "Listed" compare the last two readings (a search or a scan each);
  -- "Swings" is how far the daily prices spread, from two days of prices on
  stat("Since last look", r and r.move and M().pctText(r.move) or "needs 2 looks", r and r.move and M().pctColor(r.move) or ns.C.dim)
  local listed = r and r.wasN and ((r.wasN .. " -> " .. (r.n or 0)) .. (r.supply and r.supply ~= 0 and (" (" .. M().pctText(r.supply) .. ")") or ""))
    or (p and p.n and (p.n .. " now")) or "--"
  stat("Listed", listed, r and r.supply and (r.supply <= -10 and ORANGE or ns.C.light))
  stat("Swings", r and r.vol and (math.floor(r.vol * 100 + 0.5) .. "%") or "needs 2 days", r and r.vol and (r.vol >= 0.25 and ns.C.accent or ns.C.light) or ns.C.dim)
  stat(kind == "days" and "Range (days)" or (kind == "interval" and ("Range (" .. spanText(sec * 30) .. ")")) or "Range (scans)",
    lo and (ns.money(lo) .. " - " .. ns.money(hi)) or "--")
  local vendor = p and p.vendor
  stat("Vendor pays", vendor and vendor > 0 and ns.money(vendor) or "--")
  local by = sy + 3 * 16 + 4
  local bw = math.floor((w - 32) / 2)
  button("Search it now", x + 12, by, bw, function()
    if A().searchNow(name) then ns.say("Searching " .. Q.plain(name) .. ".") end
  end, { label = "Search " .. name, enabled = A().isOpen(), tip = "Search it now", tipText = "A fresh price, added to its line." })
  local deal
  for _, d in ipairs(T().deals()) do if d.id == id then deal = d end end
  local mineHas = false
  for _, row in ipairs(T().sellable()) do if row.id == id then mineHas = true end end
  if deal then
    button("Deal: +" .. ns.money(deal.profit) .. " each", x + 20 + bw, by, bw, function() P.open("deals") end, { label = "See deal " .. name })
  elseif mineHas then
    button("Sell yours", x + 20 + bw, by, bw, function() P.open("selling") end, { label = "Sell " .. name })
  end
end

-- A card listing rows of movers, paged by key.
local function moverCard(key, title, sub, rows, x, y, w, h, opts)
  card(x, y, w, h, title, sub)
  if #rows == 0 then
    text(opts and opts.empty or "Nothing yet.", x + 14, y + 34, w - 28, "small", ns.C.dim, nil, true)
    return
  end
  list(key, rows, x + 6, y + 30, w - 12, 22, h - 36, function(r, rx2, ry, rw) moverRow(r, rx2, ry, rw, opts) end)
end

local function tile(x, y, w, h, label, value, sub, color)
  rect(x, y, w, h, ns.C.panel)
  rect(x, y, 2, h, { (color or ns.C.accent)[1], (color or ns.C.accent)[2], (color or ns.C.accent)[3], 0.9 }, "BORDER")
  text(label, x + 10, y + 6, w - 16, "dim", ns.C.dim)
  text(value, x + 10, y + 20, w - 16, "title", color or ns.C.light)
  if sub then text(sub, x + 10, y + h - 15, w - 16, "dim", ns.C.dim) end
end

local KIND_TAGS = { buy = { "BOUGHT", { 0.35, 0.8, 0.85 } }, post = { "POSTED", { 0.85, 0.85, 0.85 } }, sold = { "SOLD", GREEN },
  expired = { "EXPIRED", ORANGE }, cancel = { "CANCELLED", RED } }

local function tradesView(W, y, bottom)
  local rec = M().record()
  local x, w = 16, W - 32
  local tw = math.floor((w - 24) / 4)
  local closed = rec.wins + rec.losses
  tile(x, y, tw, 52, "NET PROFIT", signed(rec.net), "flips, sales and lost deposits", rec.net >= 0 and GREEN or RED)
  tile(x + (tw + 8), y, tw, 52, "FLIPS WON", rec.winRate and (rec.winRate .. "%") or "--",
    closed > 0 and (rec.wins .. " won, " .. rec.losses .. " lost") or "no flip sold yet", rec.winRate and (rec.winRate >= 50 and GREEN or RED))
  tile(x + 2 * (tw + 8), y, tw, 52, "STILL HOLDING", #rec.holdings > 0 and signed(rec.unrealized) or "--",
    #rec.holdings .. (#rec.holdings == 1 and " item if sold now" or " items if sold now"), rec.unrealized >= 0 and GREEN or RED)
  tile(x + 3 * (tw + 8), y, tw, 52, "DEPOSITS LOST", ns.money(rec.lost), rec.sales .. (rec.sales == 1 and " sale" or " sales") .. " in all", rec.lost > 0 and ORANGE)
  y = y + 62
  -- profit over time
  local pts, run = {}, 0
  for i = #rec.flips, 1, -1 do
    local f = rec.flips[i]
    run = run + f.profit
    pts[#pts + 1] = { v = run, label = A().age(f.t), sub = Q.plain(f.name) .. " " .. signed(f.profit) }
  end
  local chh = 84
  card(x, y, w, chh + 34, "PROFIT FROM FLIPS", rec.best and ("best " .. Q.plain(rec.best.name) .. " " .. signed(rec.best.profit)) or nil)
  if #pts >= 2 then
    local base = 0
    for _, pt in ipairs(pts) do base = math.min(base, pt.v) end
    local shifted = {}
    for i, pt in ipairs(pts) do shifted[i] = { v = pt.v - base, label = pt.label, sub = pt.sub } end
    lineChart(shifted, x + 12, y + 28, w - 24, chh, { color = run >= 0 and GREEN or RED })
  else
    text("Buy a deal and sell it again: each flip adds a point here, the line climbing with every win.",
      x + 14, y + 36, w - 28, "small", ns.C.dim, nil, true)
  end
  y = y + chh + 44
  local hw = math.floor((w - 16) / 2)
  local h = bottom - y
  card(x, y, hw, h, "HOLDINGS", "bought, not sold yet")
  if #rec.holdings == 0 then
    text("Nothing the Codex bought is waiting to sell.", x + 14, y + 34, hw - 28, "small", ns.C.dim, nil, true)
  else
    list("holdings", rec.holdings, x + 6, y + 30, hw - 12, 30, h - 36, function(hd, ix, iy, iw)
      icon(itemIcon(hd.id), ix + 4, iy + 4, 20)
      text(Q.plain(hd.qty .. " x " .. hd.name), ix + 30, iy + 2, iw - 130, "small")
      text("paid " .. ns.money(hd.each) .. (hd.worth and (", worth " .. ns.money(hd.worth)) or ""), ix + 30, iy + 15, iw - 130, "dim", ns.C.dim)
      text(hd.pnl and signed(hd.pnl) or "--", ix + iw - 96, iy + 8, 92, "small", hd.pnl and (hd.pnl >= 0 and GREEN or RED) or ns.C.dim, "RIGHT")
      hit(ix, iy, iw, 28, hd.name, "Click to chart it.", function() chartItem(hd.id, "movers") end, "Chart " .. hd.name)
    end)
  end
  local rx = x + hw + 16
  card(rx, y, hw, h, "RECENT TRADES")
  local recent = M().recent(60)
  if #recent == 0 then
    text("Nothing yet. Buys from Deals, posts from Quick Sell and the sales the game reports land here.",
      rx + 14, y + 34, hw - 28, "small", ns.C.dim, nil, true)
  else
    list("trades", recent, rx + 6, y + 30, hw - 12, 22, h - 36, function(e, ix, iy, iw)
      local tag = KIND_TAGS[e.k] or KIND_TAGS.post
      pill(tag[1], ix + 2, iy + 3, 70, tag[2])
      text(Q.plain((e.qty or 1) .. " x " .. (e.name or "?")), ix + 78, iy + 4, iw - 78 - 140, "small")
      text(e.each and (ns.money(e.each) .. " each") or "", ix + iw - 210, iy + 4, 120, "dim", ns.C.dim, "RIGHT")
      text(A().age(e.t), ix + iw - 86, iy + 4, 82, "dim", ns.C.dim, "RIGHT")
    end)
  end
end

function pages.market(W, top, H)
  local db = ns.db()
  local mode = view.marketMode or "movers"
  local labels, lit = {}, 1
  for i, v in ipairs(MARKET_VIEWS) do labels[i] = v[2]; if v[1] == mode then lit = i end end
  segments(16, top, 380, labels, lit, function(i) view.marketMode = MARKET_VIEWS[i][1] end)
  local mins, minLit = {}, nil
  for i, e in ipairs(M().MINPRICES) do mins[i] = e[1]; if e[2] == M().minPrice() then minLit = i end end
  if mode ~= "trades" then
    text("Price at least", W - 16 - 230 - 90, top + 4, 86, "small", ns.C.dim, "RIGHT")
    segments(W - 16 - 230, top, 230, mins, minLit, function(i) db.auctionMarketMin = M().MINPRICES[i][2]; offsets = {} end, "Price at least ")
  end
  local y = top + 30
  local bottom = top + H
  if mode == "trades" then return tradesView(W, y, bottom) end
  local lw = math.floor((W - 48) * 0.52)
  local rw = W - 48 - lw
  local rx = 16 + lw + 16
  local h1 = math.floor((bottom - y - 12) / 2)
  local first
  if mode == "movers" then
    local ups, downs = M().gainers(), M().losers()
    first = ups[1] or downs[1]
    moverCard("gainers", "TOP GAINERS", #ups .. " rising", ups, 16, y, lw, h1,
      { empty = "Nothing rising yet. A price moves here once it has been read twice: Scan all now, and again later." })
    moverCard("losers", "TOP LOSERS", #downs .. " falling", downs, 16, y + h1 + 12, lw, bottom - y - h1 - 12,
      { empty = "Nothing falling yet." })
  else
    local hot, sig = M().hot(), M().signals()
    first = hot[1] or sig[1]
    moverCard("hot", "HOT RIGHT NOW", "big moves, supply drying up", hot, 16, y, lw, h1,
      { tag = true, empty = "Nothing hot yet: this needs two readings of an item. Scan all now, and again later." })
    moverCard("signals", "BUY AND SELL SIGNALS", "far from their usual price", sig, 16, y + h1 + 12, lw, bottom - y - h1 - 12,
      { tag = true, empty = "No signals yet: these need two days of prices." })
  end
  if not view.market or not A().store().items[view.market] then view.market = first and first.id or nil end
  chartCard(rx, y, rw, bottom - y, view.market)
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
  segments(x, top, 330, labels, lit, function(i) view.deals = KINDS[i][2]; offsets.deals = 0; A().retarget(view.deals) end)
  local mins, minLit = {}, nil
  for i, e in ipairs(T().MINPROFITS) do mins[i] = e[1]; if e[2] == T().minProfit() then minLit = i end end
  text("Worth at least", x + 344, top + 4, 100, "small", ns.C.dim, "RIGHT")
  segments(x + 450, top, w - 450, mins, minLit, function(i) db.auctionMinProfit = T().MINPROFITS[i][2]; A().retarget(view.deals) end, "At least ")
  local y = top + 30
  local flips, flipLit = {}, nil
  for i, e in ipairs(T().FLIPS) do flips[i] = e[1]; if e[2] == T().flipPct() then flipLit = i end end
  text("A flip is listed under its usual by", x, y + 4, 210, "small", ns.C.dim)
  segments(x + 214, y, 180, flips, flipLit, function(i) db.auctionFlipPct = T().FLIPS[i][2]; A().retarget(view.deals) end, "Flip at ")
  local rows = T().deals(view.deals, view.hidden)
  local profit = 0
  for _, d in ipairs(rows) do profit = profit + (T().potential(d)) end
  text(#rows .. (#rows == 1 and " deal" or " deals") .. (#rows > 0 and (", about +" .. ns.money(profit) .. " to make") or ""),
    x + 404, y + 4, w - 404, "small", #rows > 0 and GREEN or ns.C.dim, "RIGHT")
  y = y + 30
  -- the sniper
  local sn = A().sniper
  rect(x, y - 2, w, 50, sn.on and { GREEN[1], GREEN[2], GREEN[3], 0.07 } or { 1, 1, 1, 0.03 })
  button(sn.on and "Stop sniping" or "Snipe deals", x + 6, y + 4, 140, function() A().retarget(view.deals); A().toggleSnipe() end,
    { label = "Snipe deals", lit = sn.on, enabled = A().snipeAvailable(), h = 36, tip = "Snipe deals",
      tipText = "Searches the items your choices above can make a deal on, one a second, lap after lap. A deal chimes, is checked at once (how many, and the total) and waits for your Buy click." })
  local kindName = view.deals == "vendor" and "under-vendor" or (view.deals == "flip" and "flip" or "deal")
  if sn.on then
    local n, total, best = T().sniperHaul()
    text("Watching " .. #sn.list .. " " .. kindName .. " items at " .. (T().minProfit() > 0 and (ns.money(T().minProfit()) .. "+") or "any profit")
      .. ": " .. ns.thousands(sn.checked) .. " searches" .. ((sn.laps or 0) > 0 and (", lap " .. (sn.laps + 1)) or "")
      .. (sn.current and (", now " .. Q.plain(sn.current)) or ""), x + 156, y + 4, w - 162, "small", GREEN)
    if n > 0 then
      text(n .. (n == 1 and " live deal" or " live deals") .. ": +" .. ns.money(total) .. " potential profit"
        .. (best and (", best " .. Q.plain(best.name) .. " +" .. ns.money(best.amount)) or ""), x + 156, y + 22, w - 162, "body", ns.C.gold)
    else
      text("No live deal yet. Each one found chimes, shows LIVE and is checked for you.", x + 156, y + 22, w - 162, "dim", ns.C.dim)
    end
  else
    text("The sniper watches what your choices above can make: change them and it follows.", x + 156, y + 4, w - 162, "small", ns.C.light)
    text("Check finds the listings, Buy shows the total, a commodity asks to confirm. Profits count the 5% cut.",
      x + 156, y + 22, w - 162, "dim", ns.C.dim)
  end
  y = y + 56
  local bottom = top + H - 30
  if #rows == 0 then
    text("No deals in your prices yet. Scan all finds listings under vendor price and far under their usual price.",
      x, y + 6, w, "small", ns.C.dim, nil, true)
  else
    list("deals", rows, x, y, w, 40, bottom - y, function(d, rx, ry, rw)
      local live = T().isLive(d.id)
      if live then rect(rx, ry, 3, 38, GREEN, "BORDER") end
      icon(itemIcon(d.id), rx + 8, ry + 5, 28)
      local name = Q.plain(d.name)
      text(name, rx + 44, ry + 4, 220, "body", live and ns.C.gold or ns.C.light)
      local vendor = d.kind == "vendor"
      pill(vendor and "UNDER VENDOR" or "FLIP", rx + 270, ry + 4, 92, vendor and GREEN or ns.C.accent)
      if live then pill("LIVE", rx + 366, ry + 4, 40, GREEN) end
      local sub = "Listed " .. ns.money(d.low) .. (vendor and ", vendor pays " or ", usual ") .. ns.money(d.worth)
        .. "  -  +" .. ns.money(d.profit) .. " each (" .. d.pct .. "%)  -  " .. (d.source and ("Auctionator, " .. A().age(d.at)) or (ns.thousands(d.n) .. " listed"))
      text(sub, rx + 44, ry + 22, rw - 44 - 360, "dim", ns.C.dim)
      hit(rx + 40, ry, 220, 18, d.name, "Click to chart it.", function() chartItem(d.id) end, "Chart " .. d.name)
      -- potential profit
      local amount, qty, exact = T().potential(d)
      text("+" .. ns.money(amount), rx + rw - 352, ry + 4, 128, "body", GREEN, "RIGHT")
      text(exact and ("potential, " .. qty .. " under the limit") or "each, Check for more", rx + rw - 352, ry + 22, 128, "dim", ns.C.dim, "RIGHT")
      local b = T().buying[d.id]
      button(T().dealLabel(d.id), rx + rw - 216, ry + 9, 150, function()
        local x2 = T().buying[d.id]
        if not x2 or x2.stage == "none" then T().check(d) else T().buy(d.id) end
      end, { label = "Deal " .. d.name, enabled = not b or b.stage == "ready" or b.stage == "confirm" or b.stage == "none",
        lit = b and (b.stage == "ready" or b.stage == "confirm"),
        tip = d.name, tipText = "Check searches its listings; then Buy, and Confirm for a commodity." })
      local hidden = T().isHidden(d.id)
      button(hidden and "Unhide" or "Hide", rx + rw - 60, ry + 9, 56, function() T().hide(d.id, not hidden); A().retarget(view.deals) end,
        { label = (hidden and "Unhide " or "Hide ") .. d.name, tip = "Hide", tipText = "Leave it out of Deals, Quick Sell and the sniper." })
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
  text("Undercut", x, top + 4, 58, "small", ns.C.dim)
  segments(x + 60, top, 184, cuts, cutLit, function(i) db.auctionUndercut = T().UNDERCUTS[i][2] end, "Undercut ")
  local durs, durLit = {}, nil
  for i, e in ipairs(T().DURATIONS) do durs[i] = e[1]; if e[2] == T().duration() then durLit = i end end
  text("Post for", x + 254, top + 4, 54, "small", ns.C.dim)
  segments(x + 310, top, math.max(150, lw - 310), durs, durLit, function(i) db.auctionDuration = T().DURATIONS[i][2] end, "Post for ")
  local y = top + 30
  local nextRow = T().nextPost()
  button(nextRow and ("Post next: " .. nextRow.count .. " x " .. Q.plain(nextRow.name) .. " at " .. ns.money(nextRow.sell.price))
    or "Nothing to post", x, y, lw, function() T().postNext() end,
    { label = "Post next", enabled = nextRow ~= nil and T().available(), h = 26, lit = nextRow ~= nil, tip = "Post next",
      tipText = "Posts the most valuable item in the list. Click again for the next one." })
  y = y + 34
  local rows = T().sellable(false, view.hidden)
  if #rows == 0 then
    text("Nothing priced to sell in your bags. Reprice bags, top right, prices what you carry.", x, y + 4, lw, "small", ns.C.dim, nil, true)
  else
    list("selling", rows, x, y, lw, 44, bottom - y, function(row, ix, iy, iw)
      local s = row.sell
      icon(row.icon or itemIcon(row.id), ix + 6, iy + 6, 30)
      local bx = ix + iw - 172
      local tagX = bx - 96 - (s.custom and 48 or 0)
      text(Q.plain(row.count .. " x " .. row.name), ix + 44, iy + 5, tagX - ix - 50, "body")
      hit(ix + 40, iy, tagX - ix - 44, 20, row.name, "Click to chart it.", function() chartItem(row.id) end, "Chart " .. row.name)
      local _, label, color, short = T().status(row.id, s)
      pill(short or label, tagX, iy + 5, 92, color)
      hit(tagX, iy + 5, 92, 16, label, "How the market looks for selling it now.")
      local sub
      if s.blocked then sub = "A vendor pays " .. ns.money(s.vendor) .. " each: sell it there"
      else
        sub = ns.money(s.price) .. " each" .. (s.custom and " (your price)" or "")
        if s.low then sub = sub .. ", lowest " .. ns.money(s.low) end
        if s.usual and s.usual ~= s.low then sub = sub .. ", usual " .. ns.money(s.usual) end
        sub = sub .. "  -  " .. ns.money(s.price * row.count) .. " in all"
        if s.paid then sub = sub .. "  -  paid " .. ns.money(s.paid) end
      end
      text(sub, ix + 44, iy + 24, bx - ix - 50 - (s.custom and 48 or 0), "dim", s.blocked and RED or (s.loss and ORANGE or ns.C.dim))
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
        { label = (hidden and "Unhide " or "Hide ") .. row.name, tip = "Hide", tipText = "Leave it out of Quick Sell and Deals." })
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
  button("Refresh", rx + 178, top + 32, rw - 190, function() T().queryOwned() end, { label = "Refresh auctions" })
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
    text(sub, ix + 6, iy + 20, iw - 150, "dim", ns.C.dim)
    if st then pill(st[1], ix + iw - 146, iy + 18, 76, st[2]) end
    if not row.sold then
      local armed = T().armed("cancel:" .. row.auction)
      button(armed and "Sure?" or "Cancel", ix + iw - 66, iy + 8, 62, function() T().cancel(row) end,
        { label = "Cancel " .. row.name, lit = armed, tip = "Cancel", tipText = "Two clicks. The deposit is lost; the item comes back by mail." })
    end
  end)
  text("A cancelled auction loses its deposit.", rx + 12, top + H - 22, rw - 24, "dim", ns.C.dim)
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

function pages.scan(W, top, H)
  local db = ns.db()
  local lw = math.floor((W - 48) / 2)
  local lx, rx = 16, 16 + lw + 16
  -- full scan
  local age, ageColor = scanAge()
  card(lx, top, lw, 132, "FULL SCAN")
  text("Last scan:", lx + 14, top + 34, 70, "small", ns.C.dim)
  text(age, lx + 84, top + 34, 120, "small", ageColor)
  text(ns.thousands(A().count()) .. " items priced", lx + 200, top + 34, lw - 214, "small", ns.C.light, "RIGHT")
  text("Instant every 15 min; paged any time in between.", lx + 14, top + 51, lw - 28, "dim", ns.C.dim)
  local done, total, phase, pages = A().fullProgress()
  if done then
    local frac = total and total > 0 and done / total or ((pages or 0) % 10) / 10
    bar(lx + 14, top + 72, lw - 28, 8, frac, phase == "filing" and GREEN or ns.C.accent)
  else
    local speeds, lit = {}, nil
    for i, e in ipairs(A().SPEEDS) do speeds[i] = e[1]; if e[2] == A().budget() then lit = i end end
    text("Speed", lx + 14, top + 70, 50, "dim", ns.C.dim)
    segments(lx + 64, top + 66, lw - 78, speeds, lit, function(i) db.auctionScanSpeed = A().SPEEDS[i][2] end, "Scan speed ")
  end
  local label = done and (phase == "paged" and ("Paged scan: " .. ns.thousands(done) .. " items, page " .. (pages or 0))
    or (phase == "filing" and ("Saving prices " .. ns.thousands(done) .. " of " .. ns.thousands(total or 0)))
    or (phase == "reading" and total and ("Reading " .. ns.thousands(done) .. " of " .. ns.thousands(total)))
    or "Waiting for the auction house...")
    or nil
  scanAllButton(label, lx + 14, top + 90, lw - 28)
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
  local ch = math.min(130, top + H - ly - 70)
  if ch > 40 then
    lineChart((chartPoints(v.id)), rx + 14, ly + 4, lw - 28, ch, { usual = p.days and p.days >= 2 and p.usual or nil })
    ly = ly + ch + 10
    button("Open in Market", rx + 14, ly, lw - 28, function() chartItem(v.id, "movers") end, { label = "Chart " .. (p.name or v.name) })
    ly = ly + 26
  end
  button("Search it now", rx + 14, ly, lw - 28, function()
    if A().searchNow(p.name or v.name) then ns.say("Searching " .. Q.plain(p.name or v.name) .. ".") end
  end, { enabled = A().isOpen() })
end

----------------------------------------------------------------------------
-- Drawing, opening and closing
----------------------------------------------------------------------------

-- Each page's quick refresh, in the header next to Scan all: { label, tooltip, run() -> chat line }.
local function namesOf(rows, n)
  local out, seen = {}, {}
  for _, r in ipairs(rows) do
    if #out >= n then break end
    if r.name and not seen[r.name] then seen[r.name] = true; out[#out + 1] = r.name end
  end
  return out
end
P.REFRESH = {
  overview = { "Update", "Searches your bags and what your guide needs again, and reads your auctions.", function()
    local n = A().scanBags(true) + A().scanNeeds()
    T().queryOwned()
    return "Updating: " .. n .. " searches queued, your auctions read again."
  end },
  market = { "Recheck movers", "Searches the items on this page again now, so their lines and changes are fresh.", function()
    local rows = {}
    local lists = view.marketMode == "hot" and { M().hot(15), M().signals(15) } or { M().gainers(15), M().losers(15) }
    if view.marketMode == "trades" then
      lists = { M().record().holdings }
    end
    for _, l in ipairs(lists) do for _, r in ipairs(l) do rows[#rows + 1] = r end end
    if view.market then local p = A().price(view.market); if p and p.name then table.insert(rows, 1, { name = p.name }) end end
    return "Rechecking " .. A().searchNames(namesOf(rows, 30)) .. " items."
  end },
  deals = { "Recheck deals", "Searches each deal on the list again: gone ones drop off, new prices show.", function()
    return "Rechecking " .. A().searchNames(namesOf(T().deals(view.deals, view.hidden), 30)) .. " deals."
  end },
  selling = { "Reprice bags", "Searches everything you could sell again, reads your auctions and checks them for undercuts.", function()
    local n = A().scanBags(true)
    T().queryOwned()
    if #T().mine.list > 0 then ns.after(1, T().checkUndercuts) end
    return "Repricing " .. n .. " items from your bags."
  end },
  scan = { "Scan my bags", "Each item you could sell whose price is older than 30 minutes.", function()
    return "Searching " .. A().scanBags() .. " items from your bags."
  end },
}

-- The ticker's items: per move a button with the icon, the name, the price, an up or down arrow
-- and the change on a coloured tag, then a small diamond before the next one.
local ARROW_UP, ARROW_DOWN = "Interface\\Buttons\\Arrow-Up-Up", "Interface\\Buttons\\Arrow-Down-Up"
local function tickerItem(track, i)
  local it = track.items[i]
  if it then return it end
  it = CreateFrame("Button", nil, track)
  it:SetHeight(22)
  it.glow = it:CreateTexture(nil, "BACKGROUND")
  it.glow:SetAllPoints()
  it.glow:SetColorTexture(1, 1, 1, 0.08)
  it.glow:Hide()
  it.icon = it:CreateTexture(nil, "ARTWORK")
  it.icon:SetSize(16, 16)
  it.icon:SetPoint("LEFT", it, "LEFT", 4, 0)
  it.name = it:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  it.price = it:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  it.arrow = it:CreateTexture(nil, "ARTWORK")
  it.arrow:SetSize(12, 12)
  it.tag = it:CreateTexture(nil, "BORDER")
  it.tag:SetHeight(14)
  it.pct = it:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  it.sep = it:CreateTexture(nil, "ARTWORK")
  it.sep:SetSize(4, 4)
  for _, fs in ipairs({ it.name, it.price, it.pct }) do fs:SetWordWrap(false); fs:SetJustifyH("LEFT") end
  it:SetScript("OnEnter", function(self)
    self.glow:Show()
    ns.art.showTip(self)
  end)
  it:SetScript("OnLeave", function(self)
    self.glow:Hide()
    ns.art.hideTip(self)
  end)
  track.items[i] = it
  return it
end

-- Lays one copy of the moves out on a track; returns its width.
local function fillTrack(track, rows, limit)
  local x = 0
  for _, it in ipairs(track.items) do it:Hide() end
  for i, r in ipairs(rows) do
    local it = tickerItem(track, i)
    local up = (r.change or 0) > 0
    local c = M().pctColor(r.change)
    ns.setIcon(it.icon, itemIcon(r.id))
    it.name:SetText(Q.plain(r.name))
    it.name:ClearAllPoints(); it.name:SetPoint("LEFT", it, "LEFT", 24, 0)
    local nw = math.min(150, tonumber(it.name:GetStringWidth()) or 60)
    it.name:SetWidth(nw)
    it.price:SetText(ns.money(r.last))
    it.price:ClearAllPoints(); it.price:SetPoint("LEFT", it, "LEFT", 24 + nw + 6, 0)
    local pw = tonumber(it.price:GetStringWidth()) or 40
    it.price:SetWidth(pw + 2)
    local ax = 24 + nw + 6 + pw + 6
    local file = up and ARROW_UP or ARROW_DOWN
    it.arrow:ClearAllPoints(); it.arrow:SetPoint("LEFT", it, "LEFT", ax, 0)
    if ns.art.hasFile(file) and it.arrow:SetTexture(file) ~= false then
      it.arrow:SetVertexColor(c[1], c[2], c[3])
      it.arrow:Show()
    else
      it.arrow:Hide()
    end
    local tx = ax + 14
    it.pct:SetText(M().pctText(r.change))
    it.pct:SetTextColor(c[1], c[2], c[3])
    local cw = (tonumber(it.pct:GetStringWidth()) or 24) + 10
    it.tag:ClearAllPoints(); it.tag:SetPoint("LEFT", it, "LEFT", tx, 0)
    it.tag:SetWidth(cw)
    it.tag:SetColorTexture(c[1], c[2], c[3], 0.2)
    it.pct:ClearAllPoints(); it.pct:SetPoint("LEFT", it, "LEFT", tx + 5, 0)
    it.pct:SetWidth(cw - 6)
    local w = tx + cw + 8
    it.sep:ClearAllPoints(); it.sep:SetPoint("CENTER", it, "LEFT", w + 6, 0)
    it.sep:SetColorTexture(ns.C.gold[1], ns.C.gold[2], ns.C.gold[3], 0.5)
    w = w + 14
    it:SetWidth(w)
    it:ClearAllPoints(); it:SetPoint("LEFT", track, "LEFT", x, 0)
    it.tipTitle, it.tipText, it.codexLabel = r.name, moverTip(r), "Ticker " .. r.name
    local id = r.id
    it:SetScript("OnClick", function() chartItem(id, "movers") end)
    if limit and x + w > limit then it:Hide() else it:Show() end
    x = x + w
  end
  track:SetWidth(math.max(1, x))
  return x
end

local function drawTicker(y, w)
  local C = ns.C
  ticker:ClearAllPoints()
  ticker:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
  ticker:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
  ticker:Show()
  ticker.lineT:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.45)
  ticker.lineB:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.25)
  ticker.plate:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.14)
  ticker.plateEdge:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.6)
  -- live: a scan running, the sniper on, or prices under 15 minutes old
  local last = A().lastScanAt and A().lastScanAt() or 0
  local live = A().scanning() or (A().sniper and A().sniper.on) or (last > 0 and now() - last < 900)
  ticker.live = live and true or nil
  local dc = live and GREEN or C.dim
  ticker.dot:SetColorTexture(dc[1], dc[2], dc[3], 1)
  ticker.label:SetText(live and "LIVE" or "MARKET")
  ticker.label:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
  local rows = M().ticker(16)
  local key = {}
  for _, r in ipairs(rows) do key[#key + 1] = r.id .. ":" .. (r.last or 0) .. ":" .. (r.change or 0) end
  key = table.concat(key, ",") .. "|" .. ns.themeVersion .. "|" .. w
  if key == ticker.key then return end
  ticker.key = key
  ticker.wide = nil
  local a, b = ticker.tracks[1], ticker.tracks[2]
  if #rows == 0 then
    fillTrack(a, {}); fillTrack(b, {})
    ticker.empty:SetText("Prices start moving here once items have been scanned twice: Scan all now, and again later.")
    ticker.empty:Show()
    return
  end
  ticker.empty:Hide()
  local room = w - 92
  local sw = fillTrack(a, rows, not ticker.clips and room or nil)
  a:ClearAllPoints(); a:SetPoint("LEFT", ticker.strip, "LEFT", ticker.clips and -(ticker.off or 0) or 0, 0)
  if ticker.clips and sw > room then
    fillTrack(b, rows)
    b:Show()
    ticker.wide = math.max(1, sw)
    ticker.off = (ticker.off or 0) % ticker.wide
  else
    fillTrack(b, {})
    b:Hide()
    ticker.off = 0
    a:ClearAllPoints(); a:SetPoint("LEFT", ticker.strip, "LEFT", 0, 0)
  end
end

function P.refresh()
  if not P.shown() then return end
  releaseAll()
  wheelKey = nil
  local C = ns.C
  body.tint:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 0.92)
  local W = math.max(600, (tonumber((try(root.GetWidth, root))) or 800) - 8)
  local H = math.max(300, (tonumber((try(root.GetHeight, root))) or 538) - 50)
  -- header: the title (the page's tab), the page's refresh and Scan all; the ticker, your gold, the scan age
  icon(ns.ADDON_ICON, 16, 8, 22)
  local title, line = "LEVELING CODEX", P.PAGES[1][3]
  for _, pg in ipairs(P.PAGES) do
    if pg[1] == page then
      line = pg[3]
      if pg[1] ~= "overview" then title = "CODEX " .. pg[2]:upper() end
    end
  end
  text(title, 44, 11, 220, "title", C.gold)
  hit(16, 6, 240, 26, title, line)
  -- your gold and the scan age sit in the header, so the ticker runs the whole width
  local age, ageColor = scanAge()
  local infoW = W - 262 - 16 - 270
  text(money(tonumber(try(GetMoney)) or 0), 262, 9, infoW, "small", C.light)
  text("Last scan " .. age, 262, 23, infoW, "dim", ageColor)
  local r = P.REFRESH[page]
  if r then
    local bx = W - 16 - 116 - 6 - 140
    local bdone, btotal, bfinished, bat = A().batchProgress(page)
    local blabel = r[1]
    if bdone and not bfinished then
      blabel = btotal > 0 and ("Working " .. bdone .. " / " .. btotal) or "Working..."
    elseif bfinished then
      blabel = "Done"
    end
    button(blabel, bx, 8, 140, function()
      local said = r[3]()
      A().startBatch(page)
      ns.say(said)
      P.refresh()
    end, { label = r[1], tip = r[1], tipText = r[2] })
    if bdone then
      -- a bar under the button: how many of the searches it queued have come back
      local frac = bfinished and 1 or (btotal > 0 and bdone / btotal or 0.1)
      bar(bx, 32, 140, 4, frac, bfinished and GREEN or C.accent)
      if bfinished and not view.batchTimer then
        view.batchTimer = true
        ns.after(4, function()
          view.batchTimer = nil
          local b = A().batch
          if b and b.doneAt and now() - b.doneAt >= 3.5 then A().endBatch() end
          P.refresh()
        end)
      end
    end
  end
  local done, total, phase = A().fullProgress()
  scanAllButton(done and (phase == "filing" and "Saving..." or "Scanning...") or nil, W - 16 - 116, 8, 116)
  if done then bar(W - 16 - 116, 32, 116, 3, total and total > 0 and done / total or 0.5, phase == "filing" and GREEN or C.accent) end
  drawTicker(40, W + 8)
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
  lightTabs(true)
  local deselect = PanelTemplates_DeselectTab
  if type(deselect) == "function" and type(root.Tabs) == "table" then
    for _, b in ipairs(root.Tabs) do pcall(deselect, b) end
  end
  P.refresh()
end

function P.close(clicked)
  if panel and panel:IsShown() then panel:Hide() end
  lightTabs(false)
  local selectTab = PanelTemplates_SelectTab
  if clicked and type(selectTab) == "function" and type(root) == "table" and type(root.Tabs) == "table" then
    for _, b in ipairs(root.Tabs) do if b == clicked then pcall(selectTab, b) end end
  end
end

-- AUCTION_HOUSE_SHOW (Auction.lua): the tab, and the Codex tab again when it was open last time.
function P.onShow(r)
  root = r
  shows = shows + 1
  if type(root) ~= "table" then return end
  if not P.enabled() then
    for _, tab in ipairs(tabs) do tab:Hide() end
    P.close()
    return
  end
  if #tabs == 0 then makeTabs() end
  for _, tab in ipairs(tabs) do tab:Show() end
  hookTabs()
  place()
  -- Auctionator and other add-ons add their tabs a moment later
  for _, wait in ipairs({ 0.3, 1, 3 }) do
    ns.after(wait, function() if root and root:IsShown() and tabs[1] then hookTabs(); place() end end)
  end
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
  local where = "nowhere"
  if tabs[1] then
    local l, t = tonumber((try(tabs[1].GetLeft, tabs[1]))), tonumber((try(tabs[1].GetTop, tabs[1])))
    local name = placedAfter and has(placedAfter, "GetName") and placedAfter:GetName()
    where = (tabs[1]:IsVisible() and "visible" or "not visible") .. " at " .. (l and math.floor(l) or "?") .. ", " .. (t and math.floor(t) or "?")
      .. (placedBelow and ", in a column up the right edge from the bottom corner, on a rail fixed to the window (the tab row is full)"
        or (", after " .. (placedAfter and (name or "an unnamed tab") or "nothing (bottom left)")))
  end
  local rootName = type(root) == "table" and has(root, "GetName") and root:GetName() or (root and "unnamed frame" or "none")
  return { "auction tabs: " .. (#tabs > 0 and (#tabs .. " made, " .. where) or "not made") .. ", auction house " .. tostring(rootName)
    .. ", opened " .. shows .. "x, " .. (type(root) == "table" and #tabsOf(root) or 0) .. " tabs seen"
    .. (P.shown() and (", showing " .. page) or "")
    .. (P.enabled() and "" or ", turned off") .. (reopen and ", reopens" or "")
    .. (P.lastError and (", last error: " .. Q.plain(P.lastError)) or "") }
end
