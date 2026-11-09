-- Quest state comes from the game. Only manual acknowledgements need SavedVariables.
local _, ns = ...
local Q = {}
ns.quests = Q

local function result(ok, ...)
  if ok then return ... end
end

function Q.try(fn, ...) return result(ns.try(fn, ...)) end
local try = Q.try
function Q.itemCount(item)
  return tonumber(try(C_Item and C_Item.GetItemCount, item) or try(GetItemCount, item)) or 0
end

function Q.plain(value)
  return (ns.plain(value):gsub("[\128-\255]", ""))
end
local log, turnedIn, liveDone, removed = {}, {}, {}, {}
local knownFlights, flightHubs, flightLinks = {}, {}, {}
local visited, selected, review = {}, nil, nil
local classSection
local history, classHistory, classSkips = {}, {}, {}
local route, race, class
local sections, sectionsById, steps, missed, ready = {}, {}, {}, {}, {}
local startItems = {}
local questNames = {}
local index, level, resumeAt
local inWorld = true
local RADIUS = 35
local ARRIVAL = { ["goto"] = true, fly = true, hearth = true }

function Q.inFlight()
  local taxi = try(UnitOnTaxi, "player")
  return taxi == true or taxi == 1
end

function Q.position()
  if not inWorld then return end
  local map = try(C_Map and C_Map.GetBestMapForUnit, "player")
  if type(map) ~= "number" or map <= 0 then return end
  local pos = try(C_Map.GetPlayerMapPosition, map, "player")
  local x, y = pos and pos.x, pos and pos.y
  if pos and type(pos.GetXY) == "function" then x, y = try(pos.GetXY, pos) end
  if type(x) == "number" and type(y) == "number" and x >= 0 and x <= 1 and y >= 0 and y <= 1
      and (x ~= 0 or y ~= 0) then
    return map, x * 100, y * 100
  end
  return map
end

