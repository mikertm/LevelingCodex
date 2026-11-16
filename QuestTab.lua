-- QuestTab.lua: a journey board with an area path and one selected quest panel.
-- The rail opens paged route and dungeon tiles, focused quest-log categories,
-- party panels and option groups. The full itinerary is never drawn on Journey.
local _, ns = ...
local Q, U, C = ns.quests, ns.ui, ns.C
local W = U.W
local sub, allSteps = "route", false -- this session's page and area-card finished-step filter
local librarySection, query, draft = nil, "", ""
local guideView = "level"
local board = { expanded = false, stepPage = 1, routePage = 1, dungeonPage = 1 }

local STATUS = { pending = "To do", done = "Done", deferred = "Earlier", skipped = "Skipped", blocked = "Blocked" }
local GUIDE_TAG = { current = "Current", done = "Done", outleveled = "Outleveled", suggested = "Suggested", later = "Later" }
-- Leveling guides are listed by the band their first level falls in.
local BANDS = { { 1, 11, "LEVELS 1-12: STARTING ZONES" }, { 12, 19, "LEVELS 12-20" }, { 20, 29, "LEVELS 20-30" },
  { 30, 39, "LEVELS 30-40" }, { 40, 49, "LEVELS 40-50" }, { 50, 60, "LEVELS 50-60" } }

-- Text accompanies every colour: plans, previews and the guide being followed are different states.
local function badge(text, x, y, w, color, paper)
  color = color or C.accent
  -- Overlay textures stay above a parchment card even when its height is calculated afterward.
  local edge = paper and C.btnOn or color
  U.rect(x, y, w, 20, paper and C.btnOn or C.panel, "border")
  U.rect(x, y, w, 1, edge, "border", 1)
  U.rect(x, y + 19, w, 1, edge, "border", 1)
  U.rect(x, y, 1, 20, edge, "border", 1)
  U.rect(x + w - 1, y, 1, 20, edge, "border", 1)
  U.T(text, x + 4, y + 4, w - 8, "small", paper and C.btnOnInk or color, "CENTER")
end

local function guideStyle(section)
  if section.category == "dungeon" then return "Dungeon", "Interface\\Icons\\INV_Misc_Head_Dragon_01", { 0.75, 0.65, 1 } end
  if section.category == "special" then return "Special chain", "Interface\\Icons\\INV_Misc_Key_14", C.gold end
  if section.class or section.side then return "Class quest", "Interface\\Icons\\INV_Misc_Book_11", C.green end
  return section.alternate and "Alternate route" or "Leveling route", "Interface\\Icons\\INV_Misc_Map_01", C.accent
end

local function areaName(map, section)
  local info = map and Q.try(C_Map and C_Map.GetMapInfo, map)
  if type(info) == "table" and info.name then return Q.plain(info.name) end
  local _, sections = Q.rows()
  for _, candidate in ipairs(sections) do
    if map and candidate.zone == map and not candidate.category and not candidate.side and not candidate.manual then
      return Q.plain(candidate.title)
    end
  end
  return Q.plain(section.title)
end

-- Decorative art is a texture: a row has one hit target and one controller focus stop.
local function glyph(file, x, y, size)
  local texture = U.rect(x, y, size, size, C.accent, "border", 3, "questIcon")
  -- These are complete paths (including GossipFrame/Cursor art), not icon names.
  if texture:SetTexture(file) == false then texture:SetTexture(ns.QUESTION_ICON) end
  texture:SetTexCoord(0, 1, 0, 1)
  texture:SetVertexColor(1, 1, 1)
end

-- Use the client's map layer, assembled in the same row-major order as its
-- world map. Clip each tile's coordinates instead of opening/changing that map.
-- Dedicated pools keep these images clear of gradients left on colour textures.
local function mapPreview(map, x, y, w, h)
  if not map then return false end
  local layers = Q.try(C_Map and C_Map.GetMapArtLayers, map)
  local files = Q.try(C_Map and C_Map.GetMapArtLayerTextures, map, 1)
  local layer = type(layers) == "table" and layers[1]
  if type(layer) ~= "table" or type(files) ~= "table" then return false end
  local lw, lh = tonumber(layer.layerWidth), tonumber(layer.layerHeight)
  local tw, th = tonumber(layer.tileWidth), tonumber(layer.tileHeight)
  if not (lw and lh and tw and th) or lw <= 0 or lh <= 0 or tw <= 0 or th <= 0 then return false end
  local cols, rows = math.ceil(lw / tw), math.ceil(lh / th)
  if cols * rows > 64 then return false end
  for i = 1, cols * rows do
    if not files[i] or not ns.art.hasFile(files[i]) then return false end
  end
  local scale = math.max(w / lw, h / lh)
  local left, top = (lw - w / scale) / 2, (lh - h / scale) / 2
  local right, bottom = left + w / scale, top + h / scale
  local function tile(file, tx, ty, pw, ph, fw, fh, sublevel)
    local l, t = math.max(tx, left), math.max(ty, top)
    local r, b = math.min(tx + pw, right, lw), math.min(ty + ph, bottom, lh)
    if r <= l or b <= t or not file or not ns.art.hasFile(file) then return end
    local texture = U.rect(x + (l - left) * scale, y + (t - top) * scale,
      (r - l) * scale, (b - t) * scale, C.panel, "border", sublevel, "questMapTile")
    if texture:SetTexture(file) == false then texture:Hide()
    else
      texture:SetTexCoord((l - tx) / fw, (r - tx) / fw, (t - ty) / fh, (b - ty) / fh)
      texture:SetVertexColor(1, 1, 1, 1)
    end
  end
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      tile(files[row * cols + col + 1], col * tw, row * th, tw, th, tw, th, -3)
    end
  end
  -- Classic terrain is painted over the unexplored base map. Edge overlay
  -- files have power-of-two padding, which must not appear in the preview.
  local explored = Q.try(C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures, map)
  local function padded(n)
    local size = 16
    while size < n do size = size * 2 end
    return size
  end
  for _, region in ipairs(type(explored) == "table" and explored or {}) do
    local rw, rh = tonumber(region.textureWidth), tonumber(region.textureHeight)
    local ox, oy = tonumber(region.offsetX), tonumber(region.offsetY)
    if rw and rh and ox and oy and rw > 0 and rh > 0 and type(region.fileDataIDs) == "table"
      and not region.isShownByMouseOver then
      local nc, nr = math.ceil(rw / tw), math.ceil(rh / th)
      if nc * nr <= 64 then
        for row = 0, nr - 1 do
          for col = 0, nc - 1 do
            local pw, ph = math.min(tw, rw - col * tw), math.min(th, rh - row * th)
            tile(region.fileDataIDs[row * nc + col + 1], ox + col * tw, oy + row * th,
              pw, ph, col == nc - 1 and padded(pw) or tw, row == nr - 1 and padded(ph) or th, -2)
          end
        end
      end
    end
  end
  return true
end

local function areaThumbnail(map, x, y, w, h, selected)
  U.rect(x, y, w, h, C.parch, "border", -4)
  if not mapPreview(map, x + 2, y + 2, w - 4, h - 4) then
    U.T("Map unavailable", x + 5, y + 10, w - 10, "small", C.ink, "CENTER")
  end
  local edge, n = selected and C.accent or C.edgeSoft, selected and 2 or 1
  U.rect(x, y, w, n, edge, "border", -1)
  U.rect(x, y + h - n, w, n, edge, "border", -1)
  U.rect(x, y, n, h, edge, "border", -1)
  U.rect(x + w - n, y, n, h, edge, "border", -1)
end

local function paceName()
  local db = ns.db()
  if db.questKeepGrey and db.questOptional then return "Every quest" end
  if not db.questKeepGrey and not db.questOptional then return "Fastest" end
  return "Custom"
end

local function sectionInfo(section)
  return (section.category == "dungeon" and "Suggested levels " or "Levels ") .. section.levels[1] .. "-" .. section.levels[2]
end

local function runInfo(section)
  if not Q.planned(section.id) then return "Not planned" end
  local inLog, left = Q.runReadiness(section)
  return "Planned  |  " .. inLog .. " in log" .. (left > 0 and (", " .. left .. " to pick up") or "")
end

local function setPlans(list, on)
  for _, section in ipairs(Q.dungeons()) do Q.setPlanned(section.id, false) end
  for _, section in ipairs(list or {}) do Q.setPlanned(section.id, on) end
  ns.updateQuestSettings()
end

