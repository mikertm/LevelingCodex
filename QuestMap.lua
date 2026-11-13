-- QuestMap.lua: the step icons (Blizzard's own gossip and cursor art, by step type) that the arrow,
-- the minimap, the world map and the step window share.
local _, ns = ...
local Q = ns.quests

local M = {}
ns.questMap = M

local ICONS = {
  accept = "Interface\\GossipFrame\\AvailableQuestIcon",
  turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
  kill = "Interface\\Cursor\\Attack",
  loot = "Interface\\Cursor\\LootAll",
  fly = "Interface\\GossipFrame\\TaxiGossipIcon",
  getfp = "Interface\\GossipFrame\\TaxiGossipIcon",
  sethearth = "Interface\\GossipFrame\\BinderGossipIcon",
  hearth = "Interface\\GossipFrame\\BinderGossipIcon",
  buy = "Interface\\GossipFrame\\VendorGossipIcon",
  train = "Interface\\GossipFrame\\TrainerGossipIcon",
  boss = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  dungeon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  plan = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  spot = "Interface\\TaxiFrame\\UI-Taxi-Icon-Highlight",
}
M.ICONS = ICONS

-- A complete step kills when its objectives say so ("slain", "killed") or the quest has creatures to
-- target and no item objective; otherwise it loots.
local function kills(step)
  local entry = step.quest and Q.log(step.quest)
  local texts = {}
  for _, obj in ipairs(entry and entry.objectives or {}) do
    if type(obj.text) == "string" then texts[#texts + 1] = obj.text end
  end
  for _, text in ipairs(type(step.objectives) == "table" and step.objectives or {}) do
    if type(text) == "string" then texts[#texts + 1] = text end
  end
  for _, text in ipairs(texts) do
    local lower = text:lower()
    if lower:find("slain", 1, true) or lower:find("killed", 1, true) then return true end
  end
  for _, obj in ipairs(entry and entry.objectives or {}) do
    if obj.type == "item" then return false end
  end
  local mobs = step.mobs or (ns.questMobs and step.quest and ns.questMobs[step.quest])
  return type(mobs) == "table" and #mobs > 0
end

-- The icon file for a step, or nil (the caller draws a gold dot) when the client lacks the file.
function ns.questIcon(step)
  if type(step) ~= "table" then return end
  local key = step.type
  if key == "complete" then key = kills(step) and "kill" or "loot" end
  local path = ICONS[key] or ICONS.spot
  if ns.art.hasFile(path) then return path end
end

-- Show a step's icon on a texture, or a gold dot of `dot` px when the client lacks the file.
local function paintIcon(tex, step, size, dot)
  local icon = ns.questIcon(step)
  if icon then
    tex:SetTexture(icon)
    tex:SetSize(size, size)
  else
    tex:SetColorTexture(1, 0.82, 0, 1)
    tex:SetSize(dot, dot)
  end
end
M.paintIcon = paintIcon

----------------------------------------------------------------------------
-- Minimap: the current step's pin (an edge arrow when it's off the minimap), the next two steps'
-- small numbered pins, and gold dots drifting from you toward the current step. Positions are the
-- step's east/north yards from you times pixels per yard (half the minimap / its view radius),
-- turned with you when the minimap rotates.
----------------------------------------------------------------------------

local OUTDOOR = { 466.67, 400, 333.33, 266.67, 200, 133.33 } -- view diameters in yards by zoom 0-5
local INDOOR = { 300, 240, 180, 120, 80, 50 }
local ARROW_TEXTURE = "Interface\\AddOns\\LevelingCodex\\media\\quest-arrow.tga"
local DOTS, DOT_GAP, DOT_START = 40, 10, 8
local pins
local targets = {} -- { step, n } : the current step first (n = nil), then the next ones (n = 1, 2)
local since = 0

local function viewRadius()
  local CM = C_Minimap
  if type(CM) == "table" and type(CM.GetViewRadius) == "function" then
    local r = tonumber((Q.try(CM.GetViewRadius)))
    if r and r > 0 then return r end
  end
  if type(Minimap.GetZoom) ~= "function" then return end
  local zoom = tonumber((Q.try(Minimap.GetZoom, Minimap)))
  if not zoom then return end
  local indoors = Q.try(IsIndoors)
  local diameter = ((indoors == true or indoors == 1) and INDOOR or OUTDOOR)[math.floor(zoom) + 1]
  return diameter and diameter / 2
end

-- The player's facing when the minimap turns with them, else 0.
local function rotation()
  if Q.try(GetCVar, "rotateMinimap") ~= "1" then return 0 end
  local facing = Q.try(GetPlayerFacing)
  if type(issecretvalue) == "function" and issecretvalue(facing) then return 0 end
  return type(facing) == "number" and facing or 0
end

-- Screen offset (right, up) of something `pixels` away at `angle` clockwise from the top.
local function screenOffset(angle, pixels)
  return math.sin(angle) * pixels, math.cos(angle) * pixels
end

-- Pulled back onto the minimap's rim (a round one) or edge (a square one) when it's outside.
local function clamp(x, y, half, square)
  local limit = half * 0.95
  local reach = square and math.max(math.abs(x), math.abs(y)) or math.sqrt(x * x + y * y)
  if reach > limit then return x * limit / reach, y * limit / reach, true end
  return x, y, false
end

local function makePins()
  pins = CreateFrame("Frame", "LevelingCodexMinimapPins", Minimap)
  pins:SetAllPoints(Minimap)
  pins:SetFrameLevel((tonumber(Minimap:GetFrameLevel()) or 1) + 5)
  pins:Hide()
  pins.dots = {}
  for i = 1, DOTS do
    local d = pins:CreateTexture(nil, "ARTWORK")
    d:SetSize(3, 3)
    d:SetColorTexture(1, 0.82, 0, 0.7)
    d:Hide()
    pins.dots[i] = d
  end
  pins.next = {}
  for i = 1, 2 do
    local t = pins:CreateTexture(nil, "OVERLAY")
    t:SetAlpha(0.6)
    t:Hide()
    t.label = pins:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t.label:SetPoint("TOPLEFT", t, "BOTTOMRIGHT", -3, 4)
    t.label:SetText(tostring(i))
    t.label:Hide()
    pins.next[i] = t
  end
  pins.current = pins:CreateTexture(nil, "OVERLAY", nil, 2)
  pins.current:Hide()
  pins.edge = pins:CreateTexture(nil, "OVERLAY", nil, 3)
  pins.edge:SetSize(14, 14)
  pins.edge:Hide()
  pins.edgeArt = ns.art.hasFile(ARROW_TEXTURE)
  if pins.edgeArt then pins.edge:SetTexture(ARROW_TEXTURE) else pins.edge:SetColorTexture(1, 0.82, 0, 1) end
end

local function hideAll()
  pins.current:Hide()
  pins.edge:Hide()
  for _, t in ipairs(pins.next) do t:Hide(); t.label:Hide() end
  for _, d in ipairs(pins.dots) do d:Hide() end
end

local function place(tex, x, y)
  tex:ClearAllPoints()
  tex:SetPoint("CENTER", Minimap, "CENTER", x, y)
  tex:Show()
end

local function drawLine(x, y, reach)
  local nx, ny = x / reach, y / reach
  local phase = ((tonumber(GetTime()) or 0) * DOT_GAP) % DOT_GAP
  local n = 0
  local r = DOT_START + phase
  while r < reach - 6 and n < DOTS do
    n = n + 1
    place(pins.dots[n], nx * r, ny * r)
    r = r + DOT_GAP
  end
end

local function update()
  hideAll()
  local map, x, y = Q.position()
  local half = (tonumber(Minimap:GetWidth()) or 0) / 2
  local radius = viewRadius()
  if not (map and x and half > 0 and radius) then return end
  local ppy, turn = half / radius, rotation()
  local square = Q.try(GetMinimapShape) == "SQUARE"
  for _, target in ipairs(targets) do
    local spot = target.n and target.spot or Q.waypoint(target.step)
    if spot and spot.map and spot.x then
      local bearing, yards = Q.vector(spot, map, x, y)
      if not bearing then bearing, yards = Q.worldVector(spot, map, x, y) end
      if bearing and yards then
        local px, py = screenOffset(bearing + turn, yards * ppy)
        local cx, cy, out = clamp(px, py, half, square)
        if not target.n then
          if out then
            place(pins.edge, cx, cy)
            if pins.edgeArt then Q.try(pins.edge.SetRotation, pins.edge, -(bearing + turn)) end
          else
            place(pins.current, px, py)
          end
          if not ns.db().noMinimapLine then drawLine(cx, cy, math.sqrt(cx * cx + cy * cy)) end
        elseif not out then
          local pin = pins.next[target.n]
          place(pin, px, py)
          pin.label:Show()
        end
      end
    end
  end
end

----------------------------------------------------------------------------
-- World map: the same pins (current 20 px, next ones 14 px with a number) on the map canvas, for
-- the steps on the map it shows; hovering one shows the step. Redrawn when the map opens, changes
-- map, and on every refresh while it's open. The game's own waypoint still marks the current step.
----------------------------------------------------------------------------

local wpins, hooked

local function worldPin(size)
  local b = CreateFrame("Button", nil, wpins)
  b:SetSize(size, size)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("CENTER")
  b:SetScript("OnEnter", function(self)
    if not (GameTooltip and self.step) then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(Q.plain(Q.label(self.step)))
    if type(self.step.text) == "string" then GameTooltip:AddLine(Q.plain(self.step.text), 1, 1, 1, true) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  b:Hide()
  return b
end

local function canvas()
  local frame = WorldMapFrame
  local scroll = type(frame) == "table" and frame.ScrollContainer
  return frame, type(scroll) == "table" and scroll.Child or nil
end

function M.drawWorld()
  local frame, child = canvas()
  if not child then return end
  if not wpins then
    wpins = CreateFrame("Frame", "LevelingCodexWorldMapPins", child)
    wpins:SetAllPoints(child)
    wpins:SetFrameLevel((tonumber(child:GetFrameLevel()) or 1) + 20)
    wpins.current = worldPin(20)
    wpins.next = { worldPin(14), worldPin(14) }
    for n, pin in ipairs(wpins.next) do
      pin.label = pin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      pin.label:SetPoint("TOPLEFT", pin, "BOTTOMRIGHT", -4, 4)
      pin.label:SetText(tostring(n))
    end
  end
  wpins.current:Hide()
  for _, pin in ipairs(wpins.next) do pin:Hide() end
  local viewer = _G.LevelingCodexQuestViewer
  local row, i = Q.current()
  if ns.db().noWorldMapSteps or not row or not frame:IsShown() or not (viewer and viewer:IsShown()) then
    wpins:Hide()
    return
  end
  local shown = Q.try(frame.GetMapID, frame)
  local w, h = tonumber(child:GetWidth()) or 0, tonumber(child:GetHeight()) or 0
  local function put(pin, step, size, dot)
    local spot = Q.waypoint(step)
    if not (spot and spot.map == shown and spot.x and spot.y) then return end
    pin.step = step
    paintIcon(pin.icon, step, size, dot)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", child, "TOPLEFT", spot.x / 100 * w, -spot.y / 100 * h)
    pin:Show()
  end
  put(wpins.current, row.step, 20, 10)
  for n, nextRow in ipairs(Q.upcoming(i, 2)) do put(wpins.next[n], nextRow.step, 14, 7) end
  wpins:Show()
end

local function hookWorldMap()
  local frame = canvas()
  if hooked or type(frame) ~= "table" then return end
  hooked = true
  if type(frame.HookScript) == "function" then pcall(frame.HookScript, frame, "OnShow", function() M.drawWorld() end) end
  if type(frame.OnMapChanged) == "function" and type(hooksecurefunc) == "function" then
    pcall(hooksecurefunc, frame, "OnMapChanged", function() M.drawWorld() end)
  end
end

-- Rebuild the pins for the current step (QuestGuide's refresh calls this).
function M.refresh()
  hookWorldMap()
  local frame = canvas()
  if type(frame) == "table" and frame:IsShown() then M.drawWorld() end
  if not Minimap then return end
  if not pins then
    makePins()
    pins:SetScript("OnUpdate", function(_, elapsed)
      since = since + (elapsed or 0)
      if since >= 0.05 then since = 0; update() end
    end)
  end
  local row, i = Q.current()
  local viewer = _G.LevelingCodexQuestViewer
  targets = {}
  if not row or ns.db().noMinimapSteps or not (viewer and viewer:IsShown()) or not Q.position() then
    pins:Hide()
    return
  end
  targets[1] = { step = row.step }
  paintIcon(pins.current, row.step, 16, 8)
  for n, nextRow in ipairs(Q.upcoming(i, 2)) do
    local spot = Q.waypoint(nextRow.step)
    if spot and spot.map and spot.x then
      targets[#targets + 1] = { step = nextRow.step, spot = spot, n = n }
      paintIcon(pins.next[n], nextRow.step, 10, 6)
    end
  end
  pins:Show()
  update()
end
