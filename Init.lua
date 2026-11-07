-- Init.lua: events and the /codex slash command. Loaded last.
-- /codex          show or hide the guide window (Settings button inside for all options)
-- /codex macros   create or update your macros for your current level
-- /codex test     preview the level-up banner (/codex test 30 for any level)
-- /codex reset    put the banner and window back where they started
-- (still work: /codex pad xbox|ps|switch, /codex banner, /codex quiet, /codex minimap)

local _, ns = ...

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(events.RegisterEvent, events, "ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" then
    LevelingCodexDB = LevelingCodexDB or {}
    LevelingCodexCharDB = LevelingCodexCharDB or {}
    ns.useTheme(LevelingCodexDB.theme)
    local localized, token = UnitClass("player")
    ns.CLASS_NAME = localized
    ns.D = LevelingCodexData and LevelingCodexData[token]
    if ns.D then
      ns.say("loaded the " .. ns.D.spec .. " " .. localized .. " guide. Type " .. ns.WHITE .. "/codex|r or click the book on your minimap.")
      ns.updateMini()
      ns.startTalentGuide()
    end
  elseif event == "PLAYER_LEVEL_UP" then
    local level = tonumber(arg1) or UnitLevel("player")
    ns.levelUpMessage(level)
    ns.showToast(level)
    C_Timer.After(1, function()
      if not LevelingCodexDB.noAutoMacros then
        ns.setupMacros(true) -- refresh only the macros this addon made, so versions follow your level
      end
      ns.refresh()
    end)
  elseif event == "ADDON_LOADED" then
    local n = tostring(arg1 or "")
    if n:find("Talent") or n:find("PlayerSpells") or n:find("Trait") or n:find("Legacy") then
      if C_Timer then C_Timer.After(0.5, ns.discoverTalentRoots) end
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    ns.flushPendingMacros()
  end
end)

local function testBanner(level)
  ns.showToast(level, true, true)
  if PlaySound then pcall(PlaySound, 888) end
end

SLASH_LEVELINGCODEX1 = "/codex"
SlashCmdList.LEVELINGCODEX = function(msg)
  msg = strlower(strtrim(msg or ""))
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
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
