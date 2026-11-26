-- JourneySocial.lua: the social side of the journal (after JourneyCompanions.lua).
--   journey.sighted[name] = { f, l, n, d, ld, c, r, lv, g, z, bgw, bgv, slain, wit }: players you saw nearby
--     (a nameplate, your target or the mouse), pencilled in. One sighting per S.SIGHT_GAP; d = days seen.
--     Forgotten after S.FORGET_DAYS unless they matter (S.matters). Only friendly players, and none new
--     while you rest in a town or inn (people already in the book still count there).
--   journey.trace[name] = { heat[map][cell] = n (5% cells), days[day] = n, nd, last }: where and when.
--   journey.people[name] (JourneyTales.lua's) gains whispers, witness, saved, killedMe, camp, toasts,
--     added (by hand), codex = { ep, day, moments, level, bond, at } (their Codex journal, by party sync).
--   journey.tags[name] = { Friend = true, ... } (S.TAGS); journey.diary[name] = { { t, s, l, z } } (dated
--     entries, S.DIARY_MAX); journey.forgotten[name] = t (removed by you: nothing records them again until
--     you add them back); journey.bonds[name] = rank (S.BONDS; the first run seeds without cards);
--     journey.fellowships[key] = { names, secs, first, last, days, ld, quests, bosses, runs, wipes, deaths,
--     levels, dungeons, formed, auto, named } (key = the sorted names of 2+ party members);
--     journey.portraits = { { t, k, w, z, l, c, who = { { n, c, l } } } }; journey.signatures[name] =
--     { { t, s, z } }; journey.anniv["name:days"] = t.
-- Codex to Codex (addon messages, prefix S.PREFIX, party or whisper): HI (your epithet, day, moments,
-- level and your bond with each of them), SQ (please sign), SG (a signature, only after you asked), TS
-- (a toast), LV (a level reached at your side). db.noJourneyShare turns it off; db.noSocialCards the
-- reunion, bond, fellowship, signature and anniversary cards. ASCII, our own wording, all pcall'd.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local function try(...) return Q.try(...) end

local S = {}
J.social = S

S.SIGHT_GAP = 600
S.FORGET_DAYS = 30
S.SEEN_MAX = 400
S.REUNION_GAP = 2 * 86400
S.MISS_DAYS = 10
S.CARD_GAP = 20
S.FORM_SECS = 1800
S.PORTRAITS_MAX = 60
S.DIARY_MAX = 12
S.DAYS_KEPT = 90
S.SIGN_MAX = 120
S.SIGN_WINDOW = 1800   -- a request stays open this long (seconds)
S.ACK_WAIT = 6         -- the other journal's "got it" should come within this
S.TRACE_DAYS = 120
S.PREFIX = "LevCodexJ"
S.TAGS = { "Friend", "Guildmate", "Healer", "Tank", "Rival" }
S.TAG_TIPS = { Friend = "Someone you'd travel with again.", Guildmate = "In your guild.", Healer = "The one who keeps you standing.",
  Tank = "The one who takes the hits.", Rival = "A thorn in your side, or a friendly race to 60." }
S.BONDS = { { "Stranger", 0 }, { "Acquaintance", 10 }, { "Ally", 60 }, { "Companion", 200 }, { "Sworn Friend", 600 } }
S.ANNIV = { { 30, "a month" }, { 100, "a hundred days" }, { 365, "a year" }, { 730, "two years" } }
-- moment kinds a fellowship counts, and the counter each adds to
S.GROUP_COUNTS = { quest = "quests", chain = "quests", elite = "quests", boss = "bosses", dungeon = "dungeons", run = "runs",
  wipe = "wipes", death = "deaths", level = "levels" }

J.ICON.whisper = "INV_Letter_01"
J.ICON.reunion = "Spell_Holy_PrayerOfFortitude"
J.ICON.bond = "Spell_Holy_HolyBolt"
J.ICON.fellowship = "INV_BannerPVP_02"
J.ICON.signed = "INV_Scroll_03"
J.ICON.toast = "INV_Drink_05"
J.ICON.cheer = "Ability_Warrior_BattleShout"
J.ICON.anniversary = "INV_Misc_Gift_01"
J.KEEP.bond, J.KEEP.fellowship, J.KEEP.signed, J.KEEP.anniversary = true, true, true, true

local function plain(s) return Q.plain(tostring(s or "")) end
local function now() return J.now() end
function S.countKeys(t) local c = 0; for _ in pairs(type(t) == "table" and t or {}) do c = c + 1 end; return c end
local function num(v)
  if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
  return tonumber(v)
end
local function n0(v) return tonumber(v) or 0 end
local function short(name)
  if type(name) ~= "string" then return nil end
  if type(issecretvalue) == "function" and issecretvalue(name) then return nil end
  name = name:match("^([^%-]+)") or name
  if name == "" or name == "Unknown" then return nil end
  return name
end
S.short = short
local function me() return short((try(UnitName, "player"))) or "" end
local function isMe(name) return name == me() or J.isMe(name) end
local function day(t) return math.floor((tonumber(t) or now()) / 86400) end
local function zone() local _, land = J.here(); return plain(land or J.zoneName() or "the wilds") end
local function fill(lines, seed, vars) return J.fill(J.pick(lines, seed), vars) end
local function Co_name(name) return J.companions and J.companions.nameText(name) or plain(name) end
S.nameText = Co_name
local function Co_party()
  local set = {}
  for _, p in ipairs(S.party()) do set[p.name] = p end
  return set
end
S.partySet = Co_party

local TABLES = { "sighted", "trace", "tags", "diary", "forgotten", "bonds", "fellowships", "portraits", "signatures", "anniv",
  "people", "pals", "fellows", "wrote" }
local function journal()
  local j = J.data()
  for _, k in ipairs(TABLES) do if type(j[k]) ~= "table" then j[k] = {} end end
  return j
end
S.journal = journal

-- The first name of a name ("Silfer Strife" -> "silfer"): Forever names carry a surname, and the game
-- gives some names with it and some without, so records are matched on the first name.
local function firstName(name)
  name = short(name)
  if not name then return nil end
  return (name:match("^([^%s%._|]+)") or name):lower()
end
S.firstName = firstName

-- Is this name you (with or without your surname)?
function J.isMe(name)
  local f = firstName(name)
  if not f then return false end
  if f == firstName((try(UnitName, "player"))) then return true end
  local mine = J.voice and J.voice.names and (J.voice.names())
  return mine ~= nil and f == firstName(mine)
end

function J.isForgotten(name)
  local f = J.data().forgotten
  name = short(name)
  if name == nil or type(f) ~= "table" then return false end
  if f[name] ~= nil then return true end
  local first = firstName(name)
  for k in pairs(f) do if firstName(k) == first then return true end end
  return false
end

-- A person record (JourneyTales' journey.people), made when missing.
local function person(name, field, n)
  name = short(name)
  if not name or isMe(name) or J.isForgotten(name) then return nil end
  local j = journal()
  local p = j.people[name]
  if type(p) ~= "table" then p = { met = now() }; j.people[name] = p end
  if field then p[field] = n0(p[field]) + (n or 1) end
  p.last = now()
  return p
end
S.person = person

----------------------------------------------------------------------------
-- Who matters, and the bond
----------------------------------------------------------------------------


function S.tagged(name, tag)
  local t = journal().tags[name]
  if type(t) ~= "table" then return false end
  if tag then return t[tag] == true end
  return next(t) ~= nil
end

function S.signatures(name)
  local s = journal().signatures[name]
  return type(s) == "table" and s or {}
end
-- The lines you wrote in their journal (newest first, 5 kept).
function S.wrote(name)
  local s = journal().wrote[name]
  return type(s) == "table" and s or {}
end

-- The bond's score: time together and everything you shared.
function S.score(name)
  local j = journal()
  local pal, f, p, s = j.pals[name], j.fellows[name], j.people[name], j.sighted[name]
  pal = type(pal) == "table" and pal or {}
  f = type(f) == "table" and f or {}
  p = type(p) == "table" and p or {}
  s = type(s) == "table" and s or {}
  local score = n0(pal.seconds) / 60 + n0(f.quests) * 2 + n0(f.bosses) * 5 + n0(f.runs) * 8 + n0(f.levels) * 3 + n0(f.close) * 4
    + n0(f.deaths) * 2 + n0(f.rares) * 3 + n0(f.bgs) * 3 + n0(p.rez) * 15 + n0(p.saved) * 10 + n0(p.trades) * 4 + n0(p.duels) * 3
    + n0(p.waves) * 2 + math.min(20, n0(p.whispers)) * 3 + n0(p.witness) + n0(p.camp) * 4 + n0(p.toasts) * 3
    + math.min(30, n0(s.d)) * 2 + #S.signatures(name) * 10
  if S.tagged(name, "Friend") then score = score + 30 end
  if S.tagged(name, "Guildmate") then score = score + 10 end
  return math.floor(score)
end

-- rank (1-5), its name, the score, the score the next rank needs (nil at the top).
function S.bond(name)
  local score = S.score(name)
  local rank = 1
  for i, b in ipairs(S.BONDS) do if score >= b[2] then rank = i end end
  local nxt = S.BONDS[rank + 1]
  return rank, S.BONDS[rank][1], score, nxt and nxt[2] or nil
end

function S.inBook(name)
  local j = journal()
  if not name or J.isForgotten(name) then return false end
  local pal = j.pals[name]
  if type(pal) == "table" and n0(pal.seconds) >= 300 then return true end
  if type(j.people[name]) == "table" then return true end
  if S.tagged(name) then return true end
  return n0(j.bonds[name]) >= 2
end

function S.matters(name)
  local j = journal()
  if type(j.pals[name]) == "table" or type(j.fellows[name]) == "table" or type(j.people[name]) == "table" then return true end
  if S.tagged(name) or (j.notes and j.notes[name]) or (type(j.diary[name]) == "table" and #j.diary[name] > 0) then return true end
  local s = j.sighted[name]
  if type(s) == "table" and (n0(s.d) >= 5 or n0(s.bgw) + n0(s.bgv) >= 2 or n0(s.slain) >= 2) then return true end
  return false
end

-- The last time you were near them, by any record.
function S.lastContact(name)
  local j = journal()
  local t = 0
  local function take(v) v = tonumber(v); if v and v > t then t = v end end
  if type(j.fellows[name]) == "table" then take(j.fellows[name].last) end
  if type(j.sighted[name]) == "table" then take(j.sighted[name].l) end
  if type(j.people[name]) == "table" then take(j.people[name].last); take(j.people[name].met) end
  if type(j.trace[name]) == "table" then take(j.trace[name].last) end
  if t == 0 and type(j.pals[name]) == "table" then take(j.pals[name].first) end
  return t > 0 and t or nil
end

-- When you first met them, by any record.
function S.firstMet(name)
  local j = journal()
  local t
  local function take(v) v = tonumber(v); if v and (not t or v < t) then t = v end end
  if type(j.pals[name]) == "table" then take(j.pals[name].first) end
  if type(j.fellows[name]) == "table" then take(j.fellows[name].met) end
  if type(j.people[name]) == "table" then take(j.people[name].met) end
  if type(j.sighted[name]) == "table" then take(j.sighted[name].f) end
  return t
end

----------------------------------------------------------------------------
-- Cards (one at a time, S.CARD_GAP apart, held in combat)
----------------------------------------------------------------------------
local cards, lastCard = {}, -1e9
function S.flushCards()
  if #cards == 0 then return end
  if try(InCombatLockdown) == true then return end
  local t = GetTime()
  if t - lastCard < S.CARD_GAP then
    if not S.cardWait then
      S.cardWait = true
      ns.after(S.CARD_GAP - (t - lastCard) + 0.1, function() S.cardWait = nil; S.flushCards() end)
    end
    return
  end
  local c = table.remove(cards, 1)
  lastCard = t
  ns.showCard(c[1], c[2], c[3], c[4], { tab = "journey" }, c[5])
  if #cards > 0 then S.flushCards() end
end
-- onClick replaces the default (their page in your journal); hint is the card's foot line; urgent puts
-- it at the front of the queue (someone is waiting on you).
function S.card(title, sub, rows, name, onClick, hint, urgent)
  if ns.db().noSocialCards then return end
  local open = function()
    if name and J.companions then J.companions.select(name) end
    if J.openPage then J.openPage("Companions") end
    ns.openTab("journey")
  end
  local c = { title, sub, rows, onClick or open, hint or "Click to open their page  -  right-click to dismiss" }
  if urgent then table.insert(cards, 1, c) else cards[#cards + 1] = c end
  if #cards > 4 then table.remove(cards) end
  -- someone is waiting: at most a few seconds after the card on screen, never the full gap
  if urgent then lastCard = math.min(lastCard, GetTime() - S.CARD_GAP + 3) end
  if urgent then ns.after(3.1, S.flushCards) end
  S.flushCards()
end
S.cardQueue = cards

----------------------------------------------------------------------------
-- Where and when (the heat map and the timeline)
----------------------------------------------------------------------------
function S.trace(name, w)
  if not name or J.isForgotten(name) then return end
  local j = journal()
  local tr = j.trace[name]
  if type(tr) ~= "table" then tr = {}; j.trace[name] = tr end
  if type(tr.heat) ~= "table" then tr.heat = {} end
  if type(tr.days) ~= "table" then tr.days = {}; tr.nd = 0 end
  w = w or 1
  local d = day()
  if not tr.days[d] then
    tr.nd = n0(tr.nd) + 1
    if tr.nd > S.TRACE_DAYS then
      local oldest
      for k in pairs(tr.days) do if not oldest or k < oldest then oldest = k end end
      if oldest then tr.days[oldest] = nil; tr.nd = tr.nd - 1 end
    end
  end
  tr.days[d] = n0(tr.days[d]) + w
  local _, _, map, x, y = J.here()
  x, y = num(x), num(y)
  if map and x and y and not J.inInstance() then
    local cell = math.floor(math.max(0, math.min(99.9, x)) / 5) * 20 + math.floor(math.max(0, math.min(99.9, y)) / 5)
    local h = tr.heat[map]
    if type(h) ~= "table" then h = {}; tr.heat[map] = h end
    h[cell] = n0(h[cell]) + w
  end
  tr.last = now()
end

-- The map you were together on most: map, cells, total.
function S.heat(name)
  local tr = journal().trace[name]
  if type(tr) ~= "table" or type(tr.heat) ~= "table" then return nil end
  local best, most, cells
  for map, h in pairs(tr.heat) do
    local n = 0
    for _, v in pairs(h) do n = n + n0(v) end
    if n > (most or 0) then best, most, cells = map, n, h end
  end
  return best, cells, most
end

----------------------------------------------------------------------------
-- Players nearby
----------------------------------------------------------------------------
local function unitInfo(unit)
  if try(UnitExists, unit) == false then return nil end
  if try(UnitIsPlayer, unit) ~= true then return nil end
  if try(UnitIsUnit, unit, "player") == true then return nil end
  local name = short((try(UnitName, unit)))
  if not name or isMe(name) then return nil end
  local function safe(v)
    if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
    return type(v) == "string" and v ~= "" and v or nil
  end
  local friend = try(UnitIsFriend, "player", unit)
  local _, class = try(UnitClass, unit)
  local _, race = try(UnitRace, unit)
  local guild = safe((try(GetGuildInfo, unit)))
  return { name = name, friend = friend == true or friend == 1, class = safe(class), race = safe(race), level = num((try(UnitLevel, unit))),
    guild = guild and plain(guild) or nil }
end
S.unitInfo = unitInfo

local function remember(s, info)
  s.c = type(info.class) == "string" and info.class or s.c
  s.r = type(info.race) == "string" and plain(info.race) or s.r
  s.lv = info.level or s.lv
  s.g = info.guild or s.g
end

local glance = {} -- name -> GetTime of the last look this session (a minute between)
local session = { reunited = {} }
S.session = session

function S.reunion(name, joined, gap)
  if session.reunited[name] then return end
  session.reunited[name] = true
  local days = math.max(2, math.floor(gap / 86400))
  local who = plain(name)
  local text
  if joined then
    text = fill({ "%who% joined you again in %zone%, %days% days since you last rode together",
      "Back in a party with %who% in %zone%, after %days% days apart" }, who .. now(), { who = who, zone = zone(), days = days })
  else
    text = fill({ "Crossed paths with %who% again in %zone%, %days% days on", "A familiar face in %zone%: %who%, %days% days since you last met" },
      who .. now(), { who = who, zone = zone(), days = days })
  end
  J.add("reunion", text, "Reunion", { who = name })
  local _, bondName = S.bond(name)
  local rows = { { J.ICON.reunion, joined and "Joined your party" or "Nearby", days .. " days since you last met" } }
  rows[#rows + 1] = { J.ICON.bond, "Your bond", bondName }
  local f = journal().fellows[name]
  if type(f) == "table" and n0(f.quests) > 0 then rows[#rows + 1] = { J.ICON.quest, "Together", n0(f.quests) .. " quests" } end
  S.card("A FAMILIAR FACE", Co_name(name) .. (joined and " is back in your party" or " is nearby"), rows, name)
end

-- A player you saw (a nameplate, your target, the mouse): pencil them in, or note a known face.
function S.sighted(info)
  if not info or not info.name or J.isForgotten(info.name) then return end
  local name = info.name
  local t = GetTime()
  if glance[name] and t - glance[name] < 60 then return end
  glance[name] = t
  local j = journal()
  local book = S.inBook(name)
  local s = j.sighted[name]
  if type(s) ~= "table" then
    if not info.friend then return end
    if try(IsResting) == true and not book then return end
    s = { f = now(), n = 0, d = 0 }
    j.sighted[name] = s
    S.prune()
  end
  remember(s, info)
  local last = S.lastContact(name)
  if now() - n0(s.l) >= S.SIGHT_GAP then
    s.n = n0(s.n) + 1
    local d = day()
    if s.ld ~= d then s.ld, s.d = d, n0(s.d) + 1 end
    s.z = zone()
    S.trace(name, 1)
    if book and last and now() - last >= S.REUNION_GAP and not Co_party()[name] then S.reunion(name, false, now() - last) end
  end
  s.l = now()
end


-- Party members now: { name, unit, class, level, race } (not in a raid; forgotten names left out).
function S.party()
  local out = {}
  if try(IsInRaid) == true then return out end
  local n = num(try(GetNumSubgroupMembers)) or 0
  for i = 1, math.min(4, n) do
    local unit = "party" .. i
    local name = short((try(UnitName, unit)))
    if name and not J.isForgotten(name) then
      local _, class = try(UnitClass, unit)
      local _, race = try(UnitRace, unit)
      out[#out + 1] = { name = name, unit = unit, class = class, race = race, level = num((try(UnitLevel, unit))) }
    end
  end
  return out
end

-- Friendly players near you now (nameplates), and the party when it's in sight.
function S.nearby()
  local out, seen = {}, {}
  for i = 1, 40 do
    local unit = "nameplate" .. i
    if try(UnitExists, unit) == true then
      local info = unitInfo(unit)
      if info and info.friend and not seen[info.name] and not J.isForgotten(info.name) then seen[info.name] = true; out[#out + 1] = info.name end
    end
  end
  for _, p in ipairs(S.party()) do
    if not seen[p.name] and try(UnitIsVisible, p.unit) ~= false then seen[p.name] = true; out[#out + 1] = p.name end
  end
  return out
end

-- Forget pencilled names after S.FORGET_DAYS unless they matter; keep the list under S.SEEN_MAX.
function S.prune(force)
  local tnow = GetTime()
  if not force and S.prunedAt and tnow - S.prunedAt < 60 then return end
  S.prunedAt = tnow
  local j = journal()
  local t, list = now(), {}
  for name, s in pairs(j.sighted) do
    if type(s) ~= "table" then j.sighted[name] = nil
    elseif not S.matters(name) then
      if t - n0(s.l or s.f) > S.FORGET_DAYS * 86400 then j.sighted[name], j.trace[name] = nil, nil
      else list[#list + 1] = { name, n0(s.d), n0(s.l) } end
    end
  end
  local count = 0
  for _ in pairs(j.sighted) do count = count + 1 end
  if count <= S.SEEN_MAX then return end
  table.sort(list, function(a, b) if a[2] ~= b[2] then return a[2] < b[2] end return a[3] < b[3] end)
  for i = 1, math.min(#list, count - S.SEEN_MAX) do j.sighted[list[i][1]], j.trace[list[i][1]] = nil, nil end
end

----------------------------------------------------------------------------
-- Bonds
----------------------------------------------------------------------------
local BOND_LINES = {
  [3] = { "%who% became an ally on the road in %zone%", "Somewhere in %zone%, %who% stopped being a stranger and became an ally" },
  [4] = { "%who% is a true companion now: the bond was sealed in %zone%", "In %zone% you realised %who% had become a companion" },
  [5] = { "%who% and you are sworn friends now. %zone% saw it happen", "Sworn friends: %who% has earned that name, and so have you" },
}
function S.seedBonds()
  local j = journal()
  if j.bondSeeded then return end
  local names = {}
  for _, k in ipairs({ "pals", "people", "fellows" }) do for name in pairs(j[k]) do names[name] = true end end
  for name in pairs(names) do j.bonds[name] = (S.bond(name)) end
  j.bondSeeded = true
end
function S.checkBond(name, quiet)
  name = short(name)
  if not name or J.isForgotten(name) then return end
  local j = journal()
  S.seedBonds()
  local rank, bondName = S.bond(name)
  local old = n0(j.bonds[name])
  if old == 0 then j.bonds[name] = rank; old = rank; if rank <= 2 then return end end
  if rank <= old then return end
  j.bonds[name] = rank
  if quiet or rank < 3 then return end
  local who = plain(name)
  J.add("bond", fill(BOND_LINES[rank], who .. rank, { who = who, zone = zone() }), "Bond: " .. bondName, { who = name })
  S.card("A BOND GROWS", Co_name(name) .. " is now your " .. bondName, {
    { J.ICON.bond, "Bond", bondName },
    { J.ICON.pal, "Together", J.draw and J.draw.duration(n0(type(j.pals[name]) == "table" and j.pals[name].seconds)) or "" } }, name)
end

----------------------------------------------------------------------------
-- Fellowships (the same 2+ party members with you)
----------------------------------------------------------------------------
local ADJ = { "Ashen", "Wandering", "Iron", "Silver", "Ember", "Patient", "Lucky", "Quiet", "Stormy", "Gilded", "Mossy", "Hollow",
  "Lantern", "Brave", "Long Road", "Copper" }
local NOUN = { "Company", "Wayfarers", "Oath", "Pact", "Band", "Circle", "Hearth", "Lanterns", "Banner", "Shields", "Compass", "Kettle" }
-- a pair (you and one other) gets a pair's name
local PAIR = { "Pair", "Twin Blades", "Two Lanterns", "Duo", "Partners", "Two Roads", "Matched Swords", "Kindred", "Twin Stars",
  "Shared Fire", "Two Shields", "Bookends" }
function S.autoName(key)
  local h = 0
  for i = 1, #key do h = (h * 31 + key:byte(i)) % 1000003 end
  local pair = not key:find(",", 1, true)
  local nouns = pair and PAIR or NOUN
  return "The " .. ADJ[h % #ADJ + 1] .. " " .. nouns[math.floor(h / #ADJ) % #nouns + 1]
end
-- The fellowship's key: the sorted names of the party with you (one name for a pair).
function S.groupKey(list)
  local names = {}
  for _, p in ipairs(list) do names[#names + 1] = type(p) == "table" and p.name or p end
  if #names < 1 then return nil end
  table.sort(names)
  return table.concat(names, ","), names
end
function S.fellowshipName(g, key) return plain(g.named or g.auto or S.autoName(key or "")) end

local function names(key)
  local out = {}
  for n in tostring(key):gmatch("[^,]+") do out[#out + 1] = n end
  return out
end
S.names = names
function S.listText(list)
  local out = {}
  for i, n in ipairs(list) do out[i] = Co_name(n) end
  if #out <= 1 then return out[1] or "" end
  return table.concat(out, ", ", 1, #out - 1) .. " and " .. out[#out]
end

local function groupTick(list)
  local key = S.groupKey(list)
  if not key then return end
  local j = journal()
  local g = j.fellowships[key]
  if type(g) ~= "table" then
    g = { first = now(), secs = 0, days = 0 }
    j.fellowships[key] = g
    local count, weakest, least = 0, nil, nil
    for k, r in pairs(j.fellowships) do
      count = count + 1
      if not r.formed and k ~= key and (not least or n0(r.secs) < least) then weakest, least = k, n0(r.secs) end
    end
    if count > 40 and weakest then j.fellowships[weakest] = nil end
  end
  g.secs, g.last = n0(g.secs) + 5, now()
  local d = day()
  if g.ld ~= d then
    g.ld, g.days = d, n0(g.days) + 1
    -- the days you were together, for its calendar (the last S.DAYS_KEPT)
    if type(g.dl) ~= "table" then g.dl = {} end
    g.dl[#g.dl + 1] = d
    while #g.dl > S.DAYS_KEPT do table.remove(g.dl, 1) end
  end
  -- the lands you walked together, by time
  local _, land = J.here()
  if land then
    if type(g.zones) ~= "table" then g.zones = {} end
    land = plain(land)
    if g.zones[land] or S.countKeys(g.zones) < 24 then g.zones[land] = n0(g.zones[land]) + 5 end
  end
  if not g.formed and (g.secs >= S.FORM_SECS or (n0(g.days) >= 2 and g.secs >= 600)) then
    g.formed = now()
    g.fz, g.fl = zone(), J.level()
    g.auto = g.auto or S.autoName(key)
    local list2 = names(key)
    local e = J.add("fellowship", fill({ "%who% and you rode together long enough to earn a name: %name%",
      "A fellowship was born in %zone%: %who% and you, now %name%" }, key, { who = S.listText(list2), name = g.auto, zone = zone() }),
      "Fellowship", nil)
    if type(e) == "table" then e.with = key end
    S.card("A FELLOWSHIP IS BORN", g.auto, { { J.ICON.fellowship, "With", S.listText(list2) },
      { J.ICON.pal, "Together", J.draw and J.draw.duration(g.secs) or "" } })
  end
end

function S.rename(key, text)
  local g = journal().fellowships[key]
  if type(g) ~= "table" then return false, "That fellowship is gone." end
  text = plain(text):gsub("[%c;]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  if text == "" then g.named = nil; return true end
  if #text < 3 or #text > 32 then return false, "A name takes 3 to 32 characters (this one has " .. #text .. ")." end
  g.named = text
  return true
end

-- Fellowships, the most time together first: { key, g, names }.
function S.fellowships(all)
  local out = {}
  for key, g in pairs(journal().fellowships) do
    if type(g) == "table" and (all or g.formed) then out[#out + 1] = { key = key, g = g, names = names(key) } end
  end
  table.sort(out, function(a, b) if n0(a.g.secs) ~= n0(b.g.secs) then return n0(a.g.secs) > n0(b.g.secs) end return a.key < b.key end)
  return out
end

----------------------------------------------------------------------------
-- Moments: who saw them, portraits, fellowships, campfires, battlegrounds
----------------------------------------------------------------------------
local function withSet(e)
  local set = {}
  if type(e.with) == "string" then for n in e.with:gmatch("[^,]+") do set[n] = true end end
  return set
end

local function portrait(e)
  local list = S.party()
  if #list == 0 then return end
  local j = journal()
  local _, class = try(UnitClass, "player")
  local who = {}
  for _, p in ipairs(list) do who[#who + 1] = { n = p.name, c = p.class, l = p.level } end
  local what = e.k == "level" and ("Level " .. (e.l or J.level() or "?")) or plain(e.d or e.s)
  table.insert(j.portraits, { t = e.t, k = e.k, w = what, z = zone(), l = J.level(), c = class, who = who })
  while #j.portraits > S.PORTRAITS_MAX do table.remove(j.portraits, 1) end
  e.pt = e.t
  if ns.db().journeyScreenshots and type(Screenshot) == "function" then
    ns.after(0.8, function() pcall(Screenshot) end)
  end
end

local function battleground(e)
  local n = num(try(GetNumBattlefieldScores)) or 0
  if n <= 0 then return end
  local mine = (select(1, try(UnitFactionGroup, "player"))) == "Horde" and 0 or 1
  local j, self = journal(), me()
  local done = 0
  for i = 1, math.min(80, n) do
    local name, faction, class
    local info = C_PvP and C_PvP.GetScoreInfo and try(C_PvP.GetScoreInfo, i)
    if type(info) == "table" then
      name, faction, class = info.name, info.faction, info.classToken
    else
      local r = { try(GetBattlefieldScore, i) }
      name, faction = r[1], r[6]
      for k = 7, #r do if type(r[k]) == "string" and r[k]:match("^%u+$") then class = r[k] end end
    end
    name = short(name)
    if name and name ~= self and not isMe(name) and not J.isForgotten(name) and done < 40 then
      done = done + 1
      local s = j.sighted[name]
      if type(s) ~= "table" then s = { f = now(), n = 0, d = 0 }; j.sighted[name] = s end
      s.l, s.c = now(), class or s.c
      if num(faction) == mine then s.bgw = n0(s.bgw) + 1 else s.bgv = n0(s.bgv) + 1 end
    end
  end
  S.prune()
end

local function campfire(e)
  local list = S.nearby()
  if #list == 0 then return end
  local partySet = Co_party()
  local j = journal()
  for _, name in ipairs(list) do
    if partySet[name] or S.inBook(name) then person(name, "camp")
    else
      local s = j.sighted[name]
      if type(s) == "table" then s.camp = n0(s.camp) + 1 end
    end
  end
  e.with = table.concat(list, ",")
end

local function moment(e)
  if type(e) ~= "table" then return end
  if e.k == "camp" then campfire(e) end
  if e.k == "bg" then battleground(e) end
  if (e.k == "level" or e.k == "boss") then portrait(e) end
  local set = withSet(e)
  local key = S.groupKey((function() local l = {}; for n in pairs(set) do l[#l + 1] = n end; return l end)())
  local field = S.GROUP_COUNTS[e.k]
  local g = key and journal().fellowships[key]
  if field and type(g) == "table" then g[field] = n0(g[field]) + 1 end
  for n in pairs(set) do S.checkBond(n) end
  if type(e.who) == "string" and e.k ~= "bond" and e.k ~= "reunion" then S.checkBond(e.who) end
end
do
  local add = J.add
  J.add = function(kind, text, detail, extra)
    local e = add(kind, text, detail, extra)
    if type(e) == "table" then
      local ok, err = pcall(moment, e)
      if not ok and not S.errored then S.errored = true; ns.say("journey social error: " .. plain(err)) end
    end
    return e
  end
end

----------------------------------------------------------------------------
-- Deaths: who saw it, who tried to save you, who killed you
----------------------------------------------------------------------------
local heals = {} -- name -> GetTime of their last healing cast
local HEAL_WORDS = { "heal", "renew", "rejuvenation", "regrowth", "holy light", "flash of light", "power word: shield", "lay on hands",
  "healing", "mending", "blessing of protection", "divine intervention", "swiftmend", "holy shock" }
local function secret(v) return type(issecretvalue) == "function" and issecretvalue(v) end
S.secret = secret
-- Forever hides other players' casts from addons: a secret spell ID or name counts as no spell.
function S.isHeal(spell)
  if secret(spell) then return false end
  spell = type(spell) == "string" and spell:lower() or ""
  for _, w in ipairs(HEAL_WORDS) do if spell:find(w, 1, true) then return true end end
  return false
end
local function partyCast(unit, _, spellID)
  if type(unit) ~= "string" or not unit:match("^party%d$") then return end
  if secret(spellID) then return end
  local name = short((try(UnitName, unit)))
  if not name then return end
  local spell = C_Spell and C_Spell.GetSpellName and try(C_Spell.GetSpellName, spellID)
  if secret(spell) then return end
  if not spell and GetSpellInfo then spell = try(GetSpellInfo, spellID) end
  if S.isHeal(spell) then heals[name] = GetTime() end
end

local function died()
  local j = journal()
  local e
  for i = #j.events, math.max(1, #j.events - 5), -1 do
    local x = j.events[i]
    if x.k == "death" and now() - n0(x.t) <= 3 then e = x; break end
  end
  local saw = S.nearby()
  local partySet = Co_party()
  local tried = {}
  for _, name in ipairs(saw) do
    if partySet[name] or S.inBook(name) then person(name, "witness")
    else
      local s = j.sighted[name]
      if type(s) == "table" then s.wit = n0(s.wit) + 1 end
    end
    if heals[name] and GetTime() - heals[name] <= 8 then tried[#tried + 1] = name; person(name, "saved") end
  end
  if e then
    if #saw > 0 then e.saw = table.concat(saw, ",") end
    if #tried > 0 then
      e.tried = table.concat(tried, ",")
      e.d = (e.d and (e.d .. "  -  ") or "") .. S.listText(tried) .. " tried to save you"
    end
    if e.pvp and type(e.who) == "string" then
      local p = person(e.who, "killedMe")
      local s = j.sighted[e.who]
      if p and type(s) ~= "table" then j.sighted[e.who] = { f = now(), l = now(), n = 1, d = 1, ld = day() } end
    end
  end
  heals = {}
end

local function honorKill(text)
  if J.inInstance() then return end
  local read = J.tales and J.tales.read
  local a = read and read(text, "COMBATLOG_HONORGAIN", "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)")
  local victim = short(a and a[1] or (type(text) == "string" and text:match("^(.-) dies")))
  if not victim or J.isForgotten(victim) then return end
  local j = journal()
  local s = j.sighted[victim]
  if type(s) ~= "table" then s = { f = now(), n = 0, d = 0 }; j.sighted[victim] = s end
  s.l, s.slain = now(), n0(s.slain) + 1
end

----------------------------------------------------------------------------
-- Whispers: a conversation counts once both of you spoke (spam gets no reply)
----------------------------------------------------------------------------
local talk = {}
function S.whisper(sender, incoming, flag)
  if flag == "GM" or flag == "DEV" then return end
  local name = short(sender)
  if not name or isMe(name) or J.isForgotten(name) then return end
  local t = now()
  local w = talk[name] or {}
  talk[name] = w
  if incoming then w.inAt = t else w.outAt = t end
  if not (w.inAt and w.outAt) or math.abs(w.inAt - w.outAt) > 600 then return end
  if w.counted and t - w.counted < 1800 then return end
  w.counted = t
  local p = person(name, "whispers")
  if not p then return end
  S.trace(name, 1)
  if p.whispers == 1 then
    local who = plain(name)
    J.add("whisper", fill({ "Traded your first whispered words with %who% in %zone%", "%who% and you spoke for the first time, in whispers, in %zone%" },
      who, { who = who, zone = zone() }), "Whispers", { who = name })
  else
    S.checkBond(name)
  end
end

----------------------------------------------------------------------------
-- Adding, tagging, notes and forgetting
----------------------------------------------------------------------------
function S.add(name, unit)
  name = short(name)
  if name then name = name:gsub("^%s+", ""):gsub("%s+$", "") end
  if not name or name == "" then return false, "Give a name, or target a player." end
  if not name:match("^[^%d%p%s][^%d%s]*$") or #name > 24 then return false, "\"" .. plain(name) .. "\" isn't a character name." end
  name = name:sub(1, 1):upper() .. name:sub(2)
  if isMe(name) then return false, "That's you." end
  local j = journal()
  j.forgotten[name] = nil
  local p = person(name)
  p.added = p.added or now()
  local info = unit and unitInfo(unit)
  if info then
    local s = j.sighted[name]
    if type(s) ~= "table" then s = { f = now(), n = 1, d = 1, ld = day(), l = now() }; j.sighted[name] = s end
    remember(s, info)
    S.trace(name, 1)
  end
  if J.companions then J.companions.select(name) end
  ns.say(Co_name(name) .. " is in your journey now: Journey > Companions has their page, tags and notes.")
  if ns.refreshTab then ns.refreshTab("journey") end
  return true
end

function S.addTarget()
  local info = unitInfo("target")
  if not info then ns.say("Target a player to add them to your journey."); return false end
  return S.add(info.name, "target")
end

function S.toggleTag(name, tag)
  local j = journal()
  local t = j.tags[name]
  if type(t) ~= "table" then t = {}; j.tags[name] = t end
  t[tag] = not t[tag] or nil
  if not next(t) then j.tags[name] = nil end
  if t[tag] then person(name); S.checkBond(name) end
end
function S.tagList(name)
  local out = {}
  for _, tag in ipairs(S.TAGS) do if S.tagged(name, tag) then out[#out + 1] = tag end end
  return out
end

function S.diary(name)
  local d = journal().diary[name]
  return type(d) == "table" and d or {}
end
function S.addEntry(name, text)
  text = plain(text):gsub("[%c]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  if text == "" then return false, "Write a few words first." end
  if #text > 200 then return false, "An entry holds up to 200 characters (this one has " .. #text .. ")." end
  local j = journal()
  local d = j.diary[name]
  if type(d) ~= "table" then d = {}; j.diary[name] = d end
  table.insert(d, 1, { t = now(), s = text, l = J.level(), z = zone() })
  while #d > S.DIARY_MAX do table.remove(d) end
  person(name)
  return true
end
function S.removeEntry(name, i)
  local d = journal().diary[name]
  if type(d) == "table" and d[i] then table.remove(d, i) end
  if type(d) == "table" and #d == 0 then journal().diary[name] = nil end
end

-- Take someone out of the journal: their records, notes, tags and the moments that name them.
-- Every record of a name (and of the same first name: a surname the game sometimes gives), so nothing
-- the book shows still names them. Also used at login to clear what slipped in (you, or someone you removed).
local function scrub(j, match, removeMoments)
  for _, k in ipairs({ "pals", "fellows", "people", "sighted", "trace", "tags", "diary", "bonds", "signatures", "wrote", "notes" }) do
    if type(j[k]) == "table" then
      for n in pairs(j[k]) do if match(n) then j[k][n] = nil end end
    end
  end
  for key in pairs(j.fellowships) do
    for n in key:gmatch("[^,]+") do if match(n) then j.fellowships[key] = nil; break end end
  end
  for k in pairs(j.anniv) do if match(k:match("^(.-):") or k) then j.anniv[k] = nil end end
  local function strip(list)
    if type(list) ~= "string" then return list end
    local keep = {}
    for n in list:gmatch("[^,]+") do if not match(n) then keep[#keep + 1] = n end end
    return #keep > 0 and table.concat(keep, ",") or nil
  end
  local events = j.events
  for i = #events, 1, -1 do
    local e = events[i]
    if type(e) == "table" then
      if removeMoments and type(e.who) == "string" and match(e.who) and e.k ~= "death" and e.k ~= "pvp" then table.remove(events, i)
      else e.with, e.saw, e.tried = strip(e.with), strip(e.saw), strip(e.tried) end
    end
  end
  for _, p in ipairs(j.portraits) do
    for i = #(p.who or {}), 1, -1 do if match(p.who[i].n) then table.remove(p.who, i) end end
  end
end
S.scrub = scrub

-- At login: you never appear as someone you met, and a removed name (any form of it) stays removed.
function S.tidy()
  local j = journal()
  local gone = {}
  for k in pairs(j.forgotten) do local f = firstName(k); if f then gone[f] = true end end
  scrub(j, function(n) return J.isMe(n) or gone[firstName(n) or ""] == true end, false)
end

function S.forget(name)
  name = short(name)
  if not name then return end
  local j = journal()
  local first = firstName(name)
  scrub(j, function(n) return firstName(n) == first end, true)
  j.forgotten[name] = now()
  J.version = (J.version or 0) + 1
  if J.companions and J.companions.chosen() == name then J.companions.select(nil) end
end

----------------------------------------------------------------------------
-- Anniversaries and faces you miss
----------------------------------------------------------------------------
function S.anniversaries()
  local j = journal()
  local out = {}
  for name in pairs(j.pals) do out[name] = true end
  for name in pairs(j.people) do out[name] = true end
  for name in pairs(out) do
    local met = S.firstMet(name)
    local rank = S.bond(name)
    if met and rank >= 2 and not J.isForgotten(name) then
      local days = math.floor((now() - met) / 86400)
      for _, m in ipairs(S.ANNIV) do
        local key = name .. ":" .. m[1]
        if days >= m[1] and days - m[1] <= 3 and not j.anniv[key] then
          j.anniv[key] = now()
          local who = plain(name)
          local line = fill({ "It has been %span% since you first met %who%", "%span% ago today, %who% walked into your story" },
            key, { span = m[2], who = who })
          J.add("anniversary", (line:gsub("^%l", string.upper)), "Anniversary", { who = name })
          local _, bondName = S.bond(name)
          S.card("AN ANNIVERSARY", (m[2]:gsub("^%l", string.upper)) .. " since you met " .. Co_name(name),
            { { J.ICON.anniversary, "Met", "day " .. (J.draw and J.draw.dayOf(j, met) or "?") }, { J.ICON.bond, "Bond", bondName } }, name)
        end
      end
    end
  end
end

-- Allies and closer you haven't seen in S.MISS_DAYS: { { name, days, rank } }, closest bond first.
function S.missed()
  local j = journal()
  local out, seenName = {}, {}
  for _, k in ipairs({ "pals", "people" }) do
    for name in pairs(j[k]) do
      if not seenName[name] and not J.isForgotten(name) then
        seenName[name] = true
        local rank = S.bond(name)
        local last = S.lastContact(name)
        if rank >= 3 and last and now() - last >= S.MISS_DAYS * 86400 then
          out[#out + 1] = { name = name, days = math.floor((now() - last) / 86400), rank = rank }
        end
      end
    end
  end
  table.sort(out, function(a, b) if a.rank ~= b.rank then return a.rank > b.rank end return a.days < b.days end)
  return out
end
function S.missedLine(m) return "You haven't seen " .. Co_name(m.name) .. " in " .. m.days .. " days." end

----------------------------------------------------------------------------
-- Awards across your companions
----------------------------------------------------------------------------
S.AWARDS = {
  { "Road companion", "The most time together", "pal", function(j, n) return type(j.pals[n]) == "table" and n0(j.pals[n].seconds) or 0 end, "time",
    flavour = "The one whose footsteps you know best." },
  { "Guardian angel", "Raised you or tried to save you the most", "rez", function(j, n) local p = j.people[n] or {}; return n0(p.rez) + n0(p.saved) end,
    unit = { "rescue", "rescues" }, flavour = "Somebody has to keep you breathing." },
  { "Shield wall", "The most bosses brought down together", "boss", function(j, n) return n0((j.fellows[n] or {}).bosses) end,
    unit = { "boss", "bosses" }, flavour = "Stood beside you when the big ones came." },
  { "Errand partner", "The most quests turned in together", "quest", function(j, n) return n0((j.fellows[n] or {}).quests) end,
    unit = { "quest", "quests" }, flavour = "Every notice board, every reward, split down the middle." },
  { "Pen pal", "The most whispered conversations", "whisper", function(j, n) return n0((j.people[n] or {}).whispers) end,
    unit = { "talk", "talks" }, flavour = "Words across the world, one whisper at a time." },
  { "Trusted trader", "The most trades", "trade", function(j, n) return n0((j.people[n] or {}).trades) end,
    unit = { "trade", "trades" }, flavour = "Fair deals, and the odd gift." },
  { "Sparring partner", "The most duels", "duel", function(j, n) return n0((j.people[n] or {}).duels) end,
    unit = { "duel", "duels" }, flavour = "Iron sharpens iron." },
  { "Fellow sufferer", "Saw you fall or wipe the most", "death", function(j, n) local f = j.fellows[n] or {}; return n0(f.deaths) + n0(f.wipes) + n0((j.people[n] or {}).witness) end,
    unit = { "bad moment", "bad moments" }, flavour = "Was there for the worst of it, and stayed." },
  { "Familiar face", "Seen on the road on the most days", "reunion", function(j, n) return n0((j.sighted[n] or {}).d) end,
    unit = { "day seen", "days seen" }, flavour = "Always somewhere on the same road." },
  { "Globetrotter", "The most lands walked together", "zone", function(j, n) local c = 0; for _ in pairs((j.fellows[n] or {}).zones or {}) do c = c + 1 end; return c end,
    unit = { "land together", "lands together" }, flavour = "Map after map, side by side." },
  { "Campfire friend", "Shared the most campfires", "camp", function(j, n) return n0((j.people[n] or {}).camp) end,
    unit = { "fire", "fires" }, flavour = "Good stories need a fire and someone to hear them." },
  { "Nemesis", "Killed you the most", "pvp", function(j, n) return n0((j.people[n] or {}).killedMe) end,
    unit = { "kill", "kills" }, flavour = "Every story needs a villain." },
}
local function awardText(a, most)
  if a[5] == "time" then return J.draw and J.draw.duration(most) or tostring(most) end
  local u = a.unit or { "", "" }
  return most .. " " .. (most == 1 and u[1] or u[2])
end
-- Every award: { title, tip, flavour, icon, name, value, text, won }, won ones first in S.AWARDS order.
function S.awardCabinet()
  local j = journal()
  local everyone = {}
  for _, k in ipairs({ "pals", "people", "fellows", "sighted" }) do for name in pairs(j[k]) do everyone[name] = true end end
  local won, open = {}, {}
  for _, a in ipairs(S.AWARDS) do
    local best, most = nil, 0
    for name in pairs(everyone) do
      if not J.isForgotten(name) and not J.isMe(name) then
        local v = a[4](j, name)
        if v > most or (v == most and v > 0 and best and name < best) then best, most = name, v end
      end
    end
    local min = a[5] == "time" and 600 or 1
    local r = { title = a[1], tip = a[2], flavour = a.flavour, icon = J.ICON[a[3]] or J.ICON.pal }
    if best and most >= min then
      r.name, r.value, r.text, r.won = best, most, awardText(a, most), true
      won[#won + 1] = r
    else open[#open + 1] = r end
  end
  return won, open
end
-- { { title, tip, icon, name, value, text } } for the awards someone has won.
function S.awards()
  local won = S.awardCabinet()
  return won
end

----------------------------------------------------------------------------
-- Codex to Codex: titles, signatures, toasts, cheers
----------------------------------------------------------------------------
local asked, requests, toasted, gotToast, hiTo, cheered = {}, {}, {}, {}, {}, {}
S.asked, S.requests = asked, requests

local function sharing() return not ns.db().noJourneyShare end
function S.sharing() return sharing() end

local function send(msg, to)
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return false end
  msg = msg:sub(1, 250)
  local channel = "PARTY"
  if to and not Co_party()[to] then channel = "WHISPER" end
  if channel == "PARTY" and try(IsInGroup) ~= true then return false end
  local ok = pcall(C_ChatInfo.SendAddonMessage, S.PREFIX, msg, channel, channel == "WHISPER" and to or nil)
  return ok
end
S.send = send

-- Can a message reach them now (in your party, or your target)?
function S.reachable(name)
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) or not sharing() then return false end
  if Co_party()[name] then return true end
  local info = unitInfo("target")
  return info ~= nil and info.name == name and info.friend
end

function S.sayHi()
  if not sharing() then return end
  local list = S.party()
  if #list == 0 then return end
  local j = journal()
  local ep = J.voice and J.voice.epithet and J.voice.epithet(j) or ""
  local pairs_ = {}
  for _, p in ipairs(list) do
    hiTo[p.name] = true
    local rank = S.bond(p.name)
    local met = S.firstMet(p.name)
    pairs_[#pairs_ + 1] = p.name .. "=" .. rank .. ":" .. (met and J.draw and J.draw.dayOf(j, met) or 0)
  end
  local days = J.draw and J.draw.dayOf(j, now()) or 1
  send(table.concat({ "HI", "1", plain(ep or ""):gsub(";", ""), days, #j.events, J.level() or 0, table.concat(pairs_, ",") }, ";"))
end

-- Every request waits for the other Codex to say it arrived (QA / GA / TA): without that answer in
-- S.ACK_WAIT seconds you hear why it may not have landed.
local acks = {}
S.acks = acks
local function expectAck(key, name, onMissing)
  acks[key] = GetTime()
  ns.after(S.ACK_WAIT, function()
    if acks[key] then
      acks[key] = nil
      onMissing()
      if ns.ui and ns.ui.refresh then pcall(ns.ui.refresh) end
    end
  end)
end
local function gotAck(key)
  if not acks[key] then return false end
  acks[key] = nil
  return true
end

-- Where a request stands, for their page: "waiting", "seen" (their Codex has it), nil.
function S.signState(name)
  local a = asked[name]
  if not a or GetTime() - a.at > S.SIGN_WINDOW then return nil end
  return a.seen and "seen" or "waiting", a
end
function S.pendingRequest(name)
  local r = requests[name]
  return r and GetTime() - r < S.SIGN_WINDOW
end

function S.askSign(name)
  if not S.reachable(name) then ns.say("Group up with " .. Co_name(name) .. " or target them to ask."); return false end
  local a = asked[name]
  if a and not a.seen and GetTime() - a.at < S.ACK_WAIT then return false end
  if not send("SQ;" .. name, name) then ns.say("Couldn't reach " .. Co_name(name) .. " right now."); return false end
  asked[name] = { at = GetTime() }
  ns.say("Asked " .. Co_name(name) .. " to sign your journal...")
  expectAck("QA:" .. name, name, function()
    if asked[name] and not asked[name].seen then
      ns.say(Co_name(name) .. "'s journal didn't answer: they need the Leveling Codex with journal sharing on, and to be in your party or targeted.")
    end
  end)
  return true
end

function S.toast(name)
  if not S.reachable(name) then ns.say("Group up with " .. Co_name(name) .. " or target them to raise a toast."); return false end
  if toasted[name] and GetTime() - toasted[name] < 600 then ns.say("You raised a toast to " .. Co_name(name) .. " a moment ago."); return false end
  if not send("TS;" .. name, name) then ns.say("Couldn't reach " .. Co_name(name) .. " right now."); return false end
  toasted[name] = GetTime()
  local who = plain(name)
  person(name, "toastsGiven")
  J.add("toast", fill({ "Raised a toast to %who% in %zone%", "Lifted a mug to %who% in %zone%", "Drank to %who%'s health in %zone%" },
    who .. now(), { who = who, zone = zone() }), "A toast given", { who = name })
  ns.say("You raised a toast to " .. Co_name(name) .. "...")
  expectAck("TA:" .. name, name, function()
    ns.say("No answer from " .. Co_name(name) .. "'s journal: the toast is in yours, but theirs may not have it (they need the Leveling Codex).")
  end)
  return true
end

-- A line for the one who asks you to sign, from what you shared with them.
function S.suggestLine(name)
  local j = journal()
  local f = type(j.fellows[name]) == "table" and j.fellows[name] or {}
  local p = type(j.people[name]) == "table" and j.people[name] or {}
  if n0(f.bosses) > 0 then return n0(f.bosses) .. " bosses down together. Proud to have stood beside you." end
  if n0(p.rez) > 0 then return "I picked you up off the floor once. I'd do it again." end
  if n0(f.quests) > 0 then return n0(f.quests) .. " quests side by side. See you on the road!" end
  if n0(f.deaths) > 0 then return "We fell together and got back up. Good luck out there." end
  return "Good luck on the road, friend. Save me a seat by the fire."
end

function S.openSign(name)
  name = name or S.lastRequest
  if not name or not requests[name] then ns.say("Nobody has asked you to sign their journal lately."); return end
  if GetTime() - requests[name] > S.SIGN_WINDOW then
    requests[name] = nil
    ns.say(Co_name(name) .. " asked a while ago: ask them to send the request again.")
    return
  end
  ns.showMacroCopy({ copyTitle = "Sign " .. Co_name(name) .. "'s journal", body = S.suggestLine(name), paste = true, acceptLabel = "Sign it",
    help = Co_name(name) .. " asked you to write in their journal. Change the line below if you like (up to " .. S.SIGN_MAX
      .. " characters), then click Sign it.",
    onAccept = function(text)
      text = plain(text):gsub("[%c]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
      if text == "" then return false, "Write a line first." end
      if #text > S.SIGN_MAX then return false, "A signature holds up to " .. S.SIGN_MAX .. " characters (this one has " .. #text .. ")." end
      if not send("SG;" .. name .. ";" .. text, name) then return false, "Couldn't reach " .. Co_name(name) .. " right now." end
      requests[name] = nil
      local j = journal()
      person(name, "signedFor")
      local list = j.wrote[name]
      if type(list) ~= "table" then list = {}; j.wrote[name] = list end
      table.insert(list, 1, { t = now(), s = text, z = zone() })
      while #list > 5 do table.remove(list) end
      local who = plain(name)
      J.add("signed", "Signed " .. who .. "'s journal in " .. zone() .. ": \"" .. text .. "\"", "Signature given", { who = name })
      ns.say("You signed " .. Co_name(name) .. "'s journal...")
      expectAck("GA:" .. name, name, function()
        ns.say("No answer from " .. Co_name(name) .. "'s journal yet: your line may not have reached them.")
      end)
      S.checkBond(name)
      if ns.ui and ns.ui.refresh then pcall(ns.ui.refresh) end
      return true
    end })
end

local HANDLE = {}
function HANDLE.HI(from, f)
  local p = person(from)
  if not p then return end
  local mine = me()
  local bond, metDay
  for pair in tostring(f[7] or ""):gmatch("[^,]+") do
    local n, r, d = pair:match("^(.-)=(%d+):(%d+)$")
    if n == mine then bond, metDay = tonumber(r), tonumber(d) end
  end
  p.codex = { ep = plain(f[3] or ""), day = tonumber(f[4]), moments = tonumber(f[5]), level = tonumber(f[6]), bond = bond, met = metDay, at = now() }
  if not hiTo[from] and Co_party()[from] then S.sayHi() end
end
function HANDLE.SQ(from, f)
  if f[2] ~= me() then return end
  send("QA;" .. from, from)
  local again = requests[from] and GetTime() - requests[from] < 60
  requests[from] = GetTime()
  S.lastRequest = from
  if again then return end
  ns.say(Co_name(from) .. " asks you to sign their journal: click the card, or type /codex sign.")
  S.card(Co_name(from):upper() .. " ASKS FOR A LINE", "Sign their journal: they'll keep what you write", {
    { J.ICON.signed, "Suggested", S.suggestLine(from) },
    { J.ICON.pal, "Or later", "/codex sign" },
  }, from, function() S.openSign(from) end, "Click to write your line  -  right-click to dismiss", true)
  if ns.ui and ns.ui.refresh then pcall(ns.ui.refresh) end
end
-- The other Codex has the request / your line / your toast.
function HANDLE.QA(from, f)
  if f[2] ~= me() or not gotAck("QA:" .. from) then return end
  if asked[from] then asked[from].seen = true end
  ns.say(Co_name(from) .. " got your request: their line lands here once they write it.")
  if ns.ui and ns.ui.refresh then pcall(ns.ui.refresh) end
end
function HANDLE.GA(from, f)
  if f[2] ~= me() or not gotAck("GA:" .. from) then return end
  ns.say(Co_name(from) .. " has your line in their journal.")
  S.card("YOUR LINE ARRIVED", Co_name(from) .. " keeps it in their journal", { { J.ICON.signed, "Signed", "Day " .. (J.draw and J.draw.dayOf(journal(), now()) or 1) } }, from)
end
function HANDLE.TA(from, f)
  if f[2] ~= me() or not gotAck("TA:" .. from) then return end
  ns.say(Co_name(from) .. " got your toast.")
  S.card("TOAST RECEIVED", Co_name(from) .. " drank to that", { { J.ICON.toast, "Where", zone() } }, from)
end
function HANDLE.SG(from, f, raw)
  if f[2] ~= me() then return end
  if not asked[from] or GetTime() - asked[from].at > S.SIGN_WINDOW then return end
  asked[from] = nil
  send("GA;" .. from, from)
  local text = plain(raw:match("^SG;[^;]*;(.*)$") or ""):sub(1, S.SIGN_MAX)
  if text == "" then return end
  local j = journal()
  person(from)
  local list = j.signatures[from]
  if type(list) ~= "table" then list = {}; j.signatures[from] = list end
  table.insert(list, 1, { t = now(), s = text, z = zone() })
  while #list > 5 do table.remove(list) end
  local who = plain(from)
  J.add("signed", who .. " signed your journal in " .. zone() .. ": \"" .. text .. "\"", "Signature", { who = from })
  S.card("YOUR JOURNAL IS SIGNED", Co_name(from) .. " wrote a line", { { J.ICON.signed, "", text } }, from)
  S.checkBond(from)
end
function HANDLE.TS(from, f)
  if f[2] ~= me() then return end
  send("TA;" .. from, from)
  if gotToast[from] and GetTime() - gotToast[from] < 3600 then return end
  gotToast[from] = GetTime()
  if not person(from, "toasts") then return end
  local who = plain(from)
  J.add("toast", fill({ "%who% raised a toast to you in %zone%", "In %zone%, %who% lifted a mug in your name",
    "%who% drank to your health in %zone%" }, who .. now(), { who = who, zone = zone() }), "A toast", { who = from })
  local back = toasted[from] and GetTime() - toasted[from] < 600
  S.card("A TOAST", Co_name(from) .. " raised a toast to you", { { J.ICON.toast, "Where", zone() } }, from,
    not back and function() if not S.toast(from) then
      if J.companions then J.companions.select(from) end
      if J.openPage then J.openPage("Companions") end
      ns.openTab("journey")
    end end or nil,
    not back and "Click to toast them back  -  right-click to dismiss" or nil)
end
function HANDLE.LV(from, f)
  local lvl = tonumber(f[2])
  if not lvl or not Co_party()[from] then return end
  local key = from .. ":" .. lvl
  if cheered[key] then return end
  cheered[key] = true
  local who = plain(from)
  J.add("cheer", fill({ "%who% reached level %n% at your side in %zone%", "Cheered as %who% hit level %n% in %zone%" }, key,
    { who = who, n = lvl, zone = zone() }), "Level " .. lvl, { who = from })
end

local function addonMessage(prefix, text, channel, sender)
  if prefix ~= S.PREFIX or type(text) ~= "string" or not sharing() then return end
  local from = short(sender)
  if not from or from == me() or J.isForgotten(from) then return end
  local f = {}
  for part in (text .. ";"):gmatch("([^;]*);") do f[#f + 1] = part end
  local h = HANDLE[f[1]]
  if h then h(from, f, text) end
end

----------------------------------------------------------------------------
-- The roster and the tick
----------------------------------------------------------------------------
local roster = {}
local function rosterChanged()
  local now_ = {}
  local fresh = false
  for _, p in ipairs(S.party()) do
    now_[p.name] = true
    if not roster[p.name] then
      fresh = true
      hiTo[p.name] = nil
      local j = journal()
      local s = j.sighted[p.name]
      if type(s) ~= "table" then s = { f = now(), n = 0, d = 0 }; j.sighted[p.name] = s end
      remember(s, { class = p.class, race = p.race, level = p.level })
      local last = S.lastContact(p.name)
      if S.inBook(p.name) and last and now() - last >= S.REUNION_GAP then S.reunion(p.name, true, now() - last) end
      s.l = now()
    end
  end
  roster = now_
  if fresh then
    if S.hiTimer then return end
    S.hiTimer = true
    ns.after(4, function() S.hiTimer = nil; S.sayHi() end)
  end
end

local function tick()
  local list = S.party()
  for _, p in ipairs(list) do S.trace(p.name, 1); S.checkBond(p.name) end
  groupTick(list)
  S.flushCards()
end

local HANDLERS = {
  NAME_PLATE_UNIT_ADDED = function(unit) S.sighted(unitInfo(unit)) end,
  PLAYER_TARGET_CHANGED = function() S.sighted(unitInfo("target")) end,
  UPDATE_MOUSEOVER_UNIT = function() S.sighted(unitInfo("mouseover")) end,
  GROUP_ROSTER_UPDATE = rosterChanged,
  CHAT_MSG_WHISPER = function(_, sender, _, _, _, flag) S.whisper(sender, true, flag) end,
  CHAT_MSG_WHISPER_INFORM = function(_, target) S.whisper(target, false) end,
  CHAT_MSG_ADDON = addonMessage,
  PLAYER_DEAD = function() ns.after(0.3, function() pcall(died) end) end,
  CHAT_MSG_COMBAT_HONOR_GAIN = honorKill,
  PLAYER_REGEN_ENABLED = function() S.flushCards() end,
  PLAYER_LEVEL_UP = function(lvl) if sharing() and #S.party() > 0 then send("LV;" .. tostring(lvl)) end end,
  UNIT_SPELLCAST_SUCCEEDED = partyCast,
}

local frame
function ns.startJourneySocial()
  if frame then return end
  journal()
  pcall(S.tidy)
  S.seedBonds()
  pcall(S.prune, true)
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, S.PREFIX) end
  frame = CreateFrame("Frame")
  for event in pairs(HANDLERS) do
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
      if frame.RegisterUnitEvent then
        pcall(frame.RegisterUnitEvent, frame, event, "party1", "party2")
        S.castFrame = CreateFrame("Frame")
        pcall(S.castFrame.RegisterUnitEvent, S.castFrame, event, "party3", "party4")
        S.castFrame:SetScript("OnEvent", function(_, _, ...) pcall(partyCast, ...) end)
      end
    else
      pcall(frame.RegisterEvent, frame, event)
    end
  end
  frame:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(HANDLERS[event], ...)
    if not ok and not S.errored then S.errored = true; ns.say("journey social error: " .. plain(err)) end
  end)
  for _, p in ipairs(S.party()) do roster[p.name] = true end
  ns.every(5, function()
    local ok, err = pcall(tick)
    if not ok and not S.errored then S.errored = true; ns.say("journey social error: " .. plain(err)) end
  end)
  ns.after(20, function() pcall(S.anniversaries) end)
  -- the key binding's button (CLICK LevelingCodexJourneyAdd:LeftButton)
  local b = CreateFrame("Button", "LevelingCodexJourneyAdd", UIParent)
  b:Hide()
  b:SetScript("OnClick", function() S.addTarget() end)
  -- the unit menus (right-click a player, a party frame or a name in chat)
  if Menu and Menu.ModifyMenu then
    for _, tag in ipairs({ "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_FRIEND", "MENU_UNIT_TARGET",
      "MENU_UNIT_COMMUNITIES_GUILD_MEMBER", "MENU_UNIT_GUILD" }) do
      pcall(Menu.ModifyMenu, tag, function(_, root, ctx)
        local name = type(ctx) == "table" and (short(ctx.name) or (ctx.unit and short((try(UnitName, ctx.unit))))) or nil
        if not name or name == me() or not root or not root.CreateButton then return end
        local unit = type(ctx) == "table" and ctx.unit or nil
        pcall(function()
          if root.CreateDivider then root:CreateDivider() end
          if root.CreateTitle then root:CreateTitle("Leveling Codex") end
          root:CreateButton(S.inBook(name) and "Open in my journey" or "Add to my journey", function()
            if not S.inBook(name) then S.add(name, unit) end
            if J.companions then J.companions.select(name) end
            if J.openPage then J.openPage("Companions") end
            ns.openTab("journey")
          end)
        end)
      end)
    end
    S.menus = true
  end
  -- Today's entry: one face you miss
  if J.tales and J.tales.todayLines and not S.wrappedToday then
    S.wrappedToday = true
    local today = J.tales.todayLines
    J.tales.todayLines = function(since)
      local out = today(since)
      local ok, m = pcall(S.missed)
      if ok and m[1] then out[#out + 1] = S.missedLine(m[1]) end
      return out
    end
  end
end

function ns.journeySocialDebugLines()
  local j = journal()
  local seen, books, groups = 0, 0, 0
  for name in pairs(j.sighted) do seen = seen + 1; if S.inBook(name) then books = books + 1 end end
  for _, g in pairs(j.fellowships) do if type(g) == "table" and g.formed then groups = groups + 1 end end
  return { "journey social: " .. seen .. " seen (" .. books .. " in the book), " .. groups .. " fellowships, " .. #j.portraits
    .. " portraits, menus " .. (S.menus and "on" or "off") .. ", sharing " .. (sharing() and "on" or "off") }
end
