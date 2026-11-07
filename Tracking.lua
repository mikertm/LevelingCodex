-- Tracking.lua: keeps Find Herbs / Find Minerals on.
-- WoW: Forever drops gathering tracking (login, reload, loading screens, dying), so the Codex turns
-- the one you had back on. It never overrides another tracking you picked (Track Beasts...), waits
-- while you're dead or in combat, and only runs for trackers your character knows.
-- Uses the minimap tracking list (C_Minimap, else the classic globals). A client without one only
-- gets a chat reminder. Off switch: Settings > Gathering (db.noAutoTrack).

local _, ns = ...

-- In the order they're turned on: on a one-at-a-time client the last one wins.
local KINDS = {
  { key = "herbs", spellID = 2383, name = "Find Herbs", icon = "inv_misc_flower_02", fileID = 133939 },
  { key = "minerals", spellID = 2580, name = "Find Minerals", icon = "spell_nature_earthquake", fileID = 136025 },
}

local lastAction = "none yet"
local wanted       -- { herbs = true, ... }: the gathering trackers last seen on (nil = all you know)
local knownCount   -- how many gathering trackers the list had last time (to notice a new one)
local pendingCombat, told, reminded
local gen = 0

local function trackingAPI()
  local M = C_Minimap
  if type(M) == "table" and M.GetNumTrackingTypes and M.GetTrackingInfo and M.SetTracking then
    return M.GetNumTrackingTypes, M.GetTrackingInfo, M.SetTracking, "C_Minimap"
  end
  if GetNumTrackingTypes and GetTrackingInfo and SetTracking then
    return GetNumTrackingTypes, GetTrackingInfo, SetTracking, "classic"
  end
end

local function spellName(id)
  local ok, n = ns.try(C_Spell and C_Spell.GetSpellName, id)
  if ok and n then return n end
  ok, n = ns.try(GetSpellInfo, id)
  if ok and n then return n end
end

local function kindOf(name, tex, spellID)
  for _, k in ipairs(KINDS) do
    if spellID and spellID == k.spellID then return k end
    if name and (name == k.name or name == spellName(k.spellID)) then return k end
    if type(tex) == "number" then
      if tex == k.fileID then return k end
      local ok, id = ns.try(GetFileIDFromPath, "Interface\\Icons\\" .. k.icon)
      if ok and id and id == tex then return k end
    elseif type(tex) == "string" and tex:lower():find(k.icon, 1, true) then
      return k
    end
  end
end

-- The tracking list: { index, name, active, spell (a spell, not a town service), kind }, or nil
-- when the client has no list. Copes with both return styles (values, or one info table).
local function scan()
  local num, get = trackingAPI()
  if not num then return nil end
  local ok, n = pcall(num)
  if not ok or type(n) ~= "number" then return nil end
  local list = {}
  for i = 1, n do
    local okI, a, b, c, d, _, f = pcall(get, i)
    if okI and a ~= nil then
      local name, tex, active, cat, spellID
      if type(a) == "table" then
        name, tex, active, cat, spellID = a.name, a.texture or a.textureFileID, a.active, a.type or a.category, a.spellID
      else
        name, tex, active, cat, spellID = a, b, c, d, f
      end
      list[#list + 1] = { index = i, name = name, active = active and true or false, spell = cat == "spell",
        kind = kindOf(name, tex, spellID) }
    end
  end
  return list
end

