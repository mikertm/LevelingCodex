-- The on-screen guide, navigation and opt-in recorder.
local _, ns = ...
local Q, A, C = ns.quests, ns.art, ns.C
local try = Q.try
local viewer, arrow, header, headerArt, title, arrowText, arrowArt, flatBackground, levels, arrowFile
local arrowBearing, arrowCaption, arrowFacing
local dismissed, painting, theme
local nextButton, suggestionButton, bar
local lastRow, quiet -- the step shown last; quiet = the player moved it (no completion sound)
local announced = {} -- dungeon runs whose "find a group" note was said this session
local itemButton, itemPending, updateItemButton -- itemButton false = the client can't make one
local recorder, objectiveCounts, onTaxi, flightPaths, flightTarget
local events = CreateFrame("Frame")
local ARROW_TEXTURE = "Interface\\AddOns\\LevelingCodex\\media\\quest-arrow.tga"
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local BAR_TRACK = 282 -- the bar's track width (the percent sits to its right)
local RING_TEXTURE = "Interface\\TaxiFrame\\UI-Taxi-Icon-Highlight"
local ringArt -- the ring file exists (else the arrival shows the icon alone)
local COMPASS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

local function turnArrow()
  if not arrowBearing then return end
  local facing = try(GetPlayerFacing)
  if facing == arrowFacing then return end
  arrowFacing = facing
  -- The bearing increases clockwise. Facing and texture rotation increase counterclockwise.
  local rotated = type(facing) == "number" and arrowFile ~= nil
    and type(arrowArt.SetRotation) == "function" and pcall(arrowArt.SetRotation, arrowArt, -arrowBearing - facing)
  arrowArt:SetShown(rotated)
  local compass = COMPASS[(math.floor(arrowBearing / (math.pi / 4) + 0.5) % 8) + 1]
  arrowText:SetText(rotated and arrowCaption or (compass .. (arrowCaption ~= "" and " - " .. arrowCaption or "")))
end

-- A saved position wins; without one the window sits beside Questie's tracker (built some
-- seconds after login, so the refresh and the ticker both check) or in its default spot. It
-- only re-anchors when the answer changes. On the tracker's right it keeps 58 px clear: the
-- item and target buttons hang up to 46 px off the window's left edge.
local placedBy, refused -- refused: a tracker the client wouldn't let us anchor to (not retried)
local PLACED = { saved = "saved position", left = "beside Questie's tracker", right = "beside Questie's tracker",
  default = "default spot" }

local function place()
  local p = ns.db().questPosition
  local tracker, side
  if not p then tracker, side = ns.questie.trackerSide() end
  if tracker and tracker == refused then tracker, side = nil, nil end
  local key = (p and "saved") or side or "default"
  if key == placedBy then return end
  -- A placed window stays put in combat: the secure buttons beside it can't follow until after.
  if placedBy and try(InCombatLockdown) then return end
  viewer:ClearAllPoints()
  local ok = true
  if p then viewer:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  elseif side == "left" then ok = pcall(viewer.SetPoint, viewer, "TOPRIGHT", tracker, "TOPLEFT", -12, -40)
  elseif side == "right" then ok = pcall(viewer.SetPoint, viewer, "TOPLEFT", tracker, "TOPRIGHT", 58, -40) end
  if not ok then refused, key = tracker, "default" end
  if key == "default" then
    viewer:ClearAllPoints()
    viewer:SetPoint("RIGHT", UIParent, "RIGHT", -48, 80)
  end
  placedBy = key
end

function ns.questViewerPlacement() return PLACED[placedBy or "default"] end

local function font(parent, y, width, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", 16, -y)
  fs:SetWidth(width)
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(true)
  return fs
end

function ns.moveQuestStep(back)
  if back then Q.back() else Q.next() end
  quiet = true
  ns.questRefresh()
end

-- The banner shows the guide's short name (the part before a colon; the Quests tab has the full
-- title). The dialog header art's plate is about 45% of the texture's width, so the art widens
-- with the name, Morpheus drops to 12 for long names, and anything longer still is cut off.
local HEADER_FONT, PLATE = "Fonts\\MORPHEUS.TTF", 0.45
local function fitHeader(text)
  header:SetText(Q.plain(text))
  try(header.SetFont, header, HEADER_FONT, 14, "")
  try(header.SetWidth, header, 0)
  local width = tonumber(try(header.GetStringWidth, header)) or 0
  if width > 150 then
    try(header.SetFont, header, HEADER_FONT, 12, "")
    width = tonumber(try(header.GetStringWidth, header)) or width
  end
  local fits = math.min(width, 190)
  try(header.SetWidth, header, fits + 4)
  if headerArt and headerArt:IsShown() then
    headerArt:SetWidth(math.max(300, (fits + 44) / PLATE))
  end
end

-- Window comfort: its size (Settings, the setup card, Ctrl+wheel over it; 50% to 150% for small
-- screens), the background's opacity, fading to 30% in combat (the mouse over it brings it back)
-- and compact mode (db.questCompact: the title row, the bar and the buttons).
local FADED, FADE_TIME = 0.3, 0.3
local inCombat, comfortPending = false, false

-- The arrow's room above the window (clamp inset) is 76 px on screen, so 76 / scale window units.
local function arrowRoom() return 76 / (tonumber(viewer and viewer:GetScale()) or 1) end

local function applyComfort()
  if not viewer then return end
  local db = ns.db()
  local scale = math.max(0.5, math.min(1.5, tonumber(db.questViewerScale) or 1))
  local old = tonumber(viewer:GetScale()) or 1
  if math.abs(scale - old) > 0.001 then
    -- In combat the secure item and target buttons beside the window can't move, so a new size
    -- waits for PLAYER_REGEN_ENABLED.
    if try(InCombatLockdown) then
      comfortPending = true
    else
      comfortPending = false
      -- a dragged window keeps its spot on screen: its offsets are in its own (scaled) units
      local p = db.questPosition
      if type(p) == "table" and tonumber(p[3]) and tonumber(p[4]) then
        p[3], p[4] = p[3] * old / scale, p[4] * old / scale
        placedBy = nil
      end
      viewer:SetScale(scale)
      if not placedBy then place() end
      if not db.questArrowPos then try(viewer.SetClampRectInsets, viewer, 0, 0, arrowRoom(), 0) end
      updateItemButton()
    end
  end
  local a = math.max(0.2, math.min(1, tonumber(db.questViewerAlpha) or 1))
  viewer.background:SetAlpha(a)
  if type(viewer.SetBackdropColor) == "function" then
    local r, g, b = ns.rgba(C.parch)
    pcall(viewer.SetBackdropColor, viewer, r, g, b, a)
    local er, eg, eb = ns.rgba(C.edge)
    pcall(viewer.SetBackdropBorderColor, viewer, er, eg, eb, a)
  end
end

local function nudge(key, step, low, high)
  local db = ns.db()
  if type(LevelingCodexDB) ~= "table" then return end
  db[key] = math.floor(math.max(low, math.min(high, (tonumber(db[key]) or 1) + step)) * 10 + 0.5) / 10
  applyComfort()
end
function ns.setQuestViewerScale(step) nudge("questViewerScale", step, 0.5, 1.5) end
function ns.setQuestViewerAlpha(step) nudge("questViewerAlpha", step, 0.2, 1) end

