-- Horde route: The Barrens, with the Stonetalon and Ashenvale trips (12-22). Every Horde race joins
-- here: Orcs, Trolls and Undead walk in from Far Watch Post, Tauren from Camp Taurajo.
-- Source notes: tools/audits/2026-11-10-horde-barrens.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local M = B.maps
local q, quest, at, accept, finish = B.q, B.quest, B.at, B.accept, B.finish
local objectiveAt, action, taxi, withItem, along = B.objectiveAt, B.action, B.taxi, B.withItem, B.along

local function objectivePart(id, index, place, text, label)
  local step = objectiveAt(id, place, text, label)
  step.objectiveIndex = index
  return step
end
local function only(step, rules) return B.only(step, rules) end
local function dungeon(step, id) return B.forDungeon(step, "dungeon-" .. id) end
local function ba(name, x, y) return at(name, x, y, M.barrens) end
local function og(name, x, y) return at(name, x, y, M.orgrimmar) end
local function tb(name, x, y) return at(name, x, y, M.thunderBluff) end
local function st(name, x, y) return at(name, x, y, M.stonetalon) end
local function av(name, x, y) return at(name, x, y, M.ashenvale) end

local TAUREN = { race = "TAUREN" }

-- Places shared by several sections.
local p = {
  sergra = ba("Sergra Darkthorn", 52.23, 31.01), thork = ba("Thork", 51.5, 30.87),
  devrak = ba("Devrak", 51.5, 30.34), helbrim = ba("Apothecary Helbrim", 51.44, 30.15),
  gazrog = ba("Gazrog", 51.93, 30.32), boorand = ba("Innkeeper Boorand Plainswind", 51.99, 29.89),
  zargh = ba("Zargh", 52.62, 29.84), darsok = ba("Darsok Swiftdagger", 51.62, 30.9),
  tonga = ba("Tonga Runetotem", 52.26, 31.93), mankrik = ba("Mankrik", 51.95, 31.58),
  gurak = ba("Gur'ak", 52.65, 29.06), jahan = ba("Jahan Hawkwing", 51.21, 29.05),
  korran = ba("Korran", 51.07, 29.63), regthar = ba("Regthar Deathgate", 45.34, 28.41),
  wrenix = ba("Wrenix the Wretched", 63.07, 36.32), gazlowe = ba("Gazlowe", 62.68, 36.23),
  bragok = ba("Bragok", 63.09, 37.16), sputtervalve = ba("Sputtervalve", 62.98, 37.22),
  poster = ba("WANTED poster", 62.59, 37.47), drohn = ba("Brewmaster Drohn", 62.26, 38.39),
  dizzywig = ba("Wharfmaster Dizzywig", 63.35, 38.45), mebok = ba("Mebok Mizzyrix", 62.37, 37.62),
  bigglefuzz = ba("Crane Operator Bigglefuzz", 63.09, 37.61),
  vrang = ba("Vrang Wildgore", 43.8, 12.21), walton = ba("Walton", 42.02, 11.45),
  console = ba("Control Console", 52.4, 11.65), shredder = ba("Wizzlecrank's Shredder", 56.52, 7.45),
  byula = ba("Innkeeper Byula", 45.58, 59.04), jorn = ba("Jorn Skyseer", 44.86, 59.14),
  mangletooth = ba("Mangletooth", 44.55, 59.26), omusa = ba("Omusa Thunderhorn", 44.45, 59.16),
  seereth = ba("Seereth Stonebreak", 35.26, 27.88), makaba = ba("Makaba Flathoof", 35.19, 27.76),
  gryshka = og("Innkeeper Gryshka", 54.1, 68.41), doras = og("Doras", 45.12, 63.89),
  zor = og("Zor Lonetree", 38.93, 38.4), neeru = og("Neeru Fireblade", 49.47, 50.59),
  ahanu = tb("Ahanu", 45.77, 55.84), tal = tb("Tal", 47, 49.83), pala = tb("Innkeeper Pala", 45.83, 64.74),
  clarice = tb("Clarice Foster", 28.87, 26.4), zamah = tb("Apothecary Zamah", 22.81, 20.89),
  hamuul = tb("Arch Druid Hamuul Runetotem", 78.62, 28.56), nara = tb("Nara Wildmane", 75.65, 31.61),
  magatha = tb("Magatha Grimtotem", 69.85, 30.91),
  kaya = st("Kaya Flathoof", 73.48, 85.59), xenzilla = st("Xen'Zilla", 71.25, 95.02),
  jinzil = st("Witch Doctor Jin'Zil", 74.54, 97.94), tharm = st("Tharm", 45.13, 59.85),
  maggran = st("Maggran Earthbinder", 47.2, 61.16), ziz = st("Ziz Fizziks", 58.99, 62.6),
  tsunaman = st("Tsunaman", 47.36, 64.25), tammra = st("Tammra Windfield", 47.46, 58.38),
  piznik = st("Piznik", 71.87, 60), talondeep = st(nil, 78.2, 42.3),
  vaxug = av("Va'xug Firefure", 40.46, 61.42), andruk = av("Andruk", 12.24, 33.8),
  jeneu = av("Je'neu Sancrea", 11.56, 34.29), karang = av("Karang Amakkar", 11.9, 34.54),
  mitsuwa = av("Mitsuwa", 11.65, 34.85), marukai = av("Marukai", 11.69, 34.91),
  muglash = av("Muglash", 12.06, 34.63), runner = av("Warsong Runner", 12.22, 34.22),
}
local crossroadsBind = { bind = "The Crossroads" }
local taurajoBind = { bind = "Camp Taurajo" }
local bluffBind = { bind = "Thunder Bluff" }

