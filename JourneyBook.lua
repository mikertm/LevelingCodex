-- The Journey tab, drawn as an open book: a leather cover with your name, ribbons for its pages,
-- and every page laid out across a left and a right sheet of parchment (Journey.lua keeps the
-- journal itself). Pages draw into two column views (V.L, V.R) that shift their x and turn the
-- dark cards into ink on paper, so other files draw their pages the same way.
local _, ns = ...
local J = ns.journey
local Q = ns.quests
local function try(...) return Q.try(...) end
local zoneOf, here, now, level = J.zoneOf, J.here, J.now, J.level
local PIN, ICON = J.PIN, J.ICON
local ART = "Interface\\AddOns\\LevelingCodex\\media\\"

local BOOK_W = 900 -- the tab's width
local EDGE = 12 -- leather showing round the pages
local SPINE = 20 -- between the two pages
local PAD = 20 -- inside a page
local PAGE_W = (BOOK_W - 2 * EDGE - SPINE) / 2
local COL_W = PAGE_W - 2 * PAD
J.BOOK = { width = BOOK_W, page = PAGE_W, column = COL_W }

local filter = 1
local FILTERS = { "All", "Quests", "Battles", "Fortunes", "Fellowship", "Travels", "Deaths" }
local FILTER_KINDS = {
  { },
  { quest = true, chain = true, elite = true, abandon = true, milestone = true },
  { dungeon = true, boss = true, elite = true, close = true, rare = true, wipe = true, run = true, pvp = true, bg = true, duel = true,
    milestone = true },
  { first = true, upgrade = true, cap = true, craft = true, skill = true, auction = true, sold = true, expired = true, gold = true,
    mount = true },
  { pal = true, rez = true, trade = true, duel = true, emote = true, guild = true, camp = true, run = true },
  { zone = true, flight = true, start = true, camp = true, mount = true, home = true, rest = true, milestone = true },
  { death = true, close = true, wipe = true, expired = true, abandon = true },
}
local FILTER_TIPS = { "Every moment.", "Quests and the stories they finished, and the ones you gave up.",
  "Dungeons, bosses, wipes, elites, rares, close calls, duels, battlegrounds and fights with other players.",
  "Firsts, gear upgrades, crafting, professions, the auction house, your purse and your first mount.",
  "Companions, dungeon parties, resurrections, trades, duels, waves and campfires.",
  "New lands, flight paths, inns, new homes, campfires and the miles behind you.", "Every fall, wipe, near miss and lost cause." }
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

----------------------------------------------------------------------------
-- Paper, ink and leather
----------------------------------------------------------------------------

