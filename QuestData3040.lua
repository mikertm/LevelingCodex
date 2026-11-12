-- Alliance route, levels 30-40. Source notes: tools/audits/2026-11-10-alliance-30-40.md.
-- Shared 30-60 travel data and helpers live here; QuestData4050.lua and QuestData5060.lua reuse them.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local M = B.maps

-- UiMap IDs and world sizes (yards) from UiMapAssignment in the Forever client reference.
local zones = {
  stv = { 1434, 6381.25, 4254.166, 1 }, arathi = { 1417, 3600, 2400, 1 }, alterac = { 1416, 2800, 1866.667, 1 },
  hillsbrad = { 1424, 3200, 2133.333, 1 }, needles = { 1441, 4400, 2933.333, 2 }, dustwallow = { 1445, 5250, 3500, 2 },
  desolace = { 1443, 4495.833, 2997.917, 2 }, swamp = { 1435, 2293.75, 1529.167, 1 }, badlands = { 1418, 2487.5, 1658.333, 1 },
  tanaris = { 1446, 6900, 4600, 2 }, feralas = { 1444, 6950, 4633.333, 2 }, hinterlands = { 1425, 3850, 2566.667, 1 },
  searing = { 1427, 2231.25, 1487.5, 1 }, blasted = { 1419, 3350, 2233.334, 1 }, steppes = { 1428, 2929.167, 1952.083, 1 },
  wpl = { 1422, 4300, 2866.667, 1 }, epl = { 1423, 4302.084, 2866.667, 1 }, felwood = { 1448, 5750, 3833.333, 2 },
  winterspring = { 1452, 7100, 4733.333, 2 }, azshara = { 1447, 5070.833, 3381.25, 2 }, ungoro = { 1449, 3700, 2466.667, 2 },
  silithus = { 1451, 3483.334, 2322.916, 2 }, moonglade = { 1450, 2308.333, 1539.583, 2 },
  riverglades = { 2548, 4850, 3233.334, 1 }, shendralas = { 2652, 2050, 1366.666, 2 }, hyjal = { 2482, 3472.918, 2314.583, 2 },
  deadwind = { 1430, 2500, 1666.667, 1 }, barrens = { 1413, 10133.333, 6756.25, 2 }, ashenvale = { 1440, 5766.666, 3843.75, 2 },
  stonetalon = { 1442, 4883.333, 3256.25, 2 }, tirisfal = { 1420, 4518.75, 3012.5, 1 }, silverpine = { 1421, 4200, 2800, 1 },
}
for name, z in pairs(zones) do
  M[name] = z[1]
  route.extents[z[1]] = { z[2], z[3] }
  route.flightNetwork[z[1]] = route.flightNetwork[z[1]] or z[4]
end
route.flightNetwork[M.dunMorogh] = route.flightNetwork[M.dunMorogh] or 1
route.flightNetwork[M.elwynn] = route.flightNetwork[M.elwynn] or 1

-- A place on a 30-60 map: B.on.stv("Name", x, y).
B.on = {}
for name, id in pairs(M) do
  B.on[name] = function(npc, x, y) return B.at(npc, x, y, id) end
end

