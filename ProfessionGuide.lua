-- ProfessionGuide.lua: in the crafting window (Blacksmithing, Smelting), outlines the recipe the
-- guide says to make now and shows a card beside the window: how many more, how many you have
-- materials for, the recipe's live colour, or where to learn it / what's next when it's grey.
--
-- Forever's crafting window is unconfirmed, so like the talent trace this tries known window names,
-- then discovered frames named *TradeSkill* / *Profession*, and finds the row by its text. Recipe
-- data comes from the classic calls (GetTradeSkillInfo) or C_TradeSkillUI, whichever exist.

local _, ns = ...
local C, rgba, plain = ns.C, ns.rgba, ns.plain

local WINDOWS = { "TradeSkillFrame", "ProfessionsFrame", "CraftFrame" }
local guide = { roots = {} }

local function visible(f)
  if not (f and f.IsVisible) then return false end
  local ok, v = pcall(f.IsVisible, f)
  return ok and v
end

local function nameOf(f)
  if not f.GetName then return nil end
  local ok, n = pcall(f.GetName, f)
  return ok and n or nil
end

local function isOurs(f)
  if f == guide.trace or f == guide.hint then return true end
  local n = nameOf(f)
  return type(n) == "string" and n:find("^LevelingCodex") ~= nil
end

-- Shown window-sized frames named like a crafting window (their names in Forever are unknown).
local function discoverRoots()
  if not EnumerateFrames then return end
  local ok, f = pcall(EnumerateFrames)
  local budget = 6000
  while ok and f and budget > 0 do
    budget = budget - 1
    local n = nameOf(f)
    if type(n) == "string" and (n:find("TradeSkill") or n:find("Profession")) and not isOurs(f) and visible(f) then
      local wok, w, h = pcall(function() return f:GetWidth(), f:GetHeight() end)
      if wok and (w or 0) >= 300 and (h or 0) >= 300 then guide.roots[f] = true end
    end
    ok, f = pcall(EnumerateFrames, f)
  end
end

local function craftWindow()
  for _, n in ipairs(WINDOWS) do
    local f = _G[n]
    if type(f) == "table" and visible(f) and not isOurs(f) then return f, n end
  end
  for f in pairs(guide.roots) do
    if visible(f) then return f, nameOf(f) or "(unnamed)" end
  end
end

-- The profession the window shows: name, skill, cap.
local function openProfession()
  if GetTradeSkillLine then
    local ok, n, r, m = pcall(GetTradeSkillLine)
    if ok and type(n) == "string" and n ~= "UNKNOWN" then return n, tonumber(r), tonumber(m) end
  end
  if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
    local ok, info = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
    if ok and type(info) == "table" and info.professionName then
      return info.professionName, tonumber(info.skillLevel), tonumber(info.maxSkillLevel)
    end
  end
end

local function keyFor(name)
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    if P and (P.name == name or (key == "MINING" and name == "Smelting")) then return key end
  end
end

local KIND = { optimal = "orange", medium = "yellow", easy = "green", trivial = "grey" }
local RELATIVE = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey" }

-- A recipe in the window's list: { index or id, color, available }, or nil. The classic list only
-- holds what the window shows (a search, a filter or a closed heading hide recipes), and some
-- clients keep the classic calls as empty stubs: then C_TradeSkillUI gets asked too.
local function findRecipe(name)
  if GetNumTradeSkills and GetTradeSkillInfo then
    local ok, count = pcall(GetNumTradeSkills)
    for i = 1, (ok and tonumber(count)) or 0 do
      local iok, n, kind, avail = pcall(GetTradeSkillInfo, i)
      if iok and n == name and kind ~= "header" then return { index = i, color = KIND[kind], available = tonumber(avail) } end
    end
  end
  if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo then
    local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    for _, id in ipairs((ok and type(ids) == "table") and ids or {}) do
      local iok, info = pcall(C_TradeSkillUI.GetRecipeInfo, id)
      if iok and type(info) == "table" and info.name == name and info.learned ~= false then
        return { id = id, color = RELATIVE[info.relativeDifficulty], available = tonumber(info.numAvailable) }
      end
    end
  end
end

-- Row text as the recipe's name: no colour codes, no "[3]" count, no padding.
local function cleanText(s)
  if type(s) ~= "string" then return nil end
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  s = s:gsub("%s*%[%d+%]%s*$", "")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function rowText(f)
  if f.GetText then
    local ok, t = pcall(f.GetText, f)
    if ok and type(t) == "string" then return cleanText(t) end
  end
end

