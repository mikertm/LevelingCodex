-- Pace.lua: how fast you're levelling. Counted from login (so it works without saved settings):
-- XP per hour, the time to the next level at that pace, and where this level's XP came from
-- (quest turn-ins, kills, the rest), with quests, kills and deaths. Finished levels go to
-- charDB.paceLog when saved settings load, for the last few levels' times.
local _, ns = ...
local session = { xp = 0 }
local level = {}
local lastXP, lastMax, lastLevel
local pendingLevel -- a level-up the client's UnitLevel hasn't caught up with yet
local events
local KEEP = 60 -- finished levels kept in charDB.paceLog

local function try(...) return ns.quests.try(...) end

local function readXP()
  return tonumber(try(UnitXP, "player")), tonumber(try(UnitXPMax, "player"))
end

local function startLevel(lvl, partial)
  level = { level = lvl, started = GetTime(), xp = 0, quest = 0, mob = 0, quests = 0, kills = 0, deaths = 0,
    partial = partial }
end

-- Every XP change: the gain since the last reading, across a level-up.
local function onXP()
  local cur, max = readXP()
  local lvl = math.max(UnitLevel("player") or 1, pendingLevel or 0)
  if pendingLevel and (UnitLevel("player") or 1) >= pendingLevel then pendingLevel = nil end
  if cur and lastXP and lastLevel then
    local gained
    if lvl == lastLevel then
      gained = cur - lastXP
    elseif lvl == lastLevel + 1 and lastMax then
      gained = lastMax - lastXP + cur
    end
    if gained and gained > 0 then
      session.xp = session.xp + gained
      level.xp = level.xp + gained
    end
  end
  lastXP, lastMax, lastLevel = cur, max, lvl
end

local function finishLevel(newLevel)
  local db = ns.charDB()
  if type(db.paceLog) ~= "table" then db.paceLog = {} end
  table.insert(db.paceLog, { level = level.level, seconds = math.floor(GetTime() - level.started),
    quests = level.quests, kills = level.kills, deaths = level.deaths, partial = level.partial or nil })
  while #db.paceLog > KEEP do table.remove(db.paceLog, 1) end
  startLevel(newLevel, false)
end

local function duration(seconds)
  local minutes = math.floor((seconds or 0) / 60 + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return math.floor(minutes / 60) .. " h " .. (minutes % 60) .. " min"
end

local function plural(n, word) return n .. " " .. word .. (n == 1 and "" or "s") end

-- Rows { label, value } for the This Level tab's pace card.
function ns.paceRows()
  if not session.start then return {} end
  local rows = {}
  local hours = (GetTime() - session.start) / 3600
  if session.xp > 0 and hours > 0 then
    local rate = session.xp / hours
    rows[#rows + 1] = { "XP per hour", math.floor(rate + 0.5) .. " (this session)" }
    local cur, max = readXP()
    if cur and max and max > cur and rate > 0 then
      rows[#rows + 1] = { "Next level in", "about " .. duration((max - cur) / rate * 3600) .. " at this pace" }
    end
  end
  rows[#rows + 1] = { "Level " .. level.level .. " so far",
    duration(GetTime() - level.started) .. (level.partial and " since you logged in" or "") }
  rows[#rows + 1] = { "From quests", level.quest .. " XP, " .. plural(level.quests, "quest") }
  rows[#rows + 1] = { "From kills", level.mob .. " XP, " .. plural(level.kills, "kill") }
  local other = level.xp - level.quest - level.mob
  if other > 0 then rows[#rows + 1] = { "Other XP", tostring(other) } end
  if level.deaths > 0 then rows[#rows + 1] = { "Deaths", tostring(level.deaths) } end
  local log = ns.charDB().paceLog
  if type(log) == "table" then
    for i = #log, math.max(1, #log - 2), -1 do
      local r = log[i]
      if type(r) == "table" and r.level then
        rows[#rows + 1] = { "Level " .. r.level, duration(r.seconds) .. (r.partial and " (part)" or "") .. ", "
          .. plural(r.quests or 0, "quest") .. ", " .. plural(r.kills or 0, "kill")
          .. ((r.deaths or 0) > 0 and (", " .. plural(r.deaths, "death")) or "") }
      end
    end
  end
  return rows
end

function ns.startPace()
  if events then return end
  session.start = GetTime()
  startLevel(UnitLevel("player") or 1, true)
  onXP()
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "QUEST_TURNED_IN", "CHAT_MSG_COMBAT_XP_GAIN", "PLAYER_DEAD" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, a, b)
    if event == "PLAYER_XP_UPDATE" then
      onXP()
    elseif event == "PLAYER_LEVEL_UP" then
      local new = tonumber(a) or ((UnitLevel("player") or 1) + 1)
      pendingLevel = new
      finishLevel(new)
    elseif event == "QUEST_TURNED_IN" then
      level.quests = level.quests + 1
      level.quest = level.quest + (tonumber(b) or 0)
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
      if type(a) == "string" and a:find("dies", 1, true) then
        local digits = a:match("(%d[%d,%.]*) experience")
        local n = digits and tonumber((digits:gsub("[,%.]", "")))
        if n then level.mob, level.kills = level.mob + n, level.kills + 1 end
      end
    elseif event == "PLAYER_DEAD" then
      level.deaths = level.deaths + 1
    end
  end)
end
