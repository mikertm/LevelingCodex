-- Quest state comes from the game. Only manual acknowledgements need SavedVariables.
local _, ns = ...
local Q = {}
ns.quests = Q

local function result(ok, ...)
  if ok then return ... end
  return nil -- a missing or failing API reads as nil (tonumber(try(...)) stays safe)
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
local sideSection
local sideFrom, sideResumeAt
local history, sideHistory, sideSkips = {}, {}, {}
local route, race, class
local sections, sectionsById, steps, missed, ready = {}, {}, {}, {}, {}
local startItems = {}
local collectItems = {} -- item -> last count, for collect and buy steps
local runOwn = {} -- run -> quests a route step ties to it (forDungeon): the ones that need the dungeon
local killed = {} -- boss row key -> true: bosses down this dungeon visit
local inInstance, lastInstance -- the dungeon you're in now (instance ID), and the last one you entered
local questNames = {}
local greyRows = {} -- outleveled pickups this pass
local chainBefore, chainAfter, runQuests, questRun = {}, {}, {}, {}
local index, level, resumeAt
local inWorld = true
local lastZone, checkLocalOnLog
local RADIUS = 35
local ARRIVAL = { ["goto"] = true, fly = true, hearth = true }
local PHASE = { prepare = 1, inside = 2, after = 3 }

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

-- Your corpse while you are a ghost: { map, x, y } on your current map, {} when the client
-- doesn't say where it is (or it's on another map), nil while alive.
function Q.corpse()
  local ghost = try(UnitIsGhost, "player")
  if ghost ~= true and ghost ~= 1 then return end
  local map = Q.position()
  local pos = map and try(C_DeathInfo and C_DeathInfo.GetCorpseMapPosition, map)
  local x, y = type(pos) == "table" and pos.x, type(pos) == "table" and pos.y
  if type(pos) == "table" and type(pos.GetXY) == "function" then x, y = try(pos.GetXY, pos) end
  if type(x) == "number" and type(y) == "number" and (x > 0 or y > 0) then
    return { map = map, x = x * 100, y = y * 100 }
  end
  return {}
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
      local complete, readyForTurnIn
      local ready = done == true or done == 1
      if not ready then
        complete = try(C_QuestLog and C_QuestLog.IsComplete, id)
        if complete ~= true then readyForTurnIn = try(C_QuestLog and C_QuestLog.ReadyForTurnIn, id) end
        ready = complete == true or readyForTurnIn == true
      end
      if not ready and objectives and #objectives > 0 then
        ready = true
        for _, row in ipairs(objectives) do
          if row.finished ~= true and row.finished ~= 1 then ready = false; break end
        end
      end
      local readyKnown = done ~= nil or complete ~= nil or readyForTurnIn ~= nil or (objectives and #objectives > 0)
      newLog[id] = { title = title or questNames[id], level = questLevel, objectives = objectives or {},
        ready = ready, readyKnown = readyKnown, index = i }
    end
  end
  log = newLog
end

local function readCompleted()
  turnedIn = {}
  if #steps == 0 then return end
  local completed = {}
  local ids = try(C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs)
  if type(ids) == "table" then
    for _, id in ipairs(ids) do completed[id] = true end
  end
  local legacy = {}
  local value = try(GetQuestsCompleted, legacy)
  if type(value) == "table" then legacy = value end
  local function check(id)
    if not id or turnedIn[id] ~= nil then return end
    if liveDone[id] or completed[id] or legacy[id] then turnedIn[id] = true; return end
    local done = try(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, id)
    if done ~= true and done ~= 1 then done = try(IsQuestFlaggedCompleted, id) end
    turnedIn[id] = done == true or done == 1
  end
  for _, row in ipairs(steps) do
    check(row.step.quest)
    check(row.step.breadcrumb)
    check(row.step.ifDone)
    check(row.step.unlessDone)
    for _, id in ipairs(row.step.chain or {}) do check(id) end
  end
end

local function matches(rule, token)
  if type(rule) == "table" then
    for _, v in ipairs(rule) do if v == token then return true end end
    return false
  end
  return not rule or rule == token
end

local function sideHidden(section)
  return section.side and not section.category and ns.db().noClassQuests
end

-- Dungeon plans (you choose your dungeons): a route step tagged
-- `dungeon = "<detour id>"` shows only while that run is planned. `db.questDungeons`
-- plans every run; a per-dungeon choice overrides it. Without SavedVariables nothing is planned.
local function planTable()
  local db = ns.db()
  if type(db.questDungeonPlan) ~= "table" then db.questDungeonPlan = {} end
  return db.questDungeonPlan
end

function Q.planned(id)
  local choice = planTable()[id]
  if choice ~= nil then return choice == true end
  return ns.db().questDungeons == true
end

function Q.setPlanned(id, on)
  planTable()[id] = on and true or false
end

-- You chose for this run (planned or skipped it), or Plan every dungeon run is on.
function Q.planDecided(id)
  return planTable()[id] ~= nil or ns.db().questDungeons == true
end

-- Optional steps: dungeon pickups follow the plan, the rest (profession intros, errands) a setting.
-- `logOnly` steps (work on a quest picked up elsewhere) show only while it is in the log.
-- An optional objective or turn-in needs the quest: one you don't have (a carried breadcrumb
-- such as Unrequited Love, or a pickup you skipped) never shows, whatever the setting.
local function included(step)
  if step.logOnly then return step.quest ~= nil and log[step.quest] ~= nil end
  if not step.optional or (step.quest and log[step.quest]) then return true end
  if step.quest and (step.type == "turnin" or step.type == "complete") and not turnedIn[step.quest] then
    return false
  end
  if step.dungeon then return Q.planned(step.dungeon) end
  return ns.db().questOptional == true
end

local LEAD_IN = { ["goto"] = true, fly = true, getfp = true, boat = true }

-- A dungeon run's bosses (`bosses`) as steps of type "boss" in the inside phase: after its last
-- inside step, else before its first after step. Its quest objectives inside show beside them
-- as "On the way" lines (row.sticky) instead of being steps of their own.
local function addBossRows(section, first)
  local lastInside, firstAfter
  for i = first, #steps do
    local s = steps[i].step
    if s.phase == "inside" then lastInside = i end
    if s.phase == "after" and not firstAfter then firstAfter = i end
    if s.phase == "inside" and s.type == "complete" then steps[i].sticky = true end
  end
  local at = lastInside and lastInside + 1 or firstAfter or #steps + 1
  local pos = steps[at - 1] and steps[at - 1].section == section and steps[at - 1].pos or 0
  for n, boss in ipairs(section.bosses) do
    table.insert(steps, at + n - 1, { section = section, pos = pos, key = section.id .. ":boss:" .. n,
      step = { type = "boss", name = boss.name, text = boss.tip, npc = boss.npc, encounter = boss.encounter,
        phase = "inside" } })
  end
end

