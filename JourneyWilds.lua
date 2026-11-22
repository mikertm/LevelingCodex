-- JourneyWilds.lua: gathering and fishing in the journal. A Mining, Herb Gathering, Skinning or
-- Fishing cast (UNIT_SPELLCAST_SUCCEEDED, or a loot window IsFishingLoot() says is a catch) opens a
-- haul; the loot lines after it (LOOT_ITEM_SELF / _MULTIPLE, read through the client's own format)
-- fill it, and LOOT_CLOSED or a few quiet seconds close it. Each haul counts one vein, herb, hide or
-- catch:
--   journey.wilds[kind] = { n, items[name] = count, byLevel[level] = n, best = { name, q, l } }
--     (kind = mining, herbalism, skinning, fishing), journey.wildFirst[name] = true.
-- Moments (kinds mine, herb, skin, fish): the first of each kind, the first of each new material or
-- fish, a rare find (green quality or better, or something odd from the water), the 10th, 25th, 50th,
-- 100th... and a long session told when it ends (8 or more in a row, no gap over 10 minutes).
-- The Trophies page gets IN THE WILDS (J.moreTrophies). ASCII, our own wording, all pcall'd.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local function try(...) return Q.try(...) end

local Wd = {}
J.wilds = Wd

local function plain(s) return Q.plain(tostring(s or "")) end
local function now() return J.now() end
local function zone() return J.zoneName() end
local function pick(list, seed) return J.pick(list, seed) end
local function fill(text, vars) return J.fill(text, vars) end

-- kind -> what the cast is called, the moment kind, the icon and the words for one and many.
Wd.KINDS = {
  mining = { spells = { "Mining" }, k = "mine", icon = "Trade_Mining", one = "vein", many = "veins", verb = "mined", cat = "ore" },
  herbalism = { spells = { "Herb Gathering", "Herbalism" }, k = "herb", icon = "Trade_Herbalism", one = "herb", many = "herbs",
    verb = "picked", cat = "herbs" },
  skinning = { spells = { "Skinning" }, k = "skin", icon = "INV_Misc_Pelt_Wolf_01", one = "hide", many = "hides",
    verb = "skinned", cat = "hides" },
  fishing = { spells = { "Fishing" }, k = "fish", icon = "Trade_Fishing", one = "catch", many = "catches", verb = "caught", cat = "fish" },
}
J.ICON.mine, J.ICON.herb, J.ICON.skin, J.ICON.fish = "Trade_Mining", "Trade_Herbalism", "INV_Misc_Pelt_Wolf_01", "Trade_Fishing"
local MARKS = { 10, 25, 50, 100, 250, 500, 1000, 2500, 5000 }
local SESSION_GAP, SESSION_MIN = 600, 8
local WINDOW = { mining = 12, herbalism = 12, skinning = 12, fishing = 40 }
-- things from the water that are not fish
local ODD = { "crate", "chest", "bottle", "lockbox", "box", "trunk", "ring", "necklace", "boot", "pouch", "map", "skull", "coffer",
  "message", "clam", "shell", "key" }

local function journal()
  local j = J.data()
  if type(j.wilds) ~= "table" then j.wilds = {} end
  if type(j.wildFirst) ~= "table" then j.wildFirst = {} end
  return j
end
local function rec(kind)
  local j = journal()
  local w = j.wilds[kind]
  if type(w) ~= "table" then w = { n = 0, items = {}, byLevel = {} }; j.wilds[kind] = w end
  if type(w.items) ~= "table" then w.items = {} end
  if type(w.byLevel) ~= "table" then w.byLevel = {} end
  return w
end
function Wd.count(kind) local j = journal(); return type(j.wilds[kind]) == "table" and tonumber(j.wilds[kind].n) or 0 end
function Wd.atLevel(kind, l)
  local j = journal()
  local w = j.wilds[kind]
  return type(w) == "table" and type(w.byLevel) == "table" and tonumber(w.byLevel[l]) or 0
end

local function kindOfSpell(name)
  if type(name) ~= "string" then return nil end
  for kind, def in pairs(Wd.KINDS) do
    for _, s in ipairs(def.spells) do if name == s or name:find("^" .. s) then return kind end end
  end
end
local function spellName(id)
  local name = C_Spell and try(C_Spell.GetSpellName, id)
  if not name then name = try(GetSpellInfo, id) end
  return type(name) == "string" and name or nil
end
local function quality(link)
  local _, _, q = ns.itemInfo(link)
  return tonumber(q)
end
local function itemID(link) return tonumber(tostring(link or ""):match("item:(%d+)")) end

----------------------------------------------------------------------------
-- What the journal says
----------------------------------------------------------------------------
local LINES = {
  firstOf = {
    mining = { "Swung a pick at your first vein in %zone% and pried loose %item%", "Your first ore, %item%, chipped out of the rock of %zone%",
      "Struck the first vein of your life in %zone%: %item%, and sore arms" },
    herbalism = { "Knelt in %zone% and picked your first herb: %item%", "Your first %item%, gathered by hand in %zone%",
      "Learned which leaves to pick in %zone%: %item%, the first of many" },
    skinning = { "Took your first hide in %zone%: %item%", "Knife, patience and a strong stomach: your first %item%, in %zone%",
      "The first pelt of your trade, %item%, taken in %zone%" },
    fishing = { "Cast a line in %zone% and landed your first catch: %item%", "Your very first fish, %item%, pulled from the water of %zone%",
      "Sat on the bank in %zone% until something bit: %item%, your first catch" } },
  newMaterial = {
    mining = { "First %item% from the rock of %zone%", "Found %item% for the first time, in %zone%", "A new kind of ore: %item%, in %zone%" },
    herbalism = { "Picked your first %item% in %zone%", "A new plant for the satchel: %item%, in %zone%", "First %item% of the journey, in %zone%" },
    skinning = { "Your first %item%, from %zone%", "A new kind of hide: %item%, in %zone%" },
    fishing = { "First %item% on the line, in %zone%", "Something new in the waters of %zone%: %item%", "Landed a %item% for the first time, in %zone%" } },
  rare = {
    mining = { "A glint in the rock of %zone%: %item%", "Cracked a vein in %zone% and found %item% inside", "Luck in the stone of %zone%: %item%" },
    herbalism = { "Among the leaves in %zone%, something rare: %item%", "A lucky find in the grass of %zone%: %item%" },
    skinning = { "Something rare under the hide in %zone%: %item%", "A lucky cut in %zone%: %item%" },
    fishing = { "Fished something strange out of the water in %zone%: %item%", "The line came up heavy in %zone%: %item%",
      "Not a fish at all: %item%, hauled out of the water in %zone%" } },
  mark = {
    mining = { "Your %n% vein, broken open in %zone%", "%N% veins mined: the hills of %zone% heard every swing" },
    herbalism = { "Your %n% herb, picked in %zone%", "%N% herbs gathered, the latest in %zone%" },
    skinning = { "Your %n% hide, taken in %zone%", "%N% hides skinned: the latest in %zone%" },
    fishing = { "Your %n% catch, landed in %zone%", "%N% catches: the latest pulled from the water of %zone%" } },
  session = {
    mining = { "Spent %time% working the hills of %zone%: %count% %verb%, %haul%",
      "A long shift in %zone% with pick and pack: %count% %verb%, %haul%", "Worked the rock of %zone% for %time%: %haul%" },
    herbalism = { "Spent %time% roaming %zone% for herbs: %count% %verb%, %haul%",
      "Walked the meadows of %zone% with an eye on the ground: %count% %verb%, %haul%", "A gathering run through %zone%: %haul%" },
    skinning = { "Spent %time% skinning through %zone%: %count% %verb%, %haul%", "Knife work in %zone% for %time%: %haul%" },
    fishing = { "Cast a line for %time% at %place%: %count% %verb%, %haul%", "A quiet hour at %place% with rod and bait: %haul%",
      "Fished %place% for %time% and came away with %haul%" } },
  night = {
    mining = { "Late into the night in %zone%, still swinging the pick: %count% %verb%, %haul%" },
    herbalism = { "By moonlight in %zone%, picking herbs: %count% %verb%, %haul%" },
    skinning = { "Skinning in %zone% long after dark: %count% %verb%, %haul%" },
    fishing = { "Fished %place% deep into the night: %count% %verb%, %haul%", "Under the stars at %place%, line in the water: %haul%" } },
}

local function ordinal(n)
  local s = ns.thousands(n)
  local last2 = n % 100
  local suffix = (last2 >= 11 and last2 <= 13) and "th" or ({ "st", "nd", "rd" })[n % 10] or "th"
  return s .. suffix
end

local function haulText(items, order)
  local parts = {}
  for i, name in ipairs(order) do
    if i > 3 then parts[#parts] = parts[#parts] .. " and more"; break end
    parts[#parts + 1] = items[name] .. " " .. name
  end
  if #parts == 0 then return "nothing much" end
  if #parts == 1 then return parts[1] end
  return table.concat(parts, ", ", 1, #parts - 1) .. " and " .. parts[#parts]
end

local function minutes(s)
  s = math.floor((tonumber(s) or 0) / 60 + 0.5)
  if s >= 60 then return math.floor(s / 60) .. " h " .. (s % 60) .. " min" end
  return s .. " minutes"
end

----------------------------------------------------------------------------
-- Hauls and sessions
----------------------------------------------------------------------------
local pending, haul
local sessions = {}

local function endSession(kind)
  local s = sessions[kind]
  sessions[kind] = nil
  if not s or s.n < SESSION_MIN then return end
  local def = Wd.KINDS[kind]
  local late = J.tales and J.tales.lateNight and J.tales.lateNight()
  local lines = late and LINES.night[kind] or LINES.session[kind]
  local vars = { zone = s.zone, place = s.place or s.zone, time = minutes(s.last - s.start), count = s.n,
    verb = s.n == 1 and def.one or def.many, haul = haulText(s.items, s.order) }
  J.add(def.k, fill(pick(lines, kind .. s.start), vars), s.n .. " " .. def.many .. " in a row", { n = s.n })
end

local function addToSession(kind, items, order)
  local t = now()
  local s = sessions[kind]
  if s and (t - s.last > SESSION_GAP or s.zone ~= zone()) then endSession(kind); s = nil end
  if not s then
    local place = try(GetSubZoneText)
    s = { start = t, last = t, n = 0, items = {}, order = {}, zone = zone(),
      place = type(place) == "string" and place ~= "" and plain(place) or nil }
    sessions[kind] = s
  end
  s.last, s.n = t, s.n + 1
  for _, name in ipairs(order) do
    if not s.items[name] then s.order[#s.order + 1] = name; s.items[name] = 0 end
    s.items[name] = s.items[name] + items[name]
  end
end

local function isOdd(name)
  local low = name:lower()
  for _, w in ipairs(ODD) do if low:find(w, 1, true) then return true end end
end

local function closeHaul()
  local h = haul
  haul = nil
  if not h or #h.order == 0 then return end
  local kind, def = h.kind, Wd.KINDS[h.kind]
  local j = journal()
  local w = rec(kind)
  local l = J.level()
  local firstEver = (tonumber(w.n) or 0) == 0
  w.n = (tonumber(w.n) or 0) + 1
  w.byLevel[l] = (tonumber(w.byLevel[l]) or 0) + 1
  local z = zone()
  local wrote = false
  for _, name in ipairs(h.order) do
    w.items[name] = (tonumber(w.items[name]) or 0) + h.items[name]
    local q = h.q[name] or 1
    local vars = { zone = z, item = name }
    local extra = { i = h.ids[name], iq = q }
    if firstEver and not wrote then
      J.add(def.k, fill(pick(LINES.firstOf[kind], name), vars), "Your first " .. def.one, extra)
      wrote = true
      j.wildFirst[name] = true
    elseif q >= 2 or (kind == "fishing" and isOdd(name)) then
      J.add(def.k, fill(pick(LINES.rare[kind], name .. w.n), vars), "A rare find", extra)
      wrote = true
      j.wildFirst[name] = true
      if not w.best or q > (tonumber(w.best.q) or 0) then w.best = { name = name, q = q, l = l, i = h.ids[name] } end
    elseif not j.wildFirst[name] then
      j.wildFirst[name] = true
      if not wrote then
        J.add(def.k, fill(pick(LINES.newMaterial[kind], name), vars), nil, extra)
        wrote = true
      end
    end
  end
  for _, m in ipairs(MARKS) do
    if w.n == m then
      J.add(def.k, fill(pick(LINES.mark[kind], kind .. m), { zone = z, n = ordinal(m), N = ns.thousands(m) }),
        ns.thousands(m) .. " " .. def.many, { n = m })
    end
  end
  addToSession(kind, h.items, h.order)
  J.version = (J.version or 0) + 1
end
Wd.closeHaul = closeHaul

local function begin(kind)
  if haul and haul.kind ~= kind then closeHaul() end
  pending = { kind = kind, t = now() }
end

local function looted(text)
  if not pending or now() - pending.t > (WINDOW[pending.kind] or 12) then return end
  local read = J.tales and J.tales.read
  if not read then return end
  local a = read(text, "LOOT_ITEM_SELF_MULTIPLE", "You receive loot: %sx%d.")
  local n = a and tonumber(a[2])
  if not a then a = read(text, "LOOT_ITEM_SELF", "You receive loot: %s.") end
  if not a then a = read(text, "LOOT_ITEM_PUSHED_SELF", "You receive item: %s.") end
  if not a or type(a[1]) ~= "string" then return end
  local link = a[1]
  local name = plain(link:match("%[(.-)%]") or link)
  if name == "" then return end
  haul = haul or { kind = pending.kind, items = {}, order = {}, q = {}, ids = {}, at = now() }
  if not haul.items[name] then haul.order[#haul.order + 1] = name; haul.items[name] = 0 end
  haul.items[name] = haul.items[name] + (n or 1)
  haul.q[name] = quality(link) or haul.q[name]
  haul.ids[name] = itemID(link) or haul.ids[name]
  haul.at = now()
  if pending.kind == "fishing" then pending = nil end -- one catch per cast
end

local EVENTS = {
  UNIT_SPELLCAST_SUCCEEDED = function(unit, _, spell)
    if unit ~= "player" then return end
    local kind = kindOfSpell(spellName(spell))
    if kind then begin(kind) end
  end,
  LOOT_OPENED = function()
    local fishing = try(IsFishingLoot)
    if fishing == true or fishing == 1 then begin("fishing") end
  end,
  LOOT_CLOSED = function() if haul then closeHaul() end end,
  CHAT_MSG_LOOT = looted,
}

-- A haul with no LOOT_CLOSED (auto-loot on some clients) closes after 3 quiet seconds; a session
-- idle for 10 minutes is told.
local function tick()
  if haul and now() - haul.at >= 3 then closeHaul() end
  for kind, s in pairs(sessions) do
    if now() - s.last > SESSION_GAP then endSession(kind) end
  end
end
Wd.tick = tick

local frame
function ns.startJourneyWilds()
  if frame then return end
  journal()
  frame = CreateFrame("Frame")
  for event in pairs(EVENTS) do
    if event == "UNIT_SPELLCAST_SUCCEEDED" and frame.RegisterUnitEvent then
      pcall(frame.RegisterUnitEvent, frame, event, "player")
    else
      pcall(frame.RegisterEvent, frame, event)
    end
  end
  frame:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(EVENTS[event], ...)
    if not ok and not Wd.errored then Wd.errored = true; ns.say("journey error: " .. plain(err)) end
  end)
  ns.every(1, function()
    local ok, err = pcall(tick)
    if not ok and not Wd.errored then Wd.errored = true; ns.say("journey error: " .. plain(err)) end
  end)
end

----------------------------------------------------------------------------
-- The Trophies page: IN THE WILDS
----------------------------------------------------------------------------
local ORDER = { "mining", "herbalism", "skinning", "fishing" }
local LABEL = { mining = "Veins mined", herbalism = "Herbs picked", skinning = "Hides skinned", fishing = "Fish caught" }

local function wildsCard(V, y)
  local U, C, W = V.U, V.C, V.W
  local top = y
  y = y + U.sectionTitle("IN THE WILDS", y, "Gathering and fishing")
  local cw = math.floor((W - 18) / 4)
  for i, kind in ipairs(ORDER) do
    local x = (i - 1) * (cw + 6)
    local n = Wd.count(kind)
    U.box(x, y, cw, 70, C.panel)
    U.icon(Wd.KINDS[kind].icon, x + math.floor(cw / 2) - 11, y + 6, 22, LABEL[kind], nil)
    U.T(ns.thousands(n), x, y + 32, cw, "head", n > 0 and C.ink or C.inkSoft, "CENTER")
    U.T(LABEL[kind], x, y + 52, cw, "small", C.inkSoft, "CENTER")
  end
  y = y + 80
  -- the best finds and the most gathered
  local j = journal()
  local rows = {}
  for _, kind in ipairs(ORDER) do
    local w = j.wilds[kind]
    if type(w) == "table" then
      local most, mostN = nil, 0
      for name, n in pairs(type(w.items) == "table" and w.items or {}) do
        if (tonumber(n) or 0) > mostN then most, mostN = name, tonumber(n) end
      end
      if most then rows[#rows + 1] = { Wd.KINDS[kind].icon, "Most " .. Wd.KINDS[kind].verb .. ": " .. most, ns.thousands(mostN) } end
      if type(w.best) == "table" and w.best.name then
        rows[#rows + 1] = { J.draw.itemIcon(w.best.i, Wd.KINDS[kind].icon), "Best find: " .. w.best.name, "level " .. tostring(w.best.l or "?") }
      end
    end
  end
  if #rows == 0 then
    y = y + U.T("Mine a vein, pick a herb, skin a beast or cast a line, and the wilds start their own chapter here.", 10, y,
      W - 20, "small", C.inkSoft) + 8
  end
  for _, r in ipairs(rows) do
    U.icon(r[1], 10, y, 20, r[2], nil)
    U.T(r[2], 38, y + 3, W - 140, "small", C.ink)
    U.T(r[3], W - 110, y + 3, 100, "small", C.inkSoft, "RIGHT")
    y = y + 24
  end
  return y + 6
end

J.moreTrophies = J.moreTrophies or {}
J.moreTrophies[#J.moreTrophies + 1] = wildsCard
J.moreTrophies[#J.moreTrophies + 1] = function(V, y)
  if not (J.tales and J.tales.momentsCard) then return y end
  return J.tales.momentsCard("FROM THE LAND AND WATER", { mine = true, herb = true, skin = true, fish = true },
    "Your first finds, rare finds, long sessions and milestones of gathering and fishing are kept here.")(V, y)
end

function ns.journeyWildsDebugLines()
  local parts = {}
  for _, kind in ipairs(ORDER) do parts[#parts + 1] = kind .. " " .. Wd.count(kind) end
  return { "journey wilds: " .. table.concat(parts, ", ") .. (pending and (", waiting on " .. pending.kind) or "")
    .. (haul and (", haul of " .. #haul.order) or "") }
end
