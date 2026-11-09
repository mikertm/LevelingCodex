-- Alliance class quests through level 30. See the class quest notes under tools/audits.
-- Short class quests on the way are inserted into the route's sections (`inline`); longer
-- chains are side sections (`side = true`, `class = TOKEN`): listed in the Quests tab and
-- under Missed quests, never the current step unless you pick them.
local B = LevelingCodexQuests.build
LevelingCodexQuests.build = nil
local route = LevelingCodexQuests.ALLIANCE

-- Insert steps into a section after the step that matches (type and quest), or at its end.
local function inline(sectionId, afterType, afterQuest, steps)
  for _, section in ipairs(route.sections) do
    if section.id == sectionId then
      local at = not afterType and #section.steps
      if afterType then
        for i, step in ipairs(section.steps) do
          if step.type == afterType and step.quest == afterQuest then at = i; break end
        end
      end
      assert(at, "class quests: insertion point missing in " .. sectionId)
      for n, step in ipairs(steps) do table.insert(section.steps, at + n, step) end
      return
    end
  end
  error("class quests: no section " .. tostring(sectionId))
end

local function side(section)
  section.side, section.verified = true, false
  route.sections[#route.sections + 1] = section
end

-- Keep a required starter with its class chain so it can be recovered after leveling.
local function takeIntro(sectionId, id)
  for _, section in ipairs(route.sections) do
    if section.id == sectionId then
      local intro, i = {}, 1
      while i <= #section.steps do
        if section.steps[i].quest == id then
          intro[#intro + 1] = table.remove(section.steps, i)
        else
          i = i + 1
        end
      end
      assert(#intro == 2 and intro[1].type == "accept" and intro[2].type == "turnin",
        "class quests: expected an introduction for " .. id)
      return intro
    end
  end
  error("class quests: no section " .. sectionId)
end

-- First demons: pick up at the trainer, do the objective on the existing loop.
do
  local m, at = B.maps, B.at
  local drusilla = at("Drusilla La Salle", 49.87, 42.65, m.elwynn)
  local alamar = at("Alamar Grimm", 28.65, 66.14, m.dunMorogh)
  B.q(1598, "The Stolen Tome", 4, 1, nil, nil, "WARLOCK")
  B.q(1599, "Beginnings", 4, 1, nil, nil, "WARLOCK")
  B.quest[1599].race = "GNOME"
  inline("northshire", "turnin", 3105, { B.accept(1598, drusilla) })
  inline("northshire", "complete", 6, {
    B.objectiveAt(1598, at("Stolen Books", 56.7, 44.0, m.elwynn),
      "Search the stolen books in the Defias camp north of the vineyard.", "Powers of the Void"),
  })
  inline("northshire", "turnin", 6, {
    B.finish(1598, drusilla, "Return the tome to Drusilla in the abbey to learn Summon Imp."),
  })
  inline("coldridge", "turnin", 3115, { B.accept(1599, alamar) })
  inline("coldridge", "complete", 218, {
    B.objectiveAt(1599, at(nil, 30.2, 81.2, m.dunMorogh),
      "While in the troll cave, kill Frostmane Novices until you have all three charms.", "3 Feather Charms"),
  })
  inline("coldridge", "turnin", 3361, {
    B.finish(1599, alamar, "Bring the charms to Alamar inside Anvilmar to learn Summon Imp."),
  })
end

-- Warrior and Paladin
do
  local m, at, q = B.maps, B.at, B.q
  local accept, finish, goal, withItem = B.accept, B.finish, B.objectiveAt, B.withItem
  local warrior, paladin = "WARRIOR", "PALADIN"
  local human, dwarf, gnome, nightElf, skyborne = "HUMAN", "DWARF", "GNOME", "NIGHTELF", "SKYBORNE"
  local dwarfGnome, paladinRaces = { dwarf, gnome }, { human, dwarf }
  local barrens, ashenvale, thousandNeedles = 1413, 1440, 1441
  local extents = LevelingCodexQuests.ALLIANCE.extents
  extents[barrens] = { 10133.333, 6756.25 }
  extents[ashenvale] = { 5766.666, 3843.75 }
  extents[thousandNeedles] = { 4400.0, 2933.333 }

  local warriorSources = {
    "https://www.icy-veins.com/wow-forever/warrior-class-quests",
    "https://questing.wiki/wow-forever/classes/warrior/",
  }
  local paladinSources = {
    "https://www.icy-veins.com/wow-forever/paladin-class-quests",
    "https://questing.wiki/wow-forever/classes/paladin/",
  }
  local function w(id, name, level, min, prev, race)
    q(id, name, level, min, prev, nil, warrior)
    B.quest[id].race = race
  end
  local function p(id, name, level, min, prev, race, forever)
    q(id, name, level, min, prev, forever, paladin)
    B.quest[id].race = race
  end

  local lyria = at("Lyria Du Lac", 41.09, 65.77, m.elwynn)
  local harry = at("Harry Burlguard", 77.13, 53.26, m.stormwind)
  local bartleby = at("Bartleby", 76.76, 52.55, m.stormwind)
  local haggard = at("Marshal Haggard", 84.61, 69.38, m.elwynn)
  w(1638, "A Warrior's Training", 10, 10, nil, human)
  w(1639, "Bartleby the Drunk", 10, 10, 1638, human)
  w(1640, "Beat Bartleby", 10, 10, 1639, human)
  w(1665, "Bartleby's Mug", 10, 10, 1640, human)
  w(1666, "Marshal Haggard", 10, 10, 1665, human)
  w(1667, "Dead-tooth Jack", 10, 10, 1666, human)
  side({ id = "warrior-defense-human", title = "Warrior: Defensive Stance (Human)", zone = m.stormwind,
    levels = { 10, 12 }, class = warrior, start = human, sources = warriorSources, steps = {
      accept(1638, lyria, "Get A Warrior's Training from Lyria at Goldshire or Ilsa Corbin in the Old Town barracks."),
      finish(1638, harry, "Find Harry in the Pig and Whistle Tavern in Stormwind's Old Town."),
      accept(1639, harry),
      finish(1639, bartleby, "Speak to Bartleby in the same tavern."),
      accept(1640, bartleby, "Heal up, then accept Beat Bartleby to begin the fight."),
      goal(1640, bartleby, "Fight until Bartleby yields. Speak to him after he turns friendly.", "Beat Bartleby"),
      finish(1640, bartleby),
      accept(1665, bartleby),
      finish(1665, harry, "Give Harry the mug to learn Defensive Stance, Taunt and Sunder Armor."),
    } })
  side({ id = "warrior-haggards-weapon", title = "Warrior: Haggard's Weapon", zone = m.elwynn,
    levels = { 10, 12 }, class = warrior, start = human, sources = warriorSources, steps = {
      accept(1666, harry, "After Bartleby's Mug, take Harry's referral to Eastvale Logging Camp."),
      finish(1666, haggard),
      accept(1667, haggard),
      goal(1667, at("Dead-tooth's Strongbox", 89.33, 78.88, m.elwynn),
        "Head southeast to the camp. Kill Dead-tooth Jack for his key, then open the nearby strongbox for the badge.",
        "Marshal Haggard's Badge"),
      finish(1667, haggard, "Return the badge and choose a weapon you can use."),
    } })

  local granis = at("Granis Swiftaxe", 47.36, 52.65, m.dunMorogh)
  local muren = at("Muren Stormpike", 70.77, 90.27, m.ironforge)
  local tormus = at("Tormus Deepforge", 48.64, 42.48, m.ironforge)
  w(1679, "Muren Stormpike", 10, 10, nil, dwarfGnome)
  w(1678, "Vejrek", 11, 10, 1679, dwarfGnome)
  w(1680, "Tormus Deepforge", 11, 10, 1678, dwarfGnome)
  w(1681, "Ironband's Compound", 11, 10, 1680, dwarfGnome)
  w(1682, "Grey Iron Weapons", 10, 10, 1681, dwarfGnome)
  side({ id = "warrior-defense-ironforge", title = "Warrior: Defensive Stance (Ironforge)", zone = m.ironforge,
    levels = { 10, 12 }, class = warrior, start = dwarfGnome, sources = warriorSources, steps = {
      accept(1679, granis, "Take Granis Swiftaxe's referral in Kharanos."),
      finish(1679, muren, "Find Muren Stormpike in the Military Ward."),
      accept(1678, muren),
      goal(1678, at("Vejrek", 27.8, 58.0, m.dunMorogh),
        "Find Vejrek by his hut in the hills just south of Frostmane Hold. Loot his head.",
        "Vejrek's Head"),
      finish(1678, muren, "Bring Vejrek's head to Muren to learn Defensive Stance, Taunt and Sunder Armor."),
    } })
  side({ id = "warrior-grey-iron-weapons", title = "Warrior: Grey Iron Weapons", zone = m.ironforge,
    levels = { 10, 12 }, class = warrior, start = dwarfGnome, sources = warriorSources, steps = {
      accept(1680, muren, "After Vejrek, take Muren's referral to the Great Forge."),
      finish(1680, tormus),
      accept(1681, tormus),
      goal(1681, at("Ironband's Strongbox", 77.96, 62.16, m.dunMorogh),
        "Head to the Dark Iron camp south of Helm's Bed Lake. Loot the strongbox near Captain Beld for Umbral Ore.",
        "Umbral Ore"),
      finish(1681, tormus),
      accept(1682, tormus),
      finish(1682, tormus, "Talk to Tormus again and choose a weapon you can use."),
    } })

  -- Valanaar covers Skyborne (94003). Keep the Night Elf trainer referral with the chain.
  local elanariaIntro = takeIntro("teldrassil", 1684)
  local elanaria = at("Elanaria", 57.3, 34.61, m.darnassus)
  local mathiel = at("Mathiel", 59.51, 45.38, m.darnassus)
  w(1683, "Vorlus Vilehoof", 10, 10, 1684, nightElf)
  w(1686, "The Shade of Elura", 10, 10, 1683, nightElf)
  w(1692, "Smith Mathiel", 10, 10, 1686, nightElf)
  w(1693, "Weapons of Elunite", 10, 10, 1692, nightElf)
  side({ id = "warrior-defense-nightelf", title = "Warrior: Defensive Stance (Night Elf)", zone = m.darnassus,
    levels = { 10, 12 }, class = warrior, start = nightElf, sources = warriorSources, steps = {
      elanariaIntro[1], elanariaIntro[2],
      accept(1683, elanaria, "Accept from Elanaria on the Warrior's Terrace."),
      goal(1683, at("Vorlus Vilehoof", 47.25, 63.6, m.teldrassil),
        "Approach Ban'ethil Hollow from the east. Kill Vorlus Vilehoof and loot his horn.", "Horn of Vorlus"),
      finish(1683, elanaria, "Bring Elanaria the horn to learn Defensive Stance, Taunt and Sunder Armor."),
    } })
  side({ id = "warrior-weapons-of-elunite", title = "Warrior: Weapons of Elunite", zone = m.darnassus,
    levels = { 10, 13 }, class = warrior, start = nightElf, sources = warriorSources, steps = {
      accept(1686, elanaria, "After Vorlus Vilehoof, take Elanaria's assignment in Darkshore."),
      goal(1686, at("Shade of Elura", 31.64, 44.86, m.darkshore),
        "Take the Rut'theran boat to Auberdine. Swim to the wreck south of the docks, kill the Shade for her medallion, and open submerged crates for 8 Elunite Ore. Surface for air between dives.",
        "8 Elunite Ore", "Elura's Medallion"),
      finish(1686, elanaria),
      accept(1692, elanaria),
      finish(1692, mathiel, "Take the elunite to Mathiel on the Craftsmen's Terrace."),
      accept(1693, mathiel),
      finish(1693, mathiel, "Talk to Mathiel again and choose a weapon you can use."),
    } })

  local wu = at("Wu Shen", 80.55, 59.87, m.stormwind)
  local yorus = at("Yorus Barleybrew", 21.49, 44.72, m.redridge)
  local furen = at("Furen Longbeard", 64.62, 37.23, m.stormwind)
  w(1698, "Yorus Barleybrew", 20, 20)
  w(1699, "The Rethban Gauntlet", 22, 20, 1698)
  w(1702, "The Shieldsmith", 22, 20, 1699)
  w(1701, "Fire Hardened Mail", 28, 20, 1702)
  w(1782, "Furen's Armor", 28, 20, 1701)
  side({ id = "warrior-furens-favor", title = "Warrior: Furen's Favor", zone = m.redridge,
    levels = { 20, 22 }, class = warrior, sources = warriorSources, steps = {
      accept(1698, wu, "Take Wu Shen's referral from the Old Town barracks."),
      finish(1698, yorus, "Find Yorus in Lakeshire."),
      accept(1699, yorus, "Start the timed trial when you are ready to head straight to Rethban Caverns."),
      goal(1699, at(nil, 14.05, 24.71, m.redridge),
        "Head into Rethban Caverns northwest of Lakeshire. Fight past the gnolls to the first fork for credit. Return to Yorus before the hour runs out and avoid dying and releasing.",
        "Enter the Rethban Caverns"),
      finish(1699, yorus),
      accept(1702, yorus),
      finish(1702, furen, "Deliver the cask to Furen in Stormwind's Dwarven District for Furen's Favor."),
    } })
  side({ id = "warrior-fire-hardened-mail", title = "Warrior: Fire Hardened Hauberk", zone = m.stormwind,
    levels = { 25, 30 }, class = warrior, sources = warriorSources, steps = {
      accept(1701, furen, "After The Shieldsmith, ask Furen how to make the hauberk. Plan a Razorfen Kraul group before the Kalimdor leg."),
      goal(1701, nil,
        "In Wetlands, kill Leech and Cave Stalkers around 50, 62 for 50 fangs. At the Charred Vale in Stonetalon, get 12 horns from young or fledgling chimaeras and the Galvanized Horn from the matriarch. Loot the vial from Roogug in Razorfen Kraul.",
        "50 Scorched Spider Fangs", "12 Charred Horns", "Galvanized Horn", "Vial of Phlogiston"),
      finish(1701, furen),
      accept(1782, furen),
      finish(1782, furen, "Collect the Fire Hardened Hauberk from Furen."),
    } })

  local humanGnome = { human, gnome }
  local grimand = at("Grimand Elmore", 59.73, 33.78, m.stormwind)
  local klockmort = at("Klockmort Spannerspan", 67.92, 46.1, m.ironforge)
  w(1700, "Grimand Elmore", 28, 20, 1701, humanGnome)
  w(1705, "Burning Blood", 28, 20, 1700, humanGnome)
  w(1706, "Grimand's Armor", 30, 20, 1705, humanGnome)
  w(1704, "Klockmort Spannerspan", 28, 20, 1701, dwarfGnome)
  w(1708, "Iron Coral", 29, 20, 1704, dwarfGnome)
  w(1709, "Klockmort's Creation", 30, 20, 1708, dwarfGnome)
  w(1703, "Mathiel", 28, 20, 1701, nightElf)
  w(1710, "Sunscorched Shells", 30, 20, 1703, nightElf)
  w(1711, "Mathiel's Armor", 30, 20, 1710, nightElf)
  side({ id = "warrior-fire-hardened-coif", title = "Warrior: Fire Hardened Coif", zone = m.stormwind,
    levels = { 28, 30 }, class = warrior, start = humanGnome, sources = warriorSources, steps = {
      accept(1700, furen, "After Fire Hardened Mail, take Furen's referral to Grimand."),
      finish(1700, grimand),
      accept(1705, grimand),
      goal(1705, at("Gutspill", 73.89, 77.17, m.duskwood),
        "In the Rotting Orchard, kill Nightbane worgen for 20 Burning Blood and Gutspill for the Burning Rock.",
        "20 Burning Blood", "Burning Rock"),
      finish(1705, grimand),
      accept(1706, grimand),
      finish(1706, grimand, "Collect the Fire Hardened Coif."),
    } })
  side({ id = "warrior-fire-hardened-gauntlets", title = "Warrior: Fire Hardened Gauntlets", zone = m.ironforge,
    levels = { 28, 30 }, class = warrior, start = dwarfGnome, sources = warriorSources, steps = {
      accept(1704, furen, "After Fire Hardened Mail, take Furen's referral to Klockmort."),
      finish(1704, klockmort, "Find Klockmort in Ironforge's Tinker Town."),
      accept(1708, klockmort),
      goal(1708, at(nil, 9.08, 71.76, m.wetlands),
        "Dive along the coast south of Menethil Harbor and gather Iron Coral deposits for 20 Searing Coral. Surface for air between dives.",
        "20 Searing Coral"),
      finish(1708, klockmort),
      accept(1709, klockmort),
      finish(1709, klockmort, "Collect the Fire Hardened Gauntlets."),
    } })
  side({ id = "warrior-fire-hardened-leggings", title = "Warrior: Fire Hardened Leggings", zone = m.darnassus,
    levels = { 28, 30 }, class = warrior, start = nightElf, sources = warriorSources, steps = {
      accept(1703, furen, "After Fire Hardened Mail, take Furen's referral to Mathiel."),
      finish(1703, mathiel),
      accept(1710, mathiel),
      goal(1710, at(nil, 13.47, 37.05, thousandNeedles),
        "Gather 20 Sunscorched Shells off the ground around the Highperch wyvern nests in western Thousand Needles.",
        "20 Sunscorched Shells"),
      finish(1710, mathiel),
      accept(1711, mathiel),
      finish(1711, mathiel, "Collect the Fire Hardened Leggings."),
    } })

  local klannoc = at("Klannoc Macleod", 68.62, 49.16, barrens)
  w(1718, "The Islander", 30, 30)
  w(1719, "The Affray", 30, 30, 1718)
  side({ id = "warrior-berserker-stance", title = "Warrior: Berserker Stance", zone = barrens,
    levels = { 30, 30 }, class = warrior, start = { human, dwarf, gnome, nightElf, skyborne },
    sources = {
      "https://db.icy-veins.com/wow-forever/quests/1719",
      "https://bindonforever.com/quest/1719",
      "https://www.60.tools/quests/1718-the-islander",
    }, steps = {
      accept(1718, wu, "Take The Islander from Wu Shen in Stormwind, Kelv Sternhammer in Ironforge, or Darnath Bladesinger in Darnassus."),
      finish(1718, klannoc,
        "Take the boat from Booty Bay to Ratchet if coming from the Eastern Kingdoms. Follow the shore south to the Merchant Coast and cross the shallows to Fray Island. Avoid Northwatch Hold."),
      accept(1719, klannoc, "Heal up before accepting from Klannoc. You have 10 minutes for the trial and turn-in."),
      goal(1719, at(nil, 68.6, 48.72, barrens),
        "Step on the grate just north of Klannoc. Fight the challengers as they enter, then defeat Big Will. Stay in the arena until you have credit.",
        "Big Will slain"),
      finish(1719, klannoc, "Turn in The Affray to learn Berserker Stance and Intercept."),
    } })

  local divinity = "The Tome of Divinity"
  local duthorian = at("Duthorian Rall", 50.48, 47.49, m.stormwind)
  local stephanie = at("Stephanie Turner", 63.84, 72.21, m.stormwind)
  local gazin = at("Gazin Tenorm", 49.53, 44.99, m.stormwind)
  local henze = at("Henze Faulk", 72.6, 51.41, m.elwynn)
  p(1642, divinity, 12, 12, nil, human)
  p(1643, divinity, 12, 12, 1642, human)
  p(1644, divinity, 13, 12, 1643, human)
  p(1780, divinity, 13, 12, 1644, human)
  p(1781, divinity, 13, 12, 1780, human)
  p(1786, divinity, 13, 12, 1781, human)
  p(1787, divinity, 13, 12, 1786, human)
  p(1788, divinity, 13, 12, 1787, human)
  side({ id = "paladin-redemption-human", title = "Paladin: Redemption (Human)", zone = m.stormwind,
    levels = { 12, 14 }, class = paladin, start = human, sources = paladinSources, steps = {
      withItem(6775, accept(1642, duthorian,
        "Bring 10 Linen Cloth. Speak to Duthorian in the Cathedral of Light for the Tome of Divinity. Complete his introductory errand if offered, then use the book to accept this quest.")),
      finish(1642, duthorian),
      accept(1643, duthorian),
      finish(1643, stephanie, "Speak to Stephanie Turner in the Trade District."),
      accept(1644, stephanie),
      finish(1644, stephanie, "Give Stephanie 10 Linen Cloth. If short, buy some or loot Defias in Elwynn."),
      accept(1780, stephanie),
      finish(1780, duthorian),
      accept(1781, duthorian),
      finish(1781, gazin, "Take the Symbol of Life to Gazin inside the cathedral."),
      accept(1786, gazin),
      withItem(6866, goal(1786, henze,
        "Find Henze Faulk's body on the island in Stone Cairn Lake. Clear nearby Defias, target Henze, and use the Symbol of Life.",
        "Revive Henze Faulk")),
      finish(1786, henze, "Speak to Henze while he is awake."),
      accept(1787, henze, "Take the follow-up from Henze before leaving the island."),
      goal(1787, henze, "Kill Defias Rogue Wizards around Henze's island for the Defias Script.", "Defias Script"),
      finish(1787, gazin),
      accept(1788, gazin),
      finish(1788, duthorian, "Return to Duthorian to learn Redemption."),
    } })

  local tiza = at("Tiza Battleforge", 27.63, 12.18, m.ironforge)
  local john = at("John Turner", 23.34, 61.86, m.ironforge)
  local muiredon = at("Muiredon Battleforge", 23.54, 8.3, m.ironforge)
  local narm = at("Narm Faulk", 78.32, 58.09, m.dunMorogh)
  p(1646, divinity, 12, 12, nil, dwarf)
  p(1647, divinity, 12, 12, 1646, dwarf)
  p(1648, divinity, 13, 12, 1647, dwarf)
  p(1778, divinity, 13, 12, 1648, dwarf)
  p(1779, divinity, 13, 12, 1778, dwarf)
  p(1783, divinity, 13, 12, 1779, dwarf)
  p(1784, divinity, 13, 12, 1783, dwarf)
  p(1785, divinity, 13, 12, 1784, dwarf)
  side({ id = "paladin-redemption-dwarf", title = "Paladin: Redemption (Dwarf)", zone = m.ironforge,
    levels = { 12, 14 }, class = paladin, start = dwarf, sources = paladinSources, steps = {
      withItem(6916, accept(1646, tiza,
        "Bring 10 Linen Cloth. Speak to Tiza in the Mystic Ward for the Tome of Divinity. Complete her introductory errand if offered, then use the book to accept this quest.")),
      finish(1646, tiza),
      accept(1647, tiza),
      finish(1647, john, "Find John Turner in the Commons."),
      accept(1648, john),
      finish(1648, john, "Give John 10 Linen Cloth. If short, buy some or loot troggs in Dun Morogh."),
      accept(1778, john),
      finish(1778, tiza),
      accept(1779, tiza),
      finish(1779, muiredon, "Take the Symbol of Life to Muiredon in the Mystic Ward."),
      accept(1783, muiredon),
      withItem(6866, goal(1783, narm,
        "Find Narm Faulk's body south of Helm's Bed Lake. Clear nearby Dark Iron dwarves, target Narm, and use the Symbol of Life.",
        "Revive Narm Faulk")),
      finish(1783, narm, "Speak to Narm while he is awake."),
      accept(1784, narm, "Take the follow-up from Narm before leaving."),
      goal(1784, at(nil, 77.6, 61.5, m.dunMorogh), "Kill nearby Dark Iron Spies for the Dark Iron Script.", "Dark Iron Script"),
      finish(1784, muiredon),
      accept(1785, muiredon),
      finish(1785, tiza, "Return to Tiza to learn Redemption."),
    } })

  local valor, righteousness = "The Tome of Valor", "The Test of Righteousness"
  local daphne = at("Daphne Stilwell", 41.69, 89.24, m.westfall)
  local jordan = at("Jordan Stilwell", 52.49, 36.92, m.dunMorogh)
  p(1649, valor, 20, 20, nil, paladinRaces)
  p(1650, valor, 23, 20, 1649, paladinRaces)
  p(1651, valor, 25, 20, 1650, paladinRaces)
  p(1652, valor, 25, 20, 1651, paladinRaces)
  p(1653, righteousness, 21, 20, 1652, paladinRaces)
  p(1654, righteousness, 22, 20, 1653, paladinRaces)
  p(1806, righteousness, 22, 20, 1654, paladinRaces)
  side({ id = "paladin-sense-undead", title = "Paladin: Sense Undead", zone = m.westfall,
    levels = { 20, 25 }, class = paladin, start = paladinRaces, sources = paladinSources, steps = {
      withItem(6776, accept(1649, duthorian,
        "Ask Duthorian in the Cathedral of Light for the Tome of Valor. Brandur Ironhammer in Ironforge is another book source. Use the tome to accept the quest.")),
      finish(1649, duthorian),
      accept(1650, duthorian),
      finish(1650, daphne, "Find Daphne at her house on the southern edge of Westfall, above the Deadmines back exit."),
      accept(1651, daphne, "Start the defense with full health and mana. Bring a friend if the waves are too much alone."),
      goal(1651, daphne,
        "Stay with Daphne and fight the waves of Defias Raiders. Heal her as needed. If she dies, wait for her to respawn and take the defense again.",
        "Protect Daphne Stilwell"),
      finish(1651, daphne),
      accept(1652, daphne),
      finish(1652, duthorian, "Report to Duthorian for Sense Undead and the Bastion of Stormwind."),
    } })
  side({ id = "paladin-verigans-fist", title = "Paladin: Verigan's Fist", zone = m.dunMorogh,
    levels = { 22, 28 }, class = paladin, start = paladinRaces, sources = {
      "https://db.icy-veins.com/wow-forever/quests/1654",
      "https://db.icy-veins.com/wow-forever/quests/1806",
      "https://forg.gg/en/forever/tips/verigans-fist",
    }, steps = {
      accept(1653, duthorian, "After the final Tome of Valor turn-in, take Duthorian's referral to Jordan."),
      finish(1653, jordan, "Find Jordan just outside the Ironforge gate on the Dun Morogh map."),
      accept(1654, jordan, "Get Jordan's weapon list before visiting the dungeons. Bring a group for the dungeon runs."),
      goal(1654, nil,
        "Lumber: loot Goblin Woodcarvers near Sneed in Deadmines. Hammer: open Jordan's Hammer in the Shadowfang Keep courtyard stables. Ore: ask Bailor in Thelsamar for his errand, loot the shipment at Mo'grosh Stronghold (71.6, 21.6), and return it to him. Gem: get Thundris Windweaver's errand in Auberdine, kill naga in the Blackfathom Deeps entrance tunnels, then return to Thundris to purify the gem.",
        "Whitestone Oak Lumber", "Jordan's Smithing Hammer", "Jordan's Refined Ore Shipment", "Purified Kor Gem"),
      finish(1654, jordan),
      accept(1806, jordan, "Accept the last quest and wait by the anvil while Jordan forges the mace."),
      finish(1806, jordan, "Talk to Jordan when he finishes to claim Verigan's Fist."),
    } })

  local orb = at("Strange Orb", 56.22, 26.45, m.darkshore)
  local delgren = at("Delgren the Purifier", 26.2, 38.7, ashenvale)
  local katherine = at("Katherine the Pure", 48.48, 49.09, m.stormwind)
  local ursula = at("Ursula Deline", 39.89, 84.19, m.stormwind)
  local spear = at("Spear of Mannoroth", 89, 77, ashenvale)
  local shattered = at("Shattered Orb", 89, 77, ashenvale)
  p(78088, "A Strange Artifact", 30, 22, nil, paladinRaces, true)
  p(78089, "Advice From Stormwind", 30, 22, 78088, paladinRaces, true)
  p(78090, "A Second Opinion", 30, 22, 78089, paladinRaces, true)
  p(78091, "Earning Your Salt", 30, 22, 78090, paladinRaces, true)
  p(78092, "It Must Be Destroyed", 30, 22, 78091, paladinRaces, true)
  p(78093, "Return to Delgren", 30, 22, 78092, paladinRaces, true)
  side({ id = "paladin-divine-storm-cloak", title = "Paladin: Cloak of the Divine Storm", zone = m.darkshore,
    levels = { 25, 30 }, class = paladin, start = paladinRaces, sources = {
      "https://www.icy-veins.com/wow-forever/paladin-class-quests",
      "https://forg.gg/en/forever/tips/cloak-of-the-divine-storm",
      "https://db.icy-veins.com/wow-forever/quests/78093",
    }, steps = {
      accept(78088, orb, "Climb the Tower of Althalaxx in northern Darkshore. Loot the Strange Orb at the top and accept the quest."),
      finish(78088, delgren, "Take the orb to Delgren at Maestra's Post in Ashenvale."),
      accept(78089, delgren),
      finish(78089, katherine, "Bring the orb to Katherine in Stormwind's Cathedral of Light."),
      accept(78090, katherine),
      finish(78090, ursula, "Enter the Slaughtered Lamb in the Mage Quarter and take the stairs down to Ursula."),
      accept(78091, ursula),
      goal(78091, at(nil, 38.8, 19.6, m.redridge),
        "Kill Blackrock Summoners in northern Redridge until you have 14 Summoner's Salt.",
        "14 Summoner's Salt"),
      finish(78091, ursula),
      accept(78092, ursula),
      goal(78092, at(nil, 78, 83.9, ashenvale),
        "Kill demons in Demon Fall Canyon in southeastern Ashenvale for 12 Motes of Mannoroth. Keep the orb in your bags.",
        "12 Motes of Mannoroth"),
      finish(78092, spear, "Use the Spear of Mannoroth deeper in the canyon to shatter the orb."),
      accept(78093, shattered, "Click the Shattered Orb that appears at the spear."),
      B.action("goto", delgren, "Leave Demon Fall Canyon and head west across Ashenvale to Maestra's Post."),
      finish(78093, delgren, "Bring the fragments to Delgren for the Cloak of the Divine Storm."),
    } })
end

-- Hunter and Rogue
do
  local at, q, accept, finish = B.at, B.q, B.accept, B.finish
  local objective, withItem = B.objectiveAt, B.withItem
  local maps = B.maps
  local hunterSource = "https://questing.wiki/wow-forever/classes/hunter/"
  local petSource = "https://www.zockify.com/forever/hunter/feed-pet/"
  local rogueSource = "https://www.icy-veins.com/wow-forever/rogue-class-quests"
  local lockSource = "https://www.zockify.com/forever/rogue/lockpicking/"
  local poisonSource = "https://www.zockify.com/forever/rogue/poison-quest/"

  local grif = at("Grif Wildheart", 45.81, 53.04, maps.dunMorogh)
  local belia = at("Belia Thundergranite", 70.86, 85.83, maps.ironforge)
  q(6064, "Taming the Beast", 10, 10, nil, nil, "HUNTER")
  q(6084, "Taming the Beast", 10, 10, 6064, nil, "HUNTER")
  q(6085, "Taming the Beast", 10, 10, 6084, nil, "HUNTER")
  q(6086, "Training the Beast", 10, 10, 6085, nil, "HUNTER")
  side({ id = "hunter-taming-dwarf", title = "Hunter: Taming in Dun Morogh",
    zone = maps.dunMorogh, levels = { 10, 12 }, class = "HUNTER", start = "DWARF",
    sources = { hunterSource, "https://www.icy-veins.com/wow-forever/hunter-class-quests", petSource },
    steps = {
      accept(6064, grif, "Find Grif by the forge uphill from the Kharanos inn. If you took The Hunter's Path, hand it in to him first."),
      withItem(15911, objective(6064, at("Large Crag Boar", 45.8, 45.3, maps.dunMorogh),
        "Look north of Kharanos for a Large Crag Boar. Use the Taming Rod from range and stand still until the channel ends.", "Tame a Large Crag Boar")),
      finish(6064, grif),
      accept(6084, grif),
      withItem(15913, objective(6084, at("Snow Leopard", 48.7, 61.8, maps.dunMorogh),
        "Look south-east of Kharanos for a Snow Leopard. Wait for the previous trial pet to leave if it is still active, then use the new rod.", "Tame a Snow Leopard")),
      finish(6084, grif),
      accept(6085, grif),
      withItem(15908, objective(6085, at("Ice Claw Bear", 35.2, 43.9, maps.dunMorogh),
        "Go north-west of Kharanos toward Brewnall Village. Find an Ice Claw Bear away from other mobs and tame it with the new rod.", "Tame an Ice Claw Bear")),
      finish(6085, grif, "Turn in to Grif for Tame Beast and the basic pet commands."),
      accept(6086, grif),
      finish(6086, belia, "Follow the road into Ironforge and find Belia in the Hall of Arms. Learn pet feeding and training before taming a pet to keep."),
    },
  })

  local josephine = at("Josephine Carson", 42.77, 66.38, maps.elwynn)
  local isaac = at("Isaac Chan", 41.79, 66.38, maps.elwynn)
  q(94792, "Taming the Beast", 10, 10, nil, true, "HUNTER")
  q(94863, "Taming the Beast", 10, 10, 94792, true, "HUNTER")
  q(94864, "Taming the Beast", 10, 10, 94863, true, "HUNTER")
  q(94793, "Training the Beast", 10, 10, 94864, true, "HUNTER")
  side({ id = "hunter-taming-human", title = "Hunter: Taming in Elwynn",
    zone = maps.elwynn, levels = { 10, 12 }, class = "HUNTER", start = "HUMAN",
    sources = { hunterSource, petSource },
    steps = {
      accept(94792, josephine, "Find Josephine near the Goldshire inn and take the first Taming Rod."),
      withItem(266158, objective(94792, at("Rockhide Boar", 45.5, 83.8, maps.elwynn),
        "Find a Rockhide Boar near the Maclure farm. Use the rod from range and stand still until the channel ends.", "Tame a Rockhide Boar")),
      finish(94792, josephine),
      accept(94863, josephine),
      withItem(266253, objective(94863, at("Gray Forest Wolf", 59.3, 65.9, maps.elwynn),
        "Look east of Crystal Lake for a Gray Forest Wolf. Wait for the previous trial pet to leave if it is still active, then use the new rod.", "Tame a Gray Forest Wolf")),
      finish(94863, josephine),
      accept(94864, josephine),
      withItem(266254, objective(94864, at("Young Forest Bear", 47.2, 77.3, maps.elwynn),
        "Look south-east of Goldshire, on the way to the Maclure farm. Use the third rod on a Young Forest Bear away from other mobs.", "Tame a Young Forest Bear")),
      finish(94864, josephine, "Turn in to Josephine for Tame Beast and the basic pet commands."),
      accept(94793, josephine),
      finish(94793, isaac, "Find Isaac nearby in Goldshire. Learn pet feeding and training before taming a pet to keep."),
    },
  })

  local keryn = at("Keryn Sylvius", 43.87, 65.94, maps.elwynn)
  local shaw = at("Master Mathias Shaw", 78.31, 70.74, maps.stormwind)
  local hogral = at("Hogral Bakkan", 47.56, 52.61, maps.dunMorogh)
  local hulfdan = at("Hulfdan Blackbeard", 51.96, 14.84, maps.ironforge)
  local onin = at("Onin MacHammar", 25.16, 44.45, maps.dunMorogh)
  local syurna = at("Syurna", 36.99, 21.91, maps.darnassus)
  local dwarvesAndGnomes = { "DWARF", "GNOME" }

  q(2205, "Seek out SI: 7", 10, 10, nil, nil, "ROGUE")
  q(2206, "Snatch and Grab", 10, 10, 2205, nil, "ROGUE")
  side({ id = "rogue-blade-human", title = "Rogue: Snatch and Grab",
    zone = maps.elwynn, levels = { 10, 12 }, class = "ROGUE", start = "HUMAN", sources = { rogueSource },
    steps = {
      accept(2205, keryn, "Find Keryn upstairs at the Goldshire inn. Learn Pick Pocket if you still need it."),
      finish(2205, shaw, "Take Keryn's package to Mathias Shaw upstairs at SI:7 in Old Town."),
      accept(2206, shaw),
      objective(2206, at("Defias Dockmaster", 48.1, 87.0, maps.elwynn),
        "Go south to Jerod's Landing. Stealth past the campfire and use Pick Pocket on the Defias Dockmaster for his schedule.", "Defias Shipping Schedule"),
      finish(2206, shaw, "Bring the schedule back to Shaw for the Blade of Cunning."),
    },
  })

  q(2218, "Road to Salvation", 10, 10, nil, nil, "ROGUE")
  q(2238, "Simple Subterfugin'", 10, 10, 2218, nil, "ROGUE")
  q(2239, "Onin's Report", 10, 10, 2238, nil, "ROGUE")
  side({ id = "rogue-blade-dun-morogh", title = "Rogue: Road to Salvation",
    zone = maps.dunMorogh, levels = { 10, 12 }, class = "ROGUE", start = dwarvesAndGnomes, sources = { rogueSource },
    steps = {
      accept(2218, hogral),
      finish(2218, hulfdan, "Follow the road to Ironforge and find Hulfdan in the Forlorn Cavern."),
      accept(2238, hulfdan),
      finish(2238, onin, "Head west to Gnomeregan. Follow the ramp that wraps around the tall pillar outside to find Onin at the top."),
      accept(2239, onin),
      finish(2239, hulfdan, "Take the report back to Hulfdan for the Blade of Cunning."),
    },
  })

  local syurnaIntro = takeIntro("teldrassil", 2241)
  q(2242, "Destiny Calls", 10, 10, 2241, nil, "ROGUE")
  side({ id = "rogue-blade-night-elf", title = "Rogue: Destiny Calls",
    zone = maps.teldrassil, levels = { 10, 12 }, class = "ROGUE", start = "NIGHTELF", sources = { rogueSource },
    steps = {
      syurnaIntro[1], syurnaIntro[2],
      accept(2242, syurna, "Speak to Syurna again in the Cenarion Enclave. Learn Pick Pocket if you still need it."),
      objective(2242, at("Sethir the Ancient", 37.1, 22.8, maps.teldrassil),
        "Find Sethir among the harpies north of the Oracle Glade. Approach in Stealth and pickpocket his journal. Try at level 12 if he spots you.", "Sethir's Journal"),
      finish(2242, syurna, "Take the journal to Syurna for the Blade of Cunning."),
    },
  })

  local renzik = at('Renzik "The Shiv"', 78.29, 71.14, maps.stormwind)
  local jannok = at("Jannok Breezesong", 56.38, 60.14, maps.teldrassil)
  local erion = at("Erion Shadewhisper", 34.52, 25.93, maps.darnassus)
  local lucius = at("Lucius", 22.97, 52.04, maps.redridge)
  q(2300, "SI:7", 16, 16, 2205, nil, "ROGUE")
  B.quest[2300].race = "HUMAN"
  q(2299, "To Hulfdan!", 16, 16, 2218, nil, "ROGUE")
  B.quest[2299].race = dwarvesAndGnomes
  q(2298, "Kingly Shakedown", 16, 16, 2299, nil, "ROGUE")
  B.quest[2298].race = dwarvesAndGnomes
  q(2259, "Erion Shadewhisper", 16, 16, 2241, nil, "ROGUE")
  B.quest[2259].race = "NIGHTELF"
  q(2260, "Erion's Behest", 16, 16, 2259, nil, "ROGUE")
  B.quest[2260].race = "NIGHTELF"
  q(2281, "Redridge Rendezvous", 16, 16, nil, nil, "ROGUE")
  q(2282, "Alther's Mill", 20, 16, 2281, nil, "ROGUE")
  for _, id in ipairs({ 2300, 2299, 2298, 2259, 2260 }) do B.breadcrumb(id, 2281) end
  side({ id = "rogue-lockpicking", title = "Rogue: Lockpicking",
    zone = maps.redridge, levels = { 16, 20 }, class = "ROGUE",
    sources = { lockSource, "https://www.foreverwisp.com/guides/wow-forever-alliance-skyborne-leveling-guide" },
    steps = {
      accept(2300, keryn, "After Seek out SI: 7, take Keryn's referral. If you are already in Stormwind, check Renzik for Redridge Rendezvous first."),
      finish(2300, renzik),
      accept(2299, hogral, "After Road to Salvation, take Hogral's referral. If you are already in Stormwind, check Renzik for Redridge Rendezvous first."),
      finish(2299, hulfdan),
      accept(2298, hulfdan),
      finish(2298, renzik, "Take the Deeprun Tram from Ironforge to Stormwind and find Renzik in the SI:7 barracks."),
      accept(2259, jannok, "After The Apple Falls, take Jannok's referral. If you are already on the mainland, check Renzik for Redridge Rendezvous first."),
      finish(2259, erion),
      accept(2260, erion),
      finish(2260, renzik, "Take the Alliance route to Stormwind and find Renzik in the SI:7 barracks in Old Town."),
      accept(2281, renzik, "Take Renzik's assignment at SI:7 in Old Town. Train Pick Lock with a Rogue trainer before leaving Stormwind."),
      finish(2281, lucius, "Find Lucius on the dock just west of the Lakeshire bridge."),
      accept(2282, lucius, "Take the quest and check that you have Thieves' Tools. Keep them in your bags."),
      objective(2282, at("Lucius's Lockbox", 46.95, 44.69, maps.redridge),
        "Cast Pick Lock on the practice boxes at Alther's Mill. At skill 25, open Lucius's Lockbox for the token.", "Token of Thievery"),
      finish(2282, lucius, "Bring Lucius the token. Aim for skill 80 before the poison job. If the practice boxes go grey early, use Heavy Bronze Lockboxes from skill 25 and Waterlogged Footlockers in Lake Everstill from 70."),
    },
  })

  local kearnen = at("Agent Kearnen", 68.49, 70.08, maps.westfall)
  local doc = at("Doc Mixilpixil", 80.06, 69.9, maps.stormwind)
  q(2360, "Mathias and the Defias", 20, 20, nil, nil, "ROGUE")
  q(2359, "Klaven's Tower", 24, 20, 2360, nil, "ROGUE")
  q(2607, "The Touch of Zanzil", 20, 20, 2359, nil, "ROGUE")
  q(2608, "The Touch of Zanzil", 20, 20, 2607, nil, "ROGUE")
  q(2609, "The Touch of Zanzil", 20, 20, 2608, nil, "ROGUE")
  side({ id = "rogue-poisons", title = "Rogue: Poisons and the Zanzil Cure",
    zone = maps.westfall, levels = { 20, 26 }, class = "ROGUE", sources = { poisonSource, rogueSource, lockSource },
    steps = {
      accept(2360, shaw, "Accept from Shaw upstairs at SI:7. Before leaving, train Pick Pocket and Pick Lock, carry Thieves' Tools and aim for Lockpicking 80."),
      finish(2360, kearnen, "Look for the stealthed agent by a tree south of the Westfall road into Duskwood."),
      accept(2359, kearnen, "Take the tower assignment. Read Kearnen's Journal for clues and bring help if the guards are too strong."),
      objective(2359, at("Duskwood Chest", 70.41, 73.93, maps.westfall),
        "Pickpocket the Malformed Defias Drone outside for the Defias Tower Key. Sneak upstairs and use Pick Lock on the Duskwood Chest for Klaven's journal. Sap Klaven if you can approach safely, or clear the room with help.",
        "Defias Tower Key", "Klaven Mortwake's Journal"),
      finish(2359, shaw, "Take the key and journal back to Shaw. This unlocks Poisons and awards the Thistle Tea recipe."),
      accept(2607, shaw, "Take Shaw's follow-up to cure the Touch of Zanzil. If already cured, use Next to skip the cure chain."),
      finish(2607, doc, "Find the Doc in the cellar of the SI:7 barracks."),
      accept(2608, doc),
      objective(2608, doc, "Target Doc Mixilpixil and type /lay so he can examine you. Wait for the quest to complete.", "Examination"),
      finish(2608, doc),
      accept(2609, doc),
      objective(2609, at("The Finest Thread", 50.77, 60.38, maps.stormwind),
        "Loot the thread at The Finest Thread in the Mage Quarter. Buy flowers from Bernard or Felicia Gump and a Leaded Vial from Jasper Fel at SI:7. Ask an engineer or check the Auction House for a Bronze Tube.",
        "Simple Wildflowers", "Leaded Vial", "Bronze Tube", "Spool of Light Chartreuse Silk Thread"),
      finish(2609, doc, "Turn in the four supplies and use the Eau de Mixilpixil to clear the poison."),
    },
  })

  -- These maps are outside the main route. The arrow uses the client's world extents.
  local alterac, tirisfal, silverpine, hillsbrad, stonetalon = 1416, 1420, 1421, 1424, 1442
  route.extents[alterac] = { 2800.0, 1866.667 }
  route.extents[tirisfal] = { 4518.75, 3012.5 }
  route.extents[silverpine] = { 4200.0, 2800.0 }
  route.extents[hillsbrad] = { 3200.0, 2133.333 }
  route.extents[stonetalon] = { 4883.333, 3256.25 }
  local deadDrop = at("Dead Drop", 47.12, 70.99, silverpine)
  local sfk = at("Shadowfang Keep", 44.8, 67.8, silverpine)
  local sfkSource = "https://www.zockify.com/forever/dungeons/shadowfang-keep/"
  local smSource = "https://www.zockify.com/forever/dungeons/scarlet-monastery/"

  q(78261, "The Horn of Xelthos", 23, 20, nil, true, "ROGUE")
  q(78307, "The Horn of Xelthos", 23, 20, 78261, true, "ROGUE")
  side({ id = "rogue-horn-of-xelthos", title = "Rogue: The Horn of Xelthos",
    zone = silverpine, levels = { 20, 26 }, class = "ROGUE",
    sources = { sfkSource, "https://www.icy-veins.com/wow-forever/shadowfang-keep-quests/",
      "https://www.wowhead.com/forever/quest=78270/goblin-lockpicks" },
    steps = {
      accept(78261, deadDrop, "Check your mail for C's letter. Find the Dead Drop in a hut near Pyrewood Village, below the road to Shadowfang Keep. This is a solo job."),
      objective(78261, at("Veenix", 58.22, 51.74, stonetalon),
        "Speak to Veenix about Goblin Lockpicks in Windshear Crag, Stonetalon Mountains. Pickpocket Venture Co. workers for a Work Order and give it to him for a Breaching Charge. Use Next once you have the charge."),
      withItem(210186, objective(78261, sfk,
        "Enter Shadowfang Keep alone. Use the Breaching Charge at the locked courtyard gate. Pickpocket Gemela in the dining hall and Gefell up the stairs past it for the two half-keys. Use Next once you have both.")),
      objective(78261, nil,
        "Combine the half-keys somewhere safe. This breaks Stealth. Return to the courtyard stables and open the locked chest with the Twin Key.", "Horn of Xelthos"),
      finish(78261, deadDrop),
      accept(78307, deadDrop, "Visit an Alliance capital and wait for C's payment letter. Return to the Dead Drop and accept the payment quest."),
      finish(78307, deadDrop, "Collect the Pyrewood Signet Ring from the Dead Drop."),
    },
  })

  local fahrad = at("Fahrad", 84.45, 80.32, alterac)
  q(6681, "The Manor, Ravenholdt", 24, 24, nil, nil, "ROGUE")
  side({ id = "rogue-ravenholdt-manor", title = "Rogue: Ravenholdt Invitation",
    zone = alterac, levels = { 24, 30 }, class = "ROGUE",
    sources = { "https://senseos.gg/wiki/wow-forever/quests/6681/the-manor-ravenholdt/", "https://forg.gg/en/forever/tips/rogue-quests" },
    steps = {
      withItem(17126, accept(6681, { name = "Elegant Letter" },
        "Check your mail from level 24. Open the Elegant Letter and accept its quest. Keep the Seal of Ravenholdt.")),
      objective(6681, at("Ravenholdt cave", 78.6, 17.8, hillsbrad),
        "Take the uphill trail north of Durnholde Keep. In the cave, use Detect Traps or approach the chest in Stealth. Leave the trapped chest closed and continue through until you get credit.", "Rite of Cunning"),
      finish(6681, fahrad, "Follow the trail to Ravenholdt Manor and give Fahrad the seal."),
    },
  })

  local myrokos = at("Myrokos Silentform", 84.93, 80.38, alterac)
  q(96779, "Syndicate Sabotage", 24, 24, nil, true, "ROGUE")
  side({ id = "rogue-syndicate-sabotage", title = "Rogue: Syndicate Sabotage",
    zone = alterac, levels = { 24, 30 }, class = "ROGUE",
    sources = { "https://azeroth.wiki/forever/quests/syndicate-sabotage" },
    steps = {
      accept(96779, myrokos, "Find Myrokos Silentform at Ravenholdt Manor. Reach the manor through the cave north of Durnholde Keep."),
      objective(96779, at("Lord Tomas", 79.4, 46.2, hillsbrad),
        "Enter Durnholde Keep in Hillsbrad. Find Lord Tomas inside and kill him. Clear nearby Syndicate guards if needed.", "Lord Tomas slain"),
      finish(96779, myrokos),
    },
  })

  q(78676, "The Eye of Bhossca", 35, 30, 78307, true, "ROGUE")
  q(78699, "The Eye of Bhossca", 35, 30, 78676, true, "ROGUE")
  side({ id = "rogue-eye-of-bhossca", title = "Rogue: The Eye of Bhossca",
    zone = silverpine, levels = { 30, 30 }, class = "ROGUE",
    sources = { smSource, "https://www.wowhead.com/forever/quest=78676/the-eye-of-bhossca" },
    steps = {
      accept(78676, deadDrop, "After collecting the Horn job's payment, check your mail at level 30. Take C's new solo job at the Pyrewood Dead Drop."),
      objective(78676, at("Scarlet Monastery stables", 81.2, 32.1, tirisfal),
        "Go behind Scarlet Monastery and loot the Scarlet Initiate's Uniform from the Supply Locker in the stables. Use Next when you have the disguise."),
      withItem(210955, objective(78676, nil,
        "Enter the Graveyard wing alone. Pickpocket a Scarlet Scryer for the Scryer's Key. Enter the Library in disguise and open the Personal Letterbox for the Confidential Message. Stealth and attacks drop the disguise. Use Next after reading the message.")),
      objective(78676, nil,
        "Return to the Graveyard and /sit on both benches by the statues. Listen for the clicks and moving stone. Find the Stone Coffer in the north mausoleum and loot the Reliquary Key. Use Next when you have it."),
      withItem(210955, objective(78676, nil,
        "Put the disguise back on and return to the Library. Open the locked reliquary in the small side room on the left with the Reliquary Key.", "Eye of Bhossca")),
      finish(78676, deadDrop),
      accept(78699, deadDrop, "Visit an Alliance capital and wait for C's payment letter. Then take the payment quest at the Dead Drop."),
      finish(78699, deadDrop, "Collect the Ruby-Adorned Blade from the Dead Drop."),
    },
  })
end

-- Priest, Mage and Warlock
do
  local m, at = B.maps, B.at
  local function garments(sectionId, zone, races, referral, trial, teacher, trainer, patient, source)
    B.q(referral, "In Favor of the Light", 4, 5, nil, nil, "PRIEST")
    B.q(trial, "Garments of the Light", 4, 5, referral, nil, "PRIEST")
    side({ id = sectionId, title = "Priest: Garments of the Light", zone = zone, levels = { 5, 6 },
      class = "PRIEST", start = races, sources = { source, "https://www.icy-veins.com/wow-forever/priest-class-quests" },
      steps = {
        B.accept(referral, teacher),
        B.finish(referral, trainer),
        B.accept(trial, trainer, "Train Lesser Heal (Rank 2) and Power Word: Fortitude before you leave."),
        B.objectiveAt(trial, patient, "Target " .. patient.name ..
          ". Cast Lesser Heal (Rank 2) and then Power Word: Fortitude.", "Heal and fortify " .. patient.name),
        B.finish(trial, trainer, "Return for your Friar's Robes of the Light."),
      },
    })
  end
  garments("priest-garments-elwynn", m.elwynn, "HUMAN", 5623, 5624,
    at("Priestess Anetta", 49.81, 39.49, m.elwynn), at("Priestess Josetta", 43.28, 65.72, m.elwynn),
    at("Guard Roberts", 48.1, 68.0, m.elwynn), "https://bindonforever.com/quest/5624")
  garments("priest-garments-dun-morogh", m.dunMorogh, { "DWARF", "GNOME" }, 5626, 5625,
    at("Branstock Khalder", 28.6, 66.39, m.dunMorogh), at("Maxan Anvol", 47.34, 52.19, m.dunMorogh),
    at("Mountaineer Dolf", 45.8, 54.4, m.dunMorogh), "https://questing.wiki/wow-forever/quests/5625/")
end

-- Alliance class quests for Priest, Mage and Warlock, levels 10-30.
do
  local at, q, accept, finish = B.at, B.q, B.accept, B.finish
  local objective, withItem = B.objectiveAt, B.withItem
  local m = B.maps

  -- Additional waypoint maps and their yard extents from Forever's UiMapAssignment.
  local barrens, arathi, tirisfal = 1413, 1417, 1420
  local hillsbrad, ashenvale, needles, dustwallow = 1424, 1440, 1441, 1445
  route.extents[barrens] = { 10133.333, 6756.25 }
  route.extents[arathi] = { 3600.0, 2400.0 }
  route.extents[tirisfal] = { 4518.75, 3012.5 }
  route.extents[hillsbrad] = { 3200.0, 2133.333 }
  route.extents[ashenvale] = { 5766.666, 3843.75 }
  route.extents[needles] = { 4400.0, 2933.333 }
  route.extents[dustwallow] = { 5250.0, 3500.0 }

  local priest = "PRIEST"
  local laurena = at("High Priestess Laurena", 49.53, 44.6, m.stormwind)
  local rohan = at("High Priest Rohan", 24.73, 8.16, m.ironforge)
  local mims = at("High Priestess Mims", 24.59, 10, m.ironforge)
  local alathea = at("Priestess Alathea", 39.52, 81.2, m.darnassus)
  local priestSources = {
    "https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior",
    "https://www.icy-veins.com/wow-forever/priest-class-quests",
  }

  q(94773, "Divine Grace", 10, 10, nil, true, priest)
  side({ id = "priest-divine-grace", title = "Priest: Divine Grace", zone = m.stormwind,
    levels = { 10, 10 }, class = priest, start = "HUMAN", sources = priestSources, steps = {
      accept(94773, laurena, "Find Laurena inside the Cathedral of Light. If you have a Divine Grace referral from another trainer, hand it in here."),
      finish(94773, laurena, "Speak with Laurena to learn Divine Grace."),
    },
  })

  q(5676, "Arcane Feedback", 20, 20, nil, nil, priest)
  side({ id = "priest-feedback", title = "Priest: Feedback", zone = m.stormwind,
    levels = { 20, 20 }, class = priest, start = "HUMAN", sources = priestSources, steps = {
      accept(5676, laurena, "Find Laurena in the Cathedral of Light. If you have an Arcane Feedback referral, hand it in here."),
      finish(5676, laurena, "Speak with Laurena in the cathedral to learn Feedback."),
    },
  })

  q(5639, "Desperate Prayer", 10, 10, nil, true, priest)
  side({ id = "priest-desperate-prayer", title = "Priest: Desperate Prayer", zone = m.ironforge,
    levels = { 10, 10 }, class = priest, start = "DWARF", sources = priestSources, steps = {
      accept(5639, rohan, "Find Rohan in the Hall of Mysteries in Ironforge's Mystic Ward. If you have a Desperate Prayer referral, hand it in here."),
      finish(5639, rohan, "Speak with Rohan to learn Desperate Prayer."),
    },
  })

  q(5641, "Chastise", 20, 20, nil, true, priest)
  side({ id = "priest-chastise", title = "Priest: Chastise", zone = m.ironforge,
    levels = { 20, 20 }, class = priest, start = "DWARF",
    sources = { "https://questing.wiki/wow-forever/quests/5641/", "https://db.icy-veins.com/wow-forever/quests/5641" },
    steps = {
      accept(5641, rohan, "Speak with Rohan in the Hall of Mysteries. If you already have a Chastise referral, hand it in to him."),
      finish(5641, rohan, "Speak with Rohan to learn Chastise. Ask your trainer about Fear Ward during the same visit."),
    },
  })

  q(94817, "Confounding Flash", 10, 10, nil, true, priest)
  side({ id = "priest-confounding-flash", title = "Priest: Confounding Flash", zone = m.ironforge,
    levels = { 10, 10 }, class = priest, start = "GNOME", sources = priestSources, steps = {
      accept(94817, mims, "Find Mims in the Hall of Mysteries. If you took a Confounding Flash referral from Maxan or another trainer, hand it in here."),
      finish(94817, mims, "Speak with Mims to learn Confounding Flash."),
    },
  })

  q(94818, "Contingency Plan", 20, 20, nil, true, priest)
  side({ id = "priest-contingency-plan", title = "Priest: Contingency Plan", zone = m.ironforge,
    levels = { 20, 20 }, class = priest, start = "GNOME", sources = priestSources, steps = {
      accept(94818, mims, "Return to Mims in the Hall of Mysteries. If you have a Contingency Plan referral, hand it in here."),
      finish(94818, mims, "Speak with Mims to learn Contingency Plan."),
    },
  })

  q(5627, "Stars of Elune", 10, 10, 5629, nil, priest)
  B.quest[5627].race = "NIGHTELF"
  inline("teldrassil", "turnin", 5629, {
    accept(5627, alathea, "Take Stars of Elune while you are at the Temple of the Moon."),
    finish(5627, alathea, "Speak with Alathea again to learn Starshards."),
  })

  q(5674, "Elune's Grace", 20, 20, nil, nil, priest)
  side({ id = "priest-elunes-grace", title = "Priest: Elune's Grace", zone = m.darnassus,
    levels = { 20, 20 }, class = priest, start = "NIGHTELF", sources = priestSources, steps = {
      accept(5674, at("Astarii Starseeker", 38.33, 80.95, m.darnassus),
        "From Stormwind Harbor, sail to Auberdine and change boats for Rut'theran. Take the pink portal to Darnassus and find Astarii in the Temple of the Moon."),
      finish(5674, alathea, "Speak with Alathea in the same temple to learn Elune's Grace."),
    },
  })

  local mage = "MAGE"
  local allianceMages = { "HUMAN", "GNOME", "SKYBORNE" }
  local jennea = at("Jennea Cannon", 49.56, 85.8, m.stormwind)
  local bink = at("Bink", 27.25, 8.3, m.ironforge)
  local wynne = at("Wynne Larson", 51.84, 83.51, m.stormwind)
  local andromath = at("High Sorcerer Andromath", 48.71, 87.62, m.stormwind)
  local tabetha = at("Tabetha", 46.06, 57.09, dustwallow)
  local tirth = at("Magus Tirth", 78.29, 75.7, needles)
  local garion = at("Garion Wendell", 48.96, 86.52, m.stormwind)
  local mageSources = { "https://www.icy-veins.com/wow-forever/mage-class-quests" }

  q(1860, "Speak with Jennea", 10, 10, nil, nil, mage)
  q(1861, "Mirror Lake", 10, 10, 1860, nil, mage)
  side({ id = "mage-mirror-lake", title = "Mage: Mirror Lake", zone = m.elwynn,
    levels = { 10, 10 }, class = mage, start = "HUMAN", sources = mageSources, steps = {
      accept(1860, at("Zaldimar Wefhellt", 43.25, 66.19, m.elwynn), "Take the referral upstairs in the Goldshire inn."),
      finish(1860, jennea, "Go to the Wizard's Sanctum at the top of the Mage Tower in Stormwind."),
      accept(1861, jennea, "Take Jennea's Flask and head back out to western Elwynn Forest."),
      withItem(7207, objective(1861, at("Mirror Lake waterfall", 28.6, 61.4, m.elwynn),
        "Stand at the base of the waterfall at Mirror Lake and fill Jennea's Flask.", "Mirror Lake Water Sample")),
      finish(1861, jennea, "Bring the water sample back to Jennea and choose a weapon or off-hand."),
    },
  })

  q(1879, "Speak with Bink", 10, 10, nil, nil, mage)
  q(1880, "Mage-tastic Gizmonitor", 10, 10, 1879, nil, mage)
  side({ id = "mage-gizmonitor", title = "Mage: Mage-tastic Gizmonitor", zone = m.dunMorogh,
    levels = { 10, 10 }, class = mage, start = "GNOME", sources = mageSources, steps = {
      accept(1879, at("Magis Sparkmantle", 47.5, 52.08, m.dunMorogh), "Take the referral from Magis in Kharanos."),
      finish(1879, bink, "Find Bink in the Mystic Ward in Ironforge."),
      accept(1880, bink, "Take Bink's recovery job before heading west to Gnomeregan."),
      objective(1880, at("Bink's Toolbox", 27.72, 36.42, m.dunMorogh),
        "North of Gnomeregan, check the toolbox in the right-hand hut. Clear the leper gnomes one at a time, or Polymorph an extra before looting.",
        "Mage-tastic Gizmonitor"),
      finish(1880, bink, "Take the gizmonitor back to Bink and choose a weapon or off-hand."),
    },
  })

  q(1920, "Investigate the Blue Recluse", 16, 15, nil, nil, mage)
  q(1921, "Gathering Materials", 15, 15, 1920, nil, mage)
  q(1941, "Manaweave Robe", 15, 15, 1921, nil, mage)
  side({ id = "mage-manaweave-robe", title = "Mage: Manaweave Robe", zone = m.stormwind,
    levels = { 15, 17 }, class = mage, start = allianceMages, sources = mageSources, steps = {
      accept(1920, jennea, "Take the quest and pick up the Cantation of Manifestation and Chest of Containment Coffers behind Jennea."),
      withItem(7308, objective(1920, at("The Blue Recluse", 51.2, 94, m.stormwind),
        "Use the Cantation inside the Blue Recluse. Fight a Rift Spawn until it falls stunned. Use the Chest on it, then loot the coffer that appears. Capture three.",
        "3 Filled Containment Coffers")),
      finish(1920, jennea),
      accept(1921, jennea, "Keep 10 Linen Cloth from humanoid drops or buy it. The gems are in Loch Modan."),
      objective(1921, at("Silver Stream Mine", 35.26, 21.97, m.lochModan),
        "Take the tram to Ironforge and head to northern Loch Modan. Search the Miners' League Crates in Silver Stream Mine for 6 gems.",
        "6 Charged Rift Gems", "10 Linen Cloth"),
      finish(1921, wynne, "Take the gems and cloth to Larson Clothiers in Stormwind's Mage Quarter."),
      accept(1941, wynne),
      finish(1941, wynne, "Speak to Wynne again to collect your Manaweave Robe."),
    },
  })

  q(79093, "Rumi of Gnomeregan: The Collected Works", 20, 1, nil, true, mage)
  q(97286, "Research Access", 20, 1, nil, true, mage)
  B.breadcrumb(79093, 97286)
  side({ id = "mage-research-access", title = "Mage: Study", zone = m.westfall,
    levels = { 15, 20 }, class = mage, start = allianceMages,
    sources = {
      "https://www.warcrafttavern.com/forever/guides/library-books",
      "https://www.wowhead.com/forever/quest=97286/research-access",
      "https://news.blizzard.com/en-gb/article/24315281/wow-forever-hotfixes-november-6-2026",
    },
    steps = {
      accept(79093, at("Gnomish Tome", 52.7, 53.8, m.westfall),
        "Loot the Gnomish Tome inside the Sentinel Hill inn. The same book is upstairs at Thelsamar's inn. If you have donated a library book already, take Research Access from Garion first."),
      finish(79093, garion, "Turn in the book to Garion inside the Wizard's Sanctum in Stormwind's Mage Quarter."),
      accept(97286, garion, "After donating any library book, ask Garion for Research Access."),
      finish(97286, garion, "Complete Research Access to learn Study."),
    },
  })

  q(1939, "High Sorcerer Andromath", 26, 26, nil, nil, mage)
  q(1938, "Ur's Treatise on Shadow Magic", 28, 26, 1939, nil, mage)
  q(1940, "Pristine Spider Silk", 26, 26, 1938, nil, mage)
  q(1942, "Astral Knot Garment", 26, 26, 1940, nil, mage)
  side({ id = "mage-astral-knot", title = "Mage: Astral Knot Garment", zone = m.stormwind,
    levels = { 26, 30 }, class = mage, start = allianceMages, sources = mageSources, steps = {
      accept(1939, jennea),
      finish(1939, andromath, "Find Andromath on the spiral ramp just outside the portal room of the Mage Tower."),
      accept(1938, andromath),
      objective(1938, at("Tower of Ilgalar", 73.77, 47.61, m.redridge),
        "Enter the Tower of Ilgalar in eastern Redridge. Pull the gnolls and hounds carefully and take the book from the upper floor. You can leave Morganth alone.",
        "Ur's Treatise on Shadow Magic"),
      finish(1938, andromath),
      accept(1940, andromath),
      objective(1940, at("Raven Hill Cemetery", 22.2, 37.9, m.duskwood),
        "Collect 8 silk from Carrion Recluses in the cemetery or Black Widow Hatchlings on the slopes to the east. Give Mor'Ladim room.",
        "8 Pristine Spider Silk"),
      finish(1940, wynne, "Bring the silk to Larson Clothiers in Stormwind's Mage Quarter."),
      accept(1942, wynne),
      finish(1942, wynne, "Speak to Wynne again and choose the Astral Knot Robe or Blouse."),
    },
  })

  q(1947, "Journey to the Marsh", 38, 30, nil, nil, mage)
  q(1948, "Items of Power", 40, 30, 1947, nil, mage)
  q(1949, "Hidden Secrets", 38, 30, 1947, nil, mage)
  q(1950, "Get the Scoop", 30, 30, 1949, nil, mage)
  q(1951, "Rituals of Power", 40, 30, 1950, nil, mage)
  q(1952, "Mage's Wand", 40, 30, { 1948, 1951 }, nil, mage)
  side({ id = "mage-wand", title = "Mage: Mage's Wand", zone = m.stormwind,
    levels = { 30, 30 }, class = mage, start = allianceMages, sources = mageSources, steps = {
      accept(1947, jennea, "This opens at 30. Bring help for enemies in the high 30s and the Scarlet Monastery Library. Bring 1 Jade or buy it before leaving."),
      finish(1947, tabetha, "Take the Menethil Harbor ship to Theramore. Follow the road inland and approach Tabetha's hut from the west."),
      accept(1948, tabetha, "Take Tabetha's Instructions. You will gather the Jade and charged bramble on the Eastern Kingdoms leg."),
      accept(1949, tabetha),
      finish(1949, tirth, "Find Magus Tirth at the Mirage Raceway in the Shimmering Flats."),
      accept(1950, tirth),
      objective(1950, at('"Plucky" Johnson', 79.61, 75.63, needles),
        "Find the chicken by the racetrack tower. Target it, type /beckon, then ask the human who appears for the phrase.",
        "Find the strongbox phrase"),
      finish(1950, tirth),
      accept(1951, tirth),
      objective(1948, at("Witherbark Village", 65.3, 65.2, arathi),
        "Get 10 Witherbark Totem Sticks in Arathi. Use them on the central stone at the Circle of Outer Binding (52, 50). Loot the bramble after the strike and keep 1 Jade.",
        "Bolt Charged Bramble", "Jade"),
      objective(1951, at("Scarlet Monastery", 85, 32, tirisfal),
        "Enter the Library wing with a group. Loot Rituals of Power from the left bookshelf at the start of the long hall before Arcanist Doan.",
        "Rituals of Power"),
      finish(1948, tabetha, "Return to Tabetha in Dustwallow Marsh with the bramble and Jade."),
      finish(1951, tabetha),
      accept(1952, tabetha),
      finish(1952, tabetha, "Wait for Tabetha to finish her ritual, then talk to her and choose your wand."),
    },
  })

  local warlock = "WARLOCK"
  local allianceWarlocks = { "HUMAN", "GNOME" }
  local gakin = at("Gakin the Darkbinder", 39.22, 85.23, m.stormwind)
  local lago = at("Lago Blackwrench", 47.63, 9.26, m.ironforge)
  local circle = at("Summoning Circle", 39, 84.5, m.stormwind)
  local takar = at("Takar the Seer", 49.31, 57.1, barrens)
  local strahad = at("Strahad Farsan", 62.63, 35.5, barrens)
  local krom = at("Krom Stoutarm", 74.19, 9.39, m.ironforge)
  local zardeth = at("Zardeth of the Black Claw", 40.14, 85.31, m.stormwind)
  local warlockSources = { "https://www.icy-veins.com/wow-forever/warlock-class-quests" }

  q(1685, "Gakin's Summons", 10, 10, nil, nil, warlock)
  q(1715, "The Slaughtered Lamb", 10, 10, nil, nil, warlock)
  q(1688, "Surena Caledon", 10, 10, nil, nil, warlock)
  q(1689, "The Binding", 10, 10, 1688, nil, warlock)
  B.quest[1685].race = "HUMAN"
  B.quest[1715].race = "GNOME"
  B.breadcrumb(1685, 1688)
  B.breadcrumb(1715, 1688)
  side({ id = "warlock-voidwalker", title = "Warlock: Voidwalker", zone = m.stormwind,
    levels = { 10, 12 }, class = warlock, start = allianceWarlocks, sources = warlockSources, steps = {
      accept(1685, at("Remen Marcot", 44.49, 66.27, m.elwynn), "Take the referral from Remen in the basement of the Goldshire inn."),
      finish(1685, gakin, "Go downstairs in the Slaughtered Lamb in Stormwind's Mage Quarter."),
      accept(1715, lago, "Find Lago in Ironforge's Forlorn Cavern and take his referral."),
      finish(1715, gakin, "Take the Deeprun Tram to Stormwind and find Gakin below the Slaughtered Lamb in the Mage Quarter."),
      accept(1688, gakin),
      objective(1688, at("Surena Caledon", 71.01, 80.77, m.elwynn),
        "Go to the Brackwell Pumpkin Patch in southeast Elwynn. Clear nearby Defias, defeat Surena and loot her choker.", "Surena's Choker"),
      finish(1688, gakin),
      accept(1689, gakin, "Take the Bloodstone Choker. Heal and have your Imp ready before you go down to the circle."),
      withItem(6928, objective(1689, circle, "Follow the passage down from Gakin. Use the Bloodstone Choker on the summoning circle and defeat the Voidwalker.",
        "Summoned Voidwalker")),
      finish(1689, gakin, "Return to Gakin to learn Summon Voidwalker. Use Drain Soul on an enemy that grants experience to get a Soul Shard for the summon."),
    },
  })

  q(1717, "Gakin's Summons", 20, 20, nil, nil, warlock)
  q(1716, "Devourer of Souls", 20, 20, nil, nil, warlock)
  q(1738, "Heartswood", 20, 20, 1716, nil, warlock)
  q(1739, "The Binding", 20, 20, 1738, nil, warlock)
  q(65602, "What Is Love?", 20, 20, 1716, true, warlock)
  q(65603, "The Binding", 20, 20, 65602, true, warlock)
  B.quest[1717].race = "GNOME"
  B.breadcrumb(1717, 1716)
  side({ id = "warlock-sayaad", title = "Warlock: Succubus and Incubus", zone = m.stormwind,
    levels = { 20, 24 }, class = warlock, start = allianceWarlocks,
    sources = {
      "https://www.icy-veins.com/wow-forever/warlock-class-quests",
      "https://www.wowhead.com/forever/quest=1739/the-binding",
      "https://db.icy-veins.com/wow-forever/quests/65602",
      "https://conquestcapped.com/guides/wow-forever/wow-forever-warlock-quests/",
      "https://wowforeverclasses.com/articles/wow-forever-boats-zeppelins-flight-paths",
    },
    steps = {
      accept(1717, lago, "Take Lago's referral in the Forlorn Cavern if you are starting in Ironforge. If you are already in Stormwind, pick up Devourer of Souls directly from Gakin."),
      finish(1717, gakin, "Take the tram to Stormwind. Gakin is below the Slaughtered Lamb in the Mage Quarter."),
      accept(1716, gakin, "Take Devourer of Souls. A hearthstone set to Stormwind saves the return crossing."),
      finish(1716, takar, "Sail from Stormwind Harbor to Auberdine. In Ashenvale take Talondeep Path (42, 71) to Stonetalon, then the southeast road into the Barrens. Takar camps east of Camp Taurajo. Give Horde posts a wide berth."),
      accept(1738, takar, "Take Heartswood to unlock the Succubus. If you only want the Incubus, use Next on this pickup."),
      accept(65602, takar, "Take What Is Love? to unlock the Incubus. Wait for Takar to finish speaking if needed. Use Next here if you only want the Succubus."),
      objective(1738, at("Heartswood", 31.53, 31.52, ashenvale),
        "Head back into northwest Ashenvale. At Ordil'Aran, collect the Heartswood from the roots of the tree among the ruins. Watch for Dark Strand Excavators.",
        "Heartswood"),
      objective(65602, at("Wooden Figurine", 26, 22, ashenvale),
        "Go north past Maestra's Post to the house. Take the Unlit Torch from the table outside, light it at a campfire and burn the cart. Loot the figurine upstairs while the occupants are out.",
        "Wooden Figurine"),
      finish(1738, gakin, "Hearth to Stormwind if bound there, or return via Auberdine. Give the Heartswood to Gakin under the Slaughtered Lamb."),
      accept(1739, gakin),
      withItem(6913, objective(1739, circle,
        "Use the Heartswood Core at the circle in the crypt below Gakin and defeat the summoned Succubus.", "Summoned Succubus")),
      finish(1739, gakin, "Speak with Gakin to learn Summon Succubus."),
      finish(65602, gakin, "Give Gakin the Wooden Figurine at the Slaughtered Lamb in Stormwind."),
      accept(65603, gakin),
      withItem("Wooden Figurine", objective(65603, circle,
        "Use the Wooden Figurine at the circle in the crypt below Gakin and defeat the summoned Incubus.", "Summoned Incubus")),
      finish(65603, gakin, "Speak with Gakin to learn Summon Incubus."),
    },
  })

  q(1798, "Seeking Strahad", 30, 30, nil, nil, warlock)
  q(1758, "Tome of the Cabal", 30, 30, 1798, nil, warlock)
  q(1802, "Tome of the Cabal", 30, 30, 1758, nil, warlock)
  q(1804, "Tome of the Cabal", 30, 30, 1802, nil, warlock)
  q(1795, "The Binding", 30, 30, 1804, nil, warlock)
  side({ id = "warlock-felhunter", title = "Warlock: Felhunter", zone = m.stormwind,
    levels = { 30, 30 }, class = warlock, start = allianceWarlocks, sources = warlockSources, steps = {
      accept(1798, gakin, "Take the referral from Gakin below the Slaughtered Lamb in Stormwind."),
      finish(1798, strahad, "Take the Booty Bay boat to Ratchet. Learn the Ratchet flight path and find Strahad uphill behind the town."),
      accept(1758, strahad),
      finish(1758, krom, "Return to the Eastern Kingdoms and find Krom in Ironforge's Hall of Explorers."),
      accept(1802, krom),
      objective(1802, at("Moldy Tome", 27.78, 72.79, hillsbrad),
        "Loot the Moldy Tome from the murloc huts west of Southshore. In Thousand Needles, enter Splithoof Hold (44, 37), keep right and loot the Damaged Chest for the Tattered Manuscript.",
        "Moldy Tome", "Tattered Manuscript"),
      finish(1802, krom, "Take both book pieces to Krom in Ironforge before hunting for the rods."),
      accept(1804, krom),
      objective(1804, at("Dragonmaw camp", 47.7, 46.1, m.wetlands),
        "Keep the Reconstructed Tome. Kill Dragonmaw Bonewarders or Shadowwarders in the Wetlands for 3 Rods of Channeling.",
        "3 Rods of Channeling"),
      finish(1804, strahad, "Bring the rods and reconstructed tome to Strahad in Ratchet."),
      accept(1795, strahad),
      withItem(6999, objective(1795, strahad,
        "Follow Strahad and wait for his acolytes to complete the circle. Use the Tome of the Cabal inside it and defeat the summoned Felhunter.",
        "Summoned Felhunter")),
      finish(1795, strahad, "Wait for Strahad to return to his spot, then speak with him to learn Summon Felhunter."),
    },
  })

  q(1740, "The Orb of Soran'ruk", 25, 20, nil, nil, warlock)
  local doan = at("Doan Karhan", 49.31, 57.21, barrens)
  side({ id = "warlock-orb-of-soranruk", title = "Warlock: The Orb of Soran'ruk", zone = barrens,
    levels = { 20, 28 }, class = warlock, start = allianceWarlocks, sources = warlockSources, steps = {
      accept(1740, doan, "Find Doan at the camp east of Camp Taurajo. Pick this up when you visit Takar if you plan to run both dungeons."),
      objective(1740, at("Blackfathom Deeps", 14, 14, ashenvale),
        "Loot 3 small fragments from Twilight Acolytes in Blackfathom Deeps. Loot the large fragment from Shadowfang Darksouls past the courtyard in Shadowfang Keep (Silverpine 45, 68).",
        "3 Soran'ruk Fragments", "Large Soran'ruk Fragment"),
      finish(1740, doan, "Bring all four fragments back to Doan and choose a staff or off-hand."),
    },
  })

  q(335, "A Noble Brew", 30, 25, nil, nil, warlock)
  q(336, "A Noble Brew", 30, 25, 335, nil, warlock)
  q(397, "You Have Served Us Well", 30, 25, 336, nil, warlock)
  side({ id = "warlock-dread-mage-hat", title = "Warlock: Dread Mage Hat", zone = m.stormwind,
    levels = { 25, 30 }, class = warlock, start = allianceWarlocks,
    sources = { "https://senseos.gg/wiki/wow-forever/quests/335/a-noble-brew/", "https://polestar.guide/guides/class/warlock/dread-mage-hat" },
    steps = {
      accept(335, zardeth, "Find Zardeth downstairs in the Slaughtered Lamb in Stormwind's Mage Quarter."),
      objective(335, at("Tear of Tilloa", 78.35, 35.95, m.duskwood),
        "Pick the Tear of Tilloa from the garden at Manor Mistmantle north of Darkshire. Then find the Musquash Root at the base of Stonewrought Dam in the Wetlands (64.8, 75.3).",
        "Tear of Tilloa", "Musquash Root"),
      finish(335, zardeth),
      accept(336, zardeth),
      finish(336, at("Lord Baurles K. Wishock", 77.88, 48.95, m.stormwind),
        "Take the Black Claw Stout to Lord Wishock in the Hall of Petitioners in Stormwind Keep."),
      accept(397, zardeth, "Return to Zardeth at the Slaughtered Lamb for your reward."),
      finish(397, at("Zggi", 40.21, 85.31, m.stormwind), "Speak with Zggi beside Zardeth to receive the Dread Mage Hat."),
    },
  })
end

-- Druid and Shaman
do
  local at, q = B.at, B.q
  local accept, finish, objectiveAt = B.accept, B.finish, B.objectiveAt
  local action, withItem = B.action, B.withItem
  local maps = B.maps
  local moonglade, ashenvale = 1450, 1440
  route.extents[moonglade] = { 2308.333, 1539.583 }
  route.extents[ashenvale] = { 5766.666, 3843.75 }

  local mathrengyl = at("Mathrengyl Bearwalker", 35.37, 8.40, maps.darnassus)
  local dendrite = at("Dendrite Starblaze", 56.21, 30.64, moonglade)
  local shrine = at(nil, 36.0, 41.42, moonglade)
  local tajarri = at("Tajarri", 36.52, 40.10, moonglade)
  local silva = at("Silva Fil'naveth", 44.1, 45.2, moonglade)
  local druid = "DRUID"
  local nightElf, allianceDruids = "NIGHTELF", { "NIGHTELF", "SKYBORNE" }

  -- Heeding the Call (5923) is already in Teldrassil. Start at its destination.
  q(5921, "Moonglade", 10, 10, nil, nil, druid)
  q(5929, "Great Bear Spirit", 10, 10, 5921, nil, druid)
  q(5931, "Back to Darnassus", 10, 10, 5929, nil, druid)
  q(6001, "Body and Heart", 10, 10, 5931, nil, druid)
  side({ id = "druid-bear-form", title = "Druid: Bear Form", zone = maps.darnassus,
    levels = { 10, 12 }, class = druid, start = nightElf,
    sources = { "QuestieDB Forever 0f7d8ad", "https://bindonforever.com/quest/6001" },
    steps = {
      accept(5921, mathrengyl, "See Mathrengyl upstairs in the Cenarion Enclave. If you have Heeding the Call, hand it in first."),
      finish(5921, dendrite, "Cast Teleport: Moonglade. Find Dendrite upstairs in Nighthaven."),
      accept(5929, dendrite),
      objectiveAt(5929, at("Great Bear Spirit", 39.1, 27.5, moonglade),
        "Follow the north shore west of Nighthaven. Speak with the Great Bear Spirit and finish its dialogue.",
        "Speak with the Great Bear Spirit"),
      finish(5929, dendrite, "Cast Teleport: Moonglade again or walk back to Dendrite."),
      accept(5931, dendrite),
      action("goto", silva, "Find Silva southwest of Nighthaven for the Druid flight to Rut'theran Village."),
      finish(5931, mathrengyl, "Take Silva's flight to Rut'theran, then go through the pink portal to Darnassus."),
      accept(6001, mathrengyl),
      withItem(15208, objectiveAt(6001, at(nil, 43.5, 45.97, maps.darkshore),
        "Take the Rut'theran boat to Auberdine. In the cave near Bashal'Aran, use Cenarion Moondust at the Moonkin Stone. Defeat Lunaclaw and speak to his spirit.",
        "Speak with Lunaclaw's spirit")),
      finish(6001, mathrengyl, "Take the Auberdine boat back to Rut'theran and return to Mathrengyl to learn Bear Form."),
    },
  })

  -- Forever captures identify 26 as Alliance. The pinned QuestieDB swaps 26 and 27.
  q(26, "A Lesson to Learn", 16, 16, nil, nil, druid)
  q(29, "Trial of the Lake", 16, 16, 26, nil, druid)
  q(272, "Trial of the Sea Lion", 16, 16, 29, nil, druid)
  q(5061, "Aquatic Form", 16, 16, 272, nil, druid)
  side({ id = "druid-aquatic-form", title = "Druid: Aquatic Form", zone = maps.darnassus,
    levels = { 16, 18 }, class = druid, start = allianceDruids,
    sources = { "QuestieDB Forever 0f7d8ad", "https://efficient.games/wowf/quests/id5061",
      "https://bindonforever.com/quest/26" },
    steps = {
      accept(26, mathrengyl,
        "Accept upstairs in the Cenarion Enclave. From Stormwind, take the harbor boat to Auberdine, then the Rut'theran boat and the pink portal."),
      finish(26, dendrite,
        "Cast Teleport: Moonglade and find Dendrite upstairs. If you lack the spell, check the Druid trainer. Sheldras Moontree in Stormwind can help Skyborne."),
      accept(29, dendrite, "Accept the lake trial when ready to dive. The bauble expires shortly after you loot it."),
      objectiveAt(29, at(nil, 54.15, 50.2, moonglade),
        "Dive for a Bauble Container on the lake bed. If this spot is empty, search nearby from the surface. Loot the Shrine Bauble and press Next.",
        "Loot a Shrine Bauble"),
      withItem(15877, objectiveAt(29, shrine,
        "Go straight to the Shrine of Remulos on the west shore and use the bauble by the shrine tree.",
        "Use the Shrine Bauble")),
      finish(29, tajarri),
      accept(272, tajarri),
      action("goto", silva, "Go to Silva southwest of Nighthaven and take her Druid flight to Rut'theran."),
      objectiveAt(272, at(nil, 48.87, 11.32, maps.darkshore),
        "Take the boat to Auberdine, then head north along the coast. Dive to the Strange Lockbox between rock pillars. Loot Aquatic Agility, surface and press Next.",
        "Half Pendant of Aquatic Agility"),
      objectiveAt(272, at(nil, 17.94, 33.18, maps.westfall),
        "Take the Auberdine boat to Stormwind. In Westfall, swim west-northwest from Gold Coast Quarry. Loot Aquatic Endurance by the bubbling fissure, surface and press Next.",
        "Half Pendant of Aquatic Endurance"),
      withItem(15883, objectiveAt(272, shrine,
        "With both halves, teleport to Moonglade. Use the Half Pendant of Aquatic Agility at the Shrine of Remulos to join them.",
        "Pendant of the Sea Lion")),
      finish(272, dendrite, "Take the joined pendant to Dendrite in Nighthaven."),
      accept(5061, dendrite),
      action("goto", silva, "Go back to Silva for the Druid flight to Rut'theran Village."),
      finish(5061, mathrengyl, "Go through the Rut'theran portal to Darnassus. Show Mathrengyl the pendant to learn Aquatic Form."),
    },
  })

  local dwarf, shaman = "DWARF", "SHAMAN"
  local teo = at("Teo Hammerstorm", 28.79, 66.18, maps.dunMorogh)
  local ingrid = at("Ingrid Dunwald", 47.54, 51.96, maps.dunMorogh)
  local eldrun = at("Eldrun Stormbreaker", 47.10, 13.79, maps.ironforge)
  local earth = at("Minor Manifestation of Earth", 24.9, 61.9, maps.dunMorogh)
  local bruegs = at("Bruegs Kindleborn", 87.94, 44.80, maps.dunMorogh)
  local braldir = at("Braldir Ashmantle", 32.17, 65.97, maps.lochModan)
  local fire = at("Brazier of the Dormant Flame", 31.8, 64.5, maps.lochModan)
  local norric = at("Norric Lochthane", 41.76, 19.05, maps.lochModan)
  local hervdana = at("Hervdana Saegrund", 65.76, 76.52, maps.wetlands)
  local forgotten = at("Forgotten Shrine", 45.6, 59.88, maps.westfall)
  local water = at("Minor Manifestation of Water", 47.5, 60.4, maps.westfall)
  local totemGuide = "https://www.warcrafttavern.com/forever/guides/dwarf-shaman-totem-quests/"
  local function call(id, element, level, min, prior)
    q(id, "Call of " .. element, level, min, prior, true, shaman)
  end

  call(94373, "Earth", 4, 4)
  call(94374, "Earth", 4, 4, 94373)
  call(94375, "Earth", 4, 4, 94374)
  side({ id = "shaman-earth-totem", title = "Shaman: Earth Totem", zone = maps.dunMorogh,
    levels = { 4, 6 }, class = shaman, start = dwarf,
    sources = { "QuestieDB Forever 0f7d8ad", totemGuide, "https://bindonforever.com/quest/94374" },
    steps = {
      accept(94373, teo, "Find Teo inside Anvilmar. If Ingrid or Eldrun sent you back to Teo, hand in that introduction first."),
      objectiveAt(94373, at(nil, 27.4, 80.8, maps.dunMorogh),
        "Kill Frostmane Troll Whelps and Frostmane Novices in southern Coldridge Valley. Loot two Iceclaw Bear Pendants.", "Iceclaw Bear Pendant (2)"),
      finish(94373, teo),
      accept(94374, teo),
      action("goto", at(nil, 25.8, 69.3, maps.dunMorogh), "Find the uphill trail southwest of Anvilmar."),
      withItem(6635, finish(94374, earth,
        "Follow the hill trail to the Spirit Stone. Drink the Earth Sapta there, then speak with the Minor Manifestation of Earth.")),
      accept(94375, earth),
      finish(94375, teo, "Bring the Rough Quartz back to Teo for your Earth Totem."),
    },
  })

  call(94449, "Fire", 10, 10)
  call(94465, "Fire", 11, 10, 94449)
  call(94466, "Fire", 14, 10, 94465)
  call(94467, "Fire", 14, 10, 94466)
  call(94468, "Fire", 14, 10, 94467)
  side({ id = "shaman-fire-totem", title = "Shaman: Fire Totem", zone = maps.dunMorogh,
    levels = { 10, 14 }, class = shaman, start = dwarf,
    sources = { "QuestieDB Forever 0f7d8ad", totemGuide, "https://bindonforever.com/quest/94467" },
    steps = {
      accept(94449, ingrid, "Accept from Ingrid in Kharanos, Teo in Anvilmar or Eldrun in Ironforge. The reagent mobs are level 12-14, so bring help or come back around 14."),
      action("goto", at(nil, 86.7, 47.0, maps.dunMorogh),
        "Take the east road toward the north tunnel to Loch Modan. Find the uphill path behind the farm before the tunnel."),
      finish(94449, bruegs, "Follow the path up to Bruegs in the cave."),
      accept(94465, bruegs),
      finish(94465, braldir, "Cross into Loch Modan. South of Thelsamar, take the stone-marked uphill trail above Stonesplinter Valley to Braldir."),
      accept(94466, braldir),
      objectiveAt(94466, at(nil, 35.6, 20.2, maps.lochModan),
        "Go to Silver Stream Mine in northern Loch Modan. Loot one Fire Tar from a Tunnel Rat Geomancer, then press Next.", "Fire Tar"),
      objectiveAt(94466, at(nil, 34.7, 85.3, maps.lochModan),
        "Head south to Stonesplinter Valley. Loot one Reagent Pouch from a Stonesplinter Seer.", "Reagent Pouch"),
      finish(94466, braldir),
      accept(94467, braldir),
      withItem(6636, objectiveAt(94467, fire,
        "Go uphill to the stone beside the brazier. Drink the Fire Sapta, defeat the Minor Manifestation of Fire and loot its Glowing Ember.", "Glowing Ember")),
      finish(94467, fire, "Place the Glowing Ember in the brazier."),
      accept(94468, fire),
      finish(94468, bruegs, "Return through the north tunnel to Bruegs' cave for your Fire Totem."),
    },
  })

  call(94494, "Water", 20, 20)
  call(94495, "Water", 22, 20, 94494)
  call(94497, "Water", 22, 20, 94495)
  call(94499, "Water", 22, 20, 94497)
  call(94500, "Water", 23, 20, 94499)
  call(94501, "Water", 23, 20, 94500)
  call(94502, "Water", 23, 20, 94501)
  call(94503, "Water", 23, 20, 94502)
  call(94505, "Water", 23, 20, 94503)
  side({ id = "shaman-water-totem", title = "Shaman: Water Totem", zone = maps.ironforge,
    levels = { 20, 23 }, class = shaman, start = dwarf,
    sources = { "QuestieDB Forever 0f7d8ad", totemGuide, "https://forg.gg/en/forever/tips/shaman-totems" },
    steps = {
      accept(94494, eldrun, "Find Eldrun in Ironforge's Mystic Ward."),
      finish(94494, norric, "Find Norric at his hut on the northwest shore of Loch Modan, just south of Stonewrought Dam."),
      accept(94495, norric),
      finish(94495, hervdana, "Take the northern road through Dun Algaz into the Wetlands. At the falls by Thelgen Rock, follow the ramp up to Hervdana's cave."),
      accept(94497, hervdana),
      withItem(265732, objectiveAt(94497, at(nil, 64.8, 74.8, maps.wetlands),
        "Go down the ramp and use the Unfilled Brown Waterskin in the pool at the foot of the falls.", "Full Brown Waterskin")),
      finish(94497, hervdana),
      accept(94499, hervdana),
      withItem(265747, objectiveAt(94499, at(nil, 73.7, 61.6, maps.redridge),
        "Travel to Lakeshire. Follow Lake Everstill's south shore east to Stonewatch Falls. Use the Unfilled Red Waterskin in the water near the Nightcrawler Murlocs.",
        "Full Red Waterskin")),
      finish(94499, hervdana, "Take the filled red skin back to Hervdana in the Wetlands."),
      accept(94500, hervdana),
      withItem(265772, objectiveAt(94500, at(nil, 37.0, 51.6, ashenvale),
        "Take the Menethil boat to Auberdine via Southshore. From Auberdine follow the road south into Ashenvale to Astranaar. Use the Unfilled Blue Waterskin in the lake by town.",
        "Full Blue Waterskin")),
      finish(94500, hervdana, "Return to Auberdine for the Menethil boat, then take the blue skin back to Hervdana."),
      accept(94501, hervdana),
      finish(94501, norric, "Carry the Vial of Purest Water back to Norric in Loch Modan."),
      accept(94502, norric),
      withItem(6637, objectiveAt(94502, forgotten,
        "Go to Westfall. At Stendel's Pond near Moonbrook, drink the Water Sapta. Kill the corrupt water manifestation and loot its bracers.",
        "Corrupt Manifestation's Bracers")),
      finish(94502, forgotten, "Offer the bracers and Remaining Drops of Purest Water at the Forgotten Shrine by the pond."),
      accept(94503, forgotten),
      finish(94503, water, "Speak to the cleansed Minor Manifestation of Water in the pond."),
      accept(94505, water),
      finish(94505, norric, "Take the Shard of Water back to Norric in Loch Modan for your Water Totem."),
    },
  })
end

-- Additional Druid and Shaman unlocks
do
  local at, q, accept, finish, goal = B.at, B.q, B.accept, B.finish, B.objectiveAt
  local m, glade = B.maps, 1450
  local druid, shaman = "DRUID", "SHAMAN"
  local mathrengyl = at("Mathrengyl Bearwalker", 35.37, 8.4, m.darnassus)
  local dendrite = at("Dendrite Starblaze", 56.21, 30.64, glade)
  local alanndarian = at("Alanndarian Nightsong", 37.69, 40.66, m.darkshore)
  local toDarnassus = "Take Silva's flight from Nighthaven to Rut'theran. Use the pink portal to enter Darnassus and go upstairs in the Cenarion Enclave."
  q(6121, "Lessons Anew", 14, 14, nil, nil, druid)
  q(6122, "The Principal Source", 14, 14, 6121, nil, druid)
  q(6123, "Gathering the Cure", 14, 14, 6122, nil, druid)
  q(6124, "Curing the Sick", 14, 14, 6123, nil, druid)
  q(6125, "Power over Poison", 14, 14, 6124, nil, druid)
  side({ id = "druid-cure-poison", title = "Druid: Cure Poison", zone = m.darnassus,
    levels = { 14, 16 }, class = druid, start = { "NIGHTELF", "SKYBORNE" },
    sources = { "https://polestar.guide/guides/class/druid/cure-poison", "https://pd.zroot.it/forever/quests/6121" },
    steps = {
      accept(6121, mathrengyl, "Find Mathrengyl upstairs in the Cenarion Enclave. Bring 5 Earthroot for a later step."),
      finish(6121, dendrite, "Teleport to Moonglade and meet Dendrite upstairs in Nighthaven."),
      accept(6122, dendrite),
      B.withItem(15844, goal(6122, at("Cliffspring Falls", 55, 33.5, m.darkshore),
        "Fly to Darkshore. Climb to the cave above Cliffspring Falls, clear nearby naga, and use the sampler at the cave mouth. Be ready for an ambush.",
        "Filled Cliffspring Falls Sampler")),
      finish(6122, alanndarian, "Bring the sample to Alanndarian at the north end of Auberdine."),
      accept(6123, alanndarian),
      goal(6123, nil, "Gather Lunar Fungus from fungal blooms in moonkin caves east of Auberdine. Gather or buy Earthroot if you did not bring it.",
        "12 Lunar Fungus", "5 Earthroot"),
      finish(6123, alanndarian),
      accept(6124, alanndarian),
      B.withItem(15826, goal(6124, nil, "Look for living Sickly Deer along the road outside Auberdine. Use a dose of the salve on each deer to cure it.",
        "10 Sickly Deer cured")),
      finish(6124, dendrite, "Teleport to Moonglade and report to Dendrite."),
      accept(6125, dendrite),
      finish(6125, mathrengyl, toDarnassus .. " Turn in to learn Cure Poison."),
    },
  })

  local function catForm(race, spirit, intro, trial, blessing)
    local windborne = race == "SKYBORNE"
    local title = windborne and "The Great Windborne Cat Spirit" or "The Great Cat Spirit"
    q(98393, "The Great Cat Spirit", 20, 20, nil, true, druid)
    q(intro, title, 20, 20, 98393, true, druid)
    q(trial, title, 20, 20, intro, true, druid)
    q(blessing, windborne and "Blessings of the Great Windborne Cat Spirit" or "Blessings of the Great Cat Spirit",
      20, 20, trial, true, druid)
    q(98397, "To Darnassus", 20, 20, blessing, true, druid)
    side({ id = windborne and "druid-cat-skyborne" or "druid-cat-night-elf",
      title = "Druid: Cat Form", zone = m.darnassus, levels = { 20, 22 }, class = druid, start = race,
      sources = { "https://polestar.guide/guides/class/druid/cat-form", "https://warcraft.wiki.gg/wiki/To_Darnassus_(Forever)" },
      steps = {
        accept(98393, mathrengyl, "Find Mathrengyl upstairs in the Cenarion Enclave."),
        finish(98393, dendrite, "Teleport to Moonglade and meet Dendrite upstairs in Nighthaven."),
        accept(intro, dendrite),
        finish(intro, spirit, "Follow the path around the lake to the spirit on the southern hills."),
        accept(trial, spirit),
        goal(trial, at(nil, 72.4, 66.0, glade),
          "Enter the Stormrage Barrow Dens from the east side of the lake. Leave shapeshift and use the statue near the entrance to hide from the spirits. Search the alcoves past the bridge for the three relics. Return to the entrance statue if your stealth runs out.",
          "Relic of the Fang", "Relic of the Claw", "Relic of the Silent Shadow"),
        finish(trial, spirit, "Take all three relics back to the spirit in southern Moonglade."),
        accept(blessing, spirit),
        finish(blessing, dendrite, "Teleport back to Nighthaven and hand in to Dendrite upstairs."),
        accept(98397, dendrite),
        finish(98397, mathrengyl, toDarnassus .. " Turn in to learn Cat Form."),
      },
    })
  end
  catForm("NIGHTELF", at("Great Cat Spirit", 58.39, 73.52, glade), 98394, 98396, 98731)
  catForm("SKYBORNE", at("Avatar of Saeyleenan", 43.92, 73.44, glade), 98341, 98404, 98738)

  q(94789, "Call of Air", 30, 30, nil, true, shaman)
  side({ id = "shaman-air-totem", title = "Shaman: Air Totem", zone = m.ironforge,
    levels = { 30, 30 }, class = shaman, start = "DWARF",
    sources = { "https://db.icy-veins.com/wow-forever/quests/94789",
      "https://urgametips.com/wow-forever/quest-guides/call-air-alliance-veyric-thunderhame-arathi-totem/" },
    steps = {
      accept(94789, at("Eldrun Stormbreaker", 47.10, 13.79, m.ironforge), "Find Eldrun in Ironforge's Mystic Ward."),
      finish(94789, at("Veyric Thunderhame", 59.84, 27.57, 1417),
        "Take the northern road through the Wetlands and cross the Thandol Span. Follow the road into Arathi Highlands, then head into the northern hills to meet Veyric for your Air Totem."),
    },
  })
end
