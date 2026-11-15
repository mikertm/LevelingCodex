-- Horde class quests through level 30: Priest, Mage and Warlock. Source notes: tools/audits/2026-11-10-horde-class-casters.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE

-- Places shared by the three classes (QuestieDB spawns unless noted).
local M = B.maps
local wetlands = M.wetlands
route.extents[wetlands] = route.extents[wetlands] or { 4135.417, 2756.25 }
local function og(name, x, y) return B.at(name, x, y, M.orgrimmar) end
local function uc(name, x, y) return B.at(name, x, y, M.undercity) end
local function ba(name, x, y) return B.at(name, x, y, M.barrens) end
local urkyo = og("Ur'kyo", 35.59, 87.82)
local aelthalyste = uc("Aelthalyste", 49.26, 17.12)
local ganrul = og("Gan'rul Bloodeye", 48.25, 45.28)
local cleftCircle = og(nil, 49.43, 50.0)
local uthelnay = og("Uthel'nay", 39.16, 86.27)
local deino = og("Deino", 38.45, 86.13)
local anastasia = uc("Anastasia Hartwell", 85.14, 10.03)
local owen = uc("Owen Thadd", 73.6, 33.1)
local ucZeppelin = B.at(nil, 50.8, 13.8, M.durotar)
local MAGES, WARLOCKS = { "ORC", "TROLL", "SCOURGE" }, { "ORC", "TROLL", "SCOURGE" }

