-- Window.lua: the /codex window, styled like the guide pages
-- (dark leather, gold rules, parchment cards, double borders, Morpheus headings).

local _, ns = ...
local C, rgba, plain, padText = ns.C, ns.rgba, ns.plain, ns.padText

local FONT_HEAD = "Fonts\\MORPHEUS.TTF"
local FONT_MONO = "Fonts\\ARIALN.TTF"
local W = 568 -- content width

local frame, scroll, content, tabs, levelText, nowBtn
local viewLevel -- the level the window is showing (defaults to yours)
local activeTab = "level"
local scrollPos, shownTab = {}, nil -- scroll offset per tab, and the tab currently drawn
local refresh   -- defined below; the renderers' click handlers call it

----------------------------------------------------------------------------
-- Pools of reusable widgets inside the scrolling content
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
end

local function newFS() return content:CreateFontString(nil, "OVERLAY", "GameFontHighlight") end
local function newTex() return content:CreateTexture(nil, "BACKGROUND") end
local function newTexB() return content:CreateTexture(nil, "BORDER") end

----------------------------------------------------------------------------
-- Drawing helpers (x, y are offsets from the content's top-left; y grows downwards)
----------------------------------------------------------------------------

local function styleFS(fs, kind)
  if kind == "title" then fs:SetFontObject("GameFontNormalHuge"); fs:SetFont(FONT_HEAD, 24, "")
  elseif kind == "head" then fs:SetFontObject("GameFontNormalLarge"); fs:SetFont(FONT_HEAD, 18, "")
  elseif kind == "label" then fs:SetFontObject("GameFontNormalSmall")
  elseif kind == "small" then fs:SetFontObject("GameFontHighlightSmall")
  elseif kind == "mono" then fs:SetFontObject("GameFontHighlight"); fs:SetFont(FONT_MONO, 13, "")
  else fs:SetFontObject("GameFontHighlight") end
  local sh = (kind == "head" or kind == "title" or kind == "label") and 1 or 0
  fs:SetShadowOffset(sh, -sh)
  fs:SetSpacing(kind == "mono" and 3 or 2)
  fs:SetWordWrap(true)
  fs:SetJustifyV("TOP")
end

-- Place text at (x, y) in content; returns its height and the font string.
local function T(str, x, y, width, kind, color, justify)
  local fs = take("fs", newFS)
  styleFS(fs, kind)
  fs:SetTextColor(rgba(color or C.light))
  fs:SetWidth(width)
  fs:SetJustifyH(justify or "LEFT")
  fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  fs:SetText(str)
  return fs:GetStringHeight(), fs
end

local function rect(x, y, w, h, color, layer, sub)
  local t = take(layer == "border" and "texB" or "tex", layer == "border" and newTexB or newTex)
  if layer == "border" then t:SetDrawLayer("BORDER", sub or 0) else t:SetDrawLayer("BACKGROUND", sub or 0) end
  t:SetColorTexture(rgba(color))
  t:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  t:SetSize(w, h)
  return t
end

-- A card with a double gold border, like the guide's panels.
local function box(x, y, w, h, fill, edge)
  rect(x, y, w, h, fill)
  -- aged edge: parchment darkens toward the bottom, dark panels get a faint warm sheen at the top
  local shade = rect(x, y, w, h, { 1, 1, 1, 1 }, nil, 1)
  if fill == C.parch then ns.fade(shade, "VERTICAL", 0.5, 0.35, 0.15, 0.22, 0)
  else ns.fade(shade, "VERTICAL", 0.6, 0.45, 0.2, 0, 0.12) end
  edge = edge or C.edge
  rect(x, y, w, 1, edge, "border"); rect(x, y + h - 1, w, 1, edge, "border")
  rect(x, y, 1, h, edge, "border"); rect(x + w - 1, y, 1, h, edge, "border")
  local e2 = { edge[1], edge[2], edge[3], 0.35 }
  rect(x + 4, y + 4, w - 8, 1, e2, "border"); rect(x + 4, y + h - 5, w - 8, 1, e2, "border")
  rect(x + 4, y + 4, 1, h - 8, e2, "border"); rect(x + w - 5, y + 4, 1, h - 8, e2, "border")
end

local function showTip(self)
  if not self.tipTitle or not GameTooltip then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(self.tipTitle, rgba(C.tipTitle))
  if self.tipText and self.tipText ~= "" then GameTooltip:AddLine(self.tipText, 1, 1, 1, true) end
  GameTooltip:Show()
end
local function hideTip() if GameTooltip then GameTooltip:Hide() end end

local function newIcon()
  local f = CreateFrame("Button", nil, content)
  f.ring = f:CreateTexture(nil, "BORDER"); f.ring:SetAllPoints(); f.ring:SetColorTexture(rgba(C.edge))
  f.tex = f:CreateTexture(nil, "ARTWORK")
  f.tex:SetPoint("TOPLEFT", 1, -1); f.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f:SetScript("OnEnter", showTip); f:SetScript("OnLeave", hideTip)
  return f
end

local function icon(name, x, y, size, title, text)
  local f = take("icon", newIcon)
  f:SetSize(size, size)
  f:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  ns.setIcon(f.tex, name)
  f.tipTitle, f.tipText = title, text
  return f
end

-- Gold-bordered button in the guide's style.
local function styleButton(b)
  b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
  b.edges = {}
  for i = 1, 4 do b.edges[i] = b:CreateTexture(nil, "BORDER") end
  b.edges[1]:SetPoint("TOPLEFT"); b.edges[1]:SetPoint("TOPRIGHT"); b.edges[1]:SetHeight(1)
  b.edges[2]:SetPoint("BOTTOMLEFT"); b.edges[2]:SetPoint("BOTTOMRIGHT"); b.edges[2]:SetHeight(1)
  b.edges[3]:SetPoint("TOPLEFT"); b.edges[3]:SetPoint("BOTTOMLEFT"); b.edges[3]:SetWidth(1)
  b.edges[4]:SetPoint("TOPRIGHT"); b.edges[4]:SetPoint("BOTTOMRIGHT"); b.edges[4]:SetWidth(1)
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.16)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("CENTER")
  b.SetLook = function(self, on)
    self.bg:SetColorTexture(rgba(on and C.btnOn or C.btnOff))
    for _, e in ipairs(self.edges) do e:SetColorTexture(rgba(C.edge)) end
    self.label:SetTextColor(rgba(on and C.btnOnInk or C.gold))
  end
  b:SetLook(false)
  b:SetScript("OnEnter", showTip); b:SetScript("OnLeave", hideTip)
  return b
