-- JourneyTales.lua: the journal's MMO moments, the ones that happen between you, Azeroth and the
-- other players. Each becomes a moment of Journey.lua's story (J.add) and a count for the Trophies
-- ledger:
--   dungeon runs and wipes (a run told when you leave it: time, bosses, wipes, who came),
--   battlegrounds (in, then victory or defeat), honorable kills, duels,
--   resurrections by other players, trades, waves and other emotes aimed at you, joining a guild,
--   campfires (lighting one, sitting by one), crafting sessions and profession milestones (late at
--   night too), the auction house (a visit's posts and buys, sales and expired auctions by mail,
--   the money collected at the mailbox) and your purse's high marks, quests you gave up.
--   journey.tally = { honor, duelsWon, duelsLost, bgWon, bgLost, wipes, runs, rezzed, trades, camps,
--     crafted, posted, bought, sold, expired, ahGold, richest, abandoned }
--   journey.people[name] = { met, trades, duels, rez, waves }, journey.taken[questID] = { t, l, m }
-- Everything is read at call time and pcall'd; nothing here may break the rest of the add-on.
local _, ns = ...
local Q = ns.quests
local J = ns.journey
local function try(...) return Q.try(...) end

local T = {}
J.tales = T

local function now() return time and time() or 0 end
local function level() return tonumber(UnitLevel("player")) or 1 end
local function num(v)
  if v == nil then return nil end
  if type(issecretvalue) == "function" then
    local ok, secret = pcall(issecretvalue, v)
    if not ok or secret then return nil end
  end
  local ok, n = pcall(tonumber, v)
  return ok and n or nil
end
local function me() return try(UnitName, "player") end
local function plain(s) return Q.plain(tostring(s or "")) end
local function itemName(s)
  if type(s) ~= "string" then return nil end
  return plain(s:match("%[(.-)%]") or s)
end
local function zone() return J.zoneName() end
local function plural(n, one, many) return n == 1 and ("one " .. one) or (n .. " " .. (many or (one .. "s"))) end
local function list(names)
  if #names == 0 then return nil end
  if #names == 1 then return names[1] end
  return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

local function journal()
  local j = J.data()
  if type(j.tally) ~= "table" then j.tally = {} end
  if type(j.people) ~= "table" then j.people = {} end
  if type(j.taken) ~= "table" then j.taken = {} end
  return j
end
local function bump(key, n)
  local t = journal().tally
  t[key] = (tonumber(t[key]) or 0) + (n or 1)
  return t[key]
end
function T.tally(key) return tonumber(journal().tally[key]) or 0 end

-- Someone you met: a small record per name (trades, duels, resurrections, waves).
local function person(name, field)
  if type(name) ~= "string" or name == "" then return nil end
  name = name:match("^([^%-]+)") or name
  if J.isForgotten and J.isForgotten(name) then return nil end
  if J.isMe and J.isMe(name) then return nil end
  local j = journal()
  local p = j.people[name]
  local first = type(p) ~= "table"
  if first then p = { met = now() }; j.people[name] = p end
  if field then p[field] = (tonumber(p[field]) or 0) + 1 end
  p.last = now()
  return p, first
end

-- The local hour, for the late-night lines (nil when the client has no date()).
local function hour()
  if type(date) ~= "function" then return nil end
  local ok, t = pcall(date, "*t")
  return ok and type(t) == "table" and tonumber(t.hour) or nil
end
function T.lateNight()
  local h = hour()
  return h ~= nil and (h >= 23 or h < 5)
end

