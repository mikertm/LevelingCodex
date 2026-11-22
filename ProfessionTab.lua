-- ProfessionTab.lua: the Professions tab of the /codex window. What to do at your skill (the
-- recipe, how many more, materials against your bags, where to learn it), training when it's
-- due, the whole route, and a shopping list to 300. Gathering guides show nodes for your faction,
-- Tailoring the cloth (mob levels and zones), and its shopping list counts bolts as their cloth.

local _, ns = ...
local C, plain = ns.C, ns.plain

local shown        -- profession key on screen (nil = pick one you have)
local pending      -- restore this selection if a temporary read failure clears
local picked = {}  -- key -> { index = step clicked in the route, at = your skill then }
local displayed = {}  -- last rendered reading can differ from the skill-up watcher's
local browse       -- a guide you haven't learned, opened from Other guides (shown as at skill 1)
local grid = false -- the Other guides picker is open
local shopAll = false -- this session: the shopping list counts to 300, not to your cap

local function choose(key)
  shown, pending, browse, grid = key, nil, nil, false
end

function ns.profTabSkillsChanged(snapshot)
  for key, preview in pairs(picked) do
    local reading = snapshot[key]
    if reading and not (reading.hidden or reading.unavailable) and reading.rank ~= preview.at then
      picked[key] = nil
    end
  end
  for _, key in ipairs(ns.PROF_ORDER) do
    local before, after = displayed[key] or {}, snapshot[key] or {}
    if before.rank ~= after.rank or before.cap ~= after.cap or before.hidden ~= after.hidden
      or before.unavailable ~= after.unavailable then
      ns.refreshProfessionTab(snapshot)
      return
    end
  end
end

function ns.profTabShow(key)
  if ns.profSkill(key) then choose(key) end
end

local function recipeColor(step, skill)
  if skill < step.yellow then return "orange" end
  if skill < math.floor((step.yellow + step.grey) / 2) then return "yellow" end
  if skill < step.grey then return "green" end
  return "grey"
end

local function colorsLine(step)
  local green = math.floor((step.yellow + step.grey) / 2)
  return "Turns yellow at " .. step.yellow .. ", green at " .. green .. " and grey at " .. step.grey .. "."
end

local function have(item)
  if not GetItemCount then return nil end
  local ok, n = pcall(GetItemCount, item)
  return ok and tonumber(n) or nil
end

