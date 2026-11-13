-- Horde route, levels 30-40. Source notes: tools/audits/2026-11-12-horde-30-40.md.
-- Shared Horde 30-60 setup lives at the top of this file: map sizes and flight networks for every
-- 30-60 map, the zeppelins and boats, and the B.horde helpers that QuestHorde4050.lua,
-- QuestHorde5060.lua, QuestHordeDungeons3060.lua and QuestHordeClass3060.lua use.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local M = B.maps

-- Map sizes: the Alliance 30-60 file already holds the client's UiMapAssignment sizes for every
-- 30-60 map. The Horde numbers its flight networks the other way round (Kalimdor 1, Eastern
-- Kingdoms 2), so the continent number is swapped as it is copied.
do
  local alliance = LevelingCodexQuests.ALLIANCE
  local swap = { [1] = 2, [2] = 1 }
  for map, size in pairs(alliance.extents) do
    route.extents[map] = route.extents[map] or size
  end
  for map, network in pairs(alliance.flightNetwork) do
    route.flightNetwork[map] = route.flightNetwork[map] or swap[network]
  end
end

local H = {}
B.horde = H

-- One leveling section of the Horde route.
function H.section(id, title, zone, low, high, sources, steps, extra)
  local section = { id = id, title = title, zone = zone, levels = { low, high }, verified = false,
    sources = sources, steps = steps }
  for key, value in pairs(extra or {}) do section[key] = value end
  route.sections[#route.sections + 1] = section
  return section
end

-- Quests carried in from an earlier chapter. A turn-in or objective whose pickup is not on the
-- Horde main route yet becomes optional (shown only while the quest is in your log); a pickup
-- whose prerequisite the main route never gives is dropped.
function H.carried(steps)
  local seen = {}
  for _, s in ipairs(route.sections) do
    if not s.side and not s.alternate then
      for _, step in ipairs(s.steps) do
        if step.quest and step.type == "accept" then seen[step.quest] = true end
      end
    end
  end
  local kept = {}
  for _, step in ipairs(steps) do
    local keep = true
    if step.quest and step.type == "accept" then
      for _, pre in ipairs(step.chain or {}) do
        if not seen[pre] then keep = false end
      end
      if keep then seen[step.quest] = true end
    elseif step.quest and not seen[step.quest] and not step.logOnly then
      step.optional = true
    end
    if keep then kept[#kept + 1] = step end
  end
  return kept
end

-- A main-route chapter (steps pass through H.carried) and an alternate route.
function H.chapter(id, title, zone, low, high, sources, suggest, steps)
  return H.section(id, title, zone, low, high, sources, H.carried(steps), { suggest = suggest })
end

function H.alternate(id, title, zone, low, high, sources, suggest, steps)
  return H.section(id, title, zone, low, high, sources, steps, { alternate = true, suggest = suggest })
end

-- Quest facts: q() always (re)defines, need() fills a gap only (the Alliance files register
-- many neutral 30-60 quests first; their chains are the same game facts).
function H.need(id, name, level, min, prerequisite, forever)
  if not B.quest[id] then B.q(id, name, level, min, prerequisite, forever) end
  return B.quest[id]
end

-- Limit a quest to some races or classes (QuestieDB requiredRaces / requiredClasses).
function H.limit(id, rules)
  for key, value in pairs(rules) do B.quest[id][key] = value end
end

-- A pickup for a dungeon detour (shown while that run is planned).
function H.dungeon(id, step) return B.forDungeon(step, "dungeon-" .. id) end

-- A boat, zeppelin or road the arrow uses when no known flight path joins two maps.
function H.road(from, to, waypoint, label)
  route.roadTo[to] = route.roadTo[to] or {}
  route.roadTo[to][from] = route.roadTo[to][from] or { waypoint = waypoint, label = label }
end

-- The Alliance dungeon guide's boss list (same instance, same bosses), for a Horde guide.
function H.bosses(id)
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == id then return section.bosses end
  end
  error("Horde 30-60: no Alliance dungeon guide " .. id)
end

-- A Horde dungeon guide with the Alliance guide's facts (title, map, levels, instance, bosses) and
-- only its entrance step: a placeholder until the Horde guide's own steps are written. `levels`
-- overrides the Alliance range when the Horde runs it at other levels.
function H.placeholderDungeon(id, levels)
  for _, a in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if a.id == id then
      local entry
      for _, step in ipairs(a.steps) do
        if step.type == "dungeon" and step.map then entry = step; break end
      end
      local enter = { type = "dungeon", phase = "prepare", name = a.title, npc = entry and entry.npc,
        map = entry and entry.map, x = entry and entry.x, y = entry and entry.y,
        text = "Travel to " .. a.title .. " with your group and go in together." }
      route.sections[#route.sections + 1] = { id = id, title = a.title, zone = a.zone,
        levels = levels or { a.levels[1], a.levels[2] }, instanceID = a.instanceID, instance = a.instance,
        bosses = a.bosses, side = true, category = "dungeon", verified = false, sources = a.sources,
        steps = { enter } }
      return
    end
  end
  error("Horde 30-60: no Alliance dungeon guide " .. id)
end

-- Places on the 30-60 maps: B.on.<map>(name, x, y) (QuestData3040.lua), B.on.durotar etc. below.
for _, name in ipairs({ "durotar", "orgrimmar", "thunderBluff", "undercity", "mulgore", "barrens",
    "tirisfal", "silverpine", "stonetalon", "ashenvale", "hillsbrad", "needles", "alterac", "arathi",
    "desolace", "dustwallow" }) do
  local id = M[name]
  B.on[name] = B.on[name] or function(npc, x, y) return B.at(npc, x, y, id) end
end

-- Zeppelins and boats (zeppelin masters' spots from QuestieDB Forever).
do
  local road, at = H.road, B.at
  local durotarToGromgol = at("Snurk Bucksquick", 50.7, 12.9, M.durotar)
  local gromgolToOrgrimmar = at("Nez'raz", 31.4, 29.9, M.stv)
  local gromgolToUndercity = at("Squibby Overspeck", 31.5, 29.4, M.stv)
  local tirisfalToGromgol = at("Hin Denburg", 61.8, 59.2, M.tirisfal)
  local bootyBayPier = at(nil, 25.8, 73.1, M.stv)
  local ratchetPier = at(nil, 63.7, 38.6, M.barrens)
  road(M.durotar, M.stv, durotarToGromgol, "Take the zeppelin to Grom'gol")
  road(M.orgrimmar, M.stv, durotarToGromgol, "Leave Orgrimmar for the zeppelin to Grom'gol")
  road(M.tirisfal, M.stv, tirisfalToGromgol, "Take the zeppelin to Grom'gol")
  road(M.undercity, M.stv, tirisfalToGromgol, "Leave the Undercity for the zeppelin to Grom'gol")
  road(M.stv, M.durotar, gromgolToOrgrimmar, "Take the zeppelin to Orgrimmar")
  road(M.stv, M.orgrimmar, gromgolToOrgrimmar, "Take the zeppelin to Orgrimmar")
  road(M.stv, M.tirisfal, gromgolToUndercity, "Take the zeppelin to the Undercity")
  road(M.stv, M.undercity, gromgolToUndercity, "Take the zeppelin to the Undercity")
  road(M.undercity, M.durotar, at(nil, 60.8, 58.7, M.tirisfal), "Take the zeppelin to Orgrimmar")
  road(M.undercity, M.orgrimmar, at(nil, 60.8, 58.7, M.tirisfal), "Take the zeppelin to Orgrimmar")
  road(M.orgrimmar, M.undercity, at(nil, 50.8, 13.8, M.durotar), "Leave Orgrimmar for the zeppelin to the Undercity")
  road(M.barrens, M.stv, ratchetPier, "Take the Booty Bay boat from the Ratchet dock")
  road(M.stv, M.barrens, bootyBayPier, "Take the Ratchet boat from the Booty Bay docks")
  -- Overland legs out of the Horde towns used by more than one band.
  road(M.barrens, M.dustwallow, at(nil, 56.4, 63.6, M.barrens), "Take the east road out of the Barrens into Dustwallow")
  road(M.needles, M.tanaris, B.on.needles(nil, 75.5, 96.9), "Follow the Shimmering Flats road south into Tanaris")
  road(M.tanaris, M.ungoro, B.on.tanaris(nil, 27.8, 56.9), "Go west through the ridge path into Un'Goro")
  road(M.ungoro, M.silithus, B.on.ungoro(nil, 29.5, 22.3), "Take the northwest ramp out of Un'Goro into Silithus")
  road(M.stonetalon, M.desolace, B.on.stonetalon(nil, 29.2, 90.5), "Take the south road out of Stonetalon into Desolace")
  road(M.desolace, M.feralas, B.on.desolace(nil, 43.9, 95.6), "Follow the road south out of Desolace into Feralas")
  road(M.feralas, M.desolace, B.on.feralas(nil, 44.9, 1.6), "Follow the road north into Desolace")
  road(M.ashenvale, M.felwood, B.on.ashenvale(nil, 55.6, 18.6), "Take the north road out of Ashenvale into Felwood")
  road(M.ashenvale, M.azshara, B.on.ashenvale(nil, 94.6, 47.8), "Take the east road out of Ashenvale into Azshara")
  road(M.felwood, M.winterspring, B.on.felwood(nil, 64.6, 8.2), "Go through Timbermaw Hold to Winterspring")
  road(M.hillsbrad, M.alterac, B.on.hillsbrad(nil, 54.6, 40.9), "Climb the north road into the Alterac Mountains")
  road(M.hillsbrad, M.arathi, B.on.hillsbrad(nil, 82.4, 39.6), "Take the east road out of Hillsbrad into Arathi")
  road(M.arathi, M.hillsbrad, B.on.arathi(nil, 17.1, 35.3), "Take the west road into Hillsbrad")
  road(M.hillsbrad, M.hinterlands, B.on.hillsbrad(nil, 86.4, 32.0), "Take the northeast pass into the Hinterlands")
  road(M.wpl, M.epl, B.on.wpl(nil, 69.4, 49.6), "Take the east road into the Eastern Plaguelands")
  road(M.swamp, M.blasted, B.on.swamp(nil, 34.2, 66.4), "Take the road south from the Swamp into the Blasted Lands")
end

-- 30-40 chapters follow. Quest facts: QuestieDB Forever (tools/questfacts.py), quest IDs and flight
-- names checked in tools/reference/forever.json; order and grouping from two published Forever guides.
local quest = B.quest
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, part, withItem, along = B.objectiveAt, B.objectivePart, B.withItem, B.along
local note, optional, withTrainers, on = B.note, B.optional, B.withTrainers, B.on
local need, dungeon, chapter, alternate = H.need, H.dungeon, H.chapter, H.alternate

-- People and places the 30-40 chapters visit more than once.
local P = {
  nyse = on.needles("Nyse", 45.14, 49.11),
  longhorn = on.needles("Cliffwatcher Longhorn", 45.67, 50.74),
  abeqwa = on.needles("Innkeeper Abeqwa", 46.07, 51.5),
  korran = on.barrens("Korran", 51.07, 29.63),
  devrak = on.barrens("Devrak", 51.5, 30.34),
  bragok = on.barrens("Bragok", 63.1, 37.2),
  gazlowe = on.barrens("Gazlowe", 62.68, 36.23),
  mebok = on.barrens("Mebok Mizzyrix", 62.37, 37.62),
  doras = on.orgrimmar("Doras", 45.12, 63.89),
  gryshka = on.orgrimmar("Innkeeper Gryshka", 54.1, 68.4),
  belgrom = on.orgrimmar("Belgrom Rockmaul", 75.23, 34.24),
  keldran = on.orgrimmar("Keldran", 22.56, 52.63),
  tal = on.thunderBluff("Tal", 47.0, 49.82),
  ucZeppelin = on.durotar(nil, 50.8, 13.8),
  gromgolZeppelin = on.durotar("Snurk Bucksquick", 50.7, 12.9),
  garrett = on.undercity("Michael Garrett", 63.25, 48.56),
  genavie = on.undercity("Genavie Callow", 63.83, 49.45),
  faranell = on.undercity("Master Apothecary Faranell", 48.82, 69.28),
  calder = on.undercity("Calder Gray", 49.11, 70.14),
  varimathras = on.undercity("Varimathras", 56.25, 92.2),
  zarise = on.hillsbrad("Zarise", 60.14, 18.62),
  lydon = on.hillsbrad("Apothecary Lydon", 61.44, 19.06),
  darthalia = on.hillsbrad("High Executor Darthalia", 62.33, 20.45),
  krusk = on.hillsbrad("Krusk", 63.24, 20.66),
  belvaril = on.hillsbrad("Keeper Bel'varil", 61.5, 20.93),
  voidglare = on.hillsbrad("Magus Wordeen Voidglare", 61.6, 20.85),
  urda = on.arathi("Urda", 73.0, 32.7),
  adegwa = on.arathi("Innkeeper Adegwa", 73.8, 32.5),
  drumFel = on.arathi("Drum Fel", 74.24, 33.92),
  gormul = on.arathi("Gor'mul", 72.64, 33.93),
  torgan = on.arathi("Tor'gan", 74.72, 36.29),
  zaruk = on.arathi("Zaruk", 74.54, 35.64),
  victor = on.arathi("Doctor Gregory Victor", 73.41, 36.89),
  zengu = on.arathi("Zengu", 73.8, 33.96),
  thalon = on.desolace("Thalon", 21.6, 74.1),
  thysta = on.stv("Thysta", 32.5, 29.4),
  gringer = on.stv("Gringer", 26.9, 77.1),
  shardi = on.dustwallow("Shardi", 35.6, 31.9),
  gorrik = on.badlands("Gorrik", 4.0, 44.8),
  freewind = { bind = "Freewind Post" },
  org = { bind = "Orgrimmar" },
  hammerfall = { bind = "Hammerfall" },
  kargath = { bind = "Kargath" },
}

-- Class trainers in the three cities (QuestieDB spawns).
P.ucTrainers = {
  { "WARRIOR", on.undercity("Angela Curthas", 48.3, 16.0) }, { "ROGUE", on.undercity("Carolyn Ward", 83.9, 72.1) },
  { "PRIEST", on.undercity("Aelthalyste", 49.3, 17.1) }, { "MAGE", on.undercity("Lexington Mortaim", 84.2, 15.6) },
  { "WARLOCK", on.undercity("Richard Kerwin", 88.9, 15.9) },
}
P.tbTrainers = {
  { "WARRIOR", on.thunderBluff("Torm Ragetotem", 57.27, 87.34) }, { "HUNTER", on.thunderBluff("Urek Thunderhorn", 59.13, 86.91) },
  { "ROGUE", on.thunderBluff("Boarton Shadetotem", 39.49, 65.88) }, { "PRIEST", on.thunderBluff("Miles Welsh", 25.31, 15.24) },
  { "SHAMAN", on.thunderBluff("Tigor Skychaser", 23.64, 18.74) }, { "MAGE", on.thunderBluff("Archmage Shymm", 22.74, 14.48) },
  { "PALADIN", on.thunderBluff("Alodan the Hopeful", 25.18, 14.4) }, { "DRUID", on.thunderBluff("Turak Runetotem", 76.48, 27.25) },
}
P.orgTrainers = {
  { "WARRIOR", on.orgrimmar("Grezz Ragefist", 79.91, 31.36) }, { "HUNTER", on.orgrimmar("Ormak Grimshot", 66.05, 18.52) },
  { "ROGUE", on.orgrimmar("Ormok", 43.9, 54.65) }, { "PRIEST", on.orgrimmar("Ur'kyo", 35.59, 87.8) },
  { "SHAMAN", on.orgrimmar("Kardris Dreamseeker", 38.82, 36.41) }, { "MAGE", on.orgrimmar("Pephredo", 38.36, 85.54) },
  { "WARLOCK", on.orgrimmar("Mirket", 48.62, 46.95) },
}

local questie = "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever"

-- Tarren Mill at 30: the silithid and Alliance Relations errands, the Battle of Hillsbrad, the
-- Lordamere camp and Strahnbrad, Dun Garok, then Hammerfall and back to the Undercity.
do
  local hb, al, ar = on.hillsbrad, on.alterac, on.arathi
  local poster = hb("Dangerous!", 62.56, 19.66)
  local thaivand = hb("Novice Thaivand", 63.88, 19.66)
  local humbert = hb("Deathguard Humbert", 62.76, 20.21)
  local tallow = hb("Tallow", 61.87, 19.57)
  local fields = hb(nil, 30.9, 43.1)
  local mine = hb(nil, 31.1, 55.3)
  local garok = hb(nil, 71.3, 78.2)
  local camp = al(nil, 19.9, 85.5)
  local northfold = ar(nil, 32.5, 27.3)

  need(1145, "The Swarm Grows", 33, 29)
  need(1146, "The Swarm Grows", 33, 29, 1145)
  need(1431, "Alliance Relations", 30, 30)
  need(1432, "Alliance Relations", 30, 30, 1431)
  need(2841, "Rig Wars", 35, 25)
  need(1164, "To Steal From Thieves", 36, 27)
  need(1109, "Going, Going, Guano!", 33, 30)
  need(96988, "Source of Power", 33, nil, nil, true)
  need(96986, "The Grave Knight", 33, nil, nil, true)
  need(532, "Battle of Hillsbrad", 26, 19, 529)
  need(539, "Battle of Hillsbrad", 28, 19, 532)
  need(541, "Battle of Hillsbrad", 30, 19, 539)
  need(550, "Battle of Hillsbrad", 32, 19, 541)
  need(567, "Dangerous!", 28, 19)
  need(533, "Infiltration", 34, 29, 498)
  need(1361, "Regthar Deathgate", 32, 30)
  need(552, "Helcular's Revenge", 33, 29)
  need(553, "Helcular's Revenge", 33, 29, 552)
  need(556, "Stone Tokens", 32, 30)
  need(544, "Prison Break In", 34, 30)
  need(93680, "Key to the City", 33, nil, nil, true)
  need(547, "Humbert's Sword", 30, 26)
  need(509, "Elixir of Agony", 28, 24)
  need(513, "Elixir of Agony", 28, 24, 509)
  need(676, "The Hammer May Fall", 32, 30)
  need(677, "Call to Arms", 32, 30, 676)
  need(655, "Hammerfall", 34, 29)
  need(672, "Raising Spirits", 34, 29, 655)
  need(674, "Raising Spirits", 34, 29, 672)
  need(675, "Raising Spirits", 34, 29, 674)
  need(671, "Foul Magics", 33, 30)
  need(97539, "Silky Sutures", 36, nil, nil, true)
  need(95663, "Dragonmaw Rumors", 31, nil, nil, true)
  need(97985, "Thundering Hearts", 33, nil, nil, true)

  local cleanup = action("note", nil, "Clean out your quest log. If you are not going to run Wailing Caverns, Shadowfang Keep or Blackfathom Deeps, abandon their quests now: the thirties need the room.",
    { name = "Quest log", drop = { 914, 962, 1014, 1098, 6563, 6921 } })
  cleanup.suggest = { "stv-30", "desolace-31" }

  chapter("hillsbrad-30", "Tarren Mill, Alterac and Hammerfall", M.hillsbrad, 30, 33, {
    "https://www.wowhead.com/forever/zone=267/hillsbrad-foothills",
    "https://www.wowhead.com/forever/zone=45/arathi-highlands",
    "https://www.warcrafttavern.com/forever/guides/city-of-dalaran-quests/",
    "https://www.wowhead.com/forever/quest=93680",
    "https://www.wowhead.com/forever/quest=97539",
    questie,
  }, { "flats-33", "dustwallow-33" }, withTrainers({
    cleanup,
    taxi("fly", B.at("Devrak", 51.5, 30.34, 1413), "Crossroads, The Barrens", "Fly from Freewind Post to the Crossroads."),
    accept(1145, P.korran, "Korran, in the Crossroads, wants a note about the silithid carried to Orgrimmar."),
    taxi("fly", B.at("Doras", 45.12, 63.89, 1454), "Orgrimmar, Durotar", "Fly to Orgrimmar."),
    finish(1145, P.belgrom, "Belgrom Rockmaul stands in the Valley of Honor, on the east side of the city."),
    accept(1146, P.belgrom, "Keep his sealed note for Moktar Krin, who watches the silithid west of the Shimmering Flats."),
    dungeon("gnomeregan", accept(2841, on.orgrimmar("Nogg", 75.99, 25.41),
      "Nogg, at the north end of the Valley of Honor, wants plans from deep inside Gnomeregan. Take it only if you plan to run the dungeon.")),
    accept(1431, on.orgrimmar("Craven Drok", 51.3, 45.9), "Craven Drok has a message for Keldran."),
    finish(1431, P.keldran, "Keldran stands in the Valley of Spirits, on the west side of the city."),
    accept(1432, P.keldran, "Keep his message for Takata Steelblade at Ghost Walker Post in Desolace."),
    action("boat", P.ucZeppelin, "Leave Orgrimmar by the main gate and take the zeppelin to Tirisfal Glades from the tower north-east of the city. Then walk into the Undercity."),
    accept(1164, P.genavie, "Genavie Callow, beside the bat handler east of the Trade Quarter, wants three Syndicate heads from Arathi."),
    dungeon("razorfen-kraul", accept(1109, P.faranell,
      "Master Apothecary Faranell in the Apothecarium has a guano errand inside Razorfen Kraul. Take it only if you plan to run the dungeon.")),
    dungeon("city-of-dalaran", accept(96988, on.undercity("Doctor Martin Felben", 46.61, 74.09),
      "Doctor Martin Felben, also in the Apothecarium, wants sentry cores from the City of Dalaran.")),
    taxi("fly", B.at("Zarise", 60.14, 18.62, 1424), "Tarren Mill, Hillsbrad", "Fly to Tarren Mill from Michael Garrett, the bat handler."),
    accept(532, P.darthalia, "High Executor Darthalia's next Battle of Hillsbrad orders target the town hall in Hillsbrad Fields."),
    accept(567, poster, "Read the Dangerous! poster outside the town hall: four Hillsbrad citizens carry bounties."),
    accept(533, P.krusk, "Krusk wants to know where the Syndicate holds Gol'dir."),
    accept(1361, P.krusk, "Krusk also has word for Regthar Deathgate, west of the Crossroads. Keep it until you are back in the Barrens."),
    accept(552, thaivand, "Novice Thaivand wants Helcular's Rod back from the yetis."),
    accept(556, P.belvaril, "Keeper Bel'varil wants worn stone tokens from the Dalaran mages in Alterac."),
    accept(544, P.voidglare, "Magus Wordeen Voidglare wants four bloodstone pieces from the traitors held at the Lordamere Internment Camp."),
    accept(93680, P.voidglare, "He also wants the key the camp's warden keeps."),
    dungeon("city-of-dalaran", accept(96986, hb("Melisara", 62.63, 20.65), "Melisara wants Atrexis the Grave Knight destroyed in the City of Dalaran.")),
    objective(552, hb(nil, 44.9, 32.2), "Ride south-west out of Tarren Mill to the yeti cave in the hills. Kill Cave and Ferocious Yetis until one drops Helcular's Rod.",
      "Helcular's Rod"),
    action("goto", fields, "Follow the road south-west down to Hillsbrad Fields."),
    along(objective(532, hb(nil, 29.7, 41.6), "Clear the town hall: kill Magistrate Burnside and four Hillsbrad Councilmen, destroy the proclamation and take the town registry.",
      "Magistrate Burnside slain", "4 Hillsbrad Councilmen", "Hillsbrad Proclamation destroyed", "Hillsbrad Town Registry"), 567),
    part(567, 1, hb("Clerk Horrace Whitesteed", 29.5, 42.4), "Clerk Horrace Whitesteed works in the same town hall.", "Clerk Horrace Whitesteed slain"),
    part(567, 2, hb("Citizen Wilkes", 32.6, 39.8), "Citizen Wilkes walks the fields north-east of the town hall.", "Citizen Wilkes slain"),
    part(567, 4, hb("Farmer Kalaba", 35.9, 46.6), "Farmer Kalaba works the fields to the south-east.", "Farmer Kalaba slain"),
    action("goto", P.darthalia, "Ride back north-east to Tarren Mill."),
    finish(532, P.darthalia), accept(539, P.darthalia, "Darthalia's next target is the Azurelode Mine south of the fields."),
    finish(552, thaivand), accept(553, thaivand, "Thaivand wants the rod charged at three flames, then driven into Helcular's grave near Southshore."),
    action("goto", mine, "Ride back down past Hillsbrad Fields to the Azurelode Mine."),
    along(objective(539, mine, "Kill Hillsbrad Miners around and inside the mine. Foreman Bonds walks the tunnels.", "Foreman Bonds slain", "10 Hillsbrad Miners"), 567),
    part(567, 3, hb("Miner Hackett", 31.1, 58.6), "Miner Hackett works at the south end of the mine.", "Miner Hackett slain"),
    action("goto", camp, "Follow the lake shore north-west into the hills to the Lordamere Internment Camp."),
    along(objective(544, camp, "Kill the four traitors: Ricter in the yard, Dermot and Alina in the roofless house, and Kegan Darkmar upstairs in the house outside the palisade.",
      "Bloodstone Marble", "Bloodstone Wedge", "Bloodstone Shard", "Bloodstone Oval"), 93680, 556),
    note(objective(93680, al("Warden Belamoore", 17.8, 83.0), "Kill Warden Belamoore on the ground floor of Kegan's house and open the warden's footlocker for the key."),
      "The footlocker comes from a published guide; QuestieDB has no record of it."),
    objective(556, al(nil, 18.3, 84.8), "Kill Dalaran mages, guards and workers around the camp until you have ten Worn Stone Tokens.", "10 Worn Stone Tokens"),
    part(553, 3, al("Flame of Uzel", 37.5, 66.2), "Ride east into the Alterac hills to the Flame of Uzel and touch it to charge the rod.", "Flame of Uzel charged"),
    action("goto", hb(nil, 44.0, 27.5), "Ride south-east back down to the Hillsbrad yeti cave."),
    part(553, 1, hb("Flame of Azel", 43.9, 28.1), "The Flame of Azel burns inside the cave.", "Flame of Azel charged"),
    part(553, 2, hb("Flame of Veraz", 44.0, 26.6), "The Flame of Veraz burns deeper in the same cave.", "Flame of Veraz charged"),
    action("goto", al(nil, 58.2, 67.2), "Climb north-east into Alterac to the Syndicate town of Strahnbrad."),
    objective(533, al(nil, 58.2, 67.2), "Kill Syndicate Footpads and Thieves in Strahnbrad until one carries the Syndicate Missive.", "Syndicate Missive"),
    action("goto", P.krusk, "Ride south back to Tarren Mill."),
    finish(539, P.darthalia), accept(541, P.darthalia, "Darthalia now sends you against Dun Garok, the dwarven fort in the south-east."),
    finish(567, P.darthalia),
    finish(533, P.krusk),
    finish(544, P.voidglare), finish(93680, P.voidglare),
    finish(556, P.belvaril),
    accept(547, humbert, "Deathguard Humbert lost his sword at Dun Garok."),
    accept(509, P.lydon, "Apothecary Lydon wants Mudsnout Blossoms from the hills east of Southshore."),
    note(finish(553, hb("Helcular's Grave", 52.75, 53.37), "Ride south to the graveyard north of Southshore and drive the charged rod into Helcular's grave. Alliance guards walk the road: be quick."),
      "Guard patrols near the Southshore graveyard need an in-game check."),
    objective(509, hb(nil, 64.4, 61.5), "Ride south-east into the hills and pick Mudsnout Blossoms.", "6 Mudsnout Blossoms"),
    along(objective(541, garok, "Fight into Dun Garok. Kill Mountaineers, Riflemen and Priests, and Captain Ironhill inside the fort.",
      "8 Dun Garok Mountaineers", "4 Dun Garok Riflemen", "2 Dun Garok Priests", "Captain Ironhill slain"), 547),
    objective(547, garok, "Keep killing the dwarves until one drops Humbert's Sword.", "Humbert's Sword"),
    action("goto", P.darthalia, "Ride north back to Tarren Mill."),
    finish(541, P.darthalia), accept(550, P.darthalia, "Keep Darthalia's commendation for Varimathras in the Undercity."),
    finish(547, humbert),
    finish(509, P.lydon), accept(513, P.lydon, "Keep the composite for Master Apothecary Faranell in the Undercity."),
    accept(676, tallow, "Tallow wants Boulderfist ogres killed on your way to Hammerfall."),
    action("goto", hb(nil, 82.4, 39.6), "Take the east road out of Tarren Mill through Thoradin's Wall into Arathi."),
    objective(676, ar(nil, 34.6, 45.0), "Kill Boulderfist Ogres and Enforcers at their camp in western Arathi.", "8 Boulderfist Ogres", "10 Boulderfist Enforcers"),
    objective(1164, ar(nil, 55.5, 37.5), "Follow the road east to Dabyrie's Farmstead. Kill Fardel, Marcel and Kenata Dabyrie in and around the farmhouses.",
      "Fardel's Head", "Marcel's Head", "Kenata's Head"),
    taxi("getfp", P.urda, "Hammerfall, Arathi", "Ride on east to Hammerfall and learn the flight path from Urda."),
    accept(655, P.gormul),
    finish(676, P.drumFel), accept(677, P.drumFel, "Drum Fel wants the Witherbark trolls south of Hammerfall thinned."),
    finish(655, P.torgan, "Tor'gan stands at the south side of the camp."),
    accept(672, P.torgan), accept(671, P.torgan),
    accept(97539, P.victor, "Doctor Gregory Victor needs spider silk for his sutures."),
    dungeon("excavation-site", accept(95663, P.zaruk, "Zaruk has rumors about the Dragonmaw in the Wetlands. Take it only if you plan to run the Excavation Site.")),
    action("goto", northfold, "Ride west across the highlands to the Syndicate at Northfold Manor."),
    objective(671, northfold, "Kill Syndicate Highwaymen, Pathstalkers and Mercenaries around Northfold Manor for Bloodstone Amulets.", "10 Bloodstone Amulets"),
    along(objective(672, ar(nil, 43.3, 44.6), "Ride back east through the highlands. Kill Highland Striders and Thrashers for their eyes.", "10 Highland Raptor Eyes"), 97539),
    along(note(objective(97539, ar(nil, 46.4, 37.0), "Kill Plains Creepers on the way for Surgical Spidersilk.", "12 Surgical Spidersilk"),
      "The silk's drop list is not published; Plains Creepers are the Arathi spiders."), 672),
    objective(677, ar(nil, 66.4, 75.0), "Ride south-east to Witherbark Village. Kill Axe Throwers, Headhunters and Witch Doctors.",
      "10 Witherbark Axe Throwers", "10 Witherbark Headhunters", "8 Witherbark Witch Doctors"),
    action("goto", P.drumFel, "Ride north back to Hammerfall."),
    finish(677, P.drumFel),
    finish(671, P.torgan), finish(672, P.torgan), accept(674, P.torgan),
    finish(674, P.gormul), accept(675, P.gormul), finish(675, P.torgan),
    finish(97539, P.victor),
    taxi("fly", B.at("Michael Garrett", 63.25, 48.56, 1458), "Undercity, Tirisfal", "Fly to the Undercity."),
    finish(1164, P.genavie),
    finish(513, P.faranell),
    finish(550, P.varimathras, "Varimathras waits in the Royal Quarter."),
    accept(97985, P.calder, "Calder Gray, beside Faranell, wants the heart of Stormheart, a beast in Thousand Needles. Keep it for your return there."),
    action("train", nil, "Visit your class trainer in the Undercity. Train spells for level", { level = 32 }),
  }, P.ucTrainers))
end

-- The Shimmering Flats at 33: Stormheart, the silithid hive and the racing camps, then the
-- Crossroads and Ratchet errands.
do
  local tn, ba = on.needles, on.barrens
  local moktar = tn("Moktar Krin", 67.58, 63.94)
  local kravel = tn("Kravel Koalbeard", 77.79, 77.27)
  local fizzle = tn("Fizzle Brassbolts", 78.06, 77.13)
  local wizzle = tn("Wizzle Brassbolts", 78.14, 77.12)
  local pozzik = tn("Pozzik", 80.18, 75.88)
  local zherin = tn("Trackmaster Zherin", 81.63, 77.95)
  local hive = tn(nil, 67.3, 85.7)
  local regthar = ba("Regthar Deathgate", 45.34, 28.41)

  need(5361, "Family Tree", 35, 32)
  need(1147, "The Swarm Grows", 35, 29, 1146)
  need(1148, "Parts of the Swarm", 35, 28)
  need(1184, "Parts of the Swarm", 35, 28, 1148)
  need(1362, "The Kolkar of Desolace", 32, 30)
  need(5762, "Hemet Nesingwary", 31, 28)
  quest[1148].startItem = 5877

  chapter("flats-33", "Shimmering Flats and Ratchet", M.needles, 33, 34, {
    "https://www.wowhead.com/forever/zone=400/thousand-needles",
    questie,
  }, { "desolace-34", "dustwallow-33" }, {
    action("hearth", P.abeqwa, "Hearth to Freewind Post.", P.freewind),
    accept(5361, P.longhorn, "Cliffwatcher Longhorn has a report for Nataka Longhorn at Ghost Walker Post in Desolace. Keep it for later."),
    note(objective(97985, tn("Stormheart", 55.7, 54.2), "Ride east out of Freewind into the canyon. Stormheart, a level 30 beast, roams the canyon floor between the mesas. Kill it and take its heart."),
      "Stormheart's route comes from QuestieDB spawn points only; check in game."),
    action("goto", moktar, "Follow the canyon road east toward the Shimmering Flats. Moktar Krin camps on the high ground west of the flats."),
    finish(1146, moktar), accept(1147, moktar),
    action("goto", kravel, "Ride down onto the salt flats to the racing camps in the middle."),
    accept(1110, kravel), accept(1111, kravel, "Kravel also has a parts order for the wharfmaster in Ratchet."),
    accept(1104, fizzle), accept(1105, wizzle),
    accept(1176, pozzik, "Pozzik runs the goblin camp east of the gnomes."), accept(1175, zherin),
    along(objective(1105, tn(nil, 74.6, 55.7), "Ride north. Kill Sparkleshell Tortoises for their shells and pick up Rocket Car Parts from the wreckage as you go.",
      "9 Hardened Tortoise Shells"), 1104, 1110, 1175),
    along(objective(1104, tn(nil, 75.1, 55.8), "Scorpid Reavers share the north end of the flats. Kill them for their venom.", "6 Salty Scorpid Venoms"),
      1105, 1110, 1175),
    along(part(1175, 1, tn(nil, 75.6, 56.6), "Kill the Saltstone Basilisks around the north end.", "10 Saltstone Basilisks"), 1104, 1105, 1110),
    along(part(1175, 2, tn(nil, 78.0, 87.2), "Ride south past the camps. Saltstone Crystalhides live at the south end.", "10 Saltstone Crystalhides"), 1176, 1110),
    along(part(1175, 3, tn(nil, 77.5, 87.7), "Saltstone Gazers share the south end.", "6 Saltstone Gazers"), 1176, 1110),
    along(objective(1176, tn(nil, 78.7, 89.5), "Kill Salt Flats Vultures and Scavengers for Hollow Vulture Bones. They circle all over the south.",
      "10 Hollow Vulture Bones"), 1110, 1175),
    objective(1110, tn(nil, 77.0, 85.6), "Finish the Rocket Car Parts from the wreckage piles across the flats.", "30 Rocket Car Parts"),
    action("goto", hive, "Ride west to the silithid hive at the south-west edge of the flats."),
    along(objective(1147, hive, "Kill Silithid Searchers, Hive Drones and Invaders around the hive.", "5 Silithid Searchers", "5 Silithid Hive Drones",
      "5 Silithid Invaders"), 1148),
    withItem(5877, accept(1148, hive, "Use the Cracked Silithid Carapace when one drops.")),
    objective(1148, hive, "Keep killing silithid for a heart, talons and intact carapaces.", "Silithid Heart", "5 Silithid Talons", "3 Intact Silithid Carapaces"),
    action("goto", kravel, "Ride back to the racing camps."),
    finish(1110, kravel), accept(5762, kravel, "Kravel has a crate for Hemet Nesingwary in Stranglethorn. Keep it for later."),
    finish(1104, fizzle), accept(1106, fizzle, "Fizzle has a letter for Martek the Exiled in the Badlands. Keep it for later."),
    finish(1105, wizzle),
    finish(1176, pozzik), accept(1178, pozzik, "Keep Pozzik's request for Gazlowe in Ratchet."),
    finish(1175, zherin),
    finish(1147, moktar, "Ride back west to Moktar Krin."),
    action("goto", P.nyse, "Follow the canyon road west back to Freewind Post."),
    taxi("fly", B.at("Devrak", 51.5, 30.34, 1413), "Crossroads, The Barrens", "Fly to the Crossroads."),
    finish(1148, P.korran), accept(1184, P.korran, "Keep Korran's report for Belgrom Rockmaul in Orgrimmar."),
    finish(1361, regthar, "Ride west along the road to Regthar Deathgate's camp."),
    accept(1362, regthar, "Keep his word for Felgur Twocuts at Ghost Walker Post in Desolace."),
    taxi("fly", B.at("Bragok", 63.09, 37.16, 1413), "Ratchet, The Barrens", "Ride back to the Crossroads and fly to Ratchet."),
    finish(1111, on.barrens("Wharfmaster Dizzywig", 63.35, 38.45), "Wharfmaster Dizzywig stands on the Ratchet docks."),
    finish(1178, P.gazlowe, "Gazlowe has his office above the docks."),
    accept(1180, P.gazlowe, "Keep his request for Wharfmaster Lozgil in Booty Bay."),
  })
end

-- Desolace from Thunder Bluff at 34: Gloomrise in Mulgore, Ghost Walker Post, Sargeron and the
-- Kolkar, the Kodo Graveyard, the Gelkis, Shadowprey Village and the naga coast.
do
  local ds, mg, tb = on.desolace, on.mulgore, on.thunderBluff
  local takata = ds("Takata Steelblade", 52.57, 54.39)
  local maurin = ds("Maurin Bonesplitter", 52.25, 53.44)
  local nataka = ds("Nataka Longhorn", 55.41, 55.81)
  local felgur = ds("Felgur Twocuts", 56.19, 59.57)
  local gurda = ds("Gurda Wildmane", 56.29, 59.68)
  local bibbly = ds("Bibbly F'utzbuckle", 62.33, 38.99)
  local smeed = ds("Smeed Scrabblescrew", 60.86, 61.86)
  local uthek = ds("Uthek the Wise", 36.22, 79.25)
  local sikewa = ds("Innkeeper Sikewa", 24.1, 68.2)
  local mailahii = ds("Mai'Lahii", 22.64, 71.97)
  local drulzegar = ds("Drulzegar Skraghook", 23.32, 72.87)
  local azore = ds("Azore Aldamort", 38.88, 27.16)
  local rackmore = ds("Rackmore's Log", 36.07, 30.41)
  local thunderAxe = ds(nil, 55.5, 26.5)
  local graveyard = ds(nil, 52.5, 58.3)
  local naga = ds(nil, 36.4, 23.5)
  local muln = mg("Muln Earthfury", 33.41, 22.58)
  local mazukon = mg("Mazu'kon", 32.5, 20.66)
  local yorn = mg("Yorn Grimtotem", 32.47, 19.98)
  local valraxx = mg("Broodmother Valraxx", 33.2, 8.5)
  local gloomrise = mg(nil, 33.6, 12.2)
  local shadowprey = { bind = "Shadowprey Village" }

  need(1102, "A Vengeful Fate", 34, 29)
  need(96259, "Defending the Dead", 30, nil, nil, true)
  need(96241, "Talkin' bout Toxins, Mon", 30, nil, nil, true)
  need(96260, "Stronger than Steel", 30, nil, nil, true)
  need(96261, "The Broodmother", 31, nil, 96259, true)
  need(96294, "A Darker Truth", 30, nil, nil, true)
  quest[96294].startItem = 273658
  need(1480, "The Corrupter", 33, 25)
  quest[1480].startItem = 20310
  need(1481, "The Corrupter", 33, 25, 1480)
  need(1482, "The Corrupter", 35, 25, 1481)
  need(1484, "The Corrupter", 35, 25, 1482)
  need(1433, "Alliance Relations", 33, 30, 1432)
  need(1434, "Befouled by Satyr", 33, 25)
  need(1435, "The Burning of Spirits", 33, 25, 1433)
  need(1436, "Alliance Relations", 33, 30, 1435)
  need(1365, "Khan Dez'hepah", 35, 30)
  need(1368, "Gelkis Alliance", 33, 30)
  need(93225, "Carved Centaur Totems", 40, nil, nil, true)
  need(94873, "Buying Friendship: Gelkis", 40, nil, 93225, true)
  need(6142, "Clam Bait", 35, 31)
  need(6143, "Other Fish to Fry", 36, 32)
  need(5763, "Hunting in Stranglethorn", 31, 28)

  chapter("desolace-34", "Desolace: Ghost Walker Post and Shadowprey", M.desolace, 34, 36, {
    "https://www.wowhead.com/forever/zone=405/desolace",
    "https://www.wowhead.com/forever/zone=215/mulgore",
    "https://www.wowhead.com/forever/quest=93225",
    "https://www.wowhead.com/forever/quest=94873",
    "https://www.wowhead.com/classic/quest=1435/the-burning-of-spirits",
    questie,
  }, { "stv-35", "dustwallow-33" }, withTrainers({
    taxi("fly", B.at("Tal", 47, 49.82, 1456), "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
    action("train", nil, "Visit your class trainer in Thunder Bluff. Train spells for level", { level = 34 }),
    dungeon("razorfen-kraul", accept(1102, tb("Auld Stonespire", 35.97, 59.92),
      "Auld Stonespire, west of the inn on the central mesa, wants Charlga Razorflank's heart from Razorfen Kraul.")),
    action("goto", muln, "Take the lift down and ride north-west across Mulgore to Muln Earthfury at the Skywatcher Plateau."),
    accept(96259, muln), accept(96241, mazukon), accept(96260, yorn),
    along(objective(96259, gloomrise, "Ride north to Gloomrise, the spider nest at the edge of Mulgore. Kill Gloomrise Hatchlings and Soldiers.",
      "10 Gloomrise Hatchlings", "5 Gloomrise Soldiers"), 96241, 96260),
    along(withItem(273015, objective(96241, gloomrise, "Use Mazu'kon's Toxin Extractor on the gnawed corpses around the nest.", "5 Gloomrise Toxin Samples")),
      96259, 96260),
    along(objective(96260, mg(nil, 33.4, 11.6), "Kill Gloomrise Spinners for their Crystalline Silk.", "3 Crystalline Silk"), 96259, 96241),
    action("goto", muln, "Ride back south to the plateau."),
    finish(96259, muln), finish(96241, mazukon), finish(96260, yorn),
    accept(96261, muln),
    objective(96261, valraxx, "Return to Gloomrise and kill Broodmother Valraxx at the back of the nest.", "Broodmother Valraxx slain"),
    withItem(273658, accept(96294, valraxx, "Read the letter Valraxx drops.")),
    finish(96261, muln, "Ride back to Muln Earthfury."), finish(96294, muln),
    note(action("goto", on.stonetalon(nil, 29.2, 90.5), "Ride north out of Mulgore into southern Stonetalon and follow the roads west to the Desolace border."),
      "The path from Gloomrise into Stonetalon needs an in-game check; flying to Sun Rock Retreat and riding south also works."),
    withItem(20310, accept(1480, thunderAxe, "Ride south into Desolace. At Thunder Axe Fortress, kill Burning Blade cultists until one drops a Flayed Demon Skin, then read it.")),
    action("goto", takata, "Follow the road south to Ghost Walker Post."),
    finish(5361, nataka),
    finish(1432, takata), accept(1433, takata), accept(1434, takata),
    finish(1433, maurin), accept(1435, maurin, "Maurin gives you a Burning Gem. Use it on Burning Blade cultists when they are nearly dead."),
    finish(1480, maurin), accept(1481, maurin),
    finish(1362, felgur), accept(1365, felgur),
    accept(1368, gurda, "Gurda Wildmane wants you on friendly terms with the Gelkis centaur."),
    note(accept(93225, gurda, "She also wants carved totems from centaur of any clan."),
      "QuestieDB has no giver for this Forever quest; Gurda takes it in."),
    withItem(6436, objective(1435, thunderAxe, "Ride north back to Thunder Axe Fortress. Bring a Burning Blade cultist low, use the Burning Gem on it, then finish it.",
      "15 Infused Burning Gems")),
    accept(5501, bibbly, "Ride south-east to Kormek's Hut. Bibbly F'utzbuckle wants kodo bones from the Kodo Graveyard."),
    action("goto", ds(nil, 75.1, 16.0), "Ride north-east to Sargeron, the satyr camp in the corner of the zone."),
    along(objective(1434, ds(nil, 75.1, 16.0), "Kill Hatefury Rogues, Felsworn, Betrayers and Hellcallers.", "7 Hatefury Rogues", "7 Hatefury Felsworn",
      "7 Hatefury Betrayers", "7 Hatefury Hellcallers"), 1481),
    objective(1481, ds(nil, 76.7, 24.5), "Hatefury Shadowstalkers, often stealthed, roam the south end of Sargeron. Kill one for its scalp.", "Shadowstalker Scalp"),
    action("goto", ds(nil, 72.3, 45.0), "Ride south to the Kolkar centaur village."),
    along(objective(1365, ds("Khan Dez'hepah", 73.4, 41.6), "Khan Dez'hepah leads the Kolkar from the north end of the village. Kill him for his head.",
      "Khan Dez'hepah's Head"), 93225),
    objective(93225, ds(nil, 72.3, 45.0), "Kill Kolkar centaur until you have five Carved Centaur Totems.", "5 Carved Centaur Totems"),
    action("goto", takata, "Ride south-west back to Ghost Walker Post."),
    finish(1434, takata),
    finish(1481, maurin), accept(1482, maurin, "Maurin now wants an Oracle Crystal from the Slitherblade naga on the north-west coast."),
    finish(1435, maurin), accept(1436, takata, "Keep Takata's answer for Keldran in Orgrimmar."),
    finish(1365, felgur),
    finish(93225, gurda), note(accept(94873, gurda, "Take the Totem Tote to the Gelkis quartermaster."),
      "QuestieDB has no giver for this Forever quest; Gurda takes in the totems before it."),
    accept(5561, smeed, "Ride south-east to Smeed Scrabblescrew's camp beside the Kodo Graveyard."),
    along(withItem(13892, objective(5561, graveyard, "Use the Kodo Kombobulator on Ancient or Dying Kodos in the graveyard and lead each tamed kodo back to Smeed.",
      "5 Kodos Tamed")), 5501),
    along(objective(5501, graveyard, "Pick up Kodo Bones from the ground in the graveyard.", "10 Kodo Bones"), 5561),
    finish(5561, smeed),
    action("goto", uthek, "Ride south-west to the Gelkis village."),
    note(finish(94873, uthek, "Hand the Totem Tote to the Gelkis quartermaster in the village."),
      "The quartermaster has no QuestieDB record; the arrow points at Uthek the Wise in the same village."),
    finish(1368, uthek, "Uthek the Wise welcomes you now that the Gelkis are friendly."),
    taxi("getfp", P.thalon, "Shadowprey Village, Desolace", "Ride west to Shadowprey Village on the coast and learn the flight path from Thalon."),
    action("sethearth", sikewa, "Bind at the Shadowprey inn.", shadowprey),
    accept(6142, mailahii), accept(6143, drulzegar),
    accept(5763, ds("Roon Wildmane", 25.05, 72.27), "Roon Wildmane has a kodo horn for Hemet Nesingwary in Stranglethorn. Keep it for later."),
    action("goto", rackmore, "Ride north along the coast to the shipwreck below Ethel Rethor."),
    accept(6161, rackmore, "Read Rackmore's log at the shipwreck."),
    part(6161, 1, ds(nil, 33.5, 33.0), "Kill Drysnap crabs along the shore until one drops Rackmore's Silver Key.", "Rackmore's Silver Key"),
    accept(5741, azore, "Climb to Azore Aldamort's tower at Ethel Rethor. He wants the Sceptre of Light from Thunder Axe Fortress."),
    action("goto", naga, "Walk north along the coast to the Slitherblade naga."),
    along(objective(6143, ds(nil, 34.2, 23.5), "Kill Slitherblade Naga, Sorceresses and Myrmidons up the coast.", "7 Slitherblade Myrmidons",
      "7 Slitherblade Naga", "5 Slitherblade Sorceresses"), 6142, 1482, 6161),
    along(objective(6142, naga, "The naga carry Soft-shelled Clam Meat.", "10 Soft-shelled Clam Meat"), 6143, 6161),
    objective(1482, ds("Slitherblade Oracle", 32.7, 12.9), "Slitherblade Oracles stand farther north. Kill one for its crystal.", "Oracle Crystal"),
    part(6161, 2, ds(nil, 32.4, 7.3), "One of the naga at the northern shore carries Rackmore's Golden Key.", "Rackmore's Golden Key"),
    finish(6161, ds("Rackmore's Chest", 30.0, 8.71), "Swim to the small isle off the coast and open Rackmore's Chest."),
    action("goto", thunderAxe, "Ride east across the north of Desolace to Thunder Axe Fortress."),
    objective(5741, ds("Burning Blade Seer", 55.2, 30.1), "The Burning Blade Seer inside the fortress holds the Sceptre of Light.", "Sceptre of Light"),
    action("goto", azore, "Ride back west to Azore's tower."),
    finish(5741, azore),
    action("goto", takata, "Ride south-east to Ghost Walker Post."),
    finish(1482, maurin), accept(1484, maurin), finish(1484, takata),
    finish(5501, bibbly, "Ride north-east to Kormek's Hut."),
    action("hearth", sikewa, "Hearth to Shadowprey Village.", shadowprey),
    finish(6142, mailahii), finish(6143, drulzegar),
  }, P.tbTrainers))
end

-- Stranglethorn from Grom'gol at 35: the Nesingwary hunts, the Bloodscalps, the Vile Reef and the
-- Mosh'Ogg, a first visit to Booty Bay, then a second loop for the Kurzen and the Venture Co.
do
  local st = on.stv
  local aggrogosh = st("Commander Aggro'gosh", 32.17, 28.9)
  local mokthardin = st("Far Seer Mok'thardin", 32.12, 29.24)
  local nimboya = st("Nimboya", 32.16, 27.72)
  local kinweelay = st("Kin'weelay", 32.27, 27.71)
  local hemet = st("Hemet Nesingwary", 35.66, 10.81)
  local ajeck = st("Ajeck Rouack", 35.62, 10.62)
  local erlgadin = st("Sir S. J. Erlgadin", 35.55, 10.55)
  local krazek = st("Krazek", 26.94, 77.21)
  local kebok = st("Kebok", 27.0, 77.13)
  local revilgaz = st("Baron Revilgaz", 27.23, 76.87)
  local crank = st("Crank Fizzlebub", 27.12, 77.21)
  local lozgil = st("Wharfmaster Lozgil", 26.35, 73.56)
  local wendel = st("Wendel Mathers", 44.3, 7.9)
  local zimmix = st("Zimmix Sputterspark", 23.5, 12.8)
  local bloodscalp = st(nil, 24.7, 12.1)
  local headhunters = st(nil, 22.7, 10.9)
  local shadowmaw = st(nil, 37.6, 36.4)

  need(568, "The Defense of Grom'gol", 36, 33)
  need(569, "The Defense of Grom'gol", 37, 33, 568)
  need(570, "Mok'thardin's Enchantment", 38, 33)
  need(581, "Hunt for Yenniku", 34, 30)
  need(582, "Headhunting", 37, 30, 581)
  need(596, "Bloody Bone Necklaces", 37, 30)
  need(629, "The Vile Reef", 37, 30)
  need(638, "Trollbane", 37, 32)

  chapter("stv-35", "Stranglethorn: Grom'gol and Nesingwary", M.stv, 35, 37, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    questie,
  }, { "dustwallow-37", "badlands-37" }, withTrainers({
    taxi("fly", B.at("Doras", 45.12, 63.89, 1454), "Orgrimmar, Durotar", "Fly to Orgrimmar."),
    finish(1436, P.keldran, "Bring Takata's answer to Keldran in the Valley of Spirits."),
    finish(1184, P.belgrom, "Belgrom Rockmaul waits in the Valley of Honor."),
    action("train", nil, "Visit your class trainer in Orgrimmar. Train spells for level", { level = 36 }),
    action("sethearth", P.gryshka, "Bind at the Orgrimmar inn in the Valley of Strength. You come back here after Stranglethorn.", P.org),
    action("boat", P.gromgolZeppelin, "Leave Orgrimmar by the main gate and take the zeppelin to Grom'gol from the tower north-east of the city."),
    taxi("getfp", P.thysta, "Grom'gol, Stranglethorn", "Learn the Grom'gol flight path from Thysta."),
    accept(568, aggrogosh), accept(570, mokthardin), accept(581, nimboya), accept(596, kinweelay), accept(629, kinweelay),
    action("goto", hemet, "Follow the road north from Grom'gol to Nesingwary's Expedition, just west of the road."),
    finish(5762, hemet), finish(5763, hemet),
    accept(583, st("Barnil Stonepot", 35.66, 10.53)), finish(583, hemet),
    accept(194, hemet), accept(185, ajeck), accept(190, erlgadin),
    along(objective(185, st(nil, 36.0, 13.7), "Hunt Young Stranglethorn Tigers around the camp.", "10 Young Stranglethorn Tigers"), 190),
    along(objective(190, st(nil, 41.9, 12.2), "Young Panthers prowl east of the camp, across the road.", "10 Young Panthers"), 185),
    finish(185, ajeck), accept(186, ajeck), finish(190, erlgadin), accept(191, erlgadin),
    objective(186, st(nil, 46.5, 14.8), "Ride east for Stranglethorn Tigers. The Kurzen compound is just north of them: keep clear for now.", "10 Stranglethorn Tigers"),
    accept(97328, st("Thoroughly Scavenged Supplies", 31.55, 12.95), "Ride back west past the camp and search the scavenged supplies."),
    along(objective(191, st(nil, 28.8, 14.1), "Panthers prowl the jungle west of the camp.", "10 Panthers"), 194, 97328),
    along(objective(194, st(nil, 25.8, 16.1), "Stranglethorn Raptors hunt nearer the coast.", "10 Stranglethorn Raptors"), 191),
    note(accept(97329, zimmix, "Zimmix Sputterspark is caged near the Bloodscalp camp at the Ruins of Zul'Kunda."),
      "Zimmix has no QuestieDB record; the spot comes from the Alliance route's map point."),
    along(objective(581, bloodscalp, "Kill Bloodscalp trolls along the coast for their tusks.", "9 Bloodscalp Tusks"), 596, 97329, 97328),
    along(objective(596, bloodscalp, "Every kind of Bloodscalp also carries Bloody Bone Necklaces.", "25 Bloody Bone Necklaces"), 581, 97329, 97328),
    along(objective(97329, bloodscalp, "One of the trolls carries Zimmix's Primitive Key.", "Primitive Key"), 581, 596),
    along(objective(97328, st(nil, 26.0, 13.0), "Pick up the stolen shipments scattered around the camps.", "8 Stolen Shipments"), 581, 596),
    finish(97329, zimmix), accept(97331, zimmix),
    objective(97331, zimmix, "Help Zimmix out of the troll camp.", "Zimmix Escaped"),
    action("goto", hemet, "Ride back east to Nesingwary's camp."),
    finish(186, ajeck), accept(187, ajeck), finish(191, erlgadin), accept(192, erlgadin), finish(194, hemet), accept(195, hemet),
    objective(187, st(nil, 33.5, 18.4), "Elder Stranglethorn Tigers prowl the hills south of the camp.", "10 Elder Stranglethorn Tigers"),
    along(objective(195, st(nil, 34.5, 24.0), "Lashtail Raptors run in packs farther south, north of Grom'gol.", "10 Lashtail Raptors"), 568),
    along(objective(568, st(nil, 34.5, 24.0), "Commander Aggro'gosh wants the same Lashtails dead.", "15 Lashtail Raptors"), 195),
    objective(629, st("Gri'lek the Wanderer", 24.8, 23.0), "Ride west to the Vile Reef and dive to the troll statue on the sea floor for a Tablet Shard.", "Tablet Shard"),
    optional(action("collect", st("Giant Clam", 26.1, 26.5), "Open Giant Clams on the reef for Blue Pearls. Rigglefuzz in the Badlands wants nine at level 39.",
      { item = 4611, count = 9 })),
    action("goto", aggrogosh, "Swim back to shore and ride south-east to Grom'gol."),
    finish(568, aggrogosh), accept(569, aggrogosh),
    finish(581, nimboya), accept(582, nimboya),
    finish(596, kinweelay), finish(629, kinweelay),
    along(objective(569, st(nil, 37.0, 31.0), "Ride east to the Mosh'Ogg camp. Kill Brutes and Witch Doctors.", "10 Mosh'Ogg Brutes", "5 Mosh'Ogg Witch Doctors"), 570, 192),
    along(objective(192, shadowmaw, "Shadowmaw Panthers stalk unseen in the jungle south of the ogres.", "10 Shadowmaw Panthers"), 570, 569),
    along(objective(570, shadowmaw, "Collect Shadowmaw Claws from the panthers and a Pristine Tigress Fang from the tigresses there.", "8 Shadowmaw Claws",
      "Pristine Tigress Fang"), 192),
    action("goto", lozgil, "Follow the road south through the jungle to Booty Bay. Wharfmaster Lozgil stands on the docks."),
    taxi("getfp", P.gringer, "Booty Bay, Stranglethorn", "Learn the Booty Bay flight path from Gringer."),
    finish(1180, lozgil), accept(1181, lozgil),
    finish(97328, lozgil), finish(97331, lozgil),
    finish(1181, revilgaz, "Baron Revilgaz looks over the bay from the top floor of the inn."), accept(1182, revilgaz),
    accept(605, crank), accept(189, kebok), accept(213, kebok), accept(201, krazek),
    taxi("fly", B.at("Thysta", 32.5, 29.4, 1434), "Grom'gol, Stranglethorn", "Fly back to Grom'gol."),
    finish(569, aggrogosh), finish(570, mokthardin),
    action("goto", headhunters, "Ride north-west to the Bloodscalp camps on the coast."),
    along(objective(582, headhunters, "Kill Bloodscalp Headhunters for Shrunken Heads.", "20 Shrunken Heads"), 189),
    along(objective(189, headhunters, "Every Bloodscalp also drops ears.", "15 Bloodscalp Ears"), 582),
    objective(605, st(nil, 24.8, 17.6), "Kill Crystal Spine Basilisks south of the camps for Singing Crystal Shards.", "10 Singing Crystal Shards"),
    objective(201, st(nil, 35.65, 10.96), "Ride east to Nesingwary's Expedition: Krazek only wants you to find the hunters' camp.", "Locate the hunters' camp"),
    finish(187, ajeck), accept(188, ajeck), finish(192, erlgadin), finish(195, hemet),
    objective(188, st("Sin'Dall", 32.2, 17.4), "Sin'Dall, a white tigress, prowls the hilltop south-west of the camp. Kill her for her paw.", "Paw of Sin'Dall"),
    finish(188, ajeck),
    note(accept(97047, wendel, "Ride east to Wendel Mathers on the slope above the Kurzen compound. His cook is locked inside."),
      "Wendel has no QuestieDB record; the spot comes from the Alliance route's map point."),
    objective(97047, st(nil, 48.8, 5.4), "Loot a Kurzen Fighter's Uniform and the compound's cage key from the Kurzen guards, then free the cook.",
      "Kurzen Fighter's Uniform", "Compound Cage Key"),
    finish(97047, wendel), accept(97048, wendel, "Keep his note for Captain Aransas in Booty Bay."),
    along(objective(213, st(nil, 44.6, 22.1), "Ride south to the Venture Co. dig. Kill Geologists for Tumbled Crystals.", "8 Tumbled Crystals"), 1182),
    objective(1182, st("Cozzle's Footlocker", 43.3, 20.3), "Open Cozzle's Footlocker in the Venture Co. camp for the blueprints.", "Fuel Regulator Blueprints"),
    action("goto", nimboya, "Ride west back to Grom'gol."),
    finish(582, nimboya), accept(638, nimboya, "Nimboya sends you to Zengu in Hammerfall. Keep it for Arathi."),
    taxi("fly", B.at("Gringer", 26.9, 77.1, 1434), "Booty Bay, Stranglethorn", "Fly to Booty Bay."),
    finish(189, kebok), finish(213, kebok), finish(201, krazek), finish(605, crank), finish(1182, revilgaz),
    finish(97048, st("Captain Aransas", 27.4, 76.3), "Captain Aransas waits by the docks."),
    action("hearth", P.gryshka, "Hearth to Orgrimmar.", P.org),
  }, P.orgTrainers))
end

-- Dustwallow from Brackenwall Village at 37: the Shady Rest, the Black Shield, Swamp Eye Jarl and the
-- Theramore docks; then Ratchet, Thunder Bluff and the camp outside Razorfen Downs.
do
  local dm = on.dustwallow
  local krog = dm("Krog", 36.42, 31.88)
  local dogol = dm("Do'gol", 36.53, 30.79)
  local nazeer = dm("Nazeer Bloodpike", 35.21, 30.66)
  local ogron = dm("Ogron", 40.96, 36.69)
  local mudcrush = dm("Mudcrush Durtfeet", 35.15, 38.26)
  local stinky = dm("\"Stinky\" Ignatz", 46.88, 17.52)
  local jarl = dm("\"Swamp Eye\" Jarl", 55.44, 26.27)
  local dirt = dm("Loose Dirt", 55.44, 25.92)
  local spiders = dm(nil, 32.8, 22.2)
  local myriam = on.barrens("Myriam Moonsinger", 49.01, 94.94)

  need(1268, "Suspicious Hoofprints", 35, 30)
  need(1269, "Lieutenant Paval Reethe", 37, 30)
  need(1251, "The Black Shield", 35, 30)
  need(1321, "The Black Shield", 35, 30, 1251)
  need(1322, "The Black Shield", 37, 30, 1321)
  need(1323, "The Black Shield", 37, 30, 1322)
  need(1276, "The Black Shield", 37, 30, 1323)
  need(1273, "Questioning Reethe", 37, 30, 1269)
  need(1201, "Theramore Spies", 35, 30)
  need(1202, "The Theramore Docks", 35, 30, 1201)
  need(1270, "Stinky's Escape", 37, 30)
  need(1238, "The Lost Report", 35, 30)

  chapter("dustwallow-37", "Dustwallow: Brackenwall Village", M.dustwallow, 37, 38, {
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    questie,
  }, { "arathi-38", "badlands-37" }, {
    action("buy", on.orgrimmar("Xen'to", 57.6, 52.9), "Buy 3 Soothing Spices from Xen'to in Orgrimmar. Swamp Eye Jarl in Dustwallow wants them.",
      { item = 3713, count = 3 }),
    taxi("fly", B.at("Omusa Thunderhorn", 44.45, 59.15, 1413), "Camp Taurajo, The Barrens", "Fly to Camp Taurajo."),
    action("goto", dm("Suspicious Hoofprint", 29.7, 47.64), "Ride east out of the Barrens into Dustwallow Marsh and follow the road to the burned Shady Rest Inn."),
    accept(1268, dm("Suspicious Hoofprint", 29.7, 47.64), "Look at the hoofprints by the inn."),
    accept(1269, dm("Theramore Guard Badge", 29.83, 48.24), "Pick up the guard badge lying nearby."),
    accept(1251, dm("Black Shield", 29.63, 48.62), "Take the black shield beside the inn."),
    action("goto", krog, "Follow the road north to Brackenwall Village."),
    taxi("getfp", P.shardi, "Brackenwall Village, Dustwallow Marsh", "Learn the Brackenwall flight path from Shardi."),
    finish(1268, krog), finish(1269, krog), finish(1251, krog), accept(1321, krog),
    finish(1321, dogol), accept(1322, dogol),
    accept(1201, nazeer),
    accept(1273, ogron, "Ogron waits south-east of the village. He takes you to question Reethe."),
    note(objective(1273, ogron, "Follow Ogron to Reethe and stay with him through the questioning. Fight off the ambush that follows."),
      "The escort's path is not in QuestieDB; check in game."),
    accept(1177, mudcrush, "Mudcrush Durtfeet, a friendly ogre south of the village, is hungry for murloc heads."),
    objective(1201, dm(nil, 38.6, 24.4), "Theramore Infiltrators sneak through the reeds north-east of the village. Kill them.", "9 Theramore Infiltrators"),
    accept(1270, stinky, "Ride north-east to \"Stinky\" Ignatz in the bog. His escape is an escort."),
    note(objective(1270, dm(nil, 48.8, 24.5), "Escort Stinky while he gathers bog samples and fight off the attackers."),
      "Escort route from the classic quest; check in game."),
    accept(1218, jarl, "Ride east to Swamp Eye Jarl's shack and hand him the spices at once."), finish(1218, jarl),
    accept(1206, jarl),
    accept(1238, dirt, "Search the loose dirt beside Jarl's shack."),
    objective(1177, dm(nil, 56.8, 15.6), "Ride north to the coast and kill Mirefin murlocs for their heads.", "8 Mirefin Heads"),
    action("goto", spiders, "Ride west along the north of the marsh to the Darkmist spider caves north of Brackenwall."),
    along(objective(1206, spiders, "Kill Darkmist spiders for Unpopped Darkmist Eyes.", "20 Unpopped Darkmist Eyes"), 1322),
    along(objective(1322, dm(nil, 33.0, 22.1), "The same spiders carry Acidic Venom Sacs.", "5 Acidic Venom Sacs"), 1206),
    finish(1201, nazeer), accept(1202, nazeer), finish(1238, nazeer),
    finish(1322, dogol), accept(1323, dogol), finish(1323, krog),
    finish(1273, krog), accept(1276, krog, "Keep the shield for Mosarn in Thunder Bluff."),
    finish(1177, mudcrush, "Hand Mudcrush his murloc heads south of the village."),
    action("goto", jarl, "Ride east back to Swamp Eye Jarl."),
    finish(1206, jarl),
    note(objective(1202, dm("Captain's Footlocker", 71.5, 51.2), "Follow the road south-east to Theramore. On the docks, open the Captain's Footlocker for the documents. The guards hit hard: get in, grab them and run.",
      "Captain's Documents"), "Many players die here and run back; check how Forever's guards react."),
    action("goto", nazeer, "Ride back north-west to Brackenwall Village."),
    finish(1202, nazeer),
    taxi("fly", B.at("Bragok", 63.09, 37.16, 1413), "Ratchet, The Barrens", "Fly to Ratchet."),
    finish(1270, P.mebok, "Mebok Mizzyrix in Ratchet is Stinky's contact."),
    taxi("fly", B.at("Tal", 47, 49.82, 1456), "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
    finish(1276, on.thunderBluff("Mosarn", 54.01, 80.77), "Mosarn stands on Hunter Rise."),
    taxi("fly", B.at("Omusa Thunderhorn", 44.45, 59.15, 1413), "Camp Taurajo, The Barrens", "Fly to Camp Taurajo."),
    action("goto", myriam, "Ride south down the Barrens road to the thorny mounds of Razorfen Downs."),
    accept(6626, myriam, "Myriam Moonsinger waits outside Razorfen Downs."),
    objective(6626, on.barrens(nil, 47.8, 92.3), "Kill Razorfen Battleguards, Thornweavers and Death's Head Cultists around the entrance.",
      "8 Razorfen Battleguards", "8 Razorfen Thornweavers", "8 Death's Head Cultists"),
    finish(6626, myriam),
    action("hearth", P.gryshka, "Hearth to Orgrimmar.", P.org),
  })
end

-- Alterac and Arathi at 38: Dalaran's patrols, Gol'dir and the Perenoldes from Tarren Mill, then
-- Hammerfall: Myzrael's shards, the raptors and ogres, Stromgarde and Faldir's Cove.
do
  local al, ar, hb = on.alterac, on.arathi, on.hillsbrad
  local goldir = al("Gol'dir", 59.96, 43.74)
  local elysa = al("Elysa", 39.3, 14.31)
  local shards = ar("Iridescent Shards", 84.31, 30.95)
  local korinFel = ar("Korin Fel", 74.04, 33.07)
  local obreen = ar("Shakes O'Breen", 32.28, 81.38)
  local nilzlix = ar("First Mate Nilzlix", 32.8, 81.48)
  local steelgut = ar("Captain Steelgut", 34.0, 80.8)
  local phizzlethorpe = ar("Professor Phizzlethorpe", 33.87, 80.55)
  local draxlegauge = ar("Doctor Draxlegauge", 33.86, 80.45)
  local ruins = al(nil, 15.9, 76.3)
  local stromgarde = ar(nil, 27.7, 63.8)

  need(1048, "Into The Scarlet Monastery", 42, 33)
  need(3341, "Bring the End", 42, 37)
  need(503, "Gol'dir", 36, 29, 533)
  need(506, "Blackmoore's Legacy", 36, 29, 503)
  need(507, "Lord Aliden Perenolde", 42, 29, 506)
  need(508, "Taretha's Gift", 40, 29, 507)
  need(545, "Dalaran Patrols", 35, 30, 544)
  need(557, "Bracers of Binding", 34, 30, 556)
  need(566, "WANTED: Baron Vardus", 40, 35)
  need(639, "Sigil of Strom", 37, 32, 638)
  need(678, "Call to Arms", 38, 30, 677)
  need(679, "Call to Arms", 40, 30, 678)
  need(680, "The Real Threat", 40, 30, 678)
  need(701, "Guile of the Raptor", 37, 29, 675)
  need(702, "Guile of the Raptor", 37, 29, 701)
  need(847, "Guile of the Raptor", 37, 29, 702)
  need(673, "Foul Magics", 40, 35, 671)
  need(92519, "Ward Restocking", 36, nil, 97539, true)

  chapter("arathi-38", "Alterac Mountains and Arathi Highlands", M.arathi, 38, 39, {
    "https://www.wowhead.com/forever/zone=36/alterac-mountains",
    "https://www.wowhead.com/forever/zone=45/arathi-highlands",
    "https://www.wowhead.com/forever/quest=92519",
    questie,
  }, { "badlands-39" }, withTrainers({
    action("boat", P.ucZeppelin, "Leave Orgrimmar by the main gate and take the zeppelin to Tirisfal Glades, then walk into the Undercity."),
    finish(97985, P.calder, "Bring Stormheart's heart to Calder Gray in the Apothecarium."),
    dungeon("scarlet-monastery-cathedral", accept(1048, P.varimathras,
      "Varimathras wants four leaders of the Scarlet Monastery dead. Take it only if you plan to run the monastery's wings.")),
    dungeon("razorfen-downs", accept(3341, on.undercity("Andrew Brownell", 74.05, 33.31),
      "Andrew Brownell wants Amnennar the Coldbringer slain in Razorfen Downs. Take it only if you plan to run the dungeon.")),
    action("train", nil, "Visit your class trainer in the Undercity. Train spells for level", { level = 38 }),
    taxi("fly", B.at("Zarise", 60.14, 18.62, 1424), "Tarren Mill, Hillsbrad", "Fly to Tarren Mill."),
    accept(503, P.krusk, "Krusk has found where the Syndicate holds Gol'dir: free him."),
    accept(557, P.belvaril, "Keeper Bel'varil now wants bracers from the elemental slaves."),
    accept(545, P.voidglare, "Magus Voidglare wants Dalaran's summoners and their slaves thinned."),
    accept(566, hb("WANTED", 62.63, 20.75), "Read the WANTED poster outside the town hall: Baron Vardus, a Syndicate mage in northern Alterac."),
    action("goto", ruins, "Ride north-west into Alterac to the ruins outside Dalaran's walls."),
    along(objective(545, ruins, "Kill Dalaran Summoners and the Elemental Slaves they keep around the ruins.", "6 Dalaran Summoners", "12 Elemental Slaves"), 557),
    along(objective(557, al(nil, 15.6, 76.5), "Elemental Slaves drop Bracers of Earth Binding.", "4 Bracers of Earth Binding"), 545),
    action("goto", al(nil, 62.0, 43.6), "Ride east across Alterac to the Syndicate hideout in the eastern hills."),
    objective(503, al("Jailor Borhuin", 63.1, 43.4), "Kill Jailor Borhuin for his Rusted Iron Key.", "Rusted Iron Key"),
    finish(503, goldir, "Free Gol'dir from his cell nearby and speak with him."),
    accept(506, goldir),
    action("goto", P.krusk, "Ride south back to Tarren Mill."),
    finish(545, P.voidglare), finish(557, P.belvaril),
    finish(506, P.krusk), accept(507, P.krusk, "Krusk wants Lord Aliden Perenolde dead. His mistress Elysa knows where Taretha's pendant is."),
    action("goto", al(nil, 44.0, 16.0), "Ride north through Alterac to the ruins of Alterac in the far north."),
    note(objective(566, al("Baron Vardus", 47.8, 17.1), "Baron Vardus, a level 40 Syndicate mage, holds the east side of the ruins. Pull his guards apart from him.",
      "Head of Baron Vardus"), "Level 40 with guards: group up if you can."),
    note(objective(507, al("Lord Aliden Perenolde", 39.3, 14.6), "Lord Aliden Perenolde, level 41, stays in the manor at the west end of the ruins. Kill him.",
      "Lord Aliden Perenolde slain"), "Level 41 and usually guarded; check in game."),
    finish(507, elysa, "Speak with Elysa beside him."), accept(508, elysa),
    action("goto", P.krusk, "Ride back south to Tarren Mill."),
    finish(508, P.krusk), finish(566, P.darthalia),
    taxi("fly", B.at("Urda", 73, 32.7, 1417), "Hammerfall, Arathi", "Fly to Hammerfall."),
    action("sethearth", P.adegwa, "Bind at the Hammerfall inn.", P.hammerfall),
    finish(638, P.zengu), accept(639, P.zengu),
    accept(678, P.drumFel), accept(701, P.torgan), accept(673, P.torgan),
    accept(92519, P.victor),
    accept(642, ar("Shards of Myzrael", 62.5, 33.73), "Ride a short way west of Hammerfall to the glowing shards by the road."),
    objective(642, ar(nil, 78.5, 35.8), "Ride east into Drywhisker Gorge. Kill the kobolds for Motes of Myzrael.", "12 Motes of Myzrael"),
    finish(642, shards, "Bring the motes to the Iridescent Shards at the back of the gorge."), accept(651, shards),
    part(651, 2, ar("Stone of East Binding", 66.7, 29.7), "Ride back west past Hammerfall to the Stone of East Binding. Touch it and defeat the guardian that appears for the Cresting Key.",
      "Cresting Key"),
    note(objective(92519, ar("Apothecary Jorell", 60.1, 59.3), "Ride south to Go'shek Farm and pick up the case of Packaged Tonics in Jorell's lab.", "Packaged Tonics"),
      "The case has no QuestieDB record; the arrow points at Apothecary Jorell's lab."),
    part(651, 3, ar("Stone of Outer Binding", 52.0, 50.7), "Ride west to the Stone of Outer Binding for the Thundering Key.", "Thundering Key"),
    along(objective(701, ar(nil, 52.3, 66.6), "Ride south and kill Highland Fleshstalkers for Raptor Hearts.", "12 Raptor Hearts"), 678),
    along(objective(678, ar(nil, 53.1, 75.2), "Kill Boulderfist Brutes and Magi at the ogre camp farther south.", "10 Boulderfist Brutes", "4 Boulderfist Magi"), 701),
    optional(action("collect", ar(nil, 55.5, 67.0), "Kill Mesa Buzzards when you see them for Buzzard Wings. Rigglefuzz in the Badlands wants four.",
      { item = 3404, count = 4 })),
    action("hearth", P.adegwa, "Hearth to Hammerfall.", P.hammerfall),
    finish(701, P.torgan), accept(702, P.torgan), finish(702, P.gormul), accept(847, P.gormul), finish(847, P.torgan),
    finish(678, P.drumFel), accept(679, P.drumFel), accept(680, korinFel),
    finish(92519, P.victor),
    action("goto", ar(nil, 25.5, 30.1), "Ride west across the highlands to the Stone of West Binding near Northfold."),
    part(651, 1, ar("Stone of West Binding", 25.5, 30.1), "Take the Burning Key at the Stone of West Binding. The Burning Exiles around it may carry it too.", "Burning Key"),
    finish(651, ar("Stone of Inner Binding", 36.23, 57.38), "Ride south to the Stone of Inner Binding on the hill east of Stromgarde and set the three keys in it."),
    action("goto", stromgarde, "Ride west into the Stromgarde ruins."),
    along(objective(639, stromgarde, "Kill Syndicate Prowlers, Conjurors and Magi in the ruins until one drops the Sigil of Strom.", "Sigil of Strom"), 673),
    note(objective(673, ar("Marez Cowl", 29.6, 63.0), "Marez Cowl, a level 40 Syndicate mage, carries the Befouled Bloodstone Orb.", "Befouled Bloodstone Orb"),
      "Level 40; check her guards in game."),
    along(objective(679, ar(nil, 19.0, 67.4), "Ride to the ogres in the western ruins. Kill Boulderfist Shamans and Lords.", "7 Boulderfist Shaman", "3 Boulderfist Lords"), 680),
    objective(680, ar("Or'Kalar", 18.9, 67.1), "Or'Kalar leads the ogres here. Kill him for his head.", "Or'Kalar's Head"),
    accept(663, ar("Lolo the Lookout", 31.78, 82.68), "Ride south to Faldir's Cove. Lolo the Lookout stands on the cliff above it."),
    finish(663, obreen), accept(662, nilzlix), accept(664, steelgut), accept(665, phizzlethorpe),
    objective(665, phizzlethorpe, "Escort Professor Phizzlethorpe to the cave on the shore. Fight off the surge elemental there, then walk him back.", "Phizzlethorpe escorted"),
    finish(665, draxlegauge), accept(666, draxlegauge),
    along(objective(662, ar(nil, 23.1, 84.5), "Dive to the two wrecks in the cove for their charts and logs. Bring water breathing: a potion, a spell or a held breath and quick swims.",
      "Maiden's Folly Charts", "Maiden's Folly Log", "Spirit of Silverpine Charts", "Spirit of Silverpine Log"), 664, 666),
    along(objective(664, ar(nil, 22.6, 86.6), "Kill Daggerspine Raiders and Sorceresses on the reef.", "10 Daggerspine Raiders", "3 Daggerspine Sorceresses"), 662, 666),
    along(objective(666, ar(nil, 23.2, 86.9), "Wear the Goggles of Gem Hunting and gather Elven Gems from the clams on the reef.", "10 Elven Gems"), 662, 664),
    finish(662, nilzlix), finish(664, steelgut), finish(666, draxlegauge), accept(668, draxlegauge), finish(668, obreen),
    action("hearth", P.adegwa, "Hearth to Hammerfall.", P.hammerfall),
    finish(639, P.zengu), finish(673, P.torgan), finish(679, P.drumFel), finish(680, korinFel),
  }, P.ucTrainers))
end

-- Badlands at 39: over Thandol Span and through Loch Modan to Kargath; Rigglefuzz and Martek, Lotwil's
-- elementals, Jarkal's reagents, the coyotes and the Dustbowl. Ends at Kargath, bound there, for the
-- 40-50 route's flight to Grom'gol.
local badlands = {}
do
  local bl = on.badlands
  badlands.rigglefuzz = bl("Rigglefuzz", 42.39, 52.93)
  badlands.lotwil = bl("Lotwil Veriatus", 25.95, 44.87)
  badlands.shulkar = bl("Innkeeper Shul'kar", 2.8, 45.9)
  badlands.jarkal = bl("Jarkal Mossmeld", 2.42, 46.06)
  badlands.neeka = bl("Neeka Bloodscar", 6.49, 47.2)
  badlands.mushale = bl("Mus'hale", 4.1, 45.6)
  badlands.elementals = bl(nil, 21.7, 45.7)
  badlands.dustbowl = bl(nil, 29.6, 57.0)
  badlands.coyotes = bl(nil, 12.8, 65.6)
  badlands.thandol = on.arathi(nil, 43.4, 92.1)
  badlands.dunAlgaz = on.lochModan(nil, 25.44, 10.38)
  badlands.lochGate = on.lochModan(nil, 47.2, 79.0)

  need(2258, "Badlands Reagent Run", 39, 36)
  need(2202, "Uldaman Reagent Run", 42, 36, 2258)
  need(1419, "Coyote Thieves", 40, 30)
  need(1420, "Report to Helgrum", 40, 30)
  need(97663, "Supplies and Studies", 40, nil, nil, true)
  need(705, "Pearl Diving", 37, 30)

  -- The ride in and the Kargath half, shared with the badlands-37 alternate.
  function badlands.rideIn(text)
    return {
      action("goto", badlands.thandol, text),
      action("goto", badlands.dunAlgaz, "Follow the road south through the Wetlands, then east through Dun Algaz into Loch Modan. Stay on the road and clear of Thelsamar."),
      action("goto", badlands.lochGate, "Take the south road out of Loch Modan into the Badlands."),
    }
  end
  function badlands.kargath()
    local B2 = badlands
    return {
      accept(710, B2.lotwil, "Ride west along the road toward Kargath. Lotwil Veriatus, beside it, wants stone shards from the rock elementals."),
      taxi("getfp", P.gorrik, "Kargath, Badlands", "Ride on west to Kargath and learn the flight path from Gorrik."),
      note(accept(97663, B2.mushale, "Mus'hale wants his stolen supplies back from the ogres of the Dustbowl."),
        "QuestieDB has no record of this Forever quest's giver; Wowhead names Mus'hale at Kargath."),
      action("sethearth", B2.shulkar, "Bind at the Kargath inn.", P.kargath),
      accept(2258, B2.jarkal), accept(1419, B2.neeka),
      action("goto", B2.elementals, "Ride back east to Lotwil's camp."),
      along(objective(710, B2.elementals, "Kill Lesser Rock Elementals around the camp for Small Stone Shards.", "10 Small Stone Shards"), 2258),
      finish(710, B2.lotwil), accept(711, B2.lotwil),
      along(part(2258, 3, bl(nil, 17.7, 42.6), "Lesser Rock Elementals north-west of the camp also drop Rock Elemental Shards.", "5 Rock Elemental Shards"), 711),
      objective(711, bl(nil, 14.5, 34.5), "Ride into the hills north-west of the camp. Kill Rock Elementals for Large Stone Slabs.", "3 Large Stone Slabs"),
      note(objective(97663, B2.dustbowl, "Ride south to the Dustbowl. Kill Dustbelcher ogres until you recover Mus'hale's Stolen Supplies, then use them on the stone etchings nearby for a small and a large rubbing."),
        "The ogre camp and the etchings are not in QuestieDB; the arrow points at the nearest Dustbelcher ogres."),
      along(part(2258, 2, B2.coyotes, "Ride south-west. Kill Elder Crag Coyotes for their fangs.", "10 Crag Coyote Fangs"), 1419),
      along(objective(1419, B2.coyotes, "Every coyote can carry a Coyote Jawbone. Feral and Elder Crag Coyotes roam much of the south.", "30 Coyote Jawbones"), 2258),
      along(part(2258, 1, bl(nil, 15.5, 62.1), "Giant Buzzards circle the same hills. Kill them for their gizzards.", "5 Buzzard Gizzards"), 1419),
    }
  end
  function badlands.home()
    local B2 = badlands
    return {
      finish(2258, B2.jarkal),
      dungeon("uldaman", accept(2202, B2.jarkal, "Jarkal now wants fungus caps from the Uldaman dig. Take it only if you plan to run Uldaman.")),
      finish(1419, B2.neeka), accept(1420, B2.neeka, "Keep Neeka's report for Helgrum the Swift in Stonard, in the Swamp of Sorrows."),
      finish(97663, B2.mushale),
    }
  end

  local martek = bl("Martek the Exiled", 42.22, 52.69)
  local steps = badlands.rideIn("Ride south-west from Hammerfall to Thandol Span and cross into the Wetlands. Alliance guards watch both ends of the bridge.")
  for _, step in ipairs({
    action("goto", badlands.rigglefuzz, "Ride south through the Badlands to Rigglefuzz's camp in the middle of the zone."),
    finish(1106, martek, "Martek the Exiled camps beside Rigglefuzz."), accept(1108, martek),
    accept(703, badlands.rigglefuzz, "Rigglefuzz wants four Buzzard Wings."),
    optional(accept(705, badlands.rigglefuzz, "If you brought nine Blue Pearls from the Vile Reef, Rigglefuzz takes them now.")),
    optional(finish(705, badlands.rigglefuzz)),
  }) do steps[#steps + 1] = step end
  for _, step in ipairs(badlands.kargath()) do steps[#steps + 1] = step end
  for _, step in ipairs({
    objective(1108, bl(nil, 51.5, 67.3), "Ride south-east to the Stonevault troggs past Rigglefuzz's camp. Kill them for Indurium Flakes.", "10 Indurium Flakes"),
    objective(703, bl(nil, 62.5, 54.9), "Kill Buzzards east of Rigglefuzz's camp for their wings, unless you brought them from Arathi.", "4 Buzzard Wings"),
    finish(703, badlands.rigglefuzz), finish(1108, martek),
    finish(711, badlands.lotwil, "Ride west back to Lotwil's camp."),
    action("goto", badlands.jarkal, "Ride on west to Kargath."),
  }) do steps[#steps + 1] = step end
  for _, step in ipairs(badlands.home()) do steps[#steps + 1] = step end
  steps[#steps + 1] = action("grind", badlands.coyotes, "If you are short of level 40, hunt coyotes and buzzards in the hills south of Kargath.", { level = 40 })

  chapter("badlands-39", "Badlands: Kargath", M.badlands, 39, 40, {
    "https://www.wowhead.com/forever/zone=3/badlands",
    "https://www.wowhead.com/forever/quest=97663",
    questie,
  }, nil, steps)
end

-- Alternates for 30-40. Each is a route on its own: it accepts everything it hands in.

-- Stranglethorn early (30-34): Grom'gol and the first two rounds of the Nesingwary hunts.
do
  local st = on.stv
  local hemet = st("Hemet Nesingwary", 35.66, 10.81)
  local ajeck = st("Ajeck Rouack", 35.62, 10.62)
  local erlgadin = st("Sir S. J. Erlgadin", 35.55, 10.55)
  local aggrogosh = st("Commander Aggro'gosh", 32.17, 28.9)
  local nimboya = st("Nimboya", 32.16, 27.72)
  local thulbek = st("Innkeeper Thulbek", 31.5, 29.8)
  local gromgol = { bind = "Grom'gol Base Camp" }

  alternate("stv-30", "Stranglethorn Early: Grom'gol and Nesingwary", M.stv, 30, 34, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    questie,
  }, { "flats-33", "desolace-34", "dustwallow-33" }, {
    taxi("fly", B.at("Doras", 45.12, 63.89, 1454), "Orgrimmar, Durotar", "Fly from Freewind Post to Orgrimmar."),
    action("boat", P.gromgolZeppelin, "Leave Orgrimmar by the main gate and take the zeppelin to Grom'gol from the tower north-east of the city."),
    taxi("getfp", P.thysta, "Grom'gol, Stranglethorn", "Learn the Grom'gol flight path from Thysta."),
    action("sethearth", thulbek, "Bind at the Grom'gol inn. This run starts and ends here.", gromgol),
    action("goto", hemet, "Follow the road north from Grom'gol to Nesingwary's Expedition, just west of the road."),
    accept(583, st("Barnil Stonepot", 35.66, 10.53)), finish(583, hemet),
    accept(194, hemet), accept(185, ajeck), accept(190, erlgadin),
    along(objective(185, st(nil, 36.0, 13.7), "Hunt Young Stranglethorn Tigers around the camp.", "10 Young Stranglethorn Tigers"), 190),
    along(objective(190, st(nil, 41.9, 12.2), "Young Panthers prowl east of the camp, across the road.", "10 Young Panthers"), 185),
    finish(185, ajeck), accept(186, ajeck), finish(190, erlgadin), accept(191, erlgadin),
    objective(186, st(nil, 46.5, 14.8), "Ride east for Stranglethorn Tigers. The Kurzen compound lies just north of them: keep clear.", "10 Stranglethorn Tigers"),
    action("goto", st(nil, 28.8, 14.1), "Ride back west past the camp into the jungle toward the coast."),
    along(objective(191, st(nil, 28.8, 14.1), "Panthers prowl the jungle west of the camp.", "10 Panthers"), 194),
    along(objective(194, st(nil, 25.8, 16.1), "Stranglethorn Raptors hunt nearer the coast. Stay south of the Bloodscalp trolls.", "10 Stranglethorn Raptors"), 191),
    action("grind", st(nil, 28.8, 14.1), "If you are below level 33, keep hunting panthers and raptors here first: the Lashtails and elder tigers are level 34 to 36.",
      { level = 33 }),
    action("goto", hemet, "Ride back east to Nesingwary's camp."),
    finish(186, ajeck), accept(187, ajeck), finish(191, erlgadin), finish(194, hemet), accept(195, hemet),
    action("hearth", thulbek, "Hearth to Grom'gol.", gromgol),
    accept(568, aggrogosh, "Commander Aggro'gosh wants the Lashtail Raptors north of the camp thinned."),
    accept(581, nimboya, "Nimboya wants Bloodscalp tusks."),
    along(objective(195, st(nil, 34.5, 24.0), "Ride north of Grom'gol. Lashtail Raptors run in packs here.", "10 Lashtail Raptors"), 568),
    along(objective(568, st(nil, 34.5, 24.0), "Commander Aggro'gosh wants the same Lashtails dead.", "15 Lashtail Raptors"), 195),
    objective(187, st(nil, 33.5, 18.4), "Elder Stranglethorn Tigers prowl the hills farther north.", "10 Elder Stranglethorn Tigers"),
    objective(581, st(nil, 24.7, 12.1), "Ride north-west to the Bloodscalp camps on the coast. Kill the trolls for their tusks; pull them one at a time.", "9 Bloodscalp Tusks"),
    action("goto", hemet, "Ride east to Nesingwary's camp."),
    finish(187, ajeck), finish(195, hemet),
    action("goto", aggrogosh, "Ride south back to Grom'gol."),
    finish(568, aggrogosh), finish(581, nimboya),
    action("boat", st("Nez'raz", 31.4, 29.9), "Take the zeppelin from Grom'gol back to Orgrimmar."),
  })
end

-- Desolace early (31-36): Gloomrise in Mulgore, then Ghost Walker Post, the Kolkar and Shadowprey.
do
  local ds, mg = on.desolace, on.mulgore
  local takata = ds("Takata Steelblade", 52.57, 54.39)
  local maurin = ds("Maurin Bonesplitter", 52.25, 53.44)
  local felgur = ds("Felgur Twocuts", 56.19, 59.57)
  local gurda = ds("Gurda Wildmane", 56.29, 59.68)
  local smeed = ds("Smeed Scrabblescrew", 60.86, 61.86)
  local uthek = ds("Uthek the Wise", 36.22, 79.25)
  local sikewa = ds("Innkeeper Sikewa", 24.1, 68.2)
  local mailahii = ds("Mai'Lahii", 22.64, 71.97)
  local drulzegar = ds("Drulzegar Skraghook", 23.32, 72.87)
  local thunderAxe = ds(nil, 55.5, 26.5)
  local naga = ds(nil, 36.4, 23.5)
  local muln = mg("Muln Earthfury", 33.41, 22.58)
  local mazukon = mg("Mazu'kon", 32.5, 20.66)
  local yorn = mg("Yorn Grimtotem", 32.47, 19.98)
  local valraxx = mg("Broodmother Valraxx", 33.2, 8.5)
  local gloomrise = mg(nil, 33.6, 12.2)
  local shadowprey = { bind = "Shadowprey Village" }

  alternate("desolace-31", "Desolace Early: Gloomrise and the Centaur", M.desolace, 31, 36, {
    "https://www.wowhead.com/forever/zone=405/desolace",
    "https://www.wowhead.com/forever/zone=215/mulgore",
    "https://www.wowhead.com/forever/quest=93225",
    "https://www.wowhead.com/forever/quest=94873",
    questie,
  }, { "flats-33", "stv-35", "dustwallow-33" }, {
    taxi("fly", B.at("Tal", 47, 49.82, 1456), "Thunder Bluff, Mulgore", "Fly from Freewind Post to Thunder Bluff."),
    action("goto", muln, "Take the lift down and ride north-west across Mulgore to Muln Earthfury at the Skywatcher Plateau."),
    accept(96259, muln), accept(96241, mazukon), accept(96260, yorn),
    along(objective(96259, gloomrise, "Ride north to Gloomrise, the spider nest at the edge of Mulgore. Kill Gloomrise Hatchlings and Soldiers.",
      "10 Gloomrise Hatchlings", "5 Gloomrise Soldiers"), 96241, 96260),
    along(withItem(273015, objective(96241, gloomrise, "Use Mazu'kon's Toxin Extractor on the gnawed corpses around the nest.", "5 Gloomrise Toxin Samples")),
      96259, 96260),
    along(objective(96260, mg(nil, 33.4, 11.6), "Kill Gloomrise Spinners for their Crystalline Silk.", "3 Crystalline Silk"), 96259, 96241),
    action("goto", muln, "Ride back south to the plateau."),
    finish(96259, muln), finish(96241, mazukon), finish(96260, yorn),
    accept(96261, muln),
    objective(96261, valraxx, "Return to Gloomrise and kill Broodmother Valraxx at the back of the nest.", "Broodmother Valraxx slain"),
    withItem(273658, accept(96294, valraxx, "Read the letter Valraxx drops.")),
    finish(96261, muln, "Ride back to Muln Earthfury."), finish(96294, muln),
    note(action("goto", on.stonetalon(nil, 29.2, 90.5), "Ride north out of Mulgore into southern Stonetalon and follow the roads west to the Desolace border."),
      "The path from Gloomrise into Stonetalon needs an in-game check; flying to Sun Rock Retreat and riding south also works."),
    withItem(20310, accept(1480, thunderAxe, "Ride south into Desolace. At Thunder Axe Fortress, kill Burning Blade cultists until one drops a Flayed Demon Skin, then read it.")),
    action("goto", takata, "Follow the road south to Ghost Walker Post."),
    accept(1434, takata), finish(1480, maurin), accept(1481, maurin),
    accept(1365, felgur),
    accept(1368, gurda, "Gurda Wildmane wants you on friendly terms with the Gelkis centaur."),
    note(accept(93225, gurda, "She also wants carved totems from centaur of any clan."),
      "QuestieDB has no giver for this Forever quest; Gurda takes it in."),
    action("goto", ds(nil, 75.1, 16.0), "Ride north-east past Kormek's Hut to Sargeron, the satyr camp in the corner of the zone."),
    along(objective(1434, ds(nil, 75.1, 16.0), "Kill Hatefury Rogues, Felsworn, Betrayers and Hellcallers.", "7 Hatefury Rogues", "7 Hatefury Felsworn",
      "7 Hatefury Betrayers", "7 Hatefury Hellcallers"), 1481),
    objective(1481, ds(nil, 76.7, 24.5), "Hatefury Shadowstalkers, often stealthed, roam the south end of Sargeron. Kill one for its scalp.", "Shadowstalker Scalp"),
    action("goto", ds(nil, 72.3, 45.0), "Ride south to the Kolkar centaur village."),
    along(objective(1365, ds("Khan Dez'hepah", 73.4, 41.6), "Khan Dez'hepah leads the Kolkar from the north end of the village. Kill him for his head.",
      "Khan Dez'hepah's Head"), 93225),
    objective(93225, ds(nil, 72.3, 45.0), "Kill Kolkar centaur until you have five Carved Centaur Totems.", "5 Carved Centaur Totems"),
    action("goto", takata, "Ride south-west back to Ghost Walker Post."),
    finish(1434, takata),
    finish(1481, maurin), accept(1482, maurin, "Maurin now wants an Oracle Crystal from the Slitherblade naga on the north-west coast."),
    finish(1365, felgur),
    finish(93225, gurda), note(accept(94873, gurda, "Take the Totem Tote to the Gelkis quartermaster."),
      "QuestieDB has no giver for this Forever quest; Gurda takes in the totems before it."),
    accept(5561, smeed, "Ride south-east to Smeed Scrabblescrew's camp beside the Kodo Graveyard."),
    withItem(13892, objective(5561, ds(nil, 52.5, 58.3), "Use the Kodo Kombobulator on Ancient or Dying Kodos in the graveyard and lead each tamed kodo back to Smeed.",
      "5 Kodos Tamed")),
    finish(5561, smeed),
    action("goto", uthek, "Ride south-west to the Gelkis village."),
    note(finish(94873, uthek, "Hand the Totem Tote to the Gelkis quartermaster in the village."),
      "The quartermaster has no QuestieDB record; the arrow points at Uthek the Wise in the same village."),
    finish(1368, uthek, "Uthek the Wise welcomes you now that the Gelkis are friendly."),
    taxi("getfp", P.thalon, "Shadowprey Village, Desolace", "Ride west to Shadowprey Village on the coast and learn the flight path from Thalon."),
    action("sethearth", sikewa, "Bind at the Shadowprey inn.", shadowprey),
    accept(6142, mailahii), accept(6143, drulzegar),
    action("goto", naga, "Ride north along the coast road to the Slitherblade naga below Ethel Rethor."),
    along(objective(6143, ds(nil, 34.2, 23.5), "Kill Slitherblade Naga, Sorceresses and Myrmidons up the coast.", "7 Slitherblade Myrmidons",
      "7 Slitherblade Naga", "5 Slitherblade Sorceresses"), 6142, 1482),
    along(objective(6142, naga, "The naga carry Soft-shelled Clam Meat.", "10 Soft-shelled Clam Meat"), 6143),
    objective(1482, ds("Slitherblade Oracle", 32.7, 12.9), "Slitherblade Oracles stand farther north. Kill one for its crystal.", "Oracle Crystal"),
    action("goto", takata, "Ride south-east across Desolace to Ghost Walker Post."),
    finish(1482, maurin), accept(1484, maurin), finish(1484, takata),
    action("hearth", sikewa, "Hearth to Shadowprey Village.", shadowprey),
    finish(6142, mailahii), finish(6143, drulzegar),
    taxi("fly", B.at("Tal", 47, 49.82, 1456), "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
  })
end

-- Dustwallow first (33-37): Brackenwall Village before the Shimmering Flats or Desolace.
do
  local dm = on.dustwallow
  local krog = dm("Krog", 36.42, 31.88)
  local dogol = dm("Do'gol", 36.53, 30.79)
  local nazeer = dm("Nazeer Bloodpike", 35.21, 30.66)
  local ogron = dm("Ogron", 40.96, 36.69)
  local mudcrush = dm("Mudcrush Durtfeet", 35.15, 38.26)
  local jarl = dm("\"Swamp Eye\" Jarl", 55.44, 26.27)
  local spiders = dm(nil, 32.8, 22.2)

  alternate("dustwallow-33", "Dustwallow First: Brackenwall Village", M.dustwallow, 33, 37, {
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    questie,
  }, { "desolace-34", "stv-35", "arathi-38" }, {
    action("goto", P.devrak, "Travel to the Crossroads: fly there from any Horde flight master in Kalimdor."),
    action("buy", on.barrens("Tarban Hearthgrain", 55.2, 32.1), "Buy 3 Soothing Spices from Tarban Hearthgrain, the Crossroads baker. Swamp Eye Jarl in Dustwallow wants them.",
      { item = 3713, count = 3 }),
    taxi("fly", B.at("Omusa Thunderhorn", 44.45, 59.15, 1413), "Camp Taurajo, The Barrens", "Fly to Camp Taurajo."),
    action("goto", dm("Suspicious Hoofprint", 29.7, 47.64), "Ride east out of the Barrens into Dustwallow Marsh and follow the road to the burned Shady Rest Inn."),
    accept(1268, dm("Suspicious Hoofprint", 29.7, 47.64), "Look at the hoofprints by the inn."),
    accept(1269, dm("Theramore Guard Badge", 29.83, 48.24), "Pick up the guard badge lying nearby."),
    accept(1251, dm("Black Shield", 29.63, 48.62), "Take the black shield beside the inn."),
    action("goto", krog, "Follow the road north to Brackenwall Village."),
    taxi("getfp", P.shardi, "Brackenwall Village, Dustwallow Marsh", "Learn the Brackenwall flight path from Shardi."),
    finish(1268, krog), finish(1269, krog), finish(1251, krog), accept(1321, krog),
    finish(1321, dogol), accept(1322, dogol),
    accept(1201, nazeer),
    accept(1273, ogron, "Ogron waits south-east of the village. He takes you to question Reethe."),
    note(objective(1273, ogron, "Follow Ogron to Reethe and stay with him through the questioning. Fight off the ambush that follows."),
      "The escort's path is not in QuestieDB; check in game."),
    accept(1177, mudcrush, "Mudcrush Durtfeet, a friendly ogre south of the village, is hungry for murloc heads."),
    objective(1201, dm(nil, 38.6, 24.4), "Theramore Infiltrators sneak through the reeds north-east of the village. Kill them.", "9 Theramore Infiltrators"),
    accept(1270, dm("\"Stinky\" Ignatz", 46.88, 17.52), "Ride north-east to \"Stinky\" Ignatz in the bog. His escape is an escort."),
    note(objective(1270, dm(nil, 48.8, 24.5), "Escort Stinky while he gathers bog samples and fight off the attackers."),
      "Escort route from the classic quest; check in game."),
    accept(1218, jarl, "Ride east to Swamp Eye Jarl's shack and hand him the spices at once."), finish(1218, jarl),
    accept(1206, jarl),
    accept(1238, dm("Loose Dirt", 55.44, 25.92), "Search the loose dirt beside Jarl's shack."),
    objective(1177, dm(nil, 56.8, 15.6), "Ride north to the coast and kill Mirefin murlocs for their heads.", "8 Mirefin Heads"),
    action("goto", spiders, "Ride west along the north of the marsh to the Darkmist spider caves north of Brackenwall."),
    along(objective(1206, spiders, "Kill Darkmist spiders for Unpopped Darkmist Eyes.", "20 Unpopped Darkmist Eyes"), 1322),
    along(objective(1322, dm(nil, 33.0, 22.1), "The same spiders carry Acidic Venom Sacs.", "5 Acidic Venom Sacs"), 1206),
    finish(1201, nazeer), accept(1202, nazeer), finish(1238, nazeer),
    finish(1322, dogol), accept(1323, dogol), finish(1323, krog),
    finish(1273, krog), accept(1276, krog, "Keep the shield for Mosarn in Thunder Bluff."),
    finish(1177, mudcrush, "Hand Mudcrush his murloc heads south of the village."),
    action("goto", jarl, "Ride east back to Swamp Eye Jarl."),
    finish(1206, jarl),
    note(objective(1202, dm("Captain's Footlocker", 71.5, 51.2), "Follow the road south-east to Theramore. On the docks, open the Captain's Footlocker for the documents. The guards hit hard: get in, grab them and run.",
      "Captain's Documents"), "Many players die here and run back; check how Forever's guards react."),
    action("goto", nazeer, "Ride back north-west to Brackenwall Village."),
    finish(1202, nazeer),
    taxi("fly", B.at("Bragok", 63.09, 37.16, 1413), "Ratchet, The Barrens", "Fly to Ratchet."),
    finish(1270, P.mebok, "Mebok Mizzyrix in Ratchet is Stinky's contact."),
    taxi("fly", B.at("Tal", 47, 49.82, 1456), "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
    finish(1276, on.thunderBluff("Mosarn", 54.01, 80.77), "Mosarn stands on Hunter Rise."),
  })
end

-- Badlands first (37-40): Kargath before or instead of Arathi.
do
  local steps = { action("goto", P.urda, "Travel to Hammerfall in Arathi. Fly there if you have the flight path; otherwise fly to Tarren Mill and take the east road.") }
  for _, step in ipairs(badlands.rideIn("Ride south-west from Hammerfall to Thandol Span and cross into the Wetlands. Alliance guards watch both ends of the bridge.")) do
    steps[#steps + 1] = step
  end
  for _, step in ipairs({
    action("goto", badlands.rigglefuzz, "Ride south through the Badlands to Rigglefuzz's camp in the middle of the zone."),
    accept(703, badlands.rigglefuzz, "Rigglefuzz wants four Buzzard Wings."),
    optional(accept(705, badlands.rigglefuzz, "If you brought nine Blue Pearls from the Vile Reef, Rigglefuzz takes them now.")),
    optional(finish(705, badlands.rigglefuzz)),
    objective(703, on.badlands(nil, 62.5, 54.9), "Kill Buzzards east of the camp for their wings.", "4 Buzzard Wings"),
    finish(703, badlands.rigglefuzz),
  }) do steps[#steps + 1] = step end
  for _, step in ipairs(badlands.kargath()) do steps[#steps + 1] = step end
  steps[#steps + 1] = action("goto", badlands.lotwil, "Ride north-east back to Lotwil's camp.")
  steps[#steps + 1] = finish(711, badlands.lotwil)
  steps[#steps + 1] = action("goto", badlands.jarkal, "Ride on west to Kargath.")
  for _, step in ipairs(badlands.home()) do steps[#steps + 1] = step end
  steps[#steps + 1] = action("grind", badlands.coyotes, "If you are short of level 40, hunt coyotes and buzzards in the hills south of Kargath.", { level = 40 })

  alternate("badlands-37", "Badlands First: Kargath", M.badlands, 37, 40, {
    "https://www.wowhead.com/forever/zone=3/badlands",
    "https://www.wowhead.com/forever/quest=97663",
    questie,
  }, { "arathi-38" }, steps)
end

-- Roads for the 30-40 legs no Horde flight path covers.
do
  local road = H.road
  road(M.arathi, M.wetlands, badlands.thandol, "Cross Thandol Span south into the Wetlands")
  road(M.arathi, M.lochModan, badlands.thandol, "Cross Thandol Span, then ride east through Dun Algaz")
  road(M.arathi, M.badlands, badlands.thandol, "Cross Thandol Span and ride through the Wetlands and Loch Modan to the Badlands")
  road(M.wetlands, M.lochModan, badlands.dunAlgaz, "Take the road east through Dun Algaz into Loch Modan")
  road(M.wetlands, M.badlands, badlands.dunAlgaz, "Ride through Dun Algaz and Loch Modan to the Badlands")
  road(M.lochModan, M.badlands, badlands.lochGate, "Take the south road out of Loch Modan into the Badlands")
  road(M.alterac, M.hillsbrad, on.hillsbrad(nil, 54.6, 40.9), "Ride south out of the Alterac hills into Hillsbrad")
  road(M.mulgore, M.desolace, on.stonetalon(nil, 29.2, 90.5), "Ride north into Stonetalon and follow the roads west to Desolace")
end
