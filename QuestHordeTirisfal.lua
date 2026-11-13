-- Horde route: Tirisfal Glades (Undead, 1-12) and Silverpine Forest (12-15), then the zeppelin
-- to Durotar. Source notes: tools/audits/2026-11-10-horde-tirisfal-silverpine.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local M = B.maps

-- Quest facts: QuestieDB (Forever) and the client reference. Chains on Forever quests follow
-- the order the givers offer them (RestedXP Forever); QuestieDB has none for them.
do
  local q, quest = B.q, B.quest
  -- Deathknell
  q(363, "Rude Awakening", 1, 1)
  q(364, "The Mindless Ones", 2, 1, 363)
  q(376, "The Damned", 2, 2)
  q(1470, "Piercing the Veil", 3, 1, nil, nil, "WARLOCK")
  q(3095, "Simple Scroll", 1, 1, 364, nil, "WARRIOR")
  q(3096, "Encrypted Scroll", 1, 1, 364, nil, "ROGUE")
  q(3097, "Hallowed Scroll", 1, 1, 364, nil, "PRIEST")
  q(3098, "Glyphic Scroll", 1, 1, 364, nil, "MAGE")
  q(3099, "Tainted Scroll", 1, 1, 364, nil, "WARLOCK")
  q(98601, "A Difficult Path", 1, 1, 364, true, "PALADIN")
  q(90902, "Rediscovering the Light", 2, 1, 98601, true, "PALADIN")
  q(91208, "Coming to Terms", 4, 1, 90902, true, "PALADIN")
  q(91209, "Continue Your Training", 4, 1, 90902, true, "PALADIN")
  q(98389, "A Light in the Darkness", 4, 1, nil, true)
  q(3901, "Rattling the Rattlecages", 3, 1, 364)
  q(3902, "Scavenging Deathknell", 3, 2, 376)
  q(380, "Night Web's Hollow", 4, 2, 376)
  q(381, "The Scarlet Crusade", 4, 2, 380)
  q(382, "The Red Messenger", 5, 2, 381)
  q(383, "Vital Intelligence", 5, 2, 382)
  q(6395, "Marla's Last Wish", 5, 3, 376)
  q(5651, "In Favor of Darkness", 4, 5, nil, nil, "PRIEST")
  q(96656, "The Adventurer", 6, 4, 382, true)
  q(8, "A Rogue's Deal", 5, 1)
  -- Brill and Tirisfal
  q(365, "Fields of Grief", 7, 4)
  q(407, "Fields of Grief", 7, 4, 365)
  q(5481, "Gordo's Task", 5, 5)
  q(5482, "Doom Weed", 6, 5, 5481)
  q(99142, "Tomb Weed", 11, 6, 5482, true)
  q(86784, "Sticks and Bones", 7, 4, nil, true)
  q(404, "A Putrid Task", 6, 4)
  q(426, "The Mills Overrun", 8, 6, 404)
  q(96607, "The Great Outdoors", 6, 4, 96656, true)
  q(96658, "Camping 101: Cooking", 6, 4, 96607, true)
  q(97957, "Camping 101: Herbalism", 6, 4, 96607, true)
  q(97959, "Camping 101: Mining", 6, 4, 96607, true)
  q(97960, "Camping 101: Skinning", 6, 4, 96607, true)
  for _, id in ipairs({ 97957, 97959, 97960 }) do quest[id].optional = true end
  q(367, "A New Plague", 6, 6)
  q(368, "A New Plague", 9, 6, 367)
  q(369, "A New Plague", 11, 6, 368)
  q(492, "A New Plague", 11, 6, 369)
  q(445, "Delivery to Silverpine Forest", 10, 9)
  q(427, "At War With The Scarlet Crusade", 8, 5, 383)
  q(370, "At War With The Scarlet Crusade", 9, 5, 427)
  q(371, "At War With The Scarlet Crusade", 10, 5, 370)
  q(374, "Proof of Demise", 7, 5, 427)
  q(99134, "Discipline", 6, 4, nil, true)
  q(99141, "Patience", 6, 4, nil, true)
  q(97558, "Hides for the Forsaken", 11, 6, nil, true)
  q(99144, "Seeking Refuge", 7, 5, nil, true)
  q(5650, "Garments of Darkness", 4, 5, 5651, nil, "PRIEST")
  q(375, "The Chill of Death", 8, 7)
  q(95314, "That Shadowvale Green Elixir", 10, 7, nil, true)
  q(398, "Wanted: Maggot Eye", 10, 6)
  q(358, "Graverobbers", 8, 4)
  q(405, "The Prodigal Lich", 8, 5, 358)
  q(359, "Forsaken Duties", 9, 6, 358)
  q(360, "Return to the Magistrate", 9, 6, 359)
  q(356, "Rear Guard Patrol", 11, 6)
  q(99156, "Rear Guard Patrol", 13, 10, 356, true)
  q(354, "Deaths in the Family", 11, 7)
  q(362, "The Haunted Mills", 10, 7)
  q(355, "Speak with Sevren", 10, 7, 354)
  q(361, "A Letter Undelivered", 7, 4)
  quest[361].startItem = 2839
  q(96895, "The Argent Emissary", 12, 9, nil, true)
  q(96897, "The Cult of the Damned", 12, 9, 96895, true)
  q(96898, "Remnants of War", 12, 9, 96895, true)
  q(96899, "Bandarion Keep", 12, 9, { 96897, 96898 }, true)
  q(96896, "A Righteous Cause", 12, 9, 96899, true)
  q(98545, "Leonid's Letter", 12, 9, 96896, true)
  q(99152, "As Above, So Below", 12, 9, nil, true)
  q(99153, "The One That Got Away", 12, 9, nil, true)
  q(95328, "Whispering Horror Residue", 13, 9, nil, true)
  quest[95328].startItem = 268812
  -- Class quests on the way.
  q(1818, "Speak with Dillinger", 10, 10, nil, nil, "WARRIOR")
  q(1819, "Ulag the Cleaver", 10, 10, 1818, nil, "WARRIOR")
  q(1820, "Speak with Coleman", 10, 10, 1819, nil, "WARRIOR")
  q(1478, "Halgar's Summons", 10, 10, nil, nil, "WARLOCK")
  q(1473, "Creature of the Void", 10, 10, 1478, nil, "WARLOCK")
  q(1471, "The Binding", 10, 10, 1473, nil, "WARLOCK")
  q(1881, "Speak with Anastasia", 10, 10, nil, nil, "MAGE")
  q(1882, "The Balnir Farmstead", 10, 10, 1881, nil, "MAGE")
  q(1885, "Mennet Carkad", 10, 10, nil, nil, "ROGUE")
  q(1886, "The Deathstalkers", 13, 10, 1885, nil, "ROGUE")
  q(1898, "The Deathstalkers", 13, 10, 1886, nil, "ROGUE")
  q(1899, "The Deathstalkers", 13, 10, 1898, nil, "ROGUE")
  q(1978, "The Deathstalkers", 13, 10, 1899, nil, "ROGUE")
  q(91282, "A Second Home", 11, 10, 91209, true, "PALADIN")
  q(91285, "Murlocs at the Gates", 11, 10, 91282, true, "PALADIN")
  q(91294, "Touring the Grounds", 11, 10, 91285, true, "PALADIN")
  q(91316, "Making Repairs", 11, 10, 91294, true, "PALADIN")
  q(91317, "The Tarnished", 12, 10, 91294, true, "PALADIN")
  q(95803, "A Token of Good Faith", 12, 10, 91317, true, "PALADIN")
  -- Silverpine Forest and the Undercity
  q(435, "Escorting Erland", 11, 10)
  q(429, "Wild Hearts", 11, 10)
  q(449, "The Deathstalkers' Report", 11, 10, 435)
  q(421, "Prove Your Worth", 10, 9)
  q(422, "Arugal's Folly", 11, 9, 421)
  q(423, "Arugal's Folly", 14, 9, 422)
  q(424, "Arugal's Folly", 15, 9, 423)
  q(477, "Border Crossings", 14, 10)
  q(478, "Maps and Runes", 14, 10, 477)
  q(481, "Dalar's Analysis", 14, 10, 478)
  q(482, "Dalaran's Intentions", 14, 10, 481)
  q(6321, "Supplying the Sepulcher", 10, 10)
  q(6323, "Ride to the Undercity", 10, 10, 6321)
  q(6322, "Michael Garrett", 10, 10, 6323)
  q(3221, "Speak with Renferrel", 12, 10, 449)
  q(437, "The Dead Fields", 14, 10)
  q(438, "The Decrepit Ferry", 16, 10, 437)
  q(439, "Rot Hide Clues", 16, 10, 438)
  q(440, "The Engraved Ring", 16, 10, 439)
  q(447, "A Recipe For Death", 12, 9)
  q(1359, "Zinge's Delivery", 15, 10, 3221)
  q(1358, "Sample for Helbrim", 15, 10, 1359)
  q(430, "Return to Quinn", 11, 10, 429)
  q(91920, "Wild Eyes", 11, 10, 430, true)
  q(91921, "Return to Quinn (Again)", 11, 10, 91920, true)
  -- Forever puts Wild Eyes and Return to Quinn (Again) between Return to Quinn and Ivar: QuestieDB's
  -- Forever fixes give 91921 as Ivar's prerequisite (its base record still says 430).
  q(425, "Ivar the Foul", 12, 10, 91921)
  q(97891, "Prompt Potion Runner", 16, 10, nil, true)
  q(5725, "The Power to Destroy...", 16, 9)
  q(840, "Conscript of the Horde", 12, 10)
  q(842, "Crossroads Conscription", 12, 10, 840)
