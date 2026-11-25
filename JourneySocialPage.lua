-- JourneySocialPage.lua: the social cards on the Companions page and the Fellowships page (after
-- JourneySocial.lua). Companions, left: ADD SOMEONE (Add my target / Add by name), FACES YOU MISS, then
-- (JourneyCompanions.lua) FELLOW ADVENTURERS and FRIENDS AND STRANGERS, then SEEN ON THE ROAD (the
-- pencilled names). A person's page gains the bond (a bar to the next rank), tags, THEIR JOURNAL (Codex to
-- Codex: Sign <name>, Toast <name>, their signatures), WHERE YOU MET (a heat map and a timeline), DATED
-- ENTRIES (Entry <name>, Remove entry N) and Forget <name> (two clicks). The Fellowships page: the
-- fellowships and those forming, AWARDS, GROUP PORTRAITS; on the right the chosen fellowship.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local S = J.social

local function plain(s) return Q.plain(tostring(s or "")) end
local function n0(v) return tonumber(v) or 0 end
local function now() return J.now() end
local function D() return J.draw end
local function name(n) return S.nameText(n) end
local function ago(t)
  local d = math.floor((now() - n0(t)) / 86400)
  if d <= 0 then return "today" end
  if d == 1 then return "yesterday" end
  return d .. " days ago"
end
local function classIcon(token) return type(token) == "string" and ("classicon_" .. token:lower()) or J.ICON.pal end
local function classOf(n)
  local j = S.journal()
  local pal, s = j.pals[n], j.sighted[n]
  return (type(pal) == "table" and pal.class) or (type(s) == "table" and s.c) or nil
end
local function open(n)
  if J.companions then J.companions.select(n) end
  if J.openPage then J.openPage("Companions") end
  ns.ui.refresh()
end

