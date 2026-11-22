-- JourneyQuestLog.lua: the journal's Quest Log page (after JourneyTales.lua). Every quest in your
-- log, grouped under the game log's own zone headings, like the game's quest log: a list on the
-- left (level in its difficulty colour, the title, the progress), the chosen quest as a page of the
-- journal on the right (where and when you took it up, who gave it and who waits for it, its goals
-- with bars, the XP it gives, and the line the journal will write when you finish it), with Show
-- in guide / Track / Abandon (two clicks). Read-only toward the game except Track and Abandon.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local function try(...) return Q.try(...) end

local L = {}
J.questLog = L

local selected -- quest ID shown on the right, kept for the session
local confirmAbandon, confirmAt

local function now() return time and time() or 0 end

-- The game log's zone headings: questID -> heading (modern, else the classic log).
function L.headings()
  local out = {}
  local heading
  local modern = try(C_QuestLog and C_QuestLog.GetNumQuestLogEntries)
  local classic = try(GetNumQuestLogEntries) or 0
  for i = 1, math.max(tonumber(modern) or 0, tonumber(classic) or 0) do
    local info = try(C_QuestLog and C_QuestLog.GetInfo, i)
    if type(info) == "table" then
      if info.isHeader then heading = info.title
      elseif info.questID then out[info.questID] = heading end
    elseif i <= classic then
      local title, _, _, isHeader, _, _, _, id = try(GetQuestLogTitle, i)
      if isHeader then heading = title elseif id then out[id] = heading end
    end
  end
  return out
end

-- The quest's level against yours: the game's difficulty bands, in inks that read on parchment
-- and on the dark list.
local DIFF = {
  { "Far too hard", { 0.85, 0.15, 0.1 }, { 1, 0.3, 0.25 } },
  { "Hard", { 0.8, 0.4, 0.05 }, { 1, 0.55, 0.2 } },
  { "Fair", { 0.6, 0.48, 0.0 }, { 1, 0.85, 0.2 } },
  { "Easy", { 0.12, 0.5, 0.12 }, { 0.35, 0.9, 0.35 } },
  { "Trivial", { 0.42, 0.42, 0.42 }, { 0.6, 0.6, 0.6 } },
}
function L.difficulty(qlevel, plevel)
  qlevel, plevel = tonumber(qlevel), tonumber(plevel) or 1
  if not qlevel or qlevel <= 0 then return DIFF[3] end
  local d = qlevel - plevel
  if d >= 5 then return DIFF[1] elseif d >= 3 then return DIFF[2] elseif d >= -2 then return DIFF[3] end
  local green = tonumber(try(GetQuestGreenRange)) or (5 + math.floor(plevel / 10))
  if -d <= green then return DIFF[4] end
  return DIFF[5]
end

-- A quest's progress: done goals of all, and a share 0-1 (finished goals count whole).
local function progress(entry)
  local done, total, share = 0, 0, 0
  for _, o in ipairs(entry.objectives or {}) do
    if o.text or o.numRequired then
      total = total + 1
      local fin = o.finished == true or o.finished == 1
      if fin then done = done + 1 end
      local need, have = tonumber(o.numRequired), tonumber(o.numFulfilled)
      share = share + (fin and 1 or (need and need > 0 and have and math.min(1, have / need)) or 0)
    end
  end
  if entry.ready then return total, total, 1 end
  return done, total, total > 0 and share / total or 0
end

-- The route's accept and turn-in NPCs for a quest (nil when the route doesn't know it).
local givers
local function giver(id)
  if not givers then
    givers = {}
    local rows = Q.rows()
    for _, row in ipairs(type(rows) == "table" and rows or {}) do
      local s = row.step
      if s and s.quest and s.type == "accept" and type(s.npc) == "string" and not givers[s.quest] then
        givers[s.quest] = Q.plain(s.npc)
      end
    end
  end
  return givers[id]
end

