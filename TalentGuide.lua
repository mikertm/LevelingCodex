-- TalentGuide.lua: traces the talent the Codex says to take next in the talent window,
-- with a hint card above the window.
--
-- Forever runs talents on retail's C_Traits system and the talent window's frame and button
-- names are unconfirmed, so the finder tries several strategies: known window names, any
-- shown frame with "Talent"/"Trait" in its name, then the button by talent name (trait APIs)
-- or by icon (GetFileIDFromPath).

local _, ns = ...
local C, rgba = ns.C, ns.rgba

local TALENT_ROOTS = { "PlayerSpellsFrame", "ClassTalentFrame", "PlayerTalentFrame", "TalentFrame", "LegacySystemFrame" }
local guide = { roots = {}, watched = {} }

local function lower(s) return s and string.lower(s) or nil end

local function spellNameOf(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id); if ok and n then return n end
  end
  if GetSpellInfo then local ok, n = pcall(GetSpellInfo, id); if ok and n then return n end end
end

-- Best guess at a talent button's name, trying the trait system and older layouts.
local function buttonTalentName(b)
  local function try(fn, ...) local ok, a = pcall(fn, ...); if ok then return a end end
  if b.GetDefinitionInfo then
    local info = try(b.GetDefinitionInfo, b)
    if type(info) == "table" then
      if info.overrideName and info.overrideName ~= "" then return info.overrideName end
      local n = spellNameOf(info.spellID or info.overriddenSpellID); if n then return n end
    end
  end
  if b.GetSpellID then local n = spellNameOf(try(b.GetSpellID, b)); if n then return n end end
  if b.GetTalentName then local n = try(b.GetTalentName, b); if n then return n end end
  if type(b.talentName) == "string" then return b.talentName end
  if type(b.name) == "string" then return b.name end
end

local function iconFileID(name)
  if not name or name == "" or not GetFileIDFromPath then return nil end
  local ok, id = pcall(GetFileIDFromPath, "Interface\\Icons\\" .. name)
  if ok and id and id ~= 0 then return id end
end

local function shown(f)
  if not f or not f.IsShown then return false end
  local ok, s = pcall(f.IsShown, f)
  return ok and s
end

-- Does this frame carry the icon (a texture region showing fileID)?
local function hasIcon(f, fileID)
  if not fileID or not f.GetRegions then return false end
  local ok, regions = pcall(function() return { f:GetRegions() } end)
  if not ok then return false end
  for _, r in ipairs(regions) do
    if r.GetObjectType and r.GetTexture then
      local tok, kind = pcall(r.GetObjectType, r)
      if tok and kind == "Texture" then
        local gok, tex = pcall(r.GetTexture, r)
        if gok and tex == fileID then return true end
      end
    end
  end
  return false
end

local WALK_BUDGET = 4000 -- frames per search, so a huge tree can't stall a frame

-- Walk a frame tree looking for the talent: by name first, then by its icon.
-- Returns the button and how it matched ("name" or "icon").
local function findTalentButton(root, name, fileID)
  local want = lower(name)
  local byIcon
  local budget = WALK_BUDGET
  local function walk(f, depth)
    if depth > 12 or budget <= 0 or not shown(f) then return end
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    if not ok then return end
    for _, k in ipairs(kids) do
      budget = budget - 1
      if budget <= 0 then return end
      if shown(k) then
        local n = buttonTalentName(k)
        if n and lower(n) == want then return k end
        if not byIcon and hasIcon(k, fileID) then byIcon = k end
        local found = walk(k, depth + 1)
        if found then return found end
      end
    end
  end
  local b = walk(root, 0)
  if b then return b, "name" end
  if byIcon then return byIcon, "icon" end
end

-- Shown and every parent shown too (IsShown alone stays true inside a closed window).
local function visible(f)
  if not f then return false end
  if f.IsVisible then
    local ok, v = pcall(f.IsVisible, f)
    if ok then return v end
  end
  return shown(f)
end

-- Is the button we traced still showing that talent? (talent buttons are pooled and reused)
local function stillMatches(b, how, name, fileID)
  if not visible(b) then return false end
  if how == "icon" then return hasIcon(b, fileID) end
  local n = buttonTalentName(b)
  return n ~= nil and lower(n) == lower(name)
end

-- Our own frames must never be taken for the talent window.
local function isOurs(f)
  if f == guide.trace or f == guide.hint then return true end
  local ok, name = pcall(f.GetName, f)
  return ok and type(name) == "string" and name:find("^LevelingCodex") ~= nil
