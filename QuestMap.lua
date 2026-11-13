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
-- Minimap: where the arrow leads (the step, QuestieDB's nearest spawn, a flight master on a trip,
-- your corpse) gets a pin, or an edge arrow on the rim while it's off the minimap; the next two
-- steps get small numbered pins (faded on the rim while they're off it). Gold dots run from you to
-- the pin and, for a step's way in, on through its tunnel points (a bend dot at each) to the step;
-- they fade toward the rim and stop once you're there, where the pin's ring pulses once. Hovering a pin names it; clicks go through to the
-- minimap. Positions are east/north yards from you times pixels per yard (half the minimap / its
-- view radius), turned with you when the minimap rotates. Nothing moves while you stand still: a
-- soft glow runs along the dots toward the step instead.
----------------------------------------------------------------------------

local OUTDOOR = { 466.67, 400, 333.33, 266.67, 200, 133.33 } -- view diameters in yards by zoom 0-5
local INDOOR = { 300, 240, 180, 120, 80, 50 }
local ARROW_TEXTURE = "Interface\\AddOns\\LevelingCodex\\media\\quest-arrow.tga"
local DOTS, BENDS = 48, 6 -- dot pool: you to the pin, then on through the way in; bend dots
local DOT_GAP, DOT_START, FADE = 10, 8, 20 -- px between dots, clear of you, fade-out before the rim
local LINE_ALPHA, DIM = 0.85, 0.6
local FLIGHT, SPOT = { type = "fly" }, { type = "spot" } -- icons for a trip's flight master, a road
local pins
local nexts, nextsKey = {}, "" -- the next steps with a spot ({ step, spot, n }), from the last refresh
local layoutKey, iconFor, pulsedKey, glowStep
local lit = {} -- the shown dots in route order: { texture, alpha before the glow }
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

-- How far out a spot is: to the rim of a round minimap, or the edge of a square one.
local function reach(x, y, square)
  return square and math.max(math.abs(x), math.abs(y)) or math.sqrt(x * x + y * y)
end

-- Pulled back onto the minimap's rim (a round one) or edge (a square one) when it's outside.
local function clamp(x, y, half, square)
  local limit = half * 0.95
  local r = reach(x, y, square)
  if r > limit then return x * limit / r, y * limit / r, true end
  return x, y, false
end

local function tip(self)
  local info = self.info
  if not (GameTooltip and info) then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(info.title)
  if info.sub then GameTooltip:AddLine(info.sub, 1, 1, 1, true) end
  if info.yards then GameTooltip:AddLine(math.floor(info.yards + 0.5) .. " yd away", 0.8, 0.8, 0.8) end
  GameTooltip:Show()
end

-- A pin: an icon that names its step on hover and lets clicks through to the minimap (where the
-- client can't split the two, no tooltip: the pin must not eat the minimap's clicks).
local function pinFrame(size, level)
  local f = CreateFrame("Frame", nil, pins)
  f:SetSize(size, size)
  f:SetFrameLevel(pins:GetFrameLevel() + level)
  f.icon = f:CreateTexture(nil, "OVERLAY")
  f.icon:SetPoint("CENTER")
  if type(f.SetMouseClickEnabled) == "function" and type(f.SetMouseMotionEnabled) == "function" then
    f:SetMouseMotionEnabled(true)
    f:SetMouseClickEnabled(false)
    f:SetScript("OnEnter", tip)
    f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  end
  f:Hide()
  return f
end

local function makePins()
  pins = CreateFrame("Frame", "LevelingCodexMinimapPins", Minimap)
  pins:SetAllPoints(Minimap)
  pins:SetFrameLevel((tonumber(Minimap:GetFrameLevel()) or 1) + 5)
  pins:Hide()
  local function pool(count, size, sub)
    local list = {}
    for i = 1, count do
      local d = pins:CreateTexture(nil, "ARTWORK", nil, sub)
      d:SetSize(size, size)
      d:SetColorTexture(1, 0.82, 0, 1)
      d:Hide()
      list[i] = d
    end
    return list
  end
  pins.dots, pins.bends = pool(DOTS, 3, 0), pool(BENDS, 5, 1)
  pins.next = {}
  for i = 1, 2 do
    local f = pinFrame(10, 1)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.label:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", -3, 4)
    f.label:SetText(tostring(i))
    pins.next[i] = f
  end
  local c = pinFrame(16, 3)
  pins.current = c
  -- arrival: the same gold ring as the arrow's, pulsing once
  c.ring = c:CreateTexture(nil, "BACKGROUND")
  c.ring:SetSize(32, 32)
  c.ring:SetPoint("CENTER")
  c.ring:Hide()
  if ns.art.hasFile(ICONS.spot) and type(c.ring.CreateAnimationGroup) == "function" then
    c.ring:SetTexture(ICONS.spot)
    Q.try(c.ring.SetBlendMode, c.ring, "ADD")
    c.ring:SetVertexColor(1, 0.82, 0.25)
    c.pulse = c.ring:CreateAnimationGroup()
    local grow = c.pulse:CreateAnimation("Scale")
    if type(grow.SetScaleFrom) == "function" then
      Q.try(grow.SetScaleFrom, grow, 0.6, 0.6)
      Q.try(grow.SetScaleTo, grow, 1.6, 1.6)
    else
      Q.try(grow.SetScale, grow, 1.6, 1.6)
    end
    grow:SetDuration(0.6)
    local fade = c.pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(0.6)
    c.pulse:SetScript("OnFinished", function() c.ring:Hide() end)
  end
  pins.edge = pinFrame(14, 3)
  pins.edge.icon:SetSize(14, 14)
  pins.edgeArt = ns.art.hasFile(ARROW_TEXTURE)
  if pins.edgeArt then pins.edge.icon:SetTexture(ARROW_TEXTURE) else pins.edge.icon:SetColorTexture(1, 0.82, 0, 1) end
end

local function hideAll()
  pins.current:Hide()
  pins.edge:Hide()
  for _, f in ipairs(pins.next) do f:Hide() end
  for _, d in ipairs(pins.dots) do d:Hide() end
  for _, d in ipairs(pins.bends) do d:Hide() end
  lit = {}
end

local function place(region, x, y)
  region:ClearAllPoints()
  region:SetPoint("CENTER", Minimap, "CENTER", x, y)
  region:Show()
end

-- Dots from (x1, y1) to (x2, y2), `skip1` / `skip2` px clear of the ends, from `pool` after its
-- first `used`; each fades out over the last FADE px before the rim. Returns how many are used.
local function dotted(pool, used, x1, y1, x2, y2, skip1, skip2, alpha, limit, square)
  local dx, dy = x2 - x1, y2 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  local r = skip1
  while r < len - skip2 and used < #pool do
    local x, y = x1 + dx * r / len, y1 + dy * r / len
    local f = math.min(1, (limit - reach(x, y, square)) / FADE)
    if f > 0.05 then
      used = used + 1
      place(pool[used], x, y)
      lit[#lit + 1] = { pool[used], alpha * f }
    end
    r = r + DOT_GAP
  end
  return used
end

-- The glow: every fourth dot is bright, stepping toward the step six times a second. Only the
-- dots' alpha changes, so standing still moves nothing.
local function glow(force)
  local step = math.floor((tonumber(GetTime()) or 0) * 6)
  if step == glowStep and not force then return end
  glowStep = step
  for i, entry in ipairs(lit) do
    entry[1]:SetAlpha(entry[2] * ((i - step) % 4 == 0 and 1 or DIM))
  end
end

-- The icon for what the arrow leads to: the step's own, a flight master's on a flight trip.
local function goalIcon(goal)
  if goal.kind == "corpse" then return SPOT end
  if goal.kind == "leg" then
    local caption = type(goal.caption) == "string" and goal.caption or ""
    return (caption:find("^Fly") or caption:find("^Learn")) and FLIGHT or SPOT
  end
  return goal.step
end

local function goalInfo(goal, yards)
  local caption = type(goal.caption) == "string" and Q.plain(goal.caption):gsub("\n.*", "") or nil
  if goal.kind == "corpse" then return { title = "Your corpse", yards = yards } end
  local label = Q.plain(Q.label(goal.step))
  if goal.kind == "step" or not caption then return { title = label, yards = yards } end
  return { title = caption, sub = (goal.kind == "leg" and "For: " or "") .. label, yards = yards }
end

local function pulse(key)
  if pulsedKey == key then return end
  pulsedKey = key
  local c = pins.current
  if c.pulse then
    c.pulse:Stop()
    c.ring:SetAlpha(1)
    c.ring:Show()
    c.pulse:Play()
  end
end

-- `chain`: the goal's spot, then the rest of a step's way in and the step (Q.pathRest).
-- `pinSpot`: the game's user waypoint the Codex set (ns.questMapPinSpot), or nil.
local function layout(map, x, y, half, radius, turn, square, goal, chain, pinSpot)
  hideAll()
  local ppy, limit = half / radius, half * 0.95
  local function screen(spot)
    if not (spot and spot.map and spot.x) then return end
    local bearing, yards = Q.vector(spot, map, x, y)
    if not bearing then bearing, yards = Q.worldVector(spot, map, x, y) end
    if not (bearing and yards) then return end
    local px, py = screenOffset(bearing + turn, yards * ppy)
    return px, py, yards, bearing
  end
  local lineOn = not ns.db().noMinimapLine
  local gx, gy, yards, bearing = screen(goal.spot)
  if not gx then return end
  local cx, cy, out = clamp(gx, gy, half, square)
  -- arrived only at the chain's last spot: near a tunnel point the arrow moves on by itself
  local here = #chain == 1 and goal.kind ~= "leg" and yards <= Q.arrived()
  local icon = goalIcon(goal)
  if iconFor ~= icon then
    iconFor = icon
    paintIcon(pins.current.icon, icon, 16, 8)
  end
  -- off the minimap at the Codex's own map pin, the game's waypoint arrow already sits on the rim
  local s = goal.spot
  local gameArrow = out and goal.kind == "step" and pinSpot and pinSpot.map == s.map
    and math.abs(pinSpot.x - s.x / 100) <= 0.0001 and math.abs(pinSpot.y - s.y / 100) <= 0.0001
  local pin = out and pins.edge or pins.current
  pin.info = goalInfo(goal, yards)
  if not gameArrow then place(pin, cx, cy) end
  if out and pins.edgeArt then Q.try(pins.edge.icon.SetRotation, pins.edge.icon, -(bearing + turn)) end
  if here and not out then pulse(goal.key) elseif not here then pulsedKey = nil end
  if lineOn and not here then
    local used = dotted(pins.dots, 0, 0, 0, cx, cy, DOT_START, 8, LINE_ALPHA, limit, square)
    -- on through the way in: a segment either end of which can't be placed draws nothing
    local fromX, fromY, bends = gx, gy, 0
    for i = 2, #chain do
      local nx, ny = screen(chain[i])
      if nx and fromX then
        used = dotted(pins.dots, used, fromX, fromY, nx, ny, i == 2 and 8 or 4, 4, LINE_ALPHA, limit, square)
      end
      if nx and reach(nx, ny, square) <= limit and bends < #pins.bends then
        bends = bends + 1
        place(pins.bends[bends], nx, ny)
      end
      fromX, fromY = nx, ny
    end
  end
  for _, t in ipairs(nexts) do
    local nx, ny, nyards = screen(t.spot)
    if not nx then break end -- another map: no pin and no line from here on
    local rx, ry, nout = clamp(nx, ny, half, square)
    local p = pins.next[t.n]
    p.info = { title = (t.n == 1 and "Next: " or "Then: ") .. Q.plain(Q.label(t.step)), yards = nyards }
    place(p, rx, ry)
    p:SetAlpha(nout and 0.4 or 0.8)
  end
  glow(true)
  -- a tooltip open on a pin follows the new distance
  for _, p in ipairs({ pins.current, pins.edge, pins.next[1], pins.next[2] }) do
    if GameTooltip and type(GameTooltip.IsOwned) == "function" and GameTooltip:IsOwned(p) then
      if p:IsShown() then tip(p) else GameTooltip:Hide() end
    end
  end
end

local function update()
  local map, x, y = Q.position()
  local half = (tonumber(Minimap:GetWidth()) or 0) / 2
  local radius = viewRadius()
  local goal = ns.questArrowGoal and ns.questArrowGoal()
  local spot = goal and goal.spot
  if not (map and x and half > 0 and radius and spot) then
    if layoutKey ~= "" then layoutKey = ""; hideAll() end
    return
  end
  local turn, square = rotation(), Q.try(GetMinimapShape) == "SQUARE"
  -- a step's way in: from the tunnel point the arrow leads to, on through the rest to the step
  local chain = { spot }
  if goal.kind == "step" and spot.world and goal.step and goal.step.path then
    for _, p in ipairs(Q.pathRest(goal.step)) do chain[#chain + 1] = p end
  end
  local pinSpot = ns.questMapPinSpot and ns.questMapPinSpot()
  -- lay out again only when something that places the pins changed
  local parts = { map, x, y, half, radius, turn, tostring(square), goal.kind, tostring(goal.key),
    tostring(goal.caption), tostring(spot.map), tostring(spot.x), tostring(spot.y), nextsKey,
    tostring(ns.db().noMinimapLine),
    pinSpot and (pinSpot.map .. ":" .. pinSpot.x .. ":" .. pinSpot.y) or "-" }
  for i = 2, #chain do parts[#parts + 1] = tostring(chain[i].map) .. ":" .. tostring(chain[i].x) .. ":" .. tostring(chain[i].y) end
  local key = table.concat(parts, "|")
  if key ~= layoutKey then
    layoutKey = key
    layout(map, x, y, half, radius, turn, square, goal, chain, pinSpot)
  else
    glow()
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
  return frame, type(scroll) == "table" and scroll.Child or nil, type(scroll) == "table" and scroll or nil
end

-- How much larger the map's zoom draws the canvas (1 = zoomed out).
local function zoom()
  local _, _, scroll = canvas()
  local s = scroll and tonumber((Q.try(scroll.GetCanvasScale, scroll)))
  return s and s > 0 and s or 1
end

function M.drawWorld()
  local frame, child = canvas()
  if not child then return end
  if not wpins then
    wpins = CreateFrame("Frame", "LevelingCodexWorldMapPins", child)
    wpins:SetAllPoints(child)
    wpins:SetFrameLevel((tonumber(child:GetFrameLevel()) or 1) + 20)
    -- zooming scales the canvas: pins are drawn again at 1 / zoom so they keep their size
    wpins:SetScript("OnUpdate", function() if zoom() ~= wpins.zoom then M.drawWorld() end end)
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
  local z = zoom()
  wpins.zoom = z
  local function put(pin, step, size, dot)
    local spot = Q.waypoint(step)
    if not (spot and spot.map == shown and spot.x and spot.y) then return end
    pin.step = step
    paintIcon(pin.icon, step, size, dot)
    -- a pin at 1 / zoom: its offsets are in its own units, so the canvas spot times the zoom
    pin:SetScale(1 / z)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", child, "TOPLEFT", spot.x / 100 * w * z, -spot.y / 100 * h * z)
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
  nexts, nextsKey = {}, ""
  if not row or ns.db().noMinimapSteps or not (viewer and viewer:IsShown()) or not Q.position() then
    pins:Hide()
    return
  end
  local parts = {}
  for n, nextRow in ipairs(Q.upcoming(i, 2)) do
    local spot = Q.waypoint(nextRow.step)
    if spot and spot.map and spot.x then
      nexts[#nexts + 1] = { step = nextRow.step, spot = spot, n = n }
      paintIcon(pins.next[n].icon, nextRow.step, 10, 6)
      parts[#parts + 1] = tostring(nextRow.key) .. "@" .. spot.map .. "," .. spot.x .. "," .. tostring(spot.y)
    end
  end
  nextsKey = table.concat(parts, ";")
  pins:Show()
  update()
end