function Q.vector(step, map, x, y)
  if not (step and x and y and step.x and step.y and step.map == map) then return end
  local size = route and route.extents and route.extents[map]
  local width, height
  if size then width, height = size[1], size[2]
  else width, height = try(C_Map and C_Map.GetMapWorldSize, map) end
  if not (type(width) == "number" and width > 0 and type(height) == "number" and height > 0) then return end
  local east, north = (step.x - x) * width / 100, (y - step.y) * height / 100
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
    else
      rows[#rows + 1] = {} -- Keep objective indices aligned when a leaderboard row is unavailable.
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
      newLog[id] = { title = title or questNames[id], level = questLevel, objectives = objectives or {}, ready = ready, index = i }
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

local LEAD_IN = { ["goto"] = true, fly = true, getfp = true, boat = true }

local function buildRoute()
  local faction = try(UnitFactionGroup, "player")
  local _, raceToken = try(UnitRace, "player")
  local _, classToken = UnitClass("player")
  race, class = (raceToken or ""):upper(), classToken
  route = LevelingCodexQuests and LevelingCodexQuests[(faction or ""):upper()]
  sections, sectionsById, steps, startItems, flightHubs = {}, {}, {}, {}, {}
  questNames = {}
  if not route then return end
  for _, section in ipairs(route.sections) do
    -- start: nil = shared, a race token or a list; class: side sections for one class
    if matches(section.start, race) and matches(section.class, class) then
      sections[#sections + 1] = section
      sectionsById[section.id] = section
      local occurrences, arrived = {}, false
      for n, step in ipairs(section.steps) do
        if matches(step.class, class) and matches(step.race, race) then
          if step.quest and step.name then questNames[step.quest] = step.name end
          if step.startItem then startItems[step.startItem] = false end
          if step.type == "getfp" and step.map then flightHubs[step.map] = step end
          local action = step.type .. ":" .. (step.quest or n)
          occurrences[action] = (occurrences[action] or 0) + 1
          arrived = arrived or step.map == section.zone
          -- Travel before the section's first step in its own zone: the way there.
          local leadIn = not arrived and not step.quest and LEAD_IN[step.type]
          steps[#steps + 1] = { section = section, step = step, leadIn = leadIn,
            key = section.id .. ":" .. action .. ":" .. occurrences[action] }
        end
      end
    end
  end
end

local function levelFits(section)
  return level >= section.levels[1] and level <= section.levels[2]
end

-- An alternate is an opt-in route with its own end. Shared sections keep their
-- existing sequence, and an explicit catch-up prerequisite can cross routes.
local function follows(section, start)
  if section.side then return false end
  if start and start.alternate then return section == start end
  return not section.alternate
end

local function chooseSection()
  if selected then return end
  local map = Q.position()
  local active = {}
  for _, row in ipairs(steps) do
    if row.step.quest and log[row.step.quest] then active[row.section] = true end
  end
  local best
  for _, section in ipairs(sections) do
    if not section.side and levelFits(section) and
        (not section.alternate or section.zone == map or active[section]) then
      local score = (section.zone == map and 2 or 0) + (active[section] and 1 or 0)
      if not best or score > best then
        selected, best = section, score
      end
    end
  end
  if selected and level == 1 and route.starts[race] then
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
  local objective = entry and step.objectiveIndex and entry.objectives[step.objectiveIndex]
  return id and (turnedIn[id] or (step.type == "accept" and entry)
    or (step.type == "complete" and entry and (entry.ready or
      (objective and (objective.finished == true or objective.finished == 1)))))
end

local function prerequisitesMet(step)
  for _, id in ipairs(step.chain or {}) do
    if not turnedIn[id] then return false end
  end
  return true
end

-- The town your hearthstone is set to (GetBindLocation), nil when the client doesn't say.
function Q.bindLocation()
  local bind = try(GetBindLocation)
  return type(bind) == "string" and bind ~= "" and bind or nil
end

local function boundTo(town)
  local bind = Q.bindLocation()
  return bind and town and bind:lower() == town:lower()
end

local function state(row, skips, blockedQuests, later, map, x, y)
  local s = row.step
  if s.optional and not ns.db().questDungeons then return "filtered" end
  if row.section.side and ns.db().noClassQuests then return "filtered" end
  if s.type == "sethearth" then
    if ns.db().questSkipBind then return "filtered" end
    if boundTo(s.bind) then return "done" end
  end
  if s.quest then
    local entry = log[s.quest]
    if gameDone(s) then return "done" end
    if s.startItem and not entry and not startItems[s.startItem] then
      blockedQuests[s.quest] = "filtered"
      return "filtered"
    end
    local follow = s.breadcrumb
    if follow and not entry and (log[follow] or turnedIn[follow]) then return "skipped" end
    if blockedQuests[s.quest] then return blockedQuests[s.quest] end
    if not entry then
      for _, id in ipairs(s.chain or {}) do
        if blockedQuests[id] and not turnedIn[id] then
          blockedQuests[s.quest] = blockedQuests[id]
          return blockedQuests[id]
        end
      end
    end
  end
  if skips[row.key] then return "skipped" end
  -- Already in the section's zone: the way there no longer applies.
  if row.leadIn and not visited[row.key] and map == row.section.zone
      and not (s.type == "getfp" and knownFlights[s.flight]) then
    return "skipped"
  end
  if visited[row.key] then return "done" end
  if s.type == "grind" and s.level and level >= s.level then return "done" end
  if s.type == "getfp" and knownFlights[s.flight] then return "done" end
  if s.type == "goto" or s.type == "fly" then
    local _, dist = Q.vector(s, map, x, y)
    if dist and dist <= RADIUS then
      visited[row.key] = true
      return "done"
    end
    if later then return "done" end
  end
  return "pending"
end

-- Keep earlier pickups only if a remaining quest needs them. Reverse route
-- order visits a quest before its prerequisites and follows whole chains.
local function catchup(skips)
  local needed, deferred = {}, {}
  if not resumeAt then return needed, deferred end
  local start = steps[resumeAt].section
  for i = #steps, 1, -1 do
    local row = steps[i]
    local step = row.step
    if not row.section.side and step.type == "accept" and not gameDone(step) then
      if ((i >= resumeAt and follows(row.section, start)) or needed[step.quest]) and not skips[row.key]
          and (not step.optional or ns.db().questDungeons) then
        for _, id in ipairs(step.chain or {}) do
          if not turnedIn[id] then needed[id] = needed[id] or step end
        end
      elseif i < resumeAt and not needed[step.quest] then
        deferred[step.quest] = true
      end
    end
  end
  return needed, deferred
end

-- Zygor-style catch-up without a saved position: a quest you never picked up counts as
-- passed (Missed quests) once you have turned in a quest the route picks up after it in the
-- same section, unless a quest still ahead of you needs it. Walking the route backwards sees
-- what is still needed before reaching its prerequisites. Steps for a passed quest follow it.
local function markPassed()
  local progress, needs, passed = {}, {}, {}
  for i = #steps, 1, -1 do
    local row = steps[i]
    local s, sec = row.step, row.section
    if not sec.side and row.state == "pending" and s.quest and not log[s.quest] and not turnedIn[s.quest]
        and progress[sec] and not needs[s.quest] and s.type == "accept" then
      row.state, passed[s.quest] = "deferred", true
    end
    if not sec.side and row.state == "pending" and s.quest then
      for _, id in ipairs(s.chain or {}) do
        if not turnedIn[id] then needs[id] = true end
      end
    end
    if s.type == "accept" and not s.optional and turnedIn[s.quest] then progress[sec] = true end
  end
  for _, row in ipairs(steps) do
    local s = row.step
    if row.state == "pending" and s.quest and passed[s.quest] and not log[s.quest] then row.state = "deferred" end
  end
end

local function leaveClass()
  if review and steps[review].section == classSection then review = nil end
  classSection, classHistory, classSkips = nil, {}, {}
end

local function calculate()
  if ns.db().noClassQuests then
    if review and steps[review].section.side then review = nil end
    if classSection then leaveClass() end
  end
  local map, x, y = Q.position()
  if Q.inFlight() then x, y = nil, nil end
  local later, laterSeen = {}, {}
  for i = #steps, 1, -1 do
    local row = steps[i]
    later[i] = laterSeen[row.section]
    if not row.step.optional and gameDone(row.step) then laterSeen[row.section] = true end
  end
  local skips, blockedQuests, reached, seen = skipTable(), {}, false, {}
  local needed, deferred = catchup(skips)
  local fromSection = resumeAt and steps[resumeAt].section or selected
  local grey = try(GetQuestGreenRange) or (level < 40 and 5 + math.floor(level / 10) or 9)
  index, missed, ready = nil, {}, {}
  for i, row in ipairs(steps) do
    if row.section == fromSection then reached = true end
    row.state = state(row, row.section.side and classSkips or skips, blockedQuests, later[i], map, x, y)
    local s = row.step
    local entry = s.quest and log[s.quest]
    row.requiredFor = resumeAt and i < resumeAt and needed[s.quest] or nil
    if s.quest and row.state == "skipped" then blockedQuests[s.quest] = "skipped" end
    if not row.section.side and row.state == "pending" and resumeAt and (deferred[s.quest] or
        (i < resumeAt and not needed[s.quest] and not (reached and entry))) then
      row.state = "deferred"
    end
  end
  markPassed()
  reached = false
  local mainIndex, classIndex
  for i, row in ipairs(steps) do
    if row.section == fromSection then reached = true end
    local s = row.step
    local entry = s.quest and log[s.quest]
    if row.state == "pending" then
      if row.section.side then
        if row.section == classSection and not classIndex then classIndex = i end
      elseif not mainIndex and ((reached and follows(row.section, fromSection)) or needed[s.quest]) then
        mainIndex = i
      end
    end
    if s.type == "turnin" and entry and entry.ready and not turnedIn[s.quest] and row.state ~= "filtered" then
      ready[#ready + 1] = row
    end
    local side = row.section.side
    local elsewhere = side and row.section ~= classSection or not side and fromSection
      and (not reached or row.state == "deferred")
    if elsewhere and s.type == "accept" and not turnedIn[s.quest]
        and not entry and row.state ~= "filtered" and not seen[s.quest] and level >= (s.min or 1)
        and (not side or (row.state == "pending" and not seen[row.section] and prerequisitesMet(s)))
        and (side or not s.level or s.level > level - grey) then
      missed[#missed + 1], seen[s.quest] = row, true
      if side then seen[row.section] = true end
    end
  end
  if classSection and not classIndex then
    leaveClass()
    return calculate() -- restore temporarily skipped rows to the browser and pickup queue
  end
  index = classIndex or mainIndex
  if mainIndex then selected = steps[mainIndex].section end
end

-- Known flight paths. The classic client only lists them while the flight map is
-- open, so remember what it showed (charDB, if it loads back) and ask the retail
-- world-map API once per session when Forever has it.
local function flightStore()
  local db = ns.charDB()
  db.questFlights = db.questFlights or {}
  return db.questFlights
end

local function rememberFlight(name, known)
  knownFlights[name] = known or nil
  flightStore()[name] = known or nil
end

local CONTINENTS = { 1415, 1414 }
local probed, probeCount
local function probeFlights()
  probed = true
  for name in pairs(flightStore()) do knownFlights[name] = true end
  local api = C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap
  if type(api) ~= "function" then return end
  probeCount = 0
  for _, map in ipairs(CONTINENTS) do
    local nodes = try(api, map)
    for _, node in ipairs(type(nodes) == "table" and nodes or {}) do
      local known = type(node) == "table" and (node.isUndiscovered == false or
        (node.isUndiscovered == nil and (node.state == 0 or node.state == 1)))
      if known and type(node.name) == "string" then
        knownFlights[node.name], probeCount = true, probeCount + 1
      end
    end
  end
end

function Q.flightDebug()
  local n = 0
  for _ in pairs(knownFlights) do n = n + 1 end
  return n, probeCount
end

local function readStartItems()
  local changed = false
  for item, hadItem in pairs(startItems) do
    local hasItem = Q.itemCount(item) > 0
    if hasItem ~= hadItem then
      startItems[item], changed = hasItem, true
    end
  end
  return changed
end

function Q.bagsChanged()
  if not readStartItems() then return false end
  calculate()
  return true
end

function Q.update(event, id, newLevel)
  if event == "PLAYER_LEAVING_WORLD" then inWorld = false; return end
  if event == "PLAYER_ENTERING_WORLD" then inWorld = true end
  if not route then buildRoute() end
  if not probed then probeFlights() end
  level = newLevel or UnitLevel("player") or 1
  if event == "QUEST_TURNED_IN" and id then liveDone[id] = true end
  if event == "QUEST_REMOVED" and id then
    removed[id] = true
    for _, row in ipairs(steps) do
      if row.step.quest == id then visited[row.key] = nil end
    end
  end
  if event == "QUEST_ACCEPTED" and id then removed[id] = nil end
  readLog()
  readCompleted()
  readStartItems()
  chooseSection()
  calculate()
  if event == "QUEST_TURNED_IN" and review and steps[review].step.quest == id then review = nil end
end

function Q.current()
  local i = review or index
  return i and steps[i], i
end

function Q.rows() return steps, sections, missed, level or UnitLevel("player"), classSection or selected, ready end
function Q.log(id) return log[id] end
function Q.logEntries() return log end
function Q.incomplete(id)
  local entry = log[id]
  if entry and not entry.ready and not turnedIn[id] then return entry end
end
function Q.arrived() return RADIUS end

function Q.suggested()
  if classSection or review then return end
  local row = index and steps[index]
  local suggestions = row and row.step.suggest or (not row and selected and selected.suggest)
  for _, id in ipairs(suggestions or {}) do
    local section = sectionsById[id]
    if section and levelFits(section) then
      for _, candidate in ipairs(steps) do
        local s = candidate.step
        if candidate.section == section and (candidate.state == "pending" or candidate.state == "deferred") and s.quest
            and (log[s.quest] or (s.type == "accept" and level >= (s.min or 1))) then
          return section
        end
      end
    end
  end
end

function Q.destination(step, map)
  if not (step and step.map and map) or step.map == map then return step end
  if step.type == "hearth" and boundTo(step.bind) then return nil, "Hearth to " .. step.bind end
  local network = route.flightNetwork
  local origin, target = flightHubs[map], flightHubs[step.map]
  local links = origin and flightLinks[origin.flight]
  if origin and target and network and network[map] and network[map] == network[step.map]
      and (not links or links[target.flight] == "REACHABLE")
      and knownFlights[origin.flight] and knownFlights[target.flight] then
    return origin, "Fly to " .. target.flight:match("^[^,]+")
  end
  local roads = route.roadTo and route.roadTo[step.map]
  local road = roads and roads[map]
  if road then return road.waypoint, road.label end
  local info = try(C_Map and C_Map.GetMapInfo, step.map)
  local name = type(info) == "table" and info.name or step.flight
  return step, name and ("Travel to " .. Q.plain(name)) or "Objective in another zone"
end

function Q.upcoming(i)
  local result = {}
  local section = steps[i].section
  local start = resumeAt and steps[resumeAt].section or section
  for n = i + 1, #steps do
    local row = steps[n]
    if section.side and row.section ~= section then break end
    if row.state == "pending" and (row.section == section or
        follows(row.section, start) or row.requiredFor) then
      result[#result + 1] = row
      if #result == 2 then break end
    end
  end
  return result
end

local function hasMoreObjectives(row, i)
  if row.step.type ~= "complete" then return false end
  for n = i + 1, #steps do
    local nextRow = steps[n]
    if nextRow.section ~= row.section then return false end
    if nextRow.step.quest and nextRow.state ~= "filtered" then
      return nextRow.step.quest == row.step.quest and nextRow.step.type == "complete"
    end
  end
  return false
end

function Q.next()
  local row, i = Q.current()
  if not row then return end
  local manual = not review
  if review then
    repeat i = i + 1 until not steps[i] or steps[i].state ~= "filtered"
    local sameSection = steps[i] and steps[i].section == row.section
    review = index and i < index and (sameSection or (not row.section.side and not classSection
      and follows(steps[i].section, selected))) and i or nil
  elseif hasMoreObjectives(row, i) then
    visited[row.key] = true
  elseif row.step.quest or row.step.type == "dungeon" then
    local skips = row.section.side and classSkips or skipTable()
    skips[row.key] = true
  else
    if row.step.type == "getfp" then rememberFlight(row.step.flight, true) end
    visited[row.key] = true
  end
  calculate()
  if manual and (not row.section.side or classSection) then
    local trail = classSection and classHistory or history
    trail[#trail + 1] = { from = i, to = index }
  end
end

function Q.back()
  if review and (classSection or steps[review].section.side) and steps[review].section ~= classSection then
    review = nil
    return
  end
  local i = (review or index or (#steps + 1)) - 1
  local trail = classSection and classHistory or history
  local previous = trail[#trail]
  if not review and previous and previous.to == index then
    i = previous.from
    table.remove(trail)
  else
    local start = resumeAt and steps[resumeAt].section or selected
    while steps[i] and (steps[i].state == "filtered" or steps[i].state == "skipped" or
        (not classSection and not follows(steps[i].section, start) and not steps[i].requiredFor)) do i = i - 1 end
  end
  local row = steps[i]
  if classSection and (not row or row.section ~= classSection) then return end
  if row and row.section.side and row.section ~= classSection then return end
  if row then
    if row.step.type == "getfp" and not row.section.side then rememberFlight(row.step.flight, false) end
    local skips = row.section.side and classSkips or skipTable()
    skips[row.key], visited[row.key] = nil, nil
    if not classSection then selected = row.section end
    review = i
    calculate()
    if review == index then review = nil end
  end
end

function Q.jump(section, row)
  if section.side and ns.db().noClassQuests then return end
  if row then
    for i, candidate in ipairs(steps) do
      if candidate == row then review = i ~= index and i or nil; return end
    end
  elseif section.side then
    classSection, review, classHistory, classSkips = section, nil, {}, {}
    calculate()
  elseif classSection and section == selected then
    Q.returnToRoute()
  else
    leaveClass()
    selected, review, resumeAt, history = section, nil, nil, {}
    calculate()
  end
end

function Q.returnToRoute()
  leaveClass()
  review = nil
  calculate()
end

function Q.resumeActive(section)
  local map = Q.position()
  local best, score
  for i, row in ipairs(steps) do
    local s = row.step
    local entry = s.quest and log[s.quest]
    if not row.section.side and (not section or row.section == section) and entry
        and (row.state == "pending" or row.state == "deferred")
        and (s.type == "complete" or (s.type == "turnin" and entry.ready)) then
      local rank = (map and s.map == map and 4 or 0)
        + (map and row.section.zone == map and 2 or 0) + (row.section == selected and 1 or 0)
      if not score or rank > score then best, score = i, rank end
    end
  end
  if not best then return end
  selected, resumeAt, review, history = steps[best].section, best, nil, {}
  calculate()
  return true
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

function Q.learnFlights(nodes)
  for name, state in pairs(nodes) do
    if state == "CURRENT" then flightLinks[name] = nodes end
    if state == "CURRENT" or state == "REACHABLE" then rememberFlight(name, true) end
  end
  calculate()
end

function Q.checkArrival()
  local row = not review and index and steps[index]
  if row and ARRIVAL[row.step.type] and not Q.inFlight() then
    local _, dist = Q.vector(row.step, Q.position())
    if dist and dist <= RADIUS then
      visited[row.key] = true
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
  if step.type == "sethearth" or step.type == "hearth" then
    local bind = Q.bindLocation()
    if not step.bind then return step.text end
    local atTarget = bind and bind:lower() == step.bind:lower()
    if step.type == "sethearth" then
      if not bind then return step.text end
      if atTarget then return "Your hearthstone is already set to " .. bind .. "." end
      return step.text .. " Your hearthstone is set to " .. bind .. ". Skip this step to keep your current bind."
    end
    if atTarget then return step.text .. " Use your hearthstone if it's ready." end
    if not bind then return step.text .. " Use your hearthstone if you're bound there and it's ready." end
    return step.text .. " Your hearthstone is set to " .. bind .. "."
  end
  if step.type ~= "train" then return step.text end
  local visit = ns.trainAt(step.level or level) or ns.nextTrain((step.level or level) - 1)
  if not visit then return step.text .. " " .. tostring(step.level or level) .. "." end
  return ns.plain(step.text .. " " .. visit.level .. ": " .. table.concat(visit.spells, ", "))
end