local function makeViewer()
  viewer = A.frame("Frame", "LevelingCodexQuestViewer", UIParent)
  viewer:SetSize(350, 182)
  viewer:SetFrameStrata("MEDIUM")
  viewer:SetMovable(true)
  viewer:SetClampedToScreen(true)
  -- Keep the arrow (70 px tall, 6 px above the window) on screen too, e.g. beside a tracker at the top.
  try(viewer.SetClampRectInsets, viewer, 0, 0, 76, 0)
  viewer:EnableMouse(true)
  viewer:RegisterForDrag("LeftButton")
  viewer:SetScript("OnDragStart", function(self)
    if not ns.db().questLocked then self:StartMoving() end
  end)
  viewer:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relative, x, y = self:GetPoint()
    if point then ns.db().questPosition = { point, relative, x, y } end
    placedBy = nil -- the next refresh anchors the saved spot to UIParent
    updateItemButton()
  end)
  viewer:HookScript("OnHide", function()
    if not painting then dismissed = true end
    if arrow then arrow:Hide() end
  end)
  viewer:Hide()
  place()
  flatBackground = viewer:CreateTexture(nil, "BACKGROUND")
  flatBackground:SetAllPoints()
  viewer.background = flatBackground
  -- In combat the window fades to 30% unless the mouse is over it; Ctrl held over it lets the wheel
  -- resize it (otherwise the wheel stays the camera's).
  try(viewer.EnableMouseWheel, viewer, false)
  viewer:HookScript("OnEnter", function(self) self.hoverFlag = true end)
  viewer:HookScript("OnLeave", function(self) self.hoverFlag = false end)
  viewer:SetScript("OnMouseWheel", function(_, delta)
    if not try(IsControlKeyDown) then return end
    ns.setQuestViewerScale((tonumber(delta) or 0) > 0 and 0.1 or -0.1)
  end)
  viewer:HookScript("OnUpdate", function(self, elapsed)
    local hovered = self.hoverFlag or (type(self.IsMouseOver) == "function" and self:IsMouseOver() == true)
    local goal = (inCombat and not ns.db().noQuestFade and not hovered) and FADED or 1
    local a = tonumber(self:GetAlpha()) or 1
    if a ~= goal then
      local move = (tonumber(elapsed) or 0) / FADE_TIME * (1 - FADED)
      self:SetAlpha(a < goal and math.min(goal, a + move) or math.max(goal, a - move))
    end
    local wheel = hovered and try(IsControlKeyDown) and true or false
    if wheel ~= self.wheelOn then
      self.wheelOn = wheel
      try(self.EnableMouseWheel, self, wheel)
    end
  end)
  -- Compact mode's switch in the top-right corner.
  viewer.compactButton = A.iconButton(viewer, A.FILES.minusUp, "-")
  viewer.compactButton:SetSize(16, 16)
  if viewer.compactButton.icon then viewer.compactButton.icon:SetSize(16, 16) end
  viewer.compactButton:SetPoint("TOPRIGHT", -7, -7)
  viewer.compactButton:SetScript("OnClick", function()
    if type(LevelingCodexDB) ~= "table" then return end
    LevelingCodexDB.questCompact = not LevelingCodexDB.questCompact
    ns.questRefresh()
  end)
  headerArt, header = A.header(viewer, "Quest Guide", 300)
  try(header.SetWordWrap, header, false)
  levels = viewer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  levels:SetPoint("TOPRIGHT", -16, -30)
  title = font(viewer, 28, 318, "GameFontNormal")
  -- The step's icon before its title (QuestMap.lua's icons).
  viewer.titleIcon = viewer:CreateTexture(nil, "OVERLAY")
  viewer.titleIcon:SetSize(16, 16)
  viewer.titleIcon:SetPoint("TOPLEFT", 16, -27)
  viewer.titleIcon:Hide()
  -- The step's kind (QuestMap.lua): a stripe down the left edge and a chip before the title.
  viewer.stripe = viewer:CreateTexture(nil, "ARTWORK")
  viewer.stripe:SetPoint("TOPLEFT", 5, -5)
  viewer.stripe:SetPoint("BOTTOMLEFT", 5, 5)
  viewer.stripe:SetWidth(3)
  viewer.chip = CreateFrame("Frame", nil, viewer)
  viewer.chip:SetSize(40, 14)
  viewer.chip.plate = viewer.chip:CreateTexture(nil, "ARTWORK")
  viewer.chip.plate:SetAllPoints()
  viewer.chip.text = viewer.chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  viewer.chip.text:SetPoint("CENTER", 0, 0)
  viewer.chip:Hide()
  -- The step's NPC (QuestPortrait.lua), left of the title for pickups, turn-ins and kills.
  viewer.portrait = ns.makeQuestPortrait(viewer)
  viewer.portrait:SetPoint("TOPLEFT", 12, -26)
  -- A turn-in's XP under the title: a purple chip "+N XP", then "levels you up" when it would.
  viewer.xp = CreateFrame("Frame", nil, viewer)
  viewer.xp:SetSize(60, 14)
  viewer.xp.plate = viewer.xp:CreateTexture(nil, "ARTWORK")
  viewer.xp.plate:SetAllPoints()
  viewer.xp.plate:SetColorTexture(0.23, 0.16, 0.37, 0.9)
  viewer.xp.text = viewer.xp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  viewer.xp.text:SetPoint("CENTER", 0, 0)
  viewer.xp.text:SetTextColor(0.84, 0.78, 1)
  viewer.xp.note = viewer.xp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  viewer.xp.note:SetPoint("LEFT", viewer.xp, "RIGHT", 6, 0)
  viewer.xp.note:SetTextColor(0.84, 0.78, 1)
  viewer.xp:Hide()
  -- A step the game finishes: the window's edge glows once (gold lines inside the border, fading).
  local glow = CreateFrame("Frame", nil, viewer)
  glow:SetAllPoints()
  glow:SetAlpha(0)
  local function edge(a, b, w, h)
    local t = glow:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(1, 0.82, 0.25, 0.9)
    try(t.SetBlendMode, t, "ADD")
    t:SetPoint(a, 4 * (a:find("LEFT") and 1 or -1), 4 * (a:find("TOP") and -1 or 1))
    t:SetPoint(b, 4 * (b:find("LEFT") and 1 or -1), 4 * (b:find("TOP") and -1 or 1))
    if w then t:SetWidth(w) else t:SetHeight(h) end
  end
  edge("TOPLEFT", "TOPRIGHT", nil, 2)
  edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
  edge("TOPLEFT", "BOTTOMLEFT", 2, nil)
  edge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
  if type(glow.CreateAnimationGroup) == "function" then
    viewer.glowAnim = glow:CreateAnimationGroup()
    local fade = viewer.glowAnim:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(0.4)
  end

  -- The button row: a wide Next step in the theme's colour between small icon buttons (Back, Quests,
  -- Hide) that name themselves on hover; the offer button above is a primary button too.
  local function icon(label, x, file, fallback, action)
    local b = A.iconButton(viewer, file, fallback)
    b:SetPoint("BOTTOMLEFT", x, 9)
    b.codexLabel, b.tipTitle = label, label
    b:SetScript("OnClick", action)
    return b
  end
  local function primary(label, x, width, action, bottom)
    local b = A.primaryButton(viewer)
    b:SetSize(width, 24)
    b:SetPoint("BOTTOMLEFT", x, bottom or 9)
    b:SetLabel(label)
    b.codexLabel = label
    b:SetScript("OnClick", action)
    return b
  end
  -- Keep controller focus in the Quests tab so the overlay can stay up during gameplay.
  viewer.buttons = {
    icon("Back", 12, A.FILES.prevUp, "<", function() ns.moveQuestStep(true) end),
    icon("Quests", 270, A.FILES.questBook, "Q", function() ns.openQuestStep() end),
    icon("Hide", 302, A.FILES.closeUp, "x", ns.hideQuestViewer), -- the close art: minus is compact's
  }
  nextButton = primary("Next", 44, 222, function(_, mouse)
    ns.moveQuestStep(mouse == "RightButton")
  end)
  nextButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  nextButton:SetLabel("Next step", true)
  suggestionButton = primary("", 16, 318, function()
    local row = Q.current()
    if row and row.step.type == "plan" then
      ns.planQuestRun(row.step.dungeon, true)
    elseif row and row.section.side then
      Q.returnToRoute()
      quiet = true
      ns.questRefresh()
    else
      local run = Q.readyRun()
      local suggestion = not run and Q.suggestions()[1]
      local related = not run and not suggestion and Q.relatedGuide()
      if run then
        Q.jump(run)
        quiet = true
        ns.questRefresh()
      elseif related then ns.openQuestGuide(related)
      elseif suggestion then ns.followSuggestedQuestSection(suggestion)
      elseif ns.questSetupDue() then ns.openQuestSetup() end
    end
  end, 35)

  -- The completion bar under the step's title: a thin track, the fill in the theme's accent and the
  -- percent at its end. A new value slides in over 0.5 s (ease-out); hover for the counts, click
  -- for the route.
  bar = CreateFrame("Button", "LevelingCodexQuestBar", viewer)
  bar:SetSize(318, 10)
  bar.edge = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
  bar.edge:SetPoint("LEFT", 0, 0)
  bar.edge:SetSize(BAR_TRACK + 2, 8)
  bar.track = bar:CreateTexture(nil, "BACKGROUND")
  bar.track:SetPoint("LEFT", 1, 0)
  bar.track:SetSize(BAR_TRACK, 6)
  bar.track:SetColorTexture(0, 0, 0, 0.6)
  bar.fill = bar:CreateTexture(nil, "ARTWORK")
  bar.fill:SetPoint("LEFT", bar.track, "LEFT", 0, 0)
  bar.fill:SetSize(0.01, 6)
  bar.fillArt = A.hasFile(BAR_TEXTURE)
  if bar.fillArt then bar.fill:SetTexture(BAR_TEXTURE) end
  bar.pct = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bar.pct:SetPoint("RIGHT", 0, 0)
  bar.pct:SetJustifyH("RIGHT")
  bar:SetScript("OnClick", function() ns.openQuestRoute() end)
  bar:SetScript("OnEnter", function(self)
    local row = Q.current()
    if not (GameTooltip and row) then return end
    local passed, total = Q.stepProgress(row.section)
    local done, quests = Q.turninProgress(row.section)
    local pct = total > 0 and math.floor(passed * 100 / total) or 0
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(Q.plain(row.section.title .. ": " .. passed .. " of " .. total .. " steps done (" .. pct .. "%)"))
    GameTooltip:AddLine(done .. " of " .. quests .. " quests turned in", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Click to see the route.", 1, 1, 1)
    GameTooltip:Show()
  end)
  bar:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  bar:Hide()

  -- No box: a rotating arrow over the world with the distance under it, like the game's own pointers.
  -- It has its own spot once dragged (db.questArrowPos); until then it sits above the step window.
  -- Only the 48 px arrow takes the mouse, so the camera still turns around it, and it takes the
  -- wheel only while Ctrl is held over it (to resize it): otherwise the wheel zooms the camera.
  arrow = CreateFrame("Frame", "LevelingCodexQuestArrow", UIParent)
  arrow:SetSize(48, 48)
  arrow:SetFrameStrata("MEDIUM")
  arrow:SetMovable(true)
  arrow:SetClampedToScreen(true)
  arrow:EnableMouse(true)
  arrow:RegisterForDrag("LeftButton")
  try(arrow.EnableMouseWheel, arrow, false)
  arrow:Hide()
  arrowArt = arrow:CreateTexture(nil, "ARTWORK")
  arrowArt:SetAllPoints()
  if A.hasFile(ARROW_TEXTURE) then arrowFile = ARROW_TEXTURE; arrowArt:SetTexture(arrowFile) end
  arrowText = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  arrowText:SetPoint("TOP", arrow, "BOTTOM", 0, -2)
  arrowText:SetWidth(320)
  arrowText:SetJustifyH("CENTER")
  arrowText:SetWordWrap(true)
  try(arrowText.SetShadowColor, arrowText, 0, 0, 0, 1)
  try(arrowText.SetShadowOffset, arrowText, 1, -1)
  -- Arrival: the step's icon bobs over a gold ring that pulses once (Settings > Animate the arrow).
  arrow.here = arrow:CreateTexture(nil, "ARTWORK")
  arrow.here:SetSize(36, 36)
  arrow.here:SetPoint("CENTER")
  arrow.here:Hide()
  arrow.ring = arrow:CreateTexture(nil, "BACKGROUND")
  arrow.ring:SetSize(72, 72)
  arrow.ring:SetPoint("CENTER")
  arrow.ring:Hide()
  ringArt = A.hasFile(RING_TEXTURE)
  if ringArt then
    arrow.ring:SetTexture(RING_TEXTURE)
    try(arrow.ring.SetBlendMode, arrow.ring, "ADD")
    arrow.ring:SetVertexColor(1, 0.82, 0.25)
  end
  if type(arrow.here.CreateAnimationGroup) == "function" then
    arrow.bob = arrow.here:CreateAnimationGroup()
    local up = arrow.bob:CreateAnimation("Translation")
    up:SetOffset(0, 8)
    up:SetDuration(0.4)
    try(up.SetSmoothing, up, "IN_OUT")
    arrow.bob:SetLooping("BOUNCE")
    arrow.pulse = arrow.ring:CreateAnimationGroup()
    local grow = arrow.pulse:CreateAnimation("Scale")
    if type(grow.SetScaleFrom) == "function" then
      try(grow.SetScaleFrom, grow, 0.6, 0.6)
      try(grow.SetScaleTo, grow, 1.4, 1.4)
    else
      try(grow.SetScale, grow, 1.4, 1.4)
    end
    grow:SetDuration(0.6)
    local fade = arrow.pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(0.6)
    arrow.pulse:SetScript("OnFinished", function() arrow.ring:Hide() end)
  end
  -- The wheel is the arrow's only while Ctrl is held over it.
  local wheel = false
  arrow:SetScript("OnUpdate", function()
    local want = arrow.hovered and try(IsControlKeyDown) and true or false
    if want ~= wheel then
      wheel = want
      try(arrow.EnableMouseWheel, arrow, want)
    end
    turnArrow()
  end)
  arrow:SetScript("OnDragStart", function(self)
    if not ns.db().questArrowLocked then self:StartMoving() end
  end)
  arrow:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not ns.db().questArrowLocked then ns.saveQuestArrowSpot() end
    ns.placeQuestArrow()
  end)
  arrow:SetScript("OnMouseWheel", function(_, delta)
    if not try(IsControlKeyDown) then return end
    local db = ns.db()
    -- a moved arrow grows and shrinks around its centre: keep that spot in screen units first
    if type(db.questArrowPos) == "table" then ns.saveQuestArrowSpot() end
    local scale = (tonumber(db.questArrowScale) or 1) + ((tonumber(delta) or 0) > 0 and 0.1 or -0.1)
    db.questArrowScale = math.floor(math.max(0.6, math.min(2, scale)) * 10 + 0.5) / 10
    ns.placeQuestArrow()
  end)
  arrow:SetScript("OnEnter", function(self)
    self.hovered = true
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Quest arrow")
    GameTooltip:AddLine("Drag to move it. Ctrl+mouse wheel changes its size.", 1, 1, 1)
    GameTooltip:Show()
  end)
  arrow:SetScript("OnLeave", function(self)
    self.hovered = false
    wheel = false
    try(self.EnableMouseWheel, self, false)
    if GameTooltip then GameTooltip:Hide() end
  end)
  ns.placeQuestArrow()
end

-- Save where the arrow's centre is, in UIParent units (its own units times its scale), so a later
-- size change keeps that centre: { "CENTER", "BOTTOMLEFT", x, y, true }. An older save without the
-- fifth field holds the anchor and offsets as dragged, in the arrow's own units.
function ns.saveQuestArrowSpot()
  if not arrow then return end
  local x, y = arrow:GetCenter()
  local scale = tonumber(arrow:GetScale()) or 1
  if type(x) == "number" and type(y) == "number" then ns.db().questArrowPos = { "CENTER", "BOTTOMLEFT", x * scale, y * scale, true } end
end

-- The arrow's spot: the saved one (and then the step window no longer keeps room above itself for
-- it), else above the step window; its size from db.questArrowScale (60-200%).
function ns.placeQuestArrow()
  if not arrow then return end
  local db = ns.db()
  local p = db.questArrowPos
  local scale = math.max(0.6, math.min(2, tonumber(db.questArrowScale) or 1))
  arrow:ClearAllPoints()
  arrow:SetScale(scale)
  if type(p) == "table" and type(p[1]) == "string" then
    local x, y = tonumber(p[3]) or 0, tonumber(p[4]) or 0
    if p[5] then x, y = x / scale, y / scale end
    arrow:SetPoint(p[1], UIParent, type(p[2]) == "string" and p[2] or p[1], x, y)
    try(viewer.SetClampRectInsets, viewer, 0, 0, 0, 0)
  else
    arrow:SetPoint("BOTTOM", viewer, "TOP", 0, 28)
    try(viewer.SetClampRectInsets, viewer, 0, 0, arrowRoom(), 0)
  end
end

-- The flight timer: where you're flying (the node TakeTaxiNode took), how long you've flown and,
-- once a flight between the same two points has been timed, about how long is left.
local flight = {}
local function clock(seconds)
  seconds = math.max(0, math.floor(seconds + 0.5))
  return math.floor(seconds / 60) .. ":" .. string.format("%02d", seconds % 60)
end

local function flightTimes()
  local db = ns.db()
  if type(db.flightTimes) ~= "table" then db.flightTimes = {} end
  return db.flightTimes
end

local function flightText()
  local now = GetTime()
  flight.start = flight.start or now
  local elapsed = now - flight.start
  local text = "In flight" .. (flight.to and (" to " .. flight.to:match("^[^,]+")) or "") .. " - " .. clock(elapsed)
  local known = flight.from and flight.to and flightTimes()[flight.from .. ">" .. flight.to]
  if type(known) == "number" and known > elapsed then text = text .. "\nabout " .. clock(known - elapsed) .. " left" end
  return text
end

-- The timed length of the flight just taken, when one between the same two points was timed.
function ns.questFlightEstimate()
  local known = flight.from and flight.to and flightTimes()[flight.from .. ">" .. flight.to]
  return type(known) == "number" and known or nil
end

-- Every tick: a landing stores the flight's time.
local function tickFlight()
  if Q.inFlight() then
    flight.start = flight.start or GetTime()
  elseif flight.start then
    if flight.from and flight.to then flightTimes()[flight.from .. ">" .. flight.to] = GetTime() - flight.start end
    if ns.stats then ns.stats.flightTime(GetTime() - flight.start) end
    flight = {}
  end
end