end

local tirisfal, undercity, silverpine = M.tirisfal, M.undercity, M.silverpine
local function ti(name, x, y) return B.at(name, x, y, tirisfal) end
local function uc(name, x, y) return B.at(name, x, y, undercity) end
local function sp(name, x, y) return B.at(name, x, y, silverpine) end

local function objectivePart(id, index, place, text, label)
  local step = B.objectiveAt(id, place, text, label)
  step.objectiveIndex = index
  return step
end

-- Places and trainers used by more than one section.
local town = {
  zygand = ti("Executor Zygand", 60.59, 51.76),
  sevren = ti("Magistrate Sevren", 61.26, 50.84),
  renee = ti("Innkeeper Renee", 61.71, 52.05),
  johaan = ti("Apothecary Johaan", 59.45, 52.4),
  tower = ti(nil, 60.96, 58.63),
  ucGate = ti(nil, 61.92, 64.85),
  norman = uc("Innkeeper Norman", 67.74, 37.96),
  varimathras = uc("Varimathras", 56.25, 92.2),
  mennet = uc("Mennet Carkad", 83.51, 69.11),
  karos = sp("Karos Razok", 45.62, 42.6),
  -- GetBindLocation names (unverified: the Brill inn may report "Brill").
  brillBind = "Gallows' End Tavern",
  ucBind = "Undercity",
  trainers = {
    { "WARRIOR", ti("Austil de Mon", 61.85, 52.54) },
    { "PALADIN", ti("Shari Stilwell", 60.22, 52.66) },
    { "ROGUE", ti("Marion Call", 61.75, 52.0) },
    { "PRIEST", ti("Dark Cleric Beryl", 61.57, 52.19) },
    { "MAGE", ti("Cain Firesong", 61.97, 52.47) },
    { "WARLOCK", ti("Rupert Boch", 61.59, 52.39) },
  },
}

-- B.objective(id, x, y, ...) places the step on the Alliance default map; these sections
-- need theirs set.
local function objectiveOn(map)
  return function(id, x, y, text, ...)
    local step = B.objective(id, x, y, text, ...)
    step.map = map
    return step
  end
end

