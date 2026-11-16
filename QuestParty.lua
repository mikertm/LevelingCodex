-- QuestParty.lua: playing the guide in a party. Nothing here runs in a raid.
-- Party sync: party members running the Codex tell each other their real step, its live goal and
-- the quests in their log (addon messages); the step window lists every party member against your
-- step (Settings > Show my party's steps) and Quests > Party shows each one in full, with the
-- quests one of you has and the other doesn't. Opt-in helpers: share a guide quest with the party
-- when you accept it, say in party chat where you are flying, and quest tracker-like party chat lines for
-- the steps you finish, the quest items you pick up and your quest progress.
local _, ns = ...
local Q = ns.quests
local try = Q.try
local PREFIX = "LevCodex"
local HEARTBEAT = 60      -- your step goes out again this often, so the others know you're still there
local QUIET = 180         -- a member whose Codex sends a heartbeat drops out after this long silent
local QUIET_OLD = 900     -- an older Codex sends no heartbeat (nor goals): its step keeps this long
local members = {}        -- name -> { section, pos, label, goal, live, at }: live = it sends goals
local logs = {}           -- name -> { [questID] = true }: the quests in their log
local sent, sentQuests    -- what we last told the party: step and goal, and the quest list
local sentAt, retrying = -HEARTBEAT, false
local rosterKey, rosterAt = nil, -10
local events

local function inParty()
  local group = try(IsInGroup)
  local raid = try(IsInRaid)
  return (group == true or group == 1) and not (raid == true or raid == 1)
end
ns.partyInParty = inParty

local function send(text)
  local api = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
  if type(api) == "function" then try(api, PREFIX, text, "PARTY") end
end

-- A number the client may hide from addon code (a secret value) reads as nil.
local function number(v)
  if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
  return tonumber(v)
end

local function me() return try(UnitName, "player") end

local function questTitle(id, entry)
  return (entry and entry.title) or (id and Q.questName(id)) or "a quest"
end

-- Your real step: the route's own, not one you went Back to look at.
local function myRow()
  if Q.routeRow then return Q.routeRow() end
  return Q.current()
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

-- The quests in your log, "783,33,7" (sorted, cut at a comma to fit one message).
local function myQuests()
  local ids = {}
  for id in pairs(Q.logEntries()) do ids[#ids + 1] = id end
  table.sort(ids)
  local text = table.concat(ids, ",")
  if #text > 240 then text = text:sub(1, 240):match("^(.*),") or "" end
  return text
end

local function clean(text, max)
  return (tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[;|]", ","):sub(1, max))
end

-- Tell the party about your step, "S;section;position;label" (what every Codex version reads), its
-- goal, "G;goal", and, when it changed, your quests, "L;ids" (older versions ignore both). At most
-- every 2 s: a change sooner goes out when the 2 s are up. `force` (joining, a HELLO, the heartbeat)
-- sends at once.
local function broadcast(force)
  if ns.db().noPartySteps or not inParty() then return end
  local row = myRow()
  local key = row and (row.section.id .. ";" .. tostring(row.pos)) or "none;0"
  local goal = clean(myGoal(row), 80)
  local state = key .. ";" .. goal
  local quests = myQuests()
  local now = GetTime()
  if not force and state == sent and quests == sentQuests then return end
  if not force and now - sentAt < 2 then
    if not retrying then
      retrying = true
      ns.after(2 - (now - sentAt), function() retrying = false; broadcast(false) end)
    end
    return
  end
  sent, sentAt = state, now
  local label = row and clean(Q.plain(Q.label(row.step)), 200) or ""
  send(("S;" .. key .. ";" .. label):sub(1, 250))
  send("G;" .. goal)
  if quests ~= sentQuests or force then
    sentQuests = quests
    send("L;" .. quests)
  end
end

-- The party from the client: party1..4 with level, class and whether they're online or dead;
-- empty without the API.
local function roster()
  local out = {}
  local count = number(try(GetNumSubgroupMembers)) or 0
  for i = 1, math.min(count, 4) do
    local unit = "party" .. i
    local name = try(UnitName, unit)
    if type(name) == "string" and name ~= "" then
      local level = number(try(UnitLevel, unit))
      local className = try(UnitClass, unit)
      out[#out + 1] = { name = Q.plain(name), level = level and level > 0 and level or nil,
        className = type(className) == "string" and Q.plain(className) or nil,
        offline = try(UnitIsConnected, unit) == false, dead = try(UnitIsDeadOrGhost, unit) == true }
    end
  end
  return out
end

local function fresh(m, now)
  return m and now - m.at < (m.live and QUIET or QUIET_OLD)
end

-- Share a quest from your log with the party: true once offered, false when the game won't.
local function pushQuest(id, index)
  local L = C_QuestLog
  if L and type(L.SetSelectedQuest) == "function" then
    if type(L.IsPushableQuest) == "function" and try(L.IsPushableQuest, id) == false then return false end
    try(L.SetSelectedQuest, id)
  else
    index = index or (Q.log(id) and Q.log(id).index)
    if not index or type(SelectQuestLogEntry) ~= "function" then return false end
    try(SelectQuestLogEntry, index)
    if type(GetQuestLogPushable) == "function" and not try(GetQuestLogPushable) then return false end
  end
  if type(QuestLogPushQuest) ~= "function" then return false end
  try(QuestLogPushQuest)
  return true
end

-- A member's Ask to share: offer them that quest (once per 10 s each), or tell them it can't be.
local asked = {}
local function shareRequest(id, asker)
  if not id then return end
  local now = GetTime()
  if asked[id] and now - asked[id] < 10 then return end
  asked[id] = now
  local entry = Q.log(id)
  if entry and pushQuest(id, entry.index) then
    ns.say(asker .. " asked for " .. Q.plain(questTitle(id, entry)) .. ": offered it to your party.")
  else
    send("N;" .. id .. ";" .. asker)
  end
end

local function receive(prefix, text, channel, sender)
  if prefix ~= PREFIX or channel ~= "PARTY" or type(text) ~= "string" or type(sender) ~= "string" then return end
  local myName = me()
  local name = Q.plain(sender:match("^[^-]+") or sender)
  if name == myName then return end
  local now = GetTime()
  if text == "HELLO" then broadcast(true); return end
  local m = members[name]
  local goal = text:match("^G;(.*)$")
  if goal then
    if m then m.goal, m.live, m.at = goal, true, now end
    ns.questRefresh()
    return
  end
  local list = text:match("^L;(.*)$")
  if list then
    local set = {}
    for id in list:gmatch("%d+") do set[tonumber(id)] = true end
    logs[name] = set
    if m then m.live, m.at = true, now end
    ns.questRefresh()
    return
  end
  -- "R;quest;name": name asks for a quest of yours; "N;quest;name": the one you asked can't share it
  local kind, quest, target = text:match("^([RN]);(%d+);(.+)$")
  if kind then
    quest = tonumber(quest)
    if Q.plain(target:match("^[^-]+") or target) ~= myName then return end
    if kind == "R" then shareRequest(quest, name)
    else ns.say(name .. " can't share " .. Q.plain(questTitle(quest)) .. ": the game won't let it be shared, or it isn't in their log.") end
    return
  end
  local section, pos, label = text:match("^S;([^;]*);([^;]*);(.*)$")
  if not section then return end
  pos = tonumber(pos)
  if section == "none" then
    members[name] = nil
  else
    -- a new step drops the old step's goal until its own arrives
    local goalKept = m and m.section == section and m.pos == pos and m.goal or nil
    members[name] = { section = section, pos = pos, label = label, goal = goalKept, live = m and m.live, at = now }
  end
  ns.questRefresh()
end

-- How many steps a member is ahead (+) or behind (-) you, counted in your own route: the rows you
-- see (not filtered, grey or cut) between your step and the first of yours at or past their place
-- in the guide's data. Their step may be one your route doesn't have (another class's quest).
local function shown(row) return row.state ~= "filtered" and not row.grey and not row.cut end

local function distance(mine, at, pos)
  if pos == mine.pos then return 0 end
  local steps = Q.rows()
  local ahead = pos > mine.pos
  local n, i = 0, ahead and at or at - 1
  while steps[i] and steps[i].section == mine.section and (ahead and steps[i].pos < pos or not ahead and steps[i].pos >= pos) do
    if shown(steps[i]) then n = n + 1 end
    i = ahead and i + 1 or i - 1
  end
  n = math.max(1, n)
  return ahead and n or -n
end

-- One row per party member (the roster decides who; without one, every Codex member heard from
-- lately): { name, level, className, text, where, status, label, goal, guide, section, heard,
-- codex, steps, offline, dead }. `status` is "same" (your step), "behind" (they are behind you),
-- "ahead", "other" (another guide), "offline" or "none" (no step shared). The step window's rows
-- (empty out of a party or with Settings > Show my party's steps off; `all` ignores the setting).
function ns.partyRows(all)
  if (ns.db().noPartySteps and not all) or not inParty() then return {} end
  local mine, at = myRow()
  local now = GetTime()
  local list = roster()
  if #list == 0 then
    for name, m in pairs(members) do
      if fresh(m, now) then list[#list + 1] = { name = name } end
    end
  end
  local rows = {}
  for _, who in ipairs(list) do
    local m = members[who.name]
    if not fresh(m, now) then m = nil end
    local head = who.name .. (who.level and (" (" .. who.level .. ")") or "")
    local r = { name = who.name, level = who.level, className = who.className, offline = who.offline,
      dead = who.dead, text = head, status = "none", where = "no step shared", codex = m ~= nil }
    if m then
      local other = Q.section(m.section)
      r.label, r.goal, r.heard, r.live = m.label, m.goal or "", now - m.at, m.live
      r.section, r.guide = other, other and other.title or "another guide"
      r.text = head .. ": " .. m.label
      if mine and mine.section.id == m.section and m.pos and mine.pos then
        r.steps = distance(mine, at, m.pos)
        if r.steps == 0 then
          r.status, r.where = "same", "same step"
          if r.goal ~= "" then r.text = head .. ": " .. r.goal end
        else
          r.status = r.steps > 0 and "ahead" or "behind"
          r.where = math.abs(r.steps) .. (r.steps > 0 and " ahead" or " behind")
        end
      else
        r.status, r.where = "other", r.guide
      end
    end
    if who.offline then
      r.status, r.where = "offline", "offline"
    elseif who.dead then
      r.where = r.where .. " (dead)"
    end
    r.text, r.where = Q.plain(r.text), Q.plain(r.where)
    rows[#rows + 1] = r
  end
  table.sort(rows, function(a, b) return a.name < b.name end)
  return rows
end

-- Everyone online is on your step (and at least one of them shares it).
local function together(rows)
  local any = false
  for _, r in ipairs(rows) do
    if r.status ~= "offline" then
      if r.status ~= "same" then return false end
      any = true
    end
  end
  return any
end
ns.partyTogether = together

-- Catch-up cues for the step window: "Bo is 4 steps behind you." for each member 3 or more steps
-- behind you in your guide.
function ns.partyWaitLines(rows)
  local lines = {}
  for _, r in ipairs(rows or ns.partyRows()) do
    if r.status == "behind" and -r.steps >= 3 then
      lines[#lines + 1] = r.name .. " is " .. -r.steps .. " steps behind you."
    end
  end
  return lines
end

-- The compact step window's party line: "Party: all on this step" or "Party: Ann same step, Bo 4 behind".
function ns.partySummary()
  local rows = ns.partyRows()
  if #rows == 0 then return nil end
  if together(rows) then return "Party: all on this step" end
  local bits = {}
  for _, r in ipairs(rows) do bits[#bits + 1] = r.name .. " " .. r.where end
  return Q.plain("Party: " .. table.concat(bits, ", "))
end

-- The quests a member has that you don't (quests of your route you haven't turned in), and the
-- quests you have that they don't: two lists of { id, title }, or nil before their log is known.
function ns.partyQuestDiff(name)
  local theirs = logs[name]
  if not theirs then return nil end
  local log = Q.logEntries()
  local have, lack = {}, {}
  for id in pairs(theirs) do
    if not log[id] and Q.questName(id) and not Q.turnedIn(id) then
      have[#have + 1] = { id = id, title = Q.plain(Q.questName(id)) }
    end
  end
  for id, entry in pairs(log) do
    if not theirs[id] then lack[#lack + 1] = { id = id, title = Q.plain(questTitle(id, entry)) } end
  end
  local function byTitle(a, b) return a.title < b.title end
  table.sort(have, byTitle)
  table.sort(lack, byTitle)
  return have, lack
end

-- Quests > Party's buttons.
function ns.partyAskShare(name, id)
  send("R;" .. id .. ";" .. name)
  ns.say("asked " .. name .. " to share " .. Q.plain(questTitle(id)) .. ".")
end

function ns.partyShare(id)
  local entry = Q.log(id)
  if entry and pushQuest(id, entry.index) then
    ns.say("offered " .. Q.plain(questTitle(id, entry)) .. " to your party.")
  else
    ns.say("the game won't let " .. Q.plain(questTitle(id, entry)) .. " be shared.")
  end
end

-- Switch your guide to the one a member is in.
function ns.partyFollow(name)
  local m = members[name]
  local section = m and Q.section(m.section)
  if not section then return end
  if section.side then
    Q.jump(section)
    ns.showQuestViewer()
  else
    ns.followSuggestedQuestSection(section)
  end
  ns.questRefresh()
end

-- Settings > Share guide quests with my party (on unless you turned it off: `db.questShareParty`
-- false): offer a quest of your route to the party. It waits 2.5 s (a member who takes it at the
-- same time has said so by then) and leaves out a quest every party member's Codex already has.
function ns.questSharing() return ns.db().questShareParty ~= false end
function ns.toggleQuestSharing() ns.db().questShareParty = not ns.questSharing() end

local function everyoneHas(id)
  local list = roster()
  if #list == 0 then return false end
  for _, who in ipairs(list) do
    if not (logs[who.name] and logs[who.name][id]) then return false end
  end
  return true
end

local function accepted(a, b)
  local id = tonumber(b) or tonumber(a)
  local index = b and tonumber(a) or nil
  if not id or not ns.questSharing() or not inParty() or not Q.questMatch(id) then return end
  ns.after(2.5, function()
    if inParty() and Q.log(id) and not everyoneHas(id) then pushQuest(id, index) end
  end)
end

-- Settings > Say my flights in party chat.
local chat
local function announceFlight(node)
  if not ns.db().questAnnounceFlights or not inParty() then return end
  local name = Q.plain(try(TaxiNodeName, node) or "")
  if name == "" then return end
  local left = ns.questFlightEstimate and ns.questFlightEstimate()
  local eta = left and (" (about " .. math.floor(left / 60) .. ":" .. string.format("%02d", math.floor(left % 60)) .. ")") or ""
  chat("flight", (name:match("^[^,]+") or name) .. eta .. ".", nil, "flight")
end

-- Party transport uses a standard raid marker and validated native links. Custom
-- textures belong only in the receiving client's chat filter, never SendChatMessage.
-- Native names stay localized; arbitrary text loses markup and grammar escapes.
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
  return (text:gsub("|", ""):gsub("[%z\1-\31\127]", " "))
end

local STYLES = {
  accepted = { "Accepted", "ffd9b35b", "accept" },
  item = { "Loot", "ff77ccec", "loot" },
  found = { "Found quest item", "ff77ccec", "loot" },
  objective = { "Objective complete", "ff84d88a", "check" },
  ready = { "Ready to turn in", "ffd9b35b", "turnin" },
  turnin = { "Turned in", "ff53d8cb", "check" },
  travel = { "Travel complete", "ff77ccec", "fly" },
  flight = { "Flying to", "ff77ccec", "fly" },
  step = { "Step complete", "ffd9b35b", "accept" },
}
local CHAT_MARK = "{rt6} Codex: "

-- Shorten plain fields at UTF-8 boundaries; hyperlinks are shortened only by
-- replacing the entire link with its readable label, never by slicing markup.
local function clipped(text, limit)
  if #text <= limit then return text end
  local n = math.max(0, limit - 3)
  while n > 0 and (text:byte(n + 1) or 0) >= 128 and (text:byte(n + 1) or 0) < 192 do n = n - 1 end
  return text:sub(1, n) .. "..."
end

local function reference(kind, id, name, link)
  local label = "[" .. clipped(chatText(name):gsub("%[", "("):gsub("%]", ")"), 70) .. "]"
  local valid
  if type(link) == "string" and not (issecretvalue and issecretvalue(link)) then
    local color = link:match("^|c(%x%x%x%x%x%x%x%x)")
    local body = link:gsub("^|c%x%x%x%x%x%x%x%x", ""):gsub("|r$", "")
    local payload = body:match("^|H(" .. kind .. ":%d+[:%d%-]*)|h%b[]|h$")
    if payload and tonumber(payload:match("^[^:]+:(%d+)")) == id then
      valid = "|c" .. (color or "ffffff00") .. "|H" .. payload .. "|h" .. label .. "|h|r"
    end
  end
  return { label = label, link = valid }
end

local questLinks = {}
local function questRef(id, entry, name)
  local link = id and (try(C_QuestLog and C_QuestLog.GetQuestLink, id) or try(GetQuestLink, id))
  local ref = reference("quest", id, name or questTitle(id, entry), link)
  if id then
    if ref.link then questLinks[id] = ref
    elseif questLinks[id] then return questLinks[id] end
  end
  return ref
end

local function itemRef(item, fallback)
  local name, link = ns.itemInfo(item)
  return reference("item", item, type(name) == "string" and name or fallback or "Quest item", link)
end

local function announcement(kind, parts, count)
  local style = STYLES[kind] or STYLES.step
  local prefix = CHAT_MARK .. style[1] .. ": "
  local fields, plain, total = {}, {}, #prefix
  for i, part in ipairs(type(parts) == "table" and parts or { parts }) do
    local ref = type(part) == "table"
    fields[i] = ref and (part.link or part.label) or clipped(chatText(part, count), 180)
    plain[i] = ref and part.label or fields[i]
    total = total + #fields[i]
  end
  for i = 1, #fields do
    if total <= 255 then break end
    if fields[i] ~= plain[i] then
      total = total - #fields[i] + #plain[i]
      fields[i] = plain[i]
    end
  end
  while total > 255 do
    local longest
    for i = 1, #fields do
      if fields[i] == plain[i] and #fields[i] > 3 and (not longest or #fields[i] > #fields[longest]) then longest = i end
    end
    if not longest then return end
    local shorter = clipped(fields[longest], math.max(3, #fields[longest] - (total - 255)))
    total = total - #fields[longest] + #shorter
    fields[longest], plain[longest] = shorter, shorter
  end
  return prefix .. table.concat(fields)
end

local function chatIcon(path)
  if type(path) ~= "string" then return "" end
  if not path:find("\\", 1, true) then path = ns.iconPath(path) end
  return ns.art.hasFile(path) and ("|T" .. path .. ":14:14|t ") or ""
end

local function decorated(text)
  if type(text) ~= "string" or text:sub(1, #CHAT_MARK) ~= CHAT_MARK then return end
  local label, body = text:sub(#CHAT_MARK + 1):match("^([^:]+): (.*)$")
  for _, style in pairs(STYLES) do
    if label == style[1] then
      local statusIcon = style[3] == "check" and "Interface\\RaidFrame\\ReadyCheck-Ready" or ns.questMap.ICONS[style[3]]
      return chatIcon(ns.ADDON_ICON or "Achievement_Level_60") .. "|cff53d8cbCodex|r "
        .. chatIcon(statusIcon) .. "|c" .. style[2] .. label .. ":|r " .. body
    end
  end
end

local function announcementFilter(_, _, text, author, ...)
  local display = decorated(text)
  if display then return false, display, author, ... end
end

local filtersAdded = {}
local function registerAnnouncementFilters(attempt)
  if type(ChatFrameAddMessageEventFilter) ~= "function" then return end
  local retry
  for _, event in ipairs({ "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" }) do
    if not filtersAdded[event] then
      local ok = ns.try(ChatFrameAddMessageEventFilter, event, announcementFilter)
      if ok then filtersAdded[event] = true else retry = true end
    end
  end
  if retry and attempt < 3 then ns.after(1, function() registerAnnouncementFilters(attempt + 1) end) end
end

function ns.previewQuestAnnouncements()
  local row = myRow()
  local id = row and row.step.quest or 783
  local ref = questRef(id, Q.log(id))
  ns.say("Quest announcement preview (only you can see this):")
  for _, sample in ipairs({
    { "accepted", { ref } },
    { "item", { "Quest item: 4/8 - ", ref } },
    { "objective", { "Objective: 10/10 - ", ref } },
    { "ready", { ref } },
    { "turnin", { ref } },
    { "found", { itemRef(1307), " - starts ", ref } },
    { "flight", { "Stormwind (about 2:15)." } },
  }) do
    local line = decorated(announcement(sample[1], sample[2]))
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(line) end
  end
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

chat = function(key, text, count, kind)
  if not inParty() then return end
  text = announcement(kind, text, count)
  if not text then return end
  for _, line in ipairs(queue) do
    if key and line.key == key then line.text = text; return end
  end
  queue[#queue + 1] = { key = key, text = text }
  while #queue > 6 do table.remove(queue, 1) end
  pump()
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
    questRef(id, entry) -- Keep native links while the quest is still in the log, including across turn-in.
    local objs = {}
    for i, obj in ipairs(entry.objectives or {}) do
      objs[i] = { have = objectiveCount(obj), done = obj.finished == true or obj.finished == 1 }
    end
    snap[id] = { ready = entry.ready == true, objs = objs }
  end
  return snap
end

-- Quest items you picked up (each new count), finished objectives and quests ready to turn in.
-- One line per objective; a quest that is now ready says only that. quest tracker's own lines win:
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
  local providerObjectives = ns.questSupport.announces("objectives")
  for id, now in pairs(snap) do
    local before, entry = old[id], log[id]
    if before and entry then
      if progress and now.ready and not before.ready then
        chat("ready:" .. id, { questRef(id, entry) }, nil, "ready")
        said[id] = true
      else
        for i, obj in ipairs(entry.objectives or {}) do
          local was, is = before.objs[i], now.objs[i]
          local rose = was and is and is.have and was.have and is.have > was.have
          local doneNow = was and is and is.done and not was.done
          if rose and items and obj.type == "item" and not (doneNow and providerObjectives) then
            chat("obj:" .. id .. ":" .. i, { chatText(obj.text, is.have), " - ", questRef(id, entry) }, is.have, doneNow and "objective" or "item")
            said[id] = true
          elseif doneNow and progress and not providerObjectives then
            chat("obj:" .. id .. ":" .. i, { chatText(obj.text, is.have), " - ", questRef(id, entry) }, is.have, "objective")
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

-- A route item that starts a quest turning up in your bags (left to quest tracker when it says those).
local function announceStarters()
  local now = {}
  for item, has in pairs(Q.starterItems()) do now[item] = has end
  local old = starters
  starters = now
  if not old or GetTime() < quietUntil or not ns.db().questAnnounceItems or not inParty()
      or ns.questSupport.announces("items") then
    return
  end
  for item, has in pairs(now) do
    if has and old[item] == false then
      local quest = startsQuest(item)
      local name = ns.itemInfo(item)
      chat("start:" .. item, { itemRef(item, name), " - starts ", questRef(quest, quest and Q.log(quest)) }, nil, "found")
    end
  end
end

-- The together ping's sound (Settings > Ping sound): the Battle.net friend-online chime by default
-- (Forever's SoundKit gives it volume 0.4, the ready check 0.69), the party invite or the ready
-- check. Played on the Sound Effects channel, so that slider sets how loud it is.
ns.PARTY_PINGS = { { "Soft chime", 18019 }, { "Party invite", 880 }, { "Ready check", 8960 } }

function ns.partyPingIndex()
  local i = tonumber(ns.db().partyPingSound)
  return ns.PARTY_PINGS[i] and i or 1
end

function ns.playPartyPing(i)
  local sound = ns.PARTY_PINGS[i or ns.partyPingIndex()]
  if sound and type(PlaySound) == "function" then pcall(PlaySound, sound[2], "SFX") end
end

-- The ping when the last member reaches your step, or you reach theirs: not in the first 5 s
-- after someone joins (their replies to HELLO), at most every 20 s (Settings > Ping when the party
-- is together on my step).
local wasTogether, pingAt = nil, -60
local function checkTogether()
  local now = GetTime()
  local isTogether = together(ns.partyRows())
  if isTogether and wasTogether == false and now - rosterAt >= 5 and now - pingAt >= 20 and not ns.db().noPartyPing then
    pingAt = now
    ns.playPartyPing()
  end
  wasTogether = isTogether
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
    local kind = step.type == "accept" and "accepted" or step.type == "turnin" and "turnin"
      or step.type == "complete" and "objective" or STYLES[step.type] and step.type or "step"
    local delegate = kind == "accepted" and ns.questSupport.announces("accepted")
      or kind == "turnin" and ns.questSupport.announces("turnedIn")
    if not delegate then
      chat(nil, step.quest and { questRef(step.quest, Q.log(step.quest), step.name) } or Q.plain(Q.label(step)), nil, kind)
    end
  end
  broadcast(false)
  checkTogether()
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

-- The party changed. Only someone new joining asks everyone for their steps (HELLO): an update
-- with the same people (a level, a zone, someone going offline) just redraws.
local function rosterChanged()
  if not inParty() then
    members, logs, queue, rosterKey, wasTogether = {}, {}, {}, nil, nil
    sentQuests = nil
    return
  end
  hint()
  local names = {}
  for _, who in ipairs(roster()) do names[#names + 1] = who.name end
  table.sort(names)
  local key = table.concat(names, ",")
  if key ~= rosterKey then
    rosterKey, rosterAt = key, GetTime()
    broadcast(true)
    if not ns.db().noPartySteps then send("HELLO") end
  end
end

-- Every 5 s: the heartbeat, and a redraw when a member goes quiet, offline, online or dies.
local statusKey
local function tick()
  if not inParty() then return end
  local now = GetTime()
  if now - sentAt >= HEARTBEAT then broadcast(true) end
  local bits = {}
  for _, who in ipairs(roster()) do
    bits[#bits + 1] = who.name .. (who.offline and "o" or "") .. (who.dead and "d" or "")
      .. (fresh(members[who.name], now) and "f" or "")
  end
  for name, m in pairs(members) do bits[#bits + 1] = name .. (fresh(m, now) and "+" or "-") end
  table.sort(bits)
  local key = table.concat(bits, ",")
  if key ~= statusKey then
    statusKey = key
    ns.questRefresh()
  end
end

function ns.startQuestParty()
  if events then return end
  -- the quest log can fill in over the first seconds: nothing is said for it
  quietUntil = GetTime() + 5
  registerAnnouncementFilters(1)
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
      rosterChanged()
      ns.questRefresh()
    end
  end)
  if type(TakeTaxiNode) == "function" then try(hooksecurefunc, "TakeTaxiNode", announceFlight) end
  ns.every(5, tick)
end

function ns.partyDebugLines()
  local count = 0
  for _ in pairs(members) do count = count + 1 end
  local db = ns.db()
  local on = {}
  if db.questAnnounceSteps then on[#on + 1] = "steps" end
  if db.questAnnounceItems then on[#on + 1] = "items" end
  if db.questAnnounceProgress then on[#on + 1] = "progress" end
  local lines = { "party: " .. (inParty() and "in a party" or "not in a party") .. ", Codex members seen: " .. count
    .. ", addon messages: " .. ((C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage) and "yes" or "no")
    .. ", party chat lines: " .. (#on > 0 and table.concat(on, ", ") or "off") .. ", waiting: " .. #queue }
  local now = GetTime()
  for _, r in ipairs(ns.partyRows(true)) do
    local m = members[r.name]
    local log = logs[r.name]
    local n = 0
    for _ in pairs(log or {}) do n = n + 1 end
    lines[#lines + 1] = "party member " .. r.name .. ": " .. (not m and "no step shared"
      or ((m.live and "Codex" or "older Codex (no counts or heartbeat)") .. ", step " .. m.section .. " " .. tostring(m.pos)
        .. ", " .. r.where .. ", heard " .. math.floor(now - m.at) .. " s ago"
        .. (log and (", " .. n .. " quests in log") or "")))
  end
  return lines
end
