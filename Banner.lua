-- Banner.lua: level-up chat messages and the unlocks banner ("toast"): after the game's own
-- level-up display, it lists what you unlocked. Movable, scalable, with a test mode.

local _, ns = ...
local C, rgba, plain = ns.C, ns.rgba, ns.plain

----------------------------------------------------------------------------
-- Level-up chat messages
----------------------------------------------------------------------------

function ns.levelUpMessage(level)
  local D = ns.D
  if not D or ns.db().quiet then return end
  local WHITE = ns.WHITE
  local hit, rank, text = ns.talentAt(level)
  if hit then
    ns.say("level " .. level .. " - talent: " .. WHITE .. hit.name .. " " .. rank .. "/" .. hit.max .. "|r (" .. hit.tree .. "). " .. plain(text))
  end
  local t = ns.trainAt(level)
  if t then ns.say("new spells at your trainer: " .. plain(table.concat(t.spells, ", ")) .. ".") end
  local changed = {}
  for _, m in ipairs(D.macros) do
    if m.lo == level then changed[#changed + 1] = m.name end
  end
  if #changed > 0 then
    ns.say("macros for your new level: " .. table.concat(changed, ", ") .. ". Type " .. WHITE .. "/codex macros|r to set them up.")
  end
  local b = ns.bracketFor(level)
  if b and b.level == level then ns.say("new chapter: " .. WHITE .. plain(b.title) .. "|r. Type /codex for the tips.") end
  for _, r in ipairs(ns.profLevelRows and ns.profLevelRows(level) or {}) do
    ns.say(r[4] .. ": " .. string.lower(r[5].action or "Train") .. " " .. WHITE .. r[5].name ..
      "|r now (" .. plain(r[5].where) .. ").")
  end
end

----------------------------------------------------------------------------
-- The banner
----------------------------------------------------------------------------

local toast
-- The card shows after the game's own level-up display is gone, so it takes that display's spot:
-- where we saw it (ns.builtInSpotY), else where the game usually draws it.
local DEFAULT_TOAST = { "TOP", "TOP", 0, -190 }
-- The game's own level-up displays; while one is up, the banner waits its turn.
local BUILT_IN = { "LevelUpDisplay", "EventToastManagerFrame", "LevelUpFrame", "BossBanner" }
local function builtInShowing()
  for _, n in ipairs(BUILT_IN) do
    local f = _G[n]
    if type(f) == "table" and f.IsVisible then
      local ok, v = pcall(f.IsVisible, f)
      if ok and v then return n end
    end
  end
end

-- Forever's own level-up display has an unconfirmed name: look once for a visible frame named
-- like one ("...LevelUp...", "EventToast...") and remember it for next time.
local FALLBACK_WAIT = 3.7 -- no display found: about how long the game's one stays up
local function discoverBuiltIn()
  if not EnumerateFrames then return end
  local f, n = EnumerateFrames(), 0
  while f and n < 20000 do
    n = n + 1
    local ok, name = pcall(f.GetName, f)
    if ok and type(name) == "string" and not name:find("^LevelingCodex") then
      local low = name:lower()
      if low:find("levelup") or low:find("eventtoast") then
        local vok, vis = pcall(f.IsVisible, f)
        if vok and vis then
          table.insert(BUILT_IN, 1, name)
          ns.builtInLevelUp = name
          return name
        end
      end
    end
    local nok, nextF = pcall(EnumerateFrames, f)
    f = nok and nextF or nil
  end
end
-- Remember how far below the top of the screen the game's display sits (in UIParent units).
local function scaleOf(f)
  local ok, s = pcall(f.GetEffectiveScale, f)
  return (ok and type(s) == "number" and s > 0) and s or 1
end
local function noteBuiltInSpot(name)
  local f = name and _G[name]
  if type(f) ~= "table" or not f.GetTop or not UIParent.GetTop then return end
  local ok, top = pcall(f.GetTop, f)
  local uok, uiTop = pcall(UIParent.GetTop, UIParent)
  if not (ok and uok and type(top) == "number" and type(uiTop) == "number") then return end
  local us = scaleOf(UIParent)
  local y = (top * scaleOf(f) - uiTop * us) / us
  if y <= -20 and y >= -600 then ns.builtInSpotY = math.floor(y + 0.5) end -- ignore odd sizes
end
local TOAST_W = 480
local MAX_ROWS = 5
-- seconds on screen before it fades, always: the cursor doesn't hold it (a controller parks the hidden
-- cursor in the middle of the screen, where the banner sits, and the banner never went away)
local HOLD = 8