-- A client format string ("%1$s has defeated %2$s in a duel") as a Lua pattern plus the argument
-- order of its captures; nil when the string is missing (then the English fallback is used).
local function toPattern(fmt, fallback)
  if type(fmt) ~= "string" or not fmt:find("%", 1, true) then fmt = fallback end
  if type(fmt) ~= "string" then return nil end
  local order, n = {}, 0
  local p = fmt:gsub("|1[^;]*;[^;]*;", "\3"):gsub("|4[^;]*;", "\3")
  p = p:gsub("%%(%d*)%$?([sd])", function(pos, kind)
    n = n + 1
    order[#order + 1] = tonumber(pos) or n
    return kind == "s" and "\1" or "\2"
  end)
  p = p:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
  p = p:gsub("\1", "(.+)"):gsub("\2", "([%%d,%%.]+)"):gsub("\3", ".-")
  return "^" .. p, order
end
local patterns = {}
-- The arguments of a client line in the format's own order, or nil when it doesn't match.
local function read(text, global, fallback)
  if type(text) ~= "string" then return nil end
  local p = patterns[global]
  if p == nil then
    local pat, order = toPattern(_G[global], fallback)
    p = pat and { pat, order } or false
    patterns[global] = p
  end
  if not p then return nil end
  local caps = { text:match(p[1]) }
  if #caps == 0 then return nil end
  local args = {}
  for i, v in ipairs(caps) do args[p[2][i] or i] = v end
  return args
end

T.read = read

-- Rewrite a moment in place (a second wipe on the same boss, another sale in the same hour).
local function rewrite(e, text, detail)
  if type(e) ~= "table" then return end
  e.s = plain(text)
  e.d = detail and plain(detail) or e.d
  J.version = (J.version or 0) + 1
end

----------------------------------------------------------------------------
-- Dungeon runs, wipes and battlegrounds
----------------------------------------------------------------------------

local WIPE = { "The party fell before %boss% in %dungeon%. Back to the entrance, and again",
  "Wiped on %boss% in %dungeon%: everyone down, nobody standing", "%boss% sent the whole party to the graveyard in %dungeon%" }
local RUN = { "Spent %time% in %dungeon%%with%: %bosses%", "Came out of %dungeon% after %time%%with%: %bosses%" }
local RUN_HARD = { "A hard-won run: %time% in %dungeon%%with%, %bosses% and %wipes% along the way" }
local RUN_FAIL = { "Left %dungeon% after %time%%with% without a single boss down. Another day",
  "%dungeon% won this time: %time% inside%with%, no boss down" }
local BG_IN = { "Answered the call to arms at %bg%", "Marched into %bg% with banners raised" }
local BG_WON = { "Victory at %bg%! The %side% carried the day", "Won the field at %bg% for the %side%" }
local BG_LOST = { "Defeat at %bg%. The %foe% held the field this time", "Fell back from %bg%: the %foe% won the day" }
for _, s in ipairs({ "Everyone down before %boss% in %dungeon%. A long run back from the graveyard",
  "%boss% wiped the floor with the party in %dungeon%. Regroup, rebuff, again",
  "The pull on %boss% in %dungeon% went wrong, and then very wrong",
  "Wiped on %boss% in %dungeon%. Somebody stood in the bad stuff",
  "Down went the whole party before %boss% in %dungeon%. Nobody blamed the healer. Out loud" }) do WIPE[#WIPE + 1] = s end
for _, s in ipairs({ "Cleared a path through %dungeon%%with% in %time%: %bosses%",
  "%time% in %dungeon%%with%, and %bosses%",
  "Fought through %dungeon%%with% for %time%: %bosses%",
  "Back in the daylight after %time% in %dungeon%%with%: %bosses%",
  "%dungeon%%with%, %time% from door to door: %bosses%" }) do RUN[#RUN + 1] = s end
for _, s in ipairs({ "%dungeon% fought back%with%: %time%, %wipes%, and in the end %bosses%",
  "It took %time% and %wipes% in %dungeon%%with%, but %bosses%",
  "Bruised but proud after %dungeon%%with%: %time%, %wipes%, %bosses%" }) do RUN_HARD[#RUN_HARD + 1] = s end
for _, s in ipairs({ "Turned back from %dungeon% after %time%%with%. The bosses keep their treasure, for now",
  "%time% in %dungeon%%with% and nothing to show but repair bills" }) do RUN_FAIL[#RUN_FAIL + 1] = s end
for _, s in ipairs({ "Heard the war horns and joined the fight at %bg%",
  "Took up the banner at %bg%",
  "Queued, waited, and charged into %bg%",
  "Stepped onto the field at %bg%, weapons drawn" }) do BG_IN[#BG_IN + 1] = s end
for _, s in ipairs({ "The %foe% broke at %bg%, and the %side% cheered",
  "%bg% won for the %side%: a good day on the field",
  "Held %bg% against the %foe% and carried the day",
  "Victory at %bg%. The %foe% will be talking about that one" }) do BG_WON[#BG_WON + 1] = s end
for _, s in ipairs({ "The %foe% took %bg% this time. Next time",
  "Outnumbered and outplayed at %bg%. The %foe% won",
  "Lost the field at %bg%, but not the will to go back",
  "%bg% went to the %foe%. Lick the wounds, queue again" }) do BG_LOST[#BG_LOST + 1] = s end

local run, bg
local function minutes(sec)
  local m = math.floor((tonumber(sec) or 0) / 60 + 0.5)
  if m < 60 then return m .. " min" end
  return math.floor(m / 60) .. " h " .. (m % 60) .. " min"
end

local function finishRun()
  local r = run
  run = nil
  if not r then return end
  local secs = now() - r.start
  if r.bosses == 0 and secs < 300 then return end
  local party = J.partyText() or r.party
  local vars = { dungeon = r.name, time = minutes(secs), with = party and (" with " .. party) or "",
    bosses = r.bosses == 1 and "one boss down" or (r.bosses .. " bosses down"), wipes = plural(r.wipes, "wipe") }
  local lines = r.bosses == 0 and RUN_FAIL or (r.wipes >= 3 and RUN_HARD or RUN)
  bump("runs")
  J.add("run", J.fill(J.pick(lines, r.name .. r.start), vars),
    vars.time .. ", " .. vars.bosses .. (r.wipes > 0 and (", " .. vars.wipes) or ""), { who = r.name, n = r.bosses })
end

local function finishBG()
  bg = nil
end

local function enteredWorld()
  local name, kind = try(GetInstanceInfo)
  name = type(name) == "string" and name ~= "" and plain(name) or nil
  if run and (kind ~= "party" and kind ~= "raid" or name ~= run.name) then finishRun() end
  if bg and (kind ~= "pvp" or name ~= bg.name) then finishBG() end
  if (kind == "party" or kind == "raid") and name and not run then
    run = { name = name, start = now(), bosses = 0, wipes = 0, wipeOn = {}, wipeEvent = {}, party = J.partyText() }
  elseif kind == "pvp" and name and not bg then
    bg = { name = name, start = now() }
    J.add("bg", J.fill(J.pick(BG_IN, name .. now()), { bg = name }))
  end
end

function J.wipesOn(boss)
  return run and boss and run.wipeOn[boss] or 0
end

local function encounterEnd(_, boss, _, _, success)
  if not run or type(boss) ~= "string" then return end
  boss = plain(boss)
  run.party = J.partyText() or run.party
  if success == 1 or success == true then run.bosses = run.bosses + 1; return end
  run.wipes = run.wipes + 1
  bump("wipes")
  local n = (run.wipeOn[boss] or 0) + 1
  run.wipeOn[boss] = n
  local vars = { boss = boss, dungeon = run.name }
  if n == 1 then
    run.wipeEvent[boss] = J.add("wipe", J.fill(J.pick(WIPE, boss .. run.start), vars), "Wipe in " .. run.name, { who = boss })
  else
    rewrite(run.wipeEvent[boss], J.fill("Wiped " .. n .. " times on %boss% in %dungeon%. The party kept coming back", vars),
      n .. " wipes in " .. run.name)
  end
end

local function battlefieldScore()
  if not bg or bg.done then return end
  local winner = num(try(GetBattlefieldWinner))
  if not winner then return end
  bg.done = true
  local faction = try(UnitFactionGroup, "player")
  local mine = faction == "Horde" and 0 or 1
  local won = winner == mine
  local side = faction == "Horde" and "Horde" or "Alliance"
  local foe = side == "Horde" and "Alliance" or "Horde"
  bump(won and "bgWon" or "bgLost")
  J.add("bg", J.fill(J.pick(won and BG_WON or BG_LOST, bg.name .. bg.start), { bg = bg.name, side = side, foe = foe }),
    won and "Victory" or "Defeat")
end

----------------------------------------------------------------------------
-- Honor, duels, resurrections, trades, emotes, the guild
----------------------------------------------------------------------------

local HONOR_MARKS = { [10] = true, [25] = true, [50] = true, [100] = true, [250] = true, [500] = true, [1000] = true }
local function honorGain(text)
  local a = read(text, "COMBATLOG_HONORGAIN", "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)")
  local victim = a and a[1] or (type(text) == "string" and text:match("^(.-) dies"))
  if not victim then return end
  local n = bump("honor")
  victim = plain(victim)
  if n == 1 then
    J.add("pvp", J.fill(J.pick({ "Your first honorable kill: %who% fell in %zone%", "First blood in the war: %who%, in %zone%",
      "%who% fell to you in %zone%: your first honorable kill" }, victim), { who = victim, zone = zone() }), "Honorable kill 1", { who = victim, pvp = true })
  elseif HONOR_MARKS[n] then
    J.add("pvp", J.fill(J.pick({ "%n% honorable kills now. %who% was number %n%", "Honorable kill number %n%: %who%, in %zone%",
      "%who% made it %n% honorable kills. The other side knows your name" }, victim .. n), { n = tostring(n), who = victim, zone = zone() }),
      "Honorable kill " .. n, { who = victim, pvp = true })
  end
end

local DUEL_WON = { "Bested %name% in a duel in %zone%", "Won a duel against %name% in %zone%. Bragging rights earned",
  "Knocked %name% flat in a friendly duel in %zone%", "Crossed blades with %name% in %zone% and came out on top",
  "%name% asked for a duel in %zone% and got a lesson", "Won a duel against %name% in %zone%, then shook hands" }
local DUEL_LOST = { "Lost a duel to %name% in %zone%. Next time", "%name% got the better of you in a duel in %zone%",
  "%name% put you on your back in a duel in %zone%. Good fight", "A duel with %name% in %zone% went their way",
  "Lost to %name% in a duel in %zone%, and took notes" }
local function duel(winner, loser, fled)
  local self = me()
  if not self or (winner ~= self and loser ~= self) then return end
  local other = plain(winner == self and loser or winner)
  local won = winner == self
  person(other, "duels")
  bump(won and "duelsWon" or "duelsLost")
  local vars = { name = other, zone = zone() }
  local text
  if fled then
    text = won and J.fill("%name% fled from your duel in %zone%", vars) or J.fill("Thought better of a duel with %name% and walked away", vars)
  else
    text = J.fill(J.pick(won and DUEL_WON or DUEL_LOST, other .. now()), vars)
  end
  J.add("duel", text, won and "Duel won" or "Duel lost", { who = other, pvp = true })
end

local rezBy, deadAt
local REZ = { "%name% brought you back from the dead in %zone%", "Brought back to life by %name% in %zone%. You owe them one",
  "%name% pulled you back from the spirit world in %zone%", "%name% spoke a word over your body in %zone%, and you rose",
  "Saved from the corpse run by %name% in %zone%", "%name% raised you in %zone%. Owe them a drink",
  "Back among the living in %zone%, thanks to %name%", "The grey lifted in %zone%: %name% had called you back" }
local function revived(ghost)
  if not deadAt then return end
  local by = rezBy and (now() - rezBy.t) <= 180 and rezBy.name or nil
  if not by and ghost then deadAt, rezBy = nil, nil; return end -- a corpse run: the death already tells it
  deadAt, rezBy = nil, nil
  local vars = { name = by and plain(by) or "", zone = zone() }
  if by then
    person(by, "rez")
    bump("rezzed")
    J.add("rez", J.fill(J.pick(REZ, by .. now()), vars), "Resurrected", { who = vars.name })
  else
    J.add("rez", J.fill(J.pick({ "Rose again in %zone% without the long walk from the graveyard",
      "Got back up in %zone% where you fell, spared the corpse run", "Came back to life right there in %zone%",
      "Stood up again in %zone%, dusted off, carried on" }, now()), vars), "Back on your feet")
  end
end

local tradeWith, tradeBoth
local function tradeDone()
  local name = tradeWith
  tradeWith = nil
  if not name then return end
  local p, _ = person(name, "trades")
  if not p then return end
  p.lastTrade = time and time() or nil
  local n = bump("trades")
  local mine = tonumber(p.trades) or 1
  if mine == 1 then
    J.add("trade", J.fill(J.pick({ "Traded with %name% in %zone% for the first time", "Did business with %name% in %zone%: a first trade",
      "Struck a deal with %name% in %zone%", "Swapped goods with %name% in %zone% for the first time" }, name), { name = plain(name), zone = zone() }),
      "Trade", { who = plain(name) })
  elseif mine % 10 == 0 then
    J.add("trade", J.fill(J.pick({ "%n% trades with %name% now: a trusted partner", "%name% and you, %n% trades and counting",
      "Trade number %n% with %name%. A proper business arrangement" }, name .. mine), { n = tostring(mine), name = plain(name) }),
      "Trade", { who = plain(name) })
  elseif n == 1 then
    J.add("trade", "Your first trade, with " .. plain(name) .. " in " .. zone(), "Trade", { who = plain(name) })
  end
end

local emoteDay, emotesToday, emoted = nil, 0, {}
-- An emote aimed at you says "you" or "your" as a word: "Bo waves at you", not "Bo thanks Doyouknow"
-- (someone else's emote that only contains the letters).
function T.aimedAtYou(text)
  local low = " " .. tostring(text or ""):lower() .. " "
  return low:find("%f[%a]you%f[%A]") ~= nil or low:find("%f[%a]your%f[%A]") ~= nil
end

-- Take out emotes an older build kept that were aimed at someone else, and the kind words they counted.
local function dropStrayEmotes()
  local j = journal()
  local events = j.events
  for i = #events, 1, -1 do
    local e = events[i]
    if type(e) == "table" and e.k == "emote" and not e.told and T.aimedAtYou(e.s) and type(e.who) == "string" then
      -- an older build wrote the chat line itself ("The X licks you in Desolace"): tell it in the journal's words
      local said, where = tostring(e.s):match("^(.-) in ([^,]+)$")
      if said and T.emoteLine then e.s = T.emoteLine(said, e.who, where); e.told = true end
    elseif type(e) == "table" and e.k == "emote" and not e.told and not T.aimedAtYou(e.s) then
      table.remove(events, i)
      local p = type(e.who) == "string" and j.people[e.who]
      if type(p) == "table" then
        p.waves = math.max(0, (tonumber(p.waves) or 1) - 1)
        if p.waves == 0 then p.waves = nil end
        local other = false
        for k in pairs(p) do if k ~= "met" and k ~= "last" then other = true end end
        if not other then j.people[e.who] = nil end
      end
    end
  end
end

local function textEmote(text, sender)
  if type(text) ~= "string" or type(sender) ~= "string" or sender == "" then return end
  local self = me()
  local short = sender:match("^([^%-]+)") or sender
  if short == self or not T.aimedAtYou(text) then return end
  local day = math.floor(now() / 86400)
  if day ~= emoteDay then emoteDay, emotesToday, emoted = day, 0, {} end
  if emoted[short] or emotesToday >= 6 then return end
  emoted[short], emotesToday = true, emotesToday + 1
  person(short, "waves")
  J.add("emote", T.emoteLine(plain(text), plain(short), zone()), nil, { who = plain(short), told = true })
end

-- What someone's emote at you reads like in the journal: by the verb (hug, wave, lick, slap...), never
-- the raw chat line ("The X licks you").
local EMOTE_KIND = { hug = "warm", cuddle = "warm", kiss = "warm", love = "warm", embrace = "warm", pat = "warm", snuggle = "warm",
  wave = "greet", greet = "greet", hello = "greet", bow = "greet", salute = "greet", nod = "greet", welcome = "greet", hail = "greet",
  cheer = "cheer", applaud = "cheer", clap = "cheer", congratulate = "cheer", praise = "cheer", thank = "cheer", highfive = "cheer",
  dance = "silly", lick = "silly", poke = "silly", tickle = "silly", wink = "silly", flirt = "silly", giggle = "silly", flex = "silly",
  sniff = "silly", nuzzle = "silly", purr = "silly", moo = "silly", chicken = "silly", bonk = "silly", boop = "silly",
  slap = "rude", rude = "rude", spit = "rude", laugh = "rude", mock = "rude", taunt = "rude", glare = "rude", growl = "rude",
  threaten = "rude", insult = "rude", shoo = "rude", fart = "rude", point = "rude" }
local EMOTE_LINES = {
  warm = { "%who% gave you a hug in %zone%. You'll take it", "A warm moment in %zone%: %who% %act%",
    "%who% %act% in %zone%, out of nowhere. The road is kinder than it looks",
    "Got a little kindness from %who% in %zone%", "%who% %act% in %zone%, and the day got better" },
  greet = { "%who% %act% in %zone%. You waved back", "A stranger's greeting in %zone%: %who% %act%",
    "%who% stopped to say hello in %zone%", "Traded a nod with %who% on the road through %zone%",
    "%who% %act% in passing, somewhere in %zone%" },
  cheer = { "%who% %act% in %zone%. Somebody noticed", "A bit of applause from %who% in %zone%",
    "%who% %act% in %zone%, and you stood a little taller", "Earned a cheer from %who% in %zone%" },
  silly = { "%who% %act% in %zone%. Adventurers are strange folk", "In %zone%, %who% %act%. No explanation was offered",
    "%who% %act% in %zone%, then wandered off as if nothing happened", "%who% %act% in %zone%. Make of that what you will",
    "%who% %act% in %zone%. You've had worse days" },
  rude = { "%who% %act% in %zone%. Charming", "Rudeness on the road: %who% %act% in %zone%",
    "%who% %act% in %zone%. You've made a note of the name", "Not everyone in %zone% is friendly: %who% %act%",
    "%who% %act% in %zone%, and you rose above it. Mostly" },
  other = { "%who% %act% in %zone%", "A passing moment in %zone%: %who% %act%",
    "%who% singled you out in %zone%: %act%, of all things" },
}
local IRREGULAR = { spit = "spat", sing = "sang", bite = "bit", shake = "shook", throw = "threw", give = "gave", tell = "told",
  eat = "ate", sit = "sat", fight = "fought", run = "ran", hold = "held", stand = "stood", make = "made", blow = "blew" }
function T.past(word)
  local low = tostring(word or ""):lower()
  local base = low:gsub("ies$", "y"):gsub("([sxz])es$", "%1"):gsub("([cs]h)es$", "%1"):gsub("oes$", "o")
  if base == low then base = low:gsub("s$", "") end
  if IRREGULAR[base] then return IRREGULAR[base] end
  if base:find("e$") then return base .. "d" end
  if base:find("[^aeiou]y$") then return base:sub(1, -2) .. "ied" end
  if #base <= 4 and base:find("[^aeiou][aeiou][pgtbnmd]$") then return base .. base:sub(-1) .. "ed" end
  return base .. "ed"
end
function T.emoteLine(text, who, where)
  local low = (text or ""):lower()
  local name = (who or ""):lower()
  local after = low:find(name, 1, true) and low:sub((low:find(name, 1, true)) + #name) or low
  local word = after:match("^%s*(%a+)") or ""
  local verb = word:gsub("ies$", "y"):gsub("([sxz])es$", "%1"):gsub("([cs]h)es$", "%1"):gsub("s$", "")
  local kind = EMOTE_KIND[verb] or "other"
  if word == "" then kind, word = "greet", "greets" end
  -- what they did, in the client's own words after the name: "licks you", "laughs at you", "looks at you strangely"
  local act = (text or ""):sub(#((text or ""):match("^.-" .. (who or ""):gsub("%p", "%%%0")) or "") + 1)
  act = act:gsub("^%s+", ""):gsub("[%.!%s]+$", "")
  if act == "" or not T.aimedAtYou(act) then act = word .. " you" end
  -- the journal speaks in the past: "licks you" -> "licked you"
  act = act:gsub("^(%a+)", function(w) return T.past(w) end, 1)
  local vars = { who = who, zone = where, verb = word, act = act }
  return J.fresh and J.fresh(EMOTE_LINES[kind], who .. verb, "emote", vars) or J.fill(EMOTE_LINES[kind][1], vars)
end

local function guildCheck(seed)
  local name = try(GetGuildInfo, "player")
  local j = journal()
  if type(name) ~= "string" or name == "" then return end
  if j.guild == name then return end
  local had = j.guild
  j.guild = name
  if seed and not had then return end -- the guild you were in when the journal began
  J.add("guild", J.fill(J.pick({ "Joined the guild %g% in %zone%. New friends, new stories", "Pulled on the tabard of %g% in %zone%",
    "%g% took you in, in %zone%. A family of sorts", "Signed the charter of %g% in %zone%: one of them now" }, name),
    { g = "<" .. plain(name) .. ">", zone = zone() }), "Guild")
end

----------------------------------------------------------------------------
-- Campfires
----------------------------------------------------------------------------

local lastCamp = -1e9
local CAMP_LIT = { "Made camp in %zone%: struck flint and lit a campfire", "Built a campfire in %zone% and settled in for a while",
  "Gathered sticks and lit a fire in %zone%, and the night felt smaller", "Set a fire crackling in %zone% and put your boots up",
  "Struck a spark in %zone% and made a little home for the night" }
local CAMP_SAT = { "Sat by the campfire in %zone%%with%, warming your hands", "Rested at a campfire in %zone%%with%, trading tales",
  "Shared the warmth of a campfire in %zone%%with%", "Watched the sparks rise from a campfire in %zone%%with%",
  "Sat a while by the fire in %zone%%with%, saying nothing much", "Toasted bread over a campfire in %zone%%with%" }
local function spellName(id)
  local name = C_Spell and try(C_Spell.GetSpellName, id)
  if not name then name = try(GetSpellInfo, id) end
  return type(name) == "string" and name or nil
end
local function campfire(lit)
  if now() - lastCamp < 1800 then return end
  lastCamp = now()
  bump("camps")
  local party = J.partyText()
  local vars = { zone = zone(), with = party and (" with " .. party) or "" }
  J.add("camp", J.fill(J.pick(lit and CAMP_LIT or CAMP_SAT, vars.zone .. now()), vars), "Campfire")
end
local function castDone(unit, _, spell)
  if unit ~= "player" then return end
  local name = spellName(spell)
  if name and name:find("Campfire", 1, true) then campfire(true) end
end
-- A campfire's buff on you (out of combat only: reading auras in combat throws).
local function campAura()
  if try(InCombatLockdown) or try(UnitAffectingCombat, "player") then return end
  for i = 1, 40 do
    local name
    local data = C_UnitAuras and try(C_UnitAuras.GetBuffDataByIndex, "player", i)
    if type(data) == "table" then name = data.name
    elseif not C_UnitAuras then name = try(UnitBuff, "player", i) end
    if type(name) ~= "string" then return end
    if name:find("Campfire", 1, true) or name:find("Cozy", 1, true) then campfire(false); return end
  end
end

----------------------------------------------------------------------------
-- Crafting and professions
----------------------------------------------------------------------------

local WORKPLACE = { Blacksmithing = "at the anvil", Tailoring = "at the loom", Alchemy = "over bubbling flasks",
  Cooking = "over the cooking fire", Enchanting = "at the enchanting table", Engineering = "at the workbench",
  Leatherworking = "at the tanning rack", ["First Aid"] = "rolling bandages", Mining = "at the smelter",
  Smelting = "at the smelter", Jewelcrafting = "at the jeweler's bench" }
local craft
local function professionName()
  local name = try(GetTradeSkillLine)
  if type(name) ~= "string" or name == "" or name == "UNKNOWN" then
    local info = C_TradeSkillUI and try(C_TradeSkillUI.GetBaseProfessionInfo)
    name = type(info) == "table" and info.professionName or nil
  end
  return type(name) == "string" and name ~= "" and plain(name) or nil
end
local function craftStart()
  local prof = professionName()
  if craft and craft.prof == prof then return end
  if craft then T.craftEnd() end
  craft = { prof = prof, start = now(), made = {}, order = {}, n = 0 }
end
local function created(text)
  local a = read(text, "LOOT_ITEM_CREATED_SELF_MULTIPLE", "You create: %sx%d.")
  local count = a and tonumber(a[2])
  if not a then a = read(text, "LOOT_ITEM_CREATED_SELF", "You create: %s.") end
  if not a or not craft then return end
  local name = itemName(a[1])
  if not name then return end
  count = count or 1
  if not craft.made[name] then craft.order[#craft.order + 1] = name end
  craft.made[name] = (craft.made[name] or 0) + count
  craft.n = craft.n + count
end
function T.craftEnd()
  local c = craft
  craft = nil
  if not c or c.n == 0 then return end
  bump("crafted", c.n)
  local things = {}
  for i, name in ipairs(c.order) do
    if i > 3 then things[#things] = things[#things] .. " and more"; break end
    things[#things + 1] = c.made[name] .. " " .. name
  end
  local where = WORKPLACE[c.prof or ""] or ("at your " .. (c.prof or "craft"))
  local spent = now() - c.start
  local lead = T.lateNight() and ("Toiled late into the night " .. where)
    or (spent >= 600 and ("Spent " .. minutes(spent) .. " " .. where) or ("Worked " .. where))
  local text = lead .. " in " .. zone() .. ": made " .. list(things)
  local detail = c.prof and (c.from and c.to and c.to > c.from) and (c.prof .. " " .. c.from .. " to " .. c.to) or c.prof
  J.add("craft", text, detail, { n = c.n })
end

local MILESTONE_SKIP = { [75] = true, [150] = true, [225] = true, [300] = true } -- JourneyDeeds writes the caps
local function professionSkills()
  local set = { Cooking = true, ["First Aid"] = true, Fishing = true }
  for _, key in ipairs(ns.PROF_ORDER or {}) do
    local P = ns.P and ns.P[key]
    if P and P.name then set[P.name] = true end
  end
  return set
end
local skillCache = {}
local function skillUp(text)
  local a = read(text, "SKILL_RANK_UP", "Your skill in %s has increased to %d.")
  if not a then return end
  local name, rank = plain(a[1]), tonumber(a[2])
  if not rank or not professionSkills()[name] then return end
  if craft and (craft.prof == name or (name == "Mining" and craft.prof == "Smelting")) then
    craft.from = craft.from or rank - 1
    craft.to = rank
  end
  local was = skillCache[name]
  skillCache[name] = rank
  if rank % 50 ~= 0 or MILESTONE_SKIP[rank] or (was and was >= rank) then return end
  local text2 = T.lateNight() and (name .. " reached " .. rank .. " deep in the night, in " .. zone() .. ". One more, then bed")
    or (name .. " reached " .. rank .. " in " .. zone() .. ". The craft grows with you")
  J.add("skill", text2, name .. " " .. rank)
end

----------------------------------------------------------------------------
-- The auction house, the mailbox and your purse
----------------------------------------------------------------------------

local visit
local function money() return num(try(GetMoney)) end
local function ahOpen()
  visit = { money = money(), posts = 0, buys = 0, start = now(), place = zone() }
end
local function ahClose()
  local v = visit
  visit = nil
  if not v or (v.posts == 0 and v.buys == 0) then return end
  local after = money()
  local spent = v.money and after and (v.money - after) or 0
  local firstPost = v.posts > 0 and T.tally("posted") == 0
  local firstBuy = v.buys > 0 and T.tally("bought") == 0
  bump("posted", v.posts)
  bump("bought", v.buys)
  if not (firstPost or firstBuy) and T.foldVisit(v, spent) then return end
  local deeds = {}
  if v.posts > 0 then deeds[#deeds + 1] = "put " .. plural(v.posts, "lot") .. " up for sale" end
  if v.buys > 0 then deeds[#deeds + 1] = "bought " .. plural(v.buys, "lot") end
  local text = "Haggled at the auction house in " .. v.place .. ": " .. list(deeds)
  if firstPost then text = "Your first auction! At the auction house in " .. v.place .. " you " .. list(deeds)
  elseif firstBuy then text = "Your first auction house purchase, in " .. v.place .. ": you " .. list(deeds) end
  local e = J.add("auction", text, spent > 0 and (ns.money(spent) .. " spent") or "Auction house")
  if e and not (firstPost or firstBuy) then
    e.ah = { v = 1, p = v.posts, b = v.buys, sp = math.max(0, spent), at = now() }
  end
end

-- A trader comes back to the auction house all day: visits to the same one within T.AH_FOLD (3 h)
-- of the last, at the same level, join one moment that keeps the sums (e.ah = visits, posts, buys,
-- spent, last visit) instead of writing a line each.
T.AH_FOLD = 3 * 3600
local AH_DAY = { "Spent the day trading at the auction house in %s", "A long session of haggling at the %s auction house",
  "Worked the auction house in %s like a merchant prince", "Back and forth at the auction house in %s, deal after deal" }
function T.foldVisit(v, spent)
  local events = J.data().events
  local lvl = J.level()
  for i = #events, math.max(1, #events - 40), -1 do
    local e = events[i]
    if e.k == "auction" and type(e.ah) == "table" then
      if tonumber(e.l) ~= lvl or now() - (tonumber(e.ah.at) or 0) > T.AH_FOLD or not e.s:find(v.place, 1, true) then return false end
      local a = e.ah
      a.v, a.p, a.b = (a.v or 1) + 1, (a.p or 0) + v.posts, (a.b or 0) + v.buys
      a.sp, a.at = (a.sp or 0) + math.max(0, spent), now()
      local deeds = {}
      if a.b > 0 then deeds[#deeds + 1] = "bought " .. plural(a.b, "lot") end
      if a.p > 0 then deeds[#deeds + 1] = "put " .. plural(a.p, "lot") .. " up for sale" end
      local head = string.format(AH_DAY[(math.floor(tonumber(e.t) or 0) % #AH_DAY) + 1], v.place)
      rewrite(e, head .. ": " .. a.v .. " visits, " .. list(deeds), a.sp > 0 and (ns.money(a.sp) .. " spent") or "Auction house")
      return true
    end
  end
  return false
end

local lastSale, lastExpired
local function soldOrExpired(text)
  local a = read(text, "ERR_AUCTION_SOLD_S", "A buyer has been found for your auction of %s.")
  local kind = "sold"
  if not a then a = read(text, "ERR_AUCTION_EXPIRED_S", "Your auction of %s has expired."); kind = "expired" end
  if not a then
    a = read(text, "ERR_AUCTION_WON_S", "You won an auction for %s")
    if a then bump("bought") end
    return
  end
  local name = itemName(a[1]) or "your wares"
  bump(kind)
  if kind == "sold" then T.unpaid = (T.unpaid or 0) + 1 end
  local prev = kind == "sold" and lastSale or lastExpired
  if prev and prev.e and now() - prev.t <= 1800 then
    prev.items[#prev.items + 1] = name
    prev.t = now()
    local items = list(prev.items)
    if #prev.items > 4 then items = prev.items[1] .. ", " .. prev.items[2] .. " and " .. (#prev.items - 2) .. " more" end
    rewrite(prev.e, kind == "sold" and ("Buyers snapped up your " .. items) or ("Nobody wanted your " .. items .. ": back they came, unsold"),
      #prev.items .. (kind == "sold" and " sold" or " expired"))
    return
  end
  local e = J.add(kind, J.fill(J.pick(kind == "sold" and { "A buyer snapped up your %item% at the auction house",
      "Your %item% sold at the auction house. Coin on its way", "Somebody out there wanted your %item%, and paid for it" }
    or { "Nobody wanted your %item%: the auction came back unsold", "Your %item% came home from the auction house unsold",
      "The %item% sat on the auction house, and nobody bit" }, name .. now()), { item = name }), kind == "sold" and "1 sold" or "1 expired")
  local rec = { e = e, t = now(), items = { name } }
  if kind == "sold" then lastSale = rec else lastExpired = rec end
end

local mailMoney
local function mailOpen() mailMoney = money() end
local function mailClose()
  local before = mailMoney
  mailMoney = nil
  local after = money()
  if not before or not after or after <= before or (T.unpaid or 0) == 0 then return end
  local gained = after - before
  local sales = T.unpaid
  T.unpaid = 0
  bump("ahGold", gained)
  J.add("gold", J.fill(J.pick({ "Collected %m% from the auction house at the mailbox in %zone%. The trade pays",
    "Opened the mail in %zone% to %m% from the auction house", "The mailbox in %zone% held %m% in sales. A merchant's smile",
    "%m% in auction money waited at the mailbox in %zone%" }, now()), { m = ns.money(gained), zone = zone() }), plural(sales, "sale"))
end

local PURSE = { { 10000, "Your first gold coin. The road ahead looks a little brighter" },
  { 100000, "Ten gold to your name. Merchants start to smile when you walk in" },
  { 500000, "Fifty gold in your purse: a fortune for an adventurer" },
  { 1000000, "A hundred gold! Your purse has never been this heavy" },
  { 5000000, "Five hundred gold: they speak of your wealth in the taverns" },
  { 10000000, "A thousand gold. A small dragon's hoard of your own" } }
local purseSeeded
local function purse()
  local m = money()
  if not m then return end
  local j = journal()
  local best = tonumber(j.tally.richest) or 0
  if m > best then j.tally.richest = m end
  if not purseSeeded then
    purseSeeded = true
    if (tonumber(j.tally.purseMark) or 0) == 0 then
      -- what you already had when the journal began counts as known, not new
      local mark = 0
      for i, p in ipairs(PURSE) do if math.max(m, best) >= p[1] then mark = i end end
      j.tally.purseMark = mark > 0 and mark or -1
      return
    end
  end
  local mark = math.max(0, tonumber(j.tally.purseMark) or 0)
  local reached = mark
  for i, p in ipairs(PURSE) do if m >= p[1] then reached = math.max(reached, i) end end
  if reached > mark then
    j.tally.purseMark = reached
    J.add("gold", PURSE[reached][2], ns.money(m) .. " in your purse")
  end
end

----------------------------------------------------------------------------
-- Quests taken and given up
----------------------------------------------------------------------------

local function questAccepted(a, b)
  local id = num(b) or num(a)
  if not id or id <= 0 then return end
  local j = journal()
  local _, _, map = J.here()
  j.taken[id] = { t = now(), l = level(), m = map }
end

local function doneQuest(id)
  local done = C_QuestLog and try(C_QuestLog.IsQuestFlaggedCompleted, id)
  if done == nil then done = try(IsQuestFlaggedCompleted, id) end
  if done == true or done == 1 or Q.turnedIn(id) then return true end
  local events = J.data().events
  for i = #events, math.max(1, #events - 30), -1 do
    if events[i].q == id then return true end
  end
  return false
end

local GIVE_UP = { "Gave up on %title% in %zone%. Some battles aren't worth fighting",
  "Tore %title% out of the quest log. Not every story gets an ending", "Let %title% go. Maybe another hero will finish it",
  "Crossed %title% off the list unfinished, in %zone%", "Shrugged and dropped %title%. Life is short and the log is full",
  "Decided %title% was someone else's problem" }
local function questRemoved(id)
  id = num(id)
  if not id then return end
  local title = Q.log(id) and Q.log(id).title or Q.questName(id)
    or (C_QuestLog and try(C_QuestLog.GetTitleForQuestID, id))
  ns.after(2, function()
    local j = journal()
    local taken = j.taken[id]
    j.taken[id] = nil
    if Q.log(id) or doneQuest(id) then return end
    bump("abandoned")
    local line = J.abandonLine and J.abandonLine(id, plain(title or "a quest"), zone(), taken)
    J.add("abandon", line or J.fill(J.pick(GIVE_UP, id), { title = plain(title or "a quest"), zone = zone() }),
      title and ("Quest: " .. plain(title)) or nil, { q = id, l = taken and taken.l or nil })
  end)
end
function T.taken(id) return journal().taken[id] end

----------------------------------------------------------------------------
-- Wiring
----------------------------------------------------------------------------

local HANDLERS = {
  PLAYER_ENTERING_WORLD = function() enteredWorld(); guildCheck(true); purse() end,
  ZONE_CHANGED_NEW_AREA = enteredWorld,
  ENCOUNTER_END = encounterEnd,
  UPDATE_BATTLEFIELD_SCORE = battlefieldScore,
  CHAT_MSG_COMBAT_HONOR_GAIN = honorGain,
  CHAT_MSG_SYSTEM = function(text)
    local a = read(text, "DUEL_WINNER_KNOCKOUT", "%1$s has defeated %2$s in a duel")
    if a then duel(a[1], a[2]); return end
    a = read(text, "DUEL_WINNER_RETREAT", "%2$s has fled from %1$s in a duel")
    if a then duel(a[1], a[2], true); return end
    if text == ERR_TRADE_COMPLETE or text == "Trade complete." then tradeDone(); return end
    soldOrExpired(text)
  end,
  UI_INFO_MESSAGE = function(_, text)
    if text == ERR_TRADE_COMPLETE or text == "Trade complete." then tradeDone() end
  end,
  TRADE_SHOW = function()
    tradeWith, tradeBoth = try(UnitName, "NPC"), nil
    if type(tradeWith) ~= "string" or tradeWith == "" then
      local fs = _G.TradeFrameRecipientNameText
      tradeWith = fs and fs.GetText and fs:GetText() or nil
    end
  end,
  -- both sides accepted, then the window closed: the trade went through (when "Trade complete." isn't read)
  TRADE_ACCEPT_UPDATE = function(mine, theirs) tradeBoth = (mine == 1 or mine == true) and (theirs == 1 or theirs == true) end,
  TRADE_CLOSED = function() if tradeBoth then tradeBoth = nil; ns.after(0.5, tradeDone) end end,
  RESURRECT_REQUEST = function(name) if type(name) == "string" then rezBy = { name = name, t = now() } end end,
  PLAYER_DEAD = function() deadAt = now() end,
  PLAYER_ALIVE = function()
    local ghost = try(UnitIsGhost, "player")
    if ghost == true or ghost == 1 then return end -- released: the walk back starts
    revived(false)
  end,
  PLAYER_UNGHOST = function() revived(true) end,
  CHAT_MSG_TEXT_EMOTE = textEmote,
  PLAYER_GUILD_UPDATE = function() guildCheck(false) end,
  UNIT_SPELLCAST_SUCCEEDED = castDone,
  TRADE_SKILL_SHOW = craftStart,
  TRADE_SKILL_CLOSE = function() T.craftEnd() end,
  CHAT_MSG_LOOT = created,
  CHAT_MSG_SKILL = skillUp,
  AUCTION_HOUSE_SHOW = ahOpen,
  AUCTION_HOUSE_CLOSED = ahClose,
  AUCTION_HOUSE_AUCTION_CREATED = function() if visit then visit.posts = visit.posts + 1 end end,
  COMMODITY_PURCHASE_SUCCEEDED = function() if visit then visit.buys = visit.buys + 1 end end,
  AUCTION_HOUSE_PURCHASE_COMPLETED = function() if visit then visit.buys = visit.buys + 1 end end,
  MAIL_SHOW = mailOpen,
  MAIL_CLOSED = mailClose,
  PLAYER_MONEY = purse,
  QUEST_ACCEPTED = questAccepted,
  QUEST_REMOVED = questRemoved,
}

local frame
function ns.startJourneyTales()
  if frame then return end
  journal()
  frame = CreateFrame("Frame")
  for event in pairs(HANDLERS) do
    if event == "UNIT_SPELLCAST_SUCCEEDED" and frame.RegisterUnitEvent then
      pcall(frame.RegisterUnitEvent, frame, event, "player")
    else
      pcall(frame.RegisterEvent, frame, event)
    end
  end
  frame:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(HANDLERS[event], ...)
    if not ok and not T.errored then T.errored = true; ns.say("journey error: " .. plain(err)) end
  end)
  pcall(dropStrayEmotes)
  pcall(enteredWorld)
  pcall(guildCheck, true)
  pcall(purse)
  ns.every(10, function()
    local ok, err = pcall(campAura)
    if not ok and not T.errored then T.errored = true; ns.say("journey error: " .. plain(err)) end
  end)
end

----------------------------------------------------------------------------
-- The Trophies ledger and the Companions page's friends and strangers
----------------------------------------------------------------------------

local function moments(kinds, limit)
  return J.deeds and J.deeds.moments(kinds, limit) or {}
end

-- One moment as a row of a list card (absolute x); returns its height.
local function momentRow(V, e, x, y, w)
  local U, C, D = V.U, V.C, J.draw
  U.icon(J.ICON[e.k] or J.ICON.quest, x + 14, y, 22, e.s, e.d)
  local h = U.T(e.s, x + 44, y + 1, w - 58, "small", C.light)
  U.T((e.d and (e.d .. "  -  ") or "") .. "level " .. (e.l or "?") .. ", day " .. D.dayOf(V.j, e.t), x + 44, y + h + 3, w - 58, "small", C.dim)
  return math.max(28, h + 22)
end

local LEDGER = {
  { "BATTLES", "Ability_DualWield", {
    { "Dungeon runs", "runs" }, { "Wipes", "wipes" }, { "Honorable kills", "honor" },
    { "Duels won", "duelsWon" }, { "Duels lost", "duelsLost" }, { "Battlegrounds won", "bgWon" }, { "Battlegrounds lost", "bgLost" } } },
  { "FORTUNES", "INV_Misc_Coin_04", {
    { "Auctions posted", "posted" }, { "Auctions sold", "sold" }, { "Came back unsold", "expired" }, { "Lots bought", "bought" },
    { "Gold from auctions", "ahGold", true }, { "Richest you've been", "richest", true }, { "Things crafted", "crafted" } } },
  { "FELLOWSHIP", "Spell_Holy_PrayerOfHealing", {
    { "Raised by others", "rezzed" }, { "Trades", "trades" }, { "Campfires", "camps" }, { "Quests given up", "abandoned" } } },
}

-- One column of the ledger as a passage of the page.
local function ledgerCard(V, y, col)
  local U, C, W = V.U, V.C, V.W
  local top = y
  U.icon(col[2], 14, y + 12, 22, col[1], nil)
  U.T("THE LEDGER  -  " .. col[1], 44, y + 17, W - 58, "label", C.inkSoft)
  y = y + 42
  for _, r in ipairs(col[3]) do
    local v = T.tally(r[2])
    U.T(r[1], 14, y, W - 28, "small", C.ink)
    U.T(r[3] and (v > 0 and ns.money(v) or "-") or ns.thousands(v), 14, y, W - 28, "small", v > 0 and C.ink or C.inkSoft, "RIGHT")
    U.rect(14, y + 15, W - 28, 1, { 0, 0, 0, 0.1 }, "border")
    y = y + 20
  end
  y = y + 8
  J.draw.page(U, C, 0, top, W, y - top)
  return y
end

local function momentsCard(title, kinds, empty)
  return function(V, y)
    return J.draw.listCard(V, title, nil, 0, y, V.W, moments(kinds, 5), empty,
      function(e, yy) return momentRow(V, e, 0, yy, V.W) end)
  end
end

T.momentsCard = momentsCard

-- The Trophies page's sections from this file, each fn(V, y) -> y (the book flows them into its columns),
-- then those other files add to J.moreTrophies (JourneyWilds.lua).
function T.trophySections()
  local out = {}
  for _, fn in ipairs(J.moreTrophies or {}) do out[#out + 1] = fn end
  for _, col in ipairs(LEDGER) do out[#out + 1] = function(V, y) return ledgerCard(V, y, col) end end
  out[#out + 1] = momentsCard("AT THE WORKBENCH", { craft = true, skill = true },
    "Craft something, or raise a profession past 50, 100, 200 or 250, and it is written here.")
  out[#out + 1] = momentsCard("THE AUCTION HOUSE", { auction = true, sold = true, expired = true, gold = true },
    "Your auctions, sales, lots that came back and the gold you collected show up here.")
  out[#out + 1] = momentsCard("DUNGEON RUNS", { run = true, wipe = true },
    "Each dungeon run is told when you leave it: the time, the bosses, the wipes and who came along.")
  out[#out + 1] = momentsCard("BATTLEFIELDS", { pvp = true, bg = true, duel = true },
    "Duels, battlegrounds, honorable kills and fights with other players are kept here.")
  return out
end

-- The people you met: { name, rec, score } with the most shared moments first.
function T.people()
  local out = {}
  for name, rec in pairs(journal().people) do
    if type(rec) == "table" then
      local score = (tonumber(rec.trades) or 0) + 2 * (tonumber(rec.rez) or 0) + (tonumber(rec.duels) or 0) + (tonumber(rec.waves) or 0)
        + (tonumber(rec.whispers) or 0) + 2 * (tonumber(rec.saved) or 0) + (tonumber(rec.camp) or 0) + (tonumber(rec.toasts) or 0)
        + (tonumber(rec.killedMe) or 0) + (tonumber(rec.witness) or 0)
      out[#out + 1] = { name = name, rec = rec, score = score }
    end
  end
  table.sort(out, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.name < b.name end)
  return out
end

local function deedsOf(rec)
  local parts = {}
  local function add(n, one, many) n = tonumber(n) or 0; if n > 0 then parts[#parts + 1] = plural(n, one, many) end end
  add(rec.rez, "resurrection")
  add(rec.trades, "trade")
  add(rec.duels, "duel")
  add(rec.waves, "kind word", "kind words")
  add(rec.whispers, "whispered talk", "whispered talks")
  add(rec.saved, "time they tried to save you", "times they tried to save you")
  add(rec.witness, "fall they saw", "falls they saw")
  add(rec.camp, "campfire shared", "campfires shared")
  add(rec.toasts, "toast", "toasts")
  add(rec.thanksGot, "thank you", "thank yous")
  add(rec.memGot, "memory they sent", "memories they sent")
  add(rec.killedMe, "time they killed you", "times they killed you")
  if #parts == 0 and rec.added then return "added by hand" end
  return #parts > 0 and table.concat(parts, ", ") or "crossed paths"
end

function T.companions(V, y)
  local U, C, W = V.U, V.C, V.W
  local D = J.draw
  local people = T.people()
  local shown = {}
  for i = 1, math.min(20, #people) do shown[i] = people[i] end
  return D.listCard(V, "FRIENDS AND STRANGERS", #people > 0 and tostring(#people) or nil, 0, y, W, shown,
    "Players who raise you, trade with you, duel you or wave at you are remembered here.", function(p, yy)
      U.icon(p.rec.rez and J.ICON.rez or (p.rec.trades and J.ICON.trade) or (p.rec.duels and J.ICON.duel) or J.ICON.emote,
        14, yy, 22, plain(p.name), deedsOf(p.rec))
      U.T(plain(p.name), 44, yy + 1, W - 150, "body", C.light)
      U.T("met on day " .. D.dayOf(V.j, p.rec.met), 14, yy + 1, W - 28, "small", C.dim, "RIGHT")
      U.T(deedsOf(p.rec), 44, yy + 16, W - 58, "small", C.dim)
      if J.companions then
        U.hit(10, yy - 2, W - 20, 32, plain(p.name), deedsOf(p.rec) .. "\nClick to open their page.", function()
          J.companions.select(p.name)
          U.refresh()
        end, "Companion " .. plain(p.name))
      end
      return 34
    end) + 10
end

-- Today's entry: the MMO moments this session, as sentences (JourneyDeeds' D.today adds them).
function T.todayLines(since)
  local c = {}
  for _, e in ipairs(J.data().events) do
    if (e.t or 0) >= since then c[e.k] = (c[e.k] or 0) + 1 end
  end
  local out = {}
  if (c.run or 0) > 0 or (c.wipe or 0) > 0 then
    out[#out + 1] = "Dungeon runs: " .. plural(c.run or 0, "run") .. ((c.wipe or 0) > 0 and (", " .. plural(c.wipe, "wipe")) or "") .. "."
  end
  if (c.pvp or 0) + (c.bg or 0) + (c.duel or 0) > 0 then out[#out + 1] = "Steel was crossed with other players." end
  if (c.rez or 0) > 0 then out[#out + 1] = c.rez == 1 and "Someone brought you back from the dead." or ("You were raised " .. c.rez .. " times.") end
  if (c.craft or 0) > 0 then out[#out + 1] = plural(c.craft, "session") .. " at the workbench" .. (T.lateNight() and ", late into the night." or ".") end
  if (c.auction or 0) + (c.sold or 0) > 0 then out[#out + 1] = "The auction house saw you" .. ((c.sold or 0) > 0 and ", and buyers found your wares." or ".") end
  if (c.camp or 0) > 0 then out[#out + 1] = "A campfire warmed you." end
  if (c.abandon or 0) > 0 then out[#out + 1] = plural(c.abandon, "quest") .. " left behind." end
  return out
end

function ns.journeyTalesDebugLines()
  local j = journal()
  local parts = {}
  for _, k in ipairs({ "runs", "wipes", "honor", "duelsWon", "duelsLost", "bgWon", "bgLost", "rezzed", "trades", "camps",
    "crafted", "posted", "bought", "sold", "expired", "abandoned" }) do
    local v = tonumber(j.tally[k]) or 0
    if v > 0 then parts[#parts + 1] = k .. " " .. v end
  end
  return { "journey tales: " .. (#parts > 0 and table.concat(parts, ", ") or "nothing yet")
    .. (run and (", in " .. run.name .. " (" .. run.bosses .. " bosses, " .. run.wipes .. " wipes)") or "")
    .. (craft and (", crafting " .. (craft.prof or "?") .. " (" .. craft.n .. " made)") or "") }
end