end

local function newBtn() return styleButton(CreateFrame("Button", nil, content)) end

local function btn(label, x, y, w, onClick, on, tip)
  local b = take("btn", newBtn)
  b:SetSize(w, 24)
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  b.label:SetText(label)
  b:SetLook(on)
  b:SetScript("OnClick", onClick)
  b.tipTitle, b.tipText = tip and label or nil, tip
  return b
end

-- An invisible clickable strip (for talent rows).
local function newHit()
  local f = CreateFrame("Button", nil, content)
  local hl = f:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.1)
  f:SetScript("OnEnter", showTip); f:SetScript("OnLeave", hideTip)
  return f
end

local function chip(str, x, y, filled)
  local _, fs = T(str, x + 8, y + 3, 400, "small", filled and C.chipInk or C.gold)
  local w = fs:GetStringWidth() + 16
  if filled then rect(x, y, w, 18, C.chipFill, "border")
  else box(x, y, w, 18, { 0, 0, 0, 0 }) end
  return w
end

local function goldRuleAt(y)
  local half = (W - 20) / 2
  local l = rect(0, y, half, 1, { 1, 1, 1, 1 }, "border"); ns.fadeAccent(l, "HORIZONTAL", 0, 0.8)
  local r = rect(half + 20, y, half, 1, { 1, 1, 1, 1 }, "border"); ns.fadeAccent(r, "HORIZONTAL", 0.8, 0)
  local g = rect(W / 2 - 4, y - 3, 7, 7, C.gem, "border")
  if g.SetRotation then g:SetRotation(math.rad(45)) end
end

local function sectionTitle(str, y, sub)
  local h = T(str, 0, y, W, "head", C.gold)
  if sub then T(sub, 0, y + 4, W, "small", C.dim, "RIGHT") end
  goldRuleAt(y + h + 6)
  return h + 16
end

local function testBanner(level)
  ns.showToast(level, true, true)
  if PlaySound then pcall(PlaySound, 888) end
end

----------------------------------------------------------------------------
-- Tabs
----------------------------------------------------------------------------

local function spellIconsGrid(t, y, x0, width, light)
  local col = (width - 8) / 2
  local i = 0
  for k, s in ipairs(t.spells) do
    local cx = x0 + (i % 2) * col
    local cy = y + math.floor(i / 2) * 40
    icon(t.icons and t.icons[k], cx, cy, 32, plain(s), t.notes and plain(t.notes[k]) or nil)
    T(plain(s), cx + 40, cy + 2, col - 48, "body", light and C.light or C.ink)
    if t.notes and t.notes[k] ~= "" then T(plain(t.notes[k]), cx + 40, cy + 18, col - 48, "small", light and C.dim or C.inkSoft) end
    i = i + 1
  end
  return math.ceil(i / 2) * 40
end

local renderers = {}

