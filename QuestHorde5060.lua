-- Horde route, levels 50-60. Source notes: tools/audits/2026-11-12-horde-50-60.md.
-- Helpers: B.horde (QuestHorde3040.lua) and the shared build helpers in QuestData.lua.
local B = LevelingCodexQuests.build
local H = B.horde

-- Main chapters run through H.chapter: a hand-in for a quest the 40-50 chapters give you stays
-- optional until that file is merged. Alternates (end of file) copy steps from the main chapters.
local M, on, quest = B.maps, B.on, B.quest
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, part, withItem, along, note = B.objectiveAt, B.objectivePart, B.withItem, B.along, B.note
local need = H.need

local F = {
  ratchet = "Ratchet, The Barrens", stonard = "Stonard, Swamp of Sorrows", kargath = "Kargath, Badlands",
  thorium = "Thorium Point, Searing Gorge", flameCrest = "Flame Crest, Burning Steppes",
  gromgol = "Grom'gol, Stranglethorn", orgrimmar = "Orgrimmar, Durotar", splintertree = "Splintertree Post, Ashenvale",
  valormok = "Valormok, Azshara", bloodvenom = "Bloodvenom Post, Felwood", everlook = "Everlook, Winterspring",
  gadgetzan = "Gadgetzan, Tanaris", marshal = "Marshal's Refuge, Un'Goro Crater", mojache = "Camp Mojache, Feralas",
  bluff = "Thunder Bluff, Mulgore", undercity = "Undercity, Tirisfal", lightsHope = "Light's Hope Chapel, Eastern Plaguelands",
  moonglade = "Moonglade", cenarion = "Cenarion Hold, Silithus",
}

-- Places shared by the chapters and the alternates (QuestieDB Forever spawn points).
local P = {}
do
  local stv, sw, bl, bad, sg, bs = on.stv, on.swamp, on.blasted, on.badlands, on.searing, on.steppes
  local og, tb, uc, tir, bar, fer = on.orgrimmar, on.thunderBluff, on.undercity, on.tirisfal, on.barrens, on.feralas
  local az, fw, ws, ug, tan, sil, mg, wpl, epl = on.azshara, on.felwood, on.winterspring, on.ungoro, on.tanaris,
    on.silithus, on.moonglade, on.wpl, on.epl
  -- Flight masters and innkeepers.
  P.shyn, P.bragok, P.gringer, P.breyk = fer("Shyn", 75.45, 44.36), bar("Bragok", 63.08, 37.16),
    stv("Gringer", 26.87, 77.10), sw("Breyk", 46.07, 54.83)
  P.gorrik, P.grisha, P.vahgruk, P.doras = bad("Gorrik", 3.99, 44.78), sg("Grisha", 34.84, 30.87),
    bs("Vahgruk", 65.69, 24.22), og("Doras", 45.12, 63.89)
  P.kroum, P.brakkar, P.yugrek, P.bulkrek = az("Kroum", 21.96, 49.62), fw("Brakkar", 34.44, 53.96),
    ws("Yugrek", 60.47, 36.30), tan("Bulkrek Ragefist", 51.60, 25.44)
  P.gryfe, P.tal, P.garrett, P.georgia = ug("Gryfe", 45.23, 5.83), tb("Tal", 47.00, 49.83),
    uc("Michael Garrett", 63.25, 48.56), epl("Georgia", 70.53, 47.55)
  P.faustron, P.runk = mg("Faustron", 32.09, 66.61), sil("Runk Windtamer", 48.68, 36.67)
  P.gryshka, P.vizzie = og("Innkeeper Gryshka", 54.10, 68.41), ws("Innkeeper Vizzie", 61.36, 38.83)
  P.nezraz, P.durotarTower = stv("Nez'raz", 31.4, 29.9), on.durotar(nil, 50.8, 13.8)
  -- Booty Bay, Stonard and the Blasted Lands.
  P.liv, P.islen = bar("Liv Rizzlefix", 62.45, 38.73), bar("Islen Waterseer", 65.83, 43.78)
  P.smotts, P.sprogger = stv("Captain Hecklebury Smotts", 26.69, 73.61), stv("Sprogger", 26.66, 73.64)
  P.oglethorpe, P.poobah = stv("Oglethorpe Obnoticus", 28.36, 76.35), stv("Princess Poobah", 38.53, 80.58)
  P.felzerul = sw("Fel'zerul", 47.93, 54.78)
  P.lynnore, P.drazial = bl("Bloodmage Lynnore", 50.64, 14.3), bl("Bloodmage Drazial", 50.55, 14.2)
  P.kumisha = bl("Kum'isha the Collector", 51.98, 35.65)
  -- Kargath, the Searing Gorge and the Burning Steppes.
  P.thaltrak, P.thunderheart = bad("Thal'trak Proudtusk", 3.36, 48.06), bad("Thunderheart", 3.33, 48.26)
  P.kalaran, P.maltrake = sg("Kalaran Windblade", 39.1, 39.0), sg("Squire Maltrake", 39.17, 39.0)
  P.hansel, P.burninate = sg("Hansel Heavyhands", 38.58, 27.81), sg("Master Smith Burninate", 38.8, 28.51)
  P.scrange, P.lolo = sg("Taskmaster Scrange", 38.97, 27.51), sg("Lookout Captain Lolo Longstriker", 37.74, 26.56)
  P.notice, P.outhouse = sg("Wanted/Missing/Lost & Found", 37.65, 26.47), sg("Wooden Outhouse", 65.59, 62.17)
  P.torch, P.hoard = sg("Torch of Retribution", 39.06, 39.07), sg("Hoard of the Black Dragonflight", 38.85, 38.99)
  P.tinkee, P.maxwort = bs("Tinkee Steamboil", 65.24, 24.0), bs("Maxwort Uberglint", 65.15, 23.91)
  P.cyrus, P.shani = bs("Cyrus Therepentous", 95.09, 31.56), bs("Sha'ni Proudtusk's Remains", 79.79, 45.53)
  -- Orgrimmar, Thunder Bluff and the Undercity.
  P.dran, P.jesrimon = og("Dran Droffers", 59.49, 36.57), og("Jes'rimon", 55.52, 34.08)
  P.belgrom, P.zilzibin = og("Belgrom Rockmaul", 75.23, 34.24), og("Zilzibin Drumlore", 56.26, 46.68)
  P.karus = og("Karus", 49.58, 69.12)
  P.windstrider, P.pala = tb("Bluff Runner Windstrider", 44.33, 58.76), tb("Innkeeper Pala", 45.81, 64.71)
  P.hamuul, P.ghede = tb("Arch Druid Hamuul Runetotem", 78.62, 28.56), tb("Ghede", 77.46, 21.97)
  P.bashana, P.magatha = tb("Bashana Runetotem", 71.06, 34.19), tb("Magatha Grimtotem", 69.85, 30.91)
  P.nara = tb("Nara Wildmane", 75.65, 31.61)
  P.balthazad, P.bauhaus = uc("Harbinger Balthazad", 63.90, 44.08), uc("Royal Overseer Bauhaus", 69.79, 43.16)
  P.payson, P.cuely = uc("Jeremiah Payson", 67.60, 44.16), uc("Chemist Cuely", 48.71, 71.39)
  P.thersa, P.andron = uc("Thersa Windsong", 49.04, 70.80), uc("Andron Gant", 54.81, 76.33)
  P.sylvanas = uc("Lady Sylvanas Windrunner", 58.05, 91.79)
  -- Azshara.
  P.lohatu, P.agtor = az("Loh'atu", 11.37, 78.17), az("Ag'tor Bloodfist", 22.26, 51.48)
  P.jediga, P.xylem = az("Jediga", 22.56, 51.42), az("Archmage Xylem", 29.25, 40.21)
  P.sanath, P.kimjael = az("Sanath Lim-yo", 28.1, 50.1), az("Kim'jael", 53.45, 21.82)
  P.tome, P.crystal = az("Kaldorei Tome of Summoning", 59.51, 31.30), az("Arcane Focusing Crystal", 59.59, 31.32)
  -- Felwood and Winterspring.
  P.grazle, P.greta = fw("Grazle", 50.93, 85.01), fw("Greta Mosshoof", 51.21, 82.11)
  P.taronn, P.maybess = fw("Taronn Redfeather", 50.89, 81.62), fw("Maybess Riverbreeze", 46.75, 83.13)
  P.eridan, P.jessir = fw("Eridan Bluewind", 51.35, 81.51), fw("Jessir Moonbow", 51.35, 82.01)
  P.kelek = fw("Kelek Skykeeper", 51.14, 81.75)
  P.winna, P.dreka = fw("Winna Hazzard", 34.21, 52.34), fw("Dreka'Sur", 34.80, 52.73)
  P.trull, P.nafien = fw("Trull Failbane", 34.73, 52.79), fw("Nafien", 64.77, 8.13)
  P.kernda, P.cauldron = fw("Kernda", 65.50, 3.52), fw("Deadwood Cauldron", 60.20, 5.84)
  P.arko = fw("Captured Arko'narin", 36.21, 55.47)
  P.jadefireWell, P.jaedenarWell = fw("Moonwell", 32.35, 66.54), fw("Moonwell", 35.15, 59.79)
  P.donova, P.salfa = ws("Donova Snowden", 31.27, 45.16), ws("Salfa", 27.73, 34.50)
  P.felnok, P.meggi = ws("Felnok Steelspring", 61.63, 38.61), ws("Meggi Peppinrocker", 60.66, 38.17)
  P.umi, P.storm = ws("Umi Rumplesnicker", 60.88, 37.62), ws("Storm Shadowhoof", 61.93, 38.38)
  P.gregor, P.jessica = ws("Gregor Greystone", 61.35, 38.97), ws("Jessica Redpath", 61.28, 38.98)
  P.legacki = ws("Legacki", 61.54, 38.61)
  -- Tanaris, Un'Goro and Feralas.
  P.pestlezugg, P.tranrek = tan("Alchemist Pestlezugg", 50.89, 26.96), tan("Tran'rek", 51.57, 26.76)
  P.sprinkle, P.marvon = tan("Sprinkle", 51.06, 26.87), tan("Marvon Rivetseeker", 52.71, 45.92)
  P.gaeriyan, P.gravestone = tan("Gaeriyan", 53.92, 23.33), tan("A Conspicuous Gravestone", 53.81, 29.06)
  P.holanyee, P.williden = ug("Hol'anyee Marshal", 43.89, 7.24), ug("Williden Marshal", 43.95, 7.14)
  P.spark, P.collie = ug("Spark Nilminer", 43.50, 7.42), ug("J.D. Collie", 41.92, 2.70)
  P.spraggle, P.shizzle = ug("Spraggle Frock", 43.62, 8.50), ug("Shizzle", 44.23, 11.59)
  P.larion, P.karna = ug("Larion", 45.54, 8.72), ug("Karna Remtravel", 46.38, 13.44)
  P.linken, P.quixxil = ug("Linken", 44.66, 8.10), ug("Quixxil", 43.66, 9.37)
  P.krakle, P.ringo = ug("Krakle", 30.93, 50.44), ug("Ringo", 51.90, 49.85)
  P.torwa, P.ame = ug("Torwa Pathfinder", 71.64, 75.96), ug("A-Me 01", 67.66, 16.76)
  P.pterrordaxSign = ug("Beware of Pterrordax", 43.53, 8.44)
  P.talo, P.gregan = fer("Talo Thornhoof", 76.2, 43.8), fer("Gregan Brewspewer", 45.12, 25.57)
  -- The Plaguelands (the Bulwark stands on the Tirisfal map).
  P.derrington, P.garush = tir("High Executor Derrington", 83.13, 68.94), tir("Argent Officer Garush", 83.19, 68.45)
  P.mickey, P.vandis = tir("Mickey Levine", 83.29, 72.34), tir("Shadow Priestess Vandis", 83.04, 71.91)
  P.dithers = tir("Apothecary Dithers", 83.28, 69.23)
  P.janice, P.parcel = wpl("Janice Felstone", 38.40, 54.05), wpl("Janice's Parcel", 38.73, 55.24)
  P.felstoneCauldron, P.dalsonCauldron = wpl("Scourge Cauldron", 37.25, 56.78), wpl("Scourge Cauldron", 46.18, 51.90)
  P.haunt, P.gahrron = wpl("Scourge Cauldron", 53.02, 65.61), wpl("Scourge Cauldron", 62.54, 58.47)
  P.diary, P.cabinet = wpl("Mrs. Dalson's Diary", 47.80, 50.67), wpl("Locked Cabinet", 47.35, 49.63)
  P.chromie, P.mulgris = wpl("Chromie", 39.46, 66.76), wpl("Mulgris Deepriver", 53.73, 64.66)
  P.kirsta, P.marlene = wpl("Kirsta Deepshadow", 51.92, 28.06), wpl("Marlene Redpath", 49.17, 78.57)
  P.barrel, P.renfray = wpl("Termite Barrel", 48.34, 31.99), wpl("Artist Renfray", 65.77, 75.37)
  P.tirion, P.nathanos = epl("Tirion Fordring", 5.16, 35.57), epl("Nathanos Blightcaller", 22.23, 63.51)
  P.pamela, P.carlin = epl("Pamela Redpath", 31.15, 77.98), epl("Carlin Redpath", 71.70, 50.04)
  P.zverenhoff, P.alen = epl("Duke Nicholas Zverenhoff", 71.63, 50.09), epl("Caretaker Alen", 69.93, 53.72)
  P.egan, P.augustus = epl("Egan", 11.36, 26.60), epl("Augustus the Touched", 11.36, 26.37)
  P.scroll, P.mound = epl("Torn Scroll", 22.90, 72.96), epl("Mound of Dirt", 23.58, 73.79)
  -- Moonglade and Silithus.
  P.rabine, P.umber = mg("Rabine Saturna", 51.69, 45.10), mg("Umber", 44.88, 35.60)
  P.layo, P.beetix = sil("Layo Starstrike", 81.87, 18.93), sil("Beetix Ficklespragg", 51.61, 38.63)
  P.noggle, P.proudhorn = sil("Noggle Ficklespragg", 51.63, 38.50), sil("Windcaller Proudhorn", 51.15, 38.29)
  P.larksbane, P.maralith = sil("Geologist Larksbane", 49.67, 37.46), sil("Commander Mar'alith", 49.20, 34.18)
  P.bor, P.ortell = sil("Bor Wildmane", 48.57, 37.78), sil("Hermit Ortell", 67.19, 69.76)
  P.vish, P.poster = sil("Vish Kozus", 50.75, 33.65), sil("Wanted Poster: Deathclasp", 51.35, 38.27)
  P.rutgar, P.frankal = sil("Rutgar Glyphshaper", 41.28, 88.45), sil("Frankal Stonebridge", 40.81, 88.86)
end

local ORGRIMMAR_BIND, EVERLOOK_BIND = { bind = "Orgrimmar" }, { bind = "Everlook" }
local QUESTIE = "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever"

-- QuestieDB lists two possible prerequisites for some quests (one per faction or per giver):
-- the step names the one this route gives you.
local function pre(step, ...)
  step.chain = { ... }
  return step
end

-- A travel step for a carried chain: shown only while that quest is in your log.
local function onQuest(step, id)
  step.ifOnQuest = id
  return step
end

