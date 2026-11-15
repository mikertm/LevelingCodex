-- Horde class quests through level 30: Druid and Shaman. Source notes: tools/audits/2026-11-10-horde-class-*.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE

-- Druids: Bear Form (Tauren), Moonglade (Skyborne), Cure Poison, Aquatic Form and Cat Form.
-- Skyborne Bear Form is on Zephras Isle (Valanaar); Tauren Heeding the Call is in Mulgore.
do
  local at, q, quest = B.at, B.q, B.quest
  local accept, finish, goal, action, withItem = B.accept, B.finish, B.objectiveAt, B.action, B.withItem
  local m, glade = B.maps, 1450
  route.extents[glade] = { 2308.333, 1539.583 }
  local druid, tauren, skyborne = "DRUID", "TAUREN", "SKYBORNE"
  local hordeDruids = { tauren, skyborne }

  local turak = at("Turak Runetotem", 76.48, 27.22, m.thunderBluff)
  local dendrite = at("Dendrite Starblaze", 56.21, 30.64, glade)
  local tajarri = at("Tajarri", 36.52, 40.10, glade)
  local shrine = at(nil, 36.0, 41.42, glade)
  local bunthen = at("Bunthen Plainswind", 44.3, 45.9, glade)
  local tonga = at("Tonga Runetotem", 52.26, 31.93, m.barrens)
  local teleport = "Cast Teleport: Moonglade and find Dendrite upstairs in the large building in Nighthaven."
  local flyHome = "Find Bunthen Plainswind west of Nighthaven. He flies druids to Thunder Bluff."

  route.roadTo[m.thunderBluff] = route.roadTo[m.thunderBluff] or {}
  route.roadTo[m.thunderBluff][glade] = { waypoint = bunthen, label = "Take Bunthen Plainswind's flight to Thunder Bluff" }

  -- Bear Form (Tauren, level 10). Heeding the Call (5926) already ends at Turak in the Mulgore route.
  q(5922, "Moonglade", 10, 10, nil, nil, druid)
  q(5930, "Great Bear Spirit", 10, 10, 5922, nil, druid)
  q(5932, "Back to Thunder Bluff", 10, 10, 5930, nil, druid)
  q(6002, "Body and Heart", 10, 10, 5932, nil, druid)
  for _, id in ipairs({ 5922, 5930, 5932, 6002 }) do quest[id].race = tauren end
  B.hordeSide({ id = "druid-bear-form-tauren", title = "Druid: Bear Form", zone = m.thunderBluff,
    levels = { 10, 12 }, class = druid, start = tauren,
    sources = { "QuestieDB Forever 0f7d8ad", "RestedXP Forever Horde 1-12 Mulgore (order and IDs)",
      "https://bindonforever.com/quest/6002" },
    steps = {
      accept(5922, turak, "Find Turak Runetotem on Elder Rise in Thunder Bluff. If you still carry Heeding the Call, hand it in first."),
      finish(5922, dendrite, teleport),
      accept(5930, dendrite),
      goal(5930, at("Great Bear Spirit", 39.11, 27.5, glade),
        "Walk west along the north shore of the lake to the Great Bear Spirit. Talk to it until the conversation ends.",
        "Speak with the Great Bear Spirit"),
      finish(5930, dendrite, "Walk back to Dendrite in Nighthaven, or cast Teleport: Moonglade again."),
      accept(5932, dendrite),
      action("goto", bunthen, flyHome .. " Your hearthstone works too if it is set there."),
      finish(5932, turak, "Return to Turak on Elder Rise."),
      accept(6002, turak),
      withItem(15710, goal(6002, at(nil, 42.0, 60.86, m.barrens),
        "Ride the lift down, take the east road out of Mulgore into the Barrens and find the Moonkin Stone west of Camp Taurajo. Use the Cenarion Lunardust there, kill Lunaclaw (level 12) and talk to his spirit. Avoid the Thunderheads nearby.",
        "Face Lunaclaw")),
      finish(6002, turak, "Fly from Camp Taurajo back to Thunder Bluff and see Turak to learn Bear Form."),
    },
  })

  -- Skyborne druids: Turak gives the Moonglade introduction after Child of Nature (Valanaar
  -- section). Kept in a side guide: an inline pickup would push the Barrens log past 20.
  q(94913, "Moonglade", 10, 10, nil, true, druid)
  quest[94913].race = skyborne
  B.hordeSide({ id = "druid-moonglade-skyborne-horde", title = "Druid: Moonglade (Skyborne)", zone = glade,
    levels = { 10, 12 }, class = druid, start = skyborne,
    sources = { "QuestieDB Forever 0f7d8ad", "RestedXP Forever Horde 1-14 Undead (94913 turn-in)" },
    steps = {
      accept(94913, turak, "Find Turak Runetotem on Elder Rise in Thunder Bluff, where Child of Nature ended."),
      finish(94913, dendrite, teleport .. " Use Bunthen Plainswind's flight to get back to Thunder Bluff."),
    },
  })

  -- Cure Poison (level 14).
  q(6126, "Lessons Anew", 14, 14, nil, nil, druid)
  q(6127, "The Principal Source", 14, 14, 6126, nil, druid)
  q(6128, "Gathering the Cure", 14, 14, 6127, nil, druid)
  q(6129, "Curing the Sick", 14, 14, 6128, nil, druid)
  q(6130, "Power over Poison", 14, 14, 6129, nil, druid)
  B.hordeSide({ id = "druid-cure-poison-horde", title = "Druid: Cure Poison", zone = m.barrens,
    levels = { 14, 16 }, class = druid, start = hordeDruids,
    sources = { "QuestieDB Forever 0f7d8ad", "https://polestar.guide/guides/class/druid/cure-poison" },
    steps = {
      accept(6126, turak, "Find Turak on Elder Rise in Thunder Bluff. Pick or buy 5 Earthroot before you go: a later step needs them."),
      finish(6126, dendrite, teleport),
      accept(6127, dendrite),
      action("goto", bunthen, flyHome .. " From Thunder Bluff, fly on to the Crossroads."),
      withItem(15842, goal(6127, at(nil, 47.9, 15.2, m.barrens),
        "Go north from the Crossroads and climb Dreadmist Peak. Pull the Burning Blade cultists one at a time. Stand in the pool on the summit and use the Empty Dreadmist Peak Sampler. Three Toxicologists attack while it fills.",
        "Filled Dreadmist Peak Sampler")),
      finish(6127, tonga, "Bring the sample to Tonga Runetotem in the Crossroads."),
      accept(6128, tonga),
      goal(6128, at(nil, 53.8, 43.2, m.barrens),
        "Kill Lost Barrens Kodos around the Stagnant Oasis southeast of the Crossroads for Kodo Horns. Herbalists find Earthroot all over the northern Barrens; the Crossroads trade goods vendor and the auction house sell it too.",
        "5 Earthroot", "5 Kodo Horns"),
      finish(6128, tonga),
      accept(6129, tonga),
      withItem(15826, goal(6129, at(nil, 48.8, 23.8, m.barrens),
        "Find living Sickly Gazelles north of the Crossroads road and use the Curative Animal Salve on each. Rooting them first makes it easier.",
        "10 Sickly Gazelles cured")),
      finish(6129, dendrite, "Teleport to Moonglade and report to Dendrite upstairs."),
      accept(6130, dendrite),
      action("goto", bunthen, flyHome),
      finish(6130, turak, "See Turak on Elder Rise to learn Cure Poison."),
    },
  })

  -- Aquatic Form (level 16). Forever swaps 26 and 27: 27 is the Horde opener here.
  q(27, "A Lesson to Learn", 16, 16, nil, nil, druid)
  q(28, "Trial of the Lake", 16, 16, 27, nil, druid)
  q(30, "Trial of the Sea Lion", 16, 16, 28, nil, druid)
  q(31, "Aquatic Form", 16, 16, 30, nil, druid)
  B.hordeSide({ id = "druid-aquatic-form-horde", title = "Druid: Aquatic Form", zone = glade,
    levels = { 16, 18 }, class = druid, start = hordeDruids,
    sources = { "QuestieDB Forever 0f7d8ad", "RestedXP Forever Horde 12-22 Barrens (order and IDs)",
      "https://efficient.games/wowf/quests/id5061" },
    steps = {
      accept(27, turak, "Find Turak on Elder Rise in Thunder Bluff."),
      finish(27, dendrite, teleport),
      accept(28, dendrite, "Accept when you are ready to dive: the bauble only lasts a short while once you loot it."),
      goal(28, at(nil, 54.9, 53.2, glade),
        "Dive to the bottom of the lake south of Nighthaven and open a Bauble Container. If this one is gone, look for another nearby. Loot the Shrine Bauble and press Next.",
        "Loot a Shrine Bauble"),
      withItem(15877, goal(28, shrine,
        "Swim straight to the Shrine of Remulos on the west shore and use the bauble by the great tree.",
        "Use the Shrine Bauble")),
      finish(28, tajarri),
      accept(30, tajarri),
      action("goto", bunthen, flyHome),
      goal(30, at(nil, 56.7, 8.3, m.barrens),
        "Travel to the Sludge Fen in the far north of the Barrens. The Strange Lockbox lies under the water there. Loot the Half Pendant of Aquatic Agility and press Next.",
        "Half Pendant of Aquatic Agility"),
      goal(30, at(nil, 29.6, 29.2, m.silverpine),
        "Take the zeppelin from Orgrimmar to Tirisfal Glades and head south into Silverpine Forest. Swim out from the west coast to the bubbling fissure and loot the Half Pendant of Aquatic Endurance from the lockbox beside it. Watch your breath and the fatigue bar.",
        "Half Pendant of Aquatic Endurance"),
      withItem(15883, goal(30, shrine,
        "With both halves, cast Teleport: Moonglade. Use the Half Pendant of Aquatic Agility at the Shrine of Remulos to join them.",
        "Pendant of the Sea Lion")),
      finish(30, dendrite, "Take the joined pendant to Dendrite in Nighthaven."),
      accept(31, dendrite),
      action("goto", bunthen, flyHome),
      finish(31, turak, "Show Turak the pendant to learn Aquatic Form."),
    },
  })

  -- Cat Form (level 20): Forever's Horde branch. Tauren and Skyborne meet different spirits.
  q(98340, "The Great Cat Spirit", 20, 20, nil, true, druid)
  q(98362, "To Thunder Bluff", 20, 20, nil, true, druid)
  local function catForm(race, spirit, intro, trial, blessing)
    local windborne = race == skyborne
    local title = windborne and "The Great Windborne Cat Spirit" or "The Great Cat Spirit"
    q(intro, title, 20, 20, 98340, true, druid)
    q(trial, title, 20, 20, intro, true, druid)
    q(blessing, windborne and "Blessings of the Great Windborne Cat Spirit" or "Blessings of the Great Cat Spirit",
      20, 20, trial, true, druid)
    for _, id in ipairs({ intro, trial, blessing }) do quest[id].race = race end
    B.hordeSide({ id = windborne and "druid-cat-form-skyborne-horde" or "druid-cat-form-tauren",
      title = "Druid: Cat Form", zone = glade, levels = { 20, 22 }, class = druid, start = race,
      sources = { "RestedXP Forever Horde 12-22 Barrens (order and IDs)",
        "https://polestar.guide/guides/class/druid/cat-form" },
      steps = {
        accept(98340, turak, "Find Turak on Elder Rise in Thunder Bluff."),
        finish(98340, dendrite, teleport),
        accept(intro, dendrite),
        finish(intro, spirit, "Follow the lake shore around to the spirit in the southern hills of Moonglade."),
        accept(trial, spirit),
        goal(trial, at(nil, 72.4, 66.0, glade),
          "Enter the Stormrage Barrow Dens on the east side of the lake. Leave shapeshift form and use the cat statue near the entrance to hide from the spirits inside. Cross the bridge and search the alcoves for the three relics by the cat statues. If the stealth wears off, go back to the entrance statue.",
          "Relic of the Fang", "Relic of the Claw", "Relic of the Silent Shadow"),
        finish(trial, spirit, "Bring the three relics back to the spirit in southern Moonglade."),
        accept(blessing, spirit),
        finish(blessing, dendrite, "Return to Dendrite upstairs in Nighthaven."),
        accept(98362, dendrite),
        action("goto", bunthen, flyHome),
        finish(98362, turak, "See Turak on Elder Rise to learn Cat Form."),
      },
    })
  end
  catForm(tauren, at("Great Cat Spirit", 58.39, 73.52, glade), 98405, 98342, 98739)
  catForm(skyborne, at("Avatar of Saeyleenan", 43.92, 73.44, glade), 98341, 98404, 98738)
