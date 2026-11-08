-- Hand-authored route. Source notes: tools/audits/2026-11-08-quests.md.
local elwynn, stormwind, westfall, redridge = 1429, 1453, 1436, 1433
local function at(name, x, y, map)
  return { name = name, x = x, y = y, map = map or elwynn }
end

local mcbride = at("Marshal McBride", 48.92, 41.61)
local willem = at("Deputy Willem", 48.17, 42.94)
local eagan = at("Eagan Peltskinner", 48.94, 40.16)
local paxton = at("Brother Paxton", 49.61, 40.41)
local daniel = at("Daniel", 49.48, 40.67)
local kelsey = at("Kelsey Fargo", 47.18, 32.16)
local tordrin = at("Tordrin Sternblade", 51.21, 40.8)
local milly = at("Milly Osworth", 50.69, 39.35)
local sam = at("Sam Sarsaparilla", 44.9, 63.36)
local dughan = at("Marshal Dughan", 42.11, 65.93)
local farley = at("Innkeeper Farley", 43.77, 65.8)
local pestle = at("William Pestle", 43.32, 65.7)
local remy = at("Remy Two Times", 42.14, 67.26)
local billy = at("Billy Maclure", 43.13, 85.72)
local bernice = at("Auntie Bernice Stonefield", 34.49, 84.25)
local maybell = at("Maybell Maclure", 43.15, 89.62)
local tommy = at("Tommy Joe Stonefield", 29.84, 86)
local gramma = at("Gramma Stonefield", 34.94, 83.86)
local ma = at("Ma Stonefield", 34.66, 84.48)
local jason = at("Jason Mathers", 47.46, 62.18)
local lee = at("Lee Brown", 47.61, 62.32)
local thomas = at("Guard Thomas", 73.97, 72.18)
local body = at("A half-eaten body", 72.66, 60.34)
local rolf = at("Rolf's corpse", 79.8, 55.5)
local ormin = at("Ormin Pelford", 76.54, 71.91)
local rainer = at("Deputy Rainer", 24.23, 74.45)
local fargodeep = at(nil, 40.5, 80.7)
local jasperlode = at(nil, 61.5, 50)
local abbeyTrainers = {
  { "WARRIOR", at("Llane Beshere", 50.24, 42.29) },
  { "PALADIN", at("Brother Sammuel", 50.43, 42.12) },
  { "HUNTER", tordrin },
  { "ROGUE", at("Jorik Kerridan", 50.31, 39.92) },
  { "PRIEST", at("Priestess Anetta", 49.81, 39.49) },
  { "MAGE", at("Khelden Bremen", 49.66, 39.4) },
  { "WARLOCK", at("Drusilla La Salle", 49.87, 42.65) },
}
local goldshireTrainers = {
  { "WARRIOR", at("Lyria Du Lac", 41.1, 65.8) },
  { "PALADIN", at("Brother Wilhelm", 41.1, 66.0) },
  { "HUNTER", at("Josephine Carson", 41.1, 66.2) },
  { "ROGUE", at("Keryn Sylvius", 43.9, 65.9) },
  { "PRIEST", at("Priestess Josetta", 43.4, 65.6) },
  { "MAGE", at("Zaldimar Wefhellt", 43.2, 66.2) },
  { "WARLOCK", at("Maximillian Crowe", 44.4, 66.2) },
}

local quest = {}
local function q(id, name, level, min, prerequisite, forever, class)
  quest[id] = { quest = id, name = name, level = level, min = min,
    chain = type(prerequisite) == "table" and prerequisite or prerequisite and { prerequisite },
    forever = forever, class = class }
end

