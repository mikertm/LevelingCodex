-- Horde route, levels 40-50. Source notes: tools/audits/2026-11-12-horde-40-50.md.
-- Helpers: B.horde (QuestHorde3040.lua) and the shared build helpers in QuestData.lua.
-- Main chapters go through H.chapter: a hand-in for a quest the 30-40 chapters give becomes
-- optional until that pickup is on the main route. Dungeon pickups are tagged with H.dungeon.
local B = LevelingCodexQuests.build
local H = B.horde
local M = B.maps
local on = B.on
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, part, withItem, along = B.objectiveAt, B.objectivePart, B.withItem, B.along
local note, need, dungeon, only = B.note, H.need, H.dungeon, B.only

local qdb = "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever"

-- Step lists are built in pieces (trainer visits in between).
local function cat(...)
  local result = {}
  for i = 1, select("#", ...) do
    for _, step in ipairs((select(i, ...))) do result[#result + 1] = step end
  end
  return result
end

-- One class-filtered trainer stop per class the town trains.
local function train(trainers, level)
  local steps = {}
  for _, trainer in ipairs(trainers) do
    local class, place = trainer[1], trainer[2]
    steps[#steps + 1] = action("train", place, "Visit " .. place.name .. " to train for level",
      { class = class, level = level, min = level })
  end
  return steps
end

-- Class trainers (QuestieDB spawns). Warlocks train only in Orgrimmar; druids and paladins only
-- in Thunder Bluff.
local og, tb = on.orgrimmar, on.thunderBluff
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
local bluffOnly = { bluffTrainers[7], bluffTrainers[8] }

-- Places more than one chapter uses.
local P = {
  thysta = on.stv("Thysta", 32.5, 29.4),
  thulbek = on.stv("Innkeeper Thulbek", 31.5, 29.8),
  mokthardin = on.stv("Far Seer Mok'thardin", 32.12, 29.24),
  kinweelay = on.stv("Kin'weelay", 32.27, 27.71),
  cauldron = on.stv("Bubbling Cauldron", 32.22, 27.6),
  hemet = on.stv("Hemet Nesingwary", 35.66, 10.81),
  erlgadin = on.stv("Sir S. J. Erlgadin", 35.55, 10.55),
  gringer = on.stv("Gringer", 26.9, 77.1),
  crank = on.stv("Crank Fizzlebub", 27.12, 77.21),
  seahorn = on.stv("Fleet Master Seahorn", 27.17, 77.01),
  mackinley = on.stv("\"Sea Wolf\" MacKinley", 27.78, 77.07),
  bootyPier = on.stv(nil, 25.8, 73.1),
  gromgolZeppelin = on.stv("Nez'raz", 31.4, 29.9),
  orgrimmarZeppelin = on.durotar("Snurk Bucksquick", 50.7, 12.9),
  undercityZeppelin = on.durotar(nil, 50.8, 13.8),
  breyk = on.swamp("Breyk", 46.1, 54.8),
  thalon = on.desolace("Thalon", 21.6, 74.1),
  felzerul = on.swamp("Fel'zerul", 47.93, 54.78),
  tokkar = on.swamp("Tok'Kar", 81.32, 80.97),
  katar = on.swamp("Katar", 83.76, 80.41),
  bulkrek = on.tanaris("Bulkrek Ragefist", 51.6, 25.4),
  fizzgrimble = on.tanaris("Innkeeper Fizzgrimble", 52.5, 27.9),
  bilgewhizzle = on.tanaris("Chief Engineer Bilgewhizzle", 52.46, 28.51),
  tranrek = on.tanaris("Tran'rek", 51.57, 26.76),
  fizzledowser = on.tanaris("Senior Surveyor Fizzledowser", 50.21, 27.48),
  pestlezugg = on.tanaris("Alchemist Pestlezugg", 50.89, 26.96),
  marvon = on.tanaris("Marvon Rivetseeker", 52.71, 45.92),
  stoley = on.tanaris("Stoley", 67.11, 23.98),
  yehkinya = on.tanaris("Yeh'kinya", 66.99, 22.36),
  shardi = on.dustwallow("Shardi", 35.6, 31.9),
  mokmorokk = on.dustwallow("Overlord Mok'Morokk", 36.29, 31.41),
  drazzilb = on.dustwallow("Draz'Zilb", 37.15, 33.09),
  tabetha = on.dustwallow("Tabetha", 46.06, 57.09),
  shyn = on.feralas("Shyn", 75.5, 44.4),
  greul = on.feralas("Innkeeper Greul", 74.8, 45.2),
  uzeri = on.feralas("Witch Doctor Uzer'i", 74.42, 43.36),
  jangdor = on.feralas("Jangdor Swiftstrider", 74.43, 42.91),
  tal = tb("Tal", 47.0, 49.8),
  doras = og("Doras", 45.1, 63.9),
  gilveradin = on.hinterlands("Gilveradin Sunchaser", 26.71, 48.59),
}
local gromgol, gadgetzan, mojache = { bind = "Grom'gol Base Camp" }, { bind = "Gadgetzan" }, { bind = "Camp Mojache" }

-- Roads this band rides that the shared Horde 30-60 setup does not define. The Tanaris side of
-- the Shimmering Flats road is the Thousand Needles crossing converted with the client's map extents.
do
  local road = H.road
  road(M.stv, M.duskwood, on.stv(nil, 40.6, 3.5), "Follow the road north into Duskwood")
  road(M.stv, M.swamp, on.stv(nil, 40.6, 3.5), "Ride north into Duskwood, then east through Deadwind Pass")
  road(M.duskwood, M.swamp, on.duskwood(nil, 87.7, 41.1), "Take the east road through Deadwind Pass to the Swamp of Sorrows")
  road(M.duskwood, M.deadwind, on.duskwood(nil, 87.7, 41.1), "Take the east road out of Duskwood into Deadwind Pass")
  road(M.deadwind, M.swamp, on.deadwind(nil, 60.5, 41.4), "Follow the road east into the Swamp of Sorrows")
  road(M.tanaris, M.needles, on.tanaris(nil, 51.3, 20.3), "Ride north out of Gadgetzan into the Shimmering Flats")
end

-- Stranglethorn at 40: a training trip to Orgrimmar, then Grom'gol's Bloodscalp and naga work
-- and the Nesingwary hunts.
do
  local st = on.stv
  local aggrogosh = st("Commander Aggro'gosh", 32.2, 28.9)
  local nimboya = st("Nimboya", 32.16, 27.72)

  -- A Threat in Feralas (2981, Belgrom Rockmaul in Orgrimmar) is only a pointer to Camp Mojache;
  -- the route skips it to keep a log slot free and hands it in there if you carry it.
  need(2981, "A Threat in Feralas", 43, 38)
  need(572, "Mok'thardin's Enchantment", 41, 33, 570)
  need(1240, "The Troll Witchdoctor", 35, 30, 1239)
  need(584, "Bloodscalp Clan Heads", 41, 30, 582)
  need(585, "Speaking with Nezzliok", 40, 30, 584)
  need(598, "Split Bone Necklace", 42, 30, 596)
  need(95748, "The Gurubashi Legends of Old", 40, 30, 629, true)
  need(95770, "Locating the Lost City", 40, 30, 95748, true)
  need(95773, "Enemies in the Water", 37, 30, nil, true)
  need(1261, "Marg Speaks", 40, 30, 1240)
  need(78823, "Terror of the Desert Skies", 40, nil, nil, true)
  B.quest[78823].startItem = B.quest[78823].startItem or 211269

  H.chapter("stv-40", "Stranglethorn: Grom'gol and the Bloodscalp Heads", M.stv, 40, 41, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    "https://conquestcapped.com/guides/wow-forever/wow-forever-the-drowned-city-guide/",
    "https://www.wowhead.com/forever/quest=95773",
    qdb,
  }, { "swamp-41", "dustwallow-40" }, cat({
    taxi("fly", on.badlands("Gorrik", 4.0, 44.8), "Grom'gol, Stranglethorn", "Fly from Kargath to Grom'gol Base Camp."),
    taxi("getfp", P.thysta, "Grom'gol, Stranglethorn", "If you came by zeppelin instead, learn the Grom'gol flight path from Thysta."),
    action("sethearth", P.thulbek, "Bind at the Grom'gol inn, the long hut beside the zeppelin tower.", gromgol),
    finish(1240, P.kinweelay, "Give Kin'weelay the head Nazeer sent from Dustwallow."),
    accept(584, nimboya, "Nimboya wants the heads of the two Bloodscalp leaders."),
    accept(95773, aggrogosh, "Commander Aggro'gosh wants the naga off Grom'gol's coast taught a lesson."),
    action("boat", P.gromgolZeppelin, "Level 40 means new spells and your first mount. Take the zeppelin from the tower beside Grom'gol to Orgrimmar. Use Next when you land.",
      { name = "Grom'gol - Orgrimmar" }),
  }, train(orgrimmarTrainers, 40), {
    action("note", nil, "Learn riding now if you can afford it. Orcs train with Kildar in the Valley of Honor, Trolls at Sen'jin Village, Tauren in Bloodhoof Village, Undead in Brill. Druids and paladins train their spells in Thunder Bluff; you pass it at 42.",
      { name = "Riding at 40" }),
    action("boat", P.orgrimmarZeppelin, "Leave Orgrimmar by the main gate and climb the zeppelin tower to the north. Take the zeppelin back to Grom'gol.",
      { name = "Orgrimmar - Grom'gol" }),
    along(objective(95773, st(nil, 23.4, 25.3), "Swim west to the Vile Reef. Kill Brinescale Skirmishers for their tridents.",
      "10 Brinescale Trident"), 628),
    objective(628, st(nil, 29.6, 23.9), "Elder Saltwater Crocolisks sun on the beach north of the reef. Kill one for Drizzlik's skin.",
      "Elder Crocolisk Skin"),
    action("goto", st(nil, 24.0, 11.5), "Follow the coast north to the Ruins of Zul'Kunda."),
    note(objective(95748, st(nil, 23.0, 12.0), "Find the tablet named Fall of Gurubashi in the ruins and make a rubbing of the third legend.",
      "Third Troll Legend"), "Tablet spot from a published Forever guide; check it in game."),
    along(objective(584, st("Gan'zulah", 23.4, 8.1), "Gan'zulah and Nezzliok the Dire stand at the top of the ruins. Clear their guards, then pull the leaders one by one.",
      "Gan'zulah's Head", "Nezzliok's Head"), 95748),
    action("goto", P.cauldron, "Ride back south to Grom'gol."),
    finish(584, P.cauldron, "Drop both heads into the bubbling cauldron beside Nimboya."),
    accept(585, P.cauldron),
    finish(95748, P.kinweelay), accept(95770, P.kinweelay, "Kin'weelay wants to know where the drowned city from the legend lies."),
    finish(95773, aggrogosh),
    accept(572, P.mokthardin, "Far Seer Mok'thardin wants feathers from the jungle stalkers to the south."),
    accept(598, P.kinweelay, "Kin'weelay wants necklaces from the Skullsplitter trolls in the east."),
    note(objective(95770, st(nil, 21.4, 27.8), "Swim west past the Vile Reef and find the underwater cavern called Sunken Hollow.",
      "Sunken Hollow found"), "Cavern spot from a published Forever guide; the objective text is not published."),
    action("goto", st(nil, 27.1, 44.0), "Swim back and ride south down the coast road to the ruins where the jungle stalkers hunt."),
    along(objective(572, st(nil, 27.1, 46.7), "Kill Jungle Stalkers around the ruins for their feathers.", "10 Jungle Stalker Feather"), 196),
    along(objective(196, st(nil, 27.1, 46.7), "Every stalker also counts for Hemet Nesingwary.", "10 Jungle Stalkers slain"), 572),
    action("goto", st(nil, 41.6, 43.6), "Ride east across the jungle to the Venture Co. mine."),
    objective(600, st(nil, 41.6, 43.6), "Kill the miners and tinkerers at the mine for Singing Blue Crystals.", "10 Singing Blue Crystal"),
    along(objective(598, st(nil, 45.3, 38.0), "Clear the Skullsplitter trolls in the ruins north-east of the mine for Split Bone Necklaces.",
      "25 Split Bone Necklace"), 209, 585),
    along(objective(209, st(nil, 45.3, 38.0), "The same trolls carry Kebok's tusks.", "18 Skullsplitter Tusk"), 598),
    part(585, 2, st("Ziata'jai Trophy Skulls", 42.2, 36.1), "Take the trophy from the skull pile in the Ziata'jai ruins.", "Ziata'jai Trophy"),
    part(585, 3, st("Zul'Mamwe Trophy Skulls", 47.6, 39.5), "The Zul'Mamwe trophy pile sits in the ruins to the east.", "Zul'Mamwe Trophy"),
    part(585, 1, st("Balia'mah Trophy Skulls", 46.1, 32.3), "The Balia'mah pile is in the ruins to the north.", "Balia'mah Trophy"),
    objective(193, st("Bhag'thera", 49.6, 24.0), "Bhag'thera prowls the hills north-east of the Balia'mah ruins. Kill her for her fang.",
      "Fang of Bhag'thera"),
    action("hearth", P.thulbek, "Hearth to Grom'gol.", gromgol),
    finish(572, P.mokthardin), finish(598, P.kinweelay), finish(95770, P.kinweelay),
    finish(585, P.cauldron),
    accept(1261, P.cauldron, "The cauldron has one more message: Marg's pendant must reach Nazeer in Brackenwall. You pass there at 42."),
    action("goto", P.erlgadin, "Ride north up the road to Nesingwary's Expedition."),
    finish(78823, P.hemet, "If you carry the primitive drawing from the Badlands, show it to Hemet."),
    finish(196, P.hemet), accept(197, P.hemet, "Hemet's last raptor is Tethis. You hunt him when you are back here at 44."),
    finish(193, P.erlgadin),
  }))
end