-- "Blacksmithing, Mining and Tailoring": the guided professions' names.
local function profNames()
  local names = {}
  for _, k in ipairs(ns.PROF_ORDER) do
    if ns.P and ns.P[k] then names[#names + 1] = ns.P[k].name end
  end
  if #names <= 1 then return names[1] or "" end
  return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

-- Which step the Now card shows: one you clicked (until your skill changes), else yours.
local function viewStep(key, P, skill)
  local p = picked[key]
  if p and p.at == skill and P.steps[p.index] then return P.steps[p.index], p.index, true end
  picked[key] = nil
  local s, i = ns.profStep(key, skill or 1)
  return s, i, false
end

local function smeltNamed(P, name)
  for _, s in ipairs(P.smelt or {}) do if s.name == name then return s end end
end

local function smeltLine(P, step)
  local parts = {}
  for _, name in ipairs(step.smelt or {}) do
    local s = smeltNamed(P, name)
    if s and s.grey > s.learn then
      local until_ = s.yellow > s.learn and ("orange until " .. s.yellow) or ("points until " .. s.grey)
      parts[#parts + 1] = s.makes .. " (" .. until_ .. ")"
    end
  end
  if #parts == 0 then return "Mine veins to gain skill in this range." end
  return "Smelting can also give skill points. " .. table.concat(parts, ", ") .. "."
end

local function renderer(_, snapshot)
  local ui = ns.ui
  local W, T, box, icon, btn, rect, hit = ui.W, ui.T, ui.box, ui.icon, ui.btn, ui.rect, ui.hit
  local y = ui.sectionTitle("Professions", 0)
  local names = profNames()
  if names == "" then return y + T("No profession guides in this build.", 0, y, W, "body", C.dim) + 10 end

  snapshot = snapshot or ns.profSkillSnapshot()
  displayed = snapshot
  local learned, hidden, unavailable = {}, false, false
  for _, key in ipairs(ns.PROF_ORDER) do
    local reading = snapshot[key]
    if reading then
      if reading.rank then learned[#learned + 1] = key end
      hidden = hidden or reading.hidden
      unavailable = unavailable or reading.unavailable
    end
  end

  if pending then
    local reading = snapshot[pending]
    if reading and reading.rank then choose(pending)
    elseif not (reading and (reading.hidden or reading.unavailable)) then pending = nil end
  end
  local selected = shown and snapshot[shown]
  if not (selected and selected.rank) then
    if not pending and selected and (selected.hidden or selected.unavailable) then pending = shown end
    shown = learned[1]
  end

  if hidden then
    y = y + T("In the character window, open Skills and expand Professions.",
      0, y, W, "body", C.dim) + 10
  end
  if unavailable then y = y + T("Profession skills are unavailable right now.", 0, y, W, "body", C.dim) + 10 end
  if browse and snapshot[browse] and snapshot[browse].rank then choose(browse) end -- learned it meanwhile

  -- the switch: your guides, then Other guides (the ones the client says you haven't learned: a
  -- closed Skills heading or a failed read could be hiding one you have)
  local others = {}
  for _, k in ipairs(ns.PROF_ORDER) do
    local r = snapshot[k]
    if ns.P[k] and r and not (r.rank or r.hidden or r.unavailable) then others[#others + 1] = k end
  end
  if #learned == 0 and #others == 0 then return y end
  local picker = grid or not (browse or shown)
  if #learned > 0 or browse then
    local n = #learned + (#others > 0 and 1 or 0)
    local per = math.min(n, 5)
    local bw = math.min(140, math.floor((W - 6 * (per - 1)) / per))
    local function place(i) return ((i - 1) % per) * (bw + 6), y + math.floor((i - 1) / per) * 28 end
    for i, k in ipairs(learned) do
      local name = ns.P[k].name
      local bx, by = place(i)
      btn(name, bx, by, bw, function() choose(k); ui.refresh() end, k == shown and not (browse or grid), "Show the " .. name .. " guide.")
    end
    if #others > 0 then
      local bx, by = place(n)
      btn(#learned > 0 and "Other guides" or "All guides", bx, by, bw, function() grid = not grid; ui.refresh() end, picker or browse ~= nil,
        "Browse trainers, leveling routes and shopping lists for other professions.")
    end
    y = y + math.ceil(n / per) * 28 + 6
  end
  if picker then
    T(#learned > 0 and "OTHER PROFESSION GUIDES" or "PROFESSION GUIDES", 0, y, W, "label", C.gold)
    y = y + 18
    if #learned == 0 and not (hidden or unavailable) then
      y = y + T("No supported professions learned yet.", 0, y, W, "body", C.dim) + 4
    end
    local per = 4
    local gw = math.floor((W - 6 * (per - 1)) / per)
    for i, k in ipairs(others) do
      local name = ns.P[k].name
      btn(name, ((i - 1) % per) * (gw + 6), y + math.floor((i - 1) / per) * 28, gw, function()
        browse, grid = k, false
        ui.refresh()
      end, k == browse, "Open the " .. name .. " guide from skill 1.")
    end
    return y + math.ceil(#others / per) * 28 + 10
  end

  local key = browse or shown
  local P = ns.P[key]
  local reading = snapshot[key] or {}
  local skill, cap = reading.rank, reading.cap
  local level = UnitLevel("player") or 1

  -- header card: your skill (or where to learn a guide you're browsing)
  local top = y
  y = y + 14
  icon(P.icon, 16, y, 40, P.name, nil)
  if skill then
    T(P.name .. " " .. skill .. (cap and (" / " .. cap) or ""), 66, y + 2, W - 90, "head", C.ink)
    local tier = ns.profTier(key, skill, cap)
    local barY = y + 26
    if tier then barY = barY + T(tier.name, 66, barY, W - 90, "small", C.inkSoft) + 5 end
    if cap and cap > 0 then
      local width = W - 88
      rect(66, barY, width, 4, { 0, 0, 0, 0.24 }, "border")
      rect(66, barY, width * math.min(1, skill / cap), 4, C.accent, "border", 1)
    end
    y = math.max(y + 52, barY + 15)
  else
    T(P.name .. "  -  not learned", 66, y + 2, W - 90, "head", C.ink)
    local h = T(plain(P.tiers[1].where) .. ".", 66, y + 26, W - 90, "small", C.inkSoft)
    y = y + math.max(50, 30 + h)
  end
  box(0, top, W, y - top, C.parch, C.edge)
  y = y + 12

  -- training
  if skill then
    local due, nextTier = ns.profTierDue(key, skill, cap, level)
    if due then
      local action = nextTier.action or "Train"
      top = y
      y = y + 12
      if P.levelGatesUnconfirmed then
        local title = due == "cap" and "AT YOUR CAP" or "CHECK " .. string.upper(nextTier.name)
        T(title, 16, y, W - 32, "label", C.gold)
        y = y + 18
        y = y + T("Ask a trainer about " .. nextTier.name .. " at skill " .. nextTier.skill .. " for a cap of " .. nextTier.cap ..
          ". The character level requirement is unconfirmed. " .. plain(nextTier.where) .. ".",
          16, y, W - 32, "body", C.light) + 10
      elseif due == "train" then
        T(string.upper(action .. " " .. nextTier.name), 16, y, W - 32, "label", C.gold)
        y = y + 18
        y = y + T("Raises your cap to " .. nextTier.cap .. ". Requires skill " .. nextTier.skill .. " and character level " .. nextTier.level ..
          ". " .. plain(nextTier.where) .. ".", 16, y, W - 32, "body", C.light) + 10
      else
        local trained = ns.profTier(key, skill, cap)
        T("AT YOUR CAP", 16, y, W - 32, "label", C.gold)
        y = y + 18
        y = y + T(action .. " " .. nextTier.name .. " at " .. nextTier.skill .. " (level " .. nextTier.level .. ") to go past " ..
          (trained and trained.cap or cap or skill) .. ". " .. plain(nextTier.where) .. ".", 16, y, W - 32, "body", C.light) + 10
      end
      for _, m in ipairs(nextTier.mats or {}) do
        local count = have(m[1])
        local label = m[2] .. " " .. m[1] .. (count and (" (you have " .. count .. ")") or "")
        y = y + T(label, 16, y, W - 32, "body", C.light) + 6
      end
      for _, objective in ipairs(nextTier.objectives or {}) do
        y = y + T(plain(objective), 16, y, W - 32, "body", C.light) + 6
      end
      box(0, top, W, y - top, C.panel, C.edge)
      y = y + 12
    end
  end

  -- the step to do now (or the one clicked in the route)
  local step, index, browsing = viewStep(key, P, skill)
  top = y
  y = y + 14
  if not step then
    T("ROUTE COMPLETE", 16, y, W - 32, "label", C.inkSoft)
    y = y + 18
    y = y + T("You reached " .. (skill or 300) .. " " .. P.name .. ".", 16, y, W - 32, "body", C.ink) + 14
  else
    local label = browsing and "STEP PREVIEW" or (skill and "CURRENT STEP" or "FIRST STEP")
    T(label, 16, y, W / 2 - 16, "label", C.inkSoft)
    T("Skill " .. step.from .. "-" .. step.to, W / 2, y, W / 2 - 16, "label", C.inkSoft, "RIGHT")
    y = y + 22
  end
  if step and step.name then
    icon(step.icon, 16, y, 46, step.name, plain(step.note))
    local from = (skill and not browsing) and skill or step.from
    local n = ns.craftsLeft(step, from) or 0
    local h = T(step.name, 74, y, W - 100, "head", C.ink)
    local sub = "About " .. n .. (n == 1 and " craft" or " crafts") .. " to skill " .. step.to
    if skill and not browsing then sub = sub .. "  |  " .. recipeColor(step, skill):gsub("^%l", string.upper) end
    local subH = T(sub, 74, y + h + 3, W - 100, "small", C.inkSoft)
    y = y + math.max(54, h + subH + 12)
    y = y + T(colorsLine(step), 16, y, W - 32, "small", C.inkSoft) + 6
    local source = plain(step.source)
    if not source:find("^Known when") then source = source .. " (skill " .. step.learn .. ")" end
    y = y + T(source, 16, y, W - 32, "small", C.inkSoft) + 8
    if step.tools then
      y = y + T("Tools: " .. table.concat(step.tools, ", "), 16, y, W - 32, "small", C.inkSoft) + 6
    end
    if step.station then
      y = y + T("Station: " .. step.station, 16, y, W - 32, "small", C.inkSoft) + 6
    end
    local rod = ns.profRod(key, step)
    if rod then
      local got = ns.profHasRod(key, rod)
      local line = "Rod: " .. rod.name
      if got == true then
        line = line .. " (you have it)"
      elseif got == false then
        local m = {}
        for _, x in ipairs(rod.mats or {}) do m[#m + 1] = x[2] .. " " .. x[1] end
        line = line .. " - you need it: " .. table.concat(m, ", ") .. " (learn at " .. rod.learn .. ")"
      end
      y = y + T(line, 16, y, W - 32, "small", got == false and C.gold or C.inkSoft) + 8
    end
    local mats = step.mats or {}
    if #mats > 0 then
      rect(16, y + 2, W - 32, 1, { 0, 0, 0, 0.18 }, "border")
      y = y + 10
      T("MATERIALS FOR THIS STEP", 16, y, W - 128, "label", C.inkSoft)
      if GetItemCount then T("IN BAGS", W - 110, y, 94, "label", C.inkSoft, "RIGHT") end
      y = y + 18
    end
    for _, m in ipairs(mats) do
      local got = have(m[1])
      local needed = n * m[2]
      if got then T(tostring(got), W - 110, y, 94, "body", got >= needed and C.ink or C.inkSoft, "RIGHT") end
      y = y + math.max(18, (T(needed .. " " .. m[1], 16, y, W - 128, "body", C.ink))) + 3
      local part = ns.profPart(key, m[1])
      local src = part and part.mats and part.mats[1]
      if src and ns.profHasRod(key, ns.profRod(key, part)) ~= false then  -- a part that needs a rod you lack can't be made
        local per = part.makes[2]
        local line
        if #part.mats == 1 then
          local h = have(src[1])
          line = "Make them from " .. src[1] .. " (" .. src[2] .. (per > 1 and (" makes " .. per) or " each") .. ")" ..
            (h and (": your " .. h .. " make " .. math.floor(h / src[2]) * per) or "")
        else
          local reagents = {}
          for _, mat in ipairs(part.mats) do reagents[#reagents + 1] = mat[2] .. " " .. mat[1] end
          local nPart = ns.profPartAvailable(part)
          line = "Make " .. per .. " from " .. table.concat(reagents, " + ") ..
            (nPart and (" (you can make " .. nPart .. ")") or "")
        end
        y = y + T(line, 26, y, W - 42, "small", C.inkSoft) + 4
      end
    end
    y = y + 6
    if step.note and step.note ~= "" then y = y + T(plain(step.note), 16, y, W - 32, "body", C.ink) + 6 end
    if step.alt and step.alt ~= "" then y = y + T("Alternative: " .. plain(step.alt), 16, y, W - 32, "small", C.inkSoft) + 6 end
    y = y + 8
  elseif step then -- Gathering
    y = y + T(plain(step.title), 16, y, W - 32, "head", C.ink) + 8
    if step.zones then
      y = y + T("Where: " .. plain(table.concat(ns.profZones(step), ", ")), 16, y, W - 32, "small", C.inkSoft) + 6
    end
    for _, name in ipairs(step.herbs or step.veins or {}) do
      local node = ns.profNode(key, name)
      if node then
        icon(node.icon, 16, y, 30, node.name, node.ore)
        local col = skill and ("  " .. ns.profNodeColor(node, skill)) or ""
        T(node.name .. "  " .. node.skill .. col, 54, y + 1, W - 70, "body", C.ink)
        local h = T("Where: " .. table.concat(ns.profZones(node), ", "), 54, y + 17, W - 70, "small", C.inkSoft)
        y = y + math.max(36, 21 + h)
      end
    end
    if P.smelt then y = y + T(smeltLine(P, step), 16, y, W - 32, "small", C.inkSoft) + 6 end
    if step.note and step.note ~= "" then y = y + T(plain(step.note), 16, y, W - 32, "body", C.ink) + 6 end
    y = y + 8
  end
  box(0, top, W, y - top, C.parch, C.edge)
  y = y + 12

  -- next
  local nxt = step and P.steps[(index or 0) + 1]
  if nxt then
    T("NEXT", 0, y + 4, 45, "label", C.goldDim)
    if nxt.icon then icon(nxt.icon, 52, y, 22, nxt.name or nxt.title, plain(nxt.note)) end
    T(nxt.from .. ": " .. (nxt.name or nxt.title), nxt.icon and 82 or 52, y + 4, W - 90, "body", C.light)
    y = y + 32
  end

  -- the whole route
  T("LEVELING ROUTE", 0, y, W / 2, "label", C.gold)
  T("Select a step to preview", W / 2, y, W / 2 - 10, "small", C.dim, "RIGHT")
  y = y + 20
  T("SKILL", 8, y, 60, "label", C.dim, "RIGHT")
  T("STEP", 78, y, W - 184, "label", C.dim)
  if P.steps[1].name then T("EST. CRAFTS", W - 104, y, 94, "label", C.dim, "RIGHT") end
  y = y + 17
  for i, s in ipairs(P.steps) do
    local mine = skill and skill >= s.from and skill < s.to
    local done = skill and skill >= s.to
    T(s.from .. "-" .. s.to, 8, y + 4, 60, "label", done and C.goldDim or C.gold, "RIGHT")
    local height = math.max(22, 8 + T(s.name or s.title, 78, y + 4, W - 184, "body", done and C.dim or C.light))
    if mine then rect(0, y, 3, height, C.edge, "border") end
    if index == i then rect(0, y, W, height, { C.accent[1], C.accent[2], C.accent[3], 0.18 }, nil, 2)
    elseif i % 2 == 0 then rect(0, y, W, height, { 1, 1, 1, 0.035 }) end
    local n = s.name and ns.craftsLeft(s, s.from)
    if n then T(tostring(n), W - 104, y + 5, 94, "small", C.dim, "RIGHT") end
    hit(0, y, W, height, s.from .. "-" .. s.to .. ": " .. (s.name or s.title), plain(s.note), function()
      -- your own step takes you back to "do this now"
      picked[key] = (not mine) and { index = i, at = skill } or nil
      ui.refresh()
    end)
    y = y + height + 2
    for at, note in pairs(P.notes or {}) do
      if tonumber(at) == s.to then
        y = y + T("At " .. at .. ": " .. plain(note), 78, y, W - 90, "small", C.dim) + 4
      end
    end
  end
  y = y + 10

  -- shopping list (crafting): to your cap (the next one once you're at it) or, picked, to 300
  local limit, which = ns.profShopLimit(key, skill, cap)
  local upto = (limit and not shopAll) and limit or nil
  local list = ns.profShopping(key, skill, cap, upto)
  if #list > 0 or (upto and #ns.profShopping(key, skill, cap) > 0) then
    top = y
    y = y + 12
    T("SHOPPING LIST TO " .. (upto or 300), 16, y, W - 32, "label", C.gold)
    T(skill and ("from " .. skill) or "from 1", 16, y, W - 32, "small", C.dim, "RIGHT")
    y = y + 20
    if limit then
      local mine = which == "cap"
      y = y + ui.segments(16, y, W - 32, { "To " .. limit .. (mine and " (your cap)" or " (next cap)"), "To 300" },
        upto and 1 or 2, function(i)
          shopAll = i == 2
          ui.refresh()
        end, { mine and ("What your steps need before you can train past " .. limit .. ".")
            or ("What you need from your next training up to its cap, " .. limit .. "."),
          "Everything the route needs from your skill to 300." }) + 10
    end
    if #list == 0 then
      y = y + T("Nothing to buy before " .. upto .. ".", 16, y, W - 32, "body", C.light) + 6
    end
    local col = (W - 32) / 2
    local rowH = 0  -- the taller text of the pair: a long cloth row wraps
    for i, m in ipairs(list) do
      local cx = 16 + ((i - 1) % 2) * col
      local text = m[2] .. " " .. m[1]
      if m.via then
        local part = ns.profPart(key, m.via.made or "") or {}
        local shared = part.mats and #part.mats > 1 and m.via.raw < m[2]
        local h = shared and have(m[1]) or ns.profHave(key, m[1])
        local what = part.unit or (m.via.part:find("^Bolt") and "bolts") or "parts"
        local use = shared and ("includes " .. m.via.raw .. " for ") or "for "
        text = text .. " (" .. use .. m.via.n .. " " .. what .. (h and (", you have " .. h) or "") .. ")"
      end
      rowH = math.max(rowH, (T(text, cx, y, col - 8, "body", C.light)))
      if i % 2 == 0 or i == #list then y = y + math.max(18, rowH + 4); rowH = 0 end
    end
    y = y + T("Estimates account for yellow and green recipes, which can take extra crafts.", 16, y + 4, W - 32,
      "small", C.dim) + 14
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
  if P.cloth then
    top = y
    y = y + 12
    T("CLOTH", 16, y, W - 32, "label", C.gold)
    y = y + 20
    local need = ns.profClothFor(key, (ns.profStep(key, skill or 1)))  -- your step's, not a browsed one
    local rows = {}
    for _, c in ipairs(P.cloth) do if c.name == need then rows[#rows + 1] = c end end
    for _, c in ipairs(P.cloth) do if c.name ~= need then rows[#rows + 1] = c end end
    for _, c in ipairs(rows) do
      icon(c.icon, 16, y, 30, c.name, "Humanoids level " .. c.levels)
      T(c.name .. (c.name == need and "  -  you need this now" or ""), 54, y + 1, W - 70, "body",
        c.name == need and C.gold or C.light)
      local h = T("Humanoids level " .. c.levels .. ". Where: " .. table.concat(ns.profZones(c), ", "), 54, y + 17, W - 70, "small", C.dim)
      y = y + math.max(36, 21 + h)
    end
    y = y + T("Thread, dyes and Bleach: Tailoring and trade supply vendors (most trainers have one nearby).", 16, y + 2,
      W - 32, "small", C.dim) + 12
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
  if P.disenchant then
    top = y
    y = y + 12
    T("DISENCHANTING", 16, y, W - 32, "label", C.gold)
    y = y + 20
    y = y + T(plain(P.disenchant.note or ""), 16, y, W - 32, "small", C.inkSoft) + 6
    local need = ns.deNeeded(key, (ns.profStep(key, skill or 1)))
    local function wanted(b)
      return need[b.dust] or need[b.essence] or (b.shard and need[b.shard]) or (b.epic and need[b.epic])
    end
    local rows = {}
    for _, b in ipairs(P.disenchant.bands or {}) do if wanted(b) then rows[#rows + 1] = b end end
    for _, b in ipairs(P.disenchant.bands or {}) do if not wanted(b) then rows[#rows + 1] = b end end
    for _, b in ipairs(rows) do
      local w = wanted(b)
      y = y + T("Item level " .. b.from .. "-" .. b.to .. "  -  " .. b.dust .. ", " .. b.essence ..
        (b.shard and (", " .. b.shard) or "") .. (b.epic and (", " .. b.epic .. " (epic)") or "") ..
        (w and "  -  you need this now" or ""), 16, y, W - 32, "small", w and C.gold or C.light) + 3
    end
    y = y + T("3 Lesser make 1 Greater, and back: right-click the essence.", 16, y + 3, W - 32, "small", C.dim) + 10
    local items = ns.deBagItems(key)
    if items then
      T("IN YOUR BAGS", 16, y, W - 32, "label", C.goldDim)
      y = y + 18
      if #items == 0 then
        y = y + T("No material estimates for gear in your bags.", 16, y, W - 32, "small", C.dim) + 4
      else
        local function gives(it) for _, g in ipairs(it.gives) do if need[g] then return true end end end
        table.sort(items, function(a, b)
          local ga, gb = gives(a) and 1 or 0, gives(b) and 1 or 0
          if ga ~= gb then return ga > gb end
          if a.level ~= b.level then return a.level < b.level end
          return a.name < b.name
        end)
        for i = 1, math.min(8, #items) do
          local it = items[i]
          y = y + T(it.name .. " (item level " .. it.level .. "): " .. table.concat(it.gives, " or "), 16, y, W - 32, "small",
            gives(it) and C.gold or C.light) + 3
        end
      end
    end
    y = y + 8
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
  if P.camp then
    top = y
    y = y + 12
    T("CAMP OBJECTS", 16, y, W - 32, "label", C.gold)
    y = y + 20
    for _, c in ipairs(P.camp) do
      y = y + T(c.skill .. "  " .. c.name .. "  -  " .. plain(c.source) .. ". " .. plain(c.text), 16, y, W - 32, "small", C.light) + 4
    end
    y = y + 8
    box(0, top, W, y - top, C.panel, C.edge)
    y = y + 12
  end
  return y
end

ns.addTab("professions", "Professions", renderer)