-- Class trainers in the two capitals. Druids and paladins train in Thunder Bluff only, warlocks in
-- Orgrimmar only.
local orgrimmarTrainers = {
  { "WARRIOR", og("Grezz Ragefist", 79.91, 31.36) }, { "HUNTER", og("Ormak Grimshot", 66.05, 18.52) },
  { "ROGUE", og("Ormok", 43.9, 54.65) }, { "PRIEST", og("Ur'kyo", 35.59, 87.8) },
  { "SHAMAN", og("Kardris Dreamseeker", 38.82, 36.41) }, { "MAGE", og("Pephredo", 38.36, 85.54) },
  { "WARLOCK", og("Mirket", 48.62, 46.95) },
}
local bluffTrainers = {
  { "WARRIOR", tb("Torm Ragetotem", 57.27, 87.34) }, { "HUNTER", tb("Urek Thunderhorn", 59.13, 86.91) },
  { "ROGUE", tb("Boarton Shadetotem", 39.49, 65.88) }, { "PRIEST", tb("Miles Welsh", 25.31, 15.24) },
  { "SHAMAN", tb("Tigor Skychaser", 23.64, 18.74) }, { "MAGE", tb("Archmage Shymm", 22.74, 14.48) },
  { "PALADIN", tb("Alodan the Hopeful", 25.18, 14.4) }, { "DRUID", tb("Turak Runetotem", 76.48, 27.25) },
}

-- Quest facts: QuestieDB Forever and the client reference. Prerequisites the client enforces.
q(844, "Plainstrider Menace", 12, 10)
q(845, "The Zhevra", 13, 10, 844)
q(903, "Prowlers of the Barrens", 15, 10, 845)
q(881, "Echeyakee", 16, 10, 903)
q(905, "The Angry Scytheclaws", 17, 10, 881)
q(3261, "Jorn Skyseer", 18, 10, 905)
q(882, "Ishamuhale", 19, 10, 3261)
q(907, "Enraged Thunder Lizards", 18, 10, 882)
q(913, "Cry of the Thunderhawk", 20, 10, 907)
q(870, "The Forgotten Pools", 13, 10)
q(877, "The Stagnant Oasis", 16, 10, 870)
q(880, "Altered Beings", 16, 10, 877)
q(1489, "Hamuul Runetotem", 16, 12, 880)
q(1490, "Nara Wildmane", 16, 12, 1489)
q(3301, "Mura Runetotem", 15, 10, 880)
q(871, "Disrupt the Attacks", 12, 9)
-- RestedXP takes this with Disrupt the Attacks; QuestieDB lists 871 as its prerequisite.
q(5041, "Supplies for the Crossroads", 14, 9)
q(872, "The Disruption Ends", 15, 9, 871)
q(1492, "Wharfmaster Dizzywig", 11, 9)
q(848, "Fungal Spores", 15, 10)
q(853, "Apothecary Zamah", 15, 10, 848)
q(869, "Raptor Thieves", 13, 9)
q(3281, "Stolen Silver", 18, 9, 869)
q(867, "Harpy Raiders", 15, 12)
q(875, "Harpy Lieutenants", 16, 12, 867)
q(876, "Serena Bloodfeather", 20, 12, 875)
q(1060, "Letter to Jin'Zil", 20, 15, 876)
q(819, "Chen's Empty Keg", 15, 11)
q(821, "Chen's Empty Keg", 15, 11, 819)
q(97253, "Parts and Pieces", 15, nil, nil, true)
q(887, "Southsea Freebooters", 14, 9)
q(895, "WANTED: Baron Longshore", 16, 11)
q(890, "The Missing Shipment", 14, 9, 887)
q(892, "The Missing Shipment", 14, 9, 890)
q(888, "Stolen Booty", 16, 9, 892)
q(896, "Miner's Fortune", 18, 13)
q(894, "Samophlange", 14, 10)
q(900, "Samophlange", 14, 10, 894)
q(901, "Samophlange", 14, 10, 900)
q(902, "Samophlange", 16, 10, 901)
q(858, "Ignition", 18, 13)
q(863, "The Escape", 18, 13, 858)
q(1483, "Ziz Fizziks", 21, 16)
q(1093, "Super Reaper 6000", 21, 16)
B.breadcrumb(1483, 1093)
q(1094, "Further Instructions", 21, 16, 1093)
q(1095, "Further Instructions", 27, 16, 1094)
q(850, "Kolkar Leaders", 16, 11)
q(855, "Centaur Bracers", 14, 9)
q(851, "Verog the Dervish", 18, 11, 850)
q(852, "Hezrul Bloodmark", 19, 11, 851)
q(4021, "Counterattack!", 20, 11, 852)
q(95494, "Bruised Pride and Lion Hides", 18, nil, nil, true)
q(95507, "Vrang's Game", 18, nil, nil, true)
q(95495, "The Hermit Tanner", 18, nil, { 95494, 95507 }, true)
q(95621, "Trouble in the Valley", 18, nil, 95495, true)
q(95508, "Unwelcome Guests", 18, nil, 95621, true)
q(899, "Consumed by Hatred", 20, 14)
q(4921, "Lost in Battle", 20, 14)
q(95774, "Her Name Is Olgra", 20, nil, 4921, true)
q(865, "Raptor Horns", 18, 13)
q(1069, "Deepmoss Spider Eggs", 20, 15)
q(883, "Lakota'mani", 22, 10)
quest[883].startItem = 5099
q(884, "Owatanka", 24, 10)
quest[884].startItem = 5102
q(878, "Tribes at War", 21, 14)
q(5052, "Blood Shards of Agamaggan", 21, 14, 878)
q(868, "Egg Hunt", 22, 17)
q(92706, "WANTED: Bruuz", 20, nil, nil, true)
quest[92706].optional = true
q(1061, "The Spirits of Stonetalon", 17, 13)
q(1062, "Goblin Invaders", 19, 13)
q(1063, "The Elder Crone", 18, 13, 1062)
q(1064, "Forsaken Aid", 18, 13, 1063)
q(1065, "Journey to Tarren Mill", 18, 13, 1064)
q(1068, "Shredding Machines", 23, 13, 1062)
q(6548, "Avenge My Village", 18, 12)
q(6629, "Kill Grundig Darkcloud", 18, 12, 6548)
q(6523, "Protect Kaya", 18, 12)
q(6401, "Kaya's Alive", 18, 12, 6523)
q(6301, "Cycle of Rebirth", 23, 17)
q(6461, "Blood Feeders", 19, 13)
q(6284, "Arachnophobia", 21, 15)
q(1058, "Jin'Zil's Forest Magic", 26, 20)
q(6562, "Trouble in the Deeps", 22, 17)
q(1090, "Gerenzo's Orders", 22, 17)
q(1092, "Gerenzo's Orders", 22, 17, 1090)
q(98251, "Never Coming Back", 23, nil, nil, true)
q(98252, "A Void Path", 23, nil, 98251, true)
q(6442, "Naga at the Zoram Strand", 19, 14)
q(6641, "Vorsha the Lasher", 23, 20)
q(216, "Between a Rock and a Thistlefur", 24, 21)
q(264, "Until Death Do Us Part", 15, 12)
-- Flight-path errands for new Orcs/Trolls and Tauren.
q(6365, "Meats to Orgrimmar", 10, 10)
q(6384, "Ride to Orgrimmar", 10, 10, 6365)
q(6385, "Doras the Wind Rider Master", 10, 10, 6384)
q(6386, "Return to the Crossroads.", 10, 10, 6385)
for _, id in ipairs({ 6365, 6384, 6385, 6386 }) do quest[id].race = { "ORC", "TROLL" } end
q(6361, "A Bundle of Hides", 10, 10)
q(6362, "Ride to Thunder Bluff", 10, 10, 6361)
q(6363, "Tal the Wind Rider Master", 10, 10, 6362)
q(6364, "Return to Jahan", 10, 10, 6363)
for _, id in ipairs({ 6361, 6362, 6363, 6364 }) do quest[id].race = "TAUREN" end
-- Dungeon pickups (shown when the run is planned).
q(5761, "Slaying the Beast", 16, 9)
q(97003, "Chol'aruk the Ravener", 21, nil, nil, true)
q(959, "Trouble at the Docks", 18, 14)
q(1491, "Smart Drinks", 18, 13, 865)
q(962, "Serpentbloom", 18, 14)
B.breadcrumb(853, 962)
q(914, "Leaders of the Fang", 22, 11, 1490)
q(6563, "The Essence of Aku'Mai", 22, 17, 6562)

