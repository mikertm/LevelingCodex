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

local function level() return tonumber(UnitLevel("player")) or 1 end
local levelUp -- the last PLAYER_LEVEL_UP: { to, at }

-- A level's record, made when first needed. One made while you're already into your current
-- level (not just reached by levelling up) keeps fromPct: where counting began, in whole percent.
local function levelOf(tree, lvl)
  local l = tree.levels[lvl]
  if type(l) ~= "table" then
    l = { seconds = 0, xp = 0, questXP = 0, killXP = 0, rested = 0, quests = 0, kills = 0, deaths = 0,
      goldIn = goldTable(S.GOLD_IN), goldOut = goldTable(S.GOLD_OUT) }
    if lvl == level() and not (levelUp and levelUp.to == lvl) then
      local cur, max = tonumber(try(UnitXP, "player")), tonumber(try(UnitXPMax, "player"))
      local pct = cur and max and max > 0 and math.floor(cur / max * 100) or 0
      if pct > 2 then l.fromPct = pct end
    end
    tree.levels[lvl] = l
  end
  return l
end

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

-- A level's record (the saved one; this session's when saved settings didn't load), never made here.
function S.levelRecord(lvl)
  local tree = ns.settingsLost and session or saved() or session
  local l = tree.levels[lvl]
  return type(l) == "table" and l or nil
end

-- Up to n records of the levels below lvl, newest first: { { level, record }, ... }.
function S.earlierLevels(lvl, n)
  local out = {}
  for l = lvl - 1, 1, -1 do
    if #out >= n then break end
    local r = S.levelRecord(l)
    if r then out[#out + 1] = { level = l, record = r } end
  end
  return out
end

function S.reset()
  session = fresh()
  if type(LevelingCodexCharDB) == "table" then LevelingCodexCharDB.stats = fresh() end
end

----------------------------------------------------------------------------
-- Money
----------------------------------------------------------------------------

local lastMoney, merchantOpen, trainerOpen, lootUntil, repairCost
-- A turn-in's money reward waiting for its money, with the level you turned it in at (a turn-in
-- that levels you up still belongs to the level it finished).
local pendingQuest = { copper = 0, at = 0 }
local lastOther = { copper = 0, at = 0 } -- the last gain filed as other (a reward that came first)

local function addGold(dir, key, amount, lvl)
  if amount <= 0 then return end
  lvl = lvl or level()
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
  local function file(dir, key, amount, lvl)
    amount = math.min(amount, rest)
    if amount > 0 then addGold(dir, key, amount, lvl); rest = rest - amount end
    return amount
  end
  if delta > 0 then
    if now - pendingQuest.at <= EXPIRE then
      pendingQuest.copper = pendingQuest.copper - file("goldIn", "quest", pendingQuest.copper, pendingQuest.level)
    end
    if lootUntil and now <= lootUntil then file("goldIn", "loot", rest) end
    file("goldIn", "junk", take("junk", rest))
    if merchantOpen then file("goldIn", "sales", rest) end
    local other = file("goldIn", "other", rest)
    if other > 0 then lastOther.copper, lastOther.at, lastOther.level = other, now, level() end
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

-- The level a turn-in finished: yours, or the one before when its own XP just levelled you up (the
-- level-up came within a second and you have no more XP into the new level than it gave).
local function turnInLevel(xp)
  local lvl = level()
  if levelUp and levelUp.to == lvl and GetTime() - levelUp.at <= 1 then
    local into, gained = tonumber(try(UnitXP, "player")), tonumber(xp)
    if into and gained and gained > 0 and into <= gained then return lvl - 1 end
  end
  return lvl
end

-- A turn-in's money reward: filed when its money arrives, or moved from "other" when it came first.
local function questMoney(copper, xp)
  copper = tonumber(copper) or 0
  if copper <= 0 then return end
  local now = GetTime()
  local early = now - lastOther.at <= 2 and math.min(copper, lastOther.copper) or 0
  if early > 0 then
    local lvl = lastOther.level or level() -- where that gain was filed, even across a level-up
    each(function(t)
      local l = levelOf(t, lvl)
      l.goldIn.other, l.goldIn.quest = l.goldIn.other - early, l.goldIn.quest + early
      t.totals.goldIn.other = (t.totals.goldIn.other or 0) - early
      t.totals.goldIn.quest = (t.totals.goldIn.quest or 0) + early
    end)
    lastOther.copper = lastOther.copper - early
  end
  pendingQuest.copper, pendingQuest.at, pendingQuest.level = copper - early, now, turnInLevel(xp)
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
  QUEST_TURNED_IN = function(_, xp, money) questMoney(money, xp) end,
  PLAYER_LEVEL_UP = function(newLevel)
    levelUp = { to = tonumber(newLevel) or level(), at = GetTime() }
  end,
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
  for event in pairs(HANDLERS) do
    -- spell casts: yours only, not every unit's around you (RegisterEvent where the client lacks it)
    local unitOnly = event == "UNIT_SPELLCAST_SUCCEEDED" and type(events.RegisterUnitEvent) == "function"
      and pcall(events.RegisterUnitEvent, events, event, "player")
    if not unitOnly then pcall(events.RegisterEvent, events, event) end
  end
  events:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(HANDLERS[event], ...)
    if not ok and not S.errored then
      S.errored = true
      ns.say("stats error: " .. Q.plain(err))
    end
  end)
  ns.every(1, tick)