q(783, "A Threat Within", 1, 1)
q(7, "Kobold Camp Cleanup", 2, 1, 783)
q(5261, "Eagan Peltskinner", 2, 1, 783)
q(33, "Wolves Across the Border", 2, 1, 5261)
q(15, "Investigate Echo Ridge", 3, 1, 7)
q(18, "Brotherhood of Thieves", 4, 2, 783)
q(6, "Bounty on Garrick Padfoot", 5, 2, 18)
q(21, "Skirmish at Echo Ridge", 5, 1, 15)
q(3903, "Milly Osworth", 4, 2, 18)
q(3904, "Milly's Harvest", 4, 2, 3903)
q(3905, "Grape Manifest", 4, 2, 3904)
q(54, "Report to Goldshire", 5, 1, 21)
q(2158, "Rest and Relaxation", 5, 1)
q(91741, "Nibbled-On Book", 2, 1, nil, true)
q(92124, "Book Inventory", 2, 1, 91741, true)
q(91743, "Rascally Rodents", 2, 1, 92124, true)
q(91745, "Mining Consultant", 3, 1, 91743, true)
q(91752, "The Big Picture", 3, 1, 91745, true)
q(91758, "Follow That Kobold!", 4, 1, 91752, true)
q(91772, "Shhh! We're Hunting Kobolds", 4, 1, 91758, true)
q(96627, "The Adventurer", 6, 4, 21, true)
q(95998, "The Great Outdoors", 6, 4, 96627, true)
q(96626, "Camping 101: Cooking", 6, 4, 95998, true)
q(91775, "Book Return", 6, 1, 91772, true)
q(91777, "Rare Books", 7, 1, 91775, true)
q(99127, "A Net Disaster", 7, 4, nil, true)
q(99128, "Slimy Menace", 7, 4, 99127, true)
q(99129, "A Man About a Murloc", 7, 4, 99128, true)
q(99143, "Bottles and Baubles", 7, 4, nil, true)
q(91733, "Downstream", 10, 7, nil, true)
q(47, "Gold Dust Exchange", 7, 4)
q(60, "Kobold Candles", 7, 3)
q(62, "The Fargodeep Mine", 7, 4)
q(76, "The Jasperlode Mine", 10, 4, 62)
q(61, "Shipment to Stormwind", 7, 3, 60)
q(85, "Lost Necklace", 6, 5)
q(86, "Pie for Billy", 6, 5, 85)
q(84, "Back to Billy", 6, 5, 86)
q(87, "Goldtooth", 8, 5, 84)
q(106, "Young Lovers", 6, 5)
q(111, "Speak with Gramma", 6, 5, 106)
q(107, "Note to William", 6, 5, 111)
q(112, "Collecting Kelp", 7, 5, 107)
q(114, "The Escape", 7, 5, 112)
q(88, "Princess Must Die!", 9, 6)
q(40, "A Fishy Peril", 10, 7)
q(35, "Further Concerns", 10, 7, 40)
q(37, "Find the Lost Guards", 10, 7, 35)
q(45, "Discover Rolf's Fate", 10, 7, 37)
q(71, "Report to Thomas", 10, 7, 45)
q(39, "Deliver Thomas' Report", 10, 7, 71)
q(52, "Protect the Frontier", 10, 7)
q(5545, "A Bundle of Trouble", 9, 5)
q(83, "Red Linen Goods", 9, 4)
q(239, "Westbrook Garrison Needs Help!", 10, 6, 76)
q(11, "Riverpaw Gnoll Bounty", 10, 6, 239)
q(176, 'WANTED: "Hogger"', 11, 5)
q(109, "Report to Gryan Stoutmantle", 10, 9)
q(92479, "A Scribbled Letter", 1, 1, 7, true, "HUNTER")
q(3100, "Simple Letter", 1, 1, 7, nil, "WARRIOR")
q(3101, "Consecrated Letter", 1, 1, 7, nil, "PALADIN")
q(3102, "Encrypted Letter", 1, 1, 7, nil, "ROGUE")
q(3103, "Hallowed Letter", 1, 1, 7, nil, "PRIEST")
q(3104, "Glyphic Letter", 1, 1, 7, nil, "MAGE")
q(3105, "Tainted Letter", 1, 1, 7, nil, "WARLOCK")

local function action(kind, place, text, extra)
  local step = { type = kind, text = text }
  if place then step.npc, step.map, step.x, step.y = place.name, place.map, place.x, place.y end
  for k, v in pairs(extra or {}) do step[k] = v end
  return step
end

local function questAction(kind, id, place, text)
  return action(kind, place, text, quest[id])
end

local function accept(id, npc, text)
  return questAction("accept", id, npc, text or ("Accept from " .. npc.name .. "."))
end

local function finish(id, npc, text)
  return questAction("turnin", id, npc, text or ("Turn in to " .. npc.name .. "."))
end

local function objective(id, x, y, text, ...)
  local step = questAction("complete", id, at(nil, x, y), text)
  step.objectives = { ... }
  return step
end

