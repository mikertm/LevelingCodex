-- TrainerGuide.lua: the class trainer card. At your class trainer it lists the guide's spells you
-- can learn now (Data.lua's trainer visits up to your level) with their total cost, and anything else
-- the trainer offers. Read-only: it never selects, buys or scrolls in the trainer window.
local _, ns = ...
local C, rgba, plain = ns.C, ns.rgba, ns.plain
local try = ns.quests.try
local WINDOWS = { "ClassTrainerFrame", "TrainerFrame" }
local card, theme
local place = {}   -- ns.placeByWindow's memory for the trainer window
local watched = {} -- windows whose OnHide hides the card
local seen        -- what the last visit read, for /codex debug

-- The guide's spells up to your level: { name, rank, text, icon }, first visit first.
local function guideSpells(level)
  local list, known = {}, {}
  for _, visit in ipairs(ns.D and ns.trainVisits() or {}) do
    if visit.level <= level then
      for i, spell in ipairs(visit.spells or {}) do
        local text = plain(spell)
        local name, rank = text:match("^(.-)%s*%((Rank %d+)%)$")
        name = name or text
        local key = name:lower() .. "|" .. (rank or ""):lower()
        if not known[key] then
          known[key] = true
          list[#list + 1] = { name = name, rank = rank, text = text, icon = visit.icons and visit.icons[i] }
        end
      end
    end
  end
  return list
end

local function services()
  local list = {}
  for i = 1, tonumber(try(GetNumTrainerServices)) or 0 do
    local name, rank, category = try(GetTrainerServiceInfo, i)
    if type(name) == "string" and name ~= "" and category ~= "header" then
      local skillName, skillLevel = try(GetTrainerServiceSkillReq, i)
      list[#list + 1] = { name = plain(name), rank = type(rank) == "string" and plain(rank) or "",
        category = category, cost = tonumber(try(GetTrainerServiceCost, i)) or 0,
        skillName = type(skillName) == "string" and skillName or nil, skillLevel = tonumber(skillLevel) }
    end
  end
  return list
end

-- A profession trainer (ProfessionData.lua): which guided profession it teaches, by the skill its
-- services ask for or a rank named after the profession.
local function professionOf(list)
  for _, s in ipairs(list) do
    for _, key in ipairs(ns.PROF_ORDER) do
      local P = ns.P and ns.P[key]
      if P and (s.skillName == P.name or s.name == P.name or s.name:find(" " .. P.name, 1, true)) then return key end
    end
  end
end

-- The rank a service teaches: "Blacksmithing" with rank "Expert", or "Expert Blacksmithing".
local function tierOf(P, s)
  for i, t in ipairs(P.tiers) do
    if (s.name == P.name and s.rank == t.name) or s.name == t.name .. " " .. P.name then return t, i end
  end
end

local function known(spell)
  if not (spell and IsPlayerSpell) then return nil end
  local ok, yes = pcall(IsPlayerSpell, spell)
  if ok then return yes == true end
end

-- What this trainer teaches for your route: the next rank when it's yours to train, the recipes from
-- your step to your cap (the next rank's cap when it's trainable here) it lists as available, the ones
-- it teaches later, and the first route recipe it doesn't list that you don't know.
local function professionRead(list)
  local key = professionOf(list)
  if not key then return nil end
  local P = ns.P[key]
  local skill, cap = ns.profSkill(key)
  local info = { key = key, P = P, skill = skill, now = {}, later = {}, total = 0 }
  local level = UnitLevel("player") or 1
  if not skill then
    for _, s in ipairs(list) do
      local t = tierOf(P, s)
      if t and t == P.tiers[1] then info.start = s end
    end
    return info
  end
  local trained, ti = ns.profTier(key, skill, cap)
  local nextTier = trained and P.tiers[ti + 1]
  local byName, tierService = {}, nil
  for _, s in ipairs(list) do
    if nextTier and tierOf(P, s) == nextTier then tierService = s else byName[s.name:lower()] = s end
  end
  local limit = cap or (trained and trained.cap) or 300
  if tierService and tierService.category == "available" then
    limit = nextTier.cap
    info.now[#info.now + 1] = nextTier.name .. " " .. P.name .. " (to " .. nextTier.cap .. ")"
    info.total, info.tier = info.total + tierService.cost, nextTier
  elseif nextTier and (skill < nextTier.skill or level < nextTier.level) then
    info.rankNote = nextTier.name .. " " .. P.name .. " at skill " .. nextTier.skill ..
      (nextTier.level > 1 and (" and level " .. nextTier.level) or "")
  elseif nextTier and not tierService then
    info.rankNote = nextTier.name .. " " .. P.name .. " isn't listed here: " .. ns.profBannerWhere(key, nextTier)
  end
  -- the route's recipes in range, each once: steps, the rods and parts they use, Mining's smelts
  local wanted, seenName = {}, {}
  local function want(name, range, learn, source, spell, entry)
    if name and not seenName[name] then
      seenName[name] = true
      wanted[#wanted + 1] = { name = name, range = range, learn = learn, source = source, spell = spell, entry = entry }
    end
  end
  for _, st in ipairs(P.steps) do
    if st.to > skill and st.from < limit then
      if st.name then want(st.name, st.from .. "-" .. st.to, st.learn, st.source, st.spell, st) end
      local rod = ns.profRod(key, st)
      if rod then want(rod.name, nil, rod.learn, rod.source, rod.spell, rod) end
      for _, m in ipairs(st.mats or {}) do
        local part = ns.profPart(key, m[1])
        if part and part.learn < limit then want(part.name, nil, part.learn, part.source, part.spell, part) end
      end
    end
  end
  for _, sm in ipairs(P.smelt or {}) do
    if sm.learn < limit then want(sm.name, nil, sm.learn, nil, sm.spell) end
  end
  for _, w in ipairs(wanted) do
    local s = byName[w.name:lower()]
    if s and s.category == "available" then
      info.now[#info.now + 1] = w.name .. (w.range and (" (" .. w.range .. ")") or "")
      info.total, info.recipes = info.total + s.cost, (info.recipes or 0) + 1
    elseif s and s.category == "unavailable" then
      local at = s.skillLevel or w.learn
      info.later[#info.later + 1] = { text = w.name .. " at " .. at, at = at, i = #info.later }
    elseif not s and not info.elsewhere and w.source and not w.source:find("^Known when")
        and known(w.spell) == false then
      local where = w.entry and ns.profWhereText(key, w.entry) or ""
      info.elsewhere = "Not taught here: " .. w.name .. " (learn at " .. w.learn .. "): " .. (where ~= "" and where or plain(w.source)) .. "."
    end
  end
  table.sort(info.later, function(a, b) if a.at ~= b.at then return a.at < b.at end return a.i < b.i end)
  for i, l in ipairs(info.later) do info.later[i] = l.text end
  return info
end

local function sameSpell(guide, service)
  if guide.name:lower() ~= service.name:lower() then return false end
  return not guide.rank or guide.rank:lower() == service.rank:lower()
end

-- What to train now: the guide's spells the trainer has as available, their cost, the rest on offer,
-- and whether this trainer teaches your guide at all (a profession trainer doesn't).
local function read()
  local level = UnitLevel("player") or 1
  local want = guideSpells(level)
  local now, extra, total, classTrainer, icon = {}, {}, 0, false, nil
  for _, s in ipairs(services()) do
    local guide
    for _, g in ipairs(want) do
      if sameSpell(g, s) then guide = g; break end
    end
    classTrainer = classTrainer or guide ~= nil
    if s.category == "available" then
      if guide then
        now[#now + 1], total, icon = guide.text, total + s.cost, icon or guide.icon
      else
        extra[#extra + 1] = s.name .. (s.rank ~= "" and (" (" .. s.rank .. ")") or "")
      end
    end
  end
  return { now = now, extra = extra, total = total, classTrainer = classTrainer, icon = icon, level = level }
end

local function window()
  for _, n in ipairs(WINDOWS) do
    local f = _G[n]
    if type(f) == "table" and type(f.IsVisible) == "function" and f:IsVisible() then return f, n end
  end
end

local function makeCard()
  local A = ns.art
  local h = A.frame("Frame", "LevelingCodexTrainerHint", UIParent)
  h:SetSize(440, 104)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(false) -- text only: nothing to click, nothing for the controller to land on
  h:Hide()
  A.cardChrome(h) -- the tooltip border, flat edges, or external UI's panel behind it
  h.glow = h:CreateTexture(nil, "BORDER")
  h.glow:SetPoint("TOPLEFT", 4, -4); h.glow:SetPoint("TOPRIGHT", -4, -4); h.glow:SetHeight(30)
  h.ring = h:CreateTexture(nil, "ARTWORK")
  h.ring:SetSize(42, 42); h.ring:SetPoint("TOPLEFT", 10, -12); h.ring:SetColorTexture(0.72, 0.58, 0.3, 0.95)
  h.icon = h:CreateTexture(nil, "ARTWORK", nil, 2)
  h.icon:SetSize(38, 38); h.icon:SetPoint("CENTER", h.ring, "CENTER"); h.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", h.ring, "TOPRIGHT", 10, 1)
  h.name = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h.name:SetPoint("TOPLEFT", h.label, "BOTTOMLEFT", 0, -2)
  h.name:SetFont(ns.headFont(), 18, "")
  h.name.codexHead = 18
  h.name:SetShadowOffset(1, -1)
  for _, k in ipairs({ "line", "status" }) do
    local fs = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetWidth(360); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
    h[k] = fs
  end
  h.line:SetPoint("TOPLEFT", h.name, "BOTTOMLEFT", 0, -2)
  h.status:SetPoint("TOPLEFT", h.line, "BOTTOMLEFT", 0, -4)
  return h
end

local function paint(h)
  ns.art.paintCard(h)
  h.name:SetTextColor(rgba(C.titleInk))
  h.line:SetTextColor(rgba(C.light))
  h.status:SetTextColor(rgba(C.dim))
  theme = ns.themeVersion
end

local function hideCard()
  if card then card:Hide() end
  place.edgeRoot = nil -- look for bars around the window again next time
end

local function list(names, most)
  if #names <= most then return table.concat(names, ", ") end
  local shown = {}
  for i = 1, most do shown[i] = names[i] end
  return table.concat(shown, ", ") .. " and " .. (#names - most) .. " more"
end

local function placeCard(root)
  if root then
    ns.placeByWindow(card, root, place)
    if not watched[root] and type(root.HookScript) == "function" then
      watched[root] = true
      pcall(root.HookScript, root, "OnHide", hideCard)
    end
  else
    card:ClearAllPoints()
    card:SetPoint("TOP", UIParent, "TOP", 0, -100)
  end
  card:Show()
end

local function plural(n, one, many) return n .. " " .. (n == 1 and one or many) end

local function showProfession(info)
  if not card then card = makeCard() end
  if theme ~= ns.themeVersion then paint(card) end
  card.label:SetText("PROFESSION TRAINER")
  local P, status = info.P, {}
  if not info.skill then
    card.name:SetText("Start " .. P.name .. " here")
    card.line:SetText("Learning " .. P.tiers[1].name .. " " .. P.name ..
      (info.start and info.start.cost > 0 and (" (" .. ns.money(info.start.cost) .. ")") or "") ..
      " starts its guide. Professions > Other guides shows the whole route now.")
  elseif #info.now > 0 then
    local what = info.tier and ("Train " .. info.tier.name .. ((info.recipes or 0) > 0 and (" + " .. plural(info.recipes, "recipe", "recipes")) or ""))
      or ("Learn " .. plural(#info.now, "recipe", "recipes"))
    card.name:SetText(what .. "  -  " .. ns.money(info.total))
    card.line:SetText(list(info.now, 8))
    local money = tonumber(try(GetMoney))
    if money and money < info.total then
      status[#status + 1] = "You have " .. ns.money(money) .. ": " .. ns.money(info.total - money) .. " short."
    end
  else
    card.name:SetText("Nothing to learn here yet")
    card.line:SetText(#info.later > 0 and ("Next here: " .. list(info.later, 4) .. ".") or
      ("Your " .. P.name .. " route needs nothing else from this trainer before your cap."))
  end
  if info.skill and #info.now > 0 and #info.later > 0 then status[#status + 1] = "Later here: " .. list(info.later, 4) .. "." end
  if info.rankNote then status[#status + 1] = info.rankNote .. "." end
  if info.elsewhere then status[#status + 1] = info.elsewhere end
  card.status:SetText(table.concat(status, "\n"))
  ns.setIcon(card.icon, P.icon or "INV_Misc_Book_09")
  card:SetHeight(math.max(84, 46 + card.line:GetStringHeight() + card.status:GetStringHeight() + 14))
  placeCard(window())
end

local function refresh()
  local trade = try(IsTradeskillTrainer)
  local info = read()
  seen = info
  if trade == true or trade == 1 or not info.classTrainer then
    local prof = not ns.db().noProfTrainer and professionRead(services())
    seen.profession = prof
    if prof then showProfession(prof) else hideCard() end
    return
  end
  if ns.db().noTrainerGuide then hideCard(); return end
  if not card then card = makeCard() end
  if theme ~= ns.themeVersion then paint(card) end
  card.label:SetText("CLASS TRAINER")
  local status = {}
  if #info.now > 0 then
    card.name:SetText("Train " .. #info.now .. (#info.now == 1 and " spell" or " spells") .. "  -  " .. ns.money(info.total))
    card.line:SetText(list(info.now, 12))
    local money = tonumber(try(GetMoney))
    if money and money < info.total then
      status[#status + 1] = "You have " .. ns.money(money) .. ": " .. ns.money(info.total - money) .. " short of all of them."
    end
  else
    card.name:SetText("Nothing from the guide to train")
    local visit = ns.nextTrain(info.level)
    card.line:SetText(visit and ("Next visit: level " .. visit.level .. " - " .. plain(table.concat(visit.spells, ", ")))
      or "Your guide has no more trainer visits.")
  end
  if #info.extra > 0 then status[#status + 1] = "Also here, not in the guide: " .. list(info.extra, 6) .. "." end
  card.status:SetText(table.concat(status, "\n"))
  ns.setIcon(card.icon, info.icon or "INV_Misc_Book_09")
  card:SetHeight(math.max(84, 46 + card.line:GetStringHeight() + card.status:GetStringHeight() + 14))
  placeCard(window())
end

local function safeRefresh()
  local ok, err = pcall(refresh)
  if not ok and not place.errored then
    place.errored = true
    ns.say("trainer guide error: " .. plain(err))
  end
end

function ns.startTrainerGuide()
  if place.events then return end
  local events = CreateFrame("Frame")
  place.events = events
  for _, ev in ipairs({ "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event)
    if event == "TRAINER_CLOSED" then hideCard(); return end
    if event == "TRAINER_UPDATE" and not (card and card:IsShown()) then return end
    safeRefresh()
    -- the window can open just after the event: place the card against it once it's there
    if event == "TRAINER_SHOW" then ns.after(0.3, function() if card and card:IsShown() then safeRefresh() end end) end
  end)
end

function ns.classTrainerDebugLines()
  if not seen then return { "class trainer: not visited this session" } end
  local _, name = window()
  local out = { "class trainer: " .. (seen.classTrainer and "yes" or "no") .. ", guide spells now: " .. #seen.now ..
    ", others available: " .. #seen.extra .. ", window: " .. tostring(name or "not found") }
  local p = seen.profession
  if p then
    out[#out + 1] = "profession trainer: " .. p.P.name .. ", route items now: " .. #p.now .. ", later: " .. #p.later ..
      (p.elsewhere and ", one taught elsewhere" or "")
  end
  return out
end
