-- The on-screen guide, navigation and opt-in recorder.
local _, ns = ...
local Q, A, C = ns.quests, ns.art, ns.C
local try = Q.try
local viewer, arrow, header, title, detail, preview, arrowText, arrowArt, flatBackground, badge, arrowFile
local arrowBearing, arrowCaption, arrowFacing
local dismissed, painting, theme, controllerRequested
local nextButton, pinButton, suggestionButton
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

local function place()
  viewer:ClearAllPoints()
  local p = ns.db().questPosition
  if p then viewer:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  else viewer:SetPoint("RIGHT", UIParent, "RIGHT", -48, 80) end
end

local function font(parent, y, width, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", 16, -y)
  fs:SetWidth(width)
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(true)
  return fs
end

local function pin()
  local row = Q.current()
  local s = row and row.step
  if not (s and s.map and s.x and s.y) then return end
  local point = try(UiMapPoint and UiMapPoint.CreateFromCoordinates, s.map, s.x / 100, s.y / 100)
  if point and C_Map and type(C_Map.SetUserWaypoint) == "function" then
    if pcall(C_Map.SetUserWaypoint, point) then
      try(C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint, true)
      return
    end
  end
  if TomTom and type(TomTom.AddWaypoint) == "function" then
    try(TomTom.AddWaypoint, TomTom, s.map, s.x / 100, s.y / 100,
      { title = s.name or s.text, persistent = false })
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
    updateItemButton()
  end)
  viewer:HookScript("OnHide", function()
    if not painting then dismissed, controllerRequested = true, false end
  end)
  viewer:Hide()
  place()
  flatBackground = viewer:CreateTexture(nil, "BACKGROUND")
  flatBackground:SetAllPoints()
  local _, caption = A.header(viewer, "Quest Guide", 300)
  header = caption
  try(header.SetFont, header, "Fonts\\MORPHEUS.TTF", 14, "")
  badge = viewer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  badge:SetPoint("TOPRIGHT", -16, -30)
  badge:SetText("Unverified")
  title = font(viewer, 28, 318, "GameFontNormal")
  detail = font(viewer, 47, 318)
  preview = font(viewer, 126, 318)

  local buttons = {}
  local function button(label, x, width, action, bottom)
    bottom = bottom or 9
    local b = A.button(viewer, width, 22)
    b:SetPoint("BOTTOMLEFT", x, bottom)
    b:SetLabel(label)
    b.codexLabel = label
    b:SetScript("OnClick", action)
    buttons[#buttons + 1] = { frame = b, x = x + width / 2, y = 179 - bottom, fixed = true }
    return b
  end
  button("Back", 12, 62, function() Q.back(); quiet = true; ns.questRefresh() end)
  nextButton = button("Next", 80, 62, function(_, mouse)
    if mouse == "RightButton" then Q.back() else Q.next() end
    quiet = true
    ns.questRefresh()
  end)
  nextButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  pinButton = button("Pin", 148, 55, pin)
  button("Quests", 209, 70, function() ns.openTab("quests") end)
  button("Hide", 285, 53, function() viewer:Hide() end)
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
  ns.gamepad.attach(viewer, { passive = true, enabled = function() return controllerRequested end,
    focusables = function() return buttons end })

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

local function paintArrow()
  if not viewer or not viewer:IsShown() then return end
  local row = Q.current()
  local goal = row and row.step
  arrowBearing = nil
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
  local bearing, yards = Q.vector(step, map, x, y)
  arrowArt:Hide()
  if yards and yards <= Q.arrived() then
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

function Q.detail(step, requiredFor)
  local _, _, _, level = Q.rows()
  local text = Q.text(step)
  if step.min and level < step.min then text = "Requires level " .. step.min .. ". " .. text end
  if step.type == "complete" then
    local lines = objectiveLines(Q.log(step.quest), false, step.objectiveIndex)
    if #lines == 0 then lines = step.objectives or {} end
    if #lines > 0 then text = text .. "\n" .. table.concat(lines, "  /  ") end
  end
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
      text = "Your quest log is full (" .. count .. "/" .. max .. "). Turn in or abandon a quest first.\n" .. text
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
local function stepItem(step)
  if not step then return end
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
  b:RegisterForClicks("AnyUp", "AnyDown") -- Forever follows retail's key-down setting (as Zygor does)
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

-- The target button (RestedXP's targeting): a secure macro button under the item button that
-- targets the current step's quest giver by name. Same combat rules as the item button.
local targetButton -- false = the client can't make one
local TARGET_TYPES = { accept = true, turnin = true }

local function stepTarget(step)
  if not step or not TARGET_TYPES[step.type] or step.item or step.startItem then return end
  local name = step.npc and Q.plain(step.npc)
  if name and name:find("%a") and not name:find("[\n/;]") then return name end
end

local function targetTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText("Target " .. tostring(self.target))
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
  local name = not ns.db().noQuestTarget and stepTarget(row and row.step)
  if not name then
    if targetButton then targetButton:Hide() end
    return
  end
  if not targetButton then
    makeTargetButton()
    if not targetButton then return end
  end
  targetButton:SetAttribute("type", "macro")
  targetButton:SetAttribute("macrotext", "/targetexact " .. name)
  targetButton.target = name
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
    header:SetText(sec.title .. "  " .. sec.levels[1] .. "-" .. sec.levels[2])
    badge:SetShown(not sec.verified)
    title:SetWidth(sec.verified and 318 or 252)
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
    pinButton:SetShown(row ~= nil)
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
    ns.gamepad.refresh(viewer)
    painting = false
    paintArrow()
  elseif viewer and viewer:IsShown() then
    painting = true
    viewer:Hide()
    painting = false
  end
  updateItemButton()
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
  dismissed, controllerRequested = false, true
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

local function interact(event)
  local id = try(GetQuestID)
  if event == "QUEST_DETAIL" then
    observation("detail", id, { name = Q.plain(try(GetTitleText)), text = Q.plain(try(GetObjectiveText)) })
  end
  local s = Q.autoStep()
  if not id or not s or s.quest ~= id or try(InCombatLockdown) ~= false then return end
  local db = ns.db()
  if event == "QUEST_DETAIL" and s.type == "accept" and db.questAutoAccept then
    try(AcceptQuest)
  elseif s.type == "turnin" and db.questAutoTurnin then
    if event == "QUEST_PROGRESS" and try(IsQuestCompletable) == true then
      try(CompleteQuest)
    elseif event == "QUEST_COMPLETE" and try(GetNumQuestChoices) == 0 and (try(GetQuestMoneyToGet) or 0) == 0 then
      try(GetQuestReward, 0)
    end
  end
end

local function sameTitle(a, b)
  return type(a) == "string" and type(b) == "string" and Q.plain(a):lower() == Q.plain(b):lower()
end

-- Many NPCs open a gossip or greeting list before the quest window. With auto-accept or
-- auto-turn-in on, pick the guide's current quest there (never another; Alt holds it back).
local function pickFromList(event)
  local s = Q.autoStep()
  if not s or not s.quest or try(InCombatLockdown) ~= false or try(IsAltKeyDown) then return end
  local db = ns.db()
  local accept = s.type == "accept" and db.questAutoAccept
  local turnin = s.type == "turnin" and db.questAutoTurnin
  if not accept and not turnin then return end
  if event == "GOSSIP_SHOW" then
    local G = C_GossipInfo
    if type(G) ~= "table" then return end
    local list = try(accept and G.GetAvailableQuests or G.GetActiveQuests)
    for _, q in ipairs(type(list) == "table" and list or {}) do
      if type(q) == "table" and (q.questID == s.quest or sameTitle(q.title, s.name)) then
        try(accept and G.SelectAvailableQuest or G.SelectActiveQuest, q.questID)
        return
      end
    end
    return
  end
  for i = 1, tonumber(try(accept and GetNumAvailableQuests or GetNumActiveQuests)) or 0 do
    local id
    if accept then id = select(5, try(GetAvailableQuestInfo, i)) else id = try(GetActiveQuestID, i) end
    if id == s.quest or sameTitle(try(accept and GetAvailableTitle or GetActiveTitle, i), s.name) then
      try(accept and SelectAvailableQuest or SelectActiveQuest, i)
      return
    end
  end
end

local function handle(event, a, b)
  if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
    interact(event)
    return
  end
  if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then
    pickFromList(event)
    return
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
  if nodes then Q.learnFlights(nodes) end
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

function ns.startQuestGuide()
  for _, ev in ipairs({ "PLAYER_LEVEL_UP", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
    "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "ZONE_CHANGED_NEW_AREA", "TAXIMAP_OPENED", "NEW_TAXI_PATH",
    "QUEST_QUERY_COMPLETE", "PLAYER_CONTROL_GAINED",
    "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "HEARTHSTONE_BOUND", "PLAYER_BIND_CHANGED",
    "GOSSIP_SHOW", "QUEST_GREETING", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED" }) do
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
    if Q.checkPosition() then ns.questRefresh() else paintArrow() end
  end)
end

function ns.questDebugLines()
  local groups = {
    { "C_QuestLog", C_QuestLog, "IsQuestFlaggedCompleted", "IsComplete", "GetNumQuestLogEntries", "GetInfo",
      "GetQuestIDForLogIndex", "GetQuestObjectives", "GetMaxNumQuestsCanAccept", "GetAllCompletedQuestIDs" },
    { "Classic quest APIs", _G, "GetNumQuestLogEntries", "GetQuestLogTitle", "GetQuestLogLeaderBoard",
      "IsQuestFlaggedCompleted", "GetQuestsCompleted", "QueryQuestsCompleted" },
    { "C_Map", C_Map, "GetBestMapForUnit", "GetPlayerMapPosition", "GetMapInfo", "GetMapWorldSize", "SetUserWaypoint" },
    { "C_SuperTrack", C_SuperTrack, "SetSuperTrackedUserWaypoint" },
    { "TomTom", TomTom, "AddWaypoint" },
    { "Facing", _G, "GetPlayerFacing" },
    { "Flights and binds", _G, "UnitOnTaxi", "GetBindLocation", "NumTaxiNodes", "TaxiNodeGetType" },
    { "C_TaxiMap", C_TaxiMap, "GetTaxiNodesForMap", "GetAllTaxiNodes" },
    { "Gossip", C_GossipInfo, "GetAvailableQuests", "GetActiveQuests", "SelectAvailableQuest", "SelectActiveQuest" },
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
  local known, probed = Q.flightDebug()
  lines[#lines + 1] = "Known flight paths: " .. known .. (probed and (" (" .. probed .. " from C_TaxiMap)") or " (no C_TaxiMap)")
    .. ". Hearth: " .. Q.plain(Q.bindLocation() or "unknown") .. ". Arrow art: " .. tostring(arrowFile or "text only")
  return lines
end
