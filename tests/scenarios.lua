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
  for _, child in ipairs({ root:GetRegions() }) do
    if child:IsShown() and child._text and child._text:find(value, 1, true) then return true end
  end
  for _, child in ipairs({ root:GetChildren() }) do
    if child:IsShown() and questText(child, value) then return true end
  end
  return false
end

local function questQueue(name)
  local button = findButton(win(), function(label)
    return label:match("^" .. name .. " %(%d+%)$")
  end)
  check(button, "quest view is available: " .. name)
  button:Click()
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
  check(questText(win(), "No route covers level 31"), "level 31 is beyond milestone coverage")
  click(win(), "Wetlands")
  check(questText(questViewer(), "Wetlands"), "the Wetlands section is listed")
  click(win(), "Elwynn Forest")
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
  click(win(), "Resume active quest")
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
  click(win(), "Resume active quest")
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
    for _, b in ipairs(MOCK.buttons(win())) do
      if b:IsVisible() and b.tipTitle == "Complete - " .. title then b:Click(); return end
    end
    error("No route objective for " .. title)
  end
  preview("Blackrock Blockade")
  local frame = questViewer()
  check(questText(frame, "Blackrock Supplies 4/10"), "the primary objective keeps its live progress")
  check(questText(frame, "Also on this loop") and questText(frame, "Battleworn Axe 3/10"),
    "the blockade step shows the overlapping axe objective")
  MOCK.questLog[1].objectives[1].text = "Battleworn Axe 5/10"
  MOCK.event("QUEST_LOG_UPDATE")
  check(questText(frame, "Battleworn Axe 5/10"), "the overlapping objective updates live")
  MOCK.questLog[1].isComplete = true
  MOCK.event("QUEST_LOG_UPDATE")
  check(not questText(frame, "Also on this loop") and questText(frame, "Blackrock Supplies 4/10"),
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
  check(findButton(win(), function(l) return l == "Westfall" end), "the shared Westfall section remains available")
end

function S.questLayout()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 19, 1433
  MOCK.questLog = { { questID = 3741, isComplete = true }, { questID = 246 } }
  S.login()
  slash("quests")
  local opener = findButton(win(), function(label) return label == "Show step window" end)
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
  check(questText(win(), "Accept - Hilary's Necklace"), "finished steps can be shown")
  check(not questText(win(), "The Defias Brotherhood"), "route shows only the selected section")
  checkBounds()
  questQueue("Ready to turn in")
  check(questText(win(), "Hilary's Necklace"), "ready view lists the turn-in")
  checkBounds()
  questQueue("Missed quests")
  check(questText(win(), "Missed quests"), "missed view has its own heading")
  checkBounds()
  click(win(), "Westfall")
  check(questText(win(), "The Defias Brotherhood"), "switching sections returns to its route")
  checkBounds()
end

function S.questBind()
  MOCK.race, MOCK.level, MOCK.questMap, MOCK.bind = "Skyborne", 18, 1433, "Goldshire"
  S.login()
  local frame = questViewer()
  check(questText(frame, "Flight path - Lakeshire, Redridge"), "Lakeshire starts at its flight path")
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
  check(not questText(win(), "Bind hearthstone"), "skipped bind steps leave the route list")
  local hearth
  for _, button in ipairs(MOCK.buttons(win())) do
    if button:IsVisible() and button.tipTitle == "Return to Lakeshire" then hearth = button; break end
  end
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
  click(win(), "Take the guide's flights and binds")
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
  check(questText(frame, "Bind hearthstone"), "the bind step follows")
  MOCK.event("GOSSIP_SHOW")
  MOCK.event("CONFIRM_BINDER", "Lakeshire")
  check(MOCK.gossipOption == nil and not MOCK.binderConfirmed, "no binding away from the step's inn")
  MOCK.questX, MOCK.questY = 22.1, 44.6
  MOCK.event("GOSSIP_SHOW")
  check(MOCK.gossipOption == 3, "the innkeeper's bind option is picked at the step's inn")
  MOCK.event("CONFIRM_BINDER", "Goldshire")
  check(not MOCK.binderConfirmed, "a different town's bind is never confirmed")
  MOCK.event("CONFIRM_BINDER", "Lakeshire")
  check(MOCK.binderConfirmed and MOCK.popupHidden == "CONFIRM_BINDER", "the bind is confirmed and its popup closed")
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

function S.questCleanup()
  MOCK.level = 20
  MOCK.questLog = { { questID = 783, title = "A Threat Within", level = 1 },
    { questID = 999, title = "Stray Errand", level = 19 },
    { questID = 7, title = "Kobold Camp Cleanup", level = 2, isComplete = true } }
  S.login()
  slash("quests")
  click(win(), "Guide library")
  check(questText(win(), "Quest log cleanup"), "the library lists quests to clean up")
  check(questText(win(), "Stray Errand\nNot in your guides") and questText(win(), "A Threat Within\nGrey"),
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
end

function S.questMobTarget()
  MOCK.questDone[783], MOCK.questDone[5261], MOCK.questDone[33] = true, true, true
  local vermin = { text = "Kobold Vermin 4/10", numFulfilled = 4, numRequired = 10 }
  MOCK.questLog = { { questID = 7, objectives = { vermin } } }
  S.login()
  local target = _G.LevelingCodexQuestTarget
  check(target and target:IsShown() and target:GetAttribute("macrotext") == "/targetexact Kobold Vermin",
    "an objective step targets the creatures it needs")
  hover(target)
  MOCK.ns.questMobs[7] = { "Kobold Vermin", "Kobold Worker" }
  MOCK.event("QUEST_LOG_UPDATE")
  check(target:GetAttribute("macrotext") == "/targetexact Kobold Worker\n/targetexact Kobold Vermin",
    "the first creature listed goes last, so it wins when both are near")
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
  click(win(), "Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Ghoul Ribs 6/7"), "resume the final Duskwood quest")
  MOCK.questDone[133], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 133)
  check(questText(frame, "Reach level 26 for Wetlands"), "an underleveled handoff shows the catch-up step")
  MOCK.level = 26
  MOCK.event("PLAYER_LEVEL_UP", 26)
  check(questText(frame, "return to Darkshire"), "at level 26 the route leads back to the flight path")
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
  click(win(), "Resume active quest")
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
  click(win(), "Lakeshire")
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