-- Roads and zeppelins the arrow uses between this band's maps.
do
  local road = H.road
  road(M.blasted, M.swamp, on.blasted(nil, 52.7, 3.1), "Ride north along the road into the Swamp of Sorrows")
  road(M.winterspring, M.felwood, on.winterspring(nil, 27.8, 34.6), "Go back through Timbermaw Hold into Felwood")
  road(M.felwood, M.moonglade, on.felwood(nil, 64.6, 8.2), "Go through Timbermaw Hold and take the Moonglade tunnel")
  road(M.winterspring, M.moonglade, on.winterspring(nil, 27.8, 34.6), "Go into Timbermaw Hold and take the Moonglade tunnel")
  road(M.moonglade, M.felwood, on.moonglade(nil, 35.8, 71.9), "Take the tunnel back through Timbermaw Hold into Felwood")
  road(M.tirisfal, M.wpl, on.tirisfal(nil, 83.0, 70.0), "Ride east past the Bulwark into the Western Plaguelands")
  road(M.wpl, M.tirisfal, on.wpl(nil, 26.5, 56.0), "Ride west to the Bulwark")
  road(M.epl, M.wpl, on.epl(nil, 5.2, 36.0), "Ride west along the road into the Western Plaguelands")
  road(M.silithus, M.ungoro, on.silithus(nil, 88.9, 24.0), "Take the ramp east of Valor's Rest down into Un'Goro Crater")
  road(M.ungoro, M.tanaris, on.ungoro(nil, 71.6, 76.0), "Leave Un'Goro by the south-east path into Tanaris")
end

-- Main chapters keep their original step lists here for the alternates at the end.
local mainSteps = {}
local function chapter(id, title, zone, low, high, sources, suggest, steps)
  mainSteps[id] = steps
  return H.chapter(id, title, zone, low, high, sources, suggest, steps)
end

-- 50-51: Booty Bay errands, Stonard and the Nethergarde bloodmages.
do
  local stv, bl = on.stv, on.blasted
  need(4502, "Volcanic Activity", 55, 49)
  need(2874, "Deliver to MacKinley", 45, 40, 2873)
  need(580, "Whiskey Slim's Lost Grog", 50, 40)
  need(1122, "Report Back to Fizzlebub", 44, 35, 1120)
  need(2767, "Rescue OOX-22/FE!", 45, 40, 2766)
  need(648, "Rescue OOX-17/TN!", 48, 43, 351)
  need(836, "Rescue OOX-09/HL!", 48, 43, 485)
  need(3721, "An OOX of Your Own", 50, 45, { 648, 836, 2767 })
  need(8552, "The Monogrammed Sash", 50, 40)
  quest[8552].startItem = 3985
  need(8553, "The Captain's Cutlass", 50, 40, 8552)
  need(8554, "Facing Negolash", 50, 40, 8553)
  need(594, "Message in a Bottle", 45, 45)
  quest[594].startItem = 4098
  need(630, "Message in a Bottle", 51, 45, 594)
  need(1444, "Return to Fel'Zerul", 44, 38, 1429)
  need(1445, "The Temple of Atal'Hakkar", 50, 38, 1444)
  need(2601, "The Basilisk's Bite", 50, 45)
  need(2603, "Vulture's Vigor", 50, 45)
  need(2585, "The Decisive Striker", 50, 45)
  need(2583, "A Boar's Vitality", 50, 45)
  need(2581, "Snickerfang Jowls", 50, 45)
  need(3501, "Everything Counts In Large Amounts", 55, 45)
  need(2521, "To Serve Kum'isha", 55, 45)

  chapter("blasted-50", "Booty Bay, Stonard and the Blasted Lands", M.stv, 50, 51, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    "https://www.wowhead.com/forever/zone=4/blasted-lands",
    QUESTIE,
  }, { "searing-alt", "azshara-alt" }, {
    taxi("fly", P.shyn, F.ratchet, "Fly from Camp Mojache to Ratchet."),
    accept(4502, P.liv, "Liv Rizzlefix, beside the Ratchet bank, wants ash from Un'Goro's fire elementals. Keep it for the crater."),
    action("boat", on.barrens(nil, 63.7, 38.6), "Take the boat at the end of Ratchet's dock to Booty Bay. Use Next when you arrive.",
      { name = "Ratchet - Booty Bay" }),
    finish(2874, stv("\"Sea Wolf\" MacKinley", 27.78, 77.07), "If you carried Stoley's bottle from Tanaris, hand it to MacKinley on the harbour walkway."),
    finish(580, stv("Whiskey Slim", 27.14, 77.45), "Whiskey Slim sits upstairs in the inn. Give him his port if you found it."),
    finish(1122, stv("Crank Fizzlebub", 27.12, 77.21), "Report to Crank Fizzlebub if you still carry the Fool's Stout report."),
    finish(648, P.oglethorpe, "Oglethorpe Obnoticus has a hut on the pier past the bank. Report any robot you walked home."),
    finish(836, P.oglethorpe),
    accept(3721, P.oglethorpe, "With all three robots safe, Oglethorpe gives you a mechanical chicken of your own."),
    finish(3721, P.oglethorpe),
    withItem(3985, accept(8552, stv(nil, 27.1, 83.1), "Bloodsail pirates on the beaches south of town can drop a Monogrammed Sash. Use it from your bags if you have one.")),
    finish(8552, P.smotts, "Captain Smotts waits on the wooden walkway inside the tunnel into town."),
    accept(8553, P.smotts), finish(8553, P.sprogger, "Sprogger stands right beside him."),
    accept(8554, P.sprogger, "Sprogger knows who took the captain's cutlass: the naga Negolash, out at the old lifeboat."),
    note(onQuest(action("buy", stv("Nixxrax Fillamug", 27.04, 77.17),
      "Buy 10 Barbecued Buzzard Wings and 5 Junglevine Wine from Nixxrax Fillamug at the inn. They are the bait for Negolash.",
      { item = 4457, count = 10 }), 8554), "Vendor not confirmed in the quest data; check in game."),
    objective(8554, stv("Ruined Lifeboat", 32.48, 81.98),
      "Swim east to the ruined lifeboat on the shore. Set out the wings and wine to call Negolash, then kill him for Smotts' Cutlass.",
      "Smotts' Cutlass"),
    withItem(4098, accept(594, stv(nil, 32.5, 82.0), "Bottles wash up on these beaches. If you found a Message in a Bottle, use it from your bags.")),
    finish(594, P.poobah, "Princess Poobah sits in a cage on Jaguero Isle, east across the water."),
    accept(630, P.poobah),
    objective(630, stv("King Mukla", 40.95, 83.9), "Clear the gorillas on the isle until King Mukla stands alone, then kill him for the Shackle Key.",
      "Shackle Key"),
    finish(630, P.poobah),
    finish(8554, P.smotts, "Swim back to Booty Bay and give Captain Smotts his cutlass."),
    taxi("fly", P.gringer, F.stonard, "Fly to Stonard in the Swamp of Sorrows."),
    finish(1444, P.felzerul, "Fel'zerul stands in the great hall of Stonard. Report the Atal'ai Exile's words if you carry them."),
    H.dungeon("sunken-temple", accept(1445, P.felzerul, "Fel'zerul wants 20 Fetishes of Hakkar from the Sunken Temple. Take it if you plan that dungeon.")),
    action("goto", P.lynnore, "Ride south out of Stonard along the road into the Blasted Lands. Two bloodmages camp on the ridge just inside."),
    accept(2601, P.lynnore, "Bloodmage Lynnore and Bloodmage Drazial each brew from beast parts. Take all five of their recipes."),
    accept(2603, P.lynnore), accept(2585, P.drazial), accept(2583, P.drazial), accept(2581, P.drazial),
    B.optional(accept(3501, P.kumisha, "Kum'isha the Collector, in the middle of the Blasted Lands, pays for Draenethyst fragments the ogres drop. Take it if you want her reward.")),
    action("note", bl(nil, 55.0, 30.0),
      "Hunt the valleys south of the bloodmages: Scorpok stingers and Snickerfang hyenas in the west, boars, basilisks and vultures in the middle. Use Next when all five recipes are ready.",
      { name = "Blasted Lands hunt" }),
    B.optional(finish(3501, P.kumisha, "Hand Kum'isha the Draenethyst fragments you looted.")),
    B.optional(accept(2521, P.kumisha, "A Flawless Draenethyst Sphere is rare. Take this only if you found one.")),
    B.optional(finish(2521, P.kumisha)),
    finish(2601, P.lynnore, "Ride back north to the bloodmages."), finish(2603, P.lynnore),
    finish(2585, P.drazial), finish(2583, P.drazial), finish(2581, P.drazial),
    taxi("fly", P.breyk, F.kargath, "Ride north back to Stonard and fly to Kargath in the Badlands."),
  })
end

-- 51-52: Kargath, Thorium Point and the Cauldron, then Flame Crest in the Burning Steppes.
do
  local sg, bs = on.searing, on.steppes
  need(3821, "Dreadmaul Rock", 52, 48)
  need(3822, "Krom'Grul", 53, 48, 3821)
  need(3906, "Disharmony of Flame", 52, 48)
  need(4449, "Caught!", 45, 43)
  need(4451, "The Key to Freedom", 47, 43)
  quest[4451].startItem = 11818
  need(3441, "Divine Retribution", 48, 40)
  need(3442, "The Flawless Flame", 48, 40, 3441)
  need(3443, "Forging the Shaft", 48, 40, 3442)
  need(3452, "The Flame's Casing", 50, 40, 3443)
  need(3453, "The Torch of Retribution", 50, 40, 3452)
  need(3454, "The Torch of Retribution", 50, 40, 3453)
  need(3462, "Squire Maltrake", 50, 40, 3454)
  need(3463, "Set Them Ablaze!", 52, 40, 3462)
  need(3481, "Trinkets...", 50, 40, 3463)
  need(7722, "What the Flux?", 50, 45)
  need(7723, "Curse These Fat Fingers", 49, 45)
  need(7724, "Fiery Menace!", 49, 45)
  need(7727, "Incendosaurs? Whateverosaur is More Like It", 49, 45)
  need(7728, "STOLEN: Smithing Tuyere and Lookout's Spyglass", 48, 45)
  need(7729, "JOB OPPORTUNITY: Culling the Competition", 48, 45)
  need(7701, "WANTED: Overseer Maltorius", 50, 45)
  need(4726, "Broodling Essence", 52, 50)
  need(4808, "Felnok Steelspring", 54, 50, 4726)
  need(4296, "Tablet of the Seven", 50, 50)
  need(4022, "A Taste of Flame", 54, 52, 3481)

  chapter("searing-51", "Searing Gorge and the Burning Steppes", M.searing, 51, 52, {
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    "https://www.wowhead.com/forever/zone=46/burning-steppes",
    QUESTIE,
  }, { "azshara-alt", "ungoro-alt" }, {
    accept(3821, P.thaltrak, "Thal'trak Proudtusk in Kargath asks you to find his brother in the Burning Steppes. Follow him if he walks off while he talks."),
    H.dungeon("blackrock-depths", accept(3906, P.thunderheart, "Thunderheart wants Overmaster Pyron dead in Blackrock Depths.")),
    action("goto", P.outhouse,
      "Ride north out of Kargath up the mountain path into the Searing Gorge. The Grimesilt dig site with its wooden outhouse is the first camp you reach."),
    accept(4449, P.outhouse, "Someone is locked in the outhouse. Bring 15 Silk Cloth: the Shadowforge dwarves in the Badlands drop it, or buy it."),
    objective(4449, sg(nil, 63.3, 61.3), "Kill Dark Iron Geologists around the dig site, then hand the cloth through the outhouse door.",
      "8 Dark Iron Geologist", "15 Silk Cloth"),
    finish(4449, P.outhouse),
    withItem(11818, accept(4451, P.outhouse, "Dark Iron dwarves sometimes drop the Grimesilt Outhouse Key. Use it from your bags if you have it.")),
    finish(4451, P.outhouse),
    accept(3441, P.kalaran, "Ride west to the ridge above the Cauldron. Kalaran Windblade stands alone there."),
    objective(3441, P.kalaran, "Listen to his story.", "Divine Retribution"),
    finish(3441, P.kalaran), accept(3442, P.kalaran),
    taxi("getfp", P.grisha, F.thorium, "Ride north-west to Thorium Point and learn the flight path from Grisha."),
    accept(7723, P.hansel, "Hansel Heavyhands has three jobs for you."), accept(7724, P.hansel), accept(7727, P.hansel),
    accept(7728, P.notice, "Read the board beside the Thorium Point tents for three more."), accept(7729, P.notice), accept(7701, P.notice),
    accept(7722, P.burninate),
    B.optional(action("collect", sg("Clunk", 34.69, 51.89),
      "Clunk, a goblin shredder on the Cauldron's west side, drops a Mithril Casing. Keep it for A-Me 01 in Un'Goro.",
      { item = 10561, sticky = true })),
    along(objective(7724, sg(nil, 28.0, 53.3), "Kill Greater Lava Spiders on the western plateaus and in the south-west lava pools.", "20 Greater Lava Spider"),
      3442, 7723),
    along(objective(3442, sg(nil, 36.0, 45.3), "Heavy War Golems carry Golem Oil and the fire elementals east of the Cauldron carry Hearts of Flame.",
      "4 Heart of Flame", "4 Golem Oil"), 7723, 7728),
    finish(3442, P.kalaran), accept(3443, P.kalaran),
    along(objective(7727, sg(nil, 46.5, 23.7), "Go down into the Slag Pit on the Cauldron's north rim. Incendosaurs fill its lava pools.", "20 Incendosaur"),
      7701, 7722),
    along(objective(7701, sg("Overseer Maltorius", 40.8, 35.9), "Overseer Maltorius waits in the lowest chamber of the Slag Pit.", "Head of Overseer Maltorius"),
      7722),
    objective(7722, sg(nil, 40.5, 35.7), "The Fiery Flux plans lie on the table next to him.", "Secret Plans: Fiery Flux"),
    along(objective(7729, sg(nil, 44.6, 35.5), "Back on the Cauldron floor, kill Taskmasters and Slavers.", "15 Dark Iron Taskmaster", "15 Dark Iron Slaver"),
      3443),
    along(objective(3443, sg(nil, 42.6, 53.6), "Dark Iron dwarves and slave workers drop Thorium Plated Daggers.", "8 Thorium Plated Dagger"), 7729),
    finish(3443, P.kalaran), accept(3452, P.kalaran),
    objective(3452, sg(nil, 23.1, 37.1), "Ride west to the Twilight camp on Firewatch Ridge. The cultists there drop the Symbol of Ragnaros.",
      "Symbol of Ragnaros"),
    finish(3452, P.kalaran), accept(3453, P.kalaran),
    finish(3453, P.kalaran, "Wait for Kalaran to finish the torch, then speak to him again."), accept(3454, P.kalaran),
    finish(3454, P.torch, "Take the Torch of Retribution from beside him."),
    accept(3462, P.kalaran), finish(3462, P.maltrake), accept(3463, P.maltrake),
    along(objective(3463, sg(nil, 33.3, 54.5), "Use the Torch of Retribution inside the four sentry towers around the Cauldron: north and west first, then south and east.",
      "Northern Tower", "Western Tower", "Southern Tower", "Eastern Tower"), 7723, 7728),
    objective(7728, sg(nil, 52.7, 58.5), "Dark Iron Steamsmiths carry the tuyere and the lookouts near the towers carry the spyglass.",
      "Smithing Tuyere", "Lookout's Spyglass"),
    objective(7723, sg(nil, 46.3, 38.7), "Finish the Heavy War Golems along the roads around the Cauldron.", "20 Heavy War Golem"),
    finish(3463, P.maltrake, "Ride back to Squire Maltrake on the ridge."),
    accept(3481, P.hoard, "Open the Hoard of the Black Dragonflight beside him."), finish(3481, P.hoard),
    finish(7701, P.lolo, "Ride north to Thorium Point."), finish(7723, P.hansel), finish(7724, P.hansel), finish(7727, P.hansel),
    finish(7722, P.burninate), finish(7729, P.scrange), finish(7728, P.scrange),
    taxi("getfp", P.vahgruk, F.flameCrest,
      "Ride south down the Searing Gorge to Blackrock Mountain, cross the chain bridges and leave by the Burning Steppes door. Flame Crest is on the ridge to the east; learn its flight path."),
    accept(4726, P.tinkee, "Tinkee Steamboil gives you a device to catch broodling essence."), accept(4296, P.maxwort),
    objective(4296, bs("Tablet of the Seven", 54.12, 40.76), "Ride south-west to the Tablet of the Seven at the edge of the Ruins of Thaurissan and copy it.",
      "Tablet Transcript"),
    finish(3821, P.shani, "Ride east to Dreadmaul Rock. Sha'ni's remains lie at its foot."),
    accept(3822, P.shani),
    objective(3822, bs("Krom'Grul", 79.66, 47.43), "Krom'Grul walks the caves and tunnels inside Dreadmaul Rock. Kill him for the nose-ring.",
      "Sha'ni's Nose-Ring"),
    withItem(12284, objective(4726, bs(nil, 86.5, 32.0),
      "Ride north-east to the black dragon spires. Use the Draco-Incarcinatrix 900 on Black Broodlings, then kill them for their essence.",
      "8 Broodling Essence")),
    accept(4022, P.cyrus, "Cyrus Therepentous camps at the eastern edge of the Steppes. Open the hoard from the Searing Gorge and show him the Black Dragonflight Molt."),
    finish(4022, P.cyrus),
    finish(4726, P.tinkee, "Ride back west to Flame Crest."),
    accept(4808, P.tinkee, "Tinkee sends a letter to Felnok Steelspring in Everlook. Keep it until Winterspring."),
    finish(4296, P.maxwort),
    taxi("fly", P.vahgruk, F.kargath, "Fly to Kargath."),
    finish(3822, P.thaltrak, "Give Thal'trak his brother's nose-ring."),
    taxi("fly", P.gorrik, F.gromgol, "Fly to Grom'gol in Stranglethorn."),
    action("boat", P.nezraz, "Take the zeppelin from the Grom'gol tower to Orgrimmar. Use Next when you land.", { name = "Grom'gol - Orgrimmar" }),
  })
