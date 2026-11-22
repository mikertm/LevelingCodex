-- Art.lua: Blizzard frame art with safe fallbacks.
--
-- Everything here uses art the game has shipped since vanilla (dialog borders, the gold title
-- banner, red panel buttons, check boxes, character-sheet tabs, tooltip borders). Forever's
-- texture list isn't documented and a missing texture renders green, so every file is probed
-- first (SetTexture returns false for a missing file) and each piece falls back to the flat
-- Codex look. /codex debug lists what loaded (ns.art.report).

local _, ns = ...
local C, rgba = ns.C, ns.rgba

local A = { report = {} }
ns.art = A

A.FILES = {
  dialogEdge  = "Interface\\DialogFrame\\UI-DialogBox-Border",
  dialogBg    = "Interface\\DialogFrame\\UI-DialogBox-Background",
  dialogDark  = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  header      = "Interface\\DialogFrame\\UI-DialogBox-Header",
  tipEdge     = "Interface\\Tooltips\\UI-Tooltip-Border",
  tipBg       = "Interface\\Tooltips\\UI-Tooltip-Background",
  tabActive   = "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab",
  tabInactive = "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab",
  tabGlow     = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",
  prevUp      = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
  prevDown    = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down",
  nextUp      = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
  nextDown    = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down",
  squareGlow  = "Interface\\Buttons\\ButtonHilight-Square",
  slot        = "Interface\\Buttons\\UI-Quickslot2",
  white       = "Interface\\Buttons\\WHITE8X8",
  classCircles = "Interface\\TargetingFrame\\UI-Classes-Circles",
  circle      = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", -- a white disc
  parchment   = "Interface\\QuestFrame\\QuestBG",
  checkTick   = "Interface\\Buttons\\UI-CheckBox-Check",
  plusUp      = "Interface\\Buttons\\UI-PlusButton-Up",
  minusUp     = "Interface\\Buttons\\UI-MinusButton-Up",
  questBook   = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
  closeUp     = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up",
}

-- Does the client have this file? (cached; probed on a hidden texture)
local probeTex
local known = {}
function A.hasFile(path)
  if not path then return false end
  if known[path] == nil then
    if not probeTex then
      local f = CreateFrame("Frame")
      f:Hide()
      probeTex = f:CreateTexture()
    end
    local ok, r = pcall(probeTex.SetTexture, probeTex, path)
    known[path] = (ok and r ~= false) and true or false
  end
  return known[path]
end

function A.hasAtlas(name)
  if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
  local ok, info = pcall(C_Texture.GetAtlasInfo, name)
  return ok and info ~= nil
end

local function note(role, state) A.report[role] = state end

-- Put a role's file on a texture. Returns true if the art was used.
function A.set(tex, role, coords)
  local path = A.FILES[role]
  if A.hasFile(path) and tex:SetTexture(path) ~= false then
    if coords then tex:SetTexCoord(unpack(coords)) else tex:SetTexCoord(0, 1, 0, 1) end
    note(role, "ok")
    return true
  end
  note(role, "missing")
  return false
end

----------------------------------------------------------------------------
-- Frames with Blizzard borders
----------------------------------------------------------------------------

-- Modern clients only allow SetBackdrop on frames made with BackdropTemplate.
function A.frame(kind, name, parent)
  if BackdropTemplateMixin then
    local ok, f = pcall(CreateFrame, kind, name, parent, "BackdropTemplate")
    if ok and f then return f end
  end
  return CreateFrame(kind, name, parent)
end

local BACKDROPS = {
  -- the stone-and-gold dialog border (Game Menu, popups)
  dialog = { bgFile = A.FILES.dialogBg, edgeFile = A.FILES.dialogEdge, tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 } },
  -- the tooltip border (thin, takes a tint)
  tooltip = { bgFile = A.FILES.tipBg, edgeFile = A.FILES.tipEdge, tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 } },
}

-- The external UI theme (skin adapter) draws no Blizzard art: the Codex's flat look in its colours,
-- with external UI's own pieces on the windows' backing frames.
local function eui() return ns.skinSupport and ns.skinSupport.on() end