-- Deathknell (1-6)
local deathknell = (function()
  local accept, finish, along, action = B.accept, B.finish, B.along, B.action
  local objective = objectiveOn(B.maps.tirisfal)
  local mordo = ti("Undertaker Mordo", 30.22, 71.65)
  local sarvis = ti("Shadow Priest Sarvis", 30.84, 66.2)
  local elreth = ti("Novice Elreth", 30.86, 66.05)
  local venya = ti("Venya Marthand", 30.98, 66.41)
  local saltain = ti("Deathguard Saltain", 31.61, 65.6)
  local arren = ti("Executor Arren", 32.15, 66.01)
  local aramis = ti("Aramis Hammerhand", 31.1, 66.41)
  local duesten = ti("Dark Cleric Duesten", 31.11, 66.03)
  local isabella = ti("Isabella", 30.93, 66.06)
  local maximillion = ti("Maximillion", 30.91, 66.34)
  local dannal = ti("Dannal Stern", 32.69, 65.56)
  local david = ti("David Trias", 32.53, 65.65)
  local trainers = {
    { "WARRIOR", dannal }, { "PALADIN", aramis }, { "ROGUE", david },
    { "PRIEST", duesten }, { "MAGE", isabella }, { "WARLOCK", maximillion },
  }
  local steps = {
    accept(363, mordo, "Walk out of the crypt and talk to Undertaker Mordo among the graves."),
    finish(363, sarvis, "Follow the path north into Deathknell and find Shadow Priest Sarvis in the chapel."),
    accept(364, sarvis),
    accept(1470, venya, "Warlocks: Venya Marthand stands at the back of the chapel."),
    objective(1470, 31.8, 61.5, "Kill Rattlecage Skeletons in the graveyard north of the chapel and loot their skulls.",
      "3 Rattlecage Skulls"),
    finish(1470, venya),
    objective(364, 31.7, 64.0, "Kill the zombies shambling around the graves just north of the chapel.",
      "8 Mindless Zombies", "8 Wretched Zombies"),
    finish(364, sarvis),
    accept(3901, sarvis), accept(376, elreth, "Novice Elreth stands beside Sarvis."),
    accept(3095, sarvis), finish(3095, dannal, "Read the scroll, then find Dannal Stern in the house east of the chapel."),
    accept(3096, sarvis), finish(3096, david, "Read the scroll, then find David Trias in the house east of the chapel."),
    accept(3097, sarvis), finish(3097, duesten, "Read the scroll, then speak to Dark Cleric Duesten inside the chapel."),
    accept(3098, sarvis), finish(3098, isabella, "Read the scroll, then speak to Isabella inside the chapel."),
    accept(3099, sarvis), finish(3099, maximillion, "Read the scroll, then speak to Maximillion inside the chapel."),
    accept(98601, sarvis), finish(98601, aramis, "Read the scroll, then speak to Aramis Hammerhand inside the chapel."),
    accept(90902, aramis),
    action("train", nil, "Train spells for level", { level = 2 }),
    along(objective(90902, 31.9, 65.1, "Cast Holy Light on the Injured Deathguards lying around the village.",
      "5 Injured Deathguards healed"), 3901),
    along(objective(376, 34.3, 56.8, "Hunt the scavengers and bats on the hills northeast of the village for paws and wings.",
      "6 Scavenger Paws", "6 Duskbat Wings"), 3901),
    objective(3901, 31.8, 61.5, "Clear Rattlecage Skeletons in the graveyard north of the chapel.", "12 Rattlecage Skeletons"),
    finish(3901, sarvis), finish(376, elreth), accept(6395, elreth),
    finish(90902, aramis), accept(91208, aramis), accept(91209, aramis),
    accept(98389, aramis, "Aramis Hammerhand in the chapel asks for help with the webbed victims north of the village."),
    action("train", nil, "Train spells for level", { level = 4 }),
    accept(3902, saltain), accept(380, arren),
    objective(3902, 32.4, 64.4, "Pick up the scavenged crates and sacks lying beside the village houses.", "6 Scavenged Goods"),
    B.objectiveAt(91208, ti(nil, 27.68, 63.83), "Find the Frightened Paladin hiding west of the village and offer aid.",
      "Offer aid to the Frightened Paladin"),
    along(objectivePart(380, 1, ti(nil, 29.9, 57.3), "Kill Young Night Web Spiders at the mouth of Night Web's Hollow, the cave northwest of the village.",
      "10 Young Night Web Spiders"), 98389),
    along(objectivePart(380, 2, ti(nil, 24.7, 59.5), "Go deeper into the cave and kill the larger Night Web Spiders.",
      "8 Night Web Spiders"), 98389),
    along(objective(98389, 24.6, 59.5, "Free the webbed Forsaken stuck to the cave walls by clicking the cocoons.",
      "6 Webbed Forsaken freed"), 380),
    finish(3902, saltain), finish(380, arren), accept(381, arren),
    finish(91208, aramis), finish(98389, aramis),
    objective(381, 36.1, 68.7, "Cross the stream east to the Scarlet camp and loot armbands from Initiates and Converts. Leave Meven Korgal for now.",
      "12 Scarlet Armbands"),
    B.objectiveAt(6395, ti("Samuel Fipps", 36.69, 61.67),
      "Kill Samuel Fipps north of the Scarlet camp and loot his remains. Bury them at Marla's Grave behind the chapel.",
      "Samuel's Remains Buried"),
    finish(6395, elreth), accept(5651, duesten),
    finish(381, arren), accept(382, arren),
    objective(382, 36.5, 68.8, "Return to the Scarlet camp and kill Meven Korgal in the middle of it. Loot his documents.",
      "Scarlet Crusade Documents"),
    finish(382, arren), accept(383, arren), accept(96656, arren),
    action("train", nil, "Train spells for level", { level = 6 }),
    accept(8, ti("Calvin Montague", 38.23, 56.79), "Take the road east out of Deathknell. Calvin Montague waits by the bridge."),
  }
  return B.withTrainers(steps, trainers)
end)()