-- The Crossroads, 12-15: hub pickups, Thorn Hill, Ratchet and the coast.
local crossroads = (function()
  return {
    only(objectiveAt(924, ba("Altar of Fire", 47.97, 19.07),
      "Orcs and Trolls: with the Flawed Power Stone from Far Watch, follow the road west and climb Dreadmist Peak. Use the altar in the den at the top before the stone crumbles (30 minutes).",
      "Destroy the Demon Seed"), { race = { "ORC", "TROLL" } }),
    action("goto", p.sergra, "Make for the Crossroads, the walled town where the Barrens roads meet. From Far Watch Post follow the road west; from Camp Taurajo follow it north."),
    taxi("getfp", p.devrak, "Crossroads, The Barrens", "Learn the flight path from Devrak on the tower in the middle of town."),
    action("sethearth", p.boorand, "Bind your hearthstone with Innkeeper Boorand Plainswind at the inn.", crossroadsBind),
    -- Arrival turn-ins from the starting zones (accepted in the Durotar, Mulgore and Tirisfal files).
    only(finish(842, p.sergra), { race = { "ORC", "TROLL", "SCOURGE" } }),
    only(finish(860, p.sergra), TAUREN),
    only(finish(886, p.tonga), { race = "TAUREN", class = "DRUID" }),
    only(finish(854, p.thork), TAUREN),
    only(finish(1358, p.helbrim), { race = "SCOURGE" }),
    only(finish(98024, p.thork), { race = "SKYBORNE" }),
    accept(844, p.sergra, "Sergra Darkthorn stands at the south end of town, by the watch tower."),
    accept(870, p.tonga),
    accept(871, p.thork), accept(5041, p.thork),
    accept(1492, p.helbrim), accept(848, p.helbrim),
    accept(869, p.gazrog),
    accept(6365, p.zargh, "Zargh sells meat by the inn. He has a delivery that starts the flight-path errand."),
    finish(6365, p.devrak, "Hand the meat to Devrak at the flight tower."),
    accept(6384, p.devrak, "Keep this until the route visits Orgrimmar. Don't fly there now."),
    accept(6361, p.jahan, "Jahan Hawkwing has hides for Thunder Bluff. He stands on the north side of town."),
    finish(6361, p.devrak), accept(6362, p.devrak, "Keep this until you fly to Thunder Bluff after the Ratchet trip."),

    -- The Razormane camps north-east of town.
    along(objectiveAt(871, ba(nil, 53.6, 24.5),
      "Take the road north-east out of town. Razormane Water Seekers, Thornweavers and Hunters roam the grass and small camps along it. Kill raptors and plainstriders you pass.",
      "8 Razormane Water Seekers", "8 Razormane Thornweavers", "3 Razormane Hunters"), 869, 844),
    withItem(4926, accept(819, ba(nil, 55.7, 23.6),
      "Look for Chen's Empty Keg on the ground by the Razormane camps. Loot it and use it to start the quest.")),
    along(objectiveAt(844, ba(nil, 53.7, 29.2),
      "Head back toward town through the grassland and loot beaks from the plainstriders. Keep killing Sunscale raptors for their heads.",
      "7 Plainstrider Beaks"), 869),
    finish(844, p.sergra), accept(845, p.sergra),
    finish(871, p.thork), accept(872, p.thork),
    accept(867, p.darsok),

    -- Thorn Hill, then the coast road.
    along(objectivePart(872, 3, ba(nil, 58.7, 27.1),
      "Go east to Thorn Hill, the Razormane stronghold. Kreenig Snarlsnout wanders between the huts at its south end; kill him for his tusk.",
      "Kreenig Snarlsnout's Tusk"), 5041, 845),
    along(objectiveAt(872, ba(nil, 59.3, 24.7),
      "Work north through Thorn Hill, killing Geomancers and Defenders. Look for the supply crates as you go.",
      "8 Razormane Geomancers", "8 Razormane Defenders"), 5041, 845),
    objectiveAt(5041, ba(nil, 59.5, 24.6), "Search the huts on Thorn Hill for the Crossroads' supply crates.", "Crossroads' Supply Crates"),
    only(finish(924, ba("Ak'Zeloth", 62.34, 20.07), "Far Watch Post is just north-east of Thorn Hill. Tell Ak'Zeloth the seed is destroyed."),
      { race = { "ORC", "TROLL" } }),
    along(action("goto", p.gazlowe, "Take the road south-east to Ratchet on the coast. Kill Zhevra Runners for hooves on the way."), 845, 869),
    accept(97253, p.wrenix), accept(887, p.gazlowe),
    taxi("getfp", p.bragok, "Ratchet, The Barrens", "Learn the flight path from Bragok on the hill above the docks."),
    accept(894, p.sputtervalve),
    accept(895, p.poster, "Read the WANTED poster on the wall beside Sputtervalve."),
    finish(819, p.drohn, "Bring the keg to Brewmaster Drohn by the inn."),
    accept(821, p.drohn),

    -- The Southsea pirate camps south of Ratchet.
    along(objectiveAt(887, ba(nil, 64.2, 47.1),
      "Follow the shore south to the pirate camps. Kill Brigands and Cannoneers; Cannoneers hit hard at range, so pull them to cover.",
      "12 Southsea Brigands", "6 Southsea Cannoneers"), 895, 97253),
    along(objectiveAt(97253, ba(nil, 62.0, 45.1),
      "Search the upper camp on the hill for handfuls of complicated parts.", "5 Handfuls of Complicated Parts"), 887),
    objectiveAt(895, ba(nil, 62.6, 49.7),
      "Baron Longshore stands in the southern camp with guards around him. Clear them first, then kill him for his head.", "Baron Longshore's Head"),
    finish(887, p.gazlowe), finish(895, p.gazlowe), accept(890, p.gazlowe),
    finish(97253, p.wrenix),
    finish(1492, p.dizzywig, "Wharfmaster Dizzywig is on the docks."), finish(890, p.dizzywig),
    accept(892, p.dizzywig), accept(896, p.dizzywig),
    finish(892, p.gazlowe), accept(888, p.gazlowe, "Leave the stolen boots and lens for the next visit south of Ratchet."),
    taxi("fly", p.devrak, "Crossroads, The Barrens", "Fly back to the Crossroads from Bragok."),
    objectiveAt(845, ba(nil, 48.3, 36.8),
      "If you still need hooves, hunt Zhevra Runners in the grassland just south-west of town.", "4 Zhevra Hooves"),
    finish(5041, p.thork), finish(872, p.thork),
    finish(845, p.sergra), accept(903, p.sergra),

    -- Tauren: the flight errand to Thunder Bluff.
    only(taxi("fly", p.tal, "Thunder Bluff, Mulgore",
      "Fly to Thunder Bluff with the hides. Without the flight path, ride south to Camp Taurajo and west through Mulgore."), TAUREN),
    finish(6362, p.ahanu, "Ahanu stands on the central rise of Thunder Bluff."),
    only(finish(98435, p.hamuul, "Cross the rope bridges to Elder Rise and give Hamuul Runetotem Thunderhorn's report."), TAUREN),
    accept(6363, p.ahanu), finish(6363, p.tal, "Tal keeps the wind riders on the central rise."),
    accept(6364, p.tal),
    only(taxi("fly", p.devrak, "Crossroads, The Barrens", "Fly back to the Crossroads."), TAUREN),
    finish(6364, p.jahan),
  }
end)()

