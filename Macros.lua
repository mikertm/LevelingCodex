-- Macros.lua: creates and updates this character's macros for the current level.
--
-- Auto-update after a level-up only touches macros the Codex made. Those are recognised by
-- LevelingCodexCharDB.made OR by a body that matches one of the guide's versions, because
-- SavedVariables may not load in Forever and the feature must not depend on them.

local _, ns = ...

-- Set up while in combat: "full" (asked for by the player) or "refresh" (after a level-up).
local pending

-- Exact bodies from before the Warrior priority update. Their names stay on existing bars.
local warriorLegacyBodies = {
  Fight = {
    "#showtooltip\n/startattack\n/cast [nocombat] Charge\n" ..
      "/castsequence [combat] reset=target Rend, Heroic Strike, Heroic Strike, Heroic Strike",
    "#showtooltip\n/startattack\n/cast [nocombat,nostance:1] Battle Stance\n/cast [nocombat] Charge\n" ..
      "/cast [combat,stance:1] Defensive Stance\n/castsequence [combat,stance:2] reset=target Rend, Sunder Armor, Sunder Armor",
    "#showtooltip\n/startattack\n/cast [nocombat] Charge\n/cast [nostance:2] Defensive Stance\n" ..
      "/castsequence [combat] reset=target Rend, Sunder Armor, Sunder Armor",
    "#showtooltip\n/startattack\n/cast [nocombat] Charge\n/cast [nostance:2] Defensive Stance\n" ..
      "/castsequence [combat] reset=target Shield Slam, Rend, Sunder Armor, Sunder Armor, Shield Slam, Sunder Armor, Sunder Armor, Sunder Armor",
  },
  ["Fight pack"] = {
    "#showtooltip\n/startattack\n/cast [combat,stance:1] Defensive Stance\n" ..
      "/castsequence [combat] reset=target Thunder Clap, Sunder Armor, Cleave, Sunder Armor, Sunder Armor",
  },
  ["Block & Revenge"] = { "#showtooltip\n/startattack\n/castsequence reset=6/target/combat Shield Block, Revenge" },
  ["Rage up"] = { "#showtooltip\n/castsequence reset=60 Bloodrage, Battle Shout" },
  Panic = { "#showtooltip\n/castsequence reset=180 Last Stand, Shield Wall" },
}

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

local function matchesGuideBody(name, body)
  if not body or not ns.D then return false end
  body = trim(body)
  for _, m in ipairs(ns.D.macros) do
    if m.name == name and trim(m.body) == body then return true end
  end
  local legacy = ns.D == LevelingCodexData.WARRIOR and warriorLegacyBodies[name]
  if legacy then
    for _, oldBody in ipairs(legacy) do
      if oldBody == body then return true end
    end
  end
  return false
end

-- Does this existing macro look like one the Codex made?
local function isOurs(index, name)
  local made = ns.charDB().made
  if made and made[name] then return true end
  return matchesGuideBody(name, macroBody(index))
end
ns.isOurMacro = isOurs

-- How many of the guide's macros exist with a current or previous Codex body.
function ns.countOurMacros()
  if not ns.D then return 0 end
  local n, seen = 0, {}
  for _, m in ipairs(ns.D.macros) do
    if not seen[m.name] then
      seen[m.name] = true
      local i = macroIndex(m.name)
      if i > 0 and matchesGuideBody(m.name, macroBody(i)) then n = n + 1 end
    end
  end
  return n
end

-- onlyExisting = true: the after-level-up refresh, which only touches macros the Codex made.
-- A macro of the player's own with a guide macro's name is never overwritten: it is kept and
-- the Codex version is offered in the copy box. Returns made, updated, failed, kept.
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
  local made, updated, same, failed, kept = 0, 0, 0, {}, {}
  for _, m in ipairs(ns.macrosFor(level)) do
    local index = macroIndex(m.name)
    if index and index > 0 then
      if not isOurs(index, m.name) then
        -- the player's own macro under the same name: never overwrite it
        if not onlyExisting then kept[#kept + 1] = m end
      else
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
  local function names(list)
    local out = {}
    for i, m in ipairs(list) do out[i] = m.name end
    return table.concat(out, ", ")
  end
  if #kept > 0 then
    ns.say("kept your own macro(s) with the same name: " .. names(kept) .. ". The Codex version is in the copy box - rename yours to use both.")
  end
  if #failed > 0 then
    ns.say("couldn't make: " .. names(failed) .. ". Your character macro slots may be full.")
  end
  -- everything the player has to make by hand, in one copy box
  local manual = {}
  for _, m in ipairs(failed) do manual[#manual + 1] = m end
  for _, m in ipairs(kept) do manual[#manual + 1] = m end
  if #manual > 0 and ns.showMacroCopy then ns.showMacroCopy(manual[1], manual) end
  return made, updated, failed, kept
end

-- PLAYER_REGEN_ENABLED: finish a setup that was asked for during combat.
function ns.flushPendingMacros()
  if not pending then return end
  local mode = pending
  pending = nil
  ns.setupMacros(mode == "refresh")
end