local function ago(t)
  local secs = now() - (tonumber(t) or now())
  if secs < 3600 then return "less than an hour ago" end
  if secs < 86400 then local h = math.floor(secs / 3600); return h .. (h == 1 and " hour ago" or " hours ago") end
  local d = math.floor(secs / 86400)
  return d .. (d == 1 and " day ago" or " days ago")
end

-- The quests in your log as { id, entry, title, heading } sorted by heading, then level.
function L.quests()
  local heads = L.headings()
  local out = {}
  for id, entry in pairs(Q.logEntries()) do
    local row = Q.questMatch(id)
    local heading = heads[id]
    if not heading and row and row.step.map then heading = select(2, J.zoneOf(row.step.map)) end
    out[#out + 1] = { id = id, entry = entry, heading = Q.plain(heading or "Other quests"),
      title = Q.plain(entry.title or (row and row.step.name) or Q.questName(id) or ("Quest " .. id)), row = row }
  end
  -- your zone's heading first, then the others in order
  local _, here = J.here()
  table.sort(out, function(a, b)
    if a.heading ~= b.heading then
      if a.heading == here then return true elseif b.heading == here then return false end
      return a.heading < b.heading
    end
    local la, lb = tonumber(a.entry.level) or 0, tonumber(b.entry.level) or 0
    if la ~= lb then return la < lb end
    return a.title < b.title
  end)
  return out
end

local function listRow(V, q, x, y, w, on, plevel)
  local U, C = V.U, V.C
  local diff = L.difficulty(q.entry.level, plevel)
  local done, total = progress(q.entry)
  if on then
    U.rect(x, y, w, 24, C.wash)
    U.rect(x, y, 3, 24, C.gold)
  end
  local lvl = tonumber(q.entry.level)
  U.T(lvl and lvl > 0 and ("[" .. lvl .. "]") or "[?]", x + 8, y + 5, 34, "small", C.book and diff[2] or diff[3])
  local _, fs = U.T(q.title, x + 40, y + 5, w - 96, "small", on and C.light or (q.row and C.light or C.dim))
  if fs.SetWordWrap then fs:SetWordWrap(false) end
  if q.entry.ready then
    U.T("Done", x + w - 56, y + 5, 50, "small", C.green, "RIGHT")
  elseif total > 0 then
    U.T(done .. "/" .. total, x + w - 56, y + 5, 50, "small", C.dim, "RIGHT")
  end
  U.hit(x, y, w, 24, q.title, (q.entry.ready and "Ready to turn in." or diff[1] .. " for your level.")
    .. " Click to read it in the journal.", function()
    selected, confirmAbandon = q.id, nil
    ns.ui.refresh()
  end, "Quest " .. q.title)
  return 24
end