-- Brill, Tirisfal Glades and a first Undercity visit (6-12)
local glades = (function()
  local accept, finish, objectiveAt, along, action, withItem, forDungeon =
    B.accept, B.finish, B.objectiveAt, B.along, B.action, B.withItem, B.forDungeon
  local objective = objectiveOn(B.maps.tirisfal)
  local only = B.only
  local simmer = ti("Deathguard Simmer", 40.91, 54.17)
  local gordo = ti("Gordo", 40.77, 54.42)
  local bartholomew = ti("Deathguard Bartholomew", 58.47, 51.39)
  local dillinger = ti("Deathguard Dillinger", 58.2, 51.45)
  local eleanor = ti("Eleanor Shackleton", 57.28, 55.49)
  local shari = ti("Shari Stilwell", 60.22, 52.66)
  local pickman = ti("William Pickman", 61.75, 51.44)
  local gretchen = ti("Gretchen Dedmar", 61.89, 52.73)
  local beryl = ti("Dark Cleric Beryl", 61.57, 52.19)
  local linnea = ti("Deathguard Linnea", 65.49, 60.25)
  local shelene = ti("Shelene Rhobart", 65.43, 60.12)
  local holland = ti("Junior Apothecary Holland", 57.44, 48.85)
  local carolai = ti("Carolai Anise", 59.43, 52.19)
  local burgess = ti("Deathguard Burgess", 60.93, 52.01)
  local coleman = ti("Coleman Farthing", 61.72, 52.29)
  local hadric = ti("Hadric Harlson", 65.93, 61.13)
  local leonid = ti("Leonid Barthalomew the Revered", 22.03, 44.73)
  local breton = ti("Breton Samuels", 21.85, 45.23)
  local danitha = ti("Danitha Morr", 22.09, 44.66)
  local hilda = ti("Hilda the Breaker", 21.96, 47.25)
  local ephram = ti("Ephram Barbaro", 20.17, 46.49)
  local jorin = ti("Jorin Croge", 22.69, 44.7)
  local halgar = uc("Carendin Halgar", 85.06, 25.99)
  local anastasia = uc("Anastasia Hartwell", 85.14, 10.03)
  local zygand, sevren, johaan = town.zygand, town.sevren, town.johaan
  local classUC = { class = { "WARLOCK", "MAGE", "ROGUE" } }
  local steps = {
    accept(365, simmer, "Follow the road east. Deathguard Simmer guards the crossroads by the river."),
    accept(5481, gordo, "Gordo, the abomination, wanders the road near Deathguard Simmer."),
    action("goto", ti(nil, 58.5, 51.6), "Follow the road east to Brill."),
    accept(86784, bartholomew), accept(404, dillinger),
    objectiveAt(86784, ti(nil, 57.33, 52.39), "Pick up Dry Branches on the ground around the west side of Brill.", "6 Dry Branches"),
    finish(86784, eleanor, "Eleanor Shackleton camps by the road just south of Brill."),
    finish(96656, eleanor), accept(96607, eleanor),
    objectiveAt(96607, eleanor, "Sit by Eleanor's campfire (/sit) until you get Boosted Rest.", "Boosted Rest"),
    finish(96607, eleanor), accept(96658, eleanor),
    accept(97957, eleanor, "If you know Herbalism, ask Eleanor for the herbalism lesson too."),
    accept(97959, eleanor, "If you know Mining, ask Eleanor for the mining lesson too."),
    accept(97960, eleanor, "If you know Skinning, ask Eleanor for the skinning lesson too."),
    accept(367, johaan),
    finish(383, zygand, "Executor Zygand stands outside the town hall in the middle of Brill."),
    accept(427, zygand), accept(99141, zygand), accept(99134, zygand),
    withItem(286176, along(objectiveAt(99134, zygand, "Use the Executor's Motivator on five Deathguards in and around Brill.",
      "5 Deathguards motivated"), 99141)),
    objectivePart(99141, 1, dillinger, "Ask Deathguard Dillinger on the west side of Brill for his report.", "Dillinger's Report"),
    finish(91209, shari, "Paladins: Shari Stilwell trains Paladins next to the town hall."),
    finish(8, town.renee, "Innkeeper Renee is inside the Gallows' End Tavern."),
    action("sethearth", town.renee, "Bind your hearthstone at the Gallows' End Tavern.", { bind = town.brillBind }),
    finish(96658, pickman, "William Pickman cooks just outside the tavern."),
    finish(97957, ti("Faruza", 59.79, 52.12), "Faruza, the herbalism trainer, is in the apothecary building west of the town hall."),
    finish(5651, beryl, "Priests: Dark Cleric Beryl is upstairs in the tavern."), accept(5650, beryl),
    action("train", nil, "Train spells for level", { level = 6 }),
    objectiveAt(5650, ti("Deathguard Kel", 59.18, 46.49), "Heal Deathguard Kel north of Brill, then cast Power Word: Fortitude on him.",
      "Heal and fortify Deathguard Kel"),
    objectivePart(99141, 2, ti("Deathguard Kristof", 65.25, 60.22), "Follow the road southeast to Deathguard Kristof's camp and ask for his report.",
      "Kristof's Report"),
    accept(97558, shelene),
    finish(97960, ti("Rand Rhobart", 65.58, 60.03), "Rand Rhobart, the skinning trainer, shares the camp."),
    along(objective(404, 52.6, 57.0, "Head back west past Brill. Kill Rotting Dead and Ravaged Corpses in the fields for Putrid Claws.",
      "7 Putrid Claws"), 367, 97558),
    objectivePart(99141, 3, gordo, "Find Gordo on the road west of Brill and ask for his report.", "Gordo's Report"),
    objective(5481, 44.4, 57.3, "Pick Gloom Weed beside the river south of the road.", "3 Gloom Weed"),
    objective(365, 36.6, 50.1, "Loot pumpkins in the farm fields north of the Deathknell road.", "10 Tirisfal Pumpkins"),
    accept(99144, ti("Bareth Dawnstone", 31.96, 46.34), "Fight your way into the Scarlet tower to the west and talk to Bareth Dawnstone at the top."),
    along(objectiveAt(99144, ti(nil, 39.07, 48.77), "Escort Bareth out of the Scarlet camp and east toward Brill. Kill Scarlet Warriors on the way.",
      "Bareth Dawnstone escorted"), 427),
    objective(427, 31.8, 51.4, "Finish killing Scarlet Warriors around the Scarlet camp.", "10 Scarlet Warriors"),
    along(objective(367, 42.3, 47.8, "Kill Decrepit Darkhounds in the hills north of the road. Skin or loot them for hides too.",
      "5 Vials of Darkhound Blood"), 97558),
    action("hearth", town.renee, "Hearth to Brill, or follow the road back east.", { bind = town.brillBind }),
    finish(5481, holland, "Junior Apothecary Holland walks around the graveyard north of the town hall."), accept(5482, holland),
    finish(404, dillinger), accept(426, dillinger),
    finish(367, johaan), finish(365, johaan), accept(368, johaan), accept(407, johaan),
    accept(95314, carolai),
    finish(427, zygand), accept(370, zygand), finish(99141, zygand), finish(99134, zygand),
    accept(374, burgess), accept(398, ti("Wanted!", 60.74, 51.5), "Read the Wanted poster outside the town hall."),
    accept(358, sevren),
    finish(99144, shari, "Report Bareth's escape to Shari Stilwell next to the town hall."),
    finish(5650, beryl),
    accept(375, gretchen),
    accept(354, coleman, "Coleman Farthing, a few steps from Gretchen in the tavern, has two quests for Agamand Mills. Take both now."),
    accept(362, coleman),
    objectivePart(375, 2, ti("Abigail Shiel", 61.03, 52.35),
      "Buy the Coarse Thread now from Abigail Shiel, the trade goods vendor a short way west of Gretchen.", "Coarse Thread"),
    action("train", nil, "Train spells for level", { level = 8 }),
    along(objective(5482, 57.5, 36.0, "Go north to the gnoll camp by the lake. Pick the Doom Weed growing between the tents.",
      "10 Doom Weed"), 358),
    objectivePart(358, 1, ti(nil, 55.2, 42.5), "Kill the Rot Hide Graverobbers digging in the fields north of Brill. Loot Embalming Ichor.",
      "8 Rot Hide Graverobbers"),
    along(objective(398, 58.7, 30.8, "Kill Maggot Eye in the hut at the north end of the gnoll camp and take his paw.", "Maggot Eye's Paw"), 358),
    along(objectivePart(358, 2, ti(nil, 59.8, 32.4), "Kill the Rot Hide Mongrels around the gnoll camp.", "5 Rot Hide Mongrels"), 368),
    objectivePart(358, 3, ti(nil, 59.8, 32.4), "Finish looting Embalming Ichor from the Rot Hide gnolls.", "8 Embalming Ichor"),
    along(objective(368, 59.5, 27.9, "Kill Vile Fin murlocs on the lake shore north of the camp for scales. Skin or loot them for murloc skins too.",
      "5 Vile Fin Scales"), 97558),
    along(objectivePart(375, 1, ti(nil, 64.1, 33.5), "Kill Greater and Vampiric Duskbats east of the lake for pelts and wing membranes.",
      "5 Duskbat Pelts"), 97558),
    objective(97558, 64.1, 33.5, "Finish the hides: wing membranes from Duskbats, hides from Darkhounds and skins from Vile Fin murlocs.",
      "8 Duskbat Wing Membranes", "6 Darkhound Hides", "3 Vile Fin Murloc Skins"),
    action("hearth", town.renee, "Hearth to Brill.", { bind = town.brillBind }),
    finish(398, zygand), finish(358, sevren), accept(359, sevren), accept(405, sevren),
    finish(375, gretchen),
    finish(97558, shelene, "Follow the road southeast to Shelene Rhobart's camp."),
    finish(359, linnea), accept(360, linnea), accept(356, linnea),
    finish(368, johaan, "Return to Brill."), accept(369, johaan),
    finish(5482, holland), accept(99142, holland),
    withItem(2839, accept(361, ti(nil, 47.3, 40.8), "Thurman's ghost at Agamand Mills may drop A Letter to Yvette. Read it to start the quest.")),
    along(objective(362, 47.3, 40.8, "Go northwest to Agamand Mills. Kill Devlin Agamand near the mill for his remains.",
      "Devlin's Remains"), 426),
    along(objectivePart(354, 2, ti(nil, 49.3, 36.0), "Kill Nissa Agamand at the house north of the mill.", "Nissa's Remains"), 426),
    along(objective(354, 45.1, 31.2, "Kill Thurman and Gregor Agamand in the family estate to the north.",
      "Gregor's Remains", "Thurman's Remains"), 426),
    objective(426, 45.1, 31.2, "Kill Rattlecage and Cracked Skull Soldiers and Darkeye Bonecasters around the mills for ribs and skulls.",
      "5 Notched Ribs", "3 Blackened Skulls"),
    action("hearth", town.renee, "Hearth to Brill.", { bind = town.brillBind }),
    finish(426, dillinger),
    finish(361, ti("Yvette Farthing", 61.58, 52.6), "Yvette Farthing is upstairs in the tavern."),
    finish(354, coleman), finish(362, coleman), accept(355, coleman),
    finish(360, sevren), finish(355, sevren),
    action("train", nil, "Train spells for level", { level = 10 }),
    accept(1818, ti("Austil de Mon", 61.85, 52.54)), finish(1818, dillinger), accept(1819, dillinger),
    objectiveAt(1819, ti(nil, 59.16, 48.51), "Click the skull in the crypt in the Brill graveyard to summon Ulag the Cleaver, then kill him.",
      "Ulag the Cleaver"),
    finish(1819, dillinger), accept(1820, dillinger), finish(1820, coleman),
    accept(1478, ti("Ageron Kargal", 61.62, 52.68), "Warlocks: Ageron Kargal stands outside the tavern."),
    accept(1881, ti("Cain Firesong", 61.97, 52.47)),
    accept(1885, ti("Marion Call", 61.75, 52.0)),
    accept(96895, ti("Deathguard Terrence", 63.47, 56.55), "Deathguard Terrence guards the road south of Brill toward the Undercity."),
    accept(91282, shari),
    -- First Undercity visit: class quests only (Warlocks, Mages, Rogues).
    only(action("goto", town.ucGate, "Follow the road south into the ruins of Lordaeron and take the elevator down into the Undercity."), classUC),
    finish(1478, halgar, "Carendin Halgar is in the Magic Quarter, in the room past the warlock trainers."), accept(1473, halgar),
    finish(1881, anastasia, "Anastasia Hartwell is in the Magic Quarter."), accept(1882, anastasia),
    finish(1885, town.mennet, "Mennet Carkad is in the Rogues' Quarter."), accept(1886, town.mennet),
    only(action("goto", town.ucGate, "Ride the elevator up and leave the Undercity."), classUC),
    along(objective(370, 51.0, 69.6, "Go west of the Undercity to Solliden Farmstead. Kill Captain Perrine, Zealots and Missionaries. Loot their rings.",
      "Captain Perrine", "3 Scarlet Zealots", "3 Scarlet Missionaries"), 374),
    objective(374, 51.0, 69.6, "Finish collecting Scarlet Insignia Rings at Solliden Farmstead.", "10 Scarlet Insignia Rings"),
    objective(1473, 51.06, 67.57, "Find Egalin's Grimoire inside the farmhouse at Solliden Farmstead.", "Egalin's Grimoire"),
    only(action("goto", town.ucGate, "Warlocks: go back into the Undercity to Carendin Halgar."), { class = "WARLOCK" }),
    finish(1473, halgar), accept(1471, halgar),
    withItem(6284, objectiveAt(1471, uc(nil, 86.64, 27.1), "Use the Runes of Summoning beside Halgar and defeat the Voidwalker.", "Summoned Voidwalker")),
    finish(1471, halgar),
    only(action("goto", town.ucGate, "Warlocks: leave the Undercity and return to Brill."), { class = "WARLOCK" }),
    finish(374, burgess, "Return to Brill."),
    finish(370, zygand), accept(371, zygand),
    finish(96895, hadric, "Take the road southeast. Hadric Harlson waits near the Deathguard camp."),
    accept(96897, hadric), accept(96898, hadric),
    along(objective(96897, 70.0, 64.1, "Kill Dark Neophytes and Dark Enforcers in the cultist camp east of Hadric. Loot crystal fragments from the ground.",
      "8 Dark Neophytes", "8 Dark Enforcers"), 96898),
    objective(96898, 70.0, 64.1, "Finish picking up Necrotic Crystal Fragments around the cultist camp.", "12 Necrotic Crystal Fragments"),
    along(objective(1882, 77.5, 62.0, "Mages: pick Balnir Snapdragons in the garden at Balnir Farmstead.", "Balnir Snapdragons"), 356),
    along(objective(99142, 75.0, 59.4, "Pick Tomb Weed beside the graves of Balnir Farmstead.", "5 Tomb Weed"), 356),
    objective(356, 74.3, 61.0, "Kill Bleeding Horrors and Wandering Spirits around Balnir Farmstead.", "8 Bleeding Horrors", "8 Wandering Spirits"),
    objective(371, 79.8, 56.4, "Go northeast to the Scarlet Watch Post. Kill Scarlet Friars and Captain Vachon in the camp.",
      "Captain Vachon", "5 Scarlet Friars"),
    objective(369, 85.0, 54.7, "Kill Vicious Night Web Spiders east of the Scarlet camp for their venom.", "4 Vicious Night Web Spider Venom"),
    finish(96897, hadric, "Head back west to Hadric Harlson."), finish(96898, hadric), accept(96899, hadric),
    finish(356, linnea),
    forDungeon(accept(99156, linnea, "Ruins of Lordaeron: Linnea's next patrol hunts Riptear, a level 13 elite. Bring friends."),
      "dungeon-ruins-of-lordaeron"),
    forDungeon(objective(99156, 84.1, 43.8, "With a group, kill Riptear in the woods northeast of Balnir and take its heart.", "Riptear's Heart"),
      "dungeon-ruins-of-lordaeron"),
    forDungeon(finish(99156, linnea), "dungeon-ruins-of-lordaeron"),
    finish(369, johaan, "Return to Brill."), accept(492, johaan), accept(445, johaan),
    finish(371, zygand),
    finish(99142, holland),
    finish(407, ti("Captured Scarlet Zealot", 61.97, 51.29), "Take the Laced Pumpkin down to the cellar of the tavern."),
    finish(492, ti("Captured Mountaineer", 61.94, 51.4), "Give the drink to the Captured Mountaineer in the same cellar."),
    action("goto", ti(nil, 30.0, 48.0), "Follow the road west past Deathknell toward Bandarion Keep on the coast."),
    finish(91282, breton, "Paladins: Breton Samuels waits at the keep's gate."), accept(91285, breton),
    finish(96899, leonid, "Leonid Barthalomew is inside Bandarion Keep."), accept(96896, leonid),
    finish(96896, leonid, "Listen to Leonid and Danitha Morr talk, then speak to Leonid again."), accept(98545, leonid),
    accept(99152, hilda), accept(99153, ephram),
    objective(91285, 18.2, 60.3, "Paladins: kill Vile Fin Attackers and Seers on the shore south of the keep.",
      "8 Vile Fin Attackers", "8 Vile Fin Seers"),
    finish(91285, breton), accept(91294, breton),
    objectivePart(91294, 1, hilda, "Speak with Hilda the Breaker outside the keep.", "Speak with Hilda the Breaker"),
    objectivePart(91294, 3, ti("Ander Solliden", 23.73, 49.89), "Speak with Ander Solliden, who patrols the road south of the keep.",
      "Speak with Ander Solliden"),
    objectivePart(91294, 2, jorin, "Speak with Jorin Croge inside the keep.", "Speak with Jorin Croge"),
    finish(91294, danitha, "Danitha Morr is upstairs in the keep."),
    accept(91317, danitha), accept(91316, jorin),
    objectivePart(91317, 1, ti("Rudolph Gelhardt", 11.48, 64.2), "Kill Rudolph Gelhardt upstairs in the ruined house south of the keep. Take his head.",
      "Rudolph Gelhardt's Head"),
    objective(91317, 12.1, 64.0, "Kill Tarnished Drudges and Zealots around the ruins.", "8 Tarnished Drudges", "6 Tarnished Zealots"),
    action("goto", ti(nil, 12.92, 65.72), "Enter the Shadowvale Crypt, south of the keep."),
    along(objective(99152, 10.6, 65.4, "Kill Shadowvale Lurchers and Mystics in the crypt for glowing bones. Pick up elixir bottles as you go.",
      "6 Faintly Glowing Bones"), 95314, 91316),
    objective(99153, 9.8, 69.4, "Find the Glowing Crystal Fragment on the floor at the south end of the crypt.", "Glowing Crystal Fragment"),
    along(objective(95314, 8.5, 67.1, "Collect the Bottles of Whispering Elixir on the floor and the walls of the crypt.",
      "8 Bottles of Whispering Elixir"), 91316),
    objective(91316, 8.5, 67.1, "Paladins: pick up Sturdy Lumber piles in the crypt.", "12 Sturdy Lumber"),
    withItem(268812, accept(95328, ti("Whispering Horror", 8.53, 60.09),
      "The Whispering Horror (elite) lurks in the north of the crypt. With help, kill it and use the residue it drops. Skip it if you are alone.")),
    finish(99152, hilda, "Return to Bandarion Keep."), finish(99153, ephram),
    finish(91316, jorin), finish(91317, danitha), accept(95803, danitha),
    action("hearth", town.renee, "Hearth to Brill.", { bind = town.brillBind }),
    finish(95314, carolai),
    action("train", nil, "Train spells for level", { level = 12 }),
    action("goto", town.ucGate, "Follow the road south into the ruins and take the elevator down into the Undercity."),
    action("sethearth", town.norman, "Bind your hearthstone at the Undercity inn in the Trade Quarter.", { bind = town.ucBind }),
    finish(98545, uc("Glix Xizzix", 70.07, 47.33), "Glix Xizzix, the goblin, sits along the Trade Quarter's outer ring."),
    finish(97959, uc("Brom Killian", 56.03, 37.45), "Brom Killian, the mining trainer, is on the Trade Quarter's west side."),
    finish(95328, uc("Father Lankester", 49.14, 14.61), "Father Lankester is in the War Quarter."),
    finish(405, uc("Bethor Iceshard", 84.07, 17.45), "Bethor Iceshard is in the Magic Quarter."),
    finish(1882, anastasia),
    finish(95803, uc("Lady Sylvanas Windrunner", 58.05, 91.79), "Paladins: Sylvanas holds court in the Royal Quarter at the bottom of the city."),
  }
  return B.withTrainers(steps, town.trainers)
end)()

