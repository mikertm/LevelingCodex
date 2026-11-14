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
    parchGlow = { 0.16, 0.72, 0.88 }, -- the teal wash along the bottom of Forever's quest parchment
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
    parchGlow = { 0.85, 0.5, 0.16 },
  },
}

-- The active palette. Mutated in place by useTheme, so `local C = ns.C` stays valid everywhere.
local C = {}
ns.C = C

ns.themeVersion = 0 -- bumped on every switch, so long-lived frames know to repaint
function ns.useTheme(name)
  local t = ns.THEMES[name] or ns.THEMES.forever
  for k, v in pairs(t) do C[k] = v end
  ns.themeVersion = ns.themeVersion + 1
end
ns.useTheme("forever")

function ns.rgba(t) return t[1], t[2], t[3], t[4] or 1 end

-- The saved settings, or an empty table before they exist (never nil).
-- SavedVariables may not load in Forever, so nothing may depend on what's in here.
function ns.db() return LevelingCodexDB or {} end
function ns.charDB() return LevelingCodexCharDB or {} end

-- Call an API that might not exist in Forever. Returns ok, results...
function ns.try(fn, ...)
  if type(fn) ~= "function" then return false end
  return pcall(fn, ...)
end

-- GetItemInfo's returns (name, link, quality, ..., sellPrice 11th, classID 12th): C_Item.GetItemInfo
-- where the client has it (WoW: Forever, like retail, reads item info there: asking only the old
-- global left every grey without a price), else the classic global; nil while the item isn't cached,
-- on an error or without either call.
local function okValues(ok, ...) if ok then return ... end end
function ns.itemInfoAPI()
  if type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function" then return C_Item.GetItemInfo end
  if type(GetItemInfo) == "function" then return GetItemInfo end
end
function ns.itemInfo(item)
  local get = ns.itemInfoAPI()
  if not get or item == nil then return nil end
  return okValues(pcall(get, item))
end