end

local function shownTalentRoot()
  for _, n in ipairs(TALENT_ROOTS) do
    local f = _G[n]
    if type(f) == "table" and shown(f) then return f end
  end
  for f in pairs(guide.roots) do
    if shown(f) then return f end
  end
end

-- Hide the trace and hint right away when the talent window closes (the ticker is a fallback).
local hideGuide
local function watchRoot(f)
  if guide.watched[f] or not f.HookScript then return end
  guide.watched[f] = true
  pcall(f.HookScript, f, "OnHide", function() if hideGuide then hideGuide() end end)
end

-- Find extra talent windows by name. Walks every frame, so it only runs when a talent
-- toggle fires (at most once a second) or a talent addon loads (force), and only while
-- no known talent window is shown.
local lastDiscover = -100
local function discoverRoots(force)
  if not EnumerateFrames then return end
  if shownTalentRoot() then return end
  local now = GetTime and GetTime() or 0
  if not force then
    if now - lastDiscover < 1 then return end
    lastDiscover = now
  end
  local f = EnumerateFrames()
  local n = 0
  while f and n < 20000 do
    n = n + 1
    local ok, name = pcall(f.GetName, f)
    if ok and type(name) == "string" and (name:find("Talent") or name:find("Trait")) and not isOurs(f)
      and shown(f) and f.GetParent and f:GetParent() == UIParent then
      -- a window, not a small always-on helper frame
      local wok, w, h = pcall(function() return f:GetWidth(), f:GetHeight() end)
      if wok and (w or 0) >= 200 and (h or 0) >= 150 then
        guide.roots[f] = true
        watchRoot(f)
      end
    end
    local nok, nextF = pcall(EnumerateFrames, f)
    f = nok and nextF or nil
  end
end
ns.discoverTalentRoots = discoverRoots

-- The traced outline: a glowing border, pulsing halo and a bright spark running around it.
local function makeTrace()
  local t = CreateFrame("Frame", "LevelingCodexTalentTrace", UIParent)
  t:SetFrameStrata("FULLSCREEN_DIALOG")
  t:EnableMouse(false)
  t:Hide()
  t.halo = t:CreateTexture(nil, "BACKGROUND")
  t.halo:SetPoint("TOPLEFT", -14, 14); t.halo:SetPoint("BOTTOMRIGHT", 14, -14)
  if t.halo:SetTexture("Interface\\SpellActivationOverlay\\IconAlert") ~= false then
    t.halo:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    t.halo:SetBlendMode("ADD")
  else
    t.halo:SetColorTexture(1, 1, 1, 0.15)
  end
  t.edges = {}
  for i = 1, 4 do t.edges[i] = t:CreateTexture(nil, "OVERLAY") end
  t.edges[1]:SetPoint("TOPLEFT", -3, 3); t.edges[1]:SetPoint("TOPRIGHT", 3, 3); t.edges[1]:SetHeight(2)
  t.edges[2]:SetPoint("BOTTOMLEFT", -3, -3); t.edges[2]:SetPoint("BOTTOMRIGHT", 3, -3); t.edges[2]:SetHeight(2)
  t.edges[3]:SetPoint("TOPLEFT", -3, 3); t.edges[3]:SetPoint("BOTTOMLEFT", -3, -3); t.edges[3]:SetWidth(2)
  t.edges[4]:SetPoint("TOPRIGHT", 3, 3); t.edges[4]:SetPoint("BOTTOMRIGHT", 3, -3); t.edges[4]:SetWidth(2)
  t.spark = t:CreateTexture(nil, "OVERLAY", nil, 2)
  t.spark:SetSize(14, 14)
  if t.spark:SetTexture("Interface\\Cooldown\\star4") == false then t.spark:SetColorTexture(1, 1, 1, 1) end
  t.spark:SetBlendMode("ADD")
  t.spark2 = t:CreateTexture(nil, "OVERLAY", nil, 2)
  t.spark2:SetSize(10, 10)
  if t.spark2:SetTexture("Interface\\Cooldown\\star4") == false then t.spark2:SetColorTexture(1, 1, 1, 1) end
  t.spark2:SetBlendMode("ADD")

  t.tag = CreateFrame("Frame", nil, t)
  t.tag:SetSize(10, 22)
  t.tag:SetPoint("BOTTOM", t, "TOP", 0, 8)
  t.tag.bg = t.tag:CreateTexture(nil, "BACKGROUND"); t.tag.bg:SetAllPoints()
  t.tag.line = t.tag:CreateTexture(nil, "BORDER")
  t.tag.line:SetPoint("BOTTOMLEFT"); t.tag.line:SetPoint("BOTTOMRIGHT"); t.tag.line:SetHeight(2)
  t.tag.text = t.tag:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  t.tag.text:SetPoint("CENTER", 0, 1)

  t.time = 0
  t:SetScript("OnUpdate", function(self, elapsed)
    self.time = self.time + elapsed
    local w0, h0 = self:GetWidth(), self:GetHeight()
    if not w0 or not h0 or w0 <= 0 then return end
    local w, h = w0 + 6, h0 + 6
    local per = 2 * (w + h)
    local function at(d)
      d = d % per
      if d < w then return -3 + d, 3 end
      d = d - w
      if d < h then return w - 3, 3 - d end
      d = d - h
      if d < w then return w - 3 - d, 3 - h end
      return -3, 3 - h + (d - w)
    end
    local x, y = at(self.time * per / 1.6)
    self.spark:ClearAllPoints(); self.spark:SetPoint("CENTER", self, "TOPLEFT", x, y)
    local x2, y2 = at(self.time * per / 1.6 + per / 2)
    self.spark2:ClearAllPoints(); self.spark2:SetPoint("CENTER", self, "TOPLEFT", x2, y2)
    local pulse = 0.55 + 0.45 * math.sin(self.time * 4)
    self.halo:SetAlpha(0.35 + 0.4 * pulse)
    for _, e in ipairs(self.edges) do e:SetAlpha(0.7 + 0.3 * pulse) end
  end)
  return t
