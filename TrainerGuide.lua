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
  for _, visit in ipairs(ns.D and ns.D.train or {}) do
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
      list[#list + 1] = { name = plain(name), rank = type(rank) == "string" and plain(rank) or "",
        category = category, cost = tonumber(try(GetTrainerServiceCost, i)) or 0 }
    end
  end
  return list
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
  h.blizz = A.backdrop(h, "tooltip")
  if not h.blizz then
    h.bg = h:CreateTexture(nil, "BACKGROUND"); h.bg:SetAllPoints()
    h.edges = {}
    for i = 1, 4 do h.edges[i] = h:CreateTexture(nil, "BORDER") end
    h.edges[1]:SetPoint("TOPLEFT"); h.edges[1]:SetPoint("TOPRIGHT"); h.edges[1]:SetHeight(1)
    h.edges[2]:SetPoint("BOTTOMLEFT"); h.edges[2]:SetPoint("BOTTOMRIGHT"); h.edges[2]:SetHeight(1)
    h.edges[3]:SetPoint("TOPLEFT"); h.edges[3]:SetPoint("BOTTOMLEFT"); h.edges[3]:SetWidth(1)
    h.edges[4]:SetPoint("TOPRIGHT"); h.edges[4]:SetPoint("BOTTOMRIGHT"); h.edges[4]:SetWidth(1)
  end
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
  h.name:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
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
  if h.blizz then
    h:SetBackdropColor(0.03, 0.03, 0.05, 0.94)
    h:SetBackdropBorderColor(rgba(C.edge))
  else
    h.bg:SetColorTexture(rgba(C.bg))
    for _, e in ipairs(h.edges) do e:SetColorTexture(rgba(C.edge)) end
  end
  ns.fade(h.glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.25)
  h.label:SetTextColor(1, 0.82, 0)
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

local function refresh()
  if ns.db().noTrainerGuide then hideCard(); return end
  local trade = try(IsTradeskillTrainer)
  local info = read()
  seen = info
  if trade == true or trade == 1 or not info.classTrainer then hideCard(); return end
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
  local root = window()
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
  return { "class trainer: " .. (seen.classTrainer and "yes" or "no") .. ", guide spells now: " .. #seen.now ..
    ", others available: " .. #seen.extra .. ", window: " .. tostring(name or "not found") }
end
