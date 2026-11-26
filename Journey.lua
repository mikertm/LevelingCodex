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
J.FAST_YDS = 20 -- yards a second no mount reaches (epic: 14): a sample this fast is a flight
J.FLY_STEP_YD = 58 -- the recount's longest step (a mount's 4 s sample is 56 yd, a flight's 2 s 60+)
J.TAXI_GRACE = 6 -- seconds after a flight (or before UnitOnTaxi says so) without trail
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
-- The same moment always reads the same way, but two characters word it differently: the seed
-- carries the character's name (J.salt).
local function pick(list, seed)
  local h = 0
  if not J.salt then
    local ok, who = pcall(UnitName, "player")
    if ok and type(who) == "string" and who ~= "" then J.salt = who end
  end
  seed = (J.salt or "") .. tostring(seed or "")
  for i = 1, #seed do h = (h * 31 + seed:byte(i)) % 2147483647 end
  return list[h % #list + 1]
end

local function fill(text, vars)
  return (text:gsub("%%(%w+)%%", function(k) return vars[k] or "" end))
end
J.pick, J.fill, J.now, J.level = pick, fill, now, level
-- Pick a line like J.pick, but pass over one that opens (its first word) like one of the last six moments of
-- that kind, so a day with five new companions doesn't read "Met X on the road..." five times.
function J.fresh(list, seed, kind, vars)
  if type(list) ~= "table" or #list == 0 then return nil end
  local function opening(t) return (tostring(t or ""):lower():match("^(%S+)") or "") end
  local recent, n = {}, 0
  local events = J.data().events
  for i = #events, 1, -1 do
    local e = events[i]
    if e.k == kind then recent[opening(e.s)] = true; n = n + 1; if n >= 6 then break end end
  end
  local start = 1
  for i, l in ipairs(list) do if l == pick(list, seed) then start = i; break end end
  local first
  for k = 0, #list - 1 do
    local text = fill(list[(start - 1 + k) % #list + 1], vars or {})
    first = first or text
    if not recent[opening(text)] then return text end
  end
  return first
end

-- Zone maps: up through parents while the map is smaller than a zone.
local zoneCache = {}
local function zoneOf(map)
  if type(map) ~= "number" then return end
  local hit = zoneCache[map]
  if hit then return hit[1], hit[2], hit[3] end
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
  -- a continent or the world map (a position read while zoomed out) is no land of its own
  local broad = type(info) == "table" and tonumber(info.mapType) ~= nil and info.mapType <= 2 or nil
  zoneCache[map] = { id, name, broad }
  return id, name, broad
end
J.zoneOf = zoneOf
-- The land a map belongs to, by name; nil for a continent or the world.
function J.landOf(map)
  local _, name, broad = zoneOf(map)
  if not broad then return name end
end

local function inInstance()
  local _, kind = try(GetInstanceInfo)
  return kind == "party" or kind == "raid"
end

local function here()
  local map, x, y = Q.position()
  local zone, name, broad = zoneOf(map)
  if broad then return nil, nil, map, x, y end
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
J.FOES = FOES
local KILL = { "Answered %giver%'s call to arms against the %foe%s of %zone%", "Made %zone% a little safer from %foe%s",
  "Hunted %foe%s across %zone%", "Cleared the %foe%s out of %zone%", "Took the fight to the %foe%s of %zone% so %giver% could sleep at night",
  "Went looking for %foe%s in %zone%, and found plenty", "Thinned the %foe% numbers in %zone% at %giver%'s asking",
  "Spent a bloody afternoon among the %foe%s of %zone%", "Sent the %foe%s of %zone% running, the ones still able to run",
  "Did the grim work %giver% asked: %foe%s, and plenty of them, in %zone%", "Came back from %zone% with a tally of %foe%s and a few new scars" }
local GATHER = { "Gathered %item% across %zone% for %giver%", "Rummaged through %zone% for %item%",
  "Brought back the %item% %giver% needed", "Searched every corner of %zone% for %item%", "Came back to %giver% with arms full of %item%",
  "Turned %zone% upside down looking for %item%", "Filled your bags with %item% from %zone% and hauled them to %giver%",
  "Found every last %item% %giver% asked for, in the far corners of %zone%", "Picked %zone% clean of %item%, as promised" }
local COOK = { "Gathered %item% in %zone% so %giver% could get cooking", "Kept the kitchens of %zone% stocked with %item%",
  "Brought %giver% the %item% for supper, and maybe got a taste", "Fetched %item% from %zone%: somebody's stew depends on it" }
local ERRAND = { "Ran an errand for %giver% in %zone%", "Carried word across %zone% for %giver%", "Did a good turn for %giver% in %zone%",
  "Kept a promise to %giver% in %zone%", "Answered %giver%'s plea for help in %zone%", "Carried a message across %zone% for %giver%",
  "Walked the long way round %zone% on %giver%'s business", "Did what %giver% couldn't, in %zone%",
  "Played messenger for %giver%: %zone% is smaller now", "Made %giver%'s problem your problem, and then made it go away" }
local NO_GIVER = { "Lent a helping hand in %zone%", "Answered a call for help in %zone%", "Did a stranger a good turn in %zone%",
  "Set something right in %zone%" }

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
local BOSS = { "Defeated %boss% in %dungeon%", "Brought down %boss% deep in %dungeon%", "Bested %boss% in %dungeon%",
  "Stood over the fallen %boss% in the heart of %dungeon%", "%boss% fell in %dungeon%, and the party breathed again",
  "Ended %boss%'s reign in %dungeon%", "Fought %boss% to the last in %dungeon%, and won", "Left %boss% where they fell, deep in %dungeon%" }
for _, s in ipairs({ "Left %dungeon% with %boss% finally beaten",
  "%boss% made a last stand in %dungeon%, and lost",
  "Put an end to %boss% in %dungeon%" }) do BOSS[#BOSS + 1] = s end
local DUNGEON = { "Ventured into %dungeon%", "Gathered your courage and stepped into %dungeon%", "Delved into %dungeon%",
  "Lit a torch and went down into %dungeon%", "Took a deep breath at the door of %dungeon% and walked in",
  "Followed the party down into %dungeon%", "Stepped into the dark of %dungeon%, weapons ready" }
for _, s in ipairs({ "Pushed open the doors of %dungeon%",
  "Went down into %dungeon% with torches and good intentions",
  "Checked the bandages one last time and entered %dungeon%" }) do DUNGEON[#DUNGEON + 1] = s end
local ZONE = { "Set foot in %zone% for the first time", "The road led on to %zone%", "Arrived in %zone%, a new land to explore",
  "First steps into %zone%", "Crossed into %zone%, map in hand", "Left the familiar behind and walked into %zone%",
  "Came over the rise and saw %zone% for the first time", "%zone%: new ground, new faces, new trouble", "Wandered into %zone% and stayed a while",
  "Followed the road until it became %zone%" }
local DEATH = { "Fell to %killer% in %zone%, then got back up", "Was bested by %killer% in %zone%: a lesson learned",
  "%killer% got the better of you in %zone%. The spirit healer sends regards", "Lost a fight to %killer% in %zone%. Pride hurts most",
  "Went down to %killer% in %zone%. Back on your feet, eventually", "%killer% won the day in %zone%. Not the war, though",
  "Underestimated %killer% in %zone%, and paid for it" }
for _, s in ipairs({ "%killer% had the last word in %zone%, for now",
  "Fell to %killer% in %zone% and saw the grey sky again",
  "%killer% ended a good day early in %zone%",
  "Lost the fight with %killer% in %zone%. The graveyard knows you well",
  "Was laid low by %killer% in %zone%. Pride bruised, gear battered" }) do DEATH[#DEATH + 1] = s end
local PVP_DEATH = { "Ambushed by %killer% in %zone%. Not every enemy in Azeroth is a monster",
  "Cut down by %killer% in %zone%: the war is real", "Fell to %killer% in %zone%, and swore to remember the name" }
for _, s in ipairs({ "%killer% caught you off guard in %zone%. The war has long arms",
  "Slain by %killer% in %zone%. They'll be on your list now" }) do PVP_DEATH[#PVP_DEATH + 1] = s end
local DEATH_PLAIN = { "Met an untimely end in %zone%, but the story goes on", "Took a spill in %zone% and walked back from the graveyard",
  "Died in %zone%. It happens to the best of us", "The world went grey in %zone%, for a while" }
for _, s in ipairs({ "Something got you in %zone%. The ghost walk was long",
  "Fell in %zone%, and the world turned to mist",
  "Died in %zone%, and nobody saw it coming, least of all you" }) do DEATH_PLAIN[#DEATH_PLAIN + 1] = s end
local FLIGHT = { "Made friends with the flight master at %place%", "Found a new flight path at %place%",
  "Learned the skies over %place%", "Shook the flight master's hand at %place%: one more road through the air",
  "Added %place% to the map of the skies", "Met the gryphons of %place%, or whatever flies there" }
for _, s in ipairs({ "Learned the way through the air from %place%",
  "Paid the flight master at %place% a visit: one more path",
  "Marked %place% on the map of the skies",
  "Gave the gryphons at %place% a scratch and learned their road" }) do FLIGHT[#FLIGHT + 1] = s end
local PAL = { "Joined forces with %name%", "Met %name% on the road and travelled together", "Shared a road and a few fights with %name%",
  "Fell in with %name% for a stretch of the road", "Found a friend in %name%, or at least a second sword", "Teamed up with %name%; the road felt shorter" }
for _, s in ipairs({ "Grouped up with %name% and the work went faster",
  "Fought side by side with %name%",
  "Made a new friend on the road: %name%",
  "Found %name% heading the same way, and went together",
  "Shared a campfire and a quest log with %name% in %zone%",
  "%name% asked if you wanted to group. You did",
  "Two blades are better than one: met %name% in %zone%",
  "Ran into %name% at the same quest giver, and stuck together",
  "Fell into step with %name% somewhere in %zone%",
  "Watched %name%'s back in %zone%, and they watched yours",
  "Picked up a travelling companion in %zone%: %name%",
  "Joined %name% against whatever %zone% had to offer",
  "Said hello to %name%. Several hours later, still grouped",
  "Met %name% over the same quest mob, and decided to share",
  "%name% came along for the ride through %zone%",
  "A stranger in %zone% became a companion: %name%",
  "Trusted %name% with your back, and they earned it" }) do PAL[#PAL + 1] = s end

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
  local special = {
    [10] = "Reached level 10 in " .. zone .. ": your first talent point awaits",
    [20] = "Reached level 20 in " .. zone .. ": no longer a beginner, not yet a veteran",
    [30] = "Reached level 30 in " .. zone .. ": halfway up the mountain",
    [40] = "Reached level 40 in " .. zone .. ": old enough to ride, if the purse allows",
    [50] = "Reached level 50 in " .. zone .. ": the summit is in sight",
    [5] = "Reached level 5 in " .. zone .. ": the first steps are behind you",
    [15] = "Reached level 15 in " .. zone .. ": the world is getting bigger",
    [25] = "Reached level 25 in " .. zone .. ": a name people are starting to know",
    [35] = "Reached level 35 in " .. zone .. ": the hard lands are calling",
    [45] = "Reached level 45 in " .. zone .. ": old dangers look smaller now",
    [55] = "Reached level 55 in " .. zone .. ": the last stretch of the climb",
    [59] = "Reached level 59 in " .. zone .. ": one more step to the top",
  }
  if special[lvl] then return special[lvl] end
  local list = { "Grew stronger: level %n% in %zone%", "Reached level %n% in %zone%",
    "Level %n%, earned the hard way in %zone%", "Level %n% in %zone%: a little taller, a little tougher",
    "Felt the light of level %n% in %zone%", "Level %n% came in %zone%, with a rush of new strength",
    "Level %n%: the trainers in town will want a word", "Climbed to level %n% somewhere in %zone%",
    "Level %n%. %zone% will remember this one", "Level %n% found you in %zone%, a little out of breath",
    "Turned the page to level %n% in %zone%", "In %zone%, level %n%: one more rung on the ladder",
    "Level %n% in %zone%, and the road ahead looked shorter", "New strength, same old boots: level %n% in %zone%",
    "%zone% saw you reach level %n%", "Level %n% in %zone%, and not a moment too soon",
    "Stood a little straighter in %zone%: level %n%", "Level %n%, won in %zone% one fight at a time",
    "The golden light of level %n% fell on %zone%", "Level %n% in %zone%. Somewhere, a trainer smiled",
    "Level %n% arrived in %zone% like an old friend", "Another notch on the belt: level %n%, in %zone%",
    "Level %n% in %zone%: the new spells won't learn themselves", "Pushed through to level %n% in %zone%",
    "Level %n%. %zone% looked a little less dangerous after that", "The ladder grew a rung: level %n% in %zone%",
    "Level %n% in %zone%, and a quick look at the talent tree", "A flash of light in %zone%: level %n%",
    "Level %n%: the road to sixty got one step shorter", "Earned level %n% the long way round, in %zone%",
    "Level %n% caught up with you in %zone%", "Level %n% in %zone%, won with sweat and stubbornness" }
  return fill(J.rotate and J.rotate(list, "level", lvl) or pick(list, lvl), { n = tostring(lvl), zone = zone })
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
  if J.retell then
    local ok, told = pcall(J.retell, kind, text, extra)
    if ok and type(told) == "string" then text = told end
  end
  local e = { t = now(), k = kind, l = level(), s = Q.plain(text or ""), d = detail and Q.plain(detail) or nil }
  if extra and extra.at then map, x, y = extra.at[1], extra.at[2], extra.at[3] end
  if extra and extra.q then e.q = extra.q end
  if extra and extra.l then e.l = extra.l end
  for _, f in ipairs({ "who", "i", "iq", "fk", "pct", "n", "pvp", "c", "told" }) do
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

local last -- the last trail sample: { map, x, y, level, run, t }
local air -- the last sample in flight: { map, x, y }
-- Flown yards: the flight path's samples, apart from the walk.
local function flownSample()
  last = nil
  J.taxiAt = GetTime()
  local map, x, y = Q.position()
  if not (map and x and y) then air = nil; return end
  if air and air.map == map then
    local yd = J.yards(ns.questWorld and ns.questWorld[map], x - air.x, y - air.y)
    if yd and yd < 2000 then local j = J.data(); j.flown = (tonumber(j.flown) or 0) + yd end
  end
  air = { map = map, x = x, y = y }
end
local function sample()
  if Q.inFlight() then flownSample(); return end
  air = nil
  -- just landed: no trail for a moment (the speed check below catches a flight UnitOnTaxi missed)
  if J.taxiAt and GetTime() - J.taxiAt < J.TAXI_GRACE then last = nil; return end
  local dead = try(UnitIsDeadOrGhost, "player")
  if dead == true or dead == 1 or inInstance() then last = nil; return end
  local map, x, y = Q.position()
  if not (map and x and y) then return end
  local j = J.data()
  local lvl = level()
  local world = ns.questWorld and ns.questWorld[map]
  local function yards(dx, dy) return J.yards(world, dx, dy) end
  if last and last.map == map and last.level == lvl then
    local dx, dy = x - last.x, y - last.y
    local pct = math.sqrt(dx * dx + dy * dy)
    if pct < JUMP_PCT then
      local yd = yards(dx, dy)
      if (yd and yd < STEP_YD) or (not yd and pct < STEP_PCT) then return end
      local dt = GetTime() - (last.t or 0)
      if yd and dt > 0 and yd / dt > J.FAST_YDS then
        -- faster than any mount: a flight, boat or zeppelin the client didn't call a taxi
        last = nil
        return sample()
      end
      last.t = GetTime()
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
  last = { map = map, x = x, y = y, level = lvl, run = run, t = GetTime() }
  if j.points > J.MAX_POINTS then thin(j) end
  J.trailVersion = (J.trailVersion or 0) + 1
end

-- Yards for a step of (dx, dy) map percent on a map of ns.questWorld (positional rows:
-- continent, north, west, height, width; named fields too). nil without the map's size.
-- (Until v0.33 this read only the named fields, so the journal's miles stayed at 0.)
function J.yards(world, dx, dy)
  if type(world) ~= "table" then return end
  local h, w = tonumber(world.height or world[4]), tonumber(world.width or world[5])
  if not (h and w) then return end
  local ax, ay = dx / 100 * w, dy / 100 * h
  return math.sqrt(ax * ax + ay * ay)
end

-- The yards along every trail run (no jump counted, and no step longer than J.FLY_STEP_YD: a
-- flight's 2 s samples, which journals before v0.33.1 could keep), for a journal written before the fix.
function J.recountWalked(j)
  local total = 0
  for map, runs in pairs(j.trail or {}) do
    local world = ns.questWorld and ns.questWorld[map]
    for _, r in ipairs(type(runs) == "table" and runs or {}) do
      local pts = J.unpack(r.p or "")
      for i = 2, #pts do
        local dx, dy = pts[i][1] - pts[i - 1][1], pts[i][2] - pts[i - 1][2]
        if math.sqrt(dx * dx + dy * dy) < JUMP_PCT then
          local yd = J.yards(world, dx, dy) or 0
          if yd <= J.FLY_STEP_YD then total = total + yd end
        end
      end
    end
  end
  return total
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
    J.add("zone", J.firstVisitLine and J.firstVisitLine(name) or fill(pick(ZONE, name), { zone = name }), nil, { at = x and { map, x, y } })
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
  J.add("dungeon", party and (text .. " with " .. party) or text, nil, { who = Q.plain(name) })
end

local function bossDown(name)
  if type(name) ~= "string" or name == "" then return end
  bossSeen = bossSeen or {}
  if bossSeen[name] then return end
  bossSeen[name] = true
  local wipes = J.wipesOn and J.wipesOn(name) or 0
  local detail = dungeonHere and Q.plain(dungeonHere)
  if wipes > 0 then detail = (detail and (detail .. ", ") or "") .. "after " .. wipes .. (wipes == 1 and " wipe" or " wipes") end
  J.add("boss", J.bossLine(name, dungeonHere), detail, { who = name })
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
    J.add(kind, text, title and ("Quest: " .. Q.plain(title)) or nil, { q = id, who = kind == "elite" and Q.eliteName(id) or nil })
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
    if J.isForgotten and J.isForgotten(p.name) then rec = false
    elseif type(rec) ~= "table" then
      rec = { seconds = 0, first = now(), level = level() }
      j.pals[p.name] = rec
      J.add("pal", J.fresh(PAL, p.name, "pal", { name = Q.plain(p.name), zone = zoneName() }), nil, { who = p.name })
    end
    if rec then
      rec.class = p.class or rec.class
      rec.seconds = (tonumber(rec.seconds) or 0) + PAL_TICK
    end
  end
end

-- Forget the last trail sample (the next one starts a new run).
function J.resetSample() last = nil end

local events
function ns.startJourney()
  if events then return end
  local j = J.data()
  -- an older journal may list a continent among its lands: take it out (its moments stay)
  pcall(function()
    for i = #j.order, 1, -1 do
      local _, _, broad = zoneOf(j.order[i])
      if broad then j.zones[j.order[i]] = nil; table.remove(j.order, i) end
    end
  end)
  if (tonumber(j.walkFix) or 0) < 2 then
    -- v0.33.0 rebuilt the miles from the trail, flights included: count again without them (a
    -- thinned trail (over 12000 points) has longer steps, so it keeps the lower of the two)
    local ok, yd = pcall(J.recountWalked, j)
    if ok and yd then
      local was = tonumber(j.walked) or 0
      if j.walkFix ~= 1 and yd > was then j.walked = yd
      elseif (tonumber(j.points) or 0) < 12000 and yd < was then j.walked = yd end
    end
    j.walkFix = 2
  end
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
  for _, l in ipairs(wtrail.lines or {}) do l:Hide() end
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
  local runs, total = J.runs(map, WORLD_DOTS * 2)
  -- a line where the client draws them (dots ran into blobs where you walked a lot): points 5 px
  -- apart at least, no line across a jump, each stroke on a dark under-stroke
  local lines = type(wtrail.CreateLine) == "function" and 0 or nil
  if lines then
    wtrail.lines = wtrail.lines or {}
    local function stroke(x1, y1, x2, y2, c, a, thick, sub)
      lines = lines + 1
      local l = wtrail.lines[lines]
      if not l then l = wtrail:CreateLine(nil, "ARTWORK"); wtrail.lines[lines] = l end
      l:SetDrawLayer("ARTWORK", sub)
      l:SetStartPoint("TOPLEFT", wtrail, x1, y1)
      l:SetEndPoint("TOPLEFT", wtrail, x2, y2)
      l:SetThickness(thick)
      l:SetColorTexture(c[1], c[2], c[3], a)
      l:Show()
    end
    local dark = { 0.1, 0.06, 0.02 }
    for _, r in ipairs(runs) do
      local c = J.bandColor(r.level)
      local px, py
      for _, pt in ipairs(r.pts) do
        if lines >= WORLD_DOTS * 2 then break end
        local x, y = pt[1] / 100 * w * z, -pt[2] / 100 * h * z
        if not px then px, py = x, y
        else
          local d2 = (x - px) ^ 2 + (y - py) ^ 2
          if d2 > (w * z * 0.12) ^ 2 then px, py = x, y
          elseif d2 >= 25 then
            stroke(px, py, x, y, dark, 0.5, 5, 1)
            stroke(px, py, x, y, c, 0.95, 3, 2)
            used = used + 1
            px, py = x, y
          end
        end
      end
    end
    runs = {}
  end
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
  J.worldLine = used .. (lines and " strokes" or " dots") .. " of " .. total .. " points and " .. pins .. " pins on map " .. map
end
