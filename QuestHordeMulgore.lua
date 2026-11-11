-- Horde route: Mulgore (Tauren, 1-12). Source notes: tools/audits/2026-11-10-horde-mulgore.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE

do
  local at, q, quest = B.at, B.q, B.quest
  local accept, finish, objectiveAt, action, taxi = B.accept, B.finish, B.objectiveAt, B.action, B.taxi
  local withItem, along, only, forDungeon = B.withItem, B.along, B.only, B.forDungeon
  local mulgore, thunderBluff, barrens = B.maps.mulgore, B.maps.thunderBluff, B.maps.barrens
  local function mu(name, x, y) return at(name, x, y, mulgore) end
  local function tb(name, x, y) return at(name, x, y, thunderBluff) end
  local function objective(id, x, y, text, ...) return objectiveAt(id, mu(nil, x, y), text, ...) end
  local function objectivePart(id, index, place, text, label)
    local step = objectiveAt(id, place, text, label)
    step.objectiveIndex = index
    return step
  end

  -- Camp Narache (1-6).
  q(747, "The Hunt Begins", 2, 1)
  q(752, "A Humble Task", 2, 1)
  q(753, "A Humble Task", 3, 1, 752)
  q(3091, "Simple Note", 1, 1, 747, nil, "WARRIOR")
  q(3092, "Etched Note", 1, 1, 747, nil, "HUNTER")
  q(3093, "Rune-Inscribed Note", 1, 1, 747, nil, "SHAMAN")
  q(3094, "Verdant Note", 1, 1, 747, nil, "DRUID")
  q(750, "The Hunt Continues", 3, 1, 747)
  q(755, "Rites of the Earthmother", 3, 1, 753)
  q(757, "Rite of Strength", 4, 1, 755)
  q(95805, "Grace of An'she and Mu'sha", 4, nil, nil, true)
  q(780, "The Battleboars", 4, 1, 750)
  q(3376, "Break Sharptusk!", 5, 3)
  q(781, "Attack on Camp Narache", 4, 1)
  q(1519, "Call of Earth", 4, 4, nil, nil, "SHAMAN")
  q(1520, "Call of Earth", 4, 4, 1519, nil, "SHAMAN")
  q(1521, "Call of Earth", 4, 4, 1520, nil, "SHAMAN")
  q(763, "Rites of the Earthmother", 5, 1, 757)
  q(96659, "The Adventurer", 6, nil, nil, true)
  q(1656, "A Task Unfinished", 5, 1)

  -- Bloodhoof Village, Thunder Bluff and the rest of Mulgore (6-12).
  q(96605, "The Great Outdoors", 6, nil, 96659, true)
  q(96661, "Camping 101: Cooking", 6, nil, 96605, true)
  q(97936, "Camping 101: Skinning", 6, nil, 96605, true)
  q(97933, "Camping 101: Herbalism", 6, nil, 96605, true)
  q(97935, "Camping 101: Mining", 6, nil, 96605, true)
  for _, id in ipairs({ 97936, 97933, 97935 }) do quest[id].optional = true end
  q(745, "Sharing the Land", 6, 1)
  q(767, "Rite of Vision", 6, 3, 763)
  q(746, "Dwarven Digging", 8, 6)
  q(771, "Rite of Vision", 7, 3, 767)
  q(772, "Rite of Vision", 7, 3, 771)
  q(773, "Rite of Wisdom", 10, 3, 772)
  q(775, "Journey into Thunder Bluff", 10, 3, 773)
  q(776, "Rites of the Earthmother", 14, 3, 775)
  q(766, "Mazzranache", 8, 5)
  q(96130, "Chakuyak", 5, nil, nil, true)
  q(99411, "Kyle's Gone Missing!", 7, nil, nil, true)
  q(761, "Swoop Hunting", 6, 4)
  q(99108, "Sparring Match", 6, nil, nil, true)
  q(748, "Poison Water", 5, 4)
  q(754, "Winterhoof Cleansing", 6, 4, 748)
  q(756, "Thunderhorn Totem", 7, 4, 754)
  q(758, "Thunderhorn Cleansing", 8, 4, 756)
  q(759, "Wildmane Totem", 10, 4, 758)
  q(760, "Wildmane Cleansing", 10, 4, 759)
  q(98435, "Thunderhorn's Report", 10, nil, 760, true)
  q(99079, "Longwalker Malah", 9, nil, nil, true)
  q(99081, "Grim Tidings", 9, nil, 99079, true)
  q(99101, "Our Ancient Enemy", 9, nil, 99081, true)
  q(99080, "Drive Them Out", 11, nil, 99101, true)
  q(99082, "The High Chieftain", 11, nil, 99080, true)
  q(743, "Dangers of the Windfury", 8, 5)
  q(749, "The Ravaged Caravan", 8, 5)
  q(751, "The Ravaged Caravan", 8, 5, 749)
  q(764, "The Venture Co.", 10, 5, 751)
  q(765, "Supervisor Fizsprocket", 12, 5, 751)
  q(98424, "Fizsprocket's Notes", 10, nil, nil, true)
  q(98430, "The Longwalkers", 8, nil, nil, true)
  q(833, "A Sacred Burial", 10, 7)
  q(770, "The Demon Scarred Cloak", 12, 6)
  quest[770].startItem = 4854
  q(861, "The Hunter's Way", 10, 10)
  q(860, "Sergra Darkthorn", 10, 10, 861)
  q(744, "Preparation for Ceremony", 11, 7)
  q(76156, "Stalk With The Earthmother", 10, nil, nil, true)
  q(76160, "Stalk With The Earthmother", 11, nil, 76156, true)
  q(76240, "Stalk With The Earthmother", 11, nil, 76160, true)
  q(886, "The Barrens Oases", 10, 10)
  q(5722, "Searching for the Lost Satchel", 16, 9)
  q(5723, "Testing an Enemy's Strength", 15, 9)
  q(854, "Journey to the Crossroads", 12, 9)
  -- Level 10 class quests: the ones that lead into the Barrens are carried by the Barrens file.
  q(1505, "Veteran Uzzek", 10, 10, nil, nil, "WARRIOR")
  q(2984, "Call of Fire", 10, 10, nil, nil, "SHAMAN")
  q(5926, "Heeding the Call", 10, 10, nil, nil, "DRUID")
  q(6061, "Taming the Beast", 10, 10, nil, nil, "HUNTER")
  q(6087, "Taming the Beast", 10, 10, 6061, nil, "HUNTER")
  q(6088, "Taming the Beast", 10, 10, 6087, nil, "HUNTER")
  q(6089, "Training the Beast", 10, 10, 6088, nil, "HUNTER")
  for _, id in ipairs({ 3091, 3092, 3093, 3094, 1519, 748, 754, 756, 758, 759, 760, 98435, 854,
    5926, 6061, 6087, 6088, 6089 }) do
    quest[id].race = "TAUREN"
  end

  -- Camp Narache.
  local grull = mu("Grull Hawkwind", 44.47, 77.5)
  local hawkwind = mu("Chief Hawkwind", 43.89, 76.66)
  local windfeather = mu("Brave Windfeather", 44.18, 77.03)
  local ravenfeather = mu("Seer Ravenfeather", 44.35, 76.77)
  local greatmother = mu("Greatmother Hawkwind", 48.77, 80.92)
  local graytongue = mu("Seer Graytongue", 42.54, 90.13)
  local manifestation = mu("Minor Manifestation of Earth", 51.99, 80.4)
  local narache = {
    accept(747, grull), accept(752, hawkwind),
    along(finish(752, greatmother, "Walk southeast down the slope to the well. Kill Plainstriders on the way for meat and feathers."), 747),
    accept(753, greatmother),
    objective(753, 48.93, 81.09, "Take a Water Pitcher from the well beside Greatmother Hawkwind.", "Water Pitcher"),
    objective(747, 46.5, 82.5, "Finish the Plainstrider meat and feathers on the plain between the well and camp.",
      "7 Plainstrider Meat", "7 Plainstrider Feathers"),
    finish(747, grull),
    accept(3091, grull, "Grull also has a note from your class trainer. Take it now."),
    accept(3092, grull, "Grull also has a note from your class trainer. Take it now."),
    accept(3093, grull, "Grull also has a note from your class trainer. Take it now."),
    accept(3094, grull, "Grull also has a note from your class trainer. Take it now."),
    accept(750, grull),
    finish(753, hawkwind), accept(755, hawkwind),
    along(objective(750, 44.8, 87.5, "Head south toward the hills and kill Mountain Cougars for their pelts.", "10 Mountain Cougar Pelts"), 755),
    finish(755, graytongue, "Seer Graytongue lives up in the hills south of camp."),
    accept(757, graytongue),
    accept(95805, graytongue, "Take the incense last: it burns out 10 minutes after you accept it. Go back to camp quickly, then straight on to the shrine."),
    finish(750, grull, "Hurry north to Grull with the pelts."),
    accept(780, grull), accept(3376, windfeather),
    finish(3091, mu("Harutt Thunderhorn", 43.75, 76.72)),
    finish(3092, mu("Lanka Farshot", 43.96, 76.35)),
    finish(3093, mu("Meela Dawnstrider", 44.58, 76.56)),
    finish(3094, mu("Gart Mistrunner", 44.65, 76.55)),
    action("train", nil, "Visit your class trainer in camp. Train spells for level", { level = 4 }),
    accept(1519, ravenfeather, "Shamans: Seer Ravenfeather has your first totem quest."),
    along(finish(95805, mu("Ritual Fire", 56.61, 88.7), "Run southeast to the shrine of An'she and Mu'sha in the hills and use the Ritual Fire before the incense burns out. Kill Battleboars on the way."), 780),
    objective(780, 53.75, 84.51, "Hunt Battleboars on the plain between the shrine and Brambleblade Ravine.",
      "8 Battleboar Snouts", "8 Battleboar Flanks"),
    along(objective(3376, 61.03, 78.0, "Go east into Brambleblade Ravine and kill Chief Sharptusk Thornmantle at the far end for his head. Loot belts from the quilboar on the way.",
      "Chief Sharptusk Thornmantle's Head"), 757, 1519),
    withItem(4851, accept(781, mu(nil, 59.8, 82.2), "Pick up the Dirt-stained Map lying on the ground in the ravine and use it to start the quest.")),
    along(objective(757, 60.4, 78.6, "Kill Bristlebacks in the ravine until you have 12 belts.", "12 Bristleback Belts"), 1519),
    objective(1519, 60.3, 80.1, "Shamans: kill Bristleback Shamans in the ravine for Ritual Salve.", "2 Ritual Salve"),
    action("hearth", hawkwind, "Hearth back to Camp Narache, or walk west out of the ravine.", { bind = "Camp Narache" }),
    finish(780, grull), finish(3376, windfeather),
    finish(1519, ravenfeather), accept(1520, ravenfeather),
    finish(781, hawkwind), finish(757, hawkwind), accept(763, hawkwind), accept(96659, hawkwind),
    withItem(6635, finish(1520, manifestation, "Shamans: walk east to Kodo Rock and drink the Earth Sapta there. Talk to the spirit that appears.")),
    accept(1521, manifestation),
    finish(1521, ravenfeather, "Bring the Rough Quartz back to Seer Ravenfeather."),
    action("train", nil, "Visit your class trainer before leaving camp. Train spells for level", { level = 6 }),
    accept(1656, mu("Antur Fallow", 39.16, 81.24), "Find Antur Fallow on the western edge of Red Cloud Mesa. He sends you down to Bloodhoof Village."),
  }
  local naracheTrainers = {
    { "WARRIOR", mu("Harutt Thunderhorn", 43.75, 76.72) },
    { "HUNTER", mu("Lanka Farshot", 43.96, 76.35) },
    { "SHAMAN", mu("Meela Dawnstrider", 44.58, 76.56) },
    { "DRUID", mu("Gart Mistrunner", 44.65, 76.55) },
  }

  -- Bloodhoof Village and Thunder Bluff.
  local kaga = mu("Kaga Wildhoof", 46.16, 67.3)
  local kauth = mu("Innkeeper Kauth", 45.93, 64.16)
  local baine = mu("Baine Bloodhoof", 46.67, 63.38)
  local zarlman = mu("Zarlman Two-Moons", 46.88, 61.19)
  local maur = mu("Maur Raincaller", 46.23, 60.8)
  local yaw = mu("Yaw Sharpmane", 46.93, 59.65)
  local ahab = mu("Ahab Wheathoof", 47.29, 57.65)
  local harken = mu("Harken Windtotem", 47.67, 62.68)
  local krang = mu("Krang Stonehoof", 48.35, 63.74)
  local mull = mu("Mull Thunderhorn", 47.52, 63.58)
  local wildrunner = mu("Brave Wildrunner", 46.68, 63.83)
  local ruul = mu("Ruul Eagletalon", 46.54, 64.94)
  local skorn = mu("Skorn Whitecloud", 46.03, 63.44)
  local morin = mu("Morin Cloudstalker", 54.76, 64.27)
  local malah = mu("Malah Longwind", 57.62, 63.18)
  local crate = mu("Sealed Supply Crate", 51.87, 53.37)
  local wiserunner = mu("Seer Wiserunner", 34.31, 43.29)
  local raintotem = mu("Lorekeeper Raintotem", 56.98, 34.55)
  local spirit = mu("Ancestral Spirit", 58.31, 30.7)
  local lift = mu(nil, 37.3, 38.4)
  local liftTop = tb(nil, 35.33, 63.32)
  local boarton = tb("Boarton Shadetotem", 39.44, 65.82)
  local pala = tb("Innkeeper Pala", 45.81, 64.71)
  local cairne = tb("Cairne Bloodhoof", 60.3, 51.68)
  local eyahn = tb("Eyahn Eagletalon", 37.75, 59.57)
  local melor = tb("Melor Stonehoof", 61.54, 80.92)
  local rahauro = tb("Rahauro", 70.14, 29.52)
  local bloodhoofTrainers = {
    { "WARRIOR", krang },
    { "HUNTER", yaw },
    { "SHAMAN", mu("Narm Skychaser", 47.4, 62.54) },
    { "DRUID", mu("Gennia Runetotem", 47.48, 62.95) },
  }
  local bloodhoof = {
    finish(96659, kaga, "Follow the road north off the mesa. Kaga Wildhoof camps beside the road just south of Bloodhoof Village."),
    accept(96605, kaga),
    objective(96605, 46.16, 67.3, "Sit down by Kaga's campfire until you get Boosted Rest.", "Boosted Rest"),
    finish(96605, kaga), accept(96661, kaga),
    accept(97936, kaga, "If you know Skinning, ask Kaga for the skinning lesson too."),
    accept(97933, kaga, "If you know Herbalism, ask Kaga for the herbalism lesson too."),
    accept(97935, kaga, "If you know Mining, ask Kaga for the mining lesson too."),
    finish(1656, kauth, "Bring the furs to Innkeeper Kauth in the inn on the west side of the village."),
    action("sethearth", kauth, "Bind your hearthstone at the Bloodhoof inn.", { bind = "Bloodhoof Village" }),
    finish(763, baine, "Baine Bloodhoof stands in the middle of the village."),
    accept(745, baine), accept(767, baine), accept(746, baine),
    finish(767, zarlman), accept(771, zarlman),
    accept(766, maur), accept(96130, yaw),
    accept(99411, ahab, "Ahab Wheathoof at the north end of the village gives you the meat for his dog."),
    finish(96661, mu("Pyall Silentstride", 44.92, 61.67), "Talk to Pyall Silentstride on the west side of the village about Cooking."),
    finish(97936, mu("Yonn Deepcut", 44.97, 61.4), "Yonn Deepcut stands next to Pyall."),
    accept(761, harken), accept(99108, krang),
    objective(99108, 48.76, 63.68, "Beat three Novice Warriors in the sparring ring beside Krang, or win three duels.", "3 duels won"),
    finish(99108, krang),
    accept(748, mull), accept(99079, wildrunner), accept(743, ruul),
    along(objective(748, 49.43, 68.81, "Go south of the village and kill Prairie Wolves and Adult Plainstriders for paws and talons. Pick up Ambercorns from the ground under the trees as you go.",
      "6 Prairie Wolf Paws", "4 Plainstrider Talons"), 771, 761, 766),
    finish(748, mull), accept(754, mull),
    along(withItem(5411, objective(754, 51.82, 68.49, "Walk southeast to the Winterhoof Water Well and use the cleansing totem beside it.",
      "Cleanse the Winterhoof Water Well")), 771),
    along(objective(771, 52.14, 68.59, "Pick up Well Stones around the well, plus any Ambercorns you still need from the ground nearby.",
      "2 Well Stones", "2 Ambercorns"), 761, 766),
    finish(754, mull), accept(756, mull),
    finish(771, zarlman),
    accept(772, zarlman, "Zarlman gives you the Water of the Seers. Drinking it by the village fire shows the way, but all you need is to find Seer Wiserunner later."),
    withItem(287505, objective(99411, 47.15, 61.36, "Find Kyle the Frenzied running around the village and feed him the Tender Strider Meat.", "Kyle fed")),
    finish(99411, ahab),
    action("train", nil, "Visit your class trainer in the village. Train spells for level", { level = 8 }),
    accept(749, morin, "Morin Cloudstalker travels the road east of the village with his kodo."),
    finish(99079, malah, "Follow the road east to Malah Longwind near the edge of Mulgore."),
    accept(99081, malah),
    along(finish(749, crate, "Walk north to the Ravaged Caravan and open the Sealed Supply Crate. Kill stalkers and cougars for claws on the way."), 756),
    accept(751, crate),
    along(objective(756, 55.5, 53.7, "Finish the claws in the grass east of the caravan: Prairie Stalkers and Flatland Cougars.",
      "6 Stalker Claws", "6 Cougar Claws"), 761, 766),
    finish(756, mull, "Head back through the village to Mull."), accept(758, mull),
    objective(96130, 39.39, 66.04, "Go west of the village and kill Chakuyak for her pelt.", "Chakuyak's Pelt"),
    along(objective(745, 36.56, 65.1, "Kill Palemane gnolls around Palemane Rock to the west.",
      "10 Palemane Tanners", "8 Palemane Skinners", "5 Palemane Poachers"), 766),
    accept(98430, mu("Perith Stormhoof", 33.11, 65.95), "Perith Stormhoof is a prisoner in the gnoll cave at Palemane Rock."),
    objective(98430, 37.16, 64.86, "Escort Perith out of the cave and away from the camp. Kill the gnolls that attack him.", "Escort Perith Stormhoof"),
    finish(96130, yaw, "Return to Yaw Sharpmane in Bloodhoof Village."),
    finish(99081, wildrunner), accept(99101, wildrunner),
    finish(745, baine), finish(99101, baine), accept(99080, baine),
    along(withItem(5415, objective(758, 44.15, 51.03, "Follow the road north to the Thunderhorn Water Well and use the cleansing totem. Kill Swoops for quills on the way.",
      "Cleanse the Thunderhorn Water Well")), 761, 766),
    withItem(4702, objective(746, 33.11, 54.79, "Go west to the Bael'dun dig site. Kill the dwarves for Prospector's Picks and use the picks at the forge in the camp to break them.",
      "5 Broken Tools")),
    objective(743, 33.5, 46.81, "Climb the hills north of the dig site and kill Windfury harpies for talons.", "8 Windfury Talons"),
    finish(772, wiserunner, "Seer Wiserunner sits in a small cave just north of the harpies."),
    accept(773, wiserunner),
    action("goto", lift, "Walk north to Thunder Bluff and ride the lift up the side of the mesa."),
    accept(76156, boarton, "Boarton Shadetotem is stealthed near the top of the lift. Look closely to find him."),
    action("sethearth", pala, "Bind your hearthstone at the Thunder Bluff inn.", { bind = "Thunder Bluff" }),
    taxi("getfp", tb("Tal", 47.0, 49.82), "Thunder Bluff, Mulgore", "Learn the flight path from Tal at the top of the wind rider tower."),
    finish(97935, tb("Brek Stonehoof", 34.37, 57.9), "Miners: Brek Stonehoof has the next mining lesson."),
    finish(97933, tb("Komin Winterhoof", 49.95, 40.41), "Herbalists: Komin Winterhoof has the next herbalism lesson."),
    action("goto", liftTop, "Ride the lift back down to Mulgore."),
    withItem(4854, accept(770, nil, "If Ghost Howl, a level 12 grey wolf that roams Mulgore, dropped the Demon Scarred Cloak, use it to start the quest.")),
    accept(833, raintotem, "Go east from Thunder Bluff to Red Rocks. Lorekeeper Raintotem waits at the foot of the rocks."),
    finish(773, spirit, "Climb Red Rocks to the Ancestral Spirit."),
    accept(775, spirit),
    objective(833, 56.97, 34.55, "Kill Bristleback Interlopers around the base of Red Rocks.", "8 Bristleback Interlopers"),
    finish(833, raintotem),
    objective(761, 49.58, 28.52, "Hunt Swoops on the plain west of Red Rocks until you have the quills.", "8 Trophy Swoop Quills"),
    objective(766, 52.97, 40.27, "Finish any Mazzranache parts on the way south: Prairie Wolves, Flatland Cougars, Plainstriders and Swoops.",
      "Prairie Wolf Heart", "Flatland Cougar Femur", "Plainstrider Scale", "Swoop Gizzard"),
    finish(770, skorn, "Give the Demon Scarred Cloak to Skorn Whitecloud in Bloodhoof Village."),
    accept(861, skorn, "Skorn Whitecloud in Bloodhoof Village wants Flatland Prowler claws taken to Thunder Bluff."),
    finish(746, baine), finish(743, ruul),
    finish(758, mull), accept(759, mull),
    finish(761, harken), finish(766, maur),
    action("train", nil, "Visit your class trainer in the village. Train spells for level", { level = 10 }),
    accept(5926, mu("Gennia Runetotem", 47.48, 62.95), "Druids: Gennia sends you to Turak Runetotem in Thunder Bluff. If she offers nothing, use Next."),
    accept(6061, yaw, "Hunters: Yaw Sharpmane starts your pet training."),
    withItem(15914, objective(6061, 39.88, 61.1, "Hunters: use the Taming Rod on an Adult Plainstrider west of the village, from as far away as you can.", "Tame an Adult Plainstrider")),
    finish(6061, yaw), accept(6087, yaw),
    withItem(15915, objective(6087, 48.32, 48.45, "Hunters: use the new Taming Rod on a Prairie Stalker north of the village.", "Tame a Prairie Stalker")),
    finish(6087, yaw), accept(6088, yaw),
    withItem(15916, objective(6088, 46.45, 47.66, "Hunters: use the last Taming Rod on a Swoop north of the village.", "Tame a Swoop")),
    finish(6088, yaw), accept(6089, yaw),
    finish(751, morin, "Find Morin Cloudstalker on the east road again."),
    accept(764, morin), accept(765, morin),
    along(objective(99080, 60.57, 61.72, "Go east to the Galak centaur camp. Kill centaurs and outriders, and Herak the Pillager for his head.",
      "6 Galak Centaurs", "4 Galak Outrunners", "Herak's Head"), 759),
    objective(759, 62.39, 69.1, "Kill Prairie Wolf Alphas southeast of the centaur camp for their teeth.", "8 Prairie Alpha Teeth"),
    along(objective(765, 61.23, 49.33, "Go north to the Venture Co. mine. Fight through to Supervisor Fizsprocket inside and loot his clipboard and plans.",
      "Fizsprocket's Clipboard"), 764, 76156),
    withItem(281031, accept(98424, mu(nil, 61.23, 49.33), "Read the Mulgore Expansion Plans from Fizsprocket to start the quest.")),
    objectivePart(98424, 1, mu(nil, 58.62, 47.32), "Find the Shredder Operation Instructions in the mine tunnels.", "Shredder Operation Instructions"),
    objectivePart(98424, 2, mu(nil, 61.66, 47.26), "Find the Barrens Operations Best Practices in the mine.", "Barrens Operations Best Practices"),
    objectivePart(98424, 3, mu(nil, 59.03, 46.43), "Find the last page about Gerenzo in the mine.", "One Gerenzo, of Stonetalon"),
    along(objective(76156, 60.24, 49.87, "Loot Seaforium Mining Charges from the carts of blasting supplies in the mine.", "5 Seaforium Mining Charges"), 764),
    objective(764, 58.22, 52.86, "Finish the Venture Co. Workers and Supervisors outside the mine.", "14 Venture Co. Workers", "6 Venture Co. Supervisors"),
    finish(764, morin, "Return to Morin Cloudstalker on the east road."),
    finish(765, morin), finish(98424, morin),
    finish(99080, baine), accept(99082, baine),
    finish(759, mull), accept(760, mull),
    action("hearth", pala, "Hearth to Thunder Bluff.", { bind = "Thunder Bluff" }),
    finish(76156, boarton), accept(76160, boarton),
    finish(6089, tb("Holt Thunderhorn", 57.3, 89.79), "Hunters: Holt Thunderhorn is on Hunter Rise."),
    accept(744, eyahn),
    finish(775, cairne, "Cross the bridges to High Chieftain Cairne Bloodhoof in the great lodge."),
    accept(776, cairne), finish(99082, cairne), finish(98430, cairne),
    finish(5926, tb("Turak Runetotem", 76.48, 27.22), "Druids: Turak Runetotem is on Elder Rise. Your next druid quests are in the class guides."),
    only(accept(886, tb("Arch Druid Hamuul Runetotem", 78.62, 28.56), "Druids: Hamuul next to Turak sends you to the Crossroads."), { class = "DRUID" }),
    forDungeon(accept(5723, rahauro, "If you plan to run Ragefire Chasm, Rahauro on Elder Rise has two quests for it."), "dungeon-ragefire-chasm"),
    forDungeon(accept(5722, rahauro), "dungeon-ragefire-chasm"),
    action("goto", liftTop, "Ride the lift down to Mulgore."),
    along(objective(744, 32.22, 29.44, "Go north along the cliffs to the Windfury harpies. Sorceresses drop Azure Feathers, Matriarchs drop Bronze Feathers. Pick up Windfury Cones under the trees as you go.",
      "6 Azure Feathers", "6 Bronze Feathers"), 76160),
    withItem(206176, objective(76160, 32.8, 32.2, "Gather the rest of the 8 Windfury Cones under the trees near the harpies, then use the Mortar and Pestle on them.", "Pine Salve")),
    along(withItem(5416, objective(760, 42.49, 24.68, "Head east to the Wildmane Water Well and use the cleansing totem.", "Cleanse the Wildmane Water Well")), 861),
    along(objective(776, 50.92, 23.34, "Find Arra'chea, the big kodo that roams the plain east of the well, and take its horn.", "Horn of Arra'chea"), 861),
    objective(861, 43.55, 22.3, "Kill Flatland Prowlers on the northern plain for their claws.", "4 Flatland Prowler Claws"),
    action("goto", lift, "Return to Thunder Bluff by the lift."),
    finish(776, cairne), finish(744, eyahn),
    finish(76160, boarton), accept(76240, boarton),
    withItem(206344, objectiveAt(76240, boarton, "Buy a Raw Brilliant Smallfish at the auction house or catch one in the pond, then use the Knife Set in front of Boarton.", "Fish Chunks")),
    finish(76240, boarton),
    finish(861, melor, "Melor Stonehoof is on Hunter Rise."),
    accept(860, melor),
    -- CARRY: turnin 860 Sergra Darkthorn at Sergra Darkthorn, Crossroads (the Barrens file owns the Crossroads).
    -- CARRY: turnin 886 The Barrens Oases at Tonga Runetotem, Crossroads (druids only here).
    -- Veteran Uzzek (1505, Warriors) and Call of Fire (2984, Shamans) are left for the class-quest pass.
    action("goto", liftTop, "Ride the lift down and follow the road south to Bloodhoof Village."),
    finish(760, mull),
    accept(98435, mull, "Mull has a report for Arch Druid Hamuul in Thunder Bluff. Keep it until your next visit there."),
    -- CARRY: turnin 98435 Thunderhorn's Report at Arch Druid Hamuul Runetotem, Thunder Bluff (next Thunder Bluff visit, e.g. Ride to Thunder Bluff from the Crossroads).
    action("train", nil, "Visit your class trainer in the village. Train spells for level", { level = 12 }),
    action("goto", mu(nil, 65.1, 63.6), "Follow the road east out of Mulgore and down into the Barrens."),
    taxi("getfp", at("Omusa Thunderhorn", 44.45, 59.15, barrens), "Camp Taurajo, The Barrens", "Learn the flight path from Omusa Thunderhorn at Camp Taurajo."),
    accept(854, at("Kirge Sternhorn", 44.88, 58.61, barrens)),
    -- CARRY: turnin 854 Journey to the Crossroads at Thork, Crossroads (the Barrens file starts there).
    action("goto", at(nil, 51.9, 30.3, barrens), "Follow the road north from Camp Taurajo to the Crossroads."),
  }

  route.starts.TAUREN = "camp-narache"
  local sources = {
    "https://bindonforever.com/zones/mulgore",
    "https://www.warcrafttavern.com/forever/guides/tauren/",
    "https://mobalytics.gg/wow-forever/guides/wow-forever-race-class-combinations",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
    "https://wago.tools/db2/QuestV2?build=1.60.1.70862",
  }
  route.sections[#route.sections + 1] = { id = "camp-narache", title = "Camp Narache", zone = mulgore, levels = { 1, 6 },
    start = "TAUREN", verified = false, sources = sources, steps = B.withTrainers(narache, naracheTrainers) }
  route.sections[#route.sections + 1] = { id = "mulgore", title = "Mulgore", zone = mulgore, levels = { 6, 12 },
    start = "TAUREN", verified = false, sources = sources, steps = B.withTrainers(bloodhoof, bloodhoofTrainers) }

  -- Arrow legs for the lift and the road east.
  route.roadTo[thunderBluff] = route.roadTo[thunderBluff] or {}
  route.roadTo[thunderBluff][mulgore] = { waypoint = lift, label = "Ride the lift up to Thunder Bluff" }
  route.roadTo[mulgore] = route.roadTo[mulgore] or {}
  route.roadTo[mulgore][thunderBluff] = { waypoint = liftTop, label = "Ride the lift down to Mulgore" }
  route.roadTo[barrens] = route.roadTo[barrens] or {}
  route.roadTo[barrens][mulgore] = { waypoint = mu(nil, 65.1, 63.6), label = "Take the east road into the Barrens" }
end