-- Draw layers inside the book (BACKGROUND sublevels; the pages' own drawing sits at 0 and above):
local L_LEATHER, L_GRAIN, L_STACK, L_PAPER, L_FIBRE, L_SHADE, L_PANEL = -8, -7, -6, -5, -4, -3, -2

-- One of the book's art files at (x, y, w, h), tinted; false (and hidden) when the file is missing.
-- tile repeats a 256 px file at its own size; coords = { l, r, t, b }.
local function art(U, file, x, y, w, h, color, sub, tile, coords)
  if ns.C.eui then return false end
  local t = U.rect(x, y, w, h, color, nil, sub, "journeyArt")
  local ok = t:SetTexture(ART .. file, tile and "REPEAT" or nil, tile and "REPEAT" or nil)
  if ok == false then t:Hide(); return false end
  if tile then t:SetTexCoord(0, w / 256, 0, h / 256)
  elseif coords then t:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  else t:SetTexCoord(0, 1, 0, 1) end
  t:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
  return t
end

-- A 1 px frame round (x, y, w, h).
local function frame(U, x, y, w, h, c, sub)
  U.rect(x, y, w, 1, c, "border", sub); U.rect(x, y + h - 1, w, 1, c, "border", sub)
  U.rect(x, y, 1, h, c, "border", sub); U.rect(x + w - 1, y, 1, h, c, "border", sub)
end

-- The page's inks: what a dark card wrote in light colours writes in ink on parchment. external UI's
-- "parchment" is a dark panel with light ink, so there the light colours stay.
local function inkPalette(C)
  local P = setmetatable({ book = true }, { __index = C })
  local ink, soft = C.ink or C.light, C.inkSoft or C.dim
  P.light, P.dim = ink, soft
  if not C.eui then
    local g = C.gold
    P.gold = { g[1] * 0.55, g[2] * 0.55, g[3] * 0.55, 1 }
    P.green = { 0.12, 0.45, 0.12 }
  end
  P.edge = { ink[1], ink[2], ink[3], 0.45 }
  P.edgeSoft = { ink[1], ink[2], ink[3], 0.22 }
  P.wash = { ink[1], ink[2], ink[3], 0.1 }
  return P
end

-- A colour made for dark cards (class colours, item qualities), darkened to read on paper.
local function readable(C, c)
  if C.eui or type(c) ~= "table" then return c end
  return { c[1] * 0.6, c[2] * 0.6, c[3] * 0.6, c[4] or 1 }
end

-- A card on the page: a parchment card becomes a framed passage (a double rule), a dark one a light
-- ink wash with a rule round it.
local function panel(U, P, x, y, w, h, fill, edge)
  local ink = P.ink or P.light
  if fill == P.parch then
    frame(U, x, y, w, h, { ink[1], ink[2], ink[3], 0.3 }, -7)
    frame(U, x + 3, y + 3, w - 6, h - 6, { ink[1], ink[2], ink[3], 0.12 }, -7)
    return
  end
  local a = (fill == P.btnOn and 0.14) or (fill == P.btnOff and 0.04) or 0.07
  U.rect(x, y, w, h, { ink[1], ink[2], ink[3], a }, nil, L_PANEL)
  frame(U, x, y, w, h, edge == P.gold and P.gold or { ink[1], ink[2], ink[3], 0.28 }, -7)
end

-- The flourish under a heading, centred in w (a rule and a diamond without the art).
local function ornament(U, P, x, y, w)
  local ow = math.min(w, 340)
  local ink = P.ink or P.light
  local c = { ink[1], ink[2], ink[3], 0.7 }
  if art(U, "journey-ornament.tga", x + (w - ow) / 2, y, ow, math.floor(ow * 38 / 512), c, L_SHADE, false,
      { 0, 1, 0.2, 0.8 }) then
    return math.floor(ow * 38 / 512)
  end
  U.rect(x + (w - ow) / 2, y + 8, ow, 1, { ink[1], ink[2], ink[3], 0.4 }, "border")
  local g = U.rect(x + w / 2 - 4, y + 5, 7, 7, c, "border", nil, "gem")
  if g.SetRotation then g:SetRotation(math.rad(45)) end
  return 18
end

-- A column of the book: the window's drawing helpers shifted by ox, W = the column's width, the
-- ink palette, and cards drawn as panels. Returns a view like V (U, C, W) for the page code.
local function column(V, P, ox, w)
  local U = V.U
  local X = setmetatable({ W = w }, { __index = U })
  X.T = function(s, x, ...) return U.T(s, x + ox, ...) end
  X.rect = function(x, ...) return U.rect(x + ox, ...) end
  X.icon = function(name, x, ...) return U.icon(name, x + ox, ...) end
  X.btn = function(label, x, ...) return U.btn(label, x + ox, ...) end
  X.hit = function(x, ...) return U.hit(x + ox, ...) end
  X.check = function(label, x, ...) return U.check(label, x + ox, ...) end
  X.segments = function(x, ...) return U.segments(x + ox, ...) end
  X.playerPortrait = function(x, ...) return U.playerPortrait(x + ox, ...) end
  X.picture = function(path, x, ...) return U.picture(path, x + ox, ...) end
  X.box = function(x, y, bw, bh, fill, edge) panel(U, P, x + ox, y, bw, bh, fill, edge) end
  X.plate, X.surface = X.box, X.box
  -- a heading in the middle of the column with the flourish under it; returns the space it takes
  X.sectionTitle = function(str, y, sub)
    local h = U.T(str, ox, y, w, "head", P.ink or P.light, "CENTER")
    local oh = ornament(U, P, ox, y + h + 2, w)
    local used = h + oh + 8
    if sub then used = used + U.T(sub, ox, y + used - 4, w, "small", P.dim, "CENTER") + 4 end
    return used
  end
  return setmetatable({ U = X, C = P, W = w, x = ox, book = true }, { __index = V })
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

-- A framed passage on the page (other files call it as J.draw.page).
local function page(U, C, x, y, w, h)
  U.box(x, y, w, h, C.parch)
end

-- The pages of the journal, one spread at a time. Other files add pages with
-- J.addPage(name, tip, draw, after): draw(V, y) draws into V.L and V.R (column views) from y and
-- returns the bottom of each (ly, ry); a page's `pre(V, y) -> y` draws across the book above them.
local PAGES = {
  { name = "Overview", tip = "Your journey at a glance: today's entry, the numbers, the road, the latest chapter and where you are." },
  { name = "Story", tip = "Every chapter of your story, level by level, each with its own map." },
  { name = "Map", tip = "Your trail on every land you have walked, and the lands explored." },
  { name = "Trophies", tip = "Your firsts, your nemeses, close calls, rares, bosses, upgrades, crafts and the ledger." },
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

-- A line of lore for a land (JourneyLore.lua), or nil.
local function lore(name)
  return J.lore and J.lore.zoneLine and J.lore.zoneLine(name) or nil
end

-- The map plate at (mx, my, mw x mh): art or a gridded parchment, the trail, you and the pins.
local function drawPlate(V, map, mx, my, mw, mh, pinSize, onlyLevel)
  local U, C, j = V.U, V.C, V.j
  local ink = C.ink or C.light
  U.rect(mx - 4, my - 4, mw + 8, mh + 8, { ink[1], ink[2], ink[3], 0.55 }, "border", -5)
  U.rect(mx - 3, my - 3, mw + 6, mh + 6, { 0, 0, 0, 1 }, "border", -5)
  U.rect(mx - 1, my - 1, mw + 2, mh + 2, C.book and { 0.75, 0.62, 0.38, 1 } or C.edgeSoft, "border", -4)
  if not mapArt(U, C, map, mx, my, mw, mh) then
    U.rect(mx, my, mw, mh, C.parch, "border", -3)
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
    local gold = ns.C.gold
    disc(U, cx - 8, cy - 8, 16, { 0, 0, 0, 0.8 }, nil, "journeyRing", true)
    disc(U, cx - 5, cy - 5, 10, { gold[1], gold[2], gold[3], 1 }, 1, "journeyRing", true)
    U.T("You", cx + 8, cy - 7, 40, "small", gold, nil, true)
    U.hit(cx - 8, cy - 8, 16, 16, "You are here", nil, nil, "You are here")
  end
  for _, e in ipairs(J.pinsOn(map, onlyLevel)) do
    local file = PIN[e.k]
    local big = highlight == e
    if file or big then
      local size = big and pinSize + 8 or pinSize
      local px, py = mx + e.x / 100 * mw - size / 2, my + e.y / 100 * mh - size / 2
      local gold = ns.C.gold
      if big then disc(U, px - 4, py - 4, size + 8, { gold[1], gold[2], gold[3], 0.6 }, nil, "journeyRing", true) end
      pinArt(U, ns.C, file or PIN.level, px, py, size)
      U.hit(px, py, size, size, e.s, "Level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t), nil, "Pin " .. e.s)
    end
  end
end

-- The map's key: the level bands, then the pins (on two lines when narrow).
local function legend(V, x, y, w)
  local U, C = V.U, V.C
  local lx = x
  for _, b in ipairs(J.BANDS) do
    disc(U, lx, y + 2, 10, b[3], nil, "journeyDot")
    U.T(b[4], lx + 13, y + 1, 44, "small", C.dim)
    lx = lx + 56
  end
  local narrow = w < 500
  local kx, ky = narrow and x or (x + w - 150), narrow and (y + 18) or y
  for _, k in ipairs({ { "level", "level up" }, { "death", "fell" }, { "boss", "boss" }, { "close", "close call" } }) do
    if narrow or k[1] == "level" or k[1] == "death" then
      pinArt(U, C, PIN[k[1]], kx, ky, 14)
      U.T(k[2], kx + 18, ky + 1, 70, "small", C.dim)
      kx = kx + 84
    end
  end
  return narrow and 40 or 22
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

-- A paragraph opened by a large initial (the rest hangs beside it); returns its height.
local function initialed(U, C, text, x, y, w, kind, color)
  text = Q.plain(text or "")
  local first, rest = text:match("^(%a)(.+)$")
  if not first then return U.T(text, x, y, w, kind or "body", color or C.ink) end
  local ch, fs = U.T(first, x, y - 3, 34, "title", C.gold)
  local cw = math.max(14, math.min(30, tonumber(fs and fs.GetStringWidth and fs:GetStringWidth()) or 18))
  local h = U.T(rest, x + cw + 3, y + 1, w - cw - 3, kind or "body", color or C.ink)
  return math.max(ch - 2, h + 1)
end

-- One chapter at (x, y), w wide, showing up to limit moments; nil when the filter leaves it empty.
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
  local ix, iw = x + 14, w - 28
  U.rect(x, y, w, 3, { band[1], band[2], band[3], 0.85 }, "border", 3)
  U.T("CHAPTER " .. roman(l), ix, y + 12, iw, "label", C.inkSoft)
  local first, latest
  for _, e in ipairs(events) do
    first = (not first or (tonumber(e.t) or 0) < first) and tonumber(e.t) or first
    latest = (not latest or (tonumber(e.t) or 0) > latest) and tonumber(e.t) or latest
  end
  if l == lvl then
    U.T("you are here", ix, y + 12, iw, "small", C.inkSoft, "RIGHT")
  elseif first then
    local d1, d2 = dayOf(j, first), dayOf(j, latest)
    U.T(d1 == d2 and ("day " .. d1) or ("days " .. d1 .. "-" .. d2), ix, y + 12, iw, "small", C.inkSoft, "RIGHT")
  end
  y = y + 28
  y = y + U.T("Level " .. l .. (best and ("  -  " .. best) or ""), ix, y, iw, "head", C.ink) + 4
  -- the land's own line opens the chapter where you first reached it
  local tale
  if not compact and best then
    for _, z in pairs(j.zones) do
      if type(z) == "table" and z.name == best and tonumber(z.level) == l then tale = lore(best) end
    end
  end
  if tale then y = y + U.T(tale, ix, y, iw, "small", C.inkSoft) + 6 end
  -- the plate floats right of the epigraph and the chapter's prose
  local plateMap, plateBottom = not compact and chapterMap(j, l, events), nil
  local hw = iw
  if plateMap then
    local pw = 148
    local ph = math.floor(pw * 668 / 1002)
    local px, py = x + w - 14 - pw, y + 4
    drawPlate(V, plateMap, px, py, pw, ph, 9, l)
    U.hit(px, py, pw, ph, mapLabel(j, plateMap) .. " at level " .. l, "Click to open it on the map.", function()
      mapPick, highlight = plateMap, nil
      openPage(P_MAP, U)
    end, "Plate level " .. l)
    U.T(mapLabel(j, plateMap), px, py + ph + 6, pw, "small", C.inkSoft, "CENTER")
    plateBottom = py + ph + 22
    hw = iw - pw - 12
  end
  y = y + 2
  if opening then
    y = y + U.T('"' .. opening.s .. '"', ix, y, hw, compact and "small" or "body", C.inkSoft) + 8
  end
  if not compact then
    local prose = J.lore and J.lore.chapterProse and J.lore.chapterProse(l, events, rec, l == lvl)
    if prose and prose ~= "" then y = y + initialed(U, C, prose, ix, y, hw, "small", C.ink) + 8 end
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
  local textW = iw - 32 - (compact and 0 or 52)
  for _, e in ipairs(order) do
    if drawn >= limit then break end
    drawn = drawn + 1
    spineTop = spineTop or (y + 10)
    spineEnd = y + 10
    U.icon(ICON[e.k] or ICON.quest, ix, y, 22, e.s, e.d)
    local th = U.T(e.s, ix + 30, y + 3, textW, compact and "small" or "body", e.k == "death" and DEATH_INK or C.ink)
    local day = dayOf(j, e.t)
    if not compact and day ~= lastDay then U.T("day " .. day, x + w - 66, y + 4, 52, "small", C.inkSoft, "RIGHT") end
    lastDay = day
    local rowH = math.max(24, th + 6)
    if e.d and not compact then rowH = rowH + U.T(e.d, ix + 30, y + th + 5, textW, "small", C.inkSoft) + 2 end
    if e.m and e.x then
      U.hit(x + 10, y - 2, w - 20, rowH + 2, e.s, (e.d and (e.d .. "\n") or "") .. "Click to show where it happened.", function()
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
    y = y + U.T("... and " .. plural(#list - drawn, "more moment") .. " in this chapter (Read the whole story).", ix + 30, y,
      iw - 30, "small", C.inkSoft) + 6
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
  if C.book then nameColor = readable(C, nameColor) end
  if token then U.icon("classicon_" .. token:lower(), x, y, 22, cls, nil) end
  local secs = tonumber(p.rec.seconds) or 0
  local together = secs < 60 and "just met" or (duration(secs) .. " together")
  local track = C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 }
  U.T(Q.plain(p.name), x + 30, y + 1, w - 150, "body", nameColor)
  U.T(together, x + 30, y + 1, w - 30, "small", C.light, "RIGHT")
  if compact then
    U.rect(x + 30, y + 18, w - 30, 4, track)
    U.rect(x + 30, y + 18, math.max(2, (w - 30) * secs / most), 4, nameColor)
    return 30
  end
  U.T(cls .. (p.rec.level and ("  -  met at level " .. p.rec.level) or ""), x + 30, y + 17, w - 30, "small", C.dim)
  U.rect(x + 30, y + 33, w - 30, 4, track)
  U.rect(x + 30, y + 33, math.max(2, (w - 30) * secs / most), 4, nameColor)
  return 44
end

-- A card's gold label (and an optional note on the right); returns the y its content starts at.
local function cardTitle(V, title, x, y, w, right)
  V.U.T(title, x + 14, y + 10, w - 28, "label", V.C.gold)
  if right then V.U.T(right, x + 14, y + 10, w - 28, "small", V.C.light, "RIGHT") end
  return y + 30
end

----------------------------------------------------------------------------
-- The cover, the ribbons and the spread
----------------------------------------------------------------------------

-- The leather band over the pages: who you are, where, and the chapter you're in.
local function cover(V)
  local U, C, W, j, lvl = V.U, V.C, V.W, V.j, V.lvl
  local gold = C.gold
  local tool = { gold[1], gold[2], gold[3], 0.55 }
  frame(U, 6, 6, W - 12, 100, tool, -6)
  frame(U, 9, 9, W - 18, 94, { gold[1], gold[2], gold[3], 0.2 }, -6)
  U.rect(20, 18, 76, 76, gold, "border", 2)
  U.rect(22, 20, 72, 72, { 0, 0, 0, 1 }, "border", 3)
  U.playerPortrait(24, 22, 68, select(2, try(UnitClass, "player")) or "WARRIOR", true)
  U.T("THE JOURNEY OF", 112, 20, 420, "label", gold)
  U.T(V.name:upper(), 112, 34, 420, "title", C.titleInk or C.light)
  local rule = U.rect(112, 66, 300, 1, { 1, 1, 1, 1 }, "border", 3, "fade")
  ns.fade(rule, "HORIZONTAL", gold[1], gold[2], gold[3], 0.7, 0)
  U.T((V.race ~= "" and (V.race .. " ") or "") .. V.className .. ", level " .. lvl
    .. (V.curName and ("  -  now in " .. V.curName) or ""), 112, 72, 420, "small", C.light)
  U.T("Day " .. dayOf(j, now()) .. ", " .. plural(#j.events, "moment") .. " written", 112, 86, 420, "small", C.dim)
  -- a line about the land you stand in, like a book's epigraph
  local tale = V.curName and lore(V.curName)
  if tale then
    U.T(V.curName:upper(), 548, 24, 210, "label", gold, "CENTER")
    U.T(tale, 548, 40, 210, "small", C.dim, "CENTER")
  end
  -- the chapter you're in, set large on the right like a book's running head
  U.rect(W - 128, 20, 1, 72, { gold[1], gold[2], gold[3], 0.35 }, "border", 3)
  U.T("CHAPTER", W - 120, 22, 104, "label", C.dim, "CENTER")
  U.T(roman(lvl), W - 120, 38, 104, "title", gold, "CENTER")
  U.T(lvl >= 60 and "the summit" or "of 60", W - 120, 72, 104, "small", C.dim, "CENTER")
  local y = 116
  if ns.settingsLost then
    y = y + U.T("Forever didn't load your saved journal: this chapter of the story starts at this login.", EDGE, y,
      W - 2 * EDGE, "small", C.dim, "CENTER") + 6
  end
  return y
end

-- The ribbons: one per page of the book.
local function ribbons(V, y)
  local U = V.U
  local names, tips, lit = {}, {}, 1
  for i, p in ipairs(PAGES) do
    names[i], tips[i] = p.name, p.tip
    if p.name == pageName then lit = i end
  end
  return y + U.segments(EDGE, y, V.W - 2 * EDGE, names, lit, function(i) openPage(PAGES[i].name, U) end, tips) + 8, lit
end

-- One sheet of the spread at (x, y), PAGE_W x h; side "left" or "right".
local function sheet(V, P, x, y, h, side)
  local U = V.U
  local w = PAGE_W
  local parch = P.parch
  -- the edges of the pages beneath it, along the outer side and the bottom
  for i = 3, 1, -1 do
    local shade = 0.86 - i * 0.07
    local sx = side == "left" and (x - i * 2) or x
    U.rect(sx, y + i, w + i * 2, h, { parch[1] * shade, parch[2] * shade, parch[3] * shade, 1 }, nil, L_STACK)
  end
  U.rect(x, y, w, h, parch, nil, L_PAPER)
  art(U, "journey-paper.tga", x, y, w, h, { parch[1], parch[2], parch[3], 1 }, L_FIBRE)
  -- the curve into the spine
  local shade = U.rect(side == "left" and (x + w - 34) or x, y, 34, h, { 1, 1, 1, 1 }, nil, L_SHADE, "fade")
  if side == "left" then ns.fade(shade, "HORIZONTAL", 0, 0, 0, 0, 0.22)
  else ns.fade(shade, "HORIZONTAL", 0, 0, 0, 0.26, 0) end
  local ink = P.ink or P.light
  frame(U, x, y, w, h, { ink[1], ink[2], ink[3], 0.35 }, -6)
  -- page corners
  local c = { ink[1], ink[2], ink[3], 0.4 }
  local s = 36
  art(U, "journey-corner.tga", x + 6, y + 6, s, s, c, L_SHADE, false, { 0, 1, 0, 1 })
  art(U, "journey-corner.tga", x + w - 6 - s, y + 6, s, s, c, L_SHADE, false, { 1, 0, 0, 1 })
  art(U, "journey-corner.tga", x + 6, y + h - 6 - s, s, s, c, L_SHADE, false, { 0, 1, 1, 0 })
  art(U, "journey-corner.tga", x + w - 6 - s, y + h - 6 - s, s, s, c, L_SHADE, false, { 1, 0, 1, 0 })
end

-- Whatever goes up on the cover's leather (drawn last, under everything).
local function leather(V, h)
  local U, C = V.U, V.C
  local base = C.bg or C.panel
  local hide = { math.min(1, base[1] * 1.6 + 0.04), math.min(1, base[2] * 1.4 + 0.03), math.min(1, base[3] * 1.3 + 0.02), 1 }
  U.rect(0, 0, V.W, h, hide, nil, L_LEATHER)
  art(U, "journey-leather.tga", 0, 0, V.W, h, { math.min(1, hide[1] * 1.35), math.min(1, hide[2] * 1.35), math.min(1, hide[3] * 1.35), 1 },
    L_GRAIN, true)
  local edge = U.rect(0, 0, V.W, 14, { 1, 1, 1, 1 }, nil, L_STACK, "fade")
  ns.fade(edge, "VERTICAL", 0, 0, 0, 0, 0.35)
  frame(U, 0, 0, V.W, h, { 0, 0, 0, 0.8 }, -8)
end

-- Flowing sections into the shorter column, so a page fills both sheets: each is fn(CV, y) -> y.
local function flow(V, y, sections)
  local ly, ry = y, y
  for _, fn in ipairs(sections) do
    if ly <= ry then ly = fn(V.L, ly) + 12 else ry = fn(V.R, ry) + 12 end
  end
  return ly, ry
end

----------------------------------------------------------------------------
-- Page: Overview
----------------------------------------------------------------------------

-- Today's entry: this session in a few sentences, like a diary page.
local function todayCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local D = J.deeds
  if not D then return y end
  local top = y
  U.icon("INV_Feather_05", 14, y + 12, 30, "Today's entry", "Written from what happened since you logged in.")
  U.T("TODAY'S ENTRY", 54, y + 12, W - 68, "label", C.inkSoft)
  U.T("day " .. dayOf(j, now()), 54, y + 12, W - 68, "small", C.inkSoft, "RIGHT")
  local h = initialed(U, C, D.today(), 54, y + 30, W - 68, "body", C.ink)
  y = y + 30 + math.max(h, 18) + 14
  page(U, C, 0, top, W, y - top)
  return y + 12
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
  local per = W >= 560 and 6 or 3
  local gap = 8
  local sw = math.floor((W - (per - 1) * gap) / per)
  for i, s in ipairs(list) do
    local sx = ((i - 1) % per) * (sw + gap)
    local sy = y + math.floor((i - 1) / per) * 74
    U.box(sx, sy, sw, 66, C.panel, C.edge)
    -- a wax seal under the icon
    if C.book and not C.eui then disc(U, sx + math.floor(sw / 2) - 16, sy + 3, 32, { 0.5, 0.1, 0.08, 0.85 }, 0, "journeyDot") end
    U.icon(s[1], sx + math.floor(sw / 2) - 11, sy + 8, 22, s[3]:sub(1, 1):upper() .. s[3]:sub(2), s[4])
    U.T(s[2], sx + 4, sy + 37, sw - 8, "head", C.gold, "CENTER")
    U.T(s[3], sx + 4, sy + 53, sw - 8, "small", C.dim, "CENTER")
  end
  return y + math.ceil(#list / per) * 74 + 4
end

-- The road from 1 to 60: one notch per level, coloured by band, a star over your level.
local function road(V, y)
  local U, C, W, lvl = V.U, V.C, V.W, V.lvl
  local roadH = 66
  U.box(0, y, W, roadH, C.panel, C.edge)
  cardTitle(V, "THE ROAD TO 60", 0, y - 2, W,
    lvl >= 60 and "the summit reached" or ("level " .. lvl .. ", " .. (60 - lvl) .. " to go"))
  local rx, rw = 14, W - 28
  local notch = rw / 60
  local ny = y + 34
  for l = 1, 60 do
    local c = J.bandColor(l)
    local nx = rx + (l - 1) * notch
    local reached = l <= lvl
    local tall = l == lvl and 4 or 0
    U.rect(nx + 0.5, ny - tall / 2, math.max(1, notch - 1.5), 10 + tall, reached and { c[1], c[2], c[3], l == lvl and 1 or 0.85 }
      or { c[1], c[2], c[3], 0.2 })
    local rec = ns.stats and ns.stats.levelRecord(l)
    local tip = rec and (duration(rec.seconds) .. " on this level, " .. plural(tonumber(rec.quests) or 0, "quest")
      .. ", " .. plural(tonumber(rec.kills) or 0, "kill") .. ", " .. plural(tonumber(rec.deaths) or 0, "death"))
      or (l == lvl and "You are here." or reached and "Before the journal began." or "Still ahead.")
    U.hit(nx, ny - 6, math.max(2, notch), 22, "Level " .. l, tip, nil, "Road level " .. l)
  end
  pinArt(U, C, PIN.level, rx + (lvl - 0.5) * notch - 8, ny - 19, 16)
  for l = 10, 60, 10 do U.T(tostring(l), rx + (l - 0.5) * notch - 10, ny + 14, 20, "small", l <= lvl and C.light or C.dim, "CENTER") end
  return y + roadH + 12
end

-- Where you stand: a plate of the map you are on.
local function whereCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local maps = mapList(j)
  local curMap = Q.position()
  local show
  for _, m in ipairs(maps) do if m == curMap then show = m end end
  show = show or maps[#maps]
  local top = y
  y = cardTitle(V, "WHERE YOU ARE", 0, y, W, #maps > 0 and plural(#maps, "land") or nil)
  if show then
    U.T(mapLabel(j, show), 14, y - 4, W - 28, "body", C.ink)
    y = y + 18
    local mw = W - 28
    local mh = math.floor(mw * 668 / 1002)
    drawPlate(V, show, 14, y, mw, mh, 10)
    y = y + mh + 10
    U.btn("Open the map", 14, y, 130, function() mapPick, highlight = show, nil; openPage(P_MAP, U) end, false,
      "Your whole trail, land by land.")
    y = y + 32
  else
    y = y + U.T("Your trail appears here as you travel.", 14, y, W - 28, "small", C.dim) + 10
  end
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local function palsCard(V, y, limit)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local pals = palList(j)
  local top = y
  y = cardTitle(V, "FELLOW ADVENTURERS", 0, y, W, #pals > 0 and tostring(#pals) or nil)
  if #pals == 0 then
    y = y + U.T("Nobody has shared the road with you yet.", 14, y, W - 28, "small", C.dim) + 8
  else
    local most = math.max(60, tonumber(pals[1].rec.seconds) or 60)
    for i = 1, math.min(limit, #pals) do y = y + palRow(V, pals[i], most, 14, y, W - 28, true) end
    if #pals > limit then
      U.btn("All companions", 14, y, 130, function() openPage(P_COMPANIONS, U) end, false)
      y = y + 30
    end
  end
  y = y + 4
  U.box(0, top, W, y - top, C.panel, C.edge)
  return y + 12
end

local function overviewPage(V, y)
  local L, R, j = V.L, V.R, V.j
  -- left: today, the seals and where you are
  local ly = todayCard(L, y)
  ly = seals(L, ly)
  ly = whereCard(L, ly)
  -- right: the road, the latest chapter read in full, then your companions
  local ry = road(R, y)
  local kept = filter
  filter = 1
  local chapters, byLevel = chapterData(j)
  local l = chapters[1]
  if l then ry = drawChapter(R, l, byLevel[l], 0, ry, R.W, 6, false) or ry end
  filter = kept
  if not l then
    page(R.U, R.C, 0, ry, R.W, 80)
    R.U.T("The first page is still blank. Your story is written here as you go.", 16, ry + 16, R.W - 32, "body", R.C.ink)
    ry = ry + 80
  end
  ry = ry + 8
  R.U.btn("Read the story", 0, ry, 150, function() openPage(P_STORY, R.U) end, false, "Every chapter, level by level.")
  if #chapters > 1 then R.U.T(plural(#chapters, "chapter") .. " so far", 160, ry + 6, R.W - 160, "small", R.C.dim) end
  ry = ry + 34
  ry = palsCard(R, ry, 4)
  return ly, ry
end

----------------------------------------------------------------------------
-- Page: Map
----------------------------------------------------------------------------
local function mapPage(V, y)
  local L, R, j = V.L, V.R, V.j
  local maps = mapList(j)
  local curMap = Q.position()
  if not mapPick then
    for _, m in ipairs(maps) do if m == curMap then mapPick = m end end
    mapPick = mapPick or maps[#maps]
  end
  local idx = 1
  for i, m in ipairs(maps) do if m == mapPick then idx = i end end

  -- left: the map itself, its key and the journal's switches
  local U, C, W = L.U, L.C, L.W
  local top, ly = y, y
  ly = cardTitle(L, "THE MAP", 0, ly, W)
  if #maps == 0 then
    ly = ly + U.T("Your trail appears here as you travel: every road you walk, coloured by your level, with stars where you grew stronger and skulls where you fell.",
      14, ly, W - 28, "small", C.dim) + 10
  else
    U.btn("<", 14, ly, 28, function() mapPick = maps[(idx - 2) % #maps + 1]; highlight = nil; U.refresh() end, false,
      "The previous land on your journey.")
    U.T(mapLabel(j, mapPick), 46, ly - 1, W - 92, "head", C.ink, "CENTER")
    local zrec = j.zones[mapPick]
    U.T((zrec and zrec.level and ("first reached at level " .. zrec.level .. ", day " .. dayOf(j, zrec.first) .. "  -  ") or "")
      .. "land " .. idx .. " of " .. #maps, 46, ly + 21, W - 92, "small", C.dim, "CENTER")
    U.btn(">", W - 42, ly, 28, function() mapPick = maps[idx % #maps + 1]; highlight = nil; U.refresh() end, false,
      "The next land on your journey.")
    ly = ly + 42
    local mw = W - 28
    local mh = math.floor(mw * 668 / 1002)
    drawPlate(L, mapPick, 14, ly, mw, mh, 13)
    ly = ly + mh + 10
    ly = ly + legend(L, 14, ly, W - 28)
  end
  U.box(0, top, W, ly - top, C.panel, C.edge)
  ly = ly + 12
  top = ly
  ly = cardTitle(L, "YOUR JOURNAL", 0, ly, W)
  U.check("Show my trail on the world map", 14, ly, not ns.db().noJourneyMap, function()
    local db = LevelingCodexDB
    if type(db) == "table" then db.noJourneyMap = not db.noJourneyMap or nil end
    J.drawWorld(true)
    U.refresh()
  end, "Draws your trail, level stars and skulls on the world map you have open.")
  ly = ly + 28
  U.check("Record my trail", 14, ly, not ns.db().noJourneyTrail, function()
    local db = LevelingCodexDB
    if type(db) == "table" then db.noJourneyTrail = not db.noJourneyTrail or nil end
    J.resetSample()
    U.refresh()
  end, "Keeps a breadcrumb every 35 yards you walk. The journal's moments are written either way.")
  ly = ly + 30
  local armed = confirmReset and GetTime() - (confirmAt or 0) < 5
  U.btn(armed and "Click again to erase" or "Erase the journal", 14, ly, 180, function()
    if confirmReset and GetTime() - (confirmAt or 0) < 5 then
      confirmReset, mapPick, highlight = nil, nil, nil
      J.reset()
      ns.say("journal erased: a fresh page.")
    else
      confirmReset, confirmAt = true, GetTime()
    end
    U.refresh()
  end, armed, "Erases every moment and your whole trail. Click twice to confirm.")
  ly = ly + 26
  ly = ly + U.T("Two clicks erase every moment and the whole trail.", 14, ly, W - 28, "small", C.dim) + 8
  U.box(0, top, W, ly - top, C.panel, C.edge)
  ly = ly + 12

  -- right: about the land on the map, then every land as a chip
  U, C, W = R.U, R.C, R.W
  local ry = y
  if mapPick then
    top = ry
    local name = mapLabel(j, mapPick)
    ry = ry + 12
    ry = ry + R.U.sectionTitle(name:upper(), ry)
    local tale = lore(name)
    if tale then ry = ry + U.T(tale, 14, ry, W - 28, "body", C.inkSoft, "CENTER") + 10 end
    -- what happened here
    local n, deaths, levels, quests, bosses = 0, 0, 0, 0, 0
    for _, e in ipairs(j.events) do
      if e.m and select(2, zoneOf(e.m)) == name or e.m == mapPick then
        n = n + 1
        if e.k == "death" then deaths = deaths + 1 elseif e.k == "level" then levels = levels + 1
        elseif e.k == "quest" or e.k == "chain" or e.k == "elite" then quests = quests + 1
        elseif e.k == "boss" or e.k == "rare" then bosses = bosses + 1 end
      end
    end
    local zrec = j.zones[mapPick]
    local facts = {
      { "First reached", zrec and zrec.level and ("level " .. zrec.level .. ", day " .. dayOf(j, zrec.first)) or "before the journal" },
      { "Moments written here", tostring(n) }, { "Quests finished", tostring(quests) }, { "Levels gained", tostring(levels) },
      { "Great foes felled", tostring(bosses) }, { "Falls", tostring(deaths) },
    }
    for _, f in ipairs(facts) do
      U.T(f[1], 14, ry, W - 28, "small", C.inkSoft)
      U.T(f[2], 14, ry, W - 28, "small", C.ink, "RIGHT")
      U.rect(14, ry + 15, W - 28, 1, { 0, 0, 0, 0.08 }, "border")
      ry = ry + 20
    end
    ry = ry + 8
    page(U, C, 0, top, W, ry - top)
    ry = ry + 12
  end
  if #maps > 0 then
    top = ry
    ry = cardTitle(R, "LANDS EXPLORED", 0, ry, W, plural(#maps, "land"))
    local cols, gap = 2, 8
    local cw = math.floor((W - 28 - (cols - 1) * gap) / cols)
    for i, m in ipairs(maps) do
      local cx = 14 + ((i - 1) % cols) * (cw + gap)
      local cy = ry + math.floor((i - 1) / cols) * 46
      local lit = m == mapPick
      local zrec = j.zones[m]
      local band = J.bandColor(zrec and zrec.level or 1)
      U.box(cx, cy, cw, 40, lit and C.btnOn or C.btnOff, lit and C.gold or C.edgeSoft)
      U.rect(cx + 1, cy + 1, 3, 38, { band[1], band[2], band[3], 1 }, "border", 3)
      U.T(mapLabel(j, m), cx + 10, cy + 5, cw - 16, "body", lit and C.gold or C.ink)
      U.T(zrec and zrec.level and ("level " .. zrec.level .. ", day " .. dayOf(j, zrec.first)) or "passed through",
        cx + 10, cy + 22, cw - 16, "small", C.dim)
      U.hit(cx, cy, cw, 40, mapLabel(j, m), "Show your trail here.", function() mapPick, highlight = m, nil; U.refreshTop() end,
        "Land " .. mapLabel(j, m))
    end
    ry = ry + math.ceil(#maps / cols) * 46 + 6
    U.box(0, top, W, ry - top, C.panel, C.edge)
    ry = ry + 12
  end
  return ly, ry
end

----------------------------------------------------------------------------
-- Page: Story
----------------------------------------------------------------------------
local function storyFilters(V, y)
  return y + V.U.segments(EDGE, y, V.W - 2 * EDGE, FILTERS, filter, function(i) filter = i; V.U.refresh() end, FILTER_TIPS) + 8
end

local function storyPage(V, y)
  local L, R, j = V.L, V.R, V.j
  local ly = y + L.U.sectionTitle("THE STORY SO FAR", y)
  local ry = y
  local chapters, byLevel = chapterData(j)
  -- the right page opens with the book's own preface
  local lines = J.lore and J.lore.preface and J.lore.preface(j, V) or nil
  if lines then
    local top = ry
    ry = ry + 14
    ry = ry + initialed(R.U, R.C, lines, 14, ry, R.W - 28, "body", R.C.ink) + 12
    page(R.U, R.C, 0, top, R.W, ry - top)
    ry = ry + 12
  end
  if #chapters == 0 then
    page(L.U, L.C, 0, ly, L.W, 70)
    L.U.T("The first page is still blank. Your story is written here as you go: every level, every land, every quest and every fall.",
      16, ly + 14, L.W - 32, "body", L.C.ink)
    ly = ly + 78
  end
  local shown = 0
  for _, l in ipairs(chapters) do
    if shown >= 4 and not showAll then break end
    local onLeft = ly <= ry
    local CV = onLeft and L or R
    local ny = drawChapter(CV, l, byLevel[l], 0, onLeft and ly or ry, CV.W, showAll and 999 or 8)
    if ny then
      shown = shown + 1
      if onLeft then ly = ny + 12 else ry = ny + 12 end
    end
  end
  if #chapters > 4 or showAll then
    local CV = ly <= ry and L or R
    local by = ly <= ry and ly or ry
    CV.U.btn(showAll and "Show the last chapters" or "Read the whole story", 0, by, 200, function()
      showAll = not showAll
      CV.U.refresh()
    end, showAll)
    if CV == L then ly = by + 32 else ry = by + 32 end
  end
  return ly, ry
end

----------------------------------------------------------------------------
-- Page: Companions
----------------------------------------------------------------------------
local function companionsPage(V, y)
  local L, R, j = V.L, V.R, V.j
  local U, C, W = L.U, L.C, L.W
  local pals = palList(j)
  local top, ly = y, y
  local total = 0
  for _, p in ipairs(pals) do total = total + (tonumber(p.rec.seconds) or 0) end
  ly = cardTitle(L, "FELLOW ADVENTURERS", 0, ly, W, #pals > 0 and plural(#pals, "companion") or nil)
  if total >= 60 then ly = ly + U.T(duration(total) .. " in good company", 14, ly - 6, W - 28, "small", C.dim) + 4 end
  if #pals == 0 then
    ly = ly + U.T("Nobody has shared the road with you yet. Group up and they are remembered here: who they are, when you met and how long you travelled together.",
      14, ly, W - 28, "small", C.dim) + 8
  end
  local most = math.max(60, pals[1] and tonumber(pals[1].rec.seconds) or 60)
  for i, p in ipairs(pals) do
    if i > 40 then break end
    ly = ly + palRow(L, p, most, 14, ly, W - 28)
  end
  ly = ly + 6
  U.box(0, top, W, ly - top, C.panel, C.edge)
  ly = ly + 12
  -- right: your closest companion, then everyone else you met
  local ry = y
  local best = pals[1]
  if best and (tonumber(best.rec.seconds) or 0) >= 60 then
    local RU, RC, RW = R.U, R.C, R.W
    top = ry
    ry = ry + 12
    ry = ry + RU.sectionTitle("A TRUE COMPANION", ry)
    local token = type(best.rec.class) == "string" and best.rec.class or nil
    if token then RU.icon("classicon_" .. token:lower(), math.floor(RW / 2) - 20, ry, 40, Q.plain(best.name), nil) end
    ry = ry + (token and 46 or 0)
    ry = ry + RU.T(Q.plain(best.name), 14, ry, RW - 28, "head", RC.ink, "CENTER") + 4
    local cls = token and (token:sub(1, 1) .. token:sub(2):lower()) or nil
    local line = (cls and (cls .. ", ") or "") .. "met " .. (best.rec.level and ("at level " .. best.rec.level .. ", ") or "")
      .. "day " .. dayOf(j, best.rec.first) .. ". " .. duration(best.rec.seconds) .. " on the road together."
    ry = ry + RU.T(line, 14, ry, RW - 28, "small", RC.inkSoft, "CENTER") + 6
    local words = J.lore and J.lore.companionLine and J.lore.companionLine(best.name, best.rec)
    if words then ry = ry + RU.T('"' .. words .. '"', 24, ry, RW - 48, "body", RC.ink, "CENTER") + 8 end
    ry = ry + 6
    page(RU, RC, 0, top, RW, ry - top)
    ry = ry + 12
  end
  if J.tales and J.tales.companions then ry = J.tales.companions(R, ry) + 12 end
  return ly, ry
end

----------------------------------------------------------------------------
-- Page: Trophies
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

local function firstsCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local D = J.deeds
  local firsts = type(j.firsts) == "table" and j.firsts or {}
  y = y + U.sectionTitle("FIRSTS", y)
  local gap = 8
  local per = W >= 560 and 4 or 2
  local cw = math.floor((W - (per - 1) * gap) / per)
  local ch = 104
  for i, f in ipairs(D.FIRSTS) do
    local cx = ((i - 1) % per) * (cw + gap)
    local cy = y + math.floor((i - 1) / per) * (ch + gap)
    local r = firsts[f.fk]
    local got = r and not r.had
    page(U, C, cx, cy, cw, ch)
    local q = r and tonumber(r.iq) or f.q or 1
    local light = QUALITY_LIGHT[q] or QUALITY_LIGHT[1]
    local ink = QUALITY_INK[q] or QUALITY_INK[1]
    U.rect(cx + math.floor(cw / 2) - 20, cy + 10, 40, 40, { light[1], light[2], light[3], got and 1 or 0.35 }, "border", 2)
    local ic = U.icon(itemIcon(r and r.i, f.fk == "bag" and "INV_Misc_Bag_08" or ICON.first), cx + math.floor(cw / 2) - 18, cy + 12, 36,
      f.label, got and (r.n .. "\nLevel " .. (r.l or "?") .. ", day " .. dayOf(j, r.t)) or (r and r.had and "You had one before the journal began.")
        or "Still out there.")
    if not got then ic.tex:SetDesaturated(true); ic.tex:SetAlpha(0.55) end
    U.T(f.label:upper(), cx + 6, cy + 56, cw - 12, "label", C.inkSoft, "CENTER")
    if got then
      U.T(Q.plain(r.n or "?"), cx + 6, cy + 70, cw - 12, "small", ink, "CENTER")
      U.T("level " .. (r.l or "?") .. ", day " .. dayOf(j, r.t), cx + 6, cy + 86, cw - 12, "small", C.inkSoft, "CENTER")
    else
      U.T(r and r.had and "before the journal" or "still out there", cx + 6, cy + 72, cw - 12, "small", C.inkSoft, "CENTER")
    end
  end
  return y + math.ceil(#D.FIRSTS / per) * (ch + gap) + 2
end

local function nemesesCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local nem = J.deeds.nemeses()
  local shown = {}
  for i = 1, math.min(5, #nem) do shown[i] = nem[i] end
  local most = nem[1] and nem[1].n or 1
  return listCard(V, "NEMESES", #nem > 0 and plural(tonumber(j.deaths) or 0, "fall") or nil, 0, y, W, shown,
    "Nobody has bested you yet. Long may it last.", function(r, ry)
      U.icon("INV_Misc_Bone_HumanSkull_01", 14, ry, 22, r.name, plural(r.n, "fall") .. ", the last: " .. r.last.s)
      U.T(Q.plain(r.name), 44, ry + 1, W - 110, "body", C.light)
      U.T(plural(r.n, "fall"), 14, ry + 1, W - 28, "small", C.book and DEATH_INK or { 0.9, 0.35, 0.3 }, "RIGHT")
      local bw = W - 58
      U.rect(44, ry + 18, bw, 3, C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 })
      U.rect(44, ry + 18, math.max(2, bw * r.n / most), 3, { 0.75, 0.2, 0.15, 1 })
      return 30
    end)
end

local function closeCallsCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local closes = J.deeds.moments({ close = true }, 5)
  return listCard(V, "CLOSE CALLS", tonumber(j.closeCalls) and j.closeCalls > 0 and tostring(j.closeCalls) or nil, 0, y, W,
    closes, "No close shaves yet: every fight ended with health to spare.", function(e, yy)
      U.icon(ICON.close, 14, yy, 22, e.s, e.d)
      local h = U.T(e.s, 44, yy + 1, W - 58, "small", C.light)
      local pct = tonumber(e.pct)
      if pct then
        U.T(pct .. "% health  -  level " .. (e.l or "?"), 44, yy + h + 3, W - 58, "small", C.dim)
        h = h + 14
      end
      return math.max(28, h + 8)
    end)
end

local function bossesCard(V, y)
  local U, C, W, j = V.U, V.C, V.W, V.j
  local bosses = J.deeds.moments({ boss = true, rare = true }, 6)
  local nb, nr = 0, tonumber(j.rares) or 0
  for _, e in ipairs(j.events) do if e.k == "boss" then nb = nb + 1 end end
  return listCard(V, "BOSSES AND RARES", (nb + nr > 0) and (plural(nb, "boss"):gsub("bosss", "bosses") .. ", " .. plural(nr, "rare")) or nil,
    0, y, W, bosses, "The great foes are still ahead. Dungeon bosses and rares you slay are kept here.", function(e, yy)
      U.icon(ICON[e.k] or ICON.boss, 14, yy, 22, e.s, e.d)
      local h = U.T(e.s, 44, yy + 1, W - 58, "small", C.light)
      U.T("level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t), 44, yy + h + 3, W - 58, "small", C.dim)
      return math.max(28, h + 22)
    end)
end

local function upgradesCard(V, y)
  local U, C, W = V.U, V.C, V.W
  local ups = J.deeds.moments({ upgrade = true }, 6)
  return listCard(V, "GEAR UPGRADES", nil, 0, y, W, ups, "Pieces you put on and keep wearing for a minute show up here.",
    function(e, yy)
      local q = tonumber(e.iq) or 1
      local light = QUALITY_LIGHT[q] or QUALITY_LIGHT[1]
      U.rect(13, yy - 1, 24, 24, light, "border", 2)
      U.icon(itemIcon(e.i, ICON.upgrade), 14, yy, 22, e.s, e.d)
      local h = U.T(e.s, 44, yy + 1, W - 58, "small", C.book and (QUALITY_INK[q] or C.light) or C.light)
      if e.d then U.T(e.d .. "  -  level " .. (e.l or "?"), 44, yy + h + 3, W - 58, "small", C.dim); h = h + 14 end
      return math.max(28, h + 8)
    end)
end

local function craftsCard(V, y)
  local U, C, W = V.U, V.C, V.W
  local caps = J.deeds.moments({ cap = true })
  local top = y
  y = cardTitle(V, "CRAFT MILESTONES", 0, y, W, #caps > 0 and tostring(#caps) or nil)
  if #caps == 0 then
    y = y + U.T("Take a profession to the end of a tier (75, 150, 225 or 300) and it is written here.", 14, y, W - 28, "small", C.dim) + 10
  else
    local cols = W >= 560 and 2 or 1
    local chw = math.floor((W - 28 - (cols - 1) * 8) / cols)
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
  return y
end

local function trophiesPage(V, y)
  if not J.deeds then return y, y end
  local sections = { firstsCard, nemesesCard, bossesCard, closeCallsCard, upgradesCard, craftsCard }
  for _, fn in ipairs(J.tales and J.tales.trophySections and J.tales.trophySections() or {}) do sections[#sections + 1] = fn end
  return flow(V, y, sections)
end

for _, p in ipairs({ { P_OVERVIEW, overviewPage }, { P_STORY, storyPage, storyFilters }, { P_MAP, mapPage },
  { P_TROPHIES, trophiesPage }, { P_COMPANIONS, companionsPage } }) do
  for _, pg in ipairs(PAGES) do if pg.name == p[1] then pg.draw, pg.pre = p[2], p[3] end end
end

----------------------------------------------------------------------------
-- The book
----------------------------------------------------------------------------
local FOOTER = 34 -- the page numbers under the columns

local function render()
  local U, C = ns.ui, ns.C
  local st = ns.stats and select(2, ns.stats.data())
  if ns.settingsLost or not st then st = ns.stats and (ns.stats.data()) end
  local _, curName = here()
  local V = { U = U, C = C, W = BOOK_W, j = J.data(), lvl = level(), totals = st and st.totals or {}, curName = curName,
    name = Q.plain(try(UnitName, "player") or "Adventurer"), className = Q.plain((try(UnitClass, "player")) or ""),
    race = Q.plain((try(UnitRace, "player")) or "") }
  local P = inkPalette(C)
  V.readable = function(c) return readable(C, c) end
  V.L = column(V, P, EDGE + PAD, COL_W)
  V.R = column(V, P, EDGE + PAGE_W + SPINE + PAD, COL_W)
  local y = cover(V)
  local lit
  y, lit = ribbons(V, y)
  local pg = PAGES[lit] or PAGES[1]
  if pg.pre then y = pg.pre(V, y) end
  -- the spread: running heads, the columns, page numbers, then the sheets under them
  local top = y + 4
  local lx, rx = EDGE, EDGE + PAGE_W + SPINE
  local headY = top + 14
  U.T("THE JOURNEY OF " .. V.name:upper(), lx + PAD, headY, COL_W, "label", P.inkSoft, "CENTER")
  U.T((pg.name or ""):upper(), rx + PAD, headY, COL_W, "label", P.inkSoft, "CENTER")
  local ink = P.ink or P.light
  U.rect(lx + PAD + 40, headY + 16, COL_W - 80, 1, { ink[1], ink[2], ink[3], 0.25 }, "border")
  U.rect(rx + PAD + 40, headY + 16, COL_W - 80, 1, { ink[1], ink[2], ink[3], 0.25 }, "border")
  local draw = pg.draw or overviewPage
  local ly, ry = draw(V, headY + 30)
  ry = ry or ly
  local bottom = math.max(ly, ry, top + 260) + 6
  local h = bottom - top + FOOTER
  local n = lit * 2
  U.T("- " .. n .. " -", lx + PAD, bottom + 8, COL_W, "small", P.inkSoft, "CENTER")
  U.T("- " .. (n + 1) .. " -", rx + PAD, bottom + 8, COL_W, "small", P.inkSoft, "CENTER")
  sheet(V, P, lx, top, h, "left")
  sheet(V, P, rx, top, h, "right")
  -- the spine between the sheets and a ribbon marking your chapter
  local half = SPINE / 2
  local s1 = U.rect(lx + PAGE_W, top, half, h, { 1, 1, 1, 1 }, nil, L_STACK, "fade")
  ns.fade(s1, "HORIZONTAL", 0, 0, 0, 0.15, 0.6)
  local s2 = U.rect(lx + PAGE_W + half, top, half, h, { 1, 1, 1, 1 }, nil, L_STACK, "fade")
  ns.fade(s2, "HORIZONTAL", 0, 0, 0, 0.6, 0.15)
  local band = J.bandColor(V.lvl)
  local mark = { band[1] * 0.7, band[2] * 0.7, band[3] * 0.7, 1 }
  U.rect(rx + PAGE_W - 46, top - 6, 14, 52, mark, "border", 6)
  U.rect(rx + PAGE_W - 46, top - 6, 1, 52, { 0, 0, 0, 0.35 }, "border", 7)
  U.rect(rx + PAGE_W - 33, top - 6, 1, 52, { 0, 0, 0, 0.35 }, "border", 7)
  local total = top + h + EDGE
  leather(V, total)
  return total + 8
end

-- Drawing helpers for the pages other files add (JourneyQuestLog.lua, JourneyTales.lua).
J.draw = { page = page, cardTitle = cardTitle, dayOf = dayOf, plural = plural, duration = duration, roman = roman,
  listCard = listCard, itemIcon = itemIcon, DEATH_INK = DEATH_INK, flow = flow, initialed = initialed,
  readable = readable, ornament = ornament }

ns.addTab("journey", "Journey", render, BOOK_W)
