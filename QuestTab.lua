-- QuestTab.lua: the Quests tab. A fixed top (the current step with its completion bar and one row of
-- step buttons), then five sub-tabs: Step (what to do now and the step's tools), Route (this
-- guide's steps), Guides (search, guides by level band, dungeons, special and class chains),
-- Quest log (active quests, ready turn-ins, missed and grey pickups, clean-up) and Party (each
-- party member's step and quests, and the party switches).
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
local SUBS = { { "step", "Step" }, { "route", "Route" }, { "guides", "Guides" }, { "log", "Quest log" }, { "party", "Party" } }

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

-- A guide's page (Guides), where Start this route switches to it: clicking a guide never switches
-- by itself. `from` = the sub-tab its Back button returns to ("route" for Other routes).
local pageFrom
local function previewGuide(section, from)
  sub, librarySection, pageFrom = "guides", section, from or "route"
  U.refreshTop()
end

-- The step buttons (Previous / Next / Show on map / Hide step window), one row at y inside the
-- step card (x 16 to W - 16), or on their own when there is no step.
local function stepButtons(current, x, y, w)
  local each = (w - 24) / 4
  U.btn("Previous step", x, y, each, function() ns.moveQuestStep(true) end)
  -- On a Dungeon ahead step, Next leaves the run out, so it says Skip (like the step window's).
  local choosing = current and current.step.type == "plan"
  local eliteAsk = current and current.step.type == "elite"
  U.btn(choosing and "Skip run" or eliteAsk and "Skip" or "Next step", x + each + 8, y, each,
    function() ns.moveQuestStep(false) end, false,
    choosing and "The run stays out of your route. Guides > Dungeons can plan it later."
    or eliteAsk and "The guide passes this elite quest and the quests that need it." or nil)
  U.btn("Show on map", x + 2 * (each + 8), y, each, ns.showQuestStepOnMap, false,
    "Open the world map where the current step is.")
  local viewer = _G.LevelingCodexQuestViewer
  local shown = viewer and viewer:IsShown()
  U.btn(shown and "Hide step window" or "Show step window", x + 3 * (each + 8), y, each, function()
    if shown then ns.hideQuestViewer() else ns.showQuestViewer() end
    U.refresh()
  end, false, "Show or hide the quest step and arrow while you play.")
  return 22
end

-- The current step's card: the guide and its progress on top, the step, what to do (smaller), and
-- the step buttons along the bottom.
local function stepCard(row, y)
  local top = y
  y = y + 12
  local label = Q.autoStep() and "CURRENT STEP" or "STEP PREVIEW"
  local heading = U.T(label, 16, y, 128, "label", C.inkSoft)
  local passed, total = Q.stepProgress(row.section)
  local bar = total > 0 and not ns.db().noStepBar
  local guide = Q.plain(row.section.title) .. (bar and ("  -  " .. math.floor(passed * 100 / total) .. "%") or "")
  local section = U.T(guide, 148, y, W - 164, "small", C.inkSoft, "RIGHT")
  y = y + math.max(heading, section) + 2
  if bar then
    -- a thin bar under the heading row: how far into this guide you are
    U.rect(16, y + 2, W - 32, 3, C.edgeSoft)
    if passed > 0 then U.rect(16, y + 2, math.max(1, math.floor((W - 32) * passed / total)), 3, C.accent) end
  end
  y = y + 10
  y = y + U.T(Q.label(row.step), 16, y, W - 32, "head", C.ink) + 3
  y = y + U.T(Q.detail(row.step, row.requiredFor, row == Q.current()), 16, y, W - 32, "small", C.ink) + 10
  y = y + stepButtons(row, 16, y, W - 32) + 12
  U.box(0, top, W, y - top, C.parch, C.edge)
  return y + 10
end

local function openStep(row, follow)
  Q.jump(row.section, not follow and row or nil)
  ns.showQuestViewer()
end

-- `still`: a step of a route you're only looking at (its page): hovering shows it, clicking does nothing.
local function drawRow(row, y, title, status, secondary, secondaryWidth, active, tip, follow, still)
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
  U.hit(0, y, W, height, title, tip or row.step.text, not still and function() openStep(row, follow) end or nil)
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

-- A guide as a quest-log row (36 px): a 3 px edge (gold current, teal suggested), the title on one
-- line, its levels, a step progress bar under the title and one tag at the right. A guide with a
-- `reward` (special and class quests) adds what you get under the bar (48 px).
local TRACK = { 0.14, 0.21, 0.23, 1 }
local function guideRow(y, section, status, done, total, tag, onClick, tip, label)
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
  U.hit(0, y, W, height, Q.plain(section.title), tip, onClick, label or section.title)
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

----------------------------------------------------------------------------
-- Route
----------------------------------------------------------------------------

-- The guide you're on, first thing on the Route sub-tab, so the other routes under it don't read
-- as a choice you still have to make.
-- The route you just started (Start this route), confirmed on its card for half a minute.
local started
local function startedRecently(section)
  local now = tonumber(GetTime and GetTime())
  return started and started.section == section and now and now - started.at < 30
end

local function followingCard(selected, current, y)
  local on = current and current.section or selected
  if not on then return y end
  local top = y
  local route = not on.side
  y = y + 10
  U.btn("Change route", W - 148, y - 2, 132, function()
    librarySection, pageFrom = nil, nil
    show("guides")
  end, false, "Pick another route under Guides. Nothing changes until you press Start on its page.")
  y = y + U.T(route and "YOU ARE ON THIS ROUTE" or "YOU ARE FOLLOWING THIS GUIDE", 16, y, W - 180, "label", C.inkSoft) + 4
  y = y + U.T(Q.plain(on.title), 16, y, W - 180, "head", C.ink) + 2
  local info = on.levels and ("Levels " .. on.levels[1] .. "-" .. on.levels[2]) or ""
  local passed, total = Q.stepProgress(on)
  if total > 0 then info = info .. (info ~= "" and ", " or "") .. math.floor(passed * 100 / total) .. "% done" end
  if info ~= "" then y = y + U.T(info, 16, y, W - 180, "small", C.inkSoft) + 2 end
  if startedRecently(on) then
    y = y + 2 + U.T("Started. The step window and arrow follow it now.", 16, y + 2, W - 32, "small", C.green) + 2
  end
  y = math.max(y, top + 40) + 8
  U.box(0, top, W, y - top, C.parch, C.edge)
  return y + 12
end

local function renderRoute(rows, selected, current, y)
  y = followingCard(selected, current, y)
  local _, _, _, level = Q.rows()
  local place = current and current.section or selected
  local prepHeading
  for _, dungeon in ipairs(Q.dungeons()) do
    local _, left = Q.runReadiness(dungeon)
    if place and left > 0 and level >= dungeon.levels[1] - 5 and level <= dungeon.levels[2]
        and (Q.planned(dungeon.id) or dungeon.zone == place.zone) then
      if not prepHeading then
        y = y + U.sectionTitle("DUNGEON PREPARATION", y)
        y = y + U.T("Gather quests and finish outdoor chains while leveling. Choose when to run the dungeon.", 0, y, W, "small", C.dim) + 6
        prepHeading = true
      end
      U.btn("Prepare: " .. dungeon.title, 0, y, W, function()
        Q.setPlanned(dungeon.id, true)
        Q.jump(dungeon, nil, "prepareOnly")
        ns.showQuestViewer()
      end, false, left .. " outdoor pickups remain. Suggested run levels " .. dungeon.levels[1] .. "-" .. dungeon.levels[2] .. ".")
      y = y + 30
    end
  end
  -- Other routes for your level (alternates and the next zone) as guide rows: each opens its page,
  -- where Start this route switches to it.
  local choices = Q.suggestions(true)
  if #choices > 0 then
    y = y + U.T("OTHER ROUTES FOR YOUR LEVEL", 0, y, W, "label", C.gold) + 4
    y = y + U.T("Click one to see its steps. You stay on your route until you press Start on its page.",
      0, y, W, "small", C.dim) + 6
    local suggestedSet = {}
    for _, section in ipairs(choices) do suggestedSet[section] = true end
    for _, section in ipairs(choices) do
      local status, done, total = Q.sectionStatus(section, suggestedSet)
      y = guideRow(y, section, status, done, total, guideTag(section, status, done, total),
        function() previewGuide(section) end,
        "See this route's steps. You stay on your current route until you start it.", "Preview " .. section.title)
    end
    y = y + 10
  end
  if not selected then
    return y + U.T("No guide is selected. Pick one under Guides.", 0, y, W, "body", C.dim)
  end
  U.btn(allSteps and "Hide finished" or "Show all steps", W - 138, y, 138, function()
    allSteps = not allSteps
    U.refresh()
  end, allSteps, "Toggle finished, earlier and skipped steps in this section.")
  local h = U.T(allSteps and "ALL STEPS" or "STEPS TO DO", 0, y + 5, W - 154, "label", C.gold)
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
  librarySection, pageFrom = section, nil
  U.refreshTop()
end

-- Start this route / Start this guide: switch, say so, and show the route you're now on.
local function startGuide(section)
  local before = Q.current()
  Q.jump(section)
  ns.showQuestViewer()
  local now = Q.current()
  if now and now.section == section then
    if not (before and before.section == section) then
      ns.say("Now following " .. Q.plain(section.title) .. ".")
      started = { section = section, at = tonumber(GetTime and GetTime()) or 0 }
    end
    sub, librarySection, pageFrom = "route", nil, nil
  end
  U.refreshTop()
end

local function renderLibrarySection(rows, section, y)
  local back = pageFrom == "route"
  U.btn(back and "Back to the route" or "Back to guides", 0, y, 160, function()
    librarySection = nil
    if back then sub = "route" end
    pageFrom = nil
    U.refreshTop()
  end, false, back and "Back to the route you're on." or "Back to the list of guides.")
  y = y + 34
  y = y + U.sectionTitle(section.title, y)
  y = y + U.T(sectionInfo(section), 0, y, W, "small", C.dim) + 4
  if section.reward then y = y + U.T("You get: " .. Q.plain(section.reward), 0, y, W, "body", C.gold) + 4 end
  y = y + 4
  local col = math.floor((W - 16) / 3)
  local minimum = Q.guideMinimum(section)
  local current = Q.current()
  local status, done, total = Q.sectionStatus(section)
  local onIt = status == "current"
  local preview = not section.category and not onIt
  if minimum then
    U.T("Available at level " .. minimum, 0, y + 4, W, "body", C.dim)
  elseif not section.category then
    -- A leveling route or class guide: nothing switches until you press Start.
    local route = not section.side
    if onIt then
      U.T(route and "You are on this route." or "You are following this guide.", 0, y + 4, W - 376, "body", C.gold)
      U.btn("First open step", W - 368, y, 200, function() startGuide(section) end, false,
        "Go back to the first step of this " .. (route and "route" or "guide") .. " you haven't done (after Back or a skip).")
      U.btn("See your step", W - 160, y, 160, function() show("step") end, false, "The step you're on, under Step.")
    else
      local label = route and "Start this route" or "Start this guide"
      U.btn(label, 0, y, 200, function() startGuide(section) end, true,
        "Move the step window and arrow to this " .. (route and "route" or "guide") .. ".")
      local now = current and current.section
      U.T(now and ("You are on " .. Q.plain(now.title) .. " until you start this one.")
        or "Start it to follow it in the step window.", 212, y + 4, W - 212, "small", C.dim)
    end
    -- How the guide fits you now, under the buttons.
    local _, _, _, lvl = Q.rows()
    local fit
    if status == "done" then fit = "You have done every step of it."
    elseif status == "outleveled" then fit = "You have outleveled it (levels " .. section.levels[1] .. "-" .. section.levels[2]
      .. "): its quests give little XP now."
    elseif status == "later" then fit = "It starts at level " .. section.levels[1] .. "; you are " .. tostring(lvl) .. "."
    elseif total > 0 and done > 0 then fit = done .. " of " .. total .. " steps done."
    end
    if fit then
      y = y + 30
      U.T(fit, 0, y + 4, W, "small", (status == "later" or status == "outleveled") and C.gold or C.dim)
    end
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
    y = y + 24
    U.btn("Prepare quests", 0, y, W, function()
      Q.setPlanned(section.id, true)
      followGuide(section, "prepareOnly")
    end, false, "Follow outdoor pickups and prerequisite chains now, then return to leveling. Dungeon entry waits until you choose to run it.")
    y = y + 30
    y = y + U.T("Prepare while leveling; run when your group is ready. " .. sectionInfo(section) .. ".", 0, y, W, "small", C.dim)
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
  if not section.category then
    local count = 0
    for _, row in ipairs(rows) do
      if row.section == section and row.state ~= "filtered" then count = count + 1 end
    end
    y = y + U.sectionTitle("STEPS (" .. count .. ")", y)
    if preview then
      y = y + U.T("Hover a step to read it. Start this route to follow them in the step window.", 0, y, W, "small", C.dim) + 6
    end
  end
  for _, row in ipairs(rows) do
    if row.section == section and row.state ~= "filtered" then
      local s = row.step
      local phase = section.category == "dungeon" and (s.phase or "prepare")
      if phase and phase ~= lastPhase then
        y = y + U.sectionTitle(headers[phase], y)
        lastPhase = phase
      end
      local tip = Q.detail(s)
      local quest = s.quest and Q.questStatus(row) or STATUS[row.state]
      y = drawRow(row, y, Q.label(s), STATUS[row.state], quest ~= STATUS[row.state] and quest or nil,
        150, false, tip, nil, preview)
    end
  end
  return y
end

-- Leveling guides (and class quests) as rows: clicking one opens its page (Start is there).
local function guideRows(y, list, suggestedSet)
  for _, section in ipairs(list) do
    local status, done, total = Q.sectionStatus(section, suggestedSet)
    y = guideRow(y, section, status, done, total, guideTag(section, status, done, total), function()
      showGuide(section)
    end, status == "current" and "The route you are on: see its steps." or "See its steps; Start on its page switches to it.")
  end
  return y
end

-- Guides opens on Your level: the guides that fit you now and the next few, not every guide at
-- once. All levels (the bands), Dungeons, Special and Class each show one list. Kept this session.
local guideView = "level"
local VIEWS = { { "level", "Your level" }, { "all", "All levels" }, { "dungeon", "Dungeons" },
  { "special", "Special" }, { "class", "Class" } }
local VIEW_TIPS = {
  level = "The guides that fit your level now, and the next ones.",
  all = "Every leveling guide, by level band.",
  dungeon = "Dungeon guides, and which runs you plan.",
  special = "Special quest chains: attunements, keys and rewards.",
  class = "Your class quests.",
}

-- A small gold heading with a count, for the lists under a view.
local function listHeading(text, y, note)
  local h = U.T(text, 0, y, W, "label", C.gold) + 2
  if note then h = h + U.T(note, 0, y + h, W, "small", C.dim) + 2 end
  return y + h + 4
end

local function dungeonRow(y, section, suggestedSet)
  local status, done, total = Q.sectionStatus(section, suggestedSet)
  local planned = Q.planned(section.id)
  if status ~= "current" and status ~= "done" and status ~= "outleveled" then
    status = planned and "suggested" or "open"
  end
  return guideRow(y, section, status, done, total, planned and "Planned" or "Not planned",
    function() showGuide(section) end, runInfo(section) .. ". View steps and quest readiness.")
end

local function specialRow(y, section, suggestedSet)
  local status, done, total = Q.sectionStatus(section, suggestedSet)
  return guideRow(y, section, status, done, total, guideTag(section, status, done, total),
    function() showGuide(section) end, "View steps and quest readiness.")
end

-- Your level: leveling guides you're on, suggested or in range; then coming up (the next five
-- levels); dungeons in their range; class quests you can do now.
local function renderYourLevel(groups, level, suggestedSet, y)
  local rank = { current = 1, suggested = 2 }
  local now, soon, runs, classes = {}, {}, {}, {}
  for _, section in ipairs(groups.leveling) do
    local status = Q.sectionStatus(section, suggestedSet)
    if status ~= "done" then
      if status == "current" or status == "suggested"
          or (level >= section.levels[1] - 1 and level <= section.levels[2]) then
        now[#now + 1] = { section = section, rank = rank[status] or 3 }
      elseif section.levels[1] > level and section.levels[1] <= level + 5 then
        soon[#soon + 1] = section
      end
    end
  end
  table.sort(now, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.section.levels[1] < b.section.levels[1]
  end)
  table.sort(soon, function(a, b) return a.levels[1] < b.levels[1] end)
  for _, section in ipairs(groups.dungeon) do
    local status = Q.sectionStatus(section, suggestedSet)
    if status ~= "done" and level >= section.levels[1] and level <= section.levels[2] then runs[#runs + 1] = section end
  end
  for _, section in ipairs(groups.class) do
    local status = Q.sectionStatus(section, suggestedSet)
    if status ~= "done" and status ~= "outleveled" and level >= section.levels[1] then classes[#classes + 1] = section end
  end

  if #now == 0 then
    y = y + U.T("No leveling guide fits level " .. level .. ". All levels lists every guide.", 0, y, W, "body", C.dim) + 10
  else
    y = listHeading("LEVELING GUIDES FOR LEVEL " .. level .. " (" .. #now .. ")", y,
      "Click one to see its steps. You stay on your route until you press Start on its page.")
    local list = {}
    for i, entry in ipairs(now) do list[i] = entry.section end
    y = guideRows(y, list, suggestedSet) + 10
  end
  if #soon > 0 then
    y = listHeading("COMING UP", y)
    local list = {}
    for i = 1, math.min(4, #soon) do list[i] = soon[i] end
    y = guideRows(y, list, suggestedSet) + 10
  end
  if #runs > 0 then
    y = listHeading("DUNGEONS AT YOUR LEVEL (" .. #runs .. ")", y)
    for _, section in ipairs(runs) do y = dungeonRow(y, section, suggestedSet) end
    y = y + 10
  end
  if #classes > 0 and not ns.db().noClassQuests then
    y = listHeading("CLASS QUESTS YOU CAN DO (" .. #classes .. ")", y)
    y = guideRows(y, classes, suggestedSet) + 10
  end
  return y + U.T("All levels, Dungeons, Special and Class list every guide.", 0, y, W, "small", C.dim) + 4
end

-- All levels: the leveling guides by level band, yours and the next one open, the others folded.
local function renderBands(groups, level, suggestedSet, y)
  local bands = {}
  for _, band in ipairs(BANDS) do bands[band] = {} end
  for _, section in ipairs(groups.leveling) do
    for _, band in ipairs(BANDS) do
      if section.levels[1] <= band[2] then table.insert(bands[band], section); break end
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
  return y
end

local function renderGuides(rows, sections, y)
  if librarySection then return renderLibrarySection(rows, librarySection, y) end

  local _, _, _, level = Q.rows()
  local groups = { leveling = {}, class = {}, dungeon = {}, special = {} }
  for _, section in ipairs(sections) do
    local key = section.category or (section.side and "class" or "leveling")
    if groups[key] then table.insert(groups[key], section) end
  end
  local views, labels, tips, lit = {}, {}, {}, 1
  for _, v in ipairs(VIEWS) do
    local key = v[1]
    local empty = (key == "class" and (ns.db().noClassQuests or #groups.class == 0))
      or ((key == "dungeon" or key == "special") and #groups[key] == 0)
    if not empty then
      views[#views + 1], labels[#labels + 1], tips[#tips + 1] = key, v[2], VIEW_TIPS[key]
      if key == guideView then lit = #views end
    end
  end
  guideView = views[lit]
  y = y + U.segments(0, y, W, labels, lit, function(i)
    guideView, query, draft = views[i], "", ""
    U.refreshTop()
  end, tips) + 10

  local function search()
    query, librarySection = draft, nil
    U.refreshTop()
  end
  U.questSearch(8, y, W - 100, draft, function(value) draft = value end, search)
  local find = U.btn("Search", W - 80, y, 80, search, false, "Search every guide by its title, a quest name or a quest ID.")
  find.tipTitle = "Search"
  y = y + 34
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

  local suggestedSet = {}
  for _, section in ipairs(Q.suggestions(true)) do suggestedSet[section] = true end
  if guideView == "level" then return renderYourLevel(groups, level, suggestedSet, y) end
  if guideView == "all" then return renderBands(groups, level, suggestedSet, y) end
  if guideView == "dungeon" then
    y = y + U.T("Plan the runs you mean to do: their pickups join your route, and the step window says when to find a group.",
      0, y, W, "small", C.dim) + 6
    y = y + dungeonChoices(0, y, W) + 10
    for _, section in ipairs(groups.dungeon) do y = dungeonRow(y, section, suggestedSet) end
    return y
  end
  if guideView == "special" then
    for _, section in ipairs(groups.special) do y = specialRow(y, section, suggestedSet) end
    return y
  end
  return guideRows(y, groups.class, suggestedSet)
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
  for _, quest in ipairs(unused) do
    local name = Q.plain(quest.title)
    U.rect(0, y, W, 36, C.wash)
    U.rect(0, y + 35, W, 1, C.edgeSoft, "border")
    U.T(name, 12, y + 4, W - 190, "body", C.light)
    U.T(quest.reason, 12, y + 20, W - 190, "small", C.dim)
    local armed = confirmAbandon == quest.id and GetTime() - (confirmAt or 0) < 5
    local b = U.btn(armed and "Click again" or "Abandon", W - 164, y + 7, 160, function()
      if confirmAbandon == quest.id and GetTime() - (confirmAt or 0) < 5 then
        confirmAbandon = nil
        if Q.abandon(quest.id) then ns.say("abandoned " .. name .. ".")
        else ns.say("this client can't abandon quests from the Codex. Use the quest log.") end
      else
        confirmAbandon, confirmAt = quest.id, GetTime()
      end
      U.refresh()
    end, armed, "Abandon this quest. Click twice to confirm.")
    b.codexLabel = armed and "Click again to abandon" or ("Abandon " .. name)
    y = y + 38
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
  -- One quest-log row per quest: its name and state, then small Show and Track buttons (their
  -- codexLabels keep the quest name: "Show X", "Track X" / "Untrack X").
  for _, id in ipairs(active) do
    local entry = Q.log(id)
    local row = Q.questMatch(id)
    local name = Q.plain(entry.title or (row and row.step.name) or ("Quest " .. id))
    local open = Q.incomplete(id)
    U.rect(0, y, W, 30, pinned[id] and C.panel or C.wash)
    U.rect(0, y + 29, W, 1, C.edgeSoft, "border")
    if pinned[id] then U.rect(0, y, 3, 30, C.accent) end
    local state = not open and "Ready" or pinned[id] and "Tracked" or not row and "Not in your guide" or nil
    local _, title = U.T(name, 12, y + 8, W - 300, "body", row and C.light or C.dim)
    if title.SetWordWrap then title:SetWordWrap(false) end
    if state then U.T(state, W - 286, y + 9, 110, "small", not open and C.green or C.dim, "RIGHT") end
    if row then
      U.btn("Show", W - 168, y + 4, 76, function()
        Q.followQuest(row)
        ns.showQuestViewer()
      end, false, "Follow the matching guide step.").codexLabel = "Show " .. name
    end
    if open then
      U.btn(pinned[id] and "Untrack" or "Track", W - 84, y + 4, 80, function()
        if Q.togglePin(id) then ns.questRefresh() else ns.say("you can track up to three quests.") end
      end, pinned[id], "Keep this quest's progress in the step window.").codexLabel = (pinned[id] and "Untrack " or "Track ") .. name
    end
    y = y + 32
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
  -- Elite quest ahead: the same choice as the step window's Take it / Skip (controller players act here).
  if current and current.step.type == "elite" then
    U.btn("Take it", 0, y, half, function() ns.chooseEliteQuest(current.step.eliteQuest, true) end, true,
      "The quest stays on your route. Bring a group or a strong partner for " .. (current.step.elite or "the elite") .. ".")
    U.btn("Skip it", half + 8, y, half, function() ns.moveQuestStep(false) end, false,
      "The guide passes this quest and the quests that need it. Previous step asks again.")
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
-- Party: each member's guide, step, live goal and when you last heard from them, Follow their
-- guide, the quests one of you has and the other doesn't (Ask to share / Share), and the party
-- switches (QuestParty.lua).
----------------------------------------------------------------------------

-- Where a member is, on the parchment card: dark green on your step, dark orange behind you, the
-- theme's accent ahead, soft ink otherwise (the step window's light colours fade on parchment).
local STATUS_INK = { same = { 0.12, 0.45, 0.12 }, behind = { 0.62, 0.27, 0.04 } }

local function heardText(seconds)
  seconds = math.floor(seconds or 0)
  if seconds < 10 then return "heard just now" end
  if seconds < 60 then return "heard " .. seconds .. " s ago" end
  return "heard " .. math.floor(seconds / 60) .. " min ago"
end

local function questLines(y, heading, list, button, tip, label, onClick)
  if not list or #list == 0 then return y end
  y = y + U.T(heading .. " (" .. #list .. ")", 16, y, W - 32, "label", C.inkSoft) + 4
  for _, q in ipairs(list) do
    U.T(q.title, 28, y + 5, W - 200, "body", C.ink)
    U.btn(button, W - 16 - 150, y, 150, function() onClick(q.id) end, false, tip).codexLabel = label(q)
    y = y + 28
  end
  return y + 2
end

local function memberCard(r, y)
  local top = y
  y = y + 10
  local head = r.name .. (r.level and (" (" .. r.level .. ")") or "") .. (r.className and (" " .. r.className) or "")
  local color = STATUS_INK[r.status] or (r.status == "ahead" and C.accent) or C.inkSoft
  local h = U.T(head, 16, y, W - 200, "head", C.ink)
  U.T(r.where, W - 196, y + 2, 180, "small", color, "RIGHT")
  y = y + h + 4
  if r.codex then
    y = y + U.T(r.guide .. ": " .. Q.plain(r.label or ""), 16, y, W - 32, "body", C.ink) + 2
    local note = (r.goal ~= "" and (Q.plain(r.goal) .. "  -  ") or "") .. heardText(r.heard)
    y = y + U.T(note, 16, y, W - 32, "small", C.inkSoft) + 8
    local mine = Q.routeRow()
    if r.section and not (mine and mine.section == r.section) then
      U.btn("Follow " .. r.name .. "'s guide", 16, y, W - 32, function() ns.partyFollow(r.name) end, false,
        "Switch your guide to " .. r.guide .. ", where " .. r.name .. " is. Your own progress comes from your quest log.")
      y = y + 32
    end
    local have, lack = ns.partyQuestDiff(r.name)
    y = questLines(y, r.name .. " has, you don't", have, "Ask to share",
      "Asks " .. r.name .. "'s Codex to offer you this quest. The game asks you to accept it.",
      function(q) return "Ask " .. r.name .. " to share " .. q.title end,
      function(id) ns.partyAskShare(r.name, id) end)
    y = questLines(y, "You have, " .. r.name .. " doesn't", lack, "Share",
      "Offers this quest to your party. If " .. r.name .. " has done it already, the game says so.",
      function(q) return "Share " .. q.title end, ns.partyShare)
  else
    y = y + U.T(r.offline and (r.name .. " is offline.")
      or (r.name .. " needs the Leveling Codex to share a step, with Settings > Show my party's steps on."),
      16, y, W - 32, "small", C.inkSoft) + 8
  end
  U.box(0, top, W, y - top + 4, C.parch, C.edge)
  return y + 14
end

local function renderParty(y)
  local db = ns.db()
  if ns.partyInParty() then
    local rows = ns.partyRows(true)
    y = y + U.sectionTitle("Party (" .. #rows .. ")", y)
    if db.noPartySteps then
      y = y + U.T("Show my party's steps is off: the party doesn't hear your step, and the step window leaves them out.",
        0, y, W, "small", C.dim) + 8
    end
    for _, r in ipairs(rows) do y = memberCard(r, y) end
  else
    y = y + U.T("You're not in a party. Group up with someone running the Leveling Codex and you'll see each other's"
      .. " steps, kill and loot counts and quests here.", 0, y, W, "body", C.dim) + 12
  end
  y = y + U.sectionTitle("Party settings", y)
  local function toggle(key, fn)
    return function()
      db[key] = not db[key]
      if fn then fn() end
      U.refresh()
    end
  end
  local checks = {
    { "Show my party's steps", not db.noPartySteps, toggle("noPartySteps", ns.questRefresh),
      "Party members who use the Codex see each other's step, counts and quests." },
    { "Share guide quests with my party", ns.questSharing(), function() ns.toggleQuestSharing(); U.refresh() end,
      "When you accept a quest from your guide, the Codex offers it to party members who don't have it." },
    { "Say my flights in party chat", db.questAnnounceFlights, toggle("questAnnounceFlights"),
      "Taking a flight says where you're flying in party chat." },
    { "Say steps I finish in party chat", db.questAnnounceSteps, toggle("questAnnounceSteps"),
      "When the game finishes a step of your guide, party chat gets \"Codex: Done - <step>\"." },
    { "Say quest items I pick up", db.questAnnounceItems, toggle("questAnnounceItems"),
      "Each quest item you loot goes to party chat with your count." },
    { "Say quest progress in party chat", db.questAnnounceProgress, toggle("questAnnounceProgress"),
      "A finished objective and a quest that's ready to turn in go to party chat." },
    { "Ping when the party is together on my step", not db.noPartyPing, toggle("noPartyPing"),
      "A soft chime when the last member reaches your step (Settings > Ping sound picks another)." },
  }
  for _, c in ipairs(checks) do
    U.check(c[1], 0, y, c[2], c[3], c[4])
    y = y + 28
  end
  return y
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
  label("Elite quests")
  y = y + U.segments(x, y, w, Q.ELITE_LABELS, Q.eliteModeIndex(), function(i)
    Q.setEliteMode(i)
    ns.updateQuestSettings()
  end, Q.ELITE_TIPS) + 10
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
  y = y + 30
  -- the step window's size and compact mode, so a small screen meets them on first run
  label("Step window")
  U.btn("-", x, y - 1, 28, function() ns.setQuestViewerScale(-0.1); U.refresh() end).codexLabel = "Step window size -"
  U.T(math.floor((tonumber(db.questViewerScale) or 1) * 100 + 0.5) .. "%", x + 32, y + 4, 44, "body", C.ink, "CENTER")
  U.btn("+", x + 80, y - 1, 28, function() ns.setQuestViewerScale(0.1); U.refresh() end).codexLabel = "Step window size +"
  U.check("Compact", x + 150, y - 1, db.questCompact, function()
    db.questCompact = not db.questCompact
    ns.questRefresh()
    U.refresh()
  end, "Only the step's title, a thin progress bar and the buttons: for small screens.")
  y = y + 30
  -- how many of the next steps the step window lists; Settings has every number from 0 to 10
  label("Steps ahead")
  local counts, ahead = { 2, 5, 10 }, ns.questPreviewCount()
  local lit
  for i, n in ipairs(counts) do if n == ahead then lit = i end end
  y = y + U.segments(x, y, w, { "2 steps", "5 steps", "10 steps" }, lit, function(i)
    ns.setQuestPreview(counts[i])
    U.refresh()
  end, { "The step window lists the next 2 steps under the current one.",
    "The step window lists the next 5 steps, on into the next guide.",
    "The step window lists the next 10 steps, on into the next guide." }) + 4
  if not lit then
    y = y + U.T((ahead == 1 and "1 step" or ahead .. " steps") .. ": see Settings", x, y, w, "small", C.dim) + 4
  end
  y = y + 6
  y = U.questButtonOptions(y, 16, W - 32)
  -- the vendor helpers (Vendor.lua), the same switches as Settings
  label("Vendor")
  U.check("Sell junk", x, y - 1, not db.noAutoSell, function()
    db.noAutoSell = not db.noAutoSell
    U.refresh()
  end, "At a vendor, sell your grey items (never quest items or the Hearthstone). Hold Alt as you open the vendor to skip it once.")
  U.check("Repair", x + 150, y - 1, not db.noAutoRepair, function()
    db.noAutoRepair = not db.noAutoRepair
    U.refresh()
  end, "At a vendor who repairs, repair everything with your own money. Hold Alt as you open the vendor to skip it once.")
  y = y + 30
  -- the party (QuestParty.lua), the same switches as Settings > Party and Quests > Party
  label("Party")
  U.check("Party steps", x, y - 1, not db.noPartySteps, function()
    db.noPartySteps = not db.noPartySteps
    ns.questRefresh()
    U.refresh()
  end, "Party members who use the Codex see each other's step, kill and loot counts and quests in the step window and Quests > Party.")
  U.check("Share quests", x + 150, y - 1, ns.questSharing(), function()
    ns.toggleQuestSharing()
    U.refresh()
  end, "When you accept a quest from your guide, the Codex offers it to party members who don't have it yet.")
  U.check("Ping together", x + 300, y - 1, not db.noPartyPing, function()
    db.noPartyPing = not db.noPartyPing
    U.refresh()
  end, "A soft chime when the last party member reaches your step (Settings > Ping sound picks another).")
  y = y + 30
  -- the party chat lines everyone in the party reads: off until you turn them on
  label("Party chat")
  local chatLines = {
    { "Steps done", "questAnnounceSteps", "\"Codex: Done - <step>\" when the game finishes a step of your guide." },
    { "Quest items", "questAnnounceItems", "Each quest item you loot, with your count, and an item that starts a quest." },
    { "Progress", "questAnnounceProgress", "A finished objective, and a quest that's ready to turn in." },
    { "Flights", "questAnnounceFlights", "Where you're flying, with the time once that flight has been timed." },
  }
  for i, c in ipairs(chatLines) do
    U.check(c[1], x + (i - 1) * 112, y - 1, db[c[2]], toggle(c[2]), "Off by default. In party chat: " .. c[3])
  end
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
  else
    if not selected then
      y = y + U.T("No route covers level " .. tostring(level) .. ". Choose a guide under Guides.",
        0, y, W, "body", C.dim) + 8
    end
    y = y + stepButtons(nil, 0, y, W) + 14
  end

  -- The sub-tabs as one row of choices: the open one lit (A.segment), the others flat.
  local labels, lit = {}, 1
  for i, s in ipairs(SUBS) do
    labels[i] = s[2]
    if sub == s[1] then lit = i end
  end
  y = y + U.segments(0, y, W, labels, lit, function(i)
    local key = SUBS[i][1]
    if key == "guides" then librarySection, pageFrom = nil, nil end -- the Guides tab opens the list
    show(key)
  end) + 8
  U.goldRuleAt(y)
  y = y + 12

  if sub == "route" then y = renderRoute(rows, selected, current, y)
  elseif sub == "guides" then y = renderGuides(rows, sections, y)
  elseif sub == "log" then y = renderLog(missed, ready, y)
  elseif sub == "party" then y = renderParty(y)
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
  sub, librarySection, query, draft, pageFrom = "guides", section, "", "", nil
  ns.openTab("quests")
  U.refreshTop()
end