renderers.level = function(V)
  local y = 0
  -- Talent card (parchment)
  local top = y
  y = y + 14
  if V >= 10 then
    local hit, rank, text = ns.talentAt(V)
    T("YOUR TALENT POINT", 16, y, 300, "label", C.inkSoft)
    T("Level " .. V, 16, y, W - 32, "label", C.inkSoft, "RIGHT")
    y = y + 18
    if hit then
      icon(hit.icon, 16, y, 46, hit.name, plain(hit.why))
      local h = T(hit.name .. "  " .. rank .. "/" .. hit.max, 74, y, W - 100, "head", C.ink)
      T(hit.tree, 74, y + h + 2, W - 100, "small", C.inkSoft)
      y = y + math.max(50, h + 20)
      y = y + T(plain(text), 16, y, W - 32, "body", C.ink) + 14
    end
  else
    T("YOUR TALENT POINT", 16, y, 300, "label", C.inkSoft)
    y = y + 18
    y = y + T("Talents start at level 10. Until then, train every new spell and rank.", 16, y, W - 32, "body", C.ink) + 14
  end
  box(0, top, W, y - top, C.parch, C.edge)
  y = y + 12

  -- Next talents strip, with a test button for this level's banner
  local stripTop = y
  if V < 60 and V >= 9 then
    T("NEXT", 0, y + 8, 60, "label", C.goldDim)
    local x = 52
    for l = V + 1, math.min(V + 2, 60) do
      local h2, r2 = ns.talentAt(l)
      if h2 then
        icon(h2.icon, x, y, 28, l .. ": " .. h2.name .. " " .. r2 .. "/" .. h2.max, plain(l == h2.from and h2.why or h2.more))
        T(l .. "  " .. h2.name .. " " .. r2 .. "/" .. h2.max, x + 34, y + 7, 140, "small", C.light)
        x = x + 178
      end
    end
  end
  btn("Test level-up", W - 120, stripTop + 2, 120, function() testBanner(V) end, false,
    "See the level-up banner for level " .. V .. ". Drag it to move it; change its size in Settings; right-click to close.")
  y = stripTop + 40

  -- Trainer card (dark)
  top = y
  y = y + 12
  local t = ns.trainAt(V)
  local n = ns.nextTrain(V)
  if t then
    T("AT YOUR TRAINER NOW", 16, y, 300, "label", C.gold)
    y = y + 20
    y = y + spellIconsGrid(t, y, 16, W - 32, true)
  elseif n then
    T("NEXT TRAINER VISIT  -  LEVEL " .. n.level, 16, y, W - 32, "label", C.gold)
    y = y + 20
    y = y + spellIconsGrid(n, y, 16, W - 32, true)
  end
  y = y + 6
  box(0, top, W, y - top, C.panel, C.edge)
  y = y + 14

  -- Macros card
  top = y
  y = y + 12
  local list = ns.macrosFor(V)
  T("YOUR MACROS AT LEVEL " .. V, 16, y, 300, "label", C.gold)
  btn("Set up macros", W - 156, y - 4, 140, function() ns.setupMacros(false) end, true,
    "Creates or updates this character's macros for your current level.")
  y = y + 24
  for _, m in ipairs(list) do
    icon(m.icon, 16, y, 26, m.name, m.tips and plain(table.concat(m.tips, "\n")) or nil)
    T(m.name, 50, y + 5, 170, "body", C.light)
    local x = 220
    if m.pad ~= "" then x = x + chip(padText(m.pad), x, y + 4, true) + 6 end
    if m.kb ~= "" then chip("Key " .. plain(m.kb), x, y + 4, false) end
    y = y + 32
  end
  if #list == 0 then y = y + T("No macros yet at this level.", 16, y, W - 32, "body", C.dim) + 6 end
  y = y + 4
  box(0, top, W, y - top, C.panel, C.edge)
  return y + 10
end

renderers.talents = function(V)
  local y = sectionTitle("Talent order", 0, "hover for why  -  click to view a level")
  local me = UnitLevel("player")
  for l = 10, 60 do
    local hit, rank, text = ns.talentAt(l)
    if hit then
      if l == V then rect(0, y, W, 28, { C.accent[1], C.accent[2], C.accent[3], 0.18 }, nil, 2) end
      if l == me then rect(0, y, 3, 28, C.edge, "border") end
      T(tostring(l), 8, y + 7, 30, "label", l <= me and C.goldDim or C.gold, "RIGHT")
      icon(hit.icon, 46, y + 2, 24, hit.name, plain(text))
      T(hit.name .. "  " .. rank .. "/" .. hit.max, 80, y + 7, 330, "body", l < me and C.dim or C.light)
      T(hit.tree, 0, y + 8, W - 10, "small", C.dim, "RIGHT")
      local hb = take("hit", newHit)
      hb:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y); hb:SetSize(W, 28)
      hb.tipTitle = "Level " .. l .. ": " .. hit.name .. " " .. rank .. "/" .. hit.max
      hb.tipText = plain(text)
      hb:SetScript("OnClick", function() viewLevel = l; activeTab = "level"; refresh() end)
      hb:SetFrameLevel(content:GetFrameLevel() + 1)
      y = y + 30
    end
  end
  return y + 8
end

