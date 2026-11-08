-- The on-screen guide, navigation and opt-in recorder.
local _, ns = ...
local Q, A, C = ns.quests, ns.art, ns.C
local try = Q.try
local viewer, arrow, header, title, detail, preview, arrowText, arrowArt, flatBackground
local dismissed, painting, theme, controllerRequested
local recorder, objectiveCounts, onTaxi, flightPaths, flightTarget
local events = CreateFrame("Frame")
local ARROW_TEXTURE = "Interface\\AddOns\\LevelingCodex\\media\\quest-arrow.tga"
local COMPASS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

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
  title = font(viewer, 28, 318, "GameFontNormal")
  detail = font(viewer, 47, 318)
  preview = font(viewer, 126, 318)

  local buttons = {}
  local function button(label, x, width, action)
    local b = A.button(viewer, width, 22)
    b:SetPoint("BOTTOMLEFT", x, 9)
    b:SetLabel(label)
    b.codexLabel = label
    b:SetScript("OnClick", action)
    buttons[#buttons + 1] = { frame = b, x = x + width / 2, y = 170, fixed = true }
    return b
  end
  button("Back", 12, 62, function() Q.back(); ns.questRefresh() end)
  local nextButton = button("Next", 80, 62, function(_, mouse)
    if mouse == "RightButton" then Q.back() else Q.next() end
    ns.questRefresh()
  end)
  nextButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button("Pin", 148, 55, pin)
  button("Quests", 209, 70, function() ns.openTab("quests") end)
  button("Hide", 285, 53, function() viewer:Hide() end)
  ns.gamepad.attach(viewer, { passive = true, enabled = function() return controllerRequested end,
    focusables = function() return buttons end })

  arrow = A.frame("Frame", "LevelingCodexQuestArrow", viewer)
  arrow:SetSize(140, 38)
  arrow:SetPoint("BOTTOM", viewer, "TOP", 0, 9)
  A.backdrop(arrow, "tooltip", C.parch, C.edge)
  arrowArt = arrow:CreateTexture(nil, "ARTWORK")
  arrowArt:SetSize(29, 29)
  arrowArt:SetPoint("LEFT", 8, 0)
  if A.hasFile(ARROW_TEXTURE) then arrowArt:SetTexture(ARROW_TEXTURE) end
  arrowText = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  arrowText:SetPoint("CENTER", 12, 0)
end

local function paintArrow()
  if not viewer or not viewer:IsShown() then return end
  local row, i = Q.current()
  local map, x, y = Q.position()
  local step = Q.destination(row, i, map)
  if ns.db().noQuestArrow or not step or not step.map or not step.x then
    arrow:Hide()
    return
  end
  arrow:Show()
  local bearing, yards = Q.vector(step, map, x, y)
  local facing = try(GetPlayerFacing)
  arrowArt:Hide()
  if yards and yards <= Q.arrived() then
    arrowText:SetText("Arrived")
  elseif bearing then
    local label = COMPASS[(math.floor(bearing / (math.pi / 4) + 0.5) % 8) + 1]
    local rotated = type(facing) == "number" and A.hasFile(ARROW_TEXTURE)
      and type(arrowArt.SetRotation) == "function" and pcall(arrowArt.SetRotation, arrowArt, -bearing - facing)
    if rotated then arrowArt:Show() end
    local distance = yards and (math.floor(yards + 0.5) .. " yd") or ""
    arrowText:SetText(rotated and distance or (label .. (yards and ", " .. distance or "")))
  else
    arrowText:SetText(map and map ~= step.map and "Other zone" or "Position unavailable")
  end
end

local ACTION = { accept = "Accept", complete = "Complete", turnin = "Turn in", ["goto"] = "Travel",
  fly = "Fly", getfp = "Flight path", sethearth = "Bind hearthstone", hearth = "Hearth",
  boat = "Boat", train = "Train", buy = "Buy", use = "Use", grind = "Level up", dungeon = "Dungeon", note = "Note" }

function Q.label(step)
  local verb = ACTION[step.type]
  local name = step.name or step.flight
  return name and (verb .. " - " .. name) or verb
end

function ns.questRefresh()
  local row, i = Q.current()
  if not dismissed and row then
    painting = true
    if not viewer then makeViewer() end
    if theme ~= ns.themeVersion then
      local backdrop = A.backdrop(viewer, "dialog", C.parch, C.edge)
      flatBackground:SetColorTexture(ns.rgba(C.parch))
      flatBackground:SetShown(not backdrop)
      title:SetTextColor(ns.rgba(C.gold))
      detail:SetTextColor(ns.rgba(C.ink))
      preview:SetTextColor(ns.rgba(C.dim))
      theme = ns.themeVersion
    end
    local s, sec = row.step, row.section
    header:SetText(sec.title .. "  " .. sec.levels[1] .. "-" .. sec.levels[2] ..
      (sec.verified and "" or "  (Unverified)"))
    title:SetText(Q.label(s))
    local _, _, _, level = Q.rows()
    local text = Q.text(s)
    if s.min and level < s.min then text = "Requires level " .. s.min .. ". " .. text end
    local entry = s.quest and Q.log(s.quest)
    if s.type == "complete" then
      local lines = {}
      for _, obj in ipairs(entry and entry.objectives or {}) do
        if type(obj.text) == "string" then lines[#lines + 1] = Q.plain(obj.text) end
      end
      if #lines == 0 then lines = s.objectives or {} end
      if #lines > 0 then text = text .. "\n" .. table.concat(lines, "  /  ") end
    end
    detail:SetText(Q.plain(text))
    local nextLabels = {}
    for _, nextRow in ipairs(Q.upcoming(i)) do nextLabels[#nextLabels + 1] = Q.label(nextRow.step) end
    preview:SetText(#nextLabels > 0 and ("Next: " .. table.concat(nextLabels, "\n")) or "")
    local previewY = 55 + detail:GetStringHeight()
    preview:ClearAllPoints()
    preview:SetPoint("TOPLEFT", 16, -previewY)
    viewer:SetHeight(math.max(140, previewY + preview:GetStringHeight() + 38))
    viewer:Show()
    ns.gamepad.refresh(viewer)
    painting = false
    paintArrow()
  elseif viewer and viewer:IsShown() then
    painting = true
    viewer:Hide()
    painting = false
  end
  ns.refreshQuestTab()
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

local function handle(event, a, b)
  if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
    interact(event)
    return
  end
  local id = event == "QUEST_ACCEPTED" and (tonumber(b) or tonumber(a)) or tonumber(a)
  local old = id and Q.log(id)
  Q.update(event, id, event == "PLAYER_LEVEL_UP" and id or nil)
  local nodes = event == "TAXIMAP_OPENED" and taxiSnapshot()
  if nodes then Q.acknowledge("getfp", function(step) return nodes[step.flight] == "CURRENT" end) end
  if event == "HEARTHSTONE_BOUND" or event == "PLAYER_BIND_CHANGED" then
    Q.acknowledge("sethearth", function(step)
      local _, distance = Q.vector(step, Q.position())
      return distance and distance <= Q.arrived()
    end)
  end
  if event == "ZONE_CHANGED_NEW_AREA" then
    Q.acknowledge("hearth", function(step)
      local _, distance = Q.vector(step, Q.position())
      return distance and distance <= Q.arrived()
    end)
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

function ns.startQuestGuide()
  for _, ev in ipairs({ "PLAYER_LEVEL_UP", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
    "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "TAXIMAP_OPENED", "NEW_TAXI_PATH",
    "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "HEARTHSTONE_BOUND", "PLAYER_BIND_CHANGED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, ...) handle(...) end)
  Q.update()
  ns.questRefresh()
  if type(TakeTaxiNode) == "function" then
    try(hooksecurefunc, "TakeTaxiNode", function(node)
      if recorder then flightTarget = Q.plain(try(TaxiNodeName, node)) end
    end)
  end
  ns.every(0.25, function()
    recordFlight()
    if Q.checkArrival() then ns.questRefresh() else paintArrow() end
  end)
end

function ns.questDebugLines()
  local groups = {
    { "C_QuestLog", C_QuestLog, "IsQuestFlaggedCompleted", "GetNumQuestLogEntries", "GetInfo",
      "GetQuestIDForLogIndex", "GetQuestObjectives", "GetMaxNumQuestsCanAccept" },
    { "Classic quest APIs", _G, "GetNumQuestLogEntries", "GetQuestLogTitle", "GetQuestLogLeaderBoard",
      "IsQuestFlaggedCompleted", "GetQuestsCompleted" },
    { "C_Map", C_Map, "GetBestMapForUnit", "GetPlayerMapPosition", "SetUserWaypoint" },
    { "C_SuperTrack", C_SuperTrack, "SetSuperTrackedUserWaypoint" },
    { "TomTom", TomTom, "AddWaypoint" },
    { "Facing", _G, "GetPlayerFacing" },
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
  return lines
end
