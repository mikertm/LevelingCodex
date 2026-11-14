-- QuestParty.lua: playing the guide in a party. Nothing here runs in a raid.
-- Party sync: party members running the Codex tell each other their current step and its live goal
-- (addon messages), and the step window lists every party member against your step (Settings > Show
-- my party's steps). Opt-in helpers: share a guide quest with the party when you accept it, say in
-- party chat where you are flying, and Questie-like party chat lines for the steps you finish, the
-- quest items you pick up and your quest progress.
local _, ns = ...
local Q = ns.quests
local try = Q.try
local PREFIX = "LevCodex"
local members = {}  -- name -> { section, pos, label, goal, at }
local sent          -- the last step and goal we told the party about
local sentAt, retrying = 0, false
local events

local function inParty()
  local group = try(IsInGroup)
  local raid = try(IsInRaid)
  return (group == true or group == 1) and not (raid == true or raid == 1)
end

local function send(text)
  local api = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
  if type(api) == "function" then try(api, PREFIX, text, "PARTY") end
end

-- A number the client may hide from addon code (a secret value) reads as nil.
local function number(v)
  if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
  return tonumber(v)
end

-- Your step's live goal for the party: the first open objective ("Kobold Vermin slain: 3/10"),
-- "ready to turn in" once its quest is, else nothing.
local function myGoal(row)
  local step = row and row.step
  local entry = step and step.quest and Q.log(step.quest)
  if not entry then return "" end
  if entry.ready and (step.type == "turnin" or step.type == "complete") then return "ready to turn in" end
  if step.type ~= "complete" then return "" end
  for i, obj in ipairs(entry.objectives or {}) do
    if (not step.objectiveIndex or i == step.objectiveIndex) and type(obj.text) == "string"
        and obj.finished ~= true and obj.finished ~= 1 then
      return obj.text
    end
  end
  return ""
end

-- Tell the party about the current step, "S;section;position;label" (what every Codex version
-- reads), then its goal, "G;goal" (older versions ignore it). At most every 2 s: a change sooner
-- goes out when the 2 s are up.
local function broadcast(force)
  if ns.db().noPartySteps or not inParty() then return end
  local row = Q.current()
  local key = row and (row.section.id .. ";" .. tostring(row.pos)) or "none;0"
  local goal = myGoal(row):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[;|]", ","):sub(1, 80)
  local state = key .. ";" .. goal
  local now = GetTime()
  if not force and state == sent then return end
  if not force and now - sentAt < 2 then
    if not retrying then
      retrying = true
      ns.after(2 - (now - sentAt), function() retrying = false; broadcast(false) end)
    end
    return
  end
  sent, sentAt = state, now
  local label = row and Q.plain(Q.label(row.step)):gsub("[;|]", ",") or ""
  send(("S;" .. key .. ";" .. label):sub(1, 250))
  send("G;" .. goal)
end

local function receive(prefix, text, channel, sender)
  if prefix ~= PREFIX or channel ~= "PARTY" or type(text) ~= "string" or type(sender) ~= "string" then return end
  local me = try(UnitName, "player")
  local name = Q.plain(sender:match("^[^-]+") or sender)
  if name == me then return end
  if text == "HELLO" then broadcast(true); return end
  local goal = text:match("^G;(.*)$")
  if goal then
    local m = members[name]
    if m then m.goal, m.at = goal, GetTime() end
    ns.questRefresh()
    return
  end
  local section, pos, label = text:match("^S;([^;]*);([^;]*);(.*)$")
  if not section then return end
  local old = members[name]
  pos = tonumber(pos)
  if section == "none" then
    members[name] = nil
  else
    -- a new step drops the old step's goal until its own arrives
    local goalKept = old and old.section == section and old.pos == pos and old.goal or nil
    members[name] = { section = section, pos = pos, label = label, goal = goalKept, at = GetTime() }
  end
  ns.questRefresh()
end

-- The party from the client: party1..4 with their levels; empty without the API.
local function roster()
  local out = {}
  local count = number(try(GetNumSubgroupMembers)) or 0
  for i = 1, math.min(count, 4) do
    local unit = "party" .. i
    local name = try(UnitName, unit)
    if type(name) == "string" and name ~= "" then
      local level = number(try(UnitLevel, unit))
      out[#out + 1] = { name = Q.plain(name), level = level and level > 0 and level or nil }
    end
  end
  return out
end

-- The step window's party rows, one per party member (the roster decides who; without one, every
-- Codex member heard from in the last 15 minutes): { name, text, where, status }. `status` is
-- "same" (your step), "behind" (they are behind you), "ahead", "other" (another guide) or "none"
-- (no step shared: no Codex, or it's turned off). Empty out of a party or with the setting off.
function ns.partyRows()
  if ns.db().noPartySteps or not inParty() then return {} end
  local row = Q.current()
  local now = GetTime()
  local list = roster()
  if #list == 0 then
    for name in pairs(members) do list[#list + 1] = { name = name } end
  end
  local rows = {}
  for _, who in ipairs(list) do
    local m = members[who.name]
    if m and now - m.at >= 900 then m = nil end
    local head = who.name .. (who.level and (" (" .. who.level .. ")") or "")
    local r = { name = who.name, text = head, status = "none", where = "no step shared" }
    if m then
      r.text = head .. ": " .. m.label
      if row and row.section.id == m.section and m.pos and row.pos then
        local diff = m.pos - row.pos
        if diff == 0 then
          r.status, r.where = "same", "same step"
          if m.goal and m.goal ~= "" then r.text = head .. ": " .. m.goal end
        else
          r.status = diff > 0 and "ahead" or "behind"
          r.where = math.abs(diff) .. (diff > 0 and " ahead" or " behind")
        end
      else
        local other = Q.section(m.section)
        r.status, r.where = "other", other and other.title or "another guide"
      end
    end
    r.text, r.where = Q.plain(r.text), Q.plain(r.where)
    rows[#rows + 1] = r
  end
  table.sort(rows, function(a, b) return a.name < b.name end)
  return rows
end

-- Settings > Share guide quests with my party: offer a quest of your route to the party.
local function pushQuest(id, index)
  local L = C_QuestLog
  if L and type(L.SetSelectedQuest) == "function" then
    if type(L.IsPushableQuest) == "function" and try(L.IsPushableQuest, id) == false then return end
    try(L.SetSelectedQuest, id)
  elseif index and type(SelectQuestLogEntry) == "function" then
    try(SelectQuestLogEntry, index)
    if type(GetQuestLogPushable) == "function" and not try(GetQuestLogPushable) then return end
  else
    return
  end
  try(QuestLogPushQuest)
end

local function accepted(a, b)
  local id = tonumber(b) or tonumber(a)
  local index = b and tonumber(a) or nil
  if not id or not ns.db().questShareParty or not inParty() or not Q.questMatch(id) then return end
  ns.after(0.5, function() pushQuest(id, index) end)
end

-- Settings > Say my flights in party chat.
local function announceFlight(node)
  if not ns.db().questAnnounceFlights or not inParty() then return end
  local name = Q.plain(try(TaxiNodeName, node) or "")
  if name == "" then return end
  local left = ns.questFlightEstimate and ns.questFlightEstimate()
  local eta = left and (" (about " .. math.floor(left / 60) .. ":" .. string.format("%02d", math.floor(left % 60)) .. ")") or ""
  try(SendChatMessage, "Flying to " .. (name:match("^[^,]+") or name) .. eta .. ".", "PARTY")
end

-- Party chat announcements (Settings > Party, each off by default), said as "Codex: ...".
-- Chat can't take the client's escape codes: colours, links and textures go, and the |4 and |1
-- grammar codes keep their first form for a count of 1 and their last otherwise. The client's own
-- text (quest and item names in its language) is left as it is: party chat draws every language.
local function chatText(text, count)
  local function form(forms)
    local list = {}
    for piece in (forms .. ":"):gmatch("([^:]*):") do list[#list + 1] = piece end
    return count == 1 and list[1] or list[#list] or ""
  end
  text = tostring(text or "")
  text = text:gsub("|4([^;]*);", form)
  text = text:gsub("|1([^;]*);([^;]*);", function(one, many) return count == 1 and one or many end)
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
  return (text:gsub("|", ""):sub(1, 240))
end

-- One line a second at most, queued; a line with the same key (a newer count of the same objective)
-- replaces one still waiting. Leaving the party or joining a raid drops what's left.
local queue, saidAt, pumping = {}, -10, false
local function pump()
  if pumping or #queue == 0 then return end
  if not inParty() then queue = {}; return end
  local wait = saidAt + 1 - GetTime()
  if wait > 0 then
    pumping = true
    ns.after(wait, function() pumping = false; pump() end)
    return
  end
  local line = table.remove(queue, 1)
  saidAt = GetTime()
  try(SendChatMessage, line.text, "PARTY")
  pump()
end

local function chat(key, text, count)
  if not inParty() then return end
  text = chatText(text, count)
  if text == "" then return end
  text = "Codex: " .. text
  for _, line in ipairs(queue) do
    if key and line.key == key then line.text = text; return end
  end
  queue[#queue + 1] = { key = key, text = text }
  while #queue > 6 do table.remove(queue, 1) end
  pump()
end

local function questTitle(id, entry)
  return (entry and entry.title) or (id and Q.questName(id)) or "a quest"
end

-- What the quest log said last time (questID -> { ready, objs = { { have, done } } }) and which of
-- the route's quest-starting items were in your bags. The first read after login, and anything new
-- in the log, is only noted: nothing is said for what you already had.
local snapshot, starters
local quietUntil = 0

local function objectiveCount(obj)
  local have = number(obj.numFulfilled)
  if not have and type(obj.text) == "string" then have = tonumber(obj.text:match("(%d+)%s*/%s*%d+")) end
  return have
end

local function readSnapshot()
  local snap = {}
  for id, entry in pairs(Q.logEntries()) do
    local objs = {}
    for i, obj in ipairs(entry.objectives or {}) do
      objs[i] = { have = objectiveCount(obj), done = obj.finished == true or obj.finished == 1 }
    end
    snap[id] = { ready = entry.ready == true, objs = objs }
  end
  return snap
end

-- Quest items you picked up (each new count), finished objectives and quests ready to turn in.
-- One line per objective; a quest that is now ready says only that. Questie's own lines win:
-- with its objective announcements on, a finished objective is left to it. `said[questID]` marks
-- the quests that got a line, so a finished step for one isn't said as well.
local readFrom -- the log table the snapshot was read from (each quest log read makes a new one)
local function announceLog(said)
  if Q.logEntries() == readFrom then return end
  readFrom = Q.logEntries()
  local db = ns.db()
  local snap = readSnapshot()
  local old = snapshot
  snapshot = snap
  local items, progress = db.questAnnounceItems, db.questAnnounceProgress
  if not old or GetTime() < quietUntil or not (items or progress) or not inParty() then return end
  local log = Q.logEntries()
  local questieObjectives = ns.questie.announces("objectives")
  for id, now in pairs(snap) do
    local before, entry = old[id], log[id]
    if before and entry then
      local title = questTitle(id, entry)
      if progress and now.ready and not before.ready then
        chat("ready:" .. id, title .. " is ready to turn in.")
        said[id] = true
      else
        for i, obj in ipairs(entry.objectives or {}) do
          local was, is = before.objs[i], now.objs[i]
          local rose = was and is and is.have and was.have and is.have > was.have
          local doneNow = was and is and is.done and not was.done
          if rose and items and obj.type == "item" and not (doneNow and questieObjectives) then
            chat("obj:" .. id .. ":" .. i, chatText(obj.text, is.have) .. " (" .. title .. ")")
            said[id] = true
          elseif doneNow and progress and not questieObjectives then
            chat("obj:" .. id .. ":" .. i, chatText(obj.text, is.have) .. " (" .. title .. ")")
            said[id] = true
          end
        end
      end
    end
  end
end

-- Which quest each of the route's starter items starts, rebuilt with the route.
local starterQuest, starterSteps = {}, nil
local function startsQuest(item)
  local steps = Q.rows()
  if steps ~= starterSteps then
    starterSteps, starterQuest = steps, {}
    for _, row in ipairs(steps or {}) do
      local s = row.step
      if s.startItem and s.quest and not starterQuest[s.startItem] then starterQuest[s.startItem] = s.quest end
    end
  end
  return starterQuest[item]
end

-- A route item that starts a quest turning up in your bags (left to Questie when it says those).
local function announceStarters()
  local now = {}
  for item, has in pairs(Q.starterItems()) do now[item] = has end
  local old = starters
  starters = now
  if not old or GetTime() < quietUntil or not ns.db().questAnnounceItems or not inParty()
      or ns.questie.announces("items") then
    return
  end
  for item, has in pairs(now) do
    if has and old[item] == false then
      local quest = startsQuest(item)
      local name = ns.itemInfo(item)
      chat("start:" .. item, "Found " .. (type(name) == "string" and name or "a quest item") .. ": it starts "
        .. questTitle(quest, quest and Q.log(quest)) .. ".")
    end
  end
end

-- QuestGuide's refresh hands over a step the game just finished (the step sound's moment: not
-- Next, Back or a jump); the lines go out at the end of the same refresh.
local finishedStep
function ns.partyStepDone(step) finishedStep = step end

function ns.partyStepChanged()
  local said = {}
  announceLog(said)
  announceStarters()
  local step = finishedStep
  finishedStep = nil
  if step and ns.db().questAnnounceSteps and GetTime() >= quietUntil and not (step.quest and said[step.quest]) then
    chat(nil, "Done - " .. Q.plain(Q.label(step)))
  end
  broadcast(false)
end

-- Joining a party with every announcement off says once where they are (once ever while your
-- settings are saved, else once a session).
local hinted
local function hint()
  local db = ns.db()
  if hinted or db.questPartyHint then return end
  hinted, db.questPartyHint = true, true
  if db.questAnnounceSteps or db.questAnnounceItems or db.questAnnounceProgress then return end
  ns.say("in a party? Settings > Party can say the steps you finish, the quest items you pick up and your quest progress in party chat.")
end

function ns.startQuestParty()
  if events then return end
  -- the quest log can fill in over the first seconds: nothing is said for it
  quietUntil = GetTime() + 5
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "QUEST_ACCEPTED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
  if type(register) == "function" then try(register, PREFIX) end
  events:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then
      receive(a, b, c, d)
    elseif event == "QUEST_ACCEPTED" then
      accepted(a, b)
    elseif event == "GROUP_ROSTER_UPDATE" then
      if not inParty() then
        members, queue = {}, {}
      else
        hint()
        broadcast(true)
        if not ns.db().noPartySteps then send("HELLO") end
      end
      ns.questRefresh()
    end
  end)
  if type(TakeTaxiNode) == "function" then try(hooksecurefunc, "TakeTaxiNode", announceFlight) end
end

function ns.partyDebugLines()
  local count = 0
  for _ in pairs(members) do count = count + 1 end
  local db = ns.db()
  local on = {}
  if db.questAnnounceSteps then on[#on + 1] = "steps" end
  if db.questAnnounceItems then on[#on + 1] = "items" end
  if db.questAnnounceProgress then on[#on + 1] = "progress" end
  return { "party: " .. (inParty() and "in a party" or "not in a party") .. ", Codex members seen: " .. count
    .. ", addon messages: " .. ((C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage) and "yes" or "no")
    .. ", party chat lines: " .. (#on > 0 and table.concat(on, ", ") or "off") .. ", waiting: " .. #queue }
end