renderers.trainer = function(V)
  local y = sectionTitle("Trainer visits", 0, "every new spell and rank, by level")
  local me = UnitLevel("player")
  local list = {}
  for _, t in ipairs(ns.D.train) do list[#list + 1] = t end
  table.sort(list, function(a, b) return a.level < b.level end)
  for _, t in ipairs(list) do
    local here = t.level == V
    local done = t.level <= me and not here
    local top = y
    y = y + 10
    T("LEVEL " .. t.level .. (here and "  -  THIS LEVEL" or (done and "  -  done" or "")), 14, y, W - 28, "label", here and C.ink or (done and C.dim or C.gold))
    y = y + 18
    y = y + spellIconsGrid(t, y, 14, W - 28, not here) + 4
    box(0, top, W, y - top, here and C.parch or C.panel, here and C.edge or C.edgeSoft)
    y = y + 8
  end
  return y
end

renderers.macros = function(V)
  local y = sectionTitle("Macros for level " .. V, 0, "hover the icon for how it works")
  y = y + T("Press Set up macros to create them all at once (they go in the character tab of Esc > Macros), then drag each onto the button or key shown.", 0, y, W - 160, "small", C.dim)
  btn("Set up macros", W - 140, y - 30, 140, function() ns.setupMacros(false) end, true,
    "Creates or updates this character's macros for your current level (" .. UnitLevel("player") .. ").")
  y = y + 10
  for _, m in ipairs(ns.macrosFor(V)) do
    local top = y
    y = y + 12
    icon(m.icon, 14, y, 36, m.name, nil)
    T(m.name, 60, y, 300, "head", C.gold)
    T("Levels " .. m.lo .. "-" .. m.hi, 60, y + 22, 200, "small", C.dim)
    btn("Copy", W - 78, y, 64, function() ns.showMacroCopy(m) end, false,
      "Shows the macro text ready to copy, for making it yourself in Esc > Macros.")
    local cx = 300
    if m.pad ~= "" then cx = cx + chip("Controller " .. padText(m.pad), cx, y + 2, true) + 6 end
    if m.kb ~= "" then chip("Keyboard " .. plain(m.kb), 300, y + 24, false) end
    y = y + 46
    local codeTop = y
    local h = T(m.body, 22, y + 8, W - 44, "mono", C.codeInk)
    rect(14, codeTop, W - 28, h + 16, C.code, nil, 3)
    y = y + h + 24
    for _, line in ipairs(m.tips or {}) do
      y = y + T("-  " .. padText(line), 22, y, W - 44, "small", C.light) + 4
    end
    y = y + 8
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 10
  end
  local soon = ns.comingMacros(V)
  if #soon > 0 then
    local s = {}
    for i = 1, math.min(#soon, 6) do s[#s + 1] = soon[i].name .. " at " .. soon[i].lo end
    y = y + T("Coming up:  " .. table.concat(s, ",  "), 0, y, W, "small", C.dim) + 6
  end
  return y
end

renderers.tips = function(V)
  local b = ns.bracketFor(V)
  if not b then return T("No tips for this level yet.", 0, 0, W, "body", C.dim) end
  local y = 0
  local top = y
  y = y + 16
  T(plain(b.range):upper(), 18, y, W - 36, "label", C.inkSoft)
  y = y + 16
  y = y + T(plain(b.title), 18, y, W - 36, "title", C.ink) + 8
  y = y + T(padText(b.intro), 18, y, W - 36, "body", C.ink) + 14
  for i, step in ipairs(b.steps) do
    icon(b.stepIcons and b.stepIcons[i], 18, y, 26, nil, nil)
    local h = T(padText(step), 54, y + 4, W - 74, "body", C.ink)
    y = y + math.max(30, h + 10)
  end
  y = y + 8
  box(0, top, W, y - top, C.parch, C.edge)
  return y + 10
end

renderers.settings = function()
  local db = LevelingCodexDB
  local toast = ns.getToast()
  local y = sectionTitle("Settings", 0)
  if ns.settingsLost then
    local top = y
    y = y + 10
    y = y + T("Your settings from last time didn't load. WoW: Forever doesn't always load addon settings yet, so the defaults are in use. Set them again here if you like; the Codex works the same either way, and your macros still update.",
      14, y, W - 28, "small", C.ink) + 10
    box(0, top, W, y - top, C.parch, C.edge)
    y = y + 14
  end
  local function row(label, x, w, on, fn, tip) btn(label, x, y, w, function() fn(); refresh() end, on, tip) end
  local function head(str) T(str, 0, y, W, "label", C.gold); y = y + 20 end

  head("THEME")
  local th = db.theme or "forever"
  row("Forever (teal)", 0, 150, th == "forever", function() db.theme = "forever"; ns.rebuildForTheme() end,
    "The WoW: Forever look: logo teal, sky blue and cream.")
  row("Codex (gold)", 156, 150, th == "codex", function() db.theme = "codex"; ns.rebuildForTheme() end,
    "The guide site's look: gold, leather and parchment.")
  y = y + 40

  head("CONTROLLER BUTTON NAMES")
  local p = db.pad or "xbox"
  row("Xbox", 0, 120, p == "xbox", function() db.pad = "xbox" end)
  row("PlayStation", 126, 120, p == "ps", function() db.pad = "ps" end)
  row("Switch", 252, 120, p == "switch", function() db.pad = "switch" end)
  y = y + 40

  head("LEVEL-UP BANNER")
  row(db.noToast and "Banner: Off" or "Banner: On", 0, 140, not db.noToast, function() db.noToast = not db.noToast end)
  row("Test level-up", 146, 100, toast and toast.testing, function()
    local t = ns.getToast()
    if t and t.unlocked then ns.setToastUnlocked(false) end
    testBanner(viewLevel or UnitLevel("player"))
  end, "Plays a level-up for the level shown in the header and keeps the banner up: drag it where you want it, change its size below, right-click it to close.")
  local unlocked = toast and toast.unlocked
  row(unlocked and "Lock banner" or "Move banner", 252, 120, unlocked, function()
    local t = ns.getToast()
    ns.setToastUnlocked(not (t and t.unlocked))
  end, "Shows the banner so you can drag it anywhere. Press again to lock it there.")
  row("Reset", 378, 80, false, function() db.toastPos = nil; db.toastScale = 1; ns.placeToast() end)
  y = y + 32
  T("Size", 0, y + 5, 60, "body", C.light)
  row("-", 60, 28, false, function() db.toastScale = math.max(0.5, (db.toastScale or 1) - 0.1); ns.placeToast() end)
  T(math.floor((db.toastScale or 1) * 100 + 0.5) .. "%", 92, y + 5, 50, "body", C.gold, "CENTER")
  row("+", 146, 28, false, function() db.toastScale = math.min(2, (db.toastScale or 1) + 0.1); ns.placeToast() end)
  y = y + 44

  head("MESSAGES AND MACROS")
  row(db.quiet and "Level-up chat: Off" or "Level-up chat: On", 0, 180, not db.quiet, function() db.quiet = not db.quiet end)
  row(db.noAutoMacros and "Auto-update macros: Off" or "Auto-update macros: On", 186, 200, not db.noAutoMacros,
    function() db.noAutoMacros = not db.noAutoMacros end,
    "After a level-up, macros the Codex made switch to the right version for your new level. Your own macros are never touched.")
  y = y + 44

  head("TALENT WINDOW GUIDE")
  row(db.noTalentGuide and "Trace my talent: Off" or "Trace my talent: On", 0, 200, not db.noTalentGuide,
    function() db.noTalentGuide = not db.noTalentGuide end,
    "When you open your talent window, the Codex traces the talent to take for your level and shows a card above the window.")
  y = y + 44

  head("MINIMAP BUTTON")
  row(db.noMinimap and "Minimap button: Off" or "Minimap button: On", 0, 180, not db.noMinimap,
    function() db.noMinimap = not db.noMinimap; ns.updateMini() end,
    "Drag the book icon around the edge of the minimap to put it where you like; it remembers the spot.")
  row("Reset position", 186, 140, false, function() db.minimapAngle = nil; ns.updateMini() end)
  y = y + 44

  head("THIS WINDOW")
  T("Size", 0, y + 5, 60, "body", C.light)
  row("-", 60, 28, false, function() db.windowScale = math.max(0.6, (db.windowScale or 1) - 0.1); ns.placeWindow() end)
  T(math.floor((db.windowScale or 1) * 100 + 0.5) .. "%", 92, y + 5, 50, "body", C.gold, "CENTER")
  row("+", 146, 28, false, function() db.windowScale = math.min(1.6, (db.windowScale or 1) + 0.1); ns.placeWindow() end)
  row("Reset position", 186, 140, false, function() db.windowPos = nil; ns.placeWindow() end)
  y = y + 44
  T("Drag the window by its header to move it. /codex reset puts the window and banner back where they started.", 0, y, W, "small", C.dim)
  return y + 30
end

----------------------------------------------------------------------------
-- Frame
----------------------------------------------------------------------------

local TABS = {
  { "level", "This Level" }, { "talents", "Talents" }, { "trainer", "Trainer" },
  { "macros", "Macros" }, { "tips", "Tips" }, { "settings", "Settings" },
}

function ns.placeWindow()
  if not frame then return end
  local db = ns.db()
  local p = db.windowPos
  frame:SetScale(db.windowScale or 1)
  frame:ClearAllPoints()
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER") end
end

refresh = function()
  if not (frame and frame:IsShown() and ns.D) then return end
  local me = UnitLevel("player")
  viewLevel = viewLevel or me
  if viewLevel < 1 then viewLevel = 1 elseif viewLevel > 60 then viewLevel = 60 end
  levelText:SetText("Level " .. viewLevel)
  nowBtn:SetLook(viewLevel == me)
  nowBtn.label:SetText(viewLevel == me and "You" or "Back to " .. me)
  for _, t in ipairs(tabs) do
    local on = t.key == activeTab
    t.label:SetTextColor(rgba(on and C.gold or C.dim))
    t.line:SetShown(on)
  end
  -- remember where the tab we're leaving (or redrawing) was scrolled to
  if shownTab then scrollPos[shownTab] = scroll:GetVerticalScroll() or 0 end
  releaseAll()
  local h = renderers[activeTab](viewLevel) or 0
  content:SetHeight(math.max(h, 10))
  shownTab = activeTab
  if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
  local want = scrollPos[activeTab] or 0
  local range = scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange() or want
  scroll:SetVerticalScroll(math.max(0, math.min(want, range or 0)))
end
ns.refresh = refresh

-- Double gold border drawn on a frame, like the guide's panels.
local function doubleBorder(f)
  local function line(p1, p2, horiz, inset, a)
    local t = f:CreateTexture(nil, "BORDER")
    t:SetColorTexture(C.edge[1], C.edge[2], C.edge[3], a)
    t:SetPoint(p1, inset * (p1:find("LEFT") and 1 or -1), inset * (p1:find("TOP") and -1 or 1))
    t:SetPoint(p2, inset * (p2:find("LEFT") and 1 or -1), inset * (p2:find("TOP") and -1 or 1))
    if horiz then t:SetHeight(1) else t:SetWidth(1) end
  end
  for _, inset in ipairs({ 0, 5 }) do
    local a = inset == 0 and 1 or 0.4
    line("TOPLEFT", "TOPRIGHT", true, inset, a); line("BOTTOMLEFT", "BOTTOMRIGHT", true, inset, a)
    line("TOPLEFT", "BOTTOMLEFT", false, inset, a); line("TOPRIGHT", "BOTTOMRIGHT", false, inset, a)
  end
end

local function closeWithEsc(name)
  if type(UISpecialFrames) ~= "table" then return end
  for _, n in ipairs(UISpecialFrames) do if n == name then return end end
  table.insert(UISpecialFrames, name)
end

-- Controller: B (PAD2) or Back closes the frame; every other button still reaches the game.
-- Only when the client can pass gamepad input on, so we never swallow buttons. Out of combat only.
local function closeWithGamepad(f)
  if not (f.EnableGamePadButton and f.SetPropagateGamePadInput and f.HasScript) then return end
  if not pcall(f.HasScript, f, "OnGamePadButtonDown") then return end
  if not (pcall(f.EnableGamePadButton, f, true) and pcall(f.SetPropagateGamePadInput, f, true)) then return end
  f:SetScript("OnGamePadButtonDown", function(self, button)
    if InCombatLockdown() then return end -- leave input alone in combat
    local close = button == "PAD2" or button == "PADBACK"
    pcall(self.SetPropagateGamePadInput, self, not close)
    if close then self:Hide() end
  end)
  f:HookScript("OnHide", function(self)
    if not InCombatLockdown() then pcall(self.SetPropagateGamePadInput, self, true) end
  end)
end

local function headerButton(parent, label, w)
  local b = styleButton(CreateFrame("Button", nil, parent))
  b:SetSize(w, 24)
  b.label:SetText(label)
  return b
end

local function makeFrame()
  frame = CreateFrame("Frame", "LevelingCodexFrame", UIParent)
  frame:SetSize(640, 620)
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:Hide()
  shownTab = nil -- a new scroll frame: keep the saved offsets, don't read the empty one
  closeWithEsc("LevelingCodexFrame") -- by name, so a rebuilt frame needs no second entry
  closeWithGamepad(frame)

  -- leather background, warm glow at the top, double gold border
  local bg = frame:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(rgba(C.bg))
  -- the game's own stone texture, tinted warm, under a dark wash: reads as worn leather
  local rock = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
  rock:SetAllPoints()
  if rock:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT") ~= false then
    if rock.SetHorizTile then rock:SetHorizTile(true); rock:SetVertTile(true) end
    rock:SetVertexColor(rgba(C.rock))
    bg:SetColorTexture(rgba(C.wash))
  else
    rock:Hide()
  end
  local vignette = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
  vignette:SetPoint("BOTTOMLEFT"); vignette:SetPoint("BOTTOMRIGHT"); vignette:SetHeight(160)
  ns.fade(vignette, "VERTICAL", 0, 0, 0, 0.45, 0)
  local glow = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  glow:SetPoint("TOPLEFT"); glow:SetPoint("TOPRIGHT"); glow:SetHeight(140)
  ns.fade(glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.3)
  doubleBorder(frame)

  -- header (drag here to move)
  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", 6, -6); header:SetPoint("TOPRIGHT", -6, -6); header:SetHeight(70)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() frame:StartMoving() end)
  header:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    local p1, _, p2, x, y = frame:GetPoint(1)
    ns.db().windowPos = { p1, p2, x, y }
  end)

  local ring = header:CreateTexture(nil, "BORDER")
  ring:SetSize(50, 50); ring:SetPoint("LEFT", 14, -2); ring:SetColorTexture(rgba(C.edge))
  local crest = header:CreateTexture(nil, "ARTWORK")
  crest:SetPoint("TOPLEFT", ring, "TOPLEFT", 2, -2); crest:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", -2, 2)
  crest:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local _, token = UnitClass("player")
  ns.setIcon(crest, "classicon_" .. string.lower(token or "warrior"))

  local kicker = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  kicker:SetPoint("TOPLEFT", ring, "TOPRIGHT", 12, -2)
  kicker:SetTextColor(rgba(C.goldDim))
  kicker:SetText("WOW: FOREVER  -  LEVELING 1-60")
  local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", kicker, "BOTTOMLEFT", 0, -2)
  title:SetFont(FONT_HEAD, 26, "")
  title:SetTextColor(rgba(C.titleInk))
  title:SetShadowOffset(1, -1)
  title:SetText("The Leveling Codex")
  local spec = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  spec:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
  spec:SetTextColor(rgba(C.dim))
  spec:SetText(ns.D.spec .. " " .. ns.CLASS_NAME)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  -- level picker: view any level
  local nextB = headerButton(header, ">", 26); nextB:SetPoint("RIGHT", -40, -6)
  levelText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  levelText:SetFont(FONT_HEAD, 18, "")
  levelText:SetTextColor(rgba(C.gold))
  levelText:SetWidth(90); levelText:SetJustifyH("CENTER")
  levelText:SetPoint("RIGHT", nextB, "LEFT", -4, 0)
  local prevB = headerButton(header, "<", 26); prevB:SetPoint("RIGHT", levelText, "LEFT", -4, 0)
  nowBtn = headerButton(header, "You", 90); nowBtn:SetPoint("TOP", levelText, "BOTTOM", 0, -4)
  prevB:SetScript("OnClick", function() viewLevel = math.max(1, (viewLevel or 1) - 1); refresh() end)
  nextB:SetScript("OnClick", function() viewLevel = math.min(60, (viewLevel or 1) + 1); refresh() end)
  nowBtn:SetScript("OnClick", function() viewLevel = UnitLevel("player"); refresh() end)
  prevB.tipTitle, prevB.tipText = "Previous level", "Browse the guide at any level."
  nextB.tipTitle, nextB.tipText = "Next level", "Browse the guide at any level."

  local divider = frame:CreateTexture(nil, "BORDER")
  divider:SetPoint("TOPLEFT", 16, -82); divider:SetPoint("TOPRIGHT", -16, -82); divider:SetHeight(1)
  ns.fadeAccent(divider, "HORIZONTAL", 0.2, 0.9)

  -- tabs
  tabs = {}
  local x = 18
  for _, t in ipairs(TABS) do
    local b = CreateFrame("Button", nil, frame)
    b:SetHeight(26)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetText(t[2])
    local w = b.label:GetStringWidth() + 22
    b:SetWidth(w)
    b:SetPoint("TOPLEFT", x, -88)
    b.line = b:CreateTexture(nil, "ARTWORK")
    b.line:SetPoint("BOTTOMLEFT", 6, 0); b.line:SetPoint("BOTTOMRIGHT", -6, 0); b.line:SetHeight(2)
    b.line:SetColorTexture(rgba(C.edge))
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.08)
    b.key = t[1]
    b:SetScript("OnClick", function() activeTab = t[1]; refresh() end)
    tabs[#tabs + 1] = b
    x = x + w + 4
  end

  scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 18, -124)
  scroll:SetPoint("BOTTOMRIGHT", -34, 16)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(W, 10)
  scroll:SetScrollChild(content)

  frame:SetScript("OnShow", function() viewLevel = viewLevel or UnitLevel("player"); refresh() end)
  ns.placeWindow()