----------------------------------------------------------------------------
-- Companions page, left column
----------------------------------------------------------------------------
function S.leftTop(L, y)
  local U, C, W = L.U, L.C, L.W
  local top = y
  y = D().cardTitle(L, "ADD SOMEONE", 0, y, W)
  y = y + U.T("Put a player in your book by hand: your target, or a name. Right-click a player or a name in chat for "
    .. "\"Add to my journey\", or bind a key under Key Bindings > AddOns.", 14, y - 4, W - 28, "small", C.dim) + 6
  local bw = math.floor((W - 36) / 2)
  local b = U.btn("Add my target", 14, y, bw, function() S.addTarget(); ns.ui.refresh() end, false,
    "Adds the player you have targeted.")
  if b then b.codexLabel = "Add my target" end
  b = U.btn("Add by name", 22 + bw, y, bw, function()
    ns.showMacroCopy({ copyTitle = "Add someone to your journey", body = "", paste = true, acceptLabel = "Add them",
      help = "Type a character's name (same realm), then click Add them.",
      onAccept = function(text)
        local ok, why = S.add(text)
        if ok then ns.ui.refresh() end
        return ok, why
      end })
  end, false, "Type a character's name.")
  if b then b.codexLabel = "Add by name" end
  y = y + 30
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 12
  local missed = S.missed()
  if #missed > 0 then
    top = y
    y = D().cardTitle(L, "FACES YOU MISS", 0, y, W, tostring(#missed))
    for i = 1, math.min(4, #missed) do
      local m = missed[i]
      U.icon(classIcon(classOf(m.name)), 14, y, 20, name(m.name), select(2, S.bond(m.name)))
      U.T(S.missedLine(m), 42, y + 3, W - 56, "small", C.ink or C.light)
      U.hit(10, y - 2, W - 20, 24, name(m.name), "Click to open their page.", function() open(m.name) end, "Companion " .. plain(m.name))
      y = y + 26
    end
    y = y + 4
    U.box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
  return y
end

function S.leftMore(L, y)
  local U, C, W = L.U, L.C, L.W
  local j = S.journal()
  local list = {}
  for n, s in pairs(j.sighted) do
    if type(s) == "table" and not S.inBook(n) and n0(s.n) > 0 then list[#list + 1] = { name = n, s = s } end
  end
  table.sort(list, function(a, b)
    if n0(a.s.d) ~= n0(b.s.d) then return n0(a.s.d) > n0(b.s.d) end
    if n0(a.s.l) ~= n0(b.s.l) then return n0(a.s.l) > n0(b.s.l) end
    return a.name < b.name
  end)
  local top = y
  y = D().cardTitle(L, "SEEN ON THE ROAD", 0, y, W, #list > 0 and tostring(#list) or nil)
  if #list == 0 then
    y = y + U.T("Players you pass on the road are pencilled in here: who, where and how often. They fade after "
      .. S.FORGET_DAYS .. " days unless you meet them again or add them.", 14, y, W - 28, "small", C.dim) + 10
  else
    y = y + U.T("Pencilled in: they fade after " .. S.FORGET_DAYS .. " days unless they come back into your story.", 14, y - 4,
      W - 28, "small", C.dim) + 6
    for i = 1, math.min(10, #list) do
      local it = list[i]
      local s = it.s
      U.icon(classIcon(s.c), 14, y, 20, name(it.name), s.g and ("<" .. s.g .. ">") or nil)
      U.T(name(it.name), 42, y + 1, W - 150, "body", C.ink or C.light)
      U.T(ago(s.l), 14, y + 1, W - 28, "small", C.dim, "RIGHT")
      local bits = { "seen on " .. D().plural(math.max(1, n0(s.d)), "day") }
      if s.z then bits[#bits + 1] = "last in " .. plain(s.z) end
      if s.lv then bits[#bits + 1] = "level " .. s.lv end
      U.T(table.concat(bits, ", "), 42, y + 17, W - 56, "small", C.dim)
      U.hit(10, y - 2, W - 20, 34, name(it.name), "Click to open their page.", function() open(it.name) end, "Companion " .. plain(it.name))
      y = y + 36
    end
    if #list > 10 then y = y + U.T("... and " .. (#list - 10) .. " more faces.", 14, y, W - 28, "small", C.dim) + 6 end
    y = y + 4
  end
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

----------------------------------------------------------------------------
-- A person's page
----------------------------------------------------------------------------
function S.personTop(R, p, y)
  local U, C, W = R.U, R.C, R.W
  local n = p.name
  local rank, bondName, score, nextAt = S.bond(n)
  U.T("BOND: " .. bondName:upper(), 14, y, W - 28, "label", C.gold, "CENTER")
  y = y + 18
  local bw = W - 80
  local base = S.BONDS[rank][2]
  local share = nextAt and math.max(0, math.min(1, (score - base) / math.max(1, nextAt - base))) or 1
  local track = C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 }
  U.rect(40, y, bw, 5, track)
  U.rect(40, y, math.max(2, bw * share), 5, C.gold)
  for i = 2, #S.BONDS do
    U.rect(40 + math.floor(bw * (i - 1) / (#S.BONDS - 1)) - 1, y - 2, 2, 9, { C.gold[1], C.gold[2], C.gold[3], i <= rank and 0.9 or 0.35 })
  end
  U.hit(36, y - 6, bw + 8, 16, "Bond: " .. bondName, nextAt and ("Next: " .. S.BONDS[rank + 1][1] .. ". Time together, quests, bosses, "
    .. "rezzes, trades, whispers and the days you meet all bring you closer.") or "The closest bond there is.")
  y = y + 10
  local line = nextAt and ("Next: " .. S.BONDS[rank + 1][1]) or "As close as two adventurers get"
  y = y + U.T(line, 14, y, W - 28, "small", C.inkSoft or C.dim, "CENTER") + 6
  -- tags
  -- three to a row: five in one row overlapped ("Guildmate" ran into "Healer")
  local each = math.floor((W - 28) / 3)
  for i, tag in ipairs(S.TAGS) do
    local x = 14 + ((i - 1) % 3) * each
    local yy = y + math.floor((i - 1) / 3) * 26
    local cb = U.check(tag, x, yy, S.tagged(n, tag), function() S.toggleTag(n, tag); ns.ui.refresh() end, S.TAG_TIPS[tag])
    if cb then cb.codexLabel = "Tag " .. tag end
  end
  y = y + math.ceil(#S.TAGS / 3) * 26 + 2
  return y
end

local function journalCard(R, p, y)
  local U, C, W = R.U, R.C, R.W
  local n = p.name
  local codex = p.person and type(p.person.codex) == "table" and p.person.codex or nil
  local sigs = S.signatures(n)
  local top = y
  y = D().cardTitle(R, "THEIR JOURNAL", 0, y, W, codex and "Codex" or nil)
  if codex then
    local bits = {}
    if codex.day then bits[#bits + 1] = "day " .. codex.day end
    if codex.ep and codex.ep ~= "" then bits[#bits + 1] = codex.ep end
    if codex.moments then bits[#bits + 1] = codex.moments .. " moments" end
    if codex.level then bits[#bits + 1] = "level " .. codex.level end
    y = y + U.T(name(n) .. " keeps a Codex journal too: " .. table.concat(bits, ", ") .. ".", 14, y, W - 28, "small", C.ink or C.light) + 4
    if codex.bond then
      local theirs = S.BONDS[codex.bond] and S.BONDS[codex.bond][1] or "?"
      y = y + U.T("In their book you are their " .. theirs .. (codex.met and codex.met > 0 and (", met on their day " .. codex.met) or "")
        .. ".", 14, y, W - 28, "small", C.inkSoft or C.dim) + 4
    end
  else
    y = y + U.T("If they run the Codex too, group up and your journals swap titles; then ask them to sign yours or raise a toast.",
      14, y, W - 28, "small", C.dim) + 4
  end
  for i = 1, math.min(3, #sigs) do
    local s = sigs[i]
    y = y + U.T('"' .. plain(s.s) .. '"', 24, y + 2, W - 48, "body", C.ink or C.light, "CENTER") + 2
    y = y + U.T("- " .. name(n) .. ", day " .. D().dayOf(R.j or S.journal(), s.t) .. (s.z and (", " .. plain(s.z)) or ""), 24, y, W - 48,
      "small", C.inkSoft or C.dim, "CENTER") + 6
  end
  local can = S.reachable(n)
  local bw = math.floor((W - 36) / 2)
  local b = U.btn("Ask to sign", 14, y + 4, bw, function() S.askSign(n); ns.ui.refresh() end, can,
    can and "Ask them to write a line in your journal." or "Group up with them or target them first.")
  if b then b.codexLabel = "Sign " .. plain(n) end
  b = U.btn("Raise a toast", 22 + bw, y + 4, bw, function() S.toast(n) end, can,
    can and "A toast lands in their journal." or "Group up with them or target them first.")
  if b then b.codexLabel = "Toast " .. plain(n) end
  y = y + 34
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local function heatCard(R, p, y)
  local U, C, W = R.U, R.C, R.W
  local n = p.name
  local map, cells, total = S.heat(n)
  local tr = S.journal().trace[n]
  local days = type(tr) == "table" and type(tr.days) == "table" and tr.days or {}
  local nd = 0
  for _ in pairs(days) do nd = nd + 1 end
  if not map and nd == 0 then return y end
  local top = y
  local _, land = J.zoneOf(map or 0)
  y = D().cardTitle(R, "WHERE YOU MET", 0, y, W, map and plain(land) or nil)
  if map and cells then
    local mw = W - 28
    local mh = math.floor(mw * 0.62)
    local drawn = D().mapArt and D().mapArt(U, C, map, 14, y, mw, mh)
    if not drawn then U.rect(14, y, mw, mh, C.book and { 0.55, 0.45, 0.3, 0.25 } or { 0.1, 0.1, 0.12, 0.9 }, "border", -3) end
    local most = 1
    for _, v in pairs(cells) do if n0(v) > most then most = n0(v) end end
    local cw, ch = mw / 20, mh / 20
    for cell, v in pairs(cells) do
      cell = n0(cell)
      local cx, cy = math.floor(cell / 20), cell % 20
      local a = 0.25 + 0.6 * math.min(1, n0(v) / most)
      U.rect(14 + cx * cw, y + cy * ch, math.ceil(cw), math.ceil(ch), { 0.85, 0.25, 0.12, a }, "border", 2)
    end
    U.hit(14, y, mw, mh, "Where you met " .. name(n), "The warmer the square, the more time you spent there together.")
    y = y + mh + 6
  end
  -- the timeline: every day you were together, from the first to today
  local d0 = math.floor(n0(S.firstMet(n) or now()) / 86400)
  local d1 = math.floor(now() / 86400)
  local span = math.max(1, d1 - d0)
  local tw = W - 28
  U.rect(14, y + 18, tw, 2, C.book and { 0, 0, 0, 0.25 } or { 1, 1, 1, 0.2 })
  local most = 1
  for _, v in pairs(days) do if n0(v) > most then most = n0(v) end end
  for d, v in pairs(days) do
    local x = 14 + math.floor((n0(d) - d0) / span * (tw - 3))
    local h = 4 + math.floor(12 * math.min(1, math.sqrt(n0(v) / most)))
    U.rect(math.max(14, math.min(14 + tw - 3, x)), y + 18 - h, 3, h, C.gold)
  end
  U.T("Day " .. D().dayOf(S.journal(), S.firstMet(n) or now()), 14, y + 24, tw, "small", C.dim)
  U.T("today", 14, y + 24, tw, "small", C.dim, "RIGHT")
  U.T("Together on " .. D().plural(nd, "day"), 14, y + 24, tw, "small", C.inkSoft or C.dim, "CENTER")
  U.hit(14, y, tw, 36, "Your days together", "Each mark is a day you shared the road, met or spoke; the taller, the longer.")
  y = y + 44
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local confirmForget, confirmAt
local function diaryCard(R, p, y)
  local U, C, W = R.U, R.C, R.W
  local n = p.name
  local list = S.diary(n)
  local top = y
  y = D().cardTitle(R, "DATED ENTRIES", 0, y, W, #list > 0 and tostring(#list) or nil)
  if #list == 0 then
    y = y + U.T("Short entries with the day they were written: the run they carried, the night you got lost together.", 14, y, W - 28,
      "small", C.dim) + 6
  end
  for i, e in ipairs(list) do
    local h = U.T(plain(e.s), 14, y, W - 56, "body", C.ink or C.light)
    U.T("Day " .. D().dayOf(S.journal(), e.t) .. (e.l and (", level " .. e.l) or "") .. (e.z and (", " .. plain(e.z)) or ""), 14, y + h + 2,
      W - 56, "small", C.dim)
    local b = U.btn("x", W - 38, y, 24, function() S.removeEntry(n, i); ns.ui.refresh() end, false, "Remove this entry.")
    if b then b.codexLabel = "Remove entry " .. i end
    y = y + math.max(26, h + 20)
  end
  local b = U.btn("Add an entry", 14, y + 2, 140, function()
    ns.showMacroCopy({ copyTitle = "An entry on " .. name(n), body = "", paste = true, acceptLabel = "Save entry",
      help = "A few words for today, up to 200 characters. It is kept with the day, your level and where you are.",
      onAccept = function(text)
        local ok, why = S.addEntry(n, text)
        if ok then ns.ui.refresh() end
        return ok, why
      end })
  end, false, "Write a dated entry about them.")
  if b then b.codexLabel = "Entry " .. plain(n) end
  y = y + 32
  U.box(0, top, W, y - top, C.panel, C.edge)
  y = y + 12
  local armed = confirmForget == n and confirmAt and GetTime() - confirmAt < 5
  b = U.btn(armed and "Click again to forget" or "Remove from journey", 14, y, W - 28, function()
    if armed then
      confirmForget = nil
      S.forget(n)
      ns.say(name(n) .. " is gone from your journey. Add them again any time.")
    else
      confirmForget, confirmAt = n, GetTime()
    end
    ns.ui.refresh()
  end, armed, "Takes them out of the journal: their page, notes, tags and the moments that name them. Click twice.")
  if b then b.codexLabel = "Forget " .. plain(n) end
  return y + 34
end

function S.personMore(R, p, y)
  y = journalCard(R, p, y)
  y = heatCard(R, p, y)
  return diaryCard(R, p, y)
end

----------------------------------------------------------------------------
-- The Fellowships page
----------------------------------------------------------------------------
local chosen
function S.selectFellowship(key) chosen = key end
function S.chosenFellowship() return chosen end

-- A group portrait: you and the party, framed, with the moment as its caption; returns its height.
function S.portraitCard(V, pt, x, y, w)
  local U, C = V.U, V.C
  local top = y
  local j = S.journal()
  U.T("Day " .. D().dayOf(j, pt.t) .. "  -  " .. plain(pt.w), x + 10, y + 8, w - 20, "label", C.gold, "CENTER")
  y = y + 24
  if pt.z then y = y + U.T(plain(pt.z), x + 10, y, w - 20, "small", C.dim, "CENTER") + 4 end
  local folk = { { n = "You", c = pt.c, l = pt.l } }
  for _, m in ipairs(pt.who or {}) do folk[#folk + 1] = m end
  local each = math.min(72, math.floor((w - 20) / #folk))
  local x0 = x + math.floor((w - each * #folk) / 2)
  for i, m in ipairs(folk) do
    local cx = x0 + (i - 1) * each
    U.rect(cx + math.floor(each / 2) - 18, y, 36, 36, { C.gold[1], C.gold[2], C.gold[3], 0.8 })
    U.icon(classIcon(m.c), cx + math.floor(each / 2) - 16, y + 2, 32, m.n == "You" and "You" or name(m.n), m.l and ("Level " .. m.l) or nil)
    U.T(m.n == "You" and "You" or name(m.n), cx, y + 40, each, "small", C.ink or C.light, "CENTER")
    if m.l then U.T(tostring(m.l), cx, y + 54, each, "small", C.dim, "CENTER") end
  end
  y = y + 72
  U.box(x, top, w, y - top, C.panel, C.edge)
  return y - top
end

local function fellowshipRow(L, f, y, lit)
  local U, C, W = L.U, L.C, L.W
  local g = f.g
  if lit then U.rect(8, y - 4, W - 16, 46, { C.gold[1], C.gold[2], C.gold[3], C.book and 0.16 or 0.22 }) end
  U.icon(J.ICON.fellowship, 14, y, 22, S.fellowshipName(g, f.key), S.listText(f.names))
  U.T(S.fellowshipName(g, f.key), 44, y + 1, W - 150, "body", C.ink or C.light)
  U.T(D().duration(n0(g.secs)), 14, y + 1, W - 28, "small", C.light, "RIGHT")
  local bits = { S.listText(f.names) }
  if n0(g.quests) > 0 then bits[#bits + 1] = D().plural(n0(g.quests), "quest") end
  if n0(g.bosses) > 0 then bits[#bits + 1] = n0(g.bosses) .. (n0(g.bosses) == 1 and " boss" or " bosses") end
  U.T(table.concat(bits, "  -  "), 44, y + 17, W - 58, "small", C.dim)
  U.hit(10, y - 3, W - 20, 42, S.fellowshipName(g, f.key), "Click to open its page.", function() chosen = f.key; ns.ui.refresh() end,
    "Fellowship " .. S.fellowshipName(g, f.key))
  return 46
end

local function awardsCard(L, y)
  local U, C, W = L.U, L.C, L.W
  local list = S.awards()
  local top = y
  y = D().cardTitle(L, "AWARDS", 0, y, W, #list > 0 and tostring(#list) or nil)
  if #list == 0 then
    y = y + U.T("Travel, fight, trade and talk with people and the awards fill in: road companion, guardian angel, pen pal and more.",
      14, y, W - 28, "small", C.dim) + 10
  else
    local cw = math.floor((W - 34) / 2)
    for i, a in ipairs(list) do
      local cx = 14 + ((i - 1) % 2) * (cw + 6)
      local cy = y + math.floor((i - 1) / 2) * 50
      U.box(cx, cy, cw, 44, C.panel)
      U.icon(a.icon, cx + 6, cy + 10, 24, a.title, a.tip)
      U.T(a.title:upper(), cx + 36, cy + 5, cw - 40, "small", C.gold)
      U.T(name(a.name), cx + 36, cy + 18, cw - 40, "body", C.ink or C.light)
      U.T(a.text, cx + 36, cy + 30, cw - 40, "small", C.dim)
      U.hit(cx, cy, cw, 44, a.title .. ": " .. name(a.name), a.tip .. " (" .. a.text .. ").\nClick to open their page.", function() open(a.name) end,
        "Award " .. a.title)
    end
    y = y + math.ceil(#list / 2) * 50 + 4
  end
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local function fellowshipPage(R, f, y)
  local U, C, W = R.U, R.C, R.W
  local g, key = f.g, f.key
  local j = S.journal()
  local top = y
  y = y + 12
  y = y + U.sectionTitle(S.fellowshipName(g, key):upper(), y)
  local each = math.min(80, math.floor((W - 28) / (#f.names + 1)))
  local x0 = math.floor((W - each * (#f.names + 1)) / 2)
  local _, mine = Q.try(UnitClass, "player")
  local folk = { { "You", mine } }
  for _, n in ipairs(f.names) do folk[#folk + 1] = { n, classOf(n) } end
  for i, m in ipairs(folk) do
    local cx = x0 + (i - 1) * each
    U.icon(classIcon(m[2]), cx + math.floor(each / 2) - 14, y, 28, m[1] == "You" and "You" or name(m[1]))
    U.T(m[1] == "You" and "You" or name(m[1]), cx, y + 32, each, "small", C.ink or C.light, "CENTER")
    if m[1] ~= "You" then U.hit(cx, y, each, 46, name(m[1]), "Click to open their page.", function() open(m[1]) end, "Companion " .. plain(m[1])) end
  end
  y = y + 52
  local s = {}
  s[#s + 1] = "Formed on day " .. D().dayOf(j, g.formed or g.first) .. ", after " .. D().duration(n0(g.secs)) .. " on the road together"
    .. (n0(g.days) > 1 and (" over " .. n0(g.days) .. " days") or "") .. "."
  local work = {}
  if n0(g.quests) > 0 then work[#work + 1] = D().plural(n0(g.quests), "quest") end
  if n0(g.bosses) > 0 then work[#work + 1] = n0(g.bosses) .. (n0(g.bosses) == 1 and " boss" or " bosses") end
  if n0(g.runs) > 0 then work[#work + 1] = D().plural(n0(g.runs), "dungeon run") end
  if n0(g.levels) > 0 then work[#work + 1] = D().plural(n0(g.levels), "level") end
  if #work > 0 then s[#s + 1] = "Between you: " .. table.concat(work, ", ") .. "." end
  if n0(g.wipes) + n0(g.deaths) > 0 then
    s[#s + 1] = "Not every pull went well: " .. D().plural(n0(g.wipes), "wipe") .. " and " .. D().plural(n0(g.deaths), "fall") .. "."
  end
  if g.last then s[#s + 1] = "Last together " .. ago(g.last) .. "." end
  y = y + D().initialed(U, C, table.concat(s, " "), 14, y, W - 28, "body", C.ink or C.light) + 10
  local b = U.btn("Rename", math.floor(W / 2) - 60, y, 120, function()
    ns.showMacroCopy({ copyTitle = "Name your fellowship", body = g.named or g.auto or "", paste = true, acceptLabel = "Save name",
      help = "3 to 32 characters. Save it empty to go back to the name it was given.",
      onAccept = function(text)
        local ok, why = S.rename(key, text)
        if ok then ns.ui.refresh() end
        return ok, why
      end })
  end, false, "Give the fellowship your own name.")
  if b then b.codexLabel = "Rename fellowship" end
  y = y + 32
  D().page(U, C, 0, top, W, y - top)
  y = y + 12
  -- its portraits
  local set = {}
  for _, n in ipairs(f.names) do set[n] = true end
  local shown = 0
  for i = #j.portraits, 1, -1 do
    local pt = j.portraits[i]
    local hits = 0
    for _, m in ipairs(pt.who or {}) do if set[m.n] then hits = hits + 1 end end
    if hits == #f.names and shown < 3 then
      shown = shown + 1
      y = y + S.portraitCard(R, pt, 0, y, W) + 10
    end
  end
  -- shared moments: every member there
  top = y
  y = D().cardTitle(R, "WHAT YOU DID TOGETHER", 0, y, W)
  local count = 0
  for i = #j.events, 1, -1 do
    local e = j.events[i]
    if type(e) == "table" and type(e.with) == "string" then
      local here = {}
      for n in e.with:gmatch("[^,]+") do here[n] = true end
      local all = true
      for _, n in ipairs(f.names) do if not here[n] then all = false end end
      if all and count < 8 then
        count = count + 1
        U.icon(J.ICON[e.k] or J.ICON.quest, 14, y, 22, e.s, e.d)
        local h = U.T(e.s, 44, y + 1, W - 58, "small", C.ink or C.light)
        U.T("Day " .. D().dayOf(j, e.t) .. ", level " .. (e.l or "?"), 44, y + h + 3, W - 58, "small", C.dim)
        y = y + math.max(28, h + 22)
      end
    end
  end
  if count == 0 then y = y + U.T("Nothing written with all of you there yet.", 14, y, W - 28, "small", C.dim) + 8 end
  y = y + 4
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local function page(V, y)
  local L, R = V.L, V.R
  local U, C, W = L.U, L.C, L.W
  local formed = S.fellowships(false)
  local forming = {}
  for _, f in ipairs(S.fellowships(true)) do if not f.g.formed then forming[#forming + 1] = f end end
  local pick
  for _, f in ipairs(formed) do if f.key == chosen then pick = f end end
  pick = pick or formed[1]
  local top, ly = y, y
  ly = D().cardTitle(L, "FELLOWSHIPS", 0, ly, W, #formed > 0 and tostring(#formed) or nil)
  if #formed == 0 then
    ly = ly + U.T("When the same two or more people travel with you for half an hour, or meet you again on another day, "
      .. "you become a fellowship: it gets a name, a page and a record of everything you did together.", 14, ly, W - 28, "small", C.dim) + 8
  end
  for i, f in ipairs(formed) do
    if i > 12 then break end
    ly = ly + fellowshipRow(L, f, ly, f == pick)
  end
  for i = 1, math.min(3, #forming) do
    local f = forming[i]
    local share = math.min(1, n0(f.g.secs) / S.FORM_SECS)
    U.T(S.listText(f.names) .. ": forming", 14, ly, W - 28, "small", C.inkSoft or C.dim)
    U.rect(14, ly + 16, W - 28, 4, C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 })
    U.rect(14, ly + 16, math.max(2, (W - 28) * share), 4, C.gold)
    ly = ly + 28
  end
  ly = ly + 6
  U.box(0, top, W, ly - top, C.panel, C.edge)
  ly = ly + 12
  ly = awardsCard(L, ly)
  -- the latest group portraits
  local j = S.journal()
  top = ly
  ly = D().cardTitle(L, "GROUP PORTRAITS", 0, ly, W, #j.portraits > 0 and tostring(#j.portraits) or nil)
  if #j.portraits == 0 then
    ly = ly + U.T("A level gained or a boss brought down in a party is framed here, with everyone who was there.", 14, ly, W - 28,
      "small", C.dim) + 10
    U.box(0, top, W, ly - top, C.panel, C.edge)
    ly = ly + 12
  else
    U.box(0, top, W, ly - top, C.panel, C.edge)
    ly = ly + 6
    for i = #j.portraits, math.max(1, #j.portraits - 3), -1 do ly = ly + S.portraitCard(L, j.portraits[i], 0, ly, W) + 8 end
    ly = ly + 4
  end
  local ry = y
  if pick then ry = fellowshipPage(R, pick, ry)
  else
    local RU, RC, RW = R.U, R.C, R.W
    local rtop = ry
    ry = ry + 12
    ry = ry + RU.sectionTitle("THE COMPANY YOU KEEP", ry)
    ry = ry + D().initialed(RU, RC, "No fellowship has formed yet. Group up with the same friends again and the book gives your band a "
      .. "name, keeps its record, frames its portraits and remembers what you did together. You can rename it any time.", 14, ry, RW - 28,
      "body", RC.ink or RC.light) + 12
    D().page(RU, RC, 0, rtop, RW, ry - rtop)
    ry = ry + 12
  end
  return ly, ry
end

J.addPage("Fellowships", "Your fellowships, the awards your companions have won and the group portraits.", page, "Companions")