local function routeHas(text)
  click(win(), "Route")
  if findButton(win(), function(l) return l == "Show all steps" end) then click(win(), "Show all steps") end
  return questText(win(), text)
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
  local missed = findButton(win(), function(l) return l:match("^Missed quests %((%d+)%)$") end)
  check(missed, "missed view exists")
  missed:Click()
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

function S.questWetlands()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 28, 1437
  S.login()
  local frame = questViewer()
  check((questText(frame, "Wetlands") and questText(frame, "Levels 26-30")), "a level 28 in the Wetlands follows the Wetlands section")
  check(questText(frame, "Accept - Razormaw Needling"), "the trip there is skipped once you are in the Wetlands")

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
  click(win(), "Resume active quest")
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
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 28, 1431
  S.login()
  local frame = questViewer()
  check(questText(frame, "Fly - Stormwind, Elwynn"), "from Duskwood the Wetlands section starts with the way there")
  click(frame, "Next")
  check(questText(frame, "The Doomed Fleet"), "Bishop Farthing's pickup in Stormwind follows the flight")
  click(frame, "Next")
  check(questText(frame, "Deeprun Tram"), "the tram step follows the Stormwind pickup")
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

function S.questWetlandsEnd()
  -- The Wetlands section ends in Auberdine: Nord'el for Thundris after the Stormwind turn-ins.
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 30, 1439
  MOCK.questLog = { { questID = 98209, isComplete = true } }
  S.login()
  slash("quests")
  click(win(), "Resume active quest")
  local frame = questViewer()
  check(questText(frame, "Turn in - Bloom of the Heavens"), "resume at the final Wetlands turn-in")
  check(questText(frame, "Last step in this guide"), "the final turn-in identifies itself as the last step")
  MOCK.questDone[98209], MOCK.questLog = true, {}
  MOCK.event("QUEST_TURNED_IN", 98209)
  check(frame:IsShown() and questText(frame, "End of the leveling guide"), "the guide shows its ending after the turn-in")
  check(not findButton(frame, function(label) return label == "Next" end), "the ending has no dead Next button")
  click(frame, "Hide")
  click(win(), "Show step window")
  check(frame:IsShown() and questText(frame, "End of the leveling guide"), "the end card can be reopened")
  click(frame, "Back")
  check(questText(frame, "Turn in - Bloom of the Heavens"), "Back can review the final step")
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
    check(findButton(win(), function(l) return l == "Westfall" end), name .. " joins the shared route at Westfall")
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
  click(win(), "Warrior: Test Chain")
  check(questText(questViewer(), "Accept - First class quest"), "selecting the side section follows its quest")
  click(questViewer(), "Next")
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "skipping the chain returns to leveling")
  click(win(), "Warrior: Test Chain")
  check(questText(questViewer(), "Accept - First class quest"), "reopening a class guide restores unfinished quests")
  click(win(), "Return to leveling")
  check(questText(questViewer(), "Accept - Report to Gryan Stoutmantle"), "you can leave a class guide early")
  click(win(), "Warrior: Test Chain")
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
  click(win(), "Guide library")
  click(win(), "Test Dungeon")
  check(questText(win(), "BEFORE YOU GO") and questText(win(), "INSIDE") and questText(win(), "AFTER THE RUN"), "dungeon stages are shown")
  check(questText(win(), "Requires level 15"), "shows the actual level gate")
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
  click(win(), "Return to leveling")
  check(questText(questViewer(), "Report to Gryan Stoutmantle"), "return restores the leveling step")
  click(win(), "Guide library")
  click(win(), "Track Dungeon Test Pickup")
  check(questText(questViewer(), "Tracking") and questText(questViewer(), "Dungeon Test Pickup"), "pinned quests stay visible across guides")
  local search = _G.LevelingCodexQuestSearch
  check(search and search:IsShown(), "search field is available")
  search:SetText("Dungeon Test Inside")
  MOCK.fire(search, "OnEnterPressed")
  check(questText(win(), "Dungeon Test Inside"), "search finds a quest inside a detour")
  MOCK.questLog = {}
  MOCK.event("QUEST_TURNED_IN", 999011)
  check(not questText(questViewer(), "Tracking"), "completed quests disappear from the pinned list")