-- The Sepulcher, Silverpine Forest, and the trip to the Barrens (12-15)
local sepulcher = (function()
  local accept, finish, objectiveAt, along, action, forDungeon =
    B.accept, B.finish, B.objectiveAt, B.along, B.action, B.forDungeon
  local objective = objectiveOn(B.maps.silverpine)
  local erland = sp("Deathstalker Erland", 56.18, 9.18)
  local rane = sp("Rane Yorick", 53.46, 13.43)
  local quinn = sp("Quinn Yorick", 53.43, 12.59)
  local dalar = sp("Dalar Dawnweaver", 44.2, 39.81)
  local allister = sp("Shadow Priest Allister", 43.98, 40.93)
  local podrig = sp("Deathguard Podrig", 43.42, 41.68)
  local hadrec = sp("High Executor Hadrec", 43.42, 40.86)
  local renferrel = sp("Apothecary Renferrel", 42.8, 40.86)
  local boat = sp("Corpse Laden Boat", 58.44, 34.9)
  local crate = sp("Dalaran Crate", 49.89, 60.33)
  local andron = uc("Andron Gant", 54.81, 76.33)
  -- Spots the arrow visits in turn, for mobs spread over two camps.
  local function tour(step, ...)
    step.points = { ... }
    return step
  end
  -- The target button's creatures, nearest camps first.
  local function hunt(step, ...)
    step.mobs = { ... }
    return step
  end
  local steps = {
    action("goto", ti(nil, 53.2, 75.8), "Leave the Undercity and follow the road southwest out of Tirisfal into Silverpine Forest."),
    accept(435, erland, "Deathstalker Erland stands just south of the border on the road."),
    objectiveAt(435, rane, "Escort Erland south along the road to Rane Yorick. Worgs attack on the way.", "Erland must reach Rane Yorick"),
    finish(435, rane), accept(429, rane), accept(449, rane),
    hunt(objective(429, 56.6, 13.4, "Hunt Mottled Worgs in the woods east of the Yoricks until you have 6 Discolored Worg Hearts. Gorefang, a rare worg, prowls the north end.",
      "6 Discolored Worg Hearts"), "Mottled Worg", "Worg", "Gorefang"),
    objective(1886, 49.7, 32.2, "Rogues: Astor Hadren patrols the road between Brill and the Sepulcher. Talk to him, then kill him for the letter.",
      "Astor's Letter of Introduction"),
    B.taxi("getfp", town.karos, "The Sepulcher, Silverpine Forest", "Follow the road south to the Sepulcher. Learn the flight path from Karos Razok."),
    accept(421, dalar), accept(477, allister), accept(6321, podrig),
    finish(449, hadrec, "High Executor Hadrec is inside the Sepulcher's crypt."), accept(3221, hadrec), accept(437, hadrec),
    finish(429, renferrel), finish(445, renferrel), finish(3221, renferrel),
    accept(1359, renferrel), accept(447, renferrel), accept(430, renferrel),
    along(objective(421, 49.1, 36.7, "Kill Moonrage Whitescalps in the woods northeast of the Sepulcher. Kill bears for their hearts as you go.",
      "5 Moonrage Whitescalps"), 447),
    finish(421, dalar), accept(422, dalar),
    objective(422, 52.8, 28.6, "Find the Remedy of Arugal in the abandoned house east of the road, north of the Sepulcher.", "Remedy of Arugal"),
    finish(430, quinn, "Follow the road north to Quinn Yorick at the Ivar Patch."), accept(91920, quinn),
    hunt(tour(objective(91920, 58.7, 18.2, "Go east to the lake shore and kill Vile Fin murlocs until you have 3 Murloc Eyes. Their camps run north-east from here toward 64, 13.",
      "3 Murloc Eyes"), { 58.7, 18.2 }, { 63.4, 13.3 }), "Vile Fin Shredder", "Vile Fin Tidehunter"),
    along(objective(437, 45.4, 21.0, "Go west into the Dead Fields. Kill Nightlash, the ghost that rises there, for its essence.",
      "Enter the Dead Fields", "Essence of Nightlash"), 447),
    objectivePart(447, 2, sp(nil, 36.3, 14.2), "Kill Moss Stalkers near the shore northwest of the Dead Fields for Skittering Blood.",
      "6 Skittering Blood"),
    objectivePart(447, 1, sp(nil, 41.6, 21.7), "Kill Ferocious and Giant Grizzled Bears around the Dead Fields for their hearts.",
      "6 Grizzled Bear Hearts"),
    finish(422, dalar, "Return to the Sepulcher."), accept(423, dalar),
    finish(437, hadrec), accept(438, hadrec),
    finish(91920, renferrel), accept(91921, renferrel),
    -- All the shackles here, so Grimson's quest is in hand before the lake shore (he stands where
    -- the second shackle camp was).
    tour(objective(423, 43.8, 31.0, "Kill Moonrage Gluttons and Darksouls in the woods north-west of the Sepulcher until you have all the shackles. More of them roam west toward 38, 25.",
      "6 Glutton Shackles", "3 Darksoul Shackles"), { 43.8, 31.0 }, { 43.6, 27.2 }, { 39.1, 25.5 }),
    finish(423, dalar, "Return to the Sepulcher."), accept(424, dalar),
    finish(91921, quinn, "Take the potion north to Quinn Yorick."),
    accept(425, rane),
    objective(425, 51.5, 13.9, "Kill Ivar the Foul in the barn north of the Yoricks and take his head. Two Ravenclaw Slaves are with him: clear the yard and pull the one that walks about on its own first.", "Ivar's Head"),
    finish(425, rane),
    finish(438, boat, "Go southeast to the Corpse Laden Boat on the shore of the Lordamere Lake."), accept(439, boat),
    objective(424, 58.6, 44.9, "Follow the lake shore south to the Deep Elem Mine. Grimson the Pale is inside, with Moonrage Darksouls around the entrance; take his head.", "Head of Grimson"),
    finish(477, crate, "Go south-west to the road and find the Dalaran Crate near the Dalaran camp."), accept(478, crate),
    finish(478, allister, "Return to the Sepulcher."), accept(481, allister),
    finish(439, hadrec), accept(440, hadrec),
    finish(424, dalar), finish(481, dalar), accept(482, dalar), finish(482, allister),
    finish(6321, town.karos), accept(6323, town.karos),
    action("hearth", town.norman, "Hearth to the Undercity, or buy a bat ride from Karos Razok.", { bind = town.ucBind }),
    finish(6323, uc("Gordon Wendham", 61.49, 41.79), "Gordon Wendham sells goods in the Trade Quarter."), accept(6322, uc("Gordon Wendham", 61.49, 41.79)),
    finish(6322, uc("Michael Garrett", 63.25, 48.56), "Michael Garrett is the bat handler in the Trade Quarter."),
    B.taxi("getfp", uc("Michael Garrett", 63.25, 48.56), "Undercity, Tirisfal", "Learn the Undercity flight path from Michael Garrett."),
    accept(97891, uc("Alessandro Luca", 58.61, 54.68)),
    finish(97891, uc("Doctor Martin Felben", 46.61, 74.09), "Run the potion to Doctor Martin Felben in the Apothecarium before the timer runs out."),
    finish(447, uc("Master Apothecary Faranell", 48.82, 69.28), "Master Apothecary Faranell works in the Apothecarium."),
    finish(1359, uc("Apothecary Zinge", 50.14, 67.97)), accept(1358, uc("Apothecary Zinge", 50.14, 67.97)),
    -- CARRY: turnin 1358 Sample for Helbrim at Apothecary Helbrim, the Crossroads (Barrens file).
    finish(1886, town.mennet, "Rogues: return to Mennet Carkad in the Rogues' Quarter."), accept(1898, town.mennet),
    finish(1898, andron, "Andron Gant is in the Apothecarium."), accept(1899, andron),
    objectiveAt(1899, uc(nil, 55.43, 76.87), "Pick up Andron's Ledger from the table next to him.", "Andron's Ledger"),
    finish(1899, town.mennet), accept(1978, town.mennet),
    finish(1978, town.varimathras, "Take the ledger to Varimathras in the Royal Quarter."),
    -- The Power to Destroy... (5725, Varimathras) is in the Ragefire Chasm checklist's prepare phase.
    action("goto", town.ucGate, "Ride the elevator up and leave the Undercity. Follow the road north to Brill."),
    finish(440, town.sevren, "Give Deliah's Ring to Magistrate Sevren in Brill."),
    action("train", nil, "Train spells for level", { level = 14 }),
    action("boat", town.tower, "Climb the zeppelin tower between Brill and the Undercity and take the zeppelin to Durotar. Use Next when you land.",
      { name = "Tirisfal Glades - Durotar" }),
    accept(840, B.at("Takrin Pathseeker", 50.84, 43.59, M.durotar), "Walk south from the zeppelin tower along the road to Razor Hill. Takrin Pathseeker stands by the road."),
    finish(840, B.at("Kargal Battlescar", 62.26, 19.38, M.barrens), "Take the road west from Razor Hill over the bridge into the Barrens. Kargal Battlescar waits at Far Watch Post."),
    accept(842, B.at("Kargal Battlescar", 62.26, 19.38, M.barrens)),
    -- CARRY: turnin 842 Crossroads Conscription at Sergra Darkthorn, the Crossroads (Barrens file).
  }
  return B.withTrainers(steps, town.trainers)
