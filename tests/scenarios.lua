-- Test scenarios. Each S.<name>() raises on failure; tests/run.py runs them per class and API variant.
-- They only use what a player (or the client) can reach: events, /codex, frames by global name,
-- clicks, drags and hovers, so they keep working however the addon is organised inside.

local S = {}
SCENARIOS = S

-- The client's talent-window toggle (the addon hooks it if it exists at login).
function ToggleTalentFrame() if ToggleTalentFrame_Mock then ToggleTalentFrame_Mock() end end

local function check(cond, msg, level)
  if not cond then error("ASSERT: " .. msg, (level or 1) + 1) end
end

local function D() return LevelingCodexData and LevelingCodexData[MOCK.class] end
local function win() return _G.LevelingCodexFrame end
local function toast() return _G.LevelingCodexToast end
local function slash(msg) SlashCmdList.LEVELINGCODEX(msg) end

local function chatHas(pat)
  for _, line in ipairs(MOCK.chat) do if line:find(pat) then return true end end
  return false
end

local function labelOf(b)
  return b.codexLabel or (b.label and b.label._text) or b._text
end

local function findButton(root, pred)
  for _, b in ipairs(MOCK.buttons(root)) do
    local l = labelOf(b)
    if l and pred(l) then return b end
  end
end

local function click(root, text, mouse)
  local b = findButton(root, function(l) return l == text end)
  check(b, "no button '" .. text .. "'", 2)
  b:Click(mouse)
  return b
end

local function hover(b)
  MOCK.fire(b, "OnEnter")
  MOCK.fire(b, "OnLeave")
end

-- the level the plan puts a point in, as the guide reads (nil before 10)
local function planAt(level)
  local hit
  for _, p in ipairs(D().plan) do
    if level >= p.from and level <= p.to then hit = p end
  end
  return hit
end

----------------------------------------------------------------------------
-- Talent window mock: retail-style trait buttons nested a few frames deep.
----------------------------------------------------------------------------

local talent = {}
S.talent = talent

-- mode "name": buttons answer GetDefinitionInfo() with a spellID (C_Traits style)
-- mode "icon": buttons only carry an icon texture
function S.makeTalentWindow(mode, frameName)
  if not D() then return end
  local root = CreateFrame("Frame", frameName or "PlayerSpellsFrame", UIParent)
  root:SetSize(800, 600)
  root:Hide()
  local talents = CreateFrame("Frame", nil, root)
  local canvas = CreateFrame("Frame", nil, talents)
  local trees = {}
  talent.root, talent.byName, talent.mode = root, {}, mode
  local id = 9000
  local function addButton(tree, name, iconName)
    if not trees[tree] then trees[tree] = CreateFrame("Frame", nil, canvas) end
    id = id + 1
    local b = CreateFrame("Button", nil, trees[tree])
    b:SetSize(40, 40)
    local spellID = id
    MOCK.spells[spellID] = name
    if mode == "name" then
      b.GetDefinitionInfo = function() return { spellID = b.spellID } end
      b.spellID = spellID
    end
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\Icons\\" .. iconName)
    b.iconTex = tex
    -- the trait UI's node shapes: circle, square and choice nodes, each with its own border art
    local shapes = { "circle", "square", "choice" }
    b.expectShape = shapes[(id % 3) + 1]
    if mode == "name" then
      b.StateBorder = b:CreateTexture(nil, "OVERLAY")
      b.StateBorder:SetAllPoints()
      b.StateBorder:SetAtlas("talents-node-" .. b.expectShape .. "-yellow")
    else
      b.IconMask = b:CreateTexture(nil, "ARTWORK") -- only the mask tells the shape
      b.IconMask:SetAtlas("talents-node-" .. b.expectShape .. "-mask")
    end
    return b
  end
  -- decoys first, so a sloppy finder picks the wrong thing
  for i = 1, 25 do addButton("Decoy", "Decoy Talent " .. i, "inv_misc_questionmark_decoy" .. i) end
  for _, p in ipairs(D().plan) do
    if not talent.byName[p.name] then talent.byName[p.name] = addButton(p.tree, p.name, p.icon) end
  end
  ToggleTalentFrame_Mock = function() if root:IsShown() then root:Hide() else root:Show() end end
  return root
end

----------------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------------

-- The client's start-up order: our ADDON_LOADED, PLAYER_LOGIN, PLAYER_ENTERING_WORLD.
function S.login()
  MOCK.event("ADDON_LOADED", "LevelingCodex")
  MOCK.event("VARIABLES_LOADED")
  MOCK.event("PLAYER_LOGIN")
  MOCK.event("PLAYER_ENTERING_WORLD", true, false)
  MOCK.advance(1)
  check(type(LevelingCodexDB) == "table", "LevelingCodexDB created")
  check(type(LevelingCodexCharDB) == "table", "LevelingCodexCharDB created")
  if D() then
    check(chatHas("loaded the"), "login message")
    local mini = _G.LevelingCodexMinimapButton
    if LevelingCodexDB.noMinimap then
      check(not (mini and mini:IsShown()), "minimap button hidden when turned off")
    else
      check(mini and mini:IsShown(), "minimap button shown")
    end
  end
end

-- Level 1 -> 60, letting each banner play out.
function S.levelups()
  for level = 2, 60 do
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level, 10, 0, 0, 0, 0, 0)
    MOCK.advance(1.2)
    if D() and not LevelingCodexDB.noToast then
      check(not (toast() and toast():IsShown()), "banner waits for the game's own level-up display (level " .. level .. ")")
    end
    MOCK.advance(3.3)
    if D() and not LevelingCodexDB.noToast then
      local t = toast()
      check(t and t:IsShown(), "banner shown at level " .. level)
      check(t.title and t.title:GetText() == "New at Level " .. level, "banner title at level " .. level)
    end
    MOCK.advance(10)
    if D() then check(not toast():IsShown(), "banner fades by itself at level " .. level) end
  end
end

-- Hovering keeps the banner up; leaving lets it fade; click opens the window.
function S.bannerMouse()
  if not D() then return end
  MOCK.level = 20
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(4.5)
  local t = toast()
  MOCK.mouseOver[t] = true
  MOCK.advance(12)
  check(t:IsShown(), "banner stays while hovered")
  MOCK.mouseOver[t] = nil
  MOCK.advance(12)
  check(not t:IsShown(), "banner fades after mouse leaves")
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(4.5)
  MOCK.fire(t, "OnMouseUp", "LeftButton")
  MOCK.advance(1.5)
  check(not t:IsShown(), "left-click dismisses the banner")
  check(win() and win():IsShown(), "left-click on the banner opens the window")
  win():Hide()
end

-- Banner test mode, drag, right-click close, /codex test N.
function S.bannerTest()
  if not D() then return end
  slash("test")
  MOCK.advance(0.6)
  local t = toast()
  check(t:IsShown(), "test banner shown")
  MOCK.advance(20)
  check(t:IsShown(), "test banner stays up")
  MOCK.drag(t, 40, -25)
  check(LevelingCodexDB.toastPos, "dragging the test banner saves its position")
  MOCK.fire(t, "OnMouseUp", "LeftButton")
  check(t:IsShown(), "left-click keeps the test banner")
  MOCK.fire(t, "OnMouseUp", "RightButton")
  MOCK.advance(1.5)
  check(not t:IsShown(), "right-click closes the test banner")
  for _, l in ipairs({ 1, 9, 10, 30, 59, 60 }) do
    slash("test " .. l)
    MOCK.advance(0.6)
    check(t.title:GetText() == "New at Level " .. l, "/codex test " .. l)
    MOCK.fire(t, "OnMouseUp", "RightButton")
    MOCK.advance(1.5)
  end
end

local TABS = { "This Level", "Talents", "Trainer", "Macros", "Tips", "Professions", "Settings" }

local function openAt(level, tab)
  MOCK.level = level
  if not (win() and win():IsShown()) then slash("") end
  check(win():IsShown(), "window opens")
  local now = findButton(win(), function(l) return l == "You" or l:find("^Back to") end)
  check(now, "level reset button")
  now:Click()
  click(win(), tab)
end

-- Browse every level 1-60 on every tab with the arrows, hovering everything.
function S.browse()
  if not D() then
    slash("")
    check(chatHas("no guide for your class"), "unsupported class message")
    return
  end
  for _, tab in ipairs(TABS) do
    openAt(1, tab)
    for level = 1, 60 do
      local b = MOCK.buttons(win())
      for _, x in ipairs(b) do hover(x) end
      MOCK.staleUnder(win(), tab .. " at " .. level)
      if level < 60 then click(win(), ">") end
    end
    for _ = 1, 65 do click(win(), "<") end
  end
  win():Hide()
end

-- Click every button on every tab, each from a fresh state, at a few levels.
function S.everyButton()
  if not D() then return end
  for _, level in ipairs({ 1, 9, 10, 30, 60 }) do
    for _, tab in ipairs(TABS) do
      openAt(level, tab)
      local n = #MOCK.buttons(win())
      for i = 1, n do
        openAt(level, tab)
        local list = MOCK.buttons(win())
        local b = list[i]
        if b then
          hover(b)
          b:Click("LeftButton")
          MOCK.advance(0.3)
          if win() and win():IsShown() then MOCK.staleUnder(win(), tab .. " after a click") end
        end
      end
      -- leave the banner closed for the next round
      local t = toast()
      if t and t.unlocked then openAt(level, "Settings"); click(win(), "Lock banner") end
      if t and t:IsShown() then MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
    end
  end
  if win() then win():Hide() end
  -- clicking every toggle an odd number of times leaves things off: put the defaults back
  for _, k in ipairs({ "noToast", "quiet", "noAutoMacros", "noTalentGuide", "noMinimap", "noAutoTrack", "noProfCards", "noCraftGuide", "padNative" }) do
    if LevelingCodexDB[k] then
      LevelingCodexDB[k] = nil
    end
  end
  slash("minimap"); slash("minimap") -- re-apply the minimap setting
end

-- Settings: both themes, all pad names, banner move/lock, sizes, window position.
function S.settings()
  if not D() then return end
  openAt(30, "Settings")
  click(win(), "Codex (gold)")
  check(LevelingCodexDB.theme == "codex", "theme saved")
  check(win() and win():IsShown(), "window rebuilt and shown after theme switch")
  click(win(), "This Level")
  click(win(), "Settings")
  click(win(), "Forever (teal)")
  check(LevelingCodexDB.theme == "forever", "theme back to forever")
  for _, pad in ipairs({ "PlayStation", "Switch", "Xbox" }) do click(win(), "Settings"); click(win(), pad) end
  click(win(), "Move banner")
  check(toast():IsShown() and toast().unlocked, "banner unlocked and shown")
  MOCK.drag(toast(), -30, 10)
  click(win(), "Lock banner")
  check(not toast():IsShown(), "banner hidden after lock")
  click(win(), "+"); click(win(), "+"); click(win(), "-")
  MOCK.drag(win(), 10, 10)
  click(win(), "Settings")
  win():Hide()
end

-- Minimap: show/hide, hover, clicks and drag (round and square minimaps).
function S.minimap()
  if not D() then return end
  local mini = _G.LevelingCodexMinimapButton
  check(mini and mini:IsShown(), "minimap button exists")
  check((mini.icon._path or ""):lower():find("achievement_level_60"), "the Level 60 badge, not the common book")
  if LevelingCodexDB.minimapAngle == nil then
    -- right side, about 10 degrees up: clear of Forever's own buttons and the lower-left spot most addons use
    local _, rel, _, x, y = mini:GetPoint(1)
    check(rel == Minimap and x > 0 and y > 0 and y < x * 0.3, "default spot on the right (" .. tostring(x) .. ", " .. tostring(y) .. ")")
  end
  hover(mini)
  mini:Click("LeftButton")
  check(win():IsShown(), "left-click opens the window")
  mini:Click("LeftButton")
  check(not win():IsShown(), "left-click again closes it")
  mini:Click("RightButton")
  check(win():IsShown(), "right-click opens settings")
  win():Hide()
  for _, shape in ipairs({ "ROUND", "SQUARE" }) do
    MOCK.minimapShape = shape
    MOCK.fire(mini, "OnDragStart", "LeftButton")
    local cx, cy = Minimap:GetCenter()
    MOCK.cursor = { cx, cy + 100 }
    MOCK.advance(0.1)
    MOCK.cursor = { cx - 100, cy }
    MOCK.advance(0.1)
    MOCK.fire(mini, "OnDragStop")
    check(math.abs((LevelingCodexDB.minimapAngle or -1) - 180) < 0.01, "drag saves the angle (" .. shape .. ")")
    local _, rel, _, x, y = mini:GetPoint(1)
    check(rel == Minimap and x < 0 and math.abs(y) < 0.01, "button sits on the left of the minimap (" .. shape .. ")")
  end
  slash("minimap")
  check(not mini:IsShown(), "/codex minimap hides it")
  slash("minimap")
  check(mini:IsShown(), "/codex minimap shows it")
end

----------------------------------------------------------------------------
-- Controller (Gamepad.lua): Forever's navigation, the Codex's own as a backup
----------------------------------------------------------------------------

local function pad(f, b) MOCK.fire(f, "OnGamePadButtonDown", b) end
local function nav() return GamepadMode.FrameControlsManager end

-- Forever's controller UI on: the window joins its navigation.
function S.padForever()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Settings")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "window handed to Forever's window manager")
  check(win()._padScroll ~= nil, "scroll area registered")
  -- tooltip-only icons ignored, clickable pieces not
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and b.padSkip then check(b._padIgnored, "tooltip-only piece ignored") end
    if b:IsShown() and not b.padSkip then check(not b._padIgnored, "clickable piece not ignored: " .. tostring(b.tipTitle)) end
  end
  local n = #MOCK.padRefreshed
  click(win(), "Professions")
  check(#MOCK.padRefreshed > n, "buttons re-read after a redraw")
  -- (Review 4) after switching tabs the marks follow each strip's click
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() then check((b._padIgnored == true) == (b.padSkip == true), "mark follows the strip after a tab switch") end
  end
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: Forever navigation"), "debug line")
  win():Hide()
  check(MOCK.padHidden[win()], "closing hands it back (Review 2: Hide/Esc path)")
  check(win()._padPropagate ~= false, "input passes through once closed")
  MOCK.gamepadUI = nil
end

-- (Review 1) a theme switch rebuilds the window: the old one is handed back, the new one joins.
function S.padThemeRebuild()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Settings")
  local old = win()
  click(win(), "Codex (gold)")
  check(MOCK.padHidden[old], "old frame handed back")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown and win() ~= old, "the rebuilt window is handed over")
  click(win(), "Forever (teal)")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- LB/RB switch tabs (both modes), keeping B-to-close.