-- Which dungeon plan the setup lights: "all" (Plan every dungeon run, or every run planned),
-- "none", "recommended" (exactly Q.recommendedRuns()) or "picks", with the planned count. Only
-- runs you haven't outleveled count, as for the recommended ones, so Recommended stays lit as
-- you level past some of its runs.
local function dungeonState()
  local _, _, _, lvl = Q.rows()
  local all, planned, set, every = Q.dungeons(), 0, {}, true
  for _, section in ipairs(all) do
    local on = Q.planned(section.id)
    if not on then every = false end
    if on and (lvl or 1) <= section.levels[2] then planned, set[section.id] = planned + 1, true end
  end
  if ns.db().questDungeons or (#all > 0 and every) then return "all", planned end
  if planned == 0 then return "none", 0 end
  local recommended = Q.recommendedRuns()
  local same = #recommended == planned
  for _, section in ipairs(recommended) do if not set[section.id] then same = false end end
  return same and "recommended" or "picks", planned
end

-- The dungeon choices: Recommended, All, None (the setup card and Guides > Dungeons).
local DUNGEON_TIPS = { "Runs near your route or tied to your class quests: their pickups join your route.",
  "Plan every dungeon run: all their pickups join your route.",
  "Leave dungeon pickups out. Quests > Guides > Dungeons plans runs one by one." }
local function pickDungeons(i)
  local db = ns.db()
  if i == 1 then db.questDungeons = false; setPlans(Q.recommendedRuns(), true)
  elseif i == 2 then db.questDungeons = true; setPlans(Q.dungeons(), true)
  elseif i == 3 then db.questDungeons = false; setPlans(nil)
  else U.refresh() end
end
local function dungeonChoices(x, y, w)
  local state, planned = dungeonState()
  local labels, tips = { "Recommended", "All", "None" }, { DUNGEON_TIPS[1], DUNGEON_TIPS[2], DUNGEON_TIPS[3] }
  local lit = ({ recommended = 1, all = 2, none = 3 })[state]
  if state == "picks" then
    labels[4], tips[4], lit = "Your picks (" .. planned .. ")", "The runs you planned one by one.", 4
  end
  return U.segments(x, y, w, labels, lit, pickDungeons, tips)
end

local function show(key)
  sub = key
  U.refreshTop()
end

-- A guide's page (Guides), where Start this route switches to it: clicking a guide never switches
-- by itself. `from` = the sub-tab its Back button returns to ("route" for Other routes).
local pageFrom
-- The step buttons (Previous / Next / Show on map / Hide step window), one row at y inside the
-- step card (x 16 to W - 16), or on their own when there is no step.
local function stepButtons(current, x, y, w)
  local each = (w - 24) / 4
  U.btn("Previous step", x, y, each, function() ns.moveQuestStep(true) end)
  -- On a Dungeon ahead step, Next leaves the run out, so it says Skip (like the step window's).
  local choosing = current and current.step.type == "plan"
  local eliteAsk = current and current.step.type == "elite"
  U.btn(choosing and "Skip run" or eliteAsk and "Skip" or "Next step", x + each + 8, y, each,
    function() ns.moveQuestStep(false) end, false,
    choosing and "The run stays out of your route. Guides > Dungeons can plan it later."
    or eliteAsk and "The guide passes this elite quest and the quests that need it." or nil)
  U.btn("Show on map", x + 2 * (each + 8), y, each, ns.showQuestStepOnMap, false,
    "Open the world map where the current step is.")
  local viewer = _G.LevelingCodexQuestViewer
  local shown = viewer and viewer:IsShown()
  U.btn(shown and "Hide step window" or "Show step window", x + 3 * (each + 8), y, each, function()
    if shown then ns.hideQuestViewer() else ns.showQuestViewer() end
    U.refresh()
  end, false, "Show or hide the quest step and arrow while you play.")
  return 22
end

-- The current step's card: the guide and its progress on top, the step, what to do (smaller), and
-- the step buttons along the bottom.
local function stepCard(row, y)
  local top = y
  y = y + 12
  local label = Q.autoStep() and "CURRENT STEP" or "STEP PREVIEW"
  local heading = U.T(label, 16, y, 128, "label", C.inkSoft)
  local passed, total = Q.stepProgress(row.section)
  local bar = total > 0 and not ns.db().noStepBar
  local guide = Q.plain(row.section.title) .. (bar and ("  -  " .. math.floor(passed * 100 / total) .. "%") or "")
  local section = U.T(guide, 148, y, W - 164, "small", C.inkSoft, "RIGHT")
  y = y + math.max(heading, section) + 2
  if bar then
    -- a thin bar under the heading row: how far into this guide you are
    U.rect(16, y + 2, W - 32, 3, C.edgeSoft)
    if passed > 0 then U.rect(16, y + 2, math.max(1, math.floor((W - 32) * passed / total)), 3, C.accent) end
  end
  y = y + 10
  local labelText = ns.questKindStyle(ns.questStepKind(row.step), row.step).label
  local file = ns.questIcon(row.step)
  if file then glyph(file, 16, y, 26) end
  badge(labelText, W - 112, y + 1, 96, nil, true)
  local titleHeight = U.T(Q.label(row.step), 52, y + 2, W - 176, "head", C.ink)
  y = y + math.max(28, titleHeight) + 6
  y = y + U.T(Q.detail(row.step, row.requiredFor, row == Q.current()), 16, y, W - 32, "small", C.ink) + 10
  y = y + stepButtons(row, 16, y, W - 32) + 12
  U.box(0, top, W, y - top, C.parch, C.edge)
  return y + 10
end

local function openStep(row, follow)
  Q.jump(row.section, not follow and row or nil)
  ns.showQuestViewer()
end

-- `still`: a step of a route you're only looking at (its page): hovering shows it, clicking does nothing.
local function drawRow(row, y, title, status, secondary, secondaryWidth, active, tip, follow, still)
  local titleWidth = W - 126 - (secondary and secondaryWidth + 12 or 0)
  local done = row.state == "done"
  local marker = active and C.gold or done and C.green or C.dim
  local text = active and C.gold or row.state == "pending" and C.light or C.dim
  local h1 = U.T(status, 12, y + 7, 62, "small", marker)
  local h2 = U.T(title, 114, y + 7, titleWidth, "body", text)
  local file = ns.questIcon(row.step)
  if file then glyph(file, 84, y + 7, 18) end
  local h3 = 0
  if secondary then
    h3 = U.T(secondary, W - 12 - secondaryWidth, y + 7, secondaryWidth, "small", C.dim, "RIGHT")
  end
  local height = math.max(30, math.max(h1, h2, h3) + 14)
  U.rect(0, y, W, height, active and C.panel or C.wash)
  U.rect(0, y + height - 1, W, 1, C.edgeSoft, "border")
  if active then U.rect(0, y, 3, height, C.edge, "border") end
  U.hit(0, y, W, height, title, tip or row.step.text, not still and function() openStep(row, follow) end or nil)
  return y + height + 3
end

local function renderQueue(y, title, list, status, empty, tip)
  y = y + U.sectionTitle(title, y)
  if #list == 0 then return y + U.T(empty, 0, y, W, "body", C.dim) + 8 end
  for _, row in ipairs(list) do
    local follow = row.section.side and status == "Pickup"
    y = drawRow(row, y, row.step.name, status, row.section.title, 136, false,
      follow and "Follow this class quest chain." or tip, follow)
  end
  return y + 8
end

local TRACK = { 0.14, 0.21, 0.23, 1 }

-- A guide's tag: Current, Suggested, Side (an alternate route), Later, Done or Outleveled, with
-- its percentage for Current, Side and Later once you've started it.
local function guideTag(section, status, done, total)
  if total > 0 and done == total then return "Complete" end
  local tag = GUIDE_TAG[status]
  if section.alternate and (status == "open" or status == "later") then tag = "Side" end
  local pct = total > 0 and math.floor(done * 100 / total) or 0
  if pct > 0 and (tag == "Current" or tag == "Side" or tag == "Later") then tag = tag .. " " .. pct .. "%" end
  return tag
end

----------------------------------------------------------------------------
-- Guides
----------------------------------------------------------------------------

local function followGuide(section, phase)
  Q.jump(section, nil, phase)
  ns.showQuestViewer()
end

local function showGuide(section, row)
  librarySection, pageFrom = section, nil
  board.section, board.leg, board.stepPage, board.phase, board.bosses = nil, nil, 1, nil, false
  board.searchRow, board.phase = row, row and row.step.phase or nil
  U.refreshTop()
end

-- Start this route / Start this guide: switch, say so, and show the route you're now on.
local function startGuide(section)
  local before = Q.current()
  Q.jump(section)
  ns.showQuestViewer()
  local now = Q.current()
  if now and now.section == section then
    if not (before and before.section == section) then
      ns.say("Now following " .. Q.plain(section.title) .. ".")
    end
    sub, librarySection, pageFrom = "route", nil, nil
  end
  U.refreshTop()
end

----------------------------------------------------------------------------
-- Quest log
----------------------------------------------------------------------------

-- Quest log cleanup: quests no guide uses and grey ones. Abandon takes two clicks; the second
-- must come within 5 seconds.
local confirmAbandon, confirmAt
local function renderCleanup(y)
  local unused = Q.unusedQuests()
  if #unused == 0 then return y end
  y = y + 6 + U.sectionTitle("Quest log cleanup", y + 6)
  y = y + U.T("Quests no guide of yours uses, and grey quests that give little XP. Abandoning one frees log space.",
    0, y, W, "small", C.dim) + 6
  for _, quest in ipairs(unused) do
    local name = Q.plain(quest.title)
    U.rect(0, y, W, 36, C.wash)
    U.rect(0, y + 35, W, 1, C.edgeSoft, "border")
    U.T(name, 12, y + 4, W - 190, "body", C.light)
    U.T(quest.reason, 12, y + 20, W - 190, "small", C.dim)
    local armed = confirmAbandon == quest.id and GetTime() - (confirmAt or 0) < 5
    local b = U.btn(armed and "Click again" or "Abandon", W - 164, y + 7, 160, function()
      if confirmAbandon == quest.id and GetTime() - (confirmAt or 0) < 5 then
        confirmAbandon = nil
        if Q.abandon(quest.id) then ns.say("abandoned " .. name .. ".")
        else ns.say("this client can't abandon quests from the Codex. Use the quest log.") end
      else
        confirmAbandon, confirmAt = quest.id, GetTime()
      end
      U.refresh()
    end, armed, "Abandon this quest. Click twice to confirm.")
    b.codexLabel = armed and "Click again to abandon" or ("Abandon " .. name)
    y = y + 38
  end
  return y
end

local function renderActive(y)
  local active, pinned = {}, {}
  for id in pairs(Q.logEntries()) do active[#active + 1] = id end
  table.sort(active)
  for _, id in ipairs(Q.pins()) do pinned[id] = true end
  local count, max = Q.logCapacity()
  y = y + U.sectionTitle("Active quests" .. (max and (" (" .. count .. "/" .. max .. ")") or ""), y)
  if #active == 0 then return y + U.T("Your quest log is empty.", 0, y, W, "body", C.dim) + 8 end
  -- One quest-log row per quest: its name and state, then small Show and Track buttons (their
  -- codexLabels keep the quest name: "Show X", "Track X" / "Untrack X").
  for _, id in ipairs(active) do
    local entry = Q.log(id)
    local row = Q.questMatch(id)
    local name = Q.plain(entry.title or (row and row.step.name) or ("Quest " .. id))
    local open = Q.incomplete(id)
    U.rect(0, y, W, 30, pinned[id] and C.panel or C.wash)
    U.rect(0, y + 29, W, 1, C.edgeSoft, "border")
    if pinned[id] then U.rect(0, y, 3, 30, C.accent) end
    local state = not open and "Ready" or pinned[id] and "Tracked" or not row and "Not in your guide" or nil
    local _, title = U.T(name, 12, y + 8, W - 300, "body", row and C.light or C.dim)
    if title.SetWordWrap then title:SetWordWrap(false) end
    if state then U.T(state, W - 286, y + 9, 110, "small", not open and C.green or C.dim, "RIGHT") end
    if row then
      U.btn("Show", W - 168, y + 4, 76, function()
        Q.followQuest(row)
        ns.showQuestViewer()
      end, false, "Follow the matching guide step.").codexLabel = "Show " .. name
    end
    if open then
      U.btn(pinned[id] and "Untrack" or "Track", W - 84, y + 4, 80, function()
        if Q.togglePin(id) then ns.questRefresh() else ns.say("you can track up to three quests.") end
      end, pinned[id], "Keep this quest's progress in the step window.").codexLabel = (pinned[id] and "Untrack " or "Track ") .. name
    end
    y = y + 32
  end
  return y + 8
end

----------------------------------------------------------------------------
-- Step
----------------------------------------------------------------------------

local function renderStepView(current, selected, y)
  local half = (W - 8) / 2
  if current and current.step.type == "plan" then
    U.btn("Plan " .. current.step.name, 0, y, half, function() ns.planQuestRun(current.step.dungeon, true) end, true,
      "The run and its quests join your route, and the guide says when to find a group.")
    U.btn("Skip this run", half + 8, y, half, function() ns.planQuestRun(current.step.dungeon, false) end, false,
      "The run stays out of your route. Guides > Dungeons can plan it later.")
    y = y + 34
  end
  -- Elite quest ahead: the same choice as the step window's Take it / Skip (controller players act here).
  if current and current.step.type == "elite" then
    U.btn("Take it", 0, y, half, function() ns.chooseEliteQuest(current.step.eliteQuest, true) end, true,
      "The quest stays on your route. Bring a group or a strong partner for " .. (current.step.elite or "the elite") .. ".")
    U.btn("Skip it", half + 8, y, half, function() ns.moveQuestStep(false) end, false,
      "The guide passes this quest and the quests that need it. Previous step asks again.")
    y = y + 34
  end
  local run = Q.readyRun()
  if run then
    U.btn("Run " .. run.title, 0, y, W, function()
      Q.jump(run)
      ns.showQuestViewer()
    end, true, "Your planned run is ready: its pickups are done. Find a group, then follow its checklist.")
    y = y + 34
  end
  local related = Q.relatedGuide()
  if related then
    U.btn("Plan " .. related.title, 0, y, W, function() ns.openQuestGuide(related) end, false,
      "Check the pickups, prerequisites, and turn-ins for this guide.")
    y = y + 34
  end
  if selected and selected.side then
    U.btn("Return to leveling", 0, y, half, function()
      Q.returnToRoute()
      ns.showQuestViewer()
    end, false, "Go back to your leveling route. Detour quest progress comes from the game.")
  else
    U.btn("Resume active quest", 0, y, half, function()
      if Q.resumeActive() then ns.showQuestViewer()
      else ns.say("no active route quest to resume.") end
    end, false, "Resume a quest from your log, preferring your current zone. Required earlier quests are kept.")
  end
  local pointing = ns.pointingToFlightMaster()
  U.btn(pointing and "Back to the step" or "Nearest flight master", half + 8, y, half, ns.pointToFlightMaster, pointing,
    "Point the arrow at the closest flight master on your continent, until you open a flight map or press this again.")
  y = y + 36
  y = y + 6 + U.sectionTitle("Help", y + 6)
  if current then
    U.btn("Report this step", 0, y, half, ns.reportQuestStep, false,
      "Copy what the guide sees about this step (your position, quest log and the step) to send with a bug report.")
  end
  U.btn("Copy recorder log", half + 8, y, half, function() ns.questRecord("copy") end)
  return y + 32
end

----------------------------------------------------------------------------
-- Party: each member's guide, step, live goal and when you last heard from them, Follow their
-- guide, the quests one of you has and the other doesn't (Ask to share / Share), and the party
-- switches (QuestParty.lua).
----------------------------------------------------------------------------

-- Where a member is, on the parchment card: dark green on your step, dark orange behind you, the
-- theme's accent ahead, soft ink otherwise (the step window's light colours fade on parchment).
local STATUS_INK = { same = { 0.12, 0.45, 0.12 }, behind = { 0.62, 0.27, 0.04 } }

local function heardText(seconds)
  seconds = math.floor(seconds or 0)
  if seconds < 10 then return "heard just now" end
  if seconds < 60 then return "heard " .. seconds .. " s ago" end
  return "heard " .. math.floor(seconds / 60) .. " min ago"
end

local function questLines(y, heading, list, button, tip, label, onClick)
  if not list or #list == 0 then return y end
  y = y + U.T(heading .. " (" .. #list .. ")", 16, y, W - 32, "label", C.inkSoft) + 4
  for _, q in ipairs(list) do
    U.T(q.title, 28, y + 5, W - 200, "body", C.ink)
    U.btn(button, W - 16 - 150, y, 150, function() onClick(q.id) end, false, tip).codexLabel = label(q)
    y = y + 28
  end
  return y + 2
end

local function memberCard(r, y)
  local top = y
  y = y + 10
  local head = r.name .. (r.level and (" (" .. r.level .. ")") or "") .. (r.className and (" " .. r.className) or "")
  local color = STATUS_INK[r.status] or (r.status == "ahead" and C.accent) or C.inkSoft
  local h = U.T(head, 16, y, W - 200, "head", C.ink)
  U.T(r.where, W - 196, y + 2, 180, "small", color, "RIGHT")
  y = y + h + 4
  if r.codex then
    y = y + U.T(r.guide .. ": " .. Q.plain(r.label or ""), 16, y, W - 32, "body", C.ink) + 2
    local note = (r.goal ~= "" and (Q.plain(r.goal) .. "  -  ") or "") .. heardText(r.heard)
    y = y + U.T(note, 16, y, W - 32, "small", C.inkSoft) + 8
    local mine = Q.routeRow()
    if r.section and not (mine and mine.section == r.section) then
      U.btn("Follow " .. r.name .. "'s guide", 16, y, W - 32, function() ns.partyFollow(r.name) end, false,
        "Switch your guide to " .. r.guide .. ", where " .. r.name .. " is. Your own progress comes from your quest log.")
      y = y + 32
    end
    local have, lack = ns.partyQuestDiff(r.name)
    y = questLines(y, r.name .. " has, you don't", have, "Ask to share",
      "Asks " .. r.name .. "'s Codex to offer you this quest. The game asks you to accept it.",
      function(q) return "Ask " .. r.name .. " to share " .. q.title end,
      function(id) ns.partyAskShare(r.name, id) end)
    y = questLines(y, "You have, " .. r.name .. " doesn't", lack, "Share",
      "Offers this quest to your party. If " .. r.name .. " has done it already, the game says so.",
      function(q) return "Share " .. q.title end, ns.partyShare)
  else
    y = y + U.T(r.offline and (r.name .. " is offline.")
      or (r.name .. " needs the Leveling Codex to share a step, with Settings > Show my party's steps on."),
      16, y, W - 32, "small", C.inkSoft) + 8
  end
  U.box(0, top, W, y - top + 4, C.parch, C.edge)
  return y + 14
end

----------------------------------------------------------------------------
-- Guide setup: a new character gets an offer in the step window. Options opens
-- the four focused groups at any time; session UI state never requires SavedVariables.
----------------------------------------------------------------------------

local setupOpen = false

function ns.questSetupDue()
  return not ns.db().questSetupDone and (UnitLevel("player") or 1) <= 5
end

function ns.openQuestSetup()
  setupOpen, sub, board.option = true, "options", "route"
  ns.openTab("quests")
  U.refreshTop()
end

----------------------------------------------------------------------------
-- The tab
----------------------------------------------------------------------------

-- The board uses the same pooled widgets and controller tagging as every other tab.
-- This local coordinate space keeps the rail separate from the selected page.
local rootUI, rootWidth = U, W
local function pageUI(x, y, width)
  local out = {}
  for key, value in pairs(rootUI) do out[key] = value end
  out.W = width
  out.T = function(s, a, b, ...) return rootUI.T(s, x + a, y + b, ...) end
  for _, key in ipairs({ "rect", "box", "plate", "hit", "segments" }) do
    local method = rootUI[key]
    out[key] = function(a, b, ...) return method(x + a, y + b, ...) end
  end
  for _, key in ipairs({ "icon", "btn", "check", "fold" }) do
    local method = rootUI[key]
    out[key] = function(s, a, b, ...) return method(s, x + a, y + b, ...) end
  end
  out.questSearch = function(a, b, ...) return rootUI.questSearch(x + a, y + b, ...) end
  out.questButtonOptions = function(b, a, w) return rootUI.questButtonOptions(y + b, x + a, w) - y end
  out.goldRuleAt = function(b) rootUI.rect(x, y + b, width, 1, C.edgeSoft, "border") end
  out.sectionTitle = function(s, b, note)
    local h = rootUI.T(Q.plain(s), x, y + b, width, "head", C.gold)
    if note then h = h + rootUI.T(note, x, y + b + h + 4, width, "small", C.dim) + 4 end
    rootUI.rect(x, y + b + h + 6, width, 1, C.edgeSoft, "border")
    return h + 16
  end
  return out
end

local function lineText(text, x, y, w, kind, color, justify)
  local h, fs = U.T(Q.plain(text), x, y, w, kind, color, justify)
  if fs.SetWordWrap then fs:SetWordWrap(false) end
  return h, fs
end

local function excerpt(text, n)
  text = Q.plain(text):gsub("%s+", " ")
  return #text > n and (text:sub(1, n - 3):gsub("%s+%S*$", "") .. "...") or text
end

local function disc(x, y, size, color)
  local t = U.rect(x, y, size, size, color, "border", 2, "questDisc")
  local file = ns.art.FILES.circle
  if ns.art.hasFile(file) and t:SetTexture(file) ~= false then
    t:SetTexCoord(0, 1, 0, 1)
    t:SetVertexColor(ns.rgba(color))
  end
end

local function meter(x, y, value)
  for i = 1, 24 do
    local a = (i / 24) * math.pi * 2 - math.pi / 2
    disc(x + math.cos(a) * 23 - 2, y + math.sin(a) * 23 - 2, 4, i <= value * 24 and C.accent or C.edgeSoft)
  end
  U.T(math.floor(value * 100) .. "%", x - 20, y - 7, 40, "small", C.light, "CENTER")
end

local function legsFor(rows, section)
  local legs, leg, last = {}, nil, nil
  for _, row in ipairs(rows) do
    if row.section == section and row.state ~= "filtered" then
      local map = row.step.map or section.zone
      if not leg or map ~= last then
        leg = { map = map, rows = {}, name = areaName(map, section) }
        legs[#legs + 1], last = leg, map
      end
      leg.rows[#leg.rows + 1] = row
    end
  end
  return legs
end

local function prepareBoard(rows, section)
  local legs, active = legsFor(rows, section), Q.routeRow()
  local activeLeg = 1
  for i, leg in ipairs(legs) do
    for _, row in ipairs(leg.rows) do if row == active then activeLeg = i end end
  end
  if board.section ~= section then
    board.section, board.leg, board.areaPage, board.stepPage, board.expanded = section, nil, nil, 1, false
  end
  if board.searchRow then
    for i, leg in ipairs(legs) do
      for n, row in ipairs(leg.rows) do
        if row == board.searchRow then
          board.leg, board.stepPage, board.searchRow = i, math.floor((n - 1) / 6) + 1, nil
          break
        end
      end
    end
  end
  local selected = math.min(board.leg or activeLeg, math.max(1, #legs))
  return legs, selected, activeLeg
end

local function pager(y, n, size, key, label)
  local pages = math.max(1, math.ceil(n / size))
  board[key] = math.max(1, math.min(board[key] or 1, pages))
  if pages > 1 then
    if board[key] > 1 then U.btn("<", 0, y, 34, function() board[key] = board[key] - 1; U.refreshTop() end).codexLabel = "Previous " .. label .. " page" end
    U.T("Page " .. board[key] .. " / " .. pages, 42, y + 5, W - 84, "small", C.dim, "CENTER")
    if board[key] < pages then U.btn(">", W - 34, y, 34, function() board[key] = board[key] + 1; U.refreshTop() end).codexLabel = "Next " .. label .. " page" end
  end
  return (board[key] - 1) * size + 1, pages > 1 and 32 or 0
end

local function areaCards(rows, section, y, preview)
  local legs, selected = prepareBoard(rows, section)
  local leg = legs[selected]
  if not preview then
    U.btn("Back to journey", 0, y, 140, function() board.expanded = false; U.refreshTop() end)
    U.btn(allSteps and "Hide finished" or "Show finished", W - 136, y, 136, function()
      allSteps, board.stepPage = not allSteps, 1; U.refreshTop()
    end, allSteps).codexLabel = allSteps and "Hide finished" or "Show all steps"
    y = y + 34
  end
  y = y + U.T(leg and ("Area: " .. leg.name) or "Area steps", 0, y, W, "head", C.gold) + 8
  local list = {}
  for _, row in ipairs(leg and leg.rows or {}) do
    if allSteps or preview or row.state == "pending" or row == Q.current() then list[#list + 1] = row end
  end
  local first, ph = pager(y, #list, 6, "stepPage", "steps")
  y = y + ph
  local each = (W - 12) / 2
  for i = first, math.min(first + 5, #list) do
    local row, index = list[i], i - first
    local x, top = (index % 2) * (each + 12), y + math.floor(index / 2) * 108
    local style = ns.questKindStyle(ns.questStepKind(row.step), row.step)
    U.box(x, top, each, 96, C.panel, row == Q.current() and C.accent or C.edgeSoft)
    local file = ns.questIcon(row.step)
    if file then glyph(file, x + 12, top + 10, 20) end
    U.T(style.label, x + 40, top + 12, each - 52, "small", style.color)
    local _, title = U.T(excerpt(row.step.name or Q.label(row.step), 58), x + 12, top + 37, each - 24, "body", C.light)
    title.codexLabel = Q.label(row.step)
    lineText(row.step.quest and Q.questStatus(row) or STATUS[row.state] or "Details", x + 12, top + 76, each - 24, "small", row.state == "done" and C.green or C.dim)
    local why = Q.reason(row)
    U.hit(x, top, each, 96, Q.label(row.step), (why and why .. "\n" or "") .. Q.detail(row.step), not preview and function() openStep(row) end or nil)
  end
  if #list == 0 then U.T("No remaining steps in this area. Show finished to review it.", 0, y, W, "body", C.dim) end
  return y + math.max(1, math.ceil(math.min(6, #list) / 2)) * 108
end

local function journey(rows, selected, current)
  if not selected then
    U.T("Choose a route to begin", 0, 0, W, "head", C.gold)
    U.btn("Explore routes", 0, 42, W, function() sub, librarySection = "guides", nil; U.refreshTop() end)
    stepButtons(nil, 0, 82, W)
    U.btn("Step tools", 0, 116, 140, function() sub = "step"; U.refreshTop() end).codexLabel = "Step"
    return 150
  end
  local legs, chosen, activeLeg = prepareBoard(rows, selected)
  if board.expanded then return areaCards(rows, selected, 0, false) end
  local leg = legs[chosen]
  U.T("YOUR ADVENTURE", 0, 0, W - 110, "label", C.gold)
  U.T("Where to next?", 0, 17, W - 110, "head", C.light)
  local passed, total = Q.stepProgress(selected)
  badge(total > 0 and passed == total and "Complete" or "Following", W - 100, 8, 100)
  local top, height = 48, 156
  U.box(0, top, W, height, C.panel, C.edgeSoft)
  lineText(selected.title, 14, top + 10, W - 92, "head", C.light)
  U.T("Levels " .. selected.levels[1] .. "-" .. selected.levels[2] .. "  |  " .. passed .. " / " .. total .. " steps passed",
    14, top + 34, W - 112, "small", C.dim)
  meter(W - 38, top + 32, total > 0 and passed / total or 0)
  local areaPage = board.areaPage or math.floor((chosen - 1) / 3)
  areaPage = math.max(0, math.min(areaPage, math.max(0, math.ceil(#legs / 3) - 1)))
  if areaPage > 0 then U.btn("<", 14, top + 55, 24, function() board.areaPage = areaPage - 1; U.refresh() end).codexLabel = "Previous areas page" end
  if (areaPage + 1) * 3 < #legs then U.btn(">", W - 38, top + 55, 24, function() board.areaPage = areaPage + 1; U.refresh() end).codexLabel = "Next areas page" end
  local cell = (W - 28) / 3
  U.rect(14 + cell / 2, top + 91, cell * 2, 2, C.edgeSoft)
  for slot = 1, 3 do
    local index = areaPage * 3 + slot
    local area = legs[index]
    if area then
      local cx = 14 + (slot - 0.5) * cell
      areaThumbnail(area.map, cx - 39, top + 68, 78, 48, index == chosen)
      lineText(area.name, cx - cell / 2 + 4, top + 120, cell - 8, "small", index == chosen and C.gold or C.light, "CENTER")
      U.T(index == activeLeg and "You are here" or index == chosen and "Preview" or "Area " .. index,
        cx - cell / 2, top + 137, cell, "small", C.dim, "CENTER")
      U.hit(cx - 46, top + 68, 92, 86, area.name, "Preview this area's quests without changing your followed step.", function()
        board.leg, board.stepPage = index, 1; U.refresh()
      end, "Area " .. index .. ": " .. area.name)
    end
  end
  local row
  for _, candidate in ipairs(leg and leg.rows or {}) do
    if candidate == current then row = candidate; break end
    if not row and candidate.state == "pending" then row = candidate end
  end
  row = row or (leg and leg.rows[1])
  local y, left = 218, math.floor(W * 0.63)
  local bottom = y + 150
  if row then
    local preview = row ~= current
    U.T(preview and "AREA PREVIEW" or Q.autoStep() and "CURRENT STEP" or "STEP PREVIEW", 14, y + 12, left - 28, "label", C.inkSoft)
    local style = ns.questKindStyle(ns.questStepKind(row.step), row.step)
    local titleHeight, title = U.T(excerpt(row.step.name or Q.label(row.step), 48), 14, y + 33, left - 28, "head", C.ink)
    title.codexLabel = Q.label(row.step)
    local textY = y + 38 + titleHeight
    local detailHeight = U.T(excerpt(Q.detail(row.step, row.requiredFor, row == current), 80), 14, textY, left - 28, "small", C.ink)
    local actionY = math.max(y + 114, textY + detailHeight + 10)
    U.btn(preview and "View this step" or "Continue guide", 14, actionY, left - 28, function()
      if preview then openStep(row) else Q.leaveReview(); ns.showQuestViewer(); U.refresh() end
    end, true, style.label .. ": " .. Q.plain(row.step.text or ""))
    bottom = math.max(bottom, actionY + 34)
    U.box(0, y, left, bottom - y, C.parch, C.edge)
  else
    U.T("This route is complete.", 14, y + 18, left - 28, "head", C.ink)
    U.box(0, y, left, 150, C.parch, C.edge)
  end
  lineText("Area: " .. (leg and leg.name or areaName(selected.zone, selected)), left + 14, y + 4, W - left - 14, "small", C.dim)
  U.T("COMING UP", left + 14, y + 25, W - left - 14, "label", C.gold)
  local nextY, count, seen = y + 48, 0, not row
  for _, candidate in ipairs(leg and leg.rows or {}) do
    if seen and candidate ~= row and candidate.state == "pending" and count < 2 then
      local file = ns.questIcon(candidate.step)
      if file then glyph(file, left + 14, nextY, 16) end
      local h = U.T(excerpt(candidate.step.name or Q.label(candidate.step), 48), left + 38, nextY, W - left - 38, "small", C.light)
      nextY, count = nextY + h + 14, count + 1
    end
    if candidate == row then seen = true end
  end
  if count == 0 then U.T("Next area follows when this one is finished.", left + 14, nextY, W - left - 14, "small", C.dim) end
  y = bottom + 12
  y = y + stepButtons(current, 0, y, W) + 12
  local state, n = dungeonState()
  local plan = ({ recommended = "Recommended", all = "All", none = "None", picks = "Your picks" })[state]
  y = y + U.T("Pace: " .. paceName() .. "  |  Dungeons: " .. plan .. (n > 0 and " (" .. n .. ")" or "") .. "  |  Elites: " .. Q.ELITE_LABELS[Q.eliteModeIndex()],
    0, y, W, "small", C.dim) + 8
  U.btn("Area steps", 0, y, 112, function() board.expanded, board.stepPage = true, 1; U.refreshTop() end)
  U.btn("Step tools", 120, y, 110, function() sub = "step"; U.refreshTop() end).codexLabel = "Step"
  U.btn("Explore routes", W - 150, y, 150, function() sub, librarySection = "guides", nil; U.refreshTop() end).codexLabel = "Change route"
  return y + 24
end

local function guideTile(section, x, y, w, dungeon)
  local status, done, total = Q.sectionStatus(section, board.suggestions)
  local kind, file, color = guideStyle(section)
  local h = dungeon and 174 or 158
  U.box(x, y, w, h, C.panel, status == "current" and C.accent or C.edgeSoft)
  local art = U.rect(x + 5, y + 5, w - 10, 46, C.panel, nil, 0, "questTileFade")
  ns.fade(art, "HORIZONTAL", color[1], color[2], color[3], 0.22, 0.03)
  if not mapPreview(section.zone, x + 5, y + 5, w - 10, 46) then
    glyph(file, x + 14, y + 13, 28)
  end
  if dungeon then U.T("Entrance area", x + 12, y + 34, w - 24, "small", C.light) end
  local tag = dungeon and (total > 0 and done == total and "Complete" or status == "current" and "Following" or Q.planned(section.id) and "Planned" or "Not planned") or guideTag(section, status, done, total)
  if tag then badge(tag, x + w - 104, y + 14, 90, (status == "done" or status == "outleveled") and C.dim or color) end
  U.T(excerpt(section.title, 48), x + 12, y + 58, w - 24, "body", status == "outleveled" and C.dim or C.light)
  U.T("Levels " .. section.levels[1] .. "-" .. section.levels[2], x + 12, y + 97, w - 24, "small", C.dim)
  local barY = y + (dungeon and 119 or 151)
  U.rect(x + 12, barY, w - 24, 3, TRACK)
  if total > 0 and done > 0 then U.rect(x + 12, barY, (w - 24) * done / total, 3, C.accent) end
  if not dungeon and section.reward then U.T(Q.plain(section.reward), x + 12, y + 120, w - 24, "small", C.dim) end
  U.hit(x, y, w, dungeon and 136 or h, section.title,
    kind .. ": " .. areaName(section.zone, section) .. ". " .. (section.reward or "Preview the guide before following it."),
    function() showGuide(section) end, section.title)
  if dungeon then
    local planned = Q.planned(section.id)
    local inLog, left = Q.runReadiness(section)
    lineText(inLog .. " in log, " .. left .. " to pick up", x + 12, y + 124, w - 24, "small", C.dim)
    U.btn("Prepare", x + 12, y + 144, w - 90, function()
      Q.setPlanned(section.id, true); Q.jump(section, nil, "prepareOnly"); ns.showQuestViewer(); U.refresh()
    end, false, "Follow outdoor pickups before entering the dungeon.").codexLabel = "Prepare: " .. section.title
    U.btn(planned and "Planned" or "Plan", x + w - 70, y + 144, 58, function()
      Q.setPlanned(section.id, not planned); ns.updateQuestSettings()
    end, planned).codexLabel = (planned and "Unplan " or "Plan ") .. section.title
  end
  return h
end

local function tileGrid(list, y, dungeon, key)
  local first, ph = pager(y, #list, 4, key, dungeon and "dungeons" or "guides")
  y = y + ph
  local each, h = (W - 12) / 2, dungeon and 174 or 158
  for i = first, math.min(first + 3, #list) do
    local n = i - first
    guideTile(list[i], (n % 2) * (each + 12), y + math.floor(n / 2) * (h + 12), each, dungeon)
  end
  if #list == 0 then return y + U.T("No guides in this view yet.", 0, y, W, "body", C.dim) + 12 end
  return y + math.ceil(math.min(4, #list) / 2) * (h + 12)
end

local function guidePage(rows, section)
  local back = pageFrom == "route"
  U.btn(back and "Back to the route" or "Back to guides", 0, 0, 150, function()
    librarySection, pageFrom = nil, nil
    if back then sub = "route" end
    U.refreshTop()
  end)
  local status, done, total = Q.sectionStatus(section)
  local onIt, dungeon = status == "current", section.category == "dungeon"
  local current = Q.routeRow()
  local preview = not onIt
  local y = 38
  badge(total > 0 and done == total and "Complete" or onIt and "Following" or "Preview", W - 100, y, 100)
  U.T(preview and "PREVIEW" or "FOLLOWING THIS GUIDE", 0, y + 3, W - 112, "label", C.gold)
  y = y + 29
  y = y + U.T(section.title, 0, y, W, "head", C.light) + 8
  y = y + U.T("Area: " .. areaName(section.zone, section) .. "  |  " .. sectionInfo(section), 0, y, W, "small", C.dim) + 10
  if section.reward then y = y + U.T("You get: " .. Q.plain(section.reward), 0, y, W, "small", C.gold) + 10 end
  local minimum = Q.guideMinimum(section)
  if minimum then y = y + U.T("Available at level " .. minimum, 0, y, W, "body", C.dim) + 12
  elseif dungeon then
    local each = (W - 16) / 3
    U.btn("Follow this guide", 0, y, each, function() followGuide(section) end)
    U.btn("Start inside", each + 8, y, each, function() followGuide(section, "inside") end)
    U.btn("After the run", 2 * (each + 8), y, each, function() followGuide(section, "after") end)
    y = y + 34
    local planned = Q.planned(section.id)
    U.btn(planned and "Planned: its pickups are in your route" or "Plan this run", 0, y, W, function()
      Q.setPlanned(section.id, not planned); ns.updateQuestSettings()
    end, planned)
    y = y + 30
    y = y + U.T(runInfo(section), 0, y, W, "small", C.dim) + 10
    U.btn("Prepare quests", 0, y, W, function()
      Q.setPlanned(section.id, true); followGuide(section, "prepareOnly")
    end)
    y = y + 34
  elseif not section.category then
    if onIt then
      y = y + U.T(section.side and "You are following this guide." or "You are on this route.", 0, y, W, "small", C.gold) + 8
      U.btn("First open step", 0, y, (W - 8) / 2, function() startGuide(section) end)
      U.btn("See your step", (W + 8) / 2, y, (W - 8) / 2, function() show("step") end)
    else
      U.btn(section.side and "Start this guide" or "Start this route", 0, y, W, function() startGuide(section) end, true)
    end
    y = y + 32
    local _, _, _, level, selected = Q.rows()
    if not onIt and selected then y = y + U.T("You are on " .. Q.plain(selected.title) .. " until you start this one.", 0, y, W, "small", C.dim) + 10 end
    if status == "later" then y = y + U.T("It starts at level " .. section.levels[1] .. "; you are " .. level .. ".", 0, y, W, "small", C.gold) + 10 end
  else
    U.btn("Follow this guide", 0, y, W, function() followGuide(section) end)
    y = y + 34
  end
  for _, id in ipairs(section.links or {}) do
    local linked = Q.section(id)
    if linked then U.btn(linked.title, 0, y, W, function() showGuide(linked) end); y = y + 28 end
  end
  local list = rows
  if dungeon then
    local phases, labels = { "prepare", "inside", "after" }, { "Prepare", "Inside", "Turn-ins" }
    local phase = board.phase or (onIt and current and current.section == section and current.step.phase) or "prepare"
    local lit = 1
    for i, value in ipairs(phases) do
      if value == phase then lit = i end
      if onIt and current and current.section == section and (current.step.phase or "prepare") == value then labels[i] = labels[i] .. " (now)" end
    end
    y = y + U.segments(0, y, W, labels, lit, function(i)
      board.phase, board.leg, board.stepPage = phases[i], nil, 1; U.refreshTop()
    end) + 10
    if section.bosses and #section.bosses > 0 then
      U.btn(board.bosses and "Quest checklist" or "Bosses in order", 0, y, W, function() board.bosses = not board.bosses; U.refreshTop() end)
      y = y + 30
      if board.bosses then
        y = y + U.sectionTitle("BOSSES IN ORDER", y)
        local first, ph = pager(y, #section.bosses, 4, "bossPage", "bosses")
        y = y + ph
        for i = first, math.min(first + 3, #section.bosses) do
          local boss = section.bosses[i]
          y = y + U.T(i .. ". " .. Q.plain(boss.name), 0, y, W, "body", C.gold) + 5
          y = y + U.T(Q.plain(boss.tip), 0, y, W, "small", C.light) + 16
        end
        return y
      end
    end
    list = {}
    for _, row in ipairs(rows) do
      if row.section == section and (row.step.phase or "prepare") == phases[lit] then list[#list + 1] = row end
    end
    U.T(({ prepare = "BEFORE YOU GO", inside = "INSIDE", after = "AFTER THE RUN" })[phases[lit]], 0, y, W, "label", C.gold)
    y = y + 24
  end
  local legs, chosen = prepareBoard(list, section)
  if #legs > 1 then
    if chosen > 1 then U.btn("<", 0, y, 28, function() board.leg, board.stepPage = chosen - 1, 1; U.refreshTop() end).codexLabel = "Previous guide area" end
    U.T("Area " .. chosen .. " / " .. #legs, 36, y + 5, W - 72, "small", C.dim, "CENTER")
    if chosen < #legs then U.btn(">", W - 28, y, 28, function() board.leg, board.stepPage = chosen + 1, 1; U.refreshTop() end).codexLabel = "Next guide area" end
    y = y + 30
  end
  return areaCards(list, section, y, true)
end

local function routeBoard(rows, sections, level, dungeon)
  if librarySection then return guidePage(rows, librarySection) end
  U.T(dungeon and "YOUR DUNGEON BOARD" or "CHOOSE YOUR ADVENTURE", 0, 0, W, "label", C.gold)
  U.T(dungeon and "Prepare. Group up. Go." or "Routes for your level", 0, 17, W, "head", C.light)
  local y = 48
  if dungeon then
    y = y + dungeonChoices(0, y, W) + 12
    return tileGrid(Q.dungeons(), y, true, "dungeonPage")
  end
  local labels, views = { "Your level", "All levels", "Special", "Class" }, { "level", "all", "special", "class" }
  local lit = 1
  for i, view in ipairs(views) do if guideView == view then lit = i end end
  y = y + U.segments(0, y, W, labels, lit, function(i)
    guideView, board.routePage, query, draft = views[i], 1, "", ""; U.refreshTop()
  end) + 10
  local function search() query, board.routePage = draft, 1; U.refreshTop() end
  U.questSearch(8, y, W - 100, draft, function(value) draft = value end, search)
  U.btn("Search", W - 80, y, 80, search)
  y = y + 34
  local groups = { leveling = {}, special = {}, class = {}, dungeon = {} }
  for _, section in ipairs(sections) do
    local key = section.category or (section.side and "class" or "leveling")
    if groups[key] then groups[key][#groups[key] + 1] = section end
  end
  if query:find("%S") then
    local found, matches = Q.find(query)
    local list, filtered = {}, 0
    for _, section in ipairs(found) do list[#list + 1] = { section = section } end
    for _, row in ipairs(matches) do
      if row.state == "filtered" then filtered = filtered + 1
      else list[#list + 1] = { row = row } end
    end
    U.btn("Clear search", 0, y, 120, function() query, draft, board.routePage = "", "", 1; U.refreshTop() end)
    y = y + 34
    local first, ph = pager(y, #list, 4, "routePage", "guides")
    y = y + ph
    local each = (W - 12) / 2
    for i = first, math.min(first + 3, #list) do
      local item, n = list[i], i - first
      local x, top = (n % 2) * (each + 12), y + math.floor(n / 2) * 170
      if item.section then guideTile(item.section, x, top, each, false)
      else
        local row = item.row
        U.box(x, top, each, 132, C.panel, C.edgeSoft)
        glyph(ns.questIcon(row.step) or "Interface\\Icons\\INV_Misc_Note_01", x + 12, top + 12, 24)
        local _, title = U.T(excerpt(row.step.name or Q.label(row.step), 60), x + 12, top + 49, each - 24, "body", C.light)
        title.codexLabel = Q.label(row.step)
        lineText(row.section.title, x + 12, top + 103, each - 24, "small", C.dim)
        U.hit(x, top, each, 132, Q.label(row.step), Q.detail(row.step), function() showGuide(row.section, row) end, Q.label(row.step))
      end
    end
    if #list == 0 then
      U.T(filtered > 0 and "Matching quests are outside your current route options. Review Options > Your route to change optional quest choices."
        or "No matching guides or quests.", 0, y, W, "body", C.dim)
    end
    return y + math.max(1, math.ceil(math.min(4, #list) / 2)) * 170
  end
  if guideView == "all" then
    local band = board.band
    if not band then
      local each = (W - 12) / 2
      for i, value in ipairs(BANDS) do
        local x, top = ((i - 1) % 2) * (each + 12), y + math.floor((i - 1) / 2) * 92
        U.box(x, top, each, 80, C.panel, C.edgeSoft)
        glyph("Interface\\Icons\\INV_Misc_Map_01", x + 12, top + 14, 25)
        U.T("Levels " .. value[1] .. "-" .. value[2], x + 48, top + 15, each - 60, "body", C.light)
        U.T(i == 1 and "Starting zones" or "Explore routes", x + 12, top + 49, each - 24, "small", C.dim)
        U.hit(x, top, each, 80, value[3], nil, function() board.band, board.routePage = value, 1; U.refreshTop() end, value[3])
      end
      return y + 276
    end
    U.btn("All level bands", 0, y, W, function() board.band = nil; U.refreshTop() end)
    local list = {}
    for _, section in ipairs(groups.leveling) do if section.levels[1] >= band[1] and section.levels[1] <= band[2] then list[#list + 1] = section end end
    return tileGrid(list, y + 34, false, "routePage")
  end
  local list = {}
  if guideView == "class" or guideView == "special" then list = groups[guideView]
  else
    local suggested = {}
    for _, section in ipairs(Q.suggestions(true)) do suggested[section] = true end
    for _, section in ipairs(groups.leveling) do
      local status = Q.sectionStatus(section, suggested)
      if status == "current" or suggested[section] or (level >= section.levels[1] - 1 and level <= section.levels[2]) then list[#list + 1] = section end
    end
    table.sort(list, function(a, b)
      local ac, bc = Q.sectionStatus(a) == "current", Q.sectionStatus(b) == "current"
      if ac ~= bc then return ac end
      return a.levels[1] < b.levels[1]
    end)
  end
  return tileGrid(list, y, false, "routePage")
end

local function navigation(selected)
  U.rect(0, 0, 94, 470, C.panel)
  U.rect(94, 0, 1, 470, C.edgeSoft, "border")
  U.T("QUESTS", 8, 8, 78, "label", C.gold)
  local nav = { { "route", "Journey", "Route", "INV_Misc_Map_01" }, { "guides", "Routes", "Guides", "INV_Misc_Book_09" },
    { "dungeons", "Dungeons", "Dungeons", "INV_Misc_Head_Dragon_01" }, { "log", "Quest log", "Quest log", "INV_Misc_Note_01" },
    { "party", "Party", "Party", "INV_Misc_GroupLooking" }, { "options", "Options", "Setup", "INV_Misc_Gear_01" } }
  for i, entry in ipairs(nav) do
    local y = 35 + (i - 1) * 46
    local active = sub == entry[1] or sub == "step" and entry[1] == "route"
    if sub == "guides" and librarySection and librarySection.category == "dungeon" then active = entry[1] == "dungeons" end
    if active then
      U.rect(4, y, 86, 38, C.btnOn, "border")
      U.rect(4, y, 3, 38, C.accent, "border", 1)
    end
    glyph("Interface\\Icons\\" .. entry[4], 9, y + 11, 16)
    U.T(entry[2], 30, y + 12, 58, "small", active and C.btnOnInk or C.light)
    U.hit(4, y, 86, 38, entry[2], nil, function()
      sub, librarySection, pageFrom = entry[1], nil, nil
      if sub == "route" then board.expanded = false end
      if sub == "route" then board.leg, board.areaPage = nil, nil end
      if sub == "guides" then guideView, board.routePage, board.band = "level", 1, nil end
      if sub == "dungeons" then board.dungeonPage = 1 end
      if sub == "log" then board.log = nil end
      if sub == "party" then board.member = nil end
      if sub == "options" then board.option = nil end
      U.refreshTop()
    end, entry[3])
  end
  if selected then
    U.T("FOLLOWING", 8, 340, 78, "label", C.gold)
    U.T(excerpt(selected.title, 38), 8, 362, 78, "small", C.light)
  end
end

local function optionsBoard()
  local db, group = ns.db(), board.option
  U.T("SET UP YOUR GUIDE", 0, 0, W, "label", C.gold)
  U.T(group and ({ route = "Your route", display = "Map and step window", helpers = "Quest and vendor helpers", party = "Party play" })[group] or "Guide options",
    0, 18, W, "head", C.light)
  local function done()
    db.questSetupDone, setupOpen, sub, board.option = true, false, "route", nil
    ns.questRefresh(); U.refreshTop()
  end
  if not group then
    local cards = { { "route", "Your route", "Pace, dungeon pickups and elite decisions.", "INV_Misc_Map_01" },
      { "display", "Map and step window", "Arrow, map lines, size and quest buttons.", "INV_Misc_Spyglass_03" },
      { "helpers", "Helpers", "Quest conversations, travel and vendors.", "INV_Misc_Gear_01" },
      { "party", "Party play", "Sharing, progress and chat announcements.", "INV_Misc_GroupLooking" } }
    local each = (W - 12) / 2
    for i, card in ipairs(cards) do
      local x, y = ((i - 1) % 2) * (each + 12), 55 + math.floor((i - 1) / 2) * 147
      U.box(x, y, each, 135, C.panel, C.edgeSoft)
      glyph("Interface\\Icons\\" .. card[4], x + 14, y + 14, 30)
      U.T(card[2], x + 14, y + 57, each - 28, "body", C.light)
      U.T(card[3], x + 14, y + 82, each - 28, "small", C.dim)
      U.hit(x, y, each, 135, card[2], card[3], function() board.option = card[1]; U.refreshTop() end, card[2])
    end
    U.btn("Done", 0, 360, W, done, true)
    return 400
  end
  U.btn("Back to options", 0, 52, 140, function() board.option = nil; U.refreshTop() end)
  local y = 90
  local function heading(s)
    y = y + U.T(s, 0, y, W, "label", C.gold) + 8
  end
  local function check(label, key, inverse, refresh)
    U.check(label, 0, y, inverse and not db[key] or not inverse and db[key], function()
      db[key] = not db[key]; if refresh then refresh() end; U.refresh()
    end)
    y = y + 28
  end
  if group == "route" then
    heading("PACE")
    local every, fastest = db.questKeepGrey and db.questOptional, not db.questKeepGrey and not db.questOptional
    y = y + U.segments(0, y, W, { "Fastest", "Every quest" }, fastest and 1 or every and 2 or nil, function(i)
      db.questKeepGrey, db.questOptional = i == 2, i == 2; ns.updateQuestSettings()
    end) + 8
    y = y + U.T(every and "Keep grey pickups and optional errands." or fastest and "Focus on leveling; leave grey pickups and side errands out." or "Custom: see Settings", 0, y, W, "small", C.dim) + 18
    heading("DUNGEONS")
    y = y + dungeonChoices(0, y, W) + 8
    y = y + U.T("Planned runs add outdoor pickups. You choose when to enter.", 0, y, W, "small", C.dim) + 18
    heading("ELITE QUESTS")
    y = y + U.segments(0, y, W, Q.ELITE_LABELS, Q.eliteModeIndex(), function(i) Q.setEliteMode(i); ns.updateQuestSettings() end, Q.ELITE_TIPS) + 22
  elseif group == "helpers" then
    heading("QUEST CONVERSATIONS")
    check("Auto-accept", "questAutoAccept")
    check("Auto turn-in", "questAutoTurnin")
    check("Auto-fly and bind", "questAutoTravel")
    heading("VENDORS")
    check("Sell junk", "noAutoSell", true)
    check("Repair", "noAutoRepair", true)
    y = y + U.T("Hold Alt to pause these helpers for the current conversation.", 0, y, W, "small", C.dim) + 12
  elseif group == "display" then
    heading("MAP LINES")
    check("Minimap", "noMinimapLine", true, ns.questRefresh)
    check("World map", "noWorldMapLine", true, ns.questRefresh)
    heading("STEP WINDOW")
    U.btn("-", 0, y, 28, function() ns.setQuestViewerScale(-0.1); U.refresh() end).codexLabel = "Step window size -"
    U.T(math.floor((tonumber(db.questViewerScale) or 1) * 100 + 0.5) .. "%", 34, y + 4, 52, "body", C.light, "CENTER")
    U.btn("+", 92, y, 28, function() ns.setQuestViewerScale(0.1); U.refresh() end).codexLabel = "Step window size +"
    y = y + 34
    check("Compact", "questCompact", false, ns.questRefresh)
    local counts, ahead, lit = { 2, 5, 10 }, ns.questPreviewCount()
    for i, n in ipairs(counts) do if n == ahead then lit = i end end
    y = y + U.segments(0, y, W, { "2 steps", "5 steps", "10 steps" }, lit, function(i) ns.setQuestPreview(counts[i]); U.refresh() end) + 18
    if not lit then y = y + U.T(ahead .. " steps: see Settings", 0, y, W, "small", C.dim) + 12 end
    local top = y
    y = U.questButtonOptions(y + 12, 16, W - 32)
    U.box(0, top, W, y - top + 8, C.parch, C.edge)
    y = y + 20
  elseif group == "party" then
    check("Party steps", "noPartySteps", true, ns.questRefresh)
    U.check("Share quests", 0, y, ns.questSharing(), function() ns.toggleQuestSharing(); U.refresh() end); y = y + 28
    check("Ping together", "noPartyPing", true)
    heading("PARTY CHAT")
    check("Steps done", "questAnnounceSteps")
    check("Quest items", "questAnnounceItems")
    check("Progress", "questAnnounceProgress")
    check("Flights", "questAnnounceFlights")
  end
  U.btn("Done", 0, y + 6, W, done, true)
  return y + 42
end

local function logBoard(missed, ready)
  if board.log then
    U.btn("Back to quest log", 0, 0, 160, function() board.log = nil; U.refreshTop() end)
    if board.log == "active" then return renderActive(40) end
    if board.log == "cleanup" then return renderCleanup(40) end
    if board.log == "ready" then return renderQueue(40, "Ready to turn in (" .. #ready .. ")", ready, "Ready", "No route quests are ready to turn in.") end
    local y = renderQueue(40, "Missed quests (" .. #missed .. ")", missed, "Pickup", "No earlier pickups match your level.")
    return renderQueue(y, "Outleveled (grey)", Q.greyPickups(), "Grey", "No grey pickups.")
  end
  U.T("YOUR QUEST LOG", 0, 0, W, "label", C.gold)
  U.T("What needs attention?", 0, 18, W, "head", C.light)
  local count = 0
  for _ in pairs(Q.logEntries()) do count = count + 1 end
  local cards = { { "ready", "Ready to turn in", #ready .. " route quests", "ActiveQuestIcon" },
    { "active", "In progress", count .. " quests in your log", "AvailableQuestIcon" },
    { "missed", "Missed pickups", (#missed + #Q.greyPickups()) .. " earlier pickups", "AvailableQuestIcon" },
    { "cleanup", "Clean up", "Review quests outside your route", "VendorGossipIcon" } }
  local each = (W - 12) / 2
  for i, card in ipairs(cards) do
    local x, y = ((i - 1) % 2) * (each + 12), 58 + math.floor((i - 1) / 2) * 143
    U.box(x, y, each, 130, C.panel, C.edgeSoft)
    glyph("Interface\\GossipFrame\\" .. card[4], x + 14, y + 16, 28)
    U.T(card[2], x + 14, y + 61, each - 28, "body", C.light)
    U.T(card[3], x + 14, y + 90, each - 28, "small", C.dim)
    U.hit(x, y, each, 130, card[2], nil, function() board.log = card[1]; U.refreshTop() end, card[2])
  end
  return 350
end

local function partyBoard()
  U.T("ADVENTURE TOGETHER", 0, 0, W, "label", C.gold)
  U.T("Your party", 0, 18, W, "head", C.light)
  local rows = ns.partyInParty() and ns.partyRows(true) or {}
  local y = 56
  if board.member then
    U.btn("Back to party", 0, y, W, function() board.member = nil; U.refreshTop() end)
    y = y + 34
    for _, r in ipairs(rows) do if r.name == board.member then y = memberCard(r, y); break end end
  elseif #rows == 0 then
    glyph("Interface\\Icons\\INV_Misc_GroupLooking", 16, y + 18, 34)
    U.T("Ready when your party is.", 62, y + 20, W - 78, "head", C.ink)
    U.T("You're not in a party. Group up with another Codex player to see each other's guide, quest goals and shared progress.", 16, y + 70, W - 32, "body", C.ink)
    U.box(0, y, W, 140, C.parch, C.edge)
    y = y + 156
  else
    local each = (W - 12) / 2
    for i, r in ipairs(rows) do
      local x, top = ((i - 1) % 2) * (each + 12), y + math.floor((i - 1) / 2) * 154
      U.box(x, top, each, 142, C.panel, r.status == "same" and C.accent or C.edgeSoft)
      U.T(excerpt(r.name, 32), x + 12, top + 12, each - 24, "head", C.light)
      lineText(r.where, x + 12, top + 38, each - 24, "small", C.gold)
      U.T(excerpt(r.codex and (r.guide .. ": " .. (r.label or "")) or r.offline and "Offline" or "Waiting for Codex progress", 72),
        x + 12, top + 63, each - 24, "small", C.light)
      lineText(r.goal or "", x + 12, top + 115, each - 24, "small", C.dim)
      U.hit(x, top, each, 142, r.name, "Open this party member's guide and shared quests.", function() board.member = r.name; U.refreshTop() end, "Party member: " .. r.name)
    end
    y = y + math.ceil(#rows / 2) * 154
  end
  U.btn("Party settings", 0, y, W, function() sub, board.option = "options", "party"; U.refreshTop() end)
  U.btn("Preview quest announcements", 0, y + 32, W, ns.previewQuestAnnouncements, false, "Preview privately; no party message is sent.")
  return y + 66
end

local function render()
  local rows, sections, missed, level, selected, ready = Q.rows()
  board.suggestions = {}
  for _, section in ipairs(Q.suggestions(true)) do board.suggestions[section] = true end
  navigation(selected)
  U, W = pageUI(108, 0, rootWidth - 108), rootWidth - 108
  local ok, height = pcall(function()
    if #sections == 0 then return U.T("Your character has no published route yet.", 0, 0, W, "body", C.dim) end
    if sub == "route" then return journey(rows, selected, Q.current()) end
    if sub == "guides" then return routeBoard(rows, sections, level, false) end
    if sub == "dungeons" then return routeBoard(rows, sections, level, true) end
    if sub == "options" then return optionsBoard() end
    if sub == "log" then return logBoard(missed, ready) end
    if sub == "party" then return partyBoard() end
    U.btn("Back to journey", 0, 0, 140, function() sub = "route"; U.refreshTop() end)
    local y = Q.current() and stepCard(Q.current(), 36) or (36 + stepButtons(nil, 0, 36, W) + 14)
    return renderStepView(Q.current(), selected, y)
  end)
  U, W = rootUI, rootWidth
  if not ok then error(height) end
  return math.max(470, height + 8)
end

ns.addTab("quests", "Quests", render)

-- The step window's Quests button: the Step sub-tab.
function ns.openQuestStep()
  sub = "step"
  ns.openTab("quests")
  U.refreshTop()
end

-- The step window's completion bar opens the current guide's route.
function ns.openQuestRoute()
  sub = "route"
  ns.openTab("quests")
  U.refreshTop()
end

function ns.openQuestGuide(section)
  board.section, board.leg, board.stepPage, board.phase, board.bosses, board.searchRow = nil, nil, 1, nil, false, nil
  sub, librarySection, query, draft, pageFrom = "guides", section, "", "", nil
  ns.openTab("quests")
  U.refreshTop()
end