end

-- 52-53: Orgrimmar, Loh'atu, Valormok and Kim'jael in Azshara.
do
  local az = on.azshara
  need(81, "Ripple Delivery", 48, 42, 77)
  need(4300, "Bone-Bladed Weapons", 52, 48)
  need(3504, "Betrayed", 53, 44)
  need(3505, "Betrayed", 53, 44, 3504)
  need(3506, "Betrayed", 56, 44, 3505)
  need(3507, "Betrayed", 56, 44, 3506)
  need(4494, "March of the Silithid", 53, 50)
  need(5535, "Spiritual Unrest", 47, 45)
  need(5536, "A Land Filled with Hatred", 47, 45)
  need(3517, "Stealing Knowledge", 52, 45)
  need(3561, "Delivery to Archmage Xylem", 52, 45, 3517)
  need(3565, "Xylem's Payment to Jediga", 52, 45, 3561)
  need(3518, "Delivery to Magatha", 52, 45, 3517)
  need(3541, "Delivery to Jes'rimon", 52, 45, 3517)
  need(3601, "Kim'jael Indeed!", 53, 47)
  need(5534, "Kim'jael's \"Missing\" Equipment", 53, 47, 3601)
  need(3568, "Seeping Corruption", 52, 45)

  chapter("azshara-52", "Orgrimmar and Azshara", M.azshara, 52, 53, {
    "https://www.wowhead.com/forever/zone=16/azshara",
    QUESTIE,
  }, { "felwood-alt", "ungoro-alt" }, {
    action("sethearth", P.gryshka, "Bind at the inn in the Valley of Strength.", ORGRIMMAR_BIND),
    finish(81, P.dran, "Dran Droffers in the Drag takes the barrel from the Hinterlands, if you carry it."),
    finish(4300, P.jesrimon, "Jes'rimon, in the Cleft of Shadow, wants the White Ravasaur Claws if you brought them from Un'Goro."),
    accept(3504, P.belgrom, "Belgrom Rockmaul in the Valley of Honor gives you a sealed letter for Azshara."),
    accept(4494, P.zilzibin, "Zilzibin Drumlore sends you to an alchemist in Gadgetzan. Keep it for your Tanaris trip."),
    taxi("fly", P.doras, F.splintertree, "Fly to Splintertree Post in Ashenvale."),
    action("goto", P.lohatu, "Ride east along the road out of Ashenvale into Azshara. Loh'atu, a centaur spirit, stands just past the border."),
    accept(5535, P.lohatu), accept(5536, P.lohatu),
    along(objective(5536, az(nil, 20.8, 61.7), "Ride north-east to the Haldarr satyr camp in the ruins.",
      "6 Haldarr Satyr", "2 Haldarr Trickster", "2 Haldarr Felsworn"), 5535),
    along(objective(5535, az(nil, 16.4, 70.3), "Kill the Highborne ghosts at the shrine ruins on your way back south.",
      "6 Highborne Apparition", "6 Highborne Lichling"), 5536),
    finish(5535, P.lohatu), finish(5536, P.lohatu),
    taxi("getfp", P.kroum, F.valormok, "Ride north to Valormok and learn the flight path from Kroum."),
    finish(3504, P.agtor, "Ag'tor Bloodfist waits in the Valormok camp."), accept(3505, P.agtor),
    accept(3517, P.jediga, "Jediga, next to him, wants four stone tablets from the Ruins of Eldarath."),
    action("goto", P.kimjael, "Ride north-east across Azshara to the cliff above the Thalassian Base Camp."),
    accept(3601, P.kimjael, "Kim'jael, a goblin, lost his gear to the blood elves below."),
    along(objective(3505, az(nil, 57.1, 27.8), "Kill Blood Elf Reclaimers and Surveyors in the base camp below the cliff.",
      "10 Blood Elf Reclaimer", "10 Blood Elf Surveyor"), 3601),
    along(objective(3601, az(nil, 57.8, 28.0), "Search the crates around the camp for Kim'jael's four missing things.",
      "Kim'Jael's Compass", "Kim'Jael's Scope", "Kim'Jael's Stuffed Chicken", "Kim'Jael's Wizzlegoober"), 3505),
    finish(3505, P.tome, "Magus Rimtori's camp is at the east end of the base camp. Click the Kaldorei Tome of Summoning there."),
    accept(3506, P.tome),
    objective(3506, P.crystal, "Destroy the arcane focusing crystal beside the tome, then kill Magus Rimtori when she comes for you.",
      "Head of Magus Rimtori"),
    finish(3601, P.kimjael, "Climb back up to Kim'jael."), accept(5534, P.kimjael),
    action("goto", az(nil, 37.2, 54.6), "Ride south-west to the Ruins of Eldarath on the Bay of Storms."),
    along(objective(3517, az(nil, 36.6, 54.0), "The four tablets lie among the ruins and the naga camps.",
      "Tablet of Beth'Amara", "Tablet of Jin'yael", "Tablet of Markri", "Tablet of Sael'hai"), 5534),
    along(objective(5534, az(nil, 45.3, 54.4), "Spitelash Sirens and Myrmidons in the ruins carry Some Rune.", "Some Rune"), 3517),
    note(objective(3568, az(nil, 38.5, 55.0), "If you carry Chemist Cuely's vials, fill each one at a tide pool along the Eldarath shore.",
      "Filled Vial Labeled #1", "Filled Vial Labeled #2", "Filled Vial Labeled #3", "Filled Vial Labeled #4"),
      "Tide pool spots are not in the quest data; search the shore below the ruins."),
    action("goto", P.kimjael, "Ride back north to Kim'jael."),
    finish(5534, P.kimjael),
    action("goto", P.jediga, "Ride back west to Valormok."),
    finish(3517, P.jediga), accept(3561, P.jediga),
    accept(3518, P.jediga, "Jediga also sends tablets to Magatha in Thunder Bluff and Jes'rimon in Orgrimmar. Keep them for those visits."),
    accept(3541, P.jediga),
    finish(3506, P.agtor), accept(3507, P.agtor, "Ag'tor sends you back to Belgrom in Orgrimmar."),
    note(action("goto", P.sanath, "Walk west to Sanath Lim-yo below Archmage Xylem's tower and ask him to send you up."),
      "The old teleport quests are gone from Forever; the gossip option is assumed."),
    finish(3561, P.xylem, "Give Archmage Xylem the Tablet of Sael'hai."), accept(3565, P.xylem),
    finish(3565, P.jediga, "Ask Nyrill to send you down again, then give Jediga Xylem's note."),
    taxi("fly", P.kroum, F.splintertree, "Fly back to Splintertree Post."),
  })
end

-- 53-54: the Emerald Sanctuary, Bloodvenom Post, Timbermaw Hold and the first Winterspring stop.
do
  local fw, ws = on.felwood, on.winterspring
  need(8460, "Timbermaw Ally", 48, 45)
  need(8462, "Speak to Nafien", 55, 45, 8460)
  need(5155, "Forces of Jaedenar", 51, 48)
  need(5157, "Collection of the Corrupt Water", 52, 48, 5155)
  need(5158, "Seeking Spiritual Aid", 52, 48, 5157)
  need(5156, "Verifying the Corruption", 54, 48)
  need(4102, "Cleansing Felwood", 55, 48)
  need(6162, "A Husband's Last Battle", 51, 46)
  need(4505, "Well of Corruption", 54, 49)
  need(4120, "The Strength of Corruption", 52, 47)
  need(3908, "It's a Secret to Everybody", 52, 47, 3845)
  need(3909, "The Videre Elixir", 52, 47, 3908)
  need(6603, "Trouble in Winterspring!", 56, 52)
  need(5082, "Threat of the Winterfall", 56, 52, 6603)
  need(5083, "Winterfall Firewater", 56, 52)
  quest[5083].startItem = 12771
  need(5084, "Falling to Corruption", 56, 52, 5083)
  need(5085, "Mystery Goo", 56, 52, 5084)
  need(3563, "Jes'rimon's Payment to Jediga", 52, 45, 3541)

  chapter("felwood-53", "Felwood: Bloodvenom Post and Timbermaw Hold", M.felwood, 53, 54, {
    "https://www.wowhead.com/forever/zone=361/felwood",
    "https://www.wowhead.com/forever/zone=618/winterspring",
    QUESTIE,
  }, { "ungoro-alt", "plaguelands-alt" }, {
    action("goto", P.grazle, "Ride west out of Splintertree and take the north road out of Ashenvale into Felwood. The Emerald Sanctuary sits beside the road."),
    accept(8460, P.grazle, "Grazle, a Timbermaw furbolg, asks you to prove yourself against the Deadwood tribe."),
    accept(5155, P.greta), accept(5156, P.taronn),
    accept(4102, P.maybess, "Maybess Riverbreeze, west of the sanctuary, wants Blood Amber from the Irontree treants in the north."),
    objective(5155, fw(nil, 37.3, 60.5), "Ride north-west into Jaedenar. Kill hounds, guardsmen, adepts and cultists around the entrance.",
      "4 Jaedenar Hound", "4 Jaedenar Guardsman", "6 Jaedenar Adept", "6 Jaedenar Cultist"),
    taxi("getfp", P.brakkar, F.bloodvenom, "Follow the road north to Bloodvenom Post and learn the flight path from Brakkar."),
    accept(6162, P.dreka, "Dreka'Sur wants the claw of Overlord Ror, the Deadwood chief in the south."),
    accept(4505, P.winna, "Winna Hazzard wants a sample from the satyrs' corrupted moonwell."),
    withItem(12566, objective(4505, P.jadefireWell, "Ride south-west to the moonwell in the Jadefire satyrs' glen and fill Winna's flasket.",
      "Filled Flasket")),
    action("goto", fw(nil, 48.2, 90.5), "Ride south-east to the Deadwood furbolg camps south of the Emerald Sanctuary."),
    along(objective(8460, fw(nil, 48.2, 90.5), "Kill Deadwood warriors, pathfinders and gardeners in the camps.",
      "6 Deadwood Warrior", "6 Deadwood Pathfinder", "6 Deadwood Gardener"), 6162),
    objective(6162, fw("Overlord Ror", 48.23, 94.28), "Overlord Ror stands at the back of the southern camp. Kill him for his claw.",
      "Overlord Ror's Claw"),
    finish(8460, P.grazle, "Return to Grazle at the sanctuary."), accept(8462, P.grazle),
    finish(5155, P.greta), accept(5157, P.greta),
    action("goto", P.jaedenarWell, "Ride back north-west to Jaedenar."),
    withItem(12922, objective(5157, P.jaedenarWell, "Fill the Empty Canteen at the moonwell in the middle of Jaedenar.", "Corrupt Moonwell Water")),
    objective(5156, fw(nil, 42.5, 41.4), "Ride north to Shatter Scar Vale. Kill Entropic Beasts and Horrors and look at the fel craters.",
      "2 Entropic Beast", "2 Entropic Horror"),
    action("goto", P.nafien, "Follow the road north to Nafien outside Timbermaw Hold."),
    finish(8462, P.nafien),
    action("goto", P.salfa, "Walk through the Timbermaw tunnels into Winterspring. The furbolgs let you pass now."),
    finish(3908, P.donova, "Donova Snowden camps by the hot springs. Give her Linken's sword if you carry it."),
    accept(3909, P.donova, "Donova asks about the Videre Elixir. Gregan Brewspewer in Feralas can help."),
    action("goto", P.yugrek, "Ride east along the valley road to Everlook."),
    taxi("getfp", P.yugrek, F.everlook, "Learn the Everlook flight path from Yugrek."),
    finish(4808, P.felnok, "Felnok Steelspring works in the goblin town. Give him Tinkee's letter."),
    accept(6603, P.meggi, "Meggi Peppinrocker sends you to Donova Snowden at the hot springs."),
    action("goto", P.donova, "Ride back west along the road to Donova."),
    finish(6603, P.donova), accept(5082, P.donova, "Donova wants the Winterfall furbolgs around the springs thinned out."),
    objective(5082, ws(nil, 32.3, 36.3), "The Winterfall camps lie north and east of the springs.",
      "8 Winterfall Pathfinder", "8 Winterfall Den Watcher", "8 Winterfall Totemic"),
    withItem(12771, accept(5083, ws(nil, 32.3, 36.3), "Winterfall furbolgs drop an Empty Firewater Flask. Use it from your bags.")),
    finish(5082, P.donova), finish(5083, P.donova), accept(5084, P.donova),
    action("goto", P.cauldron, "Go back through Timbermaw Hold into Felwood. The Deadwood camp sits just outside the tunnel."),
    finish(5084, P.cauldron, "Search the cauldron in the middle of the Deadwood camp."), accept(5085, P.cauldron, "Keep the goo for Donova's next visit."),
    along(objective(4102, fw(nil, 56.3, 18.0), "Ride south to Irontree Woods. Warpwood treants drop Blood Amber.", "15 Blood Amber"), 4120),
    objective(4120, fw(nil, 55.4, 24.7), "If Talo Thornhoof sent you, kill Angerclaw Grizzlies and Felpaw Ravagers around the woods.",
      "12 Angerclaw Grizzly", "12 Felpaw Ravager"),
    action("goto", P.winna, "Ride south along the road to Bloodvenom Post."),
    finish(4505, P.winna), finish(6162, P.dreka),
    action("goto", P.greta, "Ride on south to the Emerald Sanctuary."),
    finish(4102, P.maybess), finish(5157, P.greta),
    accept(5158, P.greta, "Greta wants the water taken to Islen Waterseer outside Ratchet."), finish(5156, P.taronn),
    action("hearth", P.gryshka, "Hearth to Orgrimmar.", ORGRIMMAR_BIND),
    finish(3541, P.jesrimon, "Give Jes'rimon the Tablet of Jin'yael."),
    accept(3563, P.jesrimon, "Take Jes'rimon's note back to Jediga on your next Azshara visit."),
    finish(3507, P.belgrom, "Tell Belgrom what you learned in Azshara."),
  })
