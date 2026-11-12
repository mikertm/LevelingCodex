-- Horde route: the Riverglades (Forever zone: Rog'mar, Bolder'ok, Powderfuse Port) and Shen'dralas,
-- four alternate routes, and the Horde Krol'dok Stronghold guide.
-- Source notes: tools/audits/2026-11-12-horde-riverglades.md.
--
-- QuestieDB's cached Forever data has no Riverglades or Shen'dralas quests. Givers, enders and their
-- positions come from bindonforever.com quest and NPC pages (QuestieDB-format data for client build
-- 1.60.1.70888); objectives, levels and sides from ForeverDB quest pages; quest-starting items from the
-- client's ItemSparse table; the instance and its encounters from tools/reference/forever.json.
-- Objective spots are the centre of the target creatures' published spawn points. Anything the
-- sources did not settle carries a B.note for an in-game check.
local B = LevelingCodexQuests.build
local H = B.horde
local route = LevelingCodexQuests.HORDE
local M, on = B.maps, B.on
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, part, withItem, along, note = B.objectiveAt, B.objectivePart, B.withItem, B.along, B.note
local need, alternate, dungeon = H.need, H.alternate, H.dungeon
local rg = on.riverglades

-- The target button's creatures (QuestMobData.lua has no Forever-only Riverglades quests).
local function targets(step, ...)
  step.mobs = { ... }
  return step
end

local function fromItem(id, item, name, level, min, prerequisite)
  need(id, name, level, min, prerequisite, true)
  B.quest[id].startItem = item
end

local ROGMAR, PORT = "Rog'mar, Riverglades", "Powderfuse Port, Riverglades"
local rogmarInn = { bind = "Rog'mar" }

-- Places more than one chapter uses (bindonforever NPC pages; the flight points from the client).
local place = {
  flight = rg("Grakna", 59.6, 45.1),
  toka = rg("Innkeeper Toka", 58.4, 46.2),
  kromrosh = rg("Krom'rosh", 59.4, 45.6),
  kreza = rg("Kreza Darkthorn", 59.9, 46.0),
  gorg = rg("Gorg", 58.6, 44.6),
  neza = rg("Neza Bloodsnout", 60.5, 47.9),
  tanjani = rg("Tan'jani", 58.1, 45.3),
  trangul = rg("Tran'gul", 59.5, 44.0),
  dagrosh = rg("Da'grosh", 33.5, 37.9),
  clugfist = rg("Clugfist", 64.2, 15.7),
  friz = rg("Friz Frazzlespark", 77.1, 52.9),
  whizzbuzz = rg("Wharfmaster Whizzbuzz", 79.5, 52.7),
  portFlight = rg(nil, 79.0, 52.3),
}

local zoneSources = {
  "https://bindonforever.com/zones/riverglades",
  "https://bindonforever.com/npcs/riverglades",
  "https://www.foreverdb.app/en/forever/zones/riverglades/quests",
  "https://warcraft.wiki.gg/wiki/Riverglades",
}

-- The goblin barge between Tanaris and the Riverglades (both factions). Rog'mar's flights reach
-- Hammerfall, Kargath, Stonard and Flame Crest once you have learned it.
do
  local steamwheedle = on.tanaris("Wharfmaster Steamfizzle", 67.6, 23.1)
  H.road(M.tanaris, M.riverglades, steamwheedle, "Take the barge from Steamwheedle Port to Powderfuse Port")
  H.road(M.riverglades, M.tanaris, place.whizzbuzz, "Take the barge from Powderfuse Port to Steamwheedle Port")
  H.road(M.desolace, M.shendralas, on.desolace(nil, 58.6, 88.8),
    "Ride into the Valley of Bones at the south end of Desolace and on into Shen'dralas")
end

