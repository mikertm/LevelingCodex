-- JourneyQuestLines.lua: what a finished quest reads like in the Journey. J.questLine (Journey.lua)
-- knew three shapes (kill, gather, errand) and read only "Name: 0/7" objectives, so Forever's
-- "0/7 Name" turned every collect quest into an errand. This reads the quest's objectives in either
-- order and with the route's data (ns.questMobs, ns.questShop, ns.questNPCs) tells a bounty, a hunt,
-- loot taken from a foe, gathering, shopping, an escort, scouting, a deed at an object, a delivery
-- or an errand; each kind has a deep pool of lines, foe families add their own, and a line that opens
-- like one of the last few quest moments gives way to the next one, so the book doesn't repeat itself.
local _, ns = ...
local J = ns.journey
local Q = ns.quests
local QL = {}
J.questLines = QL

local function try(...) return Q.try(...) end
local function fill(text, vars) return J.fill(text, vars) end

local WORDS = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve" }
local function say(n)
  n = tonumber(n) or 0
  return WORDS[n] or tostring(n)
end

-- English plurals for creature and item names ("Syndicate Spy" -> "Syndicate Spies").
local function plural(name)
  if name == "" then return name end
  local low = name:lower()
  if low:find("s$") then return name end
  if low:find("man$") then return name:sub(1, -4) .. "men" end
  if low:find("wolf$") or low:find("elf$") or low:find("dwarf$") then return name:sub(1, -2) .. "ves" end
  if low:find("[^aeiou]y$") then return name:sub(1, -2) .. "ies" end
  if low:find("[sxz]$") or low:find("[cs]h$") then return name .. "es" end
  return name .. "s"
end
local function singular(name)
  name = name or ""
  if name:lower():find("ies$") then return name:sub(1, -4) .. "y" end
  if name:lower():find("ves$") then return name:sub(1, -4) .. "f" end
  if name:find("[^s]s$") and not name:lower():find("ss$") then return name:sub(1, -2) end
  return name
end
QL.plural, QL.singular = plural, singular