end

local function paintTrace(t)
  local a = C.accent
  t.halo:SetVertexColor(a[1], a[2], a[3])
  for _, e in ipairs(t.edges) do e:SetColorTexture(a[1], a[2], a[3], 1) end
  t.spark:SetVertexColor(C.gem[1], C.gem[2], C.gem[3]); t.spark2:SetVertexColor(C.gem[1], C.gem[2], C.gem[3])
  t.tag.bg:SetColorTexture(rgba(C.panel)); t.tag.line:SetColorTexture(rgba(C.edge))
  t.tag.text:SetTextColor(rgba(C.gold))
end

-- The hint card at the top of the talent window.
local function makeHint()
  local h = CreateFrame("Frame", "LevelingCodexTalentHint", UIParent)
  h:SetSize(420, 58)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:EnableMouse(false)
  h:Hide()
  h.bg = h:CreateTexture(nil, "BACKGROUND"); h.bg:SetAllPoints()
  h.edges = {}
  for i = 1, 4 do h.edges[i] = h:CreateTexture(nil, "BORDER") end
  h.edges[1]:SetPoint("TOPLEFT"); h.edges[1]:SetPoint("TOPRIGHT"); h.edges[1]:SetHeight(1)
  h.edges[2]:SetPoint("BOTTOMLEFT"); h.edges[2]:SetPoint("BOTTOMRIGHT"); h.edges[2]:SetHeight(1)
  h.edges[3]:SetPoint("TOPLEFT"); h.edges[3]:SetPoint("BOTTOMLEFT"); h.edges[3]:SetWidth(1)
  h.edges[4]:SetPoint("TOPRIGHT"); h.edges[4]:SetPoint("BOTTOMRIGHT"); h.edges[4]:SetWidth(1)
  h.icon = h:CreateTexture(nil, "ARTWORK")
  h.icon:SetSize(38, 38); h.icon:SetPoint("LEFT", 10, 0); h.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", h.icon, "TOPRIGHT", 10, 0)
  h.name = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h.name:SetPoint("TOPLEFT", h.label, "BOTTOMLEFT", 0, -2)
  h.name:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
  h.next = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.next:SetPoint("TOPLEFT", h.name, "BOTTOMLEFT", 0, -2)
  h.next:SetWidth(350); h.next:SetJustifyH("LEFT"); h.next:SetWordWrap(false)
  return h
end

local function paintHint(h)
  h.bg:SetColorTexture(rgba(C.bg))
  for _, e in ipairs(h.edges) do e:SetColorTexture(rgba(C.edge)) end
  h.label:SetTextColor(rgba(C.goldDim)); h.name:SetTextColor(rgba(C.titleInk)); h.next:SetTextColor(rgba(C.dim))
end

hideGuide = function()
  if guide.trace then guide.trace:Hide() end
  if guide.hint then guide.hint:Hide() end
  guide.open = false
end