function S.padTabs()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level")
  pad(win(), "PADRSHOULDER")
  check(MOCK.textUnder(win()):find("Talent tree") and win()._padPropagate == false, "RB: next tab (Talents), button kept")
  pad(win(), "PADLSHOULDER"); pad(win(), "PADLSHOULDER")
  check(MOCK.textUnder(win()):find("Minimap button"), "LB twice from Talents wraps to Settings")
  pad(win(), "PAD1")
  check(win()._padPropagate == true, "A is Forever's in Forever mode")
  pad(win(), "PAD2")
  check(not win():IsShown(), "B closes")
  MOCK.gamepadUI = nil
end

-- Opened in combat: Forever's functions wait until combat ends (the mock flags any call in combat).
function S.padCombatOpen()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  MOCK.combat = true
  openAt(30, "Settings")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(not shown, "not handed over in combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.6)
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "handed over once combat ends")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- (Review 5) picking up the controller while the window is open.
function S.padPickUp()
  if not D() or not GamepadMode then return end
  openAt(30, "Settings")
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: not in use"), "no controller: not in use")
  MOCK.gamepadUI = true
  MOCK.event("GAME_PAD_ACTIVE_CHANGED", true)
  MOCK.advance(0.6)
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "joins Forever's navigation without reopening")
  win():Hide()
  MOCK.gamepadUI = nil
end

local function focusLabel()
  local t = LevelingCodexPadFocus and LevelingCodexPadFocus.target
  return t and (t.label and t.label:GetText() or t.tipTitle or (t.GetText and t:GetText())) or ""
end

local function reachSkillUpTick()
  for _ = 1, 80 do
    if focusLabel():find("Profession skill%-up cards") then return true end
    pad(win(), "PADDDOWN")
  end
end

-- Backup when Forever refuses: the D-pad, A, scrolling, B.
function S.padBackup()
  if not D() or not GamepadMode then return end
  for _, how in ipairs({ "error", "no focus", "setting", "no manager" }) do
    MOCK.gamepadUI = true
    local saved = GamepadMode
    if how == "error" then MOCK.padRefuse = true end
    if how == "no focus" then MOCK.padNoFocus = true end
    if how == "setting" then LevelingCodexDB.padNative = false end
    if how == "no manager" then GamepadMode = nil; MOCK.gamepad = true end
    openAt(30, "Settings")
    MOCK.advance(0.6)
    check(LevelingCodexPadFocus and LevelingCodexPadFocus:IsShown(), "highlight shown (" .. how .. ")")
    check(reachSkillUpTick(), "D-pad reaches the skill-up tick (" .. how .. ")")
    check(GameTooltip:IsOwned(LevelingCodexPadFocus.target), "focusing shows its tooltip")
    check(win()._padPropagate == false, "the D-pad is the Codex's in this mode")
    pad(win(), "PAD1")
    check(LevelingCodexDB.noProfCards == true, "A ticks it (" .. how .. ")")
    pad(win(), "PAD1")
    check(not LevelingCodexDB.noProfCards, "A unticks it")
    MOCK.chat = {}; slash("debug")
    check(chatHas("controller: Codex navigation %("), "debug says why (" .. how .. ")")
    pad(win(), "PAD2")
    check(not win():IsShown() and not LevelingCodexPadFocus:IsShown(), "B closes, highlight goes")
    MOCK.padRefuse, MOCK.padNoFocus, LevelingCodexDB.padNative, MOCK.gamepad = nil, nil, nil, nil
    GamepadMode = saved
    MOCK.gamepadUI = nil
  end
end

-- Moving past the bottom scrolls; the right stick scrolls.
function S.padBackupScroll()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  for _ = 1, 80 do -- down past the first screen (the content shows about 480 px)
    local t = LevelingCodexPadFocus.target
    if t.padY and t.padY > 600 then break end
    pad(win(), "PADDDOWN")
  end
  check((LevelingCodexPadFocus.target.padY or 0) > 600, "the D-pad reaches the lower part of Settings")
  check(LevelingCodexPadFocus.target:IsShown(), "focused piece visible")
  check(MOCK.scrollOf(win()) > 0, "scrolled to bring a lower piece into view")
  local before = MOCK.scrollOf(win())
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 1)
  MOCK.advance(0.5)
  check(MOCK.scrollOf(win()) < before, "right stick up scrolls up")
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 0)
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- (Review 3) combat starts while the window is open in Codex mode: a D-pad press must not leave
-- the window swallowing the controller, and after combat the highlight is back where it was.
function S.padBackupCombat()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  pad(win(), "PADDDOWN")
  local t = LevelingCodexPadFocus.target
  check(win()._padPropagate == false, "the D-pad is the Codex's before combat")
  MOCK.event("PLAYER_REGEN_DISABLED"); MOCK.combat = true
  pad(win(), "PADDDOWN")
  check(win()._padPropagate == true and not LevelingCodexPadFocus:IsShown(), "in combat the controller goes to the game")
  MOCK.combat = false; MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.1)
  check(LevelingCodexPadFocus:IsShown() and LevelingCodexPadFocus.target == t, "after combat the highlight is back where it was")
  pad(win(), "PADDDOWN")
  check(LevelingCodexPadFocus.target ~= t, "and the D-pad moves it again")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- The copy box: a popup for Forever, the backup otherwise.
function S.padCopyBox()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  S.copyOpen()
  local copy = _G.LevelingCodexCopy
  local shown = false
  for _, f in ipairs(nav().shown) do if f == copy then shown = copy._padPopup == true end end
  check(shown, "copy box joins as a popup")
  pad(copy, "PAD2"); check(not copy:IsShown(), "B closes the copy box")
  LevelingCodexDB.padNative = false
  S.copyOpen()
  check(LevelingCodexPadFocus:IsShown() and LevelingCodexPadFocus.target == copy.edit, "backup focuses the text first")
  pad(copy, "PADDRIGHT")
  check(LevelingCodexPadFocus.target ~= copy.edit, "D-pad moves to the box's buttons")
  pad(copy, "PAD2")
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- Review fixes 1-2: combat starting releases the controller (also after LB/RB in Forever mode)
-- and hands the window back to Forever, so closing it in combat leaves no ghost window behind.
function S.padForeverCombat()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  MOCK.padHidden = {}
  openAt(30, "This Level")
  pad(win(), "PADRSHOULDER")
  MOCK.event("PLAYER_REGEN_DISABLED")
  check(win()._padPropagate == true, "combat starting releases the controller after RB")
  check(MOCK.padHidden[win()], "and hands the window back to Forever before combat")
  MOCK.combat = true
  win():Hide()                                   -- closed with Esc in combat
  MOCK.combat = false; MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.6)
  local ghost = false
  for _, f in ipairs(nav().shown) do if f == win() then ghost = true end end
  check(not ghost, "no ghost window left with Forever")
  slash(""); MOCK.advance(0.6)
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: Forever navigation"), "the next opening joins Forever again")
  -- combat that starts without its event reaching us: the hand-back waits for combat to end
  MOCK.padHidden = {}
  MOCK.combat = true
  win():Hide()
  check(not MOCK.padHidden[win()], "nothing called in combat")
  MOCK.combat = false; MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.1)
  check(MOCK.padHidden[win()], "handed back once combat ends")
  MOCK.gamepadUI = nil
end

-- Review fix 3: the Talents tab's tree nodes and every-point rows are reachable.
function S.padTalents()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Talents")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and b:GetScript("OnClick") then
      check(not b._padIgnored, "Forever: clickable piece not ignored: " .. tostring(b.tipTitle))
    end
  end
  win():Hide()
  LevelingCodexDB.padNative = false
  openAt(30, "Talents")
  local node, row
  for _ = 1, 120 do
    local t = LevelingCodexPadFocus.target
    local title = t and t.tipTitle or ""
    if title:find("^Level %d+:") then row = t; break end
    if title:find("%d/%d") and t:GetScript("OnClick") then node = t end
    pad(win(), "PADDDOWN")
  end
  check(node, "the D-pad reaches a talent tree node")
  check(row, "the D-pad reaches the every-point rows")
  local level = row and tonumber(row.tipTitle:match("^Level (%d+)"))
  pad(win(), "PAD1")
  check(level and MOCK.textUnder(win()):find("Level " .. level) and not MOCK.textUnder(win()):find("Talent tree"),
    "A on a row opens that level")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- Review fix 4: tooltip-only pieces are out of Forever's focus before the window joins, and a
-- redraw that hides the focused piece puts the focus back on the window.
function S.padForeverFocus()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level"); win():Hide()          -- This Level has tooltip-only icons
  for _, b in ipairs(MOCK.buttons(win())) do b._padIgnored = nil end -- fresh widgets
  slash(""); MOCK.advance(0.1)
  check(MOCK.padMarksAtJoin == true, "marks in place when the window joins")
  click(win(), "Settings")
  local tick
  for _, b in ipairs(MOCK.buttons(win())) do if b:IsShown() and b._type == "CheckButton" then tick = b end end
  SmartNavigation._current = tick                -- Forever's focus on a Settings tick
  pad(win(), "PADRSHOULDER")                     -- Settings -> This Level: the tick is gone
  local cur = SmartNavigation:GetCurrentButton()
  check(cur and cur:IsShown() and not cur._padIgnored, "focus back on a shown, clickable piece")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- Review fix 9: LB/RB belong to the window Forever's focus is in.
function S.padForeverActive()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level")
  local other = CreateFrame("Frame", nil, UIParent)
  table.insert(nav().shown, other)               -- the player moved the focus to another window (LT/RT)
  pad(win(), "PADRSHOULDER")
  check(win()._padPropagate == true and not MOCK.textUnder(win()):find("Talent tree"), "LB/RB left to the focused window")
  table.remove(nav().shown)
  pad(win(), "PADRSHOULDER")
  check(MOCK.textUnder(win()):find("Talent tree"), "back on the Codex, RB switches its tab")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- Review fix 7: after the right stick scrolls, the highlight sits on a piece in view.
function S.padStickKeepsFocus()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, -1)
  MOCK.advance(1.5)
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 0)
  local off = MOCK.scrollOf(win())
  check(off > 0, "the stick scrolled down")
  local _, _, _, _, ty = LevelingCodexPadFocus.target:GetPoint(1)
  check(ty and -ty >= off - 30 and -ty <= off + 480, "the highlight is on a piece in view (" .. tostring(ty) .. ", " .. off .. ")")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- Forever's addon compartment (the addons button under the clock) lists the Codex.