end

function S.questDungeonContent()
  MOCK.level, MOCK.questMap = 15, 1455
  MOCK.questDone[96392], MOCK.questDone[96390], MOCK.questDone[96391] = true, true, true
  S.login()
  slash("quests")
  click(win(), "Guide library")
  click(win(), "Hall of Thanes")
  check(questText(win(), "Old Ironforge Incursion") and questText(win(), "The Treaty of Understanding"),
    "Hall of Thanes has both outdoor unlock and inside starter")
  click(win(), "Follow this guide")
  check(questText(questViewer(), "Accept - Old Ironforge Incursion"), "completed map prep leads directly to the dungeon pickup")
  click(questViewer(), "Return to leveling")
  MOCK.instanceName, MOCK.instanceID = "The Hall of Thanes", 3065
  MOCK.event("PLAYER_ENTERING_WORLD")
  click(win(), "Follow this guide")
  check(questText(questViewer(), "Accept - An Ancient Grudge"), "reopening inside starts with the first obtainable inside quest")
  click(questViewer(), "Return to leveling")
  click(win(), "Guide library")
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
  click(win(), "Alternate First")
  check(questText(questViewer(), "Accept - Shared Alternate Pickup"), "the first alternate offers the quest")
  click(questViewer(), "Next")
  click(win(), "Alternate Second")
  check(questText(questViewer(), "Accept - Shared Alternate Pickup"), "manual skips stay in their own alternate")
  MOCK.questDone[999020] = true
  MOCK.event("QUEST_TURNED_IN", 999020)
  check(not questText(questViewer(), "Accept - Shared Alternate Pickup"), "game completion is shared across alternates")
