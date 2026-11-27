-- Professions.lua: the profession guides (ProfessionData.lua): your skill, the step for it, craft
-- counts and the shopping list, training tiers, and which veins you can mine where.
-- Everything copes with no data, a profession you don't have, and a client without the
-- profession APIs (the skill then reads as unknown).

local _, ns = ...

ns.P = LevelingCodexProfessions
ns.PROF_ORDER = { "BLACKSMITHING", "MINING", "TAILORING", "ENCHANTING", "HERBALISM", "SKINNING", "LEATHERWORKING", "ALCHEMY",
  "ENGINEERING", "FIRST_AID", "COOKING", "FISHING" }

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

-- Units of a part its raw materials can produce, limited by the scarcest reagent.
function ns.profPartAvailable(part)
  local crafts
  for _, m in ipairs(part.mats) do
    local have = bagCount(m[1])
    if have == nil then return nil end
    local n = math.floor(have / m[2])
    crafts = math.min(crafts or n, n)
  end
  return crafts and crafts * part.makes[2]
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
  -- The first slot holds pcall's result. Clients with First Aid can return six profession slots.
  for i = 2, 7 do
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

-- Expected crafts from a skill to the step's end (or toSkill when that comes first): one per point
-- below yellow, then the game's chance (grey - skill) / (grey - yellow). math.huge if the recipe
-- goes grey first; nil for a step that isn't a craft (Mining).
function ns.expectedCrafts(step, fromSkill, toSkill)
  if not (step and step.yellow and step.grey) then return nil end
  local total = 0
  for s = math.max(fromSkill or step.from, step.from), math.min(step.to, toSkill or step.to) - 1 do
    if s >= step.grey then return math.huge end
    total = total + ((s < step.yellow) and 1 or (step.grey - step.yellow) / (step.grey - s))
  end
  return total
end

-- "about N" as the guide says it (whole crafts, rounded up).
function ns.craftsLeft(step, fromSkill, toSkill)
  local n = ns.expectedCrafts(step, fromSkill, toSkill)
  if not n or n == math.huge then return nil end
  return math.ceil(n - 1e-9)
end