-- Gathering entries from a scan, in KINDS order.
local function gathering(list)
  local out = {}
  for _, k in ipairs(KINDS) do
    for _, e in ipairs(list) do
      if e.kind == k then out[#out + 1] = e; break end
    end
  end
  return out
end

-- Remember what's on (only a non-empty set: the client dropping it isn't the player's choice).
local function remember(list)
  local set, any = {}, false
  for _, e in ipairs(gathering(list)) do
    if e.active then set[e.kind.key] = true; any = true end
  end
  if not any then return end
  wanted = set
  if LevelingCodexCharDB then LevelingCodexCharDB.gatherTrack = set end
end

local function wantedSet()
  if wanted then return wanted end
  local saved = ns.charDB().gatherTrack
  if type(saved) == "table" and next(saved) then
    wanted = {}
    for k, v in pairs(saved) do if v then wanted[k] = true end end
    return wanted
  end
end

local function setTracking(index, on)
  local _, _, set = trackingAPI()
  if set then return pcall(set, index, on) end
end

local function isDead()
  local ok, dead = ns.try(UnitIsDeadOrGhost, "player")
  return ok and dead
end

-- No tracking list (vanilla-style client): addons can't switch tracking, so just remind once.
local function remind()
  if reminded then return end
  local ok, tex = ns.try(GetTrackingTexture)
  if not ok or tex then return end
  for _, k in ipairs(KINDS) do
    local okK, known = ns.try(IsSpellKnown, k.spellID)
    if okK and known then
      reminded = true
      lastAction = "reminded (no tracking API)"
      ns.say(k.name .. " is off. This client doesn't let addons turn tracking on, so cast it from your spellbook.")
      return
    end
  end
end

-- kick: tracking that looks on is toggled off and on (at login it can be on without showing).
local function restore(kick)
  if ns.db().noAutoTrack or isDead() then return end
  local list = scan()
  if not list then remind(); return end
  local mine = gathering(list)
  knownCount = #mine
  if #mine == 0 then return end
  for _, e in ipairs(list) do
    if e.spell and e.active and not e.kind then
      lastAction = "left alone: " .. tostring(e.name) .. " is on"
      return
    end
  end
  if InCombatLockdown and InCombatLockdown() then pendingCombat = true; return end
  local anyOn = false
  for _, e in ipairs(mine) do if e.active then anyOn = true end end
  if anyOn then
    if kick then
      for _, e in ipairs(mine) do
        if e.active then
          local idx = e.index
          setTracking(idx, false)
          ns.after(0.4, function() setTracking(idx, true) end)
        end
      end
      lastAction = "refreshed at login"
    end
    remember(list)
    return
  end
  local want = wantedSet()
  local any = false
  if want then
    for _, e in ipairs(mine) do if want[e.kind.key] then any = true end end
  end
  local names = {}
  for _, e in ipairs(mine) do
    if not any or want[e.kind.key] then
      if setTracking(e.index, true) then names[#names + 1] = e.kind.name end
    end
  end
  if #names == 0 then return end
  lastAction = "turned on " .. table.concat(names, ", ")
  if not told then
    told = true
    ns.say("turned " .. table.concat(names, " and ") .. " back on. (Settings > Gathering to stop this.)")
  end
end

-- Check a couple of times: right after a loading screen the list may not be ready.
local function soon(kick)
  gen = gen + 1
  local my = gen
  ns.after(2, function() if my == gen then restore(kick) end end)
  ns.after(6, function() if my == gen then restore(false) end end)
end

function ns.restoreTracking() restore(false) end

local events = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_ALIVE", "PLAYER_UNGHOST",
    "MINIMAP_UPDATE_TRACKING", "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED" }) do
  pcall(events.RegisterEvent, events, ev) -- unknown events throw in Forever
end
local seenWorld
events:SetScript("OnEvent", function(_, event, isLogin, isReload)
  if event == "PLAYER_ENTERING_WORLD" then
    local first = not seenWorld
    seenWorld = true
    soon(first or isLogin or isReload)
  elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    soon(false)
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingCombat then
      pendingCombat = nil
      ns.after(1, function() restore(false) end)
    end
  elseif event == "MINIMAP_UPDATE_TRACKING" then
    local list = scan()
    if list then remember(list) end
  elseif event == "LEARNED_SPELL_IN_TAB" or event == "SPELLS_CHANGED" then
    -- a new gathering tracker (you just learned Herbalism or Mining): turn it on
    if not seenWorld then return end
    local list = scan()
    if not list then return end
    local n = #gathering(list)
    if knownCount and n > knownCount then soon(false) end
    knownCount = n
  end
end)

-- For /codex debug.
function ns.trackingDebugLines()
  local _, _, _, how = trackingAPI()
  local list = scan()
  local parts = {}
  if list then
    for _, e in ipairs(gathering(list)) do parts[#parts + 1] = e.kind.name .. (e.active and " on" or " off") end
  end
  return { "gathering tracking: " .. (ns.db().noAutoTrack and "off in settings" or "on") ..
    ", api " .. (how or "none") .. (list and (" (" .. #list .. " types)") or "") ..
    ", found: " .. (#parts > 0 and table.concat(parts, ", ") or "none") .. ", last: " .. lastAction }
end
