-- Gamepad.lua: controller support for the Codex's own frames (the window, the copy box).
-- Each time a frame shows it picks a mode:
--   nil       the controller isn't in use: nothing changes (B or Back still closes);
--   "forever" the frame joins Forever's own controller navigation (GamepadMode.FrameControlsManager,
--             SmartNavigation moves its gold focus glow over the frame's buttons);
--   "codex"   the backup when Forever's navigation is missing, refuses the frame, never focuses it
--             or is turned off in Settings: the frame moves its own gold highlight with the D-pad,
--             A presses, the right stick scrolls.
-- LB/RB switch tabs and B closes in every mode. Nothing here runs in combat: a frame shown in combat
-- is set up when combat ends, and the Codex's own navigation lets go of the controller as combat starts.

local _, ns = ...

local G = {}
ns.gamepad = G

local states = {} -- frame -> { opts, mode, why, last, lastWhy, waiting, focus, keep, stickY }
local main        -- the window (opts.main), for /codex debug
local highlight   -- LevelingCodexPadFocus, shared by the window and the copy box

local DIRS = { PADDUP = { 0, -1 }, PADDDOWN = { 0, 1 }, PADDLEFT = { -1, 0 }, PADDRIGHT = { 1, 0 } }
local GOLD = { 1, 0.82, 0 } -- Forever's default focus colour
local STICK_SPEED = 600     -- pixels a second at full tilt

local function inCombat() return InCombatLockdown and InCombatLockdown() end

function G.inUse()
  local ui = type(InputUtil) == "table" and InputUtil.IsGamepadUIEnabled
  if type(ui) == "function" then
    local ok, on = pcall(ui)
    if ok and on then return true end
  end
  if type(IsUsingGamepad) == "function" then
    local ok, on = pcall(IsUsingGamepad)
    if ok and on then return true end
  end
  return false
end

local function manager()
  local gm = GamepadMode
  local m = type(gm) == "table" and gm.FrameControlsManager
  if type(m) == "table" and type(m.FrameShown) == "function" then return m end
end

local function navigation()
  return type(SmartNavigation) == "table" and SmartNavigation or nil
end

local function propagate(f, on)
  if f.SetPropagateGamePadInput and not inCombat() then pcall(f.SetPropagateGamePadInput, f, on) end
end

local function shown(f)
  local ok, v = pcall(f.IsShown, f)
  return ok and v
end