end)()

-- Zeppelin legs for the arrow: from the Eastern Kingdoms to Durotar, the Barrens and Orgrimmar.
do
  local zeppelin = { waypoint = town.tower, label = "Take the zeppelin to Durotar from the tower outside Brill" }
  local fromSilverpine = { waypoint = town.karos, label = "Fly to the Undercity, then take the zeppelin to Durotar" }
  for _, target in ipairs({ M.durotar, M.barrens, M.orgrimmar }) do
    route.roadTo[target] = route.roadTo[target] or {}
    local roads = route.roadTo[target]
    roads[tirisfal] = roads[tirisfal] or zeppelin
    roads[undercity] = roads[undercity] or zeppelin
    roads[silverpine] = roads[silverpine] or fromSilverpine
  end
end

local sources = {
  "https://bindonforever.com/zones/tirisfal-glades",
  "https://bindonforever.com/zones/silverpine-forest",
}
route.starts.SCOURGE = "deathknell"
local sections = route.sections
sections[#sections + 1] = { id = "deathknell", title = "Deathknell", zone = tirisfal, levels = { 1, 6 },
  start = "SCOURGE", verified = false, sources = sources, steps = deathknell }
sections[#sections + 1] = { id = "tirisfal", title = "Tirisfal Glades", zone = tirisfal, levels = { 6, 12 },
  start = "SCOURGE", verified = false, sources = sources, steps = glades }
