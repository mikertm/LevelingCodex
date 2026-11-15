-- Pace.lua: this session's XP rate (ns.paceRate, counted from login so it works without saved
-- settings) and the XP events Stats.lua files per level: every gain (across a level-up via the last
-- max), quest turn-ins' XP and kills, read from the client's own kill line.
local _, ns = ...
local session = { xp = 0 }
local lastXP, lastMax, lastLevel
local pendingLevel -- a level-up the client's UnitLevel hasn't caught up with yet
local events
local killPattern -- built from the client's own kill line at the first XP line
local lastLine -- the last CHAT_MSG_COMBAT_XP_GAIN: { text, n = kill XP or nil }

local function try(...) return ns.quests.try(...) end

local function readXP()
  return tonumber(try(UnitXP, "player")), tonumber(try(UnitXPMax, "player"))
end

-- The kill line in the client's own words (COMBATLOG_XPGAIN_FIRSTPERSON, e.g. "%s dies, you gain
-- %d experience."): its name and number become captures, not anchored at the end, so rested and
-- group bonus text after it still matches. The client's grammar codes (|1a;b; picks a particle,
-- |4one:many; a plural) match whatever it printed; a format that puts the number first (%2$d before
-- %1$s) is read in that order. Without that string, the English line.
local numberFirst -- the kill pattern's number capture comes before the name's
local function buildKillPattern()
  local fmt = COMBATLOG_XPGAIN_FIRSTPERSON
  if type(fmt) ~= "string" or not fmt:find("%", 1, true) then
    return "(.+) dies, you gain ([%d,%.]+) experience", false
  end
  local p = fmt:gsub("|1[^;]*;[^;]*;", "\3"):gsub("|4[^;]*;", "\3")
  p = p:gsub("%%%d+%$s", "\1"):gsub("%%s", "\1"):gsub("%%%d+%$d", "\2"):gsub("%%d", "\2")
  local name, number = p:find("\1", 1, true), p:find("\2", 1, true)
  p = p:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
  p = p:gsub("\1", "(.+)"):gsub("\2", "([%%d,%%.]+)"):gsub("\3", ".-")
  return p, (name and number and number < name) and true or false
end

-- The XP a kill line gives, or nil when the line isn't a kill.
local function killXP(text)
  if not killPattern then killPattern, numberFirst = buildKillPattern() end
  local a, b = text:match(killPattern)
  local digits = numberFirst and a or b
  return digits and tonumber((digits:gsub("[,%.]", ""))) or nil
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
      if ns.stats then ns.stats.xp("total", gained) end
    end
  end
  lastXP, lastMax, lastLevel = cur, max, lvl
end

-- XP per hour this session, nil before any gain.
function ns.paceRate()
  if not session.start or session.xp <= 0 then return end
  local hours = (GetTime() - session.start) / 3600
  if hours > 0 then return session.xp / hours end
end

-- /codex debug: the last XP line and what it counted.
function ns.paceDebugLines()
  if not lastLine then return { "pace: no XP line yet" } end
  return { 'pace: last XP line "' .. ns.plain(lastLine.text) .. '" -> '
    .. (lastLine.n and ("kill " .. lastLine.n .. " XP") or "not counted") }
end

function ns.startPace()
  if events then return end
  session.start = GetTime()
  onXP()
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "QUEST_TURNED_IN", "CHAT_MSG_COMBAT_XP_GAIN" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, a, b)
    if event == "PLAYER_XP_UPDATE" then
      onXP()
    elseif event == "PLAYER_LEVEL_UP" then
      pendingLevel = tonumber(a) or ((UnitLevel("player") or 1) + 1)
    elseif event == "QUEST_TURNED_IN" then
      if ns.stats then ns.stats.xp("quest", tonumber(b) or 0); ns.stats.count("quests") end
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
      if type(a) == "string" then
        local n = killXP(a)
        lastLine = { text = a, n = n }
        if n and ns.stats then ns.stats.xp("kill", n); ns.stats.count("kills") end
      end
    end
  end)
end