end

----------------------------------------------------------------------------
-- Copy a macro: the body in a text box, already selected, for when CreateMacro fails
-- (slots full, combat lockdown) or the player wants to make it themselves.
----------------------------------------------------------------------------

local copy

local function makeCopy()
  copy = CreateFrame("Frame", "LevelingCodexCopy", UIParent)
  copy:SetSize(480, 318)
  copy:SetFrameStrata("FULLSCREEN_DIALOG")
  copy:SetMovable(true)
  copy:EnableMouse(true)
  copy:SetClampedToScreen(true)
  copy:RegisterForDrag("LeftButton")
  copy:SetScript("OnDragStart", function(self) self:StartMoving() end)
  copy:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  copy:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  copy:Hide()
  closeWithEsc("LevelingCodexCopy")
  closeWithGamepad(copy)

  local bg = copy:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(rgba(C.bg))
  local glow = copy:CreateTexture(nil, "BACKGROUND", nil, 1)
  glow:SetPoint("TOPLEFT"); glow:SetPoint("TOPRIGHT"); glow:SetHeight(90)
  ns.fade(glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.3)
  doubleBorder(copy)

  copy.title = copy:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  copy.title:SetPoint("TOPLEFT", 20, -18)
  copy.title:SetFont(FONT_HEAD, 20, "")
  copy.title:SetTextColor(rgba(C.titleInk))
  copy.title:SetShadowOffset(1, -1)
  copy.help = copy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  copy.help:SetPoint("TOPLEFT", copy.title, "BOTTOMLEFT", 0, -6)
  copy.help:SetWidth(440); copy.help:SetJustifyH("LEFT"); copy.help:SetWordWrap(true)
  copy.help:SetTextColor(rgba(C.dim))
  copy.help:SetText("The text is selected: press Ctrl+C (Cmd+C on a Mac). Then in Esc > Macros click New, " ..
    "choose the character tab, name it, and paste with Ctrl+V into the macro box.")

  local well = copy:CreateTexture(nil, "BORDER")
  well:SetPoint("TOPLEFT", 16, -88); well:SetPoint("BOTTOMRIGHT", -16, 52)
  well:SetColorTexture(rgba(C.code))

  local eb = CreateFrame("EditBox", nil, copy)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetFontObject("GameFontHighlight")
  pcall(eb.SetFont, eb, FONT_MONO, 13, "")
  if eb.SetTextColor then eb:SetTextColor(rgba(C.codeInk)) end
  eb:SetPoint("TOPLEFT", 24, -96)
  eb:SetSize(432, 160)
  eb:SetMaxLetters(0)
  local function reselect(self) self:SetFocus(); self:HighlightText() end
  eb:SetScript("OnEscapePressed", function() copy:Hide() end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  -- read-only: typing puts the macro back, still selected
  eb:SetScript("OnTextChanged", function(self, userInput)
    if userInput and copy.body and self:GetText() ~= copy.body then self:SetText(copy.body); self:HighlightText() end
  end)
  eb:SetScript("OnMouseUp", reselect)
  copy.edit = eb

  copy.count = copy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  copy.count:SetPoint("BOTTOMLEFT", 22, 22)
  copy.count:SetTextColor(rgba(C.dim))

  local function button(label, w, onClick)
    local b = styleButton(CreateFrame("Button", nil, copy))
    b:SetSize(w, 24)
    b.label:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
  end
  copy.done = button("Done", 90, function() copy:Hide() end)
  copy.done:SetPoint("BOTTOMRIGHT", -18, 16)
  copy.done:SetLook(true)
  copy.nextB = button("Next", 70, function() ns.showMacroCopy(nil, nil, 1) end)
  copy.nextB:SetPoint("RIGHT", copy.done, "LEFT", -6, 0)
  copy.prevB = button("Back", 70, function() ns.showMacroCopy(nil, nil, -1) end)
  copy.prevB:SetPoint("RIGHT", copy.nextB, "LEFT", -6, 0)
  local close = CreateFrame("Button", nil, copy, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  copy:HookScript("OnHide", function(self) self.edit:ClearFocus() end) -- give the keyboard back
end

-- Show one macro (m), optionally as part of a list (the ones that couldn't be made);
-- step = 1 / -1 moves through that list.
function ns.showMacroCopy(m, list, step)
  if not copy then makeCopy() end
  if m then
    copy.list = list or { m }
    copy.index = 1
    for i, x in ipairs(copy.list) do if x == m then copy.index = i end end
  elseif step and copy.list then
    copy.index = (copy.index - 1 + step) % #copy.list + 1
  end
  local cur = copy.list and copy.list[copy.index]
  if not cur then return end
  local many = #copy.list > 1
  copy.title:SetText("Copy the " .. cur.name .. " macro")
  copy.count:SetText(many and ("Macro " .. copy.index .. " of " .. #copy.list .. " that couldn't be made") or "")
  copy.nextB:SetShown(many); copy.prevB:SetShown(many)
  copy.body = cur.body
  copy:Show()
  copy.edit:SetText(cur.body)
  copy.edit:SetFocus()
  copy.edit:HighlightText()
end

function ns.toggleWindow()
  if not ns.D then
    ns.say("no guide for your class yet.")
    return
  end
  if not frame then makeFrame() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end

-- Theme change: rebuild the window (and drop the banner) in the new colours.
function ns.rebuildForTheme()
  ns.useTheme(ns.db().theme)
  ns.dropToast()
  if copy then copy:Hide(); copy = nil end
  if frame then
    frame:Hide(); frame = nil
    for _, p in pairs(pools) do for i = 1, #p.list do p.list[i]:Hide() end end
    pools = {}
    makeFrame()
    frame:Show()
  end
end

function ns.openTab(tab)
  if not ns.D then return end
  if not frame then makeFrame() end
  activeTab = tab
  if frame:IsShown() then refresh() else frame:Show() end
end
