-- QuestTravel.lua: trips through flight masters. Every flight point and each zone's place in the
-- world come from QuestFlightData.lua (the client's own tables); which flight paths you have comes
-- from the flight map and C_TaxiMap (Quests.lua). For a long trip on one continent the arrow
-- compares walking with: walk to one of the closest flight masters, fly to the flight point you
-- have that is closest to the step, walk the rest. It never chains flights you'd have to change
-- yourself, boats or portals. A flight path you don't have close to the way is learned on the
-- way, the flight map marks the guide's flight, and Quests > Nearest flight master points at one.
local _, ns = ...
local Q = ns.quests
local try = Q.try

local WALK = 7          -- yards per second on foot
local FLY = 25          -- straight-line yards per second of a flight (routes bend)
local OVERHEAD = 20     -- seconds to talk to the flight master, take off and land
local MIN_TRIP = 700    -- shorter trips are walked
local SAVE = 0.8        -- a flight must save a fifth of the walk
local ORIGINS = 3       -- flight masters considered as the start
local LEARN_REACH = 500 -- a flight path you don't have this close ...
local LEARN_DETOUR = 250 -- ... and at most this far out of the way is learned on the way

local nodes, byName     -- your faction's flight points
local pointing          -- Quests > Nearest flight master: the flight point the arrow leads to
local cache = {}

local function load()
  if nodes then return end
  nodes, byName = {}, {}
  local faction = try(UnitFactionGroup, "player")
  local letter = faction == "Alliance" and "A" or faction == "Horde" and "H"
  if not letter then nodes = nil; return end
  for id, d in pairs(ns.questFlightNodes or {}) do
    local world = ns.questWorld and ns.questWorld[d[3]]
    if d[2]:find(letter, 1, true) and world then
      local node = { id = id, name = d[1], map = d[3], x = d[4], y = d[5], links = d[6], continent = world[1],
        wx = world[2] - d[5] / 100 * world[4], wy = world[3] - d[4] / 100 * world[5] }
      nodes[id], byName[node.name] = node, node
    end
  end
end

-- A spot's world position: continent, then yards north and west.
local function world(map, x, y)
  local w = map and x and y and ns.questWorld and ns.questWorld[map]
  if not w then return end
  return w[1], w[2] - y / 100 * w[4], w[3] - x / 100 * w[5]
end

local function dist(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return math.sqrt(dx * dx + dy * dy)
end

local function short(name) return (name:match("^[^,]+")) end

-- The client reports a continent map (in some tunnels): spots on that continent are walked to.
function Q.continentMap(map)
  local w = ns.questWorld and ns.questWorld[map]
  return w ~= nil and w[6] == true
end

-- Two maps on the same continent (zones, cities or the continent map itself).
function Q.sameContinent(a, b)
  local wa, wb = ns.questWorld and ns.questWorld[a], ns.questWorld and ns.questWorld[b]
  return wa ~= nil and wb ~= nil and wa[1] == wb[1]
end

-- Heading and yards to a spot on another map of the same continent (Q.vector only works on one map).
function Q.worldVector(spot, map, x, y)
  local c, px, py = world(map, x, y)
  local tc, tx, ty = world(spot and spot.map, spot and spot.x, spot and spot.y)
  if not c or c ~= tc then return end
  local north, east = tx - px, py - ty
  return math.atan2(east, north), math.sqrt(north * north + east * east)
end

local function walkSpeed()
  local _, run = try(GetUnitSpeed, "player")
  return math.max(WALK, tonumber(run) or 0)
end

-- A flight's length: the time you took last time, else the distance at flight speed.
local function flightSeconds(from, to)
  local times = ns.db().flightTimes
  local timed = type(times) == "table" and times[from.name .. ">" .. to.name]
  if type(timed) == "number" and timed > 0 then return timed + OVERHEAD end
  return dist(from.wx, from.wy, to.wx, to.wy) / FLY + OVERHEAD
end

-- Can you fly from one flight point to another? What its flight map said when you opened it there,
-- else a path through flight points you have.
local function reachable(from, to)
  if from == to then return false end
  local seen = Q.flightMapFrom(from.name)
  if seen then return seen[to.name] == "REACHABLE" end
  local queue, done, head = { from }, { [from.id] = true }, 1
  while queue[head] do
    local n = queue[head]
    head = head + 1
    for _, id in ipairs(n.links) do
      local m = nodes[id]
      if m and not done[id] and Q.knownFlight(m.name) then
        if m == to then return true end
        done[id] = true
        queue[#queue + 1] = m
      end
    end
  end
  return false
end

-- We know which flight paths you have on a continent when the client lists them, or when you
-- opened a flight map there this session (it shows every flight path you have).
local function complete(continent)
  if Q.flightsListed() then return true end
  for _, n in pairs(nodes) do
    if n.continent == continent and Q.flightMapFrom(n.name) then return true end
  end
  return false
end

local function plan(target, map, x, y)
  local c, px, py = world(map, x, y)
  local tc, tx, ty = world(target.map, target.x, target.y)
  if not c or c ~= tc then return end
  local direct = dist(px, py, tx, ty)
  if direct < MIN_TRIP then return end
  local speed = walkSpeed()
  local around = {}
  for _, n in pairs(nodes) do
    if n.continent == c then around[#around + 1] = { node = n, yards = dist(px, py, n.wx, n.wy) } end
  end
  table.sort(around, function(a, b) return a.yards < b.yards end)
  local best, bestTime = nil, direct / speed * SAVE
  for i = 1, math.min(ORIGINS, #around) do
    local origin, walkTo = around[i].node, around[i].yards / speed
    for _, to in pairs(nodes) do
      if to.continent == c and to ~= origin and Q.knownFlight(to.name) then
        local total = walkTo + flightSeconds(origin, to) + dist(to.wx, to.wy, tx, ty) / speed
        if total < bestTime and reachable(origin, to) then
          best, bestTime = { origin = origin, to = to, seconds = total }, total
        end
      end
    end
  end
  return best
end

-- A flight path you don't have, close by and close to the way to the step.
local function learnOnTheWay(target, map, x, y)
  if ns.db().noFlightLearn then return end
  local c, px, py = world(map, x, y)
  local tc, tx, ty = world(target.map, target.x, target.y)
  if not c or c ~= tc or not complete(c) then return end
  local direct = dist(px, py, tx, ty)
  local best, bestExtra
  for _, n in pairs(nodes) do
    if n.continent == c and not Q.knownFlight(n.name) then
      local toNode = dist(px, py, n.wx, n.wy)
      local extra = toNode + dist(n.wx, n.wy, tx, ty) - direct
      if toNode <= LEARN_REACH and extra <= LEARN_DETOUR and (not best or extra < bestExtra) then
        best, bestExtra = n, extra
      end
    end
  end
  return best
end

local function leg(node)
  return { map = node.map, x = node.x, y = node.y, leg = true, type = "goto", flight = node.name }
end

-- The arrow's way to a step on your continent: nil when walking straight there is best.
-- Returns a waypoint (`leg = true`: the arrow shows its distance) and the caption.
function Q.travelLeg(step, map)
  load()
  if not nodes or not step or not step.x then return end
  local _, x, y = Q.position()
  if not x then return end
  if pointing then
    local _, yards = Q.worldVector(pointing, map, x, y)
    local name = short(pointing.name)
    if yards and yards <= Q.arrived() then
      return leg(pointing), (Q.knownFlight(pointing.name) and "Flight master at " or "Learn the flight path at ") .. name
    end
    return leg(pointing), "Nearest flight master: " .. name
  end
  if ns.db().noFlightPlans then return end
  local key = table.concat({ step.map, step.x, step.y, map, math.floor(x), math.floor(y), Q.flightVersion(),
    ns.db().noFlightLearn and "noLearn" or "learn" }, ":")
  if cache.key ~= key then
    cache.key, cache.plan, cache.learn = key, plan(step, map, x, y), nil
    if not cache.plan and step.type ~= "getfp" then cache.learn = learnOnTheWay(step, map, x, y) end
  end
  local trip = cache.plan
  if trip then
    local to = short(trip.to.name)
    local _, yards = Q.worldVector(trip.origin, map, x, y)
    if yards and yards <= Q.arrived() then
      return leg(trip.origin), Q.knownFlight(trip.origin.name) and ("Fly to " .. to .. ": talk to the flight master")
        or ("Learn this flight path, then fly to " .. to)
    end
    local from = short(trip.origin.name)
    return leg(trip.origin), Q.knownFlight(trip.origin.name) and ("Fly to " .. to .. " from " .. from)
      or ("Learn the " .. from .. " flight path, then fly to " .. to)
  end
  if cache.learn then return leg(cache.learn), "Learn the " .. short(cache.learn.name) .. " flight path on the way" end
end

-- Standing at the flight master the travel plan starts from (travel automation picks its taxi option).
function Q.atPlannedFlightMaster()
  local trip = cache.plan
  if not trip then return false end
  local _, yards = Q.worldVector(trip.origin, Q.position())
  return yards ~= nil and yards <= Q.arrived() * 2
end

-- The flight the guide wants from this flight map: the current Fly step's, else the best one for
-- the current step from the flight point you stand at (by `seen`, the open flight map's nodes).
function Q.flightTarget(seen)
  local fly = Q.flightStep()
  if fly then return fly.flight end
  load()
  if not nodes or ns.db().noFlightPlans then return end
  local row = Q.current()
  local spot = row and Q.waypoint(row.step)
  local tc, tx, ty = world(spot and spot.map, spot and spot.x, spot and spot.y)
  local here
  for name, state in pairs(seen or {}) do
    if state == "CURRENT" then here = byName[Q.plain(name)] end
  end
  if not tc or not here or here.continent ~= tc then return end
  local speed = walkSpeed()
  local best, bestTime = nil, dist(here.wx, here.wy, tx, ty) / speed * SAVE
  for name, state in pairs(seen) do
    local to = state == "REACHABLE" and byName[Q.plain(name)]
    if to and to.continent == tc then
      local total = flightSeconds(here, to) + dist(to.wx, to.wy, tx, ty) / speed
      if total < bestTime then best, bestTime = to, total end
    end
  end
  return best and best.name
end

-- The flight map: a Codex badge on the guide's destination and a line naming it.
local mark
function ns.markTaxi(want, again)
  pointing = nil
  if mark then mark:Hide() end
  local frame = _G.TaxiFrame or _G.FlightMapFrame
  if not want or type(frame) ~= "table" or type(frame.IsShown) ~= "function" then return end
  if not mark then
    mark = CreateFrame("Frame", "LevelingCodexTaxiMark", frame)
    mark:SetSize(10, 10)
    mark.badge = mark:CreateTexture(nil, "OVERLAY")
    mark.badge:SetSize(22, 22)
    ns.setIcon(mark.badge, ns.ADDON_ICON)
    mark.text = mark:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  end
  mark:SetParent(frame)
  mark:ClearAllPoints()
  mark:SetPoint("TOP", frame, "TOP", 0, -48)
  mark:SetFrameLevel((tonumber(try(frame.GetFrameLevel, frame)) or 1) + 10)
  mark.text:ClearAllPoints()
  mark.text:SetPoint("TOP", mark, "TOP", 0, 0)
  mark.text:SetText(Q.plain("Leveling Codex: fly to " .. short(want)))
  local button
  for i = 1, tonumber(try(NumTaxiNodes)) or 0 do
    local name = try(TaxiNodeName, i)
    if type(name) == "string" and Q.plain(name):lower() == Q.plain(want):lower() then button = _G["TaxiButton" .. i] end
  end
  mark.badge:ClearAllPoints()
  if type(button) == "table" and type(button.GetObjectType) == "function" then
    mark.badge:SetPoint("BOTTOMLEFT", button, "TOPRIGHT", -6, -6)
    mark.badge:Show()
  else
    mark.badge:Hide()
    if not again then ns.after(0.3, function() if frame:IsShown() then ns.markTaxi(want, true) end end) end
  end
  mark:Show()
end

-- Quests > Nearest flight master: the arrow leads to the closest flight point of your faction on
-- your continent until you open a flight map or press it again.
function ns.pointToFlightMaster()
  if pointing then
    pointing = nil
    ns.questRefresh()
    return
  end
  load()
  local map, x, y = Q.position()
  local c, px, py = world(map, x, y)
  local best, bestYards
  for _, n in pairs(nodes or {}) do
    if n.continent == c then
      local yards = dist(px, py, n.wx, n.wy)
      if not bestYards or yards < bestYards then best, bestYards = n, yards end
    end
  end
  if not best then
    ns.say("no flight master is known for where you are.")
    return
  end
  pointing = best
  ns.say(Q.plain("the arrow points to the " .. short(best.name) .. " flight master"
    .. (Q.knownFlight(best.name) and "" or " (a flight path you don't have yet)") .. "."))
  ns.questRefresh()
end

function ns.pointingToFlightMaster() return pointing ~= nil end

function ns.travelDebugLines()
  load()
  local count, known, plans = 0, 0, nil
  for _, n in pairs(nodes or {}) do
    count = count + 1
    if Q.knownFlight(n.name) then known = known + 1 end
  end
  if cache.plan then plans = short(cache.plan.origin.name) .. " > " .. short(cache.plan.to.name) end
  return { "travel: " .. count .. " flight points for your faction, " .. known .. " known"
    .. (Q.flightsListed() and " (listed by the client)" or "") .. ", plan: " .. (plans or "walk")
    .. (cache.learn and (", learn " .. short(cache.learn.name)) or "") }
end