end

----------------------------------------------------------------------------
-- The Stats tab
----------------------------------------------------------------------------

local GOLD_NAMES = { quest = "Quest rewards", loot = "Looted", junk = "Junk sold by the Codex", sales = "Other vendor sales",
  other = "Other", repair = "Repairs", training = "Training", flights = "Flights", buys = "Vendor purchases" }
local showAllLevels, showAllZones = false, false
local confirmReset, confirmAt

local function duration(seconds)
  local minutes = math.floor((tonumber(seconds) or 0) / 60 + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return math.floor(minutes / 60) .. " h " .. (minutes % 60) .. " min"
end

local function signed(copper)
  copper = tonumber(copper) or 0
  return (copper < 0 and "-" or "") .. ns.money(math.abs(copper))
end

local function sum(t)
  local n = 0
  for _, v in pairs(type(t) == "table" and t or {}) do n = n + (tonumber(v) or 0) end
  return n
end

local function totalsOf(tree)
  local xp, seconds = 0, 0
  for _, l in pairs(tree.levels) do
    if type(l) == "table" then xp, seconds = xp + (tonumber(l.xp) or 0), seconds + (tonumber(l.seconds) or 0) end
  end
  return xp, seconds
end

local function render()
  local U, C = ns.ui, ns.C
  local W = U.W
  local lost = ns.settingsLost
  local tree = (not lost and saved()) or session
  local y = U.sectionTitle("Stats", 0, lost and "counting since you logged in" or "this session and all saved")

  -- A parchment card: its heading, then { label, value } rows (a row with `cols` is a table row).
  local function card(title, rows, note)
    local top = y
    y = y + 10
    y = y + U.T(title, 14, y, W - 28, "label", C.inkSoft) + 6
    if note then y = y + U.T(note, 14, y, W - 28, "small", C.ink) + 6 end
    for _, row in ipairs(rows) do
      if row.cols then
        local x, h = 14, 0
        for i, text in ipairs(row.cols) do
          local w = row.widths[i]
          h = math.max(h, (U.T(text, x, y, w, row.head and "label" or "small", row.head and C.inkSoft or C.ink,
            i == 1 and "LEFT" or "RIGHT")))
          x = x + w
        end
        y = y + h + 3
      else
        U.T(row[1], 14, y, W * 0.55, "body", C.ink)
        y = y + U.T(row[2], W * 0.55, y, W * 0.45 - 14, "body", C.ink, "RIGHT") + 4
      end
    end
    y = y + 8
    U.box(0, top, W, y - top, C.parch, C.edge)
    y = y + 12
  end

  -- 1. This session
  local now = time and time() or 0
  local hours = math.max(1 / 60, (now - (tonumber(session.started) or now)) / 3600)
  local xp = totalsOf(session)
  local net = sum(session.totals.goldIn) - sum(session.totals.goldOut)
  card("THIS SESSION", {
    { "Time", duration(hours * 3600) },
    { "XP per hour", tostring(math.floor(xp / hours + 0.5)) },
    { "Gold per hour", signed(math.floor(net / hours + 0.5)) },
    { "Quests turned in", tostring(session.totals.quests or 0) },
    { "Kills", tostring(session.totals.kills or 0) },
    { "Deaths", tostring(session.totals.deaths or 0) },
  }, lost and "Counting since you logged in: Forever didn't load your saved stats." or nil)

  -- 2. Level splits: the last 10 levels (or all), newest first.
  local levels = {}
  for lvl, l in pairs(tree.levels) do if type(l) == "table" then levels[#levels + 1] = tonumber(lvl) end end
  table.sort(levels, function(a, b) return a > b end)
  local widths = { 0.16 * (W - 28), 0.2 * (W - 28), 0.2 * (W - 28), 0.14 * (W - 28), 0.12 * (W - 28), 0.18 * (W - 28) }
  local rows = { { head = true, widths = widths, cols = { "LEVEL", "TIME", "QUEST XP", "KILLS", "DEATHS", "NET GOLD" } } }
  local current = level()
  for i, lvl in ipairs(levels) do
    if i > 10 and not showAllLevels then break end
    local l = tree.levels[lvl]
    local share = (tonumber(l.xp) or 0) > 0 and math.floor((tonumber(l.questXP) or 0) * 100 / l.xp + 0.5) .. "%" or "-"
    rows[#rows + 1] = { widths = widths, cols = { lvl .. (lvl == current and " (now)" or ""), duration(l.seconds), share,
      tostring(l.kills or 0), tostring(l.deaths or 0), signed(sum(l.goldIn) - sum(l.goldOut)) } }
  end
  if tree.played and tree.played.total then
    rows[#rows + 1] = { "Played (from your last /played)", duration(tree.played.total) }
  end
  card("LEVEL SPLITS", rows)
  if #levels > 10 then
    U.btn(showAllLevels and "Show the last 10 levels" or "Show all levels", 0, y - 6, 200, function()
      showAllLevels = not showAllLevels
      U.refresh()
    end, showAllLevels)
    y = y + 30
  end

  -- 3. Gold by source.
  local gold = {}
  for _, key in ipairs(S.GOLD_IN) do
    gold[#gold + 1] = { "+ " .. GOLD_NAMES[key], ns.money(session.totals.goldIn[key] or 0) .. " / "
      .. ns.money(tree.totals.goldIn[key] or 0) }
  end
  for _, key in ipairs(S.GOLD_OUT) do
    gold[#gold + 1] = { "- " .. GOLD_NAMES[key], ns.money(session.totals.goldOut[key] or 0) .. " / "
      .. ns.money(tree.totals.goldOut[key] or 0) }
  end
  local here = tree.levels[current]
  gold[#gold + 1] = { "Net this level", here and signed(sum(here.goldIn) - sum(here.goldOut)) or "0c" }
  card("GOLD", gold, "This session / all saved.")

  -- 4. Activity.
  local t = tree.totals
  card("ACTIVITY", {
    { "Quests turned in", tostring(t.quests or 0) }, { "Kills", tostring(t.kills or 0) },
    { "Deaths", tostring(t.deaths or 0) }, { "Flights", tostring(t.flights or 0) },
    { "Time in the air", duration(t.flightSeconds) }, { "Hearthstone uses", tostring(t.hearths or 0) },
    { "Dungeon runs", tostring(t.dungeons or 0) }, { "Bosses killed", tostring(t.bosses or 0) },
  })

  -- 5. Zones by time.
  local zones = {}
  for id, z in pairs(tree.zones) do if type(z) == "table" then zones[#zones + 1] = z end end
  table.sort(zones, function(a, b) return (a.seconds or 0) > (b.seconds or 0) end)
  local zw = { 0.46 * (W - 28), 0.2 * (W - 28), 0.2 * (W - 28), 0.14 * (W - 28) }
  local zoneRows = { { head = true, widths = zw, cols = { "ZONE", "TIME", "XP", "QUESTS" } } }
  for i, z in ipairs(zones) do
    if i > 8 and not showAllZones then break end
    zoneRows[#zoneRows + 1] = { widths = zw, cols = { Q.plain(z.name or "?"), duration(z.seconds), tostring(z.xp or 0),
      tostring(z.quests or 0) } }
  end
  card("ZONES", zoneRows, #zones == 0 and "No zone time yet." or nil)
  if #zones > 8 then
    U.btn(showAllZones and "Show the top 8 zones" or "Show all zones", 0, y - 6, 200, function()
      showAllZones = not showAllZones
      U.refresh()
    end, showAllZones)
    y = y + 30
  end

  -- 6. Reset, two clicks within 5 s.
  local armed = confirmReset and GetTime() - (confirmAt or 0) < 5
  U.btn(armed and "Click again to reset" or "Reset stats", 0, y, 200, function()
    if confirmReset and GetTime() - (confirmAt or 0) < 5 then
      confirmReset = nil
      S.reset()
      ns.say("stats reset.")
    else
      confirmReset, confirmAt = true, GetTime()
    end
    U.refresh()
  end, armed, "Clears this session's and the saved stats. Click twice to confirm.")
  return y + 40
end

ns.addTab("stats", "Stats", render)
