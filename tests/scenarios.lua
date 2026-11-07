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
      local t = toast()
      check(t and t:IsShown(), "banner shown at level " .. level)
      check(t.title and t.title:GetText() == "Level " .. level, "banner title at level " .. level)
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
  MOCK.advance(0.5)
  local t = toast()
  MOCK.mouseOver[t] = true
  MOCK.advance(12)
  check(t:IsShown(), "banner stays while hovered")
  MOCK.mouseOver[t] = nil
  MOCK.advance(12)
  check(not t:IsShown(), "banner fades after mouse leaves")
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(0.5)
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
    check(t.title:GetText() == "Level " .. l, "/codex test " .. l)
    MOCK.fire(t, "OnMouseUp", "RightButton")
    MOCK.advance(1.5)
  end
end

local TABS = { "This Level", "Talents", "Trainer", "Macros", "Tips", "Settings" }

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
  for _, k in ipairs({ "noToast", "quiet", "noAutoMacros", "noTalentGuide", "noMinimap" }) do
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
      end
      seen[b.expectShape] = true
    end
    talent.root:Hide()
    MOCK.advance(0.3)
  end
  check(seen.circle and seen.square, "both circle and square talents were traced")
end

-- /codex debug runs anywhere and reports the art and the talent guide.
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