end

-- 54-55: Gadgetzan, Marshal's Refuge and the crater, then Feralas, Thunder Bluff and Ratchet.
do
  local ug, tan = on.ungoro, on.tanaris
  need(4496, "Bungle in the Jungle", 53, 50)
  need(3444, "The Stone Circle", 51, 46, 3380)
  need(3446, "Into the Depths", 51, 46, 3444)
  need(3447, "Secret of the Circle", 51, 46, 3444)
  need(3883, "Alien Ecology", 52, 48)
  need(3881, "Expedition Salvation", 53, 48)
  need(3882, "Roll the Bones", 51, 49)
  need(4285, "The Northern Pylon", 53, 47, 4284)
  need(4287, "The Eastern Pylon", 53, 47, 4284)
  need(4288, "The Western Pylon", 53, 47, 4284)
  need(4321, "Making Sense of It", 53, 47, { 4285, 4287, 4288 })
  need(4492, "Lost!", 55, 50)
  need(4491, "A Little Help From My Friends", 55, 50, 4492)
  need(4501, "Beware of Pterrordax", 55, 49)
  need(4145, "Larion and Muigin", 52, 47)
  need(4147, "Marvon's Workshop", 52, 47, 4145)
  need(4503, "Shizzle's Flyer", 51, 49)
  need(4243, "Chasing A-Me 01", 53, 48)
  need(4244, "Chasing A-Me 01", 53, 48, 4243)
  need(4245, "Chasing A-Me 01", 53, 48, 4244)
  need(974, "Finding the Source", 55, 51)
  need(980, "The New Springs", 55, 51, 974)
  need(4289, "The Apes of Un'Goro", 55, 47)
  need(4292, "The Bait for Lar'korwi", 56, 48, 4291)
  need(4301, "The Mighty U'cha", 55, 50, 4289)
  need(1000, "The New Frontier", 55, 54)
  need(1123, "Rabine Saturna", 55, 54, 1000)
  need(5095, "A Call to Arms: The Plaguelands!", 50, 50)
  need(3762, "Assisting Arch Druid Runetotem", 50, 47)
  need(3761, "Un'Goro Soil", 50, 47)
  need(3782, "Morrowgrain Research", 50, 47, 3761)
  need(3562, "Magatha's Payment to Jediga", 52, 45, 3518)
  need(5159, "Cleansed Water Returns to Felwood", 54, 48, 5158)

  chapter("ungoro-54", "Un'Goro Crater: Marshal's Refuge", M.ungoro, 54, 55, {
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    "https://www.wowhead.com/forever/zone=440/tanaris",
    QUESTIE,
  }, { "felwood-alt", "plaguelands-alt" }, {
    taxi("fly", P.doras, F.gadgetzan, "Fly to Gadgetzan."),
    finish(4494, P.pestlezugg, "Alchemist Pestlezugg works on the north side of Gadgetzan."),
    accept(4496, P.pestlezugg, "He wants a Gorishi scent gland and 5 Un'Goro Soil from the crater."),
    finish(3444, P.marvon, "If you carry the Stone Circle, take it to Marvon Rivetseeker south of Gadgetzan."),
    H.dungeon("sunken-temple", accept(3446, P.marvon, "Marvon's two Sunken Temple tasks are done inside the dungeon.")),
    H.dungeon("sunken-temple", accept(3447, P.marvon)),
    taxi("fly", P.bulkrek, F.marshal,
      "Fly to Marshal's Refuge. Without that flight path, ride west out of Gadgetzan and down the ramp into Un'Goro, then north to the refuge."),
    taxi("getfp", P.gryfe, F.marshal, "Learn the Marshal's Refuge flight path from Gryfe."),
    accept(3883, P.holanyee), accept(3881, P.williden), accept(3882, P.spark),
    accept(4285, P.collie, "J.D. Collie in the cave asks you to find the three crystal pylons."), accept(4287, P.collie), accept(4288, P.collie),
    accept(4492, P.spraggle, "Spraggle Frock's friend Ringo is lost near the volcano."),
    accept(4501, P.pterrordaxSign, "Read the warning sign next to Spraggle."),
    accept(4145, P.larion, "Larion wants the bloodpetal plants culled."), accept(4503, P.shizzle),
    accept(4243, P.karna, "Karna Remtravel lost her robot A-Me 01 in the north-east."),
    action("note", nil,
      "Loot 25 Un'Goro Soil from the dirt piles as you cross the crater: 5 for Pestlezugg and 20 for Thunder Bluff.",
      { name = "Un'Goro Soil" }),
    objective(4285, ug("Northern Crystal Pylon", 56.52, 12.54), "Ride east along the northern cliffs to the Northern Crystal Pylon.",
      "Northern Pylon"),
    objective(4289, ug(nil, 66.1, 16.1), "If Torwa gave you the ape pelts, kill gorillas in the cave valley in the north-east.",
      "2 Un'Goro Gorilla Pelt", "2 Un'Goro Stomper Pelt", "2 Un'Goro Thunderer Pelt"),
    finish(4243, P.ame, "A-Me 01 waits beside the gorilla caves."), accept(4244, P.ame),
    note(finish(4244, P.ame, "Give A-Me a Mithril Casing (Clunk in the Searing Gorge drops one). Skip with Next if you have none."),
      "Mithril Casing source: QuestieDB lists Clunk; buying one also works."),
    accept(4245, P.ame, "Walk A-Me back to Karna at the refuge. Gorillas and dinosaurs attack on the way."),
    finish(4245, P.karna),
    along(objective(4145, ug(nil, 65.7, 32.8), "Ride east from the refuge. Bloodpetal lashers and threshers grow in the eastern jungle.",
      "5 Bloodpetal Lasher", "5 Bloodpetal Thresher", "5 Bloodpetal Flayer", "5 Bloodpetal Trapper"), 3882, 4503),
    objective(3881, ug("Crate of Foodstuffs", 68.54, 36.54), "The Crate of Foodstuffs lies in a small camp in the east.", "Crate of Foodstuffs"),
    objective(4287, ug("Eastern Crystal Pylon", 77.16, 49.98), "The Eastern Crystal Pylon stands on the east side of the crater.", "Eastern Pylon"),
    objective(4292, ug(nil, 68.7, 56.7), "If you carry Torwa's pouch, use it near the threshadon carcass to call Lar'korwi.", "Lar'korwi's Head"),
    finish(4289, P.torwa, "Torwa Pathfinder stands at the crater's south-east entrance."),
    finish(4292, P.torwa), accept(4301, P.torwa, "Torwa wants the pelt of U'cha, the gorilla king in the north-east."),
    action("goto", ug(nil, 46.1, 75.9), "Ride west to the Gorishi hive in the south of the crater."),
    along(withItem(11132, objective(3883, ug("Gorishi Hive Hatchery", 48.69, 85.32),
      "Ride west into the Gorishi hive. Use the Scraping Vial at a hatchery chamber.", "Hive Wall Sample")), 4496),
    objective(4496, ug(nil, 46.6, 83.3), "Gorishi silithids drop the scent gland.", "Gorishi Scent Gland", "5 Un'Goro Soil"),
    along(objective(4501, ug(nil, 35.7, 45.4), "Kill Pterrordaxes on the southern plains and Frenzied Pterrordaxes in the west.",
      "10 Pterrordax", "15 Frenzied Pterrordax"), 4503),
    objective(3881, ug("Research Equipment", 38.45, 66.06), "The Research Equipment crate lies in the south-west.", "Research Equipment"),
    along(objective(3882, ug(nil, 33.4, 75.1), "Stegodons and the bone piles in the south-west give Dinosaur Bones.", "8 Dinosaur Bone"), 4503),
    objective(4503, ug(nil, 34.6, 65.5), "Diemetradons drop the webbed scales; pterrordaxes drop the rest.",
      "8 Webbed Diemetradon Scale", "8 Webbed Pterrordax Scale"),
    objective(4288, ug("Western Crystal Pylon", 23.86, 59.19), "The Western Crystal Pylon stands at the crater's west edge.", "Western Pylon"),
    accept(974, P.krakle, "Krakle, a gnome by the western hot springs, has a thermometer for the volcano."),
    withItem(12472, objective(974, ug(nil, 47.6, 47.1), "Climb Fire Plume Ridge and use Krakle's Thermometer at the hottest spot near the top.",
      "Krakle's Thermometer")),
    objective(4502, ug(nil, 47.9, 46.8), "Kill Scorching Elementals and Living Blazes on the ridge for their ash.", "9 Un'Goro Ash"),
    finish(974, P.krakle, "Ride back to Krakle."), accept(980, P.krakle, "Krakle sends you to Donova in Winterspring."),
    finish(4492, P.ringo, "Ringo sits at the foot of Fire Plume Ridge."),
    accept(4491, P.ringo, "Walk Ringo north to Spraggle. Give him Spraggle's canteen whenever he faints."),
    finish(4491, P.spraggle), finish(4501, P.spraggle),
    finish(3883, P.holanyee), finish(3881, P.williden), finish(3882, P.spark),
    finish(4285, P.collie), finish(4287, P.collie), finish(4288, P.collie),
    accept(4321, P.collie), finish(4321, P.collie, "Wait for Collie to study the readings."),
    finish(4503, P.shizzle), finish(4145, P.larion),
    accept(4147, P.larion, "Larion sends you to Marvon's workshop in Ratchet."),
    objective(4301, ug("U'cha", 68.14, 12.56), "If you took Torwa's last task, U'cha lives at the back of the north-east gorilla cave.", "U'cha's Pelt"),
    onQuest(action("goto", P.torwa, "Ride south through the crater to Torwa at the south-east entrance."), 4301),
    finish(4301, P.torwa),
    action("goto", P.pestlezugg, "Fly from Marshal's Refuge to Gadgetzan, or leave the crater by the south-east path."),
    finish(4496, P.pestlezugg),
    onQuest(taxi("fly", P.bulkrek, F.mojache, "Fly to Camp Mojache in Feralas."), 4120),
    finish(4120, P.talo, "Talo Thornhoof waits in Camp Mojache."),
    onQuest(action("goto", P.gregan, "Ride north-west to Gregan Brewspewer's camp for the Videre Elixir."), 3909),
    note(objective(3909, P.gregan,
      "Gregan needs Evoroot for the elixir. Buy his bait, use it to distract Miblon Snarltooth at the Ruins of Isildien, take the Evoroot and return.",
      "Videre Elixir"), "Gregan's own Evoroot quest is not in the Forever client; check how he hands the elixir out."),
    taxi("fly", P.bulkrek, F.bluff, "Fly to Thunder Bluff (from Camp Mojache if you went to Feralas)."),
    accept(1000, P.windstrider, "Bluff Runner Windstrider by the lift has two calls for you."), accept(5095, P.windstrider),
    accept(3762, P.pala, "Innkeeper Pala has a note for the Arch Druid."),
    finish(3762, P.hamuul, "Arch Druid Hamuul Runetotem stands on the Elder Rise."), accept(3761, P.hamuul),
    finish(1000, P.hamuul), accept(1123, P.hamuul, "Hamuul sends you to Rabine Saturna in Moonglade. Keep it for later."),
    finish(3761, P.ghede, "Give Ghede 20 Un'Goro Soil. Use Next if you have too few."),
    accept(3782, P.hamuul), finish(3782, P.bashana),
    finish(3518, P.magatha, "Give Magatha Grimtotem the Tablet of Beth'Amara."),
    accept(3562, P.magatha, "Take Magatha's note back to Jediga in Azshara."),
    taxi("fly", P.tal, F.ratchet, "Fly to Ratchet."),
    finish(4502, P.liv), finish(4147, P.liv),
    finish(5158, P.islen, "Islen Waterseer stands outside Ratchet to the south-east."),
    accept(5159, P.islen, "Take the purified water back to Greta in Felwood."),
  })
end

