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

  q(1459, "Reagents for Reclaimers Inc.", 35, 30, 1458)
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
    taxi("fly", on.dustwallow("Baldruc", 67.5, 51.3), "Nijel's Point, Desolace", "Fly from Theramore to Nijel's Point."),
    action("sethearth", inn, "Bind at the Nijel's Point inn. You will come back twice.", nijels),
    accept(261, anton, "Brother Anton wants the Undead Ravagers in the Valley of Bones thinned out."),
    accept(1459, kreldig), accept(1466, kreldig, "Kreldig's last reagent run sends you to the demons of Mannoroc Coven."),
    objective(1459, ds(nil, 52.2, 57.5), "Kill Scorpashi scorpids for venom and Aged Kodos for hides around the Kodo Graveyard.",
      "Scorpashi Venom", "3 Aged Kodo Hide"),
    accept(6134, hornizz, "Hornizz, the goblin on the hill west of the Kodo Graveyard, hands you a crate of ghost magnets."),
    finish(1373, uthek, "Bring the Draenethyst shard to Uthek the Wise in the Gelkis village."),
    accept(1374, uthek),
    accept(93034, uthek, "Uthek sends you to his scout Nerlokh at the Valley of Bones."),
    objective(1466, ds(nil, 51.7, 83.9),
      "Go east to Mannoroc Coven. Kill felhounds, Nether Sisters and Doomwarders for the reagents. Pull the hounds away from the casters.",
      "10 Felhound Brain", "10 Nether Wing", "Doomwarder Blood"),
    finish(93034, nerlokh, "Nerlokh waits at the southern entrance of the Valley of Bones."),
    accept(93035, nerlokh), accept(93037, nerlokh),
    along(objective(261, ds(nil, 62.0, 90.0), "Destroy Undead Ravagers through the valley. Each one counts for Brother Anton and Nerlokh.",
      "30 Undead Ravagers"), 93035, 93037, 6134),
    along(objective(93037, ds(nil, 63.8, 90.4), "Loot a Necromantic Garb from the Outcast Necromancers deeper in the valley.", "Necromantic Garb"), 261, 6134),
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
    taxi("fly", on.feralas("Fyldren Moonfeather", 30.2, 43.2), "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
    action("goto", fizzle, "Ride north out of Gadgetzan to the Mirage Raceway in the Shimmering Flats."),
    accept(1106, fizzle, "Fizzle Brassbolts has a letter for his old partner Martek in the Badlands."),
    finish(1117, kravel), accept(1118, kravel, "Keep Kravel's scheme for Booty Bay."),
    action("hearth", inn, "Hearth back to Nijel's Point.", nijels),
    finish(261, anton),
    finish(1466, kreldig), accept(1467, kreldig, "Carry Leftwitch's package to Ironforge."),
    taxi("fly", ds("Baritanas Skyriver", 64.7, 10.5), "Theramore, Dustwallow Marsh", "Fly to Theramore."),
    action("boat", on.dustwallow(nil, 71.5, 56.3), "Take the ship from the Theramore docks to Menethil Harbor. Use Next when you land.",
      { name = "Theramore - Menethil Harbor" }),
    taxi("fly", on.wetlands("Shellei Brondir", 9.5, 59.7), "Ironforge, Dun Morogh", "Fly to Ironforge."),
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
  }, { "stv-41", "searing-gorge" }, {
    finish(1467, roetten, "Take the deep road to the Hall of Explorers and give Roetten his package."),
    finish(554, stormpike, "Prospector Stormpike, in the Hall of Explorers, reads the parchment from Southshore."),
    accept(707, stormpike, "Stormpike sends you to his partner Ironband in Loch Modan."),
    finish(653, gerrig, "Gerrig Bonegrip in the Forlorn Cavern reads Myzrael's tablet."),
    accept(687, gerrig, "Gerrig sends you to Theldurin, camped in the southern Badlands."),
    taxi("fly", ifg("Gryth Thurden", 55.5, 47.7), "Thelsamar, Loch Modan", "Fly to Thelsamar."),
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
    taxi("fly", lm("Thorgrum Borrelson", 33.9, 51.0), "Ironforge, Dun Morogh", "Fly to Ironforge."),
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
  q(1364, "Mazen's Behest", 41, 37)
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
    finish(543, sw("Count Remington Ridgewell", 74.0, 30.2), "Take the tram to Stormwind. Count Remington Ridgewell waits in Stormwind Keep with the tiara."),
    finish(542, sw("Milton Sheaf", 77.07, 30.21), "Milton Sheaf is in the keep's library."),
    finish(3636, sw("Archbishop Benedictus", 50.3, 45.5), "Archbishop Benedictus is in the Cathedral of Light."),
    accept(1364, sw("Acolyte Dellis", 51.4, 73.81), "Acolyte Dellis in the Mage Quarter wants a book from the Swamp of Sorrows taken to Nethergarde."),
    accept(1477, sw("High Sorcerer Andromath", 48.71, 87.62), "High Sorcerer Andromath, in the Wizard's Sanctum, sends supplies toward Nethergarde."),
    taxi("fly", sw("Dungar Longdrink", 71.3, 72.2), "Booty Bay, Stranglethorn", "Fly to Booty Bay."),
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
    taxi("fly", st("Gyll", 27.5, 77.8), "Darkshire, Duskwood", "Fly to Darkshire."),
    finish(1477, on.duskwood("Watchmaster Sorigal", 75.78, 46.16), "Watchmaster Sorigal stands by the town hall."),
    accept(1395, on.duskwood("Watchmaster Sorigal", 75.78, 46.16)),
    action("goto", sp(nil, 3.0, 61.0), "Take the east road through Deadwind Pass into the Swamp of Sorrows."),
    finish(624, sp("A Soggy Scroll", 22.87, 48.19), "Read the soggy scroll under the bridge in the swamp's west."),
    accept(625, sp("A Soggy Scroll", 22.87, 48.19), "The riddle continues in Dustwallow Marsh. Keep it for Theramore."),
    accept(1398, biggs, "Watcher Biggs camps on the road south of the bridge."),
    along(objective(1364, sp(nil, 15.0, 37.3), "Swampwalkers and Tangled Horrors around the western pools carry Khadgar's essays.",
      "Khadgar's Essays on Dimensional Convergence"), 1258),
    along(objective(1398, sp(nil, 91.6, 70.1), "Cross the swamp to Misty Reed Strand in the far east. Pick up the sundried driftwood on the beach.",
      "Sundried Driftwood"), 1258),
    along(objective(1258, sp(nil, 91.6, 70.1), "Kill crawlers on the same beach for their legs.", "12 Pristine Crawler Leg"), 1398),
    finish(1398, biggs), accept(1425, biggs),
    action("goto", on.blasted(nil, 60.0, 15.0), "Take the road south out of the swamp into the Blasted Lands and head to Nethergarde Keep."),
    finish(1364, on.blasted("Watcher Mahar Ba", 67.65, 19.17)),
    finish(1425, on.blasted("Quartermaster Lungertz", 66.52, 21.39)), finish(1395, on.blasted("Quartermaster Lungertz", 66.52, 21.39)),
    taxi("getfp", on.blasted("Alexandra Constantine", 65.5, 24.3), "Nethergarde Keep, Blasted Lands", "Learn the Nethergarde flight path."),
    taxi("fly", on.blasted("Alexandra Constantine", 65.5, 24.3), "Booty Bay, Stranglethorn", "Fly back to Booty Bay."),
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
  local modiste = tn("Haughty Modiste", 66.56, 22.27)
  local chief = tn("Security Chief Bilgewhizzle", 67.06, 23.89)
  local stoley = tn("Stoley", 67.11, 23.98)
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
  q(2873, "Stoley's Shipment", 45, 40, 2872)
  q(8365, "Pirate Hats Ahoy!", 45, 40)
  q(8366, "Southsea Shakedown", 45, 40)
  q(3520, "Screecher Spirits", 44, 40)
  q(626, "Cortello's Riddle", 51, 35, 625)
  q(1452, "Rhapsody's Kalimdor Kocktail", 43, 38, 1451)

  chapter("tanaris-43", "Tanaris: Gadgetzan and the Shimmering Flats", M.tanaris, 43, 44, {
    "https://bindonforever.com/zones/tanaris",
    "https://bindonforever.com/zones/thousand-needles",
    "https://www.wowhead.com/forever/zone=440/tanaris",
    qdb,
  }, { "feralas-44", "shendralas" }, {
    taxi("fly", at("Bragok", 63.1, 37.2, M.barrens), "Theramore, Dustwallow Marsh", "Fly from Ratchet to Theramore."),
    finish(623, dm("Privateer Groy", 67.7, 51.7), "Privateer Groy is on the Theramore docks."),
    finish(1258, dm("Morgan Stern", 66.3, 45.5), "Morgan Stern waits in the inn with the crawler legs."),
    action("sethearth", janene, "Bind at the Theramore inn.", { bind = "Theramore Isle" }),
    objective(1187, dm(nil, 54.1, 56.5), "Take the road west out of Theramore and look for the Seaforium booster in the wrecked camp south of the road.",
      "Seaforium Booster"),
    finish(625, dm("Musty Scroll", 31.1, 66.14), "Follow the riddle to the musty scroll in the southwest of the marsh."),
    accept(626, dm("Musty Scroll", 31.1, 66.14), "The last clue points to the Hinterlands. Keep it for later."),
    taxi("fly", dm("Baldruc", 67.5, 51.3), "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
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
    accept(8365, modiste), accept(3520, yehkinya, "Yeh'kinya wants screecher spirits from Feralas."),
    accept(8366, chief), finish(2872, stoley), accept(2873, stoley),
    along(objective(1690, tn(nil, 63.9, 31.6), "Kill Wastewander Bandits and Thieves in the dunes south of the port.",
      "10 Wastewander Bandits", "10 Wastewander Thieves"), 1707),
    along(objective(1707, tn(nil, 63.9, 31.6), "The same bandits carry the water pouches.", "5 Wastewander Water Pouch"), 1690),
    B.objectivePart(1452, 1, tn(nil, 44.6, 39.6), "Hunt Rocs in the hills southwest of Gadgetzan for Rhapsody's gizzards.", "3 Roc Gizzard"),
    finish(1690, bilgewhizzle), finish(1707, luglunket),
  })
end
