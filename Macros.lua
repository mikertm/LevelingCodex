-- Macros.lua: creates and updates this character's macros for the current level.

local _, ns = ...

local pending = false -- asked for in combat: done when the fight ends

-- onlyExisting = true: the after-level-up refresh, which only touches macros the Codex made.
function ns.setupMacros(onlyExisting)
  if not ns.D then return end
  if InCombatLockdown() then
    pending = true
    ns.say("you're in combat - your macros will be set up when the fight ends.")
    return
  end
  local level = UnitLevel("player")
  local made, updated, failed = 0, 0, {}
  LevelingCodexCharDB.made = LevelingCodexCharDB.made or {}
  for _, m in ipairs(ns.macrosFor(level)) do
    local index = GetMacroIndexByName(m.name)
    if index and index > 0 then
      if not onlyExisting or LevelingCodexCharDB.made[m.name] then
        local ok = pcall(EditMacro, index, m.name, ns.QUESTION_ICON, m.body)
        if ok then updated = updated + 1 else failed[#failed + 1] = m.name end
      end
    elseif not onlyExisting then
      local ok, newIndex = pcall(CreateMacro, m.name, ns.QUESTION_ICON, m.body, true)
      if ok and newIndex then
        made = made + 1
        LevelingCodexCharDB.made[m.name] = true
      else
        failed[#failed + 1] = m.name
      end
    end
  end
  if onlyExisting then
    if updated > 0 then ns.say("updated " .. updated .. " macro(s) for level " .. level .. ".") end
    return
  end
  ns.say(ns.GREEN .. made .. " created|r, " .. updated .. " updated for level " .. level ..
    ". Open " .. ns.WHITE .. "Esc > Macros|r (character tab) and drag them onto your bars - /codex shows where.")
  if #failed > 0 then
    ns.say("couldn't make: " .. table.concat(failed, ", ") .. ". Your character macro slots may be full.")
  end
end

-- PLAYER_REGEN_ENABLED: finish a setup that was asked for during combat.
function ns.flushPendingMacros()
  if not pending then return end
  pending = false
  ns.setupMacros(false)
end
