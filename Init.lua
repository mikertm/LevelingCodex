-- Init.lua: events and the /codex slash command. Loaded last.
-- /codex          show or hide the guide window (Settings button inside for all options)
-- /codex macros   create or update your macros for your current level
-- /codex test     preview the level-up banner (/codex test 30 for any level)
-- /codex reset    put the banner and window back where they started
-- (still work: /codex pad xbox|ps|switch, /codex banner, /codex quiet, /codex minimap)

local _, ns = ...

-- Were the saved variables there when the client loaded us? (Forever may not load them.)
local hadDB, hadCharDB

local function noteSavedState()
  if hadDB == nil then hadDB = LevelingCodexDB ~= nil end
  if hadCharDB == nil then hadCharDB = LevelingCodexCharDB ~= nil end
end

-- Runs once, at PLAYER_LOGIN (or PLAYER_ENTERING_WORLD if the class wasn't known yet).
local function start()
  if ns.started then return end
  noteSavedState()
  LevelingCodexDB = LevelingCodexDB or {}
  LevelingCodexCharDB = LevelingCodexCharDB or {}
  LevelingCodexDB.v = 1 -- so a table that comes back next session is told apart from a lost one
  ns.useTheme(LevelingCodexDB.theme)
  local localized, token = UnitClass("player")
  if not token then return end -- try again at PLAYER_ENTERING_WORLD
  ns.started = true
  ns.CLASS_NAME = localized
  ns.D = LevelingCodexData and LevelingCodexData[token]
  if not ns.D then return end
  ns.say("loaded the " .. ns.D.spec .. " " .. localized .. " guide. Type " .. ns.WHITE .. "/codex|r or click the book on your minimap.")
  -- Macros from an earlier session but no saved settings: they didn't load (a known Forever issue).
  if (not hadDB or not hadCharDB) and ns.countOurMacros() > 0 then
    ns.settingsLost = true
    ns.say("your settings from last time didn't load (a known WoW: Forever issue), so the defaults are in use. Your macros still update.")
  end
  ns.updateMini()
  ns.startTalentGuide()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LEVEL_UP")
-- anything beyond the core events is pcall'd: an unknown event throws and would abort this file
for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "ADDON_LOADED", "PLAYER_ENTERING_WORLD" }) do
  pcall(events.RegisterEvent, events, ev)
end
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    start()
  elseif event == "PLAYER_LEVEL_UP" then
    local level = tonumber(arg1) or UnitLevel("player")
    ns.levelUpMessage(level)
    ns.showToast(level)
    ns.after(1, function()
      if not ns.db().noAutoMacros then
        ns.setupMacros(true) -- refresh only the macros this addon made, so versions follow your level
      end
      ns.refresh()
    end)
  elseif event == "ADDON_LOADED" then
    local n = tostring(arg1 or "")
    if n == "LevelingCodex" then
      noteSavedState()
    elseif n:find("Talent") or n:find("PlayerSpells") or n:find("Trait") or n:find("Legacy") then
      -- the talent UI loads on demand: its toggle functions may only exist now
      ns.hookTalentToggles()
      ns.after(0.5, function() ns.discoverTalentRoots(true) end)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    ns.flushPendingMacros()
  end
end)

local function testBanner(level)
  ns.showToast(level, true, true)
  if PlaySound then pcall(PlaySound, 888) end
end

-- Key binding (Bindings.xml): Esc > Options > Keybindings > AddOns > Leveling Codex.
BINDING_HEADER_LEVELINGCODEX = "Leveling Codex"
BINDING_NAME_LEVELINGCODEX_TOGGLE = "Open or close the Codex"
function LevelingCodex_Toggle() ns.toggleWindow() end

SLASH_LEVELINGCODEX1 = "/codex"
SlashCmdList.LEVELINGCODEX = function(msg)
  msg = string.lower((tostring(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")))
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  if not LevelingCodexDB then LevelingCodexDB = {} end
  local db = LevelingCodexDB
  if cmd == "" then
    ns.toggleWindow()
  elseif cmd == "macros" then
    ns.setupMacros(false)
  elseif cmd == "pad" and ns.PADS[rest] then
    db.pad = rest
    ns.say("showing " .. rest .. " button names.")
    ns.refresh()
  elseif cmd == "test" then
    testBanner(tonumber(rest) or UnitLevel("player"))
  elseif cmd == "banner" then
    db.noToast = not db.noToast
    ns.say("level-up banner " .. (db.noToast and "off." or "on."))
  elseif cmd == "quiet" then
    db.quiet = not db.quiet
    ns.say("level-up messages " .. (db.quiet and "off." or "on."))
  elseif cmd == "minimap" then
    db.noMinimap = not db.noMinimap
    ns.updateMini()
    ns.say("minimap button " .. (db.noMinimap and "hidden." or "shown."))
  elseif cmd == "reset" then
    db.toastPos, db.toastScale = nil, 1
    db.windowPos, db.windowScale = nil, 1
    ns.placeToast()
    ns.placeWindow()
    db.minimapAngle = nil
    ns.updateMini()
    ns.say("banner, window and minimap button positions and sizes reset.")
  else
    ns.say("/codex opens the guide - everything else is under its Settings button. Also: /codex macros, /codex test, /codex reset")
  end
end
