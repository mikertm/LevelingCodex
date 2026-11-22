-- The Leveling Codex: in-game companion for the WoW: Forever leveling guides.
-- skin adapter: the external UI theme (the skin adapter).
--
-- external UI (a UI suite for Retail and Forever) lends other addons its look through
-- RegisterSkin(name, fn), its public skinning API (SKINNING_API.md in its folder). The
-- callback runs once, at PLAYER_LOGIN (at once for a later registration), and only while the player
-- has its third-party skins on for the Codex (external UI options: skin settings > Window Skins >
-- Third-Party Addons). It hands over a facade S: Shell, Panel, CloseButton, PageButton, Checkbox,
-- EditBox, ScrollBar, Font, and the player's panel colour, accent colour and UI font.
--
-- With S the Codex adds the "external UI" theme (the active skin palette, made from those colours and made
-- again whenever external UI's looks change) and draws in it, unless the player picked another theme
-- while external UI was on (db.euiTheme; db.theme keeps the choice for when it isn't installed).
--
-- external UI fades every texture of a frame its Shell or Panel skinned, and fades them all again
-- whenever some Blizzard windows open (the talent window, professions, collections, the calendar).
-- So those never go on a Codex frame: E.backing(f, kind) gives f a child frame at f's own frame level
-- (regions of frames at the same level draw by layer, so f's own art and text stay on top) that holds
-- nothing but external UI's backdrop. Pooled widgets inside the windows are drawn by the Codex itself in
-- the theme's colours (Art.lua's flat look).

local _, ns = ...
local E = {}
ns.skinSupport = E

local S          -- external UI's facade, once its callback ran
local registered -- RegisterSkin was called
local MORPHEUS = "Fonts\\MORPHEUS.TTF"

-- Call one of the facade's functions; false when it's missing or fails, else true and its returns.
local function call(name, ...)
  local fn = S and S[name]
  if type(fn) ~= "function" then return false end
  local ok, a, b, c, d = pcall(fn, ...)
  if not ok then return false end
  return true, a, b, c, d
end
E.call = call

-- external UI's skin is on for the Codex: its callback ran and the player hasn't turned it off since
-- (turning it off takes a /reload in external UI; the Codex drops the theme at once).
function E.available()
  if not S then return false end
  local ok, on = call("IsEnabled")
  return not (ok and on == false)
end

-- The Codex is drawn in the external UI theme right now.
function E.on() return ns.C.eui == true and S ~= nil end

local function unit(v, default)
  v = tonumber(v)
  if v == nil or v ~= v then return default end
  return math.max(0, math.min(1, v))
end

-- The palette: external UI's neutral greys and panel fill, the player's accent for headings and
-- highlights, light text on every card (the parchment cards become its dark panels).
function E.palette()
  local _, ar, ag, ab = call("GetAccentColor")
  ar, ag, ab = unit(ar, 0.047), unit(ag, 0.824), unit(ab, 0.616)
  local _, pr, pg, pb, pa = call("GetPanelColor")
  pr, pg, pb, pa = unit(pr, 0.08), unit(pg, 0.08), unit(pb, 0.08), unit(pa, 0.92)
  local accent = { ar, ag, ab }
  local function toward(t, k) return { ar + (t - ar) * k, ag + (t - ag) * k, ab + (t - ab) * k } end
  local bright = 0.299 * ar + 0.587 * ag + 0.114 * ab > 0.55
  local white, grey = { 0.92, 0.92, 0.92 }, { 0.6, 0.6, 0.6 }
  return {
    eui = true,
    bg = { pr * 0.75, pg * 0.75, pb * 0.75, 0.97 }, panel = { pr + 0.03, pg + 0.03, pb + 0.03, 1 },
    gold = accent, goldDim = toward(0.5, 0.45), edge = { 0.2, 0.2, 0.2, 1 }, edgeSoft = { 0.14, 0.14, 0.14, 1 },
    parch = { pr, pg, pb, pa }, ink = white, inkSoft = { 0.62, 0.62, 0.62 },
    light = white, dim = grey, code = { 0.02, 0.02, 0.02, 1 }, codeInk = { 0.9, 0.9, 0.9 },
    green = { 0.55, 0.9, 0.45 }, accent = accent, gem = { ar, ag, ab, 1 },
    chipFill = { ar, ag, ab, 1 }, chipInk = bright and { 0.05, 0.05, 0.05 } or { 1, 1, 1 },
    btnOn = { ar * 0.55, ag * 0.55, ab * 0.55, 1 }, btnOnInk = { 1, 1, 1 }, btnOff = { pr, pg, pb, pa },
    iconFrame = { 0, 0, 0, 1 }, rowLabel = accent, burst = accent,
    toastHeader = { 0.85, 0.85, 0.85 }, toastTitle = accent, band = { 0, 0, 0 },
    rock = { 0.3, 0.3, 0.3 }, wash = { 0, 0, 0, 0.6 }, glow = accent,
    titleInk = { 1, 1, 1 }, tipTitle = accent, parchGlow = accent,
  }
end

-- The theme to draw in: with external UI's skin on, the player's pick made then (its own theme unless
-- they chose another); without it, db.theme (Forever teal by default).
function ns.themeName()
  local db = ns.db()
  if E.available() then
    local t = db.euiTheme
    if t ~= "forever" and t ~= "codex" then t = "ellesmere" end
    return t
  end
  local t = db.theme
  if t == "ellesmere" or not ns.THEMES[t] then t = "forever" end
  return t
end

-- Settings > Theme. A choice made while external UI's skin is on is kept apart (db.euiTheme), so
-- installing external UI brings its theme even to someone who once picked Codex gold.
function ns.setTheme(name)
  local db = ns.db()
  if E.available() then db.euiTheme = name else db.theme = name end
  ns.rebuildForTheme()
end

-- The player's external UI font (path, flags) while its theme is on; nil otherwise.
function E.font()
  if not E.on() then return nil end
  local ok, path, flags = call("GetFont")
  if ok and type(path) == "string" and path ~= "" then
    return path, type(flags) == "string" and flags or ""
  end
end

-- The face for the Codex's headings: Morpheus, or the external UI font in its theme.
function ns.headFont() return (E.font()) or MORPHEUS end

-- Every font string under frame in the external UI font while its theme is on (S.Font keeps each one's
-- size), or back to the font it had. A heading (fs.codexHead = its size) takes ns.headFont() instead.
-- Each string is done once per theme switch, so it's cheap to call on every refresh: pooled rows made
-- later get theirs then.
function E.fonts(frame)
  if type(frame) ~= "table" or type(frame.GetRegions) ~= "function" then return end
  local on, version = E.on(), ns.themeVersion
  local function walk(f, depth)
    for _, r in ipairs({ f:GetRegions() }) do
      if r.GetObjectType and r:GetObjectType() == "FontString" and r.codexFontFor ~= version then
        r.codexFontFor = version
        if r.codexHead then
          pcall(r.SetFont, r, ns.headFont(), r.codexHead, r.codexHeadFlags or "")
        elseif on then
          if not r.codexFont then
            local ok, path, size, flags = pcall(r.GetFont, r)
            if ok and type(path) == "string" then r.codexFont = { path, size, flags } end
          end
          call("Font", r)
        elseif r.codexFont then
          pcall(r.SetFont, r, r.codexFont[1], r.codexFont[2] or 12, r.codexFont[3] or "")
          r.codexFont = nil
        end
      end
    end
    if depth < 8 and type(f.GetChildren) == "function" then
      for _, c in ipairs({ f:GetChildren() }) do walk(c, depth + 1) end
    end
  end
  walk(frame, 0)
end

-- f's backing frame with external UI's `kind` ("Shell" for a window, "Panel" for a card or the step
-- window; opts as external UI takes them, e.g. { inset = true }): made once, shown while the
-- external UI theme is on and hidden otherwise. Returns true when it shows.
function E.backing(f, kind, opts)
  if not E.on() then
    if f.euiSkin then f.euiSkin:Hide() end
    return false
  end
  local b = f.euiSkin
  if not b then
    b = CreateFrame("Frame", nil, f)
    b.codexSkin = true
    b:SetAllPoints(f)
    b:SetFrameLevel(f:GetFrameLevel())
    f.euiSkin = b
    if not call(kind == "Shell" and "Shell" or "Panel", b, opts) then
      -- external UI refused: a plain fill in its colours, so the window isn't see-through
      local fill = b:CreateTexture(nil, "BACKGROUND", nil, -8)
      fill:SetAllPoints(b)
      fill:SetColorTexture(ns.rgba(ns.C.parch))
    end
  end
  b:Show()
  return true
end

-- An old-style scroll bar (UIPanelScrollFrameTemplate's slider) the way external UI flattens its own:
-- the arrows' art faded, the thumb a 4 px white strip; a modern one through S.ScrollBar.
function E.scrollBar(scroll)
  if not E.on() then return end
  local sb = scroll and (scroll.ScrollBar or (scroll.GetName and scroll:GetName() and _G[scroll:GetName() .. "ScrollBar"]))
  if type(sb) ~= "table" then return end
  call("ScrollBar", sb)
  for _, key in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
    local b = sb[key]
    if type(b) == "table" then
      for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
        local ok, t = pcall(b[get] or function() end, b)
        if ok and type(t) == "table" and t.SetAlpha then t:SetAlpha(0) end
      end
    end
  end
  local ok, thumb = pcall(sb.GetThumbTexture or function() end, sb)
  if ok and type(thumb) == "table" and thumb.SetColorTexture then
    thumb:SetColorTexture(1, 1, 1, 0.3)
    if thumb.SetWidth then thumb:SetWidth(4) end
  end
end

-- external UI's looks change (its accent colour, live from its options): one repaint 0.4 s after the
-- last change. A colour picker sends a change for every step of a drag, and each rebuild makes new
-- frames (the client never frees one).
local looksRun = 0
local function looksChanged()
  if not S then return end
  looksRun = looksRun + 1
  local run = looksRun
  ns.after(0.4, function()
    if run ~= looksRun or not S then return end
    ns.THEMES.ellesmere = E.palette()
    if ns.started and ns.themeKey == "ellesmere" then ns.rebuildForTheme() end
  end)
end

-- external UI's callback: keep its facade, make the theme, switch to it (now when the Codex has
-- started; otherwise start() picks it).
local function apply(facade)
  if type(facade) ~= "table" then return end
  S = facade
  ns.THEMES.ellesmere = E.palette()
  call("OnLooksChanged", looksChanged)
  if ns.started then
    if ns.themeName() ~= ns.themeKey then ns.rebuildForTheme() end
  else
    ns.useTheme(ns.themeName())
  end
end

-- Register with external UI. At load (the .toc lists it as an optional dependency, so it loaded first)
-- and again from start(), for a client that loaded it after us.
function E.register()
  if registered then return end
  local eui = EllesmereUI
  if type(eui) ~= "table" or type(eui.RegisterSkin) ~= "function" then return end
  registered = true
  pcall(eui.RegisterSkin, "LevelingCodex", apply)
end
E.register()

-- /codex debug
function E.debugLine()
  if type(EllesmereUI) ~= "table" then return "external UI: not installed" end
  if not E.available() then return "external UI: installed, skin off" .. (registered and "" or " (no skin API)") end
  local _, style = call("GetStyle")
  return "external UI: skin on (api " .. tostring(S.apiVersion) .. ", style " .. tostring(style or "?") ..
    "), Codex theme: " .. tostring(ns.themeKey == "ellesmere" and "external skin" or ns.themeKey)
end