function S.compartment()
  if not D() or not AddonCompartmentFrame then return end
  local found = {}
  for _, a in ipairs(AddonCompartmentFrame.registeredAddons) do
    if a.text == "The Leveling Codex" then found[#found + 1] = a end
  end
  check(#found == 1, "the Codex is in the addon compartment once (" .. #found .. ")")
  local entry = found[1]
  if not entry then return end
  check(type(entry.icon) == "string" and entry.icon:lower():find("achievement_level_60"), "with the Level 60 badge")
  entry.func(entry, { buttonName = "LeftButton" })
  check(win() and win():IsShown(), "click opens the Codex")
  entry.func(entry, { buttonName = "LeftButton" })
  check(not win():IsShown(), "click again closes it")
  entry.func(entry, { buttonName = "RightButton" })
  check(win():IsShown() and MOCK.textUnder(win()):find("Minimap button"), "right-click opens Settings")
  win():Hide()
  local owner = CreateFrame("Button", nil, UIParent)
  entry.funcOnEnter(owner)
  local lines = table.concat(GameTooltip._lines or {}, " / ")
  check(GameTooltip:IsOwned(owner) and lines:find("The Leveling Codex") and lines:find("Left%-click"), "hover shows the tooltip")
  check(not lines:find("Drag"), "no minimap drag hint in the compartment")
  entry.funcOnLeave(owner)
end

-- Every slash command, including junk.
function S.slash()
  for _, cmd in ipairs({ "", "", "pad ps", "pad switch", "pad nope", "pad xbox", "test", "test 45", "banner", "banner",
      "quiet", "quiet", "minimap", "minimap", "reset", "debug", "help", "MACROS", "  test  ", "zzz" }) do
    slash(cmd)
    MOCK.advance(0.2)
  end
  if win() then win():Hide() end
  if toast() then MOCK.fire(toast(), "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
end

-- Macros at every level, staying within the client's limits.
function S.macros()
  if not D() then slash("macros"); return end
  for level = 1, 60 do
    MOCK.level = level
    slash("macros")
  end
  check(#MOCK.macros > 0, "macros were created")
  -- combat: deferred until the fight ends
  MOCK.macros = {}
  MOCK.combat = true
  slash("macros")
  check(#MOCK.macros == 0, "no macros made in combat")
  check(chatHas("in combat"), "combat message")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(#MOCK.macros > 0, "macros made when combat ends")
  -- no free slots
  MOCK.macros = {}
  MOCK.charMacroSlots = 0
  slash("macros")
  check(chatHas("couldn't make"), "full macro slots reported")
  local copy = _G.LevelingCodexCopy
  check(copy and copy:IsShown(), "copy box offered when macros can't be made")
  local want = {}
  for _, m in ipairs(D().macros) do if MOCK.level >= m.lo and MOCK.level <= m.hi then want[#want + 1] = m end end
  check(copy.edit:GetText() == want[1].body, "copy box holds the first macro that failed")
  if #want > 1 then
    click(copy, "Next")
    check(copy.edit:GetText() == want[2].body, "Next shows the second failed macro")
    click(copy, "Back")
    check(copy.edit:GetText() == want[1].body, "Back returns to the first")
  end
  click(copy, "Done")
  check(not copy:IsShown(), "Done closes the copy box")
  MOCK.charMacroSlots = nil
end

-- The player already has their own macro under one of the guide's names: Set up macros keeps
-- it, says so, and offers the Codex version in the copy box.
function S.ownMacroSameName()
  if not D() then return end
  MOCK.level = 30
  local list = {}
  for _, m in ipairs(D().macros) do if 30 >= m.lo and 30 <= m.hi then list[#list + 1] = m end end
  if #list == 0 then return end
  local name = list[1].name
  MOCK.macros = { { name = name, icon = 1, body = "/say this one is mine", perChar = true } }
  if LevelingCodexCharDB then LevelingCodexCharDB.made = nil end
  MOCK.chat = {}
  slash("macros")
  check(MOCK.macros[1].body == "/say this one is mine", "player's own " .. name .. " macro kept")
  check(chatHas("kept your own"), "chat says the player's macro was kept")
  local copy = _G.LevelingCodexCopy
  check(copy and copy:IsShown() and copy.edit:GetText() == list[1].body, "copy box offers the Codex version of " .. name)
  copy:Hide()
  -- and the level-up refresh leaves it alone too
  MOCK.level = 31
  MOCK.event("PLAYER_LEVEL_UP", 31)
  MOCK.advance(1.5)
  check(MOCK.macros[1].body == "/say this one is mine", "level-up leaves the player's macro alone")
  MOCK.advance(12)
  MOCK.macros = {}
end

-- The Copy button on a macro card: body selected, read-only, Esc closes and frees the keyboard.
function S.copyMacro()
  if not D() then return end
  openAt(30, "Macros")
  local list = {}
  for _, m in ipairs(D().macros) do if 30 >= m.lo and 30 <= m.hi then list[#list + 1] = m end end
  if #list == 0 then win():Hide(); return end
  click(win(), "Copy")
  local copy = _G.LevelingCodexCopy
  check(copy:IsShown(), "copy box opens")
  local eb = copy.edit
  check(eb:GetText() == list[1].body, "copy box shows the macro body")
  check(eb:HasFocus() and eb._highlight, "body is selected and focused")
  eb._text = "oops"
  MOCK.fire(eb, "OnTextChanged", true)
  check(eb:GetText() == list[1].body, "typing can't change the macro")
  MOCK.fire(eb, "OnEscapePressed")
  check(not copy:IsShown() and not eb:HasFocus(), "Esc closes it and gives the keyboard back")
  win():Hide()
end

-- Each tab keeps its own scroll position.
function S.scrollMemory()
  if not D() then return end
  local function scroller(f)
    for _, c in ipairs((f or win())._children) do
      if c._type == "ScrollFrame" then return c end
      local inner = scroller(c)
      if inner then return inner end
    end
  end
  openAt(30, "Talents")
  local sf = scroller()
  sf:SetVerticalScroll(300)
  local talents = sf:GetVerticalScroll()
  check(talents > 0, "talents tab scrolls")
  click(win(), "Trainer")
  check(sf:GetVerticalScroll() == 0, "trainer tab starts at the top")
  sf:SetVerticalScroll(120)
  click(win(), "Talents")
  check(sf:GetVerticalScroll() == talents, "talents tab scroll kept")
  click(win(), "Trainer")
  check(sf:GetVerticalScroll() == 120, "trainer tab scroll kept")
  click(win(), ">")
  check(sf:GetVerticalScroll() == 120, "browsing levels keeps the scroll")
  win():Hide()
  slash("")
  check(sf:GetVerticalScroll() == 120, "reopening keeps the scroll")
  win():Hide()
end

-- Controller: B or Back closes the window, other buttons pass through to the game.
function S.gamepadClose()
  if not D() or MOCK.minimal then return end
  for _, name in ipairs({ "LevelingCodexFrame", "LevelingCodexCopy" }) do
    if name == "LevelingCodexFrame" then slash("") else S.copyOpen() end
    local f = _G[name]
    check(f:IsShown(), name .. " open")
    MOCK.fire(f, "OnGamePadButtonDown", "PAD1")
    check(f:IsShown() and f._padPropagate == true, "A passes through on " .. name)
    MOCK.combat = true
    MOCK.fire(f, "OnGamePadButtonDown", "PAD2")
    check(f:IsShown() and f._padPropagate == true, "in combat B is left to the game on " .. name)
    MOCK.combat = false
    MOCK.fire(f, "OnGamePadButtonDown", "PAD2")
    check(not f:IsShown(), "B closes " .. name)
    check(f._padPropagate == true, "input passes through again once closed (" .. name .. ")")
  end
  if win() then win():Hide() end
end
function S.copyOpen()
  openAt(30, "Macros")
  local b = findButton(win(), function(l) return l == "Copy" end)
  if b then b:Click() else _G.LevelingCodexCopy:Show() end
  win():Hide()
end

-- The key binding toggles the window.
function S.binding()
  if not D() then return end
  for _, body in ipairs(BINDING_BODIES or {}) do
    local f = assert(loadstring(body))
    f()
    check(win():IsShown(), "binding opens the window")
    f()
    check(not win():IsShown(), "binding closes the window")
  end
end

-- Macros the addon made follow your level (auto-update), your own macros are left alone.
function S.macroAutoUpdate()
  if not D() then return end
  MOCK.macros = {}
  -- a macro of the player's own that shares no name with ours
  MOCK.macros[1] = { name = "MyOwnMacro", icon = 1, body = "/say hi", perChar = true }
  MOCK.level = 1
  for level = 1, 60 do
    MOCK.level = level
    if level == 1 then slash("macros") end
    MOCK.event("PLAYER_LEVEL_UP", level)
    MOCK.advance(1.5)
    for _, m in ipairs(D().macros) do
      if level >= m.lo and level <= m.hi then
        local i = GetMacroIndexByName(m.name)
        if i > 0 and LevelingCodexCharDB.made and LevelingCodexCharDB.made[m.name] then
          check(MOCK.macros[i].body == m.body, "macro " .. m.name .. " follows level " .. level)
        end
      end
    end
  end
  check(MOCK.macros[1].body == "/say hi", "player's own macro untouched")
  if toast() then MOCK.advance(12) end
end

-- Talent tracing against a mock talent window.
local function traceCheck(level, expectTrace)
  local hit = planAt(level)
  local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
  if not hit then
    check(not (trace and trace:IsShown()), "no trace before 10 (level " .. level .. ")")
    return
  end
  check(hint and hint:IsShown(), "hint card shown at level " .. level)
  local _, rel = hint:GetPoint(1)
  check(rel == talent.root, "hint card sits on the talent window at level " .. level)
  if expectTrace then
    check(trace and trace:IsShown(), "trace shown at level " .. level)
    local _, on = trace:GetPoint(1)
    local want = talent.byName[hit.name]
    if talent.mode == "icon" then
      -- talents can share an icon: any button wearing the right icon is a correct match
      check(on and on.iconTex and on.iconTex._tex == want.iconTex._tex, "trace on " .. hit.name .. "'s icon at level " .. level)
    else
      check(on == want, "trace on " .. hit.name .. " at level " .. level)
    end
  end
end

local function runTalentLevels(expectTrace)
  for level = 1, 60 do
    MOCK.level = level
    ToggleTalentFrame()
    MOCK.advance(0.8)
    traceCheck(level, expectTrace)
    ToggleTalentFrame()
    MOCK.advance(0.8)
    local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
    check(not (trace and trace:IsShown()), "trace hidden after closing (level " .. level .. ")")
    check(not (hint and hint:IsShown()), "hint hidden after closing (level " .. level .. ")")
  end
end

function S.talentByName()
  if not D() then return end
  runTalentLevels(not MOCK.minimal) -- minimal API has no way to read talent names or icons
end

function S.talentByIcon()
  if not D() then return end
  runTalentLevels(not MOCK.minimal)
end

-- Turning the guide off hides it.
function S.talentGuideOff()
  if not D() then return end
  MOCK.level = 30
  openAt(30, "Settings")
  click(win(), "Trace my talent in the talent window")
  check(LevelingCodexDB.noTalentGuide, "check box turns the guide off")
  win():Hide()
  ToggleTalentFrame()
  MOCK.advance(0.8)
  local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
  check(not (trace and trace:IsShown()) and not (hint and hint:IsShown()), "guide hidden when turned off")
  ToggleTalentFrame()
  openAt(30, "Settings")
  click(win(), "Trace my talent in the talent window")
  check(not LevelingCodexDB.noTalentGuide, "check box turns the guide back on")
  win():Hide()
end

-- Levelling up in combat (the killing blow) must not create macros nobody asked for.
function S.combatLevelUp()
  if not D() then return end
  MOCK.macros = {}
  MOCK.level = 20
  MOCK.combat = true
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(1.5)
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.5)
  check(#MOCK.macros == 0, "combat level-up created " .. #MOCK.macros .. " macro(s) nobody asked for")
  -- but macros the Codex made are still brought up to date after the fight
  MOCK.level = 9
  slash("macros")
  local before = #MOCK.macros
  check(before > 0, "macros made at 9")
  MOCK.level = 10
  MOCK.combat = true
  MOCK.event("PLAYER_LEVEL_UP", 10)
  MOCK.advance(1.5)
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.5)
  check(#MOCK.macros == before, "no new macros after combat")
  for _, m in ipairs(D().macros) do
    if 10 >= m.lo and 10 <= m.hi then
      local i = GetMacroIndexByName(m.name)
      if i > 0 then check(MOCK.macros[i].body == m.body, m.name .. " updated after combat") end
    end
  end
  MOCK.advance(12)
end

-- SavedVariables didn't load: macros made last session must still follow your level,
-- and the player is told their settings didn't persist.
function S.lostSavedVariables()
  if not D() then return end
  -- this run started with no saved variables but with last session's macros (see run.py)
  local found
  for _, line in ipairs(MOCK.chat) do if line:find("didn't load") then found = true end end
  check(found, "chat note that settings didn't persist")
  openAt(MOCK.level, "Settings")
  check(MOCK.textUnder(win()):find("didn't load"), "settings tab shows the note")
  win():Hide()
  for level = MOCK.level + 1, 60 do
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level)
    MOCK.advance(1.5)
    for _, m in ipairs(D().macros) do
      if level >= m.lo and level <= m.hi then
        local i = GetMacroIndexByName(m.name)
        if i > 0 then check(MOCK.macros[i].body == m.body, m.name .. " follows level " .. level .. " without saved variables") end
      end
    end
    MOCK.advance(10)
  end
  check(MOCK.macros[1].body == "/say mine", "player's own macro untouched")
end

-- A clean install must not claim settings were lost.
function S.noFalseLostNote()
  for _, line in ipairs(MOCK.chat) do check(not line:find("didn't load"), "no lost-settings note on a fresh install") end
end

-- Once the talent is traced, the finder stops walking the window.
function S.talentFinderCost()
  if not D() or MOCK.minimal then return end
  MOCK.level = 30
  ToggleTalentFrame()
  MOCK.advance(1)
  traceCheck(30, true)
  local walked = MOCK.walked
  MOCK.advance(20)
  check(MOCK.walked - walked < 5, "finder kept walking the tree (" .. (MOCK.walked - walked) .. " walks in 20s)")
  -- talent not in the window (other tab): searches back off instead of walking every second
  local hit = planAt(30)
  local b = talent.byName[hit.name]
  b:Hide()
  walked = MOCK.walked
  MOCK.advance(30)
  local perSearch = 40 -- frames in the mock window
  local searches = (MOCK.walked - walked) / perSearch
  check(searches <= 10, "finder searched " .. searches .. " times in 30s while the talent was missing")
  b:Show()
  MOCK.advance(10)
  traceCheck(30, true)
  ToggleTalentFrame()
  MOCK.advance(0.5)
end

-- Reported in game: the trace stayed up after closing the talent window. Close it every way
-- (Esc/close button hide it directly, not through the toggle) and check nothing is left.
function S.talentCloseDirect()
  if not D() or MOCK.minimal then return end
  for _, level in ipairs({ 10, 16, 30, 60 }) do
    MOCK.level = level
    talent.root:Show()
    MOCK.advance(0.6)
    traceCheck(level, true)
    talent.root:Hide() -- no toggle, no time passing
    local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
    check(not trace:IsShown() and not hint:IsShown(), "guide hidden the moment the window closes (level " .. level .. ")")
    MOCK.advance(5)
    check(not trace:IsShown() and not hint:IsShown(), "guide stays hidden after closing (level " .. level .. ")")
  end
end

-- Talent buttons are pooled: when the traced button is reused for another talent, the trace follows.
function S.talentPooledButtons()
  if not D() or MOCK.minimal or talent.mode ~= "name" then return end
  MOCK.level = 30
  ToggleTalentFrame()
  MOCK.advance(1)
  traceCheck(30, true)
  local hit = planAt(30)
  local a = talent.byName[hit.name]
  -- swap the spells of the traced button and a decoy
  local decoy = MOCK.buttons(talent.root)[1]
  a.spellID, decoy.spellID = decoy.spellID, a.spellID
  talent.byName[hit.name] = decoy
  MOCK.advance(1)
  traceCheck(30, true)
  a.spellID, decoy.spellID = decoy.spellID, a.spellID
  talent.byName[hit.name] = a
  MOCK.advance(1)
  traceCheck(30, true)
  ToggleTalentFrame()
  MOCK.advance(0.5)
end

-- A talent UI that loads on demand after login, under a name we don't know, opened by its own
-- toggle function: the guide still finds it.
function S.lateTalentUI()
  if not D() or MOCK.minimal then return end
  local root = S.makeTalentWindow("name", "ForeverTalentsUI")
  function PlayerSpellsFrame_Toggle() if root:IsShown() then root:Hide() else root:Show() end end
  MOCK.event("ADDON_LOADED", "Blizzard_PlayerSpells")
  MOCK.advance(1)
  MOCK.level = 30
  PlayerSpellsFrame_Toggle()
  MOCK.advance(1)
  traceCheck(30, true)
  PlayerSpellsFrame_Toggle()
  MOCK.advance(1)
  local hint = _G.LevelingCodexTalentHint
  check(not (hint and hint:IsShown()), "hint hides when the late talent UI closes")
end

-- The guide only shows while there's a point to spend, and traces the next point in the plan.
function S.talentPoints()
  if not D() or not talent.root then return end
  local trace, hint
  local function guideShown()
    trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
    return (trace and trace:IsShown()) or (hint and hint:IsShown())
  end
  MOCK.level = 30
  MOCK.unspent = 0
  talent.root:Show()
  MOCK.advance(1)
  check(not guideShown(), "nothing shown with 0 points to spend")
  -- two points left at 30: the level-29 point comes first
  MOCK.unspent = 2
  MOCK.advance(0.5)
  check(hint and hint:IsShown(), "hint shown with 2 points to spend")
  check(hint.label:GetText():find("2 POINTS TO SPEND"), "hint says 2 points to spend")
  if not MOCK.minimal then
    local want = talent.byName[planAt(29).name]
    local _, on = trace:GetPoint(1)
    check(on == want or (talent.mode == "icon" and on.iconTex._tex == want.iconTex._tex), "traces the level-29 point first")
  end
  MOCK.unspent = 1
  MOCK.advance(0.5)
  traceCheck(30, not MOCK.minimal)
  -- the player clicks it: no points left, the guide goes away while the window stays open
  MOCK.unspent = 0
  MOCK.advance(0.5)
  check(not guideShown(), "guide hides once the point is spent")
  check(talent.root:IsShown(), "talent window still open")
  talent.root:Hide()
  MOCK.unspent = nil
  MOCK.advance(0.5)
end

-- The trace takes the talent button's shape (circle, square or choice node).
function S.talentShape()
  if not D() or not talent.root or MOCK.minimal then return end
  local seen = {}
  for level = 10, 60 do
    MOCK.level = level
    talent.root:Show()
    MOCK.advance(0.6)
    local trace = _G.LevelingCodexTalentTrace
    local _, b = trace:GetPoint(1)
    if b and b.expectShape then
      check(trace.shape == b.expectShape, "trace shape " .. tostring(trace.shape) .. ", button is " .. b.expectShape .. " (level " .. level .. ")")
      if talent.mode == "name" then
        check(trace.copied and trace.shapeLine._atlas == b.StateBorder._atlas, "trace copies the button's border art (level " .. level .. ")")
        local _, rel = trace.shapeLine:GetPoint(1)
        check(rel == b.StateBorder, "outline sits on the button's border (level " .. level .. ")")
      else
        check(not trace.copied, "no border art to copy in icon mode")
        check(trace.disc:IsShown() == (b.expectShape ~= "square"), "round glow for round nodes (level " .. level .. ")")
        check(trace.edges[1]:IsShown() == (b.expectShape == "square"), "box only for square nodes (level " .. level .. ")")
        if b.expectShape == "square" then
          -- Forever's square nodes have clipped corners: the outline cuts them too
          check(trace.cut and trace.cut > 0, "square outline has clipped corners (level " .. level .. ")")
          for i, k in ipairs(trace.corners) do
            check(k:IsShown() and k._rot and math.abs(math.abs(math.deg(k._rot)) - 45) < 0.01,
              "corner cut " .. i .. " drawn at 45 degrees (level " .. level .. ")")
          end
          local _, _, _, x = trace.edges[1]:GetPoint(1)
          check(x == -3 + trace.cut, "top side starts after the corner cut (level " .. level .. ")")
        else
          for _, k in ipairs(trace.corners) do check(not k:IsShown(), "no corner cuts on round nodes") end
        end
      end
      seen[b.expectShape] = true
    end
    talent.root:Hide()
    MOCK.advance(0.3)
  end
  check(seen.circle and seen.square, "both circle and square talents were traced")
end

-- /codex debug runs anywhere and reports the art and the talent guide.
----------------------------------------------------------------------------
-- Gathering tracking: Forever drops Find Herbs / Find Minerals; the Codex turns it back on.
----------------------------------------------------------------------------

local TRACK = {
  herbs = { name = "Find Herbs", texture = 133939, category = "spell", spellID = 2383 },
  minerals = { name = "Find Minerals", texture = 136025, category = "spell", spellID = 2580 },
  beasts = { name = "Track Beasts", texture = 132328, category = "spell", spellID = 1494 },
  flight = { name = "Flight Master", texture = 136456, category = "other", active = true },
}

local function trackEntry(name)
  for i, t in ipairs(MOCK.tracking) do if t.name == name then return t, i end end
end

local function trackOn(name)
  local t = trackEntry(name)
  return t and t.active
end

local function gatherOn()
  return trackOn("Find Herbs") or trackOn("Find Minerals")
end

-- what the client does at a loading screen: gathering tracking is gone
local function dropTracking()
  for _, t in ipairs(MOCK.tracking) do if t.category == "spell" then t.active = false end end
end

local function hasTrackingAPI() return C_Minimap ~= nil end

-- Before login: which trackers the character knows ("herbs,minerals", "multi" = both can be on at once).
function S.trackKnown(which)
  MOCK.tracking = { { name = TRACK.flight.name, texture = TRACK.flight.texture, category = "other", active = true } }
  for key in tostring(which or ""):gmatch("[^,]+") do
    if key == "multi" then MOCK.multiTrack = true
    elseif key == "herbsOn" then
      local t = TRACK.herbs
      MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = true }
    elseif TRACK[key] then
      local t = TRACK[key]
      MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = false }
    end
  end
end

-- After login the Codex turns gathering tracking back on (once the client is ready).
function S.trackRestored()
  MOCK.advance(7)
  if not hasTrackingAPI() then
    check(#MOCK.trackCalls == 0, "no tracking calls without the API")
    check(chatHas("is off"), "a client without the tracking API gets a reminder instead")
    return
  end
  check(gatherOn(), "gathering tracking back on after login")
  check(trackOn("Flight Master"), "town tracking left alone")
  if MOCK.multiTrack then
    check(trackOn("Find Herbs") and trackOn("Find Minerals"), "both trackers on when the client allows both")
  end
  check(chatHas("back on"), "says it turned tracking back on")
  for _, c in ipairs(MOCK.trackCalls) do check(c.name ~= "Flight Master", "never touches town tracking") end
end

-- A loading screen drops it again: the one the player picked last comes back.
function S.trackLoadingScreen()
  if not hasTrackingAPI() then return end
  local _, herbs = trackEntry("Find Herbs")
  local _, minerals = trackEntry("Find Minerals")
  local pick = minerals and "Find Minerals" or "Find Herbs"
  local idx = minerals or herbs
  if herbs and minerals then
    -- the player switches to the other one by hand
    pick = trackOn("Find Herbs") and "Find Minerals" or "Find Herbs"
    idx = pick == "Find Herbs" and herbs or minerals
  end
  C_Minimap.SetTracking(idx, true)
  MOCK.advance(1)
  local chatLines
  for _ = 1, 3 do
    dropTracking()
    MOCK.event("PLAYER_ENTERING_WORLD", false, false)
    MOCK.advance(7)
    check(trackOn(pick), pick .. " (the player's pick) back on after a loading screen")
    chatLines = chatLines or #MOCK.chat
  end
  check(#MOCK.chat == chatLines, "only says so once a session")
end

-- Dead or a ghost: wait. Alive again: back on.
function S.trackDeath()
  if not hasTrackingAPI() then return end
  MOCK.dead = true
  dropTracking()
  MOCK.event("PLAYER_ALIVE")
  MOCK.advance(7)
  check(not gatherOn(), "nothing turned on while a ghost")
  MOCK.dead = false
  MOCK.event("PLAYER_UNGHOST")
  MOCK.advance(7)
  check(gatherOn(), "back on after resurrecting")
end

-- In combat: wait for the fight to end (the mock flags tracking changes in combat).
function S.trackCombat()
  if not hasTrackingAPI() then return end
  dropTracking()
  MOCK.combat = true
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  MOCK.advance(7)
  check(not gatherOn(), "waits for combat to end")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(3)
  check(gatherOn(), "back on after combat")
end

-- Another tracking (Track Beasts) is the player's choice: leave it.
function S.trackOtherChoice()
  if not hasTrackingAPI() then return end
  local _, i = trackEntry("Track Beasts")
  if not i then
    local t = TRACK.beasts
    MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = false }
    i = #MOCK.tracking
  end
  dropTracking()
  MOCK.tracking[i].active = true
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  MOCK.advance(7)
  check(trackOn("Track Beasts"), "Track Beasts left on")
  check(not gatherOn(), "gathering not forced over another tracking")
  MOCK.tracking[i].active = false
end

-- The setting turns it off; turning it back on restores right away.
function S.trackSettingOff()
  dropTracking()
  local calls = #MOCK.trackCalls
  if D() then
    openAt(30, "Settings")
    click(win(), "Keep Find Herbs / Find Minerals on")
    win():Hide()
  else
    LevelingCodexDB.noAutoTrack = true
  end
  check(LevelingCodexDB.noAutoTrack, "check box turns tracking restore off")
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  MOCK.advance(7)
  check(#MOCK.trackCalls == calls, "no tracking calls while turned off")
  if D() then
    openAt(30, "Settings")
    click(win(), "Keep Find Herbs / Find Minerals on")
    win():Hide()
    check(not LevelingCodexDB.noAutoTrack, "check box turns it back on")
    MOCK.advance(1)
    if hasTrackingAPI() then check(gatherOn(), "turning the setting on restores tracking") end
  else
    LevelingCodexDB.noAutoTrack = nil
  end
end

-- Logging in with tracking that looks on: it is toggled off and on so the minimap draws it.
function S.trackKick()
  if not hasTrackingAPI() then return end
  MOCK.advance(7)
  local seenOff, seenOn
  for _, c in ipairs(MOCK.trackCalls) do
    if c.name == "Find Herbs" then
      if not c.on then seenOff = true elseif seenOff then seenOn = true end
    end
  end
  check(seenOff and seenOn, "tracking that looked on at login was toggled off and back on")
  check(trackOn("Find Herbs"), "and is on")
end

-- Learning Herbalism later: Find Herbs goes on.
function S.trackLearn()
  if not hasTrackingAPI() then return end
  check(not gatherOn(), "nothing to track yet")
  local t = TRACK.herbs
  MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = false }
  MOCK.event("LEARNED_SPELL_IN_TAB", t.spellID, 1)
  MOCK.event("SPELLS_CHANGED")
  MOCK.advance(7)
  check(trackOn("Find Herbs"), "Find Herbs on after learning Herbalism")
end

function S.trackDebug()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("gathering tracking:"), "debug reports gathering tracking")
end

function S.debugReport()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("art files:"), "debug lists the art files")
  check(chatHas("unspent points:"), "debug shows the talent points")
  if talent.root then
    talent.root:Show(); MOCK.advance(0.6)
    MOCK.chat = {}
    slash("debug")
    check(chatHas("talent window:"), "debug names the talent window")
    talent.root:Hide(); MOCK.advance(0.3)
  end
end

-- Blizzard art is used when the client has it, and its absence never breaks anything.
function S.artUsed()
  if not D() then return end
  slash("")
  local f = win()
  local expectArt = not MOCK.minimal and not MOCK.noArt
  check((f._backdrop ~= nil) == expectArt, "dialog border " .. (expectArt and "used" or "skipped"))
  win():Hide()
end

-- Icon buttons under the window with a given tooltip title.
local function iconsTitled(title)
  local out = {}
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle == title or (b.tipTitle and b.tipTitle:find("^" .. title:gsub("%p", "%%%0") .. "  %d")) then out[#out + 1] = b end
  end
  return out
end

-- Talents tab: a tree node per talent, filled in to the level shown, and a click shows every point.
function S.talentTree()
  if not D() then return end
  openAt(16, "Talents")
  local seen = {}
  for _, p in ipairs(D().plan) do
    if not seen[p.name] then
      seen[p.name] = true
      local nodes = iconsTitled(p.name)
      check(#nodes >= 1, "tree node for " .. p.name)
      local node = nodes[1]
      -- rank at 16
      local r = 0
      for _, q in ipairs(D().plan) do
        if q.name == p.name then
          for l = q.from, math.min(q.to, 16) do if l >= q.from then r = r + 1 end end
        end
      end
      check(node.tipTitle == p.name .. "  " .. r .. "/" .. p.max, p.name .. " shows " .. r .. "/" .. p.max .. " at 16, got " .. tostring(node.tipTitle))
      check((r == 0) == (node.tex._desat == true), p.name .. " greyed out only when no points yet")
    end
  end
  -- click a future talent: its points and reasons appear
  local future
  for _, p in ipairs(D().plan) do if p.from > 40 then future = p; break end end
  if future then
    iconsTitled(future.name)[1]:Click()
    local text = MOCK.textUnder(win())
    check(text:find("Level " .. future.from, 1, true), "detail lists level " .. future.from .. " for " .. future.name)
    local snippet = future.why:match("^[A-Za-z0-9 ,%.']+") or "" -- not %w: it takes UTF-8 bytes on Windows
    if #snippet > 8 then check(text:find(snippet, 1, true), "detail shows why " .. future.name) end
  end
  win():Hide()
end

-- With the game's tree layout available, nodes sit where the talent window puts them.
function S.traitLayoutTree()
  if not D() or MOCK.minimal then return end
  local names, id = {}, 700
  for _, p in ipairs(D().plan) do
    if not names[p.name] then
      id = id + 1
      names[p.name] = id
      MOCK.spells[50000 + id] = p.name
      -- reverse order: the first talent in the plan sits furthest right
      MOCK.traitNodes[id] = { posX = 10000 - id * 100, posY = 0, spellID = 50000 + id }
    end
  end
  openAt(30, "Talents")
  local prevX = {} -- per tree: each tree is its own grid
  for _, p in ipairs(D().plan) do
    if names[p.name] then
      local node = iconsTitled(p.name)[1]
      local _, _, _, x = node:GetPoint(1)
      if prevX[p.tree] then check(x < prevX[p.tree], p.name .. " sits left of the talent before it (game layout)") end
      prevX[p.tree] = x
      names[p.name] = nil
    end
  end
  check(not MOCK.textUnder(win()):find("Open your talent window once", 1, true), "no layout note once the game's layout is known")
  win():Hide()
end

-- Macros tab: each macro on its controller button and its key, drawn as glyphs and keycaps.
function S.macroMockups()
  if not D() then return end
  for _, pad in ipairs({ "PlayStation", "Xbox", "Switch" }) do
    openAt(30, "Settings")
    click(win(), pad)
    click(win(), "Macros")
    for _, m in ipairs(D().macros) do
      if 30 >= m.lo and 30 <= m.hi then
        local n = #iconsTitled(m.name)
        local want = 1 + (m.pad ~= "" and 1 or 0) + (m.kb ~= "" and 1 or 0)
        check(n >= want, m.name .. " appears on the controller, the key bar and its card (" .. n .. "/" .. want .. ")")
      end
    end
    local text = MOCK.textUnder(win())
    check(text:find("ON YOUR CONTROLLER", 1, true) and text:find("ON YOUR KEYBOARD", 1, true), "both mock-ups drawn")
    if pad == "PlayStation" and not MOCK.minimal then
      -- shapes are drawn with turned strokes, not as text
      local turned = 0
      local function walk(f)
        for _, r in ipairs(f._regions) do if r._shown and r._rot and r._rot ~= 0 then turned = turned + 1 end end
        for _, c in ipairs(f._children) do if c._shown then walk(c) end end
      end
      walk(win())
      check(turned > 0, "PlayStation shapes drawn")
    end
  end
  openAt(30, "Settings"); click(win(), "Xbox")
  win():Hide()
end

-- The banner never sits on top of the game's own level-up display.
function S.bannerBuiltIn()
  if not D() then return end
  LevelingCodexDB.toastPos = nil
  if MOCK.ns.builtInSpotY == nil then
    -- game display never seen: the usual level-up spot near the top
    MOCK.ns.showToast(25, true, true)
    local _, _, _, _, dy = toast():GetPoint(1)
    check(dy == -190, "banner defaults to the game's usual level-up spot (y " .. tostring(dy) .. ")")
    toast():Hide()
  end
  local builtin = _G.EventToastManagerFrame or CreateFrame("Frame", "EventToastManagerFrame", UIParent)
  builtin._top = 1080 - 180 -- the game's display: its top 180 below the top of the screen
  builtin:Show()
  MOCK.level = 25
  MOCK.event("PLAYER_LEVEL_UP", 25)
  MOCK.advance(3)
  check(not (toast() and toast():IsShown()), "banner waits while the game's level-up display is up")
  builtin:Hide()
  MOCK.advance(1)
  check(toast():IsShown(), "banner shows once the game's display is gone")
  local _, _, _, x, y = toast():GetPoint(1)
  check(y == -180, "banner takes the game's display's spot (y " .. tostring(y) .. ")")
  -- a bigger banner still starts at that spot (offsets are in its scaled units)
  LevelingCodexDB.toastScale = 1.5
  MOCK.ns.placeToast()
  _, _, _, x, y = toast():GetPoint(1)
  check(y == -120, "scaled banner starts at the same spot (y " .. tostring(y) .. ")")
  LevelingCodexDB.toastScale = 1
  -- where you dragged it wins
  LevelingCodexDB.toastPos = { "TOP", "TOP", 40, -400 }
  MOCK.ns.placeToast()
  _, _, _, x, y = toast():GetPoint(1)
  check(x == 40 and y == -400, "a banner you moved stays where you put it")
  LevelingCodexDB.toastPos = nil
  MOCK.ns.placeToast()
  -- a game display that never goes away doesn't swallow the banner
  MOCK.advance(12)
  builtin:Show()
  MOCK.event("PLAYER_LEVEL_UP", 26)
  MOCK.advance(10)
  check(toast():IsShown(), "banner shows after 8 s even if the game's display stays up")
  builtin:Hide()
  MOCK.advance(12)
end

-- A level-up display under a name we don't know is found and waited for, then remembered.
function S.bannerFindsDisplay()
  if not D() or MOCK.minimal then return end
  local f = _G.ForeverLevelUpBanner or CreateFrame("Frame", "ForeverLevelUpBanner", UIParent)
  f:Show()
  MOCK.level = 33
  MOCK.event("PLAYER_LEVEL_UP", 33)
  MOCK.advance(5)
  check(not toast():IsShown(), "banner waits for the game's display it found")
  check(MOCK.ns.builtInLevelUp == "ForeverLevelUpBanner", "remembers the game's display (" .. tostring(MOCK.ns.builtInLevelUp) .. ")")
  f:Hide()
  MOCK.advance(1)
  check(toast():IsShown() and toast().title:GetText() == "New at Level 33", "unlocks shown right after it")
  MOCK.advance(12)
end

-- Keycaps have a light face (dark legends on a dark cap were unreadable in game).
function S.keycapsLight()
  if not D() then return end
  openAt(30, "This Level")
  local light = 0
  local function walk(f)
    for _, r in ipairs(f._regions) do
      local c = r._shown and r._tex == "color" and r._color
      if c and c[1] > 0.8 and c[2] > 0.8 and c[3] > 0.7 and r._w > 18 then light = light + 1 end
    end
    for _, c in ipairs(f._children) do if c._shown then walk(c) end end
  end
  walk(win())
  local keyed = 0
  for _, m in ipairs(D().macros) do if 30 >= m.lo and 30 <= m.hi and m.kb ~= "" then keyed = keyed + 1 end end
  check(light >= keyed, "a light keycap face per key (" .. light .. " for " .. keyed .. " keys)")
  win():Hide()
end

-- The card above the talent window stays on screen: a window near the top gets it underneath.
function S.talentHintOnScreen()
  if not D() or not talent.root then return end
  MOCK.level = 30
  for _, case in ipairs({ { 600, 150, "above" }, { 1075, 200, "below" }, { 1075, 30, "inside" } }) do
    talent.root._top, talent.root._bottom = case[1], case[2]
    talent.root:Show()
    MOCK.advance(0.6)
    local hint = _G.LevelingCodexTalentHint
    check(hint:IsShown() and hint.where == case[3], "card goes " .. case[3] .. " (got " .. tostring(hint.where) .. ")")
    local p, rel, rp = hint:GetPoint(1)
    check(rel == talent.root, "card still anchored to the talent window")
    talent.root:Hide()
    MOCK.advance(0.3)
  end
  -- a bar hanging under the window (Forever's controller hints): the card goes below the bar
  if EnumerateFrames then
    local bar = CreateFrame("Frame", nil, UIParent); bar:SetSize(600, 62)
    bar._top, bar._bottom = 202, 140
    talent.root._top, talent.root._bottom = 1075, 200
    talent.root:Show()
    MOCK.advance(0.6)
    local hint = _G.LevelingCodexTalentHint
    local _, rel, _, _, y = hint:GetPoint(1)
    check(hint.where == "below" and rel == talent.root and y and y <= -66,
      "talent card below the bar (" .. tostring(hint.where) .. ", offset " .. tostring(y) .. ")")
    talent.root:Hide()
    bar:Hide()
    MOCK.advance(0.3)
  end
  talent.root._top, talent.root._bottom = nil, nil
end

-- The trace takes the theme's colour, not the node's own green or yellow.
function S.talentTraceThemed()
  if not D() or not talent.root or MOCK.minimal or talent.mode ~= "name" then return end
  MOCK.level = 30
  talent.root:Show()
  MOCK.advance(0.6)
  local t = _G.LevelingCodexTalentTrace
  check(t.copied and t.shapeLine._desat and t.shapeGlow._desat, "copied border art is greyed out before the theme tint")
  talent.root:Hide()
  MOCK.advance(0.3)
end

-- Controller panels follow the controller: L2 set on the left, R2 set on the right.
function S.controllerSides()
  if not D() then return end
  for level = 1, 60 do
    MOCK.level = level
    openAt(level, "Macros")
    local g = MOCK.ns.controllerLayout
    if g and g.L and g.R then
      check(g.L.px < g.R.px, "L2 set left of R2 set at level " .. level)
    end
    if g and g["L+R"] and (g.L or g.R) then
      local side = g.L or g.R
      check(g["L+R"].px > 14, "L2 + R2 set centred under the sides at level " .. level)
    end
  end
  win():Hide()
end

-- Tabs: the hover glow never lights the selected tab.
function S.tabGlow()
  if not D() then return end
  openAt(20, "Tips")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.glow then
      local selected = labelOf(b) == "Tips"
      check(b.glow:IsShown() == not selected, "hover glow " .. (selected and "off" or "on") .. " for " .. labelOf(b))
    end
  end
  win():Hide()
end

-- The talent window is already open when we log in.
function S.talentBeforeLogin()
  if not (D() and talent.root) then return end
  MOCK.level = 30
  talent.root:Show()
  MOCK.event("ADDON_LOADED", "Blizzard_PlayerSpells")
end
function S.talentBeforeLoginCheck()
  if not D() then return end
  MOCK.advance(1)
  traceCheck(30, not MOCK.minimal)
  ToggleTalentFrame()
  MOCK.advance(0.5)
end

----------------------------------------------------------------------------
-- Professions (ProfessionData.lua): skills, the Professions tab, skill-up cards, the crafting window
----------------------------------------------------------------------------

-- skills:BS;97;150,MI;140;225:professions[:Horde[:Skyborne]]  (the step parser splits on ":")
-- api "skilllines": the client only has the classic skill list (no GetProfessions).
function S.skills(list, api, faction, race)
  MOCK.skillAPI = api or "professions"
  if MOCK.skillAPI ~= "professions" then GetProfessions, GetProfessionInfo = nil, nil end
  MOCK.faction, MOCK.race = faction, race
  local names = { BS = "Blacksmithing", MI = "Mining", HE = "Herbalism", TA = "Tailoring", EN = "Enchanting" }
  for part in (list or ""):gmatch("[^,]+") do
    local k, r, m = part:match("(%a+);(%d+);(%d+)")
    MOCK.setSkill(names[k], tonumber(r), tonumber(m))
  end
end

-- /codex debug reports each profession's skill and step.
function S.profDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing 97/150, step 95%-100 Rough Bronze Leggings, about 3 more"), "BS step in debug")
  check(chatHas("profession: Mining 140/225, step 125%-175"), "Mining step in debug")
  local via = (GetProfessions and "professions") or "skill lines"
  check(chatHas("profession skills read from: " .. via), "skills read from " .. via)
end

function S.profNone()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing not learned") and chatHas("profession: Mining not learned"), "no professions")
  check(chatHas("profession: Tailoring not learned"), "Tailoring not learned in debug")
  check(chatHas("profession: Enchanting not learned"), "Enchanting not learned in debug")
end

local function profText() return MOCK.textUnder(win()) end

-- Without GetProfessions the classic skill list hides lines under a closed heading: the guide
-- keeps the skill it saw last, and the card still comes when the heading opens again.
function S.profCollapsed()
  if not D() then return end
  MOCK.skillsCollapsed = true
  MOCK.event("SKILL_LINES_CHANGED"); MOCK.advance(1.2)
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("Blacksmithing 97 / 150"), "closed heading: still the skill seen before")
  win():Hide()
  MOCK.setSkill("Blacksmithing", 100, 150); MOCK.advance(1.2) -- a skill-up the list doesn't show
  MOCK.skillsCollapsed = false
  MOCK.event("SKILL_LINES_CHANGED"); MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Blacksmithing 100", "card when the heading opens again")
end

-- A closed heading from the start (nothing seen yet this session): say so, not "not learned".
function S.skillsClosed() MOCK.skillsCollapsed = true end
function S.profCollapsedCold()
  if not D() then return end
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("skill not seen") and profText():find("heading in your skill list is closed")
    and not profText():find("not learned"), "tab: heading closed")
  win():Hide()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing not seen"), "debug: not seen")
  MOCK.skillsCollapsed = false
  MOCK.event("SKILL_LINES_CHANGED"); MOCK.advance(1.2)
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("Blacksmithing 97 / 150"), "heading opened: skill read")
  win():Hide()
end

-- The Professions tab at Blacksmithing 97/150 and Mining 140/225 (set by the skills step).
function S.profTab()
  if not D() then return end
  openAt(30, "Professions")
  click(win(), "Blacksmithing")
  local t = profText()
  check(t:find("Blacksmithing 97 / 150"), "skill header")
  check(t:find("Rough Bronze Leggings") and t:find("about 3 more to 100"), "now card")
  check(t:find("Learn at 95"), "learn level")
  check(t:find("SHOPPING LIST TO 300"), "shopping list")
  check(t:find("1882 Thorium Bar"), "shopping list counts the 140 Thorium Bars the Imperial Plate quests take")
  check(t:find("24 Heavy Grinding Stone"), "shopping list counts only the stones the route doesn't make itself")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^100%-112") then b:Click(); break end
  end
  check(profText():find("STEP 100%-112") and profText():find("make 24 more"), "clicked step shows; the note says how many more stones")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^95%-100") then b:Click(); break end
  end
  check(profText():find("DO THIS NOW") and profText():find("about 3 more to 100"), "clicking your own step goes back to it")
  check(t:find("THE WHOLE ROUTE"), "route list")
  check(t:find("TRAIN EXPERT") == nil, "Expert not due at 97")
  click(win(), "Mining")
  t = profText()
  check(t:find("Mining 140 / 225") and t:find("Iron Deposit") and t:find("Arathi Highlands"), "mining header, vein, zones")
  MOCK.staleUnder(win(), "Professions")
  win():Hide()
end

-- Tier card, route done, not learned, faction and Skyborne zones.
function S.profTabCases()
  if not D() then return end
  MOCK.setSkill("Blacksmithing", 150, 150)
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("TRAIN EXPERT") and profText():find("Bengus Deepforge"), "Expert due at 150, level 30")
  MOCK.level = 15
  click(win(), "Blacksmithing")
  check(profText():find("AT YOUR CAP"), "stuck at the cap at level 15")
  MOCK.level = 30
  MOCK.setSkill("Blacksmithing", 300, 300)
  click(win(), "Blacksmithing")
  check(profText():find("ROUTE DONE"), "route done at 300")
  MOCK.skills = {}
  click(win(), "Blacksmithing")
  check(profText():find("Blacksmithing: not learned"), "not learned")
  MOCK.setSkill("Mining", 30, 75)
  MOCK.faction, MOCK.race = "Alliance", "Human"
  click(win(), "Mining")
  check(profText():find("Elwynn Forest") and not profText():find("Durotar"), "Alliance copper zones only")
  MOCK.faction, MOCK.race = "Horde", "Orc"
  click(win(), "Mining")
  check(profText():find("Durotar") and not profText():find("Elwynn Forest"), "Horde copper zones only")
  MOCK.race = "Skyborne"
  click(win(), "Mining")
  check(profText():find("Zephras Isle"), "Skyborne starting isle for Copper")
  MOCK.faction, MOCK.race = nil, nil
  win():Hide()
end

-- A theme switch rebuilds the window: the Professions tab is still there.
function S.profTabAfterTheme()
  if not D() then return end
  openAt(30, "Settings"); click(win(), "Codex (gold)")
  click(win(), "Professions")
  check(profText():find("Blacksmithing") or profText():find("Mining"), "Professions tab survives a theme rebuild")
  click(win(), "Settings"); click(win(), "Forever (teal)")
  win():Hide()
end

-- Skill-up cards: only when a step starts, a tier is due or a vein opens; one card for a jump.
-- (1.2 s waits: the minimal client has no skill events, so its cards come from a 1 s poll.)
function S.profSkillUps()
  if not D() then return end
  local function dismiss(t) MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
  MOCK.setSkill("Blacksmithing", 94, 150)       -- first reading this session: no card
  MOCK.advance(1.2)
  check(not (toast() and toast():IsShown()), "no card for the first reading")
  MOCK.setSkill("Blacksmithing", 95, 150)       -- step boundary at 95
  MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Blacksmithing 95", "card at a new step")
  check(t.sub:GetText() == "Journeyman Blacksmithing", "card subtitle: your tier (" .. tostring(t.sub:GetText()) .. ")")
  check(MOCK.textUnder(t):find("Rough Bronze Leggings"), "card names the next recipe")
  dismiss(t)
  MOCK.setSkill("Blacksmithing", 96, 150)       -- an ordinary point
  MOCK.advance(1.2)
  check(not t:IsShown(), "no card for an ordinary point")
  MOCK.setSkill("Blacksmithing", 112, 150)      -- jumps over 100 and 112: one card, both steps
  MOCK.advance(1.2)
  local text = MOCK.textUnder(t)
  check(t:IsShown() and text:find("Heavy Grinding Stone") and text:find("Rough Bronze Leggings"), "one card for two boundaries")
  dismiss(t)
  MOCK.level = 30
  MOCK.setSkill("Blacksmithing", 125, 150)      -- Expert can be trained now
  MOCK.advance(1.2)
  check(t:IsShown() and MOCK.textUnder(t):find("TRAIN EXPERT"), "Expert card at 125")
  for _, row in ipairs(t.rows or {}) do
    local v = row:IsShown() and row.value and row.value:GetText()
    check(not v or #v <= 60, "banner row fits on its line: " .. tostring(v))
  end
  MOCK.fire(t, "OnMouseUp", "LeftButton"); MOCK.advance(1.5)
  check(win() and win():IsShown() and MOCK.textUnder(win()):find("Blacksmithing 125"), "click opens the Professions tab")
  win():Hide()
  MOCK.setSkill("Mining", 64, 75)               -- first Mining reading
  MOCK.advance(1.2)
  MOCK.setSkill("Mining", 65, 75)
  MOCK.advance(1.2)
  check(t:IsShown() and MOCK.textUnder(t):find("Tin Vein"), "new vein card")
  dismiss(t)
  MOCK.setSkill("Herbalism", 1, 75); MOCK.advance(1.2)
  MOCK.setSkill("Herbalism", 50, 75); MOCK.advance(1.2)
  check(not t:IsShown(), "no card for a profession the guide doesn't cover")
  LevelingCodexDB.noProfCards = true
  MOCK.setSkill("Blacksmithing", 140, 150); MOCK.advance(1.2)
  check(not t:IsShown(), "cards off in Settings")
  LevelingCodexDB.noProfCards = nil
end

-- Skill 65 reached at level 9 (Journeyman needs level 10): the level-up to 10 brings the
-- training row, once. Runs after profSkillUps (Mining 65/75).
function S.profLevelTier()
  if not D() then return end
  local function levelUp(level)
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level, 10, 0, 0, 0, 0, 0)
    MOCK.advance(4.5)
    local t = toast()
    return t and t:IsShown() and MOCK.textUnder(t) or ""
  end
  MOCK.level = 9
  MOCK.setSkill("Mining", 65, 75); MOCK.advance(1.2)
  MOCK.chat = {}
  local text = levelUp(10)
  check(text:find("TRAIN JOURNEYMAN MINING"), "level-up banner: train Journeyman Mining")
  check(chatHas("Mining: train .-Journeyman"), "level-up chat: train Journeyman")
  check(not text:find("BLACKSMITHING"), "no row for Blacksmithing (Expert needs level 20)")
  MOCK.advance(10)
  check(not levelUp(11):find("TRAIN JOURNEYMAN"), "only at the level that unlocks it")
  MOCK.advance(10)
end

-- Opening the Codex within a minute of a banner opens what it was about.
function S.bannerOpensTarget()
  if not D() then return end
  openAt(30, "Settings"); win():Hide()          -- last tab: Settings
  MOCK.setSkill("Blacksmithing", 94, 150); MOCK.advance(1.2)
  MOCK.setSkill("Blacksmithing", 95, 150); MOCK.advance(1.2)   -- skill-up card
  slash("")
  check(MOCK.textUnder(win()):find("Blacksmithing 95 / 150"), "opens on the profession the card was about")
  win():Hide()
  slash("")
  check(MOCK.textUnder(win()):find("Blacksmithing 95 / 150"), "used once: reopening keeps the tab you were on")
  click(win(), "Settings"); win():Hide()
  MOCK.setSkill("Blacksmithing", 100, 150); MOCK.advance(1.2)
  MOCK.advance(61)
  slash("")
  check(MOCK.textUnder(win()):find("Minimap button"), "after a minute it opens as usual")
  win():Hide()
end

----------------------------------------------------------------------------
-- Crafting window mock: TradeSkillFrame with 8 visible rows TradeSkillSkill1..8 showing the
-- recipes from `offset`. Row text carries a count and orange ones a colour code, like the game.
-- style "retail": no classic calls, only C_TradeSkillUI.
----------------------------------------------------------------------------

local RELATIVE = { optimal = 0, medium = 1, easy = 2, trivial = 3 }

-- Tailoring: the shopping list in raw cloth (bolts become their cloth), the cloth section.

-- How far down the window (draw y) the first shown text matching pat sits; the text dump follows
-- the widget pools, not the screen, so order on screen is read from the anchors.
local function textY(root, pat)
  local found
  local function walk(f)
    for _, r in ipairs(f._regions) do
      if not found and r._shown and r._text and r._text:find(pat) and r._points[1] then found = -r._points[1][5] end
    end
    for _, c in ipairs(f._children) do if c._shown and not found then walk(c) end end
  end
  walk(root)
  return found
end

-- The shopping list's text only (between its title and the cloth section).
local function shoppingText()
  local t = profText()
  local a = t:find("SHOPPING LIST TO 300", 1, true)
  local b = t:find("\nCLOTH\n", a or 1, true)
  return a and t:sub(a, b or #t) or ""
end

local function tailoring() click(win(), "Tailoring"); return profText() end

-- Two shopping-list texts in the same column whose lines overlap (a row that wraps into the next).
local function shoppingOverlap()
  local top, bottom = textY(win(), "^SHOPPING LIST TO 300$"), textY(win(), "^CLOTH$")
  local items = {}
  local function walk(f)
    for _, r in ipairs(f._regions) do
      if r._shown and r._text and r._points[1] and top and bottom then
        local y = -r._points[1][5]
        if y > top and y < bottom then items[#items + 1] = { x = r._points[1][4], y = y, h = r:GetStringHeight(), t = r._text } end
      end
    end
    for _, c in ipairs(f._children) do if c._shown then walk(c) end end
  end
  walk(win())
  for i, a in ipairs(items) do
    for j, b in ipairs(items) do
      if i < j and a.x == b.x and a.y < b.y + b.h and b.y < a.y + a.h then return a.t .. " | " .. b.t end
    end
  end
end

function S.tailorTab()
  if not D() then return end
  openAt(30, "Professions")
  local t = tailoring()
  check(t:find("Tailoring 150 / 225"), "Tailoring header")
  check(t:find("Earthen Vest"), "step at 150: Earthen Vest")
  check(t:find("SHOPPING LIST TO 300") and t:find("\nCLOTH\n"), "shopping list and cloth section")
  local shop = shoppingText()
  check(not shop:find("%d+ Bolt of"), "no bolt rows in the shopping list: they're counted as cloth")
  local cloth, bolts = shop:match("(%d+) Runecloth %(for (%d+) bolts")
  check(cloth and tonumber(cloth) == 5 * tonumber(bolts), "Runecloth row: 5 per bolt (" .. tostring(cloth) .. ", " .. tostring(bolts) .. ")")
  check(t:find("make them from Silk Cloth %(4 each%)"), "step card: bolts are made from Silk Cloth")
  local now, linen = textY(win(), "^Silk Cloth  %-  you need this now"), textY(win(), "^Linen Cloth$")
  check(now and linen and now < linen, "this step's cloth (Silk) first, marked")
  check(t:find("Humanoids level 27%-39"), "silk mob levels")
  if GetItemCount then
    MOCK.bags["Mageweave Cloth"] = 20
    check(tailoring():find("Mageweave Cloth %(for %d+ bolts, you have 20%)"), "have: cloth in bags")
    MOCK.bags["Bolt of Mageweave"] = 10
    check(tailoring():find("Mageweave Cloth %(for %d+ bolts, you have 70%)"), "have: held bolts count as 5 cloth each")
    MOCK.bags["Mageweave Cloth"], MOCK.bags["Bolt of Mageweave"] = nil, nil
    local over = shoppingOverlap()
    check(not over, "shopping rows don't overlap: " .. tostring(over))
    MOCK.bags["Bolt of Silk Cloth"] = 12
    local held = tailoring()
    check(held:find("make them from Silk Cloth %(4 each%): your 0 make 0") and not held:find("your 48"),
      "step card: held bolts aren't cloth that makes more bolts")
    MOCK.bags["Bolt of Silk Cloth"] = nil
  else
    check(not t:find("you have"), "no bag counts without GetItemCount")
  end
  local function has(l) return findButton(win(), function(x) return x == l end) end
  check(has("Blacksmithing") and has("Mining") and has("Tailoring"), "three profession buttons")
  win():Hide()
  openAt(30, "Professions")
  check(profText():find("Tailoring 150 / 225"), "the picked profession stays after reopening")
  MOCK.staleUnder(win(), "Professions")
  click(win(), "Settings")
  local cards = findButton(win(), function(l) return l == "Profession skill-up cards" end)
  check(cards and cards.tipText and cards.tipText:find("Tailoring"), "Settings: skill-up cards name Tailoring")
  win():Hide()
end

-- Faction zones, more bolts than needed, the end of the route.
function S.tailorTabCases()
  if not D() then return end
  openAt(30, "Professions")
  local t = tailoring()
  check(t:find("Westfall") and not t:find("Durotar"), "Alliance cloth zones")
  MOCK.faction = "Horde"
  t = tailoring()
  check(t:find("Durotar") and not t:find("Westfall"), "Horde cloth zones")
  MOCK.race = "Skyborne"
  t = tailoring()
  check(t:find("Durotar") and not t:find("Zephras Isle"), "Skyborne: their faction's zones")
  MOCK.faction, MOCK.race = nil, nil
  local _, before = shoppingText():match("(%d+) Runecloth %(for (%d+) bolts")
  MOCK.bags["Bolt of Runecloth"] = 999
  tailoring()
  local shop = shoppingText()
  check(not shop:find("%-%d"), "no negative counts with 999 bolts held")
  local _, after = shop:match("(%d+) Runecloth %(for (%d+) bolts")
  check(before and after == before, "held bolts don't change the need")
  MOCK.bags["Bolt of Runecloth"] = nil
  MOCK.setSkill("Tailoring", 50, 75)
  t = tailoring()
  check(t:find("TRAIN JOURNEYMAN") and t:find("Taleen Shimmerthread") and not t:find("Zephras Isle tailors: Sellandus"),
    "Journeyman card names the Zephras Isle trainers")
  MOCK.setSkill("Tailoring", 260, 300)
  t = tailoring()
  check(t:find("Runecloth Cuffs") and t:find("Pexmit"), "step at 260: Runecloth Cuffs from Pexmit")
  check(t:find("Runecloth  %-  you need this now"), "Runecloth marked at 260")
  MOCK.setSkill("Tailoring", 300, 300)
  t = tailoring()
  check(t:find("ROUTE DONE") and not t:find("you need this now"), "route done at 300")
  MOCK.setSkill("Tailoring", 150, 225)
  win():Hide()
end

-- Only Tailoring learned: the tab opens on it.
function S.tailorOnly()
  if not D() then return end
  openAt(30, "Professions")
  local t = profText()
  check(t:find("Tailoring 20 / 75") and t:find("Bolt of Linen Cloth"), "opens on Tailoring without a click")
  check(t:find("Linen Cloth  %-  you need this now"), "Linen Cloth first for the bolt step")
  win():Hide()
end

function S.tailorNone()
  if not D() then return end
  openAt(30, "Professions")
  local t = tailoring()
  check(t:find("Tailoring: not learned"), "not learned")
  check(t:find("Linen Cloth  %-  you need this now"), "cloth for the first step")
  win():Hide()
end

function S.tailorSkillUps()
  if not D() then return end
  MOCK.advance(10)
  MOCK.setSkill("Tailoring", 159, 225); MOCK.advance(1.2)
  MOCK.setSkill("Tailoring", 160, 225); MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Tailoring 160", "Tailoring card at a new step")
  check(t and MOCK.textUnder(t):find("Crimson Silk Vest"), "card names Crimson Silk Vest")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(10)
  MOCK.level = 9
  MOCK.setSkill("Tailoring", 60, 75); MOCK.advance(1.2)
  MOCK.advance(10)
  MOCK.level = 10
  MOCK.event("PLAYER_LEVEL_UP", 10, 10, 0, 0, 0, 0, 0)
  MOCK.advance(4.5)
  t = toast()
  local text = t and t:IsShown() and MOCK.textUnder(t) or ""
  check(text:find("TRAIN JOURNEYMAN TAILORING") and text:find("An Expert, Master or Artisan Tailor"), "level-up banner: train Journeyman Tailoring")
  MOCK.advance(10)
end

function S.tailorDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Tailoring 150/225, step 147%-160 Earthen Vest"), "Tailoring step in debug")
end

function S.tailorClosed()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Tailoring not seen"), "Tailoring not seen under a closed heading")
end

-- Enchanting: rods per step, Motes counted as Strange Dust, the disenchanting section and your bags.
local function enchanting() click(win(), "Enchanting"); return profText() end

function S.enchantTab()
  if not D() then return end
  openAt(30, "Professions")
  local t = enchanting()
  check(t:find("Enchanting 150 / 225"), "Enchanting header")
  check(t:find("Enchant Bracer %- Lesser Stamina") and t:find("about 5 more to 155"), "step at 150")
  check(t:find("Enchant your own bracers"), "what to enchant")
  check(t:find("\nDISENCHANTING\n"), "disenchanting section")
  if GetItemCount then
    check(t:find("Rod: Runed Silver Rod %- you need it"), "rod line: you need it")
    MOCK.bags["Runed Silver Rod"] = 1
    check(enchanting():find("Rod: Runed Silver Rod %(you have it%)"), "rod line: you have it")
    MOCK.bags["Runed Silver Rod"] = nil
    t = enchanting()
  else
    check(t:find("Rod: Runed Silver Rod") and not t:find("you need it"), "rod line without bag counts")
  end
  check(not shoppingText():find("%d+ Mote of Magic"), "no Mote rows in the shopping list")
  local marked, first = textY(win(), "^Level 26%-30: Soul Dust.*you need this now"), textY(win(), "^Level 1%-10:")
  check(marked and first and marked < first, "the Soul Dust band first and marked")
  check(t:find("3 Lesser make 1 Greater"), "essence line")
  if not C_Container then check(not t:find("IN YOUR BAGS"), "no bag list without the bag API") end
  local function has(l) return findButton(win(), function(x) return x == l end) end
  check(has("Blacksmithing") and has("Mining") and has("Tailoring") and has("Enchanting"), "four profession buttons")
  for _, name in ipairs({ "Blacksmithing", "Mining", "Tailoring", "Enchanting" }) do
    local b = has(name)
    local _, _, _, x = b:GetPoint(1)
    check(x and x + b:GetWidth() <= 568, name .. " button inside the 568 content width (" .. tostring(x) .. " + " .. tostring(b:GetWidth()) .. ")")
  end
  MOCK.staleUnder(win(), "Professions")
  win():Hide()
end

-- A better rod, the start and the end of the route.
function S.enchantTabCases()
  if not D() then return end
  openAt(30, "Professions")
  if GetItemCount then
    MOCK.bags = { ["Runed Truesilver Rod"] = 1 }
    check(enchanting():find("Rod: Runed Silver Rod %(you have it%)"), "a better rod counts")
    MOCK.bags = {}
  end
  MOCK.setSkill("Enchanting", 1, 75)
  local t = enchanting()
  check(t:find("Runed Copper Rod") and t:find("Dust to Motes"), "skill 1: the rod, then Dust to Motes")
  check(shoppingText():find("Strange Dust %(for %d+ motes"), "Motes counted as Strange Dust")
  check(shoppingText():find("\n1 Mote of Magic"), "the rod's first Mote stays on the list: it must be bought")
  if GetItemCount then
    check(not t:find("make them from Strange Dust"), "skill 1, no rod: no 'make them from' (Dust to Motes needs the rod)")
    MOCK.setSkill("Enchanting", 12, 75)
    MOCK.bags = { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 4 }
    check(enchanting():find("make them from Strange Dust %(1 makes 3%): your 4 make 12"), "Motes: 1 dust makes 3")
    MOCK.bags = { ["Runed Arcanite Rod"] = 1 }
    MOCK.setSkill("Enchanting", 265, 300)
    check(enchanting():find("Rod: Runed Truesilver Rod %(you have it%)"), "an Arcanite rod counts for the Truesilver one")
    MOCK.bags = {}
  end
  check(t:find("Level 1%-10: Strange Dust[^\n]*you need this now"), "the Strange Dust band marked at 1")
  MOCK.setSkill("Enchanting", 265, 300)
  t = enchanting()
  check(t:find("Enchant Shield %- Greater Stamina") and t:find("Mythrin'dir") and t:find("any shield"), "skill 265: shield, formula vendor")
  MOCK.setSkill("Enchanting", 300, 300)
  t = enchanting()
  check(t:find("ROUTE DONE") and not t:find("you need this now"), "route done at 300")
  MOCK.setSkill("Enchanting", 150, 225)
  win():Hide()
end

function S.enchantBags()
  if not D() or not C_Container then return end
  MOCK.bagItems = {
    { name = "Ironforge Boots", quality = 2, level = 22, class = "Armor" },
    { name = "Rusty Sword", quality = 2, level = 8, class = "Weapon" },
    { name = "Blue Cloak", quality = 3, level = 33, class = "Armor" },
    { name = "Linen Shirt", quality = 1, level = 5, class = "Armor" },
    { name = "Copper Ore", quality = 1, level = 1, class = "Trade Goods" },
    { name = "Unseen Gloves", quality = 2, level = 30, class = "Armor", loaded = false },
  }
  openAt(30, "Professions")
  local t = enchanting()
  check(t:find("IN YOUR BAGS"), "bag list")
  check(t:find("Ironforge Boots %(level 22%): Soul Dust or Greater Astral Essence"), "green armour: dust then essence")
  check(t:find("Rusty Sword %(level 8%): Lesser Magic Essence or Strange Dust"), "green weapon: essence then dust")
  check(t:find("Blue Cloak %(level 33%): Large Glowing Shard"), "blue: the shard")
  check(not t:find("Linen Shirt") and not t:find("Copper Ore") and not t:find("Unseen Gloves"), "white, non-gear and unloaded items left out")
  local boots, sword = textY(win(), "^Ironforge Boots"), textY(win(), "^Rusty Sword")
  check(boots and sword and boots < sword, "the Soul Dust item first at 150")
  MOCK.bagItems = {}
  for i = 1, 12 do MOCK.bagItems[i] = { name = "Green Thing " .. i, quality = 2, level = 10 + i, class = "Armor" } end
  t = enchanting()
  local rows = 0
  for _ in t:gmatch("Green Thing %d+ %(level") do rows = rows + 1 end
  check(rows == 8, "at most 8 bag rows (" .. rows .. ")")
  MOCK.bagItems = {}
  check(enchanting():find("No green or blue weapons or armour in your bags"), "empty bags")
  win():Hide()
end

function S.enchantSkillUps()
  if not D() then return end
  MOCK.advance(10)
  MOCK.setSkill("Enchanting", 159, 225); MOCK.advance(1.2)
  MOCK.setSkill("Enchanting", 160, 225); MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Enchanting 160", "Enchanting card at a new step")
  check(t and MOCK.textUnder(t):find("Enchant Boots %- Lesser Agility"), "card names Boots - Lesser Agility")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(10)
  MOCK.level = 9
  MOCK.setSkill("Enchanting", 60, 75); MOCK.advance(1.2)
  MOCK.advance(10)
  MOCK.level = 10
  MOCK.event("PLAYER_LEVEL_UP", 10, 10, 0, 0, 0, 0, 0)
  MOCK.advance(4.5)
  t = toast()
  local text = t and t:IsShown() and MOCK.textUnder(t) or ""
  check(text:find("TRAIN JOURNEYMAN ENCHANTING") and text:find("An Expert, Master or Artisan Enchanter"), "level-up banner: train Journeyman Enchanting")
  MOCK.advance(10)
end

function S.enchantDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Enchanting 150/225, step 135%-155 Enchant Bracer %- Lesser Stamina"), "Enchanting step in debug")
end

function S.makeCraftWindow(style)
  local f = CreateFrame("Frame", "TradeSkillFrame", UIParent); f:SetSize(384, 512); f:Hide()
  -- the selected recipe's details pane: its name in big letters, like the game's
  local details = CreateFrame("Frame", nil, f); details:SetSize(300, 180)
  local dname = details:CreateFontString(nil, "OVERLAY"); dname:SetText("Rough Bronze Leggings")
  MOCK.trade = { line = "Blacksmithing", rank = 97, max = 150, style = style or "classic", offset = 0, selected = 0, rows = {},
    recipes = { { "Rough Sharpening Stone", "trivial", 5 }, { "Copper Chain Belt", "trivial", 3 }, { "Runed Copper Belt", "easy", 1 },
                { "Rough Bronze Leggings", "optimal", 4 } } }
  -- style "scrollbox": Forever's own window, a modern ScrollBox of anonymous pooled rows
  local box = style == "scrollbox" and CreateFrame("Frame", nil, f) or nil
  if box then box:SetSize(300, 140) end
  for i = 1, 8 do
    local b = CreateFrame("Button", (not box) and ("TradeSkillSkill" .. i) or nil, box or f); b:SetSize(300, 16)
    MOCK.trade.rows[i] = b
  end
  MOCK.trade.layout = function()
    for i, b in ipairs(MOCK.trade.rows) do
      local r = MOCK.trade.recipes[i + MOCK.trade.offset]
      if r then
        local name = r[2] == "optimal" and ("|cffff8040" .. r[1] .. "|r") or r[1]
        b:SetText("  " .. name .. (r[3] > 0 and (" [" .. r[3] .. "]") or "")); b:Show()
      else
        b:Hide()
      end
    end
  end
  MOCK.trade.layout()
  if box then
    -- scrolls by percentage; ScrollToElementDataByPredicate is added by the scenario that wants it
    -- (elements are tree nodes whose GetData() holds the recipe's name)
    local function maxOffset() return math.max(0, #MOCK.trade.recipes - 8) end
    box.SetScrollPercentage = function(_, p)
      MOCK.trade.offset = math.floor(math.max(0, math.min(1, p)) * maxOffset() + 0.5)
      MOCK.trade.layout()
    end
    box.GetScrollPercentage = function()
      local m = maxOffset()
      return m > 0 and MOCK.trade.offset / m or 0
    end
    MOCK.trade.box = box
    MOCK.trade.scrollToPredicate = function(_, pred)
      for i, r in ipairs(MOCK.trade.recipes) do
        local node = { GetData = function() return { name = r[1], kind = r[2] } end }
        if pred(node) then
          MOCK.trade.offset = math.max(0, math.min(i - 4, maxOffset()))
          MOCK.trade.layout()
          return node
        end
      end
    end
    return f
  end
  -- the classic list scrolls through FauxScrollFrame_SetOffset + TradeSkillFrame_Update
  TradeSkillListScrollFrame = CreateFrame("ScrollFrame", "TradeSkillListScrollFrame", f)
  TRADE_SKILLS_DISPLAYED = 8
  FauxScrollFrame_SetOffset = function(frame, offset) if frame == TradeSkillListScrollFrame then MOCK.trade.offset = offset end end
  TradeSkillFrame_Update = function() MOCK.trade.layout() end
  if style == "retail" then
    GetTradeSkillLine, GetNumTradeSkills, GetTradeSkillInfo, SelectTradeSkill = nil, nil, nil, nil
    S.retailAPI()
  end
  return f
end

-- Retail's C_TradeSkillUI over MOCK.trade.
function S.retailAPI()
    C_TradeSkillUI = {
      GetBaseProfessionInfo = function()
        return { professionName = MOCK.trade.line, skillLevel = MOCK.trade.rank, maxSkillLevel = MOCK.trade.max }
      end,
      GetAllRecipeIDs = function()
        local ids = {}
        for i = 1, #MOCK.trade.recipes do ids[i] = 1000 + i end
        return ids
      end,
      GetRecipeInfo = function(id)
        local r = MOCK.trade.recipes[id - 1000]
        if r then return { name = r[1], learned = true, numAvailable = r[3], relativeDifficulty = RELATIVE[r[2]] } end
      end,
      OpenRecipe = function(id)
        local i = id - 1000
        MOCK.trade.selected = i
        MOCK.trade.offset = math.max(0, i - 4)
        MOCK.trade.layout()
      end,
    }
end

local function openCraft() TradeSkillFrame:Show(); MOCK.event("TRADE_SKILL_SHOW"); MOCK.advance(0.6) end
local function closeCraft() TradeSkillFrame:Hide(); MOCK.event("TRADE_SKILL_CLOSE"); MOCK.advance(0.6) end
local function craftReady() return D() and not MOCK.minimal and _G.TradeSkillFrame end

function S.craftTrace()
  if not craftReady() then return end
  MOCK.setSkill("Blacksmithing", 97, 150)
  openCraft()
  local tr, h = _G.LevelingCodexCraftTrace, _G.LevelingCodexCraftHint
  check(h and h:IsShown(), "card beside the crafting window")
  local text = MOCK.textUnder(h)
  check(text:find("Rough Bronze Leggings") and text:find("About 3 more to 100") and text:find("materials for 4"), "card text")
  check(text:find("orange"), "live colour on the card")
  check(tr and tr:IsShown(), "row traced")
  local _, rel = tr:GetPoint(1)
  check(rel == TradeSkillSkill4, "trace on the Rough Bronze Leggings row (its text has a colour code and a count)")
  closeCraft()
  check(not tr:IsShown() and not h:IsShown(), "trace and card hide with the window")
end

function S.craftNotLearned()
  if not craftReady() then return end
  table.remove(MOCK.trade.recipes, 4); MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Not learned yet"), "not learned")
  check(not LevelingCodexCraftTrace:IsShown(), "nothing to trace")
  closeCraft()
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 4 })
  MOCK.trade.layout()
end

function S.craftGrey()
  if not craftReady() then return end
  MOCK.trade.recipes[4][2] = "trivial"; MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Grey now: next is Heavy Grinding Stone"), "grey: move on")
  closeCraft()
  MOCK.trade.recipes[4][2] = "optimal"; MOCK.trade.layout()
end

function S.craftScrolled()
  if not craftReady() then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
  openCraft()
  local h = LevelingCodexCraftHint
  check(h:IsShown() and not LevelingCodexCraftTrace:IsShown(), "card without a trace when the row is off screen")
  check(MOCK.textUnder(h):find("It's in the list: scroll to it.", 1, true), "the card says to scroll to it")
  MOCK.trade.offset = 11; MOCK.trade.layout() -- the player scrolls to it
  MOCK.advance(2.3)
  check(LevelingCodexCraftTrace:IsShown(), "traced once the player scrolls to it")
  check(MOCK.trade.selected == 0, "nothing selected for the player")
  closeCraft()
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
end

-- Reported in game: on the controller the crafting list wouldn't scroll once the card came up, then
-- the game crashed. The guide selected the recipe, scrolled the list and clicked its row by itself
-- (and offered Show it to do the same). The crafting window is the player's: the guide only reads
-- it and outlines the row when it's in view.
function S.craftHandsOff()
  if not craftReady() then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  local touched, restore = {}, {}
  local function spy(t, k, label)
    local f = t and t[k]
    if type(f) ~= "function" then return end
    t[k] = function(...) touched[#touched + 1] = label; return f(...) end
    restore[#restore + 1] = function() t[k] = f end
  end
  local box = MOCK.trade.box
  if box then box.ScrollToElementDataByPredicate = MOCK.trade.scrollToPredicate end
  spy(_G, "SelectTradeSkill", "SelectTradeSkill")
  spy(_G, "FauxScrollFrame_SetOffset", "FauxScrollFrame_SetOffset")
  spy(_G, "TradeSkillFrame_Update", "TradeSkillFrame_Update")
  spy(C_TradeSkillUI, "OpenRecipe", "C_TradeSkillUI.OpenRecipe")
  spy(box, "SetScrollPercentage", "SetScrollPercentage")
  spy(box, "ScrollToElementDataByPredicate", "ScrollToElementDataByPredicate")
  for i, b in ipairs(MOCK.trade.rows) do spy(b, "Click", "row " .. i .. " Click") end
  for _, pad in ipairs({ true, false }) do
    local who = pad and "controller" or "mouse"
    MOCK.gamepad, MOCK.gamepadUI = pad or nil, pad or nil
    MOCK.trade.offset, MOCK.trade.selected = 0, 0
    MOCK.trade.layout()
    for k in pairs(touched) do touched[k] = nil end
    openCraft()
    MOCK.advance(3)
    check(#touched == 0, who .. ": the guide never drives the crafting window (" .. table.concat(touched, ", ") .. ")")
    check(MOCK.trade.offset == 0 and MOCK.trade.selected == 0, who .. ": the list stays where the player left it")
    local h = LevelingCodexCraftHint
    local text = h and h:IsShown() and MOCK.textUnder(h) or ""
    check(text:find("It's in the list: scroll to it.", 1, true), who .. ": the card says to scroll to it")
    check(not text:find("Show it"), who .. ": no Show it button")
    closeCraft()
  end
  MOCK.gamepad, MOCK.gamepadUI = nil, nil
  for _, undo in ipairs(restore) do undo() end
  if box then box.ScrollToElementDataByPredicate = nil end
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.offset, MOCK.trade.selected = 0, 0
  MOCK.trade.layout()
end

-- The crafting guide turned off in Settings: nothing over the crafting window.
function S.craftGuideOff()
  if not craftReady() then return end
  LevelingCodexDB.noCraftGuide = true
  openCraft()
  check(not (LevelingCodexCraftHint and LevelingCodexCraftHint:IsShown()), "no card when turned off")
  closeCraft()
  LevelingCodexDB.noCraftGuide = nil
end

-- The Mining (smelting) window at 80: Smelt Silver is the one that still gives points.
function S.craftSmelting()
  if not craftReady() then return end
  MOCK.setSkill("Mining", 80, 150)
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset }
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset = "Mining", 80, 150, 0
  MOCK.trade.recipes = { { "Smelt Copper", "trivial", 9 }, { "Smelt Tin", "trivial", 2 }, { "Smelt Silver", "optimal", 3 },
                         { "Smelt Bronze", "medium", 1 } }
  MOCK.trade.layout()
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("MINING 80") and text:find("Smelt Silver") and text:find("About 20 more to 100"), "smelting card")
  local _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill3, "Smelt Silver row traced")
  closeCraft()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset = unpack(saved)
  MOCK.trade.layout()
end

-- A trainer's real skill requirements that differ from the guide show in /codex debug.
function S.trainerReqs()
  if not D() or MOCK.minimal then return end
  MOCK.trainer = { { "Rough Bronze Leggings", "Blacksmithing", 80 }, { "Runed Copper Belt", "Blacksmithing", 80 },
                   { "Copper Bracers", "Blacksmithing", 1 }, { "Smelt Silver", "Mining", 70 } }
  MOCK.event("TRAINER_SHOW")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("trainer: Rough Bronze Leggings needs 80 %(guide says 95%)"), "difference reported")
  check(chatHas("trainer: Smelt Silver needs 70 %(guide says 75%)"), "smelt difference reported")
  check(not chatHas("Runed Copper Belt needs"), "matching values not reported")
  check(not chatHas("Copper Bracers"), "recipes off the route not reported")
end

-- The game sends TRADE_SKILL_SHOW before its window is on screen: the card still comes.
function S.craftEventFirst()
  if not craftReady() then return end
  closeCraft()
  check(not (LevelingCodexCraftHint and LevelingCodexCraftHint:IsShown()), "starts with the window closed")
  MOCK.event("TRADE_SKILL_SHOW")
  MOCK.advance(0.4)
  TradeSkillFrame:Show()
  MOCK.advance(0.6)
  check(LevelingCodexCraftHint and LevelingCodexCraftHint:IsShown(), "card when the window shows after the event")
  closeCraft()
end

-- A recipe you know but the window's filter or a closed heading hides; one you don't know shows its alternative.
function S.craftFiltered()
  if not craftReady() then return end
  table.remove(MOCK.trade.recipes, 4); MOCK.trade.layout()
  MOCK.knownSpells[2668] = true
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("not in the list: clear the search"), "known but filtered")
  closeCraft()
  MOCK.knownSpells[2668] = nil
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Not learned yet") and text:find("Instead: Runed Copper Belt"), "not learned shows the alternative")
  closeCraft()
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 4 })
  MOCK.trade.layout()
end

-- Classic calls that exist but return nothing (compatibility stubs): C_TradeSkillUI is read instead.
function S.craftClassicStubs()
  if not craftReady() then return end
  local count = GetNumTradeSkills
  S.retailAPI()
  GetNumTradeSkills = function() return 0 end
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("materials for 4"), "recipe read through C_TradeSkillUI")
  closeCraft()
  GetNumTradeSkills = count
  C_TradeSkillUI = nil
end

-- The recipe is in the list but scrolled out of view: the row search slows down (it walks the
-- whole window), yet a row scrolled into view is outlined within about 2 s.
function S.craftRowBackoff()
  if not craftReady() then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
  local searches, walk = 0, TradeSkillFrame.GetChildren
  TradeSkillFrame.GetChildren = function(self) searches = searches + 1; return walk(self) end
  openCraft()
  searches = 0
  MOCK.advance(20)
  check(searches <= 14, "row searched " .. searches .. " times in 20 s while scrolled out of view")
  check(not LevelingCodexCraftTrace:IsShown(), "no outline while out of view")
  local at
  for i, r in ipairs(MOCK.trade.recipes) do if r[1] == "Rough Bronze Leggings" then at = i end end
  MOCK.trade.offset = at - 3; MOCK.trade.layout() -- the player scrolls to it
  MOCK.advance(2.3)
  check(LevelingCodexCraftTrace:IsShown(), "outlined within about 2 s of scrolling into view")
  TradeSkillFrame.GetChildren = nil
  closeCraft()
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
end

-- Reported in game: with the crafting window near the top of the screen the card went below it,
-- over the controller hint bar the game hangs under the window. Bars touching the window's edge
-- count as part of the window.
function S.craftHintClearsBar()
  if not craftReady() or not EnumerateFrames then return end
  TradeSkillFrame._top, TradeSkillFrame._bottom = 1075, 560
  local bar = CreateFrame("Frame", nil, UIParent); bar:SetSize(600, 62)
  bar._top, bar._bottom = 562, 500
  openCraft()
  local h = LevelingCodexCraftHint
  local _, rel, _, _, y = h:GetPoint(1)
  check(h.where == "below" and rel == TradeSkillFrame and y and y <= -66,
    "card below the bar under the window (" .. tostring(h.where) .. ", offset " .. tostring(y) .. ")")
  closeCraft()
  bar:Hide()
  TradeSkillFrame._top, TradeSkillFrame._bottom = nil, nil
end

-- Tailoring at 150 (Earthen Vest takes 3 Bolts of Silk Cloth): with only the cloth, the bolt is
-- outlined first; with bolts, the step's recipe again.
local function tailorWindow(fillers)
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected }
  MOCK.setSkill("Tailoring", 150, 225)
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset, MOCK.trade.selected = "Tailoring", 150, 225, 0, 0
  MOCK.trade.recipes = { { "Bolt of Silk Cloth", "trivial", 11 }, { "Crimson Silk Vest", "optimal", 0 }, { "Earthen Vest", "medium", 0 } }
  for i = 1, fillers or 0 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.bags = { ["Silk Cloth"] = 46 }
  MOCK.trade.layout()
  return function()
    MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected = unpack(saved)
    MOCK.bags = {}
    MOCK.trade.layout()
  end