-- Where the shopping list's "To your cap" stops: your cap, or the next tier's once you're at it
-- (nil when that is 300 anyway or the skill is unknown), and whether that is your cap or the next.
function ns.profShopLimit(key, skill, cap)
  local P = ns.P and ns.P[key]
  if not (P and skill) then return nil end
  local trained, i = ns.profTier(key, skill, cap)
  local limit, which = cap or (trained and trained.cap), "cap"
  if limit and skill >= limit then
    local nextTier = P.tiers[(i or #P.tiers) + 1]
    limit, which = nextTier and nextTier.cap, "next"
  end
  if not limit or limit >= 300 then return nil end
  return limit, which
end

-- Every material from this skill to 300: { { item, count }, ... }, most first. Things the route
-- makes itself (Heavy Grinding Stones) only count where it doesn't make enough, and a step's
-- extra (the Thorium Bars a quest takes for its plan) counts until that step starts. Parts never
-- show: what's still needed is counted as their materials, and those rows carry
-- via = { part = name, n = parts still to make, raw = units of this material used for them }.
-- upto (optional) stops the count at that skill: steps past it drop out, a step that crosses it
-- counts its crafts to it, and a tier's materials count when that tier opens by then.
function ns.profShopping(key, skill, cap, upto)
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
    if s.to > (skill or 0) and s.mats and (not upto or s.from < upto) then
      local n = ns.craftsLeft(s, skill, upto) or 0
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
  -- Rank quest materials stay on the list until the skill cap rises.
  local _, trained = ns.profTier(key, skill, cap)
  for i = trained + 1, #P.tiers do
    if not upto or P.tiers[i].skill <= upto then
      for _, m in ipairs(P.tiers[i].mats or {}) do add(m[1], m[2]) end
    end
  end
  -- A part that uses another part must come first so its demand reaches the later recipe.
  for _, p in ipairs(P.parts or {}) do
    local item = p.makes and p.makes[1]
    local row = item and byItem[item]
    local left = row and math.max(row[2] - (keep[item] or 0), 0) or 0
    if row then row[2] = 0 end
    local per = p.makes[2]
    local crafts = math.ceil(left / per)
    for _, m in ipairs(p.mats or {}) do add(m[1], crafts * m[2]) end
    local total = left + (partMade[item] or 0)
    if total > 0 then
      for _, m in ipairs(p.mats or {}) do
        if byItem[m[1]] then
          byItem[m[1]].via = { part = p.name, made = item, n = total, raw = math.ceil(total / per) * m[2] }
        end
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

-- What your current step in each profession you have still needs, for the vendor's shopping card:
-- { { name, n, label = "Linen Belt (Tailoring)" } } in profession order, each name once. The step's
-- materials (a part's own materials instead of the part: bolts as cloth, oil as eel and vial), its
-- tools (one each), and the rod's materials while you lack the rod. Bags are counted by the card.
function ns.profSupplies()
  local out, byName = {}, {}
  local function add(name, n, label, tool)
    if n <= 0 then return end
    local row = byName[name]
    if not row then
      row = { name = name, n = 0, label = label }
      byName[name], out[#out + 1] = row, row
    elseif not row.label:find(label, 1, true) and not row.more then
      row.label, row.more = row.label .. " and " .. label, true
    end
    row.n = tool and math.max(row.n, n) or row.n + n
  end
  local snapshot = ns.profSkillSnapshot()
  for _, key in ipairs(ns.PROF_ORDER) do
    local P, reading = ns.P and ns.P[key], snapshot[key]
    local step = P and reading and reading.rank and ns.profStep(key, reading.rank)
    if step and step.mats then
      local label = step.name .. " (" .. P.name .. ")"
      local n = ns.craftsLeft(step, reading.rank) or 0
      local makesRod = false -- the rod's own step: its Mote can't be made yet
      for _, r in ipairs(P.rods or {}) do if r.name == step.name then makesRod = true end end
      for _, m in ipairs(step.mats) do
        local part = not makesRod and ns.profPart(key, m[1])
        if part then
          local short = math.max(n * m[2] - (bagCount(m[1]) or 0), 0)
          local crafts = math.ceil(short / (part.makes[2] or 1))
          for _, pm in ipairs(part.mats or {}) do add(pm[1], crafts * pm[2], label) end
        else
          add(m[1], n * m[2], label)
        end
      end
      for _, tool in ipairs(step.tools or {}) do add(tool, 1, label, true) end
      local rod = ns.profRod(key, step)
      if rod and ns.profHasRod(key, rod) == false then
        for _, m in ipairs(rod.mats or {}) do add(m[1], m[2], rod.name .. " (" .. P.name .. ")") end
      end
    end
    -- the book that unlocks your next rank once it's due, and a bought recipe your step needs
    -- and you don't know: the vendor card offers them where they're sold
    if P and reading and reading.rank then
      local level = UnitLevel and tonumber((UnitLevel("player"))) or 1
      local due, nextTier = ns.profTierDue(key, reading.rank, reading.cap, level)
      if due and nextTier.item and (bagCount(nextTier.item) or 0) == 0 then
        add(nextTier.item, 1, nextTier.name .. " " .. P.name, true)
      end
      if step and step.item and not (step.source or ""):find("^Quest") and (bagCount(step.item) or 0) == 0
          and step.spell and IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, step.spell)
        if ok and known == false then add(step.item, 1, step.name .. " (" .. P.name .. ")", true) end
      end
    end
  end
  return out
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

-- Where to learn, buy or unlock something: a tier or a step's `at` (ProfessionPlaces.lua's NPCs),
-- else for a trainer's step the trainer tier that teaches at its skill, else the profession's
-- capital trainers. Only your faction's (both when unknown); nearest you first (same continent by
-- yards, then the list's order). Each { name, faction, map, x, y, zone }.
local function placeOf(name)
  local p = ns.PROF_PLACES and ns.PROF_PLACES[name]
  if p then return { name = name, faction = p[1], map = p[2], x = p[3], y = p[4], zone = p[5] } end
end

local function trainerTier(P, learn)
  for i = #P.tiers, 1, -1 do
    local t = P.tiers[i]
    if t.at and not t.action and t.skill <= learn and learn <= t.cap then return t end
  end
end

local function sortPlaces(list)
  local Q = ns.quests
  local here
  if Q and Q.position then
    local map, x, y = Q.position()
    if map and x then here = { map = map, x = x, y = y } end
  end
  for i, p in ipairs(list) do
    p.order = i
    p.yards = here and Q.worldYards and Q.worldYards(here, p) or nil
  end
  table.sort(list, function(a, b)
    if (a.yards ~= nil) ~= (b.yards ~= nil) then return a.yards ~= nil end
    if a.yards and b.yards and a.yards ~= b.yards then return a.yards < b.yards end
    return a.order < b.order
  end)
  return list
end

function ns.profPlaces(key, entry)
  local P = ns.P and ns.P[key]
  if not (P and entry) then return {} end
  local faction = ns.profFaction()
  local letter = faction == "Alliance" and "A" or faction == "Horde" and "H" or nil
  local function pick(names)
    local out = {}
    for _, name in ipairs(names or {}) do
      local p = placeOf(name)
      if p and (not letter or p.faction:find(letter, 1, true)) then out[#out + 1] = p end
    end
    return out
  end
  local out = pick(entry.at)
  local text = (entry.source or entry.where or ""):lower()
  if #out == 0 and entry.learn and not entry.at and text:find("trainer", 1, true) then
    local tier = trainerTier(P, entry.learn)
    out = pick(tier and tier.at)
  end
  local trainer = (entry.cap and not entry.action) or (not entry.cap and text:find("trainer", 1, true))
  if #out == 0 and trainer and not text:find("^known when") then out = pick(ns.PROF_TRAINERS and ns.PROF_TRAINERS[key]) end
  return sortPlaces(out)
end

local function spot(p)
  return string.format("%s in %s (%.1f, %.1f)", p.name, p.zone, p.x, p.y)
end
ns.profSpotText = spot

-- One line saying where to go for a tier or step, for your faction, and the place (nil when the
-- guide names no NPC with a known spot: then the guide's own text).
function ns.profWhereText(key, entry)
  local places = ns.profPlaces(key, entry)
  local p = places[1]
  if not p then return ns.plain(entry.short or entry.where or entry.source or ""), nil end
  local text
  if (entry.source or ""):find("^Quest") then
    text = "Quest from " .. spot(p) .. (entry.item and (" (it gives " .. entry.item .. ")") or "")
  elseif entry.item then
    text = (entry.cap and "Buy and read " or "Buy ") .. entry.item .. " from " .. spot(p)
  elseif entry.cap and entry.action then
    text = "Quest from " .. spot(p)
  else
    text = (entry.cap and "Trainer: " or "Learn from ") .. spot(p)
  end
  if places[2] and (places[2].yards or 0) - (p.yards or 0) < 2000 and not entry.item and not entry.action then
    text = text .. ", or " .. places[2].name .. " in " .. places[2].zone
  end
  return ns.plain(text), p
end

-- The last place a profession card named (the crafting window's hint, the Professions tab): /codex
-- way points the arrow there. Said in chat once a session per place and reason.
local offered = {}
function ns.offerProfWay(place, why)
  if not place then return end
  ns.profWay = { place = place, why = why }
  local key = place.name .. ":" .. (why or "")
  if offered[key] then return end
  offered[key] = true
  if not ns.db().quiet then
    ns.say(ns.plain((why and (why .. ": ") or "") .. spot(place) .. ". Type /codex way to point the arrow there."))
  end
end

-- /codex way (and the Professions tab's Show the way): the arrow leads to that place, or back to
-- your step when it already does.
function ns.profShowWay(place, why)
  place = place or (ns.profWay and ns.profWay.place)
  why = why or (ns.profWay and ns.profWay.why)
  if not place then
    ns.say("no profession trainer or vendor to point to yet: open a crafting window or the Professions tab.")
    return
  end
  if ns.pointArrowTo then ns.pointArrowTo(place, why) end
end

-- One banner row (about 60 characters): the NPC for your faction with its spot, else the tier's short text.
function ns.profBannerWhere(key, tier)
  local p = ns.profPlaces(key, tier)[1]
  if p then return ns.plain(spot(p)) end
  return ns.plain(tier.short or tier.where)
end

-- Herbs specify their own cutoffs. Veins use Forever's gathering intervals: orange to +25, yellow to
-- +65 (Forever moved green later than Classic's +50), green to +100.
function ns.profNodeColor(node, skill)
  skill = skill or 0
  if skill < node.skill then return "red" end
  if skill < (node.yellow or node.skill + 25) then return "orange" end
  if skill < (node.green or node.skill + 65) then return "yellow" end
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
    local label = P.levelGatesUnconfirmed and "CHECK " or string.upper(nextTier.action or "Train") .. " "
    rows[#rows + 1] = { P.icon, label .. string.upper(nextTier.name), ns.profBannerWhere(key, nextTier) }
  end
  if nextTier and trained.cap > old and trained.cap <= new then
    rows[#rows + 1] = { P.icon, "AT YOUR CAP", (nextTier.action or "Train") .. " " .. nextTier.name .. " to go past " .. trained.cap }
    local text, place = ns.profWhereText(key, nextTier)
    if place then
      rows[#rows + 1] = { P.icon, string.upper(nextTier.item and "Buy the book" or nextTier.action and "Quest" or "Trainer"), spot(place) }
      ns.offerProfWay(place, (nextTier.action or "Train") .. " " .. nextTier.name .. " " .. P.name)
    end
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
        local label = (nextTier.action or "Train") .. " " .. nextTier.name .. " " .. P.name
        rows[#rows + 1] = { P.icon, string.upper(label), ns.profBannerWhere(key, nextTier), P.name, nextTier }
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
