-- Stats.lua: leveling statistics for the Stats tab. Every counter goes to this session and to your
-- character's saved stats (LevelingCodexCharDB.stats, version 1; a missing or broken table starts
-- fresh), so the tab works whether or not Forever loads saved data back.
--   levels[lvl] = { seconds, xp, questXP, killXP, rested, quests, kills, deaths, goldIn, goldOut }
--   zones[mapID] = { name, seconds, xp, quests } (a subzone map rolls up to its zone)
--   totals = { quests, kills, deaths, flights, flightSeconds, hearths, dungeons, bosses, goldIn, goldOut }
--   played = { total, level, at } from the last /played (the Codex never asks for it: that prints)
-- XP comes from Pace.lua (quest, kill and total gains); money changes are filed by where they
-- happened: a quest's reward, looting, the Codex's own junk sales and repairs, a vendor, a trainer,
-- a flight just taken, or other.
local _, ns = ...
local Q = ns.quests
local function try(...) return Q.try(...) end

local S = {}
ns.stats = S

S.GOLD_IN = { "quest", "loot", "junk", "sales", "other" }
S.GOLD_OUT = { "repair", "training", "flights", "buys", "other" }
local COUNTED = { "quests", "kills", "deaths", "flights", "hearths", "dungeons", "bosses" }
local PER_LEVEL = { quests = true, kills = true, deaths = true }
local HEARTHSTONE_SPELL = 8690
local EXPIRE = 5 -- seconds an announced amount (S.expect) waits for its money
local LOOT_GRACE = 1 -- autoloot can close the window before the money arrives

local function goldTable(keys)
  local t = {}
  for _, k in ipairs(keys) do t[k] = 0 end
  return t
end

local function fresh()
  local totals = { flightSeconds = 0, goldIn = goldTable(S.GOLD_IN), goldOut = goldTable(S.GOLD_OUT) }
  for _, k in ipairs(COUNTED) do totals[k] = 0 end
  return { version = 1, started = time and time() or 0, levels = {}, zones = {}, totals = totals }
end

local session = fresh()

-- The saved tree, made fresh when it's missing or of another shape (nil when no character table).
local function saved()
  local db = LevelingCodexCharDB
  if type(db) ~= "table" then return end
  local st = db.stats
  if type(st) ~= "table" or st.version ~= 1 or type(st.levels) ~= "table" or type(st.zones) ~= "table"
      or type(st.totals) ~= "table" then
    st = fresh()
    db.stats = st
  end
  return st
end

local function each(fn)
  fn(session)
  local st = saved()
  if st then fn(st) end
end

local function levelOf(tree, lvl)
  local l = tree.levels[lvl]
  if type(l) ~= "table" then
    l = { seconds = 0, xp = 0, questXP = 0, killXP = 0, rested = 0, quests = 0, kills = 0, deaths = 0,
      goldIn = goldTable(S.GOLD_IN), goldOut = goldTable(S.GOLD_OUT) }
    tree.levels[lvl] = l
  end
  return l
end

local function level() return tonumber(UnitLevel("player")) or 1 end

-- The zone-level map of a map: up through parents while the map is smaller than a zone.
local zoneCache = {}
local function zoneOf(map)
  if type(map) ~= "number" then return end
  local hit = zoneCache[map]
  if hit then return hit[1], hit[2] end
  local id = map
  local info = try(C_Map and C_Map.GetMapInfo, id)
  while type(info) == "table" and tonumber(info.mapType) and info.mapType > 3 and info.parentMapID do
    local parent = try(C_Map.GetMapInfo, info.parentMapID)
    if type(parent) ~= "table" then break end
    id, info = info.parentMapID, parent
  end
  local name = type(info) == "table" and type(info.name) == "string" and info.name or ("Map " .. id)
  zoneCache[map] = { id, name }
  return id, name
end

local function zoneRec(tree, id, name)
  local z = tree.zones[id]
  if type(z) ~= "table" then
    z = { seconds = 0, xp = 0, quests = 0 }
    tree.zones[id] = z
  end
  z.name = name
  return z
