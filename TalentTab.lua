-- TalentTab.lua: the Talents tab. Path cards (the Codex guide, a path per spec, Custom), the full game
-- tree for all three trees side by side with your path's ranks at the level shown, the talent you
-- clicked with every point the path puts into it, and every point in order. Window.lua keeps the tab
-- and calls ns.renderTalents(V); drawing goes through ns.ui.

local _, ns = ...
local C, plain = ns.C, ns.plain

local GOLD = { 1, 0.82, 0, 1 }
local CARD_W, CARD_H = 280, 54
local TREE_W, TREE_GAP = 184, 8
local CELL_W, CELL_H, NODE = 42, 52, 32
local CUSTOM_ICON = "inv_misc_note_01"

local selectedTalent

local function accent(a) return { C.accent[1], C.accent[2], C.accent[3], a } end

-- The tree with your path's points: { tabs, talents = { { name, icon, max, tab, row, col, prereq, tip,
-- points = { { level, rank, text } } } }, byName }.
local function model(plan)
  local tree = ns.talentTree()
  if not tree then return nil end
  local talents, byName = {}, {}
  for _, t in ipairs(tree.talents) do
    local m = { name = t.name, icon = t.icon, max = t.max, tab = t.tab, row = t.row, col = t.col,
      prereq = t.prereq, tip = t.tip, points = {} }
    talents[#talents + 1], byName[t.name] = m, m
  end
  local ranks = {}
  for _, p in ipairs(plan) do
    local m = byName[p.name]
    if m then
      for l = p.from, p.to do
        ranks[p.name] = (ranks[p.name] or 0) + 1
        m.points[#m.points + 1] = { level = l, rank = ranks[p.name], text = (l == p.from or p.more == "") and p.why or p.more }
      end
    end
  end
  for _, m in ipairs(talents) do table.sort(m.points, function(a, b) return a.level < b.level end) end
  return { tabs = tree.tabs, talents = talents, byName = byName }
end

-- A talent's rank at level V, its next point after V, and whether V's point goes into it.
local function rankAt(t, V)
  local r, nextP, here = 0, nil, false
  for _, p in ipairs(t.points) do
    if p.level <= V then
      r = p.rank
      if p.level == V then here = true end
    elseif not nextP then
      nextP = p
    end
  end
  return r, nextP, here
end

local function outline(x, y, w, h, color)
  local rect = ns.ui.rect
  rect(x, y, w, 2, color, "border", 1); rect(x, y + h - 2, w, 2, color, "border", 1)
  rect(x, y, 2, h, color, "border", 1); rect(x + w - 2, y, 2, h, color, "border", 1)
end

local function splitText(plan)
  local s = ns.talentSplit(plan)
  return s[1] .. " / " .. s[2] .. " / " .. s[3]
end

local function pathPlan(p)
  if p.custom then
    local key = ns.talentPathKey()
    return key == "custom" and ns.talentPlan() or {}
  end
  return p.plan or {}
end

----------------------------------------------------------------------------
-- Path cards
----------------------------------------------------------------------------

local function drawCards(y)
  local U = ns.ui
  local key, how = ns.talentPathKey()
  local paths = ns.talentPaths()
  for i, p in ipairs(paths) do
    local x = ((i - 1) % 2) * (CARD_W + 8)
    local cy = y + math.floor((i - 1) / 2) * (CARD_H + 8)
    local chosen = p.key == key
    U.box(x, cy, CARD_W, CARD_H, C.panel, chosen and GOLD or C.edge)
    if chosen then U.rect(x + 3, cy + 3, CARD_W - 6, CARD_H - 6, accent(0.16)) end
    local plan = pathPlan(p)
    local first = plan[1]
    U.icon(p.custom and CUSTOM_ICON or (first and first.icon) or CUSTOM_ICON, x + 10, cy + 10, 34)
    U.T(p.spec, x + 54, cy + 8, 150, "head", chosen and C.titleInk or C.light)
    U.T(p.role ~= "" and p.role or " ", x + 54, cy + 32, 150, "small", C.dim)
    local tag = p.guide and "Codex guide" or ""
    if chosen then tag = tag ~= "" and (tag .. "  -  Chosen") or "Chosen" end
    U.T(tag, x + 150, cy + 8, CARD_W - 160, "label", chosen and GOLD or C.goldDim, "RIGHT")
    U.T(p.custom and (#ns.customPoints() .. " of 51 placed") or splitText(plan), x + 150, cy + 32, CARD_W - 160,
      "small", C.light, "RIGHT")
    local tip = plain(p.note or "") .. (p.custom and "" or ("\n\nAt 60: " .. splitText(plan) .. " (" .. table.concat(ns.talentTree().tabs, " / ") .. ")"))
      .. (chosen and "\n\nYou follow this path." or "\n\nClick to follow this path. It's saved for this character.")
    U.hit(x, cy, CARD_W, CARD_H, p.spec .. (p.guide and " (Codex guide)" or ""), tip, function()
      ns.setTalentPath(p.key)
      selectedTalent = nil
      U.refresh()
    end, "Path: " .. p.spec)
  end
  y = y + math.ceil(#paths / 2) * (CARD_H + 8) + 2
  local p = ns.talentPath()
  if p then
    if p.note and p.note ~= "" then y = y + U.T(plain(p.note), 0, y, U.W, "body", C.light) + 4 end
    if not p.guide then
      y = y + U.T("Macros and tips follow the " .. ns.D.spec .. " guide.", 0, y, U.W, "small", C.dim) + 4
    end
    if how == "matched" then
      y = y + U.T("Picked from the talents you have spent. Choose one to keep it.", 0, y, U.W, "small", C.gold) + 4
    end
  end
  return y + 8
end

----------------------------------------------------------------------------
-- The tree: three trees side by side, every talent at the game's row and column
----------------------------------------------------------------------------

local function nodeSpot(px, gy, t)
  return px + 8 + (t.col - 1) * CELL_W + math.floor((CELL_W - NODE) / 2), gy + (t.row - 1) * CELL_H
end

-- Prerequisite lines: from the prerequisite's bottom (or its side) to the talent's top.
local function drawLink(px, gy, from, to, lit)
  local rect = ns.ui.rect
  local fx, fy = nodeSpot(px, gy, from)
  local tx, ty = nodeSpot(px, gy, to)
  local color = lit and GOLD or { 0.45, 0.45, 0.45, 0.8 }
  local cx = tx + NODE / 2 - 1
  if from.col == to.col then
    rect(cx, fy + NODE, 2, math.max(0, ty - fy - NODE), color, "border", 2)
  else
    -- out of the prerequisite's side, then down into the talent
    local midY = fy + NODE / 2 - 1
    if from.col < to.col then rect(fx + NODE, midY, math.max(0, cx + 2 - fx - NODE), 2, color, "border", 2)
    else rect(cx, midY, math.max(0, fx - cx), 2, color, "border", 2) end
    rect(cx, midY, 2, math.max(0, ty - midY), color, "border", 2)
  end
end

local function drawTrees(m, V, y, sel, editing, onNode)
  local U = ns.ui
  local top = y
  local height = 34 + 7 * CELL_H + 4
  for tab = 1, 3 do
    local px = (tab - 1) * (TREE_W + TREE_GAP)
    U.box(px, top, TREE_W, height, C.panel, C.edge)
    local got = 0
    for _, t in ipairs(m.talents) do
      if t.tab == tab then got = got + rankAt(t, V) end
    end
    U.T(m.tabs[tab], px + 10, top + 10, TREE_W - 50, "label", C.gold)
    U.T(tostring(got), px + 10, top + 10, TREE_W - 20, "label", got > 0 and C.light or C.dim, "RIGHT")
    local gy = top + 34
    for _, t in ipairs(m.talents) do
      if t.tab == tab then
        for _, pn in ipairs(t.prereq or {}) do
          local from = m.byName[pn]
          if from and from.tab == tab then drawLink(px, gy, from, t, rankAt(from, V) >= from.max) end
        end
      end
    end
    for _, t in ipairs(m.talents) do
      if t.tab == tab then
        local nx, ny = nodeSpot(px, gy, t)
        local r, nextP, here = rankAt(t, V)
        if here then U.rect(nx - 5, ny - 5, NODE + 10, NODE + 10, accent(0.5), "border", 0) end
        if t == sel then outline(nx - 3, ny - 3, NODE + 6, NODE + 6, GOLD) end
        local f = U.icon(t.icon, nx, ny, NODE)
        local blocked
        if editing then blocked = select(2, ns.talentCanAdd(ns.customPoints(), t.name)) end
        local rankInk
        if r == 0 then
          f.tex:SetDesaturated(true); f.tex:SetVertexColor(0.65, 0.65, 0.65)
          f.ring:SetColorTexture(0.38, 0.38, 0.38, 0.9)
          rankInk = { 0.75, 0.75, 0.75, 1 }
        elseif r >= t.max then
          f.ring:SetColorTexture(1, 0.82, 0, 1); rankInk = GOLD
        else
          f.ring:SetColorTexture(0.3, 0.9, 0.35, 1); rankInk = { 0.4, 1, 0.45, 1 }
        end
        if editing and blocked then f.tex:SetVertexColor(0.45, 0.45, 0.45) end
        f:SetScript("OnClick", function() onNode(t) end)
        f.tipTitle = t.name .. "  " .. r .. "/" .. t.max
        local lead
        if editing then
          lead = blocked and (blocked .. ". ") or ("Click to put level " .. (10 + #ns.customPoints()) .. "'s point here. ")
        else
          lead = (here and ("Level " .. V .. ": your point goes here. ") or "") ..
            (nextP and ("Next point at level " .. nextP.level .. ". ") or (#t.points > 0 and "All points taken. " or "Not in this path. "))
        end
        f.tipText = lead .. plain(t.tip or "") .. (editing and "" or "\n\nClick for every point and why.")
        -- rank tag on the corner, like the talent window
        U.rect(nx + 12, ny + 20, 22, 13, { 0, 0, 0, 0.88 }, nil, 0, nil, true)
        U.T(r .. "/" .. t.max, nx + 12, ny + 20, 22, "small", rankInk, "CENTER", true)
        if not editing then
          if here then
            U.T("NOW", nx - 5, ny + NODE + 2, NODE + 10, "label", C.gold, "CENTER")
          elseif nextP then
            U.T("Lv " .. nextP.level, nx - 5, ny + NODE + 2, NODE + 10, "small", C.dim, "CENTER")
          end
        end
      end
    end
  end
  return top + height + 12
end

----------------------------------------------------------------------------
-- The tab
----------------------------------------------------------------------------

function ns.renderTalents(V)
  local U = ns.ui
  local W, T = U.W, U.T
  local y = U.sectionTitle("Talent paths", 0, "pick how you spend your points  -  saved for this character")
  if not ns.talentTree() then
    return y + T("No talent tree for your class yet.", 0, y, W, "body", C.dim) + 10
  end
  y = drawCards(y)
  local path = ns.talentPath()
  local custom = path and path.custom
  local editing = custom and ns.talentEditing and ns.talentEditing()
  if custom and ns.drawCustomEditor then y = ns.drawCustomEditor(y) end
  local plan = ns.talentPlan()
  local m = model(plan)
  local shownLevel = editing and 60 or V
  y = y + U.sectionTitle("Talent tree", y, editing and "click a talent to place your next point"
    or ("your path at level " .. V .. "  -  click a talent for every point"))
  local sel = selectedTalent and m.byName[selectedTalent]
  if not sel then
    local hit = ns.talentAt(math.max(10, V))
    sel = hit and m.byName[hit.name]
  end
  y = drawTrees(m, shownLevel, y, sel, editing, function(t)
    if editing then
      ns.customAdd(t.name)
    else
      selectedTalent = t.name
    end
    U.refresh()
  end)

  -- the selected talent: the game's tooltip, every point the path puts into it, and why
  if sel and not editing then
    local top = y
    y = y + 14
    local r = rankAt(sel, V)
    U.icon(sel.icon, 16, y, 40, sel.name, nil)
    T(sel.name, 66, y, W - 90, "head", C.ink)
    T(m.tabs[sel.tab] .. "  -  " .. r .. "/" .. sel.max .. " at level " .. V, 66, y + 22, W - 90, "small", C.inkSoft)
    y = y + 50
    y = y + T(plain(sel.tip or ""), 16, y, W - 32, "small", C.inkSoft) + 10
    if #sel.points == 0 then
      y = y + T("This path doesn't take " .. sel.name .. ".", 16, y, W - 32, "body", C.ink) + 6
    end
    for _, p in ipairs(sel.points) do
      local now, past = p.level == V, p.level < V
      local h = T(plain(p.text), 110, y + 3, W - 130, "body", past and C.inkSoft or C.ink)
      local rowH = math.max(20, h + 6)
      if now then U.rect(10, y - 2, W - 20, rowH + 2, accent(0.22), nil, 4) end
      T("Level " .. p.level, 16, y + 4, 60, "label", past and C.inkSoft or C.ink)
      T(p.rank .. "/" .. sel.max, 76, y + 4, 30, "label", past and C.inkSoft or C.ink, "CENTER")
      y = y + rowH + 4
    end
    y = y + 8
    U.box(0, top, W, y - top, C.parch, C.edge)
    y = y + 14
  end

  -- every point in order (click one to see that level)
  T("EVERY POINT, IN ORDER", 0, y, W, "label", C.gold)
  T("click a level to open it", 0, y, W - 6, "small", C.dim, "RIGHT")
  y = y + 20
  local me = UnitLevel("player")
  for l = 10, 60 do
    local hit, rank, text = ns.talentAt(l)
    if hit or ns.talentUnplanned(l) then
      if l == V then U.rect(0, y, W, 28, accent(0.18), nil, 2) end
      if l == me then U.rect(0, y, 3, 28, C.edge, "border") end
      T(tostring(l), 8, y + 7, 30, "label", l <= me and C.goldDim or C.gold, "RIGHT")
      if hit then
        U.icon(hit.icon, 46, y + 2, 24, hit.name, plain(text))
        T(hit.name .. "  " .. rank .. "/" .. hit.max, 80, y + 7, 330, "body", l < me and C.dim or C.light)
        T(hit.tree, 0, y + 8, W - 10, "small", C.dim, "RIGHT")
        U.hit(0, y, W, 28, "Level " .. l .. ": " .. hit.name .. " " .. rank .. "/" .. hit.max, plain(text),
          function() U.openLevel(l) end)
      else
        T("Not planned yet", 80, y + 7, 330, "body", C.dim)
        U.hit(0, y, W, 28, "Level " .. l .. ": not planned yet", "Place this point in the tree above.",
          function() U.openLevel(l) end)
      end
      y = y + 30
    end
  end
  return y + 8
end
