-- Horde route: Hillsbrad, the southern Barrens, Stonetalon, Ashenvale and Thousand Needles (22-30).
-- Source notes: tools/audits/2026-11-10-horde-22-30.md.
--
-- Quests accepted before level 22 belong to the 12-22 files. Their objectives and turn-ins sit
-- here as "-- CARRY:" comments followed by "-->" code lines: at integration, remove the "-->"
-- prefix from those lines and delete the CARRY chains loop below the quest list.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local M = B.maps
local at, q, quest = B.at, B.q, B.quest
local accept, finish, objectiveAt, action, taxi = B.accept, B.finish, B.objectiveAt, B.action, B.taxi
local withItem, withTrainers, forDungeon, along, only = B.withItem, B.withTrainers, B.forDungeon, B.along, B.only

local function objectivePart(id, index, place, text, label)
  local step = objectiveAt(id, place, text, label)
  step.objectiveIndex = index
  return step
end

-- Concatenate step lists (sections mix trainer towns, so withTrainers runs per piece).
local function cat(...)
  local result = {}
  for i = 1, select("#", ...) do
    for _, step in ipairs((select(i, ...))) do result[#result + 1] = step end
  end
  return result
end

-- A carried quest is defined here only if the file that accepts it has not done so already.
local function carriedQ(id, name, level, min, prerequisite)
  if not quest[id] then q(id, name, level, min, prerequisite) end
end

local function road(from, to, waypoint, label)
  route.roadTo[to] = route.roadTo[to] or {}
  if not route.roadTo[to][from] then route.roadTo[to][from] = { waypoint = waypoint, label = label } end
end

-- Quests (facts: tools/questfacts.py, QuestieDB Forever 0f7d8ad; Forever IDs checked in tools/reference/forever.json).
q(441, "Raleigh and the Undercity", 16, 10, 440)
q(530, "A Husband's Revenge", 20, 10, 441)
q(1013, "The Book of Ur", 26, 16)
q(516, "Beren's Peril", 21, 16)
q(95981, "Watching the Roads", 20, nil, nil, true)
q(493, "Journey to Hillsbrad Foothills", 20, 19)
q(95884, "The Offering Stone", 23, nil, nil, true)
q(95883, "The Tortured Soul", 23, nil, 95884, true)
q(95885, "The Offering of Blood", 23, nil, 95883, true)
q(494, "Time To Strike", 20, 19)
q(1066, "Blood of Innocents", 23, 13, 1065)
q(496, "Elixir of Suffering", 22, 19)
q(499, "Elixir of Suffering", 22, 19, 496)
q(501, "Elixir of Pain", 24, 21)
q(502, "Elixir of Pain", 24, 21, 501)
q(527, "Battle of Hillsbrad", 24, 19)
q(528, "Battle of Hillsbrad", 25, 19, 527)
q(529, "Battle of Hillsbrad", 26, 19, 528)
q(546, "Souvenirs of Death", 25, 20, 527)
q(549, "WANTED: Syndicate Personnel", 22, 17)
q(498, "The Rescue", 22, 17)
q(1067, "Return to Thunder Bluff", 23, 13, 1066)
q(98094, "Scout Support", 25, nil, 528, true)
q(98095, "Valuable Vantages", 25, nil, 98094, true)
q(1098, "Deathstalkers in Shadowfang", 25, 18)
q(1014, "Arugal Must Die", 27, 18)
q(1086, "The Flying Machine Airport", 23, 13, 1067)
q(1195, "The Sacred Flame", 25, 20)
q(1196, "The Sacred Flame", 29, 20, 1195)
q(1197, "The Sacred Flame", 29, 20, 1196)
q(97538, "Pigments for Paints", 26, nil, nil, true)

q(6382, "The Ashenvale Hunt", 20, 20)
q(879, "Betrayal from Within", 25, 17, 5052)
q(906, "Betrayal from Within", 25, 17, 879)
q(97250, "Wrongly Blamed, Justly Corrected", 23, nil, nil, true)
q(884, "Owatanka", 24, 10)
q(885, "Washte Pawne", 25, 10)
q(897, "The Harvester", 24, 10)
quest[884].startItem, quest[885].startItem, quest[897].startItem = 5102, 5103, 5138
q(843, "Gann's Reclamation", 23, 17)
q(846, "Revenge of Gann", 26, 17, 843)
q(849, "Revenge of Gann", 26, 17, 846)
q(98093, "Field to Clear", 23, nil, nil, true)
q(893, "Weapons of Choice", 24, 17)
q(1153, "A New Ore Sample", 29, 25, 893)
q(1130, "Melor Sends Word", 30, 20)
q(1131, "Steelsnap", 30, 20, 1130)
-- Weapons of Choice needs three Razormane drops from the northern Barrens: optional, with its follow-up.
quest[893].optional, quest[1153].optional = true, true

q(1087, "Cenarius' Legacy", 25, 20)
q(1088, "Ordanus", 29, 20, 1087)
q(6282, "Harpies Threaten", 26, 18)
q(6283, "Bloodfury Bloodline", 26, 18, 6282)
q(86576, "Bloodfury Trinkets", 26, nil, nil, true)
q(6381, "New Life", 25, 17, 6301)
q(6284, "Arachnophobia", 21, 15)
q(5881, "Calling in the Reserves", 28, 23)

q(6544, "Torek's Assault", 24, 20)
q(6503, "Ashenvale Outrunners", 24, 19)
q(6383, "The Ashenvale Hunt", 20, 20, 6382)
q(25, "Stonetalon Standstill", 25, 23)
q(6441, "Satyr Horns", 26, 21)
q(1918, "The Befouled Element", 27, 23)
q(824, "Je'neu of the Earthen Ring", 27, 23, 1918)
q(6482, "Freedom to Ruul", 24, 19)
q(23, "Ursangous's Paw", 24, 20, 6383)
q(24, "Shadumbra's Head", 27, 20, 6383)
q(2, "Sharptalon's Claw", 30, 20, 6383)
q(247, "The Hunt Completed", 30, 20, { 2, 23, 24 })
quest[2].startItem, quest[2].optional, quest[247].optional = 16305, true, true
q(6563, "The Essence of Aku'Mai", 22, 17, 6562)
q(6921, "Amongst the Ruins", 27, 21)

q(857, "The Tear of the Moons", 30, 22)
q(4542, "Message to Freewind Post", 25, 23)
q(4841, "Pacify the Centaur", 25, 23, 4542)
q(5064, "Grimtotem Spying", 28, 24, 4841)
q(5147, "Wanted - Arnak Grimtotem", 29, 25)
q(98069, "Stolen Freewind Supplies", 31, nil, nil, true)
q(98070, "Stop the Screeching", 31, nil, nil, true)
q(4821, "Alien Egg", 26, 24)
q(4865, "Serpent Wild", 26, 24, 4821)
q(5062, "Sacred Fire", 27, 24, 4865)
q(5088, "Arikara", 28, 24, 5062)
q(4767, "Wind Rider", 29, 25)
q(4770, "Homeward Bound", 29, 25)
q(5151, "Hypercapacitor Gizmo", 30, 24)
q(4881, "Assassination Plot", 28, 23)
q(4966, "Protect Kanati Greycloud", 28, 23, 4881)
quest[4881].startItem = 12564
q(1149, "Test of Faith", 26, 25)
q(1150, "Test of Endurance", 30, 25, 1149)
q(1151, "Test of Strength", 30, 25, 1150)
q(4904, "Free at Last", 29, 25)
quest[98094].optional, quest[98095].optional = true, true

q(1104, "Salt Flat Venom", 30, 28)
q(1105, "Hardened Shells", 30, 28)
q(1176, "Load Lightening", 30, 29)
q(1110, "Rocket Car Parts", 31, 28)

-- Quests the 12-22 files accept; their remaining steps are CARRY lines below.
carriedQ(440, "The Engraved Ring", 16, 10, 439)
carriedQ(3301, "Mura Runetotem", 15, 10, 880)
carriedQ(264, "Until Death Do Us Part", 15, 12)
carriedQ(92401, "A Frightened Request", 22, nil)
carriedQ(1065, "Journey to Tarren Mill", 18, 13, 1064)
carriedQ(868, "Egg Hunt", 22, 17)
carriedQ(1068, "Shredding Machines", 23, 13, 1062)
carriedQ(1092, "Gerenzo's Orders", 22, 17, 1090)
carriedQ(1096, "Gerenzo Wrenchwhistle", 27, 16, 1095)
carriedQ(1058, "Jin'Zil's Forest Magic", 26, 20)
carriedQ(6301, "Cycle of Rebirth", 23, 17)
carriedQ(6393, "Elemental War", 25, 19)
carriedQ(216, "Between a Rock and a Thistlefur", 24, 21)
carriedQ(6462, "Troll Charm", 24, 19)

-- CARRY chains: these prerequisites are turned in by the 12-22 files (or by CARRY lines that
-- stay commented until integration). Delete this loop once the CARRY lines are live.
for _, id in ipairs({ 441, 1066, 879, 6381, 6563 }) do quest[id].chain = nil end

-- Thunder Bluff and Undercity trainers (QuestieDB spawns; RestedXP for the two it lacks).
local tb = function(name, x, y) return at(name, x, y, M.thunderBluff) end
local ucTrainers = {
  { "WARRIOR", at("Angela Curthas", 48.3, 16.0, M.undercity) },
  { "ROGUE", at("Carolyn Ward", 83.9, 72.1, M.undercity) },
  { "PRIEST", at("Aelthalyste", 49.3, 17.1, M.undercity) },
  { "MAGE", at("Lexington Mortaim", 84.2, 15.6, M.undercity) },
  { "WARLOCK", at("Richard Kerwin", 88.9, 15.9, M.undercity) },
}
local tbOthers = {
  { "HUNTER", tb("Urek Thunderhorn", 59.1, 86.9) },
  { "SHAMAN", tb("Tigor Skychaser", 23.6, 18.8) },
  { "DRUID", tb("Kym Wildmane", 77.2, 29.8) },
  { "PALADIN", tb("Alodan the Hopeful", 25.18, 14.4) },
}
local tbTrainers = {
  { "WARRIOR", tb("Ker Ragetotem", 57.6, 85.5) },
  { "HUNTER", tb("Urek Thunderhorn", 59.1, 86.9) },
  { "ROGUE", tb("Boarton Shadetotem", 39.49, 65.88) },
  { "PRIEST", tb("Miles Welsh", 25.3, 15.3) },
  { "SHAMAN", tb("Tigor Skychaser", 23.6, 18.8) },
  { "MAGE", tb("Archmage Shymm", 22.8, 14.5) },
  { "DRUID", tb("Kym Wildmane", 77.2, 29.8) },
  { "PALADIN", tb("Alodan the Hopeful", 25.18, 14.4) },
}

-- Thunder Bluff people the route visits more than once.
local tbPlaces = {
  tal = tb("Tal", 47.0, 49.82),
  zamah = tb("Apothecary Zamah", 22.81, 20.89),
  zangen = tb("Zangen Stonehoof", 54.97, 51.41),
  tah = tb("Tah Winterhoof", 54.14, 47.05),
  melor = tb("Melor Stonehoof", 61.54, 80.92),
  magatha = tb("Magatha Grimtotem", 69.85, 30.91),
}

-- The Sepulcher (22-23): zeppelin to Tirisfal, Undercity pickups, southern Silverpine.
local sepulcher = (function()
  local function sp(name, x, y) return at(name, x, y, M.silverpine) end
  local zeppelin = at(nil, 50.8, 13.8, M.durotar)
  local sevren = at("Magistrate Sevren", 61.26, 50.84, M.tirisfal)
  local raleigh = at("Raleigh Andrean", 62.01, 42.75, M.undercity)
  local garrett = at("Michael Garrett", 63.25, 48.56, M.undercity)
  local karos = sp("Karos Razok", 45.62, 42.58)
  local allister = sp("Shadow Priest Allister", 43.98, 40.93)
  local stone = sp("Offering Stone", 58.12, 69.77)
  return {
    action("boat", zeppelin, "Leave Orgrimmar by the main gate and climb the zeppelin tower north-east of the city. Take the zeppelin to Tirisfal Glades."),
    -- CARRY: turnin 440 The Engraved Ring at Magistrate Sevren (accepted from Hadrec at the Sepulcher before 22)
    --> finish(440, sevren, "Walk north-east from the zeppelin tower to Brill and give Deliah's ring to Magistrate Sevren in the town hall."),
    accept(441, sevren, "If you carry Deliah's ring from the Sepulcher, Magistrate Sevren in Brill's town hall sends it on to the Undercity. Otherwise use Next."),
    finish(441, raleigh, "Enter the Undercity through the ruined city south of Brill. Raleigh stands in the Trade Quarter."),
    accept(530, raleigh),
    forDungeon(accept(1013, at("Keeper Bel'dugur", 53.74, 54.46, M.undercity),
      "Keeper Bel'dugur in the Apothecarium wants the Book of Ur from Shadowfang Keep."), "dungeon-shadowfang-keep"),
    taxi("getfp", garrett, "Undercity, Tirisfal", "Learn the Undercity flight path from Michael Garrett, the bat handler east of the Trade Quarter."),
    action("goto", karos, "Fly to the Sepulcher if you know the route. Otherwise leave the Undercity, follow the road west then south into Silverpine Forest and up to the Sepulcher."),
    taxi("getfp", karos, "The Sepulcher, Silverpine Forest", "Learn the Sepulcher flight path from Karos Razok."),
    accept(516, allister), accept(95981, allister),
    accept(493, sp("Apothecary Renferrel", 42.8, 40.86)),
    -- CARRY: turnin 3301 Mura Runetotem at Mura Runetotem (accepted from Tonga at the Crossroads before 22)
    --> finish(3301, sp("Mura Runetotem", 42.91, 41.99)),
    -- CARRY: turnin 264 Until Death Do Us Part at Yuriv's Tombstone (accepted from Clarice Foster in Thunder Bluff before 22)
    --> finish(264, sp("Yuriv's Tombstone", 44.19, 42.67), "Place Clarice's pendant on Yuriv's tombstone in the graveyard behind the Sepulcher."),
    -- CARRY: turnin 92401 A Frightened Request at Tabitha Heartweaver (accepted in the Undercity before 22)
    --> finish(92401, sp("Tabitha Heartweaver", 44.52, 43.02)),
    objectiveAt(530, sp("Valdred Moray", 44.6, 84.7), "Follow the road south past Pyrewood Village to the Greymane Wall. Kill Valdred Moray, a level 21 human camped beside the wall.",
      "Valdred Moray slain"),
    along(withItem(271343, accept(95884, sp(nil, 58.3, 71.3),
      "Head east into the hills to Beren's Peril. Kill Ravenclaw Drudgers and Guardians outside the cave until one drops a Note Scrap, then use it.")), 516),
    finish(95884, stone, "Follow the cave to the Offering Stone at the back."),
    accept(95883, stone),
    along(objectiveAt(95883, sp(nil, 57.15, 70.37), "Kill Ravenclaws in the cave until you loot a Tortured Soul.", "Tortured Soul"), 516),
    finish(95883, stone), accept(95885, stone),
    withItem(210713, objectiveAt(95885, stone, "Heal up, then use the Tortured Soul at the Offering Stone and kill the spirit it releases.")),
    finish(95885, stone),
    objectiveAt(516, sp(nil, 58.3, 71.3), "Finish the Ravenclaw kills inside and outside the cave.", "6 Ravenclaw Drudgers", "6 Ravenclaw Guardians"),
    objectiveAt(95981, sp(nil, 63.3, 76.0), "Kill Dalaran Watchers and Wizards at the Dalaran camp south-east of Beren's Peril. A second camp sits at Ambermill (64, 58).",
      "8 Dalaran Watchers", "8 Dalaran Wizards"),
  }
end)()

-- Hillsbrad Foothills (23-25): Tarren Mill, then back through the Sepulcher and the Undercity to Thunder Bluff.
local hillsbrad = (function()
  local function hb(name, x, y) return at(name, x, y, M.hillsbrad) end
  local lydon = hb("Apothecary Lydon", 61.44, 19.06)
  local darthalia = hb("High Executor Darthalia", 62.33, 20.45)
  local krusk = hb("Krusk", 63.24, 20.66)
  local samsa = hb("Deathguard Samsa", 62.11, 19.7)
  local zarise = hb("Zarise", 60.14, 18.62)
  local masoj = hb("Deathstalker Masoj", 63.58, 53.11)
  local allister = at("Shadow Priest Allister", 43.98, 40.93, M.silverpine)
  local garrett = at("Michael Garrett", 63.25, 48.56, M.undercity)
  local fields = {
    accept(494, hb("Deathstalker Lesh", 20.79, 47.4), "Take the road east out of Silverpine into Hillsbrad. Deathstalker Lesh waits beside the road just past the border."),
    taxi("getfp", zarise, "Tarren Mill, Hillsbrad", "Follow the road north-east to Tarren Mill and learn the flight path from Zarise."),
    finish(493, lydon),
    -- CARRY: turnin 1065 Journey to Tarren Mill at Apothecary Lydon (accepted from Zamah in Thunder Bluff before 22)
    --> finish(1065, lydon),
    accept(1066, lydon, "If you brought Zamah's note, Lydon now wants blood from the Syndicate mages. Otherwise use Next."),
    accept(496, lydon), accept(501, lydon),
    finish(494, darthalia), accept(527, darthalia),
    accept(549, hb("WANTED", 62.63, 20.75), "Read the WANTED poster outside the town hall."),
    accept(498, krusk),
    along(objectiveAt(496, hb(nil, 63.9, 34.9), "Go south-east toward Durnholde Keep. Kill Gray Bears and Forest Moss Creepers on the way for tongues and ichor.",
      "10 Gray Bear Tongues", "Creeper Ichor"), 498, 549),
    along(objectivePart(498, 2, hb(nil, 79.79, 39.65), "Enter Durnholde Keep. Find Tog'thar chained at the east side of the keep (80, 40) and free him.", "Rescue Tog'thar"), 549, 1066),
    along(objectivePart(498, 1, hb(nil, 75.33, 41.5), "Find Drull chained at the west side of the keep (75, 41) and free him.", "Rescue Drull"), 549, 1066),
    along(objectiveAt(549, hb(nil, 77.6, 43.0), "Clear Syndicate Rogues and Watchmen inside the keep. Mages give the Vials of Innocent Blood.",
      "10 Syndicate Rogues", "10 Syndicate Watchmen"), 1066),
    objectiveAt(1066, hb(nil, 67.22, 45.85), "Kill Syndicate Shadow Mages in the keep and at the camp west of it until you have five vials.", "5 Vials of Innocent Blood"),
    objectiveAt(496, hb(nil, 62.7, 36.2), "Finish the bear tongues and creeper ichor on the slopes north of the keep on your way back.", "10 Gray Bear Tongues", "Creeper Ichor"),
    finish(498, krusk), finish(549, darthalia),
    finish(1066, lydon), finish(496, lydon), accept(499, lydon), accept(1067, lydon),
    finish(499, hb("Umpi", 61.55, 19.14), "Give the elixir to Umpi beside Lydon."),
    along(objectiveAt(501, hb(nil, 53.1, 35.3), "Head west toward Hillsbrad Fields. Kill Starving Mountain Lions in the hills along the way.", "10 Vials of Mountain Lion Blood"), 527),
    objectivePart(527, 4, hb("Farmer Getz", 35.21, 37.53), "Kill Farmer Getz in the house at the east edge of the fields.", "Farmer Getz slain"),
    objectivePart(527, 3, hb("Farmer Ray", 33.68, 35.44), "Kill Farmer Ray in the farmhouse to the north-west.", "Farmer Ray slain"),
    objectivePart(527, 1, hb(nil, 32.7, 36.9), "Kill Hillsbrad Farmers in the fields.", "6 Hillsbrad Farmers"),
    objectivePart(527, 2, hb(nil, 34.8, 40.8), "Kill Hillsbrad Farmhands in the fields to the south.", "6 Hillsbrad Farmhands"),
    objectiveAt(501, hb(nil, 54.3, 43.2), "Finish the lion blood on the way back to Tarren Mill.", "10 Vials of Mountain Lion Blood"),
    finish(501, lydon), accept(502, lydon),
    finish(527, darthalia), accept(528, darthalia),
    accept(546, samsa),
    finish(502, hb("Stanley", 32.66, 35.32), "Return to the fields and feed the elixir to Stanley, the dog by the farmhouse. Be at full health: he turns into Enraged Stanley."),
    along(objectiveAt(528, hb(nil, 34.0, 44.9), "Kill Hillsbrad Peasants in the orchards south of the fields. Loot human skulls as you go.", "15 Hillsbrad Peasants"), 546),
    finish(528, darthalia, "Go back to Tarren Mill."), accept(529, darthalia),
    accept(98094, darthalia, "Darthalia also has orders for a scout south of town. Optional: it adds a short loop to Dun Garok."),
    finish(98094, masoj, "Ride south along the road to Deathstalker Masoj outside Dun Garok. Lions, creepers and gnolls of level 26 to 28 live around him."),
    accept(98095, masoj),
    objectiveAt(98095, masoj, "Place the three Apothecary Vials on the peaks shown on your quest map, then return to Masoj."),
    finish(98095, masoj),
    objectivePart(529, 3, hb(nil, 32.02, 45.45), "Go to the smithy in Hillsbrad and loot the Shipment of Iron crate.", "Shipment of Iron"),
    along(objectivePart(529, 1, hb("Blacksmith Verringtan", 32.23, 45.32), "Kill Blacksmith Verringtan at his forge.", "Blacksmith Verringtan slain"), 546),
    along(objectivePart(529, 2, hb(nil, 32.23, 45.32), "Kill the Apprentice Blacksmiths around the smithy.", "4 Hillsbrad Apprentice Blacksmiths"), 546),
    objectiveAt(546, hb(nil, 34.5, 42.5), "Finish the skulls on any Hillsbrad humans around the fields and orchards.", "30 Hillsbrad Human Skulls"),
    finish(529, darthalia, "Return to Tarren Mill."), finish(546, samsa),
    taxi("fly", zarise, "The Sepulcher, Silverpine Forest", "Fly to the Sepulcher."),
    finish(516, allister), finish(95981, allister),
    forDungeon(accept(1098, at("High Executor Hadrec", 43.42, 40.86, M.silverpine), "High Executor Hadrec wants two deathstalkers found inside Shadowfang Keep."),
      "dungeon-shadowfang-keep"),
    forDungeon(accept(1014, at("Dalar Dawnweaver", 44.2, 39.81, M.silverpine), "Dalar Dawnweaver wants Archmage Arugal's head from Shadowfang Keep."),
      "dungeon-shadowfang-keep"),
    taxi("fly", at("Karos Razok", 45.62, 42.58, M.silverpine), "Undercity, Tirisfal", "Fly to the Undercity."),
    finish(530, at("Raleigh Andrean", 62.01, 42.75, M.undercity), "Tell Raleigh in the Trade Quarter that Valdred is dead."),
    action("train", nil, "Visit your class trainer in the Undercity. Train spells for level", { level = 24 }),
  }
  local home = {
    action("boat", at(nil, 60.8, 58.7, M.tirisfal), "Leave the Undercity and take the zeppelin to Orgrimmar from the tower west of the ruins."),
    taxi("fly", at("Doras", 45.12, 63.89, M.orgrimmar), "Thunder Bluff, Mulgore", "Enter Orgrimmar and fly to Thunder Bluff from Doras on the flight tower in the Valley of Strength."),
    finish(1067, tbPlaces.zamah, "Find Apothecary Zamah in the Pools of Vision, below Spirit Rise."),
    accept(1086, tbPlaces.zamah),
    accept(1195, tbPlaces.zangen), accept(97538, tbPlaces.tah),
    action("train", nil, "Visit your class trainer in Thunder Bluff. Train spells for level", { level = 24 }),
  }
  return cat(withTrainers(fields, ucTrainers), withTrainers(home, tbOthers))
end)()

-- Southern Barrens (25-26): Camp Taurajo, the Field of Giants and Bael Modan.
local barrensSouth = (function()
  local function ba(name, x, y) return at(name, x, y, M.barrens) end
  local mangletooth = ba("Mangletooth", 44.55, 59.26)
  local logmar = ba("Grunt Logmar", 44.62, 59.27)
  local jorn = ba("Jorn Skyseer", 44.86, 59.14)
  local tatternack = ba("Tatternack Steelforge", 45.1, 57.68)
  local gann = ba("Gann Stonespire", 45.89, 77.0)
  local sulhasa = ba("Sulhasa", 47.93, 77.62)
  return {
    taxi("fly", tbPlaces.tal, "Camp Taurajo, The Barrens", "Fly from Thunder Bluff to Camp Taurajo."),
    accept(879, mangletooth, "Mangletooth, the caged quilboar, wants three Razorfen leaders dead. If he does not offer it, use Next."),
    accept(97250, logmar),
    withItem(5102, accept(884, ba("Owatanka", 46.4, 61.9), "If you kill Owatanka, a rare thunderhawk south-east of camp, use the tailspike he drops.")),
    -- CARRY: complete 868 Egg Hunt at the Field of Giants (accepted from Korran at the Crossroads before 22)
    --> objectiveAt(868, ba(nil, 42.91, 69.86), "Loot Silithid Eggs from the mounds in the Field of Giants south of camp. Kill a Silithid Harvester for the Digging Claw.", "12 Silithid Eggs", "Digging Claw"),
    withItem(5138, accept(897, ba("Silithid Harvester", 43.1, 70.1), "If the Silithid Harvester drops its head in the Field of Giants, use it.")),
    accept(843, gann, "Follow the road south to Gann Stonespire's camp above Bael Modan."),
    accept(98093, sulhasa, "Sulhasa is stuck up the tree beside the road. She wants the lizards and hyenas cleared."),
    along(objectiveAt(98093, ba(nil, 46.6, 76.2), "Kill Stormhide lizards and Hecklefang Stalkers around the tree and the road.", "7 Stormhides", "7 Hecklefang Stalkers"), 879),
    withItem(5103, accept(885, ba("Washte Pawne", 45.7, 77.9), "If you kill Washte Pawne, a rare wind serpent around here, use his feather.")),
    objectivePart(879, 1, ba("Kuz", 45.1, 80.1), "Kill Kuz at the quilboar camp south of Gann.", "Kuz's Skull"),
    objectivePart(879, 3, ba("Lok Orcbane", 40.1, 80.5), "Kill Lok Orcbane at the camp to the west.", "Lok's Skull"),
    objectivePart(879, 2, ba("Nak", 43.8, 83.3), "Kill Nak at the camp south-east of Lok.", "Nak's Skull"),
    objectiveAt(843, ba(nil, 47.22, 84.98), "Enter Bael Modan. Kill Excavators and Foremen around the pit. Prospector Khazgorm, at the north-east edge (48, 86), carries his journal.",
      "15 Bael'dun Excavators", "5 Bael'dun Foremen", "Khazgorm's Journal"),
    finish(843, gann), accept(846, gann),
    objectiveAt(846, ba(nil, 48.96, 84.36), "Kill Bael'dun Riflemen, Soldiers and Officers around the dig site for the three explosive parts.",
      "6 Nitroglycerin", "6 Wood Pulp", "6 Sodium Nitrate"),
    finish(846, gann), accept(849, gann),
    objectiveAt(849, ba(nil, 46.97, 85.63), "Destroy the flying machine on the west side of Bael Modan.", "Bael Modan Flying Machine destroyed"),
    finish(849, gann),
    objectiveAt(98093, ba(nil, 47.49, 80.54), "Finish the lizards and hyenas near the road.", "7 Stormhides", "7 Hecklefang Stalkers"),
    finish(98093, sulhasa),
    objectiveAt(97250, ba(nil, 49.08, 76.97), "Ride east toward the Dustwallow Marsh border and kill the Alliance soldiers and pillagers camped there.", "Encroaching Soldiers", "Outraged Pillagers"),
    action("goto", jorn, "Ride north back to Camp Taurajo."),
    finish(884, jorn), finish(885, jorn), finish(897, jorn),
    finish(97250, logmar),
    finish(879, mangletooth), accept(906, mangletooth),
    accept(6382, jorn, "Jorn Skyseer sends hunters to Senani Thunderheart in Ashenvale. Take it for the Ashenvale hunt quests."),
    accept(1130, jorn, "Jorn also has word for Melor Stonehoof in Thunder Bluff. Keep it for your next visit there."),
    accept(893, tatternack, "Tatternack wants three Razormane weapons. If you kept them from the northern Barrens, hand them in now."),
    objectiveAt(893, tatternack, "Hand Tatternack the Razormane Backstabber, the Charred Razormane Wand and the Razormane War Shield."),
    finish(893, tatternack), accept(1153, tatternack, "Tatternack's next job is in Thousand Needles. Take it now."),
    taxi("fly", ba("Omusa Thunderhorn", 44.45, 59.16), "Crossroads, The Barrens", "Fly to the Crossroads."),
    finish(906, ba("Thork", 51.5, 30.87)),
    -- CARRY: turnin 868 Egg Hunt at Korran (accepted at the Crossroads before 22)
    --> finish(868, ba("Korran", 51.07, 29.63)),
  }
end)()

-- Stonetalon Mountains (25-27): Sun Rock Retreat, Windshear Crag, Stonetalon Peak and the Charred Vale.
local stonetalon = (function()
  local function st(name, x, y) return at(name, x, y, M.stonetalon) end
  local tharm = st("Tharm", 45.13, 59.85)
  local braelyn = st("Braelyn Firehand", 45.94, 60.42)
  local maggran = st("Maggran Earthbinder", 47.2, 61.16)
  local tammra = st("Tammra Windfield", 47.46, 58.38)
  local tsunaman = st("Tsunaman", 47.36, 64.25)
  local ziz = st("Ziz Fizziks", 58.99, 62.6)
  local jinzil = st("Witch Doctor Jin'Zil", 74.54, 97.94)
  local seereth = at("Seereth Stonebreak", 35.26, 27.88, M.barrens)
  return {
    taxi("fly", at("Devrak", 51.5, 30.34, M.barrens), "Sun Rock Retreat, Stonetalon Mountains",
      "Fly to Sun Rock Retreat. Without that flight, ride west from the Crossroads into Stonetalon and take the road north through Windshear Crag."),
    taxi("getfp", tharm, "Sun Rock Retreat, Stonetalon Mountains", "Learn the Sun Rock flight path from Tharm if you do not have it."),
    accept(1087, braelyn),
    accept(6282, maggran), accept(86576, maggran),
    accept(6284, st("Wanted Poster: Besseleth", 59.06, 75.71), "Ride south-east on the road to the Webwinder Path and read the wanted poster for Besseleth."),
    objectiveAt(6284, st("Besseleth", 53.1, 72.5), "Kill Besseleth, a level 21 spider in the webbed hollow to the west, and take her fang.", "Besseleth's Fang"),
    -- CARRY: turnin 1092 Gerenzo's Orders at Ziz Fizziks (accepted from Piznik before 22)
    --> finish(1092, ziz, "Ride north-east to Ziz Fizziks on the road below Windshear Crag."),
    -- CARRY: complete 1068 Shredding Machines (XT:9), accepted from Seereth before 22
    --> objectivePart(1068, 2, st("XT:9", 64.1, 56.6), "Kill the shredder XT:9 patrolling the logging road south of the crag.", "XT:9 slain"),
    withItem(5638, objectiveAt(1086, st(nil, 66.47, 45.45), "Climb into Windshear Crag to the Venture Co. sky port. Use the Toxic Fogger under or on top of the platform.")),
    -- CARRY: complete 1068 Shredding Machines (XT:4)
    --> objectivePart(1068, 1, st("XT:4", 64.1, 46.4), "Kill XT:4, which patrols the north side of the river.", "XT:4 slain"),
    -- CARRY: complete 1096 Gerenzo Wrenchwhistle (accepted from Ziz before 22)
    --> objectiveAt(1096, st("Gerenzo Wrenchwhistle", 64.5, 40.2), "Climb to the top of the tower at the north end of the crag and kill Gerenzo for his mechanical arm.", "Gerenzo's Mechanical Arm"),
    -- CARRY: turnin 1096 Gerenzo Wrenchwhistle at Ziz Fizziks
    --> finish(1096, ziz),
    finish(6284, maggran, "Ride back west to Sun Rock Retreat."),
    objectiveAt(97538, st(nil, 47.27, 38.32), "Follow the road north to Mirkfallon Lake and loot Dried Mirkweed from the water.", "30 Mirkweed Pods"),
    -- CARRY: complete 6301 Cycle of Rebirth (accepted from Tammra before 22)
    --> objectiveAt(6301, st(nil, 45.95, 40.72), "Loot Gaea Seeds on the ground around the lake.", "10 Gaea Seeds"),
    -- CARRY: complete 1058 Jin'Zil's Forest Magic (accepted from Jin'Zil before 22), four parts on Stonetalon Peak
    --> objectivePart(1058, 3, st(nil, 44.51, 20.92), "Kill Antlered Coursers on the way north for their eyes.", "30 Courser Eyes"),
    --> objectivePart(1058, 1, st(nil, 35.3, 16.7), "Kill Sap Beasts in the woods below the peak.", "5 Stonetalon Sap"),
    --> objectivePart(1058, 2, st(nil, 32.24, 10.76), "Kill Twilight Runners near the top of the peak.", "5 Twilight Whiskers"),
    --> objectivePart(1058, 4, st(nil, 33.96, 11.82), "Kill Fey Dragons and Wily Fey Dragons until one drops a scale.", "Fey Dragon Scale"),
    objectiveAt(1087, st(nil, 36.5, 12.6), "Climb Stonetalon Peak. Kill Sons and Daughters of Cenarius and Cenarion Botanists among the trees at the top.",
      "4 Sons of Cenarius", "4 Daughters of Cenarius", "4 Cenarion Botanists"),
    action("goto", st(nil, 32.7, 63.3), "Ride back south past Sun Rock Retreat and west into the Charred Vale."),
    along(objectiveAt(6282, st(nil, 32.7, 63.3), "In the Charred Vale, kill the four Bloodfury harpy types and loot Glittering Sunstones.",
      "7 Bloodfury Harpies", "7 Bloodfury Ambushers", "7 Bloodfury Slayers", "7 Bloodfury Roguefeathers"), 86576),
    along(objectiveAt(86576, st(nil, 31.4, 59.0), "Finish the Glittering Sunstones on the harpies.", "15 Glittering Sunstones"), 6282),
    action("goto", braelyn, "Ride east back to Sun Rock Retreat."),
    finish(1087, braelyn), accept(1088, braelyn),
    finish(6282, maggran), accept(6283, maggran),
    -- CARRY: turnin 6301 Cycle of Rebirth at Tammra Windfield
    --> finish(6301, tammra),
    accept(6381, tammra, "Tammra wants the enchanted seeds planted in the Charred Vale. If you skipped her seed quest, use Next."),
    objectiveAt(6283, st("Bloodfury Ripper", 30.8, 61.9), "Return to the Charred Vale and kill Bloodfury Ripper on the harpy ridge.", "Bloodfury Ripper's Remains"),
    objectiveAt(6381, st(nil, 31.9, 64.25), "Plant the seeds in the Gaea Dirt Mounds across the burned valley floor.", "Gaea seed planted"),
    -- CARRY: complete 6393 Elemental War (accepted from Tsunaman before 22)
    --> objectiveAt(6393, st(nil, 28.8, 65.1), "Kill Burning Ravagers and fire spirits in the vale for Incendrites.", "10 Incendrites"),
    finish(86576, st("Mor'rogal", 47.22, 64.04), "Return to Sun Rock and give the sunstones to Mor'rogal."),
    -- CARRY: turnin 6393 Elemental War at Tsunaman
    --> finish(6393, tsunaman),
    finish(6283, maggran), accept(5881, maggran),
    finish(6381, tammra),
    -- CARRY: turnin 1058 Jin'Zil's Forest Magic at Witch Doctor Jin'Zil in Malaka'jin
    --> finish(1058, jinzil, "Ride south-east down the road to Malaka'jin and bring Jin'Zil his reagents."),
    -- CARRY: turnin 1068 Shredding Machines at Seereth Stonebreak on the Barrens border
    --> finish(1068, seereth),
  }
end)()

-- Ashenvale (26-28): Splintertree Post, Mystral Lake, Thistlefur, Raynewood and Zoram'gar.
local ashenvale = (function()
  local function av(name, x, y) return at(name, x, y, M.ashenvale) end
  local torek = av("Torek", 68.34, 75.3)
  local kuraybin = av("Kuray'bin", 71.11, 68.12)
  local senani = av("Senani Thunderheart", 73.78, 61.46)
  local mastok = av("Mastok Wrilehiss", 73.67, 60.0)
  local pixel = av("Pixel", 73.06, 61.48)
  local vhulgra = av("Vhulgra", 73.18, 61.59)
  local jeneu = av("Je'neu Sancrea", 11.56, 34.29)
  local karang = av("Karang Amakkar", 11.9, 34.54)
  local mitsuwa = av("Mitsuwa", 11.65, 34.85)
  return {
    action("goto", torek, "Fly to the Crossroads and ride north on the road past Mor'shan Rampart into Ashenvale. Torek waits where the road meets the forest."),
    accept(6544, torek),
    objectiveAt(6544, av(nil, 64.81, 75.34), "Follow Torek and his grunts west into Silverwing Outpost. Help them kill the sentinels and Duriel Moonfire, and keep Torek alive."),
    accept(6503, kuraybin, "Kuray'bin stands by the road north-east of Torek."),
    finish(6544, av("Ertog Ragetusk", 73.03, 62.47), "Ride north to Splintertree Post and report to Ertog Ragetusk."),
    finish(6382, senani), accept(6383, senani), finish(6383, senani),
    action("sethearth", av("Innkeeper Kaylisk", 74.0, 60.64), "Set your hearthstone at Splintertree Post.", { bind = "Splintertree Post" }),
    accept(25, mastok), accept(6441, pixel),
    taxi("getfp", vhulgra, "Splintertree Post, Ashenvale", "Learn the Splintertree flight path from Vhulgra."),
    objectiveAt(6503, av(nil, 73.5, 72.6), "Kill Ashenvale Outrunners in the woods south-east of the post. They stealth, so watch for ambushes.", "9 Ashenvale Outrunners"),
    withItem(16305, accept(2, av("Sharptalon", 75.0, 70.1), "If you kill Sharptalon, the level 31 hippogryph circling here, use his claw. Skip him if he is too strong.")),
    action("goto", av(nil, 47.4, 69.0), "Ride west along the road to Mystral Lake."),
    objectivePart(25, 1, av(nil, 47.4, 69.0), "Kill Befouled Water Elementals around Mystral Lake.", "12 Befouled Water Elementals"),
    objectivePart(25, 2, av(nil, 48.93, 69.56), "Swim to the gazebo in the middle of the lake and step onto it."),
    withItem(16408, accept(1918, av("Tideress", 45.9, 70.6), "Kill Tideress, the elemental at the west end of the lake, and use the Befouled Water Globe she drops.")),
    withItem(16303, accept(23, av("Ursangous", 43.78, 68.86), "Find Ursangous, a level 25 bear roaming west of the lake. Use his paw to start the quest.")),
    action("goto", av("Ruul Snowhoof", 41.53, 34.49), "Ride north to Thistlefur Village and the cave of Thistlefur Hold. Give Astranaar, the Alliance town at 36, 50, a wide berth."),
    -- CARRY: complete 6462 Troll Charm (accepted at Zoram'gar before 22)
    --> objectiveAt(6462, av(nil, 40.39, 33.22), "Loot Troll Chests on the floor of Thistlefur Hold for Troll Charms.", "8 Troll Charms"),
    accept(6482, av("Ruul Snowhoof", 41.53, 34.49), "Talk to Ruul Snowhoof, caged at the back of the cave. This starts an escort."),
    objectiveAt(6482, av(nil, 38.73, 36.86), "Escort Ruul out of the hold and through the village. Kill the furbolgs that attack him."),
    -- CARRY: complete 216 Between a Rock and a Thistlefur (accepted at Zoram'gar before 22)
    --> objectiveAt(216, av(nil, 36.2, 36.0), "Kill Thistlefur Avengers and Shamans in the village outside the hold.", "8 Thistlefur Avengers", "8 Thistlefur Shaman"),
    action("goto", av(nil, 57.5, 56.0), "Ride east along the main road toward Raynewood Retreat."),
    withItem(16304, accept(24, av("Shadumbra", 57.5, 56.0), "Find Shadumbra, a level 28 panther near Raynewood, and use her head to start the quest.")),
    objectiveAt(1088, av("Keeper Ordanus", 62.0, 51.4), "Climb the Raynewood Retreat building to the top and kill Keeper Ordanus. Two vindicators guard him and can summon treants.",
      "Ordanus' Head"),
    objectiveAt(6441, av(nil, 67.3, 53.2), "Kill Felmusk satyrs in the woods east of Raynewood for their horns.", "16 Satyr Horns"),
    withItem(5867, objectiveAt(1195, av(nil, 60.2, 72.9), "Ride south-west to the moonwell (60, 73) and use the Etched Phial at the water.", "Filled Etched Phial")),
    finish(6503, kuraybin),
    finish(6441, pixel, "Ride north to Splintertree Post."),
    finish(25, mastok), finish(1918, mastok), accept(824, mastok),
    finish(6482, av("Yama Snowhoof", 74.11, 60.92)),
    finish(23, senani), finish(24, senani), finish(2, senani),
    accept(247, senani), finish(247, senani),
    taxi("fly", vhulgra, "Zoram'gar Outpost, Ashenvale", "Fly to Zoram'gar Outpost on the west coast."),
    -- CARRY: turnin 216 Between a Rock and a Thistlefur at Karang Amakkar
    --> finish(216, karang),
    -- CARRY: turnin 6462 Troll Charm at Mitsuwa
    --> finish(6462, mitsuwa),
    finish(824, jeneu),
    forDungeon(accept(6563, jeneu, "Je'neu wants Sapphires of Aku'Mai from the caves of Blackfathom Deeps."), "dungeon-blackfathom-deeps"),
    forDungeon(accept(6921, jeneu, "Je'neu also wants a Fathom Core from inside Blackfathom Deeps."), "dungeon-blackfathom-deeps"),
    taxi("fly", av("Andruk", 12.24, 33.8), "Sun Rock Retreat, Stonetalon Mountains", "Fly to Sun Rock Retreat."),
    finish(1088, at("Braelyn Firehand", 45.94, 60.42, M.stonetalon)),
  }
end)()

-- Thousand Needles (28-30): Thunder Bluff, Bael Modan, Freewind Post and the western mesas.
local needles = (function()
  local function tn(name, x, y) return at(name, x, y, M.needles) end
  local longhorn = tn("Cliffwatcher Longhorn", 45.67, 50.74)
  local rau = tn("Rau Cliffrunner", 46.14, 51.71)
  local jandia = tn("Jandia", 46.21, 51.51)
  local hagar = tn("Hagar Lightninghoof", 44.64, 50.29)
  local elu = tn("Elu", 44.93, 48.92)
  local nyse = tn("Nyse", 45.14, 49.11)
  local dorn = tn("Dorn Plainstalker", 53.95, 41.49)
  local motega = tn("Motega Firemane", 21.54, 32.35)
  local kanati = tn("Kanati Greycloud", 21.25, 32.06)
  local wizlo = tn("Wizlo Bearingshiner", 21.43, 32.55)
  local feegly = at("Feegly the Exiled", 48.97, 86.31, M.barrens)
  local tatternack = at("Tatternack Steelforge", 45.1, 57.68, M.barrens)
  local town = {
    taxi("fly", at("Tharm", 45.13, 59.85, M.stonetalon), "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
    finish(1195, tbPlaces.zangen), accept(1196, tbPlaces.zangen),
    finish(97538, tbPlaces.tah),
    finish(1086, tbPlaces.zamah),
    finish(1130, tbPlaces.melor, "Find Melor Stonehoof on Hunter Rise."),
    accept(1131, tbPlaces.melor),
    action("train", nil, "Visit your class trainer in Thunder Bluff. Train spells for level", { level = 28 }),
  }
  local west = {
    taxi("fly", tbPlaces.tal, "Camp Taurajo, The Barrens", "Fly to Camp Taurajo."),
    accept(857, feegly, "Ride south to Bael Modan. Feegly the Exiled hides at the east edge of the pit."),
    objectiveAt(857, at(nil, 49.13, 84.25, M.barrens), "Find the Tear of the Moons in the dig site just north of Feegly and loot it.", "Tear of the Moons"),
    finish(857, feegly),
    action("goto", at(nil, 44.13, 91.44, M.barrens), "Follow the road south to the Great Lift and ride it down into Thousand Needles."),
    finish(5881, tn("Grish Longrunner", 31.86, 21.66)),
    accept(4542, tn("Brave Moonhorn", 32.24, 22.17)),
    withItem(12564, accept(4881, tn("Galak Messenger", 39.4, 33.1), "If you kill the Galak Messenger, a centaur who patrols the road, use the note he drops.")),
    taxi("getfp", nyse, "Freewind Post, Thousand Needles", "Follow the road south-east to Freewind Post on its mesa. Learn the flight path from Nyse."),
    action("sethearth", tn("Innkeeper Abeqwa", 46.07, 51.5), "Set your hearthstone at Freewind Post.", { bind = "Freewind Post" }),
    finish(4542, longhorn), accept(4841, longhorn),
    accept(5147, tn("Wanted Poster - Arnak Grimtotem", 46.0, 50.86), "Read the wanted poster for Arnak Grimtotem beside Longhorn."),
    finish(1196, rau), accept(1197, rau),
    accept(98069, jandia), accept(98070, jandia),
    accept(4821, hagar), accept(4767, elu),
    accept(1149, dorn, "Leave Freewind and ride north-east to Dorn Plainstalker on his wooden platform."),
    objectiveAt(1149, tn(nil, 26.6, 34.2), "Wait for Dorn to send you to the planks on a needle. Jump from the very end of the plank: it teleports you down safely."),
    finish(1149, dorn), accept(1150, dorn),
    along(objectiveAt(4821, tn(nil, 56.36, 50.39), "Search the canyon east of Freewind for the Alien Egg.", "Alien Egg"), 1153),
    objectiveAt(1153, tn(nil, 60.3, 57.7), "Kill Gravelsnout Diggers and Surveyors at the kobold camp to the south-east until one drops the ore sample.", "Unrefined Ore Sample"),
    along(objectiveAt(4841, tn(nil, 43.12, 36.86), "Kill Galak centaur in the camps north-west of Freewind.", "12 Galak Scouts", "10 Galak Wranglers", "6 Galak Windchasers"), 1197),
    objectiveAt(1197, tn(nil, 42.0, 31.8), "Kill Galak Flame Guards at Splithoof Hold until one drops the Cloven Hoof.", "Cloven Hoof"),
    finish(4841, longhorn, "Return to Freewind Post."), accept(5064, longhorn),
    finish(1197, rau),
    finish(4821, hagar), accept(4865, hagar),
    along(objectiveAt(98070, tn(nil, 26.4, 54.3), "Ride west to the Screeching Canyon. Kill the three harpy types; Windcallers stun and harpies silence, so pull one at a time.",
      "5 Screeching Harpies", "5 Screeching Roguefeathers", "5 Screeching Windcallers"), 98069, 1150),
    objectiveAt(98069, tn(nil, 26.91, 52.26), "Loot the Stolen Freewind Supplies from the floor of Roguefeather Den.", "8 Stolen Freewind Supplies"),
    objectiveAt(1150, tn(nil, 25.9, 55.23), "Kill Grenka Bloodscreech, the level 31 harpy leader in the canyon, for her claw.", "Grenka's Claw"),
    objectiveAt(4767, tn(nil, 13.91, 39.11), "Ride north-west to Highperch and loot Highperch Wyvern Eggs from the nests.", "10 Highperch Wyvern Eggs"),
    accept(4770, tn("Pao'ka Swiftmountain", 17.89, 40.57), "Talk to Pao'ka Swiftmountain on Highperch. This starts an escort."),
    objectiveAt(4770, tn(nil, 15.17, 32.66), "Escort Pao'ka down from Highperch. Wyverns attack along the way."),
    objectiveAt(1131, tn("Steelsnap", 17.6, 19.5), "Ride north to Steelsnap, a level 30 hyena with two companions. Pull him away from them if you can.", "Steelsnap's Rib"),
    finish(4881, kanati, "Go to Whitereach Post and warn Kanati Greycloud."),
    accept(4966, kanati),
    objectiveAt(4966, kanati, "Defend Kanati from the Galak assassins who attack."),
    finish(4966, kanati),
    finish(4865, motega), accept(5062, motega), finish(4770, motega),
    accept(5151, wizlo),
    objectiveAt(5151, tn("Enraged Panther", 22.8, 24.6), "Kill the Enraged Panther in its cage north of the post for the gizmo and the key.", "Hypercapacitor Gizmo"),
    finish(5151, wizlo),
    objectiveAt(5062, tn(nil, 36.58, 38.77), "Ride east and loot Incendia Agave around the hot springs. The elementals there stun and scald.", "10 Incendia Agave"),
    taxi("fly", nyse, "Thunder Bluff, Mulgore", "Return to Freewind Post and fly to Thunder Bluff."),
    finish(5062, tbPlaces.magatha, "Bring the agave to Magatha Grimtotem on Elder Rise."), accept(5088, tbPlaces.magatha),
    finish(1131, tbPlaces.melor),
    action("train", nil, "Visit your class trainer in Thunder Bluff. Train spells for level", { level = 30 }),
  }
  local pinnacle = {
    only(taxi("fly", tbPlaces.tal, "Camp Taurajo, The Barrens", "If you carry Tatternack's ore sample, fly to Camp Taurajo."), { optional = true }),
    finish(1153, tatternack),
    taxi("fly", tbPlaces.tal, "Freewind Post, Thousand Needles", "Fly to Freewind Post."),
    finish(4767, elu),
    finish(98069, jandia), finish(98070, jandia),
    finish(1150, dorn), accept(1151, dorn),
    objectiveAt(5088, tn("Arikara", 38.0, 35.3), "Ride north-west to Darkcloud Pinnacle. Kill Arikara, the serpent in the Grimtotem camp at its foot, and take her skin.",
      "Arikara Serpent Skin"),
    objectivePart(5064, 3, tn(nil, 39.2, 41.6), "Find the first secret note in the Grimtotem camp at the south-east foot of the pinnacle.", "Secret Note #3"),
    objectivePart(5064, 2, tn(nil, 33.8, 39.9), "Find the next note in the western camp.", "Secret Note #2"),
    objectivePart(5064, 1, tn(nil, 31.79, 32.58), "Find the last note at the north-west camp.", "Secret Note #1"),
    objectiveAt(5147, tn("Arnak Grimtotem", 38.1, 26.9), "Climb to the top of the pinnacle and kill Arnak Grimtotem."),
    accept(4904, tn("Lakota Windsong", 37.95, 26.45), "Free Lakota Windsong beside Arnak. This starts an escort."),
    objectiveAt(4904, tn(nil, 31.06, 36.89), "Escort Lakota down the pinnacle and out of the Grimtotem camps."),
    finish(5088, motega, "Ride west to Whitereach Post."),
    objectiveAt(1151, tn("Rok'Alim the Pounder", 25.8, 42.1), "Hunt Rok'Alim the Pounder, a level 30 elemental who patrols the north-west of the zone. Use Next if you cannot find him.",
      "Fragments of Rok'Alim"),
    action("hearth", nil, "Hearth to Freewind Post.", { bind = "Freewind Post" }),
    finish(5064, longhorn), finish(5147, longhorn),
    finish(4904, tn("Thalia Amberhide", 45.97, 51.61)),
    finish(1151, dorn),
  }
  return cat(withTrainers(town, tbTrainers), withTrainers(west, tbTrainers), pinnacle)
end)()

-- Shimmering Flats (alternate, 29-31): the racing teams' quests on the salt flats.
local flats = (function()
  local function tn(name, x, y) return at(name, x, y, M.needles) end
  local kravel = tn("Kravel Koalbeard", 77.79, 77.27)
  local fizzle = tn("Fizzle Brassbolts", 78.06, 77.13)
  local wizzle = tn("Wizzle Brassbolts", 78.14, 77.12)
  local pozzik = tn("Pozzik", 80.18, 75.88)
  return {
    action("goto", kravel, "Ride east from Freewind Post down to the Shimmering Flats and the racing camp in the middle."),
    accept(1110, kravel), accept(1104, fizzle), accept(1105, wizzle), accept(1176, pozzik),
    along(objectiveAt(1105, tn(nil, 74.6, 55.7), "Kill Sparkleshell Tortoises north of the camp for their shells. Loot Rocket Car Parts from the ground as you go.",
      "9 Hardened Tortoise Shells"), 1110, 1104),
    along(objectiveAt(1104, tn(nil, 75.1, 55.8), "Kill Scorpid Reavers in the same area for their venom.", "6 Salty Scorpid Venoms"), 1110, 1105),
    along(objectiveAt(1176, tn(nil, 78.7, 89.5), "Kill Salt Flats Vultures south of the camp for their bones. They are level 32 to 34.", "10 Hollow Vulture Bones"), 1110),
    objectiveAt(1110, tn(nil, 77.65, 87.34), "Finish collecting Rocket Car Parts from the wreckage scattered across the flats.", "30 Rocket Car Parts"),
    finish(1105, wizzle), finish(1104, fizzle), finish(1176, pozzik), finish(1110, kravel),
  }
end)()

-- Arrow shortcuts for legs between maps. Files that load earlier keep their own entries.
road(M.durotar, M.tirisfal, at(nil, 50.8, 13.8, M.durotar), "Take the zeppelin to Tirisfal Glades")
road(M.orgrimmar, M.tirisfal, at(nil, 50.8, 13.8, M.durotar), "Leave Orgrimmar for the zeppelin to Tirisfal Glades")
road(M.tirisfal, M.durotar, at(nil, 60.8, 58.7, M.tirisfal), "Take the zeppelin to Orgrimmar")
road(M.tirisfal, M.orgrimmar, at(nil, 60.8, 58.7, M.tirisfal), "Take the zeppelin to Orgrimmar")
road(M.tirisfal, M.silverpine, at(nil, 53.2, 75.8, M.tirisfal), "Follow the road south into Silverpine Forest")
road(M.barrens, M.ashenvale, at(nil, 48.12, 5.42, M.barrens), "Ride north past Mor'shan Rampart into Ashenvale")
road(M.stonetalon, M.ashenvale, at(nil, 78.3, 42.5, M.stonetalon), "Walk through Talondeep Path to Ashenvale")
road(M.barrens, M.needles, at(nil, 44.13, 91.44, M.barrens), "Ride the Great Lift down into Thousand Needles")

local sources = {
  "https://bindonforever.com/zones/silverpine-forest",
  "https://bindonforever.com/zones/hillsbrad-foothills",
  "https://bindonforever.com/zones/the-barrens",
  "https://bindonforever.com/zones/stonetalon-mountains",
  "https://bindonforever.com/zones/ashenvale",
  "https://bindonforever.com/zones/thousand-needles",
  "https://www.warcrafttavern.com/forever/guides/leveling",
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
}

for _, section in ipairs({
  { id = "sepulcher", title = "Silverpine: The Sepulcher", zone = M.silverpine, levels = { 22, 23 }, steps = sepulcher },
  { id = "hillsbrad", title = "Hillsbrad Foothills", zone = M.hillsbrad, levels = { 23, 25 }, steps = hillsbrad },
  { id = "barrens-south", title = "Southern Barrens", zone = M.barrens, levels = { 25, 26 }, steps = barrensSouth },
  { id = "stonetalon-sunrock", title = "Stonetalon: Sun Rock", zone = M.stonetalon, levels = { 25, 27 }, steps = stonetalon },
  { id = "ashenvale-splintertree", title = "Ashenvale: Splintertree", zone = M.ashenvale, levels = { 26, 28 }, steps = ashenvale },
  { id = "thousand-needles", title = "Thousand Needles", zone = M.needles, levels = { 28, 30 }, steps = needles,
    suggest = { "shimmering-flats" } },
  { id = "shimmering-flats", title = "Shimmering Flats", zone = M.needles, levels = { 29, 31 }, steps = flats,
    alternate = true },
}) do
  section.verified, section.sources = false, sources
  route.sections[#route.sections + 1] = section
end