-- One leveling section (a reference chapter's worth of quests in one or two zones).
function B.section(id, title, zone, low, high, sources, steps, extra)
  local section = { id = id, title = title, zone = zone, levels = { low, high }, verified = false,
    sources = sources, steps = steps }
  for key, value in pairs(extra or {}) do section[key] = value end
  route.sections[#route.sections + 1] = section
  return section
end

-- Shown only while its quest is in your log (a quest carried in from another guide).
function B.optional(step)
  step.optional = true
  return step
end

function B.note(step, text)
  step.uncertain = text
  return step
end

-- Boats and roads the arrow uses when no known flight path connects two maps.
function B.road(from, to, waypoint, label)
  route.roadTo[to] = route.roadTo[to] or {}
  route.roadTo[to][from] = route.roadTo[to][from] or { waypoint = waypoint, label = label }
end

do
  local road, on = B.road, B.on
  local menethilPier = on.wetlands(nil, 4.49, 56.66)
  local theramorePier = on.dustwallow(nil, 71.5, 56.3)
  local bootyPier = on.stv(nil, 25.8, 73.1)
  local ratchetPier = B.at(nil, 63.7, 38.6, M.barrens)
  local auberdineSouth = on.darkshore("Thamarian", 32.67, 42.11)
  local stormwindPier = on.stormwind(nil, 21.8, 56.8)
  -- Ships between the continents.
  road(M.wetlands, M.dustwallow, menethilPier, "Take the Theramore ship from Menethil's south pier")
  road(M.dustwallow, M.wetlands, theramorePier, "Take the Menethil ship from the Theramore docks")
  road(M.stv, M.barrens, bootyPier, "Take the Ratchet boat from the Booty Bay docks")
  road(M.barrens, M.stv, ratchetPier, "Take the Booty Bay boat from the Ratchet dock")
  road(M.darkshore, M.stormwind, auberdineSouth, "Take the Stormwind ship from Auberdine's south pier")
  road(M.stormwind, M.dustwallow, stormwindPier, "Take the Auberdine ship, then fly south to Theramore")
  -- Overland legs out of the Alliance towns.
  road(M.duskwood, M.stv, on.duskwood(nil, 44.7, 87.5), "Follow the road south into Stranglethorn")
  road(M.stv, M.duskwood, on.stv(nil, 40.6, 3.5), "Follow the road north into Duskwood")
  road(M.duskwood, M.deadwind, on.duskwood(nil, 87.7, 41.1), "Take the east road out of Darkshire into Deadwind Pass")
  road(M.deadwind, M.swamp, on.deadwind(nil, 60.5, 41.4), "Follow the road east into the Swamp of Sorrows")
  road(M.duskwood, M.swamp, on.duskwood(nil, 87.7, 41.1), "Take the east road through Deadwind Pass to the Swamp of Sorrows")
  road(M.swamp, M.blasted, on.swamp(nil, 34.2, 66.4), "Take the road south from the Swamp into the Blasted Lands")
  road(M.wetlands, M.arathi, on.wetlands(nil, 50.2, 13.6), "Cross Thandol Span north into Arathi")
  road(M.arathi, M.wetlands, on.arathi(nil, 43.4, 92.1), "Cross Thandol Span south into the Wetlands")
  road(M.hillsbrad, M.arathi, on.hillsbrad(nil, 82.4, 39.6), "Take the east road out of Hillsbrad into Arathi")
  road(M.arathi, M.hillsbrad, on.arathi(nil, 17.1, 35.3), "Take the west road into Hillsbrad")
  road(M.hillsbrad, M.alterac, on.hillsbrad(nil, 54.6, 40.9), "Climb the north road into the Alterac Mountains")
  road(M.hillsbrad, M.hinterlands, on.hillsbrad(nil, 86.4, 32.0), "Take the northeast pass into the Hinterlands")
  road(M.lochModan, M.badlands, on.lochModan(nil, 47.2, 79.0), "Take the south road out of Loch Modan into the Badlands")
  road(M.redridge, M.steppes, on.redridge(nil, 19.3, 16.4), "Take the north road out of Redridge into the Burning Steppes")
  road(M.barrens, M.needles, B.at(nil, 44.4, 91.5, M.barrens), "Follow the Barrens road south through the Great Lift")
  road(M.barrens, M.dustwallow, B.at(nil, 56.4, 63.6, M.barrens), "Take the east road out of the Barrens into Dustwallow")
  road(M.needles, M.tanaris, on.needles(nil, 75.5, 96.9), "Follow the Shimmering Flats road south into Tanaris")
  road(M.tanaris, M.ungoro, on.tanaris(nil, 27.8, 56.9), "Go west through the Lost Rigger Cove ridge path into Un'Goro")
  road(M.ungoro, M.silithus, on.ungoro(nil, 29.5, 22.3), "Take the northwest ramp out of Un'Goro into Silithus")
  road(M.stonetalon, M.desolace, on.stonetalon(nil, 29.2, 90.5), "Take the south road out of Stonetalon into Desolace")
  road(M.desolace, M.feralas, on.desolace(nil, 43.9, 95.6), "Follow the road south out of Desolace into Feralas")
  road(M.feralas, M.desolace, on.feralas(nil, 44.9, 1.6), "Follow the road north into Desolace")
  road(M.ashenvale, M.felwood, on.ashenvale(nil, 55.6, 18.6), "Take the north road out of Ashenvale into Felwood")
  road(M.ashenvale, M.azshara, on.ashenvale(nil, 94.6, 47.8), "Take the east road out of Ashenvale into Azshara")
  road(M.felwood, M.winterspring, on.felwood(nil, 64.6, 8.2), "Go through Timbermaw Hold to Winterspring")
  road(M.hillsbrad, M.wpl, on.hillsbrad(nil, 54.6, 40.9), "Climb through Alterac to the Western Plaguelands")
  road(M.wpl, M.epl, on.wpl(nil, 69.4, 49.6), "Take the east road into the Eastern Plaguelands")
end

local at, q, quest = B.at, B.q, B.quest
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, withItem, along, breadcrumb = B.objectiveAt, B.withItem, B.along, B.breadcrumb
local forDungeon, withGuide, note = B.forDungeon, B.withGuide, B.note
local on, section = B.on, B.section

-- Darkshire at 30: the worgen and Night Watch chains, Mor'Ladim and the first Nesingwary hunts.
do
  local dw = on.duskwood
  local viktori = dw("Viktori Prism'Antras", 79.8, 48.0)
  local calor = dw("Calor", 75.3, 48.0)
  local althea = dw("Commander Althea Ebonlocke", 73.6, 46.9)
  local trelayne = dw("Innkeeper Trelayne", 73.9, 44.4)
  local sirra = dw("Sirra Von'Indi", 72.6, 47.6)
  local ello = dw("Lord Ello Ebonlocke", 71.9, 46.4)
  local ladimore = dw("Watcher Ladimore", 74.5, 46.1)
  local abercrombie = dw("Abercrombie", 28.1, 31.5)
  local sven = dw("Sven Yorgen", 7.8, 34.1)
  local grave = dw("A Weathered Grave", 17.73, 29.08)
  local felicia = dw("Felicia Maline", 77.5, 44.3)
  local ajeck = on.stv("Ajeck Rouack", 35.62, 10.62)
  local erlgadin = on.stv("Sir S. J. Erlgadin", 35.55, 10.55)
  local barnil = on.stv("Barnil Stonepot", 35.7, 10.8)
  local darkshire = { bind = "Darkshire" }

  q(538, "Southshore", 38, 20, 337)
  q(225, "The Weathered Grave", 35, 28)
  q(227, "Morgan Ladimore", 35, 28, 225)
  q(228, "Mor'Ladim", 35, 28, 227)
  q(229, "The Daughter Who Lived", 35, 28, 228)
  q(253, "Bride of the Embalmer", 30, 20, 252)
  q(55, "Morbent Fel", 32, 18, 325)
  q(215, "Jungle Secrets", 33, 30)
  q(583, "Welcome to the Jungle", 30, 28)
  q(185, "Tiger Mastery", 31, 28, 583)
  q(190, "Panther Mastery", 31, 28, 583)
  q(690, "Malin's Request", 32, 30)
  q(1301, "James Hyal", 35, 30)

  section("darkshire-30", "Darkshire: Mor'Ladim and the Worgen", M.duskwood, 30, 32, {
    "https://www.wowhead.com/forever/zone=10/duskwood",
    "https://bindonforever.com/zones/duskwood",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("boat", on.darkshore("Thamarian", 32.67, 42.11),
      "Take the Stormwind ship from Auberdine's south pier. Use Next when you reach Stormwind Harbor.",
      { name = "Auberdine - Stormwind Harbor" }),
    action("note", nil, "Clean out your quest log. If you never ran the Deadmines, abandon its quests now: they are grey and the 30s need the room.",
      { name = "Quest log", drop = { 166, 167, 168, 214, 2040, 92753 } }),
    accept(538, at("Milton Sheaf", 77.07, 30.21, M.stormwind),
      "Milton Sheaf in the Stormwind Keep library offers this once you have returned his old history book. Use Next if he has nothing."),
    taxi("fly", at("Dungar Longdrink", 71.3, 72.2, M.stormwind), "Darkshire, Duskwood", "Fly to Darkshire."),
    accept(181, viktori, "Viktori, in the house at the east end of town, has one more task now that Mary's looking glass is home."),
    accept(173, calor), accept(58, althea, "Commander Althea has the last Night Watch assignment."),
    action("sethearth", trelayne, "Bind at the Scarlet Raven Tavern. You will come back here twice.", darkshire),
    objective(173, dw(nil, 63.6, 41.2), "Hunt Nightbane Shadow Weavers in Brightwood Grove, just west of town. Avoid pulling the worgen in pairs.",
      "6 Nightbane Shadow Weavers"),
    finish(173, calor), accept(221, calor),
    objective(221, dw(nil, 61.4, 41.2), "Go back to the same woods for Nightbane Dark Runners.", "12 Nightbane Dark Runners"),
    action("goto", dw(nil, 23.6, 34.6), "Follow the main road west to Raven Hill and enter the cemetery."),
    objective(58, dw(nil, 24.3, 32.9), "Kill Plague Spreaders among the graves north of the road. Pull them one at a time near the crypt.",
      "20 Plague Spreaders"),
    accept(134, abercrombie, "Walk north to Abercrombie's shack."),
    accept(225, grave, "Read the weathered grave in the hills west of the cemetery."),
    finish(325, sven, "Keep west to Sven's camp at the edge of the forest and give him Morbent's Bane."),
    accept(55, sven, "Morbent Fel is level 32 and hits hard. Weaken him with the bane before you fight."),
    withItem(281145, accept(79363, nil, "Use Silvia's Sword if a Lost Defender dropped it. The ghost haunts Sven's old farm and the Rotting Orchard.")),
    withItem(281142, accept(96138, nil, "Use Merrick's Bow if a Lost Watcher dropped it on the way south.")),
    action("goto", dw(nil, 34.6, 74.8), "Go south across the forest to the Vul'Gol Ogre Mound."),
    along(objective(96138, dw(nil, 34.4, 75.5), "If you have Merrick's quest, kill Splinter Fist Warriors and Taskmasters around the mound.",
      "8 Splinter Fist Warriors", "4 Splinter Fist Taskmasters"), 134, 181),
    along(objective(134, dw("Abercrombie's Crate", 33.4, 76.4), "Take Abercrombie's crate from the ogres' camp in front of the mound.",
      "Abercrombie's Crate"), 181),
    along(note(objective(181, dw("Zzarc' Vul", 36.8, 83.8),
      "Zzarc' Vul guards the back of the mound. Clear the room first and pull him alone. Use Next if he is too strong.", "Ogre's Monocle"),
      "Check whether Forever changed Zzarc' Vul's level."), 134),
    objective(79363, dw(nil, 21.8, 69.9), "If you have Silvia's quest, clear Defias Night Blades and Enchanters at Addle's Stead.",
      "7 Defias Night Blades", "7 Defias Enchanters"),
    finish(134, abercrombie, "Take the crate north to Abercrombie."), accept(160, abercrombie),
    action("hearth", trelayne, "Hearth back to Darkshire.", darkshire),
    finish(58, althea),
    finish(160, ello, "Lord Ello Ebonlocke is in the town hall."), accept(251, ello),
    finish(251, sirra), accept(401, sirra), finish(401, sirra, "Wait while Sirra translates, then speak to her again."),
    accept(252, sirra), finish(252, ello), accept(253, ello, "Ello sends you after Eliza, the Embalmer's bride, at Raven Hill."),
    finish(225, sirra), accept(227, sirra), finish(227, althea), accept(228, althea),
    finish(79363, sirra), finish(96138, sirra),
    finish(221, calor), accept(222, calor),
    finish(181, viktori),
    objective(222, dw(nil, 71.9, 72.1), "Go south of town for Nightbane Vile Fangs and Tainted Ones. Pull from the edge of the camp.",
      "8 Nightbane Vile Fangs", "8 Nightbane Tainted Ones"),
    action("grind", dw(nil, 64.1, 68.5), "Keep killing worgen south of town until you are level 31. Mor'Ladim and Eliza are much easier then.",
      { level = 31 }),
    action("goto", dw(nil, 23.6, 34.6), "Return west to Raven Hill Cemetery."),
    note(objective(253, dw(nil, 28.9, 30.8), "Eliza waits in the crypt grounds with her ghouls. Clear the ghouls first and fight her with a partner if you can.",
      "The Embalmer's Heart"), "Eliza summons ghouls during the fight. Group size varies; check in game."),
    withItem(7297, objective(55, dw("Morbent Fel", 16.9, 33.4),
      "Use Morbent's Bane on Morbent Fel at the hill west of the cemetery to strip his shield, then kill him.", "Morbent Fel")),
    note(objective(228, dw("Mor'Ladim", 19.6, 37.3),
      "Mor'Ladim walks the cemetery paths. He is level 35: bring help, or skip him and use Next.", "Mor'Ladim's Skull"),
      "Patrol path and difficulty need an in-game check."),
    finish(55, sven, "Ride back west to Sven for the Morbent Fel turn-in."),
    action("goto", on.stv(nil, 40.6, 3.5), "Follow the main road south out of Duskwood into Stranglethorn Vale."),
    accept(215, on.stv("Private Thorsen", 40.3, 8.4), "Private Thorsen sometimes patrols the road near the Rebel Camp. Take his note if you see him."),
    accept(583, barnil, "Follow the road south to Nesingwary's Expedition, west of the road."),
    finish(583, at("Hemet Nesingwary", 35.66, 10.81, M.stv)),
    accept(185, ajeck), accept(190, erlgadin),
    along(objective(185, on.stv(nil, 35.4, 12.5), "Hunt Young Stranglethorn Tigers around the camp.", "10 Young Stranglethorn Tigers"), 190),
    along(objective(190, on.stv(nil, 41.5, 12.0), "Young Panthers prowl east of the camp, across the road.", "10 Young Panthers"), 185),
    finish(185, ajeck), finish(190, erlgadin),
    finish(215, on.stv("Lieutenant Doren", 38.0, 3.0), "Climb north to the Rebel Camp and find Lieutenant Doren."),
    action("hearth", trelayne, "Hearth back to Darkshire.", darkshire),
    finish(228, althea), accept(229, althea), finish(229, ladimore, "Watcher Ladimore stands just outside the town hall."),
    finish(253, ello),
    finish(222, calor), accept(223, calor), finish(223, dw("Jonathan Carevin", 75.3, 49.0)),
    taxi("fly", felicia, "Stormwind, Elwynn", "Fly to Stormwind."),
    accept(690, at("Archmage Malin", 50.5, 87.47, M.stormwind), "Archmage Malin, in the Wizard's Sanctum, asks you to find his contact in Arathi."),
    accept(1301, at("Connor Rivers", 51.12, 95.52, M.stormwind), "Connor Rivers, at the Mage Quarter's south end, has a message for Menethil Harbor."),
  }, { suggest = { "stv-30", "theramore-33" } })
end

-- Ironforge errands, then Southshore, the Alterac foothills and Refuge Pointe.
do
  local hb, ar, al, ifg = on.hillsbrad, on.arathi, on.alterac, on.ironforge
  local magni = ifg("King Magni Bronzebeard", 39.09, 56.2)
  local marblesten = ifg("Grand Mason Marblesten", 39.04, 88.05)
  local farren = hb("Lieutenant Farren Orinelle", 51.46, 58.39)
  local redpath = hb("Marshal Redpath", 49.47, 58.73)
  local maleb = hb("Magistrate Henry Maleb", 48.14, 59.11)
  local dibbs = hb("Loremaster Dibbs", 50.57, 57.09)
  local darren = hb("Darren Malvew", 52.42, 55.96)
  local bartolo = hb("Bartolo Ginsetti", 49.43, 55.53)
  local jessen = hb("Chef Jessen", 51.89, 58.68)
  local micha = hb("Micha Yance", 48.9, 55.0)
  local anderson = hb("Innkeeper Anderson", 51.2, 58.9)
  local nials = ar("Captain Nials", 45.83, 47.56)
  local quae = ar("Quae", 60.18, 53.85)
  local documents = al("Syndicate Documents", 58.32, 67.92)
  local southshore = { bind = "Southshore" }

  q(683, "Sara Balloo's Plea", 30, 25, 637)
  q(686, "A King's Tribute", 30, 25, 683)
  q(689, "A King's Tribute", 31, 25, 686)
  q(1179, "The Brassbolts Brothers", 30, 28)
  q(1302, "James Hyal", 35, 30, 1301)
  q(564, "Costly Menace", 34, 30)
  q(659, "Hints of a New Plague?", 33, 30)
  q(658, "Hints of a New Plague?", 36, 30, 659)
  q(505, "Syndicate Assassins", 33, 26)
  q(563, "Reassignment", 32, 25, 562)
  q(565, "Bartolo's Yeti Fur Cloak", 34, 29)
  q(555, "Soothing Turtle Bisque", 31, 28)
  q(510, "Foreboding Plans", 34, 26)
  q(511, "Encrypted Letter", 34, 30)
  q(514, "Letter to Stormpike", 34, 30, 511)
  q(681, "Northfold Manor", 31, 30)
  q(700, "A King's Tribute", 31, 25, 689)
  q(1453, "Reclaimers' Business in Desolace", 33, 30)

  section("hillsbrad-32", "Southshore, Alterac and Refuge Pointe", M.hillsbrad, 31, 34, {
    "https://www.wowhead.com/forever/zone=267/hillsbrad-foothills",
    "https://www.wowhead.com/forever/zone=45/arathi-highlands",
    "https://bindonforever.com/zones/hillsbrad-foothills",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("goto", nil, "Take the Deeprun Tram from Stormwind's Dwarven District to Ironforge. Use Next when you arrive."),
    accept(683, ifg("Sara Balloo", 63.5, 67.3), "Sara Balloo in the Mystic Ward has a plea for the king."),
    finish(683, magni, "Bring her note to King Magni in the High Seat."), accept(686, magni),
    finish(686, marblesten, "Grand Mason Marblesten works in the Great Forge's south hall."),
    accept(689, marblesten, "He wants Alterac Granite. You will find it in the hills of Hillsbrad and Alterac."),
    accept(1179, ifg("Pilot Longbeard", 72.73, 94.01), "Pilot Longbeard, by the Ironforge gate, needs a crate carried to the Shimmering Flats later on."),
    taxi("fly", ifg("Gryth Thurden", 55.5, 47.7), "Menethil Harbor, Wetlands", "Fly to Menethil Harbor."),
    withGuide("missing-diplomat", finish(1301, on.wetlands("Vincent Hyal", 8.39, 61.75),
      "Vincent Hyal is in the inn. Mikhail, in the same inn, carries on the Missing Diplomat chain.")),
    accept(1302, on.wetlands("Vincent Hyal", 8.39, 61.75), "Take Vincent's message for Theramore. You will go there after Arathi."),
    taxi("fly", on.wetlands("Shellei Brondir", 9.5, 59.7), "Southshore, Hillsbrad", "Fly to Southshore."),
    accept(564, darren, "Darren Malvew stands at the north end of town."),
    finish(538, dibbs, "Loremaster Dibbs is upstairs in the town hall."),
    accept(659, hb("Phin Odelic", 50.3, 59.0), "Phin Odelic, outside the inn, wants word sent to Arathi."),
    B.optional(finish(98219, farren, "If Lord Grayson sent you, report to Lieutenant Farren Orinelle on the dock road.")),
    accept(536, farren), accept(505, maleb),
    accept(565, bartolo, "Bartolo wants cloth, thread, a Hillman's Cloak and yeti fur. Leatherworkers make the cloak: check the Auction House or ask a crafter."),
    accept(555, jessen, "Chef Jessen wants Turtle Meat from the Snapjaws in Alterac and his Soothing Spices."),
    action("sethearth", anderson, "Bind at the Southshore inn.", southshore),
    action("buy", micha, "Buy Fine Thread and Soothing Spices from Micha Yance at the general store. Get a Bolt of Woolen Cloth from the Auction House or a tailor if you have none."),
    objective(536, hb(nil, 44.7, 67.2), "Walk west from the docks along the Western Strand. Pull Tidehunters and Oracles back onto dry land.",
      "10 Torn Fin Tidehunters", "10 Torn Fin Oracles"),
    finish(536, farren), accept(559, farren),
    objective(559, hb(nil, 33.2, 69.1), "Go farther west on the Strand for Murloc Heads. Muckdwellers and Coastrunners are easier than the Oracles.",
      "10 Murloc Heads"),
    finish(559, farren), accept(560, farren), finish(560, redpath), accept(561, redpath), finish(561, farren),
    accept(562, farren),
    objective(562, hb(nil, 57.0, 67.0), "Follow the beach east of the docks for Daggerspine naga. Pull Sirens alone.",
      "10 Daggerspine Shorehunters", "10 Daggerspine Sirens"),
    finish(562, farren), accept(563, farren, "Keep Farren's report for Major Samuelson in Stormwind Keep."),
    action("goto", hb(nil, 55.0, 40.0), "Take the road north out of town and climb toward the Alterac foothills."),
    along(objective(689, hb(nil, 44.5, 29.7), "Kill ogres and loot granite in the foothills and the Alterac hills above them.", "5 Alterac Granite"),
      555, 565),
    along(objective(555, al(nil, 39.7, 42.7), "Kill Snapjaws by the Alterac lakes for Turtle Meat.", "10 Turtle Meat"), 689, 565),
    along(objective(565, al(nil, 31.2, 52.8), "Hunt yetis around Growless Cave for Yeti Fur.", "10 Yeti Fur"), 564),
    along(objective(505, al(nil, 48.0, 82.0), "Clear Syndicate Footpads and Thieves on the road and in Strahnbrad.",
      "12 Syndicate Footpads", "8 Syndicate Thieves"), 564),
    accept(510, documents, "Search the documents on the table in Strahnbrad's inn. They also give the encrypted letter."),
    accept(511, documents),
    objective(564, al(nil, 61.8, 35.7), "Finish the Mountain Lions on the hills north of Strahnbrad and along the climb.",
      "8 Mountain Lions", "10 Hulking Mountain Lions"),
    taxi("getfp", on.wpl("Bibilfaz Featherwhistle", 42.9, 85.1), "Chillwind Camp, Western Plaguelands",
      "Keep north through the pass to Chillwind Camp and learn its flight path. Stay out of the Plaguelands for now."),
    taxi("fly", on.wpl("Bibilfaz Featherwhistle", 42.9, 85.1), "Southshore, Hillsbrad", "Fly back to Southshore."),
    finish(565, bartolo), finish(511, dibbs), accept(514, dibbs, "Keep the letter for Prospector Stormpike in Ironforge."),
    finish(555, jessen), finish(505, maleb), finish(510, maleb), finish(564, darren),
    action("goto", hb(nil, 82.4, 39.6), "Take the east road out of Hillsbrad through Thoradin's Wall into Arathi."),
    taxi("getfp", ar("Cedrik Prose", 45.7, 46.1), "Refuge Pointe, Arathi", "Follow the road to Refuge Pointe and learn its flight path."),
    accept(681, nials), finish(690, ar("Skuerto", 46.65, 47.01)),
    finish(659, quae, "Quae hides in the farmhouse ruins east of Refuge Pointe."), accept(658, quae),
    along(objective(681, ar(nil, 31.1, 29.5), "Ride northwest to Northfold Manor and clear the Syndicate around it.",
      "10 Syndicate Highwaymen", "6 Syndicate Mercenaries"), 658),
    note(objective(658, ar("Forsaken Courier", 52.5, 61.5),
      "The Forsaken Courier walks the road between Hillsbrad and Hammerfall with two guards. Watch the road and take the folder.", "Sealed Folder"),
      "Courier route from the classic data; check where she walks in Forever."),
    finish(681, nials), finish(658, quae),
    taxi("fly", ar("Cedrik Prose", 45.7, 46.1), "Ironforge, Dun Morogh", "Fly to Ironforge for the turn-ins."),
    finish(514, ifg("Prospector Stormpike", 74.64, 11.74), "Prospector Stormpike is in the Hall of Explorers."),
    accept(1453, ifg("Roetten Stonehammer", 69.95, 21.26), "Roetten Stonehammer, also in the Hall of Explorers, sends you to Desolace."),
    finish(689, marblesten), accept(700, marblesten), finish(700, magni),
    taxi("fly", ifg("Gryth Thurden", 55.5, 47.7), "Menethil Harbor, Wetlands", "Fly to Menethil Harbor for the Theramore ship."),
  }, { suggest = { "theramore-33", "stv-30" } })
end

-- Theramore, the trek south through Thousand Needles and the Shimmering Flats races.
do
  local dm, tn, rb = on.dustwallow, on.needles, on.barrens
  local vimes = dm("Captain Garran Vimes", 68.21, 48.62)
  local fiora = dm("Fiora Longears", 66.46, 45.15)
  local janene = dm("Innkeeper Janene", 66.6, 45.2)
  local jarl = dm("\"Swamp Eye\" Jarl", 55.44, 26.27)
  local shadyRest = dm("Shady Rest Inn", 29.7, 47.8)
  local kravel = tn("Kravel Koalbeard", 77.79, 77.27)
  local fizzle = tn("Fizzle Brassbolts", 78.06, 77.13)
  local wizzle = tn("Wizzle Brassbolts", 78.14, 77.12)
  local pozzik = tn("Pozzik", 80.18, 75.88)
  local zherin = tn("Trackmaster Zherin", 81.63, 77.95)
  local flats = tn(nil, 77.6, 85.0)
  local theramore = { bind = "Theramore Isle" }

  q(1282, "They Call Him Smiling Jim", 35, 30)
  q(1135, "Highperch Venom", 30, 25)
  q(1218, "Soothing Spices", 35, 30)
  q(1219, "The Orc Report", 35, 30)
  q(1220, "Captain Vimes", 35, 30, 1219)
  q(1284, "Suspicious Hoofprints", 35, 30)
  q(1253, "The Black Shield", 35, 30)
  q(1319, "The Black Shield", 35, 30, 1253)
  q(1320, "The Black Shield", 35, 30, 1319)
  q(1059, "Reclaiming the Charred Vale", 27, 20, 1057)
  q(1100, "Lonebrow's Journal", 34, 29)
  quest[1100].startItem = 5791
  q(1110, "Rocket Car Parts", 31, 28)
  q(1104, "Salt Flat Venom", 30, 28)
  q(1105, "Hardened Shells", 30, 28)
  q(1176, "Load Lightening", 30, 29)
  q(1175, "A Bump in the Road", 33, 28)
  q(1178, "Goblin Sponsorship", 37, 29, 1176)
  q(1111, "Wharfmaster Dizzywig", 36, 30)

  section("needles-33", "Theramore and the Shimmering Flats", M.needles, 33, 35, {
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    "https://www.wowhead.com/forever/zone=400/thousand-needles",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("boat", on.wetlands(nil, 5.1, 63.4), "Take the Theramore ship from Menethil's south pier. Use Next when it docks in Theramore.",
      { name = "Menethil Harbor - Theramore Isle" }),
    taxi("getfp", dm("Baldruc", 67.5, 51.3), "Theramore, Dustwallow Marsh", "Learn the Theramore flight path from Baldruc by the docks."),
    withGuide("missing-diplomat", finish(1302, dm("Clerk Lendry", 67.88, 48.24),
      "Clerk Lendry is in Foothold Citadel. Commander Samaul, in the same keep, finishes the Missing Diplomat.")),
    accept(1282, dm("Guard Byron", 66.15, 46.07), "Guard Byron by the inn has a message for Captain Vimes."),
    finish(1282, vimes, "Captain Vimes is on the citadel's top floor."),
    accept(1135, fiora, "Fiora Longears, outside the inn, wants venom sacs from the Highperch wyverns in Thousand Needles."),
    action("sethearth", janene, "Bind at the Theramore inn. You come back here after the Shimmering Flats.", theramore),
    action("buy", dm("Helenia Olden", 66.4, 51.5), "Buy 3 Soothing Spices from Helenia Olden, the trade supplier by the docks, for Swamp Eye Jarl."),
    action("goto", dm(nil, 55.0, 27.5), "Leave Theramore by the causeway and follow the northern road to Swamp Eye Jarl's shack."),
    accept(1218, jarl, "Swamp Eye Jarl is a hermit by the north road. Hand him the spices at once."),
    finish(1218, jarl),
    accept(1219, dm("Loose Dirt", 55.44, 25.92), "Search the loose dirt beside Jarl's shack."),
    action("goto", shadyRest, "Follow the road west to the burned Shady Rest Inn."),
    accept(1284, dm("Suspicious Hoofprint", 29.7, 47.64), "Look at the hoofprints by the inn."),
    accept(1253, dm("Black Shield", 29.63, 48.62), "Take the black shield lying near the inn."),
    action("goto", rb(nil, 44.4, 91.5), "Take the road west into the Barrens, then south through Camp Taurajo's outskirts to the Great Lift into Thousand Needles. Avoid the Horde camp itself."),
    withItem(5791, accept(1100, nil, "If Henrig Lonebrow's Journal dropped from a centaur, read it to start the quest.")),
    taxi("getfp", on.feralas("Thyssiana", 89.5, 45.9), "Thalanaar, Feralas",
      "Follow the canyon road west to Thalanaar on the Feralas border and learn its flight path."),
    finish(1100, on.feralas("Falfindel Waywarder", 89.64, 46.57)),
    B.optional(finish(1059, on.feralas("Falfindel Waywarder", 89.64, 46.57),
      "If you carried Keeper Albagorm's charred vale report from Stonetalon, hand it to Falfindel too.")),
    objective(1135, tn(nil, 11.1, 35.6), "Climb to Highperch, west of the canyon road, and kill wyverns for their venom sacs.", "10 Highperch Venom Sacs"),
    action("goto", flats, "Follow the canyon road east through Freewind Post's lower roads to the Shimmering Flats. Keep to the road past the centaur camps."),
    accept(1110, kravel, "Kravel Koalbeard runs the gnome racing camp."), accept(1111, kravel, "Kravel also wants parts picked up from Ratchet's wharfmaster."),
    finish(1179, wizzle, "Hand the crash helmets to Wizzle Brassbolts."), accept(1105, wizzle), accept(1104, fizzle),
    accept(1176, pozzik, "Pozzik runs the goblin camp just east of the gnomes."), accept(1175, zherin),
    along(objective(1110, flats, "Rocket car wreckage lies all over the salt flats. Pick up parts while you hunt.", "30 Rocket Car Parts"),
      1104, 1105, 1176, 1175),
    along(objective(1105, tn(nil, 76.4, 58.2), "Sparkleshell Tortoises and Snappers near the camps drop hardened shells.", "9 Hardened Tortoise Shells"),
      1104, 1110, 1176, 1175),
    along(objective(1104, tn(nil, 80.0, 86.0), "Scorpid Reavers and Terrors in the south of the flats carry the venom.", "6 Salty Scorpid Venom"),
      1105, 1110, 1176, 1175),
    along(objective(1176, tn(nil, 78.0, 88.0), "Salt Flats Vultures and Scavengers drop hollow bones.", "10 Hollow Vulture Bones"),
      1104, 1105, 1110, 1175),
    along(objective(1175, tn(nil, 70.0, 77.0), "Saltstone basilisks sit on the flats west of the camps.", "10 Saltstone Basilisks",
      "10 Saltstone Crystalhides", "10 Saltstone Gazers"), 1104, 1105, 1110, 1176),
    finish(1175, zherin), finish(1176, pozzik), accept(1178, pozzik, "Pozzik sends you to Gazlowe in Ratchet."),
    finish(1104, fizzle), finish(1105, wizzle), finish(1110, kravel),
    taxi("getfp", on.tanaris("Bera Stonehammer", 51.0, 29.3), "Gadgetzan, Tanaris",
      "Take the road south out of the flats into Tanaris and learn the Gadgetzan flight path. You will be back here in the forties."),
    action("hearth", janene, "Hearth to Theramore.", theramore),
    finish(1135, fiora),
    finish(1219, dm("Theramore Lieutenant", 67.07, 53.22), "The Theramore Lieutenant stands at the docks entrance."), accept(1220, dm("Theramore Lieutenant", 67.07, 53.22)),
    finish(1220, vimes), finish(1284, vimes),
    finish(1253, vimes), accept(1319, vimes),
    finish(1319, dm("Caz Twosprocket", 64.75, 50.43), "Caz Twosprocket works in the smithy near the docks."), accept(1320, dm("Caz Twosprocket", 64.75, 50.43)),
    finish(1320, vimes),
  }, { suggest = { "theramore-33", "stv-30" } })
end

-- Riverglades (Forever): two alternates around Farholde Keep and the Twilight's Shroud.
-- Facts from the Wowhead Forever quest pages (givers, enders, map points, series); objectives
-- the pages don't spell out are marked for an in-game check.
do
  local rg = on.riverglades
  local brant = rg("Demar Brant", 66.6, 81.0)
  local ashe = rg("Ashe Amberhall", 66.6, 81.0)
  local ember = rg("Ember Bladewhisper", 66.0, 79.6)
  local rowland = rg("Sister Rowland", 61.8, 83.2)
  local lowley = rg("Brother Lowley", 65.4, 79.0)
  local cassandra = rg("Cassandra Wheeler", 64.6, 82.8)
  local benjy = rg("Benjy Wheeler", 54.8, 73.0)
  local halligan = rg("Halligan Turner", 41.0, 63.0)
  local dalton = rg("Cedric Dalton", 39.4, 74.6)
  local cornelius = rg("Watcher Cornelius", 59.4, 63.8)
  local friz = rg("Friz Frazzlespark", 77.0, 52.8)
  local whizzbuzz = rg("Wharfmaster Whizzbuzz", 79.4, 52.8)
  local fimbo = rg("Fimbo Greasemitz", 79.0, 54.2)
  local zizplink = rg("Innkeeper Zizplink", 78.8, 54.0)
  local argo = rg("Argo Brinewhistle", 79.8, 52.4)
  local elbrim = rg("Farmer Elbrim", 52.8, 42.4)
  local claire = rg("Apprentice Claire", 47.6, 47.4)
  local fuzzle = rg("Fuzzle", 44.4, 47.3)
  local riftan = rg("Sergeant Riftan", 30.6, 49.0)
  local ryan = rg("Marshal Ryan", 26.2, 40.8)
  local dunston = rg("Dunston Willis", 68.6, 12.6)
  local gelinda = rg("Gelinda Coppergleam", 30.2, 69.0)
  local mudfin = rg(nil, 49.2, 78.8)
  local twilight = rg(nil, 45.5, 55.8)
  local farholdeFlight, portFlight = "Farholde Keep, Riverglades", "Powderfuse Port, Riverglades"
  local sources = {
    "https://www.wowhead.com/forever/zone=16591/riverglades",
    "https://warcraft.wiki.gg/wiki/Riverglades",
    "https://warcraft.wiki.gg/wiki/Farholde_Keep",
    "https://www.icy-veins.com/wow-forever/news/new-leveling-zones-in-wow-forever-riverglades-mount-hyjal/",
  }
  local function rq(id, name, level, min, pre) q(id, name, level, min, pre, true) end
  -- Breadcrumbs from other guides; see the optional pickups in hillsbrad-32, stv-34 and swamp-38.
  rq(95315, "The Riverglades Report", 38, 36)
  rq(94929, "Deliver the Second Shipment", 38, 36)
  rq(93443, "Lost Shipping Crate", 36, 36)
  rq(95147, "The Lost Scout", 37, 36)
  rq(95148, "Southern Watch Gnoll Report", 37, 36, 95147)
  rq(94678, "Gnoll Infestation", 38, 36)
  rq(94679, "Snargl's Snout", 40, 36)
  rq(94999, "Eyes for the Watchman", 36, 36)
  rq(94857, "If a Tree Falls, and No One Hears...", 39, 36)
  rq(94861, "Helping Hands", 39, 36, 94857)
  rq(94842, "Unsavory Plant Food", 38, 36)
  rq(94843, "From Seed to Sprout", 38, 36)
  rq(94931, "Stolen Saws", 38, 36)
  rq(95330, "Love Thy Neighbor", 37, 36)
  rq(94613, "My Kingdom for a Horse", 38, 36)
  rq(94614, "Freshwater Fiends", 38, 36, 94613)
  rq(94615, "Foal Play", 38, 36, 94613)
  rq(94617, "Coyote Huntin'", 38, 36, 94615)
  rq(94618, "Wheeler's Fleeing Steeds", 38, 36, 94613)
  rq(94992, "Rescue Roundup", 38, 36)
  rq(95329, "Out in the Field", 38, 36)
  rq(95603, "Bats in the Belfry", 38, 36)
  rq(95615, "In Memoriam", 38, 36)
  rq(96082, "Doctor's Orderly", 40, 36)
  rq(96083, "Clerical Quarantine", 40, 36, 96082)
  rq(96084, "Something's in the Water", 40, 36, 96083)
  rq(94924, "Hunting the Hunters", 39, 36, 95329)
  rq(94925, "A Fur Trade", 39, 36, 95329)
  rq(94928, "A Few Furs for Friz", 39, 36, 94925)
  rq(95064, "Preventative Measures", 39, 36, 95329)
  rq(95426, "Rog'mar Supplies", 39, 36, 95329)
  rq(95066, "The Rog'mar Situation", 39, 36, 95329)
  rq(95983, "A Feast for Buzzards", 38, 36)
  rq(95984, "Song of the Strider", 39, 36, 95983)
  rq(95986, "King of the Wild Plains", 41, 36, 95984)
  rq(95059, "Frazzlespark's Crate", 36, 36)
  rq(95118, "Saltwater Savages", 41, 36)
  rq(95121, "A Taste of the Sea", 40, 36)
  rq(95988, "Goes Down Smooth", 38, 36)
  rq(95254, "WANTED: Trapclaw", 42, 36)

  section("riverglades-farholde", "Riverglades: Farholde Keep and the Plains", M.riverglades, 36, 41, sources, {
    note(action("goto", rg(nil, 20.5, 69.5),
      "From Lakeshire, ride east through Redridge Pass, south of the Bristle Hills, into the Riverglades."),
      "The pass position is from the zone description; confirm the road in game."),
    accept(95147, rg("Scout Bolain", 23.6, 67.8), "Scout Bolain hides near the pass, east of the gnoll hills."),
    finish(95147, dalton, "Follow the road east to Southern Watch and find Captain Dalton."), accept(95148, dalton),
    accept(94678, dalton), accept(94679, dalton),
    accept(94999, rg("Eleanor Holmsby", 43.4, 82.4), "Ride southeast to the Meadowsbrook farm and talk to Eleanor Holmsby."),
    finish(94999, rg("Watcher Fredericks", 36.4, 75.8), "Take her delivery back to Watcher Fredericks just west of Southern Watch."),
    along(objective(94678, rg(nil, 17.4, 71.8), "Clear Redridge Brutes, Mystics and Trappers in the Bristle Hills west of Southern Watch.",
      "8 Redridge Brutes", "8 Redridge Mystics", "8 Redridge Trappers"), 94679),
    along(objective(94679, rg("Snargl", 16.0, 73.2), "Snargl leads the gnolls at the west end of the hills. Kill him for his snout.", "Snargl's Snout"), 94678),
    finish(94678, dalton), finish(94679, dalton),
    accept(94857, rg("Curly", 46.0, 71.0), "Ride northeast and find Curly by the fallen trees."),
    finish(94857, rg("Hurley", 41.4, 64.4), "Hurley is at Turner's Logging Camp, to the north."), accept(94861, rg("Hurley", 41.4, 64.4)),
    finish(94861, halligan, "Walk with Hurley to Halligan Turner in the camp."),
    accept(94842, halligan), accept(94843, halligan), accept(94931, halligan),
    along(objective(94843, rg("Loamy Soil", 39.7, 62.9), "Plant Halligan's saplings in the patches of loamy soil around the camp.",
      "5 Saplings Planted"), 94931),
    along(note(objective(94931, rg(nil, 40.0, 63.0), "Take the stolen saws back from the lumberjacks around the mill.", "8 Stolen Saws"),
      "Check where the saws drop or lie in game."), 94843),
    action("goto", mudfin, "Head southeast past the Mudfin murlocs on the way to Farholde Keep."),
    note(objective(94842, mudfin, "Kill Mudfin murlocs and crawfish along the river for Halligan's plant food.", "4 Plant Food"),
      "Item name not published; the murlocs and Jumbo Crawfish drop it."),
    action("goto", brant, "Follow the road east to Farholde Keep."),
    finish(95148, brant, "Knight Commander Demar Brant holds the keep's hall."),
    B.optional(finish(95315, brant, "Hand in Captain Nials' report from Refuge Pointe.")),
    B.optional(finish(94929, brant, "Hand in the shipment from the Swamp of Sorrows.")),
    accept(94613, brant), accept(95329, brant),
    taxi("getfp", rg(nil, 60.6, 81.6), farholdeFlight, "Learn the Farholde Keep flight path."),
    accept(95330, cassandra, "Cassandra Wheeler has farm goods for Halligan Turner. You will pass his camp again later."),
    accept(95603, rowland, "Sister Rowland tends the chapel south of the keep."), accept(95615, rowland),
    accept(96082, lowley, "Brother Lowley nurses the wounded inside the keep."),
    objective(96082, lowley, "Bandage the wounded soldiers lying around Brother Lowley.", "3 Wounded Soldiers Bandaged"),
    finish(96082, lowley), accept(96083, lowley),
    finish(96083, rowland), accept(96084, rowland),
    along(objective(95603, rg(nil, 60.2, 84.4), "Kill the Roosting Duskbats in the chapel's bell tower.", "5 Roosting Duskbats"), 95615),
    along(objective(95615, rg("Burned Memorial Candle", 61.6, 83.5), "Place memorial candles on the graves in the chapel yard.",
      "3 Candles Placed"), 95603),
    finish(95603, rowland), finish(95615, rowland),
    finish(94613, benjy, "Ride west to Wheeler's Grange and find Benjy Wheeler."),
    accept(94614, benjy), accept(94615, benjy), accept(94618, benjy),
    objective(94615, benjy, "Search around the Wheeler stables for signs of the missing horses.", "Evidence Found"),
    finish(94615, benjy), accept(94617, benjy),
    along(objective(94617, rg("Sootfur", 53.8, 86.2), "Sootfur, a coyote, prowls south of the farm. Kill it and take its pelt.", "Sootfur's Pelt"), 94618),
    along(objective(94614, mudfin, "Kill Mudfin Oracles and Warriors along the river west of the farm.", "8 Mudfin Oracles", "8 Mudfin Warriors"), 94618),
    objective(94618, rg("Lost Horse", 53.6, 66.2), "Find a lost horse north of the farm and give it Benjy's feed.", "Horse Fed"),
    accept(94992, rg("Lost Horse", 53.6, 66.2)),
    finish(94614, benjy), finish(94617, benjy), finish(94618, benjy), finish(94992, benjy),
    finish(95329, cornelius, "Ride north to Terral's Watch and report to Watcher Cornelius."),
    accept(94924, cornelius), accept(94925, cornelius), accept(95064, cornelius), accept(95426, cornelius),
    accept(95066, cornelius, "Keep his report on Rog'mar for Demar Brant."),
    accept(95983, rg("Picked Carcass", 61.6, 58.8), "Look at the picked carcass just north of the watchtower."),
    note(objective(96084, rg(nil, 56.5, 60.5), "Fill a water sample from the stream on the plains below the tower.", "Water Sample"),
      "Sample spot not published; any plains stream near Terral's Watch is a guess."),
    along(objective(94924, rg(nil, 58.2, 61.0), "Kill Rog'mar Poachers around the plains near the tower.", "12 Rog'mar Poachers"), 94925, 95983),
    along(objective(94925, rg(nil, 60.1, 53.0), "Hunt Wildplains lions north of the tower for their hides.", "8 Lion Hides"), 94924, 95983),
    along(note(objective(95983, rg(nil, 61.6, 58.8), "Collect what the buzzards leave behind on the plains.", "Buzzard Remains"),
      "Objective wording not published."), 94924, 94925),
    action("goto", rg(nil, 59.0, 35.5), "Go north toward Rog'mar. Keep clear of the Horde town itself."),
    along(objective(95064, rg(nil, 59.0, 35.5), "Kill Rog'mar Trainees at the training camps north of the plains.", "12 Rog'mar Trainees"), 95426),
    along(objective(95426, rg(nil, 60.0, 33.0), "Take Horde supply shipments from the training camps.", "8 Horde Supply Shipments"), 95064),
    finish(94924, cornelius), finish(94925, cornelius), finish(95064, cornelius), finish(95426, cornelius), finish(95983, cornelius),
    accept(95984, cornelius), accept(94928, cornelius),
    objective(95984, rg(nil, 54.6, 58.0), "Find a Roving Tallstrider on the plains west of the tower.", "Tallstrider Song"),
    finish(95984, cornelius), accept(95986, cornelius),
    objective(95986, rg("Ombassa", 59.4, 53.8), "Find Ombassa, the great lion of the plains, and defeat it.", "Ombassa"),
    finish(95986, cornelius),
    action("goto", friz, "Follow the road east to Powderfuse Port on the coast."),
    taxi("getfp", rg(nil, 77.5, 53.5), portFlight, "Learn the Powderfuse Port flight path."),
    finish(94928, friz, "Friz Frazzlespark buys the lion hides."), B.optional(finish(93443, friz, "Hand over the lost crate from Stranglethorn.")),
    accept(95059, friz, "Friz has a crate for Demar Brant."),
    accept(95118, whizzbuzz), accept(95121, fimbo), accept(95988, zizplink),
    accept(95254, rg("WANTED!", 78.5, 53.9), "Read the wanted poster by the inn."),
    along(objective(95988, rg(nil, 78.6, 49.6), "Kill Shore Crawlers on the beach north of the port.", "3 Crawler Parts"), 95121),
    along(objective(95118, rg(nil, 72.4, 69.5), "Go south along the shore for the murloc camps.", "8 Murloc Oracles", "8 Murloc Warriors"), 95121),
    along(objective(95121, rg(nil, 74.2, 67.2), "Loot eyes from the murlocs and meat from the Sand Crawlers.", "12 Murloc Eyes", "6 Crawler Meat"), 95118),
    along(objective(95254, rg("Trapclaw", 79.5, 53.3), "On the way back, look for Trapclaw, a big crawler that walks the shore by the port.", "Trapclaw's Claw"), 95988),
    finish(95988, zizplink), finish(95254, fimbo), finish(95118, whizzbuzz), finish(95121, fimbo),
    taxi("fly", rg(nil, 77.5, 53.5), farholdeFlight, "Fly back to Farholde Keep."),
    finish(95059, brant), finish(95066, brant), finish(96084, rowland),
    finish(95330, halligan, "When you are next by Turner's Logging Camp, give Halligan the farm goods."),
    finish(94842, halligan), finish(94843, halligan), finish(94931, halligan),
  }, { alternate = true, suggest = { "riverglades-shroud", "dustwallow-40" } })

  rq(94829, "What We Lost", 40, 36)
  rq(94858, "All That's Left", 40, 36, 94829)
  rq(94877, "Saving Sunnyglade", 40, 36)
  rq(94881, "Curious Trinkets", 38, 36)
  rq(94885, "Field Marshal's Log", 40, 36)
  rq(94887, "Saving Marshal Ryan", 47, 36, 94885)
  rq(94892, "Dying Wish", 47, 36, 94887)
  rq(94893, "Delivering Closure", 47, 36, 94892)
  rq(94884, "An Unsettling Discovery", 41, 36)
  rq(95562, "Cut Off the Heads", 41, 36)
  rq(95642, "Abominable Magics", 40, 36)
  rq(95643, "Indiscriminate Purge", 40, 36)
  rq(94961, "Biting the Hand", 40, 36)
  rq(94963, "Biting the Hand", 40, 36, 94961)
  rq(94886, "The Western Front", 44, 38)
  rq(94888, "No Soldier Left Behind", 44, 38, 94886)
  rq(94889, "Carving a Path", 44, 38, 94886)
  rq(96015, "A Miner Problem", 43, 38, 94886)
  rq(94890, "Bring Me His Head", 46, 38, 94889)
  rq(94891, "News to Farholde", 46, 38, 94890)
  rq(94907, "A Small Favor", 44, 36)
  rq(94983, "Twilight Mementos", 42, 38, 94886)
  rq(94984, "Tome of Twilight", 44, 39, 94907)
  rq(94982, "Eye of Mugg", 45, 40)
  rq(94894, "The Twilight Threat", 45, 38)
  rq(96125, "In Need of Relief", 43, 38)
  rq(96126, "An Ogre's Captive", 44, 38, 96125)
  rq(94927, "Dunston Checks Out", 44, 38, 96126)
  rq(95912, "WANTED: Blademaster Kaijo", 42, 38)
  rq(95991, "WANTED: Ghostmaw", 42, 38)
  rq(95119, "Unfriendly Competition", 43, 38)
  rq(95122, "Unchecked Expansion", 44, 38)
  rq(95165, "See Ya, Scallywags!", 44, 38)
  rq(95124, "Admiral Lamora", 45, 38)
  rq(95288, "Smuggler's Paradise", 43, 38)
  rq(95260, "Terrors From the Deep", 42, 38)
  rq(95261, "It Takes Guts", 42, 38, 95260)
  rq(95267, "The Monster Surfaces", 42, 38, 95261)
  rq(95120, "WANTED: Old Rot-Chum", 42, 36)
  rq(95792, "Clear 'em Out", 42, 36)
  local krol = "dungeon-krol-dok-stronghold"

  section("riverglades-shroud", "Riverglades: Sunnyglade and the Twilight's Shroud", M.riverglades, 40, 46, sources, {
    taxi("fly", brant, farholdeFlight, "Fly to Farholde Keep."),
    accept(94877, brant), accept(94886, brant), accept(94894, brant, "Brant also wants Highlord Bolvar warned. Keep the report until you next fly to Stormwind."),
    forDungeon(accept(94982, brant, "Brant's dungeon task: infiltrate Krol'dok Stronghold."), krol),
    accept(94881, ashe), accept(94907, ashe),
    accept(95912, rg("Wanted", 65.9, 81.1), "Read the wanted poster in the keep's courtyard."),
    accept(95991, rg("WANTED!", 65.6, 80.9)),
    accept(96125, cornelius, "Stop at Terral's Watch on the way north."),
    action("goto", elbrim, "Ride north to the farms at Sunnyglade."),
    accept(94829, elbrim, "Farmer Elbrim waits outside his ruined farm."),
    along(objective(94829, rg("Loose Soil", 48.6, 43.8), "Dig in the loose soil around the farm and kill the Twilight Raiders nearby.", "5 Lost Belongings"),
      94877, 94881),
    finish(94829, elbrim), accept(94858, elbrim),
    objective(94858, rg("Converted Farmer", 53.4, 45.0), "Look for what is left of Elbrim's family among the converted farmers east of the farm.", "Converted Farmer"),
    finish(94858, elbrim),
    accept(94884, claire, "Apprentice Claire is camped west of the farm."), accept(95642, claire), accept(95643, claire), accept(95562, claire),
    accept(94961, fuzzle, "Fuzzle, a hungry critter, hides in the brush west of Claire."),
    along(objective(94877, twilight, "Defeat Twilight Shadowmancers, Neophytes and Raiders around Sunnyglade.",
      "8 Twilight Shadowmancers", "8 Twilight Neophytes", "8 Twilight Raiders"), 94881, 94961, 94885),
    along(objective(94881, twilight, "Loot trinkets from the Twilight cultists.", "25 Twilight Trinkets"), 94877, 94961),
    along(objective(94961, twilight, "Fuzzle wants food from the Twilight cultists. Pick it up while you fight.", "20 Morsels"), 94877, 94881),
    accept(94885, nil, "A cultist carries the Field Marshal's log. Read it when it drops."),
    along(objective(95643, rg(nil, 48.4, 48.4), "Kill the Empowered Brutes and Twilight Ritualists at the ritual site.", "5 Empowered Brutes", "5 Twilight Ritualists"),
      95642),
    along(objective(95642, rg(nil, 47.8, 49.4), "Use the item Claire gave you on the brutes and ritualists to absorb their magic.",
      "25 Samples"), 95643),
    note(objective(95562, rg("Chogg'Zac", 44.8, 51.2), "Chogg'Zac lurks in the caves beneath Sunnyglade. Bring a partner.", "Chogg'Zac's Heads"),
      "Two-headed ogre; check whether it is elite."),
    finish(94961, fuzzle), accept(94963, fuzzle),
    objective(94963, rg("Fuzzle's Treasure", 41.7, 47.7), "Follow Fuzzle to its hidden treasure.", "Fuzzle's Treasure"),
    finish(94963, rg("Fuzzle's Treasure", 41.7, 47.7)),
    finish(95642, claire), finish(95643, claire), finish(95562, claire),
    objective(95912, rg("Blademaster Kaijo", 57.4, 36.6), "Blademaster Kaijo trains warriors north of Sunnyglade. Kill him for the bounty.", "Kaijo's Blade"),
    objective(95991, rg("Ghostmaw", 59.9, 46.5), "Ghostmaw hunts the hills east of Sunnyglade.", "Ghostmaw's Head"),
    action("goto", rg(nil, 66.0, 22.0), "Ride north to the ogre camp at Bolder'ok."),
    finish(96125, dunston, "Find Dunston Willis, held by the ogres."), accept(96126, dunston),
    objective(96126, rg("Gronok the Butcher", 67.6, 19.2), "Kill Gronok the Butcher and take the key to Dunston's shackles.", "Shackle Key"),
    finish(96126, dunston), accept(94927, dunston),
    objective(94927, dunston, "Escort Dunston out of Bolder'ok. Fight off the ogres that chase you.", "Dunston Escorted"),
    finish(94927, cornelius, "Report to Watcher Cornelius at Terral's Watch."),
    action("goto", brant, "Ride south to Farholde Keep."),
    finish(94877, brant), finish(94881, ashe), finish(94884, ashe), finish(94885, brant), accept(94887, brant), finish(95912, ember),
    finish(95991, rg("Wheatley", 63.6, 85.0)),
    action("goto", riftan, "Ride west to the Twilight's Shroud and find Sergeant Riftan at the edge of the fog."),
    finish(94886, riftan), accept(94888, riftan), accept(94889, riftan), accept(96015, riftan),
    forDungeon(accept(94983, riftan, "Riftan wants bangles from the Twilight's Hammer inside Krol'dok."), krol),
    along(objective(94889, rg(nil, 29.6, 44.2), "Fight through the Twilight Fanatics, Corrupters and Champions in the Shroud.",
      "8 Twilight Fanatics", "8 Twilight Corrupters", "8 Twilight Champions"), 94888, 94907, 96015),
    along(objective(94888, rg(nil, 27.4, 38.8), "Free the captured Farholde Scouts in the Shroud.", "5 Farholde Scouts"), 94889, 96015),
    along(objective(94907, rg(nil, 26.6, 47.8),
      "Summon a Twilight's Thrall at one of the conduits and capture it with the item Ashe gave you.", "Twilight's Thrall"), 94889),
    objective(96015, rg(nil, 27.0, 35.6), "Defeat the Ogre Miners and their Twilight Subjugators at the dig in the north of the Shroud.",
      "5 Ogre Miners", "5 Twilight Subjugators"),
    objective(94887, ryan, "Find Marshal Ryan deep in the Shroud.", "Marshal Ryan"),
    finish(94887, ryan), accept(94892, ryan),
    finish(94888, riftan), finish(94889, riftan), finish(96015, riftan), accept(94890, riftan),
    note(objective(94890, rg("Overlord Kilgar", 26.6, 44.8), "Overlord Kilgar commands the Shroud. Bring a group or come back at 46.", "Kilgar's Head"),
      "Likely a group fight; check in game."),
    finish(94890, riftan), accept(94891, riftan),
    action("goto", brant, "Ride back east to Farholde Keep."),
    finish(94891, ashe), finish(94892, brant), finish(94907, ashe),
    forDungeon(accept(94984, ashe, "Ashe's next task, Nar'gurk, is inside Krol'dok Stronghold."), krol),
    accept(94893, brant),
    taxi("fly", rg(nil, 60.6, 81.6), portFlight, "Fly to Powderfuse Port for the pirates on the east coast."),
    accept(95119, whizzbuzz), accept(95122, whizzbuzz), accept(95165, whizzbuzz), accept(95124, whizzbuzz), accept(95288, friz),
    accept(95120, rg("WANTED!", 78.5, 53.9)),
    accept(95260, rg("Painted Hide", 72.3, 61.8), "Look at the painted hide on the shore south of the port."),
    finish(95260, argo), accept(95261, argo),
    along(objective(95122, rg(nil, 78.4, 35.6), "Go north along the coast to the Eastsea pirate camp for Raiders and Bombardiers.",
      "8 Eastsea Raiders", "8 Eastsea Bombardiers"), 95119, 95288, 95165, 95261),
    along(objective(95119, rg(nil, 85.5, 35.0), "Kill Eastsea Buccaneers and Musketeers farther east.", "10 Eastsea Buccaneers", "10 Eastsea Musketeers"),
      95122, 95288, 95165),
    along(objective(95288, rg(nil, 85.5, 35.0), "Loot smuggled goods from the Eastsea pirates.", "8 Smuggled Goods"), 95119, 95122),
    along(objective(95165, rg("Cannon Ammunition", 88.4, 25.8), "Plant charges on the three piles of cannon ammunition along the pirate shore.",
      "3 Charges Planted"), 95119, 95124),
    note(objective(95124, rg("Admiral Lamora", 90.6, 29.2), "Admiral Lamora commands from the far end of the pirate shore. Clear her guards first.",
      "Admiral Lamora"), "Group size needed is unknown; check in game."),
    along(objective(95261, rg(nil, 78.0, 56.6), "Loot guts from the boars, crawlers and other beasts along the coast.", "15 Beast Guts"), 95120),
    objective(95120, rg("Old Rot-Chum", 77.4, 72.2), "Old Rot-Chum roams the south shore.", "Proof of Old Rot-Chum"),
    finish(95119, whizzbuzz), finish(95122, whizzbuzz), finish(95165, whizzbuzz), finish(95124, whizzbuzz),
    finish(95288, friz), finish(95120, whizzbuzz), finish(95261, argo), accept(95267, argo),
    objective(95267, rg("Monstrous Threshadon", 74.4, 72.2),
      "Use the item Argo gave you in the water south of the port, then kill the Monstrous Threshadon.", "Monstrous Threshadon"),
    finish(95267, argo),
    taxi("fly", rg(nil, 77.5, 53.5), farholdeFlight, "Fly to Farholde Keep, then ride west to Southern Watch."),
    accept(95792, gelinda, "Gelinda Coppergleam, near Southern Watch, wants the dragon whelps cleared."),
    objective(95792, rg(nil, 29.6, 73.2), "Kill Cinderscale Whelps and Warriors south of Gelinda's camp.", "8 Cinderscale Whelps", "8 Cinderscale Warriors"),
    finish(95792, gelinda),
    taxi("fly", rg(nil, 60.6, 81.6), "Stormwind, Elwynn", "Ride back to Farholde Keep and fly to Stormwind."),
    finish(94893, at("Abigail Lawson", 50.2, 51.8, M.stormwind), "Deliver Marshal Ryan's last words to Abigail Lawson near the Cathedral."),
    finish(94894, at("Highlord Bolvar Fordragon", 80.21, 38.35, M.stormwind), "Report the Twilight threat to Highlord Bolvar in Stormwind Keep."),
  }, { alternate = true, suggest = { "feralas-44", "searing-gorge", "shendralas" } })
end


-- Desolace from Nijel's Point: the Reclaimers, the Malem family, the centaur war and the kodo graveyard.
do
  local ds = on.desolace
  local kreldig = ds("Kreldig Ungor", 66.2, 9.63)
  local vahlarriel = ds("Vahlarriel Demonslayer", 66.44, 11.82)
  local anton = ds("Brother Anton", 66.52, 7.91)
  local melkins = ds("Corporal Melkins", 66.74, 10.87)
  local pentigast = ds("Captain Pentigast", 66.66, 10.93)
  local lyshaerya = ds("Innkeeper Lyshaerya", 66.3, 6.6)
  local azore = ds("Azore Aldamort", 38.88, 27.16)
  local dalinda = ds("Dalinda Malem", 54.86, 26.13)
  local bibbly = ds("Bibbly F'utzbuckle", 62.33, 38.99)
  local smeed = ds("Smeed Scrabblescrew", 60.86, 61.86)
  local chest = ds("Karnitol's Chest", 36.11, 30.45)
  local graveyard = ds(nil, 52.5, 58.6)
  local thunderAxe = ds(nil, 55.5, 28.5)
  local nijels = { bind = "Nijel's Point" }

  q(1458, "Reagents for Reclaimers Inc.", 33, 30, 1453)
  q(1459, "Reagents for Reclaimers Inc.", 35, 30, 1458)
  q(1454, "The Karnitol Shipwreck", 39, 30, 1453)
  q(1455, "The Karnitol Shipwreck", 39, 30, 1454)
  q(1456, "The Karnitol Shipwreck", 39, 30, 1455)
  q(1457, "The Karnitol Shipwreck", 39, 30, 1456)
  q(1437, "Vahlarriel's Search", 33, 30)
  q(1465, "Vahlarriel's Search", 33, 30, 1437)
  q(1438, "Vahlarriel's Search", 33, 30, 1465)
  q(1439, "Search for Tyranis", 33, 30, 1438)
  q(1440, "Return to Vahlarriel", 33, 30, 1439)
  q(97284, "Vahlarriel's Vengeance", 36, 30, nil, true)
  q(5741, "Sceptre of Light", 33, 30)
  q(6027, "Book of the Ancients", 38, 30, 5741)
  q(6161, "Claim Rackmore's Treasure!", 36, 30)
  q(261, "Down the Scarlet Path", 39, 34)
  q(1052, "Down the Scarlet Path", 40, 34, 261)
  q(1387, "Centaur Bounty", 31, 30)
  q(1382, "Strange Alliance", 35, 30)
  q(5501, "Bone Collector", 39, 33)
  q(5561, "Kodo Roundup", 34, 30)

  section("desolace-35", "Desolace: Nijel's Point", M.desolace, 35, 37, {
    "https://www.wowhead.com/forever/zone=405/desolace",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.dustwallow("Baldruc", 67.5, 51.3), "Thalanaar, Feralas", "Fly from Theramore to Thalanaar."),
    action("goto", on.feralas(nil, 44.9, 4.0), "Follow the road west across Feralas, then take the north fork into Desolace. Stay on the road past the ogre ruins."),
    action("goto", kreldig, "Keep north on the Desolace road to Nijel's Point, high on the eastern ridge."),
    taxi("getfp", ds("Baritanas Skyriver", 64.7, 10.5), "Nijel's Point, Desolace", "Learn the Nijel's Point flight path."),
    action("sethearth", lyshaerya, "Bind at the Nijel's Point inn.", nijels),
    finish(1453, kreldig, "Kreldig Ungor runs the Reclaimers' camp."), accept(1458, kreldig), accept(1454, kreldig),
    accept(1437, vahlarriel), accept(97284, vahlarriel, "Vahlarriel also wants the Burning Blade at Thunder Axe Fortress punished."), accept(261, anton), accept(1387, melkins), accept(1382, pentigast),
    objective(1458, ds(nil, 72.5, 17.9), "Go east to the satyr grounds at Sargeron and loot claws and horns from the Hatefury satyrs.",
      "10 Hatefury Claws", "10 Hatefury Horns"),
    finish(1458, kreldig), accept(1459, kreldig),
    finish(1437, ds("Malem Chest", 56.52, 17.84), "Ride west to the burned Malem wagon and search the chest."),
    accept(1465, ds("Malem Chest", 56.52, 17.84)),
    accept(5741, azore, "Follow the road west to Azore Aldamort's tower at Ethel Rethor."),
    finish(1454, chest, "Walk down to the Karnitol shipwreck on the coast and open Karnitol's chest."), accept(1455, chest),
    accept(6161, ds("Rackmore's Log", 36.07, 30.41), "Read Rackmore's log beside the chest."),
    objective(6161, ds(nil, 33.2, 31.6), "Kill the Drysnap crabs along the shore for Rackmore's Silver Key.", "Rackmore's Silver Key"),
    action("hearth", lyshaerya, "Hearth to Nijel's Point.", nijels),
    finish(1455, kreldig), accept(1456, kreldig),
    finish(1465, vahlarriel), accept(1438, vahlarriel),
    action("goto", thunderAxe, "Ride southwest to Thunder Axe Fortress."),
    along(objective(5741, ds("Burning Blade Seer", 55.2, 30.1), "Kill the Burning Blade Seer inside the fortress for the Sceptre of Light.", "Sceptre of Light"),
      97284, 1459),
    along(objective(97284, thunderAxe, "Clear the Burning Blade Augurs, Reavers and the rest of the fortress garrison.",
      "Burning Blade Augurs", "Burning Blade Reavers"), 5741),
    finish(1438, dalinda, "Dalinda Malem is held in the fortress's north building."), accept(1439, dalinda),
    objective(1439, ds("Tyranis Malem", 53.0, 29.1), "Find Tyranis Malem in the fortress. He has turned to the Burning Blade: kill him.", "Tyranis' Pendant"),
    finish(1439, dalinda), accept(1440, dalinda),
    objective(1440, dalinda, "Escort Dalinda out of the fortress. Clear the way first and stay close to her.", "Dalinda escorted"),
    accept(5501, bibbly, "Bibbly F'utzbuckle waits at Kormek's Hut, east of the road south."),
    action("goto", ds(nil, 69.4, 73.4), "Ride south to the Magram centaur village in the southeast."),
    along(objective(1387, ds(nil, 69.4, 73.4), "Kill Magram centaurs for their ears. Every kill also raises your standing with the Gelkis.", "15 Centaur Ears"), 1382),
    objective(261, ds(nil, 64.0, 91.7), "Go south to the Scarlet camp at the edge of the Valley of Bones and kill Undead Ravagers.", "30 Undead Ravagers"),
    accept(5561, smeed, "Smeed Scrabblescrew camps beside the Kodo Graveyard."),
    along(withItem(13892, objective(5561, graveyard, "Use the Kodo Kombobulator on Ancient or Dying Kodos in the graveyard, then walk each tamed kodo back to Smeed.",
      "5 Tamed Kodos")), 5501, 1459),
    along(objective(5501, graveyard, "Pick up kodo bones from the ground in the graveyard.", "10 Kodo Bones"), 5561, 1459),
    along(objective(1459, ds(nil, 52.2, 57.5), "Kill Scorpashi scorpids around the graveyard for venom, and Aged Kodos for their hides.",
      "7 Scorpashi Venom", "3 Aged Kodo Hides"), 5561, 5501),
    finish(5561, smeed),
    action("goto", ds(nil, 40.0, 75.0), "Ride west across the south of Desolace toward the Gelkis village."),
    finish(1382, ds("Uthek the Wise", 36.22, 79.25), "Once the Gelkis are Friendly, find Uthek the Wise in their village."),
    action("goto", bibbly, "Ride back northeast to Kormek's Hut."),
    finish(5501, bibbly),
    finish(5741, azore, "Bring the Sceptre to Azore at Ethel Rethor."), accept(6027, azore),
    objective(6027, ds("Lord Kragaru", 28.2, 6.7), "Go north along the coast to the Ranazjar Isle ogres. Lord Kragaru carries the Book of the Ancients.",
      "Book of the Ancients"),
    along(objective(1456, ds(nil, 30.8, 8.0), "Kill Slitherblade naga at the northern shore until Karnitol's Satchel drops.", "Karnitol's Satchel"), 6161),
    along(objective(6161, ds(nil, 30.8, 8.0), "The Slitherblade naga also carry Rackmore's Golden Key.", "Rackmore's Golden Key"), 1456),
    finish(6161, ds("Rackmore's Chest", 30.0, 8.71), "Open Rackmore's chest on the small isle off the coast."),
    finish(6027, azore),
    action("hearth", lyshaerya, "Hearth to Nijel's Point.", nijels),
    finish(1456, kreldig), accept(1457, kreldig, "Keep the satchel for Roetten Stonehammer in Ironforge."),
    finish(1459, kreldig), finish(261, anton), accept(1052, anton, "Keep Anton's letter for Raleigh the Devout in Southshore."),
    finish(1387, melkins), finish(1440, vahlarriel), finish(97284, vahlarriel),
    taxi("fly", ds("Baritanas Skyriver", 64.7, 10.5), "Theramore, Dustwallow Marsh", "Fly to Theramore."),
  }, { suggest = { "riverglades-farholde", "theramore-33" } })
end

-- Stranglethorn at 36-38: Booty Bay, the Rebel Camp, the Kurzen compound and the Nesingwary hunts, in two loops.
do
  local st = on.stv
  local krazek = st("Krazek", 26.94, 77.21)
  local kebok = st("Kebok", 27.0, 77.13)
  local revilgaz = st("Baron Revilgaz", 27.23, 76.87)
  local crank = st("Crank Fizzlebub", 27.12, 77.21)
  local lozgil = st("Wharfmaster Lozgil", 26.35, 73.56)
  local skindle = st("Innkeeper Skindle", 27.0, 77.3)
  local gyll = st("Gyll", 27.5, 77.8)
  local yohwa = st("Sergeant Yohwa", 38.02, 3.33)
  local doren = st("Lieutenant Doren", 38.04, 3.01)
  local nimetz = st("Brother Nimetz", 37.83, 3.56)
  local hemet = st("Hemet Nesingwary", 35.66, 10.81)
  local ajeck = st("Ajeck Rouack", 35.62, 10.62)
  local erlgadin = st("Sir S. J. Erlgadin", 35.55, 10.55)
  local wendel = st("Wendel Mathers", 44.3, 7.9)
  local zimmix = st("Zimmix Sputterspark", 23.5, 12.8)
  local kurzen = st(nil, 44.9, 10.2)
  local bloodscalp = st(nil, 25.5, 9.4)
  local bootyBay = { bind = "Booty Bay" }

  q(1180, "Goblin Sponsorship", 37, 29, 1178)
  q(1181, "Goblin Sponsorship", 37, 29, 1180)
  q(1182, "Goblin Sponsorship", 37, 29, 1181)
  q(605, "Singing Blue Shards", 35, 30)
  q(213, "Hostile Takeover", 36, 31)
  q(198, "Supplies to Private Thorsen", 32, 30)
  q(201, "Investigate the Camp", 32, 28)
  q(616, "The Haunted Isle", 37, 32)
  q(578, "The Stone of the Tides", 37, 32, 616)
  q(601, "Water Elementals", 37, 32, 578)
  q(602, "Magical Analysis", 37, 32, 601)
  q(203, "The Second Rebellion", 33, 30)
  q(204, "Bad Medicine", 34, 30)
  q(574, "Special Forces", 38, 30, { 203, 204 })
  q(207, "Kurzen's Mystery", 38, 30, { 203, 204 })
  q(200, "Bookie Herod", 35, 30, 215)
  q(328, "The Hidden Key", 37, 30, 200)
  q(329, "The Spy Revealed!", 37, 30, 328)
  q(330, "Patrol Schedules", 37, 30, 329)
  q(331, "Report to Doren", 37, 30, 330)
  q(210, "Krazek's Cookery", 37, 32)
  q(189, "Bloodscalp Ears", 35, 30)
  q(186, "Tiger Mastery", 33, 28, 185)
  q(187, "Tiger Mastery", 35, 28, 186)
  q(188, "Tiger Mastery", 37, 28, 187)
  q(191, "Panther Mastery", 33, 28, 190)
  q(192, "Panther Mastery", 38, 28, 191)
  q(194, "Raptor Mastery", 34, 28, 583)
  q(195, "Raptor Mastery", 36, 28, 194)
  q(97047, "The Cook in the Cage", 37, 30, nil, true)
  q(97048, "Returning to Port", 37, 30, 97047, true)
  q(97328, "Anything of Value", 35, 30, nil, true)
  q(97329, "Where's the Key?", 37, 30, nil, true)
  q(97331, "Zimmix's Great Escape", 37, 30, 97329, true)

  section("stv-36", "Stranglethorn: Rebels, Kurzen and Nesingwary", M.stv, 36, 38, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("goto", on.barrens(nil, 62.6, 37.0), "Leave Theramore west and follow the Barrens road north to Ratchet on the coast."),
    taxi("getfp", on.barrens("Bragok", 63.1, 37.2), "Ratchet, The Barrens", "Learn the Ratchet flight path."),
    finish(1178, on.barrens("Gazlowe", 62.68, 36.23), "Gazlowe has his office above the docks."),
    accept(1180, on.barrens("Gazlowe", 62.68, 36.23), "Gazlowe sends you on to Booty Bay."),
    finish(1111, on.barrens("Wharfmaster Dizzywig", 63.35, 38.45)),
    action("boat", on.barrens(nil, 63.7, 38.6), "Take the boat from Ratchet's dock to Booty Bay. Use Next when you arrive.",
      { name = "Ratchet - Booty Bay" }),
    taxi("getfp", gyll, "Booty Bay, Stranglethorn", "Learn the Booty Bay flight path from Gyll, up the ramps above the inn."),
    action("note", nil, "Stranglethorn fills your quest log. Abandon the Blackfathom Deeps and Excavation Site quests if you are not going to run them.",
      { name = "Quest log", drop = { 971, 1275, 95646, 95647, 98815 } }),
    finish(1180, lozgil, "Wharfmaster Lozgil stands on the docks."), accept(1181, lozgil),
    accept(605, crank, "Crank Fizzlebub waits on the inn's lower floor."),
    action("sethearth", skindle, "Bind at the Salty Sailor Tavern.", bootyBay),
    accept(198, krazek, "Krazek, on the inn's upper balcony, has supplies for the Rebel Camp."), accept(201, krazek), accept(616, krazek),
    accept(213, kebok, "Kebok stands beside Krazek."), accept(189, kebok),
    finish(616, revilgaz, "Baron Revilgaz looks over the bay from the top floor of the inn."), accept(578, revilgaz),
    finish(1181, revilgaz), accept(1182, revilgaz),
    taxi("fly", gyll, "Darkshire, Duskwood", "Fly to Darkshire."),
    action("goto", st(nil, 38.0, 3.5), "Take the road south out of Duskwood into Stranglethorn and climb to the Rebel Camp."),
    finish(198, st("Private Thorsen", 37.98, 3.41)), accept(203, yohwa), accept(204, yohwa), accept(200, doren),
    accept(210, st("Corporal Kaleb", 37.74, 3.3), "Corporal Kaleb has a recipe errand for Krazek in Booty Bay."),
    B.optional(accept(93443, st("Lost Shipping Crate", 38.0, 3.1),
      "A lost shipping crate sits by the Rebel Camp. Take it if you plan to visit the Riverglades.")),
    objective(201, hemet, "Walk down to Nesingwary's Expedition: you have found the hunters' camp for Krazek.", "Hunters' Camp Found"),
    accept(186, ajeck), accept(191, erlgadin), accept(194, hemet),
    accept(97047, wendel, "Wendel Mathers hides on the slope above the Kurzen compound. His cook is locked up inside."),
    along(objective(203, kurzen, "Clear the Kurzen Jungle Fighters around the compound.", "15 Kurzen Jungle Fighters"), 204, 200, 97047),
    along(objective(204, kurzen, "Medicine Men carry Jungle Remedies. The Venom Fern Extract is in a chest in the compound's back cave.",
      "7 Jungle Remedy", "Venom Fern Extract"), 203, 200, 97047),
    along(objective(97047, st(nil, 48.8, 5.4), "Loot a Kurzen Fighter's Uniform and the compound's cage key from the Kurzen guards, then free the cook.",
      "Kurzen Fighter's Uniform", "Compound Cage Key"), 203, 204),
    finish(200, st("Bookie Herod's Records", 43.67, 9.37), "Read Bookie Herod's records in the compound."),
    accept(328, st("Bookie Herod's Records", 43.67, 9.37)),
    finish(328, st("Bookie Herod's Strongbox", 49.62, 7.56), "Open Bookie Herod's strongbox east of the compound with the small brass key."),
    accept(329, st("Bookie Herod's Strongbox", 49.62, 7.56)),
    finish(97047, wendel), accept(97048, wendel, "Keep his note for Captain Aransas in Booty Bay."),
    along(objective(605, st(nil, 48.5, 8.8), "Kill Stone Maw basilisks east of the compound for Singing Crystal Shards.", "10 Singing Crystal Shards"), 186),
    along(objective(186, st(nil, 46.7, 15.8), "Hunt Stranglethorn Tigers in the jungle south of the compound.", "10 Stranglethorn Tigers"), 213, 1182),
    along(objective(213, st(nil, 45.6, 18.8), "Kill Venture Co. Geologists at the dig south of the tigers for Tumbled Crystals.", "8 Tumbled Crystals"), 1182),
    along(objective(1182, st(nil, 43.3, 20.3), "Search the Venture Co. camp for the fuel regulator blueprints.", "Fuel Regulator Blueprints"), 213),
    finish(203, yohwa), finish(204, yohwa), accept(574, yohwa), accept(207, nimetz, "Brother Nimetz wants the troll tablets read."),
    finish(329, doren), accept(330, doren), finish(330, st("Corporal Sethman", 37.66, 3.39)), accept(331, st("Corporal Sethman", 37.66, 3.39)),
    finish(331, doren),
    objective(574, st(nil, 47.9, 7.8), "Back in the compound, kill Kurzen Commandos and Headshrinkers.", "10 Kurzen Commandos", "6 Kurzen Headshrinkers"),
    finish(186, ajeck), accept(187, ajeck),
    accept(97328, st("Thoroughly Scavenged Supplies", 31.55, 12.95), "Search the scavenged supplies west of Nesingwary's camp."),
    along(objective(191, st(nil, 29.8, 11.2), "Panthers prowl the jungle west of the camp.", "10 Panthers"), 187, 194, 97328),
    along(objective(187, st(nil, 31.9, 19.9), "Elder Stranglethorn Tigers live farther south and west.", "10 Elder Stranglethorn Tigers"), 191, 194),
    along(objective(194, st(nil, 27.2, 16.1), "Stranglethorn Raptors hunt near the western coast.", "10 Stranglethorn Raptors"), 191, 187, 207),
    accept(97329, zimmix, "Zimmix Sputterspark is caged near the Bloodscalp camp on the coast."),
    along(objective(189, bloodscalp, "Kill Bloodscalp trolls along the coast for their ears.", "15 Bloodscalp Ears"), 97329, 97328),
    along(objective(97329, bloodscalp, "A Bloodscalp troll carries Zimmix's Primitive Key.", "Primitive Key"), 189),
    along(objective(97328, st(nil, 26.0, 13.0), "Pick up the stolen shipments scattered around the Bloodscalp camps.", "8 Stolen Shipments"), 189),
    finish(97329, zimmix), accept(97331, zimmix),
    objective(97331, zimmix, "Help Zimmix out of the troll camp.", "Zimmix Escaped"),
    B.objectivePart(207, 4, st("Tablet", 24.7, 8.9), "Read the troll tablet in the ruins just north of the Bloodscalp camp.", "The Fourth Troll Legend"),
    B.objectivePart(207, 3, st("Tablet", 22.9, 12.0), "Read the next tablet in the ruins by the coast.", "The Third Troll Legend"),
    B.objectivePart(207, 1, st("Tablet", 29.5, 19.1), "Head southeast to the tablet on the ridge above the elder tigers.", "The First Troll Legend"),
    B.objectivePart(207, 2, st("Tablet", 24.8, 22.9), "Go back west to the coast for the last tablet at the Ruins of Aboraz.", "The Second Troll Legend"),
    objective(578, st("Stone of the Tides", 21.6, 21.8), "Swim to the Haunted Isle just off the coast and take the Stone of the Tides from its pool.",
      "Stone of the Tides"),
    finish(191, erlgadin), finish(187, ajeck), finish(194, hemet), accept(195, hemet), accept(188, ajeck), accept(192, erlgadin),
    finish(207, nimetz), finish(574, doren),
    action("hearth", skindle, "Hearth to Booty Bay.", bootyBay),
    finish(605, crank), finish(213, kebok), finish(189, kebok), finish(201, krazek), finish(210, krazek),
    finish(1182, revilgaz), finish(578, revilgaz), accept(601, revilgaz),
    finish(97048, st("Captain Aransas", 27.7, 76.6)), finish(97328, lozgil), finish(97331, lozgil),
    action("goto", st(nil, 36.1, 37.3), "Follow the road north out of Booty Bay toward the middle of the vale."),
    objective(192, st(nil, 36.1, 37.3), "Shadowmaw Panthers stalk unseen in the jungle around Mistvale Valley. Watch for stealth.", "10 Shadowmaw Panthers"),
    objective(195, st(nil, 31.4, 22.3), "Lashtail Raptors run in packs farther north near the coast.", "10 Lashtail Raptors"),
    objective(188, st("Sin'Dall", 32.2, 17.2), "Sin'Dall, a big white tiger, prowls on the hill above the elder tigers.", "Paw of Sin'Dall"),
    objective(601, st(nil, 21.1, 22.8), "Kill Lesser Water Elementals around the Haunted Isle for their bracers.", "6 Water Elemental Bracers"),
    finish(195, hemet), finish(188, ajeck), finish(192, erlgadin),
    action("goto", revilgaz, "Ride back south to Booty Bay, or hearth if it is ready."),
    finish(601, revilgaz), accept(602, revilgaz, "Keep the bracers for Archmage Ansirem in Dalaran, in the Alterac Mountains."),
  }, { suggest = { "riverglades-farholde" } })
