-- Hand-authored route. Source notes: tools/audits/2026-11-08-quests.md.
local elwynn, stormwind, westfall = 1429, 1453, 1436
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
    chain = prerequisite and { prerequisite }, forever = forever, class = class }
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
  finish(176, dughan), accept(109, dughan),
  action("grind", at(nil, 26.3, 91.3), "If still under level 12, finish nearby quests or clear Riverpaw gnolls to reach 12.", { level = 12 }),
  action("goto", at(nil, 59.95, 19.36, westfall), "Take the west road across the bridge and follow it to the Furlbrow farm."),
  action("note", nil, "Human 1-12 route complete. Keep Report to Gryan Stoutmantle for Sentinel Hill."),
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

LevelingCodexQuests = {
  ALLIANCE = {
    starts = { HUMAN = "northshire" },
    -- Width and height in yards, from UiMapAssignment in the Forever client reference.
    extents = { [elwynn] = { 3470.833, 2314.583 }, [stormwind] = { 1737.504, 1158.340 },
      [westfall] = { 3500, 2333.333 } },
    sections = {
      { id = "northshire", title = "Northshire Valley", zone = elwynn, levels = { 1, 5 },
        start = "HUMAN", verified = false, sources = sources, steps = withTrainers(northshire, abbeyTrainers) },
      { id = "elwynn", title = "Elwynn Forest", zone = elwynn, levels = { 6, 12 },
        start = "HUMAN", verified = false, sources = sources, steps = withTrainers(forest, goldshireTrainers) },
    },
  },
}
