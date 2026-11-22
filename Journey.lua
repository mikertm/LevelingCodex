-- Journey.lua: your adventure journal. It records where you walked (a trail per zone, coloured by
-- your level then) and the moments of your journey (levels, new zones, quests, dungeons and bosses,
-- deaths, flight paths, the companions you travelled with), each written as a line of the story,
-- and draws them in the Journey tab and as a trail on the world map.
--   LevelingCodexCharDB.journey = { version = 1, started, zones = { [map] = { name, first, level } },
--     order = { map, ... } (first visit order), trail = { [map] = { { l = level, p = "xxxyyy..." } } },
--     points, walked (yards), events = { { t, k, l, m, x, y, s, d, q } }, pals = { [name] = { seconds,
--     class, first, level } }, deaths }
-- A trail run's points are packed six digits each: x and y in tenths of a percent (000-999). Forever
-- may not load saved data back: the journal then starts again at this login and the tab says so.
local _, ns = ...
local Q = ns.quests
local function try(...) return Q.try(...) end

local J = {}
ns.journey = J

J.MAX_POINTS = 20000 -- trail points kept (older trails are thinned, never cut)
J.MAX_EVENTS = 2000
local STEP_YD, STEP_PCT = 35, 0.8 -- a new trail point after this far (yards, else map percent)
local JUMP_PCT = 12 -- a bigger jump between samples (a hearth, a portal) starts a new run
local SAMPLE = 2 -- seconds between trail samples
local PAL_TICK = 5

