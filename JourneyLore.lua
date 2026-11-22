-- The journal's storybook voice: a line of lore for every land, the prose that opens each chapter,
-- the book's preface, words for your closest companion, and a few moments of their own (your first
-- mount, a new home, an inn's fire, the milestones of the road). Our own wording, ASCII only.
local _, ns = ...
local J = ns.journey
local Q = ns.quests
local function try(...) return Q.try(...) end

local Lr = {}
J.lore = Lr

-- One or two lines per land, as a book would open a chapter set there.
Lr.ZONES = {
  ["Elwynn Forest"] = { "Green hills, quiet farms and a forest that hums with bees. Every hero has to start somewhere.",
    "Under the oaks of Elwynn, the road to everything begins." },
  ["Westfall"] = { "Golden fields gone to seed, scarecrows that walk, and a people asking who will help them now.",
    "Wind over empty farmland, and a red bandana behind every haystack." },
  ["Redridge Mountains"] = { "Red cliffs over a blue lake, a town on the bridge and orcs in the hills." },
  ["Duskwood"] = { "A forest where the sun forgot to rise. Lock the door and keep the lantern lit.",
    "Crows, cobwebs and a graveyard that will not stay quiet." },
  ["Dun Morogh"] = { "Snow to the knees, ale by the fire, and troggs where the mines used to be." },
  ["Loch Modan"] = { "A great dam, a deep loch and the smell of pipe smoke over the water." },
  ["Wetlands"] = { "Rain, rot and raptors. Even the frogs here look tired." },
  ["Teldrassil"] = { "A world tree's crown, wrapped in moonlight and old magic." },
  ["Darkshore"] = { "A long grey coast where old ruins whisper and the sea keeps its secrets." },
  ["Ashenvale"] = { "An ancient forest where every tree is watching, and some of them fight back." },
  ["Stonetalon Mountains"] = { "Stone, smoke and saws: a mountain bleeding where the goblins cut it." },
  ["Durotar"] = { "Red earth, hard sun and harder people. Nothing here is given." },
  ["Mulgore"] = { "Wide grass under wide skies, where the wind carries the drums of the plains." },
  ["Tirisfal Glades"] = { "Grey trees, cold light and the dead who refuse to rest." },
  ["Silverpine Forest"] = { "Pines and fog, and howling under the moon." },
  ["The Barrens"] = { "Dust to the horizon, lions in the grass and a crossroads at the heart of it all.",
    "So much land, so little shade." },
  ["Hillsbrad Foothills"] = { "Orchards and farms caught between two flags." },
  ["Alterac Mountains"] = { "Frozen passes and fallen kings. Ogres hold what men lost." },
  ["Arathi Highlands"] = { "Old stone circles and older grudges on the windswept highlands." },
  ["Thousand Needles"] = { "Pillars of rock like a stone forest, and a long fall below every bridge." },
  ["Desolace"] = { "A land of bones and ash, where centaur tribes wage endless war." },
  ["Stranglethorn Vale"] = { "Jungle heat, pirate ships and tigers in the trees. Watch your back.",
    "Every vine hides a panther, and every panther has friends." },
  ["Dustwallow Marsh"] = { "Mist, mud and the shadow of a black dragon over the swamp." },
  ["Badlands"] = { "Cracked earth and the bones of giants, baking under a merciless sun." },
  ["Swamp of Sorrows"] = { "A drowned land of grief, where the trees weep into black water." },
  ["Feralas"] = { "Giant trees, wild beasts and the broken halls of the highborne." },
  ["The Hinterlands"] = { "Green hills where gryphons nest and trolls guard their temples." },
  ["Tanaris"] = { "Sand, sun and a goblin city that sells everything, including water." },
  ["Searing Gorge"] = { "Ash falls like snow over a pit of fire and chains." },
  ["Blasted Lands"] = { "Red sky, scorched earth and a dark portal humming with old war." },
  ["Un'Goro Crater"] = { "A lost world of steaming jungle, where the ground shakes under every footstep." },
  ["Azshara"] = { "Autumn colours over drowned palaces. Beautiful, and full of ghosts." },
  ["Felwood"] = { "A poisoned forest, glowing sickly green. Breathe lightly." },
  ["Burning Steppes"] = { "Black rock and red fire under the shadow of the mountain." },
  ["Western Plaguelands"] = { "Fields of the dead and farms that remember being alive." },
  ["Eastern Plaguelands"] = { "The heart of the plague. Even the light seems tired here." },
  ["Winterspring"] = { "Snow, silence and the howl of wind over frozen falls." },
  ["Silithus"] = { "A desert buzzing with things that should stay buried." },
  ["Deadwind Pass"] = { "Dead trees, a dead wind and a tower that stares back." },
  ["Moonglade"] = { "A quiet glade where druids gather and the moon is always near." },
  ["Stormwind City"] = { "White stone, blue banners and the busiest bank in the kingdom." },
  ["Ironforge"] = { "A city carved into the mountain, loud with hammers and louder with stories." },
  ["Darnassus"] = { "Moonwells, quiet paths and a temple open to the stars." },
  ["Orgrimmar"] = { "Spikes, smoke and drums. A city built to stand." },
  ["Thunder Bluff"] = { "Tents high on the mesas, where the wind is always singing." },
  ["Undercity"] = { "Below the ruins of a fallen capital, the Forsaken keep their own counsel." },
  ["Zephras Isle"] = { "A sky-touched island, all wind and wings, where the Skyborne first learn to fly." },
}

