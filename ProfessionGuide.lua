-- ProfessionGuide.lua: adds the current leveling step to the profession book's spell tooltips.
-- Beside a profession window it shows gathering advice or outlines the recommended recipe and
-- reports its live difficulty, craft count, and material availability.
--
-- Forever's crafting window is unconfirmed, so like the talent trace this tries known window names,
-- then discovered frames named *TradeSkill* / *Profession*, and finds the row by its text. Recipe
-- data comes from the classic calls (GetTradeSkillInfo) or C_TradeSkillUI, whichever exist.
--
-- The window is the player's: the guide only reads it. It never selects, scrolls or clicks in it
-- (doing that from an addon took the list away from the controller in Forever).

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
      if wok and (w or 0) >= 300 and (h or 0) >= 300 and n ~= "ProfessionsBookFrame" then guide.roots[f] = true end
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
  if name == "Smelting" or name == "Find Minerals" then return "MINING" end
  if name == "Find Herbs" then return "HERBALISM" end
  for _, key in ipairs(ns.PROF_ORDER) do
    local P = ns.P and ns.P[key]
    if P and P.name == name then return key end
  end
end

local function skillText(skill, cap)
  return skill .. (cap and (" / " .. cap) or "")
end

local function gatheringAdvice(key, step, skill)
  local names, zones = {}, ns.profZones(step)
  for _, name in ipairs(step.herbs or step.veins or {}) do
    local node = ns.profNode(key, name)
    if node and node.skill <= skill and ns.profNodeColor(node, skill) ~= "grey" then
      names[#names + 1] = node.name
      if #zones == 0 then zones = ns.profZones(node) end
    end
  end
  local targets = #names > 0 and ("Gather " .. table.concat(names, ", ")) or nil
  local places = #zones > 0 and ("Try " .. table.concat(zones, ", ", 1, math.min(3, #zones))) or nil
  return targets, places
end

-- The profession book uses the game's spellbook tooltip. Append the current
-- route to profession abilities without changing the tooltip's owner or contents.
local function addBookHint(tip, slot, bank)
  if ns.db().noCraftGuide then return end
  local name
  if C_SpellBook and C_SpellBook.GetSpellBookItemName then
    local ok, value = pcall(C_SpellBook.GetSpellBookItemName, slot, bank)
    if ok then name = value end
  end
  if not name and tip.GetSpell then
    local ok, value = pcall(tip.GetSpell, tip)
    if ok then name = value end
  end
  local key = type(name) == "string" and keyFor(name)
  local P = key and ns.P and ns.P[key]
  if not P then return end
  local skill, cap = ns.profSkill(key)
  if not skill then return end
  local goldR, goldG, goldB = rgba(C.gold)
  local r, g, b = rgba(C.light)
  tip:AddLine(" ")
  tip:AddLine("Leveling Codex  |  " .. P.name .. " " .. skillText(skill, cap), goldR, goldG, goldB)
  local step = ns.profStep(key, skill)
  if not step then
    tip:AddLine("Route complete", r, g, b)
    return
  end
  tip:AddLine(plain((step.name or step.title) .. " (skill " .. step.from .. "-" .. step.to .. ")"), r, g, b, true)
  if not step.name then
    local targets, places = gatheringAdvice(key, step, skill)
    if targets then tip:AddLine(plain(targets), r, g, b, true) end
    if places then tip:AddLine(plain(places), r, g, b, true) end
  end
end

local KIND = { optimal = "orange", medium = "yellow", easy = "green", trivial = "grey" }
local RELATIVE = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey" }
local DIFFICULTY = {
  orange = { "Orange", { 1, 0.64, 0.3 } },
  yellow = { "Yellow", { 1, 0.86, 0.46 } },
  green = { "Green", { 0.59, 0.88, 0.53 } },
}

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

-- Parts first when you have too few for the step, can make a batch, and know both recipes.
local function partFirst(key, step)
  if not GetItemCount then return nil end
  local function count(item)
    local ok, n = pcall(GetItemCount, item)
    return (ok and tonumber(n)) or 0
  end
  if not findRecipe(step.name) then return nil end
  for _, m in ipairs(step.mats or {}) do
    local part = ns.profPart(key, m[1])
    if part and count(m[1]) < m[2] and ns.profHasRod(key, ns.profRod(key, part)) ~= false then
      local canMake = ns.profPartAvailable(part)
      if canMake and canMake > 0 and findRecipe(part.name) then
        local reagent = #part.mats == 1 and part.mats[1][1] or nil
        return { name = part.name, spell = part.spell, icon = part.icon, yellow = part.yellow, grey = part.grey,
                 learn = part.learn, mats = part.mats, from = step.from, to = step.to, partOf = step,
                 plural = part.plural or part.name, reagent = reagent, have = reagent and count(reagent),
                 canMake = canMake }
      end
    end
  end
end

-- Rod first (Enchanting): the step needs a rod you don't have (nor a better one), and both the rod's
-- recipe and the step's are in the window.
local function rodFirst(key, step)
  local rod = ns.profRod(key, step)
  if not rod or ns.profHasRod(key, rod) ~= false then return nil end
  if not (findRecipe(step.name) and findRecipe(rod.name)) then return nil end
  return { name = rod.name, spell = rod.spell, icon = rod.icon, yellow = rod.yellow, grey = rod.grey, learn = rod.learn,
           mats = rod.mats, from = step.from, to = step.to, rodOf = step }
end

-- What to make at this skill: the crafting step (a missing rod or craftable part first), or the Mining smelt
-- you can know that has the best chance (one in the window first). A smelt is counted only while
-- it's orange (sure points, to yellow); after that the card gives its chance instead.
local function pickFor(key, skill)
  local P = ns.P[key]
  local step = ns.profStep(key, skill)
  if not step then return nil end
  if step.name then return rodFirst(key, step) or partFirst(key, step) or step end
  if not P.smelt then return { gathering = true, step = step } end
  local best, bestScore, bestListed, later
  for _, sname in ipairs(step.smelt or {}) do
    for _, s in ipairs(P.smelt or {}) do
      if s.name == sname then
        if s.learn > skill then
          later = later or s
        elseif skill < s.grey then
          local listed = findRecipe(s.name) ~= nil
          local score = chanceAt(s, skill) + (listed and 10 or 0)
          if not best or score > bestScore then best, bestScore, bestListed = s, score, listed end
        end
      end
    end
  end
  if not bestListed then return { none = true, step = step, later = later, smelt = best } end
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

local HINT_WIDTH, HINT_INSET = 378, 14

local function makeHint()
  local A = ns.art
  local h = A.frame("Frame", "LevelingCodexCraftHint", UIParent)
  h:SetSize(HINT_WIDTH, 100)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(false) -- text only: nothing on it to click or for the controller to land on
  h:Hide()
  A.cardChrome(h) -- the tooltip border, flat edges, or external UI's panel behind it
  h.glow = h:CreateTexture(nil, "BORDER")
  h.glow:SetPoint("TOPLEFT", 4, -4); h.glow:SetPoint("TOPRIGHT", -4, -4); h.glow:SetHeight(30)
  h.ring = h:CreateTexture(nil, "ARTWORK")
  h.ring:SetSize(36, 36); h.ring:SetPoint("TOPLEFT", HINT_INSET, -12)
  h.edge = h:CreateTexture(nil, "ARTWORK", nil, 1)
  h.edge:SetSize(34, 34); h.edge:SetPoint("CENTER", h.ring, "CENTER"); h.edge:SetColorTexture(0, 0, 0, 1)
  h.icon = h:CreateTexture(nil, "ARTWORK", nil, 2)
  h.icon:SetSize(32, 32); h.icon:SetPoint("CENTER", h.ring, "CENTER"); h.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", h.ring, "TOPRIGHT", 10, -1)
  h.name = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h.name:SetPoint("TOPLEFT", h.label, "BOTTOMLEFT", 0, -2)
  h.name:SetWidth(HINT_WIDTH - 2 * HINT_INSET - 46)
  h.name:SetJustifyH("LEFT")
  h.name:SetWordWrap(true)
  h.name:SetFont(ns.headFont(), 18, "")
  h.name.codexHead = 18
  h.name:SetShadowOffset(1, -1)
  h.rule = h:CreateTexture(nil, "ARTWORK")
  h.rule:SetHeight(1)
  for _, k in ipairs({ "line", "status", "detail" }) do
    local fs = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetWidth(HINT_WIDTH - 2 * HINT_INSET); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
    h[k] = fs
  end
  return h
end

local function layoutHint(h, line, status, detail)
  local y = math.max(54, 22 + h.label:GetStringHeight() + h.name:GetStringHeight())
  h.rule:ClearAllPoints()
  h.rule:SetPoint("TOPLEFT", HINT_INSET, -y)
  h.rule:SetPoint("TOPRIGHT", -HINT_INSET, -y)
  y = y + 8
  local lines = { line or "", status or "", detail or "" }
  for i, fs in ipairs({ h.line, h.status, h.detail }) do
    local text = lines[i]
    fs:SetText(text)
    fs:SetShown(text ~= "")
    if text ~= "" then
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", HINT_INSET, -y)
      y = y + fs:GetStringHeight() + 4
    end
  end
  h:SetHeight(y + 8)
end

local function paint()
  local t, h, a = guide.trace, guide.hint, C.accent
  for _, x in ipairs(t.edges) do x:SetColorTexture(a[1], a[2], a[3], 1) end
  t.fill:SetColorTexture(a[1], a[2], a[3], 1)
  ns.art.paintCard(h)
  h.rule:SetColorTexture(a[1], a[2], a[3], 0.35)
  h.name:SetTextColor(rgba(C.titleInk))
  h.status:SetTextColor(rgba(C.light))
  h.detail:SetTextColor(rgba(C.dim))
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

-- Every 0.25 s while a crafting window is open.
local function tick(root, rootName)
  if not root then root, rootName = craftWindow() end
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
  local P = key and ns.P and ns.P[key]
  if not P then
    if guide.open then hideGuide() end
    return
  end
  if not skill or skill <= 0 then skill, cap = ns.profSkill(key) end
  if not skill then
    if guide.open then hideGuide() end
    return
  end
  local pick = pickFor(key, skill)
  guide.trace = guide.trace or makeTrace()
  guide.hint = guide.hint or makeHint()
  if guide.theme ~= ns.themeVersion then paint() end
  guide.open, guide.rootName = true, rootName
  local h, t = guide.hint, guide.trace
  h.label:SetText(string.upper(P.name) .. "  " .. skillText(skill, cap))
  local line, status, detail, difficulty

  if not pick or pick.none or pick.gathering then
    ns.setIcon(h.icon, P.icon)
    if pick then
      local targets, places = gatheringAdvice(key, pick.step, skill)
      h.name:SetText(pick.none and "Mine for skill points" or plain(pick.step.title))
      if pick.none then
        if pick.smelt then
          line = pick.smelt.name .. " can also give skill points."
        else
          line = "Smelting gives no skill points at " .. skill .. "."
          if pick.later then line = line .. " " .. pick.later.name .. " can give points from " .. pick.later.learn .. "." end
        end
        status = targets and places and (targets .. ". " .. places .. ".") or targets or places
      else
        line = targets or ("Skill " .. pick.step.from .. "-" .. pick.step.to)
        status = places
      end
      status = status and plain(status)
      detail = plain(pick.step.note or "")
    else
      h.name:SetText("Route complete")
      line = "You reached " .. skill .. " " .. P.name .. "."
    end
    t:Hide(); guide.row, guide.how = nil, pick and "gathering" or "complete"
  else
    ns.setIcon(h.icon, pick.icon)
    h.name:SetText(pick.name)
    local found = findRecipe(pick.name)
    local n = (not pick.chanceOnly) and ns.craftsLeft(pick, skill)
    local prerequisite = pick.partOf or pick.rodOf
    if n then line = "About " .. n .. (n == 1 and " craft" or " crafts") .. " to skill " .. pick.to end
    if pick.chanceOnly then
      line = "About " .. math.floor(pick.chance * 100 + 0.5) .. "% chance of a point per smelt"
    end
    if pick.rodOf then
      line = "Make this rod first for " .. pick.rodOf.name .. "."
    elseif pick.partOf then
      line = "Make this first for " .. pick.partOf.name .. "."
      if pick.reagent then
        detail = pick.have .. " " .. pick.reagent .. " in your bags can make " .. pick.canMake .. " " .. pick.plural .. "."
      else
        detail = "You can make " .. pick.canMake .. " with your materials."
      end
    end
    if not found then
      local known
      if pick.spell and IsPlayerSpell then
        local ok, learned = pcall(IsPlayerSpell, pick.spell)
        if ok and type(learned) == "boolean" then known = learned end
      end
      if known then
        line = "Recipe hidden"
        status = "Clear the search or filters, or expand the recipe category."
        guide.how = "filtered"
      else
        local source = pick.source or (P.name .. " trainer")
        line = known == false and "Recipe not learned" or "Recipe unavailable"
        status = plain(source) .. (pick.learn and (" (skill " .. pick.learn .. ")") or "")
        if known == nil then status = status .. ". If you know it, check your search and filters." end
        if pick.alt and pick.alt ~= "" then detail = "Alternative: " .. plain(pick.alt) end
        guide.how = "not learned"
      end
      t:Hide(); guide.row = nil
    elseif found.color == "grey" and not prerequisite then  -- a bolt or rod is worth making even when grey
      local nxt = ns.profNext(key, skill)
      line = "Grey  |  No skill points"
      status = nxt and ("Next in the guide: " .. (nxt.name or nxt.title) .. " (skill " .. nxt.from .. ").")
      t:Hide(); guide.row, guide.how = nil, "grey"
    else
      difficulty = not prerequisite and DIFFICULTY[found.color]
      if found.available and not pick.partOf then
        status = found.available > 0 and ("Materials for " .. found.available .. (found.available == 1 and " craft" or " crafts"))
          or "Missing materials"
      end
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
        guide.how = "row"
      else
        t:Hide()
        local instruction = found.index and "Scroll to the recipe." or "Check filters or scroll to the recipe."
        detail = detail and (detail .. " " .. instruction) or instruction
        guide.how = "not shown"
      end
    end
  end
  guide.pick = pick and pick.name
  local color = difficulty and difficulty[2] or C.light
  h.line:SetTextColor(rgba(color))
  if difficulty then line = line and (difficulty[1] .. "  |  " .. line) or difficulty[1] end
  layoutHint(h, line, status, detail)
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
  if hooksecurefunc and GameTooltip and GameTooltip.SetSpellBookItem and GameTooltip.AddLine then
    pcall(hooksecurefunc, GameTooltip, "SetSpellBookItem", addBookHint)
  end
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
    local root, rootName
    if not guide.active then
      root, rootName = craftWindow()
      if not root then return end
    end
    local ok, err = pcall(tick, root, rootName)
    if not ok and not guide.errored then
      guide.errored = true
      ns.say("crafting guide error: " .. plain(err))
    end
  end)
end
