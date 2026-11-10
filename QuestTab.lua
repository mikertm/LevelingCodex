-- QuestTab.lua: the current step, section browser and quest queues.
local _, ns = ...
local Q, U, C = ns.quests, ns.ui, ns.C
local W = U.W
local view, allSteps = "route", false

local STATUS = { pending = "To do", done = "Done", deferred = "Earlier", skipped = "Skipped" }

local function sectionInfo(section)
  return "Levels " .. section.levels[1] .. "-" .. section.levels[2] ..
    (section.verified and "" or "  |  Unverified")
end

local function stepCard(row, y)
  local top = y
  y = y + 13
  local label = Q.autoStep() and "CURRENT STEP" or "STEP PREVIEW"
  local heading = U.T(label, 16, y, 128, "label", C.inkSoft)
  local section = U.T(row.section.title, 148, y, W - 164, "small", C.inkSoft, "RIGHT")
  y = y + math.max(heading, section) + 6
  y = y + U.T(Q.label(row.step), 16, y, W - 32, "head", C.ink) + 4
  y = y + U.T(Q.detail(row.step, row.requiredFor), 16, y, W - 32, "body", C.ink) + 14
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
      y = drawRow(row, y, Q.label(row.step), active and "Current" or STATUS[row.state],
        row.step.forever and "Forever" or nil, 62, active)
      visible = true
    end
  end
  if not visible then
    y = y + U.T("No remaining steps in this section.", 0, y, W, "body", C.dim)
  end
  return y
end

local function render()
  local rows, sections, missed, level, selected, ready = Q.rows()
  local current = Q.current()
  local y = U.sectionTitle("Quest Guide", 0)
  if #sections == 0 then
    return y + U.T("Your character has no published route yet.", 0, y, W, "body", C.dim) + 16
  end

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
    end, false, "Go back to your leveling route. Class quest progress comes from the game.")
  else
    U.btn("Resume active quest", w + 8, y, w, function()
      if Q.resumeActive() then ns.showQuestViewer()
      else ns.say("no active route quest to resume.") end
    end, false, "Resume a quest from your log, preferring your current zone. Required earlier quests are kept.")
  end
  U.btn("Copy recorder log", W - w, y, w, function() ns.questRecord("copy") end)
  y = y + 36

  local stepWidth = (W - 24) / 4
  U.btn("Previous step", 0, y, stepWidth, function() ns.moveQuestStep(true) end)
  U.btn("Next step", stepWidth + 8, y, stepWidth, function() ns.moveQuestStep(false) end)
  U.btn("Pin step", 2 * (stepWidth + 8), y, stepWidth, ns.pinQuestStep)
  U.btn("Hide step window", W - stepWidth, y, stepWidth, ns.hideQuestViewer)
  y = y + 32

  local choices = Q.suggestions(true)
  if #choices > 0 then y = y + U.T("ROUTE OPTIONS FOR YOUR LEVEL", 0, y, W, "label", C.gold) + 6 end
  for _, suggested in ipairs(choices) do
    U.btn("Try " .. suggested.title, 0, y, W, function() ns.followSuggestedQuestSection(suggested) end, false,
      "Follow this section and resume a quest there if you have one.")
    y = y + 36
  end

  local column = (W - 12) / 2
  local function sectionButtons(heading, kind)
    local count = 0
    for _, section in ipairs(sections) do
      if (section.side and "class" or section.alternate and "alternate" or "main") == kind then
        if count == 0 then y = y + U.T(heading, 0, y, W, "label", C.gold) + 6 end
        local x = count % 2 * (column + 12)
        U.btn(section.title, x, y, column, function()
          view = "route"
          Q.jump(section)
          ns.showQuestViewer()
        end, selected == section, "Follow this section in the step window.")
        U.T(sectionInfo(section), x, y + 25, column, "small", C.dim, "CENTER")
        count = count + 1
        if count % 2 == 0 then y = y + 46 end
      end
    end
    if count % 2 == 1 then y = y + 46 end
  end
  sectionButtons("ROUTE SECTIONS", "main")
  sectionButtons("ALTERNATE ROUTES", "alternate")
  if not ns.db().noClassQuests then sectionButtons("CLASS QUESTS", "class") end

  local function viewButton(key, label, x)
    U.btn(label, x, y, w, function() view = key; U.refresh() end, view == key)
  end
  viewButton("route", "Route", 0)
  viewButton("ready", "Ready to turn in (" .. #ready .. ")", w + 8)
  viewButton("missed", "Missed quests (" .. #missed .. ")", W - w)
  y = y + 34

  if view == "ready" then
    y = renderQueue(y, "Ready to turn in", ready, "Ready", "No route quests are ready to turn in.",
      "Show the turn-in in the step window.")
  elseif view == "missed" then
    y = renderQueue(y, "Missed quests", missed, "Pickup", "No earlier pickups match your level.",
      "Review this earlier pickup in the step window.")
  else
    y = renderRoute(rows, selected, current, y)
  end
  return y + 12
end

ns.addTab("quests", "Quests", render)