-- Alternate, 36-41: Rog'mar, the plains, Turner's Logging Camp, Meadowsbrook and the Bristle Hills.
do
  local p = place
  local carcass = rg("Picked Carcass", 61.6, 58.8)
  local plains = rg(nil, 53.3, 56.8)
  local turner = rg(nil, 41.5, 62.5)
  local meadowsbrook = rg(nil, 42.7, 80.8)
  local bristle = rg(nil, 16.6, 70.8)

  need(93786, "A Message in Blood", 36, 35, nil, true)
  need(93787, "Food for the Taking", 36, 36, 93786, true)
  need(94480, "A Gift From Our Enemies", 36, 36, 93787, true)
  need(94481, "A Serving of Strength", 38, 36, 94480, true)
  need(94483, "Show Them How It's Done", 39, 36, nil, true)
  need(93788, "Borrowed Blades", 38, 36, nil, true)
  need(93976, "The Goblin Trader", 36, 36, 93788, true)
  need(94535, "Bristle Hills Bandits", 38, 36, nil, true)
  need(94532, "Gnoll Infestation", 38, 36, nil, true)
  need(94533, "Snargl's Snout", 40, 36, nil, true)
  need(96107, "Feathers for Fletching", 40, 36, nil, true)
  need(96108, "Poison Tips", 40, 36, 96107, true)
  need(96109, "A Hunter's Quiver", 40, 36, 96108, true)
  need(96103, "A Feast for Buzzards", 38, 36, nil, true)
  need(96104, "Song of the Strider", 39, 36, 96103, true)
  need(96105, "King of the Wild Plains", 41, 36, 96104, true)
  need(95951, "Fetch 'n' Fletch", 38, 36, nil, true)
  need(95955, "Stick 'Em", 39, 36, 95951, true)
  need(95062, "Frazzlespark's Crate", 36, 36, nil, true)
  need(95033, "On the Other Side", 41, 40, nil, true)

  alternate("riverglades-rogmar", "Riverglades: Rog'mar and the Plains", M.riverglades, 36, 41, zoneSources,
    { "riverglades-bolderok", "riverglades-eastsea" }, {
    note(action("goto", p.flight, "Travel to Rog'mar, the Horde camp in the middle of the Riverglades. From Kalimdor, take the "
      .. "goblin barge from Steamwheedle Port in Tanaris to Powderfuse Port and ride west along the road. From the Eastern "
      .. "Kingdoms, ride in from the Badlands or north from the Swamp of Sorrows."),
      "The barge is confirmed by several sources; the overland ways in come from zone notes and need an in-game check."),
    taxi("getfp", p.flight, ROGMAR, "Learn the Rog'mar flight path from Grakna. It links to Kargath, Stonard, Hammerfall and Flame Crest."),
    accept(93786, p.kromrosh, "Krom'rosh leads the camp. He wants blood from the Alliance farm at Meadowsbrook."),
    note(accept(94483, p.kromrosh, "He also wants the Farholde soldiers at Turner's Logging Camp thinned out."),
      "No prerequisite is published; check that he offers it on your first visit."),
    accept(93788, p.kreza, "Kreza Darkthorn, the camp smith, wants the lumberjacks' axes."),
    accept(94535, p.kreza, "She also wants the ore the gnolls stole from the miners."),
    note(action("sethearth", p.toka, "Make Rog'mar your home at Innkeeper Toka. Each trip in this guide ends back here.", rogmarInn),
      "Bind name assumed to be Rog'mar."),
    accept(95951, p.tanjani, "Tan'jani the headhunter wants wood for throwing spears."),
    accept(94532, p.neza, "Neza Bloodsnout, the huntress at the south edge of camp, has three hunts for you."),
    note(accept(94533, p.neza), "Snargl is elite (level 40)."), accept(96107, p.neza),
    action("goto", plains, "Ride south onto the plains below Rog'mar."),
    targets(objective(96107, plains, "Kill Low Plains Buzzards for their coarse feathers.", "6 Plains Buzzard Feathers"),
      "Low Plains Buzzard"),
    accept(96103, carcass, "Look at the picked carcass just north of the Alliance watchtower and take its skull for Neza."),
    action("goto", turner, "Ride west along the river to Turner's Logging Camp, an Alliance lumber camp."),
    along(note(targets(objective(93788, rg(nil, 37.1, 62.6), "Kill the lumberjacks on the west side of the camp and take their axes.",
      "10 Woodworker's Axe"), "Turner's Mill Lumberjack", "Woodworker"),
      "Which of the camp's workers carry the axes is not published."), 95951, 94483),
    along(note(objective(95951, rg(nil, 38.5, 62.5),
      "Pick up Wood Bundles from the Peasant Woodpiles around the camp, then fletch them into spears.", "20 Makeshift Stickin' Spears"),
      "Woodpile spots and how the fletching works need an in-game check."), 93788),
    along(targets(objective(94483, rg(nil, 43.5, 64.6), "Kill Farholde Priests and Scouts on the east side of the camp.",
      "8 Farholde Priests", "12 Farholde Scouts"), "Farholde Priest", "Farholde Scout"), 93788),
    action("goto", meadowsbrook, "Ride south to the Meadowsbrook farm."),
    targets(objective(93786, meadowsbrook, "Kill Meadowsbrook Farmhands in the fields around the farm.", "12 Meadowsbrook Farmhands"),
      "Meadowsbrook Farmhand"),
    action("goto", bristle, "Ride west to the gnoll hills. Pass south of Southern Watch, the Alliance town."),
    along(targets(objective(94532, bristle, "Kill Redridge Mystics, Trappers and Brutes in the Bristle Hills.",
      "8 Redridge Mystics", "8 Redridge Trappers", "6 Redridge Brutes"), "Redridge Mystic", "Redridge Trapper", "Redridge Brute"),
      94535, 94533),
    along(note(objective(94535, bristle, "Loot Stolen Ore from the gnolls as you fight.", "40 Stolen Ore"),
      "Which gnolls carry the ore is not published."), 94532),
    note(targets(objective(94533, rg("Snargl", 16.6, 71.5), "Snargl leads the gnolls in the middle of the hills. Clear his guards first, "
      .. "then kill him for his snout.", "Snargl's Snout"), "Snargl"), "Elite, level 40: bring a friend if you are below 40."),
    action("hearth", p.toka, "Hearth to Rog'mar.", rogmarInn),
    finish(93786, p.kromrosh), accept(93787, p.kromrosh), finish(94483, p.kromrosh),
    finish(93788, p.kreza), finish(94535, p.kreza),
    accept(93976, p.kreza, "Kreza has a blade for a goblin trader at Powderfuse Port. Keep it until the end of this guide."),
    finish(95951, p.tanjani), accept(95955, p.tanjani),
    finish(94532, p.neza), finish(94533, p.neza), finish(96107, p.neza), accept(96108, p.neza),
    finish(96103, p.neza, "Show Neza the skull. She knows the lion that made those marks."), accept(96104, p.neza),
    action("goto", plains, "Go back down to the plains."),
    targets(objective(96104, rg(nil, 52.9, 57.7), "Kill Roving Tallstriders until one leaves its beak whole.", "Intact Tallstrider Beak"),
      "Roving Tallstrider"),
    targets(objective(96108, rg(nil, 58.1, 59.8), "Kill Glade Vipers by the pools near the watchtower for their venom.", "4 Glade Viper Venom"),
      "Glade Viper"),
    action("goto", rg(nil, 40.9, 59.1), "Ride west to the river north of Turner's Logging Camp."),
    note(targets(objective(95955, rg(nil, 40.9, 59.1), "Throw your spears at the Freshwater Crocolisks along the river.",
      "10 Freshwater Crocolisks"), "Freshwater Crocolisk"), "Check whether the spears are thrown from an item button."),
    action("goto", meadowsbrook, "Ride south to Meadowsbrook once more."),
    note(objective(93787, meadowsbrook, "Take Feed Satchels from around the Meadowsbrook farm.", "6 Feed Satchels"),
      "Satchel spots are not published; search the barns and fields."),
    action("goto", p.kromrosh, "Ride back north to Rog'mar."),
    finish(95955, p.tanjani), finish(93787, p.kromrosh), accept(94480, p.kromrosh),
    finish(94480, p.gorg, "Bring the stolen feed to Gorg, the camp cook."), accept(94481, p.gorg),
    finish(96108, p.neza), accept(96109, p.neza), finish(96104, p.neza), accept(96105, p.neza),
    note(targets(objective(94481, rg(nil, 55.9, 38.7), "Feed the Rog'mar Trainees at the training grounds just northwest of camp.",
      "8 Rog'mar Trainees fed"), "Rog'mar Trainee"), "Check whether the stew is used from an item button."),
    finish(94481, p.gorg),
    action("goto", rg(nil, 55.5, 54.5), "Ride south to the lions' hill on the plains."),
    along(targets(objective(96109, rg(nil, 55.0, 54.2), "Kill Wildplains Huntresses and Patriarchs for prized lion hides.",
      "6 Prized Lion Hides"), "Wildplains Huntress", "Wildplains Patriarch"), 96105),
    note(withItem("Tallstrider Call", targets(objective(96105, rg("Ombassa", 57.1, 56.3),
      "At the top of the hill, use the Tallstrider Call to bring out Ombassa, the pride leader. Kill it and take its hide.",
      "Ombassa's Hide"), "Ombassa")), "Ombassa is elite (level 41). Bring a friend if you need one."),
    action("goto", p.neza, "Ride back to Rog'mar."),
    finish(96109, p.neza), finish(96105, p.neza),
    B.optional(accept(95033, p.tanjani, "If you go to Feralas next, Tan'jani sends you to Witch Doctor Uzer'i at Camp Mojache.")),
    action("goto", p.friz, "Ride east along the road to Powderfuse Port, the goblin town on the coast."),
    note(taxi("getfp", p.portFlight, PORT, "Learn the Powderfuse Port flight path if a flight master is there."),
      "The client lists a Horde flight point here with no routes yet; a creator found no flight master on the beta."),
    finish(93976, p.friz, "Give Kreza's blade to Friz Frazzlespark and tell her they are even."),
    accept(95062, p.friz, "Friz has a crate for Krom'rosh."),
    action("goto", p.kromrosh, "Ride back west to Rog'mar."),
    finish(95062, p.kromrosh),
  })
