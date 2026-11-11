-- The on-screen guide, navigation and opt-in recorder.
local _, ns = ...
local Q, A, C = ns.quests, ns.art, ns.C
local try = Q.try
local viewer, arrow, header, headerArt, title, detail, preview, arrowText, arrowArt, flatBackground, levels, arrowFile
local arrowBearing, arrowCaption, arrowFacing
local dismissed, painting, theme
local nextButton, suggestionButton
local lastRow, quiet -- the step shown last; quiet = the player moved it (no completion sound)
local announced = {} -- dungeon runs whose "find a group" note was said this session
local itemButton, itemPending, updateItemButton -- itemButton false = the client can't make one
local recorder, objectiveCounts, onTaxi, flightPaths, flightTarget
local events = CreateFrame("Frame")
local ARROW_TEXTURE = "Interface\\AddOns\\LevelingCodex\\media\\quest-arrow.tga"
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

local function makeViewer()
  viewer = A.frame("Frame", "LevelingCodexQuestViewer", UIParent)
  viewer:SetSize(350, 182)
  viewer:SetFrameStrata("MEDIUM")
  viewer:SetMovable(true)
  viewer:SetClampedToScreen(true)
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
  end)
  viewer:Hide()
  place()
  flatBackground = viewer:CreateTexture(nil, "BACKGROUND")
  flatBackground:SetAllPoints()
  headerArt, header = A.header(viewer, "Quest Guide", 300)
  try(header.SetWordWrap, header, false)
  levels = viewer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  levels:SetPoint("TOPRIGHT", -16, -30)
  title = font(viewer, 28, 318, "GameFontNormal")
  detail = font(viewer, 47, 318)
  preview = font(viewer, 126, 318)

  local function button(label, x, width, action, bottom)
    bottom = bottom or 9
    local b = A.button(viewer, width, 22)
    b:SetPoint("BOTTOMLEFT", x, bottom)
    b:SetLabel(label)
    b.codexLabel = label
    b:SetScript("OnClick", action)
    return b
  end
  -- Keep controller focus in the Quests tab so the overlay can stay up during gameplay.
  button("Back", 12, 72, function() ns.moveQuestStep(true) end)
  nextButton = button("Next", 92, 72, function(_, mouse)
    ns.moveQuestStep(mouse == "RightButton")
  end)
  nextButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button("Quests", 172, 86, function() ns.openTab("quests") end)
  button("Hide", 266, 72, ns.hideQuestViewer)
  suggestionButton = button("", 16, 318, function()
    local row = Q.current()
    if row and row.section.side then
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
      elseif related then ns.openQuestGuide(related) else ns.followSuggestedQuestSection(suggestion) end
    end
  end, 35)

  -- No box: a rotating arrow over the world with the distance under it, like the game's own pointers.
  arrow = CreateFrame("Frame", "LevelingCodexQuestArrow", viewer)
  arrow:SetSize(320, 70)
  arrow:SetPoint("BOTTOM", viewer, "TOP", 0, 6)
  arrowArt = arrow:CreateTexture(nil, "ARTWORK")
  arrowArt:SetSize(48, 48)
  arrowArt:SetPoint("TOP", 0, 0)
  if A.hasFile(ARROW_TEXTURE) then arrowFile = ARROW_TEXTURE; arrowArt:SetTexture(arrowFile) end
  arrowText = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  arrowText:SetPoint("BOTTOM", 0, 0)
  arrowText:SetWidth(320)
  arrowText:SetJustifyH("CENTER")
  arrowText:SetWordWrap(true)
  try(arrowText.SetShadowColor, arrowText, 0, 0, 0, 1)
  try(arrowText.SetShadowOffset, arrowText, 1, -1)
  arrow:SetScript("OnUpdate", turnArrow)
end

-- As a ghost the arrow leads back to your corpse instead of the step.
local function paintCorpse(corpse)
  arrow:Show()
  arrowArt:Hide()
  local map, x, y = Q.position()
  local bearing, yards = Q.vector(corpse, map, x, y)
  if yards and yards <= Q.arrived() then
    arrowText:SetText("Your corpse is here")
  elseif bearing then
    arrowBearing, arrowCaption, arrowFacing = bearing, "Your corpse - " .. math.floor(yards + 0.5) .. " yd", false
    turnArrow()
  else
    arrowText:SetText("Return to your corpse")
  end
