-- Macros.lua: creates and updates this character's macros for the current level.
--
-- Auto-update after a level-up only touches macros the Codex made. Those are recognised by
-- LevelingCodexCharDB.made OR by a body that matches one of the guide's versions, because
-- SavedVariables may not load in Forever and the feature must not depend on them.

local _, ns = ...

-- Set up while in combat: "full" (asked for by the player) or "refresh" (after a level-up).
local pending

local function trim(s) return (tostring(s or ""):gsub("%s+$", "")) end

local function macroIndex(name)
  local ok, i = ns.try(GetMacroIndexByName, name)
  return ok and i or 0
end

-- The body of a macro, or nil when the client can't tell us.
local function macroBody(index)
  local ok, _, _, body = ns.try(GetMacroInfo, index)
  if ok then return body end
end

-- Does this existing macro look like one the Codex made?
local function isOurs(index, name)
  local made = ns.charDB().made
  if made and made[name] then return true end
  local body = macroBody(index)
  if not body or not ns.D then return false end
  body = trim(body)
  for _, m in ipairs(ns.D.macros) do
    if m.name == name and trim(m.body) == body then return true end
  end
  return false
end
ns.isOurMacro = isOurs

-- How many of the guide's macros exist on this character with one of the guide's bodies.
function ns.countOurMacros()
  if not ns.D then return 0 end
  local n, seen = 0, {}
  for _, m in ipairs(ns.D.macros) do
    if not seen[m.name] then
      seen[m.name] = true
      local i = macroIndex(m.name)
      if i > 0 then
        local body = macroBody(i)
        for _, v in ipairs(ns.D.macros) do
          if v.name == m.name and body and trim(v.body) == trim(body) then n = n + 1; break end
        end
      end
    end
  end
  return n
end

-- onlyExisting = true: the after-level-up refresh, which only touches macros the Codex made.
-- Returns made, updated, failed (list of names).
function ns.setupMacros(onlyExisting)
  if not ns.D then return end
  if InCombatLockdown() then
    if onlyExisting then
      pending = pending or "refresh"
    else
      pending = "full"
      ns.say("you're in combat - your macros will be set up when the fight ends.")
    end
    return
  end
  if not LevelingCodexCharDB then LevelingCodexCharDB = {} end
  LevelingCodexCharDB.made = LevelingCodexCharDB.made or {}
  local level = UnitLevel("player")
  local made, updated, same, failed = 0, 0, 0, {}
  for _, m in ipairs(ns.macrosFor(level)) do
    local index = macroIndex(m.name)
    if index and index > 0 then
      if not onlyExisting or isOurs(index, m.name) then
        local current = macroBody(index)
        if current and trim(current) == trim(m.body) then
          LevelingCodexCharDB.made[m.name] = true -- already right: nothing to do
          same = same + 1
        else
          local ok = pcall(EditMacro, index, m.name, ns.QUESTION_ICON, m.body)
          if ok then
            updated = updated + 1
            LevelingCodexCharDB.made[m.name] = true
          else
            failed[#failed + 1] = m
          end
        end
      end
    elseif not onlyExisting then
      local ok, newIndex = pcall(CreateMacro, m.name, ns.QUESTION_ICON, m.body, true)
      if ok and newIndex then
        made = made + 1
        LevelingCodexCharDB.made[m.name] = true
      else
        failed[#failed + 1] = m
      end
    end
  end
  if onlyExisting then
    if updated > 0 then ns.say("updated " .. updated .. " macro(s) for level " .. level .. ".") end
    return made, updated, failed
  end
  ns.say(ns.GREEN .. made .. " created|r, " .. updated .. " updated" ..
    (same > 0 and (", " .. same .. " already up to date") or "") .. " for level " .. level ..
    ". Open " .. ns.WHITE .. "Esc > Macros|r (character tab) and drag them onto your bars - /codex shows where.")
  if #failed > 0 then
    local names = {}
    for i, m in ipairs(failed) do names[i] = m.name end
    ns.say("couldn't make: " .. table.concat(names, ", ") .. ". Your character macro slots may be full.")
    if ns.showMacroCopy then ns.showMacroCopy(failed[1], failed) end
  end
  return made, updated, failed
end

-- PLAYER_REGEN_ENABLED: finish a setup that was asked for during combat.
function ns.flushPendingMacros()
  if not pending then return end
  local mode = pending
  pending = nil
  ns.setupMacros(mode == "refresh")
end
