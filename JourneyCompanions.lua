-- JourneyCompanions.lua: the people of your story. Journey.lua keeps who you grouped with
-- (journey.pals: seconds together, class, the first meeting); this file keeps what you did together
-- and draws the Companions page.
--   journey.fellows[name] = { met, myLevel, theirLevel, metZone, metAt = { map, x, y }, last, lastZone,
--     lastLevel, zones[land] = seconds, quests, kills, bosses, dungeons, runs, wipes, deaths, levels, rares,
--     close, bgs }: a 5 s tick while you are in a party (not a raid) and the moments J.add writes then.
--   A moment written while grouped (quests, bosses, dungeons, runs, wipes, deaths, levels, rares, close
--     calls, battlegrounds, new lands) carries e.with = "Ann,Bo", so each companion has a timeline.
--   journey.notes[name] = your own note on them (ASCII, up to Co.NOTE_MAX characters).
-- The page: FELLOW ADVENTURERS on the left (click a row: "Companion <name>"), their page on the right
-- (a title from what you shared, the prose, the figures, the lands, SHARED MOMENTS, YOUR NOTE with
-- "Note <name>"); FRIENDS AND STRANGERS (JourneyTales.lua) under the list on the left. ASCII, our own wording, all pcall'd.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local function try(...) return Q.try(...) end

local Co = {}
J.companions = Co

local TICK = 5
Co.NOTE_MAX = 200
-- moment kinds a companion shares, and the counter each adds to
local SHARED = { quest = "quests", chain = "quests", elite = "quests", boss = "bosses", dungeon = "dungeons", run = "runs",
  wipe = "wipes", death = "deaths", level = "levels", rare = "rares", close = "close", bg = "bgs", zone = false }
-- moments that name the person themselves (e.who)
local PERSONAL = { pal = true, rez = true, trade = true, duel = true, emote = true }

local function plain(s) return Q.plain(tostring(s or "")) end
local function now() return J.now() end
local function num(v)
  if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
  return tonumber(v)
end
local function say(n) return J.lore and J.lore.say and J.lore.say(n) or tostring(n) end
local function count(n, one, many) n = tonumber(n) or 0; return say(n) .. " " .. (n == 1 and one or (many or (one .. "s"))) end
local function plural(n, one, many) n = tonumber(n) or 0; return n .. " " .. (n == 1 and one or (many or (one .. "s"))) end

-- A name as the book prints it: the game's own name when it has letters beyond ASCII (the game font
-- draws a name's letters; stripping them could leave nothing), else the plain one; never empty.
function Co.nameText(name)
  name = tostring(name or "")
  if name:find("[\128-\255]") then return name end
  local p = plain(name)
  return p ~= "" and p or "a stranger"
end

local function journal()
  local j = J.data()
  if type(j.fellows) ~= "table" then j.fellows = {} end
  if type(j.notes) ~= "table" then j.notes = {} end
  return j
end

function Co.rec(name, make)
  local j = journal()
  local r = j.fellows[name]
  if type(r) ~= "table" then
    if not make then return nil end
    r = {}
    j.fellows[name] = r
  end
  if type(r.zones) ~= "table" then r.zones = {} end
  return r
end