local function withTrainers(steps, trainers)
  local result = {}
  for _, step in ipairs(steps) do
    if step.type == "train" then
      for _, trainer in ipairs(trainers) do
        local class, place = trainer[1], trainer[2]
        result[#result + 1] = action("train", place, "Visit " .. place.name .. " to train for level",
          { class = class, level = step.level, min = step.level })
      end
    else
      result[#result + 1] = step
    end
  end
  return result
end

local northshire = {
  accept(783, willem), finish(783, mcbride, "Find Marshal McBride inside the abbey."),
  accept(7, mcbride),
  accept(5261, willem), finish(5261, eagan, "Go around the abbey to Eagan on the north side."),
  accept(33, eagan),
  objective(7, 48.8, 36.4, "Clear the camp north of the abbey. Loot the kobolds for a Nibbled-On Book.", "10 Kobold Vermin"),
  objective(33, 49.7, 39.1, "Loot meat from the wolves around the abbey.", "8 Tough Wolf Meat"),
  finish(33, eagan), finish(7, mcbride),
  accept(15, mcbride),
  accept(91741, at(nil, 48.8, 36.4), "Use the Nibbled-On Book from your bags. If it has not dropped, loot more Kobold Vermin."),
  finish(91741, paxton, "Bring the chewed book to Brother Paxton in the library."),
  accept(92124, paxton), finish(92124, daniel), accept(91743, paxton),
  accept(92479, mcbride), finish(92479, tordrin, "Read the letter and speak to Tordrin near the stable."),
  accept(3100, mcbride), finish(3100, at("Llane Beshere", 50.24, 42.29)),
  accept(3101, mcbride), finish(3101, at("Brother Sammuel", 50.43, 42.12)),
  accept(3102, mcbride), finish(3102, at("Jorik Kerridan", 50.31, 39.92)),
  accept(3103, mcbride), finish(3103, at("Priestess Anetta", 49.81, 39.49)),
  accept(3104, mcbride), finish(3104, at("Khelden Bremen", 49.66, 39.4)),
  accept(3105, mcbride), finish(3105, at("Drusilla La Salle", 49.87, 42.65)),
  action("train", nil, "Visit your class trainer around the abbey. Train spells for level", { level = 2 }),
  accept(18, willem),
  objective(15, 49, 35.7, "Kill Workers around the approach to Echo Ridge Mine. Loot books while you fight.", "10 Kobold Workers"),
  objective(91743, 48.3, 34, "Finish collecting Stolen Books from the Workers and Vermin.", "8 Stolen Books"),
  finish(15, mcbride), accept(21, mcbride),
  finish(91743, paxton), accept(91745, paxton),
  finish(91745, kelsey, "Speak to Kelsey outside the mouth of Echo Ridge Mine."),
  accept(91752, kelsey),
  objective(21, 48.4, 29, "Enter Echo Ridge Mine and clear the Laborers.", "12 Kobold Laborers"),
  objective(91752, 49, 28, "Loot the sack from Shinyfinder Narf inside the mine. Group up if needed.", 'Sack of "Picture" Books'),
  objective(18, 53.1, 44.8, "Work the vineyard from its edges and loot the Defias Thugs.", "12 Red Burlap Bandanas"),
  finish(18, willem), accept(6, willem), accept(3903, willem),
  finish(3903, milly), accept(3904, milly),
  objective(3904, 54.5, 48.5, "Pick up grape crates among the vineyard rows.", "8 crates of Milly's Harvest"),
  objective(6, 57.4, 48.3, "Kill Garrick by the shack east of the vineyard and loot his head.", "Garrick's Head"),
  finish(6, willem), finish(3904, milly), accept(3905, milly),
  finish(3905, at("Brother Neals", 49.47, 41.59), "Take the manifest upstairs in the abbey."),
  finish(21, mcbride), finish(91752, mcbride), accept(91758, mcbride),
  accept(54, mcbride), accept(96627, mcbride),
  finish(91758, tordrin), accept(91772, tordrin),
}

local forest = {
  accept(2158, at("Falkhaan Isenstrider", 45.56, 47.74)),
  objective(91772, 45.6, 55.3, "Use the Kobold Tracking Kit from your bags. Follow the tracks from the stables toward Goldshire.", "6 Kobold Tracks"),
  finish(96627, sam), accept(95998, sam),
  objective(95998, 45, 63, "Sit by Sam's fire until you get Boosted Rest.", "Boosted Rest"),
  finish(95998, sam), accept(96626, sam),
  finish(2158, farley),
  action("sethearth", farley, "Bind your hearthstone at the Lion's Pride Inn."),
  finish(96626, at("Tomas", 44.37, 65.99), "Speak to Tomas in the inn about Cooking."),
  finish(54, dughan), finish(91772, dughan), accept(91775, dughan),
  accept(62, dughan), accept(60, pestle), accept(47, remy),
  action("train", nil, "Visit your Goldshire class trainer. Train spells for level", { level = 6 }),
  action("goto", at(nil, 35.8, 80.3), "Follow the road south and cut southwest toward Stonefield Farm. Loot boars on the way."),
  accept(85, bernice),
  finish(85, billy), accept(86, billy), accept(106, maybell),
  objective(86, 40, 86, "Loot Stonetusk Boars between the farms if you need more meat.", "4 Chunks of Boar Meat"),
  finish(106, tommy), accept(111, tommy), finish(111, gramma), accept(107, gramma),
  finish(86, bernice), accept(84, bernice), accept(88, ma),
  finish(84, billy), accept(87, billy),
  objective(62, 40.6, 80.9, "Explore Fargodeep Mine until you get credit. Loot every kobold for dust and candles.", "Explore Fargodeep Mine"),
  objective(87, 41.4, 80.8, "Find Goldtooth in the mine and take the necklace.", "Bernice's Necklace"),
  objective(91775, 40.8, 80.8, "Collect the Lost Books and loot Fun with Elementals from Nimsy. Bring help for Nimsy.", "6 Lost Books", "Fun with Elementals"),
  objective(47, fargodeep.x, fargodeep.y, "Finish collecting gold dust from the kobolds.", "10 Gold Dust"),
  objective(60, fargodeep.x, fargodeep.y, "Loot kobolds for any Large Candles you still need.", "8 Large Candles"),
  finish(87, bernice),
  action("hearth", farley, "Hearth to Goldshire, or take the road north if your hearthstone is on cooldown."),
  finish(62, dughan), accept(76, dughan), finish(91775, dughan), accept(91777, dughan),
  finish(47, remy), accept(40, remy), finish(40, dughan), accept(35, dughan),
  finish(60, pestle), accept(61, pestle), finish(107, pestle), accept(112, pestle),
  action("train", nil, "Train spells for level", { level = 8 }),
  accept(99127, jason), accept(99143, lee),
  objective(99127, 47.9, 62.6, "Search the fishing traps in the shallows for a Half-Eaten Fish.", "Half-Eaten Fish"),
  finish(99127, jason), accept(99128, jason),
  objective(99128, 53.6, 65.4, "Pull murlocs near Crystal Lake a few at a time. Loot kelp and search for junk as you go.", "7 Murlocs", "4 Murloc Streamrunners"),
  objective(112, 55.1, 65.6, "Collect the rest of the kelp from the murlocs by the lake.", "4 Crystal Kelp Fronds"),
  objective(99143, 52.9, 65, "Search the murloc camp for its shiny junk.", "6 pieces of shiny junk"),
  finish(99128, jason), accept(99129, jason), finish(99143, lee),
  action("goto", at(nil, 60.5, 50), "Approach Jasperlode Mine from the south."),
  objective(76, jasperlode.x, jasperlode.y, "Follow the middle tunnel until you get exploration credit.", "Explore Jasperlode Mine"),
  objective(91777, jasperlode.x, jasperlode.y, "With help, loot Geomancy from Geosculptor Yip and Arcane Explainer from Mother Fang.", "Geomancy for Curious Young Wizards", "Arcane Explainer: Magical Stuff in Simple Words"),
  finish(35, thomas), accept(37, thomas), accept(52, thomas),
  finish(37, body, "Search the bank north of the bridge for the half-eaten body."), accept(45, body),
  finish(45, rolf, "Find Rolf's corpse in the murloc camp east of the river."), accept(71, rolf),
  accept(5545, at("Supervisor Raelen", 81.38, 66.11)),
  accept(83, at("Sara Timberlain", 79.46, 68.79)),
  objective(5545, 81.7, 62.4, "Gather fallen wood around Eastvale Logging Camp.", "8 Bundles of Wood"),
  objective(52, 81, 69, "Kill the wolves and bears around Eastvale while gathering wood.", "8 Prowlers", "5 Young Forest Bears"),
  finish(5545, at("Supervisor Raelen", 81.38, 66.11)),
  finish(52, thomas), finish(71, thomas), accept(39, thomas), accept(91733, ormin),
  objective(91733, 74.3, 76.4, "Search the riverbanks south of the bridge for Ormin's tools.", "Waterlogged Axe", "Waterlogged Saw", "Waterlogged Toolbox"),
  finish(91733, ormin),
  objective(83, 70.9, 80.1, "Loot Defias Bandits at Brackwell Pumpkin Patch.", "6 Red Linen Bandanas"),
  objective(88, 69.8, 79.4, "Clear Princess's guards before taking her collar.", "Brass Collar"),
  finish(83, at("Sara Timberlain", 79.46, 68.79)),
  action("hearth", farley, "Hearth to Goldshire for the next turn-ins."),
  finish(39, dughan), finish(76, dughan), accept(239, dughan),
  finish(99129, remy), finish(112, pestle), accept(114, pestle),
  action("train", nil, "Visit your class trainer and learn spells for level", { level = 10 }),
  finish(91777, paxton, "Return the two rare books to Paxton before heading on to Stormwind."),
  action("goto", at(nil, 34.7, 51), "Follow the road through the gates into Stormwind."),
  finish(61, at("Morgan Pestle", 63.2, 74.4, stormwind)),
  action("getfp", at("Dungar Longdrink", 71, 72.5, stormwind), "Learn the flight path from Dungar above the Trade District.",
    { flight = "Stormwind, Elwynn" }),
  action("hearth", farley, "Hearth to Goldshire. If it is on cooldown, take the road back through the gates."),
  finish(114, maybell), finish(88, ma),
  finish(239, rainer), accept(11, rainer),
  accept(176, at("Wanted Poster", 24.55, 74.69)),
  objective(11, 26.3, 91.3, "Clear Riverpaw gnolls along Forest's Edge and loot their armbands.", "8 Painted Gnoll Armbands"),
  objective(176, 25.1, 94.1, "Find Hogger near the gnoll camps. Get help if needed and loot his claw.", "Huge Gnoll Claw"),
  finish(11, rainer),
  finish(176, dughan),
  action("grind", at(nil, 26.3, 91.3), "If still under level 12, finish nearby quests or clear Riverpaw gnolls to reach 12.", { level = 12 }),
  action("goto", at(nil, 59.95, 19.36, westfall), "Take the west road across the bridge and follow it to the Furlbrow farm."),
}

-- Shared Alliance route. None of these NPCs require the Human starter chapters.
local function wf(name, x, y) return at(name, x, y, westfall) end
local function rr(name, x, y) return at(name, x, y, redridge) end
local function sw(name, x, y) return at(name, x, y, stormwind) end
local furlbrow = wf("Farmer Furlbrow", 59.95, 19.36)
local verna = wf("Verna Furlbrow", 59.92, 19.42)
local saldean = wf("Farmer Saldean", 56.04, 31.23)
local salma = wf("Salma Saldean", 56.42, 30.52)
local ozwin = wf("Ozwin Ironsprocket", 51.53, 32.31)
local gryan = wf("Gryan Stoutmantle", 56.33, 47.52)
local danuvin = wf("Captain Danuvin", 56.42, 47.62)
local galiaan = wf("Scout Galiaan", 53.98, 52.98)
local lewis = wf("Quartermaster Lewis", 57, 47.17)
local thor = wf("Thor", 56.55, 52.64)
local alba = wf("Alba Fairmoon", 52.48, 52.97)
local exitAlba = wf("Alba Fairmoon", 38.68, 83.7)
local traitor = wf("The Defias Traitor", 55.68, 47.5)
local riell = wf("Scout Riell", 56.67, 47.35)
local dungar = sw("Dungar Longdrink", 70.95, 72.51)
local osric = sw("Osric Strang", 77.17, 60.99)
local shaw = sw("Master Mathias Shaw", 78.31, 70.74)
local sprite = sw("Sprite Jumpsprocket", 61.88, 30.56)
local jasper = sw("Jasper Fel", 80.28, 70.07)
local wilder = sw("Wilder Thistlenettle", 70.31, 40.82)
local shoni = sw("Shoni the Shilent", 62.63, 34.11)
local ariena = rr("Ariena Stormfeather", 25.5, 59.3)
local wiley = rr("Wiley the Black", 21.39, 45.35)
local parker = rr("Guard Parker", 10.18, 71.46)
local feldon = rr("Deputy Feldon", 25.64, 60)
local darcy = rr("Darcy", 21.53, 44.3)
local martie = rr("Martie Jainrose", 16.77, 46.33)
local breanna = rr("Chef Breanna", 17.59, 43.84)
local baren = rr("Dockmaster Baren", 22.63, 47.38)
local solomon = rr("Magistrate Solomon", 24.9, 44.45)
local verner = rr("Verner Osgood", 25.88, 47.27)
local oslow = rr("Foreman Oslow", 27.05, 48.64)
local marris = rr("Marshal Marris", 28.41, 48.97)
local argus = at("Smith Argus", 41.71, 65.54)
local marcus = sw("General Marcus Jonathan", 69.17, 82.72)

q(64, "The Forgotten Heirloom", 12, 9)
q(151, "Poor Old Blanchy", 14, 9)
q(36, "Westfall Stew", 10, 9)
q(38, "Westfall Stew", 13, 9, 36)
q(22, "Goretusk Liver Pie", 12, 9)
q(9, "The Killing Fields", 15, 8)
q(102, "Patrolling Westfall", 14, 8)
q(153, "Red Leather Bandanas", 15, 10)
q(12, "The People's Militia", 12, 9)
q(13, "The People's Militia", 14, 9, 12)
q(14, "The People's Militia", 17, 9, 13)
q(6181, "A Swift Message", 10, 10)
q(6281, "Continue to Stormwind", 10, 10, 6181)
q(6261, "Dungar Longdrink", 10, 10, 6281)
q(6285, "Return to Lewis", 10, 10, 6261)
q(65, "The Defias Brotherhood", 18, 14)
q(132, "The Defias Brotherhood", 18, 14, 65)
q(135, "The Defias Brotherhood", 18, 14, 132)
q(141, "The Defias Brotherhood", 18, 14, 135)
q(142, "The Defias Brotherhood", 18, 14, 141)
q(155, "The Defias Brotherhood", 18, 14, 142)
q(166, "The Defias Brotherhood", 22, 14, 155)
q(214, "Red Silk Bandanas", 17, 14, 155)
q(168, "Collecting Memories", 18, 14)
q(167, "Oh Brother...", 20, 15)
q(2040, "Underground Assault", 20, 15)
q(373, "The Unsent Letter", 22, 16)
q(92742, "Testing the Wells", 12, 9, nil, true)
q(92744, "Murloc Gills", 12, 9, nil, true)
q(92745, "The State of the Mines", 14, 9, { 92742, 92744 }, true)
q(92747, "Moonbrook Espionage", 15, 9, 92745, true)
q(92748, "Explosive Consultation", 16, 9, 92747, true)
q(92749, "A Dynamite Plan", 16, 9, 92748, true)
q(92750, "Detonation at a Distance", 16, 9, 92749, true)
q(92751, "Detonation at a Distance", 16, 9, 92750, true)
q(92752, "Explosive Consultation", 16, 9, 92751, true)
q(92753, "Destruction in Deadmines", 18, 9, 92752, true)
q(92819, "Destruction in Deadmines", 18, 9, 92753, true)
q(92909, "Harvesting the Harvesters", 15, 9, nil, true)

q(244, "Encroaching Gnolls", 16, 11)
q(246, "Assessing the Threat", 17, 11, 244)
q(98407, "Show of Force", 17, 11, nil, true)
q(129, "A Free Lunch", 15, 12)
q(130, "Visit the Herbalist", 15, 12, 129)
q(131, "Delivering Daffodils", 15, 12, 130)
q(3741, "Hilary's Necklace", 15, 12)
q(125, "The Lost Tools", 16, 15)
q(89, "The Everstill Bridge", 20, 15, 125)
q(98386, "Alther's Mill", 21, 15, 89, true)
q(92, "Redridge Goulash", 18, 15)
q(127, "Selling Fish", 21, 16)
q(118, "The Price of Shoes", 18, 14)
q(119, "Return to Verner", 18, 13, 118)
q(120, "Messenger to Stormwind", 14, 14)
q(121, "Messenger to Stormwind", 14, 14, 120)
q(122, "Underbelly Scales", 18, 14, 119)
q(124, "A Baying of Gnolls", 20, 15, 119)
q(20, "Blackrock Menace", 21, 18)
q(98387, "Blackrock Blockade", 21, 18, nil, true)

local function objectiveAt(id, place, text, ...)
  local step = questAction("complete", id, place, text)
  step.objectives = { ... }
  return step
end

local function taxi(kind, place, name, text)
  return action(kind, place, text, { flight = name })
end

local function deadmines(step)
  step.optional, step.dungeon = true, "The Deadmines"
  return step
end

local west = {
  accept(109, furlbrow), accept(64, furlbrow), accept(36, verna), accept(151, verna),
  objectiveAt(64, wf(nil, 49.5, 19.3), "Search the wardrobe inside the farmhouse west of the Furlbrows.", "Furlbrow's Pocket Watch"),
  finish(64, furlbrow),
  action("goto", saldean, "Follow the road south to Saldean's Farm. Pick up oats from sacks by the fields."),
  finish(36, salma), accept(38, salma), accept(22, salma), accept(9, saldean), accept(92909, ozwin),
  finish(109, gryan, "Climb the stairs in the Sentinel Hill tower."),
  accept(12, gryan), accept(102, danuvin),
  accept(6181, lewis), finish(6181, thor),
  taxi("getfp", thor, "Sentinel Hill, Westfall", "Learn the Sentinel Hill flight path from Thor."),
  accept(6281, thor), accept(153, galiaan), accept(92742, alba), accept(92744, alba),
  action("sethearth", wf("Innkeeper Heather", 52.9, 53.7), "Bind at Sentinel Hill for the Westfall loops."),
  action("goto", wf(nil, 46.08, 38.14), "Work north through the farms. Take a sample at the Molsen Farm well."),
  objectiveAt(102, wf(nil, 46.5, 38.6), "Loot paws from the Riverpaw gnolls around the Molsen Farm.", "8 Gnoll Paws"),
  objectiveAt(92742, wf(nil, 56.62, 18.69), "Use the sample kit at the Molsen Farm well (46.1, 38.1) and the Jansen Stead well (56.6, 18.7).",
    "Molsen Farm Water Sample", "Jansen Stead Water Sample"),
  objectiveAt(12, wf(nil, 46.6, 25.2), "Clear Trappers and Smugglers around Jangolode and the nearby fields. Loot their bandanas.", "15 Defias Trappers", "15 Defias Smugglers"),
  objectiveAt(153, wf(nil, 47.2, 23.3), "Loot any remaining red leather bandanas from the Defias.", "15 Red Leather Bandanas"),
  objectiveAt(92744, wf(nil, 55.2, 9.4), "Loot gills from Coastrunners and Raiders on the north shore. Keep three eyes for Salma.", "7 Longshore Murloc Gills"),
  objectiveAt(151, wf(nil, 50.9, 21.7), "Collect eight Handfuls of Oats from sacks at the nearby farms.", "8 Handfuls of Oats"),
  finish(151, verna),
  action("goto", saldean, "Return south past Saldean's Farm and do the fields before heading to the tower."),
  objectiveAt(9, wf(nil, 53.1, 31.1), "Kill Harvest Watchers in the farm fields. Loot the machinery for Ozwin.", "20 Harvest Watchers"),
  objectiveAt(92909, wf(nil, 52.4, 31.3), "Loot Harvest Golems and Watchers for Ozwin's parts.", "14 Golem Isosprings", "5 Harvester Gyrostabilizers"),
  objectiveAt(22, wf(nil, 54.4, 40.4), "Kill goretusks south of the farm until you have the livers.", "8 Goretusk Livers"),
  objectiveAt(38, wf(nil, 54.4, 40.4), "Collect snouts from goretusks, meat from vultures, eyes from murlocs and okra from harvesters.",
    "3 Goretusk Snouts", "3 Stringy Vulture Meat", "3 Murloc Eyes", "3 Okra"),
  finish(9, saldean), finish(92909, ozwin), finish(22, salma), finish(38, salma),
  finish(12, gryan), accept(13, gryan), finish(102, danuvin), finish(153, galiaan),
  finish(92742, alba), finish(92744, alba), accept(92745, alba),
  action("goto", wf(nil, 46.3, 18.9), "Ride north to the Jangolode Mine entrance for the first half of Alba's survey."),
  objectiveAt(92745, wf(nil, 45.3, 20), "Kill 4 Kobold Diggers in Jangolode Mine. Then head southwest to Gold Coast Quarry (29.8, 48.1) for 6 Riverpaw Miners.",
    "4 Kobold Diggers", "6 Riverpaw Miners"),
  objectiveAt(13, wf(nil, 36.4, 54.4), "Clear Pillagers and Looters around Alexston Farmstead, then Moonbrook if you need more.",
    "15 Defias Pillagers", "15 Defias Looters"),
  finish(13, gryan), accept(14, gryan), finish(92745, alba), accept(92747, alba),
  objectiveAt(92747, wf(nil, 42.8, 68.2), "Open suspicious crates among the buildings in Moonbrook.", "8 Suspicious Industrial Supplies"),
  objectiveAt(14, wf(nil, 55.4, 76.8), "Clear the Defias camps on the Dust Plains south of Sentinel Hill.",
    "15 Defias Highwaymen", "5 Defias Pathstalkers", "5 Defias Knuckledusters"),
  finish(92747, alba), accept(92748, alba), finish(14, gryan),
  action("grind", wf(nil, 46, 68), "Reach level 15 before making the city trip. Finish any nearby outdoor quests or clear Defias.", { level = 15 }),
  accept(65, gryan),
  action("goto", ariena, "Follow the road east through Goldshire to Redridge and the gryphon master south of the Lakeshire bridge."),
  taxi("getfp", ariena, "Lakeshire, Redridge", "Learn the Lakeshire flight path."),
  finish(65, wiley, "Find Wiley upstairs at the Lakeshire inn."),
  accept(132, wiley),
  taxi("fly", thor, "Sentinel Hill, Westfall", "Fly from Lakeshire to Sentinel Hill, or use your Westfall hearth."),
  finish(132, gryan), accept(135, gryan),
  taxi("fly", dungar, "Stormwind, Elwynn", "Take Thor's gryphon to Stormwind. If the route is unavailable, walk through Goldshire to the city."),
  finish(6281, osric), accept(6261, osric),
  finish(135, shaw, "Find Shaw upstairs in the SI:7 building in Old Town."), accept(141, shaw),
  finish(92748, sprite), accept(92749, sprite),
  objectiveAt(92749, sprite, "Bring Sprite 10 Coarse Dynamite from a crafter or the auction house. Use Next to pass this chain if you cannot get it.", "10 Coarse Dynamite"),
  finish(92749, sprite), accept(92750, sprite), finish(92750, jasper), accept(92751, jasper),
  finish(92751, sprite), accept(92752, sprite),
  accept(168, wilder), accept(167, wilder), accept(2040, shoni),
  finish(6261, dungar), accept(6285, dungar),
  taxi("getfp", dungar, "Stormwind, Elwynn", "Check in with Dungar on the gryphon platform to learn the Stormwind flight path."),
  taxi("fly", thor, "Sentinel Hill, Westfall", "Fly back to Sentinel Hill or hearth there."),
  finish(6285, lewis), finish(92752, alba), accept(92753, alba),
  finish(141, gryan), accept(142, gryan),
  objectiveAt(142, wf(nil, 44.5, 69.6), "Intercept the Defias Messenger along the road from Moonbrook to Jangolode Mine and loot his message.", "A Mysterious Message"),
  finish(142, gryan), accept(155, traitor),
  objectiveAt(155, traitor, "Stay with the Defias Traitor from the tower to Moonbrook. Protect him until the escort gets credit.", "Defias hideout found"),
  finish(155, gryan),
  action("grind", wf(nil, 46, 68), "Reach level 17 for the next section. Finish Westfall outdoor quests or fight Defias near Moonbrook.", { level = 17 }),
  accept(166, gryan), accept(214, riell),
  deadmines(action("dungeon", wf(nil, 42.5, 71.7), "With a group, enter the mine through the large Moonbrook building. Use Next at the mine entrance.",
    { name = "The Deadmines" })),
  deadmines(objectiveAt(168, nil, "Loot Miners' Union Cards from undead in the tunnels before the instance portal.", "4 Miners' Union Cards")),
  deadmines(objectiveAt(167, nil, "Find Foreman Thistlenettle in the tunnels and loot his badge.", "Explorers' League Badge")),
  deadmines(objectiveAt(214, nil, "Loot Red Silk Bandanas from Defias in the mines and the dungeon.", "10 Red Silk Bandanas")),
  deadmines(objectiveAt(2040, nil, "Defeat Sneed's Shredder inside the instance and loot the sprocket.", "Gnoam Sprecklesprocket")),
  deadmines(objectiveAt(92753, nil, "Use the Extra-Destructive Explosives near the forge inside the Deadmines.", "Explosives planted")),
  deadmines(objectiveAt(166, nil, "Kill Edwin VanCleef on the ship and loot his head and the letter.", "Head of VanCleef")),
  deadmines(accept(373, nil, "Use the Letter to the City Architect from VanCleef's loot.")),
  deadmines(finish(92753, exitAlba, "Leave by the dungeon's back exit and speak to Alba outside.")),
  deadmines(accept(92819, exitAlba)),
  deadmines(objectiveAt(92819, exitAlba, "Use the detonator beside Alba.", "Detonator used")),
  deadmines(finish(92819, exitAlba)),
  deadmines(finish(166, gryan)), deadmines(finish(214, riell)),
  deadmines(taxi("fly", dungar, "Stormwind, Elwynn", "Fly to Stormwind for the Deadmines turn-ins.")),
  deadmines(finish(373, sw("Baros Alexston", 57.74, 47.86))),
  deadmines(finish(167, wilder)), deadmines(finish(168, wilder)), deadmines(finish(2040, shoni)),
  taxi("fly", ariena, "Lakeshire, Redridge", "Fly to Lakeshire. If you cannot fly, take the road east through Goldshire."),
}

local lakeshire = {
  taxi("getfp", ariena, "Lakeshire, Redridge", "Talk to Ariena on the south side of the bridge to learn the Lakeshire flight path."),
  action("sethearth", rr("Innkeeper Brianna", 22.0, 44.5), "Bind your hearthstone in the Lakeshire inn."),
  accept(129, darcy), accept(92, breanna), accept(127, baren),
  accept(3741, rr("Shawn", 24.23, 53.64)),
  accept(125, oslow), accept(118, verner), accept(120, solomon),
  finish(129, parker), accept(130, parker), accept(244, parker),
  finish(244, feldon), accept(246, feldon), accept(98407, feldon),
  objectiveAt(246, rr(nil, 10.7, 63.2), "Clear the southwest gnoll camps for Mongrels and Poachers.", "10 Redridge Mongrels", "6 Redridge Poachers"),
  objectiveAt(98407, rr(nil, 10.7, 63.2), "Loot Spiked Collars from the Thrashers among the same camps.", "5 Spiked Collars"),
  finish(246, feldon), finish(98407, feldon),
  finish(130, martie), accept(131, martie), finish(131, darcy),
  objectiveAt(3741, rr(nil, 33, 54.5), "Search Glinting Mud on the lakebed east of the bridge. Check nearby patches if this one is empty.", "Hilary's Necklace"),
  objectiveAt(125, rr(nil, 41.5, 54.7), "Swim east under the lake and look for Oslow's toolbox by the sunken boat.", "Oslow's Toolbox"),
  objectiveAt(127, rr(nil, 42, 53.8), "Loot Spotted Sunfish from murlocs around Lake Everstill.", "10 Spotted Sunfish"),
  finish(3741, rr("Hilary", 24.15, 53.63)), finish(125, oslow), accept(89, oslow), finish(127, baren),
  action("goto", argus, "Follow the west road to Goldshire. Stop at the smithy on the way to Stormwind."),
  finish(118, argus), accept(119, argus),
  action("goto", marcus, "Continue to Stormwind's front gate and find General Marcus Jonathan."),
  finish(120, marcus), accept(121, marcus),
  taxi("getfp", dungar, "Stormwind, Elwynn", "Learn the Stormwind flight path at the gryphon platform if needed."),
  taxi("fly", ariena, "Lakeshire, Redridge", "Fly or hearth back to Lakeshire with the letters and horseshoes."),
  finish(119, verner), accept(122, verner), accept(124, verner), finish(121, solomon),
  objectiveAt(124, rr(nil, 34.5, 31.5), "Clear Brutes and Mystics in the hills north of the lake. Loot bridge parts as you fight.", "10 Redridge Brutes", "8 Redridge Mystics"),
  objectiveAt(89, rr(nil, 33.8, 31.7), "Loot enough pikes and rivets from the northern gnolls.", "5 Iron Pikes", "5 Iron Rivets"),
  objectiveAt(122, rr(nil, 39.6, 33.1), "Loot scales from Black Dragon Whelps north of the lake.", "6 Underbelly Whelp Scales"),
  finish(122, verner), finish(124, verner), finish(89, oslow), accept(98386, oslow),
  objectiveAt(98386, rr(nil, 46.5, 37.5), "Kill Greater Tarantulas and crush eggs from the mill down toward the road. Save spider meat for the goulash.",
    "12 Greater Tarantulas", "6 Tarantula Eggs"),
  finish(98386, oslow),
  action("grind", rr(nil, 33.8, 31.7), "Reach level 18 for the Blackrock pickups. Finish your lake and gnoll quests first.", { level = 18 }),
  accept(20, marris), accept(98387, marris),
  objectiveAt(92, rr(nil, 28.2, 76.5), "Hunt condors, Great Goretusks and spiders south of the lake for Breanna.",
    "5 Tough Condor Meat", "5 Great Goretusk Snouts", "5 Crisp Spider Meat"),
  action("goto", rr(nil, 65.6, 78.7), "Follow the south shore toward Render's Valley."),
  objectiveAt(98387, rr(nil, 68.9, 79), "Search the southeastern Blackrock camps. Take weapons from racks and supplies from sacks and barrels.",
    "8 Stolen Weapons", "10 Blackrock Supplies"),
  objectiveAt(20, rr(nil, 71.1, 83.4), "Loot Battleworn Axes from the Blackrock orcs around the camps.", "10 Battleworn Axes"),
  action("hearth", rr("Innkeeper Brianna", 22, 44.5), "Hearth to Lakeshire for the final turn-ins, or follow the lake road west."),
  finish(92, breanna), finish(98387, marris), finish(20, marris),
  action("note", nil, "This route ends in Lakeshire. Review earlier Westfall quests from the Quests tab if you want to catch up."),
}

local sources = {
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
  "https://www.icy-veins.com/wow-classic/leveling-guide",
  "https://www.warcrafttavern.com/forever/guides/leveling",
  "https://forg.gg/en/forever/zones/elwynn-forest",
  "https://bindonforever.com/zones/elwynn-forest",
  "https://www.oraclenewsnetwork.com/quests",
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
}

local westSources = {
  "https://bindonforever.com/zones/westfall",
  "https://polestar.guide/guides/alliance/02-westfall",
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
  "https://questing.wiki/wow-forever/dungeons/deadmines/quests/",
}
local lakeshireSources = {
  "https://bindonforever.com/zones/redridge-mountains",
  "https://questing.wiki/wow-forever/leveling/redridge/",
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
}

LevelingCodexQuests = {
  ALLIANCE = {
    starts = { HUMAN = "northshire" },
    -- Width and height in yards, from UiMapAssignment in the Forever client reference.
    extents = { [elwynn] = { 3470.833, 2314.583 }, [stormwind] = { 1737.504, 1158.340 },
      [westfall] = { 3500, 2333.333 }, [redridge] = { 2170.834, 1447.916 } },
    sections = {
      { id = "northshire", title = "Northshire Valley", zone = elwynn, levels = { 1, 5 },
        start = "HUMAN", verified = false, sources = sources, steps = withTrainers(northshire, abbeyTrainers) },
      { id = "elwynn", title = "Elwynn Forest", zone = elwynn, levels = { 6, 12 },
        start = "HUMAN", verified = false, sources = sources, steps = withTrainers(forest, goldshireTrainers) },
      { id = "westfall", title = "Westfall", zone = westfall, levels = { 12, 18 },
        verified = false, sources = westSources, steps = west },
      { id = "lakeshire", title = "Lakeshire", zone = redridge, levels = { 17, 22 },
        verified = false, sources = lakeshireSources, steps = lakeshire },
    },
  },
}
