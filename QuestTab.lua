-- QuestTab.lua: the Quests tab. A fixed top (the current step with its completion bar and one row of
-- step buttons), then four sub-tabs: Step (what to do now and the step's tools), Route (this
-- guide's steps), Guides (search, guides by level band, dungeons, special and class chains) and
-- Quest log (active quests, ready turn-ins, missed and grey pickups, clean-up).
local _, ns = ...
local Q, U, C = ns.quests, ns.ui, ns.C
local W = U.W
local sub, allSteps = "route", false -- the sub-tab shown (this session) and Route's Show all steps
local librarySection, query, draft = nil, "", ""
local openBands = {} -- band -> true/false once you open or fold it (else yours and the next are open)

local STATUS = { pending = "To do", done = "Done", deferred = "Earlier", skipped = "Skipped", blocked = "Blocked" }
local GUIDE_TAG = { current = "Current", done = "Done", outleveled = "Outleveled", suggested = "Suggested", later = "Later" }
-- Leveling guides are listed by the band their first level falls in.
local BANDS = { { 1, 11, "LEVELS 1-12: STARTING ZONES" }, { 12, 19, "LEVELS 12-20" }, { 20, 29, "LEVELS 20-30" },
  { 30, 39, "LEVELS 30-40" }, { 40, 49, "LEVELS 40-50" }, { 50, 60, "LEVELS 50-60" } }
local SUBS = { { "step", "Step" }, { "route", "Route" }, { "guides", "Guides" }, { "log", "Quest log" } }

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

-- Which dungeon plan the setup lights: "all" (Plan every dungeon run, or every run planned),
-- "none", "recommended" (exactly Q.recommendedRuns()) or "picks", with the planned count. Only
-- runs you haven't outleveled count, as for the recommended ones, so Recommended stays lit as
-- you level past some of its runs.
local function dungeonState()
  local _, _, _, lvl = Q.rows()
  local all, planned, set, every = Q.dungeons(), 0, {}, true
  for _, section in ipairs(all) do
    local on = Q.planned(section.id)
    if not on then every = false end
    if on and (lvl or 1) <= section.levels[2] then planned, set[section.id] = planned + 1, true end
  end
  if ns.db().questDungeons or (#all > 0 and every) then return "all", planned end
  if planned == 0 then return "none", 0 end
  local recommended = Q.recommendedRuns()
  local same = #recommended == planned
  for _, section in ipairs(recommended) do if not set[section.id] then same = false end end
  return same and "recommended" or "picks", planned
end

-- The dungeon choices: Recommended, All, None (the setup card and Guides > Dungeons).
local DUNGEON_TIPS = { "Runs near your route or tied to your class quests: their pickups join your route.",
  "Plan every dungeon run: all their pickups join your route.",
  "Leave dungeon pickups out. Quests > Guides > Dungeons plans runs one by one." }
local function pickDungeons(i)
  local db = ns.db()
  if i == 1 then db.questDungeons = false; setPlans(Q.recommendedRuns(), true)
  elseif i == 2 then db.questDungeons = true; setPlans(Q.dungeons(), true)
  elseif i == 3 then db.questDungeons = false; setPlans(nil)
  else U.refresh() end
end
local function dungeonChoices(x, y, w)
  local state, planned = dungeonState()
  local labels, tips = { "Recommended", "All", "None" }, { DUNGEON_TIPS[1], DUNGEON_TIPS[2], DUNGEON_TIPS[3] }
  local lit = ({ recommended = 1, all = 2, none = 3 })[state]
  if state == "picks" then
    labels[4], tips[4], lit = "Your picks (" .. planned .. ")", "The runs you planned one by one.", 4
  end
  return U.segments(x, y, w, labels, lit, pickDungeons, tips)
end

local function show(key)
  sub = key
  U.refreshTop()
end

-- The current step's card, with the guide's completion bar under the step text.
local function stepCard(row, y)
  local top = y
  y = y + 13
  local label = Q.autoStep() and "CURRENT STEP" or "STEP PREVIEW"
  local heading = U.T(label, 16, y, 128, "label", C.inkSoft)
  local section = U.T(row.section.title, 148, y, W - 164, "small", C.inkSoft, "RIGHT")
  y = y + math.max(heading, section) + 6
  y = y + U.T(Q.label(row.step), 16, y, W - 32, "head", C.ink) + 4
  y = y + U.T(Q.detail(row.step, row.requiredFor, row == Q.current()), 16, y, W - 32, "body", C.ink) + 10
  local passed, total = Q.stepProgress(row.section)
  if total > 0 and not ns.db().noStepBar then
    local track = W - 32 - 48
    U.rect(16, y + 3, track, 6, C.edgeSoft)
    if passed > 0 then U.rect(16, y + 3, math.max(1, math.floor(track * passed / total)), 6, C.accent) end
    U.T(math.floor(passed * 100 / total) .. "%", W - 16 - 44, y, 44, "small", C.inkSoft, "RIGHT")
    y = y + 16
  end
  y = y + 4
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
  if #list == 0 then return y + U.T(empty, 0, y, W, "body", C.dim) + 8 end
  for _, row in ipairs(list) do
    local follow = row.section.side and status == "Pickup"
    y = drawRow(row, y, row.step.name, status, row.section.title, 136, false,
      follow and "Follow this class quest chain." or tip, follow)
  end
  return y + 8
end

----------------------------------------------------------------------------
-- Route
----------------------------------------------------------------------------

local function renderRoute(rows, selected, current, y)
  -- Other routes for your level (alternates and the next zone), above this guide's steps.
  local choices = Q.suggestions(true)
  if #choices > 0 then y = y + U.T("ROUTE OPTIONS FOR YOUR LEVEL", 0, y, W, "label", C.gold) + 6 end
  for _, suggested in ipairs(choices) do
    U.btn("Try " .. suggested.title, 0, y, W, function() ns.followSuggestedQuestSection(suggested) end, false,
      "Follow this section and resume a quest there if you have one.")
    y = y + 34
  end
  if #choices > 0 then y = y + 6 end
  if not selected then
    return y + U.T("No guide is selected. Pick one under Guides.", 0, y, W, "body", C.dim)
  end
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

----------------------------------------------------------------------------
-- Guides
----------------------------------------------------------------------------

local function followGuide(section, phase)
  Q.jump(section, nil, phase)
  ns.showQuestViewer()
end

local function showGuide(section)
  librarySection = section
  U.refreshTop()
end

local function renderLibrarySection(rows, section, y)
  U.btn("Back to guides", 0, y, 160, function()
    librarySection = nil
    U.refreshTop()
  end, false, "Back to the list of guides.")
  y = y + 34
  y = y + U.sectionTitle(section.title, y)
  y = y + U.T(sectionInfo(section), 0, y, W, "small", C.dim) + 4
  if section.reward then y = y + U.T("You get: " .. Q.plain(section.reward), 0, y, W, "body", C.gold) + 4 end
  y = y + 4
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

-- A guide as a quest-log row (36 px): a 3 px edge (gold current, teal suggested), the title on one
-- line, its levels, a step progress bar under the title and one tag at the right. A guide with a
-- `reward` (special and class quests) adds what you get under the bar (48 px).
local TRACK = { 0.14, 0.21, 0.23, 1 }
local function guideRow(y, section, status, done, total, tag, onClick, tip)
  local current, suggested = status == "current", status == "suggested"
  local height = section.reward and 48 or 36
  if current then U.rect(0, y, W, height, { C.accent[1], C.accent[2], C.accent[3], 0.12 }) end
  if current or suggested then U.rect(0, y, 3, height, current and C.gold or C.accent) end
  local faded = status == "done" or status == "outleveled" or status == "later"
  local _, title = U.T(Q.plain(section.title), 12, y + 5, W - 200, "body",
    current and C.gold or faded and C.dim or C.light)
  if title.SetWordWrap then title:SetWordWrap(false) end
  U.T("Levels " .. section.levels[1] .. "-" .. section.levels[2], W - 186, y + 7, 90, "small", C.dim, "RIGHT")
  U.rect(12, y + 22, W - 212, 4, TRACK)
  if total > 0 and done > 0 then U.rect(12, y + 22, math.max(1, (W - 212) * done / total), 4, C.accent) end
  if section.reward then
    local _, line = U.T(Q.plain(section.reward), 12, y + 30, W - 106, "small", C.dim)
    if line.SetWordWrap then line:SetWordWrap(false) end
  end
  if tag then
    U.plate(W - 90, y + 7, 84, 20, { 0, 0, 0, 0.35 }, { C.edge[1], C.edge[2], C.edge[3], 0.6 })
    U.T(tag, W - 90, y + 11, 84, "small", current and C.gold or suggested and C.accent or faded and C.dim or C.light,
      "CENTER")
  end
  U.hit(0, y, W, height, Q.plain(section.title), tip, onClick, section.title)
  return y + height + 2
end

-- A guide's tag: Current, Suggested, Side (an alternate route), Later, Done or Outleveled, with
-- its percentage for Current, Side and Later once you've started it.
local function guideTag(section, status, done, total)
  local tag = GUIDE_TAG[status]
  if section.alternate and (status == "open" or status == "later") then tag = "Side" end
  local pct = total > 0 and math.floor(done * 100 / total) or 0
  if pct > 0 and (tag == "Current" or tag == "Side" or tag == "Later") then tag = tag .. " " .. pct .. "%" end
  return tag
end

-- Leveling guides (and class quests) as rows: clicking one follows it in the step window.
local function guideRows(y, list, suggestedSet)
  for _, section in ipairs(list) do
    local status, done, total = Q.sectionStatus(section, suggestedSet)
    y = guideRow(y, section, status, done, total, guideTag(section, status, done, total), function()
      sub = "route"
      Q.jump(section)
      ns.showQuestViewer()
    end, "Follow this section in the step window.")
  end
  return y
end

local function renderGuides(rows, sections, y)
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
    U.btn("Clear search", 0, y, 160, function()
      query, draft = "", ""
      U.refreshTop()
    end)
    y = y + 34
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

  -- Leveling guides by level band: yours and the next one open, the others folded to one line.
  local _, _, _, level = Q.rows()
  local choices = Q.suggestions(true)
  local suggestedSet = {}
  for _, section in ipairs(choices) do suggestedSet[section] = true end
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
  local yours
  for n, band in ipairs(BANDS) do
    if level >= band[1] and level <= band[2] then yours = n end
  end
  for n, band in ipairs(BANDS) do
    local list = bands[band]
    if #list > 0 then
      local open = openBands[band]
      if open == nil then open = yours ~= nil and (n == yours or n == yours + 1) end
      local done = 0
      for _, section in ipairs(list) do
        if Q.sectionStatus(section, suggestedSet) == "done" then done = done + 1 end
      end
      -- a fold row like the quest log's headers: plus folded, minus open; the label keeps
      -- "+ LEVELS 20-30: 8 guides, 1 done" for controllers and the harness
      local levels = band[3]:match("^(LEVELS %d+%-%d+)")
      local count = #list .. (#list == 1 and " guide" or " guides")
        .. (done == #list and ", all done" or done > 0 and (", " .. done .. " done") or "")
      U.fold(open, 0, y + 4)
      local _, head = U.T(levels, 22, y + 4, 140, "label", C.gold)
      local headWidth = tonumber(head.GetStringWidth and head:GetStringWidth()) or 90
      U.T(count, 22 + math.min(headWidth, 140) + 10, y + 6, 300, "small", C.dim)
      U.hit(0, y, W, 24, levels, open and "Fold these guides." or "Show these guides.", function()
        openBands[band] = not open
        U.refresh()
      end, (open and "- " or "+ ") .. levels .. ": " .. count)
      y = y + 28
      if open then y = guideRows(y, list, suggestedSet) + 4 end
    end
  end

  for _, group in ipairs({ { "dungeon", "Dungeons" }, { "special", "Special quest chains" } }) do
    local count = 0
    for _, section in ipairs(sections) do
      if section.category == group[1] then
        if count == 0 then
          y = y + 6 + U.sectionTitle(group[2], y + 6)
          if group[1] == "dungeon" then
            y = y + U.T("Plan the runs you mean to do: their pickups join your route, and the step window says when to find a group.",
              0, y, W, "small", C.dim) + 6
            y = y + dungeonChoices(0, y, W) + 10
          end
        end
        local status, done, total = Q.sectionStatus(section, suggestedSet)
        local tag, tip = guideTag(section, status, done, total), "View steps and quest readiness."
        if section.category == "dungeon" then
          local planned = Q.planned(section.id)
          tag, tip = planned and "Planned" or "Not planned", runInfo(section) .. ". View steps and quest readiness."
          if status ~= "current" and status ~= "done" and status ~= "outleveled" then
            status = planned and "suggested" or "open"
          end
        end
        y = guideRow(y, section, status, done, total, tag, function() showGuide(section) end, tip)
        count = count + 1
      end
    end
  end
  if not ns.db().noClassQuests and #classes > 0 then
    y = y + 6 + U.sectionTitle("Class quests", y + 6)
    y = guideRows(y, classes, suggestedSet)
  end
  return y
end

----------------------------------------------------------------------------
-- Quest log
----------------------------------------------------------------------------

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
  local count, max = Q.logCapacity()
  y = y + U.sectionTitle("Active quests" .. (max and (" (" .. count .. "/" .. max .. ")") or ""), y)
  if #active == 0 then return y + U.T("Your quest log is empty.", 0, y, W, "body", C.dim) + 8 end
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
  return y + 8
end

local function renderLog(missed, ready, y)
  y = renderActive(y)
  y = renderQueue(y, "Ready to turn in (" .. #ready .. ")", ready, "Ready", "No route quests are ready to turn in.",
    "Show the turn-in in the step window.")
  local grey = Q.greyPickups()
  y = renderQueue(y, "Missed quests (" .. (#missed + #grey) .. ")", missed, "Pickup", "No earlier pickups match your level.",
    "Review this earlier pickup in the step window.")
  if #grey > 0 then
    y = renderQueue(y, "Outleveled (grey)", grey, "Grey", "",
      "Grey pickups left the route. Settings > Keep grey quests in the route brings them back.")
  end
  return renderCleanup(y)
end

----------------------------------------------------------------------------
-- Step
----------------------------------------------------------------------------

local function renderStepView(current, selected, y)
  local half = (W - 8) / 2
  if current and current.step.type == "plan" then
    U.btn("Plan " .. current.step.name, 0, y, half, function() ns.planQuestRun(current.step.dungeon, true) end, true,
      "The run and its quests join your route, and the guide says when to find a group.")
    U.btn("Skip this run", half + 8, y, half, function() ns.planQuestRun(current.step.dungeon, false) end, false,
      "The run stays out of your route. Guides > Dungeons can plan it later.")
    y = y + 34
  end
  local run = Q.readyRun()
  if run then
    U.btn("Run " .. run.title, 0, y, W, function()
      Q.jump(run)
      ns.showQuestViewer()
    end, true, "Your planned run is ready: its pickups are done. Find a group, then follow its checklist.")
    y = y + 34
  end
  local related = Q.relatedGuide()
  if related then
    U.btn("Plan " .. related.title, 0, y, W, function() ns.openQuestGuide(related) end, false,
      "Check the pickups, prerequisites, and turn-ins for this guide.")
    y = y + 34
  end
  if selected and selected.side then
    U.btn("Return to leveling", 0, y, half, function()
      Q.returnToRoute()
      ns.showQuestViewer()
    end, false, "Go back to your leveling route. Detour quest progress comes from the game.")
  else
    U.btn("Resume active quest", 0, y, half, function()
      if Q.resumeActive() then ns.showQuestViewer()
      else ns.say("no active route quest to resume.") end
    end, false, "Resume a quest from your log, preferring your current zone. Required earlier quests are kept.")
  end
  local pointing = ns.pointingToFlightMaster()
  U.btn(pointing and "Back to the step" or "Nearest flight master", half + 8, y, half, ns.pointToFlightMaster, pointing,
    "Point the arrow at the closest flight master on your continent, until you open a flight map or press this again.")
  y = y + 36
  y = y + 6 + U.sectionTitle("Help", y + 6)
  if current then
    U.btn("Report this step", 0, y, half, ns.reportQuestStep, false,
      "Copy what the guide sees about this step (your position, quest log and the step) to send with a bug report.")
  end
  U.btn("Copy recorder log", half + 8, y, half, function() ns.questRecord("copy") end)
  return y + 32
end

----------------------------------------------------------------------------
-- Guide setup: pace, dungeons and helpers in one place. It shows by itself for a new character
-- (level 5 or lower) until Done; the Setup button opens it any time.
----------------------------------------------------------------------------

local setupOpen = false

function ns.questSetupDue()
  return not ns.db().questSetupDone and (UnitLevel("player") or 1) <= 5
end

function ns.openQuestSetup()
  setupOpen, sub = true, "step"
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
  local x, w = 108, W - 16 - 108
  local function label(text) U.T(text, 16, y + 5, 88, "body", C.ink) end
  -- Pace: Fastest (no grey pickups, no side errands) or Every quest (both); a mix lights neither.
  local fastest = not db.questKeepGrey and not db.questOptional
  local every = db.questKeepGrey and db.questOptional
  label("Pace")
  y = y + U.segments(x, y, w, { "Fastest", "Every quest" }, fastest and 1 or every and 2 or nil, function(i)
    db.questKeepGrey, db.questOptional = i == 2, i == 2
    ns.updateQuestSettings()
  end, { "Grey pickups leave the route and side errands stay hidden.",
    "Keep grey pickups and show side errands such as Camping 101." }) + 4
  if not (fastest or every) then y = y + U.T("Custom: see Settings", x, y, w, "small", C.dim) + 4 end
  y = y + 6
  label("Dungeons")
  y = y + dungeonChoices(x, y, w) + 10
  label("Helpers")
  local function toggle(key) return function() db[key] = not db[key]; U.refresh() end end
  U.check("Auto-accept", x, y - 1, db.questAutoAccept, toggle("questAutoAccept"),
    "Accept the guide's current quest by itself. Hold Alt to stop it.")
  U.check("Auto turn-in", x + 150, y - 1, db.questAutoTurnin, toggle("questAutoTurnin"),
    "Turn in the guide's current quest by itself when there's no reward to choose. Hold Alt to stop it.")
  U.check("Auto-fly and bind", x + 300, y - 1, db.questAutoTravel, toggle("questAutoTravel"),
    "Take the step's flight, and pick the bind option at the step's inn (you accept the bind). Hold Alt to stop it.")
  y = y + 30
  label("Map lines")
  U.check("Minimap", x, y - 1, not db.noMinimapLine, function()
    db.noMinimapLine = not db.noMinimapLine
    U.refresh()
  end, "Gold dots on the minimap from you to the current step.")
  U.check("World map", x + 150, y - 1, not db.noWorldMapLine, function()
    db.noWorldMapLine = not db.noWorldMapLine
    ns.questRefresh()
    U.refresh()
  end, "The same dots on your world map.")
  y = y + 34
  U.btn("Done", 16, y, W - 32, function()
    db.questSetupDone, setupOpen = true, false
    ns.questRefresh()
    U.refresh()
  end, true)
  y = y + 34
  U.box(0, top, W, y - top, C.parch, C.edge)
  return y + 12
end

----------------------------------------------------------------------------
-- The tab
----------------------------------------------------------------------------

local function render()
  local rows, sections, missed, level, selected, ready = Q.rows()
  local current = Q.current()
  local y = U.sectionTitle("Quest Guide", 0)
  U.btn("Setup", W - 90, 0, 90, function()
    setupOpen = not setupOpen
    U.refresh()
  end, setupOpen, "Pace, dungeons and helpers in one place.")
  if #sections == 0 then
    return y + U.T("Your character has no published route yet.", 0, y, W, "body", C.dim) + 16
  end
  if setupOpen or ns.questSetupDue() then y = renderSetup(y) end

  if current then
    y = stepCard(current, y)
  elseif not selected then
    y = y + U.T("No route covers level " .. tostring(level) .. ". Choose a guide under Guides.",
      0, y, W, "body", C.dim) + 12
  end

  local quarter = (W - 24) / 4
  U.btn("Previous step", 0, y, quarter, function() ns.moveQuestStep(true) end)
  -- On a Dungeon ahead step, Next leaves the run out, so it says Skip (like the step window's).
  local choosing = current and current.step.type == "plan"
  U.btn(choosing and "Skip run" or "Next step", quarter + 8, y, quarter, function() ns.moveQuestStep(false) end,
    false, choosing and "The run stays out of your route. Guides > Dungeons can plan it later." or nil)
  U.btn("Show on map", 2 * (quarter + 8), y, quarter, ns.showQuestStepOnMap, false,
    "Open the world map where the current step is.")
  local viewer = _G.LevelingCodexQuestViewer
  local shown = viewer and viewer:IsShown()
  U.btn(shown and "Hide step window" or "Show step window", 3 * (quarter + 8), y, quarter, function()
    if shown then ns.hideQuestViewer() else ns.showQuestViewer() end
    U.refresh()
  end, false, "Show or hide the quest step and arrow while you play.")
  y = y + 38

  for i, s in ipairs(SUBS) do
    U.btn(s[2], (i - 1) * (quarter + 8), y, quarter, function()
      if s[1] == "guides" and sub == "guides" then librarySection = nil end
      show(s[1])
    end, sub == s[1])
  end
  y = y + 30
  U.goldRuleAt(y)
  y = y + 12

  if sub == "route" then y = renderRoute(rows, selected, current, y)
  elseif sub == "guides" then y = renderGuides(rows, sections, y)
  elseif sub == "log" then y = renderLog(missed, ready, y)
  else y = renderStepView(current, selected, y) end
  return y + 12
end

ns.addTab("quests", "Quests", render)

-- The step window's Quests button: the Step sub-tab.
function ns.openQuestStep()
  sub = "step"
  ns.openTab("quests")
  U.refreshTop()
end

-- The step window's completion bar opens the current guide's route.
function ns.openQuestRoute()
  sub = "route"
  ns.openTab("quests")
  U.refreshTop()
end

function ns.openQuestGuide(section)
  sub, librarySection, query, draft = "guides", section, "", ""
  ns.openTab("quests")
  U.refreshTop()
end
