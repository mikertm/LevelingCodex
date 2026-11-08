-- Gamepad.lua: controller support for the Codex's own frames (the window, the copy box).
-- Each time a frame shows it picks a mode:
--   nil       the controller isn't in use: nothing changes (B or Back still closes);
--   "forever" the frame joins Forever's own controller navigation (GamepadMode.FrameControlsManager,
--             SmartNavigation moves its gold focus glow over the frame's buttons);
--   "codex"   the backup when Forever's navigation is missing, refuses the frame or is turned off.
-- LB/RB switch tabs in both modes. Nothing here runs in combat: a frame shown in combat is set up
-- when combat ends, and buttons are left to the game meanwhile.

local _, ns = ...

local G = {}
ns.gamepad = G

local states = {} -- frame -> { opts, mode, why, last, lastWhy, waiting }
local main        -- the window (opts.main), for /codex debug

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

-- Every shown Button, CheckButton or EditBox inside f.
local function pieces(f, out)
  out = out or {}
  local ok, kids = pcall(function() return { f:GetChildren() } end)
  for _, k in ipairs(ok and kids or {}) do
    local sok, shown = pcall(k.IsShown, k)
    if sok and shown then
      local tok, kind = pcall(k.GetObjectType, k)
      if tok and (kind == "Button" or kind == "CheckButton" or kind == "EditBox") then out[#out + 1] = k end
      pieces(k, out)
    end
  end
  return out
end

-- End the frame's current mode (it closed, combat, or the controller went away).
local function leave(f, st)
  if st.mode == "forever" then
    local m = manager()
    if m and type(m.FrameHidden) == "function" and not inCombat() then pcall(m.FrameHidden, m, f) end
  end
  if st.mode then st.last, st.lastWhy = st.mode, st.why end
  st.mode, st.why = nil, nil
end

-- Re-read the frame's buttons after it redrew: tooltip-only pieces stay out of the focus.
function G.refresh(f)
  local st = states[f]
  if not (st and st.mode == "forever") or inCombat() then return end
  local mark, clear = SmartNavigation_MarkFrameIgnored, SmartNavigation_ClearIgnoreStatus
  for _, p in ipairs(pieces(f)) do
    local fn = p.padSkip and mark or clear
    if type(fn) == "function" then pcall(fn, p) end
  end
  local nav = navigation()
  if nav and type(nav.RefreshButtonGroups) == "function" then pcall(nav.RefreshButtonGroups, nav, f) end
end

local function pick(f)
  local st = states[f]
  if not st then return end
  if inCombat() then st.waiting = true; return end
  st.waiting = nil
  local sok, shown = pcall(f.IsShown, f)
  if not (sok and shown) then return end
  if not G.inUse() then
    if st.mode then leave(f, st) end
    return
  end
  if st.mode then return end
  local m = manager()
  if m and ns.db().padNative ~= false then
    local ok, res = pcall(m.FrameShown, m, f, st.opts.popup and true or false)
    if ok and res ~= false then
      st.mode, st.why = "forever", nil
      local nav = navigation()
      if nav and st.opts.scroll and type(nav.SetScrollFrameForFrame) == "function" then
        pcall(nav.SetScrollFrameForFrame, nav, f, st.opts.scroll)
      end
      G.refresh(f)
      return
    end
    st.why = "Forever refused the window"
  end
end

-- B or Back closes; LB/RB switch tabs once a mode is set. Every other button goes to the game.
local function onButton(self, button)
  if inCombat() then return end -- leave input alone in combat
  local st = states[self]
  local close = button == "PAD2" or button == "PADBACK"
  local tab = st and st.mode and st.opts.onTab and (button == "PADLSHOULDER" or button == "PADRSHOULDER")
  pcall(self.SetPropagateGamePadInput, self, not (close or tab))
  if close then
    self:Hide()
  elseif tab then
    st.opts.onTab(button == "PADLSHOULDER" and -1 or 1)
  end
end

-- opts: { main, popup, scroll, focusables, onTab } (see the plan in docs/superpowers/plans).
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
      st.waiting = nil
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
  local open = main and select(2, pcall(main.IsShown, main)) == true
  if st and not open and st.last then mode, why, suffix = st.last, st.lastWhy, " (when the Codex was last open)" end
  local line = "controller: not in use"
  if mode == "forever" then line = "controller: Forever navigation" .. suffix
  elseif mode == "codex" then line = "controller: Codex navigation (" .. tostring(why) .. ")" .. suffix end
  return { line }
end

-- The controller picked up or put down, and combat ending: set up any shown frame again.
local events = CreateFrame("Frame")
for _, ev in ipairs({ "GAME_PAD_ACTIVE_CHANGED", "PLAYER_REGEN_ENABLED" }) do
  pcall(events.RegisterEvent, events, ev)
end
events:SetScript("OnEvent", function(_, event)
  for f, st in pairs(states) do
    if event == "GAME_PAD_ACTIVE_CHANGED" or st.waiting then pick(f) end
  end
end)
