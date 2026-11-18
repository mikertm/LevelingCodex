-- Window.lua: the /codex window in Blizzard frame art: the dialog border and gold title banner,
-- a round class portrait, character-sheet tabs, red panel buttons, check boxes, and cards with
-- the tooltip border (parchment or dark). Morpheus headings and the theme's accent colour stay.
-- Every piece of art falls back to the flat Codex look when the client lacks it (Art.lua). In the
-- external UI theme (skin adapter) the window is external UI's shell on a backing frame, the inside
-- the flat look in its colours and font.

local _, ns = ...
local C, rgba, plain, padText = ns.C, ns.rgba, ns.plain, ns.padText
local A = ns.art

local FONT_HEAD = "head" -- Morpheus, or the external UI font in its theme (ns.headFont)
local FONT_MONO = "Fonts\\ARIALN.TTF"
local W = 568 -- content width
local tabWidths = {}

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

-- Layers inside the scroll child: Blizzard-bordered cards are frames, so text, icons and
-- buttons live on an overlay frame above them (a parent's own regions draw under its children).
-- `top` sits above the icons, for things drawn on them (controller glyphs, rank badges, hotkeys).
local overlay, top
local function newFS() return overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight") end
local function newTex() return overlay:CreateTexture(nil, "BACKGROUND") end
local function newTexB() return overlay:CreateTexture(nil, "BORDER") end
local function newFSTop() return top:CreateFontString(nil, "OVERLAY", "GameFontHighlight") end
local function newTexTop() return top:CreateTexture(nil, "ARTWORK") end

----------------------------------------------------------------------------
-- Drawing helpers (x, y are offsets from the content's top-left; y grows downwards)
----------------------------------------------------------------------------

-- The face, size and flags of one of the game's font objects (so SetFont can set it exactly).
local fontCache = {}
local function fontOf(objName, size)
  if not fontCache[objName] then
    local o = _G[objName]
    local path, sz, flags
    if type(o) == "table" and o.GetFont then
      local ok, p, s, f = pcall(o.GetFont, o)
      if ok and type(p) == "string" then path, sz, flags = p, s, f end
    end
    fontCache[objName] = { path or "Fonts\\FRIZQT__.TTF", sz or size or 12, flags or "" }
  end
  local f = fontCache[objName]
  return f[1], f[2], f[3]
end

-- Text styles. Every style sets its font explicitly: pooled font strings are reused across tabs,
-- and a font set with SetFont sticks through SetFontObject (that's how Morpheus leaked into notes).
local STYLES = {
  title = { "GameFontNormalHuge", FONT_HEAD, 24 },
  head  = { "GameFontNormalLarge", FONT_HEAD, 18 },
  label = { "GameFontNormalSmall" },
  small = { "GameFontHighlightSmall" },
  mono  = { "GameFontHighlight", FONT_MONO, 13 },
  body  = { "GameFontHighlight" },
}

local function styleFS(fs, kind)
  local st = STYLES[kind] or STYLES.body
  fs:SetFontObject(st[1])
  local path, size, flags = fontOf(st[1], 12)
  local face, fl = st[2] or path, (st[2] and "") or flags or ""
  if face == FONT_HEAD then face = ns.headFont() end
  local eui, euiFlags = ns.skinSupport.font()
  if eui and kind ~= "mono" then face, fl = eui, euiFlags end -- code keeps Arial Narrow
  fs:SetFont(face, st[3] or size, fl)
  local sh = (kind == "head" or kind == "title" or kind == "label") and 1 or 0
  fs:SetShadowOffset(sh, -sh)
  fs:SetSpacing(kind == "mono" and 3 or 2)
  fs:SetWordWrap(true)
  fs:SetJustifyV("TOP")
end

-- Place text at (x, y) in content; returns its height and the font string.
local function T(str, x, y, width, kind, color, justify, onTop)
  local fs = onTop and take("fsTop", newFSTop) or take("fs", newFS)
  fs.codexLabel = nil
  styleFS(fs, kind)
  fs:SetTextColor(rgba(color or C.light))
  fs:SetWidth(width)
  fs:SetJustifyH(justify or "LEFT")
  if fs.SetWordWrap then fs:SetWordWrap(true) end -- a pooled string may have been kept to one line
  fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  fs:SetText(str)
  return fs:GetStringHeight(), fs
end

-- A solid rectangle. `kind` keeps textures that get a fade ("fade") or a rotation ("gem") in their
-- own pools: the client keeps a gradient or rotation through SetColorTexture, so a plain rect must
-- never reuse one (that's what turned macro chips into faded strips and diagonal bars).
local function rect(x, y, w, h, color, layer, sub, kind, onTop)
  local t
  if onTop then
    t = take("texTop" .. (kind or ""), newTexTop)
    t:SetDrawLayer("ARTWORK", sub or 0)
  else
    t = take((layer == "border" and "texB" or "tex") .. (kind or ""), layer == "border" and newTexB or newTex)
    if layer == "border" then t:SetDrawLayer("BORDER", sub or 0) else t:SetDrawLayer("BACKGROUND", sub or 0) end
  end
  t:SetColorTexture(rgba(color))
  t:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  t:SetSize(w, h)
  return t
end

-- Card frames with the game's tooltip border; parchment cards get the quest-log paper.
local function newCard()
  local f = A.frame("Frame", nil, content)
  f.paper = f:CreateTexture(nil, "BORDER")
  f.paper:SetPoint("TOPLEFT", 4, -4); f.paper:SetPoint("BOTTOMRIGHT", -4, 4)
  f.shade = f:CreateTexture(nil, "BORDER", nil, 1)
  f.shade:SetPoint("TOPLEFT", 4, -4); f.shade:SetPoint("BOTTOMRIGHT", -4, 4)
  -- the theme's wash rising from the bottom edge (Forever: the teal of its quest parchment)
  f.glow = f:CreateTexture(nil, "BORDER", nil, 2)
  f.glow:SetPoint("BOTTOMLEFT", 4, 4); f.glow:SetPoint("BOTTOMRIGHT", -4, 4)
  f.blizz = A.backdrop(f, "tooltip")
  f.hasPaper = A.set(f.paper, "parchment", { 0, 0.586, 0, 0.655 })
  return f
end

-- The guide's flat card (when the client has no backdrops): fill, aged shade, double border. In the
-- external UI theme its panel: the fill and a 1 px border, nothing else.
local function flatBox(x, y, w, h, fill, edge)
  rect(x, y, w, h, fill)
  if C.eui then
    edge = edge or C.edge
    rect(x, y, w, 1, edge, "border"); rect(x, y + h - 1, w, 1, edge, "border")
    rect(x, y, 1, h, edge, "border"); rect(x + w - 1, y, 1, h, edge, "border")
    return
  end
  local shade = rect(x, y, w, h, { 1, 1, 1, 1 }, nil, 1, "fade")
  if fill == C.parch then ns.fade(shade, "VERTICAL", 0.5, 0.35, 0.15, 0.22, 0)
  else ns.fade(shade, "VERTICAL", 0.6, 0.45, 0.2, 0, 0.12) end
  edge = edge or C.edge
  rect(x, y, w, 1, edge, "border"); rect(x, y + h - 1, w, 1, edge, "border")
  rect(x, y, 1, h, edge, "border"); rect(x + w - 1, y, 1, h, edge, "border")
  local e2 = { edge[1], edge[2], edge[3], 0.35 }
  rect(x + 4, y + 4, w - 8, 1, e2, "border"); rect(x + 4, y + h - 5, w - 8, 1, e2, "border")
  rect(x + 4, y + 4, 1, h - 8, e2, "border"); rect(x + w - 5, y + 4, 1, h - 8, e2, "border")
end

-- A card: parchment (fill == C.parch) or dark. Drawn under the overlay.
local function box(x, y, w, h, fill, edge)
  if w < 24 or h < 16 then return flatBox(x, y, w, h, fill, edge) end
  local f = take("card", newCard)
  if not f.blizz then f:Hide(); return flatBox(x, y, w, h, fill, edge) end
  f:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  f:SetSize(w, h)
  edge = edge or C.edge
  f.shade:Show()
  if fill == C.parch then
    f:SetBackdropColor(rgba(C.parch))
    f:SetBackdropBorderColor(0.55, 0.42, 0.24, 1)
    f.paper:SetShown(f.hasPaper)
    if f.hasPaper then f.paper:SetVertexColor(1, 0.98, 0.93) end
    ns.fade(f.shade, "VERTICAL", 0.45, 0.3, 0.12, 0.12, 0)
    local g = C.parchGlow or C.accent
    f.glow:SetHeight(math.max(12, math.min(140, (h - 8) * 0.42)))
    ns.fade(f.glow, "VERTICAL", g[1], g[2], g[3], 0.62, 0)
    f.glow:Show()
  else
    f:SetBackdropColor(0, 0, 0, 0.62)
    f:SetBackdropBorderColor(edge[1], edge[2], edge[3], 0.9)
    f.paper:Hide()
    ns.fade(f.shade, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.1)
    f.glow:Hide()
  end
end

-- A small filled plate with a thin border (controller badges, keycaps, rank tags), under the overlay.
local function plate(x, y, w, h, bg, edge)
  local f = take("card", newCard)
  if not f.blizz then
    f:Hide()
    rect(x, y, w, h, bg, "border", 1)
    rect(x, y, w, 1, edge, "border", 2); rect(x, y + h - 1, w, 1, edge, "border", 2)
    rect(x, y, 1, h, edge, "border", 2); rect(x + w - 1, y, 1, h, edge, "border", 2)
    return
  end
  f:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  f:SetSize(w, h)
  f:SetBackdropColor(rgba(bg))
  f:SetBackdropBorderColor(rgba(edge))
  f.paper:Hide(); f.shade:Hide(); f.glow:Hide()
end

-- Loot uses standalone illustrations over solid UI surfaces.
-- Every file can fall back to a plain surface without a missing-texture square.
local function picture(path, x, y, w, h)
  if not A.hasFile(path) then return false end
  local t = take("picture", newTex)
  t:SetDrawLayer("BACKGROUND", 2)
  t:SetTexture(path)
  t:SetTexCoord(0, 1, 0, 1)
  t:SetVertexColor(1, 1, 1, 1)
  t:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y); t:SetSize(w, h)
  return true
end
local function surface(x, y, w, h, bg, edge)
  rect(x,y,w,h,bg)
  edge = edge or C.edgeSoft
  rect(x,y,w,1,edge,"border"); rect(x,y+h-1,w,1,edge,"border")
  rect(x,y,1,h,edge,"border"); rect(x+w-1,y,1,h,edge,"border")
end
local function newFolio()
  local f=CreateFrame("Frame",nil,content)
  f:SetFrameLevel(content:GetFrameLevel()+1)
  f.paper=f:CreateTexture(nil,"BACKGROUND");f.paper:SetAllPoints(f)
  return f
end
local function folio(h,bg,w)
  local f=take("folio",newFolio)
  f:SetPoint("TOPLEFT",content,"TOPLEFT",0,0);f:SetSize(w or W,h)
  f.paper:SetColorTexture(rgba(bg))
end

local showTip, hideTip = A.showTip, A.hideTip

-- Spell icons the way the game draws them: a black edge with a thin gold rim.
local function newIcon()
  local f = CreateFrame("Button", nil, overlay)
  f.ring = f:CreateTexture(nil, "BORDER"); f.ring:SetPoint("TOPLEFT", -1, 1); f.ring:SetPoint("BOTTOMRIGHT", 1, -1)
  f.ring:SetColorTexture(0.72, 0.58, 0.3, 0.9)
  f.edge = f:CreateTexture(nil, "BORDER", nil, 1); f.edge:SetAllPoints(); f.edge:SetColorTexture(0, 0, 0, 1)
  f.tex = f:CreateTexture(nil, "ARTWORK")
  f.tex:SetPoint("TOPLEFT", 1, -1); f.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local hl = f:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
  if A.hasFile(A.FILES.squareGlow) then hl:SetTexture(A.FILES.squareGlow); hl:SetBlendMode("ADD")
  else hl:SetColorTexture(1, 1, 1, 0.12) end
  f:SetScript("OnEnter", showTip); f:SetScript("OnLeave", hideTip)
  return f
end

local function icon(name, x, y, size, title, text)
  local f = take("icon", newIcon)
  f:SetSize(size, size)
  f:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  f:EnableMouse(true) -- a decorative use may have made this pooled icon passive
  ns.setIcon(f.tex, name)
  f.tex:SetDesaturated(false)
  f.tex:SetAlpha(1)
  f.tex:SetVertexColor(1, 1, 1)
  f.ring:SetColorTexture(0.72, 0.58, 0.3, 0.9)
  f:SetScript("OnClick", nil)
  f.tipTitle, f.tipText = title, text
  return f
end

local function newBtn() return A.button(overlay, 100, 22) end

local function btn(label, x, y, w, onClick, on, tip)
  local b = take("btn", newBtn)
  b:SetSize(w, 22)
  b:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  b:SetLabel(label)
  b:SetLook(on)
  b:SetScript("OnClick", onClick)
  b.tipTitle, b.tipText = tip and label or nil, tip
  b.codexLabel = nil -- a caller may name it (steppers); a reused button forgets the old name
  return b
end

-- A row of choices with one lit (A.segment): equal widths, 4 px apart, 24 px tall. `lit` is the
-- chosen index (nil: none), `onPick(i)` runs on a click, `tips[i]` is that choice's tooltip.
local function newSegment() return A.segment(overlay) end
local function segments(x, y, w, labels, lit, onPick, tips)
  local n = #labels
  local each = math.floor((w - 4 * (n - 1)) / n)
  for i, label in ipairs(labels) do
    local b = take("segment", newSegment)
    b:SetSize(each, 24)
    b:SetPoint("TOPLEFT", content, "TOPLEFT", x + (i - 1) * (each + 4), -y)
    b:SetLabel(label)
    b.codexLabel, b.codexOn = label, i == lit
    b:SetLook(i == lit)
    b:SetScript("OnClick", function() onPick(i) end)
    b.tipTitle, b.tipText = tips and tips[i] and label or nil, tips and tips[i] or nil
  end
  return 24
end

-- A check box with its label (for on/off settings).
local function newCheck() return A.check(overlay) end
local function check(label, x, y, on, onClick, tip)
  local cb = take("check", newCheck)
  cb:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  cb:SetLabel(label)
  cb:SetLook(on)
  cb:SetScript("OnClick", onClick)
  cb.tipTitle, cb.tipText = tip and label or nil, tip
  return cb
end

-- An invisible clickable strip (for talent rows).
local function newHit()
  local f = CreateFrame("Button", nil, overlay)
  local hl = f:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.1)
  f:SetScript("OnEnter", showTip); f:SetScript("OnLeave", hideTip)
  return f
end

local function goldRuleAt(y)
  local half = (W - 20) / 2
  local l = rect(0, y, half, 1, { 1, 1, 1, 1 }, "border", nil, "fade"); ns.fadeAccent(l, "HORIZONTAL", 0, 0.8)
  local r = rect(half + 20, y, half, 1, { 1, 1, 1, 1 }, "border", nil, "fade"); ns.fadeAccent(r, "HORIZONTAL", 0.8, 0)
  local g = rect(W / 2 - 4, y - 3, 7, 7, C.gem, "border", nil, "gem")
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
-- Controller and keyboard drawing: glyphs like Forever's gamepad UI, keycaps like a keyboard
----------------------------------------------------------------------------

-- A filled circle (the game makes any texture round with SetPortraitToTexture), else a square.
local function newDisc() return top:CreateTexture(nil, "ARTWORK") end
-- (SetPortraitToTexture can't round a plain white texture in Forever, so it's a round white file.)
local round = nil
local function disc(cx, cy, size, color, sub)
  local t = take("disc", newDisc)
  t:SetDrawLayer("ARTWORK", sub or 0)
  if round == nil then
    round = A.hasFile(A.FILES.circle)
    A.report["round shapes"] = round and "ok" or "square"
  end
  if round then
    t:SetTexture(A.FILES.circle)
    t:SetTexCoord(0, 1, 0, 1)
    t:SetVertexColor(color[1], color[2], color[3])
    t:SetAlpha(color[4] or 1)
  else
    t:SetColorTexture(rgba(color))
    t:SetAlpha(1)
  end
  t:SetSize(size, size)
  t:SetPoint("CENTER", content, "TOPLEFT", cx, -cy)
  return t
end

-- A straight stroke centred on (cx, cy), turned `deg` degrees anticlockwise.
local canTurn = nil
local function bar(cx, cy, len, thick, deg, color, sub)
  local t = take("texTopbar", newTexTop)
  t:SetDrawLayer("ARTWORK", sub or 3)
  t:SetColorTexture(rgba(color))
  t:SetPoint("CENTER", content, "TOPLEFT", cx, -cy)
  if canTurn == nil then canTurn = t.SetRotation ~= nil end
  deg = deg or 0
  if deg == 90 or deg == -90 then
    t:SetSize(thick, len) -- upright strokes need no rotation
    deg = 0
  else
    t:SetSize(len, thick)
  end
  if canTurn then t:SetRotation(math.rad(deg)) end
  return t
end

-- Where each face button sits (by its Xbox letter) and its colour on each controller.
local FACE_POS = { Y = { 0, -1 }, X = { -1, 0 }, B = { 1, 0 }, A = { 0, 1 } }
local DPAD_POS = { Up = { 0, -1 }, Left = { -1, 0 }, Right = { 1, 0 }, Down = { 0, 1 } }
local XBOX_INK = { A = { 0.45, 0.82, 0.3, 1 }, B = { 0.92, 0.32, 0.26, 1 }, X = { 0.3, 0.58, 0.98, 1 }, Y = { 1, 0.82, 0.22, 1 } }
local PS_INK = { Cross = { 0.55, 0.72, 1, 1 }, Circle = { 1, 0.42, 0.46, 1 }, Square = { 1, 0.58, 0.86, 1 }, Triangle = { 0.38, 0.88, 0.66, 1 } }

local function padKind() return ns.db().pad or "xbox" end
local function padNames() return ns.PADS[padKind()] or ns.PADS.xbox end

-- A binding's note in brackets, e.g. "1 (in Bear Form)" -> "1", "in Bear Form".
local function splitNote(raw)
  raw = plain(raw)
  local note = raw:match("%((.-)%)")
  return (raw:gsub("%s*%b()", ""):gsub("^%s+", ""):gsub("%s+$", "")), note
end

-- Split a guide binding like "RT+A" or "LT+RT+(left arrow)" into modifiers and a button.
local function parsePad(raw)
  local out = { mods = {} }
  local body, note = splitNote(raw)
  out.note = note
  for token in (body .. "+"):gmatch("(.-)%+") do
    local t = plain(token):gsub("^%s+", ""):gsub("%s+$", "")
    if t == "LT" then out.mods[#out.mods + 1] = "L"
    elseif t == "RT" then out.mods[#out.mods + 1] = "R"
    elseif FACE_POS[t] then out.face = t
    elseif DPAD_POS[t] then out.dir = t
    elseif t ~= "" then out.other = (out.other and (out.other .. "+") or "") .. t end
  end
  return out
end

-- One face button: a dark disc with a rim, holding the letter or PlayStation shape.
local function faceGlyph(cx, cy, size, letter, dim)
  local a = dim and 0.4 or 1
  disc(cx, cy, size, { 0.62, 0.55, 0.42, a }, 0)
  disc(cx, cy, size - 3, { 0.07, 0.07, 0.08, dim and 0.7 or 1 }, 1)
  local name = padNames()[letter]
  local kind = padKind()
  local th = math.max(2, math.floor(size / 9 + 0.5))
  if kind == "ps" and canTurn ~= false and PS_INK[name] then
    local ink = PS_INK[name]
    ink = { ink[1], ink[2], ink[3], a }
    local s = size * 0.5
    if name == "Cross" then
      bar(cx, cy, s, th, 45, ink); bar(cx, cy, s, th, -45, ink)
    elseif name == "Square" then
      local h = s * 0.42
      bar(cx, cy - h, s * 0.84 + th, th, 0, ink); bar(cx, cy + h, s * 0.84 + th, th, 0, ink)
      bar(cx - h, cy, s * 0.84, th, 90, ink); bar(cx + h, cy, s * 0.84, th, 90, ink)
    elseif name == "Triangle" then
      local L = s * 1.05
      local hh = L * 0.866
      bar(cx, cy + hh / 3, L, th, 0, ink)
      bar(cx - L / 4, cy - hh / 6, L, th, 60, ink)
      bar(cx + L / 4, cy - hh / 6, L, th, -60, ink)
    else -- Circle: a ring of short strokes (round textures may not exist, rotation does)
      local R, n = s * 0.5, 12
      local seg = 2 * R * math.sin(math.pi / n) + 1.5
      for i = 0, n - 1 do
        local a = (i + 0.5) * 2 * math.pi / n
        bar(cx + R * math.cos(a), cy - R * math.sin(a), seg, th, math.deg(a) + 90, ink)
      end
    end
    return
  end
  local ink = kind == "xbox" and XBOX_INK[letter] or { 0.95, 0.95, 0.95, 1 }
  local _, fs = T(kind == "ps" and (name or letter):sub(1, 1) or (name or letter), cx - size / 2, cy - 7, size, "label",
    { ink[1], ink[2], ink[3], a }, "CENTER", true)
  return fs
end

-- A d-pad with the pressed direction lit.
local function dpadGlyph(cx, cy, size, dir, dim)
  local a = dim and 0.4 or 1
  disc(cx, cy, size, { 0.62, 0.55, 0.42, a }, 0)
  disc(cx, cy, size - 3, { 0.07, 0.07, 0.08, dim and 0.7 or 1 }, 1)
  local arm, th = size * 0.62, size * 0.22
  bar(cx, cy, arm, th, 0, { 0.45, 0.45, 0.47, a }, 2)
  bar(cx, cy, arm, th, 90, { 0.45, 0.45, 0.47, a }, 2)
  local p = DPAD_POS[dir]
  if p then
    local off = size * 0.19
    bar(cx + p[1] * off, cy + p[2] * off, arm * 0.4, th, p[1] ~= 0 and 0 or 90, { C.accent[1], C.accent[2], C.accent[3], a }, 4)
  end
end

local function glyph(cx, cy, size, b, dim)
  if b.face then faceGlyph(cx, cy, size, b.face, dim)
  elseif b.dir then dpadGlyph(cx, cy, size, b.dir, dim) end
end

-- A modifier badge (LT/RT, L2/R2, ZL/ZR) in the style of Forever's on-screen R1 / R2 tags.
local function padBadge(text, x, y)
  local _, fs = T(text, x, y + 4, 200, "label", { 1, 1, 1, 1 }, "LEFT")
  local w = math.max(26, fs:GetStringWidth() + 14)
  fs:SetWidth(w); fs:SetJustifyH("CENTER"); fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, -(y + 4))
  plate(x, y, w, 20, { 0.14, 0.12, 0.1, 0.96 }, { 0.66, 0.58, 0.44, 1 })
  return w
end

-- A whole controller binding, e.g.  [R2] + (X)  - returns its width.
local function padCombo(raw, x, y)
  local b = parsePad(raw)
  local P = padNames()
  local cx = x
  for i, m in ipairs(b.mods) do
    if i > 1 then T("+", cx + 1, y + 3, 12, "label", C.dim, "LEFT"); cx = cx + 12 end
    cx = cx + padBadge(P[m], cx, y) + 3
  end
  if b.face or b.dir then
    if #b.mods > 0 then T("+", cx + 1, y + 3, 12, "label", C.dim, "LEFT"); cx = cx + 12 end
    glyph(cx + 11, y + 10, 22, b)
    cx = cx + 24
  end
  if b.other then
    if cx > x then T("+", cx + 1, y + 3, 12, "label", C.dim, "LEFT"); cx = cx + 12 end
    cx = cx + padBadge(b.other, cx, y) + 3
  end
  if b.note then
    local _, fs = T(b.note, cx + 4, y + 4, 140, "small", C.dim, "LEFT")
    cx = cx + 8 + fs:GetStringWidth()
  end
  return cx - x
end

-- A keyboard key: a light keycap with a dark legend. Combos like "Shift+2" become two caps.
local function keycap(text, x, y)
  local _, fs = T(text, x, y + 4, 200, "label", { 0.1, 0.09, 0.08, 1 }, "LEFT")
  local w = math.max(24, fs:GetStringWidth() + 14)
  fs:SetWidth(w); fs:SetJustifyH("CENTER"); fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, -(y + 4))
  fs:SetShadowOffset(0, 0)
  plate(x, y, w, 20, { 0.84, 0.82, 0.76, 1 }, { 0.32, 0.3, 0.27, 1 })
  -- the key's face, painted directly (a tinted tooltip background comes out dark in Forever)
  rect(x + 2, y + 2, w - 4, 16, { 0.86, 0.84, 0.78, 1 }, "border", 2)
  rect(x + 2, y + 2, w - 4, 3, { 0.96, 0.95, 0.91, 1 }, "border", 3) -- light top edge
  rect(x + 2, y + 15, w - 4, 3, { 0.6, 0.58, 0.53, 1 }, "border", 3)  -- the key's front edge
  return w
end

local function keyCombo(raw, x, y)
  local cx = x
  local parts = {}
  local body, note = splitNote(raw)
  for token in (body .. "+"):gmatch("(.-)%+") do
    token = token:gsub("^%s+", ""):gsub("%s+$", "")
    if token ~= "" then parts[#parts + 1] = token end
  end
  for i, k in ipairs(parts) do
    if i > 1 then T("+", cx + 1, y + 3, 12, "label", C.dim, "LEFT"); cx = cx + 12 end
    cx = cx + keycap(k, cx, y) + 2
  end
  if note then
    local _, fs = T(note, cx + 4, y + 4, 140, "small", C.dim, "LEFT")
    cx = cx + 8 + fs:GetStringWidth()
  end
  return cx - x
end

local function macroTip(m)
  return m.tips and padText(table.concat(m.tips, "\n")) or nil
end

-- The controller mock-up: one panel per modifier set (R2, L2, L2 + R2 ...), the d-pad on the left
-- and the face buttons on the right, with each macro's icon on the button it goes on.
local function controllerMock(list, y)
  local groups, order = {}, {}
  for _, m in ipairs(list) do
    if m.pad ~= "" then
      local b = parsePad(m.pad)
      if b.face or b.dir then
        local key = table.concat(b.mods, "+")
        if not groups[key] then
          groups[key] = { mods = b.mods, face = {}, dir = {} }
          order[#order + 1] = key
        end
        local g = groups[key]
        local slots = b.face and g.face or g.dir
        local at = b.face or b.dir
        -- one button can carry several macros (a druid's cat and bear Fight, used in different forms)
        slots[at] = slots[at] or {}
        table.insert(slots[at], m)
      end
    end
  end
  if #order == 0 then return 0 end
  -- laid out like the controller: L2 on the left, R2 on the right, then combos (L2 + R2) and
  -- unmodified buttons centred underneath, one row each
  local rank = { L = 1, R = 2, ["L+R"] = 3, [""] = 4 }
  table.sort(order, function(a, b) return (rank[a] or 9) < (rank[b] or 9) end)
  local P = padNames()
  local pw, ph, gap = (W - 40) / 2, 166, 8
  local slots, row = {}, 0
  local sides = groups.L or groups.R
  for _, key in ipairs(order) do
    if key == "L" then slots[key] = { 14, 0 }
    elseif key == "R" then slots[key] = { 14 + pw + gap, 0 }
    else
      row = row + 1
      slots[key] = { math.floor((W - pw) / 2), sides and row or row - 1 }
    end
  end
  local rows = (sides and 1 or 0) + row
  for _, key in ipairs(order) do
    local g = groups[key]
    local px = slots[key][1]
    local py = y + slots[key][2] * (ph + gap)
    g.px = px
    -- header: "Hold [L2] + [R2]"
    local hx = px + 10
    T(#g.mods > 0 and "HOLD" or "PRESS", hx, py + 12, 60, "label", C.dim, "LEFT")
    hx = hx + 44
    for k, mod in ipairs(g.mods) do
      if k > 1 then T("+", hx + 1, py + 11, 12, "label", C.dim, "LEFT"); hx = hx + 12 end
      hx = hx + padBadge(P[mod], hx, py + 8) + 3
    end
    -- the two diamonds
    local cyD = py + 100
    local sets = {}
    if next(g.dir) then sets[#sets + 1] = { pos = DPAD_POS, slots = g.dir, isDir = true } end
    if next(g.face) then sets[#sets + 1] = { pos = FACE_POS, slots = g.face } end
    for k, set in ipairs(sets) do
      -- one diamond: centred; two: d-pad on the left, face buttons on the right
      set.cx = px + pw * (#sets == 1 and 0.5 or (k == 1 and 0.26 or 0.74))
    end
    for _, set in ipairs(sets) do
      for name, p in pairs(set.pos) do
        local sx, sy = set.cx + p[1] * 40, cyD + p[2] * 40
        local ms = set.slots[name]
        local b = set.isDir and { dir = name } or { face = name }
        if ms and #ms > 1 then
          -- shared button (a druid's caster, Bear and Cat Fight, used in different forms): up to three
          -- icons, overlapped, the first on top, each with its own tooltip
          local n = math.min(#ms, 3)
          local size, step = n == 2 and 25 or 21, n == 2 and 10 or 7
          for k = n, 1, -1 do
            local m = ms[k]
            local f = icon(m.icon, sx - 17 + (k - 1) * step, sy - 17 + (k - 1) * step, size, m.name, macroTip(m))
            f:SetFrameLevel(overlay:GetFrameLevel() + 1 + (n - k))
          end
          glyph(sx + 13, sy + 13, 16, b)
        elseif ms then
          local m = ms[1]
          icon(m.icon, sx - 17, sy - 17, 34, m.name, macroTip(m))
          glyph(sx + 13, sy + 13, 16, b)
        else
          rect(sx - 17, sy - 17, 34, 34, { 0.3, 0.27, 0.22, 0.8 }, "border", 1)
          rect(sx - 16, sy - 16, 32, 32, { 0.03, 0.03, 0.04, 0.85 }, "border", 2)
          glyph(sx, sy, 20, b, true)
        end
      end
    end
  end
  ns.controllerLayout = groups -- where each button set was drawn (px), for /codex debug and tests
  return rows * ph + (rows - 1) * gap
end

-- The keyboard mock-up: an action bar with each macro on its key (hotkey in the corner,
-- like the game's own bars) and the keycap under it.
local function keyboardMock(list, y)
  local keys = {}
  for _, m in ipairs(list) do
    if m.kb ~= "" then keys[#keys + 1] = m end
  end
  if #keys == 0 then return 0 end
  table.sort(keys, function(a, b)
    local ka, kb = splitNote(a.kb), splitNote(b.kb)
    local na, nb = tonumber(ka), tonumber(kb)
    if na and nb then return na < nb end
    if na or nb then return na ~= nil end
    return ka < kb
  end)
  local slot, step = 40, 78
  local perRow = math.floor((W - 28) / step)
  local rows = math.ceil(#keys / perRow)
  for i, m in ipairs(keys) do
    local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
    local cx = 14 + col * step + step / 2
    local sy = y + row * 84
    -- the bar's empty slot art behind the button
    rect(cx - slot / 2 - 3, sy - 3, slot + 6, slot + 6, { 0.22, 0.2, 0.17, 0.9 }, "border", 0)
    icon(m.icon, cx - slot / 2, sy, slot, m.name, macroTip(m))
    -- hotkey text as the game's bars write it: Shift+1 -> s-1
    local hot = splitNote(m.kb):gsub("Shift%+", "s-"):gsub("Ctrl%+", "c-"):gsub("Alt%+", "a-")
    T(hot, cx - slot / 2, sy + 2, slot - 3, "small", { 0.9, 0.9, 0.9, 1 }, "RIGHT", true)
    -- the macro's name under its button
    local _, fs = T(m.name, cx - step / 2, sy + slot + 8, step, "small", C.light, "CENTER")
    fs:SetWordWrap(false)
  end
  return rows * 84 - 18
end

----------------------------------------------------------------------------
-- Tabs
----------------------------------------------------------------------------

-- Spells in two columns. Each row is as tall as its tallest entry, so long notes that wrap
-- push the next row (and the card's bottom edge) down instead of running over them.
local function spellIconsGrid(t, y, x0, width, light)
  local col = (width - 8) / 2
  local rowTop, rowH = y, 0
  for k, s in ipairs(t.spells) do
    local i = k - 1
    if i > 0 and i % 2 == 0 then rowTop, rowH = rowTop + rowH + 8, 0 end
    local cx = x0 + (i % 2) * col
    icon(t.icons and t.icons[k], cx, rowTop, 32, plain(s), t.notes and plain(t.notes[k]) or nil)
    local h = T(plain(s), cx + 40, rowTop + 1, col - 48, "body", light and C.light or C.ink)
    if t.notes and t.notes[k] and t.notes[k] ~= "" then
      h = h + 3 + T(plain(t.notes[k]), cx + 40, rowTop + h + 4, col - 48, "small", light and C.dim or C.inkSoft)
    end
    rowH = math.max(rowH, 32, h + 2)
  end
  if #t.spells == 0 then return 0 end
  return rowTop + rowH - y + 4
end

local renderers = {}

-- The pace card's pieces: durations, counts and the colours of the XP bar and the XP sources.
local XP_FILL, RESTED_FILL, BAR_TRACK = { 0.58, 0.31, 0.75, 1 }, { 0.25, 0.4, 0.85, 1 }, { 0.05, 0.05, 0.08, 0.9 }
local SOURCE_COLORS = { { 0.88, 0.7, 0.29, 1 }, { 0.77, 0.33, 0.29, 1 }, { 0.36, 0.45, 0.46, 1 } }
local function duration(seconds)
  local minutes = math.floor((tonumber(seconds) or 0) / 60 + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return math.floor(minutes / 60) .. " h " .. (minutes % 60) .. " min"
end
local function plural(n, word) return n .. " " .. word .. (n == 1 and "" or "s") end

-- YOUR PACE for level V: on your own level the XP bar (rested in blue) and the time to the next
-- level at this session's rate; the time spent on V, its XP by source and the last three levels.
local function paceCard(V, y)
  local S, me = ns.stats, tonumber(UnitLevel("player")) or 1
  local top = y
  y = y + 12
  T("YOUR PACE", 16, y, 300, "label", C.gold)
  y = y + 22
  if ns.settingsLost then y = y + T("Counting since you logged in.", 16, y, W - 32, "small", C.dim) + 4 end
  local rate = ns.paceRate and ns.paceRate()
  if V == me then
    local cur, max = tonumber(ns.quests.try(UnitXP, "player")), tonumber(ns.quests.try(UnitXPMax, "player"))
    if cur and max and max > 0 then
      T("Level " .. V .. ": " .. ns.thousands(cur) .. " / " .. ns.thousands(max) .. " XP", 16, y, W / 2, "small", C.light)
      if rate and rate > 0 and max > cur and V < 60 then
        T("Level " .. (V + 1) .. " in about " .. duration((max - cur) / rate * 3600), W / 2, y, W / 2 - 16, "small",
          C.light, "RIGHT")
      end
      y = y + 16
      local bw = W - 32
      local done = math.min(1, math.max(0, cur / max))
      local rested = tonumber(ns.quests.try(GetXPExhaustion)) or 0
      rect(16, y, bw, 12, BAR_TRACK)
      local restedPart = math.min(1 - done, rested / max)
      if restedPart * bw >= 1 then rect(16 + done * bw, y, restedPart * bw, 12, RESTED_FILL, nil, 1) end
      if done * bw >= 1 then rect(16, y, done * bw, 12, XP_FILL, nil, 2) end
      y = y + 20
    end
  end
  local rec = S and S.levelRecord(V)
  if not rec then
    y = y + T("No stats for level " .. V .. " yet.", 16, y, W - 32, "body", C.dim) + 6
  else
    y = y + T(duration(rec.seconds) .. " on this level " .. (ns.settingsLost and "since you logged in" or "(all sessions)")
      .. (rec.fromPct and (" (counted from " .. rec.fromPct .. "%)") or ""), 16, y, W - 32, "body", C.light) + 4
    if V == me and rate then
      y = y + T(ns.thousands(rate) .. " XP per hour this session"
        .. ((rec.rested or 0) > 0 and (", " .. ns.thousands(rec.rested) .. " rested XP on this level") or ""), 16, y,
        W - 32, "small",
        C.light) + 6
    end
    local other = (rec.xp or 0) - (rec.questXP or 0) - (rec.killXP or 0)
    local chips = { "Quests " .. ns.thousands(rec.questXP) .. " XP, " .. (rec.quests or 0) .. " turned in",
      "Kills " .. ns.thousands(rec.killXP) .. " XP, " .. plural(rec.kills or 0, "kill") }
    if other > 0 then chips[3] = "Other " .. ns.thousands(other) .. " XP" end
    local cw = math.floor((W - 32) / 3)
    for i, text in ipairs(chips) do
      local x = 16 + (i - 1) * cw
      rect(x, y + 3, 9, 9, SOURCE_COLORS[i])
      T(text, x + 14, y, cw - 18, "small", C.light)
    end
    y = y + 20
  end
  local earlier = S and S.earlierLevels(math.min(V, me), 3) or {}
  if #earlier > 0 then
    y = y + 4
    T("LAST LEVELS", 16, y, 300, "label", C.goldDim)
    y = y + 20
    local longest = 1
    for _, e in ipairs(earlier) do longest = math.max(longest, tonumber(e.record.seconds) or 0) end
    for _, e in ipairs(earlier) do
      local r = e.record
      T("Level " .. e.level, 16, y, 70, "small", C.light)
      rect(90, y + 3, 140, 8, BAR_TRACK)
      local bar = 140 * (tonumber(r.seconds) or 0) / longest
      if bar >= 1 then rect(90, y + 3, bar, 8, C.accent, nil, 1) end
      T(duration(r.seconds) .. ", " .. plural(r.quests or 0, "quest") .. ", " .. plural(r.kills or 0, "kill")
        .. ((r.deaths or 0) > 0 and (", " .. plural(r.deaths, "death")) or "")
        .. (r.fromPct and (" (counted from " .. r.fromPct .. "%)") or ""), 240, y, W - 256, "small", C.light)
      y = y + 18
    end
  end
  y = y + 8
  box(0, top, W, y - top, C.panel, C.edge)
  return y
end

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
    elseif ns.talentUnplanned(V) then
      y = y + T("Your custom path has no point for level " .. V .. " yet. Plan it on the Talents tab.", 16, y, W - 32, "body", C.ink) + 14
    end
  else
    T("YOUR TALENT POINT", 16, y, 300, "label", C.inkSoft)
    y = y + 18
    y = y + T("Talents start at level 10. Until then, train every new spell and rank.", 16, y, W - 32, "body", C.ink) + 14
  end
  box(0, top, W, y - top, C.parch, C.edge)
  y = y + 12

  -- Next talents strip (the banner test lives in Settings)
  if V < 60 and V >= 9 then
    T("NEXT", 0, y + 8, 60, "label", C.goldDim)
    local x = 52
    for l = V + 1, math.min(V + 2, 60) do
      local h2, r2 = ns.talentAt(l)
      if h2 then
        icon(h2.icon, x, y, 28, l .. ": " .. h2.name .. " " .. r2 .. "/" .. h2.max, plain(l == h2.from and h2.why or h2.more))
        T(l .. "  " .. h2.name .. " " .. r2 .. "/" .. h2.max, x + 34, y + 8, 160, "small", C.light)
        x = x + 196
      elseif ns.talentUnplanned(l) then
        T(l .. "  Not planned yet", x + 34, y + 8, 160, "small", C.dim)
        x = x + 196
      end
    end
    y = y + 40
  end

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
    icon(m.icon, 16, y, 26, m.name, macroTip(m))
    T(m.name, 50, y + 6, 170, "body", C.light)
    local x = 230
    if m.pad ~= "" then x = x + padCombo(m.pad, x, y + 3) + 22 end
    if m.kb ~= "" then keyCombo(m.kb, math.max(x, 400), y + 3) end
    y = y + 32
  end
  if #list == 0 then y = y + T("No macros yet at this level.", 16, y, W - 32, "body", C.dim) + 6 end
  y = y + 4
  box(0, top, W, y - top, C.panel, C.edge)

  -- Pace card: the shown level's record from Stats.lua (all sessions), with your XP bar and this
  -- session's rate on your own level, XP by source and the levels before it
  y = paceCard(V, y + 14)
  return y + 10
end

----------------------------------------------------------------------------
-- Talents: the path cards, the game's tree and every point (TalentTab.lua)
----------------------------------------------------------------------------

renderers.talents = function(V) return ns.renderTalents(V) end

renderers.trainer = function(V)
  local y = sectionTitle("Trainer visits", 0, "every new spell and rank, by level")
  local me = UnitLevel("player")
  local list = {}
  for _, t in ipairs(ns.trainVisits()) do list[#list + 1] = t end
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

----------------------------------------------------------------------------
-- Macros: where each one goes on your controller and keyboard, then each macro in full
----------------------------------------------------------------------------

local PAD_NAMES = { xbox = "Xbox", ps = "PlayStation", switch = "Switch" }

renderers.macros = function(V)
  local list = ns.macrosFor(V)
  local y = sectionTitle("Macros for level " .. V, 0, "hover a button for how it works")
  -- the macros follow your talent path: its own set, or the guide's when it has none
  local path = ns.talentPath()
  local _, from = ns.pathMacros()
  if path and path.custom then
    y = y + T("Your custom path uses the " .. ((from and from.spec) or ns.D.spec) ..
      " macros: that path shares the most points with yours.", 0, y, W, "small", C.gold) + 6
  elseif path and not path.guide then
    y = y + T(from and not from.guide and ("Built for the " .. path.spec .. " path.")
      or ("These macros are built for the " .. ns.D.spec .. " guide."), 0, y, W, "small", C.gold) + 6
  end
  local h = T("Set up macros makes them all at once (character tab of Esc > Macros). Then put each on the button or key shown below.",
    0, y, W - 170, "small", C.dim)
  btn("Set up macros", W - 150, y - 2, 150, function() ns.setupMacros(false) end, true,
    "Creates or updates this character's macros for your current level (" .. UnitLevel("player") .. ").")
  y = y + math.max(h, 24) + 12
  if #list == 0 then
    y = y + T("No macros yet at this level.", 0, y, W, "body", C.dim) + 10
  else
    -- controller
    local top = y
    y = y + 12
    T("ON YOUR CONTROLLER", 16, y, 300, "label", C.gold)
    T((PAD_NAMES[padKind()] or "Xbox") .. " buttons  -  change in Settings", 16, y, W - 32, "small", C.dim, "RIGHT")
    y = y + 22
    local ch = controllerMock(list, y)
    if ch == 0 then y = y + T("None of these macros has a controller button.", 16, y, W - 32, "small", C.dim) + 4 end
    y = y + ch + 12
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
    -- keyboard
    top = y
    y = y + 12
    T("ON YOUR KEYBOARD", 16, y, 300, "label", C.gold)
    T("action bar keys", 16, y, W - 32, "small", C.dim, "RIGHT")
    y = y + 26
    local kh = keyboardMock(list, y)
    if kh == 0 then y = y + T("None of these macros has a key.", 16, y, W - 32, "small", C.dim) + 4 end
    y = y + kh + 14
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 14
  end
  -- each macro in full
  for _, m in ipairs(list) do
    local top = y
    y = y + 12
    icon(m.icon, 14, y, 36, m.name, macroTip(m))
    T(plain(m.title or m.name), 60, y, 300, "head", C.gold)
    local details = "Levels " .. m.lo .. "-" .. m.hi
    if m.title and m.title ~= m.name then details = details .. "  -  Esc > Macros: " .. m.name end
    T(details, 60, y + 22, W - 150, "small", C.dim)
    btn("Copy", W - 78, y + 6, 64, function() ns.showMacroCopy(m) end, false,
      "Shows the macro text ready to copy, for making it yourself in Esc > Macros.")
    y = y + 46
    local bx = 14
    if m.pad ~= "" then
      T("CONTROLLER", bx, y + 5, 90, "label", C.dim)
      bx = bx + 84
      bx = bx + padCombo(m.pad, bx, y) + 24
    end
    if m.kb ~= "" then
      T("KEY", bx, y + 5, 40, "label", C.dim)
      keyCombo(m.kb, bx + 32, y)
    end
    if m.pad ~= "" or m.kb ~= "" then y = y + 30 end
    local codeTop = y
    local ch = T(m.body, 22, y + 8, W - 44, "mono", C.codeInk)
    rect(14, codeTop, W - 28, ch + 16, C.code, nil, 3)
    y = y + ch + 24
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

-- Shared by Settings and Quests > Guide setup. Sliders update only the secure buttons,
-- so dragging a thumb never rebuilds the setup card under the mouse. +/- buttons offer
-- the same offsets to controller users.
local function newOffsetSlider()
  local slider = CreateFrame("Slider", nil, overlay)
  slider:SetOrientation("HORIZONTAL")
  slider:SetValueStep(1)
  ns.try(slider.SetObeyStepOnDrag, slider, true)
  slider.track = slider:CreateTexture(nil, "BACKGROUND")
  slider.track:SetPoint("LEFT", 0, 0)
  slider.track:SetPoint("RIGHT", 0, 0)
  slider.track:SetHeight(4)
  slider.thumb = slider:CreateTexture(nil, "ARTWORK")
  slider.thumb:SetSize(12, 20)
  slider:SetThumbTexture(slider.thumb)
  return slider
end

local function questButtonOptions(y, x, w)
  local db = ns.db()
  btn(ns.questButtonsUnlocked() and "Lock button dragging" or "Unlock button dragging", x, y, 190, function()
    ns.toggleQuestButtonDragging()
    refresh()
  end, ns.questButtonsUnlocked(), "Show drag handles for both buttons, even when this step has no quest item. Drag outside combat, then lock them here.")
  local h = T("Unlock, drag the Item and Target handles, then lock. Dragging pauses in combat.",
    x + 202, y + 3, w - 202, "small", C.dim)
  y = y + math.max(30, h + 8)
  local choices = { { "left", "Left" }, { "right", "Right" }, { "top", "Top" }, { "bottom", "Bottom" } }
  local function draw(kind, name, toggleLabel, offKey, tip)
    check(toggleLabel, x, y, not db[offKey], function()
      db[offKey] = not db[offKey]
      ns.placeQuestButtons()
      refresh()
    end, tip .. " Changes wait until you leave combat.")
    btn("Reset position", x + w - 116, y, 116, function()
      ns.resetQuestButtonLayout(kind)
      refresh()
    end, false, "Return this button to the left of the step window with no offsets.").codexLabel = "Reset " .. name:lower() .. " position"
    y = y + 30
    local side = ns.questButtonLayout(kind)
    T("Position", x, y + 5, 86, "body", C.ink)
    local each = math.floor((w - 92 - 12) / 4)
    for i, choice in ipairs(choices) do
      btn(choice[2], x + 92 + (i - 1) * (each + 4), y, each, function()
        local _, dx, dy = ns.questButtonLayout(kind)
        ns.setQuestButtonLayout(kind, choice[1], dx, dy)
        refresh()
      end, side == choice[1], "Place the " .. name:lower() .. " button at the " .. choice[1] .. " of the step window.").codexLabel = name .. " position: " .. choice[2]
    end
    y = y + 30
    local function offset(axis, label)
      local _, dx, dy = ns.questButtonLayout(kind)
      local value = axis == "x" and dx or dy
      T(label, x, y + 4, 86, "small", C.ink)
      local _, amount = T(value .. " px", x + w - 124, y + 4, 54, "small", C.ink, "CENTER")
      local slider = take("offsetSlider", newOffsetSlider)
      slider:SetPoint("TOPLEFT", content, "TOPLEFT", x + 98, -y)
      slider:SetSize(w - 238, 24)
      slider.track:SetColorTexture(rgba(C.edge))
      slider.thumb:SetColorTexture(rgba(C.gold))
      slider.codexLabel = name .. " " .. label:lower() .. " offset"
      slider:SetScript("OnValueChanged", nil)
      local limit = ns.questButtonOffsetLimit()
      slider:SetMinMaxValues(-limit, limit)
      slider:SetValue(value)
      local function change(n)
        n = math.floor(math.max(-limit, math.min(limit, n)) + 0.5)
        local currentSide, currentX, currentY = ns.questButtonLayout(kind)
        ns.setQuestButtonLayout(kind, currentSide, axis == "x" and n or currentX, axis == "y" and n or currentY)
        amount:SetText(n .. " px")
      end
      slider:SetScript("OnValueChanged", function(_, n) change(n) end)
      for i, delta in ipairs({ -5, 5 }) do
        local symbol = delta < 0 and "-" or "+"
        btn(symbol, x + w - 64 + (i - 1) * 34, y, 30, function()
          local _, currentX, currentY = ns.questButtonLayout(kind)
          change((axis == "x" and currentX or currentY) + delta)
          refresh()
        end, false, "Move the button by 5 pixels.").codexLabel = slider.codexLabel .. " " .. symbol
      end
      y = y + 30
    end
    offset("x", "Horizontal")
    offset("y", "Vertical")
    y = y + 8
  end
  draw("item", "Quest item", "Show the quest item button", "noQuestItem", "Use the current step's quest item.")
  draw("target", "Target", "Show the target button", "noQuestTarget", "Target the step's quest giver or creatures. Key Bindings > AddOns can give it a key.")
  y = y + T("Offsets: positive horizontal moves right; positive vertical moves up. Button changes wait until you leave combat.",
    x, y, w, "small", C.dim) + 12
  return y
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
  local function tick(label, on, fn, tip)
    check(label, 0, y, on, function() fn(); refresh() end, tip)
    y = y + 28
  end
  local function head(str) T(str, 0, y, W, "label", C.gold); y = y + 20 end

  head("THEME")
  local th = ns.themeKey or "forever"
  row("Forever (teal)", 0, 150, th == "forever", function() ns.setTheme("forever") end,
    "WoW: Forever's logo teal for the accents and highlights.")
  row("Codex (gold)", 156, 150, th == "codex", function() ns.setTheme("codex") end,
    "The guide site's gold for the accents and highlights.")
  if ns.skinSupport.available() then
    row("External skin", 312, 150, th == "ellesmere", function() ns.setTheme("ellesmere") end,
      "Use your installed UI skin's panels, accent colour and font. Its skin settings can turn this off for the Codex.")
  end
  y = y + 40

  head("CONTROLLER BUTTON NAMES")
  local p = db.pad or "xbox"
  row("Xbox", 0, 120, p == "xbox", function() db.pad = "xbox" end)
  row("PlayStation", 126, 120, p == "ps", function() db.pad = "ps" end)
  row("Switch", 252, 120, p == "switch", function() db.pad = "switch" end)
  y = y + 40

  head("LEVEL-UP BANNER")
  tick("Show the level-up banner", not db.noToast, function() db.noToast = not db.noToast end)
  row("Test level-up", 0, 120, toast and toast.testing, function()
    local t = ns.getToast()
    if t and t.unlocked then ns.setToastUnlocked(false) end
    testBanner(viewLevel or UnitLevel("player"))
  end, "Plays a level-up for the level shown in the header and keeps the banner up: drag it where you want it, change its size below, right-click it to close.")
  local unlocked = toast and toast.unlocked
  row(unlocked and "Lock banner" or "Move banner", 126, 120, unlocked, function()
    local t = ns.getToast()
    ns.setToastUnlocked(not (t and t.unlocked))
  end, "Shows the banner so you can drag it anywhere. Press again to lock it there.")
  row("Reset", 252, 80, false, function() db.toastPos = nil; db.toastScale = 1; ns.placeToast() end)
  y = y + 32
  T("Size", 0, y + 4, 60, "body", C.light)
  row("-", 60, 28, false, function() db.toastScale = math.max(0.5, (db.toastScale or 1) - 0.1); ns.placeToast() end)
  T(math.floor((db.toastScale or 1) * 100 + 0.5) .. "%", 92, y + 4, 50, "body", C.gold, "CENTER")
  row("+", 146, 28, false, function() db.toastScale = math.min(2, (db.toastScale or 1) + 0.1); ns.placeToast() end)
  y = y + 40

  head("MESSAGES AND MACROS")
  tick("Level-up messages in chat", not db.quiet, function() db.quiet = not db.quiet end)
  tick("Keep my Codex macros up to date", not db.noAutoMacros, function() db.noAutoMacros = not db.noAutoMacros end,
    "After a level-up, macros the Codex made switch to the right version for your new level. Your own macros are never touched.")
  y = y + 12

  head("TALENT WINDOW GUIDE")
  tick("Trace my talent in the talent window", not db.noTalentGuide, function() db.noTalentGuide = not db.noTalentGuide end,
    "When you have a talent point to spend and open your talent window, the Codex traces the talent to take and shows a card above the window.")
  y = y + 12

  head("TRAINERS")
  tick("Show what to train at my class trainer", not db.noTrainerGuide, function() db.noTrainerGuide = not db.noTrainerGuide end,
    "At your class trainer, a card above the window lists the guide's spells you can learn now and what they cost. The Codex never buys anything for you.")
  tick("Show what to learn at profession trainers", not db.noProfTrainer, function() db.noProfTrainer = not db.noProfTrainer end,
    "At a profession trainer, a card lists the next rank when you can train it and the recipes your route needs from this trainer, and names the trainer or vendor for one it doesn't teach.")
  y = y + 12

  head("PROFESSIONS")
  tick("Trace my recipe in the crafting window", not db.noCraftGuide, function() db.noCraftGuide = not db.noCraftGuide end,
    "When you open a crafting profession or Smelting, the Codex outlines the recipe to make for your skill and shows how many more to make.")
  tick("Profession skill-up cards", not db.noProfCards, function() db.noProfCards = not db.noProfCards end,
    "Shows a card for new steps, training or skill caps in every profession the Codex guides. Mining and Herbalism also announce new nodes.")
  y = y + 12

  head("GATHERING")
  tick("Keep Find Herbs / Find Minerals on", not db.noAutoTrack, function()
    db.noAutoTrack = not db.noAutoTrack
    if not db.noAutoTrack then ns.restoreTracking() end
  end, "WoW: Forever turns gathering tracking off when you log in, zone or die. The Codex turns the one you had back on (out of combat), unless you picked another tracking such as Track Beasts.")
  y = y + 12

  head("CONTROLLER")
  tick("Use Forever's controller navigation", db.padNative ~= false, function()
    db.padNative = (db.padNative == false) and nil or false
    ns.gamepad.repick()
  end, "Off: the Codex moves its own highlight with the D-pad instead of Forever's focus glow. Turn it off if Forever's controller navigation misbehaves in the Codex.")
  y = y + 12

  head("VENDOR")
  tick("Sell grey items at vendors", not db.noAutoSell, function() db.noAutoSell = not db.noAutoSell end,
    "When you open a vendor, grey items with a sell price are sold one by one. Items a guide step needs and your Hearthstone are kept. Hold Alt to stop it.")
  tick("Repair at vendors", not db.noAutoRepair, function() db.noAutoRepair = not db.noAutoRepair end,
    "Repairs all your gear with your own money when you open a vendor that repairs. Hold Alt to stop it.")
  tick("Show what to buy for the guide", not db.noShopCard, function() db.noShopCard = not db.noShopCard end,
    "At a vendor, a card lists items your coming steps need that this vendor sells, with one button to buy them. Nothing is bought until you click it.")
  tick("Include profession supplies", not db.noProfShop, function() db.noProfShop = not db.noProfShop end,
    "The card also lists the thread, vials, flux, dye, spices, tools and rods your current profession steps need, when this vendor sells them.")
  y = y + 12

  head("QUEST GUIDE")
  tick("Plan every dungeon run", db.questDungeons, function() db.questDungeons = not db.questDungeons; ns.updateQuestSettings() end,
    "Every dungeon's quest pickups join your route (such as the Deadmines run in Westfall). Quests > Guides > Dungeons plans runs one by one, which overrides this.")
  tick("Keep grey quests in the route", db.questKeepGrey, function() db.questKeepGrey = not db.questKeepGrey; ns.updateQuestSettings() end,
    "Off: pickups that have gone grey for your level leave the route (unless a later quest needs them) and are listed under Quests > Missed quests > Outleveled.")
  tick("Show optional quests", db.questOptional, function() db.questOptional = not db.questOptional; ns.updateQuestSettings() end,
    "Side errands the route can skip, such as Forever's Camping 101 profession introductions.")
  -- Elite quests: ask at each pickup (default), or take or skip them all.
  T("Elite quests", 0, y + 5, 110, "body", C.ink)
  local Q = ns.quests
  y = y + segments(116, y, W - 116, Q.ELITE_LABELS, Q.eliteModeIndex(), function(i)
    Q.setEliteMode(i)
    ns.updateQuestSettings()
    refresh()
  end, Q.ELITE_TIPS) + 8
  tick("Skip hearthstone binding steps", db.questSkipBind, function()
    db.questSkipBind = not db.questSkipBind
    ns.updateQuestSettings()
  end, "Keep your hearthstone where it is. Bind steps tick off by themselves when your hearthstone is already set to that inn; hearth steps say where yours is set.")
  tick("Play a sound when a step completes", not db.questNoSound, function() db.questNoSound = not db.questNoSound end)
  tick("Show class quests", not db.noClassQuests, function() db.noClassQuests = not db.noClassQuests; ns.updateQuestSettings() end,
    "Your class's quest chains (pets, forms, totems, class spells) as their own sections in the Quests tab. They also show under Missed quests when you reach their level.")
  y = questButtonOptions(y, 0, W)
  tick("Show the quest arrow", not db.noQuestArrow, function() db.noQuestArrow = not db.noQuestArrow; ns.questRefresh() end)
  tick("Show the NPC portrait", not db.noQuestPortrait, function()
    db.noQuestPortrait = not db.noQuestPortrait
    ns.questRefresh()
  end, "A small 3D portrait of the quest giver, the one you turn in to, or the creature to hunt, beside the step's title.")
  tick("Colour the arrow by direction", not db.noArrowColor, function()
    db.noArrowColor = not db.noArrowColor
    ns.questRefresh()
  end, "Green when you're heading for the step, gold when it's off to your side, red when it's behind you.")
  tick("Animate the arrow on arrival", not db.noArrowBounce, function() db.noArrowBounce = not db.noArrowBounce end,
    "When you reach the step's spot (or its mob or object), the arrow turns into the step's icon, bobbing gently over a gold ring that pulses once.")
  tick("Lock the arrow", db.questArrowLocked, function() db.questArrowLocked = not db.questArrowLocked end,
    "Drag the arrow to put it anywhere on screen; Ctrl+mouse wheel over it changes its size. Locked, it stays where it is.")
  T("Arrow size", 0, y + 4, 90, "body", C.light)
  local function arrowSize(step)
    db.questArrowScale = math.floor(math.max(0.6, math.min(2, (tonumber(db.questArrowScale) or 1) + step)) * 10 + 0.5) / 10
    ns.placeQuestArrow()
  end
  row("-", 90, 28, false, function() arrowSize(-0.1) end)
  T(math.floor((tonumber(db.questArrowScale) or 1) * 100 + 0.5) .. "%", 122, y + 4, 50, "body", C.gold, "CENTER")
  row("+", 176, 28, false, function() arrowSize(0.1) end)
  row("Reset arrow", 216, 120, false, function()
    db.questArrowPos, db.questArrowScale = nil, nil
    ns.placeQuestArrow()
  end, "Puts the arrow back above the step window at its normal size.")
  y = y + 36
  if ns.questSupport.usable() then
    tick("Point the arrow at the nearest objective", not db.noNearestSpawn, function()
      db.noNearestSpawn = not db.noNearestSpawn
      ns.questRefresh()
    end, "Near a kill or collect step's camp, the arrow leads to the closest mob or object you still need using your installed quest-data provider.")
  end
  tick("Track the step's quest in the quest tracker", not db.noQuestWatch, function() db.noQuestWatch = not db.noQuestWatch; ns.questRefresh() end,
    "Adds the current step's quest to the game's objective tracker. Quests you track yourself are left alone.")
  tick("Warn about elites and rares near the step", not db.noDangerWarnings, function() db.noDangerWarnings = not db.noDangerWarnings; ns.questRefresh() end,
    "The step window names hostile elites and rares close to the current step until you outlevel them.")
  y = y + 6
  head("PARTY")
  tick("Show my party's steps", not db.noPartySteps, function() db.noPartySteps = not db.noPartySteps; ns.questRefresh() end,
    "The step window lists your party: who is on your step (with their kill or loot count), how many steps ahead or behind the others are, and who isn't sharing a step. Party members need the Codex to share theirs.")
  tick("Share guide quests with my party", ns.questSharing(), ns.toggleQuestSharing,
    "On by default. When you accept a quest from your guide, the Codex offers it to party members who don't have it yet.")
  tick("Say my flights in party chat", db.questAnnounceFlights, function() db.questAnnounceFlights = not db.questAnnounceFlights end,
    "Off by default. Taking a flight says where you're flying in party chat, with the time once that flight has been timed.")
  tick("Say steps I finish in party chat", db.questAnnounceSteps, function() db.questAnnounceSteps = not db.questAnnounceSteps end,
    "Off by default. Icons and clickable quest links mark accepted quests, finished objectives and turn-ins. Next and Back stay quiet.")
  tick("Say quest items I pick up", db.questAnnounceItems, function() db.questAnnounceItems = not db.questAnnounceItems end,
    "Off by default. Quest loot goes to party chat with your progress count and quest link. An item that starts a quest includes its item link when available.")
  tick("Say quest progress in party chat", db.questAnnounceProgress, function() db.questAnnounceProgress = not db.questAnnounceProgress end,
    "Off by default. Finished objectives and quests ready to turn in use distinct status messages and quest links. At most a line a second, never in a raid.")
  tick("Ping when the party is together on my step", not db.noPartyPing, function() db.noPartyPing = not db.noPartyPing end,
    "A sound when the last party member reaches your step (or you reach theirs). Quests > Party shows everyone's step, counts and quests.")
  btn("Preview quest announcements", 0, y, 260, ns.previewQuestAnnouncements, false, "Show sample icons, links and progress privately. Nothing is sent to the party.")
  y = y + 28
  -- the ping's sound: picking one plays it, so you can hear it (Sound Effects volume)
  T("Ping sound", 0, y + 5, 110, "body", C.ink)
  local pingLabels, pingTips = {}, {
    "A quiet chime (the game's friend-online sound).",
    "The game's party invite sound.",
    "The game's ready-check sound: the loudest.",
  }
  for i, sound in ipairs(ns.PARTY_PINGS) do pingLabels[i] = sound[1] end
  y = y + segments(116, y, W - 116, pingLabels, ns.partyPingIndex(), function(i)
    db.partyPingSound = i
    ns.playPartyPing(i)
    refresh()
  end, pingTips) + 8
  if ns.questSupport.announces("objectives") or ns.questSupport.announces("items") then
    y = y - 4 + T("Your quest tracker already announces finished objectives and quest-starting items, so the Codex avoids repeating them.",
      28, y - 4, W - 28, "small", C.dim) + 6
  end
  T("Steps shown ahead", 0, y + 4, 150, "body", C.light)
  row("-", 150, 28, false, function() ns.setQuestPreview(ns.questPreviewCount() - 1) end,
    "Fewer of the next steps the step window lists under the current one.")
  T(tostring(ns.questPreviewCount()), 182, y + 4, 30, "body", C.gold, "CENTER")
  row("+", 216, 28, false, function() ns.setQuestPreview(ns.questPreviewCount() + 1) end,
    "More of the next steps the step window lists under the current one (0-10). The list runs on into the next section.")
  y = y + 36
  tick("Pin the current step on the map", not db.noQuestMapPin, function() db.noQuestMapPin = not db.noQuestMapPin; ns.questRefresh() end,
    "Puts the game's own map waypoint on the current step, so it shows on your world map and minimap. A waypoint you placed yourself is never replaced.")
  tick("Show the completion bar", not db.noStepBar, function() db.noStepBar = not db.noStepBar; ns.questRefresh() end,
    "A thin bar under the step's title fills as you get through the guide; hover it for the counts, click it for the route.")
  tick("Show steps on the minimap", not db.noMinimapSteps, function() db.noMinimapSteps = not db.noMinimapSteps; ns.questRefresh() end,
    "The current step's icon on the minimap (an arrow on its edge when it's farther), and small numbered pins for the next two steps.")
  tick("Show steps on the world map", not db.noWorldMapSteps, function() db.noWorldMapSteps = not db.noWorldMapSteps; ns.questRefresh() end,
    "Pins for the current step and the next two on your world map; hover one for its step.")
  tick("Route line on the minimap", not db.noMinimapLine, function() db.noMinimapLine = not db.noMinimapLine end,
    "Gold dots on the minimap run from you to the current step, through a cave or tunnel's way in.")
  tick("Route line on the world map", not db.noWorldMapLine, function()
    db.noWorldMapLine = not db.noWorldMapLine
    ns.questRefresh()
  end, "The same gold dots on your world map, from you to the current step, on the map you're on.")
  tick("Lock the quest step window", db.questLocked, function() db.questLocked = not db.questLocked end)
  -- The step window's size (down to half for small screens) and background, as steppers.
  local function stepper(label, value, change)
    T(label, 0, y + 4, 150, "body", C.light)
    btn("-", 156, y, 28, function() change(-0.1); refresh() end, false).codexLabel = label .. " -"
    T(math.floor(value * 100 + 0.5) .. "%", 188, y + 4, 46, "body", C.gold, "CENTER")
    btn("+", 238, y, 28, function() change(0.1); refresh() end, false).codexLabel = label .. " +"
    y = y + 30
  end
  stepper("Step window size", tonumber(db.questViewerScale) or 1, ns.setQuestViewerScale)
  stepper("Step window background", tonumber(db.questViewerAlpha) or 1, ns.setQuestViewerAlpha)
  T("Ctrl+mouse wheel over the step window also changes its size.", 0, y - 2, W, "small", C.dim)
  y = y + 18
  tick("Fade the step window in combat", not db.noQuestFade, function() db.noQuestFade = not db.noQuestFade end,
    "In combat the step window drops to 30% so it's out of your way; the mouse over it brings it back.")
  tick("Compact step window", db.questCompact, function() db.questCompact = not db.questCompact; ns.questRefresh() end,
    "Only the step's title, a thin progress bar and the buttons: for small screens. The corner button switches it too.")
  local providerKey = ns.questSupport.keyName()
  local holdBack = "Hold Alt" .. (providerKey and (" or " .. providerKey) or "") .. " to stop it."
  local function providerNote(on, text)
    if on then y = y - 4 + T(text, 28, y - 4, W - 28, "small", C.dim) + 6 end
  end
  tick("Auto-accept the current guide quest", db.questAutoAccept, function() db.questAutoAccept = not db.questAutoAccept end,
    "Off by default, so you can read each quest. On: accepts only the guide's current quest, also from an NPC's gossip list. " .. holdBack)
  providerNote(ns.questSupport.autoAccept(), "Your quest tracker's auto-accept is on and handles quest pickups.")
  tick("Auto-turn in the current guide quest", db.questAutoTurnin, function() db.questAutoTurnin = not db.questAutoTurnin end,
    "Off by default. On: turns in only the guide's current quest, out of combat, when there is no reward to choose. " .. holdBack)
  providerNote(ns.questSupport.autoComplete(), "Your quest tracker's auto-complete is on and handles quest turn-ins.")
  tick("Mark the best-selling quest reward", not db.noRewardHint, function() db.noRewardHint = not db.noRewardHint end,
    "When a quest offers a choice of rewards, a coin marks the one that sells for the most and chat names it. The Codex never picks a reward for you.")
  tick("Loot tooltip advice",not db.noLootHints,function() db.noLootHints=not db.noLootHints end,
    "Compare equipment against your current gear with your selected loot profile.")
  tick("Mark gear upgrade rewards",not db.noLootRewards,function() db.noLootRewards=not db.noLootRewards end,
    "A plus marks the strongest conclusive gear upgrade. Vendor value keeps its separate coin mark.")
  tick("Show loot target tracker",not db.noLootTracker,function() db.noLootTracker=not db.noLootTracker;if ns.loot then ns.loot.refreshTracker() end end,
    "A small panel lists your tracked items. Drag it to move it.")
  tick("Loot notifications",db.lootNotifications,function() db.lootNotifications=not db.lootNotifications end,
    "Off by default. Announce obtained targets and conclusively new bag upgrades once.")
  tick("Open a dungeon's guide when you enter it", not db.noDungeonOpen, function() db.noDungeonOpen = not db.noDungeonOpen end,
    "Zoning into a dungeon the Codex has a guide for switches the step window to it, boss by boss, even if you didn't press Run. Return to leveling takes you back.")
  tick("Plan trips through flight masters", not db.noFlightPlans, function() db.noFlightPlans = not db.noFlightPlans; ns.questRefresh() end,
    "For a long trip the arrow leads to a flight master when flying is quicker, and the flight map marks the flight to take. It only uses flight paths you have.")
  tick("Lead me to flight paths I don't have", not db.noFlightLearn, function() db.noFlightLearn = not db.noFlightLearn; ns.questRefresh() end,
    "When a flight master you haven't talked to is close to the way, the arrow stops there first so you learn the flight path. Works once the game has listed your flight paths, or you opened a flight map this session.")
  tick("Auto-fly: take the guide's flights and binds", db.questAutoTravel, function() db.questAutoTravel = not db.questAutoTravel end,
    "Off by default. On: at a flight master the Codex takes the flight the guide marks (a Fly step's, or the one the arrow names), and at the step's innkeeper during a bind step it picks the bind option (accept the game's popup yourself: addons may not). Hold Alt to stop it.")
  y = y + 12

  head("MINIMAP BUTTON")
  tick("Minimap button", not db.noMinimap, function() db.noMinimap = not db.noMinimap; ns.updateMini() end,
    "Drag the Level 60 badge around the edge of the minimap to put it where you like; it remembers the spot. The Codex is also in the addons button under the clock.")
  row("Reset position", 0, 140, false, function() db.minimapAngle = nil; ns.updateMini() end)
  y = y + 40

  head("THIS WINDOW")
  T("Size", 0, y + 4, 60, "body", C.light)
  row("-", 60, 28, false, function() db.windowScale = math.max(0.6, (db.windowScale or 1) - 0.1); ns.placeWindow() end)
  T(math.floor((db.windowScale or 1) * 100 + 0.5) .. "%", 92, y + 4, 50, "body", C.gold, "CENTER")
  row("+", 146, 28, false, function() db.windowScale = math.min(1.6, (db.windowScale or 1) + 0.1); ns.placeWindow() end)
  row("Reset position", 186, 140, false, function() db.windowPos = nil; ns.placeWindow() end)
  y = y + 40
  T("Drag the window by its header to move it. /codex reset puts the window and banner back where they started. /codex debug lists what the Codex can see, for bug reports.", 0, y, W, "small", C.dim)
  return y + 40
end

----------------------------------------------------------------------------
-- Frame
----------------------------------------------------------------------------

local TABS = {
  { "level", "This Level" }, { "talents", "Talents" }, { "trainer", "Trainer" },
  { "macros", "Macros" }, { "tips", "Tips" }, { "settings", "Settings" },
}

-- Another file adds its own tab (before Settings): renderer(viewLevel) draws with ns.ui and
-- returns the content height. TABS outlives the frame, so a theme rebuild keeps the tab.
function ns.addTab(key, label, renderer, width)
  renderers[key] = renderer
  tabWidths[key] = width
  for _, t in ipairs(TABS) do if t[1] == key then return end end
  table.insert(TABS, #TABS, { key, label })
end

-- An invisible row button with a tooltip (route rows and the like). `label` names it for the
-- controller and the harness (codexLabel); nil leaves it unnamed.
local function hit(x, y, w, h, tipTitle, tipText, onClick, label)
  local hb = take("hit", newHit)
  hb:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y); hb:SetSize(w, h)
  hb.tipTitle, hb.tipText = tipTitle, tipText
  -- A previous use may have installed a native item tooltip (the Loot browser).
  hb:SetScript("OnEnter", showTip); hb:SetScript("OnLeave", hideTip)
  hb.codexLabel = label
  hb:SetScript("OnClick", onClick)
  hb:SetFrameLevel(overlay:GetFrameLevel() + 1)
  return hb
end

-- The quest log's fold button (plus folded, minus open), 16 px; "+" / "-" without the art.
local function newFoldTex() return overlay:CreateTexture(nil, "ARTWORK") end
local function fold(open, x, y)
  local path = open and A.FILES.minusUp or A.FILES.plusUp
  if A.hasFile(path) then
    local t = take("fold", newFoldTex)
    t:SetTexture(path)
    t:SetSize(16, 16)
    t:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
    return
  end
  T(open and "-" or "+", x + 4, y, 12, "body", C.gold)
end

local function questSearch(x, y, w, value, onChange, onSubmit)
  local edit = take("edit", function()
    local box = CreateFrame("EditBox", "LevelingCodexQuestSearch", overlay, "InputBoxTemplate")
    if C.eui then ns.skinSupport.call("EditBox", box) end -- its near-black box, the template art gone
    box:SetAutoFocus(false)
    box:SetMaxLetters(80)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnHide", function(self) self:ClearFocus() end)
    return box
  end)
  edit:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
  edit:SetSize(w, 22)
  if edit:GetText() ~= value then edit:SetText(value) end
  edit:SetScript("OnTextChanged", function(self) onChange(self:GetText()) end)
  edit:SetScript("OnEnterPressed", function(self) self:ClearFocus(); onSubmit() end)
end

local function entry(key,x,y,w,value,onChange,onSubmit,maxBytes)
  local edit=take("input:"..key,function()
    local e=CreateFrame("EditBox","LevelingCodex"..key,overlay,"InputBoxTemplate")
    e:SetAutoFocus(false)
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    e:SetScript("OnHide",function(self) self:ClearFocus() end)
    return e
  end)
  edit:SetScript("OnTextChanged",nil)
  edit:SetPoint("TOPLEFT",content,"TOPLEFT",x,-y); edit:SetSize(w,22)
  edit:SetMaxLetters(maxBytes or 2048); edit.codexLabel=key
  if edit:GetText()~=value then edit:SetText(value or "") end
  edit:SetScript("OnTextChanged",function(self) if onChange then onChange(self:GetText()) end end)
  edit:SetScript("OnEnterPressed",function(self) self:ClearFocus(); if onSubmit then onSubmit(self:GetText()) end end)
  return edit
end

-- A static portrait avoids inheriting the player's animations, mounts, and camera.
local function playerPortrait(x,y,size,class,live)
  local tex=take("playerPortrait",function() return overlay:CreateTexture(nil,"ARTWORK") end)
  tex:SetPoint("TOPLEFT",content,"TOPLEFT",x,-y)
  tex:SetSize(size,size)
  tex:SetTexCoord(0,1,0,1)
  if live then
    local ok,result=ns.try(SetPortraitTexture,tex,"player")
    if ok and result~=false then return end
  end
  ns.setIcon(tex,"classicon_"..class:lower())
end
local function interactivePoolKinds()
  local kinds={"icon","btn","check","hit","edit"}
  for kind in pairs(pools) do if kind:sub(1,6)=="input:" then kinds[#kinds+1]=kind end end
  return kinds
end

-- The drawing helpers for tabs that live in other files.
ns.ui = { W = W, T = T, rect = rect, box = box, plate = plate, surface = surface, picture = picture, folio = folio, icon = icon, btn = btn, check = check, hit = hit,
  entry = entry, playerPortrait = playerPortrait,
  segments = segments, fold = fold, questButtonOptions = questButtonOptions,
  questSearch = questSearch, sectionTitle = sectionTitle, goldRuleAt = goldRuleAt, refresh = function() refresh() end,
  openLevel = function(l) viewLevel = l; activeTab = "level"; refresh() end,
  refreshTop = function() if scroll then scroll:SetVerticalScroll(0) end; refresh() end }

function ns.placeWindow()
  if not frame then return end
  local db = ns.db()
  local p = db.windowPos
  local scale = db.windowScale or 1
  if tabWidths[activeTab] then
    local screenWidth = UIParent:GetWidth()
    if screenWidth and screenWidth > 32 then scale = math.min(scale, (screenWidth - 32) / frame:GetWidth()) end
  end
  frame:SetScale(scale)
  frame:ClearAllPoints()
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER") end
end

refresh = function(professionSnapshot)
  if not (frame and frame:IsShown() and ns.D) then return end
  local me = UnitLevel("player")
  local width = tabWidths[activeTab] or W
  if content:GetWidth() ~= width then
    content:SetWidth(width)
    frame:SetWidth(width + 72)
    ns.placeWindow()
  end
  viewLevel = viewLevel or me
  if viewLevel < 1 then viewLevel = 1 elseif viewLevel > 60 then viewLevel = 60 end
  levelText:SetText("Level " .. viewLevel)
  nowBtn:SetLook(viewLevel == me)
  nowBtn:SetLabel(viewLevel == me and "You" or "Back to " .. me)
  for _, t in ipairs(tabs) do t:SetSelected(t.key == activeTab) end
  -- remember where the tab we're leaving (or redrawing) was scrolled to
  if shownTab then scrollPos[shownTab] = scroll:GetVerticalScroll() or 0 end
  local edit = pools.edit and pools.edit.list[1]
  local keepSearchFocus = edit and edit:IsShown() and edit:HasFocus()
  local keepEntryFocus
  for kind, pool in pairs(pools) do
    if kind:sub(1,6) == "input:" then
      for i = 1, pool.used do
        local entry = pool.list[i]
        if entry:IsShown() and entry:HasFocus() then keepEntryFocus = entry; break end
      end
    end
  end
  releaseAll()
  local h = renderers[activeTab](viewLevel, professionSnapshot) or 0
  content:SetHeight(math.max(h, 10))
  shownTab = activeTab
  if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
  local want = scrollPos[activeTab] or 0
  local range = scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange() or want
  scroll:SetVerticalScroll(math.max(0, math.min(want, range or 0)))
  -- the controller's tags, from what each widget is now (pooled widgets change role between tabs,
  -- and some get their click after the helper drew them): padSkip = nothing to press, padX/padY =
  -- its centre in content coordinates
  for _, kind in ipairs(interactivePoolKinds()) do
    local p = pools[kind]
    for i = 1, p and p.used or 0 do
      local w = p.list[i]
      w.padSkip = (kind ~= "edit" and kind:sub(1,6) ~= "input:" and w:GetScript("OnClick") == nil) or nil
      local _, rel, _, x, y = w:GetPoint(1)
      if rel == content and x and y then
        w.padX, w.padY = x + (w:GetWidth() or 0) / 2, -y + (w:GetHeight() or 0) / 2
      end
    end
  end
  if ns.gamepad then ns.gamepad.refresh(frame) end
  if keepSearchFocus and edit:IsShown() then edit:SetFocus() end
  if keepEntryFocus and keepEntryFocus:IsShown() then keepEntryFocus:SetFocus() end
end
ns.refresh = refresh
local lootRefreshQueued
function ns.refreshLootTab(background)
  if not (frame and frame:IsShown() and activeTab=="loot") then return end
  if background then
    local ok,down=ns.try(IsMouseButtonDown,"LeftButton")
    down=ok and down==true
    local hits=pools.hit
    if not down and hits then
      for i=1,hits.used do
        local button=hits.list[i]
        local supported,state=ns.try(button.GetButtonState,button)
        if supported and state=="PUSHED" then down=true;break end
      end
    end
    -- The renderer hides and reuses pooled buttons. Keep a pressed button intact
    -- until its mouse-up can finish before applying delayed item/bag updates.
    if down then
      if not lootRefreshQueued then
        lootRefreshQueued=true
        ns.after(0.08,function()
          lootRefreshQueued=nil
          ns.refreshLootTab(true)
        end)
      end
      return
    end
  end
  refresh()
end
function ns.refreshQuestTab()
  if frame and frame:IsShown() and activeTab == "quests" then refresh() end
end

function ns.refreshProfessionTab(snapshot)
  if frame and frame:IsShown() and activeTab == "professions" then refresh(snapshot) end
end

-- LB/RB on a controller: the next or previous tab, wrapping around.
local function cycleTab(delta)
  local i = 1
  for k, t in ipairs(TABS) do if t[1] == activeTab then i = k end end
  i = (i - 1 + delta) % #TABS + 1
  activeTab = TABS[i][1]
  refresh()
end

-- What the controller can focus, at logical positions (content coordinates, y down): the content's
-- buttons, ticks and clickable strips, the header above it and the tabs below it.
local function listFocusables()
  local out = {}
  for _, kind in ipairs(interactivePoolKinds()) do
    local p = pools[kind]
    for i = 1, p and p.used or 0 do
      local w = p.list[i]
      if w:IsShown() and not w.padSkip then out[#out + 1] = { frame = w, x = w.padX or 0, y = w.padY or 0 } end
    end
  end
  local chrome = frame.padChrome or {}
  local width = content:GetWidth()
  for _, c in ipairs({ { chrome.prev, width * 0.6 }, { chrome.now, width * 0.75 }, { chrome.next, width * 0.9 }, { chrome.close, width + 20 } }) do
    if c[1] and c[1]:IsShown() then out[#out + 1] = { frame = c[1], x = c[2], y = -40, fixed = true } end
  end
  local h = content:GetHeight() or 0
  for i, t in ipairs(tabs) do out[#out + 1] = { frame = t, x = i * W / #tabs, y = h + 40, fixed = true } end
  return out
end

-- The flat Codex chrome (when the client has no dialog border): leather, glow, double border.
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

local function flatChrome(f)
  local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(rgba(C.bg))
  local rock = f:CreateTexture(nil, "BACKGROUND", nil, -1)
  rock:SetAllPoints()
  if rock:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT") ~= false then
    if rock.SetHorizTile then rock:SetHorizTile(true); rock:SetVertTile(true) end
    rock:SetVertexColor(rgba(C.rock))
    bg:SetColorTexture(rgba(C.wash))
  else
    rock:Hide()
  end
  local glow = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  glow:SetPoint("TOPLEFT"); glow:SetPoint("TOPRIGHT"); glow:SetHeight(140)
  ns.fade(glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.3)
  doubleBorder(f)
end

-- The game's dialog border and background, with a faint theme-coloured glow under the header;
-- external UI's window shell in its theme.
local function chrome(f, glowHeight)
  if ns.skinSupport.backing(f, "Shell") then return true end
  if A.backdrop(f, "dialog") then
    -- the dialog background is see-through: darken it so names and effects in the world
    -- don't show through the text
    local fill = f:CreateTexture(nil, "BACKGROUND", nil, 0)
    fill:SetPoint("TOPLEFT", 11, -12); fill:SetPoint("BOTTOMRIGHT", -12, 11)
    fill:SetColorTexture(0.035, 0.035, 0.045, 0.88)
    local glow = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    glow:SetPoint("TOPLEFT", 12, -12); glow:SetPoint("TOPRIGHT", -12, -12); glow:SetHeight(glowHeight or 110)
    ns.fade(glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.22)
    return true
  end
  flatChrome(f)
  return false
end

-- A dark inset (the tooltip border) to hold scrolling content or a text box; external UI's darker
-- inset panel in its theme.
local function inset(parent)
  local f = A.frame("Frame", nil, parent)
  if ns.skinSupport.backing(f, "Panel", { inset = true }) then return f end
  if not A.backdrop(f, "tooltip", { 0, 0, 0, 0.5 }, { C.edgeSoft[1], C.edgeSoft[2], C.edgeSoft[3], 1 }) then
    local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.35)
  end
  return f
end

local function closeWithEsc(name)
  if type(UISpecialFrames) ~= "table" then return end
  for _, n in ipairs(UISpecialFrames) do if n == name then return end end
  table.insert(UISpecialFrames, name)
end

local function makeFrame()
  frame = A.frame("Frame", "LevelingCodexFrame", UIParent)
  frame:SetSize(640, 620)
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  if frame.SetClampRectInsets then pcall(frame.SetClampRectInsets, frame, 0, 0, 30, -34) end -- keep banner and tabs on screen
  frame:Hide()
  shownTab = nil -- a new scroll frame: keep the saved offsets, don't read the empty one
  closeWithEsc("LevelingCodexFrame") -- by name, so a rebuilt frame needs no second entry

  chrome(frame, 110)
  A.header(frame, "The Leveling Codex", 360)

  -- header (drag here to move): portrait, spec, level picker
  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", 12, -12); header:SetPoint("TOPRIGHT", -12, -12); header:SetHeight(84)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() frame:StartMoving() end)
  header:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    local p1, _, p2, x, y = frame:GetPoint(1)
    ns.db().windowPos = { p1, p2, x, y }
  end)

  local _, token = UnitClass("player")
  local portrait = A.portrait(header, 54, token)
  portrait:SetPoint("TOPLEFT", 6, -12)

  local spec = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  spec:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 10, -10)
  spec:SetFont(ns.headFont(), 24, "")
  spec.codexHead = 24
  spec:SetTextColor(rgba(C.titleInk))
  spec:SetShadowOffset(1, -1)
  spec:SetText(ns.D.spec .. " " .. ns.CLASS_NAME)
  local kicker = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  kicker:SetPoint("TOPLEFT", spec, "BOTTOMLEFT", 1, -3)
  kicker:SetTextColor(rgba(C.goldDim))
  kicker:SetText("WOW: FOREVER  -  LEVELING 1-60")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)
  if C.eui then ns.skinSupport.call("CloseButton", close) end

  -- level picker: view any level, with the spellbook's page arrows
  local nextB = A.arrow(header, "next"); nextB:SetPoint("TOPRIGHT", -36, -22)
  levelText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  levelText:SetFont(ns.headFont(), 20, "")
  levelText.codexHead = 20
  if C.eui then levelText:SetTextColor(1, 1, 1) else levelText:SetTextColor(1, 0.82, 0) end
  levelText:SetShadowOffset(1, -1)
  levelText:SetWidth(96); levelText:SetJustifyH("CENTER")
  levelText:SetPoint("RIGHT", nextB, "LEFT", -2, 0)
  local prevB = A.arrow(header, "prev"); prevB:SetPoint("RIGHT", levelText, "LEFT", -2, 0)
  nowBtn = A.button(header, 96, 22); nowBtn:SetPoint("TOP", levelText, "BOTTOM", 0, -6)
  nowBtn:SetLabel("You")
  prevB:SetScript("OnClick", function() viewLevel = math.max(1, (viewLevel or 1) - 1); refresh() end)
  nextB:SetScript("OnClick", function() viewLevel = math.min(60, (viewLevel or 1) + 1); refresh() end)
  nowBtn:SetScript("OnClick", function() viewLevel = UnitLevel("player"); refresh() end)
  prevB.tipTitle, prevB.tipText = "Previous level", "Browse the guide at any level."
  nextB.tipTitle, nextB.tipText = "Next level", "Browse the guide at any level."
  frame.padChrome = { prev = prevB, now = nowBtn, next = nextB, close = close }

  -- the page: a dark inset with the scrolling content
  local page = inset(frame)
  page:SetPoint("TOPLEFT", 14, -100)
  page:SetPoint("BOTTOMRIGHT", -14, 14)
  scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 8, -10)
  scroll:SetPoint("BOTTOMRIGHT", -28, 10)
  ns.skinSupport.scrollBar(scroll)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(W, 10)
  scroll:SetScrollChild(content)
  overlay = CreateFrame("Frame", nil, content)
  overlay:SetAllPoints(content)
  overlay:SetFrameLevel(content:GetFrameLevel() + 5)
  top = CreateFrame("Frame", nil, content)
  top:SetAllPoints(content)
  top:SetFrameLevel(content:GetFrameLevel() + 20) -- above the icons (overlay + 1)

  -- tabs hang below the window, like the character sheet's
  tabs = {}
  local prev
  for i, t in ipairs(TABS) do
    local b = A.tab(frame, t[2])
    if i == 1 then b:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 16, 8)
    else b:SetPoint("LEFT", prev, "RIGHT", -12, 0) end
    b.key = t[1]
    b:SetScript("OnClick", function() activeTab = t[1]; refresh() end)
    tabs[#tabs + 1] = b
    prev = b
  end
  -- Too many tabs for the window's width: every tab shrinks by the same share (12 px overlap each).
  local total, avail = -12 * (#tabs - 1), (tonumber(frame:GetWidth()) or 0) - 32
  for _, b in ipairs(tabs) do total = total + (tonumber(b:GetWidth()) or 0) end
  if avail > 0 and total > avail then
    local share = (avail + 12 * (#tabs - 1)) / (total + 12 * (#tabs - 1))
    for _, b in ipairs(tabs) do b:SetWidth(math.floor((tonumber(b:GetWidth()) or 0) * share)) end
  end

  ns.skinSupport.fonts(frame) -- the title, kicker and tabs (the pooled text sets its own: styleFS)
  frame:SetScript("OnShow", function() viewLevel = viewLevel or UnitLevel("player"); refresh() end)
  -- after OnShow is set: the controller (Gamepad.lua) hooks it
  ns.gamepad.attach(frame, { main = true, scroll = scroll, focusables = listFocusables, onTab = cycleTab })
  ns.placeWindow()
end

----------------------------------------------------------------------------
-- Copy a macro: the body in a text box, already selected, for when CreateMacro fails
-- (slots full, combat lockdown) or the player wants to make it themselves.
----------------------------------------------------------------------------

local copy

local function makeCopy()
  copy = A.frame("Frame", "LevelingCodexCopy", UIParent)
  copy:SetSize(480, 330)
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

  chrome(copy, 80)
  local _, title = A.header(copy, "Copy a macro", 300)
  copy.title = title

  copy.help = copy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  copy.help:SetPoint("TOPLEFT", 24, -34)
  copy.help:SetWidth(432); copy.help:SetJustifyH("LEFT"); copy.help:SetWordWrap(true)
  copy.help:SetTextColor(rgba(C.light))
  copy.macroHelp = "The text is selected: press Ctrl+C (Cmd+C on a Mac). Then in Esc > Macros click New, " ..
    "choose the character tab, name it, and paste with Ctrl+V into the macro box."

  local well = inset(copy)
  well:SetPoint("TOPLEFT", 18, -76); well:SetPoint("BOTTOMRIGHT", -18, 50)

  local eb = CreateFrame("EditBox", nil, well)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetFontObject("GameFontHighlight")
  pcall(eb.SetFont, eb, FONT_MONO, 13, "")
  if eb.SetTextColor then eb:SetTextColor(rgba(C.codeInk)) end
  eb:SetPoint("TOPLEFT", 10, -10)
  eb:SetSize(424, 180)
  eb:SetMaxLetters(0)
  local function reselect(self) self:SetFocus(); self:HighlightText() end
  eb:SetScript("OnEscapePressed", function() copy:Hide() end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  -- read-only: typing puts the macro back, still selected (a paste box keeps what you type)
  eb:SetScript("OnTextChanged", function(self, userInput)
    if copy.paste then return end
    if userInput and copy.body and self:GetText() ~= copy.body then self:SetText(copy.body); self:HighlightText() end
  end)
  eb:SetScript("OnMouseUp", reselect)
  copy.edit = eb

  copy.count = copy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  copy.count:SetPoint("BOTTOMLEFT", 24, 24)
  copy.count:SetWidth(210) -- clear of the buttons at the bottom right (a refused code's reason wraps)
  copy.count:SetJustifyH("LEFT")
  copy.count:SetWordWrap(true)
  copy.count:SetTextColor(rgba(C.dim))

  local function button(label, w, onClick)
    local b = A.button(copy, w, 22)
    b:SetLabel(label)
    b:SetScript("OnClick", onClick)
    return b
  end
  copy.done = button("Done", 90, function() copy:Hide() end)
  copy.done:SetPoint("BOTTOMRIGHT", -20, 18)
  copy.nextB = button("Next", 70, function() ns.showMacroCopy(nil, nil, 1) end)
  copy.nextB:SetPoint("RIGHT", copy.done, "LEFT", -6, 0)
  copy.prevB = button("Back", 70, function() ns.showMacroCopy(nil, nil, -1) end)
  copy.prevB:SetPoint("RIGHT", copy.nextB, "LEFT", -6, 0)
  -- paste mode: hand the text to the entry's onAccept; a refusal says why and keeps the box open
  copy.useB = button("Use this code", 120, function()
    local cur = copy.list and copy.list[copy.index]
    if not (cur and cur.onAccept) then return end
    local ok, why = cur.onAccept(copy.edit:GetText())
    if ok then copy:Hide() else copy.count:SetText(why or "") end
  end)
  copy.useB.codexLabel = "Use this code"
  copy.useB:SetPoint("RIGHT", copy.done, "LEFT", -6, 0)
  local close = CreateFrame("Button", nil, copy, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)
  if C.eui then ns.skinSupport.call("CloseButton", close) end
  ns.skinSupport.fonts(copy) -- the title, help and count (the macro text keeps Arial Narrow)
  copy:HookScript("OnHide", function(self) self.edit:ClearFocus() end) -- give the keyboard back
  -- the controller: the text first, then the box's buttons along one row
  ns.gamepad.attach(copy, { popup = true, focusables = function()
    local out = { { frame = copy.edit, x = 0, y = 0, fixed = true } }
    local i = 0
    for _, k in ipairs({ copy:GetChildren() }) do
      if k:IsShown() and k:GetObjectType() == "Button" then
        i = i + 1
        out[#out + 1] = { frame = k, x = 100 * i, y = 0, fixed = true }
      end
    end
    return out
  end })
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
  copy.title:SetText(cur.copyTitle or (cur.recording and "Copy quest recorder log" or ("Copy the " .. cur.name .. " macro")))
  copy.help:SetText(cur.help or (cur.recording and "Press Ctrl+C to copy the selected log, then paste it into a text file." or copy.macroHelp))
  copy.count:SetText(many and ("Macro " .. copy.index .. " of " .. #copy.list .. " to make yourself") or "")
  copy.nextB:SetShown(many); copy.prevB:SetShown(many)
  copy.paste = cur.paste and true or false
  copy.useB:SetShown(copy.paste)
  copy.body = cur.body or ""
  copy:Show()
  copy.edit:SetText(copy.body)
  copy.edit:SetFocus()
  if not copy.paste then copy.edit:HighlightText() end
end

function ns.toggleWindow()
  if not ns.D then
    ns.say("no guide for your class yet.")
    return
  end
  if not frame then makeFrame() end
  if frame:IsShown() then frame:Hide(); return end
  -- opened within a minute of a banner: open what it was about (once)
  local b = ns.lastBanner
  ns.lastBanner = nil
  if b and GetTime() - b.at <= 60 and renderers[b.tab] then
    activeTab = b.tab
    if b.level then viewLevel = b.level end
    if b.key and ns.profTabShow then ns.profTabShow(b.key) end
  end
  frame:Show()
end

-- Theme change: rebuild the window (and drop the banner) in the new colours. A closed window stays
-- closed (external UI's accent changes rebuild too).
function ns.rebuildForTheme()
  ns.useTheme(ns.themeName())
  ns.questRefresh()
  if ns.loot then ns.loot.refreshTracker() end
  ns.dropToast()
  if copy then copy:Hide(); copy = nil end
  if frame then
    local shown = frame:IsShown()
    frame:Hide(); frame = nil -- hiding first hands it back to Forever's controller navigation
    for _, p in pairs(pools) do for i = 1, #p.list do p.list[i]:Hide() end end
    pools = {}
    makeFrame()
    if shown then frame:Show() end
  end
end

function ns.openTab(tab, atTop)
  if not ns.D then return end
  ns.lastBanner = nil -- a banner click (or any direct opening) has used it
  if not frame then makeFrame() end
  if atTop then
    scrollPos[tab] = 0
    if shownTab == tab then scroll:SetVerticalScroll(0) end
  end
  activeTab = tab
  if frame:IsShown() then refresh() else frame:Show() end
end