-- Northern Barrens, 15-16: the centaur and harpy camps, the Dry Hills and Orgrimmar.
local north = (function()
  return {
    accept(850, p.regthar, "Take the west road out of town to Regthar Deathgate's camp."),
    accept(855, p.regthar),
    along(objectiveAt(870, ba(nil, 45.1, 22.5),
      "Go north to the Forgotten Pools and swim through the water until the quest updates. Pick up Fungal Spores from the mushrooms around the pools.",
      "Explore the waters of the Forgotten Pools"), 848, 855),
    objectiveAt(848, ba(nil, 45.1, 22.5), "Collect the rest of the Fungal Spores around the Forgotten Pools.", "4 Fungal Spores"),
    along(objectiveAt(850, ba(nil, 42.8, 23.5),
      "Barak Kodobane leads the Kolkar camp west of the pools. Fight through the centaurs, loot their bracers, and take his head.",
      "Kodobane's Head"), 855),
    finish(850, p.regthar), accept(851, p.regthar, "Leave Verog for the trip south."),
    along(objectiveAt(903, ba(nil, 41.6, 23.4),
      "Hunt Savannah Prowlers on the plains north-west of Regthar. Their tusks also fill Chen's keg.",
      "7 Prowler Claws"), 821, 867),
    along(objectiveAt(867, ba(nil, 41.8, 14.8),
      "Go north to the Witchwing harpy roosts and loot talons from the harpies. Pull them one at a time.",
      "8 Witchwing Talons"), 903),

    -- The Dry Hills: Vrang's hunting camp and the Kul Tiran valley.
    accept(95494, p.vrang, "Vrang Wildgore camps in the Dry Hills, just north-east of the harpies."),
    accept(95507, p.vrang),
    along(objectiveAt(95494, ba(nil, 44.1, 16.7),
      "Hunt the Savannah Patriarchs and Matriarchs in the hills south of Vrang for their hides.", "6 Savannah Lion Hides"), 95507, 821),
    objectiveAt(95507, ba(nil, 45.2, 14.2), "Check the sprung traps in the grass east of Vrang's camp for trapped game.", "8 Trapped Game"),
    finish(95494, p.vrang), finish(95507, p.vrang), accept(95495, p.vrang),
    finish(95495, p.walton, "Walton the tanner lives just west of Vrang."), accept(95621, p.walton),
    objectiveAt(95621, ba("Corporal Adamore", 41.79, 15.74),
      "Find Corporal Adamore with the Kul Tiran soldiers in the valley south of Walton and ask why they are here.",
      "Learn why the Kul Tirans are here"),
    finish(95621, p.walton), accept(95508, p.walton),
    objectiveAt(95508, ba("Terry Longdrink", 41.96, 11.5), "Help Walton deal with Terry Longdrink at his camp.", "Assist Walton"),
    finish(95508, p.walton),

    -- The Venture Co. in the north-east.
    finish(894, p.console, "Follow the hills east to the goblin pumping station and use the Control Console."),
    accept(900, p.console),
    objectiveAt(900, ba(nil, 52.35, 11.5), "Close the three valves next to the pipes beside the console.",
      "Shut off Main Control Valve", "Shut off Fuel Control Valve", "Shut off Regulator Valve"),
    finish(900, p.console), accept(901, p.console),
    objectiveAt(901, ba("Tinkerer Sniggles", 52.84, 10.4), "Kill Tinkerer Sniggles in the hut north-east of the console and take his key.", "Console Key"),
    finish(901, p.console), accept(902, p.console),
    along(objectiveAt(869, ba(nil, 54.3, 12.3),
      "Finish the raptor heads on the hills east of the station. Kill Savannah Prowlers for any missing claws.", "12 Raptor Heads"), 903),
    accept(858, p.shredder, "Go north to the Venture Co. drill site and talk to Wizzlecrank's Shredder at the edge of the camp."),
    objectiveAt(858, ba("Supervisor Lugwizzle", 56.34, 8.24),
      "Supervisor Lugwizzle walks the top of the drill tower. Kill him and take the ignition key.", "Ignition Key"),
    finish(858, p.shredder), accept(863, p.shredder),
    objectiveAt(863, ba(nil, 55.5, 7.1),
      "Follow Wizzlecrank out of the drill site and kill the goblins that ambush him, Overseer Glibby among them.",
      "Escort Wizzlecrank out of the Venture Co. drill site"),
    objectiveAt(896, ba(nil, 61.5, 4.4),
      "Go east to the Boulder Lode Mine. Kill the Venture Co. Enforcers and Overseers inside until a Cats Eye Emerald drops.",
      "Cats Eye Emerald"),

    -- Orgrimmar: the west gate is a short ride north of the mine.
    action("goto", nil, "Follow the path north along the river and enter Orgrimmar by its western gate. Use Next once you are inside."),
    finish(6384, p.gryshka, "Innkeeper Gryshka runs the inn in the Valley of Strength."),
    accept(6385, p.gryshka), finish(6385, p.doras, "Doras keeps the wind riders on the tower above the Valley of Strength."),
    accept(6386, p.doras),
    taxi("getfp", p.doras, "Orgrimmar, Durotar", "Learn the Orgrimmar flight path from Doras if you don't have it."),
    action("train", nil, "Train spells for level", { level = 16 }),
    accept(1061, p.zor, "Zor Lonetree stands in the Valley of Wisdom, near Thrall's hall."),
    dungeon(accept(5761, p.neeru, "For Ragefire Chasm, Neeru Fireblade in the Cleft of Shadow wants Taragaman's heart."), "ragefire-chasm"),
    action("hearth", p.boorand, "Hearth back to the Crossroads.", crossroadsBind),
  }
end)()