-- 55-56: Jediga's payments, Shadow Hold, Timbermaw, Donova's Winterfall chain and Everlook.
do
  local fw, ws = on.felwood, on.winterspring
  need(3542, "Delivery to Andron Gant", 52, 45, 3517)
  need(4506, "Corrupted Sabers", 54, 49, 4505)
  need(4521, "Wild Guardians", 56, 52)
  need(4741, "Wild Guardians", 58, 52, 4521)
  need(4721, "Wild Guardians", 59, 52, 4741)
  need(5165, "Dousing the Flames of Protection", 55, 48, 5159)
  need(5242, "A Final Blow", 58, 48, 5165)
  need(5202, "A Strange Red Key", 55, 49)
  quest[5202].startItem = 13140
  need(5203, "Rescue From Jaedenar", 55, 49, 5202)
  need(5204, "Retribution of the Light", 57, 49, 5203)
  need(5385, "The Remains of Trey Lightforge", 57, 49, 5204)
  need(8461, "Deadwood of the North", 55, 45)
  need(8465, "Speak to Salfa", 55, 45, 8461)
  need(8464, "Winterfall Activity", 58, 45)
  need(8470, "Deadwood Ritual Totem", 55, 45)
  quest[8470].startItem = 20741
  need(5086, "Toxic Horrors", 56, 52, 5085)
  need(5087, "Winterfall Runners", 57, 52, 5086)
  need(5121, "High Chief Winterfall", 59, 52, 5087)
  need(4842, "Strange Sources", 56, 51, 980)
  need(3912, "Meet at the Grave", 52, 47, 3909)
  need(3913, "A Grave Situation", 52, 47, 3912)
  need(3914, "Linken's Sword", 52, 47, 3913)
  need(3941, "A Gnome's Assistance", 52, 47, 3914)
  need(3942, "Linken's Memory", 54, 47, 3941)
  need(4084, "Silver Heart", 55, 47, 3942)
  need(3783, "Are We There, Yeti?", 56, 52)
  need(5054, "Ursius of the Shardtooth", 56, 53)
  need(5055, "Brumeran of the Chillwind", 58, 53, 5054)
  need(6029, "The Everlook Report", 52, 50)
  need(6030, "Duke Nicholas Zverenhoff", 52, 50)
  need(5601, "Sister Pamela", 55, 50)

  chapter("winterspring-55", "Felwood and Winterspring: Shadow Hold and the Winterfall", M.felwood, 55, 56, {
    "https://www.wowhead.com/forever/zone=361/felwood",
    "https://www.wowhead.com/forever/zone=618/winterspring",
    QUESTIE,
  }, { "plaguelands-alt", "winterspring-alt" }, {
    taxi("fly", P.bragok, F.valormok, "Fly from Ratchet to Valormok in Azshara."),
    finish(3562, P.jediga, "Give Jediga Magatha's note."), finish(3563, P.jediga, "And Jes'rimon's note."),
    accept(3542, P.jediga, "Jediga's last tablet goes to Andron Gant in the Undercity. Keep it for the Plaguelands."),
    taxi("fly", P.kroum, F.bloodvenom, "Fly to Bloodvenom Post in Felwood."),
    accept(4506, P.winna, "Winna gives you a kitten to take to the corrupted moonwell."),
    accept(4521, P.trull, "Trull Failbane wants Winterspring's owlbeasts thinned out. You will be there soon."),
    action("goto", P.greta, "Ride south along the road to the Emerald Sanctuary."),
    finish(5159, P.greta), accept(5165, P.greta, "Greta gives you purified water for the four braziers in Shadow Hold."),
    note(withItem(12565, objective(4506, P.jadefireWell,
      "Ride north-west to the moonwell in the Jadefire glen and release Winna's kitten there. Pick it up again once it has changed.",
      "Corrupted Saber")), "Moonwell assumed to be the same one as Well of Corruption; check in game."),
    withItem(13140, accept(5202, fw(nil, 37.3, 60.5), "Jaedenar's demons can drop a Blood Red Key. Use it from your bags if you find one.")),
    withItem(12906, objective(5165, fw(nil, 36.5, 55.2), "Climb the path from Jaedenar into Shadow Hold. Douse the four braziers with the purified water as you pass them.",
      "Brazier of Pain", "Brazier of Malice", "Brazier of Suffering", "Brazier of Hatred")),
    finish(5202, P.arko, "Arko'narin is chained in the first cave of Shadow Hold."), accept(5203, P.arko),
    objective(5203, P.arko, "Let Arko'narin collect her gear, then guard her as she fights her way out. Trey Lightforge's spirit attacks near the exit.",
      "Arko'narin escorted"),
    finish(4506, P.winna, "Lead the corrupted saber back to Winna at Bloodvenom Post."),
    action("goto", P.nafien, "Ride north along the road to Nafien at Timbermaw Hold."),
    accept(8461, P.nafien),
    objective(8461, fw(nil, 62.0, 8.0), "Clear the Deadwood camp next to the tunnel.", "6 Deadwood Den Watcher", "6 Deadwood Avenger", "6 Deadwood Shaman"),
    finish(8461, P.nafien), accept(8465, P.nafien),
    withItem(20741, accept(8470, P.kernda, "If the furbolgs dropped a Deadwood Ritual Totem, use it and give it to Kernda inside Timbermaw Hold.")),
    finish(8470, P.kernda),
    finish(8465, P.salfa, "Walk through Timbermaw Hold. Salfa stands outside the Winterspring end."),
    finish(5085, P.donova, "Take the goo to Donova."), accept(5086, P.donova, "Toxic Horrors live in Felwood's Irontree Woods. You will pass them later."),
    finish(980, P.donova, "Tell Donova about the volcano's springs."),
    accept(4842, P.donova, "Donova wants the springs in Darkwhisper Gorge, in the far south, checked."),
    finish(3909, P.donova, "Bring Donova the Videre Elixir if you have it."),
    accept(3912, P.donova, "Donova sends you to the graveyard outside Gadgetzan with the elixir."),
    action("goto", P.vizzie, "Ride east along the road to Everlook. Ragged Owlbeasts along the way count for Trull."),
    action("sethearth", P.vizzie, "Bind at the Everlook inn.", EVERLOOK_BIND),
    accept(3783, P.umi, "Umi Rumplesnicker wants thick yeti fur."),
    accept(5054, P.storm, "Storm Shadowhoof wants Ursius, a great Shardtooth bear, dead."),
    objective(3783, ws(nil, 67.0, 43.0), "Ice Thistle yetis live in the hills east of Everlook.", "10 Thick Yeti Fur"),
    objective(4521, ws(nil, 57.0, 33.6), "Raging Owlbeasts roam the hills north-west of Everlook; Ragged Owlbeasts live along the road to the west.",
      "15 Raging Owlbeast", "15 Ragged Owlbeast"),
    objective(5054, ws("Ursius", 64.01, 24.14), "Ursius prowls the snow north of Everlook. Bring a friend if he is too tough.", "Ursius"),
    finish(3783, P.umi, "Ride back to Everlook."), finish(5054, P.storm),
    accept(5055, P.storm, "Storm next wants Brumeran, a chimaera in the southern valleys."),
    onQuest(taxi("fly", P.yugrek, F.gadgetzan, "Fly to Gadgetzan for Donova's errand."), 3912),
    onQuest(withItem(11243, action("goto", P.gravestone, "In the graveyard east of Gadgetzan, drink the Videre Elixir. You die and walk as a ghost.")), 3912),
    finish(3912, P.gaeriyan, "As a ghost, walk north to Gaeriyan."), accept(3913, P.gaeriyan),
    finish(3913, P.gravestone, "Return to your body, then search the gravestone Gaeriyan described."), accept(3914, P.gravestone),
    onQuest(taxi("fly", P.bulkrek, F.marshal, "Fly to Marshal's Refuge."), 3914),
    finish(3914, P.linken, "Linken sits at the back of the refuge."), accept(3941, P.linken),
    finish(3941, P.collie, "J.D. Collie works in the cave."), accept(3942, P.collie, "Collie sends you to Eridan Bluewind in Felwood."),
    onQuest(action("hearth", P.vizzie, "Hearth to Everlook.", EVERLOOK_BIND), 3942),
    objective(5055, on.winterspring("Brumeran", 62.54, 57.90), "Ride south into the valleys below Everlook. Brumeran roams there.", "Brumeran"),
    objective(4842, ws(nil, 59.82, 74.25), "Ride on south through Frostwhisper Gorge to the edge of Darkwhisper Gorge. Mind the giants on the way.",
      "Darkwhisper Gorge"),
    action("goto", P.storm, "Ride back north to Everlook."),
    finish(5055, P.storm),
    accept(6029, P.gregor, "Gregor Greystone has a report for the Bulwark and a book for Light's Hope Chapel."), accept(6030, P.gregor),
    accept(5601, P.jessica, "Jessica Redpath asks you to find her sister Pamela in Darrowshire."),
    taxi("fly", P.yugrek, F.bloodvenom, "Fly to Bloodvenom Post."),
    finish(4521, P.trull), accept(4741, P.trull, "Trull next wants Moontouched Owlbeasts from Winterspring."),
    action("goto", P.greta, "Ride south to the Emerald Sanctuary."),
    finish(5165, P.greta), accept(5242, P.greta, "Greta wants Shadow Lord Fel'dan and his two guards dead in Shadow Hold."),
    finish(5203, P.jessir), accept(5204, P.jessir),
    finish(3942, P.eridan, "Give Eridan Bluewind Collie's message."),
    accept(4084, P.eridan, "Eridan needs Silvery Claws from Felwood's bears and the heart of an Irontree treant."),
    part(4084, 1, fw(nil, 45.2, 75.4), "Angerclaw bears around the sanctuary drop Silvery Claws.", "11 Silvery Claws"),
    action("goto", fw("Rakaiah", 38.30, 50.51), "Ride north-west back to Shadow Hold."),
    objective(5204, fw("Rakaiah", 38.30, 50.51), "Kill the succubus Rakaiah in Shadow Hold.", "Rakaiah"),
    finish(5204, fw("Remains of Trey Lightforge", 38.5, 50.4), "Search Trey Lightforge's remains beside her."),
    accept(5385, fw("Remains of Trey Lightforge", 38.5, 50.4)),
    objective(5242, fw("Shadow Lord Fel'dan", 38.82, 46.78), "Fight deeper into Shadow Hold for Moora, Salia and Shadow Lord Fel'dan. Pull them one at a time.",
      "Moora", "Salia", "Shadow Lord Fel'dan's Head"),
    action("goto", fw(nil, 49.0, 25.2), "Ride north along the road to Irontree Woods."),
    objective(5086, fw(nil, 49.0, 25.2), "Toxic Horrors lurk in the poisoned pools of Irontree Woods.", "3 Toxic Horror Droplet"),
    part(4084, 2, fw(nil, 47.9, 25.4), "Irontree Stompers drop the Irontree Heart.", "Irontree Heart"),
    action("goto", P.salfa, "Ride north and go through Timbermaw Hold into Winterspring."),
    finish(4842, P.donova), finish(5086, P.donova), accept(5087, P.donova),
    objective(5087, ws(nil, 27.9, 34.5), "Winterfall Runners carry crates between the camps. Watch the road by the Timbermaw exit.", "Winterfall Crate"),
    finish(5087, P.donova), accept(5121, P.donova, "Donova wants High Chief Winterfall dead. You will raid his village on your next visit."),
    action("goto", ws(nil, 65.1, 22.1), "Ride east past Everlook into the hills north-east of the town."),
    objective(4741, ws(nil, 65.1, 22.1), "Hunt Moontouched Owlbeasts in the north-eastern hills.", "13 Moontouched Owlbeast"),
    taxi("fly", P.yugrek, F.bloodvenom, "Ride back to Everlook and fly to Bloodvenom Post."),
    finish(4741, P.trull), accept(4721, P.trull, "Trull's last request: Berserk Owlbeasts in Winterspring. You will hunt them on your next visit."),
    action("goto", P.greta, "Ride south to the Emerald Sanctuary."),
    finish(5242, P.greta), finish(5385, P.jessir), finish(4084, P.eridan),
    taxi("fly", P.brakkar, F.orgrimmar, "Ride back to Bloodvenom Post and fly to Orgrimmar. Train your new ranks while you are there."),
  })
end