end

-- Alternate, 41-46: Sunnyglade, the Bolder'ok ogres and their Bloodmaster's Ring, and the Twilight's Shroud.
do
  local p = place
  local clubtoe = rg("Clubtoe", 50.0, 47.0)
  local fuzzle = rg("Fuzzle", 47.3, 51.4)
  local stash = rg("Fuzzle's Treasure", 41.6, 47.7)
  local jezap = rg("Jezap Jinglesprocket", 65.6, 21.4)
  local ring = rg(nil, 65.4, 19.7)
  local gobam = rg("Gobam", 67.0, 17.2)
  local gorgegut = rg("Gorgegut", 69.6, 25.9)
  local hamur = rg("Hamur", 67.2, 21.8)
  local jomjom = rg("Jom-jom", 73.4, 24.7)
  local cragrog = rg("Crag'rog", 27.7, 36.5)
  local camp = rg(nil, 39.5, 45.5)
  local caves = rg(nil, 45.5, 51.2)
  local shroud = rg(nil, 26.0, 42.5)

  need(94672, "Encroaching Twilight", 41, 36, nil, true)
  need(94680, "Twilight Missives", 41, 36, nil, true)
  need(94727, "Digging for Answers", 40, 36, 94680, true)
  need(94961, "Biting the Hand", 40, 36, nil, true)
  need(94963, "Biting the Hand", 40, 36, 94961, true)
  need(95992, "WANTED: Ghostmaw", 42, 38, nil, true)
  need(95882, "WANTED: Scoutmaster Vargas", 43, 38, nil, true)
  need(95602, "Sickening Lights", 40, 36, nil, true)
  need(95417, "The Purple Ones", 40, 36, nil, true)
  need(95601, "The Purple Ones", 40, 36, 95417, true)
  need(95427, "Twilight No More!", 41, 36, 95601, true)
  need(95418, "Spread the Word", 40, 36, 95427, true)
  need(95420, "Land of Giants", 40, 36, 95418, true)
  need(95424, "Might Makes Right", 41, 36, nil, true)
  need(95425, "Unworthy Champion", 42, 36, nil, true)
  need(95428, "Clugfist's Decree", 41, 36, 95424, true)
  need(94744, "The Wayward Warrior", 43, 38, 95428, true)
  need(94556, "Jom-jom's Escape", 42, 36, nil, true)
  need(95183, "Step One: Rock", 41, 38, nil, true)
  need(94668, "Bloodmaster's Ring", 41, 36, nil, true)
  need(94669, "Pay to Play", 41, 36, 94668, true)
  need(94670, "Bloodmaster's Ring", 41, 36, 94669, true)
  need(94739, "Bloodmaster's Ring", 42, 36, 94670, true)
  need(94962, "Bloodmaster's Ring", 42, 36, 94739, true)
  need(94964, "Bloodmaster's Ring", 43, 36, 94962, true)
  need(94733, "Our Ogre Friend", 41, 36, 94964, true)
  need(94734, "A Boar's Delight", 41, 36, 94733, true)
  need(94737, "A Treat for a Friend", 41, 36, 94734, true)
  need(94965, "Bloodmaster's Ring", 44, 36, 94737, true)
  need(95063, "Bloodmaster's Ring", 45, 36, 94965, true)
  need(95431, "Rumblings of Discontent", 41, 38, nil, true)
  need(95432, "Rise Up!", 43, 36, 95431, true)
  need(95433, "Death to the Executioner", 46, 36, 95432, true)
  need(94745, "Carving a Path", 44, 38, nil, true)
  need(94748, "Break Their Chains", 44, 38, nil, true)
  need(94768, "Bring Me His Head", 46, 38, { 94745, 94748 }, true)
  need(95278, "It Is Time, Brother...", 45, 38, 94768, true)
  need(94968, "Eye of Mugg", 45, 40, nil, true)
  need(94972, "Tome of Twilight", 44, 39, nil, true)
  need(94975, "A Token of Vengeance", 42, 38, nil, true)

  local function ringFight(id, foe, level, text)
    return note(targets(objective(id, ring, text, foe), foe),
      "Ring fight (level " .. level .. "); the quest is flagged elite. Check whether it is a solo fight.")
  end

  alternate("riverglades-bolderok", "Riverglades: Bolder'ok and the Twilight's Shroud", M.riverglades, 41, 46, zoneSources,
    { "riverglades-eastsea" }, {
    taxi("fly", p.flight, ROGMAR, "Fly to Rog'mar. If you have never been there, follow the way in from the Rog'mar guide."),
    accept(94672, p.trangul, "Tran'gul keeps watch on the Twilight's Hammer at Sunnyglade."), accept(94680, p.trangul),
    accept(95992, rg("WANTED!", 59.5, 47.0), "Read the wanted poster at the south end of camp: Ghostmaw, a white crocolisk."),
    accept(95882, rg("Wanted", 59.6, 47.0), "The second poster names Scoutmaster Vargas, an Alliance scout."),
    action("goto", fuzzle, "Ride west toward Sunnyglade. Fuzzle, a gnoll, hides in the brush on the way."),
    accept(94961, fuzzle, "Fuzzle pays for Twilight finger bones."),
    action("goto", camp, "Go on west to the Twilight's Hammer camp below the ogre fortress."),
    along(targets(objective(94672, camp, "Kill Twilight Raiders and Neophytes around the camp.", "8 Twilight Raiders", "8 Twilight Neophytes"),
      "Twilight Raider", "Twilight Neophyte"), 94680, 94961),
    along(targets(objective(94680, rg(nil, 43.3, 49.9), "Kill Twilight Shadowmancers southeast of the camp for their missives.",
      "3 Twilight Missives"), "Twilight Shadowmancer"), 94961),
    along(note(objective(94961, rg(nil, 42.0, 47.5), "Loot finger bones from the Twilight cultists as you go.", "20 Twilight Finger Bones"),
      "Drop sources are not published; any Twilight's Hammer member is the guess."), 94672, 94680),
    finish(94961, fuzzle), accept(94963, fuzzle),
    objective(94963, stash, "Follow Fuzzle to its hidden stash and fight off anything that attacks you on the way.", "Fuzzle's Treasure"),
    finish(94963, stash, "Open Fuzzle's treasure."),
    action("goto", rg(nil, 41.2, 64.0), "Ride south to the river by Turner's Logging Camp."),
    note(targets(objective(95992, rg("Ghostmaw", 41.2, 65.9), "Ghostmaw, an elite white crocolisk, swims the river here. "
      .. "Kill it for its fang.", "Ghostmaw's Fang"), "Ghostmaw"), "Elite, level 42. It patrols the river, so the spot is a guess."),
    action("goto", p.trangul, "Ride back to Rog'mar."),
    finish(94672, p.trangul), finish(94680, p.trangul), accept(94727, p.trangul),
    finish(95992, p.tanjani, "Give Tan'jani the fang: the poster was his."),
    action("goto", clubtoe, "Ride west to Sunnyglade and find Clubtoe, an ogre who digs for the cult."),
    finish(94727, clubtoe, "Get Clubtoe talking about what the cult digs for."),
    accept(95602, clubtoe), accept(95417, clubtoe),
    finish(95417, rg("Twilight Brute", 49.2, 46.7), "Look at the dead ogre just west of Clubtoe."),
    accept(95601, rg("Twilight Brute", 49.2, 46.7)),
    along(targets(objective(95601, caves, "Go down into the caves under Sunnyglade. Kill the Empowered Brutes and Twilight Ritualists.",
      "5 Empowered Brutes", "10 Twilight Ritualists"), "Empowered Brute", "Twilight Ritualist"), 95602),
    along(note(objective(95602, caves, "Destroy the glowing ritual circles in the same caves.", "5 Twilight Ritual Circles"),
      "Circle spots inside the caves are not published."), 95601),
    finish(95601, clubtoe), finish(95602, clubtoe), accept(95427, clubtoe),
    note(targets(objective(95427, rg("Chogg'Zac", 45.4, 51.2), "Chogg'Zac, a two-headed ogre, waits deep in the caves. "
      .. "Bring a group and take both heads.", "Chogg's Head", "Zac's Head"), "Chogg'Zac"), "Elite quest; group size not known."),
    finish(95427, clubtoe), accept(95418, clubtoe),
    action("goto", p.trangul, "Ride back to Rog'mar."),
    finish(95418, p.trangul), accept(95420, p.trangul),
    action("goto", p.clugfist, "Ride north into the hills to Bolder'ok, the town of the free ogres."),
    finish(95420, p.clugfist, "Offer the head to Clugfist, the ogre chief."),
    accept(95424, p.clugfist), accept(95425, p.clugfist), accept(94668, p.clugfist),
    finish(94668, jezap, "Jezap Jinglesprocket runs the Bloodmaster's Ring just south of Clugfist."), accept(94669, jezap),
    note(objective(94669, jezap, "Pay Jezap the safety deposit.", "Safety deposit paid"), "The fee is not published."),
    finish(94669, jezap), accept(94670, jezap),
    ringFight(94670, "Buzzbeak", 41, "Step into the ring and beat Buzzbeak."),
    finish(94670, jezap), accept(94739, jezap),
    ringFight(94739, "Kronk", 42, "Back into the ring: Kronk is next."),
    finish(94739, jezap), accept(94962, jezap),
    ringFight(94962, "Bonegnaw", 42, "Your third fight is Bonegnaw."),
    finish(94962, jezap),
    accept(95183, gorgegut, "Gorgegut, east of the ring, wants good rocks for Hamur's weapons."),
    accept(94556, jomjom, "Jom-jom, east of Gorgegut, wants to go home to Clugfist."),
    note(objective(94556, jomjom, "Keep Jom-jom alive on the walk back to Clugfist.", "Escort Jom-jom"),
      "Escort path not published. If it starts at once, do the next steps after it."),
    finish(94556, p.clugfist),
    along(note(objective(95183, rg(nil, 70.0, 27.0), "Pick up good rocks by the river outside Bolder'ok.", "10 Good Rocks"),
      "Rock spots are not published; the quest says the river near Bolder'ok."), 95424),
    along(targets(part(95424, 1, rg(nil, 67.6, 30.2), "Kill Twilight Maulers in the camp south of Bolder'ok.", "7 Twilight Maulers"),
      "Twilight Mauler"), 95183),
    along(targets(part(95424, 2, rg(nil, 74.1, 29.2), "Kill Twilight Firecallers farther east, toward the water.", "7 Twilight Firecallers"),
      "Twilight Firecaller"), 95425),
    note(targets(objective(95425, rg("Klunk", 74.8, 27.1), "Klunk took Clugfist's weapon to a cave by the water. Kill him and take it back.",
      "Skullbasher"), "Klunk"), "One source calls the weapon Skullthumper, another Skullbasher."),
    note(targets(objective(95882, rg("Scoutmaster Vargas", 73.4, 34.2), "Swim to the small island south of here. Scoutmaster Vargas "
      .. "camps there with his pet. Kill him for his eye.", "Scoutmaster's Eye"), "Scoutmaster Vargas"),
      "Elite quest (level 43); his pet fights with him."),
    action("goto", p.clugfist, "Go back to Bolder'ok."),
    finish(95424, p.clugfist), finish(95425, p.clugfist), accept(95428, p.clugfist),
    finish(95183, hamur, "Hamur takes the rocks."),
    accept(94964, jezap),
    ringFight(94964, "Mog'thar", 43, "Your fourth fight is Mog'thar."),
    finish(94964, jezap), accept(94733, jezap),
    finish(94733, gobam, "Gobam waits just north of the ring."), accept(94734, gobam),
    note(objective(94734, rg(nil, 67.5, 20.0), "Gather Sweetberry and Riverweed around Bolder'ok.", "8 Sweetberry", "12 Riverweed"),
      "Plant spots are not published; look along the river and the hills by the town."),
    finish(94734, gobam), accept(94737, gobam), finish(94737, jezap),
    action("goto", p.kromrosh, "Ride south to Rog'mar."),
    finish(95428, p.kromrosh), accept(94744, p.kromrosh),
    finish(95882, p.neza, "Give Neza the scoutmaster's eye."),
    action("goto", p.dagrosh, "Ride west past Sunnyglade to the hills east of the Twilight's Shroud and find Da'grosh."),
    finish(94744, p.dagrosh),
    accept(94745, p.dagrosh), accept(94748, p.dagrosh), accept(95431, p.dagrosh),
    finish(95431, cragrog, "Crag'rog, a Bolder'ok ogre, hides in the cave just west."), accept(95432, cragrog),
    note(targets(objective(95432, rg(nil, 26.5, 33.9), "Win over the Ogre Miners at the dig north of the cave. Their Twilight "
      .. "Subjugators fight back.", "5 Ogre Miners recruited"), "Twilight Subjugator", "Ogre Miner"),
      "How the miners are recruited (talking, or freeing them) is not published."),
    finish(95432, cragrog), accept(95433, cragrog),
    along(targets(objective(94745, shroud, "Fight into the Twilight's Shroud. Kill Twilight Fanatics, Corrupters and Champions.",
      "8 Twilight Fanatics", "8 Twilight Corrupters", "8 Twilight Champions"), "Twilight Fanatic", "Twilight Corrupter", "Twilight Champion"),
      94748, 95433),
    along(note(objective(94748, rg(nil, 26.1, 44.7), "Free the captured Rog'mar Scouts held in the fortress.", "5 Rog'mar Scouts rescued"),
      "How the scouts are freed is not published."), 94745),
    note(targets(objective(95433, rg("Executioner Morg", 28.3, 41.1), "Executioner Morg, a huge ogre, guards the Shroud. Bring a group, "
      .. "kill him and take his mace.", "Executioner's Mace"), "Executioner Morg"), "Elite, level 46."),
    finish(94745, p.dagrosh), finish(94748, p.dagrosh), accept(94768, p.dagrosh),
    note(targets(objective(94768, rg("Overlord Kilgar", 26.3, 44.2), "Overlord Kilgar commands the stronghold inside the Shroud. "
      .. "Bring a group, kill him and take his head.", "Kilgar's Head"), "Overlord Kilgar"), "Elite quest (level 46)."),
    finish(94768, p.dagrosh), accept(95278, p.dagrosh),
    dungeon("krol-dok-stronghold", accept(94975, p.dagrosh, "Da'grosh also wants ears from the cultists inside Krol'dok Stronghold, "
      .. "the cave north of here.")),
    action("hearth", p.toka, "Hearth to Rog'mar.", rogmarInn),
    finish(95278, p.kromrosh),
    dungeon("krol-dok-stronghold", accept(94968, p.kromrosh, "Krom'rosh wants Overseer Mugg of Krol'dok dead.")),
    dungeon("krol-dok-stronghold", accept(94972, p.trangul, "Tran'gul wants the Tome of Twilight from the stronghold.")),
    action("goto", p.clugfist, "Ride north to Bolder'ok."),
    finish(95433, p.clugfist, "Give Clugfist the executioner's mace."),
    accept(94965, jezap),
    ringFight(94965, "Snufflesnout", 44, "Back to the ring: Snufflesnout."),
    finish(94965, jezap), accept(95063, jezap),
    ringFight(95063, "Chub'chob", 45, "The last fight: Chub'chob, the Bloodmaster of Bolder'ok."),
    finish(95063, p.clugfist, "Tell Clugfist you are the new champion of the ring."),
  })
