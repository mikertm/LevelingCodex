-- Talents.lua: the talent path you follow. The Codex guide's own plan (Data.lua), a recommended path
-- for each spec (TalentPaths.lua) or a custom path of your own, checked against the game's tree
-- (TalentTreeData.lua). ns.talentAt (Guide.lua) reads ns.talentPlan(), so every talent display follows
-- the choice: This Level, the level-up banner and chat, the minimap tooltip, the talent-window trace.
--
-- Saved per character: LevelingCodexCharDB.talentPath (a key) and .customTalents (talent names, the
-- first one at level 10). Forever may not load SavedVariables back, so with no saved key the Codex
-- picks the spec path that the talents you already spent follow.

local _, ns = ...

ns.talentVersion = 0
local FIRST, LAST, MAX_POINTS = 10, 60, 51

local function bump() ns.talentVersion = ns.talentVersion + 1 end

local function classToken()
  local _, t = UnitClass("player")
  return t
end

function ns.talentTree()
  local t = classToken()
  return t and ns.talentTrees and ns.talentTrees[t] or nil
end

-- name -> talent and name -> position in the tree's list, built once per tree
local indexes = {}
local function index(tree)
  if not tree then return {}, {} end
  local x = indexes[tree]
  if not x then
    x = { byName = {}, pos = {}, byLower = {} }
    for i, t in ipairs(tree.talents) do
      x.byName[t.name], x.pos[t.name], x.byLower[string.lower(t.name)] = t, i, t
    end
    indexes[tree] = x
  end
  return x.byName, x.pos, x.byLower
end

----------------------------------------------------------------------------
-- The paths
----------------------------------------------------------------------------

local CUSTOM = { key = "custom", spec = "Custom", role = "Your own build",
  note = "Place every point yourself: click the tree in level order.", custom = true }

