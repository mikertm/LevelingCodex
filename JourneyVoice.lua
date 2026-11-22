-- JourneyVoice.lua: who the book is about and how it is told.
--   Names: WoW Forever characters carry a first and a last name. J.voice.names() reads both from the
--     client (a surname separator in the name, C_NameUtil, or the full name the client gives), and a
--     last name set in the book (the Contents page) wins; C_PlayerInfo.ShouldDisplaySurname() false
--     hides an automatic one.
--   The narrator: Chronicler (a formal history, by name), Fireside (told to you across a fire) or
--     Bard (a song in prose). Each character gets one by a hash of who they are; the Contents page
--     changes it (journey.voice).
--   Traits: what the journal says about you (a wanderer, a gatherer, unbroken, reckless, a friend of
--     many...), from the journal's counts. The strongest gives your epithet ("the Wanderer") and
--     colours the chapters.
--   Chapter prose: J.lore.chapterProse, rewritten here to build on what came before: lands you return
--     to, the hardest or quickest chapter yet, a clean page after a bad one, gathering and fishing,
--     the people who shared the road, in the narrator's own voice.
-- ASCII and our own wording only.
local _, ns = ...
local J = ns.journey
local Q = ns.quests
local function try(...) return Q.try(...) end

local Vo = {}
J.voice = Vo

local function pick(list, seed) return J.pick(list, seed) end
local function fill(text, vars) return J.fill(text, vars) end
local function say(n) return J.lore.say(n) end
local function count(n, one, many)
  n = tonumber(n) or 0
  return say(n) .. " " .. (n == 1 and one or (many or (one .. "s")))
end
local function capital(s) return (tostring(s or ""):gsub("^%l", string.upper)) end
local function plain(s) return Q.plain(tostring(s or "")) end

----------------------------------------------------------------------------
-- Names
----------------------------------------------------------------------------

