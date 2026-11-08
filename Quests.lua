-- Quest state comes from the game. Only manual acknowledgements need SavedVariables.
local _, ns = ...
local Q = {}
ns.quests = Q

local function result(ok, ...)
  if ok then return ... end
end

function Q.try(fn, ...) return result(ns.try(fn, ...)) end
local try = Q.try
function Q.plain(value)
  return (ns.plain(value):gsub("[\128-\255]", ""))
end
local log, turnedIn, liveDone, removed = {}, {}, {}, {}
local visited, selected, review = {}, nil, nil
local history = {}
local route, race, class
local sections, steps, missed = {}, {}, {}
local index, level
local RADIUS = 35

function Q.position()
  local map = try(C_Map and C_Map.GetBestMapForUnit, "player")
  local pos = map and try(C_Map.GetPlayerMapPosition, map, "player")
  local x, y = pos and pos.x, pos and pos.y
  if pos and type(pos.GetXY) == "function" then x, y = try(pos.GetXY, pos) end
  if type(x) == "number" and type(y) == "number" then return map, x * 100, y * 100 end
  return map
end

function Q.vector(step, map, x, y)
  local size = route and route.extents and route.extents[map]
  if not (step and x and y and step.x and step.y and step.map == map) then return end
  local east, north = step.x - x, y - step.y
  local angle = math.atan2(east, north)
  if not size then return angle end
  east, north = east * size[1] / 100, north * size[2] / 100
  return math.atan2(east, north), math.sqrt(east * east + north * north)
end

local function classicObjectives(i)
  local count = try(GetNumQuestLeaderBoards, i)
  if type(count) ~= "number" then return end
  local rows = {}
  for n = 1, count do
    local label, _, done = try(GetQuestLogLeaderBoard, n, i)
    if type(label) == "string" then
      local have, need = label:match("(%d+)%s*/%s*(%d+)")
      rows[#rows + 1] = { text = label, finished = done == true or done == 1,
        numFulfilled = tonumber(have), numRequired = tonumber(need) }
    end
  end
  return rows
end

local function readLog()
  local newLog = {}
  local modern = try(C_QuestLog and C_QuestLog.GetNumQuestLogEntries)
  local classic = try(GetNumQuestLogEntries) or 0
  for i = 1, math.max(modern or 0, classic) do
    local info = try(C_QuestLog and C_QuestLog.GetInfo, i)
    local id, title, questLevel, done
    if type(info) == "table" and not info.isHeader then
      id = info.questID or try(C_QuestLog.GetQuestIDForLogIndex, i)
      title, questLevel, done = info.title, info.level, info.isComplete
    elseif info == nil and i <= classic then
      local _, header, questID
      title, questLevel, _, header, _, done, _, questID = try(GetQuestLogTitle, i)
      if not header then id = questID end
    elseif info == nil and i <= (modern or 0) then
      id = try(C_QuestLog.GetQuestIDForLogIndex, i)
    end
    if type(id) == "number" and id > 0 and not removed[id] then
      local objectives = try(C_QuestLog and C_QuestLog.GetQuestObjectives, id)
      if type(objectives) ~= "table" or #objectives == 0 then objectives = classicObjectives(i) end
      local ready = done == true or done == 1 or try(C_QuestLog and C_QuestLog.ReadyForTurnIn, id) == true
      if not ready and objectives and #objectives > 0 then
        ready = true
        for _, row in ipairs(objectives) do
          if row.finished ~= true and row.finished ~= 1 then ready = false; break end
        end
      end
      newLog[id] = { title = title, level = questLevel, objectives = objectives or {}, ready = ready }
    end
  end
  log = newLog
end

local function readCompleted()
  turnedIn = {}
  local completed = {}
  local value = try(GetQuestsCompleted, completed)
  if type(value) == "table" then completed = value end
  for _, row in ipairs(steps) do
    local id = row.step.quest
    if id and turnedIn[id] == nil then
      local done = try(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, id)
      if done == nil then done = try(IsQuestFlaggedCompleted, id) end
      turnedIn[id] = liveDone[id] or done == true or done == 1 or not not completed[id]
    end
  end
