-- Test scenarios. Each S.<name>() raises on failure; tests/run.py runs them per class and API variant.
-- They only use what a player (or the client) can reach: events, /codex, frames by global name,
-- clicks, drags and hovers, so they keep working however the addon is organised inside.

local S = {}
SCENARIOS = S

-- The client's talent-window toggle (the addon hooks it if it exists at login).
function ToggleTalentFrame() if ToggleTalentFrame_Mock then ToggleTalentFrame_Mock() end end

local function check(cond, msg, level)
  if not cond then error("ASSERT: " .. msg, (level or 1) + 1) end
end

local function D() return LevelingCodexData and LevelingCodexData[MOCK.class] end
local function win() return _G.LevelingCodexFrame end
local function toast() return _G.LevelingCodexToast end
local function slash(msg) SlashCmdList.LEVELINGCODEX(msg) end

local function chatHas(pat)
  for _, line in ipairs(MOCK.chat) do if line:find(pat) then return true end end
  return false
end

local function labelOf(b)
  return b.codexLabel or (b.label and b.label._text) or b._text
end

local function findButton(root, pred)
  for _, b in ipairs(MOCK.buttons(root)) do
    local l = labelOf(b)
    if l and pred(l) then return b end
  end
end

local function click(root, text, mouse)
  local b = findButton(root, function(l) return l == text end)
  -- Follow the redesigned board's visible navigation when an older scenario asks for a
  -- control that moved to an area, a focused options page, or another grid page.
  if not b and root == win() then
    local function press(name)
      local control = findButton(root, function(l) return l == name end)
      if control then control:Click(mouse); return true end
    end
    if text == "Step" then press("Route")
    elseif text == "Show all steps" then press("Area steps")
    elseif text:find("^Track ") or text:find("^Untrack ") or text:find("^Show ") then press("In progress") end
    b = findButton(root, function(l) return l == text end)
    if not b then
      local group = ({ ["Fastest"] = "Your route", ["Every quest"] = "Your route", ["Recommended"] = "Your route", ["All"] = "Your route", ["None"] = "Your route",
        ["Ask"] = "Your route", ["Always take"] = "Your route", ["Always skip"] = "Your route", ["Auto-accept"] = "Helpers", ["Auto turn-in"] = "Helpers",
        ["Auto-fly and bind"] = "Helpers", ["Sell junk"] = "Helpers", ["Repair"] = "Helpers", ["Minimap"] = "Map and step window", ["World map"] = "Map and step window",
        ["Compact"] = "Map and step window", ["2 steps"] = "Map and step window", ["5 steps"] = "Map and step window", ["10 steps"] = "Map and step window",
        ["Step window size -"] = "Map and step window", ["Step window size +"] = "Map and step window", ["Party steps"] = "Party play", ["Share quests"] = "Party play",
        ["Ping together"] = "Party play", ["Steps done"] = "Party play", ["Quest items"] = "Party play", ["Progress"] = "Party play", ["Flights"] = "Party play" })[text]
      if group and press("Back to options") then press(group)
      elseif group then press(group) end
      b = findButton(root, function(l) return l == text end)
    end
    for _ = 1, 40 do
      if b then break end
      if not (press("Next dungeons page") or press("Next guides page")) then break end
      b = findButton(root, function(l) return l == text end)
    end
  end
  check(b, "no button '" .. text .. "'", 2)
  b:Click(mouse)
  return b
end

local function hover(b)
  MOCK.fire(b, "OnEnter")
  MOCK.fire(b, "OnLeave")
end

local function questViewer()
  local frame = _G.LevelingCodexQuestViewer
  check(frame and frame:IsShown(), "quest viewer shown")
  return frame
end

local function questText(root, value)
  local texts = {}
  for _, child in ipairs({ root:GetRegions() }) do
    if child:IsShown() and child._text and child._text:find(value, 1, true) then return true end
    -- the step title shows the name; its full label ("Accept - X") is its codexLabel
    if child:IsShown() and type(child.codexLabel) == "string" and child.codexLabel:find(value, 1, true) then return true end
    if child:IsShown() and child._text and child._text ~= "" then texts[#texts + 1] = child._text end
  end
  -- A checklist row in the step window shows its goal and its count apart: "Kobold Vermin" "4/10".
  if #texts == 2 and (texts[1] .. " " .. texts[2]):find(value, 1, true) then return true end
  for _, child in ipairs({ root:GetChildren() }) do
    if child:IsShown() and questText(child, value) then return true end
  end
  return false
end

-- A piece of the step window whose text begins with this (UP NEXT lists the next step first).
local function questTextStarts(root, value)
  for _, child in ipairs({ root:GetRegions() }) do
    if child:IsShown() and child._text and child._text:sub(1, #value) == value then return true end
  end
  for _, child in ipairs({ root:GetChildren() }) do
    if child:IsShown() and questTextStarts(child, value) then return true end
  end
  return false
end

-- The Quests tab's Quest log sub-tab, with this queue's heading ("Missed quests (2)").
local function questQueue(name)
  click(win(), "Quest log")
  click(win(), name == "Missed quests" and "Missed pickups" or name)
  check(questText(win(), name .. " ("), "quest view is available: " .. name, 2)
end

-- A guide's button under Quests > Guides, opening folded level bands ("+ LEVELS ...") until it shows.
-- Guides opens on Your level; each view (All levels, Dungeons, Special, Class) shows one list.
local function guideButton(name)
  click(win(), "Guides")
  local function find() return findButton(win(), function(l) return l == name end) end
  local function pages()
    local b = find()
    for _ = 1, 40 do
      if b then return b end
      local next = findButton(win(), function(l) return l == "Next guides page" or l == "Next dungeons page" end)
      if not next then break end
      next:Click(); b = find()
    end
    return b
  end
  local b = pages()
  for _, view in ipairs({ "Your level", "All levels", "Dungeons", "Special", "Class" }) do
    if b then break end
    if view ~= "Dungeons" then click(win(), "Guides") end
    local tab = findButton(win(), function(l) return l == view end)
    if tab then
      tab:Click()
      b = pages()
      if not b and view == "All levels" then
        local bands = {}
        for _, control in ipairs(MOCK.buttons(win())) do
          local label = labelOf(control)
          if label and label:find("^LEVELS ") then bands[#bands + 1] = label end
        end
        for _, label in ipairs(bands) do
          click(win(), label); b = pages()
          if b then break end
          click(win(), "All level bands")
        end
      end
      while not b do
        local folded = findButton(win(), function(l) return l:find("^%+ LEVELS") ~= nil end)
        if not folded then break end
        folded:Click()
        b = find()
      end
    end
  end
  return b
end

-- Quests > Guides, then one of its views ("Your level", "All levels", "Dungeons", "Special", "Class").
local function guidesView(name)
  click(win(), "Guides")
  click(win(), name)
end

-- A button under Quests > Step (Resume active quest, Return to leveling, ...).
local function stepTool(name)
  click(win(), "Step")
  return click(win(), name)
end

-- Opens a guide's page and, for a leveling route or class guide, presses Start on it (a guide row
-- only opens its page). Dungeon and special pages are left open for their own buttons.
local function clickGuide(name)
  local b = guideButton(name)
  check(b, "no guide button '" .. name .. "'", 2)
  b:Click()
  local start = findButton(win(), function(l) return l == "Start this route" or l == "Start this guide" end)
  if start then start:Click() end
end

-- Browse the visible area nodes and six-card pages; data scenarios still inspect every authored
-- step, while the board itself is deliberately bounded. This never follows or advances a step.
local function walkRoute(visit)
  click(win(), "Route")
  local function press(name)
    local button = findButton(win(), function(l) return l == name end)
    if button then button:Click(); return true end
  end
  for _ = 1, 80 do if not press("Previous areas page") then break end end
  for _ = 1, 80 do
    local areas = {}
    for _, button in ipairs(MOCK.buttons(win())) do
      local label = labelOf(button)
      if label and label:find("^Area %d+:") then areas[#areas + 1] = label end
    end
    if #areas == 0 then break end
    for _, name in ipairs(areas) do
      press(name); press("Area steps")
      press("Show all steps")
      for _ = 1, 100 do
        local result = visit()
        if result then return result end
        if not press("Next steps page") then break end
      end
      press("Back to journey")
    end
    if not press("Next areas page") then break end
  end
  click(win(), "Route")
end

local function routeHas(text)
  local found = false
  walkRoute(function()
    if questText(win(), text) then found = true end
  end)
  return found
end

local function routeStep(title)
  return walkRoute(function()
    for _, button in ipairs(MOCK.buttons(win())) do
      if button:IsShown() and button.tipTitle == title then return button end
    end
  end)
end

local function guideHas(text)
  local function press(name)
    local b = findButton(win(), function(l) return l == name end)
    if b then b:Click(); return true end
  end
  local phases = {}
  for _, phase in ipairs({ "Prepare", "Inside", "Turn-ins" }) do
    local b = findButton(win(), function(l) return l == phase or l == phase .. " (now)" end)
    if b then phases[#phases + 1] = labelOf(b) end
  end
  if #phases == 0 then phases[1] = false end
  for _, phase in ipairs(phases) do
    if phase then press(phase) end
    for _ = 1, 80 do if not press("Previous guide area") then break end end
    for _ = 1, 80 do
      for _ = 1, 100 do
        if questText(win(), text) then return true end
        if not press("Next steps page") then break end
      end
      if not press("Next guide area") then break end
    end
  end
  return false
end

function S.questStart()
  local frame = questViewer()
  check(questText(frame, "A Threat Within"), "fresh Human route starts at A Threat Within")
  local target = _G.LevelingCodexQuestTarget
  check(target and target:IsShown() and target:GetAttribute("macrotext") == "/targetexact Deputy Willem",
    "the target button targets the step's quest giver")
  click(frame, "Next")
  check(questText(frame, "Accept - Nibbled-On Book"), "skipping the first quest skips its dependent steps")
  click(frame, "Back")
  check(questText(frame, "A Threat Within"), "back returns to initial step")
  click(frame, "Quests")
  check(not questText(win(), "Unverified") and not questText(frame, "Unverified"), "no Unverified labels for players")
  check(questText(frame, "Levels 1-5") and not findButton(frame, function(l) return l == "Pin" end),
    "the step window shows the level range and has no Pin button")
end

function S.questProgress()
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = { { text = "Kobold Vermin 4/10", numFulfilled = 4 } } } }
  S.login()
  check(questText(questViewer(), "Kobold Vermin 4/10"), "login resumes the active objective")
  check(LevelingCodexQuestArrow and LevelingCodexQuestArrow:IsShown(), "same-map arrow shown")
  MOCK.facing = nil
  MOCK.advance(0.5)
  check(questText(LevelingCodexQuestArrow, " yd"), "compass fallback when facing is absent")
  MOCK.questDone[7], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 7)
  check(not questText(questViewer(), "Kobold Vermin 4/10"), "turn-in clears completed objective")
end

function S.questClassic()
  C_QuestLog.GetInfo = function() return nil end
  C_QuestLog.GetQuestObjectives = function() return nil end
  C_QuestLog.IsQuestFlaggedCompleted = function() return nil end
  GetNumQuestLogEntries = function() return 1 end
  GetQuestLogTitle = function() return "Kobold Camp Cleanup", 2, nil, false, false, false, nil, 7 end
  GetNumQuestLeaderBoards = function() return 1 end
  GetQuestLogLeaderBoard = function() return "Kobold Vermin 3/10", "monster", false end
  IsQuestFlaggedCompleted = function(id) return id == 783 or id == 5261 or id == 33 end
  S.login()
  check(questText(questViewer(), "Kobold Vermin 3/10"), "classic fallback resumes objective")
end

function S.questPastRoute()
  MOCK.level = 31
  S.login()
  slash("quests")
  check(questText(win(), "Darkshire: Mor'Ladim and the Worgen"), "level 31 lists the Darkshire chapter")
  clickGuide("Wetlands")
  check(questText(questViewer(), "Wetlands"), "the Wetlands section is listed")
  clickGuide("Elwynn Forest")
  check(questText(questViewer(), "Elwynn Forest"), "can jump to the nearest available section")
end

function S.questNavigation()
  MOCK.level, MOCK.questX, MOCK.questY = 6, 43.77, 65.8
  for _, id in ipairs({ 2158, 96627, 95998, 96626, 54, 91772 }) do
    MOCK.questDone[id] = true
  end
  for _, id in ipairs({ 91775, 62, 60, 47 }) do
    MOCK.questLog[#MOCK.questLog + 1] = { questID = id }
  end
  S.login()
  local frame = questViewer()
  click(frame, "Next") -- hearth binding
  click(frame, "Next") -- training
  check(questText(frame, "Follow the road south"), "arrives at the first Elwynn travel step")
  MOCK.onTaxi = true
  MOCK.questX, MOCK.questY = 35.8, 80.3
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  MOCK.advance(0.5)
  check(questText(frame, "Follow the road south"), "passing over a waypoint on a taxi does not complete it")
  MOCK.onTaxi = false
  MOCK.advance(0.5)
  check(not questText(frame, "Follow the road south"), "travel completes within range")
  check(questText(frame, "Accept - Lost Necklace"), "arrival advances to the farm quest")
end

function S.questTravelArrow()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Skyborne", 19, 1433, 32.5, 31.5
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "lakeshire" then
      for _, step in ipairs(section.steps) do
        if step.quest == 124 then break end
        if step.type == "accept" then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 124, objectives = { { text = "Redridge Brutes 4/10" } } } }
  MOCK.taxiNodes = { { "Stormwind, Elwynn", "CURRENT" }, { "Lakeshire, Redridge", "REACHABLE" } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Redridge Brutes 4/10"), "following the active Redridge objective")
  local arrow = LevelingCodexQuestArrow
  local art = arrow:GetRegions()
  check(art:IsShown() and math.abs(math.sin(art._rot) + 1) < 0.01, "east is right when facing north")

  MOCK.questMap, MOCK.questX, MOCK.questY = 1453, 77.2, 82.72
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Redridge Brutes 4/10"), "travel keeps the same quest selected")
  check(questText(arrow, "Leave Stormwind for Redridge") and not questText(arrow, "140 yd"),
    "Stormwind points to a named exit and omits the old unlabeled distance")

  MOCK.event("TAXIMAP_OPENED")
  check(questText(arrow, "Fly to Lakeshire"), "learned routes redirect the arrow to the flight master")
  MOCK.taxiNodes[2][2] = "DISTANT"
  MOCK.event("TAXIMAP_OPENED")
  check(questText(arrow, "Leave Stormwind for Redridge"), "an unavailable flight falls back to the road")
  MOCK.taxiNodes[2][2] = "REACHABLE"
  MOCK.event("TAXIMAP_OPENED")
  MOCK.onTaxi = true
  MOCK.questMap, MOCK.questX, MOCK.questY = 1433, 32.5, 31.5
  MOCK.mapSizes = { [1433] = LevelingCodexQuests.ALLIANCE.extents[1433] }
  LevelingCodexQuests.ALLIANCE.extents[1433] = nil
  MOCK.advance(0.25)
  check(questText(arrow, "In flight") and not art:IsShown() and not questText(arrow, " yd"),
    "flight suspends the heading and distance")
  MOCK.onTaxi = false
  MOCK.advance(0.25)
  check(art:IsShown() and questText(arrow, "43 yd"), "landing restores the arrow and distance using the client map size")
  MOCK.facing = 3 * math.pi / 2
  MOCK.advance(0.05)
  check(math.abs(math.cos(art._rot) - 1) < 0.01, "the arrow straightens promptly when the player faces east")

  MOCK.event("PLAYER_LEAVING_WORLD")
  check(not art:IsShown() and not questText(arrow, " yd"), "loading clears the old heading immediately")
  MOCK.questMap, MOCK.questX, MOCK.questY = 1429, 42.1, 65.9
  MOCK.event("PLAYER_ENTERING_WORLD")
  check(questText(arrow, "Take the east road to Redridge") and not questText(arrow, "43 yd"),
    "hearthing to Goldshire gives a road leg back to the quest zone")
  check(questText(frame, "Redridge Brutes 4/10"), "hearth travel preserves objective progress")

  MOCK.questMap = 1457
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(arrow, "Travel to Redridge Mountains") and not art:IsShown() and not questText(arrow, " yd"),
    "an unsupported connection names the destination zone")
  MOCK.questMap, MOCK.questX, MOCK.questY = 1433, 0, 0
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(arrow, "Position unavailable") and not art:IsShown(), "an invalid map position has no heading")
end

function S.questObjectiveWaypoints()
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 15, 1436, 45.3, 20
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "westfall" then
      for _, step in ipairs(section.steps) do
        if step.quest == 92745 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  local diggers = { text = "Kobold Diggers 0/4", finished = false }
  local miners = { text = "Riverpaw Miners 0/6", finished = false }
  MOCK.questLog = { { questID = 92745, objectives = { diggers, miners } } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame, arrow = questViewer(), LevelingCodexQuestArrow
  check(questText(frame, "Jangolode Mine") and questText(arrow, "Arrived"), "first mine objective points to Jangolode")

  diggers.text, diggers.finished = "Kobold Diggers 4/4", true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Gold Coast Quarry") and not questText(frame, "Kobold Diggers 4/4"),
    "the first objective advances without waiting for the whole quest")
  check(questText(arrow, " yd"), "the arrow leaves the completed location")
  MOCK.questX, MOCK.questY = 29.8, 48.1
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(arrow, "Arrived"), "the new arrow leads to the quarry")

  miners.text, miners.finished = "Riverpaw Miners 6/6", true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Turn in - The State of the Mines"), "the last objective advances to the turn-in")
end

-- Duskwood: Lean Wolf Flanks for Seasoned Wolf Kabobs also drop from the Young Black Ravagers of the
-- Ira's Dagger hunt and the wolves around the spider woods, so both steps list the kabobs.
function S.questDuskwoodFlanks()
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 23, 1431, 55.3, 63.7
  MOCK.questLog = {
    { questID = 96137, objectives = { { text = "Young Black Ravager slain: 2/10" }, { text = "Black Ravager slain: 0/7" } } },
    { questID = 245, objectives = { { text = "Pygmy Venom Web Spider slain: 0/15" } } },
    { questID = 90, objectives = { { text = "Lean Wolf Flank: 3/10" }, { text = "Stormwind Seasoning Herbs: 0/1" } } },
  }
  S.login()
  slash("quests")
  local function preview(title)
    local button = routeStep("Complete - " .. title)
    check(button, "route objective is available for " .. title)
    button:Click()
  end
  local frame = questViewer()
  preview("Ira's Dagger")
  check(questText(frame, "WHILE YOU'RE HERE") and questText(frame, "Seasoned Wolf Kabobs")
    and questText(frame, "Lean Wolf Flank 3/10"), "the ravager hunt lists the kabobs' wolf flanks")
  preview("Eight-Legged Menaces")
  check(questText(frame, "Seasoned Wolf Kabobs") and questText(frame, "Lean Wolf Flank 3/10"),
    "and so does the spider step")
end

function S.questRedridgeOverlap()
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 19, 1433, 52.0, 76.6
  MOCK.questLog = {
    { questID = 20, objectives = { { text = "Battleworn Axe 3/10" } } },
    { questID = 98387, objectives = { { text = "Blackrock Supplies 4/10" } } },
    { questID = 92, objectives = { { text = "Great Goretusk Snout 2/5" } } },
    { questID = 122, objectives = { { text = "Underbelly Whelp Scale 1/6" } } },
  }
  S.login()
  slash("quests")
  local function preview(title)
    local button = routeStep("Complete - " .. title)
    check(button, "route objective is available for " .. title)
    button:Click()
  end
  preview("Blackrock Blockade")
  local frame = questViewer()
  check(questText(frame, "Blackrock Supplies 4/10"), "the primary objective keeps its live progress")
  check(questText(frame, "WHILE YOU'RE HERE") and questText(frame, "Battleworn Axe 3/10"),
    "the blockade step shows the overlapping axe objective")
  MOCK.questLog[1].objectives[1].text = "Battleworn Axe 5/10"
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Battleworn Axe 5/10"), "the overlapping objective updates live")
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not questText(frame, "WHILE YOU'RE HERE") and questText(frame, "Blackrock Supplies 4/10"),
    "completed axes leave the panel without changing the primary objective")
  preview("Redridge Goulash")
  check(questText(frame, "Great Goretusk Snout 2/5") and questText(frame, "Underbelly Whelp Scale 1/6"),
    "the south-shore loop shows ingredients and scales together")
  MOCK.event("QUEST_REMOVED", 122)
  check(not questText(frame, "Underbelly Whelp Scale"), "abandoned overlap leaves the panel")
end

function S.questSkyborne()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 19, 1433
  MOCK.questLog = { { questID = 14 } } -- an older Westfall quest is still in the log
  S.login()
  check(questText(questViewer(), "Lakeshire"), "level 19 Skyborne starts in Lakeshire with an older Westfall quest")
  slash("quests")
  check(not findButton(win(), function(l) return l == "Northshire Valley" end), "Human start stays race filtered")
  check(guideButton("Westfall"), "the shared Westfall section remains available")
end

function S.questLayout()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 19, 1433
  MOCK.questLog = { { questID = 3741, isComplete = true }, { questID = 246 } }
  S.login()
  slash("quests")
  local opener = findButton(win(), function(label) return label == "Show step window" or label == "Hide step window" end)
  check(opener, "step window control is visible")
  local _, content = opener:GetPoint(1)
  local function checkBounds()
    local bounds = {}
    for _, button in ipairs(MOCK.buttons(win())) do
      local point, relative, _, x, y = button:GetPoint(1)
      if button:IsVisible() and point == "TOPLEFT" and relative == content then
        local name = labelOf(button) or button.tipTitle or "unnamed control"
        local right, bottom = x + button:GetWidth(), -y + button:GetHeight()
        check(x >= 0 and -y >= 0 and right <= content:GetWidth() and bottom <= content:GetHeight(),
          "quest control fits the scroll content: " .. name)
        for _, other in ipairs(bounds) do
          check(x >= other.right or right <= other.x or -y >= other.bottom or bottom <= other.y,
            "quest controls overlap: " .. name .. " and " .. other.name)
        end
        bounds[#bounds + 1] = { name = name, x = x, y = -y, right = right, bottom = bottom }
      end
    end
    check(#bounds >= 8, "layout check covered the quest controls")
  end
  checkBounds()
  check(questText(win(), "CURRENT STEP"), "current action has a dedicated card")
  check(not questText(win(), "Accept - Hilary's Necklace"), "finished steps are hidden by default")
  click(win(), "Show all steps")
  check(routeHas("Accept - Hilary's Necklace"), "finished steps can be shown through area pages")
  check(not questText(win(), "The Defias Brotherhood"), "route shows only the selected section")
  checkBounds()
  questQueue("Ready to turn in")
  check(questText(win(), "Hilary's Necklace"), "ready view lists the turn-in")
  checkBounds()
  questQueue("Missed quests")
  check(questText(win(), "Missed quests"), "missed view has its own heading")
  checkBounds()
  clickGuide("Westfall")
  check(routeHas("The Defias Brotherhood"), "switching sections exposes that route's area cards")
  checkBounds()
end

function S.questBind()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 18, 1433, "Goldshire"
  S.login()
  local frame = questViewer()
  check(questText(frame, "Flight path - Lakeshire, Redridge"), "Lakeshire starts at its flight path")
  click(frame, "Next")
  -- Deputy Feldon stands beside the gryphon master: his pickup comes before the walk to the inn.
  check(questText(frame, "Accept - Show of Force"), "Feldon's pickup follows the flight path")
  click(frame, "Next")
  check(questText(frame, "Bind hearthstone"), "bind step follows the flight path")
  check(questText(frame, "Your hearthstone is set to Goldshire"), "bind step names the current bind")
  check(questText(frame, "Use Next to keep your current bind"), "binding explicitly explains how to skip")
  click(frame, "Next")
  check(MOCK.bind == "Goldshire" and not questText(frame, "Bind hearthstone"), "Next skips the bind without changing it")
  click(frame, "Back")
  check(questText(frame, "Bind hearthstone"), "Back restores a skipped bind step")
  MOCK.bind = "Lakeshire"
  MOCK.event("HEARTHSTONE_BOUND")
  check(not questText(frame, "Bind hearthstone"), "binding at the inn finishes the step")
  check(questText(frame, "Accept - A Free Lunch"), "the route moves on after binding")
  MOCK.bind = "Goldshire"
  MOCK.event("HEARTHSTONE_BOUND")
  check(questText(frame, "Bind hearthstone"), "binding elsewhere brings the step back")
  slash("quests")
  click(win(), "Settings")
  click(win(), "Skip hearthstone binding steps")
  check(LevelingCodexDB.questSkipBind, "skip setting is saved")
  check(not questText(frame, "Bind hearthstone"), "skip setting hides bind steps")
  check(questText(frame, "Accept - A Free Lunch"), "skip setting moves on to the next step")
  click(win(), "Quests")
  check(not routeHas("Bind hearthstone"), "skipped bind steps leave the route list")
  local hearth = routeStep("Return to Lakeshire")
  check(hearth, "hearth step is in the route list")
  MOCK.bags[6948] = 1
  hearth:Click()
  check(questText(frame, "Your hearthstone is set to Goldshire") and questText(frame, "lake road west"),
    "return step names the different bind and keeps the route to Lakeshire")
  check(not questText(frame, "Hearth to Lakeshire"), "return step does not recommend a hearth to the wrong town")
  local item = _G.LevelingCodexQuestItem
  check(not (item and item:IsShown()), "no Hearthstone button while it is set to another town")
  MOCK.bind = "Lakeshire"
  MOCK.event("HEARTHSTONE_BOUND")
  check(questText(frame, "Use your hearthstone") and not questText(frame, "Your hearthstone is set to Goldshire"),
    "return step offers the hearth when it leads to Lakeshire")
  item = _G.LevelingCodexQuestItem
  check(item and item:IsShown() and item:GetAttribute("item") == "item:6948",
    "a hearth step to your bind town puts the Hearthstone on the item button")
  MOCK.cooldowns = { [6948] = { MOCK.time, 3540 } }
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Your hearthstone is ready in 59 min: travel there instead.")
    and not questText(LevelingCodexQuestArrow, "Hearth to Lakeshire"), "a hearthstone on cooldown sends you by road")
end

function S.questTravelFlight()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 28, 1431
  MOCK.taxiNodes = { { "Darkshire, Duskwood", "CURRENT" }, { "Stormwind, Elwynn", "REACHABLE" } }
  MOCK.gossipOptions = { { gossipOptionID = 7, name = "I want to browse your goods." },
    { gossipOptionID = 8, name = "Show me where I can fly." } }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Fly - Stormwind, Elwynn"), "the Wetlands section starts with the flight to Stormwind")
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("TAXIMAP_OPENED")
  check(MOCK.gossipOption == nil and MOCK.tookTaxi == nil, "travel automation is off by default")
  slash("quests")
  click(win(), "Settings")
  click(win(), "Auto-fly: take the guide's flights and binds")
  check(LevelingCodexDB.questAutoTravel, "the travel setting is saved")
  MOCK.alt = true
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("TAXIMAP_OPENED")
  check(MOCK.gossipOption == nil and MOCK.tookTaxi == nil, "holding Alt keeps the flight master's choices")
  MOCK.alt = false
  MOCK.combat = true
  MOCK.event("TAXIMAP_OPENED")
  check(MOCK.tookTaxi == nil, "no flights taken in combat")
  MOCK.combat = false
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == 8, "the flight master's flight option is picked")
  MOCK.event("TAXIMAP_OPENED")
  check(MOCK.tookTaxi == 2 and chatHas("flying to Stormwind, Elwynn"), "the step's flight is taken")
  MOCK.tookTaxi = nil
  MOCK.taxiNodes[2][2] = "UNREACHABLE"
  MOCK.event("TAXIMAP_OPENED")
  check(MOCK.tookTaxi == nil, "an unreachable destination is left to the player")
end

function S.questTravelBind()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 18, 1433, "Goldshire"
  MOCK.gossipOptions = { { gossipOptionID = 3, name = "Make this inn your home." },
    { gossipOptionID = 4, name = "Show me where I can fly." } }
  LevelingCodexDB = { questAutoTravel = true }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Flight path - Lakeshire, Redridge"), "Lakeshire starts at its flight path")
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == 4, "a flight path step opens the flight master's map")
  MOCK.gossipOption = nil
  click(frame, "Next")
  check(questText(frame, "Accept - Show of Force"), "Feldon's pickup beside the flight master comes next")
  click(frame, "Next")
  check(questText(frame, "Bind hearthstone"), "the bind step follows")
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == nil, "no bind option picked away from the step's inn")
  MOCK.questX, MOCK.questY = 22.1, 44.6
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == 3, "the innkeeper's bind option is picked at the step's inn")
  -- Reported from the game: confirming the bind and hiding its popup from addon code made Forever
  -- show "LevelingCodex has been blocked from an action only available to the Blizzard UI", later
  -- at the Spirit Healer too. The bind popup is the player's: the Codex never accepts or hides it.
  MOCK.event("CONFIRM_BINDER", "Lakeshire")
  check(MOCK.forbidden == nil, "the bind popup is left to the player (no Blizzard-only call)")
end

function S.questGrind()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 14, 1436
  LevelingCodexCharDB = { questFlights = { ["Sentinel Hill, Westfall"] = true } }
  local grind
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "westfall" then
      for _, step in ipairs(section.steps) do
        if step.type == "grind" then grind = step; break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.xp, MOCK.xpMax, MOCK.rested = 1000, 4000, 600
  S.login()
  local frame = questViewer()
  check(questText(frame, "Level up") and questText(frame, "Reach level 15"), "the Westfall grind step is current")
  check(questText(frame, "XP 1000 / 4000 (25%)") and questText(frame, "3000 XP to level 15")
    and questText(frame, "Rested: 600 XP"), "the grind step shows the XP still to go")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Defias Looter dies, you gain 150 experience.")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "You gain 300 experience.")
  MOCK.xp = 1150
  MOCK.event("PLAYER_XP_UPDATE", "player")
  check(questText(frame, "2850 XP to level 15, about 19 kills"), "kills are estimated from the last kills' XP")
  MOCK.questLog = { { questID = 999, title = "Elsewhere", isComplete = true } }
  MOCK.rewardXP = { [999] = 875 }
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Ready turn-ins: about 875 XP"), "XP waiting in finished quests is shown")
  -- A grind target inside a level: level 15 and 40%.
  grind.xp = 0.4
  MOCK.level, MOCK.xp, MOCK.questLog = 15, 800, {}
  MOCK.event("PLAYER_LEVEL_UP", 15)
  check(questText(frame, "800 XP to 40% of level 15"), "a share of a level is a grind target")
  MOCK.xp = 1700
  MOCK.event("PLAYER_XP_UPDATE", "player")
  check(not questText(frame, "Reach level 15"), "reaching the share finishes the grind step")
end

-- Reported from the game: "LevelingCodex has been blocked from an action only available to the
-- Blizzard UI" kept coming back and taint.log stayed empty. The game's ADDON_ACTION_FORBIDDEN names
-- the function: the Codex says it once in chat and keeps it for /codex debug.
function S.blockedReport()
  S.login()
  MOCK.event("ADDON_ACTION_FORBIDDEN", "SomeOtherAddon", "CastSpellByName()")
  check(not (LevelingCodexDB.blocked and LevelingCodexDB.blocked[1]) and not chatHas("blocked the Codex"),
    "another addon's block is left alone")
  MOCK.event("ADDON_ACTION_FORBIDDEN", "LevelingCodex", "C_Minimap.SetTracking()")
  check(chatHas("the game blocked the Codex from C_Minimap%.SetTracking%(%)"), "a block of the Codex is named in chat")
  local b = LevelingCodexDB.blocked and LevelingCodexDB.blocked[1]
  check(b and b.func == "C_Minimap.SetTracking()" and b.event == "ADDON_ACTION_FORBIDDEN",
    "the block is kept in the saved settings")
  local said = #MOCK.chat
  MOCK.event("ADDON_ACTION_FORBIDDEN", "LevelingCodex", "C_Minimap.SetTracking()")
  check(#MOCK.chat == said and #LevelingCodexDB.blocked == 2, "the same block is said once a session, but every one is kept")
  for i = 1, 12 do MOCK.event("ADDON_ACTION_BLOCKED", "LevelingCodex", "TakeTaxiNode()") end
  check(#LevelingCodexDB.blocked == 10 and LevelingCodexDB.blocked[1].func == "TakeTaxiNode()", "the last 10 are kept")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("blocked by the game: TakeTaxiNode%(%) %(ADDON_ACTION_BLOCKED%)"), "/codex debug lists the blocks")
  -- The events are synchronous: a blocked call made by the Codex is traced to the Codex line.
  local setWaypoint = C_Map.SetUserWaypoint
  C_Map.SetUserWaypoint = function(point)
    pcall(MOCK.event, "ADDON_ACTION_FORBIDDEN", "LevelingCodex", "UNKNOWN()") -- the client's C side
    return setWaypoint(point)
  end
  MOCK.userWaypoint = nil
  click(questViewer(), "Next")
  C_Map.SetUserWaypoint = setWaypoint
  b = LevelingCodexDB.blocked[1]
  check(b.func == "UNKNOWN()" and b.where and b.where:find("^Theme%.lua:%d+ < Quests%.lua:%d+ < QuestGuide%.lua:%d+"),
    "a blocked call names the Codex lines right above it (try helpers, then the caller): " .. tostring(b.where))
  check(chatHas("blocked the Codex from UNKNOWN%(%) at .*QuestGuide%.lua:%d+"), "chat names that line")
end

function S.questCleanup()
  MOCK.level = 20
  MOCK.questLog = { { questID = 783, title = "A Threat Within", level = 1 },
    { questID = 999, title = "Stray Errand", level = 19 },
    { questID = 7, title = "Kobold Camp Cleanup", level = 2, isComplete = true } }
  S.login()
  slash("quests")
  click(win(), "Quest log"); click(win(), "Clean up")
  check(questText(win(), "Quest log cleanup"), "the library lists quests to clean up")
  check(questText(win(), "Stray Errand") and questText(win(), "Not in your guides") and questText(win(), "Grey"),
    "each quest says why it is listed")
  check(not findButton(win(), function(l) return l == "Abandon Kobold Camp Cleanup" end),
    "a finished grey quest is left for its turn-in")
  click(win(), "Abandon Stray Errand")
  check(MOCK.abandoned == nil, "the first click only asks")
  click(win(), "Click again to abandon")
  check(MOCK.abandoned == 999 and chatHas("abandoned Stray Errand"), "the second click abandons the quest")
end

function S.questReward()
  S.login()
  local buttons = {}
  for i = 1, 3 do buttons[i] = CreateFrame("Button", "QuestInfoRewardsFrameQuestInfoItem" .. i, UIParent) end
  MOCK.questChoices = 3
  MOCK.rewardChoices = { { "Mail Vest", 1, 450 }, { "Cloth Gloves", 1, nil }, { "Rough Arrow", 200, 1 } }
  MOCK.event("QUEST_COMPLETE")
  check(not chatHas("sells for the most"), "waits while an item's info is still loading")
  MOCK.rewardChoices[2][3] = 1300
  MOCK.advance(0.6)
  local mark = _G.LevelingCodexRewardMark
  check(mark and mark:IsShown() and mark:GetParent() == buttons[2], "a coin marks the best-selling choice")
  check(chatHas("Cloth Gloves sells for the most %(13s%)"), "chat names it with its price")
  check(not MOCK.questRewarded, "the Codex never picks the reward")
  MOCK.event("QUEST_FINISHED")
  check(not mark:IsShown(), "the mark goes when the quest window closes")
  LevelingCodexDB.noRewardHint = true
  MOCK.event("QUEST_COMPLETE")
  check(not mark:IsShown(), "the setting turns the mark off")
  LevelingCodexDB.noRewardHint = nil
  MOCK.chat = {}
  slash("debug")
  check(chatHas("reward mark: 3 choices %(Mail Vest 4s 50c, Cloth Gloves 13s, Rough Arrow x200 2s%), 2 reads; "
    .. "marked Cloth Gloves on QuestInfoRewardsFrameQuestInfoItem2"), "debug says what the last reward window read")
end

local function rewardLines()
  local n = 0
  for _, line in ipairs(MOCK.chat) do if line:find("sells for the most") then n = n + 1 end end
  return n
end

-- A price still loading when the quest window closes or opens again: no late line, no second line.
function S.questRewardStale()
  S.login()
  for i = 1, 2 do CreateFrame("Button", "QuestInfoRewardsFrameQuestInfoItem" .. i, UIParent) end
  MOCK.questChoices = 2
  MOCK.rewardChoices = { { "Mail Vest", 1, 450 }, { "Cloth Gloves", 1, nil } }
  MOCK.event("QUEST_COMPLETE")
  MOCK.event("QUEST_FINISHED")
  MOCK.rewardChoices[2][3] = 1300
  MOCK.advance(4)
  check(rewardLines() == 0, "a closed quest window gets no reward line")
  local mark = _G.LevelingCodexRewardMark
  check(not (mark and mark:IsShown()), "and no mark")
  slash("debug")
  check(chatHas("reward mark: 2 choices %(Mail Vest 4s 50c, Cloth Gloves price not loaded%), 1 read; "
    .. "the window closed while waiting for a price"), "debug says the read stopped with the window")
  MOCK.rewardChoices[2][3] = nil
  MOCK.event("QUEST_COMPLETE")
  MOCK.advance(0.3)
  MOCK.event("QUEST_FINISHED")
  MOCK.event("QUEST_COMPLETE")
  MOCK.rewardChoices[2][3] = 1300
  MOCK.advance(4)
  check(rewardLines() == 1, "reopening the window says it once (said " .. rewardLines() .. ")")
end

-- A slow price is waited for; one that never loads is named, so the line never claims too much.
function S.questRewardSlowPrice()
  S.login()
  local buttons = {}
  for i = 1, 3 do buttons[i] = CreateFrame("Button", "QuestInfoRewardsFrameQuestInfoItem" .. i, UIParent) end
  MOCK.questChoices = 3
  MOCK.rewardChoices = { { "Mail Vest", 1, 450 }, { "Cloth Gloves", 1, nil }, { "Rough Arrow", 200, 1 } }
  MOCK.event("QUEST_COMPLETE")
  MOCK.advance(2)
  check(rewardLines() == 0, "still waits for a price after 2 s")
  MOCK.rewardChoices[2][3] = 1300
  MOCK.advance(0.6)
  check(chatHas("Cloth Gloves sells for the most %(13s%)%.$"), "then names the best reward")
  check(_G.LevelingCodexRewardMark:GetParent() == buttons[2], "and marks it")
  MOCK.event("QUEST_FINISHED")
  MOCK.chat = {}
  MOCK.rewardChoices[2][3] = nil
  MOCK.event("QUEST_COMPLETE")
  MOCK.advance(5)
  check(chatHas("Mail Vest sells for the most %(4s 50c%), but the price of Cloth Gloves didn't load%."),
    "a price that never loads is named")
  check(_G.LevelingCodexRewardMark:GetParent() == buttons[1], "the best known reward is marked")
  check(rewardLines() == 1, "said once")
  MOCK.event("QUEST_FINISHED")
  MOCK.chat = {}
  MOCK.rewardChoices = { { "Mail Vest", 1, 450 }, { "Cloth Gloves", 1, 450 }, { "Rough Arrow", 200, 1 } }
  MOCK.event("QUEST_COMPLETE")
  check(chatHas("Mail Vest sells for the most %(4s 50c%), tied with Cloth Gloves%."), "a tie says so")
end

-- The mark goes on the button QuestInfo tagged with that choice, even when the buttons start with
-- a fixed reward.
function S.questRewardButtons()
  S.login()
  local frame = CreateFrame("Frame", "QuestInfoRewardsFrame", UIParent)
  frame.RewardButtons = {}
  local kinds = { { "reward", 1 }, { "choice", 1 }, { "choice", 2 } }
  for i, k in ipairs(kinds) do
    local b = CreateFrame("Button", "QuestInfoRewardsFrameQuestInfoItem" .. i, frame)
    b.type = k[1]
    b:SetID(k[2])
    frame.RewardButtons[i] = b
  end
  MOCK.questChoices = 2
  MOCK.rewardChoices = { { "Mail Vest", 1, 450 }, { "Cloth Gloves", 1, 1300 } }
  MOCK.event("QUEST_COMPLETE")
  check(_G.LevelingCodexRewardMark:GetParent() == frame.RewardButtons[3], "the second choice's own button is marked")
end

function S.questMobTarget()
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  local vermin = { text = "Kobold Vermin 4/10", numFulfilled = 4, numRequired = 10 }
  MOCK.questLog = { { questID = 7, objectives = { vermin } } }
  S.login()
  local target = _G.LevelingCodexQuestTarget
  check(target and target:IsShown() and target:GetAttribute("macrotext") == "/targetexact Kobold Vermin",
    "an objective step targets the creatures it needs")
  MOCK.fire(target, "OnEnter")
  check(#GameTooltip._lines == 1 and GameTooltip._lines[1] == "Target Kobold Vermin",
    "the target tooltip shows just the creature name")
  MOCK.fire(target, "OnLeave")
  MOCK.ns.questMobs[7] = { "Kobold Vermin", "Kobold Worker" }
  MOCK.event("QUEST_LOG_UPDATE")
  check(target:GetAttribute("macrotext") == "/targetexact Kobold Worker\n/targetexact Kobold Vermin",
    "the first creature listed goes last, so it wins when both are near")
  MOCK.fire(target, "OnEnter")
  check(#GameTooltip._lines == 2 and GameTooltip._lines[2] == "Kobold Vermin, Kobold Worker",
    "the compact tooltip still shows every supported target")
  MOCK.fire(target, "OnLeave")
  local many = {}
  for i = 1, 30 do many[i] = "Kobold Tunnel Rat " .. i end
  MOCK.ns.questMobs[7] = many
  MOCK.event("QUEST_LOG_UPDATE")
  local macro = target:GetAttribute("macrotext")
  check(#macro <= 255 and macro:find("Kobold Tunnel Rat 1$"), "a long list is cut to fit a macro, keeping the first")
  vermin.text, vermin.numFulfilled, vermin.finished = "Kobold Vermin 10/10", 10, true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not (target:IsShown() and target:GetAttribute("macrotext"):find("Kobold")),
    "finished objectives stop targeting their creatures")
end

function S.questMapPin()
  S.login()
  local frame = questViewer()
  local function pin() local w = MOCK.userWaypoint; return w and w.uiMapID, w and w.position.x, w and w.position.y end
  local map, x, y = pin()
  check(map == 1429 and math.abs(x - 0.4817) < 0.0001 and math.abs(y - 0.4294) < 0.0001 and MOCK.superTracked,
    "the current step gets the game's map waypoint")
  click(frame, "Next")
  local _, x2 = pin()
  check(x2 and math.abs(x2 - 0.4817) > 0.0001, "the waypoint follows the next step")
  MOCK.userWaypoint = { uiMapID = 1429, position = { x = 0.1, y = 0.1 } }
  click(frame, "Back")
  map, x = pin()
  check(x == 0.1, "a waypoint the player placed is never replaced")
  MOCK.userWaypoint = nil
  MOCK.event("QUEST_LOG_UPDATE")
  check(pin() == 1429, "once the player's waypoint is gone the step is pinned again")
  LevelingCodexDB.noQuestMapPin = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(MOCK.userWaypoint == nil, "the setting clears the Codex's waypoint")
end

-- The step sound: the game finishing a step (an accept, a turn-in) plays it; Next doesn't.
function S.stepSound()
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - A Threat Within"), "Northshire starts with A Threat Within")
  MOCK.sounds = {}
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  check(#MOCK.sounds == 1, "accepting the step's quest plays the step sound (" .. #MOCK.sounds .. ")")
  check(MOCK.sounds[1].channel == "Master", "on the Master channel, so a low effects volume doesn't hide it")
  MOCK.questLog = {}
  MOCK.questDone[783] = true
  MOCK.event("QUEST_TURNED_IN", 783, 100, 0)
  MOCK.event("QUEST_LOG_UPDATE")
  check(#MOCK.sounds == 2, "turning it in plays it again (" .. #MOCK.sounds .. ")")
  click(frame, "Next")
  check(#MOCK.sounds == 2, "Next is quiet")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("step sound: played 2 times this session, last for Turn in %- A Threat Within"),
    "debug says when the step sound played")
end

-- The step window colours each step by kind: a chip and a tinted title row.
function S.stepKinds()
  local kind = MOCK.ns.questStepKind
  check(kind({ type = "accept" }) == "accept" and kind({ type = "turnin" }) == "turnin"
    and kind({ type = "fly" }) == "travel" and kind({ type = "boss" }) == "dungeon"
    and kind({ type = "note" }) == "other" and kind({ type = "buy" }) == "collect", "step kinds")
  check(MOCK.ns.questKindStyle("other", { type = "train" }).label == "Train", "other kinds use the step's word")
  check(MOCK.ns.questKindStyle("dungeon", { type = "boss" }).label == "Boss", "a boss step's chip")
  S.login()
  local frame = questViewer()
  local function shown(text)
    local function walk(f)
      for _, r in ipairs({ f:GetRegions() }) do if r:IsShown() and r._text == text then return true end end
      for _, c in ipairs({ f:GetChildren() }) do if c:IsShown() and walk(c) then return true end end
    end
    return walk(frame)
  end
  check(frame.chip and frame.chip.text._text == "Accept" and shown("A Threat Within") and not shown("Accept - A Threat Within"),
    "an accept step: the chip says Accept, the title shows the name alone")
  local band = frame.statusBand
  check(band and band:IsShown(), "the step kind has a tint behind the title row")
  local _, _, _, left, top = band:GetPoint(2)
  local _, _, _, chipLeft, chipTop = frame.chip:GetPoint()
  check(left < chipLeft and chipLeft - left <= 4 and top > chipTop and band:GetHeight() >= frame.chip:GetHeight(),
    "the band is inset around the chip, beside the portrait")
  local accept = frame.chip.plate._color
  check(accept[1] > accept[2], "the chip is gold for a pickup")
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  local turnin = frame.chip.plate._color
  check(frame.chip.text._text == "Turn in" and turnin[2] > turnin[1] and turnin[2] > turnin[3], "a turn-in step: green")
  click(frame, "Compact")
  local _, _, _, compactLeft = band:GetPoint(2)
  check(band:IsShown() and compactLeft < left, "the title tint follows the chip in compact mode")
end

-- Up next rows: the step's icon and how far it is, updating as you move.
function S.stepUpNext()
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 3, { type = "goto", text = "Look in on Stormwind.", map = 1453, x = 50, y = 50 })
  MOCK.mapInfo = { [1453] = { name = "Stormwind City", mapType = 3, parentMapID = 1415 } }
  MOCK.questX, MOCK.questY = 44, 41
  S.login()
  local frame = questViewer()
  local function dist()
    local function walk(f)
      for _, r in ipairs({ f:GetRegions() }) do
        if r:IsShown() and type(r._text) == "string" and r._text:match("^%d+ yd$") then return r._text end
      end
      for _, c in ipairs({ f:GetChildren() }) do local hit = c:IsShown() and walk(c); if hit then return hit end end
    end
    return walk(frame)
  end
  local before = dist()
  check(before, "an up-next row shows its distance")
  check(questText(frame, "Stormwind City"), "a step on another map shows its zone")
  MOCK.questX = 47
  MOCK.advance(0.5)
  check(dist() and dist() ~= before, "and it updates as you move")
  MOCK.questX, MOCK.questY = nil, nil -- no position (an instance)
  MOCK.advance(0.5)
  check(not dist(), "no position: no distances, no error")
end

-- A turn-in step shows the XP it gives, and when it levels you up.
function S.stepXP()
  MOCK.xp, MOCK.xpMax = 100, 400
  MOCK.rewardXP = { [783] = 350 }
  S.login()
  local frame = questViewer()
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  if MOCK.minimal then check(not questText(frame, " XP"), "no XP API: no chip"); return end
  check(questText(frame, "+350 XP") and questText(frame, "levels you up"), "the turn-in's XP chip")
  MOCK.rewardXP[783] = 100
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "+100 XP") and not questText(frame, "levels you up"), "not enough to level")
  MOCK.questLog = {}
  MOCK.questDone[783] = true
  MOCK.event("QUEST_TURNED_IN", 783, 100, 0)
  MOCK.event("QUEST_LOG_UPDATE")
  check(not questText(frame, "+100 XP"), "the next step has no chip")
end

-- A small 3D portrait of the step's NPC, the step's icon when the model can't show.
function S.questPortrait()
  MOCK.ns.questNPCs[783] = { start = 197, finish = 823 }
  S.login()
  local frame = questViewer()
  local p = frame.portrait
  check(p.rim and p.rim._color[1] == MOCK.ns.C.edgeSoft[1], "the portrait has a rim in the active theme's edge colour")
  if MOCK.minimal then
    check(p and p:IsShown() and p.icon:IsShown() and not (p.model and p.model:IsShown()), "no models: the icon")
    return
  end
  check(p:IsShown() and p.creature == 197 and p.model:IsShown(), "an accept step shows its giver")
  -- A quest several NPCs give (class quests): the one the step names.
  local giver
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    for _, step in ipairs(section.steps) do
      if step.quest == 783 and step.type == "accept" then giver = giver or step.npc end
    end
  end
  check(giver, "the 783 pickup names its NPC")
  MOCK.ns.questNPCs[783].by = { [giver] = 198 }
  MOCK.event("QUEST_LOG_UPDATE")
  check(p.creature == 198, "the step's own NPC wins over the first giver")
  MOCK.ns.questNPCs[783].by = nil
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  check(p.creature == 823, "a turn-in shows its finisher")
  MOCK.modelFails = true
  MOCK.ns.questNPCs[783].finish = 824
  MOCK.event("QUEST_LOG_UPDATE")
  local asked = p.model._asked
  MOCK.advance(1.2)
  check(p.icon:IsShown(), "a model still loading after a second shows the icon meanwhile")
  MOCK.advance(2.2)
  check(p.model._asked == asked + 1, "a model still loading is asked for once more")
  MOCK.modelFails = nil
  MOCK.advance(0.5)
  check(p.model:IsShown() and not p.icon:IsShown(), "a model that loads late replaces the icon")
  MOCK.modelFails = true
  MOCK.ns.questNPCs[783].finish = 825
  MOCK.event("QUEST_LOG_UPDATE")
  -- Reported from the game: Zombie Juice's step showed Tavernkeep Smitts, the step before's NPC. A
  -- creature the client hasn't loaded leaves the old model drawn, and that passed for loaded.
  MOCK.advance(0.3)
  check(not (p.model:IsShown() and p.model._shows and p.model._shows ~= 825), "the step before's NPC never stands in for this one")
  MOCK.advance(11)
  check(p.icon:IsShown() and not p.model:IsShown(), "a model that never loads gives way to the icon")
  MOCK.targetGUID = "Creature-0-1-2-3-825-0001"
  MOCK.event("PLAYER_TARGET_CHANGED")
  MOCK.advance(0.5)
  check(p.model:IsShown() and p.model._unit == "target" and not p.icon:IsShown(),
    "targeting the step's NPC shows it from the target")
  MOCK.targetGUID = nil
  -- Talking to the NPC (the quest window is open): drawn from that unit at once.
  MOCK.ns.questNPCs[783].finish = 826
  MOCK.npcGUID = "Creature-0-1-2-3-826-0001"
  MOCK.event("QUEST_LOG_UPDATE")
  check(p.model:IsShown() and p.model._unit == "npc", "the NPC you talk to is drawn from that unit")
  MOCK.npcGUID, MOCK.modelFails = nil, nil
  MOCK.ns.questNPCs[783] = nil -- a quest started by an object or item: no NPC to show
  MOCK.event("QUEST_LOG_UPDATE")
  check(p:IsShown() and p.icon:IsShown() and not p.model:IsShown(), "no NPC ID: the well shows the icon")
  LevelingCodexDB.noQuestPortrait = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not p:IsShown(), "the setting hides it")
end

-- The step window's buttons: a wide themed Next, small icon buttons with tooltips.
function S.stepButtons()
  S.login()
  local frame = questViewer()
  local nextB = findButton(frame, function(l) return l == "Next" end)
  check(nextB and nextB.label and nextB.label._text:find("^Next step") and nextB:GetWidth() > 200, "a wide Next step")
  for _, name in ipairs({ "Back", "Quests", "Hide" }) do
    local b = findButton(frame, function(l) return l == name end)
    check(b and b:GetWidth() <= 30, name .. " is an icon button")
    MOCK.fire(b, "OnEnter")
    check(GameTooltip._lines[1] == name, name .. " names itself on hover")
    MOCK.fire(b, "OnLeave")
  end
  check(nextB.rim and nextB.shade and nextB.bevel, "Next has an inset face, shading and a raised top edge")
  for _, name in ipairs({ "Back", "Quests", "Hide", "Compact" }) do
    local b = findButton(frame, function(l) return l == name end)
    check(b and not b.edgeLines, name .. " has no outline")
    if b.icon then check(not (b.bg and b.bg:IsShown()), name .. " is just its art") end
  end
  local hide = findButton(frame, function(l) return l == "Hide" end)
  local compactB = findButton(frame, function(l) return l == "Compact" end)
  if hide.icon then
    check(hide.icon._path == "Interface\\Buttons\\UI-Panel-MinimizeButton-Up"
      and not (compactB.icon and compactB.icon._path == hide.icon._path),
      "Hide is the close button, not the compact switch's minus")
  else
    check(hide.label._text ~= (compactB.label and compactB.label._text), "Hide and the compact switch read differently")
  end
  local before = nextB.fill._color[1]
  slash("")
  click(win(), "Settings")
  click(win(), "Codex (gold)") -- Settings' theme switch
  check(math.abs(nextB.fill._color[1] - before) > 0.1, "a theme switch repaints Next")
  check(frame.portrait.rim._color[1] == MOCK.ns.C.edgeSoft[1], "a theme switch repaints the portrait rim")
  click(frame, "Next")
  check(findButton(frame, function(l) return l == "Back" end), "Next still moves on")
end

-- Step window comfort: size (down to half for small screens, Ctrl+wheel), background, fading in
-- combat, compact mode.
function S.stepComfort()
  S.login()
  local frame = questViewer()
  slash("")
  click(win(), "Settings")
  for _ = 1, 2 do click(win(), "Step window size +") end
  check(math.abs(frame:GetScale() - 1.2) < 0.001, "the size stepper scales the window")
  for _ = 1, 10 do click(win(), "Step window size -") end
  check(math.abs(frame:GetScale() - 0.5) < 0.001, "down to half size for small screens")
  local textAlpha = frame:GetAlpha() or 1
  for _ = 1, 3 do click(win(), "Step window background -") end
  check(frame.background and math.abs((frame.background:GetAlpha() or 1) - 0.7) < 0.01
    and (frame:GetAlpha() or 1) == textAlpha, "the background stepper fades the background only")
  check(not frame:IsMouseWheelEnabled(), "the wheel stays the camera's")
  MOCK.fire(frame, "OnEnter"); MOCK.ctrl = true; MOCK.advance(0.1)
  check(frame:IsMouseWheelEnabled(), "Ctrl over the window takes the wheel")
  MOCK.fire(frame, "OnMouseWheel", 1)
  check(math.abs(frame:GetScale() - 0.6) < 0.001, "and the wheel resizes it")
  MOCK.ctrl = false; MOCK.fire(frame, "OnLeave"); MOCK.advance(0.1)
  check(not frame:IsMouseWheelEnabled(), "letting go gives the wheel back")
  MOCK.event("PLAYER_REGEN_DISABLED")
  MOCK.advance(0.5)
  check(math.abs((frame:GetAlpha() or 1) - 0.3) < 0.01, "combat fades the window")
  MOCK.fire(frame, "OnEnter"); MOCK.advance(0.5)
  check(math.abs((frame:GetAlpha() or 1) - 1) < 0.01, "the mouse brings it back")
  MOCK.fire(frame, "OnLeave"); MOCK.advance(0.5)
  check((frame:GetAlpha() or 1) < 0.5, "leaving fades it again")
  MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.5)
  check(math.abs((frame:GetAlpha() or 1) - 1) < 0.01, "after combat it's back")
  LevelingCodexDB.noQuestFade = true
  MOCK.event("PLAYER_REGEN_DISABLED"); MOCK.advance(0.5)
  check(math.abs((frame:GetAlpha() or 1) - 1) < 0.01, "with the setting off nothing fades")
  MOCK.event("PLAYER_REGEN_ENABLED")
  local tall = frame:GetHeight()
  click(frame, "Compact")
  check(frame:GetHeight() < tall and not questText(frame, "UP NEXT") and findButton(frame, function(l) return l == "Expand" end),
    "compact mode keeps only the title row, the bar and the buttons")
  click(frame, "Expand")
  check(questText(frame, "UP NEXT"), "and expands again")
end

-- The guide setup card offers the step window's size and compact mode (laptops meet them on first run).
function S.stepSetupWindow()
  S.login()
  slash("quests")
  local frame = questViewer()
  click(win(), "Setup"); click(win(), "Map and step window")
  click(win(), "Step window size -")
  check(math.abs(frame:GetScale() - 0.9) < 0.001, "the setup card's size stepper")
  click(win(), "Compact")
  check(LevelingCodexDB.questCompact and not questText(frame, "UP NEXT"), "and its Compact check box")
  click(win(), "Back to options"); click(win(), "Helpers")
  local function box(name) return findButton(win(), function(l) return l == name end) end
  check(box("Sell junk") and box("Sell junk"):GetChecked() and box("Repair") and box("Repair"):GetChecked(),
    "the vendor helpers start on")
  click(win(), "Sell junk")
  check(LevelingCodexDB.noAutoSell and not box("Sell junk"):GetChecked(), "Sell junk turns junk selling off")
  click(win(), "Repair")
  check(LevelingCodexDB.noAutoRepair and not box("Repair"):GetChecked(), "Repair turns repairing off")
  click(win(), "Sell junk")
  check(not LevelingCodexDB.noAutoSell, "and back on")
end

-- Compact mode on a step with no goals and no spot draws the title row alone.
function S.stepCompactNote()
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 1, { type = "note", text = "Read this first." })
  LevelingCodexDB = { questCompact = true }
  S.login()
  local frame = questViewer()
  check(frame:IsShown() and frame.chip.text._text == "Note" and not questText(frame, " yd"),
    "a compact note step: chip and title, no count or distance")
end

-- At any size the target button sits beside the window (in UIParent units), the arrow keeps its room
-- above it, and in combat a new size waits (the secure buttons beside it can't move then).
function S.stepScaleButtons()
  S.login()
  local frame = questViewer()
  frame._left, frame._top = 400, 600 -- the window's edges in its own units
  slash("")
  click(win(), "Settings")
  for _ = 1, 5 do click(win(), "Step window size -") end
  check(math.abs(frame:GetScale() - 0.5) < 0.001, "half size")
  local target = _G.LevelingCodexQuestTarget
  local _, _, _, x, y = target:GetPoint()
  check(target:IsShown() and math.abs(x - (400 * 0.5 - 10)) < 0.01 and math.abs(y - (600 * 0.5 - 72 * 0.5)) < 0.01,
    "the target button sits beside the half-size window (" .. tostring(x) .. ", " .. tostring(y) .. ")")
  check(frame._clampInsets and math.abs(frame._clampInsets[3] - 152) < 0.01, "the arrow keeps its room above the window")
  MOCK.combat = true
  click(win(), "Step window size +")
  check(math.abs(frame:GetScale() - 0.5) < 0.001, "in combat the new size waits")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(math.abs(frame:GetScale() - 0.6) < 0.001, "and applies after combat")
end

-- A dragged window keeps its spot on screen when it's resized (Ctrl+wheel stays under the cursor).
function S.stepScaleSaved()
  LevelingCodexDB = { questPosition = { "CENTER", "CENTER", 100, 50 } }
  S.login()
  local frame = questViewer()
  slash("")
  click(win(), "Settings")
  click(win(), "Step window size -")
  local _, _, _, x, y = frame:GetPoint()
  check(math.abs(x * frame:GetScale() - 100) < 0.01 and math.abs(y * frame:GetScale() - 50) < 0.01,
    "a dragged window keeps its spot when resized (" .. tostring(x) .. ", " .. tostring(y) .. ")")
end

-- Compact mode's distance on the title row stays live as you move.
function S.stepCompactDistance()
  LevelingCodexDB = { questCompact = true }
  MOCK.questX, MOCK.questY = 44, 41
  S.login()
  local frame = questViewer()
  local function dist()
    local function walk(f)
      for _, r in ipairs({ f:GetRegions() }) do
        if r:IsShown() and type(r._text) == "string" and r._text:match("^%d+ yd$") then return r._text end
      end
      for _, c in ipairs({ f:GetChildren() }) do local hit = c:IsShown() and walk(c); if hit then return hit end end
    end
    return walk(frame)
  end
  local before = dist()
  check(before, "compact shows how far the step is")
  MOCK.questX = 46
  MOCK.advance(0.5)
  check(dist() and dist() ~= before, "and it updates as you move (" .. tostring(before) .. " then " .. tostring(dist()) .. ")")
end

-- Titles keep their meaning: a travel chip says the step's own verb, and a step without a name takes
-- the first sentence of its text as its title (not "Travel" twice).
function S.stepTitles()
  local style = MOCK.ns.questKindStyle
  check(style("travel", { type = "fly" }).label == "Fly" and style("travel", { type = "getfp" }).label == "Flight path"
    and style("travel", { type = "boat" }).label == "Boat" and style("travel", { type = "goto" }).label == "Travel",
    "travel chips say the step's own verb")
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 1, { type = "goto", text = "Go down the tunnel to the cave. Mind the kobolds.",
    map = 1429, x = 52, y = 47 })
  S.login()
  local frame = questViewer()
  local function shown(text)
    local function walk(f)
      for _, r in ipairs({ f:GetRegions() }) do if r:IsShown() and r._text == text then return true end end
      for _, c in ipairs({ f:GetChildren() }) do if c:IsShown() and walk(c) then return true end end
    end
    return walk(frame)
  end
  check(frame.chip.text._text == "Travel" and shown("Go down the tunnel to the cave."),
    "a nameless step's title is the first sentence of its text")
end

-- Recommended stays the lit dungeon choice as you level past some of its runs.
function S.questSetupLevelled()
  S.login()
  slash("quests")
  click(win(), "Setup"); click(win(), "Your route")
  click(win(), "Recommended")
  MOCK.level = 30
  MOCK.event("PLAYER_LEVEL_UP", 30)
  slash("quests")
  guidesView("Dungeons")
  local rec = findButton(win(), function(l) return l == "Recommended" end)
  check(rec and rec.codexOn, "Recommended is still lit at level 30")
  check(not findButton(win(), function(l) return l:find("^Your picks") end), "not your picks")
end

-- A dungeon run done before the guide knew about it: every quest of the guide is turned in, but
-- the guide never saw you enter. Steps after the entry are done, so the entry is too.
function S.dungeonDoneBefore()
  MOCK.level = 25
  local guide
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "dungeon-deadmines" then guide = s end end
  for _, step in ipairs(guide.steps) do if step.quest then MOCK.questDone[step.quest] = true end end
  S.login()
  slash("quests")
  clickGuide("The Deadmines")
  click(win(), "Follow this guide")
  local frame = questViewer()
  check(not questText(frame, "Dungeon - The Deadmines"), "the entry step isn't left to do")
  check(not questText(frame, "Deadmines"), "a finished guide hands back to leveling: " .. MOCK.textUnder(frame))
end

-- After a /reload the game keeps the waypoint the Codex set, but the Codex has forgotten it set it:
-- one on a step of your route is still the Codex's and follows the step; the player's own stays.
function S.questMapPinReload()
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  local old
  for _, s in ipairs(northshire.steps) do
    if s.map == 1429 and s.x and math.abs(s.x - 48.17) > 1 then old = s; break end
  end
  MOCK.userWaypoint = { uiMapID = 1429, position = { x = old.x / 100, y = old.y / 100 } }
  S.login()
  local w = MOCK.userWaypoint
  check(w and math.abs(w.position.x - 0.4817) < 0.0001 and math.abs(w.position.y - 0.4294) < 0.0001,
    "the waypoint left on an earlier step moves to the current step")
  MOCK.userWaypoint = { uiMapID = 1429, position = { x = 0.1, y = 0.1 } }
  MOCK.event("QUEST_LOG_UPDATE")
  check(MOCK.userWaypoint.position.x == 0.1, "a waypoint off the route is the player's and stays")
end

-- The quest arrow: drag it anywhere, Ctrl+wheel resizes it, lock and reset; it hides with the window.
function S.arrowMove()
  LevelingCodexDB = { questArrowScale = 9 }
  S.login()
  local arrow, frame = _G.LevelingCodexQuestArrow, questViewer()
  check(arrow:GetParent() == UIParent and arrow:IsShown(), "the arrow lives on its own")
  check(math.abs(arrow:GetScale() - 2) < 0.001, "a saved scale out of bounds is held at 200%")
  -- The wheel zooms the camera unless Ctrl is held over the arrow.
  check(not arrow:IsMouseWheelEnabled(), "the arrow leaves the mouse wheel to the camera")
  MOCK.fire(arrow, "OnEnter")
  MOCK.advance(0.1)
  check(not arrow:IsMouseWheelEnabled(), "hovering alone still leaves the wheel to the camera")
  MOCK.ctrl = true
  MOCK.advance(0.1)
  check(arrow:IsMouseWheelEnabled(), "Ctrl held over the arrow takes the wheel to resize it")
  MOCK.ctrl = false
  MOCK.advance(0.1)
  check(not arrow:IsMouseWheelEnabled(), "letting go of Ctrl gives it back")
  MOCK.ctrl = true
  MOCK.advance(0.1)
  MOCK.fire(arrow, "OnLeave")
  check(not arrow:IsMouseWheelEnabled(), "and so does moving off the arrow")
  MOCK.ctrl = false
  slash("")
  click(win(), "Settings")
  click(win(), "Reset arrow")
  win():Hide()
  local _, rel = arrow:GetPoint()
  check(rel == frame and math.abs(arrow:GetScale() - 1) < 0.001, "unmoved, it sits above the step window at 100%")
  check(select(3, frame:GetClampRectInsets()) >= 76, "the window keeps room for it on screen")
  MOCK.drag(arrow, 100, 50)
  local p = LevelingCodexDB.questArrowPos
  _, rel = arrow:GetPoint()
  check(p and rel == UIParent, "dragging puts it anywhere and saves the spot")
  check(select(3, frame:GetClampRectInsets()) == 0, "a moved arrow no longer pads the window")
  -- where its centre is on screen: the anchor offset in the arrow's own (scaled) units times its scale
  local function centre()
    local point, _, _, x, y = arrow:GetPoint()
    return point, x * arrow:GetScale(), y * arrow:GetScale()
  end
  local _, cx, cy = centre()
  MOCK.ctrl = true
  MOCK.fire(arrow, "OnMouseWheel", 1)
  check(math.abs(arrow:GetScale() - 1.1) < 0.001 and LevelingCodexDB.questArrowScale, "Ctrl+wheel resizes it")
  local point, cx2, cy2 = centre()
  check(point == "CENTER" and math.abs(cx2 - cx) < 0.01 and math.abs(cy2 - cy) < 0.01,
    "resizing a moved arrow keeps its centre where it was")
  MOCK.fire(arrow, "OnMouseWheel", -1)
  MOCK.ctrl = false
  MOCK.fire(arrow, "OnMouseWheel", 1)
  check(math.abs(arrow:GetScale() - 1) < 0.001, "the wheel alone leaves the size")
  LevelingCodexDB.questArrowLocked = true
  local x = p[3]
  MOCK.drag(arrow, 30, 30)
  check(LevelingCodexDB.questArrowPos[3] == x, "a locked arrow stays put")
  click(frame, "Hide")
  check(not arrow:IsShown(), "it hides with the step window")
end

-- The arrow's colour says how far off course you face: green heading for the step, its own gold with
-- the step to your side, red with it behind you; Settings turns it off.
function S.arrowColor()
  MOCK.questX, MOCK.questY, MOCK.facing = 60, 60, 0 -- away from Deputy Willem, the first step
  S.login()
  local art = _G.LevelingCodexQuestArrow:GetRegions()
  check(art:IsShown() and art._rot, "the arrow points at the step")
  local ahead = art._rot -- facing this way puts the step straight ahead
  local function tint(facing)
    MOCK.facing = facing
    MOCK.advance(0.3)
    return art:GetVertexColor()
  end
  local r, g, b = tint(ahead)
  check(math.abs(art._rot) < 0.01 and g == 1 and r < 0.5 and b < 0.5, "heading for the step: green")
  r, g, b = tint(ahead + math.rad(10))
  check(g == 1 and r < 0.5, "a little off is still green")
  r, g, b = tint(ahead + math.pi / 2)
  check(math.abs(r - 1) < 0.01 and math.abs(g - 1) < 0.01 and math.abs(b - 1) < 0.01,
    "the step to your side: the arrow's own gold")
  local r2, g2 = tint(ahead - math.rad(55))
  check(g2 == 1 and r2 > 0.4 and r2 < 1, "turning toward it blends to green")
  r, g, b = tint(ahead + math.pi)
  check(r == 1 and g < 0.5 and b < 0.5, "the step behind you: red")
  slash("")
  click(win(), "Settings")
  click(win(), "Colour the arrow by direction")
  win():Hide()
  check(LevelingCodexDB.noArrowColor, "Settings turns it off")
  r, g, b = tint(ahead + math.pi - 0.01)
  check(r == 1 and g == 1 and b == 1, "and the arrow stays gold")
end

-- The icon's height over the arrow's centre, sampled every frame at 60 fps for `seconds`:
-- the lowest and highest it went and the biggest move from one frame to the next.
local function bobRun(arrow, seconds)
  local function lift()
    local point, _, _, _, y = arrow.here:GetPoint()
    return point == "CENTER" and y or nil
  end
  local low, high, jump, last = math.huge, -math.huge, 0, lift() or 0
  for _ = 1, math.floor(seconds * 60 + 0.5) do
    MOCK.advance(1 / 60, 1 / 60)
    local y = lift() or 1000 -- an icon off its centre anchor counts as a jump
    low, high = math.min(low, y), math.max(high, y)
    jump = math.max(jump, math.abs(y - last))
    last = y
  end
  return low, high, jump
end

-- The arrow on arrival: the step's icon bobs over a gold ring that pulses once; leaving brings it back.
-- In game the bob (a Translation looping BOUNCE) jumped where it turned: it is now drawn from the
-- clock every frame, so it rises and falls 8 px with no step at the turns or where it loops.
function S.arrowArrival()
  MOCK.questX, MOCK.questY = 60, 60 -- away from Deputy Willem (the default spot is next to him)
  S.login()
  local arrow = _G.LevelingCodexQuestArrow
  check(not arrow.here:IsShown() and arrow:GetRegions():IsShown(), "away from the step the arrow points")
  local willemX, yardsPerPercent = 48.17, 34.70833 -- Elwynn map width / 100
  MOCK.questX, MOCK.questY = willemX + 25 / yardsPerPercent, 42.94
  MOCK.advance(0.5)
  check(not arrow.here:IsShown() and arrow:GetRegions():IsShown() and questText(arrow, "25 yd"),
    "the arrow still points to Deputy Willem inside the old 35-yard radius")
  MOCK.questX = willemX + 7 / yardsPerPercent
  MOCK.advance(0.5)
  check(questText(arrow, "Deputy Willem") and questText(arrow, "Arrived"), "arrival names the step's NPC")
  check(arrow.here:IsShown() and not arrow:GetRegions():IsShown(), "the arrow turns into the step's icon")
  check(arrow.here._atlas == "crosshair_quest_64", "a pickup shows the yellow !")
  check(arrow.pulse:IsPlaying(), "the ring pulses")
  local low, high, jump = bobRun(arrow, 1)
  check(not arrow.pulse:IsPlaying(), "the ring pulses once")
  check(low > -0.01 and low < 0.5 and high > 7.5 and high < 8.01,
    "the icon bobs 8 px (went from " .. low .. " to " .. high .. ")")
  low, high, jump = bobRun(arrow, 2.5) -- three more loops
  check(high > 7.5 and jump < 0.6, "the bob goes on smoothly, also at its turns (biggest step " .. jump .. " px)")
  MOCK.questX = willemX + 9 / yardsPerPercent
  MOCK.advance(0.5)
  check(not arrow.here:IsShown() and arrow:GetRegions():IsShown(), "leaving the spot brings the arrow back")
  local _, _, _, _, y = arrow.here:GetPoint()
  check(y == 0, "and the icon is back on its centre for the next arrival")
  LevelingCodexDB.noArrowBounce = true
  MOCK.questX = willemX
  MOCK.advance(0.5)
  low, high = bobRun(arrow, 1)
  check(arrow.here:IsShown() and low == 0 and high == 0, "with the animation off the icon stays still")
end

-- Step icons: the client's own crosshair art (the cursor icons without the pointer tip, drawn by
-- Blizzard at 32, 48, 64, 96 and 128 px), the smallest drawing at least as big as the icon is on
-- screen. Without atlases, the old 16-32 px gossip and cursor files.
function S.questIconArt()
  MOCK.questX, MOCK.questY = 48.17, 42.94 -- Deputy Willem, the first step (a pickup)
  S.login()
  MOCK.advance(0.5)
  if MOCK.minimal then -- no C_Texture (and no C_Map, so no arrival to watch)
    local tex = UIParent:CreateTexture()
    check(MOCK.ns.questMap.setIcon(tex, { type = "accept" }, 36) and not tex._atlas
      and tex._path == "Interface\\GossipFrame\\AvailableQuestIcon", "a client without the atlases shows the gossip ! file")
    return
  end
  local arrow, viewer = _G.LevelingCodexQuestArrow, questViewer()
  check(arrow.here:IsShown(), "arriving shows the step's icon")
  -- 36 px at scale 1 on a 1080p screen is 51 pixels; the step title's 16 px is 23
  check(arrow.here._atlas == "crosshair_quest_64", "the arrival ! is the 64 px drawing: " .. tostring(arrow.here._atlas))
  check(viewer.titleIcon._atlas == "crosshair_quest_32", "the title's ! is the 32 px one: " .. tostring(viewer.titleIcon._atlas))
  -- on a 4K screen the same 36 px is 101 pixels
  MOCK.screenHeight = 2160
  MOCK.questX, MOCK.questY = 60, 60
  MOCK.advance(0.5)
  MOCK.questX, MOCK.questY = 48.17, 42.94
  MOCK.advance(0.5)
  check(arrow.here._atlas == "crosshair_quest_128", "on 4K the arrival ! is the 128 px one: " .. tostring(arrow.here._atlas))
  -- a texture going back to a file loses the atlas's coordinates
  local tex = viewer:CreateTexture()
  MOCK.ns.questMap.setIcon(tex, { type = "accept" }, 36)
  MOCK.ns.questMap.setIcon(tex, { type = "boss" }, 36)
  local l, t, _, _, _, _, r, b = tex:GetTexCoord()
  check(tex._path == "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" and l == 0 and t == 0 and r == 1 and b == 1,
    "a step without crosshair art (a boss) shows its own file, whole")
end

-- Minimap: pins for the current and next steps, an edge arrow out of range, a dotted line.
function S.minimapPins()
  S.login()
  local pins = _G.LevelingCodexMinimapPins
  if MOCK.minimal then
    MOCK.advance(0.5)
    check(not (pins and pins:IsShown()), "no map API: no pins, no error")
    return
  end
  MOCK.viewRadius = 200
  -- Five percent south of Deputy Willem: about 116 yd (Elwynn is 2314.6 yd tall), 40 px out.
  MOCK.questX, MOCK.questY = 48.17, 47.94
  MOCK.advance(0.2)
  check(pins and pins:IsShown() and pins.current:IsShown(), "the current step gets a minimap pin")
  local _, _, _, x, y = pins.current:GetPoint()
  check(math.abs(x) < 0.5 and y > 0, "north is up")
  check(#pins.next >= 1 and pins.next[1]:IsShown(), "the next steps get small pins")
  local function dots()
    local n = 0
    for _, d in ipairs(pins.dots) do if d:IsShown() then n = n + 1 end end
    return n
  end
  check(dots() > 0, "a dotted line leads to the step")
  local pinSets, dotSets = pins.current._pointSets, pins.dots[1]._pointSets
  MOCK.advance(1)
  check(pins.current._pointSets == pinSets and pins.dots[1]._pointSets == dotSets,
    "standing still, nothing on the minimap is moved again")
  MOCK.questY = 47.5
  MOCK.advance(0.2)
  check(pins.current._pointSets > pinSets, "moving moves the pins")
  MOCK.questY = 47.94
  MOCK.advance(0.2)
  MOCK.cvars = { rotateMinimap = "1" }
  MOCK.facing = math.pi / 2 -- facing west: north is to the right
  MOCK.advance(0.2)
  _, _, _, x, y = pins.current:GetPoint()
  check(x > 0 and math.abs(y) < 0.5, "a rotating minimap turns the pins with you")
  MOCK.cvars, MOCK.facing = {}, 0
  MOCK.questY = 60 -- 394 yd south of Willem: off the minimap, no trip
  MOCK.advance(0.2)
  check(not pins.edge:IsShown() and not pins.current:IsShown() and dots() > 0,
    "the game's own waypoint arrow marks the rim, so ours stays off; the dots still run there")
  MOCK.superTracked = false -- you track something else: the game's arrow points there instead
  MOCK.advance(0.2)
  check(pins.edge:IsShown(), "while the game's arrow tracks something else, ours shows")
  MOCK.superTracked = true
  MOCK.advance(0.2)
  check(not pins.edge:IsShown(), "and gives way again once it tracks the Codex's waypoint")
  LevelingCodexDB.noQuestMapPin = true
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.2)
  check(pins.edge:IsShown(), "without the map pin, our edge arrow shows")
  MOCK.questY = 80
  MOCK.advance(0.2)
  check(not pins.current:IsShown() and pins.edge:IsShown(), "out of range the pin becomes an edge arrow")
  _, _, _, x, y = pins.edge:GetPoint()
  check(math.abs(math.sqrt(x * x + y * y) - 66.5) < 0.6, "on the rim of a round minimap")
  MOCK.minimapShape = "SQUARE"
  MOCK.advance(0.2)
  _, _, _, x, y = pins.edge:GetPoint()
  check(math.abs(math.max(math.abs(x), math.abs(y)) - 66.5) < 0.6, "on the edge of a square minimap")
  LevelingCodexDB.noQuestMapPin = nil
  MOCK.minimapShape, MOCK.viewRadius = nil, 0
  MOCK.minimapZoom = 9 -- no zoom table entry either
  MOCK.advance(0.2)
  check(not pins.current:IsShown() and not pins.edge:IsShown(), "no usable scale: no pins")
  MOCK.viewRadius, MOCK.minimapZoom = 200, nil
  LevelingCodexDB.noMinimapLine = true
  MOCK.questY = 47.94
  MOCK.advance(0.2)
  check(pins.current:IsShown() and dots() == 0, "the line can be turned off")
  LevelingCodexDB.noMinimapSteps = true
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.2)
  check(not pins:IsShown(), "and the pins")
end

-- Minimap route: the dots run to the current step (no second line past it); they fade
-- toward the rim and stop on arrival, where the pin pulses; pins name their step on hover and let
-- clicks through; next steps off the minimap wait on the rim; a ghost's line leads to the corpse.
function S.minimapRoute()
  S.login()
  if MOCK.minimal then return end
  local pins = _G.LevelingCodexMinimapPins
  local function shown(list)
    local out = {}
    for _, d in ipairs(list or {}) do if d:IsShown() then out[#out + 1] = d end end
    return out
  end
  local function brightest(list, from, to)
    local a = 0
    for i = from, to do if list[i] then a = math.max(a, list[i]:GetAlpha() or 0) end end
    return a
  end
  local function tooltipHas(text)
    for _, line in ipairs(GameTooltip._lines or {}) do
      if type(line) == "string" and line:find(text, 1, true) then return true end
    end
    return false
  end
  -- 100 yd across half the minimap: Deputy Willem 46 yd north (32 px), then Marshal McBride
  -- about 28 px further on, then Willem again.
  MOCK.viewRadius = 100
  MOCK.questX, MOCK.questY = 48.17, 44.94
  MOCK.advance(0.3)
  local line = shown(pins.dots)
  check(pins.ahead == nil, "no second line")
  check(#line > 0, "the dots run to the current step")

  -- Willem 116 yd north is off the minimap: the line runs to the rim and fades out there.
  MOCK.questY = 47.94
  MOCK.advance(0.3)
  line = shown(pins.dots)
  check(#line >= 5 and line[#line]:GetAlpha() < 0.6 * brightest(line, 1, #line - 2),
    "the line fades out toward the rim")

  -- At the step (30 yd out, inside the 35 yd arrival; 52 px at 40 yd across, room for a line):
  -- no line, and the pin pulses its ring once.
  MOCK.viewRadius, MOCK.questY = 40, 44.24
  MOCK.advance(0.3)
  check(#shown(pins.dots) == 0, "on arrival the line stops")
  check(pins.current:IsShown() and pins.current.pulse and pins.current.pulse:IsPlaying(), "and the pin pulses")
  MOCK.advance(1)
  check(not pins.current.pulse:IsPlaying(), "once")

  MOCK.fire(pins.current, "OnEnter")
  check(tooltipHas("A Threat Within") and tooltipHas(" yd"), "hovering a pin names its step and how far it is")
  MOCK.fire(pins.current, "OnLeave")
  check(pins.current._mouseClick == false and pins.current._mouseMotion == true, "clicks go through to the minimap")

  -- 20 yd across: Marshal McBride, 66 yd away, waits on the rim, faded.
  MOCK.viewRadius = 20
  MOCK.advance(0.3)
  local n = pins.next[1]
  local _, _, _, x, y = n:GetPoint()
  check(n:IsShown() and math.abs(math.sqrt(x * x + y * y) - 66.5) < 0.6 and n:GetAlpha() < 0.6,
    "a next step off the minimap waits on its rim, faded")
  MOCK.fire(n, "OnEnter")
  check(tooltipHas("Marshal McBride") or tooltipHas("A Threat Within"), "and names its step on hover")
  MOCK.fire(n, "OnLeave")

  -- A ghost: the pin and the line lead to the corpse, 46 yd east.
  MOCK.viewRadius = 100
  MOCK.ghost, MOCK.corpse = true, { 1429, 49.5, 44.24 }
  MOCK.advance(0.5)
  _, _, _, x, y = pins.current:GetPoint()
  check(x > 20 and math.abs(y) < 1, "as a ghost the minimap leads to your corpse (" .. x .. ", " .. y .. ")")
  MOCK.ghost = false
end

-- Pace: kill XP lines with rested or group text and in the client's own words; the debug line.
function S.paceKills()
  S.login()
  if MOCK.minimal then return end
  local st, lvl = LevelingCodexCharDB.stats, MOCK.level
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Vermin dies, you gain 1,250 experience. (+625 exp Rested bonus)")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Worker dies, you gain 40 experience. (+8 exp Group bonus)")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "You gain 300 experience.")
  check(st.levels[lvl].killXP == 1290 and st.levels[lvl].kills == 2, "rested and group lines count, a plain gain doesn't")
  MOCK.chat = {}
  slash("debug")
  check(chatHas('pace: last XP line "You gain 300 experience." %-> not counted'), "debug names the last XP line")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Worker dies, you gain 40 experience.")
  MOCK.chat = {}
  slash("debug")
  check(chatHas('pace: last XP line "Kobold Worker dies, you gain 40 experience." %-> kill 40 XP'),
    "and what a kill line counted")
end

-- Pace: the kill line in another client language.
function S.paceKillsLocale()
  COMBATLOG_XPGAIN_FIRSTPERSON = "%s stirbt, Ihr bekommt %d Erfahrung."
  S.login()
  if MOCK.minimal then COMBATLOG_XPGAIN_FIRSTPERSON = nil; return end
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 75 Erfahrung.")
  local l = LevelingCodexCharDB.stats.levels[MOCK.level]
  COMBATLOG_XPGAIN_FIRSTPERSON = nil
  check(l.killXP == 75 and l.kills == 1, "the client's own wording counts")
end

-- Pace: a kill line with the client's grammar codes (|1a;b; picks a particle, |4 a plural) counts.
function S.paceKillsGrammar()
  COMBATLOG_XPGAIN_FIRSTPERSON = "%s|1i;ga; jugeossseumnida. gyeongheomchi %d|4jeom:jeom; hoekdeuk."
  S.login()
  if MOCK.minimal then COMBATLOG_XPGAIN_FIRSTPERSON = nil; return end
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold ga jugeossseumnida. gyeongheomchi 75jeom hoekdeuk.")
  local l = LevelingCodexCharDB.stats.levels[MOCK.level]
  COMBATLOG_XPGAIN_FIRSTPERSON = nil
  check(l and l.killXP == 75 and l.kills == 1, "a line with grammar codes counts")
end

-- Pace: a kill line that puts the number before the creature's name.
function S.paceKillsNumberFirst()
  COMBATLOG_XPGAIN_FIRSTPERSON = "%2$d XP: %1$s stirbt."
  S.login()
  if MOCK.minimal then COMBATLOG_XPGAIN_FIRSTPERSON = nil; return end
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "75 XP: Kobold stirbt.")
  local l = LevelingCodexCharDB.stats.levels[MOCK.level]
  COMBATLOG_XPGAIN_FIRSTPERSON = nil
  check(l and l.killXP == 75 and l.kills == 1, "a number-first line counts")
end

-- Stats: a level first counted partway in remembers where counting began.
function S.statsFromPct()
  MOCK.level, MOCK.xp, MOCK.xpMax = 5, 400, 1000
  S.login()
  if MOCK.minimal then return end
  MOCK.advance(2)
  local st = LevelingCodexCharDB.stats
  check(st.levels[5].fromPct == 40, "level 5 counted from 40%")
  MOCK.level, MOCK.xp = 6, 50
  MOCK.event("PLAYER_LEVEL_UP", 6)
  MOCK.advance(2)
  check(st.levels[6] and st.levels[6].fromPct == nil, "a level reached by levelling up has no mark")
  check(MOCK.ns.thousands(21400) == "21,400" and MOCK.ns.thousands(999) == "999"
    and MOCK.ns.thousands(1234567) == "1,234,567", "thousands")
  local earlier = MOCK.ns.stats.earlierLevels(6, 3)
  check(#earlier == 1 and earlier[1].level == 5 and earlier[1].record == st.levels[5], "earlier levels, newest first")
  check(MOCK.ns.stats.levelRecord(6) == st.levels[6] and MOCK.ns.stats.levelRecord(7) == nil
    and st.levels[7] == nil, "a level's record, never made by asking")
  MOCK.xp = 500
  slash("")
  click(win(), "Stats")
  click(win(), "Reset stats")
  click(win(), "Click again to reset")
  MOCK.advance(2)
  local again = LevelingCodexCharDB.stats.levels[6]
  check(again and again.fromPct == 50, "after Reset stats, a level counted from partway in is marked again")
end

-- An outleveled dungeon's row fades like an outleveled guide's.
function S.guideRowsFade()
  MOCK.race, MOCK.level = "Human", 40
  S.login()
  slash("quests")
  guidesView("Dungeons")
  local function find(f, text)
    for _, r in ipairs({ f:GetRegions() }) do if r._text == text and r:IsShown() then return r end end
    for _, c in ipairs({ f:GetChildren() }) do local hit = c:IsShown() and find(c, text); if hit then return hit end end
  end
  local title = find(win(), "The Deadmines")
  local dim = MOCK.ns.C.dim
  local r, g, b = title:GetTextColor()
  check(math.abs(r - dim[1]) < 0.01 and math.abs(g - dim[2]) < 0.01 and math.abs(b - dim[3]) < 0.01,
    "the outleveled Deadmines row is dimmed")
end

-- A long guide title stays on one line inside its row.
function S.guideRowsLong()
  MOCK.race, MOCK.level = "Human", 32
  S.login()
  slash("quests")
  local title = "Stranglethorn Early: Rebel Camp and Nesingwary"
  local row = guideButton(title)
  check(row and row._type == "Button" and not row.SetLook, "a guide is a row, not a panel button")
  local function find(f)
    for _, r in ipairs({ f:GetRegions() }) do if r._text == title and r:IsShown() then return r end end
    for _, c in ipairs({ f:GetChildren() }) do local hit = c:IsShown() and find(c); if hit then return hit end end
  end
  local fs = find(win())
  check(fs and fs:GetWidth() <= row:GetWidth() - 24, "the title keeps clear of the range and the tag")
  guidesView("All levels")
  check(findButton(win(), function(l) return l:find("^LEVELS 30%-40") end),
    "an open band keeps its label")
end

-- Minimap: the line bends through a step's way-in points to the step itself.
function S.minimapPath()
  -- the questEntrancePath step: tunnel points (48, 43) and (50, 45), the cave at (52, 47)
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 1, { type = "goto", text = "Go down the tunnel to the cave.", map = 1429,
    x = 52, y = 47, path = { { 48, 43 }, { 50, 45 } } })
  MOCK.questX, MOCK.questY, MOCK.viewRadius = 44, 41, 400
  S.login()
  if MOCK.minimal then return end
  local pins = _G.LevelingCodexMinimapPins
  MOCK.advance(0.5)
  local function shown(list) local n = 0; for _, t in ipairs(list) do if t:IsShown() then n = n + 1 end end; return n end
  check(shown(pins.bends) == 2, "a bend dot at the second tunnel point and at the cave")
  local _, _, _, px, py = pins.current:GetPoint()
  local far = 0
  for _, d in ipairs(pins.dots) do
    if d:IsShown() then local _, _, _, x, y = d:GetPoint(); far = math.max(far, math.sqrt(x * x + y * y)) end
  end
  check(far > math.sqrt(px * px + py * py) + 5, "dots go on past the pin, through the tunnel")
  MOCK.questX, MOCK.questY = 48, 43
  MOCK.advance(0.5)
  check(shown(pins.bends) == 1, "past the first point, one bend is left")
  MOCK.questMap, MOCK.questX, MOCK.questY = 1415, 46.02, 70.09 -- on the continent map
  MOCK.advance(0.5) -- an error in the minimap's OnUpdate fails the scenario here
end

-- World map: numbered pins for the current and next steps on the map the world map shows.
function S.worldMapPins()
  S.login()
  if MOCK.minimal then return end
  MOCK.worldMapID = 1429
  WorldMapFrame:Show()
  local pins = _G.LevelingCodexWorldMapPins
  check(pins and pins:IsShown() and pins.current:IsShown(), "the current step shows on the world map")
  local _, _, _, x, y = pins.current:GetPoint()
  check(math.abs(x - 482.66) < 1 and math.abs(y + 286.84) < 1, "at the step's spot on the map")
  check(pins.next[1]:IsShown(), "the next step gets a numbered pin")
  -- Zoomed in, the canvas is drawn twice as large: the pins keep their size and stay on their spot.
  MOCK.canvasScale = 2
  MOCK.advance(0.1)
  _, _, _, x, y = pins.current:GetPoint()
  check(math.abs(pins.current:GetScale() - 0.5) < 0.001 and math.abs(x - 965.32) < 2 and math.abs(y + 573.68) < 2,
    "zooming the map keeps the pins' size and spot (scale " .. tostring(pins.current:GetScale()) .. ", x " .. x .. ")")
  MOCK.canvasScale = nil
  MOCK.advance(0.1)
  _, _, _, x = pins.current:GetPoint()
  check(math.abs(pins.current:GetScale() - 1) < 0.001 and math.abs(x - 482.66) < 1, "zooming back out")
  MOCK.fire(pins.current, "OnEnter")
  check(GameTooltip._lines[1] and GameTooltip._lines[1]:find("A Threat Within", 1, true), "hovering names the step")
  MOCK.fire(pins.current, "OnLeave")
  MOCK.worldMapID = 1453
  WorldMapFrame:OnMapChanged()
  check(not pins.current:IsShown(), "another map hides the pins")
  MOCK.worldMapID = 1429
  LevelingCodexDB.noWorldMapSteps = true
  WorldMapFrame:OnMapChanged()
  check(not pins:IsShown(), "the setting turns them off")
end

-- Special and class guides say what you get from them, in their row and on their page.
function S.guideRewards()
  MOCK.race, MOCK.level = "Human", 20
  S.login()
  slash("quests")
  guidesView("Special")
  local reward = "A sleeping bag: rest in it for up to 3% bonus XP"
  check(questText(win(), reward), "a special chain says what you get")
  click(win(), "Class")
  check(questText(win(), "Teaches Defensive Stance, Taunt and Sunder Armor"), "a class guide says what it teaches")
  click(win(), "Special")
  click(win(), "Cozy Sleeping Bag")
  check(questText(win(), "You get: " .. reward), "and so does its page")
end

-- World map: a dotted route line from you, through a step's way-in points, to the step.
function S.worldMapLine()
  local northshire
  for _, s in ipairs(LevelingCodexQuests.ALLIANCE.sections) do if s.id == "northshire" then northshire = s end end
  table.insert(northshire.steps, 1, { type = "goto", text = "Go down the tunnel to the cave.", map = 1429,
    x = 52, y = 47, path = { { 48, 43 }, { 50, 45 } } })
  MOCK.questX, MOCK.questY = 44, 41
  S.login()
  if MOCK.minimal then return end
  MOCK.worldMapID = 1429
  WorldMapFrame:Show()
  local pins = _G.LevelingCodexWorldMapPins
  local function dots()
    local list = {}
    for _, d in ipairs(pins.dots or {}) do if d:IsShown() then list[#list + 1] = d end end
    return list
  end
  local line = dots()
  check(#line > 5, "a dotted line runs on the world map (" .. #line .. " dots)")
  check(line[1].edge and line[1].edge:IsShown(), "each dot has a dark edge, so it reads on the parchment map")
  check(pins:GetFrameLevel() >= 2000 and pins.line:GetFrameLevel() >= 2000 and pins.current:GetFrameLevel() >= 2000,
    "the pins and the line draw at the map's own pin level, above its art (" .. pins:GetFrameLevel() .. ")")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("world map line: %d+ dots from you to the step"), "debug says what the line drew")
  local far = 0
  for _, d in ipairs(line) do local _, _, _, x = d:GetPoint(); far = math.max(far, x) end
  check(far > 0.5 * 1002 and far <= 0.52 * 1002 + 1, "through the tunnel points to the cave (" .. far .. ")")
  MOCK.canvasScale = 2
  MOCK.advance(0.1)
  local farZoomed = 0
  for _, d in ipairs(dots()) do local _, _, _, x = d:GetPoint(); farZoomed = math.max(farZoomed, x) end
  check(math.abs(pins.line:GetScale() - 0.5) < 0.001 and farZoomed > 2 * 0.5 * 1002 and farZoomed <= 2 * 0.52 * 1002 + 2,
    "zoomed in, the line keeps its dot size and its spots (" .. farZoomed .. ")")
  MOCK.canvasScale = nil
  MOCK.advance(0.1)
  local _, _, _, x1 = line[1]:GetPoint()
  MOCK.questX = 46
  MOCK.advance(0.5)
  local _, _, _, x2 = dots()[1]:GetPoint()
  check(x2 > x1, "moving with the map open moves the line's start")
  MOCK.worldMapID = 1453
  WorldMapFrame:OnMapChanged()
  check(#dots() == 0, "a map you're not on has no line")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("world map line: none, the map shows 1453 and you're on 1429"), "and debug says why")
  MOCK.worldMapID = 1429
  WorldMapFrame:OnMapChanged()
  slash("")
  click(win(), "Settings")
  click(win(), "Route line on the world map")
  check(LevelingCodexDB.noWorldMapLine and #dots() == 0, "Settings turns it off")
  click(win(), "Route line on the world map")
  check(#dots() > 0, "and on again")
end

-- The step window's completion bar: steps you're past out of the guide's steps, sliding to its value.
function S.stepProgress()
  S.login()
  local bar, frame = _G.LevelingCodexQuestBar, questViewer()
  check(bar and bar:IsShown() and questText(bar, "0%"), "a fresh guide starts at 0%")
  click(frame, "Next")
  click(frame, "Next")
  MOCK.advance(0.1)
  local mid = bar.fill:GetWidth()
  MOCK.advance(0.6)
  check(bar.fill:GetWidth() > mid and not questText(bar, "0%"), "skipped steps fill the bar, sliding")
  MOCK.fire(bar, "OnEnter")
  local l = GameTooltip._lines
  check(l[1] and l[1]:find(" steps done (", 1, true) and l[2] and l[2]:find(" quests turned in", 1, true)
    and l[3] == "Click to see the route.", "the tooltip counts steps, then turn-ins: " .. tostring(l[1]))
  MOCK.fire(bar, "OnLeave")
  local pct = MOCK.textUnder(bar):match("(%d+)%%")
  bar:Click()
  check(win() and win():IsShown() and findButton(win(), function(l) return l == "Area steps" end),
    "clicking opens the journey")
  click(win(), "Guides")
  check(pct and (questText(win(), "Current " .. pct .. "%") or (pct == "0" and questText(win(), "Current"))),
    "the guide list shows the bar's percentage: " .. tostring(pct))
  LevelingCodexDB.noStepBar = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not bar:IsShown(), "the bar can be turned off")
end

-- The step window: the step's icon before its title, a flash on a rising count, a glow on completion.
function S.stepPolish()
  -- The questProgress setup: Kobold Vermin (quest 7) in progress after the first Northshire quests.
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = { { text = "Kobold Vermin 4/10", numFulfilled = 4 } } } }
  S.login()
  local frame = questViewer()
  -- the kill's target in the portrait (QuestNPCData.lua: Kobold Vermin, 6), the small icon hidden
  check(frame.portrait:IsShown() and frame.portrait.creature == 6 and not frame.titleIcon:IsShown(),
    "a kill step shows its target before its title")
  local row
  for _, c in ipairs({ frame:GetChildren() }) do
    if c.count and c.count._text == "4/10" and c:IsShown() then row = c end
  end
  check(row and row.bar and row.bar:IsShown() and row.track:IsShown()
    and math.abs(row.bar:GetWidth() - 0.4 * row.track:GetWidth()) < 1, "a 4/10 goal fills 40% of its bar")
  local c = row.bar._color
  check(c and math.abs(c[1] - 0.95) < 0.01 and math.abs(c[2] - 0.45) < 0.01, "in the kill step's red")
  local function flashing()
    for g in pairs(MOCK.anims) do if g._owner and g._owner._isFlash and g:IsPlaying() then return true end end
    return false
  end
  check(not flashing(), "nothing flashes before progress")
  MOCK.questLog[1].objectives[1] = { text = "Kobold Vermin 5/10", numFulfilled = 5 }
  MOCK.event("QUEST_LOG_UPDATE")
  check(flashing(), "a rising count flashes its row")
  MOCK.questLog[1].objectives[1] = { text = "Kobold Vermin 10/10", numFulfilled = 10, finished = true }
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(frame.glowAnim and frame.glowAnim:IsPlaying(), "a step the game finished makes the window's edge glow")
  check(MOCK.sounds and #MOCK.sounds > 0, "and plays a sound")
end

-- The Quests tab: a fixed step card and button row, then Step, Route, Guides and Quest log sub-tabs.
function S.questTabViews()
  S.login(); slash("quests")
  for _, name in ipairs({ "Setup", "Previous step", "Next step", "Show on map", "Step", "Route", "Guides", "Dungeons", "Quest log", "Party" }) do
    check(findButton(win(), function(l) return l == name end), "the quest board has " .. name)
  end
  check(findButton(win(), function(l) return l == "Area steps" end), "Journey opens first with area drill-down")
  click(win(), "Step")
  check(findButton(win(), function(l) return l == "Resume active quest" end), "the selected step retains its tools")
  click(win(), "Guides")
  check(findButton(win(), function(l) return l == "Your level" end).codexOn, "Routes opens on Your level")
  click(win(), "All levels")
  local band = findButton(win(), function(l) return l:find("^LEVELS 30%-40") end)
  check(band, "level bands are selectable tiles")
  band:Click()
  check(questText(win(), "Levels 3") and findButton(win(), function(l) return l == "All level bands" end), "a band opens its guide grid")
  click(win(), "Dungeons")
  check(findButton(win(), function(l) return l == "Recommended" end), "Dungeons has pickup plan choices")
  questQueue("Ready to turn in")
  check(questText(win(), "Ready to turn in"), "quest log categories open focused queues")
  stepTool("Report this step")
end

-- A buy step that lists several items waits until the bags hold every one of them.
function S.questBuyItems()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "buy", items = { { 2320, 1 }, { 3713, 2 } }, name = "Thread and spices",
        text = "Buy Fine Thread and two Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  MOCK.bags[2320] = 1
  S.login()
  local frame = questViewer()
  check(questText(frame, "Buy - Thread and spices"), "a buy step with two items waits for both")
  check(questText(frame, "In your bags 0/2"), "it counts the item still missing")
  MOCK.bags[3713] = 2
  MOCK.event("BAG_UPDATE_DELAYED")
  check(not questText(frame, "Buy - Thread and spices"), "it ticks off once the bags hold every item")
end

-- A buy step stays behind you once a later step of its guide is done, even with empty bags
-- (the items were handed in before a logout).
function S.questBuyUsedUp()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "buy", items = { { 3713, 2 } }, name = "Used up thread",
        text = "Buy Fine Thread.", map = 1429, x = 48, y = 43 })
    end
  end
  MOCK.questDone[783] = true
  MOCK.questDone[1218] = true -- the quest the spices were for, handed in
  S.login()
  check(not questText(questViewer(), "Buy - Used up thread"), "a buy step before a finished step doesn't come back")
end

-- A vendor errand for a quest's item stays until that quest is handed in: an unrelated later step done
-- long ago (here Northshire's 783) must not skip it (Soothing Spices, bought for quest 1218).
function S.questBuyNotSkipped()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "buy", item = 3713, count = 3, name = "Spices errand",
        text = "Buy Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  MOCK.questDone[783] = true
  S.login()
  check(questText(questViewer(), "Buy - Spices errand"), "an unrelated finished step doesn't skip a buy for a quest not handed in")
  MOCK.questDone[1218] = true
  S.login()
  check(not questText(questViewer(), "Buy - Spices errand"), "handing in the quest ends the errand")
end

-- Step types and gates: collect/buy by bag count, abandon, skipOn, profession, maxLevel, sticky goals.
function S.questStepTypes()
  local northshire
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then northshire = section end
  end
  local added = {
    { type = "collect", item = 2589, count = 5, name = "Linen Cloth", text = "Collect five Linen Cloth.", map = 1429, x = 48, y = 43 },
    { type = "collect", item = "Glowing Stone", name = "Glowing Stone", text = "Keep an eye out for a Glowing Stone.", sticky = true },
    { type = "abandon", quest = 999, name = "Old Errand", text = "Abandon Old Errand to make room." },
    { type = "goto", text = "Head into Elwynn.", map = 1429, x = 60, y = 60, skipOn = 1429 },
    { type = "note", text = "Miners only.", profession = "MINING" },
    { type = "note", text = "Low levels only.", maxLevel = 3 },
    { type = "note", text = "While Old Errand is in your log.", ifOnQuest = 999 },
    { type = "note", text = "Once A Threat Within is done.", ifDone = 783 },
  }
  for i, step in ipairs(added) do table.insert(northshire.steps, i, step) end
  MOCK.bags[2589] = 2
  MOCK.questLog = { { questID = 999, title = "Old Errand" } }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Collect - Linen Cloth") and questText(frame, "In your bags 2/5"), "a collect step counts your bags")
  MOCK.bags[2589] = 5
  MOCK.event("BAG_UPDATE_DELAYED")
  check(questText(frame, "Abandon - Old Errand"), "enough items finish the collect step; the sticky goal is passed over")
  check(questText(frame, "ON THE WAY") and questText(frame, "Collect - Glowing Stone 0/1"),
    "a passed sticky goal shows under the current step")
  MOCK.bags[2589] = 0
  MOCK.event("BAG_UPDATE_DELAYED")
  check(questText(frame, "Abandon - Old Errand"), "using the items later doesn't bring the collect step back")
  MOCK.questLog = {}
  MOCK.event("QUEST_REMOVED", 999)
  check(questText(frame, "Low levels only."), "abandoning finishes its step, skipOn passes a map you're on, "
    .. "a profession you don't have filters its step, and gated quest steps wait")
  MOCK.bags["Glowing Stone"] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  check(not questText(frame, "ON THE WAY"), "a finished sticky goal leaves the window")
  MOCK.level = 4
  MOCK.event("PLAYER_LEVEL_UP", 4)
  check(questText(frame, "Accept - A Threat Within"), "maxLevel skips a step once you're past it")
  MOCK.questDone[783], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 783)
  check(questText(frame, "Once A Threat Within is done."), "an ifDone step appears once its quest is turned in")
end

-- Steps with several spots: the arrow loops through them, or leads to the nearest one.
function S.questWaypoints()
  local northshire
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then northshire = section end
  end
  table.insert(northshire.steps, 1, { type = "note", text = "Clear the wolves along the slope.", map = 1429,
    points = { { 48, 43 }, { 52, 47 }, { 44, 39 } } })
  table.insert(northshire.steps, 2, { type = "note", text = "Use the nearest mailbox.", map = 1429,
    points = { { 40, 40 }, { 70, 70 } }, nearest = true })
  MOCK.questX, MOCK.questY = 48, 43
  S.login()
  local frame, arrow = questViewer(), LevelingCodexQuestArrow
  MOCK.advance(0.5)
  check(questText(arrow, "(spot 2 of 3)"), "reaching a spot moves the arrow on to the next")
  check(math.abs(MOCK.userWaypoint.position.x - 0.52) < 0.0001, "the map pin follows the arrow's spot")
  MOCK.questX, MOCK.questY = 52, 47
  MOCK.advance(0.5)
  check(questText(arrow, "(spot 3 of 3)"), "the next spot follows")
  MOCK.questX, MOCK.questY = 44, 39
  MOCK.advance(0.5)
  check(questText(arrow, "(spot 1 of 3)"), "after the last spot the arrow loops")
  click(frame, "Next")
  MOCK.advance(0.5)
  check(questText(frame, "Use the nearest mailbox.") and questText(arrow, "(spot 1 of 2)"), "nearest picks the closest spot")
  MOCK.questX, MOCK.questY = 66, 66
  MOCK.advance(0.5)
  check(questText(arrow, "(spot 2 of 2)"), "nearest changes as you move")
end

-- Route tooltips say why a step was skipped; Show on map, Report this step, the step count setting,
-- the quest tracker, the arrival time and the flight timer.
function S.questWindowExtras()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 18, 1433, "Goldshire"
  S.login()
  local frame = questViewer()
  check(questText(frame, "Flight path - Lakeshire, Redridge"), "Lakeshire starts at its flight path")
  click(frame, "Next")
  slash("quests")
  click(win(), "Route")
  if findButton(win(), function(l) return l == "Show all steps" end) then click(win(), "Show all steps") end
  local skipped = routeStep("Flight path - Lakeshire, Redridge")
  check(skipped and skipped.tipText:find("Skipped: you passed it with Next", 1, true), "the route list says why a step was skipped")
  click(win(), "Route"); click(win(), "Show on map")
  check(MOCK.openedMap == 1433, "Show on map opens the world map at the step")
  stepTool("Report this step")
  local copy = _G.LevelingCodexCopy
  local report = copy and copy:IsShown() and copy.edit:GetText() or ""
  check(report:find("Guide: lakeshire", 1, true) and report:find("Position: 1433", 1, true)
    and report:find("Hearthstone: Goldshire", 1, true), "the step report has the guide, position and hearth")
  copy:Hide()
  check(questText(frame, "UP NEXT"), "two steps ahead are listed by default")
  LevelingCodexDB.questPreview = 0
  MOCK.event("QUEST_LOG_UPDATE")
  check(not questText(frame, "UP NEXT"), "the step count setting can hide the steps ahead")
  LevelingCodexDB.questPreview = 2
end

-- The tracker follows the step's quest and lets go of a watch the Codex added.
function S.questTracker()
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = { { text = "Kobold Vermin 4/10", numFulfilled = 4 } } },
    { questID = 15, title = "Investigate Echo Ridge" } }
  MOCK.watches = { [15] = true }
  S.login()
  check(questText(questViewer(), "Kobold Vermin 4/10"), "login resumes the active objective")
  check(MOCK.watches[7], "the current step's quest is added to the tracker")
  LevelingCodexDB.noQuestWatch = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not MOCK.watches[7] and MOCK.watches[15], "the Codex takes off only a watch it added")
end

function S.questArrowTimes()
  MOCK.questX, MOCK.questY = 40, 40
  S.login()
  local arrow = LevelingCodexQuestArrow
  MOCK.advance(0.3)
  MOCK.questX, MOCK.questY = 40.4, 40.2
  MOCK.advance(0.3)
  MOCK.questX, MOCK.questY = 40.8, 40.4
  MOCK.advance(0.3)
  local caption = ""
  for _, r in ipairs({ arrow:GetRegions() }) do
    if r._text then caption = caption .. r._text end
  end
  check(caption:find(" yd %- %d+:%d%d"), "moving toward the step shows an arrival time: " .. caption)
  MOCK.taxiNodes = { { "Stormwind, Elwynn", "CURRENT" }, { "Lakeshire, Redridge", "REACHABLE" } }
  MOCK.event("TAXIMAP_OPENED")
  TakeTaxiNode(2)
  MOCK.onTaxi = true
  MOCK.advance(5)
  check(questText(arrow, "In flight to Lakeshire - 0:05"), "the flight timer counts up")
  MOCK.onTaxi = false
  MOCK.advance(0.5)
  MOCK.event("TAXIMAP_OPENED")
  TakeTaxiNode(2)
  MOCK.onTaxi = true
  MOCK.advance(2)
  check(questText(arrow, "left"), "a timed flight says how long is left the next time")
  MOCK.onTaxi = false
  MOCK.advance(0.5)
end

-- A new character gets the guide setup card: pace, dungeons and helpers, then Done.
function S.questSetup()
  S.login()
  local frame = questViewer()
  click(frame, "Set up the guide")
  check(questText(win(), "SET UP YOUR GUIDE"), "the step window opens the guide setup")
  local function seg(name) return findButton(win(), function(l) return l == name end) end
  check(seg("Fastest").codexOn and not seg("Every quest").codexOn, "a fresh setup lights Fastest")
  check(seg("Recommended") and seg("All") and seg("None"), "dungeons are three choices")
  local off, on = seg("Every quest"), seg("Fastest")
  check(off:GetAlpha() == 1 and off.plate and off.plate:IsShown(), "an unlit choice is a flat plate, not a dimmed button")
  if on.Left then
    check(off.Left:GetAlpha() == 0 and on.Left:GetAlpha() == 1 and not on.plate:IsShown(),
      "the panel button's art shows on the lit choice only")
  end
  local onLabel, offLabel = on.GetFontString and on:GetFontString(), off.GetFontString and off:GetFontString()
  if on.tick and onLabel and offLabel then
    local _, _, _, x = onLabel:GetPoint()
    local _, _, _, ox = offLabel:GetPoint()
    check(x and x >= 8 and ox == 0, "the lit label moves right of its tick; an unlit one stays centred")
  end
  click(win(), "None")
  check(seg("None").codexOn and not seg("Recommended").codexOn, "None lights once nothing is planned")
  click(win(), "Recommended")
  check(seg("Recommended").codexOn, "Recommended lights the recommended plan")
  click(win(), "All")
  check(seg("All").codexOn and LevelingCodexDB.questDungeons, "All plans every run")
  click(win(), "Recommended")
  check(seg("Recommended").codexOn and not LevelingCodexDB.questDungeons, "and back")
  LevelingCodexDB.questKeepGrey, LevelingCodexDB.questOptional = true, false
  slash("quests")
  check(not seg("Fastest").codexOn and not seg("Every quest").codexOn and questText(win(), "Custom: see Settings"),
    "a mixed pace lights neither and says so")
  click(win(), "Back to options"); click(win(), "Helpers")
  local accept = seg("Auto-accept")
  check(accept and accept.GetChecked and not accept:GetChecked(), "helpers are check boxes")
  click(win(), "Every quest")
  check(LevelingCodexDB.questKeepGrey and LevelingCodexDB.questOptional, "Every quest keeps grey and side quests")
  check(seg("Every quest").codexOn and not questText(win(), "Custom: see Settings"), "and lights")
  click(win(), "Auto-accept")
  check(LevelingCodexDB.questAutoAccept, "the setup turns helpers on")
  check(seg("Auto-accept"):GetChecked(), "and ticks the box")
  click(win(), "Fastest")
  check(not LevelingCodexDB.questKeepGrey and not LevelingCodexDB.questOptional, "Fastest drops them again")
  click(win(), "Back to options"); click(win(), "Map and step window")
  check(seg("Minimap"):GetChecked() and seg("World map"):GetChecked(), "both route lines start on")
  click(win(), "World map")
  check(LevelingCodexDB.noWorldMapLine and not seg("World map"):GetChecked(), "the setup turns the world map line off")
  click(win(), "Minimap")
  check(LevelingCodexDB.noMinimapLine, "and the minimap line")
  -- the party: every party sync option, with quest sharing on by default and the chat lines off
  click(win(), "Back to options"); click(win(), "Party play")
  check(seg("Party steps"):GetChecked() and seg("Share quests"):GetChecked() and seg("Ping together"):GetChecked(),
    "party sync, quest sharing and the together ping start on")
  check(not seg("Steps done"):GetChecked() and not seg("Quest items"):GetChecked() and not seg("Progress"):GetChecked()
    and not seg("Flights"):GetChecked(), "the party chat lines start off")
  click(win(), "Share quests")
  check(LevelingCodexDB.questShareParty == false and not seg("Share quests"):GetChecked(), "the setup turns quest sharing off")
  click(win(), "Share quests")
  check(LevelingCodexDB.questShareParty == true and seg("Share quests"):GetChecked(), "and back on")
  click(win(), "Party steps")
  click(win(), "Ping together")
  check(LevelingCodexDB.noPartySteps and LevelingCodexDB.noPartyPing, "party steps and the ping turn off")
  for _, name in ipairs({ "Steps done", "Quest items", "Progress", "Flights" }) do click(win(), name) end
  check(LevelingCodexDB.questAnnounceSteps and LevelingCodexDB.questAnnounceItems and LevelingCodexDB.questAnnounceProgress
    and LevelingCodexDB.questAnnounceFlights and seg("Flights"):GetChecked(), "the setup turns each party chat line on")
  LevelingCodexDB.questDungeons = false
  LevelingCodexDB.questDungeonPlan = { ["dungeon-deadmines"] = true }
  slash("quests")
  click(win(), "Back to options"); click(win(), "Your route")
  check(seg("Your picks (1)") and seg("Your picks (1)").codexOn, "a hand-made plan shows as your picks")
  click(win(), "Done")
  check(LevelingCodexDB.questSetupDone and not questText(win(), "SET UP YOUR GUIDE"), "Done closes the setup")
  local offer = findButton(frame, function(l) return l == "Set up the guide" end)
  check(not (offer and offer:IsShown()), "the step window stops offering the setup")
  click(win(), "Setup")
  check(questText(win(), "SET UP YOUR GUIDE"), "Guide setup opens it again")
end

-- Steps shown ahead (the setup card and Settings, 0-10): the list runs on into the next section.
function S.questPreviewAhead()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 22, 1433, "Lakeshire"
  local order, seen = {}, {}
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "lakeshire" then
      for _, step in ipairs(section.steps) do
        if step.quest and not seen[step.quest] then seen[step.quest], order[#order + 1] = true, step.quest end
      end
    end
  end
  local last, before = order[#order], order[#order - 1]
  for _, id in ipairs(order) do
    if id ~= last and id ~= before then MOCK.questDone[id] = true end
  end
  MOCK.questLog = { { questID = before, isComplete = true }, { questID = last, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  LevelingCodexDB.questPreview = 8
  MOCK.event("QUEST_LOG_UPDATE")
  local Q = MOCK.ns.quests
  local row, i = Q.current()
  local ahead = row and Q.upcoming(i, 8) or {}
  check(row and row.section.id == "lakeshire" and #ahead == 8 and ahead[1].section.id == "lakeshire"
    and ahead[8].section.id == "duskwood", "the test starts a few steps before the end of Lakeshire")
  for n, r in ipairs(ahead) do
    check(questText(frame, Q.label(r.step)), "8 steps ahead lists step " .. n .. ": " .. Q.label(r.step))
  end
  check(questText(frame, "Next section: Duskwood"), "the list names the next section where it starts")

  local function seg(name) return findButton(win(), function(l) return l == name end) end
  click(win(), "Setup"); click(win(), "Map and step window")
  check(not seg("2 steps").codexOn and questText(win(), "8 steps: see Settings"),
    "the setup card says when the count is one Settings set")
  click(win(), "10 steps")
  check(LevelingCodexDB.questPreview == 10 and seg("10 steps").codexOn, "the setup card can show 10 steps ahead")
  click(win(), "2 steps")
  check(LevelingCodexDB.questPreview == 2 and seg("2 steps").codexOn and not questText(frame, Q.label(ahead[8].step)),
    "and back to 2")
  click(win(), "Settings")
  local function stepsButton(label)
    for _, b in ipairs(MOCK.buttons(win())) do
      if labelOf(b) == label and b.tipText and b.tipText:find("steps the step window lists", 1, true) then return b end
    end
    check(false, "Settings has a '" .. label .. "' button for the steps shown ahead", 2)
  end
  LevelingCodexDB.questPreview = 9
  stepsButton("+"):Click()
  check(LevelingCodexDB.questPreview == 10, "Settings goes up to 10 steps ahead")
  stepsButton("+"):Click()
  check(LevelingCodexDB.questPreview == 10, "Settings stops at 10 steps ahead")
  stepsButton("-"):Click()
  check(LevelingCodexDB.questPreview == 9, "Settings can show fewer steps ahead")
end

-- Hostile elites and rares near the current step are named until you outlevel them.
function S.questDanger()
  S.login()
  local frame = questViewer()
  MOCK.ns.questDanger[1429] = { { "Test Brute", 3, 4, "elite", "", spots = { 90, 90, 48.3, 43.1 } },
    { "Friendly Guard", 3, 4, "elite", "A", spots = { 48.2, 43 } } }
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Watch out here: Elite Test Brute (3-4)."), "a hostile elite near the step is named")
  check(not questText(frame, "Friendly Guard"), "creatures friendly to you are left out")
  MOCK.level = 8
  MOCK.event("PLAYER_LEVEL_UP", 8)
  check(not questText(frame, "Watch out here"), "an elite you've outleveled is left out")
  MOCK.level = 1
  LevelingCodexDB.noDangerWarnings = true
  MOCK.event("PLAYER_LEVEL_UP", 1)
  check(not questText(frame, "Watch out here"), "the setting turns the warnings off")
end

-- Party distances count the steps your own route shows (not filtered, grey or cut) between your real
-- step and a member's: the first of yours at or past their position in the guide's data.
local function partySteps(theirPos)
  local Q = MOCK.ns.quests
  local steps = Q.rows()
  local mine, at = Q.routeRow()
  local function shown(r) return r.state ~= "filtered" and not r.grey and not r.cut end
  local n, i = 0, theirPos > mine.pos and at or at - 1
  while steps[i] and steps[i].section == mine.section
      and (theirPos > mine.pos and steps[i].pos < theirPos or theirPos < mine.pos and steps[i].pos >= theirPos) do
    if shown(steps[i]) then n = n + 1 end
    i = theirPos > mine.pos and i + 1 or i - 1
  end
  return math.max(1, n)
end

local function fromParty(name, text) MOCK.event("CHAT_MSG_ADDON", "LevCodex", text, "PARTY", name) end

local function addonCount(pattern)
  local n = 0
  for _, m in ipairs(MOCK.addonSent or {}) do if m.text:find(pattern) then n = n + 1 end end
  return n
end

-- In a party: your step goes out by addon message, others' steps show in the step window, and the
-- opt-in quest sharing and flight announcements.
function S.questParty()
  MOCK.party = true
  S.login()
  local frame = questViewer()
  MOCK.event("GROUP_ROSTER_UPDATE")
  local last = MOCK.addonSent and MOCK.addonSent[#MOCK.addonSent]
  check(MOCK.addonPrefix == "LevCodex" and last and last.channel == "PARTY", "the Codex talks to the party by addon message")
  local pos
  for _, m in ipairs(MOCK.addonSent) do pos = tonumber(m.text:match("^S;northshire;(%d+);Accept %- A Threat Within$")) or pos end
  check(pos, "the current step is told to the party")
  MOCK.event("CHAT_MSG_ADDON", "LevCodex", "S;northshire;40;Turn in - Bounty on Garrick Padfoot", "PARTY", "Ann-Realm")
  check(questText(frame, "Ann: Turn in - Bounty on Garrick Padfoot " .. partySteps(40) .. " ahead"),
    "a party member's step shows with how far ahead they are")
  MOCK.event("CHAT_MSG_ADDON", "LevCodex", "S;westfall;3;Accept - Westfall Stew", "PARTY", "Bo")
  check(questText(frame, "Bo: Accept - Westfall Stew Westfall"), "a member in another guide shows that guide")
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.advance(0.6)
  check(not MOCK.pushed, "the offer waits a moment, so a member who takes it at the same time isn't offered it")
  MOCK.advance(2)
  check(MOCK.pushed == 783, "a guide quest you accept is offered to the party (on by default)")
  LevelingCodexDB.questShareParty = false
  MOCK.pushed = nil
  MOCK.questLog = { { questID = 783 }, { questID = 7 } }
  MOCK.event("QUEST_ACCEPTED", 2, 7)
  MOCK.advance(2.6)
  check(not MOCK.pushed, "turned off, quest sharing stays off")
  LevelingCodexDB.questAnnounceFlights = true
  MOCK.taxiNodes = { { "Stormwind, Elwynn", "CURRENT" }, { "Lakeshire, Redridge", "REACHABLE" } }
  TakeTaxiNode(2)
  local said = MOCK.said and MOCK.said[#MOCK.said]
  check(said and said.text == "{rt6} Codex: Flying to: Lakeshire." and said.channel == "PARTY", "the flight is said in party chat")
  MOCK.party = false
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(not questText(frame, "Ann:"), "leaving the party clears the party's steps")
end

-- Party sync: one row per party member in the step window, with their level and where they are
-- against you (same step with their goal, N behind, N ahead, another guide, no step shared), and a
-- heading that says when everyone is on your step. Distances count the steps your own route shows
-- (questPartyCatchUp checks Back). The roster decides who shows.
function S.questPartySync()
  MOCK.party = true
  MOCK.partyMembers = { { name = "Ann", level = 5, class = "MAGE" }, { name = "Bo", realm = "Elsewhere", level = 4, class = "WARRIOR" } }
  S.login()
  local frame = questViewer()
  MOCK.event("GROUP_ROSTER_UPDATE")
  local function myPos()
    local pos
    for _, m in ipairs(MOCK.addonSent) do pos = tonumber(m.text:match("^S;northshire;(%d+);")) or pos end
    return pos
  end
  local pos = myPos()
  check(pos, "your step goes out")
  local goal
  for _, m in ipairs(MOCK.addonSent) do if m.text:find("^G;") then goal = m.text end end
  check(goal == "G;", "your goal goes out with it (none on an accept step)")
  check(questText(frame, "Ann (5) no step shared") and questText(frame, "Bo (4) no step shared"),
    "party members who haven't shared a step show with their level")
  fromParty("Ann-Realm", "S;northshire;" .. pos .. ";Accept - A Threat Within")
  fromParty("Ann-Realm", "G;Kobold Vermin slain: 3/10")
  check(questText(frame, "Ann (5): Kobold Vermin slain: 3/10 same step"), "a member on your step shows their goal")
  check(questText(frame, "PARTY") and not questText(frame, "ALL ON THIS STEP"), "not everyone is on your step yet")
  fromParty("Bo-Elsewhere", "S;northshire;" .. pos .. ";Accept - A Threat Within")
  check(questText(frame, "PARTY - ALL ON THIS STEP"), "the heading says when everyone is on your step")
  -- a step of another class (in the guide's data, not in your route) counts from the next one you have
  local Q = MOCK.ns.quests
  local steps = Q.rows()
  local mine, at = Q.routeRow()
  local gap
  for k = at, #steps - 1 do
    if steps[k + 1].section ~= mine.section then break end
    if steps[k + 1].pos > steps[k].pos + 1 then gap = k; break end
  end
  check(gap, "Northshire has another class's step after yours")
  local theirs = steps[gap].pos + 1
  fromParty("Ann-Realm", "S;northshire;" .. theirs .. ";Accept - Another class's quest")
  check(questText(frame, "Ann (5): Accept - Another class's quest " .. partySteps(theirs) .. " ahead"),
    "a member on a step your route doesn't have counts from the next one you do")
  local past = steps[gap + 1].pos
  check(partySteps(past) < past - pos, "past it, the guide's data has more steps than your route shows")
  fromParty("Ann-Realm", "S;northshire;" .. past .. ";Turn in - Something")
  check(questText(frame, "Ann (5): Turn in - Something " .. partySteps(past) .. " ahead"),
    "a member ahead of you, counted in the steps your route shows")
  check(not questText(frame, "ALL ON THIS STEP"), "the heading follows")
  click(frame, "Next")
  click(frame, "Next")
  MOCK.advance(2.5)
  local now = myPos()
  check(now and now > pos, "your new step goes out after Next")
  check(questText(frame, "Bo (4): Accept - A Threat Within " .. partySteps(pos) .. " behind"), "a member behind you")
  fromParty("Bo-Elsewhere", "S;westfall;3;Accept - Westfall Stew")
  check(questText(frame, "Bo (4): Accept - Westfall Stew Westfall"), "a member in another guide shows that guide")
  MOCK.partyMembers = { MOCK.partyMembers[1] }
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(questText(frame, "Ann (5)") and not questText(frame, "Bo (4)"), "a member who left the party is gone")
  MOCK.raid = true
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(not questText(frame, "Ann (5)"), "nothing in a raid")
end

-- Keeping in touch: your step goes out again every minute; a member whose Codex goes quiet for
-- 3 minutes drops out (an older Codex, which sends no goals or heartbeat, keeps its step 15 minutes);
-- offline and dead members are marked; the party is asked for its steps only when someone new joins.
function S.questPartyHeartbeat()
  MOCK.party = true
  MOCK.partyMembers = { { name = "Ann", level = 5 }, { name = "Bo", level = 4 } }
  S.login()
  local frame = questViewer()
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(addonCount("^HELLO$") == 1, "joining asks the party for their steps")
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(addonCount("^HELLO$") == 1, "a roster update with the same people asks nothing")
  local pos = MOCK.ns.quests.routeRow().pos
  fromParty("Ann", "S;northshire;" .. pos .. ";Accept - A Threat Within")
  fromParty("Ann", "G;")
  fromParty("Bo", "S;northshire;" .. pos .. ";Accept - A Threat Within")
  local before = addonCount("^S;")
  MOCK.advance(65, 0.5)
  check(addonCount("^S;") > before, "your step goes out again every minute")
  check(questText(frame, "Ann (5): Accept - A Threat Within same step"), "Ann still shows a minute later")
  MOCK.advance(130, 0.5)
  check(questText(frame, "Ann (5) no step shared"), "a Codex that goes quiet for 3 minutes drops out")
  check(questText(frame, "Bo (4): Accept - A Threat Within same step"), "an older Codex keeps its step for 15 minutes")
  MOCK.partyMembers[2].offline = true
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(questText(frame, "Bo (4): Accept - A Threat Within offline"), "an offline member is marked")
  MOCK.partyMembers[2].offline, MOCK.partyMembers[2].dead = false, true
  MOCK.advance(5.5, 0.5)
  check(questText(frame, "Bo (4): Accept - A Threat Within same step (dead)"), "and a dead one, within 5 s")
  check(addonCount("^HELLO$") == 1, "nobody new yet")
  table.insert(MOCK.partyMembers, { name = "Cy", level = 6 })
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(addonCount("^HELLO$") == 2, "someone new joining asks again")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("party member Bo: older Codex"), "debug lists each member")
end

-- Quests > Party: each member with their guide, step, live goal and when you last heard from them;
-- Follow <name>'s guide when they're in another guide; the quests they have that you don't (Ask to
-- share) and the reverse (Share); the party switches.
function S.questPartyTab()
  MOCK.party = true
  MOCK.partyMembers = { { name = "Ann", level = 5, class = "MAGE" }, { name = "Bo", level = 4, class = "WARRIOR" } }
  MOCK.questLog = { { questID = 783, title = "A Threat Within" } }
  S.login()
  MOCK.event("GROUP_ROSTER_UPDATE")
  fromParty("Ann", "S;westfall;3;Accept - Westfall Stew")
  fromParty("Ann", "G;")
  fromParty("Ann", "L;7,33,783")
  slash("quests")
  click(win(), "Party")
  check(findButton(win(), function(l) return l == "Party member: Ann" end) and findButton(win(), function(l) return l == "Party member: Bo" end), "the Party board has one panel per member")
  click(win(), "Party member: Bo")
  check(questText(win(), "Bo (4) Warrior") and questText(win(), "Bo needs the Leveling Codex to share a step"), "a member without the Codex has a detail panel")
  click(win(), "Back to party"); click(win(), "Party member: Ann")
  check(questText(win(), "Ann (5) Mage"), "the member detail shows level and class")
  check(questText(win(), "Westfall: Accept - Westfall Stew"), "with their guide and step")
  check(questText(win(), "heard just now"), "and when you last heard from them")
  check(questText(win(), "Ann has, you don't (2)"), "the quests Ann has that you don't")
  click(win(), "Ask Ann to share Wolves Across the Border")
  check(addonCount("^R;33;Ann$") == 1, "asking sends Ann's Codex a share request")
  check(not questText(win(), "You have, Ann doesn't"), "Ann has everything you have")
  fromParty("Ann", "L;7,33")
  check(questText(win(), "You have, Ann doesn't (1)"), "the reverse")
  click(win(), "Share A Threat Within")
  check(MOCK.pushed == 783, "Share offers your quest to the party")
  click(win(), "Follow Ann's guide")
  check(MOCK.ns.quests.current().section.id == "westfall", "following switches your guide to Ann's")
  click(win(), "Party")
  check(not findButton(win(), function(l) return l == "Follow Ann's guide" end), "no Follow once you're in the same guide")
  click(win(), "Party settings"); click(win(), "Quest items")
  check(LevelingCodexDB.questAnnounceItems, "the party switches are in the tab too")
  MOCK.party = false
  MOCK.event("GROUP_ROSTER_UPDATE")
  click(win(), "Party")
  check(questText(win(), "You're not in a party"), "out of a party the tab says so")
end

-- Share requests: a member's Ask to share offers them your quest (once per 10 s); one the game won't
-- share says so to them; auto-share waits 2.5 s and leaves out a quest every member already has.
function S.questPartyShare()
  MOCK.party = true
  MOCK.partyMembers = { { name = "Ann", level = 5 } }
  MOCK.questLog = { { questID = 783, title = "A Threat Within" } }
  S.login()
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(addonCount("^L;783$") >= 1, "your quest log goes out")
  fromParty("Ann", "R;783;Tester")
  check(MOCK.pushed == 783 and chatHas("Ann asked for A Threat Within"), "a share request from a party member")
  MOCK.pushed = nil
  fromParty("Ann", "R;783;Tester")
  check(not MOCK.pushed, "once per 10 s")
  MOCK.advance(11)
  fromParty("Ann", "R;783;Someone")
  check(not MOCK.pushed, "a request for someone else")
  MOCK.notPushable = { [783] = true }
  fromParty("Ann", "R;783;Tester")
  check(not MOCK.pushed and addonCount("^N;783;Ann$") == 1, "a quest the game won't share says so")
  fromParty("Ann", "N;33;Tester")
  check(chatHas("Ann can't share Wolves Across the Border"), "and the asker hears it")
  MOCK.notPushable = nil
  LevelingCodexDB.questShareParty = true
  fromParty("Ann", "S;northshire;1;Accept - A Threat Within")
  fromParty("Ann", "G;")
  fromParty("Ann", "L;33,783")
  table.insert(MOCK.questLog, { questID = 33, title = "Wolves Across the Border" })
  MOCK.event("QUEST_ACCEPTED", 2, 33)
  MOCK.advance(2.6)
  check(not MOCK.pushed, "auto-share leaves out a quest every member already has")
  table.insert(MOCK.questLog, { questID = 7, title = "Kobold Camp Cleanup" })
  MOCK.event("QUEST_ACCEPTED", 3, 7)
  MOCK.advance(2.6)
  check(MOCK.pushed == 7, "and offers one a member lacks")
end

-- Party chat announcements (Settings > Party, each off by default, said as "Codex: ..."): quest
-- items you pick up (each new count; a route item that starts a quest) and quest progress (an
-- objective finished, a quest ready to turn in). Nothing for what's in your log at login, at most a
-- line a second (a newer count of the same item replaces a waiting one), nothing in a raid, and
-- what quest tracker already says in party chat is left to it.
function S.questPartyChat()
  MOCK.party = true
  local function goal(text, kind, have, need)
    return { text = text .. ": " .. have .. "/" .. need, type = kind, numFulfilled = have, numRequired = need,
      finished = have >= need }
  end
  local meat = goal("Tough Wolf Meat", "item", 2, 8)
  local vermin, worker = goal("Kobold Vermin slain", "monster", 9, 10), goal("Kobold Worker slain", "monster", 0, 10)
  MOCK.questLog = { { questID = 33, title = "Wolves Across the Border", objectives = { meat } },
    { questID = 7, title = "Kobold Camp Cleanup", objectives = { vermin, worker } } }
  S.login()
  MOCK.advance(5) -- the quest log can fill in over the first seconds: nothing is said for it
  MOCK.event("GROUP_ROSTER_UPDATE")
  local function hints()
    local n = 0
    for _, line in ipairs(MOCK.chat) do if line:find("Settings > Party", 1, true) then n = n + 1 end end
    return n
  end
  check(hints() == 1, "joining a party says once where the chat announcements are")
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(hints() == 1, "only once a session")
  local function set(obj, have)
    obj.numFulfilled, obj.finished = have, have >= obj.numRequired
    obj.text = obj.text:gsub("%d+/", have .. "/")
    MOCK.event("QUEST_LOG_UPDATE")
  end
  local function said(text)
    local n = 0
    for _, m in ipairs(MOCK.said or {}) do if m.channel == "PARTY" and m.text == text then n = n + 1 end end
    return n
  end
  set(meat, 3)
  check(not MOCK.said, "announcements are off by default")
  slash("quests")
  click(win(), "Settings")
  click(win(), "Say quest items I pick up")
  click(win(), "Say quest progress in party chat")
  check(LevelingCodexDB.questAnnounceItems and LevelingCodexDB.questAnnounceProgress, "Settings turns them on")
  check(not MOCK.said, "nothing for what was already in your log")
  set(meat, 4)
  check(said("{rt6} Codex: Loot: Tough Wolf Meat: 4/8 - [Wolves Across the Border]") == 1, "a quest item you pick up is said in party chat")
  set(meat, 5)
  set(meat, 6)
  check(#MOCK.said == 1, "a line a second at most")
  MOCK.advance(1.1)
  check(#MOCK.said == 2 and said("{rt6} Codex: Loot: Tough Wolf Meat: 6/8 - [Wolves Across the Border]") == 1,
    "a newer count replaces the waiting one")
  set(worker, 5)
  MOCK.advance(1.1)
  check(#MOCK.said == 2, "kills are said when the objective is finished, not each one")
  set(vermin, 10)
  MOCK.advance(1.1)
  check(said("{rt6} Codex: Objective complete: Kobold Vermin slain: 10/10 - [Kobold Camp Cleanup]") == 1, "a finished objective")
  set(worker, 10)
  MOCK.advance(1.1)
  check(said("{rt6} Codex: Ready to turn in: [Kobold Camp Cleanup]") == 1
    and said("{rt6} Codex: Objective complete: Kobold Worker slain: 10/10 - [Kobold Camp Cleanup]") == 0, "the last objective says the quest is ready instead")
  MOCK.bagItems = { { id = 1307, name = "Gold Pickup Schedule", level = 1, quality = 1 } }
  MOCK.bags[1307] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  MOCK.advance(1.1)
  check(said("{rt6} Codex: Found quest item: [Gold Pickup Schedule] - starts [The Collector]") == 1, "a route item that starts a quest")
  -- quest tracker says finished objectives and quest-starting items itself: the Codex leaves those to it.
  MOCK.makeQuestProvider({ announce = { channel = "party", objectives = true, items = true } })
  MOCK.bags[1307] = 0
  MOCK.event("BAG_UPDATE_DELAYED")
  MOCK.bags[1307] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  local bandana, thug = goal("Red Burlap Bandana", "item", 5, 12), goal("Defias Thug slain", "monster", 9, 10)
  table.insert(MOCK.questLog, { questID = 18, title = "Brotherhood of Thieves", objectives = { bandana, thug } })
  MOCK.event("QUEST_LOG_UPDATE")
  set(thug, 10)
  MOCK.advance(1.1)
  set(bandana, 6)
  MOCK.advance(1.1)
  check(said("{rt6} Codex: Found quest item: [Gold Pickup Schedule] - starts [The Collector]") == 1
    and said("{rt6} Codex: Objective complete: Defias Thug slain: 10/10 - [Brotherhood of Thieves]") == 0, "what quest tracker says is left to it")
  check(said("{rt6} Codex: Loot: Red Burlap Bandana: 6/12 - [Brotherhood of Thieves]") == 1, "item counts still go out")
  click(win(), "Settings")
  check(questText(win(), "avoids repeating them"), "Settings explains duplicate announcement suppression")
  MOCK.raid = true
  set(bandana, 7)
  MOCK.advance(1.1)
  check(said("{rt6} Codex: Loot: Red Burlap Bandana: 7/12 - [Brotherhood of Thieves]") == 0, "nothing in a raid")
end

-- Settings > Say steps I finish in party chat: a step the game finished (not Next or Back) goes out
-- as "Codex: Done - <step>".
function S.questPartyChatSteps()
  MOCK.party = true
  S.login()
  MOCK.advance(5)
  LevelingCodexDB.questAnnounceSteps = true
  local frame = questViewer()
  MOCK.event("GROUP_ROSTER_UPDATE")
  check(not chatHas("Settings > Party"), "no hint once an announcement is on")
  MOCK.questLog = { { questID = 783, title = "A Threat Within" } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  MOCK.event("QUEST_LOG_UPDATE")
  local last = MOCK.said and MOCK.said[#MOCK.said]
  check(last and last.text == "{rt6} Codex: Accepted: [A Threat Within]" and last.channel == "PARTY", "a step the game finished is said")
  MOCK.advance(1.1)
  MOCK.questLog = {}
  MOCK.questDone[783] = true
  MOCK.event("QUEST_TURNED_IN", 783, 100, 0)
  MOCK.event("QUEST_LOG_UPDATE")
  last = MOCK.said[#MOCK.said]
  check(last.text == "{rt6} Codex: Turned in: [A Threat Within]", "and the next one")
  local n = #MOCK.said
  MOCK.advance(1.1)
  click(frame, "Next")
  MOCK.advance(1.1)
  check(#MOCK.said == n, "Next isn't a finished step")
end

function S.questPartyPolishedChat()
  MOCK.party = true
  MOCK.questLinks = { [783] = "|cffffff00|Hquest:783:1|h[A Threat Within]|h|r" }
  S.login()
  MOCK.advance(5)
  LevelingCodexDB.questAnnounceSteps = true
  MOCK.questLog = { { questID = 783, title = "A Threat Within" } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  local line = MOCK.said and MOCK.said[#MOCK.said]
  check(line and line.text:find("{rt6} Codex: Accepted:", 1, true), "accepted quests have a recognizable marker and status")
  check(line.text:find("|Hquest:783:1|h[A Threat Within]|h", 1, true), "party announcements preserve the native clickable quest link")
  check(not line.text:find("|T", 1, true), "party transport contains no custom texture escapes")
  local filter = MOCK.chatFilters and MOCK.chatFilters.CHAT_MSG_PARTY
  check(filter, "party chat has a local visual filter")
  local blocked, display, author, language = filter(nil, "CHAT_MSG_PARTY", line.text, "Ann", "enUS")
  check(blocked == false and author == "Ann" and language == "enUS", "visual formatting preserves the chat sender and metadata")
  check(display:find("|T", 1, true) and display:find("|cff", 1, true), "Codex clients render a badge and colored status")
  check(display:find("|TInterface\\GossipFrame\\AvailableQuestIcon:14:14|t", 1, true),
    "status icons retain their full Blizzard texture path")
  check(display:find("|Hquest:783:1|h[A Threat Within]|h", 1, true), "visual filter preserves quest links")
  check(filter(nil, "CHAT_MSG_PARTY", "A normal party message", "Ann") == nil, "other party messages are untouched")
  MOCK.advance(1.1)
  MOCK.questLinks[783], MOCK.questLog, MOCK.questDone[783] = nil, {}, true
  MOCK.event("QUEST_TURNED_IN", 783)
  local turnedIn = MOCK.said[#MOCK.said].text
  check(turnedIn:find("Turned in:", 1, true) and turnedIn:find("|Hquest:783:1|h", 1, true),
    "turn-in announcements retain the known native link after the quest leaves the log")
  local _, finished = filter(nil, "CHAT_MSG_PARTY", turnedIn, "Ann")
  check(finished:find("ReadyCheck-Ready", 1, true), "turned-in quests use a completion check rather than a ready question mark")
end

function S.questPartyAnnouncementPreview()
  S.login()
  slash("")
  click(win(), "Settings")
  local before = #MOCK.chat
  click(win(), "Preview quest announcements")
  check(not MOCK.said, "preview never sends a party message")
  check(#MOCK.chat >= before + 5, "preview shows several announcement states privately")
  check(chatHas("|T"), "private previews use the same graphical presentation")
  slash("quests")
  click(win(), "Party")
  click(win(), "Preview quest announcements")
  check(not MOCK.said, "Party tab preview is also private while solo")
end

function S.questPartyAnnouncementBudget()
  MOCK.party = true
  MOCK.questLinks = { [783] = "|cffffff00|Hquest:783:1" .. string.rep(":0", 150)
    .. "|h[" .. string.rep("Long quest title ", 30) .. "]|h|r" }
  S.login()
  MOCK.advance(5)
  LevelingCodexDB.questAnnounceSteps = true
  MOCK.questLog = { { questID = 783, title = string.rep("Long quest title ", 30) } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  local line = MOCK.said and MOCK.said[#MOCK.said]
  check(line and #line.text <= 255, "long announcements fit the chat byte limit")
  check(line.text:find("{rt6} Codex: Accepted:", 1, true), "long messages retain their status and marker")
  if line.text:find("|H", 1, true) then
    check(line.text:match("|Hquest:[^|]+|h%b[]|h"), "length limiting never cuts a native link in half")
  end
end

function S.questPartyProviderAnnounce()
  MOCK.party = true
  MOCK.makeQuestProvider({ announce = { channel = "party", objectives = true, items = true } })
  Questie.db.profile.questAnnounceAccepted = true
  Questie.db.profile.questAnnounceCompleted = true
  S.login()
  MOCK.advance(5)
  LevelingCodexDB.questAnnounceSteps = true
  MOCK.questLog = { { questID = 783, title = "A Threat Within" } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  check(not MOCK.said, "quest tracker handles its enabled accepted-quest announcement")
  MOCK.advance(1.1)
  MOCK.questLog, MOCK.questDone[783] = {}, true
  MOCK.event("QUEST_TURNED_IN", 783)
  check(not MOCK.said, "quest tracker handles its enabled quest turn-in announcement")
end

-- Trips through flight masters (QuestTravel.lua): the arrow leads to a flight master when flying
-- is quicker, the flight map marks the flight (travel automation takes it), a flight path you
-- don't have close to the way is learned on the way, and Quests > Nearest flight master.
local function redridgeBrutes(x, y)
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Skyborne", 19, 1433, 32.5, 31.5
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "lakeshire" then
      for _, step in ipairs(section.steps) do
        if step.quest == 124 then break end
        if step.type == "accept" then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 124, objectives = { { text = "Redridge Brutes 4/10" } } } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  check(questText(questViewer(), "Redridge Brutes 4/10"), "following the Redridge objective")
  MOCK.questX, MOCK.questY = x or 32.5, y or 31.5
  MOCK.advance(0.3)
end

-- Party sync sends your step's live goal ("G;Redridge Brutes 4/10") with your step, and a new count
-- within 2 s. With every announcement on, a kill step whose quest is just ready says "ready to turn
-- in" once, not "Done" as well.
function S.questPartyGoal()
  MOCK.party = true
  redridgeBrutes()
  MOCK.advance(5)
  MOCK.event("GROUP_ROSTER_UPDATE")
  local function sent(text)
    for _, m in ipairs(MOCK.addonSent or {}) do if m.text == text then return true end end
    return false
  end
  check(sent("G;Redridge Brutes 4/10"), "your step's goal goes out to the party")
  LevelingCodexDB.questAnnounceSteps, LevelingCodexDB.questAnnounceItems = true, true
  LevelingCodexDB.questAnnounceProgress = true
  MOCK.questLog[1].objectives[1].text = "Redridge Brutes 5/10"
  MOCK.event("QUEST_LOG_UPDATE")
  check(not sent("G;Redridge Brutes 5/10"), "at most every 2 s")
  MOCK.advance(2.1)
  check(sent("G;Redridge Brutes 5/10"), "a new count goes out once the 2 s are up")
  check(not MOCK.said, "a kill that doesn't finish the objective isn't said")
  MOCK.questLog[1].objectives[1] = { text = "Redridge Brutes 10/10", finished = true }
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(1.1)
  local lines = {}
  for _, m in ipairs(MOCK.said or {}) do lines[#lines + 1] = m.text end
  check(#lines == 1 and lines[1] == "{rt6} Codex: Ready to turn in: [A Baying of Gnolls]",
    "one line for the finished kill step: " .. table.concat(lines, " | "))
end

-- Catch-up cues: a note when a member is 3 or more steps behind you, a ping when the last member
-- reaches your step (Settings: Ping when the party is together on my step, at most every 20 s; a
-- soft chime on the Sound Effects channel by default, Settings > Ping sound picks another and plays
-- it), and the compact step window's one-line party summary.
function S.questPartyCatchUp()
  MOCK.party = true
  MOCK.partyMembers = { { name = "Ann", level = 19 }, { name = "Bo", level = 18 } }
  redridgeBrutes()
  local frame = questViewer()
  MOCK.event("GROUP_ROSTER_UPDATE")
  MOCK.advance(6)
  MOCK.sounds = {}
  local function pings(id)
    local n = 0
    for _, s in ipairs(MOCK.sounds) do if s.id == (id or 18019) and s.channel == "SFX" then n = n + 1 end end
    return n
  end
  local Q = MOCK.ns.quests
  local steps = Q.rows()
  local mine, at = Q.routeRow()
  local here, section = mine.pos, mine.section.id
  -- a place four of your steps back
  local n, i = 0, at
  while n < 4 do
    i = i - 1
    local r = steps[i]
    if r.state ~= "filtered" and not r.grey and not r.cut then n = n + 1 end
  end
  check(steps[i].section == mine.section, "the Redridge step has four steps before it")
  local back = steps[i].pos
  local function to(name, p)
    fromParty(name, "S;" .. section .. ";" .. p .. ";Somewhere")
    fromParty(name, "G;")
  end
  to("Ann", here)
  check(pings() == 0, "one member on your step isn't the whole party")
  to("Bo", back)
  check(questText(frame, "Bo is " .. partySteps(back) .. " steps behind you."), "a member 3+ steps behind is named")
  check(pings() == 0, "no ping while someone is behind")
  to("Bo", here)
  check(pings() == 1 and not questText(frame, "steps behind you"),
    "the last member reaching your step pings: a soft chime your Sound Effects volume sets")
  check(pings(8960) == 0, "not the ready-check sound")
  LevelingCodexDB.questCompact = true
  MOCK.ns.questRefresh()
  check(questText(frame, "Party: all on this step"), "the compact window's party line")
  LevelingCodexDB.questCompact = false
  to("Bo", back)
  to("Bo", here)
  check(pings() == 1, "at most a ping every 20 s")
  to("Bo", back)
  MOCK.advance(21)
  to("Bo", here)
  check(pings() == 2, "and again after that")
  to("Bo", back)
  MOCK.advance(21)
  LevelingCodexDB.noPartyPing = true
  to("Bo", here)
  check(pings() == 2, "the ping can be turned off")
  -- Back shows the step before (done), but the party keeps hearing where you really are
  local function lastStep()
    local text
    for _, m in ipairs(MOCK.addonSent) do if m.text:find("^S;") then text = m.text end end
    return text and tonumber(text:match("^S;[^;]*;(%d+);"))
  end
  click(frame, "Back")
  MOCK.advance(2.5)
  check(Q.current() ~= Q.routeRow(), "Back shows an earlier step")
  check(lastStep() == here, "going Back to look doesn't tell the party you're behind")
  check(questText(frame, "Ann (19): Somewhere same step"), "and the rows still measure from your real step")
  -- Settings > Ping sound: picking one plays it, and the next ping uses it
  slash("quests")
  click(win(), "Settings")
  local count = #MOCK.sounds
  click(win(), "Party invite")
  check(LevelingCodexDB.partyPingSound == 2 and #MOCK.sounds == count + 1 and pings(880) == 1,
    "picking a ping sound plays it so you can hear it")
  LevelingCodexDB.noPartyPing = false
  to("Bo", back)
  MOCK.advance(21)
  to("Bo", here)
  check(pings(880) == 2, "the next ping uses it")
end

local function arrowCaption()
  local caption = ""
  for _, r in ipairs({ LevelingCodexQuestArrow:GetRegions() }) do
    if r._text and r:IsShown() then caption = caption .. r._text end
  end
  return caption
end

local function arrowSays(text) return arrowCaption():find(text, 1, true) ~= nil end

local function taxiMap(nodes)
  MOCK.taxiNodes = nodes
  if not _G.TaxiFrame then
    local frame = CreateFrame("Frame", "TaxiFrame", UIParent)
    for i = 1, 4 do CreateFrame("Button", "TaxiButton" .. i, frame) end
  end
  TaxiFrame:Show()
  MOCK.event("TAXIMAP_OPENED")
end

local function walkTo(map, x, y)
  local zone = map ~= MOCK.questMap
  MOCK.questMap, MOCK.questX, MOCK.questY = map, x, y
  if zone then MOCK.event("ZONE_CHANGED_NEW_AREA") end
  MOCK.advance(0.3)
end

function S.questFlightPlan()
  redridgeBrutes()
  walkTo(1436, 56.0, 50.0) -- Westfall, 66 yd from the Sentinel Hill flight master
  check(not arrowSays("Fly to"), "no trip is planned before the guide knows your flight paths: " .. arrowCaption())

  -- A flight map in Stormwind said what you have: Lakeshire, not Sentinel Hill.
  taxiMap({ { "Stormwind, Elwynn", "CURRENT" }, { "Lakeshire, Redridge", "REACHABLE" } })
  TaxiFrame:Hide()
  walkTo(1436, 56.0, 50.0)
  check(arrowSays("Learn the Sentinel Hill flight path, then fly to Lakeshire") and arrowSays(" yd"),
    "a flight master you haven't talked to starts the trip: " .. arrowCaption())
  walkTo(1436, 56.6, 52.7)
  check(arrowSays("Learn this flight path, then fly to Lakeshire"), "at that flight master: learn it, then fly")

  taxiMap({ { "Sentinel Hill, Westfall", "CURRENT" }, { "Stormwind, Elwynn", "REACHABLE" },
    { "Lakeshire, Redridge", "REACHABLE" } })
  local mark = _G.LevelingCodexTaxiMark
  check(mark and mark:IsShown() and questText(mark, "fly to Lakeshire"), "the flight map names the guide's flight")
  local glow = _G.LevelingCodexTaxiGlow
  check(glow, "the flight map has the Codex's light")
  local _, onto = glow:GetPoint(1)
  check(glow:IsShown() and onto == _G.TaxiButton3, "the guide's flight master lights up on the map")
  check(not glow:IsMouseEnabled(), "the light lets the click through to the flight master")
  -- Its ring pulses from the clock, like the arrival bob: no jump where it turns (an Alpha looping
  -- BOUNCE could step there in game).
  local low, high, jump, last = math.huge, -math.huge, 0, glow.ring:GetAlpha() or 1
  for _ = 1, 240 do -- 4 s at 60 fps
    MOCK.advance(1 / 60, 1 / 60)
    local a = glow.ring:GetAlpha() or 1
    low, high, jump, last = math.min(low, a), math.max(high, a), math.max(jump, math.abs(a - last)), a
  end
  check(low < 0.4 and high > 0.95 and jump < 0.05,
    "the ring pulses smoothly (" .. low .. " to " .. high .. ", biggest step " .. jump .. ")")
  check(MOCK.tookTaxi == nil, "the flight is only marked while travel automation is off")
  TaxiFrame:Hide()
  walkTo(1436, 56.0, 50.0)
  check(arrowSays("Fly to Lakeshire from Sentinel Hill") and arrowSays(" yd"),
    "a long trip leads to the flight master with its distance: " .. arrowCaption())
  local mini = _G.LevelingCodexMinimapPins
  check(mini and mini:IsShown() and mini.current:IsShown() and mini.current.icon
    and mini.current.icon._atlas == "crosshair_taxi_32", "the minimap leads to the flight master too")
  -- Reported from the game: Forever hides your speed from addons at times (a secret value), and
  -- math on it was blocked 374 times. The trip is planned at walking speed then.
  MOCK.runSpeed = MOCK.SECRET
  walkTo(1436, 55.0, 49.0)
  check(arrowSays("Fly to Lakeshire from Sentinel Hill"), "a secret run speed still plans the trip: " .. arrowCaption())
  MOCK.runSpeed = nil
  walkTo(1436, 56.6, 52.7)
  check(arrowSays("Fly to Lakeshire: talk to the flight master"), "at the flight master the arrow says where to fly")

  LevelingCodexDB.questAutoTravel = true
  MOCK.gossipOptions = { { gossipOptionID = 7, name = "I want to browse your goods." },
    { gossipOptionID = 8, name = "Show me where I can fly." } }
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == 8, "travel automation opens the flight map at the trip's flight master")
  taxiMap(MOCK.taxiNodes)
  check(MOCK.tookTaxi == 3 and chatHas("flying to Lakeshire"), "travel automation takes the trip's flight")
  TaxiFrame:Hide()
  LevelingCodexDB.questAutoTravel = nil
  MOCK.tookTaxi = nil

  LevelingCodexDB.noFlightPlans = true
  walkTo(1436, 56.0, 50.0)
  check(not arrowSays("from Sentinel Hill"), "Plan trips through flight masters off: no trip")
  LevelingCodexDB.noFlightPlans = nil

  -- Quests > Nearest flight master, and back.
  slash("quests")
  click(win(), "Nearest flight master")
  MOCK.advance(0.3)
  check(arrowSays("Nearest flight master: Sentinel Hill") and arrowSays(" yd") and chatHas("Sentinel Hill flight master"),
    "the arrow points to the nearest flight master: " .. arrowCaption())
  click(win(), "Back to the step")
  MOCK.advance(0.3)
  check(not arrowSays("Nearest flight master"), "pressing it again returns the arrow to the step")
end

function S.questFlightLearn()
  redridgeBrutes(27, 55) -- 69 yd from the Lakeshire flight master, 377 yd from the brutes
  check(arrowSays(" yd") and not arrowSays("Learn"), "nothing to learn before the guide knows your flight paths")
  taxiMap({ { "Stormwind, Elwynn", "CURRENT" }, { "Sentinel Hill, Westfall", "REACHABLE" } })
  check(not (_G.LevelingCodexTaxiMark and LevelingCodexTaxiMark:IsShown()), "no flight is marked when walking is quicker")
  TaxiFrame:Hide()
  MOCK.advance(0.3)
  check(arrowSays("Learn the Lakeshire flight path on the way") and arrowSays(" yd"),
    "a flight path you don't have close to the way is learned first: " .. arrowCaption())
  LevelingCodexDB.noFlightLearn = true
  MOCK.advance(0.3)
  check(not arrowSays("Learn"), "Lead me to flight paths I don't have off: straight to the step")
  LevelingCodexDB.noFlightLearn = nil
  taxiMap({ { "Lakeshire, Redridge", "CURRENT" }, { "Stormwind, Elwynn", "REACHABLE" } })
  TaxiFrame:Hide()
  MOCK.advance(0.3)
  check(not arrowSays("Learn") and arrowSays(" yd"), "once learned the arrow goes on to the step: " .. arrowCaption())
  slash("debug")
  check(chatHas("travel: %d+ flight points for your faction"), "the debug output reports travel planning")
end

-- Reported from the game: at the Ironforge flight master the arrow said "Fly to Menethil Harbor"
-- (the Wetlands' flight hub), but the flight map marked nothing and travel automation didn't fly.
-- The trip planner measured the walk to Ironbeard's Tomb as a straight line over the mountains and
-- chose walking, and the flight map only asked the planner.
function S.questFlightHub()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Dwarf", 24, 1455, 55.6, 47.9
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.quest == 470 then break end
        if step.type == "accept" then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 470, objectives = { { text = "Sida's Bag: 0/1" } } } }
  S.login()
  local nodes = { { "Ironforge, Dun Morogh", "CURRENT" }, { "Menethil Harbor, Wetlands", "REACHABLE" },
    { "Thelsamar, Loch Modan", "REACHABLE" } }
  taxiMap(nodes)
  TaxiFrame:Hide()
  slash("quests")
  stepTool("Resume active quest")
  MOCK.advance(0.3)
  check(questText(questViewer(), "Digging Through the Ooze"), "following the ooze in the Wetlands")
  check(arrowSays("Fly to Menethil Harbor"), "the arrow sends you to Menethil Harbor: " .. arrowCaption())
  taxiMap(nodes)
  local mark, glow = _G.LevelingCodexTaxiMark, _G.LevelingCodexTaxiGlow
  check(mark and mark:IsShown() and questText(mark, "fly to Menethil Harbor"),
    "the flight map names the flight the arrow asked for")
  check(glow, "the flight map has the Codex's light")
  local _, onto = glow:GetPoint(1)
  check(glow:IsShown() and onto == _G.TaxiButton2, "Menethil Harbor lights up on the flight map")
  check(MOCK.tookTaxi == nil, "the flight is only marked while travel automation is off")
  TaxiFrame:Hide()
  LevelingCodexDB.questAutoTravel = true
  MOCK.gossipOptions = { { gossipOptionID = 7, name = "I want to browse your goods." },
    { gossipOptionID = 8, name = "Show me where I can fly." } }
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == 8, "travel automation opens the flight map at the hub's flight master")
  taxiMap(nodes)
  check(MOCK.tookTaxi == 2 and chatHas("flying to Menethil Harbor"), "travel automation takes the hub's flight")
  TaxiFrame:Hide()
end

-- Reported from the game: in Darkshire the arrow sent you to Sentinel Hill for Sven's Camp (on the
-- Duskwood-Westfall border), and once you landed it said "Fly to Darkshire": the trip planner chose
-- walking from Sentinel Hill, and the zone-hub fallback flew you back to a hub farther from the step.
function S.questFlightBack()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 26, 1431, 77.4, 44.3
  local open = {}
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "duskwood" then
      for _, step in ipairs(section.steps) do
        if step.type == "goto" and step.text and step.text:find("Sven's Camp", 1, true) then break end
        if step.type == "accept" and step.quest then open[step.quest] = true end
        if step.type == "turnin" and step.quest then open[step.quest] = nil; MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = {}
  for id in pairs(open) do MOCK.questLog[#MOCK.questLog + 1] = { questID = id, isComplete = id == 230 } end
  S.login()
  local nodes = { { "Darkshire, Duskwood", "CURRENT" }, { "Sentinel Hill, Westfall", "REACHABLE" },
    { "Stormwind, Elwynn", "REACHABLE" } }
  taxiMap(nodes)
  TaxiFrame:Hide()
  slash("quests")
  stepTool("Resume active quest")
  MOCK.advance(0.3)
  check(questText(questViewer(), "Sven"), "following the way to Sven's Camp")
  -- Walked into Westfall: the hub flight still offers Darkshire (mountains can block a straight walk).
  walkTo(1436, 56.0, 50.0)
  check(arrowSays("Fly to Darkshire"), "walking in, the zone hub's flight is offered: " .. arrowCaption())
  walkTo(1431, 77.4, 44.3)
  taxiMap(nodes)
  TakeTaxiNode(2)
  TaxiFrame:Hide()
  MOCK.onTaxi = true
  MOCK.advance(1)
  MOCK.onTaxi = false
  walkTo(1436, 56.6, 52.7) -- landed at Sentinel Hill
  check(questText(questViewer(), "Sven"), "still on the way to Sven's Camp")
  check(not arrowSays("Fly to"), "after landing the arrow doesn't fly you back: " .. arrowCaption())
  check(arrowSays(" yd"), "it leads on to Sven's Camp with its distance: " .. arrowCaption())
end

function S.questFlightMorbent()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 31, 1431, 77.4, 44.3
  MOCK.bind = "Darkshire"
  for _, id in ipairs({ 538, 181, 173, 58, 221, 134, 225 }) do MOCK.questDone[id] = true end
  S.login()
  MOCK.questLog = { { questID = 325, isComplete = true } } -- Morbent's Bane for Sven
  MOCK.event("QUEST_ACCEPTED", 1, 325)
  local frame = questViewer()
  check(questText(frame, "give him Morbent's Bane"), "the Darkshire guide starts with Sven's turn-in")
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 153, isComplete = true }
  MOCK.event("QUEST_LOG_UPDATE")
  local nodes = { { "Darkshire, Duskwood", "CURRENT" }, { "Sentinel Hill, Westfall", "REACHABLE" } }
  taxiMap(nodes)
  check(arrowSays("Fly to Sentinel Hill"), "the arrow routes to Sven via Sentinel Hill: " .. arrowCaption())
  TakeTaxiNode(2)
  TaxiFrame:Hide()
  MOCK.onTaxi = true
  MOCK.advance(1)
  MOCK.onTaxi = false
  walkTo(1436, 56.6, 52.7)
  check(questText(frame, "give him Morbent's Bane") and not questText(frame, "Auberdine - Stormwind Harbor"),
    "landing at Sentinel Hill keeps the turn-in current")
  check(arrowSays(" yd") and not arrowSays("Fly to"), "the arrow leads on foot to Sven: " .. arrowCaption())
end

local function allText(root)
  local out = {}
  for _, child in ipairs({ root:GetRegions() }) do
    if child:IsShown() and child._text then out[#out + 1] = child._text end
  end
  for _, child in ipairs({ root:GetChildren() }) do
    if child:IsShown() then out[#out + 1] = allText(child) end
  end
  return table.concat(out, " | ")
end

function S.questDarkshireStranglethornHandoff()
  MOCK.race, MOCK.level, MOCK.bind = "Human", 31, "Darkshire"
  MOCK.questMap, MOCK.questX, MOCK.questY = 1436, 56.55, 52.70
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "darkshire-30" then
      for _, step in ipairs(section.steps) do
        if step.quest == 215 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  S.login()
  local frame = questViewer()
  check(questText(frame, "Darkshire") and questText(frame, "Levels 30-32"), "reload keeps the Darkshire chapter at Sentinel Hill")
  check(not questText(frame, "Auberdine - Stormwind Harbor"), "Sentinel Hill resumes without the Auberdine ship")
  check(questText(frame, "Follow the road south into Stranglethorn Vale"), "the next step is the overland approach to Rebel Camp: " .. allText(frame))
  check(arrowSays("bridge into Duskwood"), "the arrow leads across the Westfall bridge: " .. arrowCaption())
  walkTo(1431, 8, 64)
  check(arrowSays("road south into Stranglethorn"), "in Duskwood the arrow leads to the south road: " .. arrowCaption())
  walkTo(1434, 40.6, 3.5)
  check(questText(frame, "Accept - Jungle Secrets"), "crossing the border leads to Thorsen's pickup")
end

function S.questDarkshirePantherSuggestion()
  MOCK.race, MOCK.level, MOCK.bind = "Human", 31, "Darkshire"
  MOCK.questMap, MOCK.questX, MOCK.questY = 1431, 73.9, 44.4
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "darkshire-30" then
      for _, step in ipairs(section.steps) do
        if step.quest == 185 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 185, isComplete = true }, { questID = 190, objectives = {
    { text = "Young Panther slain: 1/10", numFulfilled = 1, numRequired = 10 },
  } } }
  S.login()
  local frame = questViewer()
  walkTo(1434, 41.5, 12.0)
  check(questText(frame, "Darkshire") and questText(frame, "Young Panthers prowl east of the camp"),
    "entering Stranglethorn keeps the Darkshire chapter on Panther Mastery: " .. allText(frame))
  check(not findButton(frame, function(label) return label == "Try Stranglethorn Early: Rebel Camp and Nesingwary" end),
    "the step window does not offer a route switch during its own Stranglethorn hunt")
  slash("quests")
  check(guideButton("Stranglethorn Early: Rebel Camp and Nesingwary"), "the longer route is still available in Quests")
end

function S.questDarkshireSouthshorePreview()
  MOCK.race, MOCK.level, MOCK.bind = "Human", 31, "Darkshire"
  MOCK.questMap, MOCK.questX, MOCK.questY = 1431, 73.9, 44.4
  LevelingCodexDB = { questPreview = 10, questDungeonPlan = { ["dungeon-gnomeregan"] = true } }
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "darkshire-30" then
      for _, step in ipairs(section.steps) do
        if step.flight == "Stormwind, Elwynn" then break end
        if step.quest and step.quest ~= 185 and step.quest ~= 190 then MOCK.questDone[step.quest] = true end
      end
    elseif section.id == "dungeon-gnomeregan" then
      for _, step in ipairs(section.steps) do
        if step.type == "accept" and step.phase == "prepare" and step.quest ~= 2929 then
          MOCK.questDone[step.quest] = true
        end
      end
    end
  end
  MOCK.questLog = { { questID = 185, isComplete = true }, { questID = 190, isComplete = true }, { questID = 2929 } }
  S.login()
  local frame = questViewer()
  walkTo(1434, 35.55, 10.55)
  check(questText(frame, "Turn in - Tiger Mastery"), "Darkshire keeps the first hunts active in Stranglethorn")
  for _, id in ipairs({ 185, 190 }) do
    table.remove(MOCK.questLog, 1)
    MOCK.questDone[id] = true
    MOCK.event("QUEST_TURNED_IN", id)
  end
  check(questText(frame, "Fly to Stormwind") and questText(frame, "Next section: Southshore, Alterac and Refuge Pointe"),
    "Stormwind is current and Southshore is a preview after the hunts: " .. allText(frame))
  check(questText(frame, "Dungeon quests ready"), "a dungeon is ready alongside the outdoor route")
  click(frame, "Try Stranglethorn Early: Rebel Camp and Nesingwary")
  check(questText(frame, "Stranglethorn Early") and questText(frame, "Levels 30-35"),
    "the Stranglethorn button opens the longer outdoor route while a dungeon is ready: " .. allText(frame))
  click(frame, "Run Gnomeregan")
  check(questText(frame, "Gnomeregan"), "the dungeon icon still opens its own guide")
end

-- Dungeon ahead: before a run's first pickup the route asks whether to plan it. Plan adds its
-- quests, Skip (Next) leaves them out, and a ready run leads the step text with find a group.
function S.questDungeonChoice()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 17, 1453, 61.88, 30.56
  local open = {}
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "westfall" then
      for _, step in ipairs(section.steps) do
        if step.quest == 92751 and step.type == "turnin" then break end
        if step.type == "accept" and step.quest then open[step.quest] = true end
        if step.type == "turnin" and step.quest then open[step.quest] = nil; MOCK.questDone[step.quest] = true end
      end
    end
  end
  open[92751] = nil
  MOCK.questLog = { { questID = 92751, isComplete = true } }
  for id in pairs(open) do MOCK.questLog[#MOCK.questLog + 1] = { questID = id } end
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - "), "resumes at Sprite's turn-in")
  table.remove(MOCK.questLog, 1)
  MOCK.questDone[92751] = true
  MOCK.event("QUEST_TURNED_IN", 92751)
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 92752 }
  MOCK.event("QUEST_ACCEPTED", 1, 92752)
  check(questText(frame, "Dungeon ahead - The Deadmines") and questText(frame, "group of five")
    and questText(frame, "Recommended for you"), "the route asks about the Deadmines before its first pickup: " .. allText(frame))
  check(findButton(frame, function(l) return l == "Plan The Deadmines" end)
    and findButton(frame, function(l) return l == "Skip" end), "the step window offers Plan and Skip")
  check(findButton(win(), function(l) return l == "Plan The Deadmines" end)
    and findButton(win(), function(l) return l == "Skip this run" end), "the Quests tab offers both for controllers")
  check(findButton(win(), function(l) return l == "Skip run" end)
    and not findButton(win(), function(l) return l == "Next step" end),
    "the Quests tab's Next step says it skips the run, like the step window's")

  click(frame, "Skip")
  check(LevelingCodexDB.questDungeonPlan["dungeon-deadmines"] == false and chatHas("The Deadmines is skipped"),
    "Skip leaves the run out")
  check(not questText(frame, "Dungeon ahead") and questText(frame, "Accept - "), "the route goes on to the pickups")
  click(frame, "Back")
  check(questText(frame, "Dungeon ahead - The Deadmines"), "Back returns to the choice")
  click(frame, "Plan The Deadmines")
  check(LevelingCodexDB.questDungeonPlan["dungeon-deadmines"] == true and chatHas("The Deadmines is planned"),
    "Plan adds the run")
  check(not questText(frame, "Dungeon ahead"), "planning goes on with the route")

  for _, id in ipairs({ 2040, 168, 167 }) do
    MOCK.questLog[#MOCK.questLog + 1] = { questID = id }
    MOCK.event("QUEST_ACCEPTED", 1, id)
  end
  check(not findButton(frame, function(l) return l == "Run The Deadmines" end), "finish the remaining outdoor chains before declaring the run ready")
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "dungeon-deadmines" then
      for _, step in ipairs(section.steps) do
        if step.phase == "prepare" and step.type == "accept" and step.quest ~= 2040 and step.quest ~= 168 and step.quest ~= 167 then
          MOCK.questDone[step.quest] = true
        end
      end
    end
  end
  MOCK.event("QUEST_QUERY_COMPLETE")
  check(questText(frame, "Dungeon quests ready - find a group"), "a ready run has a short reminder after the quest instructions")
  local dungeon = findButton(frame, function(l) return l == "Run The Deadmines" end)
  check(dungeon and dungeon:GetWidth() <= 32, "the run action is a compact icon")
end

-- The quests a section's route takes before the step `stop` matches: turned in before it (MOCK.questDone)
-- or still open (returned as a set, for the quest log).
local function routeUpTo(sectionId, stop)
  local open = {}
  local route = LevelingCodexQuests[MOCK.faction == "Horde" and "HORDE" or "ALLIANCE"]
  for _, section in ipairs(route.sections) do
    if section.id == sectionId then
      for _, step in ipairs(section.steps) do
        if stop(step) then break end
        if step.type == "accept" and step.quest then open[step.quest] = true end
        if step.type == "turnin" and step.quest then open[step.quest] = nil; MOCK.questDone[step.quest] = true end
      end
    end
  end
  return open
end

local function hasButton(root, label)
  return findButton(root, function(l) return l == label end) ~= nil
end

-- A Human at Deputy Rainer in Elwynn with Westbrook Garrison Needs Help! (239) ready, Hogger's poster next.
local function eliteAtHogger(hoggerInLog)
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 11, 1429, 24.3, 74.5
  local open = routeUpTo("elwynn", function(s) return s.quest == 239 and s.type == "turnin" end)
  open[239] = nil
  MOCK.questLog = { { questID = 239, isComplete = true } }
  for id in pairs(open) do MOCK.questLog[#MOCK.questLog + 1] = { questID = id } end
  if hoggerInLog then MOCK.questLog[#MOCK.questLog + 1] = { questID = 176 } end
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Westbrook Garrison Needs Help!"), "resumes at Rainer's turn-in: " .. allText(frame), 2)
  table.remove(MOCK.questLog, 1)
  MOCK.questDone[239] = true
  MOCK.event("QUEST_TURNED_IN", 239)
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 11 }
  MOCK.event("QUEST_ACCEPTED", 1, 11)
  return frame
end

-- An elite quest's pickup asks first: Take it keeps it, Skip passes it (Back asks again), and the
-- Quests tab offers the same choice for controller players.
function S.questEliteAsk()
  local frame = eliteAtHogger()
  check(questText(frame, 'Elite quest - WANTED: "Hogger"') and questText(frame, "Hogger (elite)")
    and questText(frame, "bring a group"), "the route asks before Hogger's poster: " .. allText(frame))
  check(hasButton(frame, "Take it") and hasButton(frame, "Skip") and not hasButton(frame, "Next"),
    "the step window offers Take it, and Next says Skip")
  click(win(), "Step")
  check(hasButton(win(), "Take it") and hasButton(win(), "Skip it"), "the Quests tab's Step view offers both")
  check(hasButton(win(), "Skip") and not hasButton(win(), "Next step"), "and its Next step button says Skip")

  click(frame, "Skip")
  check(LevelingCodexCharDB.questElite[176] == false and chatHas('WANTED: "Hogger" is skipped'),
    "Skip remembers the choice for this character")
  check(not questText(frame, "Elite quest") and not questText(frame, 'Accept - WANTED: "Hogger"')
    and questText(frame, "Complete - Riverpaw Gnoll Bounty"), "the route passes Hogger and goes on: " .. allText(frame))
  click(frame, "Next")
  check(not questText(frame, 'WANTED: "Hogger"'), "Hogger's own objective is passed too: " .. allText(frame))
  click(frame, "Back")
  click(frame, "Back")
  check(questText(frame, 'Elite quest - WANTED: "Hogger"') and LevelingCodexCharDB.questElite[176] == nil,
    "Back to the question asks again: " .. allText(frame))
  click(frame, "Take it")
  check(LevelingCodexCharDB.questElite[176] == true and questText(frame, 'Accept - WANTED: "Hogger"'),
    "Take it goes on to the pickup: " .. allText(frame))
end

-- A quest you already have (or have done) never asks.
function S.questEliteInLog()
  local frame = eliteAtHogger(true)
  check(not questText(frame, "Elite quest") and questText(frame, "Complete - Riverpaw Gnoll Bounty"),
    "with Hogger in the log there's no question: " .. allText(frame))
  check(LevelingCodexCharDB.questElite == nil or LevelingCodexCharDB.questElite[176] == nil, "and nothing is saved")
end

-- Settings > Elite quests: Ask (default), Always take, Always skip.
function S.questEliteModes()
  LevelingCodexDB = { questEliteMode = "take" }
  local frame = eliteAtHogger()
  check(not questText(frame, "Elite quest") and questText(frame, 'Accept - WANTED: "Hogger"'),
    "Always take goes straight to the pickup: " .. allText(frame))
  click(win(), "Settings")
  local function lit(label)
    local b = findButton(win(), function(l) return l == label end)
    return b and b.codexOn
  end
  check(lit("Always take") and not lit("Ask"), "Settings lights the mode in use")
  click(win(), "Always skip")
  check(LevelingCodexDB.questEliteMode == "skip" and lit("Always skip"), "Always skip is saved")
  check(not questText(frame, "Elite quest") and not questText(frame, 'Accept - WANTED: "Hogger"')
    and questText(frame, "Complete - Riverpaw Gnoll Bounty"), "Always skip passes the quest without asking: " .. allText(frame))
  click(win(), "Ask")
  check(LevelingCodexDB.questEliteMode == nil and questText(frame, 'Elite quest - WANTED: "Hogger"'),
    "Ask brings the question back: " .. allText(frame))
  check(LevelingCodexCharDB.questElite == nil or LevelingCodexCharDB.questElite[176] == nil,
    "the modes don't save a choice for the quest")
  click(win(), "Quests")
  click(win(), "Setup"); click(win(), "Your route")
  check(hasButton(win(), "Ask") and hasButton(win(), "Always take") and hasButton(win(), "Always skip"),
    "the guide setup card has the same three choices")
  click(win(), "Always take")
  check(LevelingCodexDB.questEliteMode == "take" and questText(frame, 'Accept - WANTED: "Hogger"'),
    "the setup card sets the mode too")
end

-- Skipping an elite quest passes the quests that need it; the Quests tab's Take it and Skip it work too.
local function eliteChainFixture()
  local function step(kind, id, name, y, chain, elite)
    return { type = kind, quest = id, name = name, text = "Test elite chain.", map = 1430, x = 50, y = y,
      level = 33, min = 30, chain = chain, elite = elite }
  end
  local sections = LevelingCodexQuests.ALLIANCE.sections
  sections[#sections + 1] = { id = "test-elite", title = "Test Elite Chain", zone = 1430, levels = { 32, 34 },
    alternate = true, verified = false, steps = {
      step("accept", 999201, "Test Bounty", 50, nil, "Test Brute"),
      step("complete", 999201, "Test Bounty", 60, nil, "Test Brute"),
      step("turnin", 999201, "Test Bounty", 50, nil, "Test Brute"),
      step("accept", 999202, "Test Follow-up", 50, { 999201 }),
      step("turnin", 999202, "Test Follow-up", 50, { 999201 }),
      step("accept", 999203, "Test Errand", 52),
      step("turnin", 999203, "Test Errand", 52),
    } }
end

function S.questEliteChain()
  eliteChainFixture()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 33, 1430, 50, 50
  S.login()
  local frame = questViewer()
  check(questText(frame, "Elite quest - Test Bounty") and questText(frame, "the quests that need it"),
    "the fixture's elite pickup asks, naming its follow-ups: " .. allText(frame))
  slash("quests")
  stepTool("Skip it")
  check(LevelingCodexCharDB.questElite[999201] == false and questText(frame, "Accept - Test Errand"),
    "the Quests tab's Skip it passes the quest and its follow-up: " .. allText(frame))
  click(frame, "Back")
  check(questText(frame, "Elite quest - Test Bounty"), "Back asks again: " .. allText(frame))
  stepTool("Take it")
  check(LevelingCodexCharDB.questElite[999201] == true and questText(frame, "Accept - Test Bounty"),
    "the Quests tab's Take it goes on to the pickup: " .. allText(frame))
  MOCK.questLog = { { questID = 999201, isComplete = true } }
  MOCK.event("QUEST_ACCEPTED", 1, 999201)
  check(questText(frame, "Turn in - Test Bounty"), "the taken quest goes on as usual: " .. allText(frame))
end

-- The same choice with no quest log or map APIs (the minimal client) and nothing saved: an elite
-- pickup put first in Northshire asks at login; Skip, Back and the Quests tab's Take it work.
function S.questEliteFresh()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "accept", quest = 999301, name = "Test Elite Bounty", elite = "Test Brute",
        text = "Test elite pickup.", map = 1429, x = 48.9, y = 41.6, level = 1, min = 1 })
      table.insert(section.steps, 2, { type = "turnin", quest = 999301, name = "Test Elite Bounty", elite = "Test Brute",
        text = "Test elite hand-in.", map = 1429, x = 48.9, y = 41.6 })
    end
  end
  LevelingCodexDB, LevelingCodexCharDB = nil, nil
  S.login()
  local frame = questViewer()
  check(questText(frame, "Elite quest - Test Elite Bounty") and questText(frame, "Test Brute (elite)"),
    "a fresh character is asked at the elite pickup: " .. allText(frame))
  click(frame, "Skip")
  check(questText(frame, "Accept - A Threat Within"), "Skip passes the pickup and its hand-in: " .. allText(frame))
  click(frame, "Back")
  check(questText(frame, "Elite quest - Test Elite Bounty"), "Back asks again: " .. allText(frame))
  slash("quests")
  stepTool("Take it")
  check(questText(frame, "Accept - Test Elite Bounty"), "the Quests tab's Take it goes on to the pickup: " .. allText(frame))
end

-- Inside a dungeon: zoning in opens its guide (Settings > Open a dungeon's guide when you enter
-- it), each boss is a step with its tip, ticked off by ENCOUNTER_END or BOSS_KILL (or Next; never
-- the combat log, which Forever keeps from addons), the quest objectives show as On the way, and
-- leaving goes back to the route.
function S.questBossSteps()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 20, nil
  MOCK.instanceName, MOCK.instanceID = "Deadmines", 36
  MOCK.questLog = { { questID = 166, objectives = { { text = "Head of VanCleef: 0/1" } } } }
  LevelingCodexDB = { noDungeonOpen = true }
  S.login()
  local frame = questViewer()
  check(not questText(frame, "Boss - "), "with the setting off, entering keeps the route")
  LevelingCodexDB.noDungeonOpen = nil
  MOCK.instanceName, MOCK.instanceID = nil, nil
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  MOCK.instanceName, MOCK.instanceID = "Deadmines", 36
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Boss - Rhahk'Zor") and questText(frame, "Pull him back to the group")
    and chatHas("The Deadmines: the step window follows its guide"), "zoning in opens the guide at its first boss")
  check(questText(frame, "ON THE WAY") and questText(frame, "Head of VanCleef 0/1"),
    "the run's quest objectives show beside the bosses")
  local target = _G.LevelingCodexQuestTarget
  check(target and target:GetAttribute("macrotext") == "/targetexact Rhahk'Zor", "the target button targets the boss")

  MOCK.event("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 0)
  check(questText(frame, "Boss - Rhahk'Zor"), "a wipe (ENCOUNTER_END without success) changes nothing")
  MOCK.event("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 1)
  check(questText(frame, "Boss - Miner Johnson"), "ENCOUNTER_END ticks the boss off")
  click(frame, "Skip rare")
  check(questText(frame, "Boss - Sneed's Shredder"), "Skip rare passes a rare that isn't there")
  MOCK.event("ENCOUNTER_END", 2742, "Sneed's Shredder", 1, 5, 1)
  check(questText(frame, "Boss - Gilnid"), "ENCOUNTER_END ticks the next boss off")
  MOCK.event("BOSS_KILL", 2743, "Gilnid")
  check(questText(frame, "Boss - Mr. Smite"), "BOSS_KILL ticks a boss off")
  MOCK.event("BOSS_KILL", 2744, "Captain Greenskin")
  check(questText(frame, "Boss - Mr. Smite"), "a boss killed out of order is ticked off, the current one stays")
  MOCK.event("ENCOUNTER_END", 2745, "Mr. Smite", 1, 5, 1)
  check(questText(frame, "Boss - Edwin VanCleef"), "the next boss skips one already down")
  check(target:GetAttribute("macrotext") == "/targetexact Edwin VanCleef", "the target button follows the boss")

  MOCK.instanceName, MOCK.instanceID = nil, nil
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(not questText(frame, "Boss - "), "leaving the dungeon leaves the boss steps")
  MOCK.instanceName, MOCK.instanceID = "Deadmines", 36
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Boss - Edwin VanCleef"), "running back in keeps the bosses already down")
end

function S.questStockadeBossGuide()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 26, nil
  MOCK.instanceName, MOCK.instanceID = "Stormwind Stockade", 34
  MOCK.questLog = {
    { questID = 377, objectives = { { text = "Hand of Dextren Ward: 0/1" } } },
    { questID = 388, objectives = { { text = "Red Wool Bandana: 0/10" } } },
  }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Boss - Targorr the Dread") and questText(frame, "0/5 bosses") and questText(frame, "Thrash")
    and not questText(frame, "Chain Lightning"), "the step window shows the current fight's mechanics")
  slash("quests")
  guidesView("Dungeons")
  click(win(), "The Stockade")
  check(questText(win(), "0/5 bosses") and questText(win(), "Thrash") and not questText(win(), "Chain Lightning"),
    "the inside page starts on one encounter")
  click(win(), "Quest checklist")
  check(questText(win(), "INSIDE"), "the quest checklist is available during the run")
  click(win(), "Bosses in order")
  click(win(), "Next boss")
  check(questText(win(), "Shield Slam") and questText(frame, "Boss - Targorr the Dread"),
    "previewing Kam in the board leaves the followed boss alone")
  click(win(), "Current boss")
  MOCK.event("BOSS_KILL", 2757, "Kam Deepfury")
  check(questText(win(), "1/5 bosses") and questText(win(), "Thrash"), "a kill out of order counts without moving the current boss")
  MOCK.event("ENCOUNTER_END", 2756, "Targorr the Dread", 1, 5, 1)
  check(questText(win(), "2/5 bosses") and questText(win(), "Chain Lightning") and questText(frame, "Bloodlust"),
    "both views advance to Hamhock and show his abilities")
  MOCK.event("BOSS_KILL", 2758, "Hamhock")
  check(questText(frame, "Smoke Bomb"), "Bazil's card calls out his stun")
  MOCK.event("BOSS_KILL", 2760, "Bazil Thredd")
  check(questText(frame, "Skip rare if you don't see the boss") and hasButton(frame, "Skip rare")
    and hasButton(frame, "Mark defeated") and hasButton(win(), "Skip rare"), "Bruegal is clearly optional in both views")
  click(frame, "Compact")
  check(questText(frame, "Rare") and hasButton(frame, "Skip rare"), "compact mode still calls out the rare and the skip")
  click(frame, "Expand")
  click(win(), "Skip rare")
  check(questText(win(), "4/5 bosses") and questText(frame, "Intimidating Shout")
    and questText(frame, "Hand of Dextren Ward 0/1") and questText(frame, "Red Wool Bandana 0/10"),
    "skipping Bruegal advances without counting a kill or losing quest goals")
  click(win(), "Previous boss")
  check(questText(win(), "Skipped") and questText(win(), "Bruegal Ironknuckle"), "the board records a skip")
  click(frame, "Back")
  check(hasButton(frame, "Mark defeated"), "Back lets the player revisit the rare")
  click(frame, "Mark defeated")
  check(questText(win(), "Defeated") and questText(frame, "Boss - Dextren Ward"),
    "a player who found Bruegal can record the kill manually")
  click(win(), "Current boss")
  MOCK.event("BOSS_KILL", 2759, "Dextren Ward")
  click(win(), "Inside")
  check(questText(win(), "5/5 bosses"), "the board retains the completed clear")
end

function S.questDungeonEncounterGuides()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 42, nil
  MOCK.instanceName, MOCK.instanceID = "Scarlet Monastery", 189
  S.login()
  local frame = questViewer()
  check(not questText(frame, "Boss - Interrogator Vishas"), "a shared map does not assume the Graveyard")
  MOCK.event("ENCOUNTER_START", 450, "High Inquisitor Whitemane", 1, 5)
  check(questText(frame, "Boss - High Inquisitor Fairbanks") and hasButton(frame, "Skip boss"),
    "a Cathedral encounter selects the wing and identifies Fairbanks as optional")
  click(frame, "Skip boss")
  check(questText(frame, "Boss - Mograine and Whitemane") and questText(frame, "Scarlet Resurrection")
    and questText(frame, "0/1 bosses"), "both phases are one encounter")
  MOCK.event("BOSS_KILL", nil, "Scarlet Commander Mograine")
  check(questText(frame, "Boss - Mograine and Whitemane"), "Mograine's first fall does not finish the encounter")
  MOCK.event("ENCOUNTER_END", 450, "High Inquisitor Whitemane", 1, 5, 1)
  check(not questText(frame, "Boss - Mograine and Whitemane"), "the successful encounter advances both phases")
  MOCK.event("ENCOUNTER_START", 446, "Houndmaster Loksey", 1, 5)
  check(questText(frame, "Boss - Houndmaster Loksey") and questText(frame, "Bloodlust"), "another wing selects its own boss guide")
  click(frame, "Return to leveling")
  MOCK.event("BOSS_KILL", 446, "Houndmaster Loksey")
  check(not questText(frame, "Boss - Arcanist Doan"), "leaving the guide prevents an encounter from reopening it")

  MOCK.instanceName, MOCK.instanceID = "Uldaman", 70
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Boss - Revelosh") and questText(frame, "Chain Lightning"), "Alliance Uldaman has ability notes")
  MOCK.event("BOSS_KILL", 547, "Alternate encounter name")
  check(questText(frame, "Boss - The Lost Dwarves") and questText(frame, "1/8 bosses"), "the numeric encounter ID advances the Alliance guide")

  MOCK.instanceName, MOCK.instanceID = "Dire Maul: North", 429
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Tribute run: leave Mol'dar alive") and questText(frame, "0/1 bosses"), "the named wing opens with Tribute instructions")
  for _ = 1, 6 do click(frame, "Skip boss") end
  check(questText(frame, "Boss - King Gordok") and questText(frame, "Mortal Strike")
    and questText(frame, "0/1 bosses"), "Tribute skips all six optional fights and keeps the required boss")
end

-- A step's `path`: the arrow leads through the way in, in order, then to the step's own spot;
-- a position the client reports on the continent map still counts.
function S.questEntrancePath()
  local northshire
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then northshire = section end
  end
  table.insert(northshire.steps, 1, { type = "goto", text = "Go down the tunnel to the cave.", map = 1429,
    x = 52, y = 47, path = { { 48, 43 }, { 50, 45 } } })
  MOCK.questX, MOCK.questY = 40, 40
  S.login()
  local frame, arrow = questViewer(), LevelingCodexQuestArrow
  MOCK.advance(0.5)
  check(questText(frame, "Go down the tunnel") and questText(arrow, "(way in 1 of 2)"), "a path starts at its first point")
  MOCK.questX, MOCK.questY = 48, 43
  MOCK.advance(0.5)
  check(questText(arrow, "(way in 2 of 2)"), "reaching a point leads on to the next")
  MOCK.questMap, MOCK.questX, MOCK.questY = 1415, 46.02, 70.09 -- Elwynn 50, 45 on the continent map
  MOCK.advance(0.5)
  check(not questText(arrow, "way in") and questText(arrow, " yd"),
    "a point reached on the continent map counts; then the step's own spot")
end

-- The pace card: XP per hour, time to level, where this level's XP came from, finished levels.
function S.paceCard()
  MOCK.level, MOCK.xp, MOCK.xpMax, MOCK.rested = 5, 400, 1000, 150
  local function rec(seconds, xp, q, k, quests, kills)
    return { seconds = seconds, xp = xp, questXP = q, killXP = k, rested = 0, quests = quests, kills = kills, deaths = 0,
      goldIn = {}, goldOut = {} }
  end
  -- what an earlier session (or a /reload) saved
  LevelingCodexCharDB = { stats = { version = 1, zones = {}, totals = { goldIn = {}, goldOut = {} },
    levels = { [3] = rec(0, 0, 0, 0, 0, 0), [4] = rec(3900, 900, 600, 250, 4, 9), [5] = rec(1800, 300, 200, 100, 2, 3) } } }
  LevelingCodexCharDB.stats.levels[5].rested = 1200
  S.login()
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Vermin dies, you gain 50 experience.")
  MOCK.xp = 450
  MOCK.event("PLAYER_XP_UPDATE", "player")
  slash("")
  click(win(), "This Level")
  if MOCK.minimal then check(questText(win(), "YOUR PACE"), "the card shows without the XP calls"); return end
  check(questText(win(), "Level 5: 450 / 1,000 XP") and questText(win(), "Level 6 in about"), "the XP bar's figures")
  check(questText(win(), "30 min on this level (all sessions)"), "time on the level survives a reload")
  check(questText(win(), "XP per hour this session, 1,200 rested XP on this level"), "the rested figure says what it counts")
  check(questText(win(), "Quests 200 XP, 2 turned in") and questText(win(), "Kills 150 XP, 4 kills"), "XP by source")
  check(questText(win(), "Level 4") and questText(win(), "1 h 5 min, 4 quests, 9 kills"), "the last levels")
  click(win(), ">")
  check(questText(win(), "Level 4") and not questText(win(), "Level 5"),
    "above your level, the last levels are still the ones you finished")
  click(win(), "<")
  click(win(), "<")
  click(win(), "<")
  check(questText(win(), "0 min on this level"), "an empty record draws without dividing by zero")
  click(win(), "<")
  check(questText(win(), "No stats for level 2 yet."), "a level without stats says so")
end

function S.paceCardLost()
  slash("")
  click(win(), "This Level")
  check(questText(win(), "since you logged in"), "without saved data the card says what it counts")
end

function S.questCorpse()
  S.login()
  local arrow = _G.LevelingCodexQuestArrow
  MOCK.ghost, MOCK.corpse = true, { 1429, 50, 50 }
  MOCK.advance(0.5)
  check(arrow:IsShown() and questText(arrow, "Your corpse - "), "a ghost's arrow leads to the corpse")
  MOCK.questX, MOCK.questY = 50, 50.2
  MOCK.advance(0.5)
  check(questText(arrow, "Your corpse is here"), "the arrow says when you reach the corpse")
  MOCK.corpse = nil
  MOCK.advance(0.5)
  check(questText(arrow, "Return to your corpse"), "a corpse the client can't place still gets a hint")
  MOCK.ghost = false
  MOCK.advance(0.5)
  check(not questText(arrow, "corpse"), "alive again, the arrow leads to the step")
end

function S.questGossip()
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - A Threat Within"), "fresh route starts with an accept")
  MOCK.gossipAvailable = { { questID = 999, title = "Other" }, { questID = 783, title = "A Threat Within" } }
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == nil, "gossip is left alone while auto-accept is off")
  LevelingCodexDB.questAutoAccept = true
  MOCK.alt = true
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == nil, "holding Alt keeps the gossip list")
  MOCK.alt = false
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == 783, "auto-accept picks the guide quest from a gossip list")
  MOCK.greetingAvailable = { { title = "Other", questID = 999 }, { title = "A Threat Within" } }
  MOCK.event("QUEST_GREETING")
  check(MOCK.greetingPicked == 2, "auto-accept picks the guide quest from a greeting by title")
  local played
  local original = PlaySound
  PlaySound = function(id) played = id end
  MOCK.questLog = { { questID = 783 } }
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  check(played, "a step the game finishes plays a sound")
  played = nil
  click(frame, "Next")
  check(not played, "Next stays quiet")
  PlaySound = original
end

-- quest tracker side by side: its auto-questing and hold-back key take precedence over the Codex's.
function S.questIntegrationAuto()
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - A Threat Within"), "fresh route starts with an accept")
  LevelingCodexDB.questAutoAccept = true
  MOCK.gossipAvailable = { { questID = 783, title = "A Threat Within" } }
  Questie = {} -- loaded, settings not built yet
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == 783, "quest tracker without settings leaves auto-accept to the Codex")
  MOCK.gossipPicked = nil
  MOCK.makeQuestProvider({ autoAccept = true })
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == nil, "quest tracker's auto-accept handles gossip lists")
  MOCK.interactionQuest = 783
  MOCK.event("QUEST_DETAIL")
  check(not MOCK.questAccepted, "quest tracker's auto-accept handles the quest window")
  MOCK.makeQuestProvider({ legacyAccept = true })
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipPicked == nil, "an older quest tracker's autoaccept counts too")
  slash("quests")
  click(win(), "Settings")
  check(questText(win(), "Your quest tracker's auto-accept is on and handles quest pickups."), "the tickbox says quest tracker handles it")

  MOCK.makeQuestProvider({}) -- auto-accept off, key Shift
  click(win(), "Settings")
  local box = findButton(win(), function(l) return l == "Auto-accept the current guide quest" end)
  MOCK.fire(box, "OnEnter")
  check(table.concat(GameTooltip._lines or {}, " "):find("Hold Alt or Shift to stop it.", 1, true),
    "the tooltip names quest tracker's key")
  MOCK.shift = true
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("QUEST_DETAIL")
  check(MOCK.gossipPicked == nil and not MOCK.questAccepted, "quest tracker's key holds the Codex back")
  MOCK.shift, MOCK.alt = false, true
  MOCK.event("QUEST_DETAIL")
  check(not MOCK.questAccepted, "Alt holds back the quest window too")
  MOCK.alt = false
  MOCK.event("QUEST_DETAIL")
  check(MOCK.questAccepted == 783, "the Codex accepts when quest tracker's auto-accept is off and no key is held")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest tracker: loaded %(version .-%), auto%-accept off, auto%-complete off, key Shift"),
    "debug reports quest tracker's settings")

  local objective = { text = "Speak to McBride 1/1", numFulfilled = 1, numRequired = 1, finished = true }
  MOCK.questLog = { { questID = 783, title = "A Threat Within", objectives = { objective } } }
  MOCK.event("QUEST_ACCEPTED", 783)
  MOCK.event("QUEST_LOG_UPDATE")
  LevelingCodexDB.questAutoTurnin, MOCK.questChoices = true, 0
  MOCK.makeQuestProvider({ autocomplete = true })
  MOCK.event("QUEST_COMPLETE")
  check(not MOCK.questRewarded, "quest tracker's auto-complete handles turn-ins")
  click(win(), "Settings")
  check(questText(win(), "Your quest tracker's auto-complete is on and handles quest turn-ins."), "the turn-in tickbox says so")
  MOCK.makeQuestProvider({})
  MOCK.event("QUEST_COMPLETE")
  check(MOCK.questRewarded == 783, "the Codex turns in when quest tracker's auto-complete is off")
end

-- quest tracker side by side: the step window sits beside external quest tracker until you move it.
function S.questIntegrationTracker()
  S.login()
  local viewer = questViewer()
  local p, rel, rp, x, y = viewer:GetPoint()
  check(p == "RIGHT" and rel == UIParent and x == -48 and y == 80, "default spot without quest tracker")
  MOCK.makeQuestProvider({ cx = 1700 }) -- quest tracker builds its tracker after login
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(p == "TOPRIGHT" and rel == Questie_BaseFrame and rp == "TOPLEFT" and x == -12 and y == -40,
    "beside a right-hand tracker, on its left")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Step window: beside external quest tracker"), "debug names the placement")
  Questie_BaseFrame._cx = 200
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(p == "TOPLEFT" and rel == Questie_BaseFrame and rp == "TOPRIGHT" and x == 58 and y == -40,
    "beside a left-hand tracker, on its right, clear of the item and target buttons")
  Questie_BaseFrame.GetCenter = function() return nil end
  MOCK.event("QUEST_LOG_UPDATE")
  check(select(2, viewer:GetPoint()) == UIParent, "a tracker without a position yet is ignored")
  Questie_BaseFrame.GetCenter = nil
  Questie_BaseFrame:Hide()
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(p == "RIGHT" and rel == UIParent and x == -48 and y == 80, "a hidden tracker restores the default spot")
  MOCK.drag(viewer, -30, 0)
  Questie_BaseFrame:Show()
  MOCK.event("QUEST_LOG_UPDATE")
  p, rel, rp, x, y = viewer:GetPoint()
  check(rel == UIParent and x == -78, "a dragged position wins over external quest tracker")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Step window: saved position"), "debug names the saved position")
end

-- external quest tracker changing without a quest event, in combat, and an anchor the client refuses.
function S.questIntegrationTrackerLive()
  S.login()
  local viewer = questViewer()
  MOCK.makeQuestProvider({ cx = 1700 })
  MOCK.advance(0.25)
  check(select(2, viewer:GetPoint()) == Questie_BaseFrame, "a tracker shown without a quest event is noticed on the next tick")
  MOCK.combat = true
  MOCK.event("PLAYER_REGEN_DISABLED")
  Questie_BaseFrame:Hide()
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  check(select(2, viewer:GetPoint()) == Questie_BaseFrame, "the window stays put in combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.25)
  local p, rel, _, x, y = viewer:GetPoint()
  check(p == "RIGHT" and rel == UIParent and x == -48 and y == 80, "after combat it moves to the default spot")
  Questie_BaseFrame:ClearAllPoints()
  Questie_BaseFrame:SetPoint("TOP", viewer, "BOTTOM") -- anchoring to it would now be a loop
  Questie_BaseFrame:Show()
  MOCK.advance(0.25)
  check(select(2, viewer:GetPoint()) == UIParent, "an anchor the client refuses leaves the window in its default spot")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("Step window: default spot"), "debug says where the window is")
end

-- quest database fixture: Kobold Camp Cleanup (7) in Elwynn; see the plan's test geometry.
local function koboldDB(opts)
  opts = opts or {}
  MOCK.makeQuestDataProvider({
    contract = opts.contract, noZones = opts.noZones,
    quests = { [7] = { objectives = opts.objectives or { [1] = { { 6, nil, 0 }, { 257, nil, 0 }, { 999, nil, 0 } } } } },
    npcs = {
      [6] = { name = "Kobold Vermin", spawns = {
        [12] = { { 50.0, 38.0 }, { 47.0, 34.0 }, { 48.9, 40.6, 5 }, { 48.8, 54.0 } },
        [40] = { { 48.8, 44.0 } } } },
      [257] = { name = "Kobold Worker", spawns = { [12] = { { 44.0, 36.4 } } } },
      [999] = { name = "Ghost" },
    },
    objects = opts.objects, items = opts.items,
  })
end

function S.questIntegrationDB()
  S.login()
  slash("quests")
  click(win(), "Settings")
  check(not questText(win(), "Point the arrow at the nearest objective"), "no setting without quest database")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest tracker: not loaded") and chatHas("quest database: not installed"), "debug names what is missing")
  koboldDB({ contract = 0 })
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest database: off %(contract check failed%)"), "an incompatible quest database is refused")
  koboldDB({ noZones = true })
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest database: off %(no zone table%)"), "quest database without its zone table is refused")
  koboldDB()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest database: contract 4 %(baked%), 2 zone maps, arrow: "), "a usable quest database is reported")
  click(win(), "Settings")
  check(questText(win(), "Point the arrow at the nearest objective"), "the setting shows with quest database")
end

function S.questIntegrationMinimal()
  MOCK.makeQuestProvider({ autoAccept = true })
  koboldDB()
  S.login()
  slash("quests")
  click(win(), "Settings")
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("QUEST_DETAIL")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest tracker: loaded") and chatHas("quest database: contract 4"), "the quest tracker block works on a minimal client")
end

-- The last-mile arrow: Kobold Camp Cleanup's camp is at (48.8, 36.4) in Elwynn.
local function koboldCamp(objectives, x, y)
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = objectives } }
  MOCK.questMap, MOCK.questX, MOCK.questY = 1429, x, y
  S.login()
end

local function moveTo(x, y)
  MOCK.questX, MOCK.questY = x, y
  MOCK.advance(0.25)
end

function S.questIntegrationNearest()
  koboldDB()
  local vermin = { text = "Kobold Vermin 4/10", finished = false }
  koboldCamp({ vermin }, 48.8, 50.0)
  local arrow = LevelingCodexQuestArrow
  local art = arrow:GetRegions()
  check(questText(arrow, "315 yd") and not questText(arrow, "Kobold Vermin"), "outside the camp the arrow leads to the camp")
  moveTo(48.8, 44.0)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "inside the camp: the nearest unphased spawn on this map")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("arrow: inside the camp, 2 spawns, nearest Kobold Vermin"), "debug reports the candidates")
  moveTo(48.8, 48.0)
  check(questText(arrow, "Kobold Vermin - 235 yd"), "still inside before CAMP_LEAVE; spawns past SPAWN_RANGE ignored")
  moveTo(48.8, 50.0)
  check(questText(arrow, "315 yd"), "leaving the camp returns to the camp point")
  moveTo(48.8, 48.0)
  check(questText(arrow, "268 yd"), "no re-entry before CAMP_ENTER")
  moveTo(50.0, 38.5)
  check(questText(arrow, "Kobold Vermin nearby") and not art:IsShown(), "next to a spawn: nearby, no arrow art")
  moveTo(48.8, 44.0)
  LevelingCodexDB.noNearestSpawn = true
  MOCK.advance(0.25)
  check(questText(arrow, "176 yd") and not questText(arrow, "Kobold Vermin"), "the setting turns it off")
  LevelingCodexDB.noNearestSpawn = nil
  local worker = { text = "Kobold Worker 0/5", finished = false }
  MOCK.questLog = { { questID = 7, objectives = { vermin, worker } } }
  MOCK.event("QUEST_LOG_UPDATE")
  moveTo(48.8, 44.0)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "two objectives: the nearest of both")
  vermin.text, vermin.finished = "Kobold Vermin 10/10", true
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  check(questText(arrow, "Kobold Worker - 242 yd"), "a finished objective drops its spawns")
  MOCK.questLog = { { questID = 7, objectives = { { text = "Gnoll Pelt 0/5", finished = false } } } }
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "no name match: every objective counts, spawnless ones skipped")
  MOCK.questDone[7], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 7)
  MOCK.advance(0.25)
  check(not questText(arrow, "Kobold Vermin"), "a new step drops the old nearest target")
end

function S.questIntegrationNearestFallback()
  koboldDB()
  koboldCamp({ { text = "Kobold Vermin 10/10", finished = true }, { text = "Gnoll Pelt 0/5", finished = false } }, 48.8, 44.0)
  check(questText(LevelingCodexQuestArrow, "Kobold Worker - 242 yd"), "the wide fallback leaves out finished objectives")
end

function S.questIntegrationNearestItem()
  koboldDB({
    objectives = { [3] = { { 1001, nil, 0 } } },
    items = { [1001] = { name = "Large Candle", npcDrops = { 6 }, objectDrops = { 50 } } },
    objects = { [50] = { name = "Candle Box", spawns = { [12] = { { 47.5, 42.0 } } } } },
  })
  koboldCamp({ { text = "Large Candle: 2/8", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "Candle Box - 65 yd"), "item objectives lead to whatever drops them")
  moveTo(47.5, 42.5)
  check(questText(arrow, "Candle Box nearby"), "nearby an item source")
end

function S.questIntegrationNearestPart()
  MOCK.makeQuestDataProvider({
    quests = { [92745] = { objectives = { [1] = { { 1101, nil, 0 }, { 1102, nil, 0 } } } } },
    npcs = {
      [1101] = { name = "Kobold Digger", spawns = { [40] = { { 46.5, 22.0 } } } },
      [1102] = { name = "Riverpaw Miner", spawns = { [40] = { { 45.3, 22.5 } } } },
    },
  })
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 15, 1436, 45.3, 22.0
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "westfall" then
      for _, step in ipairs(section.steps) do
        if step.quest == 92745 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 92745, objectives = {
    { text = "Kobold Diggers 0/4", finished = false }, { text = "Riverpaw Miners 0/6", finished = false } } } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  MOCK.advance(0.25)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "Kobold Digger - 42 yd") and not questText(arrow, "Riverpaw"),
    "an objective-part step only uses its own objective")
end

-- Deferred review minors, one scenario each.
function S.questIntegrationNearestCleared()
  koboldDB()
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "Kobold Vermin - 145 yd"), "the nearest spawn first")
  moveTo(50.0, 38.5)
  check(questText(arrow, "Kobold Vermin nearby"), "standing at the spawn")
  moveTo(48.8, 44.0)
  check(questText(arrow, "Kobold Vermin - 240 yd"), "a spawn you just visited is skipped")
  MOCK.advance(90)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "it counts again after 90 seconds")
end

function S.questIntegrationArrowClamp()
  S.login()
  local _, _, top = questViewer():GetClampRectInsets()
  check(top and top >= 76, "the screen clamp keeps the arrow above the window on screen")
end

function S.questIntegrationNearestRetext()
  koboldDB()
  local line = { text = "", finished = false } -- objective text not loaded yet
  koboldCamp({ line }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "Kobold Vermin - 145 yd"), "no text yet: the wide search")
  line.text = "Kobold Worker 0/5"
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  check(questText(arrow, "Kobold Worker - 242 yd"), "the objective text arriving narrows the search")
end

function S.questIntegrationNearestLateData()
  local quests = {}
  MOCK.makeQuestDataProvider({ quests = quests, npcs = { [6] = { name = "Kobold Vermin", spawns = { [12] = { { 50.0, 38.0 } } } } } })
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "176 yd"), "no quest database objectives yet: today's arrow")
  quests[7] = { objectives = { [1] = { { 6, nil, 0 } } } }
  MOCK.advance(5)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "an empty spawn list is looked up again after 5 seconds")
end

function S.questIntegrationRecheck()
  koboldDB({ contract = 0 })
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "176 yd"), "a refused contract keeps today's arrow")
  LibQuestieDB.RequireContract = function() return true end -- quest database finished starting up
  MOCK.advance(10)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "quest database is checked once more after 10 seconds")
end

function S.questIntegrationNearestEmptyText()
  koboldDB({ objectives = { [1] = { { 6, "", 0 } } } })
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  check(questText(LevelingCodexQuestArrow, "Kobold Vermin - 145 yd"), "an empty objective text falls back to the NPC's name")
end

function S.questIntegrationNearestEmptyName()
  MOCK.makeQuestDataProvider({ quests = { [7] = { objectives = { [1] = { { 6, "Kobold Vermin", 0 } } } } },
    npcs = { [6] = { name = "", spawns = { [12] = { { 50.0, 38.0 } } } } } })
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  check(questText(LevelingCodexQuestArrow, "Kobold Vermin - 145 yd"), "an empty NPC name falls back to the objective's")
end

function S.questIntegrationNearestNoRows()
  koboldDB()
  koboldCamp({}, 48.8, 44.0) -- the log gives no objective lines
  check(questText(LevelingCodexQuestArrow, "Kobold Vermin - 145 yd"), "no objective lines: the wide search")
end

function S.questIntegrationNearestNoScale()
  koboldDB()
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  LevelingCodexQuests.ALLIANCE.extents[1429] = nil
  MOCK.advance(0.25)
  MOCK.chat = {}
  slash("debug")
  check(chatHas("arrow: no map scale"), "debug says the map scale is missing")
end

function S.questIntegrationNearestRoundTrip()
  koboldDB()
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  local frame, arrow = questViewer(), LevelingCodexQuestArrow
  moveTo(48.8, 48.0)
  check(questText(arrow, "Kobold Vermin - 235 yd"), "inside the camp")
  click(frame, "Next")
  MOCK.advance(0.25)
  click(frame, "Back")
  MOCK.advance(0.25)
  check(questText(arrow, "268 yd"), "leaving the step and coming back starts outside the camp")
end

function S.questIntegrationNearestError()
  koboldDB()
  MOCK.questDataError = true
  koboldCamp({ { text = "Kobold Vermin 4/10", finished = false } }, 48.8, 44.0)
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, "176 yd") and not questText(arrow, "Kobold Vermin"), "a read error keeps today's arrow")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("quest database: off %(read failed"), "debug names the read error")
  MOCK.questDataError = false
  MOCK.advance(0.25)
  check(questText(arrow, "176 yd"), "no retry straight away")
  MOCK.advance(10)
  check(questText(arrow, "Kobold Vermin - 145 yd"), "one retry after 10 seconds")
  MOCK.questDataError = true
  MOCK.questLog = { { questID = 7, objectives = { { text = "Kobold Vermin 4/10", finished = false },
    { text = "Kobold Worker 0/5", finished = false } } } }
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(0.25)
  MOCK.questDataError = false
  MOCK.advance(15)
  check(questText(arrow, "176 yd"), "a second read error turns it off for the session")
end

function S.questFlights()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 18, 1433
  LevelingCodexCharDB = { questFlights = { ["Darkshire, Duskwood"] = true } }
  C_TaxiMap = { GetTaxiNodesForMap = function(map)
    if map == 1415 then return { { name = "Lakeshire, Redridge", isUndiscovered = false },
      { name = "Darkshire, Duskwood", isUndiscovered = true } } end
  end }
  S.login()
  check(not questText(questViewer(), "Flight path - Lakeshire, Redridge"), "a flight path the game lists as known is skipped")
  check(LevelingCodexCharDB.questFlights == nil or not LevelingCodexCharDB.questFlights["Darkshire, Duskwood"],
    "the client clears a path falsely remembered by an older version")
  C_TaxiMap = nil
end

function S.questDuskwood()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 23, 1431, "Lakeshire"
  S.login()
  local frame = questViewer()
  check((questText(frame, "Duskwood") and questText(frame, "Levels 21-27")), "a level 23 in Duskwood starts the Duskwood section")
  check(questText(frame, "Flight path - Darkshire, Duskwood"), "Duskwood starts at the Darkshire flight path")
  MOCK.bind = "Darkshire"
  MOCK.event("HEARTHSTONE_BOUND")
  click(frame, "Next")
  check(questText(frame, "Accept - The Totem of Infliction"), "Darkshire starts with the first pickups, Madame Eva by the flight master")
end

function S.questDuskwoodDagger()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 24, 1431, "Darkshire"
  LevelingCodexCharDB = { questFlights = { ["Darkshire, Duskwood"] = true } }
  MOCK.questDone[56] = true
  for _, id in ipairs({ 163, 164, 165, 57, 101, 96139 }) do
    MOCK.questLog[#MOCK.questLog + 1] = { questID = id }
  end
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - Eight-Legged Menaces") and not questText(frame, "Accept - Ira's Dagger"),
    "the west loop starts without waiting for a rare drop")
  MOCK.bags[281143] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  check(questText(frame, "Accept - Ira's Dagger") and questText(frame, "from your bags"),
    "looting the dagger adds its pickup on the west loop")
  click(frame, "Next")
  check(questText(frame, "Accept - Eight-Legged Menaces") and not questText(frame, "Accept - Ira's Dagger"),
    "skipping the dagger keeps the main spider circuit available")
end

function S.questDuskwoodHandoff()
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 25, 1431, 23.8, 36.5
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "duskwood" then
      for _, step in ipairs(section.steps) do
        if step.quest and step.quest ~= 133 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 133, objectives = { { text = "Ghoul Ribs 6/7" } } } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Ghoul Ribs 6/7"), "resume the final Duskwood quest")
  MOCK.questDone[133], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 133)
  check(questText(frame, "Reach level 26 for Wetlands"), "an underleveled handoff shows the catch-up step")
  MOCK.level = 26
  MOCK.event("PLAYER_LEVEL_UP", 26)
  check(questText(frame, "Hearth to Darkshire") and questText(frame, "Felicia Maline") and questText(frame, "flight to Stormwind"),
    "at level 26 the route names the return, flight master and onward flight")
end

function S.questSouthshoreForebodingPlans()
  MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = 33, 1424, 48.14, 59.11
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "hillsbrad-32" then
      for _, step in ipairs(section.steps) do
        if step.quest == 505 and step.type == "turnin" then break end
        if step.quest and step.quest ~= 505 and step.quest ~= 510 and step.quest ~= 564 then
          MOCK.questDone[step.quest] = true
        end
      end
    end
  end
  MOCK.questLog = { { questID = 505, isComplete = true }, { questID = 564, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Syndicate Assassins"), "resume at Maleb with Syndicate Assassins ready")

  table.remove(MOCK.questLog, 1)
  MOCK.questDone[505] = true
  MOCK.event("QUEST_TURNED_IN", 505)
  check(questText(frame, "Turn in - Costly Menace") and not questText(frame, "Turn in - Foreboding Plans"),
    "the Southshore route passes Maleb's hand-in if Foreboding Plans was never picked up: " .. allText(frame))
  click(frame, "Back")
  check(questText(frame, "Pick up this quest first."), "reviewing the hand-in explains why it is unavailable")
  click(frame, "Next")
  questQueue("Missed quests")
  check(questText(win(), "Foreboding Plans"), "the earlier pickup in Alterac is available under Missed pickups")

  MOCK.questLog[#MOCK.questLog + 1] = { questID = 510, isComplete = true }
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Turn in - Foreboding Plans"), "Maleb's hand-in returns once Foreboding Plans is in the log")
  table.remove(MOCK.questLog)
  MOCK.questDone[510] = true
  MOCK.event("QUEST_TURNED_IN", 510)
  check(questText(frame, "Turn in - Costly Menace"), "turning in the plans advances the Southshore route")
end

function S.questBrackenwallVenom()
  local checked = 0
  for _, section in ipairs(LevelingCodexQuests.HORDE.sections) do
    if section.id == "dustwallow-37" or section.id == "dustwallow-33" then
      local objectives, positions = {}, {}
      for index, step in ipairs(section.steps) do
        if step.type == "complete" and step.quest then
          objectives[step.quest], positions[step.quest] = step, index
        end
      end
      local spies, shield, eyes = objectives[1201], objectives[1322], objectives[1206]
      check(spies and shield and eyes and positions[1322] == positions[1201] + 1,
        section.id .. " collects venom while the player is near the Theramore Infiltrators")
      check(spies.also and spies.also[1] == 1322 and not eyes.also,
        section.id .. " shows venom progress with the infiltrators and keeps Jarl's hunt separate")
      check(shield.mobs and shield.mobs[1] == "Darkfang Venomspitter",
        section.id .. " targets Darkfang spiders at the venom stop")
      check(shield.objectives[1] == "6 Acidic Venom Sacs" and eyes.objectives[1] == "40 Unpopped Darkmist Eyes",
        section.id .. " shows the Forever quest counts before live progress loads")
      checked = checked + 1
    end
  end
  check(checked == 2, "both Horde Brackenwall routes are covered")
end

function S.questHordeMissedPickup()
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 48
  MOCK.questMap, MOCK.questX, MOCK.questY = 1424, 61.44, 19.06
  for _, section in ipairs(LevelingCodexQuests.HORDE.sections) do
    if section.id == "hinterlands-48" then
      for _, step in ipairs(section.steps) do
        if step.quest == 7816 and step.type == "turnin" then break end
        if step.quest and step.quest ~= 7816 and step.quest ~= 2933 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 7816, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Gammerita, Mon!"), "resume at the preceding hand-in")
  MOCK.questLog, MOCK.questDone[7816] = {}, true
  MOCK.event("QUEST_TURNED_IN", 7816)
  if questTextStarts(frame, "Fly to Tarren Mill.") then click(frame, "Next") end
  check(questText(frame, "Accept - Venom Bottles") and not questText(frame, "Turn in - Venom Bottles"),
    "recover the missed pickup before sending the player to Lydon: " .. allText(frame))
  check(not questText(frame, "Complete - Undamaged Venom Sac"), "do not preview an objective for an unaccepted follow-up")

  MOCK.questLog = { { questID = 2933, isComplete = true } }
  MOCK.event("QUEST_ACCEPTED", 1, 2933)
  check(questText(frame, "Turn in - Venom Bottles"), "a real quest in the log can be turned in")
  MOCK.questLog, MOCK.questDone[2933] = {}, true
  MOCK.event("QUEST_TURNED_IN", 2933)
  check(questText(frame, "Accept - Undamaged Venom Sac"), "the actual hand-in unlocks the follow-up")
end

function S.questLakeshireHandoff()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 22, 1433, "Lakeshire"
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "lakeshire" then
      for _, step in ipairs(section.steps) do
        if step.quest and step.quest ~= 20 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 20, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Blackrock Menace"), "resume at the last Lakeshire turn-in")
  check(questText(frame, "Next section: Duskwood"), "the last Lakeshire step names the next section")
  MOCK.questDone[20], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 20)
  check((questText(frame, "Duskwood") and questText(frame, "Levels 21-27")) and questText(frame, "Flight path - Darkshire"),
    "the final turn-in leads straight to Duskwood")
end

function S.questDuskwoodZoneEntry()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 20, 1433, "Lakeshire"
  LevelingCodexCharDB = { questFlights = { ["Lakeshire, Redridge"] = true, ["Darkshire, Duskwood"] = true } }
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "lakeshire" then
      for _, step in ipairs(section.steps) do
        if step.quest and step.quest ~= 20 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 20, isComplete = true } }
  S.login()
  local frame = questViewer()
  -- Select the section so its return-to-town step is current before turning in.
  slash("quests")
  clickGuide("Lakeshire")
  check(questText(win(), "You are on this route."), "Lakeshire's page says you're on it")
  click(win(), "First open step")
  check(questText(frame, "Return to Lakeshire"), "the guide is still on the Lakeshire hearth step")

  MOCK.questMap, MOCK.questX, MOCK.questY = 1431, 77.7, 44.4
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check((questText(frame, "Duskwood") and questText(frame, "Levels 21-27")) and not questText(frame, "Return to Lakeshire"),
    "walking into Duskwood switches to local pickups even without an accepted quest there")
  check(questText(frame, "Bind hearthstone") and questText(frame, "Accept - The Totem of Infliction"),
    "Duskwood starts with the next local steps, including pickups available at level 20")

  MOCK.event("ZONE_CHANGED_NEW_AREA") -- Sometimes the map still shows the old zone during the event.
  MOCK.questMap, MOCK.questX, MOCK.questY = 1433, 25, 40
  MOCK.advance(0.5)
  check((questText(frame, "Lakeshire") and questText(frame, "Levels 17-22")) and questText(frame, "Turn in - Blackrock Menace"),
    "a delayed map update still resumes the old zone's unfinished turn-in")
  check(next(LevelingCodexCharDB.questSkips) == nil, "changing zones does not skip any quest permanently")
end

function S.questItem()
  S.login()
  local frame = questViewer()
  check(not (_G.LevelingCodexQuestItem and _G.LevelingCodexQuestItem:IsShown()), "no item button without a quest item")
  MOCK.bags["Nibbled-On Book"] = 1
  click(frame, "Next")
  check(questText(frame, "Accept - Nibbled-On Book"), "the book step is current")
  local button = _G.LevelingCodexQuestItem
  check(button and button:IsShown(), "the step's item gets a button")
  check(button._secure and button:GetAttribute("type") == "item" and button:GetAttribute("item") == "Nibbled-On Book",
    "the secure button uses the step's item")
  hover(button)
  MOCK.combat = true
  MOCK.bags["Nibbled-On Book"] = 0
  MOCK.event("BAG_UPDATE_DELAYED")
  check(button:IsShown(), "the button waits for the end of combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(not button:IsShown(), "after combat the used-up item's button goes")
  click(frame, "Back")
  MOCK.questLog = { { questID = 783 } }
  MOCK.questItems[1] = { "|cffffffff|Hitem:5555::::|h[Thing]|h|r", 134400 }
  MOCK.bags[5555] = 2
  MOCK.event("QUEST_ACCEPTED", 1, 783)
  check(questText(frame, "A Threat Within"), "the quest in the log is current")
  check(button:IsShown() and button:GetAttribute("item") == "item:5555", "the quest log's own usable item is used")
  check(button.count._text == "2", "the button shows how many you carry")
  LevelingCodexDB.noQuestItem = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not button:IsShown(), "the setting hides the button")
end

local function questButtonFixture()
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = { { text = "Kobold Vermin 4/10", numFulfilled = 4, numRequired = 10 } } } }
  MOCK.questItems[1] = { "|cffffffff|Hitem:5555::::|h[Thing]|h|r", 134400 }
  MOCK.bags[5555] = 2
  S.login()
  local item, target = _G.LevelingCodexQuestItem, _G.LevelingCodexQuestTarget
  check(item and item:IsShown() and target and target:IsShown(), "both quest buttons are available")
  return questViewer(), item, target
end

local function questOffsetSlider(label)
  local function find(root)
    for _, child in ipairs({ root:GetChildren() }) do
      if child:IsShown() then
        if child:GetObjectType() == "Slider" and child.codexLabel == label then return child end
        local found = find(child)
        if found then return found end
      end
    end
  end
  local slider = find(win())
  check(slider, "offset slider is available: " .. label)
  return slider
end

function S.questButtonOptions()
  local frame, item, target = questButtonFixture()
  slash("")
  click(win(), "Settings")
  click(win(), "Quest item position: Right")
  check(item:GetLeft() ~= nil and select(1, item:GetPoint()) == "TOPLEFT", "item can move to the right")
  check(select(1, target:GetPoint()) == "TOPRIGHT", "target keeps its own left placement")
  local _, parent, _, x, y = item:GetPoint()
  check(parent == UIParent, "secure buttons stay independent of the movable step window")
  local slider = questOffsetSlider("Quest item horizontal offset")
  slider:SetValue(37)
  local _, _, _, movedX = item:GetPoint()
  check(math.abs(movedX - x - 37) < 0.001, "horizontal slider moves the item immediately")
  questOffsetSlider("Quest item vertical offset"):SetValue(-23)
  check(math.abs(select(5, item:GetPoint()) - y + 23) < 0.001, "vertical slider moves the item immediately")
  click(win(), "Target position: Bottom")
  check(select(1, target:GetPoint()) == "TOPLEFT", "target can move below the panel")
  click(win(), "Quest item position: Bottom")
  questOffsetSlider("Quest item horizontal offset"):SetValue(0)
  questOffsetSlider("Quest item vertical offset"):SetValue(0)
  local _, _, _, ix, iy = item:GetPoint()
  local _, _, _, tx, ty = target:GetPoint()
  check(tx >= ix + item:GetWidth() and math.abs(iy - ty) < 0.001, "bottom buttons sit side by side without overlapping")
  click(win(), "Target position: Top")
  check(select(1, target:GetPoint()) == "BOTTOMLEFT", "target can move above the panel")
  click(win(), "Show the quest item button")
  check(not item:IsShown() and target:IsShown(), "item can be disabled independently")
  click(win(), "Show the target button")
  check(not target:IsShown(), "target can be disabled independently")
  slash("quests")
  click(win(), "Setup")
  click(win(), "Map and step window")
  check(not findButton(win(), function(l) return l == "Show the quest item button" end):GetChecked(), "setup shares the item toggle")
  click(win(), "Show the quest item button")
  click(win(), "Show the target button")
  check(item:IsShown() and target:IsShown(), "setup can turn both buttons back on")
  click(win(), "Quest item position: Top")
  check(select(1, item:GetPoint()) == "BOTTOMLEFT", "setup can place the item above the panel")
  questOffsetSlider("Target horizontal offset"):SetValue(-41)
  questOffsetSlider("Target vertical offset"):SetValue(19)
  click(win(), "Target horizontal offset +")
  check(questOffsetSlider("Target horizontal offset"):GetValue() == -36, "offset steppers move by 5 pixels")
  click(win(), "Reset quest item position")
  check(select(1, item:GetPoint()) == "TOPRIGHT", "reset returns the item to the left")
  click(win(), "Reset target position")
  check(select(1, target:GetPoint()) == "TOPRIGHT" and questOffsetSlider("Target horizontal offset"):GetValue() == 0,
    "reset clears the target's placement and offsets")
  -- The protected buttons must stay where they were until combat ends.
  local _, _, _, oldX, oldY = target:GetPoint()
  MOCK.combat = true
  MOCK.event("PLAYER_REGEN_DISABLED")
  click(win(), "Target position: Right")
  questOffsetSlider("Target horizontal offset"):SetValue(75)
  check(select(1, target:GetPoint()) == "TOPRIGHT" and select(4, target:GetPoint()) == oldX
    and select(5, target:GetPoint()) == oldY, "placement changes wait through combat")
  click(win(), "Show the quest item button")
  check(item:IsShown(), "hiding the secure item button also waits through combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(select(1, target:GetPoint()) == "TOPLEFT" and not item:IsShown(), "pending placement and visibility apply after combat")
  click(win(), "Show the quest item button")
  win():Hide()
  frame:Hide()
  check(not item:IsShown() and not target:IsShown(), "hiding the guide hides the repositioned buttons")
end

function S.questButtonSavedLayout()
  LevelingCodexDB = { questViewerScale = 0.7, questItemLayout = { side = "right", x = 24, y = -17 },
    questTargetLayout = { side = "bottom", x = -30, y = 11 } }
  local frame, item, target = questButtonFixture()
  local _, _, _, x, y = item:GetPoint()
  check(select(1, item:GetPoint()) == "TOPLEFT" and math.abs(x - ((frame:GetLeft() + frame:GetWidth()) * 0.7 + 6 + 24)) < 0.001
    and math.abs(y - ((frame:GetTop() - 26) * 0.7 - 17)) < 0.001, "saved right placement follows the scaled panel")
  local _, _, _, tx, ty = target:GetPoint()
  check(math.abs(tx - (frame:GetLeft() * 0.7 + 56 - 30)) < 0.001
    and math.abs(ty - ((frame:GetTop() - frame:GetHeight()) * 0.7 - 10 + 11)) < 0.001, "bottom placement follows the scaled panel height")
  frame._left, frame._top = 200, 600
  MOCK.fire(frame, "OnDragStop")
  check(math.abs(select(4, item:GetPoint()) - ((200 + frame:GetWidth()) * 0.7 + 30)) < 0.001,
    "buttons follow the panel when it is dragged")
  slash("")
  click(win(), "Settings")
  click(win(), "Compact step window")
  check(math.abs(select(5, target:GetPoint()) - ((600 - frame:GetHeight()) * 0.7 + 1)) < 0.001,
    "bottom placement follows compact mode's new height")
end

function S.questButtonInvalidLayout()
  LevelingCodexDB = { questItemLayout = "invalid", questTargetLayout = { side = "elsewhere", x = 99999, y = "bad" } }
  local _, item, target = questButtonFixture()
  check(select(1, item:GetPoint()) == "TOPRIGHT" and select(1, target:GetPoint()) == "TOPRIGHT", "invalid sides fall back to the left")
  slash("")
  click(win(), "Settings")
  check(questOffsetSlider("Quest item horizontal offset"):GetValue() == 0
    and questOffsetSlider("Target horizontal offset"):GetValue() == UIParent:GetWidth()
    and questOffsetSlider("Target vertical offset"):GetValue() == 0, "invalid offsets fall back or clamp to the slider range")
end

-- Move the handle as the client does: StartMoving may change its anchor, and the final
-- screen edges are what the player dropped. The mock's default GetLeft/GetTop are fixed.
local function dragQuestHandle(handle, dx, dy)
  check(handle and handle:IsShown(), "quest button drag handle is visible")
  local point, _, _, x, y = handle:GetPoint()
  local left = point == "TOPRIGHT" and x - handle:GetWidth() or x
  local top = point == "BOTTOMLEFT" and y + handle:GetHeight() or y
  MOCK.fire(handle, "OnDragStart", "LeftButton")
  check(handle._moving, "the handle starts moving")
  handle._left, handle._top = left + dx, top + dy
  MOCK.fire(handle, "OnDragStop")
  check(not handle._moving, "the handle stops moving")
end

function S.questButtonDragging()
  local frame, item, target = questButtonFixture()
  slash("")
  click(win(), "Settings")
  click(win(), "Unlock button dragging")
  local itemMover, targetMover = _G.LevelingCodexQuestItemMover, _G.LevelingCodexQuestTargetMover
  check(itemMover and itemMover:IsShown() and targetMover and targetMover:IsShown(), "unlock shows both drag handles")
  check(not itemMover._secure and not targetMover._secure, "handles do not use the item or target action")
  local _, _, _, x, y = item:GetPoint()
  local targetX, targetY = select(4, target:GetPoint()), select(5, target:GetPoint())
  dragQuestHandle(itemMover, 540, -61)
  check(math.abs(select(4, item:GetPoint()) - x - 540) < 0.001 and math.abs(select(5, item:GetPoint()) - y + 61) < 0.001,
    "dropping the item handle moves only its button, including beyond the old slider range")
  check(select(4, target:GetPoint()) == targetX and select(5, target:GetPoint()) == targetY, "item dragging leaves the target in place")
  check(questOffsetSlider("Quest item horizontal offset"):GetValue() == 540
    and questOffsetSlider("Quest item vertical offset"):GetValue() == -61, "dragged offsets appear in Settings")
  check(item:GetAttribute("type") == "item" and target:GetAttribute("type") == "macro", "dragging preserves normal button actions")
  slash("quests")
  click(win(), "Setup")
  click(win(), "Map and step window")
  check(findButton(win(), function(l) return l == "Lock button dragging" end), "setup shares the unlock state")
  click(win(), "Target position: Bottom")
  local _, _, _, bottomX, bottomY = target:GetPoint()
  dragQuestHandle(targetMover, -120, 85)
  check(select(4, target:GetPoint()) == bottomX - 120 and select(5, target:GetPoint()) == bottomY + 85, "bottom handle saves the drop with its own anchor")
  click(win(), "Target position: Top")
  local _, _, _, topX, topY = target:GetPoint()
  dragQuestHandle(targetMover, 13, -17)
  check(select(4, target:GetPoint()) == topX + 13 and select(5, target:GetPoint()) == topY - 17, "top handle saves the button's bottom anchor")
  local savedX = select(4, item:GetPoint())
  frame._left = frame:GetLeft() + 60
  MOCK.fire(frame, "OnDragStop")
  check(select(4, item:GetPoint()) == savedX + 60, "dragged buttons still follow the step panel")
  MOCK.combat = true
  MOCK.event("PLAYER_REGEN_DISABLED")
  check(not itemMover:IsShown() and not targetMover:IsShown(), "combat hides drag handles")
  MOCK.fire(itemMover, "OnDragStart", "LeftButton")
  check(not itemMover._moving, "dragging is blocked in combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(itemMover:IsShown() and targetMover:IsShown(), "drag handles return after combat")
  MOCK.fire(itemMover, "OnDragStart", "LeftButton")
  MOCK.combat = true
  MOCK.event("PLAYER_REGEN_DISABLED")
  check(not itemMover._moving and not itemMover:IsShown(), "entering combat cancels an active drag")
  click(win(), "Lock button dragging")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(not itemMover:IsShown() and not targetMover:IsShown(), "locking in combat keeps the handles hidden afterward")
  click(win(), "Reset quest item position")
  check(select(4, item:GetPoint()) == frame:GetLeft() - 6, "reset clears dragged offsets")
  click(win(), "Unlock button dragging")
  frame:Hide()
  check(not itemMover:IsShown() and not targetMover:IsShown(), "hiding the guide also hides its drag handles")
end

function S.questButtonDragPreview()
  S.login()
  slash("")
  click(win(), "Settings")
  click(win(), "Unlock button dragging")
  local mover = _G.LevelingCodexQuestItemMover
  check(mover and mover:IsShown() and not (_G.LevelingCodexQuestItem and _G.LevelingCodexQuestItem:IsShown()),
    "the item can be positioned without an item on the current step")
  dragQuestHandle(mover, 80, -42)
  check(LevelingCodexDB.questItemLayout.x == 80 and LevelingCodexDB.questItemLayout.y == -42, "preview drag saves offsets")
  click(win(), "Lock button dragging")
  check(not mover:IsShown(), "lock removes the preview")
  if not MOCK.minimal then
    MOCK.bags["Nibbled-On Book"] = 1
    click(questViewer(), "Next")
    local item = _G.LevelingCodexQuestItem
    check(item and item:IsShown() and select(4, item:GetPoint()) == questViewer():GetLeft() - 6 + 80,
      "a quest item appearing later uses its dragged position")
  end
end

function S.questButtonMinimalLayout()
  S.login()
  local target = _G.LevelingCodexQuestTarget
  check(target and target:IsShown(), "target works without optional APIs")
  slash("")
  click(win(), "Settings")
  click(win(), "Target position: Right")
  check(select(1, target:GetPoint()) == "TOPLEFT", "minimal client can reposition the target")
  questOffsetSlider("Target horizontal offset"):SetValue(18)
  click(win(), "Show the target button")
  check(not target:IsShown(), "minimal client can hide the target")
  slash("quests")
  click(win(), "Setup")
  click(win(), "Map and step window")
  click(win(), "Show the target button")
  check(target:IsShown(), "minimal setup shares the visibility option")
end

function S.questButtonController()
  LevelingCodexDB = { padNative = false }
  MOCK.gamepadUI = true
  S.login()
  slash("")
  click(win(), "Settings")
  local function press(button) MOCK.fire(win(), "OnGamePadButtonDown", button) end
  local function adjust()
    local minus, plus = "Quest item horizontal offset -", "Quest item horizontal offset +"
    -- Changing tabs keeps the closest focus position, which can be below this row.
    for _ = 1, 100 do press("PADDUP") end
    for _ = 1, 100 do
      local focused = LevelingCodexPadFocus and LevelingCodexPadFocus.target
      if focused and (labelOf(focused) == minus or labelOf(focused) == plus) then break end
      press("PADDDOWN")
    end
    check(LevelingCodexPadFocus and (labelOf(LevelingCodexPadFocus.target) == minus or labelOf(LevelingCodexPadFocus.target) == plus),
      "D-pad reaches the offset adjustment row")
    if labelOf(LevelingCodexPadFocus.target) == minus then press("PADDRIGHT") end
    check(labelOf(LevelingCodexPadFocus.target) == plus, "D-pad selects the plus button")
    local before = questOffsetSlider("Quest item horizontal offset"):GetValue()
    press("PAD1")
    check(questOffsetSlider("Quest item horizontal offset"):GetValue() == before + 5, "controller A adjusts the offset")
  end
  adjust()
  slash("quests")
  click(win(), "Setup")
  click(win(), "Map and step window")
  adjust()
  press("PAD2")
  check(not win():IsShown(), "controller B closes setup")
end

function S.questRace()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 13, 1436
  S.login()
  slash("quests")
  check(not routeHas("A Swift Message"), "Human-only quests are left out for other races")
end

function S.questRaceHuman()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 13, 1436
  S.login()
  slash("quests")
  check(routeHas("A Swift Message"), "Humans keep the Swift Message chain")
end

function S.questPassed()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 15, 1436
  local requested, loaded
  QueryQuestsCompleted = function() requested = true end
  GetQuestsCompleted = function(completed)
    if loaded then completed[102] = true end
  end
  C_QuestLog.GetAllCompletedQuestIDs = function() return {} end
  S.login()
  loaded = true
  MOCK.event("QUEST_QUERY_COMPLETE")
  QueryQuestsCompleted, GetQuestsCompleted = nil, nil
  check(requested, "classic history is requested when both APIs are available")
  local frame = questViewer()
  check(not questText(frame, "Accept - Report to Gryan Stoutmantle"), "a pickup you moved past is not the current step")
  check(questText(frame, "Accept - Westfall Stew"), "a pickup a later quest still needs stays current")
  slash("quests")
  questQueue("Missed quests")
  check(questText(win(), "The Forgotten Heirloom"), "passed pickups are listed under Missed quests")
end

function S.questBreadcrumb()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 13, 1436
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    for _, step in ipairs(section.steps) do
      if step.quest == 109 then step.breadcrumb = 12 end
    end
  end
  MOCK.questLog = { { questID = 12 } }
  S.login()
  local frame = questViewer()
  check(not questText(frame, "Report to Gryan Stoutmantle"), "a breadcrumb drops off once its follow-up is in the log")
  check(questText(frame, "Accept - The Forgotten Heirloom"), "the route continues with the next pickup")
end

-- Verification notes (`uncertain`) are for us, not players: the owner doesn't want "Check in game"
-- notes in the step window or the route list (2026-11-13), like the old Unverified label.
function S.questNoCheckNotes()
  MOCK.race, MOCK.level = "Human", 1
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      for _, step in ipairs(section.steps) do step.uncertain = "Confirm this NPC's spot." end
    end
  end
  S.login()
  local frame = questViewer()
  check(questText(frame, "Northshire"), "the Northshire step is shown: " .. allText(frame))
  check(not questText(frame, "Check in game") and not questText(frame, "Confirm this NPC's spot"),
    "no verification note in the step window: " .. allText(frame))
  slash("quests")
  check(not questText(win(), "Check in game") and not questText(win(), "Confirm this NPC's spot"),
    "no verification note on the Quests tab")
end

function S.questWetlands()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.quest == 633 and step.type == "turnin" then
          check(not step.text:lower():find("swim"), "the Thandol return crosses the bridge instead of swimming beneath it")
        end
      end
    end
  end
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 28, 1437
  S.login()
  local frame = questViewer()
  check((questText(frame, "Wetlands") and questText(frame, "Levels 26-30")), "a level 28 in the Wetlands follows the Wetlands section")
  check(questText(frame, "Accept - Tramping Paws"), "the trip there is skipped once you are in the Wetlands: " .. allText(frame))

  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.quest and step.quest ~= 98221 and step.quest ~= 464 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  local plans = { { text = "Menethil Harbor 0/1" }, { text = "Thelsamar 0/1" },
    { text = "Southshore 1/1", finished = true }, { text = "Ironforge 0/1" } }
  MOCK.questLog = { { questID = 98221, objectives = plans },
    { questID = 464, objectives = { { text = "Dragonmaw War Banners 3/8" } } } }
  MOCK.questX, MOCK.questY = 38.46, 46.02
  MOCK.event("QUEST_LOG_UPDATE")
  slash("quests")
  stepTool("Resume active quest")
  check(questText(frame, "Ironforge 0/1") and questText(LevelingCodexQuestArrow, "Arrived"),
    "Angerfang starts at the western Ironforge plan even though it is fourth in the quest log")
  check(questText(frame, "Dragonmaw War Banners 3/8"), "show banner progress during the plan sweep")
  plans[4].finished = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Menethil Harbor 0/1"), "the next plan has its own objective")
  plans[1].finished = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Thelsamar 0/1"), "the route passes the already-destroyed Southshore plan")
end

function S.questWetlandsTravel()
  -- Redridge, not Duskwood: at 28 Duskwood now offers the Darkshire chapter's first pickups.
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 28, 1433
  S.login()
  local frame = questViewer()
  check(questText(frame, "Fly - Stormwind, Elwynn"), "from Redridge the Wetlands section starts with the way there")
  click(frame, "Next")
  check(questText(frame, "The Doomed Fleet"), "Bishop Farthing's pickup in Stormwind follows the flight")
  click(frame, "Next")
  check(questText(frame, "Deeprun Tram"), "the tram step follows the Stormwind pickup")
end

local function wetlandsRidgeQuests()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 28, 1437, 63, 41.8
  local keep = { [98245] = true, [98246] = true, [98072] = true, [98283] = true }
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.quest and not keep[step.quest] then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = {
    { questID = 98245, objectives = { { text = "Razormaw Incisor: 3/10" } } },
    { questID = 98246, objectives = { { text = "Perfect Razormaw Egg: 4/12" } } },
    { questID = 98072, objectives = { { text = "Pristine Crimson Scale: 5/8" } } },
    { questID = 98283, objectives = { { text = "Malignant Rotclaw Flesh: 0/1" }, { text = "Carnage's Head: 0/1" } } },
  }
end

function S.questWetlandsRidgeLoop()
  wetlandsRidgeQuests()
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  for _, text in ipairs({ "Razormaw Incisor", "Perfect Razormaw Egg", "Pristine Crimson Scale", "Malignant Rotclaw Flesh" }) do
    check(questText(frame, text), "the ridge loop tracks all overlapping objectives: " .. text .. " / " .. allText(frame))
  end
  check(questText(frame, "whelps") and questText(frame, "Raptor Ridge"), "loop instructions connect the slope and ridge")
end

function S.questWetlandsCarnageChoice()
  wetlandsRidgeQuests()
  MOCK.questDone = {}
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.quest == 98283 then break end
        if step.quest and step.quest ~= 98072 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { MOCK.questLog[3], { questID = 275, isComplete = true } }
  MOCK.questDone[98245], MOCK.questDone[98246] = true, true
  MOCK.questDone[275] = nil
  MOCK.questX, MOCK.questY = 56.37, 40.4
  S.login()
  local frame = questViewer()
  slash("quests")
  stepTool("Resume active quest")
  check(questText(frame, "Turn in - Blisters on The Land"), "Rethiel takes the preceding quest first: " .. allText(frame))
  table.remove(MOCK.questLog, 2)
  MOCK.questDone[275] = true
  MOCK.event("QUEST_TURNED_IN", 275)
  check(questText(frame, "Elite quest - Carnage") and hasButton(frame, "Take it") and hasButton(frame, "Skip"),
    "Carnage is offered at Rethiel through the elite choice: " .. allText(frame))
  click(frame, "Skip")
  check(LevelingCodexCharDB.questElite[98283] == false and questText(frame, "Pristine Crimson Scale"),
    "skipping Carnage keeps the shared whelp loop available")
end

function S.questWetlandsCarnageSummon()
  wetlandsRidgeQuests()
  for _, id in ipairs({ 98245, 98246, 98072 }) do MOCK.questDone[id] = true end
  MOCK.questLog = { { questID = 98283, objectives = {
    { text = "Malignant Rotclaw Flesh: 1/1", finished = true }, { text = "Carnage's Head: 0/1" },
  } } }
  MOCK.bags[280331] = 1
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Offering Stone") and questText(frame, "69.5, 34.7"), "Carnage's instructions identify the cave entrance and summon point")
  local item, target = LevelingCodexQuestItem, LevelingCodexQuestTarget
  check(item and item:IsShown() and item:GetAttribute("item") == "item:280331", "Carnage has a usable flesh button")
  check(target and target:GetAttribute("macrotext") == "/targetexact Carnage", "the summon step targets Carnage rather than the bait bears")
end

function S.questWetlandsEarly()
  -- The 20-25 Wetlands chapter starts in Menethil Harbor, where the Auberdine ship lands, and
  -- takes Fitzsimmons' Greenwarden breadcrumb as a normal step (it is optional in the 26-30 route).
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "NightElf", 21, 1437, 9.6, 59.8
  S.login()
  local frame = questViewer()
  check(questText(frame, "Levels 20-25"), "a level 21 in Menethil follows the early Wetlands chapter")
  check(questText(frame, "Flight path - Menethil Harbor, Wetlands"), "the early chapter starts at the Menethil flight master")
  click(frame, "Next")
  MOCK.bind = "Menethil Harbor"
  MOCK.event("HEARTHSTONE_BOUND")
  check(questText(frame, "Accept - The Absent Minded Prospector"), "the Menethil pickups follow the bind")
  click(frame, "Next")
  check(questText(frame, "Accept - The Greenwarden"), "the Greenwarden breadcrumb is a normal step in the early chapter")
end

function S.questWetlandsAfterEarly()
  -- The 26-30 Wetlands route after the 20-25 chapter (2026-11-12 audit): the early chapter turns in
  -- many quests the 26-30 route also has. Those turn-ins say nothing about the 26-30 route's own
  -- earlier pickups, so Howin's quests and the rest must not go to Missed quests.
  MOCK.race, MOCK.level, MOCK.bind = "Human", 27, "Menethil Harbor"
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "duskwood" or section.id == "wetlands-early" then
      for _, step in ipairs(section.steps) do
        if step.quest and not step.optional then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questMap, MOCK.questX, MOCK.questY = 1437, 49.4, 42.2
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - Blisters on The Land"), "after the early chapter, the Greenwarden chain continues before the coast: " .. allText(frame))
  slash("quests")
  questQueue("Missed quests")
  for _, name in ipairs({ "Razormaw Needling", "Trying Times", "War Banners", "Apprentice's Duties" }) do
    check(not questText(win(), name), name .. " is still on the route, not missed: " .. allText(win()))
  end
end

function S.questWetlandsHarloPickup()
  MOCK.race, MOCK.level, MOCK.bind = "Skyborne", 29, "Menethil Harbor"
  MOCK.questMap, MOCK.questX, MOCK.questY = 1437, 10.85, 55.90
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.quest == 631 then break end
        if step.quest and step.quest ~= 472 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - Fall of Dun Modr"), "Harlo's pickup stays available at the harbor after completing the raptor quests: " .. allText(frame))
  click(frame, "Next")
  MOCK.event("QUEST_LOG_UPDATE")
  check(not questText(frame, "Accept - Fall of Dun Modr"), "Next still skips Harlo's pickup")
end

function S.questTheramoreArrival()
  MOCK.race, MOCK.level = "Human", 33
  MOCK.questMap, MOCK.questX, MOCK.questY = 1437, 5.1, 63.4
  S.login()
  slash("quests")
  clickGuide("Theramore and the Shimmering Flats")
  local frame = questViewer()
  check(questText(frame, "Menethil Harbor - Theramore Isle"), "the crossing starts at Menethil")
  walkTo(1445, 67.5, 51.3)
  check(questText(frame, "Theramore and the Shimmering Flats") and not questText(frame, "Menethil Harbor - Theramore Isle"),
    "landing in Theramore continues the selected Shimmering Flats route: " .. allText(frame))
  slash("quests")
  clickGuide("Theramore and the Shimmering Flats")
  check(not questText(frame, "Menethil Harbor - Theramore Isle"), "starting the route at the dock skips the completed crossing")
end

function S.questBootyBayArrival()
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 50
  MOCK.questMap, MOCK.questX, MOCK.questY = 1413, 63.7, 38.6
  MOCK.questDone[2873] = true
  MOCK.questLog = { { questID = 2874, isComplete = true } }
  S.login()
  slash("quests")
  clickGuide("Booty Bay, Stonard and the Blasted Lands")
  local frame = questViewer()
  check(questText(frame, "Ratchet - Booty Bay"), "the delivery route starts on the boat in Ratchet")
  walkTo(1434, 25.8, 73.1)
  check(questText(frame, "Turn in - Deliver to MacKinley"), "MacKinley is the next step after docking: " .. allText(frame))
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Turn in - Deliver to MacKinley"), "the turn-in stays current without pressing Next")
end

function S.questSkycutterDalaranJoin()
  MOCK.race, MOCK.level = "Skyborne", 12
  MOCK.questMap, MOCK.questX, MOCK.questY = 1416, 12.3, 56.3
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "valanaar" then
      for _, step in ipairs(section.steps) do
        if step.quest == 94946 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 94946, isComplete = true } }
  S.login()
  slash("quests")
  clickGuide("Valanaar")
  local frame = questViewer()
  check(questTextStarts(frame, "Turn in to Denaaris Stargale"),
    "starting Valanaar at the Dalaran dock leads to Denaaris: " .. allText(frame))
end

function S.questRagefireZeppelinRoundTrip()
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 14
  MOCK.questMap, MOCK.questX, MOCK.questY = 1458, 56.25, 92.2
  MOCK.questLog = { { questID = 5722 }, { questID = 5723 }, { questID = 5726, isComplete = true } }
  S.login()
  slash("quests")
  guidesView("Dungeons")
  click(win(), "Ragefire Chasm")
  click(win(), "Follow this guide")
  local frame = questViewer()
  check(questTextStarts(frame, "Enter the Undercity"), "joining in the Undercity leads to Varimathras: " .. allText(frame))
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 5725 }
  MOCK.event("QUEST_ACCEPTED", #MOCK.questLog, 5725)
  check(questTextStarts(frame, "Leave the Undercity and take the zeppelin"),
    "accepting the books quest keeps the return zeppelin: " .. allText(frame))
  walkTo(1411, 50.8, 13.8)
  check(questTextStarts(frame, "Bring the insignia to Thrall"),
    "landing in Durotar advances the return leg to Thrall: " .. allText(frame))
end

function S.questHordeCozyWestfallJoin()
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 25
  MOCK.questMap, MOCK.questX, MOCK.questY = 1436, 37.3, 89.2
  MOCK.questLog = { { questID = 79007, isComplete = true } }
  S.login()
  slash("quests")
  guidesView("Special")
  click(win(), "Cozy Sleeping Bag")
  click(win(), "Follow this guide")
  local frame = questViewer()
  check(questTextStarts(frame, "Search the Burned-Out Remains in the burned field"),
    "joining in Westfall leads to the farmstead: " .. allText(frame))
end

function S.questWinterspringIronforgeJoin()
  MOCK.race, MOCK.level = "Human", 56
  MOCK.questMap, MOCK.questX, MOCK.questY = 1455, 55.5, 47.7
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "winterspring-55" then
      for _, step in ipairs(section.steps) do
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  S.login()
  slash("quests")
  clickGuide("Winterspring: Everlook and the Southern Valleys")
  local frame = questViewer()
  check(not questTextStarts(frame, "Walk back through Timbermaw Hold")
      and not questTextStarts(frame, "Fly to Auberdine") and not questText(frame, "Auberdine - Menethil Harbor"),
    "restarting from Ironforge passes the earlier travel legs: " .. allText(frame))
end

function S.questHillsbradThunderBluffJoin()
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 24
  MOCK.questMap, MOCK.questX, MOCK.questY = 1456, 47, 49.82
  LevelingCodexCharDB = { questFlights = { ["Tarren Mill, Hillsbrad"] = true } }
  for _, section in ipairs(LevelingCodexQuests.HORDE.sections) do
    if section.id == "hillsbrad" then
      for _, step in ipairs(section.steps) do
        if step.quest and step.quest ~= 1067 and step.quest ~= 1086 then MOCK.questDone[step.quest] = true end
      end
    end
  end
  MOCK.questLog = { { questID = 1067, isComplete = true } }
  S.login()
  slash("quests")
  clickGuide("Hillsbrad Foothills")
  local frame = questViewer()
  check(not questTextStarts(frame, "Leave the Undercity and take the Durotar zeppelin"),
    "joining in Thunder Bluff skips the older zeppelin leg: " .. allText(frame))
  check(questText(frame, "Turn in - Return to Thunder Bluff"), "Zamah's local hand-in is available: " .. allText(frame))
end

function S.questStranglethornRoad()
  -- A 30-60 map: the arrow knows its size, and from Duskwood it names the road south.
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 37, 1434, 38.5, 5.0
  -- Everything the route picks up before this point is done.
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if not section.side and not section.alternate then
      for _, step in ipairs(section.steps) do
        if section.id == "stv-36" and step.quest == 203 then break end
        if step.type == "accept" and step.quest then MOCK.questDone[step.quest] = true end
      end
      if section.id == "stv-36" then break end
    end
  end
  MOCK.questLog = { { questID = 203, objectives = { { text = "Kurzen Jungle Fighters 3/15" } } } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Stranglethorn") and questText(frame, "Levels 36-38"), "Stranglethorn resumes its 36-38 guide")
  local arrow = LevelingCodexQuestArrow
  check(questText(arrow, " yd"), "the Stranglethorn waypoint shows a distance")
  MOCK.questMap, MOCK.questX, MOCK.questY = 1431, 44.0, 80.0
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  MOCK.advance(0.25)
  check(questText(arrow, "Follow the road south into Stranglethorn"), "from Duskwood the arrow names the road south")
end

function S.questStranglethornStockpile()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Human", 37, 1434, 45.82, 8.18
  MOCK.questLog = {
    { questID = 574, objectives = { { text = "Kurzen Commandos 3/10" }, { text = "Kurzen Headshrinkers 0/6" } } },
    { questID = 97047, objectives = { { text = "Compound Cage Key 0/1" }, { text = "Kurzen Fighter's Uniform 0/1" } } },
  }
  S.login()
  slash("quests")
  clickGuide("Stranglethorn: Rebels, Kurzen and Nesingwary")
  local step = routeStep("Complete - Special Forces")
  check(step, "the Stranglethorn route has a Stockpile objective for Special Forces")
  step:Click()
  local frame = questViewer()
  check(questText(frame, "Kurzen Commandos 3/10"), "the guide shows live Special Forces progress")
  check(questText(frame, "WHILE YOU'RE HERE") and questText(frame, "Compound Cage Key 0/1"),
    "the cook's key is visible while clearing Special Forces")
  MOCK.questLog[2].objectives[1].text = "Compound Cage Key 1/1"
  MOCK.questLog[2].objectives[1].finished = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not questText(frame, "Compound Cage Key") and questText(frame, "Kurzen Fighter's Uniform 0/1"),
    "the grouped panel keeps only the uniform after looting the key")
end

local TICK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local function shownTexture(root, path)
  for _, r in ipairs({ root:GetRegions() }) do
    if r:IsShown() and r._path == path then return true end
  end
  for _, c in ipairs({ root:GetChildren() }) do
    if c:IsShown() and shownTexture(c, path) then return true end
  end
  return false
end

-- The step window shows a step's objectives as a checklist: the goal, its count on the right and a
-- tick once it's done, from either log style; the Quests tab keeps the log's own words.
function S.questStepChecklist()
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  MOCK.questLog = { { questID = 7, objectives = { { text = "4/10 Kobold Vermin slain" } } } }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Kobold Vermin slain 4/10") and not questText(frame, "4/10 Kobold Vermin slain"),
    "Forever's '4/10 goal' objective is a checklist row with the count on the right: " .. allText(frame))
  check(not shownTexture(frame, TICK), "an unfinished goal has no tick")
  MOCK.questLog[1].objectives = { { text = "Kobold Vermin slain: 10/10", finished = true },
    { text = "Kobold Worker slain: 2/10" } }
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Kobold Vermin slain done") and questText(frame, "Kobold Worker slain 2/10"),
    "the classic 'goal: 2/10' style splits the same way; a finished goal says done: " .. allText(frame))
  local doneRow
  for _, c in ipairs({ frame:GetChildren() }) do
    if c.count and c.count._text == "done" and c:IsShown() then doneRow = c end
  end
  check(doneRow and doneRow.bar:IsShown() and math.abs(doneRow.bar:GetWidth() - doneRow.track:GetWidth()) < 1
    and math.abs(doneRow.bar._color[2] - 0.85) < 0.01, "with a full green bar")
  check(shownTexture(frame, TICK), "a finished goal is ticked")
  click(frame, "Quests")
  check(questText(win(), "Kobold Vermin slain: 10/10") and questText(win(), "Kobold Worker slain: 2/10"),
    "the Quests tab's step card keeps the log's own words, one goal per line")
  MOCK.questLog[1].objectives[1] = { text = "Kobold Vermin slain: 9/10" }
  MOCK.event("QUEST_LOG_UPDATE")
  check(not shownTexture(frame, TICK), "a pooled row loses its tick when it shows an unfinished goal")
end

function S.questWetlandsDig()
  -- In game (2026-11-12) Prospector Whelgar, beside Merrin, offered Uncovering the Past to a level
  -- 24 who had just taken Ormer's first hunt and Merrin's letter. The pickup comes then, not after
  -- the raptors (that sent you back to the cave), the raptor step shows the fragments, Ormer's
  -- second hunt and the rest of the fragments share the dig, and Ormer (nearer the dig) comes first.
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "NightElf", 24, 1437, 38.8, 52.3
  for _, id in ipairs({ 463, 276, 277, 98282, 470, 98197, 279, 484, 281, 284, 285, 286, 98189, 305 }) do
    MOCK.questDone[id] = true
  end
  MOCK.questLog = { { questID = 294 }, { questID = 306 } }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Levels 20-25") and questText(frame, "Accept - Uncovering the Past"),
    "Whelgar's pickup comes with Merrin's, before the raptors: " .. allText(frame))
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 299 }
  MOCK.event("QUEST_ACCEPTED", 3, 299)
  check(questText(frame, "Complete - Ormer's Revenge") and questText(frame, "Uncovering the Past"),
    "the raptor hunt is next and shows the fragments on the way: " .. allText(frame))
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Turn in - Ormer's Revenge"), "then back to Ormer: " .. allText(frame))
  MOCK.questDone[294] = true
  table.remove(MOCK.questLog, 1)
  MOCK.event("QUEST_TURNED_IN", 294)
  check(questText(frame, "Accept - Ormer's Revenge"), "Ormer's second hunt follows the first: " .. allText(frame))
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 295 }
  MOCK.event("QUEST_ACCEPTED", 3, 295)
  check(questText(frame, "Complete - Uncovering the Past") and questText(frame, "Sarltooth"),
    "the rest of the fragments share the dig with the hunt, with a Sarltooth warning: " .. allText(frame))
  for _, entry in ipairs(MOCK.questLog) do entry.isComplete = true end
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "UP NEXT") and questTextStarts(frame, "Turn in - Uncovering the Past"),
    "Ormer, nearer the dig, comes before Whelgar: " .. allText(frame))
end

function S.questWetlandsEnd()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "wetlands" then
      for _, step in ipairs(section.steps) do
        if step.type == "boat" and step.name == "Stormwind Harbor - Auberdine" then
          check(step.ifOnQuest == 98209, "the Wetlands boat requires the unfinished Auberdine delivery")
        end
      end
    end
  end
  -- The Wetlands section ends in Auberdine: Nord'el for Thundris, then the ship to Stormwind for Darkshire.
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 30, 1439
  MOCK.questLog = { { questID = 98209, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Bloom of the Heavens"), "resume at the final Wetlands turn-in")
  check(not questText(frame, "Last step in this guide"), "the Wetlands turn-in is no longer the end of the route")
  MOCK.questDone[98209], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 98209)
  check(frame:IsShown() and questText(frame, "Auberdine - Stormwind Harbor"), "the route continues with the ship to Stormwind")
  check(questText(frame, "Darkshire"), "the next guide is the Darkshire chapter")
end

function S.questRouteEnd()
  -- The leveling route ends in Moonglade at 60: Umber's last hand-in is the final step.
  MOCK.level, MOCK.questMap = 60, 1450
  MOCK.questLog = { { questID = 1185, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Under the Chitin Was..."), "resume at the last turn-in of the route")
  check(questText(frame, "Last step in this guide"), "the final turn-in identifies itself as the last step")
  MOCK.questDone[1185], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 1185)
  check(frame:IsShown() and questText(frame, "End of the leveling guide"), "the guide shows its ending after the turn-in")
  check(not findButton(frame, function(label) return label == "Next" end), "the ending has no dead Next button")
  click(frame, "Hide")
  click(win(), "Show step window")
  check(frame:IsShown() and questText(frame, "End of the leveling guide"), "the end card can be reopened")
  click(frame, "Back")
  check(questText(frame, "Turn in - Under the Chitin Was..."), "Back can review the final step")
end


-- Each Alliance race starts in its own zone at level 1.
for name, start in pairs({ Dwarf = "Coldridge Valley", Gnome = "Coldridge Valley", NightElf = "Shadowglen",
    Skyborne = "Thendal Grove" }) do
  S["questStart" .. name] = function()
    MOCK.race, MOCK.level = name, 1
    S.login()
    check(questText(questViewer(), start), name .. " starts in " .. start)
    slash("quests")
    check(not findButton(win(), function(l) return l == "Northshire Valley" end), name .. " doesn't see the Human start")
    check(guideButton("Westfall"), name .. " joins the shared route at Westfall")
  end
end

-- Each Horde race starts in its own zone at level 1 and never sees the Alliance route.
for name, start in pairs({ Orc = { "Valley of Trials", "Your Place In The World" },
    Troll = { "Valley of Trials", "Your Place In The World" },
    Tauren = { "Camp Narache", "Camp Narache" },
    Scourge = { "Deathknell", "Deathknell" }, Skyborne = { "Thendal Grove", "Coming of Age" } }) do
  S["questStartHorde" .. name] = function()
    MOCK.faction, MOCK.race, MOCK.level = "Horde", name, 1
    S.login()
    check(questText(questViewer(), start[1]) and questText(questViewer(), start[2]),
      name .. " starts in " .. start[1])
    slash("quests")
    check(not findButton(win(), function(l) return l == "Northshire Valley" or l == "Westfall" end),
      name .. " doesn't see Alliance guides")
    MOCK.faction = nil
  end
end

-- Windshaper Skyborne share Zephras Isle with the High Order but take their own faction's chains.
function S.questHordeSkyborne()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Skyborne", 6, 2521
  S.login()
  slash("quests")
  check(routeHas("The Windshapers") and routeHas("Meddlesome Mages"), "Horde Skyborne get the Windshaper chain")
  check(not routeHas("The High Order") and not routeHas("A Magical Affront"), "Horde Skyborne don't get the High Order chain")
  MOCK.faction = nil
end

-- Kalimdor races who take the zeppelin to Silverpine at 12 get the alternate route there.
function S.questHordeSilverpine()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Orc", 13, 1421
  S.login()
  check(questText(questViewer(), "Tirisfal and Silverpine"), "an Orc in Silverpine at 13 is on the Silverpine alternate")
  MOCK.faction = nil
end

-- All Horde starts join the Barrens; each race only sees its own arrival quests.
function S.questHordeBarrens()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Tauren", 13, 1413
  S.login()
  check(questText(questViewer(), "The Crossroads"), "a level 13 Tauren in the Barrens is on the Crossroads guide")
  slash("quests")
  check(routeHas("Journey to the Crossroads") and not routeHas("Crossroads Conscription"),
    "Tauren turn in their own arrival quest, not the Durotar one")
  MOCK.faction = nil
end

-- Horde 30-60: a level 36 in Stranglethorn resumes its 35-37 chapter, the route ends at Karus in
-- Orgrimmar at 60, and the Horde's own Zul'Farrak guide opens at the door.
function S.questHordeStranglethorn()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Horde", "Troll", 36, 1434, 32.0, 28.0
  S.login()
  local frame = questViewer()
  check(questText(frame, "Stranglethorn") and questText(frame, "Levels 35-37"),
    "a level 36 Troll at Grom'gol follows the Horde Stranglethorn chapter")
  click(frame, "Next")
  check(questText(frame, "Stranglethorn") and questText(frame, "Levels 35-37"), "Next stays in the chapter")
  MOCK.faction = nil
end

-- Player feedback: clicking a route switched to it without a word, and the Route sub-tab then led
-- with other routes, so it didn't look like you were on the one you picked.
-- The overview must describe the route being followed while guide pages are only previews.
-- Option summaries must update from the same choices that actually change the route.
function S.questTabOverview()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  MOCK.mapInfo = { [1432] = { name = "Loch Modan" }, [1439] = { name = "Darkshore" } }
  S.login()
  slash("quests")
  clickGuide("Loch Modan")
  click(win(), "Route")
  check(questText(win(), "Area: Loch Modan"), "the overview names the active route's area")
  check(questText(win(), "Pace: Fastest") and questText(win(), "Elites: Ask"), "the overview shows the active options")
  local viewer = questViewer()
  local before = MOCK.textUnder(viewer)
  guideButton("Darkshore"):Click()
  check(questText(win(), "PREVIEW") and questText(win(), "Area: Darkshore"), "a guide page labels its preview and area")
  check(MOCK.textUnder(viewer) == before, "browsing another area never changes the followed step")
  click(win(), "Start this route")
  check(questText(win(), "Darkshore") and questText(win(), "Following"), "starting updates the route overview")
  click(win(), "Setup")
  click(win(), "Every quest")
  click(win(), "Always skip")
  click(win(), "None")
  click(win(), "Done")
  check(questText(win(), "Pace: Every quest") and questText(win(), "Elites: Always skip")
    and questText(win(), "Dungeons: None"), "the closed setup still confirms every routing choice")
  if not MOCK.minimal then
    MOCK.mapInfo = nil
    C_Map.GetMapInfo = function() error("map data unavailable") end
    click(win(), "Route")
    check(questText(win(), "Darkshore") and not questText(win(), "Area: nil"), "missing area APIs keep the route readable")
  end
end

-- The journey must stay a single screen even when a route has hundreds of steps.
-- In-game report: the board's circles and tile headers were empty. Artwork paths
-- must reach SetTexture intact, including GossipFrame art outside Interface/Icons.
function S.questBoardIcons()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  S.login(); slash("quests")
  local function textures()
    local found = {}
    local function walk(frame)
      for _, region in ipairs(frame._regions) do
        if region._shown and region._type == "Texture" then
          check(not (region._path or ""):find("Interface\\Icons\\Interface\\", 1, true),
            "quest artwork paths must not receive a second icon-directory prefix")
          found[#found + 1] = region
        end
      end
      for _, child in ipairs(frame._children) do if child._shown then walk(child) end end
    end
    walk(win())
    return found
  end
  local function artwork(file)
    for _, texture in ipairs(textures()) do
      if texture._path == file then return texture end
    end
  end
  local map = "Interface\\Icons\\INV_Misc_Map_01"
  check(artwork(map), "journey area nodes and sidebar display game map artwork")
  click(win(), "Guides")
  check(artwork(map), "route tiles display game map artwork")
  click(win(), "Dungeons")
  check(artwork("Interface\\Icons\\INV_Misc_Head_Dragon_01"), "dungeon tiles display game artwork")
  click(win(), "Quest log")
  check(artwork("Interface\\GossipFrame\\AvailableQuestIcon"), "quest-log cards display quest artwork outside the icon directory")
  MOCK.missingTextures[map:lower()] = true
  click(win(), "Guides")
  local fallback = false
  for _, texture in ipairs(textures()) do
    if texture:GetTexture() == 134400 then fallback = true end
  end
  check(fallback, "unavailable board artwork displays the question-mark fallback")
end

function S.questBoardAreaMaps()
  local maps = { 1432, 1437, 1417 }
  local names = { "Loch Modan", "Wetlands", "Arathi Highlands" }
  local steps = {}
  MOCK.mapArt, MOCK.mapInfo, MOCK.mapOverlays = {}, {}, {}
  for i, map in ipairs(maps) do
    MOCK.mapInfo[map] = { name = names[i] }
    MOCK.mapArt[map] = {
      layers = { { layerWidth = 768, layerHeight = 512, tileWidth = 256, tileHeight = 256 } },
      textures = { { 900000 + i * 10 + 1, 900000 + i * 10 + 2, 900000 + i * 10 + 3,
        900000 + i * 10 + 4, 900000 + i * 10 + 5, 900000 + i * 10 + 6 } },
    }
    MOCK.mapOverlays[map] = { { textureWidth = 300, textureHeight = 270, offsetX = 150, offsetY = 110,
      fileDataIDs = { 901000 + i * 10 + 1, 901000 + i * 10 + 2, 901000 + i * 10 + 3, 901000 + i * 10 + 4 } } }
    steps[#steps + 1] = { type = "note", name = names[i] .. " stop", text = "Visit " .. names[i] .. ".", map = map }
  end
  LevelingCodexQuests.ALLIANCE.sections[#LevelingCodexQuests.ALLIANCE.sections + 1] = {
    id = "test-area-art", title = "Test area artwork", zone = 1432, levels = { 11, 18 }, steps = steps,
  }
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  S.login(); slash("quests"); clickGuide("Test area artwork")
  if MOCK.minimal then
    check(questText(win(), "Map unavailable") and questText(win(), "Loch Modan"),
      "without map APIs the area preview keeps its name and explains unavailable art")
    return
  end
  local function artUnder(root)
    local found = {}
    local function walk(frame)
      for _, region in ipairs(frame._regions) do
        if region._shown and region._type == "Texture" and type(region._tex) == "number"
          and region._tex > 900000 and region._tex < 902000 then
          found[region._tex] = region
          for _, v in ipairs(region._coords or {}) do check(v >= 0 and v <= 1, "map tiles crop within their texture") end
        end
      end
      for _, child in ipairs(frame._children) do if child._shown then walk(child) end end
    end
    walk(root)
    return found
  end
  local art = artUnder(win())
  for i = 1, 3 do
    check(art[900000 + i * 10 + 2] and art[900000 + i * 10 + 5], "each journey area uses its own map tiles")
    check(art[901000 + i * 10 + 4], "each map includes explored terrain over its base parchment")
  end
  local edge = art[901014]._coords
  check(edge[2] <= 44 / 64 and edge[4] <= 14 / 16, "partial exploration tiles exclude power-of-two texture padding")
  local before = MOCK.textUnder(questViewer())
  click(win(), "Area 2: Wetlands")
  check(MOCK.textUnder(questViewer()) == before and not MOCK.openedMap, "map previews leave the followed step and world map alone")
  click(win(), "Guides")
  check(artUnder(win())[900012], "route cards use their zone's real map tiles")
  C_MapExplorationInfo.GetExploredMapTextures = function() error("exploration unavailable") end
  click(win(), "Route")
  check(artUnder(win())[900012], "unavailable exploration APIs keep the base map usable")
  C_Map.GetMapArtLayers = function() error("map art unavailable") end
  click(win(), "Route")
  check(questText(win(), "Map unavailable") and not next(artUnder(win())), "failed map APIs show a named placeholder and hide pooled map tiles")
  C_Map.GetMapArtLayers, C_Map.GetMapArtLayerTextures = nil, nil
  click(win(), "Guides"); click(win(), "Route")
  check(questText(win(), "Map unavailable"), "clients without map-art APIs keep the board usable")
end

function S.questBoardJourney()
  local steps = {}
  for i = 1, 36 do steps[#steps + 1] = { type = "note", name = "Loch stop " .. i, text = "Read the Loch instruction " .. i .. ".", map = 1432 } end
  steps[#steps + 1] = { type = "note", name = "Coastal stop", text = "Read the coastal instruction.", map = 1439 }
  steps[#steps + 1] = { type = "note", name = "Return stop", text = "Return to the Loch.", map = 1432 }
  LevelingCodexQuests.ALLIANCE.sections[#LevelingCodexQuests.ALLIANCE.sections + 1] = {
    id = "test-journey-board", title = "Test journey board", zone = 1432, levels = { 11, 18 }, steps = steps,
  }
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  MOCK.mapInfo = { [1432] = { name = "Loch Modan" }, [1439] = { name = "Darkshore" } }
  S.login()
  slash("quests")
  clickGuide("Test journey board")
  local opener = findButton(win(), function(l) return l == "Hide step window" or l == "Show step window" end)
  local _, content = opener:GetPoint()
  check(content:GetHeight() <= 480, "the default journey fits one screen instead of drawing the full itinerary")
  local before = MOCK.textUnder(questViewer())
  click(win(), "Area 2: Darkshore")
  check(questText(win(), "Coastal stop") and questText(win(), "AREA PREVIEW"), "an area node opens its own quest panel")
  check(MOCK.textUnder(questViewer()) == before, "area browsing leaves the followed quest and arrow alone")
  click(win(), "Area steps")
  check(questText(win(), "Coastal stop") and not questText(win(), "Loch stop 36"), "area steps contain only the selected leg")
  click(win(), "Back to journey")
  click(win(), "Area 1: Loch Modan")
  click(win(), "Area steps")
  check(not questText(win(), "Loch stop 36"), "long areas are paged")
  click(win(), "Next steps page")
  local oldPage = false
  for _, b in ipairs(MOCK.buttons(win())) do if b.tipTitle == "Note - Loch stop 1" then oldPage = true end end
  check(questText(win(), "Loch stop 7") and not oldPage, "the next page replaces the first six quest cards")
end

function S.questBoardDungeons()
  MOCK.level, MOCK.questMap = 20, 1436
  S.login()
  slash("quests")
  guidesView("Dungeons")
  local a = findButton(win(), function(l) return l == "The Deadmines" end)
  local b = findButton(win(), function(l) return l == "Wailing Caverns" end)
  check(a and b, "the dungeon board includes the early runs")
  local _, _, _, ax, ay = a:GetPoint()
  local _, _, _, bx, by = b:GetPoint()
  check(ax ~= bx and ay == by, "dungeons are peer tiles in two columns, not a vertical button list")
  click(win(), "Plan The Deadmines")
  check(LevelingCodexDB.questDungeonPlan["dungeon-deadmines"], "a tile plans its run without following it")
  check(not questText(questViewer(), "Enter the Deadmines"), "planning leaves the leveling guide active")
end

function S.questBoardSearch()
  local steps = { { type = "note", text = "Stay at the Loch.", map = 1432 } }
  for i = 1, 12 do steps[#steps + 1] = { type = "note", text = "Coastal errand " .. i, map = 1439 } end
  steps[#steps + 1] = { type = "accept", quest = 999181, name = "Needle Paperwork", text = "Pick up the paperwork.", map = 1439, min = 11 }
  steps[#steps + 1] = { type = "accept", quest = 999182, name = "Optional Paperwork", text = "An optional errand.", map = 1439, min = 11, optional = true }
  LevelingCodexQuests.ALLIANCE.sections[#LevelingCodexQuests.ALLIANCE.sections + 1] = {
    id = "test-board-search", title = "Test board search", zone = 1432, levels = { 11, 18 }, steps = steps,
  }
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  S.login(); slash("quests")
  local before = MOCK.textUnder(questViewer())
  click(win(), "Guides")
  LevelingCodexQuestSearch:SetText("Needle Paperwork")
  MOCK.fire(LevelingCodexQuestSearch, "OnEnterPressed")
  local match = findButton(win(), function(l) return l == "Accept - Needle Paperwork" end)
  check(match, "quest-name searches retain a card for the matching quest")
  match:Click()
  check(questText(win(), "Needle Paperwork"), "search opens the area and card page containing the matching quest")
  check(MOCK.textUnder(questViewer()) == before, "search previews leave the followed step alone")
  click(win(), "Guides")
  LevelingCodexQuestSearch:SetText("Optional Paperwork")
  MOCK.fire(LevelingCodexQuestSearch, "OnEnterPressed")
  check(not findButton(win(), function(l) return l == "Accept - Optional Paperwork" end)
    and questText(win(), "outside your current route options"), "filtered matches explain their exclusion instead of opening an unrelated area")
  click(win(), "Setup"); click(win(), "Your route"); click(win(), "Every quest")
  click(win(), "Guides")
  LevelingCodexQuestSearch:SetText("Optional Paperwork")
  MOCK.fire(LevelingCodexQuestSearch, "OnEnterPressed")
  local optional = findButton(win(), function(l) return l == "Accept - Optional Paperwork" end)
  check(optional, "enabling optional quests makes the search result navigable")
  optional:Click()
  check(questText(win(), "Optional Paperwork"), "the enabled match opens its own area page")
end

function S.questBoardExternalGuide()
  local sections = LevelingCodexQuests.ALLIANCE.sections
  for _, name in ipairs({ "A", "B" }) do
    sections[#sections + 1] = { id = "board-run-" .. name, title = "Board run " .. name, zone = 1436, levels = { 13, 18 }, side = true, category = "dungeon", steps = {
      { type = "note", phase = "prepare", text = "Prepare for " .. name },
      { type = "note", phase = "inside", text = "Inside " .. name },
      { type = "note", phase = "after", text = "After " .. name },
    } }
  end
  sections[#sections + 1] = { id = "board-linked-route", title = "Board linked route", zone = 1436, levels = { 13, 18 }, steps = {
    { type = "note", text = "A related guide is available.", guide = "board-run-B" },
  } }
  MOCK.level, MOCK.questMap = 14, 1436
  S.login(); slash("quests"); clickGuide("Board linked route")
  guidesView("Dungeons"); click(win(), "Board run A"); click(win(), "Turn-ins")
  stepTool("Plan Board run B")
  local prepare = findButton(win(), function(l) return l == "Prepare" end)
  local after = findButton(win(), function(l) return l == "Turn-ins" end)
  check(prepare and prepare.codexOn and after and not after.codexOn, "opening a related guide clears the previous dungeon's phase selection")
end

-- Area headings follow travel order, including returning to an earlier area.
function S.questTabItinerary()
  LevelingCodexQuests.ALLIANCE.sections[#LevelingCodexQuests.ALLIANCE.sections + 1] = {
    id = "test-itinerary", title = "Test travel itinerary", zone = 1432, levels = { 11, 18 }, steps = {
      { type = "note", name = "First stop", text = "First stop.", map = 1432 },
      { type = "note", name = "Second stop", text = "Second stop.", map = 1439 },
      { type = "note", name = "Return stop", text = "Return stop.", map = 1432 },
    },
  }
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  MOCK.mapInfo = { [1432] = { name = "Loch Modan" }, [1439] = { name = "Darkshore" } }
  S.login(); slash("quests"); clickGuide("Test travel itinerary")
  local positions = {}
  for i, name in ipairs({ "Area 1: Loch Modan", "Area 2: Darkshore", "Area 3: Loch Modan" }) do
    local b = findButton(win(), function(l) return l == name end)
    check(b, "consecutive area node is available: " .. name)
    positions[i] = select(4, b:GetPoint())
  end
  check(positions[1] < positions[2] and positions[2] < positions[3], "area nodes preserve route order, including a return visit")
  local before = MOCK.textUnder(questViewer())
  click(win(), "Area 3: Loch Modan")
  check(questText(win(), "Return stop") and MOCK.textUnder(questViewer()) == before, "a return-area preview is independent of the followed step")
end

-- Planning pickups and actively following a dungeon are independent states.
function S.questTabDungeonStates()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 20, 1436
  S.login()
  slash("quests")
  guidesView("Dungeons")
  click(win(), "The Deadmines")
  check(questText(win(), "Not planned") and questText(win(), "PREVIEW"), "an unplanned dungeon opens as a preview")
  check(findButton(win(), function(l) return l == "Prepare" end) and findButton(win(), function(l) return l == "Inside" end) and findButton(win(), function(l) return l == "Turn-ins" end),
    "the dungeon page explains its three stages")
  local pickup
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and type(b.tipTitle) == "string" and b.tipTitle:find("^Accept %- ") then pickup = b; break end
  end
  check(pickup, "the dungeon preview has a pickup to inspect")
  pickup:Click()
  check(questText(win(), "FOLLOWING") and questText(win(), "PREVIEW"),
    "inspecting a dungeon step keeps the followed leveling route in the overview")
  click(win(), "Plan this run")
  check(questText(win(), "Planned") and questText(win(), "PREVIEW"), "planning leaves the leveling route active")
  click(win(), "Start inside")
  click(win(), "Guides")
  click(win(), "Dungeons")
  click(win(), "The Deadmines")
  check(questText(win(), "Following") and questText(win(), "Planned"), "a followed dungeon still confirms its pickup plan")
end

function S.questTabStagePreview()
  LevelingCodexQuests.ALLIANCE.sections[#LevelingCodexQuests.ALLIANCE.sections + 1] = {
    id = "test-stage-run", title = "Test stage run", zone = 1436, levels = { 20, 30 }, side = true, category = "dungeon",
    steps = {
      { type = "note", phase = "prepare", text = "Prepare for the test run." },
      { type = "note", phase = "inside", text = "Inside the test run." },
      { type = "note", phase = "after", text = "Finish the test run." },
    },
  }
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 26, 1436
  S.login()
  slash("quests")
  guidesView("Dungeons")
  click(win(), "Test stage run")
  click(win(), "Start inside")
  check(questText(questViewer(), "Inside the test run."), "the run is following its inside phase")
  guidesView("Dungeons")
  click(win(), "The Deadmines")
  for _, b in ipairs(MOCK.buttons(win())) do
    if type(b.tipTitle) == "string" and b.tipTitle:find("^Accept %- ") then b:Click(); break end
  end
  guidesView("Dungeons")
  click(win(), "Test stage run")
  check(findButton(win(), function(l) return l == "Inside (now)" end) and not findButton(win(), function(l) return l == "Prepare (now)" end),
    "another dungeon's step preview cannot move the followed dungeon's stage highlight")
end

function S.questRoutePick()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  S.login()
  local frame = questViewer()
  check(questText(frame, "Levels 11-18"), "the Dwarf starts on Loch Modan")
  slash("quests")
  check(questText(win(), "Following") and questText(win(), "Loch Modan"), "Journey names the followed route")
  local row = guideButton("Darkshore")
  check(row, "Darkshore is listed under Guides", 2)
  row:Click()
  check(not questText(frame, "Levels 12-20"), "clicking a guide row doesn't switch routes")
  check(findButton(win(), function(l) return l == "Start this route" end), "its page offers Start this route")
  check(questText(win(), "until you start this one"), "the page says which route you stay on")
  check(questText(win(), "Area:"), "the preview identifies the selected area")
  -- a step row of a route you're only previewing doesn't move the step window
  local stepRow
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and type(b.tipTitle) == "string" and b.tipTitle:find("^Accept %- ") then stepRow = b; break end
  end
  check(stepRow, "the preview lists Darkshore's pickups", 2)
  stepRow:Click()
  check(questText(frame, "Levels 11-18") and not questText(frame, "Levels 12-20"),
    "clicking a step of a previewed route keeps the step window on yours")
  click(win(), "Start this route")
  check(questText(frame, "Levels 12-20"), "Start this route switches the step window")
  check(chatHas("Now following Darkshore"), "starting a route says so in chat")
  check(questText(win(), "Following") and findButton(win(), function(l) return l == "Area steps" end),
    "Start opens the new route's journey board")
  check(questText(win(), "Darkshore"), "the journey confirms which route started")
  MOCK.advance(31)
  click(win(), "Route")
  check(not questText(win(), "Started. The step window"), "the confirmation goes after half a minute")
  clickGuide("Darkshore")
  check(questText(win(), "You are on this route."), "the page of the route you're on says so")
  click(win(), "Route")
  local preview = guideButton("Loch Modan")
  check(preview, "Routes offers another route")
  preview:Click()
  check(questText(frame, "Levels 12-20"), "previewing another route keeps you on yours")
  click(win(), "Back to guides"); click(win(), "Route")
  check(questText(win(), "Following") and questText(win(), "Darkshore"), "Journey keeps the followed route after previewing")
  click(win(), "Change route")
  check(guideButton("Darkshore"), "Change route opens the guide list")
  -- a route above your level says so on its page
  local later = guideButton("Duskwood")
  check(later, "Duskwood is listed under Guides", 2)
  later:Click()
  check(questText(win(), "It starts at level 21; you are 12."), "a later route's page says when it starts")
end

local function hillsbradNote()
  for _, section in ipairs(LevelingCodexQuests.HORDE.sections) do
    if section.id == "hillsbrad-30" then
      for n, step in ipairs(section.steps) do
        if step.type == "note" then return section, n, step end
      end
    end
  end
end

-- Player feedback: Tarren Mill's quest log clean-up note came back after every /reload until Next.
function S.questNoteOnce()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Orc", 30, 1441
  S.login()
  slash("quests")
  clickGuide("Tarren Mill, Alterac and Hammerfall")
  local frame = questViewer()
  check(questText(frame, "Clean out your quest log"), "Tarren Mill starts with the clean-up note")
  click(frame, "Next")
  check(not questText(frame, "Clean out your quest log"), "Next passes the note")
  local saved = false
  for key in pairs(LevelingCodexCharDB.questSkips or {}) do
    if key:find("^hillsbrad%-30:note:") then saved = true end
  end
  check(saved, "the passed note is kept with the character's skips")
  MOCK.faction = nil
end

-- After a reload: a note passed with Next (saved) stays passed.
function S.questNoteSaved()
  local _, n = hillsbradNote()
  check(n, "hillsbrad-30 has a note step", 2)
  LevelingCodexCharDB = { questSkips = { ["hillsbrad-30:note:" .. n .. ":1"] = true } }
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Orc", 30, 1441
  S.login()
  slash("quests")
  clickGuide("Tarren Mill, Alterac and Hammerfall")
  check(not questText(questViewer(), "Clean out your quest log"), "a saved note doesn't come back after a reload")
  MOCK.faction = nil
end

-- Without SavedVariables: a later step of the chapter the game finished passes the note too.
function S.questNoteLater()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Orc", 30, 1441
  MOCK.questDone[1145] = true
  S.login()
  slash("quests")
  clickGuide("Tarren Mill, Alterac and Hammerfall")
  check(not questText(questViewer(), "Clean out your quest log"),
    "the note is passed once a later quest of the chapter is turned in")
  MOCK.faction = nil
end

function S.questHordeRouteEnd()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Orc", 60, 1454
  MOCK.questLog = { { questID = 4511, isComplete = true } }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Calm Before the Storm") and questText(frame, "Last step in this guide"),
    "the Horde route's last step is the Calm Before the Storm hand-in")
  MOCK.questDone[4511], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 4511)
  check(questText(frame, "End of the leveling guide"), "the Horde guide shows its ending at 60")
  MOCK.faction = nil
end

function S.questHordeDungeon()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Tauren", 46, nil
  MOCK.instanceName, MOCK.instanceID = "Zul'Farrak", 209
  S.login()
  local frame = questViewer()
  check(questText(frame, "Boss - Antu'sul") and chatHas("Zul'Farrak: the step window follows its guide"),
    "zoning into Zul'Farrak opens the Horde guide at its first boss")
  MOCK.faction, MOCK.instanceName, MOCK.instanceID = nil, nil, nil
end

-- Reported in game: Sovik's quest is behind gossip, so leaving Orgrimmar after
-- only visiting the vendor sends the player back from Booty Bay.
local function sovikPickup(dungeon, withoutRigWars)
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 30
  MOCK.questMap, MOCK.questX, MOCK.questY = 1454, 75.49, 25.36
  LevelingCodexDB = { questDungeonPlan = { ["dungeon-gnomeregan"] = true } }
  MOCK.questLog = withoutRigWars and {} or { { questID = 2841 } }
  if not dungeon then
    for _, section in ipairs(LevelingCodexQuests.HORDE.sections) do
      if not section.side and not section.alternate then
        for _, step in ipairs(section.steps) do
          if step.quest == 2842 then break end
          if step.quest and step.quest ~= 2841 then MOCK.questDone[step.quest] = true end
        end
        if section.id == "hillsbrad-30" then break end
      end
    end
  end
  S.login()
  slash("quests")
  if dungeon then
    guidesView("Dungeons")
    click(win(), "Gnomeregan")
    click(win(), "Follow this guide")
    if withoutRigWars then
      check(questText(questViewer(), "Accept - Rig Wars"), "Nogg is offered first")
      click(questViewer(), "Next")
    end
  else
    clickGuide("Tarren Mill, Alterac and Hammerfall")
    -- Travel and clean-up notes before the city pickups still need acknowledging.
    for _ = 1, 20 do
      if questTextStarts(questViewer(), "Sovik") then break end
      click(questViewer(), "Next")
    end
  end
  local frame = questViewer()
  check(questText(frame, "Accept - Chief Engineer Scooty"), "Sovik's pickup is current")
  check(questText(frame, "What else do you have to say?"), "Sovik's pickup explains the required gossip choice")
  check(questText(frame, "quest log") and questText(frame, "Orgrimmar"), "confirm the quest before leaving Orgrimmar")
  MOCK.event("GOSSIP_CLOSED")
  check(questText(frame, "Accept - Chief Engineer Scooty"), "closing gossip cannot acknowledge the pickup")
  MOCK.questLog[#MOCK.questLog + 1] = { questID = 2842 }
  MOCK.event("QUEST_ACCEPTED", 2, 2842)
  check(not questTextStarts(frame, "Sovik"), "accepting the quest advances past Sovik")
end

function S.questSovikDungeon() sovikPickup(true) end
function S.questSovikRoute() sovikPickup(false) end
function S.questSovikWithoutRigWars() sovikPickup(true, true) end

local function incendiariesAfterUse(ready)
  MOCK.faction, MOCK.race, MOCK.level = "Horde", "Orc", 56
  MOCK.questMap, MOCK.questX, MOCK.questY = 1420, 83.2, 69.1
  if ready then MOCK.questLog = { { questID = 5096, isComplete = true } }
  else MOCK.questDone[5096] = true end
  for _, section in ipairs(LevelingCodexQuests.HORDE.sections) do
    if section.id == "plaguelands-56" then
      for _, step in ipairs(section.steps) do
        if step.type == "accept" and step.quest == 5096 then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  S.login()
  slash("quests")
  clickGuide("Plaguelands: the Bulwark and Tirion Fordring")
  local frame = questViewer()
  for _ = 1, 12 do
    if questTextStarts(frame, "Take a Flame in a Bottle") or questTextStarts(frame, "Garush hands out") then break end
    click(frame, "Next")
  end
  check(not questTextStarts(frame, "Take a Flame in a Bottle"), "a finished Scarlet Diversions never sends you back for an incendiary")
  check(questTextStarts(frame, "Garush hands out"), "the route continues to the Argent Dawn pickup")
end

function S.questIncendiariesDone() incendiariesAfterUse(false) end
function S.questIncendiariesReady() incendiariesAfterUse(true) end

local function upperSpireDialoguePickup(quest, name)
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 60, nil
  S.login()
  slash("quests")
  guidesView("Dungeons")
  click(win(), "Upper Blackrock Spire")
  click(win(), "Start inside")
  local frame = questViewer()
  local found = false
  for _ = 1, 60 do
    -- The pickup instructions are on the current card, not in UP NEXT.
    if questText(frame, "Accept - " .. name) and questText(frame, "dialogue") then found = true; break end
    local nextButton = findButton(frame, function(l) return l == "Next" end)
    if not nextButton then break end
    nextButton:Click()
  end
  check(found, name .. " is offered before receiving its supplied quest item")
  MOCK.questLog = { { questID = quest } }
  MOCK.event("QUEST_ACCEPTED", 1, quest)
  check(not questTextStarts(frame, quest == 5160 and "Awbee" or "After The Beast"), "accepting the NPC quest advances the guide")
end

function S.questAwbeePickup() upperSpireDialoguePickup(5160, "The Matron Protectorate") end
function S.questFinklePickup() upperSpireDialoguePickup(5047, "Finkle Einhorn, At Your Service!") end

function S.questHearthModernCooldown()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "hearth", bind = "Goldshire", map = 1429, x = 47, y = 41,
        text = "Return to Goldshire, then talk to the flight master." })
    end
  end
  MOCK.bind, MOCK.bags[6948], MOCK.time = "Goldshire", 1, 20
  GetItemCooldown = nil
  C_Item.GetItemCooldown = function(id) if id == 6948 then return 10, 3600, true end end
  C_Container.GetItemCooldown = function(bag, slot) return 0, 0, true end
  S.login()
  check(questText(questViewer(), "ready in 60 min"), "modern item cooldown does not mistake an item ID for a bag")
  local b = LevelingCodexQuestItem
  check(b and b:IsShown() and questText(b, "60m"), "clickable hearthstone shows its live cooldown")
  MOCK.advance(61)
  check(questText(b, "59m"), "clickable item cooldown updates while the step stays current")
end

function S.questFlightRouteInitialization()
  local initialized
  TaxiNodeOnButtonEnter = function(button) initialized = button end
  local original = TakeTaxiNode
  TakeTaxiNode = function(slot)
    check(initialized == _G["TaxiButton" .. slot], "initialize the destination route before taking a connecting flight")
    original(slot)
  end
  _G.TaxiButton2 = CreateFrame("Button", "TaxiButton2", UIParent)
  S.questTravelFlight()
end

function S.questCompletedSet()
  C_QuestLog.IsQuestFlaggedCompleted = function() return false end
  C_QuestLog.GetAllCompletedQuestIDs = function() return { [783] = true, [92710] = true } end
  S.login()
  check(not questText(questViewer(), "Accept - A Threat Within"), "completed quest ID sets skip earlier pickups on a fresh DB")
end

function S.questDungeonPreparation()
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 24, 1437
  S.login()
  slash("quests")
  guidesView("Dungeons")
  click(win(), "Excavation Site: Wetlands")
  click(win(), "Prepare quests")
  check(LevelingCodexDB.questDungeonPlan["dungeon-excavation-site"], "preparation plans the dungeon pickups while leveling")
  check(questText(questViewer(), "Songblade Search"), "prepare offers the Lakeshire prerequisite before the run level")
  -- Finish every outdoor quest and travel step through player acknowledgements.
  for _ = 1, 60 do
    local frame = questViewer()
    check(not questTextStarts(frame, "Meet the group at the upper dig"), "preparing never sends you to enter the dungeon")
    if findButton(frame, function(l) return l == "Return to leveling" end) == nil then break end
    click(frame, "Next")
  end
  check(not findButton(questViewer(), function(l) return l == "Return to leveling" end), "finishing preparation returns to leveling")
end

function S.questDungeonIncompletePreparation()
  MOCK.level, MOCK.questMap = 28, 1437
  LevelingCodexDB = { questDungeonPlan = { ["dungeon-excavation-site"] = true } }
  MOCK.questLog = { { questID = 98815 }, { questID = 95772 }, { questID = 95647 } }
  S.login()
  check(not findButton(questViewer(), function(l) return l == "Run Excavation Site: Wetlands" end),
    "three quests do not declare the dungeon ready while outdoor prerequisites remain")
end

local function classSideFixture()
  local function step(kind, id, name)
    return { type = kind, quest = id, name = name, text = "Test class chain.", min = 10, level = 10,
      chain = id == 999002 and { 999001 } or nil }
  end
  local sections = LevelingCodexQuests.ALLIANCE.sections
  sections[#sections + 1] = { id = "test-class-side", title = "Warrior: Test Chain",
    zone = 1436, levels = { 10, 12 }, side = true, class = "WARRIOR", steps = {
      step("accept", 999001, "First class quest"),
      step("complete", 999001, "Find first item"), step("complete", 999001, "Find second item"),
      step("turnin", 999001, "First class quest"),
      step("accept", 999002, "Second class quest"), step("turnin", 999002, "Second class quest"),
    } }
end

function S.questClassSide()
  classSideFixture()
  MOCK.level, MOCK.questMap = 13, 1436
  S.login()
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "class quests do not interrupt the route")
  slash("quests")
  clickGuide("Warrior: Test Chain")
  check(questText(questViewer(), "Accept - First class quest"), "selecting the side section follows its quest")
  click(questViewer(), "Next")
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "skipping the chain returns to leveling")
  clickGuide("Warrior: Test Chain")
  check(questText(questViewer(), "Accept - First class quest"), "reopening a class guide restores unfinished quests")
  stepTool("Return to leveling")
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "you can leave a class guide early")
  clickGuide("Warrior: Test Chain")
  MOCK.questLog = { { questID = 999001 } }
  MOCK.event("QUEST_ACCEPTED", 1, 999001)
  check(questText(questViewer(), "Complete - Find first item"), "the side guide advances on quest events")
  click(questViewer(), "Next")
  check(questText(questViewer(), "Complete - Find second item"), "Next advances one part of a multi-part objective")
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(questViewer(), "Turn in - First class quest"), "the turn-in still follows the final objective")
  MOCK.questDone[999001], MOCK.questDone[999002] = true, true
  MOCK.questLog = {}
  MOCK.event("QUEST_TURNED_IN", 999002)
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "finishing returns to the same leveling step")
  click(win(), "Settings")
  click(win(), "Show class quests")
  click(win(), "Quests")
  check(not findButton(win(), function(l) return l == "Warrior: Test Chain" end), "hidden side sections are not selectable")
end

function S.questDetourLibrary()
  local sections = LevelingCodexQuests.ALLIANCE.sections
  sections[#sections + 1] = { id = "test-dungeon", title = "Test Dungeon", zone = 1436,
    levels = { 13, 18 }, side = true, category = "dungeon", verified = false, steps = {
      { type = "accept", phase = "prepare", quest = 999011, name = "Dungeon Test Pickup", min = 13, text = "Talk to the guide." },
      { type = "dungeon", phase = "prepare", name = "Test Dungeon", text = "Enter with your group." },
      { type = "accept", phase = "inside", quest = 999012, name = "Dungeon Test Inside", min = 15, text = "Talk to the prisoner." },
      { type = "turnin", phase = "after", quest = 999011, name = "Dungeon Test Pickup", text = "Return to the guide." },
      { type = "turnin", phase = "after", quest = 999012, name = "Dungeon Test Inside", text = "Return to the prisoner." },
    } }
  MOCK.level, MOCK.questMap = 13, 1436
  S.login()
  slash("quests")
  click(win(), "Settings")
  click(win(), "Show class quests")
  click(win(), "Quests")
  guidesView("Dungeons")
  click(win(), "Test Dungeon")
  check(findButton(win(), function(l) return l == "Prepare" end) and findButton(win(), function(l) return l == "Inside" end)
    and findButton(win(), function(l) return l == "Turn-ins" end), "dungeon stages are selectable")
  click(win(), "Inside")
  check(questText(win(), "Requires level 15"), "the inside checklist shows the actual level gate")
  click(win(), "Follow this guide")
  check(questText(questViewer(), "Dungeon Test Pickup"), "dungeon guide starts independently of class quests")
  MOCK.questLog = { { questID = 999011, title = "Dungeon Test Pickup", objectives = { { text = "Dungeon widgets: 0/2" } } } }
  MOCK.event("QUEST_ACCEPTED", 1, 999011)
  check(questText(questViewer(), "Enter with your group"), "acceptance advances to the dungeon entrance")
  MOCK.questLog[2] = { questID = 999012, isComplete = true }
  MOCK.event("QUEST_LOG_UPDATE")
  click(win(), "After the run")
  check(questText(questViewer(), "Turn in - Dungeon Test Inside") and not questText(questViewer(), "Turn in - Dungeon Test Pickup"),
    "the after-run phase skips unfinished turn-ins")
  stepTool("Return to leveling")
  check(questText(questViewer(), "Report to Gryan Stoutmantle"), "return restores the leveling step")
  click(win(), "Quest log")
  click(win(), "Track Dungeon Test Pickup")
  check(questText(questViewer(), "TRACKING") and questText(questViewer(), "Dungeon Test Pickup"), "pinned quests stay visible across guides")
  click(win(), "Guides")
  local search = _G.LevelingCodexQuestSearch
  check(search and search:IsShown(), "search field is available")
  search:SetText("Dungeon Test Inside")
  MOCK.fire(search, "OnEnterPressed")
  check(questText(win(), "Dungeon Test Inside"), "search finds a quest inside a detour")
  MOCK.questLog = {}
  MOCK.event("QUEST_TURNED_IN", 999011)
  check(not questText(questViewer(), "TRACKING"), "completed quests disappear from the pinned list")
end

function S.questDungeonContent()
  MOCK.level, MOCK.questMap = 15, 1455
  MOCK.questDone[96392], MOCK.questDone[96390], MOCK.questDone[96391] = true, true, true
  S.login()
  slash("quests")
  guidesView("Dungeons")
  click(win(), "Hall of Thanes")
  check(guideHas("Old Ironforge Incursion"), "Hall of Thanes shows its outdoor unlock")
  click(win(), "Inside")
  check(guideHas("The Treaty of Understanding"), "its inside checklist includes the starter")
  click(win(), "Follow this guide")
  check(questText(questViewer(), "Accept - Old Ironforge Incursion"), "completed map prep leads directly to the dungeon pickup")
  click(questViewer(), "Return to leveling")
  MOCK.instanceName, MOCK.instanceID = "The Hall of Thanes", 3065
  MOCK.event("PLAYER_ENTERING_WORLD")
  click(win(), "Follow this guide")
  check(questText(questViewer(), "Accept - An Ancient Grudge"), "reopening inside starts with the first obtainable inside quest")
  click(questViewer(), "Return to leveling")
  guidesView("Special")
  click(win(), "Cozy Sleeping Bag")
  click(win(), "Follow this guide")
  check(questText(questViewer(), "Accept - ... and that note you found") and questText(questViewer(), "Alexston Farmstead"),
    "the Alliance sleeping bag detour starts in Westfall")
end

function S.questAlternateSharedPickup()
  local sections = LevelingCodexQuests.ALLIANCE.sections
  for _, suffix in ipairs({ "First", "Second" }) do
    sections[#sections + 1] = { id = "alternate-" .. suffix, title = "Alternate " .. suffix,
      zone = 1436, levels = { 13, 18 }, alternate = true, verified = false, steps = {
        { type = "accept", quest = 999020, name = "Shared Alternate Pickup", text = "Talk to the guide." },
      } }
  end
  MOCK.level, MOCK.questMap = 13, 1436
  S.login()
  slash("quests")
  clickGuide("Alternate First")
  check(questText(questViewer(), "Accept - Shared Alternate Pickup"), "the first alternate offers the quest")
  click(questViewer(), "Next")
  clickGuide("Alternate Second")
  check(questText(questViewer(), "Accept - Shared Alternate Pickup"), "manual skips stay in their own alternate")
  MOCK.questDone[999020] = true
  MOCK.event("QUEST_TURNED_IN", 999020)
  check(not questText(questViewer(), "Accept - Shared Alternate Pickup"), "game completion is shared across alternates")
end

function S.questSouthshoreTurnin()
  local turtle = { questID = 555, objectives = { { text = "Turtle Meat: 1/10" } } }
  MOCK.race, MOCK.level, MOCK.questMap = "Human", 33, 1416
  MOCK.questLog = { turtle, { questID = 98071, isComplete = true } }
  for _, id in ipairs({ 98059, 647, 98219, 536, 559, 560, 561, 562, 659 }) do MOCK.questDone[id] = true end
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turtle Meat 1/10"), "the level 33 route is following the turtle objective")

  MOCK.questMap, MOCK.questX, MOCK.questY = 1424, 52.13, 58.74
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Turtle Meat 1/10"), "the ready turn-in does not switch to the older Southshore alternate")
  MOCK.questDone[98071], MOCK.questLog = true, { turtle }
  MOCK.event("QUEST_TURNED_IN", 98071)
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Turtle Meat 1/10"), "turning in Brewer's Trade keeps the turtle objective in view")
end

function S.questPinCapacity()
  MOCK.level, MOCK.questMap = 13, 1436
  for i = 1, 4 do MOCK.questLog[i] = { questID = 999030 + i, title = "Pin test " .. i } end
  S.login()
  slash("quests")
  click(win(), "Quest log")
  for i = 1, 3 do click(win(), "Track Pin test " .. i) end
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  click(win(), "Track Pin test 4")
  check(not questText(questViewer(), "Pin test 1") and questText(questViewer(), "Pin test 4"),
    "finishing objectives frees a pin slot for a new quest")
end

function S.questLibraryResume()
  local sections = LevelingCodexQuests.ALLIANCE.sections
  for i, name in ipairs({ "Earlier Active Quest", "Local Active Quest" }) do
    local id, map = 999040 + i, 1454 + i
    sections[#sections + 1] = { id = "active-test-" .. i, title = name, zone = map,
      levels = { 49, 50 }, verified = false, steps = {
        { type = "accept", quest = id, name = name, map = map, text = "Talk to the guide." },
        { type = "complete", quest = id, name = name, map = map, text = "Work on the objective." },
        { type = "turnin", quest = id, name = name, map = map, text = "Return to the guide." },
      } }
  end
  MOCK.level, MOCK.questMap = 50, 1456
  MOCK.questLog = {
    { questID = 999041, title = "Earlier Active Quest", objectives = { { text = "Widgets: 1/20" } } },
    { questID = 999042, title = "Local Active Quest", objectives = { { text = "Gizmos: 0/10" } } },
  }
  S.login()
  slash("quests")
  stepTool("Resume active quest")
  check(questText(questViewer(), "Complete - Local Active Quest"), "the local active quest takes precedence")
  click(win(), "Quest log")
  click(win(), "Show Earlier Active Quest")
  check(questText(questViewer(), "Complete - Earlier Active Quest") and questText(questViewer(), "Widgets 1/20"),
    "the library follows an unfinished objective from an earlier section")
end

function S.questClassCatchup()
  classSideFixture()
  MOCK.level = 31
  S.login()
  slash("quests")
  questQueue("Missed quests")
  check(questText(win(), "First class quest"), "older characters can still catch up on a class unlock")
  check(not questText(win(), "Second class quest"), "catch-up does not offer a locked follow-up")
end

function S.questHunterGuides()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 10, 1426
  S.login()
  slash("quests")
  check(guideButton("Hunter: Taming in Dun Morogh"), "Dwarves get their tame guide")
  check(not findButton(win(), function(l) return l == "Hunter: Taming in Elwynn" end), "Human taming is race filtered")
  check(not questText(win(), "Warrior: Defensive Stance"), "another class's guides are hidden")
  clickGuide("Hunter: Taming in Dun Morogh")
  check(questText(questViewer(), "Accept - Taming the Beast"), "the guide starts at the Dwarf taming pickup")
end

-- Horde class quests: inline steps on the route and side guides filtered by race.
function S.questHordeHunter()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Orc", 11, 1411
  S.login()
  slash("quests")
  check(routeHas("Taming the Beast"), "an Orc Hunter's Durotar route includes Taming the Beast")
  MOCK.faction = nil
end

function S.questHordeShaman()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap = "Horde", "Tauren", 20, 1413
  S.login()
  slash("quests")
  check(guideButton("Shaman: Water Totem"), "Tauren Shamans get the Horde Water Totem guide")
  clickGuide("Shaman: Water Totem")
  check(questText(questViewer(), "Call of Water"), "the Water Totem guide opens at its first step")
  MOCK.faction = nil
end

function S.questShamanGuides()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 30, 1455
  S.login()
  slash("quests")
  clickGuide("Shaman: Air Totem")
  check(questText(questViewer(), "Accept - Call of Air"), "the Air Totem quest is in the class guide at 30")
end

function S.questWestfallDeed()
  MOCK.level, MOCK.questMap = 12, 1436
  S.login()
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "no random drop needed to start Westfall")
  MOCK.bags[1972] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  check(questText(questViewer(), "Accept - Furlbrow's Deed"), "looting the deed reveals its pickup")
  local item = _G.LevelingCodexQuestItem
  check(item and item:IsShown(), "the deed can be used from the guide")
  MOCK.questLog = { { questID = 184 } }
  MOCK.bags[1972] = 0
  MOCK.event("QUEST_ACCEPTED", 1, 184)
  check(questText(questViewer(), "Turn in - Furlbrow's Deed"), "the hand-in stays after the pickup item is consumed")
  MOCK.questLog = {}
  MOCK.event("QUEST_TURNED_IN", 184)
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "the route resumes after the deed")
end

function S.questQuarryKeg()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 10, 1426
  S.login()
  slash("quests")
  check(not routeHas("Stolen Blasting Powder"), "the entire powder chain is hidden without the keg")
  MOCK.bags[268548] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  check(routeHas("Stolen Blasting Powder"), "looting the keg reveals the chain")
  MOCK.bags[268548] = 0
  MOCK.questDone[95213] = true
  MOCK.event("QUEST_TURNED_IN", 95213)
  check(routeHas("Complete - Stolen Blasting Powder"), "the follow-up stays visible after turning in the keg")
end

function S.questWestfall()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 13, 1436
  S.login()
  check(questText(questViewer(), "Westfall"), "Skyborne can enter the shared Westfall route")
  slash("quests")
  check(routeHas("The Defias Brotherhood"), "solo Defias lead-in is visible with dungeons off")
  check(not routeHas("Dungeon - The Deadmines"), "dungeon run is hidden by default")
  click(win(), "Settings")
  click(win(), "Plan every dungeon run")
  click(win(), "Quests")
  check(routeHas("Dungeon - The Deadmines"), "dungeon setting reveals the Deadmines run")
end

-- Reported in game: logging in at Menethil with Wetlands turn-ins ready kept the Duskwood guide,
-- because catch-up pulled Sven's whole chain (needed for The Doomed Fleet) from Duskwood.
function S.questLoginWetlandsLocal()
  local log = {
    { questID = 163, isComplete = true }, { questID = 164, isComplete = true },
    { questID = 96139, objectives = { { text = "Raven Hill Tome: 0/1" } } },
    { questID = 56, objectives = { { text = "Skeletal Warrior slain: 0/8" } } },
    { questID = 174, objectives = { { text = "Bronze Tube: 0/1" } } },
    { questID = 279, objectives = { { text = "Bluegill Murloc slain: 0/12" } } },
    { questID = 484, isComplete = true }, { questID = 98197, isComplete = true },
    { questID = 98282, objectives = { { text = "Unruptured Stalker Gland: 0/1" } } },
    { questID = 305, isComplete = true }, { questID = 463, isComplete = true },
    { questID = 470, objectives = { { text = "Sida's Bag: 0/1" } } },
    { questID = 288, objectives = { { text = "Flagon of Dwarven Honeymead: 0/1" } } },
    { questID = 98208, objectives = { { text = "Nord'el: 0/1" } } },
  }
  -- The client often has no position at the first update; Proving Your Worth makes Seeking Wisdom takeable.
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.questLog = "Human", 24, nil, log
  for _, id in ipairs({ 245, 268, 323 }) do MOCK.questDone[id] = true end
  S.login()
  MOCK.questMap, MOCK.questX, MOCK.questY = 1437, 10.4, 60.6
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  MOCK.advance(2)
  local frame = questViewer()
  check(questText(frame, "Wetlands") and not questText(frame, "Duskwood") and not questText(frame, "Sven"),
    "logging in at Menethil follows the Wetlands, not a Duskwood prerequisite")
  slash("quests")
  questQueue("Ready to turn in")
  check(questText(win(), "The Greenwarden"), "an optional breadcrumb in your log shows its turn-in")
end

-- Warriors with Fire Hardened Mail collect its Scorched Spider Fangs from the same Thelgen Rock
-- stalkers as Alchemical Hazards' gland; nobody else sees the step.
local function thelgenRoute(log)
  MOCK.race, MOCK.level, MOCK.questLog = "Human", 22, log
  MOCK.questMap, MOCK.questX, MOCK.questY = 1437, 52.6, 62.9
  S.login()
  slash("quests")
  click(win(), "Show all steps")
end

function S.questWarriorFangs()
  thelgenRoute({
    { questID = 98282, objectives = { { text = "Unruptured Stalker Gland: 0/1" } } },
    { questID = 1701, objectives = { { text = "Scorched Spider Fang: 12/50" }, { text = "Charred Horn: 0/12" },
      { text = "Galvanized Horn: 0/1" }, { text = "Vial of Phlogiston: 0/1" } } },
  })
  check(routeHas("Complete - Alchemical Hazards") and routeHas("Complete - Fire Hardened Mail"),
    "a Warrior with Fire Hardened Mail collects the fangs at Thelgen Rock")
end

function S.questWarriorFangsOtherClass() -- run as a Mage
  thelgenRoute({
    { questID = 98282, objectives = { { text = "Unruptured Stalker Gland: 0/1" } } },
    { questID = 1701, objectives = { { text = "Scorched Spider Fang: 12/50" } } },
  })
  check(routeHas("Complete - Alchemical Hazards") and not routeHas("Complete - Fire Hardened Mail"),
    "other classes never get the Warrior's fang step")
end

function S.questWarriorFangsNotTaken()
  LevelingCodexDB = { questOptional = true } -- even with optional quests shown
  thelgenRoute({ { questID = 98282, objectives = { { text = "Unruptured Stalker Gland: 0/1" } } } })
  check(routeHas("Complete - Alchemical Hazards") and not routeHas("Complete - Fire Hardened Mail"),
    "without Fire Hardened Mail in the log there is no fang step")
end

-- Class objectives the route passes (from the class quest audit): shown only to the class, only
-- while the quest is in the log. One check per faction, run as that class.
local function routeAt(race, level, map, x, y, log)
  MOCK.race, MOCK.level, MOCK.questLog = race, level, log
  MOCK.questMap, MOCK.questX, MOCK.questY = map, x, y
  S.login()
  slash("quests")
  click(win(), "Show all steps")
end

function S.questClassAlongDruid() -- run as a Druid
  routeAt("NightElf", 16, 1439, 47.0, 14.0, { { questID = 272, objectives = { { text = "Pendant of the Sea Lion: 0/1" } } } })
  check(routeHas("Travel - Trial of the Sea Lion"), "a Druid with Trial of the Sea Lion gets the Darkshore lockbox stop")
end

function S.questClassAlongDruidNotTaken() -- run as a Druid
  routeAt("NightElf", 16, 1439, 47.0, 14.0, {})
  check(routeHas("Darkshore") and not routeHas("Trial of the Sea Lion"), "no lockbox stop without the quest")
end

function S.questClassAlongShaman() -- run as a Shaman
  MOCK.faction = "Horde"
  routeAt("Orc", 13, 1413, 52.0, 30.0, { { questID = 1525, objectives = { { text = "Fire Tar: 0/1" }, { text = "Reagent Pouch: 0/1" } } } })
  check(routeHas("Complete - Call of Fire"), "a Shaman with Call of Fire gets the Fire Tar step at the Crossroads")
end

function S.questClassAlongShamanNotTaken() -- run as a Shaman
  MOCK.faction = "Horde"
  routeAt("Orc", 13, 1413, 52.0, 30.0, {})
  check(routeHas("Crossroads") and not routeHas("Complete - Call of Fire"), "no Fire Tar step without the quest")
end

-- Reported in game: with Show optional quests on, the step window said "Turn in - Unrequited Love"
-- (Hollee's note, carried from Darkshore) to a player who never took it.
function S.questCarriedTurninNotTaken()
  LevelingCodexDB = { questOptional = true }
  thelgenRoute({ { questID = 98282, objectives = { { text = "Unruptured Stalker Gland: 0/1" } } } })
  check(routeHas("Complete - Alchemical Hazards") and not routeHas("Turn in - Unrequited Love"),
    "no turn-in for an optional quest you don't have, even with optional quests shown")
end

function S.questCarriedTurninCarried()
  LevelingCodexDB = { questOptional = true }
  thelgenRoute({ { questID = 98282, objectives = { { text = "Unruptured Stalker Gland: 0/1" } } },
    { questID = 98461, isComplete = true } })
  check(routeHas("Turn in - Unrequited Love"), "carrying Hollee's note keeps its turn-in")
end

-- Outleveled pickups leave the route and guides show progress by level band.
function S.questGrey()
  local sections = LevelingCodexQuests.ALLIANCE.sections
  local function step(kind, id, name, level, chain)
    return { type = kind, quest = id, name = name, text = name, level = level, min = 1, chain = chain }
  end
  sections[#sections + 1] = { id = "test-grey", title = "Test grey route", zone = 1436, levels = { 12, 30 },
    verified = true, steps = {
      step("accept", 999301, "Grey Errand", 5), step("turnin", 999301, "Grey Errand", 5),
      step("accept", 999302, "Grey Prerequisite", 6), step("turnin", 999302, "Grey Prerequisite", 6),
      step("accept", 999303, "Fresh Follow-up", 20, { 999302 }), step("turnin", 999303, "Fresh Follow-up", 20, { 999302 }),
    } }
  MOCK.level, MOCK.questMap = 20, 1436
  S.login()
  slash("quests")
  clickGuide("Test grey route")
  local frame = questViewer()
  check(questText(frame, "Accept - Grey Prerequisite"), "a grey pickup leaves the route unless a later quest needs it")
  guidesView("Your level")
  check(questText(win(), "Current"), "the guide you're on leads Your level")
  click(win(), "All levels")
  check(findButton(win(), function(l) return l:find("LEVELS 12-20", 1, true) ~= nil end),
    "guides are grouped by level band with progress and status")
  check(not questText(win(), "% done"), "guides are rows with a tag, not buttons with a % done line")
  questQueue("Missed quests")
  check(questText(win(), "Outleveled (grey)") and questText(win(), "Grey Errand"), "the grey pickup is listed as outleveled")
  click(win(), "Settings")
  click(win(), "Keep grey quests in the route")
  check(questText(frame, "Accept - Grey Errand"), "the setting keeps grey pickups in the route")
end

-- Dungeon plans, the "find a group" moment, chain position and a full log.
function S.questDungeonPlan()
  local sections = LevelingCodexQuests.ALLIANCE.sections
  local function step(kind, id, name, text, extra)
    local s = { type = kind, quest = id, name = name, text = text, min = 13 }
    for k, v in pairs(extra or {}) do s[k] = v end
    return s
  end
  sections[#sections + 1] = { id = "test-plan-route", title = "Test plan route", zone = 1436, levels = { 13, 18 },
    verified = true, steps = {
      step("accept", 999201, "Plan Outdoor Errand", "Talk to the farmer."),
      step("accept", 999202, "Plan Dungeon Pickup", "Talk to the scout.", { optional = true, dungeon = "test-plan-dungeon" }),
      step("accept", 999205, "Plan Optional Errand", "Talk to the camper.", { optional = true }),
      step("turnin", 999201, "Plan Outdoor Errand", "Return to the farmer."),
      step("accept", 999206, "Plan Second Errand", "Talk to the farmer again.", { chain = { 999201 } }),
      step("accept", 999207, "Plan Third Errand", "Talk to the farmer once more.", { chain = { 999206 } }),
    } }
  sections[#sections + 1] = { id = "test-plan-dungeon", title = "Test Plan Dungeon", zone = 1436,
    levels = { 13, 18 }, side = true, category = "dungeon", verified = false,
    bosses = { { name = "Test Warden", tip = "Interrupt the test bolt." } }, steps = {
      step("accept", 999203, "Plan Dungeon Errand", "Talk to the guard.", { phase = "prepare" }),
      { type = "dungeon", phase = "prepare", name = "Test Plan Dungeon", text = "Enter the test dungeon with your group." },
      step("turnin", 999202, "Plan Dungeon Pickup", "Report to the scout.", { phase = "after" }),
      step("turnin", 999203, "Plan Dungeon Errand", "Report to the guard.", { phase = "after" }),
    } }
  MOCK.level, MOCK.questMap = 14, 1436
  S.login()
  slash("quests")
  clickGuide("Test plan route")
  local frame = questViewer()
  check(questText(frame, "Accept - Plan Outdoor Errand"), "the plan fixture starts at its first pickup")
  check(questText(frame, "Chain: part 1 of 3"), "a story chain shows its position")
  MOCK.questLog = { { questID = 999201, objectives = { { text = "Hay bales 0/3" } } } }
  MOCK.event("QUEST_ACCEPTED", 1, 999201)
  check(not questText(frame, "Plan Dungeon Pickup") and not questText(frame, "Plan Optional Errand"),
    "unplanned dungeon pickups and optional errands stay hidden")
  guidesView("Dungeons")
  check(findButton(win(), function(l) return l == "Recommended" end) and questText(win(), "Not planned"),
    "the dungeon list offers plans")
  click(win(), "Test Plan Dungeon")
  click(win(), "Bosses in order")
  check(questText(win(), "BOSSES IN ORDER") and questText(win(), "Interrupt the test bolt."), "the dungeon page retains boss tips")
  click(win(), "Quest checklist")
  click(win(), "Plan this run")
  check(findButton(win(), function(l) return l == "Planned: its pickups are in your route" end), "the dungeon page shows the plan")
  check(questText(frame, "Accept - Plan Dungeon Pickup"), "a planned run adds its pickup to the route")
  MOCK.questLog[2] = { questID = 999202 }
  MOCK.questLog[3] = { questID = 999203 }
  MOCK.event("QUEST_LOG_UPDATE")
  check(chatHas("Find a group"), "a planned run with its pickups done says to find a group")
  click(frame, "Run Test Plan Dungeon")
  check(questText(frame, "Enter the test dungeon"), "the run button opens the dungeon checklist")
  click(frame, "Return to leveling")
  click(win(), "Settings")
  click(win(), "Show optional quests")
  check(questText(frame, "Accept - Plan Optional Errand"), "optional errands follow their own setting")
  C_QuestLog.GetMaxNumQuestsCanAccept = function() return 3 end
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Your quest log is full (3/3)"), "a full log warns before a pickup")
  check(questText(frame, "Quests > Quest log lists ones you can drop"), "it points to where the clean-up list is")
  C_QuestLog.GetMaxNumQuestsCanAccept = nil
  click(win(), "Quests")
  guidesView("Dungeons")
  click(win(), "None")
  check(not findButton(frame, function(l) return l == "Run Test Plan Dungeon" end), "dropping the plan removes the run prompt")
end

function S.questCatchup()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 19, 1433
  for _, id in ipairs({ 244, 129, 130, 120 }) do MOCK.questDone[id] = true end
  MOCK.questLog = {
    { questID = 246, objectives = { { text = "Redridge Mongrels 4/10" } } },
    { questID = 3741, isComplete = true },
    { questID = 125 },
  }
  S.login()
  slash("quests")
  questQueue("Ready to turn in")
  check(questText(win(), "Hilary's Necklace"), "ready quests have their own list")
  stepTool("Resume active quest")
  check(questText(questViewer(), "Accept - The Price of Shoes"), "catch-up retains a prerequisite for later quests")
  MOCK.questDone[118] = true
  MOCK.event("QUEST_TURNED_IN", 118)
  check(questText(questViewer(), "Redridge Mongrels 4/10"), "resume opens an active objective")
  questQueue("Missed quests")
  check(questText(win(), "Selling Fish"), "earlier pickups remain available for review")
  check(next(LevelingCodexCharDB.questSkips) == nil, "catch-up leaves manual skips alone")
  questQueue("Ready to turn in")
  local ready
  for _, button in ipairs(MOCK.buttons(win())) do
    if button:IsVisible() and button.tipTitle == "Hilary's Necklace" then ready = button; break end
  end
  check(ready, "ready quest is clickable")
  ready:Click()
  check(questText(questViewer(), "Turn in - Hilary's Necklace"), "ready quest opens its turn-in")
  MOCK.questDone[3741] = true
  MOCK.questLog = { MOCK.questLog[1], MOCK.questLog[3] } -- the game takes it out of the log
  MOCK.event("QUEST_TURNED_IN", 3741)
  check(questText(questViewer(), "Redridge Mongrels 4/10"), "turn-in review returns to the resumed quest")
  check(not questText(win(), "Hilary's Necklace"), "turned-in quest leaves the ready list")
end

local function questDetourFixture()
  local route = LevelingCodexQuests.ALLIANCE
  local function quest(kind, id, name, chain)
    return { type = kind, quest = id, name = name, text = name, min = 12, level = 15, chain = chain }
  end
  local sections = route.sections
  sections[#sections + 1] = { id = "test-outbound", title = "Test outbound", zone = 1436, levels = { 12, 18 },
    verified = true, steps = {
      { type = "grind", text = "Choose a detour", level = 16, suggest = { "test-detour" } },
      quest("accept", 999101, "Earlier prerequisite"), quest("turnin", 999101, "Earlier prerequisite"),
      quest("accept", 999104, "Continue along the shared route"), quest("turnin", 999104, "Continue along the shared route"),
    } }
  sections[#sections + 1] = { id = "test-detour", title = "Test detour", zone = 1432, levels = { 12, 18 },
    verified = true, alternate = true, suggest = { "test-outbound" }, steps = {
      quest("accept", 999102, "Detour objective"), quest("complete", 999102, "Detour objective"),
      quest("turnin", 999102, "Detour objective"),
      quest("accept", 999103, "Detour follow-up", { 999101 }), quest("turnin", 999103, "Detour follow-up", { 999101 }),
    } }
end

function S.questDetour()
  questDetourFixture()
  MOCK.level, MOCK.questMap = 15, 1436
  S.login()
  slash("quests")
  clickGuide("Test outbound")
  local frame = questViewer()
  click(frame, "Try Test detour")
  check(questText(frame, "Accept - Detour objective"), "suggestion switches to the optional route")
  MOCK.questDone[999101], MOCK.questDone[999102], MOCK.questDone[999103] = true, true, true
  MOCK.level = 16
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "End of the alternate route"), "an alternate ends at its own boundary")
  click(frame, "Try Test outbound")
  check(questText(frame, "Continue along the shared route"), "the finished detour returns to the shared route")
  click(frame, "Next")
  check(frame:IsShown() and questText(frame, "End of the leveling guide"),
    "the shared route ends without continuing into a detour")
end

function S.questCrossZoneResume()
  questDetourFixture()
  MOCK.level, MOCK.questMap = 15, 1432
  MOCK.questLog = { { questID = 999102, objectives = { { text = "Detour progress 2/5" } } } }
  S.login()
  slash("quests")
  clickGuide("Test outbound")
  stepTool("Resume active quest")
  local frame = questViewer()
  check(not questText(frame, "Choose a detour"), "resume switches away from the selected guide")
  check(questText(frame, "Detour progress 2/5"), "resume starts with the objective in your zone")
  MOCK.questDone[999102], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 999102)
  check(questText(frame, "Accept - Earlier prerequisite"), "cross-zone resume retains an earlier prerequisite")
  check(questText(frame, "Required for Detour follow-up"), "catch-up explains why the earlier step is required")
  MOCK.questDone[999101] = true
  MOCK.event("QUEST_TURNED_IN", 999101)
  check(questText(frame, "Accept - Detour follow-up"), "the prerequisite leads back to the quest that needed it")
  check(next(LevelingCodexCharDB.questSkips) == nil, "resume leaves manual skips alone")
end

function S.questZoneResume()
  questDetourFixture()
  MOCK.level, MOCK.questMap = 15, 1436
  MOCK.questLog = { { questID = 999102, objectives = { { text = "Detour progress 2/5" } } } }
  S.login()
  local frame = questViewer()
  check((questText(frame, "Westfall") and questText(frame, "Levels 12-18")), "a remote active quest does not pull the guide away at login")

  MOCK.onTaxi, MOCK.questMap = true, 1432
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check((questText(frame, "Westfall") and questText(frame, "Levels 12-18")), "a taxi flyover does not change sections")
  MOCK.onTaxi = false
  MOCK.event("PLAYER_CONTROL_GAINED")
  check(questText(frame, "Detour progress 2/5"), "entering a zone catches up to its active quest")
  MOCK.questDone[999102], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 999102)
  check(questText(frame, "Accept - Earlier prerequisite") and questText(frame, "Required for Detour follow-up"),
    "zone catch-up keeps the required pickup for when the route needs it")
  MOCK.questDone[999101] = true
  MOCK.event("QUEST_TURNED_IN", 999101)
  check(questText(frame, "Accept - Detour follow-up"), "catch-up returns to the quest that needed it")
  check(next(LevelingCodexCharDB.questSkips) == nil, "zone catch-up does not write skips")
end

function S.questLoginResume()
  questDetourFixture()
  MOCK.level, MOCK.questMap = 15, 1432
  C_QuestLog.GetAllCompletedQuestIDs = function() return { 999101 } end
  S.login()
  MOCK.event("QUEST_LOG_UPDATE") -- The client can send an empty update before the first real log.
  MOCK.questLog = { { questID = 999102, isComplete = true } }
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(questViewer(), "Turn in - Detour objective"),
    "a late quest log resumes at the turn-in and uses completed history from the bulk scan")
end

function S.questHistoryResume()
  questDetourFixture()
  MOCK.level, MOCK.questMap = 15, 1432
  local section = LevelingCodexQuests.ALLIANCE.sections[#LevelingCodexQuests.ALLIANCE.sections]
  table.insert(section.steps, 1, { type = "sethearth", bind = "Thelsamar", text = "Bind before starting" })
  C_QuestLog.GetAllCompletedQuestIDs = function() return { 999101, 999102 } end
  S.login()
  local frame = questViewer()
  check(questText(frame, "Accept - Detour follow-up"), "completed local history skips earlier setup with no active quest")
  check(not questText(frame, "Bind before starting"), "the earlier bind is not required to resume")
end

function S.questAlternateRoutes()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  S.login()
  local frame = questViewer()
  check((questText(frame, "Loch Modan") and questText(frame, "Levels 11-18")), "starting in Loch Modan selects its local route")
  check(questText(frame, "Flight path - Thelsamar, Loch Modan"), "local start skips the way there")
  check(questText(frame, "Use Next to skip this flight path"), "the flight path explains how to skip")
  click(frame, "Next")
  check(questText(frame, "Accept - Thelsamar Blood Sausages"), "Loch Modan starts with a Thelsamar pickup")
  check(not LevelingCodexCharDB.questFlights["Thelsamar, Loch Modan"], "skipping does not record a flight path as learned")
  slash("quests")
  check(guideButton("Darkshore"), "other suitable routes are offered through Routes")
  clickGuide("Darkshore")
  check(questText(frame, "Boat - Stormwind Harbor - Auberdine"), "Darkshore provides the way to Auberdine")
  MOCK.questMap = 1439
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check(questText(frame, "Flight path - Auberdine, Darkshore"), "entering Darkshore skips the approach")
  click(frame, "Next")
  MOCK.bind = "Auberdine"
  MOCK.event("HEARTHSTONE_BOUND")
  check(questText(frame, "Accept - Washed Ashore"), "Darkshore continues with its first pickup")
  MOCK.questMap = 1432
  MOCK.event("ZONE_CHANGED_NEW_AREA")
  check((questText(frame, "Loch Modan") and questText(frame, "Levels 11-18")), "entering another alternate zone follows its available pickups")
end

function S.questLochHistory()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 18, 1432
  local completed, seen = {}, {}
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "loch-modan" then
      for _, step in ipairs(section.steps) do
        if step.quest and not seen[step.quest] then
          completed[#completed + 1], seen[step.quest] = step.quest, true
        end
      end
    end
  end
  C_QuestLog.GetAllCompletedQuestIDs = function() return completed end
  S.login()
  local frame = questViewer()
  check(questText(frame, "End of the alternate route"), "completed Loch Modan history advances past setup and reminders")
  check(not findButton(frame, function(label) return label == "Next" end), "a completed route needs no manual Next")
  slash("quests")
  check(questText(win(), "Complete"), "the completed selected route has an explicit Complete badge")
end

function S.questLochReady()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 17, 1432
  MOCK.questLog = { { questID = 250 } }
  C_QuestLog.IsComplete = function(id) return id == 250 or id == 199 end
  S.login()
  local frame = questViewer()
  check(questText(frame, "Cross to the east ramp"), "a client-complete delivery resumes at the barrel")
  MOCK.questLog = { { questID = 199 } }
  MOCK.event("QUEST_TURNED_IN", 250)
  check(questText(frame, "Take the clue back to Hinderweir"), "the same-title follow-up keeps its own turn-in")
end

function S.questLochFlight()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 12, 1432
  local learned = false
  C_TaxiMap = { GetTaxiNodesForMap = function(map)
    if map == 1415 then return { { name = "Thelsamar, Loch Modan", isUndiscovered = not learned } } end
  end }
  S.login()
  local frame = questViewer()
  check(questText(frame, "Flight path - Thelsamar, Loch Modan"), "unknown flight is shown")
  learned = true
  MOCK.event("NEW_TAXI_PATH")
  C_TaxiMap = nil
  check(not questText(frame, "Flight path - Thelsamar, Loch Modan")
    and questText(frame, "Accept - Thelsamar Blood Sausages"), "learning the flight path advances without Next")
end

function S.questLochBingles()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 17, 1432
  MOCK.questX, MOCK.questY = 48.73, 30.09
  local objectives = {
    { text = "Wrench 0/1" }, { text = "Screwdriver 0/1" },
    { text = "Hammer 0/1" }, { text = "Blastencapper 0/1" },
  }
  MOCK.questLog = { { questID = 2038, objectives = objectives } }
  S.login()
  local frame, arrow = questViewer(), LevelingCodexQuestArrow
  check(questText(frame, "Wrench 0/1") and questText(arrow, "Arrived"), "Bingles starts at the wrench camp")
  objectives[1].text, objectives[1].finished = "Wrench 1/1", true
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Screwdriver 0/1") and not questText(frame, "Wrench 1/1") and questText(arrow, " yd"),
    "the wrench advances the waypoint to the screwdriver")
  for i = 2, 4 do objectives[i].finished = true end
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Turn in - Bingles' Missing Supplies"), "all four tools advance to the turn-in")
end

function S.questWestfallDetour()
  MOCK.level, MOCK.questMap, MOCK.bind = 14, 1436, "Sentinel Hill"
  LevelingCodexCharDB = { questFlights = { ["Sentinel Hill, Westfall"] = true } }
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "westfall" then
      for _, step in ipairs(section.steps) do
        if step.type == "grind" then break end
        if step.quest then MOCK.questDone[step.quest] = true end
      end
    end
  end
  S.login()
  local frame = questViewer()
  check(findButton(frame, function(label) return label == "Try Loch Modan" end), "the step window offers a detour")
  slash("quests")
  check(guideButton("Loch Modan"), "Westfall offers Loch Modan through Routes")
  guideButton("Darkshore"):Click()
  check(not questText(frame, "Levels 12-20"), "previewing a route doesn't switch to it")
  click(win(), "Start this route")
  check((questText(frame, "Darkshore") and questText(frame, "Levels 12-20")), "Westfall also offers quest XP through Darkshore")
end

function S.questRecorder()
  S.login()
  MOCK.interactionQuest = 783
  MOCK.event("QUEST_DETAIL")
  check(not LevelingCodexDB.rec, "recording is off by default")
  slash("record")
  LevelingCodexDB.questAutoAccept = true
  MOCK.combat = true
  MOCK.event("QUEST_DETAIL")
  check(not MOCK.questAccepted, "no automatic acceptance in combat")
  MOCK.combat = false
  MOCK.event("QUEST_DETAIL")
  check(MOCK.questAccepted == 783, "accepts the active guide quest out of combat")
  local objective = { text = "Speak to McBride 0/1", numFulfilled = 0, numRequired = 1 }
  MOCK.questLog = { { questID = 783, title = "A Threat Within", objectives = { objective } } }
  MOCK.event("QUEST_ACCEPTED", 783)
  objective.text, objective.numFulfilled, objective.finished = "Speak to McBride 1/1", 1, true
  MOCK.event("QUEST_LOG_UPDATE")
  local records = LevelingCodexDB.rec
  check(records[#records].type == "complete" and records[#records].count == 1 and records[#records].map == 1429,
    "objective gain records the count and map")
  LevelingCodexDB.questAutoTurnin = true
  MOCK.questChoices = 1
  MOCK.event("QUEST_COMPLETE")
  check(not MOCK.questRewarded, "never picks a reward")
  MOCK.questChoices = 0
  MOCK.event("QUEST_COMPLETE")
  check(MOCK.questRewarded == 783, "turns in the active quest without reward choices")
  MOCK.event("QUEST_TURNED_IN", 783)
  check(LevelingCodexDB.rec and #LevelingCodexDB.rec >= 3, "quest events recorded")
  slash("record")
  local count = #LevelingCodexDB.rec
  MOCK.event("QUEST_DETAIL")
  check(#LevelingCodexDB.rec == count, "toggling recording off stops new observations")
end

function S.questController(mode)
  MOCK.gamepad, MOCK.gamepadUI = true, true
  S.login()
  local frame = questViewer()
  local manager = GamepadMode.FrameControlsManager
  slash("quests")
  click(win(), "Step")
  check(manager:GetActiveFrame() == win(), "the Codex has native controller focus")
  if mode == "backup" then MOCK.padNoFocus = true end
  win().padChrome.close:Click()
  MOCK.advance(0.6)
  check(not win():IsShown() and frame:IsShown(), "the X closes the Codex and leaves the step guide visible")
  check(manager:GetActiveFrame() == nil, "closing the Codex returns native focus to gameplay")
  check(not (LevelingCodexPadFocus and LevelingCodexPadFocus:IsShown()),
    "closing the Codex does not give the step guide backup focus")
  check(not frame._gamepad and not frame._padStick, "the step guide leaves controller buttons and movement to the game")
  MOCK.event("GAME_PAD_ACTIVE_CHANGED")
  check(manager:GetActiveFrame() == nil, "using the controller again leaves focus with gameplay")

  MOCK.padNoFocus = nil
  slash("quests")
  check(manager:GetActiveFrame() == win(), "opening the Codex gives its controls native focus again")
  click(win(), "Next step")
  check(questText(frame, "Accept - Nibbled-On Book"), "Next step in Quests advances the guide")
  click(win(), "Previous step")
  check(questText(frame, "Accept - A Threat Within"), "Previous step in Quests goes back")
  click(win(), "Hide step window")
  check(not frame:IsShown(), "the guide can be hidden from Quests")
  click(win(), "Show step window")
  check(frame:IsShown(), "the guide can be shown again from Quests")
end

function S.questControllerBackup()
  S.questController("backup")
end

-- the level the plan puts a point in, as the guide reads (nil before 10)
local function planAt(level)
  local hit
  for _, p in ipairs(D().plan) do
    if level >= p.from and level <= p.to then hit = p end
  end
  return hit
end

----------------------------------------------------------------------------
-- Talent window mock: retail-style trait buttons nested a few frames deep.
----------------------------------------------------------------------------

local talent = {}
S.talent = talent

-- mode "name": buttons answer GetDefinitionInfo() with a spellID (C_Traits style)
-- mode "icon": buttons only carry an icon texture
-- all = "all": a button for every talent of the class tree, not only the guide plan's
function S.makeTalentWindow(mode, frameName, all)
  if not D() then return end
  local root = CreateFrame("Frame", frameName or "PlayerSpellsFrame", UIParent)
  root:SetSize(800, 600)
  root:Hide()
  local talents = CreateFrame("Frame", nil, root)
  local canvas = CreateFrame("Frame", nil, talents)
  local trees = {}
  talent.root, talent.byName, talent.mode = root, {}, mode
  local id = 9000
  local function addButton(tree, name, iconName)
    if not trees[tree] then trees[tree] = CreateFrame("Frame", nil, canvas) end
    id = id + 1
    local b = CreateFrame("Button", nil, trees[tree])
    b:SetSize(40, 40)
    local spellID = id
    MOCK.spells[spellID] = name
    if mode == "name" then
      b.GetDefinitionInfo = function() return { spellID = b.spellID } end
      b.spellID = spellID
    end
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\Icons\\" .. iconName)
    b.iconTex = tex
    -- the trait UI's node shapes: circle, square and choice nodes, each with its own border art
    local shapes = { "circle", "square", "choice" }
    b.expectShape = shapes[(id % 3) + 1]
    if mode == "name" then
      b.StateBorder = b:CreateTexture(nil, "OVERLAY")
      b.StateBorder:SetAllPoints()
      b.StateBorder:SetAtlas("talents-node-" .. b.expectShape .. "-yellow")
    else
      b.IconMask = b:CreateTexture(nil, "ARTWORK") -- only the mask tells the shape
      b.IconMask:SetAtlas("talents-node-" .. b.expectShape .. "-mask")
    end
    return b
  end
  -- decoys first, so a sloppy finder picks the wrong thing
  for i = 1, 25 do addButton("Decoy", "Decoy Talent " .. i, "inv_misc_questionmark_decoy" .. i) end
  for _, p in ipairs(D().plan) do
    if not talent.byName[p.name] then talent.byName[p.name] = addButton(p.tree, p.name, p.icon) end
  end
  local tree = all == "all" and MOCK.ns.talentTrees and MOCK.ns.talentTrees[MOCK.class]
  for _, t in ipairs(tree and tree.talents or {}) do
    if not talent.byName[t.name] then talent.byName[t.name] = addButton(tree.tabs[t.tab], t.name, t.icon) end
  end
  ToggleTalentFrame_Mock = function() if root:IsShown() then root:Hide() else root:Show() end end
  return root
end

----------------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------------

-- The client's start-up order: our ADDON_LOADED, PLAYER_LOGIN, PLAYER_ENTERING_WORLD.
function S.login()
  MOCK.event("ADDON_LOADED", "LevelingCodex")
  MOCK.event("VARIABLES_LOADED")
  MOCK.event("PLAYER_LOGIN")
  MOCK.event("PLAYER_ENTERING_WORLD", true, false)
  MOCK.advance(1)
  check(type(LevelingCodexDB) == "table", "LevelingCodexDB created")
  check(type(LevelingCodexCharDB) == "table", "LevelingCodexCharDB created")
  if D() then
    check(chatHas("loaded the"), "login message")
    local mini = _G.LevelingCodexMinimapButton
    if LevelingCodexDB.noMinimap then
      check(not (mini and mini:IsShown()), "minimap button hidden when turned off")
    else
      check(mini and mini:IsShown(), "minimap button shown")
    end
  end
end

-- Level 1 -> 60, letting each banner play out.
function S.levelups()
  for level = 2, 60 do
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level, 10, 0, 0, 0, 0, 0)
    MOCK.advance(1.2)
    if D() and not LevelingCodexDB.noToast then
      check(not (toast() and toast():IsShown()), "banner waits for the game's own level-up display (level " .. level .. ")")
    end
    MOCK.advance(3.3)
    if D() and not LevelingCodexDB.noToast then
      local t = toast()
      check(t and t:IsShown(), "banner shown at level " .. level)
      check(t.title and t.title:GetText() == "New at Level " .. level, "banner title at level " .. level)
    end
    MOCK.advance(10)
    if D() then check(not toast():IsShown(), "banner fades by itself at level " .. level) end
  end
end

-- The banner always closes by itself, even with the cursor on it (a controller leaves the hidden
-- cursor in the middle of the screen, where the banner sits: the owner's banner never went away);
-- click opens the window.
function S.bannerMouse()
  if not D() then return end
  MOCK.level = 20
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(4.5)
  local t = toast()
  MOCK.mouseOver[t] = true
  MOCK.advance(12)
  check(not t:IsShown(), "banner fades by itself with the cursor on it")
  MOCK.mouseOver[t] = nil
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(4.5)
  MOCK.fire(t, "OnMouseUp", "LeftButton")
  MOCK.advance(1.5)
  check(not t:IsShown(), "left-click dismisses the banner")
  check(win() and win():IsShown(), "left-click on the banner opens the window")
  win():Hide()
end

-- Banner test mode, drag, right-click close, /codex test N.
function S.bannerTest()
  if not D() then return end
  slash("test")
  MOCK.advance(0.6)
  local t = toast()
  check(t:IsShown(), "test banner shown")
  MOCK.advance(20)
  check(t:IsShown(), "test banner stays up")
  MOCK.drag(t, 40, -25)
  check(LevelingCodexDB.toastPos, "dragging the test banner saves its position")
  MOCK.fire(t, "OnMouseUp", "LeftButton")
  check(t:IsShown(), "left-click keeps the test banner")
  MOCK.fire(t, "OnMouseUp", "RightButton")
  MOCK.advance(1.5)
  check(not t:IsShown(), "right-click closes the test banner")
  for _, l in ipairs({ 1, 9, 10, 30, 59, 60 }) do
    slash("test " .. l)
    MOCK.advance(0.6)
    check(t.title:GetText() == "New at Level " .. l, "/codex test " .. l)
    MOCK.fire(t, "OnMouseUp", "RightButton")
    MOCK.advance(1.5)
  end
end

local TABS = { "This Level", "Talents", "Trainer", "Macros", "Tips", "Professions", "Quests", "Stats", "Settings" }

local function openAt(level, tab)
  MOCK.level = level
  if not (win() and win():IsShown()) then slash("") end
  check(win():IsShown(), "window opens")
  local now = findButton(win(), function(l) return l == "You" or l:find("^Back to") end)
  check(now, "level reset button")
  now:Click()
  click(win(), tab)
end

-- Browse every level 1-60 on every tab with the arrows, hovering everything.
function S.browse()
  if not D() then
    slash("")
    check(chatHas("no guide for your class"), "unsupported class message")
    return
  end
  for _, tab in ipairs(TABS) do
    openAt(1, tab)
    for level = 1, 60 do
      local b = MOCK.buttons(win())
      for _, x in ipairs(b) do hover(x) end
      MOCK.staleUnder(win(), tab .. " at " .. level)
      if level < 60 then click(win(), ">") end
    end
    for _ = 1, 65 do click(win(), "<") end
  end
  win():Hide()
end

-- Click every button on every tab, each from a fresh state, at a few levels.
function S.everyButton()
  if not D() then return end
  for _, level in ipairs({ 1, 9, 10, 30, 60 }) do
    for _, tab in ipairs(TABS) do
      openAt(level, tab)
      local n = #MOCK.buttons(win())
      for i = 1, n do
        openAt(level, tab)
        local list = MOCK.buttons(win())
        local b = list[i]
        if b then
          hover(b)
          b:Click("LeftButton")
          MOCK.advance(0.3)
          if win() and win():IsShown() then MOCK.staleUnder(win(), tab .. " after a click") end
        end
      end
      -- leave the banner closed for the next round
      local t = toast()
      if t and t.unlocked then openAt(level, "Settings"); click(win(), "Lock banner") end
      if t and t:IsShown() then MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
    end
  end
  if win() then win():Hide() end
  -- clicking every toggle an odd number of times leaves things off: put the defaults back
  for _, k in ipairs({ "noToast", "quiet", "noAutoMacros", "noTalentGuide", "noMinimap", "noAutoTrack", "noProfCards", "noCraftGuide", "padNative" }) do
    if LevelingCodexDB[k] then
      LevelingCodexDB[k] = nil
    end
  end
  slash("minimap"); slash("minimap") -- re-apply the minimap setting
  -- the path cards were clicked too: back to the Codex guide's path
  LevelingCodexCharDB.talentPath, LevelingCodexCharDB.customTalents = nil, nil
end

-- Settings: both themes, all pad names, banner move/lock, sizes, window position.
function S.settings()
  if not D() then return end
  openAt(30, "Settings")
  click(win(), "Codex (gold)")
  check(LevelingCodexDB.theme == "codex", "theme saved")
  check(win() and win():IsShown(), "window rebuilt and shown after theme switch")
  click(win(), "This Level")
  click(win(), "Settings")
  click(win(), "Forever (teal)")
  check(LevelingCodexDB.theme == "forever", "theme back to forever")
  for _, pad in ipairs({ "PlayStation", "Switch", "Xbox" }) do click(win(), "Settings"); click(win(), pad) end
  click(win(), "Move banner")
  check(toast():IsShown() and toast().unlocked, "banner unlocked and shown")
  MOCK.drag(toast(), -30, 10)
  click(win(), "Lock banner")
  check(not toast():IsShown(), "banner hidden after lock")
  click(win(), "+"); click(win(), "+"); click(win(), "-")
  MOCK.drag(win(), 10, 10)
  click(win(), "Settings")
  win():Hide()
end

-- Minimap: show/hide, hover, clicks and drag (round and square minimaps).
function S.minimap()
  if not D() then return end
  local mini = _G.LevelingCodexMinimapButton
  check(mini and mini:IsShown(), "minimap button exists")
  check((mini.icon._path or ""):lower():find("achievement_level_60"), "the Level 60 badge, not the common book")
  if LevelingCodexDB.minimapAngle == nil then
    -- right side, about 10 degrees up: clear of Forever's own buttons and the lower-left spot most addons use
    local _, rel, _, x, y = mini:GetPoint(1)
    check(rel == Minimap and x > 0 and y > 0 and y < x * 0.3, "default spot on the right (" .. tostring(x) .. ", " .. tostring(y) .. ")")
  end
  hover(mini)
  mini:Click("LeftButton")
  check(win():IsShown(), "left-click opens the window")
  mini:Click("LeftButton")
  check(not win():IsShown(), "left-click again closes it")
  local function viewerShown() local v = _G.LevelingCodexQuestViewer; return v and v:IsShown() end
  local before = viewerShown()
  mini:Click("RightButton")
  if before then
    check(not viewerShown() and not win():IsShown(), "right-click hides the step window, not the Codex")
  else
    check(viewerShown() or win():IsShown(), "right-click shows the step window (or the Quests tab without a step)")
  end
  if win():IsShown() then win():Hide() end
  mini:Click("RightButton")
  check(viewerShown() == before, "right-click again puts it back")
  if win():IsShown() then win():Hide() end
  for _, shape in ipairs({ "ROUND", "SQUARE" }) do
    MOCK.minimapShape = shape
    MOCK.fire(mini, "OnDragStart", "LeftButton")
    local cx, cy = Minimap:GetCenter()
    MOCK.cursor = { cx, cy + 100 }
    MOCK.advance(0.1)
    MOCK.cursor = { cx - 100, cy }
    MOCK.advance(0.1)
    MOCK.fire(mini, "OnDragStop")
    check(math.abs((LevelingCodexDB.minimapAngle or -1) - 180) < 0.01, "drag saves the angle (" .. shape .. ")")
    local _, rel, _, x, y = mini:GetPoint(1)
    check(rel == Minimap and x < 0 and math.abs(y) < 0.01, "button sits on the left of the minimap (" .. shape .. ")")
  end
  slash("minimap")
  check(not mini:IsShown(), "/codex minimap hides it")
  slash("minimap")
  check(mini:IsShown(), "/codex minimap shows it")
end

----------------------------------------------------------------------------
-- Controller (Gamepad.lua): Forever's navigation, the Codex's own as a backup
----------------------------------------------------------------------------

local function pad(f, b) MOCK.fire(f, "OnGamePadButtonDown", b) end
local function nav() return GamepadMode.FrameControlsManager end

-- Forever's controller UI on: the window joins its navigation.
function S.padForever()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Settings")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "window handed to Forever's window manager")
  check(win()._padScroll ~= nil, "scroll area registered")
  -- tooltip-only icons ignored, clickable pieces not
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and b.padSkip then check(b._padIgnored, "tooltip-only piece ignored") end
    if b:IsShown() and not b.padSkip then check(not b._padIgnored, "clickable piece not ignored: " .. tostring(b.tipTitle)) end
  end
  local n = #MOCK.padRefreshed
  click(win(), "Professions")
  check(#MOCK.padRefreshed > n, "buttons re-read after a redraw")
  -- (Review 4) after switching tabs the marks follow each strip's click
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() then check((b._padIgnored == true) == (b.padSkip == true), "mark follows the strip after a tab switch") end
  end
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: Forever navigation"), "debug line")
  win():Hide()
  check(MOCK.padHidden[win()], "closing hands it back (Review 2: Hide/Esc path)")
  check(win()._padPropagate ~= false, "input passes through once closed")
  MOCK.gamepadUI = nil
end

-- (Review 1) a theme switch rebuilds the window: the old one is handed back, the new one joins.
function S.padThemeRebuild()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Settings")
  local old = win()
  click(win(), "Codex (gold)")
  check(MOCK.padHidden[old], "old frame handed back")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown and win() ~= old, "the rebuilt window is handed over")
  click(win(), "Forever (teal)")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- LB/RB switch tabs (both modes), keeping B-to-close.
function S.padTabs()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level")
  pad(win(), "PADRSHOULDER")
  check(MOCK.textUnder(win()):find("Talent tree") and win()._padPropagate == false, "RB: next tab (Talents), button kept")
  pad(win(), "PADLSHOULDER"); pad(win(), "PADLSHOULDER")
  check(MOCK.textUnder(win()):find("Minimap button"), "LB twice from Talents wraps to Settings")
  pad(win(), "PAD1")
  check(win()._padPropagate == true, "A is Forever's in Forever mode")
  pad(win(), "PAD2")
  check(not win():IsShown(), "B closes")
  MOCK.gamepadUI = nil
end

-- Opened in combat: Forever's functions wait until combat ends (the mock flags any call in combat).
function S.padCombatOpen()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  MOCK.combat = true
  openAt(30, "Settings")
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(not shown, "not handed over in combat")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.6)
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "handed over once combat ends")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- (Review 5) picking up the controller while the window is open.
function S.padPickUp()
  if not D() or not GamepadMode then return end
  openAt(30, "Settings")
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: not in use"), "no controller: not in use")
  MOCK.gamepadUI = true
  MOCK.event("GAME_PAD_ACTIVE_CHANGED", true)
  MOCK.advance(0.6)
  local shown = false
  for _, f in ipairs(nav().shown) do if f == win() then shown = true end end
  check(shown, "joins Forever's navigation without reopening")
  win():Hide()
  MOCK.gamepadUI = nil
end

local function focusLabel()
  local t = LevelingCodexPadFocus and LevelingCodexPadFocus.target
  return t and (t.label and t.label:GetText() or t.tipTitle or (t.GetText and t:GetText())) or ""
end

local function reachSkillUpTick()
  for _ = 1, 80 do
    if focusLabel():find("Profession skill%-up cards") then return true end
    pad(win(), "PADDDOWN")
  end
end

-- Backup when Forever refuses: the D-pad, A, scrolling, B.
function S.padBackup()
  if not D() or not GamepadMode then return end
  for _, how in ipairs({ "error", "no focus", "setting", "no manager" }) do
    MOCK.gamepadUI = true
    local saved = GamepadMode
    if how == "error" then MOCK.padRefuse = true end
    if how == "no focus" then MOCK.padNoFocus = true end
    if how == "setting" then LevelingCodexDB.padNative = false end
    if how == "no manager" then GamepadMode = nil; MOCK.gamepad = true end
    openAt(30, "Settings")
    MOCK.advance(0.6)
    check(LevelingCodexPadFocus and LevelingCodexPadFocus:IsShown(), "highlight shown (" .. how .. ")")
    check(reachSkillUpTick(), "D-pad reaches the skill-up tick (" .. how .. ")")
    check(GameTooltip:IsOwned(LevelingCodexPadFocus.target), "focusing shows its tooltip")
    check(win()._padPropagate == false, "the D-pad is the Codex's in this mode")
    pad(win(), "PAD1")
    check(LevelingCodexDB.noProfCards == true, "A ticks it (" .. how .. ")")
    pad(win(), "PAD1")
    check(not LevelingCodexDB.noProfCards, "A unticks it")
    MOCK.chat = {}; slash("debug")
    check(chatHas("controller: Codex navigation %("), "debug says why (" .. how .. ")")
    pad(win(), "PAD2")
    check(not win():IsShown() and not LevelingCodexPadFocus:IsShown(), "B closes, highlight goes")
    MOCK.padRefuse, MOCK.padNoFocus, LevelingCodexDB.padNative, MOCK.gamepad = nil, nil, nil, nil
    GamepadMode = saved
    MOCK.gamepadUI = nil
  end
end

-- Moving past the bottom scrolls; the right stick scrolls.
function S.padBackupScroll()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  for _ = 1, 80 do -- down past the first screen (the content shows about 480 px)
    local t = LevelingCodexPadFocus.target
    if t.padY and t.padY > 600 then break end
    pad(win(), "PADDDOWN")
  end
  check((LevelingCodexPadFocus.target.padY or 0) > 600, "the D-pad reaches the lower part of Settings")
  check(LevelingCodexPadFocus.target:IsShown(), "focused piece visible")
  check(MOCK.scrollOf(win()) > 0, "scrolled to bring a lower piece into view")
  local before = MOCK.scrollOf(win())
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 1)
  MOCK.advance(0.5)
  check(MOCK.scrollOf(win()) < before, "right stick up scrolls up")
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 0)
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- (Review 3) combat starts while the window is open in Codex mode: a D-pad press must not leave
-- the window swallowing the controller, and after combat the highlight is back where it was.
function S.padBackupCombat()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  pad(win(), "PADDDOWN")
  local t = LevelingCodexPadFocus.target
  check(win()._padPropagate == false, "the D-pad is the Codex's before combat")
  MOCK.event("PLAYER_REGEN_DISABLED"); MOCK.combat = true
  pad(win(), "PADDDOWN")
  check(win()._padPropagate == true and not LevelingCodexPadFocus:IsShown(), "in combat the controller goes to the game")
  MOCK.combat = false; MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.1)
  check(LevelingCodexPadFocus:IsShown() and LevelingCodexPadFocus.target == t, "after combat the highlight is back where it was")
  pad(win(), "PADDDOWN")
  check(LevelingCodexPadFocus.target ~= t, "and the D-pad moves it again")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- The copy box: a popup for Forever, the backup otherwise.
function S.padCopyBox()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  S.copyOpen()
  local copy = _G.LevelingCodexCopy
  local shown = false
  for _, f in ipairs(nav().shown) do if f == copy then shown = copy._padPopup == true end end
  check(shown, "copy box joins as a popup")
  pad(copy, "PAD2"); check(not copy:IsShown(), "B closes the copy box")
  LevelingCodexDB.padNative = false
  S.copyOpen()
  check(LevelingCodexPadFocus:IsShown() and LevelingCodexPadFocus.target == copy.edit, "backup focuses the text first")
  pad(copy, "PADDRIGHT")
  check(LevelingCodexPadFocus.target ~= copy.edit, "D-pad moves to the box's buttons")
  pad(copy, "PAD2")
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- Review fixes 1-2: combat starting releases the controller (also after LB/RB in Forever mode)
-- and hands the window back to Forever, so closing it in combat leaves no ghost window behind.
function S.padForeverCombat()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  MOCK.padHidden = {}
  openAt(30, "This Level")
  pad(win(), "PADRSHOULDER")
  MOCK.event("PLAYER_REGEN_DISABLED")
  check(win()._padPropagate == true, "combat starting releases the controller after RB")
  check(MOCK.padHidden[win()], "and hands the window back to Forever before combat")
  MOCK.combat = true
  win():Hide()                                   -- closed with Esc in combat
  MOCK.combat = false; MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.6)
  local ghost = false
  for _, f in ipairs(nav().shown) do if f == win() then ghost = true end end
  check(not ghost, "no ghost window left with Forever")
  slash(""); MOCK.advance(0.6)
  MOCK.chat = {}; slash("debug")
  check(chatHas("controller: Forever navigation"), "the next opening joins Forever again")
  -- combat that starts without its event reaching us: the hand-back waits for combat to end
  MOCK.padHidden = {}
  MOCK.combat = true
  win():Hide()
  check(not MOCK.padHidden[win()], "nothing called in combat")
  MOCK.combat = false; MOCK.event("PLAYER_REGEN_ENABLED"); MOCK.advance(0.1)
  check(MOCK.padHidden[win()], "handed back once combat ends")
  MOCK.gamepadUI = nil
end

-- Review fix 3: the Talents tab's tree nodes and every-point rows are reachable.
function S.padTalents()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "Talents")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b:IsShown() and b:GetScript("OnClick") then
      check(not b._padIgnored, "Forever: clickable piece not ignored: " .. tostring(b.tipTitle))
    end
  end
  win():Hide()
  LevelingCodexDB.padNative = false
  openAt(30, "Talents")
  local node, row
  for _ = 1, 120 do
    local t = LevelingCodexPadFocus.target
    local title = t and t.tipTitle or ""
    if title:find("^Level %d+:") then row = t; break end
    if title:find("%d/%d") and t:GetScript("OnClick") then node = t end
    pad(win(), "PADDDOWN")
  end
  check(node, "the D-pad reaches a talent tree node")
  check(row, "the D-pad reaches the every-point rows")
  local level = row and tonumber(row.tipTitle:match("^Level (%d+)"))
  pad(win(), "PAD1")
  check(level and MOCK.textUnder(win()):find("Level " .. level) and not MOCK.textUnder(win()):find("Talent tree"),
    "A on a row opens that level")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- Review fix 4: tooltip-only pieces are out of Forever's focus before the window joins, and a
-- redraw that hides the focused piece puts the focus back on the window.
function S.padForeverFocus()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level"); win():Hide()          -- This Level has tooltip-only icons
  for _, b in ipairs(MOCK.buttons(win())) do b._padIgnored = nil end -- fresh widgets
  slash(""); MOCK.advance(0.1)
  check(MOCK.padMarksAtJoin == true, "marks in place when the window joins")
  click(win(), "Settings")
  local tick
  for _, b in ipairs(MOCK.buttons(win())) do if b:IsShown() and b._type == "CheckButton" then tick = b end end
  SmartNavigation._current = tick                -- Forever's focus on a Settings tick
  pad(win(), "PADRSHOULDER")                     -- Settings -> This Level: the tick is gone
  local cur = SmartNavigation:GetCurrentButton()
  check(cur and cur:IsShown() and not cur._padIgnored, "focus back on a shown, clickable piece")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- Review fix 9: LB/RB belong to the window Forever's focus is in.
function S.padForeverActive()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  openAt(30, "This Level")
  local other = CreateFrame("Frame", nil, UIParent)
  table.insert(nav().shown, other)               -- the player moved the focus to another window (LT/RT)
  pad(win(), "PADRSHOULDER")
  check(win()._padPropagate == true and not MOCK.textUnder(win()):find("Talent tree"), "LB/RB left to the focused window")
  table.remove(nav().shown)
  pad(win(), "PADRSHOULDER")
  check(MOCK.textUnder(win()):find("Talent tree"), "back on the Codex, RB switches its tab")
  win():Hide()
  MOCK.gamepadUI = nil
end

-- Review fix 7: after the right stick scrolls, the highlight sits on a piece in view.
function S.padStickKeepsFocus()
  if not D() or not GamepadMode then return end
  LevelingCodexDB.padNative = false; MOCK.gamepadUI = true
  openAt(30, "Settings")
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, -1)
  MOCK.advance(1.5)
  MOCK.fire(win(), "OnGamePadStick", "Right", 0, 0)
  local off = MOCK.scrollOf(win())
  check(off > 0, "the stick scrolled down")
  local _, _, _, _, ty = LevelingCodexPadFocus.target:GetPoint(1)
  check(ty and -ty >= off - 30 and -ty <= off + 480, "the highlight is on a piece in view (" .. tostring(ty) .. ", " .. off .. ")")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
end

-- Forever's addon compartment (the addons button under the clock) lists the Codex.
function S.compartment()
  if not D() or not AddonCompartmentFrame then return end
  local found = {}
  for _, a in ipairs(AddonCompartmentFrame.registeredAddons) do
    if a.text == "The Leveling Codex" then found[#found + 1] = a end
  end
  check(#found == 1, "the Codex is in the addon compartment once (" .. #found .. ")")
  local entry = found[1]
  if not entry then return end
  check(type(entry.icon) == "string" and entry.icon:lower():find("achievement_level_60"), "with the Level 60 badge")
  entry.func(entry, { buttonName = "LeftButton" })
  check(win() and win():IsShown(), "click opens the Codex")
  entry.func(entry, { buttonName = "LeftButton" })
  check(not win():IsShown(), "click again closes it")
  local function viewerShown() local v = _G.LevelingCodexQuestViewer; return v and v:IsShown() end
  local before = viewerShown()
  entry.func(entry, { buttonName = "RightButton" })
  if before then
    check(not viewerShown() and not win():IsShown(), "right-click hides the step window, not the Codex")
  else
    check(viewerShown() or win():IsShown(), "right-click shows the step window (or the Quests tab without a step)")
  end
  if win():IsShown() then win():Hide() end
  entry.func(entry, { buttonName = "RightButton" })
  check(viewerShown() == before, "right-click again puts it back")
  if win():IsShown() then win():Hide() end
  local owner = CreateFrame("Button", nil, UIParent)
  entry.funcOnEnter(owner)
  local lines = table.concat(GameTooltip._lines or {}, " / ")
  check(GameTooltip:IsOwned(owner) and lines:find("The Leveling Codex") and lines:find("Left%-click"), "hover shows the tooltip")
  check(not lines:find("Drag"), "no minimap drag hint in the compartment")
  entry.funcOnLeave(owner)
end

-- Every slash command, including junk.
function S.slash()
  for _, cmd in ipairs({ "", "", "pad ps", "pad switch", "pad nope", "pad xbox", "test", "test 45", "banner", "banner",
      "quiet", "quiet", "minimap", "minimap", "reset", "debug", "help", "MACROS", "  test  ", "zzz" }) do
    slash(cmd)
    MOCK.advance(0.2)
  end
  if win() then win():Hide() end
  if toast() then MOCK.fire(toast(), "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
end

-- Macros at every level, staying within the client's limits.
function S.macros()
  if not D() then slash("macros"); return end
  for level = 1, 60 do
    MOCK.level = level
    slash("macros")
  end
  check(#MOCK.macros > 0, "macros were created")
  -- combat: deferred until the fight ends
  MOCK.macros = {}
  MOCK.combat = true
  slash("macros")
  check(#MOCK.macros == 0, "no macros made in combat")
  check(chatHas("in combat"), "combat message")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  check(#MOCK.macros > 0, "macros made when combat ends")
  -- no free slots
  MOCK.macros = {}
  MOCK.charMacroSlots = 0
  slash("macros")
  check(chatHas("couldn't make"), "full macro slots reported")
  local copy = _G.LevelingCodexCopy
  check(copy and copy:IsShown(), "copy box offered when macros can't be made")
  local want = {}
  for _, m in ipairs(D().macros) do if MOCK.level >= m.lo and MOCK.level <= m.hi then want[#want + 1] = m end end
  check(copy.edit:GetText() == want[1].body, "copy box holds the first macro that failed")
  if #want > 1 then
    click(copy, "Next")
    check(copy.edit:GetText() == want[2].body, "Next shows the second failed macro")
    click(copy, "Back")
    check(copy.edit:GetText() == want[1].body, "Back returns to the first")
  end
  click(copy, "Done")
  check(not copy:IsShown(), "Done closes the copy box")
  MOCK.charMacroSlots = nil
end

-- The player already has their own macro under one of the guide's names: Set up macros keeps
-- it, says so, and offers the Codex version in the copy box.
function S.ownMacroSameName()
  if not D() then return end
  MOCK.level = 30
  local list = {}
  for _, m in ipairs(D().macros) do if 30 >= m.lo and 30 <= m.hi then list[#list + 1] = m end end
  if #list == 0 then return end
  local name = list[1].name
  MOCK.macros = { { name = name, icon = 1, body = "/say this one is mine", perChar = true } }
  if LevelingCodexCharDB then LevelingCodexCharDB.made = nil end
  MOCK.chat = {}
  slash("macros")
  check(MOCK.macros[1].body == "/say this one is mine", "player's own " .. name .. " macro kept")
  check(chatHas("kept your own"), "chat says the player's macro was kept")
  local copy = _G.LevelingCodexCopy
  check(copy and copy:IsShown() and copy.edit:GetText() == list[1].body, "copy box offers the Codex version of " .. name)
  copy:Hide()
  -- and the level-up refresh leaves it alone too
  MOCK.level = 31
  MOCK.event("PLAYER_LEVEL_UP", 31)
  MOCK.advance(1.5)
  check(MOCK.macros[1].body == "/say this one is mine", "level-up leaves the player's macro alone")
  MOCK.advance(12)
  MOCK.macros = {}
end

-- The Copy button on a macro card: body selected, read-only, Esc closes and frees the keyboard.
function S.copyMacro()
  if not D() then return end
  openAt(30, "Macros")
  local list = {}
  for _, m in ipairs(D().macros) do if 30 >= m.lo and 30 <= m.hi then list[#list + 1] = m end end
  if #list == 0 then win():Hide(); return end
  click(win(), "Copy")
  local copy = _G.LevelingCodexCopy
  check(copy:IsShown(), "copy box opens")
  local eb = copy.edit
  check(eb:GetText() == list[1].body, "copy box shows the macro body")
  check(eb:HasFocus() and eb._highlight, "body is selected and focused")
  eb._text = "oops"
  MOCK.fire(eb, "OnTextChanged", true)
  check(eb:GetText() == list[1].body, "typing can't change the macro")
  MOCK.fire(eb, "OnEscapePressed")
  check(not copy:IsShown() and not eb:HasFocus(), "Esc closes it and gives the keyboard back")
  win():Hide()
end

-- Each tab keeps its own scroll position.
function S.scrollMemory()
  if not D() then return end
  local function scroller(f)
    for _, c in ipairs((f or win())._children) do
      if c._type == "ScrollFrame" then return c end
      local inner = scroller(c)
      if inner then return inner end
    end
  end
  openAt(30, "Talents")
  local sf = scroller()
  sf:SetVerticalScroll(300)
  local talents = sf:GetVerticalScroll()
  check(talents > 0, "talents tab scrolls")
  click(win(), "Trainer")
  check(sf:GetVerticalScroll() == 0, "trainer tab starts at the top")
  sf:SetVerticalScroll(120)
  click(win(), "Talents")
  check(sf:GetVerticalScroll() == talents, "talents tab scroll kept")
  click(win(), "Trainer")
  check(sf:GetVerticalScroll() == 120, "trainer tab scroll kept")
  click(win(), ">")
  check(sf:GetVerticalScroll() == 120, "browsing levels keeps the scroll")
  win():Hide()
  slash("")
  check(sf:GetVerticalScroll() == 120, "reopening keeps the scroll")
  win():Hide()
end

-- Controller: B or Back closes the window, other buttons pass through to the game.
function S.gamepadClose()
  if not D() or MOCK.minimal then return end
  for _, name in ipairs({ "LevelingCodexFrame", "LevelingCodexCopy" }) do
    if name == "LevelingCodexFrame" then slash("") else S.copyOpen() end
    local f = _G[name]
    check(f:IsShown(), name .. " open")
    MOCK.fire(f, "OnGamePadButtonDown", "PAD1")
    check(f:IsShown() and f._padPropagate == true, "A passes through on " .. name)
    MOCK.combat = true
    MOCK.fire(f, "OnGamePadButtonDown", "PAD2")
    check(f:IsShown() and f._padPropagate == true, "in combat B is left to the game on " .. name)
    MOCK.combat = false
    MOCK.fire(f, "OnGamePadButtonDown", "PAD2")
    check(not f:IsShown(), "B closes " .. name)
    check(f._padPropagate == true, "input passes through again once closed (" .. name .. ")")
  end
  if win() then win():Hide() end
end
function S.copyOpen()
  openAt(30, "Macros")
  local b = findButton(win(), function(l) return l == "Copy" end)
  if b then b:Click() else _G.LevelingCodexCopy:Show() end
  win():Hide()
end

-- The key binding toggles the window.
function S.binding()
  if not D() then return end
  for _, body in ipairs(BINDING_BODIES or {}) do
    local f = assert(loadstring(body))
    f()
    check(win():IsShown(), "binding opens the window")
    f()
    check(not win():IsShown(), "binding closes the window")
  end
end

-- Macros the addon made follow your level (auto-update), your own macros are left alone.
function S.macroAutoUpdate()
  if not D() then return end
  MOCK.macros = {}
  -- a macro of the player's own that shares no name with ours
  MOCK.macros[1] = { name = "MyOwnMacro", icon = 1, body = "/say hi", perChar = true }
  MOCK.level = 1
  for level = 1, 60 do
    MOCK.level = level
    if level == 1 then slash("macros") end
    MOCK.event("PLAYER_LEVEL_UP", level)
    MOCK.advance(1.5)
    for _, m in ipairs(D().macros) do
      if level >= m.lo and level <= m.hi then
        local i = GetMacroIndexByName(m.name)
        if i > 0 and LevelingCodexCharDB.made and LevelingCodexCharDB.made[m.name] then
          check(MOCK.macros[i].body == m.body, "macro " .. m.name .. " follows level " .. level)
        end
      end
    end
  end
  check(MOCK.macros[1].body == "/say hi", "player's own macro untouched")
  if toast() then MOCK.advance(12) end
end

local function installedMacroBody(name)
  local macro = MOCK.macros[GetMacroIndexByName(name)]
  return macro and macro.body
end

function S.druidMacros()
  local function has(name, text)
    local body = installedMacroBody(name)
    return body and body:find(text, 1, true)
  end

  MOCK.level = 60
  if not MOCK.minimal then
    -- A character can log in with an old macro and no record of who made it.
    MOCK.macros = { { name = "Heal up", icon = 134400, perChar = true,
      body = "#showtooltip\n/cancelform\n/cast [@player,combat] Regrowth; [@player] Healing Touch" } }
    LevelingCodexCharDB.made = nil
  end
  slash("macros")
  check(has("Heal up", "[@player,combat] reset=combat Rejuvenation, Regrowth"), "combat Heal up starts with self Rejuvenation")
  check(has("Heal up", "[@player,nocombat] reset=combat Healing Touch, Regrowth"), "out of combat Heal up starts with self Healing Touch")
  check(has("Fight Cat", "/dismount") and has("Fight Cat", "Rake,Claw,Claw,Claw,Ferocious Bite"),
    "Fight Cat shifts and retains the full rotation")
  check(has("Prowl Cat", "[noform:3,known:1066][noform:2,noknown:1066] Cat Form")
      and has("Prowl Cat", "[combat] Shifting Power; [nostealth] Prowl; Ravage"),
    "Prowl Cat accounts for both Cat slots and keeps its existing abilities")
  check(has("Panic Bear", "/dismount") and has("Panic Bear", "[noform:1] Dire Bear Form")
      and has("Panic Bear", "/cast Frenzied Regeneration\n/cast Enrage"),
    "Panic Bear shifts before its emergency abilities")
  check(has("Cancel Form", "Moonkin Form\n/cancelform"), "Cancel Form is created with a form-sensitive tooltip")
end

function S.warriorPackMacros()
  local function has(name, text)
    local body = installedMacroBody(name)
    return body and body:find(text, 1, true) and true or false
  end
  MOCK.level = 1
  slash("macros")
  check(has("Fight", "Heroic Strike") and has("Fight", "/targetenemy [noharm][dead]"),
    "Warrior's first Fight attacks and picks the nearest enemy when none is selected")
  check(not installedMacroBody("Fight pack"), "no Clap macro before training level")

  MOCK.level = 6
  slash("macros")
  check(has("Fight", "[nocombat,harm,nodead] Charge; [harm,nodead] Heroic Strike"),
    "Fight Charges out of combat and queues Heroic Strike in combat after level 4")
  check(installedMacroBody("Fight pack"):match("\n/cast Thunder Clap$") and not has("Fight pack", "Cleave"),
    "Thunder Clap has its button as soon as it can be trained, without Cleave yet")

  MOCK.level = 20
  slash("macros")
  local fight = installedMacroBody("Fight")
  check(fight:find("[nocombat,harm,nodead] Battle Stance", 1, true) and
    fight:find("[combat,nostance:2,known:71] Defensive Stance", 1, true) and fight:find("Sunder Armor\n", 1, true),
    "pre-Vanguard Fight dances to Battle for Charge and back to Defensive for Sunder")
  check(fight:match("\n/cast %[combat%] Bloodrage$"), "Bloodrage rides after the attack, in combat only")
  check(not installedMacroBody("Rage up") and not installedMacroBody("Cleave"),
    "Bloodrage and Cleave no longer take their own macro slots")
  check(installedMacroBody("Fight pack"):match("\n/cast Thunder Clap\n/cast %[harm,nodead%] Cleave$"),
    "Cleave rides after Thunder Clap from 20")
  check(has("Battle Shout", "[combat,harm,nodead,known:1160] Demoralizing Shout; Battle Shout"),
    "the Shout button buffs out of combat and Demoralizing Shouts in combat")
  check(has("Taunt", "[@targettarget,harm,nodead] Taunt\n") and
    installedMacroBody("Taunt"):match("\n/cast [^\n]*Sunder Armor$"),
    "Taunt works through a selected party member and Sunders on the same press")
  check(has("Revenge", "[stance:1,harm,nodead] Overpower; [harm,nodead] Revenge\n") and
    installedMacroBody("Revenge"):match("Shield Block$"), "Revenge casts Overpower in Battle and Shield Block rides along")
  check(has("Block & Revenge", "[nostance:2,equipped:Shields] Defensive Stance;") and
    installedMacroBody("Block & Revenge"):match("\n/cast %[stance:2,harm,nodead%] Revenge$"),
    "Shield Block can enter Defensive and Revenge rides along")
  check(has("Victory Rush", "/targetenemy [noharm][dead]"), "Victory Rush picks the next enemy after a kill")
  check(has("Shield Bash", "[@mouseover,harm,nodead][harm,nodead] Shield Bash"), "Shield Bash takes a mouseover enemy")
  check(not installedMacroBody("Shield Slam"), "no Shield Slam macro before its talent level")
  for _, m in ipairs(MOCK.macros) do
    check(not m.body:find("/castsequence", 1, true), m.name .. " never uses a cast sequence")
  end

  MOCK.level = 30
  slash("macros")
  fight = installedMacroBody("Fight")
  check(fight:find("[nocombat,stance:2,known:1310317,harm]", 1, true) and
    fight:find("[nocombat,harm] Battle Stance", 1, true),
    "Fight uses Defensive Charge with Vanguard and retains a Battle fallback")
  local clap = installedMacroBody("Fight pack")
  check(clap:find("[stance:3,known:71] Defensive Stance;", 1, true) and clap:find("; Thunder Clap\n", 1, true) and
    not clap:find("Sunder", 1, true), "Berserker can swap for Clap")

  MOCK.level = 40
  slash("macros")
  check(installedMacroBody("Fight"):find("Sunder Armor\n", 1, true), "Sunder stays usable when Shield Slam unlocks")
  check(has("Shield Slam", "[harm,nodead] Shield Slam\n") and installedMacroBody("Shield Slam"):match("Shield Block$"),
    "Shield Slam has its own button with Shield Block riding along")
  check(installedMacroBody("Panic"):match("\n/cast Last Stand$"), "Last Stand has its own button")
  check((installedMacroBody("Shield Wall") or ""):match("\n/cast [^\n]*Shield Wall$"), "Shield Wall has its own button")
  check(has("Shield Wall", "[nostance:2,equipped:Shields] Defensive Stance;"),
    "Shield Wall can enter Defensive with a shield equipped")
  check(has("Shield Bash", "[stance:3,harm,nodead] Pummel;") and has("Shield Bash", "[equipped:Shields,harm,nodead] Shield Bash;"),
    "one interrupt button chooses Pummel or Shield Bash")
end

function S.warriorMacroUpgrade()
  LevelingCodexCharDB.made = nil
  local pack = "#showtooltip\n/startattack\n/cast [combat,stance:1] Defensive Stance\n" ..
    "/castsequence [combat] reset=target Thunder Clap, Sunder Armor, Cleave, Sunder Armor, Sunder Armor"
  local fight = "#showtooltip\n/startattack\n/cast [nocombat] Charge\n/cast [nostance:2] Defensive Stance\n" ..
    "/castsequence [combat] reset=target Shield Slam, Rend, Sunder Armor, Sunder Armor, Shield Slam, Sunder Armor, Sunder Armor, Sunder Armor"
  MOCK.macros = {
    { name = "Fight pack", icon = 1, body = pack, perChar = true },
    { name = "Fight", icon = 1, body = fight, perChar = true },
    { name = "Panic", icon = 1, body = "#showtooltip\n/castsequence reset=180 Last Stand, Shield Wall", perChar = true },
    { name = "Victory Rush", icon = 1, body = "/say mine", perChar = true },
    { name = "Taunt", icon = 1, body = "#showtooltip Taunt\n/cast [stance:2,harm,nodead] Taunt", perChar = true },
    -- from the one-spell-per-button build
    { name = "Revenge", icon = 1, body = "#showtooltip\n/startattack\n/cast Revenge", perChar = true },
    { name = "Shield Slam", icon = 1, perChar = true,
      body = "#showtooltip Shield Slam\n/startattack [harm,nodead]\n/cast [harm,nodead] Shield Slam" },
  }
  MOCK.level = 40
  MOCK.event("PLAYER_LEVEL_UP", 40)
  MOCK.advance(1.5)
  check(#MOCK.macros == 7, "automatic upgrade edits existing macros only")
  check(MOCK.macros[1].name == "Fight pack" and MOCK.macros[1].body:match("Cleave$"),
    "legacy pack macro updates in place without SavedVariables")
  check(MOCK.macros[2].name == "Fight" and MOCK.macros[2].body:match("Bloodrage$"),
    "legacy single-target loop updates in place without SavedVariables")
  check(MOCK.macros[3].name == "Panic" and MOCK.macros[3].body:match("\n/cast Last Stand$"),
    "legacy defensive sequence updates in place without SavedVariables")
  check(MOCK.macros[5].name == "Taunt" and MOCK.macros[5].body:find("Sunder Armor", 1, true),
    "Taunt from the split-macro build updates in place without SavedVariables")
  check(MOCK.macros[6].body:find("Overpower", 1, true) and MOCK.macros[7].body:match("Shield Block$"),
    "one-spell buttons from the previous build update in place without SavedVariables")
  slash("macros")
  check(MOCK.macros[4].body == "/say mine" and chatHas("kept your own"), "manual upgrade preserves a player macro")
  check(installedMacroBody("Shield Wall") and installedMacroBody("Block & Revenge"), "setup adds newly available buttons")
end

-- Talent tracing against a mock talent window.
local function traceCheck(level, expectTrace)
  local hit = planAt(level)
  local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
  if not hit then
    check(not (trace and trace:IsShown()), "no trace before 10 (level " .. level .. ")")
    return
  end
  check(hint and hint:IsShown(), "hint card shown at level " .. level)
  local _, rel = hint:GetPoint(1)
  check(rel == talent.root, "hint card sits on the talent window at level " .. level)
  if expectTrace then
    check(trace and trace:IsShown(), "trace shown at level " .. level)
    local _, on = trace:GetPoint(1)
    local want = talent.byName[hit.name]
    if talent.mode == "icon" then
      -- talents can share an icon: any button wearing the right icon is a correct match
      check(on and on.iconTex and on.iconTex._tex == want.iconTex._tex, "trace on " .. hit.name .. "'s icon at level " .. level)
    else
      check(on == want, "trace on " .. hit.name .. " at level " .. level)
    end
  end
end

local function runTalentLevels(expectTrace)
  for level = 1, 60 do
    MOCK.level = level
    ToggleTalentFrame()
    MOCK.advance(0.8)
    traceCheck(level, expectTrace)
    ToggleTalentFrame()
    MOCK.advance(0.8)
    local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
    check(not (trace and trace:IsShown()), "trace hidden after closing (level " .. level .. ")")
    check(not (hint and hint:IsShown()), "hint hidden after closing (level " .. level .. ")")
  end
end

function S.talentByName()
  if not D() then return end
  runTalentLevels(not MOCK.minimal) -- minimal API has no way to read talent names or icons
end

function S.talentByIcon()
  if not D() then return end
  runTalentLevels(not MOCK.minimal)
end

-- Turning the guide off hides it.
function S.talentGuideOff()
  if not D() then return end
  MOCK.level = 30
  openAt(30, "Settings")
  click(win(), "Trace my talent in the talent window")
  check(LevelingCodexDB.noTalentGuide, "check box turns the guide off")
  win():Hide()
  ToggleTalentFrame()
  MOCK.advance(0.8)
  local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
  check(not (trace and trace:IsShown()) and not (hint and hint:IsShown()), "guide hidden when turned off")
  ToggleTalentFrame()
  openAt(30, "Settings")
  click(win(), "Trace my talent in the talent window")
  check(not LevelingCodexDB.noTalentGuide, "check box turns the guide back on")
  win():Hide()
end

-- Levelling up in combat (the killing blow) must not create macros nobody asked for.
function S.combatLevelUp()
  if not D() then return end
  MOCK.macros = {}
  MOCK.level = 20
  MOCK.combat = true
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(1.5)
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.5)
  check(#MOCK.macros == 0, "combat level-up created " .. #MOCK.macros .. " macro(s) nobody asked for")
  -- but macros the Codex made are still brought up to date after the fight
  MOCK.level = 9
  slash("macros")
  local before = #MOCK.macros
  check(before > 0, "macros made at 9")
  MOCK.level = 10
  MOCK.combat = true
  MOCK.event("PLAYER_LEVEL_UP", 10)
  MOCK.advance(1.5)
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.5)
  check(#MOCK.macros == before, "no new macros after combat")
  for _, m in ipairs(D().macros) do
    if 10 >= m.lo and 10 <= m.hi then
      local i = GetMacroIndexByName(m.name)
      if i > 0 then check(MOCK.macros[i].body == m.body, m.name .. " updated after combat") end
    end
  end
  MOCK.advance(12)
end

-- SavedVariables didn't load: macros made last session must still follow your level,
-- and the player is told their settings didn't persist.
function S.lostSavedVariables()
  if not D() then return end
  -- this run started with no saved variables but with last session's macros (see run.py)
  local found
  for _, line in ipairs(MOCK.chat) do if line:find("didn't load") then found = true end end
  check(found, "chat note that settings didn't persist")
  openAt(MOCK.level, "Settings")
  check(MOCK.textUnder(win()):find("didn't load"), "settings tab shows the note")
  win():Hide()
  for level = MOCK.level + 1, 60 do
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level)
    MOCK.advance(1.5)
    -- the set your path gives (the class runs spend a spec path's talents first: that path's macros)
    for _, m in ipairs(MOCK.ns.pathMacros()) do
      if level >= m.lo and level <= m.hi then
        local i = GetMacroIndexByName(m.name)
        if i > 0 then check(MOCK.macros[i].body == m.body, m.name .. " follows level " .. level .. " without saved variables") end
      end
    end
    MOCK.advance(10)
  end
  check(MOCK.macros[1].body == "/say mine", "player's own macro untouched")
end

-- A clean install must not claim settings were lost.
function S.noFalseLostNote()
  for _, line in ipairs(MOCK.chat) do check(not line:find("didn't load"), "no lost-settings note on a fresh install") end
end

-- Once the talent is traced, the finder stops walking the window.
function S.talentFinderCost()
  if not D() or MOCK.minimal then return end
  MOCK.level = 30
  ToggleTalentFrame()
  MOCK.advance(1)
  traceCheck(30, true)
  local walked = MOCK.walked
  MOCK.advance(20)
  check(MOCK.walked - walked < 5, "finder kept walking the tree (" .. (MOCK.walked - walked) .. " walks in 20s)")
  -- talent not in the window (other tab): searches back off instead of walking every second
  local hit = planAt(30)
  local b = talent.byName[hit.name]
  b:Hide()
  walked = MOCK.walked
  MOCK.advance(30)
  local perSearch = 40 -- frames in the mock window
  local searches = (MOCK.walked - walked) / perSearch
  check(searches <= 10, "finder searched " .. searches .. " times in 30s while the talent was missing")
  b:Show()
  MOCK.advance(10)
  traceCheck(30, true)
  ToggleTalentFrame()
  MOCK.advance(0.5)
end

-- Reported in game: the trace stayed up after closing the talent window. Close it every way
-- (Esc/close button hide it directly, not through the toggle) and check nothing is left.
function S.talentCloseDirect()
  if not D() or MOCK.minimal then return end
  for _, level in ipairs({ 10, 16, 30, 60 }) do
    MOCK.level = level
    talent.root:Show()
    MOCK.advance(0.6)
    traceCheck(level, true)
    talent.root:Hide() -- no toggle, no time passing
    local trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
    check(not trace:IsShown() and not hint:IsShown(), "guide hidden the moment the window closes (level " .. level .. ")")
    MOCK.advance(5)
    check(not trace:IsShown() and not hint:IsShown(), "guide stays hidden after closing (level " .. level .. ")")
  end
end

-- Talent buttons are pooled: when the traced button is reused for another talent, the trace follows.
function S.talentPooledButtons()
  if not D() or MOCK.minimal or talent.mode ~= "name" then return end
  MOCK.level = 30
  ToggleTalentFrame()
  MOCK.advance(1)
  traceCheck(30, true)
  local hit = planAt(30)
  local a = talent.byName[hit.name]
  -- swap the spells of the traced button and a decoy
  local decoy = MOCK.buttons(talent.root)[1]
  a.spellID, decoy.spellID = decoy.spellID, a.spellID
  talent.byName[hit.name] = decoy
  MOCK.advance(1)
  traceCheck(30, true)
  a.spellID, decoy.spellID = decoy.spellID, a.spellID
  talent.byName[hit.name] = a
  MOCK.advance(1)
  traceCheck(30, true)
  ToggleTalentFrame()
  MOCK.advance(0.5)
end

-- A talent UI that loads on demand after login, under a name we don't know, opened by its own
-- toggle function: the guide still finds it.
function S.lateTalentUI()
  if not D() or MOCK.minimal then return end
  local root = S.makeTalentWindow("name", "ForeverTalentsUI")
  function PlayerSpellsFrame_Toggle() if root:IsShown() then root:Hide() else root:Show() end end
  MOCK.event("ADDON_LOADED", "Blizzard_PlayerSpells")
  MOCK.advance(1)
  MOCK.level = 30
  PlayerSpellsFrame_Toggle()
  MOCK.advance(1)
  traceCheck(30, true)
  PlayerSpellsFrame_Toggle()
  MOCK.advance(1)
  local hint = _G.LevelingCodexTalentHint
  check(not (hint and hint:IsShown()), "hint hides when the late talent UI closes")
end

-- The guide only shows while there's a point to spend, and traces the next point in the plan.
function S.talentPoints()
  if not D() or not talent.root then return end
  local trace, hint
  local function guideShown()
    trace, hint = _G.LevelingCodexTalentTrace, _G.LevelingCodexTalentHint
    return (trace and trace:IsShown()) or (hint and hint:IsShown())
  end
  MOCK.level = 30
  MOCK.unspent = 0
  talent.root:Show()
  MOCK.advance(1)
  check(not guideShown(), "nothing shown with 0 points to spend")
  -- two points left at 30: the level-29 point comes first
  MOCK.unspent = 2
  MOCK.advance(0.5)
  check(hint and hint:IsShown(), "hint shown with 2 points to spend")
  check(hint.label:GetText():find("2 POINTS TO SPEND"), "hint says 2 points to spend")
  if not MOCK.minimal then
    local want = talent.byName[planAt(29).name]
    local _, on = trace:GetPoint(1)
    check(on == want or (talent.mode == "icon" and on.iconTex._tex == want.iconTex._tex), "traces the level-29 point first")
  end
  MOCK.unspent = 1
  MOCK.advance(0.5)
  traceCheck(30, not MOCK.minimal)
  -- the player clicks it: no points left, the guide goes away while the window stays open
  MOCK.unspent = 0
  MOCK.advance(0.5)
  check(not guideShown(), "guide hides once the point is spent")
  check(talent.root:IsShown(), "talent window still open")
  talent.root:Hide()
  MOCK.unspent = nil
  MOCK.advance(0.5)
end

-- The trace takes the talent button's shape (circle, square or choice node).
function S.talentShape()
  if not D() or not talent.root or MOCK.minimal then return end
  local seen = {}
  for level = 10, 60 do
    MOCK.level = level
    talent.root:Show()
    MOCK.advance(0.6)
    local trace = _G.LevelingCodexTalentTrace
    local _, b = trace:GetPoint(1)
    if b and b.expectShape then
      check(trace.shape == b.expectShape, "trace shape " .. tostring(trace.shape) .. ", button is " .. b.expectShape .. " (level " .. level .. ")")
      if talent.mode == "name" then
        check(trace.copied and trace.shapeLine._atlas == b.StateBorder._atlas, "trace copies the button's border art (level " .. level .. ")")
        local _, rel = trace.shapeLine:GetPoint(1)
        check(rel == b.StateBorder, "outline sits on the button's border (level " .. level .. ")")
      else
        check(not trace.copied, "no border art to copy in icon mode")
        check(trace.disc:IsShown() == (b.expectShape ~= "square"), "round glow for round nodes (level " .. level .. ")")
        check(trace.edges[1]:IsShown() == (b.expectShape == "square"), "box only for square nodes (level " .. level .. ")")
        if b.expectShape == "square" then
          -- Forever's square nodes have clipped corners: the outline cuts them too
          check(trace.cut and trace.cut > 0, "square outline has clipped corners (level " .. level .. ")")
          for i, k in ipairs(trace.corners) do
            check(k:IsShown() and k._rot and math.abs(math.abs(math.deg(k._rot)) - 45) < 0.01,
              "corner cut " .. i .. " drawn at 45 degrees (level " .. level .. ")")
          end
          local _, _, _, x = trace.edges[1]:GetPoint(1)
          check(x == -3 + trace.cut, "top side starts after the corner cut (level " .. level .. ")")
        else
          for _, k in ipairs(trace.corners) do check(not k:IsShown(), "no corner cuts on round nodes") end
        end
      end
      seen[b.expectShape] = true
    end
    talent.root:Hide()
    MOCK.advance(0.3)
  end
  check(seen.circle and seen.square, "both circle and square talents were traced")
end

-- /codex debug runs anywhere and reports the art and the talent guide.
----------------------------------------------------------------------------
-- Gathering tracking: Forever drops Find Herbs / Find Minerals; the Codex turns it back on.
----------------------------------------------------------------------------

local TRACK = {
  herbs = { name = "Find Herbs", texture = 133939, category = "spell", spellID = 2383 },
  minerals = { name = "Find Minerals", texture = 136025, category = "spell", spellID = 2580 },
  beasts = { name = "Track Beasts", texture = 132328, category = "spell", spellID = 1494 },
  flight = { name = "Flight Master", texture = 136456, category = "other", active = true },
}

local function trackEntry(name)
  for i, t in ipairs(MOCK.tracking) do if t.name == name then return t, i end end
end

local function trackOn(name)
  local t = trackEntry(name)
  return t and t.active
end

local function gatherOn()
  return trackOn("Find Herbs") or trackOn("Find Minerals")
end

-- what the client does at a loading screen: gathering tracking is gone
local function dropTracking()
  for _, t in ipairs(MOCK.tracking) do if t.category == "spell" then t.active = false end end
end

local function hasTrackingAPI() return C_Minimap ~= nil end

-- Before login: which trackers the character knows ("herbs,minerals", "multi" = both can be on at once).
function S.trackKnown(which)
  MOCK.tracking = { { name = TRACK.flight.name, texture = TRACK.flight.texture, category = "other", active = true } }
  for key in tostring(which or ""):gmatch("[^,]+") do
    if key == "multi" then MOCK.multiTrack = true
    elseif key == "herbsOn" then
      local t = TRACK.herbs
      MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = true }
    elseif TRACK[key] then
      local t = TRACK[key]
      MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = false }
    end
  end
end

-- After login the Codex turns gathering tracking back on (once the client is ready).
function S.trackRestored()
  MOCK.advance(7)
  if not hasTrackingAPI() then
    check(#MOCK.trackCalls == 0, "no tracking calls without the API")
    check(chatHas("is off"), "a client without the tracking API gets a reminder instead")
    return
  end
  check(gatherOn(), "gathering tracking back on after login")
  check(trackOn("Flight Master"), "town tracking left alone")
  if MOCK.multiTrack then
    check(trackOn("Find Herbs") and trackOn("Find Minerals"), "both trackers on when the client allows both")
  end
  check(chatHas("back on"), "says it turned tracking back on")
  for _, c in ipairs(MOCK.trackCalls) do check(c.name ~= "Flight Master", "never touches town tracking") end
end

-- A loading screen drops it again: the one the player picked last comes back.
function S.trackLoadingScreen()
  if not hasTrackingAPI() then return end
  local _, herbs = trackEntry("Find Herbs")
  local _, minerals = trackEntry("Find Minerals")
  local pick = minerals and "Find Minerals" or "Find Herbs"
  local idx = minerals or herbs
  if herbs and minerals then
    -- the player switches to the other one by hand
    pick = trackOn("Find Herbs") and "Find Minerals" or "Find Herbs"
    idx = pick == "Find Herbs" and herbs or minerals
  end
  C_Minimap.SetTracking(idx, true)
  MOCK.advance(1)
  local chatLines
  for _ = 1, 3 do
    dropTracking()
    MOCK.event("PLAYER_ENTERING_WORLD", false, false)
    MOCK.advance(7)
    check(trackOn(pick), pick .. " (the player's pick) back on after a loading screen")
    chatLines = chatLines or #MOCK.chat
  end
  check(#MOCK.chat == chatLines, "only says so once a session")
end

-- Dead or a ghost: wait. Alive again: back on.
function S.trackDeath()
  if not hasTrackingAPI() then return end
  MOCK.dead = true
  dropTracking()
  MOCK.event("PLAYER_ALIVE")
  MOCK.advance(7)
  check(not gatherOn(), "nothing turned on while a ghost")
  MOCK.dead = false
  MOCK.event("PLAYER_UNGHOST")
  MOCK.advance(7)
  check(gatherOn(), "back on after resurrecting")
end

-- In combat: wait for the fight to end (the mock flags tracking changes in combat).
function S.trackCombat()
  if not hasTrackingAPI() then return end
  dropTracking()
  MOCK.combat = true
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  MOCK.advance(7)
  check(not gatherOn(), "waits for combat to end")
  MOCK.combat = false
  MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(3)
  check(gatherOn(), "back on after combat")
end

-- Another tracking (Track Beasts) is the player's choice: leave it.
function S.trackOtherChoice()
  if not hasTrackingAPI() then return end
  local _, i = trackEntry("Track Beasts")
  if not i then
    local t = TRACK.beasts
    MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = false }
    i = #MOCK.tracking
  end
  dropTracking()
  MOCK.tracking[i].active = true
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  MOCK.advance(7)
  check(trackOn("Track Beasts"), "Track Beasts left on")
  check(not gatherOn(), "gathering not forced over another tracking")
  MOCK.tracking[i].active = false
end

-- The setting turns it off; turning it back on restores right away.
function S.trackSettingOff()
  dropTracking()
  local calls = #MOCK.trackCalls
  if D() then
    openAt(30, "Settings")
    click(win(), "Keep Find Herbs / Find Minerals on")
    win():Hide()
  else
    LevelingCodexDB.noAutoTrack = true
  end
  check(LevelingCodexDB.noAutoTrack, "check box turns tracking restore off")
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  MOCK.advance(7)
  check(#MOCK.trackCalls == calls, "no tracking calls while turned off")
  if D() then
    openAt(30, "Settings")
    click(win(), "Keep Find Herbs / Find Minerals on")
    win():Hide()
    check(not LevelingCodexDB.noAutoTrack, "check box turns it back on")
    MOCK.advance(1)
    if hasTrackingAPI() then check(gatherOn(), "turning the setting on restores tracking") end
  else
    LevelingCodexDB.noAutoTrack = nil
  end
end

-- Logging in with tracking that looks on: it is toggled off and on so the minimap draws it.
function S.trackKick()
  if not hasTrackingAPI() then return end
  MOCK.advance(7)
  local seenOff, seenOn
  for _, c in ipairs(MOCK.trackCalls) do
    if c.name == "Find Herbs" then
      if not c.on then seenOff = true elseif seenOff then seenOn = true end
    end
  end
  check(seenOff and seenOn, "tracking that looked on at login was toggled off and back on")
  check(trackOn("Find Herbs"), "and is on")
end

-- Learning Herbalism later: Find Herbs goes on.
function S.trackLearn()
  if not hasTrackingAPI() then return end
  check(not gatherOn(), "nothing to track yet")
  local t = TRACK.herbs
  MOCK.tracking[#MOCK.tracking + 1] = { name = t.name, texture = t.texture, category = t.category, spellID = t.spellID, active = false }
  MOCK.event("LEARNED_SPELL_IN_TAB", t.spellID, 1)
  MOCK.event("SPELLS_CHANGED")
  MOCK.advance(7)
  check(trackOn("Find Herbs"), "Find Herbs on after learning Herbalism")
end

function S.trackDebug()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("gathering tracking:"), "debug reports gathering tracking")
end

function S.debugReport()
  MOCK.chat = {}
  slash("debug")
  check(chatHas("art files:"), "debug lists the art files")
  check(chatHas("unspent points:"), "debug shows the talent points")
  if talent.root then
    talent.root:Show(); MOCK.advance(0.6)
    MOCK.chat = {}
    slash("debug")
    check(chatHas("talent window:"), "debug names the talent window")
    talent.root:Hide(); MOCK.advance(0.3)
  end
end

-- Blizzard art is used when the client has it, and its absence never breaks anything.
function S.artUsed()
  if not D() then return end
  slash("")
  local f = win()
  local expectArt = not MOCK.minimal and not MOCK.noArt
  check((f._backdrop ~= nil) == expectArt, "dialog border " .. (expectArt and "used" or "skipped"))
  win():Hide()
end

-- Icon buttons under the window with a given tooltip title.
local function iconsTitled(title)
  local out = {}
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle == title or (b.tipTitle and b.tipTitle:find("^" .. title:gsub("%p", "%%%0") .. "  %d")) then out[#out + 1] = b end
  end
  return out
end

-- Talents tab: a tree node per talent, filled in to the level shown, and a click shows every point.
function S.talentTree()
  if not D() then return end
  openAt(16, "Talents")
  local seen = {}
  for _, p in ipairs(D().plan) do
    if not seen[p.name] then
      seen[p.name] = true
      local nodes = iconsTitled(p.name)
      check(#nodes >= 1, "tree node for " .. p.name)
      local node = nodes[1]
      -- rank at 16
      local r = 0
      for _, q in ipairs(D().plan) do
        if q.name == p.name then
          for l = q.from, math.min(q.to, 16) do if l >= q.from then r = r + 1 end end
        end
      end
      check(node.tipTitle == p.name .. "  " .. r .. "/" .. p.max, p.name .. " shows " .. r .. "/" .. p.max .. " at 16, got " .. tostring(node.tipTitle))
      check((r == 0) == (node.tex._desat == true), p.name .. " greyed out only when no points yet")
    end
  end
  -- click a future talent: its points and reasons appear
  local future
  for _, p in ipairs(D().plan) do if p.from > 40 then future = p; break end end
  if future then
    iconsTitled(future.name)[1]:Click()
    local text = MOCK.textUnder(win())
    check(text:find("Level " .. future.from, 1, true), "detail lists level " .. future.from .. " for " .. future.name)
    local snippet = future.why:match("^[A-Za-z0-9 ,%.']+") or "" -- not %w: it takes UTF-8 bytes on Windows
    if #snippet > 8 then check(text:find(snippet, 1, true), "detail shows why " .. future.name) end
  end
  -- the whole game tree is drawn: a talent the guide never takes shows greyed at 0
  local tree = MOCK.ns.talentTrees and MOCK.ns.talentTrees[MOCK.class]
  local inPlan = {}
  for _, p in ipairs(D().plan) do inPlan[p.name] = true end
  for _, t in ipairs(tree and tree.talents or {}) do
    if not inPlan[t.name] then
      local node = iconsTitled(t.name)[1]
      check(node and node.tipTitle == t.name .. "  0/" .. t.max and node.tex._desat == true,
        t.name .. " (not in the plan) is drawn greyed at 0")
      break
    end
  end
  win():Hide()
end

-- Nodes sit at the game's rows and columns (TalentTreeData.lua): the trees side by side, a talent under
-- a prerequisite in its column.
function S.talentTreeLayout()
  local tree = D() and MOCK.ns.talentTrees and MOCK.ns.talentTrees[MOCK.class]
  if not tree then return end
  openAt(30, "Talents")
  local function spot(name)
    local node = iconsTitled(name)[1]
    check(node, "tree node for " .. name)
    local _, _, _, x, y = node:GetPoint(1)
    return x, y
  end
  local byName = {}
  for _, t in ipairs(tree.talents) do byName[t.name] = t end
  local maxX1, minX2 = -1e9, 1e9
  for _, t in ipairs(tree.talents) do
    local x, y = spot(t.name)
    if t.tab == 1 then maxX1 = math.max(maxX1, x) elseif t.tab == 2 then minX2 = math.min(minX2, x) end
    for _, pn in ipairs(t.prereq) do
      local o = byName[pn]
      if o and o.tab == t.tab and o.col == t.col then
        local px, py = spot(pn)
        check(px == x and py > y, t.name .. " sits under its prerequisite " .. pn)
      end
    end
  end
  check(maxX1 < minX2, "the first tree sits left of the second")
  -- every node sits inside the trees, above the talent detail card under them (Affliction has 9 rows)
  local bottom, detailTop = 0, nil
  for _, b in ipairs(MOCK.buttons(win())) do
    local _, _, _, _, by = b:GetPoint(1)
    if by and b.tipTitle and b.tipTitle:find("  %d+/%d+$") then bottom = math.max(bottom, -by + (b:GetWidth() or 0)) end
    if by and b.tipTitle and byName[b.tipTitle] and b:GetWidth() == 40 then detailTop = -by end
  end
  check(detailTop, "the talent detail card under the trees")
  check(bottom < detailTop, "every node sits above the detail card (" .. bottom .. " < " .. tostring(detailTop) .. ")")
  win():Hide()
end

-- With the game's tree layout available, nodes sit where the talent window puts them.
function S.traitLayoutTree()
  if not D() or MOCK.minimal then return end
  local names, id = {}, 700
  for _, p in ipairs(D().plan) do
    if not names[p.name] then
      id = id + 1
      names[p.name] = id
      MOCK.spells[50000 + id] = p.name
      -- reverse order: the first talent in the plan sits furthest right
      MOCK.traitNodes[id] = { posX = 10000 - id * 100, posY = 0, spellID = 50000 + id }
    end
  end
  openAt(30, "Talents")
  local prevX = {} -- per tree: each tree is its own grid
  for _, p in ipairs(D().plan) do
    if names[p.name] then
      local node = iconsTitled(p.name)[1]
      local _, _, _, x = node:GetPoint(1)
      if prevX[p.tree] then check(x < prevX[p.tree], p.name .. " sits left of the talent before it (game layout)") end
      prevX[p.tree] = x
      names[p.name] = nil
    end
  end
  check(not MOCK.textUnder(win()):find("Open your talent window once", 1, true), "no layout note once the game's layout is known")
  win():Hide()
end

----------------------------------------------------------------------------
-- Talent paths (Talents.lua): the spec paths, Custom, the rules, share codes, the trainer list
----------------------------------------------------------------------------

-- A spec path of this class by key (TalentPaths.lua).
local function specPath(key)
  for _, p in ipairs((MOCK.ns.TALENT_PATHS or {})[MOCK.class] or {}) do
    if p.key == key then return p end
  end
end

-- The talents a plan has after its first n points, as the game's trait nodes would report them.
local function seedTraitRanks(plan, n)
  local ranks, order = {}, {}
  local points = {}
  for _, p in ipairs(plan) do
    for l = p.from, p.to do points[#points + 1] = { level = l, name = p.name } end
  end
  table.sort(points, function(a, b) return a.level < b.level end)
  for i = 1, math.min(n, #points) do
    local name = points[i].name
    if not ranks[name] then order[#order + 1] = name end
    ranks[name] = (ranks[name] or 0) + 1
  end
  MOCK.traitNodes = {}
  for i, name in ipairs(order) do
    MOCK.spells[60000 + i] = name
    MOCK.traitNodes[800 + i] = { posX = i * 100, posY = 0, spellID = 60000 + i, rank = ranks[name] }
  end
end

local function listHas(list, value)
  for _, v in ipairs(list or {}) do if v == value then return true end end
  return false
end

function S.talentPathApi()
  local ns = MOCK.ns
  if not D() then
    check(#ns.talentPaths() == 0, "no talent paths without a guide")
    check(ns.talentAt(20) == nil, "no talent point without a guide")
    return
  end
  MOCK.level = 40
  if MOCK.class == "DRUID" then
    check(#ns.talentPaths() == 6, "Druid: the guide, four spec paths and Custom (got " .. #ns.talentPaths() .. ")")
    return
  end
  local key, how = ns.talentPathKey()
  check(key == "guide" and how == "default", "the Codex guide by default, got " .. tostring(key) .. " " .. tostring(how))
  ns.setTalentPath("arms")
  check(ns.talentAt(40).name == "Mortal Strike", "Arms puts level 40 into Mortal Strike")
  check(LevelingCodexCharDB.talentPath == "arms", "the choice is saved for the character")
  check(select(2, ns.talentPathKey()) == "saved", "a chosen path counts as saved")
  -- the trainer list swaps talent spells: Shield Slam ranks go, Mortal Strike ranks come
  local v48 = ns.trainAt(48)
  check(v48 and listHas(v48.spells, "Mortal Strike (Rank 2)"), "Arms trains Mortal Strike (Rank 2) at 48")
  check(not listHas(v48.spells, "Shield Slam (Rank 2)"), "Arms has no Shield Slam ranks")
  check(#v48.spells == #v48.icons and #v48.spells == #v48.notes, "trainer spells, notes and icons stay parallel")
  ns.setTalentPath("guide")
  check(listHas(ns.trainAt(48).spells, "Shield Slam (Rank 2)"), "the guide path keeps its Shield Slam ranks")
  -- custom: the game's rules
  ns.setTalentPath("custom")
  ns.customClear()
  local ok, why = ns.customAdd("Mortal Strike")
  check(not ok and why == "Needs 30 points in Arms (has 0)", "Mortal Strike needs 30 Arms points, got " .. tostring(why))
  check(select(2, ns.customAdd("Bogus Talent")) == "Not a talent", "an unknown talent is refused")
  check(ns.customFrom("arms"), "a custom path starts from Arms")
  check(#ns.customPoints() == 51, "Arms copied in full")
  check(select(2, ns.customAdd("Deflection")) == "All 51 points placed", "no 52nd point")
  for _ = 1, 11 do ns.customUndo() end
  check(#ns.customPoints() == 40, "undo removes the last points")
  check(ns.talentAt(49) and not ns.talentUnplanned(49), "level 49 still planned")
  check(ns.talentAt(50) == nil and ns.talentUnplanned(50), "level 50 not planned yet")
  check(not ns.talentUnplanned(9), "no point to plan before 10")
  -- share codes
  local code = ns.talentCode()
  check(code:find("^LC1%-WARRIOR%-%w%w%w%w%-"), "a share code: " .. code)
  ns.customClear()
  check(#ns.customPoints() == 0, "clear empties the custom path")
  check(ns.readTalentCode("  " .. code:lower() .. "\n"), "a pasted code with spaces and lower case reads")
  check(#ns.customPoints() == 40, "the code brings back 40 points")
  local ok2, r2 = ns.readTalentCode((code:gsub("WARRIOR", "MAGE")))
  check(not ok2 and r2 == "This code is for a Mage", "another class's code is refused, got " .. tostring(r2))
  local ok3, r3 = ns.readTalentCode((code:gsub("^(LC1%-WARRIOR%-)%w%w%w%w", "%1ZZZZ")))
  check(not ok3 and r3 == "This code was made for other talent trees", "another tree version is refused, got " .. tostring(r3))
  local ok4, r4 = ns.readTalentCode("hello")
  check(not ok4 and r4 == "Not a Leveling Codex talent code", "a non-code is refused")
  check(#ns.customPoints() == 40, "a refused code changes nothing")
  -- a save from before a game patch: cut at the first point that no longer fits
  LevelingCodexCharDB.customTalents = { "Improved Rend", "Bogus", "Improved Rend" }
  ns.setTalentPath("custom")
  check(#ns.customPoints() == 1, "a stale custom path is cut at its first bad point")
  -- a saved key that no longer exists
  LevelingCodexCharDB.talentPath = "gone"
  check(ns.talentPathKey() == "guide", "an unknown saved path falls back to the guide")
  LevelingCodexCharDB.talentPath = nil
  if MOCK.minimal then
    check(ns.talentPathKey() == "guide", "no trait API: the guide")
    check(not ns.customFromLive(), "no trait API: no current talents to copy")
    return
  end
  -- no saved path: the spec path your spent talents follow
  seedTraitRanks(specPath("arms").plan, 12)
  MOCK.event("TRAIT_CONFIG_UPDATED", 7)
  local k2, h2 = ns.talentPathKey()
  check(k2 == "arms" and h2 == "matched", "spent Arms talents pick Arms, got " .. tostring(k2) .. " " .. tostring(h2))
  check(LevelingCodexCharDB.talentPath == nil, "a matched path isn't saved")
  check(ns.customFromLive(), "your current talents copy into a custom path")
  check(#ns.customPoints() == 12, "all 12 spent points copied")
  -- ranks that still read 0 at login (the trees loading) are read again a few seconds later
  seedTraitRanks(specPath("arms").plan, 12)
  for _, n in pairs(MOCK.traitNodes) do n.saved, n.rank = n.rank, 0 end
  MOCK.event("TRAIT_CONFIG_UPDATED", 7)
  check(ns.talentPathKey() == "guide", "no ranks yet: the guide")
  for _, n in pairs(MOCK.traitNodes) do n.rank = n.saved end
  MOCK.advance(6)
  check(ns.talentPathKey() == "arms", "ranks that arrive later are matched")
  MOCK.traitNodes = {}
  MOCK.event("TRAIT_CONFIG_UPDATED", 7)
  LevelingCodexCharDB.talentPath, LevelingCodexCharDB.customTalents = nil, nil
end

-- The Talents tab's path cards: click one to follow it (saved), the tree and every-point list follow.
function S.talentPathPick()
  if not D() then return end
  local ns = MOCK.ns
  local paths = ns.talentPaths()
  local p = paths[2]
  if not p or p.custom then return end
  openAt(30, "Talents")
  -- the guide card's tags fit their line (every guide card shows both by default)
  local function fontString(root, value)
    for _, r in ipairs({ root:GetRegions() }) do
      if r._text == value and r:IsShown() then return r end
    end
    for _, k in ipairs({ root:GetChildren() }) do
      local f = fontString(k, value)
      if f then return f end
    end
  end
  local tag = fontString(win(), "Codex guide  -  Chosen")
  check(tag and (tag:GetWidth() or 0) >= tag:GetStringWidth(), "the guide card's tags fit their line")
  click(win(), "Path: " .. p.spec)
  check(LevelingCodexCharDB.talentPath == p.key, "clicking a card chooses its path")
  local text = MOCK.textUnder(win())
  check(text:find("Chosen", 1, true), "the chosen card says so")
  local own = ((ns.PATH_MACROS or {})[MOCK.class] or {})[p.key]
  check(text:find(own and ("Macros follow this path; tips follow the " .. D().spec .. " guide.")
    or ("Macros and tips follow the " .. D().spec .. " guide."), 1, true), "the card says what follows the path")
  local hit, rank = ns.talentAt(30)
  local node = iconsTitled(hit.name)[1]
  check(node and node.tipTitle == hit.name .. "  " .. rank .. "/" .. hit.max, "the tree shows " .. hit.name .. " " .. rank .. "/" .. hit.max)
  local row
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle == "Level 30: " .. hit.name .. " " .. rank .. "/" .. hit.max then row = b end
  end
  check(row, "every point in order follows the path at 30")
  -- a talent the guide takes at 30 but this path never does: greyed at 0
  local inPath = {}
  for _, e in ipairs(p.plan) do inPath[e.name] = true end
  for _, e in ipairs(D().plan) do
    if not inPath[e.name] then
      local n = iconsTitled(e.name)[1]
      check(n and n.tipTitle == e.name .. "  0/" .. e.max and n.tex._desat == true, e.name .. " greyed on " .. p.spec)
      break
    end
  end
  click(win(), "Path: " .. paths[1].spec)
  check(LevelingCodexCharDB.talentPath == "guide", "the guide's card chooses it again")
  win():Hide()
  LevelingCodexCharDB.talentPath = nil
end

-- The controller reaches the path cards and the tree (the Codex's own navigation), and A chooses a path.
function S.padTalentPaths()
  if not D() or not GamepadMode then return end
  MOCK.gamepadUI = true
  LevelingCodexDB.padNative = false
  openAt(30, "Talents")
  local guideLabel = "Path: " .. MOCK.ns.talentPaths()[1].spec
  local card
  for _ = 1, 40 do
    local t = LevelingCodexPadFocus.target
    local l = t and t.codexLabel or ""
    if l:find("^Path: ") and l ~= guideLabel then card = l; break end
    pad(win(), "PADDDOWN")
  end
  check(card, "the D-pad reaches a path card")
  pad(win(), "PAD1")
  local want
  for _, p in ipairs(MOCK.ns.talentPaths()) do if "Path: " .. p.spec == card then want = p.key end end
  check(LevelingCodexCharDB.talentPath == want, "A on a card chooses its path")
  local node
  for _ = 1, 80 do
    local t = LevelingCodexPadFocus.target
    if t and (t.tipTitle or ""):find("%d/%d") and t:GetScript("OnClick") then node = t; break end
    pad(win(), "PADDDOWN")
  end
  check(node, "the D-pad reaches a tree node")
  win():Hide()
  LevelingCodexDB.padNative, MOCK.gamepadUI = nil, nil
  LevelingCodexCharDB.talentPath = nil
end

-- The custom path editor: start from a path, undo, clear (two clicks), place points by clicking the
-- tree, the game's rules refusing a point with the reason.
function S.talentCustom()
  if not D() or MOCK.class ~= "WARRIOR" then return end
  local function text() return MOCK.textUnder(win()) end
  local function has(label) return findButton(win(), function(l) return l == label end) ~= nil end
  openAt(60, "Talents")
  click(win(), "Path: Custom")
  check(LevelingCodexCharDB.talentPath == "custom", "the Custom card chooses Custom")
  check(text():find("Points placed: 0 of 51 - next point is level 10", 1, true), "an empty custom path counts 0 of 51")
  check(has("Start from: Arms") and has("Start from: Protection") and has("Start empty"), "start from a path or empty")
  check(not has("Start from: My current talents"), "no current talents to copy here (nothing readable)")
  click(win(), "Start from: Arms")
  check(text():find("Points placed: 51 of 51", 1, true), "Arms copied in full")
  check(not has("Start from: Arms"), "the start row goes once the path has points")
  click(win(), "Undo")
  check(text():find("Points placed: 50 of 51 - next point is level 60", 1, true), "undo takes the last point back")
  check(text():find("Lv 59", 1, true), "the last point placed is marked with its level")
  check(has("Done"), "starting from a path opens the editor")
  iconsTitled("Mortal Strike")[1]:Click()
  check(text():find("Points placed: 50 of 51", 1, true), "a refused point changes nothing")
  check(text():find("Can't place it: Already taken", 1, true), "the editor says why a point was refused")
  click(win(), "Clear")
  check(text():find("Points placed: 50 of 51", 1, true), "one click on Clear only asks")
  click(win(), "Clear")
  check(text():find("Points placed: 0 of 51 - next point is level 10", 1, true), "a second click clears")
  iconsTitled("Improved Rend")[1]:Click()
  check(text():find("Points placed: 1 of 51 - next point is level 11", 1, true), "clicking a talent places the next point")
  check(text():find("Lv 10", 1, true), "the point just placed is marked")
  check(iconsTitled("Mortal Strike")[1].tipText:find("^Needs 30 points in Arms"), "a closed talent's tooltip says why")
  click(win(), "Done")
  check(has("Edit path"), "Done closes the editor")
  check(MOCK.ns.talentAt(10).name == "Improved Rend", "the custom point is level 10's talent")
  win():Hide()
  LevelingCodexCharDB.talentPath, LevelingCodexCharDB.customTalents = nil, nil
end

-- Share codes: copy one out, paste one back (a bad one says why and changes nothing).
function S.talentCode()
  if not D() or MOCK.class ~= "WARRIOR" then return end
  local function text() return MOCK.textUnder(win()) end
  openAt(60, "Talents")
  click(win(), "Path: Custom")
  click(win(), "Start from: Fury")
  click(win(), "Share code")
  local copy = _G.LevelingCodexCopy
  check(copy and copy:IsShown() and copy.edit:GetText():find("^LC1%-WARRIOR%-"), "Share code shows the code")
  local code = copy.edit:GetText()
  copy:Hide()
  click(win(), "Clear"); click(win(), "Clear")
  check(text():find("Points placed: 0 of 51", 1, true), "cleared")
  click(win(), "Paste code")
  check(copy:IsShown() and copy.edit:GetText() == "", "Paste code opens an empty box")
  copy.edit:SetText("nonsense")
  click(copy, "Use this code")
  check(copy:IsShown() and copy.count:GetText() == "Not a Leveling Codex talent code", "a bad code says why")
  check((copy.count:GetWidth() or 0) > 0 and copy.count:GetWidth() <= 210, "the reason wraps clear of the buttons")
  check(text():find("Points placed: 0 of 51", 1, true), "a bad code changes nothing")
  copy.edit:SetText(code)
  click(copy, "Use this code")
  check(not copy:IsShown(), "a good code closes the box")
  check(text():find("Points placed: 51 of 51", 1, true), "the code brings the path back")
  win():Hide()
  LevelingCodexCharDB.talentPath, LevelingCodexCharDB.customTalents = nil, nil
end

-- A saved path comes back next session (the persisted run saves "fury": Warrior has it, Mage doesn't).
function S.talentPathSaved()
  if not D() then return end
  local key, how = MOCK.ns.talentPathKey()
  local want = MOCK.class == "WARRIOR" and "fury" or "guide"
  check(key == want, "the saved path comes back: " .. tostring(key))
  check(how == (MOCK.class == "WARRIOR" and "saved" or "default"), "how it was picked: " .. tostring(how))
  openAt(MOCK.level, "Talents")
  local chosen
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.codexLabel and b.codexLabel:find("^Path: ") and (b.tipText or ""):find("You follow this path.", 1, true) then
      chosen = b.codexLabel
    end
  end
  check(chosen == (MOCK.class == "WARRIOR" and "Path: Fury" or "Path: " .. MOCK.ns.talentPaths()[1].spec),
    "the chosen card: " .. tostring(chosen))
  win():Hide()
end

-- Before login in a lost-SavedVariables run: the talents of the class's first spec path's first 15
-- points are spent (the run starts at 25).
function S.talentSeed()
  local paths = (MOCK.ns.TALENT_PATHS or {})[MOCK.class]
  if paths and paths[2] then seedTraitRanks(paths[2].plan, 15) end
end

-- SavedVariables didn't load: the path your spent talents follow is picked (and not saved).
function S.talentPathLost()
  local paths = (MOCK.ns.TALENT_PATHS or {})[MOCK.class]
  if not D() or not paths or not paths[2] then return end
  local key, how = MOCK.ns.talentPathKey()
  check(key == paths[2].key and how == "matched", "spent talents pick " .. paths[2].key .. ", got " .. tostring(key) .. " " .. tostring(how))
  openAt(MOCK.level, "Talents")
  check(MOCK.textUnder(win()):find("Picked from the talents you have spent. Choose one to keep it.", 1, true), "the tab says why")
  check(LevelingCodexCharDB.talentPath == nil, "a matched path isn't saved")
  click(win(), "Path: " .. paths[2].spec)
  check(LevelingCodexCharDB.talentPath == paths[2].key, "choosing it keeps it")
  check(not MOCK.textUnder(win()):find("Picked from the talents", 1, true), "no note once chosen")
  win():Hide()
end

-- The chosen path drives every talent display: chat, banner, This Level, the minimap tooltip and the
-- trace in the talent window; a custom path's unplanned point says to plan it.
function S.talentPathFollow()
  if not D() or MOCK.class ~= "WARRIOR" then return end
  local ns = MOCK.ns
  ns.setTalentPath("arms")
  local function levelUp(level)
    MOCK.chat = {}
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level, 10, 0, 0, 0, 0, 0)
    MOCK.advance(4.5)
  end
  levelUp(40)
  check(chatHas("Mortal Strike 1/1"), "chat names the Arms point at 40")
  check(MOCK.textUnder(toast()):find("Mortal Strike  1/1", 1, true), "banner names the Arms point at 40")
  MOCK.advance(10)
  openAt(40, "This Level")
  check(MOCK.textUnder(win()):find("Mortal Strike", 1, true), "This Level shows the Arms point")
  win():Hide()
  local mini = _G.LevelingCodexMinimapButton
  MOCK.fire(mini, "OnEnter")
  check((GameTooltip._lines[2] or ""):find("^Arms"), "minimap tooltip names the path: " .. tostring(GameTooltip._lines[2]))
  check(table.concat(GameTooltip._lines, " "):find("Mortal Strike", 1, true), "minimap tooltip: the talent now")
  MOCK.fire(mini, "OnLeave")
  MOCK.unspent = 1
  ToggleTalentFrame()
  MOCK.advance(0.8)
  local trace = _G.LevelingCodexTalentTrace
  local _, on = trace:GetPoint(1)
  check(trace:IsShown() and on == talent.byName["Mortal Strike"], "the trace is on Mortal Strike")
  ToggleTalentFrame()
  MOCK.advance(0.8)
  -- a custom path that stops at 49
  ns.customFrom("arms")
  for _ = 1, 11 do ns.customUndo() end
  ns.setTalentPath("custom")
  levelUp(50)
  check(chatHas("plan it in .-/codex talents.- %(your custom path has none for this level%)"), "chat: plan the point")
  check(MOCK.textUnder(toast()):find("Plan it in /codex talents", 1, true), "banner: plan the point")
  MOCK.advance(10)
  openAt(50, "This Level")
  check(MOCK.textUnder(win()):find("Your custom path has no point for level 50 yet. Plan it on the Talents tab.", 1, true),
    "This Level: plan the point")
  win():Hide()
  ToggleTalentFrame()
  MOCK.advance(0.8)
  local hint = _G.LevelingCodexTalentHint
  check(hint:IsShown() and hint.name:GetText() == "No point planned", "hint card: no point planned")
  check(hint.next:GetText() == "Plan it in /codex talents.", "hint card: plan it")
  check(not trace:IsShown(), "nothing traced without a planned point")
  ToggleTalentFrame()
  MOCK.advance(0.8)
  MOCK.unspent = nil
  slash("debug")
  check(chatHas("talent path: custom %(saved%), custom points: 40"), "debug names the path")
  LevelingCodexCharDB.talentPath, LevelingCodexCharDB.customTalents = nil, nil
end

-- The trainer list and the Macros tab under another spec's path.
function S.talentTrainerPath()
  if not D() or MOCK.class ~= "WARRIOR" then return end
  MOCK.ns.setTalentPath("arms")
  openAt(48, "Trainer")
  local text = MOCK.textUnder(win())
  check(text:find("Mortal Strike (Rank 2)", 1, true), "Arms trains Mortal Strike (Rank 2)")
  check(not text:find("Shield Slam (Rank 2)", 1, true), "no Shield Slam ranks for Arms")
  click(win(), "Macros")
  check(MOCK.textUnder(win()):find("Built for the Arms path.", 1, true), "the Macros tab names the path")
  MOCK.ns.setTalentPath("guide")
  click(win(), "Trainer")
  check(MOCK.textUnder(win()):find("Shield Slam (Rank 2)", 1, true), "the guide path trains Shield Slam")
  click(win(), "Macros")
  check(not MOCK.textUnder(win()):find("These macros are built for", 1, true), "no note on the guide path")
  win():Hide()
  LevelingCodexCharDB.talentPath = nil
end

-- Every spec path has its own macro set (PathMacros.lua): choosing the path gives its macros at every
-- level (Set up macros makes exactly that set's versions, the Macros tab names the path), switching path
-- moves the macros the Codex made to the new path's versions in place, and a custom path takes the set
-- of the path that shares the most points with it.
function S.pathMacros()
  if not D() then return end
  local ns = MOCK.ns
  local sets = (ns.PATH_MACROS or {})[MOCK.class] or {}
  local specPaths = 0
  for _, p in ipairs(ns.talentPaths()) do
    if not p.guide and not p.custom then
      specPaths = specPaths + 1
      local set = sets[p.key]
      check(set, p.key .. " has its own macros")
      if set then
        ns.setTalentPath(p.key)
        check(ns.pathMacros() == set, p.key .. ": the macros follow the path")
        MOCK.macros, MOCK.chat = {}, {}
        local levels = { 60 }
        for _, m in ipairs(set) do levels[#levels + 1] = m.lo end
        for _, level in ipairs(levels) do
          MOCK.level = level
          slash("macros")
          for _, m in ipairs(set) do
            if level >= m.lo and level <= m.hi then
              check(installedMacroBody(m.name) == m.body, p.key .. " " .. m.name .. " at " .. level)
            end
          end
        end
        check(not chatHas("couldn't make"), p.key .. ": every macro fits the character slots")
        openAt(40, "Macros")
        check(MOCK.textUnder(win()):find("Built for the " .. p.spec .. " path.", 1, true), p.key .. ": the Macros tab names the path")
        for _, m in ipairs(ns.macrosFor(40)) do
          check(#iconsTitled(m.name) > 0, p.key .. ": " .. m.name .. " shows on the Macros tab")
        end
        win():Hide()
      end
    end
  end
  check(specPaths > 0, "the class has spec paths")
  -- switching path: a macro the Codex made under a name both sets use takes the new path's body
  MOCK.macros, MOCK.chat = {}, {}
  MOCK.level = 60
  ns.setTalentPath("guide")
  slash("macros")
  local moved
  for _, p in ipairs(ns.talentPaths()) do
    local set = sets[p.key]
    if set and not moved then
      for _, m in ipairs(set) do
        if 60 >= m.lo and 60 <= m.hi and installedMacroBody(m.name) and installedMacroBody(m.name) ~= m.body then
          moved = { p = p, m = m }
          break
        end
      end
    end
  end
  if moved then
    MOCK.chat = {}
    ns.setTalentPath(moved.p.key)
    check(installedMacroBody(moved.m.name) == moved.m.body, moved.m.name .. " switches to the " .. moved.p.key .. " version")
    check(chatHas("your macros now follow the " .. moved.p.spec .. " path"), "chat says the macros follow the new path")
    -- recognising a body needs GetMacroInfo, which the minimal client lacks (it goes by charDB.made there)
    if not MOCK.minimal then check(ns.countOurMacros() > 0, "macros made on another path still count as the Codex's") end
  end
  -- a custom path gets the set of the path closest to its points
  for _, p in ipairs(ns.talentPaths()) do
    if sets[p.key] then
      ns.setTalentPath("custom")
      ns.customFrom(p.key)
      local mp = ns.macroPath()
      check(mp and mp.key == p.key, "a custom path started from " .. p.key .. " uses its macros")
      openAt(30, "Macros")
      check(MOCK.textUnder(win()):find("Your custom path uses the " .. p.spec .. " macros", 1, true), "the Macros tab says which set")
      win():Hide()
      break
    end
  end
  ns.customClear()
  check(ns.macroPath() and ns.macroPath().guide, "an empty custom path uses the guide's macros")
  LevelingCodexCharDB.talentPath, LevelingCodexCharDB.customTalents = nil, nil
  ns.talentVersion = ns.talentVersion + 1
  MOCK.macros = {}
end

-- A macro an older Codex made (a body it no longer ships, PathMacros.lua's OLD_MACRO_BODIES) is still the
-- Codex's own without saved variables: the next level-up moves it to the current version.
function S.oldMacroBodies()
  if not D() or MOCK.minimal then return end
  local ns = MOCK.ns
  local old = (ns.OLD_MACRO_BODIES or {})[MOCK.class]
  if not old then return end
  local names = {}
  for name in pairs(old) do names[#names + 1] = name end
  table.sort(names)
  local tried = 0
  for _, name in ipairs(names) do
    local want
    for _, m in ipairs(ns.pathMacros()) do
      if m.name == name and m.lo > 1 and not want then want = m end
    end
    if want then
      MOCK.macros = { { name = name, icon = 134400, body = old[name][1], perChar = true } }
      LevelingCodexCharDB.made = {}
      MOCK.level = want.lo
      MOCK.event("PLAYER_LEVEL_UP", want.lo)
      MOCK.advance(1.5)
      check(MOCK.macros[1].body == want.body, name .. ": an old Codex body is updated at level " .. want.lo)
      tried = tried + 1
      MOCK.advance(10)
    end
    if tried >= 3 then break end
  end
  MOCK.macros = {}
end

-- Macros tab: each macro on its controller button and its key, drawn as glyphs and keycaps.
function S.macroMockups()
  if not D() then return end
  for _, pad in ipairs({ "PlayStation", "Xbox", "Switch" }) do
    openAt(30, "Settings")
    click(win(), pad)
    click(win(), "Macros")
    for _, m in ipairs(D().macros) do
      if 30 >= m.lo and 30 <= m.hi then
        local n = #iconsTitled(m.name)
        local want = 1 + (m.pad ~= "" and 1 or 0) + (m.kb ~= "" and 1 or 0)
        check(n >= want, m.name .. " appears on the controller, the key bar and its card (" .. n .. "/" .. want .. ")")
      end
    end
    local text = MOCK.textUnder(win())
    check(text:find("ON YOUR CONTROLLER", 1, true) and text:find("ON YOUR KEYBOARD", 1, true), "both mock-ups drawn")
    if pad == "PlayStation" and not MOCK.minimal then
      -- shapes are drawn with turned strokes, not as text
      local turned = 0
      local function walk(f)
        for _, r in ipairs(f._regions) do if r._shown and r._rot and r._rot ~= 0 then turned = turned + 1 end end
        for _, c in ipairs(f._children) do if c._shown then walk(c) end end
      end
      walk(win())
      check(turned > 0, "PlayStation shapes drawn")
    end
  end
  openAt(30, "Settings"); click(win(), "Xbox")
  win():Hide()
end

-- The banner never sits on top of the game's own level-up display.
function S.bannerBuiltIn()
  if not D() then return end
  LevelingCodexDB.toastPos = nil
  if MOCK.ns.builtInSpotY == nil then
    -- game display never seen: the usual level-up spot near the top
    MOCK.ns.showToast(25, true, true)
    local _, _, _, _, dy = toast():GetPoint(1)
    check(dy == -190, "banner defaults to the game's usual level-up spot (y " .. tostring(dy) .. ")")
    toast():Hide()
  end
  local builtin = _G.EventToastManagerFrame or CreateFrame("Frame", "EventToastManagerFrame", UIParent)
  builtin._top = 1080 - 180 -- the game's display: its top 180 below the top of the screen
  builtin:Show()
  MOCK.level = 25
  MOCK.event("PLAYER_LEVEL_UP", 25)
  MOCK.advance(3)
  check(not (toast() and toast():IsShown()), "banner waits while the game's level-up display is up")
  builtin:Hide()
  MOCK.advance(1)
  check(toast():IsShown(), "banner shows once the game's display is gone")
  local _, _, _, x, y = toast():GetPoint(1)
  check(y == -180, "banner takes the game's display's spot (y " .. tostring(y) .. ")")
  -- a bigger banner still starts at that spot (offsets are in its scaled units)
  LevelingCodexDB.toastScale = 1.5
  MOCK.ns.placeToast()
  _, _, _, x, y = toast():GetPoint(1)
  check(y == -120, "scaled banner starts at the same spot (y " .. tostring(y) .. ")")
  LevelingCodexDB.toastScale = 1
  -- where you dragged it wins
  LevelingCodexDB.toastPos = { "TOP", "TOP", 40, -400 }
  MOCK.ns.placeToast()
  _, _, _, x, y = toast():GetPoint(1)
  check(x == 40 and y == -400, "a banner you moved stays where you put it")
  LevelingCodexDB.toastPos = nil
  MOCK.ns.placeToast()
  -- a game display that never goes away doesn't swallow the banner
  MOCK.advance(12)
  builtin:Show()
  MOCK.event("PLAYER_LEVEL_UP", 26)
  MOCK.advance(10)
  check(toast():IsShown(), "banner shows after 8 s even if the game's display stays up")
  builtin:Hide()
  MOCK.advance(12)
end

-- A level-up display under a name we don't know is found and waited for, then remembered.
function S.bannerFindsDisplay()
  if not D() or MOCK.minimal then return end
  local f = _G.ForeverLevelUpBanner or CreateFrame("Frame", "ForeverLevelUpBanner", UIParent)
  f:Show()
  MOCK.level = 33
  MOCK.event("PLAYER_LEVEL_UP", 33)
  MOCK.advance(5)
  check(not toast():IsShown(), "banner waits for the game's display it found")
  check(MOCK.ns.builtInLevelUp == "ForeverLevelUpBanner", "remembers the game's display (" .. tostring(MOCK.ns.builtInLevelUp) .. ")")
  f:Hide()
  MOCK.advance(1)
  check(toast():IsShown() and toast().title:GetText() == "New at Level 33", "unlocks shown right after it")
  MOCK.advance(12)
end

-- Keycaps have a light face (dark legends on a dark cap were unreadable in game).
function S.keycapsLight()
  if not D() then return end
  openAt(30, "This Level")
  local light = 0
  local function walk(f)
    for _, r in ipairs(f._regions) do
      local c = r._shown and r._tex == "color" and r._color
      if c and c[1] > 0.8 and c[2] > 0.8 and c[3] > 0.7 and r._w > 18 then light = light + 1 end
    end
    for _, c in ipairs(f._children) do if c._shown then walk(c) end end
  end
  walk(win())
  local keyed = 0
  for _, m in ipairs(D().macros) do if 30 >= m.lo and 30 <= m.hi and m.kb ~= "" then keyed = keyed + 1 end end
  check(light >= keyed, "a light keycap face per key (" .. light .. " for " .. keyed .. " keys)")
  win():Hide()
end

-- The card above the talent window stays on screen: a window near the top gets it underneath.
function S.talentHintOnScreen()
  if not D() or not talent.root then return end
  MOCK.level = 30
  for _, case in ipairs({ { 600, 150, "above" }, { 1075, 200, "below" }, { 1075, 30, "inside" } }) do
    talent.root._top, talent.root._bottom = case[1], case[2]
    talent.root:Show()
    MOCK.advance(0.6)
    local hint = _G.LevelingCodexTalentHint
    check(hint:IsShown() and hint.where == case[3], "card goes " .. case[3] .. " (got " .. tostring(hint.where) .. ")")
    local p, rel, rp = hint:GetPoint(1)
    check(rel == talent.root, "card still anchored to the talent window")
    talent.root:Hide()
    MOCK.advance(0.3)
  end
  -- a bar hanging under the window (Forever's controller hints): the card goes below the bar
  if EnumerateFrames then
    local bar = CreateFrame("Frame", nil, UIParent); bar:SetSize(600, 62)
    bar._top, bar._bottom = 202, 140
    talent.root._top, talent.root._bottom = 1075, 200
    talent.root:Show()
    MOCK.advance(0.6)
    local hint = _G.LevelingCodexTalentHint
    local _, rel, _, _, y = hint:GetPoint(1)
    check(hint.where == "below" and rel == talent.root and y and y <= -66,
      "talent card below the bar (" .. tostring(hint.where) .. ", offset " .. tostring(y) .. ")")
    talent.root:Hide()
    bar:Hide()
    MOCK.advance(0.3)
  end
  talent.root._top, talent.root._bottom = nil, nil
end

-- The trace takes the theme's colour, not the node's own green or yellow.
function S.talentTraceThemed()
  if not D() or not talent.root or MOCK.minimal or talent.mode ~= "name" then return end
  MOCK.level = 30
  talent.root:Show()
  MOCK.advance(0.6)
  local t = _G.LevelingCodexTalentTrace
  check(t.copied and t.shapeLine._desat and t.shapeGlow._desat, "copied border art is greyed out before the theme tint")
  talent.root:Hide()
  MOCK.advance(0.3)
end

-- Controller panels follow the controller: L2 set on the left, R2 set on the right.
function S.controllerSides()
  if not D() then return end
  for level = 1, 60 do
    MOCK.level = level
    openAt(level, "Macros")
    local g = MOCK.ns.controllerLayout
    if g and g.L and g.R then
      check(g.L.px < g.R.px, "L2 set left of R2 set at level " .. level)
    end
    if g and g["L+R"] and (g.L or g.R) then
      local side = g.L or g.R
      check(g["L+R"].px > 14, "L2 + R2 set centred under the sides at level " .. level)
    end
  end
  win():Hide()
end

-- Tabs: the hover glow never lights the selected tab.
function S.tabGlow()
  if not D() then return end
  openAt(20, "Tips")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.glow then
      local selected = labelOf(b) == "Tips"
      check(b.glow:IsShown() == not selected, "hover glow " .. (selected and "off" or "on") .. " for " .. labelOf(b))
    end
  end
  win():Hide()
end

-- The talent window is already open when we log in.
function S.talentBeforeLogin()
  if not (D() and talent.root) then return end
  MOCK.level = 30
  talent.root:Show()
  MOCK.event("ADDON_LOADED", "Blizzard_PlayerSpells")
end
function S.talentBeforeLoginCheck()
  if not D() then return end
  MOCK.advance(1)
  traceCheck(30, not MOCK.minimal)
  ToggleTalentFrame()
  MOCK.advance(0.5)
end

----------------------------------------------------------------------------
-- Professions (ProfessionData.lua): skills, the Professions tab, skill-up cards, the crafting window
----------------------------------------------------------------------------

-- skills:BS;97;150,MI;140;225:professions[:Horde[:Skyborne]]  (the step parser splits on ":")
-- api "skilllines": the client only has the classic skill list (no GetProfessions).
function S.skills(list, api, faction, race)
  MOCK.skillAPI = api or "professions"
  if MOCK.skillAPI ~= "professions" then GetProfessions, GetProfessionInfo = nil, nil end
  MOCK.faction, MOCK.race = faction, race
  local names = { BS = "Blacksmithing", MI = "Mining", HE = "Herbalism", TA = "Tailoring", EN = "Enchanting",
    SK = "Skinning", LW = "Leatherworking", AL = "Alchemy", EG = "Engineering", FA = "First Aid",
    CO = "Cooking", FI = "Fishing" }
  for part in (list or ""):gmatch("[^,]+") do
    local k, r, m = part:match("(%a+);(%d+);(%d+)")
    MOCK.setSkill(names[k], tonumber(r), tonumber(m))
  end
end

-- /codex debug reports each profession's skill and step.
function S.profDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing 97/150, step 95%-100 Rough Bronze Leggings, about 3 more"), "BS step in debug")
  check(chatHas("profession: Mining 140/225, step 125%-175"), "Mining step in debug")
  local via = (GetProfessions and "professions") or "skill lines"
  check(chatHas("profession skills read from: " .. via), "skills read from " .. via)
end

local function profText() return MOCK.textUnder(win()) end
local function profButton(name) return findButton(win(), function(label) return label == name end) end

function S.profNone()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing not learned") and chatHas("profession: Mining not learned"), "no professions")
  check(chatHas("profession: Tailoring not learned"), "Tailoring not learned in debug")
  check(chatHas("profession: Enchanting not learned"), "Enchanting not learned in debug")
  check(chatHas("profession: Herbalism not learned"), "Herbalism not learned in debug")
  openAt(9, "Professions")
  local content = profText()
  check(content:find("No supported professions learned", 1, true) and content:find("PROFESSION GUIDES", 1, true),
    "nothing learned: the guide picker shows")
  for _, k in ipairs({ "Blacksmithing", "Mining", "Tailoring", "Enchanting", "Herbalism", "Skinning", "Leatherworking",
      "Alchemy", "Engineering", "First Aid", "Cooking", "Fishing" }) do
    check(profButton(k), "a button for every guide: " .. k)
  end
  check(not profButton("All guides"), "no way back needed before a guide is open")
  click(win(), "Enchanting")
  content = profText()
  check(content:find("Enchanting  -  not learned", 1, true) and content:find("Runed Copper Rod", 1, true), "browsing a guide")
  click(win(), "All guides")
  check(profText():find("PROFESSION GUIDES", 1, true) and profButton("Fishing"), "All guides goes back to the picker")
  win():Hide()
  MOCK.level = 10
  MOCK.event("PLAYER_LEVEL_UP", 10, 10, 0, 0, 0, 0, 0)
  MOCK.advance(4.5)
  local t = toast()
  check(t and t:IsShown() and not MOCK.textUnder(t):find("TRAIN JOURNEYMAN"), "no level-up row for unlearned professions")
end

function S.profLearnedSwitch()
  LevelingCodexDB.noProfCards = true
  MOCK.setSkill("Mining", 30, 75)
  MOCK.advance(1.2)
  openAt(30, "Professions")
  check(profButton("Mining") and not profButton("Blacksmithing"), "one learned guide button")
  MOCK.setSkill("Blacksmithing", 97, 150)
  MOCK.advance(1.2)
  check(profButton("Blacksmithing") and profText():find("Mining 30 / 75"), "new button without switching away from Mining")
  MOCK.removeSkill("Mining")
  MOCK.advance(1.2)
  check(not profButton("Mining") and profText():find("Blacksmithing 97 / 150"), "select learned fallback after unlearning")
  MOCK.setSkill("Mining", 30, 75)
  MOCK.advance(1.2)
  check(profButton("Mining") and profText():find("Blacksmithing 97 / 150"), "relearning doesn't override the current guide")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^100%-112") then b:Click(); break end
  end
  check(profText():find("STEP PREVIEW"), "clicked route preview")
  MOCK.setSkill("Blacksmithing", 98, 150)
  MOCK.advance(1.2)
  MOCK.setSkill("Blacksmithing", 97, 150)
  MOCK.advance(1.2)
  check(profText():find("CURRENT STEP") and not profText():find("STEP PREVIEW"), "rank change clears the preview permanently")
  MOCK.removeSkill("Mining")
  MOCK.removeSkill("Blacksmithing")
  MOCK.advance(1.2)
  check(profText():find("No supported professions learned", 1, true), "switch updates to empty while open")
end

function S.profReaderRecovery()
  MOCK.setSkill("Mining", 30, 75)
  MOCK.setSkill("Blacksmithing", 97, 150)
  openAt(30, "Professions")
  click(win(), "Mining")
  local profs, line = GetProfessions, GetSkillLineInfo
  if profs then GetProfessions = function() error("profession list is loading") end end
  GetSkillLineInfo = function(i)
    if i == 2 then error("Mining row is loading") end
    return line(i)
  end
  MOCK.event("SKILL_LINES_CHANGED")
  MOCK.advance(1.2)
  check(not profButton("Mining") and profText():find("skills are unavailable", 1, true), "partial read reports unavailable")
  check(profText():find("Blacksmithing 97 / 150"), "readable skill stays visible")
  GetProfessions, GetSkillLineInfo = profs, line
  MOCK.event("SKILL_LINES_CHANGED")
  MOCK.advance(1.2)
  check(profText():find("Mining 30 / 75"), "selection returns after the reader recovers")
  if profs then
    GetProfessions = function() return nil, 2 end
    MOCK.skillsCollapsed = true
    MOCK.event("SKILL_LINES_CHANGED")
    check(not profButton("Mining") and profText():find("Blacksmithing 97 / 150"), "complete read with a hole proves absence")
    check(not profText():find("expand Professions", 1, true), "complete read wins over closed fallback")
    GetProfessions, MOCK.skillsCollapsed = profs, false
  end
end

function S.profReaderRecoversAfterOpen()
  MOCK.setSkill("Mining", 30, 75)
  MOCK.advance(1.2)
  local profs, count = GetProfessions, GetNumSkillLines
  if profs then GetProfessions = function() error("profession list is loading") end end
  GetNumSkillLines = function() error("Skills tab is loading") end
  openAt(30, "Professions")
  check(not profButton("Mining") and profText():find("skills are unavailable", 1, true), "unavailable read while opening")
  GetProfessions, GetNumSkillLines = profs, count
  MOCK.event("SKILL_LINES_CHANGED")
  MOCK.advance(1.2)
  check(profButton("Mining") and profText():find("Mining 30 / 75"), "a healthy read refreshes the view opened during failure")
end

function S.profOpenHeadingWithClosedWeapons()
  local count, line = GetNumSkillLines, GetSkillLineInfo
  GetNumSkillLines = function() return count() + 1 end
  GetSkillLineInfo = function(i)
    if i > count() then return "Weapon Skills", true, false end
    return line(i)
  end
  openAt(30, "Professions")
  check(profButton("Mining"), "Mining confirmed with the Professions heading open")
  MOCK.removeSkill("Mining")
  MOCK.advance(1.2)
  check(not profText():find("Mining 30 / 75", 1, true) and profText():find("No supported professions learned", 1, true),
    "an unrelated closed heading cannot hide an unlearned profession")
end

-- Without GetProfessions the classic skill list hides lines under a closed heading: the guide
-- keeps the skill it saw last, and the card still comes when the heading opens again.
function S.profCollapsed()
  if not D() then return end
  MOCK.skillsCollapsed = true
  MOCK.event("SKILL_LINES_CHANGED"); MOCK.advance(1.2)
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("Blacksmithing 97 / 150"), "closed heading: still the skill seen before")
  check(not profButton("Tailoring"), "closed heading does not add unconfirmed guides")
  win():Hide()
  MOCK.setSkill("Blacksmithing", 100, 150); MOCK.advance(1.2) -- a skill-up the list doesn't show
  MOCK.skillsCollapsed = false
  MOCK.event("SKILL_LINES_CHANGED"); MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Blacksmithing 100", "card when the heading opens again")
end

-- A closed heading from the start (nothing seen yet this session): say so, not "not learned".
function S.skillsClosed() MOCK.skillsCollapsed = true end
function S.profCollapsedCold()
  if not D() then return end
  openAt(30, "Professions")
  check(profText():find("expand Professions", 1, true) and not profButton("Blacksmithing"), "tab: heading closed")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Blacksmithing not seen"), "debug: not seen")
  MOCK.skillsCollapsed = false
  MOCK.event("SKILL_LINES_CHANGED"); MOCK.advance(1.2)
  check(profButton("Blacksmithing") and profText():find("Blacksmithing 97 / 150"), "heading opened: skill read")
  win():Hide()
end

-- The Professions tab at Blacksmithing 97/150 and Mining 140/225 (set by the skills step).
function S.profTab()
  if not D() then return end
  openAt(30, "Professions")
  click(win(), "Blacksmithing")
  click(win(), "To 300")
  local t = profText()
  check(t:find("Blacksmithing 97 / 150"), "skill header")
  check(t:find("Rough Bronze Leggings") and t:find("About 3 crafts to skill 100"), "now card")
  check(t:find("(skill 95)"), "learn level")
  check(t:find("SHOPPING LIST TO 300"), "shopping list")
  check(t:find("1620 Thorium Bar"), "shopping list counts the 100 Thorium Bars the two Imperial Plate quests take")
  check(t:find("24 Heavy Grinding Stone"), "shopping list counts only the stones the route doesn't make itself")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^100%-112") then b:Click(); break end
  end
  check(profText():find("STEP PREVIEW") and profText():find("make 24 more"), "clicked step shows; the note says how many more stones")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^95%-100") then b:Click(); break end
  end
  check(profText():find("CURRENT STEP") and profText():find("About 3 crafts to skill 100"), "clicking your own step goes back to it")
  check(t:find("LEVELING ROUTE"), "route list")
  check(t:find("TRAIN EXPERT") == nil, "Expert not due at 97")
  click(win(), "Mining")
  t = profText()
  check(t:find("Mining 140 / 225") and t:find("Iron Deposit") and t:find("Arathi Highlands"), "mining header, vein, zones")
  MOCK.staleUnder(win(), "Professions")
  win():Hide()
end

-- The shopping list counts to your cap first (the next cap once you're at it); To 300 counts the
-- whole route, and the choice holds for the session.
function S.profShopScope()
  if not D() then return end
  openAt(30, "Professions")
  click(win(), "Blacksmithing")
  local t = profText()
  check(t:find("SHOPPING LIST TO 150", 1, true), "the list counts to your cap first")
  check(t:find("\n10 Green Dye", 1, true), "a step that crosses the cap counts its crafts to the cap")
  local function shopPart(text)
    local a = text:find("SHOPPING LIST", 1, true)
    local b = a and text:find("CAMP OBJECTS", a, true)
    return a and text:sub(a, b or #text) or ""
  end
  check(not shopPart(t):find("Thorium Bar", 1, true) and not shopPart(t):find("Mithril Bar", 1, true), "nothing past the cap")
  check(findButton(win(), function(l) return l == "To 150 (your cap)" end), "the switch names your cap")
  click(win(), "To 300")
  t = profText()
  check(t:find("SHOPPING LIST TO 300", 1, true) and t:find("1620 Thorium Bar", 1, true) and
    t:find("\n25 Green Dye", 1, true), "To 300 counts the whole route")
  click(win(), "Mining")
  click(win(), "Blacksmithing")
  check(profText():find("SHOPPING LIST TO 300", 1, true), "the choice holds when you come back")
  click(win(), "To 150 (your cap)")
  MOCK.setSkill("Blacksmithing", 150, 150); MOCK.advance(1.2)
  t = profText()
  check(t:find("SHOPPING LIST TO 225", 1, true) and findButton(win(), function(l) return l == "To 225 (next cap)" end),
    "at your cap the list counts to the next one")
  check(shopPart(t):find("Mithril Bar", 1, true) and not shopPart(t):find("Thorium Bar", 1, true), "and stops there")
  MOCK.setSkill("Blacksmithing", 210, 300); MOCK.advance(1.2)
  t = profText()
  check(t:find("SHOPPING LIST TO 300", 1, true) and not findButton(win(), function(l) return l == "To 300" end),
    "with a cap of 300 there's nothing to switch")
  win():Hide()
end

-- Other guides: every guide you haven't learned, shown as if you were starting it.
function S.profBrowse()
  if not D() then return end
  MOCK.faction, MOCK.race = "Alliance", "Human"
  openAt(30, "Professions")
  click(win(), "Blacksmithing")
  click(win(), "Other guides")
  local t = profText()
  check(t:find("OTHER PROFESSION GUIDES", 1, true), "the picker opens")
  check(profButton("Tailoring") and profButton("Fishing") and profButton("First Aid"), "it lists the guides you haven't learned")
  local count = 0
  for _, b in ipairs(MOCK.buttons(win())) do if labelOf(b) == "Blacksmithing" then count = count + 1 end end
  check(count == 1, "a learned guide keeps its own button, not a second one in the picker")
  click(win(), "Alchemy")
  t = profText()
  check(t:find("Alchemy  -  not learned", 1, true) and t:find("Any Alchemy trainer", 1, true), "where to learn it")
  check(t:find("FIRST STEP", 1, true) and t:find("Minor Arcane Elixir", 1, true), "its first step")
  check(t:find("LEVELING ROUTE", 1, true) and t:find("SHOPPING LIST TO 300", 1, true) and t:find("from 1", 1, true),
    "its route and shopping list from 1")
  check(not t:find("CURRENT STEP", 1, true) and not t:find("TRAIN JOURNEYMAN", 1, true), "no now card or training for a guide you lack")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^90%-120") then b:Click(); break end
  end
  t = profText()
  check(t:find("STEP PREVIEW", 1, true) and t:find("Skill 90-120", 1, true) and
    t:find("Elixir of Wisdom", 1, true), "a step can be opened")
  click(win(), "Other guides")
  click(win(), "Herbalism")
  t = profText()
  check(t:find("Herbalism  -  not learned", 1, true) and t:find("Peacebloom  1\n", 1, true) and
    t:find("Elwynn Forest", 1, true), "a gathering guide lists its first nodes without colours")
  MOCK.setSkill("Herbalism", 1, 75); MOCK.advance(1.2)
  t = profText()
  check(t:find("Herbalism 1 / 75", 1, true) and t:find("CURRENT STEP", 1, true), "learning it turns the page into your guide")
  click(win(), "Mining")
  check(profText():find("Mining 140 / 225", 1, true), "your own guides are a click away")
  MOCK.removeSkill("Herbalism"); MOCK.advance(1.2)
  MOCK.faction, MOCK.race = nil, nil
  MOCK.staleUnder(win(), "Professions")
  win():Hide()
end

-- Tier card, route done, not learned, faction and Skyborne zones.
function S.profTabCases()
  if not D() then return end
  MOCK.setSkill("Blacksmithing", 150, 150)
  openAt(30, "Professions"); click(win(), "Blacksmithing")
  check(profText():find("TRAIN EXPERT") and profText():find("Bengus Deepforge"), "Expert due at 150, level 30")
  MOCK.level = 15
  click(win(), "Blacksmithing")
  check(profText():find("AT YOUR CAP"), "stuck at the cap at level 15")
  MOCK.level = 30
  MOCK.setSkill("Blacksmithing", 300, 300)
  click(win(), "Blacksmithing")
  check(profText():find("ROUTE COMPLETE"), "route done at 300")
  MOCK.removeSkill("Blacksmithing")
  MOCK.removeSkill("Mining")
  MOCK.advance(1.2)
  check(profText():find("No supported professions learned", 1, true), "unlearned skills removed")
  MOCK.setSkill("Mining", 30, 75)
  MOCK.advance(1.2)
  MOCK.faction, MOCK.race = "Alliance", "Human"
  click(win(), "Mining")
  check(profText():find("Elwynn Forest") and not profText():find("Durotar"), "Alliance copper zones only")
  MOCK.faction, MOCK.race = "Horde", "Orc"
  click(win(), "Mining")
  check(profText():find("Durotar") and not profText():find("Elwynn Forest"), "Horde copper zones only")
  MOCK.race = "Skyborne"
  click(win(), "Mining")
  check(profText():find("Zephras Isle"), "Skyborne starting isle for Copper")
  MOCK.faction, MOCK.race = nil, nil
  win():Hide()
end

-- A theme switch rebuilds the window: the Professions tab is still there.
function S.profTabAfterTheme()
  if not D() then return end
  openAt(30, "Settings"); click(win(), "Codex (gold)")
  click(win(), "Professions")
  check(profText():find("Blacksmithing") or profText():find("Mining"), "Professions tab survives a theme rebuild")
  click(win(), "Settings"); click(win(), "Forever (teal)")
  win():Hide()
end

-- Skill-up cards: only when a step starts, a tier is due or a vein opens; one card for a jump.
-- (1.2 s waits: the minimal client has no skill events, so its cards come from a 1 s poll.)
function S.profSkillUps()
  if not D() then return end
  local function dismiss(t) MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
  MOCK.setSkill("Blacksmithing", 94, 150)       -- first reading this session: no card
  MOCK.advance(1.2)
  check(not (toast() and toast():IsShown()), "no card for the first reading")
  MOCK.setSkill("Blacksmithing", 95, 150)       -- step boundary at 95
  MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Blacksmithing 95", "card at a new step")
  check(t.sub:GetText() == "Journeyman Blacksmithing", "card subtitle: your tier (" .. tostring(t.sub:GetText()) .. ")")
  check(MOCK.textUnder(t):find("Rough Bronze Leggings"), "card names the next recipe")
  dismiss(t)
  MOCK.setSkill("Blacksmithing", 96, 150)       -- an ordinary point
  MOCK.advance(1.2)
  check(not t:IsShown(), "no card for an ordinary point")
  MOCK.setSkill("Blacksmithing", 112, 150)      -- jumps over 100 and 112: one card, both steps
  MOCK.advance(1.2)
  local text = MOCK.textUnder(t)
  check(t:IsShown() and text:find("Heavy Grinding Stone") and text:find("Rough Bronze Leggings"), "one card for two boundaries")
  dismiss(t)
  MOCK.level = 30
  MOCK.setSkill("Blacksmithing", 125, 150)      -- Expert can be trained now
  MOCK.advance(1.2)
  check(t:IsShown() and MOCK.textUnder(t):find("TRAIN EXPERT"), "Expert card at 125")
  for _, row in ipairs(t.rows or {}) do
    local v = row:IsShown() and row.value and row.value:GetText()
    check(not v or #v <= 60, "banner row fits on its line: " .. tostring(v))
  end
  MOCK.fire(t, "OnMouseUp", "LeftButton"); MOCK.advance(1.5)
  check(win() and win():IsShown() and MOCK.textUnder(win()):find("Blacksmithing 125"), "click opens the Professions tab")
  win():Hide()
  MOCK.setSkill("Mining", 64, 75)               -- first Mining reading
  MOCK.advance(1.2)
  MOCK.setSkill("Mining", 65, 75)
  MOCK.advance(1.2)
  check(t:IsShown() and MOCK.textUnder(t):find("Tin Vein"), "new vein card")
  dismiss(t)
  MOCK.setSkill("Lockpicking", 1, 75); MOCK.advance(1.2)
  MOCK.setSkill("Lockpicking", 50, 75); MOCK.advance(1.2)
  check(not t:IsShown(), "no card for a profession the guide doesn't cover")
  LevelingCodexDB.noProfCards = true
  MOCK.setSkill("Blacksmithing", 140, 150); MOCK.advance(1.2)
  check(not t:IsShown(), "cards off in Settings")
  LevelingCodexDB.noProfCards = nil
end

-- Skill 65 reached at level 9 (Journeyman needs level 10): the level-up to 10 brings the
-- training row, once. Runs after profSkillUps (Mining 65/75).
function S.profLevelTier()
  if not D() then return end
  local function levelUp(level)
    MOCK.level = level
    MOCK.event("PLAYER_LEVEL_UP", level, 10, 0, 0, 0, 0, 0)
    MOCK.advance(4.5)
    local t = toast()
    return t and t:IsShown() and MOCK.textUnder(t) or ""
  end
  MOCK.level = 9
  MOCK.setSkill("Mining", 65, 75); MOCK.advance(1.2)
  MOCK.chat = {}
  local text = levelUp(10)
  check(text:find("TRAIN JOURNEYMAN MINING"), "level-up banner: train Journeyman Mining")
  check(chatHas("Mining: train .-Journeyman"), "level-up chat: train Journeyman")
  check(not text:find("BLACKSMITHING"), "no row for Blacksmithing (Expert needs level 20)")
  MOCK.advance(10)
  check(not levelUp(11):find("TRAIN JOURNEYMAN"), "only at the level that unlocks it")
  MOCK.advance(10)
end

-- Opening the Codex within a minute of a banner opens what it was about.
function S.bannerOpensTarget()
  if not D() then return end
  openAt(30, "Settings"); win():Hide()          -- last tab: Settings
  MOCK.setSkill("Blacksmithing", 94, 150); MOCK.advance(1.2)
  MOCK.setSkill("Blacksmithing", 95, 150); MOCK.advance(1.2)   -- skill-up card
  slash("")
  check(MOCK.textUnder(win()):find("Blacksmithing 95 / 150"), "opens on the profession the card was about")
  win():Hide()
  slash("")
  check(MOCK.textUnder(win()):find("Blacksmithing 95 / 150"), "used once: reopening keeps the tab you were on")
  click(win(), "Settings"); win():Hide()
  MOCK.setSkill("Blacksmithing", 100, 150); MOCK.advance(1.2)
  MOCK.advance(61)
  slash("")
  check(MOCK.textUnder(win()):find("Minimap button"), "after a minute it opens as usual")
  win():Hide()
end

function S.profRemovedBanner(shortcut)
  MOCK.setSkill("Mining", 30, 75)
  MOCK.setSkill("Blacksmithing", 94, 150)
  MOCK.advance(1.2)
  MOCK.setSkill("Blacksmithing", 95, 150)
  MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown(), "profession card before unlearning")
  MOCK.removeSkill("Blacksmithing")
  MOCK.advance(1.2)
  if shortcut == "click" then MOCK.fire(t, "OnMouseUp", "LeftButton") else slash("") end
  check(win() and win():IsShown() and profText():find("Mining 30 / 75"), "stale shortcut selects a learned guide")
  check(not profButton("Blacksmithing"), "stale shortcut cannot expose unlearned guide")
end

function S.herbalismTab()
  openAt(1, "Professions")
  local text = profText()
  check(profButton("Herbalism") and not (profButton("Blacksmithing") or profButton("Mining") or
    profButton("Tailoring") or profButton("Enchanting")), "only learned Herbalism button")
  check(text:find("Herbalism 1 / 75") and text:find("Peacebloom  1  orange") and
    text:find("Silverleaf  1  orange") and text:find("Earthroot  15  red"), "starter herbs and first unlock")
  check(text:find("Elwynn Forest") and not text:find("Durotar"), "Alliance starter zones")
  MOCK.faction, MOCK.race = "Horde", "Orc"
  click(win(), "Herbalism")
  check(profText():find("Durotar") and not profText():find("Elwynn Forest"), "Horde starter zones")
  MOCK.race = "Skyborne"
  click(win(), "Herbalism")
  check(profText():find("Zephras Isle"), "Skyborne starter zone")
  check(text:find("LEVELING ROUTE") and text:find("270%-300") and text:find("CAMP OBJECTS"), "route and camp sections")
  check(text:find("20  Incense Candle") and text:find("140  Greenhouse") and
    text:find("300  Seed Hybridizer"), "camp unlocks")
  check(not text:find("Smelt") and not text:find("SHOPPING LIST"), "gathering route has no crafting advice")
  MOCK.setSkill("Herbalism", 25, 75); MOCK.advance(1.2)
  check(profText():find("Peacebloom  1  yellow"), "Peacebloom turns yellow at 25")
  MOCK.setSkill("Herbalism", 50, 75); MOCK.advance(1.2)
  check(profText():find("Peacebloom  1  yellow") and profText():find("TRAIN JOURNEYMAN"), "still yellow, and training at 50")
  MOCK.setSkill("Herbalism", 65, 75); MOCK.advance(1.2)
  check(profText():find("Peacebloom  1  green"), "Forever's herbs turn green at skill + 65")
  MOCK.setSkill("Herbalism", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE") and profText():find("Black Lotus opens at 300"), "cap and Black Lotus")
  click(win(), "Settings")
  local cards = findButton(win(), function(label) return label == "Profession skill-up cards" end)
  check(cards and cards.tipText and cards.tipText:find("Herbalism"), "Settings explains Herbalism cards")
end

function S.herbalismCards()
  MOCK.level = 1
  local function set(rank, cap)
    MOCK.setSkill("Herbalism", rank, cap)
    MOCK.advance(1.2)
    return toast()
  end
  local function dismiss()
    local t = toast()
    if t and t:IsShown() then MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
  end
  set(14, 75)
  local t = set(15, 75)
  check(t and t:IsShown() and t.title:GetText() == "Herbalism 15" and
    MOCK.textUnder(t):find("NEW HERB") and MOCK.textUnder(t):find("Earthroot %(15%)"), "Earthroot unlock card")
  MOCK.fire(t, "OnMouseUp", "LeftButton")
  check(win() and win():IsShown() and profText():find("Herbalism 15 / 75"), "herb card opens its guide")
  win():Hide()
  set(119, 150); dismiss()
  t = set(120, 150)
  check(t:IsShown() and MOCK.textUnder(t):find("Grave Moss %(120%)"), "off-route herb unlock")
  dismiss()
  t = set(125, 150)
  check(t:IsShown() and MOCK.textUnder(t):find("TRAIN EXPERT"), "Expert training at 125")
  dismiss()
  check(not set(126, 150):IsShown(), "ordinary point does not show a card")
  set(269, 300); dismiss()
  t = set(270, 300)
  local content = MOCK.textUnder(t)
  check(t:IsShown() and content:find("NEW STEP") and content:find("Dreamfoil %(270%)"), "late route handoff and herb unlock")
  dismiss()
  set(299, 300); dismiss()
  t = set(300, 300)
  check(t:IsShown() and MOCK.textUnder(t):find("Black Lotus %(300%)"), "Black Lotus unlock at 300")
end

function S.firstAidTab()
  if GetProfessions then GetNumSkillLines, GetSkillLineInfo = nil, nil end
  openAt(10, "Professions")
  check(profButton("Mining") and profButton("Engineering") and profButton("First Aid"),
    "First Aid is shown alongside both learned primary professions")
  click(win(), "First Aid")
  check(profText():find("First Aid 1 / 75", 1, true) and profText():find("Linen Bandage", 1, true),
    "First Aid starts with Linen Bandage")
  MOCK.setSkill("First Aid", 125, 150); MOCK.advance(1.2)
  local text = profText()
  check(text:find("UNLOCK EXPERT", 1, true) and text:find("Under Wraps", 1, true) and
    text:find("Deneb Walker", 1, true) and text:find("Balai Lok'Wein", 1, true),
    "the Expert book is available at 125 before character level 20")
  openAt(34, "Professions")
  MOCK.setSkill("First Aid", 225, 225); MOCK.advance(1.2)
  text = profText()
  check(text:find("AT YOUR CAP", 1, true) and text:find("level 35", 1, true) and
    not text:find("UNLOCK ARTISAN", 1, true), "Triage waits until level 35")
  MOCK.advance(10)
  MOCK.chat = {}
  MOCK.level = 35
  MOCK.event("PLAYER_LEVEL_UP", 35, 10, 0, 0, 0, 0, 0)
  MOCK.advance(4.5)
  local card = toast()
  check(card and card:IsShown() and MOCK.textUnder(card):find("UNLOCK ARTISAN FIRST AID", 1, true) and
    chatHas("First Aid: unlock .-Artisan"), "the level-up banner and chat announce the quest unlock")
  openAt(35, "Professions")
  text = profText()
  check(text:find("UNLOCK ARTISAN", 1, true) and text:find("Theramore", 1, true) and
    text:find("Hammerfall", 1, true) and text:find("15 patients", 1, true),
    "Triage shows both doctors and the objective")
  MOCK.setSkill("First Aid", 290, 300); MOCK.advance(1.2)
  text = profText()
  check(text:find("Heavy Runecloth Bandage", 1, true) and text:find("22 Runecloth", 1, true),
    "the last bandage step and cloth estimate")
  MOCK.setSkill("First Aid", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE", 1, true), "First Aid route ends at 300")
end

function S.alchemyTab()
  openAt(35, "Professions")
  check(profButton("Alchemy"), "learned Alchemy has a guide button")
  click(win(), "Alchemy")
  local content = profText()
  check(content:find("Alchemy 1 / 75", 1, true) and content:find("Minor Arcane Elixir", 1, true),
    "Apprentice starts with a Forever recipe")
  MOCK.setSkill("Alchemy", 200, 225); MOCK.advance(1.2)
  content = profText()
  check(content:find("TRAIN ARTISAN", 1, true) and content:find("Kylanna Windwhisper", 1, true) and
    content:find("Rogvar", 1, true) and content:find("level 35", 1, true), "Artisan rank unlock and trainers")
  check(content:find("SHOPPING LIST TO 225", 1, true) and not content:find("Stonescale Oil", 1, true),
    "to the Expert cap the oil isn't needed yet")
  click(win(), "To 300")
  content = profText()
  check(content:find("75 Leaded Vial (includes 43 for 86 Stonescale Oil", 1, true),
    "the shared vial row separates oil supplies from the vials for earlier recipes")
  MOCK.bags = { ["Stonescale Eel"] = 3, ["Leaded Vial"] = 1 }
  MOCK.setSkill("Alchemy", 265, 300); MOCK.advance(1.2)
  content = profText()
  check(content:find("Recipe: Elixir of Superior Defense", 1, true) and
    content:find("Elixir of Greater Defense", 1, true), "final recipe shows the vendor item's name")
  check(content:find("43 Stonescale Eel", 1, true) and content:find("43 Leaded Vial", 1, true) and
    content:find("43 Crystal Vial", 1, true), "shopping list includes both materials for the oil")
  if GetItemCount then
    check(content:find("you can make 2", 1, true), "bag estimate is limited by the vial")
  end
  MOCK.setSkill("Alchemy", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE", 1, true), "Alchemy route ends at 300")
end

function S.skinningLeatherworkingTab()
  openAt(35, "Professions")
  click(win(), "Skinning")
  local content = profText()
  check(content:find("Skinning 1 / 75") and content:find("Skinning Knife") and content:find("Elwynn Forest"),
    "starter Skinning guide")
  check(not content:find("Durotar") and not content:find("SHOPPING LIST"), "faction-filtered gathering guide")
  MOCK.faction, MOCK.race = "Horde", "Skyborne"
  click(win(), "Skinning")
  check(profText():find("Zephras Isle") and profText():find("Durotar") and not profText():find("Elwynn Forest"),
    "Skyborne and Horde Skinning locations")
  MOCK.setSkill("Skinning", 279, 300); MOCK.advance(1.2)
  local card = toast()
  if card and card:IsShown() then MOCK.fire(card, "OnMouseUp", "RightButton"); MOCK.advance(1.5) end
  MOCK.setSkill("Skinning", 280, 300); MOCK.advance(1.2)
  check(profText():find("Un'Goro Crater") and profText():find("280%-300"), "late Skinning route")
  card = toast()
  check(card and card:IsShown() and MOCK.textUnder(card):find("NEW STEP"), "Skinning step card")
  MOCK.setSkill("Skinning", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE"), "Skinning cap")
  click(win(), "Leatherworking")
  content = profText()
  check(content:find("Leatherworking 1 / 75") and content:find("57 Ruined Leather Scraps") and
    content:find("SHOPPING LIST TO 75"), "Leatherworking starter and shopping estimate, to the Apprentice cap")
  check(content:find("125  Tanning Rack") and content:find("Runic Leather Headband"), "hotfixed camp unlock and final step")
  MOCK.setSkill("Leatherworking", 200, 225); MOCK.advance(1.2)
  check(profText():find("TRAIN ARTISAN") and profText():find("Hahrana Ironhide"), "Leatherworking Artisan trainer")
end

----------------------------------------------------------------------------
-- Crafting window mock: TradeSkillFrame with 8 visible rows TradeSkillSkill1..8 showing the
-- recipes from `offset`. Row text carries a count and orange ones a colour code, like the game.
-- style "retail": no classic calls, only C_TradeSkillUI.
----------------------------------------------------------------------------

local RELATIVE = { optimal = 0, medium = 1, easy = 2, trivial = 3 }

-- Tailoring: the shopping list in raw cloth (bolts become their cloth), the cloth section.

-- How far down the window (draw y) the first shown text matching pat sits; the text dump follows
-- the widget pools, not the screen, so order on screen is read from the anchors.
local function textY(root, pat)
  local found
  local function walk(f)
    for _, r in ipairs(f._regions) do
      if not found and r._shown and r._text and r._text:find(pat) and r._points[1] then found = -r._points[1][5] end
    end
    for _, c in ipairs(f._children) do if c._shown and not found then walk(c) end end
  end
  walk(root)
  return found
end

-- The shopping list's text only (between its title and the cloth section).
local function shoppingText()
  local whole = findButton(win(), function(l) return l == "To 300" end)
  if whole and not whole.codexOn then whole:Click() end
  local t = profText()
  local a = t:find("SHOPPING LIST TO 300", 1, true)
  local b = t:find("\nCLOTH\n", a or 1, true)
  return a and t:sub(a, b or #t) or ""
end

function S.cookingTab()
  if GetProfessions then GetNumSkillLines, GetSkillLineInfo = nil, nil end
  openAt(10, "Professions")
  check(profButton("Mining") and profButton("Cooking"), "Cooking is shown alongside Mining")
  click(win(), "Cooking")
  local text = profText()
  check(text:find("Cooking 1 / 75", 1, true) and text:find("Basic Campfire", 1, true) and
    text:find("Station: Cooking Fire", 1, true), "Cooking shows how to make and use a fire")
  MOCK.setSkill("Cooking", 125, 150); MOCK.advance(1.2)
  text = profText()
  check(text:find("UNLOCK EXPERT", 1, true) and text:find("Expert Cookbook", 1, true) and
    text:find("Shandrina", 1, true) and text:find("Wulan", 1, true), "both factions can find the Expert book")
  MOCK.setSkill("Cooking", 225, 225); MOCK.advance(1.2)
  text = profText()
  check(text:find("AT YOUR CAP", 1, true) and text:find("level 35", 1, true), "Artisan Cooking requires level 35")
  openAt(35, "Professions")
  text = profText()
  check(text:find("UNLOCK ARTISAN", 1, true) and text:find("Clamlette Surprise", 1, true) and
    text:find("Dirge Quikcleave", 1, true), "Artisan Cooking shows the quest giver")
  local shopping = shoppingText()
  check(shopping:find("12 Giant Egg", 1, true) and shopping:find("10 Zesty Clam Meat", 1, true) and
    shopping:find("20 Alterac Swiss", 1, true), "the shopping list reserves quest materials at the 225 cap")
  MOCK.setSkill("Cooking", 225, 300); MOCK.advance(1.2)
  shopping = shoppingText()
  check(not shopping:find("Giant Egg", 1, true) and not shopping:find("Zesty Clam Meat", 1, true) and
    not shopping:find("Alterac Swiss", 1, true), "raising the cap clears quest materials at the same skill")
  MOCK.setSkill("Cooking", 285, 300); MOCK.advance(1.2)
  text = profText()
  check(text:find("Nightfin Soup", 1, true) and text:find("Gikkix", 1, true) and
    shoppingText():find("17 Raw Nightfin Snapper", 1, true), "Nightfin Soup finishes the route at a Cooking Fire")
  MOCK.setSkill("Cooking", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE", 1, true), "Cooking route ends at 300")
end

function S.fishingTab()
  if GetProfessions then GetNumSkillLines, GetSkillLineInfo = nil, nil end
  openAt(19, "Professions")
  check(profButton("Mining") and profButton("Engineering") and profButton("Cooking") and
    profButton("First Aid") and profButton("Fishing"), "both primary and all three secondary professions are shown")
  click(win(), "Fishing")
  local text = profText()
  local starterZone = MOCK.faction == "Horde" and "Durotar" or "Elwynn Forest"
  check(text:find("Fishing 1 / 75", 1, true) and text:find(starterZone, 1, true) and
    text:find("Shiny Bauble", 1, true), "the first step gives faction-appropriate water and a starter lure")
  MOCK.setSkill("Fishing", 125, 150); MOCK.advance(1.2)
  check(not profText():find("UNLOCK EXPERT", 1, true), "the book waits until character level 20")
  openAt(20, "Professions")
  text = profText()
  check(text:find("UNLOCK EXPERT", 1, true) and text:find("The Bass and You", 1, true) and
    text:find("Old Man Heming", 1, true), "the book and vendor appear at level 20 and skill 125")
  openAt(34, "Professions")
  MOCK.setSkill("Fishing", 225, 225); MOCK.advance(1.2)
  text = profText()
  check(text:find("AT YOUR CAP", 1, true) and text:find("level 35", 1, true), "Nat Pagle requires character level 35")
  openAt(35, "Professions")
  text = profText()
  check(text:find("UNLOCK ARTISAN", 1, true) and text:find("Feralas Ahi", 1, true) and
    text:find("Sar'theris Striker", 1, true) and text:find("Misty Reed Mahi Mahi", 1, true) and
    text:find("Savage Coast Blue Sailfin", 1, true), "the rank card shows all four quest fish")
  check(shoppingText() == "", "quest fish are caught during the quest and stay off the shopping list")
  MOCK.setSkill("Fishing", 225, 300); MOCK.advance(1.2)
  text = profText()
  check(text:find("Tidefury Cove", 1, true) and not text:find("UNLOCK ARTISAN", 1, true) and
    not text:find("Feralas Ahi", 1, true), "raising the cap clears the quest objectives and leaves the final water")
  MOCK.setSkill("Fishing", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE", 1, true), "Fishing route ends at 300")
end

function S.engineeringTab()
  openAt(35, "Professions")
  check(profButton("Engineering"), "learned Engineering has a guide button")
  click(win(), "Engineering")
  local content = profText()
  check(content:find("Engineering 1 / 75", 1, true) and content:find("Rough Blasting Powder", 1, true),
    "Engineering starts at actual skill for a Gnome")
  MOCK.setSkill("Engineering", 200, 225); MOCK.advance(1.2)
  content = profText()
  check(content:find("TRAIN ARTISAN", 1, true) and content:find("Buzzek Bracketswing", 1, true),
    "Artisan Engineering unlocks at 200 and level 35")
  MOCK.setSkill("Engineering", 235, 300); MOCK.advance(1.2)
  content = profText()
  check(content:find("Tools: Blacksmith Hammer, Arclight Spanner", 1, true) and
    content:find("Station: Anvil", 1, true), "bombs show both bag tools and the station")
  check(shoppingText():find("114 Solid Stone", 1, true) and
    not shoppingText():find("\n%d+ Solid Blasting Powder"), "raw stone covers both bombs and their triggers")
  MOCK.setSkill("Engineering", 285, 300); MOCK.advance(1.2)
  content = profText()
  check(content:find("Thorium Tube", 1, true) and content:find("Xizzer Fizzbolt", 1, true) and
    content:find("binds on pickup", 1, true), "the last stretch names the bind-on-pickup schematic vendor")
  MOCK.setSkill("Engineering", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE COMPLETE", 1, true), "Engineering route ends at 300")
end

local function tailoring() click(win(), "Tailoring"); return profText() end

-- Two shopping-list texts in the same column whose lines overlap (a row that wraps into the next).
local function shoppingOverlap()
  local top, bottom = textY(win(), "^SHOPPING LIST TO 300$"), textY(win(), "^CLOTH$")
  local items = {}
  local function walk(f)
    for _, r in ipairs(f._regions) do
      if r._shown and r._text and r._points[1] and top and bottom then
        local y = -r._points[1][5]
        if y > top and y < bottom then items[#items + 1] = { x = r._points[1][4], y = y, h = r:GetStringHeight(), t = r._text } end
      end
    end
    for _, c in ipairs(f._children) do if c._shown then walk(c) end end
  end
  walk(win())
  for i, a in ipairs(items) do
    for j, b in ipairs(items) do
      if i < j and a.x == b.x and a.y < b.y + b.h and b.y < a.y + a.h then return a.t .. " | " .. b.t end
    end
  end
end

function S.tailorTab()
  if not D() then return end
  openAt(30, "Professions")
  local t = tailoring()
  check(t:find("Tailoring 150 / 225"), "Tailoring header")
  check(t:find("Earthen Vest"), "step at 150: Earthen Vest")
  check(t:find("SHOPPING LIST TO 225") and t:find("\nCLOTH\n"), "shopping list (to your cap) and cloth section")
  local shop = shoppingText()
  check(not shop:find("%d+ Bolt of"), "no bolt rows in the shopping list: they're counted as cloth")
  local cloth, bolts = shop:match("(%d+) Runecloth %(for (%d+) bolts")
  check(cloth and tonumber(cloth) == 5 * tonumber(bolts), "Runecloth row: 5 per bolt (" .. tostring(cloth) .. ", " .. tostring(bolts) .. ")")
  check(t:find("Make them from Silk Cloth %(4 each%)"), "step card: bolts are made from Silk Cloth")
  local now, linen = textY(win(), "^Silk Cloth  %-  you need this now"), textY(win(), "^Linen Cloth$")
  check(now and linen and now < linen, "this step's cloth (Silk) first, marked")
  check(t:find("Humanoids level 27%-39"), "silk mob levels")
  if GetItemCount then
    MOCK.bags["Mageweave Cloth"] = 20
    check(tailoring():find("Mageweave Cloth %(for %d+ bolts, you have 20%)"), "have: cloth in bags")
    MOCK.bags["Bolt of Mageweave"] = 10
    check(tailoring():find("Mageweave Cloth %(for %d+ bolts, you have 70%)"), "have: held bolts count as 5 cloth each")
    MOCK.bags["Mageweave Cloth"], MOCK.bags["Bolt of Mageweave"] = nil, nil
    local over = shoppingOverlap()
    check(not over, "shopping rows don't overlap: " .. tostring(over))
    MOCK.bags["Bolt of Silk Cloth"] = 12
    local held = tailoring()
    check(held:find("Make them from Silk Cloth %(4 each%): your 0 make 0") and not held:find("your 48"),
      "step card: held bolts aren't cloth that makes more bolts")
    MOCK.bags["Bolt of Silk Cloth"] = nil
  else
    check(not t:find("you have"), "no bag counts without GetItemCount")
  end
  check(profButton("Tailoring") and not (profButton("Blacksmithing") or profButton("Mining")), "only learned Tailoring button")
  win():Hide()
  openAt(30, "Professions")
  check(profText():find("Tailoring 150 / 225"), "the picked profession stays after reopening")
  MOCK.staleUnder(win(), "Professions")
  click(win(), "Settings")
  local cards = findButton(win(), function(l) return l == "Profession skill-up cards" end)
  check(cards and cards.tipText and cards.tipText:find("every profession the Codex guides", 1, true),
    "Settings: skill-up cards cover every guided profession")
  check(findButton(win(), function(l) return l == "Show what to learn at profession trainers" end) and
    findButton(win(), function(l) return l == "Include profession supplies" end), "Settings: the trainer and vendor switches")
  win():Hide()
end

-- Faction zones, more bolts than needed, the end of the route.
function S.tailorTabCases()
  if not D() then return end
  openAt(30, "Professions")
  local t = tailoring()
  check(t:find("Westfall") and not t:find("Durotar"), "Alliance cloth zones")
  MOCK.faction = "Horde"
  t = tailoring()
  check(t:find("Durotar") and not t:find("Westfall"), "Horde cloth zones")
  MOCK.race = "Skyborne"
  t = tailoring()
  check(t:find("Durotar") and not t:find("Zephras Isle"), "Skyborne: their faction's zones")
  MOCK.faction, MOCK.race = nil, nil
  local _, before = shoppingText():match("(%d+) Runecloth %(for (%d+) bolts")
  MOCK.bags["Bolt of Runecloth"] = 999
  tailoring()
  local shop = shoppingText()
  check(not shop:find("%-%d"), "no negative counts with 999 bolts held")
  local _, after = shop:match("(%d+) Runecloth %(for (%d+) bolts")
  check(before and after == before, "held bolts don't change the need")
  MOCK.bags["Bolt of Runecloth"] = nil
  MOCK.setSkill("Tailoring", 50, 75)
  t = tailoring()
  check(t:find("TRAIN JOURNEYMAN") and t:find("Taleen Shimmerthread") and not t:find("Zephras Isle tailors: Sellandus"),
    "Journeyman card names the Zephras Isle trainers")
  MOCK.setSkill("Tailoring", 260, 300)
  t = tailoring()
  check(t:find("Runecloth Cuffs") and t:find("Pexmit"), "step at 260: Runecloth Cuffs from Pexmit")
  check(t:find("Runecloth  %-  you need this now"), "Runecloth marked at 260")
  MOCK.setSkill("Tailoring", 285, 300)
  t = tailoring()
  check(t:find("Runecloth Shoulders") and t:find("Venomspew patterns") and t:find("need a Loom"),
    "Runecloth finish: the vendor patterns need a Loom")
  MOCK.setSkill("Tailoring", 300, 300)
  t = tailoring()
  check(t:find("ROUTE COMPLETE") and not t:find("you need this now"), "route done at 300")
  MOCK.setSkill("Tailoring", 150, 225)
  win():Hide()
end

-- Only Tailoring learned: the tab opens on it.
function S.tailorOnly()
  if not D() then return end
  openAt(30, "Professions")
  local t = profText()
  check(t:find("Tailoring 20 / 75") and t:find("Bolt of Linen Cloth"), "opens on Tailoring without a click")
  check(t:find("Linen Cloth  %-  you need this now"), "Linen Cloth first for the bolt step")
  win():Hide()
end

function S.tailorSkillUps()
  if not D() then return end
  MOCK.advance(10)
  MOCK.setSkill("Tailoring", 159, 225); MOCK.advance(1.2)
  MOCK.setSkill("Tailoring", 160, 225); MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Tailoring 160", "Tailoring card at a new step")
  check(t and MOCK.textUnder(t):find("Crimson Silk Vest"), "card names Crimson Silk Vest")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(10)
  MOCK.level = 9
  MOCK.setSkill("Tailoring", 60, 75); MOCK.advance(1.2)
  MOCK.advance(10)
  MOCK.level = 10
  MOCK.event("PLAYER_LEVEL_UP", 10, 10, 0, 0, 0, 0, 0)
  MOCK.advance(4.5)
  t = toast()
  local text = t and t:IsShown() and MOCK.textUnder(t) or ""
  check(text:find("TRAIN JOURNEYMAN TAILORING") and text:find("An Expert, Master or Artisan Tailor"), "level-up banner: train Journeyman Tailoring")
  MOCK.advance(10)
end

function S.tailorDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Tailoring 150/225, step 147%-160 Earthen Vest"), "Tailoring step in debug")
end

function S.tailorClosed()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Tailoring not seen"), "Tailoring not seen under a closed heading")
end

-- Enchanting: rods per step, Motes counted as Strange Dust, the disenchanting section and your bags.
local function enchanting() click(win(), "Enchanting"); return profText() end

function S.enchantTab()
  if not D() then return end
  openAt(30, "Professions")
  local t = enchanting()
  check(t:find("Enchanting 150 / 225"), "Enchanting header")
  check(t:find("Enchant Bracer %- Lesser Stamina") and t:find("About 5 crafts to skill 155"), "step at 150")
  check(t:find("Enchant your own bracers"), "what to enchant")
  check(t:find("\nDISENCHANTING\n"), "disenchanting section")
  if GetItemCount then
    check(t:find("Rod: Runed Silver Rod %- you need it"), "rod line: you need it")
    MOCK.bags["Runed Silver Rod"] = 1
    check(enchanting():find("Rod: Runed Silver Rod %(you have it%)"), "rod line: you have it")
    MOCK.bags["Runed Silver Rod"] = nil
    t = enchanting()
  else
    check(t:find("Rod: Runed Silver Rod") and not t:find("you need it"), "rod line without bag counts")
  end
  check(not shoppingText():find("%d+ Mote of Magic"), "no Mote rows in the shopping list")
  local marked, first = textY(win(), "^Item level 31%-35  %-  Soul Dust.*you need this now"), textY(win(), "^Item level 5%-15")
  check(marked and first and marked < first, "the Soul Dust band first and marked")
  check(t:find("3 Lesser make 1 Greater"), "essence line")
  if not C_Container then check(not t:find("IN YOUR BAGS"), "no bag list without the bag API") end
  local b = profButton("Enchanting")
  check(b and not (profButton("Blacksmithing") or profButton("Mining") or profButton("Tailoring")), "only learned Enchanting button")
  local _, _, _, x = b:GetPoint(1)
  check(x and x + b:GetWidth() <= 568, "Enchanting button fits the content width")
  MOCK.staleUnder(win(), "Professions")
  win():Hide()
end

-- A better rod, the start and the end of the route.
function S.enchantTabCases()
  if not D() then return end
  openAt(30, "Professions")
  if GetItemCount then
    MOCK.bags = { ["Runed Truesilver Rod"] = 1 }
    check(enchanting():find("Rod: Runed Silver Rod %(you have it%)"), "a better rod counts")
    MOCK.bags = {}
  end
  MOCK.setSkill("Enchanting", 1, 75)
  local t = enchanting()
  check(t:find("Runed Copper Rod") and t:find("Dust to Motes"), "skill 1: the rod, then Dust to Motes")
  check(shoppingText():find("Strange Dust %(for %d+ motes"), "Motes counted as Strange Dust")
  check(shoppingText():find("\n1 Mote of Magic"), "the rod's first Mote stays on the list: it must be bought")
  if GetItemCount then
    check(not t:find("Make them from Strange Dust"), "skill 1, no rod: no 'make them from' (Dust to Motes needs the rod)")
    MOCK.setSkill("Enchanting", 12, 75)
    MOCK.bags = { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 4 }
    check(enchanting():find("Make them from Strange Dust %(1 makes 3%): your 4 make 12"), "Motes: 1 dust makes 3")
    MOCK.bags = { ["Runed Arcanite Rod"] = 1 }
    MOCK.setSkill("Enchanting", 265, 300)
    check(enchanting():find("Rod: Runed Truesilver Rod %(you have it%)"), "an Arcanite rod counts for the Truesilver one")
    MOCK.bags = {}
  end
  check(t:find("Item level 5%-15  %-  Strange Dust[^\n]*you need this now"), "the Strange Dust band marked at 1")
  MOCK.setSkill("Enchanting", 265, 300)
  t = enchanting()
  check(t:find("Enchant Shield %- Greater Stamina") and t:find("Mythrin'dir") and t:find("any shield"), "skill 265: shield, formula vendor")
  MOCK.setSkill("Enchanting", 300, 300)
  t = enchanting()
  check(t:find("ROUTE COMPLETE") and not t:find("you need this now"), "route done at 300")
  MOCK.setSkill("Enchanting", 150, 225)
  win():Hide()
end

function S.enchantBags()
  if not D() or not C_Container then return end
  MOCK.bagItems = {
    { name = "Ironforge Boots", quality = 2, level = 22, class = "Armor" },
    { name = "Rusty Sword", quality = 2, level = 8, class = "Weapon" },
    { name = "Blue Cloak", quality = 3, level = 33, class = "Armor" },
    { name = "Quest Gloves", quality = 2, level = 1, itemLevel = 53, class = "Armor" },
    { name = "Epic Boots", quality = 4, level = 45, itemLevel = 63, class = "Armor" },
    { name = "Linen Shirt", quality = 1, level = 5, class = "Armor" },
    { name = "Copper Ore", quality = 1, level = 1, class = "Trade Goods" },
    { name = "Unseen Gloves", quality = 2, level = 30, class = "Armor", loaded = false },
  }
  openAt(30, "Professions")
  local t = enchanting()
  check(t:find("IN YOUR BAGS"), "bag list")
  check(t:find("Quest Gloves %(item level 53%): Dream Dust or Lesser Eternal Essence"),
    "disenchant uses item level even when a quest item has no equip level")
  check(t:find("Epic Boots %(item level 63%): Nexus Crystal"), "high-level epics give Nexus Crystals")
  check(t:find("Ironforge Boots %(item level 27%): Soul Dust or Greater Astral Essence"), "green armour: dust then essence")
  check(t:find("Rusty Sword %(item level 13%): Lesser Magic Essence or Strange Dust"), "green weapon: essence then dust")
  check(t:find("Blue Cloak %(item level 38%): Large Glowing Shard"), "blue: the shard")
  check(not t:find("Linen Shirt") and not t:find("Copper Ore") and not t:find("Unseen Gloves"), "white, non-gear and unloaded items left out")
  local boots, sword = textY(win(), "^Ironforge Boots"), textY(win(), "^Rusty Sword")
  check(boots and sword and boots < sword, "the Soul Dust item first at 150")
  MOCK.bagItems = {}
  for i = 1, 12 do MOCK.bagItems[i] = { name = "Green Thing " .. i, quality = 2, level = 10 + i, class = "Armor" } end
  t = enchanting()
  local rows = 0
  for _ in t:gmatch("Green Thing %d+ %(item level") do rows = rows + 1 end
  check(rows == 8, "at most 8 bag rows (" .. rows .. ")")
  MOCK.bagItems = {}
  check(enchanting():find("No material estimates for gear in your bags"), "empty bags")
  win():Hide()
end

function S.enchantSkillUps()
  if not D() then return end
  MOCK.advance(10)
  MOCK.setSkill("Enchanting", 159, 225); MOCK.advance(1.2)
  MOCK.setSkill("Enchanting", 160, 225); MOCK.advance(1.2)
  local t = toast()
  check(t and t:IsShown() and t.title:GetText() == "Enchanting 160", "Enchanting card at a new step")
  check(t and MOCK.textUnder(t):find("Enchant Boots %- Lesser Agility"), "card names Boots - Lesser Agility")
  MOCK.fire(t, "OnMouseUp", "RightButton"); MOCK.advance(10)
  MOCK.level = 9
  MOCK.setSkill("Enchanting", 60, 75); MOCK.advance(1.2)
  MOCK.advance(10)
  MOCK.level = 10
  MOCK.event("PLAYER_LEVEL_UP", 10, 10, 0, 0, 0, 0, 0)
  MOCK.advance(4.5)
  t = toast()
  local text = t and t:IsShown() and MOCK.textUnder(t) or ""
  check(text:find("TRAIN JOURNEYMAN ENCHANTING") and text:find("An Expert, Master or Artisan Enchanter"), "level-up banner: train Journeyman Enchanting")
  MOCK.advance(10)
end

function S.enchantDebug()
  if not D() then return end
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession: Enchanting 150/225, step 135%-155 Enchant Bracer %- Lesser Stamina"), "Enchanting step in debug")
end

function S.makeCraftWindow(style)
  local f = CreateFrame("Frame", "TradeSkillFrame", UIParent); f:SetSize(384, 512); f:Hide()
  -- the selected recipe's details pane: its name in big letters, like the game's
  local details = CreateFrame("Frame", nil, f); details:SetSize(300, 180)
  local dname = details:CreateFontString(nil, "OVERLAY"); dname:SetText("Rough Bronze Leggings")
  MOCK.trade = { line = "Blacksmithing", rank = 97, max = 150, style = style or "classic", offset = 0, selected = 0, rows = {},
    recipes = { { "Rough Sharpening Stone", "trivial", 5 }, { "Copper Chain Belt", "trivial", 3 }, { "Runed Copper Belt", "easy", 1 },
                { "Rough Bronze Leggings", "optimal", 4 } } }
  -- style "scrollbox": Forever's own window, a modern ScrollBox of anonymous pooled rows
  local box = style == "scrollbox" and CreateFrame("Frame", nil, f) or nil
  if box then box:SetSize(300, 140) end
  for i = 1, 8 do
    local b = CreateFrame("Button", (not box) and ("TradeSkillSkill" .. i) or nil, box or f); b:SetSize(300, 16)
    MOCK.trade.rows[i] = b
  end
  MOCK.trade.layout = function()
    for i, b in ipairs(MOCK.trade.rows) do
      local r = MOCK.trade.recipes[i + MOCK.trade.offset]
      if r then
        local name = r[2] == "optimal" and ("|cffff8040" .. r[1] .. "|r") or r[1]
        b:SetText("  " .. name .. (r[3] > 0 and (" [" .. r[3] .. "]") or "")); b:Show()
      else
        b:Hide()
      end
    end
  end
  MOCK.trade.layout()
  if box then
    -- scrolls by percentage; ScrollToElementDataByPredicate is added by the scenario that wants it
    -- (elements are tree nodes whose GetData() holds the recipe's name)
    local function maxOffset() return math.max(0, #MOCK.trade.recipes - 8) end
    box.SetScrollPercentage = function(_, p)
      MOCK.trade.offset = math.floor(math.max(0, math.min(1, p)) * maxOffset() + 0.5)
      MOCK.trade.layout()
    end
    box.GetScrollPercentage = function()
      local m = maxOffset()
      return m > 0 and MOCK.trade.offset / m or 0
    end
    MOCK.trade.box = box
    MOCK.trade.scrollToPredicate = function(_, pred)
      for i, r in ipairs(MOCK.trade.recipes) do
        local node = { GetData = function() return { name = r[1], kind = r[2] } end }
        if pred(node) then
          MOCK.trade.offset = math.max(0, math.min(i - 4, maxOffset()))
          MOCK.trade.layout()
          return node
        end
      end
    end
    return f
  end
  -- the classic list scrolls through FauxScrollFrame_SetOffset + TradeSkillFrame_Update
  TradeSkillListScrollFrame = CreateFrame("ScrollFrame", "TradeSkillListScrollFrame", f)
  TRADE_SKILLS_DISPLAYED = 8
  FauxScrollFrame_SetOffset = function(frame, offset) if frame == TradeSkillListScrollFrame then MOCK.trade.offset = offset end end
  TradeSkillFrame_Update = function() MOCK.trade.layout() end
  if style == "retail" then
    GetTradeSkillLine, GetNumTradeSkills, GetTradeSkillInfo, SelectTradeSkill = nil, nil, nil, nil
    S.retailAPI()
  end
  return f
end

-- Retail's C_TradeSkillUI over MOCK.trade.
function S.retailAPI()
    C_TradeSkillUI = {
      GetBaseProfessionInfo = function()
        return { professionName = MOCK.trade.line, skillLevel = MOCK.trade.rank, maxSkillLevel = MOCK.trade.max }
      end,
      GetAllRecipeIDs = function()
        local ids = {}
        for i = 1, #MOCK.trade.recipes do ids[i] = 1000 + i end
        return ids
      end,
      GetRecipeInfo = function(id)
        local r = MOCK.trade.recipes[id - 1000]
        if r then return { name = r[1], learned = true, numAvailable = r[3], relativeDifficulty = RELATIVE[r[2]] } end
      end,
      OpenRecipe = function(id)
        local i = id - 1000
        MOCK.trade.selected = i
        MOCK.trade.offset = math.max(0, i - 4)
        MOCK.trade.layout()
      end,
    }
end

local function openCraft() TradeSkillFrame:Show(); MOCK.event("TRADE_SKILL_SHOW"); MOCK.advance(0.6) end
local function closeCraft() TradeSkillFrame:Hide(); MOCK.event("TRADE_SKILL_CLOSE"); MOCK.advance(0.6) end
local function craftReady() return D() and not MOCK.minimal and _G.TradeSkillFrame end

function S.craftFirstAid()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "First Aid", 180, 225
  MOCK.trade.recipes = { { "Silk Bandage", "easy", 0 } }
  MOCK.trade.layout()
  openCraft()
  local hint, trace = LevelingCodexCraftHint, LevelingCodexCraftTrace
  check(hint and hint:IsShown() and not trace:IsShown() and
    MOCK.textUnder(hint):find("Manual: Heavy Silk Bandage", 1, true), "the missing recipe names its manual")
  MOCK.trade.recipes[2] = { "Heavy Silk Bandage", "medium", 1 }
  MOCK.trade.layout(); MOCK.advance(1)
  local _, row = trace:GetPoint(1)
  check(trace:IsShown() and row == TradeSkillSkill2 and MOCK.trade.selected == 0 and MOCK.trade.offset == 0,
    "First Aid outlines the learned bandage without touching the list")
  closeCraft()
end

function S.craftEngineering()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "Engineering", 285, 300
  MOCK.trade.recipes = { { "Thorium Widget", "medium", 0 } }
  MOCK.trade.layout()
  openCraft()
  local hint, trace = LevelingCodexCraftHint, LevelingCodexCraftTrace
  check(hint and hint:IsShown() and not trace:IsShown() and MOCK.textUnder(hint):find("Xizzer Fizzbolt", 1, true),
    "missing Thorium Tube lists the schematic vendor")
  MOCK.trade.recipes[2] = { "Thorium Tube", "optimal", 1 }
  MOCK.trade.layout(); MOCK.advance(1)
  local _, row = trace:GetPoint(1)
  check(trace:IsShown() and row == TradeSkillSkill2 and MOCK.trade.selected == 0 and MOCK.trade.offset == 0,
    "Engineering outlines the learned recipe without touching the list")
  closeCraft()
end

function S.craftAlchemy()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "Alchemy", 265, 300
  MOCK.trade.recipes = { { "Elixir of Greater Defense", "optimal", 0 }, { "Stonescale Oil", "trivial", 0 } }
  MOCK.bags = { ["Stonescale Eel"] = 3 }
  MOCK.trade.layout()
  openCraft()
  local hint, trace = LevelingCodexCraftHint, LevelingCodexCraftTrace
  check(hint and hint:IsShown(), "Alchemy crafting guide opens")
  local _, row = trace:GetPoint(1)
  check(row == TradeSkillSkill1, "oil is skipped while a leaded vial is missing")
  MOCK.bags["Leaded Vial"] = 1; MOCK.advance(1)
  _, row = trace:GetPoint(1)
  check(row == TradeSkillSkill2 and MOCK.textUnder(hint):find("You can make 2", 1, true),
    "make two Stonescale Oil from one eel and the only vial, even when grey")
  MOCK.bags["Stonescale Oil"] = 2; MOCK.advance(1)
  _, row = trace:GetPoint(1)
  check(row == TradeSkillSkill1 and MOCK.trade.selected == 0 and MOCK.trade.offset == 0,
    "enough oil returns the hint to the elixir without touching the list")
  closeCraft()
end

function S.craftLeatherworking()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "Leatherworking", 235, 300
  MOCK.trade.recipes = { { "Nightscape Pants", "easy", 0 } }
  MOCK.trade.layout()
  openCraft()
  local hint, trace = LevelingCodexCraftHint, LevelingCodexCraftTrace
  check(hint and hint:IsShown() and MOCK.textUnder(hint):find("Wicked Leather Gauntlets"), "Leatherworking hint")
  local status = MOCK.textUnder(hint)
  check(status:find("Recipe not learned") and status:find("Leonard Porter") and status:find("Werg Thickblade"),
    "missing Leatherworking recipe names the pattern vendors")
  MOCK.trade.recipes[2] = { "Wicked Leather Gauntlets", "optimal", 3 }
  MOCK.trade.layout(); MOCK.advance(1)
  local _, row = trace:GetPoint(1)
  check(trace:IsShown() and row == TradeSkillSkill2 and MOCK.trade.selected == 0 and MOCK.trade.offset == 0,
    "Leatherworking trace leaves the recipe list alone")
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "Skinning", 20, 75
  MOCK.trade.recipes = { { "Camp Chair", "optimal", 3 } }
  MOCK.trade.layout(); MOCK.advance(1)
  check(hint:IsShown() and not trace:IsShown() and MOCK.textUnder(hint):find("Skin starter beasts", 1, true),
    "switching to Skinning replaces the recipe trace with gathering advice")
  closeCraft()
end

function S.craftTrace()
  if not craftReady() then return end
  MOCK.setSkill("Blacksmithing", 97, 150)
  openCraft()
  local tr, h = _G.LevelingCodexCraftTrace, _G.LevelingCodexCraftHint
  check(h and h:IsShown(), "card beside the crafting window")
  local text = MOCK.textUnder(h)
  check(text:find("Rough Bronze Leggings") and text:find("About 3 crafts to skill 100") and text:find("Materials for 4 crafts"), "card text")
  check(text:find("Orange"), "live colour on the card")
  check(tr and tr:IsShown(), "row traced")
  local _, rel = tr:GetPoint(1)
  check(rel == TradeSkillSkill4, "trace on the Rough Bronze Leggings row (its text has a colour code and a count)")
  closeCraft()
  check(not tr:IsShown() and not h:IsShown(), "trace and card hide with the window")
end

function S.craftGathering()
  openCraft()
  local hint, trace = LevelingCodexCraftHint, LevelingCodexCraftTrace
  check(hint and hint:IsShown() and trace and trace:IsShown(), "crafting guide before switching professions")
  for _, profession in ipairs({
    { "Mining", 80, 150, "Silver Vein", "Rock Garden" },
    { "Mining", 185, 225, "Mithril Deposit" },
    { "Herbalism", 20, 75, "Peacebloom", "Incense Candle" },
    { "Fishing", 150, 225, "Fish at Booty Bay or Tidefury Cove", "Fishing Rack" },
    { "Skinning", 170, 225, "Skin yetis and worgen", "Field Guide" },
  }) do
    MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = unpack(profession, 1, 3)
    MOCK.trade.recipes = profession[5] and { { profession[5], "optimal", 2 } } or {}
    MOCK.trade.layout()
    MOCK.advance(0.6)
    check(hint:IsShown() and not trace:IsShown() and MOCK.textUnder(hint):find(profession[4], 1, true),
      profession[1] .. " provides gathering advice without outlining a camp recipe")
  end
  closeCraft()
  TradeSkillFrame:Show(); MOCK.advance(0.6)
  check(hint:IsShown(), "a gathering-only window may open without a crafting event")
  TradeSkillFrame:Hide()
  check(not hint:IsShown(), "gathering hint closes with the window")
end

function S.craftProfessionBook()
  MOCK.setSkill("Mining", 185, 225)
  MOCK.setSkill("Fishing", 150, 225)
  MOCK.professionSpells = { "Fishing", "Mining", "Heroic Strike" }
  local tip = GameTooltip
  tip:SetOwner(UIParent, "ANCHOR_RIGHT")
  tip:SetSpellBookItem(1, "spell")
  local function lines() return table.concat(tip._lines, "\n") end
  check(lines():find("Fishing 150 / 225", 1, true) and lines():find("Tidefury Cove", 1, true), "Fishing's native profession tooltip")
  tip:SetSpellBookItem(2, "spell")
  check(lines():find("Mithril Deposit", 1, true) and not lines():find("Tidefury Cove", 1, true), "switching tooltips replaces the advice")
  local spellBook = C_SpellBook
  C_SpellBook = { GetSpellBookItemName = function() return "Find Minerals" end }
  tip:SetSpellBookItem(2, 0)
  check(lines():find("Mining 185 / 225", 1, true), "the modern spellbook's tracking spell identifies Mining")
  C_SpellBook = spellBook
  tip:SetSpellBookItem(3, "spell")
  check(lines() == "Heroic Strike", "ordinary spell tooltips are untouched")
  LevelingCodexDB.noCraftGuide = true
  tip:SetSpellBookItem(1, "spell")
  check(lines() == "Fishing", "profession hints follow the setting")
  LevelingCodexDB.noCraftGuide = nil
  tip:Hide()
end

function S.craftNotLearned()
  if not craftReady() then return end
  table.remove(MOCK.trade.recipes, 4); MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Recipe not learned"), "not learned")
  check(not LevelingCodexCraftTrace:IsShown(), "nothing to trace")
  closeCraft()
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 4 })
  MOCK.trade.layout()
end

function S.craftGrey()
  if not craftReady() then return end
  MOCK.trade.recipes[4][2] = "trivial"; MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Next in the guide: Heavy Grinding Stone"), "grey: move on")
  closeCraft()
  MOCK.trade.recipes[4][2] = "optimal"; MOCK.trade.layout()
end

function S.craftScrolled()
  if not craftReady() then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
  openCraft()
  local h = LevelingCodexCraftHint
  check(h:IsShown() and not LevelingCodexCraftTrace:IsShown(), "card without a trace when the row is off screen")
  check(MOCK.textUnder(h):lower():find("scroll to the recipe.", 1, true), "the card says to scroll to it")
  MOCK.trade.offset = 11; MOCK.trade.layout() -- the player scrolls to it
  MOCK.advance(2.3)
  check(LevelingCodexCraftTrace:IsShown(), "traced once the player scrolls to it")
  check(MOCK.trade.selected == 0, "nothing selected for the player")
  closeCraft()
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
end

-- Reported in game: on the controller the crafting list wouldn't scroll once the card came up, then
-- the game crashed. The guide selected the recipe, scrolled the list and clicked its row by itself
-- (and offered Show it to do the same). The crafting window is the player's: the guide only reads
-- it and outlines the row when it's in view.
function S.craftHandsOff()
  if not craftReady() then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  local touched, restore = {}, {}
  local function spy(t, k, label)
    local f = t and t[k]
    if type(f) ~= "function" then return end
    t[k] = function(...) touched[#touched + 1] = label; return f(...) end
    restore[#restore + 1] = function() t[k] = f end
  end
  local box = MOCK.trade.box
  if box then box.ScrollToElementDataByPredicate = MOCK.trade.scrollToPredicate end
  spy(_G, "SelectTradeSkill", "SelectTradeSkill")
  spy(_G, "FauxScrollFrame_SetOffset", "FauxScrollFrame_SetOffset")
  spy(_G, "TradeSkillFrame_Update", "TradeSkillFrame_Update")
  spy(C_TradeSkillUI, "OpenRecipe", "C_TradeSkillUI.OpenRecipe")
  spy(box, "SetScrollPercentage", "SetScrollPercentage")
  spy(box, "ScrollToElementDataByPredicate", "ScrollToElementDataByPredicate")
  for i, b in ipairs(MOCK.trade.rows) do spy(b, "Click", "row " .. i .. " Click") end
  for _, pad in ipairs({ true, false }) do
    local who = pad and "controller" or "mouse"
    MOCK.gamepad, MOCK.gamepadUI = pad or nil, pad or nil
    MOCK.trade.offset, MOCK.trade.selected = 0, 0
    MOCK.trade.layout()
    for k in pairs(touched) do touched[k] = nil end
    openCraft()
    MOCK.advance(3)
    check(#touched == 0, who .. ": the guide never drives the crafting window (" .. table.concat(touched, ", ") .. ")")
    check(MOCK.trade.offset == 0 and MOCK.trade.selected == 0, who .. ": the list stays where the player left it")
    local h = LevelingCodexCraftHint
    local text = h and h:IsShown() and MOCK.textUnder(h) or ""
    local instruction = C_TradeSkillUI and "Check filters or scroll to the recipe." or "Scroll to the recipe."
    check(text:find(instruction, 1, true), who .. ": the card says where to find the recipe")
    check(not text:find("Show it"), who .. ": no Show it button")
    closeCraft()
  end
  MOCK.gamepad, MOCK.gamepadUI = nil, nil
  for _, undo in ipairs(restore) do undo() end
  if box then box.ScrollToElementDataByPredicate = nil end
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.offset, MOCK.trade.selected = 0, 0
  MOCK.trade.layout()
end

-- The crafting guide turned off in Settings: nothing over the crafting window.
function S.craftGuideOff()
  if not craftReady() then return end
  LevelingCodexDB.noCraftGuide = true
  openCraft()
  check(not (LevelingCodexCraftHint and LevelingCodexCraftHint:IsShown()), "no card when turned off")
  closeCraft()
  LevelingCodexDB.noCraftGuide = nil
end

-- The Mining (smelting) window at 80: Smelt Silver is the one that still gives points.
function S.craftSmelting()
  if not craftReady() then return end
  MOCK.setSkill("Mining", 80, 150)
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset }
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset = "Mining", 80, 150, 0
  MOCK.trade.recipes = { { "Smelt Copper", "trivial", 9 }, { "Smelt Tin", "trivial", 2 }, { "Smelt Silver", "optimal", 3 },
                         { "Smelt Bronze", "medium", 1 } }
  MOCK.trade.layout()
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("MINING  80 / 150", 1, true) and text:find("Smelt Silver") and
    text:find("About 20 crafts to skill 100"), "smelting card")
  local _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill3, "Smelt Silver row traced")
  closeCraft()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset = unpack(saved)
  MOCK.trade.layout()
end

-- The class trainer card: the guide's spells you can learn now, their cost, what else is on offer.
function S.classTrainer()
  MOCK.level = 8
  local window = CreateFrame("Frame", "ClassTrainerFrame", UIParent)
  window:SetSize(384, 512)
  window:Show()
  MOCK.trainer = { { "Heroic Strike", rank = "Rank 2", cost = 200 }, { "Hamstring", rank = "Rank 1", cost = 300 },
    { "Thunder Clap", rank = "Rank 1", category = "used" }, { "Parry", cost = 100 },
    { "Rend", rank = "Rank 2", category = "unavailable", cost = 600 } }
  MOCK.money = 400
  MOCK.event("TRAINER_SHOW")
  local card = _G.LevelingCodexTrainerHint
  if MOCK.minimal then
    check(not (card and card:IsShown()), "no trainer card without the trainer APIs")
    return
  end
  check(card and card:IsShown(), "the class trainer gets a card")
  check(questText(card, "Train 2 spells  -  5s") and questText(card, "Heroic Strike (Rank 2), Hamstring (Rank 1)"),
    "the card lists the guide's spells to train now and their cost")
  check(questText(card, "Also here, not in the guide: Parry.") and questText(card, "You have 4s: 1s short"),
    "the card names other spells on offer and says when money is short")
  check(not questText(card, "Rend"), "spells the trainer can't teach yet are left out")
  hover(card)
  MOCK.trainer[1].category = "used"
  MOCK.event("TRAINER_UPDATE")
  check(questText(card, "Train 1 spell  -  3s"), "the card updates as you train")
  MOCK.trainer[2].category = "used"
  MOCK.event("TRAINER_UPDATE")
  check(questText(card, "Nothing from the guide to train") and questText(card, "Next visit: level 10"),
    "with the guide's spells trained the card points to the next visit")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("class trainer: yes, guide spells now: 0"), "/codex debug reports the class trainer")
  MOCK.event("TRAINER_CLOSED")
  check(not card:IsShown(), "closing the trainer hides the card")
  MOCK.tradeskillTrainer = true
  MOCK.event("TRAINER_SHOW")
  check(not card:IsShown(), "profession trainers get no class card")
  MOCK.tradeskillTrainer = false
  LevelingCodexDB.noTrainerGuide = true
  MOCK.event("TRAINER_SHOW")
  check(not card:IsShown(), "the setting turns the card off")
end

-- A profession trainer: the card lists the next rank when you can train it and the route recipes this
-- trainer teaches up to your cap, and names where the next one it doesn't teach comes from.
function S.profTrainer()
  MOCK.level = 30
  MOCK.setSkill("Blacksmithing", 97, 150); MOCK.advance(1.2)
  local window = CreateFrame("Frame", "ClassTrainerFrame", UIParent)
  window:SetSize(384, 512)
  window:Show()
  MOCK.tradeskillTrainer = true
  MOCK.trainer = {
    { "Rough Bronze Leggings", "Blacksmithing", 95, category = "used" },
    { "Heavy Grinding Stone", "Blacksmithing", 100, category = "unavailable", cost = 500 },
    { "Iron Buckle", "Blacksmithing", 125, category = "unavailable", cost = 800 },
    { "Bronze Warhammer", "Blacksmithing", 100, category = "unavailable", cost = 900 },
    { "Silver Rod", "Blacksmithing", 100, cost = 300 },
    { "Blacksmithing", "Blacksmithing", 125, rank = "Expert", category = "unavailable", cost = 10000 },
  }
  MOCK.money = 1000
  MOCK.event("TRAINER_SHOW")
  local card = _G.LevelingCodexTrainerHint
  if MOCK.minimal then
    check(not (card and card:IsShown()), "no trainer card without the trainer APIs")
    return
  end
  check(card and card:IsShown() and questText(card, "PROFESSION TRAINER"), "a profession trainer gets its own card")
  check(questText(card, "Nothing to learn here yet") and
    questText(card, "Next here: Heavy Grinding Stone at 100, Bronze Warhammer at 100, Iron Buckle at 125"),
    "before the skill is there it says what this trainer teaches next")
  check(questText(card, "Expert Blacksmithing at skill 125 and level 20"), "and when the next rank opens")
  check(questText(card, "Not taught here: Green Iron Bracers (learn at 140): Expert trainers: Bengus Deepforge"),
    "and where the route's next recipe this trainer lacks comes from")
  check(not questText(card, "Silver Rod"), "recipes off the route are left out")
  MOCK.setSkill("Blacksmithing", 100, 150); MOCK.advance(1.2)
  MOCK.trainer[2].category, MOCK.trainer[4].category = "available", "available"
  MOCK.event("TRAINER_UPDATE")
  check(questText(card, "Learn 2 recipes  -  14s") and questText(card, "Heavy Grinding Stone (100-112), Bronze Warhammer (129-140)"),
    "what to learn now for the route, and the cost")
  check(questText(card, "You have 10s: 4s short"), "and when money is short")
  MOCK.trainer[2].category, MOCK.trainer[4].category = "used", "used"
  MOCK.setSkill("Blacksmithing", 125, 150); MOCK.advance(1.2)
  MOCK.trainer[3].category, MOCK.trainer[6].category = "available", "available"
  MOCK.money = 100000
  MOCK.event("TRAINER_UPDATE")
  check(questText(card, "Train Expert + 1 recipe  -  1g 8s") and questText(card, "Expert Blacksmithing (to 225), Iron Buckle (125-129)"),
    "the next rank comes first")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("profession trainer: Blacksmithing, route items now: 2"), "/codex debug reports the profession trainer")
  table.remove(MOCK.trainer, 6)
  MOCK.event("TRAINER_UPDATE")
  check(questText(card, "Expert Blacksmithing isn't listed here: Bengus Deepforge"), "a rank this trainer doesn't teach points to one who does")
  LevelingCodexDB.noTrainerGuide = true
  MOCK.event("TRAINER_SHOW")
  check(card:IsShown(), "the class trainer setting leaves the profession card alone")
  LevelingCodexDB.noTrainerGuide, LevelingCodexDB.noProfTrainer = nil, true
  MOCK.event("TRAINER_SHOW")
  check(not card:IsShown(), "Settings > Trainers turns the profession card off")
  LevelingCodexDB.noProfTrainer = nil
  MOCK.removeSkill("Blacksmithing"); MOCK.advance(1.2)
  MOCK.trainer = { { "Blacksmithing", nil, nil, rank = "Apprentice", cost = 10 } }
  MOCK.event("TRAINER_SHOW")
  check(questText(card, "Start Blacksmithing here") and questText(card, "Professions > Other guides"),
    "a profession you don't have yet points to its guide")
  MOCK.event("TRAINER_CLOSED")
  check(not card:IsShown(), "closing the trainer hides the card")
  MOCK.tradeskillTrainer = false
end

-- Vendor: greys sell one by one when a vendor opens, guide items and the Hearthstone are kept.
function S.vendorJunk()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 1, { type = "collect", item = 3301, count = 1, name = "Kept Fang", text = "Keep it." })
    end
  end
  S.login()
  MOCK.money = 0
  MOCK.bagItems = {
    { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 12, count = 3 },
    { name = "Linen Cloth", id = 2589, quality = 1, level = 1, sell = 13 },
    { name = "Kept Fang", id = 3301, quality = 0, level = 1, sell = 5 },
    { name = "Hearthstone", id = 6948, quality = 0, level = 1, sell = 5 },
    { name = "Odd Rag", id = 3302, quality = 0, level = 1, sell = 4, loaded = false },
    { name = "Torn Ear", id = 3303, quality = 0, level = 1, sell = 0 },
    { name = "Chipped Claw", id = 3304, quality = 0, level = 1, sell = 7 },
  }
  MOCK.openMerchant({ items = {} })
  if MOCK.minimal then
    MOCK.advance(2)
    check(#MOCK.sold == 0, "no selling without the container APIs")
    return
  end
  MOCK.advance(0.2)
  check(#MOCK.sold == 1 and MOCK.sold[1][1] == 3300, "the first grey sells right after the vendor opens")
  MOCK.bagItems[7] = { name = "Silk Cloth", id = 4306, quality = 1, level = 1, sell = 150 }
  MOCK.advance(2)
  check(#MOCK.sold == 1, "a slot that changed since the scan is skipped (Silk Cloth stays)")
  check(MOCK.money == 36 and chatHas("Sold 1 grey item for 36c%."), "one chat line with the total")
  MOCK.closeMerchant()
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 12 },
    { name = "Chipped Claw", id = 3304, quality = 0, level = 1, sell = 7 } }
  MOCK.sold = {}
  MOCK.openMerchant({ items = {} })
  MOCK.advance(0.2)
  MOCK.closeMerchant()
  MOCK.advance(2)
  check(#MOCK.sold == 1 and chatHas("the vendor closed"), "closing the vendor stops the run and says so")
  MOCK.sold, MOCK.alt = {}, true
  MOCK.openMerchant({ items = {} })
  MOCK.advance(2)
  check(#MOCK.sold == 0, "Alt holds selling back")
  MOCK.alt = false
  MOCK.closeMerchant()
  LevelingCodexDB.noAutoSell = true
  MOCK.openMerchant({ items = {} })
  MOCK.advance(2)
  check(#MOCK.sold == 0, "Settings can turn selling off")
end

-- The owner's report "auto sell junk did not" (the repair worked): WoW: Forever, like retail, reads
-- item info through C_Item.GetItemInfo, and the junk scan only asked the old global GetItemInfo, so
-- no grey had a price. The scenarios after this one run without the global.
function S.noGlobalItemInfo()
  GetItemInfo = nil
end

-- Vendor: repairs with your own money once the junk money is in, or says it's short.
function S.vendorRepair()
  S.login()
  if MOCK.minimal then return end
  MOCK.money = 150
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 100 } }
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(2)
  check(MOCK.repaired == 210 and chatHas("Repaired for 2s 10c%."), "repairs after the junk money comes in")
  MOCK.closeMerchant()
  MOCK.repaired, MOCK.money, MOCK.bagItems = nil, 100, {}
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(not MOCK.repaired and chatHas("Not enough money to repair %(2s 10c%)%."), "says when money is short")
  MOCK.closeMerchant()
  MOCK.money, MOCK.alt = 1000, true
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(not MOCK.repaired, "Alt holds repairing back")
  MOCK.alt = false
  MOCK.closeMerchant()
  LevelingCodexDB.noAutoRepair = true
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(not MOCK.repaired, "Settings can turn repairing off")
end

-- Vendor, the owner's report "auto repair didn't work": Forever fires MERCHANT_SHOW before the
-- vendor window shows (MOCK.merchantLate). The greys still sell and the repair still runs once the
-- window is there, and /codex debug says what the last visit did.
function S.vendorLateWindow()
  S.login()
  MOCK.money, MOCK.merchantLate = 150, 0.4
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 100 } }
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(3)
  check(#MOCK.sold == 1 and MOCK.sold[1][1] == 3300, "the grey sells once the late window shows")
  check(MOCK.repaired == 210 and chatHas("Repaired for 2s 10c%."), "and the repair follows")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("vendor: last visit: window .* after MERCHANT_SHOW; sold 1 grey item for 1s; repaired for 2s 10c"),
    "debug says what the last visit did")
  MOCK.closeMerchant()
  MOCK.repaired, MOCK.money, MOCK.bagItems = nil, 1000, {}
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  check(MOCK.repaired == 210, "with nothing to sell the repair runs once the window shows")
  MOCK.closeMerchant()
  MOCK.repaired, MOCK.sold = nil, {}
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 100 } }
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(0.2)
  MOCK.closeMerchant()
  MOCK.advance(2)
  check(#MOCK.sold == 0 and not MOCK.repaired, "a vendor closed before its window showed gets nothing")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("vendor: last visit: closed before its window showed"), "and debug says so")
  MOCK.money, MOCK.alt = 1000, true
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(1)
  MOCK.chat = {}
  slash("debug")
  check(not MOCK.repaired and chatHas("vendor: last visit: .*held back %(Alt%)"), "debug names what held it back")
  MOCK.alt, MOCK.merchantLate = false, nil
  MOCK.closeMerchant()
end

-- Vendor: a card lists what your coming steps need from this vendor, with one Buy button.
function S.vendorShopping()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 2, { type = "buy", item = 3713, count = 3, name = "Soothing Spices",
        text = "Buy 3 Soothing Spices.", map = 1429, x = 48, y = 43 })
      table.insert(section.steps, 3, { type = "buy", item = 159, count = 5, name = "Refreshing Spring Water",
        text = "Buy 5 Refreshing Spring Water.", map = 1429, x = 48, y = 43 })
    end
  end
  S.login()
  if MOCK.minimal then
    MOCK.openMerchant({ items = {} })
    MOCK.advance(1)
    check(not (_G.LevelingCodexShopCard and _G.LevelingCodexShopCard:IsShown()), "no card without the merchant API")
    return
  end
  MOCK.money = 1000
  local spices = { id = 3713, name = "Soothing Spices", price = 50, per = 1, stock = -1, maxStack = 20 }
  MOCK.openMerchant({ items = { { id = 4540, name = "Tough Hunk of Bread", price = 5 }, spices } })
  MOCK.advance(0.5)
  local card = _G.LevelingCodexShopCard
  check(card and card:IsShown() and questText(card, "3 x Soothing Spices"), "the card lists a coming step's item")
  check(not questText(card, "Hunk of Bread"), "items no step needs are left out")
  click(card, "Buy for 1s 50c")
  check(#MOCK.bought == 1 and MOCK.bought[1][1] == 3713 and MOCK.bought[1][2] == 3, "Buy buys the count")
  check(chatHas("Bought 3 Soothing Spices for 1s 50c%."), "chat says what it bought")
  MOCK.event("BAG_UPDATE_DELAYED")
  check(not card:IsShown(), "the card hides once nothing is left to buy")
  MOCK.closeMerchant()
  -- The water step: 5 at 25c is 1s 25c.
  local water = { id = 159, name = "Refreshing Spring Water", price = 25, per = 1, stock = -1 }
  MOCK.bought, MOCK.money = {}, 100
  MOCK.openMerchant({ items = { water } })
  MOCK.advance(0.5)
  check(findButton(card, function(l) return l == "Need 25c more" end), "short of gold: the button says how much")
  click(card, "Need 25c more")
  check(#MOCK.bought == 0, "and buys nothing")
  MOCK.closeMerchant()
  water.stock, MOCK.money = 2, 1000
  MOCK.openMerchant({ items = { water } })
  MOCK.advance(0.5)
  check(questText(card, "only 2 in stock"), "limited stock is noted")
  click(card, "Buy for 50c")
  check(MOCK.bought[1][2] == 2, "and only the stock is bought")
  MOCK.closeMerchant()
  check(not card:IsShown(), "closing the vendor hides the card")
end

-- Vendor: the shopping card also offers what your current profession steps need from this vendor:
-- materials (a part's own materials), a tool, the rod you lack; never what a later step needs.
function S.vendorProfSupplies()
  S.login()
  MOCK.setSkill("Tailoring", 40, 75)
  MOCK.setSkill("Engineering", 30, 75)
  MOCK.advance(1.2)
  MOCK.money = 100000
  MOCK.bags = { ["Coarse Thread"] = 5 }
  local thread = { id = 2320, name = "Coarse Thread", price = 10, per = 1, stock = -1, maxStack = 200 }
  local hammer = { id = 5956, name = "Blacksmith Hammer", price = 16 }
  MOCK.openMerchant({ items = { thread, { id = 2321, name = "Fine Thread", price = 100 }, hammer,
    { id = 2604, name = "Red Dye", price = 50 } } })
  MOCK.advance(0.5)
  local card = _G.LevelingCodexShopCard
  if MOCK.minimal then
    check(not (card and card:IsShown()), "no card without the merchant API")
    return
  end
  check(card and card:IsShown() and questText(card, "34 x Coarse Thread") and questText(card, "for Linen Belt (Tailoring)"),
    "the card offers the thread your step's crafts still need (39, you have 5)")
  check(questText(card, "1 x Blacksmith Hammer") and questText(card, "for Handful of Copper Bolts (Engineering)"),
    "and the tool your Engineering step needs")
  check(not questText(card, "Fine Thread") and not questText(card, "Red Dye"), "nothing a later step needs")
  click(card, "Buy for 3s 56c")
  check(#MOCK.bought == 2 and MOCK.bought[1][1] == 2320 and MOCK.bought[1][2] == 34 and MOCK.bought[2][1] == 5956,
    "one click buys them")
  MOCK.closeMerchant()
  MOCK.bought, MOCK.bags = {}, { ["Coarse Thread"] = 39, ["Blacksmith Hammer"] = 1 }
  MOCK.openMerchant({ items = { thread, hammer } })
  MOCK.advance(0.5)
  check(not card:IsShown(), "with the thread and the hammer in your bags there's nothing to buy")
  MOCK.closeMerchant()
  MOCK.removeSkill("Tailoring"); MOCK.removeSkill("Engineering")
  MOCK.setSkill("Enchanting", 12, 75); MOCK.advance(1.2)
  MOCK.bags = {}
  local rod = { id = 6217, name = "Copper Rod", price = 124 }
  local mote = { id = 1245321, name = "Mote of Magic", price = 40 }
  MOCK.openMerchant({ items = { rod, mote } })
  MOCK.advance(0.5)
  check(questText(card, "1 x Copper Rod") and questText(card, "1 x Mote of Magic") and
    questText(card, "for Runed Copper Rod (Enchanting)"), "without the rod your step needs, the card offers its materials")
  check(not questText(card, "9 x Mote of Magic"), "the step's own Motes are made from Strange Dust, not bought")
  MOCK.closeMerchant()
  LevelingCodexDB.noProfShop = true
  MOCK.openMerchant({ items = { rod, mote } })
  MOCK.advance(0.5)
  check(not card:IsShown(), "Settings > Vendor > Include profession supplies turns it off")
  MOCK.closeMerchant()
  LevelingCodexDB.noProfShop = nil
end

-- Stats: XP, gold by source, activity and zone time, counted per level and saved.
local STATS_MAPS = { [1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 1415 },
  [12] = { name = "Northshire", mapType = 5, parentMapID = 1429 } }

function S.statsCounters()
  MOCK.mapInfo = STATS_MAPS
  LevelingCodexCharDB = { stats = "x" } -- a broken saved shape is replaced, not used
  S.login()
  if MOCK.minimal then MOCK.advance(2); return end
  local lvl = MOCK.level
  local st = LevelingCodexCharDB.stats
  check(type(st) == "table" and st.version == 1, "broken saved stats start fresh")
  local function L() return st.levels[lvl] end
  MOCK.setMoney(1000)
  MOCK.event("QUEST_TURNED_IN", 783, 120, 500)
  MOCK.setMoney(1500)
  check(L().goldIn.quest == 500 and L().quests == 1 and L().questXP == 120, "a turn-in: quest gold, count and XP")
  MOCK.event("LOOT_OPENED"); MOCK.setMoney(1600); MOCK.event("LOOT_CLOSED")
  check(L().goldIn.loot == 100, "money while looting is loot")
  MOCK.event("TRAINER_SHOW"); MOCK.setMoney(1400); MOCK.event("TRAINER_CLOSED")
  check(L().goldOut.training == 200, "money spent at a trainer is training")
  MOCK.setMoney(1350)
  check(L().goldOut.other == 50, "anything else is other")
  MOCK.event("CHAT_MSG_COMBAT_XP_GAIN", "Kobold Vermin dies, you gain 45 experience.")
  check(L().killXP == 45 and L().kills == 1, "a kill's XP and count")
  MOCK.event("PLAYER_DEAD")
  check(L().deaths == 1 and st.totals.deaths == 1, "a death")
  MOCK.event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 8690)
  check(st.totals.hearths == 1, "a hearthstone use")
  check(not next(MOCK.events.UNIT_SPELLCAST_SUCCEEDED or {}),
    "spell casts are watched for you only, not every unit around you")
  check(MOCK.event("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast-2", 8690) == 0 and st.totals.hearths == 1,
    "a party member's hearthstone doesn't reach the Codex")
  MOCK.event("TIME_PLAYED_MSG", 3600, 600)
  check(st.played.total == 3600 and st.played.level == 600, "/played is remembered")
  local before = L().seconds
  MOCK.advance(3)
  check(L().seconds >= before + 3 and st.zones[1429] and st.zones[1429].seconds >= 3, "time goes to the level and the zone")
  MOCK.questMap = 12
  local elwynn = st.zones[1429].seconds
  MOCK.advance(2)
  check(st.zones[1429].seconds >= elwynn + 2 and not st.zones[12], "a subzone map rolls up to its zone")
  MOCK.questMap = 1429
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 40 } }
  MOCK.openMerchant({ items = {} })
  MOCK.advance(1)
  MOCK.closeMerchant()
  check(L().goldIn.junk == 40 and (L().goldIn.sales or 0) == 0, "the Codex's junk sales are junk, not sales")
end

-- Stats: a turn-in that levels you up keeps its gold with the level you turned it in at, whichever
-- comes first, the reward's money or the level-up.
function S.statsLevelUp()
  MOCK.money = 1000 -- known at login: no early gain to move around
  S.login()
  if MOCK.minimal then return end
  local st, lvl = LevelingCodexCharDB.stats, MOCK.level
  local function gold(level, key)
    local l = st.levels[level]
    return l and l.goldIn[key] or 0
  end
  -- the turn-in, the level-up, then its money
  MOCK.event("QUEST_TURNED_IN", 783, 120, 500)
  MOCK.level = lvl + 1
  MOCK.event("PLAYER_LEVEL_UP", lvl + 1)
  MOCK.setMoney(1500)
  check(gold(lvl, "quest") == 500 and gold(lvl + 1, "quest") == 0,
    "the reward stays with the level it was earned at (" .. gold(lvl, "quest") .. " / " .. gold(lvl + 1, "quest") .. ")")
  -- the money, the level-up, then the turn-in
  MOCK.setMoney(1800)
  MOCK.level = lvl + 2
  MOCK.event("PLAYER_LEVEL_UP", lvl + 2)
  MOCK.event("QUEST_TURNED_IN", 33, 100, 300)
  check(gold(lvl + 1, "quest") == 300 and gold(lvl + 1, "other") == 0 and gold(lvl + 2, "other") == 0
    and gold(lvl + 2, "quest") == 0, "money that came first moves to quest rewards at its own level")
  -- the level-up its XP caused, then the turn-in, then its money
  MOCK.advance(3)
  MOCK.level, MOCK.xp = lvl + 3, 40
  MOCK.event("PLAYER_LEVEL_UP", lvl + 3)
  MOCK.event("QUEST_TURNED_IN", 18, 200, 700)
  MOCK.setMoney(2500)
  check(gold(lvl + 2, "quest") == 700 and gold(lvl + 3, "quest") == 0,
    "a level-up just before its own turn-in still files the reward at the level it finished")
end

-- The Stats tab: tiles, level splits with bars, gold earned and spent, activity tiles and zones, a
-- session/character switch; two clicks reset.
function S.statsTab()
  MOCK.mapInfo, MOCK.money = STATS_MAPS, 1000 -- money known at login, so the reward's change is filed
  LevelingCodexCharDB = { stats = { version = 1, zones = {}, totals = { goldIn = {}, goldOut = {} },
    levels = { [MOCK.level + 1] = { seconds = 0, xp = 0, questXP = 0, killXP = 0, rested = 0, quests = 0, kills = 0,
      deaths = 0, goldIn = {}, goldOut = {} } } } } -- an empty record: drawn without dividing by zero
  S.login()
  MOCK.event("QUEST_TURNED_IN", 783, 120, 500)
  MOCK.setMoney(1500)
  MOCK.advance(2)
  slash("")
  click(win(), "Stats")
  for _, head in ipairs({ "LEVEL SPLITS", "GOLD EARNED", "GOLD SPENT", "ACTIVITY", "ZONES", "XP per hour",
      "Next level in", "Gold per hour" }) do
    check(questText(win(), head), "the Stats tab has " .. head)
  end
  local function seg(name) return findButton(win(), function(l) return l == name end) end
  if not MOCK.minimal then
    check(seg("This character") and seg("This character").codexOn, "the character's figures by default")
  end
  check((MOCK.minimal or questText(win(), "Quest rewards")) and not questText(win(), "Repairs"),
    "only sources that moved money (the minimal client has no GetMoney)")
  check(not MOCK.minimal or questText(win(), "Nothing yet."), "an empty column says so")
  local split = findButton(win(), function(l) return l == "Level " .. MOCK.level end)
  check(split, "each level split is hoverable")
  MOCK.fire(split, "OnEnter")
  -- (the minimal client counts nothing here, like statsCounters: only the line's shape is checked)
  check(GameTooltip._lines and GameTooltip._lines[2]
    and GameTooltip._lines[2]:find(MOCK.minimal and "Quest XP " or "Quest XP 120", 1, true),
    "hovering a split gives its XP by source")
  MOCK.fire(split, "OnLeave")
  check(MOCK.minimal or questText(win(), "Elwynn Forest"), "zones show (the minimal client has no map API)")
  click(win(), "This session")
  check(seg("This session").codexOn and not findButton(win(), function(l) return l == "Level " .. (MOCK.level + 1) end),
    "this session's figures leave out levels from saved sessions")
  click(win(), "This character")
  click(win(), "Reset stats")
  click(win(), "Click again to reset")
  check(LevelingCodexCharDB.stats.totals.quests == 0, "two clicks reset the saved stats")
end

-- Nine tabs fit along the bottom of the window (they shrink when the labels are too wide).
function S.tabRowFits()
  S.login()
  slash("")
  local frame, tabs, left, right = win(), {}, nil, nil
  for _, b in ipairs({ frame:GetChildren() }) do
    if b._type == "Button" and b.label and b.SetSelected then tabs[#tabs + 1] = b end
  end
  check(#tabs == 11, "eleven tabs (" .. #tabs .. ")")
  local total = 0
  for _, b in ipairs(tabs) do total = total + b:GetWidth() end
  total = total - 12 * (#tabs - 1)
  check(total <= frame:GetWidth() - 32 + 0.5, "the tab row fits under the window: " .. total .. " of " .. frame:GetWidth())
end

-- Without saved data the tab says it counts from login.
function S.statsTabLost()
  slash("")
  click(win(), "Stats")
  check(questText(win(), "Counting since you logged in"), "without saved data the tab says what it counts")
  check(not findButton(win(), function(l) return l == "This character" end), "no switch without saved data")
end

-- Vendor with a server round trip (money and bought items arrive later): the repair waits for the
-- junk money, and a second click on Buy doesn't buy the list again.
function S.vendorServer()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 2, { type = "buy", item = 3713, count = 3, name = "Soothing Spices",
        text = "Buy 3 Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  S.login()
  MOCK.serverDelay = 0.3
  MOCK.money = 150
  MOCK.bagItems = { { name = "Broken Fang", id = 3300, quality = 0, level = 1, sell = 100 } }
  MOCK.openMerchant({ items = {}, canRepair = true, repairCost = 210 })
  MOCK.advance(2)
  check(MOCK.repaired == 210 and not chatHas("Not enough money to repair"),
    "the repair waits for the junk money to arrive")
  MOCK.closeMerchant()
  MOCK.money, MOCK.bagItems = 1000, {}
  MOCK.openMerchant({ items = { { id = 3713, name = "Soothing Spices", price = 50 } } })
  MOCK.advance(0.5)
  local card = _G.LevelingCodexShopCard
  card.buy:Click()
  card.buy:Click()
  MOCK.advance(1)
  check(#MOCK.bought == 1, "a second click before the items arrive buys nothing more (" .. #MOCK.bought .. " buys)")
  check(not card:IsShown(), "the card hides once the items are in your bags")
end

-- Vendor: a purchase the game refuses (full bags) is never called bought; one that arrives late is.
function S.vendorBuyFails()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 2, { type = "buy", item = 3713, count = 3, name = "Soothing Spices",
        text = "Buy 3 Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  S.login()
  MOCK.serverDelay, MOCK.money, MOCK.buyFails = 0.3, 1000, true
  MOCK.openMerchant({ items = { { id = 3713, name = "Soothing Spices", price = 50 } } })
  MOCK.advance(0.5)
  local card = _G.LevelingCodexShopCard
  card.buy:Click()
  MOCK.advance(0.5)
  check(not chatHas("Bought"), "nothing is called bought before it arrives")
  MOCK.advance(5)
  check(not chatHas("Bought") and chatHas("Couldn't buy 3 Soothing Spices"), "a purchase that never arrives says so")
  check(card:IsShown() and findButton(card, function(l) return l == "Buy for 1s 50c" end), "and the card offers Buy again")
  MOCK.buyFails = nil
  card.buy:Click()
  check(not chatHas("Bought"), "the items are on their way")
  MOCK.advance(1)
  check(chatHas("Bought 3 Soothing Spices for 1s 50c%."), "once they're in your bags, chat says what it bought")
end

-- Vendor with a controller: the shopping card never takes the controller from the vendor window.
function S.vendorPad()
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == "northshire" then
      table.insert(section.steps, 2, { type = "buy", item = 3713, count = 3, name = "Soothing Spices",
        text = "Buy 3 Soothing Spices.", map = 1429, x = 48, y = 43 })
    end
  end
  MOCK.gamepad, MOCK.gamepadUI = true, true
  S.login()
  MOCK.money = 1000
  MOCK.openMerchant({ items = { { id = 3713, name = "Soothing Spices", price = 50 } } })
  MOCK.advance(1)
  local card = _G.LevelingCodexShopCard
  check(card and card:IsShown(), "the card shows with a controller too")
  check(GamepadMode.FrameControlsManager:GetActiveFrame() ~= card, "the card doesn't take the controller's focus")
  check(not (LevelingCodexPadFocus and LevelingCodexPadFocus:IsShown()), "and gets no highlight of its own")
  check(#MOCK.bought == 0, "nothing is bought")
end

-- Vendor: a quest in your log that needs a vendor item, next to the step that buys it, counts once.
function S.vendorShoppingQuest()
  routeAt("Human", 35, 1445, 66.4, 51.5, { { questID = 1218, title = "Soothing Spices",
    objectives = { { text = "Soothing Spices: 0/3", finished = false } } } })
  MOCK.money = 1000
  MOCK.openMerchant({ items = { { id = 3713, name = "Soothing Spices", price = 50 } } })
  MOCK.advance(0.5)
  local card = _G.LevelingCodexShopCard
  check(card and card:IsShown() and questText(card, "3 x Soothing Spices"), "Theramore: the card lists Jarl's spices")
  check(not questText(card, "6 x Soothing Spices"), "the buy step and the quest don't add up")
  check(questText(card, "Swamp Eye"), "it says who they're for")
end

-- A trainer's real skill requirements that differ from the guide show in /codex debug.
function S.trainerReqs()
  if not D() or MOCK.minimal then return end
  MOCK.trainer = { { "Rough Bronze Leggings", "Blacksmithing", 80 }, { "Runed Copper Belt", "Blacksmithing", 80 },
                   { "Copper Bracers", "Blacksmithing", 1 }, { "Smelt Silver", "Mining", 70 } }
  MOCK.event("TRAINER_SHOW")
  MOCK.chat = {}
  slash("debug")
  check(chatHas("trainer: Rough Bronze Leggings needs 80 %(guide says 95%)"), "difference reported")
  check(chatHas("trainer: Smelt Silver needs 70 %(guide says 75%)"), "smelt difference reported")
  check(not chatHas("Runed Copper Belt needs"), "matching values not reported")
  check(not chatHas("Copper Bracers"), "recipes off the route not reported")
end

-- The game sends TRADE_SKILL_SHOW before its window is on screen: the card still comes.
function S.craftEventFirst()
  if not craftReady() then return end
  closeCraft()
  check(not (LevelingCodexCraftHint and LevelingCodexCraftHint:IsShown()), "starts with the window closed")
  MOCK.event("TRADE_SKILL_SHOW")
  MOCK.advance(0.4)
  TradeSkillFrame:Show()
  MOCK.advance(0.6)
  check(LevelingCodexCraftHint and LevelingCodexCraftHint:IsShown(), "card when the window shows after the event")
  closeCraft()
end

-- A recipe you know but the window's filter or a closed heading hides; one you don't know shows its alternative.
function S.craftFiltered()
  if not craftReady() then return end
  table.remove(MOCK.trade.recipes, 4); MOCK.trade.layout()
  MOCK.knownSpells[2668] = true
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Recipe hidden"), "known but filtered")
  closeCraft()
  MOCK.knownSpells[2668] = nil
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Recipe not learned") and text:find("Alternative: Runed Copper Belt"), "not learned shows the alternative")
  local hint, knownSpell = LevelingCodexCraftHint, IsPlayerSpell
  local expanded = hint:GetHeight()
  IsPlayerSpell = nil
  MOCK.advance(0.6)
  text = MOCK.textUnder(hint)
  check(text:find("Recipe unavailable") and not text:find("Recipe not learned"), "unknown recipe knowledge is shown as unavailable")
  IsPlayerSpell = knownSpell
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 0 })
  MOCK.trade.layout(); MOCK.advance(0.6)
  text = MOCK.textUnder(hint)
  check(text:find("Missing materials") and not text:find("Alternative:") and hint:GetHeight() < expanded,
    "a visible recipe without materials has a shorter hint and no stale alternative")
  closeCraft()
  MOCK.trade.recipes[#MOCK.trade.recipes][3] = 4
  MOCK.trade.layout()
end

-- Classic calls that exist but return nothing (compatibility stubs): C_TradeSkillUI is read instead.
function S.craftClassicStubs()
  if not craftReady() then return end
  local count = GetNumTradeSkills
  S.retailAPI()
  GetNumTradeSkills = function() return 0 end
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Materials for 4 crafts"), "recipe read through C_TradeSkillUI")
  closeCraft()
  GetNumTradeSkills = count
  C_TradeSkillUI = nil
end

-- The recipe is in the list but scrolled out of view: the row search slows down (it walks the
-- whole window), yet a row scrolled into view is outlined within about 2 s.
function S.craftRowBackoff()
  if not craftReady() then return end
  for i = 1, 10 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
  local searches, walk = 0, TradeSkillFrame.GetChildren
  TradeSkillFrame.GetChildren = function(self) searches = searches + 1; return walk(self) end
  openCraft()
  searches = 0
  MOCK.advance(20)
  check(searches <= 14, "row searched " .. searches .. " times in 20 s while scrolled out of view")
  check(not LevelingCodexCraftTrace:IsShown(), "no outline while out of view")
  local at
  for i, r in ipairs(MOCK.trade.recipes) do if r[1] == "Rough Bronze Leggings" then at = i end end
  MOCK.trade.offset = at - 3; MOCK.trade.layout() -- the player scrolls to it
  MOCK.advance(2.3)
  check(LevelingCodexCraftTrace:IsShown(), "outlined within about 2 s of scrolling into view")
  TradeSkillFrame.GetChildren = nil
  closeCraft()
  for _ = 1, 10 do table.remove(MOCK.trade.recipes, 1) end
  MOCK.trade.offset = 0
  MOCK.trade.layout()
end

-- Reported in game: with the crafting window near the top of the screen the card went below it,
-- over the controller hint bar the game hangs under the window. Bars touching the window's edge
-- count as part of the window.
function S.craftHintClearsBar()
  if not craftReady() or not EnumerateFrames then return end
  TradeSkillFrame._top, TradeSkillFrame._bottom = 1075, 560
  local bar = CreateFrame("Frame", nil, UIParent); bar:SetSize(600, 62)
  bar._top, bar._bottom = 562, 500
  openCraft()
  local h = LevelingCodexCraftHint
  local _, rel, _, _, y = h:GetPoint(1)
  check(h.where == "below" and rel == TradeSkillFrame and y and y <= -66,
    "card below the bar under the window (" .. tostring(h.where) .. ", offset " .. tostring(y) .. ")")
  closeCraft()
  bar:Hide()
  TradeSkillFrame._top, TradeSkillFrame._bottom = nil, nil
end

-- Tailoring at 150 (Earthen Vest takes 3 Bolts of Silk Cloth): with only the cloth, the bolt is
-- outlined first; with bolts, the step's recipe again.
local function tailorWindow(fillers)
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected }
  MOCK.setSkill("Tailoring", 150, 225)
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset, MOCK.trade.selected = "Tailoring", 150, 225, 0, 0
  MOCK.trade.recipes = { { "Bolt of Silk Cloth", "trivial", 11 }, { "Crimson Silk Vest", "optimal", 0 }, { "Earthen Vest", "medium", 0 } }
  for i = 1, fillers or 0 do table.insert(MOCK.trade.recipes, 1, { "Filler " .. i, "trivial", 0 }) end
  MOCK.bags = { ["Silk Cloth"] = 46 }
  MOCK.trade.layout()
  return function()
    MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected = unpack(saved)
    MOCK.bags = {}
    MOCK.trade.layout()
  end
end

function S.craftTailoring()
  if not craftReady() then return end
  local restore = tailorWindow()
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("46 Silk Cloth in your bags can make 11 Bolts of Silk Cloth.", 1, true), "bolts first with only the cloth")
  local _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill1, "the bolt row is outlined (grey, but still the one to make)")
  MOCK.bags["Bolt of Silk Cloth"] = 11; MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(text:find("Earthen Vest") and not text:find("first"), "with bolts: the step's recipe")
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill3, "Earthen Vest outlined")
  MOCK.bags = {}; MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Earthen Vest") and not text:find("first"), "no bolts, no cloth: the step's recipe")
  MOCK.bags = { ["Silk Cloth"] = 46 }
  local vest = table.remove(MOCK.trade.recipes, 3); MOCK.trade.layout(); MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Earthen Vest") and text:find("Recipe not learned") and not text:find("first"),
    "the step's recipe not learned: say so, not bolts first")
  table.insert(MOCK.trade.recipes, vest)
  table.remove(MOCK.trade.recipes, 1); MOCK.trade.layout(); MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Earthen Vest") and not text:find("first"), "bolt recipe not in the list: the step's recipe")
  closeCraft()
  restore()
end

-- Enchanting: a missing rod is outlined first (a better rod counts, a grey rod is still needed), then
-- Dust to Motes when you have the dust but no Motes.
local function enchantWindow(skill, max, recipes, bags)
  MOCK.setSkill("Enchanting", skill, max)
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset, MOCK.trade.selected = "Enchanting", skill, max, 0, 0
  MOCK.trade.recipes = recipes
  MOCK.bags = bags
  MOCK.trade.layout()
  MOCK.advance(1)
end

function S.craftEnchanting()
  if not craftReady() then return end
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected }
  enchantWindow(150, 225, { { "Runed Silver Rod", "easy", 0 }, { "Enchant Bracer - Lesser Stamina", "optimal", 0 },
    { "Dust to Motes", "trivial", 3 } }, {})
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make this rod first for Enchant Bracer - Lesser Stamina.", 1, true), "rod first")
  local _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill1, "the rod row is outlined")
  MOCK.bags["Runed Truesilver Rod"] = 1; MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  _, rel = LevelingCodexCraftTrace:GetPoint(1)
  check(text:find("Enchant Bracer %- Lesser Stamina") and not text:find("first"), "a better rod counts: the step's recipe")
  check(LevelingCodexCraftTrace:IsShown() and rel == TradeSkillSkill2, "the bracer row is outlined")
  MOCK.bags = {}
  table.remove(MOCK.trade.recipes, 2); MOCK.trade.layout(); MOCK.advance(1)
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Recipe not learned") and not text:find("first"), "the step's recipe missing: not learned, not the rod")
  enchantWindow(270, 300, { { "Runed Truesilver Rod", "trivial", 0 }, { "Enchant Shield - Greater Stamina", "optimal", 0 } }, {})
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make this rod first for Enchant Shield - Greater Stamina.", 1, true) and
    not text:find("No skill points"), "a grey rod still needed")
  check(LevelingCodexCraftTrace:IsShown(), "the grey rod is outlined")
  enchantWindow(1, 75, { { "Runed Copper Rod", "optimal", 0 }, { "Dust to Motes", "optimal", 5 } }, { ["Strange Dust"] = 5 })
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Runed Copper Rod") and not text:find("Make this first"), "skill 1: the rod, not Motes (Dust to Motes needs the rod)")
  enchantWindow(12, 75, { { "Dust to Motes", "trivial", 5 }, { "Enchant Bracer - Inferior Stamina", "optimal", 0 } },
    { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 5 })
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("5 Strange Dust in your bags can make 15 Motes of Magic.", 1, true), "Motes first: 3 per dust")
  closeCraft()
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset, MOCK.trade.selected = unpack(saved)
  MOCK.bags = {}
  MOCK.trade.layout()
end

-- The crafting window closed by its own close button (no event yet): the guide goes at once.
function S.craftOnHide()
  if not craftReady() then return end
  openCraft()
  check(LevelingCodexCraftHint:IsShown(), "card up")
  TradeSkillFrame:Hide()
  check(not LevelingCodexCraftHint:IsShown() and not LevelingCodexCraftTrace:IsShown(), "card and outline hide with the window")
  MOCK.event("TRADE_SKILL_CLOSE"); MOCK.advance(0.6)
end

-- Smelting at 66 (Bronze beats green Tin), 100 (Silver is yellow: a chance, not a count) and 145 (nothing gives points).
function S.craftSmeltingCases()
  if not craftReady() then return end
  local saved = { MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset }
  local function at(rank, recipes)
    MOCK.setSkill("Mining", rank, 225)
    MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.offset = "Mining", rank, 225, 0
    MOCK.trade.recipes = recipes
    MOCK.trade.layout()
    openCraft()
    local text = MOCK.textUnder(LevelingCodexCraftHint)
    closeCraft()
    return text
  end
  local t = at(66, { { "Smelt Copper", "trivial", 9 }, { "Smelt Tin", "easy", 2 }, { "Smelt Bronze", "medium", 1 } })
  check(t:find("Smelt Bronze") and not t:find("Smelt Tin"), "66: Smelt Bronze, the better chance")
  t = at(100, { { "Smelt Copper", "trivial", 9 }, { "Smelt Tin", "trivial", 2 }, { "Smelt Bronze", "easy", 1 },
                { "Smelt Silver", "medium", 3 } })
  check(t:find("Smelt Silver") and t:find("chance of a point") and not t:find("crafts to skill", 1, true), "100: a chance, not a count")
  t = at(145, { { "Smelt Copper", "trivial", 9 }, { "Smelt Bronze", "trivial", 1 }, { "Smelt Silver", "trivial", 3 },
                { "Smelt Iron", "trivial", 5 } })
  check(t:find("no skill points at 145") and t:find("Smelt Gold") and t:find("155"), "145: mine instead, Gold from 155")
  t = at(184, { { "Smelt Gold", "easy", 3 } })
  check(t:find("Smelt Gold") and t:find("chance of a point"), "184: Gold still gives points")
  t = at(185, { { "Smelt Gold", "trivial", 3 } })
  check(t:find("no skill points at 185"), "185: Gold is grey, mine instead")
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset = unpack(saved)
  MOCK.trade.layout()
end

-- A new character's intro cinematic (or Alt+Z) hides UIParent: the step window comes back with it.
-- Only the player's own Hide keeps it closed.
function S.questUiHidden()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Horde", "Scourge", 1, 1420, 30.0, 71.8
  S.login()
  local frame = questViewer()
  check(questText(frame, "Rude Awakening"), "a fresh Undead starts at Rude Awakening")
  UIParent:Hide()
  check(not frame:IsVisible(), "hidden with the UI")
  UIParent:Show()
  MOCK.event("QUEST_LOG_UPDATE")
  MOCK.advance(1)
  check(frame:IsShown() and frame:IsVisible(), "back when the UI comes back")
  click(frame, "Hide")
  UIParent:Hide()
  UIParent:Show()
  MOCK.event("QUEST_LOG_UPDATE")
  check(not frame:IsShown(), "a window the player hid stays hidden")
  MOCK.faction = nil
end

-- A fresh character whose client lists flight points as known: guides it hasn't started show no %.
function S.questFreshProgress()
  MOCK.faction, MOCK.race, MOCK.level, MOCK.questMap, MOCK.questX, MOCK.questY = "Horde", "Scourge", 1, 1420, 30.0, 71.8
  LevelingCodexCharDB = { questFlights = { ["Crossroads, The Barrens"] = true, ["Ratchet, The Barrens"] = true,
    ["The Sepulcher, Silverpine Forest"] = true, ["Undercity, Tirisfal"] = true, ["Orgrimmar, Durotar"] = true } }
  S.login()
  MOCK.questLog = { { questID = 363 } }
  MOCK.event("QUEST_ACCEPTED", 1, 363)
  MOCK.event("QUEST_LOG_UPDATE")
  slash("quests")
  for _, name in ipairs({ "The Crossroads", "Silverpine Forest", "Northern Barrens" }) do
    check(guideButton(name), "the guide list has " .. name)
  end
  local function tagged(root)
    for _, r in ipairs({ root:GetRegions() }) do
      if r:IsShown() and type(r._text) == "string" and r._text:find("^Later %d+%%") then return r._text end
    end
    for _, c in ipairs({ root:GetChildren() }) do
      local hit = c:IsShown() and tagged(c)
      if hit then return hit end
    end
  end
  local tag = tagged(win())
  check(not tag, "no guide you haven't started shows a percentage: " .. tostring(tag))
  MOCK.faction = nil
end

----------------------------------------------------------------------------
-- external UI (MOCK.makeexternal UI): its skin API themes the Codex. Its pieces must only go on the
-- backing frames the Codex makes for them: external UI fades every texture of a frame it skinned again
-- whenever some Blizzard windows open (the talent window among them, under the talent card).
----------------------------------------------------------------------------

local function eachFrame(root, fn)
  fn(root)
  for _, c in ipairs({ root:GetChildren() }) do eachFrame(c, fn) end
end

local function euiCalled(kind, frame)
  for _, c in ipairs(MOCK.eui.calls) do
    if c[1] == kind and (frame == nil or c[2] == frame) then return true end
  end
  return false
end

-- Every frame external UI keeps for its re-fade is a backing frame (codexSkin) holding only its textures.
local function euiOnlyOnBacking()
  for frame, kind in pairs(MOCK.eui.skinned) do
    if MOCK.eui.restrip[frame] then
      check(frame.codexSkin, "external UI's " .. kind .. " went on a Codex frame (" .. tostring(frame:GetName()) .. ")", 2)
      for _, r in ipairs({ frame:GetRegions() }) do
        check(MOCK.eui.own[r] or not r:IsObjectType("Texture"), "a Codex texture on an external UI backing frame", 2)
      end
    end
  end
end

-- external UI's re-fade leaves every Codex texture under these frames as it was.
local function survivesRestrip(roots, what)
  local before, n = {}, 0
  for _, root in ipairs(roots) do
    eachFrame(root, function(f)
      for _, r in ipairs({ f:GetRegions() }) do
        if r:IsObjectType("Texture") and not MOCK.eui.own[r] then before[r] = r:GetAlpha(); n = n + 1 end
      end
    end)
  end
  check(n > 0, what .. " has textures to check", 2)
  MOCK.euiRestrip()
  for r, a in pairs(before) do check(r:GetAlpha() == a, "external UI's re-fade hid a texture of " .. what, 2) end
end

local function usesFont(root, path)
  local hit
  eachFrame(root, function(f)
    for _, r in ipairs({ f:GetRegions() }) do
      if r:IsShown() and r._font == path and r._text and r._text ~= "" then hit = true end
    end
  end)
  return hit
end

local MORPHEUS = "Fonts\\MORPHEUS.TTF"

-- Installed and on: the theme at login, external UI's shell, close button and font, nothing on content.
function S.euiSkin()
  local E = MOCK.eui
  check(E and E.fired.LevelingCodex, "the Codex registered its skin with external UI and it ran")
  check(#E.registry == 1, "registered once (" .. #E.registry .. ")")
  if not D() then return end
  openAt(30, "This Level")
  local f = win()
  check(f.euiSkin and E.skinned[f.euiSkin] == "Shell", "the window's backing frame has external UI's window shell")
  check(f._backdrop == nil, "no Blizzard dialog border under the external UI shell")
  check(euiCalled("CloseButton"), "the close button is external UI's")
  check(euiCalled("PageButton"), "the level arrows are external UI's")
  check(usesFont(f, E.font), "the window's text is in the external UI font")
  check(not usesFont(f, MORPHEUS), "no Morpheus headings in the external UI theme")
  for _, tab in ipairs({ "Talents", "Trainer", "Macros", "Tips", "Professions", "Quests", "Stats", "Settings" }) do
    click(win(), tab)
    check(not usesFont(win(), MORPHEUS), "no Morpheus on " .. tab)
  end
  click(win(), "This Level")
  euiOnlyOnBacking()
  survivesRestrip({ win() }, "the Codex window")
  local v = questViewer()
  check(v.euiSkin and E.skinned[v.euiSkin] == "Panel", "the step window's backing frame has external UI's panel")
  check(v._backdrop == nil, "no Blizzard dialog border on the step window")
  check(not usesFont(v, MORPHEUS), "no Morpheus on the step window")
  survivesRestrip({ v }, "the step window")
  euiOnlyOnBacking()
  win():Hide()
end

-- The trainer, talent, crafting and vendor cards: an external UI panel behind them, their icons kept.
function S.euiCards()
  local seen = 0
  for _, name in ipairs({ "LevelingCodexTrainerHint", "LevelingCodexTalentHint", "LevelingCodexCraftHint", "LevelingCodexShopCard" }) do
    local card = _G[name]
    if card then
      seen = seen + 1
      check(card.euiSkin and MOCK.eui.skinned[card.euiSkin] == "Panel", name .. " has an external UI panel behind it")
      check(card._backdrop == nil, name .. " has no Blizzard tooltip border")
      check(not usesFont(card, MORPHEUS), name .. " has no Morpheus heading")
      survivesRestrip({ card }, name)
    end
  end
  check(seen > 0 or MOCK.minimal, "a card to check")
  euiOnlyOnBacking()
end

-- Settings: the external UI theme sits beside the other two and a choice made with it on is kept apart.
function S.euiThemePick()
  if not D() then return end
  openAt(30, "Settings")
  check(findButton(win(), function(l) return l == "External skin" end), "Settings offers the external UI theme")
  local before = LevelingCodexDB.theme
  click(win(), "Forever (teal)")
  check(LevelingCodexDB.euiTheme == "forever", "the choice made with external UI on is saved apart")
  check(LevelingCodexDB.theme == before, "the theme without external UI is untouched")
  check(win():IsShown() and not (win().euiSkin and win().euiSkin:IsShown()), "the window rebuilt without the external UI shell")
  check(not MOCK.minimal == (win()._backdrop ~= nil), "Forever teal draws its own border again")
  local v = _G.LevelingCodexQuestViewer
  if v and v:IsShown() then check(not (v.euiSkin and v.euiSkin:IsShown()), "the step window drops the external UI panel") end
  click(win(), "Settings")
  click(win(), "External skin")
  check(LevelingCodexDB.euiTheme == "ellesmere", "external UI chosen again")
  check(win().euiSkin and win().euiSkin:IsShown(), "the external UI shell is back")
  if v and v:IsShown() then check(v.euiSkin and v.euiSkin:IsShown(), "the step window's panel is back") end
  euiOnlyOnBacking()
  win():Hide()
end

-- A new accent colour in external UI repaints the Codex and never opens a closed window. A colour
-- picker sends a change for every step of a drag: the Codex repaints once, after the last.
function S.euiAccent()
  if not D() then return end
  if win() then win():Hide() end
  MOCK.euiLooks({ 1, 0.5, 0 })
  MOCK.advance(0.5)
  check(not (win() and win():IsShown()), "an accent change leaves the window closed")
  openAt(30, "Settings")
  local accent = MOCK.ns.C.accent
  check(accent[1] == 1 and accent[2] == 0.5 and accent[3] == 0, "the Codex follows external UI's new accent")
  local function shells()
    local n = 0
    for _, c in ipairs(MOCK.eui.calls) do if c[1] == "Shell" then n = n + 1 end end
    return n
  end
  local before = shells()
  for i = 1, 8 do MOCK.euiLooks({ 0.2, 0.6, 0.1 * i }); MOCK.advance(0.05) end
  check(shells() == before, "no repaint while the colour is still moving")
  MOCK.advance(0.5)
  check(shells() == before + 1, "one repaint after the last change (" .. (shells() - before) .. ")")
  check(win():IsShown(), "an accent change keeps an open window open")
  check(math.abs(MOCK.ns.C.accent[3] - 0.8) < 1e-9, "and repaints it in the last colour")
  euiOnlyOnBacking()
  win():Hide()
end

function S.euiDebug()
  MOCK.chat = {}
  slash("debug")
  if MOCK.eui and MOCK.eui.off then
    check(chatHas("external UI: installed, skin off"), "debug says external UI's skin is off for the Codex")
  elseif MOCK.eui then
    check(chatHas("external UI: skin on %(api 4, style eui%)"), "debug says the external UI skin is on")
  else
    check(chatHas("external UI: not installed"), "debug says external UI isn't installed")
  end
end

-- external UI installed with its skin for the Codex turned off: nothing changes.
function S.euiOff()
  check(MOCK.eui and not MOCK.eui.fired.LevelingCodex, "the skin callback never ran")
  if not D() then return end
  openAt(30, "Settings")
  check(not findButton(win(), function(l) return l == "External skin" end), "no external UI theme while its skin is off")
  check(not win().euiSkin, "no external UI shell")
  check(not MOCK.minimal == (win()._backdrop ~= nil), "the Codex draws its own border")
  win():Hide()
  S.euiDebug()
end

function S.euiDispatch() MOCK.euiDispatch() end

-- external UI's callback after the Codex started (its PLAYER_LOGIN came second): the theme switches live.
function S.euiLate()
  local v = questViewer()
  check(not v.euiSkin, "Forever teal until external UI's callback runs")
  if D() then openAt(30, "This Level"); win():Hide() end
  MOCK.euiDispatch()
  check(MOCK.eui.fired.LevelingCodex, "the callback ran")
  check(v.euiSkin and v.euiSkin:IsShown(), "the step window takes the external UI panel at once")
  check(not usesFont(v, MORPHEUS), "and its fonts")
  if D() then
    check(not win():IsShown(), "the window stays closed")
    openAt(30, "This Level")
    check(win().euiSkin and win().euiSkin:IsShown(), "the window opens in the external UI theme")
    win():Hide()
  end
  euiOnlyOnBacking()
end

-- Saved settings from before external UI (Codex gold): installing external UI still brings its theme.
function S.euiSkinOn()
  check(MOCK.eui.fired.LevelingCodex, "the callback ran")
  check(MOCK.ns.C.eui == true, "the external UI theme is on")
  local v = questViewer()
  check(v.euiSkin and v.euiSkin:IsShown(), "the step window has the external UI panel")
  if D() then
    openAt(30, "This Level")
    check(win().euiSkin and win().euiSkin:IsShown(), "the window has the external UI shell")
    win():Hide()
  end
  euiOnlyOnBacking()
end

local function lootSetup()
  MOCK.level=30
  MOCK.lootItems[900001]={name="Old Vest",stats={ITEM_MOD_STRENGTH_SHORT=10}}
  MOCK.lootItems[900002]={name="Better Vest",stats={ITEM_MOD_STRENGTH_SHORT=100}}
  MOCK.equipped[5]="item:900001"
  MOCK.skills={{name="Cloth",rank=1,max=1}}
  MOCK.event("PLAYER_LOGIN")
  slash("loot")
  check(win() and win():IsShown() and questText(win(),"Loot"),"Loot tab opens")
end
function S.lootTab()
  lootSetup()
  for _,name in ipairs({"Compare","Tracked","Profiles","Upgrades"}) do click(win(),name) end
  check(questText(win(),"Level 30") and questText(win(),"Scoring profile") and questText(win(),"0 active"),
    "the Loot header shows level context, scoring profile, and active targets")
  MOCK.equipped[5]="item:900002"
  if MOCK.event("PLAYER_EQUIPMENT_CHANGED",5)==0 then MOCK.event("PLAYER_REGEN_ENABLED") end
  MOCK.advance(0.2)
  local canRead=type(GetItemInfo)=="function" or type(C_Item)=="table" and type(C_Item.GetItemInfo)=="function"
  check(questText(win(),canRead and "Better Vest" or "Item 900002"),"paper doll refreshes after equipment changes")
  click(win(),"Browse Ranged / relic")
  local relic=MOCK.class=="PALADIN" or MOCK.class=="SHAMAN" or MOCK.class=="DRUID"
  check(questText(win(),relic and "Relic upgrades" or "Ranged upgrades"),"paper doll chooses the class's ranged or relic category")
end
function S.lootGraphics()
  lootSetup()
  check(questText(win(),"Armor") and questText(win(),"Accessories") and questText(win(),"Weapons"),
    "equipment slots have visible group headings")
  check(questText(win(),"1 / 17") or questText(win(),"Equipment data unavailable"),
    "the portrait panel summarizes how many equipment slots are filled")
  local chestSlot=findButton(win(),function(label) return label=="Browse Chest" end)
  MOCK.fire(chestSlot,"OnEnter")
  local _,link=GameTooltip:GetItem()
  check(GameTooltip:IsOwned(chestSlot) and link=="item:900001",
    "the equipment slot opens the native item tooltip")
  MOCK.fire(chestSlot,"OnLeave")
  local chestIcon,headIcon,model
  local function walk(f)
    for _,b in ipairs({f:GetChildren()}) do
      if b:IsShown() then
        if b:GetObjectType()=="PlayerModel" then model=b end
        if b.tex and b.tipTitle=="Chest" then chestIcon=b.tex end
        if b.tex and b.tipTitle=="Head" then headIcon=b.tex end
        walk(b)
      end
    end
  end
  walk(win())
  check(not model,"Loot uses a static portrait instead of inheriting player animations")
  local canRead=type(GetItemInfo)=="function" or type(C_Item)=="table" and type(C_Item.GetItemInfo)=="function"
  local chestTexture=canRead and 134400 or MOCK.fileID("Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest")
  check(chestIcon and chestIcon:GetTexture()==chestTexture,"native item IDs and unloaded-item slot art reach the renderer intact")
  check(headIcon and headIcon:GetTexture()==MOCK.fileID("Interface\\PaperDoll\\UI-PaperDoll-Slot-Head"),"complete empty-slot texture paths stay intact")
  local darkBackground
  local function checkSurfaces(frame)
    for _,r in ipairs({frame:GetRegions()}) do
      if r:IsShown() then
        check(not (r._path and r._path:find("loot-paper.tga",1,true)),"Loot backgrounds do not depend on the client's paper texture tint")
        local color=r._color
        if r:GetObjectType()=="Texture" and color then
          local _,anchor=r:GetPoint(1)
          local _,opposite=r:GetPoint(2)
          if anchor==frame and opposite==frame and frame:GetWidth()>=500 and frame:GetHeight()>=420 then
            darkBackground=darkBackground or (color[1]<0.22 and color[2]<0.22 and color[3]<0.22 and color[4]==1)
          end
        end
      end
    end
    for _,child in ipairs({frame:GetChildren()}) do if child:IsShown() then checkSurfaces(child) end end
  end
  checkSurfaces(win())
  check(darkBackground,"Loot uses an opaque dark background even in a bright game scene")
end
function S.lootCardViews()
  lootSetup();click(win(),"Compare")
  click(win(),"Equipped")
  local canRead=type(GetItemInfo)=="function" or type(C_Item)=="table" and type(C_Item.GetItemInfo)=="function"
  local chest=findButton(win(),function(label) return label=="Chest: "..(canRead and "Old Vest" or "Item 900001") end)
  check(chest and chest:GetWidth()<400 and chest:GetHeight()>=44,"equipment is browsed in readable item cards")
  click(win(),"Bags")
  check(questText(win(),"No bag equipment") or questText(win(),"Bag items unavailable"),"an empty or unavailable bag view is explained")
  if C_Container and canRead then
    for i=1,7 do
      local id=900010+i;local name="Bag Vest "..i
      MOCK.lootItems[id]={name=name,stats={ITEM_MOD_STRENGTH_SHORT=1}}
      MOCK.bagItems[#MOCK.bagItems+1]={id=id,name=name,class="Armor",quality=2,level=1}
    end
    MOCK.lootItems[900018]={name="Bag Blade",slot="INVTYPE_WEAPONMAINHAND",classID=2,subclassID=0,stats={ITEM_MOD_STRENGTH_SHORT=1}}
    MOCK.bagItems[#MOCK.bagItems+1]={id=900018,name="Bag Blade",class="Weapon",quality=2,level=1}
    MOCK.event("BAG_UPDATE_DELAYED");MOCK.advance(0.2)
    click(win(),"Next items")
    check(findButton(win(),function(label) return label=="Bag: Bag Vest 7" end),"bag cards remain reachable beyond the first page")
    check(findButton(win(),function(label) return label=="Bag: Bag Blade" end)
      and findButton(win(),function(label) return label=="Bag: Bag Vest 7" end),"different kinds of gear can be compared from the same bag view")
    local filter=LevelingCodexLootInventorySearch
    filter:SetText("Blade");filter:GetScript("OnEnterPressed")(filter)
    check(findButton(win(),function(label) return label=="Bag: Bag Blade" end)
      and not findButton(win(),function(label) return label=="Bag: Bag Vest 7" end),"bag filtering finds items and resets paging")
  end
  click(win(),"Scoring settings")
  local protection=findButton(win(),function(label) return label=="Protection" end)
  check(protection and protection:GetWidth()>240 and protection:GetWidth()<300 and protection:GetHeight()>=80,
    "specialization cards use the wider workspace")
  click(win(),"Arms")
  check(LevelingCodexCharDB.lootProfileKey=="arms","specialization cards apply their selected scoring profile")
  click(win(),"Export profile")
  check(LevelingCodexLootProfileCode and LevelingCodexLootProfileCode:IsShown() and #LevelingCodexLootProfileCode:GetText()>0,"profile sharing remains available")
  click(win(),"Tracked");click(win(),"Browse upgrades")
  check(questText(win(),"Your equipment"),"the empty target page leads directly to equipment browsing")
end
function S.lootDetailCards()
  lootSetup();click(win(),"Compare")
  local edit=LevelingCodexLootItem
  edit:SetText("900002");edit:GetScript("OnEnterPressed")(edit)
  local canRead=type(GetItemInfo)=="function" or type(C_Item)=="table" and type(C_Item.GetItemInfo)=="function"
  click(win(),"Full comparison")
  click(win(),"Upgrades");click(win(),"Browse Chest");click(win(),"Compare")
  check(findButton(win(),function(label) return label=="Back to items" end)
    and questText(win(),canRead and "Better Vest" or "Item 900002"),
    "browsing upgrades preserves the selected comparison and its detail view")
  if canRead then
    check(questText(win(),"Equipped: 10") and questText(win(),"New: 100"),"stat cards show independently known before and after values")
    local strength=findButton(win(),function(label) return label=="Strength comparison" end)
    check(strength and strength:GetWidth()<400,"individual stat comparisons are grouped cards")
    MOCK.fire(strength,"OnEnter")
    check(GameTooltip:IsOwned(strength),"stat comparison details are available on focus or hover")
    MOCK.fire(strength,"OnLeave")
    MOCK.lootItems[900005]={name="Old Sword",slot="INVTYPE_WEAPONMAINHAND",classID=2,subclassID=0,stats={ITEM_MOD_STRENGTH_SHORT=10}}
    MOCK.lootItems[900006]={name="Old Shield",slot="INVTYPE_SHIELD",classID=4,subclassID=6,stats={ITEM_MOD_STRENGTH_SHORT=5}}
    MOCK.lootItems[900007]={name="New Two-hander",slot="INVTYPE_2HWEAPON",classID=2,subclassID=1,stats={ITEM_MOD_STRENGTH_SHORT=20}}
    MOCK.equipped[16],MOCK.equipped[17]="item:900005","item:900006"
    MOCK.event("PLAYER_EQUIPMENT_CHANGED",16);MOCK.advance(0.2)
    edit:SetText("900007");edit:GetScript("OnEnterPressed")(edit)
    check(questText(win(),"Equipped: 15") and questText(win(),"New: 20"),"two-hand comparisons include both replaced items")
    edit:SetText("900002");edit:GetScript("OnEnterPressed")(edit)
    MOCK.lootItems[900004]={name="Unknown Vest",loaded=false}
    MOCK.equipped[5]="item:900004";MOCK.event("PLAYER_EQUIPMENT_CHANGED",5);MOCK.advance(0.2)
  end
  check(questText(win(),"Stat comparison unavailable"),"missing equipment facts never become a zero baseline in a graph")
  edit:SetText("2572");edit:GetScript("OnEnterPressed")(edit)
  click(win(),"Sources")
  check(findButton(win(),function(label) return label=="Source details 1" end),"acquisition details are organized into expandable source cards")
  check(not questText(win(),"Materials:"),"source summaries start compact")
  click(win(),"Source details 1")
  check(questText(win(),"Database reference") or questText(win(),"Client reference"),"source evidence stays visible while browsing")
  check(questText(win(),"Materials:") and questText(win(),"Bolt of Linen Cloth"),"expanding a crafting source reveals its actual materials")
  click(win(),"Source details 1")
  check(not questText(win(),"Materials:"),"source cards can be folded back to their summary")
  click(win(),"Track source 1")
  local target
  for _,t in pairs(LevelingCodexCharDB.lootTargets or {}) do if t.id==2572 and t.sourceID=="craft:2389:2572" then target=t end end
  check(target and questText(win(),"Source tracked"),"source card actions track the selected acquisition route")
end
-- A wrong slot handler, lost filter/page, or an item detail appended below the list
-- would break this player-visible browse/back flow.
function S.lootBrowse()
  lootSetup()
  check(questText(win(),"Your equipment"),"loot starts with the equipment paper doll")
  check(win():GetWidth()>810,"Loot has room for a result list beside the item preview")
  for _,name in ipairs({"Head","Neck","Shoulders","Back","Chest","Wrists","Hands","Waist","Legs","Feet",
    "Ring 1","Ring 2","Trinket 1","Trinket 2","Main hand","Off hand","Ranged / relic"}) do
    check(findButton(win(),function(label) return label=="Browse "..name end),"paper doll slot is clickable: "..name)
  end
  local function clickThroughArtwork(control)
    local _,anchor,_,x,y=control:GetPoint(1)
    for _,child in ipairs({control:GetParent():GetChildren()}) do
      local _,relative,_,cx,cy=child:GetPoint(1)
      if child.tex and child:IsShown() and child:IsMouseEnabled() and relative==anchor
          and cx<x+control:GetWidth() and cx+child:GetWidth()>x
          and cy>y-control:GetHeight() and cy-child:GetHeight()<y then
        check(control:GetFrameLevel()>child:GetFrameLevel(),"the first click on an item icon reaches its row action")
      end
    end
    control:Click()
  end
  local chest=findButton(win(),function(label) return label=="Browse Chest" end)
  local redraws=0
  chest:HookScript("OnHide",function() redraws=redraws+1 end)
  MOCK.leftMouseDown=true
  MOCK.event("PLAYER_REGEN_ENABLED");MOCK.advance(0.3)
  check(redraws==0,"a background refresh does not replace a slot button during a click")
  MOCK.leftMouseDown=false
  clickThroughArtwork(chest)
  check(questText(win(),"Chest upgrades") and questText(win(),"Currently equipped"),"slot opens its results and equipped baseline")
  check(MOCK.scrollOf(win())==0,"the results page opens with its navigation visible")
  local results=0
  for _,control in ipairs(MOCK.buttons(win())) do
    if control.codexLabel and control.codexLabel:find("^Inspect item ") then
      results=results+1
      check(control:GetWidth()>=320,"the results give item names and their acquisition text more room")
    end
  end
  check(results==5,"five items fit on the first results page")
  check(findButton(win(),function(label) return label=="Availability filters" end),"the visible level opens the filters directly")
  check(not findButton(win(),function(label) return label=="Slot Shoulder" or label=="All sources" end),"slot and source lists stay off the results page")
  click(win(),"Change slot")
  local shoulder=findButton(win(),function(label) return label=="Slot Shoulder" end)
  check(shoulder and shoulder:GetWidth()>240 and questText(win(),"Accessories") and questText(win(),"Weapons"),
    "the slot picker groups the slots in full-width columns")
  MOCK.fire(shoulder,"OnEnter")
  check(GameTooltip._lines[1]=="Shoulder","reused slot rows have their own tooltip, not an old equipped item")
  MOCK.fire(shoulder,"OnLeave")
  click(win(),"Back to results")
  click(win(),"Availability filters")
  for _,source in ipairs({"Quest reward","Dungeon drop","Raid drop","Vendor","Crafted","PvP"}) do
    check(findButton(win(),function(label) return label==source end),source.." is visible when filters open")
  end
  local function enabled(source)
    return findButton(win(),function(label) return label==source end).codexOn
  end
  local source=findButton(win(),function(label) return label=="World drop" end)
  check(source.codexOn and enabled("Dungeon drop") and enabled("Reputation"),"sources start enabled")
  clickThroughArtwork(source)
  check(not enabled("World drop") and enabled("Dungeon drop") and enabled("Reputation") and LevelingCodexLootZone:IsShown(),
    "one click excludes a source without altering the others")
  click(win(),"Show results")
  check(questText(win(),"World drop excluded"),"results identify the excluded source")
  click(win(),"Filters")
  click(win(),"Clear sources")
  check(not enabled("Dungeon drop") and not enabled("Reputation"),"clear sources turns off every tile")
  click(win(),"Show results")
  check(questText(win(),"No acquisition sources selected"),"no sources selected has a clear empty state")
  click(win(),"Choose sources")
  click(win(),"Dungeon drop");click(win(),"Reputation")
  check(enabled("Dungeon drop") and enabled("Reputation") and not enabled("Raid drop"),
    "dungeons and reputation can be enabled together")
  click(win(),"All sources")
  click(win(),"Local / active")
  check(findButton(win(),function(label) return label=="Local / active" end).codexOn,"local ordering is explicitly selectable")
  click(win(),"Best upgrade")
  check(findButton(win(),function(label) return label=="Best upgrade" end).codexOn,"upgrade ordering is explicitly selectable")
  local level=LevelingCodexLootPlanLevel
  level:SetText("60")
  click(win(),"Show results")
  check(questText(win(),"Available by level 60"),"Show results accepts a typed plan level without Enter")
  click(win(),"Filters")
  click(win(),"Use my level")
  check(level:GetText()=="30","the player level can be restored directly")
  click(win(),"Raise loot plan level")
  check(level:GetText()=="31","the level stepper adjusts by one")
  click(win(),"Lower loot plan level")
  check(level:GetText()=="30","the level stepper can return to the original level")
  level:SetText("0")
  click(win(),"Show results")
  check(level:IsShown() and questText(win(),"Enter a level from 1 to 60"),"invalid levels leave the filter controls available")
  click(win(),"Use my level")
  click(win(),"Show results")
  check(not (LevelingCodexLootZone and LevelingCodexLootZone:IsShown()),"filter fields are hidden from results")
  click(win(),"Next loot page")
  check(questText(win(),"Page 2 of"),"results can be paged")
  local row
  for _,candidate in ipairs(MOCK.buttons(win())) do
    if candidate.codexLabel and candidate.codexLabel:find("^Inspect item ") and not candidate.codexOn then
      row=candidate;break
    end
  end
  check(row,"a different result can be selected")
  local label=row.codexLabel
  clickThroughArtwork(row)
  local active=findButton(win(),function(candidate) return candidate==label end)
  check(active and active.codexOn and LevelingCodexLootSearch:IsShown() and questText(win(),"Selected item"),
    "a single click changes the selection while keeping the results visible")
  click(win(),"Full comparison")
  click(win(),"Back to results")
  check(questText(win(),"Page 2 of"),"returning from details retains the result page")
  local search=LevelingCodexLootSearch
  search:SetFocus()
  if MOCK.event("BAG_UPDATE_DELAYED")==0 then MOCK.event("PLAYER_REGEN_ENABLED") end
  MOCK.advance(0.2)
  check(search:HasFocus(),"background equipment updates do not interrupt search typing")
  search:SetText("Red Linen Robe");search:GetScript("OnEnterPressed")(search)
  check(findButton(win(),function(label) return label=="Inspect item 2572" end),"chest browsing includes robes")
  check(questText(win(),"Tailoring: Red Linen Robe"),
    "the preview shows the actual recipe source before opening details")
  local itemRow=findButton(win(),function(label) return label=="Inspect item 2572" end)
  local routeRow=findButton(win(),function(label) return label=="Sources for item 2572" end)
  local _,_,_,itemX=itemRow:GetPoint(1)
  local _,_,_,routeX=routeRow:GetPoint(1)
  check(itemX+itemRow:GetWidth()<=routeX,"the source shortcut has its own hit area beside the item")
  check(questText(win(),"Crafted / Tailoring: Red Linen Robe"),"the source stays readable on the item row")
  click(win(),"Sources for item 2572")
  check(questText(win(),"Tailoring: Red Linen Robe") and questText(win(),"Bolt of Linen Cloth")
    and findButton(win(),function(label) return label=="Track source 1" end),"the result's source link opens the route it advertises")
  click(win(),"Back to results")
  check(LevelingCodexLootSearch:GetText()=="Red Linen Robe","returning from a source preserves the item search")
  click(win(),"Inspect item 2572")
  local _,_,_,_,beforeTrack=search:GetPoint(1)
  click(win(),"Track this item")
  local _,_,_,_,afterTrack=search:GetPoint(1)
  check(beforeTrack==afterTrack and questText(win(),"Target tracked"),"tracking feedback keeps the result controls in place")
  click(win(),"Full comparison");click(win(),"Sources")
  check(questText(win(),"Crafted") and questText(win(),"Track route"),"item details retain the recipe and its track action")
  click(win(),"Back to results")
  search:SetText("no-such-item-123");search:GetScript("OnEnterPressed")(search)
  check(questText(win(),"No matching items"),"empty results explain the filters")
  click(win(),"Filters")
  check(LevelingCodexLootZone and LevelingCodexLootZone:IsShown(),"advanced filters can be opened")
  local zone=LevelingCodexLootZone
  zone:SetText("no-such-zone-123")
  click(win(),"Show results")
  check(questText(win(),"No matching items") and questText(win(),"Zone: no-such-zone-123"),"results show the applied filter")
  click(win(),"Filters")
  click(win(),"Reset filters")
  click(win(),"Show results")
  check(LevelingCodexLootSearch:GetText()=="" and not questText(win(),"No matching items"),"reset restores the slot list")
  click(win(),"Back to character")
  click(win(),"Browse Ring 2")
  check(questText(win(),"Ring upgrades") and questText(win(),"Ring 1") and questText(win(),"Ring 2"),"paired slots show both equipped baselines")
  click(win(),"Back to character")
  click(win(),"Browse Off hand")
  check(questText(win(),"Off hand upgrades"),"off hand opens its own equipment category")
end
function S.lootWeaponRoutes()
  MOCK.lootItems[15225]={name="Sequoia Hammer of the Whale",slot="INVTYPE_WEAPONMAINHAND",
    classID=2,subclassID=4,stats={ITEM_MOD_STAMINA_SHORT=6}}
  MOCK.equipped[16]="item:15225:0:0:0:0:0:-15"
  lootSetup()
  click(win(),"Browse Main hand")
  check(questText(win(),"One-hand + shield"),"Protection starts with a shield-compatible main-hand list")
  local edit=LevelingCodexLootSearch
  edit:SetText("Whirlwind Warhammer");edit:GetScript("OnEnterPressed")(edit)
  check(questText(win(),"No matching items"),"Protection does not include two-handers by default")
  click(win(),"Weapon filters")
  click(win(),"Two-hand")
  click(win(),"Maces")
  click(win(),"Show results")
  check(questText(win(),"Whirlwind Warhammer") and questText(win(),"The Islander"),
    "explicit weapon types show the reward and the beginning of its chain")
  check(findButton(win(),function(label) return label=="Inspect item 6976" end),
    "the two-handed mace result is selectable")
  if type(GetItemInfo)=="function" or (C_Item and C_Item.GetItemInfo) then
    check(questText(win(),"+18.7 DPS"),"the preview shows verified weapon DPS even with uncertain item effects")
  end
  check(questText(win(),"prevents a shield"),"the preview explains the shield trade-off")
  if C_Map and C_Map.SetUserWaypoint then
    click(win(),"Map preview pickup")
    check(MOCK.userWaypoint and MOCK.userWaypoint.uiMapID==1453 and LevelingCodexLootSearch:IsShown(),
      "the preview pins the next pickup without leaving the weapon list")
    click(win(),"Clear loot map target")
  end
  click(win(),"Sources for item 6976")
  check(questText(win(),"Whirlwind Weapon") and questText(win(),"The Summoning")
    and questText(win(),"The Islander") and questText(win(),"Bath'rah the Windwatcher"),
    "the source view shows the named chain and its reward contact")
  if C_Map and C_Map.SetUserWaypoint then
    click(win(),"Map quest 1718")
    check(MOCK.userWaypoint and MOCK.userWaypoint.uiMapID==1453,"the chain-start pin leads to the Alliance starter")
    click(win(),"Clear loot map target")
  end
  MOCK.questDone[1718]=true
  click(win(),"Back to results")
  if IsQuestFlaggedCompleted or C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    check(questText(win(),"Next quest") and questText(win(),"The Affray"),"a completed chain starter advances the preview")
  else
    check(questText(win(),"The Islander"),"the route keeps its known starter when completion cannot be read")
  end
  click(win(),"Weapon filters")
  click(win(),"Use profile default")
  click(win(),"Axes")
  click(win(),"Show results")
  edit:SetText("Gutterblade");edit:GetScript("OnEnterPressed")(edit)
  check(questText(win(),"Raene Wolfrunner"),"the one-hand axe shows the start of the Raene chain")
  click(win(),"Sources for item 17046")
  check(questText(win(),"Reward quest pickup at Krolg") and questText(win(),"Turn in to Raene Wolfrunner"),
    "the reward step distinguishes pickup from turn-in")
end
function S.lootLevelAvailability()
  lootSetup()
  MOCK.level=31
  MOCK.event("PLAYER_LEVEL_UP",31);MOCK.advance(0.2)
  click(win(),"Browse Main hand")
  check(questText(win(),"Available by level 31"),"the list identifies the level used for source availability")
  local edit=LevelingCodexLootSearch
  for _,id in ipairs({"289294","274383","20003","276338"}) do
    edit:SetText(id);edit:GetScript("OnEnterPressed")(edit)
    check(questText(win(),"No matching items"),"unverified weapon "..id.." is hidden even when searched directly")
  end
  edit:SetText("6220");edit:GetScript("OnEnterPressed")(edit)
  check(findButton(win(),function(label) return label=="Inspect item 6220" end),
    "level-appropriate dungeon weapons remain discoverable")
  edit:SetText("289294");edit:GetScript("OnEnterPressed")(edit)
  click(win(),"Filters");click(win(),"Show unverified sources");click(win(),"Show results")
  check(findButton(win(),function(label) return label=="Inspect item 289294" end)
    and questText(win(),"Source unverified"),"the explicit discovery filter labels unverified weapons")
end
function S.lootCompareVerdicts()
  lootSetup(); click(win(),"Compare")
  local edit=_G.LevelingCodexLootItem
  check(edit,"item link input exists")
  edit:SetText("900002"); edit:GetScript("OnEnterPressed")(edit)
  local canRead=type(GetItemInfo)=="function" or type(C_Item)=="table" and type(C_Item.GetItemInfo)=="function"
  check(questText(win(),canRead and "Estimated gear score" or "Needs review"),"actual uncataloged item compares or explains missing APIs: "..MOCK.textUnder(win()))
  click(win(),"Equipped")
  check(LevelingCodexLootItem:IsShown(),"item input stays visible after comparing")
  click(win(),"Chest: "..(canRead and "Old Vest" or "Item 900001"))
  check(findButton(win(),function(label) return label=="Chest: "..(canRead and "Old Vest" or "Item 900001") end)
    and questText(win(),"Equipped baseline") and questText(win(),"Selected item"),
    "one click compares another item beside the equipment picker")
  click(win(),"Planning")
  check(LevelingCodexLootPreviewLevel:IsShown(),"planning controls are still reachable")
  click(win(),"Use live character")
  check(not LevelingCodexLootPreviewLevel:IsShown(),"live mode closes the planning controls")
  edit:SetText("900002");edit:GetScript("OnEnterPressed")(edit)
  click(win(),"Track this item"); click(win(),"Tracked")
  check(findButton(win(),function(label) return label:find(" - tracked",1,true) and (label:find("Better Vest",1,true) or label:find("900002",1,true)) end),"tracked item is listed")
end
function S.lootInputBounds()
  lootSetup(); click(win(),"Compare")
  local edit=_G.LevelingCodexLootItem
  check(edit,"item link input exists")
  edit:SetText(string.rep("x",2049)); edit:GetScript("OnEnterPressed")(edit)
  check(questText(win(),"valid item"),"invalid item input has a clear message")
end
function S.lootTracker()
  S.lootCompareVerdicts();MOCK.advance(0.5)
  check(_G.LevelingCodexLootTracker and LevelingCodexLootTracker:IsShown(),"tracked loot opens the optional tracker")
  check(LevelingCodexLootTracker:GetHeight()<160,"a single target keeps the floating tracker compact")
  check(questText(LevelingCodexLootTracker,"Source unverified"),"a target without verified sources explains what's missing")
  check(not findButton(LevelingCodexLootTracker,function(label) return label=="Clear loot map" end),"a map clear action only appears for an active loot waypoint")
  local target=findButton(LevelingCodexLootTracker,function(label) return label:find("^Loot target ") end)
  check(target,"the tracked item has a hover target")
  MOCK.fire(target,"OnEnter")
  local _,link=GameTooltip:GetItem()
  check(GameTooltip:IsOwned(target) and link=="item:900002","hovering a tracked item opens its native stat tooltip")
  MOCK.fire(target,"OnLeave")
  check(not GameTooltip:IsShown(),"the tracker closes its own tooltip on leave")
  slash("loot");click(win(),"Compare")
  local edit=LevelingCodexLootItem
  edit:SetText("2572");edit:GetScript("OnEnterPressed")(edit)
  click(win(),"Track this item");MOCK.advance(0.5)
  check(questText(LevelingCodexLootTracker,"Tailoring: Red Linen Robe"),"an item-only target shows a known recipe source")
  click(LevelingCodexLootTracker,"Loot target Red Linen Robe")
  check(questText(win(),"Bolt of Linen Cloth"),"the tracker opens the route it displays")
  edit:SetText("276339");edit:GetScript("OnEnterPressed")(edit)
  click(win(),"Track this item");MOCK.advance(0.5)
  check(questText(LevelingCodexLootTracker,"Prey and Predator") and questText(LevelingCodexLootTracker,"Mount Hyjal"),
    "the tracker shows the quest and zone even when the source is above the player's level")
  click(win(),"Tracked")
  check(questText(win(),"Prey and Predator") and questText(win(),"Mount Hyjal") and questText(win(),"Level 54"),
    "the journal card shows the target's destination and required level")
  check(findButton(win(),function(label) return label=="Map Cured Staghide Leggings" end),
    "item-only tracking can expose the known source waypoint")
  check(not findButton(win(),function(label) return label=="Map Red Linen Robe" end),
    "a craft route without coordinates has no map action")
  if C_Map and C_Map.SetUserWaypoint then
    click(win(),"Map Cured Staghide Leggings")
    check(MOCK.userWaypoint and MOCK.userWaypoint.uiMapID==2482,"the journal pins the source shown on the card")
    check(not OpenWorldMap or MOCK.openedMap==2482,"mouse users still get the destination map")
    click(win(),"Clear loot map target")
    check(not MOCK.userWaypoint,"clearing the pin leaves the tracked item available")
    if OpenWorldMap and InputUtil then
      MOCK.blockControllerMap,MOCK.gamepadUI,MOCK.openedMap=true,true,nil
      click(LevelingCodexLootTracker,"Map loot target Cured Staghide Leggings")
      check(not chatHas("SetPreferredGamepadInteractTarget") and not MOCK.openedMap,
        "the tracked reward does not open Blizzard's protected controller map")
      check(MOCK.userWaypoint and MOCK.userWaypoint.uiMapID==2482 and MOCK.superTracked,
        "the controller action still sets and tracks the reward waypoint")
      check(chatHas("Open your world map"),"the tracker tells controller users how to see the pin")
      click(LevelingCodexLootTracker,"Clear loot map")
      MOCK.blockControllerMap,MOCK.gamepadUI=nil,nil
    end
  end
  click(LevelingCodexLootTracker,"Loot target Cured Staghide Leggings")
  check(questText(win(),"Starts with Kala'th") and questText(win(),"Source requires level 54"),
    "the shown quest route opens with its giver and availability")
  check(not MOCK.questRewarded,"loot guidance never selects a reward")
end
function S.lootTooltips()
  lootSetup()
  GameTooltip:SetHyperlink("item:900002")
  check(#(GameTooltip._lines or {})==1,"Codex adds one compact score line with no extra advice")
  local count=0
  for _,line in ipairs(GameTooltip._lines or {}) do if line:find("Codex:",1,true) then count=count+1 end end
  check(count==1,"one annotation even with setter and item callbacks ("..count..")")
  GameTooltip:SetHyperlink("item:900001")
  count=0
  for _,line in ipairs(GameTooltip._lines or {}) do if line:find("Codex:",1,true) then count=count+1 end end
  check(count==1,"reused tooltip has one current annotation")
  GameTooltip:SetHyperlink("item:2572")
  check(#(GameTooltip._lines or {})==1 and GameTooltip._lines[1]:find("Rank #",1,true),
    "a verified catalog comparison has rank and score on one line")
  click(win(),"Scoring settings")
  click(win(),"Show other profile ranks")
  GameTooltip:SetHyperlink("item:2572")
  check(#GameTooltip._lines>1 and GameTooltip._lines[2]:find("Arms:",1,true),"other profile ranks are opt-in")
  click(win(),"Show other profile ranks")
  GameTooltip:SetHyperlink("item:2572")
  check(#GameTooltip._lines==1,"the tooltip returns to one line when other profiles are disabled")
  check(not MOCK.questRewarded and #(MOCK.sold or {})==0,"tooltip guidance is read-only")
end
function S.lootTooltipStaysOpen()
  lootSetup()
  for _,tip in ipairs({GameTooltip,ItemRefTooltip}) do
    tip:SetOwner(UIParent,"ANCHOR_RIGHT")
    tip:SetHyperlink("item:900002")
    tip:AddLine("Shared tooltip detail")
    MOCK.advance(0.3)
    check(tip:IsShown(),tip:GetName().." remains open after delayed loot-data refresh")
    for _,event in ipairs({"GET_ITEM_INFO_RECEIVED","BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","PLAYER_REGEN_ENABLED"}) do
      MOCK.event(event,900002,true)
      MOCK.advance(0.2)
      check(tip:IsShown() and tip:IsOwned(UIParent),tip:GetName().." keeps its visibility and owner after "..event)
      local callback=tip:GetScript("OnTooltipSetItem")
      if callback then callback(tip) end
      local ours,shared=0,0
      for _,line in ipairs(tip._lines or {}) do
        if line:find("Codex:",1,true) then ours=ours+1 end
        if line=="Shared tooltip detail" then shared=shared+1 end
      end
      check(ours==1 and shared==1,"refresh callbacks preserve shared tooltip content without duplicate advice")
    end
    tip:Hide();MOCK.advance(0.3)
    check(not tip:IsShown(),"a player-closed tooltip stays closed")
    tip:SetHyperlink("item:900001")
    check(tip:IsShown(),"the next item tooltip can open normally")
    tip:Hide()
  end
end
function S.lootPad()
  if not GamepadMode then return end
  MOCK.gamepadUI=true
  lootSetup();click(win(),"Compare");MOCK.advance(0.6)
  check(LevelingCodexLootItem and not LevelingCodexLootItem.padSkip,"controller can focus the item input")
  MOCK.padRefuse=true;win():Hide();slash("loot");MOCK.advance(0.6)
  check(LevelingCodexPadFocus and LevelingCodexPadFocus:IsShown(),"fallback controller can navigate Loot")
  MOCK.combat=true;MOCK.event("PLAYER_REGEN_DISABLED");MOCK.combat=false;MOCK.event("PLAYER_REGEN_ENABLED")
  MOCK.advance(0.6)
  check(not MOCK.forbidden,"loot controller recovery is safe")
end
function S.lootCacheLate()
  lootSetup();click(win(),"Compare")
  MOCK.lootItems[900003]={name="Late Vest",loaded=false,stats={ITEM_MOD_STRENGTH_SHORT=50}}
  local edit=LevelingCodexLootItem
  edit:SetText("900003");edit:GetScript("OnEnterPressed")(edit)
  edit:SetText("900002");edit:GetScript("OnEnterPressed")(edit)
  MOCK.lootItems[900003].loaded=true;MOCK.event("GET_ITEM_INFO_RECEIVED",900003,true);MOCK.advance(1)
  local canRead=type(GetItemInfo)=="function" or type(C_Item)=="table" and type(C_Item.GetItemInfo)=="function"
  check(questText(win(),canRead and "Better Vest" or "Item 900002"),"late response does not replace the selected candidate")
end

-- Journey: the adventure journal records the start, new zones, a trail, levels, quests, deaths,
-- dungeons, bosses and companions, each as an ASCII line of the story.
local function journeyHas(kind, pat)
  local j = LevelingCodexCharDB.journey
  for _, e in ipairs(j and j.events or {}) do
    if (not kind or e.k == kind) and (not pat or e.s:find(pat, 1, true)) then return e end
  end
end

function S.journeyRecord()
  MOCK.mapInfo = STATS_MAPS
  LevelingCodexCharDB = { journey = "broken" } -- a broken saved shape starts a fresh journal
  S.login()
  MOCK.advance(3)
  local j = LevelingCodexCharDB.journey
  check(type(j) == "table" and j.version == 1, "a broken journal starts fresh")
  check(journeyHas("start", "begins in"), "the first zone starts the journey")
  if not MOCK.minimal then
    check(j.zones[1429], "Elwynn Forest is a land you have explored")
    local before = j.points
    for i = 1, 6 do MOCK.questX = 48 + i * 2; MOCK.advance(2.1) end
    check(j.points > before and j.trail[1429] and #j.trail[1429] >= 1, "walking leaves a trail (" .. j.points .. ")")
    MOCK.questX = 48
  end
  MOCK.level = MOCK.level + 1
  MOCK.event("PLAYER_LEVEL_UP", MOCK.level)
  local up = journeyHas("level")
  check(up and up.l == MOCK.level and up.s:find(tostring(MOCK.level), 1, true), "a level-up is a moment")
  -- the minimal client knows none of the optional events (turn-ins, deaths, dungeons)
  if MOCK.minimal then return end
  MOCK.event("QUEST_TURNED_IN", 166, 100, 0)
  check(journeyHas(nil, "Conquered Edwin VanCleef and saved Westfall"), "a famous turn-in has its own line")
  MOCK.event("QUEST_TURNED_IN", 783, 100, 0)
  local q = journeyHas(nil, nil)
  for _, e in ipairs(j.events) do if e.q == 783 then q = e end end
  check(q and q.q == 783 and #q.s > 10 and q.d and q.d:find("^Quest: "), "a turn-in reads as a line of the story")
  MOCK.event("PLAYER_DEAD")
  check(journeyHas("death") and j.deaths == 1, "a death is remembered")
  MOCK.party, MOCK.partyMembers = true, { { name = "Bo", level = 6, class = "MAGE" } }
  MOCK.advance(6)
  check(journeyHas("pal", "Bo") and j.pals.Bo and j.pals.Bo.class == "MAGE", "a party member becomes a companion")
  MOCK.instanceName, MOCK.instanceID = "The Deadmines", 36
  MOCK.event("PLAYER_ENTERING_WORLD", false, false)
  check(journeyHas("dungeon", "The Deadmines") and journeyHas("dungeon", "with Bo"), "a dungeon run names who came")
  MOCK.event("ENCOUNTER_END", 1, "Edwin VanCleef", 1, 5, 1)
  MOCK.event("BOSS_KILL", 1, "Edwin VanCleef")
  local bosses = 0
  for _, e in ipairs(j.events) do if e.k == "boss" then bosses = bosses + 1 end end
  check(bosses == 1 and journeyHas("boss", "saved Westfall"), "a boss is written once, a famous one in its own words")
  MOCK.instanceName, MOCK.instanceID = nil, nil
  for _, e in ipairs(j.events) do
    check(not e.s:find("[^\32-\126]") and not e.s:find("%%"), "moments are ASCII with no template left: " .. e.s)
  end
end

-- Journey: the tab draws the cover, the road, the map, the story and companions; filters and the
-- world map trail.
function S.journeyTab()
  MOCK.mapInfo = STATS_MAPS
  S.login()
  MOCK.advance(3)
  for i = 1, 4 do MOCK.questX = 40 + i * 3; MOCK.advance(2.1) end
  MOCK.event("PLAYER_DEAD")
  MOCK.level = MOCK.level + 1
  MOCK.event("PLAYER_LEVEL_UP", MOCK.level)
  MOCK.event("QUEST_TURNED_IN", 176, 100, 0)
  slash("")
  click(win(), "Journey")
  local pages = {
    { nil, "THE JOURNEY OF", "THE ROAD TO 60", "WHERE YOU ARE", "FELLOW ADVENTURERS",
      "CHAPTER " .. MOCK.ns.journey.roman(MOCK.level), "Level " .. MOCK.level },
    { "Map", "THE MAP", "YOUR JOURNAL" },
    { "Companions", "FELLOW ADVENTURERS", "THE JOURNEY OF" },
    { "Story", "THE STORY SO FAR", "CHAPTER " .. MOCK.ns.journey.roman(MOCK.level) },
  }
  for _, p in ipairs(pages) do
    if p[1] then click(win(), p[1]) end
    for i = 2, #p do check(questText(win(), p[i]), "the Journey " .. (p[1] or "Overview") .. " page has " .. p[i]) end
  end
  check(not questText(win(), "THE ROAD TO 60"), "the Story page leaves the overview out")
  if MOCK.minimal then return end -- no optional events, no map positions
  check(questText(win(), "Brought down Hogger"), "the story has the turn-in")
  click(win(), "Deaths")
  check(not questText(win(), "Brought down Hogger") and questText(win(), "Elwynn Forest"),
    "the Deaths filter leaves quests out")
  click(win(), "All")
  local moment = findButton(win(), function(l) return l:find("^Moment ") end)
  check(MOCK.minimal or moment, "a moment with a spot can be shown on the map")
  if moment then moment:Click() end
  check(MOCK.minimal or findButton(win(), function(l) return l:find("^Pin ") end), "moments are pinned on the map")
  check(questText(win(), "LANDS EXPLORED"), "a moment opens the Map page")
  if not MOCK.minimal then
    MOCK.worldMapID = 1429
    WorldMapFrame:Show()
    MOCK.advance(2.1)
    local trail = _G.LevelingCodexJourneyTrail
    local shown = 0
    for _, r in ipairs(trail and { trail:GetRegions() } or {}) do if r:IsShown() then shown = shown + 1 end end
    check(trail and trail:IsShown() and shown > 2, "the world map shows the trail (" .. shown .. ")")
    click(win(), "Show my trail on the world map")
    MOCK.advance(2.1)
    check(not trail:IsShown(), "the setting hides the world map trail")
    WorldMapFrame:Hide()
  end
  click(win(), "Erase the journal")
  click(win(), "Click again to erase")
  check(#LevelingCodexCharDB.journey.events == 0, "two clicks erase the journal")
end

-- Journey: past the point limit the busiest zone's trail is thinned, never cut off.
function S.journeyThin()
  local p = {}
  for i = 1, 60 do p[#p + 1] = string.format("%03d%03d", i * 10, 500) end
  local run = table.concat(p)
  local runs = {}
  for i = 1, 4 do runs[i] = { l = 5, p = run } end
  LevelingCodexCharDB = { journey = { version = 1, started = 0, zones = {}, order = {}, trail = { [1429] = runs },
    points = 240, walked = 0, events = {}, pals = {}, deaths = 0 } }
  local journey = LevelingCodexCharDB.journey
  S.login()
  if MOCK.minimal then return end
  -- a lower cap (the module's own table), so a few samples cross it
  local J = MOCK.ns.journey
  J.MAX_POINTS = 200
  MOCK.questX = 20; MOCK.advance(2.1)
  MOCK.questX = 30; MOCK.advance(2.1)
  check(journey.points <= 200, "the trail is thinned under the cap (" .. tostring(journey.points) .. ")")
  check(#journey.trail[1429] >= 4, "every run is kept")
end
