-- Professions.lua: the profession guides (ProfessionData.lua): your skill, the step for it, craft
-- counts and the shopping list, training tiers, and which veins you can mine where.
-- Everything copes with no data, a profession you don't have, and a client without the
-- profession APIs (the skill then reads as unknown).

local _, ns = ...

ns.P = LevelingCodexProfessions
ns.PROF_ORDER = { "BLACKSMITHING", "MINING", "TAILORING", "ENCHANTING", "HERBALISM", "SKINNING", "LEATHERWORKING" }

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

-- Rods (Enchanting): the rod a step needs, or nil.
function ns.profRod(key, step)
  local P = ns.P and ns.P[key]
  if not (P and P.rods and step and step.rod) then return nil end
  for _, r in ipairs(P.rods) do if r.name == step.rod then return r end end
end

-- Every bit of need set in have (masks without the bit library: a better rod's mask holds the lower ones').
local function hasBits(have, need)
  local p = 1
  while p <= need do
    if math.floor(need / p) % 2 == 1 and math.floor(have / p) % 2 ~= 1 then return false end
    p = p * 2
  end
  return true
end

-- That rod, or a better one, in your bags; nil when the client can't count items.
function ns.profHasRod(key, rod)
  local P = ns.P and ns.P[key]
  if not (P and P.rods and rod) or not bagCount(rod.name) then return nil end
  for _, r in ipairs(P.rods) do
    if (bagCount(r.name) or 0) > 0 and hasBits(r.mask or 0, rod.mask or 0) then return true end
  end
  return false
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

local function readProfessions(skills)
  if not (GetProfessions and GetProfessionInfo) then return false end
  local slots = { pcall(GetProfessions) }
  if not slots[1] then return false end
  local complete = true
  for i = 2, 6 do
    if slots[i] then
      local ok, name, _, rank, cap = pcall(GetProfessionInfo, slots[i])
      rank, cap = tonumber(rank), tonumber(cap)
      if ok and name and rank then
        if rank > 0 then skills[name] = { rank = rank, cap = cap and cap > 0 and cap or nil } end
      else
        complete = false
      end
    end
  end
  return complete
end

local function readSkillLines(skills)
  if not (GetNumSkillLines and GetSkillLineInfo) then return false end
  local ok, count = pcall(GetNumSkillLines)
  count = ok and tonumber(count)
  if not count then return false end
  local complete, professionHeading = true, false
  local professionHidden, otherHidden = false, false
  for i = 1, count do
    local read, name, header, expanded, rank, _, _, cap = pcall(GetSkillLineInfo, i)
    rank, cap = tonumber(rank), tonumber(cap)
    if not (read and name) then
      complete = false
    elseif header then
      if name == "Professions" or name == PROFESSIONS then
        professionHeading = true
        if not expanded then professionHidden = true end
      elseif not expanded then
        otherHidden = true
      end
    elseif not rank then
      complete = false
    elseif rank > 0 and not skills[name] then
      skills[name] = { rank = rank, cap = cap and cap > 0 and cap or nil }
    end
  end
  local hidden = professionHidden or (not professionHeading and otherHidden)
  return complete and not hidden, hidden
end

-- Last confirmed skills for when the classic Skills list hides them.
local seen = {}

function ns.profSkillSnapshot()
  local skills, snapshot = {}, {}
  local retailComplete = readProfessions(skills)
  local classicComplete, hidden = readSkillLines(skills)
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    if P then
      local reading = skills[P.name]
      if reading then
        seen[key] = reading
      elseif retailComplete or classicComplete then
        seen[key] = nil
        reading = {}
      elseif hidden then
        reading = seen[key] or { hidden = true }
      else
        reading = { unavailable = true }
      end
      snapshot[key] = reading
    end
  end
  return snapshot
end

-- Rank and cap, or the reason a rank could not be read.
function ns.profSkill(key)
  local reading = ns.profSkillSnapshot()[key]
  if reading then return reading.rank, reading.cap, reading.hidden, reading.unavailable end
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
  -- a part that needs a rod can't be made for the step that makes that rod: keep it as a row to buy
  local rodPart, keep = {}, {}
  for _, p in ipairs(P.parts or {}) do
    if p.rod and p.makes then rodPart[p.rod] = p.makes[1] end
  end
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
        if rodPart[s.name] == m[1] then keep[m[1]] = (keep[m[1]] or 0) + need - own end
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
    local left = row and math.max(row[2] - (keep[item] or 0), 0) or 0
    if row then row[2] = 0 end
    local crafts = math.ceil(left / ((p.makes and p.makes[2]) or 1))
    for _, m in ipairs(p.mats or {}) do add(m[1], crafts * m[2]) end
    local total = left + (partMade[item] or 0)
    if total > 0 then
      for _, m in ipairs(p.mats or {}) do
        if byItem[m[1]] then byItem[m[1]].via = { part = p.name, made = item, n = total } end
      end
    end
  end
  for item, n in pairs(keep) do add(item, n) end
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

