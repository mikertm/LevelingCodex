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
local UNCOUNTED = { "meat", "cloth", "dust", "leather", "ore", "silk", "wool", "venison", "flesh", "moss", "wood", "lumber",
  "water", "blood", "silt", "ichor", "ash", "slime", "mud", "powder", "salt", "jerky", "bacon" }
local function plural(name)
  if name == "" then return name end
  local low = name:lower()
  for _, w in ipairs(UNCOUNTED) do if low:sub(-#w) == w and (#low == #w or low:sub(-#w - 1, -#w - 1) == " ") then return name end end
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
      local f = { title = entry.title and Q.plain(entry.title), objectives = {}, level = tonumber(entry.level) }
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
local SEEK_TITLES = { "^[Ss]earch for (.+)$", "^[Ii]n [Ss]earch of (.+)$", "^[Ll]ooking for (.+)$", "^[Ff]inding (.+)$",
  "^[Ff]ind (.+)$", "^[Tt]he [Ss]earch for (.+)$", "^[Tt]he [Hh]unt for (.+)$", "^[Ww]here [Ii]s (.+)%??$" }
local REPORT_TITLES = { "^[Rr]eport to (.+)$", "^[Rr]eport [Bb]ack to (.+)$", "^[Rr]eturn to (.+)$", "^[Ss]peak [Ww]ith (.+)$",
  "^[Ss]peak to (.+)$", "^[Tt]alk to (.+)$", "^[Ss]eek [Oo]ut (.+)$", "^[Ii]nto the [Hh]ands of (.+)$" }
local LORE = { "legend", "tale of", "story of", "history", "secret", "mystery", "riddle", "prophecy", "the lost ", "chronicle",
  "ballad", "memory", "memories" }
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
  -- no objectives: the title tells a search, a report, a legend; else carried something to someone, or a talk
  for _, pat in ipairs(SEEK_TITLES) do
    local quarry = title:match(pat)
    if quarry and quarry ~= "" then vars.quarry = quarry; return "seek", vars end
  end
  for _, pat in ipairs(REPORT_TITLES) do
    local who = title:match(pat)
    if who and who ~= "" then vars.who = who; return "report", vars end
  end
  if anyIn(lowTitle, LORE) then return "lore", vars end
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
    "Found %target% in %zone%, and the reward found you", "Ended the career of %target%, outlaw of %zone%",
    "Read the poster, sharpened the blade, and went after %target%", "Took the bounty on %target% and earned every copper of it",
    "%target% ran out of places to hide in %zone%", "The posters for %target% can come down now. %giver% saw to the payment",
    "Turned the hunter on %target%, and the hunt ended in %zone%", "Cashed in on %target%: wanted no longer",
    "Followed the rumours of %target% through %zone% to their end", "Put a price on %target%'s head into your own purse" },
  slay = { "Faced %target% in %zone% and walked away", "Put an end to %target% at %giver%'s asking",
    "Sought out %target% in %zone%, and that was that", "Brought down %target%, as %giver% asked",
    "Settled a score with %target% in %zone%", "Laid %target% low somewhere in %zone%",
    "Went looking for %target% and found them, to their regret", "%target% had it coming. %zone% agrees",
    "Stood over %target% at the end of a hard fight in %zone%", "One name, one fight: %target%, done",
    "Ended %target%'s reign over their corner of %zone%", "Sent %target% to the spirit healer, and they won't be coming back",
    "Cornered %target% in %zone%; it didn't end well for them", "%giver% wanted %target% gone. Now they are",
    "Met %target% blade to blade in %zone%, and kept the blade", "Took %target% off the map of %zone% for good" },
  kill = { "Thinned the %foes% of %zone% by %n%, as %giver% asked", "Answered %giver%'s call to arms against the %foes% of %zone%",
    "Made %zone% a little safer from the %foes%", "Hunted the %foes% across %zone% until the count was right",
    "Took the fight to the %foes% of %zone% so %giver% could sleep at night", "Went looking for the %foes% in %zone%, and found plenty",
    "Spent a bloody afternoon among the %foes% of %zone%", "Sent %n% of the %foes% to their rest in %zone%",
    "Did the grim work %giver% asked: the %foes%, and plenty of them", "Came back from %zone% with a tally of the %foes% and a few new scars",
    "Cleared a path through the %foes% of %zone%", "Kept a careful count of the %foes% of %zone%: %n%, and not one fewer",
    "Broke the %foes%' hold on their corner of %zone%", "Gave the %foes% of %zone% something to fear",
    "Waded into the %foes% of %zone% and waded back out again", "Reported %n% fewer %foes% in %zone% to %giver%",
    "Swept the %foes% out of %zone%'s quieter corners", "Counted %n% %foes% down in %zone%, and lost count of the bruises",
    "Pushed the %foes% back in %zone%, at least for a while", "Did %zone% a favour where the %foes% were concerned",
    "Made the %foes% regret settling in %zone%", "Wore out a whetstone on the %foes% of %zone%",
    "Took %giver%'s grudge against the %foes% and made it yours", "Left a trail of %foes% behind you across %zone%" },
  loot = { "Took %count% off the %foes% in %zone% for %giver%", "Pried %count% from the hands of the %foes% across %zone%",
    "Searched the fallen %foes% of %zone% until %count% turned up", "Won %count% from the %foes%, one fight at a time",
    "Brought %giver% %count%, taken from the %foes% in %zone%", "The %foes% of %zone% were carrying %items%; now you are",
    "Fought the %foes% of %zone% for %count%, and won them all", "Relieved the %foes% in %zone% of %count%",
    "Emptied the pockets of the %foes% across %zone% for %items%", "Recovered %count% from the %foes%: %giver% was grateful",
    "Took back %count% the %foes% had no business holding", "Checked every fallen foe in %zone% for %items%. Most had none. Some did",
    "Cursed the drop rate, then found the last of the %items% on a %foe%", "Fought for %items% in %zone% until the bags were heavy",
    "Turned %foes% into %items%, the old-fashioned way", "Put %count% on %giver%'s table, still warm from the fight" },
  proof = { "Brought %giver% %count% as proof the %foes% of %zone% are fewer now", "Carried %count% back to %giver%: grim proof of a job done",
    "Gathered %count% from the %foes% in %zone%, as %giver% asked", "Showed %giver% %count%: the %foes% of %zone% won't be missed",
    "Took %count% from the %foes% of %zone%; %giver% counted every one", "Returned to %giver% with %count% and a story to match",
    "Laid %count% on %giver%'s table. Nobody asked for details", "Proved the deed with %count%: the %foes% of %zone% know who did it",
    "Brought back %count% from %zone%; the smell will take longer to go", "Collected %count% as trophies of a hard hunt in %zone%" },
  gather = { "Gathered %count% across %zone% for %giver%", "Rummaged through %zone% for %count%",
    "Brought back the %items% %giver% needed", "Searched every corner of %zone% for %count%", "Came back to %giver% with arms full of %items%",
    "Turned %zone% upside down looking for %items%", "Filled your bags with %items% from %zone% and hauled them to %giver%",
    "Found every last %item% %giver% asked for, in the far corners of %zone%", "Picked %zone% clean of %items%, as promised",
    "Combed %zone% for %count%: back aching, bags full", "Collected %count% for %giver%, no questions asked",
    "Bent over in the fields of %zone% until %count% were in the bag", "Spent a quiet hour in %zone% gathering %items%",
    "Brought %giver% %count%, and a few spares just in case", "Walked %zone% with your eyes on the ground, picking up %items%",
    "Kept looking for %items% long after your knees told you to stop", "Stocked %giver%'s shelves with %count% from %zone%" },
  cook = { "Gathered %count% in %zone% so %giver% could get cooking", "Kept the kitchens of %zone% stocked with %items%",
    "Brought %giver% %count% for supper, and maybe got a taste", "Fetched %items% from %zone%: somebody's stew depends on it",
    "Delivered %count% to %giver%: dinner is saved", "Hunted %zone% for %items%; the pot was waiting",
    "Filled %giver%'s larder with %count%", "Came back from %zone% smelling of %items%, with a recipe in mind",
    "Brought home the makings of a feast: %count%", "Supplied %giver% with %items%, and the kitchen smelled wonderful" },
  find = { "Found %count% in %zone% and brought it to %giver%", "Tracked down %count% in %zone%",
    "Turned up %count% where %giver% said it would be, more or less", "Recovered %count% from the wilds of %zone%",
    "Put %count% into %giver%'s hands at last", "Went into %zone% for %count%, and came back with it",
    "Searched %zone% high and low, and %count% was in the last place you looked", "Dug %count% out of a forgotten corner of %zone%",
    "Brought back %count%, a little worse for wear but whole", "Found what %giver% had lost: %count%" },
  buy = { "Shopped for %count% so %giver% didn't have to", "Bought %count% from a merchant and carried it to %giver%",
    "Spent your own coin on %count% for %giver%", "Haggled for %count% and brought it to %giver%",
    "Ran to the merchant for %count%; %giver% owes you a drink", "Opened your purse for %count%, all for %giver%",
    "Found a trader with %items% and a fair price, more or less" },
  escort = { "Saw %ward% safely through %zone%", "Guarded %ward% every step of the way across %zone%",
    "Walked %ward% out of danger in %zone%, sword drawn", "Kept %ward% alive on a long road through %zone%",
    "Escorted %ward% home, and nobody got left behind", "Stood between %ward% and everything %zone% threw at you",
    "Matched pace with %ward% across %zone%, slow as it was", "Brought %ward% through %zone% with every ambush beaten off",
    "Kept watch over %ward% the whole way through %zone%", "Got %ward% where they were going. Mostly in one piece" },
  scout = { "Scouted %place% for %giver%", "Found %place% and brought word back to %giver%",
    "Explored %place% in %zone% so %giver% would know what lies there", "Went where %giver% sent you: %place%",
    "Took a look at %place% in %zone% and lived to report it", "Mapped the way to %place% for %giver%",
    "Crept close to %place% and counted what you saw", "Went out to %place% to see for yourself, and came back with answers",
    "Put %place% on %giver%'s map" },
  seek = { "Went looking for %quarry% in %zone%, as %giver% asked", "Searched %zone% for %quarry% and found the trail",
    "Followed every lead in %zone% to %quarry%", "Picked up the trail of %quarry% in %zone%",
    "Asked around %zone% until someone knew where %quarry% was", "Found %quarry%, or what %giver% needed to know about them",
    "Turned over every stone in %zone% in search of %quarry%", "The search for %quarry% led you across %zone%" },
  report = { "Reported to %who% in %zone%", "Brought your news to %who%", "Made your report to %who%, who listened closely",
    "Stood before %who% and told them everything", "Found %who% in %zone% and passed on the word",
    "Took the road to %who%, with orders in your pack" },
  lore = { "Pieced together %title% for %giver%", "Dug into %title% and turned up more than anyone expected",
    "Learned the truth behind %title% in %zone%", "Followed the threads of %title% across %zone%",
    "Unravelled a little more of %title%", "Listened to %title% in %zone%, and then went and did something about it",
    "Heard %title% from %giver%, and became part of it" },
  deed = { "Did what had to be done in %zone%: %title%", "Put your hands to the task in %zone% for %giver%",
    "Set things right in %zone%: %title%", "Took care of %title% in %zone%, start to finish",
    "Saw to %title% for %giver%, out in %zone%", "Handled %title% in %zone%, and %giver% took note",
    "Rolled up your sleeves for %title%", "Did the work %title% asked for, in the heart of %zone%",
    "Made good on %title% in %zone%" },
  deliver = { "Carried word across %zone% to %giver%", "Delivered a message to %giver% in %zone%",
    "Played messenger: %title%, safely in %giver%'s hands", "Brought %giver% the news from the road",
    "Walked the long way round %zone% on someone else's business, all the way to %giver%",
    "Put %title% into %giver%'s hands, as promised", "Took the road to %giver% with word that couldn't wait",
    "Carried a sealed letter to %giver% and resisted every urge to read it", "Ran a message to %giver%; the seal was still unbroken",
    "Was the post for a day: %title%, delivered", "Brought %giver% a parcel and a bit of road dust" },
  errand = { "Ran an errand for %giver% in %zone%", "Did a good turn for %giver% in %zone%", "Kept a promise to %giver% in %zone%",
    "Answered %giver%'s plea for help in %zone%", "Did what %giver% couldn't, in %zone%",
    "Made %giver%'s problem your problem, and then made it go away", "Saw %title% through for %giver%",
    "Lent %giver% a hand with %title% in %zone%", "Helped %giver% with %title%, and got a tired smile for it",
    "Took on %title% because %giver% asked nicely", "Saw %title% done for %giver% in %zone%",
    "Did %giver% a favour in %zone%; they won't forget it", "Put %title% to rest for %giver%",
    "Gave %giver% a little of your time in %zone%: %title%", "Listened to %giver%, then did %title%",
    "Did right by %giver% in %zone%" },
}
-- Without a giver to name: the same kinds, with nobody named.
QL.NO_GIVER = { "Lent a helping hand in %zone%", "Answered a call for help in %zone%", "Did a stranger a good turn in %zone%",
  "Set something right in %zone%", "Saw %title% through in %zone%", "Finished %title% somewhere in %zone%",
  "Took care of %title% in %zone%", "Did your part in %zone%: %title%" }