-- The two halves of a name joined by a separator (a space, a dot, a dash, anything not a letter).
local function split(s)
  if type(s) ~= "string" or s == "" then return nil end
  -- the client knows its own separator: where its link form differs is where the names meet
  local f = C_NameUtil and C_NameUtil.ReplaceSurnameSeparatorWithLinkSeparator
  if type(f) == "function" then
    local ok, r = pcall(f, s)
    if ok and type(r) == "string" and r ~= s then
      local a = 0
      while a < #s and a < #r and s:byte(a + 1) == r:byte(a + 1) do a = a + 1 end
      local b = 0
      while b < #s - a and b < #r - a and s:byte(#s - b) == r:byte(#r - b) do b = b + 1 end
      local first, last = s:sub(1, a), s:sub(#s - b + 1)
      if first ~= "" and last ~= "" then return first, last end
    end
  end
  local first, last = s:match("^([^%s%.%-_|,]+)[%s%.%-_|,]+([^%s%.%-_|,]+)$")
  if first then return first, last end
  return s
end

-- The word that follows your first name in a longer string (a title before it is left out).
local function after(s, first)
  if type(s) ~= "string" or type(first) ~= "string" or first == "" then return nil end
  local at = s:find(first, 1, true)
  if not at then return nil end
  local rest = s:sub(at + #first)
  return rest:match("^[%s%.%-_|]+([^%s%.%-_|,]+)")
end

function Vo.names()
  local raw = try(UnitName, "player")
  local first, last = split(type(raw) == "string" and raw or nil)
  first = first or "Adventurer"
  if not last then
    for _, src in ipairs({ { UnitNameUnmodified, "player" }, { UnitPVPName, "player" }, { GetUnitName, "player", false } }) do
      if type(src[1]) == "function" then
        local ok, s = pcall(src[1], src[2], src[3])
        last = ok and after(s, first) or nil
        if last then break end
      end
    end
    if last then
      local show = C_PlayerInfo and C_PlayerInfo.ShouldDisplaySurname
      if type(show) == "function" then
        local ok, on = pcall(show)
        if ok and on == false then last = nil end
      end
    end
  end
  local j = J.data()
  if type(j.surname) == "string" and j.surname ~= "" then last = j.surname elseif j.surname == false then last = nil end
  first = plain(first)
  last = last and plain(last) or nil
  if last == "" then last = nil end
  return first, last
end

function Vo.fullName()
  local first, last = Vo.names()
  return last and (first .. " " .. last) or first
end

-- Set the last name by hand ("" or nil clears it back to what the client says; "-" means none).
function Vo.setSurname(text)
  local j = J.data()
  text = plain(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then j.surname = nil; return true end
  if text == "-" then j.surname = false; return true end
  if #text > 24 or text:find("[^%a%s'%-]") then return false, "Letters only, up to 24." end
  j.surname = text
  return true
end

----------------------------------------------------------------------------
-- The narrator
----------------------------------------------------------------------------
Vo.STYLES = { "chronicle", "fireside", "bard" }
Vo.STYLE_LABELS = { "Chronicler", "Fireside", "Bard" }
Vo.STYLE_TIPS = { "A history in the formal style: your deeds set down by name, for those who come after.",
  "Told to you across a campfire by someone who was nearly there.",
  "A song in prose: the road, the light and the weather, sung a little larger than life." }

function Vo.style()
  local j = J.data()
  for _, s in ipairs(Vo.STYLES) do if j.voice == s then return s end end
  local _, class = try(UnitClass, "player")
  return pick(Vo.STYLES, "narrator" .. tostring(class))
end
function Vo.setStyle(s) J.data().voice = s end

-- A line in the narrator's voice: lines[style] is a list, %name% is your name.
local function voiced(lines, seed, vars)
  local style = Vo.style()
  local list = lines[style] or lines.fireside
  vars = vars or {}
  vars.name = vars.name or (Vo.names())
  return fill(pick(list, seed), vars)
end
Vo.voiced = voiced

----------------------------------------------------------------------------
-- Traits: what the journal says about you
----------------------------------------------------------------------------
local function tally(j, key) return type(j.tally) == "table" and tonumber(j.tally[key]) or 0 end
local function wild(j, key) return type(j.wilds) == "table" and type(j.wilds[key]) == "table" and tonumber(j.wilds[key].n) or 0 end

Vo.TRAITS = {
  wanderer = { epithets = { "the Wanderer", "Far-Walker", "the Long Road" },
    aside = { "As ever, the horizon was the only real destination.", "Your boots had opinions about all this walking, and were ignored." } },
  unbroken = { epithets = { "the Unbroken", "the Untouched", "Deathless" },
    aside = { "The spirit healers still don't know your face.", "Luck, skill or stubbornness: the record stayed clean." } },
  undaunted = { epithets = { "the Undaunted", "Twice-Risen", "the Stubborn" },
    aside = { "Falling had long since stopped being a reason to stop.", "The graveyard paths were getting familiar." } },
  friend = { epithets = { "Friend of Many", "the Good Company", "Shield-Friend" },
    aside = { "As usual, the road was better shared.", "There is always room for one more in your party." } },
  lone = { epithets = { "the Lone", "Walks-Alone", "the Solitary" },
    aside = { "Alone again, and that suited you fine.", "No party, no waiting, no one to split the loot with." } },
  gatherer = { epithets = { "the Gatherer", "Stone-Picker", "Root-and-Vein" },
    aside = { "As ever, your pack came home heavier than it left.", "Not a vein or a flower went past unnoticed." } },
  angler = { epithets = { "the Angler", "Patient-Line", "Friend of the Fish" },
    aside = { "Somewhere along the way there was water, and so there was a line in it.", "The fish of Azeroth have learned your name." } },
  artisan = { epithets = { "the Artisan", "Steady-Hand", "the Maker" },
    aside = { "The work at the bench never really stopped.", "Every hour on the road fed something at the workbench." } },
  merchant = { epithets = { "the Merchant", "Coin-Counter", "the Shrewd" },
    aside = { "The auction house kept a seat warm for you.", "Gold moved, as gold does around you." } },
  delver = { epithets = { "the Delver", "Deep-Goer", "Dungeon-Born" },
    aside = { "The dark places kept calling, and you kept answering.", "Another door into the deep, another way out." } },
  warbound = { epithets = { "the Warbound", "Banner-Bearer", "the Bloodied" },
    aside = { "The other faction remembers you, and not fondly.", "There is always a war somewhere, and you always find it." } },
  dutiful = { epithets = { "the Dutiful", "Word-Keeper", "the Reliable" },
    aside = { "Every notice board knew you'd come.", "A promise made was a promise kept, as always." } },
  restless = { epithets = { "the Restless", "Half-Finished", "the Fickle" },
    aside = { "Some quests were left by the roadside, as usual.", "Not every errand earns your patience." } },
  newcomer = { epithets = { "the Newcomer", "the Untested", "Fresh-Boots" }, aside = {} },
}

-- Your traits, strongest first: { { key, score }, ... }.
function Vo.traits(j)
  j = j or J.data()
  local lvl = math.max(1, tonumber(J.level()) or 1)
  local deaths = tonumber(j.deaths) or 0
  local lands = type(j.order) == "table" and #j.order or 0
  local palTime = 0
  for _, p in pairs(type(j.pals) == "table" and j.pals or {}) do
    if type(p) == "table" then palTime = palTime + (tonumber(p.seconds) or 0) end
  end
  local st = ns.stats and select(2, ns.stats.data())
  if ns.settingsLost or not st then st = ns.stats and (ns.stats.data()) end
  local quests = st and st.totals and tonumber(st.totals.quests) or 0
  local out = {}
  local function add(key, score) if score > 0 then out[#out + 1] = { key, score } end end
  add("wanderer", (lands >= 4 and lands / lvl >= 0.35) and (lands / lvl) * 3 or 0)
  add("unbroken", (deaths == 0 and lvl >= 6) and (1 + lvl / 10) or 0)
  add("undaunted", deaths >= 5 and deaths / lvl >= 0.6 and deaths / lvl * 2 or 0)
  add("friend", palTime >= 3600 and palTime / 3600 or 0)
  add("lone", (palTime < 300 and lvl >= 12) and 1.5 or 0)
  local gathered = wild(j, "mining") + wild(j, "herbalism") + wild(j, "skinning")
  add("gatherer", gathered >= 30 and gathered / 30 or 0)
  add("angler", wild(j, "fishing") >= 20 and wild(j, "fishing") / 20 or 0)
  add("artisan", tally(j, "crafted") >= 30 and tally(j, "crafted") / 30 or 0)
  add("merchant", (tally(j, "posted") + tally(j, "sold")) >= 10 and (tally(j, "posted") + tally(j, "sold")) / 10 or 0)
  add("delver", tally(j, "runs") >= 3 and tally(j, "runs") / 2 or 0)
  add("warbound", (tally(j, "honor") >= 10 or tally(j, "bgWon") + tally(j, "bgLost") >= 2)
    and (tally(j, "honor") / 10 + tally(j, "bgWon") + tally(j, "bgLost")) or 0)
  add("dutiful", (quests >= 40 and tally(j, "abandoned") <= 2) and quests / 60 or 0)
  add("restless", tally(j, "abandoned") >= 5 and tally(j, "abandoned") / 4 or 0)
  table.sort(out, function(a, b) return a[2] > b[2] end)
  if #out == 0 and lvl < 10 then out[1] = { "newcomer", 0.1 } end
  return out
end

-- "the Wanderer", or nil while the journal says too little.
function Vo.epithet(j)
  local top = Vo.traits(j)[1]
  if not top then return nil end
  return pick(Vo.TRAITS[top[1]].epithets, "epithet" .. top[1])
end

----------------------------------------------------------------------------
-- Chapter prose that builds on the chapters before it
----------------------------------------------------------------------------
local L = {
  newLand = {
    chronicle = { "In this chapter %name% first came to %a%.", "The record shows %name% arriving in %a% for the first time.",
      "%a% enters the history here, with %name% walking into it." },
    fireside = { "Then came %a%, and you'd never set foot there before.", "First time in %a%. Remember the smell of it?",
      "You wandered into %a% with no idea what was waiting." },
    bard = { "New ground under new skies: %a% opened its gates.", "%a% rose before you, strange and wide and waiting.",
      "And the road unrolled into %a%, a land not yet sung." } },
  backLand = {
    chronicle = { "%name% returned to %a%, last seen in chapter %r%.", "Once more the record finds %name% in %a%, as in chapter %r%." },
    fireside = { "Back to %a% again; you'd been there in chapter %r%.", "%a% one more time. Some places just keep pulling you back." },
    bard = { "The road curled home to %a%, remembered from chapter %r%.", "%a% again, its old paths waiting where you left them." } },
  oneLand = {
    chronicle = { "The whole of this chapter took place in %a%.", "%name% did not leave %a% in this chapter." },
    fireside = { "All of it happened in %a%.", "%a% kept you busy the whole time.", "You never left %a% this time round." },
    bard = { "%a% held you, every hour of it.", "One land, one long song: %a%." } },
  manyLands = {
    chronicle = { "From %a% the road led on through %n% lands, as far as %b%.", "The chapter crosses %n% lands, %a% to %b%." },
    fireside = { "The road ran long this time: %a%, and on all the way to %b%.", "You covered ground: %n% lands, %a% to %b%." },
    bard = { "Over %n% lands the road went singing, from %a% to %b%.", "%a% behind, %b% ahead, and %n% lands between." } },
  work = {
    chronicle = { "%Q% were completed and %f% defeated.", "%name% saw %q% through and defeated %f%." },
    fireside = { "%Q% done and %f% knocked flat.", "It took %q% and %f% to earn the next step.", "There were %q% to see through and %f% to face." },
    bard = { "%Q% kept and %f% laid low.", "Promises, %q% of them; foes, %f%; and the road went on." } },
  questsOnly = {
    chronicle = { "%Q% were completed without much bloodshed." },
    fireside = { "%Q% done, and hardly a sword drawn.", "%Q% finished, each one a promise kept." },
    bard = { "%Q% kept like candles lit in the dark." } },
  foesOnly = {
    chronicle = { "%F% fell to %name% in this chapter." },
    fireside = { "%F% went down. No time for errands." },
    bard = { "%F% fell, and the grass grew over them." } },
  clean = {
    chronicle = { "Not once did %name% fall.", "The chapter records no falls." },
    fireside = { "You never once saw the spirit healer.", "Nobody laid you low. Not once." },
    bard = { "No grave held you, not even for a breath.", "Untouched by death, the whole way through." } },
  cleanAfter = {
    chronicle = { "After the falls of chapter %r%, a chapter without a single one." },
    fireside = { "After the mess of chapter %r%, not a single fall. Lessons learned." },
    bard = { "Where chapter %r% was all graves, this one was clean as snow." } },
  oneFall = {
    chronicle = { "%name% fell once, and rose again." },
    fireside = { "You fell once, and got back up.", "One fall, one long walk back." },
    bard = { "Once you fell, and once you rose." } },
  falls = {
    chronicle = { "%name% fell %n% times, and each time returned." },
    fireside = { "You went down %n% times, and each time you got back up.", "%N% falls. The spirit healer started saving you a seat." },
    bard = { "%N% times the dark took you, %n% times you walked back into the light." } },
  worstFalls = {
    chronicle = { "No chapter yet had cost so many falls." },
    fireside = { "Your worst chapter for falls so far. It happens." },
    bard = { "Never had the road been crueller." } },
  quick = {
    chronicle = { "It was the swiftest chapter yet.", "No level before had passed so quickly." },
    fireside = { "Fastest level yet. You were flying.", "Blink and you'd have missed this one." },
    bard = { "Swift as a hawk, the quickest chapter yet." } },
  long = {
    chronicle = { "It was the longest chapter so far." },
    fireside = { "The longest level so far. Some are like that.", "This one dragged on. The longest yet." },
    bard = { "Long were these days, the longest of the road so far." } },
  deep = {
    chronicle = { "Below ground, %b% fell to %name% and companions%w%." },
    fireside = { "Down in the dark, %b% went down%w%.", "You went below and %b% didn't come back up%w%." },
    bard = { "In the deep places %b% fell%w%, and songs were owed." } },
  dark = {
    chronicle = { "%name% descended into the dark and returned." },
    fireside = { "You went down into the dark, and came back out." },
    bard = { "Into the dark you went, and out again into the day." } },
  elite = {
    chronicle = { "%name% faced %e% and prevailed." },
    fireside = { "You took on %e% and walked away.", "%E%, and you still standing at the end." },
    bard = { "%E% stood in the way, and then did not." } },
  rare = {
    chronicle = { "A rare beast was hunted down." },
    fireside = { "A rare one crossed your path, and lost." },
    bard = { "A creature of legend met its end on your blade." } },
  pvp = {
    chronicle = { "Blood was spilled against the other faction." },
    fireside = { "There was a scrap with the other faction." },
    bard = { "Banners met, and steel answered steel." } },
  close = {
    chronicle = { "At least once, %name% survived on a sliver of health." },
    fireside = { "At least once it came down to a sliver of health.", "There was a fight you really shouldn't have walked away from." },
    bard = { "Once, the thread of life was drawn thin as a hair, and held." } },
  pals = {
    chronicle = { "%p% shared the road with %name%." },
    fireside = { "%p% came along for part of it.", "%p% shared the road." },
    bard = { "%p% walked beside you a while." } },
  rez = {
    chronicle = { "Another hand raised %name% from death." },
    fireside = { "Somebody raised you when it mattered." },
    bard = { "A kind hand called you back from the grey." } },
  gather = {
    chronicle = { "%name% gathered from the land: %g%." },
    fireside = { "Your pack filled up on the way: %g%.", "In between, you worked the land: %g%." },
    bard = { "The land gave freely: %g%." } },
  fish = {
    chronicle = { "%name% fished the waters and landed %f%." },
    fireside = { "There was a line in the water too: %f%.", "You found time to fish, and landed %f%." },
    bard = { "From quiet water came %f%." } },
  craft = {
    chronicle = { "Between battles, %name% laboured at the bench." },
    fireside = { "Between the fights there was work at the bench." },
    bard = { "Between the battles, the hammer and the needle sang." } },
  auction = {
    chronicle = { "Business was done at the auction house." },
    fireside = { "The auction house saw you more than once." },
    bard = { "Coin changed hands under the auctioneer's eye." } },
  camp = {
    chronicle = { "There was rest by a campfire." },
    fireside = { "There was a fire, and a moment to rest by it." },
    bard = { "A fire, a quiet hour, the stars overhead." } },
  flight = {
    chronicle = { "New flight paths extended the reach of %name%." },
    fireside = { "New wings carried you further." },
    bard = { "Gryphon wings, wind wings: the sky grew larger." } },
  mount = {
    chronicle = { "This was the chapter in which %name% first rode." },
    fireside = { "And this was the chapter you finally got your own mount." },
    bard = { "Hooves on the road at last: the chapter of the first ride." } },
  open = {
    chronicle = { "The chapter is still open.", "The record is still being written." },
    fireside = { "The chapter's still being written.", "The ink here is still wet." },
    bard = { "The song goes on; this verse is still unfinished.", "And the page is still not finished." } },
}

local function chapterZones(events)
  local list, seen, count = {}, {}, {}
  for _, e in ipairs(events) do
    local zn = e.m and J.landOf(e.m)
    if zn then
      if not seen[zn] then seen[zn] = true; list[#list + 1] = zn end
      count[zn] = (count[zn] or 0) + 1
    end
  end
  return list, count
end

-- The chapter (level) where a land first appears in the journal, from the events of earlier chapters.
local function firstChapterOf(j, land, before)
  local best
  for _, e in ipairs(j.events) do
    local l = tonumber(e.l) or 1
    if l < before and e.m and J.landOf(e.m) == land then best = (not best or l < best) and l or best end
  end
  return best
end

local function recordOf(l) return ns.stats and ns.stats.levelRecord and ns.stats.levelRecord(l) or nil end

local function names(list)
  if #list == 0 then return nil end
  if #list == 1 then return list[1] end
  return table.concat(list, ", ", 1, #list - 1) .. " and " .. list[#list]
end

function Vo.chapterProse(l, events, rec, current)
  local j = J.data()
  local seed = "chapter" .. l
  local n = { quest = 0, death = 0, boss = 0, dungeon = 0, rez = 0, craft = 0, auction = 0, close = 0, flight = 0,
    elite = 0, chain = 0, rare = 0, pvp = 0, camp = 0, wipe = 0, mount = 0 }
  local pals, bosses, elites, fish = {}, {}, {}, 0
  for _, e in ipairs(events) do
    local k = e.k
    if k == "chain" or k == "elite" then n.quest = n.quest + 1 end
    if n[k] then n[k] = n[k] + 1 end
    if k == "pal" then
      local who = e.who or (e.s and (e.s:match("with (.+)$") or e.s:match("Met (.-) on")))
      if who then pals[#pals + 1] = who end
    end
    if k == "boss" and e.s then bosses[#bosses + 1] = e.who or e.s:match("^Defeated (.-) in") or e.s:match("^Brought down (.-) in") end
    if k == "elite" and e.who then elites[#elites + 1] = e.who end
  end
  local quests = rec and tonumber(rec.quests) or n.quest
  local foes = rec and tonumber(rec.kills) or 0
  local deaths = rec and tonumber(rec.deaths) or n.death
  local out = {}
  local function add(slot, vars, s2) out[#out + 1] = voiced(L[slot], seed .. slot .. (s2 or ""), vars) end
  -- where, with what came before
  local zones, zcount = chapterZones(events)
  local main
  for _, z in ipairs(zones) do if not main or zcount[z] > zcount[main] then main = z end end
  if #zones > 2 then
    add("manyLands", { a = zones[1], b = zones[#zones], n = say(#zones) })
  elseif main then
    local before = firstChapterOf(j, main, l)
    -- the chapter before this one (the nearest with moments): were you already here?
    local prevL, stayed = nil, false
    for _, e in ipairs(j.events) do
      local el = tonumber(e.l) or 1
      if el < l and (not prevL or el > prevL) then prevL = el end
    end
    for _, e in ipairs(j.events) do
      if (tonumber(e.l) or 1) == prevL and e.m and J.landOf(e.m) == main then stayed = true; break end
    end
    if stayed then add("oneLand", { a = main })
    elseif before then add("backLand", { a = main, r = J.draw.roman(before) })
    elseif not before and l > 1 then add("newLand", { a = main })
    else add("oneLand", { a = main }) end
  end
  -- the work
  if quests > 0 and foes > 0 then
    add("work", { q = count(quests, "quest"), Q = capital(count(quests, "quest")), f = count(foes, "foe") })
  elseif quests > 0 then add("questsOnly", { Q = capital(count(quests, "quest")) })
  elseif foes > 0 then add("foesOnly", { F = capital(count(foes, "foe")) }) end
  -- the deeper roads
  if #bosses > 0 then
    add("deep", { b = names(bosses), w = n.wipe > 0 and ", though not at the first try" or "" })
  elseif n.dungeon > 0 then add("dark") end
  if #elites > 0 then add("elite", { e = elites[1], E = elites[1] })
  elseif n.elite > 0 then add("elite", { e = "an elite", E = "An elite" }) end
  if n.rare > 0 then add("rare") end
  if n.pvp > 0 then add("pvp") end
  -- falls, against the chapters before
  local prev = recordOf(l - 1)
  local worst = 0
  for x = math.max(1, l - 20), l - 1 do
    local r = recordOf(x)
    if r then worst = math.max(worst, tonumber(r.deaths) or 0) end
  end
  if deaths == 0 then
    if prev and (tonumber(prev.deaths) or 0) >= 2 then add("cleanAfter", { r = J.draw.roman(l - 1) })
    elseif (quests + foes) >= 10 then add("clean") end
  elseif deaths == 1 then add("oneFall")
  else
    add("falls", { n = say(deaths), N = capital(say(deaths)) })
    if deaths > worst and worst > 0 then add("worstFalls") end
  end
  if n.close > 0 then add("close") end
  -- pace, against the chapters before (finished chapters only)
  if not current and rec and tonumber(rec.seconds) and l > 3 then
    local fastest, slowest, seen = math.huge, 0, 0
    for x = 2, l - 1 do
      local r = recordOf(x)
      local s = r and tonumber(r.seconds)
      if s and s > 60 and not r.fromPct then seen = seen + 1; fastest = math.min(fastest, s); slowest = math.max(slowest, s) end
    end
    local s = tonumber(rec.seconds)
    if seen >= 2 and s < fastest then add("quick") elseif seen >= 2 and s > slowest then add("long") end
  end
  -- company and the rest of life
  local p = names(pals)
  if p then add("pals", { p = p }) end
  if n.rez > 0 then add("rez") end
  if n.mount > 0 then add("mount") end
  local g = {}
  local Wd = J.wilds
  if Wd then
    for _, w in ipairs({ { "mining", "vein" }, { "herbalism", "herb" }, { "skinning", "hide" } }) do
      local c = Wd.atLevel(w[1], l)
      if c > 0 then g[#g + 1] = count(c, w[2]) end
    end
    fish = Wd.atLevel("fishing", l)
  end
  if #g > 0 then add("gather", { g = names(g) }) end
  if fish > 0 then add("fish", { f = count(fish, "fish", "fish") }) end
  if n.craft > 0 then add("craft") end
  if n.auction > 0 then add("auction") end
  if n.camp > 0 then add("camp") end
  if n.flight > 0 then add("flight") end
  -- a word about who you are, when the chapter shows it
  local top = Vo.traits(j)[1]
  local shows = top and ((top[1] == "gatherer" and #g > 0) or (top[1] == "angler" and fish > 0) or (top[1] == "friend" and p)
    or (top[1] == "lone" and not p) or (top[1] == "delver" and n.dungeon > 0) or (top[1] == "artisan" and n.craft > 0)
    or (top[1] == "unbroken" and deaths == 0) or (top[1] == "undaunted" and deaths > 0) or (top[1] == "wanderer" and #zones > 1)
    or (top[1] == "merchant" and n.auction > 0) or (top[1] == "warbound" and n.pvp > 0))
  local aside = shows and Vo.TRAITS[top[1]].aside
  if aside and #aside > 0 then out[#out + 1] = pick(aside, seed .. "aside") end
  if current then add("open") end
  -- the first two (where, what), then the most telling, the aside and the open page
  local keep = {}
  for i, s in ipairs(out) do
    if i <= 6 or i == #out then keep[#keep + 1] = s end
  end
  return table.concat(keep, " ")
end

----------------------------------------------------------------------------
-- The preface
----------------------------------------------------------------------------
local PREFACE = {
  open = {
    chronicle = { "Here begins the history of %full%, %who%, as set down from the first day in %zone%.",
      "This is the true account of %full%, %who%, whose road began in %zone%." },
    fireside = { "Pull up a log. This is the story of %full%, %who%, and it starts in %zone%.",
      "You want to hear about %full%? %Who%, started out in %zone%. Here's how it went." },
    bard = { "Sing now of %full%, %who%, who set out from %zone% with nothing but hope.",
      "Of %full% this song is made: %who%, and %zone% the first verse." } },
  known = {
    chronicle = { "Those who know the name call %first% %epithet%." },
    fireside = { "Folk around the fires call %first% %epithet%, and not for nothing." },
    bard = { "And the taverns know %first% as %epithet%." } },
  family = {
    chronicle = { "The %last% name is not yet famous. It may be, by the end." },
    fireside = { "Nobody had heard of the %last% family. They will." },
    bard = { "Remember the name %last%; the bards will need it." } },
  lands = {
    chronicle = { "Since then the road has crossed %n%." },
    fireside = { "%N% since then, give or take." },
    bard = { "%N% have passed beneath those boots." } },
  deeds = {
    chronicle = { "There have been %q% and %f% along the way." },
    fireside = { "%Q% and %f% so far, if anyone's counting. I am." },
    bard = { "%Q% and %f%, and every one a verse." } },
  clean = {
    chronicle = { "Not a single fall is recorded." },
    fireside = { "Not one fall yet. Touch wood." },
    bard = { "And death has not yet learned the way." } },
  falls = {
    chronicle = { "There have been %d%, and after each %first% rose." },
    fireside = { "There have been %d%. Every time, back up again." },
    bard = { "%D% times the dark has claimed this hero, and every time it gave them back." } },
  close = {
    chronicle = { "What follows is written as it happened, a level to a chapter." },
    fireside = { "Turn the page; every level has its own chapter." },
    bard = { "Turn the leaves: each level is a verse of its own." } },
}

function Vo.preface(j, V)
  if type(j) ~= "table" or #j.events == 0 then return nil end
  local first, last = Vo.names()
  local full = last and (first .. " " .. last) or first
  local firstEvent = j.events[1]
  local zone = firstEvent and firstEvent.m and J.landOf(firstEvent.m) or "the wide world"
  local who = V and V.className ~= "" and ((V.race ~= "" and (V.race .. " ") or "") .. V.className) or "adventurer"
  local seed = "preface"
  local out = {}
  local vars = { full = full, first = first, last = last, who = who, Who = capital(who), zone = zone }
  local function add(slot, more)
    for k, v in pairs(more or {}) do vars[k] = v end
    out[#out + 1] = voiced(PREFACE[slot], seed .. slot, vars)
  end
  add("open")
  local ep = Vo.epithet(j)
  if ep then add("known", { epithet = ep }) end
  if last then add("family") end
  local lands = type(j.order) == "table" and #j.order or 0
  if lands > 1 then add("lands", { n = count(lands, "land"), N = capital(count(lands, "land")) }) end
  local totals = V and V.totals or {}
  local q, k = tonumber(totals.quests) or 0, tonumber(totals.kills) or 0
  if q + k > 0 then add("deeds", { q = count(q, "quest"), Q = capital(count(q, "quest")), f = count(k, "foe") }) end
  local d = tonumber(j.deaths) or 0
  if d == 0 then add("clean") else add("falls", { d = count(d, "fall"), D = capital(say(d)) }) end
  add("close")
  return table.concat(out, " ")
end

----------------------------------------------------------------------------
-- Moments that remember the ones before them (J.add asks J.retell before it writes one)
----------------------------------------------------------------------------
local AGAIN_DEATH = { "%killer% again, in %zone%. This is becoming a habit", "Fell to %killer% for the %nth% time. A grudge is forming",
  "%killer% wins another round in %zone%. Not the last word, though", "Beaten by %killer% once more, in %zone%. Next time",
  "%killer%, again. Some lessons take a while" }
local REGULAR = { "Back to %giver% once more: the %nth% favour done in %zone%", "%giver% had another job, and you saw it through: number %n%",
  "By now %giver% greets you by name: favour number %n%, in %zone%", "Another errand for %giver%, the %nth%. They keep a cup ready for you now" }

local function ordinal(n)
  local words = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" }
  return words[n] or (tostring(n) .. "th")
end

function J.retell(kind, text, extra)
  local j = J.data()
  if kind == "death" and extra and type(extra.who) == "string" and not extra.pvp then
    local before = 0
    for _, e in ipairs(j.events) do if e.k == "death" and e.who == plain(extra.who) then before = before + 1 end end
    if before >= 1 then
      return fill(pick(AGAIN_DEATH, extra.who .. before), { killer = plain(extra.who), zone = J.zoneName(), nth = ordinal(before + 1) })
    end
  elseif kind == "quest" and extra and extra.q and J.finisher then
    local giver = J.finisher(extra.q)
    if not giver then return nil end
    local before = 0
    for _, e in ipairs(j.events) do
      if e.q and (e.k == "quest" or e.k == "chain" or e.k == "elite") and J.finisher(e.q) == giver then before = before + 1 end
    end
    -- the third favour and every other one after: the rest keep their own words
    if before >= 2 and before % 2 == 0 then
      return fill(pick(REGULAR, giver .. before), { giver = giver, zone = J.zoneName(), n = tostring(before + 1), nth = ordinal(before + 1) })
    end
  end
end

-- The Lore file's prose and preface give way to the narrator's.
J.lore.chapterProse = Vo.chapterProse
J.lore.preface = Vo.preface

function ns.journeyVoiceDebugLines()
  local first, last = Vo.names()
  local raw = try(UnitName, "player")
  local function show(s)
    if type(s) ~= "string" then return tostring(s) end
    return (s:gsub("[^\32-\126]", function(c) return "\\" .. c:byte() end))
  end
  local pvp = type(UnitPVPName) == "function" and select(2, pcall(UnitPVPName, "player")) or nil
  local top = Vo.traits()[1]
  return { "journey voice: " .. Vo.style() .. ", name '" .. show(first) .. "' + '" .. show(last or "-") .. "' from UnitName '"
    .. show(raw) .. "', UnitPVPName '" .. show(pvp) .. "', NameUtil " .. tostring(C_NameUtil ~= nil)
    .. ", top trait " .. (top and (top[1] .. " " .. string.format("%.1f", top[2])) or "none") }
end