end

-- Stormwind errands, the Swamp of Sorrows and Nethergarde Keep.
do
  local sw, sm = on.stormwind, on.swamp
  local biggs = sm("Watcher Biggs", 26.74, 59.83)
  local magtoor = sm("Magtoor", 25.98, 31.4)
  local galen = sm("Galen Goodward", 65.47, 18.16)
  local brohann = sw("Brohann Caskbelly", 69.45, 40.4)
  local dellis = sw("Acolyte Dellis", 51.4, 73.81)

  q(1260, "Morgan Stern", 38, 33)
  q(1363, "Mazen's Behest", 41, 37)
  q(1364, "Mazen's Behest", 41, 37, 1363)
  q(1448, "In Search of The Temple", 43, 38)
  q(1449, "To The Hinterlands", 43, 38, 1448)
  q(543, "The Perenolde Tiara", 40, 30)
  q(1396, "Encroaching Wildlife", 37, 30)
  q(1421, "The Lost Caravan", 35, 30, 1396)
  q(1392, "Noboru the Cudgel", 39, 29)
  quest[1392].startItem = 6196
  q(1389, "Draenethyst Crystals", 35, 30)
  q(1393, "Galen's Escape", 38, 30)

  section("swamp-38", "Swamp of Sorrows and Nethergarde", M.swamp, 38, 39, {
    "https://www.wowhead.com/forever/zone=8/swamp-of-sorrows",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.stv("Gyll", 27.5, 77.8), "Stormwind, Elwynn", "Fly to Stormwind."),
    accept(1260, sw("Angus Stern", 51.79, 93.64), "Angus Stern, by the Mage Quarter's south gate, has a letter for his brother in Theramore."),
    accept(1363, sw("Mazen Mac'Nadir", 51.8, 74.24), "Mazen Mac'Nadir works in the Mage Quarter's tower."),
    finish(1363, dellis, "Acolyte Dellis stands beside him."), accept(1364, dellis, "Dellis wants Khadgar's lost essays found in the swamp and taken to Nethergarde Keep."),
    accept(1448, brohann, "Brohann Caskbelly in the Dwarven District is looking for a lost temple in the swamp."),
    accept(543, sw("Count Remington Ridgewell", 76.94, 47.83), "Count Remington Ridgewell, in Stormwind Keep, wants the Perenolde Tiara from Alterac. Keep it for later."),
    taxi("fly", sw("Dungar Longdrink", 71.3, 72.2), "Darkshire, Duskwood", "Fly to Darkshire."),
    action("goto", sm(nil, 10.0, 54.0), "Take the east road out of Darkshire through Deadwind Pass into the Swamp of Sorrows."),
    accept(1396, biggs, "Watcher Biggs camps by the road at the swamp's western edge."),
    B.optional(accept(94929, biggs, "Biggs also has a shipment for the Riverglades. Take it if you plan to go there.")),
    withItem(6196, accept(1392, nil, "If Noboru's Cudgel dropped from the mossy giant Noboru, read it to start the quest.")),
    accept(1389, magtoor, "Ride north to the Harborage, the draenei refuge on the swamp's northwest shore, and find Magtoor."),
    finish(1392, magtoor),
    objective(1364, sm(nil, 15.0, 37.3), "Swampwalkers and Tangled Horrors around the western pools carry Khadgar's essays.",
      "Khadgar's Essays on Dimensional Convergence"),
    objective(1396, sm(nil, 44.0, 41.6), "Hunt Young Sawtooth Crocolisks, Sorrow Spinners and Swamp Jaguars across the western swamp.",
      "8 Young Sawtooth Crocolisks", "10 Sorrow Spinners", "10 Swamp Jaguars"),
    finish(1396, biggs), accept(1421, biggs),
    action("goto", sm(nil, 60.5, 23.2), "Ride east along the north shore."),
    along(objective(1389, sm(nil, 60.5, 23.2), "Pick up the glowing Draenethyst crystals around the Lost One villages.", "6 Draenethyst Crystals"), 1421),
    along(objective(1421, sm("Caravan Chest", 64.5, 18.3), "Open the caravan chest in the Fallow Sanctuary for the Wizards' Reagents.", "Wizards' Reagents"), 1389),
    accept(1393, galen, "Galen Goodward is caged nearby. Free him and accept his escort."),
    objective(1393, galen, "Escort Galen out of the sanctuary. He runs off once safe, and his strongbox waits at his old camp.", "Galen escorted"),
    finish(1393, sm("Galen's Strongbox", 47.81, 39.76), "Open Galen's strongbox at his camp by the lake."),
    objective(1448, sm(nil, 67.0, 47.0), "Wade into the lake at the swamp's centre-east until you see the sunken Temple of Atal'Hakkar.",
      "Temple of Atal'Hakkar found"),
    finish(1389, magtoor),
    finish(1421, biggs),
    action("goto", on.blasted(nil, 60.0, 15.0), "Take the road south from the swamp into the Blasted Lands and follow it to Nethergarde Keep."),
    taxi("getfp", on.blasted("Alexandra Constantine", 65.5, 24.3), "Nethergarde Keep, Blasted Lands", "Learn the Nethergarde Keep flight path."),
    finish(1364, on.blasted("Watcher Mahar Ba", 67.65, 19.17), "Watcher Mahar Ba is inside the keep."),
    taxi("fly", on.blasted("Alexandra Constantine", 65.5, 24.3), "Stormwind, Elwynn", "Fly to Stormwind."),
    finish(1448, brohann), accept(1449, brohann, "Keep the introduction for Falstad Wildhammer in the Hinterlands."),
  }, { suggest = { "riverglades-farholde" } })