-- Swamp of Sorrows at 41: Beggar's Haunt on the way in, Stonard, the Harborage and the Lost Ones,
-- then Booty Bay, the boat to Ratchet and Thunder Bluff.
do
  local sw, st = on.swamp, on.stv
  local zraedus = on.duskwood("Deathstalker Zraedus", 87.81, 35.63)
  local faustin = on.duskwood("Apothecary Faustin", 87.45, 35.25)
  local dar = sw("Dar", 44.7, 57.21)
  local helgrum = sw("Helgrum the Swift", 47.74, 55.2)
  local magtoor = sw("Magtoor", 25.98, 31.4)
  local pelluk = sw("Pelluk", 26.0, 31.6)
  local galen = sw("Galen Goodward", 65.47, 18.16)
  local strongbox = sw("Galen's Strongbox", 47.81, 39.76)
  local krazek = st("Krazek", 26.94, 77.21)
  local kebok = st("Kebok", 27.0, 77.13)
  local revilgaz = st("Baron Revilgaz", 27.23, 76.87)
  local drizzlik = st("Drizzlik", 28.29, 77.59)
  local mebok = on.barrens("Mebok Mizzyrix", 62.37, 37.62)
  local bragok = on.barrens("Bragok", 63.1, 37.2)

  need(1372, "Nothing But The Truth", 42, 37)
  need(698, "Lack of Surplus", 40, 35)
  need(93663, "Lost in Transit", 35, nil, nil, true)
  need(1420, "Report to Helgrum", 40, 30)
  need(1424, "Pool of Tears", 43, 38)
  need(1392, "Noboru the Cudgel", 39, 29)
  need(1389, "Draenethyst Crystals", 35, 30)
  need(93430, "Taking the Bait Back", 35, nil, nil, true)
  need(1373, "Ongeku", 37, 30, 1370)
  need(1393, "Galen's Escape", 38, 30)
  need(1183, "Goblin Sponsorship", 37, 29, 1182)
  need(1270, "Stinky's Escape", 37, 30)
  need(1276, "The Black Shield", 37, 30, 1323)
  need(1205, "Deadmire", 45, 35)
  need(1049, "Compendium of the Fallen", 38, 28)
  H.limit(1049, { race = { "ORC", "TAUREN", "TROLL" } })

  H.chapter("swamp-41", "Swamp of Sorrows: Stonard and the Harborage", M.swamp, 41, 42, {
    "https://www.wowhead.com/forever/zone=8/swamp-of-sorrows",
    "https://www.wowhead.com/forever/quest=93663",
    "https://www.wowhead.com/forever/quest=93430",
    qdb,
  }, { "desolace-41", "dustwallow-40" }, cat({
    action("goto", st(nil, 40.6, 3.5), "Ride north from Nesingwary's camp up the road into Duskwood."),
    accept(1372, zraedus, "Follow the Duskwood road east past Darkshire to Beggar's Haunt, the ruined house in the far east. Deathstalker Zraedus hides inside."),
    finish(1372, faustin, "Apothecary Faustin is in the same house."),
    action("goto", sw(nil, 3.0, 61.0), "Take the road east through Deadwind Pass into the Swamp of Sorrows."),
    objective(1116, sw(nil, 13.5, 61.0), "Kill the dragon whelps in the western swamp for Krazek's dream dust.", "10 Speck of Dream Dust"),
    action("goto", dar, "Follow the road east to Stonard, the orc town in the middle of the swamp."),
    accept(698, dar, "Dar stands by the town's west gate."),
    accept(93663, dar),
    taxi("getfp", P.breyk, "Stonard, Swamp of Sorrows", "Learn the Stonard flight path from Breyk."),
    finish(1420, helgrum, "Helgrum the Swift is in the great hall."),
    accept(1424, P.felzerul, "Fel'zerul, beside Helgrum, wants artifacts from the Pool of Tears."),
    note(objective(93663, sw(nil, 44.0, 41.0), "Ride north out of Stonard. Search the water's edge along the road for the missing goblin courier and take his shipment.",
      "Courier's Shipment"), "The courier's spot is not published; check it in game."),
    action("goto", magtoor, "Follow the road north-west to the Harborage, the draenei camp on the swamp's north edge."),
    finish(93663, magtoor, "Give Dar's shipment to Magtoor."),
    accept(1389, magtoor),
    note(accept(93430, pelluk, "Pelluk, at the same camp, lost his lucky lure to a Lost One fisherman."),
      "Pelluk is a Forever addition; his exact spot in the camp needs an in-game check."),
    along(note(objective(93430, sw(nil, 45.4, 33.4), "Ride east along the lake shore and kill Lost One Fishermen until the lure turns up.",
      "Lucky Lure"), "Which fisherman carries the lure is not published."), 1392),
    withItem(6196, accept(1392, sw("Noboru the Cudgel", 55.7, 34.4), "Noboru the Cudgel wanders the shore east of the lake. Kill him and use the cudgel he drops.")),
    action("goto", sw(nil, 62.0, 22.0), "Ride north-east to the Lost Ones' village in the Fallow Sanctuary."),
    along(objective(1389, sw(nil, 63.3, 22.4), "Pick up the green Draenethyst crystals around the village.", "6 Draenethyst Crystal"), 1373),
    objective(1373, sw("Ongeku", 65.1, 22.0), "Ongeku stands in the village. Kill him for the Draenethyst shard.", "Draenethyst Shard"),
    accept(1393, galen, "Galen Goodward is caged at the north end of the village. Free him."),
    objective(1393, galen, "Escort Galen south out of the village. Kill the Lost Ones that jump you on the way.", "Galen escorted"),
    finish(1393, strongbox, "Galen's strongbox sits at his old camp by the road. Open it."),
    action("goto", magtoor, "Ride west back to the Harborage."),
    finish(1389, magtoor), finish(1392, magtoor), finish(93430, pelluk),
    objective(698, sw(nil, 54.8, 45.2), "Ride east. Sawtooth Crocolisks lie in the water east of the road; take their flanks for Dar.",
      "8 Unprepared Sawtooth Flank"),
    objective(1424, sw(nil, 73.8, 55.1), "Go east to the Pool of Tears and pick up the Atal'ai artifacts lying in the shallow water.",
      "10 Atal'ai Artifact"),
    finish(698, P.tokkar, "Tok'Kar's camp is at Misty Reed Strand in the south-east. Bring him the flanks."),
    action("goto", P.felzerul, "Ride back west to Stonard."),
    finish(1424, P.felzerul),
    taxi("fly", P.breyk, "Booty Bay, Stranglethorn", "Fly to Booty Bay."),
    taxi("getfp", P.gringer, "Booty Bay, Stranglethorn", "Learn the Booty Bay flight path from Gringer if you rode in."),
    finish(1116, krazek, "Krazek is upstairs in the Booty Bay inn."),
    accept(1117, krazek), accept(2864, krazek, "Krazek also has word for Tran'rek in Gadgetzan."),
    finish(209, kebok, "Kebok stands beside Krazek."),
    finish(669, P.seahorn, "Fleet Master Seahorn is at the top of the inn."),
    accept(1183, revilgaz, "Baron Revilgaz, near Seahorn, sponsors a racer in the Shimmering Flats."),
    finish(600, P.crank, "Crank Fizzlebub is in the inn too."),
    accept(2872, P.mackinley, "\"Sea Wolf\" MacKinley wants a debt collected in Tanaris."),
    finish(628, drizzlik),
    action("boat", P.bootyPier, "Take the boat from the Booty Bay pier to Ratchet. Use Next when you land.", { name = "Booty Bay - Ratchet" }),
    finish(1270, mebok, "If you escorted Stinky out of Dustwallow, tell Mebok Mizzyrix in Ratchet."),
    taxi("fly", bragok, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
  }, train(bluffTrainers, 42), {
    finish(1276, tb("Mosarn", 54.01, 80.77), "Show the black shield to Mosarn."),
    accept(1205, tb("Melor Stonehoof", 61.54, 80.92), "Melor Stonehoof wants Deadmire's tooth from Dustwallow Marsh."),
    finish(1049, tb("Sage Truthseeker", 34.4, 46.87), "Bring the Compendium from the Scarlet Monastery to Sage Truthseeker."),
  }))
end

-- Desolace at 41: Shadowprey Village, Mannoroc Coven, the Gelkis and Magram khans.
do
  local ds = on.desolace
  local taiga = ds("Taiga Wisemane", 25.82, 68.21)
  local uthek = ds("Uthek the Wise", 36.22, 79.25)
  local hornizz = ds("Hornizz Brimbuzzle", 47.83, 61.83)
  local maurin = ds("Maurin Bonesplitter", 52.25, 53.44)
  local takata = ds("Takata Steelblade", 52.57, 54.39)
  local melizza = ds("Melizza Brimbuzzle", 33.95, 53.5)

  need(5581, "Portals of the Legion", 38, 32, 5381)
  need(1374, "Khan Jehn", 37, 30, 1373)
  need(6134, "Ghost-o-plasm Round Up", 39, 34)
  need(1484, "The Corrupter", 35, 25, 1482)
  need(1488, "The Corrupter", 40, 25, 1484)
  need(1380, "Khan Hratha", 42, 30, 1374)
  need(6132, "Get Me Out of Here!", 39, 34)

  H.chapter("desolace-41", "Desolace: Shadowprey Village and Mannoroc Coven", M.desolace, 41, 41, {
    "https://www.wowhead.com/forever/zone=405/desolace",
    qdb,
  }, { "tanaris-41", "dustwallow-40" }, {
    taxi("fly", P.tal, "Shadowprey Village, Desolace", "Fly from Thunder Bluff to Shadowprey Village."),
    accept(5581, taiga, "Taiga Wisemane in Shadowprey Village gives you the box for banishing the Mannoroc portals."),
    finish(1373, uthek, "Ride east to the Gelkis village and give Uthek the Wise Ongeku's shard."),
    accept(1374, uthek),
    accept(6134, hornizz, "Hornizz Brimbuzzle camps near the Kodo Graveyard. He lends you a crate of ghost magnets."),
    accept(1484, maurin, "Maurin Bonesplitter, at Ghost Walker Post, sends you to Takata Steelblade."),
    finish(1484, takata), accept(1488, takata),
    action("goto", ds(nil, 53.5, 76.0), "Ride south to Mannoroc Coven."),
    note(objective(5581, ds(nil, 53.5, 78.0), "Use Taiga's box at the demon portals around the coven and kill the guardian each one sends out.",
      "6 Demon Portal Guardian"), "The portals' spots are not in the quest data; look around the coven."),
    objective(1488, ds("Lord Azrethoc", 57.0, 75.7), "Kill Lord Azrethoc on the east side of the coven and Jugkar Grim'rod beside the ruins to the south.",
      "Lord Azrethoc", "Jugkar Grim'rod"),
    objective(1374, ds("Khan Jehn", 66.0, 80.4), "Ride east to the Magram village. Khan Jehn waits in the largest tent; clear his guards first.",
      "Khan Jehn's Head"),
    objective(6134, ds(nil, 64.0, 91.7), "Go south into the Valley of Bones. Open the crate of ghost magnets near the Magrami Spectres and pick up the ghost-o-plasm they leave.",
      "8 Ghost-o-plasm"),
    finish(1488, takata, "Ride back north to Ghost Walker Post."),
    finish(6134, hornizz),
    finish(1374, uthek), accept(1380, uthek),
    note(objective(1380, ds(nil, 33.0, 56.1), "Ride north to the Maraudine centaur camp. Its scouts drop a war horn mouthpiece; use it to call Khan Hratha and kill him for the key fragment.",
      "Maraudine Key Fragment"), "Where the horn is blown is not in the quest data; check it in game."),
    accept(6132, melizza, "Hornizz's cousin Melizza is held in the same Maraudine camp. Free her."),
    objective(6132, melizza, "Escort Melizza out of the camp to safety.", "Melizza escorted"),
    finish(6132, hornizz, "Tell Hornizz his cousin is safe."),
    finish(1380, uthek),
    action("goto", taiga, "Ride west back to Shadowprey Village."),
    finish(5581, taiga),
  })
end

-- Tanaris and Dustwallow at 41-43: Gadgetzan, the Shimmering Flats racers and Brackenwall Village.
do
  local tn, dm, fl = on.tanaris, on.dustwallow, on.needles
  local poster = tn("Wanted Poster", 51.83, 27.04)
  local luglunket = tn("Spigot Operator Luglunket", 52.49, 28.45)
  local kravel = fl("Kravel Koalbeard", 77.79, 77.27)
  local fizzle = fl("Fizzle Brassbolts", 78.06, 77.13)
  local pozzik = fl("Pozzik", 80.18, 75.88)
  local razzeric = fl("Razzeric", 80.33, 76.09)
  local plans = fl("Rizzle's Unguarded Plans", 77.21, 77.39)
  local krak = dm("Krak", 36.4, 30.9)
  local tharg = dm("Tharg", 37.37, 31.39)
  local nazeer = dm("Nazeer Bloodpike", 35.21, 30.66)

  need(2864, "Tran'rek", 45, 40)
  need(2781, "WANTED: Caliph Scorpidsting", 46, 39)
  need(243, "Into the Field", 46, 38, 238)
  need(379, "Slake That Thirst", 46, 38, 243)
  need(654, "Tanaris Field Sampling", 46, 38, 379)
  B.quest[654].startItem = B.quest[654].startItem or 8524
  need(1690, "Wastewander Justice", 43, 40)
  need(1691, "More Wastewander Justice", 44, 40, 1690)
  need(1707, "Water Pouch Bounty", 44, 40)
  need(3520, "Screecher Spirits", 44, 40)
  need(1186, "The Eighteenth Pilot", 37, 29, 1183)
  need(1187, "Razzeric's Tweaking", 41, 29, 1186)
  need(1190, "Keeping Pace", 41, 29, 1137)
  need(1194, "Rizzle's Schematics", 41, 29, 1190)
  need(1118, "Back to Booty Bay", 43, 35, 1117)
  need(98192, "Skin Careful, Skin Sharp", 43, nil, nil, true)
  need(1166, "Overlord Mok'Morokk's Concern", 43, 38)
  need(1168, "Army of the Black Dragon", 43, 38)
  need(1169, "Identifying the Brood", 43, 38)
  need(2846, "Tiara of the Deep", 46, 40)
  need(1262, "Report to Zor", 40, 30, 1261)

  H.chapter("tanaris-41", "Tanaris and Dustwallow: Gadgetzan and Brackenwall", M.tanaris, 41, 43, {
    "https://www.wowhead.com/forever/zone=440/tanaris",
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    "https://www.wowhead.com/forever/quest=98192",
    qdb,
  }, { "feralas-43", "dustwallow-40" }, {
    note(taxi("fly", P.thalon, "Gadgetzan, Tanaris", "Fly from Shadowprey Village to Gadgetzan."),
      "Without the Gadgetzan flight path, fly to Freewind Post and ride south through the Shimmering Flats."),
    taxi("getfp", P.bulkrek, "Gadgetzan, Tanaris", "Learn the Gadgetzan flight path from Bulkrek Ragefist by the north gate if you rode in."),
    finish(2864, P.tranrek, "Give Tran'rek Krazek's message."),
    accept(2781, poster, "Read the wanted poster on the wall by the inn."),
    action("sethearth", P.fizzgrimble, "Bind at the Gadgetzan inn.", gadgetzan),
    finish(243, P.bilgewhizzle, "Chief Engineer Bilgewhizzle stands by the water tower in the middle of town."),
    accept(379, P.bilgewhizzle), accept(1690, P.bilgewhizzle), accept(1707, luglunket),
    action("goto", tn(nil, 62.0, 28.0), "Ride east out of Gadgetzan to the Wastewander camps among the dunes."),
    along(objective(1690, tn(nil, 63.0, 30.0), "Kill Wastewander Bandits and Thieves around the camps.", "10 Wastewander Bandits", "10 Wastewander Thieves"),
      1707, 379),
    along(objective(1707, tn(nil, 63.0, 30.0), "The bandits and thieves carry water pouches. You need five for Luglunket.", "5 Wastewander Water Pouch"), 1690),
    objective(379, tn(nil, 63.0, 30.0), "Keep five more pouches for Bilgewhizzle.", "5 Wastewander Water Pouch"),
    action("goto", P.stoley, "Ride north-east to Steamwheedle Port on the coast."),
    finish(2872, P.stoley, "Find Stoley in Steamwheedle Port and settle MacKinley's debt."),
    accept(3520, P.yehkinya, "Yeh'kinya wants the spirits of Feralas screechers. Keep it for Camp Mojache."),
    action("goto", P.bilgewhizzle, "Ride back west to Gadgetzan."),
    finish(1690, P.bilgewhizzle), finish(379, P.bilgewhizzle), finish(1707, luglunket),
    accept(1691, P.bilgewhizzle, "Bilgewhizzle wants the rest of the Wastewander gang dealt with. You do it after Dustwallow."),
    action("goto", fl(nil, 77.5, 80.0), "Ride north out of Gadgetzan to the Mirage Raceway in the Shimmering Flats."),
    finish(1117, kravel, "Kravel Koalbeard runs the goblin pit at the raceway."),
    finish(1137, fizzle, "Fizzle Brassbolts is beside the gnome pit."),
    finish(1183, pozzik, "Pozzik works on the goblin racer."),
    accept(1186, pozzik), accept(1190, pozzik),
    finish(1186, razzeric), accept(1187, razzeric, "Razzeric's booster went down in Dustwallow. You get it there."),
    finish(1190, plans, "Ask Zamek in the goblin pit for a distraction, then take Rizzle's plans from the gnome camp while the guards look away."),
    accept(1194, plans), finish(1194, pozzik),
    accept(1118, kravel, "Keep Kravel's scheme for Booty Bay. You go back there at 44."),
    action("hearth", P.fizzgrimble, "Hearth to Gadgetzan.", gadgetzan),
    note(taxi("fly", P.bulkrek, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village."),
      "Assumes you learned the Brackenwall flight path in your 30s."),
    taxi("getfp", P.shardi, "Brackenwall Village, Dustwallow Marsh", "Learn the Brackenwall flight path from Shardi if you rode in."),
    note(accept(98192, krak, "Krak, a skinner in Brackenwall, wants intact raptor hides."), "A Forever quest; the giver's spot needs an in-game check."),
    accept(1166, P.mokmorokk, "Overlord Mok'Morokk lost his grog, snuff and strongbox in the south of the marsh."),
    accept(1169, P.drazzilb), accept(1168, tharg),
    action("goto", P.tabetha, "Ride south on the road to Tabetha's farm in the middle of the marsh."),
    dungeon("zul-farrak", accept(2846, P.tabetha, "Tabetha wants a tiara a sea witch wears in Zul'Farrak. Take it if you plan that dungeon.")),
    objective(1205, dm("Deadmire", 48.8, 56.8), "Deadmire, a huge crocolisk, swims in the lake east of Tabetha's farm. Kill him for his tooth.",
      "Deadmire's Tooth"),
    objective(1187, dm("Gizmorium Shipping Crate", 54.1, 56.5), "Razzeric's crate lies on the shore farther east. Take the Seaforium Booster.",
      "Seaforium Booster"),
    objective(1261, dm(nil, 56.4, 63.9), "Kill Muckshell crabs along the east coast until the jeweled pendant drops.", "Jeweled Pendant"),
    action("goto", dm(nil, 45.0, 68.0), "Ride west to the Wyrmbog in the south of the marsh."),
    along(objective(1168, dm(nil, 44.3, 66.4), "Kill Firemane Scouts and Ash Tails around the Wyrmbog. The Scalebanes guard the dragon caves to the east.",
      "10 Firemane Scouts", "10 Firemane Ash Tails", "5 Firemane Scalebanes"), 1169, 1166),
    along(objective(1169, dm(nil, 45.1, 73.7), "Searing Hatchlings and Whelps give the tongues and hearts.", "15 Searing Tongue", "15 Searing Heart"), 1168),
    part(1166, 1, dm("Mok'Morokk's Snuff", 44.5, 66.0), "The snuff lies in the Wyrmbog camp.", "Mok'Morokk's Snuff"),
    part(1166, 2, dm("Mok'Morokk's Grog", 38.7, 65.6), "The grog is farther west.", "Mok'Morokk's Grog"),
    part(1166, 3, dm("Mok'Morokk's Strongbox", 36.6, 69.6), "The strongbox is south of the grog.", "Mok'Morokk's Strongbox"),
    note(objective(98192, dm(nil, 33.6, 66.2), "Kill the Bloodfen raptors around Dragonmurk for intact hides.", "8 Intact Raptor Hide"),
      "The hide count comes from the quest page; which raptors drop them is not published."),
    action("goto", P.mokmorokk, "Ride north back to Brackenwall Village."),
    finish(1169, P.drazzilb), finish(1166, P.mokmorokk), finish(98192, krak), finish(1168, tharg),
    finish(1261, nazeer, "Give Nazeer Bloodpike Marg's pendant."),
    accept(1262, nazeer, "Nazeer sends the pendant on to Zor Lonetree in Orgrimmar. You go there at 45."),
    taxi("fly", P.shardi, "Gadgetzan, Tanaris", "Fly back to Gadgetzan."),
    withItem(8524, accept(654, nil, "Use the power source Bilgewhizzle gave you to start the field tests.")),
    note(objective(654, tn(nil, 52.0, 36.0), "Use the testing kit on basilisks, hyenas and scorpids in the dunes south of Gadgetzan.",
      "8 Acceptable Basilisk Sample", "8 Acceptable Hyena Sample", "8 Acceptable Scorpid Sample"), "The kit runs on a timer; finish before it runs out."),
    objective(2781, tn("Caliph Scorpidsting", 61.8, 38.2), "Ride south-east. Caliph Scorpidsting roams the Wastewander camps north of the pirate coast.",
      "Caliph Scorpidsting's Head"),
    objective(1691, tn(nil, 62.7, 37.1), "Clear the Wastewander Rogues, Assassins and Shadow Mages in the same camps.",
      "8 Wastewander Rogues", "6 Wastewander Assassins", "10 Wastewander Shadow Mages"),
    action("goto", P.bilgewhizzle, "Ride back to Gadgetzan."),
    finish(654, P.bilgewhizzle), finish(1691, P.bilgewhizzle), finish(2781, P.bilgewhizzle),
  })
end

-- Feralas at 43: Camp Mojache, the Gordunni and Woodpaw, the Writhing Deep, then Thunder Bluff and
-- Orgrimmar for turn-ins and training.
do
  local fe = on.feralas
  local rok = fe("Rok Orhan", 75.8, 43.58)
  local orwin = fe("Orwin Gizzmick", 75.7, 44.31)
  local krueg = fe("Krueg Skullsplitter", 75.94, 42.74)
  local hadoken = fe("Hadoken Swiftstrider", 74.91, 42.46)
  local blaise = fe("Blaise Montgomery", 74.9, 44.0)
  local battleMap = fe("Woodpaw Battle Map", 71.63, 55.92)
  local oox = fe("Homing Robot OOX-22/FE", 53.35, 55.7)
  local uthelnay = og("Uthel'nay", 39.16, 86.27)
  local zor = og("Zor Lonetree", 38.93, 38.4)

  need(2975, "The Ogres of Feralas", 43, 38)
  need(2987, "Gordunni Cobalt", 43, 38)
  need(2973, "A New Cloak's Sheen", 45, 38)
  need(2862, "War on the Woodpaw", 42, 39)
  need(2822, "The Mark of Quality", 46, 40)
  need(92878, "Lost for Words", 43, nil, nil, true)
  need(2978, "The Gordunni Scroll", 43, 38)
  B.quest[2978].startItem = B.quest[2978].startItem or 9370
  need(2863, "Alpha Strike", 43, 39, 2862)
  need(2980, "The Ogres of Feralas", 44, 38, 2975)
  need(2979, "Dark Ceremony", 46, 38, 2978)
  need(2974, "A Grim Discovery", 45, 38, 2973)
  need(2902, "Woodpaw Investigation", 43, 39, 2863)
  need(2903, "The Battle Plans", 43, 39, 2902)
  need(2976, "A Grim Discovery", 45, 37, 2974)
  need(7730, "Zukk'ash Infestation", 45, 39, 2903)
  need(7731, "Stinglasher", 47, 39, 2903)
  need(2766, "Find OOX-22/FE!", 45, 40)
  B.quest[2766].startItem = B.quest[2766].startItem or 8705
  need(2767, "Rescue OOX-22/FE!", 45, 40, 2766)
  need(3002, "The Gordunni Orb", 47, 38, 2979)
  need(7732, "Zukk'ash Report", 48, 39, { 7730, 7731 })
  need(3121, "A Strange Request", 45, 40)
  need(3122, "Return to Witch Doctor Uzer'i", 45, 40, 3121)
  need(7541, "Service to the Horde", 45, 30, 1262)
  need(7068, "Shadowshard Fragments", 42, 38)

  H.chapter("feralas-43", "Feralas: Camp Mojache and the Gordunni", M.feralas, 43, 45, {
    "https://www.wowhead.com/forever/zone=357/feralas",
    "https://www.wowhead.com/forever/quest=92878",
    qdb,
  }, { "stv-44", "searing-45", "dustwallow-40" }, cat({
    note(taxi("fly", P.bulkrek, "Camp Mojache, Feralas", "Fly from Gadgetzan to Camp Mojache."),
      "Without that flight path, fly to Shadowprey Village, ride south into Feralas and east along the road."),
    taxi("getfp", P.shyn, "Camp Mojache, Feralas", "Learn the Camp Mojache flight path from Shyn if you rode in."),
    finish(2981, rok, "If you carry Belgrom's message, give it to Rok Orhan."),
    accept(2975, rok, "Rok Orhan wants the Gordunni ogres north of the camp thinned out."),
    accept(2987, orwin, "Orwin Gizzmick, the goblin in the camp, lends you a shovel for the ogres' cobalt."),
    accept(2973, krueg), accept(2862, hadoken), accept(2822, P.jangdor),
    note(accept(92878, blaise, "Blaise Montgomery wants proof that the Grimtotem leader who raided his camp is dead."),
      "A Forever quest; check the giver's spot in game."),
    action("sethearth", P.greul, "Bind at the Camp Mojache inn.", mojache),
    objective(2862, fe(nil, 73.0, 54.0), "Ride south to the Woodpaw gnoll camps below Camp Mojache and take their manes.", "10 Woodpaw Gnoll Mane"),
    action("goto", fe(nil, 75.0, 30.0), "Ride north up the road to the Gordunni Outpost."),
    along(objective(2975, fe(nil, 75.5, 30.0), "Kill Gordunni Ogres and Ogre Mages around the outpost. Brutes count too.",
      "10 Gordunni Ogres", "10 Gordunni Ogre Mages", "5 Gordunni Brutes"), 2987),
    along(note(objective(2987, fe(nil, 75.5, 30.0), "Dig in the ogres' dirt mounds with Orwin's shovel for cobalt.", "12 Gordunni Cobalt"),
      "The mounds' spots are not in the quest data."), 2975),
    withItem(9370, accept(2978, nil, "If an ogre dropped the Gordunni Scroll, read it.")),
    action("goto", rok, "Ride back south to Camp Mojache."),
    finish(2862, hadoken), accept(2863, hadoken, "Alpha Strike gives you one hour. Go straight back south."),
    finish(2987, orwin), finish(2975, rok), accept(2980, rok), finish(2978, rok), accept(2979, rok),
    objective(2863, fe(nil, 66.7, 53.3), "Ride south-west past the gnoll camps and kill Woodpaw Alphas.", "5 Woodpaw Alphas"),
    objective(2973, fe(nil, 67.8, 47.5), "Go north to the hills around the Grimtotem camp and kill Sprite Darters for their wings.",
      "10 Iridescent Sprite Darter Wing"),
    action("goto", hadoken, "Ride back east to Camp Mojache."),
    finish(2863, hadoken), accept(2902, hadoken), finish(2973, krueg), accept(2974, krueg),
    along(objective(2974, fe(nil, 67.2, 46.5), "Kill Grimtotem raiders, naturalists and shamans in the camps west of Camp Mojache for horns.",
      "20 Grimtotem Horn"), 92878),
    note(objective(92878, fe(nil, 68.0, 39.0), "Namida Grimtotem leads the northern Grimtotem camp. Kill her and take her hoof.", "Namida's Hoof"),
      "Namida's spot is not published; the quest only says her camp is north-west of Camp Mojache."),
    finish(2902, battleMap, "Ride south to the Woodpaw camp and look over the battle map on the ground."),
    accept(2903, battleMap),
    action("goto", hadoken, "Ride back to Camp Mojache."),
    finish(92878, blaise), finish(2974, krueg),
    accept(2976, krueg, "The crate of horns goes to Belgrom Rockmaul in Orgrimmar. You go there at the end of this chapter."),
    finish(2903, hadoken), accept(7730, hadoken), accept(7731, hadoken),
    objective(7730, fe(nil, 75.9, 63.9), "Ride south to the Writhing Deep, the silithid hive. Kill Zukk'ash insects for carapaces.",
      "20 Zukk'ash Carapace"),
    objective(7731, fe("Stinglasher", 77.0, 61.6), "Stinglasher lurks in the hive's tunnels. Kill it for its glands.", "Stinglasher's Glands"),
    action("goto", fe(nil, 60.0, 60.0), "Ride west into the Lower Wilds."),
    along(objective(3520, fe(nil, 57.6, 57.3), "Kill Vale Screechers and use Yeh'kinya's flask on their bodies.", "3 Screecher Spirit"), 2980),
    along(objective(2980, fe(nil, 61.0, 66.5), "Go south to the Ruins of Isildien. Kill Gordunni Shamans, Warlocks and Maulers.",
      "10 Gordunni Shaman", "10 Gordunni Warlocks", "5 Gordunni Maulers"), 2979),
    objective(2979, fe(nil, 61.4, 68.6), "The Gordunni Mage-Lords in the ruins carry the orb.", "Gordunni Orb"),
    action("goto", fe(nil, 54.6, 56.7), "Ride north-west to Feral Scar Vale."),
    objective(2822, fe(nil, 54.6, 56.7), "Kill the Feral Scar yetis in the vale and their cave for thick hides. Keep any distress beacon that drops.",
      "10 Thick Yeti Hide"),
    withItem(8705, accept(2766, nil, "If a yeti dropped the OOX-22/FE distress beacon, use it.")),
    finish(2766, oox, "The robot hides at the back of the yeti cave."),
    note(accept(2767, oox, "Escort OOX-22/FE west to the Forgotten Coast. It is a long walk with ambushes; bring a partner if you can."),
      "Escort path and ambushes need an in-game check."),
    objective(2767, fe(nil, 45.7, 43.4), "Keep the robot alive until it flies off at the coast.", "Escort OOX-22/FE"),
    action("hearth", P.greul, "Hearth to Camp Mojache.", mojache),
    finish(2980, rok), finish(2979, rok), accept(3002, rok, "The orb goes to Uthel'nay in Orgrimmar."),
    finish(7730, hadoken), finish(7731, hadoken), accept(7732, hadoken),
    accept(3121, P.uzeri, "Witch Doctor Uzer'i wants a shrunken head taken to Neeru Fireblade in Orgrimmar."),
    finish(2822, P.jangdor),
    taxi("fly", P.shyn, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
    finish(1205, tb("Melor Stonehoof", 61.54, 80.92), "Bring Melor Stonehoof Deadmire's tooth."),
  }, train(bluffOnly, 44), {
    taxi("fly", P.tal, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
  }, train(orgrimmarTrainers, 44), {
    finish(3002, uthelnay, "Uthel'nay is in the Darkbriar Lodge in the Valley of Spirits."),
    dungeon("maraudon", accept(7068, uthelnay, "Uthel'nay also wants shadowshard fragments from Maraudon. Take it if you plan that dungeon.")),
    finish(1262, zor, "Zor Lonetree waits in the Valley of Wisdom."),
    accept(7541, zor), finish(7541, zor, "Zor thanks you for your service at once."),
    finish(7732, og("Zilzibin Drumlore", 56.26, 46.68), "Zilzibin Drumlore is in the Drag."),
    finish(3121, og("Neeru Fireblade", 49.47, 50.59), "Neeru Fireblade is in the Cleft of Shadow."),
    accept(3122, og("Neeru Fireblade", 49.47, 50.59), "Neeru's herb pouch goes back to Uzer'i. You see him again at 46."),
    finish(2976, og("Belgrom Rockmaul", 75.23, 34.24), "Belgrom Rockmaul is in the Valley of Honor."),
    action("boat", P.orgrimmarZeppelin, "Leave Orgrimmar and take the zeppelin to Grom'gol.", { name = "Orgrimmar - Grom'gol" }),
  }))
end

-- Stranglethorn at 44: Grom'gol's last tasks, Booty Bay's pirates and errands, and the southern jungle.
do
  local st = on.stv
  local tethis = st("Tethis", 28.5, 43.7)
  local bloads = st("Privateer Bloads", 26.76, 76.38)
  local oglethorpe = st("Oglethorpe Obnoticus", 28.36, 76.35)
  local fin = st("Fin Fizracket", 27.61, 76.74)
  local crazz = st("First Mate Crazz", 28.1, 76.22)
  local smotts = st("Captain Hecklebury Smotts", 26.69, 73.61)
  local correspondence = st("Bloodsail Correspondence", 27.28, 69.52)
  local deeg = st("Deeg", 26.92, 77.35)
  local dizzy = st("Dizzy One-Eye", 28.59, 75.9)
  local shaky = st("\"Shaky\" Phillipe", 26.9, 73.59)
  local slim = st("Whiskey Slim", 27.14, 77.45)
  local unbagwa = st("Witch Doctor Unbagwa", 35.27, 60.41)

  need(586, "Speaking with Gan'zulah", 46, 30, 584)
  need(571, "Mok'thardin's Enchantment", 41, 33, 572)
  need(573, "Mok'thardin's Enchantment", 44, 33, 571)
  need(588, "The Fate of Yenniku", 45, 30, { 585, 586 })
  need(589, "The Singing Crystals", 45, 30, 588)
  need(617, "Akiris by the Bundle", 43, 38)
  need(621, "Zanzil's Secret", 44, 35)
  need(606, "Scaring Shaky", 41, 30)
  need(607, "Return to MacKinley", 41, 30, 606)
  need(609, "Voodoo Dues", 44, 30, 607)
  need(348, "Stranglethorn Fever", 45, 40)
  need(595, "The Bloodsail Buccaneers", 41, 37)
  need(597, "The Bloodsail Buccaneers", 41, 37, 595)
  need(599, "The Bloodsail Buccaneers", 41, 37, 597)
  need(604, "The Bloodsail Buccaneers", 43, 37, 599)
  need(608, "The Bloodsail Buccaneers", 45, 37, 604)
  need(587, "Up to Snuff", 41, 37, 595)
  need(576, "Keep An Eye Out", 42, 37, 595)
  need(8551, "The Captain's Chest", 47, 40)
  need(624, "Cortello's Riddle", 43, 35)
  B.quest[624].startItem = B.quest[624].startItem or 4056
  need(580, "Whiskey Slim's Lost Grog", 50, 40)
  need(1119, "Zanzil's Mixture and a Fool's Stout", 44, 35, { 621, 1118 })

  H.chapter("stv-44", "Stranglethorn: Booty Bay and the Southern Jungle", M.stv, 44, 45, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    qdb,
  }, { "swamp-45", "searing-45" }, {
    accept(586, P.cauldron, "The bubbling cauldron in Grom'gol speaks again: it wants more Skullsplitters dead and Ana'thek's armor."),
    accept(571, P.mokthardin),
    objective(197, tethis, "Ride south-west to the ruins where Tethis, a big raptor, hunts. Kill him for his talon.", "Talon of Tethis"),
    action("goto", st(nil, 45.0, 44.0), "Ride east across the jungle to the Skullsplitter ruins."),
    objective(586, st(nil, 46.7, 44.0), "Kill Skullsplitter Hunters, Headhunters and Berserkers. Ana'thek the Cruel guards the top of the ruins and wears the armor.",
      "8 Skullsplitter Hunters", "6 Skullsplitter Headhunters", "4 Skullsplitter Berserkers", "Broken Armor of Ana'thek"),
    action("goto", P.hemet, "Ride north to Nesingwary's Expedition."),
    finish(197, P.hemet), accept(208, P.hemet, "Hemet's last target is King Bangalash, the white tiger."),
    action("goto", P.cauldron, "Ride south to Grom'gol."),
    finish(586, P.cauldron), accept(588, P.cauldron),
    finish(588, P.kinweelay), accept(589, P.kinweelay),
    taxi("fly", P.thysta, "Booty Bay, Stranglethorn", "Fly to Booty Bay."),
    accept(617, bloads, "Privateer Bloads wants akiris reeds."),
    finish(2767, oglethorpe, "If you escorted OOX-22/FE, report to Oglethorpe Obnoticus, the gnome who built it."),
    finish(1118, P.crank, "Give Crank Fizzlebub Kravel's scheme."),
    accept(621, P.crank),
    accept(606, P.mackinley), accept(348, fin, "Fin Fizracket wants the heart of a savage gorilla."),
    accept(595, crazz, "First Mate Crazz wants the cove north of town scouted."),
    accept(8551, smotts, "Captain Hecklebury Smotts, near the tunnel into town, lost his chest to a crocolisk."),
    finish(595, correspondence, "Walk north out of town to the shore camp and read the Bloodsail papers on the barrel."),
    accept(597, correspondence),
    action("goto", crazz, "Go back into Booty Bay."),
    finish(597, crazz), accept(599, crazz),
    accept(587, deeg, "Deeg, in the inn, wants Bloodsail snuff."),
    finish(599, P.seahorn), accept(604, P.seahorn),
    accept(576, dizzy, "Dizzy One-Eye lost his glass eye to the pirates."),
    action("goto", st(nil, 27.5, 82.0), "Leave town by the south tunnel to the Wild Shore."),
    along(objective(604, st(nil, 27.1, 83.1), "Kill Bloodsail Swashbucklers along the Wild Shore. The charts and orders lie in the pirates' camp.",
      "10 Bloodsail Swashbucklers", "Bloodsail Charts", "Bloodsail Orders"), 587, 576),
    along(objective(587, st(nil, 28.9, 82.7), "Bloodsail pirates also carry snuff.", "15 Snuff"), 604, 576),
    along(objective(576, st(nil, 28.9, 82.7), "One of them has Dizzy's eye.", "Dizzy's Eye"), 604, 587),
    action("goto", st(nil, 33.0, 65.3), "Go back through Booty Bay and ride north up the road to Mistvale Valley."),
    along(objective(606, st(nil, 33.0, 65.3), "Kill Elder Mistvale Gorillas for their giblets.", "5 Mistvale Giblets"), 571, 348),
    along(objective(571, st(nil, 33.0, 65.3), "The same gorillas give the aged sinew.", "Aged Gorilla Sinew"), 606),
    note(objective(348, unbagwa, "Bring 10 Gorilla Fangs from the gorillas to Witch Doctor Unbagwa in the valley. He calls out Mokk the Savage; kill him for his heart.",
      "Heart of Mokk"), "The classic fang hand-in is not in the Forever client; check how Unbagwa calls Mokk."),
    action("goto", shaky, "Ride back to Booty Bay."),
    finish(606, shaky, "\"Shaky\" Phillipe waits near the tunnel into town."), accept(607, shaky),
    finish(607, P.mackinley), accept(609, P.mackinley),
    finish(604, P.seahorn), accept(608, P.seahorn, "Seahorn wants the three Bloodsail captains dead. Bring a group for their ships."),
    finish(576, dizzy), finish(348, fin),
    taxi("fly", P.gringer, "Grom'gol, Stranglethorn", "Fly to Grom'gol."),
    finish(571, P.mokthardin), accept(573, P.mokthardin),
    objective(208, st("King Bangalash", 38.2, 35.6), "King Bangalash and his panthers hold the hill south-east of Grom'gol. Kill the panthers first.",
      "Head of Bangalash"),
    objective(589, st(nil, 43.1, 47.8), "Kill Ironjaw Basilisks around the Crystalvein Mine to the south-east for Pulsing Blue Shards.",
      "3 Pulsing Blue Shard"),
    action("goto", st(nil, 37.0, 54.0), "Ride south-west to the coast across from Zanzil's islands."),
    along(objective(621, st(nil, 37.3, 55.1), "Kill Zanzil's naga, zombies and witch doctors on the islands for his mixture.", "12 Zanzil's Mixture"), 609),
    part(609, 1, st("Maury \"Club Foot\" Wilkins", 35.3, 51.3), "Maury \"Club Foot\" Wilkins camps on the islet to the north-west.", "Maury's Clubbed Foot"),
    part(609, 2, st("Jon-Jon the Crow", 34.9, 51.8), "Jon-Jon the Crow stands beside Maury.", "Jon-Jon's Golden Spyglass"),
    part(609, 3, st("Chucky \"Ten Thumbs\"", 40.0, 58.2), "Chucky \"Ten Thumbs\" is on the big island to the south-east.", "Chucky's Huge Ring"),
    note(objective(8551, st("Gorlash", 37.0, 69.7), "Gorlash, a big crocolisk, swims in the bay south of the islands. Kill it for Smotts' chest.",
      "Smotts' Chest"), "Gorlash is level 47; check whether it is elite in Forever."),
    action("goto", st(nil, 30.5, 88.0), "Ride south along the coast to the Bloodsail ships off Jaguero Isle."),
    withItem(4056, accept(624, st(nil, 30.7, 88.6), "If you found Cortello's Riddle on the cliffs or from a pirate, read it.")),
    note(objective(608, st("Fleet Master Firallon", 30.6, 90.6), "Board the three Bloodsail ships and kill Captain Stillwater, Captain Keelhaul and Fleet Master Firallon. Use Next if you have no group.",
      "Captain Stillwater", "Captain Keelhaul", "Fleet Master Firallon"), "The captains are elite in the classic data; check in game."),
    action("goto", st(nil, 26.3, 62.6), "Ride north past Booty Bay to the naga beach below Mistvale Valley."),
    along(objective(573, st(nil, 26.3, 62.6), "Kill Naga Explorers on the beach and fill the vial at the holy spring in the hills above.",
      "10 Naga Explorers", "Holy Spring Water"), 617),
    along(objective(617, st(nil, 26.3, 62.6), "The naga also carry akiris reeds.", "10 Bundle of Akiris Reed"), 573),
    action("goto", P.crank, "Ride back south to Booty Bay."),
    finish(8551, smotts), finish(609, P.mackinley), finish(617, bloads), finish(587, deeg), finish(608, P.seahorn),
    finish(621, P.crank), accept(1119, P.crank, "Crank's stout goes to Kravel in the Shimmering Flats. You pass there at 46."),
    accept(580, slim, "Whiskey Slim's grog washed up in the Hinterlands. You go there at 48."),
    taxi("fly", P.gringer, "Grom'gol, Stranglethorn", "Fly to Grom'gol."),
    finish(573, P.mokthardin), finish(589, P.kinweelay),
    action("goto", P.hemet, "Ride north to Nesingwary's Expedition."),
    finish(208, P.hemet),
  })
end

-- Swamp of Sorrows at 45: the Fallen Hero, Misty Reed Strand and Stagalbog, then back to Camp Mojache.
do
  local sw = on.swamp
  local hero = sw("Fallen Hero of the Horde", 34.29, 66.14)
  local ruag = sw("Dispatch Commander Ruag", 47.79, 54.94)
  local bengor = sw("Bengor", 44.97, 57.37)
  local scroll = sw("A Soggy Scroll", 22.87, 48.19)

  need(2784, "Fall From Grace", 50, 45)
  need(2621, "The Disgraced One", 50, 45, 2784)
  need(2622, "The Missing Orders", 50, 45, 2621)
  need(2623, "The Swamp Talker", 55, 45, 2622)
  -- The Alliance files register these with the Alliance prerequisite (2783); the game takes either.
  B.q(2801, "A Tale of Sorrow", 57, 45, 2623)
  need(1429, "The Atal'ai Exile", 44, 38, 1424)
  need(699, "Lack of Surplus", 42, 35, 698)
  need(1422, "Threat From the Sea", 45, 35, 699)
  need(1426, "Threat From the Sea", 43, 35, 1422)
  need(1427, "Threat From the Sea", 43, 35, 1426)
  need(1428, "Continued Threat", 45, 35, 1427)
  need(625, "Cortello's Riddle", 43, 35, 624)
  need(3123, "Testing the Vessel", 47, 40, 3122)
  need(3380, "The Sunken Temple", 51, 46)

  H.chapter("swamp-45", "Swamp of Sorrows: The Fallen Hero and Misty Reed Strand", M.swamp, 45, 46, {
    "https://www.wowhead.com/forever/zone=8/swamp-of-sorrows",
    qdb,
  }, { "tanaris-46", "searing-45" }, {
    taxi("fly", P.thysta, "Stonard, Swamp of Sorrows", "Fly from Grom'gol to Stonard."),
    action("goto", hero, "Ride south-west out of Stonard to the Fallen Hero of the Horde, who waits at the edge of the swamp near the Blasted Lands road."),
    accept(2784, hero),
    objective(2784, hero, "Listen to the Fallen Hero's story.", "Fallen Hero's story"),
    finish(2784, hero), accept(2621, hero),
    action("goto", ruag, "Ride back to Stonard."),
    finish(2621, ruag, "Dispatch Commander Ruag is in the great hall."), accept(2622, ruag),
    finish(2622, bengor, "Bengor stands beside Dar at the town's west gate."), accept(2623, bengor),
    accept(1429, P.felzerul, "Fel'zerul wants the artifacts you found taken to an Atal'ai exile in the Hinterlands. You go there at 48."),
    action("goto", P.tokkar, "Ride south-east to Tok'Kar's camp at Misty Reed Strand."),
    accept(699, P.tokkar),
    objective(699, sw(nil, 84.2, 34.3), "Ride north along the eastern shore and kill Sawtooth Snappers for their claws.", "6 Sawtooth Snapper Claw"),
    finish(699, P.tokkar), accept(1422, P.tokkar),
    finish(1422, P.katar, "Katar stands at the water's edge beside Tok'Kar."), accept(1426, P.katar),
    objective(1426, sw(nil, 86.0, 84.9), "Kill Marsh Murlocs, Inkspewers and Flesheaters along the strand.",
      "10 Marsh Murlocs", "10 Marsh Inkspewers", "10 Marsh Flesheaters"),
    finish(1426, P.katar), accept(1427, P.katar), finish(1427, P.tokkar), accept(1428, P.katar),
    action("goto", sw(nil, 64.5, 86.0), "Ride west along the coast to Stagalbog and its cave."),
    along(objective(1428, sw(nil, 63.1, 85.0), "Kill Marsh Inkspewers, Flesheaters and Oracles around Stagalbog and inside the cave.",
      "10 Marsh Inkspewers", "10 Marsh Flesheaters", "10 Marsh Oracles"), 2623),
    note(objective(2623, sw("Swamp Talker", 62.6, 88.1), "The Swamp Talker, a level 50 elite, waits at the back of Stagalbog Cave. Bring a group for him and take the Warchief's orders.",
      "Warchief's Orders"), "Elite in the classic data; use Next if you have no group."),
    finish(1428, P.katar, "Ride back east to Katar."),
    action("goto", hero, "Ride west across the swamp to the Fallen Hero."),
    finish(2623, hero), accept(2801, hero),
    objective(2801, hero, "Listen to the rest of his tale.", "Fallen Hero's tale"),
    finish(2801, hero),
    finish(624, scroll, "If you carry Cortello's Riddle, ride north-west to the soggy scroll under the bridge."),
    accept(625, scroll, "The next clue is in Dustwallow Marsh. Keep it."),
    action("hearth", P.greul, "Hearth to Camp Mojache.", mojache),
    finish(3122, P.uzeri, "Give Witch Doctor Uzer'i Neeru's pouch."),
    accept(3123, P.uzeri, "Uzer'i's muisek vessel is tested on wildkin in the Hinterlands. You go there at 48."),
  })
end

-- Tanaris at 46: the Shimmering Flats errands, Lost Rigger Cove, the southern desert and
-- Zul'Farrak's pickups, then Brackenwall's Onyxia chain.
do
  local tn, dm, fl = on.tanaris, on.dustwallow, on.needles
  local kravel = fl("Kravel Koalbeard", 77.79, 77.27)
  local pitBoss = fl("Gnome Pit Boss", 77.56, 76.94)
  local razzeric = fl("Razzeric", 80.33, 76.09)
  local wizzle = fl("Wizzle Brassbolts", 78.14, 77.12)
  local shreev = tn("Shreev", 50.96, 27.24)
  local marin = tn("Marin Noggenfogger", 51.81, 28.66)
  local sprinkle = tn("Sprinkle", 51.06, 26.87)
  local andi = tn("Andi Lynn", 52.82, 27.4)
  local trenton = tn("Trenton Lighthammer", 51.41, 28.75)
  local poster = tn("Wanted Poster", 51.83, 27.04)
  local modiste = tn("Haughty Modiste", 66.56, 22.27)
  local chief = tn("Security Chief Bilgewhizzle", 67.06, 23.89)
  local tooga = tn("Tooga", 31.8, 74.15)
  local torta = tn("Torta", 66.58, 25.67)
  local robot = tn("Homing Robot OOX-17/TN", 60.23, 64.72)
  local musty = dm("Musty Scroll", 31.1, 66.14)

  need(1120, "Get the Gnomes Drunk", 44, 35, 1119)
  need(1188, "Safety First", 41, 29, 1187)
  need(2770, "Gahz'rilla", 50, 40)
  need(3362, "Thistleshrub Valley", 50, 45)
  need(992, "Gadgetzan Water Survey", 46, 38)
  need(82, "Noxious Lair Investigation", 47, 39, 992)
  need(2875, "WANTED: Andre Firebeard", 45, 40)
  need(2605, "The Thirsty Goblin", 49, 44)
  need(2606, "In Good Taste", 49, 44, 2605)
  need(2641, "Sprinkle's Secret Ingredient", 49, 44, 2606)
  need(5863, "The Dunemaul Compound", 49, 44)
  need(8365, "Pirate Hats Ahoy!", 45, 40)
  need(8366, "Southsea Shakedown", 45, 40)
  need(2873, "Stoley's Shipment", 45, 40, 2872)
  need(2874, "Deliver to MacKinley", 45, 40, 2873)
  need(2876, "Ship Schedules", 45, 40)
  B.quest[2876].startItem = B.quest[2876].startItem or 9250
  need(3161, "Gahz'ridian", 48, 43)
  need(1560, "Tooga's Quest", 50, 40)
  need(3527, "The Prophecy of Mosh'aru", 47, 40, 3520)
  need(10, "The Scrimshank Redemption", 48, 39, 82)
  need(110, "Insect Part Analysis", 48, 39, 10)
  need(113, "Insect Part Analysis", 48, 39, 110)
  need(32, "Rise of the Silithid", 48, 39, 113)
  need(351, "Find OOX-17/TN!", 48, 43)
  B.quest[351].startItem = B.quest[351].startItem or 8623
  need(648, "Rescue OOX-17/TN!", 48, 43, 351)
  need(3042, "Troll Temper", 45, 40)
  need(2768, "Divino-matic Rod", 47, 40)
  need(2865, "Scarab Shells", 45, 40, 2864)
  need(864, "Return to Apothecary Zinge", 46, 38, 654)
  need(4787, "The Ancient Egg", 50, 40, 3527)
  need(1170, "The Brood of Onyxia", 43, 38, 1169)
  need(1171, "The Brood of Onyxia", 43, 38, 1170)
  need(1172, "The Brood of Onyxia", 45, 38, 1171)
  need(1173, "Challenge Overlord Mok'Morokk", 45, 38, 1172)
  need(626, "Cortello's Riddle", 51, 35, 625)

  local others = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK" }
  local bluff = { "DRUID", "PALADIN" }

  H.chapter("tanaris-46", "Tanaris: Lost Rigger Cove and the Southern Desert", M.tanaris, 46, 48, {
    "https://www.wowhead.com/forever/zone=440/tanaris",
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    qdb,
  }, { "hinterlands-48", "searing-45", "blasted-47", "ungoro-48" }, cat({
    accept(3380, P.uzeri, "Before you leave Camp Mojache, Witch Doctor Uzer'i sends you to Marvon Rivetseeker in Tanaris."),
    taxi("fly", P.shyn, "Gadgetzan, Tanaris", "Fly from Camp Mojache to Gadgetzan."),
    action("goto", fl(nil, 77.5, 80.0), "Ride north out of Gadgetzan to the Mirage Raceway in the Shimmering Flats."),
    finish(1119, kravel, "Give Kravel Koalbeard Crank's stout."), accept(1120, kravel),
    finish(1120, pitBoss, "Hand the stout to the gnome pit boss."),
    finish(1187, razzeric, "Give Razzeric his Seaforium Booster."), accept(1188, razzeric),
    dungeon("zul-farrak", accept(2770, wizzle, "Wizzle Brassbolts wants a scale from Gahz'rilla in Zul'Farrak. Take it if you plan that dungeon.")),
    action("goto", P.tranrek, "Ride back south to Gadgetzan."),
    finish(1188, shreev, "Give Shreev the booster."),
    accept(3362, P.tranrek), accept(992, P.fizzledowser, "Senior Surveyor Fizzledowser stands by the water tower."),
    action("sethearth", P.fizzgrimble, "Bind at the Gadgetzan inn.", gadgetzan),
    accept(2875, poster, "Read the wanted poster by the inn."),
    accept(2605, marin, "Marin Noggenfogger, the town's boss, wants a dew gland."),
    accept(5863, andi, "Andi Lynn wants the Dunemaul ogres cleared."),
    accept(864, P.bilgewhizzle, "Bilgewhizzle sends your sealed testing kit back to Apothecary Zinge in the Undercity. You go there at 48."),
    objective(992, tn(nil, 39.0, 29.2), "Ride west to the pool at Sandsorrow Watch and use the dowsing widget beside it.", "Tapped Dowsing Widget"),
    finish(992, P.fizzledowser, "Ride back to Gadgetzan."), accept(82, P.fizzledowser),
    action("goto", P.stoley, "Ride north-east to Steamwheedle Port."),
    accept(8365, modiste, "Haughty Modiste wants pirate hats."), accept(8366, chief), accept(2873, P.stoley),
    action("goto", tn(nil, 72.0, 46.0), "Ride south along the coast to Lost Rigger Cove."),
    along(objective(8366, tn(nil, 73.3, 46.0), "Work through the Southsea pirates in the cove.",
      "10 Southsea Pirates", "10 Southsea Freebooters", "10 Southsea Dock Workers", "10 Southsea Swashbucklers"), 8365, 2873),
    along(objective(8365, tn(nil, 73.3, 46.0), "Every pirate can drop a hat.", "20 Southsea Pirate Hat"), 8366),
    objective(2873, tn("Stolen Cargo", 72.2, 46.8), "Stoley's shipment is in a crate of stolen cargo in the cove.", "Stoley's Shipment"),
    objective(2875, tn("Andre Firebeard", 73.4, 47.1), "Andre Firebeard holds the ship's upper deck at the cove's mouth.", "Firebeard's Head"),
    withItem(9250, accept(2876, nil, "If a pirate dropped a ship schedule, read it.")),
    action("goto", P.marvon, "Ride west across the desert to Marvon Rivetseeker's camp at the Broken Pillar."),
    finish(3380, P.marvon), accept(3161, P.marvon, "Marvon lends you a detector for Gahz'ridian ornaments."),
    action("goto", tn(nil, 35.0, 44.0), "Ride west to the Noxious Lair, the silithid mound in the western dunes."),
    objective(82, tn(nil, 33.6, 44.4), "Kill Centipaar silithids in and around the lair for insect parts.",
      "5 Centipaar Insect Parts"),
    objective(5863, tn(nil, 41.2, 54.1), "Ride south-east to the Dunemaul Compound. Kill Brutes and Enforcers, then Gor'marok the Ravager in the middle.",
      "10 Dunemaul Brutes", "10 Dunemaul Enforcers", "Gor'marok the Ravager"),
    objective(3161, tn(nil, 46.7, 65.4), "South of the compound, wear Marvon's detector and dig up Gahz'ridian ornaments in the sand.",
      "30 Gahz'ridian Ornament"),
    action("goto", tn(nil, 29.0, 65.0), "Ride west to Thistleshrub Valley."),
    along(objective(3362, tn(nil, 29.0, 64.8), "Kill Gnarled Thistleshrubs and Thistleshrub Rootshapers.",
      "8 Gnarled Thistleshrubs", "8 Thistleshrub Rootshapers"), 2605),
    objective(2605, tn(nil, 28.5, 66.4), "Thistleshrub Dew Collectors drop the dew gland.", "Laden Dew Gland"),
    accept(1560, tooga, "Tooga the turtle waits at the south end of the valley. He wants to go home."),
    note(action("goto", torta, "Lead Tooga all the way north-east to his wife Torta at Steamwheedle Port. Keep him close; he stops if you run ahead."),
      "A long walk; how Tooga follows needs an in-game check."),
    objective(1560, torta, "Bring Tooga to Torta.", "Tooga brought home"),
    finish(1560, torta),
    finish(2875, chief), finish(8366, chief), finish(2876, chief),
    finish(2873, P.stoley), accept(2874, P.stoley, "Stoley sends a bottle to MacKinley in Booty Bay. You go there at 50."),
    finish(8365, modiste), finish(3520, P.yehkinya),
    dungeon("zul-farrak", accept(3527, P.yehkinya, "Yeh'kinya wants two tablets from Zul'Farrak. Take it if you plan that dungeon.")),
    action("hearth", P.fizzgrimble, "Hearth to Gadgetzan.", gadgetzan),
    finish(2605, marin), accept(2606, marin), finish(2606, sprinkle), accept(2641, sprinkle, "Sprinkle's violet tragan grows in the Hinterlands. Keep it for 48."),
    finish(82, P.pestlezugg, "Give Alchemist Pestlezugg the insect parts."),
    accept(10, P.fizzledowser),
    finish(3362, P.tranrek), finish(5863, andi),
    finish(3161, P.marvon, "Ride south to Marvon with the ornaments."),
    objective(10, tn("Scrimshank's Surveying Gear", 56.0, 71.2), "Ride south-east into the Gaping Chasm and find Scrimshank's surveying gear in the silithid tunnels.",
      "Scrimshank's Surveying Gear"),
    withItem(8623, accept(351, robot, "If a silithid dropped the OOX-17/TN beacon, use it and find the robot near the chasm.")),
    finish(351, robot),
    note(accept(648, robot, "Escort OOX-17/TN north to Steamwheedle Port."), "Escort route needs an in-game check."),
    action("goto", P.stoley, "Walk north with the robot to Steamwheedle Port. Fight off the ambushes."),
    objective(648, P.stoley, "Stay with the robot until it reaches the port.", "Escort OOX-17/TN"),
    action("goto", P.fizzledowser, "Ride back to Gadgetzan."),
    finish(10, P.fizzledowser), accept(110, P.fizzledowser),
    finish(110, P.pestlezugg), accept(113, P.pestlezugg),
    finish(113, P.fizzledowser), accept(32, P.fizzledowser, "The report goes to Zilzibin Drumlore in Orgrimmar."),
    dungeon("zul-farrak", accept(3042, trenton, "Trenton Lighthammer wants troll temper from Zul'Farrak's trolls.")),
    dungeon("zul-farrak", accept(2768, P.bilgewhizzle, "Bilgewhizzle wants his divino-matic rod back from Sergeant Bly in Zul'Farrak.")),
    dungeon("zul-farrak", accept(2865, P.tranrek, "Tran'rek wants uncracked scarab shells from Zul'Farrak.")),
    dungeon("zul-farrak", finish(3042, trenton, "After Zul'Farrak, hand in your quests in Gadgetzan.")),
    dungeon("zul-farrak", finish(2768, P.bilgewhizzle)),
    dungeon("zul-farrak", finish(2865, P.tranrek)),
    dungeon("zul-farrak", finish(3527, P.yehkinya, "Ride to Steamwheedle Port with Theka's and Velratha's tablets.")),
    dungeon("zul-farrak", accept(4787, P.yehkinya, "Yeh'kinya now wants an ancient egg from Jintha'alor in the Hinterlands. You go there at 48.")),
    dungeon("zul-farrak", finish(2770, wizzle, "Ride north to the Shimmering Flats with Gahz'rilla's scale.")),
    taxi("fly", P.bulkrek, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village."),
    accept(1170, P.drazzilb), finish(1170, P.mokmorokk), accept(1171, P.mokmorokk),
    finish(1171, P.drazzilb), accept(1172, P.drazzilb),
    finish(625, musty, "If you carry Cortello's Riddle, ride south to the musty scroll in the south-west of the marsh."),
    accept(626, musty, "The last clue points to the Hinterlands. Keep it for 48."),
    action("goto", dm(nil, 52.0, 72.0), "Ride east to the dragon caves on the Wyrmbog's east side."),
    note(objective(1172, dm(nil, 55.1, 74.0), "Ride east into the Wyrmbog's dragon caves and destroy the Eggs of Onyxia. Watch for the whelp handlers.",
      "5 Eggs of Onyxia destroyed"), "Check the cave guards' strength in game."),
    dungeon("zul-farrak", finish(2846, P.tabetha, "Give Tabetha the Tiara of the Deep on your way north.")),
    action("goto", P.drazzilb, "Ride north to Brackenwall Village."),
    finish(1172, P.drazzilb), accept(1173, P.mokmorokk),
    note(objective(1173, P.mokmorokk, "Challenge Overlord Mok'Morokk and beat him in a fair fight.", "Mok'Morokk defeated"),
      "He is level 45 with a lot of health; check in game."),
    finish(1173, P.drazzilb),
    only(taxi("fly", P.shardi, "Thunder Bluff, Mulgore", "Druids and paladins: fly to Thunder Bluff to train."), { class = bluff }),
  }, train(bluffOnly, 48), {
    only(taxi("fly", P.tal, "Orgrimmar, Durotar", "Fly on to Orgrimmar."), { class = bluff }),
    only(taxi("fly", P.shardi, "Orgrimmar, Durotar", "Fly to Orgrimmar."), { class = others }),
  }))
end

-- The Hinterlands at 48: Orgrimmar and the Undercity on the way, Revantusk Village, the Vilebranch
-- temples, Jintha'alor, and a western loop through Quel'Danil and the Witherbark camps.
do
  local hl, uc = on.hinterlands, on.undercity
  local dran = og("Dran Droffers", 59.49, 36.57)
  local malton = og("Malton Droffers", 59.65, 36.94)
  local zilzibin = og("Zilzibin Drumlore", 56.26, 46.68)
  local oran = uc("Oran Snakewrithe", 73.06, 32.85)
  local zinge = uc("Apothecary Zinge", 50.14, 67.97)
  local garrett = uc("Michael Garrett", 63.2, 48.6)
  local lydon = on.hillsbrad("Apothecary Lydon", 61.44, 19.06)
  local zarise = on.hillsbrad("Zarise", 60.1, 18.6)
  local bottle = hl("Venom Bottle", 23.54, 58.8)
  local rinji = hl("Rin'ji", 30.73, 46.9)
  local secret = hl("Rin'ji's Secret", 86.3, 59.01)
  local gorkas = hl("Gorkas", 81.7, 81.8)
  local slagtree = hl("Smith Slagtree", 77.23, 80.13)
  local lard = hl("Lard", 78.14, 81.38)
  local katoom = hl("Katoom the Angler", 80.33, 81.54)
  local yayojin = hl("Mystic Yayo'jin", 78.8, 78.25)
  local otho = hl("Otho Moji'ko", 79.38, 79.08)
  local markhor = hl("Huntsman Markhor", 79.16, 79.53)
  local torntusk = hl("Primal Torntusk", 78.2, 81.18)
  local callToArms = hl("Call to Arms!", 79.08, 78.99)
  local elder = hl("Elder Torntusk", 59.69, 77.84)
  local exile = hl("Atal'ai Exile", 33.75, 75.21)
  local treasure = hl("Cortello's Treasure", 80.79, 46.82)
  local ooxRobot = hl("Homing Robot OOX-09/HL", 49.35, 37.66)

  need(649, "Ripple Recovery", 48, 42)
  need(650, "Ripple Recovery", 48, 42, 649)
  need(2995, "Lines of Communication", 47, 42)
  need(2933, "Venom Bottles", 43, 40)
  need(2934, "Undamaged Venom Sac", 45, 40, 2933)
  need(77, "A Sticky Situation", 48, 42, 650)
  need(81, "Ripple Delivery", 48, 42, 77)
  need(2742, "Rin'ji is Trapped!", 47, 42)
  need(2782, "Rin'ji's Secret", 47, 42, 2742)
  need(8273, "Oran's Gratitude", 47, 42, 2782)
  need(7839, "Vilebranch Hooligans", 48, 44)
  need(7840, "Lard Lost His Lunch", 49, 44)
  need(7815, "Snapjaws, Mon!", 50, 44)
  need(7844, "Cannibalistic Cousins", 48, 44)
  need(7828, "Stalking the Stalkers", 48, 44)
  need(7829, "Hunt the Savages", 48, 44)
  need(7830, "Avenging the Fallen", 48, 44)
  need(7841, "Message to the Wildhammer", 48, 44)
  need(7842, "Another Message to the Wildhammer", 48, 44, 7841)
  need(7861, "Wanted: Vile Priestess Hexx and Her Minions", 51, 46)
  need(7862, "Job Opening: Guard Captain of Revantusk Village", 51, 46)
  need(7849, "Separation Anxiety", 50, 46)
  need(7850, "Dark Vessels", 50, 46)
  need(7845, "Kidnapped Elder Torntusk!", 51, 46)
  need(7846, "Recover the Key!", 51, 46, 7845)
  need(7847, "Return to Primal Torntusk", 51, 46, 7846)
  need(1444, "Return to Fel'Zerul", 44, 38, 1429)
  need(485, "Find OOX-09/HL!", 48, 43)
  B.quest[485].startItem = B.quest[485].startItem or 8704
  need(836, "Rescue OOX-09/HL!", 48, 43, 485)

  H.chapter("hinterlands-48", "The Hinterlands: Revantusk Village and Jintha'alor", M.hinterlands, 48, 49, {
    "https://www.wowhead.com/forever/zone=47/the-hinterlands",
    qdb,
  }, { "feralas-49", "ungoro-48", "blasted-47" }, cat(train(orgrimmarTrainers, 48), {
    finish(32, zilzibin, "Give Zilzibin Drumlore, in the Drag, the silithid report."),
    accept(649, dran, "Dran Droffers, in the Drag's salvage shop, has a delivery for you."),
    finish(649, malton), accept(650, malton, "Malton sends you to Gilveradin Sunchaser in the Hinterlands."),
    action("boat", P.undercityZeppelin, "Leave Orgrimmar and take the other zeppelin from the tower to Tirisfal Glades. Walk into the Undercity.",
      { name = "Orgrimmar - Undercity" }),
    accept(2995, oran, "Oran Snakewrithe, in the Magic Quarter, wants the Highvale records in the Hinterlands burned."),
    finish(864, zinge, "Apothecary Zinge is in the Apothecarium."),
    action("collect", uc("Auctioneer Rhyker", 60.5, 46.4), "Buy 10 Long Elegant Feathers at the Auction House for a Revantusk quest, if they are cheap. Use Next to skip and loot them from Witherbark Hideskinners instead.",
      { item = 4589, count = 10, name = "Long Elegant Feathers" }),
    taxi("fly", garrett, "Tarren Mill, Hillsbrad", "Fly to Tarren Mill."),
    action("goto", on.hillsbrad(nil, 86.4, 32.0), "Ride east out of Tarren Mill and take the north-east pass into the Hinterlands."),
    finish(650, P.gilveradin, "Gilveradin Sunchaser camps just inside the Hinterlands."),
    accept(77, P.gilveradin),
    accept(2933, bottle, "Ride south to the Witherbark village and take a venom bottle from the trolls' hut."),
    action("goto", rinji, "Ride north to Quel'Danil Lodge, the high elf lodge in the woods."),
    objective(2995, hl("Highvale Records", 32.0, 46.8), "Burn the Highvale Records, Notes and Report inside the lodge's buildings.",
      "Highvale Records burned", "Highvale Notes burned", "Highvale Report burned"),
    accept(2742, rinji, "Rin'ji is held captive in the lodge. Free him."),
    objective(2742, rinji, "Escort Rin'ji out of the lodge. The elves come after you.", "Rin'ji escorted"),
    action("goto", hl(nil, 58.3, 42.4), "Ride east along the road to Skulk Rock, the cave north of the road."),
    objective(77, hl(nil, 58.3, 42.4), "Open the Horde supply crates around the abandoned camp for honey ripple.", "10 Hinterlands Honey Ripple"),
    action("goto", gorkas, "Follow the road south-east to Revantusk Village on the coast."),
    taxi("getfp", gorkas, "Revantusk Village, The Hinterlands", "Learn the Revantusk flight path from Gorkas."),
    accept(7839, slagtree), accept(7840, lard), accept(7815, katoom),
    accept(7844, yayojin), accept(7828, markhor), accept(7829, markhor), accept(7830, markhor),
    objective(580, hl(nil, 77.7, 74.2), "Walk north along the shore to the Pupellyverbos Port wreck and gather Whiskey Slim's bottles.",
      "12 Pupellyverbos Port"),
    objective(7815, hl(nil, 77.6, 65.6), "Kill Saltwater Snapjaws along the coast to the north.", "15 Saltwater Snapjaws"),
    note(objective(7840, hl(nil, 81.0, 60.0), "Lard left his lunch on the island off the coast. The Vilebranch kidnappers there took it.",
      "Lard's Lunch"), "Kidnapper spots are not in the quest data; check the island in game."),
    finish(2742, secret, "Climb the Overlook Cliffs to the east and find Rin'ji's secret on the cliff top."),
    accept(2782, secret, "Rin'ji's tablet goes to Oran Snakewrithe in the Undercity."),
    finish(626, treasure, "If you carry Cortello's last riddle, follow the coast north to his treasure. A strong guardian may appear; use Next if it's too much."),
    action("goto", hl(nil, 70.0, 47.0), "Ride west to the Vilebranch temples of Shaol'watha and Agol'watha."),
    along(objective(7839, hl("Slagtree's Lost Tools", 71.0, 48.7), "Slagtree's tools lie at one of the temples.", "Slagtree's Lost Tools"), 7844),
    objective(7844, hl(nil, 69.5, 47.0), "Kill Vilebranch Scalpers and Soothsayers around the temples.", "30 Vilebranch Scalpers", "15 Vilebranch Soothsayers"),
    along(objective(7828, hl(nil, 65.4, 53.9), "Hunt Silvermane Stalkers and Howlers in the wilds south of the temples.",
      "10 Silvermane Stalkers", "10 Silvermane Howlers"), 7830),
    objective(7830, hl("Razorbeak Skylord", 63.8, 52.0), "A rare Razorbeak Skylord circles these hills. Kill it for its plume when you see it.", "Skylord Plume"),
    along(objective(7829, hl(nil, 61.7, 43.4), "Kill Savage Owlbeasts north of the wolves. Use Uzer'i's vessel on the wildkin you kill.", "20 Savage Owlbeasts"), 3123),
    objective(3123, hl(nil, 61.7, 43.4), "Each wildkin you capture with the vessel counts for Uzer'i.", "10 Wildkin Muisek"),
    withItem(8704, accept(485, ooxRobot, "If a beast dropped the OOX-09/HL beacon, use it and find the robot north of the road by Skulk Rock.")),
    finish(485, ooxRobot),
    note(accept(836, ooxRobot, "Escort OOX-09/HL east to the shore below the Overlook Cliffs."), "Escort route needs an in-game check."),
    action("goto", hl(nil, 79.3, 61.3), "Walk east with the robot to the shore. Fight off the ambushes."),
    objective(836, hl(nil, 79.3, 61.3), "Keep the robot alive until it reaches the shore.", "Escort OOX-09/HL"),
    action("goto", slagtree, "Ride back south to Revantusk Village."),
    finish(7839, slagtree), finish(7840, lard), finish(7815, katoom), finish(7844, yayojin),
    finish(7828, markhor), finish(7829, markhor), finish(7830, markhor),
    accept(7841, otho, "Otho Moji'ko wants the Highvale elves at Quel'Danil thinned out. You go back west for them."),
    accept(7861, callToArms, "Read the Call to Arms board in the middle of the village."), accept(7862, callToArms),
    accept(7849, markhor), accept(7845, torntusk), accept(7850, torntusk),
    taxi("fly", gorkas, "Tarren Mill, Hillsbrad", "Fly to Tarren Mill."),
    finish(2933, lydon, "Give Apothecary Lydon the venom bottle."), accept(2934, lydon),
    action("goto", P.gilveradin, "Ride back east through the pass into the Hinterlands."),
    finish(77, P.gilveradin, "Give Gilveradin the honey."), accept(81, P.gilveradin, "The barrel goes to Dran Droffers in Orgrimmar."),
    objective(7841, hl(nil, 32.5, 47.4), "Kill Highvale Outrunners, Scouts, Marksmen and Rangers around Quel'Danil Lodge.",
      "15 Highvale Outrunners", "15 Highvale Scouts", "15 Highvale Marksmen", "15 Highvale Rangers"),
    objective(2641, hl("Violet Tragan", 40.8, 59.4), "Ride south-east to the hills by the Hiri'watha ruins and pick a Violet Tragan.", "Violet Tragan"),
    action("collect", hl(nil, 31.8, 58.0), "If you didn't buy them, kill Witherbark Hideskinners in the troll camp to the west for 10 Long Elegant Feathers.",
      { item = 4589, count = 10, name = "Long Elegant Feathers" }),
    objective(2934, hl(nil, 32.7, 72.9), "Ride south to Shadra'Alor and kill Witherbark Broodguards until an undamaged venom sac drops.",
      "Undamaged Venom Sac"),
    finish(1429, exile, "The Atal'ai Exile hides at the south edge of Shadra'Alor."), accept(1444, exile, "The exile's word goes back to Fel'zerul in Stonard."),
    action("goto", hl(nil, 62.0, 75.0), "Ride east to Jintha'alor, the Vilebranch city on the big hill."),
    along(objective(7862, hl(nil, 65.0, 76.0), "Kill Vilebranch Berserkers, Shadow Hunters, Blood Drinkers and Soul Eaters on the lower terraces.",
      "20 Vilebranch Berserkers", "20 Vilebranch Shadow Hunters", "20 Vilebranch Blood Drinkers", "20 Vilebranch Soul Eaters"), 7850, 7849),
    along(objective(7850, hl(nil, 65.5, 74.3), "Pick up the Vessels of Tainted Blood on the terraces.", "10 Vessel of Tainted Blood"), 7862),
    part(7849, 1, hl("Pile of Skulls", 58.6, 64.8), "Search the pile of skulls by the ooze pools north of the city for Malkhor's skull.",
      "Huntsman Malkhor's Skull"),
    part(7849, 2, hl("Pile of Bones", 62.1, 75.3), "His bones are in a pile among the wolves on the terraces.", "Huntsman Malkhor's Bones"),
    finish(7845, elder, "Elder Torntusk is chained near the top of the city."), accept(7846, elder),
    dungeon("zul-farrak", objective(4787, hl("Ancient Egg", 57.6, 86.8), "The ancient egg sits in a nest on the south side of the city.", "Ancient Egg")),
    objective(7846, hl("Hitah'ya the Keeper", 57.3, 86.6), "Kill Hitah'ya the Keeper on the south side of the city for the shackle key.", "Shackle Key"),
    finish(7846, elder), accept(7847, elder),
    note(objective(7861, hl("Vile Priestess Hexx", 59.5, 78.3), "Kill Vilebranch Aman'zasi Guards on the top terrace, then Vile Priestess Hexx at the altar. Bring a partner for Hexx.",
      "Vile Priestess Hexx", "20 Vilebranch Aman'zasi Guards"), "Check whether Hexx is elite in Forever."),
    action("goto", torntusk, "Ride back east to Revantusk Village."),
    finish(7862, torntusk), finish(7861, torntusk), finish(7847, torntusk), finish(7850, torntusk), finish(7849, markhor),
    finish(7841, otho),
    accept(7842, otho, "If you have ten Long Elegant Feathers, take Otho's next task and hand them over at once. If not, use Next twice."),
    finish(7842, otho),
    taxi("fly", gorkas, "Tarren Mill, Hillsbrad", "Fly to Tarren Mill."),
    finish(2934, lydon),
    taxi("fly", zarise, "Undercity, Tirisfal", "Fly to the Undercity."),
    finish(2995, oran), finish(2782, oran), accept(8273, oran), finish(8273, oran, "Oran thanks you at once."),
    action("hearth", P.fizzgrimble, "Hearth to Gadgetzan.", gadgetzan),
    finish(2641, on.tanaris("Sprinkle", 51.06, 26.87), "Give Sprinkle the violet tragan."),
    dungeon("zul-farrak", finish(4787, P.yehkinya, "Ride to Steamwheedle Port and give Yeh'kinya the ancient egg.")),
  }))
end

-- Feralas and Un'Goro at 49: Uzer'i's muisek vessel, the Forgotten Coast giants and the
-- Northspring harpies, a first look at Un'Goro, then the boat from Ratchet to Booty Bay.
do
  local fe, ug = on.feralas, on.ungoro
  local talo = fe("Talo Thornhoof", 76.18, 43.83)
  local zorbin = fe("Zorbin Fandazzle", 44.81, 43.42)
  local torwa = ug("Torwa Pathfinder", 71.64, 75.96)
  local raft = ug("A Wrecked Raft", 63.02, 68.6)
  local pack = ug("A Small Pack", 63.11, 69.06)
  local linken = ug("Linken", 44.66, 8.1)
  local williden = ug("Williden Marshal", 43.95, 7.14)
  local gryfe = ug("Gryfe", 45.2, 5.8)
  local boorand = on.barrens("Innkeeper Boorand Plainswind", 52.0, 29.9)
  local devrak = on.barrens("Devrak", 51.5, 30.3)

  need(3063, "Vengeance on the Northspring", 50, 45)
  need(3062, "Dark Heart", 50, 45)
  need(7734, "Improved Quality", 48, 40, 2822)
  need(3124, "Hippogryph Muisek", 47, 40, 3123)
  need(3125, "Faerie Dragon Muisek", 45, 40, 3124)
  need(3126, "Treant Muisek", 50, 40, 3125)
  need(3127, "Mountain Giant Muisek", 50, 40, 3126)
  need(3128, "Natural Materials", 50, 40)
  need(3129, "Weapons of Spirit", 50, 40, { 3127, 3128 })
  need(7003, "Zapped Giants", 48, 45)
  -- The Alliance files register this with the Alliance prerequisite (3445); the game takes either.
  B.q(3444, "The Stone Circle", 51, 46, 3380)
  need(4290, "The Fare of Lar'korwi", 53, 48)
  need(4291, "The Scent of Lar'korwi", 53, 48, 4290)
  need(3844, "It's a Secret to Everybody", 52, 47)
  need(3845, "It's a Secret to Everybody", 52, 47, 3844)
  need(3884, "Williden's Journal", 50, 48)
  B.quest[3884].startItem = B.quest[3884].startItem or 11116

  H.chapter("feralas-49", "Feralas and Un'Goro: The Muisek Vessel", M.feralas, 49, 50, {
    "https://www.wowhead.com/forever/zone=357/feralas",
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    qdb,
  }, nil, {
    taxi("fly", P.bulkrek, "Camp Mojache, Feralas", "Fly from Gadgetzan to Camp Mojache."),
    accept(3063, talo, "Talo Thornhoof wants the Northspring harpies punished."), accept(3062, talo),
    accept(7734, P.jangdor),
    finish(3123, P.uzeri, "Give Uzer'i the wildkin muiseks."), accept(3124, P.uzeri), accept(3128, P.uzeri),
    action("sethearth", P.greul, "Bind at the Camp Mojache inn. You come back here twice.", mojache),
    action("goto", fe(nil, 55.0, 66.0), "Ride south-west to the Frayfeather Highlands."),
    along(objective(3124, fe(nil, 55.0, 68.0), "Kill Frayfeather hippogryphs and use the vessel on their bodies.", "10 Hippogryph Muisek"), 3128),
    part(3128, 3, fe(nil, 55.0, 68.0), "Hippogryphs also drop resilient sinew.", "20 Resilient Sinew"),
    part(3128, 4, fe(nil, 55.0, 68.0), "And metallic fragments.", "40 Metallic Fragments"),
    action("goto", P.uzeri, "Ride back to Camp Mojache."),
    finish(3124, P.uzeri), accept(3125, P.uzeri),
    along(objective(3125, fe(nil, 67.8, 47.5), "Kill Sprite Darters on the hills west of the camp and capture them with the vessel.", "8 Faerie Dragon Muisek"), 3128),
    part(3128, 2, fe(nil, 67.8, 47.5), "Sprite darters drop encrusted minerals.", "6 Encrusted Minerals"),
    action("goto", P.uzeri, "Ride back to Camp Mojache."),
    finish(3125, P.uzeri), accept(3126, P.uzeri),
    action("goto", fe(nil, 54.0, 33.0), "Ride north-west to Rage Scar Hold."),
    objective(7734, fe(nil, 53.5, 31.9), "Kill Rage Scar yetis around the hold for their hides.", "10 Rage Scar Yeti Hide"),
    along(objective(3126, fe(nil, 44.0, 23.0), "Go west into the woods north of the Twin Colossals. Kill Wandering Forest Walkers and capture them with the vessel.",
      "3 Treant Muisek"), 3128),
    part(3128, 1, fe(nil, 44.0, 23.0), "The forest walkers drop splintered logs.", "2 Splintered Log"),
    action("goto", fe(nil, 39.0, 15.0), "Ride north to the Ruins of Ravenwind."),
    objective(3063, fe(nil, 39.1, 13.3), "Kill Northspring Harpies, Roguefeathers, Windcallers and Slayers. Keep the Horn of Hatetalon if one drops.",
      "4 Northspring Harpies", "4 Northspring Roguefeathers", "4 Northspring Windcallers", "4 Northspring Slayers"),
    note(objective(3062, fe(nil, 39.0, 11.0), "Blow the Horn of Hatetalon on the ruins' high ground to call Edana Hatetalon. Kill her for her dark heart.",
      "Edana's Dark Heart"), "Where the horn works is not in the quest data; check in game."),
    action("hearth", P.greul, "Hearth to Camp Mojache.", mojache),
    finish(3126, P.uzeri), accept(3127, P.uzeri),
    finish(7734, P.jangdor), finish(3063, talo), finish(3062, talo),
    action("goto", zorbin, "Ride west along the road to the Forgotten Coast docks."),
    accept(7003, zorbin, "Zorbin Fandazzle lends you an ultra-shrinker for the giants to the north."),
    action("goto", fe(nil, 38.5, 22.6), "Ride north to the giants along the Forgotten Coast."),
    along(objective(3127, fe(nil, 38.5, 22.6), "Kill Land Walkers and Cliff Giants and capture them with the vessel.", "7 Mountain Giant Muisek"), 7003),
    objective(7003, fe(nil, 38.5, 22.6), "Zap giants with Zorbin's shrinker, kill the shrunken ones and loot their residue.", "15 Miniaturization Residue"),
    finish(7003, zorbin),
    action("goto", P.uzeri, "Ride back east to Camp Mojache."),
    finish(3127, P.uzeri), finish(3128, P.uzeri), accept(3129, P.uzeri),
    finish(3129, P.uzeri, "Wait while Uzer'i prepares your weapon, then take it."),
    taxi("fly", P.shyn, "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
    accept(3444, P.marvon, "Ride south to Marvon Rivetseeker. He needs a stone circle from his workshop in Ratchet."),
    action("goto", ug(nil, 70.0, 80.0), "Ride west across the desert and down the ramp into Un'Goro Crater."),
    accept(4290, torwa, "Torwa Pathfinder waits just inside the crater's eastern entrance."),
    accept(3844, raft, "Search the wrecked raft by the lake to the north-west."),
    finish(3844, pack), accept(3845, pack),
    objective(3845, pack, "Take the compass, map and key from the raft's pack.", "Large Compass", "Curled Map Parchment", "Lion-headed Key"),
    objective(4290, ug("Fresh Threshadon Carcass", 68.7, 56.7), "Find the threshadon carcass on the east shore and take a piece.",
      "Piece of Threshadon Carcass"),
    finish(4290, torwa, "Ride back south to Torwa."), accept(4291, torwa),
    note(objective(4291, ug(nil, 63.2, 77.4), "Kill the Lar'korwi mates west of Torwa for their pheromone glands.", "2 Ravasaur Pheromone Gland"),
      "The mates' spawns are not in the quest data."),
    finish(4291, torwa),
    withItem(11116, accept(3884, nil, "If a crater beast dropped a mangled journal, read it.")),
    action("goto", linken, "Ride north through the crater to Marshal's Refuge."),
    finish(3845, linken, "Give Linken his things."),
    finish(3884, williden),
    taxi("getfp", gryfe, "Marshal's Refuge, Un'Goro Crater", "Learn the Marshal's Refuge flight path from Gryfe."),
    taxi("fly", gryfe, "Crossroads, The Barrens", "Fly to the Crossroads."),
    action("sethearth", boorand, "Bind at the Crossroads inn.", { bind = "The Crossroads" }),
    taxi("fly", devrak, "Ratchet, The Barrens", "Fly to Ratchet."),
    objective(3444, on.barrens("Marvon's Chest", 62.5, 38.5), "Open Marvon's chest in his workshop in Ratchet and take the stone circle. Keep it for when you are back in Tanaris.",
      "Stone Circle"),
    action("boat", on.barrens(nil, 63.7, 38.6), "Take the boat from the Ratchet dock to Booty Bay. Use Next when you land.", { name = "Ratchet - Booty Bay" }),
  })
end

-- Alternate, 40-46: all of Brackenwall Village's work in one trip (the main route splits it
-- between 42 and 47), with Stinky's escort on the way.
do
  local dm = on.dustwallow
  local krak = dm("Krak", 36.4, 30.9)
  local tharg = dm("Tharg", 37.37, 31.39)
  local stinky = dm("\"Stinky\" Ignatz", 46.88, 17.52)
  local mebok = on.barrens("Mebok Mizzyrix", 62.37, 37.62)

  H.alternate("dustwallow-40", "Dustwallow Marsh: Brackenwall and the Black Dragonflight", M.dustwallow, 40, 46, {
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    "https://www.wowhead.com/forever/quest=98192",
    qdb,
  }, { "feralas-43", "tanaris-41" }, {
    taxi("fly", P.doras, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village in Dustwallow Marsh."),
    taxi("getfp", P.shardi, "Brackenwall Village, Dustwallow Marsh", "Learn the Brackenwall flight path from Shardi if you rode in."),
    note(accept(98192, krak, "Krak, a skinner in Brackenwall, wants intact raptor hides."), "A Forever quest; the giver's spot needs an in-game check."),
    accept(1166, P.mokmorokk, "Overlord Mok'Morokk lost his grog, snuff and strongbox in the south of the marsh."),
    accept(1169, P.drazzilb, "Draz'Zilb wants to study the black dragons' young."),
    accept(1168, tharg),
    accept(1270, stinky, "Ride north-east to \"Stinky\" Ignatz, a goblin camped in the northern marsh. He needs an escort."),
    note(objective(1270, stinky, "Escort Stinky through the marsh until he is safe.", "Stinky escorted"),
      "Escort route needs an in-game check."),
    action("goto", dm(nil, 45.0, 68.0), "Ride south past Tabetha's farm to the Wyrmbog."),
    along(objective(1168, dm(nil, 44.3, 66.4), "Kill Firemane Scouts and Ash Tails around the Wyrmbog. The Scalebanes guard the dragon caves to the east.",
      "10 Firemane Scouts", "10 Firemane Ash Tails", "5 Firemane Scalebanes"), 1169, 1166),
    along(objective(1169, dm(nil, 45.1, 73.7), "Searing Hatchlings and Whelps give the tongues and hearts.", "15 Searing Tongue", "15 Searing Heart"), 1168),
    part(1166, 1, dm("Mok'Morokk's Snuff", 44.5, 66.0), "The snuff lies in the Wyrmbog camp.", "Mok'Morokk's Snuff"),
    part(1166, 2, dm("Mok'Morokk's Grog", 38.7, 65.6), "The grog is farther west.", "Mok'Morokk's Grog"),
    part(1166, 3, dm("Mok'Morokk's Strongbox", 36.6, 69.6), "The strongbox is south of the grog.", "Mok'Morokk's Strongbox"),
    note(objective(98192, dm(nil, 33.6, 66.2), "Kill the Bloodfen raptors around Dragonmurk for intact hides.", "8 Intact Raptor Hide"),
      "Which raptors drop the hides is not published."),
    action("goto", P.mokmorokk, "Ride north back to Brackenwall Village."),
    finish(1166, P.mokmorokk), finish(98192, krak), finish(1168, tharg),
    finish(1169, P.drazzilb), accept(1170, P.drazzilb),
    finish(1170, P.mokmorokk), accept(1171, P.mokmorokk),
    finish(1171, P.drazzilb), accept(1172, P.drazzilb),
    action("goto", dm(nil, 52.0, 72.0), "Ride back south to the dragon caves on the Wyrmbog's east side."),
    note(objective(1172, dm(nil, 55.1, 74.0), "Go into the caves and destroy the Eggs of Onyxia. Watch for the whelp handlers.",
      "5 Eggs of Onyxia destroyed"), "Check the cave guards' strength in game."),
    action("goto", P.drazzilb, "Ride north to Brackenwall Village."),
    finish(1172, P.drazzilb), accept(1173, P.mokmorokk),
    note(objective(1173, P.mokmorokk, "Challenge Overlord Mok'Morokk and beat him in a fair fight.", "Mok'Morokk defeated"),
      "He is level 45 with a lot of health; check in game."),
    finish(1173, P.drazzilb),
    taxi("fly", P.shardi, "Ratchet, The Barrens", "Fly to Ratchet."),
    finish(1270, mebok, "Tell Mebok Mizzyrix that Stinky made it out."),
  })
end

-- Alternate, 45-50: Thorium Point and the Cauldron in the Searing Gorge, by way of Kargath.
do
  local sg = on.searing
  local grisha = sg("Grisha", 34.8, 30.9)
  local poster = sg("Wanted/Missing/Lost & Found", 37.65, 26.47)
  local scrange = sg("Taskmaster Scrange", 38.97, 27.51)
  local hansel = sg("Hansel Heavyhands", 38.58, 27.81)
  local lolo = sg("Lookout Captain Lolo Longstriker", 37.74, 26.56)
  local kalaran = sg("Kalaran Windblade", 39.06, 38.99)
  local outhouse = sg("Wooden Outhouse", 65.59, 62.17)

  need(7728, "STOLEN: Smithing Tuyere and Lookout's Spyglass", 48, 45)
  need(7729, "JOB OPPORTUNITY: Culling the Competition", 48, 45)
  need(7723, "Curse These Fat Fingers", 49, 45)
  need(7724, "Fiery Menace!", 49, 45)
  need(7727, "Incendosaurs? Whateverosaur is More Like It", 49, 45)
  need(7701, "WANTED: Overseer Maltorius", 50, 45)
  need(3441, "Divine Retribution", 48, 40)
  need(3442, "The Flawless Flame", 48, 40, 3441)
  need(4449, "Caught!", 45, 43)

  H.alternate("searing-45", "Searing Gorge: Thorium Point and the Cauldron", M.searing, 45, 50, {
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    qdb,
  }, { "hinterlands-48", "feralas-49", "ungoro-48" }, {
    taxi("fly", P.breyk, "Kargath, Badlands", "Fly to Kargath in the Badlands (from Stonard, Grom'gol or the Undercity)."),
    note(action("goto", grisha, "Take the road west out of Kargath into the Searing Gorge and climb to Thorium Point on the north-west rim."),
      "Check the way in from the Badlands in game."),
    taxi("getfp", grisha, "Thorium Point, Searing Gorge", "Learn the Thorium Point flight path from Grisha."),
    accept(7728, poster, "Read the board at Thorium Point."), accept(7729, poster), accept(7701, poster),
    accept(7723, hansel), accept(7724, hansel), accept(7727, hansel),
    accept(3441, kalaran, "Kalaran Windblade stands on the ledge south of Thorium Point."),
    objective(3441, kalaran, "Listen to Kalaran's story.", "Kalaran's story"),
    finish(3441, kalaran), accept(3442, kalaran),
    action("goto", sg(nil, 43.0, 33.0), "Go down the ramp into the Cauldron."),
    along(objective(7729, sg(nil, 44.6, 35.5), "Kill Dark Iron Taskmasters and Slavers around the slave pens.",
      "15 Dark Iron Taskmasters", "15 Dark Iron Slavers"), 7728, 7701),
    along(objective(7723, sg(nil, 36.0, 45.3), "Heavy War Golems patrol the Cauldron's west side. They also drop golem oil.", "20 Heavy War Golems"), 3442),
    objective(7728, sg(nil, 40.3, 48.9), "Dark Iron Steamsmiths on the Cauldron floor carry the tuyere; the Lookouts on the south-east ramps have the spyglass.",
      "Smithing Tuyere", "Lookout's Spyglass"),
    along(objective(3442, sg(nil, 54.5, 44.9), "Kill Magma Elementals on the east side for Hearts of Flame and more golem oil.", "4 Heart of Flame", "4 Golem Oil"),
      7723),
    action("goto", sg(nil, 46.5, 26.0), "Climb to the Slag Pit, the cave on the Cauldron's north side."),
    objective(7727, sg(nil, 46.5, 23.7), "Kill the Incendosaurs in the Slag Pit's lava pools.", "20 Incendosaurs"),
    note(objective(7701, sg("Overseer Maltorius", 40.8, 35.9), "Overseer Maltorius waits deep in the Slag Pit. Bring a partner and take his head.",
      "Head of Overseer Maltorius"), "Elite in the classic data; check in game."),
    action("goto", sg(nil, 25.7, 76.3), "Climb out of the Cauldron and ride to the south-west plateaus."),
    objective(7724, sg(nil, 25.7, 76.3), "Hunt Greater Lava Spiders around the lava pools.", "20 Greater Lava Spiders"),
    action("goto", outhouse, "Ride east to the Grimesilt dig site in the south-east."),
    accept(4449, outhouse, "Someone is locked in the outhouse. Knock on the door."),
    objective(4449, sg(nil, 63.3, 61.3), "Kill Dark Iron Geologists at the dig site. You also need 15 Silk Cloth from your bags or the Auction House.",
      "8 Dark Iron Geologists", "15 Silk Cloth"),
    finish(4449, outhouse),
    action("goto", kalaran, "Ride back north-west to Thorium Point."),
    finish(3442, kalaran),
    finish(7729, scrange), finish(7728, scrange), finish(7701, lolo),
    finish(7723, hansel), finish(7724, hansel), finish(7727, hansel),
  })
end

-- Alternate, 47-50: the Bloodmages' collections in the Blasted Lands, from Stonard.
do
  local bl = on.blasted
  local drazial = bl("Bloodmage Drazial", 50.55, 14.2)
  local lynnore = bl("Bloodmage Lynnore", 50.64, 14.3)

  need(2581, "Snickerfang Jowls", 50, 45)
  need(2583, "A Boar's Vitality", 50, 45)
  need(2585, "The Decisive Striker", 50, 45)
  need(2601, "The Basilisk's Bite", 50, 45)
  need(2603, "Vulture's Vigor", 50, 45)

  H.alternate("blasted-47", "Blasted Lands: The Bloodmages' Collections", M.blasted, 47, 50, {
    "https://www.wowhead.com/forever/zone=4/blasted-lands",
    qdb,
  }, { "feralas-49", "ungoro-48" }, {
    taxi("fly", P.thysta, "Stonard, Swamp of Sorrows", "Fly to Stonard."),
    action("goto", on.swamp(nil, 34.2, 66.4), "Ride south-west out of Stonard and take the road south into the Blasted Lands."),
    accept(2581, drazial, "The Bloodmages Drazial and Lynnore camp at the edge of the Dreadmaul hills, north of the Blasted Lands' center."),
    accept(2583, drazial), accept(2585, drazial), accept(2601, lynnore), accept(2603, lynnore),
    along(objective(2581, bl(nil, 46.5, 23.2), "Kill Starving Snickerfangs south of the camp for jowls. Collect the other parts as they drop.",
      "3 Snickerfang Jowl", "2 Blasted Boar Lung", "Scorpok Pincer"), 2585),
    along(objective(2585, bl(nil, 45.5, 24.4), "Scorpok Stingers in the same hills give the pincers.", "3 Scorpok Pincer", "2 Vulture Gizzard", "Blasted Boar Lung"),
      2581),
    action("goto", bl(nil, 57.0, 30.0), "Ride east into the hills around the Dreadmaul camps."),
    along(objective(2583, bl(nil, 55.9, 28.0), "Kill Grunters and Ashmane Boars for their lungs.", "3 Blasted Boar Lung", "2 Scorpok Pincer", "Basilisk Brain"),
      2601),
    along(objective(2601, bl(nil, 60.6, 32.7), "Redstone Basilisks on the slopes give the brains.", "10 Basilisk Brain", "2 Vulture Gizzard"), 2603),
    along(objective(2603, bl(nil, 56.4, 37.0), "Black Slayers and Bonepickers circle to the south. Take their gizzards and any jowls you still need.",
      "10 Vulture Gizzard", "2 Snickerfang Jowl"), 2601),
    action("goto", drazial, "Ride back north-west to the Bloodmages' camp."),
    finish(2581, drazial), finish(2583, drazial), finish(2585, drazial), finish(2601, lynnore), finish(2603, lynnore),
  })
end

-- Alternate, 48-50: a first pass through Un'Goro Crater from Torwa's camp to Marshal's Refuge.
do
  local ug = on.ungoro
  local torwa = ug("Torwa Pathfinder", 71.64, 75.96)
  local raft = ug("A Wrecked Raft", 63.02, 68.6)
  local pack = ug("A Small Pack", 63.11, 69.06)
  local linken = ug("Linken", 44.66, 8.1)
  local williden = ug("Williden Marshal", 43.95, 7.14)
  local holanyee = ug("Hol'anyee Marshal", 43.89, 7.24)
  local spark = ug("Spark Nilminer", 43.5, 7.42)
  local shizzle = ug("Shizzle", 44.23, 11.59)
  local larion = ug("Larion", 45.54, 8.72)
  local karna = ug("Karna Remtravel", 46.38, 13.44)
  local ame = ug("A-Me 01", 67.66, 16.76)
  local gryfe = ug("Gryfe", 45.2, 5.8)

  need(3881, "Expedition Salvation", 53, 48)
  need(3883, "Alien Ecology", 52, 48)
  need(3882, "Roll the Bones", 51, 49)
  need(4503, "Shizzle's Flyer", 51, 49)
  need(4145, "Larion and Muigin", 52, 47)
  need(4243, "Chasing A-Me 01", 53, 48)
  H.limit(4145, { race = { "ORC", "TAUREN", "TROLL", "SCOURGE", "SKYBORNE" } })

  H.alternate("ungoro-48", "Un'Goro Crater: Torwa and Marshal's Refuge", M.ungoro, 48, 50, {
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    qdb,
  }, { "feralas-49" }, {
    taxi("fly", P.doras, "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
    action("goto", ug(nil, 70.0, 80.0), "Ride west across the desert and down the ramp into Un'Goro Crater."),
    accept(4290, torwa, "Torwa Pathfinder waits just inside the crater's eastern entrance."),
    accept(3844, raft, "Search the wrecked raft by the lake to the north-west."),
    finish(3844, pack), accept(3845, pack),
    objective(3845, pack, "Take the compass, map and key from the raft's pack.", "Large Compass", "Curled Map Parchment", "Lion-headed Key"),
    objective(4290, ug("Fresh Threshadon Carcass", 68.7, 56.7), "Find the threshadon carcass on the east shore and take a piece.",
      "Piece of Threshadon Carcass"),
    finish(4290, torwa, "Ride back south to Torwa."), accept(4291, torwa),
    note(objective(4291, ug(nil, 63.2, 77.4), "Kill the Lar'korwi mates west of Torwa for their pheromone glands.", "2 Ravasaur Pheromone Gland"),
      "The mates' spawns are not in the quest data."),
    finish(4291, torwa),
    withItem(11116, accept(3884, nil, "If a crater beast dropped a mangled journal, read it.")),
    action("goto", linken, "Ride north through the crater to Marshal's Refuge."),
    finish(3845, linken, "Give Linken his things."),
    finish(3884, williden),
    taxi("getfp", gryfe, "Marshal's Refuge, Un'Goro Crater", "Learn the Marshal's Refuge flight path from Gryfe."),
    accept(3881, williden), accept(3883, holanyee), accept(3882, spark), accept(4503, shizzle),
    accept(4145, larion, "Larion wants the bloodpetal plants thinned."), accept(4243, karna, "Karna Remtravel lost track of her robot, A-Me 01."),
    finish(4243, ame, "Ride east along the crater's north wall. A-Me 01 hides among the rocks."),
    along(part(4145, 1, ug(nil, 65.7, 32.8), "Kill Bloodpetal Lashers in the eastern hills.", "5 Bloodpetal Lashers"), 3881),
    part(4145, 4, ug(nil, 65.6, 34.7), "Bloodpetal Threshers grow beside them.", "5 Bloodpetal Threshers"),
    part(3881, 1, ug("Crate of Foodstuffs", 68.5, 36.5), "The expedition's crate of foodstuffs lies in the same hills.", "Crate of Foodstuffs"),
    part(4503, 1, ug(nil, 63.9, 35.2), "Young Diemetradons graze nearby. Take their scales.", "8 Webbed Diemetradon Scale"),
    part(4503, 2, ug(nil, 78.3, 59.2), "Ride south-east and kill Fledgling Pterrordaxes on the eastern cliffs for scales.", "8 Webbed Pterrordax Scale"),
    note(objective(3883, ug(nil, 48.0, 80.0), "Ride south-west to the Gorishi hive. Use the scraping vial on a hive wall in a hatchery chamber with hanging larvae.",
      "Hive Wall Sample"), "The hatchery spot is not in the quest data."),
    part(4145, 3, ug(nil, 54.0, 64.3), "Bloodpetal Flayers grow north of the hive.", "5 Bloodpetal Flayers"),
    part(3881, 2, ug("Research Equipment", 38.5, 66.1), "The research equipment lies to the west.", "Research Equipment"),
    objective(3882, ug(nil, 33.4, 75.1), "Ride south-west to the stegodon herds and pick up dinosaur bones from the ground.", "8 Dinosaur Bone"),
    part(4145, 2, ug(nil, 35.9, 33.8), "Ride north to the western hills and kill Bloodpetal Trappers.", "5 Bloodpetal Trappers"),
    action("goto", williden, "Ride north-east back to Marshal's Refuge."),
    finish(3881, williden), finish(3883, holanyee), finish(3882, spark), finish(4503, shizzle), finish(4145, larion),
  })
end