-- Returns true when the Blizzard border was applied. In the external UI theme it takes off a border
-- it put on earlier (a frame made before a theme switch) and returns false.
function A.backdrop(f, kind, bg, edge)
  if eui() then
    if f.codexBackdrop and f.SetBackdrop then pcall(f.SetBackdrop, f, nil) end
    f.codexBackdrop = nil
    return false
  end
  local b = BACKDROPS[kind]
  if not (b and f.SetBackdrop and A.hasFile(b.edgeFile) and A.hasFile(b.bgFile)) then
    note("backdrop " .. kind, "missing")
    return false
  end
  if not pcall(f.SetBackdrop, f, b) then
    note("backdrop " .. kind, "failed")
    return false
  end
  if bg and f.SetBackdropColor then f:SetBackdropColor(rgba(bg)) end
  if edge and f.SetBackdropBorderColor then f:SetBackdropBorderColor(rgba(edge)) end
  f.codexBackdrop = kind
  note("backdrop " .. kind, "ok")
  return true
end

-- A card's frame (the trainer, talent, crafting and vendor cards, the talent trace's tag): the tooltip
-- border, else a flat fill with 1 px edges (h.bg, h.edges: always made, so painting them is safe); in
-- the external UI theme its panel on a backing frame instead. Call it again before each paint: it
-- follows a theme switch (h.blizz = the tooltip border is on) and puts the card's text in the theme's
-- fonts (a heading marks itself with fs.codexHead = its size).
function A.cardChrome(h)
  if h.chromeFor ~= ns.themeVersion then
    h.chromeFor = ns.themeVersion
    local skinned = ns.skinSupport.backing(h, "Panel")
    h.blizz = A.backdrop(h, "tooltip")
    if not h.bg then
      h.bg = h:CreateTexture(nil, "BACKGROUND"); h.bg:SetAllPoints()
      h.edges = {}
      for i = 1, 4 do h.edges[i] = h:CreateTexture(nil, "BORDER") end
      h.edges[1]:SetPoint("TOPLEFT"); h.edges[1]:SetPoint("TOPRIGHT"); h.edges[1]:SetHeight(1)
      h.edges[2]:SetPoint("BOTTOMLEFT"); h.edges[2]:SetPoint("BOTTOMRIGHT"); h.edges[2]:SetHeight(1)
      h.edges[3]:SetPoint("TOPLEFT"); h.edges[3]:SetPoint("BOTTOMLEFT"); h.edges[3]:SetWidth(1)
      h.edges[4]:SetPoint("TOPRIGHT"); h.edges[4]:SetPoint("BOTTOMRIGHT"); h.edges[4]:SetWidth(1)
    end
    local flat = not h.blizz and not skinned
    h.bg:SetShown(flat)
    for _, e in ipairs(h.edges) do e:SetShown(flat) end
  end
  ns.skinSupport.fonts(h)
end

-- Paint a card in the theme (A.cardChrome first): its border or flat edges, the theme's glow along the
-- top (h.glow), the gold rim round its icon (h.ring) and its kicker (h.label). The external UI theme:
-- its panel, no glow, a black icon edge, the kicker in the accent. `fill`: the tooltip border's fill.
function A.paintCard(h, fill)
  A.cardChrome(h)
  if h.blizz then
    h:SetBackdropColor(rgba(fill or { 0.03, 0.03, 0.05, 0.94 }))
    h:SetBackdropBorderColor(rgba(C.edge))
  else
    h.bg:SetColorTexture(rgba(C.bg))
    for _, e in ipairs(h.edges) do e:SetColorTexture(rgba(C.edge)) end
  end
  if h.glow then
    h.glow:SetShown(not C.eui)
    ns.fade(h.glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.25)
  end
  if h.ring then
    if C.eui then h.ring:SetColorTexture(0, 0, 0, 1) else h.ring:SetColorTexture(0.72, 0.58, 0.3, 0.95) end
  end
  if h.label then
    if C.eui then h.label:SetTextColor(rgba(C.accent)) else h.label:SetTextColor(1, 0.82, 0) end
  end
end