-- Southern Barrens, 16-18: Echeyakee, Ratchet again, the Stagnant Oasis, Camp Taurajo and the
-- centaur leaders.
local south = (function()
  return {
    finish(869, p.gazrog), accept(3281, p.gazrog),
    finish(848, p.helbrim),
    finish(867, p.darsok), accept(875, p.darsok),
    accept(899, p.mankrik, "Mankrik waits by the south gate. Take both of his quests."), accept(4921, p.mankrik),
    finish(870, p.tonga), accept(877, p.tonga),
    finish(903, p.sergra), accept(881, p.sergra),
    finish(6386, p.zargh),
    withItem(10327, objectiveAt(881, ba(nil, 55.8, 17.0),
      "Ride north-east into the grassland between Thorn Hill and the Sludge Fen. Blow the Horn of Echeyakee there and kill the white lion that answers.",
      "Echeyakee's Hide")),
    finish(881, p.sergra), accept(905, p.sergra),
    taxi("fly", p.bragok, "Ratchet, The Barrens", "Fly to Ratchet from Devrak."),
    finish(902, p.sputtervalve), finish(863, p.sputtervalve), accept(1483, p.sputtervalve),
    finish(896, p.dizzywig),
    accept(865, p.mebok, "Mebok Mizzyrix stands by the bank."), accept(1069, p.mebok),
    objectiveAt(888, ba(nil, 63.1, 49.4),
      "Go back south to the pirate camps. The Shipment of Boots and the Telescopic Lens lie among the tents on the beach.",
      "Shipment of Boots", "Telescopic Lens"),

    -- West across the plains to the Stagnant Oasis.
    along(objectiveAt(3281, ba(nil, 58.0, 53.9),
      "Head west to the Raptor Grounds and search the raptor nests for the stolen silver. Loot horns from Sunscale Scytheclaws.",
      "Stolen Silver"), 865, 821),
    along(objectiveAt(877, ba(nil, 55.6, 42.8),
      "Go north to the Stagnant Oasis and drop the dried seeds into the water at its edge. Kolkar centaurs camp around it.",
      "Test the Dried Seeds"), 855),
    along(objectiveAt(851, ba(nil, 53.0, 41.8),
      "Kill the Kolkar at the camp on the oasis's west shore until Verog the Dervish appears. He is tough: rest before he arrives.",
      "Verog's Head"), 855),
    along(objectiveAt(905, ba(nil, 52.4, 46.4),
      "South of the oasis, kill Sunscale raptors for feathers and use one at each of the blue, red and yellow nests.",
      "Visit Blue Raptor Nest", "Visit Yellow Raptor Nest", "Visit Red Raptor Nest"), 865),
    objectiveAt(4921, ba("Beaten Corpse", 49.33, 50.32),
      "Follow the road south-west to a beaten corpse by the roadside and look it over.", "Find Mankrik's Wife"),
    action("goto", p.byula, "Follow the road south to Camp Taurajo."),
    action("sethearth", p.byula, "Bind your hearthstone with Innkeeper Byula.", taurajoBind),
    taxi("getfp", p.omusa, "Camp Taurajo, The Barrens", "Learn the flight path from Omusa Thunderhorn."),
    accept(878, p.mangletooth, "Mangletooth is caged by the north gate."),
    taxi("fly", p.devrak, "Crossroads, The Barrens", "Fly to the Crossroads."),
    finish(4921, p.mankrik), accept(95774, p.mankrik),
    finish(877, p.tonga), accept(880, p.tonga),
    finish(905, p.sergra), accept(3261, p.sergra),
    finish(3281, p.gazrog),

    -- Regthar's centaur leaders.
    finish(851, p.regthar), accept(852, p.regthar),
    along(objectiveAt(852, ba(nil, 45.6, 38.2),
      "Take the road south-west to the Lushwater Oasis. Hezrul Bloodmark leads the Kolkar there. Snapjaw turtles in the water carry the altered shells.",
      "Hezrul's Head"), 855, 880),
    objectiveAt(855, ba(nil, 45.6, 38.2), "Finish the centaur bracers around the Lushwater camp.", "15 Centaur Bracers"),
    finish(852, p.regthar), finish(855, p.regthar), accept(4021, p.regthar),
    objectiveAt(4021, ba("Warlord Krom'zar", 44.48, 28.15),
      "Centaurs attack Regthar's camp in waves. Fight them beside the guards until Warlord Krom'zar shows up, kill him and pick up his banner.",
      "Piece of Krom'zar's Banner"),
    finish(4021, p.regthar),
    objectiveAt(875, ba(nil, 40.3, 15.5),
      "Return to the Witchwing roosts. Kill Witchwing Slayers for their rings; they hit harder than the other harpies.", "6 Harpy Lieutenant Rings"),
    finish(1061, p.seereth, "Follow the road west to the Stonetalon border. Seereth Stonebreak stands at the foot of the pass."),
    accept(1062, p.seereth), accept(6548, p.makaba),
  }
end)()

