-- Horde dungeon detours, levels 44-60. Source notes: tools/audits/2026-11-12-horde-dungeons-45-60.md.
-- Each guide is self-contained (its own pickups and lead-in chains); outdoor pickups are also
-- tagged on the leveling route (B.horde.dungeon) where the route passes their givers. Quests a
-- guide can't start on its own (a long outdoor chain from another guide) are `carried`: their
-- objective and hand-in show only while the quest is in your log.
local B = LevelingCodexQuests.build
local H = B.horde
local route = LevelingCodexQuests.HORDE
local M, on = B.maps, B.on
local at, accept, finish, action, taxi = B.at, B.accept, B.finish, B.action, B.taxi
local objective, part, withItem, uncertain, need = B.objectiveAt, B.objectivePart, B.withItem, B.note, H.need

local function add(section, prepare, inside, after)
  section.side, section.category, section.verified = true, "dungeon", false
  section.steps = {}
  for _, group in ipairs({ { "prepare", prepare }, { "inside", inside }, { "after", after } }) do
    for _, step in ipairs(group[2] or {}) do
      -- A guide owns its steps: only a carried quest's steps stay optional.
      step.phase, step.dungeon = group[1], nil
      step.optional, step.carried = step.carried or nil, nil
      section.steps[#section.steps + 1] = step
    end
  end
  route.sections[#route.sections + 1] = section
  return section
end

local function special(section)
  section.side, section.category, section.verified = true, "special", false
  route.sections[#route.sections + 1] = section
  return section
end

-- Work on a quest picked up in another guide: shown only while it is in your log.
local function carried(step)
  step.carried = true
  return step
end

local function tip(name, text)
  return action("note", nil, text, { name = name })
end

local function enter(name, place, text, path)
  return action("dungeon", place, text, { name = name, path = path })
end

local function collect(item, place, text)
  return action("collect", place, text, { item = item })
end

local function fromItem(id, item, name, level, min, prerequisite)
  need(id, name, level, min, prerequisite)
  B.quest[id].startItem = item
end

-- The Alliance guide's boss list (same instance, same bosses) with the client's encounter IDs, so
-- ENCOUNTER_END marks each boss row done even where the row's name differs from the game's.
-- `more` = { { position, boss }, ... } rows for encounters the Alliance list leaves out.
local function bosses(id, ids, more)
  local list = {}
  for _, boss in ipairs(H.bosses(id)) do
    list[#list + 1] = { name = boss.name, tip = boss.tip, npc = boss.npc, encounter = ids[boss.name] }
  end
  for _, extra in ipairs(more or {}) do table.insert(list, extra[1], extra[2]) end
  return list
end

-- Shared places (QuestieDB Forever spawns; flight masters at the client's taxi nodes).
local og, uc, bad, bs, ds = on.orgrimmar, on.undercity, on.badlands, on.steppes, on.desolace
local thrall = og("Thrall", 31.73, 37.82)
local ogFlights = og("Doras", 45.1, 63.9)
local ucFlights = uc("Michael Garrett", 63.2, 48.6)
local durotarTower = at("Zeppelin tower", 50.8, 13.8, M.durotar)
local tirisfalTower = at("Zeppelin tower", 60.7, 58.8, M.tirisfal)
local gromgolZeppelin = at("Snurk Bucksquick", 50.7, 12.9, M.durotar)
local kargathFlights = bad("Gorrik", 4.0, 44.8)
local flameCrestFlights = bs("Vahgruk", 65.7, 24.2)
local stonardFlights = on.swamp("Breyk", 46.1, 54.8)
local revantuskFlights = on.hinterlands("Gorkas", 81.7, 81.8)
local hammerfallFlights = on.arathi("Urda", 73.0, 32.7)
local lightsHopeFlights = on.epl("Georgia", 70.5, 47.5)
local mojacheFlights = on.feralas("Shyn", 75.5, 44.4)
local gadgetzanFlights = on.tanaris("Bulkrek Ragefist", 51.6, 25.4)
local marshalFlights = on.ungoro("Gryfe", 45.2, 5.8)
local ratchetFlights = on.barrens("Bragok", 63.1, 37.2)
local moongladeFlights = on.moonglade("Faustron", 32.1, 66.6)
local everlookFlights = on.winterspring("Yugrek", 60.5, 36.3)
local shadowpreyFlights = ds("Thalon", 21.6, 74.1)
local cenarionFlights = on.silithus("Runk Windtamer", 48.7, 36.7)
local brackenwallFlights = on.dustwallow("Shardi", 35.6, 31.9)
-- Kargath and Flame Crest, the Horde's Blackrock Mountain camps.
local zinge = uc("Apothecary Zinge", 50.14, 67.97)
local goretooth = bad("Warlord Goretooth", 5.81, 47.52)
local lexlort = bad("Lexlort", 5.88, 47.63)
local galamav = bad("Galamav the Marksman", 5.96, 47.73)
local vivian = bad("Shadowmage Vivian Lagrave", 2.9, 47.76)
local thunderheart = bad("Thunderheart", 3.33, 48.26)
local theodora = bad("Hierophant Theodora Mulvadania", 3.02, 47.81)
local kibler = bs("Kibler", 65.89, 21.92)
local ragged = bs("Ragged John", 65.01, 23.76)
local maxwort = bs("Maxwort Uberglint", 65.15, 23.91)
local tinkee = bs("Tinkee Steamboil", 65.24, 24.0)
-- Blackrock Mountain's Searing Gorge gate (34.8, 85.3 on the Searing Gorge map), placed on the
-- Burning Steppes map through the client's world coordinates: the Horde comes from Flame Crest.
local brm = bs("Blackrock Mountain", 28.4, 17.3)
local dmDoor = on.feralas("Dire Maul", 59.0, 44.8)
-- The Light's Hope Chapel crowd and the Caer Darrow ghosts.
local betina = on.epl("Betina Bigglezink", 71.66, 49.94)
local leonid = on.epl("Leonid Barthalomew the Revered", 71.89, 48.29)
local eva = on.wpl("Eva Sarkhoff", 70.22, 73.71)
local marduke = on.wpl("Magistrate Marduke", 70.57, 74.11)
local alexi = on.tirisfal("Alexi Barov", 83.06, 71.6)
local bulwark = on.tirisfal("The Bulwark", 83.1, 68.9)

-- The Plaguelands have no Horde flight point west of Light's Hope: ride out past the Bulwark.
H.road(M.undercity, M.wpl, bulwark, "Leave the Undercity and ride east through Tirisfal past the Bulwark")
H.road(M.tirisfal, M.wpl, bulwark, "Ride east past the Bulwark into the Western Plaguelands")

-- Maraudon. Orgrimmar's Uthel'nay, Shadowprey Village, the Pariah and Willow; the Seed of Life goes to Moonglade.
do
  local name = "Maraudon"
  local uthelnay = og("Uthel'nay", 39.16, 86.27)
  local vark = ds("Vark Battlescar", 23.22, 70.33)
  local selendra = ds("Selendra", 26.87, 77.67)
  local pariah = ds("Centaur Pariah", 50.42, 86.65)
  local willow = ds("Willow", 62.2, 39.63)
  local cavindra = ds("Cavindra", 32.1, 63.96)
  local mouth = ds("Maraudon", 29.1, 62.6)
  local remulos = on.moonglade("Keeper Remulos", 36.18, 41.79)
  need(7068, "Shadowshard Fragments", 42, 38)
  need(7029, "Vyletongue Corruption", 47, 41)
  need(7064, "Corruption of Earth and Seed", 51, 45)
  add({ id = "dungeon-maraudon", title = name, zone = M.desolace, levels = { 46, 52 }, instanceID = 349, instance = name,
    bosses = bosses("dungeon-maraudon", { Noxxion = 422, Razorlash = 423, ["Lord Vyletongue"] = 424,
      ["Celebras the Cursed"] = 425, Landslide = 426, ["Tinkerer Gizlock"] = 427, Rotgrip = 428,
      ["Princess Theradras"] = 429 }),
    sources = { "https://www.wowhead.com/forever/zone=2100", "https://questing.wiki/wow-forever/dungeons/maraudon/quests/" } }, {
    accept(7068, uthelnay, "In Orgrimmar, find Uthel'nay with the mage trainers in the Valley of Spirits. He wants shadowshard fragments from Maraudon."),
    taxi("fly", shadowpreyFlights, "Shadowprey Village, Desolace", "Fly to Shadowprey Village on the Desolace coast."),
    accept(7029, vark, "Vark Battlescar stands in Shadowprey Village. His vial is for the corrupted vines inside."),
    accept(7064, selendra, "Selendra waits just south of the village. She wants Princess Theradras dead."),
    action("goto", pariah, "Ride east along the southern road toward the Kolkar camps."),
    accept(7067, pariah, "Missable: only the Centaur Pariah starts the amulet quest. He wanders south of the Kolkar camps. Read his instructions."),
    action("goto", willow, "Ride north through the middle of Desolace to Willow's camp."),
    accept(7028, willow, "Willow wants Theradric crystal carvings from the creatures of Maraudon."),
    action("goto", mouth, "Ride south-west to the Valley of Spears. Maraudon's cave opens at the foot of the big rock."),
    collect(17757, ds("The Nameless Prophet", 28.1, 63.0),
      "Just inside the cave, kill The Nameless Prophet and loot the Amulet of Spirits."),
    uncertain(tip("Khan spirits", "Three of the five Kolkar khans lie in the outer caves. Use the Amulet of Spirits on each to call his spirit, kill it and keep the gem. The last two are inside the instance."),
      "Check which khans are outside the portals in the Forever layout."),
    objective(7068, ds("Shadowshard caves", 27.8, 56.0), "Shadowshard Smashers and Rumblers roam the outer caves on the purple side. Collect the fragments.",
      "10 Shadowshard Fragments"),
    accept(7044, cavindra, "Cavindra waits where the orange and purple paths split."),
    uncertain(withItem(17693, part(7029, 2, nil, "Follow the orange path and fill the Coated Cerulean Vial at the orange crystal pool before the portal.",
      "Filled Cerulean Vial")), "Check that the pool is outside the orange portal."),
    enter(name, cavindra, "Meet your group by Cavindra. The orange portal leads to Noxxion and the vines, the purple one to Lord Vyletongue. Both reach the inner falls.",
      { { 29.1, 62.6 } }),
  }, {
    tip("Two wings", "The orange wing holds Noxxion and the Celebrian Rod; the purple wing holds Lord Vyletongue and the Celebrian Diamond. Clear one, then the other, and meet at Celebras."),
    withItem(17696, objective(7029, nil, "On the orange side, use the Filled Cerulean Vial on Vylestem Vines and kill the Noxxious Scion that comes out of each.",
      "8 Vylestem Vines healed")),
    objective(7067, nil, "Find the last two khans, Veng and Maraudos, inside. With all five gems, combine them into the Amulet of Union.", "Amulet of Union"),
    objective(7044, nil, "Take the Celebrian Rod from Noxxion and the Celebrian Diamond from Lord Vyletongue.", "Celebrian Rod", "Celebrian Diamond"),
    finish(7044, nil, "Kill Celebras the Cursed in his grove, then talk to Celebras the Redeemed."),
    accept(7046, nil, "Let Celebras make the scepter."),
    objective(7046, nil, "Stand by while Celebras works on the scepter."),
    finish(7046, nil, "Talk to Celebras again and take the Scepter of Celebras."),
    objective(7028, nil, "Carvings drop from most creatures in the inner halls. Finish the count as you go.", "15 Theradric Crystal Carvings"),
    objective(7064, nil, "Head down past Landslide and the falls to Princess Theradras and kill her.", "Princess Theradras"),
    accept(7066, nil, "Missable: Zaetar's Spirit appears after Theradras dies. Take the Seed of Life before you leave."),
  }, {
    finish(7029, vark, "Leave Maraudon and ride south-west to Shadowprey Village."),
    finish(7064, selendra),
    action("goto", pariah, "Ride east to the Centaur Pariah."),
    finish(7067, pariah),
    action("goto", willow, "Ride north to Willow's camp."),
    finish(7028, willow),
    taxi("fly", ogFlights, "Orgrimmar, Durotar", "Ride back to Shadowprey Village and fly to Orgrimmar."),
    finish(7068, uthelnay),
    taxi("fly", moongladeFlights, "Moonglade", "Fly to Moonglade."),
    finish(7066, remulos, "Keeper Remulos stands at the shrine in Nighthaven."),
  })
end

-- The Temple of Atal'Hakkar. Marvon's Stone Circle, Larion's zapper, Fel'zerul's Stonard chain and the Atal'ai Exile.
do
  local name = "Sunken Temple"
  local ba, tn = on.barrens, on.tanaris
  local uzeri = on.feralas("Witch Doctor Uzer'i", 74.42, 43.36)
  local marvon = tn("Marvon Rivetseeker", 52.71, 45.92)
  local larion = on.ungoro("Larion", 45.54, 8.72)
  local liv = ba("Liv Rizzlefix", 62.45, 38.73)
  local felzerul = on.swamp("Fel'zerul", 47.93, 54.78)
  local exile = on.hinterlands("Atal'ai Exile", 33.75, 75.21)
  local yehkinya = tn("Yeh'kinya", 66.99, 22.36)
  need(3380, "The Sunken Temple", 51, 46)
  B.q(3444, "The Stone Circle", 51, 46, 3380)
  need(4145, "Larion and Muigin", 52, 47)
  need(4147, "Marvon's Workshop", 52, 47, 4145)
  need(4146, "Zapper Fuel", 52, 47, 4147)
  need(1424, "Pool of Tears", 43, 38)
  need(1429, "The Atal'ai Exile", 44, 38, 1424)
  need(1444, "Return to Fel'Zerul", 44, 38, 1429)
  need(1445, "The Temple of Atal'Hakkar", 50, 38, 1444)
  need(3528, "The God Hakkar", 53, 40, 4787)
  add({ id = "dungeon-sunken-temple", title = name, zone = M.swamp, levels = { 50, 56 }, instanceID = 109,
    instance = "Sunken Temple", links = { "dungeon-zul-farrak" },
    bosses = bosses("dungeon-sunken-temple", { ["Atal'alarion (statue event)"] = 3582,
      ["Jammal'an the Prophet and Ogom the Wretched"] = 3589, ["Dreamscythe and Weaver"] = 3587,
      ["Morphaz and Hazzas"] = 3585, ["Avatar of Hakkar (optional, needs Hakkari Blood)"] = 3583,
      ["Shade of Eranikus"] = 3584 }),
    sources = { "https://www.wowhead.com/forever/zone=1477", "https://questing.wiki/wow-forever/dungeons/sunken-temple/quests/" } }, {
    accept(3380, uzeri, "Start at Camp Mojache in Feralas. Witch Doctor Uzer'i sends you to Marvon Rivetseeker in Tanaris."),
    taxi("fly", gadgetzanFlights, "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
    finish(3380, marvon, "Ride south out of Gadgetzan to Marvon Rivetseeker's camp."),
    accept(3444, marvon, "Marvon left his Stone Circle in his old workshop in Ratchet."),
    taxi("fly", marshalFlights, "Marshal's Refuge, Un'Goro Crater", "Fly to Marshal's Refuge in Un'Goro Crater."),
    accept(4145, larion, "Larion at Marshal's Refuge wants the bloodpetal plants thinned out."),
    part(4145, 3, on.ungoro(nil, 56.3, 16.5), "Kill Bloodpetal Flayers in the jungle south-east of the refuge.", "5 Bloodpetal Flayers"),
    part(4145, 1, on.ungoro(nil, 65.7, 32.8), "Go south-east into the eastern jungle for Bloodpetal Lashers.", "5 Bloodpetal Lashers"),
    part(4145, 4, on.ungoro(nil, 65.6, 34.7), "Bloodpetal Threshers grow among the lashers.", "5 Bloodpetal Threshers"),
    part(4145, 2, on.ungoro(nil, 35.9, 33.8), "Cross to the western jungle for Bloodpetal Trappers.", "5 Bloodpetal Trappers"),
    finish(4145, larion, "Return to Larion at Marshal's Refuge."),
    accept(4147, larion, "Larion sends you to Marvon's workshop in Ratchet."),
    taxi("fly", ratchetFlights, "Ratchet, The Barrens", "Fly to Ratchet."),
    objective(3444, ba("Marvon's Chest", 62.5, 38.5), "Open Marvon's chest in his Ratchet workshop and take the Stone Circle.", "Stone Circle"),
    finish(4147, liv, "Liv Rizzlefix runs the workshop now."),
    accept(4146, liv, "Liv gives you an unloaded zapper. It needs Atal'ai Haze from the Sunken Temple."),
    taxi("fly", gadgetzanFlights, "Gadgetzan, Tanaris", "Fly back to Gadgetzan and ride south to Marvon."),
    finish(3444, marvon),
    accept(3446, marvon, "Marvon wants you to find the Altar of Hakkar."),
    accept(3447, marvon, "He also wants the secret of the statue circle."),
    taxi("fly", ogFlights, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
    action("boat", gromgolZeppelin, "Take the zeppelin to Grom'gol from the tower north of Orgrimmar."),
    taxi("fly", stonardFlights, "Stonard, Swamp of Sorrows", "Fly from Grom'gol to Stonard."),
    accept(1424, felzerul, "Fel'zerul in Stonard's great hall wants Atal'ai Artifacts from the Pool of Tears."),
    objective(1424, on.swamp("Pool of Tears", 65.9, 55.6), "Ride east to the Pool of Tears. Pick up artifacts from the ground around the broken walls; mind the trolls and crocolisks.",
      "10 Atal'ai Artifacts"),
    finish(1424, felzerul, "Ride back to Stonard."),
    accept(1429, felzerul, "Fel'zerul wants the artifacts shown to the Atal'ai Exile in the Hinterlands."),
    taxi("fly", revantuskFlights, "Revantusk Village, The Hinterlands", "Fly to Revantusk Village."),
    action("goto", exile, "Ride west across the Hinterlands to the troll ruins in the south. The Atal'ai Exile hides there."),
    finish(1429, exile),
    accept(1444, exile, "The Exile sends word back to Fel'zerul."),
    accept(1446, exile, "He also wants the head of Jammal'an the Prophet."),
    taxi("fly", stonardFlights, "Stonard, Swamp of Sorrows", "Ride back to Revantusk Village and fly to Stonard."),
    finish(1444, felzerul),
    accept(1445, felzerul, "Fel'zerul wants 20 Fetishes of Hakkar from the temple's trolls."),
    enter(name, on.swamp("Temple of Atal'Hakkar", 69.7, 53.5),
      "Ride east to the Pool of Tears and swim to the sunken temple in the middle. Take the stairs down inside the ring of broken walls to the portal."),
  }, {
    uncertain(finish(3447, nil, "On the lower ring, use the six statues around the circle in the right order. Kill Atal'alarion when he rises, then touch the Idol of Hakkar."),
      "Statue order and where the Idol appears: check in game."),
    objective(1445, nil, "Atal'ai trolls throughout the temple drop the fetishes. Loot every troll.", "20 Fetishes of Hakkar"),
    objective(4146, nil, "Deep Lurkers, Murk Worms and oozes in the flooded halls drop the haze.", "5 Atal'ai Haze"),
    finish(3446, nil, "Find the Altar of Hakkar in the central chamber below the balconies."),
    objective(1446, nil, "Kill the six troll guardians on the balconies to open the way down. Then kill Jammal'an the Prophet and take his head.",
      "Head of Jammal'an"),
    uncertain(carried(objective(3528, nil, "If you carry The God Hakkar: at the central altar use the Egg of Hakkar, put out the four flames with Hakkari Blood from the Bloodkeepers, and kill the Avatar of Hakkar.",
      "Filled Egg of Hakkar")), "Event order: check in game."),
    withItem(10454, accept(3373, nil, "Kill the Shade of Eranikus in the dragons' lair and use the Essence of Eranikus he drops.")),
    finish(3373, nil, "Place the essence in the Essence Font in the lair."),
  }, {
    finish(1445, felzerul, "Leave the temple and ride west to Stonard."),
    taxi("fly", revantuskFlights, "Revantusk Village, The Hinterlands", "Fly to Revantusk Village."),
    action("goto", exile, "Ride west to the Atal'ai Exile."),
    finish(1446, exile),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Ride back to Revantusk Village and fly to the Undercity."),
    action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar from the tower north-west of the Undercity gate."),
    taxi("fly", marshalFlights, "Marshal's Refuge, Un'Goro Crater", "Fly to Marshal's Refuge."),
    finish(4146, larion),
    carried(finish(3528, yehkinya, "If you carry The God Hakkar, fly to Gadgetzan and ride east to Yeh'kinya at Steamwheedle Port.")),
  })
end

-- Blackrock Depths. Kargath's quests, Flame Crest, Franclorn's hammer and Thrall's Royal Rescue.
do
  local name = "Blackrock Depths"
  local wanted = bad("WANTED", 3.74, 47.43)
  local killOnSight = bad("KILL ON SIGHT", 3.94, 46.73)
  local lotwil = bad("Lotwil Veriatus", 25.95, 44.87)
  local cyrus = bs("Cyrus Therepentous", 95.09, 31.56)
  need(4133, "Vivian Lagrave", 55, 50)
  need(4134, "Lost Thunderbrew Recipe", 55, 50, 4133)
  need(7201, "The Last Element", 54, 48)
  need(3906, "Disharmony of Flame", 52, 48)
  need(3907, "Disharmony of Fire", 56, 48, 3906)
  need(4081, "KILL ON SIGHT: Dark Iron Dwarves", 52, 48)
  need(4082, "KILL ON SIGHT: High Ranking Dark Iron Officials", 54, 50, 4081)
  need(4061, "The Rise of the Machines", 54, 52)
  need(4062, "The Rise of the Machines", 54, 52, 4061)
  need(4063, "The Rise of the Machines", 58, 52, 4062)
  need(3981, "Commander Gor'shak", 52, 48, 3906)
  need(3982, "What Is Going On?", 54, 48, 3981)
  need(4001, "What Is Going On?", 54, 48, 3982)
  need(4002, "The Eastern Kingdom", 54, 48, 4001)
  need(4003, "The Royal Rescue", 59, 48, 4002)
  need(4004, "The Princess Saved?", 60, 48, 4003)
  need(4024, "A Taste of Flame", 58, 52, 4022)
  add({ id = "dungeon-blackrock-depths", title = name, zone = M.searing, levels = { 52, 60 }, instanceID = 230, instance = name,
    links = { "dungeon-lower-blackrock-spire", "shadowforge-key-horde", "molten-core-attunement-horde" },
    bosses = bosses("dungeon-blackrock-depths", { ["Lord Roccor"] = 228, ["High Interrogator Gerstahn"] = 227,
      ["Ring of Law"] = 230, ["Pyromancer Loregrain"] = 231, ["Lord Incendius"] = 232, ["Fineous Darkvire"] = 234,
      ["Bael'Gar"] = 235, ["General Angerforge"] = 236, ["Golem Lord Argelmach"] = 237, ["Hurley Blackbreath"] = 238,
      ["Ribbly Screwspigot"] = 240, ["Ambassador Flamelash"] = 242, ["The Seven"] = 243, Magmus = 244,
      ["Emperor Dagran Thaurissan"] = 2790 }),
    sources = { "https://www.wowhead.com/forever/zone=1584", "https://questing.wiki/wow-forever/dungeons/blackrock-depths/quests/" } }, {
    accept(4133, zinge, "In the Undercity's Apothecarium, Apothecary Zinge sends you to Vivian Lagrave in Kargath."),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath on the western edge of the Badlands."),
    finish(4133, vivian, "Find Shadowmage Vivian Lagrave in Kargath."),
    accept(4134, vivian, "She wants the Lost Thunderbrew Recipe from the Depths' tavern."),
    accept(7201, vivian, "She also wants Essence of the Elements from the golems and fire elementals inside."),
    accept(3906, thunderheart, "Thunderheart wants Overmaster Pyron dead. Pyron guards the quarry in front of the Depths' portal."),
    accept(4081, wanted, "Read the WANTED poster: Warlord Goretooth wants Anvilrage dwarves killed."),
    accept(4061, theodora, "Hierophant Theodora Mulvadania wants Fractured Elemental Shards from the Burning Steppes."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest in the Burning Steppes."),
    accept(4123, maxwort, "Maxwort Uberglint wants the Heart of the Mountain from the Depths' vault."),
    objective(4061, bs(nil, 65.2, 36.6), "Ride south from Flame Crest. War Reavers and obsidian elementals drop the shards.", "10 Fractured Elemental Shards"),
    uncertain(action("goto", brm, "Ride west along the northern Steppes to Blackrock Mountain and go in through its gate."),
      "The arrow points at the mountain's north gate; the Steppes gate is on its south face."),
    uncertain(accept(3801, nil, "Franclorn Forgewright's ghost lies on the stone ledge in the middle of the mountain. Only a spirit sees him: die nearby and talk to him before you resurrect."),
      "Check that Forever keeps the ghost-only rule."),
    finish(3801, nil, "Listen to Franclorn's story."),
    accept(3802, nil, "He asks you to put his hammer Ironfel back on his statue."),
    objective(3906, nil, "Kill Overmaster Pyron, the fire elemental that patrols the quarry in front of the Depths' portal.", "Overmaster Pyron"),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Ride back to Flame Crest and fly to Kargath."),
    finish(3906, thunderheart),
    accept(3907, thunderheart, "Thunderheart now wants Lord Incendius dead, and anything he carries."),
    accept(3981, galamav, "Galamav the Marksman has a drawing of Commander Gor'shak, a prisoner in the Depths."),
    finish(4061, theodora),
    accept(4062, theodora, "Take the shard sample to Lotwil Veriatus."),
    finish(4062, lotwil, "Ride east along the Badlands road to Lotwil's camp."),
    accept(4063, lotwil, "Lotwil wants Golem Lord Argelmach's head and cores from his golems."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Ride back to Kargath and fly to Flame Crest."),
    uncertain(enter(name, brm, "Ride west into Blackrock Mountain. Cross the chains down to the quarry at the bottom; the Depths' portal is there."),
      "Portal spot inside the mountain: check in game."),
  }, {
    tip("Detention Block", "The first halls are the Detention Block. High Interrogator Gerstahn carries the Prison Cell Key that opens the cells."),
    objective(4081, nil, "Kill Anvilrage Guardsmen, Wardens and Footmen in the Detention Block and the halls beyond.",
      "15 Anvilrage Guardsmen", "10 Anvilrage Wardens", "5 Anvilrage Footmen"),
    finish(3981, nil, "Open Commander Gor'shak's cell with the Prison Cell Key and talk to him."),
    accept(3982, nil, "Gor'shak asks you to guard him while he gets ready."),
    objective(3982, nil, "Kill the dwarves that rush the cell."),
    finish(3982, nil, "Talk to Gor'shak once the attackers are dead."),
    accept(4001, nil, "Gor'shak sends you to Kharan Mighthammer in a nearby cell. Hear Kharan's story, then take it to Thrall."),
    objective(3907, nil, "Fight through to the Black Anvil, kill Lord Incendius and take the Tablet of Kurniya.", "Lord Incendius", "Tablet of Kurniya"),
    objective(3802, nil, "Kill Fineous Darkvire for Franclorn's hammer, Ironfel.", "Ironfel"),
    finish(3802, nil, "Carry Ironfel to the Shrine of Thaurissan and place it on Franclorn's statue. Take the Shadowforge Key it gives you."),
    carried(withItem(11231, objective(4024, nil, "If you carry A Taste of Flame: kill Bael'Gar and use the Altered Black Dragonflight Molt on his body.",
      "Encased Fiery Essence"))),
    objective(4063, nil, "Kill Golem Lord Argelmach, and loot Intact Elemental Cores from his Ragereaver Golems and Warbringer Constructs.",
      "Head of Argelmach", "10 Intact Elemental Cores"),
    objective(7201, nil, "Golems and fire elementals drop Essence of the Elements. Finish the count as you go.", "10 Essence of the Elements"),
    uncertain(objective(4123, nil, "After the Ring of Law, find the Vault. Open the safe in its wall for the Heart of the Mountain.", "The Heart of the Mountain"),
      "How the Vault opens in Forever: check in game."),
    objective(4134, nil, "In the Grim Guzzler, break the ale kegs to bring out Hurley Blackbreath. Kill him for the recipe.", "Lost Thunderbrew Recipe"),
    carried(objective(4136, nil, "If you carry Ribbly Screwspigot: kill Ribbly in the Grim Guzzler, away from his friends at the bar, and take his head.",
      "Ribbly's Head")),
  }, {
    finish(4123, maxwort, "Leave the Depths and ride east to Flame Crest."),
    carried(finish(4136, bs("Yuka Screwspigot", 66.06, 21.95), "If you carry Ribbly Screwspigot, give his head to Yuka Screwspigot at Flame Crest.")),
    carried(finish(4024, cyrus, "If you carry A Taste of Flame, ride east to Cyrus Therepentous at the edge of the Steppes.")),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath."),
    finish(4081, goretooth),
    accept(4082, killOnSight, "Read the KILL ON SIGHT poster: Goretooth now wants high-ranking officers."),
    finish(3907, thunderheart),
    finish(4134, vivian),
    finish(7201, vivian),
    finish(4063, lotwil, "Ride east to Lotwil Veriatus."),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Ride back to Kargath and fly to the Undercity."),
    action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
    finish(4001, thrall, "Bring Kharan's story to Thrall in Grommash Hold."),
    accept(4002, thrall, "Thrall has a plan."),
    finish(4002, thrall, "Hear Thrall out."),
    accept(4003, thrall, "Thrall wants Princess Moira freed: kill Emperor Dagran Thaurissan but spare her."),
    action("boat", durotarTower, "Take the zeppelin to the Undercity."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest for your next run."),
    objective(4082, nil, "On your next run, kill Anvilrage Medics, Soldiers and Officers.",
      "10 Anvilrage Medics", "10 Anvilrage Soldiers", "10 Anvilrage Officers"),
    objective(4003, nil, "Fight through to the throne room and kill Emperor Dagran Thaurissan. Do not kill Princess Moira.", "Emperor Dagran Thaurissan"),
    finish(4003, nil, "Talk to Princess Moira after the fight."),
    accept(4004, nil, "Moira asks you to take her answer to Thrall."),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Leave the Depths, ride to Flame Crest and fly to Kargath."),
    finish(4082, goretooth),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
    action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
    finish(4004, thrall),
  })
end

-- Lower Blackrock Spire. Kargath's spy and generals, Flame Crest's pets and poison; Warlord's Command leads to Thrall.
do
  local name = "Lower Blackrock Spire"
  need(4903, "Warlord's Command", 60, 55)
  need(4941, "Eitrigg's Wisdom", 60, 55, 4903)
  need(4981, "Operative Bijou", 59, 55)
  need(4982, "Bijou's Belongings", 59, 55, 4981)
  need(4983, "Bijou's Reconnaissance Report", 59, 55, 4982)
  need(4724, "The Pack Mistress", 59, 55)
  add({ id = "dungeon-lower-blackrock-spire", title = name, zone = M.searing, levels = { 55, 60 }, instanceID = 229,
    instance = "Blackrock Spire", links = { "dungeon-upper-blackrock-spire", "dungeon-blackrock-depths", "ubrs-seal-horde" },
    bosses = bosses("dungeon-lower-blackrock-spire", { ["Highlord Omokk"] = 267, ["Shadow Hunter Vosh'gajin"] = 268,
      ["War Master Voone"] = 269, ["Mother Smolderweb"] = 270, ["Urok Doomhowl (event)"] = 271,
      ["Quartermaster Zigris"] = 272, ["Halycon and Gizrul the Slavener"] = 273, ["Overlord Wyrmthalak"] = 275 }),
    sources = { "https://www.wowhead.com/forever/zone=1583", "https://questing.wiki/wow-forever/dungeons/lower-blackrock-spire/quests/" } }, {
    taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath."),
    uncertain(accept(4903, goretooth, "Warlord Goretooth wants the Spire's three generals dead and their battle plans taken."),
      "Some players report Goretooth must be at the top of Kargath's tower to offer this."),
    accept(4981, lexlort, "Lexlort has lost touch with his spy Bijou in the Spire."),
    accept(4724, galamav, "Galamav the Marksman wants Halycon, the Bloodaxe worg mother, dead."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest."),
    accept(4862, kibler, "Kibler wants spider eggs from the Spire."),
    accept(4729, kibler, "He also gives you a cage for a Bloodaxe worg pup."),
    accept(4866, ragged, "Ragged John wants you poisoned by Mother Smolderweb."),
    uncertain(enter(name, brm, "Ride west into Blackrock Mountain and climb the upper path to the Spire's portal."),
      "Portal spot inside the mountain: check in game."),
  }, {
    accept(4867, nil, "Warosh, a troll near the start, gives you his scroll."),
    finish(4981, nil, "Find Bijou hiding in the Spire's first halls."),
    accept(4982, nil, "Bijou stashed her belongings on the bottom floor of the city."),
    objective(4982, nil, "Find Bijou's Belongings on the bottom floor.", "Bijou's Belongings"),
    finish(4982, nil, "Bring the belongings back to Bijou."),
    accept(4983, nil, "Take Bijou's report back to Lexlort."),
    B.withGuide("ubrs-seal-horde", tip("Seal of Ascension", "Vaelan near the start of the Spire starts the Seal of Ascension for Upper Blackrock Spire. The Seal of Ascension guide has the whole chain.")),
    objective(4862, nil, "Spire spider eggs lie in the webbed halls around Mother Smolderweb.", "15 Spire Spider Eggs"),
    tip("Mother's Milk", "Let Mother Smolderweb's poison land on you, then kill her. Go straight to Ragged John after the run while you are still poisoned."),
    withItem(12262, objective(4729, nil, "Use the cage on a Bloodaxe Worg Pup near Halycon's den.", "Caged Worg Pup")),
    objective(4724, nil, "Kill Halycon in the worg kennels.", "Halycon"),
    objective(4867, nil, "Bring the Roughshod Pike and Omokk's Head to Urok's platform, call Urok Doomhowl and kill him for Warosh's Mojo.", "Warosh's Mojo"),
    finish(4867, nil, "Return the mojo to Warosh."),
    objective(4903, nil, "Kill Highlord Omokk, War Master Voone and Overlord Wyrmthalak, and loot the Important Blackrock Documents.",
      "Overlord Wyrmthalak", "Highlord Omokk", "War Master Voone", "Important Blackrock Documents"),
  }, {
    finish(4866, ragged, "Leave the Spire and ride east to Ragged John at Flame Crest while still poisoned."),
    finish(4862, kibler),
    finish(4729, kibler),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath."),
    finish(4903, goretooth),
    accept(4941, goretooth, "Goretooth sends you to Eitrigg and Thrall in Orgrimmar."),
    finish(4983, lexlort),
    finish(4724, galamav),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
    action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
    finish(4941, thrall, "In Grommash Hold, talk to Eitrigg first, then report to Thrall. For The Horde! continues in the Upper Blackrock Spire guide."),
  })
end

-- Upper Blackrock Spire. For The Horde!, the Darkstone Tablet, Tinkee's eggs, Awbee and Finkle; Blackhand's Command.
do
  local name = "Upper Blackrock Spire"
  local felnok = on.winterspring("Felnok Steelspring", 61.63, 38.61)
  local malyfous = on.winterspring("Malyfous Darkhammer", 60.99, 38.78)
  local haleh = on.winterspring("Haleh", 54.55, 51.2)
  local hydraxis = on.azshara("Duke Hydraxis", 79.28, 73.7)
  need(4974, "For The Horde!", 60, 55, 4941)
  need(4769, "Vivian Lagrave and the Darkstone Tablet", 60, 57)
  need(4768, "The Darkstone Tablet", 60, 57, 4769)
  need(4726, "Broodling Essence", 52, 50)
  need(4808, "Felnok Steelspring", 54, 50, 4726)
  need(4809, "Chillwind Horns", 54, 50, 4808)
  need(4810, "Return to Tinkee", 54, 50, 4809)
  need(4734, "Egg Freezing", 60, 57, 4810)
  need(4735, "Egg Collection", 60, 57, 4734)
  fromItem(7761, 18987, "Blackhand's Command", 60, 55)
  need(6821, "Eye of the Emberseer", 60, 56, { 6804, 6805 })
  add({ id = "dungeon-upper-blackrock-spire", title = name, zone = M.searing, levels = { 58, 60 }, instanceID = 229,
    instance = "Blackrock Spire",
    links = { "dungeon-lower-blackrock-spire", "ubrs-seal-horde", "attunement-onyxia-horde" },
    bosses = bosses("dungeon-upper-blackrock-spire", { ["Pyroguard Emberseer"] = 3062,
      ["Warchief Rend Blackhand and Gyth"] = 3063, ["The Beast"] = 3068, ["General Drakkisath"] = 3069 }),
    sources = { "https://www.wowhead.com/forever/zone=1583", "https://questing.wiki/wow-forever/dungeons/upper-blackrock-spire/quests/" } }, {
    tip("Seal of Ascension", "Upper Blackrock Spire's door opens for a group with one Seal of Ascension holder. The Seal of Ascension guide has the chain."),
    accept(4769, zinge, "In the Undercity's Apothecarium, Apothecary Zinge has another errand for Vivian Lagrave."),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath."),
    finish(4769, vivian),
    accept(4768, vivian, "Vivian wants the Darkstone Tablet from the upper Spire."),
    uncertain(accept(4903, goretooth, "Thrall's quest needs Warlord's Command first. Take it from Warlord Goretooth if you have not done it yet."),
      "Some players report Goretooth must be at the top of Kargath's tower to offer this."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest."),
    accept(4726, tinkee, "Tinkee Steamboil gives you her Draco-Incarcinatrix 900 for broodling essence."),
    withItem(12284, objective(4726, bs("Broodlings", 74.7, 27.6), "Ride east from Flame Crest. Use the Draco-Incarcinatrix on Scalding and Black Broodlings, kill them and pick up the essence.",
      "8 Broodling Essence")),
    finish(4726, tinkee, "Return to Tinkee at Flame Crest."),
    accept(4808, tinkee, "Tinkee sends a letter to Felnok Steelspring in Everlook."),
    action("goto", brm, "Ride west to Blackrock Mountain for a Lower Spire run."),
    B.withGuide("dungeon-lower-blackrock-spire", objective(4903, nil, "In Lower Blackrock Spire, kill Highlord Omokk, War Master Voone and Overlord Wyrmthalak and take the Important Blackrock Documents.",
      "Overlord Wyrmthalak", "Highlord Omokk", "War Master Voone", "Important Blackrock Documents")),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Ride back to Flame Crest and fly to Kargath."),
    finish(4903, goretooth),
    accept(4941, goretooth, "Goretooth sends you to Eitrigg and Thrall in Orgrimmar."),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
    action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
    finish(4941, thrall, "In Grommash Hold, talk to Eitrigg first, then report to Thrall."),
    accept(4974, thrall, "Thrall wants the head of Warchief Rend Blackhand."),
    taxi("fly", everlookFlights, "Everlook, Winterspring", "Fly to Everlook in Winterspring."),
    finish(4808, felnok),
    accept(4809, felnok, "Felnok wants uncracked Chillwind horns."),
    objective(4809, on.winterspring("Chillwind Chimaeras", 57.5, 44.4), "Kill Chillwind Chimaeras south-west of Everlook for their horns.", "8 Uncracked Chillwind Horns"),
    finish(4809, felnok, "Return to Felnok in Everlook."),
    accept(4810, felnok, "Felnok packs a parcel for Tinkee."),
    taxi("fly", ogFlights, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
    action("boat", durotarTower, "Take the zeppelin to the Undercity."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest."),
    finish(4810, tinkee),
    accept(4734, tinkee, "Tinkee wants an egg in the Rookery frozen with her Eggscilloscope Prototype."),
    action("goto", brm, "Ride west into Blackrock Mountain and climb toward the Spire."),
    uncertain(withItem(18987, accept(7761, nil, "Kill the Scarshield Quartermaster on the way up to the Spire and read Blackhand's Command from his body.")),
      "Check where the Quartermaster stands in Forever."),
    uncertain(enter(name, brm, "Climb to the Spire's portal. The Upper Spire door is just inside, past the first ramps."),
      "Portal and door spots inside the mountain: check in game."),
  }, {
    carried(objective(6821, nil, "If you carry Eye of the Emberseer: wake Pyroguard Emberseer at the seven altars, kill him and take his eye.",
      "Eye of the Emberseer")),
    withItem(12286, objective(4734, nil, "In the Rookery, use the Eggscilloscope Prototype on one of the eggs.")),
    uncertain(objective(4768, nil, "Find the Darkstone Tablet in the upper halls on your way through.", "Darkstone Tablet"),
      "Where the tablet lies: check in game."),
    uncertain(accept(5160, nil, "Awbee, a small dragon hiding near the Rookery, asks you to take her scale to Haleh."),
      "Where Awbee waits: check in game."),
    objective(4974, nil, "Start the arena event, hold through the waves, then kill Gyth and Warchief Rend Blackhand. Take Rend's head.", "Head of Rend Blackhand"),
    uncertain(accept(5047, nil, "After The Beast dies, skin its body to free Finkle Einhorn and talk to him."),
      "Check whether Finkle needs a skinner in Forever."),
    finish(7761, nil, "Behind General Drakkisath, touch Drakkisath's Brand for the Mark of Drakkisath."),
  }, {
    finish(4734, tinkee, "Leave the Spire and ride east to Flame Crest."),
    accept(4735, tinkee, "Tinkee wants eight dragon eggs gathered with her Collectronic Module."),
    taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath."),
    finish(4768, vivian),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
    action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
    B.withGuide("attunement-onyxia-horde", finish(4974, thrall, "Bring Rend's head to Thrall. His next quest starts the Horde's Onyxia attunement.")),
    taxi("fly", everlookFlights, "Everlook, Winterspring", "Fly to Everlook."),
    finish(5047, malyfous, "Malyfous Darkhammer works the Everlook forge."),
    finish(5160, haleh, "Haleh waits at the top of Mazthoril, south-west of Everlook. Take the cave path up."),
    carried(finish(6821, hydraxis, "If you carry Eye of the Emberseer, fly to Valormok and ride to Duke Hydraxis on the south-east coast of Azshara.")),
    taxi("fly", ogFlights, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
    action("boat", durotarTower, "Take the zeppelin to the Undercity."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest for your next Upper Spire run."),
    withItem(12287, objective(4735, nil, "On your next Upper Spire run, use the Collectronic Module on the Rookery eggs.", "8 Collected Dragon Eggs")),
    finish(4735, tinkee, "Bring the eggs to Tinkee at Flame Crest."),
  })
end

-- Dire Maul: East. Camp Mojache, the Lariss Pavilion and Rabine Saturna's Felvine.
do
  local name = "Dire Maul: East"
  local gorlach = og("Warcaller Gorlach", 37.56, 75.36)
  local rabine = on.moonglade("Rabine Saturna", 51.69, 45.1)
  local talo = on.feralas("Talo Thornhoof", 76.18, 43.83)
  local azj = on.feralas("Azj'Tordin", 76.91, 37.35)
  need(7492, "Camp Mojache", 57, 54)
  need(7489, "Lethtendris's Web", 57, 54, 7492)
  add({ id = "dungeon-dire-maul-east", title = name, zone = M.feralas, levels = { 55, 60 }, instanceID = 429, instance = "Dire Maul",
    links = { "dungeon-dire-maul-west", "dungeon-dire-maul-north" },
    bosses = bosses("dungeon-dire-maul-east", { Pusillin = 2792, ["Zevrim Thornhoof"] = 343, Hydrospawn = 344,
      Lethtendris = 345, ["Alzzin the Wildshaper"] = 346 }),
    sources = { "https://www.wowhead.com/forever/zone=2557", "https://questing.wiki/wow-forever/dungeons/dire-maul/quests/" } }, {
    accept(7492, gorlach, "In Orgrimmar, Warcaller Gorlach calls for help at Camp Mojache."),
    taxi("fly", moongladeFlights, "Moonglade", "Fly to Moonglade."),
    accept(5527, rabine, "Rabine Saturna in Nighthaven wants a Reliquary of Purity from Silithus."),
    taxi("fly", cenarionFlights, "Cenarion Hold, Silithus", "Fly to Cenarion Hold in Silithus."),
    objective(5527, on.silithus("Dusty Reliquary", 63.2, 55.4), "Ride south-east to the ruins of Southwind Village and open the Dusty Reliquary.", "Reliquary of Purity"),
    taxi("fly", moongladeFlights, "Moonglade", "Fly back to Moonglade."),
    finish(5527, rabine),
    accept(5526, rabine, "Rabine gives you the reliquary to seal a shard of the Felvine."),
    taxi("fly", mojacheFlights, "Camp Mojache, Feralas", "Fly to Camp Mojache."),
    finish(7492, talo),
    accept(7489, talo, "Talo Thornhoof wants the web of Lethtendris, a night elf witch in Dire Maul."),
    accept(7441, azj, "Azj'Tordin, at the Lariss Pavilion north of the camp, wants his book back from the imp Pusillin."),
    action("goto", dmDoor, "Ride west to the ruined city of Dire Maul."),
    uncertain(enter(name, dmDoor, "The East wing's portal is reached from the Broken Commons courtyard."),
      "Wing entrance positions from the classic map; check in game."),
  }, {
    objective(7441, nil, "Talk to Pusillin and chase him through the halls. When he gives up, kill him and take the book. Keep the Crescent Key too.",
      "Azj'Tordin's Book of Incantations"),
    objective(7489, nil, "Kill Lethtendris and her imp, and take her web.", "Lethtendris's Web"),
    withItem(18539, objective(5526, nil, "Kill Alzzin the Wildshaper, then use the Reliquary of Purity on the Felvine for a sealed shard.", "Felvine Shard")),
  }, {
    action("goto", azj, "Leave Dire Maul and ride east to the Lariss Pavilion."),
    finish(7441, azj),
    finish(7489, talo, "Ride south to Camp Mojache."),
    taxi("fly", moongladeFlights, "Moonglade", "Fly to Moonglade."),
    finish(5526, rabine),
  })
end

-- Dire Maul: West. The pylons, Immol'thar and Prince Tortheldrin.
do
  local name = "Dire Maul: West"
  need(7877, "The Treasure of the Shen'dralar", 60, 56, 7461)
  add({ id = "dungeon-dire-maul-west", title = name, zone = M.feralas, levels = { 57, 60 }, instanceID = 429, instance = "Dire Maul",
    links = { "dungeon-dire-maul-east", "dungeon-dire-maul-north" },
    bosses = bosses("dungeon-dire-maul-west", { ["Tendris Warpwood"] = 350, ["Illyanna Ravenoak"] = 347,
      ["Magister Kalendris"] = 348, ["Immol'thar"] = 349, ["Prince Tortheldrin"] = 361 }),
    sources = { "https://www.wowhead.com/forever/zone=2557", "https://questing.wiki/wow-forever/dungeons/dire-maul/quests/" } }, {
    tip("Crescent Key", "The West and North wings open with the Crescent Key. Pusillin drops it in Dire Maul East; one key holder opens the doors for the group."),
    taxi("fly", mojacheFlights, "Camp Mojache, Feralas", "Fly to Camp Mojache in Feralas."),
    action("goto", dmDoor, "Ride west to the ruined city of Dire Maul."),
    uncertain(enter(name, dmDoor, "The West wing's portal is in the Capital Gardens courtyard."),
      "Wing entrance positions from the classic map; check in game."),
  }, {
    accept(7461, nil, "The Shen'dralar Ancient in the gardens wants Immol'thar freed and destroyed, and Prince Tortheldrin with him."),
    tip("Pylons", "Five pylons hold Immol'thar's prison. Kill the guardians at each one; the force field drops when all five are down."),
    objective(7461, nil, "Kill Immol'thar in his prison, then Prince Tortheldrin in the Athenaeum.", "Immol'thar", "Prince Tortheldrin"),
    finish(7461, nil, "Return to the Shen'dralar Ancient."),
    accept(7877, nil, "The Ancient points you to the treasure in the Athenaeum."),
    finish(7877, nil, "Open the Treasure of the Shen'dralar in the Athenaeum and take your reward."),
  }, {
    tip("Gordok wing", "Captain Kromcrush in the North wing wants the Gauntlet of Gordok Might from Tortheldrin's hall. The Dire Maul: North guide has his quest."),
  })
end

-- Dire Maul: North. Elven Legends from Camp Mojache, Knot Thimblejack and the Gordok tribute.
do
  local name = "Dire Maul: North"
  local korolusk = on.feralas("Sage Korolusk", 75.24, 43.76)
  need(7481, "Elven Legends", 60, 54)
  need(5525, "Free Knot!", 60, 57)
  need(5518, "The Gordok Ogre Suit", 60, 56)
  add({ id = "dungeon-dire-maul-north", title = name, zone = M.feralas, levels = { 57, 60 }, instanceID = 429, instance = "Dire Maul",
    links = { "dungeon-dire-maul-west", "dungeon-dire-maul-east" },
    bosses = bosses("dungeon-dire-maul-north", { ["Guard Mol'dar"] = 362, ["Stomper Kreeg"] = 363, ["Guard Fengus"] = 364,
      ["Guard Slip'kik"] = 365, ["Captain Kromcrush"] = 366, ["Cho'Rush the Observer"] = 367, ["King Gordok"] = 368 }),
    sources = { "https://www.wowhead.com/forever/zone=2557", "https://questing.wiki/wow-forever/dungeons/dire-maul/quests/" } }, {
    taxi("fly", mojacheFlights, "Camp Mojache, Feralas", "Fly to Camp Mojache in Feralas."),
    accept(7481, korolusk, "Sage Korolusk wants news of Kariel Winthalus, a scholar lost in Dire Maul."),
    tip("Ogre suit", "Knot Thimblejack inside makes a Gordok Ogre Suit. Bring 4 Bolts of Runecloth, 8 Rugged Leather and 2 Rune Thread if you want it."),
    tip("Crescent Key", "The North wing opens with the Crescent Key from Pusillin in Dire Maul East."),
    action("goto", dmDoor, "Ride west to the ruined city of Dire Maul."),
    uncertain(enter(name, dmDoor, "The Gordok wing's portal is on the north side of the courtyard."),
      "Wing entrance positions from the classic map; check in game."),
  }, {
    tip("Tribute run", "Leave the guards alive and kill only King Gordok for the biggest tribute chest. Every guard you kill makes it smaller."),
    accept(5525, nil, "Knot Thimblejack is chained up in the wing. He asks for the Gordok Shackle Key."),
    objective(5525, nil, "Gordok guards drop the Gordok Shackle Key.", "Gordok Shackle Key"),
    finish(5525, nil, "Free Knot with the key."),
    accept(5518, nil, "Knot will sew a Gordok Ogre Suit if you bring the cloth, leather, thread and Ogre Tannin."),
    objective(5518, nil, "The Ogre Tannin sits in a basket in the wing; one group member can take it.",
      "4 Bolts of Runecloth", "8 Rugged Leather", "2 Rune Thread", "Ogre Tannin"),
    finish(5518, nil, "Bring everything to Knot."),
    uncertain(objective(7481, nil, "Find the remains of Kariel Winthalus in the wing's library and search them.", "Kariel Winthalus"),
      "Some guides place Kariel in the West wing; check where he is."),
    accept(5528, nil, "After King Gordok falls, Stomper Kreeg offers a taste test."),
    finish(5528, nil, "Try the brew and hand the quest back to Kreeg."),
    accept(7703, nil, "Captain Kromcrush wants the Gauntlet of Gordok Might."),
  }, {
    finish(7481, korolusk, "Leave Dire Maul and fly or ride back to Camp Mojache."),
    uncertain(objective(7703, nil, "On a Dire Maul West run, kill Prince Tortheldrin and take the gauntlet from his hall.", "Gauntlet of Gordok Might"),
      "Where the gauntlet lies: check in game."),
    finish(7703, nil, "Bring the gauntlet to Captain Kromcrush in the North wing."),
  })
end

-- Stratholme's gate: the Alliance guide's classic-map spot moved onto Forever's Eastern Plaguelands
-- map (that map's frame differs from classic; see the audit).
local stratGate = on.epl("Stratholme", 26.5, 10.4)

-- Scholomance. Light's Hope, the Bulwark and Caer Darrow; Ras Frostwhisper's chain runs through Stratholme.
do
  local name = "Scholomance"
  local caerDarrow = on.wpl("Caer Darrow", 69.4, 72.8)
  need(5341, "Barov Family Fortune", 60, 52)
  need(4771, "Dawn's Gambit", 60, 57, 5531)
  add({ id = "dungeon-scholomance", title = name, zone = M.wpl, levels = { 57, 60 }, instanceID = 289, instance = name,
    links = { "dungeon-stratholme", "scholomance-key-horde" },
    bosses = bosses("dungeon-scholomance", { ["Kirtonos the Herald (summoned)"] = 2805, ["Jandice Barov"] = 2804,
      Rattlegore = 2811, ["Ras Frostwhisper"] = 2810, ["Doctor Theolen Krastinov"] = 2802, ["Lorekeeper Polkelt"] = 2808,
      ["Lady Illucia Barov and Lord Alexei Barov"] = 2807, ["The Ravenian"] = 2812, ["Instructor Malicia"] = 2803,
      ["Darkmaster Gandling"] = 2801 }, {
      { 4, { name = "Marduk Blackpool", encounter = 2809,
        tip = "He shares the balcony above the Viewing Room with Vectus. Pull him on his own if you can." } },
      { 5, { name = "Vectus", encounter = 2813, npc = 10432,
        tip = "On the same balcony. Dawn's Gambit, placed in the Viewing Room, turns the students below into skeletons; clear them before you take him." } },
    }),
    sources = { "https://www.wowhead.com/forever/zone=2057", "https://questing.wiki/wow-forever/dungeons/scholomance/quests/" } }, {
    B.withGuide("scholomance-key-horde", tip("Skeleton Key", "Scholomance needs the Skeleton Key. One key holder opens the door for the whole group.")),
    taxi("fly", lightsHopeFlights, "Light's Hope Chapel, Eastern Plaguelands", "Fly to Light's Hope Chapel. Without that flight path, ride east from the Undercity through both Plaguelands."),
    accept(5529, betina, "Betina Bigglezink wants the plagued dragon hatchlings in Scholomance destroyed."),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
    action("goto", alexi, "Leave the Undercity and ride east to the Bulwark at the edge of the Plaguelands."),
    accept(5341, alexi, "Alexi Barov wants his family's four deeds back from Scholomance."),
    action("goto", eva, "Ride east into the Western Plaguelands and follow the road south-east to the lake around Caer Darrow."),
    accept(5382, eva, "Eva Sarkhoff's ghost wants Doctor Theolen Krastinov destroyed and her family's remains burned."),
    enter(name, caerDarrow, "Cross to Caer Darrow and enter Scholomance under the castle with your key."),
  }, {
    objective(5529, nil, "The plagued hatchlings fill the dragon nest room below the entry halls.", "20 Plagued Hatchlings"),
    objective(5341, nil, "Loot the four Barov deeds from the Barov family members and the chests in their rooms.",
      "The Deed to Brill", "The Deed to Caer Darrow", "The Deed to Southshore", "The Deed to Tarren Mill"),
    objective(5382, nil, "Kill Doctor Theolen Krastinov, then burn the remains of Eva and Lucien Sarkhoff in his room.",
      "Doctor Theolen Krastinov", "Remains of Eva Sarkhoff Burned", "Remains of Lucien Sarkhoff Burned"),
    carried(withItem(12368, objective(4771, nil, "If you carry Dawn's Gambit, place it in the Viewing Room and defeat Vectus.", "Vectus"))),
    finish(5382, eva, "Step outside to Eva Sarkhoff if you want to go on in the same run."),
    accept(5515, eva, "Eva wants Krastinov's Bag of Horrors from Jandice Barov."),
    objective(5515, nil, "Kill Jandice Barov and loot the bag.", "Krastinov's Bag of Horrors"),
    finish(5515, eva, "Bring the bag to Eva outside."),
    accept(5384, eva, "Eva gives you the Blood of Innocents to call Kirtonos the Herald."),
    withItem(13523, objective(5384, nil, "Place the Blood of Innocents in the brazier on the porch and kill Kirtonos.", "Kirtonos the Herald")),
  }, {
    finish(5384, eva, "Eva rewards you with the Spectral Essence. Wear it to see Magistrate Marduke."),
    accept(5461, marduke, "Magistrate Marduke stands beside Eva. He wants a Keepsake of Remembrance from Stromgarde."),
    action("goto", alexi, "Ride back west to the Bulwark."),
    finish(5341, alexi),
    taxi("fly", hammerfallFlights, "Hammerfall, Arathi", "Ride to the Undercity and fly to Hammerfall."),
    action("goto", on.arathi("Stromgarde", 18.5, 66.7), "Ride west across Arathi to the ruins of Stromgarde."),
    objective(5461, on.arathi("Keepsake of Remembrance", 18.5, 66.7), "Search the ruins of Stromgarde for the Keepsake of Remembrance.", "Keepsake of Remembrance"),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Ride back to Hammerfall and fly to the Undercity."),
    action("goto", marduke, "Ride east past the Bulwark to Caer Darrow."),
    finish(5461, marduke),
    accept(5462, marduke, "Marduke sends you to Leonid Barthalomew at Light's Hope."),
    taxi("fly", lightsHopeFlights, "Light's Hope Chapel, Eastern Plaguelands", "Ride back to the Undercity and fly to Light's Hope Chapel."),
    finish(5529, betina),
    carried(finish(4771, betina, "If you carried Dawn's Gambit, hand it in to Betina too.")),
    finish(5462, leonid),
    accept(5463, leonid, "Leonid sends the Keepsake to Menethil's Gift in Stratholme."),
    action("goto", stratGate, "Ride north-west to Stratholme. The service gate on the east side leads to the dead side."),
    finish(5463, nil, "On the dead side of Stratholme, place the Keepsake on Menethil's Gift, the patch of unholy ground."),
    accept(5464, nil, "Take the Soulbound Keepsake from Menethil's Gift."),
    action("goto", leonid, "Leave Stratholme and ride back to Light's Hope Chapel."),
    finish(5464, leonid),
    accept(5465, leonid, "Leonid sends you back to Marduke."),
    taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
    action("goto", marduke, "Ride east past the Bulwark to Caer Darrow."),
    finish(5465, marduke),
    accept(5466, marduke, "Marduke wants Ras Frostwhisper made mortal and killed."),
    withItem(13752, objective(5466, nil, "On your next Scholomance run, use the Soulbound Keepsake on Ras Frostwhisper, then kill him and take his head.",
      "Human Head of Ras Frostwhisper")),
    finish(5466, marduke, "Bring the head to Marduke outside."),
  })
end

-- Stratholme. Light's Hope pickups, Egan, Zverenhoff's chain to the Argent Hold; Nathanos's Ramstein carried in.
do
  local name = "Stratholme"
  local ep = on.epl
  local alen = ep("Caretaker Alen", 69.93, 53.72)
  local zverenhoff = ep("Duke Nicholas Zverenhoff", 71.63, 50.09)
  local smokey = ep("Smokey LaRue", 70.88, 48.43)
  local tyrosus = ep("Lord Maxwell Tyrosus", 71.9, 48.41)
  local argentHold = ep("The Argent Hold", 71.96, 48.41)
  local egan = ep("Egan", 11.36, 26.6)
  local nathanos = ep("Nathanos Blightcaller", 22.23, 63.51)
  local tirion = ep("Tirion Fordring", 5.16, 35.57)
  B.q(5214, "The Great Ezra Grimm", 60, 55)
  need(5265, "The Argent Hold", 60, 55, 5264)
  need(6163, "Ramstein", 60, 56, 6135)
  add({ id = "dungeon-stratholme", title = name, zone = M.epl, levels = { 57, 60 }, instanceID = 329, instance = name,
    links = { "dungeon-scholomance" },
    bosses = bosses("dungeon-stratholme", { ["The Unforgiven"] = 472, ["Timmy the Cruel"] = 474, ["Cannon Master Willey"] = 475,
      ["Archivist Galford"] = 477, Balnazzar = 478, ["Baroness Anastari"] = 479, ["Nerub'enkan"] = 480,
      ["Maleki the Pallid"] = 481, ["Ramstein the Gorger"] = 483, ["Baron Rivendare"] = 484 }, {
      { 2, { name = "Ezra Grimm", encounter = 2797,
        tip = "Opening the tobacco box in his smoke shop calls him. Fight him in the shop doorway and loot the tobacco after." } },
      { 7, { name = "Magistrate Barthilas", encounter = 482,
        tip = "He stands at the way into the dead side. Clear the area around him before you pull." } },
    }),
    sources = { "https://www.wowhead.com/forever/zone=2017", "https://www.wowhead.com/forever/quest=5214",
      "https://questing.wiki/wow-forever/dungeons/stratholme/quests/" } }, {
    taxi("fly", lightsHopeFlights, "Light's Hope Chapel, Eastern Plaguelands", "Fly to Light's Hope Chapel."),
    accept(5281, alen, "Caretaker Alen wants Egan found."),
    accept(5251, zverenhoff, "Duke Nicholas Zverenhoff wants Archivist Galford dead and the Scarlet Archive burned."),
    accept(5212, betina, "Betina Bigglezink wants plagued flesh samples."),
    accept(5214, smokey, "Smokey LaRue wants a box of Ezra Grimm's tobacco."),
    accept(5243, leonid, "Leonid Barthalomew wants Stratholme's holy water."),
    action("goto", egan, "Ride north-west across the Plaguelands to Egan."),
    finish(5281, egan),
    accept(5282, egan, "Egan gives you his blaster for the ghosts of Stratholme."),
    uncertain(enter(name, stratGate, "The main gate in the north-west leads to the living side and the Scarlet Bastion. The service gate on the east side leads to the dead side and Baron Rivendare."),
      "Gate spot converted from the classic map; check in game."),
  }, {
    withItem(13289, objective(5282, nil, "Use Egan's Blaster on ghostly citizens, then again on the souls that break free.", "15 Souls Freed")),
    objective(5212, nil, "Any creature in the city can drop plagued flesh.", "10 Plagued Flesh Samples"),
    objective(5243, nil, "Search the supply crates in the streets for holy water.", "5 Stratholme Holy Water"),
    objective(5214, nil, "On the living side, find Ezra Grimm's smoke shop. Open the tobacco box to call him, kill him and loot the tobacco.",
      "Grimm's Premium Tobacco"),
    carried(objective(5848, nil, "If you carry Of Love and Family: in the Scarlet Bastion, the painting hangs behind the twin moons painting.",
      "Of Love and Family")),
    objective(5251, nil, "Kill Archivist Galford in the Scarlet Archive and set the archive on fire.", "Archivist Galford", "Archive Burned"),
    tip("Head of Balnazzar", "Keep the Head of Balnazzar that Balnazzar drops. Its quest opens once The Archivist is handed in."),
    carried(objective(6163, nil, "If you carry Ramstein from Nathanos: on the dead side, kill Ramstein the Gorger and take his head.",
      "Head of Ramstein the Gorger")),
  }, {
    finish(5282, egan, "Leave the city and return to Egan."),
    action("goto", smokey, "Ride back to Light's Hope Chapel."),
    finish(5214, smokey),
    finish(5243, leonid),
    finish(5212, betina),
    accept(5213, betina, "Betina wants new Scourge data from the dead side's ziggurats."),
    finish(5251, zverenhoff),
    withItem(13250, accept(5262, zverenhoff, "Use the Head of Balnazzar now.")),
    finish(5262, zverenhoff),
    accept(5263, zverenhoff, "Zverenhoff now wants Baron Rivendare's head."),
    action("goto", nathanos, "Ride west across the Plaguelands to Nathanos Blightcaller at Marris Stead.", { ifOnQuest = 6163 }),
    carried(finish(6163, nathanos, "Give Nathanos the head of Ramstein.")),
    carried(finish(5848, tirion, "If you carry Of Love and Family, ride to Tirion Fordring's hut by the river in the far west and give him the painting.")),
    action("goto", stratGate, "Ride north-west to Stratholme for a dead-side run."),
    objective(5213, nil, "On the dead side, search the ziggurats for new Scourge data.", "Scourge Data"),
    objective(5263, nil, "On the dead side, kill Baron Rivendare and take his head.", "Head of Baron Rivendare"),
    action("goto", betina, "Leave Stratholme and ride back to Light's Hope Chapel."),
    finish(5213, betina),
    finish(5263, zverenhoff),
    accept(5264, zverenhoff, "Zverenhoff sends you to Lord Maxwell Tyrosus."),
    finish(5264, tyrosus, "Lord Maxwell Tyrosus is inside the chapel."),
    accept(5265, tyrosus, "Tyrosus opens the Argent Hold for you."),
    finish(5265, argentHold, "Open the Argent Hold beside him and choose your reward."),
  })
end

-- Horde attunements and keys (special guides).
H.road(M.arathi, M.wetlands, on.arathi(nil, 43.4, 92.1), "Cross Thandol Span south into the Wetlands")
H.road(M.wetlands, M.arathi, on.wetlands(nil, 50.2, 13.6), "Cross Thandol Span north into Arathi")

-- Onyxia's Lair: Thrall's For The Horde! leads to Rexxar, Myranda and Emberstrife's tests.
do
  local rexxar = on.feralas("Rexxar", 46.39, 18.24)
  local myranda = on.wpl("Myranda the Hag", 50.79, 77.85)
  local emberstrife = on.dustwallow("Emberstrife", 56.66, 87.72)
  need(6566, "What the Wind Carries", 60, 55, 4974)
  need(6567, "The Champion of the Horde", 60, 55, 6566)
  need(6568, "The Testament of Rexxar", 60, 55, 6567)
  need(6569, "Oculus Illusions", 60, 55, 6568)
  need(6570, "Emberstrife", 60, 55, 6569)
  need(6582, "The Test of Skulls, Scryer", 60, 55, 6570)
  need(6583, "The Test of Skulls, Somnus", 60, 55, 6570)
  need(6584, "The Test of Skulls, Chronalis", 60, 55, 6570)
  need(6585, "The Test of Skulls, Axtroz", 60, 55, { 6582, 6583, 6584 })
  need(6601, "Ascension...", 60, 55, 6585)
  need(6602, "Blood of the Black Dragon Champion", 60, 55, 6601)
  special({ id = "attunement-onyxia-horde", title = "Blood of the Black Dragon Champion (Onyxia's Lair)", zone = M.dustwallow,
    levels = { 55, 60 }, links = { "dungeon-lower-blackrock-spire", "dungeon-upper-blackrock-spire" },
    sources = { "https://www.wowhead.com/forever/quest=6602/blood-of-the-black-dragon-champion",
      "https://www.wowhead.com/forever/quest=4974/for-the-horde" },
    steps = {
      taxi("fly", kargathFlights, "Kargath, Badlands", "Fly to Kargath in the Badlands."),
      uncertain(accept(4903, goretooth, "Warlord Goretooth wants the three Lower Spire generals dead and their battle plans."),
        "Some players report Goretooth must be at the top of Kargath's tower to offer this."),
      B.withGuide("dungeon-lower-blackrock-spire", objective(4903, nil, "In Lower Blackrock Spire, kill Highlord Omokk, War Master Voone and Overlord Wyrmthalak and take the Important Blackrock Documents.",
        "Overlord Wyrmthalak", "Highlord Omokk", "War Master Voone", "Important Blackrock Documents")),
      finish(4903, goretooth, "Fly back to Kargath."),
      accept(4941, goretooth, "Goretooth sends you to Eitrigg and Thrall in Orgrimmar."),
      taxi("fly", ucFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
      action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
      finish(4941, thrall, "In Grommash Hold, talk to Eitrigg first, then report to Thrall."),
      accept(4974, thrall, "Thrall wants the head of Warchief Rend Blackhand."),
      B.withGuide("dungeon-upper-blackrock-spire", objective(4974, nil, "In Upper Blackrock Spire, kill Gyth and Warchief Rend Blackhand and take Rend's head.",
        "Head of Rend Blackhand")),
      finish(4974, thrall, "Bring Rend's head to Thrall in Orgrimmar."),
      accept(6566, thrall, "Thrall has news from the winds."),
      finish(6566, thrall, "Listen to Thrall's story."),
      accept(6567, thrall, "Thrall sends you to find Rexxar on the roads between Desolace and Feralas."),
      taxi("fly", mojacheFlights, "Camp Mojache, Feralas", "Fly to Camp Mojache."),
      uncertain(action("goto", rexxar, "Ride north-west to the road at the Desolace border. Rexxar walks it with his bear, Misha."),
        "Rexxar patrols: look along the road if he is not here."),
      finish(6567, rexxar),
      accept(6568, rexxar, "Rexxar gives you a letter for Myranda the Hag in the Western Plaguelands."),
      taxi("fly", ogFlights, "Orgrimmar, Durotar", "Ride back to Camp Mojache and fly to Orgrimmar."),
      action("boat", durotarTower, "Take the zeppelin to the Undercity."),
      action("goto", myranda, "Ride east past the Bulwark into the Western Plaguelands and south to Sorrow Hill."),
      finish(6568, myranda),
      accept(6569, myranda, "Myranda needs 20 Black Dragonspawn Eyes for her illusion."),
      B.withGuide("dungeon-lower-blackrock-spire", objective(6569, nil, "Kill Rage Talon dragonspawn in Blackrock Spire for their eyes.", "20 Black Dragonspawn Eyes")),
      action("goto", myranda, "Return to Myranda at Sorrow Hill."),
      finish(6569, myranda),
      accept(6570, myranda, "Myranda gives you the Amulet of Draconic Subversion. Wear it when you meet Emberstrife."),
      action("boat", tirisfalTower, "Ride to the Undercity's zeppelin tower and take the zeppelin to Orgrimmar."),
      taxi("fly", brackenwallFlights, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village."),
      action("goto", emberstrife, "Ride south through the marsh to the Wyrmbog. Emberstrife's den is in the far south."),
      finish(6570, emberstrife, "Put on the Amulet of Draconic Subversion and talk to Emberstrife in his den."),
      accept(6582, emberstrife, "Emberstrife wants the skull of Scryer, the blue drake champion."),
      accept(6583, emberstrife, "He wants the skull of Somnus, the green champion."),
      accept(6584, emberstrife, "He wants the skull of Chronalis, the bronze champion."),
      taxi("fly", gadgetzanFlights, "Gadgetzan, Tanaris", "Ride back to Brackenwall Village and fly to Gadgetzan."),
      action("goto", on.tanaris("Chronalis", 64.2, 48.5), "Ride south-east to the Caverns of Time."),
      objective(6584, on.tanaris("Chronalis", 64.2, 48.5), "Kill Chronalis at the Caverns of Time and take his skull. Bring a group.", "The Skull of Chronalis"),
      taxi("fly", everlookFlights, "Everlook, Winterspring", "Ride back to Gadgetzan and fly to Everlook."),
      objective(6582, on.winterspring("Scryer", 52.7, 55.9), "Scryer lairs south-west of Everlook. Kill him and take his skull. Bring a group.", "The Skull of Scryer"),
      taxi("fly", ogFlights, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
      action("boat", gromgolZeppelin, "Take the zeppelin to Grom'gol."),
      taxi("fly", stonardFlights, "Stonard, Swamp of Sorrows", "Fly to Stonard."),
      objective(6583, on.swamp("Somnus", 74.1, 68.3), "Somnus flies over the south-east of the swamp. Kill him and take his skull. Bring a group.", "The Skull of Somnus"),
      taxi("fly", on.stv("Thysta", 32.5, 29.4), "Grom'gol, Stranglethorn", "Ride back to Stonard and fly to Grom'gol."),
      action("boat", on.stv("Nez'raz", 31.4, 29.9), "Take the zeppelin to Orgrimmar."),
      taxi("fly", brackenwallFlights, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village."),
      action("goto", emberstrife, "Ride south to Emberstrife's den in the Wyrmbog."),
      finish(6582, emberstrife, "Wear the amulet and hand Emberstrife the skulls."),
      finish(6583, emberstrife),
      finish(6584, emberstrife),
      accept(6585, emberstrife, "The last test: the skull of Axtroz, the red champion at Grim Batol."),
      taxi("fly", hammerfallFlights, "Hammerfall, Arathi", "Ride back to Brackenwall, fly to Orgrimmar, take the zeppelin to the Undercity and fly to Hammerfall."),
      action("goto", on.wetlands("Grim Batol", 81.8, 48.2), "Ride south across Thandol Span into the Wetlands and east to Grim Batol."),
      uncertain(objective(6585, on.wetlands("Axtroz", 81.8, 48.2), "Kill Axtroz at Grim Batol and take his skull. Bring a group: the dragons there hit hard.", "The Skull of Axtroz"),
        "Grim Batol's guards and level in Forever: check in game."),
      taxi("fly", brackenwallFlights, "Brackenwall Village, Dustwallow Marsh", "Ride back to Hammerfall, fly to the Undercity, take the zeppelin to Orgrimmar and fly to Brackenwall."),
      action("goto", emberstrife, "Ride south to Emberstrife's den."),
      finish(6585, emberstrife),
      accept(6601, emberstrife, "The amulet won't work inside Blackrock Spire. Show the Dull Drakefire Amulet to Rexxar."),
      taxi("fly", mojacheFlights, "Camp Mojache, Feralas", "Ride back to Brackenwall Village and fly to Camp Mojache."),
      action("goto", rexxar, "Ride north-west to Rexxar's road."),
      finish(6601, rexxar),
      accept(6602, rexxar, "Rexxar wants the blood of General Drakkisath."),
      B.withGuide("dungeon-upper-blackrock-spire", objective(6602, nil, "In Upper Blackrock Spire, kill General Drakkisath and take his blood.",
        "Blood of the Black Dragon Champion")),
      action("goto", rexxar, "Travel back to Rexxar on the Desolace and Feralas road."),
      finish(6602, rexxar, "Rexxar turns your amulet into the Drakefire Amulet: it opens Onyxia's Lair in Dustwallow Marsh."),
    },
  })
end

-- The Seal of Ascension (Upper Blackrock Spire's door).
special({ id = "ubrs-seal-horde", title = "Seal of Ascension (Upper Blackrock Spire)", zone = M.searing, levels = { 57, 60 },
  links = { "dungeon-lower-blackrock-spire", "dungeon-upper-blackrock-spire" },
  sources = { "https://www.wowhead.com/forever/quest=4742/seal-of-ascension" },
  steps = {
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest in the Burning Steppes."),
    action("goto", brm, "Ride west into Blackrock Mountain and enter Lower Blackrock Spire with your group."),
    accept(4742, nil, "Vaelan, a captured dragon in disguise, stands near the start of Lower Blackrock Spire."),
    objective(4742, nil, "Kill Highlord Omokk, War Master Voone and Overlord Wyrmthalak for their gemstones, and loot an Unadorned Seal of Ascension from the Spire's orcs.",
      "Gemstone of Spirestone", "Gemstone of Smolderthorn", "Gemstone of Bloodaxe", "Unadorned Seal of Ascension"),
    finish(4742, nil, "Bring everything back to Vaelan."),
    accept(4743, nil, "Vaelan sends you to break a black drake with the Unforged Seal."),
    taxi("fly", brackenwallFlights, "Brackenwall Village, Dustwallow Marsh", "Leave the Spire. Fly to the Undercity, take the zeppelin to Orgrimmar and fly to Brackenwall Village."),
    action("goto", on.dustwallow("Emberstrife", 56.66, 87.72), "Ride south to Emberstrife's den in the Wyrmbog."),
    uncertain(objective(4743, on.dustwallow("Emberstrife", 56.66, 87.72),
      "Beat Emberstrife, a level 61 elite drake, down to low health, set the Unforged Seal before him and use the Orb of Draconic Energy on him. Bring a group.",
      "Forged Seal of Ascension"), "Emberstrife's guards and the exact order: check in game."),
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Orgrimmar, take the zeppelin to the Undercity and fly to Flame Crest."),
    action("goto", brm, "Ride west into Blackrock Mountain and back into Lower Blackrock Spire."),
    finish(4743, nil, "Give Vaelan the Forged Seal. The Seal of Ascension opens Upper Blackrock Spire."),
  },
})

-- Attunement to the Core (Molten Core) and the Shadowforge Key (Blackrock Depths).
special({ id = "molten-core-attunement-horde", title = "Attunement to the Core", zone = M.searing, levels = { 55, 60 },
  links = { "dungeon-blackrock-depths" },
  sources = { "https://www.wowhead.com/forever/quest=7848/attunement-to-the-core" },
  steps = {
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest in the Burning Steppes."),
    action("goto", brm, "Ride west into Blackrock Mountain."),
    accept(7848, nil, "Lothos Riftwaker waits on the ledge just past the chain down to Blackrock Depths."),
    B.withGuide("dungeon-blackrock-depths", objective(7848, nil, "In Blackrock Depths, go past Lord Incendius to the Molten Core portal and take a Core Fragment from the rock beside it.",
      "Core Fragment")),
    finish(7848, nil, "Return to Lothos. Once attuned he can send you straight to Molten Core."),
  },
})

special({ id = "shadowforge-key-horde", title = "Dark Iron Legacy (Shadowforge Key)", zone = M.searing, levels = { 52, 60 },
  links = { "dungeon-blackrock-depths" },
  sources = { "https://www.wowhead.com/forever/quest=3802/dark-iron-legacy" },
  steps = {
    taxi("fly", flameCrestFlights, "Flame Crest, Burning Steppes", "Fly to Flame Crest in the Burning Steppes."),
    action("goto", brm, "Ride west into Blackrock Mountain."),
    uncertain(accept(3801, nil, "Franclorn Forgewright's ghost lies on the stone ledge in the middle of the mountain. Only a spirit sees him: die nearby and talk to him before you resurrect."),
      "Check that Forever keeps the ghost-only rule."),
    finish(3801, nil, "Listen to Franclorn's story."),
    accept(3802, nil, "Franclorn asks you to put his hammer back on his statue."),
    B.withGuide("dungeon-blackrock-depths", objective(3802, nil, "In Blackrock Depths, kill Fineous Darkvire for the hammer Ironfel.", "Ironfel")),
    finish(3802, nil, "Place Ironfel on Franclorn's statue in the Shrine of Thaurissan and take the Shadowforge Key. It opens the doors deeper in the Depths."),
  },
})

-- The Skeleton Key (Scholomance): the Bulwark's chain through Andorhal, Gadgetzan and Fire Plume Ridge.
do
  local balthazad = uc("Harbinger Balthazad", 63.9, 44.08)
  local derrington = on.tirisfal("High Executor Derrington", 83.13, 68.94)
  local dithers = on.tirisfal("Apothecary Dithers", 83.28, 69.23)
  local krinkle = on.tanaris("Krinkle Goodsteel", 51.46, 28.81)
  local wp = on.wpl
  need(5094, "A Call to Arms: The Plaguelands!", 50, 50)
  need(5096, "Scarlet Diversions", 53, 50, 5094)
  need(5098, "All Along the Watchtowers", 56, 50, 5096)
  need(838, "Scholomance", 55, 55, 5098)
  need(964, "Skeletal Fragments", 57, 55, 838)
  need(5514, "Mold Rhymes With...", 57, 55, 964)
  need(5802, "Fire Plume Forged", 57, 55, 5514)
  need(5804, "Araj's Scarab", 60, 55, 5802)
  need(5511, "The Key to Scholomance", 60, 55, 5804)
  special({ id = "scholomance-key-horde", title = "The Key to Scholomance", zone = M.wpl, levels = { 55, 60 },
    links = { "dungeon-scholomance" },
    sources = { "https://www.wowhead.com/forever/quest=5511/the-key-to-scholomance" },
    steps = {
      accept(5094, balthazad, "In the Undercity's Trade Quarter, Harbinger Balthazad calls for help at the Bulwark."),
      action("goto", derrington, "Leave the Undercity and ride east to the Bulwark."),
      finish(5094, derrington),
      accept(5096, derrington, "High Executor Derrington wants the Scarlet command tent in the Plaguelands burned."),
      collect(12814, on.tirisfal("Box of Incendiaries", 83.2, 69.1), "Take a Flame in a Bottle from the Box of Incendiaries at the Bulwark."),
      uncertain(objective(5096, nil, "Ride into the Western Plaguelands to the Scarlet camp between Felstone Field and Dalson's Tears. Burn the command tent and plant the Scourge banner."),
        "The camp's exact spot: check in game."),
      finish(5096, derrington, "Return to Derrington at the Bulwark."),
      accept(5098, derrington, "Derrington gives you a Beacon Torch for the four towers of Andorhal."),
      part(5098, 3, wp("Andorhal tower", 44.3, 63.2), "Ride to Andorhal. Stand in the doorway of the north-east tower and use the torch.", "Tower Three marked"),
      part(5098, 2, wp("Andorhal tower", 42.3, 66.2), "Mark the next tower to the south-west.", "Tower Two marked"),
      part(5098, 1, wp("Andorhal tower", 40.0, 71.6), "Mark the south-west tower.", "Tower One marked"),
      part(5098, 4, wp("Andorhal tower", 46.6, 71.0), "Cross east to the last tower and mark it.", "Tower Four marked"),
      finish(5098, derrington, "Ride back to the Bulwark."),
      accept(838, derrington, "Derrington sends you to Apothecary Dithers beside him."),
      finish(838, dithers),
      accept(964, dithers, "Dithers wants skeletal fragments from Andorhal's undead."),
      objective(964, wp("Andorhal", 45.1, 67.2), "Kill skeletons in and around Andorhal for their fragments.", "15 Skeletal Fragments"),
      finish(964, dithers, "Ride back to the Bulwark."),
      accept(5514, dithers, "Dithers wants the fragments shaped by Krinkle Goodsteel in Gadgetzan. Bring 15 gold."),
      action("boat", tirisfalTower, "Ride to the Undercity's zeppelin tower and take the zeppelin to Orgrimmar."),
      taxi("fly", gadgetzanFlights, "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
      finish(5514, krinkle),
      accept(5802, krinkle, "Krinkle gives you the Skeleton Key Mold. You also need 2 Thorium Bars."),
      action("collect", nil, "Get 2 Thorium Bars: smelt them or buy them at the Auction House.", { item = 12359, count = 2 }),
      taxi("fly", marshalFlights, "Marshal's Refuge, Un'Goro Crater", "Fly to Marshal's Refuge in Un'Goro Crater."),
      objective(5802, on.ungoro("Fire Plume Ridge", 50.5, 49.5), "Climb Fire Plume Ridge in the middle of the crater and use the mold beside the lava lake.",
        "Unfinished Skeleton Key"),
      taxi("fly", ogFlights, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
      action("boat", durotarTower, "Take the zeppelin to the Undercity."),
      action("goto", dithers, "Ride east to the Bulwark."),
      finish(5802, dithers),
      accept(5804, dithers, "Dithers wants the scarab of Araj the Summoner."),
      uncertain(objective(5804, wp("Araj the Summoner", 45.27, 69.21), "Araj stands in the middle of Andorhal with his guards. Bring a group, kill him and loot his scarab.",
        "Araj's Scarab"), "Araj is a level 61 elite; the group size needed is not confirmed for Forever."),
      finish(5804, dithers, "Ride back to the Bulwark."),
      accept(5511, derrington, "Derrington finishes the key."),
      finish(5511, derrington, "Take the Skeleton Key. It opens Scholomance on Caer Darrow."),
    },
  })
end