-- One objective: name (counts, "slain" and "(Complete)" taken off), how many, and its kind.
function QL.objective(o)
  if type(o) ~= "table" then return nil end
  local text = type(o.text) == "string" and o.text or ""
  local need = tonumber(o.numRequired)
  local n1, n2 = text:match("(%d+)%s*/%s*(%d+)")
  need = need or tonumber(n2)
  local name = text:gsub("^%s*%d+%s*/%s*%d+%s*", ""):gsub("[:%s]*%d+%s*/%s*%d+%s*$", "")
  name = name:gsub("%s*%(%a+%)%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
  local kind = type(o.type) == "string" and o.type or nil
  local low = name:lower()
  if low:find(" slain$") or low:find(" killed$") or low:find(" defeated$") then
    name = name:gsub("%s+%a+$", "")
    kind = "monster"
  end
  return { name = Q.plain(name), need = need, kind = kind, raw = Q.plain(text) }
end

-- What we know about a quest, read while it sits in the log (kept after it leaves).
local facts = {}
local lastLog
function QL.read()
  local log = Q.logEntries()
  if type(log) ~= "table" or log == lastLog then return end
  lastLog = log
  for id, entry in pairs(log) do
    if type(entry) == "table" then
      local f = { title = entry.title and Q.plain(entry.title), objectives = {} }
      for _, o in ipairs(type(entry.objectives) == "table" and entry.objectives or {}) do
        local ob = QL.objective(o)
        if ob and ob.name ~= "" then f.objectives[#f.objectives + 1] = ob end
      end
      facts[id] = f
    end
  end
end
function QL.facts(id) QL.read(); return facts[id] end

local ESCORT = { "escort", "protect", "safely", "accompany", "guide ", "lead ", "safe passage", "defend" }
local SCOUT = { "find", "explore", "scout", "locate", "investigate", "search", "discover", "survey", "visit", "reach" }
local DELIVER = { "report to", "return to", "letter", "message", "note", "package", "delivery", "shipment", "orders", "word to",
  "summons", "parcel", "crate", "missive", "tidings", "introduction" }
local FOOD = { "meat", "flank", "egg", "steak", "spice", "fish", "milk", "cheese", "bread", "fillet", "haunch", "venison", "rib",
  "tongue", "wing", "leg", "liver", "heart", "chop", "flesh", "snout", "brain", "mushroom", "berry", "apple", "pumpkin" }
local PROOF = { "head", "skull", "ear", "fang", "tooth", "claw", "scalp", "tusk", "horn", "talon", "paw", "eye", "insignia",
  "badge", "medal", "tabard", "bead", "mane", "tail", "feather" }
local function anyIn(text, list)
  text = (text or ""):lower()
  for _, w in ipairs(list) do if text:find(w, 1, true) then return true end end
  return false
end

-- The family name a quest's foes share ("Syndicate Sentry", "Syndicate Spy" -> "Syndicate").
local function family(names)
  if type(names) ~= "table" or #names == 0 then return nil end
  local first = names[1]:match("^(%S+)%s")
  if not first then return nil end
  for i = 2, #names do if names[i]:match("^(%S+)") ~= first then return nil end end
  if #names >= 2 then return first end
end

-- The quest's kind and the words to fill in: kind, vars.
function QL.classify(id, title)
  local f = QL.facts(id) or {}
  title = Q.plain(title or f.title or Q.questName(id) or "")
  local lowTitle = title:lower()
  local objectives = f.objectives or {}
  local mobs = ns.questMobs and ns.questMobs[id]
  local shop = ns.questShop and ns.questShop[id]
  local npcs = ns.questNPCs and ns.questNPCs[id]
  local vars = { title = title }
  local kills, items, objects, events, total = {}, {}, {}, {}, 0
  for _, o in ipairs(objectives) do
    if o.kind == "monster" then kills[#kills + 1] = o
    elseif o.kind == "item" then items[#items + 1] = o
    elseif o.kind == "object" then objects[#objects + 1] = o
    elseif o.kind == "event" or o.kind == "log" then events[#events + 1] = o
    elseif o.need then items[#items + 1] = o
    else events[#events + 1] = o end
  end
  local foe = kills[1] and kills[1].name or (mobs and mobs[1])
  local fam = family(mobs)
  if foe then
    vars.foe = singular(foe)
    vars.foes = fam or plural(singular(foe))
  end
  -- a bounty: WANTED or Bounty in the title, or a single named kill
  local wanted = lowTitle:find("^wanted") or lowTitle:find("bounty")
  if wanted and (kills[1] or items[1] or foe) then
    local target = title:match("^[Ww][Aa][Nn][Tt][Ee][Dd]:?%s*(.+)$")
    vars.target = target or (kills[1] and kills[1].name) or (mobs and mobs[1]) or vars.foe or "the outlaw"
    if items[1] then vars.item = items[1].name end
    return "wanted", vars
  end
  if #kills > 0 then
    local n = 0
    for _, o in ipairs(kills) do n = n + (o.need or 1) end
    vars.n = say(n)
    if #kills == 1 and (kills[1].need or 1) == 1 then vars.target = kills[1].name; return "slay", vars end
    if #kills > 1 then vars.foe2 = plural(kills[2].name) end
    return "kill", vars
  end
  if #items > 0 then
    local it = items[1]
    vars.item = singular(it.name)
    vars.items = (it.need or 1) > 1 and plural(singular(it.name)) or it.name
    vars.n = say(it.need or 1)
    vars.count = (it.need or 1) > 1 and (say(it.need) .. " " .. vars.items) or ("the " .. it.name)
    if shop then return "buy", vars end
    if mobs and #mobs > 0 then
      if anyIn(it.name, PROOF) then return "proof", vars end
      return "loot", vars
    end
    if anyIn(it.name, FOOD) then return "cook", vars end
    if (it.need or 1) == 1 and #items == 1 then return "find", vars end
    return "gather", vars
  end
  -- read before the journal could see its objectives: the route's foes still tell a hunt
  if #objectives == 0 and mobs and #mobs > 0 and not anyIn(lowTitle, DELIVER) then return "kill", vars end
  if anyIn(lowTitle, ESCORT) or (events[1] and anyIn(events[1].name, ESCORT)) then
    vars.ward = events[1] and events[1].name:gsub("^[Ee]scort%s+", ""):gsub("%s+to safety.*$", "") or nil
    return "escort", vars
  end
  if #objects > 0 then vars.thing = objects[1].name; return "deed", vars end
  if #events > 0 then
    vars.place = events[1].name:gsub("^%a+%s+", "", 1)
    if anyIn(events[1].name, SCOUT) then return "scout", vars end
    vars.deed = events[1].name
    return "deed", vars
  end
  -- no objectives: carried something to someone, or a talk
  if npcs and npcs.start and npcs.finish and npcs.start ~= npcs.finish then return "deliver", vars end
  if anyIn(lowTitle, DELIVER) then return "deliver", vars end
  return "errand", vars
end

-- The lines. %zone% the land, %giver% who you hand it in to, %foe%/the %foes% the creature and its kind,
-- %target% one named foe, %item%/%items%/%count% the goods, %n% how many as a word.
QL.LINES = {
  wanted = { "Collected the bounty on %target% in %zone%", "Brought %target% to justice, and %giver% paid up",
    "Hunted down %target%: one less name on the posters of %zone%", "Tore down the WANTED poster for %target%: the job is done",
    "Tracked %target% across %zone% and ended the matter", "Claimed the price on %target%'s head from %giver%",
    "Answered the call on the wanted board: %target% won't trouble %zone% again", "Made %target% pay for their crimes in %zone%",
    "Found %target% in %zone%, and the reward found you", "Ended the career of %target%, outlaw of %zone%" },
  slay = { "Faced %target% in %zone% and walked away", "Put an end to %target% at %giver%'s asking",
    "Sought out %target% in %zone%, and that was that", "Brought down %target%, as %giver% asked",
    "Settled a score with %target% in %zone%", "Laid %target% low somewhere in %zone%",
    "Went looking for %target% and found them, to their regret", "%target% had it coming. %zone% agrees" },
  kill = { "Thinned the %foes% of %zone% by %n%, as %giver% asked", "Answered %giver%'s call to arms against the %foes% of %zone%",
    "Made %zone% a little safer from the %foes%", "Hunted the %foes% across %zone% until the count was right",
    "Took the fight to the %foes% of %zone% so %giver% could sleep at night", "Went looking for the %foes% in %zone%, and found plenty",
    "Spent a bloody afternoon among the %foes% of %zone%", "Sent %n% of the %foes% to their rest in %zone%",
    "Did the grim work %giver% asked: the %foes%, and plenty of them", "Came back from %zone% with a tally of the %foes% and a few new scars",
    "Cleared a path through the %foes% of %zone%", "Kept a careful count of the %foes% of %zone%: %n%, and not one fewer",
    "Broke the %foes%' hold on their corner of %zone%", "Gave the %foes% of %zone% something to fear" },
  loot = { "Took %count% off the %foes% in %zone% for %giver%", "Pried %count% from the hands of the %foes% across %zone%",
    "Searched the fallen %foes% of %zone% until %count% turned up", "Won %count% from the %foes%, one fight at a time",
    "Brought %giver% %count%, taken from the %foes% in %zone%", "The %foes% of %zone% were carrying %items%; now you are",
    "Fought the %foes% of %zone% for %count%, and won them all", "Relieved the %foes% in %zone% of %count%",
    "Emptied the pockets of the %foes% across %zone% for %items%", "Recovered %count% from the %foes%: %giver% was grateful" },
  proof = { "Brought %giver% %count% as proof the %foes% of %zone% are fewer now", "Carried %count% back to %giver%: grim proof of a job done",
    "Gathered %count% from the %foes% in %zone%, as %giver% asked", "Showed %giver% %count%: the %foes% of %zone% won't be missed",
    "Took %count% from the %foes% of %zone%; %giver% counted every one", "Returned to %giver% with %count% and a story to match" },
  gather = { "Gathered %count% across %zone% for %giver%", "Rummaged through %zone% for %count%",
    "Brought back the %items% %giver% needed", "Searched every corner of %zone% for %count%", "Came back to %giver% with arms full of %items%",
    "Turned %zone% upside down looking for %items%", "Filled your bags with %items% from %zone% and hauled them to %giver%",
    "Found every last %item% %giver% asked for, in the far corners of %zone%", "Picked %zone% clean of %items%, as promised",
    "Combed %zone% for %count%: back aching, bags full", "Collected %count% for %giver%, no questions asked" },
  cook = { "Gathered %count% in %zone% so %giver% could get cooking", "Kept the kitchens of %zone% stocked with %items%",
    "Brought %giver% %count% for supper, and maybe got a taste", "Fetched %items% from %zone%: somebody's stew depends on it",
    "Delivered %count% to %giver%: dinner is saved", "Hunted %zone% for %items%; the pot was waiting" },
  find = { "Found %count% in %zone% and brought it to %giver%", "Tracked down %count% in %zone%",
    "Turned up %count% where %giver% said it would be, more or less", "Recovered %count% from the wilds of %zone%",
    "Put %count% into %giver%'s hands at last", "Went into %zone% for %count%, and came back with it" },
  buy = { "Shopped for %count% so %giver% didn't have to", "Bought %count% from a merchant and carried it to %giver%",
    "Spent your own coin on %count% for %giver%", "Haggled for %count% and brought it to %giver%" },
  escort = { "Saw %ward% safely through %zone%", "Guarded %ward% every step of the way across %zone%",
    "Walked %ward% out of danger in %zone%, sword drawn", "Kept %ward% alive on a long road through %zone%",
    "Escorted %ward% home, and nobody got left behind", "Stood between %ward% and everything %zone% threw at you" },
  scout = { "Scouted %place% for %giver%", "Found %place% and brought word back to %giver%",
    "Explored %place% in %zone% so %giver% would know what lies there", "Went where %giver% sent you: %place%",
    "Took a look at %place% in %zone% and lived to report it", "Mapped the way to %place% for %giver%" },
  deed = { "Did what had to be done in %zone%: %title%", "Put your hands to the task in %zone% for %giver%",
    "Set things right in %zone%: %title%", "Took care of %title% in %zone%, start to finish",
    "Saw to %title% for %giver%, out in %zone%", "Handled %title% in %zone%, and %giver% took note" },
  deliver = { "Carried word across %zone% to %giver%", "Delivered a message to %giver% in %zone%",
    "Played messenger: %title%, safely in %giver%'s hands", "Brought %giver% the news from the road",
    "Walked the long way round %zone% on someone else's business, all the way to %giver%",
    "Put %title% into %giver%'s hands, as promised", "Took the road to %giver% with word that couldn't wait" },
  errand = { "Ran an errand for %giver% in %zone%", "Did a good turn for %giver% in %zone%", "Kept a promise to %giver% in %zone%",
    "Answered %giver%'s plea for help in %zone%", "Did what %giver% couldn't, in %zone%",
    "Made %giver%'s problem your problem, and then made it go away", "Saw %title% through for %giver%",
    "Lent %giver% a hand with %title% in %zone%" },
}
-- Without a giver to name: the same kinds, with nobody named.
QL.NO_GIVER = { "Lent a helping hand in %zone%", "Answered a call for help in %zone%", "Did a stranger a good turn in %zone%",
  "Set something right in %zone%", "Saw %title% through in %zone%" }

-- The opening words of a line (two words, lower case), to tell lines that read alike.
local function opening(text)
  local a, b = (text or ""):lower():match("^(%S+)%s+(%S+)")
  return (a or "") .. " " .. (b or "")
end
-- The openings of the last few quest moments in the book.
local function recentOpenings(limit)
  local list, out = J.data().events, {}
  local n = 0
  for i = #list, 1, -1 do
    local e = list[i]
    if e.k == "quest" or e.k == "chain" or e.k == "elite" then
      out[opening(e.s)] = true
      n = n + 1
      if n >= limit then break end
    end
  end
  return out
end

-- Pick a line from the pool: the one the quest's hash names, unless it opens like one of the last
-- eight quest moments; then the next that doesn't. Lines naming something we don't know are passed.
function QL.choose(pool, seed, vars)
  local n = #pool
  local idx = {}
  for i = 1, n do idx[i] = i end
  local start = J.pick(idx, seed)
  local recent = recentOpenings(8)
  local first
  for k = 0, n - 1 do
    local line = pool[(start - 1 + k) % n + 1]
    local ok = true
    for key in line:gmatch("%%(%w+)%%") do if vars[key] == nil or vars[key] == "" then ok = false; break end end
    if ok then
      local text = fill(line, vars)
      first = first or text
      if not recent[opening(text)] then return (text:gsub("^%l", string.upper)) end
    end
  end
  return first and (first:gsub("^%l", string.upper)) or nil
end

-- The family lines from Journey.lua (murlocs, kobolds, the dead...) for a kill-shaped quest.
local function familyLines(vars)
  local foe = ((vars.foe or "") .. " " .. (vars.foes or "")):lower()
  for _, f in ipairs(J.FOES or {}) do
    for word in f[1]:gmatch("[^|]+") do
      if foe:find(word, 1, true) then return f[2] end
    end
  end
end

-- A quest turn-in as a line of the story: (text, kind). Replaces Journey.lua's.
local base = J.questLine
function QL.line(id, title, zone)
  QL.read()
  if J.FAMOUS_QUESTS[id] then return J.FAMOUS_QUESTS[id], "chain" end
  local part, length = Q.chainInfo(id)
  local f = facts[id] or {}
  title = Q.plain(title or f.title or Q.questName(id) or ("Quest " .. tostring(id)))
  zone = zone or "the wilds"
  if part and length and part == length then
    return fill(J.pick({ "Saw the tale of %title% through to the end", "Finished the long road of %title%",
      "Closed the book on %title%: the last page turned in %zone%", "Followed %title% to its end, every step of it" }, id),
      { title = title, zone = zone }), "chain"
  end
  local elite = Q.eliteName(id)
  if elite then
    return fill(J.pick({ "Took on %elite% and lived to tell the tale", "Stood against %elite% in %zone% and won",
      "Gathered your nerve and your friends, and brought down %elite%", "%elite% was too big to fight alone; you fought it anyway",
      "Felled %elite% in %zone%: a fight worth retelling" }, id), { elite = Q.plain(elite), zone = zone }), "elite"
  end
  local kind, vars = QL.classify(id, title)
  vars.zone = zone
  vars.giver = J.finisher and J.finisher(id) or nil
  vars.title = title
  local pool = QL.LINES[kind] or QL.LINES.errand
  if kind == "kill" then
    local fam = familyLines(vars)
    if fam then
      local mixed = {}
      for _, l in ipairs(fam) do mixed[#mixed + 1] = l end
      for _, l in ipairs(pool) do mixed[#mixed + 1] = l end
      pool = mixed
    end
  end
  local text = QL.choose(pool, id, vars) or QL.choose(QL.NO_GIVER, id, vars)
  QL.lastKind = kind
  if not text then return base(id, title, zone) end
  return text, "quest"
end
J.questLine = QL.line
J.questKind = function(id, title) return (QL.classify(id, title)) end

local started
function ns.startJourneyQuestLines()
  if started then return end
  started = true
  ns.every(5, function() pcall(QL.read) end)
end

function ns.journeyQuestLinesDebugLines()
  local n = 0
  for _ in pairs(facts) do n = n + 1 end
  return { "journey quest lines: " .. n .. " quests read, last kind " .. tostring(QL.lastKind) }
end