local function buildRoute()
  local faction = try(UnitFactionGroup, "player")
  local _, raceToken = try(UnitRace, "player")
  local _, classToken = UnitClass("player")
  race, class = (raceToken or ""):upper(), classToken
  route = LevelingCodexQuests and LevelingCodexQuests[(faction or ""):upper()]
  sections, sectionsById, steps, startItems, flightHubs, collectItems = {}, {}, {}, {}, {}, {}
  questNames, chainBefore, chainAfter, runQuests, questRun = {}, {}, {}, {}, {}
  if not route then return end
  for _, section in ipairs(route.sections) do
    -- start: nil = shared, a race token or a list; class: side sections for one class
    if matches(section.start, race) and matches(section.class, class) then
      sections[#sections + 1] = section
      sectionsById[section.id] = section
      local occurrences, arrived = {}, false
      local first = #steps + 1
      for n, step in ipairs(section.steps) do
        if matches(step.class, class) and matches(step.race, race) then
          if step.quest and step.name then questNames[step.quest] = step.name end
          if step.quest then
            -- A story chain: links where a quest has exactly one prerequisite and one follow-up.
            local pre = step.chain and #step.chain == 1 and step.chain[1]
            if pre and pre ~= step.quest and chainBefore[step.quest] == nil then
              chainBefore[step.quest] = pre
              local after = chainAfter[pre]
              if after == nil then chainAfter[pre] = step.quest
              elseif after ~= step.quest then chainAfter[pre] = false end
            end
            local run = step.dungeon or (section.category == "dungeon" and section.id)
            if run then
              runQuests[run] = runQuests[run] or {}
              runQuests[run][step.quest] = true
              questRun[step.quest] = questRun[step.quest] or run
            end
          end
          if step.startItem then startItems[step.startItem] = false end
          if (step.type == "collect" or step.type == "buy") and step.item then collectItems[step.item] = -1 end
          if step.type == "getfp" and step.map then flightHubs[step.map] = step end
          local action = step.type .. ":" .. (step.quest or n)
          occurrences[action] = (occurrences[action] or 0) + 1
          arrived = arrived or step.map == section.zone
          -- Travel before the section's first step in its own zone: the way there.
          local leadIn = not arrived and not step.quest and LEAD_IN[step.type]
          steps[#steps + 1] = { section = section, step = step, leadIn = leadIn, pos = n,
            key = section.id .. ":" .. action .. ":" .. occurrences[action] }
        end
      end
      if section.category == "dungeon" and type(section.bosses) == "table" and #section.bosses > 0 then
        addBossRows(section, first)
      end
    end
  end
  -- Dungeon ahead: before the route's first step for a run (a step tagged for it, or the pickup
  -- of a quest a tagged step finishes inside), a step asks whether to plan the run (Q.planText).
  -- Lead-in chains the run's checklist also lists (the Defias Brotherhood) don't count.
  runOwn = {}
  for _, row in ipairs(steps) do
    local s = row.step
    if s.dungeon and s.quest and not row.section.side then
      runOwn[s.dungeon] = runOwn[s.dungeon] or {}
      runOwn[s.dungeon][s.quest] = true
    end
  end
  local asked, withChoices = {}, {}
  for _, row in ipairs(steps) do
    local s = row.step
    local run = s.dungeon
    if not run and s.type == "accept" then
      for id, quests in pairs(runOwn) do
        if quests[s.quest] then run = id end
      end
    end
    run = not row.section.side and run
    local runSection = run and sectionsById[run]
    if runSection and runSection.category == "dungeon" and not asked[run] then
      asked[run] = true
      withChoices[#withChoices + 1] = { section = row.section, pos = row.pos, key = row.section.id .. ":plan:" .. run,
        step = { type = "plan", dungeon = run, name = runSection.title, map = s.map, x = s.x, y = s.y } }
    end
    withChoices[#withChoices + 1] = row
  end
  steps = withChoices
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
  local active, progressed = {}, {}
  for _, row in ipairs(steps) do
    local s = row.step
    if s.quest and included(s) then
      if log[s.quest] then active[row.section] = true end
      if s.type == "accept" and turnedIn[s.quest] then progressed[row.section] = true end
    end
  end
  local best
  for _, section in ipairs(sections) do
    if not section.side and levelFits(section) and
        (not section.alternate or active[section] or (not section.manual and section.zone == map)) then
      local score = (section.zone == map and 4 or 0) + (active[section] and 2 or 0)
        + (progressed[section] and 1 or 0)
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

local function inDungeon(section)
  if not section.instanceID then return false end
  local name, kind, _, _, _, _, _, instanceID = try(GetInstanceInfo)
  if kind ~= "party" then return false end
  if type(instanceID) == "number" and instanceID > 0 then return instanceID == section.instanceID end
  return name == (section.instance or section.title)
end

local function awaitingObjectives(step, entry)
  return entry and entry.readyKnown and not entry.ready and step.phase == "after" and step.type == "turnin"
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
Q.boundTo = boundTo

-- Your XP into this level, the level's total and rested XP (nil when the client doesn't say).
function Q.xp()
  local cur, max = tonumber(try(UnitXP, "player")), tonumber(try(UnitXPMax, "player"))
  if cur and max and max > 0 then return cur, max, tonumber(try(GetXPExhaustion)) or 0 end
end

-- A grind step's `xp` is a share of its level (0.4 = level 15 and 40%). Without XP from the
-- client, reaching the level counts.
local function grindReached(step)
  if not step.xp then return true end
  local cur, max = Q.xp()
  return not cur or cur / max >= step.xp
end

-- Step gates: `maxLevel` (skipped above it), `profession` + optional `skill` (filtered without the
-- profession, blocked below the skill), `ifOnQuest` (only while that quest is in your log),
-- `ifDone` (only once it's turned in) and `unlessDone` (skipped once it's turned in).
local function gated(s)
  if s.maxLevel and level > s.maxLevel then return "skipped" end
  if s.profession and ns.profSkill then
    local skill, _, unseen = ns.profSkill(s.profession)
    if not unseen then
      if not skill then return "filtered" end
      if s.skill and skill < s.skill then return "blocked" end
    end
  end
  if s.ifOnQuest and not log[s.ifOnQuest] then return "filtered" end
  if s.ifDone and not turnedIn[s.ifDone] then return "filtered" end
  if s.unlessDone and turnedIn[s.unlessDone] then return "skipped" end
end

-- Items a collect or buy step wants: done once your bags hold `count` (default 1).
local function haveItems(s)
  return s.item and Q.itemCount(s.item) >= (s.count or 1)
end

