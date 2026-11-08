-- Professions.lua: the profession guides (ProfessionData.lua): your skill, the step for it, craft
-- counts and the shopping list, training tiers, and which veins you can mine where.
-- Everything copes with no data, a profession you don't have, and a client without the
-- profession APIs (the skill then reads as unknown).

local _, ns = ...

ns.P = LevelingCodexProfessions
ns.PROF_ORDER = { "BLACKSMITHING", "MINING", "TAILORING" }

-- Parts: items a profession makes for its own recipes (Tailoring's bolts). The part that makes item.
function ns.profPart(key, item)
  local P = ns.P and ns.P[key]
  for _, p in ipairs((P and P.parts) or {}) do
    if p.makes and p.makes[1] == item then return p end
  end
end

local function bagCount(item)
  if not GetItemCount then return nil end
  local ok, n = pcall(GetItemCount, item)
  return ok and tonumber(n) or nil
end

-- How much of item you hold, counting the parts made from it (a held Bolt of Mageweave counts as
-- 5 Mageweave Cloth). nil when the client can't count items.
function ns.profHave(key, item)
  local n = bagCount(item)
  if not n then return nil end
  local P = ns.P and ns.P[key]
  for _, p in ipairs((P and P.parts) or {}) do
    for _, m in ipairs(p.mats or {}) do
      if m[1] == item then n = n + (bagCount(p.makes[1]) or 0) * m[2] / (p.makes[2] or 1) end
    end
  end
  return math.floor(n)
end

-- The cloth a step uses: one named in its materials, else the first material of the first part it uses.
function ns.profClothFor(key, step)
  local P = ns.P and ns.P[key]
  if not (P and P.cloth and step) then return nil end
  local names = {}
  for _, c in ipairs(P.cloth) do names[c.name] = true end
  for _, m in ipairs(step.mats or {}) do if names[m[1]] then return m[1] end end
  for _, m in ipairs(step.mats or {}) do
    local part = ns.profPart(key, m[1])
    if part and part.mats and part.mats[1] then return part.mats[1][1] end
  end
end

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
    local hidden = false
    for i = 1, (ok and tonumber(count)) or 0 do
      local ok2, n, isHeader, isExpanded, rank, _, _, max = pcall(GetSkillLineInfo, i)
      if ok2 and n == name and not isHeader and tonumber(rank) then return tonumber(rank), tonumber(max) end
      if ok2 and isHeader and not isExpanded then hidden = true end
    end
    -- a closed heading hides the lines under it: the skill may be there
    return nil, nil, hidden
  end
end

-- The last skill read this session, for while a closed heading hides it.
local seen = {}

-- Your skill and its cap (nil when you don't have the profession or the client won't say).
-- A third value, true, means the skill list has a closed heading and nothing was seen before.
function ns.profSkill(key)
  local P = ns.P and ns.P[key]
  if not P then return end
  local rank, max, hidden = readSkill(P.name)
  if rank and rank > 0 then
    seen[key] = { rank, (max and max > 0) and max or nil }
  elseif hidden then
    if not seen[key] then return nil, nil, true end
  else
    seen[key] = nil
  end
  if seen[key] then return seen[key][1], seen[key][2] end
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

-- Every material from this skill to 300: { { item, count }, ... }, most first. Things the route
-- makes itself (Heavy Grinding Stones) only count where it doesn't make enough, and a step's
-- extra (the Thorium Bars a quest takes for its plan) counts until that step starts. Parts never
-- show: what's still needed is counted as their materials, and those rows carry
-- via = { part = name, n = parts still to make (the parts' own steps included) }.
function ns.profShopping(key, skill)
  local P = ns.P and ns.P[key]
  local list = {}
  if not P then return list end
  local byItem, made, partMade = {}, {}, {}
  local function add(item, n)
    if n <= 0 then return end
    if not byItem[item] then byItem[item] = { item, 0 }; list[#list + 1] = byItem[item] end
    byItem[item][2] = byItem[item][2] + n
  end
  for _, s in ipairs(P.steps) do
    if s.to > (skill or 0) and s.mats then
      local n = ns.craftsLeft(s, skill) or 0
      for _, m in ipairs(s.mats) do
        local need = n * m[2]
        local own = math.min(made[m[1]] or 0, need)
        made[m[1]] = (made[m[1]] or 0) - own
        add(m[1], need - own)
      end
      if s.makes then
        made[s.makes[1]] = (made[s.makes[1]] or 0) + n * s.makes[2]
        partMade[s.makes[1]] = (partMade[s.makes[1]] or 0) + n * s.makes[2]
      end
      if (skill or 0) < s.from then
        for _, m in ipairs(s.extra or {}) do add(m[1], m[2]) end
      end
    end
  end
  for _, p in ipairs(P.parts or {}) do
    local item = p.makes and p.makes[1]
    local row = item and byItem[item]
    local left = row and math.max(row[2], 0) or 0
    if row then row[2] = 0 end
    local crafts = math.ceil(left / ((p.makes and p.makes[2]) or 1))
    for _, m in ipairs(p.mats or {}) do add(m[1], crafts * m[2]) end
    local total = left + (partMade[item] or 0)
    if total > 0 then
      for _, m in ipairs(p.mats or {}) do
        if byItem[m[1]] then byItem[m[1]].via = { part = p.name, n = total } end
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
    rows[#rows + 1] = { P.icon, "TRAIN " .. string.upper(nextTier.name), ns.plain(nextTier.short or nextTier.where) }
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

-- Training this level-up opens: your skill was already there, the level was the wait. Rows for
-- the level-up banner, { icon, label, text, profession name, tier }.
function ns.profLevelRows(level)
  local rows = {}
  if ns.db().noProfCards then return rows end
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    local skill, cap = ns.profSkill(key)
    local due, nextTier = ns.profTierDue(key, skill, cap, level)
    if P and due == "train" and nextTier.level == level then
      rows[#rows + 1] = { P.icon, "TRAIN " .. string.upper(nextTier.name .. " " .. P.name), ns.plain(nextTier.short or nextTier.where),
        P.name, nextTier }
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
        local tier = ns.profTier(key, new, cap)
        ns.showCard(P.name .. " " .. new, tier and (tier.name .. " " .. P.name) or P.name, rows, function()
          if ns.profTabShow then ns.profTabShow(key) end
          ns.openTab("professions")
        end, { tab = "professions", key = key })
        if not db.quiet then ns.say(P.name .. " " .. new .. ": " .. ns.plain(rows[1][3])) end
      end
    end
  end
end

-- The skill a trainer really asks for each route recipe, where it differs from the guide's
-- learn level (that's server-side, so the guide's values come from guide sites).
local trainerSeen, trainerDiff = false, {}

local function guideLearn(skillName, recipe)
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    if P and P.name == skillName then
      for _, s in ipairs(P.steps) do if s.name == recipe then return s.learn end end
      for _, s in ipairs(P.smelt or {}) do if s.name == recipe then return s.learn end end
    end
  end
end

local function readTrainer()
  if not (GetNumTrainerServices and GetTrainerServiceInfo and GetTrainerServiceSkillReq) then return end
  trainerSeen = true
  local ok, count = pcall(GetNumTrainerServices)
  for i = 1, (ok and tonumber(count)) or 0 do
    local iok, name = pcall(GetTrainerServiceInfo, i)
    local rok, skillName, skillLevel = pcall(GetTrainerServiceSkillReq, i)
    local learn = iok and rok and guideLearn(skillName, name)
    if learn then
      skillLevel = tonumber(skillLevel)
      trainerDiff[name] = (skillLevel and skillLevel ~= learn) and { name, skillLevel, learn } or nil
    end
  end
end

function ns.trainerDebugLines()
  if not trainerSeen then return { "trainer: not visited this session" } end
  local out = {}
  for _, d in pairs(trainerDiff) do out[#out + 1] = "trainer: " .. d[1] .. " needs " .. d[2] .. " (guide says " .. d[3] .. ")" end
  table.sort(out)
  if #out == 0 then out[1] = "trainer: no differences from the guide seen" end
  return out
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
  pcall(events.RegisterEvent, events, "TRAINER_SHOW")
  events:SetScript("OnEvent", function(_, event)
    local ok, err = pcall(event == "TRAINER_SHOW" and readTrainer or checkSkills)
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
      local skill, cap, hidden = ns.profSkill(key)
      if not skill then
        out[#out + 1] = "profession: " .. P.name .. (hidden and " not seen: a heading in the skill list is closed" or " not learned")
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