end

-- Shamans: Fire, Water and Air totems. Earth is in the starting zones; Skyborne Earth and Fire
-- are on Zephras Isle.
do
  local at, q, quest = B.at, B.q, B.quest
  local accept, finish, goal, part, action, withItem = B.accept, B.finish, B.objectiveAt, B.objectivePart,
    B.action, B.withItem
  local breadcrumb, taxi = B.breadcrumb, B.taxi
  local m = B.maps
  local shaman = "SHAMAN"
  local orcTroll, tauren, skyborne = { "ORC", "TROLL" }, "TAUREN", "SKYBORNE"

  local swart = at("Swart", 54.42, 42.59, m.durotar)
  local narm = at("Narm Skychaser", 47.40, 62.54, m.mulgore)
  local searn = at("Searn Firewarder", 37.96, 37.73, m.orgrimmar)
  local xanis = at("Xanis Flameweaver", 25.16, 20.51, m.thunderBluff)
  local kranal = at("Kranal Fiss", 56.03, 19.89, m.barrens)
  local telf = at("Telf Joolam", 38.55, 58.96, m.durotar)
  local brazier = at("Brazier of the Dormant Flame", 38.96, 58.22, m.durotar)
  local islen = at("Islen Waterseer", 65.83, 43.78, m.barrens)
  local brine = at("Brine", 43.42, 77.41, m.barrens)
  local everfount = at("Brazier of Everfount", 38.26, 44.56, m.silverpine)
  local water = at("Minor Manifestation of Water", 38.75, 44.63, m.silverpine)
  local prate = at("Prate Cloudseer", 53.54, 42.65, m.needles)
  local ratchetFlight = at("Bragok", 63.09, 37.16, m.barrens)
  local taurajoFlight = at("Omusa Thunderhorn", 44.45, 59.15, m.barrens)
  local totemGuide = "https://conquestcapped.com/guides/wow-forever/wow-forever-shaman-totem-quests/"
  local function call(id, element, level, min, prior)
    q(id, "Call of " .. element, level, min, prior, nil, shaman)
  end
  local other = " If another shaman trainer already gave you the same quest, use Next: it counts just the same."

  -- Fire Totem (level 10). The four openers are the same quest from different trainers;
  -- 2984 is declared in the Mulgore file.
  call(2983, "Fire", 10, 10)
  call(1524, "Fire", 11, 10)
  call(1525, "Fire", 12, 10, 1524)
  call(1526, "Fire", 13, 10, 1525)
  call(1527, "Fire", 13, 10, 1526)
  quest[2983].race, quest[2984].race = orcTroll, tauren
  breadcrumb(2983, 1524)
  breadcrumb(2984, 1524)
  B.hordeSide({ id = "shaman-fire-totem-horde", title = "Shaman: Fire Totem", zone = m.barrens,
    levels = { 10, 13 }, class = shaman, start = { "ORC", "TROLL", tauren },
    sources = { "QuestieDB Forever 0f7d8ad", totemGuide,
      "RestedXP Forever Horde 01-12 Durotar, 1-12 Mulgore, 12-22 Barrens (order and IDs)" },
    steps = {
      accept(2983, swart, "Find Swart, the shaman trainer in Razor Hill." .. other),
      accept(2984, narm, "Find Narm Skychaser, the shaman trainer in Bloodhoof Village." .. other),
      finish(2983, kranal, "Cross the bridge west of Razor Hill into the Barrens. Kranal Fiss stands on a rise north of the road from the Crossroads to Far Watch Post."),
      finish(2984, kranal, "Follow the road north from the Crossroads toward Far Watch Post. Kranal Fiss stands on a rise just north of it."),
      accept(1524, kranal),
      action("goto", at(nil, 36.74, 57.78, m.durotar),
        "Cross into Durotar and follow the river south. The trail up to Telf starts on the river side of the hills here. It is narrow: a fall can kill you."),
      finish(1524, telf, "Follow the trail to the top of the shrine to Telf Joolam."),
      accept(1525, telf),
      action("goto", at(nil, 51.6, 30.0, m.durotar), "Climb back down and head north past Razor Hill toward Dustwind Cave."),
      part(1525, 2, at(nil, 52.4, 25.5, m.durotar),
        "Go north past Razor Hill to Dustwind Cave. Kill Burning Blade Cultists inside until one drops a Reagent Pouch.",
        "Reagent Pouch"),
      part(1525, 1, at(nil, 55.0, 26.0, m.barrens),
        "Back in the Barrens, kill Razormane quillboar south of Kranal Fiss (Water Seekers, Thornweavers, Geomancers) until one drops Fire Tar.",
        "Fire Tar"),
      action("goto", at(nil, 36.74, 57.78, m.durotar), "Return to the foot of Telf's trail by the river in Durotar."),
      finish(1525, telf),
      accept(1526, telf),
      withItem(6636, goal(1526, at(nil, 38.7, 58.3, m.durotar),
        "Drink the Fire Sapta next to the shrine. Kill the Minor Manifestation of Fire (level 12) and loot its Glowing Ember.",
        "Glowing Ember")),
      finish(1526, brazier, "Place the Glowing Ember in the brazier on top of the shrine."),
      accept(1527, brazier),
      finish(1527, kranal, "Take the Torch of Eternal Flame back to Kranal Fiss in the Barrens for your Fire Totem."),
    },
  })

  -- Water Totem (level 20). Openers from Orgrimmar and Thunder Bluff (also Swart and Narm).
  call(1528, "Water", 20, 20)
  call(1529, "Water", 20, 20)
  call(1530, "Water", 22, 20)
  call(1535, "Water", 22, 20, 1530)
  call(1536, "Water", 22, 20, 1535)
  call(1534, "Water", 23, 20, 1536)
  call(220, "Water", 23, 20, 1534)
  call(63, "Water", 23, 20, 220)
  call(100, "Water", 23, 20, 63)
  call(96, "Water", 23, 20, 100)
  quest[1528].race, quest[1529].race = orcTroll, { tauren, skyborne }
  breadcrumb(1528, 1530)
  breadcrumb(1529, 1530)
  B.hordeSide({ id = "shaman-water-totem-horde", title = "Shaman: Water Totem", zone = m.barrens,
    levels = { 20, 25 }, class = shaman, start = { "ORC", "TROLL", tauren, skyborne },
    sources = { "QuestieDB Forever 0f7d8ad", totemGuide,
      "RestedXP Forever Horde 12-22 Barrens and Classic Horde 20-30 (order and IDs)" },
    steps = {
      accept(1528, searn, "Find Searn Firewarder in the Valley of Wisdom, Orgrimmar." .. other),
      accept(1529, xanis, "Find Xanis Flameweaver on Spirit Rise in Thunder Bluff." .. other),
      finish(1528, islen, "Fly to Ratchet and walk south along the beach to Islen Waterseer's fishing hut."),
      finish(1529, islen, "Fly to Ratchet and walk south along the beach to Islen Waterseer's fishing hut."),
      accept(1530, islen),
      taxi("fly", taurajoFlight, "Camp Taurajo, The Barrens", "Walk back up to Ratchet and fly to Camp Taurajo."),
      finish(1530, brine, "Travel to the southern Barrens. Brine's hut is beside the road south of Camp Taurajo, close to the way down into Thousand Needles."),
      accept(1535, brine),
      withItem(7766, goal(1535, at(nil, 44.2, 76.8, m.barrens),
        "Use the Empty Brown Waterskin in the watering hole just below Brine's hut.", "Filled Brown Waterskin")),
      finish(1535, brine),
      accept(1536, brine),
      withItem(7768, goal(1536, at(nil, 62.17, 20.82, m.hillsbrad),
        "Take the zeppelin from Orgrimmar to Tirisfal Glades, then travel south through Silverpine Forest to Tarren Mill in Hillsbrad. Use the Empty Red Waterskin at the town well.",
        "Filled Red Waterskin")),
      finish(1536, brine, "Take the red waterskin back to Brine in the southern Barrens."),
      accept(1534, brine),
      withItem(7767, goal(1534, at(nil, 33.5, 67.5, m.ashenvale),
        "Go to the Ruins of Stardust in southwestern Ashenvale, south of the Alliance town of Astranaar. Use the Empty Blue Waterskin in the pool among the ruins. Watch for Alliance guards.",
        "Filled Blue Waterskin")),
      finish(1534, brine, "Take the blue waterskin back to Brine."),
      accept(220, brine),
      taxi("fly", ratchetFlight, "Ratchet, The Barrens", "Fly from Camp Taurajo to Ratchet."),
      finish(220, islen, "Take the Vial of Purest Water to Islen south of Ratchet."),
      accept(63, islen, "Accept, and make sure Islen gives you the Water Sapta. Ask her for another if you lose it."),
      action("goto", at(nil, 41.83, 41.16, m.silverpine),
        "Travel to the Sepulcher in Silverpine Forest. Just west of it, climb the slope by the big tree to get onto the hills."),
      withItem(6637, goal(63, at(nil, 38.5, 44.46, m.silverpine),
        "Go down the far side to the pool by the Brazier of Everfount. Drink the Water Sapta, kill the Corrupt Minor Manifestation of Water and loot its bracers.",
        "Corrupt Manifestation's Bracers")),
      finish(63, everfount, "Place the bracers and the Remaining Drops of Purest Water on the Brazier of Everfount."),
      accept(100, everfount),
      finish(100, water, "Wait for the cleansed spirit to rise from the pool, then talk to it."),
      accept(96, water),
      finish(96, islen, "Take the Shard of Water back to Islen south of Ratchet for your Water Totem."),
    },
  })

  -- Air Totem (level 30): one trip to Prate Cloudseer. Skyborne have their own version (96136).
  call(1531, "Air", 30, 30)
  call(1532, "Air", 30, 30)
  quest[1531].race, quest[1532].race = orcTroll, tauren
  B.hordeSide({ id = "shaman-air-totem-horde", title = "Shaman: Air Totem", zone = m.needles,
    levels = { 30, 30 }, class = shaman, start = { "ORC", "TROLL", tauren },
    sources = { "QuestieDB Forever 0f7d8ad", totemGuide },
    steps = {
      accept(1531, searn, "Find Searn Firewarder in the Valley of Wisdom, Orgrimmar."),
      accept(1532, xanis, "Find Xanis Flameweaver on Spirit Rise in Thunder Bluff."),
      finish(1531, prate, "Fly to Freewind Post in Thousand Needles. Prate Cloudseer is on the mesas northeast of it."),
      finish(1532, prate, "Fly to Freewind Post in Thousand Needles. Prate Cloudseer is on the mesas northeast of it."),
    },
  })
end