end

-- Arathi's binding stones and Faldir's Cove, Southshore's Alterac bounties, and Aerie Peak.
do
  local ar, hb, al, ifg = on.arathi, on.hillsbrad, on.alterac, on.ironforge
  local kryten = ar("Apprentice Kryten", 46.2, 47.75)
  local skuerto = ar("Skuerto", 46.65, 47.01)
  local nials = ar("Captain Nials", 45.83, 47.56)
  local quae = ar("Quae", 60.18, 53.85)
  local kinelory = ar("Kinelory", 60.24, 53.92)
  local shards = ar("Iridescent Shards", 84.31, 30.95)
  local inner = ar("Stone of Inner Binding", 36.23, 57.38)
  local keystone = ar("Keystone", 36.08, 58.09)
  local obreen = ar("Shakes O'Breen", 32.28, 81.38)
  local nilzlix = ar("First Mate Nilzlix", 32.8, 81.48)
  local steelgut = ar("Captain Steelgut", 34.0, 80.8)
  local draxlegauge = ar("Doctor Draxlegauge", 33.86, 80.45)
  local maleb = hb("Magistrate Henry Maleb", 48.14, 59.11)
  local dibbs = hb("Loremaster Dibbs", 50.57, 57.09)
  local redpath = hb("Marshal Redpath", 49.47, 58.73)
  local anderson = hb("Innkeeper Anderson", 51.2, 58.9)
  local falstad = on.hinterlands("Falstad Wildhammer", 11.81, 46.76)
  local southshore = { bind = "Southshore" }

  q(525, "Further Mysteries", 34, 30, 514)
  q(691, "Worth Its Weight in Gold", 36, 30, 690)
  q(693, "Wand over Fist", 39, 30, 691)
  q(694, "Trelane's Defenses", 39, 30, 693)
  q(695, "An Apprentice's Enchantment", 39, 30, 694)
  q(685, "Wanted!  Otto and Falconcrest", 40, 30)
  q(657, "Hints of a New Plague?", 36, 30, 658)
  q(660, "Hints of a New Plague?", 37, 30, 657)
  q(661, "Hints of a New Plague?", 37, 30, 660)
  q(642, "The Princess Trapped", 37, 30)
  q(651, "Stones of Binding", 38, 30, 642)
  q(652, "Breaking the Keystone", 42, 30, 651)
  q(653, "Myzrael's Allies", 40, 30, 652)
  q(663, "Land Ho!", 35, 35)
  q(662, "Deep Sea Salvage", 40, 35, 663)
  q(664, "Drowned Sorrows", 40, 35)
  q(665, "Sunken Treasure", 40, 35)
  q(666, "Sunken Treasure", 40, 35, 665)
  q(668, "Sunken Treasure", 40, 35, 666)
  q(500, "Crushridge Bounty", 36, 30)
  q(537, "Dark Council", 40, 30, 525)
  q(512, "Noble Deaths", 36, 26, 510)
  q(540, "Preserving Knowledge", 38, 20, 538)
  q(542, "Return to Milton", 38, 20, 540)
  q(551, "The Ensorcelled Parchment", 40, 30)
  quest[551].startItem = 3706
  q(554, "Stormpike's Deciphering", 40, 28, 551)
  q(1450, "Gryphon Master Talonaxe", 43, 38, 1449)
  q(1451, "Rhapsody Shindigger", 43, 38, 1450)
  q(1053, "In the Name of the Light", 40, 34, 1052)
  q(1050, "Mythology of the Titans", 38, 28)

  section("arathi-39", "Arathi Highlands, Alterac and Aerie Peak", M.arathi, 39, 40, {
    "https://www.wowhead.com/forever/zone=45/arathi-highlands",
    "https://www.wowhead.com/forever/zone=36/alterac-mountains",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("goto", nil, "Take the Deeprun Tram from Stormwind to Ironforge. Use Next when you arrive."),
    finish(1457, ifg("Roetten Stonehammer", 69.95, 21.26), "Give Karnitol's satchel to Roetten Stonehammer in the Hall of Explorers."),
    accept(525, ifg("Prospector Stormpike", 74.64, 11.74), "Prospector Stormpike has decoded the Syndicate letter. Take it to Southshore."),
    action("buy", ifg("Auctioneer Lympkin", 23.8, 71.8), "Buy an Elixir of Water Breathing at the Auction House (an alchemist can make one). Faldir's Cove's wreck quest is under water."),
    taxi("fly", ifg("Gryth Thurden", 55.5, 47.7), "Refuge Pointe, Arathi", "Fly to Refuge Pointe."),
    accept(691, kryten, "Apprentice Kryten wants troll goods for Skuerto's research."),
    accept(685, ar("Wanted Board", 46.04, 47.76), "Read the wanted board: Otto and Lord Falconcrest hide in Stromgarde."),
    accept(657, quae, "Quae, at the farm east of Refuge Pointe, sends you to Kinelory."),
    finish(657, kinelory), accept(660, kinelory),
    objective(660, kinelory, "Protect Kinelory while she raids the Hammerfall supply. Let her pull ahead and stay close.", "Kinelory protected"),
    finish(660, quae), accept(661, quae, "Keep Quae's report for Phin Odelic in Southshore."),
    accept(642, ar("Shards of Myzrael", 62.5, 33.73), "Ride north to the glowing shards beside the Drywhisker Gorge path."),
    objective(642, ar(nil, 80.0, 35.0), "Kill Drywhisker kobolds in the gorge for Motes of Myzrael.", "12 Motes of Myzrael"),
    finish(642, shards, "Bring the motes to the Iridescent Shards deep in the gorge."), accept(651, shards),
    B.objectivePart(651, 2, ar("Stone of East Binding", 66.7, 29.7), "Take the Cresting Key from the Stone of East Binding, west of the gorge. Its guardian appears when you touch it.",
      "Cresting Key"),
    objective(691, ar(nil, 68.2, 79.5), "Ride south to Witherbark Village and loot tusks, medicine pouches and a Shadow Hunter Knife from the trolls.",
      "10 Witherbark Tusks", "4 Witherbark Medicine Pouches", "Shadow Hunter Knife"),
    B.objectivePart(651, 3, ar("Stone of Outer Binding", 52.0, 50.7), "Take the Thundering Key from the Stone of Outer Binding, northwest of the village on the way back.",
      "Thundering Key"),
    finish(691, kryten), accept(693, skuerto),
    objective(693, ar("Kor'gresh Coldrage", 54.8, 81.9), "Kor'gresh Coldrage, an ogre mage, holds Trelane's wand in the cave south of Witherbark.",
      "Trelane's Wand of Invocation"),
    finish(693, skuerto), accept(694, skuerto),
    action("goto", ar(nil, 25.5, 30.1), "Ride northwest past Northfold Manor."),
    B.objectivePart(651, 1, ar("Stone of West Binding", 25.5, 30.1), "Take the Burning Key from the Stone of West Binding.", "Burning Key"),
    objective(694, ar(nil, 20.2, 67.2), "Go south to the Boulderfist ogres near Stromgarde. A Boulderfist Shaman carries the Azure Agate.", "Azure Agate"),
    note(objective(685, ar(nil, 26.0, 65.7), "Otto and Lord Falconcrest hide in the Stromgarde ruins with the Syndicate. Bring a partner.",
      "Otto's Head", "Falconcrest's Head"), "Both may be guarded or elite; check in game."),
    finish(651, inner, "Bring the three keys to the Stone of Inner Binding on the hill east of Stromgarde."), accept(652, inner),
    note(objective(652, ar(nil, 40.0, 70.0), "Hunt down Fozruk, the giant that wanders the hills south of the stone, for the Rod of Order.", "Rod of Order"),
      "Fozruk walks a long path; check his level and route in game."),
    finish(652, keystone, "Place the rod at the Keystone beside the stone."), accept(653, keystone, "Keep the message for Gerrig Bonegrip in Ironforge."),
    accept(663, ar("Lolo the Lookout", 31.78, 82.68), "Follow the coast south to Faldir's Cove. Lolo watches from the cliff."),
    finish(663, obreen), accept(662, nilzlix), accept(664, steelgut), accept(665, ar("Professor Phizzlethorpe", 33.87, 80.55)),
    objective(665, ar(nil, 33.9, 80.4), "Escort Professor Phizzlethorpe to the cave on the shore and back. Fight off the surge elemental there.", "Phizzlethorpe escorted"),
    finish(665, draxlegauge), accept(666, draxlegauge),
    along(withItem(5996, objective(662, ar(nil, 22.5, 85.0),
      "Drink water breathing and dive to the two wrecks in the cove for their charts and logs.",
      "Maiden's Folly Charts", "Maiden's Folly Log", "Spirit of Silverpine Charts", "Spirit of Silverpine Log")), 664, 666),
    along(objective(664, ar(nil, 19.3, 84.1), "Kill Daggerspine Raiders and Sorceresses around the reef.", "10 Daggerspine Raiders", "3 Daggerspine Sorceresses"),
      662, 666),
    along(objective(666, ar(nil, 22.7, 88.6), "Wear the Goggles of Gem Hunting and gather Elven Gems from the clams on the reef.", "10 Elven Gems"), 662, 664),
    finish(662, nilzlix), finish(664, steelgut), finish(666, draxlegauge), accept(668, draxlegauge), finish(668, obreen),
    finish(694, kryten), accept(695, kryten), finish(695, skuerto), finish(685, nials),
    action("goto", hb(nil, 82.4, 39.6), "Ride west through Thoradin's Wall into Hillsbrad and on to Southshore."),
    finish(661, hb("Phin Odelic", 50.35, 59.05)),
    finish(1052, hb("Raleigh the Devout", 51.47, 58.35), "Raleigh the Devout stands near the inn."),
    forDungeon(accept(1053, hb("Raleigh the Devout", 51.47, 58.35), "Raleigh's next task is in the Scarlet Monastery: its four leaders."),
      "dungeon-scarlet-monastery-cathedral"),
    finish(525, maleb), accept(537, maleb), accept(512, maleb),
    accept(500, redpath), accept(540, dibbs),
    action("sethearth", anderson, "Bind at the Southshore inn.", southshore),
    finish(602, al("Archmage Ansirem Runeweaver", 14.2, 59.7), "Ride north and west into Alterac to Archmage Ansirem at Dalaran's walls."),
    along(objective(543, al(nil, 40.4, 47.1), "Ride east to the Ruins of Alterac. The Perenolde Tiara is in a chest inside the ruined keep.", "Perenolde Tiara"), 540),
    along(objective(540, al(nil, 38.4, 46.4), "Pick up Recovered Tomes from the Syndicate and ogres in the ruins. The Worn Leather Book is in the keep.",
      "5 Recovered Tomes", "Worn Leather Book"), 543, 500),
    along(objective(500, al(nil, 48.5, 40.7), "Kill Crushridge ogres east of the ruins for Dirty Knucklebones.", "9 Dirty Knucklebones"), 540),
    along(objective(512, al(nil, 58.7, 30.5), "Go north to the Syndicate camp at Misty Shore and loot Alterac Signet Rings.", "7 Alterac Signet Rings"), 537),
    along(objective(537, al(nil, 58.7, 30.5), "Kill the Argus Shadow Mages there.", "4 Argus Shadow Mages"), 512),
    withItem(3706, accept(551, nil, "If the Ensorcelled Parchment dropped, read it.")),
    objective(537, al("Nagaz", 39.2, 14.3), "Nagaz leads the Syndicate in the tower at the lake's north end. Kill him for his head.", "Head of Nagaz"),
    action("goto", hb(nil, 86.4, 32.0), "Ride back down through Hillsbrad and take the northeast pass into the Hinterlands."),
    finish(1449, falstad, "Climb up to Aerie Peak and find High Thane Falstad Wildhammer."), accept(1450, falstad),
    taxi("getfp", on.hinterlands("Guthrum Thunderfist", 11.1, 46.2), "Aerie Peak, The Hinterlands", "Learn the Aerie Peak flight path."),
    finish(1450, on.hinterlands("Gryphon Master Talonaxe", 9.75, 44.47), "Gryphon Master Talonaxe is inside the aviary."),
    accept(1451, on.hinterlands("Gryphon Master Talonaxe", 9.75, 44.47)),
    finish(1451, on.hinterlands("Rhapsody Shindigger", 26.94, 48.59), "Follow the road east to Rhapsody Shindigger's camp. His kocktail needs Kalimdor beasts: save it for later."),
    action("hearth", anderson, "Hearth to Southshore.", southshore),
    finish(500, redpath), finish(512, maleb), finish(537, maleb),
    finish(551, dibbs), accept(554, dibbs), finish(540, dibbs), accept(542, dibbs),
    taxi("fly", hb("Darla Harris", 49.34, 52.27), "Ironforge, Dun Morogh", "Fly to Ironforge."),
    finish(554, ifg("Prospector Stormpike", 74.64, 11.74)),
    forDungeon(accept(1050, ifg("Librarian Mae Paledust", 74.97, 12.48), "Librarian Mae Paledust, beside Stormpike, wants a book from the Scarlet Monastery library."),
      "dungeon-scarlet-monastery-library"),
    finish(653, ifg("Gerrig Bonegrip", 50.83, 5.62), "Gerrig Bonegrip is in the Forlorn Cavern."),
    action("goto", nil, "Take the Deeprun Tram to Stormwind. Use Next when you arrive."),
    finish(543, at("Count Remington Ridgewell", 76.94, 47.83, M.stormwind)),
    finish(542, at("Milton Sheaf", 77.07, 30.21, M.stormwind)),
  }, { suggest = { "riverglades-farholde", "riverglades-shroud" } })