local function pick(list, seed) return J.pick(list, seed) end
local function fill(text, vars) return J.fill(text, vars) end

-- A line about a land, or nil (the same line every time for the same land).
function Lr.zoneLine(name)
  if type(name) ~= "string" then return nil end
  local lines = Lr.ZONES[name]
  return lines and pick(lines, name) or nil
end

-- Numbers the way a storyteller says them.
local WORDS = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve" }
local function say(n)
  n = tonumber(n) or 0
  if n == 0 then return "no" end
  return WORDS[n] or ns.thousands(n)
end
Lr.say = say
local function count(n, one, many)
  n = tonumber(n) or 0
  return say(n) .. " " .. (n == 1 and one or (many or (one .. "s")))
end
local function capital(s) return (s:gsub("^%l", string.upper)) end
local function joinNames(list)
  if #list == 0 then return nil end
  if #list == 1 then return list[1] end
  return table.concat(list, ", ", 1, #list - 1) .. " and " .. list[#list]
end

-- A few sentences for a chapter, from its moments and Stats' record of the level.
function Lr.chapterProse(l, events, rec, current)
  local n = { quest = 0, death = 0, boss = 0, dungeon = 0, pal = 0, rez = 0, craft = 0, auction = 0, close = 0, flight = 0,
    elite = 0, chain = 0, rare = 0, pvp = 0, camp = 0, wipe = 0 }
  local zones, seen, pals, dungeons = {}, {}, {}, {}
  for _, e in ipairs(events) do
    local k = e.k
    if k == "chain" or k == "elite" then n.quest = n.quest + 1 end
    if n[k] then n[k] = n[k] + 1 end
    if k == "pal" and e.s then pals[#pals + 1] = e.s:match("with (.+)$") or e.s:match("Met (.-) on") end
    if k == "dungeon" and e.s then dungeons[#dungeons + 1] = e.s end
    local zn = e.m and select(2, J.zoneOf(e.m))
    if zn and not seen[zn] then seen[zn] = true; zones[#zones + 1] = zn end
  end
  local quests = rec and tonumber(rec.quests) or n.quest
  local foes = rec and tonumber(rec.kills) or 0
  local deaths = rec and tonumber(rec.deaths) or n.death
  local seed = "chapter" .. l
  local out = {}
  -- where
  if #zones > 2 then
    out[#out + 1] = fill(pick({ "The road ran long this time: %a%, and on to %b%.", "This chapter wandered from %a% to %b%." }, seed),
      { a = zones[1], b = zones[#zones] })
  elseif #zones == 2 then
    out[#out + 1] = fill(pick({ "The story moved between %a% and %b%.", "Half in %a%, half in %b%." }, seed), { a = zones[1], b = zones[2] })
  elseif #zones == 1 then
    out[#out + 1] = fill(pick({ "%a% was home for this chapter.", "All of it happened in %a%.", "%a% kept you busy." }, seed), { a = zones[1] })
  end
  -- the work
  if quests > 0 and foes > 0 then
    out[#out + 1] = fill(pick({ "%q% finished and %f% fallen made it so.", "It took %q% and %f% to earn the next step.",
      "There were %q% to see through and %f% to face." }, seed .. "w"), { q = count(quests, "quest"), f = count(foes, "foe") })
  elseif quests > 0 then
    out[#out + 1] = capital(count(quests, "quest")) .. " finished, " .. (quests == 1 and "one promise kept." or "each one a promise kept.")
  elseif foes > 0 then
    out[#out + 1] = capital(count(foes, "foe")) .. " fell before you."
  end
  -- the deeper roads
  if n.boss > 0 or n.dungeon > 0 then
    out[#out + 1] = n.boss > 0 and ("Below ground, " .. count(n.boss, "great foe") .. " fell" .. (n.wipe > 0 and ", though not at the first try." or "."))
      or "You went down into the dark, and came back out."
  end
  if n.elite > 0 then out[#out + 1] = "You took on " .. (n.elite == 1 and "an elite" or count(n.elite, "elite")) .. " and walked away." end
  if n.rare > 0 then out[#out + 1] = "A rare beast crossed your path, and lost." end
  if n.pvp > 0 then out[#out + 1] = "Steel met steel with the other faction." end
  -- the falls
  if deaths == 0 and (quests + foes) >= 10 then
    out[#out + 1] = pick({ "Not once did you fall.", "You never once saw the spirit healer.", "Nobody laid you low." }, seed .. "d")
  elseif deaths == 1 then
    out[#out + 1] = pick({ "You fell once, and got back up.", "One fall, one long walk back." }, seed .. "d")
  elseif deaths > 1 then
    out[#out + 1] = "You fell " .. say(deaths) .. " times, and each time you got back up."
  end
  if n.close > 0 then out[#out + 1] = "At least once it came down to a sliver of health." end
  -- the company and the rest of life
  local names = joinNames(pals)
  if names then out[#out + 1] = names .. " shared the road." end
  if n.rez > 0 then out[#out + 1] = "Someone raised you when it mattered." end
  if n.craft > 0 then out[#out + 1] = "Between the battles there was work at the bench." end
  if n.auction > 0 then out[#out + 1] = "The auction house saw you more than once." end
  if n.camp > 0 then out[#out + 1] = "There was a fire, and a moment to rest by it." end
  if n.flight > 0 then out[#out + 1] = "New wings carried you further." end
  if current then out[#out + 1] = pick({ "The chapter is still being written.", "The ink here is still wet.", "And the page is not finished yet." }, seed .. "c") end
  -- keep it to a few sentences: the first, then the most telling
  local keep = {}
  for i, s in ipairs(out) do
    if i <= 5 or (current and i == #out) then keep[#keep + 1] = s end
  end
  return table.concat(keep, " ")
end

-- The book's preface on the Story page: the whole journey so far in a paragraph.
function Lr.preface(j, V)
  if type(j) ~= "table" or #j.events == 0 then return nil end
  local first = j.events[1]
  local zone = first and first.m and select(2, J.zoneOf(first.m))
  local lands = #j.order
  local totals = V and V.totals or {}
  local days = math.max(1, math.floor(((J.now() or 0) - (tonumber(j.started) or 0)) / 86400) + 1)
  local parts = {}
  parts[1] = "This is the story of " .. (V and V.name or "a hero") .. (V and V.className ~= "" and (", " .. (V.race ~= "" and (V.race .. " ") or "") .. V.className) or "")
    .. ", begun " .. (zone and ("in " .. zone .. " ") or "") .. (days == 1 and "today." or (say(days) .. " days ago."))
  if lands > 1 then parts[#parts + 1] = "Since then the road has crossed " .. count(lands, "land") .. "." end
  local q, k = tonumber(totals.quests) or 0, tonumber(totals.kills) or 0
  if q + k > 0 then parts[#parts + 1] = "There have been " .. count(q, "quest") .. " and " .. count(k, "foe") .. " along the way." end
  local d = tonumber(j.deaths) or 0
  parts[#parts + 1] = d == 0 and "Not a single fall yet." or ("There have been " .. count(d, "fall") .. ", and every time, you rose.")
  parts[#parts + 1] = "What follows is written as it happened, newest first."
  return table.concat(parts, " ")
end

-- A line about your closest companion.
function Lr.companionLine(name, rec)
  local secs = tonumber(rec and rec.seconds) or 0
  local lines = secs >= 36000 and { "Some friendships are forged in fire. This one was forged in a great many fires.",
      "Where you went, they went. That says everything." }
    or secs >= 7200 and { "A good companion makes a long road short.", "Shoulder to shoulder through more than one hard day." }
    or { "Every friendship starts with a single invite.", "The start of something, perhaps." }
  return pick(lines, name)
end

----------------------------------------------------------------------------
-- First visits to the great cities
----------------------------------------------------------------------------
local CITIES = {
  ["Stormwind City"] = "Walked through the great gates of Stormwind City for the first time",
  ["Ironforge"] = "Stepped into the warm, loud halls of Ironforge for the first time",
  ["Darnassus"] = "Crossed the bridge into Darnassus, quiet beneath the great tree",
  ["Orgrimmar"] = "Passed under the spiked gates of Orgrimmar for the first time",
  ["Thunder Bluff"] = "Rode the lift up to Thunder Bluff and saw the plains from the clouds",
  ["Undercity"] = "Descended into the Undercity beneath the ruins of Lordaeron",
}
function J.firstVisitLine(name)
  return CITIES[name]
end

----------------------------------------------------------------------------
-- Moments of the road: a first mount, a new home, an inn's fire, milestones
----------------------------------------------------------------------------
J.ICON.mount, J.ICON.home, J.ICON.rest, J.ICON.milestone = "Ability_Mount_RidingHorse", "INV_Misc_Rune_01", "Spell_Nature_Sleep",
  "INV_Misc_Ribbon_01"
J.KEEP.mount, J.KEEP.milestone = true, true

local MOUNT = { "Saddled up for the first time and rode out of %zone%: the world just got smaller",
  "Rode out of %zone% on your own mount at last. Walking is for other people now" }
local HOME = { "Made %place% your home: the hearthstone knows the way back now", "Settled on %place% as home, for now",
  "Bound your hearthstone to %place%" }
local REST = { "Warmed your hands by the fire at %place% after a long road", "Rested your feet at %place%",
  "Took a seat by the hearth at %place% and listened to the talk" }
local REST_GAP = 7200 -- seconds between two inn moments

-- Milestones: { key, thresholds, line(n) }
local MARKS = {
  { "quests", { 50, 100, 250, 500, 750, 1000 }, "The %n%th quest of your journey, done" },
  { "kills", { 100, 500, 1000, 2500, 5000, 10000 }, "%n% foes defeated on the road so far" },
  { "miles", { 5, 10, 25, 50, 100 }, "%n% miles walked since the journal began" },
  { "deaths", { 10, 25, 50, 100 }, "Fell for the %n%th time. Still standing, in the end" },
}

local function journal() return J.data() end

local function counts()
  local st = ns.stats and select(2, ns.stats.data())
  if ns.settingsLost or not st then st = ns.stats and (ns.stats.data()) end
  local t = st and st.totals or {}
  local j = journal()
  return { quests = tonumber(t.quests) or 0, kills = tonumber(t.kills) or 0,
    miles = math.floor((tonumber(j.walked) or 0) / 1760), deaths = tonumber(j.deaths) or 0 }
end

-- Each milestone fires once, when a count crosses it; the first reading only seeds.
function Lr.checkMarks()
  local j = journal()
  j.marks = type(j.marks) == "table" and j.marks or {}
  local now = counts()
  for _, m in ipairs(MARKS) do
    local key, value = m[1], now[m[1]]
    local passed = 0
    for _, t in ipairs(m[2]) do if value >= t then passed = t end end
    if j.marks[key] == nil then
      j.marks[key] = passed
    elseif passed > (tonumber(j.marks[key]) or 0) then
      j.marks[key] = passed
      J.add("milestone", fill(m[3], { n = ns.thousands(passed) }), nil, { n = key .. ":" .. passed })
    end
  end
end

-- The first time you sit on your own mount (once per journal).
function Lr.checkMount()
  local j = journal()
  if j.mounted then return end
  local up = try(IsMounted)
  if up == true or up == 1 then
    j.mounted = true
    local zone = J.zoneName()
    J.add("mount", fill(pick(MOUNT, zone), { zone = zone }))
  end
end

local function bindPlace()
  local place = try(GetBindLocation)
  if type(place) == "string" and place ~= "" then return Q.plain(place) end
end

local EVENTS = {
  HEARTHSTONE_BOUND = function()
    local j = journal()
    local place = bindPlace()
    if not place or place == j.home then return end
    j.home = place
    J.add("home", fill(pick(HOME, place), { place = place }))
  end,
  PLAYER_UPDATE_RESTING = function()
    local resting = try(IsResting)
    if not (resting == true or resting == 1) then return end
    local j = journal()
    local t = J.now()
    if t - (tonumber(j.lastRest) or 0) < REST_GAP or (J.inInstance and J.inInstance()) then return end
    local place = try(GetSubZoneText)
    if type(place) ~= "string" or place == "" or place == try(GetZoneText) then return end -- a city's streets, not an inn
    j.lastRest = t
    J.add("rest", fill(pick(REST, place .. t), { place = Q.plain(place) }))
  end,
  PLAYER_MOUNT_DISPLAY_CHANGED = function() Lr.checkMount() end,
}

local frame
function ns.startJourneyLore()
  if frame then return end
  local j = journal()
  if j.home == nil then j.home = bindPlace() or false end -- the bind you log in with is not a new home
  frame = CreateFrame("Frame")
  for event in pairs(EVENTS) do pcall(frame.RegisterEvent, frame, event) end
  frame:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(EVENTS[event], ...)
    if not ok and not Lr.errored then Lr.errored = true; ns.say("journey error: " .. Q.plain(err)) end
  end)
  ns.every(10, function()
    local ok, err = pcall(function() Lr.checkMarks(); Lr.checkMount() end)
    if not ok and not Lr.errored then Lr.errored = true; ns.say("journey error: " .. Q.plain(err)) end
  end)
end

function ns.journeyLoreDebugLines()
  local j = journal()
  local marks = {}
  for k, v in pairs(type(j.marks) == "table" and j.marks or {}) do marks[#marks + 1] = k .. " " .. tostring(v) end
  table.sort(marks)
  return { "journey lore: home " .. tostring(j.home) .. ", mounted " .. tostring(j.mounted == true) .. ", marks "
    .. (#marks > 0 and table.concat(marks, ", ") or "not read yet") }
end
