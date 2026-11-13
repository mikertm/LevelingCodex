-- Alliance route, levels 40-50. Source notes: tools/audits/2026-11-10-alliance-40-50.md.
-- Uses the shared 30-60 helpers and travel data from QuestData3040.lua.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local M = B.maps
local at, q, quest = B.at, B.q, B.quest
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, withItem, along, breadcrumb = B.objectiveAt, B.withItem, B.along, B.breadcrumb
local forDungeon, withGuide, note = B.forDungeon, B.withGuide, B.note
local on, section = B.on, B.section

-- Quests carried in from the 30-40 chapters. A turn-in or objective whose pickup is not on
-- the leveling route before it shows only while the quest is in your log (optional), and a
-- pickup whose prerequisite the route never offers is left out. Once the earlier chapters
-- pick these quests up, this changes nothing.
local function carried(steps)
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
    elseif step.quest and not seen[step.quest] then
      step.optional = true
    end
    if keep then kept[#kept + 1] = step end
  end
  return kept
end

local function chapter(id, title, zone, low, high, sources, suggest, steps)
  return section(id, title, zone, low, high, sources, carried(steps), { suggest = suggest })
end

local function alternate(id, title, zone, low, high, sources, suggest, steps)
  return section(id, title, zone, low, high, sources, steps, { alternate = true, suggest = suggest })
end

local function dungeon(id, step) return forDungeon(step, "dungeon-" .. id) end

local qdb = "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever"

-- Desolace at 40: Nijel's Point, the Gelkis and the Valley of Bones, with a Shimmering Flats errand.
do
  local ds = on.desolace
  local kreldig = ds("Kreldig Ungor", 66.2, 9.63)
  local anton = ds("Brother Anton", 66.52, 7.91)
  local talendria = ds("Talendria", 68.5, 8.88)
  local marandis = ds("Keeper Marandis", 63.83, 10.67)
  local willow = ds("Willow", 62.2, 39.63)
  local hornizz = ds("Hornizz Brimbuzzle", 47.83, 61.83)
  local uthek = ds("Uthek the Wise", 36.22, 79.25)
  local cavindra = ds("Cavindra", 32.1, 63.96)
  local pariah = ds("Centaur Pariah", 50.42, 86.65)
  local nerlokh = ds("Nerlokh", 58.4, 88.6)
  local inn = ds("Innkeeper Lyshaerya", 66.3, 6.6)
  local nijels = { bind = "Nijel's Point" }
  local fizzle = on.needles("Fizzle Brassbolts", 78.06, 77.13)
  local kravel = on.needles("Kravel Koalbeard", 77.79, 77.27)

  q(1466, "Reagents for Reclaimers Inc.", 40, 30, 1459)
  q(1467, "Reagents for Reclaimers Inc.", 40, 30, 1466)
  q(261, "Down the Scarlet Path", 39, 34)
  q(6134, "Ghost-o-plasm Round Up", 39, 34)
  q(1373, "Ongeku", 37, 30, 1370)
  q(1374, "Khan Jehn", 37, 30, 1373)
  q(93034, "Valley of Bones", 38, 35, 1373, true)
  q(93035, "Ravaging Ravagers", 38, 35, 93034, true)
  q(93037, "Outing Outcasts", 40, 35, 93034, true)
  q(93041, "Facing the Truth", 38, 35, { 93035, 93037 }, true)
  q(93045, "Test Your Theory", 38, 35, 93041, true)
  q(93058, "Saving Our Own", 42, 35, 93045, true)
  q(93062, "Bone Burying", 42, 35, 93045, true)
  q(93122, "Checking Things Out", 43, 35, { 93058, 93062 }, true)
  q(93128, "Khan Jehn", 42, 35, 93122, true)
  q(1106, "Martek the Exiled", 35, 26)
  q(1117, "Rumors for Kravel", 36, 30, 1116)
  q(1118, "Back to Booty Bay", 43, 35, 1117)

  chapter("desolace-40", "Desolace: Nijel's Point and the Valley of Bones", M.desolace, 40, 41, {
    "https://www.wowhead.com/forever/zone=16651/shendralas",
    "https://www.wowhead.com/forever/quest=93034/valley-of-bones",
    "https://bindonforever.com/zones/desolace",
    qdb,
  }, { "badlands-41", "shendralas" }, {
    taxi("fly", B.at("Baritanas Skyriver", 64.7, 10.5, 1443), "Nijel's Point, Desolace", "Fly from Theramore to Nijel's Point."),
    action("sethearth", inn, "Bind at the Nijel's Point inn. You will come back twice.", nijels),
    accept(1466, kreldig, "Kreldig's last reagent run sends you to the demons of Mannoroc Coven."),
    accept(6134, hornizz, "Hornizz, the goblin on the hill west of the Kodo Graveyard, hands you a crate of ghost magnets."),
    finish(1373, uthek, "Bring the Draenethyst shard to Uthek the Wise in the Gelkis village."),
    accept(1374, uthek),
    accept(93034, uthek, "Uthek sends you to his scout Nerlokh at the Valley of Bones."),
    objective(1466, ds(nil, 51.7, 83.9),
      "Go east to Mannoroc Coven. Kill felhounds, Nether Sisters and Doomwarders for the reagents. Pull the hounds away from the casters.",
      "10 Felhound Brain", "10 Nether Wing", "Doomwarder Blood"),
    finish(93034, nerlokh, "Nerlokh waits at the southern entrance of the Valley of Bones."),
    accept(93035, nerlokh), accept(93037, nerlokh),
    along(objective(93037, ds(nil, 63.8, 90.4), "Loot a Necromantic Garb from the Outcast Necromancers deeper in the valley.", "Necromantic Garb"), 93035, 6134),
    along(objective(6134, ds(nil, 64.0, 91.7), "Use the ghost magnets near the Magrami Spectres and collect the ghost-o-plasm they leave.", "8 Ghost-o-plasm"),
      261, 93035),
    finish(93035, nerlokh), finish(93037, nerlokh), accept(93041, nerlokh),
    objective(1374, ds("Khan Jehn", 65.9, 80.4), "Go north to the Magram village and kill Khan Jehn in the big tent. Clear his guards first.", "Khan Jehn's Head"),
    finish(6134, hornizz, "Head back west to Hornizz with the ghost-o-plasm."),
    finish(1374, uthek), finish(93041, uthek), accept(93045, uthek),
    objective(93045, nerlokh, "Go back to Nerlokh and lift the curse from the Accursed Skull as he explains.", "Curse dispelled"),
    finish(93045, nerlokh), accept(93058, nerlokh), accept(93062, nerlokh),
    along(note(objective(93058, at(nil, 33.0, 26.0, M.shendralas), "Free Gelkis captives held in the Valley of Bones.", "5 Gelkis Captives rescued"),
      "Captive positions are not published; check them in game."), 93062),
    along(objective(93062, at(nil, 38.6, 29.8, M.shendralas), "Dispel the failed summons, piles of Haggard Bones, spread through the valley.",
      "8 Haggard Bones"), 93058),
    finish(93058, nerlokh), finish(93062, nerlokh), accept(93122, nerlokh),
    note(objective(93122, at(nil, 30.0, 40.0, M.shendralas), "Look over the centaur sites Nerlokh marks inside Shen'dralas.", "Points of interest"),
      "Point locations are not published; check them in game."),
    finish(93122, nerlokh),
    note(accept(93128, nerlokh, "If Nerlokh asks you to kill Khan Jehn again, take it. Use Next if he does not offer it."),
      "Check whether this repeats the classic Khan Jehn quest or replaces it."),
    objective(93128, ds("Khan Jehn", 65.9, 80.4), "Return to the Magram village and kill Khan Jehn once more.", "Khan Jehn"),
    finish(93128, uthek),
    action("goto", ds(nil, 41.1, 91.7), "Follow the road south out of Desolace into Feralas."),
    taxi("getfp", on.feralas("Fyldren Moonfeather", 30.2, 43.2), "Feathermoon, Feralas",
      "Take the ferry from the Forgotten Coast dock to Feathermoon Stronghold and learn the flight path."),
    taxi("fly", B.at("Bera Stonehammer", 51, 29.3, 1446), "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
    action("goto", fizzle, "Ride north out of Gadgetzan to the Mirage Raceway in the Shimmering Flats."),
    accept(1106, fizzle, "Fizzle Brassbolts has a letter for his old partner Martek in the Badlands."),
    finish(1117, kravel), accept(1118, kravel, "Keep Kravel's scheme for Booty Bay."),
    action("hearth", inn, "Hearth back to Nijel's Point.", nijels),
    finish(1466, kreldig), accept(1467, kreldig, "Carry Leftwitch's package to Ironforge."),
    taxi("fly", B.at("Baldruc", 67.5, 51.3, 1445), "Theramore, Dustwallow Marsh", "Fly to Theramore."),
    action("boat", on.dustwallow(nil, 71.5, 56.3), "Take the ship from the Theramore docks to Menethil Harbor. Use Next when you land.",
      { name = "Theramore - Menethil Harbor" }),
    taxi("fly", B.at("Gryth Thurden", 55.5, 47.7, 1455), "Ironforge, Dun Morogh", "Fly to Ironforge."),
  })
end

-- Ironforge errands, Loch Modan and the Badlands. Uldaman's outdoor pickups are here.
do
  local bl, lm, ifg = on.badlands, on.lochModan, on.ironforge
  local roetten = ifg("Roetten Stonehammer", 69.95, 21.26)
  local stormpike = ifg("Prospector Stormpike", 74.64, 11.74)
  local mae = ifg("Librarian Mae Paledust", 74.97, 12.48)
  local gerrig = ifg("Gerrig Bonegrip", 50.8, 5.6)
  local krom = ifg("Krom Stoutarm", 74.2, 9.4)
  local ghak = lm("Ghak Healtouch", 37.07, 49.38)
  local ironband = lm("Prospector Ironband", 65.93, 65.62)
  local hearthstove = lm("Innkeeper Hearthstove", 35.5, 48.4)
  local ryedol = bl("Prospector Ryedol", 53.42, 43.39)
  local sigrun = bl("Sigrun Ironhew", 53.4, 43.4)
  local martek = bl("Martek the Exiled", 42.22, 52.69)
  local rigglefuzz = bl("Rigglefuzz", 42.39, 52.93)
  local garek = bl("Garek", 61.94, 54.26)
  local skeleton = bl("Battered Dwarven Skeleton", 50.89, 62.4)
  local theldurin = bl("Theldurin the Lost", 51.39, 76.87)
  local lotwil = bl("Lotwil Veriatus", 25.95, 44.87)
  local thelsamar = { bind = "Thelsamar" }

  q(554, "Stormpike's Deciphering", 40, 28, 551)
  q(707, "Ironband Wants You!", 37, 30)
  q(738, "Find Agmond", 38, 30, 707)
  q(739, "Murdaloc", 42, 30, 738)
  q(653, "Myzrael's Allies", 40, 30, 652)
  q(687, "Theldurin the Lost", 40, 30, 653)
  q(692, "The Lost Fragments", 41, 30, 687)
  q(2500, "Badlands Reagent Run", 39, 36)
  q(719, "A Dwarf and His Tools", 35, 35)
  q(718, "Mirages", 38, 35)
  q(733, "Scrounging", 40, 35, 718)
  q(732, "Tremors of the Earth", 43, 40, 718)
  q(720, "A Sign of Hope", 35, 35)
  q(1108, "Indurium", 39, 28, 1106)
  q(1137, "News for Fizzle", 38, 28, 1108)
  q(703, "Barbecued Buzzard Wings", 40, 33)
  q(710, "Study of the Elements: Rock", 37, 35)
  q(711, "Study of the Elements: Rock", 39, 35, 710)
  q(712, "Study of the Elements: Rock", 42, 35, 711)

  chapter("badlands-41", "Badlands: Ryedol's Camp and the Rock Elementals", M.badlands, 41, 42, {
    "https://bindonforever.com/zones/badlands",
    "https://www.wowhead.com/forever/zone=3/badlands",
    qdb,
  }, { "stv-41", "searing-gorge", "riverglades-shroud" }, {
    finish(1467, roetten, "Take the deep road to the Hall of Explorers and give Roetten his package."),
    accept(707, stormpike, "Prospector Stormpike, in the Hall of Explorers, sends you to his partner Ironband in Loch Modan."),
    accept(687, gerrig, "Gerrig Bonegrip in the Forlorn Cavern sends you to Theldurin, camped in the southern Badlands."),
    taxi("fly", B.at("Thorgrum Borrelson", 33.9, 51, 1432), "Thelsamar, Loch Modan", "Fly to Thelsamar."),
    action("sethearth", hearthstove, "Bind at the Thelsamar inn. The Badlands road starts just south of here.", thelsamar),
    accept(2500, ghak, "Ghak Healtouch, beside the inn, wants reagents from the Badlands."),
    finish(707, ironband, "Ride east to Ironband's excavation by the dam."), accept(738, ironband),
    action("goto", bl(nil, 49.2, 7.8), "Take the road south out of Loch Modan into the Badlands."),
    along(objective(2500, bl(nil, 52.0, 30.0), "On the way south, loot buzzards, crag coyotes and rock elementals for Ghak whenever they are near.",
      "Buzzard Gizzard", "Crag Coyote Fang", "Rock Elemental Shard"), 720),
    accept(720, bl("Crumpled Map", 53.03, 33.94), "Pick up the crumpled map lying beside the road north of the dwarven camp."),
    accept(719, ryedol, "Prospector Ryedol and Sigrun share the camp in the middle of the Badlands."),
    accept(718, ryedol), finish(720, ryedol),
    objective(719, bl(nil, 43.5, 30.5), "Go northwest to the Shadowforge camp. Kill dwarves until Ryedol's lucky pick drops.", "Ryedol's Lucky Pick"),
    objective(718, bl("Supply Crate", 66.9, 23.4), "Cross to the northeast and loot the supply crate at the wrecked camp.", "Supply Crate"),
    finish(718, sigrun), accept(733, sigrun), finish(719, ryedol),
    finish(1106, martek, "Martek lives by the trailer southwest of the camp."), accept(1108, martek),
    accept(703, rigglefuzz, "Rigglefuzz, beside Martek, wants buzzard wings."),
    accept(732, garek, "Garek camps east of Ryedol and wants the Sign of the Earth."),
    finish(738, skeleton, "Follow the gully south to Agmond's remains."), accept(739, skeleton),
    along(objective(739, bl(nil, 49.6, 66.7), "Kill Murdaloc and the Stonevault Bonesnappers in the troggs' cave mouth.", "Murdaloc", "12 Stonevault Bonesnappers"),
      1108),
    finish(687, theldurin, "Theldurin camps at the south end of the Badlands."), accept(692, theldurin),
    along(objective(692, bl(nil, 49.6, 66.7), "Loot the three scroll fragments from troggs and rock elementals around Angor Fortress.",
      "Torn Scroll Fragment", "Crumpled Scroll Fragment", "Singed Scroll Fragment"), 1108),
    along(objective(1108, bl(nil, 50.3, 69.1), "Kill Stonevault troggs until you have the indurium flakes.", "10 Indurium Flake"), 692),
    finish(692, theldurin),
    finish(1108, martek), accept(1137, martek, "Keep Martek's news for Fizzle. You pass the Shimmering Flats later."),
    accept(710, lotwil, "Lotwil Veriatus works at his circle at the west end of the Badlands."),
    along(objective(710, bl(nil, 18.0, 42.8), "Break Lesser Rock Elementals west of the circle for small shards.", "10 Small Stone Shard"), 2500),
    finish(710, lotwil), accept(711, lotwil),
    along(objective(711, bl(nil, 14.7, 35.3), "Hunt Rock Elementals farther northwest for the stone slabs.", "3 Large Stone Slab"), 2500),
    finish(711, lotwil), accept(712, lotwil),
    along(objective(712, bl(nil, 2.7, 81.3), "Go to the far southwest corner and take bracers from the Greater Rock Elementals.",
      "5 Bracers of Rock Binding"), 733, 2500),
    along(objective(733, bl(nil, 11.0, 80.0), "Kill Dustbelcher ogres nearby for scrap metal.", "Scrap Metal"), 712),
    along(objective(703, bl(nil, 58.8, 54.0), "Work back east and hunt buzzards for wings and anything Ghak still needs.", "4 Buzzard Wing"), 2500),
    finish(712, lotwil), finish(703, rigglefuzz), finish(733, sigrun),
    objective(732, bl(nil, 36.4, 71.6), "Search the ogre camp south of Lotwil for the Sign of the Earth.", "Sign of the Earth"),
    finish(732, garek),
    taxi("getfp", on.searing("Lanie Reed", 37.9, 30.9), "Thorium Point, Searing Gorge",
      "Take the west road from the Badlands into the Searing Gorge and climb to Thorium Point for the flight path."),
    action("hearth", hearthstove, "Hearth back to Thelsamar.", thelsamar),
    finish(2500, ghak), finish(739, ironband, "Ride east to Ironband with Murdaloc's death confirmed."),
    taxi("fly", B.at("Gryth Thurden", 55.5, 47.7, 1455), "Ironforge, Dun Morogh", "Fly to Ironforge."),
  })
end

-- Stormwind turn-ins, Booty Bay and the whole of Stranglethorn, then the Swamp of Sorrows and Nethergarde.
do
  local st, sw, sp = on.stv, on.stormwind, on.swamp
  local crank = st("Crank Fizzlebub", 27.12, 77.21)
  local krazek = st("Krazek", 26.94, 77.21)
  local kebok = st("Kebok", 27.0, 77.13)
  local seahorn = st("Fleet Master Seahorn", 27.2, 77.0)
  local catelyn = st("Catelyn the Blade", 27.3, 77.5)
  local bloads = st("Privateer Bloads", 26.8, 76.4)
  local mackinley = st("\"Sea Wolf\" MacKinley", 27.8, 77.1)
  local drizzlik = st("Drizzlik", 28.29, 77.59)
  local crazz = st("First Mate Crazz", 28.1, 76.22)
  local deeg = st("Deeg", 26.9, 77.3)
  local dizzy = st("Dizzy One-Eye", 28.6, 75.9)
  local slim = st("Whiskey Slim", 27.14, 77.45)
  local shaky = st("\"Shaky\" Phillipe", 26.9, 73.6)
  local skindle = st("Innkeeper Skindle", 27.0, 77.3)
  local hemet = st("Hemet Nesingwary", 35.66, 10.81)
  local erlgadin = st("Sir S. J. Erlgadin", 35.55, 10.55)
  local biggs = sp("Watcher Biggs", 26.74, 59.83)
  local bootyBay = { bind = "Booty Bay" }

  q(543, "The Perenolde Tiara", 40, 30)
  q(542, "Return to Milton", 38, 20, 540)
  q(3636, "Bring the Light", 42, 39)
  q(1477, "Vital Supplies", 45, 40)
  q(1395, "Supplies for Nethergarde", 45, 40, 1477)
  q(1116, "Dream Dust in the Swamp", 36, 30, 1115)
  q(209, "Skullsplitter Tusks", 42, 37, 189)
  q(669, "Sunken Treasure", 40, 35, 668)
  q(603, "Ansirem's Key", 37, 32, 602)
  q(610, "\"Pretty Boy\" Duncan", 39, 32, 603)
  q(611, "The Curse of the Tides", 40, 32, 610)
  q(600, "Venture Company Mining", 41, 30, 605)
  q(621, "Zanzil's Secret", 44, 35)
  q(1119, "Zanzil's Mixture and a Fool's Stout", 44, 35, { 621, 1118 })
  q(617, "Akiris by the Bundle", 43, 38)
  q(623, "Akiris by the Bundle", 43, 38, 617)
  q(606, "Scaring Shaky", 41, 30)
  q(607, "Return to MacKinley", 41, 30, 606)
  q(609, "Voodoo Dues", 44, 30, 607)
  q(2872, "Stoley's Debt", 45, 40)
  q(628, "Excelsior", 38, 31, 577)
  q(595, "The Bloodsail Buccaneers", 41, 37)
  q(597, "The Bloodsail Buccaneers", 41, 37, 595)
  q(599, "The Bloodsail Buccaneers", 41, 37, 597)
  q(604, "The Bloodsail Buccaneers", 43, 37, 599)
  q(587, "Up to Snuff", 41, 37, 595)
  q(576, "Keep An Eye Out", 42, 37, 595)
  q(196, "Raptor Mastery", 41, 28, 195)
  q(197, "Raptor Mastery", 43, 28, 196)
  q(193, "Panther Mastery", 40, 28, 192)
  q(205, "Troll Witchery", 40, 30, 207)
  q(202, "Colonel Kurzen", 40, 30, 574)
  q(208, "Big Game Hunter", 43, 28, { 188, 193, 197 })
  q(624, "Cortello's Riddle", 43, 35)
  quest[624].startItem = 4056
  q(625, "Cortello's Riddle", 43, 35, 624)
  q(1398, "Driftwood", 42, 30, 1421)
  q(1425, "Deliver the Shipment", 42, 30, 1398)
  q(1258, "... and Bugs", 40, 33, 1204)
  q(2864, "Tran'rek", 45, 40)
  q(580, "Whiskey Slim's Lost Grog", 50, 40)

  chapter("stv-41", "Stranglethorn and the Swamp of Sorrows", M.stv, 41, 43, {
    "https://bindonforever.com/zones/stranglethorn-vale",
    "https://bindonforever.com/zones/swamp-of-sorrows",
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    qdb,
  }, { "tanaris-43", "shendralas" }, {
    action("goto", nil, "Take the tram to Stormwind."),
    B.optional(finish(3636, sw("Archbishop Benedictus", 50.3, 45.5), "If you killed Amnennar in Razorfen Downs, report to Archbishop Benedictus in the Cathedral of Light.")),
    accept(1477, sw("High Sorcerer Andromath", 48.71, 87.62), "High Sorcerer Andromath, in the Wizard's Sanctum, sends supplies toward Nethergarde."),
    taxi("fly", B.at("Gyll", 27.5, 77.8, 1434), "Booty Bay, Stranglethorn", "Fly to Booty Bay."),
    finish(1116, krazek, "Krazek stands on the top floor of the inn."),
    accept(2864, krazek, "Krazek also has a letter for Tran'rek in Gadgetzan. Keep it for Tanaris."),
    accept(209, kebok, "Kebok, next to Krazek, wants Skullsplitter tusks."),
    finish(669, seahorn), finish(603, catelyn), accept(610, catelyn),
    finish(1118, crank, "Crank Fizzlebub, on the inn's middle floor, wants Kravel's scheme."),
    accept(600, crank), accept(621, crank),
    action("sethearth", skindle, "Bind at the Booty Bay inn.", bootyBay),
    accept(617, bloads), accept(606, mackinley), accept(628, drizzlik),
    accept(595, crazz, "First Mate Crazz, on the dock behind the inn, sends you to look for Bloodsail papers."),
    finish(595, st("Bloodsail Correspondence", 27.28, 69.52), "Walk north out of town to the shore camp and read the Bloodsail papers on the barrel."),
    accept(597, st("Bloodsail Correspondence", 27.28, 69.52)),
    objective(610, st("\"Pretty Boy\" Duncan", 27.4, 69.4), "Kill \"Pretty Boy\" Duncan in the same camp and take Catelyn's blade.", "Catelyn's Blade"),
    finish(597, crazz), accept(599, crazz),
    finish(610, catelyn), accept(611, catelyn),
    accept(587, deeg), finish(599, seahorn), accept(576, dizzy),
    along(objective(606, st(nil, 33.5, 65.2), "Go northeast into Mistvale Valley and loot giblets from the elder gorillas.", "5 Mistvale Giblets"), 617),
    objective(196, st(nil, 31.8, 40.9), "Follow the coast north and hunt Jungle Stalkers around the ruins.", "10 Jungle Stalkers"),
    objective(600, st(nil, 41.7, 43.7), "Go east to the Venture Co. mine and take crystals from the workers.", "10 Singing Blue Crystal"),
    along(objective(209, st(nil, 45.8, 42.3), "Clear the Skullsplitter camp just east of the mine. Tusks drop from every troll there.", "18 Skullsplitter Tusk"),
      205),
    along(objective(205, st(nil, 45.8, 42.3), "Loot fetishes from the Mystics and Witch Doctors in the same camp.", "4 Skullsplitter Fetish"), 209),
    objective(193, st("Bhag'thera", 48.4, 19.2), "Head north. Bhag'thera prowls the ridge east of the road; pull her alone.", "Fang of Bhag'thera"),
    note(objective(202, st(nil, 44.4, 9.8), "Fight through the Kurzen compound for six elites, six subchiefs and the Colonel. Bring a group for the caves.",
      "6 Kurzen Elites", "6 Kurzen Subchiefs", "Kurzen's Head"), "Kurzen sits deep in the cave; positions need an in-game check."),
    finish(205, st("Brother Nimetz", 37.8, 3.6), "Brother Nimetz is at the Rebel Camp."),
    finish(202, st("Lieutenant Doren", 38.0, 3.0)),
    finish(193, erlgadin, "Ride south to Nesingwary's camp."), finish(196, hemet), accept(197, hemet),
    objective(628, st(nil, 21.6, 16.6), "Hunt Elder Saltwater Crocolisks along the west coast for Drizzlik's skin.", "Elder Crocolisk Skin"),
    objective(611, st("Gazban", 25.0, 23.6), "Wade out to the small isle southwest of the camp and kill Gazban for the Stone of the Tides.", "Stone of the Tides"),
    objective(197, st("Tethis", 31.1, 43.2), "Tethis, the big raptor, circles the ruins south of the camp. Kill him for his talon.", "Talon of Tethis"),
    finish(197, hemet), accept(208, hemet),
    objective(208, st("King Bangalash", 38.2, 35.6), "King Bangalash and his panthers hold the hill east of the road. Kill the cubs first.", "Head of Bangalash"),
    finish(208, hemet),
    action("hearth", skindle, "Hearth back to Booty Bay.", bootyBay),
    finish(600, crank), finish(209, kebok),
    finish(611, seahorn), accept(604, seahorn),
    finish(606, shaky, "\"Shaky\" Phillipe waits on the dock at the town's mouth."), accept(607, shaky),
    finish(607, mackinley), accept(609, mackinley),
    finish(628, drizzlik),
    objective(617, st(nil, 26.0, 62.5), "Kill Naga Explorers along the coast north of town for Akiris reeds.", "Akiris Reed"),
    along(objective(604, st(nil, 27.0, 83.2), "South of town on the Wild Shore, kill Bloodsail swashbucklers and take their charts and orders.",
      "10 Bloodsail Swashbucklers", "10 Bloodsail Charts", "10 Bloodsail Orders"), 587, 576),
    along(objective(587, st(nil, 27.0, 83.2), "Snuff drops from the Bloodsail pirates on the same shore.", "Snuff"), 604, 576),
    along(objective(576, st(nil, 27.0, 83.2), "Dizzy's eye is with the pirates too.", "Dizzy's Eye"), 604, 587),
    withItem(4056, accept(624, st("Cortello's Riddle", 30.7, 88.6), "Search the cliff south of the pirate camp for Cortello's scroll and read it.")),
    objective(609, st(nil, 40.0, 58.2), "Go northeast to Zanzil's islands. Kill Chucky, Maury and Jon-Jon for MacKinley's dues.",
      "Maury's Clubbed Foot", "Jon-Jon's Golden Spyglass", "Chucky's Huge Ring"),
    objective(621, st(nil, 40.0, 58.2), "Loot Zanzil's mixture from the witch doctors on the same islands.", "Zanzil's Mixture"),
    action("hearth", skindle, "Hearth or ride back to Booty Bay.", bootyBay),
    finish(587, deeg), finish(604, seahorn),
    finish(621, slim), accept(580, slim, "Whiskey Slim's lost grog is in the Hinterlands. Keep it for later."),
    accept(1119, crank),
    finish(617, bloads), accept(623, bloads, "Bloads sends the reeds to Theramore. Keep this for Dustwallow."),
    finish(609, mackinley), accept(2872, mackinley, "MacKinley's debt is collected in Steamwheedle Port, Tanaris."),
    finish(576, dizzy),
    taxi("fly", B.at("Felicia Maline", 77.49, 44.29, 1431), "Darkshire, Duskwood", "Fly to Darkshire."),
    finish(1477, on.duskwood("Watchmaster Sorigal", 75.78, 46.16), "Watchmaster Sorigal stands by the town hall."),
    accept(1395, on.duskwood("Watchmaster Sorigal", 75.78, 46.16)),
    action("goto", sp(nil, 3.0, 61.0), "Take the east road through Deadwind Pass into the Swamp of Sorrows."),
    finish(624, sp("A Soggy Scroll", 22.87, 48.19), "Read the soggy scroll under the bridge in the swamp's west."),
    accept(625, sp("A Soggy Scroll", 22.87, 48.19), "The riddle continues in Dustwallow Marsh. Keep it for Theramore."),
    accept(1398, biggs, "Watcher Biggs camps on the road south of the bridge."),
    along(objective(1398, sp(nil, 91.6, 70.1), "Cross the swamp to Misty Reed Strand in the far east. Pick up the sundried driftwood on the beach.",
      "Sundried Driftwood"), 1258),
    along(objective(1258, sp(nil, 91.6, 70.1), "Kill crawlers on the same beach for their legs.", "12 Pristine Crawler Leg"), 1398),
    finish(1398, biggs), accept(1425, biggs),
    action("goto", on.blasted(nil, 60.0, 15.0), "Take the road south out of the swamp into the Blasted Lands and head to Nethergarde Keep."),
    finish(1425, on.blasted("Quartermaster Lungertz", 66.52, 21.39)), finish(1395, on.blasted("Quartermaster Lungertz", 66.52, 21.39)),
    taxi("getfp", on.blasted("Alexandra Constantine", 65.5, 24.3), "Nethergarde Keep, Blasted Lands", "Learn the Nethergarde flight path."),
    taxi("fly", B.at("Gyll", 27.5, 77.8, 1434), "Booty Bay, Stranglethorn", "Fly back to Booty Bay."),
    action("boat", st(nil, 25.8, 73.1), "Take the boat from Booty Bay to Ratchet. Use Next when you land.", { name = "Booty Bay - Ratchet" }),
  })
end

-- Theramore errands, Gadgetzan, the Shimmering Flats and Steamwheedle Port.
do
  local tn, dm, fl = on.tanaris, on.dustwallow, on.needles
  local bilgewhizzle = tn("Chief Engineer Bilgewhizzle", 52.46, 28.51)
  local luglunket = tn("Spigot Operator Luglunket", 52.49, 28.45)
  local curgle = tn("Curgle Cranklehop", 52.36, 26.91)
  local tranrek = tn("Tran'rek", 51.57, 26.76)
  local shreev = tn("Shreev", 50.96, 27.24)
  local yehkinya = tn("Yeh'kinya", 67.0, 22.4)
  local razzeric = fl("Razzeric", 80.33, 76.09)
  local pozzik = fl("Pozzik", 80.18, 75.88)
  local fizzle = fl("Fizzle Brassbolts", 78.06, 77.13)
  local kravel = fl("Kravel Koalbeard", 77.79, 77.27)
  local janene = dm("Innkeeper Janene", 66.6, 45.2)

  q(1187, "Razzeric's Tweaking", 41, 29, 1186)
  q(1188, "Safety First", 41, 29, 1187)
  q(1190, "Keeping Pace", 41, 29, 1137)
  q(1194, "Rizzle's Schematics", 41, 29, 1190)
  q(1120, "Get the Gnomes Drunk", 44, 35, 1119)
  q(1122, "Report Back to Fizzlebub", 44, 35, 1120)
  q(1690, "Wastewander Justice", 43, 40)
  q(1707, "Water Pouch Bounty", 44, 40)
  q(3022, "Handle With Care", 47, 42)
  q(3520, "Screecher Spirits", 44, 40)
  q(626, "Cortello's Riddle", 51, 35, 625)
  q(1452, "Rhapsody's Kalimdor Kocktail", 43, 38, 1451)

  chapter("tanaris-43", "Tanaris: Gadgetzan and the Shimmering Flats", M.tanaris, 43, 44, {
    "https://bindonforever.com/zones/tanaris",
    "https://bindonforever.com/zones/thousand-needles",
    "https://www.wowhead.com/forever/zone=440/tanaris",
    qdb,
  }, { "feralas-44", "shendralas" }, {
    taxi("fly", B.at("Baldruc", 67.5, 51.3, 1445), "Theramore, Dustwallow Marsh", "Fly from Ratchet to Theramore."),
    finish(623, dm("Privateer Groy", 67.7, 51.7), "Privateer Groy is on the Theramore docks."),
    finish(1258, dm("Morgan Stern", 66.3, 45.5), "Morgan Stern waits in the inn with the crawler legs."),
    action("sethearth", janene, "Bind at the Theramore inn.", { bind = "Theramore Isle" }),
    objective(1187, dm(nil, 54.1, 56.5), "Take the road west out of Theramore and look for the Seaforium booster in the wrecked camp south of the road.",
      "Seaforium Booster"),
    finish(625, dm("Musty Scroll", 31.1, 66.14), "Follow the riddle to the musty scroll in the southwest of the marsh."),
    accept(626, dm("Musty Scroll", 31.1, 66.14), "The last clue points to the Hinterlands. Keep it for later."),
    taxi("fly", B.at("Bera Stonehammer", 51, 29.3, 1446), "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
    accept(1690, bilgewhizzle, "Chief Engineer Bilgewhizzle and the spigot operator stand by the water tower."),
    accept(1707, luglunket),
    accept(3022, curgle, "Curgle wants a crate carried to Rut'theran Village. You will pass there from Feralas."),
    finish(2864, tranrek, "Tran'rek sits by the bank."),
    action("goto", fl(nil, 75.0, 90.0), "Ride north out of Gadgetzan along the road to the Mirage Raceway in the Shimmering Flats."),
    finish(1187, razzeric), accept(1188, razzeric, "Razzeric wants the booster checked by Shreev in Gadgetzan."),
    finish(1137, fizzle, "Fizzle Brassbolts is beside the raceway's grandstand."),
    accept(1190, pozzik),
    finish(1190, fl("Rizzle's Unguarded Plans", 77.21, 77.39), "Ask Zamek for his distraction, then grab Rizzle's plans in the gnome camp."),
    accept(1194, fl("Rizzle's Unguarded Plans", 77.21, 77.39)), finish(1194, pozzik),
    finish(1119, kravel), accept(1120, kravel),
    finish(1120, fl("Gnome Pit Boss", 77.56, 76.94), "Give the stout to the gnome pit boss."),
    accept(1122, kravel, "Kravel's report goes to Crank Fizzlebub in Booty Bay. You will be back there at 50."),
    action("goto", tn(nil, 51.5, 28.0), "Ride back south to Gadgetzan."),
    finish(1188, shreev, "Shreev sells goods by the north gate."),
    action("goto", tn(nil, 66.6, 23.0), "Take the road northeast to Steamwheedle Port."),
    accept(3520, yehkinya, "Yeh'kinya wants screecher spirits from Feralas. The pirate quests here wait until you are back at 49."),
    along(objective(1690, tn(nil, 63.9, 31.6), "Kill Wastewander Bandits and Thieves in the dunes south of the port.",
      "10 Wastewander Bandits", "10 Wastewander Thieves"), 1707),
    along(objective(1707, tn(nil, 63.9, 31.6), "The same bandits carry the water pouches.", "5 Wastewander Water Pouch"), 1690),
    B.objectivePart(1452, 1, tn(nil, 44.6, 39.6), "Hunt Rocs in the hills southwest of Gadgetzan for Rhapsody's gizzards.", "3 Roc Gizzard"),
    finish(1690, bilgewhizzle), finish(1707, luglunket),
  })
end

-- Feathermoon Stronghold and the Feralas mainland, with a trip to Rut'theran and Darnassus.
do
  local fe, tel = on.feralas, on.teldrassil
  local shandris = fe("Shandris Feathermoon", 30.28, 46.17)
  local latronicus = fe("Latronicus Moonspear", 30.38, 46.17)
  local ginro = fe("Ginro Hearthkindle", 31.86, 45.13)
  local quintis = fe("Quintis Jonespyre", 32.45, 43.79)
  local vestia = fe("Vestia Moonspear", 30.08, 45.06)
  local pratt = fe("Pratt McGrubben", 30.63, 42.71)
  local troyas = fe("Troyas Moonbreeze", 31.78, 45.5)
  local angelas = fe("Angelas Moonbreeze", 31.83, 45.61)
  local kindal = fe("Kindal Moonweaver", 65.94, 45.65)
  local jerkai = fe("Jer'kai Moonweaver", 65.95, 45.61)
  local gazebo = fe("Solarsal Gazebo", 26.31, 52.34)
  local rowboat = fe("Wrecked Row Boat", 45.44, 64.96)
  local backpacks = fe("Large Leather Backpacks", 73.32, 56.31)
  local pod = fe("Zukk'ash Pod", 72.07, 63.72)
  local fyldren = fe("Fyldren Moonfeather", 30.2, 43.2)
  local shyria = fe("Innkeeper Shyria", 31.0, 43.5)
  local erelas = tel("Erelas Ambersky", 55.5, 92.05)
  local daryn = tel("Daryn Lightwind", 55.41, 92.23)
  local feathermoon = { bind = "Feathermoon Stronghold" }

  q(4124, "The Missing Courier", 43, 40)
  q(4125, "The Missing Courier", 43, 40, 4124)
  q(4127, "Boat Wreckage", 44, 40, 4125)
  q(4129, "The Knife Revealed", 44, 40, 4127)
  q(4130, "Psychometric Reading", 44, 40, 4129)
  q(4131, "The Woodpaw Gnolls", 44, 40, 4130)
  q(4135, "The Writhing Deep", 46, 40, 4131)
  q(4265, "Freed from the Hive", 46, 40, 4135)
  q(4266, "A Hero's Welcome", 46, 40, 4265)
  q(4267, "Rise of the Silithid", 46, 40, 4266)
  q(2866, "The Ruins of Solarsal", 43, 40)
  q(2867, "Return to Feathermoon Stronghold", 43, 40, 2866)
  q(3130, "Against the Hatecrest", 43, 40, 2867)
  q(2869, "Against the Hatecrest", 43, 40, 3130)
  q(2870, "Against Lord Shalzaru", 45, 40, 2869)
  q(2871, "Delivering the Relic", 45, 40, 2870)
  q(2821, "The Mark of Quality", 46, 40)
  q(2939, "In Search of Knowledge", 47, 42)
  q(2940, "Feralas: A History", 47, 42, 2939)
  q(2941, "The Borrower", 48, 42, 2940)
  q(2982, "The High Wilderness", 44, 39)
  q(2766, "Find OOX-22/FE!", 45, 40)
  quest[2766].startItem = 8705
  q(2767, "Rescue OOX-22/FE!", 45, 40, 2766)
  q(2969, "Freedom for All Creatures", 47, 38)
  q(2970, "Doling Justice", 47, 38, 2969)
  q(2972, "Doling Justice", 47, 38, 2970)
  q(4281, "Thalanaar Delivery", 44, 40)
  quest[4281].startItem = 11463
  q(3661, "Favored of Elune?", 47, 42)
  q(3445, "The Sunken Temple", 51, 46)

  chapter("feralas-44", "Feralas: Feathermoon and the Twin Colossals", M.feralas, 44, 48, {
    "https://bindonforever.com/zones/feralas",
    "https://www.wowhead.com/forever/zone=357/feralas",
    qdb,
  }, { "hinterlands-48", "searing-gorge", "blasted-lands-47" }, {
    taxi("fly", B.at("Fyldren Moonfeather", 30.2, 43.2, 1444), "Feathermoon, Feralas", "Fly from Gadgetzan to Feathermoon Stronghold."),
    accept(2821, pratt, "Pratt McGrubben, by the flight master, wants thick yeti hides."),
    action("sethearth", shyria, "Bind at the Feathermoon inn.", feathermoon),
    accept(2866, shandris, "Shandris Feathermoon commands the stronghold from the building at its south end."),
    accept(4124, latronicus),
    accept(2939, troyas), accept(2982, angelas),
    finish(4124, ginro), accept(4125, ginro),
    finish(2866, gazebo, "Swim south to the Isle of Dread and find the gazebo at the Ruins of Solarsal."),
    accept(2867, gazebo), finish(2867, shandris), accept(3130, shandris),
    finish(3130, latronicus), accept(2869, latronicus),
    objective(2869, fe(nil, 26.6, 53.4), "Kill Hatecrest naga around the Ruins of Solarsal for their scales.", "10 Hatecrest Naga Scale"),
    finish(2869, latronicus), accept(2870, latronicus),
    objective(2870, fe("Lord Shalzaru", 28.5, 70.6), "Lord Shalzaru holds the cave at the south tip of the isle. Kill him for the relic.", "Mysterious Relic"),
    finish(2870, latronicus), accept(2871, latronicus), finish(2871, vestia),
    finish(4125, rowboat, "Take the ferry to the mainland and follow the coast south to the wrecked rowboat."),
    accept(4127, rowboat), finish(4127, ginro, "Bring the knife back to Ginro on Feathermoon."), accept(4129, ginro),
    finish(4129, quintis), accept(4130, quintis), finish(4130, ginro), accept(4131, ginro),
    action("goto", fe(nil, 55.4, 45.5), "Ferry back to the mainland and ride east along the road to the Twin Colossals."),
    objective(2821, fe(nil, 53.5, 55.5), "Kill Feral Scar yetis in the cave south of the road for thick hides. Keep any OOX distress beacon that drops.",
      "10 Thick Yeti Hide"),
    withItem(8705, accept(2766, nil, "If a yeti dropped the OOX-22/FE beacon, use it.")),
    finish(2766, fe("Homing Robot OOX-22/FE", 53.35, 55.7), "The robot hides in the yeti cave."),
    note(accept(2767, fe("Homing Robot OOX-22/FE", 53.35, 55.7), "Escort OOX-22/FE out of the cave and up the coast. It is a long escort; bring a partner."),
      "Escort path and ambushes need an in-game check."),
    objective(2767, fe(nil, 45.7, 43.4), "Keep the robot alive until it flies off.", "Escort OOX-22/FE"),
    along(objective(2982, fe(nil, 61.0, 56.1), "Clear Gordunni ogres in the ruins east of the Colossals.",
      "8 Gordunni Brutes", "8 Gordunni Shamans", "8 Gordunni Warlocks"), 3520, 1452),
    along(objective(3520, fe(nil, 58.6, 58.8), "Kill Vale Screechers and use the spirit flask on their corpses.", "Screecher Spirit"), 2982),
    B.objectivePart(1452, 2, fe(nil, 59.3, 60.6), "Hunt Ironfur bears for Rhapsody's livers.", "3 Ironfur Liver"),
    B.objectivePart(1452, 3, fe(nil, 62.0, 58.0), "Groddoc apes in the same valley give the other livers.", "3 Groddoc Liver"),
    accept(2969, kindal, "Kindal and Jer'kai Moonweaver camp at Ancient Glade, just north of the road."),
    objective(2969, fe(nil, 66.7, 46.8), "Free the sprite darters trapped in cages at the Grimtotem camp.", "Sprite darters freed"),
    finish(2969, kindal), accept(2970, jerkai),
    objective(2970, fe(nil, 66.9, 38.8), "Kill Grimtotem naturalists, raiders and shamans at the camp north of the glade.",
      "12 Grimtotem Naturalists", "12 Grimtotem Raiders", "12 Grimtotem Shamans"),
    finish(2970, jerkai), accept(2972, jerkai, "Jer'kai's report goes to Tyrande in Darnassus."),
    finish(4131, backpacks, "Go southeast to the Woodpaw gnoll camp and find the backpacks."),
    accept(4135, backpacks),
    withItem(11463, accept(4281, backpacks, "If you found the undelivered parcel, keep it for Thalanaar.")),
    finish(4135, pod, "Enter the Writhing Deep south of the camp and find the Zukk'ash pod."),
    accept(4265, pod),
    objective(4265, pod, "Free the captive from the pod and help him out of the hive.", "Captive freed"),
    finish(4281, fe("Falfindel Waywarder", 89.64, 46.57), "Ride east along the road to Thalanaar and hand Falfindel the parcel."),
    action("hearth", shyria, "Hearth back to Feathermoon.", feathermoon),
    finish(2821, pratt), finish(4265, ginro), accept(4266, ginro), finish(4266, shandris), accept(4267, shandris),
    finish(2982, angelas), accept(3445, angelas, "Angelas sends you to Marvon Rivetseeker in Tanaris. Keep it for later."),
    taxi("fly", B.at("Vesprystus", 58.4, 94.02, 1438), "Rut'theran Village, Teldrassil", "Fly to Rut'theran Village."),
    finish(3022, erelas, "Give Curgle's crate to Erelas Ambersky."),
    accept(3661, erelas, "Erelas wants wildkin feathers from the Hinterlands. Keep it for later."),
    finish(2939, daryn),
    accept(2940, tel("Feralas: A History", 55.22, 91.46), "Read the book on the table beside Daryn."),
    finish(2940, daryn), accept(2941, daryn, "Daryn's book goes back to Curgle in Gadgetzan."),
    action("goto", tel(nil, 55.9, 89.5), "Take the portal up into Darnassus."),
    finish(4267, on.darnassus("Gracina Spiritmight", 41.83, 85.62), "Gracina is in the Temple of the Moon."),
    finish(2972, on.darnassus("Tyrande Whisperwind", 39.1, 81.59), "Tyrande stands at the temple's upper level."),
    action("buy", on.darnassus("Auctioneer Tolon", 56.4, 51.8),
      "Optional: buy 5 Troll Tribal Necklaces for the Hinterlands and red, blue, green and yellow Power Crystals for Un'Goro at the Auction House."),
    taxi("fly", B.at("Bera Stonehammer", 51, 29.3, 1446), "Gadgetzan, Tanaris", "Fly back down to Gadgetzan."),
  })
end

-- Gadgetzan's water survey, then the Hinterlands from Aerie Peak.
do
  local tn, hl = on.tanaris, on.hinterlands
  local fizzledowser = tn("Senior Surveyor Fizzledowser", 50.21, 27.48)
  local pestlezugg = tn("Alchemist Pestlezugg", 50.89, 26.96)
  local curgle = tn("Curgle Cranklehop", 52.36, 26.91)
  local fizzgrimble = tn("Innkeeper Fizzgrimble", 52.5, 27.9)
  local talonaxe = hl("Gryphon Master Talonaxe", 9.75, 44.47)
  local rhapsody = hl("Rhapsody Shindigger", 26.94, 48.59)
  local fraggar = hl("Fraggar Thundermantle", 14.83, 44.57)
  local gadgetzan = { bind = "Gadgetzan" }

  q(2944, "The Super Snapper FX", 48, 42, 2941)
  q(992, "Gadgetzan Water Survey", 46, 38)
  q(82, "Noxious Lair Investigation", 47, 39, 992)
  q(2988, "Witherbark Cages", 45, 40)
  q(2989, "The Altar of Zul", 48, 40, 2988)
  q(1469, "Rhapsody's Tale", 43, 38, 1452)
  q(2880, "Troll Necklace Bounty", 45, 40)
  q(2877, "Skulk Rock Clean-up", 48, 40)
  q(485, "Find OOX-09/HL!", 48, 43)
  quest[485].startItem = 8704
  q(836, "Rescue OOX-09/HL!", 48, 43, 485)

  chapter("hinterlands-48", "The Hinterlands from Aerie Peak", M.hinterlands, 48, 49, {
    "https://bindonforever.com/zones/the-hinterlands",
    "https://bindonforever.com/zones/tanaris",
    "https://www.wowhead.com/forever/zone=47/the-hinterlands",
    qdb,
  }, { "ungoro-49", "searing-gorge", "blasted-lands-47" }, {
    action("sethearth", fizzgrimble, "Bind at the Gadgetzan inn. You come back here for Un'Goro.", gadgetzan),
    finish(2941, curgle, "Return Daryn's book to Curgle Cranklehop."),
    accept(2944, curgle, "Curgle lends you his camera for a turtle photo in the Hinterlands."),
    accept(992, fizzledowser, "Senior Surveyor Fizzledowser stands by the Gadgetzan water tower."),
    objective(992, tn(nil, 39.0, 29.2), "Ride west to the Noxious Lair and use the dowsing widget at its mouth.", "Tapped Dowsing Widget"),
    finish(992, fizzledowser), accept(82, fizzledowser),
    objective(82, tn(nil, 35.7, 39.8), "Kill Centipaar silithids in and around the Noxious Lair until the insect parts drop.", "Centipaar Insect Parts"),
    finish(82, pestlezugg, "Alchemist Pestlezugg is in the house beside the inn."),
    taxi("fly", B.at("Baldruc", 67.5, 51.3, 1445), "Theramore, Dustwallow Marsh", "Fly to Theramore."),
    action("boat", on.dustwallow(nil, 71.5, 56.3), "Take the ship to Menethil Harbor. Use Next when you land.",
      { name = "Theramore - Menethil Harbor" }),
    taxi("fly", B.at("Cedrik Prose", 45.7, 46.1, 1417), "Refuge Pointe, Arathi", "Fly to Refuge Pointe."),
    action("goto", hl(nil, 9.0, 47.0), "Ride west out of Arathi through Hillsbrad and take the pass north into the Hinterlands. Aerie Peak is just inside."),
    taxi("getfp", B.at("Guthrum Thunderfist", 11.1, 46.2, 1425), "Aerie Peak, The Hinterlands", "Learn the Aerie Peak flight path from Guthrum Thunderfist."),
    accept(2988, talonaxe),
    accept(2880, fraggar, "Fraggar wants troll necklaces. Witherbark trolls drop them; turn them in when you have five."),
    accept(2877, fraggar),
    finish(1452, rhapsody, "Rhapsody waits at the small camp east of Aerie Peak with his kocktail."),
    accept(1469, rhapsody, "Rhapsody's tale goes to Brohann Caskbelly in Stormwind."),
    along(B.objectivePart(2988, 1, hl(nil, 23.1, 58.8), "Open the Witherbark cages at the troll camp south of the road.",
      "First Witherbark Cage"), 2880, 3661),
    along(B.objectivePart(2988, 2, hl(nil, 23.4, 58.4), "The second cage is in the same camp.", "Second Witherbark Cage"), 2880, 3661),
    along(objective(3661, hl(nil, 28.1, 58.1), "Kill wildkin on the hills east of the camp for feathers.", "15 Wildkin Feather"), 2880),
    along(B.objectivePart(2988, 3, hl(nil, 32.0, 57.3), "The third cage sits in the eastern troll camp.", "Third Witherbark Cage"), 2880),
    finish(2880, fraggar, "Back at Aerie Peak, hand Fraggar the necklaces."),
    finish(2988, talonaxe), accept(2989, talonaxe),
    withItem(8704, accept(485, nil, "If a troll dropped the OOX-09/HL beacon, use it.")),
    objective(2877, hl(nil, 57.7, 42.8), "Ride east to Skulk Rock and kill the oozes in and around it.", "10 Green Sludges", "10 Jade Oozes"),
    finish(485, hl("Homing Robot OOX-09/HL", 49.35, 37.66), "The robot waits north of the road near Skulk Rock."),
    note(accept(836, hl("Homing Robot OOX-09/HL", 49.35, 37.66), "Escort OOX-09/HL to the coast in the southeast. Expect ambushes on the way."),
      "Escort route needs an in-game check."),
    objective(836, hl(nil, 79.3, 61.3), "Keep the robot alive until it reaches the shore.", "Escort OOX-09/HL"),
    objective(2944, hl("Gammerita", 75.9, 63.8), "Find the turtle Gammerita on the beach and take her photo with the camera.", "Snapshot of Gammerita"),
    objective(580, hl(nil, 77.9, 65.5), "Search the wreck at Pupellyverbos Port for Whiskey Slim's grog.", "Pupellyverbos Port"),
    note(finish(626, hl("Cortello's Treasure", 80.8, 46.82), "Follow the last riddle to Cortello's treasure north along the coast. Its guardian is level 50; bring help or use Next."),
      "Guard level from the classic data."),
    objective(2989, hl(nil, 48.8, 68.4), "Ride back west to the Altar of Zul and do as Talonaxe asked there.", "Altar of Zul"),
    finish(2877, fraggar, "Ride west to Aerie Peak for the last turn-ins."), finish(2989, talonaxe),
    taxi("fly", B.at("Dungar Longdrink", 71, 72.5, 1453), "Stormwind, Elwynn", "Fly to Stormwind."),
    finish(1469, on.stormwind("Brohann Caskbelly", 69.45, 40.4), "Brohann Caskbelly runs the Dwarven District's ale shop."),
    taxi("fly", B.at("Gyll", 27.5, 77.8, 1434), "Booty Bay, Stranglethorn", "Fly to Booty Bay."),
    finish(580, on.stv("Whiskey Slim", 27.14, 77.45), "Bring Whiskey Slim his grog."),
    finish(1122, on.stv("Crank Fizzlebub", 27.12, 77.21)),
    finish(2767, on.stv("Oglethorpe Obnoticus", 28.36, 76.35), "Oglethorpe Obnoticus, on the dock by the bank, built the OOX robots."),
    finish(836, on.stv("Oglethorpe Obnoticus", 28.36, 76.35)),
    action("hearth", fizzgrimble, "Hearth back to Gadgetzan.", gadgetzan),
  })
end

-- Tanaris at 49: the pirate coast, the southern ruins and Thistleshrub, then a first pass through Un'Goro.
do
  local tn, ug = on.tanaris, on.ungoro
  local bilgewhizzle = tn("Chief Engineer Bilgewhizzle", 52.46, 28.51)
  local andi = tn("Andi Lynn", 52.82, 27.4)
  local poster = tn("Wanted Poster", 51.83, 27.04)
  local fizzledowser = tn("Senior Surveyor Fizzledowser", 50.21, 27.48)
  local pestlezugg = tn("Alchemist Pestlezugg", 50.89, 26.96)
  local marin = tn("Marin Noggenfogger", 51.81, 28.66)
  local sprinkle = tn("Sprinkle", 51.06, 26.87)
  local tranrek = tn("Tran'rek", 51.57, 26.76)
  local marvon = tn("Marvon Rivetseeker", 52.71, 45.92)
  local modiste = tn("Haughty Modiste", 66.56, 22.27)
  local chief = tn("Security Chief Bilgewhizzle", 67.06, 23.89)
  local stoley = tn("Stoley", 67.11, 23.98)
  local yehkinya = tn("Yeh'kinya", 67.0, 22.4)
  local fizzgrimble = tn("Innkeeper Fizzgrimble", 52.5, 27.9)
  local torwa = ug("Torwa Pathfinder", 71.64, 75.96)
  local muigin = ug("Muigin", 42.94, 9.64)
  local linken = ug("Linken", 44.66, 8.1)
  local williden = ug("Williden Marshal", 43.95, 7.14)
  local pack = ug("A Small Pack", 63.11, 69.06)
  local gadgetzan = { bind = "Gadgetzan" }

  q(1691, "More Wastewander Justice", 44, 40, 1690)
  q(5863, "The Dunemaul Compound", 49, 44)
  q(2781, "WANTED: Caliph Scorpidsting", 46, 39)
  q(2875, "WANTED: Andre Firebeard", 45, 40)
  q(10, "The Scrimshank Redemption", 48, 39, 82)
  q(110, "Insect Part Analysis", 48, 39, 10)
  q(113, "Insect Part Analysis", 48, 39, 110)
  q(162, "Rise of the Silithid", 49, 39, 113)
  q(3161, "Gahz'ridian", 48, 43)
  q(2873, "Stoley's Shipment", 45, 40, 2872)
  q(2874, "Deliver to MacKinley", 45, 40, 2873)
  q(8365, "Pirate Hats Ahoy!", 45, 40)
  q(8366, "Southsea Shakedown", 45, 40)
  q(2876, "Ship Schedules", 45, 40)
  quest[2876].startItem = 9250
  q(351, "Find OOX-17/TN!", 48, 43)
  quest[351].startItem = 8623
  q(648, "Rescue OOX-17/TN!", 48, 43, 351)
  q(2605, "The Thirsty Goblin", 49, 44)
  q(2606, "In Good Taste", 49, 44, 2605)
  q(2641, "Sprinkle's Secret Ingredient", 49, 44, 2606)
  q(3362, "Thistleshrub Valley", 50, 45)
  q(4290, "The Fare of Lar'korwi", 53, 48)
  q(4291, "The Scent of Lar'korwi", 53, 48, 4290)
  q(3844, "It's a Secret to Everybody", 52, 47)
  q(3845, "It's a Secret to Everybody", 52, 47, 3844)
  q(3908, "It's a Secret to Everybody", 52, 47, 3845)
  q(3884, "Williden's Journal", 50, 48)
  quest[3884].startItem = 11116
  q(4141, "Muigin and Larion", 52, 47)
  q(4142, "A Visit to Gregan", 52, 47, 4141)

  chapter("ungoro-49", "Tanaris and Un'Goro Crater", M.tanaris, 49, 50, {
    "https://bindonforever.com/zones/tanaris",
    "https://bindonforever.com/zones/un-goro-crater",
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    qdb,
  }, { "stv-50", "azshara-alt", "searing-alt" }, {
    accept(1691, bilgewhizzle),
    accept(2781, poster, "Read the wanted poster on the wall by the inn."), accept(2875, poster),
    accept(10, fizzledowser),
    finish(3445, marvon, "Ride south to Marvon Rivetseeker's camp at the Broken Pillar."),
    accept(3161, marvon),
    objective(2781, tn("Caliph Scorpidsting", 60.9, 37.8), "Caliph Scorpidsting roams the dunes northeast of Marvon. Kill him for his head.",
      "Caliph Scorpidsting's Head"),
    objective(1691, tn(nil, 65.4, 36.6), "Clear Wastewander Rogues, Assassins and Shadow Mages around the camps north of the pirate coast.",
      "10 Wastewander Rogues", "10 Wastewander Assassins", "10 Wastewander Shadow Mages"),
    accept(8365, modiste, "Steamwheedle Port is just north. Haughty Modiste wants pirate hats."),
    accept(8366, chief), finish(2872, stoley), accept(2873, stoley),
    along(objective(8366, tn(nil, 72.2, 46.8), "Go south to Lost Rigger Cove and work through the Southsea pirates.",
      "10 Southsea Pirates", "10 Southsea Freebooters", "10 Southsea Dock Workers", "10 Southsea Swashbucklers"), 8365, 2873, 2875),
    along(objective(8365, tn(nil, 72.2, 46.8), "Every pirate there can drop a hat.", "20 Southsea Pirate Hat"), 8366, 2873),
    along(objective(2873, tn(nil, 72.2, 46.8), "Stoley's shipment is in a crate inside the cove.", "Stoley's Shipment"), 8366, 8365),
    objective(2875, tn("Andre Firebeard", 73.4, 47.1), "Andre Firebeard holds the upper deck of the ship at the cove's mouth.", "Firebeard's Head"),
    withItem(9250, accept(2876, nil, "If a pirate dropped a ship schedule, read it.")),
    objective(3161, tn(nil, 47.8, 64.8), "Go southwest to the Gahz'ridian ruins and dig up ornaments with Marvon's detector.", "30 Gahz'ridian Ornament"),
    objective(10, tn(nil, 56.0, 71.2), "Find Scrimshank's surveying gear in the silithid tunnels to the southeast.", "Scrimshank's Surveying Gear"),
    withItem(8623, accept(351, tn("Homing Robot OOX-17/TN", 60.23, 64.72), "If a silithid dropped the OOX-17/TN beacon, use it and find the robot.")),
    finish(351, tn("Homing Robot OOX-17/TN", 60.23, 64.72)),
    note(accept(648, tn("Homing Robot OOX-17/TN", 60.23, 64.72), "Escort OOX-17/TN north to Steamwheedle Port."),
      "Escort route needs an in-game check."),
    objective(648, tn(nil, 67.0, 23.1), "Stay with the robot until it reaches the port.", "Escort OOX-17/TN"),
    finish(8366, chief), finish(2875, chief), finish(2876, chief),
    finish(2873, stoley), accept(2874, stoley, "Stoley sends word back to MacKinley in Booty Bay. Keep it for 50."),
    finish(8365, modiste), finish(3520, yehkinya),
    action("hearth", fizzgrimble, "Hearth back to Gadgetzan.", gadgetzan),
    finish(1691, bilgewhizzle), finish(2781, bilgewhizzle),
    finish(10, fizzledowser), accept(110, fizzledowser), finish(110, pestlezugg), accept(113, pestlezugg),
    finish(113, fizzledowser), accept(162, fizzledowser, "Fizzledowser's report goes to Darnassus. Keep it for later."),
    accept(5863, andi, "Andi Lynn, by the bank, wants the Dunemaul ogres cleared."),
    accept(2605, marin, "Marin Noggenfogger, upstairs by the inn, wants a dew gland."),
    accept(3362, tranrek),
    finish(3161, marvon, "Ride back south to Marvon with the ornaments."),
    along(objective(5863, tn(nil, 42.6, 55.1), "Go west to the Dunemaul Compound. Clear Brutes and Enforcers, then Gor'marok in the middle.",
      "10 Dunemaul Brutes", "10 Dunemaul Enforcers", "Gor'marok the Ravager"), 3362),
    along(objective(3362, tn(nil, 30.5, 66.1), "Continue southwest into Thistleshrub Valley and kill the Thistleshrubs.",
      "8 Gnarled Thistleshrubs", "8 Thistleshrub Rootshapers"), 2605),
    along(objective(2605, tn(nil, 30.5, 66.1), "Dew Collectors in the valley drop the dew gland.", "Laden Dew Gland"), 3362),
    action("goto", ug(nil, 70.0, 80.0), "Take the ramp west out of Tanaris down into Un'Goro Crater."),
    accept(4290, torwa, "Torwa Pathfinder waits just inside the crater's eastern entrance."),
    accept(3844, ug("A Wrecked Raft", 63.02, 68.6), "Search the wrecked raft on the lakeshore."),
    finish(3844, pack), accept(3845, pack),
    objective(3845, pack, "Gather the compass, map and key from the raft's pack.", "Large Compass", "Curled Map Parchment", "Lion-headed Key"),
    objective(4290, ug(nil, 68.7, 56.7), "Find the threshadon carcass on the east shore and take a piece.", "Piece of Threshadon Carcass"),
    withItem(11116, accept(3884, nil, "If a crater beast dropped a mangled journal, read it.")),
    finish(3845, linken, "Ride north to Marshal's Refuge and give Linken his things."), accept(3908, linken),
    finish(3884, williden), accept(4141, muigin),
    taxi("getfp", ug("Gryfe", 45.2, 5.8), "Marshal's Refuge, Un'Goro Crater", "Learn the Marshal's Refuge flight path."),
    objective(4141, ug(nil, 67.6, 32.6), "Go east to the Bloodpetal hills and pick bloodpetals from the plants you kill.", "15 Bloodpetal"),
    finish(4141, muigin), accept(4142, muigin, "Muigin's next errand is in Feralas. Keep it for later."),
    finish(4290, torwa, "Ride south to Torwa."), accept(4291, torwa),
    objective(4291, ug(nil, 63.2, 77.4), "Kill the Lar'korwi mates west of Torwa for their pheromone glands.", "2 Ravasaur Pheromone Gland"),
    finish(4291, torwa),
    action("hearth", fizzgrimble, "Hearth back to Gadgetzan.", gadgetzan),
    finish(2605, marin), accept(2606, marin), finish(2606, sprinkle), accept(2641, sprinkle),
    finish(5863, andi), finish(3362, tranrek),
    taxi("fly", B.at("Bragok", 63.1, 37.2, 1413), "Ratchet, The Barrens", "Fly to Ratchet for the boat to Booty Bay."),
    action("boat", at(nil, 63.7, 38.6, M.barrens), "Take the boat from the Ratchet dock to Booty Bay. Use Next when you land.",
      { name = "Ratchet - Booty Bay" }),
    finish(2874, on.stv("\"Sea Wolf\" MacKinley", 27.78, 77.07), "Give Stoley's message to MacKinley."),
    finish(648, on.stv("Oglethorpe Obnoticus", 28.36, 76.35), "Report the third robot to Oglethorpe on the dock by the bank."),
  })
end

-- Alternate, 40-46: Shen'dralas, Forever's hidden Highborne temple south of the Valley of Bones.
do
  local sh = on.shendralas
  local mordent = sh("Mordent Evenshade", 35.0, 46.4)
  local biraxas = sh("Historian Biraxas", 45.8, 78.2)
  local kirandis = sh("Magister Kirandis", 47.2, 75.8)
  local liranne = sh("Liranne", 47.2, 65.2)
  local kogthug = sh("Kog'thug the Brave", 72.6, 31.4)
  local pylon = sh("Shen'dralar Pylon", 43.6, 34.2)

  q(92914, "Strange Pylons", 43, 35, nil, true)
  q(96010, "Fragments of the Pylons", 41, 35, 92914, true)
  q(96018, "Powering the Pylons", 43, 35, 96010, true)
  q(93016, "A Brief History Lesson", 43, 35, 96018, true)
  q(93394, "Meeting the Magister", 43, 35, 93016, true)
  q(99257, "A Heart of Crystal", 43, 35, nil, true)
  q(99258, "Mana Mania", 43, 35, 99257, true)
  q(93568, "Partially Digested Collar", 45, 35, nil, true)
  quest[93568].startItem = 259461
  q(93574, "Corpsefeeder's Carapace", 45, 35, nil, true)
  quest[93574].startItem = 259893
  q(93644, "Tattered Journal", 45, 35, nil, true)
  quest[93644].startItem = 260347

  alternate("shendralas", "Shen'dralas: The Pylons and the Temple", M.shendralas, 40, 46, {
    "https://www.wowhead.com/forever/zone=16651/shendralas",
    "https://www.wowhead.com/forever/quest=92914/strange-pylons",
    "https://www.wowhead.com/forever/quest=99257/a-heart-of-crystal",
    "https://warcraft.wiki.gg/wiki/Shen'dralas",
  }, { "feralas-44", "searing-gorge" }, {
    note(action("goto", pylon, "From Nijel's Point, ride south through Desolace past the Valley of Bones into Shen'dralas."),
      "Entrance path not published; check the way in from the Valley of Bones in game."),
    accept(92914, pylon, "Examine the strange pylon on the rise north of the temple."),
    finish(92914, mordent, "Mordent Evenshade studies the pylons from a camp west of the temple."),
    accept(96010, mordent),
    accept(99257, biraxas, "Historian Biraxas works inside the temple. Ask him about the pylon protectors."),
    objective(99257, sh(nil, 43.3, 32.7), "Destroy Decrepit Pylon Protectors around the northern pylons until a depleted crystal heart drops.",
      "Depleted Crystal Heart"),
    along(note(objective(96010, sh(nil, 33.0, 26.0), "Collect pylon fragments. The shards lie guarded in the Magram and Gelkis camps around the valley's edge.",
      "Pylon Fragment"), "Fragment positions need an in-game check."), 93644, 93574),
    withItem(259893, accept(93574, nil, "If Corpsefeeder dropped its carapace, read it. The beetle prowls the north of the zone.")),
    finish(93574, kogthug, "Kog'thug the Brave camps on the eastern ridge and wants the carapace."),
    withItem(260347, accept(93644, nil, "If an Outcast Necromancer dropped a tattered journal, read it.")),
    finish(96010, mordent), finish(93644, mordent), accept(96018, mordent),
    finish(99257, biraxas), accept(99258, biraxas),
    note(objective(96018, sh(nil, 47.0, 74.0), "Take the mana sieve from inside the temple and use it on the ancient mana crystals you find there.",
      "Ancient Mana Crystals"), "Crystal positions need an in-game check."),
    objective(99258, sh(nil, 37.6, 52.8), "Throw the crystal heart into an unstable mana rift where the Nascent Pylon Protectors gather.",
      "Rift fed"),
    withItem(259461, accept(93568, nil, "If a Prowler coughed up a partially digested collar, read it.")),
    finish(93568, liranne, "Liranne waits in the gardens south of the temple."),
    finish(99258, biraxas),
    finish(96018, mordent), accept(93016, mordent),
    finish(93016, mordent, "Listen to Mordent's account of the crystals."),
    accept(93394, mordent), finish(93394, kirandis, "Magister Kirandis waits deep inside the temple."),
  })
end

-- Alternate, 45-50: Thorium Point and the Cauldron in the Searing Gorge.
do
  local sg = on.searing
  local poster = sg("Wanted/Missing/Lost & Found", 37.65, 26.47)
  local scrange = sg("Taskmaster Scrange", 38.97, 27.51)
  local hansel = sg("Hansel Heavyhands", 38.58, 27.81)
  local lolo = sg("Lookout Captain Lolo Longstriker", 37.74, 26.56)
  local kalaran = sg("Kalaran Windblade", 39.06, 38.99)
  local outhouse = sg("Wooden Outhouse", 65.59, 62.17)
  local dorius = sg("Dorius Stonetender", 63.92, 60.99)

  q(7728, "STOLEN: Smithing Tuyere and Lookout's Spyglass", 48, 45)
  q(7729, "JOB OPPORTUNITY: Culling the Competition", 48, 45)
  q(7723, "Curse These Fat Fingers", 49, 45)
  q(7724, "Fiery Menace!", 49, 45)
  q(7727, "Incendosaurs? Whateverosaur is More Like It", 49, 45)
  q(7701, "WANTED: Overseer Maltorius", 50, 45)
  q(3441, "Divine Retribution", 48, 40)
  q(3442, "The Flawless Flame", 48, 40, 3441)
  q(4449, "Caught!", 45, 43)
  q(3367, "Suntara Stones", 48, 40)

  alternate("searing-gorge", "Searing Gorge: Thorium Point", M.searing, 45, 50, {
    "https://bindonforever.com/zones/searing-gorge",
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    qdb,
  }, { "ungoro-49", "blasted-lands-47" }, {
    taxi("fly", B.at("Lanie Reed", 37.9, 30.9, 1427), "Thorium Point, Searing Gorge",
      "Fly to Thorium Point. You learned it from the Badlands; if not, ride west from the Badlands through the gorge gate."),
    accept(7728, poster, "Read the board at Thorium Point."), accept(7729, poster), accept(7701, poster),
    accept(7723, hansel), accept(7724, hansel), accept(7727, hansel),
    accept(3441, kalaran, "Kalaran Windblade stands on the ledge south of Thorium Point."),
    finish(3441, kalaran, "Listen to Kalaran's story."), accept(3442, kalaran),
    along(objective(7729, sg(nil, 44.0, 36.0), "Go down into the Cauldron and kill Dark Iron Taskmasters and Slavers along the slave pens.",
      "15 Dark Iron Taskmasters", "15 Dark Iron Slavers"), 7723, 3442, 7728),
    along(objective(7723, sg(nil, 36.0, 45.3), "Heavy War Golems patrol the Cauldron's west rim. Their oil counts for Kalaran too.",
      "20 Heavy War Golems"), 7729, 3442),
    along(objective(3442, sg(nil, 54.5, 44.9), "Kill magma elementals on the east side for Hearts of Flame. Golem oil drops from the war golems.",
      "4 Heart of Flame", "4 Golem Oil"), 7729, 7723),
    along(objective(7728, sg(nil, 41.2, 49.8), "The Smithing Tuyere drops from Dark Iron Steamsmiths; the spyglass from the Lookouts on the south ramp.",
      "Smithing Tuyere", "Lookout's Spyglass"), 7729),
    along(objective(7727, sg(nil, 50.7, 35.7), "Enter the Slag Pit on the north side of the Cauldron and kill Incendosaurs in its lava pools.",
      "20 Incendosaurs"), 7701),
    note(objective(7701, sg("Overseer Maltorius", 40.8, 35.9), "Overseer Maltorius stands deep in the Slag Pit. Bring a group for him.",
      "Head of Overseer Maltorius"), "Elite in the classic data; check in game."),
    objective(7724, sg(nil, 27.3, 76.5), "Climb out of the Cauldron and hunt Greater Lava Spiders on the southwest plateaus.", "20 Greater Lava Spiders"),
    accept(4449, outhouse, "Cross to the Grimesilt dig site in the southeast and knock on the outhouse door."),
    objective(4449, sg(nil, 63.3, 60.6), "Kill Dark Iron Geologists at the dig site. You also need 15 Silk Cloth from your bags or the Auction House.",
      "8 Dark Iron Geologists", "15 Silk Cloth"),
    finish(4449, outhouse),
    note(accept(3367, dorius, "Dorius Stonetender is held at the dig site. Escort him out; it is a hard fight at the end."),
      "Escort difficulty needs an in-game check."),
    objective(3367, sg(nil, 74.45, 19.29), "Keep Dorius alive on the walk north.", "Escort Dorius"),
    finish(3367, sg("Singed Letter", 74.45, 19.29), "Pick up the singed letter Dorius leaves behind."),
    finish(3442, kalaran),
    finish(7729, scrange), finish(7728, scrange), finish(7701, lolo),
    finish(7723, hansel), finish(7724, hansel), finish(7727, hansel),
  })
end

-- Alternate, 47-50: the Bloodmages' collections in the Blasted Lands.
do
  local bl = on.blasted
  local drazial = bl("Bloodmage Drazial", 50.55, 14.2)
  local lynnore = bl("Bloodmage Lynnore", 50.64, 14.3)

  q(2581, "Snickerfang Jowls", 50, 45)
  q(2583, "A Boar's Vitality", 50, 45)
  q(2585, "The Decisive Striker", 50, 45)
  q(2601, "The Basilisk's Bite", 50, 45)
  q(2603, "Vulture's Vigor", 50, 45)

  alternate("blasted-lands-47", "Blasted Lands: The Bloodmages' Collections", M.blasted, 47, 50, {
    "https://bindonforever.com/zones/blasted-lands",
    "https://www.wowhead.com/forever/zone=4/blasted-lands",
    qdb,
  }, { "ungoro-49" }, {
    taxi("fly", B.at("Alexandra Constantine", 65.5, 24.3, 1419), "Nethergarde Keep, Blasted Lands", "Fly to Nethergarde Keep."),
    accept(2581, drazial, "The Bloodmages Drazial and Lynnore camp west of Nethergarde on the edge of the Dreadmaul hills."),
    accept(2583, drazial), accept(2585, drazial), accept(2601, lynnore), accept(2603, lynnore),
    along(objective(2581, bl(nil, 46.7, 20.6), "Starving Snickerfangs roam just south of the camp. Collect jowls, and gather the other parts as you go.",
      "3 Snickerfang Jowl", "2 Blasted Boar Lung", "Scorpok Pincer"), 2583, 2585, 2601, 2603),
    along(objective(2585, bl(nil, 49.6, 18.5), "Scorpok Stingers in the same hills give the pincers.", "3 Scorpok Pincer", "2 Vulture Gizzard",
      "Blasted Boar Lung"), 2581, 2583),
    along(objective(2583, bl(nil, 59.7, 28.3), "Go east to the Grunters and Ashmane Boars for lungs.", "3 Blasted Boar Lung", "2 Scorpok Pincer",
      "Basilisk Brain"), 2601, 2603),
    along(objective(2601, bl(nil, 61.3, 28.1), "Redstone Basilisks share those hills. Collect their brains.", "10 Basilisk Brain", "2 Vulture Gizzard"),
      2583, 2603),
    along(objective(2603, bl(nil, 60.0, 35.9), "Spiteflayer vultures circle farther south. Take their gizzards and any extra parts for the second round.",
      "10 Vulture Gizzard", "2 Snickerfang Jowl"), 2601),
    action("goto", drazial, "Ride back north to the Bloodmages' camp."),
    finish(2581, drazial), finish(2583, drazial), finish(2585, drazial), finish(2601, lynnore), finish(2603, lynnore),
  })
end
