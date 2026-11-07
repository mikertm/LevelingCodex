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

-- Unspent talent points and where the number came from (nil when the client can't tell us).
-- The trait system first (Forever's talent window), then the classic API.
local function unspentPoints()
  if C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo
    and C_Traits.GetTreeCurrencyInfo then
    local ok, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if ok and configID then
      local iok, info = pcall(C_Traits.GetConfigInfo, configID)
      if iok and type(info) == "table" and type(info.treeIDs) == "table" then
        local total, seen, any = 0, {}, false
        for _, treeID in ipairs(info.treeIDs) do
          local cok, list = pcall(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
          if cok and type(list) == "table" then
            for i, cur in ipairs(list) do
              local id = cur.traitCurrencyID or (treeID .. ":" .. i)
              if not seen[id] then
                seen[id] = true
                total = total + (tonumber(cur.quantity) or 0)
                any = true
              end
            end
          end
        end
        if any then return total, "C_Traits" end
      end
    end
  end
  if UnitCharacterPoints then
    local ok, n = pcall(UnitCharacterPoints, "player")
    if ok and type(n) == "number" then return n, "UnitCharacterPoints" end
  end
  return nil, "unknown"
end
ns.unspentTalentPoints = unspentPoints

-- The plan level of the next point to spend: with 2 points left at 30, that's level 29's.
local function nextPlanLevel(level, unspent)
  if not unspent then return level end
  local earned = math.max(0, level - 9)
  local spent = math.max(0, earned - unspent)
  return math.max(10, math.min(level, 10 + spent))
end

-- The talent button's own border art, so the trace takes its shape (circle, square, choice).
local BORDER_KEYS = { "StateBorder", "Border", "IconBorder", "Ring", "Frame", "BorderSheen" }
local function shapeName(s)
  s = lower(tostring(s or "")) or ""
  if s:find("circle") or s:find("round") then return "circle" end
  if s:find("choice") or s:find("octagon") then return "choice" end
  if s:find("square") then return "square" end
end

local function regionArt(r)
  if type(r) ~= "table" or not r.GetObjectType then return end
  local ok, kind = pcall(r.GetObjectType, r)
  if not ok or kind ~= "Texture" then return end
  local atlas
  if r.GetAtlas then
    local aok, a = pcall(r.GetAtlas, r)
    if aok and type(a) == "string" and a ~= "" then atlas = a end
  end
  local file
  if not atlas and r.GetTexture then
    local fok, f = pcall(r.GetTexture, r)
    if fok and f then file = f end
  end
  if not (atlas or file) then return end
  local coords
  if file and r.GetTexCoord then
    local cok, a, b, c, d, e, f2, g, h = pcall(r.GetTexCoord, r)
    if cok and a then coords = { a, b, c, d, e, f2, g, h } end
  end
  return { region = r, atlas = atlas, file = file, coords = coords, shape = shapeName(atlas or file) }
end

local function buttonShape(b)
  for _, k in ipairs(BORDER_KEYS) do
    local art = regionArt(b[k])
    if art then return art end
  end
  -- no border region: the icon mask still tells the shape
  for _, k in ipairs({ "IconMask", "Mask", "CircleMask" }) do
    local m = b[k]
    if type(m) == "table" then
      local name
      if m.GetAtlas then local ok, a = pcall(m.GetAtlas, m); if ok then name = a end end
      if not name and m.GetTexture then local ok, t = pcall(m.GetTexture, m); if ok then name = t end end
      local s = shapeName(name) or (k == "CircleMask" and "circle")
      if s then return { shape = s } end
    end
  end
  return { shape = "square" }
end

local function copyArt(tex, art)
  if art.atlas and tex.SetAtlas then
    if pcall(tex.SetAtlas, tex, art.atlas, false) then return true end
  end
  if art.file and tex:SetTexture(art.file) ~= false then
    if art.coords then pcall(tex.SetTexCoord, tex, unpack(art.coords)) end
    return true
  end
  return false
end

-- The traced outline: the talent's own border shape in the accent colour with a pulsing glow,
-- and two sparks running round it. Square boxes only when the button's shape can't be read.
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
  -- the drawn outline: four sides plus four diagonal corner cuts, matching Forever's talent
  -- nodes (squares with clipped corners). edges = sides then corners, so one loop paints all.
  t.edges = {}
  for i = 1, 8 do t.edges[i] = t:CreateTexture(nil, "OVERLAY") end
  t.corners = { t.edges[5], t.edges[6], t.edges[7], t.edges[8] }
  t.canCut = t.edges[5].SetRotation ~= nil
  -- c = how much of each corner is cut off, in pixels (0 = a plain box)
  function t.layoutBox(self, c)
    if not self.canCut then c = 0 end
    local e, o = self.edges, 3 -- o: the outline sits 3 px outside the button
    for _, x in ipairs(e) do x:ClearAllPoints() end
    e[1]:SetPoint("TOPLEFT", -o + c, o); e[1]:SetPoint("TOPRIGHT", o - c, o); e[1]:SetHeight(2)
    e[2]:SetPoint("BOTTOMLEFT", -o + c, -o); e[2]:SetPoint("BOTTOMRIGHT", o - c, -o); e[2]:SetHeight(2)
    e[3]:SetPoint("TOPLEFT", -o, o - c); e[3]:SetPoint("BOTTOMLEFT", -o, -o + c); e[3]:SetWidth(2)
    e[4]:SetPoint("TOPRIGHT", o, o - c); e[4]:SetPoint("BOTTOMRIGHT", o, -o + c); e[4]:SetWidth(2)
    self.cut = c
    if c <= 0 then
      for _, k in ipairs(self.corners) do k:Hide() end
      return
    end
    local len, half = c * 1.4142 + 1, c / 2
    -- each cut runs between the ends of two sides; rotation is counter-clockwise
    local spots = {
      { "TOPLEFT", -o + half, o - half, 45 },      -- up and to the right
      { "TOPRIGHT", o - half, o - half, -45 },     -- down and to the right
      { "BOTTOMRIGHT", o - half, -o + half, 45 },
      { "BOTTOMLEFT", -o + half, -o + half, -45 },
    }
    for i, s in ipairs(spots) do
      local k = self.corners[i]
      k:SetSize(len, 2)
      k:SetPoint("CENTER", self, s[1], s[2], s[3])
      k:SetRotation(math.rad(s[4]))
      k:Show()
    end
  end
  t:layoutBox(0)
  -- shape-matched outline and glow (copies of the button's border)
  t.shapeGlow = t:CreateTexture(nil, "BACKGROUND", nil, 1)
  t.shapeGlow:SetBlendMode("ADD")
  t.shapeLine = t:CreateTexture(nil, "OVERLAY")
  t.shapeLine:SetBlendMode("ADD")
  -- round glow when only the mask says "circle"
  t.disc = t:CreateTexture(nil, "BACKGROUND", nil, 2)
  t.disc:SetPoint("TOPLEFT", -6, 6); t.disc:SetPoint("BOTTOMRIGHT", 6, -6)
  t.disc.round = SetPortraitToTexture and pcall(SetPortraitToTexture, t.disc, "Interface\\Buttons\\WHITE8X8")
  if not t.disc.round then t.disc:SetColorTexture(1, 1, 1, 1) end
  t.disc:SetBlendMode("ADD")
  t.spark = t:CreateTexture(nil, "OVERLAY", nil, 2)
  t.spark:SetSize(14, 14)
  if t.spark:SetTexture("Interface\\Cooldown\\star4") == false then t.spark:SetColorTexture(1, 1, 1, 1) end
  t.spark:SetBlendMode("ADD")
  t.spark2 = t:CreateTexture(nil, "OVERLAY", nil, 2)
  t.spark2:SetSize(10, 10)
  if t.spark2:SetTexture("Interface\\Cooldown\\star4") == false then t.spark2:SetColorTexture(1, 1, 1, 1) end
  t.spark2:SetBlendMode("ADD")

  -- "Codex pick" tag in a tooltip-style box
  t.tag = ns.art.frame("Frame", nil, t)
  t.tag:SetSize(10, 22)
  t.tag:SetPoint("BOTTOM", t, "TOP", 0, 8)
  t.tag.blizz = ns.art.backdrop(t.tag, "tooltip")
  if not t.tag.blizz then
    t.tag.bg = t.tag:CreateTexture(nil, "BACKGROUND"); t.tag.bg:SetAllPoints()
    t.tag.line = t.tag:CreateTexture(nil, "BORDER")
    t.tag.line:SetPoint("BOTTOMLEFT"); t.tag.line:SetPoint("BOTTOMRIGHT"); t.tag.line:SetHeight(2)
  end
  t.tag.text = t.tag:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  t.tag.text:SetPoint("CENTER", 0, 0)

  t.time = 0
  t:SetScript("OnUpdate", function(self, elapsed)
    self.time = self.time + elapsed
    local w0, h0 = self:GetWidth(), self:GetHeight()
    if not w0 or not h0 or w0 <= 0 then return end
    local x, y, x2, y2
    if self.round then
      -- sparks orbit a circle or choice node
      local r = math.max(w0, h0) / 2 + 3
      local a = self.time * 2 * math.pi / 1.6
      x, y = w0 / 2 + r * math.cos(a), -h0 / 2 + r * math.sin(a)
      x2, y2 = w0 / 2 + r * math.cos(a + math.pi), -h0 / 2 + r * math.sin(a + math.pi)
    else
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
      x, y = at(self.time * per / 1.6)
      x2, y2 = at(self.time * per / 1.6 + per / 2)
    end
    self.spark:ClearAllPoints(); self.spark:SetPoint("CENTER", self, "TOPLEFT", x, y)
    self.spark2:ClearAllPoints(); self.spark2:SetPoint("CENTER", self, "TOPLEFT", x2, y2)
    local pulse = 0.55 + 0.45 * math.sin(self.time * 4)
    self.halo:SetAlpha(0.35 + 0.4 * pulse)
    self.shapeGlow:SetAlpha(0.3 + 0.45 * pulse)
    self.shapeLine:SetAlpha(0.75 + 0.25 * pulse)
    self.disc:SetAlpha(0.12 + 0.18 * pulse)
    for _, e in ipairs(self.edges) do e:SetAlpha(0.7 + 0.3 * pulse) end
  end)
  return t
end

local function paintTrace(t)
  local a = C.accent
  t.halo:SetVertexColor(a[1], a[2], a[3])
  for _, e in ipairs(t.edges) do e:SetColorTexture(a[1], a[2], a[3], 1) end
  t.shapeGlow:SetVertexColor(a[1], a[2], a[3]); t.shapeLine:SetVertexColor(C.gem[1], C.gem[2], C.gem[3])
  t.disc:SetVertexColor(a[1], a[2], a[3])
  t.spark:SetVertexColor(C.gem[1], C.gem[2], C.gem[3]); t.spark2:SetVertexColor(C.gem[1], C.gem[2], C.gem[3])
  if t.tag.blizz then
    t.tag:SetBackdropColor(0.03, 0.03, 0.05, 0.92)
    t.tag:SetBackdropBorderColor(rgba(C.edge))
  else
    t.tag.bg:SetColorTexture(rgba(C.panel)); t.tag.line:SetColorTexture(rgba(C.edge))
  end
  t.tag.text:SetTextColor(1, 0.82, 0)
end

-- Fit the trace to the button: copy its border when we can read it, else a box or a disc.
local function shapeTrace(t, b)
  local art = buttonShape(b)
  t.shape = art.shape
  t.round = art.shape == "circle" or art.shape == "choice"
  local copied = false
  if art.region then
    copied = copyArt(t.shapeLine, art) and copyArt(t.shapeGlow, art)
    if copied then
      t.shapeLine:ClearAllPoints()
      t.shapeLine:SetPoint("TOPLEFT", art.region, "TOPLEFT", -2, 2)
      t.shapeLine:SetPoint("BOTTOMRIGHT", art.region, "BOTTOMRIGHT", 2, -2)
      t.shapeGlow:ClearAllPoints()
      t.shapeGlow:SetPoint("TOPLEFT", art.region, "TOPLEFT", -9, 9)
      t.shapeGlow:SetPoint("BOTTOMRIGHT", art.region, "BOTTOMRIGHT", 9, -9)
    end
  end
  t.copied = copied
  t.shapeLine:SetShown(copied); t.shapeGlow:SetShown(copied)
  local box = not copied and not t.round
  for _, e in ipairs(t.edges) do e:SetShown(box) end
  if box then
    -- Forever's square nodes have their corners clipped by about an eighth of their width
    local ok, w = pcall(b.GetWidth, b)
    w = (ok and tonumber(w)) or 40
    t:layoutBox(math.max(3, math.min(12, math.floor(w * 0.13 + 0.5))) + 1)
  end
  t.halo:SetShown(box)
  t.disc:SetShown(not copied and t.round)
end

-- The hint card above the talent window, in a tooltip-style Blizzard border.
local function makeHint()
  local A = ns.art
  local h = A.frame("Frame", "LevelingCodexTalentHint", UIParent)
  h:SetSize(430, 62)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:EnableMouse(false)
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
  h.ring:SetSize(42, 42); h.ring:SetPoint("LEFT", 10, 0); h.ring:SetColorTexture(0.72, 0.58, 0.3, 0.95)
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
  h.next = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.next:SetPoint("TOPLEFT", h.name, "BOTTOMLEFT", 0, -2)
  h.next:SetWidth(360); h.next:SetJustifyH("LEFT"); h.next:SetWordWrap(false)
  return h
end

local function paintHint(h)
  if h.blizz then
    h:SetBackdropColor(0.03, 0.03, 0.05, 0.94)
    h:SetBackdropBorderColor(rgba(C.edge))
  else
    h.bg:SetColorTexture(rgba(C.bg))
    for _, e in ipairs(h.edges) do e:SetColorTexture(rgba(C.edge)) end
  end
  ns.fade(h.glow, "VERTICAL", C.glow[1], C.glow[2], C.glow[3], 0, 0.25)
  h.label:SetTextColor(1, 0.82, 0); h.name:SetTextColor(rgba(C.titleInk)); h.next:SetTextColor(rgba(C.dim))
end

hideGuide = function()
  if guide.trace then guide.trace:Hide() end
  if guide.hint then guide.hint:Hide() end
  guide.open = false
end

-- Runs every 0.25 s. Cheap once the talent is traced: one name check on the cached button.
-- Shows only while there's a talent point to spend (when the client can tell us).
local function talentGuideTick()
  local root = (ns.D and not ns.db().noTalentGuide) and shownTalentRoot()
  if root and isOurs(root) then guide.roots[root] = nil; root = nil end
  if not root then
    if guide.open then hideGuide() end
    return
  end
  watchRoot(root)
  local level = UnitLevel("player")
  local unspent, source = unspentPoints()
  guide.unspent, guide.source = unspent, source
  if unspent and unspent <= 0 then
    if guide.open then hideGuide() end
    return
  end
  local planLevel = nextPlanLevel(level, unspent)
  local hit, rank = ns.talentAt(planLevel)
  if not hit then
    if guide.open then hideGuide() end
    return
  end
  local now = GetTime and GetTime() or 0
  local key = hit.name .. rank .. ":" .. tostring(unspent)
  local fileID = iconFileID(hit.icon)
  local dirty = false
  if not guide.open or root ~= guide.root or key ~= guide.key or guide.theme ~= ns.themeVersion then
    -- just opened, other window, other point or new theme: redraw, and look again now if needed
    guide.open, guide.root, guide.theme = true, root, ns.themeVersion
    if hit.name ~= guide.talent or root ~= guide.lastRoot then guide.button = nil end
    guide.lastRoot, guide.talent = root, hit.name
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
  local points = (unspent and unspent > 1) and (unspent .. " POINTS TO SPEND") or ("LEVEL " .. planLevel)
  h.label:SetText("LEVELING CODEX  -  " .. points .. "  -  " .. string.upper(hit.tree))
  h.name:SetText(hit.name .. "  " .. rank .. "/" .. hit.max)
  local nexts = {}
  for l = planLevel + 1, math.min(planLevel + 2, 60) do
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
    shapeTrace(t, b)
    t.tag.text:SetText("Codex pick  " .. rank .. "/" .. hit.max)
    t.tag:SetWidth(t.tag.text:GetStringWidth() + 18)
    t:Show()
    h.next:SetText(nextText ~= "" and nextText or "Click the traced talent.")
  else
    t:Hide()
    h.next:SetText(nextText ~= "" and nextText or ("Find it in the " .. hit.tree .. " tree."))
  end
end

-- For /codex debug: what the talent guide can see right now.
function ns.talentDebugLines()
  local out = {}
  local root = shownTalentRoot()
  local rname = root and root.GetName and select(2, pcall(root.GetName, root)) or nil
  out[#out + 1] = "talent window: " .. (root and tostring(rname or "(unnamed)") or "not open")
  local n, source = unspentPoints()
  out[#out + 1] = "unspent points: " .. tostring(n) .. " (from " .. source .. ")"
  local discovered = 0
  for _ in pairs(guide.roots) do discovered = discovered + 1 end
  out[#out + 1] = "discovered windows: " .. discovered .. ", hooked toggles: " .. ns.hookedToggleCount()
  if guide.button then
    local t = guide.trace
    out[#out + 1] = "traced: " .. tostring(guide.talent) .. " by " .. tostring(guide.how) .. ", shape " ..
      tostring(t and t.shape) .. (t and t.copied and " (border copied)" or " (drawn)")
  else
    out[#out + 1] = "traced: nothing" .. (root and " (talent not found in the window)" or "")
  end
  return out
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
function ns.hookedToggleCount()
  local n = 0
  for _ in pairs(hooked) do n = n + 1 end
  return n
end

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
