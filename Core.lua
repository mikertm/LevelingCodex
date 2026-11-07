-- The Leveling Codex — in-game companion for the WoW: Forever leveling guides.
-- /codex          show or hide the guide window (Settings button inside for all options)
-- /codex macros   create or update your macros for your current level
-- /codex test     preview the level-up banner
-- /codex reset    put the banner and window back where they started
-- (still work: /codex pad xbox|ps|switch, /codex banner, /codex quiet)

local ADDON_NAME = ...
local ICON = 134400 -- red question mark: with #showtooltip the macro shows the spell it will cast
local GOLD, WHITE, GREY, GREEN = "|cffffd100", "|cffffffff", "|cffa0a0a0", "|cff40ff40"

local D            -- this class's guide data
local CLASS_NAME   -- localized class name
local pendingMacros = false

-- Colour themes ----------------------------------------------------------------
-- "forever": the WoW: Forever logo teal (#34bad7 / #2081a5 / #094165) with sky and cream.
-- "codex":   the guide site's gold, leather and parchment.
local THEMES = {
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
local C = {}
local function useTheme(name)
  local t = THEMES[name] or THEMES.forever
  for k, v in pairs(t) do C[k] = v end
end
useTheme("forever")
local function rgba(t) return t[1], t[2], t[3], t[4] or 1 end

local PADS = {
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

local function plain(s)
  s = tostring(s or "")
  for _, p in ipairs(SWAP) do s = s:gsub(p[1], p[2]) end
  return s
end

-- Turn Xbox button names in guide text into the chosen controller's names.
local function padText(s)
  local P = PADS[LevelingCodexDB.pad or "xbox"] or PADS.xbox
  s = plain(s)
  s = s:gsub("A/B/X/Y", "\2A/\2B/\2X/\2Y")
  s = s:gsub("%f[%w]LT%f[%W]", "\1L"):gsub("%f[%w]RT%f[%W]", "\1R")
  s = s:gsub("(\1[LR]%s*%+%s*)([ABXY])%f[%W]", "%1\2%2")
  s = s:gsub("(mash%a*) ([ABXY])%f[%W]", "%1 \2%2"):gsub("(works) ([ABXY]) and ([ABXY])%f[%W]", "%1 \2%2 and \2%3")
  s = s:gsub("\1([LR])", function(k) return P[k] end):gsub("\2([ABXY])", function(k) return P[k] end)
  return s
end

local function say(msg)
  DEFAULT_CHAT_FRAME:AddMessage(GOLD .. "Leveling Codex:|r " .. msg)
end

----------------------------------------------------------------------------
-- Guide lookups
----------------------------------------------------------------------------

local function talentAt(level)
  if not D then return end
  local rank = 0
  local hit
  for _, p in ipairs(D.plan) do
    if level >= p.from and level <= p.to then hit = p end
  end
  if not hit then return end
  for _, p in ipairs(D.plan) do
    if p.name == hit.name then
      local top = math.min(p.to, level)
      if top >= p.from then rank = rank + (top - p.from + 1) end
    end
  end
  local text = (level == hit.from or hit.more == "") and hit.why or hit.more
  return hit, rank, text
end

local function trainAt(level)
  for _, t in ipairs(D.train) do
    if t.level == level then return t end
  end
end

local function nextTrain(level)
  local best
  for _, t in ipairs(D.train) do
    if t.level > level and (not best or t.level < best.level) then best = t end
  end
  return best
end

local function bracketFor(level)
  local best
  for _, b in ipairs(D.br) do
    if b.level <= level and (not best or b.level > best.level) then best = b end
  end
  return best
end

local function macrosFor(level)
  local list = {}
  for _, m in ipairs(D.macros) do
    if level >= m.lo and level <= m.hi then list[#list + 1] = m end
  end
  return list
end

local function comingMacros(level)
  local list, seen = {}, {}
  for _, m in ipairs(D.macros) do
    if m.lo > level and not seen[m.name .. m.lo] then
      seen[m.name .. m.lo] = true
      list[#list + 1] = m
    end
  end
  table.sort(list, function(a, b) return a.lo < b.lo end)
  return list
end

----------------------------------------------------------------------------
-- Macros
----------------------------------------------------------------------------

local function setupMacros(onlyExisting)
  if not D then return end
  if InCombatLockdown() then
    pendingMacros = true
    say("you're in combat - your macros will be set up when the fight ends.")
    return
  end
  local level = UnitLevel("player")
  local made, updated, failed = 0, 0, {}
  LevelingCodexCharDB.made = LevelingCodexCharDB.made or {}
  for _, m in ipairs(macrosFor(level)) do
    local index = GetMacroIndexByName(m.name)
    if index and index > 0 then
      if not onlyExisting or LevelingCodexCharDB.made[m.name] then
        local ok = pcall(EditMacro, index, m.name, ICON, m.body)
        if ok then updated = updated + 1 else failed[#failed + 1] = m.name end
      end
    elseif not onlyExisting then
      local ok, newIndex = pcall(CreateMacro, m.name, ICON, m.body, true)
      if ok and newIndex then
        made = made + 1
        LevelingCodexCharDB.made[m.name] = true
      else
        failed[#failed + 1] = m.name
      end
    end
  end
  if onlyExisting then
    if updated > 0 then say("updated " .. updated .. " macro(s) for level " .. level .. ".") end
    return
  end
  say(GREEN .. made .. " created|r, " .. updated .. " updated for level " .. level ..
    ". Open " .. WHITE .. "Esc > Macros|r (character tab) and drag them onto your bars - /codex shows where.")
  if #failed > 0 then
    say("couldn't make: " .. table.concat(failed, ", ") .. ". Your character macro slots may be full.")
  end
end

----------------------------------------------------------------------------
-- Level-up messages
----------------------------------------------------------------------------

local function levelUpMessage(level)
  if not D or LevelingCodexDB.quiet then return end
  local hit, rank, text = talentAt(level)
  if hit then
    say("level " .. level .. " - talent: " .. WHITE .. hit.name .. " " .. rank .. "/" .. hit.max .. "|r (" .. hit.tree .. "). " .. plain(text))
  end
  local t = trainAt(level)
  if t then say("new spells at your trainer: " .. plain(table.concat(t.spells, ", ")) .. ".") end
  local changed = {}
  for _, m in ipairs(D.macros) do
    if m.lo == level then changed[#changed + 1] = m.name end
  end
  if #changed > 0 then
    say("macros for your new level: " .. table.concat(changed, ", ") .. ". Type " .. WHITE .. "/codex macros|r to set them up.")
  end
  local b = bracketFor(level)
  if b and b.level == level then say("new chapter: " .. WHITE .. plain(b.title) .. "|r. Type /codex for the tips.") end
end

----------------------------------------------------------------------------
-- Level-up banner (top of the screen, fades in and out like the classic one)
----------------------------------------------------------------------------

local toggleWindow -- set once the window code below exists
local refreshSettings -- set once the settings panel exists
local toast
local DEFAULT_TOAST = { "TOP", "TOP", 0, -150 } -- just below the game's own level-up text
local TOAST_W = 480
local MAX_ROWS = 5
local HOLD = 8 -- seconds on screen before it fades (paused while your mouse is over it)

local function placeToast()
  if not toast then return end
  local p = LevelingCodexDB.toastPos or DEFAULT_TOAST
  toast:SetScale(LevelingCodexDB.toastScale or 1)
  toast:ClearAllPoints()
  toast:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

-- Small helpers that work across client versions -----------------------------

local function iconPath(name)
  if not name or name == "" then return 134400 end
  return "Interface\\Icons\\" .. name
end

local function setIcon(tex, name)
  local ok = tex:SetTexture(iconPath(name))
  if ok == false then tex:SetTexture(134400) end
end

-- Paint a texture as a fade between two colors (both modern and old APIs).
local function fade(tex, orient, r, g, b, a1, a2)
  tex:SetColorTexture(1, 1, 1, 1)
  if CreateColor and tex.SetGradient then
    if pcall(tex.SetGradient, tex, orient, CreateColor(r, g, b, a1), CreateColor(r, g, b, a2)) then return end
  end
  if tex.SetGradientAlpha and pcall(tex.SetGradientAlpha, tex, orient, r, g, b, a1, r, g, b, a2) then return end
  tex:SetColorTexture(r, g, b, (a1 + a2) / 2)
end

local function fadeAccent(tex, orient, a1, a2)
  fade(tex, orient, C.accent[1], C.accent[2], C.accent[3], a1, a2)
end

local function scaleAnim(group, from, to, duration, order, delay)
  local s = group:CreateAnimation("Scale")
  local ok = s.SetScaleFrom and pcall(function() s:SetScaleFrom(from, from); s:SetScaleTo(to, to) end)
  if not ok and s.SetFromScale then ok = pcall(function() s:SetFromScale(from, from); s:SetToScale(to, to) end) end
  if not ok then pcall(s.SetScale, s, to / from, to / from) end
  s:SetDuration(duration); s:SetOrder(order or 1)
  if delay then s:SetStartDelay(delay) end
  if s.SetSmoothing then s:SetSmoothing("OUT") end
  return s
end

local function alphaAnim(group, from, to, duration, order, delay)
  local f = group:CreateAnimation("Alpha")
  f:SetFromAlpha(from); f:SetToAlpha(to); f:SetDuration(duration); f:SetOrder(order or 1)
  if delay then f:SetStartDelay(delay) end
  return f
end

-- A gold rule that fades out at both ends, with a small diamond in the middle.
local function goldRule(parent, width)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(width, 10)
  local left = holder:CreateTexture(nil, "ARTWORK")
  left:SetPoint("LEFT"); left:SetSize(width / 2 - 8, 1)
  fadeAccent(left, "HORIZONTAL", 0, 0.9)
  local right = holder:CreateTexture(nil, "ARTWORK")
  right:SetPoint("RIGHT"); right:SetSize(width / 2 - 8, 1)
  fadeAccent(right, "HORIZONTAL", 0.9, 0)
  local gem = holder:CreateTexture(nil, "OVERLAY")
  gem:SetSize(7, 7); gem:SetPoint("CENTER")
  gem:SetColorTexture(rgba(C.gem))
  if gem.SetRotation then gem:SetRotation(math.rad(45)) end
  return holder
end

-- The banner -----------------------------------------------------------------

local function makeRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(380, 34)
  local back = row:CreateTexture(nil, "BACKGROUND")
  back:SetPoint("TOPLEFT", 0, -1); back:SetPoint("BOTTOMRIGHT", 0, 1)
  fadeAccent(back, "HORIZONTAL", 0.12, 0)
  local frameTex = row:CreateTexture(nil, "BORDER")
  frameTex:SetSize(30, 30); frameTex:SetPoint("LEFT", 2, 0)
  frameTex:SetColorTexture(rgba(C.iconFrame))
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(28, 28); row.icon:SetPoint("CENTER", frameTex, "CENTER")
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.label:SetPoint("TOPLEFT", frameTex, "TOPRIGHT", 10, 0)
  row.label:SetTextColor(rgba(C.rowLabel))
  row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.value:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -2)
  row.value:SetWidth(330); row.value:SetJustifyH("LEFT"); row.value:SetWordWrap(false)

  -- slides in from the left and fades up
  row.anim = row:CreateAnimationGroup()
  local jump = row.anim:CreateAnimation("Translation")
  jump:SetOffset(-28, 0); jump:SetDuration(0); jump:SetOrder(1)
  local slide = row.anim:CreateAnimation("Translation")
  slide:SetOffset(28, 0); slide:SetDuration(0.35); slide:SetOrder(2)
  if slide.SetSmoothing then slide:SetSmoothing("OUT") end
  row.fadeIn = alphaAnim(row.anim, 0, 1, 0.35, 2)
  if row.anim.SetToFinalAlpha then row.anim:SetToFinalAlpha(true) end
  row.anim:SetScript("OnFinished", function() row:SetAlpha(1) end)
  row.jump = jump
  return row
end

local function makeToast()
  toast = CreateFrame("Frame", "LevelingCodexToast", UIParent)
  toast:SetSize(TOAST_W, 200)
  toast:SetFrameStrata("HIGH")
  toast:SetClampedToScreen(true)
  toast:SetMovable(true)
  toast:EnableMouse(true)
  toast:RegisterForDrag("LeftButton")
  toast:Hide()

  -- dark band that fades out at the left and right edges
  local mid = toast:CreateTexture(nil, "BACKGROUND")
  mid:SetPoint("TOPLEFT", 120, -34); mid:SetPoint("BOTTOMRIGHT", -120, 0)
  mid:SetColorTexture(C.band[1], C.band[2], C.band[3], 0.7)
  local l = toast:CreateTexture(nil, "BACKGROUND")
  l:SetPoint("TOPRIGHT", mid, "TOPLEFT"); l:SetPoint("BOTTOMLEFT", 0, 0)
  fade(l, "HORIZONTAL", C.band[1], C.band[2], C.band[3], 0, 0.7)
  local r = toast:CreateTexture(nil, "BACKGROUND")
  r:SetPoint("TOPLEFT", mid, "TOPRIGHT"); r:SetPoint("BOTTOMRIGHT", 0, 0)
  fade(r, "HORIZONTAL", C.band[1], C.band[2], C.band[3], 0.7, 0)

  -- golden burst behind the level number: slow spin and a gentle pulse
  toast.burst = toast:CreateTexture(nil, "BORDER")
  toast.burst:SetSize(300, 300)
  toast.burst:SetPoint("CENTER", toast, "TOP", 0, -58)
  local ok = toast.burst:SetTexture("Interface\\Cooldown\\star4")
  if ok == false then toast.burst:SetColorTexture(C.burst[1], C.burst[2], C.burst[3], 0.15) end
  toast.burst:SetBlendMode("ADD")
  toast.burst:SetVertexColor(rgba(C.burst))
  toast.spin = toast.burst:CreateAnimationGroup()
  local spin = toast.spin:CreateAnimation("Rotation")
  spin:SetDegrees(-360); spin:SetDuration(24)
  toast.spin:SetLooping("REPEAT")
  toast.glow = toast.burst:CreateAnimationGroup()
  alphaAnim(toast.glow, 0.35, 0.8, 1.6, 1)
  toast.glow:SetLooping("BOUNCE")

  toast.header = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  toast.header:SetPoint("TOP", 0, -8)
  toast.header:SetTextColor(rgba(C.toastHeader))
  toast.header:SetText("You have reached")

  toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  toast.title:SetPoint("TOP", toast.header, "BOTTOM", 0, -2)
  if toast.title:SetFont("Fonts\\MORPHEUS.TTF", 44, "OUTLINE") == false then
    toast.title:SetFontObject("GameFontNormalHuge")
  end
  toast.title:SetTextColor(rgba(C.toastTitle))
  toast.title:SetShadowColor(0, 0, 0, 1)
  toast.title:SetShadowOffset(2, -2)

  toast.rule = goldRule(toast, 360)
  toast.rule:SetPoint("TOP", toast.title, "BOTTOM", 0, -4)

  toast.sub = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  toast.sub:SetPoint("TOP", toast.rule, "BOTTOM", 0, -4)
  toast.sub:SetTextColor(0.8, 0.8, 0.8)

  toast.rows = {}
  for i = 1, MAX_ROWS do
    local row = makeRow(toast)
    if i == 1 then row:SetPoint("TOP", toast.sub, "BOTTOM", 0, -10) else row:SetPoint("TOP", toast.rows[i - 1], "BOTTOM", 0, -4) end
    toast.rows[i] = row
  end

  toast.hint = toast:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  toast.hint:SetText("Click for the full guide  -  right-click to dismiss")

  -- entrance: the whole banner fades in while the number punches down into place
  toast.enter = toast:CreateAnimationGroup()
  alphaAnim(toast.enter, 0, 1, 0.3, 1)
  toast.punch = toast.title:CreateAnimationGroup()
  scaleAnim(toast.punch, 2.2, 1, 0.4, 1)
  alphaAnim(toast.punch, 0, 1, 0.25, 1)
  toast.burstIn = toast.burst:CreateAnimationGroup()
  scaleAnim(toast.burstIn, 0.2, 1, 0.6, 1)

  -- exit
  toast.leave = toast:CreateAnimationGroup()
  alphaAnim(toast.leave, 1, 0, 1.0, 1)
  toast.leave:SetScript("OnFinished", function()
    toast:Hide(); toast.spin:Stop(); toast.glow:Stop()
  end)

  toast:SetScript("OnUpdate", function(self, elapsed)
    if self.unlocked or self.testing or not self.holding then return end
    if self:IsMouseOver() then return end
    self.holding = self.holding - elapsed
    if self.holding <= 0 then self.holding = nil; self.leave:Play() end
  end)
  toast:SetScript("OnEnter", function(self)
    if self.leave:IsPlaying() then self.leave:Stop(); self:SetAlpha(1); self.holding = 2 end
  end)
  toast:SetScript("OnDragStart", function(self) if self.unlocked or self.testing then self:StartMoving() end end)
  toast:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p1, _, p2, x, y = self:GetPoint(1)
    LevelingCodexDB.toastPos = { p1, p2, x, y }
  end)
  toast:SetScript("OnMouseUp", function(self, mouseButton)
    if self.unlocked then return end
    if self.testing then
      if mouseButton == "RightButton" then self.testing = nil; self.leave:Play() end
      return
    end
    self.holding = nil; self.leave:Play()
    if mouseButton ~= "RightButton" and toggleWindow then toggleWindow() end
  end)
  placeToast()
end

local function shorten(list, max)
  if #list <= max then return table.concat(list, ", ") end
  local out = {}
  for i = 1, max do out[i] = list[i] end
  return table.concat(out, ", ") .. " +" .. (#list - max) .. " more"
end

-- What you unlocked at this level, as rows of { icon, label, text }.
local function unlocksAt(level)
  local rows = {}
  local hit, rank = talentAt(level)
  if hit then
    rows[#rows + 1] = { hit.icon, "TALENT POINT", hit.name .. "  " .. rank .. "/" .. hit.max }
  end
  local t = trainAt(level)
  if t then
    local spells = {}
    for i, s in ipairs(t.spells) do spells[i] = plain(s) end
    rows[#rows + 1] = { t.icons and t.icons[1], "NEW AT YOUR TRAINER", shorten(spells, 3) }
  end
  for _, m in ipairs(D.macros) do
    if m.lo == level then
      local older = false
      for _, o in ipairs(D.macros) do
        if o.name == m.name and o.lo < m.lo then older = true end
      end
      rows[#rows + 1] = { m.icon, older and "MACRO UPDATED" or "NEW MACRO", m.name .. "  -  /codex macros" }
    end
  end
  local b = bracketFor(level)
  if b and b.level == level then rows[#rows + 1] = { b.icon, "NEW CHAPTER", plain(b.title) } end
  if #rows == 0 then
    local n = nextTrain(level)
    if n then rows[1] = { "inv_misc_book_09", "NEXT TRAINER VISIT", "Level " .. n.level } end
  end
  return rows
end

local function layoutToast(rowsUsed)
  local h = 118 + rowsUsed * 38 + 26
  toast:SetHeight(h)
  toast.hint:ClearAllPoints()
  toast.hint:SetPoint("BOTTOM", 0, 8)
end

local function showToast(level, force, test)
  if not D then return end
  if LevelingCodexDB.noToast and not force then return end
  if not toast then makeToast() end
  if toast.unlocked then return end

  local rows = unlocksAt(level)
  local n = math.min(#rows, MAX_ROWS)
  for i, row in ipairs(toast.rows) do
    local u = rows[i]
    row.anim:Stop()
    if u and i <= n then
      setIcon(row.icon, u[1])
      row.label:SetText(u[2])
      row.value:SetText(u[3])
      row:SetAlpha(0)
      row:Show()
      row.jump:SetStartDelay(0.45 + (i - 1) * 0.12)
      row.anim:Play()
    else
      row:Hide()
    end
  end
  toast.title:SetText("Level " .. level)
  toast.sub:SetText(D.spec .. " " .. CLASS_NAME)
  toast.testing = test or nil
  toast.hint:SetText(test and "TEST LEVEL-UP  -  drag to move  -  change its size in Settings  -  right-click to close"
    or "Click for the full guide  -  right-click to dismiss")
  toast.hint:SetTextColor(rgba(test and C.gold or C.dim))
  toast.hint:Show()
  layoutToast(n)
  placeToast()

  toast.leave:Stop()
  toast:SetAlpha(1)
  toast:Show()
  toast.enter:Play(); toast.punch:Play(); toast.burstIn:Play()
  toast.spin:Play(); toast.glow:Play()
  toast.holding = HOLD
end

-- Unlocked: the banner stays on screen so you can drag it where you want it.
local function setToastUnlocked(on)
  if not toast then makeToast() end
  toast.unlocked = on
  toast.leave:Stop()
  if on then
    toast.title:SetText("Level " .. UnitLevel("player"))
    toast.sub:SetText("Drag me where you want me, then click Lock banner in the Codex settings")
    for i, row in ipairs(toast.rows) do
      row.anim:Stop()
      if i == 1 then
        setIcon(row.icon, "inv_misc_book_09"); row.label:SetText("MOVING THE BANNER"); row.value:SetText("Drag to place it")
        row:SetAlpha(1); row:Show()
      else
        row:Hide()
      end
    end
    toast.hint:Hide()
    layoutToast(1)
    placeToast()
    toast:SetAlpha(1)
    toast:Show()
    toast.spin:Play(); toast.glow:Play()
  else
    toast:Hide(); toast.spin:Stop(); toast.glow:Stop()
  end
end

----------------------------------------------------------------------------
-- Window: styled like the guide pages (dark leather, gold rules, parchment cards)
----------------------------------------------------------------------------

local FONT_HEAD = "Fonts\\MORPHEUS.TTF"
local FONT_MONO = "Fonts\\ARIALN.TTF"

local frame, scroll, content, tabs, levelText, nowBtn
local refresh, placeWindow, updateMini
local viewLevel -- the level the window is showing (defaults to yours)
local activeTab = "level"
local W = 568 -- content width


-- Pools of reusable widgets inside the scrolling content ---------------------

local pools = {}
local rebuildForTheme
local function pool(kind, make)
  pools[kind] = pools[kind] or { list = {}, used = 0, make = make }
  return pools[kind]
end
local function take(kind, make)
  local p = pool(kind, make)
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

-- Place text at (x, y) in content; returns its height.
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
  if fill == C.parch then fade(shade, "VERTICAL", 0.5, 0.35, 0.15, 0.22, 0)
  else fade(shade, "VERTICAL", 0.6, 0.45, 0.2, 0, 0.12) end
  edge = edge or C.edge
  rect(x, y, w, 1, edge, "border"); rect(x, y + h - 1, w, 1, edge, "border")
  rect(x, y, 1, h, edge, "border"); rect(x + w - 1, y, 1, h, edge, "border")
  local e2 = { edge[1], edge[2], edge[3], 0.35 }
  rect(x + 4, y + 4, w - 8, 1, e2, "border"); rect(x + 4, y + h - 5, w - 8, 1, e2, "border")
  rect(x + 4, y + 4, 1, h - 8, e2, "border"); rect(x + w - 5, y + 4, 1, h - 8, e2, "border")
end

local function showTip(self)
  if not self.tipTitle then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(self.tipTitle, rgba(C.tipTitle))
  if self.tipText and self.tipText ~= "" then GameTooltip:AddLine(self.tipText, 1, 1, 1, true) end
  GameTooltip:Show()
end
local function hideTip() GameTooltip:Hide() end

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
  setIcon(f.tex, name)
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
  local h, fs = T(str, x + 8, y + 3, 400, "small", filled and C.chipInk or C.gold)
  local w = fs:GetStringWidth() + 16
  if filled then rect(x, y, w, 18, C.chipFill, "border")
  else box(x, y, w, 18, { 0, 0, 0, 0 }) end
  return w
end

local function goldRuleAt(y)
  local half = (W - 20) / 2
  local l = rect(0, y, half, 1, { 1, 1, 1, 1 }, "border"); fadeAccent(l, "HORIZONTAL", 0, 0.8)
  local r = rect(half + 20, y, half, 1, { 1, 1, 1, 1 }, "border"); fadeAccent(r, "HORIZONTAL", 0.8, 0)
  local g = rect(W / 2 - 4, y - 3, 7, 7, C.gem, "border")
  if g.SetRotation then g:SetRotation(math.rad(45)) end
end

local function sectionTitle(str, y, sub)
  local h = T(str, 0, y, W, "head", C.gold)
  if sub then T(sub, 0, y + 4, W, "small", C.dim, "RIGHT") end
  goldRuleAt(y + h + 6)
  return h + 16
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
    local hit, rank, text = talentAt(V)
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
      local h2, r2 = talentAt(l)
      if h2 then
        icon(h2.icon, x, y, 28, l .. ": " .. h2.name .. " " .. r2 .. "/" .. h2.max, plain(l == h2.from and h2.why or h2.more))
        T(l .. "  " .. h2.name .. " " .. r2 .. "/" .. h2.max, x + 34, y + 7, 140, "small", C.light)
        x = x + 178
      end
    end
  end
  btn("Test level-up", W - 120, stripTop + 2, 120, function()
    showToast(V, true, true)
    if PlaySound then pcall(PlaySound, 888) end
  end, false, "See the level-up banner for level " .. V .. ". Drag it to move it; change its size in Settings; right-click to close.")
  y = stripTop + 40

  -- Trainer card (dark)
  top = y
  y = y + 12
  local t = trainAt(V)
  local n = nextTrain(V)
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
  local list = macrosFor(V)
  T("YOUR MACROS AT LEVEL " .. V, 16, y, 300, "label", C.gold)
  btn("Set up macros", W - 156, y - 4, 140, function() setupMacros(false) end, true,
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
    local hit, rank, text = talentAt(l)
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
  for _, t in ipairs(D.train) do list[#list + 1] = t end
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
  btn("Set up macros", W - 140, y - 30, 140, function() setupMacros(false) end, true,
    "Creates or updates this character's macros for your current level (" .. UnitLevel("player") .. ").")
  y = y + 10
  for _, m in ipairs(macrosFor(V)) do
    local top = y
    y = y + 12
    icon(m.icon, 14, y, 36, m.name, nil)
    T(m.name, 60, y, 300, "head", C.gold)
    T("Levels " .. m.lo .. "-" .. m.hi, 60, y + 22, 200, "small", C.dim)
    local x = W - 14
    local kw = 0
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
  local soon = comingMacros(V)
  if #soon > 0 then
    local s = {}
    for i = 1, math.min(#soon, 6) do s[#s + 1] = soon[i].name .. " at " .. soon[i].lo end
    y = y + T("Coming up:  " .. table.concat(s, ",  "), 0, y, W, "small", C.dim) + 6
  end
  return y
end

renderers.tips = function(V)
  local b = bracketFor(V)
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
  local y = sectionTitle("Settings", 0)
  local function row(label, x, w, on, fn, tip) btn(label, x, y, w, function() fn(); refresh() end, on, tip) end
  local function head(str) T(str, 0, y, W, "label", C.gold); y = y + 20 end

  head("THEME")
  local th = db.theme or "forever"
  row("Forever (teal)", 0, 150, th == "forever", function() db.theme = "forever"; rebuildForTheme() end,
    "The WoW: Forever look: logo teal, sky blue and cream.")
  row("Codex (gold)", 156, 150, th == "codex", function() db.theme = "codex"; rebuildForTheme() end,
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
    if toast and toast.unlocked then setToastUnlocked(false) end
    showToast(viewLevel or UnitLevel("player"), true, true)
    if PlaySound then pcall(PlaySound, 888) end
  end, "Plays a level-up for the level shown in the header and keeps the banner up: drag it where you want it, change its size below, right-click it to close.")
  local unlocked = toast and toast.unlocked
  row(unlocked and "Lock banner" or "Move banner", 252, 120, unlocked, function() setToastUnlocked(not (toast and toast.unlocked)) end,
    "Shows the banner so you can drag it anywhere. Press again to lock it there.")
  row("Reset", 378, 80, false, function() db.toastPos = nil; db.toastScale = 1; placeToast() end)
  y = y + 32
  T("Size", 0, y + 5, 60, "body", C.light)
  row("-", 60, 28, false, function() db.toastScale = math.max(0.5, (db.toastScale or 1) - 0.1); placeToast() end)
  T(math.floor((db.toastScale or 1) * 100 + 0.5) .. "%", 92, y + 5, 50, "body", C.gold, "CENTER")
  row("+", 146, 28, false, function() db.toastScale = math.min(2, (db.toastScale or 1) + 0.1); placeToast() end)
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
    function() db.noMinimap = not db.noMinimap; updateMini() end,
    "Drag the book icon around the edge of the minimap to put it where you like; it remembers the spot.")
  row("Reset position", 186, 140, false, function() db.minimapAngle = nil; updateMini() end)
  y = y + 44

  head("THIS WINDOW")
  T("Size", 0, y + 5, 60, "body", C.light)
  row("-", 60, 28, false, function() db.windowScale = math.max(0.6, (db.windowScale or 1) - 0.1); placeWindow() end)
  T(math.floor((db.windowScale or 1) * 100 + 0.5) .. "%", 92, y + 5, 50, "body", C.gold, "CENTER")
  row("+", 146, 28, false, function() db.windowScale = math.min(1.6, (db.windowScale or 1) + 0.1); placeWindow() end)
  row("Reset position", 186, 140, false, function() db.windowPos = nil; placeWindow() end)
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

placeWindow = function()
  if not frame then return end
  local p = LevelingCodexDB.windowPos
  frame:SetScale(LevelingCodexDB.windowScale or 1)
  frame:ClearAllPoints()
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER") end
end

refresh = function()
  if not (frame and frame:IsShown() and D) then return end
  local me = UnitLevel("player")
  viewLevel = viewLevel or me
  if viewLevel < 1 then viewLevel = 1 elseif viewLevel > 60 then viewLevel = 60 end
  levelText:SetText(viewLevel == me and ("Level " .. viewLevel) or ("Level " .. viewLevel))
  nowBtn:SetLook(viewLevel == me)
  nowBtn.label:SetText(viewLevel == me and "You" or "Back to " .. me)
  for _, t in ipairs(tabs) do
    local on = t.key == activeTab
    t.label:SetTextColor(rgba(on and C.gold or C.dim))
    t.line:SetShown(on)
  end
  releaseAll()
  local h = renderers[activeTab](viewLevel) or 0
  content:SetHeight(math.max(h, 10))
  scroll:SetVerticalScroll(0)
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
  tinsert(UISpecialFrames, "LevelingCodexFrame") -- Esc closes it

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
  fade(vignette, "VERTICAL", 0, 0, 0, 0.45, 0)
  local glow = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  glow:SetPoint("TOPLEFT"); glow:SetPoint("TOPRIGHT"); glow:SetHeight(140)
  fade(glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.3)
  local function line(p1, p2, horiz, inset, a)
    local t = frame:CreateTexture(nil, "BORDER")
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

  -- header (drag here to move)
  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", 6, -6); header:SetPoint("TOPRIGHT", -6, -6); header:SetHeight(70)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() frame:StartMoving() end)
  header:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    local p1, _, p2, x, y = frame:GetPoint(1)
    LevelingCodexDB.windowPos = { p1, p2, x, y }
  end)

  local ring = header:CreateTexture(nil, "BORDER")
  ring:SetSize(50, 50); ring:SetPoint("LEFT", 14, -2); ring:SetColorTexture(rgba(C.edge))
  local crest = header:CreateTexture(nil, "ARTWORK")
  crest:SetPoint("TOPLEFT", ring, "TOPLEFT", 2, -2); crest:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", -2, 2)
  crest:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local _, token = UnitClass("player")
  setIcon(crest, "classicon_" .. string.lower(token or "warrior"))

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
  spec:SetText(D.spec .. " " .. CLASS_NAME)

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
  fadeAccent(divider, "HORIZONTAL", 0.2, 0.9)

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
  placeWindow()
end

local function toggle()
  if not D then
    say("no guide for your class yet.")
    return
  end
  if not frame then makeFrame() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end
toggleWindow = toggle

rebuildForTheme = function()
  useTheme(LevelingCodexDB.theme)
  if toast then toast:Hide(); toast.testing = nil; toast = nil end
  if frame then
    frame:Hide(); frame = nil
    for _, p in pairs(pools) do for i = 1, #p.list do p.list[i]:Hide() end end
    pools = {}
    makeFrame()
    frame:Show()
  end
end

local function openTab(tab)
  if not D then return end
  if not frame then makeFrame() end
  activeTab = tab
  if frame:IsShown() then refresh() else frame:Show(); activeTab = tab; refresh() end
end

----------------------------------------------------------------------------
-- Minimap button: click to open, drag it around the minimap and it stays there
----------------------------------------------------------------------------

local mini

local function placeMini()
  if not mini then return end
  local angle = math.rad(LevelingCodexDB.minimapAngle or 210)
  local r = (Minimap:GetWidth() / 2) + 6
  local x, y = math.cos(angle), math.sin(angle)
  local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
  if square then
    -- slide along the edge of a square minimap
    x = math.max(-1, math.min(1, x * 1.42))
    y = math.max(-1, math.min(1, y * 1.42))
  end
  mini:ClearAllPoints()
  mini:SetPoint("CENTER", Minimap, "CENTER", x * r, y * r)
end

local function miniDrag(self)
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  cx, cy = cx / scale, cy / scale
  LevelingCodexDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx)) % 360
  placeMini()
end

local function makeMini()
  if mini or not Minimap then return end
  mini = CreateFrame("Button", "LevelingCodexMinimapButton", Minimap)
  mini:SetSize(31, 31)
  mini:SetFrameStrata("MEDIUM")
  mini:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  mini:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  mini:RegisterForDrag("LeftButton")

  local back = mini:CreateTexture(nil, "BACKGROUND")
  back:SetSize(20, 20); back:SetPoint("TOPLEFT", 7, -5)
  back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  local ico = mini:CreateTexture(nil, "ARTWORK")
  ico:SetSize(18, 18); ico:SetPoint("TOPLEFT", 7, -6)
  setIcon(ico, "inv_misc_book_09")
  ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  mini.icon = ico
  local border = mini:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  mini:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  mini:SetScript("OnClick", function(_, button)
    if button == "RightButton" then openTab("settings") else toggle() end
  end)
  mini:SetScript("OnDragStart", function(self)
    self.icon:SetTexCoord(0, 1, 0, 1)
    self:SetScript("OnUpdate", miniDrag)
  end)
  mini:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    placeMini()
  end)
  mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("The Leveling Codex", rgba(C.tipTitle))
    if D then GameTooltip:AddLine(D.spec .. " " .. (CLASS_NAME or "") .. " - level " .. UnitLevel("player"), 0.8, 0.8, 0.8) end
    local hit, rank
    if D then hit, rank = talentAt(UnitLevel("player")) end
    if hit then GameTooltip:AddLine("Talent now: " .. hit.name .. " " .. rank .. "/" .. hit.max, 1, 1, 1) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffd100Left-click|r  open the Codex", 1, 1, 1)
    GameTooltip:AddLine("|cffffd100Right-click|r  settings", 1, 1, 1)
    GameTooltip:AddLine("|cffffd100Drag|r  move it around the minimap", 1, 1, 1)
    GameTooltip:Show()
  end)
  mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
  placeMini()
end

updateMini = function()
  if LevelingCodexDB.noMinimap then
    if mini then mini:Hide() end
  else
    makeMini()
    if mini then mini:Show(); placeMini() end
  end
end

----------------------------------------------------------------------------
-- Talent window guide: traces the talent the Codex says to take next
----------------------------------------------------------------------------

-- Talent windows we know about. Forever runs talents on the modern trait system,
-- so we also look for any shown frame with "Talent" in its name.
local TALENT_ROOTS = { "PlayerSpellsFrame", "ClassTalentFrame", "PlayerTalentFrame", "TalentFrame", "LegacySystemFrame" }
local guide = { roots = {} }

local function lower(s) return s and string.lower(s) or nil end

local function spellNameOf(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id); if ok and n then return n end
  end
  if GetSpellInfo then local ok, n = pcall(GetSpellInfo, id); if ok and n then return n end end
end

-- Best guess at a talent button's name, trying the trait system and older layouts.
local function buttonTalentName(b)
  local function try(fn, ...) local ok, a = pcall(fn, ...); if ok then return a end end
  if b.GetDefinitionInfo then
    local info = try(b.GetDefinitionInfo, b)
    if type(info) == "table" then
      if info.overrideName and info.overrideName ~= "" then return info.overrideName end
      local n = spellNameOf(info.spellID or info.overriddenSpellID); if n then return n end
    end
  end
  if b.GetSpellID then local n = spellNameOf(try(b.GetSpellID, b)); if n then return n end end
  if b.GetTalentName then local n = try(b.GetTalentName, b); if n then return n end end
  if type(b.talentName) == "string" then return b.talentName end
  if type(b.name) == "string" then return b.name end
end

local function iconFileID(name)
  if not name or name == "" or not GetFileIDFromPath then return nil end
  local ok, id = pcall(GetFileIDFromPath, "Interface\\Icons\\" .. name)
  if ok and id and id ~= 0 then return id end
end

-- Walk a frame tree looking for the talent: by name first, then by its icon.
local function findTalentButton(root, name, fileID)
  local want = lower(name)
  local byIcon
  local function walk(f, depth)
    if depth > 12 or not f.IsShown or not f:IsShown() then return end
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    if not ok then return end
    for _, k in ipairs(kids) do
      if k.IsShown and k:IsShown() then
        local n = buttonTalentName(k)
        if n and lower(n) == want then return k end
        if fileID and not byIcon and k.GetRegions then
          local rok, regions = pcall(function() return { k:GetRegions() } end)
          if rok then
            for _, r in ipairs(regions) do
              if r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture then
                local tok, tex = pcall(r.GetTexture, r)
                if tok and (tex == fileID) then byIcon = k end
              end
            end
          end
        end
        local found = walk(k, depth + 1)
        if found then return found end
      end
    end
  end
  return walk(root, 0) or byIcon
end

local function shownTalentRoot()
  for _, n in ipairs(TALENT_ROOTS) do
    local f = _G[n]
    if f and f.IsShown and f:IsShown() then return f end
  end
  for f in pairs(guide.roots) do
    if f:IsShown() then return f end
  end
end

-- Find extra talent windows by name (done rarely: on addon load and when a toggle is hooked).
local function discoverRoots()
  if not EnumerateFrames then return end
  local f = EnumerateFrames()
  local n = 0
  while f and n < 20000 do
    n = n + 1
    local ok, name = pcall(f.GetName, f)
    -- never our own trace/hint frames: they'd become the "talent window" and anchor to themselves
    if ok and name and not name:find("^LevelingCodex") and f:IsShown()
      and (name:find("Talent") or name:find("Trait")) and f:GetParent() == UIParent then
      guide.roots[f] = true
    end
    f = EnumerateFrames(f)
  end
end

-- The traced outline: a glowing border, pulsing halo and a bright spark running around it.
local function makeTrace()
  local t = CreateFrame("Frame", "LevelingCodexTalentTrace", UIParent)
  t:SetFrameStrata("FULLSCREEN_DIALOG")
  t:EnableMouse(false)
  t:Hide()
  t.halo = t:CreateTexture(nil, "BACKGROUND")
  t.halo:SetPoint("TOPLEFT", -14, 14); t.halo:SetPoint("BOTTOMRIGHT", 14, -14)
  if t.halo:SetTexture("Interface\\SpellActivationOverlay\\IconAlert") ~= false then
    t.halo:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    t.halo:SetBlendMode("ADD")
  else
    t.halo:SetColorTexture(1, 1, 1, 0.15)
  end
  t.edges = {}
  for i = 1, 4 do t.edges[i] = t:CreateTexture(nil, "OVERLAY") end
  t.edges[1]:SetPoint("TOPLEFT", -3, 3); t.edges[1]:SetPoint("TOPRIGHT", 3, 3); t.edges[1]:SetHeight(2)
  t.edges[2]:SetPoint("BOTTOMLEFT", -3, -3); t.edges[2]:SetPoint("BOTTOMRIGHT", 3, -3); t.edges[2]:SetHeight(2)
  t.edges[3]:SetPoint("TOPLEFT", -3, 3); t.edges[3]:SetPoint("BOTTOMLEFT", -3, -3); t.edges[3]:SetWidth(2)
  t.edges[4]:SetPoint("TOPRIGHT", 3, 3); t.edges[4]:SetPoint("BOTTOMRIGHT", 3, -3); t.edges[4]:SetWidth(2)
  t.spark = t:CreateTexture(nil, "OVERLAY", nil, 2)
  t.spark:SetSize(14, 14)
  if t.spark:SetTexture("Interface\\Cooldown\\star4") == false then t.spark:SetColorTexture(1, 1, 1, 1) end
  t.spark:SetBlendMode("ADD")
  t.spark2 = t:CreateTexture(nil, "OVERLAY", nil, 2)
  t.spark2:SetSize(10, 10)
  if t.spark2:SetTexture("Interface\\Cooldown\\star4") == false then t.spark2:SetColorTexture(1, 1, 1, 1) end
  t.spark2:SetBlendMode("ADD")

  t.tag = CreateFrame("Frame", nil, t)
  t.tag:SetSize(10, 22)
  t.tag:SetPoint("BOTTOM", t, "TOP", 0, 8)
  t.tag.bg = t.tag:CreateTexture(nil, "BACKGROUND"); t.tag.bg:SetAllPoints()
  t.tag.line = t.tag:CreateTexture(nil, "BORDER")
  t.tag.line:SetPoint("BOTTOMLEFT"); t.tag.line:SetPoint("BOTTOMRIGHT"); t.tag.line:SetHeight(2)
  t.tag.text = t.tag:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  t.tag.text:SetPoint("CENTER", 0, 1)

  t.time = 0
  t:SetScript("OnUpdate", function(self, elapsed)
    self.time = self.time + elapsed
    local w0, h0 = self:GetWidth(), self:GetHeight()
    if not w0 or not h0 or w0 <= 0 then return end
    local w, h = w0 + 6, h0 + 6
    local per = 2 * (w + h)
    local function at(d)
      d = d % per
      if d < w then return -3 + d, 3 end
      d = d - w
      if d < h then return w - 3, 3 - d end
      d = d - h
      if d < w then return w - 3 - d, 3 - h end
      return -3, 3 - h + (d - w)
    end
    local x, y = at(self.time * per / 1.6)
    self.spark:ClearAllPoints(); self.spark:SetPoint("CENTER", self, "TOPLEFT", x, y)
    local x2, y2 = at(self.time * per / 1.6 + per / 2)
    self.spark2:ClearAllPoints(); self.spark2:SetPoint("CENTER", self, "TOPLEFT", x2, y2)
    local pulse = 0.55 + 0.45 * math.sin(self.time * 4)
    self.halo:SetAlpha(0.35 + 0.4 * pulse)
    for _, e in ipairs(self.edges) do e:SetAlpha(0.7 + 0.3 * pulse) end
  end)
  return t
end

local function paintTrace(t)
  local a = C.accent
  t.halo:SetVertexColor(a[1], a[2], a[3])
  for _, e in ipairs(t.edges) do e:SetColorTexture(a[1], a[2], a[3], 1) end
  t.spark:SetVertexColor(C.gem[1], C.gem[2], C.gem[3]); t.spark2:SetVertexColor(C.gem[1], C.gem[2], C.gem[3])
  t.tag.bg:SetColorTexture(rgba(C.panel)); t.tag.line:SetColorTexture(rgba(C.edge))
  t.tag.text:SetTextColor(rgba(C.gold))
end

-- The hint card at the top of the talent window.
local function makeHint()
  local h = CreateFrame("Frame", "LevelingCodexTalentHint", UIParent)
  h:SetSize(420, 58)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:EnableMouse(false)
  h:Hide()
  h.bg = h:CreateTexture(nil, "BACKGROUND"); h.bg:SetAllPoints()
  h.edges = {}
  for i = 1, 4 do h.edges[i] = h:CreateTexture(nil, "BORDER") end
  h.edges[1]:SetPoint("TOPLEFT"); h.edges[1]:SetPoint("TOPRIGHT"); h.edges[1]:SetHeight(1)
  h.edges[2]:SetPoint("BOTTOMLEFT"); h.edges[2]:SetPoint("BOTTOMRIGHT"); h.edges[2]:SetHeight(1)
  h.edges[3]:SetPoint("TOPLEFT"); h.edges[3]:SetPoint("BOTTOMLEFT"); h.edges[3]:SetWidth(1)
  h.edges[4]:SetPoint("TOPRIGHT"); h.edges[4]:SetPoint("BOTTOMRIGHT"); h.edges[4]:SetWidth(1)
  h.icon = h:CreateTexture(nil, "ARTWORK")
  h.icon:SetSize(38, 38); h.icon:SetPoint("LEFT", 10, 0); h.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", h.icon, "TOPRIGHT", 10, 0)
  h.name = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h.name:SetPoint("TOPLEFT", h.label, "BOTTOMLEFT", 0, -2)
  h.name:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
  h.next = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.next:SetPoint("TOPLEFT", h.name, "BOTTOMLEFT", 0, -2)
  h.next:SetWidth(350); h.next:SetJustifyH("LEFT"); h.next:SetWordWrap(false)
  return h
end

local function paintHint(h)
  h.bg:SetColorTexture(rgba(C.bg))
  for _, e in ipairs(h.edges) do e:SetColorTexture(rgba(C.edge)) end
  h.label:SetTextColor(rgba(C.goldDim)); h.name:SetTextColor(rgba(C.titleInk)); h.next:SetTextColor(rgba(C.dim))
end

local function talentGuideTick()
  local db = LevelingCodexDB
  local root = (D and not db.noTalentGuide) and shownTalentRoot()
  if not root then
    if guide.trace then guide.trace:Hide() end
    if guide.hint then guide.hint:Hide() end
    guide.button = nil
    return
  end
  local level = UnitLevel("player")
  local hit, rank = talentAt(level)
  if not hit then
    if guide.trace then guide.trace:Hide() end
    if guide.hint then guide.hint:Hide() end
    return
  end
  guide.trace = guide.trace or makeTrace()
  guide.hint = guide.hint or makeHint()
  paintTrace(guide.trace); paintHint(guide.hint)

  -- hint card above the talent window
  local h = guide.hint
  setIcon(h.icon, hit.icon)
  h.label:SetText("LEVELING CODEX  -  LEVEL " .. level .. "  -  " .. string.upper(hit.tree))
  h.name:SetText(hit.name .. "  " .. rank .. "/" .. hit.max)
  local nexts = {}
  for l = level + 1, math.min(level + 2, 60) do
    local h2, r2 = talentAt(l)
    if h2 then nexts[#nexts + 1] = l .. ": " .. h2.name .. " " .. r2 .. "/" .. h2.max end
  end
  h.next:SetText(#nexts > 0 and ("Then  " .. table.concat(nexts, "   ")) or "")
  h:ClearAllPoints(); h:SetPoint("BOTTOM", root, "TOP", 0, 6)
  h:Show()

  -- trace the button
  local b = guide.button
  local now = GetTime and GetTime() or 0
  if not (b and b:IsShown() and guide.buttonFor == hit.name .. rank) and now >= (guide.nextSearch or 0) then
    b = findTalentButton(root, hit.name, iconFileID(hit.icon))
    guide.button, guide.buttonFor = b, hit.name .. rank
    guide.nextSearch = b and 0 or now + 1 -- not found yet: look again in a second
  end
  local t = guide.trace
  if b then
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    t.tag.text:SetText("Codex pick  " .. rank .. "/" .. hit.max)
    t.tag:SetWidth(t.tag.text:GetStringWidth() + 16)
    t:Show()
    h.next:SetText((h.next:GetText() or "") ~= "" and h.next:GetText() or "Click the traced talent.")
  else
    t:Hide()
    if (h.next:GetText() or "") == "" then h.next:SetText("Find it in the " .. hit.tree .. " tree.") end
  end
end

local function startTalentGuide()
  if guide.ticker or not C_Timer or not C_Timer.NewTicker then return end
  guide.ticker = C_Timer.NewTicker(0.25, talentGuideTick)
  -- hook the usual ways of opening the talent window so new windows are found quickly
  for _, fn in ipairs({ "ToggleTalentFrame", "ToggleLegacySystemUI", "TalentFrame_LoadUI", "PlayerSpellsFrame_Toggle" }) do
    if type(_G[fn]) == "function" and hooksecurefunc then
      pcall(hooksecurefunc, fn, function() C_Timer.After(0.1, discoverRoots) end)
    end
  end
end

----------------------------------------------------------------------------
-- Events and slash command
----------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(events.RegisterEvent, events, "ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" then
    LevelingCodexDB = LevelingCodexDB or {}
    LevelingCodexCharDB = LevelingCodexCharDB or {}
    useTheme(LevelingCodexDB.theme)
    local localized, token = UnitClass("player")
    CLASS_NAME = localized
    D = LevelingCodexData and LevelingCodexData[token]
    if D then
      say("loaded the " .. D.spec .. " " .. localized .. " guide. Type " .. WHITE .. "/codex|r or click the book on your minimap.")
      updateMini()
      startTalentGuide()
    end
  elseif event == "PLAYER_LEVEL_UP" then
    local level = tonumber(arg1) or UnitLevel("player")
    levelUpMessage(level)
    showToast(level)
    C_Timer.After(1, function()
      if not LevelingCodexDB.noAutoMacros then
        setupMacros(true) -- refresh only the macros this addon made, so versions follow your level
      end
      refresh()
    end)
  elseif event == "ADDON_LOADED" then
    local n = tostring(arg1 or "")
    if n:find("Talent") or n:find("PlayerSpells") or n:find("Trait") or n:find("Legacy") then
      if C_Timer then C_Timer.After(0.5, discoverRoots) end
    end
  elseif event == "PLAYER_REGEN_ENABLED" and pendingMacros then
    pendingMacros = false
    setupMacros(false)
  end
end)

SLASH_LEVELINGCODEX1 = "/codex"
SlashCmdList.LEVELINGCODEX = function(msg)
  msg = strlower(strtrim(msg or ""))
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  if cmd == "" then
    toggle()
  elseif cmd == "macros" then
    setupMacros(false)
  elseif cmd == "pad" and PADS[rest] then
    LevelingCodexDB.pad = rest
    say("showing " .. rest .. " button names.")
    refresh()
  elseif cmd == "test" then
    showToast(tonumber(rest) or UnitLevel("player"), true, true)
    if PlaySound then pcall(PlaySound, 888) end
  elseif cmd == "banner" then
    LevelingCodexDB.noToast = not LevelingCodexDB.noToast
    say("level-up banner " .. (LevelingCodexDB.noToast and "off." or "on."))
  elseif cmd == "quiet" then
    LevelingCodexDB.quiet = not LevelingCodexDB.quiet
    say("level-up messages " .. (LevelingCodexDB.quiet and "off." or "on."))
  elseif cmd == "minimap" then
    LevelingCodexDB.noMinimap = not LevelingCodexDB.noMinimap
    updateMini()
    say("minimap button " .. (LevelingCodexDB.noMinimap and "hidden." or "shown."))
  elseif cmd == "reset" then
    LevelingCodexDB.toastPos, LevelingCodexDB.toastScale = nil, 1
    LevelingCodexDB.windowPos, LevelingCodexDB.windowScale = nil, 1
    placeToast()
    if frame then placeWindow() end
    LevelingCodexDB.minimapAngle = nil
    updateMini()
    say("banner, window and minimap button positions and sizes reset.")
  else
    say("/codex opens the guide - everything else is under its Settings button. Also: /codex macros, /codex test, /codex reset")
  end
end