-- Stonetalon and Camp Taurajo, 18-21: Malaka'jin, Sun Rock, the Venture Co., the southern quilboar,
-- Ratchet and Thunder Bluff.
local sunrock = (function()
  return {
    objectiveAt(6548, st(nil, 80.6, 90.0),
      "Climb the pass into Stonetalon. Kill Grimtotem Ruffians and Mercenaries around the camp just inside.",
      "8 Grimtotem Ruffians", "6 Grimtotem Mercenaries"),
    finish(6548, p.makaba), accept(6629, p.makaba),
    objectiveAt(6629, st("Grundig Darkcloud", 73.65, 86.13),
      "Go farther up the pass to Grimtotem Post. Kill the Brutes in the camp and Grundig Darkcloud by his tent.", "Grundig Darkcloud", "6 Grimtotem Brutes"),
    accept(6523, p.kaya, "Kaya Flathoof is held in the same camp. Accept when ready to escort her."),
    objectiveAt(6523, st(nil, 76.7, 90.9),
      "Walk Kaya south-east to Camp Aparaje. Grimtotems ambush you on the way: keep them off her.", "Kaya Escorted to Camp Aparaje"),
    accept(6461, p.xenzilla, "Follow the trail south to the troll village of Malaka'jin."),
    along(taxi("getfp", p.tharm, "Sun Rock Retreat, Stonetalon Mountains",
      "Follow the road north-west to Sun Rock Retreat. Kill Deepmoss Creepers along the way, then learn the flight path from Tharm."), 6461),
    finish(1483, p.ziz, "Ride east to Ziz Fizziks's hut on the road toward Windshear Crag."),
    accept(1093, p.ziz),
    along(objectiveAt(1062, st(nil, 61.5, 55.1),
      "Go north into Windshear Crag and kill the Venture Co. Loggers. Collect Deepmoss Eggs from the spider nests at the foot of the trees.",
      "15 Venture Co. Loggers"), 1093, 1069),
    along(objectiveAt(1093, st(nil, 62.8, 53.7), "Kill Venture Co. Operators near the logging machines until the blueprints drop.",
      "Super Reaper 6000 Blueprints"), 1062, 1069),
    objectiveAt(1069, st(nil, 61.4, 56.8), "Finish the Deepmoss Eggs from the nests around the crag.", "15 Deepmoss Eggs"),
    finish(1093, p.ziz), accept(1094, p.ziz),
    objectivePart(6461, 2, st(nil, 59.3, 61.6), "Kill Deepmoss Venomspitters around Ziz's hut.", "7 Deepmoss Venomspitters"),
    objectivePart(6461, 1, st(nil, 59.0, 73.0), "Finish the Deepmoss Creepers in the woods south of the hut.", "10 Deepmoss Creepers"),
    action("hearth", p.byula, "Hearth to Camp Taurajo.", taurajoBind),
    finish(3261, p.jorn), accept(882, p.jorn),

    -- The Bristleback quilboar south and east of Camp Taurajo.
    withItem(5099, accept(883, ba(nil, 46.3, 52.0),
      "Lakota'mani, a grey kodo, roams the grass north of Camp Taurajo. If its hoof drops, use it to start the quest.")),
    along(objectiveAt(878, ba(nil, 50.7, 54.6),
      "Go east to the Bristleback quilboar camps. Kill Water Seekers, Thornweavers and Geomancers and loot every tusk.",
      "6 Bristleback Water Seekers", "12 Bristleback Thornweavers", "12 Bristleback Geomancers"), 899, 95774, 821),
    along(objectiveAt(899, ba(nil, 50.7, 54.6), "Keep killing Bristlebacks until you have all the tusks.", "60 Bristleback Quilboar Tusks"), 878, 95774),
    objectiveAt(95774, ba(nil, 48.0, 53.3), "Razormane Raiders on the road west of the camps carry Olgra's adornments.", "4 Olgra's Adornments"),
    along(objectiveAt(821, ba(nil, 50.9, 53.0),
      "Kill Stormsnout, a thunder lizard among the hills here, for its horn. Finish the plainstrider kidneys and lion tusks too.",
      "5 Savannah Lion Tusks", "5 Plainstrider Kidneys", "Thunder Lizard Horn"), 865),
    objectiveAt(865, ba(nil, 52.0, 46.5), "Finish the raptor horns from Sunscale Scytheclaws north of the camps.", "5 Intact Raptor Horns"),
    objectiveAt(880, ba(nil, 55.6, 43.4), "Kill Oasis Snapjaws in the Stagnant Oasis for their shells.", "8 Altered Snapjaw Shells"),
    withItem(10338, objectiveAt(882, ba(nil, 59.7, 30.3),
      "Kill a Zhevra Runner for a fresh carcass, then ride north-east to the dead tree east of the Crossroads. Place the carcass under it and kill Ishamuhale when he comes.",
      "Ishamuhale's Fang")),
    action("goto", p.gazlowe, "Ride south-east to Ratchet."),
    finish(888, p.gazlowe),
    finish(1094, p.sputtervalve), accept(1095, p.sputtervalve),
    finish(865, p.mebok), finish(1069, p.mebok),
    -- Smart Drinks (1491) and Trouble at the Docks (959) are in the Wailing Caverns checklist's prepare
    -- phase; carrying them here would overfill the quest log through 22-30.
    finish(821, p.drohn),
    accept(92706, p.poster, "If you have a group, take Bruuz's poster. He is an elite shark in the water off the docks."),
    objectiveAt(92706, ba("Bruuz", 65.09, 39.09), "Swim out east of the docks with your group and kill Bruuz.", "Bruuz slain"),
    finish(92706, p.gazlowe),
    taxi("fly", p.devrak, "Crossroads, The Barrens", "Fly to the Crossroads."),
    finish(875, p.darsok), accept(876, p.darsok, "Leave Serena for the trip back from Thunder Bluff."),
    finish(899, p.mankrik), finish(95774, p.mankrik),
    finish(880, p.tonga), accept(1489, p.tonga), accept(3301, p.tonga),
    -- CARRY: turnin 3301 Mura Runetotem at Mura Runetotem, Silverpine Forest (22-30 file)
    accept(868, p.korran, "Korran's Egg Hunt is in the southern Barrens; keep it for later."),
    -- CARRY: complete and turnin 868 Egg Hunt at Korran (22-30 file, southern Barrens)
    accept(853, p.helbrim),
    taxi("fly", p.omusa, "Camp Taurajo, The Barrens", "Fly to Camp Taurajo."),
    finish(878, p.mangletooth), accept(5052, p.mangletooth),
    finish(5052, p.mangletooth, "Hand Mangletooth a Blood Shard from the quilboar you killed."),
    finish(882, p.jorn), accept(907, p.jorn),
    finish(883, p.jorn, "If you found Lakota'mani's hoof, hand it to Jorn."),

    -- Thunder lizards and thunderhawks around Camp Taurajo.
    withItem(5102, accept(884, ba(nil, 49.2, 61.4),
      "Owatanka, a blue thunderhawk, flies east of camp. If its tailspike drops, use it to start the quest.")),
    objectiveAt(907, ba(nil, 44.3, 60.8), "Kill Thunderheads and Stormsnouts in the fields around camp for their blood.", "3 Thunder Lizard Blood"),
    finish(884, p.jorn), finish(907, p.jorn), accept(913, p.jorn),
    objectiveAt(913, ba(nil, 44.8, 63.1), "Kill a thunderhawk in the fields south of camp for its wings.", "Thunderhawk Wings"),
    finish(913, p.jorn),
    -- Not taken: Mahren Skyseer 874 (level 27, from Jorn) leads to Isha Awak 873; leave it to the 22-30 route.

    -- Thunder Bluff.
    taxi("fly", p.tal, "Thunder Bluff, Mulgore",
      "Fly to Thunder Bluff if you know the flight. Otherwise take the road west from Camp Taurajo through Mulgore and ride the lift up."),
    taxi("getfp", p.tal, "Thunder Bluff, Mulgore", "Learn the flight path from Tal on the central rise."),
    action("sethearth", p.pala, "Bind your hearthstone with Innkeeper Pala.", bluffBind),
    action("train", nil, "Train spells for level", { level = 20 }),
    accept(264, p.clarice, "Clarice Foster stands on the Spirit Rise. Her quest leads to Silverpine; keep it."),
    -- CARRY: turnin 264 Until Death Do Us Part at Yuriv's Tombstone, Silverpine Forest (22-30 file)
    finish(853, p.zamah, "Apothecary Zamah is in the Pools of Vision, under the Spirit Rise."),
    dungeon(accept(962, p.zamah), "wailing-caverns"),
    finish(1489, p.hamuul, "Cross to the Elder Rise to Hamuul Runetotem."), accept(1490, p.hamuul),
    finish(1490, p.nara),
    dungeon(accept(914, p.nara), "wailing-caverns"),
    taxi("fly", p.devrak, "Crossroads, The Barrens", "Fly to the Crossroads."),
    objectiveAt(876, ba("Serena Bloodfeather", 39.16, 12.16),
      "Ride north-west to the far Witchwing roost. Serena Bloodfeather is at the top with her guards; pull them one by one.",
      "Serena's Head"),
    action("goto", p.darsok, "Ride back south-east to the Crossroads."),
    finish(876, p.darsok, "Hand Serena's head to Darsok."), accept(1060, p.darsok),
  }
end)()