end

-- Alternate, 41-45: Powderfuse Port's errands, the murloc shore, Argo's sea monster and the Eastsea pirates.
do
  local p = place
  local fimbo = rg("Fimbo Greasemitz", 79.0, 54.2)
  local argo = rg("Argo Brinewhistle", 80.0, 52.5)
  local poster = rg("WANTED!", 78.5, 53.9)
  local hide = rg("Painted Hide", 72.3, 61.9)
  local bentcoin = rg("Captain Bentcoin", 91.3, 39.7)
  local haynes = rg("Captain Haynes", 91.2, 39.8)
  local murlocs = rg(nil, 72.4, 69.5)
  local islands = rg(nil, 73.6, 73.5)
  local crew = rg(nil, 82.0, 43.8)
  local raiders = rg(nil, 76.0, 32.0)

  need(95118, "Saltwater Savages", 41, 36, nil, true)
  need(95121, "A Taste of the Sea", 40, 36, nil, true)
  need(95254, "WANTED: Trapclaw", 42, 36, nil, true)
  need(95120, "WANTED: Old Rot-Chum", 42, 36, nil, true)
  need(95260, "Terrors From the Deep", 42, 38, nil, true)
  need(95261, "It Takes Guts", 42, 38, 95260, true)
  need(95267, "The Monster Surfaces", 42, 38, 95261, true)
  need(95119, "Unfriendly Competition", 43, 38, nil, true)
  need(95122, "Unchecked Expansion", 44, 38, nil, true)
  need(95123, "A Blast Ye Scurvy Dogs!", 44, 38, nil, true)
  need(95165, "See Ya, Scallywags!", 44, 38, nil, true)
  need(95124, "Admiral Lamora", 45, 38, nil, true)
  need(95288, "Smuggler's Paradise", 43, 38, nil, true)
  need(95293, "Smuggler's Special", 42, 38, 95288, true)
  need(95294, "Smuggler's Bargain", 42, 38, 95293, true)

  alternate("riverglades-eastsea", "Riverglades: Powderfuse Port and the Eastsea Pirates", M.riverglades, 41, 45, {
    "https://bindonforever.com/zones/riverglades",
    "https://www.foreverdb.app/en/forever/zones/riverglades/quests",
    "https://warcraft.wiki.gg/wiki/Powderfuse_Port",
    "https://www.method.gg/wow-forever/all-travel-routes-in-wow-forever-boats-zeppelins",
  }, { "riverglades-bolderok", "shendralas-pylons" }, {
    action("goto", p.friz, "Travel to Powderfuse Port: take the barge from Steamwheedle Port in Tanaris, or fly to Rog'mar and ride east "
      .. "along the road."),
    accept(95288, p.friz, "Friz Frazzlespark wants her smuggled goods back from the Eastsea pirates."),
    note(taxi("getfp", p.portFlight, PORT, "Learn the Powderfuse Port flight path if a flight master is there."),
      "The client lists a Horde flight point here with no routes yet."),
    accept(95118, p.whizzbuzz, "Wharfmaster Whizzbuzz runs the docks. He wants the murlocs and the pirates gone."),
    accept(95119, p.whizzbuzz),
    accept(95121, fimbo, "Fimbo Greasemitz wants seafood for a new stew."),
    accept(95254, poster, "Read the wanted posters by the inn."), note(accept(95120, poster), "Old Rot-Chum is elite (level 42)."),
    targets(objective(95254, rg("Trapclaw", 79.5, 52.5), "Trapclaw, a huge crab, walks under the docks. Kill it for its pincer.",
      "Trapclaw's Pincer"), "Trapclaw"),
    finish(95254, fimbo),
    accept(95260, hide, "Ride south along the shore. Look at the painted hide lying on the beach."),
    action("goto", murlocs, "Go on south to the murloc camps along the Eastwind Shore."),
    along(targets(objective(95118, murlocs, "Kill Murloc Oracles and Warriors along the shore.", "8 Murloc Oracles", "8 Murloc Warriors"),
      "Murloc Oracle", "Murloc Warrior"), 95121),
    along(note(targets(objective(95121, rg(nil, 74.2, 67.2), "Loot eyes from the murlocs and meat from the Sand Crawlers on the beach.",
      "12 Saltwater Murloc Eyes", "6 Sand Crawler Meat"), "Sand Crawler", "Murloc Oracle", "Murloc Warrior"),
      "Sand Crawler spots on this beach need an in-game check."), 95118),
    note(targets(objective(95120, rg("Old Rot-Chum", 74.3, 73.4), "Old Rot-Chum swims among the murloc islands to the south. "
      .. "Kill it and take its harpoon as proof.", "Rot-Covered Harpoon"), "Old Rot-Chum"), "Elite, level 42."),
    action("goto", p.whizzbuzz, "Ride back north to Powderfuse Port."),
    finish(95118, p.whizzbuzz), finish(95120, p.whizzbuzz), finish(95121, fimbo),
    finish(95260, argo, "Argo Brinewhistle, a fisherman on the docks, knows the monster on the hide."), accept(95261, argo),
    action("goto", crew, "Ride north along the coast to the Eastsea crew's camps."),
    along(targets(objective(95119, crew, "Kill Eastsea Buccaneers and Musketeers along the shore.", "10 Eastsea Buccaneers",
      "10 Eastsea Musketeers"), "Eastsea Buccaneer", "Eastsea Musketeer"), 95288, 95261),
    along(note(objective(95288, crew, "Loot Smuggled Goods from the Eastsea pirates.", "8 Smuggled Goods"),
      "Whether the goods drop or lie in crates is not published."), 95119),
    along(note(objective(95261, rg(nil, 78.0, 56.6), "Collect Beast Entrails from beasts along the coast and Rotflesh Mushrooms.",
      "15 Beast Entrails", "8 Rotflesh Mushrooms"), "Which beasts and where the mushrooms grow is not published."), 95119),
    action("goto", p.whizzbuzz, "Go back to Powderfuse Port."),
    finish(95119, p.whizzbuzz), accept(95122, p.whizzbuzz), accept(95123, p.whizzbuzz),
    finish(95288, p.friz), accept(95293, p.friz, "Friz has a special delivery for Captain Bentcoin at Windstead."),
    action("goto", raiders, "Ride north to the pirates who burned Windstead."),
    along(targets(objective(95122, raiders, "Kill Eastsea Raiders and Bombardiers.", "8 Eastsea Raiders", "8 Eastsea Bombardiers"),
      "Eastsea Raider", "Eastsea Bombardier"), 95123),
    along(note(objective(95123, raiders, "Steal Eastsea Powder Kegs from the pirate camp.", "5 Eastsea Powder Kegs"),
      "Keg spots are not published."), 95122),
    action("goto", bentcoin, "Ride east to the ruins of Windstead."),
    finish(95293, bentcoin, "Deliver the Friz Special to Captain Bentcoin."),
    accept(95294, haynes, "Captain Haynes has an offer for Friz."),
    action("goto", p.whizzbuzz, "Ride back to Powderfuse Port."),
    finish(95122, p.whizzbuzz), finish(95123, p.whizzbuzz), accept(95165, p.whizzbuzz), accept(95124, p.whizzbuzz),
    finish(95294, p.friz), finish(95261, argo), accept(95267, argo),
    action("goto", rg(nil, 88.0, 31.0), "Ride north to the Eastsea ships and Admiral Lamora's camp."),
    along(note(objective(95165, rg(nil, 88.0, 31.0), "Board each of the three Eastsea boats and plant a charge near its cannons.",
      "3 Charges Planted"), "Boat positions are not published."), 95124),
    note(targets(objective(95124, rg("Admiral Lamora", 89.2, 30.9), "Kill Admiral Lamora, then find his stash of loot nearby.",
      "Lamora's Loot"), "Admiral Lamora"), "Group size needed is not known."),
    action("goto", p.whizzbuzz, "Ride back to Powderfuse Port."),
    finish(95165, p.whizzbuzz), finish(95124, p.whizzbuzz),
    action("goto", islands, "Ride south to the murloc islands where you found the painted hide."),
    note(withItem("Big Ball o' Bait", targets(objective(95267, rg("Monstrous Threshadon", 72.9, 73.6),
      "Throw the Big Ball o' Bait into the water by the fresh wreckage, then kill the sea monster and take its head.",
      "Sea Monster's Head"), "Monstrous Threshadon")), "Wreckage spot is not published."),
    action("goto", argo, "Ride back to Powderfuse Port."),
    finish(95267, argo),
  })
