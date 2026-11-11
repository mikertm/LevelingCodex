-- Working side by side with Questie: its settings decide who auto-accepts and turns in,
-- and its hold-back key stops the Codex too. Everything is read at call time and never errors:
-- Questie may be missing, still loading, or a version with other settings.
local _, ns = ...
local M = {}
ns.questie = M

local function profile()
  local q = _G.Questie
  local db = type(q) == "table" and q.db
  local p = type(db) == "table" and db.profile
  if type(p) == "table" then return p end
end

function M.loaded() return profile() ~= nil end

function M.autoAccept()
  local p = profile()
  if not p then return false end
  if type(p.autoAccept) == "table" then return p.autoAccept.enabled == true end
  return p.autoaccept == true
end

function M.autoComplete()
  local p = profile()
  return p ~= nil and p.autocomplete == true
end

local KEYS = { shift = { "Shift", "IsShiftKeyDown" }, ctrl = { "Ctrl", "IsControlKeyDown" }, alt = { "Alt", "IsAltKeyDown" } }

local function key()
  local p = profile()
  return p and type(p.autoModifier) == "string" and KEYS[p.autoModifier]
end

-- Questie's key when it isn't Alt (Alt already holds the Codex back).
function M.keyName()
  local k = key()
  if k and k[1] ~= "Alt" then return k[1] end
end

function M.modifierHeld()
  local k = key()
  if not k then return false end
  local ok, down = ns.try(_G[k[2]])
  return ok and down ~= nil and down ~= false -- older clients return 1/nil
end

local function scaleOf(frame)
  local ok, s = ns.try(frame.GetEffectiveScale, frame)
  return ok and type(s) == "number" and s > 0 and s or 1
end

-- Questie's tracker, when shown and laid out, and which side of it the step window goes:
-- "left" for a tracker on the right half of the screen, else "right".
function M.trackerSide()
  local tracker = _G.Questie_BaseFrame
  if type(tracker) ~= "table" or type(tracker.IsShown) ~= "function" then return end
  local ok, shown = ns.try(tracker.IsShown, tracker)
  if not ok or not shown then return end
  local cok, cx = ns.try(tracker.GetCenter, tracker)
  local wok, width = ns.try(UIParent.GetWidth, UIParent)
  if not cok or type(cx) ~= "number" or not wok or type(width) ~= "number" then return end
  local onRight = cx * scaleOf(tracker) > width * scaleOf(UIParent) / 2
  return tracker, onRight and "left" or "right"
end

-- QuestieDB, through its public LibQuestieDB API. The check runs once per LibQuestieDB table
-- (a /reload makes a new one); a failure, or a later read error, turns it off for good.
local db -- { lib, ok, reason, zones, zoneCount }
M.arrowState = "waiting"

-- A Lua source string returning AreaId -> UiMapID, run with nothing in its environment.
local function zoneTable(src)
  if type(src) ~= "string" or type(loadstring) ~= "function" then return end
  local fn = loadstring(src)
  if not fn then return end
  if type(setfenv) == "function" then setfenv(fn, {}) end
  local ok, t = pcall(fn)
  if not ok or type(t) ~= "table" then return end
  local out = {}
  for area, map in pairs(t) do
    if type(area) == "number" and type(map) == "number" then out[area] = map end
  end
  return out
end

local function check(lib)
  local state = { lib = lib }
  local ok, passed = ns.try(lib.RequireContract, 1)
  if not ok or passed ~= true then
    state.reason = "contract check failed"
    return state
  end
  local support = type(lib.Support) == "table" and lib.Support
  local gok, zoneDB = ns.try(support and support.Get, "ZoneDB")
  local private = gok and type(zoneDB) == "table" and type(zoneDB.private) == "table" and zoneDB.private
  local zones = private and zoneTable(private.areaIdToUiMapId)
  if zones then
    for area, map in pairs(zoneTable(private.areaIdToUiMapIdOverride) or {}) do zones[area] = map end
    local count = 0
    for area, map in pairs(zones) do
      if map == 0 then zones[area] = nil else count = count + 1 end
    end
    state.zones, state.zoneCount = zones, count
  end
  if not state.zoneCount or state.zoneCount == 0 then
    state.reason = "no zone table"
    return state
  end
  state.ok = true
  return state
end

function M.usable()
  local lib = _G.LibQuestieDB
  if type(lib) ~= "table" then return false, "not installed" end
  if not db or db.lib ~= lib then
    db = check(lib)
    M.arrowState = "waiting"
  end
  return db.ok == true, db.reason
end

function M.mapFor(area)
  if M.usable() then return db.zones[area] end
end

function M.disable(reason)
  if M.usable() then db.ok, db.reason = false, reason end
end

local function onOff(on) return on and "on" or "off" end

function ns.questieDebugLines()
  local lines = {}
  if M.loaded() then
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, version = ns.try(meta, "Questie", "Version")
    local k = key()
    lines[#lines + 1] = "Questie: loaded (version " .. (ok and version and tostring(version) or "?") .. "), auto-accept "
      .. onOff(M.autoAccept()) .. ", auto-complete " .. onOff(M.autoComplete()) .. ", key " .. (k and k[1] or "none")
  else
    lines[#lines + 1] = "Questie: not loaded"
  end
  if ns.questViewerPlacement then lines[#lines + 1] = "Step window: " .. ns.questViewerPlacement() end
  local usable, reason = M.usable()
  if usable then
    local lib = _G.LibQuestieDB
    lines[#lines + 1] = "QuestieDB: contract " .. tostring(lib.contractVersion) .. " (" .. tostring(lib.readMode) .. "), "
      .. db.zoneCount .. " zone maps, arrow: " .. M.arrowState
  elseif reason == "not installed" then
    lines[#lines + 1] = "QuestieDB: not installed"
  else
    lines[#lines + 1] = "QuestieDB: off (" .. tostring(reason) .. ")"
  end
  return lines
end