-- Party members now: { name, level } (not in a raid).
local function party()
  local out = {}
  if try(IsInRaid) == true then return out end
  local n = num(try(GetNumSubgroupMembers)) or 0
  for i = 1, math.min(4, n) do
    local unit = "party" .. i
    local name = try(UnitName, unit)
    if type(name) == "string" and name ~= "" and name ~= "Unknown" then
      out[#out + 1] = { name = name, level = num((try(UnitLevel, unit))) }
    end
  end
  return out
end
Co.party = party

function Co.withYou(name)
  for _, p in ipairs(party()) do if p.name == name then return true end end
  return false
end

local function sessionKills()
  local st = ns.stats and ns.stats.data and (ns.stats.data())
  return type(st) == "table" and type(st.totals) == "table" and num(st.totals.kills) or nil
end

local lastKills
local function tick()
  local kills = sessionKills()
  local dk = (lastKills and kills and kills > lastKills) and (kills - lastKills) or 0
  lastKills = kills
  local list = party()
  if #list == 0 then return end
  local _, land, map, x, y = J.here()
  local inside = J.inInstance()
  if not land then land = J.zoneName() end
  for _, p in ipairs(list) do
    local r = Co.rec(p.name, true)
    if not r.met then
      r.met, r.myLevel, r.theirLevel, r.metZone = now(), J.level(), p.level, land
      if map and x and y and not inside then r.metAt = { map, math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10 } end
    end
    r.last, r.lastLevel = now(), p.level or r.lastLevel
    if land then
      r.lastZone = land
      if not inside then r.zones[land] = (tonumber(r.zones[land]) or 0) + TICK end
    end
    if dk > 0 then r.kills = (tonumber(r.kills) or 0) + dk end
  end
end

-- Every moment J.add writes while you are grouped names who was there.
local function tag(e)
  local field = SHARED[e.k]
  if field == nil then return end
  local names = {}
  for _, p in ipairs(party()) do
    names[#names + 1] = p.name
    if field then
      local r = Co.rec(p.name, true)
      r[field] = (tonumber(r[field]) or 0) + 1
    end
  end
  if #names > 0 then e.with = table.concat(names, ",") end
end
do
  local add = J.add
  J.add = function(kind, text, detail, extra)
    local e = add(kind, text, detail, extra)
    if type(e) == "table" then pcall(tag, e) end
    return e
  end
end

local function sharedWith(e, name)
  if type(e.with) == "string" then
    for n in e.with:gmatch("[^,]+") do if n == name then return true end end
  end
  return PERSONAL[e.k] and (e.who == name or e.who == plain(name)) or false
end

-- The moments you shared with name, newest first (limit of them), and how many there are.
function Co.moments(name, limit)
  local out, n = {}, 0
  local events = J.data().events
  for i = #events, 1, -1 do
    local e = events[i]
    if type(e) == "table" and sharedWith(e, name) then
      n = n + 1
      if not limit or #out < limit then out[#out + 1] = e end
    end
  end
  return out, n
end

-- Notes
function Co.note(name)
  local v = journal().notes[name]
  return type(v) == "string" and v ~= "" and v or nil
end
function Co.setNote(name, text)
  text = plain(text):gsub("[%c]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  if #text > Co.NOTE_MAX then return false, "A note holds up to " .. Co.NOTE_MAX .. " characters (this one has " .. #text .. ")." end
  journal().notes[name] = text ~= "" and text or nil
  return true
end

-- Everyone in the book: companions (pals) and the people you met (JourneyTales), merged by name,
-- the longest together first, then the most shared deeds.
function Co.list()
  local j = journal()
  local seen, out = {}, {}
  local function entry(name)
    if not seen[name] then
      seen[name] = { name = name, secs = 0, score = 0 }
      out[#out + 1] = seen[name]
    end
    return seen[name]
  end
  if type(j.pals) == "table" then
    for name, rec in pairs(j.pals) do
      if type(rec) == "table" then local p = entry(name); p.pal = rec; p.secs = tonumber(rec.seconds) or 0 end
    end
  end
  if type(j.people) == "table" then
    for name, rec in pairs(j.people) do
      if type(rec) == "table" then
        local p = entry(name)
        p.person = rec
        p.score = (tonumber(rec.trades) or 0) + 2 * (tonumber(rec.rez) or 0) + (tonumber(rec.duels) or 0) + (tonumber(rec.waves) or 0)
      end
    end
  end
  for _, p in ipairs(out) do p.f = type(j.fellows[p.name]) == "table" and j.fellows[p.name] or {} end
  table.sort(out, function(a, b)
    if a.secs ~= b.secs then return a.secs > b.secs end
    if a.score ~= b.score then return a.score > b.score end
    return a.name < b.name
  end)
  return out
end

local function field(p, key)
  local v = tonumber(p.f[key]) or 0
  if p.person and (key == "rez" or key == "trades" or key == "duels" or key == "waves") then v = tonumber(p.person[key]) or 0 end
  return v
end

-- A title for the person from what you shared.
function Co.title(p)
  local secs = p.secs
  if secs >= 36000 then return "Sworn companion" end
  if field(p, "rez") >= 2 then return "Your guardian angel" end
  if field(p, "bosses") >= 5 then return "Companion of the deep halls" end
  if field(p, "quests") >= 25 then return "Comrade of many errands" end
  if secs >= 7200 then return "Trusted companion" end
  if field(p, "rez") >= 1 then return "The one who raised you" end
  if field(p, "trades") >= 3 then return "Trading partner" end
  if field(p, "duels") >= 1 then return "Sparring partner" end
  if p.pal and secs >= 600 then return "Fellow traveller" end
  if p.pal then return "A passing companion" end
  return "A face on the road"
end

local function span(secs)
  secs = tonumber(secs) or 0
  if secs < 120 then return "a few moments" end
  if secs < 3600 then return say(math.floor(secs / 60 + 0.5)) .. " minutes" end
  if secs < 7200 then return "an hour" end
  return say(math.floor(secs / 3600 + 0.5)) .. " hours"
end

local function className(p)
  local token = p.pal and type(p.pal.class) == "string" and p.pal.class or nil
  return token and (token:sub(1, 1) .. token:sub(2):lower()) or nil, token
end

-- The lands you walked together, most time first: { { land, seconds } }.
function Co.lands(p)
  local out = {}
  for land, s in pairs(p.f.zones or {}) do out[#out + 1] = { land, tonumber(s) or 0 } end
  table.sort(out, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
  return out
end

local OPEN = {
  chronicle = { "The record first names %who% on day %day%, %where%: %what%, met when %name% was level %mine%.",
    "On day %day% the chronicle takes note of %who%, %what%, %where%. %name% was level %mine% then." },
  fireside = { "You remember meeting %who% %where%, on day %day%: %what%, and you were level %mine%.",
    "It was day %day%, %where%, when %who% fell in with you: %what%. You were level %mine%." },
  bard = { "Sing of the day %who% joined the tale, %where%, day %day%: %what%, beside %name% of level %mine%!",
    "On day %day% the road brought %who%, %what%, %where%, to stand by %name%, then level %mine%." },
}
local MET_PERSON = {
  chronicle = { "The record notes %who% on day %day%, %where%." },
  fireside = { "You crossed paths with %who% on day %day%, %where%." },
  bard = { "Day %day% brought %who% across your road, %where%." },
}
local NOW_LINES = {
  chronicle = { "%who% travels with %name% still.", "The entry stays open: %who% is in the party now." },
  fireside = { "And they are with you still.", "They are at your side even now." },
  bard = { "And still they march with you!", "The song goes on: they ride with you yet." },
}
local LAST_LINES = {
  chronicle = { "Last seen together on day %day%, %where%." },
  fireside = { "The last time you rode together was day %day%, %where%." },
  bard = { "Your roads last ran as one on day %day%, %where%." },
}

local function voiced(lines, seed, vars)
  if J.voice and J.voice.voiced then return J.voice.voiced(lines, seed, vars) end
  return J.fill(J.pick(lines.fireside, seed), vars)
end

-- The person's story: a few sentences from the record, in the narrator's voice.
function Co.prose(p)
  local j = J.data()
  local f = p.f
  local who = plain(p.name)
  if who == "" then who = "this companion" end
  local day = function(t) return math.max(1, math.floor(((tonumber(t) or 0) - (tonumber(j.started) or 0)) / 86400) + 1) end
  local s = {}
  local cls = className(p)
  local met = f.met or (p.pal and p.pal.first) or (p.person and p.person.met)
  local where = f.metZone and ("in " .. plain(f.metZone)) or "on the road"
  if p.pal then
    local what = (f.theirLevel and ("a level " .. f.theirLevel .. " ") or "a ") .. (cls and cls:lower() or "adventurer")
    s[#s + 1] = voiced(OPEN, who .. "open", { who = who, day = day(met), where = where, what = what,
      mine = tostring(f.myLevel or (p.pal and p.pal.level) or "?") })
  else
    s[#s + 1] = voiced(MET_PERSON, who .. "met", { who = who, day = day(met), where = where })
  end
  local lands = Co.lands(p)
  if p.secs >= 60 then
    local road = "Together you spent " .. span(p.secs) .. " on the road"
    if #lands >= 2 then road = road .. ", across " .. count(#lands, "land") .. ", most of it in " .. plain(lands[1][1])
    elseif #lands == 1 then road = road .. " in " .. plain(lands[1][1]) end
    s[#s + 1] = road .. "."
  end
  local work = {}
  if field(p, "quests") > 0 then work[#work + 1] = "turned in " .. count(field(p, "quests"), "quest") .. " side by side" end
  if field(p, "kills") > 0 then work[#work + 1] = "felled " .. count(field(p, "kills"), "foe") end
  if field(p, "bosses") > 0 then work[#work + 1] = "brought down " .. count(field(p, "bosses"), "boss", "bosses") end
  if field(p, "runs") > 0 then work[#work + 1] = "came out of " .. count(field(p, "runs"), "dungeon") .. " alive"
  elseif field(p, "dungeons") > 0 then work[#work + 1] = "went into " .. count(field(p, "dungeons"), "dungeon") end
  if field(p, "rares") > 0 then work[#work + 1] = "hunted down " .. count(field(p, "rares"), "rare beast") end
  if #work > 0 then
    local last = table.remove(work)
    s[#s + 1] = "You " .. (#work > 0 and (table.concat(work, ", ") .. " and " .. last) or last) .. "."
  end
  local hard = {}
  if field(p, "deaths") > 0 then hard[#hard + 1] = field(p, "deaths") == 1 and "They saw you fall once" or ("They saw you fall " .. say(field(p, "deaths")) .. " times") end
  if field(p, "wipes") > 0 then hard[#hard + 1] = "you wiped together " .. (field(p, "wipes") == 1 and "once" or (say(field(p, "wipes")) .. " times")) end
  if field(p, "close") > 0 then hard[#hard + 1] = "you scraped through " .. count(field(p, "close"), "close call") end
  if #hard > 0 then s[#s + 1] = (hard[1]:gsub("^%l", string.upper)) .. (#hard > 1 and (", " .. table.concat(hard, ", ", 2)) or "") .. "." end
  if field(p, "rez") > 0 then
    s[#s + 1] = field(p, "rez") == 1 and "Once, they brought you back from the dead." or ("They raised you from the dead " .. say(field(p, "rez")) .. " times.")
  end
  local kind = {}
  if field(p, "trades") > 0 then kind[#kind + 1] = count(field(p, "trades"), "trade") end
  if field(p, "duels") > 0 then kind[#kind + 1] = count(field(p, "duels"), "duel") end
  if field(p, "waves") > 0 then kind[#kind + 1] = count(field(p, "waves"), "kind word") end
  if #kind > 0 then s[#s + 1] = "Between you: " .. table.concat(kind, ", ") .. "." end
  if field(p, "levels") > 0 then
    s[#s + 1] = field(p, "levels") == 1 and "You gained a level in their company." or ("You gained " .. say(field(p, "levels")) .. " levels in their company.")
  end
  if p.pal and Co.withYou(p.name) then
    s[#s + 1] = voiced(NOW_LINES, who .. "now", { who = who })
  elseif f.last then
    s[#s + 1] = voiced(LAST_LINES, who .. "last", { day = day(f.last), where = f.lastZone and ("in " .. plain(f.lastZone)) or "on the road" })
  end
  return table.concat(s, " ")
end

----------------------------------------------------------------------------
-- The page
----------------------------------------------------------------------------
local chosen -- the name whose page is open (kept for the session); nil = the first in the list

function Co.select(name) chosen = name end
function Co.chosen() return chosen end

local function nameInk(C, token)
  local cc = token and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[token]
  local c = type(cc) == "table" and tonumber(cc.r) and { cc.r, cc.g, cc.b } or nil
  if C.book then return C.ink, c and J.draw.readable(C, c) or C.inkSoft end
  return c or C.light, c or C.light
end

-- One row of FELLOW ADVENTURERS; returns its height.
local function row(V, p, most, x, y, w, lit)
  local U, C = V.U, V.C
  local cls, token = className(p)
  local ink, bar = nameInk(C, token)
  local h = 48
  if lit then U.rect(x - 6, y - 4, w + 12, h - 2, { C.gold[1], C.gold[2], C.gold[3], C.book and 0.16 or 0.22 }) end
  U.icon(token and ("classicon_" .. token:lower()) or J.ICON.emote, x, y, 22, Co.nameText(p.name), cls)
  local mark = Co.note(p.name) and 16 or 0
  U.T(Co.nameText(p.name), x + 30, y + 1, w - 150, "body", ink)
  if mark > 0 then U.icon("INV_Scroll_03", x + w - 14, y + 18, 14, "Your note", Co.note(p.name)) end
  U.T(p.pal and (p.secs < 60 and "just met" or (J.draw.duration(p.secs) .. " together")) or "met on the road", x + 30, y + 1, w - 30,
    "small", C.light, "RIGHT")
  local bits = {}
  if cls then bits[#bits + 1] = cls end
  local lvl = p.f.theirLevel or (p.pal and p.pal.level)
  if p.pal and lvl then bits[#bits + 1] = "met at level " .. lvl end
  if field(p, "quests") > 0 then bits[#bits + 1] = plural(field(p, "quests"), "quest") end
  if field(p, "bosses") > 0 then bits[#bits + 1] = plural(field(p, "bosses"), "boss", "bosses") end
  if field(p, "rez") > 0 then bits[#bits + 1] = plural(field(p, "rez"), "rez", "rezzes") end
  if field(p, "trades") > 0 then bits[#bits + 1] = plural(field(p, "trades"), "trade") end
  U.T(table.concat(bits, "  -  "), x + 30, y + 17, w - 30 - mark, "small", C.dim)
  local track = C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 }
  U.rect(x + 30, y + 34, w - 30, 4, track)
  U.rect(x + 30, y + 34, math.max(2, (w - 30) * math.min(1, p.secs / most)), 4, bar)
  U.hit(x - 4, y - 3, w + 8, h - 4, Co.nameText(p.name), Co.title(p) .. "\nClick to open their page.", function()
    chosen = p.name
    U.refresh()
  end, "Companion " .. plain(p.name))
  return h
end

local function tiles(CV, cells, y)
  local U, C, W = CV.U, CV.C, CV.W
  local cw = math.floor((W - 18) / 4)
  for i, c in ipairs(cells) do
    local cx = (i - 1) * (cw + 6)
    U.box(cx, y, cw, 44, C.panel)
    U.T(c[1], cx, y + 7, cw, "head", C.ink or C.light, "CENTER")
    U.T(c[2], cx, y + 27, cw, "small", C.inkSoft or C.dim, "CENTER")
  end
  return 54
end

-- The chosen person's page on the right column; returns the bottom.
local function personPage(R, p, best, y)
  local U, C, W, j = R.U, R.C, R.W, R.j
  local D = J.draw
  local top = y
  y = y + 12
  local title = (p == best and p.secs >= 60) and "A TRUE COMPANION" or Co.title(p):upper()
  y = y + U.sectionTitle(title, y)
  local cls, token = className(p)
  U.icon(token and ("classicon_" .. token:lower()) or J.ICON.emote, math.floor(W / 2) - 20, y, 40, Co.nameText(p.name), cls)
  y = y + 46
  y = y + U.T(Co.nameText(p.name), 14, y, W - 28, "head", C.ink, "CENTER") + 2
  local sub = {}
  if p == best and p.secs >= 60 then sub[#sub + 1] = Co.title(p) end
  if cls then sub[#sub + 1] = cls .. ((p.f.lastLevel and p.pal) and (", level " .. p.f.lastLevel .. " when last seen") or "") end
  if p.pal and Co.withYou(p.name) then sub[#sub + 1] = "with you now" end
  if #sub > 0 then y = y + U.T(table.concat(sub, "  -  "), 14, y, W - 28, "small", C.inkSoft, "CENTER") + 8 end
  y = y + D.initialed(U, C, Co.prose(p), 14, y, W - 28, "body", C.ink) + 10
  if p.pal then
    local b = field(p, "bosses") > 0 and { tostring(field(p, "bosses")), field(p, "bosses") == 1 and "boss" or "bosses" }
      or { tostring(field(p, "deaths")), "falls seen" }
    y = y + tiles(R, { { p.secs >= 60 and D.duration(p.secs) or "-", "together" }, { tostring(field(p, "quests")), "quests" },
      { tostring(field(p, "kills")), "foes" }, b }, y)
  end
  local lands = Co.lands(p)
  if #lands > 0 then
    local names = {}
    for i = 1, math.min(5, #lands) do names[i] = plain(lands[i][1]) end
    y = y + U.T("Lands walked together: " .. table.concat(names, ", ") .. (#lands > 5 and (" and " .. (#lands - 5) .. " more") or "") .. ".",
      14, y, W - 28, "small", C.inkSoft, "CENTER") + 8
  end
  local words = J.lore and J.lore.companionLine and p.pal and J.lore.companionLine(p.name, p.pal)
  if words then y = y + U.T('"' .. words .. '"', 24, y, W - 48, "body", C.inkSoft, "CENTER") + 8 end
  y = y + 6
  D.page(U, C, 0, top, W, y - top)
  y = y + 12
  -- SHARED MOMENTS
  local list, n = Co.moments(p.name, 8)
  top = y
  y = D.cardTitle(R, "SHARED MOMENTS", 0, y, W, n > 0 and tostring(n) or nil)
  if #list == 0 then
    y = y + U.T("Nothing written together yet. Quest, fight or fall with them in your party and the moment carries their name.",
      14, y, W - 28, "small", C.dim) + 10
  else
    for _, e in ipairs(list) do
      U.icon(J.ICON[e.k] or J.ICON.quest, 14, y, 22, e.s, e.d)
      local h = U.T(e.s, 44, y + 1, W - 58, "small", C.light)
      U.T("Day " .. D.dayOf(j, e.t) .. ", level " .. (e.l or "?") .. (e.d and ("  -  " .. e.d) or ""), 44, y + h + 3, W - 58, "small", C.dim)
      y = y + math.max(28, h + 22)
    end
    if n > #list then y = y + U.T("... and " .. plural(n - #list, "more moment") .. " in the story.", 14, y, W - 28, "small", C.dim) + 6 end
    y = y + 4
  end
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 12
  -- YOUR NOTE
  top = y
  y = D.cardTitle(R, "YOUR NOTE", 0, y, W)
  local note = Co.note(p.name)
  if note then
    y = y + U.T('"' .. note .. '"', 20, y, W - 40, "body", C.ink) + 8
  else
    y = y + U.T("Write down who they are to you: a guildmate, the healer who saved a run, a friend from home.", 14, y, W - 28,
      "small", C.dim) + 8
  end
  local name = p.name
  local b = U.btn(note and "Edit the note" or "Write a note", 14, y, 140, function()
    ns.showMacroCopy({ copyTitle = "A note on " .. Co.nameText(name), body = Co.note(name) or "", paste = true,
      acceptLabel = "Save note",
      help = "A few words to remember them by, up to " .. Co.NOTE_MAX .. " characters. Click Save note when you are done; save it empty to remove the note.",
      onAccept = function(text)
        local ok, why = Co.setNote(name, text)
        if ok then ns.ui.refresh() end
        return ok, why
      end })
  end, false, "Your own words on this page, kept with the journal.")
  if b then b.codexLabel = "Note " .. plain(name) end
  y = y + 32
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

-- The Companions page (JourneyBook.lua calls it): ly, ry.
function Co.page(V, y)
  local L, R = V.L, V.R
  local U, C, W = L.U, L.C, L.W
  local all = Co.list()
  local pals, best = {}, nil
  local total = 0
  for _, p in ipairs(all) do
    if p.pal then pals[#pals + 1] = p; total = total + p.secs end
  end
  best = pals[1]
  local pick
  for _, p in ipairs(all) do if p.name == chosen then pick = p end end
  pick = pick or best or all[1]
  -- left: everyone who travelled with you
  local top, ly = y, y
  ly = J.draw.cardTitle(L, "FELLOW ADVENTURERS", 0, ly, W, #pals > 0 and plural(#pals, "companion") or nil)
  if total >= 60 then ly = ly + U.T(J.draw.duration(total) .. " in good company", 14, ly - 6, W - 28, "small", C.dim) + 4 end
  if #pals == 0 then
    ly = ly + U.T("Nobody has shared the road with you yet. Group up and they are remembered here: who they are, when you met, "
      .. "what you did together and how long you travelled.", 14, ly, W - 28, "small", C.dim) + 8
  else
    ly = ly + U.T("Click a name to open their page.", 14, ly - 2, W - 28, "small", C.inkSoft or C.dim) + 6
  end
  local most = math.max(60, best and best.secs or 60)
  for i, p in ipairs(pals) do
    if i > 40 then break end
    ly = ly + row(L, p, most, 14, ly, W - 28, p == pick)
  end
  ly = ly + 6
  U.box(0, top, W, ly - top, C.panel, C.edge)
  ly = ly + 12
  if J.tales and J.tales.companions then ly = J.tales.companions(L, ly) + 12 end
  -- right: the chosen person's page
  local ry = y
  if pick then ry = personPage(R, pick, best, ry) end
  return ly, ry
end

function ns.startJourneyCompanions()
  if Co.started then return end
  Co.started = true
  journal()
  lastKills = sessionKills()
  ns.every(TICK, function()
    local ok, err = pcall(tick)
    if not ok and not Co.errored then Co.errored = true; ns.say("journey companions error: " .. plain(err)) end
  end)
end

function ns.journeyCompanionsDebugLines()
  local j = journal()
  local n, notes = 0, 0
  for _ in pairs(j.fellows) do n = n + 1 end
  for _ in pairs(j.notes) do notes = notes + 1 end
  local here = {}
  for _, p in ipairs(party()) do here[#here + 1] = plain(p.name) end
  return { "journey companions: " .. n .. " remembered, " .. notes .. " notes"
    .. (#here > 0 and (", with " .. table.concat(here, ", ") .. " now") or "") }
end
