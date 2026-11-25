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

-- The awards cabinet: every award, the won ones with their holder, the rest dim with how to win them.
local function awardsCard(L, y)
  local U, C, W = L.U, L.C, L.W
  local won, rest = S.awardCabinet()
  local top = y
  y = D().cardTitle(L, "AWARDS", 0, y, W, #won .. " of " .. (#won + #rest))
  y = y + U.T("Titles your companions have earned in your story. Each goes to whoever holds the record.", 14, y, W - 28, "small", C.dim) + 8
  local cw = math.floor((W - 34) / 2)
  local all = {}
  for _, a in ipairs(won) do all[#all + 1] = a end
  for _, a in ipairs(rest) do all[#all + 1] = a end
  -- Row by row: a description that wraps makes its row taller, so it never
  -- runs into the award below.
  for r = 1, #all, 2 do
    local rowH = 44
    local drawn = {}
    for k = 0, 1 do
      local a = all[r + k]
      if a then
        local cx = 14 + k * (cw + 6)
        local ic = U.icon(a.icon, cx + 6, y + 10, 24, a.title, a.tip)
        local h
        if a.won then
          U.T(a.title:upper(), cx + 36, y + 5, cw - 40, "small", C.gold)
          U.T(name(a.name), cx + 36, y + 18, cw - 40, "body", C.ink or C.light)
          h = 30 + (U.T(a.text, cx + 36, y + 31, cw - 40, "small", C.dim) or 12) + 6
        else
          if ic and ic.tex then ic.tex:SetDesaturated(true); ic.tex:SetAlpha(0.45) end
          U.T(a.title:upper(), cx + 36, y + 5, cw - 40, "small", C.inkSoft or C.dim)
          U.T("Not yet awarded", cx + 36, y + 18, cw - 40, "small", C.dim)
          h = 30 + (U.T(a.tip, cx + 36, y + 31, cw - 40, "small", C.dim) or 12) + 6
        end
        if h > rowH then rowH = h end
        drawn[#drawn + 1] = { a = a, cx = cx }
      end
    end
    for _, d in ipairs(drawn) do
      local a, cx = d.a, d.cx
      U.box(cx, y, cw, rowH, C.panel)
      if a.won then
        U.hit(cx, y, cw, rowH, a.title .. ": " .. name(a.name), a.tip .. " (" .. a.text .. ").\n" .. (a.flavour or "") .. "\nClick to open their page.",
          function() open(a.name) end, "Award " .. a.title)
      else
        U.hit(cx, y, cw, rowH, a.title, a.tip .. ".\n" .. (a.flavour or ""), nil, "Award " .. a.title)
      end
    end
    y = y + rowH + 6
  end
  y = y + 4
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

-- Who you're grouped with now: the fellowship you're becoming (or are).
local function bandNow(L, y)
  local U, C, W = L.U, L.C, L.W
  local party = S.party()
  if #party == 0 then return y end
  local key = S.groupKey(party)
  local g = key and S.journal().fellowships[key]
  local top = y
  y = D().cardTitle(L, "YOUR BAND RIGHT NOW", 0, y, W, #party == 1 and "a pair" or (#party + 1) .. " of you")
  local each = math.min(70, math.floor((W - 28) / #party))
  for i, p in ipairs(party) do
    local cx = 14 + (i - 1) * each
    U.icon(classIcon(p.class), cx + math.floor(each / 2) - 12, y, 24, name(p.name), p.level and ("Level " .. p.level) or nil)
    U.T(name(p.name), cx, y + 27, each, "small", C.ink or C.light, "CENTER")
  end
  y = y + 46
  local secs = g and n0(g.secs) or 0
  if g and g.formed then
    y = y + U.T("You ride as " .. S.fellowshipName(g, key) .. ": " .. D().duration(secs) .. " together so far.", 14, y, W - 28, "small", C.inkSoft or C.dim) + 4
    U.hit(10, top, W - 20, y - top, S.fellowshipName(g, key), "Click to open its page.", function() S.selectFellowship(key); ns.ui.refresh() end,
      "Band now")
  else
    local share = math.min(1, secs / S.FORM_SECS)
    local left = math.max(0, S.FORM_SECS - secs)
    U.rect(14, y, W - 28, 5, C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 })
    U.rect(14, y, math.max(2, (W - 28) * share), 5, C.gold)
    y = y + 10
    local line = secs < 60 and "Stay together and the book will give you a name."
      or ("About " .. D().duration(left) .. " more together and the book gives you a name.")
    y = y + U.T(line, 14, y, W - 28, "small", C.inkSoft or C.dim) + 4
  end
  y = y + 6
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

-- The fellowship's colours, from its key: { r, g, b }.
local BANNERS = { { 0.55, 0.12, 0.12 }, { 0.14, 0.24, 0.5 }, { 0.15, 0.4, 0.22 }, { 0.38, 0.16, 0.45 }, { 0.12, 0.38, 0.4 },
  { 0.55, 0.36, 0.1 }, { 0.28, 0.3, 0.34 }, { 0.45, 0.1, 0.25 } }
local function hash(s)
  local h = 0
  for i = 1, #s do h = (h * 31 + s:byte(i)) % 1000003 end
  return h
end

-- Moments with every member there, newest first.
local function together(j, f)
  local out = {}
  for i = #j.events, 1, -1 do
    local e = j.events[i]
    if type(e) == "table" and type(e.with) == "string" then
      local here = {}
      for n in e.with:gmatch("[^,]+") do here[n] = true end
      local all = true
      for _, n in ipairs(f.names) do if not here[n] then all = false end end
      if all then out[#out + 1] = e end
    end
  end
  return out
end

local FINE = { boss = 10, run = 8, dungeon = 7, elite = 6, rare = 6, level = 5, chain = 4, bond = 3, quest = 1 }
local DARK = { wipe = 10, death = 8, close = 5 }
local function weightiest(list, w)
  local best, bw = nil, 0
  for _, e in ipairs(list) do
    local v = w[e.k] or 0
    if v > bw then best, bw = e, v end
  end
  return best
end

-- The fellowship's lands by time: { { land, secs } }, from its own record, else its moments.
local function landsOf(g, moments)
  local out = {}
  if type(g.zones) == "table" then
    for land, secs in pairs(g.zones) do out[#out + 1] = { land, n0(secs) } end
  else
    local c = {}
    for _, e in ipairs(moments) do
      local land = e.m and J.landOf and J.landOf(e.m)
      if land then c[land] = (c[land] or 0) + 60 end
    end
    for land, secs in pairs(c) do out[#out + 1] = { land, secs } end
  end
  table.sort(out, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
  return out
end

-- A motto from what the fellowship has done.
local function motto(g, key, lands)
  local pair = #S.names(key) == 1
  local pool
  if n0(g.wipes) >= 3 then pool = { "We fall together, and we get up together.", "Wipe, laugh, run it back." }
  elseif n0(g.bosses) >= 3 then pool = { "No boss too big, no dungeon too deep.", "Down they go, one after another." }
  elseif n0(g.quests) >= 20 then pool = { "Every errand, every road, together.", "No notice board left unread." }
  elseif #lands >= 4 then pool = { "Many roads, one company.", "The map is a little smaller with a friend." }
  elseif n0(g.days) >= 3 then pool = { "Again tomorrow, as always.", "Same time, same road." }
  elseif n0(g.deaths) == 0 and n0(g.secs) >= 3600 then pool = { "Not one of us left behind.", "Nobody falls on our watch." }
  elseif pair then pool = { "Where one goes, the other follows.", "Two swords are better than one.", "Back to back, always.",
    "Two paths, one road." }
  else pool = { "Steel, salt and good company.", "Share the road, share the fire.", "Slow to anger, quick to help.",
    "Into the dark, and out again.", "Strength in numbers, and in friends." } end
  return pool[hash(key .. "motto") % #pool + 1]
end

-- The fellowship's story, in the narrator's voice.
local SAGA = {
  founded = {
    chronicle = { "The %band% was founded on day %day%%where%, when %who% and %name% had shared the road long enough to be named.",
      "On day %day%%where%, %who% and %name% became the %band%." },
    fireside = { "Day %day%%where%: that's when you and %who% stopped being strangers and became the %band%.",
      "It started on day %day%%where%. You, %who%, and a road that kept going." },
    bard = { "On day %day%%where% a fellowship was born: %who% and you, the %band%.",
      "Sing of day %day%%where%, when the %band% first rode out." } },
  forming = {
    chronicle = { "The %band% is not yet founded; %who% and %name% are still earning their name." },
    fireside = { "You and %who% aren't a fellowship yet. Give it time." },
    bard = { "Not yet a fellowship, but the song is tuning up." } },
  work = {
    chronicle = { "Together they completed %work%.", "The record shows %work% between them." },
    fireside = { "Between you: %work%.", "You got through %work% together." },
    bard = { "Together you won %work%.", "Hand in hand came %work%." } },
  hard = {
    chronicle = { "It was not without cost: %hard%.", "There were setbacks: %hard%." },
    fireside = { "Not every pull went well: %hard%.", "There were bad nights too: %hard%." },
    bard = { "Not all the verses are bright: %hard%." } },
  clean = {
    chronicle = { "None of them fell while together." },
    fireside = { "And not one fall between you. Not bad." },
    bard = { "No grave was dug while they rode together." } },
  lands = {
    chronicle = { "Their road ran through %lands%.", "They walked %lands% together." },
    fireside = { "You covered %lands% together.", "The road took you through %lands%." },
    bard = { "Through %lands% the company wandered." } },
  days = {
    chronicle = { "They met on %n% separate days.", "Their company spans %n% days." },
    fireside = { "%N% days on the road together, and counting.", "You kept finding each other: %n% days so far." },
    bard = { "%N% dawns found them on the same road." } },
  last = {
    chronicle = { "They were last together %when%." },
    fireside = { "Last time together: %when%.", "You last rode together %when%." },
    bard = { "The last verse was sung %when%." } },
}

local function voiced(lines, seed, vars)
  if J.voice and J.voice.voiced then return J.voice.voiced(lines, seed, vars) end
  return J.fill(J.pick(lines.fireside, seed), vars)
end
local function say(n) return J.lore and J.lore.say and J.lore.say(n) or tostring(n) end

local function saga(j, f, lands)
  local g, key = f.g, f.key
  local vars = { band = S.fellowshipName(g, key):gsub("^The ", ""), who = S.listText(f.names), day = D().dayOf(j, g.formed or g.first) }
  vars.where = g.fz and (" in " .. plain(g.fz)) or ""
  local out = {}
  out[#out + 1] = voiced(g.formed and SAGA.founded or SAGA.forming, key .. "f", vars)
  local work = {}
  if n0(g.quests) > 0 then work[#work + 1] = D().plural(n0(g.quests), "quest") end
  if n0(g.bosses) > 0 then work[#work + 1] = n0(g.bosses) .. (n0(g.bosses) == 1 and " boss" or " bosses") end
  if n0(g.runs) > 0 then work[#work + 1] = D().plural(n0(g.runs), "dungeon run") end
  if n0(g.levels) > 0 then work[#work + 1] = D().plural(n0(g.levels), "level") end
  if #work > 0 then
    vars.work = #work == 1 and work[1] or (table.concat(work, ", ", 1, #work - 1) .. " and " .. work[#work])
    out[#out + 1] = voiced(SAGA.work, key .. "w", vars)
  end
  if n0(g.wipes) + n0(g.deaths) > 0 then
    local hard = {}
    if n0(g.wipes) > 0 then hard[#hard + 1] = D().plural(n0(g.wipes), "wipe") end
    if n0(g.deaths) > 0 then hard[#hard + 1] = D().plural(n0(g.deaths), "fall") end
    vars.hard = table.concat(hard, " and ")
    out[#out + 1] = voiced(SAGA.hard, key .. "h", vars)
  elseif n0(g.secs) >= 1800 then out[#out + 1] = voiced(SAGA.clean, key .. "c", vars) end
  if #lands >= 2 then
    local l = {}
    for i = 1, math.min(3, #lands) do l[i] = lands[i][1] end
    vars.lands = #lands > 3 and (table.concat(l, ", ") .. " and " .. say(#lands - 3) .. " more")
      or (#l == 2 and (l[1] .. " and " .. l[2]) or (l[1] .. ", " .. l[2] .. " and " .. l[3]))
    out[#out + 1] = voiced(SAGA.lands, key .. "l", vars)
  end
  if n0(g.days) >= 2 then
    vars.n, vars.N = say(n0(g.days)), (say(n0(g.days)):gsub("^%l", string.upper))
    out[#out + 1] = voiced(SAGA.days, key .. "d", vars)
  end
  if g.last and now() - n0(g.last) > 3600 then
    vars.when = ago(g.last)
    out[#out + 1] = voiced(SAGA.last, key .. "t", vars)
  end
  return table.concat(out, " ")
end

local function hourCard(R, title, e, y, color)
  local U, C, W = R.U, R.C, R.W
  local j = S.journal()
  local top = y
  y = D().cardTitle(R, title, 0, y, W)
  U.icon(J.ICON[e.k] or J.ICON.quest, 14, y, 28, e.s, e.d)
  local h = U.T(e.s, 50, y + 1, W - 64, "body", color or C.ink or C.light)
  local where = e.m and J.landOf and J.landOf(e.m)
  U.T("Day " .. D().dayOf(j, e.t) .. ", level " .. (e.l or "?") .. (where and (", " .. where) or ""), 50, y + h + 3, W - 64, "small", C.dim)
  y = y + math.max(34, h + 22) + 4
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local function fellowshipPage(R, f, y)
  local U, C, W = R.U, R.C, R.W
  local g, key = f.g, f.key
  local j = S.journal()
  local moments = together(j, f)
  local lands = landsOf(g, moments)
  local top = y
  y = y + 12
  -- the banner: its colours, its sign and the year it was founded
  local col = BANNERS[hash(key) % #BANNERS + 1]
  local bw, bh = 96, 84
  local bx = math.floor((W - bw) / 2)
  U.rect(bx - 2, y - 2, bw + 4, bh + 4, { C.gold[1], C.gold[2], C.gold[3], 0.9 })
  U.rect(bx, y, bw, bh, { col[1], col[2], col[3], 1 })
  U.rect(bx + 6, y + 6, bw - 12, 1, { 1, 0.85, 0.4, 0.5 })
  U.rect(bx + 6, y + bh - 7, bw - 12, 1, { 1, 0.85, 0.4, 0.5 })
  -- the swallowtail: two tails under the banner
  U.rect(bx, y + bh + 2, math.floor(bw / 2) - 6, 10, { col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 1 })
  U.rect(bx + math.floor(bw / 2) + 6, y + bh + 2, math.floor(bw / 2) - 6, 10, { col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 1 })
  U.icon(J.ICON.fellowship, bx + math.floor(bw / 2) - 18, y + 12, 36, S.fellowshipName(g, key), motto(g, key, lands))
  U.T(g.formed and ("EST. DAY " .. D().dayOf(j, g.formed)) or "FORMING", bx, y + 56, bw, "small", { 1, 0.9, 0.6 }, "CENTER")
  y = y + bh + 20
  y = y + U.sectionTitle(S.fellowshipName(g, key):upper(), y)
  y = y + U.T('"' .. motto(g, key, lands) .. '"', 14, y, W - 28, "body", C.inkSoft or C.dim, "CENTER") + 10
  -- the roster: you and them, with their bond and role
  local each = math.min(90, math.floor((W - 28) / (#f.names + 1)))
  local x0 = math.floor((W - each * (#f.names + 1)) / 2)
  local _, mine = Q.try(UnitClass, "player")
  local folk = { { "You", mine } }
  for _, n in ipairs(f.names) do folk[#folk + 1] = { n, classOf(n) } end
  for i, m in ipairs(folk) do
    local cx = x0 + (i - 1) * each
    U.icon(classIcon(m[2]), cx + math.floor(each / 2) - 14, y, 28, m[1] == "You" and "You" or name(m[1]))
    U.T(m[1] == "You" and "You" or name(m[1]), cx, y + 32, each, "small", C.ink or C.light, "CENTER")
    local role
    if m[1] == "You" then role = "the one writing this"
    else
      local _, bondName = S.bond(m[1])
      local tag = S.tagged(m[1], "Healer") and "Healer" or S.tagged(m[1], "Tank") and "Tank" or nil
      role = tag and (tag .. ", " .. bondName:lower()) or bondName
    end
    U.T(role, cx, y + 46, each, "small", C.dim, "CENTER")
    if m[1] ~= "You" then U.hit(cx, y, each, 60, name(m[1]), "Click to open their page.", function() open(m[1]) end, "Companion " .. plain(m[1])) end
  end
  y = y + 66
  y = y + D().initialed(U, C, saga(j, f, lands), 14, y, W - 28, "body", C.ink or C.light) + 10
  -- four figures
  local cells = { { D().duration(n0(g.secs)), "together" }, { tostring(n0(g.quests)), n0(g.quests) == 1 and "quest" or "quests" },
    { tostring(n0(g.bosses)), n0(g.bosses) == 1 and "boss" or "bosses" },
    { tostring(n0(g.wipes) + n0(g.deaths)), (n0(g.wipes) + n0(g.deaths)) == 1 and "setback" or "setbacks" } }
  local cw = math.floor((W - 28 - 18) / 4)
  for i, c in ipairs(cells) do
    local cx = 14 + (i - 1) * (cw + 6)
    U.box(cx, y, cw, 42, C.panel)
    U.T(c[1], cx, y + 5, cw, "body", C.ink or C.light, "CENTER")
    U.T(c[2], cx, y + 24, cw, "small", C.dim, "CENTER")
  end
  y = y + 50
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
  -- the finest and darkest hours
  local fine = weightiest(moments, FINE)
  if fine then y = hourCard(R, "FINEST HOUR", fine, y) end
  local dark = weightiest(moments, DARK)
  if dark then y = hourCard(R, "DARKEST HOUR", dark, y, D().DEATH_INK) end
  -- the lands walked together
  if #lands > 0 then
    top = y
    y = D().cardTitle(R, "THE ROAD YOU SHARED", 0, y, W, #lands == 1 and "1 land" or (#lands .. " lands"))
    local most = lands[1][2]
    for i = 1, math.min(6, #lands) do
      local l = lands[i]
      U.T(l[1], 14, y, W - 120, "small", C.ink or C.light)
      if type(g.zones) == "table" then U.T(D().duration(l[2]), 14, y, W - 28, "small", C.dim, "RIGHT") end
      U.rect(14, y + 15, W - 28, 4, C.book and { 0, 0, 0, 0.1 } or { 0.05, 0.05, 0.08, 0.9 })
      U.rect(14, y + 15, math.max(2, (W - 28) * l[2] / math.max(1, most)), 4, { col[1] + 0.2, col[2] + 0.2, col[3] + 0.2, 0.9 })
      y = y + 24
    end
    y = y + 4
    U.box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
  -- the days together: the last four weeks as a calendar
  if type(g.dl) == "table" and #g.dl > 0 then
    top = y
    y = D().cardTitle(R, "DAYS TOGETHER", 0, y, W, D().plural(n0(g.days), "day"))
    local set = {}
    for _, d in ipairs(g.dl) do set[d] = true end
    local today = math.floor(now() / 86400)
    local cell = math.floor((W - 28 - 13 * 3) / 14)
    for i = 0, 27 do
      local d = today - 27 + i
      local cx = 14 + (i % 14) * (cell + 3)
      local cy = y + math.floor(i / 14) * (cell + 3)
      local lit = set[d]
      U.rect(cx, cy, cell, cell, lit and { col[1] + 0.25, col[2] + 0.25, col[3] + 0.25, 1 } or (C.book and { 0, 0, 0, 0.08 } or { 0.1, 0.1, 0.12, 0.9 }))
      if d == today then U.rect(cx, cy + cell - 2, cell, 2, C.gold) end
    end
    y = y + 2 * (cell + 3) + 2
    U.T("four weeks ago", 14, y, W - 28, "small", C.dim)
    U.T("today", 14, y, W - 28, "small", C.dim, "RIGHT")
    y = y + 20
    U.box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
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
  y = D().cardTitle(R, "WHAT YOU DID TOGETHER", 0, y, W, #moments > 0 and tostring(#moments) or nil)
  for i = 1, math.min(8, #moments) do
    local e = moments[i]
    U.icon(J.ICON[e.k] or J.ICON.quest, 14, y, 22, e.s, e.d)
    local h = U.T(e.s, 44, y + 1, W - 58, "small", C.ink or C.light)
    U.T("Day " .. D().dayOf(j, e.t) .. ", level " .. (e.l or "?"), 44, y + h + 3, W - 58, "small", C.dim)
    y = y + math.max(28, h + 22)
  end
  if #moments == 0 then y = y + U.T("Nothing written with all of you there yet.", 14, y, W - 28, "small", C.dim) + 8 end
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
  for _, f in ipairs(forming) do if f.key == chosen then pick = f end end
  pick = pick or formed[1]
  local ly = bandNow(L, y)
  local top = ly
  ly = D().cardTitle(L, "FELLOWSHIPS", 0, ly, W, #formed > 0 and tostring(#formed) or nil)
  if #formed == 0 then
    ly = ly + U.T("Travel with the same friend, or the same party, for half an hour (or meet again on another day) and you "
      .. "become a fellowship: a name, a banner, a motto and a record of everything you did together.", 14, ly, W - 28, "small", C.dim) + 8
  end
  for i, f in ipairs(formed) do
    if i > 12 then break end
    ly = ly + fellowshipRow(L, f, ly, f == pick)
  end
  if #forming > 0 then
    ly = ly + U.T("FORMING", 14, ly + 2, W - 28, "small", C.gold) + 6
  end
  for i = 1, math.min(3, #forming) do
    local f = forming[i]
    local share = math.min(1, n0(f.g.secs) / S.FORM_SECS)
    U.T(S.listText(f.names), 14, ly, W - 28, "small", C.inkSoft or C.dim)
    U.T(math.floor(share * 100) .. "%", 14, ly, W - 28, "small", C.dim, "RIGHT")
    U.rect(14, ly + 16, W - 28, 4, C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 })
    U.rect(14, ly + 16, math.max(2, (W - 28) * share), 4, C.gold)
    U.hit(10, ly - 2, W - 20, 24, S.listText(f.names), "Forming: " .. D().duration(n0(f.g.secs)) .. " of " .. D().duration(S.FORM_SECS)
      .. " together.\nClick to see it.", function() chosen = f.key; ns.ui.refresh() end, "Forming " .. S.listText(f.names))
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
    ry = ry + D().initialed(RU, RC, "No fellowship has formed yet. Travel with the same friend, or the same party, and the book raises "
      .. "your banner: a name, a motto, your finest and darkest hours, the lands you crossed and the days you met. You can rename it "
      .. "any time.", 14, ry, RW - 28, "body", RC.ink or RC.light) + 12
    D().page(RU, RC, 0, rtop, RW, ry - rtop)
    ry = ry + 12
  end
  return ly, ry
end

J.addPage("Fellowships", "Your fellowships, their banners and stories, the awards your companions have won and the group portraits.", page, "Companions")