-- Timers: C_Timer when the client has it, else a small OnUpdate scheduler.
local jobs, clock
local function schedule(sec, fn, every)
  local job = { at = (GetTime and GetTime() or 0) + sec, fn = fn, every = every }
  if not clock then
    clock = CreateFrame("Frame")
    clock:SetScript("OnUpdate", function()
      local now = GetTime and GetTime() or 0
      local due = {}
      for i = #jobs, 1, -1 do
        local j = jobs[i]
        if j.cancelled then table.remove(jobs, i)
        elseif now >= j.at then
          due[#due + 1] = j
          if j.every then j.at = now + j.every else table.remove(jobs, i) end
        end
      end
      for _, j in ipairs(due) do j.fn() end
    end)
    jobs = {}
  end
  jobs[#jobs + 1] = job
  return job
end

function ns.after(sec, fn)
  if C_Timer and C_Timer.After then C_Timer.After(sec, fn) else schedule(sec, fn) end
end

-- Repeating timer; returns a handle with :Cancel().
function ns.every(sec, fn)
  if C_Timer and C_Timer.NewTicker then return C_Timer.NewTicker(sec, fn) end
  local job = schedule(sec, fn, sec)
  job.Cancel = function(self) self.cancelled = true end
  return job
end

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

-- Copper as "1g 20s 5c" with each part in its coin's colour (colour codes are ASCII).
function ns.coins(copper)
  copper = math.max(0, math.floor(tonumber(copper) or 0))
  local parts = {}
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  if g > 0 then parts[#parts + 1] = "|cffffd100" .. g .. "g|r" end
  if s > 0 then parts[#parts + 1] = "|cffc7c7cf" .. s .. "s|r" end
  if c > 0 or #parts == 0 then parts[#parts + 1] = "|cffeda55f" .. c .. "c|r" end
  return table.concat(parts, " ")
end

-- A whole number with thousands separators: 21400 -> "21,400".
function ns.thousands(n)
  n = math.floor((tonumber(n) or 0) + 0.5)
  local digits = tostring(math.abs(n))
  local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  if out:sub(1, 1) == "," then out = out:sub(2) end
  return (n < 0 and "-" or "") .. out
end

-- Copper as "1g 20s 5c" (ASCII, no coin icons).
function ns.money(copper)
  copper = math.max(0, math.floor(tonumber(copper) or 0))
  local parts = {}
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  if g > 0 then parts[#parts + 1] = g .. "g" end
  if s > 0 then parts[#parts + 1] = s .. "s" end
  if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
  return table.concat(parts, " ")
end

function ns.say(msg)
  local line = ns.GOLD .. "Leveling Codex:|r " .. msg
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(line)
  elseif print then print(line) end
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

-- Cards beside a game window (talent, crafting) ---------------------------------

-- Screen-space edges of a frame (nil where the client won't say).
local function screenEdges(f)
  local function get(m)
    if not f[m] then return nil end
    local ok, v = pcall(f[m], f)
    return (ok and type(v) == "number") and v or nil
  end
  local sc = get("GetEffectiveScale") or 1
  local t, b, l, r = get("GetTop"), get("GetBottom"), get("GetLeft"), get("GetRight")
  return t and t * sc, b and b * sc, l and l * sc, r and r * sc
end

local function shownFrame(f)
  if not f.IsVisible then return false end
  local ok, v = pcall(f.IsVisible, f)
  return ok and v
end

-- Ours: a LevelingCodex* frame or anything inside one.
local function oursOrInside(f)
  for _ = 1, 8 do
    if not f then return false end
    local ok, n = pcall(f.GetName, f)
    if ok and type(n) == "string" and n:find("^LevelingCodex") then return true end
    local pok, p = pcall(f.GetParent, f)
    f = pok and p or nil
  end
  return false
end

-- How far bars hanging off the window's top and bottom edges reach past it (Forever puts its
-- controller hints right under the crafting window). Walks every frame, so it runs when the
-- window opens and again 1 and 3 s later (bars can come a moment after the window).
local function scanEdges(root, state)
  state.edgeUp, state.edgeDown = 0, 0
  local top, bottom, left, right = screenEdges(root)
  if not (top and bottom and EnumerateFrames) then return end
  local bars = {}
  local ok, f = pcall(EnumerateFrames)
  local budget = 8000
  while ok and f and budget > 0 do
    budget = budget - 1
    if f ~= root and shownFrame(f) then
      local t, b, l, r = screenEdges(f)
      -- bar-sized and near the window's top or bottom edge (two bars deep at most)
      if t and b and t > b and t - b < 200 and (t <= bottom + 212 or b >= top - 212) then
        bars[#bars + 1] = { t, b, l, r, f }
      end
    end
    ok, f = pcall(EnumerateFrames, f)
  end
  local up, down = top, bottom
  for _ = 1, 2 do -- twice: a bar under a bar
    for _, x in ipairs(bars) do
      local t, b, l, r = x[1], x[2], x[3], x[4]
      if not (l and r and left and right) or (r > left + 20 and l < right - 20) then
        local below = t <= down + 12 and t >= down - 40 and b < down
        local above = b >= up - 12 and b <= up + 40 and t > up
        if (below or above) and not oursOrInside(x[5]) then
          if below then down = b end
          if above then up = t end
        end
      end
    end
  end
  state.edgeUp, state.edgeDown = up - top, bottom - down
end

local RESCAN = { 1, 2 } -- seconds to the next look after each scan

-- True when the next look for bars around the window is due (callers that only redraw on change
-- call ns.placeByWindow again then).
function ns.windowEdgesDue(state)
  return state.edgeRoot ~= nil and (GetTime and GetTime() or 0) >= (state.edgeNext or 0)
end

-- Put card h above the window when there's room, else below it, else inside its top edge,
-- clear of any bar hanging off the window. state: the caller's table for this window (set
-- state.edgeRoot = nil when the window closes, so the next open looks again).
function ns.placeByWindow(h, root, state)
  local now = GetTime and GetTime() or 0
  if state.edgeRoot ~= root then state.edgeRoot, state.edgeScans, state.edgeNext = root, 0, 0 end
  if now >= (state.edgeNext or 0) then
    pcall(scanEdges, root, state)
    state.edgeScans = (state.edgeScans or 0) + 1
    state.edgeNext = RESCAN[state.edgeScans] and now + RESCAN[state.edgeScans] or math.huge
  end
  h:ClearAllPoints()
  local top, bottom = screenEdges(root)
  local screen = screenEdges(UIParent)
  local hs = select(2, pcall(h.GetEffectiveScale, h))
  hs = type(hs) == "number" and hs > 0 and hs or 1
  local up, down = state.edgeUp or 0, state.edgeDown or 0
  local need = ((h:GetHeight() or 100) + 12) * hs
  local where = "above"
  if top and screen and top + up + need > screen then
    where = (bottom and bottom - down - need > 0) and "below" or "inside"
  end
  local ok
  if where == "above" then ok = pcall(h.SetPoint, h, "BOTTOM", root, "TOP", 0, 6 + up / hs)
  elseif where == "below" then ok = pcall(h.SetPoint, h, "TOP", root, "BOTTOM", 0, -6 - down / hs)
  else ok = pcall(h.SetPoint, h, "TOP", root, "TOP", 0, -44) end
  if not ok then h:ClearAllPoints(); h:SetPoint("TOP", UIParent, "TOP", 0, -80); where = "screen" end
  h.where = where
end
