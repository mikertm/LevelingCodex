-- QuestTab.lua: the current step, section browser and quest queues.
local _, ns = ...
local Q, U, C = ns.quests, ns.ui, ns.C
local W = U.W
local view, allSteps = "route", false
local librarySection, query, draft = nil, "", ""

local STATUS = { pending = "To do", done = "Done", deferred = "Earlier", skipped = "Skipped", blocked = "Blocked" }
local GUIDE_TAG = { current = "Current", done = "Done", outleveled = "Outleveled", suggested = "Suggested", later = "Later" }
-- Leveling guides are listed by the band their first level falls in.
local BANDS = { { 1, 11, "LEVELS 1-12: STARTING ZONES" }, { 12, 19, "LEVELS 12-20" }, { 20, 29, "LEVELS 20-30" },
  { 30, 60, "LEVELS 30-60" } }

local function sectionInfo(section)
  return (section.category == "dungeon" and "Suggested levels " or "Levels ") .. section.levels[1] .. "-" .. section.levels[2]
end

local function runInfo(section)
  if not Q.planned(section.id) then return "Not planned" end
  local inLog, left = Q.runReadiness(section)
  return "Planned  |  " .. inLog .. " in log" .. (left > 0 and (", " .. left .. " to pick up") or "")
end

local function setPlans(list, on)
  for _, section in ipairs(Q.dungeons()) do Q.setPlanned(section.id, false) end
  for _, section in ipairs(list or {}) do Q.setPlanned(section.id, on) end
  ns.updateQuestSettings()
end

local function stepCard(row, y)
  local top = y
  y = y + 13
  local label = Q.autoStep() and "CURRENT STEP" or "STEP PREVIEW"
  local heading = U.T(label, 16, y, 128, "label", C.inkSoft)
  local section = U.T(row.section.title, 148, y, W - 164, "small", C.inkSoft, "RIGHT")
  y = y + math.max(heading, section) + 6
  y = y + U.T(Q.label(row.step), 16, y, W - 32, "head", C.ink) + 4
  y = y + U.T(Q.detail(row.step, row.requiredFor, row == Q.current()), 16, y, W - 32, "body", C.ink) + 14
  U.box(0, top, W, y - top, C.parch, C.edge)
  return y + 12
end

local function openStep(row, follow)
  Q.jump(row.section, not follow and row or nil)
  ns.showQuestViewer()
end

local function drawRow(row, y, title, status, secondary, secondaryWidth, active, tip, follow)
  local titleWidth = W - 94 - (secondary and secondaryWidth + 12 or 0)
  local done = row.state == "done"
  local marker = active and C.gold or done and C.green or C.dim
  local text = active and C.gold or row.state == "pending" and C.light or C.dim
  local h1 = U.T(status, 12, y + 7, 62, "small", marker)
  local h2 = U.T(title, 82, y + 7, titleWidth, "body", text)
  local h3 = 0
  if secondary then
    h3 = U.T(secondary, W - 12 - secondaryWidth, y + 7, secondaryWidth, "small", C.dim, "RIGHT")
  end
  local height = math.max(30, math.max(h1, h2, h3) + 14)
  U.rect(0, y, W, height, active and C.panel or C.wash)
  U.rect(0, y + height - 1, W, 1, C.edgeSoft, "border")
  if active then U.rect(0, y, 3, height, C.edge, "border") end
  U.hit(0, y, W, height, title, tip or row.step.text, function() openStep(row, follow) end)
  return y + height + 3
end

local function renderQueue(y, title, list, status, empty, tip)
  y = y + U.sectionTitle(title, y)
  if #list == 0 then return y + U.T(empty, 0, y, W, "body", C.dim) end
  for _, row in ipairs(list) do
    local follow = row.section.side and status == "Pickup"
    y = drawRow(row, y, row.step.name, status, row.section.title, 136, false,
      follow and "Follow this class quest chain." or tip, follow)
  end
  return y
end

