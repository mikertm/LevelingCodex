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
  close = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- the cross: nearly fell here
  rare = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", -- the triangle
  first = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", -- the diamond
  pvp = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", -- the moon: a fight with another player
  camp = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", -- the circle: a campfire
}
J.PIN = PIN
local ICON = {
  level = "Spell_Holy_SurgeOfLight", zone = "INV_Misc_Map_01", quest = "INV_Misc_Note_01",
  chain = "INV_Misc_Book_09", elite = "Ability_Warrior_BattleShout", dungeon = "INV_Misc_Key_03",
  boss = "INV_Misc_Head_Dragon_01", death = "INV_Misc_Bone_HumanSkull_01", flight = "Ability_Mount_Gryphon_01",
  pal = "Spell_Holy_PrayerOfHealing", start = "INV_Misc_Book_11", first = "INV_Misc_Bag_08",
  close = "Spell_Holy_SealOfSacrifice", upgrade = "INV_Chest_Chain", rare = "Ability_Hunter_SniperShot",
  cap = "Trade_BlackSmithing", wipe = "Spell_Shadow_DeathScream", run = "INV_Misc_Key_14",
  pvp = "Ability_DualWield", bg = "INV_BannerPVP_02", duel = "Ability_Parry", rez = "Spell_Holy_Resurrection",
  trade = "INV_Misc_Coin_02", emote = "Spell_Holy_Heal", guild = "INV_Misc_TabardSummer01", camp = "Spell_Fire_Fire",
  craft = "Trade_Engineering", skill = "INV_Misc_Book_08", auction = "INV_Misc_Coin_04", sold = "INV_Misc_Coin_01",
  expired = "INV_Misc_Bag_10", gold = "INV_Misc_Coin_03", abandon = "INV_Misc_Note_02",
}
J.ICON = ICON

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
J.pick, J.fill = pick, fill

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
J.partyText, J.partyNames, J.inInstance, J.here = partyText, partyNames, inInstance, here

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
local PVP_DEATH = { "Ambushed by %killer% in %zone%. Not every enemy in Azeroth is a monster",
  "Cut down by %killer% in %zone%: the war is real", "Fell to %killer% in %zone%, and swore to remember the name" }
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

J.finisher = finisher

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

-- Moments the journal never drops to make room: the story's spine and its trophies.
J.KEEP = { level = true, zone = true, start = true, boss = true, first = true, cap = true, rare = true }