-- Priest: the racial spell quests at 10 and 20 sit on the route.
do
  local q, quest, accept, finish = B.q, B.quest, B.accept, B.finish
  local priest = "PRIEST"
  local miles = B.at("Miles Welsh", 25.31, 15.24, M.thunderBluff)

  -- Troll: Tai'jin offers Hex of Weakness when you train at 10 (quest record 5654; QuestieDB
  -- lists 5655 for her), Ur'kyo takes it on the first Orgrimmar visit.
  q(5654, "Hex of Weakness", 10, 10, nil, nil, priest)
  quest[5654].race = "TROLL"
  B.hordeInline("durotar", "turnin", 96822, {
    accept(5654, B.at("Tai'jin", 54.26, 42.93, M.durotar),
      "Priests: at level 10 Tai'jin, your trainer in Razor Hill, sends you to Ur'kyo in Orgrimmar for Hex of Weakness."),
  })
  B.hordeInline("northern-durotar", "accept", 5726, {
    finish(5654, urkyo,
      "Priests: walk south-west to the Valley of Spirits. Ur'kyo teaches Hex of Weakness in the priest hut."),
  })

  -- Undead: Aelthalyste in the War Quarter gives and takes Touch of Weakness herself.
  q(5658, "Touch of Weakness", 10, 10, nil, nil, priest)
  quest[5658].race = "SCOURGE"
  B.hordeInline("tirisfal", "turnin", 95328, {
    accept(5658, aelthalyste,
      "Priests: Aelthalyste, the priest trainer beside Father Lankester, has Touch of Weakness for you. If a trainer gave you a Touch of Weakness letter, hand that in here instead."),
    finish(5658, aelthalyste, "Speak with Aelthalyste again to learn Touch of Weakness."),
  })

  -- Level 20: Miles Welsh in Thunder Bluff has both racials (Forever renamed the Undead one
  -- Dark Sacrifice: Devouring Plague is baseline now).
  q(5642, "Shadowguard", 20, 20, nil, nil, priest)
  quest[5642].race = "TROLL"
  q(5644, "Dark Sacrifice", 20, 20, nil, nil, priest)
  quest[5644].race = "SCOURGE"
  -- Right after training: Miles Welsh is the trainer, so the pickups come while you're with him
  -- (2026-11-12 loop check: after Zamah's turn-in they were a walk back up the Spirit Rise).
  B.hordeInline("sun-rock", "train", nil, {
    accept(5642, miles, "Priests: Miles Welsh, the priest trainer on the Spirit Rise, sends Trolls to Ur'kyo for Shadowguard."),
    accept(5644, miles, "Priests: Miles Welsh sends the Undead to Aelthalyste in the Undercity for Dark Sacrifice."),
  })
  B.hordeInline("zoramgar", "fly", nil, {
    finish(5642, urkyo, "Priests: go to Ur'kyo in the Valley of Spirits to learn Shadowguard."),
  })
  B.hordeInline("hillsbrad", "turnin", 530, {
    finish(5644, aelthalyste, "Priests: Aelthalyste in the War Quarter teaches Dark Sacrifice."),
  })
end

-- Mage: Ju-Ju Heaps (Orc, Troll), Study, Spellfire Robes, Nether-lace and the wand.
do
  local q, quest, accept, finish = B.q, B.quest, B.accept, B.finish
  local objective, withItem, action, only = B.objectiveAt, B.withItem, B.action, B.only
  local mage = "MAGE"
  local sources = {
    "https://questing.wiki/wow-forever/classes/mage/",
    "https://www.wowhead.com/forever/quest=1884/ju-ju-heaps",
  }

  q(1883, "Speak with Un'thuwa", 10, 10, nil, nil, mage)
  q(1884, "Ju-Ju Heaps", 10, 10, 1883, nil, mage)
  quest[1883].race, quest[1884].race = { "ORC", "TROLL" }, { "ORC", "TROLL" }
  local unthuwa = B.at("Un'Thuwa", 56.31, 75.11, M.durotar)
  B.hordeSide({ id = "mage-ju-ju-heaps", title = "Mage: Ju-Ju Heaps", zone = M.durotar,
    levels = { 10, 12 }, class = mage, start = { "ORC", "TROLL" }, sources = sources, steps = {
      accept(1883, uthelnay, "Find Uthel'nay in the mage hut in Orgrimmar's Valley of Spirits."),
      finish(1883, unthuwa, "Leave Orgrimmar and follow the road south past Razor Hill to Sen'jin Village. Un'Thuwa trains mages there."),
      accept(1884, unthuwa),
      objective(1884, B.at(nil, 67.8, 84.3, M.durotar),
        "Wade across to the largest of the Echo Isles. Destroy four Ju-Ju Heaps among the huts. Hexed and Voodoo Trolls guard them.",
        "4 Ju-Ju Heaps Destroyed"),
      finish(1884, unthuwa, "Return to Un'Thuwa and choose the orb or the staff."),
    },
  })

  -- Study: donate one library book to Owen Thadd in the Undercity, then ask for Research Access.
  -- Undead pass both places on the route; Orcs and Trolls take the Orgrimmar book (side guide).
  q(79095, "The Apothecary's Metaphysical Primer", 10, 1, nil, true, mage)
  quest[79095].race = "SCOURGE"
  q(79094, "The Lessons of Ta'zo", 10, 1, nil, true, mage)
  quest[79094].race = { "ORC", "TROLL" }
  q(97286, "Research Access", 10, 1, nil, true, mage)
  B.breadcrumb(79095, 97286)
  B.breadcrumb(79094, 97286)
  B.hordeInline("tirisfal", "accept", 95314, {
    only(action("goto", B.at(nil, 59.44, 52.2, M.tirisfal),
      "Mages: take The Apothecary's Metaphysical Primer from the bookshelf in Carolai's shop. Keep it for the Undercity library."),
      { class = mage, race = "SCOURGE" }),
  })
  B.hordeInline("tirisfal", "turnin", 1882, {
    accept(79095, owen, "Mages: give the Primer to Owen Thadd in the inner ring of the Magic Quarter."),
    finish(79095, owen),
    accept(97286, owen, "Ask Owen Thadd for Research Access now that you have donated a book."),
    finish(97286, owen, "Complete Research Access to learn Study."),
  })
  B.hordeSide({ id = "mage-study-horde", title = "Mage: Study", zone = M.undercity,
    levels = { 10, 24 }, class = mage, start = { "ORC", "TROLL" },
    sources = {
      "https://www.warcrafttavern.com/forever/guides/library-books",
      "https://www.wowhead.com/forever/quest=97286/research-access",
    },
    steps = {
      action("goto", og(nil, 38.5, 78.2),
        "Take The Lessons of Ta'zo from the painted rock beside the mage hut in the Valley of Spirits. Keep it until you visit the Undercity."),
      action("boat", ucZeppelin, "Take the zeppelin to Tirisfal Glades from the tower outside Orgrimmar, then ride south into the Undercity. Do this on the route's Undercity visit at 24 if you like."),
      accept(79094, owen, "Give the book to Owen Thadd in the inner ring of the Magic Quarter."),
      finish(79094, owen),
      accept(97286, owen, "Ask Owen Thadd for Research Access now that you have donated a book."),
      finish(97286, owen, "Complete Research Access to learn Study."),
    },
  })

  q(1959, "Report to Anastasia", 15, 15, nil, nil, mage)
  quest[1959].race = { "ORC", "TROLL" }
  q(1960, "Investigate the Alchemist Shop", 16, 15, nil, nil, mage)
  q(1961, "Gathering Materials", 15, 15, 1960, nil, mage)
  q(1962, "Spellfire Robes", 15, 15, 1961, nil, mage)
  B.breadcrumb(1959, 1960)
  local josef = uc("Josef Gregorian", 70.76, 30.69)
  B.hordeSide({ id = "mage-spellfire-robes", title = "Mage: Spellfire Robes", zone = M.undercity,
    levels = { 15, 17 }, class = mage, start = MAGES, sources = sources, steps = {
      accept(1959, uthelnay, "Orcs and Trolls: Uthel'nay in Orgrimmar's Valley of Spirits sends you to the Undercity. Skip this if you are already there."),
      only(action("boat", ucZeppelin, "Take the zeppelin to Tirisfal Glades and ride south into the Undercity."), { race = { "ORC", "TROLL" } }),
      finish(1959, anastasia, "Anastasia Hartwell stands in the Magic Quarter."),
      accept(1960, anastasia, "Take the quest, then pick up the Cantation of Manifestation and the Chest of Containment Coffers behind Anastasia."),
      withItem(7308, objective(1960, uc(nil, 53.0, 74.7),
        "Follow the waypoint to the alchemy shop near the Apothecarium. Read the Cantation to reveal the Rift Spawns. Beat one down until it is stunned, open the Chest on it and loot the filled coffer. Do it three times.",
        "3 Filled Containment Coffers")),
      finish(1960, anastasia),
      accept(1961, anastasia, "Save 10 Linen Cloth from humanoids, or buy it. The gems come from Silverpine Forest."),
      objective(1961, B.at(nil, 52.6, 65.1, M.silverpine),
        "Ride south into Silverpine Forest to the Dalaran camp at 52, 65. Kill Dalaran Apprentices for 6 Dalaran Mana Gems.",
        "6 Dalaran Mana Gems", "10 Linen Cloth"),
      finish(1961, josef, "Take the gems and the cloth to Josef Gregorian in the Magic Quarter."),
      accept(1962, josef),
      finish(1962, josef, "Speak to Josef again for your Spellfire Robes."),
    },
  })

  q(1943, "Speak with Deino", 26, 26, nil, nil, mage)
  q(1944, "Waters of Xavian", 26, 26, 1943, nil, mage)
  q(1945, "Laughing Sisters", 26, 26, 1944, nil, mage)
  q(1946, "Nether-lace Garment", 26, 26, 1945, nil, mage)
  local kilhala = ba("Kil'hala", 52.2, 31.7)
  B.hordeSide({ id = "mage-nether-lace", title = "Mage: Nether-lace Garment", zone = M.ashenvale,
    levels = { 26, 28 }, class = mage, start = MAGES,
    sources = { "https://questing.wiki/wow-forever/classes/mage/", "https://warcraft.wiki.gg/wiki/Waters_of_Xavian" },
    steps = {
      accept(1943, anastasia, "Anastasia Hartwell in the Undercity's Magic Quarter has the next robe. Take it on an Undercity visit."),
      finish(1943, deino, "Take the zeppelin to Orgrimmar. Deino teaches in the mage hut in the Valley of Spirits."),
      accept(1944, deino, "Take Deino's Flask with you to eastern Ashenvale."),
      withItem(7269, objective(1944, B.at(nil, 76.0, 41.0, M.ashenvale),
        "Fly to Splintertree Post. Follow the river north past Satyrnaar to the satyr ruins of Xavian and fill the flask at the foot of the highest waterfall. Satyrs hold the ruins.",
        "Xavian Water Sample")),
      finish(1944, deino, "Bring the sample back to Deino in Orgrimmar."),
      accept(1945, deino),
      objective(1945, B.at(nil, 59.0, 56.1, M.ashenvale),
        "Return to Ashenvale. Kill Laughing Sisters, the dryads around Raynewood Retreat, for 12 of their hairs.",
        "12 Laughing Sister's Hairs"),
      finish(1945, kilhala, "Fly to the Crossroads. Kil'hala is in the town."),
      accept(1946, kilhala),
      finish(1946, kilhala, "Speak to Kil'hala again and choose the robe or the blouse."),
    },
  })

  -- Mage's Wand opens at 30 (Deino's copy of Journey to the Marsh; Tabetha's part is shared).
  local dustwallow, needles, arathi = M.dustwallow, M.needles, M.arathi
  local tabetha = B.at("Tabetha", 46.06, 57.09, dustwallow)
  local tirth = B.at("Magus Tirth", 78.29, 75.7, needles)
  q(1947, "Journey to the Marsh", 38, 30, nil, nil, mage)
  q(1948, "Items of Power", 40, 30, 1947, nil, mage)
  q(1949, "Hidden Secrets", 38, 30, 1947, nil, mage)
  q(1950, "Get the Scoop", 30, 30, 1949, nil, mage)
  q(1951, "Rituals of Power", 40, 30, 1950, nil, mage)
  q(1952, "Mage's Wand", 40, 30, { 1948, 1951 }, nil, mage)
  B.hordeSide({ id = "mage-wand-horde", title = "Mage: Mage's Wand", zone = dustwallow,
    levels = { 30, 30 }, class = mage, start = MAGES,
    sources = { "https://questing.wiki/wow-forever/classes/mage/", "https://www.wowhead.com/forever/quest=1952/mages-wand" },
    steps = {
      accept(1947, deino, "This opens at 30. Its enemies are in the high 30s and the last book is in the Scarlet Monastery Library, so bring friends. Buy a Jade before you leave if you can."),
      finish(1947, tabetha, "Ride east from the Barrens into Dustwallow Marsh. Tabetha's hut stands in the hills in the west of the marsh, at 46, 57."),
      accept(1948, tabetha, "Take Tabetha's Instructions. The bramble is made in Arathi Highlands."),
      accept(1949, tabetha),
      finish(1949, tirth, "Find Magus Tirth at the Mirage Raceway in the Shimmering Flats."),
      accept(1950, tirth),
      objective(1950, B.at('"Plucky" Johnson', 79.61, 75.63, needles),
        "Find the chicken near the raceway tower. Target it and type /beckon; the man who appears tells you the phrase.",
        "Find the strongbox phrase"),
      finish(1950, tirth),
      accept(1951, tirth),
      objective(1948, B.at(nil, 65.3, 65.2, arathi),
        "In Arathi Highlands, loot 10 Witherbark Totem Sticks from the trolls at Witherbark Village. Use them on the centre stone of the Circle of Outer Binding (52, 50), then loot the charged bramble. Keep a Jade.",
        "Bolt Charged Bramble", "Jade"),
      objective(1951, B.at(nil, 85, 32, M.tirisfal),
        "With a group, run the Scarlet Monastery Library in north-east Tirisfal. Rituals of Power sits on a bookshelf in the long hall before Arcanist Doan.",
        "Rituals of Power"),
      finish(1948, tabetha, "Bring the bramble and the Jade back to Tabetha."),
      finish(1951, tabetha),
      accept(1952, tabetha),
      finish(1952, tabetha, "Let Tabetha finish her ritual, then speak to her and pick your wand."),
    },
  })
end

-- Warlock: Voidwalker for Orcs and Trolls (Undead do theirs in Tirisfal), the Succubus and
-- Incubus from Gan'rul, the Orb of Soran'ruk and the Felhunter.
do
  local q, quest, accept, finish = B.q, B.quest, B.accept, B.finish
  local objective, withItem = B.objectiveAt, B.withItem
  local warlock = "WARLOCK"
  local sources = {
    "https://questing.wiki/wow-forever/classes/warlock/",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }

  -- Voidwalker on the Durotar route: Ophek in Razor Hill, the Tablet of Verga in Skull Rock.
  q(1506, "Gan'rul's Summons", 10, 10, nil, nil, warlock)
  q(1501, "Creature of the Void", 11, 10, 1506, nil, warlock)
  q(1504, "The Binding", 11, 10, 1501, nil, warlock)
  quest[1506].race = { "ORC", "TROLL" }
  quest[1501].race = { "ORC", "TROLL" }
  quest[1504].race = { "ORC", "TROLL" }
  B.hordeInline("northern-durotar", "accept", 806, {
    accept(1506, B.at("Ophek", 54.37, 41.29, M.durotar), "Warlocks: Ophek stands beside the warlock trainer in Razor Hill."),
  })
  B.hordeInline("northern-durotar", "accept", 5726, {
    finish(1506, ganrul, "Warlocks: Gan'rul Bloodeye is in the Cleft of Shadow, the tunnel below the Valley of Strength."),
    accept(1501, ganrul),
  })
  B.hordeInline("northern-durotar", "complete", 5726, {
    objective(1501, B.at(nil, 51.6, 9.8, M.durotar),
      "Warlocks: take the right-hand passage in Skull Rock to its end and open the Burning Blade Stash for the Tablet of Verga.",
      "Tablet of Verga"),
  })
  B.hordeInline("northern-durotar", "accept", 809, {
    finish(1501, ganrul, "Warlocks: give the tablet to Gan'rul in the Cleft of Shadow."),
    accept(1504, ganrul),
    withItem(7464, objective(1504, cleftCircle,
      "Warlocks: heal up, use the Glyphs of Summoning in the Cleft of Shadow and defeat the Voidwalker.", "Summoned Voidwalker")),
    finish(1504, ganrul, "Warlocks: return to Gan'rul to learn Summon Voidwalker."),
  })

  -- Succubus (classic chain) and Incubus (Forever) from Gan'rul at 20.
  q(1507, "Devourer of Souls", 20, 20, nil, nil, warlock)
  q(1508, "Blind Cazul", 20, 20, 1507, nil, warlock)
  q(1509, "News of Dogran", 20, 20, 1508, nil, warlock)
  q(1510, "News of Dogran", 20, 20, 1509, nil, warlock)
  q(1511, "Ken'zigla's Draught", 20, 20, 1510, nil, warlock)
  q(1515, "Dogran's Captivity", 20, 20, 1511, nil, warlock)
  q(1512, "Love's Gift", 20, 20, 1515, nil, warlock)
  q(1513, "The Binding", 20, 20, 1512, nil, warlock)
  q(65601, "Love Hurts", 20, 20, 1507, true, warlock)
  q(65610, "Wish You Were Here", 27, 20, 65601, true, warlock)
  q(65604, "The Binding", 20, 20, 65610, true, warlock)
  local cazul = og("Cazul", 47.06, 46.43)
  local logmar = ba("Grunt Logmar", 44.62, 59.27)
  B.hordeSide({ id = "warlock-sayaad-horde", title = "Warlock: Succubus and Incubus", zone = M.orgrimmar,
    levels = { 20, 27 }, class = warlock, start = WARLOCKS,
    sources = {
      "https://questing.wiki/wow-forever/classes/warlock/",
      "https://db.icy-veins.com/wow-forever/quests/65601",
      "https://conquestcapped.com/guides/wow-forever/wow-forever-warlock-quests/",
    },
    steps = {
      accept(1507, ganrul, "Gan'rul Bloodeye waits in the Cleft of Shadow in Orgrimmar."),
      finish(1507, cazul, "Cazul sits a few steps away in the same tunnel."),
      accept(1508, cazul, "Take Blind Cazul for the Succubus."),
      accept(65601, cazul, "Take Love Hurts for the Incubus as well. Use Next if you only want the Succubus."),
      finish(1508, og("Zankaja", 37.04, 59.45), "Zankaja is in the Valley of Spirits, west of the Cleft."),
      accept(1509, og("Zankaja", 37.04, 59.45)),
      finish(65601, og("Magar", 63.65, 49.93), "Magar is in the Valley of Honor, on the east side of the city."),
      accept(65610, og("Magar", 63.65, 49.93), "Wish You Were Here sends you to Fallen Sky Lake in Ashenvale, a level 27 area. Keep it for later if needed."),
      finish(1509, ba("Gazrog", 51.93, 30.32), "Fly to the Crossroads. Gazrog is in the town."),
      accept(1510, ba("Gazrog", 51.93, 30.32)),
      finish(1510, B.at("Ken'zigla", 73.25, 95.13, M.stonetalon),
        "Ride west into Stonetalon Mountains and follow the road south to Malaka'jin. Ken'zigla is in the troll village."),
      accept(1511, B.at("Ken'zigla", 73.25, 95.13, M.stonetalon)),
      finish(1511, logmar, "Bring the draught to Grunt Logmar at Camp Taurajo in the southern Barrens."),
      accept(1515, logmar),
      finish(1515, ba("Grunt Dogran", 43.3, 47.89), "Grunt Dogran is held prisoner north of Camp Taurajo, at 43, 48. Give him the draught."),
      accept(1512, ba("Grunt Dogran", 43.3, 47.89)),
      finish(1512, ganrul, "Take the pendant back to Gan'rul in Orgrimmar."),
      accept(1513, ganrul),
      withItem(6626, objective(1513, cleftCircle,
        "Use Dogran's Pendant in the Cleft of Shadow and defeat the Succubus.", "Summoned Succubus")),
      finish(1513, ganrul, "Speak with Gan'rul to learn Summon Succubus."),
      objective(65610, B.at(nil, 66.3, 82.0, M.ashenvale),
        "Fly to Splintertree Post and go south-west to Fallen Sky Lake. Kill Shadethicket Stone Movers and Bark Rippers around the lake for the Withered Scarf.",
        "Withered Scarf"),
      finish(65610, ganrul, "Bring the scarf to Gan'rul in Orgrimmar."),
      accept(65604, ganrul),
      withItem("Withered Scarf", objective(65604, cleftCircle,
        "Use the Withered Scarf in the Cleft of Shadow and defeat the Incubus.", "Summoned Incubus")),
      finish(65604, ganrul, "Speak with Gan'rul to learn Summon Incubus."),
    },
  })

  q(1740, "The Orb of Soran'ruk", 25, 20, nil, nil, warlock)
  local doan = ba("Doan Karhan", 49.31, 57.21)
  B.hordeSide({ id = "warlock-orb-horde", title = "Warlock: The Orb of Soran'ruk", zone = M.barrens,
    levels = { 20, 28 }, class = warlock, start = WARLOCKS, sources = sources,
    links = { "dungeon-blackfathom-deeps", "dungeon-shadowfang-keep" },
    steps = {
      accept(1740, doan, "Doan Karhan camps with Takar the Seer east of Camp Taurajo. Take this when you plan to run both Blackfathom Deeps and Shadowfang Keep."),
      objective(1740, B.at(nil, 14.0, 14.0, M.ashenvale),
        "In Blackfathom Deeps, loot 3 Soran'ruk Fragments from Twilight Acolytes. In Shadowfang Keep, Shadowfang Darksouls past the courtyard drop the Large Soran'ruk Fragment.",
        "3 Soran'ruk Fragments", "Large Soran'ruk Fragment"),
      finish(1740, doan, "Bring the four fragments to Doan and choose the orb or the staff."),
    },
  })

  -- Felhunter at 30: Gan'rul's referral, Strahad in Ratchet, Jorah Annison in the Undercity.
  q(2996, "Seeking Strahad", 30, 30, nil, nil, warlock)
  q(1801, "Tome of the Cabal", 30, 30, nil, nil, warlock)
  q(1803, "Tome of the Cabal", 30, 30, 1801, nil, warlock)
  q(1805, "Tome of the Cabal", 30, 30, 1803, nil, warlock)
  q(1795, "The Binding", 30, 30, 1805, nil, warlock)
  B.breadcrumb(2996, 1801)
  local strahad = ba("Strahad Farsan", 62.63, 35.5)
  local jorah = uc("Jorah Annison", 75.92, 37.89)
  B.hordeSide({ id = "warlock-felhunter-horde", title = "Warlock: Felhunter", zone = M.barrens,
    levels = { 30, 30 }, class = warlock, start = WARLOCKS, sources = sources, steps = {
      accept(2996, ganrul, "Gan'rul in Orgrimmar's Cleft of Shadow sends you to Ratchet. Undead may get the same referral from Carendin Halgar in the Undercity."),
      finish(2996, strahad, "Fly to Ratchet. Strahad Farsan lives in the house on the hill behind the town."),
      accept(1801, strahad),
      finish(1801, jorah, "Take the zeppelin to Tirisfal and find Jorah Annison in the Undercity's Magic Quarter."),
      accept(1803, jorah),
      B.objectivePart(1803, 1, B.at(nil, 27.8, 72.8, M.hillsbrad),
        "Fly to Tarren Mill and ride to the murloc huts on the coast west of Southshore. Loot the Moldy Tome there. Southshore is an Alliance town: keep clear of its guards.",
        "Moldy Tome"),
      B.objectivePart(1803, 2, B.at(nil, 43.4, 32.7, M.needles),
        "In Thousand Needles, enter Splithoof Hold, keep right and loot the Damaged Chest for the Tattered Manuscript.",
        "Tattered Manuscript"),
      finish(1803, jorah, "Bring both pieces to Jorah in the Undercity."),
      accept(1805, jorah, "Keep the Reconstructed Tome. The rods come from the Wetlands."),
      objective(1805, B.at(nil, 47.7, 46.1, wetlands),
        "Go to Hammerfall in Arathi, then south over Thandol Span into the Wetlands. Kill Dragonmaw Bonewarders and Shadowwarders at the camp around 48, 46 for 3 Rods of Channeling.",
        "3 Rods of Channeling"),
      finish(1805, strahad, "Bring the rods and the tome to Strahad in Ratchet."),
      accept(1795, strahad),
      withItem(6999, objective(1795, strahad,
        "Follow Strahad until his acolytes form the circle. Use the Tome of the Cabal inside it and defeat the Felhunter.",
        "Summoned Felhunter")),
      finish(1795, strahad, "Wait for Strahad to walk back, then speak to him to learn Summon Felhunter."),
    },
  })
end