-- 56-57: the Bulwark, the Western Plaguelands cauldrons, then Tirion, Nathanos and Light's Hope.
do
  local wpl, epl = on.wpl, on.epl
  need(5096, "Scarlet Diversions", 53, 50, 5095)
  need(5405, "Argent Dawn Commission", 55, 50)
  need(5901, "A Plague Upon Thee", 55, 48)
  need(5902, "A Plague Upon Thee", 55, 48, 5901)
  need(5098, "All Along the Watchtowers", 56, 50, 5096)
  need(5228, "The Scourge Cauldrons", 53, 50, 5096)
  need(5229, "Target: Felstone Field", 53, 50, 5228)
  need(5230, "Return to the Bulwark", 53, 50, 5229)
  need(5231, "Target: Dalson's Tears", 55, 50, 5230)
  need(5232, "Return to the Bulwark", 55, 50, 5231)
  need(5233, "Target: Writhing Haunt", 55, 50, 5232)
  need(5234, "Return to the Bulwark", 55, 50, 5233)
  need(5235, "Target: Gahrron's Withering", 58, 50, 5234)
  need(5021, "Better Late Than Never", 52, 50)
  need(3569, "Seeping Corruption", 52, 45, 3568)
  need(5961, "The Champion of the Banshee Queen", 56, 54)
  need(5058, "Mrs. Dalson's Diary", 55, 52)
  need(4971, "A Matter of Time", 56, 53)
  need(4972, "Counting Out Time", 56, 53, 4971)
  need(838, "Scholomance", 55, 55, 5098)
  need(964, "Skeletal Fragments", 57, 55, 838)
  need(4984, "The Wildlife Suffers Too", 54, 51)
  need(4985, "The Wildlife Suffers Too", 56, 51, 4984)
  need(4987, "Glyphed Oaken Branch", 56, 51, 4985)
  need(6004, "Unfinished Business", 56, 50)
  need(6023, "Unfinished Business", 57, 50, 6004)
  need(5542, "Demon Dogs", 56, 52)
  need(5543, "Blood Tinged Skies", 56, 52)
  need(5544, "Carrion Grubbage", 56, 52)
  need(5742, "Redemption", 56, 52, { 5542, 5543, 5544 })
  need(5781, "Of Forgotten Memories", 57, 52, 5742)
  need(5845, "Of Lost Honor", 58, 52, 5781)
  need(6022, "To Kill With Purpose", 58, 54)
  need(6042, "Un-Life's Little Annoyances", 58, 54)
  need(6133, "The Ranger Lord's Behest", 60, 54)
  need(5149, "Pamela's Doll", 55, 50, 5601)
  need(5152, "Auntie Marlene", 56, 50, 5149)
  need(5241, "Uncle Carlin", 56, 50, 5149)
  need(5211, "Defenders of Darrowshire", 55, 50, 5241)
  need(5153, "A Strange Historian", 56, 50, 5152)
  need(5154, "The Annals of Darrowshire", 56, 50, 5153)
  need(5210, "Brother Carlin", 56, 50, 5154)
  need(6021, "Zaeldarr the Outcast", 55, 50)
  need(5281, "The Restless Souls", 60, 55)
  need(6164, "Augustus' Receipt Book", 55, 50)
  need(6024, "Hameya's Plea", 60, 54)

  chapter("plaguelands-56", "Plaguelands: the Bulwark and Tirion Fordring", M.wpl, 56, 57, {
    "https://www.wowhead.com/forever/zone=28/western-plaguelands",
    "https://www.wowhead.com/forever/zone=139/eastern-plaguelands",
    QUESTIE,
  }, { "silithus-alt", "winterspring-alt" }, {
    action("boat", P.durotarTower, "Leave Orgrimmar by the front gate and take the zeppelin to the Undercity from the tower outside. Use Next when you land.",
      { name = "Orgrimmar - Undercity" }),
    action("goto", P.andron, "Take the lift down into the Undercity."),
    finish(3542, P.andron, "Give Andron Gant Jediga's last tablet."),
    finish(3568, P.cuely, "Chemist Cuely, in the Apothecarium, takes the filled vials if you carry them."), accept(3569, P.cuely),
    finish(3569, P.thersa, "Give Thersa Windsong Cuely's elixir."),
    accept(5961, P.sylvanas, "In the Royal Quarter, Lady Sylvanas sends you to Nathanos Blightcaller as her champion."),
    action("goto", P.derrington, "Leave the city and ride east along the road to the Bulwark at the edge of the Plaguelands."),
    finish(5095, P.derrington), accept(5096, P.derrington, "High Executor Derrington wants the Scarlet Crusade's command tent burned."),
    finish(6029, P.garush, "Give Argent Officer Garush the Everlook report."),
    accept(5405, P.garush, "Garush hands out the Argent Dawn Commission. Wear it to collect Scourgestones."), finish(5405, P.garush),
    action("goto", wpl(nil, 42.0, 51.7), "Ride east into the Western Plaguelands."),
    note(objective(5096, wpl(nil, 42.0, 51.7),
      "Ride east to the Scarlet camp between Felstone Field and Dalson's Tears. Burn their command tent with the items Derrington gave you.",
      "Command tent burned"), "The tent's exact spot is not in the quest data; it stands in the middle of the Scarlet camp."),
    finish(5096, P.derrington, "Ride back west to the Bulwark."),
    accept(5098, P.derrington, "Derrington gives you a beacon torch for the Andorhal towers."), accept(5228, P.derrington),
    finish(5228, P.vandis), accept(5229, P.vandis),
    objective(5229, wpl(nil, 37.2, 56.8), "Ride to Felstone Field. Kill Cauldron Lord Bilemaw beside the cauldron for its key.", "Felstone Field Cauldron Key"),
    finish(5229, P.felstoneCauldron, "Use the key on the cauldron to fill the bottle."), accept(5230, P.felstoneCauldron),
    accept(5021, P.janice, "Janice Felstone's ghost lingers in the farmhouse next to the field."),
    finish(5021, P.parcel, "Her parcel lies in the barn beside the horse."),
    finish(5230, P.vandis, "Ride back to the Bulwark."), accept(5231, P.vandis),
    objective(5231, wpl(nil, 46.2, 52.4), "Ride east to Dalson's Tears. Kill Cauldron Lord Malvinious for the key.", "Dalson's Tears Cauldron Key"),
    finish(5231, P.dalsonCauldron), accept(5232, P.dalsonCauldron),
    accept(5058, P.diary, "Read Mrs. Dalson's diary in the farmhouse."), finish(5058, P.diary),
    withItem(12815, part(5098, 1, wpl("Andorhal Tower One", 40.0, 71.6),
      "Ride south to Andorhal. Stand in each tower's doorway and use the Beacon Torch. Start in the south-west.", "Tower One marked")),
    accept(4971, P.chromie, "Chromie hides in the ruined inn of Andorhal."),
    withItem(12627, objective(4971, wpl(nil, 43.1, 68.1), "Use the Temporal Displacer near one of Andorhal's grain silos and kill the Temporal Parasites that appear.",
      "10 Temporal Parasite")),
    withItem(12815, part(5098, 2, wpl("Andorhal Tower Two", 42.3, 66.2), "Mark the north-west tower.", "Tower Two marked")),
    withItem(12815, part(5098, 3, wpl("Andorhal Tower Three", 44.3, 63.2), "Mark the north-east tower.", "Tower Three marked")),
    withItem(12815, part(5098, 4, wpl("Andorhal Tower Four", 46.6, 71.0), "Mark the south-east tower.", "Tower Four marked")),
    finish(4971, P.chromie), accept(4972, P.chromie),
    objective(4972, wpl(nil, 43.1, 68.1), "Open the small lockboxes in Andorhal's rubble for the watches.", "5 Andorhal Watch"),
    finish(4972, P.chromie),
    finish(5232, P.vandis, "Ride back to the Bulwark."), accept(5233, P.vandis),
    finish(5098, P.derrington), accept(838, P.derrington), finish(838, P.dithers), accept(964, P.dithers),
    accept(5901, P.mickey, "Mickey Levine wants 100 termites from the Eastern Plaguelands. Keep his jar for later."),
    action("goto", wpl(nil, 37.5, 56.3), "Ride east to Felstone Field."),
    objective(964, wpl(nil, 37.5, 56.3), "Skeletal Flayers and Sorcerers around Felstone Field drop Skeletal Fragments.", "15 Skeletal Fragments"),
    finish(964, P.dithers, "Ride back to the Bulwark."),
    action("goto", wpl(nil, 53.0, 65.6), "Ride east along the road to the Writhing Haunt."),
    objective(5233, wpl(nil, 53.0, 65.6), "Kill Cauldron Lord Razarch beside the cauldron for the key.", "Writhing Haunt Cauldron Key"),
    finish(5233, P.haunt), accept(5234, P.haunt),
    accept(4984, P.mulgris, "Mulgris Deepriver, a troll druid on the hill above the Haunt, wants the diseased wildlife put down."),
    objective(4984, wpl(nil, 45.7, 44.6), "Diseased Wolves roam the fields north of Dalson's Tears.", "8 Diseased Wolf"),
    accept(6004, P.kirsta, "Kirsta Deepshadow hides in the hills north of the Scarlet camps."),
    objective(6004, wpl(nil, 50.5, 41.1), "Kill Scarlet medics, hunters, mages and knights at the camps along the Northridge road.",
      "2 Scarlet Medic", "2 Scarlet Hunter", "2 Scarlet Mage", "2 Scarlet Knight"),
    finish(6004, P.kirsta), accept(6023, P.kirsta),
    part(6023, 1, wpl("Huntsman Radley", 57.83, 36.10), "Huntsman Radley holds the Scarlet camp to the east.", "Huntsman Radley"),
    part(6023, 2, wpl("Cavalier Durgen", 55.15, 23.62), "Cavalier Durgen guards the tower to the north.", "Cavalier Durgen"),
    finish(6023, P.kirsta),
    finish(4984, P.mulgris, "Ride south to Mulgris."), accept(4985, P.mulgris),
    objective(4985, wpl(nil, 56.1, 54.0), "Diseased Grizzlies roam east of the Haunt.", "8 Diseased Grizzly"),
    action("goto", P.tirion, "Follow the road east into the Eastern Plaguelands. Tirion Fordring's hut is on the hill north of the road."),
    accept(5542, P.tirion), accept(5543, P.tirion), accept(5544, P.tirion),
    finish(5961, P.nathanos, "Ride south-east to Marris Stead and report to Nathanos Blightcaller."),
    accept(6022, P.nathanos, "Nathanos has two tasks for you."), accept(6042, P.nathanos),
    along(objective(5543, epl(nil, 13.9, 66.4), "Plaguebats, plaguehound runts and carrion grubs crowd the fields west of Marris Stead.", "30 Plaguebat"),
      5542, 5544),
    objective(5544, epl(nil, 15.4, 65.2), "Carrion Grubs and Devourers drop the worm meat.", "15 Slab of Carrion Worm Meat"),
    part(5542, 1, epl(nil, 14.8, 66.6), "Plaguehound Runts roam the same fields.", "20 Plaguehound Runt"),
    finish(5601, P.pamela, "Ride east to ruined Darrowshire. Pamela Redpath's ghost plays there."),
    pre(accept(5149, P.pamela), 5601),
    note(objective(5149, epl(nil, 32.5, 78.5), "Search the ruined houses around Pamela for the doll's head, left side and right side, then put the doll together.",
      "Pamela's Doll"), "The doll pieces' spots are not in the quest data."),
    finish(5149, P.pamela), accept(5152, P.pamela), accept(5241, P.pamela),
    withItem(15454, objective(6022, epl(nil, 52.6, 57.6),
      "Ride north-east to Corin's Crossing. Kill its Scourge for Living Rot and grind seven pieces with the Mortar and Pestle within ten minutes.",
      "Coagulated Rot")),
    objective(6042, epl(nil, 43.7, 52.7), "Noxious Plaguebats circle the middle of the zone; Monstrous Plaguebats fly further north.",
      "20 Noxious Plaguebat", "10 Monstrous Plaguebat"),
    part(5542, 2, epl(nil, 47.0, 47.4), "Plaguehounds hunt the central hills.", "5 Plaguehound"),
    taxi("getfp", P.georgia, F.lightsHope, "Ride east to Light's Hope Chapel and learn the flight path from Georgia."),
    finish(6030, P.zverenhoff, "Give Duke Nicholas Zverenhoff Gregor's book."),
    finish(5241, P.carlin), accept(5211, P.carlin, "Carlin Redpath wants the spirits of Darrowshire's defenders freed."),
    B.only(objective(5211, epl(nil, 53.2, 56.4), "Kill ghouls and flayers as you travel. Free the Darrowshire spirits that rise from them.",
      "15 Darrowshire Spirit"), { sticky = true }),
    accept(6021, P.alen, "Caretaker Alen wants Zaeldarr the Outcast dead."), accept(5281, P.alen, "Alen also asks you to find Egan near Stratholme."),
    action("goto", epl(nil, 44.4, 32.4), "Ride north-west into the hills."),
    part(5542, 3, epl(nil, 44.4, 32.4), "Ride north-west. Frenzied Plaguehounds roam the northern hills.", "5 Frenzied Plaguehound"),
    withItem(15042, objective(5901, epl(nil, 22.2, 30.0), "Use Mickey's termite jar on the termite mounds near Terrordale.", "100 Plagueland Termites")),
    finish(5281, P.egan, "Egan waits in Terrordale, near Stratholme's gate."),
    accept(6164, P.augustus, "Augustus the Touched, beside him, lost his receipt book."),
    objective(6164, epl("Augustus' Receipt Book", 14.04, 24.22), "The receipt book lies in a hut nearby.", "Augustus' Receipt Book"),
    finish(6164, P.augustus),
    finish(5542, P.tirion, "Ride south to Tirion's hut."), finish(5543, P.tirion), finish(5544, P.tirion),
    accept(5742, P.tirion), objective(5742, P.tirion, "Listen to Tirion's story.", "Redemption"), finish(5742, P.tirion),
    accept(5781, P.tirion),
    finish(6022, P.nathanos, "Ride back south-east to Nathanos."), finish(6042, P.nathanos),
    accept(6133, P.nathanos, "Nathanos also wants the Quel'Thalas Registry from the far north. Keep it for later."),
    objective(6021, epl("Zaeldarr the Outcast", 23.07, 72.63), "Ride south to the Undercroft. Zaeldarr the Outcast waits at its mouth.", "Zaeldarr's Head"),
    accept(6024, P.scroll, "Read Hameya's torn scroll near the Undercroft entrance."),
    objective(5781, epl(nil, 23.6, 73.8), "Go down into the Undercroft and kill Mercutio Filthgorger for Taelan's Hammer.", "Taelan's Hammer"),
    action("goto", P.tirion, "Ride north back to Tirion's hut."),
    finish(5781, P.tirion), accept(5845, P.tirion),
    action("goto", P.mulgris, "Follow the road west into the Western Plaguelands to Mulgris."),
    finish(4985, P.mulgris), accept(4987, P.mulgris, "Mulgris gives you a glyphed branch for the druids in Thunder Bluff."),
    finish(5152, P.marlene, "Marlene Redpath lives in the house south of Andorhal."), accept(5153, P.marlene),
    objective(5153, wpl("Joseph Redpath's Monument", 49.70, 76.76), "Search Joseph's grave behind the house for his ring.", "Joseph's Wedding Ring"),
    finish(5153, P.chromie, "Take the ring to Chromie in Andorhal."), accept(5154, P.chromie),
    note(objective(5154, wpl(nil, 43.1, 68.1), "Find the Annals of Darrowshire in Andorhal's town hall.", "Annals of Darrowshire"),
      "The book's spot is not in the quest data."),
    finish(5154, P.chromie), accept(5210, P.chromie, "Chromie sends the extended annals to Carlin Redpath at Light's Hope."),
    finish(5234, P.vandis, "Ride west to the Bulwark."), accept(5235, P.vandis),
    finish(5901, P.mickey), accept(5902, P.mickey, "Mickey wants the termites let loose in the Northridge lumber camp."),
  })
end

-- 57-58: the Undercity, Northdale and the north, then Caer Darrow, Hearthglen and Light's Hope.
do
  local wpl, epl = on.wpl, on.epl
  need(5181, "Villains of Darrowshire", 57, 50, 5210)
  need(5168, "Heroes of Darrowshire", 56, 50, 5210)
  need(5846, "Of Love and Family", 58, 52, 5845)
  need(5236, "Return to the Bulwark", 58, 50, 5235)
  need(6390, "A Plague Upon Thee", 55, 48, 5902)
  need(6025, "Unfinished Business", 58, 50, 6023)

  chapter("plaguelands-57", "Plaguelands: Darrowshire, Northdale and Hearthglen", M.epl, 57, 58, {
    "https://www.wowhead.com/forever/zone=139/eastern-plaguelands",
    "https://www.wowhead.com/forever/zone=28/western-plaguelands",
    QUESTIE,
  }, { "silithus-alt", "winterspring-alt" }, {
    taxi("fly", P.garrett, F.lightsHope, "Ride west to the Undercity and fly to Light's Hope Chapel."),
    finish(6021, P.alen),
    finish(5210, P.carlin), accept(5181, P.carlin), accept(5168, P.carlin),
    objective(5845, epl("Symbol of Lost Honor", 62.53, 26.81), "Ride north to Northdale and search the ruined house for the Symbol of Lost Honor.",
      "Symbol of Lost Honor"),
    objective(6024, epl("Infiltrator Hameya", 61.96, 11.11), "Infiltrator Hameya roams the far north. Kill him for his key.", "Hameya's Key"),
    objective(6133, epl(nil, 45.4, 12.9), "Ride west to the Quel'Lithien lodge. Fight past the rangers and take the Registry from inside.",
      "Quel'Thalas Registry"),
    part(5181, 1, epl(nil, 44.3, 41.2), "Ride south. Horgus's skull lies at the Infectis Scar.", "Skull of Horgus"),
    part(5181, 2, epl(nil, 46.9, 55.4), "Marduk's broken sword lies at the Pestilent Scar further south.", "Shattered Sword of Marduk"),
    finish(6133, P.nathanos, "Ride west to Nathanos at Marris Stead."),
    finish(6024, P.mound, "Use Hameya's key on the mound of dirt behind the Undercroft."),
    action("goto", P.tirion, "Ride north to Tirion's hut."),
    finish(5845, P.tirion), accept(5846, P.tirion, "Tirion asks you to look for a painting on Caer Darrow."),
    action("goto", P.renfray, "Ride west into the Western Plaguelands and south to the lake around Caer Darrow."),
    finish(5846, P.renfray, "Artist Renfray's ghost stands on the island."),
    part(5168, 2, wpl("Redpath's Shield", 63.8, 57.2), "Ride north to Gahrron's Withering. Redpath's Shield lies there.", "Redpath's Shield"),
    objective(5235, wpl(nil, 62.6, 58.9), "Kill Cauldron Lord Soulwrath at Gahrron's Withering for the last key.", "Gahrron's Withering Cauldron Key"),
    finish(5235, P.gahrron), accept(5236, P.gahrron),
    finish(5902, P.barrel, "Ride north-west to the Northridge lumber camp and set the barrel down in the middle."), accept(6390, P.barrel),
    accept(6025, P.kirsta, "Kirsta wants Hearthglen looked over from a high place."),
    objective(6025, wpl(nil, 45.81, 18.25), "Ride north into Hearthglen and climb a tower to look over the town.", "Hearthglen overlooked"),
    part(5168, 1, wpl("Davil's Libram", 42.5, 19.0), "Davil's Libram lies in the Hearthglen town hall.", "Davil's Libram"),
    finish(6025, P.kirsta, "Ride back to Kirsta."),
    finish(5236, P.vandis, "Ride west to the Bulwark."), finish(6390, P.mickey),
    taxi("fly", P.garrett, F.lightsHope, "Ride to the Undercity and fly to Light's Hope Chapel."),
    finish(5211, P.carlin), finish(5181, P.carlin), finish(5168, P.carlin),
  })
end