local function state(row, skips, blockedQuests, later, map, x, y)
  local s = row.step
  if s.type == "plan" then
    -- Asked until you choose, unless you're already past it here, did the run or outleveled it.
    local run = sectionsById[s.dungeon]
    if Q.planDecided(s.dungeon) or later or not run or sideHidden(run) or level > run.levels[2] then
      return "filtered"
    end
    for id in pairs(runOwn[s.dungeon] or {}) do
      if turnedIn[id] then return "filtered" end
    end
    return "pending"
  end
  if row.section.category ~= "dungeon" and not included(s) then return "filtered" end
  if sideHidden(row.section) then return "filtered" end
  if s.type == "boss" then
    -- Down (or passed with Next) this visit; only shown while you're in its dungeon.
    if killed[row.key] or visited[row.key] then return "done" end
    if skips[row.key] then return "skipped" end
    return inDungeon(row.section) and "pending" or "filtered"
  end
  local gate = gated(s)
  if gate then return gate end
  if s.type == "abandon" and not (s.quest and log[s.quest]) then return "done" end
  if (s.type == "collect" or s.type == "buy") and s.item then
    if (s.quest and turnedIn[s.quest]) or haveItems(s) then
      visited[row.key] = true -- keep it done when the items get used up later
      return "done"
    end
  end
  if s.type == "sethearth" then
    if ns.db().questSkipBind then return "filtered" end
    if boundTo(s.bind) then return "done" end
  end
  if s.type == "getfp" and knownFlights[s.flight] then return "done" end
  if s.type == "dungeon" and row.section.category == "dungeon" and inDungeon(row.section) then return "done" end
  if s.quest then
    local entry = log[s.quest]
    if gameDone(s) then return "done" end
    if awaitingObjectives(s, entry) then return "blocked" end
    local follow = s.breadcrumb
    if follow and not entry and (log[follow] or turnedIn[follow]) then return "skipped" end
    if s.startItem and not entry and not startItems[s.startItem] then
      local unavailable = row.section.category and "blocked" or "filtered"
      blockedQuests[s.quest] = unavailable
      return unavailable
    end
    if blockedQuests[s.quest] then return blockedQuests[s.quest] end
    if not entry then
      if row.section.category and s.min and level < s.min then return "blocked" end
      for _, id in ipairs(s.chain or {}) do
        if blockedQuests[id] and not turnedIn[id] then
          blockedQuests[s.quest] = blockedQuests[id]
          return blockedQuests[id]
        end
      end
      if row.section.category and s.type == "accept" and not prerequisitesMet(s) then
        blockedQuests[s.quest] = "blocked"
        return "blocked"
      end
      if row.section.category and s.type ~= "accept" then return "blocked" end
    end
  end
  if skips[row.key] then return "skipped" end
  -- Already in the section's zone: the way there no longer applies.
  if row.leadIn and not visited[row.key] and map == row.section.zone then
    return "skipped"
  end
  if visited[row.key] then return "done" end
  if s.type == "grind" and s.level and (level > s.level or (level == s.level and grindReached(s))) then
    return "done"
  end
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
-- order visits a quest before its prerequisites and follows whole chains, but only within a
-- zone: a prerequisite picked up in another zone is kept only if you could take it now. A chain
-- you skipped elsewhere is cut (with everything after it) instead of sending you back there.
local function catchup(skips)
  local needed, deferred, cut = {}, {}, {}
  if not resumeAt then return needed, deferred, cut end
  local start = steps[resumeAt].section
  local pickup = {}
  for _, row in ipairs(steps) do
    local s = row.step
    if not row.section.side and s.type == "accept" and s.quest and not pickup[s.quest] then pickup[s.quest] = row end
  end
  local function takeable(id)
    local from = pickup[id]
    if not from then return false end
    for _, pre in ipairs(from.step.chain or {}) do
      if not turnedIn[pre] and not log[pre] then return false end
    end
    return true
  end
  for i = #steps, 1, -1 do
    local row = steps[i]
    local step = row.step
    if not row.section.side and step.type == "accept" and not gameDone(step) then
      if ((i >= resumeAt and follows(row.section, start)) or needed[step.quest]) and not skips[row.key]
          and included(step) then
        for _, id in ipairs(step.chain or {}) do
          if not turnedIn[id] then
            local from = pickup[id]
            if log[id] or (from and (from.section.zone == row.section.zone or takeable(id))) then
              needed[id] = needed[id] or step
            else
              cut[step.quest] = true
            end
          end
        end
      elseif i < resumeAt and not needed[step.quest] then
        deferred[step.quest] = true
      end
    end
  end
  -- Whatever follows a cut quest is cut too, and a cut quest isn't needed any more.
  for _, row in ipairs(steps) do
    local s = row.step
    if not row.section.side and s.type == "accept" and not log[s.quest] and not turnedIn[s.quest] then
      for _, id in ipairs(s.chain or {}) do
        if cut[id] and not turnedIn[id] and not log[id] then cut[s.quest] = true end
      end
    end
  end
  for id in pairs(cut) do needed[id] = nil end
  return needed, deferred, cut
end

-- Catch-up without a saved position: a quest you never picked up counts as
-- passed (Missed quests) once you have turned in a quest the route picks up after it in the
-- same section, unless a quest still ahead of you needs it. Walking the route backwards sees
-- what is still needed before reaching its prerequisites. Earlier setup can be reviewed too.
-- A quest two leveling sections pick up counts as progress only for the lower-level one: the
-- 20-25 Wetlands chapter turns in quests the 26-30 route also has, which says you walked the
-- early chapter, not the 26-30 route's own earlier pickups.
local function markPassed()
  local progress, needs, passed, owner = {}, {}, {}, {}
  for _, row in ipairs(steps) do
    local s, sec = row.step, row.section
    if not sec.side and s.type == "accept" and s.quest then
      local had = owner[s.quest]
      if not had or (sec.levels and had.levels and sec.levels[1] < had.levels[1]) then owner[s.quest] = sec end
    end
  end
  for i = #steps, 1, -1 do
    local row = steps[i]
    local s, sec = row.step, row.section
    if not sec.side and row.state == "pending" and progress[sec] then
      if s.type == "accept" and not log[s.quest] and not needs[s.quest] then
        passed[sec] = passed[sec] or {}
        row.state, passed[sec][s.quest] = "deferred", true
      elseif s.type == "sethearth" or s.type == "hearth" or s.type == "train"
          or (sec.alternate and s.type == "getfp") then
        row.state = "deferred"
      end
    end
    if not sec.side and row.state == "pending" and s.quest then
      for _, id in ipairs(s.chain or {}) do
        if not turnedIn[id] then needs[id] = true end
      end
    end
    if s.type == "accept" and not s.optional and turnedIn[s.quest] and owner[s.quest] == sec then progress[sec] = true end
  end
  for _, row in ipairs(steps) do
    local s = row.step
    local skippedHere = passed[row.section]
    if skippedHere and row.state == "pending" and s.quest and skippedHere[s.quest] and not log[s.quest] then
      row.state = "deferred"
    end
  end
end