end

function S.craftTailoring()
  if not craftReady() then return end
  local restore = tailorWindow()
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make Bolts of Silk Cloth first: your 46 Silk Cloth make 11.", 1, true), "bolts first with only the cloth")
  local _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill1, "the bolt row is outlined (grey, but still the one to make)")
  MOCK.bags["Bolt of Silk Cloth"] = 11; MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(text:find("Earthen Vest") and not text:find("first"), "with bolts: the step's recipe")
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill3, "Earthen Vest outlined")
  MOCK.bags = {}; MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Earthen Vest") and not text:find("first"), "no bolts, no cloth: the step's recipe")
  MOCK.bags = { ["Silk Cloth"] = 46 }
  local vest = table.remove(MOCK.trade.recipes, 3); MOCK.trade.layout(); MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Earthen Vest") and text:find("Not learned yet") and not text:find("first"),
    "the step's recipe not learned: say so, not bolts first")
  table.insert(MOCK.trade.recipes, vest)
  table.remove(MOCK.trade.recipes, 1); MOCK.trade.layout(); MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Earthen Vest") and not text:find("first"), "bolt recipe not in the list: the step's recipe")
  closeCraft()
  restore()
end

-- Enchanting: a missing rod is outlined first (a better rod counts, a grey rod is still needed), then
-- Dust to Motes when you have the dust but no Motes.
local function enchantWindow(skill, max, recipes, bags)
  MOCK.setSkill("Enchanting", skill, max)
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset, MOCK.trade.selected = "Enchanting", skill, max, 0, 0
  MOCK.trade.recipes = recipes
  MOCK.bags = bags
  MOCK.trade.layout()
  MOCK.advance(1)