-- The gold title banner across the top edge of a dialog, with its title text. In the external UI
-- theme: no banner, the title in white in the window's top bar.
function A.header(parent, text, width)
  local h = parent:CreateTexture(nil, "ARTWORK")
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if eui() then
    h:Hide()
    fs:SetPoint("TOP", 0, -6)
    fs:SetTextColor(1, 1, 1)
  elseif A.set(h, "header") then
    h:SetSize(width or 320, 64)
    h:SetPoint("TOP", 0, 12)
    fs:SetPoint("TOP", h, "TOP", 0, -14)
    fs:SetTextColor(1, 0.82, 0)
  else
    h:Hide()
    fs:SetPoint("TOP", 0, -10)
    fs:SetTextColor(rgba(C.titleInk))
  end
  fs:SetText(text)
  return h, fs
end

----------------------------------------------------------------------------
-- Tooltips on hover
----------------------------------------------------------------------------

function A.showTip(self)
  if not self.tipTitle or not GameTooltip then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(self.tipTitle, 1, 0.82, 0)
  if self.tipText and self.tipText ~= "" then GameTooltip:AddLine(self.tipText, 1, 1, 1, true) end
  GameTooltip:Show()
end
function A.hideTip() if GameTooltip then GameTooltip:Hide() end end

local function hoverTips(b)
  if b.HookScript then
    b:HookScript("OnEnter", A.showTip)
    b:HookScript("OnLeave", A.hideTip)
  else
    b:SetScript("OnEnter", A.showTip); b:SetScript("OnLeave", A.hideTip)
  end
end

----------------------------------------------------------------------------
-- Buttons
----------------------------------------------------------------------------

-- The flat Codex button (fallback when the Blizzard template is missing).
function A.flatButton(b)
  b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
  b.edges = {}
  for i = 1, 4 do b.edges[i] = b:CreateTexture(nil, "BORDER") end
  b.edges[1]:SetPoint("TOPLEFT"); b.edges[1]:SetPoint("TOPRIGHT"); b.edges[1]:SetHeight(1)
  b.edges[2]:SetPoint("BOTTOMLEFT"); b.edges[2]:SetPoint("BOTTOMRIGHT"); b.edges[2]:SetHeight(1)
  b.edges[3]:SetPoint("TOPLEFT"); b.edges[3]:SetPoint("BOTTOMLEFT"); b.edges[3]:SetWidth(1)
  b.edges[4]:SetPoint("TOPRIGHT"); b.edges[4]:SetPoint("BOTTOMRIGHT"); b.edges[4]:SetWidth(1)
  -- external UI's buttons: a subtle white hover, a white label
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
  if C.eui then hl:SetColorTexture(1, 1, 1, 0.1) else hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.16) end
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("CENTER")
  b.SetLabel = function(self, s) self.label:SetText(s) end
  b.SetLook = function(self, on)
    self.bg:SetColorTexture(rgba(on and C.btnOn or C.btnOff))
    for _, e in ipairs(self.edges) do e:SetColorTexture(rgba(C.edge)) end
    self.label:SetTextColor(rgba(on and C.btnOnInk or (C.eui and C.light or C.gold)))
  end
  b:SetLook(false)
  ns.skinSupport.fonts(b)
  return b
end

-- The red Blizzard panel button (the flat button in the external UI theme). SetLabel(text);
-- SetLook(on) keeps a chosen option lit.
function A.button(parent, w, h)
  local ok, b = false, nil
  if not eui() then ok, b = pcall(CreateFrame, "Button", nil, parent, "UIPanelButtonTemplate") end
  if ok and b then
    note("panel button", "ok")
    b.SetLabel = function(self, s) self:SetText(s) end
    b.SetLook = function(self, on)
      if on and self.LockHighlight then self:LockHighlight() elseif self.UnlockHighlight then self:UnlockHighlight() end
      local fs = self.GetFontString and self:GetFontString()
      if fs then
        if on then fs:SetTextColor(1, 1, 1) else fs:SetTextColor(1, 0.82, 0) end
      end
    end
  else
    note("panel button", eui() and "external UI" or "fallback")
    b = A.flatButton(CreateFrame("Button", nil, parent))
  end
  b:SetSize(w or 100, h or 22)
  hoverTips(b)
  return b
end