local function renderRoute(rows, selected, current, y)
  if not selected then return y end
  U.btn(allSteps and "Hide finished" or "Show all steps", W - 138, y, 138, function()
    allSteps = not allSteps
    U.refresh()
  end, allSteps, "Toggle finished, earlier and skipped steps in this section.")
  local h = U.T(selected.title .. " route", 0, y + 1, W - 154, "head", C.gold)
  y = y + math.max(22, h) + 9
  U.goldRuleAt(y)
  y = y + 10
  local visible = false
  for _, row in ipairs(rows) do
    if row.section == selected and row.state ~= "filtered" and
        (allSteps or row == current or row.state == "pending") then
      local active = row == current
      local why = Q.reason(row)
      y = drawRow(row, y, Q.label(row.step), active and "Current" or row.grey and "Grey" or STATUS[row.state],
        row.step.forever and "Forever" or nil, 62, active, why and (why .. "\n" .. Q.plain(row.step.text or "")) or nil)
      visible = true
    end
  end
  if not visible then
    y = y + U.T("No remaining steps in this section.", 0, y, W, "body", C.dim)
  end
  return y
end

local function followGuide(section, phase)
  Q.jump(section, nil, phase)
  ns.showQuestViewer()
end

local function showGuide(section)
  librarySection = section
  U.refreshTop()
end

local function renderLibrarySection(rows, section, y)
  y = y + U.sectionTitle(section.title, y)
  y = y + U.T(sectionInfo(section), 0, y, W, "small", C.dim) + 8
  local col = math.floor((W - 16) / 3)
  local minimum = Q.guideMinimum(section)
  if minimum then
    U.T("Available at level " .. minimum, 0, y + 4, W, "body", C.dim)
  else
    U.btn("Follow this guide", 0, y, col, function() followGuide(section) end)
  end
  if section.category == "dungeon" then
    U.btn("Start inside", col + 8, y, col, function() followGuide(section, "inside") end)
    U.btn("After the run", W - col, y, col, function() followGuide(section, "after") end)
    y = y + 34
    local planned = Q.planned(section.id)
    U.btn(planned and "Planned: its pickups are in your route" or "Plan this run", 0, y, W, function()
      Q.setPlanned(section.id, not planned)
      ns.updateQuestSettings()
    end, planned, "Planned runs add their quest pickups to your leveling route and say when you're ready to find a group.")
    y = y + 30
    y = y + U.T(runInfo(section), 0, y, W, "small", C.dim)
  end
  y = y + 34
  for _, id in ipairs(section.links or {}) do
    local linked = Q.section(id)
    if linked then
      U.btn(linked.title, 0, y, W, function() showGuide(linked) end, false, "Open this related guide.")
      y = y + 28
    end
  end
  if section.bosses and #section.bosses > 0 then
    y = y + U.sectionTitle("BOSSES IN ORDER", y)
    for i, boss in ipairs(section.bosses) do
      y = y + U.T(i .. ". " .. Q.plain(boss.name), 0, y, W, "body", C.gold) + 2
      y = y + U.T(Q.plain(boss.tip), 12, y, W - 12, "small", C.light) + 8
    end
  end
  local headers = { prepare = "BEFORE YOU GO", inside = "INSIDE", after = "AFTER THE RUN" }
  local lastPhase
  for _, row in ipairs(rows) do
    if row.section == section and row.state ~= "filtered" then
      local s = row.step
      local phase = section.category == "dungeon" and (s.phase or "prepare")
      if phase and phase ~= lastPhase then
        y = y + U.sectionTitle(headers[phase], y)
        lastPhase = phase
      end
      local status = s.quest and Q.questStatus(row) or STATUS[row.state]
      local tip = Q.detail(s)
      y = drawRow(row, y, Q.label(s), STATUS[row.state], status ~= STATUS[row.state] and status or nil,
        150, false, tip)
    end
  end
  return y
end