-- Every shown Button, CheckButton or EditBox inside f.
local function pieces(f, out)
  out = out or {}
  local ok, kids = pcall(function() return { f:GetChildren() } end)
  for _, k in ipairs(ok and kids or {}) do
    if shown(k) then
      local tok, kind = pcall(k.GetObjectType, k)
      if tok and (kind == "Button" or kind == "CheckButton" or kind == "EditBox") then out[#out + 1] = k end
      pieces(k, out)
    end
  end
  return out
end

local function inside(piece, f)
  for _ = 1, 12 do
    if not piece then return false end
    if piece == f then return true end
    local ok, p = pcall(piece.GetParent, piece)
    piece = ok and p or nil
  end
  return false
end

----------------------------------------------------------------------------
-- The Codex's own navigation (the backup)
----------------------------------------------------------------------------

local function makeHighlight()
  local h = CreateFrame("Frame", "LevelingCodexPadFocus", UIParent)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:EnableMouse(false)
  h.edges = {}
  for i = 1, 4 do
    local t = h:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
    h.edges[i] = t
  end
  local e = h.edges
  e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(2)
  e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(2)
  e[3]:SetPoint("TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT"); e[3]:SetWidth(2)
  e[4]:SetPoint("TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(2)
  h:Hide()
  return h
end

local function tooltip(piece, on)
  if not piece then return end
  local ok, fn = pcall(piece.GetScript, piece, on and "OnEnter" or "OnLeave")
  if ok and fn then pcall(fn, piece) end
end

local function hideHighlight(f)
  if highlight and (not f or inside(highlight.target, f)) then
    tooltip(highlight.target, false)
    highlight.target = nil
    highlight:Hide()
  end
end

local function list(st)
  local ok, items = false, nil
  if st.opts.focusables then ok, items = pcall(st.opts.focusables) end
  return (ok and type(items) == "table") and items or {}
end

-- Bring a content piece into view (the header and tabs are fixed and never scroll).
local function scrollTo(st, item)
  local sc = st.opts.scroll
  if not sc or item.fixed then return end
  local okOff, off = pcall(sc.GetVerticalScroll, sc)
  off = okOff and tonumber(off) or 0
  local okH, visible = pcall(sc.GetHeight, sc)
  visible = (okH and tonumber(visible) and visible > 0) and visible or 480
  if item.y >= off and item.y <= off + visible then return end
  local okR, range = pcall(sc.GetVerticalScrollRange, sc)
  range = (okR and tonumber(range)) or 0
  local want = math.max(0, math.min(item.y - visible / 2, range))
  pcall(sc.SetVerticalScroll, sc, want)
end

local function focusOn(st, item)
  local old = highlight and highlight.target
  if old and old ~= item.frame then tooltip(old, false) end
  st.focus = item
  highlight = highlight or makeHighlight()
  scrollTo(st, item)
  highlight.target = item.frame
  highlight:ClearAllPoints()
  pcall(highlight.SetPoint, highlight, "TOPLEFT", item.frame, "TOPLEFT", -3, 3)
  pcall(highlight.SetPoint, highlight, "BOTTOMRIGHT", item.frame, "BOTTOMRIGHT", 3, -3)
  highlight:Show()
  if old ~= item.frame then tooltip(item.frame, true) end
end

-- Focus the piece nearest to (x, y), or the first piece of the content in reading order (the
-- header and tabs only when the content has nothing to press).
local function refocus(f, st, x, y)
  local items = list(st)
  local best, bestScore
  for _, it in ipairs(items) do
    local score
    if x then score = (it.x - x) ^ 2 + (it.y - y) ^ 2
    else score = (it.fixed and 1e9 or 0) + it.y * 10000 + it.x end
    if not best or score < bestScore then best, bestScore = it, score end
  end
  if best then focusOn(st, best) else hideHighlight(f) end
end

local ROW = 8 -- pieces within this many pixels up or down share a row

-- Up/down: the nearest row in that direction, then the piece in it closest across. Left/right: the
-- nearest piece in that direction on the same row.
local function step(st, dir)
  local cur = st.focus
  if not cur then return end
  local items = list(st)
  local x, y = cur.x, cur.y
  for _, it in ipairs(items) do
    if it.frame == cur.frame then x, y = it.x, it.y end
  end
  local best, bestKey
  if dir[2] ~= 0 then
    local nearest
    for _, it in ipairs(items) do
      local along = (it.y - y) * dir[2]
      if it.frame ~= cur.frame and along > ROW and (not nearest or along < nearest) then nearest = along end
    end
    if not nearest then return end
    for _, it in ipairs(items) do
      local along = (it.y - y) * dir[2]
      if it.frame ~= cur.frame and along > ROW and along <= nearest + ROW then
        local key = math.abs(it.x - x)
        if not best or key < bestKey then best, bestKey = it, key end
      end
    end
  else
    for _, it in ipairs(items) do
      local along = (it.x - x) * dir[1]
      if it.frame ~= cur.frame and along > 0 and math.abs(it.y - y) <= ROW then
        if not best or along < bestKey then best, bestKey = it, along end
      end
    end
  end
  if best then focusOn(st, best) end
end

local function press(f, st)
  local piece = st.focus and st.focus.frame
  if not (piece and shown(piece)) then return end
  if type(piece.Click) == "function" then pcall(piece.Click, piece)
  elseif type(piece.SetFocus) == "function" then pcall(piece.SetFocus, piece) end
end

-- The right stick scrolls while it's tilted.
local driver = CreateFrame("Frame")
local function stickUpdate(_, elapsed)
  local any = false
  for _, st in pairs(states) do
    local sc = st.mode == "codex" and st.stickY and math.abs(st.stickY) > 0.2 and st.opts.scroll
    if sc then
      any = true
      local ok, off = pcall(sc.GetVerticalScroll, sc)
      local okR, range = pcall(sc.GetVerticalScrollRange, sc)
      off, range = (ok and tonumber(off)) or 0, (okR and tonumber(range)) or 0
      pcall(sc.SetVerticalScroll, sc, math.max(0, math.min(off - st.stickY * STICK_SPEED * elapsed, range)))
    end
  end
  if not any then driver:SetScript("OnUpdate", nil) end
end

local function onStick(self, stick, _, y)
  local st = states[self]
  if not (st and st.mode == "codex") or inCombat() then return end
  if stick == "Right" or stick == "Camera" then
    st.stickY = tonumber(y) or 0
    if math.abs(st.stickY) > 0.2 then driver:SetScript("OnUpdate", stickUpdate) end
  end
end

local function enterCodex(f, st, why)
  st.mode, st.why = "codex", why
  if f.EnableGamePadStick then pcall(f.EnableGamePadStick, f, true) end
  if f.HasScript and select(2, pcall(f.HasScript, f, "OnGamePadStick")) then f:SetScript("OnGamePadStick", onStick) end
  local keep = st.keep
  st.keep = nil
  if keep then refocus(f, st, keep.x, keep.y) else refocus(f, st) end
end

local function leaveCodex(f, st)
  hideHighlight(f)
  st.focus, st.stickY = nil, nil
  if f.EnableGamePadStick and not inCombat() then pcall(f.EnableGamePadStick, f, false) end
  propagate(f, true)
end

----------------------------------------------------------------------------
-- Modes
----------------------------------------------------------------------------

-- End the frame's current mode (it closed, combat, or the controller went away).
local function leave(f, st)
  if st.mode == "forever" then
    local m = manager()
    if m and type(m.FrameHidden) == "function" and not inCombat() then pcall(m.FrameHidden, m, f) end
  elseif st.mode == "codex" then
    leaveCodex(f, st)
  end
  if st.mode then st.last, st.lastWhy = st.mode, st.why end
  st.mode, st.why = nil, nil
end

-- Re-read the frame's pieces after it redrew.
function G.refresh(f)
  local st = states[f]
  if not st or inCombat() then return end
  if st.mode == "codex" then
    local at = st.focus
    if at then refocus(f, st, at.x, at.y) else refocus(f, st) end
    return
  end
  if st.mode ~= "forever" then return end
  -- tooltip-only pieces stay out of Forever's focus
  local mark, clear = SmartNavigation_MarkFrameIgnored, SmartNavigation_ClearIgnoreStatus
  for _, p in ipairs(pieces(f)) do
    local fn = p.padSkip and mark or clear
    if type(fn) == "function" then pcall(fn, p) end
  end
  local nav = navigation()
  if nav and type(nav.RefreshButtonGroups) == "function" then pcall(nav.RefreshButtonGroups, nav, f) end
end

-- Half a second after joining: no focus inside the frame means Forever didn't take it.
local function checkFocus(f)
  local st = states[f]
  if not (st and st.mode == "forever") or inCombat() or not shown(f) then return end
  local nav = navigation()
  local ok, cur = false, nil
  if nav and type(nav.GetCurrentButton) == "function" then ok, cur = pcall(nav.GetCurrentButton, nav) end
  if ok and inside(cur, f) then return end
  local m = manager()
  if m and type(m.FrameHidden) == "function" then pcall(m.FrameHidden, m, f) end
  st.mode = nil
  enterCodex(f, st, "no focus from Forever")
end

local function pick(f)
  local st = states[f]
  if not st then return end
  if inCombat() then st.waiting = true; return end
  st.waiting = nil
  if not shown(f) then return end
  if not G.inUse() then
    if st.mode then leave(f, st) end
    return
  end
  if st.mode then return end
  local m = manager()
  if not m then return enterCodex(f, st, "no Forever navigation") end
  if ns.db().padNative == false then return enterCodex(f, st, "turned off in Settings") end
  local ok, res = pcall(m.FrameShown, m, f, st.opts.popup and true or false)
  if not ok or res == false then return enterCodex(f, st, "Forever refused the window") end
  st.mode, st.why = "forever", nil
  local nav = navigation()
  if nav and st.opts.scroll and type(nav.SetScrollFrameForFrame) == "function" then
    pcall(nav.SetScrollFrameForFrame, nav, f, st.opts.scroll)
  end
  G.refresh(f)
  ns.after(0.5, function() checkFocus(f) end)
end

-- Settings changed (Forever's navigation on or off): set up every shown frame again.
function G.repick()
  if inCombat() then return end
  for f, st in pairs(states) do
    if st.mode then leave(f, st) end
    pick(f)
  end
end

-- B or Back closes; LB/RB switch tabs once a mode is set; in the Codex's own navigation the
-- D-pad moves and A presses. Every other button goes to the game.
local function onButton(self, button)
  if inCombat() then return end -- leave input alone in combat
  local st = states[self]
  local codex = st and st.mode == "codex"
  local close = button == "PAD2" or button == "PADBACK"
  local tab = st and st.mode and st.opts.onTab and (button == "PADLSHOULDER" or button == "PADRSHOULDER")
  local dir = codex and DIRS[button]
  local isPress = codex and button == "PAD1"
  pcall(self.SetPropagateGamePadInput, self, not (close or tab or dir or isPress))
  if close then
    self:Hide()
  elseif tab then
    st.opts.onTab(button == "PADLSHOULDER" and -1 or 1)
  elseif dir then
    step(st, dir)
  elseif isPress then
    press(self, st)
  end
end

-- opts: { main, popup, scroll, focusables, onTab } (see the plan in docs/superpowers/plans).
-- focusables() returns { { frame, x, y, fixed }, ... } at logical positions (y grows downwards).
function G.attach(f, opts)
  states[f] = { opts = opts or {} }
  if opts and opts.main then main = f end
  if f.EnableGamePadButton and f.SetPropagateGamePadInput and f.HasScript
      and pcall(f.HasScript, f, "OnGamePadButtonDown")
      and pcall(f.EnableGamePadButton, f, true) and pcall(f.SetPropagateGamePadInput, f, true) then
    f:SetScript("OnGamePadButtonDown", onButton)
  end
  f:HookScript("OnShow", function(self) pick(self) end)
  f:HookScript("OnHide", function(self)
    local st = states[self]
    if st then
      if st.mode then leave(self, st) end
      st.waiting, st.keep = nil, nil
    end
    propagate(self, true)
  end)
end

function G.mode(f)
  local st = states[f]
  if st then return st.mode, st.why end
end

function G.debugLines()
  local st = main and states[main]
  local mode, why, suffix = st and st.mode, st and st.why, ""
  local open = main and shown(main)
  if st and not open and st.last then mode, why, suffix = st.last, st.lastWhy, " (when the Codex was last open)" end
  local line = "controller: not in use"
  if mode == "forever" then line = "controller: Forever navigation" .. suffix
  elseif mode == "codex" then line = "controller: Codex navigation (" .. tostring(why) .. ")" .. suffix end
  return { line }
end

-- The controller picked up or put down; combat starting (the Codex's own navigation lets go of the
-- controller first, remembering where its highlight was) and ending (set up any shown frame again).
local events = CreateFrame("Frame")
for _, ev in ipairs({ "GAME_PAD_ACTIVE_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
  pcall(events.RegisterEvent, events, ev)
end
events:SetScript("OnEvent", function(_, event)
  for f, st in pairs(states) do
    if event == "PLAYER_REGEN_DISABLED" then
      if st.mode == "codex" then
        st.keep = st.focus and { x = st.focus.x, y = st.focus.y }
        leave(f, st)
        st.waiting = true
      end
    elseif event == "GAME_PAD_ACTIVE_CHANGED" or st.waiting then
      pick(f)
    end
  end
end)