end

-- Alternate, 41-46: Shen'dralas from Shadowprey Village. The pylon and temple quests are for both
-- factions; the centaur lines need Gelkis or Magram standing from Desolace and are left out.
do
  local sh = on.shendralas
  local mordent = sh("Mordent Evenshade", 35.2, 46.6)
  local biraxas = sh("Historian Biraxas", 46.0, 78.2)
  local kirandis = sh("Magister Kirandis", 47.4, 76.5)
  local liranne = sh("Liranne", 47.5, 65.6)
  local kogthug = sh("Kog'thug the Brave", 72.7, 31.2)
  local pylon = sh("Shen'dralar Pylon", 43.6, 34.3)

  need(92914, "Strange Pylons", 43, 35, nil, true)
  need(96010, "Fragments of the Pylons", 41, 35, 92914, true)
  need(96018, "Powering the Pylons", 43, 35, 96010, true)
  need(93016, "A Brief History Lesson", 43, 35, 96018, true)
  need(93394, "Meeting the Magister", 43, 35, 93016, true)
  need(99257, "A Heart of Crystal", 43, 35, nil, true)
  need(99258, "Mana Mania", 43, 35, 99257, true)
  fromItem(93568, 259461, "Partially Digested Collar", 45, 35)
  fromItem(93574, 259893, "Corpsefeeder's Carapace", 45, 35)
  fromItem(93644, 260347, "Tattered Journal", 45, 35)

  alternate("shendralas-pylons", "Shen'dralas: The Pylons and the Temple", M.shendralas, 41, 46, {
    "https://bindonforever.com/zones/shendralas",
    "https://www.foreverdb.app/en/forever/zones/shen-dralas/quests",
    "https://warcraft.wiki.gg/wiki/Shen'dralas",
  }, nil, {
    taxi("fly", on.desolace(nil, 21.6, 74.0), "Shadowprey Village, Desolace", "Fly to Shadowprey Village in Desolace."),
    note(action("goto", on.desolace(nil, 58.6, 88.8), "Ride east across southern Desolace to the Valley of Bones, then south "
      .. "into Shen'dralas."), "The road south from the Valley of Bones is from zone notes; check it in game."),
    accept(92914, pylon, "Examine the strange pylon in the Valley of Bones once its mana elementals are dead."),
    finish(92914, mordent, "Mordent Evenshade camps at Evenshade's Overlook, northwest of the temple."), accept(96010, mordent),
    note(accept(99257, biraxas, "Historian Biraxas works inside the temple. He wants a crystal heart from a pylon guard."),
      "His text mentions an earlier errand; check that he offers this on your first visit."),
    note(targets(objective(99257, sh(nil, 43.3, 32.7), "Kill Decrepit Pylon Protectors around the northern pylons until a "
      .. "crystal heart drops.", "Depleted Crystal Heart"), "Decrepit Pylon Protector"), "Protector spots need an in-game check."),
    note(objective(96010, sh(nil, 33.0, 26.0), "Recover the pylon fragment and shard. The centaur camps that trespass in "
      .. "Shen'dralas guard them.", "Pylon Fragment", "Pylon Shard"), "Fragment and shard positions need an in-game check."),
    withItem(259893, accept(93574, nil, "If Corpsefeeder dropped its carapace, read it.")),
    finish(93574, kogthug, "Kog'thug the Brave, a quilboar chief at Bristleback Retreat, wants the carapace."),
    withItem(260347, accept(93644, nil, "If an outcast necromancer dropped a tattered journal, read it.")),
    finish(96010, mordent), finish(93644, mordent), accept(96018, mordent),
    finish(99257, biraxas), accept(99258, biraxas),
    note(objective(96018, sh(nil, 47.0, 74.0), "Borrow the Mana Sieve inside the temple, collect mana from the floating sparks, "
      .. "then empower the pylons.", "Ancient Mana Crystals", "Pylons empowered"), "Spark and pylon positions need an in-game check."),
    note(objective(99258, sh(nil, 37.6, 52.8), "Throw the crystal heart into an Unstable Mana Rift.", "Rift fed"),
      "Rift position needs an in-game check."),
    withItem(259461, accept(93568, nil, "If a prowler coughed up a partially digested collar, read it.")),
    finish(93568, liranne, "Liranne waits in the gardens north of the temple."),
    finish(99258, biraxas),
    finish(96018, mordent), accept(93016, mordent),
    finish(93016, mordent, "Listen to Mordent's story of the crystals."),
    accept(93394, mordent), finish(93394, kirandis, "Magister Kirandis waits deep inside the temple."),
  })