-- Runs every 0.25 s. Cheap once the talent is traced: one name check on the cached button.
local function talentGuideTick()
  local root = (ns.D and not ns.db().noTalentGuide) and shownTalentRoot()
  if root and isOurs(root) then guide.roots[root] = nil; root = nil end
  if not root then
    if guide.open then hideGuide() end
    return
  end
  watchRoot(root)
  local level = UnitLevel("player")
  local hit, rank = ns.talentAt(level)
  if not hit then
    if guide.open then hideGuide() end
    return
  end
  local now = GetTime and GetTime() or 0
  local key = hit.name .. rank
  local fileID = iconFileID(hit.icon)
  local dirty = false
  if not guide.open or root ~= guide.root or key ~= guide.key or guide.theme ~= ns.themeVersion then
    -- just opened, other window, new level or new theme: redraw, and look again now if needed
    guide.open, guide.root, guide.theme = true, root, ns.themeVersion
    if key ~= guide.key or root ~= guide.lastRoot then guide.button = nil end
    guide.lastRoot = root
    guide.key = key
    guide.nextSearch, guide.backoff = 0, 1
    dirty = true
  end
  if guide.button and not stillMatches(guide.button, guide.how, hit.name, fileID) then
    guide.button = nil
    guide.nextSearch, guide.backoff = 0, 1
    dirty = true
  end
  if not guide.button and now >= (guide.nextSearch or 0) then
    local b, how = findTalentButton(root, hit.name, fileID)
    if b then
      guide.button, guide.how = b, how
      dirty = true
    else
      -- not in view (other tab, still loading): back off 1, 2, 4, 8 s
      guide.nextSearch = now + guide.backoff
      guide.backoff = math.min((guide.backoff or 1) * 2, 8)
      if guide.traced then dirty = true end
    end
  end
  if not dirty then return end

  guide.trace = guide.trace or makeTrace()
  guide.hint = guide.hint or makeHint()
  paintTrace(guide.trace); paintHint(guide.hint)

  -- hint card above the talent window
  local h = guide.hint
  ns.setIcon(h.icon, hit.icon)
  h.label:SetText("LEVELING CODEX  -  LEVEL " .. level .. "  -  " .. string.upper(hit.tree))
  h.name:SetText(hit.name .. "  " .. rank .. "/" .. hit.max)
  local nexts = {}
  for l = level + 1, math.min(level + 2, 60) do
    local h2, r2 = ns.talentAt(l)
    if h2 then nexts[#nexts + 1] = l .. ": " .. h2.name .. " " .. r2 .. "/" .. h2.max end
  end
  local nextText = #nexts > 0 and ("Then  " .. table.concat(nexts, "   ")) or ""
  h:ClearAllPoints()
  if not pcall(h.SetPoint, h, "BOTTOM", root, "TOP", 0, 6) then h:SetPoint("TOP", UIParent, "TOP", 0, -80) end
  h:Show()

  -- trace the button
  local b, t = guide.button, guide.trace
  guide.traced = b ~= nil
  if b and pcall(function()
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
  end) then
    t.tag.text:SetText("Codex pick  " .. rank .. "/" .. hit.max)
    t.tag:SetWidth(t.tag.text:GetStringWidth() + 16)
    t:Show()
    h.next:SetText(nextText ~= "" and nextText or "Click the traced talent.")
  else
    t:Hide()
    h.next:SetText(nextText ~= "" and nextText or ("Find it in the " .. hit.tree .. " tree."))
  end
end

-- Hook the usual ways of opening the talent window so new windows are found quickly.
-- Called at login and again whenever a talent addon loads (its toggle may not exist before).
local hooked = {}
local function hookToggles()
  if not hooksecurefunc then return end
  for _, fn in ipairs({ "ToggleTalentFrame", "ToggleLegacySystemUI", "TalentFrame_LoadUI", "PlayerSpellsFrame_Toggle",
      "TogglePlayerSpellsFrame", "ToggleClassTalentFrame" }) do
    if not hooked[fn] and type(_G[fn]) == "function" then
      if pcall(hooksecurefunc, fn, function() ns.after(0.1, discoverRoots) end) then hooked[fn] = true end
    end
  end
end
ns.hookTalentToggles = hookToggles

function ns.startTalentGuide()
  hookToggles()
  if guide.ticker then return end
  guide.ticker = ns.every(0.25, function()
    local ok, err = pcall(talentGuideTick)
    if not ok and not guide.errored then
      guide.errored = true -- report once, keep ticking
      ns.say("talent guide error: " .. ns.plain(err))
    end
  end)
end
