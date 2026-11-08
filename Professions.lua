-- Professions.lua: the profession guides (ProfessionData.lua): your skill, the step for it, craft
-- counts and the shopping list, training tiers, and which veins you can mine where.
-- Everything copes with no data, a profession you don't have, and a client without the
-- profession APIs (the skill then reads as unknown).

local _, ns = ...

ns.P = LevelingCodexProfessions
ns.PROF_ORDER = { "BLACKSMITHING", "MINING" }

-- Where skills come from: retail's GetProfessions, else the classic skill list.
local function skillSource()
  if GetProfessions and GetProfessionInfo then return "professions" end
  if GetNumSkillLines and GetSkillLineInfo then return "skill lines" end
  return "nothing"
end

local function readSkill(name)
  if GetProfessions and GetProfessionInfo then
    local got = { pcall(GetProfessions) }
    if got[1] then
      for k = 2, 6 do
        local i = got[k]
        if i then
          local ok, n, _, rank, max = pcall(GetProfessionInfo, i)
          if ok and n == name and tonumber(rank) then return tonumber(rank), tonumber(max) end
        end
      end
    end
  end
  if GetNumSkillLines and GetSkillLineInfo then
    local ok, count = pcall(GetNumSkillLines)
    for i = 1, (ok and tonumber(count)) or 0 do
      local ok2, n, isHeader, _, rank, _, _, max = pcall(GetSkillLineInfo, i)
      if ok2 and n == name and not isHeader and tonumber(rank) then return tonumber(rank), tonumber(max) end
    end
  end
end

-- Your skill and its cap (nil when you don't have the profession or the client won't say).
function ns.profSkill(key)
  local P = ns.P and ns.P[key]
  if not P then return end
  local rank, max = readSkill(P.name)
  if rank and rank > 0 then return rank, (max and max > 0) and max or nil end
end

-- The step for a skill (nil before 1 and at 300 or above), and its index.
function ns.profStep(key, skill)
  local P = ns.P and ns.P[key]
  if not (P and skill) then return end
  for i, s in ipairs(P.steps) do
    if skill >= s.from and skill < s.to then return s, i end
  end
end

function ns.profNext(key, skill)
  local P = ns.P and ns.P[key]
  if not (P and skill) then return end
  for _, s in ipairs(P.steps) do
    if s.from > skill then return s end
  end
end

-- Expected crafts from a skill to the step's end: one per point below yellow, then the game's
-- chance (grey - skill) / (grey - yellow). math.huge if the recipe goes grey first; nil for a
-- step that isn't a craft (Mining).
function ns.expectedCrafts(step, fromSkill)
  if not (step and step.yellow and step.grey) then return nil end
  local total = 0
  for s = math.max(fromSkill or step.from, step.from), step.to - 1 do
    if s >= step.grey then return math.huge end
    total = total + ((s < step.yellow) and 1 or (step.grey - step.yellow) / (step.grey - s))
  end
  return total
end

-- "about N" as the guide says it (whole crafts, rounded up).
function ns.craftsLeft(step, fromSkill)
  local n = ns.expectedCrafts(step, fromSkill)
  if not n or n == math.huge then return nil end
  return math.ceil(n - 1e-9)
end