-- Stonetalon and Ashenvale, 21-22: the second Stonetalon trip, the Zoram Strand and the trip home.
local ashenvale = (function()
  return {
    action("goto", p.seereth, "Ride west to the Stonetalon border."),
    finish(1062, p.seereth), accept(1063, p.seereth), accept(1068, p.seereth),
    finish(6629, p.makaba), finish(6523, p.makaba), accept(6401, p.makaba),
    finish(1060, p.jinzil, "Climb the pass and follow the trail south to Malaka'jin. Jin'Zil is at the south end of the village."),
    accept(1058, p.jinzil, "Keep Jin'Zil's errand for a later Stonetalon visit."),
    -- CARRY: complete and turnin 1058 Jin'Zil's Forest Magic at Witch Doctor Jin'Zil (22-30 file)
    finish(6461, p.xenzilla),
    accept(6284, st("Wanted Poster: Besseleth", 59.06, 75.71), "Read the poster on the road north of Malaka'jin."),
    objectiveAt(6284, st("Besseleth", 54.8, 71.95), "Besseleth, a large spider, lurks in the webbed hollow west of the road. Kill her for her fang.", "Besseleth's Fang"),
    accept(6562, p.tsunaman, "Go on to Sun Rock Retreat. Tsunaman stands near the entrance."),
    -- Not taken: Elemental War 6393 (level 25, Tsunaman); leave it to the 22-30 route's Stonetalon visit.
    finish(6284, p.maggran),
    finish(6401, p.tammra), accept(6301, p.tammra),
    -- CARRY: complete and turnin 6301 Cycle of Rebirth at Tammra Windfield (22-30 file)
    finish(1095, p.ziz, "Ride east to Ziz Fizziks's hut on the way to Windshear Crag."),
    -- Not taken: Gerenzo Wrenchwhistle 1096 (level 27, Ziz Fizziks); leave it to the 22-30 route.
    objectivePart(1068, 2, st("XT:9", 70.62, 56.14), "XT:9, a shredder, patrols the east side of Windshear Crag. Kill it.", "XT:9"),
    -- CARRY: XT:4 and turnin 1068 Shredding Machines at Seereth Stonebreak (22-30 file)
    accept(1090, p.piznik, "Piznik mines at the east end of the crag. Accept when ready to guard him."),
    objectiveAt(1090, p.piznik, "Stand by Piznik while he mines and kill the vermin that come at him.", "Keep Piznik safe while he mines the mysterious ore"),
    finish(1090, p.piznik), accept(1092, p.piznik),
    -- CARRY: turnin 1092 Gerenzo's Orders at Ziz Fizziks (22-30 file)

    -- Ashenvale through the Talondeep Path.
    action("goto", av(nil, 42.27, 71.09), "Take the Talondeep Path tunnel at the north-east corner of Windshear Crag into Ashenvale."),
    accept(98251, p.vaxug, "Va'xug Firefure camps north-west of the tunnel exit."),
    objectiveAt(98251, av(nil, 40.1, 65.9), "Kill Shadowhorn Stags and Ashenvale Bears in the woods south of Va'xug.", "6 Shadowhorn Stags", "6 Ashenvale Bears"),
    finish(98251, p.vaxug), accept(98252, p.vaxug),
    objectiveAt(98252, av(nil, 38.9, 57.9), "Lead the Eye of Kilrogg north-west to the main road.", "Eye of Kilrogg guided to the road"),
    finish(98252, av("Eye of Kilrogg", 38.27, 58.41)),
    taxi("getfp", p.andruk, "Zoram'gar Outpost, Ashenvale",
      "Ride west across Ashenvale to Zoram'gar Outpost on the coast, keeping clear of Astranaar on the main road. Learn the flight path from Andruk."),
    finish(6562, p.jeneu),
    dungeon(accept(6563, p.jeneu), "blackfathom-deeps"),
    accept(216, p.karang),
    -- CARRY: complete and turnin 216 Between a Rock and a Thistlefur at Karang Amakkar (22-30 file)
    -- Not taken: Troll Charm 6462 (level 24, Mitsuwa; Troll Chests near 41, 34); leave it to the 22-30 Ashenvale visit.
    accept(6442, p.marukai), accept(6641, p.muglash, "Accept when ready to escort Muglash up the coast."),
    along(objectiveAt(6641, av("Vorsha the Lasher", 9.63, 27.63),
      "Follow Muglash north to the brazier, put it out, then guard him from the naga waves and Vorsha.", "Defeat Vorsha the Lasher"), 6442),
    objectiveAt(6442, av(nil, 11.0, 28.6), "Kill Wrathtail naga along the Zoram Strand for their heads.", "20 Wrathtail Heads"),
    finish(6641, p.runner, "A Warsong Runner at the outpost takes Muglash's report."),
    finish(6442, p.marukai),

    -- Home through Thunder Bluff and Orgrimmar.
    action("hearth", p.pala, "Hearth to Thunder Bluff.", bluffBind),
    finish(1063, p.magatha, "Magatha Grimtotem lives on the Elder Rise."), accept(1064, p.magatha),
    finish(1064, p.zamah), accept(1065, p.zamah),
    -- CARRY: turnin 1065 Journey to Tarren Mill at Apothecary Lydon, Tarren Mill (22-30 file)
    taxi("fly", p.doras, "Orgrimmar, Durotar", "Fly to Orgrimmar from Tal."),
    dungeon(finish(5761, p.neeru, "If you ran Ragefire Chasm, bring Taragaman's heart to Neeru Fireblade in the Cleft of Shadow."), "ragefire-chasm"),
    action("train", nil, "Train spells for level", { level = 22 }),
    -- Not taken: Chief Engineer Scooty 2842 (level 35, Sovik in the Valley of Honor); RestedXP takes it here for a
    -- much later Booty Bay visit. The 22-30 route can add it when it passes through Orgrimmar.
  }
end)()