-- Quest log cleanup: quests no guide uses and grey ones. Abandon takes two clicks; the second
-- must come within 5 seconds.
local confirmAbandon, confirmAt
local function renderCleanup(y)
  local unused = Q.unusedQuests()
  if #unused == 0 then return y end
  y = y + 6 + U.sectionTitle("Quest log cleanup", y + 6)
  y = y + U.T("Quests no guide of yours uses, and grey quests that give little XP. Abandoning one frees log space.",
    0, y, W, "small", C.dim) + 6
  local buttonWidth = math.floor(W * 0.46)
  for _, quest in ipairs(unused) do
    local name = Q.plain(quest.title)
    U.T(name .. "\n" .. quest.reason, 0, y + 1, W - buttonWidth - 8, "small", C.light)
    local armed = confirmAbandon == quest.id and GetTime() - (confirmAt or 0) < 5
    U.btn(armed and "Click again to abandon" or ("Abandon " .. name), W - buttonWidth, y, buttonWidth, function()
      if confirmAbandon == quest.id and GetTime() - (confirmAt or 0) < 5 then
        confirmAbandon = nil
        if Q.abandon(quest.id) then ns.say("abandoned " .. name .. ".")
        else ns.say("this client can't abandon quests from the Codex. Use the quest log.") end
      else
        confirmAbandon, confirmAt = quest.id, GetTime()
      end
      U.refresh()
    end, armed, "Abandon this quest. Click twice to confirm.")
    y = y + 32
  end
  return y
end