-- Arrival time: your speed over the last moments gives "120 yd - 0:24" while you move toward the spot.
local pace = {}
local function eta(yards)
  local map, x, y = Q.position()
  local now = GetTime()
  if pace.at and now - pace.at >= 0.2 then
    local moved = pace.map == map and select(2, Q.vector({ map = map, x = pace.x, y = pace.y }, map, x, y))
    local speed = moved and moved / (now - pace.at)
    if speed then pace.speed = pace.speed and (pace.speed * 0.6 + speed * 0.4) or speed end
    pace.at = nil
  end
  if not pace.at then pace.map, pace.x, pace.y, pace.at = map, x, y, now end
  if yards and pace.speed and pace.speed > 2 then return " - " .. clock(yards / pace.speed) end
  return ""
end

-- Arrival: the arrow becomes the step's icon (a gold dot when the client lacks its file), bobbing,
-- and the ring pulses once. `key` tells a new arrival (another step or path point) from the same one.
local arrivedKey
local function arrive(key, step, caption)
  arrowText:SetText(caption)
  arrowBearing = nil
  arrowArt:Hide()
  if arrivedKey == key then return end
  arrivedKey = key
  local icon = ns.questIcon(step)
  if icon then
    arrow.here:SetTexture(icon)
    arrow.here:SetSize(36, 36)
  else
    arrow.here:SetColorTexture(1, 0.82, 0, 1)
    arrow.here:SetSize(12, 12)
  end
  arrow.here:Show()
  if arrow.pulse and ringArt then
    arrow.pulse:Stop()
    arrow.ring:SetAlpha(1)
    arrow.ring:Show()
    arrow.pulse:Play()
  end
  if arrow.bob then
    if ns.db().noArrowBounce then arrow.bob:Stop() else arrow.bob:Play() end
  end
end

local function leave()
  if not arrivedKey then return end
  arrivedKey = nil
  arrow.here:Hide()
  arrow.ring:Hide()
  if arrow.bob then arrow.bob:Stop() end
  if arrow.pulse then arrow.pulse:Stop() end
end

local CORPSE = { type = "spot" }

-- As a ghost the arrow leads back to your corpse instead of the step.
local function paintCorpse(corpse)
  arrow:Show()
  arrowArt:Hide()
  local map, x, y = Q.position()
  local bearing, yards = Q.vector(corpse, map, x, y)
  if yards and yards <= Q.arrived() then
    arrive("corpse", CORPSE, "Your corpse is here")
    return
  end
  leave()
  if bearing then
    arrowBearing, arrowCaption, arrowFacing = bearing, "Your corpse - " .. math.floor(yards + 0.5) .. " yd", false
    turnArrow()
  else
    arrowText:SetText("Return to your corpse")
  end
end

-- What the arrow leads to, for the minimap (QuestMap.lua): { spot, step, kind = "step" / "spawn" /
-- "leg" / "corpse", caption, key }, or nil (no step, in flight, the window hidden). Kept up to date
-- with the arrow turned off too.
local arrowGoal
function ns.questArrowGoal() return arrowGoal end

local function paintArrow()
  arrowGoal = nil
  if not viewer or not viewer:IsShown() then
    if arrow then arrow:Hide() end
    return
  end
  local row = Q.current()
  local goal = row and row.step
  arrowBearing = nil
  local off = ns.db().noQuestArrow
  local corpse = Q.corpse()
  if corpse then
    arrowGoal = { spot = corpse, step = CORPSE, kind = "corpse", caption = "Your corpse", key = "corpse" }
    if off then
      leave()
      arrow:Hide()
    else
      paintCorpse(corpse)
    end
    return
  end
  if not goal then
    leave()
    arrow:Hide()
    return
  end
  if Q.inFlight() then
    leave()
    if off then arrow:Hide(); return end
    arrow:Show()
    arrowArt:Hide()
    arrowText:SetText(flightText())
    return
  end
  if not goal.map or not (goal.x or goal.points) then
    leave()
    arrow:Hide()
    return
  end
  local map, x, y = Q.position()
  local spot, point, count, kind = Q.waypoint(goal)
  local step, travel = Q.destination(spot, map)
  -- QuestieDB's nearest spawn leads the last mile of a kill or collect step (QuestieSupport.lua).
  local spawn, spawnName
  if step == goal then spawn, spawnName = ns.questie.nearest(goal, map, x, y) end
  local key = row.key .. ":" .. tostring(point or "")
  if spawn or step then
    arrowGoal = { spot = spawn or step, step = goal, kind = spawn and "spawn" or travel and "leg" or "step",
      caption = spawnName or travel, key = spawn and (key .. ":" .. spawnName) or key }
  end
  if off then
    leave()
    arrow:Hide()
    return
  end
  arrow:Show()
  local bearing, yards = Q.vector(spawn or step, map, x, y)
  -- A flight master or flight path on the way can be across a zone border.
  if not bearing and not spawn and step and (step.leg or step.world or Q.continentMap(map)) then
    bearing, yards = Q.worldVector(step, map, x, y)
  end
  local which = point and not travel and (" (" .. kind .. " " .. point .. " of " .. count .. ")") or ""
  arrowArt:Hide()
  if spawn and yards and yards <= Q.arrived() then
    arrive(key .. ":" .. spawnName, goal, spawnName .. " nearby")
    return
  elseif yards and yards <= Q.arrived() and not travel then
    local npc = which == "" and type(goal.npc) == "string" and Q.plain(goal.npc) or nil
    arrive(key, goal, (npc and (npc .. "\n") or "") .. "Arrived" .. which)
    return
  end
  leave()
  if spawn and bearing then
    arrowBearing, arrowCaption, arrowFacing = bearing, spawnName .. " - " .. math.floor(yards + 0.5) .. " yd", false
    turnArrow()
  elseif yards and yards <= Q.arrived() then
    arrowText:SetText(travel)
  elseif bearing then
    arrowBearing, arrowFacing = bearing, false
    local distance = yards and (math.floor(yards + 0.5) .. " yd" .. eta(yards)) or ""
    if travel and step.leg then
      arrowCaption = travel .. "\n" .. distance
    else
      arrowCaption = travel or (distance .. which)
    end
    turnArrow()
  else
    arrowText:SetText(travel or (x and "Map scale unavailable" or "Position unavailable"))
  end
end

local ACTION = { accept = "Accept", complete = "Complete", turnin = "Turn in", ["goto"] = "Travel",
  fly = "Fly", getfp = "Flight path", sethearth = "Bind hearthstone", hearth = "Hearth",
  boat = "Boat", train = "Train", buy = "Buy", use = "Use", grind = "Level up", dungeon = "Dungeon", note = "Note",
  abandon = "Abandon", collect = "Collect", plan = "Dungeon ahead", boss = "Boss" }

function Q.label(step)
  if step.type == "hearth" and step.bind then return "Return to " .. step.bind end
  local verb = ACTION[step.type]
  local name = step.name or step.flight
  return name and (verb .. " - " .. name) or verb
end

-- One objective as a checklist row: the goal, its count and whether it's done. The log says
-- "2/10 Mottled Raptor slain" (Forever), "Mottled Raptor slain: 2/10" (classic) or has no count.
-- `flat` keeps the log's own words for Q.detail (the Quests tab and tooltips).
local function goalBlock(obj, small, indent)
  local text = type(obj) == "table" and obj.text or obj
  if type(text) ~= "string" then return end
  local raw = Q.plain(text)
  local have, need, name = raw:match("^(%d+)%s*/%s*(%d+)%s+(.+)$")
  if not have then name, have, need = raw:match("^(.-):?%s+(%d+)%s*/%s*(%d+)%.?$") end
  local done = type(obj) == "table" and (obj.finished == true or obj.finished == 1) or false
  have, need = tonumber(have), tonumber(need)
  if have and need and have >= need then done = true end
  return { kind = "goal", text = (name and name ~= "") and name or raw, count = have and (have .. "/" .. need),
    started = (have or 0) > 0, done = done, small = small, indent = indent, flat = raw }
end

