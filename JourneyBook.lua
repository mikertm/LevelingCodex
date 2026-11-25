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
    mount = true, mine = true, herb = true, skin = true, fish = true },
  { pal = true, rez = true, trade = true, duel = true, emote = true, guild = true, camp = true, run = true },
  { zone = true, flight = true, start = true, camp = true, mount = true, home = true, rest = true, milestone = true },
  { death = true, close = true, wipe = true, expired = true, abandon = true },
}
local FILTER_TIPS = { "Every moment.", "Quests and the stories they finished, and the ones you gave up.",
  "Dungeons, bosses, wipes, elites, rares, close calls, duels, battlegrounds and fights with other players.",
  "Firsts, gear upgrades, crafting, professions, gathering and fishing, the auction house, your purse and your first mount.",
  "Companions, dungeon parties, resurrections, trades, duels, waves and campfires.",
  "New lands, flight paths, inns, new homes, campfires and the miles behind you.", "Every fall, wipe, near miss and lost cause." }
local storyLevel, mapPick, highlight
local storyLeaf, unfolded = 1, {} -- the page of the chapter you're reading; the folded runs you opened
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
  if not C.eui then
    -- every theme's book is old paper in sepia ink, so the pages read as a journal and not a form
    P.parch = { 0.92, 0.85, 0.7, 1 }
    ink, soft = { 0.22, 0.14, 0.07 }, { 0.43, 0.31, 0.18 }
    P.ink, P.inkSoft = ink, soft
    P.gold = { 0.52, 0.33, 0.08, 1 }
    P.green = { 0.12, 0.42, 0.12 }
    P.accent = { 0.45, 0.2, 0.1, 1 }
  end
  P.light, P.dim = ink, soft
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
  X.fold = function(open, x, ...) return U.fold(open, x + ox, ...) end
  X.line = function(x1, y1, x2, ...) return U.line(x1 + ox, y1, x2 + ox, ...) end
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
  local function addMap(m)
    if m and not listed[m] and not select(3, zoneOf(m)) then listed[m] = true; maps[#maps + 1] = m end
  end
  local pinned = {}
  for _, e in ipairs(j.events) do if e.m then pinned[e.m] = true end end
  for _, m in ipairs(j.order) do if j.trail[m] or pinned[m] then addMap(m) end end
  for _, e in ipairs(j.events) do if e.m and (j.trail[e.m] or pinned[e.m]) then addMap(e.m) end end
  for m in pairs(j.trail) do addMap(m) end
  return maps
end

-- The map's layers: the trail, then the moments by kind (each a switch on the Map page, kept in
-- db.journeyMapHide; the chapter plates show them all). pin = a raid marker for its own kinds.
local LAYERS = {
  { key = "trail", label = "Trail", tip = "The roads you walked, coloured by your level." },
  { key = "levels", label = "Levels", pin = PIN.level, color = { 1, 0.85, 0.3 }, kinds = { level = true, start = true, cap = true },
    tip = "Where you reached each level." },
  { key = "quests", label = "Quests", icon = ICON.quest, color = { 0.95, 0.8, 0.35 },
    kinds = { quest = true, chain = true, abandon = true }, tip = "Where you finished quests and stories." },
  { key = "battles", label = "Battles", pin = PIN.boss, color = { 0.85, 0.35, 0.25 },
    kinds = { boss = true, rare = true, elite = true, pvp = true, bg = true, duel = true, dungeon = true, run = true },
    tip = "Bosses, rares, elites, dungeons and fights with other players." },
  { key = "falls", label = "Falls", pin = PIN.death, color = { 0.6, 0.15, 0.12 }, kinds = { death = true, close = true, wipe = true },
    tip = "Where you fell, wiped or nearly did." },
  { key = "travels", label = "Travels", icon = ICON.zone, color = { 0.35, 0.7, 0.95 },
    kinds = { zone = true, flight = true, mount = true, home = true, rest = true, camp = true, milestone = true },
    tip = "New lands, flight paths, inns, homes, campfires and milestones." },
  { key = "fortunes", label = "Fortunes", icon = ICON.gold, color = { 0.4, 0.8, 0.35 },
    kinds = { first = true, upgrade = true, craft = true, skill = true, auction = true, sold = true, expired = true, gold = true,
      mine = true, herb = true, skin = true, fish = true }, tip = "Loot, gear, crafting, gathering, fishing and gold." },
  { key = "fellowship", label = "Fellowship", icon = ICON.pal, color = { 0.75, 0.55, 0.95 },
    kinds = { pal = true, rez = true, trade = true, emote = true, guild = true }, tip = "Companions, rezzes, trades and kind words." },
}
local function layerOf(e)
  for i = 2, #LAYERS do if LAYERS[i].kinds[e.k] then return LAYERS[i] end end
  return LAYERS[6] -- anything else is part of the road
end
local function layerOn(key, all)
  if all then return true end
  local hide = ns.db().journeyMapHide
  return not (type(hide) == "table" and hide[key])
end
local function toggleLayer(key)
  local db = ns.db()
  if type(db.journeyMapHide) ~= "table" then db.journeyMapHide = {} end
  db.journeyMapHide[key] = not db.journeyMapHide[key] or nil