end

local function hereZone()
  local map = Q.position()
  return zoneOf(map)
end

----------------------------------------------------------------------------
-- What other modules report
----------------------------------------------------------------------------

local lastRested
-- kind: "total" (every gain), "quest" (a turn-in's reward), "kill" (a creature's XP).
function S.xp(kind, amount)
  amount = tonumber(amount) or 0
  if amount <= 0 then return end
  local lvl = level()
  local field = kind == "quest" and "questXP" or kind == "kill" and "killXP" or "xp"
  local used = 0
  if field == "xp" then
    local rested = tonumber(try(GetXPExhaustion))
    if rested and lastRested and rested < lastRested then used = lastRested - rested end
    lastRested = rested
  end
  local zone, name = hereZone()
  each(function(t)
    local l = levelOf(t, lvl)
    l[field] = l[field] + amount
    l.rested = l.rested + used
    if field == "xp" and zone then local z = zoneRec(t, zone, name); z.xp = z.xp + amount end
  end)
end

local lastFlightAt
-- name: quests, kills, deaths, flights, hearths, dungeons, bosses.
function S.count(name, n)
  n = n or 1
  if name == "flights" then lastFlightAt = GetTime() end
  local lvl = level()
  local zone, zoneName
  if name == "quests" then zone, zoneName = hereZone() end
  each(function(t)
    t.totals[name] = (tonumber(t.totals[name]) or 0) + n
    if PER_LEVEL[name] then local l = levelOf(t, lvl); l[name] = l[name] + n end
    if zone then local z = zoneRec(t, zone, zoneName); z.quests = z.quests + n end
  end)
end

function S.flightTime(seconds)
  seconds = tonumber(seconds) or 0
  if seconds <= 0 then return end
  each(function(t) t.totals.flightSeconds = (tonumber(t.totals.flightSeconds) or 0) + seconds end)
end