-- 58-59: Everlook's last jobs, Winterfall Village, Moonglade, Felwood, Thunder Bluff, Tanaris and Un'Goro.
do
  local ws, ug = on.winterspring, on.ungoro
  need(4809, "Chillwind Horns", 54, 50, 4808)
  need(5056, "Shy-Rotam", 60, 53, 5055)
  need(977, "Are We There, Yeti?", 58, 52, 3783)
  need(5163, "Are We There, Yeti?", 58, 52, 977)
  need(4882, "Guarding Secrets", 59, 52)
  quest[4882].startItem = 12558
  need(4883, "Guarding Secrets", 59, 52, 4882)
  need(5123, "The Final Piece", 59, 52, 5087)
  quest[5123].startItem = 12842
  need(5128, "Words of the High Chief", 59, 52, 5123)
  need(1124, "Wasteland", 55, 54, 1123)
  need(5527, "A Reliquary of Purity", 60, 56)
  need(4504, "Super Sticky", 54, 48)
  need(4507, "Pawn Captures Queen", 54, 50, 4496)
  need(1125, "The Spirits of Southwind", 55, 54, 1124)

  chapter("silithus-58", "Winterspring, Moonglade and the Road South", M.winterspring, 58, 59, {
    "https://www.wowhead.com/forever/zone=618/winterspring",
    "https://www.wowhead.com/forever/zone=493/moonglade",
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    QUESTIE,
  }, { "silithus-alt", "winterspring-alt" }, {
    action("hearth", P.vizzie, "Hearth to Everlook.", EVERLOOK_BIND),
    accept(4809, P.felnok, "Felnok wants Uncracked Chillwind Horns from the chimaeras."),
    accept(5056, P.storm, "Storm wants Shy-Rotam, an ancient frostsaber, called out and killed."),
    accept(977, P.umi, "Umi now wants two pristine horns from the yeti leaders."),
    objective(4809, ws(nil, 57.6, 23.1), "Chillwind Ravagers north of Everlook drop Uncracked Chillwind Horns.", "8 Uncracked Chillwind Horn"),
    note(objective(5056, ws(nil, 52.1, 13.2), "Ride on north to Frostsaber Rock. Place Storm's meat to call Shy-Rotam and kill her.", "Shy-Rotam"),
      "The summoning spot is not in the quest data; look for it among the frostsabers."),
    objective(4721, ws(nil, 65.3, 22.7), "Berserk Owlbeasts roam the hills north-east of Everlook.", "10 Berserk Owlbeast"),
    withItem(12558, accept(4882, ws(nil, 65.3, 22.7), "The owlbeasts can drop a Blue-feathered Necklace. Use it from your bags if you find one.")),
    objective(5121, ws("High Chief Winterfall", 69.56, 38.31), "High Chief Winterfall waits in the cave at the back of the village. Bring a friend.",
      "High Chief Winterfall"),
    withItem(12842, accept(5123, ws(nil, 69.56, 38.31), "The High Chief drops a Crudely-written Log. Use it from your bags.")),
    objective(977, ws(nil, 67.2, 41.6), "The Ice Thistle Matriarch and Patriarch live in the yeti cave south of the village.", "2 Pristine Yeti Horn"),
    finish(4809, P.felnok, "Ride back to Everlook."), finish(5056, P.storm), finish(977, P.umi),
    accept(5163, P.umi, "Umi gives you a mechanical yeti to scare her friends in Everlook, Gadgetzan and Marshal's Refuge."),
    withItem(12928, part(5163, 1, P.legacki, "Use the mechanical yeti beside Legacki here in Everlook.", "Legacki scared")),
    action("goto", P.donova, "Ride west along the road to Donova."),
    finish(5121, P.donova), finish(5123, P.donova), accept(5128, P.donova, "Take the log to Kelek Skykeeper in Felwood."),
    action("goto", P.rabine, "Go into Timbermaw Hold and take the tunnel north into Moonglade. Nighthaven lies on the lake's east shore."),
    finish(1123, P.rabine), pre(accept(1124, P.rabine, "Rabine sends you to Layo Starstrike in Silithus."), 1123),
    accept(5527, P.rabine, "Rabine also wants the Reliquary of Purity from Southwind Village in Silithus."),
    taxi("getfp", P.faustron, F.moonglade, "Learn the Moonglade flight path from Faustron on the west side of the lake."),
    taxi("fly", P.faustron, F.bloodvenom, "Fly to Bloodvenom Post."),
    finish(4721, P.trull), finish(4882, P.trull), accept(4883, P.trull, "Trull sends the necklace to Nara Wildmane in Thunder Bluff."),
    action("goto", P.kelek, "Ride south to the Emerald Sanctuary."),
    finish(5128, P.kelek),
    taxi("fly", P.brakkar, F.bluff, "Ride back to Bloodvenom Post and fly to Thunder Bluff."),
    finish(4987, P.nara, "Nara Wildmane lives on the Elder Rise."), finish(4883, P.nara),
    taxi("fly", P.tal, F.gadgetzan, "Fly to Gadgetzan."),
    accept(4504, P.tranrek, "Tran'rek wants Super Sticky Tar from Un'Goro."),
    accept(4507, P.pestlezugg, "Pestlezugg wants the brain of the Gorishi Hive Queen."),
    withItem(12928, part(5163, 2, P.sprinkle, "Scare Sprinkle with the mechanical yeti.", "Sprinkle scared")),
    taxi("fly", P.bulkrek, F.marshal, "Fly to Marshal's Refuge."),
    withItem(12928, part(5163, 3, P.quixxil, "Scare Quixxil in the refuge with the yeti.", "Quixxil scared")),
    objective(4504, ug(nil, 46.6, 17.0), "Kill tar beasts in the Lakkari Tar Pits east of the refuge.", "12 Super Sticky Tar"),
    action("goto", ug(nil, 46.6, 83.3), "Ride south through the crater to the Gorishi hive."),
    objective(4507, ug(nil, 46.6, 83.3), "Go deep into the hive. Call the Hive Queen and kill her for her brain. Bring a friend.",
      "Gorishi Queen Brain"),
    action("goto", P.layo, "Leave Un'Goro by the north-west ramp into Silithus and ride east to Valor's Rest."),
    finish(1124, P.layo, "Layo Starstrike stands by the Valor's Rest graveyard."), accept(1125, P.layo),
  })
end

-- 59-60: Cenarion Hold, then the last hand-ins in Tanaris, Everlook, Moonglade and Orgrimmar.
do
  local sil = on.silithus
  need(1126, "Hive in the Tower", 57, 54, 1125)
  need(6844, "Umber, Archivist", 57, 54, 1126)
  need(6845, "Uncovering Past Secrets", 57, 54, 6844)
  need(1185, "Under the Chitin Was...", 57, 54, 6845)
  need(5526, "Shards of the Felvine", 60, 56, 5527)
  need(8277, "Deadly Desert Venom", 55, 54)
  need(8278, "Noggle's Last Hope", 57, 54, 8277)
  need(8282, "Noggle's Lost Satchel", 58, 54, 8278)
  need(8280, "Securing the Supply Lines", 55, 54)
  need(8281, "Stepping Up Security", 57, 54, 8280)
  need(8283, "Wanted - Deathclasp, Terror of the Sands", 59, 54)
  need(8284, "The Twilight Mystery", 58, 54)
  need(8285, "The Deserter", 59, 54, 8284)
  need(8279, "The Twilight Lexicon", 60, 54, 8285)
  need(8287, "A Terrible Purpose", 60, 54, 8279)
  need(8323, "True Believers", 59, 54, 8279)
  need(8304, "Dearest Natalia", 60, 60)
  need(8318, "Secret Communication", 60, 57)
  need(8308, "Brann Bronzebeard's Lost Letter", 60, 58)
  quest[8308].startItem = 20461
  need(4509, "Calm Before the Storm", 54, 50, 4507)
  need(4511, "Calm Before the Storm", 54, 50, 4509)

  chapter("silithus-59", "Silithus: Cenarion Hold and the Road to 60", M.silithus, 59, 60, {
    "https://www.wowhead.com/forever/zone=1377/silithus",
    "https://www.wowhead.com/forever/zone=493/moonglade",
    QUESTIE,
  }, { "winterspring-alt", "silithus-alt", "plaguelands-alt" }, {
    taxi("getfp", P.runk, F.cenarion, "Ride west to Cenarion Hold and learn the flight path from Runk Windtamer."),
    accept(8318, P.bor, "Bor Wildmane wants Encrypted Twilight Texts from the cultists."),
    accept(8284, P.larksbane),
    accept(8304, P.maralith, "Commander Mar'alith asks about Natalia at Bronzebeard's Encampment."),
    accept(8280, P.proudhorn), accept(8277, P.beetix),
    B.optional(accept(8283, P.poster, "The Deathclasp poster by the inn is a hard kill. Take it if you have help.")),
    along(objective(8280, sil(nil, 54.8, 15.6), "Ride north of the hold. Kill Dredge Strikers.", "15 Dredge Striker"), 8277),
    objective(8277, sil(nil, 57.2, 25.3), "Stonelash Scorpids drop stingers and Sand Skitterers drop fangs in the same hills.",
      "8 Stonelash Scorpid Stinger", "8 Sand Skitterer Fang"),
    withItem(20461, accept(8308, sil(nil, 62.3, 53.6), "If a Twilight cultist dropped Brann's letter, use it from your bags.")),
    objective(1125, sil(nil, 62.3, 53.6), "Ride south-east to ruined Southwind Village and free the tortured druids and sentinels.",
      "8 Tortured Druid", "8 Tortured Sentinel"),
    objective(5527, sil("Dusty Reliquary", 63.23, 55.35), "Search the ruins for the Reliquary of Purity.", "Reliquary of Purity"),
    finish(1125, P.layo, "Ride north-east back to Layo at Valor's Rest."), accept(1126, P.layo),
    note(objective(1126, sil(nil, 62.3, 53.6), "Climb the tower in Southwind Village, use the hive stone and kill the Hive'Ashi Ambusher that bursts out.",
      "Encrusted Silithid Object"), "The tower's spot is not in the quest data; it stands in the village."),
    finish(1126, P.layo, "Ride back to Layo."), accept(6844, P.layo, "Take the object to Umber in Moonglade."),
    action("goto", sil(nil, 23.5, 13.7), "Ride west across Silithus to the Twilight Base Camp in the north-west."),
    objective(8284, sil(nil, 23.5, 13.7), "Pick up Twilight Tablet Fragments around the base camp.", "8 Twilight Tablet Fragment"),
    action("goto", P.larksbane, "Ride back to Cenarion Hold."),
    finish(8284, P.larksbane), accept(8285, P.larksbane), finish(8280, P.proudhorn), accept(8281, P.proudhorn),
    finish(8277, P.beetix), accept(8278, P.beetix),
    action("goto", P.frankal, "Ride south to Bronzebeard's Encampment."),
    part(8304, 1, P.frankal, "Question Frankal Stonebridge.", "Frankal questioned"),
    part(8304, 2, P.rutgar, "Question Rutgar Glyphshaper beside him.", "Rutgar questioned"),
    finish(8308, P.rutgar, "Give Rutgar Brann's letter if you found it."),
    finish(8285, P.ortell, "Ride east to Hermit Ortell's cave."), accept(8279, P.ortell),
    along(objective(8281, sil(nil, 37.3, 54.7), "Kill Dredge Crushers on your way west.", "20 Dredge Crusher"), 8278),
    objective(8278, sil(nil, 34.8, 75.7), "Stonelash Pincers, Flayers and Rock Stalkers roam the southern hills.",
      "3 Stonelash Pincer Stinger", "3 Stonelash Flayer Stinger", "3 Rock Stalker Fang"),
    part(8279, 2, sil("Twilight Keeper Exeter", 16.1, 86.4), "Twilight Keeper Exeter holds the camp in the far south-west.", "Twilight Lexicon - Chapter 2"),
    action("goto", sil(nil, 26.4, 34.7), "Ride north to the Twilight camps in western Silithus."),
    along(objective(8318, sil(nil, 26.4, 34.7), "Twilight Geolords and Avengers at the western camps drop Encrypted Twilight Texts. Collect 20: ten for Bor and ten for Ortell.",
      "10 Encrypted Twilight Text"), 8279),
    part(8279, 1, sil("Twilight Keeper Mayna", 26.4, 36.6), "Twilight Keeper Mayna leads the western camp.", "Twilight Lexicon - Chapter 1"),
    part(8279, 3, sil("Twilight Keeper Havunth", 40.9, 42.2), "Twilight Keeper Havunth holds the camp west of the hold.", "Twilight Lexicon - Chapter 3"),
    finish(8281, P.proudhorn, "Ride back to Cenarion Hold."), finish(8278, P.beetix),
    accept(8282, P.noggle, "Noggle lost his satchel in the southern mountains."),
    finish(8304, P.maralith), finish(8318, P.bor),
    action("goto", sil("Noggle's Satchel", 44.56, 91.38), "Ride south into the mountains."),
    objective(8282, sil("Noggle's Satchel", 44.56, 91.38), "Noggle's satchel lies among the scorpids.", "Noggle's Satchel"),
    B.optional(objective(8283, sil("Deathclasp", 45.07, 92.31), "Deathclasp lurks nearby. Kill it only with help.", "Deathclasp's Pincer")),
    finish(8279, P.ortell, "Ride north-east to Hermit Ortell."), accept(8287, P.ortell),
    accept(8323, P.ortell), finish(8323, P.ortell, "Give Ortell your other ten Encrypted Twilight Texts."),
    action("goto", P.noggle, "Ride back to Cenarion Hold."),
    finish(8282, P.noggle), B.optional(finish(8283, P.vish, "Vish Kozus pays for Deathclasp's pincer.")),
    finish(8287, P.maralith),
    taxi("fly", P.runk, F.gadgetzan, "Fly to Gadgetzan."),
    finish(4504, P.tranrek), finish(4507, P.pestlezugg), accept(4509, P.pestlezugg, "Pestlezugg's report goes to Zilzibin in Orgrimmar."),
    action("hearth", P.vizzie, "Hearth to Everlook.", EVERLOOK_BIND),
    finish(5163, P.umi),
    taxi("fly", P.yugrek, F.moonglade, "Fly to Moonglade."),
    finish(6844, P.umber, "Umber lives in the house on the north side of the lake."), accept(6845, P.umber),
    finish(6845, P.rabine), finish(5527, P.rabine),
    H.dungeon("dire-maul-east", accept(5526, P.rabine, "Rabine's next task, the Felvine, grows in Dire Maul.")),
    accept(1185, P.umber), finish(1185, P.umber, "Hand Umber the silithid object one last time."),
    taxi("fly", P.faustron, F.orgrimmar, "Fly to Orgrimmar."),
    finish(4509, P.zilzibin), accept(4511, P.zilzibin),
    finish(4511, P.karus, "Take the voucher to Karus at the Orgrimmar bank. That is the end of the route: well done on reaching 60."),
  })
end