end

-- Dustwallow at 40: Morgan Stern's soup, Swamp Eye Jarl, Stinky and Mudcrush, then the Razorfen Downs camp.
do
  local dm = on.dustwallow
  local stern = dm("Morgan Stern", 66.34, 45.47)
  local jarl = dm("\"Swamp Eye\" Jarl", 55.44, 26.27)
  local mudcrush = dm("Mudcrush Durtfeet", 35.15, 38.26)
  local janene = dm("Innkeeper Janene", 66.6, 45.2)
  local myriam = on.barrens("Myriam Moonsinger", 49.01, 94.94)
  local rfd = "dungeon-razorfen-downs"

  q(1204, "Mudrock Soup and Bugs", 38, 33, 1260)
  q(1206, "Jarl Needs Eyes", 35, 30, 1218)
  q(1222, "Stinky's Escape", 37, 30)
  q(1177, "Hungry!", 36, 32)
  q(6626, "A Host of Evil", 35, 28)
  q(3636, "Bring the Light", 42, 39)

  section("dustwallow-40", "Dustwallow Marsh and Razorfen Downs", M.dustwallow, 40, 41, {
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    forDungeon(accept(3636, at("Archbishop Benedictus", 50.31, 45.47, M.stormwind),
      "Archbishop Benedictus, in the Cathedral of Light, wants Amnennar the Coldbringer of Razorfen Downs destroyed. Take it now if you might run the dungeon: it is only offered here."), rfd),
    taxi("fly", at("Dungar Longdrink", 71.3, 72.2, M.stormwind), "Menethil Harbor, Wetlands", "Fly to Menethil Harbor."),
    action("boat", on.wetlands(nil, 5.1, 63.4), "Take the Theramore ship from Menethil's south pier. Use Next when it docks.",
      { name = "Menethil Harbor - Theramore Isle" }),
    action("sethearth", janene, "Bind at the Theramore inn.", { bind = "Theramore Isle" }),
    finish(1260, stern, "Morgan Stern runs the inn's kitchen."), accept(1204, stern),
    accept(1206, jarl, "Ride north to Swamp Eye Jarl's shack again."),
    accept(1177, mudcrush, "Follow the road west to Mudcrush Durtfeet, a friendly ogre by the road."),
    objective(1206, dm(nil, 34.5, 22.1), "Kill Darkmist spiders in the northwest for unpopped eyes.", "20 Unpopped Darkmist Eyes"),
    accept(1222, dm("\"Stinky\" Ignatz", 46.88, 17.52), "\"Stinky\" Ignatz is gathering in the northern bog."),
    objective(1222, dm(nil, 48.8, 24.5), "Escort Stinky while he gathers. Fight off the attackers.", "Stinky escorted"),
    along(objective(1204, dm(nil, 60.2, 17.0), "Kill Mudrock turtles along the north shore for forked tongues.", "8 Forked Mudrock Tongues"), 1177),
    along(objective(1177, dm(nil, 57.0, 13.0), "Kill Mirefin murlocs on the same shore for their heads.", "8 Mirefin Heads"), 1204),
    finish(1206, jarl),
    action("hearth", janene, "Hearth to Theramore.", { bind = "Theramore Isle" }),
    finish(1204, stern), finish(1222, stern),
    action("goto", mudcrush, "Ride west along the road toward the Barrens."),
    finish(1177, mudcrush, "Hand Mudcrush his murloc heads on the way past."),
    action("goto", myriam, "Take the road into the Barrens and ride south past Camp Taurajo's outskirts to the thorny mounds of Razorfen Downs."),
    accept(6626, myriam, "Myriam Moonsinger waits outside Razorfen Downs."),
    objective(6626, on.barrens(nil, 48.2, 92.3), "Kill Razorfen Battleguards, Thornweavers and Death's Head Cultists around the dungeon's entrance.",
      "8 Razorfen Battleguards", "8 Razorfen Thornweavers", "8 Death's Head Cultists"),
    finish(6626, myriam),
  }, { suggest = { "riverglades-shroud" } })