-- The shown row whose text is the recipe. A button with that text wins; else a row-high frame
-- holding a matching font string (never the details pane, which shows the selected recipe's
-- name too).
local function findRow(root, name)
  local budget = 3000
  local holder
  local function walk(f, depth)
    if depth > 10 or budget <= 0 then return end
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    if not ok then return end
    for _, k in ipairs(kids) do
      budget = budget - 1
      if budget <= 0 then return end
      if visible(k) then
        if rowText(k) == name then return k end
        if not holder then
          local hok, h = pcall(k.GetHeight, k)
          if hok and type(h) == "number" and h > 0 and h <= 40 then
            local rok, regions = pcall(function() return { k:GetRegions() } end)
            for _, r in ipairs(rok and regions or {}) do
              local tok, kind = pcall(r.GetObjectType, r)
              if tok and kind == "FontString" and visible(r) and rowText(r) == name then holder = k end
            end
          end
        end
        local found = walk(k, depth + 1)
        if found then return found end
      end
    end
  end
  return walk(root, 0) or holder
end

local function stillRow(row, name) return visible(row) and rowText(row) == name end

-- The chance a craft or smelt gives a point at this skill (the game's rule).
local function chanceAt(r, skill)
  if skill < r.yellow then return 1 end
  if skill >= r.grey then return 0 end
  return (r.grey - skill) / (r.grey - r.yellow)
end

-- What to make in this window at this skill: the crafting step, or for Mining the step's smelt
-- you can know that has the best chance (one in the window first). A smelt is counted only while
-- it's orange (sure points, to yellow); after that the card gives its chance instead.
local function pickFor(key, skill)
  local P = ns.P[key]
  local step = ns.profStep(key, skill)
  if not step then return nil end
  if step.name then return step end
  local best, bestScore, later
  for _, sname in ipairs(step.smelt or {}) do
    for _, s in ipairs(P.smelt or {}) do
      if s.name == sname then
        if s.learn > skill then
          later = later or s
        elseif skill < s.grey then
          local score = chanceAt(s, skill) + (findRecipe(s.name) and 10 or 0)
          if not best or score > bestScore then best, bestScore = s, score end
        end
      end
    end
  end
  if not best then return { none = true, step = step, later = later } end
  local s = best
  local orange = skill < s.yellow
  return { name = s.name, spell = s.spell, icon = s.icon, yellow = s.yellow, grey = s.grey, learn = s.learn, mats = s.mats,
           from = step.from, to = math.min(step.to, orange and s.yellow or s.grey), smeltOf = step,
           chanceOnly = not orange, chance = chanceAt(s, skill) }
end

----------------------------------------------------------------------------
-- The outline and the card
----------------------------------------------------------------------------

local function makeTrace()
  local t = CreateFrame("Frame", "LevelingCodexCraftTrace", UIParent)
  t:SetFrameStrata("FULLSCREEN_DIALOG")
  t:EnableMouse(false)
  t:Hide()
  t.fill = t:CreateTexture(nil, "BACKGROUND")
  t.fill:SetAllPoints()
  t.edges = {}
  for i = 1, 4 do t.edges[i] = t:CreateTexture(nil, "OVERLAY") end
  local e = t.edges
  e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(2)
  e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(2)
  e[3]:SetPoint("TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT"); e[3]:SetWidth(2)
  e[4]:SetPoint("TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(2)
  t.time = 0
  t:SetScript("OnUpdate", function(self, elapsed)
    self.time = self.time + elapsed
    local pulse = 0.55 + 0.45 * math.sin(self.time * 4)
    for _, x in ipairs(self.edges) do x:SetAlpha(0.7 + 0.3 * pulse) end
    self.fill:SetAlpha(0.08 + 0.1 * pulse)
  end)
  return t
end

local function makeHint()
  local A = ns.art
  local h = A.frame("Frame", "LevelingCodexCraftHint", UIParent)
  h:SetSize(440, 104)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
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
  h.edge = h:CreateTexture(nil, "ARTWORK", nil, 1)
  h.edge:SetSize(40, 40); h.edge:SetPoint("CENTER", h.ring, "CENTER"); h.edge:SetColorTexture(0, 0, 0, 1)
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
  h.status:SetPoint("TOPLEFT", h.line, "BOTTOMLEFT", 0, -2)
  h.show = A.button(h, 70, 20)
  h.show:SetLabel("Show it")
  h.show:SetPoint("BOTTOMRIGHT", -10, 8)
  h.show.tipTitle, h.show.tipText = "Show it", "Selects the recipe in the crafting window."
  return h
end

local function paint()
  local t, h, a = guide.trace, guide.hint, C.accent
  for _, x in ipairs(t.edges) do x:SetColorTexture(a[1], a[2], a[3], 1) end
  t.fill:SetColorTexture(a[1], a[2], a[3], 1)
  if h.blizz then
    h:SetBackdropColor(0.03, 0.03, 0.05, 0.94)
    h:SetBackdropBorderColor(rgba(C.edge))
  else
    h.bg:SetColorTexture(rgba(C.bg))
    for _, e in ipairs(h.edges) do e:SetColorTexture(rgba(C.edge)) end
  end
  ns.fade(h.glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.25)
  h.label:SetTextColor(1, 0.82, 0); h.name:SetTextColor(rgba(C.titleInk))
  h.line:SetTextColor(rgba(C.light)); h.status:SetTextColor(rgba(C.dim))
  guide.theme = ns.themeVersion
end

local function hideGuide()
  if guide.trace then guide.trace:Hide() end
  if guide.hint then guide.hint:Hide() end
  guide.open, guide.row, guide.pick, guide.how = false, nil, nil, nil
  guide.nextRow, guide.rowEvery = 0, nil
  guide.edgeRoot = nil -- look for bars around the window again on the next open
end

-- Hide the outline and card as soon as the crafting window closes (the ticker is a fallback).
local function watchRoot(f)
  guide.watched = guide.watched or {}
  if guide.watched[f] or not f.HookScript then return end
  guide.watched[f] = true
  pcall(f.HookScript, f, "OnHide", function() if guide.open then hideGuide() end end)
end

local function selectRecipe(found)
  if found.index and SelectTradeSkill then
    pcall(SelectTradeSkill, found.index)
    if TradeSkillFrame_SetSelection then pcall(TradeSkillFrame_SetSelection, found.index) end
    -- the classic list doesn't scroll to a selection: put the recipe near the top of the list
    local list = _G.TradeSkillListScrollFrame
    if list and FauxScrollFrame_SetOffset then
      local offset = math.max(0, found.index - 2)
      pcall(FauxScrollFrame_SetOffset, list, offset)
      local bar = _G.TradeSkillListScrollFrameScrollBar
      if bar and bar.SetValue then pcall(bar.SetValue, bar, offset * (tonumber(_G.TRADE_SKILL_HEIGHT) or 16)) end
    end
    if TradeSkillFrame_Update then pcall(TradeSkillFrame_Update) end
  elseif found.id and C_TradeSkillUI then
    local fn = C_TradeSkillUI.OpenRecipe or C_TradeSkillUI.SetSelectedRecipe
    if fn then pcall(fn, found.id) end
  end
  guide.row, guide.nextRow, guide.rowEvery = nil, 0, nil -- look for the row again on the next tick
end

local function canSelect(found)
  return (found.index and SelectTradeSkill) or (found.id and C_TradeSkillUI and (C_TradeSkillUI.OpenRecipe or C_TradeSkillUI.SetSelectedRecipe))
end

-- Every 0.25 s while a crafting window is open.
local function tick()
  local root, rootName = craftWindow()
  if not root and guide.lookUntil and (GetTime and GetTime() or 0) < guide.lookUntil
      and (GetTime and GetTime() or 0) >= (guide.nextLook or 0) then
    -- the event can come before the window is on screen, and its name may be one we don't know
    discoverRoots()
    guide.lookEvery = math.min((guide.lookEvery or 0.5) * 2, 4)
    guide.nextLook = (GetTime and GetTime() or 0) + guide.lookEvery
    root, rootName = craftWindow()
  end
  if not root or ns.db().noCraftGuide then
    if guide.open then hideGuide() end
    return
  end
  watchRoot(root)
  local pname, skill, cap = openProfession()
  local key = pname and keyFor(pname)
  if not key then
    if guide.open then hideGuide() end
    return
  end
  if not skill or skill <= 0 then skill, cap = ns.profSkill(key) end
  if not skill then
    if guide.open then hideGuide() end
    return
  end
  local P = ns.P[key]
  local pick = pickFor(key, skill)
  guide.trace = guide.trace or makeTrace()
  guide.hint = guide.hint or makeHint()
  if guide.theme ~= ns.themeVersion then paint() end
  guide.open, guide.rootName = true, rootName
  local h, t = guide.hint, guide.trace
  h.label:SetText("LEVELING CODEX  -  " .. string.upper(P.name) .. " " .. skill)
  h.show:Hide()

  if not pick or pick.none then
    ns.setIcon(h.icon, P.icon)
    h.name:SetText(pick and plain(pick.step.title) or "Route done")
    h.line:SetText(pick and ("Smelting gives no points at " .. skill .. ": mine instead." ..
      (pick.later and ("  " .. pick.later.name .. " gives points from " .. pick.later.learn .. ".") or ""))
      or ("You've reached " .. skill .. "."))
    h.status:SetText(pick and plain(pick.step.note or "") or "")
    t:Hide(); guide.how = "none"
  else
    ns.setIcon(h.icon, pick.icon)
    h.name:SetText(pick.name)
    local found = findRecipe(pick.name)
    local n = (not pick.chanceOnly) and ns.craftsLeft(pick, skill)
    local line = n and ("About " .. n .. " more to " .. pick.to) or ""
    if pick.chanceOnly then
      line = "About a " .. math.floor(pick.chance * 100 + 0.5) .. "% chance of a point per smelt now"
    end
    if found and found.available then line = line .. "  -  you have materials for " .. found.available end
    h.line:SetText(line)
    if not found then
      local known = pick.spell and IsPlayerSpell and select(2, pcall(IsPlayerSpell, pick.spell)) == true
      if known then
        h.status:SetText("You know it, but it's not in the list: clear the search or filter, or open its heading.")
        guide.how = "filtered"
      else
        h.status:SetText("Not learned yet (or hidden by a filter): learn it at a " .. P.name .. " trainer (" ..
          (pick.learn or "?") .. ")." .. ((pick.alt and pick.alt ~= "") and ("  Instead: " .. plain(pick.alt)) or ""))
        guide.how = "not learned"
      end
      t:Hide(); guide.row = nil
    elseif found.color == "grey" then
      local nxt = ns.profNext(key, skill)
      h.status:SetText("Grey now: " .. (nxt and ("next is " .. (nxt.name or nxt.title) .. ".") or "the route is done."))
      t:Hide(); guide.row, guide.how = nil, "grey"
    else
      if guide.row and not stillRow(guide.row, pick.name) then guide.row = nil end
      if guide.rowFor ~= pick.name then guide.rowFor, guide.nextRow, guide.rowEvery = pick.name, 0, nil end
      local now = GetTime and GetTime() or 0
      if not guide.row and now >= (guide.nextRow or 0) then
        -- the search walks the whole window: while the row is out of view, look every 0.5, 1, then 2 s
        guide.row = findRow(root, pick.name)
        guide.rowEvery = (not guide.row) and math.min((guide.rowEvery or 0.25) * 2, 2) or nil
        guide.nextRow = now + (guide.rowEvery or 0)
      end
      local row = guide.row
      if row and pcall(function()
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", row, "TOPLEFT", -3, 3)
        t:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 3, -3)
      end) then
        t:Show()
        h.status:SetText((found.color or "?") .. " now. Make it here: the outlined recipe.")
        guide.how = "row"
      else
        t:Hide()
        h.status:SetText((found.color or "?") .. " now. It's in the list: scroll to it" ..
          (canSelect(found) and ", or press Show it." or "."))
        guide.how = "not shown"
        if canSelect(found) then
          h.show:SetScript("OnClick", function() selectRecipe(found) end)
          h.show:Show()
        end
      end
    end
  end
  guide.pick = pick and pick.name
  ns.placeByWindow(h, root, guide)
  h:Show()
end

function ns.craftDebugLines()
  local root, name = craftWindow()
  local out = { "crafting window: " .. (root and tostring(name) or "not open") }
  if guide.open then out[#out + 1] = "crafting pick: " .. tostring(guide.pick or "-") .. " by " .. tostring(guide.how) end
  return out
end

function ns.startCraftGuide()
  if guide.ticker then return end
  local events = CreateFrame("Frame")
  local any = false
  for _, ev in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_CLOSE" }) do
    if pcall(events.RegisterEvent, events, ev) then any = true end
  end
  events:SetScript("OnEvent", function(_, event)
    local now = GetTime and GetTime() or 0
    if event == "TRADE_SKILL_SHOW" then
      guide.active = true
      guide.lookUntil, guide.nextLook, guide.lookEvery = now + 10, now, 0.5
    elseif event == "TRADE_SKILL_CLOSE" then
      guide.active, guide.lookUntil = guide.polling, nil
      hideGuide()
      return
    end
    if guide.active then pcall(tick) end
  end)
  guide.polling = not any -- no crafting events in this client: keep looking for a window
  guide.active = guide.polling
  guide.ticker = ns.every(0.25, function()
    if not guide.active then return end
    local ok, err = pcall(tick)
    if not ok and not guide.errored then
      guide.errored = true
      ns.say("crafting guide error: " .. plain(err))
    end
  end)
end
