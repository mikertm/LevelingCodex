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

-- Forever: UnitFullName("player") returns name, surname (elsewhere the second value is the realm,
-- so it is read only on a client with Forever's surname APIs).
local function foreverSurname(first)
  local forever = (C_NameUtil and C_NameUtil.ReplaceSurnameSeparatorWithLinkSeparator)
    or (C_PlayerInfo and C_PlayerInfo.ShouldDisplaySurname)
  if not forever or type(UnitFullName) ~= "function" then return nil end
  local ok, name, sur = pcall(UnitFullName, "player")
  if not ok or type(sur) ~= "string" or sur == "" then return nil end
  if GetRealmName then
    local okR, realm = pcall(GetRealmName)
    if okR and type(realm) == "string" and (realm == sur or realm:gsub("%s", "") == sur) then return nil end
  end
  -- a full name in the first value carries the surname after the first name; keep just the surname
  if type(name) == "string" and first and sur:find(first, 1, true) == 1 then sur = after(sur, first) or sur end
  return sur
end

function Vo.names()
  local raw = try(UnitName, "player")
  local first, last = split(type(raw) == "string" and raw or nil)
  first = first or "Adventurer"
  -- the surname is the book's, whatever the nameplate setting (ShouldDisplaySurname) says
  if not last then last = foreverSurname(first) end
  if not last then
    for _, src in ipairs({ { UnitNameUnmodified, "player" }, { UnitPVPName, "player" }, { GetUnitName, "player", false } }) do
      if type(src[1]) == "function" then
        local ok, s = pcall(src[1], src[2], src[3])
        last = ok and after(s, first) or nil
        if last then break end
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
      "%a% enters the history here, with %name% walking into it.", "Here %name% set foot in %a%, a land not yet in these pages.",
      "It was in this chapter that %a% first saw %name%.", "The chronicle turns to %a%, where %name% had never been." },
    fireside = { "Then came %a%, and you'd never set foot there before.", "First time in %a%. Remember the smell of it?",
      "You wandered into %a% with no idea what was waiting.", "%a%. New maps, new faces, and nobody knew your name yet.",
      "You crossed into %a% for the first time, a little lost and loving it.",
      "Fresh ground: %a%. You stopped at the border just to look." },
    bard = { "New ground under new skies: %a% opened its gates.", "%a% rose before you, strange and wide and waiting.",
      "And the road unrolled into %a%, a land not yet sung.", "A new verse begins where %a% begins.",
      "Past the last known road lay %a%, and you went.", "%a% had waited a long age for you, and now you came." } },
  backLand = {
    chronicle = { "%name% returned to %a%, last seen in chapter %r%.", "Once more the record finds %name% in %a%, as in chapter %r%.",
      "The chronicle returns to %a%, first visited in chapter %r%.", "%name% came back to %a%, a land known since chapter %r%." },
    fireside = { "Back to %a% again; you'd been there in chapter %r%.", "%a% one more time. Some places just keep pulling you back.",
      "You knew %a% already, from chapter %r%. It knew you too.", "Back in %a%. The paths looked shorter than you remembered.",
      "%a% again. Funny how a place changes when you're stronger." },
    bard = { "The road curled home to %a%, remembered from chapter %r%.", "%a% again, its old paths waiting where you left them.",
      "Once more to %a%, an old tune in a new key.", "%a% called you back, as old lands do." } },
  oneLand = {
    chronicle = { "The whole of this chapter took place in %a%.", "%name% did not leave %a% in this chapter.",
      "%a% was the setting of every page of this chapter.", "Throughout this chapter %name% remained in %a%." },
    fireside = { "All of it happened in %a%.", "%a% kept you busy the whole time.", "You never left %a% this time round.",
      "%a%, start to finish. You got to know every hill.", "You dug into %a% and stayed there until the job was done." },
    bard = { "%a% held you, every hour of it.", "One land, one long song: %a%.", "Every verse of this chapter is sung in %a%.",
      "You and %a%, and nothing else beneath the sky." } },
  manyLands = {
    chronicle = { "From %a% the road led on through %n% lands, as far as %b%.", "The chapter crosses %n% lands, %a% to %b%.",
      "%name% travelled widely: %n% lands, beginning in %a% and ending in %b%.",
      "Few chapters cover so much ground: %n% lands between %a% and %b%." },
    fireside = { "The road ran long this time: %a%, and on all the way to %b%.", "You covered ground: %n% lands, %a% to %b%.",
      "%N% lands in one level. Your boots must have hated you.", "It started in %a% and somehow ended in %b%, by way of everywhere.",
      "You wandered all over: %n% lands, from %a% to %b%." },
    bard = { "Over %n% lands the road went singing, from %a% to %b%.", "%a% behind, %b% ahead, and %n% lands between.",
      "Through %n% lands the wind followed you, from %a% to %b%.", "From %a% to %b% you went, and the world grew wide." } },
  work = {
    chronicle = { "%Q% %qv% completed and %f% defeated.", "%name% saw %q% through and defeated %f%.",
      "The tally stands at %q% and %f%.", "%name% finished %q% and put down %f% along the way." },
    fireside = { "%Q% done and %f% knocked flat.", "It took %q% and %f% to earn the next step.",
      "On the list: %q% to see through and %f% to face.", "You ticked off %q% and saw off %f%.",
      "%Q% handed in, %f% sent to the dirt. A fair day's work." },
    bard = { "%Q% kept and %f% laid low.", "Promises kept, %q%; foes felled, %f%; and the road went on.",
      "%Q% fulfilled, %f% fallen, and the next step won.", "Sing of %q% and %f%, for both were earned." } },
  workLight = {
    chronicle = { "Little was asked of %name% here: %q% and %f%.", "A quiet chapter: %q%, %f%." },
    fireside = { "Not much to tell on the work side: %q% and %f%.", "An easy stretch. %Q% and %f%, then on.",
      "You took it slow: %q%, %f%, and plenty of looking around." },
    bard = { "A short verse of work: %q%, %f%.", "Light was the load: %q% and %f%, no more." } },
  workHeavy = {
    chronicle = { "It was a chapter of great labour: %q% and %f%.", "%name% worked without rest: %q%, and %f% defeated." },
    fireside = { "You did not stop. %Q% and %f%, one after another.", "A busy one: %q% and %f%. Your hands still ache.",
      "%Q%, %f%. Somebody had to do it, and it was you." },
    bard = { "Long was the list and longer the fight: %q% and %f%.", "%Q% and %f%: a heavy chapter, nobly borne." } },
  questsOnly = {
    chronicle = { "%Q% %qv% completed without much bloodshed.", "%name% finished %q%, and drew steel rarely." },
    fireside = { "%Q% done, and hardly a sword drawn.", "%Q% finished, each one a promise kept.",
      "You talked and walked your way through %q%." },
    bard = { "%Q% kept like candles lit in the dark.", "Not by the sword this time, but by the word: %q%." } },
  foesOnly = {
    chronicle = { "%F% fell to %name% in this chapter.", "No errands are recorded, only %f% defeated." },
    fireside = { "%F% went down. No time for errands.", "Forget the notice board: %f%, and that was the chapter." },
    bard = { "%F% fell, and the grass grew over them.", "No promises here, only %f% and the blade." } },
  clean = {
    chronicle = { "Not once did %name% fall.", "The chapter records no falls.", "%name% came through it without a single fall." },
    fireside = { "You never once saw the spirit healer.", "Nobody laid you low. Not once.",
      "Not a scratch you couldn't walk off.", "No deaths. You were careful, or lucky, or both." },
    bard = { "No grave held you, not even for a breath.", "Untouched by death, the whole way through.",
      "Death looked for you and found an empty road." } },
  cleanAfter = {
    chronicle = { "After the falls of chapter %r%, a chapter without a single one.",
      "Chapter %r% had cost dearly; this one cost nothing." },
    fireside = { "After the mess of chapter %r%, not a single fall. Lessons learned.",
      "Chapter %r% hurt. This one didn't. You'd learned something." },
    bard = { "Where chapter %r% was all graves, this one was clean as snow.",
      "The graves of chapter %r% behind you, and none ahead." } },
  oneFall = {
    chronicle = { "%name% fell once, and rose again.", "One fall is recorded in this chapter." },
    fireside = { "You fell once, and got back up.", "One fall, one long walk back.",
      "One death. We don't talk about it.", "You died the once. The spirit healer barely looked up." },
    bard = { "Once you fell, and once you rose.", "Once the dark came, and once it let you go." } },
  falls = {
    chronicle = { "%name% fell %n% times, and each time returned.", "%N% falls are recorded in this chapter." },
    fireside = { "You went down %n% times, and each time you got back up.", "%N% falls. The spirit healer started saving you a seat.",
      "%N% deaths. Some of them were even your fault.", "You died %n% times. The corpse run knows you by name." },
    bard = { "%N% times the dark took you, %n% times you walked back into the light.",
      "%N% times you fell, and the song would not let you stay down." } },
  worstFalls = {
    chronicle = { "No chapter yet had cost so many falls.", "It was the costliest chapter yet." },
    fireside = { "Your worst chapter for falls so far. It happens.", "No chapter had hurt this much. Not yet, anyway." },
    bard = { "Never had the road been crueller.", "The cruellest verse yet." } },
  quick = {
    chronicle = { "It was the swiftest chapter yet.", "No level before had passed so quickly." },
    fireside = { "Fastest level yet. You were flying.", "Blink and you'd have missed this one.",
      "Over before the tea was cold. Your quickest level yet." },
    bard = { "Swift as a hawk, the quickest chapter yet.", "Like a thrown spear it went, the swiftest yet." } },
  long = {
    chronicle = { "It was the longest chapter so far.", "No chapter before had taken so long." },
    fireside = { "The longest level so far. Some are like that.", "This one dragged on. The longest yet.",
      "This one took its time. Longest level so far." },
    bard = { "Long were these days, the longest of the road so far.", "Slow as a winter the chapter went." } },
  deep = {
    chronicle = { "Below ground, %b% fell to %name% and companions%w%.", "In the depths, %name% saw %b% defeated%w%." },
    fireside = { "Down in the dark, %b% went down%w%.", "You went below and %b% didn't come back up%w%.",
      "There was a dungeon, and %b% at the bottom of it%w%." },
    bard = { "In the deep places %b% fell%w%, and songs were owed.", "Under the stone, %b% fell%w%." } },
  dark = {
    chronicle = { "%name% descended into the dark and returned.", "%name% went below ground and came back." },
    fireside = { "You went down into the dark, and came back out.", "There was a dungeon in there too." },
    bard = { "Into the dark you went, and out again into the day." } },
  elite = {
    chronicle = { "%name% faced %e% and prevailed.", "%E% was overcome." },
    fireside = { "You took on %e% and walked away.", "%E%, and you still standing at the end.",
      "%E% was supposed to be too much for you. It wasn't." },
    bard = { "%E% stood in the way, and then did not.", "Great was %e%, and greater the one who stood against it." } },
  rare = {
    chronicle = { "A rare beast was hunted down.", "A rarely seen creature was slain." },
    fireside = { "A rare one crossed your path, and lost.", "You found something rare out there, and it didn't last." },
    bard = { "A creature of legend met its end on your blade." } },
  pvp = {
    chronicle = { "Blood was spilled against the other faction.", "There was fighting with the other faction." },
    fireside = { "There was a scrap with the other faction.", "The other side showed up. Words were exchanged. Mostly steel." },
    bard = { "Banners met, and steel answered steel." } },
  close = {
    chronicle = { "At least once, %name% survived on a sliver of health.", "Once, %name% came within a breath of death." },
    fireside = { "At least once it came down to a sliver of health.", "There was a fight you really shouldn't have walked away from.",
      "You walked away from one fight on almost nothing. Don't do that again." },
    bard = { "Once, the thread of life was drawn thin as a hair, and held." } },
  pals = {
    chronicle = { "%p% shared the road with %name%.", "%name% was joined for a time by %p%." },
    fireside = { "%p% came along for part of it.", "%p% shared the road.", "You weren't alone: %p% were there for some of it.",
      "Good company: %p%." },
    bard = { "%p% walked beside you a while.", "Not alone: %p% marched at your side." } },
  palsOne = {
    chronicle = { "%p% shared the road with %name%.", "%name% was joined for a time by %p%." },
    fireside = { "%p% came along for part of it.", "%p% shared the road.", "You weren't alone: %p% was there for some of it." },
    bard = { "%p% walked beside you a while.", "Not alone: %p% marched at your side." } },
  rez = {
    chronicle = { "Another hand raised %name% from death." },
    fireside = { "Somebody raised you when it mattered.", "Someone stopped and brought you back. Remember that." },
    bard = { "A kind hand called you back from the grey." } },
  gather = {
    chronicle = { "%name% gathered from the land: %g%.", "The land yielded %g% to %name%." },
    fireside = { "Your pack filled up on the way: %g%.", "In between, you worked the land: %g%.",
      "You kept stopping to pick things up: %g%." },
    bard = { "The land gave freely: %g%.", "Root and stone and hide gave up their riches: %g%." } },
  fish = {
    chronicle = { "%name% fished the waters and landed %f%." },
    fireside = { "There was a line in the water too: %f%.", "You found time to fish, and landed %f%." },
    bard = { "From quiet water came %f%." } },
  craft = {
    chronicle = { "Between battles, %name% laboured at the bench.", "%name% also practised a craft." },
    fireside = { "Between the fights there was work at the bench.", "You spent some evenings making things." },
    bard = { "Between the battles, the hammer and the needle sang." } },
  auction = {
    chronicle = { "Business was done at the auction house.", "%name% traded at the auction house." },
    fireside = { "The auction house saw you more than once.", "You haggled at the auction house. Of course you did." },
    bard = { "Coin changed hands under the auctioneer's eye." } },
  camp = {
    chronicle = { "There was rest by a campfire." },
    fireside = { "There was a fire, and a moment to rest by it.", "You sat by a fire once, and let the world wait." },
    bard = { "A fire, a quiet hour, the stars overhead." } },
  flight = {
    chronicle = { "New flight paths extended the reach of %name%." },
    fireside = { "New wings carried you further.", "You found new flight paths. The map got smaller." },
    bard = { "Gryphon wings, wind wings: the sky grew larger." } },
  mount = {
    chronicle = { "This was the chapter in which %name% first rode." },
    fireside = { "And this was the chapter you finally got your own mount." },
    bard = { "Hooves on the road at last: the chapter of the first ride." } },
  open = {
    chronicle = { "The chapter is still open.", "The record is still being written.", "This account is not yet complete." },
    fireside = { "The chapter's still being written.", "The ink here is still wet.", "And we're not done with this one yet.",
      "That's where things stand. More soon." },
    bard = { "The song goes on; this verse is still unfinished.", "And the page is still not finished.",
      "The last line of this verse is yours to write." } },
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