end

-- Krol'dok Stronghold for the Horde: Krom'rosh, Tran'gul and Da'grosh send you in; a moulding that
-- drops inside becomes a key at Kreza Darkthorn's forge.
do
  local name = "Krol'dok Stronghold"
  local p = place

  fromItem(94973, 267137, "Krol'dok Moulding", 41, 38)
  need(94974, "Key Ingredients", 41, 38, 94973, true)

  local steps = {}
  local function add(phase, list)
    for _, step in ipairs(list) do
      step.phase, step.optional, step.dungeon = phase, nil, nil
      steps[#steps + 1] = step
    end
  end
  add("prepare", {
    taxi("fly", p.flight, ROGMAR, "Fly to Rog'mar."),
    accept(94968, p.kromrosh, "Krom'rosh wants proof that Overseer Mugg, the stronghold's leader, is dead."),
    accept(94972, p.trangul, "Tran'gul wants the Tome of Twilight from inside."),
    action("goto", p.dagrosh, "Ride west to Da'grosh's camp east of the Twilight's Shroud."),
    accept(94975, p.dagrosh, "Da'grosh wants ears from the cultists hiding in the stronghold."),
    note(action("dungeon", rg("Krol'dok Stronghold entrance", 37.5, 37.3), "Ride north to the ogre fortress. The gates stay shut: "
      .. "the portal is in a cave west of them, next to the meeting stone.", { name = name }),
      "Entrance from published guides (37.5, 37.3); check it in game."),
  })
  add("inside", {
    objective(94975, nil, "Take ears from the Twilight's Hammer cultists all through the stronghold.", "15 Cultist Ears"),
    note(objective(94972, nil, "Kill Nar'gurk and loot the Tome of Twilight.", "Tome of Twilight"),
      "Which boss carries the tome is from published notes."),
    objective(94968, nil, "Climb to the top and kill Overseer Mugg for his eye.", "Eye of Mugg"),
    note(withItem(267137, accept(94973, nil, "If a Krol'dok Moulding drops for you, use it to start its quest.")),
      "The moulding's drop source is not published."),
  })
  add("after", {
    finish(94975, p.dagrosh, "Leave the dungeon and give Da'grosh the ears."),
    action("goto", p.kromrosh, "Ride east to Rog'mar."),
    finish(94968, p.kromrosh), finish(94972, p.trangul),
    finish(94973, p.kreza, "Show the moulding to Kreza Darkthorn at the forge."),
    note(accept(94974, p.kreza, "She can cast a key from it if you bring 4 Thick Leather and 12 Iron Bars."),
      "One source swaps the counts (12 leather, 4 bars); check the quest log."),
    finish(94974, p.kreza, "Hand over the leather and bars for the Krol'dok Compound Key."),
  })

  route.sections[#route.sections + 1] = {
    id = "dungeon-krol-dok-stronghold", title = name, zone = M.riverglades, levels = { 40, 45 },
    instanceID = 3039, instance = name, side = true, category = "dungeon", verified = false,
    bosses = {
      { name = "Slavecrusher Grox", encounter = 3450,
        tip = "Clear the ogre packs on the way slowly and wait for the long patrol to pass. Pull him away from the slave pens." },
      { name = "Twilight Commander Zarmok", encounter = 3452,
        tip = "His bleed stacks on the tank, so keep the tank's health high. The big gate behind him opens when he dies." },
      { name = "Handler Ashka", encounter = 3453,
        tip = "Two wolves fight with her. Kill or crowd control the wolves first, then her." },
      { name = "Nar'gurk", encounter = 3449,
        tip = "He mind controls a player. Crowd control the charmed player instead of killing them, and stay near cover." },
      { name = "Overseer Mugg", encounter = 3451,
        tip = "He leaps around the room, so spread out. Kill his adds first: they weaken the healing on the tank." },
    },
    sources = {
      "https://www.foreverdb.app/en/forever/dungeons-raids/krol-dok-stronghold/quests",
      "https://bindonforever.com/dungeons/kroldok-stronghold",
      "https://www.warcrafttavern.com/forever/guides/kroldok-stronghold/",
      "https://bindonforever.com/quest/94968",
      "https://bindonforever.com/quest/94972",
      "https://bindonforever.com/quest/94975",
      "https://bindonforever.com/quest/94973",
      "https://bindonforever.com/quest/94974",
    },
    steps = steps,
  }
end