function ns.getToast() return toast end

function ns.placeToast()
  if not toast then return end
  local db = ns.db()
  local scale = db.toastScale or 1
  local p = db.toastPos
  if not p and ns.builtInSpotY then
    p = { "TOP", "TOP", 0, ns.builtInSpotY / scale } -- offsets are in the card's own (scaled) units
  end
  p = p or DEFAULT_TOAST
  toast:SetScale(scale)
  toast:ClearAllPoints()
  toast:SetPoint(p[1], UIParent, p[2], p[3], p[4])
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
  ns.fadeAccent(left, "HORIZONTAL", 0, 0.9)
  local right = holder:CreateTexture(nil, "ARTWORK")
  right:SetPoint("RIGHT"); right:SetSize(width / 2 - 8, 1)
  ns.fadeAccent(right, "HORIZONTAL", 0.9, 0)
  local gem = holder:CreateTexture(nil, "OVERLAY")
  gem:SetSize(7, 7); gem:SetPoint("CENTER")
  gem:SetColorTexture(rgba(C.gem))
  if gem.SetRotation then gem:SetRotation(math.rad(45)) end
  return holder
end

local function makeRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(380, 34)
  local back = row:CreateTexture(nil, "BACKGROUND")
  back:SetPoint("TOPLEFT", 0, -1); back:SetPoint("BOTTOMRIGHT", 0, 1)
  ns.fadeAccent(back, "HORIZONTAL", 0.12, 0)
  -- icon rim like the game's: thin gold outside, black edge inside
  local frameTex = row:CreateTexture(nil, "BORDER")
  frameTex:SetSize(32, 32); frameTex:SetPoint("LEFT", 1, 0)
  frameTex:SetColorTexture(0.72, 0.58, 0.3, 0.95)
  local edge = row:CreateTexture(nil, "BORDER", nil, 1)
  edge:SetSize(30, 30); edge:SetPoint("CENTER", frameTex, "CENTER")
  edge:SetColorTexture(0, 0, 0, 1)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(28, 28); row.icon:SetPoint("CENTER", frameTex, "CENTER")
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.label:SetPoint("TOPLEFT", frameTex, "TOPRIGHT", 10, 0)
  row.label:SetTextColor(1, 0.82, 0)
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
  alphaAnim(row.anim, 0, 1, 0.35, 2)
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
  ns.fade(l, "HORIZONTAL", C.band[1], C.band[2], C.band[3], 0, 0.7)
  local r = toast:CreateTexture(nil, "BACKGROUND")
  r:SetPoint("TOPLEFT", mid, "TOPRIGHT"); r:SetPoint("BOTTOMRIGHT", 0, 0)
  ns.fade(r, "HORIZONTAL", C.band[1], C.band[2], C.band[3], 0.7, 0)
  -- gold lines along the top and bottom of the band, fading out at the ends (the game's level-up look)
  for _, edge in ipairs({ "TOP", "BOTTOM" }) do
    for side = 1, 2 do
      local g = toast:CreateTexture(nil, "BORDER")
      g:SetHeight(2)
      if side == 1 then
        g:SetPoint(edge .. "LEFT", toast, edge .. "LEFT", 20, edge == "TOP" and -34 or 0)
        g:SetPoint(edge .. "RIGHT", toast, edge, 0, edge == "TOP" and -34 or 0)
        ns.fade(g, "HORIZONTAL", 1, 0.82, 0.25, 0, 0.95)
      else
        g:SetPoint(edge .. "LEFT", toast, edge, 0, edge == "TOP" and -34 or 0)
        g:SetPoint(edge .. "RIGHT", toast, edge .. "RIGHT", -20, edge == "TOP" and -34 or 0)
        ns.fade(g, "HORIZONTAL", 1, 0.82, 0.25, 0.95, 0)
      end
    end
  end

  -- no glow behind the title: in Forever a faded texture that's animated draws as a white box

  -- "LEVELING CODEX" / "New at Level 17": what you unlocked, after the game's own level-up
  toast.header = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  toast.header:SetPoint("TOP", 0, -8)
  toast.header:SetTextColor(rgba(C.goldDim))
  toast.header:SetText("LEVELING CODEX")

  toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  toast.title:SetPoint("TOP", toast.header, "BOTTOM", 0, -3)
  if toast.title:SetFont("Fonts\\MORPHEUS.TTF", 26, "OUTLINE") == false then
    toast.title:SetFontObject("GameFontNormalLarge")
  end
  toast.title:SetTextColor(1, 0.82, 0)
  toast.title:SetShadowColor(0, 0, 0, 1)
  toast.title:SetShadowOffset(1, -1)

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
  scaleAnim(toast.punch, 1.12, 1, 0.3, 1)
  alphaAnim(toast.punch, 0, 1, 0.3, 1)

  -- exit
  toast.leave = toast:CreateAnimationGroup()
  alphaAnim(toast.leave, 1, 0, 1.0, 1)
  toast.leave:SetScript("OnFinished", function()
    toast:Hide()
  end)

  toast:SetScript("OnUpdate", function(self, elapsed)
    if self.unlocked or self.testing or not self.holding then return end
    self.holding = self.holding - elapsed
    if self.holding <= 0 then self.holding = nil; self.leave:Play() end
  end)
  toast:SetScript("OnDragStart", function(self) if self.unlocked or self.testing then self:StartMoving() end end)
  toast:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p1, _, p2, x, y = self:GetPoint(1)
    ns.db().toastPos = { p1, p2, x, y }
  end)
  toast:SetScript("OnMouseUp", function(self, mouseButton)
    if self.unlocked then return end
    if self.testing then
      if mouseButton == "RightButton" then self.testing = nil; self.leave:Play() end
      return
    end
    self.holding = nil; self.leave:Play()
    if mouseButton ~= "RightButton" then (self.onClick or ns.toggleWindow)() end
  end)
  ns.placeToast()
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
  local hit, rank = ns.talentAt(level)
  if hit then
    rows[#rows + 1] = { hit.icon, "TALENT POINT", hit.name .. "  " .. rank .. "/" .. hit.max }
  end
  local t = ns.trainAt(level)
  if t then
    local spells = {}
    for i, s in ipairs(t.spells) do spells[i] = plain(s) end
    rows[#rows + 1] = { t.icons and t.icons[1], "NEW AT YOUR TRAINER", shorten(spells, 3) }
  end
  -- profession training this level opens, next to the class trainer (the banner holds 5 rows)
  for _, r in ipairs(ns.profLevelRows and ns.profLevelRows(level) or {}) do rows[#rows + 1] = r end
  for _, m in ipairs(ns.D.macros) do
    if m.lo == level then
      local older = false
      for _, o in ipairs(ns.D.macros) do
        if o.name == m.name and o.lo < m.lo then older = true end
      end
      rows[#rows + 1] = { m.icon, older and "MACRO UPDATED" or "NEW MACRO", m.name .. "  -  /codex macros" }
    end
  end
  local b = ns.bracketFor(level)
  if b and b.level == level then rows[#rows + 1] = { b.icon, "NEW CHAPTER", plain(b.title) } end
  if #rows == 0 then
    local n = ns.nextTrain(level)
    if n then rows[1] = { "inv_misc_book_09", "NEXT TRAINER VISIT", "Level " .. n.level } end
  end
  return rows
end

local present -- fills and shows the banner (defined below showToast)

local function layoutToast(rowsUsed)
  toast:SetHeight(94 + rowsUsed * 38 + 26)
  toast.hint:ClearAllPoints()
  toast.hint:SetPoint("BOTTOM", 0, 8)
end

-- force: show even when the banner is turned off. test: stays up until right-clicked.
function ns.showToast(level, force, test, waited)
  if not ns.D then return end
  if ns.db().noToast and not force then return end
  -- a real level-up comes after the game's own level-up display: wait (up to 8 s) while it's up,
  -- or, when we can't see one, about as long as it usually lasts
  if not test then
    if waited == nil then
      local shown = builtInShowing() or discoverBuiltIn()
      if shown then ns.builtInLevelUp = shown; noteBuiltInSpot(shown) end
      if not shown then
        ns.after(FALLBACK_WAIT, function() ns.showToast(level, force, test, "done") end)
        return
      end
      waited = 0
    end
    if waited ~= "done" and waited < 8 and builtInShowing() then
      ns.after(0.5, function() ns.showToast(level, force, test, waited + 0.5) end)
      return
    end
  end
  if not toast then makeToast() end
  if toast.unlocked then return end
  present("New at Level " .. level, ns.D.spec .. " " .. ns.CLASS_NAME, unlocksAt(level), test, nil,
    test and "TEST LEVEL-UP  -  drag to move  -  change its size in Settings  -  right-click to close"
    or "Click for the full guide  -  right-click to dismiss")
  if not test then ns.lastBanner = { tab = "level", level = level, at = GetTime() } end
end

-- Any other card in the banner's look, shown right away (profession skill-ups): rows of
-- { icon, label, text }; left-click runs onClick (default: open the Codex). target { tab, key }: what
-- opening the Codex within a minute opens (ns.lastBanner, read by ns.toggleWindow).
function ns.showCard(title, sub, rows, onClick, target)
  if not toast then makeToast() end
  if toast.unlocked or toast.testing then return end
  present(title, sub, rows, false, onClick, "Click for the guide  -  right-click to dismiss")
  if target then ns.lastBanner = { tab = target.tab, key = target.key, at = GetTime() } end
end

present = function(title, sub, rows, test, onClick, hint)
  local n = math.min(#rows, MAX_ROWS)
  for i, row in ipairs(toast.rows) do
    local u = rows[i]
    row.anim:Stop()
    if u and i <= n then
      ns.setIcon(row.icon, u[1])
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
  toast.title:SetText(title)
  toast.sub:SetText(sub)
  toast.testing = test or nil
  toast.onClick = onClick
  toast.hint:SetText(hint)
  toast.hint:SetTextColor(rgba(test and C.gold or C.dim))
  toast.hint:Show()
  layoutToast(n)
  ns.placeToast()

  toast.leave:Stop()
  toast:SetAlpha(1)
  toast:Show()
  toast.enter:Play(); toast.punch:Play()
  toast.holding = HOLD
end

-- Unlocked: the banner stays on screen so you can drag it where you want it.
function ns.setToastUnlocked(on)
  if not toast then makeToast() end
  toast.unlocked = on
  toast.leave:Stop()
  if on then
    toast.title:SetText("New at Level " .. UnitLevel("player"))
    toast.sub:SetText("Drag me where you want me, then click Lock banner in the Codex settings")
    for i, row in ipairs(toast.rows) do
      row.anim:Stop()
      if i == 1 then
        ns.setIcon(row.icon, "inv_misc_book_09"); row.label:SetText("MOVING THE BANNER"); row.value:SetText("Drag to place it")
        row:SetAlpha(1); row:Show()
      else
        row:Hide()
      end
    end
    toast.hint:Hide()
    layoutToast(1)
    ns.placeToast()
    toast:SetAlpha(1)
    toast:Show()
  else
    toast:Hide()
  end
end

-- Theme change: drop the banner so the next one is built in the new colours.
function ns.dropToast()
  if toast then toast:Hide(); toast.testing = nil; toast = nil end
end