end

function S.questPinCapacity()
  MOCK.level, MOCK.questMap = 13, 1436
  for i = 1, 4 do MOCK.questLog[i] = { questID = 999030 + i, title = "Pin test " .. i } end
  S.login()
  slash("quests")
  click(win(), "Guide library")
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
  click(win(), "Resume active quest")
  check(questText(questViewer(), "Complete - Local Active Quest"), "the local active quest takes precedence")
  click(win(), "Guide library")
  click(win(), "Show Earlier Active Quest")
  check(questText(questViewer(), "Complete - Earlier Active Quest") and questText(questViewer(), "Widgets: 1/20"),
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
  check(findButton(win(), function(l) return l == "Hunter: Taming in Dun Morogh" end), "Dwarves get their tame guide")
  check(not findButton(win(), function(l) return l == "Hunter: Taming in Elwynn" end), "Human taming is race filtered")
  check(not questText(win(), "Warrior: Defensive Stance"), "another class's guides are hidden")
  click(win(), "Hunter: Taming in Dun Morogh")
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
  check(findButton(win(), function(l) return l == "Shaman: Water Totem" end), "Tauren Shamans get the Horde Water Totem guide")
  click(win(), "Shaman: Water Totem")
  check(questText(questViewer(), "Call of Water"), "the Water Totem guide opens at its first step")
  MOCK.faction = nil
end

function S.questShamanGuides()
  MOCK.race, MOCK.level, MOCK.questMap = "Dwarf", 30, 1455
  S.login()
  slash("quests")
  click(win(), "Shaman: Air Totem")
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
  check(not questText(win(), "Stolen Blasting Powder"), "the entire powder chain is hidden without the keg")
  MOCK.bags[268548] = 1
  MOCK.event("BAG_UPDATE_DELAYED")
  check(questText(win(), "Stolen Blasting Powder"), "looting the keg reveals the chain")
  MOCK.bags[268548] = 0
  MOCK.questDone[95213] = true
  MOCK.event("QUEST_TURNED_IN", 95213)
  check(questText(win(), "Complete - Stolen Blasting Powder"), "the follow-up stays visible after turning in the keg")
end

function S.questWestfall()
  MOCK.race, MOCK.level, MOCK.questMap = "Skyborne", 13, 1436
  S.login()
  check(questText(questViewer(), "Westfall"), "Skyborne can enter the shared Westfall route")
  slash("quests")
  check(questText(win(), "The Defias Brotherhood"), "solo Defias lead-in is visible with dungeons off")
  check(not questText(win(), "Dungeon - The Deadmines"), "dungeon run is hidden by default")
  click(win(), "Settings")
  click(win(), "Plan every dungeon run")
  click(win(), "Quests")
  check(questText(win(), "Dungeon - The Deadmines"), "dungeon setting reveals the Deadmines run")
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
  click(win(), "Test grey route")
  local frame = questViewer()
  check(questText(frame, "Accept - Grey Prerequisite"), "a grey pickup leaves the route unless a later quest needs it")
  check(questText(win(), "LEVELS 12-20") and questText(win(), "0% done") and questText(win(), "Current"),
    "guides are grouped by level band with progress and status")
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
  click(win(), "Test plan route")
  local frame = questViewer()
  check(questText(frame, "Accept - Plan Outdoor Errand"), "the plan fixture starts at its first pickup")
  check(questText(frame, "Chain: part 1 of 3"), "a story chain shows its position")
  MOCK.questLog = { { questID = 999201, objectives = { { text = "Hay bales 0/3" } } } }
  MOCK.event("QUEST_ACCEPTED", 1, 999201)
  check(not questText(frame, "Plan Dungeon Pickup") and not questText(frame, "Plan Optional Errand"),
    "unplanned dungeon pickups and optional errands stay hidden")
  click(win(), "Guide library")
  check(findButton(win(), function(l) return l == "Plan recommended" end) and questText(win(), "Not planned"),
    "the dungeon list offers plans")
  click(win(), "Test Plan Dungeon")
  check(questText(win(), "BOSSES IN ORDER") and questText(win(), "Interrupt the test bolt."), "the dungeon page lists boss tips")
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
  C_QuestLog.GetMaxNumQuestsCanAccept = nil
  click(win(), "Quests")
  click(win(), "Guide library")
  click(win(), "Plan none")
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
  click(win(), "Resume active quest")
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
  click(win(), "Test outbound")
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
  click(win(), "Test outbound")
  click(win(), "Resume active quest")
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
  check(findButton(win(), function(label) return label == "Try Darkshore" end), "other suitable routes are offered away from checkpoints")
  click(win(), "Darkshore")
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
  check(findButton(win(), function(label) return label == "Try Loch Modan" end), "Westfall offers Loch Modan")
  click(win(), "Try Darkshore")
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
  click(win(), "Show step window")
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
function S.makeTalentWindow(mode, frameName)
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

-- Hovering keeps the banner up; leaving lets it fade; click opens the window.
function S.bannerMouse()
  if not D() then return end
  MOCK.level = 20
  MOCK.event("PLAYER_LEVEL_UP", 20)
  MOCK.advance(4.5)
  local t = toast()
  MOCK.mouseOver[t] = true
  MOCK.advance(12)
  check(t:IsShown(), "banner stays while hovered")
  MOCK.mouseOver[t] = nil
  MOCK.advance(12)
  check(not t:IsShown(), "banner fades after mouse leaves")
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

local TABS = { "This Level", "Talents", "Trainer", "Macros", "Tips", "Professions", "Quests", "Settings" }

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
  mini:Click("RightButton")
  check(win():IsShown(), "right-click opens settings")
  win():Hide()
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
  entry.func(entry, { buttonName = "RightButton" })
  check(win():IsShown() and MOCK.textUnder(win()):find("Minimap button"), "right-click opens Settings")
  win():Hide()
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
    for _, m in ipairs(D().macros) do
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
  check(content:find("No supported professions learned", 1, true), "empty profession switch")
  for _, name in ipairs({ "Blacksmithing", "Mining", "Tailoring", "Enchanting", "Herbalism" }) do
    check(content:find(name, 1, true) and not profButton(name), "only text for supported " .. name)
  end
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
  check(profText():find("STEP 100%-112"), "clicked route preview")
  MOCK.setSkill("Blacksmithing", 98, 150)
  MOCK.advance(1.2)
  MOCK.setSkill("Blacksmithing", 97, 150)
  MOCK.advance(1.2)
  check(profText():find("DO THIS NOW") and not profText():find("STEP 100%-112"), "rank change clears the preview permanently")
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
  check(not profButton("Mining") and profText():find("No supported professions learned", 1, true),
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
  local t = profText()
  check(t:find("Blacksmithing 97 / 150"), "skill header")
  check(t:find("Rough Bronze Leggings") and t:find("about 3 more to 100"), "now card")
  check(t:find("Learn at 95"), "learn level")
  check(t:find("SHOPPING LIST TO 300"), "shopping list")
  check(t:find("1882 Thorium Bar"), "shopping list counts the 140 Thorium Bars the Imperial Plate quests take")
  check(t:find("24 Heavy Grinding Stone"), "shopping list counts only the stones the route doesn't make itself")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^100%-112") then b:Click(); break end
  end
  check(profText():find("STEP 100%-112") and profText():find("make 24 more"), "clicked step shows; the note says how many more stones")
  for _, b in ipairs(MOCK.buttons(win())) do
    if b.tipTitle and b.tipTitle:find("^95%-100") then b:Click(); break end
  end
  check(profText():find("DO THIS NOW") and profText():find("about 3 more to 100"), "clicking your own step goes back to it")
  check(t:find("THE WHOLE ROUTE"), "route list")
  check(t:find("TRAIN EXPERT") == nil, "Expert not due at 97")
  click(win(), "Mining")
  t = profText()
  check(t:find("Mining 140 / 225") and t:find("Iron Deposit") and t:find("Arathi Highlands"), "mining header, vein, zones")
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
  check(profText():find("ROUTE DONE"), "route done at 300")
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
  check(text:find("THE WHOLE ROUTE") and text:find("270%-300") and text:find("CAMP OBJECTS"), "route and camp sections")
  check(text:find("20  Incense Candle") and text:find("140  Greenhouse") and
    text:find("300  Seed Hybridizer"), "camp unlocks")
  check(not text:find("Smelt") and not text:find("SHOPPING LIST"), "gathering route has no crafting advice")
  MOCK.setSkill("Herbalism", 25, 75); MOCK.advance(1.2)
  check(profText():find("Peacebloom  1  yellow"), "Peacebloom turns yellow at 25")
  MOCK.setSkill("Herbalism", 50, 75); MOCK.advance(1.2)
  check(profText():find("Peacebloom  1  green") and profText():find("TRAIN JOURNEYMAN"), "green and training at 50")
  MOCK.setSkill("Herbalism", 300, 300); MOCK.advance(1.2)
  check(profText():find("ROUTE DONE") and profText():find("Black Lotus opens at 300"), "cap and Black Lotus")
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
  check(profText():find("ROUTE DONE", 1, true), "First Aid route ends at 300")
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
  check(profText():find("ROUTE DONE", 1, true), "Alchemy route ends at 300")
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
  check(profText():find("ROUTE DONE"), "Skinning cap")
  click(win(), "Leatherworking")
  content = profText()
  check(content:find("Leatherworking 1 / 75") and content:find("57 Ruined Leather Scraps") and
    content:find("SHOPPING LIST TO 300"), "Leatherworking starter and shopping estimate")
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
  check(profText():find("ROUTE DONE", 1, true), "Cooking route ends at 300")
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
  check(profText():find("ROUTE DONE", 1, true), "Fishing route ends at 300")
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
  check(profText():find("ROUTE DONE", 1, true), "Engineering route ends at 300")
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
  check(t:find("SHOPPING LIST TO 300") and t:find("\nCLOTH\n"), "shopping list and cloth section")
  local shop = shoppingText()
  check(not shop:find("%d+ Bolt of"), "no bolt rows in the shopping list: they're counted as cloth")
  local cloth, bolts = shop:match("(%d+) Runecloth %(for (%d+) bolts")
  check(cloth and tonumber(cloth) == 5 * tonumber(bolts), "Runecloth row: 5 per bolt (" .. tostring(cloth) .. ", " .. tostring(bolts) .. ")")
  check(t:find("make them from Silk Cloth %(4 each%)"), "step card: bolts are made from Silk Cloth")
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
    check(held:find("make them from Silk Cloth %(4 each%): your 0 make 0") and not held:find("your 48"),
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
  check(cards and cards.tipText and cards.tipText:find("Tailoring"), "Settings: skill-up cards name Tailoring")
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
  check(t:find("Runecloth Shoulders") and t:find("Venomspew Gloves") and t:find("Venomspew Cord"),
    "Runecloth finish with vendor alternatives")
  MOCK.setSkill("Tailoring", 300, 300)
  t = tailoring()
  check(t:find("ROUTE DONE") and not t:find("you need this now"), "route done at 300")
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
  check(t:find("Enchant Bracer %- Lesser Stamina") and t:find("about 5 more to 155"), "step at 150")
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
    check(not t:find("make them from Strange Dust"), "skill 1, no rod: no 'make them from' (Dust to Motes needs the rod)")
    MOCK.setSkill("Enchanting", 12, 75)
    MOCK.bags = { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 4 }
    check(enchanting():find("make them from Strange Dust %(1 makes 3%): your 4 make 12"), "Motes: 1 dust makes 3")
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
  check(t:find("ROUTE DONE") and not t:find("you need this now"), "route done at 300")
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
  check(row == TradeSkillSkill2 and MOCK.textUnder(hint):find("you can make 2", 1, true),
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
  check(status:find("Not learned yet") and status:find("Leonard Porter") and status:find("Werg Thickblade"),
    "missing Leatherworking recipe names the pattern vendors")
  MOCK.trade.recipes[2] = { "Wicked Leather Gauntlets", "optimal", 3 }
  MOCK.trade.layout(); MOCK.advance(1)
  local _, row = trace:GetPoint(1)
  check(trace:IsShown() and row == TradeSkillSkill2 and MOCK.trade.selected == 0 and MOCK.trade.offset == 0,
    "Leatherworking trace leaves the recipe list alone")
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "Skinning", 20, 75
  MOCK.trade.recipes = { { "Camp Chair", "optimal", 3 } }
  MOCK.trade.layout(); MOCK.advance(1)
  check(not hint:IsShown() and not trace:IsShown(), "Skinning gathering route has no crafting overlay")
  closeCraft()
end

function S.craftTrace()
  if not craftReady() then return end
  MOCK.setSkill("Blacksmithing", 97, 150)
  openCraft()
  local tr, h = _G.LevelingCodexCraftTrace, _G.LevelingCodexCraftHint
  check(h and h:IsShown(), "card beside the crafting window")
  local text = MOCK.textUnder(h)
  check(text:find("Rough Bronze Leggings") and text:find("About 3 more to 100") and text:find("materials for 4"), "card text")
  check(text:find("orange"), "live colour on the card")
  check(tr and tr:IsShown(), "row traced")
  local _, rel = tr:GetPoint(1)
  check(rel == TradeSkillSkill4, "trace on the Rough Bronze Leggings row (its text has a colour code and a count)")
  closeCraft()
  check(not tr:IsShown() and not h:IsShown(), "trace and card hide with the window")
end

function S.craftHerbalism()
  openCraft()
  local hint, trace = LevelingCodexCraftHint, LevelingCodexCraftTrace
  check(hint and hint:IsShown() and trace and trace:IsShown(), "crafting guide before switching professions")
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max = "Herbalism", 20, 75
  MOCK.trade.recipes = { { "Incense Candle", "optimal", 2 } }
  MOCK.trade.layout()
  MOCK.event("TRADE_SKILL_UPDATE")
  MOCK.advance(0.6)
  check(not hint:IsShown() and not trace:IsShown(), "Herbalism camp recipes do not show a crafting guide")
  closeCraft()
end

function S.craftNotLearned()
  if not craftReady() then return end
  table.remove(MOCK.trade.recipes, 4); MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Not learned yet"), "not learned")
  check(not LevelingCodexCraftTrace:IsShown(), "nothing to trace")
  closeCraft()
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 4 })
  MOCK.trade.layout()
end

function S.craftGrey()
  if not craftReady() then return end
  MOCK.trade.recipes[4][2] = "trivial"; MOCK.trade.layout()
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("Grey now: next is Heavy Grinding Stone"), "grey: move on")
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
  check(MOCK.textUnder(h):find("It's in the list: scroll to it.", 1, true), "the card says to scroll to it")
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
    check(text:find("It's in the list: scroll to it.", 1, true), who .. ": the card says to scroll to it")
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
  check(text:find("MINING 80") and text:find("Smelt Silver") and text:find("About 20 more to 100"), "smelting card")
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
  check(MOCK.textUnder(LevelingCodexCraftHint):find("not in the list: clear the search"), "known but filtered")
  closeCraft()
  MOCK.knownSpells[2668] = nil
  openCraft()
  local text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Not learned yet") and text:find("Instead: Runed Copper Belt"), "not learned shows the alternative")
  closeCraft()
  table.insert(MOCK.trade.recipes, { "Rough Bronze Leggings", "optimal", 4 })
  MOCK.trade.layout()
end

-- Classic calls that exist but return nothing (compatibility stubs): C_TradeSkillUI is read instead.
function S.craftClassicStubs()
  if not craftReady() then return end
  local count = GetNumTradeSkills
  S.retailAPI()
  GetNumTradeSkills = function() return 0 end
  openCraft()
  check(MOCK.textUnder(LevelingCodexCraftHint):find("materials for 4"), "recipe read through C_TradeSkillUI")
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
  check(text:find("Make Bolts of Silk Cloth first: your 46 Silk Cloth make 11.", 1, true), "bolts first with only the cloth")
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
  check(text:find("Earthen Vest") and text:find("Not learned yet") and not text:find("first"),
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
  check(text:find("Make your Runed Silver Rod first: every enchant from here needs it.", 1, true), "rod first")
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
  check(text:find("Not learned yet") and not text:find("first"), "the step's recipe missing: not learned, not the rod")
  enchantWindow(270, 300, { { "Runed Truesilver Rod", "trivial", 0 }, { "Enchant Shield - Greater Stamina", "optimal", 0 } }, {})
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make your Runed Truesilver Rod first") and not text:find("Grey now"), "a grey rod still needed")
  check(LevelingCodexCraftTrace:IsShown(), "the grey rod is outlined")
  enchantWindow(1, 75, { { "Runed Copper Rod", "optimal", 0 }, { "Dust to Motes", "optimal", 5 } }, { ["Strange Dust"] = 5 })
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Runed Copper Rod") and not text:find("Make Motes of Magic first"), "skill 1: the rod, not Motes (Dust to Motes needs the rod)")
  enchantWindow(12, 75, { { "Dust to Motes", "trivial", 5 }, { "Enchant Bracer - Inferior Stamina", "optimal", 0 } },
    { ["Runed Copper Rod"] = 1, ["Strange Dust"] = 5 })
  text = MOCK.textUnder(LevelingCodexCraftHint)
  check(text:find("Make Motes of Magic first: your 5 Strange Dust make 15.", 1, true), "Motes first: 3 per dust")
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
  check(t:find("Smelt Silver") and t:find("chance of a point") and not t:find("About %d+ more"), "100: a chance, not a count")
  t = at(145, { { "Smelt Copper", "trivial", 9 }, { "Smelt Bronze", "trivial", 1 }, { "Smelt Silver", "trivial", 3 },
                { "Smelt Iron", "trivial", 5 } })
  check(t:find("no points at 145") and t:find("Smelt Gold") and t:find("155"), "145: mine instead, Gold from 155")
  t = at(184, { { "Smelt Gold", "easy", 3 } })
  check(t:find("Smelt Gold") and t:find("chance of a point"), "184: Gold still gives points")
  t = at(185, { { "Smelt Gold", "trivial", 3 } })
  check(t:find("no points at 185"), "185: Gold is grey, mine instead")
  MOCK.trade.line, MOCK.trade.rank, MOCK.trade.max, MOCK.trade.recipes, MOCK.trade.offset = unpack(saved)
  MOCK.trade.layout()
end