end

local function paintArrow()
  if not viewer or not viewer:IsShown() then return end
  local row = Q.current()
  local goal = row and row.step
  arrowBearing = nil
  local corpse = not ns.db().noQuestArrow and Q.corpse()
  if corpse then
    paintCorpse(corpse)
    return
  end
  if ns.db().noQuestArrow or not goal then
    arrow:Hide()
    return
  end
  if Q.inFlight() then
    arrow:Show()
    arrowArt:Hide()
    arrowText:SetText("In flight")
    return
  end
  if not goal.map or not goal.x then
    arrow:Hide()
    return
  end
  arrow:Show()
  local map, x, y = Q.position()
  local step, travel = Q.destination(goal, map)
  local spawn, spawnName
  if step == goal then spawn, spawnName = ns.questie.nearest(goal, map, x, y) end
  local bearing, yards = Q.vector(spawn or step, map, x, y)
  arrowArt:Hide()
  if spawn and yards and yards <= Q.arrived() then
    arrowText:SetText(spawnName .. " nearby")
  elseif spawn and bearing then
    arrowBearing, arrowCaption, arrowFacing = bearing, spawnName .. " - " .. math.floor(yards + 0.5) .. " yd", false
    turnArrow()
  elseif yards and yards <= Q.arrived() then
    arrowText:SetText(travel or "Arrived")
  elseif bearing then
    arrowBearing, arrowCaption, arrowFacing = bearing, travel or (yards and (math.floor(yards + 0.5) .. " yd") or ""), false
    turnArrow()
  else
    arrowText:SetText(travel or (x and "Map scale unavailable" or "Position unavailable"))
  end
end

local ACTION = { accept = "Accept", complete = "Complete", turnin = "Turn in", ["goto"] = "Travel",
  fly = "Fly", getfp = "Flight path", sethearth = "Bind hearthstone", hearth = "Hearth",
  boat = "Boat", train = "Train", buy = "Buy", use = "Use", grind = "Level up", dungeon = "Dungeon", note = "Note" }

function Q.label(step)
  if step.type == "hearth" and step.bind then return "Return to " .. step.bind end
  local verb = ACTION[step.type]
  local name = step.name or step.flight
  return name and (verb .. " - " .. name) or verb
end

local function objectiveLines(entry, incompleteOnly, index)
  local lines = {}
  for i, obj in ipairs(entry and entry.objectives or {}) do
    if (not index or i == index) and type(obj.text) == "string" and
        (not incompleteOnly or (obj.finished ~= true and obj.finished ~= 1)) then
      lines[#lines + 1] = Q.plain(obj.text)
    end
  end
  return lines
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
  if not cur then return "" end
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
  return "\n" .. table.concat(lines, "\n")
end

function Q.detail(step, requiredFor)
  local _, _, _, level = Q.rows()
  local text = Q.text(step)
  if step.min and level < step.min then text = "Requires level " .. step.min .. ". " .. text end
  if step.type == "complete" then
    local lines = objectiveLines(Q.log(step.quest), false, step.objectiveIndex)
    if #lines == 0 then lines = step.objectives or {} end
    if #lines > 0 then text = text .. "\n" .. table.concat(lines, "  /  ") end
  end
  if step.type == "grind" and step.level then text = text .. grindLines(step, level) end
  local also = {}
  for _, id in ipairs(step.also or {}) do
    local entry = Q.incomplete(id)
    if entry and entry.title then
      local lines = objectiveLines(entry, true)
      also[#also + 1] = entry.title .. (#lines > 0 and (" - " .. table.concat(lines, "  /  ")) or "")
    end
  end
  if #also > 0 then text = text .. "\nAlso on this loop\n" .. table.concat(also, "\n") end
  local part, length, run = Q.chainInfo(step.quest)
  if part then
    text = text .. "\nChain: part " .. part .. " of " .. length .. (run and (", leads to " .. run.title) or "") .. "."
  end
  if step.type == "accept" and not Q.log(step.quest) then
    local count, max = Q.logCapacity()
    if max and count >= max then
      text = "Your quest log is full (" .. count .. "/" .. max .. "). Turn in or abandon a quest first:"
        .. " Quests > Guide library lists ones you can drop.\n" .. text
    end
  end
  if requiredFor then text = "Required for " .. requiredFor.name .. ".\n" .. text end
  if step.uncertain then text = text .. "\nCheck in game: " .. step.uncertain end
  return Q.plain(text)
end

-- A step the game finished (not Next/Back or a jump) plays the map ping, like a quest objective.
local function completionSound(row)
  local done = lastRow and row ~= lastRow and not quiet and lastRow.state == "done"
  lastRow, quiet = row, false
  if done and not ns.db().questNoSound and type(PlaySound) == "function" then
    pcall(PlaySound, SOUNDKIT and SOUNDKIT.MAP_PING or 3175)
  end
end

-- The use-item button: a secure button beside the step window that uses the current
-- step's quest item (the quest log's own usable item, else the step's `item`, an ID or
-- a name). Secure frames can't change in combat, so changes wait for PLAYER_REGEN_ENABLED.
-- A hearth step offers the Hearthstone, but only when it is set to the step's town.
local HEARTHSTONE = 6948
local function stepItem(step)
  if not step then return end
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
local TARGET_TYPES = { accept = true, turnin = true }
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
    targetButton:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left - 10, top - 72)
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
    itemButton:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left - 6, top - 26)
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