-- Add a moment. fields: k (kind), s (text), d (detail), q (quest), at = { map, x, y } (else where you are).
function J.add(kind, text, detail, extra)
  local j = J.data()
  local _, _, map, x, y = here()
  local e = { t = now(), k = kind, l = level(), s = Q.plain(text or ""), d = detail and Q.plain(detail) or nil }
  if extra and extra.at then map, x, y = extra.at[1], extra.at[2], extra.at[3] end
  if extra and extra.q then e.q = extra.q end
  if extra and extra.l then e.l = extra.l end
  for _, f in ipairs({ "who", "i", "iq", "fk", "pct", "n", "pvp", "c" }) do
    if extra and extra[f] ~= nil then e[f] = type(extra[f]) == "string" and Q.plain(extra[f]) or extra[f] end
  end
  if map and x and y and not inInstance() then
    e.m, e.x, e.y = map, math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10
  end
  local events = j.events
  events[#events + 1] = e
  if #events > J.MAX_EVENTS then
    -- drop the oldest small moment; levels and new zones are the story's spine
    for i = 1, #events do
      if not J.KEEP[events[i].k] then table.remove(events, i); break end
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
J.zoneName = zoneName

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
  local wipes = J.wipesOn and J.wipesOn(name) or 0
  local detail = dungeonHere and Q.plain(dungeonHere)
  if wipes > 0 then detail = (detail and (detail .. ", ") or "") .. "after " .. wipes .. (wipes == 1 and " wipe" or " wipes") end
  J.add("boss", J.bossLine(name, dungeonHere), detail)
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
    local enemy = killer and try(UnitIsPlayer, "target")
    if enemy == true or enemy == 1 then
      -- another player: a line of its own, with who they were
      j.pvpDeaths = (tonumber(j.pvpDeaths) or 0) + 1
      local race, cls = try(UnitRace, "target"), try(UnitClass, "target")
      local who = Q.plain(killer) .. ((race or cls) and (", " .. Q.plain(((race or "") .. " " .. (cls or "")):gsub("^ ", ""))) or "")
      if J.onDeath then J.onDeath() end
      local zone = zoneName()
      J.add("death", fill(pick(PVP_DEATH, killer .. j.deaths), { killer = who, zone = zone }), "Death " .. j.deaths
        .. " (another player)", { who = killer, pvp = true })
      return
    end
    -- no hostile target: the last foe you fought this fight (JourneyDeeds.lua)
    if not killer and J.lastFoe then killer = J.lastFoe() end
    if J.onDeath then J.onDeath() end
    local zone = zoneName()
    local text = killer and fill(pick(DEATH, killer .. j.deaths), { killer = Q.plain(killer), zone = zone })
      or fill(pick(DEATH_PLAIN, zone .. j.deaths), { zone = zone })
    J.add("death", text, "Death " .. j.deaths, { who = killer })
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

-- Every run on a map (only those walked at onlyLevel, when given), thinned to at most `cap` points
-- overall: { { x, y, level }, ... } per run.
function J.runs(map, cap, onlyLevel)
  local j = J.data()
  local runs, total = {}, 0
  for _, r in ipairs(j.trail[map] or {}) do
    if not onlyLevel or r.l == onlyLevel then
      local pts = J.unpack(r.p)
      total = total + #pts
      runs[#runs + 1] = { level = r.l, pts = pts }
    end
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
function J.pinsOn(map, onlyLevel)
  local out = {}
  for _, e in ipairs(J.data().events) do
    if e.m == map and e.x and e.y and (not onlyLevel or tonumber(e.l) == onlyLevel) then out[#out + 1] = e end
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

local filter = 1 -- All, Quests, Battles, Treasures, Travels, Deaths
local FILTERS = { "All", "Quests", "Battles", "Fortunes", "Fellowship", "Travels", "Deaths" }
local FILTER_KINDS = {
  { },
  { quest = true, chain = true, elite = true, abandon = true },
  { dungeon = true, boss = true, elite = true, close = true, rare = true, wipe = true, run = true, pvp = true, bg = true, duel = true },
  { first = true, upgrade = true, cap = true, craft = true, skill = true, auction = true, sold = true, expired = true, gold = true },
  { pal = true, rez = true, trade = true, duel = true, emote = true, guild = true, camp = true, run = true },
  { zone = true, flight = true, start = true, camp = true },
  { death = true, close = true, wipe = true, expired = true, abandon = true },
}
local FILTER_TIPS = { "Every moment.", "Quests and the stories they finished, and the ones you gave up.",
  "Dungeons, bosses, wipes, elites, rares, close calls, duels, battlegrounds and fights with other players.",
  "Firsts, gear upgrades, crafting, professions, the auction house and your purse.",
  "Companions, dungeon parties, resurrections, trades, duels, waves and campfires.",
  "New lands, flight paths and campfires.", "Every fall, wipe, near miss and lost cause." }
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

-- The pages of the journal, one at a time instead of one long scroll. Other files add pages with
-- J.addPage(name, tip, draw, after) (draw(V, y) -> y); a page is opened by name.
local PAGES = {
  { name = "Overview", tip = "Your journey at a glance: today's entry, the numbers, the road, the latest chapter and where you are." },
  { name = "Story", tip = "Every chapter of your story, level by level, each with its own map." },
  { name = "Map", tip = "Your trail on every land you have walked, and the lands explored." },
  { name = "Trophies", tip = "Your firsts, your nemeses, close calls, rares, bosses, upgrades and crafts." },
  { name = "Companions", tip = "Everyone who shared the road with you." },
}
local P_OVERVIEW, P_STORY, P_MAP, P_TROPHIES, P_COMPANIONS = "Overview", "Story", "Map", "Trophies", "Companions"
local pageName = P_OVERVIEW
local function openPage(name, U) pageName = name; U.refreshTop() end
J.openPage = function(name) openPage(name, ns.ui) end
function J.addPage(name, tip, draw, after)
  for _, p in ipairs(PAGES) do if p.name == name then p.tip, p.draw = tip, draw; return end end
  local at = #PAGES + 1
  for i, p in ipairs(PAGES) do if p.name == after then at = i + 1 end end
  table.insert(PAGES, at, { name = name, tip = tip, draw = draw })
end

-- One disc-shaped dot (a square without the circle art).
local function disc(U, x, y, size, c, sub, kind, onTop)
  local file = ns.art.hasFile(ns.art.FILES.circle) and ns.art.FILES.circle
  local t = U.rect(x, y, size, size, c, onTop and nil or "border", sub, kind, onTop)
  if file then t:SetTexture(file); t:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
  return t
end

-- A pin's art, gold when the file is missing.
local function pinArt(U, C, file, x, y, size)
  local t = U.rect(x, y, size, size, { 1, 1, 1, 1 }, nil, 2, "journeyPin", true)
  if t:SetTexture(file) == false then t:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
  else t:SetTexCoord(0, 1, 0, 1); t:SetVertexColor(1, 1, 1, 1) end
  return t
end

-- Every map with a trail or a pinned moment, in the order you first saw it.
local function mapList(j)
  local maps, listed = {}, {}
  local function addMap(m) if m and not listed[m] then listed[m] = true; maps[#maps + 1] = m end end
  local pinned = {}
  for _, e in ipairs(j.events) do if e.m then pinned[e.m] = true end end
  for _, m in ipairs(j.order) do if j.trail[m] or pinned[m] then addMap(m) end end
  for _, e in ipairs(j.events) do if e.m and (j.trail[e.m] or pinned[e.m]) then addMap(e.m) end end
  for m in pairs(j.trail) do addMap(m) end
  return maps
end

local function mapLabel(j, map)
  local _, name = zoneOf(map)
  if map and j.zones[map] then name = j.zones[map].name or name end
  return Q.plain(name or "?")
end

-- The map plate at (mx, my, mw x mh): art or a gridded parchment, the trail, you and the pins.
local function drawPlate(V, map, mx, my, mw, mh, pinSize, onlyLevel)
  local U, C, j = V.U, V.C, V.j
  U.rect(mx - 4, my - 4, mw + 8, mh + 8, C.edge, "border", -5)
  U.rect(mx - 3, my - 3, mw + 6, mh + 6, { 0, 0, 0, 1 }, "border", -5)
  U.rect(mx - 1, my - 1, mw + 2, mh + 2, C.edgeSoft, "border", -4)
  if not mapArt(U, C, map, mx, my, mw, mh) then
    U.rect(mx, my, mw, mh, C.parch, "border", -3)
    local ink = C.ink or C.light
    for g = 1, 9 do
      U.rect(mx + mw * g / 10, my, 1, mh, { ink[1], ink[2], ink[3], 0.08 }, "border", -2)
      U.rect(mx, my + mh * g / 10, mw, 1, { ink[1], ink[2], ink[3], 0.08 }, "border", -2)
    end
    U.T(mapLabel(j, map), mx, my + mh / 2 - 10, mw, "head", { ink[1], ink[2], ink[3], 0.35 }, "CENTER")
  end
  -- the trail: each dot a bright centre on a dark halo, so it reads on light and dark map art
  local small = mw < 400
  local hs, ds = small and 5 or 7, small and 3 or 4
  for _, r in ipairs(J.runs(map, small and 200 or 400, onlyLevel)) do
    local c = J.bandColor(r.level)
    for _, pt in ipairs(r.pts) do
      local cx, cy = mx + pt[1] / 100 * mw, my + pt[2] / 100 * mh
      disc(U, cx - hs / 2, cy - hs / 2, hs, { 0.08, 0.05, 0.02, 0.55 }, 1, "journeyHalo")
      disc(U, cx - ds / 2, cy - ds / 2, ds, { c[1], c[2], c[3], 1 }, 2, "journeyDot")
    end
  end
  -- you, when this is the map you're on
  local hereMap, hx, hy = Q.position()
  if hereMap == map and hx and hy and (not onlyLevel or onlyLevel == V.lvl) then
    local cx, cy = mx + hx / 100 * mw, my + hy / 100 * mh
    disc(U, cx - 8, cy - 8, 16, { 0, 0, 0, 0.8 }, nil, "journeyRing", true)
    disc(U, cx - 5, cy - 5, 10, { C.gold[1], C.gold[2], C.gold[3], 1 }, 1, "journeyRing", true)
    U.T("You", cx + 8, cy - 7, 40, "small", C.gold, nil, true)
    U.hit(cx - 8, cy - 8, 16, 16, "You are here", nil, nil, "You are here")
  end
  for _, e in ipairs(J.pinsOn(map, onlyLevel)) do
    local file = PIN[e.k]
    local big = highlight == e
    if file or big then
      local size = big and pinSize + 8 or pinSize
      local px, py = mx + e.x / 100 * mw - size / 2, my + e.y / 100 * mh - size / 2
      if big then disc(U, px - 4, py - 4, size + 8, { C.gold[1], C.gold[2], C.gold[3], 0.6 }, nil, "journeyRing", true) end
      pinArt(U, C, file or PIN.level, px, py, size)
      U.hit(px, py, size, size, e.s, "Level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t), nil, "Pin " .. e.s)
    end
  end
end

local function legend(V, x, y, w)
  local U, C = V.U, V.C
  local lx = x
  for _, b in ipairs(J.BANDS) do
    disc(U, lx, y + 2, 10, b[3], nil, "journeyDot")
    U.T(b[4], lx + 13, y + 1, 44, "small", C.dim)
    lx = lx + 56
  end
  local kx = x + w - 150
  for _, k in ipairs({ { "level", "level up" }, { "death", "fell" } }) do
    pinArt(U, C, PIN[k[1]], kx, y, 14)
    U.T(k[2], kx + 18, y + 1, 56, "small", C.dim)
    kx = kx + 78
  end
  return 22
end

-- Chapters by level, newest first; each with its moments newest first.
local function chapterData(j)
  local kinds = FILTER_KINDS[filter]
  local chapters, byLevel = {}, {}
  for i = #j.events, 1, -1 do
    local e = j.events[i]
    local l = tonumber(e.l) or 1
    if not byLevel[l] then byLevel[l] = {}; chapters[#chapters + 1] = l end
    if filter == 1 or kinds[e.k] or e.k == "level" then table.insert(byLevel[l], e) end
  end
  table.sort(chapters, function(a, b) return a > b end)
  return chapters, byLevel
end

-- The map a chapter's plate shows: the one with the most trail walked at that level, else the most moments.
local function chapterMap(j, l, events)
  local best, most = nil, 0
  for map, runs in pairs(j.trail) do
    local n = 0
    for _, r in ipairs(runs) do if r.l == l then n = n + math.floor(#(r.p or "") / 6) end end
    if n > most then best, most = map, n end
  end
  if best and most >= 3 then return best end
  local count = {}
  for _, e in ipairs(events) do
    if e.m and e.x then
      count[e.m] = (count[e.m] or 0) + 1
      if count[e.m] > most then best, most = e.m, count[e.m] end
    end
  end
  return best
end

-- One chapter card at (x, y), w wide, showing up to limit moments; nil when the filter leaves it empty.
local function drawChapter(V, l, events, x, y, w, limit, compact)
  local U, C, j, lvl = V.U, V.C, V.j, V.lvl
  -- a chapter reads in order: the level-up that opened it is its epigraph, then what happened
  local list, opening = {}, nil
  for i = #events, 1, -1 do
    local e = events[i]
    if (e.k == "level" or e.k == "start") and not opening then opening = e else list[#list + 1] = e end
  end
  if filter ~= 1 and #list == 0 then return nil end
  local top = y
  local rec = ns.stats and ns.stats.levelRecord(l)
  -- the land where most of the chapter happened names it
  local count, zoneList, best, bestN = {}, {}, nil, 0
  for _, e in ipairs(events) do
    local zn = e.m and select(2, zoneOf(e.m))
    if zn then
      if not count[zn] then count[zn] = 0; zoneList[#zoneList + 1] = zn end
      count[zn] = count[zn] + 1
      if count[zn] > bestN then best, bestN = zn, count[zn] end
    end
  end
  local band = J.bandColor(l)
  local ix, iw = x + 16, w - 32
  U.rect(x, y, w, 3, { band[1], band[2], band[3], 0.85 }, "border", 3)
  U.T("CHAPTER " .. roman(l), ix, y + 12, iw, "label", C.inkSoft)
  -- the chapter's plate: the land where you walked most at this level, with that level's trail and marks
  local plateMap, plateBottom = not compact and chapterMap(j, l, events), nil
  local hw = iw
  if plateMap then
    local pw = 176
    local ph = math.floor(pw * 668 / 1002)
    local px, py = x + w - 16 - pw, y + 14
    drawPlate(V, plateMap, px, py, pw, ph, 10, l)
    U.hit(px, py, pw, ph, mapLabel(j, plateMap) .. " at level " .. l, "Click to open it on the map.", function()
      mapPick, highlight = plateMap, nil
      openPage(P_MAP, U)
    end, "Plate level " .. l)
    U.T(mapLabel(j, plateMap), px, py + ph + 5, pw, "small", C.inkSoft, "CENTER")
    plateBottom = py + ph + 20
    hw = iw - pw - 14
  elseif l == lvl then
    U.T("you are here", ix, y + 12, iw, "small", C.inkSoft, "RIGHT")
  end
  y = y + 26
  y = y + U.T("Level " .. l .. (best and ("  -  " .. best) or ""), ix, y, hw, "head", C.ink) + 8
  if plateMap and l == lvl then y = y + U.T("you are here", ix, y - 4, hw, "small", C.inkSoft) + 4 end
  if opening then
    y = y + U.T('"' .. opening.s .. '"', ix, y, hw, compact and "small" or "body", C.inkSoft) + 6
  end
  if not compact then
    local facts = {}
    if rec then
      facts[1] = duration(rec.seconds) .. ", " .. plural(tonumber(rec.quests) or 0, "quest") .. ", "
        .. plural(tonumber(rec.kills) or 0, "foe") .. ", " .. plural(tonumber(rec.deaths) or 0, "fall")
    end
    if #zoneList > 1 then facts[#facts + 1] = "through " .. table.concat(zoneList, ", ") end
    if #facts > 0 then y = y + U.T(table.concat(facts, "  -  "), ix, y, hw, "small", C.inkSoft) + 6 end
  end
  if plateBottom and plateBottom > y then y = plateBottom end
  U.rect(ix, y + 2, iw, 1, { band[1], band[2], band[3], 0.35 }, "border", 3)
  y = y + 12
  -- the overview shows the latest moments, the story reads them in order
  local order = list
  if compact then
    order = {}
    for i = #list, math.max(1, #list - limit + 1), -1 do order[#order + 1] = list[i] end
  end
  local drawn, spineTop, spineEnd, lastDay = 0, nil, nil, nil
  local textW = iw - 34 - (compact and 0 or 70)
  for _, e in ipairs(order) do
    if drawn >= limit then break end
    drawn = drawn + 1
    spineTop = spineTop or (y + 10)
    spineEnd = y + 10
    U.icon(ICON[e.k] or ICON.quest, ix, y, 22, e.s, e.d)
    local th = U.T(e.s, ix + 32, y + 3, textW, compact and "small" or "body", e.k == "death" and DEATH_INK or C.ink)
    local day = dayOf(j, e.t)
    if not compact and day ~= lastDay then U.T("day " .. day, x + w - 82, y + 4, 66, "small", C.inkSoft, "RIGHT") end
    lastDay = day
    local rowH = math.max(24, th + 6)
    if e.d and not compact then rowH = rowH + U.T(e.d, ix + 32, y + th + 5, textW, "small", C.inkSoft) + 2 end
    if e.m and e.x then
      U.hit(x + 12, y - 2, w - 24, rowH + 2, e.s, (e.d and (e.d .. "\n") or "") .. "Click to show where it happened.", function()
        mapPick, highlight = e.m, e
        openPage(P_MAP, U)
      end, "Moment " .. e.s)
    end
    y = y + rowH + (compact and 2 or 6)
  end
  if spineTop and spineEnd > spineTop then
    U.rect(ix + 10, spineTop, 2, spineEnd - spineTop, { band[1], band[2], band[3], 0.5 }, "border", 3)
  end
  if #list > drawn and not compact then
    y = y + U.T("... and " .. plural(#list - drawn, "more moment") .. " in this chapter (Read the whole story).", ix + 32, y,
      iw - 32, "small", C.inkSoft) + 6
  end
  if #list == 0 then y = y + U.T("A quiet chapter: nothing else written yet.", ix, y, iw, "small", C.inkSoft) + 6 end
  y = y + 10
  page(U, C, x, top, w, y - top)
  return y
end

local function palList(j)
  local pals = {}
  for pname, rec in pairs(j.pals) do
    if type(rec) == "table" then pals[#pals + 1] = { name = pname, rec = rec } end
  end
  table.sort(pals, function(a, b) return (tonumber(a.rec.seconds) or 0) > (tonumber(b.rec.seconds) or 0) end)
  return pals
end

-- One companion row at (x, y), w wide; returns its height.
local function palRow(V, p, most, x, y, w, compact)
  local U, C = V.U, V.C
  local token = type(p.rec.class) == "string" and p.rec.class or nil
  local cls = token and (token:sub(1, 1) .. token:sub(2):lower()) or ""
  local cc = token and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[token]
  local nameColor = type(cc) == "table" and tonumber(cc.r) and { cc.r, cc.g, cc.b } or C.light
  if token then U.icon("classicon_" .. token:lower(), x, y, 22, cls, nil) end
  local secs = tonumber(p.rec.seconds) or 0
  local together = secs < 60 and "just met" or (duration(secs) .. " together")
  U.T(Q.plain(p.name), x + 30, y + 1, compact and w - 30 or 150, "body", nameColor)
  if compact then
    U.T(together, x + 30, y + 1, w - 30, "small", C.light, "RIGHT")
    U.rect(x + 30, y + 18, w - 30, 4, { 0.05, 0.05, 0.08, 0.9 })
    U.rect(x + 30, y + 18, math.max(2, (w - 30) * secs / most), 4, nameColor)
    return 30
  end
  U.T(cls .. (p.rec.level and ("  -  met at level " .. p.rec.level) or ""), x + 30, y + 15, 200, "small", C.dim)
  local bx = x + 236
  local bw = w - 236 - 120
  U.rect(bx, y + 8, bw, 6, { 0.05, 0.05, 0.08, 0.9 })
  U.rect(bx, y + 8, math.max(2, bw * secs / most), 6, nameColor)
  U.T(together, x + w - 114, y + 5, 114, "small", C.light, "RIGHT")
  return 32
end

-- The title strip over every page: who you are, where, and the chapter you're in.
local function header(V)
  local U, C, W, j, lvl = V.U, V.C, V.W, V.j, V.lvl
  local h = 92
  page(U, C, 0, 0, W, h)
  U.rect(14, 12, 68, 68, C.edge, "border", 2)
  U.rect(16, 14, 64, 64, { 0, 0, 0, 1 }, "border", 3)
  U.playerPortrait(18, 16, 60, select(2, try(UnitClass, "player")) or "WARRIOR", true)
  U.T("THE JOURNEY OF", 96, 12, W - 220, "label", C.inkSoft)
  U.T(V.name:upper(), 96, 25, W - 220, "title", C.ink)
  local rule = U.rect(96, 56, 260, 1, { 1, 1, 1, 1 }, "border", 3, "fade")
  local ink = C.ink or C.light
  ns.fade(rule, "HORIZONTAL", ink[1], ink[2], ink[3], 0.5, 0)
  U.T((V.race ~= "" and (V.race .. " ") or "") .. V.className .. ", level " .. lvl
    .. (V.curName and ("  -  now in " .. V.curName) or ""), 96, 62, W - 220, "small", C.inkSoft)
  U.T("Day " .. dayOf(j, now()) .. ", " .. plural(#j.events, "moment") .. " written", 96, 76, W - 220, "small", C.inkSoft)
  -- the chapter you're in, set large on the right like a book's running head
  U.rect(W - 112, 14, 1, 64, { ink[1], ink[2], ink[3], 0.2 }, "border", 3)
  U.T("CHAPTER", W - 106, 18, 96, "label", C.inkSoft, "CENTER")
  U.T(roman(lvl), W - 106, 32, 96, "title", C.ink, "CENTER")
  U.T(lvl >= 60 and "the summit" or "of 60", W - 106, 64, 96, "small", C.inkSoft, "CENTER")
  local y = h + 8
  if ns.settingsLost then
    y = y + U.T("Forever didn't load your saved journal: this chapter of the story starts at this login.", 0, y, W,
      "small", C.dim) + 8
  end
  local names, tips, lit = {}, {}, 1
  for i, p in ipairs(PAGES) do
    names[i], tips[i] = p.name, p.tip
    if p.name == pageName then lit = i end
  end
  y = y + U.segments(0, y, W, names, lit, function(i) openPage(PAGES[i].name, U) end, tips) + 12
  return y
end

-- A dark card with a gold label; returns the y its content starts at.
local function cardTitle(V, title, x, y, w, right)
  V.U.T(title, x + 14, y + 10, w - 28, "label", V.C.gold)
  if right then V.U.T(right, x + 14, y + 10, w - 28, "small", V.C.light, "RIGHT") end
  return y + 30
end

local function seals(V, y)
  local U, C, W, j, totals = V.U, V.C, V.W, V.j, V.totals
  local miles = (tonumber(j.walked) or 0) / 1760
  local list = {
    { "INV_Misc_Note_01", ns.thousands(tonumber(totals.quests) or 0), "quests done", "Quests turned in." },
    { "Ability_Warrior_Rampage", ns.thousands(tonumber(totals.kills) or 0), "foes defeated", "Creatures that gave you experience." },
    { "INV_Misc_Map_01", tostring(#j.order), "lands explored", "Zones you have set foot in." },
    { "Ability_Tracking", string.format("%.1f", miles), "miles walked",
      "Measured along your trail, on foot and mounted (flights don't count)." },
    { "INV_Misc_Key_03", ns.thousands(tonumber(totals.dungeons) or 0), "dungeons", "Dungeon runs." },
    { "INV_Misc_Bone_HumanSkull_01", ns.thousands(tonumber(j.deaths) or 0), "deaths", "Every fall, and every time you got back up." },
  }
  local sw = math.floor((W - 5 * 8) / 6)
  for i, s in ipairs(list) do
    local sx = (i - 1) * (sw + 8)
    U.box(sx, y, sw, 66, C.panel, C.edge)
    U.icon(s[1], sx + math.floor(sw / 2) - 11, y + 7, 22, s[3]:sub(1, 1):upper() .. s[3]:sub(2), s[4])
    U.T(s[2], sx + 4, y + 33, sw - 8, "head", C.gold, "CENTER")
    U.T(s[3], sx + 4, y + 51, sw - 8, "small", C.dim, "CENTER")
  end
  return y + 74
end

-- The road from 1 to 60: one notch per level, coloured by band, a star over your level.
local function road(V, y)
  local U, C, W, lvl = V.U, V.C, V.W, V.lvl
  local roadH = 64
  U.box(0, y, W, roadH, C.panel, C.edge)
  cardTitle(V, "THE ROAD TO 60", 0, y - 2, W,
    lvl >= 60 and "the summit reached" or ("level " .. lvl .. " of 60, " .. (60 - lvl) .. " to go"))
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
  pinArt(U, C, PIN.level, rx + (lvl - 0.5) * notch - 8, ny - 19, 16)
  for l = 10, 60, 10 do U.T(tostring(l), rx + (l - 0.5) * notch - 10, ny + 14, 20, "small", l <= lvl and C.light or C.dim, "CENTER") end
  return y + roadH + 10
end

----------------------------------------------------------------------------
-- Page 1: Overview
----------------------------------------------------------------------------
-- Today's entry: this session in a few sentences, like a diary page.
local function todayCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local D = J.deeds
  if not D then return y end
  local top = y
  local textW = W - 92
  U.icon("INV_Feather_05", 16, y + 14, 34, "Today's entry", "Written from what happened since you logged in.")
  U.T("TODAY'S ENTRY", 64, y + 12, textW, "label", C.inkSoft)
  U.T("day " .. dayOf(j, now()), 64, y + 12, textW, "small", C.inkSoft, "RIGHT")
  local h = U.T(D.today(), 64, y + 28, textW, "body", C.ink)
  y = y + 28 + h + 14
  page(U, C, 0, top, W, y - top)
  return y + 10
end

local function overviewPage(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  y = todayCard(V, y)
  y = seals(V, y)
  y = road(V, y)
  local gap = 10
  local lw = 312
  local rx, rw = lw + gap, W - lw - gap
  local top = y

  -- left: the latest chapter, its newest moments (every kind, whatever the story's filter)
  local ly = y
  local kept = filter
  filter = 1
  local chapters, byLevel = chapterData(j)
  local l = chapters[1]
  if l then
    ly = drawChapter(V, l, byLevel[l], 0, ly, lw, 5, true) or ly
  end
  filter = kept
  if not l then
    page(U, C, 0, ly, lw, 80)
    U.T("The first page is still blank. Your story is written here as you go.", 16, ly + 16, lw - 32, "body", C.ink)
    ly = ly + 80
  end
  ly = ly + 6
  U.btn("Read the story", 0, ly, 150, function() openPage(P_STORY, U) end, false, "Every chapter, level by level.")
  if #chapters > 1 then U.T(plural(#chapters, "chapter") .. " so far", 160, ly + 6, lw - 160, "small", C.dim) end
  ly = ly + 30

  -- right: where you are now, then your companions
  local ry = y
  local maps = mapList(j)
  local curMap = Q.position()
  local show
  for _, m in ipairs(maps) do if m == curMap then show = m end end
  show = show or maps[#maps]
  local cardTop = ry
  ry = cardTitle(V, "WHERE YOU ARE", rx, ry, rw)
  if show then
    U.T(mapLabel(j, show), rx + 14, ry - 4, rw - 28, "body", C.light)
    ry = ry + 18
    local mw = rw - 28
    local mh = math.floor(mw * 668 / 1002)
    drawPlate(V, show, rx + 14, ry, mw, mh, 10)
    ry = ry + mh + 10
    U.btn("Open the map", rx + 14, ry, 130, function() mapPick, highlight = show, nil; openPage(P_MAP, U) end, false,
      "Your whole trail, land by land.")
    U.T(plural(#maps, "land"), rx + 150, ry + 6, rw - 164, "small", C.dim)
    ry = ry + 32
  else
    ry = ry + U.T("Your trail appears here as you travel.", rx + 14, ry, rw - 28, "small", C.dim) + 10
  end
  U.box(rx, cardTop, rw, ry - cardTop, C.panel, C.edge)
  ry = ry + gap

  local pals = palList(j)
  cardTop = ry
  ry = cardTitle(V, "FELLOW ADVENTURERS", rx, ry, rw, #pals > 0 and tostring(#pals) or nil)
  if #pals == 0 then
    ry = ry + U.T("Nobody has shared the road with you yet.", rx + 14, ry, rw - 28, "small", C.dim) + 8
  else
    local most = math.max(60, tonumber(pals[1].rec.seconds) or 60)
    for i = 1, math.min(3, #pals) do ry = ry + palRow(V, pals[i], most, rx + 14, ry, rw - 28, true) end
    if #pals > 3 then
      U.btn("All companions", rx + 14, ry, 130, function() openPage(P_COMPANIONS, U) end, false)
      ry = ry + 30
    end
  end
  ry = ry + 4
  U.box(rx, cardTop, rw, ry - cardTop, C.panel, C.edge)

  return math.max(ly, ry) + 10
end

----------------------------------------------------------------------------
-- Page 2: Map
----------------------------------------------------------------------------
local function mapPage(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local maps = mapList(j)
  local curMap = Q.position()
  if not mapPick then
    for _, m in ipairs(maps) do if m == curMap then mapPick = m end end
    mapPick = mapPick or maps[#maps]
  end
  local idx = 1
  for i, m in ipairs(maps) do if m == mapPick then idx = i end end
  local top = y
  y = cardTitle(V, "THE MAP", 0, y, W)
  if #maps == 0 then
    y = y + U.T("Your trail appears here as you travel: every road you walk, coloured by your level, with stars where you grew stronger and skulls where you fell.",
      14, y, W - 28, "small", C.dim) + 10
  else
    U.btn("<", 14, y, 28, function() mapPick = maps[(idx - 2) % #maps + 1]; highlight = nil; U.refresh() end, false,
      "The previous land on your journey.")
    U.T(mapLabel(j, mapPick), 46, y - 1, W - 92, "head", C.light, "CENTER")
    local zrec = j.zones[mapPick]
    U.T((zrec and zrec.level and ("first reached at level " .. zrec.level .. ", day " .. dayOf(j, zrec.first) .. "  -  ") or "")
      .. "land " .. idx .. " of " .. #maps, 46, y + 21, W - 92, "small", C.dim, "CENTER")
    U.btn(">", W - 42, y, 28, function() mapPick = maps[idx % #maps + 1]; highlight = nil; U.refresh() end, false,
      "The next land on your journey.")
    y = y + 40
    local mw = W - 28
    local mh = math.floor(mw * 668 / 1002)
    drawPlate(V, mapPick, 14, y, mw, mh, 14)
    y = y + mh + 8
    y = y + legend(V, 14, y, W - 28)
  end
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 10

  -- the lands, as a grid of chips: click one to show it
  if #maps > 0 then
    top = y
    y = cardTitle(V, "LANDS EXPLORED", 0, y, W, plural(#maps, "land"))
    local cols, gap = 3, 8
    local cw = math.floor((W - 28 - (cols - 1) * gap) / cols)
    for i, m in ipairs(maps) do
      local cx = 14 + ((i - 1) % cols) * (cw + gap)
      local cy = y + math.floor((i - 1) / cols) * 46
      local lit = m == mapPick
      local zrec = j.zones[m]
      local band = J.bandColor(zrec and zrec.level or 1)
      U.box(cx, cy, cw, 40, lit and C.btnOn or C.btnOff, lit and C.gold or C.edgeSoft)
      U.rect(cx + 1, cy + 1, 3, 38, { band[1], band[2], band[3], 1 }, "border", 3)
      U.T(mapLabel(j, m), cx + 10, cy + 5, cw - 16, "body", lit and C.gold or C.light)
      U.T(zrec and zrec.level and ("level " .. zrec.level .. ", day " .. dayOf(j, zrec.first)) or "passed through",
        cx + 10, cy + 22, cw - 16, "small", C.dim)
      U.hit(cx, cy, cw, 40, mapLabel(j, m), "Show your trail here.", function() mapPick, highlight = m, nil; U.refreshTop() end,
        "Land " .. mapLabel(j, m))
    end
    y = y + math.ceil(#maps / cols) * 46 + 6
    U.box(0, top, W, y - top, C.panel, C.edge)
    y = y + 10
  end

  -- the journal's own switches
  top = y
  y = cardTitle(V, "YOUR JOURNAL", 0, y, W)
  U.check("Show my trail on the world map", 14, y, not ns.db().noJourneyMap, function()
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
  y = y + 30
  local armed = confirmReset and GetTime() - (confirmAt or 0) < 5
  U.btn(armed and "Click again to erase" or "Erase the journal", 14, y, 200, function()
    if confirmReset and GetTime() - (confirmAt or 0) < 5 then
      confirmReset, mapPick, highlight = nil, nil, nil
      J.reset()
      ns.say("journal erased: a fresh page.")
    else
      confirmReset, confirmAt = true, GetTime()
    end
    U.refresh()
  end, armed, "Erases every moment and your whole trail. Click twice to confirm.")
  U.T("Two clicks erase every moment and the whole trail.", 224, y + 6, W - 238, "small", C.dim)
  y = y + 34
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 10
end

----------------------------------------------------------------------------
-- Page 3: Story
----------------------------------------------------------------------------
local function storyPage(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  U.sectionTitle("THE STORY SO FAR", y)
  y = y + 30
  y = y + U.segments(0, y, W, FILTERS, filter, function(i) filter = i; U.refresh() end, FILTER_TIPS) + 8
  local chapters, byLevel = chapterData(j)
  if #chapters == 0 then
    page(U, C, 0, y, W, 60)
    U.T("The first page is still blank. Your story is written here as you go: every level, every land, every quest and every fall.",
      16, y + 14, W - 32, "body", C.ink)
    y = y + 68
  end
  local shown = 0
  for _, l in ipairs(chapters) do
    if shown >= 4 and not showAll then break end
    local ny = drawChapter(V, l, byLevel[l], 0, y, W, showAll and 999 or 8)
    if ny then shown = shown + 1; y = ny + 10 end
  end
  if #chapters > 4 or showAll then
    U.btn(showAll and "Show the last chapters" or "Read the whole story", 0, y, 200, function()
      showAll = not showAll
      U.refresh()
    end, showAll)
    y = y + 32
  end
  return y
end

----------------------------------------------------------------------------
-- Page 4: Companions
----------------------------------------------------------------------------
local function companionsPage(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local pals = palList(j)
  local top = y
  local total = 0
  for _, p in ipairs(pals) do total = total + (tonumber(p.rec.seconds) or 0) end
  y = cardTitle(V, "FELLOW ADVENTURERS", 0, y, W,
    #pals > 0 and (plural(#pals, "companion") .. (total >= 60 and (", " .. duration(total) .. " in good company") or "")) or nil)
  if #pals == 0 then
    y = y + U.T("Nobody has shared the road with you yet. Group up and they are remembered here: who they are, when you met and how long you travelled together.",
      14, y, W - 28, "small", C.dim) + 8
  end
  local most = math.max(60, pals[1] and tonumber(pals[1].rec.seconds) or 60)
  for i, p in ipairs(pals) do
    if i > 40 then break end
    y = y + palRow(V, p, most, 14, y, W - 28)
  end
  y = y + 6
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 10
  if J.tales and J.tales.companions then y = J.tales.companions(V, y) end
  return y
end

----------------------------------------------------------------------------
-- Page 4: Trophies
----------------------------------------------------------------------------

-- Item quality inks that read on parchment (the game's own colours are made for dark tooltips).
local QUALITY_INK = { [0] = { 0.4, 0.4, 0.4 }, [1] = { 0.2, 0.18, 0.15 }, [2] = { 0.08, 0.5, 0.08 },
  [3] = { 0.0, 0.33, 0.75 }, [4] = { 0.5, 0.15, 0.72 }, [5] = { 0.8, 0.4, 0.0 } }
local QUALITY_LIGHT = { [0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 }, [2] = { 0.12, 1, 0 }, [3] = { 0, 0.44, 0.87 },
  [4] = { 0.64, 0.21, 0.93 }, [5] = { 1, 0.5, 0 } }

local function itemIcon(id, fallback)
  if id then
    local tex = select(10, ns.itemInfo(id))
    if tex then return tex end
  end
  return fallback
end

-- A list card at (x, y), w wide: a title, then rows drawn by row(item, y) -> height; returns the y below it.
local function listCard(V, title, right, x, y, w, items, empty, row)
  local U, C = V.U, V.C
  local top = y
  y = cardTitle(V, title, x, y, w, right)
  if #items == 0 then
    y = y + U.T(empty, x + 14, y, w - 28, "small", C.dim) + 10
  else
    for _, it in ipairs(items) do y = y + row(it, y) end
    y = y + 4
  end
  U.box(x, top, w, y - top, C.panel, C.edge)
  return y
end

local function trophiesPage(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local D = J.deeds
  if not D then return y end
  local firsts = type(j.firsts) == "table" and j.firsts or {}

  -- the firsts: four cards in a row
  U.sectionTitle("FIRSTS", y)
  y = y + 30
  local gap = 8
  local cw = math.floor((W - 3 * gap) / 4)
  local ch = 104
  for i, f in ipairs(D.FIRSTS) do
    local cx = (i - 1) * (cw + gap)
    local r = firsts[f.fk]
    local got = r and not r.had
    page(U, C, cx, y, cw, ch)
    local q = r and tonumber(r.iq) or f.q or 1
    local light = QUALITY_LIGHT[q] or QUALITY_LIGHT[1]
    local ink = QUALITY_INK[q] or QUALITY_INK[1]
    U.rect(cx + math.floor(cw / 2) - 20, y + 10, 40, 40, { light[1], light[2], light[3], got and 1 or 0.35 }, "border", 2)
    local ic = U.icon(itemIcon(r and r.i, f.fk == "bag" and "INV_Misc_Bag_08" or ICON.first), cx + math.floor(cw / 2) - 18, y + 12, 36,
      f.label, got and (r.n .. "\nLevel " .. (r.l or "?") .. ", day " .. dayOf(j, r.t)) or (r and r.had and "You had one before the journal began.")
        or "Still out there.")
    if not got then ic.tex:SetDesaturated(true); ic.tex:SetAlpha(0.55) end
    U.T(f.label:upper(), cx + 6, y + 56, cw - 12, "label", C.inkSoft, "CENTER")
    if got then
      U.T(Q.plain(r.n or "?"), cx + 6, y + 70, cw - 12, "small", ink, "CENTER")
      U.T("level " .. (r.l or "?") .. ", day " .. dayOf(j, r.t), cx + 6, y + 86, cw - 12, "small", C.inkSoft, "CENTER")
    else
      U.T(r and r.had and "before the journal" or "still out there", cx + 6, y + 72, cw - 12, "small", C.inkSoft, "CENTER")
    end
  end
  y = y + ch + 14

  -- two columns: nemeses beside close calls, then bosses and rares beside upgrades
  local lw = math.floor((W - 10) / 2)
  local rx, rw = lw + 10, W - lw - 10
  local nem = D.nemeses()
  local shown = {}
  for i = 1, math.min(5, #nem) do shown[i] = nem[i] end
  local most = nem[1] and nem[1].n or 1
  local ly = listCard(V, "NEMESES", #nem > 0 and plural(tonumber(j.deaths) or 0, "fall") or nil, 0, y, lw, shown,
    "Nobody has bested you yet. Long may it last.", function(r, ry)
      U.icon("INV_Misc_Bone_HumanSkull_01", 14, ry, 22, r.name, plural(r.n, "fall") .. ", the last: " .. r.last.s)
      U.T(Q.plain(r.name), 44, ry + 1, lw - 110, "body", C.light)
      U.T(plural(r.n, "fall"), 14, ry + 1, lw - 28, "small", DEATH_INK[1] and { 0.9, 0.35, 0.3 } or C.light, "RIGHT")
      local bw = lw - 58
      U.rect(44, ry + 18, bw, 3, { 0.05, 0.05, 0.08, 0.9 })
      U.rect(44, ry + 18, math.max(2, bw * r.n / most), 3, { 0.75, 0.2, 0.15, 1 })
      return 30
    end)
  local closes = D.moments({ close = true }, 5)
  local ry = listCard(V, "CLOSE CALLS", tonumber(j.closeCalls) and j.closeCalls > 0 and tostring(j.closeCalls) or nil, rx, y, rw,
    closes, "No close shaves yet: every fight ended with health to spare.", function(e, yy)
      U.icon(ICON.close, rx + 14, yy, 22, e.s, e.d)
      local h = U.T(e.s, rx + 44, yy + 1, rw - 58, "small", C.light)
      local pct = tonumber(e.pct)
      if pct then
        U.T(pct .. "% health  -  level " .. (e.l or "?"), rx + 44, yy + h + 3, rw - 58, "small", C.dim)
        h = h + 14
      end
      return math.max(28, h + 8)
    end)
  y = math.max(ly, ry) + 10

  local bosses = D.moments({ boss = true, rare = true }, 6)
  local nb, nr = 0, tonumber(j.rares) or 0
  for _, e in ipairs(j.events) do if e.k == "boss" then nb = nb + 1 end end
  ly = listCard(V, "BOSSES AND RARES", (nb + nr > 0) and (plural(nb, "boss"):gsub("bosss", "bosses") .. ", " .. plural(nr, "rare")) or nil,
    0, y, lw, bosses, "The great foes are still ahead. Dungeon bosses and rares you slay are kept here.", function(e, yy)
      U.icon(ICON[e.k] or ICON.boss, 14, yy, 22, e.s, e.d)
      local h = U.T(e.s, 44, yy + 1, lw - 58, "small", C.light)
      U.T("level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t), 44, yy + h + 3, lw - 58, "small", C.dim)
      return math.max(28, h + 22)
    end)
  local ups = D.moments({ upgrade = true }, 6)
  ry = listCard(V, "GEAR UPGRADES", nil, rx, y, rw, ups, "Pieces you put on and keep wearing for a minute show up here.",
    function(e, yy)
      local q = tonumber(e.iq) or 1
      local light = QUALITY_LIGHT[q] or QUALITY_LIGHT[1]
      U.rect(rx + 13, yy - 1, 24, 24, light, "border", 2)
      U.icon(itemIcon(e.i, ICON.upgrade), rx + 14, yy, 22, e.s, e.d)
      local h = U.T(e.s, rx + 44, yy + 1, rw - 58, "small", C.light)
      if e.d then U.T(e.d .. "  -  level " .. (e.l or "?"), rx + 44, yy + h + 3, rw - 58, "small", C.dim); h = h + 14 end
      return math.max(28, h + 8)
    end)
  y = math.max(ly, ry) + 10

  -- crafts: one chip per tier capped
  local caps = D.moments({ cap = true })
  local top = y
  y = cardTitle(V, "CRAFT MILESTONES", 0, y, W, #caps > 0 and tostring(#caps) or nil)
  if #caps == 0 then
    y = y + U.T("Take a profession to the end of a tier (75, 150, 225 or 300) and it is written here.", 14, y, W - 28, "small", C.dim) + 10
  else
    local cols = 2
    local chw = math.floor((W - 28 - 8) / cols)
    for i, e in ipairs(caps) do
      local cx = 14 + ((i - 1) % cols) * (chw + 8)
      local cy = y + math.floor((i - 1) / cols) * 34
      local key = type(e.n) == "string" and e.n:match("^(%w+):") or nil
      local P = key and ns.P and ns.P[key]
      U.box(cx, cy, chw, 28, C.btnOff, C.edgeSoft)
      U.icon(P and P.icon or ICON.cap, cx + 3, cy + 3, 22, e.d or e.s, e.s)
      U.T(e.d or e.s, cx + 32, cy + 7, chw - 40, "small", C.light)
    end
    y = y + math.ceil(#caps / cols) * 34 + 4
  end
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 10
  if J.tales and J.tales.trophies then y = J.tales.trophies(V, y) end
  return y
end

for _, p in ipairs({ { P_OVERVIEW, overviewPage }, { P_STORY, storyPage }, { P_MAP, mapPage },
  { P_TROPHIES, trophiesPage }, { P_COMPANIONS, companionsPage } }) do
  for _, page in ipairs(PAGES) do if page.name == p[1] then page.draw = p[2] end end
end

local function render()
  local U, C = ns.ui, ns.C
  local st = ns.stats and select(2, ns.stats.data())
  if ns.settingsLost or not st then st = ns.stats and (ns.stats.data()) end
  local _, curName = here()
  local V = { U = U, C = C, W = U.W, j = J.data(), lvl = level(), totals = st and st.totals or {}, curName = curName,
    name = Q.plain(try(UnitName, "player") or "Adventurer"), className = Q.plain((try(UnitClass, "player")) or ""),
    race = Q.plain((try(UnitRace, "player")) or "") }
  local y = header(V)
  local draw = overviewPage
  for _, p in ipairs(PAGES) do if p.name == pageName and p.draw then draw = p.draw end end
  return draw(V, y) + 20
end

-- Drawing helpers for the pages other files add (JourneyQuestLog.lua).
J.draw = { page = page, cardTitle = cardTitle, dayOf = dayOf, plural = plural, duration = duration, roman = roman,
  listCard = listCard, itemIcon = itemIcon, DEATH_INK = DEATH_INK }

ns.addTab("journey", "Journey", render)