-- Situations around the deed: how long it sat in the log, where it was taken, how hard it was, who was there,
-- where it falls in a chain. Each has its own lines; a chosen one replaces the kind's line.
QL.SITUATIONS = {
  overdue = { "Finally handed in %title%, after %held% in the quest log", "%title% sat in your log for %held%. Done at last",
    "Remembered %title% after %held%, and %giver% was still waiting", "Dusted off %title% after %held% and saw it through",
    "Better late than never: %title%, %held% after you took it" },
  swift = { "In and out: %title% done in minutes", "Took %title% and finished it before the ink was dry",
    "%title%: barely had time to read the quest text", "Made short work of %title% in %zone%",
    "Handed %title% back almost before %giver% had finished explaining" },
  carried = { "Carried %title% from %from% all the way to %zone%", "Took %title% in %from%, finished it in %zone%",
    "%title% followed you from %from% to %zone%, and ended there", "Brought %title% the long road from %from%",
    "Picked up %title% in %from%; it took %zone% to finish it" },
  grey = { "Got round to %title% long after it stopped being a challenge", "Tidied up %title%, an old job well below you now",
    "%title%: easy work by now, but a promise is a promise", "Cleared an old task off the books: %title%",
    "Swatted through %title%; you've outgrown %zone%'s troubles" },
  hard = { "Bit off more than you could chew with %title%, and chewed it anyway", "Took on %title% above your weight, and won",
    "%title% was meant for someone stronger. You did it anyway", "Pulled off %title% by the skin of your teeth",
    "Punched above your level for %title%, and it paid off", "Survived %title%, though %zone% did its best to stop you",
    "%title% should have been too much. It wasn't", "Came out of %title% bruised, breathless and victorious" },
  party = { "Saw %title% through with friends at your side", "Shared %title% with your party in %zone%",
    "Many hands made light work of %title%", "Did %title% together; nobody had to do it alone",
    "Turned in %title% with your group, everyone grinning" },
  night = { "Finished %title% while %zone% slept", "Turned in %title% by lamplight, late into the night",
    "%title%, done in the small hours", "Handed in %title% when sensible folk were in bed" },
  dungeon = { "Finished %title% deep inside %zone%", "Saw %title% through in the dark of %zone%",
    "Brought %title% to its end where the torches gutter, in %zone%" },
  chainStart = { "Took the first step of a longer tale: %title%", "Started something with %title%; %giver% hinted at more",
    "%title% was only the beginning", "Opened a new story with %title%" },
  chainMid = { "Part %part% of %length%: %title%. The story goes on", "Turned another page of the tale: %title%",
    "%title%, part %part% of %length%, and %giver% had more to say", "Pressed on with the story: %title%",
    "One chapter more: %title%. %giver% pointed you onward" },
  firstHere = { "Your first good deed in %zone%: %title%", "Made a name in %zone% with %title%",
    "%zone% saw your first work with %title%", "Introduced yourself to %zone% by way of %title%" },
  manyHere = { "Your %nth% task done in %zone%: %title%", "%zone% now counts %n% good deeds of yours, the latest %title%",
    "Another one for %zone%, the %nth%: %title%", "%title%: number %n% in %zone%, and the locals know your face" },
}

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

