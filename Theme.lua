-- The Leveling Codex: in-game companion for the WoW: Forever leveling guides.
-- Theme.lua: colour themes, ASCII-safe text, controller names and small drawing helpers.
-- Every module shares the addon table `ns`; cross-module calls go through ns at call time,
-- so load order only matters for the values each file reads while it loads.

local _, ns = ...

ns.GOLD, ns.WHITE, ns.GREEN = "|cffffd100", "|cffffffff", "|cff40ff40"
ns.QUESTION_ICON = 134400 -- red question mark: with #showtooltip the macro shows the spell it will cast

-- Colour themes ----------------------------------------------------------------
-- "forever": the WoW: Forever logo teal (#34bad7 / #2081a5 / #094165) with sky and cream.
-- "codex":   the guide site's gold, leather and parchment.
ns.THEMES = {
  forever = {
    bg = { 0.03, 0.08, 0.12, 0.97 }, panel = { 0.05, 0.13, 0.19, 1 },
    gold = { 0.45, 0.85, 0.95 }, goldDim = { 0.27, 0.6, 0.74 }, edge = { 0.2, 0.73, 0.84, 1 },
    edgeSoft = { 0.13, 0.4, 0.52, 1 },
    parch = { 0.95, 0.93, 0.88, 1 }, ink = { 0.04, 0.2, 0.32 }, inkSoft = { 0.14, 0.38, 0.52 },
    light = { 0.88, 0.94, 0.97 }, dim = { 0.58, 0.7, 0.77 }, code = { 0.01, 0.04, 0.06, 1 },
    codeInk = { 0.75, 0.93, 0.98 }, green = { 0.55, 0.9, 0.45 },
    accent = { 0.2, 0.73, 0.84 }, gem = { 0.66, 0.9, 0.98, 1 },
    chipFill = { 0.2, 0.73, 0.84, 1 }, chipInk = { 0.02, 0.12, 0.2 },
    btnOn = { 0.13, 0.55, 0.69, 1 }, btnOnInk = { 0.96, 0.99, 1 }, btnOff = { 0.04, 0.11, 0.16, 1 },
    iconFrame = { 0.2, 0.73, 0.84, 0.9 }, rowLabel = { 0.5, 0.88, 0.97 }, burst = { 0.4, 0.85, 1 },
    toastHeader = { 0.82, 0.93, 0.97 }, toastTitle = { 0.66, 0.9, 0.98 }, band = { 0.01, 0.06, 0.1 },
    rock = { 0.32, 0.5, 0.62 }, wash = { 0.02, 0.06, 0.1, 0.74 }, glow = { 0.2, 0.62, 0.82 },
    titleInk = { 0.66, 0.9, 0.98 }, tipTitle = { 0.45, 0.85, 0.95 },
  },
  codex = {
    bg = { 0.085, 0.07, 0.055, 0.97 }, panel = { 0.13, 0.105, 0.08, 1 },
    gold = { 1, 0.82, 0.3 }, goldDim = { 0.72, 0.57, 0.28 }, edge = { 0.75, 0.6, 0.3, 1 },
    edgeSoft = { 0.45, 0.36, 0.2, 1 },
    parch = { 0.9, 0.85, 0.73, 1 }, ink = { 0.2, 0.13, 0.06 }, inkSoft = { 0.4, 0.3, 0.18 },
    light = { 0.92, 0.88, 0.78 }, dim = { 0.62, 0.58, 0.5 }, code = { 0.05, 0.04, 0.03, 1 },
    codeInk = { 0.95, 0.88, 0.65 }, green = { 0.55, 0.9, 0.45 },
    accent = { 1, 0.82, 0.3 }, gem = { 1, 0.85, 0.35, 1 },
    chipFill = { 0.85, 0.68, 0.32, 1 }, chipInk = { 0.15, 0.09, 0.03 },
    btnOn = { 0.78, 0.6, 0.25, 1 }, btnOnInk = { 0.15, 0.09, 0.03 }, btnOff = { 0.16, 0.12, 0.08, 1 },
    iconFrame = { 0.85, 0.68, 0.25, 0.9 }, rowLabel = { 1, 0.82, 0.3 }, burst = { 1, 0.78, 0.3 },
    toastHeader = { 1, 0.9, 0.6 }, toastTitle = { 1, 0.82, 0 }, band = { 0, 0, 0 },
    rock = { 0.62, 0.48, 0.34 }, wash = { 0.06, 0.045, 0.03, 0.72 }, glow = { 0.55, 0.38, 0.15 },
    titleInk = { 1, 0.86, 0.45 }, tipTitle = { 1, 0.82, 0 },
  },
}

-- The active palette. Mutated in place by useTheme, so `local C = ns.C` stays valid everywhere.
local C = {}
ns.C = C

function ns.useTheme(name)
  local t = ns.THEMES[name] or ns.THEMES.forever
  for k, v in pairs(t) do C[k] = v end
end
ns.useTheme("forever")

function ns.rgba(t) return t[1], t[2], t[3], t[4] or 1 end

-- The saved settings, or an empty table before they exist (never nil).
function ns.db() return LevelingCodexDB or {} end

-- Text -----------------------------------------------------------------------

ns.PADS = {
  xbox   = { L = "LT", R = "RT", A = "A",     B = "B",      X = "X",      Y = "Y" },
  ps     = { L = "L2", R = "R2", A = "Cross", B = "Circle", X = "Square", Y = "Triangle" },
  switch = { L = "ZL", R = "ZR", A = "B",     B = "A",      X = "Y",      Y = "X" },
}

-- Characters the default game font can't draw.
local SWAP = {
  { "↑", "Up" }, { "↓", "Down" }, { "←", "Left" }, { "→", "Right" }, { "⇧", "Shift " },
  { "—", "-" }, { "–", "-" }, { "×", "x" }, { "’", "'" }, { "‘", "'" }, { "“", '"' }, { "”", '"' },
  { "…", "..." }, { "≈", "~" }, { "·", "-" }, { "−", "-" }, { "|", "/" },
}

function ns.plain(s)
  s = tostring(s or "")
  for _, p in ipairs(SWAP) do s = s:gsub(p[1], p[2]) end
  return s
end

-- Turn Xbox button names in guide text into the chosen controller's names.
function ns.padText(s)
  local P = ns.PADS[ns.db().pad or "xbox"] or ns.PADS.xbox
  s = ns.plain(s)
  s = s:gsub("A/B/X/Y", "\2A/\2B/\2X/\2Y")
  s = s:gsub("%f[%w]LT%f[%W]", "\1L"):gsub("%f[%w]RT%f[%W]", "\1R")
  s = s:gsub("(\1[LR]%s*%+%s*)([ABXY])%f[%W]", "%1\2%2")
  s = s:gsub("(mash%a*) ([ABXY])%f[%W]", "%1 \2%2"):gsub("(works) ([ABXY]) and ([ABXY])%f[%W]", "%1 \2%2 and \2%3")
  s = s:gsub("\1([LR])", function(k) return P[k] end):gsub("\2([ABXY])", function(k) return P[k] end)
  return s
end

function ns.say(msg)
  DEFAULT_CHAT_FRAME:AddMessage(ns.GOLD .. "Leveling Codex:|r " .. msg)
end

-- Drawing helpers that work across client versions -----------------------------

function ns.iconPath(name)
  if not name or name == "" then return ns.QUESTION_ICON end
  return "Interface\\Icons\\" .. name
end

-- Missing textures render green in Forever: fall back to the question mark.
function ns.setIcon(tex, name)
  local ok = tex:SetTexture(ns.iconPath(name))
  if ok == false then tex:SetTexture(ns.QUESTION_ICON) end
end

-- Paint a texture as a fade between two colors (both modern and old APIs).
function ns.fade(tex, orient, r, g, b, a1, a2)
  tex:SetColorTexture(1, 1, 1, 1)
  if CreateColor and tex.SetGradient then
    if pcall(tex.SetGradient, tex, orient, CreateColor(r, g, b, a1), CreateColor(r, g, b, a2)) then return end
  end
  if tex.SetGradientAlpha and pcall(tex.SetGradientAlpha, tex, orient, r, g, b, a1, r, g, b, a2) then return end
  tex:SetColorTexture(r, g, b, (a1 + a2) / 2)
end

function ns.fadeAccent(tex, orient, a1, a2)
  ns.fade(tex, orient, C.accent[1], C.accent[2], C.accent[3], a1, a2)
end