-- One choice in a row of segments (Window.lua's U.segments). SetLook(true): the red panel button,
-- kept lit, with a 1 px gold inner edge, a gold label and the check box's tick at its left;
-- SetLook(false): a flat dim plate (C.btnOff) with a soft grey label, so it never reads as a
-- disabled button. Where the template has no Left/Middle/Right art to hide, unlit is dimmed.
function A.segment(parent)
  local b = A.button(parent, 100, 24)
  local base = b.SetLook
  b.panelArt = {}
  for _, k in ipairs({ "Left", "Middle", "Right" }) do
    if type(b[k]) == "table" and b[k].SetAlpha then b.panelArt[#b.panelArt + 1] = b[k] end
  end
  if #b.panelArt > 0 then
    b.plate = b:CreateTexture(nil, "BACKGROUND", nil, 1)
    b.plate:SetPoint("TOPLEFT", 1, -1)
    b.plate:SetPoint("BOTTOMRIGHT", -1, 1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.16)
  elseif b.bg then
    b.plate = b.bg -- the flat button: its fill is the plate (C.btnOff unlit, C.btnOn lit)
  end
  -- the lit choice's inner edge and label: gold, or the accent in the external UI theme (no tick there)
  local litInk = C.eui and { C.accent[1], C.accent[2], C.accent[3], 1 } or { 1, 0.82, 0, 1 }
  b.goldEdges = {}
  for i = 1, 4 do
    local e = b:CreateTexture(nil, "OVERLAY")
    e:SetColorTexture(rgba(litInk))
    e:Hide()
    b.goldEdges[i] = e
  end
  local e = b.goldEdges
  e[1]:SetPoint("TOPLEFT", 2, -2); e[1]:SetPoint("TOPRIGHT", -2, -2); e[1]:SetHeight(1)
  e[2]:SetPoint("BOTTOMLEFT", 2, 2); e[2]:SetPoint("BOTTOMRIGHT", -2, 2); e[2]:SetHeight(1)
  e[3]:SetPoint("TOPLEFT", 2, -2); e[3]:SetPoint("BOTTOMLEFT", 2, 2); e[3]:SetWidth(1)
  e[4]:SetPoint("TOPRIGHT", -2, -2); e[4]:SetPoint("BOTTOMRIGHT", -2, 2); e[4]:SetWidth(1)
  if not C.eui and A.hasFile(A.FILES.checkTick) then
    b.tick = b:CreateTexture(nil, "OVERLAY")
    b.tick:SetSize(14, 14)
    b.tick:SetPoint("LEFT", 4, 0)
    b.tick:SetTexture(A.FILES.checkTick)
    b.tick:Hide()
  end
  b.SetLook = function(self, on)
    base(self, on)
    if #self.panelArt > 0 then
      for _, t in ipairs(self.panelArt) do t:SetAlpha(on and 1 or 0) end
      self.plate:SetColorTexture(rgba(C.btnOff))
      self.plate:SetShown(not on)
      self:SetAlpha(1)
    else
      self:SetAlpha((on or self.plate) and 1 or 0.6)
    end
    local fs = self.label or (self.GetFontString and self:GetFontString())
    -- the tick only when the label still fits beside it: a narrow choice ("Auto", "1m") keeps its
    -- label centred inside the button and shows it lit by the gold edge alone
    local roomy = self.tick and true or false
    if roomy and fs and fs.GetStringWidth then
      local bw = tonumber(self.GetWidth and self:GetWidth()) or 0
      local sw = tonumber(fs:GetStringWidth()) or 0
      roomy = bw <= 0 or sw + 2 * 20 <= bw
    end
    if fs then
      if on then fs:SetTextColor(litInk[1], litInk[2], litInk[3]) else fs:SetTextColor(0.75, 0.75, 0.75) end
      -- clear of the tick, which sits at the left edge of a lit choice
      if fs.ClearAllPoints and fs.SetPoint then
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", self, "CENTER", (on and roomy) and 9 or 0, 0)
      end
    end
    for _, edge in ipairs(self.goldEdges) do edge:SetShown(on and true or false) end
    if self.tick then self.tick:SetShown((on and roomy) and true or false) end
  end
  b:SetLook(false)
  return b
end

-- The step window's buttons, in the theme's colours (Repaint() after a theme switch).
-- A small icon button: Blizzard's art alone (it has its own frame) with a hover glow; without the
-- art, a short label on a flat dark plate.
-- In the external UI theme the back arrow and the close art are external UI's page and close buttons.
function A.iconButton(parent, file, fallback)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(28, 24)
  local skin = eui() and ((file == A.FILES.prevUp and "PageButton") or (file == A.FILES.closeUp and "CloseButton"))
  if skin and ns.skinSupport.call(skin, b, "<") then
    hoverTips(b)
    b.Repaint = function() end
    return b
  end
  if A.hasFile(file) then
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(18, 18)
    b.icon:SetPoint("CENTER")
    b.icon:SetTexture(file)
  else
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetText(fallback)
  end
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.12)
  b.Repaint = function(self)
    if self.bg then self.bg:SetColorTexture(rgba(C.btnOff)) end
    if self.label then self.label:SetTextColor(rgba(C.gold)) end
  end
  b:Repaint()
  hoverTips(b)
  return b
end

-- A raised face for the step window's Next step and its offers. SetLabel(text, arrow) can add a ">".
function A.primaryButton(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(120, 24)
  b.rim = b:CreateTexture(nil, "BACKGROUND")
  b.rim:SetAllPoints()
  b.fill = b:CreateTexture(nil, "BORDER")
  b.fill:SetPoint("TOPLEFT", 1, -1)
  b.fill:SetPoint("BOTTOMRIGHT", -1, 2)
  b.shade = b:CreateTexture(nil, "ARTWORK")
  b.shade:SetAllPoints(b.fill)
  ns.fade(b.shade, "VERTICAL", 0, 0, 0, 0.28, 0)
  b.bevel = b:CreateTexture(nil, "ARTWORK", nil, 1)
  b.bevel:SetPoint("TOPLEFT", 1, -1)
  b.bevel:SetPoint("TOPRIGHT", -1, -1)
  b.bevel:SetHeight(1)
  b.bevel:SetColorTexture(1, 1, 1, 0.35)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("CENTER")
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(b.fill)
  hl:SetColorTexture(1, 1, 1, 0.12)
  local pressed = b:CreateTexture(nil, "ARTWORK", nil, 2)
  pressed:SetAllPoints(b.fill)
  pressed:SetColorTexture(0, 0, 0, 0.24)
  pressed:Hide()
  ns.try(b.SetPushedTexture, b, pressed)
  b.SetLabel = function(self, text, arrow) self.label:SetText(arrow and (text .. " >") or text) end
  b.Repaint = function(self)
    self.rim:SetColorTexture(rgba(C.edgeSoft))
    self.fill:SetColorTexture(rgba(C.btnOn))
    self.label:SetTextColor(rgba(C.btnOnInk))
    ns.skinSupport.fonts(self)
  end
  b:Repaint()
  hoverTips(b)
  return b
end

-- Spellbook page arrows (prev / next), or a small panel button with < / >; external UI's page buttons
-- in its theme.
function A.arrow(parent, dir)
  local up, down = A.FILES[dir .. "Up"], A.FILES[dir .. "Down"]
  if eui() then
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(26, 22)
    if ns.skinSupport.call("PageButton", b, dir == "prev" and "<" or ">") then
      b.codexLabel = dir == "prev" and "<" or ">"
      note("page arrows", "external UI")
      hoverTips(b)
      return b
    end
    b:Hide()
  elseif A.hasFile(up) and A.hasFile(down) then
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(28, 28)
    b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetAllPoints(); b.tex:SetTexture(up)
    local glow = b:CreateTexture(nil, "HIGHLIGHT"); glow:SetAllPoints()
    if A.hasFile(A.FILES.squareGlow) then glow:SetTexture(A.FILES.squareGlow); glow:SetBlendMode("ADD")
    else glow:SetColorTexture(1, 1, 1, 0.15) end
    b:SetScript("OnMouseDown", function(self) self.tex:SetTexture(down) end)
    b:SetScript("OnMouseUp", function(self) self.tex:SetTexture(up) end)
    b.codexLabel = dir == "prev" and "<" or ">"
    note("page arrows", "ok")
    hoverTips(b)
    return b
  end
  note("page arrows", "missing")
  local b = A.button(parent, 26, 22)
  b:SetLabel(dir == "prev" and "<" or ">")
  b.codexLabel = dir == "prev" and "<" or ">"
  return b
end

-- A check box with its label on the right (the whole label is clickable).
function A.check(parent)
  local ok, cb = pcall(CreateFrame, "CheckButton", nil, parent, "UICheckButtonTemplate")
  if ok and cb then
    note("check box", "ok")
    for _, k in ipairs({ "text", "Text" }) do
      if type(cb[k]) == "table" and cb[k].SetText then cb[k]:SetText("") end
    end
    cb.SetLook = function(self, on) self:SetChecked(on and true or false) end
    if eui() then ns.skinSupport.call("Checkbox", cb) end -- its dark box and accent tick
  else
    note("check box", "fallback")
    cb = CreateFrame("CheckButton", nil, parent)
    cb.box = cb:CreateTexture(nil, "BACKGROUND"); cb.box:SetPoint("TOPLEFT", 4, -4); cb.box:SetPoint("BOTTOMRIGHT", -4, 4)
    cb.box:SetColorTexture(rgba(C.btnOff))
    cb.mark = cb:CreateTexture(nil, "ARTWORK"); cb.mark:SetPoint("TOPLEFT", 8, -8); cb.mark:SetPoint("BOTTOMRIGHT", -8, 8)
    cb.mark:SetColorTexture(rgba(C.eui and C.accent or C.btnOn))
    cb.SetLook = function(self, on)
      if self.SetChecked then self:SetChecked(on and true or false) end
      self.mark:SetShown(on and true or false)
    end
  end
  cb:SetSize(26, 26)
  cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  cb.SetLabel = function(self, s)
    self.label:SetText(s)
    if self.SetHitRectInsets then pcall(self.SetHitRectInsets, self, 0, -(self.label:GetStringWidth() + 8), 0, 0) end
  end
  ns.skinSupport.fonts(cb)
  hoverTips(cb)
  return cb
end

-- A character-sheet tab hanging below a frame. SetSelected(on).
-- The inactive art fills its 32 px file; the active art is the top 35 of a 64 px file and sits
-- 3 px lower, as in the game's CharacterFrameTabButtonTemplate.
local TAB_X = { { 0, 0.15625 }, { 0.15625, 0.84375 }, { 0.84375, 1 } }
local TAB_BOTTOM = { inactive = 1, active = 0.546875 }
function A.tab(parent, text)
  local b = CreateFrame("Button", nil, parent)
  b:SetHeight(32)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.label:SetText(text)
  local w = math.max(64, b.label:GetStringWidth() + 36)
  b:SetWidth(w)
  local art = A.hasFile(A.FILES.tabActive) and A.hasFile(A.FILES.tabInactive)
  if eui() then
    -- external UI's tab: a flat plate, the accent underlined under the chosen one, a white hover
    note("tabs", "external UI")
    ns.skinSupport.fonts(b)
    b.plate = b:CreateTexture(nil, "BACKGROUND")
    b.plate:SetPoint("TOPLEFT", 1, -6); b.plate:SetPoint("BOTTOMRIGHT", -1, 0)
    b.plate:SetColorTexture(rgba(C.btnOff))
    b.line = b:CreateTexture(nil, "ARTWORK")
    b.line:SetPoint("BOTTOMLEFT", 1, 0); b.line:SetPoint("BOTTOMRIGHT", -1, 0); b.line:SetHeight(2)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 1, -6); hl:SetPoint("BOTTOMRIGHT", -1, 0)
    hl:SetColorTexture(1, 1, 1, 0.08)
    b.SetSelected = function(self, on)
      self.line:SetColorTexture(rgba(C.accent))
      self.line:SetShown(on and true or false)
      self.plate:SetAlpha(on and 1 or 0.75)
      self.label:ClearAllPoints(); self.label:SetPoint("CENTER", self, "CENTER", 0, -3)
      self.label:SetTextColor(rgba(on and C.light or C.dim))
    end
  elseif art then
    note("tabs", "ok")
    b.parts = {}
    for i = 1, 3 do b.parts[i] = b:CreateTexture(nil, "BACKGROUND") end
    -- hover glow: a band around the label (as in the game's tab template), never on the selected tab
    local glow = b:CreateTexture(nil, "HIGHLIGHT")
    glow:SetPoint("LEFT", b.label, "LEFT", -12, 0); glow:SetPoint("RIGHT", b.label, "RIGHT", 12, 0)
    glow:SetHeight(26)
    if A.hasFile(A.FILES.tabGlow) then glow:SetTexture(A.FILES.tabGlow); glow:SetBlendMode("ADD")
    else glow:SetColorTexture(1, 0.82, 0, 0.12) end
    b.glow = glow
    b.SetSelected = function(self, on)
      self.glow:SetShown(not on)
      local L, M, R = self.parts[1], self.parts[2], self.parts[3]
      local file = on and A.FILES.tabActive or A.FILES.tabInactive
      local bottom = on and TAB_BOTTOM.active or TAB_BOTTOM.inactive
      for i, t in ipairs(self.parts) do
        t:SetTexture(file)
        t:SetTexCoord(TAB_X[i][1], TAB_X[i][2], 0, bottom)
        t:ClearAllPoints()
      end
      local dy, h = on and -3 or 0, on and 35 or 32
      L:SetSize(20, h); L:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, dy)
      R:SetSize(20, h); R:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, dy)
      M:SetPoint("TOPLEFT", L, "TOPRIGHT"); M:SetPoint("BOTTOMRIGHT", R, "BOTTOMLEFT")
      self.label:ClearAllPoints()
      self.label:SetPoint("CENTER", self, "CENTER", 0, on and -3 or 2)
      if on then self.label:SetTextColor(1, 1, 1) else self.label:SetTextColor(1, 0.82, 0) end
    end
  else
    note("tabs", "fallback")
    b.line = b:CreateTexture(nil, "ARTWORK")
    b.line:SetPoint("TOPLEFT", 6, 0); b.line:SetPoint("TOPRIGHT", -6, 0); b.line:SetHeight(2)
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.08)
    b.SetSelected = function(self, on)
      self.line:SetColorTexture(rgba(C.edge))
      self.line:SetShown(on)
      self.label:ClearAllPoints(); self.label:SetPoint("CENTER")
      self.label:SetTextColor(rgba(on and C.gold or C.dim))
    end
  end
  b:SetSelected(false)
  return b