-- Herbs specify their own cutoffs. Veins use the standard mining intervals.
function ns.profNodeColor(node, skill)
  skill = skill or 0
  if skill < node.skill then return "red" end
  if skill < (node.yellow or node.skill + 25) then return "orange" end
  if skill < (node.green or node.skill + 50) then return "yellow" end
  if skill < (node.grey or node.skill + 100) then return "green" end
  return "grey"
end

function ns.profNode(key, name)
  local P = ns.P and ns.P[key]
  for _, node in ipairs(P and (P.herbs or P.veins) or {}) do
    if node.name == name then return node end
  end
end

function ns.profFaction()
  if not UnitFactionGroup then return end
  local ok, f = pcall(UnitFactionGroup, "player")
  if ok and (f == "Alliance" or f == "Horde") then return f end
end

-- Zones for a gathering node: both factions' (All), else your faction's (both when unknown), plus the
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
-- in (and any you jumped over), training that just opened, a cap you just hit, new nodes.
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
        local names = s.herbs or s.veins
        local node = names and ns.profNode(key, names[1])
        rows[#rows + 1] = { s.icon or (node and node.icon) or P.icon, now and "NEW STEP" or "STEP PASSED", s.title }
      end
    end
  end
  local trained, i = ns.profTier(key, new, cap)
  local nextTier = trained and P.tiers[i + 1]
  if nextTier and nextTier.skill > old and nextTier.skill <= new and (level or 1) >= nextTier.level then
    local label = P.levelGatesUnconfirmed and "CHECK " or "TRAIN "
    rows[#rows + 1] = { P.icon, label .. string.upper(nextTier.name), ns.plain(nextTier.short or nextTier.where) }
  end
  if nextTier and trained.cap > old and trained.cap <= new then
    rows[#rows + 1] = { P.icon, "AT YOUR CAP", "Train " .. nextTier.name .. " to go past " .. trained.cap }
  end
  local unlock = P.herbs and "NEW HERB" or "NEW VEIN"
  for _, node in ipairs(P.herbs or P.veins or {}) do
    if node.skill > old and node.skill <= new then
      rows[#rows + 1] = { node.icon, unlock, node.name .. " (" .. node.skill .. ")" }
    end
  end
  return rows
end

-- Training this level-up opens: your skill was already there, the level was the wait. Rows for
-- the level-up banner, { icon, label, text, profession name, tier }.
function ns.profLevelRows(level)
  local rows = {}
  if ns.db().noProfCards then return rows end
  local snapshot = ns.profSkillSnapshot()
  for _, key in ipairs(ns.PROF_ORDER) do
    local reading = snapshot[key]
    if reading then
      local due, nextTier = ns.profTierDue(key, reading.rank, reading.cap, level)
      if due == "train" and nextTier.level == level then
        local P = ns.P[key]
        rows[#rows + 1] = { P.icon, "TRAIN " .. string.upper(nextTier.name .. " " .. P.name), ns.plain(nextTier.short or nextTier.where),
          P.name, nextTier }
      end
    end
  end
  return rows
end

-- Compare every guided profession with the last reading; show a card when something changed.
local function checkSkills()
  local snapshot = ns.profSkillSnapshot()
  for _, key in ipairs(ns.PROF_ORDER) do
    local current, before = snapshot[key], last[key]
    local new, cap, old = current and current.rank, current and current.cap, before and before.rank
    if new and old and new > old then
      local P = ns.P[key]
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
  last = snapshot
  if ns.profTabSkillsChanged then ns.profTabSkillsChanged(snapshot) end
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
  last = ns.profSkillSnapshot()
  if events then return end
  events = CreateFrame("Frame")
  local any = false
  for _, ev in ipairs({ "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "TRADE_SKILL_UPDATE" }) do
    if pcall(events.RegisterEvent, events, ev) then any = true end
  end
  pcall(events.RegisterEvent, events, "LEARNED_SPELL_IN_TAB")
  pcall(events.RegisterEvent, events, "SPELLS_CHANGED")
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
  local snapshot = ns.profSkillSnapshot()
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    if P then
      local reading = snapshot[key]
      local skill, cap = reading.rank, reading.cap
      if not skill then
        local status = "not learned"
        if reading.hidden then status = "not seen: a heading in the skill list is closed" end
        if reading.unavailable then status = "skill data unavailable" end
        out[#out + 1] = "profession: " .. P.name .. " " .. status
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