-- A quest's objectives from the log (all, or the unfinished ones; `index` = just that one), else
-- the step's own `objectives`. Returns how many it added.
local function addGoals(out, entry, index, fallback, incompleteOnly, small, indent)
  local n = 0
  for i, obj in ipairs(entry and entry.objectives or {}) do
    if (not index or i == index) and type(obj.text) == "string" and
        (not incompleteOnly or (obj.finished ~= true and obj.finished ~= 1)) then
      local b = goalBlock(obj, small, indent)
      if b then out[#out + 1] = b; n = n + 1 end
    end
  end
  if n > 0 then return n end
  for _, text in ipairs(fallback or {}) do
    local b = goalBlock(text, small, indent)
    if b then out[#out + 1] = b; n = n + 1 end
  end
  return n
end

-- XP for grind steps: the last five kills (CHAT_MSG_COMBAT_XP_GAIN) estimate the kills left.
local killXP = {}

local function noteKill(msg)
  if type(msg) ~= "string" or not msg:find("dies", 1, true) then return end
  local digits = msg:match("(%d[%d,%.]*) experience")
  local n = digits and tonumber((digits:gsub("[,%.]", "")))
  if not n or n <= 0 then return end
  killXP[#killXP + 1] = n
  if #killXP > 5 then table.remove(killXP, 1) end
end

-- XP waiting in finished quests in your log (GetQuestLogRewardXP by quest ID).
local function readyQuestXP()
  local total = 0
  for id, entry in pairs(Q.logEntries()) do
    if entry.ready then total = total + (tonumber(try(GetQuestLogRewardXP, id)) or 0) end
  end
  return total
end

local function grindLines(step, level)
  local cur, max, rested = Q.xp()
  if not cur then return {} end
  local lines = { "XP " .. cur .. " / " .. max .. " (" .. math.floor(cur * 100 / max) .. "%)" }
  local need, goal
  if step.xp and step.level == level then
    need, goal = math.ceil(step.xp * max) - cur, math.floor(step.xp * 100 + 0.5) .. "% of level " .. level
  else
    need, goal = max - cur, "level " .. (level + 1)
  end
  if need > 0 then
    local kills = ""
    if #killXP > 0 then
      local sum = 0
      for _, n in ipairs(killXP) do sum = sum + n end
      kills = ", about " .. math.ceil(need * #killXP / sum) .. " kills"
    end
    lines[#lines + 1] = need .. " XP to " .. goal .. kills
  end
  if rested > 0 then lines[#lines + 1] = "Rested: " .. rested .. " XP" end
  local waiting = readyQuestXP()
  if waiting > 0 then lines[#lines + 1] = "Ready turn-ins: about " .. waiting .. " XP" end
  return lines
end

-- Collect and buy steps: what your bags hold of what the step wants (with `items`, the first one
-- still short).
local function itemCounts(step)
  if not (step.type == "collect" or step.type == "buy") then return end
  if step.item then
    local have, need = Q.itemCount(step.item), step.count or 1
    if have < need or not step.items then return have, need end
  end
  local last
  for _, pair in ipairs(type(step.items) == "table" and step.items or {}) do
    local have, need = Q.itemCount(pair[1]), pair[2] or 1
    if have < need then return have, need end
    last = { have, need }
  end
  if last then return last[1], last[2] end
end

local function itemGoal(text, have, need, small, flat)
  return { kind = "goal", text = text, count = have .. "/" .. need, started = have > 0, done = have >= need,
    small = small, flat = flat }
end

-- Sticky goals the route has passed: each with its progress, under ON THE WAY.
local function addStickies(out)
  local list = Q.stickies()
  if #list == 0 then return end
  out[#out + 1] = { kind = "heading", text = "On the way" }
  for _, row in ipairs(list) do
    local step = row.step
    local have, need = itemCounts(step)
    if have then
      out[#out + 1] = itemGoal(Q.label(step), have, need, true,
        Q.label(step) .. ": You have " .. have .. "/" .. need .. ".")
    else
      out[#out + 1] = { kind = "quest", text = Q.label(step) }
      if step.type == "complete" then
        addGoals(out, Q.log(step.quest), step.objectiveIndex, step.objectives, true, true, 12)
      end
    end
  end
end

-- Elites and rares near the current step (QuestDangerData.lua; Settings > Warn about elites and
-- rares): hostile to you, within 90 yd of the step's spot, and not outleveled (elites, rare elites
-- and bosses until 3 levels past their top level, rares until 1).
local DANGER_YARDS = 90
local KIND_LABEL = { elite = "Elite", rareelite = "Rare elite", boss = "Boss", rare = "Rare" }

local function dangerText(step)
  if ns.db().noDangerWarnings or type(ns.questDanger) ~= "table" then return end
  local spot = Q.waypoint(step)
  local list = spot and spot.map and spot.x and ns.questDanger[spot.map]
  if not list then return end
  local _, _, _, level = Q.rows()
  local faction = tostring(try(UnitFactionGroup, "player") or ""):sub(1, 1)
  local found = {}
  for _, d in ipairs(list) do
    local name, low, high, kind, friendly = d[1], d[2], d[3], d[4], d[5] or ""
    local mine = faction ~= "" and friendly:find(faction, 1, true)
    if not mine and level <= high + (kind == "rare" and 1 or 3) then
      for k = 1, #d.spots - 1, 2 do
        local _, yards = Q.vector({ map = spot.map, x = d.spots[k], y = d.spots[k + 1] }, spot.map, spot.x, spot.y)
        if yards and yards <= DANGER_YARDS then
          found[#found + 1] = (KIND_LABEL[kind] or "Elite") .. " " .. name .. " ("
            .. (low == high and low or (low .. "-" .. high)) .. ")"
          break
        end
      end
    end
  end
  if #found == 0 then return end
  local more = #found > 3 and (" and " .. (#found - 3) .. " more") or ""
  while #found > 3 do table.remove(found) end
  return "Watch out here: " .. table.concat(found, ", ") .. more .. "."
end

-- The step's detail as pieces, top to bottom. Kinds: note (`tone` warn/gold/dim), text (the step's
-- instruction), goal (`text`, `count` "2/10", `done`, `small`, `indent`), heading, quest (a quest's
-- name above its goals), info, danger and chain (the step window shows it under the title).
-- withStickies: the current step, which also lists the sticky goals still open and nearby elites.
function Q.detailBlocks(step, requiredFor, withStickies)
  local out = {}
  local function add(block) out[#out + 1] = block end
  if step.type == "plan" then add({ kind = "text", text = Q.planText(step) }); return out end
  local _, _, _, level = Q.rows()
  if requiredFor then add({ kind = "note", tone = "warn", text = "Required for " .. requiredFor.name .. "." }) end
  if step.type == "accept" and not Q.log(step.quest) then
    local count, max = Q.logCapacity()
    if max and count >= max then
      add({ kind = "note", tone = "warn", text = "Your quest log is full (" .. count .. "/" .. max .. ")."
        .. " Turn in or abandon a quest first: Quests > Quest log lists ones you can drop." })
    end
  end
  if step.min and level < step.min then add({ kind = "note", tone = "warn", text = "Requires level " .. step.min .. "." }) end
  add({ kind = "text", text = Q.text(step) })
  if step.type == "complete" then addGoals(out, Q.log(step.quest), step.objectiveIndex, step.objectives) end
  local have, need = itemCounts(step)
  if have then add(itemGoal("In your bags", have, need, false, "You have " .. have .. "/" .. need .. ".")) end
  if step.type == "grind" and step.level then
    for _, line in ipairs(grindLines(step, level)) do add({ kind = "info", text = line }) end
  end
  local danger = withStickies and dangerText(step)
  if danger then add({ kind = "danger", text = danger }) end
  local alsoShown
  for _, id in ipairs(step.also or {}) do
    local entry = Q.incomplete(id)
    if entry and entry.title then
      if not alsoShown then add({ kind = "heading", text = "Also on this loop" }); alsoShown = true end
      add({ kind = "quest", text = entry.title })
      addGoals(out, entry, nil, nil, true, true, 12)
    end
  end
  if withStickies then addStickies(out) end
  local part, length, run = Q.chainInfo(step.quest)
  if part then
    add({ kind = "chain", text = "Chain: part " .. part .. " of " .. length .. (run and (", leads to " .. run.title) or "") .. "." })
  end
  -- step.uncertain (a verification note) stays in the data for us; players never see it.
  return out
end

-- The same as plain lines, for the Quests tab's step card and route tooltips.
function Q.detail(step, requiredFor, withStickies)
  local lines = {}
  for _, b in ipairs(Q.detailBlocks(step, requiredFor, withStickies)) do lines[#lines + 1] = b.flat or b.text end
  return Q.plain(table.concat(lines, "\n"))
end

-- A step the game finished (not Next/Back or a jump) plays the map ping, like a quest objective,
-- on the Master channel so a low effects volume doesn't hide it. Counted for /codex debug.
local sounds = { n = 0 }
local function completionSound(row)
  local done = lastRow and row ~= lastRow and not quiet and lastRow.state == "done"
  local finished = lastRow
  lastRow, quiet = row, false
  if done and viewer and viewer.glowAnim then
    viewer.glowAnim:Stop()
    viewer.glowAnim:Play()
  end
  if done and not ns.db().questNoSound and type(PlaySound) == "function" then
    sounds.n, sounds.last = sounds.n + 1, Q.plain(Q.label(finished.step))
    pcall(PlaySound, SOUNDKIT and SOUNDKIT.MAP_PING or 3175, "Master")
  end
end

-- The use-item button: a secure button beside the step window that uses the current
-- step's quest item (the quest log's own usable item, else the step's `item`, an ID or
-- a name). Secure frames can't change in combat, so changes wait for PLAYER_REGEN_ENABLED.
-- A hearth step offers the Hearthstone, but only when it is set to the step's town.
local HEARTHSTONE = 6948
local function stepItem(step)
  if not step then return end
  if step.type == "boss" then
    for _, row in ipairs(Q.stickies()) do
      local id, icon = stepItem(row.step)
      if id then return id, icon end
    end
    return
  end
  if step.type == "hearth" then
    if not step.bind or Q.boundTo(step.bind) then return HEARTHSTONE end
    return
  end
  local entry = step.quest and Q.log(step.quest)
  if entry and entry.index then
    local link, icon = try(GetQuestLogSpecialItemInfo, entry.index)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if id then return id, icon end
  end
  return step.item
end

local itemCount = Q.itemCount

local function itemTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  local shown = type(self.item) == "number" and try(GameTooltip.SetItemByID, GameTooltip, self.item)
  if not shown then GameTooltip:SetText(Q.plain(tostring(self.item or "Quest item"))) end
  GameTooltip:AddLine("Click to use it. Key Bindings > AddOns can give it a key.")
  GameTooltip:Show()
end

local function makeItemButton()
  local ok, b = pcall(CreateFrame, "Button", "LevelingCodexQuestItem", UIParent, "SecureActionButtonTemplate")
  if not ok or not b then itemButton = false; return end
  itemButton = b
  b:SetSize(40, 40)
  b:SetFrameStrata("MEDIUM")
  b:RegisterForClicks("AnyUp", "AnyDown") -- Forever follows retail's key-down setting
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetSize(66, 66)
  border:SetPoint("CENTER", 0, -1)
  if A.hasFile("Interface\\Buttons\\UI-Quickslot2") then border:SetTexture("Interface\\Buttons\\UI-Quickslot2") end
  if A.hasFile("Interface\\Buttons\\ButtonHilight-Square") then
    try(b.SetHighlightTexture, b, "Interface\\Buttons\\ButtonHilight-Square", "ADD")
  end
  b.count = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.count:SetPoint("BOTTOMRIGHT", -3, 3)
  b:SetScript("OnEnter", itemTooltip)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:Hide()
end

-- The target button: a secure macro button under the item button that targets the current
-- step's quest giver, or on an objective step the creatures it needs (QuestMobData.lua, or the
-- step's own `mobs`). Same combat rules as the item button.
local targetButton -- false = the client can't make one
local TARGET_TYPES = { accept = true, turnin = true, buy = true }
local MACRO_LIMIT = 255

local function targetName(value)
  local name = type(value) == "string" and Q.plain(value)
  if name and name:find("%a") and not name:find("[\n/;]") then return name end
end

local function stepTargets(step)
  if not step then return end
  if TARGET_TYPES[step.type] then
    local name = not step.item and not step.startItem and targetName(step.npc)
    return name and { name }
  end
  if step.type == "boss" then
    local name = targetName((step.name:gsub(" %(.*$", "")))
    return name and { name }
  end
  if step.type ~= "complete" or not step.quest then return end
  local entry = Q.log(step.quest)
  if entry and entry.ready then return end
  local names = {}
  for _, value in ipairs(step.mobs or (ns.questMobs and ns.questMobs[step.quest]) or {}) do
    names[#names + 1] = targetName(value)
  end
  return #names > 0 and names or nil
end

-- One /targetexact line per creature, as many as fit in a macro. The last line that finds a
-- creature wins, so the most important (the first listed) goes last.
local function targetMacro(names)
  local kept, length = {}, 0
  for _, name in ipairs(names) do
    local add = #"/targetexact " + #name + (#kept > 0 and 1 or 0)
    if length + add > MACRO_LIMIT then break end
    kept[#kept + 1], length = name, length + add
  end
  local lines = {}
  for i = #kept, 1, -1 do lines[#lines + 1] = "/targetexact " .. kept[i] end
  return table.concat(lines, "\n"), kept
end

local function targetTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  local names = self.targets or {}
  GameTooltip:SetText(#names > 1 and "Target the nearest of" or ("Target " .. tostring(names[1])))
  if #names > 1 then GameTooltip:AddLine(table.concat(names, ", "), 1, 1, 1, true) end
  GameTooltip:AddLine("Key Bindings > AddOns can give it a key.")
  GameTooltip:Show()
end

local function makeTargetButton()
  local ok, b = pcall(CreateFrame, "Button", "LevelingCodexQuestTarget", UIParent, "SecureActionButtonTemplate")
  if not ok or not b then targetButton = false; return end
  targetButton = b
  b:SetSize(32, 32)
  b:SetFrameStrata("MEDIUM")
  b:RegisterForClicks("AnyUp", "AnyDown")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  ns.setIcon(b.icon, "Ability_Hunter_SniperShot")
  if A.hasFile("Interface\\Buttons\\ButtonHilight-Square") then
    try(b.SetHighlightTexture, b, "Interface\\Buttons\\ButtonHilight-Square", "ADD")
  end
  b:SetScript("OnEnter", targetTooltip)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:Hide()
end

local function updateTargetButton()
  if targetButton == false then return end
  local row = viewer and viewer:IsShown() and Q.current()
  local names = not ns.db().noQuestTarget and stepTargets(row and row.step)
  if not names then
    if targetButton then targetButton:Hide() end
    return
  end
  if not targetButton then
    makeTargetButton()
    if not targetButton then return end
  end
  local macro, kept = targetMacro(names)
  targetButton:SetAttribute("type", "macro")
  targetButton:SetAttribute("macrotext", macro)
  targetButton.targets = kept
  local left, top = try(viewer.GetLeft, viewer), try(viewer.GetTop, viewer)
  targetButton:ClearAllPoints()
  if left and top then
    -- the window's edges are in its own units: times its scale for UIParent's
    local s = tonumber(viewer:GetScale()) or 1
    targetButton:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left * s - 10, (top - 72) * s)
  else
    targetButton:SetPoint("CENTER", UIParent, "CENTER", -260, 30)
  end
  targetButton:Show()
end

updateItemButton = function()
  if itemButton == false and targetButton == false then return end
  if try(InCombatLockdown) ~= false then itemPending = true; return end
  itemPending = false
  updateTargetButton()
  if itemButton == false then return end
  local row = viewer and viewer:IsShown() and Q.current()
  local item, icon = stepItem(row and row.step)
  local count = item and itemCount(item) or 0
  if not item or count == 0 or ns.db().noQuestItem then
    if itemButton then itemButton:Hide() end
    return
  end
  if not itemButton then
    makeItemButton()
    if not itemButton then return end
  end
  itemButton:SetAttribute("type", "item")
  itemButton:SetAttribute("item", type(item) == "number" and ("item:" .. item) or item)
  itemButton.item = item
  icon = icon or try(C_Item and C_Item.GetItemIconByID, item) or try(GetItemIcon, item)
  if not icon or itemButton.icon:SetTexture(icon) == false then itemButton.icon:SetTexture(ns.QUESTION_ICON) end
  itemButton.count:SetText(count > 1 and tostring(count) or "")
  -- Placed by the window's screen position, not anchored to it: a protected frame anchored
  -- to the window would stop the window moving or hiding in combat.
  local left, top = try(viewer.GetLeft, viewer), try(viewer.GetTop, viewer)
  itemButton:ClearAllPoints()
  if left and top then
    local s = tonumber(viewer:GetScale()) or 1
    itemButton:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left * s - 6, (top - 26) * s)
  else
    itemButton:SetPoint("CENTER", UIParent, "CENTER", -260, 80)
  end
  itemButton:Show()
end

-- The map pin (Settings > Pin the current step on the map): the game's own map waypoint on the
-- current step's spot, when the client has one. A waypoint you placed yourself is never replaced.
local pinned -- the point the Codex set last: { map, x, y } in 0-1

local function samePoint(a, map, x, y)
  return a and a.map == map and math.abs(a.x - x) < 0.0005 and math.abs(a.y - y) < 0.0005
end

local function userWaypoint()
  local point = try(C_Map.GetUserWaypoint)
  local pos = type(point) == "table" and point.position
  if type(pos) ~= "table" then return end
  local x, y = pos.x, pos.y
  if type(pos.GetXY) == "function" then x, y = try(pos.GetXY, pos) end
  if type(x) == "number" and type(y) == "number" then return point.uiMapID, x, y end
end

-- The waypoint the Codex set ({ map, x, y } in 0-1), while it's still the game's user waypoint and
-- the game's arrow tracks it (where the client can say): the minimap leaves the rim to that arrow.
function ns.questMapPinSpot()
  if not pinned then return end
  local ST = C_SuperTrack
  if type(ST) == "table" and type(ST.IsSuperTrackingUserWaypoint) == "function"
      and try(ST.IsSuperTrackingUserWaypoint) == false then return end
  local map, x, y = userWaypoint()
  if map and samePoint(pinned, map, x, y) then return { map = pinned.map, x = pinned.x, y = pinned.y } end
end

-- A waypoint on a spot of your route (a step, its way in or its points) is one the Codex set,
-- perhaps before a /reload made it forget: the game keeps user waypoints, the Codex doesn't.
local routeSpot = { key = nil, hit = false } -- the last waypoint checked, and the answer
local function onRoute(map, x, y)
  local key = map .. ":" .. x .. ":" .. y
  if routeSpot.key == key then return routeSpot.hit end
  local hit = false
  local function near(m, px, py) return m == map and px and math.abs(px / 100 - x) < 0.0005 and math.abs(py / 100 - y) < 0.0005 end
  for _, row in ipairs((Q.rows())) do
    local s = row.step
    if near(s.map, s.x, s.y) then hit = true end
    for _, p in ipairs(s.path or {}) do if near(p[3] or s.map, p[1], p[2]) then hit = true end end
    for _, p in ipairs(s.points or {}) do if near(s.map, p[1], p[2]) then hit = true end end
    if hit then break end
  end
  routeSpot.key, routeSpot.hit = key, hit
  return hit
end

local function updateMapPin()
  local M = C_Map
  if type(M) ~= "table" or type(M.SetUserWaypoint) ~= "function" then return end
  local row = viewer and viewer:IsShown() and Q.current()
  local step = row and Q.waypoint(row.step)
  local want = not ns.db().noQuestMapPin and step and step.map and step.x and step.y
  local map, x, y = userWaypoint()
  local ours = map and (pinned and samePoint(pinned, map, x, y) or not pinned and onRoute(map, x, y))
  if map and not ours then pinned = nil; return end -- the player's own waypoint
  if not want then
    if ours then try(M.ClearUserWaypoint) end
    pinned = nil
    return
  end
  x, y = step.x / 100, step.y / 100
  if ours and samePoint(pinned, step.map, x, y) then return end
  if try(M.CanSetUserWaypointOnMap, step.map) == false then
    if ours then try(M.ClearUserWaypoint) end
    pinned = nil
    return
  end
  local point = UiMapPoint and try(UiMapPoint.CreateFromCoordinates, step.map, x, y)
  if type(point) ~= "table" then
    point = { uiMapID = step.map, position = try(CreateVector2D, x, y) or { x = x, y = y } }
  end
  try(M.SetUserWaypoint, point)
  pinned = { map = step.map, x = x, y = y }
  try(C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint, true)
end

-- The quest tracker (Settings > Track the step's quest): the current step's quest goes on Blizzard's
-- objective tracker. Only a watch the Codex added is ever taken off again.
local watched
local function isWatched(id, index)
  if try(C_QuestLog and C_QuestLog.GetQuestWatchType, id) ~= nil then return true end
  local classic = index and try(IsQuestWatched, index)
  return classic == true or classic == 1
end

local function setWatch(id, index, on)
  local L = C_QuestLog
  if L and type(L.AddQuestWatch) == "function" then
    try(on and L.AddQuestWatch or L.RemoveQuestWatch, id)
  elseif index then
    try(on and AddQuestWatch or RemoveQuestWatch, index)
  end
end

local function updateQuestWatch()
  local row = viewer and viewer:IsShown() and Q.current()
  local step = row and row.step
  local entry = step and step.quest and not ns.db().noQuestWatch and Q.log(step.quest)
  local want = entry and step.quest or nil
  if watched and watched ~= want then
    local old = Q.log(watched)
    if old then setWatch(watched, old.index, false) end
    watched = nil
  end
  if want and not watched and not isWatched(want, entry.index) then
    setWatch(want, entry.index, true)
    watched = want
  end
end

-- Quests tab > Show on map: the world map at the current step's spot.
function ns.showQuestStepOnMap()
  local row = Q.current()
  local spot = row and Q.waypoint(row.step)
  local map = spot and spot.map
  if not map then ns.say("this step has no place on the map."); return end
  if type(OpenWorldMap) == "function" then
    try(OpenWorldMap, map)
  elseif type(WorldMapFrame) == "table" then
    if not WorldMapFrame:IsShown() then try(ToggleWorldMap) end
    try(WorldMapFrame.SetMapID, WorldMapFrame, map)
  else
    ns.say("this client has no world map to open.")
  end
end

-- The steps after this one (Settings > Steps shown ahead, 0-5, default 2), as UP NEXT.
local function addPreview(out, row, i)
  local count = math.max(0, math.min(5, tonumber(ns.db().questPreview) or 2))
  local upcoming = Q.upcoming(i, math.max(1, count))
  local nextRow = upcoming[1]
  if not nextRow then
    if not row.section.side and Q.autoStep() == row.step then
      out[#out + 1] = { kind = "note", tone = "dim", gap = 6, text = row.section.alternate
        and "Last step in this alternate route." or "Last step in this guide." }
    end
    return
  end
  if count == 0 then return end
  out[#out + 1] = { kind = "heading", text = "Up next" }
  if nextRow.section ~= row.section then
    out[#out + 1] = { kind = "note", tone = "dim", text = "Next section: " .. nextRow.section.title }
  end
  -- one row per step: its icon, its label and (Task 3) how far it is
  out[#out + 1] = { kind = "upnext", step = nextRow.step, text = Q.label(nextRow.step) }
  for n = 2, #upcoming do
    if upcoming[n].section ~= nextRow.section then break end
    out[#out + 1] = { kind = "upnext", step = upcoming[n].step, text = Q.label(upcoming[n].step) }
  end
end

-- Quests pinned in the Quests tab, with their open goals, then the party's steps.
local function addTracking(out)
  local shown
  for _, id in ipairs(Q.pins()) do
    local entry = Q.incomplete(id)
    if not shown then out[#out + 1] = { kind = "heading", text = "Tracking" }; shown = true end
    out[#out + 1] = { kind = "quest", text = entry.title or ("Quest " .. id) }
    addGoals(out, entry, nil, nil, true, true, 12)
  end
  local party = ns.partyLines()
  if #party > 0 then
    out[#out + 1] = { kind = "heading", text = "Party" }
    out[#out + 1] = { kind = "note", tone = "dim", text = table.concat(party, "\n") }
  end
end

-- The window's body: pooled pieces stacked from the top by their real heights, so long lines
-- never overlap. Text pieces, headings (gold capitals with a rule to the right edge) and goal rows
-- (a box that turns into a tick, the goal, and its count on the right). `onDark`: the dialog art is
-- dark and needs light text; the flat parchment fallback needs ink.
local LEFT, WIDTH = 16, 318
local pool, live, makers = {}, {}, {}
local onDark, cursor = true, 0
local CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local INKS = {
  gold = { { 1, 0.82, 0 }, { 0.5, 0.33, 0 } },
  warn = { { 1, 0.6, 0.25 }, { 0.62, 0.27, 0.04 } },
  danger = { { 1, 0.45, 0.38 }, { 0.66, 0.1, 0.08 } },
  done = { { 0.5, 0.88, 0.42 }, { 0.12, 0.45, 0.12 } },
}

local function ink(name)
  if INKS[name] then return ns.rgba(INKS[name][onDark and 1 or 2]) end
  if name == "dim" then return ns.rgba(onDark and C.dim or C.inkSoft) end
  if name == "head" then return ns.rgba(onDark and C.gold or C.ink) end
  return ns.rgba(onDark and C.light or C.ink)
end

function makers.text(template)
  local fs = viewer:CreateFontString(nil, "OVERLAY", template)
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(true)
  return fs
end

function makers.head()
  local fs = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fs:SetJustifyH("LEFT")
  return fs
end

function makers.rule() return viewer:CreateTexture(nil, "ARTWORK") end

-- An UP NEXT row: the step's icon, its label and, at the right, how far it is.
function makers.upnext()
  local r = CreateFrame("Frame", nil, viewer)
  r.icon = r:CreateTexture(nil, "OVERLAY")
  r.icon:SetPoint("TOPLEFT", 0, 0)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  r.name:SetPoint("TOPLEFT", 16, 0)
  r.dist = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.dist:SetJustifyH("RIGHT")
  r.dist:SetPoint("TOPRIGHT", 0, 0)
  return r
end

function makers.row(template)
  local r = CreateFrame("Frame", nil, viewer)
  r.edge = r:CreateTexture(nil, "ARTWORK")
  r.fill = r:CreateTexture(nil, "OVERLAY")
  r.tick = r:CreateTexture(nil, "OVERLAY")
  if not (A.hasFile(CHECK) and r.tick:SetTexture(CHECK) ~= false) then r.flatTick = true end
  r.name = r:CreateFontString(nil, "OVERLAY", template)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(true)
  r.name:SetPoint("TOPLEFT", 16, 0)
  r.count = r:CreateFontString(nil, "OVERLAY", template)
  r.count:SetJustifyH("RIGHT")
  r.count:SetPoint("TOPRIGHT", 0, 0)
  -- the goal's bar under its text: a dark track and the share done
  r.track = r:CreateTexture(nil, "ARTWORK")
  r.bar = r:CreateTexture(nil, "OVERLAY")
  -- A rising count flashes the row gold for a moment.
  r.flash = r:CreateTexture(nil, "BACKGROUND")
  r.flash:SetPoint("TOPLEFT", -4, 2)
  r.flash:SetPoint("BOTTOMRIGHT", 4, -2)
  r.flash:SetColorTexture(1, 0.82, 0, 0.35)
  r.flash:SetAlpha(0)
  r.flash._isFlash = true
  if type(r.flash.CreateAnimationGroup) == "function" then
    r.flashAnim = r.flash:CreateAnimationGroup()
    local fade = r.flashAnim:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.6)
    fade:SetToAlpha(0)
    fade:SetDuration(0.5)
  end
  return r
end

local function take(kind, template)
  local key = kind .. ":" .. (template or "")
  pool[key] = pool[key] or {}
  local piece = table.remove(pool[key])
  if not piece then
    piece = makers[kind](template)
    piece.codexPool = key
  end
  live[#live + 1] = piece
  piece:ClearAllPoints()
  piece:Show()
  return piece
end

local function releaseAll()
  for n = #live, 1, -1 do
    local piece = live[n]
    piece:Hide()
    table.insert(pool[piece.codexPool], piece)
    live[n] = nil
  end
end

local function putText(text, tone, template, indent, spacing)
  indent = indent or 0
  local fs = take("text", template or "GameFontHighlightSmall")
  fs:SetWidth(WIDTH - indent)
  fs:SetPoint("TOPLEFT", LEFT + indent, -cursor)
  try(fs.SetSpacing, fs, spacing or 0)
  fs:SetText(Q.plain(text))
  fs:SetTextColor(ink(tone))
  cursor = cursor + (tonumber(fs:GetStringHeight()) or 12) + 3
end

local function putHeading(text)
  cursor = cursor + 6
  local fs = take("head")
  fs:SetPoint("TOPLEFT", LEFT, -cursor)
  fs:SetText(Q.plain(text):upper())
  fs:SetTextColor(ink("head"))
  local width = math.ceil(tonumber(try(fs.GetStringWidth, fs)) or 80)
  if width + 12 < WIDTH then
    local rule = take("rule")
    local r, g, b = ink("head")
    rule:SetColorTexture(r, g, b, 0.35)
    rule:SetPoint("TOPLEFT", LEFT + width + 6, -(cursor + 5))
    rule:SetSize(WIDTH - width - 6, 1)
  end
  cursor = cursor + 15
end

-- Goal counts drawn for the step on screen: a count that rose since the last draw flashes its row.
local seenCounts, newCounts, countsRow = {}, {}, nil
-- Goal bars: the current step kind's colour (set by the refresh), the loop's other quests in orange,
-- a finished goal green and full.
local goalColor
local LOOP_COLOR, DONE_COLOR, TRACK_COLOR = { 0.95, 0.65, 0.25 }, { 0.45, 0.85, 0.4 }, { 0.1, 0.13, 0.15, 0.9 }

local function putGoal(b)
  local small, indent = b.small, b.indent or 0
  local r = take("row", small and "GameFontHighlightSmall" or "GameFontHighlight")
  local width, line = WIDTH - indent, small and 12 or 14
  r:SetPoint("TOPLEFT", LEFT + indent, -cursor)
  r:SetWidth(width)
  r.count:SetText(b.count and (b.done and "done" or b.count) or "")
  r.count:SetShown(b.count ~= nil)
  local countWidth = b.count and math.ceil(tonumber(try(r.count.GetStringWidth, r.count)) or 30) + 8 or 0
  r.name:SetWidth(width - 16 - countWidth)
  r.name:SetText(Q.plain(b.text))
  r.name:SetTextColor(ink(b.done and "done" or (small and "dim" or "text")))
  r.count:SetTextColor(ink(b.done and "done" or (b.started and "gold" or "dim")))
  -- The box: an edge with the window's colour inside. Done: the ready-check tick in its place,
  -- or (no tick art) a green box with a green centre.
  local size = small and 7 or 9
  local top = -math.floor((line - size) / 2)
  local ticked = b.done and not r.flatTick
  r.edge:SetShown(not ticked)
  r.fill:SetShown(not ticked)
  r.edge:SetPoint("TOPLEFT", 2, top)
  r.edge:SetSize(size, size)
  r.edge:SetColorTexture(ink(b.done and "done" or "dim"))
  r.fill:SetPoint("TOPLEFT", 3, top - 1)
  r.fill:SetSize(size - 2, size - 2)
  if onDark then r.fill:SetColorTexture(0, 0, 0, 0.75) else r.fill:SetColorTexture(ns.rgba(C.parch)) end
  r.tick:SetShown(b.done)
  if ticked then
    local tick = size + 7
    local shift = math.floor((tick - size) / 2)
    r.tick:SetPoint("TOPLEFT", 2 - shift, top + shift)
    r.tick:SetSize(tick, tick)
  elseif b.done then
    r.tick:SetPoint("TOPLEFT", 4, top - 2)
    r.tick:SetSize(size - 4, size - 4)
    r.tick:SetColorTexture(ink("done"))
  end
  local have = type(b.count) == "string" and tonumber(b.count:match("^(%d+)"))
  if have then
    local before = seenCounts[b.text]
    if before and have > before and r.flashAnim then
      r.flashAnim:Stop()
      r.flashAnim:Play()
    end
    newCounts[b.text] = have
  end
  local height = math.max(line, tonumber(r.name:GetStringHeight()) or line)
  local need = type(b.count) == "string" and tonumber(b.count:match("/(%d+)$"))
  r.track:SetShown(need ~= nil)
  r.bar:SetShown(need ~= nil)
  if need then
    local barWidth = width - 16
    r.track:ClearAllPoints()
    r.track:SetPoint("TOPLEFT", 16, -(height + 1))
    r.track:SetSize(barWidth, 4)
    r.track:SetColorTexture(ns.rgba(TRACK_COLOR))
    local share = b.done and 1 or (need > 0 and math.min(1, (have or 0) / need) or 0)
    local color = b.done and DONE_COLOR or (small and LOOP_COLOR or goalColor or C.accent)
    r.bar:ClearAllPoints()
    r.bar:SetPoint("TOPLEFT", r.track, "TOPLEFT", 0, 0)
    r.bar:SetSize(math.max(0.01, barWidth * share), 4)
    r.bar:SetColorTexture(color[1], color[2], color[3], 1)
    height = height + 6
  end
  r:SetHeight(height)
  cursor = cursor + height + (small and 1 or 2)
end

-- How far an up-next step is: "N yd" on your map, its zone's name on another, else nothing.
local nextRows = {} -- the up-next rows drawn now, for the tick to update their distances
local compactStep -- compact mode: the step whose distance the title row shows (the tick updates it)
local function nextDistance(step)
  local spot = step and Q.waypoint(step)
  if not (spot and spot.map) then return "" end
  local map, x, y = Q.position()
  if spot.map == map then
    local _, yards = Q.vector(spot, map, x, y)
    return yards and (math.floor(yards + 0.5) .. " yd") or ""
  end
  local info = try(C_Map and C_Map.GetMapInfo, spot.map)
  return type(info) == "table" and type(info.name) == "string" and Q.plain(info.name) or ""
end

function ns.questNextDistances()
  for _, r in ipairs(nextRows) do
    if r:IsShown() and r.step then r.dist:SetText(nextDistance(r.step)) end
  end
  if compactStep and levels and viewer and viewer:IsShown() then levels:SetText(nextDistance(compactStep)) end
end

local function putNext(b)
  local r = take("upnext")
  r:SetPoint("TOPLEFT", LEFT, -cursor)
  r:SetSize(WIDTH, 13)
  ns.questMap.paintIcon(r.icon, b.step, 12, 6)
  r.step = b.step
  r.dist:SetText(nextDistance(b.step))
  r.dist:SetTextColor(ink("dim"))
  local distWidth = math.ceil(tonumber(try(r.dist.GetStringWidth, r.dist)) or 40) + 8
  r.name:SetWidth(WIDTH - 16 - distWidth)
  r.name:SetText(Q.plain(b.text))
  r.name:SetTextColor(ink("dim"))
  nextRows[#nextRows + 1] = r
  cursor = cursor + 14
end

local function draw(blocks)
  nextRows = {}
  local last
  for _, b in ipairs(blocks) do
    if b.gap then cursor = cursor + b.gap end
    if b.kind == "goal" and last and last ~= "goal" and last ~= "quest" then cursor = cursor + 3 end
    if b.kind == "goal" then putGoal(b)
    elseif b.kind == "heading" then putHeading(b.text)
    elseif b.kind == "quest" then putText(b.text, "text", "GameFontHighlightSmall", 0)
    elseif b.kind == "text" then putText(b.text, "text", nil, 0, 2)
    elseif b.kind == "note" then putText(b.text, b.tone)
    elseif b.kind == "danger" then cursor = cursor + 3; putText(b.text, "danger")
    elseif b.kind == "upnext" then putNext(b)
    elseif b.kind ~= "chain" then putText(b.text, "text") end
    last = b.kind
  end
end

-- The bar's fill slides from where it is to the new share over 0.5 s, easing out.
local function slideBar(self)
  local t = math.min(1, (GetTime() - self.t0) / 0.5)
  self.width = self.from + (self.to - self.from) * (1 - (1 - t) ^ 3)
  self.fill:SetWidth(math.max(0.01, self.width))
  self.fill:SetShown(self.width >= 1)
  if t >= 1 then self:SetScript("OnUpdate", nil) end
end

local function paintBar(row)
  local passed, total = 0, 0
  if row and not ns.db().noStepBar then passed, total = Q.stepProgress(row.section) end
  if total == 0 then bar:Hide(); return false end
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", LEFT, -cursor)
  bar.edge:SetColorTexture(ns.rgba(onDark and C.edge or C.inkSoft))
  if bar.fillArt then bar.fill:SetVertexColor(ns.rgba(C.accent)) else bar.fill:SetColorTexture(ns.rgba(C.accent)) end
  bar.pct:SetText(math.floor(passed * 100 / total) .. "%")
  bar.pct:SetTextColor(ink("dim"))
  local target = BAR_TRACK * passed / total
  if bar.to == nil or not bar:IsShown() then
    bar.from, bar.to, bar.width = target, target, target
    bar.fill:SetWidth(math.max(0.01, target))
    bar.fill:SetShown(target >= 1)
  elseif math.abs(target - bar.to) >= 0.5 then
    bar.from, bar.to, bar.t0 = bar.width or bar.to, target, GetTime()
    bar:SetScript("OnUpdate", slideBar)
  end
  bar:Show()
  return true
end

function ns.questRefresh()
  local row, i = Q.current()
  local suggestion = Q.suggestions()[1]
  local _, _, _, _, selected = Q.rows()
  local sec = row and row.section or selected
  completionSound(row)
  if not dismissed and sec then
    painting = true
    if not viewer then makeViewer() end
    place()
    if theme ~= ns.themeVersion then
      local backdrop = A.backdrop(viewer, "dialog", C.parch, C.edge)
      flatBackground:SetColorTexture(ns.rgba(C.parch))
      flatBackground:SetShown(not backdrop)
      -- Ink only on the flat parchment; the dialog art is dark, so it needs light text.
      onDark = backdrop and true or false
      title:SetTextColor(ns.rgba(C.gold))
      for _, b in ipairs(viewer.buttons) do b:Repaint() end
      nextButton:Repaint()
      suggestionButton:Repaint()
      theme = ns.themeVersion
    end
    fitHeader(sec.title:match("^([^:]+):") or sec.title)
    levels:SetText("Levels " .. sec.levels[1] .. "-" .. sec.levels[2])
    title:SetWidth(318 - math.ceil(tonumber(try(levels.GetStringWidth, levels)) or 70) - 10)
    local run, runCount = Q.readyRun()
    local blocks = {}
    local icon = row and ns.questIcon(row.step)
    viewer.titleIcon:SetShown(icon ~= nil)
    if icon then viewer.titleIcon:SetTexture(icon) end
    -- the step's kind: a stripe, a chip (dark plate, light label) and the title in its colour
    local kind = row and ns.questStepKind(row.step)
    local style = kind and ns.questKindStyle(kind, row.step)
    goalColor = style and style.color or nil
    local compact = ns.db().questCompact and true or false
    local cb = viewer.compactButton
    cb.codexLabel = compact and "Expand" or "Compact"
    cb.tipTitle = compact and "Expand" or "Compact"
    local fold = compact and A.FILES.plusUp or A.FILES.minusUp
    if cb.icon and A.hasFile(fold) then cb.icon:SetTexture(fold)
    elseif cb.label then cb.label:SetText(compact and "+" or "-") end
    local portrait = viewer.portrait:ShowFor(not compact and row and row.step or nil, kind)
    if portrait then viewer.titleIcon:Hide() end
    local x = portrait and 64 or (icon and 36 or 16)
    viewer.stripe:SetShown(style ~= nil)
    viewer.chip:SetShown(style ~= nil)
    if style then
      local r, g, b = style.color[1], style.color[2], style.color[3]
      viewer.stripe:SetColorTexture(r, g, b, 1)
      viewer.chip.plate:SetColorTexture(r * 0.3, g * 0.3, b * 0.3, 0.9)
      viewer.chip.text:SetText(style.label)
      viewer.chip.text:SetTextColor(r + (1 - r) * 0.5, g + (1 - g) * 0.5, b + (1 - b) * 0.5)
      local chipWidth = math.ceil(tonumber(try(viewer.chip.text.GetStringWidth, viewer.chip.text)) or 36) + 10
      viewer.chip:SetSize(chipWidth, 14)
      viewer.chip:ClearAllPoints()
      viewer.chip:SetPoint("TOPLEFT", x, -28)
      x = x + chipWidth + 6
    end
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", x, -28)
    title:SetWidth(334 - x - math.ceil(tonumber(try(levels.GetStringWidth, levels)) or 70) - 10)
    if row ~= countsRow then seenCounts, countsRow = {}, row end
    newCounts = {}
    if row then
      -- the chip says what to do, the title names it (a quest, a flight point); a step without a name
      -- takes the first sentence of its text; the full label stays the title's codexLabel
      local s = row.step
      local label = Q.label(s)
      local name = not (s.type == "hearth" and s.bind) and (s.name or s.flight) or nil
      if not name and type(s.text) == "string" and not (s.type == "hearth" and s.bind) then
        local text = Q.plain(s.text)
        name = text:match("^(.-[%.!?])%s") or text
        if #name > 70 then name = name:sub(1, 67) .. "..." end
        if name == "" then name = nil end
      end
      title:SetText(Q.plain(name or label))
      title.codexLabel = Q.plain(label)
      if style then
        -- on the light parchment (no dialog art) a darker shade keeps the title readable
        local shade = onDark and 1 or 0.55
        title:SetTextColor(style.color[1] * shade, style.color[2] * shade, style.color[3] * shade)
      end
      -- A planned run that's ready leads the step text until you go (Run <dungeon> below).
      if run then
        blocks[1] = { kind = "note", tone = "gold", text = "Find a group for " .. run.title .. ": " .. runCount
          .. " of its quests are in your log. Then press Run " .. run.title .. "." }
      end
      for _, b in ipairs(Q.detailBlocks(row.step, row.requiredFor, true)) do blocks[#blocks + 1] = b end
      addPreview(blocks, row, i)
    else
      title.codexLabel = nil
      title:SetTextColor(ns.rgba(C.gold))
      title:SetText(sec.alternate and "End of the alternate route" or "End of the leveling guide")
      blocks[1] = { kind = "text", text = suggestion and "Try the suggested section below, or open Quests to choose another."
        or "Open Quests to revisit a section or check for missed quests." }
    end
    addTracking(blocks)
    compactStep = nil
    if compact then
      -- compact: at the right of the title, the first unfinished goal's count, else how far the step
      -- is (kept live by the tick); the title is sized after it, so a long zone name can't overlap
      local right = ""
      for _, b in ipairs(blocks) do
        if b.kind == "goal" and b.count and not b.done and not b.small then right = b.count; break end
      end
      if right == "" and row then
        right = nextDistance(row.step)
        compactStep = row.step
      end
      levels:SetText(right)
      title:SetWidth(334 - x - math.ceil(tonumber(try(levels.GetStringWidth, levels)) or 0) - 10)
    end
    releaseAll()
    cursor = 28 + math.max(14, title:GetStringHeight()) + 2
    local xpX, xpY = LEFT, nil
    if portrait then xpX, xpY = 64, cursor end
    -- a turn-in's XP, when the game says how much (the quest must be in your log)
    local xp = not compact and row and kind == "turnin" and row.step.quest and Q.log(row.step.quest)
      and tonumber((try(GetQuestLogRewardXP, row.step.quest))) or 0
    viewer.xp:SetShown(xp > 0)
    if xp > 0 then
      viewer.xp.text:SetText("+" .. ns.thousands(xp) .. " XP")
      viewer.xp:SetSize(math.ceil(tonumber(try(viewer.xp.text.GetStringWidth, viewer.xp.text)) or 50) + 10, 14)
      local cur, max = tonumber((try(UnitXP, "player"))), tonumber((try(UnitXPMax, "player")))
      local levelsUp = cur and max and max > 0 and cur + xp >= max and (UnitLevel("player") or 1) < 60
      viewer.xp.note:SetText(levelsUp and "levels you up" or "")
      viewer.xp:ClearAllPoints()
      viewer.xp:SetPoint("TOPLEFT", xpX, -(xpY or cursor))
      if not xpY then cursor = cursor + 17 end
    end
    -- the detail starts below the portrait
    if portrait then cursor = math.max(cursor, 74) end
    if not compact then
      -- A story chain's place sits right under the step's name.
      for _, b in ipairs(blocks) do
        if b.kind == "chain" then putText(b.text, "dim") end
      end
    end
    cursor = cursor + 3
    if paintBar(row) then cursor = cursor + 12 end
    if not compact then draw(blocks) else nextRows = {} end
    seenCounts = newCounts
    nextButton:SetShown(row ~= nil)
    local choosing = row and row.step.type == "plan"
    nextButton.codexLabel = choosing and "Skip" or "Next"
    nextButton:SetLabel(choosing and "Skip run" or "Next step", true)
    local returnToRoute = sec.side
    if run and not announced[run.id] then
      announced[run.id] = true
      ns.say(Q.plain(run.title .. ": " .. runCount .. " of its quests are in your log. Find a group, then use Run "
        .. run.title .. " in the step window for the checklist."))
    end
    local related = Q.relatedGuide()
    local setup = ns.questSetupDue()
    local offer = choosing or returnToRoute or run or suggestion or related or setup
    suggestionButton:SetShown(offer ~= nil and offer ~= false)
    if offer then
      suggestionButton.codexLabel = choosing and ("Plan " .. row.step.name)
        or returnToRoute and "Return to leveling" or run and ("Run " .. run.title)
        or suggestion and ("Try " .. suggestion.title) or related and ("Plan " .. related.title) or "Set up the guide"
      suggestionButton:SetLabel(suggestionButton.codexLabel)
    end
    viewer:SetHeight(compact and (cursor + (offer and 64 or 38)) or math.max(140, cursor + (offer and 64 or 38)))
    applyComfort()
    viewer:Show()
    painting = false
    paintArrow()
  elseif viewer and viewer:IsShown() then
    painting = true
    viewer:Hide()
    painting = false
  end
  updateItemButton()
  updateMapPin()
  ns.questMap.refresh()
  updateQuestWatch()
  ns.partyStepChanged()
  ns.refreshQuestTab()
end

-- Quests tab > Report this step: what the guide sees, in the copy box, for a bug report.
function ns.reportQuestStep()
  local row, i = Q.current()
  local lines = {}
  local function add(key, value) lines[#lines + 1] = key .. ": " .. Q.plain(tostring(value)) end
  local version = try(C_AddOns and C_AddOns.GetAddOnMetadata, "LevelingCodex", "Version")
    or try(GetAddOnMetadata, "LevelingCodex", "Version")
  add("Leveling Codex", version or "unknown version")
  local _, race = try(UnitRace, "player")
  local _, class = UnitClass("player")
  add("Character", tostring(race) .. " " .. tostring(class) .. ", level " .. tostring(UnitLevel("player")))
  local map, x, y = Q.position()
  add("Position", map and (map .. (x and string.format(" at %.2f, %.2f", x, y) or ", no coordinates")) or "unknown")
  add("Hearthstone", Q.bindLocation() or "unknown")
  add("In flight", Q.inFlight() and "yes" or "no")
  if row then
    local s = row.step
    add("Guide", row.section.id .. " (" .. row.section.title .. ")")
    add("Step", "#" .. i .. " " .. row.key .. ", " .. tostring(row.state))
    add("Step place", s.map and (s.map .. " at " .. tostring(s.x) .. ", " .. tostring(s.y)) or "none")
    add("Step text", s.text or "")
    if s.quest then
      local entry = Q.log(s.quest)
      add("Quest", s.quest .. " " .. (entry and (entry.ready and "ready to turn in" or "in log") or "not in log"))
    end
  else
    add("Step", "none")
  end
  local quests = {}
  for id, entry in pairs(Q.logEntries()) do
    local done, total = 0, 0
    for _, obj in ipairs(entry.objectives or {}) do
      total = total + 1
      if obj.finished == true or obj.finished == 1 then done = done + 1 end
    end
    quests[#quests + 1] = id .. (entry.ready and " ready" or (" " .. done .. "/" .. total))
  end
  table.sort(quests)
  add("Quest log", #quests > 0 and table.concat(quests, ", ") or "empty")
  ns.showMacroCopy({ name = "step report", body = table.concat(lines, "\n"), recording = true,
    copyTitle = "Copy this step report" })
end

function ns.followSuggestedQuestSection(section)
  section = section or Q.suggestions()[1]
  if not section then return end
  if not Q.resumeActive(section) then Q.jump(section) end
  quiet = true
  ns.showQuestViewer()
end

function ns.showQuestViewer()
  dismissed = false
  ns.questRefresh()
end

function ns.hideQuestViewer()
  dismissed = true
  ns.questRefresh()
end

function ns.updateQuestSettings()
  Q.update()
  ns.questRefresh()
end

-- Dungeon ahead: Plan <dungeon> (its quests join the route) or Skip.
function ns.planQuestRun(id, on)
  local run = Q.section(id)
  Q.setPlanned(id, on)
  Q.leaveReview()
  if run then
    ns.say(Q.plain(run.title .. (on and " is planned: the run joins your route, and the guide says when to find a group."
      or " is skipped: Quests > Guides > Dungeons can plan it later.")))
  end
  ns.updateQuestSettings()
end

local function observation(kind, id, fields)
  if not recorder then return end
  local db = ns.db()
  db.rec = db.rec or {}
  if #db.rec >= 4000 then
    recorder = false
    ns.say("quest recorder is full. Use /codex record copy to save its observations.")
    return
  end
  local map, x, y = Q.position()
  local row = fields or {}
  row.type, row.quest, row.map, row.x, row.y = kind, id, map, x, y
  row.npc = Q.plain(try(UnitName, "npc"))
  db.rec[#db.rec + 1] = row
  return row
end

local function recordObjectives()
  if not recorder then return end
  local counts = {}
  for id, entry in pairs(Q.logEntries()) do
    local old = objectiveCounts[id] or {}
    local current = {}
    counts[id] = current
    for i, obj in ipairs(entry.objectives) do
      local have = tonumber(obj.numFulfilled) or (obj.finished and 1 or 0)
      current[i] = have
      if old[i] and have > old[i] then
        observation("complete", id, { name = Q.plain(entry.title), objective = i,
          text = Q.plain(obj.text), count = have, required = obj.numRequired })
      end
    end
  end
  objectiveCounts = counts
end

local function taxiSnapshot()
  local nodes = {}
  for i = 1, tonumber(try(NumTaxiNodes)) or 0 do
    local name, state = try(TaxiNodeName, i), try(TaxiNodeGetType, i)
    if name and state and state ~= "NONE" then nodes[name] = state end
  end
  return nodes
end

local function recordFlight()
  if not recorder then return end
  local taxi = try(UnitOnTaxi, "player")
  if taxi and not onTaxi then
    observation("fly", nil, { name = flightTarget, text = "Flight started" })
  elseif taxi == false and onTaxi then
    observation("fly", nil, { name = flightTarget, text = "Flight ended" })
    flightTarget = nil
  end
  onTaxi = taxi
end

function ns.questRecord(command)
  if command == "copy" then
    local lines = { "Action\tQuest ID\tName\tNPC\tMap\tX\tY\tObservation" }
    for _, row in ipairs(ns.db().rec or {}) do
      lines[#lines + 1] = table.concat({ row.type, row.quest or "", row.name or "", row.npc or "",
        row.map or "", row.x and string.format("%.2f", row.x) or "", row.y and string.format("%.2f", row.y) or "",
        ns.plain((row.text or ""):gsub("[%c]", " ")) }, "\t")
    end
    ns.showMacroCopy({ name = "quest recorder log", body = table.concat(lines, "\n"), recording = true })
    return
  end
  recorder = not recorder
  if recorder then
    objectiveCounts, onTaxi, flightPaths, flightTarget = {}, try(UnitOnTaxi, "player"), nil, nil
    recordObjectives()
  end
  ns.say(recorder and "quest recorder on. Use /codex record copy to export." or "quest recorder off.")
end

-- Alt, or Questie's own hold-back key, stops the Codex's automation.
local function heldBack()
  if try(IsAltKeyDown) then return true end
  return ns.questie.modifierHeld()
end

-- Questie's own auto-accept / auto-complete handles the quest when it is on.
local function autoAccepting(db) return db.questAutoAccept and not ns.questie.autoAccept() end
local function autoTurningIn(db) return db.questAutoTurnin and not ns.questie.autoComplete() end

local function interact(event)
  local id = try(GetQuestID)
  if event == "QUEST_DETAIL" then
    observation("detail", id, { name = Q.plain(try(GetTitleText)), text = Q.plain(try(GetObjectiveText)) })
  end
  local s = Q.autoStep()
  if not id or not s or s.quest ~= id or try(InCombatLockdown) ~= false or heldBack() then return end
  local db = ns.db()
  if event == "QUEST_DETAIL" and s.type == "accept" and autoAccepting(db) then
    try(AcceptQuest)
  elseif s.type == "turnin" and autoTurningIn(db) then
    if event == "QUEST_PROGRESS" and try(IsQuestCompletable) == true then
      try(CompleteQuest)
    elseif event == "QUEST_COMPLETE" and try(GetNumQuestChoices) == 0 and (try(GetQuestMoneyToGet) or 0) == 0 then
      try(GetQuestReward, 0)
    end
  end
end

-- The quest reward that sells for the most gets a coin mark and a chat line (Settings > Mark
-- the best-selling quest reward). The Codex never picks a reward for you.
local rewardMark

local function rewardButton(i)
  local list = type(QuestInfoRewardsFrame) == "table" and QuestInfoRewardsFrame.RewardButtons
  return _G["QuestInfoRewardsFrameQuestInfoItem" .. i] or (type(list) == "table" and list[i])
    or _G["QuestRewardItem" .. i]
end

local function markReward(tries)
  if rewardMark then rewardMark:Hide() end
  if ns.db().noRewardHint then return end
  local choices = tonumber(try(GetNumQuestChoices)) or 0
  if choices < 2 then return end
  local best, bestValue, bestName, missing = nil, 0, nil, false
  for i = 1, choices do
    local name, _, count = try(GetQuestItemInfo, "choice", i)
    local link = try(GetQuestItemLink, "choice", i)
    local price = link and select(11, try(GetItemInfo, link))
    if price == nil then missing = true end
    local value = (tonumber(price) or 0) * math.max(1, tonumber(count) or 1)
    if value > bestValue then best, bestValue, bestName = i, value, name end
  end
  if missing and (tries or 0) < 3 then
    ns.after(0.5, function() markReward((tries or 0) + 1) end) -- item info still loading
    return
  end
  if not best then return end
  ns.say(Q.plain((bestName or ("Reward " .. best)) .. " sells for the most (" .. ns.money(bestValue) .. ")."))
  local button = rewardButton(best)
  if type(button) ~= "table" or type(button.GetFrameLevel) ~= "function" then return end
  if not rewardMark then
    rewardMark = CreateFrame("Frame", "LevelingCodexRewardMark", button)
    rewardMark:SetSize(18, 18)
    rewardMark.icon = rewardMark:CreateTexture(nil, "OVERLAY")
    rewardMark.icon:SetAllPoints()
    ns.setIcon(rewardMark.icon, "INV_Misc_Coin_02")
  end
  rewardMark:SetParent(button)
  rewardMark:ClearAllPoints()
  rewardMark:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
  rewardMark:SetFrameLevel((tonumber(try(button.GetFrameLevel, button)) or 1) + 5)
  rewardMark:Show()
end

local function sameTitle(a, b)
  return type(a) == "string" and type(b) == "string" and Q.plain(a):lower() == Q.plain(b):lower()
end

-- Many NPCs open a gossip or greeting list before the quest window. With auto-accept or
-- auto-turn-in on, pick the guide's current quest there (never another; Alt or Questie's key holds it back).
local function pickFromList(event)
  local s = Q.autoStep()
  if not s or not s.quest or try(InCombatLockdown) ~= false or heldBack() then return end
  local db = ns.db()
  local accept = s.type == "accept" and autoAccepting(db)
  local turnin = s.type == "turnin" and autoTurningIn(db)
  if not accept and not turnin then return end
  if event == "GOSSIP_SHOW" then
    local G = C_GossipInfo
    if type(G) ~= "table" then return end
    local list = try(accept and G.GetAvailableQuests or G.GetActiveQuests)
    for _, q in ipairs(type(list) == "table" and list or {}) do
      if type(q) == "table" and (q.questID == s.quest or sameTitle(q.title, s.name)) then
        try(accept and G.SelectAvailableQuest or G.SelectActiveQuest, q.questID)
        return true
      end
    end
    return
  end
  for i = 1, tonumber(try(accept and GetNumAvailableQuests or GetNumActiveQuests)) or 0 do
    local id
    if accept then id = select(5, try(GetAvailableQuestInfo, i)) else id = try(GetActiveQuestID, i) end
    if id == s.quest or sameTitle(try(accept and GetAvailableTitle or GetActiveTitle, i), s.name) then
      try(accept and SelectAvailableQuest or SelectActiveQuest, i)
      return true
    end
  end
end

-- Travel automation (Settings > Auto-fly: take the guide's flights and binds, off by default): the
-- flight master's and innkeeper's gossip options and the step's flight. Alt holds it back, and
-- nothing happens in combat. The bind's own popup is the player's: accepting or hiding a Blizzard
-- popup from addon code is blocked ("blocked from an action only available to the Blizzard UI")
-- and taints the popups, so the next protected one (the Spirit Healer's Accept) is blocked too.
local function travelAllowed()
  return ns.db().questAutoTravel and try(InCombatLockdown) == false and not try(IsAltKeyDown)
end

-- A bind step only binds at its own inn: you must be near the step's innkeeper.
local function nearStep(step)
  local _, yards = Q.vector(step, Q.position())
  return yards and yards <= Q.arrived() * 2
end

local GOSSIP = {
  taxi = { icon = "TaxiGossipIcon", words = { "where i can fly", "i need a ride" } },
  binder = { icon = "BinderGossipIcon", words = { "inn your home", "make this inn" } },
}

local function gossipIs(option, kind)
  local want = GOSSIP[kind]
  if option.type == kind then return true end
  local icon = option.icon
  if type(icon) == "string" and icon:find(want.icon, 1, true) then return true end
  if type(icon) == "number" and icon == try(GetFileIDFromPath, "Interface\\GossipFrame\\" .. want.icon) then
    return true
  end
  local name = type(option.name) == "string" and Q.plain(option.name):lower() or ""
  for _, word in ipairs(want.words) do
    if name:find(word, 1, true) then return true end
  end
  return false
end

local function pickGossip(kind)
  local G = C_GossipInfo
  local options = type(G) == "table" and try(G.GetOptions)
  if type(options) == "table" then
    for _, option in ipairs(options) do
      if type(option) == "table" and option.gossipOptionID and gossipIs(option, kind) then
        try(G.SelectOption, option.gossipOptionID)
        return true
      end
    end
    return false
  end
  local list = { try(GetGossipOptions) } -- classic: text, type pairs
  for i = 1, #list, 2 do
    if gossipIs({ name = list[i], type = list[i + 1] }, kind) then
      try(SelectGossipOption, (i + 1) / 2)
      return true
    end
  end
  return false
end

local function travelGossip()
  if not travelAllowed() then return end
  local s = Q.autoStep()
  if Q.flightStep() or (s and s.type == "getfp") or Q.atPlannedFlightMaster() then
    pickGossip("taxi")
  elseif s and s.type == "sethearth" and nearStep(s) then
    pickGossip("binder")
  end
end

-- The flight map: mark the guide's flight (a Fly step's, else the travel plan's from here) and,
-- with travel automation on, take it.
local function takeFlight(nodes)
  local target = Q.flightTarget(nodes)
  ns.markTaxi(target)
  if not (target and travelAllowed()) then return end
  local want = Q.plain(target):lower()
  for i = 1, tonumber(try(NumTaxiNodes)) or 0 do
    local name = try(TaxiNodeName, i)
    if type(name) == "string" and Q.plain(name):lower() == want then
      if try(TaxiNodeGetType, i) == "REACHABLE" then
        ns.say("flying to " .. Q.plain(name) .. ". Hold Alt at the flight master to pick your own flight.")
        try(TakeTaxiNode, i)
      end
      return
    end
  end
end

-- A boss died: ENCOUNTER_END (encounterID, name, difficulty, size, success) or BOSS_KILL
-- (encounterID, name). A rare without an encounter is passed with Next. Never the combat log:
-- Forever blocks addons from registering or unregistering COMBAT_LOG_EVENT_UNFILTERED ("blocked
-- from an action only available to the Blizzard UI", reported as UNKNOWN()).
local function bossEvent(event, a, b, e)
  if event == "ENCOUNTER_END" then
    if e == 1 or e == true then return Q.bossDown(tonumber(a), b) end
  elseif event == "BOSS_KILL" then
    return Q.bossDown(tonumber(a), b)
  end
end

local function handle(event, a, b, c, d, e)
  if event == "ENCOUNTER_END" or event == "BOSS_KILL" then
    if bossEvent(event, a, b, e) then ns.questRefresh() end
    return
  end
  if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_FINISHED" then
    if rewardMark then rewardMark:Hide() end
    if event == "QUEST_FINISHED" then return end
    interact(event)
    if event == "QUEST_COMPLETE" then markReward() end
    return
  end
  if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then
    if not pickFromList(event) and event == "GOSSIP_SHOW" then travelGossip() end
    return
  end
  if event == "CHAT_MSG_COMBAT_XP_GAIN" then
    noteKill(a)
    return
  end
  if event == "PLAYER_XP_UPDATE" then
    local row = Q.current()
    if not (row and row.step.type == "grind") then return end
  end
  if event == "BAG_UPDATE_DELAYED" then
    if Q.bagsChanged() then
      quiet = true
      ns.questRefresh()
    else
      updateItemButton()
    end
    return
  end
  if event == "PLAYER_REGEN_DISABLED" then inCombat = true; return end
  if event == "PLAYER_REGEN_ENABLED" then
    inCombat = false
    if comfortPending then applyComfort() end
  end
  if event == "PLAYER_REGEN_ENABLED" and itemPending then
    updateItemButton()
    return
  end
  if event == "PLAYER_REGEN_ENABLED" then return end
  local id = event == "QUEST_ACCEPTED" and (tonumber(b) or tonumber(a)) or tonumber(a)
  local old = id and Q.log(id)
  Q.update(event, id, event == "PLAYER_LEVEL_UP" and id or nil)
  local nodes = event == "TAXIMAP_OPENED" and taxiSnapshot()
  if nodes then
    for name, kind in pairs(nodes) do
      if kind == "CURRENT" then flight.origin = Q.plain(name) end
    end
    Q.learnFlights(nodes)
    takeFlight(nodes)
  end
  if event == "HEARTHSTONE_BOUND" or event == "PLAYER_BIND_CHANGED" then
    Q.acknowledge("sethearth", function(step)
      local _, distance = Q.vector(step, Q.position())
      return distance and distance <= Q.arrived()
    end)
  end
  if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
    Q.checkPosition()
  end
  if recorder then
    if event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
      local entry = (id and Q.log(id)) or old
      local name = entry and entry.title or try(C_QuestLog and C_QuestLog.GetTitleForQuestID, id)
      local labels = {}
      if event == "QUEST_ACCEPTED" then
        for _, obj in ipairs(entry and entry.objectives or {}) do labels[#labels + 1] = Q.plain(obj.text) end
      end
      observation(event == "QUEST_ACCEPTED" and "accept" or "turnin", id, {
        name = Q.plain(name), level = entry and entry.level, text = table.concat(labels, " / "),
      })
    elseif event == "HEARTHSTONE_BOUND" or event == "PLAYER_BIND_CHANGED" then
      observation("sethearth", nil, { name = Q.plain(try(GetBindLocation)) })
    elseif nodes then
      for name, state in pairs(nodes) do
        if state == "CURRENT" and flightPaths and not flightPaths[name] then
          observation("getfp", nil, { name = Q.plain(name) })
        end
      end
      flightPaths = nodes
    elseif event == "NEW_TAXI_PATH" then
      observation("getfp", nil, { text = "New flight path learned" })
    end
    recordObjectives()
  end
  ns.questRefresh()
end

-- Questie's tracker can appear, hide or move without a quest event: check every tick, and
-- move the item and target buttons (placed by screen position) when the window moved with it.
local followLeft, followTop
local function followTracker()
  if not viewer or not viewer:IsShown() then return end
  place()
  if placedBy ~= "left" and placedBy ~= "right" then return end
  local left, top = try(viewer.GetLeft, viewer), try(viewer.GetTop, viewer)
  if left ~= followLeft or top ~= followTop then
    followLeft, followTop = left, top
    updateItemButton()
  end
end

function ns.startQuestGuide()
  for _, ev in ipairs({ "PLAYER_LEVEL_UP", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
    "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "ZONE_CHANGED_NEW_AREA", "TAXIMAP_OPENED", "NEW_TAXI_PATH",
    "QUEST_QUERY_COMPLETE", "PLAYER_CONTROL_GAINED",
    "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "HEARTHSTONE_BOUND", "PLAYER_BIND_CHANGED",
    "GOSSIP_SHOW", "QUEST_GREETING", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED",
    "PLAYER_XP_UPDATE", "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_FINISHED", "ENCOUNTER_END", "BOSS_KILL",
    "PLAYER_REGEN_DISABLED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, ...) handle(...) end)
  Q.update()
  if type(GetQuestsCompleted) == "function" then try(QueryQuestsCompleted) end
  ns.questRefresh()
  if type(TakeTaxiNode) == "function" then
    try(hooksecurefunc, "TakeTaxiNode", function(node)
      flight = { to = Q.plain(try(TaxiNodeName, node)), from = flight.origin }
      if recorder then flightTarget = Q.plain(try(TaxiNodeName, node)) end
      if ns.stats then ns.stats.count("flights") end
    end)
  end
  ns.startQuestParty()
  ns.every(0.25, function()
    tickFlight()
    recordFlight()
    followTracker()
    if Q.checkPosition() then ns.questRefresh() else paintArrow(); updateMapPin(); ns.questNextDistances() end
  end)
end

function ns.questDebugLines()
  local groups = {
    { "C_QuestLog", C_QuestLog, "IsQuestFlaggedCompleted", "IsComplete", "GetNumQuestLogEntries", "GetInfo",
      "GetQuestIDForLogIndex", "GetQuestObjectives", "GetMaxNumQuestsCanAccept", "GetAllCompletedQuestIDs" },
    { "Classic quest APIs", _G, "GetNumQuestLogEntries", "GetQuestLogTitle", "GetQuestLogLeaderBoard",
      "IsQuestFlaggedCompleted", "GetQuestsCompleted", "QueryQuestsCompleted" },
    { "C_Map", C_Map, "GetBestMapForUnit", "GetPlayerMapPosition", "GetMapInfo", "GetMapWorldSize", "SetUserWaypoint",
      "GetUserWaypoint", "ClearUserWaypoint", "CanSetUserWaypointOnMap" },
    { "C_SuperTrack", C_SuperTrack, "SetSuperTrackedUserWaypoint" },
    { "TomTom", TomTom, "AddWaypoint" },
    { "Facing", _G, "GetPlayerFacing" },
    { "Death", _G, "UnitIsGhost" },
    { "XP", _G, "UnitXP", "UnitXPMax", "GetXPExhaustion", "GetQuestLogRewardXP" },
    { "Rewards", _G, "GetQuestItemInfo", "GetQuestItemLink", "GetItemInfo" },
    { "C_DeathInfo", C_DeathInfo, "GetCorpseMapPosition" },
    { "Tracker", C_QuestLog, "AddQuestWatch", "RemoveQuestWatch", "GetQuestWatchType" },
    { "Classic tracker and map", _G, "AddQuestWatch", "RemoveQuestWatch", "IsQuestWatched", "OpenWorldMap", "ToggleWorldMap" },
    { "Flights and binds", _G, "UnitOnTaxi", "GetBindLocation", "NumTaxiNodes", "TaxiNodeGetType" },
    { "C_TaxiMap", C_TaxiMap, "GetTaxiNodesForMap", "GetAllTaxiNodes" },
    { "Gossip", C_GossipInfo, "GetAvailableQuests", "GetActiveQuests", "SelectAvailableQuest", "SelectActiveQuest",
      "GetOptions", "SelectOption" },
    { "Travel", _G, "TakeTaxiNode", "GetGossipOptions", "SelectGossipOption" },
    { "Greeting", _G, "GetNumAvailableQuests", "GetNumActiveQuests", "SelectAvailableQuest", "SelectActiveQuest" },
  }
  local lines = { "Quest guide APIs (+: present, -: absent)" }
  for _, group in ipairs(groups) do
    local bits = {}
    for i = 3, #group do
      local key = group[i]
      bits[#bits + 1] = (group[2] and type(group[2][key]) == "function" and "+" or "-") .. key
    end
    lines[#lines + 1] = group[1] .. ": " .. table.concat(bits, " ")
  end
  local frames = {}
  for _, name in ipairs({ "QuestInfoRewardsFrameQuestInfoItem1", "QuestInfoRewardsFrame", "QuestRewardItem1" }) do
    frames[#frames + 1] = (_G[name] and "+" or "-") .. name
  end
  lines[#lines + 1] = "Reward buttons: " .. table.concat(frames, " ")
  local known, probed = Q.flightDebug()
  lines[#lines + 1] = "Known flight paths: " .. known .. (probed and (" (" .. probed .. " from C_TaxiMap)") or " (no C_TaxiMap)")
    .. ". Hearth: " .. Q.plain(Q.bindLocation() or "unknown") .. ". Arrow art: " .. tostring(arrowFile or "text only")
  lines[#lines + 1] = "step sound: " .. (ns.db().questNoSound and "off, " or "") .. "played " .. sounds.n
    .. (sounds.n == 1 and " time" or " times") .. " this session" .. (sounds.last and (", last for " .. sounds.last) or "")
  return lines
end