-- What was going on around a turn-in: (situation, vars) or nil. Milestones in a land always speak; a
-- quest held long, carried from another land, far above you or part of a chain speaks two times in
-- three; a party, the small hours, a dungeon, a quick one or an outgrown one one time in three.
local MILESTONES = { [10] = true, [25] = true, [50] = true, [75] = true, [100] = true, [150] = true, [200] = true }
local NTH = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" }
local function nth(n) return NTH[n] or (tostring(n) .. "th") end
local HARD_KINDS = { kill = true, slay = true, wanted = true, loot = true, proof = true, escort = true }
function QL.situation(id, f, zone, part, length, kind)
  local hash = J.voice and J.voice.hashOf or function() return 0 end
  local strong, soft = {}, {}
  local vars = {}
  -- a land's own count of your deeds
  local inLand, all = 0, 0
  for _, e in ipairs(J.data().events) do
    if e.k == "quest" or e.k == "chain" or e.k == "elite" then
      all = all + 1
      if e.m and J.landOf and J.landOf(e.m) == zone then inLand = inLand + 1 end
    end
  end
  if inLand == 0 and all >= 10 then return "firstHere", vars end
  if MILESTONES[inLand + 1] then
    vars.n, vars.nth = tostring(inLand + 1), nth(inLand + 1)
    return "manyHere", vars
  end
  local taken = J.tales and J.tales.taken and J.tales.taken(id)
  local now = J.now()
  if type(taken) == "table" and tonumber(taken.t) then
    local held = now - tonumber(taken.t)
    if held >= 2 * 86400 then
      vars.held = J.story and J.story.away(held) or (math.floor(held / 86400) .. " days")
      strong[#strong + 1] = "overdue"
    elseif held >= 0 and held <= 180 then soft[#soft + 1] = "swift" end
    local from = taken.m and J.landOf and J.landOf(taken.m)
    if from and from ~= zone and zone ~= "the wilds" then vars.from = from; strong[#strong + 1] = "carried" end
  end
  local qlvl, lvl = tonumber(f and f.level), tonumber(J.level and J.level())
  if qlvl and lvl and qlvl > 0 then
    local grey = tonumber(try(GetQuestGreenRange)) or (lvl < 40 and 5 + math.floor(lvl / 10) or 9)
    if qlvl - lvl >= 3 and HARD_KINDS[kind] then strong[#strong + 1] = "hard"
    elseif lvl - qlvl >= grey then soft[#soft + 1] = "grey" end
  end
  if part and length and length >= 3 then
    if part == 1 then soft[#soft + 1] = "chainStart"
    elseif part < length then vars.part, vars.length = say(part), say(length); strong[#strong + 1] = "chainMid" end
  end
  local raid = try(IsInRaid)
  local party = (tonumber(try(GetNumSubgroupMembers)) or 0) > 0 or try(IsInGroup) == true
  if party and raid ~= true then soft[#soft + 1] = "party" end
  if J.inInstance and J.inInstance() then soft[#soft + 1] = "dungeon" end
  local h = J.voice and J.voice.hourOf and J.voice.hourOf(now)
  if h and h < 4 then soft[#soft + 1] = "night" end
  local roll = hash(tostring(id) .. "situation") % 3
  if #strong > 0 and roll < 2 then return strong[hash(tostring(id) .. "strong") % #strong + 1], vars end
  if #soft > 0 and roll == 0 then return soft[hash(tostring(id) .. "soft") % #soft + 1], vars end
  return nil
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
      "Closed the book on %title%: the last page turned in %zone%", "Followed %title% to its end, every step of it",
      "Reached the last page of %title%, %n% parts later", "Tied off the last thread of %title% in %zone%",
      "Brought %title% home: %n% quests, one story, finished", "Saw %title% end the way it had to, in %zone%",
      "Finished what began many steps ago: %title%" }, id),
      { title = title, zone = zone, n = say(length) }), "chain"
  end
  local elite = Q.eliteName(id)
  if elite then
    return fill(J.pick({ "Took on %elite% and lived to tell the tale", "Stood against %elite% in %zone% and won",
      "Gathered your nerve and your friends, and brought down %elite%", "%elite% was too big to fight alone; you fought it anyway",
      "Felled %elite% in %zone%: a fight worth retelling", "Called for help, got it, and %elite% fell",
      "Faced %elite% with a full party and a lot of nerve", "Brought %elite% down in %zone%; the party is still talking about it",
      "Looked %elite% in the eye and didn't blink. Much" }, id), { elite = Q.plain(elite), zone = zone }), "elite"
  end
  local kind, vars = QL.classify(id, title)
  vars.zone = zone
  vars.giver = J.finisher and J.finisher(id) or nil
  vars.title = title
  QL.lastKind = kind
  -- the moment around the deed, sometimes, in its own words
  local sit, sitVars = QL.situation(id, f, zone, part, length, kind)
  if sit then
    for k, v in pairs(sitVars) do vars[k] = v end
    local text = QL.choose(QL.SITUATIONS[sit], id .. sit, vars)
    if text then QL.lastSituation = sit; return text, "quest" end
  end
  QL.lastSituation = nil
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

-- Giving a quest up: what kind it was, how long it sat in the log, where it was taken, whether you had
-- simply outgrown it. JourneyTales.lua asks this first.
QL.GIVE_UP = {
  any = { "Gave up on %title% in %zone%. Some battles aren't worth fighting",
    "Tore %title% out of the quest log. Not every story gets an ending", "Let %title% go. Maybe another hero will finish it",
    "Crossed %title% off the list unfinished, in %zone%", "Shrugged and dropped %title%. Life is short and the log is full",
    "Decided %title% was someone else's problem", "Made room in the log: %title% had to go",
    "Folded up %title% and put it away for good", "Walked away from %title%. No regrets. Well, a few",
    "Quietly forgot about %title%. %giver% will cope", "Struck %title% from the list and moved on",
    "Left %title% for the next adventurer through %zone%", "Called it a day on %title%",
    "Some quests just don't fit the road. %title% was one" },
  kill = { "Left the %foes% of %zone% for someone else to deal with", "Called off the hunt for the %foes%: %title%",
    "Let the %foes% of %zone% be. %title%, abandoned", "Decided the %foes% could keep their corner of %zone%" },
  wanted = { "Tore up the WANTED poster for %target% unanswered", "Let %target% walk free. The bounty can wait for another hunter",
    "Gave up the hunt for %target%" },
  slay = { "Left %target% for another day, or another hero", "Decided %target% was not worth the trouble after all" },
  gather = { "Gave up looking for %items%; %zone% can keep them", "Emptied the bags of half-gathered %items% and called it off",
    "Stopped searching for %items%. Your back thanked you" },
  loot = { "Stopped fighting the %foes% for %items%: %title%, dropped", "The %foes% kept their %items%. You kept your time" },
  deliver = { "Never delivered %title%. Somebody's still waiting for that letter", "Let the message in %title% go unsent" },
  escort = { "Left %ward% to find their own way. %title%, abandoned" },
  seek = { "Gave up the search for %quarry%", "Stopped looking for %quarry%. Some things stay lost" },
  outgrown = { "Outgrew %title%: %zone%'s troubles are small fry now", "Dropped %title%; there are bigger fights waiting",
    "Let go of %title%, an old job you'd long outgrown", "Cleared %title% from the log. It was beneath you by now",
    "Retired %title%: the newer heroes of %zone% can have it" },
  stale = { "Gave up on %title% after carrying it for %held%", "%title% sat in the log for %held%. Today it went",
    "After %held% of meaning to, you finally dropped %title%" },
  carried = { "Carried %title% from %from% to %zone%, then let it go", "Dropped %title%, picked up long ago back in %from%" },
}
function QL.abandonLine(id, title, zone, taken)
  local kind, vars = QL.classify(id, title)
  vars.title, vars.zone = title, zone or "the wilds"
  vars.giver = J.finisher and J.finisher(id) or nil
  local f = facts[id] or {}
  local pools = {}
  local qlvl, lvl = tonumber(f.level), tonumber(J.level and J.level())
  if qlvl and lvl and lvl - qlvl >= 8 then pools[#pools + 1] = "outgrown" end
  if type(taken) == "table" and tonumber(taken.t) then
    local held = J.now() - tonumber(taken.t)
    if held >= 2 * 86400 then
      vars.held = J.story and J.story.away(held) or (math.floor(held / 86400) .. " days")
      pools[#pools + 1] = "stale"
    end
    local from = taken.m and J.landOf and J.landOf(taken.m)
    if from and from ~= vars.zone then vars.from = from; pools[#pools + 1] = "carried" end
  end
  if QL.GIVE_UP[kind] then pools[#pools + 1] = kind end
  pools[#pools + 1] = "any"
  -- the first special pool most of the time, the plain lines now and then
  local hash = J.voice and J.voice.hashOf or function() return 0 end
  local first = pools[1]
  if #pools > 1 and hash(tostring(id) .. "giveup") % 4 == 0 then first = "any" end
  local text = QL.choose(QL.GIVE_UP[first], tostring(id) .. "abandon", vars)
  return text or QL.choose(QL.GIVE_UP.any, tostring(id) .. "abandon", vars)
end
J.abandonLine = QL.abandonLine
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
