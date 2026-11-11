-- Horde route: shared setup, then Durotar (Orc and Troll, 1-12). The other Horde files load
-- after this one and add their sections to LevelingCodexQuests.HORDE in level order.
-- Source notes: tools/audits/2026-11-10-horde-1-30.md.
local B = LevelingCodexQuests.build
local M = B.maps
local durotar, mulgore, barrens, tirisfal, silverpine = 1411, 1412, 1413, 1420, 1421
local orgrimmar, thunderBluff, undercity = 1454, 1456, 1458
local stonetalon, ashenvale, hillsbrad, needles = 1442, 1440, 1424, 1441
local alterac, arathi, desolace, dustwallow = 1416, 1417, 1443, 1445

M.durotar, M.mulgore, M.barrens, M.tirisfal, M.silverpine = durotar, mulgore, barrens, tirisfal, silverpine
M.orgrimmar, M.thunderBluff, M.undercity = orgrimmar, thunderBluff, undercity
M.stonetalon, M.ashenvale, M.hillsbrad, M.needles = stonetalon, ashenvale, hillsbrad, needles
M.alterac, M.arathi, M.desolace, M.dustwallow = alterac, arathi, desolace, dustwallow

-- Copy filter fields (class, race, optional...) onto a step built by accept/finish/action.
function B.only(step, rules)
  for key, value in pairs(rules) do step[key] = value end
  return step
end

-- One objective of a quest at its own place (see objectivePart in QuestData.lua).
function B.objectivePart(id, index, place, text, label)
  local step = B.objectiveAt(id, place, text, label)
  step.objectiveIndex = index
  return step
end

local route = {
  -- Racial starts are added by the file that holds each start.
  starts = {},
  -- Width and height in yards, from UiMapAssignment in the Forever client reference.
  extents = {
    [durotar] = { 5287.5, 3525.0 }, [mulgore] = { 6154.167, 4102.082 }, [barrens] = { 10133.333, 6756.25 },
    [tirisfal] = { 4518.75, 3012.5 }, [silverpine] = { 4200.0, 2800.0 }, [orgrimmar] = { 1402.604, 935.417 },
    [thunderBluff] = { 1043.75, 695.833 }, [undercity] = { 959.375, 640.104 },
    [stonetalon] = { 4883.333, 3256.25 }, [ashenvale] = { 5766.666, 3843.75 }, [hillsbrad] = { 3200.0, 2133.333 },
    [needles] = { 4400.0, 2933.333 }, [alterac] = { 2800.0, 1866.667 }, [arathi] = { 3600.0, 2400.0 },
    [desolace] = { 4495.833, 2997.917 }, [dustwallow] = { 5250.0, 3500.0 },
  },
  -- Kalimdor and the Eastern Kingdoms are separate flight networks (zeppelins link them).
  flightNetwork = {
    [durotar] = 1, [orgrimmar] = 1, [mulgore] = 1, [thunderBluff] = 1, [barrens] = 1, [stonetalon] = 1,
    [ashenvale] = 1, [needles] = 1, [desolace] = 1, [dustwallow] = 1,
    [tirisfal] = 2, [undercity] = 2, [silverpine] = 2, [hillsbrad] = 2, [alterac] = 2, [arathi] = 2,
  },
  roadTo = {},
  sections = {},
}
LevelingCodexQuests.HORDE = route