end

----------------------------------------------------------------------------
-- Portrait: the class icon in a round gold-rimmed frame, like the game's own windows.
----------------------------------------------------------------------------

local function disc(parent, layer, sub, size, r, g, b)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetSize(size, size)
  if SetPortraitToTexture and A.hasFile(A.FILES.white) and pcall(SetPortraitToTexture, t, A.FILES.white) then
    t:SetVertexColor(r, g, b)
    return t, true
  end
  t:SetColorTexture(r, g, b, 1)
  return t, false
end

function A.portrait(parent, size, token)
  token = string.upper(token or "WARRIOR")
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(size + 8, size + 8)
  local icon = holder:CreateTexture(nil, "ARTWORK")
  holder.icon = icon
  -- 1. the game's round class icons (with their own ring), as on the character select screen
  local coords = type(CLASS_ICON_TCOORDS) == "table" and CLASS_ICON_TCOORDS[token]
  if coords and A.set(icon, "classCircles", { coords[1], coords[2], coords[3], coords[4] }) then
    icon:SetSize(size + 8, size + 8); icon:SetPoint("CENTER")
    note("portrait", "class circle")
    return holder
  end
  -- 2. the class icon made round, on a gold disc
  local path = "Interface\\Icons\\classicon_" .. string.lower(token)
  local rim, round = disc(holder, "BORDER", 0, size + 6, 0.95, 0.76, 0.26)
  local inner = disc(holder, "BORDER", 1, size + 2, 0.08, 0.05, 0.02)
  rim:SetPoint("CENTER"); inner:SetPoint("CENTER")
  icon:SetSize(size, size); icon:SetPoint("CENTER")
  if round and A.hasFile(path) and pcall(SetPortraitToTexture, icon, path) then
    note("portrait", "round icon")
    return holder
  end
  -- 3. a square icon with the same thin gold rim and black edge as every other icon
  rim:SetColorTexture(0.72, 0.58, 0.3, 0.95); rim:SetSize(size + 2, size + 2)
  inner:SetColorTexture(0, 0, 0, 1); inner:SetSize(size, size)
  icon:SetSize(size - 2, size - 2)
  ns.setIcon(icon, "classicon_" .. string.lower(token))
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  note("portrait", "square icon")
  return holder
end

-- Lines for /codex debug.
function A.reportLines()
  local keys = {}
  for k in pairs(A.report) do keys[#keys + 1] = k end
  table.sort(keys)
  local out = {}
  for _, k in ipairs(keys) do out[#out + 1] = k .. ": " .. A.report[k] end
  return out
end
