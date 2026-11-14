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
local scope = "character" -- the tab's switch, this session: "session" or "character"
local SOURCE_COLORS = { { 0.88, 0.7, 0.29, 1 }, { 0.77, 0.33, 0.29, 1 }, { 0.36, 0.45, 0.46, 1 } }
local EARNED, SPENT, TRACK = { 0.88, 0.7, 0.29, 1 }, { 0.77, 0.33, 0.29, 1 }, { 0.05, 0.05, 0.08, 0.9 }

local function duration(seconds)
  local minutes = math.floor((tonumber(seconds) or 0) / 60 + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return math.floor(minutes / 60) .. " h " .. (minutes % 60) .. " min"
end

local function signed(copper)
  copper = tonumber(copper) or 0
  return (copper < 0 and "-" or "") .. ns.coins(math.abs(copper))
end

local function sum(t)
  local n = 0
  for _, v in pairs(type(t) == "table" and t or {}) do n = n + (tonumber(v) or 0) end
  return n
end

local function num(v) return tonumber(v) or 0 end
local function plural(n, word) return n .. " " .. word .. (n == 1 and "" or "s") end
-- XP that came neither from a turn-in nor a kill (a turn-in's XP can be filed before its XP update)
local function otherXP(l) return math.max(0, num(l.xp) - num(l.questXP) - num(l.killXP)) end

local function render()
  local U, C = ns.ui, ns.C
  local W = U.W
  local lost = ns.settingsLost
  local useSession = lost or scope == "session"
  local tree = (not useSession and saved()) or session
  local current = level()
  local y = U.sectionTitle("Stats", 0)
  if lost then
    y = y + U.T("Counting since you logged in: Forever didn't load your saved stats.", 0, y, W, "small", C.dim) + 8
  else
    U.segments(W - 260, 0, 260, { "This session", "This character" }, useSession and 1 or 2, function(i)
      scope = i == 1 and "session" or "character"
      U.refresh()
    end, { "Only what you did since you logged in.", "Everything saved for this character, every session." })
  end

  -- Tiles: { label, value, sub, colour }, `perRow` to a row, 58 px tall.
  local function tiles(list, perRow)
    local tw = math.floor((W - 8 * (perRow - 1)) / perRow)
    for i, t in ipairs(list) do
      local x, ty = ((i - 1) % perRow) * (tw + 8), y + math.floor((i - 1) / perRow) * 66
      U.box(x, ty, tw, 58, C.panel, C.edge)
      U.T(t[1], x + 10, ty + 8, tw - 20, "small", C.dim)
      U.T(t[2], x + 10, ty + 21, tw - 20, "head", t[4] or C.light)
      if t[3] then U.T(t[3], x + 10, ty + 41, tw - 20, "small", C.dim) end
    end
    y = y + math.ceil(#list / perRow) * 66 + 6
  end
  local function heading(text, x, w, right)
    U.T(text, (x or 0) + 14, y, (w or W) - 28, "label", C.gold)
    if right then U.T(right, (x or 0) + 14, y, (w or W) - 28, "small", C.light, "RIGHT") end
  end

  -- 1. Headline tiles
  local here = tree.levels[current]
  local rate = ns.paceRate and ns.paceRate()
  local cur, max = tonumber(try(UnitXP, "player")), tonumber(try(UnitXPMax, "player"))
  local toGo = cur and max and max > cur and max - cur
  local now = time and time() or 0
  local hours = math.max(1 / 60, (now - num(session.started or now)) / 3600)
  local perHour = math.floor((sum(session.totals.goldIn) - sum(session.totals.goldOut)) / hours + 0.5)
  tiles({
    { "Level " .. current .. " so far", duration(here and here.seconds), useSession and "this session" or "all sessions" },
    { "XP per hour", rate and ns.thousands(rate) or "-", "this session" },
    { "Next level in", rate and toGo and duration(toGo / rate * 3600) or "-",
      toGo and (ns.thousands(toGo) .. " XP to go") or nil },
    { "Gold per hour", signed(perHour), "net, this session" },
  }, 4)

  -- 2. Level splits: the last 10 levels (or all), newest first, as bars of quest, kill and other XP.
  local levels = {}
  for lvl, l in pairs(tree.levels) do if type(l) == "table" then levels[#levels + 1] = tonumber(lvl) end end
  table.sort(levels, function(a, b) return a > b end)
  local top = y
  y = y + 10
  heading("LEVEL SPLITS")
  for i, name in ipairs({ "Quests", "Kills", "Other" }) do
    local lx = W - 14 - (4 - i) * 70
    U.rect(lx, y + 3, 9, 9, SOURCE_COLORS[i])
    U.T(name, lx + 13, y, 56, "small", C.dim)
  end
  y = y + 22
  local shown, longest = {}, 1
  for i, lvl in ipairs(levels) do
    if i > 10 and not showAllLevels then break end
    shown[#shown + 1] = lvl
    longest = math.max(longest, num(tree.levels[lvl].seconds))
  end
  if #shown == 0 then y = y + U.T("No levels counted yet.", 14, y, W - 28, "small", C.dim) + 4 end
  local barX, barW = 74, W - 14 - 74 - 96
  for _, lvl in ipairs(shown) do
    local l = tree.levels[lvl]
    local seconds = num(l.seconds)
    U.T(lvl .. (lvl == current and " now" or ""), 14, y, 56, "small", lvl == current and C.gold or C.light)
    U.rect(barX, y + 2, barW, 10, TRACK)
    local len = barW * seconds / longest
    if seconds > 0 then len = math.max(2, len) end
    local parts = { num(l.questXP), num(l.killXP), otherXP(l) }
    local xpTotal = parts[1] + parts[2] + parts[3]
    local x = barX
    for p = 1, 3 do
      local w = xpTotal > 0 and len * parts[p] / xpTotal or (p == 3 and len or 0)
      if w >= 0.5 then U.rect(x, y + 2, w, 10, SOURCE_COLORS[p], nil, 1) end
      x = x + w
    end
    U.T(duration(seconds), W - 14 - 90, y, 90, "small", C.light, "RIGHT")
    local tip = duration(seconds) .. " on this level"
      .. "\nQuest XP " .. ns.thousands(l.questXP) .. ", kill XP " .. ns.thousands(l.killXP) .. ", other " .. ns.thousands(otherXP(l))
      .. "\n" .. plural(num(l.quests), "quest") .. ", " .. plural(num(l.kills), "kill") .. ", " .. plural(num(l.deaths), "death")
      .. "\nNet gold " .. signed(sum(l.goldIn) - sum(l.goldOut))
      .. (l.fromPct and ("\nCounted from " .. l.fromPct .. "%") or "")
    U.hit(10, y - 2, W - 20, 18, "Level " .. lvl, tip, nil, "Level " .. lvl)
    y = y + 18
  end
  y = y + 8
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 12
  if #levels > 10 then
    U.btn(showAllLevels and "Show the last 10 levels" or "Show all levels", 0, y - 6, 200, function()
      showAllLevels = not showAllLevels
      U.refresh()
    end, showAllLevels)
    y = y + 30
  end

  -- 3. Gold earned and spent, side by side: a bar per source that moved money.
  local colW = math.floor((W - 12) / 2)
  local function goldColumn(x, title, keys, totals, color, sign)
    local cy = y + 10
    local rows, total, largest = {}, 0, 0
    for _, key in ipairs(keys) do
      local c = num(totals[key])
      if c > 0 then rows[#rows + 1] = { key, c }; total = total + c; largest = math.max(largest, c) end
    end
    U.T(title, x + 14, cy, colW - 28, "label", C.gold)
    U.T(sign .. ns.coins(total), x + 14, cy, colW - 28, "small", C.light, "RIGHT")
    cy = cy + 22
    if #rows == 0 then cy = cy + U.T("Nothing yet.", x + 14, cy, colW - 28, "small", C.dim) + 4 end
    for _, r in ipairs(rows) do
      U.T(GOLD_NAMES[r[1]], x + 14, cy, colW - 28, "small", C.light)
      U.T(ns.coins(r[2]), x + 14, cy, colW - 28, "small", C.light, "RIGHT")
      cy = cy + 15
      U.rect(x + 14, cy, colW - 28, 4, TRACK)
      local bw = (colW - 28) * r[2] / largest
      if bw >= 1 then U.rect(x + 14, cy, bw, 4, color, nil, 1) end
      cy = cy + 10
    end
    return cy + 6
  end
  local leftEnd = goldColumn(0, "GOLD EARNED", S.GOLD_IN, tree.totals.goldIn or {}, EARNED, "+")
  local rightEnd = goldColumn(colW + 12, "GOLD SPENT", S.GOLD_OUT, tree.totals.goldOut or {}, SPENT, "-")
  local bottom = math.max(leftEnd, rightEnd)
  U.box(0, y, colW, bottom - y, C.panel, C.edge)
  U.box(colW + 12, y, colW, bottom - y, C.panel, C.edge)
  y = bottom + 12

  -- 4. Activity tiles.
  local t = tree.totals
  local played = tree.played and tree.played.total
  U.T("ACTIVITY", 0, y, W, "label", C.gold)
  y = y + 20
  tiles({
    { "Quests", ns.thousands(t.quests), "turned in" }, { "Kills", ns.thousands(t.kills) },
    { "Deaths", ns.thousands(t.deaths) }, { "Flights", ns.thousands(t.flights), duration(t.flightSeconds) .. " in the air" },
    { "Hearthstone", ns.thousands(t.hearths), "uses" }, { "Dungeon runs", ns.thousands(t.dungeons) },
    { "Bosses", ns.thousands(t.bosses), "killed" },
    { "Played", played and duration(played) or "-", played and "at your last /played" or "type /played" },
  }, 4)

  -- 5. Zones by time, as bars against the longest.
  local zones = {}
  for _, z in pairs(tree.zones) do if type(z) == "table" then zones[#zones + 1] = z end end
  table.sort(zones, function(a, b) return num(a.seconds) > num(b.seconds) end)
  top = y
  y = y + 10
  heading("ZONES")
  y = y + 22
  if #zones == 0 then y = y + U.T("No zone time yet.", 14, y, W - 28, "small", C.dim) + 4 end
  local most = math.max(1, zones[1] and num(zones[1].seconds) or 1)
  local zx, zw = 190, W - 14 - 190 - 150
  for i, z in ipairs(zones) do
    if i > 8 and not showAllZones then break end
    U.T(Q.plain(z.name or "?"), 14, y, 170, "small", C.light)
    U.rect(zx, y + 3, zw, 8, TRACK)
    local bw = zw * num(z.seconds) / most
    if bw >= 1 then U.rect(zx, y + 3, bw, 8, C.accent, nil, 1) end
    U.T(duration(z.seconds) .. ", " .. plural(num(z.quests), "quest"), W - 14 - 146, y, 146, "small", C.light, "RIGHT")
    y = y + 18
  end
  y = y + 8
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 12
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
