-- JourneyDeeds.lua: the journal's trophies, the moments a quest log doesn't show. It watches for
-- your firsts (first bag, first green, blue and epic), close calls (out of a fight alive under 15%
-- health), gear upgrades you keep wearing, rares you slay and professions you take to a tier's cap,
-- and writes each as a moment of Journey.lua's story (J.add) plus a small record for the Trophies page:
--   journey.firsts = { [fk] = { t, l, i, iq, n, m, x, y } } (fk = bag/green/blue/epic)
--   journey.caps = { ["TA:150"] = t }, journey.closeCalls, journey.rares = count
-- Everything is read at call time and pcall'd; nothing here may break the rest of the add-on.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local function try(...) return Q.try(...) end

local D = {}
J.deeds = D

local CLOSE_PCT = 0.15 -- a fight that left you under this share of your health is a close call
local UPGRADE_WAIT = 60 -- seconds a new piece must stay on before it counts as an upgrade
local TICK = 2

local function now() return time and time() or 0 end
local function clock() return GetTime and GetTime() or 0 end
local function level() return tonumber(UnitLevel("player")) or 1 end

-- A number the client may hide from add-ons (a secret value): nil then.
local function num(v)
  if v == nil then return nil end
  if type(issecretvalue) == "function" then
    local ok, secret = pcall(issecretvalue, v)
    if not ok or secret then return nil end
  end
  local ok, n = pcall(tonumber, v)
  return ok and n or nil
end

local function journal()
  local j = J.data()
  if type(j.firsts) ~= "table" then j.firsts = {} end
  if type(j.caps) ~= "table" then j.caps = {} end
  return j
end

local function nameOf(link)
  return type(link) == "string" and link:match("%[(.-)%]") or nil
end
local function idOf(link)
  return tonumber(type(link) == "string" and link:match("item:(%d+)") or nil)
end

----------------------------------------------------------------------------
-- Firsts: the bags are read as they change; what you carried when the journal began doesn't count
----------------------------------------------------------------------------

D.FIRSTS = {
  { fk = "bag", label = "First bag", word = "bag" },
  { fk = "green", label = "First green", q = 2, word = "green" },
  { fk = "blue", label = "First blue", q = 3, word = "blue" },
  { fk = "epic", label = "First epic", q = 4, word = "epic" },
}
local FIRST_LINES = {
  bag = { "Strapped on your first bag: %item%. Room for the road at last", "Found %item% and stopped juggling loot in your arms" },
  green = { "Found your first green: %item%", "Turned up something special: %item%, your first green" },
  blue = { "A blue! %item% came your way in %zone%", "Held your first rare treasure, %item%, in %zone%" },
  epic = { "An epic! %item% shone in %zone%", "The stuff of legends: %item%, your first epic" },
}