-- Arrow hints for ground legs between these maps (other files may add their own).
local function road(to, from, waypoint, label)
  route.roadTo[to] = route.roadTo[to] or {}
  route.roadTo[to][from] = route.roadTo[to][from] or { waypoint = waypoint, label = label }
end
road(M.stonetalon, M.barrens, p.seereth, "Take the western pass into Stonetalon")
road(M.barrens, M.stonetalon, st(nil, 80.6, 90.0), "Take the pass down into the Barrens")
road(M.ashenvale, M.stonetalon, p.talondeep, "Take the Talondeep Path to Ashenvale")

local sources = {
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  "https://bindonforever.com/zones/the-barrens",
  "https://www.warcrafttavern.com/forever/guides/leveling",
}
local westSources = {
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  "https://bindonforever.com/zones/the-barrens",
  "https://bindonforever.com/zones/stonetalon-mountains",
  "https://bindonforever.com/zones/ashenvale",
}
for _, section in ipairs({
  { id = "crossroads", title = "The Crossroads", zone = M.barrens, levels = { 12, 15 }, steps = crossroads },
  { id = "barrens-north", title = "Northern Barrens", zone = M.barrens, levels = { 15, 16 },
    steps = B.withTrainers(north, orgrimmarTrainers) },
  { id = "barrens-south", title = "Southern Barrens", zone = M.barrens, levels = { 16, 18 }, steps = south },
  { id = "sun-rock", title = "Sun Rock and Camp Taurajo", zone = M.barrens, levels = { 18, 21 },
    steps = B.withTrainers(sunrock, bluffTrainers), web = true },
  { id = "zoramgar", title = "Stonetalon and Ashenvale", zone = M.stonetalon, levels = { 21, 22 },
    steps = B.withTrainers(ashenvale, orgrimmarTrainers), web = true },
}) do
  section.verified, section.sources = false, section.web and westSources or sources
  section.web = nil
  route.sections[#route.sections + 1] = section
end