end

function S.craftEnchanting()
  if not craftReady() then return end
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected }
  enchantWindow(150, 225, { { "Runed Silver Rod", "easy", 0 }, { "Enchant Bracer - Lesser Stamina", "optimal", 0 },
    { "Dust to Motes", "trivial", 3 } }, {})
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make your Runed Silver Rod first: every enchant from here needs it.", 1, true), "rod first")
  local _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill1, "the rod row is outlined")
  MOCK.bags["Runed Truesilver Rod"] = 1; MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(text:find("Enchant Bracer %- Lesser Stamina") and not text:find("first"), "a better rod counts: the step's recipe")
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill2, "the bracer row is outlined")
  MOCK.bags = {}
  table.remove(MOCK.trade.recipes, 2); MOCK.trade.layout(); MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Not learned yet") and not text:find("first"), "the step's recipe missing: not learned, not the rod")
  enchantWindow(270, 300, { { "Runed Truesilver Rod", "trivial", 0 }, { "Enchant Shield - Greater Stamina", "optimal", 0 } }, {})
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make your Runed Truesilver Rod first") and not text:find("Grey now"), "a grey rod still needed")
  check(LevelingCodexCraftTrace:IsShown(), "the grey rod is outlined")
  enchantWindow(1, 75, { { "Runed Copper Rod", "optimal", 0 }, { "Dust to Motes", "optimal", 5 } }, { ["Strange Dust"] = 5 })
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Runed Copper Rod") and not text:find("Make Motes of Magic first"), "skill 1: the rod, not Motes (Dust to Motes needs the rod)")
  enchantWindow(12, 75, { { "Dust to Motes", "trivial", 5 }, { "Enchant Bracer - Inferior Stamina", "optimal", 0 } },
    { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 5 })
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make Motes of Magic first: your 5 Strange Dust make 15.", 1, true), "Motes first: 3 per dust")
  closeCraft()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected = unpack(saved)
  MOCK.bags = {}
  MOCK.trade.layout()