local function updateMapPin()
  local M = C_Map
  if type(M) ~= "table" or type(M.SetUserWaypoint) ~= "function" then return end
  local row = viewer and viewer:IsShown() and Q.current()
  local step = row and row.step
  local want = not ns.db().noQuestMapPin and step and step.map and step.x and step.y
  local map, x, y = userWaypoint()
  local ours = pinned and map and samePoint(pinned, map, x, y)
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

local function previewText(row, i)
  local upcoming = Q.upcoming(i)
  local nextRow = upcoming[1]
  if not nextRow then
    if not row.section.side and Q.autoStep() == row.step then
      return row.section.alternate and "Last step in this alternate route." or "Last step in this guide."
    end
    return ""
  end
  local heading = nextRow.section == row.section and "Next: " or ("Next section: " .. nextRow.section.title .. "\n")
  local text = heading .. Q.label(nextRow.step)
  local second = upcoming[2]
  if second and second.section == nextRow.section then text = text .. "\n" .. Q.label(second.step) end
  return text
end

local function pinnedText()
  local lines = {}
  for _, id in ipairs(Q.pins()) do
    local entry = Q.incomplete(id)
    local goals = objectiveLines(entry, true)
    local name = entry.title or ("Quest " .. id)
    lines[#lines + 1] = name .. (#goals > 0 and " - " .. table.concat(goals, " / ") or "")
  end
  return #lines > 0 and Q.plain("Tracking\n" .. table.concat(lines, "\n")) or ""
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
      title:SetTextColor(ns.rgba(C.gold))
      detail:SetTextColor(ns.rgba(backdrop and C.light or C.ink))
      preview:SetTextColor(ns.rgba(backdrop and C.dim or C.inkSoft))
      theme = ns.themeVersion
    end
    fitHeader(sec.title:match("^([^:]+):") or sec.title)
    levels:SetText("Levels " .. sec.levels[1] .. "-" .. sec.levels[2])
    title:SetWidth(318 - math.ceil(tonumber(try(levels.GetStringWidth, levels)) or 70) - 10)
    if row then
      title:SetText(Q.label(row.step))
      detail:SetText(Q.detail(row.step, row.requiredFor))
    else
      title:SetText(sec.alternate and "End of the alternate route" or "End of the leveling guide")
      detail:SetText(suggestion and "Try the suggested section below, or open Quests to choose another."
        or "Open Quests to revisit a section or check for missed quests.")
    end
    -- Stack title, detail and preview by their real heights so long lines never overlap.
    local detailY = 28 + math.max(14, title:GetStringHeight()) + 5
    detail:ClearAllPoints()
    detail:SetPoint("TOPLEFT", 16, -detailY)
    local previewLines = row and previewText(row, i) or ""
    local tracked = pinnedText()
    if tracked ~= "" then previewLines = previewLines ~= "" and (previewLines .. "\n\n" .. tracked) or tracked end
    preview:SetText(previewLines)
    local previewY = detailY + detail:GetStringHeight() + 8
    preview:ClearAllPoints()
    preview:SetPoint("TOPLEFT", 16, -previewY)
    nextButton:SetShown(row ~= nil)
    local returnToRoute = sec.side
    local run, runCount = Q.readyRun()
    if run and not announced[run.id] then
      announced[run.id] = true
      ns.say(Q.plain(run.title .. ": " .. runCount .. " of its quests are in your log. Find a group, then use Run "
        .. run.title .. " in the step window for the checklist."))
    end
    local related = Q.relatedGuide()
    local offer = returnToRoute or run or suggestion or related
    suggestionButton:SetShown(offer ~= nil and offer ~= false)
    if offer then
      suggestionButton.codexLabel = returnToRoute and "Return to leveling" or run and ("Run " .. run.title)
        or (suggestion and "Try " .. suggestion.title or "Plan " .. related.title)
      suggestionButton:SetLabel(suggestionButton.codexLabel)
    end
    viewer:SetHeight(math.max(140, previewY + preview:GetStringHeight() + (offer and 64 or 38)))
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
  ns.refreshQuestTab()
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

-- Travel automation (Settings > Take the guide's flights and binds, off by default): the
-- flight master's and innkeeper's gossip options, the step's flight and the bind confirmation.
-- Alt holds it back, and nothing happens in combat.
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
  if Q.flightStep() or (s and s.type == "getfp") then
    pickGossip("taxi")
  elseif s and s.type == "sethearth" and nearStep(s) then
    pickGossip("binder")
  end
end

local function takeFlight()
  local fly = travelAllowed() and Q.flightStep()
  if not fly then return end
  local want = Q.plain(fly.flight):lower()
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

local function confirmBind(area)
  local s = Q.autoStep()
  if not travelAllowed() or not s or s.type ~= "sethearth" or not nearStep(s) then return end
  if type(area) == "string" and area ~= "" and s.bind and Q.plain(area):lower() ~= s.bind:lower() then return end
  if type(ConfirmBinder) == "function" then
    try(ConfirmBinder)
  else
    local manager, kinds = C_PlayerInteractionManager, Enum and Enum.PlayerInteractionType
    if not (manager and kinds and kinds.Binder) then return end
    try(manager.ConfirmationInteraction, kinds.Binder)
    try(manager.ClearInteraction, kinds.Binder)
  end
  try(StaticPopup_Hide, "CONFIRM_BINDER")
end

local function handle(event, a, b)
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
  if event == "CONFIRM_BINDER" then
    confirmBind(a)
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
    Q.learnFlights(nodes)
    takeFlight()
  end
  if event == "HEARTHSTONE_BOUND" or event == "PLAYER_BIND_CHANGED" then
    Q.acknowledge("sethearth", function(step)
      local _, distance = Q.vector(step, Q.position())
      return distance and distance <= Q.arrived()
    end)
  end
  if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then Q.checkPosition() end
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
    "GOSSIP_SHOW", "QUEST_GREETING", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED", "CONFIRM_BINDER",
    "PLAYER_XP_UPDATE", "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_FINISHED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, ...) handle(...) end)
  Q.update()
  if type(GetQuestsCompleted) == "function" then try(QueryQuestsCompleted) end
  ns.questRefresh()
  if type(TakeTaxiNode) == "function" then
    try(hooksecurefunc, "TakeTaxiNode", function(node)
      if recorder then flightTarget = Q.plain(try(TaxiNodeName, node)) end
    end)
  end
  ns.every(0.25, function()
    recordFlight()
    followTracker()
    if Q.checkPosition() then ns.questRefresh() else paintArrow() end
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
    { "Flights and binds", _G, "UnitOnTaxi", "GetBindLocation", "NumTaxiNodes", "TaxiNodeGetType" },
    { "C_TaxiMap", C_TaxiMap, "GetTaxiNodesForMap", "GetAllTaxiNodes" },
    { "Gossip", C_GossipInfo, "GetAvailableQuests", "GetActiveQuests", "SelectAvailableQuest", "SelectActiveQuest",
      "GetOptions", "SelectOption" },
    { "Travel", _G, "TakeTaxiNode", "GetGossipOptions", "SelectGossipOption", "ConfirmBinder", "StaticPopup_Hide" },
    { "C_PlayerInteractionManager", C_PlayerInteractionManager, "ConfirmationInteraction", "ClearInteraction" },
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
  return lines
end