-- The chosen quest as a page of the journal; returns its height.
local function questPage(V, q, x, y, w)
  local U, C = V.U, V.C
  local D = J.draw
  local top = y
  local id, entry = q.id, q.entry
  local tw = w - 28
  local diff = L.difficulty(entry.level, V.lvl)
  y = y + 14
  local lvl = tonumber(entry.level)
  U.T((lvl and lvl > 0 and ("LEVEL " .. lvl .. " QUEST") or "QUEST") .. "  -  " .. q.heading:upper(), x + 14, y, tw, "label", C.inkSoft)
  y = y + 16
  y = y + U.T(q.title, x + 14, y, tw, "head", C.ink) + 6
  U.rect(x + 14, y + 5, 24, 3, diff[2])
  U.T(diff[1] .. " for level " .. V.lvl, x + 44, y, tw - 30, "small", diff[2])
  y = y + 18
  -- when and where you took it up
  local taken = J.tales and J.tales.taken(id)
  local line
  if taken then
    local where = taken.m and select(2, J.zoneOf(taken.m))
    line = "Taken up " .. ago(taken.t) .. (where and (" in " .. Q.plain(where)) or "") .. ", at level " .. (taken.l or "?")
      .. " (day " .. D.dayOf(V.j, taken.t) .. ")."
  else
    line = "Taken up before the journal began."
  end
  y = y + U.T(line, x + 14, y, tw, "small", C.inkSoft) + 4
  local from, to = giver(id), J.finisher and J.finisher(id)
  if from or to then
    local who = from and to and from ~= to and ("From " .. from .. ". " .. to .. " waits for word of it.")
      or from and ("From " .. from .. ", who waits for word of it.") or (to .. " waits for word of it.")
    y = y + U.T(who, x + 14, y, tw, "small", C.inkSoft) + 4
  end
  -- the goals
  y = y + 6
  U.rect(x + 14, y, tw, 1, { 0, 0, 0, 0.15 }, "border")
  y = y + 8
  U.T("GOALS", x + 14, y, tw, "label", C.inkSoft)
  y = y + 16
  local any = false
  for _, o in ipairs(entry.objectives or {}) do
    if o.text and o.text ~= "" then
      any = true
      local fin = entry.ready or o.finished == true or o.finished == 1
      local need, have = tonumber(o.numRequired), tonumber(o.numFulfilled)
      local share = fin and 1 or (need and need > 0 and have and math.min(1, have / need)) or 0
      U.rect(x + 14, y + 4, 8, 8, fin and { 0.12, 0.5, 0.12 } or { 0, 0, 0, 0.35 }, "border")
      local h = U.T(Q.plain(o.text), x + 30, y, tw - 16, "small", fin and { 0.12, 0.45, 0.12 } or C.ink)
      y = y + h + 3
      if need and need > 1 then
        U.rect(x + 30, y, tw - 16, 4, { 0, 0, 0, 0.15 })
        U.rect(x + 30, y, math.max(2, (tw - 16) * share), 4, fin and { 0.15, 0.6, 0.15 } or diff[2])
        y = y + 8
      end
      y = y + 3
    end
  end
  if not any then
    y = y + U.T(entry.ready and "Nothing left to do: go and tell them." or "The log gives no goals for this one: read it in the game's quest log.",
      x + 14, y, tw, "small", C.inkSoft) + 6
  end
  if entry.ready then
    y = y + U.T("Ready to turn in" .. (to and (" to " .. to) or "") .. ".", x + 14, y, tw, "body", { 0.12, 0.45, 0.12 }) + 6
  end
  local xp = tonumber(try(GetQuestLogRewardXP, id))
  local cash = tonumber(try(GetQuestLogRewardMoney, id))
  if (xp and xp > 0) or (cash and cash > 0) then
    local parts = {}
    if xp and xp > 0 then parts[#parts + 1] = ns.thousands(xp) .. " XP" end
    if cash and cash > 0 then parts[#parts + 1] = ns.money(cash) end
    y = y + U.T("Reward: " .. table.concat(parts, " and "), x + 14, y, tw, "small", C.inkSoft) + 6
  end
  -- what the journal will say
  y = y + 4
  U.rect(x + 14, y, tw, 1, { 0, 0, 0, 0.15 }, "border")
  y = y + 8
  local ok, story = pcall(J.questLine, id, q.title, q.heading)
  if ok and type(story) == "string" then
    U.T("WHEN IT'S DONE, THE JOURNAL WILL READ", x + 14, y, tw, "label", C.inkSoft)
    y = y + 16
    y = y + U.T('"' .. Q.plain(story) .. '"', x + 14, y, tw, "body", C.ink) + 8
  end
  -- what you can do with it
  local bw = math.floor((tw - 16) / 3)
  local bx = x + 14
  if q.row then
    U.btn("Show in guide", bx, y, bw, function()
      Q.followQuest(q.row)
      ns.showQuestViewer()
    end, false, "Follow the guide's step for this quest in the step window.")
  end
  if not entry.ready then
    local pinned = false
    for _, p in ipairs(Q.pins()) do if p == id then pinned = true end end
    local b = U.btn(pinned and "Untrack" or "Track", bx + bw + 8, y, bw, function()
      if Q.togglePin(id) then ns.questRefresh() else ns.say("you can track up to three quests.") end
      ns.ui.refresh()
    end, pinned, "Keep this quest's progress in the step window.")
    b.codexLabel = (pinned and "Untrack " or "Track ") .. q.title
  end
  local armed = confirmAbandon == id and confirmAt and (GetTime() - confirmAt) < 5
  local ab = U.btn(armed and "Click again" or "Abandon", bx + 2 * (bw + 8), y, bw, function()
    if armed then
      confirmAbandon = nil
      Q.abandon(id)
      selected = nil
    else
      confirmAbandon, confirmAt = id, GetTime()
    end
    ns.ui.refresh()
  end, armed, "Give up on this quest. Click twice to confirm; the journal remembers it.")
  ab.codexLabel = armed and "Click again to abandon" or ("Abandon " .. q.title)
  y = y + 34
  D.page(U, C, x, top, w, y - top)
  return y - top
end

local QUOTES = { "Every quest is a promise made to someone in Azeroth.", "Somewhere out there, people are counting on you.",
  "A full log is a busy hero.", "Each page here is a road not yet walked." }

local function questLogPage(V, y)
  local LV, RV = V.L, V.R
  local U, C, W = LV.U, LV.C, LV.W
  local D = J.draw
  local quests = L.quests()
  local count, max = Q.logCapacity()
  local ready, tracked, outside = 0, #Q.pins(), 0
  for _, q in ipairs(quests) do
    if q.entry.ready then ready = ready + 1 end
    if not q.row then outside = outside + 1 end
  end
  -- the left page: the banner, then the list
  local top = y
  U.icon("INV_Misc_Book_08", 14, y + 14, 34, "Quest Log", "Every quest in your log, as the game's quest log keeps them.")
  U.T("THE QUEST LOG", 58, y + 12, W - 140, "label", C.inkSoft)
  U.T(#quests == 1 and "One quest in hand" or (#quests .. " quests in hand"), 58, y + 26, W - 140, "head", C.ink)
  if max then U.T(count .. " of " .. max, W - 100, y + 14, 86, "head", C.ink, "RIGHT") end
  local facts = {}
  if ready > 0 then facts[#facts + 1] = ready .. " ready to turn in" end
  if tracked > 0 then facts[#facts + 1] = tracked .. " tracked" end
  if outside > 0 then facts[#facts + 1] = outside .. " not in your guide" end
  local h = U.T(#facts > 0 and table.concat(facts, "  -  ") or QUOTES[(#quests % #QUOTES) + 1], 58, y + 50, W - 72, "small", C.inkSoft)
  y = y + 50 + h + 12
  D.page(U, C, 0, top, W, y - top)
  y = y + 12
  if #quests == 0 then
    local ry = y
    ry = ry + 16 + RV.U.T("Your quest log is empty. Somewhere a quest giver is waiting with a golden mark over their head.",
      16, ry + 16, RV.W - 32, "body", RV.C.ink) + 16
    D.page(RV.U, RV.C, 0, y, RV.W, ry - y)
    return y, ry + 10
  end
  local found
  for _, q in ipairs(quests) do if q.id == selected then found = q end end
  if not found then
    for _, q in ipairs(quests) do if q.entry.ready then found = q; break end end
    found = found or quests[1]
    selected = found.id
  end
  local ly = y
  local heading
  for _, q in ipairs(quests) do
    if q.heading ~= heading then
      heading = q.heading
      if ly > y then ly = ly + 4 end
      U.T(heading:upper(), 12, ly + 8, W - 24, "label", C.gold)
      ly = ly + 26
    end
    ly = ly + listRow(LV, q, 4, ly, W - 8, q.id == selected, V.lvl)
  end
  ly = ly + 8
  U.box(0, y, W, ly - y, C.panel, C.edge)
  -- the right page: the chosen quest
  local ph = questPage(RV, found, 0, top, RV.W)
  return ly + 10, top + ph + 10
end

J.addPage("Quest Log", "Every quest in your log, as the game's quest log keeps them, each a page of the journal.",
  questLogPage, "Story")