local pathsCache = {}
function ns.talentPaths()
  local D = ns.D
  if not D then return {} end
  if pathsCache.D == D and pathsCache.tree == ns.talentTree() then return pathsCache.list end
  local list, hasGuide = {}, false
  for _, p in ipairs((ns.TALENT_PATHS or {})[classToken()] or {}) do
    if p.key == "guide" then
      list[#list + 1] = { key = "guide", spec = p.spec or D.spec, role = p.role or "", note = p.note or "", plan = D.plan, guide = true }
      hasGuide = true
    elseif p.plan then
      list[#list + 1] = p
    end
  end
  if not hasGuide then table.insert(list, 1, { key = "guide", spec = D.spec, role = "", note = "", plan = D.plan, guide = true }) end
  if ns.talentTree() then list[#list + 1] = CUSTOM end
  pathsCache = { D = D, tree = ns.talentTree(), list = list }
  return list
end

local function pathByKey(key)
  if not key then return nil end
  for _, p in ipairs(ns.talentPaths()) do
    if p.key == key then return p end
  end
end

-- A plan's points as talent names in level order (index 1 = level 10).
local function pointsOf(plan)
  local points = {}
  for _, p in ipairs(plan or {}) do
    for l = p.from, p.to do points[l - FIRST + 1] = p.name end
  end
  local out = {}
  for i = 1, MAX_POINTS do
    if not points[i] then break end
    out[i] = points[i]
  end
  return out
end

----------------------------------------------------------------------------
-- The game's rules
----------------------------------------------------------------------------

-- Can the next point (after `points`, a list of names) go into `name`? ok, or false and why.
function ns.talentCanAdd(points, name)
  local tree = ns.talentTree()
  local byName = index(tree)
  local t = byName[name]
  if not t then return false, "Not a talent" end
  if #points >= MAX_POINTS then return false, "All " .. MAX_POINTS .. " points placed" end
  local ranks, inTab = {}, 0
  for _, n in ipairs(points) do
    ranks[n] = (ranks[n] or 0) + 1
    local o = byName[n]
    if o and o.tab == t.tab then inTab = inTab + 1 end
  end
  if (ranks[name] or 0) >= t.max then
    return false, t.max == 1 and "Already taken" or ("All " .. t.max .. " ranks taken")
  end
  if inTab < t.req then
    return false, "Needs " .. t.req .. " points in " .. tree.tabs[t.tab] .. " (has " .. inTab .. ")"
  end
  if #t.prereq > 0 then
    local need = {}
    for _, pn in ipairs(t.prereq) do
      local pt = byName[pn]
      local max = pt and pt.max or 1
      if (ranks[pn] or 0) >= max then return true end
      need[#need + 1] = pn .. " " .. max .. "/" .. max
    end
    return false, "Needs " .. table.concat(need, " or ")
  end
  return true
end

----------------------------------------------------------------------------
-- The custom path
----------------------------------------------------------------------------

local function saveCustom(points)
  LevelingCodexCharDB = LevelingCodexCharDB or {}
  LevelingCodexCharDB.customTalents = points
  bump()
end

-- Your custom path's points, checked: a save from before a game patch is cut at its first point
-- that no longer fits (and the cut list is saved).
function ns.customPoints()
  local saved = ns.charDB().customTalents
  if type(saved) ~= "table" or not ns.talentTree() then return {} end
  local out = {}
  for _, name in ipairs(saved) do
    if type(name) ~= "string" or not ns.talentCanAdd(out, name) then break end
    out[#out + 1] = name
  end
  if #out < #saved then
    for i = #saved, #out + 1, -1 do saved[i] = nil end
  end
  return out
end

function ns.customAdd(name)
  local points = ns.customPoints()
  local ok, why = ns.talentCanAdd(points, name)
  if not ok then return false, why end
  points[#points + 1] = name
  saveCustom(points)
  return true
end

function ns.customUndo()
  local points = ns.customPoints()
  if #points == 0 then return false, "Nothing to undo" end
  points[#points] = nil
  saveCustom(points)
  return true
end

function ns.customClear()
  saveCustom({})
  return true
end

-- Start the custom path from a path's points.
function ns.customFrom(key)
  local p = pathByKey(key)
  if not p or p.custom then return false, "No such path" end
  local points = {}
  for _, name in ipairs(pointsOf(p.plan)) do
    if not ns.talentCanAdd(points, name) then break end
    points[#points + 1] = name
  end
  saveCustom(points)
  return true
end

-- Start the custom path from the talents you have now, in an order the game allows (row by row).
function ns.customFromLive()
  local ranks = ns.traitRanks and ns.traitRanks()
  if not ranks then return false, "Your talents can't be read here" end
  local tree = ns.talentTree()
  if not tree then return false, "No talent tree for your class" end
  local have = {}
  for _, t in ipairs(tree.talents) do
    local r = ranks[string.lower(t.name)]
    if r and r > 0 then have[#have + 1] = { t = t, rank = math.min(r, t.max) } end
  end
  if #have == 0 then return false, "You haven't spent a talent point yet" end
  table.sort(have, function(a, b)
    if a.t.row ~= b.t.row then return a.t.row < b.t.row end
    if a.t.tab ~= b.t.tab then return a.t.tab < b.t.tab end
    return a.t.col < b.t.col
  end)
  local points = {}
  for _, h in ipairs(have) do
    for _ = 1, h.rank do
      if ns.talentCanAdd(points, h.t.name) then points[#points + 1] = h.t.name end
    end
  end
  saveCustom(points)
  return true
end

local function planFrom(points)
  local tree = ns.talentTree()
  local byName = index(tree)
  local plan, last = {}, nil
  for i, name in ipairs(points) do
    local level = FIRST + i - 1
    if last and last.name == name then
      last.to = level
    else
      local t = byName[name]
      last = { name = name, tree = tree.tabs[t.tab], icon = t.icon, max = t.max, from = level, to = level,
        why = t.tip or "", more = "" }
      plan[#plan + 1] = last
    end
  end
  return plan
end

----------------------------------------------------------------------------
-- Which path: saved, matched from the talents you spent, or the guide
----------------------------------------------------------------------------

local match = { version = -1 }

local function computeMatch()
  local ranks = ns.traitRanks and ns.traitRanks()
  if not ranks then return "guide", "default", true end -- can't read them (yet): look again later
  local spent = 0
  for _, r in pairs(ranks) do spent = spent + r end
  if spent == 0 then return "guide", "default" end
  local best, bestScore
  for _, p in ipairs(ns.talentPaths()) do
    if p.plan then
      local want = {}
      local points = pointsOf(p.plan)
      for i = 1, math.min(spent, #points) do want[points[i]] = (want[points[i]] or 0) + 1 end
      local overlap = 0
      for name, n in pairs(want) do overlap = overlap + math.min(n, ranks[string.lower(name)] or 0) end
      local score = overlap / spent
      if not bestScore or score > bestScore then best, bestScore = p.key, score end
    end
  end
  if bestScore and bestScore >= 0.6 then return best, "matched" end
  return "guide", "default"
end

-- The chosen path's key and how it was picked: "saved", "matched" (no saved choice: your spent talents
-- follow it) or "default" (the Codex guide).
function ns.talentPathKey()
  local saved = ns.charDB().talentPath
  if saved and pathByKey(saved) then return saved, "saved" end
  local now = GetTime and GetTime() or 0
  if match.version ~= ns.talentVersion or match.D ~= ns.D or (match.retry and now >= match.retry) then
    local key, how, retry = computeMatch()
    match = { version = ns.talentVersion, D = ns.D, key = key, how = how, retry = retry and now + 5 or nil }
  end
  return match.key, match.how
end

function ns.talentPath()
  return pathByKey((ns.talentPathKey()))
end

function ns.setTalentPath(key)
  if not pathByKey(key) then return false end
  LevelingCodexCharDB = LevelingCodexCharDB or {}
  LevelingCodexCharDB.talentPath = key
  bump()
  return true
end

local planCache = { version = -1 }
function ns.talentPlan()
  local key = ns.talentPathKey()
  local custom = ns.charDB().customTalents
  if planCache.version == ns.talentVersion and planCache.key == key and planCache.D == ns.D
    and planCache.custom == custom and planCache.n == (type(custom) == "table" and #custom or 0) then
    return planCache.plan
  end
  local p = pathByKey(key)
  local plan = (p and p.custom) and planFrom(ns.customPoints()) or (p and p.plan) or (ns.D and ns.D.plan) or {}
  custom = ns.charDB().customTalents
  planCache = { version = ns.talentVersion, key = key, D = ns.D, custom = custom,
    n = type(custom) == "table" and #custom or 0, plan = plan }
  return plan
end

-- A custom path with no point for this level yet (the displays say "plan it" instead of a talent).
function ns.talentUnplanned(level)
  local p = ns.talentPath()
  return (p and p.custom and level >= FIRST and level <= LAST and level - FIRST + 1 > #ns.customPoints()) and true or false
end

-- Points per tree (in the tree's order) a plan has by `level` (60 when nil).
function ns.talentSplit(plan, level)
  local tree = ns.talentTree()
  local out = { 0, 0, 0 }
  if not tree then return out end
  level = level or LAST
  for _, p in ipairs(plan or {}) do
    for i, tab in ipairs(tree.tabs) do
      if tab == p.tree then out[i] = out[i] + math.max(0, math.min(p.to, level) - p.from + 1) end
    end
  end
  return out
end

----------------------------------------------------------------------------
-- Share codes: LC1-<CLASS>-<tree check>-<runs of (talent, count)>
----------------------------------------------------------------------------

local B36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function b36(n, width)
  local s = ""
  for _ = 1, width do
    local d = n % 36
    s = B36:sub(d + 1, d + 1) .. s
    n = math.floor(n / 36)
  end
  return s
end
local function unb36(s)
  local n = 0
  for i = 1, #s do
    local d = B36:find(s:sub(i, i), 1, true)
    if not d then return nil end
    n = n * 36 + d - 1
  end
  return n
end

-- Four characters that change when the class's talents change, so an old code is refused, not misread.
local function treeCheck(tree)
  local h = 0
  for _, t in ipairs(tree.talents) do
    for i = 1, #t.name do h = (h * 31 + t.name:byte(i)) % 1679616 end
  end
  return b36(h, 4)
end

local function className(token)
  local names = type(LOCALIZED_CLASS_NAMES_MALE) == "table" and LOCALIZED_CLASS_NAMES_MALE
  return (names and names[token]) or (token:sub(1, 1) .. token:sub(2):lower())
end

function ns.talentCode()
  local tree = ns.talentTree()
  if not tree then return nil end
  local _, pos = index(tree)
  local points, runs, i = ns.customPoints(), {}, 1
  while i <= #points do
    local j = i
    while j < #points and points[j + 1] == points[i] and j - i + 1 < 35 do j = j + 1 end
    runs[#runs + 1] = b36(pos[points[i]], 2) .. b36(j - i + 1, 1)
    i = j + 1
  end
  return "LC1-" .. classToken() .. "-" .. treeCheck(tree) .. "-" .. table.concat(runs)
end

-- Read a pasted code into your custom path (and choose it). ok, or false and why (nothing changes).
function ns.readTalentCode(text)
  local tree = ns.talentTree()
  if not tree then return false, "No talent tree for your class" end
  local s = string.upper((string.gsub(tostring(text or ""), "%s", "")))
  local cls, check, runs = s:match("^LC1%-(%u+)%-(%w%w%w%w)%-(%w*)$")
  if not cls or #runs % 3 ~= 0 then return false, "Not a Leveling Codex talent code" end
  if cls ~= classToken() then return false, "This code is for a " .. className(cls) end
  if check ~= treeCheck(tree) then return false, "This code was made for other talent trees" end
  local points = {}
  for k = 1, #runs, 3 do
    local idx, n = unb36(runs:sub(k, k + 1)), unb36(runs:sub(k + 2, k + 2))
    local t = idx and tree.talents[idx]
    if not t or not n or n < 1 then return false, "Not a Leveling Codex talent code" end
    for _ = 1, n do
      local ok, why = ns.talentCanAdd(points, t.name)
      if not ok then return false, "Level " .. (FIRST + #points) .. ": " .. why end
      points[#points + 1] = t.name
    end
  end
  saveCustom(points)
  ns.setTalentPath("custom")
  return true
end

----------------------------------------------------------------------------
-- The trainer list for your path
----------------------------------------------------------------------------

-- Data.lua's trainer visits with talent spells your path never takes removed, and the ranks of talent
-- spells it takes added or moved to when the path has the talent (the later of the rank's level and
-- the level you take the talent). spells, notes and icons stay parallel.
local trainCache = {}
function ns.trainVisits()
  local D = ns.D
  if not D then return {} end
  local p = ns.talentPath()
  if not p or p.guide or not ns.talentTree() then return D.train end
  local plan = ns.talentPlan()
  if trainCache.plan == plan and trainCache.D == D then return trainCache.list end
  local byName = index(ns.talentTree())
  local first, order = {}, {}
  for _, e in ipairs(plan) do
    if not first[e.name] then order[#order + 1] = e.name end
    first[e.name] = math.min(first[e.name] or e.from, e.from)
  end
  local byLevel, levels, present = {}, {}, {}
  local function add(level, spell, note, icon)
    local v = byLevel[level]
    if not v then
      v = { level = level, spells = {}, notes = {}, icons = {} }
      byLevel[level] = v
      levels[#levels + 1] = level
    end
    v.spells[#v.spells + 1], v.notes[#v.notes + 1], v.icons[#v.icons + 1] = spell, note or "", icon or "inv_misc_questionmark"
    present[spell] = true
  end
  for _, visit in ipairs(D.train) do
    for k, spell in ipairs(visit.spells) do
      local base, rank = spell:match("^(.-)%s*%(Rank (%d+)%)%s*$")
      base, rank = base or spell, tonumber(rank)
      local t, level = byName[base], visit.level
      if t then
        local at = first[base]
        if at then
          local want = at
          for _, r in ipairs(t.spell) do
            if rank and r[1] == rank then want = math.max(r[2], at) end
          end
          add(math.max(level, want), spell, visit.notes and visit.notes[k], visit.icons and visit.icons[k])
        end
      else
        add(level, spell, visit.notes and visit.notes[k], visit.icons and visit.icons[k])
      end
    end
  end
  for _, name in ipairs(order) do
    local t = byName[name]
    if t and #t.spell > 0 then
      local at = first[name]
      local r1 = name .. " (Rank 1)"
      if not present[r1] then add(at, r1, "From your talent point.", t.icon) end
      for _, r in ipairs(t.spell) do
        local s = name .. " (Rank " .. r[1] .. ")"
        if not present[s] then add(math.max(r[2], at), s, "New rank of your " .. name .. " talent.", t.icon) end
      end
    end
  end
  table.sort(levels)
  local list = {}
  for _, l in ipairs(levels) do list[#list + 1] = byLevel[l] end
  trainCache = { plan = plan, D = D, list = list }
  return list
end

----------------------------------------------------------------------------
-- Talent changes in the game: match the path again (only matters without a saved choice)
----------------------------------------------------------------------------

local watcher = CreateFrame("Frame")
for _, ev in ipairs({ "TRAIT_CONFIG_UPDATED", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE" }) do
  pcall(watcher.RegisterEvent, watcher, ev)
end
watcher:SetScript("OnEvent", function() bump() end)

-- For /codex debug.
function ns.talentPathDebugLines()
  local key, how = ns.talentPathKey()
  return { "talent path: " .. tostring(key) .. " (" .. tostring(how) .. "), custom points: " .. #ns.customPoints() }
end