-- Alternate routes for 50-60: self-contained hubs you can do instead of (or before) a main chapter.
-- Some reuse a main chapter's steps (copies, never its optional or carried steps), the rest are
-- written out because their main chapter mixes in quests from other bands.
do
  local function copy(step)
    local result = {}
    for key, value in pairs(step) do result[key] = value end
    return result
  end

  -- Copies of a main chapter's steps for the given quests, in route order. With `travel`, the
  -- travel and note steps between the first and the last copied quest step come along too.
  local function from(id, ids, travel)
    local wanted, list, first, last = {}, mainSteps[id], nil, nil
    for _, q in ipairs(ids) do wanted[q] = true end
    for i, step in ipairs(list) do
      if step.quest and wanted[step.quest] and not step.optional then
        first, last = first or i, i
      end
    end
    local result = {}
    for i = first, last do
      local step = list[i]
      if step.quest then
        if wanted[step.quest] and not step.optional then result[#result + 1] = copy(step) end
      elseif travel and not step.optional and not step.ifOnQuest then
        result[#result + 1] = copy(step)
      end
    end
    return result
  end

  local function join(...)
    local result = {}
    for i = 1, select("#", ...) do
      for _, step in ipairs((select(i, ...))) do result[#result + 1] = step end
    end
    return result
  end

  local function alternate(id, title, zone, low, high, sources, suggest, steps)
    H.alternate(id, title, zone, low, high, sources, suggest, steps).manual = true
  end

  local fw, ws, wpl = on.felwood, on.winterspring, on.wpl
  need(5094, "A Call to Arms: The Plaguelands!", 50, 50)

  alternate("searing-alt", "Searing Gorge and the Burning Steppes", M.searing, 50, 53, {
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    "https://www.wowhead.com/forever/zone=46/burning-steppes",
    QUESTIE,
  }, { "azshara-52", "azshara-alt" }, join({
    taxi("fly", nil, F.kargath, "Fly to Kargath in the Badlands. From Kalimdor, take the zeppelin to Grom'gol and fly from there."),
  }, from("searing-51", { 3821, 4449, 4451, 3441, 3442, 7723, 7724, 7727, 7728, 7729, 7701, 7722, 3443, 3452, 3453, 3454,
    3462, 3463, 3481, 4726, 4296, 3822, 4022, 4808 }, true)))

  alternate("azshara-alt", "Azshara: Valormok and Kim'jael", M.azshara, 51, 54, {
    "https://www.wowhead.com/forever/zone=16/azshara",
    QUESTIE,
  }, { "felwood-53", "felwood-alt" }, join({
    action("goto", P.belgrom, "Travel to Orgrimmar. Belgrom Rockmaul stands in the Valley of Honor."),
  }, from("azshara-52", { 3504, 5535, 5536, 3505, 3517, 3601, 3506, 5534, 3561, 3565, 3507 }, true), {
    taxi("fly", P.kroum, F.orgrimmar, "Fly to Orgrimmar."),
    finish(3507, P.belgrom, "Tell Belgrom what you learned in Azshara."),
  }))

  alternate("ungoro-alt", "Un'Goro Crater: Marshal's Refuge", M.ungoro, 50, 56, {
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    QUESTIE,
  }, { "winterspring-55", "plaguelands-alt" }, join({
    taxi("fly", nil, F.gadgetzan, "Fly to Gadgetzan in Tanaris."),
  }, from("ungoro-54", { 4496, 3883, 3881, 3882, 4492, 4491, 4501, 4145, 4147, 4503, 4243, 4244, 4245, 974 }, true)))

  alternate("felwood-alt", "Felwood: Emerald Sanctuary and Bloodvenom Post", M.felwood, 52, 56, {
    "https://www.wowhead.com/forever/zone=361/felwood",
    QUESTIE,
  }, { "ungoro-54", "ungoro-alt" }, {
    taxi("fly", nil, F.splintertree, "Fly to Splintertree Post in Ashenvale."),
    action("goto", P.grazle, "Ride west and take the north road out of Ashenvale into Felwood. The Emerald Sanctuary sits beside the road."),
    accept(8460, P.grazle, "Grazle, a Timbermaw furbolg, asks you to prove yourself against the Deadwood tribe."),
    accept(5155, P.greta), accept(5156, P.taronn),
    accept(4102, P.maybess, "Maybess Riverbreeze wants Blood Amber from the Irontree treants in the north."),
    objective(5155, fw(nil, 37.3, 60.5), "Ride north-west into Jaedenar. Kill hounds, guardsmen, adepts and cultists.",
      "4 Jaedenar Hound", "4 Jaedenar Guardsman", "6 Jaedenar Adept", "6 Jaedenar Cultist"),
    taxi("getfp", P.brakkar, F.bloodvenom, "Follow the road north to Bloodvenom Post and learn the flight path."),
    accept(6162, P.dreka, "Dreka'Sur wants the claw of Overlord Ror, the Deadwood chief in the south."),
    accept(4505, P.winna, "Winna Hazzard wants a sample from the satyrs' corrupted moonwell."),
    withItem(12566, objective(4505, P.jadefireWell, "Ride south-west to the moonwell in the Jadefire glen and fill Winna's flasket.",
      "Filled Flasket")),
    action("goto", fw(nil, 48.2, 90.5), "Ride south-east to the Deadwood camps south of the Emerald Sanctuary."),
    objective(8460, fw(nil, 48.2, 90.5), "Kill Deadwood warriors, pathfinders and gardeners in the camps.",
      "6 Deadwood Warrior", "6 Deadwood Pathfinder", "6 Deadwood Gardener"),
    objective(6162, fw("Overlord Ror", 48.23, 94.28), "Overlord Ror stands at the back of the southern camp.", "Overlord Ror's Claw"),
    finish(8460, P.grazle), accept(8462, P.grazle), finish(5155, P.greta), accept(5157, P.greta),
    action("goto", P.jaedenarWell, "Ride back north-west to Jaedenar."),
    withItem(12922, objective(5157, P.jaedenarWell, "Fill the Empty Canteen at the moonwell in the middle of Jaedenar.", "Corrupt Moonwell Water")),
    objective(5156, fw(nil, 42.5, 41.4), "Ride north to Shatter Scar Vale. Kill Entropic Beasts and Horrors and look at the fel craters.",
      "2 Entropic Beast", "2 Entropic Horror"),
    finish(4505, P.winna, "Ride back to Bloodvenom Post."), finish(6162, P.dreka),
    accept(4506, P.winna, "Winna gives you a kitten to take to the corrupted moonwell."),
    note(withItem(12565, objective(4506, P.jadefireWell, "Release Winna's kitten at the Jadefire moonwell and pick it up again once it has changed.",
      "Corrupted Saber")), "Moonwell assumed to be the same one as Well of Corruption; check in game."),
    finish(4506, P.winna, "Lead the corrupted saber back to Winna."),
    action("goto", fw(nil, 56.3, 18.0), "Ride north along the road to Irontree Woods."),
    objective(4102, fw(nil, 56.3, 18.0), "Warpwood treants drop Blood Amber.", "15 Blood Amber"),
    action("goto", P.nafien, "Follow the road north to Nafien outside Timbermaw Hold."),
    finish(8462, P.nafien), accept(8461, P.nafien),
    objective(8461, fw(nil, 62.0, 8.0), "Clear the Deadwood camp next to the tunnel.", "6 Deadwood Den Watcher", "6 Deadwood Avenger", "6 Deadwood Shaman"),
    finish(8461, P.nafien),
    action("goto", P.greta, "Ride back south along the road to the Emerald Sanctuary."),
    finish(4102, P.maybess), finish(5157, P.greta), finish(5156, P.taronn),
  })

  alternate("plaguelands-alt", "Western Plaguelands: the Bulwark", M.wpl, 53, 58, {
    "https://www.wowhead.com/forever/zone=28/western-plaguelands",
    QUESTIE,
  }, { "silithus-58", "winterspring-alt", "silithus-alt" }, {
    action("goto", P.balthazad, "Travel to the Undercity. Harbinger Balthazad stands near the bank."),
    accept(5094, P.balthazad, "Harbinger Balthazad calls you to the Plaguelands."),
    action("goto", P.derrington, "Leave the city and ride east along the road to the Bulwark."),
    finish(5094, P.derrington), pre(accept(5096, P.derrington, "High Executor Derrington wants the Scarlet Crusade's command tent burned."), 5094),
    action("goto", wpl(nil, 42.0, 51.7), "Ride east into the Western Plaguelands."),
    note(objective(5096, wpl(nil, 42.0, 51.7), "Burn the command tent in the Scarlet camp between Felstone Field and Dalson's Tears with Derrington's items.",
      "Command tent burned"), "The tent's exact spot is not in the quest data."),
    finish(5096, P.derrington, "Ride back west to the Bulwark."),
    accept(5098, P.derrington, "Derrington gives you a beacon torch for the Andorhal towers."), accept(5228, P.derrington),
    finish(5228, P.vandis), accept(5229, P.vandis),
    objective(5229, wpl(nil, 37.2, 56.8), "Kill Cauldron Lord Bilemaw at Felstone Field for the cauldron key.", "Felstone Field Cauldron Key"),
    finish(5229, P.felstoneCauldron, "Use the key on the cauldron."), accept(5230, P.felstoneCauldron),
    accept(5021, P.janice, "Janice Felstone's ghost lingers in the farmhouse."), finish(5021, P.parcel, "Her parcel lies in the barn."),
    finish(5230, P.vandis, "Ride back to the Bulwark."), accept(5231, P.vandis),
    objective(5231, wpl(nil, 46.2, 52.4), "Kill Cauldron Lord Malvinious at Dalson's Tears for the key.", "Dalson's Tears Cauldron Key"),
    finish(5231, P.dalsonCauldron), accept(5232, P.dalsonCauldron),
    accept(5058, P.diary, "Read Mrs. Dalson's diary in the farmhouse."), finish(5058, P.diary),
    withItem(12815, part(5098, 1, wpl("Andorhal Tower One", 40.0, 71.6), "Ride south to Andorhal. Use the Beacon Torch in each tower's doorway.",
      "Tower One marked")),
    accept(4971, P.chromie, "Chromie hides in the ruined inn of Andorhal."),
    withItem(12627, objective(4971, wpl(nil, 43.1, 68.1), "Use the Temporal Displacer near a grain silo and kill the Temporal Parasites.",
      "10 Temporal Parasite")),
    withItem(12815, part(5098, 2, wpl("Andorhal Tower Two", 42.3, 66.2), "Mark the north-west tower.", "Tower Two marked")),
    withItem(12815, part(5098, 3, wpl("Andorhal Tower Three", 44.3, 63.2), "Mark the north-east tower.", "Tower Three marked")),
    withItem(12815, part(5098, 4, wpl("Andorhal Tower Four", 46.6, 71.0), "Mark the south-east tower.", "Tower Four marked")),
    finish(4971, P.chromie), accept(4972, P.chromie),
    objective(4972, wpl(nil, 43.1, 68.1), "Open the small lockboxes in the rubble for the watches.", "5 Andorhal Watch"),
    finish(4972, P.chromie),
    finish(5232, P.vandis, "Ride back to the Bulwark."), accept(5233, P.vandis),
    finish(5098, P.derrington), accept(838, P.derrington), finish(838, P.dithers), accept(964, P.dithers),
    action("goto", wpl(nil, 37.5, 56.3), "Ride east to Felstone Field."),
    objective(964, wpl(nil, 37.5, 56.3), "Skeletal Flayers and Sorcerers drop Skeletal Fragments.", "15 Skeletal Fragments"),
    finish(964, P.dithers, "Ride back to the Bulwark."),
    action("goto", wpl(nil, 53.0, 65.6), "Ride east along the road to the Writhing Haunt."),
    objective(5233, wpl(nil, 53.0, 65.6), "Kill Cauldron Lord Razarch for the key.", "Writhing Haunt Cauldron Key"),
    finish(5233, P.haunt), accept(5234, P.haunt),
    accept(4984, P.mulgris, "Mulgris Deepriver wants the diseased wildlife put down."),
    objective(4984, wpl(nil, 45.7, 44.6), "Diseased Wolves roam the fields north of Dalson's Tears.", "8 Diseased Wolf"),
    accept(6004, P.kirsta, "Kirsta Deepshadow hides in the hills north of the Scarlet camps."),
    objective(6004, wpl(nil, 50.5, 41.1), "Kill Scarlet medics, hunters, mages and knights at the camps.",
      "2 Scarlet Medic", "2 Scarlet Hunter", "2 Scarlet Mage", "2 Scarlet Knight"),
    finish(6004, P.kirsta), accept(6023, P.kirsta),
    part(6023, 1, wpl("Huntsman Radley", 57.83, 36.10), "Huntsman Radley holds the Scarlet camp to the east.", "Huntsman Radley"),
    part(6023, 2, wpl("Cavalier Durgen", 55.15, 23.62), "Cavalier Durgen guards the tower to the north.", "Cavalier Durgen"),
    finish(6023, P.kirsta), accept(6025, P.kirsta, "Kirsta wants Hearthglen looked over from a high place."),
    objective(6025, wpl(nil, 45.81, 18.25), "Ride north into Hearthglen and climb a tower to look over the town.", "Hearthglen overlooked"),
    finish(6025, P.kirsta),
    finish(4984, P.mulgris, "Ride south to Mulgris."), accept(4985, P.mulgris),
    objective(4985, wpl(nil, 56.1, 54.0), "Diseased Grizzlies roam east of the Haunt.", "8 Diseased Grizzly"),
    finish(4985, P.mulgris),
    action("goto", P.vandis, "Ride west to the Bulwark."),
    finish(5234, P.vandis), accept(5235, P.vandis),
    action("goto", wpl(nil, 62.6, 58.9), "Ride east to Gahrron's Withering."),
    objective(5235, wpl(nil, 62.6, 58.9), "Kill Cauldron Lord Soulwrath for the last key.", "Gahrron's Withering Cauldron Key"),
    finish(5235, P.gahrron), accept(5236, P.gahrron),
    action("goto", P.vandis, "Ride back west to the Bulwark."),
    finish(5236, P.vandis),
  })

  alternate("silithus-alt", "Silithus: Cenarion Hold", M.silithus, 55, 60, {
    "https://www.wowhead.com/forever/zone=1377/silithus",
    QUESTIE,
  }, { "winterspring-alt", "silithus-59" }, join({
    taxi("fly", nil, F.cenarion, "Fly to Cenarion Hold. Without that flight path, fly to Marshal's Refuge and take Un'Goro's north-west ramp into Silithus."),
    taxi("getfp", P.runk, F.cenarion, "Learn the Cenarion Hold flight path from Runk Windtamer."),
  }, from("silithus-59", { 8277, 8278, 8280, 8281, 8284, 8285, 8279, 8287, 8323, 8282, 8304, 8318, 8308 }, true)))

  alternate("winterspring-alt", "Winterspring: Everlook and the Winterfall", M.winterspring, 55, 60, {
    "https://www.wowhead.com/forever/zone=618/winterspring",
    QUESTIE,
  }, { "silithus-alt", "silithus-59" }, {
    taxi("fly", nil, F.everlook, "Fly to Everlook. Without that flight path, go through Timbermaw Hold from northern Felwood and ride east."),
    action("sethearth", P.vizzie, "Bind at the Everlook inn.", EVERLOOK_BIND),
    accept(6603, P.meggi, "Meggi Peppinrocker sends you to Donova Snowden at the hot springs."),
    accept(3783, P.umi, "Umi Rumplesnicker wants thick yeti fur."),
    accept(5054, P.storm, "Storm Shadowhoof wants Ursius, a great Shardtooth bear, dead."),
    objective(3783, ws(nil, 67.0, 43.0), "Ice Thistle yetis live in the hills east of Everlook.", "10 Thick Yeti Fur"),
    objective(5054, ws("Ursius", 64.01, 24.14), "Ursius prowls the snow north of Everlook.", "Ursius"),
    finish(3783, P.umi, "Ride back to Everlook."), accept(977, P.umi), finish(5054, P.storm), accept(5055, P.storm),
    objective(977, ws(nil, 67.2, 41.6), "The Ice Thistle Matriarch and Patriarch live in the yeti cave east of Everlook.", "2 Pristine Yeti Horn"),
    objective(5055, ws("Brumeran", 62.54, 57.90), "Ride south into the valleys below Everlook for Brumeran.", "Brumeran"),
    finish(977, P.umi, "Ride back to Everlook."), finish(5055, P.storm), accept(5056, P.storm),
    action("goto", ws(nil, 52.1, 13.2), "Ride north to Frostsaber Rock."),
    note(objective(5056, ws(nil, 52.1, 13.2), "Place Storm's meat to call Shy-Rotam and kill her.", "Shy-Rotam"),
      "The summoning spot is not in the quest data."),
    action("goto", P.storm, "Ride back south to Everlook."),
    finish(5056, P.storm),
    action("goto", P.donova, "Ride west along the road to Donova Snowden at the hot springs."),
    finish(6603, P.donova), accept(5082, P.donova, "Donova wants the Winterfall furbolgs around the springs thinned out."),
    objective(5082, ws(nil, 32.3, 36.3), "The Winterfall camps lie north and east of the springs.",
      "8 Winterfall Pathfinder", "8 Winterfall Den Watcher", "8 Winterfall Totemic"),
    withItem(12771, accept(5083, ws(nil, 32.3, 36.3), "Winterfall furbolgs drop an Empty Firewater Flask. Use it from your bags.")),
    finish(5082, P.donova), finish(5083, P.donova), accept(5084, P.donova),
    accept(8464, P.salfa, "Salfa, at the Timbermaw exit, wants Winterfall Village raided."),
    action("goto", P.cauldron, "Go through Timbermaw Hold into Felwood. The Deadwood camp sits just outside the tunnel."),
    finish(5084, P.cauldron, "Search the cauldron in the middle of the Deadwood camp."), accept(5085, P.cauldron),
    action("goto", P.donova, "Go back through Timbermaw Hold to Donova."),
    finish(5085, P.donova), accept(5086, P.donova),
    action("goto", fw(nil, 49.0, 25.2), "Go back through Timbermaw Hold and ride south to the poisoned pools of Irontree Woods."),
    objective(5086, fw(nil, 49.0, 25.2), "Toxic Horrors lurk in the pools.", "3 Toxic Horror Droplet"),
    action("goto", P.donova, "Ride north and go through Timbermaw Hold back to Donova."),
    finish(5086, P.donova), accept(5087, P.donova),
    objective(5087, ws(nil, 27.9, 34.5), "Winterfall Runners carry crates between the camps. Watch the road by the Timbermaw exit.", "Winterfall Crate"),
    finish(5087, P.donova), accept(5121, P.donova, "Donova wants High Chief Winterfall dead. Bring a friend for his cave."),
    action("goto", ws(nil, 66.8, 38.0), "Ride east past Everlook to Winterfall Village."),
    objective(8464, ws(nil, 66.8, 38.0), "Raid the village.", "8 Winterfall Shaman", "8 Winterfall Den Watcher", "8 Winterfall Ursa"),
    objective(5121, ws("High Chief Winterfall", 69.56, 38.31), "High Chief Winterfall waits in the cave at the back of the village.",
      "High Chief Winterfall"),
    withItem(12842, accept(5123, ws(nil, 69.56, 38.31), "The High Chief drops a Crudely-written Log. Use it from your bags.")),
    action("goto", P.donova, "Ride back west to Donova."),
    finish(5121, P.donova), finish(5123, P.donova), finish(8464, P.salfa),
  })
end