-- Outleveled pickups: a leveling pickup that has gone
-- grey leaves the route, with the rest of its steps, unless a quest still ahead needs it. Walking
-- backwards sees every later quest's prerequisites before reaching them. Settings > Keep grey
-- quests in the route turns this off.
local function markGrey(grey)
  greyRows = {}
  if ns.db().questKeepGrey or not level then return end
  local candidate, needs, dropped = {}, {}, {}
  for _, row in ipairs(steps) do
    local s = row.step
    if not row.section.side and s.type == "accept" and row.state == "pending" and s.level
        and s.level <= level - grey and not log[s.quest] and not turnedIn[s.quest] then
      candidate[s.quest] = true
    end
  end
  for i = #steps, 1, -1 do
    local row = steps[i]
    local s = row.step
    if not row.section.side and s.quest and (row.state == "pending" or row.state == "deferred") then
      if candidate[s.quest] and not needs[s.quest] then
        dropped[s.quest] = true
      elseif row.state == "pending" then
        for _, id in ipairs(s.chain or {}) do
          if not turnedIn[id] then needs[id] = true end
        end
      end
    end
  end
  for _, row in ipairs(steps) do
    local s = row.step
    if dropped[s.quest] and not row.section.side and (row.state == "pending" or row.state == "deferred") then
      row.state, row.grey = "deferred", true
      if s.type == "accept" then greyRows[#greyRows + 1] = row end
    else
      row.grey = nil
    end
  end
end

local function leaveSide()
  if review and steps[review].section == sideSection then review = nil end
  sideSection, sideFrom, sideResumeAt, sideHistory, sideSkips = nil, nil, nil, {}, {}
end

-- How far below your level a quest goes grey (the client's own range when it says).
local function greyRange()
  return try(GetQuestGreenRange) or (level < 40 and 5 + math.floor(level / 10) or 9)
end

local function calculate()
  if review and sideHidden(steps[review].section) then review = nil end
  if sideSection and sideHidden(sideSection) then leaveSide() end
  local map, x, y = Q.position()
  if Q.inFlight() then x, y = nil, nil end
  local later, laterSeen = {}, {}
  for i = #steps, 1, -1 do
    local row = steps[i]
    later[i] = laterSeen[row.section]
    if not row.step.optional and gameDone(row.step) then laterSeen[row.section] = true end
  end
  local skips, blockedQuests, sectionBlocked, reached, seen = skipTable(), {}, {}, false, {}
  local needed, deferred, cut = catchup(skips)
  local fromSection = resumeAt and steps[resumeAt].section or selected
  local grey = greyRange()
  index, missed, ready = nil, {}, {}
  for i, row in ipairs(steps) do
    if row.section == fromSection then reached = true end
    local blocked = blockedQuests
    if row.section.side or row.section.alternate then
      sectionBlocked[row.section] = sectionBlocked[row.section] or {}
      blocked = sectionBlocked[row.section]
    end
    row.state = state(row, row.section.side and sideSkips or skips, blocked, later[i], map, x, y)
    local s = row.step
    local entry = s.quest and log[s.quest]
    row.requiredFor = resumeAt and i < resumeAt and needed[s.quest] or nil
    if s.quest and row.state == "skipped" then blocked[s.quest] = "skipped" end
    if not row.section.side and row.state == "pending" and resumeAt and (deferred[s.quest] or
        (i < resumeAt and not needed[s.quest] and not (reached and entry))) then
      row.state = "deferred"
    end
    row.cut = nil
    if cut[s.quest] and not row.section.side and not entry and not turnedIn[s.quest]
        and (row.state == "pending" or row.state == "deferred") then
      row.state, row.cut = "deferred", true
    end
  end
  markPassed()
  markGrey(grey)
  reached = false
  local mainIndex, sideIndex, away
  local readySeen = {}
  -- A kept prerequisite in another zone waits until the route reaches the quest that needs it.
  local function here(row)
    return not map or row.step.map == map or (not row.step.map and row.section.zone == map)
  end
  -- Rows the route walks past instead of stopping at: a sticky goal (it shows beside the steps
  -- after it) and a step whose `skipOn` map you're already on (it counts as done from then on).
  local function passOver(row)
    if row.step.sticky or row.sticky then return true end
    if row.step.skipOn and map and matches(row.step.skipOn, map) then
      visited[row.key], row.state = true, "done"
      return true
    end
  end
  for i, row in ipairs(steps) do
    if row.section == fromSection then reached = true end
    local s = row.step
    local entry = s.quest and log[s.quest]
    if row.state == "pending" then
      if row.section.side then
        if row.section == sideSection and not sideIndex and i >= sideResumeAt and (PHASE[s.phase] or 1) >= sideFrom
            and not passOver(row) then
          sideIndex = i
        end
      elseif not mainIndex then
        local onRoute = reached and follows(row.section, fromSection)
        local early = resumeAt and i < resumeAt
        if onRoute and not early then
          if not passOver(row) then
            mainIndex = (away and s.type == "accept" and not entry and not prerequisitesMet(s)) and away or i
          end
        elseif (needed[s.quest] or onRoute) and not s.sticky then
          if here(row) then mainIndex = i else away = away or i end
        end
      end
    end
    if s.type == "turnin" and entry and entry.ready and not turnedIn[s.quest] and row.state ~= "filtered"
        and not readySeen[s.quest] then
      ready[#ready + 1] = row
      readySeen[s.quest] = true
    end
    local side = row.section.side
    local elsewhere = side and row.section ~= sideSection or not side and fromSection
      and (not reached or row.state == "deferred")
    if elsewhere and s.type == "accept" and not turnedIn[s.quest] and not row.cut
        and not entry and row.state ~= "filtered" and not seen[s.quest] and level >= (s.min or 1)
        and (not side or (not row.section.category and row.state == "pending" and not seen[row.section] and prerequisitesMet(s)))
        and (side or not s.level or s.level > level - grey) then
      missed[#missed + 1], seen[s.quest] = row, true
      if side then seen[row.section] = true end
    end
  end
  if sideSection and not sideIndex then
    leaveSide()
    return calculate() -- restore temporarily skipped rows to the browser and pickup queue
  end
  index = sideIndex or mainIndex
  if mainIndex then selected = steps[mainIndex].section end
end

-- Sticky goals (`sticky = true`) the route has passed in the current step's section and that
-- aren't done yet: they show under the current step until they finish or the section ends.
function Q.stickies()
  local result = {}
  local i = review or index
  local row = i and steps[i]
  if not row then return result end
  for n = 1, i - 1 do
    local other = steps[n]
    if other.section == row.section and (other.step.sticky or other.sticky) and other.state == "pending" then
      result[#result + 1] = other
    end
  end
  return result
end

-- Seconds until the Hearthstone is ready: 0 = ready, nil = the client doesn't say.
function Q.hearthCooldown()
  local start, duration = try(C_Container and C_Container.GetItemCooldown, 6948)
  if type(start) ~= "number" then start, duration = try(GetItemCooldown, 6948) end
  if type(start) ~= "number" or type(duration) ~= "number" then return end
  if start <= 0 or duration <= 0 then return 0 end
  return math.max(0, start + duration - GetTime())
end

-- The flight the current Fly step wants. A Fly step sits at the destination's flight master,
-- so it stays current until you land there.
function Q.flightStep()
  local row = not review and index and steps[index]
  if row and row.step.type == "fly" and row.step.flight and not Q.inFlight() then return row.step end
end

local function activeGoal(row, entry)
  local kind = row.step.type
  return entry and (row.state == "pending" or row.state == "deferred")
    and ((kind == "complete" and not entry.ready) or (kind == "turnin" and entry.ready))
end

local function activeStep(section, localMap)
  local map = localMap or Q.position()
  local best, score
  for i, row in ipairs(steps) do
    local s = row.step
    local entry = s.quest and log[s.quest]
    if not row.section.side and (not section or row.section == section) and activeGoal(row, entry)
        and (not localMap or (row.section.zone == map and (not s.map or s.map == map)
          and (entry.ready or #entry.objectives > 0))) then
      local rank = (map and s.map == map and 4 or 0)
        + (map and row.section.zone == map and 2 or 0) + (row.section == selected and 1 or 0)
      if not score or rank > score then best, score = i, rank end
    end
  end
  return best
end

local function hasSectionWork(section, map)
  for _, row in ipairs(steps) do
    local s = row.step
    if row.section == section and (row.state == "pending" or row.state == "deferred") and s.quest and not row.grey
        and (not map or not s.map or s.map == map)
        and (log[s.quest] or (s.type == "accept" and level >= (s.min or 1) and prerequisitesMet(s))) then
      return true
    end
  end
end

local function localSection(map)
  local early
  for _, section in ipairs(sections) do
    if not section.side and not section.manual and section.zone == map and level <= section.levels[2]
        and hasSectionWork(section, map) then
      if levelFits(section) then return section end
      -- The first pickups can open before the section's recommended level, but only a level
      -- ahead: a zone visited twice (Duskwood at 24 and 30, Hillsbrad at 23 and 30) must not
      -- pull a level 28 into its later chapter past the route's own next section.
      if level + 1 >= section.levels[1] then early = early or section end
    end
  end
  return early
end

local function followFrom(i)
  selected, resumeAt, review, history = steps[i].section, i, nil, {}
  calculate()
end

local function followSection(section)
  selected, resumeAt, review, history = section, nil, nil, {}
  calculate()
end

local function resumeLocal(event)
  local map, x = Q.position()
  if not (map and x) or Q.inFlight() then return end
  local changed = map ~= lastZone
  lastZone = map
  if not changed and not checkLocalOnLog then return end
  -- The first log update can arrive after the player's position is available.
  checkLocalOnLog = event ~= "QUEST_LOG_UPDATE" or next(log) == nil
  local row = index and steps[index]
  if sideSection or review or (row and ((row.requiredFor and row.step.map == map) or
      (row.step.map == map and row.section.zone ~= map))) then
    checkLocalOnLog = false
    return
  end
  local best = next(log) and activeStep(nil, map)
  if best then
    checkLocalOnLog = false
    if best ~= index then followFrom(best) end
  elseif changed and (not selected or selected.zone ~= map) then
    local section = localSection(map)
    if section then followSection(section) end
  end
end

-- Known flight paths. The classic client only lists them while the flight map is
-- open, so remember what it showed (charDB, if it loads back). Check the world-map
-- API at startup and after learning a route when Forever has it.
local function flightStore()
  local db = ns.charDB()
  db.questFlights = db.questFlights or {}
  return db.questFlights
end

local flightVersion = 0 -- bumps whenever what we know about flights changes (travel plans cache on it)
local function rememberFlight(name, known)
  if knownFlights[name] ~= (known or nil) then flightVersion = flightVersion + 1 end
  knownFlights[name] = known or nil
  flightStore()[name] = known or nil
end

-- What QuestTravel.lua plans with: flight points you know, what a flight map you opened said
-- (name -> "CURRENT"/"REACHABLE"/...), whether the client listed your flights, and the version.
function Q.knownFlight(name) return knownFlights[name] == true end
function Q.flightMapFrom(name) return flightLinks[name] end
function Q.flightVersion() return flightVersion end

local CONTINENTS = { 1415, 1414 }
local probed, probeCount
local function probeFlights()
  probed = true
  for name in pairs(flightStore()) do knownFlights[name] = true end
  flightVersion = flightVersion + 1
  local api = C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap
  if type(api) ~= "function" then return end
  probeCount = 0
  for _, map in ipairs(CONTINENTS) do
    local nodes = try(api, map)
    for _, node in ipairs(type(nodes) == "table" and nodes or {}) do
      if type(node) == "table" and type(node.name) == "string" then
        local undiscovered = node.isUndiscovered
        if undiscovered == true then
          rememberFlight(node.name, false)
        elseif undiscovered == false or (undiscovered == nil and (node.state == 0 or node.state == 1)) then
          knownFlights[node.name], probeCount = true, probeCount + 1
        end
      end
    end
  end
end

function Q.flightDebug()
  local n = 0
  for _ in pairs(knownFlights) do n = n + 1 end
  return n, probeCount
end

function Q.flightsListed() return (probeCount or 0) > 0 end

local function readStartItems()
  local changed = false
  for item, hadItem in pairs(startItems) do
    local hasItem = Q.itemCount(item) > 0
    if hasItem ~= hadItem then
      startItems[item], changed = hasItem, true
    end
  end
  -- collect and buy steps count their items: any change can finish one
  for item, had in pairs(collectItems) do
    local count = Q.itemCount(item)
    if count ~= had then
      collectItems[item], changed = count, true
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
  if not probed or event == "NEW_TAXI_PATH" then probeFlights() end
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
  if not event or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA"
      or event == "QUEST_LOG_UPDATE" or event == "QUEST_QUERY_COMPLETE" or event == "PLAYER_CONTROL_GAINED" then
    resumeLocal(event)
  end
  if event == "QUEST_TURNED_IN" and review and steps[review].step.quest == id then review = nil end
  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then Q.enteredDungeon() end
end

-- Zoning into a dungeon: a new dungeon clears the bosses counted down, and one with a guide
-- opens it at its inside part (Settings > Open a dungeon's guide when you enter it). Once per
-- entry, so Return to leveling inside sticks; dying and running back in keeps the count.
function Q.enteredDungeon()
  local name, kind, _, _, _, _, _, instanceID = try(GetInstanceInfo)
  if kind ~= "party" then inInstance = nil; return end
  local here = (type(instanceID) == "number" and instanceID > 0) and instanceID or name
  if here == inInstance then return end
  inInstance = here
  if here ~= lastInstance then killed = {} end
  lastInstance = here
  if ns.db().noDungeonOpen then return end
  for _, section in ipairs(sections) do
    if section.category == "dungeon" and inDungeon(section) and not sideHidden(section) then
      if sideSection ~= section then
        Q.jump(section, nil, "inside")
        if sideSection == section then
          ns.say(Q.plain(section.title .. ": the step window follows its guide, boss by boss. Return to leveling takes you back."))
        end
      end
      return section
    end
  end
end

-- A boss died: ENCOUNTER_END / BOSS_KILL (encounter ID, name; an NPC ID matches too). Marks the
-- matching boss of the dungeon you're in.
function Q.bossDown(encounter, name, npc)
  local hit = false
  local wanted = type(name) == "string" and Q.plain(name):lower()
  for _, row in ipairs(steps) do
    local s = row.step
    if s.type == "boss" and not killed[row.key] and inDungeon(row.section) then
      local bossName = s.name:gsub(" %(.*$", ""):lower()
      if (encounter and s.encounter == encounter) or (npc and s.npc == npc) or (wanted and wanted == bossName) then
        killed[row.key], hit = true, true
      end
    end
  end
  if hit then calculate() end
  return hit
end

function Q.current()
  local i = review or index
  return i and steps[i], i
end

function Q.greyPickups() return greyRows end

-- A guide's progress and status for the Quests tab: quests turned in out of
-- the quests it turns in, and "current", "done", "outleveled", "suggested", "later" or "open".
function Q.sectionProgress(section)
  local total, done, seen = 0, 0, {}
  for _, row in ipairs(steps) do
    local s = row.step
    if row.section == section and s.type == "turnin" and not seen[s.quest] and row.state ~= "filtered" then
      seen[s.quest] = true
      total = total + 1
      if turnedIn[s.quest] then done = done + 1 end
    end
  end
  return done, total
end

function Q.sectionStatus(section, suggested)
  local done, total = Q.sectionProgress(section)
  local lvl = level or 1
  if section == (sideSection or selected) then return "current", done, total end
  if total > 0 and done == total then return "done", done, total end
  if lvl > section.levels[2] then return "outleveled", done, total end
  if suggested and suggested[section] then return "suggested", done, total end
  if lvl < section.levels[1] then return "later", done, total end
  return "open", done, total
end
function Q.rows() return steps, sections, missed, level or UnitLevel("player"), sideSection or selected, ready end
function Q.log(id) return log[id] end
function Q.logEntries() return log end
function Q.incomplete(id)
  local entry = log[id]
  if entry and not entry.ready and not turnedIn[id] then return entry end
end
function Q.arrived() return RADIUS end

function Q.section(id)
  local section = sectionsById[id]
  return section and not sideHidden(section) and section or nil
end

function Q.relatedGuide()
  local row = Q.current()
  return row and row.step.guide and Q.section(row.step.guide)
end

function Q.guideMinimum(section)
  if section.category == "special" and level < section.levels[1] then return section.levels[1] end
end

-- Where a quest sits in its story chain: part, length and the
-- dungeon checklist the chain feeds, if any. Only chains of three or more quests count.
function Q.chainInfo(id)
  if not id then return end
  local first, part = id, 1
  while chainBefore[first] and part < 40 do first, part = chainBefore[first], part + 1 end
  local length, cur, run = part, id, questRun[id]
  while chainAfter[cur] and length < 80 do
    cur, length = chainAfter[cur], length + 1
    run = run or questRun[cur]
  end
  if length < 3 then return end
  return part, length, run and Q.section(run)
end

-- A planned run's quests in your log, and pickups for it you could still take now.
function Q.runReadiness(section)
  local quests = runQuests[section.id]
  if not quests then return 0, 0 end
  local inLog, left = 0, 0
  for id in pairs(quests) do
    if log[id] and not turnedIn[id] then inLog = inLog + 1 end
  end
  local counted = {}
  for _, row in ipairs(steps) do
    local s = row.step
    if s.type == "accept" and quests[s.quest] and not counted[s.quest] and not log[s.quest] and not turnedIn[s.quest]
        and (s.phase == nil or s.phase == "prepare") and row.state ~= "filtered" and row.state ~= "skipped"
        and not s.startItem and level >= (s.min or 1) and prerequisitesMet(s) then
      left, counted[s.quest] = left + 1, true
    end
  end
  return inLog, left
end

-- The "find a group" moment: a planned run in your level range whose pickups are done
-- (or that already has three quests waiting). Nil while you are on a detour.
function Q.readyRun()
  if sideSection or not level then return end
  for _, section in ipairs(sections) do
    if section.category == "dungeon" and Q.planned(section.id) and level >= section.levels[1]
        and level <= section.levels[2] + 3 and not sideHidden(section) then
      local inLog, left = Q.runReadiness(section)
      if inLog > 0 and (left == 0 or inLog >= 3) then return section, inLog end
    end
  end
end

-- Plans the runs worth doing for this character: ones near the route, or tied to a class
-- quest of yours, still in reach of your level.
function Q.recommendedRuns()
  local near, result = {}, {}
  for _, section in ipairs(sections) do
    if not section.category then near[section.zone] = true end
  end
  for map in pairs(route and route.flightNetwork or {}) do near[map] = true end
  for _, section in ipairs(sections) do
    if section.category == "dungeon" and (level or 1) <= section.levels[2] then
      local classLink = false
      for _, id in ipairs(section.links or {}) do
        local linked = sectionsById[id]
        if linked and linked.class then classLink = true end
      end
      local count = 0
      for _ in pairs(runQuests[section.id] or {}) do count = count + 1 end
      if classLink or (near[section.zone] and count >= 3) then result[#result + 1] = section end
    end
  end
  return result
end

function Q.dungeons()
  local result = {}
  for _, section in ipairs(sections) do
    if section.category == "dungeon" then result[#result + 1] = section end
  end
  return result
end

-- Quests in your log and the most the game lets you hold (nil when the client doesn't say).
function Q.logCapacity()
  local count = 0
  for _ in pairs(log) do count = count + 1 end
  local max = try(C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept)
  if type(max) ~= "number" or max <= 0 then
    max = type(MAX_QUESTLOG_QUESTS) == "number" and MAX_QUESTLOG_QUESTS or nil
  end
  return count, max
end

-- Quests in your log that no guide of yours uses, then grey ones not yet finished (little XP
-- left), for the library's cleanup list.
function Q.unusedQuests()
  local used, result = {}, {}
  for _, row in ipairs(steps) do
    if row.step.quest then used[row.step.quest] = true end
  end
  local grey = level and greyRange()
  for id, entry in pairs(log) do
    local reason
    if not used[id] then
      reason = "Not in your guides"
    elseif grey and entry.level and not entry.ready and entry.level <= level - grey then
      reason = "Grey"
    end
    if reason then
      result[#result + 1] = { id = id, reason = reason, title = entry.title or questNames[id] or ("Quest " .. id) }
    end
  end
  table.sort(result, function(a, b)
    if a.reason ~= b.reason then return a.reason > b.reason end
    return a.id < b.id
  end)
  return result
end

-- Abandons a quest in your log (the modern calls, else the classic ones by log index).
function Q.abandon(id)
  local entry = log[id]
  if not entry then return false end
  local L = C_QuestLog
  if L and type(L.SetSelectedQuest) == "function" and type(L.SetAbandonQuest) == "function"
      and type(L.AbandonQuest) == "function" then
    try(L.SetSelectedQuest, id)
    try(L.SetAbandonQuest)
    try(L.AbandonQuest)
    return true
  end
  if entry.index and type(SelectQuestLogEntry) == "function" and type(SetAbandonQuest) == "function"
      and type(AbandonQuest) == "function" then
    try(SelectQuestLogEntry, entry.index)
    try(SetAbandonQuest)
    try(AbandonQuest)
    return true
  end
  return false
end

function Q.find(query)
  local foundSections, foundRows, seen = {}, {}, {}
  query = (query or ""):lower():match("^%s*(.-)%s*$")
  if query == "" then return foundSections, foundRows end
  local id = tonumber(query)
  for _, section in ipairs(sections) do
    if not sideHidden(section) and section.title:lower():find(query, 1, true) then
      foundSections[#foundSections + 1] = section
    end
  end
  for _, row in ipairs(steps) do
    local s = row.step
    local key = s.quest and row.section.id .. ":" .. s.quest
    if key and not seen[key] and not sideHidden(row.section)
        and (s.quest == id or (s.name and s.name:lower():find(query, 1, true))) then
      foundRows[#foundRows + 1], seen[key] = row, true
    end
  end
  return foundSections, foundRows
end

function Q.questMatch(id)
  local best, bestScore
  for _, row in ipairs(steps) do
    if row.step.quest == id and not sideHidden(row.section) and row.state ~= "filtered" then
      local score = (activeGoal(row, log[id]) and 8 or 0) + (row.state == "pending" and 4 or 0)
        + (row.section == (sideSection or selected) and 2 or 0) + (not row.section.side and 1 or 0)
      if not bestScore or score > bestScore then best, bestScore = row, score end
    end
  end
  return best
end

function Q.followQuest(row)
  if not activeGoal(row, log[row.step.quest]) then
    Q.jump(row.section, row)
  elseif row.section.side then
    Q.jump(row.section, nil, row.step.phase, row)
  else
    leaveSide()
    for i, candidate in ipairs(steps) do
      if candidate == row then followFrom(i); return end
    end
  end
end

-- Why a route row isn't (or is) where the route stops, for the route list's tooltips.
function Q.reason(row)
  local s, st = row.step, row.state
  local function named(id) return questNames[id] or ("quest " .. id) end
  if st == "done" then
    if s.quest and turnedIn[s.quest] then return "Done: turned in." end
    if s.type == "accept" and s.quest and log[s.quest] then return "Done: it's in your quest log." end
    if s.skipOn and visited[row.key] then return "Done: you were already there." end
    return "Done."
  elseif st == "skipped" then
    if s.breadcrumb and (log[s.breadcrumb] or turnedIn[s.breadcrumb]) then
      return "Skipped: you already have its follow-up, " .. named(s.breadcrumb) .. "."
    end
    if s.maxLevel and level > s.maxLevel then return "Skipped: you're past level " .. s.maxLevel .. "." end
    if s.unlessDone and turnedIn[s.unlessDone] then return "Skipped: not needed once " .. named(s.unlessDone) .. " is done." end
    if row.leadIn then return "Skipped: you're already in this zone." end
    return "Skipped: you passed it with Next. Back brings it back."
  elseif st == "deferred" then
    if row.grey then return "Left out: it's grey for your level. Missed quests > Outleveled lists it." end
    if row.cut then return "Left out: it needs a quest chain you skipped in another zone." end
    return "Earlier: you've moved past it in this guide. Missed quests lists it."
  elseif st == "blocked" then
    if s.skill and s.profession then return "Waiting: needs " .. s.profession:lower() .. " skill " .. s.skill .. "." end
    return "Waiting: " .. (s.quest and Q.questStatus(row) or "not available yet") .. "."
  elseif st == "pending" and row.requiredFor then
    return "Kept: required for " .. row.requiredFor.name .. "."
  end
end

function Q.questStatus(row)
  local step = row.step
  local entry = log[step.quest]
  if turnedIn[step.quest] then return "Done" end
  if awaitingObjectives(step, entry) then return "Objectives incomplete" end
  if entry then return entry.ready and "Ready to turn in" or "In log" end
  if step.min and level < step.min then return "Requires level " .. step.min end
  if row.state == "skipped" then
    local follow = step.breadcrumb
    return follow and (log[follow] or turnedIn[follow]) and "Follow-up already started" or "Skipped"
  end
  local missing = {}
  for _, id in ipairs(step.chain or {}) do
    if not turnedIn[id] then missing[#missing + 1] = questNames[id] or ("quest " .. id) end
  end
  if #missing > 0 then return "Requires " .. table.concat(missing, ", ") end
  if step.startItem and not startItems[step.startItem] then return "Starter item needed" end
  if step.type ~= "accept" then return "Pick up quest first" end
  if step.phase == "inside" then return "Starts inside" end
  if step.uncertain then return "Check in game" end
  return "Available"
end

local function pinTable()
  local db = ns.charDB()
  if type(db.questPins) ~= "table" then db.questPins = {} end
  return db.questPins
end

function Q.pins()
  local result = {}
  for _, id in ipairs(pinTable()) do
    if Q.incomplete(id) then result[#result + 1] = id end
  end
  return result
end

function Q.togglePin(id)
  local pins = pinTable()
  for i = #pins, 1, -1 do
    if pins[i] == id then table.remove(pins, i); return true end
    if not Q.incomplete(pins[i]) then table.remove(pins, i) end
  end
  if not Q.incomplete(id) or #pins >= 3 then return false end
  pins[#pins + 1] = id
  return true
end

function Q.suggestions(browse)
  local choices, seen = {}, {}
  if sideSection or review then return choices end
  local row = index and steps[index]
  local suggestions = row and row.step.suggest or (not row and selected and selected.suggest)
  local function offer(section)
    if not section or section == selected or section.side or seen[section] or not levelFits(section) then return end
    if hasSectionWork(section) then
      choices[#choices + 1], seen[section] = section, true
    end
  end
  for _, id in ipairs(suggestions or {}) do offer(sectionsById[id]) end
  local map = not Q.inFlight() and Q.position()
  if map and selected and selected.zone ~= map then
    for _, section in ipairs(sections) do
      if section.zone == map then offer(section) end
    end
  end
  if browse then
    for _, section in ipairs(sections) do offer(section) end
  end
  return choices
end

-- A step with `points` ({ {x, y}, ... } on its map) leads through them in turn and loops, or
-- with `nearest = true` to whichever is closest. Reaching a point moves on to the next one.
-- Returns where to go now (a step-like table) and the point's number.
local pointAt = setmetatable({}, { __mode = "k" })
local PATH_RADIUS, PATH_JOIN, PATH_LOST = 15, 60, 150

-- Yards to a spot, across a zone border too (inside tunnels the client may report the continent).
local function yardsTo(spot, map, x, y)
  local _, d = Q.vector(spot, map, x, y)
  if not d and Q.worldVector then _, d = Q.worldVector(spot, map, x, y) end
  return d
end

-- A step with `path` ({ {x, y [, map]}, ... }): the way in through tunnels or a cave. The arrow
-- leads through the points in order, then to the step's own spot. You join it at the closest
-- point within 60 yd (else the first), and wandering 150 yd from the point you're on starts over.
local function pathWaypoint(step)
  local map, x, y = Q.position()
  local count = #step.path
  local function spot(i)
    local p = step.path[i]
    return { map = p[3] or step.map, x = p[1], y = p[2], world = true, type = "goto" }
  end
  local n = pointAt[step]
  if n and n <= count and x then
    local d = yardsTo(spot(n), map, x, y)
    if d and d > PATH_LOST and n > 1 then n = nil end
  end
  if not n and x then
    local best, bestDist = 1, nil
    for i = 1, count do
      local d = yardsTo(spot(i), map, x, y)
      if d and d <= PATH_JOIN and (not bestDist or d < bestDist) then best, bestDist = i, d end
    end
    n = best
  end
  n = n or 1
  while n <= count and x do
    local d = yardsTo(spot(n), map, x, y)
    if d and d <= PATH_RADIUS then n = n + 1 else break end
  end
  pointAt[step] = n
  if n > count then return step end
  return spot(n), n, count, "way in"
end

function Q.waypoint(step)
  if step and step.path and step.map and #step.path > 0 then return pathWaypoint(step) end
  if not (step and step.points and step.map and #step.points > 0) then return step end
  local map, x, y = Q.position()
  local n = pointAt[step] or 1
  local here = map == step.map and x
  local function spot(i) return { map = step.map, x = step.points[i][1], y = step.points[i][2] } end
  if here and step.nearest then
    local best, bestDist
    for i in ipairs(step.points) do
      local _, d = Q.vector(spot(i), map, x, y)
      if d and (not bestDist or d < bestDist) then best, bestDist = i, d end
    end
    n = best or n
  elseif here then
    local _, d = Q.vector(spot(n), map, x, y)
    if d and d <= RADIUS then n = n % #step.points + 1 end
  end
  pointAt[step] = n
  local target = spot(n)
  target.type, target.bind, target.flight = step.type, step.bind, step.flight
  return target, n, #step.points, "spot"
end

-- The zones' flight hubs (a route's flight-path steps): from your map's hub to the step map's hub,
-- both known and on one network. Returns the hub to walk to and the flight to take there. The arrow
-- uses it when no trip through flight masters is planned (QuestTravel.lua), and so does the flight map.
function Q.hubFlight(step, map)
  if not (route and step and step.map and map) or step.map == map then return end
  local network = route.flightNetwork
  local origin, target = flightHubs[map], flightHubs[step.map]
  local links = origin and flightLinks[origin.flight]
  if origin and target and network and network[map] and network[map] == network[step.map]
      and (not links or links[target.flight] == "REACHABLE")
      and knownFlights[origin.flight] and knownFlights[target.flight] then
    return origin, target.flight
  end
end

function Q.destination(step, map)
  if not (step and step.map and map) then return step end
  if step.map ~= map and step.type == "hearth" and boundTo(step.bind) and (Q.hearthCooldown() or 0) < 60 then
    return nil, "Hearth to " .. step.bind
  end
  if (step.world or (Q.continentMap and Q.continentMap(map))) and Q.sameContinent and Q.sameContinent(step.map, map) then
    return step
  end
  -- A long trip goes through a flight master when that's quicker (QuestTravel.lua), and a flight
  -- path you don't have close to the way there is learned on the way.
  if Q.travelLeg then
    local leg, label = Q.travelLeg(step, map)
    if leg then return leg, label end
  end
  if step.map == map then return step end
  local origin, flight = Q.hubFlight(step, map)
  if origin then return origin, "Fly to " .. flight:match("^[^,]+") end
  local roads = route.roadTo and route.roadTo[step.map]
  local road = roads and roads[map]
  if road then return road.waypoint, road.label end
  local info = try(C_Map and C_Map.GetMapInfo, step.map)
  local name = type(info) == "table" and info.name or step.flight
  return step, name and ("Travel to " .. Q.plain(name)) or "Objective in another zone"
end

function Q.upcoming(i, count)
  local result = {}
  local section = steps[i].section
  local start = resumeAt and steps[resumeAt].section or section
  for n = i + 1, #steps do
    local row = steps[n]
    if section.side and row.section ~= section then break end
    if row.state == "pending" and not row.step.sticky and not row.sticky and (row.section == section or
        follows(row.section, start) or row.requiredFor) then
      result[#result + 1] = row
      if #result == (count or 2) then break end
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
    review = index and i < index and (sameSection or (not row.section.side and not sideSection
      and follows(steps[i].section, selected))) and i or nil
  elseif hasMoreObjectives(row, i) then
    visited[row.key] = true
  elseif row.step.type == "plan" then
    Q.setPlanned(row.step.dungeon, false) -- Next on Dungeon ahead skips the run
    ns.say(Q.plain(row.step.name .. " is skipped: Quests > Guide library > Dungeons can plan it later."))
  elseif row.step.quest or row.step.type == "dungeon" or row.step.type == "getfp" or row.step.type == "sethearth" then
    local skips = row.section.side and sideSkips or skipTable()
    skips[row.key] = true
  else
    visited[row.key] = true
  end
  calculate()
  if manual and (not row.section.side or sideSection) then
    local trail = sideSection and sideHistory or history
    trail[#trail + 1] = { from = i, to = index }
  end
end

function Q.back()
  if review and (sideSection or steps[review].section.side) and steps[review].section ~= sideSection then
    review = nil
    return
  end
  local i = (review or index or (#steps + 1)) - 1
  local trail = sideSection and sideHistory or history
  local previous = trail[#trail]
  if not review and previous and previous.to == index then
    i = previous.from
    table.remove(trail)
  else
    local start = resumeAt and steps[resumeAt].section or selected
    while steps[i] and (steps[i].state == "filtered" or steps[i].state == "skipped" or
        (not sideSection and not follows(steps[i].section, start) and not steps[i].requiredFor)) do i = i - 1 end
  end
  local row = steps[i]
  if sideSection and (not row or row.section ~= sideSection) then return end
  if row and row.section.side and row.section ~= sideSection then return end
  if row then
    local skips = row.section.side and sideSkips or skipTable()
    skips[row.key], visited[row.key] = nil, nil
    if not sideSection then selected = row.section end
    review = i
    calculate()
    if review == index then review = nil end
  end
end

function Q.jump(section, row, phase, resumeRow)
  if sideHidden(section) then return end
  checkLocalOnLog = false
  if row then
    for i, candidate in ipairs(steps) do
      if candidate == row then review = i ~= index and i or nil; return end
    end
  elseif section.side then
    if Q.guideMinimum(section) then return end
    sideSection, review, sideHistory, sideSkips = section, nil, {}, {}
    sideFrom = PHASE[phase] or (section.category == "dungeon" and inDungeon(section) and PHASE.inside) or PHASE.prepare
    sideResumeAt = 0
    if resumeRow then
      for i, candidate in ipairs(steps) do
        if candidate == resumeRow then sideResumeAt = i; break end
      end
    end
    calculate()
  elseif sideSection and section == selected then
    Q.returnToRoute()
  else
    leaveSide()
    followSection(section)
  end
end

function Q.returnToRoute()
  leaveSide()
  review = nil
  calculate()
end

-- Leave a step you went Back to (the route's current step shows again).
function Q.leaveReview()
  review = nil
  calculate()
end

function Q.resumeActive(section)
  local best = activeStep(section)
  if not best then return end
  checkLocalOnLog = false
  followFrom(best)
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
  flightVersion = flightVersion + 1
  for name, state in pairs(nodes) do
    if state == "CURRENT" then flightLinks[name] = nodes end
    if state == "CURRENT" or state == "REACHABLE" then rememberFlight(name, true) end
  end
  calculate()
end

function Q.checkPosition()
  if Q.inFlight() then return end
  local map, x, y = Q.position()
  -- The map can still show the previous zone when the zone event fires.
  if x and map ~= lastZone then
    Q.update("ZONE_CHANGED_NEW_AREA")
    return true
  end
  local row = not review and index and steps[index]
  if row and ARRIVAL[row.step.type] then
    local _, dist = Q.vector(row.step, map, x, y)
    if dist and dist <= RADIUS then
      visited[row.key] = true
      calculate()
      return true
    end
  end
end

-- The Dungeon ahead step: what the run is and what planning it does.
function Q.planText(step)
  local run = sectionsById[step.dungeon]
  if not run then return "" end
  local count = 0
  for _ in pairs(runOwn[step.dungeon] or {}) do count = count + 1 end
  local recommended = false
  for _, section in ipairs(Q.recommendedRuns()) do
    if section == run then recommended = true end
  end
  return run.title .. " (levels " .. run.levels[1] .. "-" .. run.levels[2] .. ") is a dungeon for a group of five."
    .. (count > 0 and (" " .. count .. (count == 1 and " quest" or " quests") .. " on your route need it.") or "")
    .. (recommended and " Recommended for you: it's close to your route or a class quest needs it." or "")
    .. "\nPlan it: the run and its quests join your route, and the guide says when to find a group."
    .. "\nSkip it: the run stays out of your route. Quests > Guide library > Dungeons can change this later."
end

function Q.text(step)
  if step.type == "getfp" then return step.text .. " Use Next to skip this flight path." end
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
      if atTarget then return "Your hearthstone is already set to " .. bind .. "." end
      local current = bind and (" Your hearthstone is set to " .. bind .. ".") or ""
      return step.text .. current .. " Use Next to keep your current bind."
    end
    if atTarget then
      local wait = Q.hearthCooldown()
      if wait and wait >= 60 then
        return step.text .. " Your hearthstone is ready in " .. math.ceil(wait / 60) .. " min: travel there instead."
      end
      return step.text .. (wait and " Use your hearthstone: it's ready." or " Use your hearthstone if it's ready.")
    end
    if not bind then return step.text .. " Use your hearthstone if you're bound there and it's ready." end
    return step.text .. " Your hearthstone is set to " .. bind .. "."
  end
  if step.type ~= "train" then return step.text end
  local visit = ns.trainAt(step.level or level) or ns.nextTrain((step.level or level) - 1)
  if not visit then return step.text .. " " .. tostring(step.level or level) .. "." end
  return ns.plain(step.text .. " " .. visit.level .. ": " .. table.concat(visit.spells, ", "))
end
