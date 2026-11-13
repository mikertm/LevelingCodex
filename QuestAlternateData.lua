-- Alliance alternate routes. Source notes: tools/audits/2026-11-09-alliance-route-expansion.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local at, q, accept, finish = B.at, B.q, B.accept, B.finish
local objective, action, taxi = B.objectiveAt, B.action, B.taxi
local M = B.maps
local ashenvale, stonetalon, hillsbrad = 1440, 1442, 1424

local function along(step, ...)
  step.also = { ... }
  return step
end

local function check(step, text)
  step.uncertain = text
  return step
end

local function chapter(id, title, zone, low, high, sources, suggest, steps)
  route.sections[#route.sections + 1] = {
    id = id, title = title, zone = zone, levels = { low, high }, alternate = true,
    verified = false, sources = sources, suggest = suggest, steps = steps,
  }
end

local function suggest(section, ...)
  local result, seen = {}, {}
  for _, ids in ipairs({ { ... }, section.suggest or {} }) do
    for _, id in ipairs(ids) do
      if not seen[id] then
        result[#result + 1], seen[id] = id, true
      end
    end
  end
  section.suggest = result
end

local function ash(name, x, y) return at(name, x, y, ashenvale) end
local function stone(name, x, y) return at(name, x, y, stonetalon) end
local function wet(name, x, y) return at(name, x, y, M.wetlands) end
local function rr(name, x, y) return at(name, x, y, M.redridge) end
local function dw(name, x, y) return at(name, x, y, M.duskwood) end
local function hill(name, x, y) return at(name, x, y, hillsbrad) end

local astranaar = ash("Daelyshia", 34.41, 47.99)
local kimlya = ash("Innkeeper Kimlya", 36.99, 49.22)
local maestra = ash(nil, 26.2, 38.7)
local talondeep = ash(nil, 42.27, 71.09)
local menethil = wet("Shellei Brondir", 9.5, 59.7)
local darkshire = dw("Felicia Maline", 77.49, 44.29)
local lakeshire = rr("Ariena Stormfeather", 25.5, 59.3)
local astranaarFlight = "Astranaar, Ashenvale"
local menethilFlight = "Menethil Harbor, Wetlands"
local ashSources = {
  "https://wowforeverinfo.com/guides/ashenvale-alliance-18-30/",
  "https://bindonforever.com/zones/ashenvale",
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
}

q(967, "The Tower of Althalaxx", 18, 13, 966)
q(970, "The Tower of Althalaxx", 21, 13, 967)
q(973, "The Tower of Althalaxx", 24, 13, 970)
q(1008, "The Zoram Strand", 19, 14)
q(1007, "The Ancient Statuette", 20, 19)
q(991, "Raene's Cleansing", 19, 18)
q(1023, "Raene's Cleansing", 21, 18, 991)
q(1010, "Bathran's Hair", 20, 20)
q(1020, "Orendil's Cure", 20, 20, 1010)
q(1033, "Elune's Tear", 22, 20, 1020)
q(1034, "The Ruins of Stardust", 23, 20, 1033)
q(1054, "Culling the Threat", 25, 18)
-- Gap fill: tools/audits/2026-11-10-darkshore-ashenvale-wetlands-gaps.md.
q(945, "Therylune's Escape", 18, 10)
q(5321, "The Sleeper Has Awakened", 20, 17)
q(1009, "Ruuzel", 25, 20, 1007)
-- Gap fill: tools/audits/2026-11-12-alliance-kalimdor-loch-modan.md.
q(5713, "One Shot. One Kill.", 15, 10)

local balthule = at("Balthule Shadowstrike", 54.97, 24.89, M.darkshore)
local delgren = ash("Delgren the Purifier", 26.2, 38.7)
local orendil = ash("Orendil Broadleaf", 26.44, 38.59)
local shindrell = ash("Shindrell Swiftfire", 34.67, 48.84)
local raene = ash("Raene Wolfrunner", 36.62, 49.58)
local pelturas = ash("Pelturas Whitemoon", 37.37, 51.79)
local teronis = ash("Teronis' Corpse", 20.31, 42.33)
local talen = ash("Talen", 14.79, 31.3)
local ashHearth = { bind = "Astranaar" }
local therylune = at("Therylune", 38.64, 87.34, M.darkshore)
local kerlonian = at("Kerlonian Evershade", 44.4, 76.4, M.darkshore)
local liladris = ash("Liladris Moonriver", 27.3, 35.6)
local therysil = ash("Therysil", 22.65, 51.91)

local findTeronis = accept(991, raene)
local reachTeronis = finish(991, teronis,
  "Find Teronis by the lake west of Astranaar. Approach on the north shore and clear the murlocs around him.")
local takeGemQuest = accept(1023, teronis)
local lootGem = objective(1023, ash(nil, 20.34, 42.31),
  "Loot the gem from Saltspittle murlocs near Teronis. Keep his journal for the turn-in.", "Glowing Gem")

chapter("ashenvale-early", "Ashenvale: Astranaar and the Coast", ashenvale, 18, 24, ashSources,
  { "stonetalon", "ashenvale-late", "wetlands-early", "lakeshire", "duskwood" }, {
    -- Already done for players coming from the Darkshore chapter.
    accept(965, at("Sentinel Elissa Starbreeze", 39.05, 43.55, M.darkshore),
      "For Delgren's chain, start with Elissa in Auberdine. Use Next to leave the tower chain for later if you want to stay in Ashenvale."),
    finish(965, balthule, "Take the northeast road out of Auberdine to Balthule near the tower."), accept(966, balthule),
    objective(966, at(nil, 56.5, 26.2, M.darkshore), "Loot the parchments from Dark Strand Fanatics outside the tower.", "4 Worn Parchments"),
    finish(966, balthule), accept(967, balthule),
    -- Two escorts on the road south: Therylune first, then Kerlonian all the way to Maestra's Post.
    action("goto", therylune, "Take the south road from Auberdine past the Grove of the Ancients to the Twilight camp at the Master's Glaive."),
    accept(945, therylune, "Clear the cultists around Therylune, then speak to her."),
    objective(945, at(nil, 40.51, 87.09, M.darkshore), "Stay close while Therylune walks out of the camp and fight anything that attacks her.", "Therylune escorted"),
    -- Aynasha's stand: south-east of the Glaive, turned in beside Liladris at Maestra's Post.
    accept(5713, at("Sentinel Aynasha", 45.94, 90.29, M.darkshore),
      "Head east from the Glaive to Sentinel Aynasha near the Ashenvale border. She is poisoned and needs cover while she brews a cure."),
    objective(5713, at("Sentinel Aynasha", 45.94, 90.29, M.darkshore),
      "Stay beside Aynasha and kill the Blackwood Trackers that come for her, then Marosh the Devious. Speak to her once the last wave falls.",
      "Aynasha protected"),
    accept(5321, kerlonian, "Go back north to the grove. Open Kerlonian's chest beside him for the Horn of Awakening, then wake him."),
    objective(5321, liladris, "Lead Kerlonian south along the road into Ashenvale. Each time he falls asleep, use the Horn of Awakening near him.",
      "Kerlonian escorted to Maestra's Post"),
    finish(5321, liladris, "Liladris Moonriver waits at Maestra's Post."),
    finish(5713, ash("Sentinel Onaeya", 26.6, 36.73), "Sentinel Onaeya stands beside Liladris. Tell her Aynasha is safe."),
    action("goto", maestra, "If you skipped the escorts, take the south road from Auberdine through the Grove of the Ancients into Ashenvale to Maestra's Post."),
    finish(967, delgren), accept(970, delgren),
    taxi("getfp", astranaar, astranaarFlight, "Follow the road southeast from Maestra's Post and learn the Astranaar flight path."),
    -- Shindrell beside the flight point, then the inn and Raene on its east side (2026-11-12 loop check).
    accept(1008, shindrell),
    action("sethearth", kimlya, "Bind at the Astranaar inn for the west-coast trips.", ashHearth),
    findTeronis,
    accept(1054, raene, "Raene also wants Dal Bloodclaw, a level 25 furbolg in Thistlefur Village. Take it now: the hunt waits for the second circuit."),
    reachTeronis, takeGemQuest, lootGem,
    finish(945, therysil, "Follow the lake shore south to the Shrine of Aessina and tell Therysil her sister is safe."),
    accept(1007, talen, "Go west around the hills to Talen's camp above the Zoram Strand. If below level 19, take his quest after you level."),
    along(objective(1007, ash("Ancient Statuette", 14.2, 20.64),
      "Pick up the statuette among the northern ruins while you clear naga for their heads.", "Ancient Statuette"), 1008),
    along(objective(1008, ash(nil, 14.88, 22.47),
      "Work the coast on your way back toward Talen. Pull Wrathtail naga one at a time.", "20 Wrathtail Heads"), 1007),
    finish(1007, talen),
    accept(1009, talen, "Talen also wants the Ring of Zoram back from the naga."),
    along(objective(1009, ash("Ruuzel", 7.2, 13.1),
      "Swim to the small island off the north end of the strand and kill Ruuzel, level 22, for the ring. Pull his guards away first. Lady Vespia on the strand can drop it too.",
      "Ring of Zoram"), 1008),
    finish(1009, talen),
    action("hearth", kimlya, "Return to Astranaar. On foot, take the road east past Maestra's Post.", ashHearth),
    finish(1008, shindrell), finish(1023, raene),
    action("grind", kimlya, "Reach level 20 for Orendil's chain. If you need experience, finish Darkshore or Lakeshire quests before the next circuit.",
      { level = 20, suggest = { "darkshore", "lakeshire", "wetlands-early" } }),

    action("goto", maestra, "Take the road northwest from Astranaar to Maestra's Post."), accept(1010, orendil),
    objective(970, ash(nil, 31.39, 30.62), "Clear cultists around the ruins northeast of the post. Loot the Glowing Soul Gem.", "Glowing Soul Gem"),
    objective(1010, ash(nil, 31.46, 22.81), "Continue north to Bathran's Haunt and gather the plant bundles between the ruins.", "5 Bathran's Hair"),
    finish(1010, orendil), accept(1020, orendil),
    finish(970, delgren), accept(973, delgren),
    action("goto", pelturas, "Return to Astranaar and find Pelturas inside the house on the east side of the island."),
    finish(1020, pelturas), accept(1033, pelturas, "Wait for Pelturas to finish speaking before checking for his next quest."),
    objective(1033, ash(nil, 46.24, 45.96), "Cross the east bridge and gather a tear from the grass above the lake.", "Elune's Tear"),
    objective(1054, ash(nil, 39.56, 36.31), "Look for Dal Bloodclaw on the paths in Thistlefur Village. Pull his neighbors separately or leave him for another visit.", "Dal Bloodclaw's Skull"),
    finish(1054, raene), finish(1033, pelturas), accept(1034, pelturas),
    objective(1034, ash(nil, 33.42, 67.36), "Collect from the bushes among the ruins south of town. Start at the edge to avoid extra elementals.", "5 Handfuls of Stardust"),
    action("goto", ash(nil, 28.39, 60.88), "Leave the ruins to the northeast and take the path up to Fire Scar Shrine. Skip the shrine if you left Delgren's chain for later."),
    objective(973, ash(nil, 25.28, 60.69), "Kill Ilkrud Magthrull for the tome. Interrupt his summon if you can and clear space to retreat before pulling.", "Ilkrud Magthrull's Tome"),
    action("goto", maestra, "Return to the road before heading north to Maestra's Post."),
    finish(973, delgren),
    action("hearth", kimlya, "Head back to Astranaar for the last turn-in.", ashHearth), finish(1034, pelturas),
    action("grind", kimlya, "Level 22 is a good point to enter Stonetalon. Finish an open hunt or take one of the suggested routes for more experience.",
      { level = 22, suggest = { "lakeshire", "wetlands-early", "duskwood", "stonetalon" } }),
  })

q(1070, "On Guard in Stonetalon", 21, 17)
q(1085, "On Guard in Stonetalon", 21, 17, 1070)
q(1071, "A Gnome's Respite", 21, 17, 1085)
q(1093, "Super Reaper 6000", 21, 16)
q(1056, "Journey to Stonetalon Peak", 18, 18)
q(1134, "Pridewings of Stonetalon", 21, 18, 1008)
q(86574, "Stonetalon Supply Run", 24, 20, nil, true)
q(1057, "Reclaiming the Charred Vale", 27, 20)
B.breadcrumb(1056, 1057)
-- Gaxim's letters for the Eastern Kingdoms (gap fill, see the 2026-11-10 audit).
q(1072, "An Old Colleague", 21, 17, 1071)
q(1075, "A Scroll from Mauren", 21, 17, 1071)
-- Piznik's ore for Ziz (both factions; tools/audits/2026-11-12-alliance-kalimdor-loch-modan.md).
q(1090, "Gerenzo's Orders", 22, 17)
q(1092, "Gerenzo's Orders", 22, 17, 1090)

local kaela = stone("Kaela Shadowspear", 59.9, 66.85)
local gaxim = stone("Gaxim Rustfizzle", 59.52, 67.15)
local ziz = stone("Ziz Fizziks", 58.99, 62.6)
local courier = stone("Night Elf Courier", 48.69, 39.89)
local albagorm = stone("Keeper Albagorm", 37.1, 8.1)
local teloren = stone("Teloren", 36.44, 7.18)
local faralia = stone("Innkeeper Faralia", 35.79, 5.73)

chapter("stonetalon", "Stonetalon Mountains", stonetalon, 22, 28, {
  "https://bindonforever.com/zones/stonetalon-mountains",
  "https://www.wowhead.com/forever/quest=86574/stonetalon-supply-run",
}, { "ashenvale-late", "wetlands-early", "duskwood", "redridge-late", "wetlands" }, {
  taxi("getfp", astranaar, astranaarFlight, "Start in Astranaar. From Darkshore, follow the road south through Maestra's Post."),
  accept(1070, ash("Sentinel Thenysil", 34.89, 49.79)),
  accept(1056, ash("Faldreas Goeth'Shael", 35.76, 49.1)),
  accept(1008, shindrell, "If you did the Ashenvale coast loop, this is already done. Otherwise you can gather the heads now or use Next to skip the Pridewing venom pickup."),
  action("goto", maestra, "Follow the road northwest toward the coast if you still need Wrathtail heads."),
  objective(1008, ash(nil, 14.88, 22.47), "Take the northwestern road past Maestra's Post and hunt Wrathtail naga on the Zoram Strand.", "20 Wrathtail Heads"),
  action("goto", shindrell, "Return by the Maestra's Post road to Astranaar."),
  finish(1008, shindrell, "Return by the Maestra's Post road to Astranaar."),
  accept(1134, shindrell),
  action("goto", talondeep, "Take the south road toward Stardust and use Talondeep Path, the tunnel through the hills into Stonetalon."),
  finish(1070, kaela, "Take the path up from the Stonetalon end of the tunnel to Kaela's overlook."), accept(1085, kaela),
  finish(1085, gaxim), accept(1071, gaxim), accept(1093, ziz),
  along(objective(1071, stone(nil, 66.6, 55), "Follow the path north into Windshear Crag. Kill Loggers and Deforesters while working toward the machines.",
    "10 Venture Co. Loggers", "10 Venture Co. Deforesters"), 1093),
  along(objective(1093, stone(nil, 74.3, 54.7), "Loot the blueprints from Venture Co. Operators near the equipment. Finish any missing Venture Co. kills before returning.",
    "Super Reaper 6000 Blueprints"), 1071),
  -- Piznik works a side tunnel of Windshear Mine, on the way back to Ziz.
  accept(1090, stone("Piznik", 71.87, 60.0), "On the way back south, look for Piznik in a short side tunnel just inside Windshear Mine. He wants guarding while he mines an ore sample."),
  objective(1090, stone("Piznik", 71.87, 60.0), "Stay beside Piznik and kill the kobolds that attack in waves until he finishes mining. It takes a few minutes.",
    "Piznik guarded while he mines"),
  finish(1090, stone("Piznik", 71.87, 60.0), "Take the ore sample from Piznik."),
  accept(1092, stone("Piznik", 71.87, 60.0), "Piznik wants the ore taken to Ziz Fizziks."),
  finish(1093, ziz), finish(1092, ziz, "Give Ziz the ore sample as well."), finish(1071, gaxim),
  accept(1072, gaxim, "Gaxim has a letter for Lomac Gearstrip in Ironforge. Carry it until you next cross to the Eastern Kingdoms."),
  accept(1075, gaxim, "Take his scroll for Collin Mauren in Stormwind as well."),
  action("goto", courier, "Take the main road north toward Mirkfallon Lake. Stay clear of Sun Rock Retreat, the Horde town to the west."),
  check(accept(86574, courier, "Look for the Night Elf Courier by the road. If the courier has no quest for you, use Next and continue to the peak."),
    "Confirm that the courier offers the supply run at level 20 or above."),
  along(objective(86574, stone(nil, 51.26, 42.02), "Hunt wyverns and consorts around the lake for the courier's bundles. Leave the rare elite alone.", "6 Stonetalon Supply Bundles"), 1134),
  along(objective(1134, stone(nil, 54.6, 38.1), "Loot venom sacs from the same Pridewings. Finish any missing sacs before following the road up to the peak.", "12 Pridewing Venom Sacs"), 86574),
  taxi("getfp", teloren, "Stonetalon Peak, Stonetalon Mountains", "Follow the road north to Stonetalon Peak and learn the flight path."),
  finish(1056, albagorm), finish(86574, faralia),
  action("grind", faralia, "The Charred Vale is a better solo trip around level 25. Switch routes for now, or use Next if you can handle the harpies.",
    { level = 25, suggest = { "ashenvale-late", "wetlands-early", "duskwood", "redridge-late" } }),
  accept(1057, albagorm, "Take the harpy hunt if Albagorm offers it. Pull from the edges, or use Next to leave the Vale for later."),
  objective(1057, stone(nil, 33.1, 65.9), "Follow the road toward the Charred Vale and give Sun Rock Retreat a wide berth. Start with Harpies and Ambushers to the north, then move south for Slayers and Roguefeathers.",
    "Bloodfury Harpies", "Bloodfury Ambushers", "Bloodfury Slayers", "Bloodfury Roguefeathers"),
  action("goto", albagorm, "Follow the main road back north to Stonetalon Peak."), finish(1057, albagorm),
  taxi("fly", astranaar, astranaarFlight, "Fly back to Astranaar. On foot, take Talondeep Path back through the hills."),
  finish(1134, shindrell),
  -- Gaxim's letters: delivered when you leave Kalimdor (the ship from Auberdine goes to Stormwind).
  taxi("fly", at("Caylais Moonfeather", 36.34, 45.58, M.darkshore), "Auberdine, Darkshore",
    "When you head back east, fly from Astranaar to Auberdine or follow the road north through Maestra's Post."),
  action("boat", at("Thamarian", 32.67, 42.11, M.darkshore),
    "Take the Stormwind ship from Auberdine's south pier. Use Next in Stormwind Harbor.",
    { name = "Auberdine - Stormwind Harbor" }),
  finish(1075, at("Collin Mauren", 53.01, 86.63, M.stormwind), "Give Gaxim's scroll to Collin Mauren in Stormwind. His follow-ups send you to Westfall and back to Stonetalon."),
  finish(1072, at("Lomac Gearstrip", 72.09, 51.88, M.ironforge),
    "Take the Deeprun Tram to Ironforge and give the letter to Lomac Gearstrip in Tinker Town. His follow-up needs potions from an alchemist."),
})

q(1025, "An Aggressive Defense", 24, 18, 1023)
q(1016, "Elemental Bracers", 24, 20)
q(1024, "Raene's Cleansing", 21, 18, 1023)
q(1026, "Raene's Cleansing", 27, 18, 1024)
q(1027, "Raene's Cleansing", 28, 18, 1026)
q(1028, "Raene's Cleansing", 28, 18, 1027)
q(1055, "Raene's Cleansing", 28, 18, 1028)
q(1029, "Raene's Cleansing", 28, 18, 1055)
q(1030, "Raene's Cleansing", 28, 18, 1029)
q(1045, "Raene's Cleansing", 30, 18, 1030)
q(1046, "Raene's Cleansing", 30, 18, 1045)
q(4581, "Kayneth Stillwind", 29, 24)
q(1011, "Forsaken Diseases", 29, 24, 4581)
q(98027, "Gleaming Crescent Necklace", 26, 25, nil, true)
q(1022, "The Howling Vale", 30, 25)
-- Gap fill (2026-11-10 audit). The game also wants The Ruins of Stardust (1034) for Fallen Sky
-- Lake and Delgren's tower chain (973) for 1140: both finish in the early Ashenvale chapter, so
-- this chapter keeps no chain for them and its pickups say to use Next when they aren't offered.
q(1035, "Fallen Sky Lake", 30, 20)
q(1140, "The Tower of Althalaxx", 28, 13)
q(1021, "Vile Satyr! Dryads in Danger!", 32, 26)
q(1031, "The Branch of Cenarius", 32, 26, 1021)
-- Forever's Forest Song pair (Maseara Autumnmoon): the scroll at Satyrnaar, then the Xavian satyrs.
q(98417, "Vengeful Trail", 30, nil, nil, true)
q(98418, "Shared Fury", 30, nil, 98417, true)
q(1037, "Velinde Starsong", 30, 25, 1022)
q(1038, "Velinde's Effects", 30, 25, 1037)

local velene = ash("Sentinel Velene Starstrike", 49.8, 67.21)
local shael = ash("Shael'dryn", 53.54, 46.29)
local shrine = ash("Hidden Shrine", 56.38, 49.23)
local krolg = ash("Krolg", 50.84, 75.08)
local kayneth = ash("Kayneth Stillwind", 85.24, 44.71)
local melyria = ash("Sentinel Melyria Frostshadow", 22.23, 52.98)
local illiyana = ash("Illiyana", 21.73, 53.35)
local anilia = ash("Anilia", 78.32, 44.82)
local thyntel = at("Thyn'tel Bladeweaver", 61.78, 39.19, M.darnassus)
-- One objective of a multi-part quest (the quest log's objective index).
local function part(step, index)
  step.objectiveIndex = index
  return step
end
chapter("ashenvale-late", "Ashenvale: Raynewood and Forest Song", ashenvale, 24, 30, ashSources,
  { "wetlands", "southshore", "duskwood-late", "redridge-late", "stonetalon" }, {
    taxi("getfp", astranaar, astranaarFlight, "Return to Astranaar. Fly from Stonetalon Peak or walk back through Talondeep Path."),
    -- Shindrell stands beside the flight point: take Kayneth's letter before the inn and Raene
    -- (2026-11-12 loop check).
    accept(4581, shindrell, "Shindrell Swiftfire, beside the flight point, has a letter for Kayneth Stillwind in Forest Song from level 24."),
    action("sethearth", kimlya, "Bind at the Astranaar inn for the eastern circuits.", ashHearth),
    findTeronis, reachTeronis, takeGemQuest, lootGem, finish(1023, raene),
    accept(1025, raene), accept(1024, raene),
    action("goto", velene, "Cross the east bridge and follow the south road to Silverwind Refuge, near Lake Mystral."),
    accept(1016, velene),
    B.withItem(5456, objective(1016, ash(nil, 48.17, 69.74),
      "Loot five intact bracers from Befouled Water Elementals at the lake edge, then use the Divining Scroll. Stay out of deep water and avoid Tideress.", "Divined Scroll")),
    finish(1016, velene),
    objective(1025, ash(nil, 52.4, 62.8), "Work the furbolg camp northeast of the lake. Pull Den Watchers and Ursas singly and clear Warriors if the Totemics are scarce.",
      "1 Foulweald Den Watcher", "2 Foulweald Ursas", "10 Foulweald Totemics", "12 Foulweald Warriors"),
    action("hearth", kimlya, "Return to Astranaar by hearth or the main road for Raene's turn-in.", ashHearth), finish(1025, raene),
    action("grind", kimlya, "Reach level 25 for the late Ashenvale pickups. If the eastern camps are too hard, finish another chapter first.",
      { level = 25, suggest = { "stonetalon", "wetlands-early", "duskwood", "redridge-late" }, guide = "seeking-caitlin" }),
    action("goto", melyria, "Head west to the Shrine of Aessina and ask Sentinel Melyria about the vale."),
    check(accept(1022, melyria, "Pick up the study quest for the northeast. If Melyria is not at the shrine, check the quest marker on your map."),
      "Recorded spawns place Melyria at the Shrine of Aessina. Some quest text names Forest Song."),
    action("goto", ash(nil, 50.22, 56.23), "Take the road east past Astranaar, then turn north for the moonwell path near Raynewood Retreat."),
    finish(1024, shael, "Find Shael'dryn by the moonwell. She walks around the clearing."), accept(1026, shael),
    objective(1026, ash("Worn Chest", 54.41, 35.39), "Loot a Wooden Key from Withered or Crazed Ancients north of Raynewood, then open the Worn Chest for the shaft.", "Iron Shaft"),
    action("goto", ash(nil, 54.17, 32.34), "Look for the hillside tunnel into the Howling Vale northwest of the Worn Chest."),
    objective(1022, ash("Tome of Mel'Thandris", 50.49, 39.13), "Read the tome inside the vale. Pull the worgen away from the cave mouth a few at a time.", "Tome of Mel'Thandris read"),
    action("goto", ash(nil, 51.33, 38.2), "Leave through the tunnel and return to the moonwell."),
    finish(1026, shael), accept(1027, shael),
    action("goto", kayneth, "Follow the east road to Forest Song. Keep clear of Splintertree Post, the Horde outpost south of the road."),
    finish(4581, kayneth), accept(1011, kayneth),
    along(objective(1011, ash("Bottle of Disease", 75.29, 72.22), "Go south to Felfire Hill. Pick up the bottle and kill nearby slimes for Raene's chain while you are here.", "Bottle of Disease"), 1027),
    along(objective(1027, ash(nil, 73.8, 73.8), "Kill Rotting Slimes and look for a Rusty Chest left on the ground. Open it for the Iron Pommel.", "Iron Pommel"), 1011),
    action("goto", kayneth, "Return east by the road for the disease turn-in."), finish(1011, kayneth),
    action("goto", shael, "Return west to the Raynewood moonwell by the road and the hillside path."),
    finish(1027, shael), accept(1028, shael),
    action("goto", ash(nil, 56.04, 51.28), "Take the winding path up the mountain to the Hidden Shrine."),
    finish(1028, shrine), accept(1055, shrine),
    finish(1055, shael), accept(1029, shael),
    action("hearth", kimlya, "Return to Astranaar with the rod.", ashHearth),
    finish(1029, raene),
    accept(1035, pelturas, "If you finished The Ruins of Stardust, Pelturas has one more task at Fallen Sky Lake. Otherwise use Next."),
    action("grind", kimlya, "Come back for Ran Bloodtooth around level 28 or with a partner. Finish an open route if you need more experience.",
      { level = 28, suggest = { "duskwood-late", "wetlands", "redridge-late", "southshore" } }),

    -- The last circuit: west for new orders, then one sweep east from Lake Mystral to Xavian.
    accept(1030, raene, "Before you leave Astranaar: take this only if you want to finish the rod chain. The last hand-in takes the transformation rod."),
    action("goto", melyria, "Follow the road west of Astranaar to the Shrine of Aessina."),
    finish(1022, melyria), accept(1037, melyria, "Melyria sends you to Darnassus about Velinde. You go there at the end of this chapter."),
    accept(1021, illiyana, "Illiyana, beside Melyria, sends you to the dryad Anilia in Xavian, the satyr camp in the far north-east."),
    accept(1140, delgren, "Go north to Maestra's Post. If you finished Delgren's tower chain, he wants two trapped souls freed in the east. Otherwise use Next."),
    action("goto", ash(nil, 50.22, 56.23), "Head back south past Astranaar and take the east road toward Lake Mystral."),
    B.withItem(5462, finish(1030, krolg, "Find Krolg southeast of Lake Mystral and use Dartol's Rod of Transformation before speaking to him.")),
    B.withItem(5462, accept(1045, krolg, "Speak to Krolg in furbolg form.")),
    objective(1045, ash(nil, 54.75, 79.62), "Find Ran Bloodtooth southeast of the lake and loot his skull. Pull his guards separately and use Next if you need help with the camp.",
      "Ran Bloodtooth's Skull", "4 Bloodtooth Guards"),
    B.withItem(5462, finish(1045, krolg, "Use the rod again to speak to Krolg in furbolg form.")),
    B.withItem(5462, accept(1046, krolg, "Take Krolg's final delivery while in furbolg form.")),
    objective(1035, ash("Shadethicket Oracle", 66.7, 82.2),
      "Follow the south road east to Fallen Sky Lake. Kill the Shadethicket Oracle, level 30, on the shore and loot the Fallen Moonstone.", "Fallen Moonstone"),
    -- The pendant lies between Fallen Sky Lake and Night Run, so it waits for this circuit
    -- instead of a detour south from Forest Song (2026-11-12 loop check).
    check(accept(98027, ash("Gleaming Crescent Pendant", 62.99, 71.55), "On the way north to Night Run, look for the pendant in the water at 63.0, 71.6. Use Next if the object is missing."),
      "Confirm the pendant appears at level 25."),
    along(part(objective(1140, ash("Circle of Imprisonment", 66.6, 57.0),
      "Go north to Night Run and use the Circle of Imprisonment. Watch for Felmusk satyrs in stealth.", "Free the Highborne soul in Night Run"), 1), 1021),
    action("goto", ash("Maseara Autumnmoon", 86.24, 45.86), "Follow the road east to Forest Song. Learn the flight path there if you can."),
    accept(98417, ash("Maseara Autumnmoon", 86.24, 45.86), "Maseara Autumnmoon in Forest Song is looking for her husband Kurothel."),
    part(objective(1140, ash("Circle of Imprisonment", 81.6, 48.6), "Go west to Satyrnaar and use the circle there to free the second soul.",
      "Free the Highborne soul in Satyrnaar"), 2),
    objective(98417, ash("Vine-Wrapped Scroll", 80.92, 49.63), "Search just south-west of the circle for the Vine-Wrapped Scroll.", "Vine-Wrapped Scroll"),
    finish(98417, ash("Maseara Autumnmoon", 86.24, 45.86), "Bring the scroll back east to Maseara."),
    accept(98418, ash("Maseara Autumnmoon", 86.24, 45.86)),
    finish(1021, anilia, "Go west to Xavian. Anilia hides at the edge of the satyr camp."),
    accept(1031, anilia),
    along(objective(1031, ash("Geltharis", 78.0, 42.4), "Kill Geltharis, level 32, in Xavian for the Branch of Cenarius. Pull his guards first, bring a partner or use Next.",
      "Branch of Cenarius"), 98418),
    objective(98418, ash(nil, 78.8, 45.8), "Finish the Xavian Rogues, Felsworn, Betrayers and Hellcallers around the camp.",
      "5 Xavian Rogues", "5 Xavian Felsworn", "5 Xavian Betrayers", "5 Xavian Hellcallers"),
    finish(98418, ash("Maseara Autumnmoon", 86.24, 45.86), "Return east to Maseara in Forest Song."),
    action("hearth", kimlya, "Return to Astranaar. On foot, take the main road west past Forest Song.", ashHearth),
    finish(1046, raene), finish(98027, ash("Maliynn", 36.62, 49.98), "Maliynn, next to Raene, takes the pendant."),
    finish(1035, pelturas),
    action("goto", illiyana, "Ride west to the Shrine of Aessina."), finish(1031, illiyana),
    action("goto", maestra, "Follow the road north to Maestra's Post."), finish(1140, delgren),
    taxi("fly", at("Caylais Moonfeather", 36.34, 45.58, M.darkshore), "Auberdine, Darkshore",
      "For Velinde's chain, fly from Astranaar to Auberdine or follow the road north from Maestra's Post."),
    taxi("fly", at("Vesprystus", 58.4, 94.02, M.teldrassil), "Rut'theran Village, Teldrassil",
      "Fly on to Rut'theran Village, or take the ferry from Auberdine's north pier."),
    action("goto", nil, "Take the portal beside the Rut'theran pier up to Darnassus. Use Next when you arrive."),
    finish(1037, thyntel, "Find Thyn'tel Bladeweaver on the Warrior's Terrace."), accept(1038, thyntel),
    objective(1038, at("Velinde's Locker", 62.3, 83.3, M.darnassus), "Search Velinde's Locker in her old home in the south-east of the city for her journal.",
      "Velinde's Journal"),
    finish(1038, thyntel, "Bring the journal back to Thyn'tel. His next quest goes to Ratchet in the Barrens; leave it."),
    action("grind", astranaar, "If you still need level 30, finish a suggested chapter or run Blackfathom Deeps with a group.",
      { level = 30, suggest = { "wetlands", "southshore", "duskwood-late", "redridge-late" }, guide = "dungeon-blackfathom-deeps" }),
  })

q(484, "Young Crocolisk Skins", 22, 18)
-- The game also wants the fossil delivery (942), which ends the Darkshore chapter in Menethil,
-- so this chapter keeps no chain for Flagongut's follow-up and its pickup says to use Next.
q(943, "The Absent Minded Prospector", 24, 15)

local rethiel = wet("Rethiel the Greenwarden", 56.37, 40.4)
local helbrek = wet("Innkeeper Helbrek", 10.7, 61)
local karl = wet("Karl Boran", 8.32, 58.57)
local halloran = wet("James Halloran", 8.55, 55.74)
local valstag = wet("Valstag Ironjaw", 10.1, 56.9)
local stoutfist = wet("Captain Stoutfist", 9.86, 57.49)
local fitz = wet("First Mate Fitzsimmons", 10.9, 59.64)
local caitlin = wet("Caitlin Grassman", 11.88, 58.82)
local sida = wet("Sida", 11.8, 57.99)
local tarrel = wet("Tarrel Rockweaver", 11.5, 52.17)
local damagedCrate = wet("Damaged Crate", 13.52, 41.38)
local sealedBarrel = wet("Sealed Barrel", 13.6, 38.22)
local buriedBarrel = wet("Half-buried Barrel", 13.94, 34.81)
local flagongut = wet("Archaeologist Flagongut", 10.84, 60.43)
local ormer = wet("Ormer Ironbraid", 38.18, 50.89)
local merrin = wet("Merrin Rockweaver", 38.91, 52.34)
local whelgar = wet("Prospector Whelgar", 38.81, 52.39)
local menethilHearth = { bind = "Menethil Harbor" }

-- The Greenwarden is optional in the 26-30 route (it starts in Menethil, which that route reaches
-- late). Here every loop starts in Menethil, so the breadcrumb is a normal step.
local function always(step)
  step.optional = nil
  return step
end

-- The target button's creatures for a Forever drop the quest data doesn't list.
local function targets(step, ...)
  step.mobs = { ... }
  return step
end

-- Spots the arrow visits in turn, for objects scattered over one camp.
local function tour(step, ...)
  step.points = { ... }
  return step
end

-- Menethil first: the Darkshore chapter's ship lands there, and the town gives every pickup for
-- both coast loops and the one eastern trip. Notes: tools/audits/2026-11-11-wetlands-early.md,
-- tools/audits/2026-11-12-wetlands-early-dig.md (the dig's second round: Ormer and Whelgar).
chapter("wetlands-early", "Wetlands: The Green Belt and Coast", M.wetlands, 20, 25, {
  "https://bindonforever.com/zones/wetlands",
  "https://games.gg/world-of-warcraft/guides/wow-forever-wetlands-leveling-guide/",
  "https://www.wowhead.com/forever/quest=484/young-crocolisk-skins",
}, { "duskwood", "redridge-late", "ashenvale-late", "wetlands", "duskwood-late" }, {
  -- Menethil Harbor: flight path, bind and the pickups, in walking order.
  taxi("getfp", menethil, menethilFlight,
    "Start in Menethil Harbor: the Auberdine ship docks here. Walking from Loch Modan, follow the road from Dun Algaz west past the Green Belt; you come back east later. Learn the flight path."),
  action("sethearth", helbrek, "Bind at the Deepwater Tavern. Every loop in this chapter ends back here.", menethilHearth),
  accept(943, flagongut, "If you brought Remtravel's fossil, Flagongut upstairs in the tavern wants two finds from the Whelgar dig. Otherwise use Next."),
  always(accept(463, fitz, "First Mate Fitzsimmons, outside the tavern, sends you to Rethiel in the Green Belt. You go there on the eastern trip.")),
  accept(98282, caitlin, "Caitlin Grassman wants a gland from the stalkers in Thelgen Rock, on the eastern trip."),
  accept(470, sida, "Sida's bag is inside one of the oozes at Ironbeard's Tomb, also on the eastern trip."),
  accept(98197, valstag, "Valstag Ironjaw is in Menethil Keep."),
  accept(279, karl, "Karl Boran is on the docks."),
  check(accept(484, halloran, "Ask Halloran, by the north gate, for the skin hunt. Use Next if he does not offer it."),
    "Check whether Halloran offers this on a first visit to Menethil."),
  finish(98461, tarrel, "Give Hollee's note to Tarrel Rockweaver on the north bridge."),
  accept(305, tarrel, "Tarrel wants news of his sister Merrin at the Whelgar dig. You pass her on the way back west."),

  -- First coast loop: the harbor, the murlocs and the young crocolisks.
  objective(98197, wet(nil, 12.1, 52.5), "Gather the sunken timber and iron in the harbor water beside Tarrel's bridge. Surface for air between dives.",
    "6 Khaz Modan Timber", "30 Khaz Modan Iron"),
  along(objective(279, wet(nil, 15, 39.2), "Follow the coast north for Bluegill Murlocs. Gobbler walks with them near 18, 40: clear his guards before pulling him.",
    "12 Bluegill Murlocs", "Gobbler's Head"), 484),
  objective(484, wet(nil, 19.15, 47.12), "On the way back south, kill Young Wetlands Crocolisks in the marsh channels east of the beach. More sit just outside town near 15, 54.",
    "6 Young Crocolisk Skins"),
  finish(484, halloran, "Back at the north gate, give Halloran the skins. His next order is for the later Wetlands chapter."),
  finish(98197, valstag), finish(279, karl), accept(281, karl),

  -- Second coast loop: Karl's statuette from the murloc huts, then the captain.
  finish(281, damagedCrate, "Go back up the coast to the Damaged Crate in the murloc camp."), accept(284, damagedCrate),
  finish(284, sealedBarrel), accept(285, sealedBarrel),
  finish(285, buriedBarrel), accept(286, buriedBarrel),
  finish(286, karl, "Return south to Karl in Menethil with the statuette."),
  accept(98189, karl),
  finish(98189, stoutfist, "Captain Stoutfist is upstairs in Menethil Keep. His errand to Stormwind belongs to the later Wetlands chapter."),

  -- The eastern trip: the Green Belt, Thelgen Rock and the Mosshide camps, then the dig on the way back.
  action("goto", rethiel, "Take the road east out of Menethil, past the Whelgar dig. Keep to the road past the Dragonmaw at Angerfang, then find Rethiel among the trees east of the crossroads."),
  always(finish(463, rethiel)), accept(276, rethiel),
  targets(objective(98282, wet(nil, 52.6, 62.9),
    "Follow the road south toward Dun Algaz to Thelgen Rock, the cave beside the road. Kill Leech and Cave Stalkers inside until one drops the gland.",
    "Unruptured Stalker Gland"), "Leech Stalker", "Cave Stalker"),
  objective(276, wet(nil, 63, 66.1), "Cross east to the Mosshide camps. Kill Gnolls and Mongrels; more camps lie south near 62, 72.",
    "15 Mosshide Gnolls", "10 Mosshide Mongrels"),
  finish(276, rethiel, "Go back north to Rethiel."), accept(277, rethiel),
  objective(277, wet(nil, 44.3, 34.0), "Head north-west, north of Angerfang, to the Mosshide camp by the stream. Fenrunners, Trappers and Mistweavers drop the flint.",
    "9 Crude Flint"),
  objective(470, wet(nil, 44.9, 26.1), "Continue north to Ironbeard's Tomb. Kill oozes until one drops Sida's Bag; the Black Oozes are the easiest.", "Sida's Bag"),
  finish(277, rethiel, "Return south-east to Rethiel. His next quest, Blisters on the Land, is for the later Wetlands chapter."),
  accept(294, ormer, "Follow the road west, past Angerfang, to Ormer Ironbraid at the Whelgar Excavation Site."),
  finish(305, merrin, "Merrin Rockweaver is in the dig's cave."), accept(306, merrin),
  accept(299, whelgar, "Prospector Whelgar, beside Merrin, wants four tablet fragments from the dig you cross on the way west."),
  part(objective(943, wet("Flagongut's Fossil", 38.9, 52.2), "Pick up Flagongut's Fossil in the same cave.", "Flagongut's Fossil"), 2),
  along(objective(294, wet(nil, 26.3, 46.1),
    "Go west to the raptor fields. Kill Mottled Raptors and the tougher Screechers. On the way through the dig, loot any Ancient Relic or Loose Soil you pass; the rest wait for Ormer's next hunt.",
    "10 Mottled Raptors", "10 Mottled Screechers"), 943, 299),
  along(part(objective(943, wet(nil, 26.3, 46.1), "Mottled raptors of any kind can drop the Stone of Relu. Keep hunting until it drops.", "Stone of Relu"), 1), 294),
  action("grind", wet(nil, 26.3, 46.1),
    "Ormer's next hunt and the rest of Whelgar's fragments are among level 25-27 raptors in the dig. Below level 24, keep hunting raptors here first, or use Next and pull with care.",
    { level = 24 }),
  finish(294, ormer, "Return to Ormer. If Whelgar had no quest for you on the way in (it needs level 24), take Uncovering the Past from him in the cave now."),
  accept(295, ormer, "Ormer's next hunt is in the dig itself: Mottled Scytheclaws (25-26) and Razormaws (26-27), among Whelgar's fragments."),
  along(tour(objective(299, wet(nil, 34.6, 47.5),
    "Search the dig west of the cave for the fragments you still need: three Ancient Relics and a patch of Loose Soil hold them. Pull the raptors one at a time. Sarltooth, level 29, roams the south end near 33, 51: stay clear of him.",
    "Ados Fragment", "Modr Fragment", "Golm Fragment", "Neru Fragment"), { 34.6, 45.6 }, { 34.7, 48.3 }, { 34.2, 50.4 }, { 35.2, 51.4 }), 295),
  along(objective(295, wet(nil, 33.9, 47.5), "Finish the Scytheclaws and Razormaws in the dig. Avoid Sarltooth at the south end.",
    "10 Mottled Scytheclaws", "10 Mottled Razormaws"), 299),
  finish(295, ormer, "Return to Ormer. His last hunt, Sarltooth, is for the later Wetlands chapter."),
  finish(299, whelgar, "Bring the fragments to Whelgar in the cave. His next quest needs a group for the Goaz Warder: leave it."),

  -- Back in Menethil: the turn-ins and the captain's mead.
  action("hearth", helbrek, "Hearth to Menethil Harbor, or follow the road west.", menethilHearth),
  finish(943, flagongut),
  accept(288, fitz, "From level 22: First Mate Fitzsimmons wants a drink."),
  objective(288, helbrek, "Buy a Flagon of Dwarven Honeymead from Innkeeper Helbrek.", "Flagon of Dwarven Honeymead"),
  finish(288, fitz, "Bring the mead to Fitzsimmons. His next quest, The Cursed Crew, is for the later Wetlands chapter."),
  finish(98282, caitlin), finish(470, sida),
  finish(306, tarrel, "Tell Tarrel on the north bridge that you found Merrin."),
  action("grind", menethil, "If you are under level 23, finish an open route before the tougher Wetlands fights.",
    { level = 23, suggest = { "duskwood", "ashenvale-early", "stonetalon", "lakeshire" } }),
})

q(91, "Solomon's Law", 23, 17)
q(128, "Blackrock Bounty", 25, 20)
q(180, "Wanted: Lieutenant Fangore", 26, 15)
q(219, "Missing In Action", 25, 19)
q(34, "An Unwelcome Guest", 24, 18)
q(150, "Murloc Poachers", 20, 20)
q(169, "Wanted: Gath'Ilzogg", 26, 15)
q(95999, "WANTED: Incinerator Gar'im", 25, 20, nil, true)
-- The game also wants Blackrock Menace (20) for Marris's two and A Baying of Gnolls (124) for
-- Verner's: both are in the main Lakeshire route, so this chapter keeps no chain and says so.
q(19, "Tharil'zun", 25, 18)
q(115, "Shadow Magic", 23, 18)
q(126, "Howling in the Hills", 25, 15)
-- Theocritus is on the Elwynn road: an optional pickup for players who ride in from Stormwind.
q(94, "A Watchful Eye", 21, 20)
q(248, "Looking Further", 22, 20, 94)
B.quest[94].optional, B.quest[248].optional = true, true

local guardHowe = rr("Guard Howe", 26.45, 57.86)
local conacher = rr("Bailiff Conacher", 24.62, 44.27)
local marris = rr("Marshal Marris", 28.42, 48.97)
local solomon = rr("Magistrate Solomon", 24.9, 44.46)
local martie = rr("Martie Jainrose", 16.77, 46.33)
local baren = rr("Dockmaster Baren", 22.63, 47.38)
local verner = rr("Verner Osgood", 25.88, 47.27)
local lionStatue = rr("Old Lion Statue", 79.4, 46.83)
local brianna = rr("Innkeeper Brianna", 22, 44.5)
local keeshan = rr("Corporal Keeshan", 23.3, 12.55)
local lakeshireHearth = { bind = "Lakeshire" }

chapter("redridge-late", "Lakeshire: Shadowhide and Blackrock", M.redridge, 23, 29, {
  "https://bindonforever.com/zones/redridge-mountains",
  "https://www.wowhead.com/forever/quest=128/blackrock-bounty",
  "https://www.wowhead.com/forever/quest=180/wanted-lieutenant-fangore",
  "https://www.wowhead.com/forever/quest=95999",
}, { "duskwood-late", "duskwood", "wetlands-early", "wetlands", "southshore", "ashenvale-late" }, {
  accept(94, at("Theocritus", 65.22, 69.71, M.elwynn),
    "Riding in from Stormwind? Climb to the top of the Tower of Azora beside the Elwynn road and speak to Theocritus."),
  taxi("getfp", lakeshire, "Lakeshire, Redridge", "Learn the Lakeshire flight path. From Stormwind, take the east road through Elwynn to Lakeshire."),
  accept(128, guardHowe, "Guard Howe stands a few steps from the gryphon master, south of the bridge."),
  accept(19, marris, "Cross the bridge into town. Marshal Marris offers these two after Blackrock Menace. Use Next on any he doesn't have."), accept(115, marris),
  accept(126, verner, "Verner offers this after A Baying of Gnolls. Use Next if he doesn't have it."),
  accept(169, rr("Wanted: Gath'Ilzogg", 24.53, 46.16), "Read the Gath'Ilzogg wanted poster by the town hall."),
  accept(95999, rr("Wanted: Incinerator Gar'im", 24.37, 46.27), "Read the Incinerator Gar'im poster beside it."),
  accept(91, conacher),
  action("sethearth", brianna, "Bind at Lakeshire for the two trips out of town.", lakeshireHearth),
  accept(180, rr("Wanted Poster", 21.66, 46.47), "Read the Fangore wanted poster a few steps south of the inn."),
  accept(150, baren),
  accept(34, martie),
  objective(34, rr("Bellygrub", 10.6, 49.3),
    "Bellygrub is a tough boar near the road west of town. Pull it alone, bring a partner, or use Next.", "Bellygrub's Tusk"),
  finish(34, martie),
  objective(150, rr(nil, 35.9, 47.4),
    "Kill the murlocs on the shore just east of town for fins. More gather along the lake around 52.2, 52.9.", "8 Murloc Fins"),
  action("goto", rr(nil, 62.2, 44.2), "Take the road east around the north shore of the lake toward the Shadowhide camps."),
  along(objective(91, rr(nil, 72.5, 40.92), "Loot Shadowhide pendants from the gnolls. Keep an eye out for Fangore on the paths through the camp.", "10 Shadowhide Pendants"), 180),
  along(objective(180, rr(nil, 75.07, 37.82), "Find Fangore in the eastern camp. Clear the paths first and use Next if his guards make the pull unsafe.", "Fangore's Paw"), 91),
  finish(94, lionStatue, "Head south-east to the Tower of Ilgalar and use the glyph at the lion statue."), accept(248, lionStatue),
  finish(248, rr("An Empty Jar", 58.16, 49.84), "Ride west to the intact watch tower beside Stonewatch Keep. Climb it and check the jar at the top."),
  along(objective(115, rr(nil, 63.2, 55.7), "Kill Blackrock Shadowcasters around Stonewatch Keep for their Midnight Orbs.", "3 Midnight Orbs"), 19, 169),
  along(check(objective(19, rr("Tharil'zun", 64.4, 59.4),
    "Tharil'zun stands at the south end of the keep. Clear his guards first and bring a partner if needed, or use Next.", "Tharil'zun's Head"),
    "Spawn point from the classic data; confirm it in Forever."), 115),
  along(objective(169, rr("Gath'Ilzogg", 64.5, 55.8),
    "Gath'Ilzogg (level 26) holds the inside of the keep with guards close by. Bring a group, or use Next.", "Head of Gath'Ilzogg"), 115),
  check(objective(95999, rr("Incinerator Gar'im", 72.8, 86.3),
    "Go south to Render's Valley. Incinerator Gar'im waits in the cave: a group fight. Use Next without one.", "Broken Staff of Incinerator Gar'im"),
    "Position converted from a published route; confirm the cave and whether a group is needed."),
  action("hearth", brianna, "Return west to Lakeshire for the turn-ins.", lakeshireHearth),
  finish(91, conacher), finish(180, solomon), finish(169, solomon), finish(95999, solomon),
  finish(150, baren), finish(19, marris), finish(115, marris),
  objective(126, rr("Yowler", 22.6, 21.4), "Follow the road north from town. Yowler runs with the gnolls in the hills along the way.", "Yowler's Paw"),
  action("goto", rr(nil, 28.12, 6.88), "Continue north and approach the Blackrock caves from the south. Avoid elite patrols near Stonewatch to the east."),
  objective(128, rr(nil, 28.12, 6.88), "Kill Champions outside or just inside the cave. Work near the exit if respawns are fast.", "15 Blackrock Champions"),
  accept(219, keeshan, "If you can keep the route clear, start Keeshan's escort inside the cave. Use Next if the cave is busy or the escort is unsafe."),
  objective(219, rr(nil, 28.32, 48.51), "Stay with Keeshan until he reaches Lakeshire. Let him take the lead so the escort updates.", "Corporal Keeshan escorted"),
  finish(219, marris), finish(126, verner),
  finish(128, guardHowe, "Turn in to Guard Howe by the gryphon master, south of the bridge."),
})

q(58, "The Night Watch", 30, 18, 57)
q(173, "Worgen in the Woods", 28, 23)
q(221, "Worgen in the Woods", 29, 23, 173)
q(222, "Worgen in the Woods", 31, 23, 221)
q(223, "Worgen in the Woods", 31, 23, 222)
-- Ogre Thieves needs Ghoulish Effigy (133) and the last Look To The Stars needs Mary's looking
-- glass (177), both in the main Duskwood route: no chain here, the pickup text says so.
q(134, "Ogre Thieves", 30, 20)
q(160, "Note to the Mayor", 30, 20, 134)
q(251, "Translate Abercrombie's Note", 30, 20, 160)
q(401, "Wait for Sirra to Finish", 30, 20, 251)
q(252, "Translation to Ello", 30, 20, 401)
q(181, "Look To The Stars", 30, 20)
q(79363, "Silvia's Sword", 26, 18, nil, true)
B.quest[79363].startItem = 281145
q(96138, "Merrick's Bow", 30, 18, nil, true)
B.quest[96138].startItem = 281142
-- Two talk quests on the last Raven Hill pass (tools/audits/2026-11-12-alliance-duskwood-wetlands.md).
-- Mor'Ladim (228), Althea's next, is a level 35 elite and stays out.
q(225, "The Weathered Grave", 35, 28)
q(227, "Morgan Ladimore", 35, 28, 225)

local trelayne = dw("Innkeeper Trelayne", 73.87, 44.41)
local althea = dw("Commander Althea Ebonlocke", 73.54, 46.82)
local calor = dw("Calor", 75.3, 48.05)
local abercrombie = dw("Abercrombie", 28.11, 31.46)
local ello = dw("Lord Ello Ebonlocke", 71.93, 46.42)
local sirra = dw("Sirra Von'Indi", 72.62, 47.62)
local viktori = dw("Viktori Prism'Antras", 79.8, 48.02)
local darkshireHearth = { bind = "Darkshire" }

chapter("duskwood-late", "Darkshire: Worgen and the Night Watch", M.duskwood, 25, 30, {
  "https://bindonforever.com/zones/duskwood",
  "https://www.wowhead.com/forever/quest=173/worgen-in-the-woods",
  "https://www.wowhead.com/forever/quest=58/the-night-watch",
}, { "wetlands", "southshore", "ashenvale-late", "redridge-late" }, {
  taxi("getfp", darkshire, "Darkshire, Duskwood", "Learn the Darkshire flight path. From Lakeshire, take the road west to Three Corners, then south and east into Darkshire."),
  action("sethearth", trelayne, "Bind at the Scarlet Raven Tavern for the loops west of Darkshire.", darkshireHearth),
  accept(56, althea), accept(173, calor),
  objective(56, dw(nil, 79.5, 70.5), "Clear the warriors and mages in Tranquil Gardens Cemetery if you still need the first Watch assignment.", "8 Skeletal Warriors", "6 Skeletal Mages"),
  objective(173, dw(nil, 62.4, 42.4), "Look for Nightbane Shadow Weavers in Brightwood Grove west of town. Fight away from the nearby worgen patrols.", "6 Nightbane Shadow Weavers"),
  finish(56, althea), accept(57, althea), finish(173, calor), accept(221, calor),
  objective(221, dw(nil, 67, 43.2), "Return to the trees just west of town for Nightbane Dark Runners.", "12 Nightbane Dark Runners"),
  action("goto", dw(nil, 21, 45), "Follow the main road west to Raven Hill, then head north to the cemetery. Stay clear of Mor'Ladim."),
  objective(57, dw(nil, 21, 45), "Clear the southern graves for the second Watch assignment.", "15 Skeletal Fiends", "15 Skeletal Horrors"),
  accept(134, abercrombie, "Walk north from the cemetery to Abercrombie's shack. He offers this after Ghoulish Effigy; use Next if he doesn't. Save it for the ogre mound later."),
  action("hearth", trelayne, "Return to Darkshire by hearth or the east road.", darkshireHearth),
  finish(57, althea), finish(221, calor),
  action("grind", trelayne, "The remaining worgen, ogres and Plague Spreaders are safer around level 28. Finish other quests first if you are below that.",
    { level = 28, suggest = { "wetlands", "redridge-late", "ashenvale-late", "southshore" } }),
  accept(58, althea), accept(222, calor),
  accept(181, viktori, "Viktori has one more task if you brought back Mary's looking glass. Use Next if he doesn't offer it."),
  objective(222, dw(nil, 73.03, 75.08), "Go south of town for Vile Fangs and Tainted Ones. Pull from the edge and leave if the camp is too dense.", "8 Nightbane Vile Fangs", "8 Nightbane Tainted Ones"),
  B.withItem(281145, accept(79363, nil, "Use Silvia's Sword from your bags. The Lost Defender ghost that drops it haunts Sven's old farm and the Rotting Orchard.")),
  B.withItem(281142, accept(96138, nil, "Use Merrick's Bow from your bags. The Lost Watcher ghost that drops it roams south of the road to Raven Hill.")),
  action("goto", dw(nil, 34.4, 75.5), "Head west along the south of the forest to the Vul'Gol Ogre Mound. Kill any Defias you pass at Sven's old farm."),
  along(objective(134, dw("Abercrombie's Crate", 33.4, 76.3), "Take Abercrombie's crate from inside the ogre mound.", "Abercrombie's Crate"), 96138, 181),
  along(objective(96138, dw(nil, 34.4, 75.5), "Kill Splinter Fist Warriors and Taskmasters in and around the mound.",
    "8 Splinter Fist Warriors", "4 Splinter Fist Taskmasters"), 134, 181),
  along(check(objective(181, dw("Zzarc' Vul", 36.5, 82.3),
    "Zzarc' Vul (level 33) waits at the back of the mound. Clear his room first and fight him with a partner, or use Next.", "Ogre's Monocle"),
    "Level from the classic data; confirm whether Forever made him elite."), 134, 96138),
  objective(79363, dw(nil, 22.5, 72.6), "Go west to Addle's Stead for Defias Night Blades and Enchanters. A few more stand at Sven's old farm.",
    "7 Defias Night Blades", "7 Defias Enchanters"),
  action("goto", dw(nil, 23.59, 34.89), "Go north to the main road, follow it west to Raven Hill, then enter the eastern side of the cemetery."),
  objective(58, dw(nil, 23.59, 34.89), "Look for Plague Spreaders around the eastern mausoleum. Stay near an exit if you need to go inside.", "20 Plague Spreaders"),
  accept(225, dw("A Weathered Grave", 17.73, 29.08),
    "Cross to the weathered grave at the north-west corner of the cemetery and read it. Mor'Ladim, a level 35 elite, walks these graves: let him pass first."),
  finish(134, abercrombie, "Bring the crate to Abercrombie's shack east of the cemetery."), accept(160, abercrombie),
  action("hearth", trelayne, "Return to Darkshire for the last turn-ins.", darkshireHearth),
  finish(58, althea), finish(222, calor), accept(223, calor), finish(223, dw("Jonathan Carevin", 75.32, 49.02)),
  finish(160, ello, "Lord Ello Ebonlocke is in the town hall."), accept(251, ello),
  finish(251, sirra), finish(79363, sirra), finish(96138, sirra),
  finish(225, sirra, "Tell Sirra about the weathered grave."), accept(227, sirra),
  accept(401, sirra), finish(401, sirra, "Wait a moment while Sirra translates, then speak to her again."), accept(252, sirra),
  finish(252, ello),
  finish(227, althea, "Commander Althea Ebonlocke is a few steps from Ello. Her next task, Mor'Ladim, is a level 35 elite: leave it."),
  finish(181, viktori),
})

q(536, "Down the Coast", 30, 25)
q(559, "Farren's Proof", 32, 25, 536)
q(560, "Farren's Proof", 32, 25, 559)
q(561, "Farren's Proof", 32, 25, 560)
q(562, "Stormwind Ho!", 32, 25, 561)
-- Forever's level 27 Southshore errands (Bind on Forever lists both as Alliance; no source gives
-- their objective spots yet): tools/audits/2026-11-12-alliance-duskwood-wetlands.md.
q(98059, "Hillsbrad's Hoard", 27, nil, nil, true)
q(98071, "Brewer's Trade", 27, 23, nil, true)

local darla = hill("Darla Harris", 49.34, 52.27)
local farren = hill("Lieutenant Farren Orinelle", 51.46, 58.39)
local redpath = hill("Marshal Redpath", 49.47, 58.73)
local bilger = hill("Brewmeister Bilger", 52.13, 58.74)

chapter("southshore", "Southshore: Coastal Patrols", hillsbrad, 27, 30, {
  "https://worldofwarcraft.blizzard.com/en-us/news/24304071/world-of-warcraft-forever-found-photos-panel-recap",
  "https://wowforever.gg/en/guides/travel-boats-zeppelins/",
  "https://bytetavern.com/wow-forever-flight-paths/",
  "https://bindonforever.com/zones/hillsbrad-foothills",
  "https://www.wowhead.com/forever/quest=98071",
  "https://www.wowhead.com/forever/quest=98059",
}, { "wetlands", "duskwood-late", "ashenvale-late" }, {
  taxi("getfp", darla, "Southshore, Hillsbrad", "Take the ship from Menethil Harbor's northern pier or Auberdine's west pier. Stay aboard until Southshore, then walk north through town to Darla Harris."),
  -- Level 27 errands first: the coast quests below want level 29.
  check(accept(98059, hill("Captain McManus", 46.43, 50.2),
    "Captain McManus, a short walk north-west of the flight master, has a sealed request for the Hillsbrad council. Use Next if he has nothing for you."),
    "A Forever quest: confirm Captain McManus offers it to the Alliance."),
  check(objective(98059, hill(nil, 29.5, 41.5),
    "Take the road west to Hillsbrad Fields. Place the Sealed Company Request on the bookkeeping table inside the town hall.",
    "Sealed Company Request delivered"),
    "The table's spot is the town hall's registry book from the quest data; confirm the table."),
  finish(98059, hill("Captain McManus", 46.43, 50.2), "Return to Captain McManus in Southshore."),
  finish(647, bilger, "Give MacKreel's moonshine to Brewmeister Bilger by the Southshore inn."),
  check(accept(98071, bilger,
    "Brewmeister Bilger, by the Southshore inn, wants a case of Fallrook Varietal taken to the dwarves of Dun Garok. Use Next if he has nothing for you."),
    "A Forever quest: confirm Bilger offers it to the Alliance."),
  check(objective(98071, hill(nil, 71.6, 80.0),
    "Follow the road south-east to the dwarven fort of Dun Garok. Leave the case by the fireplace at the bottom of the fort and take the sack of hops.",
    "Sack of Homebrew Hops"),
    "The spot is the middle of the fort's guards; confirm where the fireplace is."),
  finish(98071, bilger, "Bring the hops back to Bilger in Southshore."),
  finish(98219, farren, "Lieutenant Farren Orinelle is on the Southshore dock road, beside Bilger. Report to him for Lord Grayson."),
  accept(536, farren, "Lieutenant Farren Orinelle, on the dock road beside Bilger, wants the Torn Fin murlocs on the Western Strand thinned."),
  action("grind", farren, "The western murlocs are level 30 to 32. Try them around level 29 with a partner, or finish more quests before returning.",
    { level = 29, suggest = { "wetlands", "duskwood-late", "ashenvale-late" }, guide = "dungeon-city-of-dalaran" }),
  objective(536, hill(nil, 47.6, 64.6), "Work west from the docks along the Western Strand. Pull Tidehunters and Oracles to dry land and watch for adds from the surf.",
    "10 Torn Fin Tidehunters", "10 Torn Fin Oracles"),
  finish(536, farren), accept(559, farren),
  objective(559, hill(nil, 46.3, 65.6), "Loot heads from the same Torn Fin murlocs. Look for the lower-level Coastrunners and Muckdwellers farther west if Oracles are difficult.", "10 Murloc Heads"),
  finish(559, farren), accept(560, farren), finish(560, redpath), accept(561, redpath), finish(561, farren),
  action("grind", farren, "Save the eastern naga for level 30 or a group. You can switch chapters here or use Next to continue.",
    { level = 30, suggest = { "wetlands", "duskwood-late", "ashenvale-late" } }),
  accept(562, farren),
  objective(562, hill(nil, 55, 64.4), "Follow the shore east and fight Daggerspine naga from the beach. Pull Sirens alone to keep their spells manageable.",
    "10 Daggerspine Shorehunters", "10 Daggerspine Sirens"),
  finish(562, farren),
})

-- Navigation shortcuts. Known and connected flight paths take precedence at runtime.
local auberdinePier = at(nil, 32.4, 44.1, M.darkshore)
local menethilPier = wet(nil, 4.49, 56.66)
local southshorePier = hill(nil, 50.7, 70.5)
local southDarkshore = at(nil, 43.05, 93.5, M.darkshore)
local dunAlgaz = at(nil, 25.44, 10.38, M.lochModan)
local stormwindPier = at(nil, 21.8, 56.8, M.stormwind)

local function road(from, to, waypoint, label)
  route.roadTo[to] = route.roadTo[to] or {}
  route.roadTo[to][from] = { waypoint = waypoint, label = label }
end

route.extents[ashenvale] = { 5766.666, 3843.75 }
route.extents[stonetalon] = { 4883.333, 3256.25 }
route.extents[hillsbrad] = { 3200, 2133.333 }
route.flightNetwork[ashenvale], route.flightNetwork[stonetalon], route.flightNetwork[hillsbrad] = 2, 2, 1

road(M.darkshore, ashenvale, southDarkshore, "Follow the south road through Maestra's Post to Astranaar")
road(M.wetlands, M.darkshore, menethilPier, "Board at the north pier and stay aboard to Auberdine")
road(M.darkshore, M.wetlands, auberdinePier, "Take the Menethil ship from Auberdine's west pier")
road(M.wetlands, hillsbrad, menethilPier, "Take the north-pier ship and get off at Southshore")
road(M.darkshore, hillsbrad, auberdinePier, "Take the west-pier ship and get off at Southshore")
road(hillsbrad, M.wetlands, southshorePier, "Board south of town and stay aboard to Menethil Harbor")
road(hillsbrad, M.darkshore, southshorePier, "Board south of town and stay aboard to Auberdine")
road(M.stormwind, M.darkshore, stormwindPier, "Take the Auberdine ship from the south pier")
road(M.stormwind, ashenvale, stormwindPier, "Take the Auberdine ship, then follow the Darkshore road south")
road(M.lochModan, M.wetlands, dunAlgaz, "Take the north road through Dun Algaz")
road(ashenvale, stonetalon, talondeep, "Walk through Talondeep Path to Stonetalon")
road(stonetalon, ashenvale, stone(nil, 78.3, 42.5), "Return through Talondeep Path to Ashenvale")
road(ashenvale, M.darkshore, maestra, "Follow the road north to Auberdine")
road(ashenvale, M.wetlands, maestra, "Go north to Auberdine for the Menethil ship")
road(ashenvale, hillsbrad, maestra, "Go north to Auberdine for the Southshore ship")

-- Put the new exits first while preserving the existing choices.
for _, section in ipairs(route.sections) do
  if section.id == "loch-modan" then
    suggest(section, "wetlands-early", "ashenvale-early")
  elseif section.id == "darkshore" then
    suggest(section, "ashenvale-early", "wetlands-early", "stonetalon")
    for i, step in ipairs(section.steps) do
      if step.quest == 966 and step.type == "turnin" then
        table.insert(section.steps, i + 1, accept(967, balthule, "Take Balthule's letter for Delgren at Maestra's Post if you plan to visit Ashenvale."))
        break
      end
    end
  elseif section.id == "lakeshire" then
    suggest(section, "ashenvale-early", "wetlands-early", "redridge-late")
  elseif section.id == "duskwood" then
    suggest(section, "duskwood-late", "redridge-late", "ashenvale-late")
  elseif section.id == "wetlands" then
    suggest(section, "southshore", "duskwood-late", "ashenvale-late")
  elseif section.id == "redridge-late" or section.id == "duskwood-late" then
    section.manual = true
  end
  for _, step in ipairs(section.steps) do
    if step.type == "grind" then
      if section.id == "lakeshire" then
        suggest(step, "ashenvale-early", "wetlands-early")
      elseif section.id == "duskwood" then
        suggest(step, "duskwood-late", "redridge-late", "wetlands-early", "ashenvale-late")
      end
    end
  end
end