end

-- The crafting window closed by its own close button (no event yet): the guide goes at once.
function S.craftOnHide()
  if not craftReady() then return end
  openCraft()
  check(LevelingCodexCraftHint:IsShown(), "card up")
  TradeSkillFrame:Hide()
  check(not LevelingCodexCraftHint:IsShown() and not LevelingCodexCraftTrace:IsShown(), "card and outline hide with the window")
  MOCK.event("TRADE_SKILL_CLOSE"); MOCK.advance(0.6)
end

-- Smelting at 66 (Bronze beats green Tin), 100 (Silver is yellow: a chance, not a count) and 145 (nothing gives points).
function S.craftSmeltingCases()
  if not craftReady() then return end
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset }
  local function at(rank, recipes)
    MOCK.setSkill("Mining", rank, 225)
    MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset = "Mining", rank, 225, 0
    MOCK.trade.recipes = recipes
    MOCK.trade.layout()
    openCraft()
    local text = MOCK.textUnder(LevelingCodexCraftHint)
    closeCraft()
    return text
  end
  local t = at(66, { { "Smelt Copper", "trivial", 9 }, { "Smelt Tin", "easy", 2 }, { "Smelt Bronze", "medium", 1 } })
  check(t:find("Smelt Bronze") and not t:find("Smelt Tin"), "66: Smelt Bronze, the better chance")
  t = at(100, { { "Smelt Copper", "trivial", 9 }, { "Smelt Tin", "trivial", 2 }, { "Smelt Bronze", "easy", 1 },
                { "Smelt Silver", "medium", 3 } })
  check(t:find("Smelt Silver") and t:find("chance of a point") and not t:find("About %d+ more"), "100: a chance, not a count")
  t = at(145, { { "Smelt Copper", "trivial", 9 }, { "Smelt Bronze", "trivial", 1 }, { "Smelt Silver", "trivial", 3 },
                { "Smelt Iron", "trivial", 5 } })
  check(t:find("no points at 145") and t:find("Smelt Gold") and t:find("155"), "145: mine instead, Gold from 155")
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset = unpack(saved)
  MOCK.trade.layout()
end
