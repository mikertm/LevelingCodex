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
local guide = { roots = {} }

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

-- Walk a frame tree looking for the talent: by name first, then by its icon.
local function findTalentButton(root, name, fileID)
  local want = lower(name)
  local byIcon
  local function walk(f, depth)
    if depth > 12 or not f.IsShown or not f:IsShown() then return end
    local ok, kids = pcall(function() return { f:GetChildren() } end)
    if not ok then return end
    for _, k in ipairs(kids) do
      if k.IsShown and k:IsShown() then
        local n = buttonTalentName(k)
        if n and lower(n) == want then return k end
        if fileID and not byIcon and k.GetRegions then
          local rok, regions = pcall(function() return { k:GetRegions() } end)
          if rok then
            for _, r in ipairs(regions) do
              if r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture then
                local tok, tex = pcall(r.GetTexture, r)
                if tok and (tex == fileID) then byIcon = k end
              end
            end
          end
        end
        local found = walk(k, depth + 1)
        if found then return found end
      end
    end
  end
  return walk(root, 0) or byIcon
end

local function shownTalentRoot()
  for _, n in ipairs(TALENT_ROOTS) do
    local f = _G[n]
    if f and f.IsShown and f:IsShown() then return f end
  end
  for f in pairs(guide.roots) do
    if f:IsShown() then return f end
  end
end

-- Find extra talent windows by name (done rarely: on addon load and when a toggle is hooked).
local function discoverRoots()
  if not EnumerateFrames then return end
  local f = EnumerateFrames()
  local n = 0
  while f and n < 20000 do
    n = n + 1
    local ok, name = pcall(f.GetName, f)
    -- never our own trace/hint frames: they'd become the "talent window" and anchor to themselves
    if ok and name and not name:find("^LevelingCodex") and f:IsShown()
      and (name:find("Talent") or name:find("Trait")) and f:GetParent() == UIParent then
      guide.roots[f] = true
    end
    f = EnumerateFrames(f)
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

local function talentGuideTick()
  local root = (ns.D and not ns.db().noTalentGuide) and shownTalentRoot()
  if not root then
    if guide.trace then guide.trace:Hide() end
    if guide.hint then guide.hint:Hide() end
    guide.button = nil
    return
  end
  local level = UnitLevel("player")
  local hit, rank = ns.talentAt(level)
  if not hit then
    if guide.trace then guide.trace:Hide() end
    if guide.hint then guide.hint:Hide() end
    return
  end
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
  h.next:SetText(#nexts > 0 and ("Then  " .. table.concat(nexts, "   ")) or "")
  h:ClearAllPoints(); h:SetPoint("BOTTOM", root, "TOP", 0, 6)
  h:Show()

  -- trace the button
  local b = guide.button
  local now = GetTime and GetTime() or 0
  if not (b and b:IsShown() and guide.buttonFor == hit.name .. rank) and now >= (guide.nextSearch or 0) then
    b = findTalentButton(root, hit.name, iconFileID(hit.icon))
    guide.button, guide.buttonFor = b, hit.name .. rank
    guide.nextSearch = b and 0 or now + 1 -- not found yet: look again in a second
  end
  local t = guide.trace
  if b then
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    t.tag.text:SetText("Codex pick  " .. rank .. "/" .. hit.max)
    t.tag:SetWidth(t.tag.text:GetStringWidth() + 16)
    t:Show()
    h.next:SetText((h.next:GetText() or "") ~= "" and h.next:GetText() or "Click the traced talent.")
  else
    t:Hide()
    if (h.next:GetText() or "") == "" then h.next:SetText("Find it in the " .. hit.tree .. " tree.") end
  end
end

function ns.startTalentGuide()
  if guide.ticker or not C_Timer or not C_Timer.NewTicker then return end
  guide.ticker = C_Timer.NewTicker(0.25, talentGuideTick)
  -- hook the usual ways of opening the talent window so new windows are found quickly
  for _, fn in ipairs({ "ToggleTalentFrame", "ToggleLegacySystemUI", "TalentFrame_LoadUI", "PlayerSpellsFrame_Toggle" }) do
    if type(_G[fn]) == "function" and hooksecurefunc then
      pcall(hooksecurefunc, fn, function() C_Timer.After(0.1, discoverRoots) end)
    end
  end
end