sections[#sections + 1] = { id = "silverpine", title = "Silverpine Forest", zone = silverpine, levels = { 12, 15 },
  start = "SCOURGE", verified = false, sources = sources, steps = sepulcher }

-- Alternate for Orcs, Trolls, Tauren and Skyborne at 12-15: RestedXP's Forever route for Kalimdor
-- races who want Silverpine before the Barrens. The zeppelin to Tirisfal, the Brill pickups RestedXP
-- takes (The Argent Emissary, the Cult of the Damned, Rear Guard Patrol, Delivery to Silverpine),
-- the Undercity flight path, then the Undead Silverpine loop without its Undead and Rogue quests,
-- and back to Durotar for the Crossroads. Source notes: tools/audits/2026-11-10-horde-loop-audit.md.
do
  local function stepsOf(id)
    for _, section in ipairs(route.sections) do
      if section.id == id then return section.steps end
    end
    error("Horde Silverpine alternate: no section " .. id)
  end
  local lead = { [96895] = true, [445] = true, [356] = true, [96897] = true, [96898] = true }
  -- Undead only (Supplying the Sepulcher and its ride), and the Undead Rogue chain.
  local skip = { [6321] = true, [6323] = true, [6322] = true, [840] = true, [842] = true }
  local kept = {}
  local function copy(step)
    local result = {}
    for key, value in pairs(step) do result[key] = value end
    return result
  end
  local function tidy(steps)
    for _, step in ipairs(steps) do
      if step.chain then
        local chain = {}
        for _, id in ipairs(step.chain) do if kept[id] then chain[#chain + 1] = id end end
        step.chain = #chain > 0 and chain or nil
      end
      if step.also then
        local also = {}
        for _, id in ipairs(step.also) do if kept[id] and id ~= step.quest then also[#also + 1] = id end end
        step.also = #also > 0 and also or nil
      end
    end
    return steps
  end

  local durotarTower = B.at("Zeppelin tower", 50.8, 13.8, M.durotar)
  local garrett = B.at("Michael Garrett", 63.25, 48.56, undercity)
  local ucEntrance = B.at("Undercity entrance", 61.8, 65.1, tirisfal)
  local steps = {
    B.action("boat", durotarTower,
      "Take the zeppelin to Tirisfal Glades from the tower just outside Orgrimmar's south gate. Use Next when you land."),
  }
  -- In Brill: Johaan (north), Terrence and Linnea on the way south-east, then Hadric's camp.
  local first = { [445] = 1, [96895] = 2, [356] = 3 }
  local pickups, rest = {}, {}
  for _, step in ipairs(stepsOf("tirisfal")) do
    if step.quest and lead[step.quest] and not step.class and not step.optional then
      kept[step.quest] = true
      if step.type == "accept" and first[step.quest] then
        pickups[first[step.quest]] = copy(step)
      else
        rest[#rest + 1] = copy(step)
      end
    end
  end
  for _, step in ipairs(pickups) do steps[#steps + 1] = step end
  for _, step in ipairs(rest) do steps[#steps + 1] = step end
  steps[#steps + 1] = B.action("goto", ucEntrance,
    "Enter the Undercity through the ruined city south of Brill and ride an elevator down.")
  steps[#steps + 1] = B.taxi("getfp", garrett, "Undercity, Tirisfal",
    "Learn the Undercity flight path from Michael Garrett, the bat handler east of the Trade Quarter.")
  for _, step in ipairs(stepsOf("silverpine")) do
    if step.type == "boat" then break end
    local wanted = step.quest and not skip[step.quest] and not step.class and not step.optional
      or (not step.quest and (step.type == "goto" or step.type == "getfp" and step.flight ~= "Undercity, Tirisfal"))
    if step.type == "hearth" then
      steps[#steps + 1] = B.taxi("fly", town.karos, "Undercity, Tirisfal",
        "Fly to the Undercity from Karos Razok.")
    elseif wanted then
      if step.quest then kept[step.quest] = true end
      steps[#steps + 1] = copy(step)
    end
  end
  steps[#steps + 1] = B.action("boat", town.tower,
    "Climb the zeppelin tower between Brill and the Undercity and take the zeppelin back to Durotar. Use Next when you land.")
  steps[#steps + 1] = B.action("goto", B.at("The Crossroads", 51.5, 30.34, M.barrens),
    "From the landing, take the road west past Orgrimmar's gate and on through the Barrens to the Crossroads.")

  local alternate = { id = "silverpine-early", title = "Tirisfal and Silverpine", zone = silverpine,
    levels = { 12, 15 }, start = { "ORC", "TROLL", "TAUREN", "SKYBORNE" }, alternate = true,
    suggest = { "crossroads" }, verified = false, sources = {
      "https://bindonforever.com/zones/silverpine-forest",
      "https://bindonforever.com/zones/tirisfal-glades",
    }, steps = tidy(steps) }
  route.sections[#route.sections + 1] = alternate
end