end

-- 30-35 alternates: an early Stranglethorn run from Duskwood, and Theramore on its own.
do
  local st, dm = on.stv, on.dustwallow
  local yohwa = st("Sergeant Yohwa", 38.02, 3.33)
  local doren = st("Lieutenant Doren", 38.04, 3.01)
  local nimetz = st("Brother Nimetz", 37.83, 3.56)
  local hemet = st("Hemet Nesingwary", 35.66, 10.81)
  local ajeck = st("Ajeck Rouack", 35.62, 10.62)
  local erlgadin = st("Sir S. J. Erlgadin", 35.55, 10.55)
  local kurzen = st(nil, 44.9, 10.2)
  local darkshire = { bind = "Darkshire" }

  section("stv-30", "Stranglethorn Early: Rebel Camp and Nesingwary", M.stv, 30, 35, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("sethearth", on.duskwood("Innkeeper Trelayne", 73.9, 44.4), "Bind in Darkshire. This run starts and ends there.", darkshire),
    accept(215, st("Private Thorsen", 40.3, 8.4), "Take the road south out of Duskwood into Stranglethorn. Private Thorsen sometimes patrols the road below the Rebel Camp: take his note if you see him."),
    action("goto", st(nil, 38.0, 3.5), "Climb to the Rebel Camp."),
    finish(215, doren), accept(203, yohwa), accept(204, yohwa), accept(200, doren),
    accept(583, st("Barnil Stonepot", 35.7, 10.8), "Walk down to Nesingwary's Expedition."),
    finish(583, hemet), accept(185, ajeck), accept(190, erlgadin), accept(194, hemet),
    along(objective(185, st(nil, 35.4, 12.5), "Hunt Young Stranglethorn Tigers around the camp.", "10 Young Stranglethorn Tigers"), 190),
    along(objective(190, st(nil, 41.5, 12.0), "Young Panthers prowl east of the camp, across the road.", "10 Young Panthers"), 185),
    finish(185, ajeck), finish(190, erlgadin), accept(186, ajeck), accept(191, erlgadin),
    along(objective(203, kurzen, "Go east to the Kurzen compound and clear the Jungle Fighters.", "15 Kurzen Jungle Fighters"), 204, 200),
    along(objective(204, kurzen, "Medicine Men carry Jungle Remedies. The Venom Fern Extract is in a chest in the back cave.",
      "7 Jungle Remedy", "Venom Fern Extract"), 203, 200),
    finish(200, st("Bookie Herod's Records", 43.67, 9.37), "Read Bookie Herod's records in the compound."),
    accept(328, st("Bookie Herod's Records", 43.67, 9.37)),
    finish(328, st("Bookie Herod's Strongbox", 49.62, 7.56), "Open the strongbox east of the compound."),
    accept(329, st("Bookie Herod's Strongbox", 49.62, 7.56)),
    objective(186, st(nil, 46.7, 15.8), "Hunt Stranglethorn Tigers in the jungle south of the compound.", "10 Stranglethorn Tigers"),
    finish(203, yohwa), finish(204, yohwa), finish(329, doren), accept(330, doren),
    finish(330, st("Corporal Sethman", 37.66, 3.39)), accept(331, st("Corporal Sethman", 37.66, 3.39)), finish(331, doren),
    accept(207, nimetz, "Brother Nimetz has the troll tablets for later. Keep the quest for your next Stranglethorn visit."),
    finish(186, ajeck), accept(187, ajeck),
    along(objective(191, st(nil, 29.8, 11.2), "Panthers prowl the jungle west of the camp.", "10 Panthers"), 187, 194),
    along(objective(187, st(nil, 31.9, 19.9), "Elder Stranglethorn Tigers live farther south and west.", "10 Elder Stranglethorn Tigers"), 191, 194),
    along(objective(194, st(nil, 27.2, 16.1), "Stranglethorn Raptors hunt near the western coast.", "10 Stranglethorn Raptors"), 191, 187),
    finish(191, erlgadin), finish(187, ajeck), finish(194, hemet),
    action("hearth", on.duskwood("Innkeeper Trelayne", 73.9, 44.4), "Hearth to Darkshire.", darkshire),
  }, { alternate = true, suggest = { "needles-33", "theramore-33" } })

  local vimes = dm("Captain Garran Vimes", 68.21, 48.62)
  local tesoran = dm("Adjutant Tesoran", 68.05, 48.11)
  local jarl = dm("\"Swamp Eye\" Jarl", 55.44, 26.27)
  local janene = dm("Innkeeper Janene", 66.6, 45.2)
  local theramore = { bind = "Theramore Isle" }
  q(1252, "Lieutenant Paval Reethe", 40, 30)
  q(1259, "Lieutenant Paval Reethe", 40, 30, 1252)
  q(1285, "Daelin's Men", 38, 30, 1259)
  q(1286, "The Deserters", 38, 30, 1285)
  q(1287, "The Deserters", 38, 30, 1286)

  section("theramore-33", "Dustwallow: Theramore and the Marsh", M.dustwallow, 33, 37, {
    "https://www.wowhead.com/forever/zone=15/dustwallow-marsh",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("boat", on.wetlands(nil, 5.1, 63.4), "Take the Theramore ship from Menethil's south pier. Use Next when it docks.",
      { name = "Menethil Harbor - Theramore Isle" }),
    taxi("getfp", dm("Baldruc", 67.5, 51.3), "Theramore, Dustwallow Marsh", "Learn the Theramore flight path from Baldruc by the docks."),
    action("sethearth", janene, "Bind at the Theramore inn.", theramore),
    accept(1282, dm("Guard Byron", 66.15, 46.07), "Guard Byron by the inn has a message for Captain Vimes."),
    finish(1282, vimes, "Captain Vimes is on the citadel's top floor."),
    action("buy", dm("Helenia Olden", 66.4, 51.5), "Buy 3 Soothing Spices from Helenia Olden by the docks for Swamp Eye Jarl."),
    accept(1218, jarl, "Ride north to Swamp Eye Jarl's shack and hand him the spices."), finish(1218, jarl),
    accept(1206, jarl), accept(1219, dm("Loose Dirt", 55.44, 25.92), "Search the loose dirt beside the shack."),
    accept(1222, dm("\"Stinky\" Ignatz", 46.88, 17.52), "\"Stinky\" Ignatz gathers in the northern bog."),
    objective(1222, dm(nil, 48.8, 24.5), "Escort Stinky while he gathers.", "Stinky escorted"),
    objective(1206, dm(nil, 34.5, 22.1), "Kill Darkmist spiders in the northwest for unpopped eyes.", "20 Unpopped Darkmist Eyes"),
    accept(1177, dm("Mudcrush Durtfeet", 35.15, 38.26), "Ride south to Mudcrush Durtfeet by the road."),
    action("goto", dm("Shady Rest Inn", 29.7, 47.8), "Follow the road southwest to the burned Shady Rest Inn."),
    accept(1284, dm("Suspicious Hoofprint", 29.7, 47.64)), accept(1252, dm("Theramore Guard Badge", 29.83, 48.24)),
    accept(1253, dm("Black Shield", 29.63, 48.62)),
    objective(1177, dm(nil, 57.0, 13.0), "Ride to the north shore and kill Mirefin murlocs for their heads.", "8 Mirefin Heads"),
    finish(1206, jarl),
    action("hearth", janene, "Hearth to Theramore.", theramore),
    finish(1222, dm("Morgan Stern", 66.34, 45.47), "Stinky's escape ends with Morgan Stern in the inn's kitchen."),
    finish(1219, dm("Theramore Lieutenant", 67.07, 53.22)), accept(1220, dm("Theramore Lieutenant", 67.07, 53.22)),
    finish(1220, vimes), finish(1284, vimes), finish(1252, vimes), accept(1259, vimes),
    finish(1259, tesoran), accept(1285, tesoran), finish(1285, vimes), accept(1286, vimes),
    finish(1253, vimes), accept(1319, vimes),
    finish(1319, dm("Caz Twosprocket", 64.75, 50.43)), accept(1320, dm("Caz Twosprocket", 64.75, 50.43)), finish(1320, vimes),
    action("goto", dm("Balos Jacken", 36.09, 54.31), "Ride back west past the Shady Rest to Balos Jacken's camp."),
    finish(1286, dm("Balos Jacken", 36.09, 54.31)), accept(1287, dm("Balos Jacken", 36.09, 54.31)),
    finish(1177, dm("Mudcrush Durtfeet", 35.15, 38.26), "Hand Mudcrush his heads on the way back."),
    action("hearth", janene, "Hearth or ride back to Theramore.", theramore),
    finish(1287, vimes),
  }, { alternate = true, suggest = { "desolace-35", "stv-36", "riverglades-farholde" } })
end