-- More things a chapter can notice, each in the three voices.
local M = {
  -- a first sentence about the chapter's mood, which some chapters open with instead of the land
  moodHard = {
    chronicle = { "This was a hard chapter for %name%.", "Few chapters tested %name% as this one did." },
    fireside = { "This one was rough. No point pretending otherwise.", "You'll remember this level, and not fondly.",
      "Some levels are a stroll. This wasn't one of them." },
    bard = { "Here the song turns dark.", "A grim verse, this one, sung low." } },
  moodBusy = {
    chronicle = { "This was a chapter of hard work.", "%name% laboured without pause through this chapter." },
    fireside = { "Head down, sleeves up: this was a working level.", "You barely stopped to breathe this time.",
      "This one was all business." },
    bard = { "Hammer and blade kept time through this verse.", "A working song, this one, all sweat and steel." } },
  moodWander = {
    chronicle = { "This was a chapter of travel.", "%name% spent this chapter on the move." },
    fireside = { "This level was mostly roads.", "You spent this one with the map open.", "Restless feet this time." },
    bard = { "A walking song, this one.", "The road itself is the hero of this verse." } },
  moodDeep = {
    chronicle = { "This chapter went underground.", "Much of this chapter took place below." },
    fireside = { "This was a dungeon level, mostly.", "Torches, stone and bad smells: this one went underground." },
    bard = { "Down, down into the dark the verse descends." } },
  moodCompany = {
    chronicle = { "This chapter was not walked alone.", "Company marked this chapter." },
    fireside = { "This was a friends level.", "You had company this time, and it showed." },
    bard = { "A song for many voices, this one." } },
  moodQuiet = {
    chronicle = { "This was a quiet chapter.", "Little disturbed this chapter." },
    fireside = { "A gentle one, this. Nothing much tried to kill you.", "A quiet level. Those are nice too." },
    bard = { "A soft verse, sung by a quiet fire." } },
  moodSwift = {
    chronicle = { "This chapter passed quickly.", "It was a brief chapter." },
    fireside = { "This one went by in a flash.", "Short and sweet, this level." },
    bard = { "A short, bright verse." } },
  -- named quests
  titles = {
    chronicle = { "Among the tasks recorded: %t%.", "The quest log of this chapter includes %t%." },
    fireside = { "You'll remember %t%.", "There was %t%, for one.", "Remember %t%? That was this level.",
      "%T% stands out." },
    bard = { "Of all the tasks, sing %t%.", "%T%: those names are in this verse." } },
  chainDone = {
    chronicle = { "A long quest chain reached its end here: %t%." },
    fireside = { "And a long one finally wrapped up: %t%.", "You saw %t% through to the very end." },
    bard = { "A long tale ended here: %t%." } },
  -- how the level was earned
  byQuests = {
    chronicle = { "Most of the experience came from completed quests.", "Quests, not combat, carried %name% through this level." },
    fireside = { "Most of this level came from handing things in.", "The quest givers paid for most of this one." },
    bard = { "The words of others, not the blade, raised you here." } },
  byKills = {
    chronicle = { "Most of the experience came from combat.", "%name% earned this level largely by the sword." },
    fireside = { "Most of this level was earned the old way: hitting things.", "More fighting than errands this time." },
    bard = { "This level was carved out with steel." } },
  rested = {
    chronicle = { "Rest earned earlier made the climb easier." },
    fireside = { "A good night's rest did a lot of the work here.", "Rested XP carried you a long way this time." },
    bard = { "Rest, well taken, bore you up the hill." } },
  -- gold
  richer = {
    chronicle = { "%name% ended the chapter %m% richer.", "The purse grew by %m%." },
    fireside = { "You came out of it %m% richer.", "The purse is %m% heavier for it.", "%M% better off, all told." },
    bard = { "Coin came in: %m% to the good." } },
  poorer = {
    chronicle = { "The chapter cost %name% %m%.", "%name% spent %m% more than was earned." },
    fireside = { "It cost you %m%, between trainers and repairs.", "You spent %m% more than you made. It happens." },
    bard = { "The purse grew lighter by %m%." } },
  -- falls with a name
  killer = {
    chronicle = { "%who% claimed %name% once in this chapter.", "%name% fell to %who%." },
    fireside = { "%who% put you in the dirt.", "It was %who% that got you.", "%who% got the better of you. Remember the name." },
    bard = { "%who% laid you low, and the song remembers it." } },
  killers = {
    chronicle = { "Among those who felled %name%: %who%." },
    fireside = { "%who% all had a go at you, and won.", "Your killers this level: %who%." },
    bard = { "By %who% you fell, and rose again." } },
  closeWho = {
    chronicle = { "%who% brought %name% down to %pct% health, and no further." },
    fireside = { "%who% had you down to %pct% health. Too close.", "You walked away from %who% on %pct% health." },
    bard = { "%who% drew you to the edge, %pct% from the grave." } },
  rareWho = {
    chronicle = { "The rare %who% was slain." },
    fireside = { "You ran into %who%, a rare one, and it didn't end well for them." },
    bard = { "%who%, rarely seen, was seen one last time." } },
  -- the clock
  night = {
    chronicle = { "Much of this chapter was written late at night." },
    fireside = { "Most of this happened well past midnight. Get some sleep.", "A night owl's level, this one." },
    bard = { "Under the stars and the late lamp this verse was made." } },
  morning = {
    chronicle = { "Much of this chapter was written in the early morning." },
    fireside = { "An early-riser's level: much of it before breakfast." },
    bard = { "Dawn light runs through this verse." } },
  oneSitting = {
    chronicle = { "The whole chapter was written in a single day." },
    fireside = { "All of it in one sitting.", "Start to finish in one day." },
    bard = { "One day held the whole verse." } },
  manyDays = {
    chronicle = { "The chapter was written over %n% days." },
    fireside = { "This one took %n% days of play.", "Spread over %n% days, this one." },
    bard = { "%N% days it took to sing this verse." } },
  -- pace against the chapter before
  faster = {
    chronicle = { "It took %d% less than the chapter before it." },
    fireside = { "%D% quicker than the level before. You're getting better at this.", "Faster than last time, by %d%." },
    bard = { "Swifter than the verse before, by %d%." } },
  slower = {
    chronicle = { "It took %d% longer than the chapter before it." },
    fireside = { "%D% slower than the level before. No shame in that.", "This one took %d% longer than the last." },
    bard = { "Slower than the verse before, by %d%." } },
  -- things found and gained
  firstFind = {
    chronicle = { "%S%, the first of its kind in this record.", "%S%. It was a first." },
    fireside = { "%S%. First one ever.", "%S%, which was a first.", "%S%. You'll always remember that one." },
    bard = { "%S%, and the moment shone.", "%S%, a first, and a bright one." } },
  upgrade = {
    chronicle = { "%S%.", "%S%, to better effect." },
    fireside = { "%S%, and looked the better for it.", "%S%. Small upgrades add up." },
    bard = { "%S%, new steel for the road." } },
  upgrades = {
    chronicle = { "%name% replaced %n% pieces of equipment." },
    fireside = { "%N% pieces of gear swapped for better ones.", "You changed out %n% pieces of kit." },
    bard = { "%N% times the old gear gave way to new." } },
  home = {
    chronicle = { "%S%." },
    fireside = { "%S%, and slept better for it.", "%S%. Every traveller needs somewhere to come back to." },
    bard = { "%S%, and the hearth was warm." } },
  milestone = {
    chronicle = { "%S%, a milestone." },
    fireside = { "%S%. A milestone, that.", "%S%. Worth a toast." },
    bard = { "%S%, a mark upon the long road." } },
  abandon = {
    chronicle = { "%Q% %qv% abandoned." },
    fireside = { "%Q% got left by the roadside.", "You gave up on %q%. Some aren't worth it." },
    bard = { "%Q% left unsung, forgotten by the road." } },
  duel = {
    chronicle = { "%name% fought %n% duels." },
    fireside = { "You found time for %n% duels.", "%N% duels. Somebody's competitive." },
    bard = { "%N% times blades crossed in sport." } },
  bond = {
    chronicle = { "A bond grew with %who%." },
    fireside = { "You and %who% got closer.", "%who% is more than a stranger now." },
    bard = { "With %who% a bond was forged." } },
  reunion = {
    chronicle = { "%name% met %who% again." },
    fireside = { "An old face turned up: %who%.", "You ran into %who% again." },
    bard = { "Old friends met again: %who%." } },
  flights = {
    chronicle = { "%N% new flight paths were found." },
    fireside = { "%N% new flight paths. The map shrinks." },
    bard = { "%N% new roads through the sky." } },
}

