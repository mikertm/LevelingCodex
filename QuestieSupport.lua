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
  return lines
end