-- Durotar: the Valley of Trials (1-6), then Sen'jin, Razor Hill and Orgrimmar (6-12), ending at
-- the Barrens' Far Watch Outpost. Order from RestedXP's Forever Durotar chapters (its Hunter and
-- Shaman path, which stays in Kalimdor); text and simplifications are ours.
do
  local at, q, quest = B.at, B.q, B.quest
  local accept, finish, objective, part = B.accept, B.finish, B.objectiveAt, B.objectivePart
  local along, withItem, action, taxi, only = B.along, B.withItem, B.action, B.taxi, B.only
  local function du(name, x, y) return at(name, x, y, durotar) end
  local function og(name, x, y) return at(name, x, y, orgrimmar) end
  local function ba(name, x, y) return at(name, x, y, barrens) end
  local ORC, TROLL = "ORC", "TROLL"

  -- Valley of Trials
  local kaltunk = du("Kaltunk", 43.29, 68.53)
  local gornek = du("Gornek", 42.06, 68.33)
  local zureetha = du("Zureetha Fargaze", 42.85, 69.15)
  local ruzan = du("Ruzan", 42.59, 69.0)
  local galgar = du("Galgar", 42.73, 67.23)
  local hanazua = du("Hana'zua", 40.6, 62.58)
  local thazzril = du("Foreman Thazz'ril", 44.63, 68.65)
  local canaga = du("Canaga Earthcaller", 42.4, 69.17)
  local manifestation = du("Minor Manifestation of Earth", 44.03, 76.2)
  local kenjai = du("Ken'jai", 42.36, 68.81)
  local frang, jenshan, rwag = du("Frang", 42.89, 69.44), du("Jen'shan", 42.84, 69.33), du("Rwag", 41.28, 68.0)
  local shikrik, maiah, nartok = du("Shikrik", 42.39, 69.0), du("Mai'ah", 42.51, 69.04), du("Nartok", 40.65, 68.52)
  local valleyTrainers = {
    { "WARRIOR", frang }, { "HUNTER", jenshan }, { "ROGUE", rwag }, { "PRIEST", kenjai },
    { "SHAMAN", shikrik }, { "MAGE", maiah }, { "WARLOCK", nartok },
  }

  q(4641, "Your Place In The World", 1, 1)
  q(788, "Cutting Teeth", 2, 1)
  q(790, "Sarkoth", 5, 1)
  q(804, "Sarkoth", 5, 1, 790)
  q(789, "Sting of the Scorpid", 3, 1)
  q(4402, "Galgar's Cactus Apple Surprise", 3, 1)
  q(5441, "Lazy Peons", 4, 3)
  q(6394, "Thazz'ril's Pick", 4, 3, 5441)
  q(792, "Vile Familiars", 4, 2, nil, nil, { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE" })
  q(1485, "Vile Familiars", 4, 1, nil, nil, "WARLOCK")
  q(1499, "Vile Familiars", 4, 1, 1485, nil, "WARLOCK")
  q(794, "Burning Blade Medallion", 5, 1)
  q(805, "Report to Sen'jin Village", 5, 1, 794)
  q(96652, "The Adventurer", 6, 4, nil, true)
  q(1516, "Call of Earth", 4, 4, nil, nil, "SHAMAN")
  q(1517, "Call of Earth", 4, 4, 1516, nil, "SHAMAN")
  q(1518, "Call of Earth", 4, 4, 1517, nil, "SHAMAN")
  q(5649, "In Favor of Spirituality", 4, 5, nil, nil, "PRIEST")
  q(5648, "Garments of Spirituality", 4, 5, 5649, nil, "PRIEST")
  quest[5649].race, quest[5648].race = TROLL, TROLL
  -- Starting class letters: one per race and class, handed in to the class trainer.
  local letters = {
    { 2383, "Simple Parchment", "WARRIOR", ORC, frang }, { 3065, "Simple Tablet", "WARRIOR", TROLL, frang },
    { 3087, "Etched Parchment", "HUNTER", ORC, jenshan }, { 3082, "Etched Tablet", "HUNTER", TROLL, jenshan },
    { 3088, "Encrypted Parchment", "ROGUE", ORC, rwag }, { 3083, "Encrypted Tablet", "ROGUE", TROLL, rwag },
    { 3089, "Rune-Inscribed Parchment", "SHAMAN", ORC, shikrik },
    { 3084, "Rune-Inscribed Tablet", "SHAMAN", TROLL, shikrik },
    { 3085, "Hallowed Tablet", "PRIEST", TROLL, kenjai },
    { 98576, "Glyphic Parchment", "MAGE", ORC, maiah }, { 3086, "Glyphic Tablet", "MAGE", TROLL, maiah },
    { 3090, "Tainted Parchment", "WARLOCK", ORC, nartok }, { 98575, "Tainted Tablet", "WARLOCK", TROLL, nartok },
  }
  local valley = {
    accept(4641, kaltunk, "Speak to Kaltunk where you arrive in the valley."),
    finish(4641, gornek, "Go into the Den, the large hut just west, and find Gornek."),
    accept(788, gornek),
  }
  for _, letter in ipairs(letters) do
    local id = letter[1]
    q(id, letter[2], 1, 1, nil, id > 90000 or nil, letter[3])
    quest[id].race = letter[4]
    valley[#valley + 1] = accept(id, gornek)
    valley[#valley + 1] = finish(id, letter[5], "Read the letter and hand it to your class trainer around the Den.")
  end
  for _, step in ipairs({
    action("train", nil, "Visit your class trainer around the Den. Train spells for level", { level = 2 }),
    accept(1485, ruzan),
    accept(4402, galgar, "Galgar cooks by the fire just north of the Den."),
    accept(790, hanazua, "Hana'zua lies wounded under the trees north-west of the Den."),
    along(objective(788, du(nil, 43.9, 65.8),
      "Kill Mottled Boars around the valley. Pick up Cactus Apples from the base of cactuses as you pass.",
      "10 Mottled Boars"), 4402),
    objective(790, du(nil, 40.6, 66.8), "Sarkoth is a large scorpid on the slope west of the Den. Kill him for his claw.",
      "Sarkoth's Mangled Claw"),
    finish(790, hanazua), accept(804, hanazua),
    objective(1485, du(nil, 43.9, 58.4), "Kill Vile Familiars in the imp camp at the north end of the valley for their heads.",
      "6 Vile Familiar Heads"),
    finish(788, gornek), finish(804, gornek), accept(789, gornek),
    finish(1485, ruzan), accept(1499, ruzan),
    finish(1499, zureetha, "Find Zureetha outside the Den to learn Summon Imp."),
    accept(792, zureetha),
    accept(5441, thazzril, "Thazz'ril stands by the lumber piles east of the Den."),
    action("train", nil, "Visit your class trainer around the Den. Train spells for level", { level = 4 }),
    withItem(16114, along(objective(5441, du(nil, 45.0, 69.1),
      "Use the Foreman's Blackjack on sleeping Lazy Peons around the lumber piles to wake them.", "5 Peons Awoken"), 4402)),
    along(objective(789, du(nil, 43.3, 58.3),
      "Head north. Kill Scorpid Workers on the way to the imp camp for their tails.", "10 Scorpid Worker Tails"), 792),
    along(objective(792, du(nil, 43.9, 58.4), "Kill Vile Familiars in the imp camp at the north end of the valley.",
      "12 Vile Familiars"), 789),
    objective(4402, du(nil, 44.7, 64.9), "Finish collecting Cactus Apples from the cactuses on the way back south.",
      "10 Cactus Apples"),
    finish(4402, galgar), finish(789, gornek),
    finish(5441, thazzril), accept(6394, thazzril),
    finish(792, zureetha),
    accept(794, zureetha),
    accept(1516, canaga),
    objective(6394, du(nil, 43.7, 53.8),
      "Enter the Burning Blade Coven, the cave at the far north of the valley. The pick lies on the ground just inside.",
      "Thazz'ril's Pick"),
    along(objective(794, du(nil, 42.7, 53.0),
      "Fight through the cave to Yarrog Baneshadow in the back chamber and take his medallion.", "Burning Blade Medallion"),
      1516),
    objective(1516, du(nil, 43.3, 53.8), "Kill Felstalkers in and around the cave until you have both hooves.",
      "2 Felstalker Hooves"),
    finish(6394, thazzril),
    finish(794, zureetha), accept(805, zureetha),
    accept(96652, du(nil, 42.79, 69.13), "Click the Lost Journal lying on the barrel beside Zureetha."),
    accept(5649, kenjai),
    finish(1516, canaga), accept(1517, canaga),
    withItem(6635, finish(1517, manifestation,
      "Walk south to Spirit Rock at the valley's southern edge. Drink the Earth Sapta there and speak to the spirit that appears.")),
    accept(1518, manifestation),
    finish(1518, canaga),
    action("train", nil, "Visit your class trainer around the Den. Train spells for level", { level = 6 }),
  }) do valley[#valley + 1] = step end

  -- Sen'jin Village, Razor Hill and the north
  local ukor = du("Ukor", 52.06, 68.31)
  local lar = du("Lar Prowltusk", 54.24, 73.28)
  local xarti = du("Xar'Ti", 55.28, 75.49)
  local velrin = du("Vel'rin Fang", 55.96, 73.93)
  local vornal = du("Master Vornal", 55.94, 74.39)
  local gadrin = du("Master Gadrin", 55.95, 74.72)
  local pazula = du("Pa'zula", 56.69, 73.74)
  local paljuh = du("Pal'juh", 46.28, 78.65)
  local brakk = du("Brakk", 51.98, 47.27)
  local garthok = du("Gar'Thok", 51.95, 43.5)
  local orgnil = du("Orgnil Soulscar", 52.24, 43.15)
  local torka = du("Cook Torka", 51.11, 42.45)
  local furl = du("Furl Scornbrow", 49.88, 40.39)
  local turroc = du("Turroc", 53.95, 42.59)
  local grosk = du("Innkeeper Grosk", 51.51, 41.64)
  local taijin = du("Tai'jin", 54.26, 42.93)
  local takrin = du("Takrin Pathseeker", 50.84, 43.59)
  local heglan = du("Heglan Shadeeye", 58.6, 45.6)
  local misha = du("Misha Tor'kren", 43.1, 30.24)
  local rezlak = du("Rezlak", 46.37, 22.94)
  local margoz = du("Margoz", 56.41, 20.04)
  local orgGate = du("Orgrimmar's south gate", 45.5, 12.2)
  local thatog, borstan = og("Thatog", 55.67, 72.15), og("Borstan", 57.2, 53.32)
  local migi, thra = og("Migi", 36.53, 29.06), og("Thra", 36.82, 29.06)
  local korgeld, yelmak, whuut = og("Kor'geld", 56.05, 34.12), og("Yelmak", 56.84, 33.03), og("Whuut", 55.79, 32.9)
  local nazgrel, thrall = og("Nazgrel", 32.3, 35.75), og("Thrall", 31.73, 37.82)
  local neeru, kamari = og("Neeru Fireblade", 49.47, 50.59), og("Kamari", 63.28, 44.75)
  local doras = og("Doras", 45.12, 63.89)
  local kargal, akzeloth = ba("Kargal Battlescar", 62.26, 19.38), ba("Ak'Zeloth", 62.34, 20.07)
  local razorHill = { bind = "Razor Hill" }
  local razorTrainers = {
    { "WARRIOR", du("Tarshaw Jaggedscar", 54.2, 42.5) }, { "HUNTER", du("Thotar", 51.9, 43.5) },
    { "ROGUE", du("Kaplak", 52.0, 43.7) }, { "PRIEST", taijin }, { "SHAMAN", du("Swart", 54.4, 42.6) },
    { "MAGE", du("Un'Thuwa", 56.3, 75.1) }, { "WARLOCK", du("Dhugru Gorelust", 54.4, 41.2) },
  }

  q(2161, "A Peon's Burden", 5, 1)
  q(786, "Thwarting Kolkar Aggression", 8, 5)
  q(97223, "Bloodtalon Matriarch", 9, 6, nil, true)
  q(817, "Practical Prey", 8, 5)
  q(96821, "Legging It", 6, 4, nil, true)
  q(818, "A Solvent Spirit", 7, 5)
  q(97225, "Forgotten Loa Idols", 9, 6, nil, true)
  q(808, "Minshina's Skull", 9, 4, 805)
  q(826, "Zalazane", 10, 4, 805)
  q(823, "Report to Orgnil", 7, 4, 805)
  q(96873, "A Pain in the Neck", 8, 5, nil, true)
  quest[96873].optional = true -- needs Enchanting to disenchant the pendants
  q(99123, "Lost in the Shadows", 8, 5, nil, true)
  q(96876, "Ukor's Lost Pack", 8, 5, nil, true)
  quest[96876].startItem = 275722
  q(96604, "The Great Outdoors", 6, 4, 96652, true)
  q(96655, "Camping 101: Cooking", 6, 4, 96604, true)
  q(806, "Dark Storms", 12, 4, 823)
  q(784, "Vanquish the Betrayers", 7, 3)
  q(825, "From The Wreckage....", 8, 3)
  q(830, "The Admiral's Orders", 7, 1)
  quest[830].startItem = 4881
  q(831, "The Admiral's Orders", 7, 1, 830)
  q(99048, "A Missing Hand", 9, 5, nil, true)
  q(99049, "Threat from Below", 9, 5, 99048, true)
  q(96825, "This Fruit Could Bite Back", 6, 4, nil, true)
  q(815, "Break a Few Eggs", 8, 6)
  q(791, "Carry Your Weight", 7, 4)
  q(96822, "For Honor", 7, 4, nil, true)
  q(837, "Encroachment", 10, 6)
  q(840, "Conscript of the Horde", 12, 10)
  q(816, "Lost But Not Forgotten", 11, 8)
  q(834, "Winds in the Desert", 9, 7)
  q(835, "Securing the Lines", 11, 7, 834)
  q(97281, "A Simmering Storm", 11, 7, nil, true)
  quest[97281].startItem = 277661
  q(97282, "Stormy Potential", 10, 7, nil, true)
  q(96877, "Halikor's Hoof", 12, 8, nil, true)
  quest[96877].startItem = 275723
  q(5726, "Hidden Enemies", 12, 9)
  q(828, "Margoz", 12, 4, 806)
  q(827, "Skull Rock", 12, 4, 828)
  q(829, "Neeru Fireblade", 12, 4, 827)
  q(832, "Burning Shadows", 12, 4)
  quest[832].startItem = 4903
  q(809, "Ak'Zeloth", 13, 4, 829)
  q(97246, "Meal Appeal", 15, 10, nil, true)
  q(97249, "Favorite Food", 15, 10, 97246, true)
  q(97242, "Yelmak's Medley", 15, 10, nil, true)
  q(97275, "Whuut's the Rush", 15, 10, 97242, true)
  q(97326, "Rocks to Rests", 15, 10, nil, true)
  q(842, "Crossroads Conscription", 12, 10, 840)
  q(924, "The Demon Seed", 14, 9, 809)

  local senjin = {
    accept(2161, ukor, "Ukor waits on the road east of the valley exit."),
    accept(786, lar, "Lar stands at the north entrance of Sen'jin Village."),
    accept(97223, xarti), accept(817, velrin), accept(96821, velrin),
    accept(818, vornal), accept(97225, vornal),
    finish(805, gadrin, "Master Gadrin is in the middle of the village."),
    accept(808, gadrin), accept(826, gadrin), accept(823, gadrin),
    accept(96873, pazula),
    along(objective(818, du(nil, 52.2, 83.0),
      "Walk south-west to the beach. Kill Pygmy Surf Crawlers for mucus and Makrura for their eyes on the way to Kolkar Crag.",
      "4 Intact Makrura Eyes", "8 Crawler Mucus"), 786),
    part(786, 1, du(nil, 49.81, 81.29), "Destroy the first set of attack plans in the southern Kolkar camp.",
      "Attack Plan: Valley of Trials"),
    part(786, 2, du(nil, 47.66, 77.34), "Burn the second set of plans by the tents in the northern camp.",
      "Attack Plan: Sen'jin Village"),
    accept(99123, paljuh, "Free Pal'juh, held captive in the western part of Kolkar Crag."),
    part(786, 3, du(nil, 46.23, 78.94), "The last set of plans lies near Pal'juh's cage.", "Attack Plan: Orgrimmar"),
    objective(99123, du(nil, 51.42, 79.29), "Escort Pal'juh out of the crag. Kill the centaurs that attack him.",
      "Help Pal'juh escape"),
    finish(786, lar), finish(99123, vornal),
    action("goto", du(nil, 52.0, 57.0), "Follow the road north toward Razor Hill."),
    objective(96821, du(nil, 51.97, 57.24),
      "Kill Ridgeshade Creepers and Lurkers in the hills beside the road. The elite Ukorsbane roams here; if you kill him with help, loot Ukor's Lost Pack.",
      "6 Ridgeshade Creepers", "6 Ridgeshade Lurkers"),
    withItem(275722, accept(96876, du(nil, 49.23, 56.76), "Read Ukor's Lost Pack from your bags.")),
    finish(96652, brakk, "Brakk keeps a campfire on the road south of Razor Hill."),
    accept(96604, brakk),
    objective(96604, du(nil, 52.06, 47.33), "Sit by Brakk's campfire (type /sit) until you get the Boosted Rest buff.",
      "Rest at the campfire"),
    finish(96604, brakk), accept(96655, brakk),
    finish(96655, torka, "Learn Cooking from Cook Torka by the Razor Hill barracks."),
    accept(96825, torka), accept(815, torka),
    finish(96821, garthok, "Gar'Thok stands in front of the barracks in Razor Hill."),
    accept(784, garthok), accept(825, garthok),
    finish(823, orgnil), accept(99048, orgnil),
    accept(791, furl, "Climb the watchtower on the west side of town to reach Furl."),
    accept(96822, turroc),
    finish(2161, grosk, "Bring Ukor's bundle to the innkeeper."),
    action("sethearth", grosk, "Set your hearthstone at Razor Hill's inn.", razorHill),
    finish(5649, taijin), accept(5648, taijin),
    objective(5648, du("Grunt Kor'ja", 53.1, 46.5),
      "Find Grunt Kor'ja south of town. Heal him and cast Power Word: Fortitude on him.", "Heal and fortify Grunt Kor'ja"),
    finish(5648, taijin),
    action("train", nil, "Visit your class trainer in Razor Hill. Train spells for level", { level = 8 }),
    finish(99048, heglan, "Follow the coast road east of Razor Hill to Heglan's camp."),
    accept(99049, heglan),
    part(99049, 1, du(nil, 58.84, 44.36), "Search the beach just north-west of Heglan for the dagger.", "Orcish Dagger"),
    part(99049, 2, du(nil, 60.06, 42.39), "Look for the banner scrap further north along the shore.", "Banner Scrap"),
    part(99049, 3, du(nil, 60.11, 44.8), "The broken trident lies at the water's edge east of Heglan.", "Broken Bone Trident"),
    along(objective(784, du(nil, 59.0, 58.3),
      "Go south to Tiragarde Keep. Kill Kul Tiras Sailors and Marines outside the walls and loot Canvas Scraps.",
      "10 Kul Tiras Sailors", "8 Kul Tiras Marines"), 791, 96822),
    part(96822, 1, du(nil, 59.37, 56.36), "Pick up the Raider's Bow by the north wall of the keep.", "Raider's Bow"),
    part(96822, 2, du(nil, 57.35, 56.47), "The Raider's Battleaxe lies by the west wall.", "Raider's Battleaxe"),
    part(96822, 3, du(nil, 56.53, 52.99), "The Raider's Shield is in the outskirts north-west of the keep.", "Raider's Shield"),
    objective(791, du(nil, 58.9, 57.4), "Finish the Canvas Scraps from the sailors and marines.", "8 Canvas Scraps"),
    objective(784, du(nil, 59.75, 58.27),
      "Climb the keep's main tower to Lieutenant Benedict at the top. Kill him and loot the Admiral's Orders.",
      "Lieutenant Benedict"),
    withItem(4881, accept(830, du(nil, 59.75, 58.27), "Read Admiral Proudmoore's Orders from your bags.")),
    objective(825, du(nil, 61.96, 55.46),
      "Swim out to the gnomish wreckage east of the keep and loot the tools from the crates.", "3 Gnomish Tools"),
    finish(784, garthok), finish(830, garthok), finish(825, garthok),
    accept(831, garthok), accept(837, garthok),
    finish(99049, orgnil), finish(791, furl), finish(96822, turroc),
    action("train", nil, "Visit your class trainer in Razor Hill. Train spells for level", { level = 10 }),
    along(objective(96825, du(nil, 48.8, 49.0),
      "Go west into the Razormane Grounds. Kill Razormane Quilboars and Scouts and pick Prickly Pear Fruit from the cactuses.",
      "8 Prickly Pear Fruit"), 837),
    action("goto", du(nil, 59.8, 83.4), "Head back south past Sen'jin to the hills by the southern coast."),
    along(objective(817, du(nil, 59.8, 83.4),
      "Kill Durotar Tigers for their fur and Bloodtalon Taillashers for eggs in the hills south of Sen'jin.",
      "4 Durotar Tiger Furs"), 815, 818),
    objective(815, du(nil, 61.0, 82.0), "Finish the Taillasher Eggs from the raptors here.", "3 Taillasher Eggs"),
    objective(97223, du(nil, 68.78, 71.63),
      "Follow the coast east to the Bloodtalon Matriarch's nest and take her eggs.", "Eggs of the Bloodtalon Matriarch"),
    action("goto", du(nil, 63.0, 82.5), "Wade across the shallows to the Echo Isles."),
    along(objective(826, du(nil, 67.2, 88.8),
      "Kill Hexed and Voodoo Trolls across the Echo Isles. Pick up the Forgotten Loa Idols on the ground as you go.",
      "8 Hexed Trolls", "8 Voodoo Trolls"), 97225, 96873),
    objective(97225, du(nil, 64.9, 85.78), "Finish gathering Forgotten Loa Idols on the islands.", "8 Forgotten Loa Idols"),
    objective(808, du(nil, 67.4, 87.8), "Take Minshina's Skull from the circle of power on the largest island.",
      "Minshina's Skull"),
    objective(826, du(nil, 67.4, 87.8), "Kill Zalazane in his hut on the same island and take his head.", "Zalazane's Head"),
    objective(818, du(nil, 59.6, 73.8), "Finish the Crawler Mucus and Makrura Eyes on the beach on the way back.",
      "4 Intact Makrura Eyes", "8 Crawler Mucus"),
    finish(96873, pazula),
    finish(808, gadrin), finish(826, gadrin), finish(97225, gadrin),
    finish(818, vornal), finish(817, velrin), finish(97223, xarti),
    finish(96876, ukor, "Return Ukor's pack to him on the road west of Sen'jin."),
    along(objective(837, du(nil, 49.2, 49.0),
      "Back in the Razormane Grounds, finish the Quilboars and Scouts and the pears.",
      "4 Razormane Quilboars", "4 Razormane Scouts"), 96825),
    finish(96825, torka), finish(815, torka),
  }
  local north = {
    accept(806, orgnil),
    accept(840, takrin, "Takrin stands near the western edge of Razor Hill."),
    objective(837, du(nil, 44.45, 39.74),
      "Follow the road north-west to the far end of the Razormane Grounds. Kill Dustrunners and Battleguards there.",
      "4 Razormane Dustrunners", "4 Razormane Battleguards"),
    accept(816, misha, "Misha lives at the farmstead north-west of Razor Hill."),
    accept(834, rezlak, "Continue north to Rezlak's wrecked caravan near Drygulch Ravine."),
    objective(834, du(nil, 49.7, 21.9), "Search the ravine east of Rezlak for Sacks of Supplies.", "5 Sacks of Supplies"),
    finish(834, rezlak), accept(835, rezlak),
    objective(806, du(nil, 42.1, 26.7),
      "Go west to Thunder Ridge. Kill Fizzle Darkstorm at the Burning Blade camp and loot his claw.", "Fizzle's Claw"),
    action("goto", orgGate, "Enter Orgrimmar through the south gate."),
    taxi("getfp", doras, "Orgrimmar, Durotar", "Speak to Doras on the tower in the Valley of Strength for the flight path."),
    finish(831, nazgrel, "Cross the city west to Grommash Hold. Nazgrel stands beside Thrall."),
    accept(5726, thrall),
    action("hearth", nil, "Hearth back to Razor Hill.", razorHill),
    finish(806, orgnil), accept(828, orgnil),
    finish(837, garthok),
    action("train", nil, "Visit your class trainer in Razor Hill. Train spells for level", { level = 12 }),
    withItem(277661, accept(97281, du(nil, 54.0, 23.7), "Read the Dull Storm Orb from your bags.")),
    objective(835, du(nil, 54.0, 23.7),
      "Kill Dustwind Savages and Storm Witches in the ravine north-east of Rezlak. A witch may drop a Dull Storm Orb.",
      "12 Dustwind Savages", "8 Dustwind Storm Witches"),
    finish(835, rezlak), finish(97281, rezlak), accept(97282, rezlak),
    objective(97282, du(nil, 39.4, 25.3),
      "Kill Lightning Hides in Thunder Ridge for the organs. The elite Halikor roams here too; with help, loot his hoof.",
      "5 Charged Thunder Lizard Organs"),
    withItem(275723, accept(96877, du(nil, 40.76, 30.1), "Read Halikor's Hoof from your bags.")),
    finish(97282, rezlak),
    finish(828, margoz, "Margoz camps on the hill east of the road north of Rezlak."),
    accept(827, margoz),
    along(objective(827, du(nil, 53.8, 8.9),
      "Enter Skull Rock to the north. Kill Burning Blade cultists for Searing Collars and a Lieutenant's Insignia.",
      "6 Searing Collars"), 5726),
    withItem(4903, accept(832, du(nil, 51.8, 10.0), "If the Eye of Burning Shadow dropped, read it from your bags.")),
    objective(5726, du(nil, 52.5, 8.6), "Keep clearing Skull Rock until a Lieutenant's Insignia drops.",
      "Lieutenant's Insignia"),
    finish(827, margoz), accept(829, margoz),
    action("goto", orgGate, "Go back to Orgrimmar's south gate."),
    accept(97246, thatog, "Thatog runs the food stand just inside the gate."),
    finish(97246, borstan, "Borstan's Firepit is in the Valley of Strength."), accept(97249, borstan),
    finish(829, neeru), finish(832, neeru), accept(809, neeru),
    accept(97242, korgeld, "Take the tunnel north to the Valley of Honor. Kor'geld is inside Yelmak's shop."),
    objective(97242, og(nil, 69.4, 34.6), "Cut Cattails and Speargrass by the streams in the east of the Valley of Honor.",
      "2 Handfuls of Cattails", "2 Bundles of Speargrass"),
    finish(97242, korgeld), accept(97275, yelmak),
    finish(97275, whuut),
    finish(96877, kamari, "Bring Halikor's Hoof to Kamari in the Valley of Honor."),
    finish(97249, migi, "Walk west to the back of Grommash Hold. Migi sits there."),
    accept(97326, thra),
    objective(97326, og(nil, 43.7, 34.6),
      "Pick up Smooth Boulders in the canyon between Grommash Hold and the Valley of Honor.", "8 Smooth Boulders"),
    finish(97326, thra),
    finish(5726, thrall, "Show Thrall the insignia in Grommash Hold."),
    action("goto", orgGate, "Leave Orgrimmar through the south gate."),
    objective(816, du(nil, 34.7, 42.3),
      "Go west to the Southfury River. Kill Dreadmaw Crocolisks along the bank until one drops Kron's Amulet.",
      "Kron's Amulet"),
    finish(816, misha),
    action("goto", du(nil, 34.6, 42.6), "Take the road west across the bridge into the Barrens."),
    finish(840, kargal, "Kargal waits at the Far Watch Outpost on the far side of the bridge."),
    accept(842, kargal),
    finish(809, akzeloth), accept(924, akzeloth),
  }

  local sources = {
    "https://bindonforever.com/zones/durotar",
    "https://www.warcrafttavern.com/forever/guides/leveling",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }
  route.starts.ORC, route.starts.TROLL = "valley-of-trials", "valley-of-trials"
  route.sections[#route.sections + 1] = { id = "valley-of-trials", title = "Valley of Trials", zone = durotar,
    levels = { 1, 6 }, start = { ORC, TROLL }, verified = false, sources = sources,
    steps = B.withTrainers(valley, valleyTrainers) }
  route.sections[#route.sections + 1] = { id = "durotar", title = "Durotar", zone = durotar,
    levels = { 6, 10 }, start = { ORC, TROLL }, verified = false, sources = sources,
    steps = B.withTrainers(senjin, razorTrainers) }
  route.sections[#route.sections + 1] = { id = "northern-durotar", title = "Northern Durotar", zone = durotar,
    levels = { 10, 12 }, start = { ORC, TROLL }, verified = false, sources = sources,
    steps = B.withTrainers(north, razorTrainers) }
end