local function renderActive(y)
  local active, pinned = {}, {}
  for id in pairs(Q.logEntries()) do active[#active + 1] = id end
  table.sort(active)
  for _, id in ipairs(Q.pins()) do pinned[id] = true end
  if #active == 0 then return y end
  local count, max = Q.logCapacity()
  y = y + U.sectionTitle("Active quests" .. (max and (" (" .. count .. "/" .. max .. ")") or ""), y)
  local buttonWidth = math.floor(W * 0.46)
  for _, id in ipairs(active) do
    local entry = Q.log(id)
    local row = Q.questMatch(id)
    local name = Q.plain(entry.title or (row and row.step.name) or ("Quest " .. id))
    if row then
      U.btn("Show " .. name, 0, y, W - buttonWidth - 8, function()
        Q.followQuest(row)
        ns.showQuestViewer()
      end, false, "Follow the matching guide step.")
    else
      U.T(name, 0, y + 4, W - buttonWidth - 8, "small", C.dim)
    end
    if Q.incomplete(id) then
      U.btn((pinned[id] and "Untrack " or "Track ") .. name, W - buttonWidth, y, buttonWidth, function()
        if Q.togglePin(id) then ns.questRefresh() else ns.say("you can track up to three quests.") end
      end, pinned[id], "Keep this quest's progress in the step window.")
    end
    y = y + 28
  end
  return renderCleanup(y)
end

local function renderLibrary(rows, sections, y)
  y = y + U.T("Search by guide, quest name or quest ID", 0, y, W, "small", C.dim) + 5
  local function search()
    query, librarySection = draft, nil
    U.refreshTop()
  end
  U.questSearch(8, y, W - 100, draft, function(value) draft = value end, search)
  U.btn("Search", W - 80, y, 80, search)
  y = y + 34
  if librarySection then return renderLibrarySection(rows, librarySection, y) end
  if query:find("%S") then
    local guides, matches = Q.find(query)
    y = y + U.sectionTitle("Search results", y)
    if #guides + #matches == 0 then return y + U.T("No matching guides or quests.", 0, y, W, "body", C.dim) end
    for _, guide in ipairs(guides) do
      U.btn(guide.title, 0, y, W, function() showGuide(guide) end)
      y = y + 28
    end
    for i, row in ipairs(matches) do
      if i > 35 then return y + U.T("Narrow your search to see more results.", 0, y, W, "small", C.dim) end
      y = drawRow(row, y, row.step.name, STATUS[row.state] or "Details",
        row.section.title .. "\n" .. Q.questStatus(row), 160, false, Q.detail(row.step))
    end
    return y
  end

  y = renderActive(y)
  for _, group in ipairs({ { "dungeon", "Dungeons" }, { "special", "Special quest chains" } }) do
    local count = 0
    local col = math.floor((W - 12) / 2)
    for _, section in ipairs(sections) do
      if section.category == group[1] then
        if count == 0 then
          y = y + U.sectionTitle(group[2], y)
          if group[1] == "dungeon" then
            y = y + U.T("Plan the runs you mean to do: their pickups join your route, and the step window says when to find a group.",
              0, y, W, "small", C.dim) + 6
            local third = math.floor((W - 16) / 3)
            U.btn("Plan recommended", 0, y, third, function() setPlans(Q.recommendedRuns(), true) end, false,
              "Runs near your route or tied to your class quests, still in reach of your level.")
            U.btn("Plan all", third + 8, y, third, function() setPlans(Q.dungeons(), true) end)
            U.btn("Plan none", W - third, y, third, function() setPlans(nil) end)
            y = y + 34
          end
        end
        local x = count % 2 * (col + 12)
        local planned = section.category == "dungeon" and Q.planned(section.id)
        U.btn(section.title, x, y, col, function() showGuide(section) end, planned, "View steps and quest readiness.")
        U.T(section.category == "dungeon" and (sectionInfo(section) .. "\n" .. runInfo(section)) or sectionInfo(section),
          x, y + 25, col, "small", C.dim, "CENTER")
        count = count + 1
        if count % 2 == 0 then y = y + (group[1] == "dungeon" and 60 or 46) end
      end
    end
    if count % 2 == 1 then y = y + (group[1] == "dungeon" and 60 or 46) end
  end
  return y
end

-- The guide setup card: pace, dungeons and helpers in one place. It shows by itself for a new
-- character (level 5 or lower) until Done; Guide setup opens it any time.
local setupOpen = false

function ns.questSetupDue()
  return not ns.db().questSetupDone and (UnitLevel("player") or 1) <= 5
end

function ns.openQuestSetup()
  setupOpen, view = true, "route"
  ns.openTab("quests")
  U.refreshTop()
end

local function renderSetup(y)
  local db = ns.db()
  local top = y
  y = y + 12
  y = y + U.T("SET UP YOUR GUIDE", 16, y, W - 32, "label", C.inkSoft) + 4
  y = y + U.T("Pick how the guide plays. Settings has every option, and you can change these any time.",
    16, y, W - 32, "small", C.ink) + 8
  local half = math.floor((W - 40) / 2)
  local function pace(keep) db.questKeepGrey, db.questOptional = keep, keep; ns.updateQuestSettings() end
  U.btn("Fastest", 16, y, half, function() pace(false) end, not db.questKeepGrey and not db.questOptional,
    "Grey pickups leave the route and side errands stay hidden.")
  U.btn("Every quest", 24 + half, y, half, function() pace(true) end, db.questKeepGrey and db.questOptional,
    "Keep grey pickups and show side errands such as Camping 101.")
  y = y + 30
  U.btn("Plan recommended dungeons", 16, y, half, function() setPlans(Q.recommendedRuns(), true) end, false,
    "Runs near your route or tied to your class quests: their pickups join your route.")
  U.btn("No dungeons", 24 + half, y, half, function() setPlans(nil) end, false,
    "Leave dungeon pickups out. Quests > Guide library > Dungeons plans runs one by one.")
  y = y + 30
  local third = math.floor((W - 48) / 3)
  local function toggle(key) return function() db[key] = not db[key]; U.refresh() end end
  U.btn("Auto-accept", 16, y, third, toggle("questAutoAccept"), db.questAutoAccept,
    "Accept the guide's current quest by itself. Hold Alt to stop it.")
  U.btn("Auto turn-in", 24 + third, y, third, toggle("questAutoTurnin"), db.questAutoTurnin,
    "Turn in the guide's current quest by itself when there's no reward to choose. Hold Alt to stop it.")
  U.btn("Flights and binds", 32 + 2 * third, y, third, toggle("questAutoTravel"), db.questAutoTravel,
    "Take the step's flight, and pick the bind option at the step's inn (you accept the bind). Hold Alt to stop it.")
  y = y + 30
  U.btn("Done", 16, y, W - 32, function()
    db.questSetupDone, setupOpen = true, false
    ns.questRefresh()
    U.refresh()
  end, true)
  y = y + 34
  U.box(0, top, W, y - top, C.parch, C.edge)
  return y + 12
end

local function render()
  local rows, sections, missed, level, selected, ready = Q.rows()
  local current = Q.current()
  local y = U.sectionTitle("Quest Guide", 0)
  if #sections == 0 then
    return y + U.T("Your character has no published route yet.", 0, y, W, "body", C.dim) + 16
  end
  if setupOpen or ns.questSetupDue() then y = renderSetup(y) end

  if current then
    y = stepCard(current, y)
  elseif not selected then
    y = y + U.T("No route covers level " .. tostring(level) .. ". Choose a section below to review it.",
      0, y, W, "body", C.dim) + 12
  end

  local w = math.floor((W - 16) / 3)
  U.btn("Show step window", 0, y, w, ns.showQuestViewer, false,
    "Show the quest step and arrow while you play.")
  if selected and selected.side then
    U.btn("Return to leveling", w + 8, y, w, function()
      Q.returnToRoute()
      ns.showQuestViewer()
    end, false, "Go back to your leveling route. Detour quest progress comes from the game.")
  else
    U.btn("Resume active quest", w + 8, y, w, function()
      if Q.resumeActive() then ns.showQuestViewer()
      else ns.say("no active route quest to resume.") end
    end, false, "Resume a quest from your log, preferring your current zone. Required earlier quests are kept.")
  end
  U.btn("Copy recorder log", W - w, y, w, function() ns.questRecord("copy") end)
  y = y + 36

  local stepWidth = (W - 16) / 3
  U.btn("Previous step", 0, y, stepWidth, function() ns.moveQuestStep(true) end)
  U.btn("Next step", stepWidth + 8, y, stepWidth, function() ns.moveQuestStep(false) end)
  U.btn("Hide step window", W - stepWidth, y, stepWidth, ns.hideQuestViewer)
  y = y + 32
  if current then
    U.btn("Show on map", 0, y, stepWidth, ns.showQuestStepOnMap, false, "Open the world map where the current step is.")
    U.btn("Report this step", stepWidth + 8, y, stepWidth, ns.reportQuestStep, false,
      "Copy what the guide sees about this step (your position, quest log and the step) to send with a bug report.")
  end
  U.btn("Guide setup", W - stepWidth, y, stepWidth, function()
    setupOpen = not setupOpen
    U.refresh()
  end, setupOpen, "Pace, dungeons and helpers in one place.")
  y = y + 32
  local pointing = ns.pointingToFlightMaster()
  U.btn(pointing and "Back to the step" or "Nearest flight master", 0, y, W, ns.pointToFlightMaster, pointing,
    "Point the arrow at the closest flight master on your continent, until you open a flight map or press this again.")
  y = y + 32
  if current and current.step.type == "plan" then
    local half = (W - 8) / 2
    U.btn("Plan " .. current.step.name, 0, y, half, function() ns.planQuestRun(current.step.dungeon, true) end, true,
      "The run and its quests join your route, and the guide says when to find a group.")
    U.btn("Skip this run", half + 8, y, half, function() ns.planQuestRun(current.step.dungeon, false) end, false,
      "The run stays out of your route. Guide library > Dungeons can plan it later.")
    y = y + 32
  end

  local run = Q.readyRun()
  if run then
    U.btn("Run " .. run.title, 0, y, W, function()
      Q.jump(run)
      ns.showQuestViewer()
    end, true, "Your planned run is ready: its pickups are done. Find a group, then follow its checklist.")
    y = y + 34
  end
  U.btn("Guide library", 0, y, W, function()
    if view == "library" and not librarySection and not query:find("%S") then view = "route"
    else view, librarySection, query, draft = "library", nil, "", "" end
    U.refreshTop()
  end, view == "library", "Search guides, prepare for a dungeon, or track an active quest.")
  y = y + 36
  if view == "library" then return renderLibrary(rows, sections, y) + 12 end
  local related = Q.relatedGuide()
  if related then
    U.btn("Plan " .. related.title, 0, y, W, function() ns.openQuestGuide(related) end, false,
      "Check the pickups, prerequisites, and turn-ins for this guide.")
    y = y + 34
  end
  local choices = Q.suggestions(true)
  if #choices > 0 then y = y + U.T("ROUTE OPTIONS FOR YOUR LEVEL", 0, y, W, "label", C.gold) + 6 end
  for _, suggested in ipairs(choices) do
    U.btn("Try " .. suggested.title, 0, y, W, function() ns.followSuggestedQuestSection(suggested) end, false,
      "Follow this section and resume a quest there if you have one.")
    y = y + 36
  end

  -- Guides by level band: progress, a status tag, the suggested ones in gold.
  local column = (W - 12) / 2
  local suggestedSet = {}
  for _, section in ipairs(choices) do suggestedSet[section] = true end
  local function guideButtons(heading, list)
    if #list == 0 then return end
    y = y + U.T(heading, 0, y, W, "label", C.gold) + 6
    local rowHeight = 0
    for count, section in ipairs(list) do
      local x = (count - 1) % 2 * (column + 12)
      local status, done, total = Q.sectionStatus(section, suggestedSet)
      local parts = { "Levels " .. section.levels[1] .. "-" .. section.levels[2] }
      if total > 0 then parts[#parts + 1] = math.floor(done * 100 / total + 0.5) .. "% done" end
      if GUIDE_TAG[status] then parts[#parts + 1] = GUIDE_TAG[status] end
      if section.alternate then parts[#parts + 1] = "Alternate" end
      U.btn(section.title, x, y, column, function()
        view = "route"
        Q.jump(section)
        ns.showQuestViewer()
      end, status == "current" or status == "suggested", "Follow this section in the step window.")
      local faded = status == "done" or status == "outleveled" or status == "later"
      local h = U.T(table.concat(parts, "  |  "), x, y + 25, column, "small",
        status == "suggested" and C.gold or faded and C.dim or C.light, "CENTER")
      rowHeight = math.max(rowHeight, 25 + h + 9, 46)
      if count % 2 == 0 or count == #list then y, rowHeight = y + rowHeight, 0 end
    end
  end
  local bands, classes = {}, {}
  for _, band in ipairs(BANDS) do bands[band] = {} end
  for _, section in ipairs(sections) do
    if not section.category then
      if section.side then
        classes[#classes + 1] = section
      else
        for _, band in ipairs(BANDS) do
          if section.levels[1] <= band[2] then table.insert(bands[band], section); break end
        end
      end
    end
  end
  for _, band in ipairs(BANDS) do guideButtons(band[3], bands[band]) end
  if not ns.db().noClassQuests then guideButtons("CLASS QUESTS", classes) end

  local function viewButton(key, label, x)
    U.btn(label, x, y, w, function() view = key; U.refresh() end, view == key)
  end
  viewButton("route", "Route", 0)
  viewButton("ready", "Ready to turn in (" .. #ready .. ")", w + 8)
  viewButton("missed", "Missed quests (" .. (#missed + #Q.greyPickups()) .. ")", W - w)
  y = y + 34

  if view == "ready" then
    y = renderQueue(y, "Ready to turn in", ready, "Ready", "No route quests are ready to turn in.",
      "Show the turn-in in the step window.")
  elseif view == "missed" then
    y = renderQueue(y, "Missed quests", missed, "Pickup", "No earlier pickups match your level.",
      "Review this earlier pickup in the step window.")
    local grey = Q.greyPickups()
    if #grey > 0 then
      y = y + 8
      y = renderQueue(y, "Outleveled (grey)", grey, "Grey", "",
        "Grey pickups left the route. Settings > Keep grey quests in the route brings them back.")
    end
  else
    y = renderRoute(rows, selected, current, y)
  end
  return y + 12
end

ns.addTab("quests", "Quests", render)

function ns.openQuestGuide(section)
  view, librarySection, query, draft = "library", section, "", ""
  ns.openTab("quests")
  U.refreshTop()
end