local seeded -- this session's first read is a baseline, never a moment
local function bagList()
  local out = {}
  local C = C_Container
  local slots = C and C.GetContainerNumSlots or GetContainerNumSlots
  local info = C and C.GetContainerItemInfo
  if type(slots) ~= "function" then return nil end
  for bag = 0, 4 do
    local n = num(try(slots, bag)) or 0
    if bag > 0 and n > 0 then out.bags = (out.bags or 0) + 1 end
    for slot = 1, n do
      local it = info and try(info, bag, slot)
      if type(it) == "table" then
        out[#out + 1] = { link = it.hyperlink, id = it.itemID, q = num(it.quality) }
      elseif not info then
        local _, _, _, quality, _, _, link = try(GetContainerItemInfo, bag, slot)
        if link then out[#out + 1] = { link = link, id = idOf(link), q = num(quality) } end
      end
    end
  end
  return out
end

local function worn()
  local best = 0
  for slot = 1, 19 do
    local q = num(try(GetInventoryItemQuality, "player", slot))
    if q and q > best then best = q end
  end
  return best
end

local function recordFirst(fk, link, id, q)
  local j = journal()
  if j.firsts[fk] then return end
  local name = nameOf(link) or (id and ns.itemInfo(id)) or (fk == "bag" and "a sturdy bag" or "a new treasure")
  local zone = J.zoneName()
  local map, x, y = Q.position()
  j.firsts[fk] = { t = now(), l = level(), i = id, iq = q, n = Q.plain(name), m = map, x = x, y = y }
  local text = J.fill(J.pick(FIRST_LINES[fk], name), { item = Q.plain(name), zone = zone })
  J.add("first", text, nil, { fk = fk, i = id, iq = q })
end

function D.scanBags()
  local list = bagList()
  if not list then return end
  local j = journal()
  if not seeded then
    -- what you already have: known, not new (also after lost saved data)
    seeded = true
    if (list.bags or 0) > 0 and not j.firsts.bag then j.firsts.bag = { had = true } end
    local best = worn()
    for _, it in ipairs(list) do if it.q and it.q > best then best = it.q end end
    for _, f in ipairs(D.FIRSTS) do
      if f.q and best >= f.q and not j.firsts[f.fk] then j.firsts[f.fk] = { had = true } end
    end
    return
  end
  if (list.bags or 0) > 0 and not j.firsts.bag then
    local link
    for bag = 1, 4 do link = link or try(GetInventoryItemLink, "player", 19 + bag) end
    recordFirst("bag", link, idOf(link), 1)
  end
  for _, f in ipairs(D.FIRSTS) do
    if f.q and not j.firsts[f.fk] then
      for _, it in ipairs(list) do
        if it.q == f.q then recordFirst(f.fk, it.link, it.id or idOf(it.link), it.q); break end
      end
    end
  end
end

----------------------------------------------------------------------------
-- Close calls: the lowest your health went in a fight you walked away from
----------------------------------------------------------------------------

local fight -- { low = share, foe = name, died }
local CLOSE_LINES = {
  "Walked away from %foe% with %pct%% health left",
  "Survived %foe% by a hair in %zone%",
  "Stared down %foe% and lived, barely",
}
local CLOSE_PLAIN = { "Came within a whisker of the graveyard in %zone%", "Limped out of a fight in %zone% with %pct%% health" }

local function hostileTarget()
  local hostile = try(UnitCanAttack, "player", "target")
  if hostile ~= true and hostile ~= 1 then return nil end
  local dead = try(UnitIsDead, "target")
  if dead == true or dead == 1 then return nil end
  local name = try(UnitName, "target")
  return type(name) == "string" and name ~= "" and name or nil
end

function J.lastFoe() return fight and fight.foe or nil end
function J.onDeath() if fight then fight.died = true end end

local function readHealth()
  if not fight then return end
  local hp, max = num(try(UnitHealth, "player")), num(try(UnitHealthMax, "player"))
  if not (hp and max and max > 0) then return end
  local share = hp / max
  if share < fight.low then fight.low = share end
  fight.foe = hostileTarget() or fight.foe
end

local function fightStart()
  fight = { low = 1, foe = hostileTarget() }
  readHealth()
end

local function fightEnd()
  local f = fight
  fight = nil
  if not f or f.died then return end
  local dead = try(UnitIsDeadOrGhost, "player")
  if dead == true or dead == 1 then return end
  readHealth()
  if f.low > CLOSE_PCT or f.low <= 0 then return end
  local j = journal()
  j.closeCalls = (tonumber(j.closeCalls) or 0) + 1
  local pct = math.max(1, math.floor(f.low * 100 + 0.5))
  local vars = { foe = Q.plain(f.foe or "a foe"), pct = tostring(pct), zone = J.zoneName() }
  local text = J.fill(J.pick(f.foe and CLOSE_LINES or CLOSE_PLAIN, (f.foe or "") .. j.closeCalls), vars)
  J.add("close", text, "Down to " .. pct .. "% health", { who = f.foe, pct = pct })
end

----------------------------------------------------------------------------
-- Rares: a rare you had targeted alive, then saw dead
----------------------------------------------------------------------------

local RARE = { rare = true, rareelite = true }
local RARE_LINES = { "Slew %name%, a rare beast of %zone%", "Tracked down and felled %name% in %zone%",
  "Bagged a rare one: %name% in %zone%" }
local rareSeen, rareDone = {}, {}

local function checkRare()
  local guid = try(UnitGUID, "target")
  if type(guid) ~= "string" then return end
  local kind = try(UnitClassification, "target")
  if not RARE[kind] then return end
  local dead = try(UnitIsDead, "target")
  if dead == true or dead == 1 then
    if rareSeen[guid] and not rareDone[guid] then
      rareDone[guid] = true
      local denied = try(UnitIsTapDenied, "target")
      if denied == true or denied == 1 then return end -- someone else's kill
      local name = Q.plain(try(UnitName, "target") or "a rare")
      local j = journal()
      j.rares = (tonumber(j.rares) or 0) + 1
      J.add("rare", J.fill(J.pick(RARE_LINES, name), { name = name, zone = J.zoneName() }), nil, { who = name })
    end
  else
    local hostile = try(UnitCanAttack, "player", "target")
    if hostile == true or hostile == 1 then rareSeen[guid] = true end
  end
end

----------------------------------------------------------------------------
-- Upgrades: a better piece (item level, else quality) that stays on for a minute
----------------------------------------------------------------------------

local SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local SLOT_NAMES = { [1] = "head", [2] = "neck", [3] = "shoulders", [5] = "chest", [6] = "waist", [7] = "legs",
  [8] = "feet", [9] = "wrists", [10] = "hands", [11] = "finger", [12] = "finger", [13] = "trinket", [14] = "trinket",
  [15] = "back", [16] = "main hand", [17] = "off hand", [18] = "ranged slot" }
local UPGRADE_LINES = { "Traded up: %item% replaced %old%", "Put on %item% and never looked back at %old%",
  "Suited up in %item%" }
local UPGRADE_NEW = { "Filled your %slot% with %item%", "Put on %item%: the %slot% was bare before" }

local wear, pending = {}, {}
local function piece(slot)
  local link = try(GetInventoryItemLink, "player", slot)
  if type(link) ~= "string" then return nil end
  local name, _, quality, ilvl = ns.itemInfo(link)
  return { link = link, id = idOf(link), name = nameOf(link) or name, q = num(quality), ilvl = num(ilvl) }
end

local function better(new, old)
  if not new then return false end
  if not old then return true end
  if new.ilvl and old.ilvl and new.ilvl ~= old.ilvl then return new.ilvl > old.ilvl end
  return (new.q or 0) > (old.q or 0)
end

function D.snapshotGear()
  for _, slot in ipairs(SLOTS) do wear[slot] = piece(slot) end
end

local function equipmentChanged(slot)
  slot = tonumber(slot)
  if not slot or not SLOT_NAMES[slot] then return end
  local new, old = piece(slot), wear[slot]
  if new and old and new.link == old.link then return end
  if new and (new.ilvl or new.q) and better(new, old) then
    pending[slot] = { item = new, old = old, at = clock() }
  else
    pending[slot] = nil
  end
  wear[slot] = new
end

local function checkPending()
  for slot, p in pairs(pending) do
    if clock() - p.at >= UPGRADE_WAIT then
      pending[slot] = nil
      local still = piece(slot)
      if still and still.link == p.item.link then
        local vars = { item = Q.plain(p.item.name or "a new piece"), old = Q.plain(p.old and p.old.name or ""),
          slot = SLOT_NAMES[slot] }
        local text = J.fill(J.pick(p.old and UPGRADE_LINES or UPGRADE_NEW, vars.item), vars)
        local detail = p.item.ilvl and p.old and p.old.ilvl and ("Item level " .. p.old.ilvl .. " to " .. p.item.ilvl) or nil
        J.add("upgrade", text, detail, { i = p.item.id, iq = p.item.q })
      end
    end
  end
end

----------------------------------------------------------------------------
-- Profession caps: a tier taken to its last point
----------------------------------------------------------------------------

D.TIERS = { [75] = "Apprentice", [150] = "Journeyman", [225] = "Expert", [300] = "Artisan" }
local capsSeeded
function D.checkCaps()
  if type(ns.profSkill) ~= "function" or type(ns.PROF_ORDER) ~= "table" then return end
  local j = journal()
  for _, key in ipairs(ns.PROF_ORDER) do
    local ok, rank, cap = pcall(ns.profSkill, key)
    rank, cap = ok and num(rank), ok and num(cap)
    if rank and cap and rank >= cap and D.TIERS[cap] then
      local id = key .. ":" .. cap
      if not j.caps[id] then
        j.caps[id] = now()
        local P = ns.P and ns.P[key]
        local prof = Q.plain(P and P.name or key)
        if capsSeeded then
          local text = cap == 300 and ("Mastered " .. prof .. ": skill 300, as far as the craft goes")
            or ("Took " .. prof .. " to " .. cap .. ", the end of " .. D.TIERS[cap])
          J.add("cap", text, D.TIERS[cap] .. " " .. prof, { n = id })
        end
      end
    end
  end
  capsSeeded = true
end

----------------------------------------------------------------------------
-- Wiring
----------------------------------------------------------------------------

local HANDLERS = {
  PLAYER_REGEN_DISABLED = fightStart,
  PLAYER_REGEN_ENABLED = fightEnd,
  UNIT_HEALTH = function(unit)
    if unit == "player" then readHealth() elseif unit == "target" then checkRare() end
  end,
  PLAYER_TARGET_CHANGED = function() checkRare(); if fight then fight.foe = hostileTarget() or fight.foe end end,
  BAG_UPDATE_DELAYED = function() D.scanBags() end,
  PLAYER_EQUIPMENT_CHANGED = equipmentChanged,
  SKILL_LINES_CHANGED = function() D.checkCaps() end,
}

local frame
function ns.startJourneyDeeds()
  if frame then return end
  D.sessionStart = now()
  frame = CreateFrame("Frame")
  for event in pairs(HANDLERS) do
    if event == "UNIT_HEALTH" and frame.RegisterUnitEvent then
      pcall(frame.RegisterUnitEvent, frame, event, "player", "target")
    else
      pcall(frame.RegisterEvent, frame, event)
    end
  end
  frame:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(HANDLERS[event], ...)
    if not ok and not D.errored then D.errored = true; ns.say("journey error: " .. Q.plain(err)) end
  end)
  pcall(D.snapshotGear)
  pcall(D.scanBags)
  pcall(D.checkCaps)
  ns.every(TICK, function()
    local ok, err = pcall(function()
      checkPending()
      if fight then readHealth() end
      if not seeded then D.scanBags() end
    end)
    if not ok and not D.errored then D.errored = true; ns.say("journey error: " .. Q.plain(err)) end
  end)
end

----------------------------------------------------------------------------
-- Readers for the tab
----------------------------------------------------------------------------

-- Who killed you, most often first: { { name, n, last = event } }.
function D.nemeses()
  local by, list = {}, {}
  for _, e in ipairs(J.data().events) do
    if e.k == "death" and type(e.who) == "string" then
      local r = by[e.who]
      if not r then r = { name = e.who, n = 0 }; by[e.who] = r; list[#list + 1] = r end
      r.n, r.last = r.n + 1, e
    end
  end
  table.sort(list, function(a, b) if a.n ~= b.n then return a.n > b.n end return (a.last.t or 0) > (b.last.t or 0) end)
  return list
end

-- Moments of some kinds, newest first.
function D.moments(kinds, limit)
  local out = {}
  local events = J.data().events
  for i = #events, 1, -1 do
    if kinds[events[i].k] then
      out[#out + 1] = events[i]
      if limit and #out >= limit then break end
    end
  end
  return out
end

-- This session: what happened since login, as a few sentences of prose.
local function list(names)
  if #names == 0 then return nil end
  if #names == 1 then return names[1] end
  return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end
local function count(n, one, many) return n == 1 and one or (n .. " " .. many) end

function D.today()
  local since = D.sessionStart or 0
  local c = { quest = 0, chain = 0, elite = 0, level = 0, death = 0, boss = 0, close = 0, rare = 0, zone = 0 }
  local zones, seenZone, firsts, low, high = {}, {}, {}, nil, nil
  for _, e in ipairs(J.data().events) do
    if (e.t or 0) >= since then
      c[e.k] = (c[e.k] or 0) + 1
      local zn = e.m and select(2, J.zoneOf(e.m))
      if zn and not seenZone[zn] then seenZone[zn] = true; zones[#zones + 1] = zn end
      if e.k == "first" then firsts[#firsts + 1] = e end
      if e.k == "level" then
        low = math.min(low or e.l, (tonumber(e.l) or 1) - 1)
        high = math.max(high or e.l, tonumber(e.l) or 1)
      end
    end
  end
  local session = ns.stats and (ns.stats.data())
  local totals = type(session) == "table" and type(session.totals) == "table" and session.totals or {}
  local kills = tonumber(totals.kills) or 0
  local secs = math.max(0, now() - since)
  local out = {}
  local mins = math.floor(secs / 60)
  local span = mins < 60 and (mins .. " minutes") or (math.floor(mins / 60) .. " h " .. (mins % 60) .. " min")
  local first = "Today's road has run " .. span
  if high then first = first .. ", from level " .. low .. " to " .. high end
  local where = list(zones)
  if where then first = first .. ", through " .. where end
  out[#out + 1] = first .. "."
  local deeds = {}
  local quests = c.quest + c.chain + c.elite
  if quests > 0 then deeds[#deeds + 1] = count(quests, "one quest finished", "quests finished") end
  if kills > 0 then deeds[#deeds + 1] = count(kills, "one foe felled", "foes felled") end
  if c.boss > 0 then deeds[#deeds + 1] = count(c.boss, "a boss brought down", "bosses brought down") end
  if c.rare > 0 then deeds[#deeds + 1] = count(c.rare, "a rare slain", "rares slain") end
  if #deeds > 0 then
    local s = list(deeds)
    out[#out + 1] = s:sub(1, 1):upper() .. s:sub(2) .. "."
  end
  for _, e in ipairs(firsts) do out[#out + 1] = e.s .. "." end
  if J.tales and J.tales.todayLines then
    for _, l in ipairs(J.tales.todayLines(since)) do out[#out + 1] = (l:gsub("^%l", string.upper)) end
  end
  if c.close > 0 then out[#out + 1] = c.close == 1 and "One fight came far too close." or (c.close .. " fights came far too close.") end
  if c.death > 0 then
    out[#out + 1] = c.death == 1 and "You fell once, and got back up." or ("You fell " .. c.death .. " times, and got back up every time.")
  elseif secs >= 600 then
    out[#out + 1] = "Not a single fall."
  end
  if #out == 1 and not high and quests == 0 then out[#out + 1] = "The page is still mostly blank: the day is young." end
  return table.concat(out, " ")
end

function ns.journeyDeedsDebugLines()
  local j = journal()
  local firsts = {}
  for _, f in ipairs(D.FIRSTS) do
    local r = j.firsts[f.fk]
    firsts[#firsts + 1] = f.fk .. "=" .. (r and (r.had and "had" or (r.n or "yes")) or "no")
  end
  return { "journey deeds: firsts " .. table.concat(firsts, ", ") .. "; close calls " .. (tonumber(j.closeCalls) or 0)
    .. ", rares " .. (tonumber(j.rares) or 0) .. (fight and (", in a fight (low " .. math.floor(fight.low * 100) .. "%)") or "") }
end
