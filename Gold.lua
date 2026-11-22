-- Gold.lua: the Gold tab. The mount fund: the gold you're saving for riding, how far you are and
-- how long it takes at this session's net gold per hour (Stats.lua). The goal is yours to set
-- (Forever's costs aren't in the client data); a riding trainer's price replaces the training part
-- of it when you visit one. The auction tools add their cards here too (ns.gold.addSection).
local _, ns = ...
local try = ns.quests.try

local G = {}
ns.gold = G

G.DEFAULT_LEVEL = 40
G.DEFAULT_GOAL = 90 * 10000 -- copper: Classic's riding training plus a mount; set your own
G.STEP = 5 * 10000          -- the -/+ buttons move the goal 5g at a time
local sections = {}         -- other files' cards: { order, draw(y) -> y }

function G.addSection(order, draw)
  sections[#sections + 1] = { order = order, draw = draw }
  table.sort(sections, function(a, b) return a.order < b.order end)
end

local function money() return tonumber(try(GetMoney)) end
local function level() return tonumber(UnitLevel("player")) or 1 end

function G.goal()
  local db = ns.db()
  return math.max(G.STEP, tonumber(db.mountGoal) or G.DEFAULT_GOAL)
end
function G.goalLevel()
  local db = ns.db()
  return math.max(1, math.min(60, tonumber(db.mountGoalLevel) or G.DEFAULT_LEVEL))
end
function G.setGoal(copper)
  ns.db().mountGoal = math.max(G.STEP, math.floor(copper))
end
function G.setGoalLevel(l)
  ns.db().mountGoalLevel = math.max(1, math.min(60, math.floor(l)))
end

-- Where you stand: { have, goal, left, pct, ready, rate, eta }.
function G.fund()
  local have, goal = money(), G.goal()
  if not have then return { goal = goal } end
  local left = math.max(0, goal - have)
  local rate = ns.stats and ns.stats.goldRate and ns.stats.goldRate()
  return { have = have, goal = goal, left = left, pct = math.min(100, math.floor(have * 100 / goal)),
    ready = left == 0, rate = rate, eta = rate and left > 0 and left * 3600 / rate or nil }
end

local function duration(seconds)
  local minutes = math.floor((tonumber(seconds) or 0) / 60 + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return math.floor(minutes / 60) .. " h " .. (minutes % 60) .. " min"
end

-- A riding trainer: its price for riding training is what training costs, not a guess.
local function readTrainer()
  for i = 1, tonumber(try(GetNumTrainerServices)) or 0 do
    local name, _, category = try(GetTrainerServiceInfo, i)
    if type(name) == "string" and name:find("Riding", 1, true) and category ~= "header" then
      local cost = tonumber(try(GetTrainerServiceCost, i))
      if cost and cost > 0 then
        local db = ns.db()
        if db.mountTraining ~= cost then
          db.mountTraining = cost
          ns.say(ns.plain(name) .. " costs " .. ns.money(cost) .. " here: the Gold tab counts it in your mount fund.")
        end
        return
      end
    end
  end
end

-- The level-up to your goal level says where the fund stands, once.
local function levelUp(newLevel)
  if tonumber(newLevel) ~= G.goalLevel() then return end
  local f = G.fund()
  if not f.have then return end
  if f.ready then
    ns.say("Level " .. newLevel .. ": you have the " .. ns.money(f.goal) .. " for riding. Visit a riding trainer.")
  else
    ns.say("Level " .. newLevel .. ": riding fund " .. ns.money(f.have) .. " of " .. ns.money(f.goal)
      .. ", " .. ns.money(f.left) .. " to go.")
  end
end

local events
function ns.startGold()
  if events then return end
  events = CreateFrame("Frame")
  pcall(events.RegisterEvent, events, "TRAINER_SHOW")
  pcall(events.RegisterEvent, events, "PLAYER_LEVEL_UP")
  pcall(events.RegisterEvent, events, "PLAYER_MONEY")
  events:SetScript("OnEvent", function(_, event, arg)
    if event == "TRAINER_SHOW" then pcall(readTrainer)
    elseif event == "PLAYER_LEVEL_UP" then pcall(levelUp, arg)
    elseif ns.refreshTab then ns.refreshTab("gold") end
  end)
end

----------------------------------------------------------------------------
-- The tab
----------------------------------------------------------------------------

local function render()
  local U, C = ns.ui, ns.C
  local W = U.W
  local y = U.sectionTitle("Gold", 0)

  -- Mount fund
  local f = G.fund()
  local top = y
  y = y + 10
  U.T("MOUNT FUND", 14, y, W - 28, "label", C.gold)
  U.T("Riding at level " .. G.goalLevel(), 14, y, W - 28, "small", C.light, "RIGHT")
  y = y + 24
  if f.have then
    U.T(ns.coins(f.have) .. "  of  " .. ns.coins(f.goal), 14, y, W - 28, "head", C.light)
    U.T(f.pct .. "%", 14, y + 4, W - 28, "body", C.gold, "RIGHT")
    y = y + 26
    U.rect(14, y, W - 28, 10, { 0.05, 0.05, 0.08, 0.9 })
    local bw = (W - 28) * f.pct / 100
    if bw >= 1 then U.rect(14, y, bw, 10, f.ready and { 0.3, 0.75, 0.35, 1 } or C.gold, nil, 1) end
    y = y + 18
    local line
    if f.ready and level() >= G.goalLevel() then
      line = "You have it: visit a riding trainer and a mount vendor."
    elseif f.ready then
      line = "You have the gold. Riding opens at level " .. G.goalLevel() .. ": keep it until then."
    elseif f.eta then
      line = ns.money(f.left) .. " to go: about " .. duration(f.eta) .. " at this session's "
        .. ns.money(f.rate) .. " net per hour."
    else
      line = ns.money(f.left) .. " to go. Your pace shows once you've earned gold this session."
    end
    y = y + U.T(line, 14, y, W - 28, "small", C.light) + 6
  else
    y = y + U.T("Your money can't be read on this client.", 14, y, W - 28, "small", C.dim) + 6
  end
  local db = ns.db()
  if db.mountTraining then
    y = y + U.T("A riding trainer asked " .. ns.money(db.mountTraining) .. " for training; the rest of your goal is the mount.",
      14, y, W - 28, "small", C.dim) + 6
  else
    y = y + U.T("The goal starts at Classic's cost. Set it to what Forever asks: a riding trainer's price shows here once you visit one.",
      14, y, W - 28, "small", C.dim) + 6
  end
  -- steppers: the goal and its level
  local function stepper(label, value, x, minus, plus)
    U.T(label, x, y + 4, 90, "body", C.light)
    U.btn("-", x + 92, y, 28, function() minus(); U.refresh() end, false).codexLabel = label .. " -"
    U.T(value, x + 124, y + 4, 70, "body", C.gold, "CENTER")
    U.btn("+", x + 198, y, 28, function() plus(); U.refresh() end, false).codexLabel = label .. " +"
  end
  stepper("Goal", ns.money(G.goal()), 14, function() G.setGoal(G.goal() - G.STEP) end,
    function() G.setGoal(G.goal() + G.STEP) end)
  stepper("Level", tostring(G.goalLevel()), 260, function() G.setGoalLevel(G.goalLevel() - 1) end,
    function() G.setGoalLevel(G.goalLevel() + 1) end)
  y = y + 32
  if db.mountGoal or db.mountGoalLevel then
    U.btn("Reset goal", 14, y, 120, function()
      db.mountGoal, db.mountGoalLevel = nil, nil
      U.refresh()
    end, false, "Back to level " .. G.DEFAULT_LEVEL .. " and " .. ns.money(G.DEFAULT_GOAL) .. ".")
    y = y + 30
  end
  y = y + 4
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 12

  for _, s in ipairs(sections) do y = s.draw(y) end
  return y + 20
end

ns.addTab("gold", "Gold", render)