end

local function matches(rule, token)
  if type(rule) == "table" then
    for _, v in ipairs(rule) do if v == token then return true end end
    return false
  end
  return not rule or rule == token
end

local function buildRoute()
  local faction = try(UnitFactionGroup, "player")
  local _, raceToken = try(UnitRace, "player")
  local _, classToken = UnitClass("player")
  race, class = (raceToken or ""):upper(), classToken
  route = LevelingCodexQuests and LevelingCodexQuests[(faction or ""):upper()]
  sections, steps = {}, {}
  if not route then return end
  for _, section in ipairs(route.sections) do
    if not section.start or section.start == race then
      sections[#sections + 1] = section
      local occurrences = {}
      for n, step in ipairs(section.steps) do
        if matches(step.class, class) and matches(step.race, race) then
          local action = step.type .. ":" .. (step.quest or n)
          occurrences[action] = (occurrences[action] or 0) + 1
          steps[#steps + 1] = { section = section, step = step,
            key = section.id .. ":" .. action .. ":" .. occurrences[action] }
        end
      end
    end
  end
end

local function chooseSection()
  if selected then return end
  for _, section in ipairs(sections) do
    if level >= section.levels[1] and level <= section.levels[2] then
      selected = section
      break
    end
  end
  if not selected then return end
  for _, row in ipairs(steps) do
    if row.step.quest and log[row.step.quest] and level <= row.section.levels[2] + 2 then
      selected = row.section
      return
    end
  end
  if level == 1 and route.starts[race] then
    for _, section in ipairs(sections) do
      if section.id == route.starts[race] then selected = section; return end
    end
  end
end

local function skipTable()
  local db = ns.charDB()
  db.questSkips = db.questSkips or {}
  return db.questSkips
end

local function gameDone(step)
  local id = step.quest
  local entry = id and log[id]
  return id and (turnedIn[id] or (step.type == "accept" and entry)
    or (step.type == "complete" and entry and entry.ready))
end

local function state(row, skips, skippedQuests, later, map, x, y)
  local s = row.step
  if s.optional and not ns.db().questDungeons then return "filtered" end
  if s.quest then
    local entry = log[s.quest]
    if gameDone(s) then return "done" end
    if skippedQuests[s.quest] then return "skipped" end
    if not entry then
      for _, id in ipairs(s.chain or {}) do
        if skippedQuests[id] and not turnedIn[id] then
          skippedQuests[s.quest] = true
          return "skipped"
        end
      end
    end
  end
  if skips[row.key] then return "skipped" end
  if visited[row.key] then return "done" end
  if s.type == "grind" and s.level and level >= s.level then return "done" end
  if s.type == "goto" then
    local _, dist = Q.vector(s, map, x, y)
    if dist and dist <= RADIUS then
      visited[row.key] = true
      return "done"
    end
    if later then return "done" end
  end
  return "pending"
end

local function calculate()
  local map, x, y = Q.position()
  local later, laterSeen = {}, {}
  for i = #steps, 1, -1 do
    local row = steps[i]
    later[i] = laterSeen[row.section]
    if not row.step.optional and gameDone(row.step) then laterSeen[row.section] = true end
  end
  local skips, skippedQuests, reached, seen = skipTable(), {}, false, {}
  index, missed = nil, {}
  for i, row in ipairs(steps) do
    if row.section == selected then reached = true end
    row.state = state(row, skips, skippedQuests, later[i], map, x, y)
    local s = row.step
    if s.quest and row.state == "skipped" then skippedQuests[s.quest] = true end
    if reached and not index and row.state == "pending" then index = i end
    if selected and not reached and s.type == "accept" and not turnedIn[s.quest]
        and row.state ~= "filtered" and not seen[s.quest] and level >= (s.min or 1) then
      local grey = try(GetQuestGreenRange) or (level < 40 and 5 + math.floor(level / 10) or 9)
      if not s.level or s.level > level - grey then
        missed[#missed + 1], seen[s.quest] = row, true
      end
    end
  end
  if index then selected = steps[index].section end
end

function Q.update(event, id, newLevel)
  if not route then buildRoute() end
  level = newLevel or UnitLevel("player") or 1
  if event == "QUEST_TURNED_IN" and id then liveDone[id] = true end
  if event == "QUEST_REMOVED" and id then removed[id] = true end
  if event == "QUEST_ACCEPTED" and id then removed[id] = nil end
  readLog()
  readCompleted()
  chooseSection()
  calculate()
end

function Q.current()
  local i = review or index
  return i and steps[i], i
end

function Q.rows() return steps, sections, missed, level or UnitLevel("player"), selected end
function Q.log(id) return log[id] end
function Q.logEntries() return log end
function Q.arrived() return RADIUS end

function Q.destination(row, i, map)
  local step = row and row.step
  if not step or not step.map or step.map == map then return step end
  for n = i - 1, 1, -1 do
    local previous = steps[n]
    if previous.section ~= row.section or (previous.step.map and previous.step.map ~= step.map
        and previous.step.map ~= map) then break end
    if previous.step.map == map and previous.step.type == "goto" then return previous.step end
  end
  return step
end

function Q.upcoming(i)
  local result = {}
  for n = i + 1, #steps do
    local row = steps[n]
    if row.state == "pending" then
      result[#result + 1] = row
      if #result == 2 then break end
    end
  end
  return result
end

function Q.next()
  local row, i = Q.current()
  if not row then return end
  local manual = not review
  if review then
    repeat i = i + 1 until not steps[i] or steps[i].state ~= "filtered"
    review = index and i < index and i or nil
  elseif row.step.quest or row.step.type == "dungeon" then
    skipTable()[row.key] = true
  else
    visited[row.key] = true
  end
  calculate()
  if manual then history[#history + 1] = { from = i, to = index } end
end

function Q.back()
  local i = (review or index or (#steps + 1)) - 1
  local previous = history[#history]
  if not review and previous and previous.to == index then
    i = previous.from
    table.remove(history)
  else
    while steps[i] and (steps[i].state == "filtered" or steps[i].state == "skipped") do i = i - 1 end
  end
  local row = steps[i]
  if row then
    skipTable()[row.key], visited[row.key] = nil, nil
    selected, review = row.section, i
    calculate()
    if review == index then review = nil end
  end
end

function Q.jump(section, row)
  selected, review = section, nil
  history = {}
  calculate()
  if row then
    for i, candidate in ipairs(steps) do
      if candidate == row then review = i ~= index and i or nil; break end
    end
  end
end

function Q.autoStep()
  local row = not review and index and steps[index]
  return row and row.step
end

function Q.acknowledge(kind, matchesStep)
  local row = index and steps[index]
  if not review and row and row.step.type == kind and matchesStep(row.step) then
    visited[row.key] = true
    calculate()
  end
end

function Q.checkArrival()
  local row = not review and index and steps[index]
  if row and row.step.type == "goto" then
    local _, dist = Q.vector(row.step, Q.position())
    if dist and dist <= RADIUS then
      calculate()
      return true
    end
  end
end

function Q.text(step)
  if step.quest == 95998 and step.type == "complete" then
    local mining = ns.P and ns.P.MINING
    local first = mining and mining.camp and mining.camp[1]
    if first then
      return step.text .. " Miners can learn " .. first.name .. " at skill " .. first.skill .. " (Professions tab)."
    end
  end
  if step.type ~= "train" then return step.text end
  local visit = ns.trainAt(step.level or level) or ns.nextTrain((step.level or level) - 1)
  if not visit then return step.text .. " " .. tostring(step.level or level) .. "." end
  return ns.plain(step.text .. " " .. visit.level .. ": " .. table.concat(visit.spells, ", "))
end