local function hashOf(s)
  local h = 0
  s = (J.salt or "") .. tostring(s)
  for i = 1, #s do h = (h * 31 + s:byte(i)) % 2147483647 end
  return h
end
local function hourOf(t)
  if type(date) ~= "function" or not tonumber(t) then return nil end
  local ok, d = pcall(date, "*t", tonumber(t))
  return ok and type(d) == "table" and tonumber(d.hour) or nil
end
local function money(c)
  c = math.floor(math.abs(tonumber(c) or 0))
  return ns.money and ns.money(c) or (math.floor(c / 10000) .. "g")
end

function Vo.chapterProse(l, events, rec, current)
  local j = J.data()
  local seed = "chapter" .. l
  local n = { quest = 0, death = 0, boss = 0, dungeon = 0, rez = 0, craft = 0, auction = 0, close = 0, flight = 0,
    elite = 0, chain = 0, rare = 0, pvp = 0, camp = 0, wipe = 0, mount = 0, upgrade = 0, abandon = 0, duel = 0 }
  local pals, bosses, elites, killers, titles, chains = {}, {}, {}, {}, {}, {}
  local firstFind, upgrade, home, milestone, closeE, rareE, bondE, reunionE
  local night, morning, timed = 0, 0, 0
  local tFirst, tLast
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
    if k == "death" and type(e.who) == "string" and e.who ~= "" then
      local seen = false
      for _, w in ipairs(killers) do if w == e.who then seen = true end end
      if not seen then killers[#killers + 1] = e.who end
    end
    local title = type(e.d) == "string" and e.d:match("^Quest: (.+)$")
    if title and (k == "quest" or k == "chain" or k == "elite") then
      titles[#titles + 1] = title
      if k == "chain" then chains[#chains + 1] = title end
    end
    if k == "first" and not firstFind then firstFind = e end
    if k == "upgrade" and (not upgrade or (tonumber(e.iq) or 0) > (tonumber(upgrade.iq) or 0)) then upgrade = e end
    if k == "home" then home = e end
    if k == "milestone" then milestone = e end
    if k == "close" and type(e.who) == "string" and (not closeE or (tonumber(e.pct) or 100) < (tonumber(closeE.pct) or 100)) then closeE = e end
    if k == "rare" and type(e.who) == "string" then rareE = e end
    if k == "bond" and type(e.who) == "string" then bondE = e end
    if k == "reunion" and type(e.who) == "string" then reunionE = e end
    local h = hourOf(e.t)
    if h then
      timed = timed + 1
      if h >= 23 or h < 5 then night = night + 1 elseif h >= 5 and h < 9 then morning = morning + 1 end
    end
    local t = tonumber(e.t)
    if t then tFirst = (not tFirst or t < tFirst) and t or tFirst; tLast = (not tLast or t > tLast) and t or tLast end
  end
  local quests = rec and tonumber(rec.quests) or n.quest
  local foes = rec and tonumber(rec.kills) or 0
  local deaths = rec and tonumber(rec.deaths) or n.death
  -- every sentence the chapter could say, with how much it matters (higher first) and its place in the telling
  local cands = {}
  local function cand(pri, order, slot, vars, pool)
    local text = voiced((pool or L)[slot], seed .. slot, vars or {})
    if text and text ~= "" then
      -- a little seeded jitter so neighbouring chapters don't pick the same sentences in the same order
      cands[#cands + 1] = { pri = pri + (hashOf(seed .. slot) % 100) / 100, order = order, text = text, slot = slot }
    end
  end
  local function M_(pri, order, slot, vars) cand(pri, order, slot, vars, M) end
  -- where, with what came before
  local zones, zcount = chapterZones(events)
  local main
  for _, z in ipairs(zones) do if not main or zcount[z] > zcount[main] then main = z end end
  local place
  if #zones > 2 then
    place = { "manyLands", { a = zones[1], b = zones[#zones], n = say(#zones), N = capital(say(#zones)) } }
  elseif main then
    local before = firstChapterOf(j, main, l)
    local prevL, stayed = nil, false
    for _, e in ipairs(j.events) do
      local el = tonumber(e.l) or 1
      if el < l and (not prevL or el > prevL) then prevL = el end
    end
    for _, e in ipairs(j.events) do
      if (tonumber(e.l) or 1) == prevL and e.m and J.landOf(e.m) == main then stayed = true; break end
    end
    if stayed then place = { "oneLand", { a = main } }
    elseif before then place = { "backLand", { a = main, r = J.draw.roman(before) } }
    elseif l > 1 then place = { "newLand", { a = main } }
    else place = { "oneLand", { a = main } } end
  end
  -- the mood, which may open the chapter instead of the land
  local mood
  if deaths >= 3 or n.wipe >= 2 then mood = "moodHard"
  elseif n.dungeon + #bosses >= 2 then mood = "moodDeep"
  elseif #zones >= 4 then mood = "moodWander"
  elseif #pals >= 2 then mood = "moodCompany"
  elseif quests >= 15 or foes >= 150 then mood = "moodBusy"
  elseif rec and tonumber(rec.seconds) and tonumber(rec.seconds) < 1800 and not current then mood = "moodSwift"
  elseif quests + foes > 0 and quests + foes < 15 and deaths == 0 then mood = "moodQuiet" end
  -- the work
  local wv = { q = count(quests, "quest"), Q = capital(count(quests, "quest")), qv = quests == 1 and "was" or "were",
    f = count(foes, "foe"), F = capital(count(foes, "foe")) }
  if quests > 0 and foes > 0 then
    cand(8, 2, (quests >= 15 or foes >= 150) and "workHeavy" or (quests <= 3 and foes < 30) and "workLight" or "work", wv)
  elseif quests > 0 then cand(8, 2, "questsOnly", wv)
  elseif foes > 0 then cand(8, 2, "foesOnly", wv) end
  -- named quests: a finished chain first, else two titles picked by the chapter
  if #chains > 0 then
    M_(7, 3, "chainDone", { t = chains[1] })
  elseif #titles >= 2 then
    local a = hashOf(seed .. "t") % #titles + 1
    local b = (a % #titles) + 1
    local t = titles[a] .. " and " .. titles[b]
    M_(5, 3, "titles", { t = t, T = capital(t) })
  elseif #titles == 1 then
    M_(4, 3, "titles", { t = titles[1], T = capital(titles[1]) })
  end
  -- how the level was earned
  if rec and not current then
    local qx, kx, rx, all = tonumber(rec.questXP) or 0, tonumber(rec.killXP) or 0, tonumber(rec.rested) or 0, tonumber(rec.xp) or 0
    if all > 0 and qx >= all * 0.6 then M_(4, 2, "byQuests")
    elseif all > 0 and kx >= all * 0.6 then M_(4, 2, "byKills") end
    if all > 0 and rx >= all * 0.3 then M_(4, 2, "rested") end
  end
  -- the deeper roads
  if #bosses > 0 then cand(9, 4, "deep", { b = names(bosses), w = n.wipe > 0 and ", though not at the first try" or "" })
  elseif n.dungeon > 0 then cand(6, 4, "dark") end
  if #elites > 0 then cand(7, 4, "elite", { e = elites[1], E = elites[1] })
  elseif n.elite > 0 then cand(6, 4, "elite", { e = "an elite", E = "An elite" }) end
  if rareE then M_(7, 4, "rareWho", { who = rareE.who }) elseif n.rare > 0 then cand(5, 4, "rare") end
  if n.pvp > 0 then cand(6, 4, "pvp") end
  if n.duel > 0 then M_(4, 4, "duel", { n = say(n.duel), N = capital(say(n.duel)) }) end
  -- falls, against the chapters before
  local prev = recordOf(l - 1)
  local worst = 0
  for x = math.max(1, l - 20), l - 1 do
    local r = recordOf(x)
    if r then worst = math.max(worst, tonumber(r.deaths) or 0) end
  end
  if deaths == 0 then
    if prev and (tonumber(prev.deaths) or 0) >= 2 then cand(8, 5, "cleanAfter", { r = J.draw.roman(l - 1) })
    elseif (quests + foes) >= 10 then cand(5, 5, "clean") end
  elseif #killers == 1 and deaths == 1 then M_(8, 5, "killer", { who = killers[1] })
  elseif #killers >= 2 then
    cand(7, 5, "falls", { n = say(deaths), N = capital(say(deaths)) })
    M_(7, 5, "killers", { who = names({ killers[1], killers[2], killers[3] }) })
  elseif deaths == 1 then cand(6, 5, "oneFall")
  else cand(7, 5, "falls", { n = say(deaths), N = capital(say(deaths)) }) end
  if deaths > worst and worst > 0 and deaths >= 2 then cand(8, 5.5, "worstFalls") end
  if closeE then M_(7, 5, "closeWho", { who = closeE.who, pct = (tonumber(closeE.pct) or 0) .. "%" })
  elseif n.close > 0 then cand(5, 5, "close") end
  -- pace, against the chapters before (finished chapters only)
  if not current and rec and tonumber(rec.seconds) and l > 3 then
    local fastest, slowest, seenN = math.huge, 0, 0
    for x = 2, l - 1 do
      local r = recordOf(x)
      local s = r and tonumber(r.seconds)
      if s and s > 60 and not r.fromPct then seenN = seenN + 1; fastest = math.min(fastest, s); slowest = math.max(slowest, s) end
    end
    local s = tonumber(rec.seconds)
    if seenN >= 2 and s < fastest then cand(7, 6, "quick") elseif seenN >= 2 and s > slowest then cand(7, 6, "long")
    elseif prev and tonumber(prev.seconds) and not prev.fromPct then
      local d = s - tonumber(prev.seconds)
      if math.abs(d) >= 600 and math.abs(d) >= tonumber(prev.seconds) * 0.2 then
        local dt = J.draw.duration(math.abs(d))
        M_(4, 6, d < 0 and "faster" or "slower", { d = dt, D = capital(dt) })
      end
    end
  end
  -- the clock: when it was played, and over how many days
  if timed >= 4 and night >= timed * 0.5 then M_(4, 6, "night")
  elseif timed >= 4 and morning >= timed * 0.5 then M_(4, 6, "morning") end
  if tFirst and tLast and not current then
    local days = math.floor(tLast / 86400) - math.floor(tFirst / 86400) + 1
    if days >= 3 then M_(3, 6, "manyDays", { n = say(days), N = capital(say(days)) })
    elseif days == 1 and #events >= 6 then M_(2, 6, "oneSitting") end
  end
  -- gold
  if rec and not current then
    local net = (tonumber(rec.goldIn) or 0) - (tonumber(rec.goldOut) or 0)
    if net >= 10000 then M_(4, 7, "richer", { m = money(net), M = capital(money(net)) })
    elseif net <= -10000 then M_(4, 7, "poorer", { m = money(net) }) end
  end
  -- company and the rest of life
  local seenPal, shown = {}, {}
  for _, who in ipairs(pals) do
    if not seenPal[who] then seenPal[who] = true; shown[#shown + 1] = who end
  end
  local extra = #shown - 3
  if extra > 1 then
    for i = #shown, 4, -1 do shown[i] = nil end
    shown[4] = say(extra) .. " others"
  end
  local p = names(shown)
  if p then cand(6, 7, #shown == 1 and "palsOne" or "pals", { p = p }) end
  if bondE then M_(5, 7, "bond", { who = bondE.who }) end
  if reunionE then M_(5, 7, "reunion", { who = reunionE.who }) end
  if n.rez > 0 then cand(6, 7, "rez") end
  if n.mount > 0 then cand(9, 7, "mount") end
  local function bare(t) return capital((tostring(t or ""):gsub("[%.!]+$", ""))) end
  if firstFind and firstFind.s then M_(6, 8, "firstFind", { S = bare(firstFind.s) }) end
  if n.upgrade >= 3 then M_(4, 8, "upgrades", { n = say(n.upgrade), N = capital(say(n.upgrade)) })
  elseif upgrade and upgrade.s then M_(4, 8, "upgrade", { S = bare(upgrade.s) }) end
  if home and home.s then M_(5, 8, "home", { S = bare(home.s) }) end
  if milestone and milestone.s then M_(4, 8, "milestone", { S = bare(milestone.s) }) end
  if n.abandon > 0 then M_(3, 8, "abandon", { q = count(n.abandon, "quest"), Q = capital(count(n.abandon, "quest")), qv = n.abandon == 1 and "was" or "were" }) end
  local g = {}
  local fish = 0
  local Wd = J.wilds
  if Wd then
    for _, w in ipairs({ { "mining", "vein" }, { "herbalism", "herb" }, { "skinning", "hide" } }) do
      local c = Wd.atLevel(w[1], l)
      if c > 0 then g[#g + 1] = count(c, w[2]) end
    end
    fish = Wd.atLevel("fishing", l)
  end
  if #g > 0 then cand(4, 8, "gather", { g = names(g) }) end
  if fish > 0 then cand(4, 8, "fish", { f = count(fish, "fish", "fish") }) end
  if n.craft > 0 then cand(3, 8, "craft") end
  if n.auction > 0 then cand(3, 8, "auction") end
  if n.camp > 0 then cand(4, 8, "camp") end
  if n.flight >= 2 then M_(3, 8, "flights", { N = capital(say(n.flight)) }) elseif n.flight > 0 then cand(3, 8, "flight") end
  -- choose: the opening (the land, or the mood on some chapters), then the five that matter most, told in order
  local out = {}
  local openWithMood = mood and (hashOf(seed .. "mood") % 3 == 0 or not place)
  if openWithMood then
    out[#out + 1] = voiced(M[mood], seed .. mood, {})
    if place then cand(9.5, 1, place[1], place[2]) end
  elseif place then
    out[#out + 1] = voiced(L[place[1]], seed .. place[1], place[2])
    if mood and hashOf(seed .. "mood2") % 2 == 0 then M_(3, 9, mood) end
  end
  table.sort(cands, function(a, b) return a.pri > b.pri end)
  local chosen = {}
  for i = 1, math.min(5, #cands) do chosen[i] = cands[i] end
  table.sort(chosen, function(a, b) if a.order ~= b.order then return a.order < b.order end return a.pri > b.pri end)
  for _, c in ipairs(chosen) do out[#out + 1] = c.text end
  -- a word about who you are, when the chapter shows it
  local top = Vo.traits(j)[1]
  local shows = top and ((top[1] == "gatherer" and #g > 0) or (top[1] == "angler" and fish > 0) or (top[1] == "friend" and p)
    or (top[1] == "lone" and not p) or (top[1] == "delver" and n.dungeon > 0) or (top[1] == "artisan" and n.craft > 0)
    or (top[1] == "unbroken" and deaths == 0) or (top[1] == "undaunted" and deaths > 0) or (top[1] == "wanderer" and #zones > 1)
    or (top[1] == "merchant" and n.auction > 0) or (top[1] == "warbound" and n.pvp > 0))
  local aside = shows and Vo.TRAITS[top[1]].aside
  -- the aside on about half the chapters, so it doesn't close every page the same way
  if aside and #aside > 0 and hashOf(seed .. "aside") % 2 == 0 then out[#out + 1] = pick(aside, seed .. "aside") end
  if current then out[#out + 1] = voiced(L.open, seed .. "open", {}) end
  return table.concat(out, " ")
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
  local full = "none"
  if type(UnitFullName) == "function" then
    local ok, a, b = pcall(UnitFullName, "player")
    full = ok and (show(a) .. "' / '" .. show(b)) or "error"
  end
  local top = Vo.traits()[1]
  return { "journey voice: " .. Vo.style() .. ", name '" .. show(first) .. "' + '" .. show(last or "-") .. "' from UnitName '"
    .. show(raw) .. "', UnitFullName '" .. full .. "', UnitPVPName '" .. show(pvp) .. "', NameUtil " .. tostring(C_NameUtil ~= nil)
    .. ", top trait " .. (top and (top[1] .. " " .. string.format("%.1f", top[2])) or "none") }
end