-- Every material from this skill to 300: { { item, count }, ... }, most first.
function ns.profShopping(key, skill)
  local P = ns.P and ns.P[key]
  local list = {}
  if not P then return list end
  local byItem = {}
  for _, s in ipairs(P.steps) do
    if s.to > (skill or 0) and s.mats then
      local n = ns.craftsLeft(s, skill) or 0
      for _, m in ipairs(s.mats) do
        if not byItem[m[1]] then byItem[m[1]] = { m[1], 0 }; list[#list + 1] = byItem[m[1]] end
        byItem[m[1]][2] = byItem[m[1]][2] + n * m[2]
      end
    end
  end
  for i = #list, 1, -1 do if list[i][2] <= 0 then table.remove(list, i) end end
  table.sort(list, function(a, b)
    if a[2] ~= b[2] then return a[2] > b[2] end
    return a[1] < b[1]
  end)
  return list
end

-- The tier you've trained: the one with your cap when the client tells it, else the lowest
-- tier that allows your skill.
function ns.profTier(key, skill, cap)
  local P = ns.P and ns.P[key]
  if not P then return end
  if cap then
    for i, t in ipairs(P.tiers) do if t.cap == cap then return t, i end end
  end
  for i, t in ipairs(P.tiers) do
    if t.cap >= (skill or 1) and (not cap or t.cap >= cap) then return t, i end
  end
  return P.tiers[#P.tiers], #P.tiers
end

-- "train" (the next tier can be learned now), "cap" (you're at your cap and can't train past it
-- yet) or nil, and the next tier.
function ns.profTierDue(key, skill, cap, level)
  local P = ns.P and ns.P[key]
  if not (P and skill) then return end
  local trained, i = ns.profTier(key, skill, cap)
  local nextTier = trained and P.tiers[i + 1]
  if not nextTier then return end
  if skill >= nextTier.skill and (level or 1) >= nextTier.level then return "train", nextTier end
  if skill >= trained.cap then return "cap", nextTier end
end

-- Each vein's colour at a skill: red (can't mine yet), orange, yellow, green or grey.
function ns.veinColor(vein, skill)
  skill = skill or 0
  if skill < vein.skill then return "red" end
  if skill < vein.skill + 25 then return "orange" end
  if skill < vein.skill + 50 then return "yellow" end
  if skill < vein.skill + 100 then return "green" end
  return "grey"
end

function ns.veinsFor(skill)
  local list = {}
  local M = ns.P and ns.P.MINING
  if not M then return list end
  for _, v in ipairs(M.veins) do list[#list + 1] = { vein = v, color = ns.veinColor(v, skill) } end
  return list
end

function ns.veinNamed(name)
  local M = ns.P and ns.P.MINING
  for _, v in ipairs(M and M.veins or {}) do if v.name == name then return v end end
end

function ns.profFaction()
  if not UnitFactionGroup then return end
  local ok, f = pcall(UnitFactionGroup, "player")
  if ok and (f == "Alliance" or f == "Horde") then return f end
end

-- Zones for a vein: both factions' (All), else your faction's (both when unknown), plus the
-- Skyborne starting isle for Skyborne characters.
function ns.profZones(vein)
  local out, seen = {}, {}
  local function add(list)
    for _, z in ipairs(list or {}) do
      if not seen[z] then seen[z] = true; out[#out + 1] = z end
    end
  end
  local z = vein.zones or {}
  local race
  if UnitRace then
    local ok, _, file = pcall(UnitRace, "player")
    if ok then race = file end
  end
  if race == "Skyborne" then add(z.Skyborne) end
  if z.All then add(z.All) end
  local f = ns.profFaction()
  if f then add(z[f]) else add(z.Alliance); add(z.Horde) end
  return out
end

-- Skills seen this session (nothing is saved): the skill-up card compares against these.
local last = {}

-- What a skill-up from old to new brings, as card rows { icon, label, text }: the step you're now
-- in (and any you jumped over), training that just opened, a cap you just hit, new veins.
function ns.profCardRows(key, old, new, cap, level)
  local rows = {}
  local P = ns.P and ns.P[key]
  if not (P and old and new and new > old) then return rows end
  for _, s in ipairs(P.steps) do
    if s.from > old and s.from <= new then
      local now = new < s.to
      if s.name then
        local n = ns.craftsLeft(s, new)
        rows[#rows + 1] = { s.icon, now and "NEW STEP" or "STEP PASSED",
          s.name .. (now and n and ("  -  about " .. n .. " to " .. s.to) or ("  (" .. s.from .. "-" .. s.to .. ")")) }
      else
        local v = s.veins and ns.veinNamed(s.veins[1])
        rows[#rows + 1] = { v and v.icon or P.icon, now and "NEW STEP" or "STEP PASSED", s.title }
      end
    end
  end
  local trained, i = ns.profTier(key, new, cap)
  local nextTier = trained and P.tiers[i + 1]
  if nextTier and nextTier.skill > old and nextTier.skill <= new and (level or 1) >= nextTier.level then
    rows[#rows + 1] = { P.icon, "TRAIN " .. string.upper(nextTier.name), ns.plain(nextTier.where) }
  end
  if nextTier and trained.cap > old and trained.cap <= new then
    rows[#rows + 1] = { P.icon, "AT YOUR CAP", "Train " .. nextTier.name .. " to go past " .. trained.cap }
  end
  for _, v in ipairs(P.veins or {}) do
    if v.skill > old and v.skill <= new then
      rows[#rows + 1] = { v.icon, "NEW VEIN", v.name .. " (" .. v.skill .. ")" }
    end
  end
  return rows
end

-- Compare every guided profession with the last reading; show a card when something changed.
local function checkSkills()
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    local new, cap = ns.profSkill(key)
    local old = last[key]
    last[key] = new
    if P and new and old and new > old then
      local rows = ns.profCardRows(key, old, new, cap, UnitLevel("player"))
      local db = ns.db()
      if #rows > 0 and not db.noProfCards then
        ns.showCard(P.name .. " " .. new, "Profession guide", rows, function()
          if ns.profTabShow then ns.profTabShow(key) end
          ns.openTab("professions")
        end)
        if not db.quiet then ns.say(P.name .. " " .. new .. ": " .. ns.plain(rows[1][3])) end
      end
    end
  end
end

local events
function ns.startProfessions()
  for _, key in ipairs(ns.PROF_ORDER) do last[key] = ns.profSkill(key) end
  if events then return end
  events = CreateFrame("Frame")
  local any = false
  for _, ev in ipairs({ "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "TRADE_SKILL_UPDATE" }) do
    if pcall(events.RegisterEvent, events, ev) then any = true end
  end
  events:SetScript("OnEvent", function()
    local ok, err = pcall(checkSkills)
    if not ok and not events.errored then events.errored = true; ns.say("profession guide error: " .. ns.plain(err)) end
  end)
  -- no skill events in this client: look once a second instead
  if not any then ns.every(1, function() pcall(checkSkills) end) end
end

-- For /codex debug.
function ns.profDebugLines()
  local out = {}
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    if P then
      local skill, cap = ns.profSkill(key)
      if not skill then
        out[#out + 1] = "profession: " .. P.name .. " not learned"
      else
        local s = ns.profStep(key, skill)
        local line = "profession: " .. P.name .. " " .. skill .. "/" .. (cap or "?")
        if s then
          line = line .. ", step " .. s.from .. "-" .. s.to .. " " .. (s.name or s.title)
          local n = ns.craftsLeft(s, skill)
          if n then line = line .. ", about " .. n .. " more" end
        else
          line = line .. ", route done"
        end
        out[#out + 1] = line
      end
    end
  end
  out[#out + 1] = "profession skills read from: " .. skillSource()
  return out
end