end
-- small moments, drawn as dots on the map (they still gather into a pin's count)
local MINOR = { mine = true, herb = true, skin = true, fish = true, gold = true, sold = true, expired = true, auction = true,
  flight = true, rest = true, camp = true, emote = true, trade = true, craft = true, skill = true, milestone = true }
-- how much a moment matters when pins share a spot (the top one shows)
local WEIGHT = { falls = 6, battles = 5, levels = 4, fellowship = 3, quests = 2, fortunes = 2, travels = 1 }

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
local function drawPlate(V, map, mx, my, mw, mh, pinSize, onlyLevel, all)
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
  -- the trail: a line in your level's colour on a dark under-stroke, points closer than 4 px merged
  -- and a gap where you jumped (a hearth, a flight); where the trail runs thickest (the camps and
  -- towns you kept coming back to) a soft wash marks the place, the six busiest at most
  local small = mw < 400
  local thick = small and 2 or 3
  local busy, cell = {}, small and 0.05 or 0.04
  local hasLine = U.line and true
  for _, r in ipairs(layerOn("trail", all) and J.runs(map, small and 250 or 600, onlyLevel) or {}) do
    local c = J.bandColor(r.level)
    local px, py
    for _, pt in ipairs(r.pts) do
      local cx, cy = mx + pt[1] / 100 * mw, my + pt[2] / 100 * mh
      local key = math.floor(pt[1] / 100 / cell) .. ":" .. math.floor(pt[2] / 100 / cell)
      local b = busy[key]
      if not b then b = { n = 0, x = 0, y = 0, c = c }; busy[key] = b end
      b.n, b.x, b.y, b.c = b.n + 1, b.x + cx, b.y + cy, c
      if not px then
        px, py = cx, cy
      else
        local dx, dy = cx - px, cy - py
        local d2 = dx * dx + dy * dy
        if d2 > (mw * 0.12) ^ 2 then
          px, py = cx, cy -- a jump: no line across the map
        elseif d2 >= 16 then
          if hasLine then
            U.line(px, py, cx, cy, { 0.08, 0.05, 0.02, 0.45 }, thick + 2, 1)
            U.line(px, py, cx, cy, { c[1], c[2], c[3], 0.95 }, thick, 2)
          else
            disc(U, cx - 2, cy - 2, 4, { c[1], c[2], c[3], 1 }, 2, "journeyDot")
          end
          px, py = cx, cy
        end
      end
    end
  end
  local spots = {}
  for _, b in pairs(busy) do if b.n >= 6 then spots[#spots + 1] = b end end
  table.sort(spots, function(a, b) return a.n > b.n end)
  for i = 1, math.min(6, #spots) do
    local b = spots[i]
    local size = math.min(small and 26 or 40, (small and 12 or 18) + b.n)
    local cx, cy = b.x / b.n, b.y / b.n
    disc(U, cx - size / 2, cy - size / 2, size, { b.c[1], b.c[2], b.c[3], 0.22 }, 0, "journeyHalo")
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
  -- the moments: pins near each other gather into one (the weightiest on top, a count beside it);
  -- small moments (gathering, gold, flights, inns) are dots, so only what matters wears an icon
  local reach = pinSize * 1.6
  local groups = {}
  for _, e in ipairs(J.pinsOn(map, onlyLevel)) do
    local lay = layerOf(e)
    if layerOn(lay.key, all) or highlight == e then
      local px, py = mx + e.x / 100 * mw, my + e.y / 100 * mh
      local into
      for _, g in ipairs(groups) do
        if math.abs(g.x - px) <= reach and math.abs(g.y - py) <= reach then into = g; break end
      end
      if not into then into = { x = px, y = py, list = {} }; groups[#groups + 1] = into end
      into.list[#into.list + 1] = { e = e, lay = lay }
    end
  end
  local gold = ns.C.gold
  for _, sp in ipairs(groups) do
    table.sort(sp.list, function(a, b)
      if (a.e == highlight) ~= (b.e == highlight) then return a.e == highlight end
      local wa, wb = WEIGHT[a.lay.key] or 0, WEIGHT[b.lay.key] or 0
      if MINOR[a.e.k] then wa = wa - 3 end
      if MINOR[b.e.k] then wb = wb - 3 end
      if wa ~= wb then return wa > wb end
      return (a.e.t or 0) > (b.e.t or 0)
    end)
    local top = sp.list[1]
    local e, lay = top.e, top.lay
    local big = highlight and e == highlight
    local minor = MINOR[e.k] and not big
    local size = big and pinSize + 8 or (minor and math.max(6, math.floor(pinSize * 0.55)) or pinSize)
    local px, py = sp.x - size / 2, sp.y - size / 2
    local tipText = "Level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t) .. (e.d and ("  -  " .. e.d) or "")
    if #sp.list > 1 then
      local more = { tipText, "", "Also here:" }
      for i = 2, math.min(7, #sp.list) do more[#more + 1] = "- " .. sp.list[i].e.s end
      if #sp.list > 7 then more[#more + 1] = "... and " .. (#sp.list - 7) .. " more" end
      tipText = table.concat(more, "\n")
    end
    if big then disc(U, px - 4, py - 4, size + 8, { gold[1], gold[2], gold[3], 0.7 }, nil, "journeyRing", true) end
    local file = lay.pin and PIN[e.k]
    local function pick() highlight = (highlight ~= e) and e or nil; U.refresh() end
    local c = lay.color or gold
    if minor then
      disc(U, px - 1, py - 1, size + 2, { 0.08, 0.05, 0.02, 0.75 }, 1, "journeyHalo", true)
      disc(U, px, py, size, { c[1], c[2], c[3], 1 }, 2, "journeyDot", true)
      U.hit(px - 2, py - 2, size + 4, size + 4, e.s, tipText, pick, "Pin " .. e.s)
    elseif file then
      disc(U, px - 2, py - 2, size + 4, { 0.08, 0.05, 0.02, 0.6 }, 1, "journeyHalo", true)
      pinArt(U, ns.C, file, px, py, size)
      U.hit(px, py, size, size, e.s, tipText, pick, "Pin " .. e.s)
    else
      disc(U, px - 3, py - 3, size + 6, { 0.08, 0.05, 0.02, 0.55 }, 1, "journeyHalo", true)
      disc(U, px - 1, py - 1, size + 2, { c[1], c[2], c[3], 1 }, 1, "journeyHalo", true)
      local f = U.icon(ICON[e.k] or lay.icon or ICON.quest, px, py, size, e.s, tipText)
      if f then
        if f.ring then f.ring:SetColorTexture(c[1], c[2], c[3], 1) end
        f:SetScript("OnClick", pick)
        f.codexLabel = "Pin " .. e.s
      end
    end
    if #sp.list > 1 then
      local n = #sp.list > 99 and "99+" or tostring(#sp.list)
      local bw = #n * 6 + 8
      local bx, by = px + size - 4, py - 6
      disc(U, bx, by, bw, { 0.1, 0.06, 0.03, 0.92 }, 3, "journeyRing", true)
      U.T(n, bx, by + 1, bw, "small", { 1, 0.9, 0.6 }, "CENTER", true)
    end
  end
end

-- The map's key: the level bands, then a switch per layer (four to a row; a click shows or hides it,
-- "Layer <label>"); counts = moments of each layer on this map. Returns the height.
local function legend(V, x, y, w, counts)
  local U, C = V.U, V.C
  local lx = x
  local bw = math.floor(w / #J.BANDS)
  for _, b in ipairs(J.BANDS) do
    disc(U, lx, y + 2, 10, b[3], nil, "journeyDot")
    U.T(b[4], lx + 13, y + 1, bw - 13, "small", C.dim)
    lx = lx + bw
  end
  y = y + 20
  local per, gap = 4, 6
  local cw = math.floor((w - (per - 1) * gap) / per)
  local ink = C.ink or C.light
  for i, lay in ipairs(LAYERS) do
    local cx, cy = x + ((i - 1) % per) * (cw + gap), y + math.floor((i - 1) / per) * 30
    local on = layerOn(lay.key)
    local c = lay.color or C.gold
    U.rect(cx, cy, cw, 26, { ink[1], ink[2], ink[3], on and 0.12 or 0.03 }, "border", -2)
    U.rect(cx, cy, 3, 26, { c[1], c[2], c[3], on and 1 or 0.3 }, "border", -1)
    if lay.key == "trail" then
      disc(U, cx + 9, cy + 8, 10, { 0.08, 0.05, 0.02, on and 0.55 or 0.2 }, 1, "journeyHalo")
      disc(U, cx + 11, cy + 10, 6, { c[1], c[2], c[3], on and 1 or 0.3 }, 2, "journeyDot")
    elseif lay.pin then
      local t = pinArt(U, C, lay.pin, cx + 7, cy + 6, 14)
      t:SetAlpha(on and 1 or 0.35)
    else
      disc(U, cx + 7, cy + 6, 14, { c[1], c[2], c[3], on and 1 or 0.3 }, 1, "journeyHalo")
      local f = U.icon(lay.icon, cx + 9, cy + 8, 10, nil, nil)
      if f then f:EnableMouse(false); f.tex:SetAlpha(on and 1 or 0.35) end
    end
    local n = counts and counts[lay.key]
    U.T(lay.label, cx + 26, cy + 6, cw - 28, "small", on and ink or (C.inkSoft or C.dim))
    if n and n > 0 then U.T(tostring(n), cx + 26, cy + 6, cw - 30, "small", C.inkSoft or C.dim, "RIGHT") end
    U.hit(cx, cy, cw, 26, (on and "Hide " or "Show ") .. lay.label:lower(), lay.tip, function()
      toggleLayer(lay.key)
      U.refresh()
    end, "Layer " .. lay.label)
  end
  return 20 + math.ceil(#LAYERS / per) * 30
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
    local zn = e.m and J.landOf(e.m)
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
    drawPlate(V, plateMap, px, py, pw, ph, 9, l, true)
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
  local barColor = C.book and readable(C, nameColor) or nameColor
  if C.book then nameColor = C.ink end
  local shown = J.companions and J.companions.nameText(p.name) or Q.plain(p.name)
  if token then U.icon("classicon_" .. token:lower(), x, y, 22, cls, nil) end
  local secs = tonumber(p.rec.seconds) or 0
  local together = secs < 60 and "just met" or (duration(secs) .. " together")
  local track = C.book and { 0, 0, 0, 0.12 } or { 0.05, 0.05, 0.08, 0.9 }
  U.T(shown, x + 30, y + 1, w - 150, "body", nameColor)
  U.T(together, x + 30, y + 1, w - 30, "small", C.light, "RIGHT")
  if compact then
    U.rect(x + 30, y + 18, w - 30, 4, track)
    U.rect(x + 30, y + 18, math.max(2, (w - 30) * secs / most), 4, barColor)
    if J.companions then
      U.hit(x, y - 2, w, 28, shown, "Click to open their page.", function()
        J.companions.select(p.name)
        openPage(P_COMPANIONS, U)
      end, "Companion " .. Q.plain(p.name))
    end
    return 30
  end
  U.T(cls .. (p.rec.level and ("  -  met at level " .. p.rec.level) or ""), x + 30, y + 17, w - 30, "small", C.dim)
  U.rect(x + 30, y + 33, w - 30, 4, track)
  U.rect(x + 30, y + 33, math.max(2, (w - 30) * secs / most), 4, barColor)
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
  local ep = J.voice and J.voice.epithet(j)
  local ex = 112
  if ep then
    local _, fs = U.T(ep, 112, 72, 200, "small", gold)
    ex = 112 + math.min(200, math.ceil(tonumber(fs and fs.GetStringWidth and fs:GetStringWidth()) or 90)) + 10
    if fs and fs.SetWordWrap then fs:SetWordWrap(false) end
  end
  U.T((ep and "-  " or "") .. (V.race ~= "" and (V.race .. " ") or "") .. V.className .. ", level " .. lvl
    .. (V.curName and ("  -  now in " .. V.curName) or ""), ex, 72, 532 - ex, "small", C.light)
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
    drawPlate(V, show, 14, y, mw, mh, 10, nil, true)
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
  R.U.btn("Read the story", 0, ry, 150, function() storyLevel, storyLeaf = l, 1; openPage(P_STORY, R.U) end, false,
    "Turn to your chapter; every level of your story is its own page.")
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
    local counts = { trail = nil }
    for _, e in ipairs(J.pinsOn(mapPick)) do
      local k = layerOf(e).key
      counts[k] = (counts[k] or 0) + 1
    end
    ly = ly + legend(L, 14, ly, W - 28, counts)
    ly = ly + U.T("Hover a pin to read what happened there; click it to mark it. A number beside a pin counts the moments it holds.",
      14, ly, W - 28, "small", C.dim) + 8
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
  ly = ly + 28
  U.check("Show a card when a big moment is written", 14, ly, not ns.db().noJourneyCards, function()
    local db = LevelingCodexDB
    if type(db) == "table" then db.noJourneyCards = not db.noJourneyCards or nil end
    U.refresh()
  end, "A boss, a first, a rare, a new land, a fall or a close call shows a small card as it goes into the book.")
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
      if e.m and J.landOf(e.m) == name or e.m == mapPick then
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
    -- the moments on this map, newest first, following the layers
    local here = {}
    for _, e in ipairs(J.pinsOn(mapPick)) do
      if layerOn(layerOf(e).key) then table.insert(here, 1, e) end
    end
    top = ry
    ry = cardTitle(R, "WHAT HAPPENED HERE", 0, ry, W, #here > 0 and plural(#here, "moment") or nil)
    if #here == 0 then
      ry = ry + U.T(n > 0 and "The layers you switched off hide what happened here." or "Nothing written on this map yet.", 14, ry, W - 28,
        "small", C.dim) + 10
    end
    for i, e in ipairs(here) do
      if i > 12 then
        ry = ry + U.T("... and " .. plural(#here - 12, "more moment") .. " (the Story has them all).", 14, ry, W - 28, "small", C.dim) + 6
        break
      end
      local lay = layerOf(e)
      local c = lay.color or C.gold
      local lit = highlight == e
      if lit then U.rect(8, ry - 3, W - 16, 30, { C.gold[1], C.gold[2], C.gold[3], 0.18 }) end
      U.rect(14, ry, 3, 24, { c[1], c[2], c[3], 1 }, "border")
      U.icon(ICON[e.k] or lay.icon or ICON.quest, 22, ry, 22, e.s, e.d)
      local h = U.T(e.s, 50, ry, W - 64, "small", C.ink or C.light)
      U.T("Level " .. (e.l or "?") .. ", day " .. dayOf(j, e.t) .. "  -  " .. lay.label:lower(), 50, ry + h + 1, W - 64, "small", C.dim)
      U.hit(8, ry - 3, W - 16, math.max(28, h + 18), e.s, "Click to mark it on the map.", function()
        highlight = (highlight ~= e) and e or nil
        U.refresh()
      end, "Moment " .. e.s)
      ry = ry + math.max(30, h + 20)
    end
    ry = ry + 4
    U.box(0, top, W, ry - top, C.panel, C.edge)
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

-- The Story reads one chapter (one level) per spread, like the pages of a book: the chapter's
-- opening, its plate and prose on the left, everything that happened on the right, and the page
-- turns at the bottom. Turning back past the first chapter opens the contents and the preface.
local CONTENTS = "contents"
local function allChapters(j)
  local seen, list = {}, {}
  for _, e in ipairs(j.events) do
    local l = tonumber(e.l) or 1
    if not seen[l] then seen[l] = true; list[#list + 1] = l end
  end
  table.sort(list)
  return list -- oldest first
end
local function chapterIndex(list, l)
  for i, v in ipairs(list) do if v == l then return i end end
end
-- The chapter the Story shows: the one picked, else your latest.
local function storyAt(list)
  if storyLevel == CONTENTS then return CONTENTS end
  if storyLevel and chapterIndex(list, storyLevel) then return storyLevel end
  return list[#list] or CONTENTS
end
function J.openChapter(l)
  storyLevel, storyLeaf = l, 1
  openPage(P_STORY, ns.ui)
end

local function turnTo(U, l)
  storyLevel, storyLeaf = l, 1
  U.refreshTop()
end

local function chapterLabel(l) return "Chapter " .. roman(l) end

-- The top of the Story: the filters, then the turning bar (Contents, back, where you are, on).
local function storyFilters(V, y)
  local U = V.U
  y = y + U.segments(EDGE, y, V.W - 2 * EDGE, FILTERS, filter, function(i) filter = i; U.refresh() end, FILTER_TIPS) + 6
  local list = allChapters(V.j)
  local at = storyAt(list)
  local i = at ~= CONTENTS and chapterIndex(list, at) or 0
  local prev = i > 1 and list[i - 1] or (i == 1 and CONTENTS) or nil
  local nxt = (at == CONTENTS and list[1]) or (i > 0 and list[i + 1]) or nil
  local x = EDGE
  U.btn("Contents", x, y, 96, function() turnTo(U, CONTENTS) end, at == CONTENTS, "The preface and every chapter of your story.")
  U.btn("< Previous chapter", x + 104, y, 150, function() if prev then turnTo(U, prev) end end, false,
    prev and (prev == CONTENTS and "Back to the contents." or ("Turn back to " .. chapterLabel(prev) .. ", level " .. prev .. "."))
    or "This is the first page.")
  local mid = at == CONTENTS and "THE CONTENTS" or ("CHAPTER " .. roman(at) .. "  -  " .. i .. " OF " .. #list
    .. (storyLeaf > 1 and ("  -  PAGE " .. storyLeaf) or ""))
  U.T(mid, x + 262, y + 6, V.W - 2 * EDGE - 524, "label", V.C.gold, "CENTER")
  U.btn("Next chapter >", V.W - EDGE - 254, y, 150, function() if nxt then turnTo(U, nxt) end end, false,
    nxt and ("Turn to " .. chapterLabel(nxt) .. ", level " .. nxt .. ".") or "The page after this one is still blank.")
  U.btn("Latest", V.W - EDGE - 96, y, 96, function() turnTo(U, list[#list] or CONTENTS) end, at == list[#list],
    "Your chapter: the one being written now.")
  return y + 32
end

-- Moments that come in runs (a day of auction trips, a string of flights, an evening of fishing) fold
-- into one line when three or more of a kind share a day: "Traded at the auction house 14 times".
-- A click opens the run (its moments drawn under it, indented) and closes it again.
local FOLD = { auction = "Traded at the auction house", sold = "Buyers found your wares", expired = "Auctions came back unsold",
  gold = "Collected auction gold at the mailbox", flight = "Took to the skies", rest = "Rested at an inn", camp = "Warmed your hands at a campfire",
  trade = "Traded with other players", emote = "Shared a wave or a smile", mine = "Worked the veins", herb = "Gathered herbs",
  skin = "Skinned your kills", fish = "Cast a line", craft = "Worked at the bench", upgrade = "Found better gear",
  abandon = "Gave up on quests", quest = "Finished quests" }
local FOLD_MIN = { quest = 8 } -- quests are the story itself: they fold only on a very busy day
local SAY_TIMES = { "once", "twice", "three times", "four times", "five times", "six times", "seven times", "eight times",
  "nine times", "ten times", "eleven times", "twelve times" }
-- copper in a "1g 2s 3c" text, or nil
local function moneyIn(text)
  if type(text) ~= "string" then return nil end
  local g, sv, c = text:match("(%d+)g"), text:match("(%d+)s"), text:match("(%d+)c")
  if not (g or sv or c) then return nil end
  return (tonumber(g) or 0) * 10000 + (tonumber(sv) or 0) * 100 + (tonumber(c) or 0)
end
-- The chapter's moments (oldest first) as rows: { e = moment } or { fold = run } (then its moments as
-- { e, sub = true } while it is open). key keeps the open runs apart per chapter.
local function foldMoments(j, list, key)
  local count = {}
  local function runKey(e) return FOLD[e.k] and (dayOf(j, e.t) .. ":" .. e.k) or nil end
  for _, e in ipairs(list) do
    local k = runKey(e)
    if k then count[k] = (count[k] or 0) + 1 end
  end
  local rows, runs = {}, {}
  for _, e in ipairs(list) do
    local k = runKey(e)
    if k and count[k] >= (FOLD_MIN[e.k] or 3) then
      local run = runs[k]
      if not run then
        run = { k = e.k, t = e.t, key = key .. ":" .. k, list = {} }
        runs[k] = run
        rows[#rows + 1] = { fold = run }
      end
      run.list[#run.list + 1] = e
    else
      rows[#rows + 1] = { e = e }
    end
  end
  local out = {}
  for _, r in ipairs(rows) do
    out[#out + 1] = r
    if r.fold and unfolded[r.fold.key] then
      for _, e in ipairs(r.fold.list) do out[#out + 1] = { e = e, sub = true } end
    end
  end
  return out
end
-- What a folded run says, and its detail line.
local function foldText(run)
  local n = #run.list
  local text = FOLD[run.k] .. " " .. (SAY_TIMES[n] or (n .. " times"))
  local spent, got, sums = 0, 0, 0
  for _, e in ipairs(run.list) do
    if type(e.ah) == "table" then spent = spent + (tonumber(e.ah.sp) or 0); sums = sums + 1
    elseif run.k == "auction" and e.d and e.d:find("spent", 1, true) then spent = spent + (moneyIn(e.d) or 0); sums = sums + 1
    elseif run.k == "gold" then got = got + (moneyIn(e.s) or 0); sums = sums + 1 end
  end
  local detail
  if spent > 0 then detail = ns.money(spent) .. " spent in all"
  elseif got > 0 then detail = ns.money(got) .. " collected in all" end
  return text, detail
end

-- The moments of a chapter in order (rows from foldMoments, first..last), as a timeline with the days
-- marked; returns the new y.
local function momentRows(V, rows, x, y, w, band, first, last)
  local U, C, j = V.U, V.C, V.j
  local spineTop, spineEnd, lastDay
  for i = first or 1, math.min(last or #rows, #rows) do
    local r = rows[i]
    local e = r.e or r.fold
    local day = dayOf(j, e.t)
    if day ~= lastDay and not r.sub then
      if lastDay then y = y + 4 end
      U.T("Day " .. day, x, y, w, "small", C.gold)
      U.rect(x + 46, y + 7, w - 46, 1, { band[1], band[2], band[3], 0.3 }, "border", 3)
      y = y + 18
    end
    lastDay = day
    spineTop = spineTop or (y + 10)
    spineEnd = y + 10
    local ix = r.sub and (x + 26) or x
    local textW = w - (ix - x) - 34
    if r.fold then
      local run = r.fold
      local text, detail = foldText(run)
      local open = unfolded[run.key]
      U.icon(ICON[run.k] or ICON.quest, ix, y, 22, text, detail)
      U.rect(ix + 12, y + 13, 16, 12, { 0.1, 0.06, 0.03, 0.85 }, "border", 5, nil, true)
      U.T("x" .. #run.list, ix + 10, y + 13, 20, "small", { 1, 0.9, 0.6 }, "CENTER", true)
      local th = U.T(text, ix + 30, y + 3, textW - 20, "body", C.ink)
      local rowH = math.max(24, th + 6)
      rowH = rowH + U.T((detail and (detail .. "  -  ") or "") .. (open and "click to fold them away" or "click to read each one"),
        ix + 30, y + th + 5, textW, "small", C.inkSoft) + 2
      U.fold(open, x + w - 16, y + 4)
      U.hit(x - 4, y - 2, w + 8, rowH + 2, text, open and "Click to fold these moments into one line."
        or "Click to read each of these moments.", function()
        unfolded[run.key] = not open or nil
        U.refresh()
      end, "Fold " .. text)
      y = y + rowH + 6
    else
      U.icon(ICON[e.k] or ICON.quest, ix, y, r.sub and 18 or 22, e.s, e.d)
      local th = U.T(e.s, ix + 30, y + 3, textW, r.sub and "small" or "body", e.k == "death" and DEATH_INK or C.ink)
      local rowH = math.max(r.sub and 20 or 24, th + 6)
      if e.d then rowH = rowH + U.T(e.d, ix + 30, y + th + 5, textW, "small", C.inkSoft) + 2 end
      if e.m and e.x then
        U.hit(ix - 4, y - 2, w - (ix - x) + 8, rowH + 2, e.s, (e.d and (e.d .. "\n") or "") .. "Click to show where it happened.", function()
          mapPick, highlight = e.m, e
          openPage(P_MAP, U)
        end, "Moment " .. e.s)
      end
      y = y + rowH + (r.sub and 2 or 6)
    end
  end
  if spineTop and spineEnd > spineTop then
    U.rect(x + 10, spineTop, 2, spineEnd - spineTop, { band[1], band[2], band[3], 0.5 }, "border", 3)
  end
  return y
end

-- A chapter's pages: the first spread holds the opening and the plate, so its right sheet takes
-- LEAF_FIRST rows; every later spread takes LEAF_COL rows a sheet.
local LEAF_FIRST, LEAF_FIRST_NO_PLATE, LEAF_COL = 9, 14, 14
local function leafCount(nrows, plate)
  local first = plate and LEAF_FIRST or LEAF_FIRST_NO_PLATE
  if nrows <= first then return 1 end
  return 1 + math.ceil((nrows - first) / (2 * LEAF_COL))
end

-- The weightiest moments of a chapter, for its highlights.
local HIGHLIGHT = { boss = 10, mount = 9, first = 8, rare = 8, cap = 7, dungeon = 7, chain = 6, run = 6, pvp = 6, bg = 6, elite = 6,
  death = 5, close = 5, wipe = 5, milestone = 4, duel = 4, home = 3, rez = 4, guild = 4 }
local function highlights(list, n)
  local pick = {}
  for _, e in ipairs(list) do
    local w = HIGHLIGHT[e.k]
    if e.k == "upgrade" and (tonumber(e.iq) or 0) >= 3 then w = 6 end
    if w then pick[#pick + 1] = { e = e, w = w } end
  end
  table.sort(pick, function(a, b)
    if a.w ~= b.w then return a.w > b.w end
    return (tonumber(a.e.t) or 0) > (tonumber(b.e.t) or 0)
  end)
  local out = {}
  for i = 1, math.min(n, #pick) do out[i] = pick[i].e end
  return out
end
local function highlightCards(CV, list, y)
  local U, C, W = CV.U, CV.C, CV.W
  local best = highlights(list, 3)
  if #best == 0 then return y end
  y = y + U.sectionTitle("HIGHLIGHTS", y)
  for _, e in ipairs(best) do
    local top = y
    U.icon(ICON[e.k] or ICON.quest, 10, y + 8, 32, e.s, e.d)
    local th = U.T(e.s, 52, y + 8, W - 64, "body", e.k == "death" and DEATH_INK or C.ink)
    local h = math.max(48, th + 16)
    if e.d then h = math.max(h, th + 14 + U.T(e.d, 52, y + th + 10, W - 64, "small", C.inkSoft) + 4) end
    page(U, C, 0, top, W, h)
    if e.m and e.x then
      U.hit(0, top, W, h, e.s, "Click to show where it happened.", function()
        mapPick, highlight = e.m, e
        openPage(P_MAP, U)
      end, "Highlight " .. e.s)
    end
    y = y + h + 6
  end
  return y + 6
end

-- One chapter across the spread.
local function chapterSpread(V, y, l, events, leaf)
  local L, R, j, lvl = V.L, V.R, V.j, V.lvl
  local LU, LC = L.U, L.C
  local list, opening = {}, nil
  for i = #events, 1, -1 do
    local e = events[i]
    if (e.k == "level" or e.k == "start") and not opening then opening = e else list[#list + 1] = e end
  end
  local rec = ns.stats and ns.stats.levelRecord(l)
  local count, zoneList, best, bestN = {}, {}, nil, 0
  local first, latest
  for _, e in ipairs(events) do
    local zn = e.m and J.landOf(e.m)
    if zn then
      if not count[zn] then count[zn] = 0; zoneList[#zoneList + 1] = zn end
      count[zn] = count[zn] + 1
      if count[zn] > bestN then best, bestN = zn, count[zn] end
    end
    local t = tonumber(e.t)
    if t then first = (not first or t < first) and t or first; latest = (not latest or t > latest) and t or latest end
  end
  local band = J.bandColor(l)
  -- left: the chapter's opening
  local ly = y
  LU.rect(0, ly, L.W, 3, { band[1], band[2], band[3], 0.85 }, "border", 3)
  ly = ly + 12
  LU.T("CHAPTER " .. roman(l), 0, ly, L.W, "title", LC.gold, "CENTER")
  ly = ly + 30
  local days
  if l == lvl then days = "the page you are writing now"
  elseif first then
    local d1, d2 = dayOf(j, first), dayOf(j, latest)
    days = d1 == d2 and ("day " .. d1) or ("days " .. d1 .. " to " .. d2)
  end
  ly = ly + LU.T("Level " .. l .. (best and ("  -  " .. best) or ""), 0, ly, L.W, "head", LC.ink, "CENTER") + 8
  if days then ly = ly + LU.T(days, 0, ly, L.W, "small", LC.inkSoft, "CENTER") + 2 end
  ly = ly + ornament(LU, LC, 0, ly + 2, L.W) + 10
  if best then
    local reached
    for _, z in pairs(j.zones) do
      if type(z) == "table" and z.name == best and tonumber(z.level) == l then reached = true end
    end
    local tale = reached and lore(best)
    if tale then ly = ly + LU.T(tale, 10, ly, L.W - 20, "small", LC.inkSoft, "CENTER") + 10 end
  end
  if opening then
    ly = ly + LU.T('"' .. opening.s .. '"', 16, ly, L.W - 32, "body", LC.inkSoft, "CENTER") + 12
  end
  local prose = J.lore and J.lore.chapterProse and J.lore.chapterProse(l, events, rec, l == lvl)
  if prose and prose ~= "" then ly = ly + initialed(LU, LC, prose, 0, ly, L.W, "body", LC.ink) + 12 end
  if rec then
    local cells = { { duration(rec.seconds), "on the road" }, { tostring(tonumber(rec.quests) or 0), "quests" },
      { tostring(tonumber(rec.kills) or 0), "foes" }, { tostring(tonumber(rec.deaths) or 0), "falls" } }
    local cw = math.floor((L.W - 18) / 4)
    for i, c in ipairs(cells) do
      local cx = (i - 1) * (cw + 6)
      L.U.box(cx, ly, cw, 44, LC.panel)
      LU.T(c[1], cx, ly + 7, cw, "head", LC.ink, "CENTER")
      LU.T(c[2], cx, ly + 27, cw, "small", LC.inkSoft, "CENTER")
    end
    ly = ly + 54
  end
  if #zoneList > 1 then ly = ly + LU.T("Through " .. table.concat(zoneList, ", ") .. ".", 0, ly, L.W, "small", LC.inkSoft, "CENTER") + 6 end
  -- right: what happened
  local ry = y
  -- the plate heads the right page, so the two sheets run about as long
  local plateMap = chapterMap(j, l, events)
  if plateMap then
    local pw = R.W - 20
    local ph = math.floor(pw * 668 / 1002)
    drawPlate(R, plateMap, 10, ry, pw, ph, 11, l, true)
    R.U.hit(10, ry, pw, ph, mapLabel(j, plateMap) .. " at level " .. l, "Click to open it on the map.", function()
      mapPick, highlight = plateMap, nil
      openPage(P_MAP, R.U)
    end, "Plate level " .. l)
    ry = ry + ph + 4
    ry = ry + R.U.T(mapLabel(j, plateMap) .. ", as you walked it at level " .. l, 10, ry, pw, "small", R.C.inkSoft, "CENTER") + 14
  end
  local rows = foldMoments(j, list, tostring(l))
  local sub = #list == 0 and nil or (plural(#list, "moment") .. (filter ~= 1 and ("  -  " .. FILTERS[filter]:lower()) or ""))
  ry = ry + R.U.sectionTitle("WHAT HAPPENED", ry, sub)
  if #list == 0 then
    local quiet = filter ~= 1 and ("No " .. FILTERS[filter]:lower() .. " in this chapter. Choose All to read the whole of it.")
      or "A quiet chapter: nothing else written yet. The next moment will be the first line on this page."
    ry = ry + R.U.T(quiet, 10, ry, R.W - 20, "body", R.C.inkSoft) + 10
  else
    local first = plateMap and LEAF_FIRST or LEAF_FIRST_NO_PLATE
    ry = momentRows(R, rows, 0, ry, R.W, band, 1, first)
    local leaves = leafCount(#rows, plateMap)
    if leaves > 1 then
      ry = ry + R.U.T("The chapter goes on over the page (" .. plural(leaves - 1, "more page") .. ").", 0, ry + 2, R.W, "small",
        R.C.inkSoft, "CENTER") + 8
    end
  end
  ly = highlightCards(L, list, ly + 6)
  return ly, ry
end

-- Who tells the story and what the book calls you: the narrator's voice and your last name.
local function narratorCard(CV, y)
  local Vo = J.voice
  if not Vo then return y end
  local U, C, W = CV.U, CV.C, CV.W
  local top = y
  y = y + 12
  U.T("THE NARRATOR", 14, y, W - 28, "label", C.inkSoft)
  y = y + 18
  local lit = 1
  for i, s in ipairs(Vo.STYLES) do if s == Vo.style() then lit = i end end
  y = y + U.segments(14, y, W - 28, Vo.STYLE_LABELS, lit, function(i)
    Vo.setStyle(Vo.STYLES[i])
    U.refresh()
  end, Vo.STYLE_TIPS) + 6
  y = y + U.T(Vo.STYLE_TIPS[lit] .. " Chapters already written keep their moments; the prose is retold in the new voice.", 14, y,
    W - 28, "small", C.inkSoft) + 10
  local first, last = Vo.names()
  U.T("YOUR NAME", 14, y, W - 28, "label", C.inkSoft)
  y = y + 18
  y = y + U.T(first .. (last and (" " .. last) or "  (no last name read)"), 14, y, W - 28, "body", C.ink) + 6
  local b = U.btn("Set last name", 14, y, 140, function()
    ns.showMacroCopy({ copyTitle = "Your last name", body = last or "", paste = true, acceptLabel = "Save name",
      help = "WoW Forever gives every character a first and a last name. Type the last name the book should use, "
        .. "leave it empty to use the one the game gives, or type - for none.",
      onAccept = function(text)
        local ok, why = Vo.setSurname(text)
        if ok then ns.ui.refresh() end
        return ok, why
      end })
  end, false, "Change the last name the book uses.")
  if b then b.codexLabel = "Set last name" end
  y = y + 34
  page(U, C, 0, top, W, y - top)
  return y + 12
end

-- The contents: the preface on the left, every chapter listed on both sheets.
local function contentsSpread(V, y, list, byLevel)
  local L, R, j = V.L, V.R, V.j
  local ly = y + L.U.sectionTitle("THE STORY SO FAR", y)
  local lines = J.lore and J.lore.preface and J.lore.preface(j, V) or nil
  if lines then ly = ly + initialed(L.U, L.C, lines, 0, ly, L.W, "body", L.C.ink) + 16 end
  ly = narratorCard(L, ly)
  if #list == 0 then
    ly = ly + L.U.T("The first page is still blank. Your story is written here as you go: every level, every land, every quest and every fall.",
      0, ly, L.W, "body", L.C.ink) + 10
    return ly, y
  end
  local ry = y + R.U.sectionTitle("CONTENTS", y, plural(#list, "chapter") .. " written")
  -- the list runs down the right sheet, then carries on under the preface
  local rowH = 24
  local room = math.max(8, math.floor((ly - ry) / rowH) + 12)
  for n, l in ipairs(list) do
    local CV = n <= room and R or L
    local cy = CV == R and ry or ly
    local events = byLevel[l] or {}
    local zn
    for _, e in ipairs(events) do if e.m then zn = J.landOf(e.m); if zn then break end end end
    local band = J.bandColor(l)
    CV.U.rect(0, cy + 4, 3, 14, { band[1], band[2], band[3], 0.9 }, "border", 3)
    CV.U.T(roman(l), 10, cy + 4, 50, "label", CV.C.gold)
    CV.U.T("Level " .. l .. (zn and ("  -  " .. zn) or ""), 62, cy + 4, CV.W - 150, "body", CV.C.ink)
    CV.U.T(plural(#events, "moment"), CV.W - 90, cy + 5, 90, "small", CV.C.inkSoft, "RIGHT")
    CV.U.hit(0, cy, CV.W, rowH - 2, chapterLabel(l) .. ": level " .. l, "Click to turn to this chapter.", function()
      turnTo(CV.U, l)
    end, "Chapter level " .. l)
    if CV == R then ry = ry + rowH else ly = ly + rowH end
  end
  return ly, ry
end

-- A chapter's moments without its opening (oldest first), its rows and how many spreads it takes.
local function chapterRows(j, l, events)
  local list, opening = {}, nil
  for i = #events, 1, -1 do
    local e = events[i]
    if (e.k == "level" or e.k == "start") and not opening then opening = e else list[#list + 1] = e end
  end
  local rows = foldMoments(j, list, tostring(l))
  local plate = chapterMap(j, l, events)
  return rows, leafCount(#rows, plate), plate
end

-- A later spread of a chapter: its moments on both sheets.
local function chapterLeaf(V, y, l, events, leaf)
  local L, R, j = V.L, V.R, V.j
  local rows, leaves, plate = chapterRows(j, l, events)
  local band = J.bandColor(l)
  local from = (plate and LEAF_FIRST or LEAF_FIRST_NO_PLATE) + (leaf - 2) * 2 * LEAF_COL + 1
  local ly, ry = y, y
  L.U.rect(0, ly, L.W, 3, { band[1], band[2], band[3], 0.85 }, "border", 3)
  ly = ly + 10
  ly = ly + L.U.T("CHAPTER " .. roman(l) .. ", CONTINUED", 0, ly, L.W, "head", L.C.gold, "CENTER") + 4
  ly = ly + L.U.T("Level " .. l .. "  -  page " .. leaf .. " of " .. leaves, 0, ly, L.W, "small", L.C.inkSoft, "CENTER") + 6
  ly = ly + ornament(L.U, L.C, 0, ly, L.W) + 8
  ly = momentRows(L, rows, 0, ly, L.W, band, from, from + LEAF_COL - 1)
  R.U.rect(0, ry, R.W, 3, { band[1], band[2], band[3], 0.85 }, "border", 3)
  ry = ry + 14
  if rows[from + LEAF_COL] then
    ry = momentRows(R, rows, 0, ry, R.W, band, from + LEAF_COL, from + 2 * LEAF_COL - 1)
  else
    ry = ry + R.U.T(l == V.lvl and "The rest of this page is still blank: your next moments will be written here."
      or "The chapter ends here.", 10, ry + 10, R.W - 20, "body", R.C.inkSoft, "CENTER") + 20
  end
  return ly, ry
end

-- How many spreads come before chapter l (the contents take one).
local function pagesBefore(j, list, byLevel, l)
  local n = 1
  for _, c in ipairs(list) do
    if c == l then break end
    n = n + select(2, chapterRows(j, c, byLevel[c] or {}))
  end
  return n
end

local function storyPage(V, y)
  local j = V.j
  local list = allChapters(j)
  local _, byLevel = chapterData(j)
  local at = storyAt(list)
  if at == CONTENTS then
    V.pageNo = 2
    return contentsSpread(V, y, list, byLevel)
  end
  local events = byLevel[at] or {}
  local leaves = select(2, chapterRows(j, at, events))
  if storyLeaf > leaves then storyLeaf = leaves end
  if storyLeaf < 1 then storyLeaf = 1 end
  local leaf = storyLeaf
  V.pageNo = 2 * (pagesBefore(j, list, byLevel, at) + leaf)
  local ly, ry
  if leaf == 1 then ly, ry = chapterSpread(V, y, at, events)
  else ly, ry = chapterLeaf(V, y, at, events, leaf) end
  -- the page turns at the foot of each sheet: through the chapter's pages, then to the next chapter
  local by = math.max(ly, ry) + 8
  local i = chapterIndex(list, at) or 1
  local prev = list[i - 1]
  local nxt = list[i + 1]
  if leaf > 1 then
    V.L.U.btn("< Page " .. (leaf - 1), 0, by, 150, function() storyLeaf = leaf - 1; V.L.U.refreshTop() end, false,
      "Turn back a page in this chapter.")
  else
    V.L.U.btn(prev and ("< " .. chapterLabel(prev)) or "< Contents", 0, by, 150, function() turnTo(V.L.U, prev or CONTENTS) end,
      false, prev and ("Turn back to level " .. prev .. ".") or "Back to the preface and the contents.")
  end
  if leaf < leaves then
    V.R.U.btn("Page " .. (leaf + 1) .. " of " .. leaves .. " >", V.R.W - 150, by, 150, function() storyLeaf = leaf + 1; V.R.U.refreshTop() end,
      false, "Turn the page: this chapter goes on.")
  elseif nxt then
    V.R.U.btn(chapterLabel(nxt) .. " >", V.R.W - 150, by, 150, function() turnTo(V.R.U, nxt) end, false,
      "Turn the page to level " .. nxt .. ".")
  else
    V.R.U.T("To be continued...", 0, by + 6, V.R.W, "small", V.R.C.inkSoft, "RIGHT")
  end
  return by + 30, by + 30
end

----------------------------------------------------------------------------
-- Page: Companions
----------------------------------------------------------------------------
-- JourneyCompanions.lua draws it (J.companions.page); this stays as the page's entry.
local function companionsPage(V, y)
  if J.companions then return J.companions.page(V, y) end
  return y, y
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
    name = J.voice and J.voice.fullName() or Q.plain(try(UnitName, "player") or "Adventurer"), className = Q.plain((try(UnitClass, "player")) or ""),
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
  -- a page that fails keeps the book standing: a line says so, and the chat names the error once
  local ok, ly, ry = pcall(draw, V, headY + 30)
  if not ok then
    local why = Q.plain(tostring(ly))
    J.pageError = why
    if not J.pageErrorSaid then J.pageErrorSaid = true; ns.say("journey page error: " .. why) end
    U.T("This page hit a snag and could not be drawn: " .. why, lx + PAD, headY + 30, COL_W, "small", DEATH_INK)
    ly, ry = headY + 90, headY + 90
  end
  ry = ry or ly
  local bottom = math.max(ly, ry, top + 260) + 6
  local h = bottom - top + FOOTER
  local n = V.pageNo or lit * 2
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
