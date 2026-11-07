-- Guide.lua: lookups into this class's guide data (Data.lua).
-- ns.D is this class's guide (set at login by Init.lua); every lookup copes with it being nil.

local _, ns = ...

-- The talent point for a level: the plan entry, its rank after this point, and the reason text.
function ns.talentAt(level)
  local D = ns.D
  if not D then return end
  local rank = 0
  local hit
  for _, p in ipairs(D.plan) do
    if level >= p.from and level <= p.to then hit = p end
  end
  if not hit then return end
  for _, p in ipairs(D.plan) do
    if p.name == hit.name then
      local top = math.min(p.to, level)
      if top >= p.from then rank = rank + (top - p.from + 1) end
    end
  end
  local text = (level == hit.from or hit.more == "") and hit.why or hit.more
  return hit, rank, text
end

function ns.trainAt(level)
  if not ns.D then return end
  for _, t in ipairs(ns.D.train) do
    if t.level == level then return t end
  end
end

function ns.nextTrain(level)
  if not ns.D then return end
  local best
  for _, t in ipairs(ns.D.train) do
    if t.level > level and (not best or t.level < best.level) then best = t end
  end
  return best
end

-- The tips chapter that covers a level.
function ns.bracketFor(level)
  if not ns.D then return end
  local best
  for _, b in ipairs(ns.D.br) do
    if b.level <= level and (not best or b.level > best.level) then best = b end
  end
  return best
end

function ns.macrosFor(level)
  local list = {}
  if not ns.D then return list end
  for _, m in ipairs(ns.D.macros) do
    if level >= m.lo and level <= m.hi then list[#list + 1] = m end
  end
  return list
end

-- Macro versions that start above this level, soonest first (one per name and level).
function ns.comingMacros(level)
  local list, seen = {}, {}
  if not ns.D then return list end
  for _, m in ipairs(ns.D.macros) do
    if m.lo > level and not seen[m.name .. m.lo] then
      seen[m.name .. m.lo] = true
      list[#list + 1] = m
    end
  end
  table.sort(list, function(a, b) return a.lo < b.lo end)
  return list
end
