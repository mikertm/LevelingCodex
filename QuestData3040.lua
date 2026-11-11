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
  })
end