-- Level bands for the trail colours: 1-9, 10-19, ... 50-60.
J.BANDS = {
  { 1, 9, { 0.45, 0.85, 0.35 }, "1-9" }, { 10, 19, { 0.25, 0.8, 0.8 }, "10-19" },
  { 20, 29, { 0.35, 0.55, 1 }, "20-29" }, { 30, 39, { 0.72, 0.45, 0.95 }, "30-39" },
  { 40, 49, { 1, 0.6, 0.2 }, "40-49" }, { 50, 60, { 1, 0.3, 0.3 }, "50-60" },
}
function J.bandColor(level)
  level = tonumber(level) or 1
  for _, b in ipairs(J.BANDS) do if level <= b[2] then return b[3] end end
  return J.BANDS[#J.BANDS][3]
end

local PIN = {
  death = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  level = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", -- the star
  boss = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}
local ICON = {
  level = "Spell_Holy_SurgeOfLight", zone = "INV_Misc_Map_01", quest = "INV_Misc_Note_01",
  chain = "INV_Misc_Book_09", elite = "Ability_Warrior_BattleShout", dungeon = "INV_Misc_Key_03",
  boss = "INV_Misc_Head_Dragon_01", death = "INV_Misc_Bone_HumanSkull_01", flight = "Ability_Mount_Gryphon_01",
  pal = "Spell_Holy_PrayerOfHealing", start = "INV_Misc_Book_11",
}

----------------------------------------------------------------------------
-- The saved journal
----------------------------------------------------------------------------

local function fresh()
  return { version = 1, started = time and time() or 0, zones = {}, order = {}, trail = {}, points = 0,
    walked = 0, events = {}, pals = {}, deaths = 0 }
end
local loose -- the journal when there is no character table at all

local function valid(j)
  return type(j) == "table" and j.version == 1 and type(j.zones) == "table" and type(j.order) == "table"
    and type(j.trail) == "table" and type(j.events) == "table" and type(j.pals) == "table"
end

function J.data()
  local db = LevelingCodexCharDB
  if type(db) ~= "table" then
    if not valid(loose) then loose = fresh() end
    return loose
  end
  if not valid(db.journey) then db.journey = fresh() end
  return db.journey
end

local function level() return tonumber(UnitLevel("player")) or 1 end
local function now() return time and time() or 0 end

-- A small stable hash of a string, to pick a phrasing that doesn't change between reloads.
local function pick(list, seed)
  local h = 0
  seed = tostring(seed or "")
  for i = 1, #seed do h = (h * 31 + seed:byte(i)) % 2147483647 end
  return list[h % #list + 1]
end

local function fill(text, vars)
  return (text:gsub("%%(%w+)%%", function(k) return vars[k] or "" end))
end

-- Zone maps: up through parents while the map is smaller than a zone.
local zoneCache = {}
local function zoneOf(map)
  if type(map) ~= "number" then return end
  local hit = zoneCache[map]
  if hit then return hit[1], hit[2] end
  local id = map
  local info = try(C_Map and C_Map.GetMapInfo, id)
  while type(info) == "table" and tonumber(info.mapType) and info.mapType > 3 and info.parentMapID do
    local parent = try(C_Map.GetMapInfo, info.parentMapID)
    if type(parent) ~= "table" then break end
    id, info = info.parentMapID, parent
  end
  local name = type(info) == "table" and type(info.name) == "string" and info.name ~= "" and Q.plain(info.name)
  if not name then
    local _, sections = Q.rows()
    for _, s in ipairs(sections or {}) do
      if s.zone == id and not s.category and not s.side then name = Q.plain((s.title:gsub(" %d+%-%d+$", ""))); break end
    end
  end
  name = name or ("Map " .. id)
  zoneCache[map] = { id, name }
  return id, name
end
J.zoneOf = zoneOf

local function inInstance()
  local _, kind = try(GetInstanceInfo)
  return kind == "party" or kind == "raid"
end

local function here()
  local map, x, y = Q.position()
  local zone, name = zoneOf(map)
  return zone, name, map, x, y
end

----------------------------------------------------------------------------
-- The party: who you travel with
----------------------------------------------------------------------------

local function partyNames()
  local out = {}
  if try(IsInRaid) == true then return out end
  local n = tonumber(try(GetNumSubgroupMembers)) or 0
  for i = 1, math.min(4, n) do
    local name = try(UnitName, "party" .. i)
    if type(name) == "string" and name ~= "" and name ~= "Unknown" then
      local _, class = try(UnitClass, "party" .. i)
      out[#out + 1] = { name = name, class = class }
    end
  end
  return out
end

local function partyText()
  local names = {}
  for _, p in ipairs(partyNames()) do names[#names + 1] = Q.plain(p.name) end
  if #names == 0 then return nil end
  if #names == 1 then return names[1] end
  return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

----------------------------------------------------------------------------
-- The story's words
----------------------------------------------------------------------------

-- Creatures by family: what a kill quest against them reads like.
local FOES = {
  { "murloc", { "Heroically did the chores: murloc duty in %zone%", "Silenced the murlocs' gurgling along the shores of %zone%",
    "Waded into %zone% and sent the murlocs back to the deep" } },
  { "kobold", { "Chased the kobolds of %zone% back into their candlelit tunnels", "Taught the kobolds of %zone% to keep their candles to themselves" } },
  { "gnoll", { "Sent the gnolls of %zone% running for the hills", "Broke a gnoll pack's grip on %zone%" } },
  { "defias", { "Taught the Defias of %zone% some manners", "Unmasked a few too many Defias in %zone%" } },
  { "spider|widow|tarantula|creeper|lurker", { "Braved the webs of %zone%", "Cleared the spiders out of %zone%, one shudder at a time" } },
  { "wolf|worg|coyote|jackal|hyena", { "Thinned the hungry packs that prowl %zone%", "Hunted the wolves of %zone% before they hunted you" } },
  { "boar|bristleback", { "Hunted boar across %zone%: somebody's supper is safe", "Out-charged the boars of %zone%" } },
  { "bear|grizzly", { "Stood tall against the bears of %zone%" } },
  { "harpy", { "Clipped the harpies' wings over %zone%" } },
  { "trogg", { "Pushed the troggs of %zone% back underground" } },
  { "ogre", { "Stood up to the ogres of %zone% and came out taller" } },
  { "quilboar|razorfen", { "Drove the quilboar back to their thorns in %zone%" } },
  { "centaur|kolkar|galak|maraudine", { "Rode down the centaur raiders of %zone%" } },
  { "raptor|crocolisk|basilisk|scorpid|threshadon", { "Tamed nothing, but survived the beasts of %zone%", "Went toe to claw with the beasts of %zone%" } },
  { "skeleton|zombie|ghoul|scourge|ghost|spirit|haunt|wraith|undead", { "Laid the restless dead of %zone% back to rest",
    "Walked among the dead of %zone% and sent them back to their graves" } },
  { "elemental|fire|earth|water|storm|lava|flame", { "Quelled the wild elements of %zone%" } },
  { "whelp|drake|dragon|wyrm", { "Faced dragonkin in %zone% and kept your eyebrows" } },
  { "naga|siren|myrmidon", { "Turned back the naga on the shores of %zone%" } },
  { "troll|skullsplitter|bloodscalp|witherbark|vilebranch|smolderthorn", { "Broke a troll war band in %zone%" } },
  { "bandit|thief|rogue|smuggler|pirate|bloodsail|thug|brigand|outlaw", { "Put an end to the outlaws of %zone%" } },
  { "orc|grunt|warlord|blackrock|dragonmaw", { "Fought the orc war bands of %zone%" } },
  { "satyr|demon|imp|felguard|voidwalker|succubus", { "Banished the demons lurking in %zone%" } },
}
local KILL = { "Answered %giver%'s call to arms against the %foe%s of %zone%", "Made %zone% a little safer from %foe%s",
  "Hunted %foe%s across %zone%", "Cleared the %foe%s out of %zone%" }
local GATHER = { "Gathered %item% across %zone% for %giver%", "Rummaged through %zone% for %item%",
  "Brought back the %item% %giver% needed" }
local COOK = { "Gathered %item% in %zone% so %giver% could get cooking", "Kept the kitchens of %zone% stocked with %item%" }
local ERRAND = { "Ran an errand for %giver% in %zone%", "Carried word across %zone% for %giver%", "Did a good turn for %giver% in %zone%" }
local NO_GIVER = { "Lent a helping hand in %zone%", "Answered a call for help in %zone%" }

-- Hand-picked moments: the turn-ins that end famous stories.
J.FAMOUS_QUESTS = {
  [166] = "Conquered Edwin VanCleef and saved Westfall", -- The Defias Brotherhood
  [176] = "Brought down Hogger, terror of Elwynn Forest", -- Wanted: Hogger
}
-- Bosses by name: the last boss of a dungeon reads as conquering it.
J.FAMOUS_BOSSES = {
  ["edwin vancleef"] = "Conquered Edwin VanCleef in the Deadmines and saved Westfall",
  ["mutanus the devourer"] = "Woke the Wailing Caverns from their nightmare by slaying Mutanus",
  ["archmage arugal"] = "Ended Archmage Arugal's madness in Shadowfang Keep",
  ["bazil thredd"] = "Put down the Stockade riot by catching Bazil Thredd",
  ["aku'mai"] = "Slew Aku'mai in the depths of Blackfathom Deeps",
  ["mekgineer thermaplugg"] = "Took Gnomeregan back from Mekgineer Thermaplugg",
  ["charlga razorflank"] = "Toppled Charlga Razorflank in Razorfen Kraul",
  ["amnennar the coldbringer"] = "Shattered Amnennar the Coldbringer in Razorfen Downs",
  ["high inquisitor whitemane"] = "Broke the Scarlet Crusade's hold on its monastery",
  ["archaedas"] = "Woke and felled Archaedas in the halls of Uldaman",
  ["chief ukorz sandscalp"] = "Conquered Zul'Farrak by defeating Chief Ukorz Sandscalp",
  ["princess theradras"] = "Lifted Princess Theradras's corruption from Maraudon",
  ["shade of eranikus"] = "Laid the Shade of Eranikus to rest in the Sunken Temple",
  ["emperor dagran thaurissan"] = "Toppled Emperor Thaurissan in Blackrock Depths",
}
local BOSS = { "Defeated %boss% in %dungeon%", "Brought down %boss% deep in %dungeon%", "Bested %boss% in %dungeon%" }
local DUNGEON = { "Ventured into %dungeon%", "Gathered your courage and stepped into %dungeon%", "Delved into %dungeon%" }
local ZONE = { "Set foot in %zone% for the first time", "The road led on to %zone%", "Arrived in %zone%, a new land to explore",
  "First steps into %zone%" }
local DEATH = { "Fell to %killer% in %zone%, then got back up", "Was bested by %killer% in %zone%: a lesson learned" }
local DEATH_PLAIN = { "Met an untimely end in %zone%, but the story goes on", "Took a spill in %zone% and walked back from the graveyard" }
local FLIGHT = { "Made friends with the flight master at %place%", "Found a new flight path at %place%" }
local PAL = { "Joined forces with %name%", "Met %name% on the road and travelled together" }

-- What a quest was about, read from its objectives while it sat in your log.
local questFacts = {} -- [id] = { title, kind = "kill"/"gather"/"errand", target }
local lastLog
local function readLog()
  local log = Q.logEntries()
  if type(log) ~= "table" or log == lastLog then return end
  lastLog = log
  for id, entry in pairs(log) do
    if type(entry) == "table" then
      local kind, target = "errand", nil
      for _, o in ipairs(type(entry.objectives) == "table" and entry.objectives or {}) do
        local text = type(o) == "table" and type(o.text) == "string" and o.text or ""
        local name = text:match("^(.-) slain") or text:match("^(.-) killed") or text:match("^(.-):")
        if o.type == "monster" or text:find(" slain") or text:find(" killed") then
          kind, target = "kill", target or name
          break
        elseif o.type == "item" and kind ~= "kill" then
          kind, target = "gather", target or name
        end
      end
      questFacts[id] = { title = entry.title, kind = kind, target = target and Q.plain(target) }
    end
  end
end

-- The quest's turn-in NPC, from the route (cached once).
local finishers
local function finisher(id)
  if not finishers then
    finishers = {}
    local steps = Q.rows()
    for _, row in ipairs(type(steps) == "table" and steps or {}) do
      local s = row.step
      if s and s.quest and type(s.npc) == "string" and (s.type == "turnin" or not finishers[s.quest]) then
        finishers[s.quest] = Q.plain(s.npc)
      end
    end
  end
  return finishers[id]
end

local function singular(name)
  name = name or ""
  return (name:gsub("ies$", "y"):gsub("([^s])s$", "%1"))
end

-- A quest turn-in as a line of the story: (text, kind).
function J.questLine(id, title, zone)
  readLog()
  local facts = questFacts[id] or {}
  title = title or facts.title or Q.questName(id) or ("Quest " .. tostring(id))
  zone = zone or "the wilds"
  local giver = finisher(id)
  local vars = { zone = zone, giver = giver or "a local", title = Q.plain(title) }
  if J.FAMOUS_QUESTS[id] then return J.FAMOUS_QUESTS[id], "chain" end
  local part, length = Q.chainInfo(id)
  if part and length and part == length then
    return fill(pick({ "Saw the tale of %title% through to the end", "Finished the long road of %title%" }, id), vars), "chain"
  end
  local elite = Q.eliteName(id)
  if elite then
    vars.elite = Q.plain(elite)
    return fill(pick({ "Took on %elite% and lived to tell the tale", "Stood against %elite% in %zone% and won" }, id), vars), "elite"
  end
  local mobs = ns.questMobs and ns.questMobs[id]
  if facts.kind == "kill" or (not facts.kind and mobs) then
    local foe = facts.target or (mobs and mobs[1]) or "foe"
    local low = foe:lower()
    for _, f in ipairs(FOES) do
      for word in f[1]:gmatch("[^|]+") do
        if low:find(word, 1, true) then return fill(pick(f[2], id), vars), "quest" end
      end
    end
    vars.foe = singular(Q.plain(foe))
    return fill(pick(KILL, id), vars), "quest"
  end
  if facts.kind == "gather" and facts.target then
    vars.item = Q.plain(facts.target)
    local low = vars.item:lower()
    local food = low:find("meat") or low:find("flank") or low:find("egg") or low:find("steak")
      or low:find("spice") or low:find("fish")
    return fill(pick(food and COOK or GATHER, id), vars), "quest"
  end
  return fill(pick(giver and ERRAND or NO_GIVER, id), vars), "quest"
end

function J.bossLine(boss, dungeon)
  local famous = J.FAMOUS_BOSSES[(boss or ""):lower()]
  if famous then return famous end
  return fill(pick(BOSS, boss), { boss = Q.plain(boss or "a fearsome foe"), dungeon = Q.plain(dungeon or "the depths") })
end

function J.levelLine(lvl, zone)
  lvl = tonumber(lvl) or 1
  if lvl == 60 then return "Reached level 60 in " .. zone .. ": the summit of the journey" end
  if lvl == 10 then return "Reached level 10 in " .. zone .. ": your first talent point awaits" end
  if lvl % 10 == 0 then return "Reached level " .. lvl .. " in " .. zone .. ", a milestone worth a toast" end
  return fill(pick({ "Grew stronger: level %n% in %zone%", "Reached level %n% in %zone%",
    "Level %n%, earned the hard way in %zone%" }, lvl), { n = tostring(lvl), zone = zone })
end

----------------------------------------------------------------------------
-- Recording
----------------------------------------------------------------------------

-- Add a moment. fields: k (kind), s (text), d (detail), q (quest), at = { map, x, y } (else where you are).
function J.add(kind, text, detail, extra)
  local j = J.data()
  local _, _, map, x, y = here()
  local e = { t = now(), k = kind, l = level(), s = Q.plain(text or ""), d = detail and Q.plain(detail) or nil }
  if extra and extra.at then map, x, y = extra.at[1], extra.at[2], extra.at[3] end
  if extra and extra.q then e.q = extra.q end
  if extra and extra.l then e.l = extra.l end
  if map and x and y and not inInstance() then
    e.m, e.x, e.y = map, math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10
  end
  local events = j.events
  events[#events + 1] = e
  if #events > J.MAX_EVENTS then
    -- drop the oldest small moment; levels and new zones are the story's spine
    for i = 1, #events do
      if events[i].k ~= "level" and events[i].k ~= "zone" and events[i].k ~= "start" then table.remove(events, i); break end
    end
    if #events > J.MAX_EVENTS then table.remove(events, 1) end
  end
  J.version = (J.version or 0) + 1
  return e
end

local function pack(x, y)
  local px = math.max(0, math.min(999, math.floor(x * 10 + 0.5)))
  local py = math.max(0, math.min(999, math.floor(y * 10 + 0.5)))
  return string.format("%03d%03d", px, py)
end

-- The points of a run: a list of { x, y } in percent.
function J.unpack(p)
  local out = {}
  if type(p) ~= "string" then return out end
  for i = 1, #p - 5, 6 do
    local x, y = tonumber(p:sub(i, i + 2)), tonumber(p:sub(i + 3, i + 5))
    if x and y then out[#out + 1] = { x / 10, y / 10 } end
  end
  return out
end

-- Over the limit: halve the zone with the most points (each run keeps its first and last point).
local function thin(j)
  local guard = 0
  while (tonumber(j.points) or 0) > J.MAX_POINTS and guard < 20 do
    guard = guard + 1
    local worst, most = nil, 0
    for map, runs in pairs(j.trail) do
      local n = 0
      for _, r in ipairs(runs) do n = n + math.floor(#(r.p or "") / 6) end
      if n > most then worst, most = map, n end
    end
    if not worst or most < 4 then return end
    local total = 0
    for _, r in ipairs(j.trail[worst]) do
      local pts = J.unpack(r.p)
      local keep = {}
      for i, pt in ipairs(pts) do
        if i == 1 or i == #pts or i % 2 == 1 then keep[#keep + 1] = pack(pt[1], pt[2]) end
      end
      r.p = table.concat(keep)
      total = total + #keep
    end
    j.points = 0
    for _, runs in pairs(j.trail) do
      for _, r in ipairs(runs) do j.points = j.points + math.floor(#(r.p or "") / 6) end
    end
  end
end

local last -- the last trail sample: { map, x, y, level, run }
local function sample()
  if Q.inFlight() then last = nil; return end
  local dead = try(UnitIsDeadOrGhost, "player")
  if dead == true or dead == 1 or inInstance() then last = nil; return end
  local map, x, y = Q.position()
  if not (map and x and y) then return end
  local j = J.data()
  local lvl = level()
  local world = ns.questWorld and ns.questWorld[map]
  local function yards(dx, dy)
    if not (world and world.width and world.height) then return end
    local ax, ay = dx / 100 * world.width, dy / 100 * world.height
    return math.sqrt(ax * ax + ay * ay)
  end
  if last and last.map == map and last.level == lvl then
    local dx, dy = x - last.x, y - last.y
    local pct = math.sqrt(dx * dx + dy * dy)
    if pct < JUMP_PCT then
      local yd = yards(dx, dy)
      if (yd and yd < STEP_YD) or (not yd and pct < STEP_PCT) then return end
      last.run.p = last.run.p .. pack(x, y)
      last.x, last.y = x, y
      j.points = (tonumber(j.points) or 0) + 1
      j.walked = (tonumber(j.walked) or 0) + (yd or 0)
      if j.points > J.MAX_POINTS then thin(j) end
      J.trailVersion = (J.trailVersion or 0) + 1
      return
    end
  end
  j.trail[map] = j.trail[map] or {}
  local run = { l = lvl, p = pack(x, y) }
  table.insert(j.trail[map], run)
  j.points = (tonumber(j.points) or 0) + 1
  last = { map = map, x = x, y = y, level = lvl, run = run }
  J.trailVersion = (J.trailVersion or 0) + 1
end

-- A zone you haven't been to (the first one starts the journal).
local function checkZone()
  if inInstance() or Q.inFlight() then return end
  local zone, name, map, x, y = here()
  local j = J.data()
  if not zone then
    -- no map position from this client: the journal still begins
    if #j.events == 0 then
      local who = Q.plain(try(UnitName, "player") or "you")
      J.add("start", "The journey of " .. who .. " begins in " .. Q.plain(try(GetZoneText) or "the wide world"))
    end
    return
  end
  if j.zones[zone] then return end
  j.zones[zone] = { name = name, first = now(), level = level() }
  j.order[#j.order + 1] = zone
  if #j.order == 1 and #j.events == 0 then
    local who = Q.plain(try(UnitName, "player") or "you")
    J.add("start", "The journey of " .. who .. " begins in " .. name, nil, { at = x and { map, x, y } })
  else
    J.add("zone", fill(pick(ZONE, name), { zone = name }), nil, { at = x and { map, x, y } })
  end
end

local function zoneName()
  local _, name = here()
  return name or "the wilds"
end

local dungeonHere, bossSeen
local function enteredWorld()
  local name, kind = try(GetInstanceInfo)
  if kind ~= "party" and kind ~= "raid" then dungeonHere = nil; return end
  if type(name) ~= "string" or name == "" or dungeonHere == name then return end
  dungeonHere, bossSeen = name, {}
  local party = partyText()
  local text = fill(pick(DUNGEON, name .. now()), { dungeon = Q.plain(name) })
  J.add("dungeon", party and (text .. " with " .. party) or text)
end

local function bossDown(name)
  if type(name) ~= "string" or name == "" then return end
  bossSeen = bossSeen or {}
  if bossSeen[name] then return end
  bossSeen[name] = true
  J.add("boss", J.bossLine(name, dungeonHere), dungeonHere and Q.plain(dungeonHere))
end

local HANDLERS = {
  PLAYER_LEVEL_UP = function(newLevel)
    local lvl = tonumber(newLevel) or level() + 1
    J.add("level", J.levelLine(lvl, zoneName()), nil, { l = lvl })
    last = nil -- the trail's colour changes with the level
  end,
  QUEST_TURNED_IN = function(id)
    id = tonumber(id)
    if not id then return end
    local title = (questFacts[id] and questFacts[id].title) or Q.questName(id)
      or try(C_QuestLog and C_QuestLog.GetTitleForQuestID, id)
    local text, kind = J.questLine(id, title, zoneName())
    J.add(kind, text, title and ("Quest: " .. Q.plain(title)) or nil, { q = id })
  end,
  PLAYER_DEAD = function()
    local j = J.data()
    j.deaths = (tonumber(j.deaths) or 0) + 1
    local killer
    local hostile = try(UnitCanAttack, "player", "target")
    if hostile == true or hostile == 1 then killer = try(UnitName, "target") end
    local zone = zoneName()
    local text = killer and fill(pick(DEATH, killer .. j.deaths), { killer = Q.plain(killer), zone = zone })
      or fill(pick(DEATH_PLAIN, zone .. j.deaths), { zone = zone })
    J.add("death", text, "Death " .. j.deaths)
  end,
  NEW_TAXI_PATH = function()
    local place = try(GetSubZoneText)
    if type(place) ~= "string" or place == "" then place = zoneName() end
    J.add("flight", fill(pick(FLIGHT, place), { place = Q.plain(place) }))
  end,
  PLAYER_ENTERING_WORLD = function() enteredWorld(); checkZone() end,
  ZONE_CHANGED_NEW_AREA = function() enteredWorld(); checkZone() end,
  ENCOUNTER_END = function(_, name, _, _, success) if success == 1 or success == true then bossDown(name) end end,
  BOSS_KILL = function(_, name) bossDown(name) end,
}

-- Companions: time grouped with each party member; the first time adds a moment.
local function palTick()
  local j = J.data()
  for _, p in ipairs(partyNames()) do
    local rec = j.pals[p.name]
    if type(rec) ~= "table" then
      rec = { seconds = 0, first = now(), level = level() }
      j.pals[p.name] = rec
      J.add("pal", fill(pick(PAL, p.name), { name = Q.plain(p.name) }))
    end
    rec.class = p.class or rec.class
    rec.seconds = (tonumber(rec.seconds) or 0) + PAL_TICK
  end
end

local events
function ns.startJourney()
  if events then return end
  J.data()
  events = CreateFrame("Frame")
  for event in pairs(HANDLERS) do pcall(events.RegisterEvent, events, event) end
  events:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(HANDLERS[event], ...)
    if not ok and not J.errored then
      J.errored = true
      ns.say("journey error: " .. Q.plain(err))
    end
  end)
  local function guarded(fn)
    return function()
      local ok, err = pcall(fn)
      if not ok and not J.errored then J.errored = true; ns.say("journey error: " .. Q.plain(err)) end
    end
  end
  ns.every(SAMPLE, guarded(function()
    readLog()
    checkZone()
    if not ns.db().noJourneyTrail then sample() end
    J.drawWorld()
  end))
  ns.every(PAL_TICK, guarded(palTick))
end

function J.reset()
  local j = fresh()
  if type(LevelingCodexCharDB) == "table" then LevelingCodexCharDB.journey = j else loose = j end
  last, J.version, J.trailVersion = nil, (J.version or 0) + 1, (J.trailVersion or 0) + 1
end

-- /codex debug
function ns.journeyDebugLines()
  local j = J.data()
  local maps = 0
  for _ in pairs(j.trail) do maps = maps + 1 end
  return { "journey: " .. #j.events .. " moments, " .. (tonumber(j.points) or 0) .. " trail points on " .. maps
    .. " maps, " .. #j.order .. " zones, world map trail: " .. (J.worldLine or "not drawn yet") }
end

----------------------------------------------------------------------------
-- Drawing the trail: helpers shared by the tab and the world map
----------------------------------------------------------------------------

-- Every run on a map, thinned to at most `cap` points overall: { { x, y, level }, ... } per run.
function J.runs(map, cap)
  local j = J.data()
  local runs, total = {}, 0
  for _, r in ipairs(j.trail[map] or {}) do
    local pts = J.unpack(r.p)
    total = total + #pts
    runs[#runs + 1] = { level = r.l, pts = pts }
  end
  local stride = math.max(1, math.ceil(total / (cap or 600)))
  if stride > 1 then
    for _, r in ipairs(runs) do
      local keep = {}
      for i, pt in ipairs(r.pts) do if i % stride == 1 or i == #r.pts then keep[#keep + 1] = pt end end
      r.pts = keep
    end
  end
  return runs, total
end

-- Moments with a spot on a map (deaths, level-ups, bosses outside, ...).
function J.pinsOn(map)
  local out = {}
  for _, e in ipairs(J.data().events) do
    if e.m == map and e.x and e.y then out[#out + 1] = e end
  end
  return out
end

----------------------------------------------------------------------------
-- The world map trail
----------------------------------------------------------------------------

local WORLD_DOTS, WORLD_PINS = 700, 40
local wtrail
local function worldCanvas()
  local frame = WorldMapFrame
  local scroll = type(frame) == "table" and frame.ScrollContainer
  return frame, type(scroll) == "table" and scroll.Child or nil, type(scroll) == "table" and scroll or nil
end

local function worldZoom()
  local _, _, scroll = worldCanvas()
  local s = scroll and tonumber((try(scroll.GetCanvasScale, scroll)))
  return s and s > 0 and s or 1
end

local hookedMap
function J.drawWorld(force)
  local frame, child = worldCanvas()
  if not child then return end
  if not hookedMap then
    hookedMap = true
    if type(frame.HookScript) == "function" then pcall(frame.HookScript, frame, "OnShow", function() J.drawWorld(true) end) end
    if type(frame.OnMapChanged) == "function" and type(hooksecurefunc) == "function" then
      pcall(hooksecurefunc, frame, "OnMapChanged", function() J.drawWorld(true) end)
    end
  end
  if not wtrail then
    wtrail = CreateFrame("Frame", "LevelingCodexJourneyTrail", child)
    wtrail:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    wtrail:SetSize(1, 1)
    local mgr = type(frame.GetPinFrameLevelsManager) == "function" and try(frame.GetPinFrameLevelsManager, frame)
    local lvl = type(mgr) == "table" and type(mgr.GetValidFrameLevel) == "function"
      and tonumber((try(mgr.GetValidFrameLevel, mgr, "PIN_FRAME_LEVEL_AREA_POI"))) or nil
    -- just under the quest pins, above the map art
    wtrail:SetFrameLevel(math.max(1, (lvl or ((tonumber(child:GetFrameLevel()) or 1) + 20)) - 1))
    wtrail.dots, wtrail.pins = {}, {}
    local disc = ns.art.hasFile(ns.art.FILES.circle) and ns.art.FILES.circle
    wtrail.disc = disc
    -- each dot a bright centre on a dark halo, so it reads on the parchment map
    for n = 1, WORLD_DOTS do
      local d = wtrail:CreateTexture(nil, "ARTWORK")
      d:SetSize(5, 5)
      d.edge = wtrail:CreateTexture(nil, "BORDER")
      d.edge:SetSize(8, 8)
      if disc then d:SetTexture(disc); d.edge:SetTexture(disc); d.edge:SetVertexColor(0.1, 0.06, 0.02, 0.6)
      else d:SetColorTexture(1, 1, 1, 1); d.edge:SetColorTexture(0.1, 0.06, 0.02, 0.6) end
      d:Hide(); d.edge:Hide()
      wtrail.dots[n] = d
    end
    for n = 1, WORLD_PINS do
      local p = wtrail:CreateTexture(nil, "OVERLAY")
      p:SetSize(14, 14)
      p:Hide()
      wtrail.pins[n] = p
    end
    wtrail:SetScript("OnUpdate", function()
      if worldZoom() ~= wtrail.zoom then J.drawWorld(true) end
    end)
  end
  local shown = frame.IsShown and frame:IsShown()
  local map = try(frame.GetMapID, frame)
  local key = tostring(map) .. ":" .. tostring(J.trailVersion) .. ":" .. tostring(J.version) .. ":" .. worldZoom()
    .. ":" .. tostring(ns.db().noJourneyMap)
  if not force and key == wtrail.key then return end
  wtrail.key = key
  for _, d in ipairs(wtrail.dots) do d:Hide(); d.edge:Hide() end
  for _, p in ipairs(wtrail.pins) do p:Hide() end
  if ns.db().noJourneyMap then J.worldLine = "off (Journey > Show my trail on the world map)"; wtrail:Hide(); return end
  if not shown then J.worldLine = J.worldLine or "the map is closed"; return end
  if type(map) ~= "number" then J.worldLine = "no map shown"; wtrail:Hide(); return end
  local w, h = tonumber(child:GetWidth()) or 0, tonumber(child:GetHeight()) or 0
  local z = worldZoom()
  wtrail.zoom = z
  wtrail:SetScale(1 / z)
  wtrail:SetSize(math.max(1, w * z), math.max(1, h * z))
  local used = 0
  local runs, total = J.runs(map, WORLD_DOTS)
  for _, r in ipairs(runs) do
    local c = J.bandColor(r.level)
    for _, pt in ipairs(r.pts) do
      if used >= WORLD_DOTS then break end
      used = used + 1
      local d = wtrail.dots[used]
      if wtrail.disc then d:SetVertexColor(c[1], c[2], c[3], 0.95) else d:SetColorTexture(c[1], c[2], c[3], 0.95) end
      local px, py = pt[1] / 100 * w * z, -pt[2] / 100 * h * z
      d:ClearAllPoints()
      d:SetPoint("CENTER", wtrail, "TOPLEFT", px, py)
      d.edge:ClearAllPoints()
      d.edge:SetPoint("CENTER", wtrail, "TOPLEFT", px, py)
      d:Show(); d.edge:Show()
    end
  end
  local pins = 0
  for _, e in ipairs(J.pinsOn(map)) do
    local file = PIN[e.k]
    if file and pins < WORLD_PINS then
      pins = pins + 1
      local p = wtrail.pins[pins]
      if p:SetTexture(file) == false then p:Hide(); pins = pins - 1
      else
        p:ClearAllPoints()
        p:SetPoint("CENTER", wtrail, "TOPLEFT", e.x / 100 * w * z, -e.y / 100 * h * z)
        p:Show()
      end
    end
  end
  wtrail:Show()
  J.worldLine = used .. " dots of " .. total .. " points and " .. pins .. " pins on map " .. map
end

----------------------------------------------------------------------------
-- The Journey tab
----------------------------------------------------------------------------

local filter = 1 -- All, Quests, Battles, Travels, Deaths
local FILTERS = { "All", "Quests", "Battles", "Travels", "Deaths" }
local FILTER_KINDS = {
  { }, { quest = true, chain = true, elite = true }, { dungeon = true, boss = true, elite = true },
  { zone = true, flight = true, pal = true, start = true }, { death = true },
}
local showAll, mapPick, highlight
local confirmReset, confirmAt

local function duration(seconds)
  local minutes = math.floor((tonumber(seconds) or 0) / 60 + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return math.floor(minutes / 60) .. " h " .. (minutes % 60) .. " min"
end
local function plural(n, word) return n .. " " .. word .. (n == 1 and "" or "s") end

local DEATH_INK = { 0.55, 0.12, 0.1 }
local function roman(n)
  n = math.max(1, math.min(3999, math.floor(tonumber(n) or 1)))
  local out = ""
  for _, p in ipairs({ { 1000, "M" }, { 900, "CM" }, { 500, "D" }, { 400, "CD" }, { 100, "C" }, { 90, "XC" }, { 50, "L" },
      { 40, "XL" }, { 10, "X" }, { 9, "IX" }, { 5, "V" }, { 4, "IV" }, { 1, "I" } }) do
    while n >= p[1] do out, n = out .. p[2], n - p[1] end
  end
  return out
end
J.roman = roman

local function dayOf(j, t)
  return math.max(1, math.floor(((tonumber(t) or 0) - (tonumber(j.started) or 0)) / 86400) + 1)
end

-- The zone map drawn to fit (x, y, w, h); false without map art.
local function mapArt(U, C, map, x, y, w, h)
  local layers = try(C_Map and C_Map.GetMapArtLayers, map)
  local files = try(C_Map and C_Map.GetMapArtLayerTextures, map, 1)
  local layer = type(layers) == "table" and layers[1]
  if type(layer) ~= "table" or type(files) ~= "table" then return false end
  local lw, lh = tonumber(layer.layerWidth), tonumber(layer.layerHeight)
  local tw, th = tonumber(layer.tileWidth), tonumber(layer.tileHeight)
  if not (lw and lh and tw and th) or lw <= 0 or lh <= 0 or tw <= 0 or th <= 0 then return false end
  local cols, rows = math.ceil(lw / tw), math.ceil(lh / th)
  if cols * rows > 64 then return false end
  local sx, sy = w / lw, h / lh
  local function tile(file, tx, ty, pw, ph, fw, fh, sub)
    local r, b = math.min(tx + pw, lw), math.min(ty + ph, lh)
    if r <= tx or b <= ty or not file then return end
    local t = U.rect(x + tx * sx, y + ty * sy, (r - tx) * sx, (b - ty) * sy, C.panel, "border", sub, "journeyTile")
    if t:SetTexture(file) == false then t:Hide(); return end
    t:SetTexCoord(0, (r - tx) / fw, 0, (b - ty) / fh)
    t:SetVertexColor(1, 1, 1, 1)
  end
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do tile(files[row * cols + col + 1], col * tw, row * th, tw, th, tw, th, -3) end
  end
  local explored = try(C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures, map)
  local function padded(n) local s = 16; while s < n do s = s * 2 end; return s end
  for _, region in ipairs(type(explored) == "table" and explored or {}) do
    local rw, rh = tonumber(region.textureWidth), tonumber(region.textureHeight)
    local ox, oy = tonumber(region.offsetX), tonumber(region.offsetY)
    if rw and rh and ox and oy and rw > 0 and rh > 0 and type(region.fileDataIDs) == "table" and not region.isShownByMouseOver then
      local nc, nr = math.ceil(rw / tw), math.ceil(rh / th)
      if nc * nr <= 64 then
        for row = 0, nr - 1 do
          for col = 0, nc - 1 do
            local pw, ph = math.min(tw, rw - col * tw), math.min(th, rh - row * th)
            tile(region.fileDataIDs[row * nc + col + 1], ox + col * tw, oy + row * th, pw, ph,
              col == nc - 1 and padded(pw) or tw, row == nr - 1 and padded(ph) or th, -2)
          end
        end
      end
    end
  end
  return true
end

-- The parchment book page behind everything else in a section.
local function page(U, C, x, y, w, h)
  U.box(x, y, w, h, C.parch)
end

local function render()
  local U, C = ns.ui, ns.C
  local W = U.W
  local j = J.data()
  local lvl = level()
  local name = Q.plain(try(UnitName, "player") or "Adventurer")
  local className = Q.plain((try(UnitClass, "player")) or "")
  local race = Q.plain((try(UnitRace, "player")) or "")
  local st = ns.stats and select(2, ns.stats.data())
  if ns.settingsLost or not st then st = ns.stats and (ns.stats.data()) end
  local totals = st and st.totals or {}
  local _, curName = here()
  local y = 0

  -- 1. The cover: the title page of your book.
  local coverH = 124
  page(U, C, 0, y, W, coverH)
  -- the portrait in a gold frame
  U.rect(14, y + 18, 72, 72, C.edge, "border", 2)
  U.rect(16, y + 20, 68, 68, { 0, 0, 0, 1 }, "border", 3)
  U.playerPortrait(18, y + 22, 64, select(2, try(UnitClass, "player")) or "WARRIOR", true)
  U.T("THE JOURNEY OF", 104, y + 18, W - 220, "label", C.inkSoft)
  U.T(name:upper(), 104, y + 32, W - 220, "title", C.ink)
  -- a thin rule under the name, fading out to the right
  local rule = U.rect(104, y + 64, 260, 1, { 1, 1, 1, 1 }, "border", 3, "fade")
  local ink = C.ink or C.light
  ns.fade(rule, "HORIZONTAL", ink[1], ink[2], ink[3], 0.5, 0)
  U.T((race ~= "" and (race .. " ") or "") .. className .. ", level " .. lvl
    .. (curName and ("  -  now in " .. curName) or ""), 104, y + 72, W - 220, "body", C.inkSoft)
  U.T("Day " .. dayOf(j, now()) .. " of the journey, " .. plural(#j.events, "moment") .. " written so far",
    104, y + 92, W - 220, "small", C.inkSoft)
  -- the chapter you're in, set large on the right like a book's running head
  U.T("CHAPTER", W - 118, y + 26, 100, "label", C.inkSoft, "CENTER")
  U.T(roman(lvl), W - 118, y + 40, 100, "title", C.ink, "CENTER")
  U.T(lvl >= 60 and "the summit" or "of 60", W - 118, y + 72, 100, "small", C.inkSoft, "CENTER")
  y = y + coverH + 8
  if ns.settingsLost then
    y = y + U.T("Forever didn't load your saved journal: this chapter of the story starts at this login.", 0, y, W,
      "small", C.dim) + 8
  end

  -- 2. Seals: the journey in numbers.
  local miles = (tonumber(j.walked) or 0) / 1760
  local seals = {
    { "INV_Misc_Note_01", ns.thousands(tonumber(totals.quests) or 0), "quests done", "Quests turned in." },
    { "Ability_Warrior_Rampage", ns.thousands(tonumber(totals.kills) or 0), "foes defeated", "Creatures that gave you experience." },
    { "INV_Misc_Map_01", tostring(#j.order), "lands explored", "Zones you have set foot in." },
    { "Ability_Tracking", string.format("%.1f", miles), "miles walked",
      "Measured along your trail, on foot and mounted (flights don't count)." },
    { "INV_Misc_Key_03", ns.thousands(tonumber(totals.dungeons) or 0), "dungeons", "Dungeon runs." },
    { "INV_Misc_Bone_HumanSkull_01", ns.thousands(tonumber(j.deaths) or 0), "deaths", "Every fall, and every time you got back up." },
  }
  local sw = math.floor((W - 5 * 8) / 6)
  for i, s in ipairs(seals) do
    local sx = (i - 1) * (sw + 8)
    U.box(sx, y, sw, 70, C.panel, C.edge)
    U.icon(s[1], sx + math.floor(sw / 2) - 12, y + 8, 24, s[3]:sub(1, 1):upper() .. s[3]:sub(2), s[4])
    U.T(s[2], sx + 4, y + 36, sw - 8, "head", C.gold, "CENTER")
    U.T(s[3], sx + 4, y + 55, sw - 8, "small", C.dim, "CENTER")
  end
  y = y + 78

  -- 3. The road from 1 to 60: one notch per level, coloured by band, stars on the levels reached.
  local roadH = 64
  U.box(0, y, W, roadH, C.panel, C.edge)
  U.T("THE ROAD TO 60", 14, y + 8, W - 28, "label", C.gold)
  U.T(lvl >= 60 and "the summit reached" or ("level " .. lvl .. " of 60, " .. (60 - lvl) .. " to go"), 14, y + 8, W - 28,
    "small", C.light, "RIGHT")
  local rx, rw = 14, W - 28
  local notch = rw / 60
  local ny = y + 32
  for l = 1, 60 do
    local c = J.bandColor(l)
    local nx = rx + (l - 1) * notch
    local reached = l <= lvl
    local tall = l == lvl and 4 or 0
    U.rect(nx + 0.5, ny - tall / 2, math.max(1, notch - 1.5), 10 + tall, reached and { c[1], c[2], c[3], l == lvl and 1 or 0.85 }
      or { c[1], c[2], c[3], 0.16 })
    local rec = ns.stats and ns.stats.levelRecord(l)
    local tip = rec and (duration(rec.seconds) .. " on this level, " .. plural(tonumber(rec.quests) or 0, "quest")
      .. ", " .. plural(tonumber(rec.kills) or 0, "kill") .. ", " .. plural(tonumber(rec.deaths) or 0, "death"))
      or (l == lvl and "You are here." or reached and "Before the journal began." or "Still ahead.")
    U.hit(nx, ny - 6, math.max(2, notch), 22, "Level " .. l, tip, nil, "Road level " .. l)
  end
  -- you, a star over your level
  local sx = rx + (lvl - 0.5) * notch - 8
  local star = U.rect(sx, ny - 19, 16, 16, C.gold, nil, nil, "journeyPin", true)
  if star:SetTexture(PIN.level) == false then star:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
  else star:SetTexCoord(0, 1, 0, 1); star:SetVertexColor(1, 1, 1, 1) end
  for l = 10, 60, 10 do U.T(tostring(l), rx + (l - 0.5) * notch - 10, ny + 14, 20, "small", l <= lvl and C.light or C.dim, "CENTER") end
  y = y + roadH + 10

  -- 4. The map: the trail on the chosen zone.
  -- every map with a trail or a pinned moment, in the order you first saw it
  local maps, listed = {}, {}
  local function addMap(m) if m and not listed[m] then listed[m] = true; maps[#maps + 1] = m end end
  local pinned = {}
  for _, e in ipairs(j.events) do if e.m then pinned[e.m] = true end end
  for _, m in ipairs(j.order) do if j.trail[m] or pinned[m] then addMap(m) end end
  for _, e in ipairs(j.events) do if e.m and (j.trail[e.m] or pinned[e.m]) then addMap(e.m) end end
  for m in pairs(j.trail) do addMap(m) end
  local curMap = Q.position()
  if not mapPick then
    for _, m in ipairs(maps) do if m == curMap then mapPick = m end end
    mapPick = mapPick or maps[#maps]
  end
  local idx = 1
  for i, m in ipairs(maps) do if m == mapPick then idx = i end end
  local mapTop = y
  U.T("THE MAP", 14, y + 10, W - 28, "label", C.gold)
  y = y + 32
  if #maps == 0 then
    y = y + U.T("Your trail appears here as you travel: every road you walk, coloured by your level, with stars where you grew stronger and skulls where you fell.",
      14, y, W - 28, "small", C.dim) + 10
  else
    local _, mapName = zoneOf(mapPick)
    if mapPick and j.zones[mapPick] then mapName = j.zones[mapPick].name or mapName end
    U.btn("<", 14, y, 28, function() mapPick = maps[(idx - 2) % #maps + 1]; highlight = nil; U.refresh() end, false,
      "The previous land on your journey.")
    U.T(Q.plain(mapName or "?"), 46, y - 1, W - 92, "head", C.light, "CENTER")
    local zrec = j.zones[mapPick]
    U.T((zrec and zrec.level and ("first reached at level " .. zrec.level .. ", day " .. dayOf(j, zrec.first) .. "  -  ") or "")
      .. "land " .. idx .. " of " .. #maps, 46, y + 21, W - 92, "small", C.dim, "CENTER")
    U.btn(">", W - 42, y, 28, function() mapPick = maps[idx % #maps + 1]; highlight = nil; U.refresh() end, false,
      "The next land on your journey.")
    y = y + 40
    local mw = W - 28
    local mh = math.floor(mw * 668 / 1002)
    local mx, my = 14, y
    -- a double frame around the map, like a page plate
    U.rect(mx - 4, my - 4, mw + 8, mh + 8, C.edge, "border", -5)
    U.rect(mx - 3, my - 3, mw + 6, mh + 6, { 0, 0, 0, 1 }, "border", -5)
    U.rect(mx - 1, my - 1, mw + 2, mh + 2, C.edgeSoft, "border", -4)
    if not mapArt(U, C, mapPick, mx, my, mw, mh) then
      U.rect(mx, my, mw, mh, C.parch, "border", -3)
      local ink = C.ink or C.light
      for g = 1, 9 do
        U.rect(mx + mw * g / 10, my, 1, mh, { ink[1], ink[2], ink[3], 0.08 }, "border", -2)
        U.rect(mx, my + mh * g / 10, mw, 1, { ink[1], ink[2], ink[3], 0.08 }, "border", -2)
      end
      U.T(Q.plain(mapName or ""), mx, my + mh / 2 - 10, mw, "head", { ink[1], ink[2], ink[3], 0.35 }, "CENTER")
    end
    local disc = ns.art.hasFile(ns.art.FILES.circle) and ns.art.FILES.circle
    -- the trail: each dot a bright centre on a dark halo, so it reads on light and dark map art
    local runs = J.runs(mapPick, 400)
    for _, r in ipairs(runs) do
      local c = J.bandColor(r.level)
      for _, pt in ipairs(r.pts) do
        local cx, cy = mx + pt[1] / 100 * mw, my + pt[2] / 100 * mh
        local halo = U.rect(cx - 3.5, cy - 3.5, 7, 7, { 0.08, 0.05, 0.02, 0.55 }, "border", 1, "journeyHalo")
        if disc then halo:SetTexture(disc); halo:SetVertexColor(0.08, 0.05, 0.02, 0.55) end
        local d = U.rect(cx - 2, cy - 2, 4, 4, { c[1], c[2], c[3], 1 }, "border", 2, "journeyDot")
        if disc then d:SetTexture(disc); d:SetVertexColor(c[1], c[2], c[3], 1) end
      end
    end
    -- you, when this is the map you're on
    local hereMap, hx, hy = Q.position()
    if hereMap == mapPick and hx and hy then
      local cx, cy = mx + hx / 100 * mw, my + hy / 100 * mh
      local ring = U.rect(cx - 8, cy - 8, 16, 16, { 0, 0, 0, 0.8 }, nil, nil, "journeyRing", true)
      if disc then ring:SetTexture(disc); ring:SetVertexColor(0, 0, 0, 0.8) end
      local me = U.rect(cx - 5, cy - 5, 10, 10, C.gold, nil, 1, "journeyRing", true)
      if disc then me:SetTexture(disc); me:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 1) end
      U.T("You", cx + 8, cy - 7, 40, "small", C.gold, nil, true)
      U.hit(cx - 8, cy - 8, 16, 16, "You are here", nil, nil, "You are here")
    end
    for _, e in ipairs(J.pinsOn(mapPick)) do
      local file = PIN[e.k]
      local big = highlight == e
      if file or big then
        local size = big and 22 or 14
        local px, py = mx + e.x / 100 * mw - size / 2, my + e.y / 100 * mh - size / 2
        if big then
          local ring = U.rect(px - 4, py - 4, size + 8, size + 8, C.gold, nil, nil, "journeyRing", true)
          if disc then ring:SetTexture(disc); ring:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.6) end
        end
        local t = U.rect(px, py, size, size, { 1, 1, 1, 1 }, nil, 2, "journeyPin", true)
        if t:SetTexture(file or PIN.level) == false then t:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1) end
        t:SetTexCoord(0, 1, 0, 1)
        t:SetVertexColor(1, 1, 1, 1)
        U.hit(px, py, size, size, e.s, "Level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t), nil, "Pin " .. e.s)
      end
    end
    y = y + mh + 8
    -- the legend
    local lx = 14
    for _, b in ipairs(J.BANDS) do
      local dot = U.rect(lx, y + 2, 10, 10, b[3], nil, nil, "journeyDot")
      if disc then dot:SetTexture(disc); dot:SetVertexColor(b[3][1], b[3][2], b[3][3], 1) end
      U.T(b[4], lx + 13, y + 1, 44, "small", C.dim)
      lx = lx + 56
    end
    -- the pins, drawn as they are on the map
    local kx = W - 14 - 150
    for _, k in ipairs({ { "level", "level up" }, { "death", "fell" } }) do
      local t = U.rect(kx, y, 14, 14, { 1, 1, 1, 1 }, nil, 2, "journeyPin", true)
      if t:SetTexture(PIN[k[1]]) == false then t:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
      else t:SetTexCoord(0, 1, 0, 1); t:SetVertexColor(1, 1, 1, 1) end
      U.T(k[2], kx + 18, y + 1, 56, "small", C.dim)
      kx = kx + 78
    end
    y = y + 22
  end
  U.box(0, mapTop, W, y - mapTop, C.panel, C.edge)
  y = y + 10
  U.check("Show my trail on the world map", 0, y, not ns.db().noJourneyMap, function()
    local db = LevelingCodexDB
    if type(db) == "table" then db.noJourneyMap = not db.noJourneyMap or nil end
    J.drawWorld(true)
    U.refresh()
  end, "Draws your trail, level stars and skulls on the world map you have open.")
  U.check("Record my trail", W / 2, y, not ns.db().noJourneyTrail, function()
    local db = LevelingCodexDB
    if type(db) == "table" then db.noJourneyTrail = not db.noJourneyTrail or nil end
    last = nil
    U.refresh()
  end, "Keeps a breadcrumb every 35 yards you walk. The journal's moments are written either way.")
  y = y + 34

  -- 5. The story: chapters by level, newest first.
  U.sectionTitle("THE STORY SO FAR", y)
  y = y + 30
  U.segments(0, y, W, FILTERS, filter, function(i) filter = i; U.refresh() end,
    { "Every moment.", "Quests and the stories they finished.", "Dungeons, bosses and elite foes.",
      "New lands, flight paths and companions.", "Every time you fell." })
  y = y + 32
  local kinds = FILTER_KINDS[filter]
  local chapters, byLevel = {}, {}
  for i = #j.events, 1, -1 do
    local e = j.events[i]
    local l = tonumber(e.l) or 1
    if not byLevel[l] then byLevel[l] = {}; chapters[#chapters + 1] = l end
    if filter == 1 or kinds[e.k] or e.k == "level" then table.insert(byLevel[l], e) end
  end
  table.sort(chapters, function(a, b) return a > b end)
  if #chapters == 0 then
    page(U, C, 0, y, W, 60)
    U.T("The first page is still blank. Your story is written here as you go: every level, every land, every quest and every fall.",
      16, y + 14, W - 32, "body", C.ink)
    y = y + 68
  end
  local shownChapters = 0
  for _, l in ipairs(chapters) do
    if shownChapters >= 4 and not showAll then break end
    -- a chapter reads in order: the level-up that opened it is its epigraph, then what happened
    local list, opening = {}, nil
    for i = #byLevel[l], 1, -1 do
      local e = byLevel[l][i]
      if (e.k == "level" or e.k == "start") and not opening then opening = e else list[#list + 1] = e end
    end
    if filter == 1 or #list > 0 then
      shownChapters = shownChapters + 1
      local top = y
      local rec = ns.stats and ns.stats.levelRecord(l)
      -- the land where most of the chapter happened names it
      local count, zoneList, best, bestN = {}, {}, nil, 0
      for _, e in ipairs(byLevel[l]) do
        local zn = e.m and select(2, zoneOf(e.m))
        if zn then
          if not count[zn] then count[zn] = 0; zoneList[#zoneList + 1] = zn end
          count[zn] = count[zn] + 1
          if count[zn] > bestN then best, bestN = zn, count[zn] end
        end
      end
      local band = J.bandColor(l)
      U.rect(0, y, W, 3, { band[1], band[2], band[3], 0.85 }, "border", 3)
      U.T("CHAPTER " .. roman(l), 18, y + 12, W - 36, "label", C.inkSoft)
      if l == lvl then U.T("you are here", 18, y + 12, W - 36, "small", C.inkSoft, "RIGHT") end
      U.T("Level " .. l .. (best and ("  -  " .. best) or ""), 18, y + 26, W - 36, "head", C.ink)
      y = y + 52
      if opening then
        y = y + U.T('"' .. opening.s .. '"', 18, y, W - 36, "body", C.inkSoft) + 6
      end
      local facts = {}
      if rec then
        facts[1] = duration(rec.seconds) .. ", " .. plural(tonumber(rec.quests) or 0, "quest") .. ", "
          .. plural(tonumber(rec.kills) or 0, "foe") .. ", " .. plural(tonumber(rec.deaths) or 0, "fall")
      end
      if #zoneList > 1 then facts[#facts + 1] = "through " .. table.concat(zoneList, ", ") end
      if #facts > 0 then
        y = y + U.T(table.concat(facts, "  -  "), 18, y, W - 36, "small", C.inkSoft) + 6
      end
      U.rect(18, y + 2, W - 36, 1, { band[1], band[2], band[3], 0.35 }, "border", 3)
      y = y + 12
      local limit = showAll and 999 or 8
      local drawn, spineTop, spineEnd = 0, nil, nil
      local lastDay
      for _, e in ipairs(list) do
        if drawn >= limit then break end
        drawn = drawn + 1
        spineTop = spineTop or (y + 10)
        spineEnd = y + 10
        U.icon(ICON[e.k] or ICON.quest, 18, y, 22, e.s, e.d)
        local th = U.T(e.s, 50, y + 3, W - 140, "body", e.k == "death" and DEATH_INK or C.ink)
        local day = dayOf(j, e.t)
        if day ~= lastDay then U.T("day " .. day, W - 84, y + 4, 66, "small", C.inkSoft, "RIGHT") end
        lastDay = day
        local rowH = math.max(24, th + 6)
        if e.d then
          rowH = rowH + U.T(e.d, 50, y + th + 5, W - 140, "small", C.inkSoft) + 2
        end
        if e.m and e.x then
          U.hit(14, y - 2, W - 28, rowH + 2, e.s, (e.d and (e.d .. "\n") or "") .. "Click to show where it happened.", function()
            mapPick, highlight = e.m, e
            U.refresh()
          end, "Moment " .. e.s)
        end
        y = y + rowH + 6
      end
      -- the timeline's spine behind the icons
      if spineTop and spineEnd > spineTop then
        U.rect(28, spineTop, 2, spineEnd - spineTop, { band[1], band[2], band[3], 0.5 }, "border", 3)
      end
      if #list > drawn then
        y = y + U.T("... and " .. plural(#list - drawn, "more moment") .. " in this chapter (Read the whole story).", 50, y, W - 68,
          "small", C.inkSoft) + 6
      end
      if #list == 0 then
        y = y + U.T("A quiet chapter: nothing else written yet.", 18, y, W - 36, "small", C.inkSoft) + 6
      end
      y = y + 10
      page(U, C, 0, top, W, y - top)
      y = y + 10
    end
  end
  if #chapters > 4 or showAll then
    U.btn(showAll and "Show the last chapters" or "Read the whole story", 0, y, 200, function()
      showAll = not showAll
      U.refresh()
    end, showAll)
    y = y + 32
  end

  -- 6. Companions.
  local pals = {}
  for pname, rec in pairs(j.pals) do
    if type(rec) == "table" then pals[#pals + 1] = { name = pname, rec = rec } end
  end
  table.sort(pals, function(a, b) return (tonumber(a.rec.seconds) or 0) > (tonumber(b.rec.seconds) or 0) end)
  local palTop = y
  U.T("FELLOW ADVENTURERS", 14, y + 10, W - 28, "label", C.gold)
  y = y + 32
  if #pals == 0 then
    y = y + U.T("Nobody has shared the road with you yet. Group up and they are remembered here.", 14, y, W - 28, "small", C.dim) + 8
  end
  local most = math.max(60, pals[1] and tonumber(pals[1].rec.seconds) or 60)
  for i, p in ipairs(pals) do
    if i > 6 then break end
    local token = type(p.rec.class) == "string" and p.rec.class or nil
    local cls = token and (token:sub(1, 1) .. token:sub(2):lower()) or ""
    local cc = token and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[token]
    local nameColor = type(cc) == "table" and tonumber(cc.r) and { cc.r, cc.g, cc.b } or C.light
    if token then U.icon("classicon_" .. token:lower(), 14, y, 22, cls, nil) end
    U.T(Q.plain(p.name), 44, y + 1, 150, "body", nameColor)
    U.T(cls .. (p.rec.level and ("  -  met at level " .. p.rec.level) or ""), 44, y + 15, 200, "small", C.dim)
    local secs = tonumber(p.rec.seconds) or 0
    local bx, bw = 250, W - 14 - 250 - 120
    U.rect(bx, y + 8, bw, 6, { 0.05, 0.05, 0.08, 0.9 })
    U.rect(bx, y + 8, math.max(2, bw * secs / most), 6, nameColor)
    U.T(secs < 60 and "just met" or (duration(secs) .. " together"), W - 14 - 114, y + 5, 114, "small", C.light, "RIGHT")
    y = y + 32
  end
  y = y + 6
  U.box(0, palTop, W, y - palTop, C.panel, C.edge)
  y = y + 12

  -- 7. Erase, two clicks within 5 s.
  local armed = confirmReset and GetTime() - (confirmAt or 0) < 5
  U.btn(armed and "Click again to erase" or "Erase the journal", 0, y, 200, function()
    if confirmReset and GetTime() - (confirmAt or 0) < 5 then
      confirmReset, mapPick, highlight = nil, nil, nil
      J.reset()
      ns.say("journal erased: a fresh page.")
    else
      confirmReset, confirmAt = true, GetTime()
    end
    U.refresh()
  end, armed, "Erases every moment and your whole trail. Click twice to confirm.")
  return y + 40
end

ns.addTab("journey", "Journey", render)