-- The Codex is about to move this much money for `source` (junk, repair, buys): the next money
-- change of that size is filed under it.
local expects = {}
function S.expect(source, copper)
  copper = tonumber(copper) or 0
  if copper > 0 then expects[#expects + 1] = { source = source, copper = copper, at = GetTime() } end
end

local function take(source, want)
  local got, now = 0, GetTime()
  for i = #expects, 1, -1 do
    local e = expects[i]
    if now - e.at > EXPIRE then
      table.remove(expects, i)
    elseif e.source == source and got < want then
      local use = math.min(e.copper, want - got)
      e.copper, got = e.copper - use, got + use
      if e.copper <= 0 then table.remove(expects, i) end
    end
  end
  return got
end

function S.data() return session, saved() end

function S.reset()
  session = fresh()
  if type(LevelingCodexCharDB) == "table" then LevelingCodexCharDB.stats = fresh() end
end

----------------------------------------------------------------------------
-- Money
----------------------------------------------------------------------------

local lastMoney, merchantOpen, trainerOpen, lootUntil, repairCost
local pendingQuest = { copper = 0, at = 0 } -- a turn-in's money reward, waiting for its money
local lastOther = { copper = 0, at = 0 } -- the last gain filed as other (a reward that came first)

local function addGold(dir, key, amount)
  if amount <= 0 then return end
  local lvl = level()
  each(function(t)
    local l = levelOf(t, lvl)
    l[dir][key] = (l[dir][key] or 0) + amount
    t.totals[dir][key] = (tonumber(t.totals[dir][key]) or 0) + amount
  end)
end

local function moneyChanged()
  local money = tonumber(try(GetMoney))
  if not money then return end
  local delta = lastMoney and money - lastMoney or 0
  lastMoney = money
  if delta == 0 then return end
  local now = GetTime()
  local rest = math.abs(delta)
  local function file(dir, key, amount)
    amount = math.min(amount, rest)
    if amount > 0 then addGold(dir, key, amount); rest = rest - amount end
    return amount
  end
  if delta > 0 then
    if now - pendingQuest.at <= EXPIRE then pendingQuest.copper = pendingQuest.copper - file("goldIn", "quest", pendingQuest.copper) end
    if lootUntil and now <= lootUntil then file("goldIn", "loot", rest) end
    file("goldIn", "junk", take("junk", rest))
    if merchantOpen then file("goldIn", "sales", rest) end
    local other = file("goldIn", "other", rest)
    if other > 0 then lastOther.copper, lastOther.at = other, now end
  else
    file("goldOut", "repair", take("repair", rest))
    if merchantOpen and repairCost then
      -- a repair the player clicked: the vendor's repair cost dropped
      local cost = tonumber((try(GetRepairAllCost))) or repairCost
      if cost < repairCost then file("goldOut", "repair", repairCost - cost) end
      repairCost = cost
    end
    file("goldOut", "buys", take("buys", rest))
    if merchantOpen then file("goldOut", "buys", rest) end
    if trainerOpen then file("goldOut", "training", rest) end
    if lastFlightAt and now - lastFlightAt <= EXPIRE then file("goldOut", "flights", rest) end
    file("goldOut", "other", rest)
  end
end

-- A turn-in's money reward: filed when its money arrives, or moved from "other" when it came first.
local function questMoney(copper)
  copper = tonumber(copper) or 0
  if copper <= 0 then return end
  local now = GetTime()
  local early = now - lastOther.at <= 2 and math.min(copper, lastOther.copper) or 0
  if early > 0 then
    local lvl = level()
    each(function(t)
      local l = levelOf(t, lvl)
      l.goldIn.other, l.goldIn.quest = l.goldIn.other - early, l.goldIn.quest + early
      t.totals.goldIn.other = (t.totals.goldIn.other or 0) - early
      t.totals.goldIn.quest = (t.totals.goldIn.quest or 0) + early
    end)
    lastOther.copper = lastOther.copper - early
  end
  pendingQuest.copper, pendingQuest.at = copper - early, now
end

----------------------------------------------------------------------------
-- Events and the clock
----------------------------------------------------------------------------

local events
local function tick()
  local lvl = level()
  local dead = try(UnitIsDeadOrGhost, "player")
  local zone, name
  if not Q.inFlight() and dead ~= true and dead ~= 1 then zone, name = hereZone() end
  each(function(t)
    local l = levelOf(t, lvl)
    l.seconds = l.seconds + 1
    if zone then local z = zoneRec(t, zone, name); z.seconds = z.seconds + 1 end
  end)
end

local HANDLERS = {
  PLAYER_MONEY = moneyChanged,
  QUEST_TURNED_IN = function(_, _, money) questMoney(money) end,
  LOOT_OPENED = function() lootUntil = math.huge end,
  LOOT_CLOSED = function() lootUntil = GetTime() + LOOT_GRACE end,
  MERCHANT_SHOW = function()
    merchantOpen = true
    repairCost = tonumber((try(GetRepairAllCost)))
  end,
  MERCHANT_CLOSED = function() merchantOpen, repairCost = false, nil end,
  TRAINER_SHOW = function() trainerOpen = true end,
  TRAINER_CLOSED = function() trainerOpen = false end,
  PLAYER_DEAD = function() S.count("deaths") end,
  TIME_PLAYED_MSG = function(total, thisLevel)
    total, thisLevel = tonumber(total), tonumber(thisLevel)
    if not total then return end
    each(function(t) t.played = { total = total, level = thisLevel, at = time and time() or 0 } end)
  end,
  UNIT_SPELLCAST_SUCCEEDED = function(unit, _, spell)
    if unit == "player" and tonumber(spell) == HEARTHSTONE_SPELL then S.count("hearths") end
  end,
}

function ns.startStats()
  if events then return end
  saved()
  lastMoney = tonumber(try(GetMoney))
  lastRested = tonumber(try(GetXPExhaustion))
  events = CreateFrame("Frame")
  for event in pairs(HANDLERS) do pcall(events.RegisterEvent, events, event) end
  events:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(HANDLERS[event], ...)
    if not ok and not S.errored then
      S.errored = true
      ns.say("stats error: " .. Q.plain(err))
    end
  end)
  ns.every(1, tick)
end
