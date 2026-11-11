-- Hand-authored route. Source notes: tools/audits/2026-11-08-quests.md.
local elwynn, stormwind, westfall, redridge, duskwood = 1429, 1453, 1436, 1433, 1431
local wetlands, lochModan, ironforge = 1437, 1432, 1455
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
q(99130, "An Enticing Offer", 7, 4, 99129, true)
q(99131, "Baited for Success", 7, 4, 99130, true)
q(91723, "Delicate Instruments", 8, 7, nil, true)
q(91724, "Delicate Instruments", 10, 7, 91723, true)
q(91725, "Stolen Enchanting Supplies", 10, 7, nil, true)
q(91732, "Good Steel", 7, 7, nil, true)
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
q(46, "Bounty on Murlocs", 10, 7, 39)
q(59, "Cloth and Leather Armor", 10, 7, 39)
q(123, "The Collector", 10, 7)
quest[123].startItem = 1307
q(52, "Protect the Frontier", 10, 7)
q(5545, "A Bundle of Trouble", 9, 5)
q(83, "Red Linen Goods", 9, 4)
q(239, "Westbrook Garrison Needs Help!", 10, 6, 76)
q(11, "Riverpaw Gnoll Bounty", 10, 6, 239)
q(176, 'WANTED: "Hogger"', 11, 5)
q(109, "Report to Gryan Stoutmantle", 10, 9)
-- Camping 101 profession intros and the skinning errand: optional (Settings > Show optional quests).
q(97924, "Camping 101: Skinning", 6, 4, 95998, true)
q(97921, "Camping 101: Herbalism", 6, 4, 95998, true)
q(97923, "Camping 101: Mining", 6, 4, 95998, true)
q(91751, "Rough Wolf Pelts", 8, 1, nil, true)
for _, id in ipairs({ 97924, 97921, 97923, 91751 }) do quest[id].optional = true end
-- Rare heads: the guide shows these only once the head is in your bags.
q(91740, "Croaky's Head", 11, 1, nil, true)
quest[91740].startItem = 247826
q(91746, "Elmpaw's Head", 12, 1, nil, true)
quest[91746].startItem = 247862
q(1097, "Elmore's Task", 15, 9)
q(98021, "Journey to Sentinel Hill", 13, 7, 94947, true)
quest[98021].race = "SKYBORNE"
q(92479, "A Scribbled Letter", 1, 1, 7, true, "HUNTER")
q(3100, "Simple Letter", 1, 1, 7, nil, "WARRIOR")
q(3101, "Consecrated Letter", 1, 1, 7, nil, "PALADIN")
q(3102, "Encrypted Letter", 1, 1, 7, nil, "ROGUE")
q(3103, "Hallowed Letter", 1, 1, 7, nil, "PRIEST")
q(3104, "Glyphic Letter", 1, 1, 7, nil, "MAGE")
q(3105, "Tainted Letter", 1, 1, 7, nil, "WARLOCK")

-- A breadcrumb leads to `followup` but isn't required for it: once the follow-up is in the
-- log or turned in, the game no longer offers the breadcrumb and the guide drops it.
local function breadcrumb(id, followup)
  quest[id].breadcrumb = followup
end

local function action(kind, place, text, extra)
  local step = { type = kind, text = text }
  if place then step.npc, step.map, step.x, step.y = place.name, place.map, place.x, place.y end
  for k, v in pairs(extra or {}) do step[k] = v end
  return step
end

local function questAction(kind, id, place, text)
  return action(kind, place, text, quest[id])
end

-- A step that uses an item from your bags: the item ID, or its name for Forever items the
-- quest data doesn't list. The step window shows a button for it.
local function withItem(item, step)
  step.item = item
  return step
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

local function along(step, ...)
  step.also = { ... }
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
  along(objective(7, 48.8, 36.4, "Kill vermin north of the abbey for the Nibbled-On Book. Loot wolves between kobold camps for Eagan.",
    "10 Kobold Vermin"), 33),
  along(objective(33, 49.7, 39.1, "Finish any wolf meat you still need around the abbey.", "8 Tough Wolf Meat"), 7),
  finish(33, eagan), finish(7, mcbride),
  accept(15, mcbride),
  withItem("Nibbled-On Book", accept(91741, at(nil, 48.8, 36.4), "Use the Nibbled-On Book from your bags. If it has not dropped, loot more Kobold Vermin.")),
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
  along(objective(15, 49, 35.7, "Kill Workers around the approach to Echo Ridge Mine. Loot Stolen Books while you fight.", "10 Kobold Workers"), 91743),
  along(objective(91743, 48.3, 34, "Finish collecting Stolen Books from the Workers and Vermin.", "8 Stolen Books"), 15),
  finish(15, mcbride), accept(21, mcbride),
  finish(91743, paxton), accept(91745, paxton),
  finish(91745, kelsey, "Speak to Kelsey outside the mouth of Echo Ridge Mine."),
  accept(91752, kelsey),
  along(objective(21, 48.4, 29, "Clear Laborers inside Echo Ridge on the way to Shinyfinder Narf.", "12 Kobold Laborers"), 91752),
  along(objective(91752, 49, 28, "Loot the sack from Shinyfinder Narf inside the mine. Group up if needed.", 'Sack of "Picture" Books'), 21),
  objective(18, 53.1, 44.8, "Work the vineyard from its edges and loot the Defias Thugs.", "12 Red Burlap Bandanas"),
  finish(18, willem), accept(6, willem), accept(3903, willem),
  finish(3903, milly), accept(3904, milly),
  along(objective(3904, 54.5, 48.5, "Pick up grape crates as you cross the vineyard toward Garrick's shack.", "8 crates of Milly's Harvest"), 6),
  along(objective(6, 57.4, 48.3, "Kill Garrick by the shack east of the vineyard and loot his head.", "Garrick's Head"), 3904),
  finish(6, willem), finish(3904, milly), accept(3905, milly),
  finish(3905, at("Brother Neals", 49.47, 41.59), "Take the manifest upstairs in the abbey."),
  finish(21, mcbride), finish(91752, mcbride), accept(91758, mcbride),
  accept(54, mcbride), accept(96627, mcbride),
  finish(91758, tordrin), accept(91772, tordrin),
}

local azora = {
  hamish = at("Hamish Bergwort", 65.1, 69.84),
  blixie = at("Blixie Fitzwink", 63.2, 72.6),
  hagar = at("Hagar Lowe", 82.47, 63.83),
  sara = at("Sara Timberlain", 79.46, 68.79),
}

local forest = {
  accept(2158, at("Falkhaan Isenstrider", 45.56, 47.74)),
  withItem("Kobold Tracking Kit", objective(91772, 45.6, 55.3, "Use the Kobold Tracking Kit from your bags. Follow the tracks from the stables toward Goldshire.", "6 Kobold Tracks")),
  finish(96627, sam), accept(95998, sam),
  objective(95998, 45, 63, "Sit by Sam's fire until you get Boosted Rest.", "Boosted Rest"),
  finish(95998, sam), accept(96626, sam),
  accept(97924, sam, "If you know Skinning, ask Sam for the skinning lesson too."),
  accept(97921, sam, "If you know Herbalism, ask Sam for the herbalism lesson too."),
  accept(97923, sam, "If you know Mining, ask Sam for the mining lesson too."),
  finish(97924, at("Helene Peltskinner", 46.24, 62.24), "Talk to Helene in the house just east of Sam's camp."),
  accept(91751, at("Helene Peltskinner", 46.24, 62.24), "Skinners can take Helene's wolf pelt order. Skin the wolves you kill east of Goldshire."),
  finish(2158, farley),
  action("sethearth", farley, "Bind your hearthstone at the Lion's Pride Inn.", { bind = "Goldshire" }),
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
  along(objective(62, 40.6, 80.9, "Explore Fargodeep Mine. Loot the kobolds for dust and candles and pick up Lost Books as you go.", "Explore Fargodeep Mine"),
    47, 60, 91775),
  along(objective(87, 41.4, 80.8, "Find Goldtooth in the mine and take the necklace.", "Bernice's Necklace"), 47, 60, 91775),
  along(objective(91775, 40.8, 80.8, "Collect the Lost Books and loot Fun with Elementals from Nimsy. Bring help for Nimsy.", "6 Lost Books", "Fun with Elementals"),
    47, 60, 87),
  along(objective(47, fargodeep.x, fargodeep.y, "Finish collecting gold dust from the kobolds.", "10 Gold Dust"), 60),
  along(objective(60, fargodeep.x, fargodeep.y, "Loot kobolds for any Large Candles you still need.", "8 Large Candles"), 47),
  finish(87, bernice),
  action("hearth", farley, "Take the road north to Goldshire if you're walking.", { bind = "Goldshire" }),
  finish(62, dughan), accept(76, dughan), finish(91775, dughan), accept(91777, dughan),
  finish(47, remy), accept(40, remy), finish(40, dughan), accept(35, dughan),
  finish(60, pestle), accept(61, pestle), finish(107, pestle), accept(112, pestle),
  action("train", nil, "Train spells for level", { level = 8 }),
  accept(99127, jason), accept(99143, lee),
  objective(99127, 47.9, 62.6, "Search the fishing traps in the shallows for a Half-Eaten Fish.", "Half-Eaten Fish"),
  finish(99127, jason), accept(99128, jason),
  along(objective(99128, 53.6, 65.4, "Pull murlocs near Crystal Lake a few at a time. Loot kelp and search for junk as you go.",
    "7 Murlocs", "4 Murloc Streamrunners"), 112, 99143),
  along(objective(112, 55.1, 65.6, "Collect the rest of the kelp from the murlocs by the lake.", "4 Crystal Kelp Fronds"), 99128, 99143),
  along(objective(99143, 52.9, 65, "Search the murloc camp for its remaining shiny junk.", "6 pieces of shiny junk"), 99128, 112),
  finish(99128, jason), accept(99129, jason), finish(99143, lee),
  accept(91723, azora.hamish, "Follow the east road to the Tower of Azora and speak to Hamish inside."),
  accept(91725, azora.blixie, "Find Blixie just southwest of the tower."),
  finish(35, thomas), accept(37, thomas), accept(52, thomas),
  finish(37, body, "Search the bank north of the bridge for the half-eaten body."), accept(45, body),
  finish(45, rolf, "Find Rolf's corpse in the murloc camp east of the river."), accept(71, rolf),
  accept(5545, at("Supervisor Raelen", 81.38, 66.11)),
  accept(83, azora.sara), accept(91732, azora.hagar),
  along(objective(5545, 81.7, 62.4, "Gather fallen wood and hunt Prowlers and Young Forest Bears around Eastvale.", "8 Bundles of Wood"), 52),
  along(objective(52, 81, 69, "Finish any wolves or bears you still need around Eastvale.", "8 Prowlers", "5 Young Forest Bears"), 5545),
  along(objective(91751, 81, 69, "Skin the Prowlers you kill around Eastvale for Helene's pelts.", "7 Rough Wolf Pelts"), 52),
  finish(5545, at("Supervisor Raelen", 81.38, 66.11)),
  finish(52, thomas), finish(71, thomas), accept(39, thomas), accept(91733, ormin),
  objective(91733, 74.3, 76.4, "Search the riverbanks south of the bridge for Ormin's tools. Croaky, a level 11 elite frog, roams the same banks; its head starts a quest.",
    "Waterlogged Axe", "Waterlogged Saw", "Waterlogged Toolbox"),
  withItem(247826, accept(91740, at("Croaky", 76.5, 86.1), "Use Croaky's Head from your bags to start the quest.")),
  finish(91740, at("Merell Ross", 84.75, 79.3), "Follow the river east to Merell Ross at Ridgepoint Tower."),
  finish(91733, ormin),
  along(objective(83, 70.9, 80.1, "Loot Defias Bandits outside at Brackwell Pumpkin Patch on the way to Princess.", "6 Red Linen Bandanas"), 88),
  along(objective(88, 69.8, 79.4, "Clear Princess's guards before taking her collar. Loot any remaining bandanas on the way out.", "Brass Collar"), 83),
  finish(83, azora.sara),
  along(action("goto", at(nil, 61.7, 53.9), "Head west from Eastvale to Jasperlode Mine. Enter through the south opening."),
    76, 91723, 91732),
  along(objective(76, jasperlode.x, jasperlode.y, "Explore the middle tunnel. Fight Kobold Geomancers and pick up the mining tools as you go.",
    "Explore Jasperlode Mine"), 91723, 91732, 91777),
  along(objective(91723, 62.9, 55.2, "Finish any Geomancers you still need around the mine and its entrance.", "8 Kobold Geomancers"), 91732, 91777),
  along(objective(91732, 61.4, 51.6, "Collect any remaining Mining Tools inside Jasperlode before leaving.", "4 Mining Tools"), 91723, 91777),
  objective(91777, jasperlode.x, jasperlode.y, "With help, loot Geomancy from Geosculptor Yip and Arcane Explainer from Mother Fang. Use Next if the rares are unavailable.",
    "Geomancy for Curious Young Wizards", "Arcane Explainer: Magical Stuff in Simple Words"),
  finish(91723, azora.hamish, "Return west along the road to Hamish at the Tower of Azora."), accept(91724, azora.hamish),
  action("hearth", farley, "The next turn-ins are in Goldshire.", { bind = "Goldshire" }),
  finish(39, dughan), accept(59, dughan), finish(76, dughan), accept(239, dughan),
  finish(99129, remy), accept(99130, remy), finish(112, pestle), accept(114, pestle),
  finish(114, maybell), finish(88, ma),
  objective(99130, 41.8, 86.1, "Pull up Overgrown Duskweed in the farm fields and loot blood from nearby Stonetusk Boars. Young Forest Bears also drop it.",
    "18 Duskweed Petals", "6 Vials of Animal Blood"),
  finish(99130, remy, "Take the road north to Remy in Goldshire."), accept(99131, remy),
  finish(99131, jason, "Bring Remy's message to Jason at Crystal Lake before going east."),
  accept(46, thomas, "Return to Guard Thomas at the east bridge. He offers the bounty after you deliver his report."),
  objective(46, 79.2, 52.0, "Hunt ordinary murlocs on the eastern shore of Stone Cairn Lake for fins. Pull them one or two at a time.",
    "8 Torn Murloc Fins"),
  objective(91724, 74.4, 53.2, "Fight the Defias Rogue Wizards near Stone Cairn Lake.", "8 Defias Rogue Wizards"),
  objective(91725, 67.8, 43.5, "Look for the scattered enchanting supplies in the gnoll camps west of the lake. Elmpaw (level 12) roams north of the lake; its head starts a quest.",
    "5 Stolen Enchanting Supplies"),
  withItem(247862, accept(91746, at("Elmpaw", 74.4, 39.6), "Use Elmpaw's Head from your bags to start the quest.")),
  finish(46, thomas), finish(59, azora.sara), finish(91732, azora.hagar),
  finish(91724, azora.hamish, "Follow the road west to the Tower of Azora."), finish(91725, azora.blixie),
  action("hearth", farley, "Take the main road west to Goldshire if you're walking.", { bind = "Goldshire" }),
  action("train", nil, "Visit your class trainer and learn spells for level", { level = 10 }),
  finish(91746, at("Helene Peltskinner", 46.24, 62.24), "Bring Elmpaw's Head to Helene in the house east of Goldshire."),
  finish(91751, at("Helene Peltskinner", 46.24, 62.24), "Hand Helene the wolf pelts."),
  accept(1097, at("Smith Argus", 41.71, 65.54), "Smith Argus has an errand for Stormwind. Take it before you head to the city."),
  finish(91777, paxton, "Return the two rare books to Paxton before heading on to Stormwind."),
  finish(97921, at("Herbalist Pomeroy", 39.96, 48.41), "Stop at Herbalist Pomeroy's house beside the road to Stormwind."),
  action("goto", at(nil, 34.7, 51), "Follow the road through the gates into Stormwind."),
  finish(61, at("Morgan Pestle", 63.2, 74.4, stormwind)),
  action("getfp", at("Dungar Longdrink", 71, 72.5, stormwind), "Learn the flight path from Dungar above the Trade District.",
    { flight = "Stormwind, Elwynn" }),
  finish(1097, at("Grimand Elmore", 59.7, 33.8, stormwind), "Go north to the Dwarven District and find Grimand Elmore. Leave his package for now unless you plan on Loch Modan."),
  finish(97923, at("Gelman Stonehand", 59.25, 37.83, stormwind), "Talk to Gelman Stonehand a few steps south of Elmore."),
  action("hearth", farley, "If you're walking, leave Stormwind through the main gates and follow the road to Goldshire.", { bind = "Goldshire" }),
  finish(239, rainer), accept(11, rainer),
  accept(176, at("Wanted Poster", 24.55, 74.69)),
  along(objective(11, 26.3, 91.3, "Loot armbands from Riverpaw gnolls as you clear the camps on the way to Hogger.",
    "8 Painted Gnoll Armbands"), 176),
  along(objective(176, 25.1, 94.1, "Find Hogger near the gnoll camps. Get help if needed and loot his claw.", "Huge Gnoll Claw"), 11),
  finish(11, rainer),
  finish(176, dughan),
  withItem(1307, accept(123, dughan, "Read the Gold Pickup Schedule you looted from the Riverpaw gnolls.")),
  finish(123, dughan, "Give the schedule to Marshal Dughan in Goldshire."),
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
q(184, "Furlbrow's Deed", 9, 8)
quest[184].startItem = 1972
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
-- The game offers the Swift Message chain to Humans only (requiredRaces 1).
for _, id in ipairs({ 6181, 6281, 6261, 6285 }) do quest[id].race = "HUMAN" end
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
q(103, "Keeper of the Flame", 16, 10)
q(104, "The Coastal Menace", 20, 15)

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
-- Forever's Stormwind library errand (Roy Lewells in the park): optional, it crosses the city twice.
q(97234, "Reading Room", 18, nil, nil, true)
q(97237, "Shelf Picked", 18, nil, 97234, true)
quest[97234].optional = true
quest[97237].optional = true
q(122, "Underbelly Scales", 18, 14, 119)
q(124, "A Baying of Gnolls", 20, 15, 119)
q(20, "Blackrock Menace", 21, 18)
q(98387, "Blackrock Blockade", 21, 18, nil, true)

q(163, "Raven Hill", 20, 17)
q(5, "Jitters' Growling Gut", 20, 17, 163)
q(93, "Dusky Crab Cakes", 20, 17, 5)
q(240, "Return to Jitters", 20, 17, 93)
q(164, "Deliveries to Sven", 23, 17)
q(165, "The Hermit", 25, 17)
q(148, "Supplies from Darkshire", 24, 20, 165)
q(149, "Ghost Hair Thread", 24, 20, 148)
q(154, "Return the Comb", 24, 20, 149)
q(157, "Deliver the Thread", 24, 20, 154)
q(158, "Zombie Juice", 24, 20, 157)
q(156, "Gather Rot Blossoms", 24, 20, 158)
q(159, "Juice Delivery", 24, 20, 156)
q(133, "Ghoulish Effigy", 27, 20, 159)
q(245, "Eight-Legged Menaces", 21, 17)
q(226, "Wolves at Our Heels", 21, 19)
q(95, "Sven's Revenge", 25, 20)
q(230, "Sven's Camp", 25, 20, 95)
q(262, "The Shadowy Figure", 25, 20, 230)
q(265, "The Shadowy Search Continues", 25, 20, 262)
q(266, "Inquire at the Inn", 25, 20, 265)
q(453, "Finding the Shadowy Figure", 25, 20, 266)
q(268, "Return to Sven", 25, 20, 453)
q(56, "The Night Watch", 24, 18)
q(57, "The Night Watch", 26, 18, 56)
q(101, "The Totem of Infliction", 25, 18)
q(96139, "The Valor Family", 23, 18, nil, true)
q(96137, "Ira's Dagger", 25, 18, nil, true)
quest[96137].startItem = 281143
q(174, "Look To The Stars", 25, 20)
q(175, "Look To The Stars", 25, 20, 174)
q(177, "Look To The Stars", 25, 20, 175)
-- Chef Grual only offers the kabobs at Cooking 50: an optional pickup (Settings > Show optional quests).
q(90, "Seasoned Wolf Kabobs", 25, 18)
quest[90].optional = true
q(79362, "Grant's Shield", 25, 18, nil, true)
quest[79362].startItem = 281147
q(337, "An Old History Book", 25, 20)
quest[337].startItem = 2794
q(323, "Proving Your Worth", 28, 20, 268)
q(269, "Seeking Wisdom", 29, 20, 323)
-- After the Wetlands' Blessed Arm (322): Grimand Elmore in Stormwind sends Morbent's Bane to Sven.
-- Morbent Fel is level 32, past this route; the steps belong to a later Duskwood visit.
q(325, "Armed and Ready", 29, 20, 322)
q(55, "Morbent Fel", 32, 20, 325)

q(98245, "Razormaw Needling", 29, 22, nil, true)
q(98246, "Trying Times", 29, 22, nil, true)
q(276, "Tramping Paws", 21, 20)
-- Fitzsimmons' breadcrumb only helps players who arrive by ship; optional steps still show once it is in the log.
q(463, "The Greenwarden", 21, 20)
quest[463].optional = true
breadcrumb(463, 276)
-- Hollee's note from Darkshore (Forever): picked up in the Darkshore chapter, handed in at Menethil.
q(98461, "Unrequited Love", 21, nil, nil, true)
quest[98461].optional = true
q(277, "Fire Taboo", 23, 20, 276)
q(275, "Blisters on The Land", 26, 20, 277)
q(294, "Ormer's Revenge", 24, 22)
q(295, "Ormer's Revenge", 27, 22, 294)
q(296, "Ormer's Revenge", 29, 22, 295)
q(299, "Uncovering the Past", 28, 25)
q(279, "Claws from the Deep", 22, 20)
q(281, "Reclaiming Goods", 25, 20, 279)
q(284, "The Search Continues", 25, 20, 281)
q(285, "Search More Hovels", 25, 20, 284)
q(286, "Return the Statuette", 25, 20, 285)
q(98189, "Return the Statuette", 25, 20, 286, true)
q(98190, "A Friend of the Family", 25, 20, 98189, true)
q(98191, "A Friend of the Family", 25, 20, 98190, true)
q(98219, "The Shamed Lieutenant", 30, nil, 98191, true)
quest[98219].optional = true
q(288, "The Third Fleet", 27, 22)
q(289, "The Cursed Crew", 29, 22, 288)
q(98282, "Alchemical Hazards", 22, 20, nil, true)
q(470, "Digging Through the Ooze", 24, 19)
q(98197, "Spoils of War", 22, 20, nil, true)
q(473, "Report to Captain Stoutfist", 28, 23)
q(464, "War Banners", 28, 23, 473)
q(98221, "From the Ashes", 28, 23, nil, true)
q(305, "In Search of The Excavation Team", 24, 21)
q(306, "In Search of The Excavation Team", 24, 21, 305)
-- Wetlands gap fill (tools/audits/2026-11-10-darkshore-ashenvale-wetlands-gaps.md).
q(270, "The Doomed Fleet", 29, 20, 269)
q(321, "Lightforge Iron", 29, 20, 270)
q(324, "The Lost Ingots", 29, 20, 321)
q(322, "Blessed Arm", 29, 20, 324)
q(290, "Lifting the Curse", 30, 22, 289)
q(292, "The Eye of Paleth", 30, 22, 290)
q(293, "Cleansing the Eye", 30, 22, 292)
q(484, "Young Crocolisk Skins", 22, 18)
q(471, "Apprentice's Duties", 26, 18, 484)
q(98072, "Crocs of the Sky", 27, nil, nil, true)
q(472, "Fall of Dun Modr", 25, 25)
q(631, "The Thandol Span", 31, 28)
q(632, "The Thandol Span", 31, 28, 631)
q(633, "The Thandol Span", 31, 28, 632)
q(637, "Sully Balloo's Letter", 30, 25)
quest[637].startItem = 4433
q(98208, "Bloom of the Heavens", 29, nil, nil, true)
q(98209, "Bloom of the Heavens", 29, nil, nil, true)
q(98291, "Death to the Dragonmaw", 30, nil, nil, true)
q(98293, "Forced Disarmament", 30, nil, nil, true)
q(95647, "Lost in the Thicket Things", 31, 24, nil, true)
q(98815, "Highland Hides", 28, nil, nil, true)
q(95646, "Horrors in the Highland", 31, 24, 275, true)
q(971, "Knowledge in the Deeps", 23, 10)
q(3765, "The Corruption Abroad", 24, 18)
q(1275, "Researching the Corruption", 24, 18, 3765)

local function objectiveAt(id, place, text, ...)
  local step = questAction("complete", id, place, text)
  step.objectives = { ... }
  return step
end

local function objectivePart(id, index, place, text, label)
  local step = objectiveAt(id, place, text, label)
  step.objectiveIndex = index
  return step
end

local function taxi(kind, place, name, text)
  return action(kind, place, text, { flight = name })
end

-- A pickup for a dungeon detour: shown when that dungeon is planned (Quests tab or Settings).
local function forDungeon(step, id)
  step.optional, step.dungeon = true, id
  return step
end

-- A step that offers a special or dungeon checklist (Plan <guide> while it is current).
local function withGuide(id, step)
  step.guide = id
  return step
end

local west = {
  withItem(1972, accept(184, furlbrow, "Use the Westfall Deed you looted to start the quest.")),
  finish(184, furlbrow, "Hand the deed to Farmer Furlbrow by the wagon."),
  accept(109, furlbrow), accept(64, furlbrow), accept(36, verna), accept(151, verna),
  objectiveAt(64, wf(nil, 49.5, 19.3), "Search the wardrobe inside the farmhouse west of the Furlbrows.", "Furlbrow's Pocket Watch"),
  finish(64, furlbrow),
  action("goto", saldean, "Follow the road south to Saldean's Farm. Pick up oats from sacks by the fields."),
  finish(36, salma), accept(38, salma), accept(22, salma), accept(9, saldean), accept(92909, ozwin),
  finish(109, gryan, "Climb the stairs in the Sentinel Hill tower."),
  finish(98021, gryan, "Turn in Bolvar's message to Gryan. If you came to Westfall without the message, use Next."),
  accept(12, gryan), accept(102, danuvin),
  accept(6181, lewis), finish(6181, thor),
  taxi("getfp", thor, "Sentinel Hill, Westfall", "Learn the Sentinel Hill flight path from Thor."),
  accept(6281, thor), accept(153, galiaan), accept(92742, alba), accept(92744, alba),
  action("sethearth", wf("Innkeeper Heather", 52.9, 53.7), "Bind your hearthstone with Innkeeper Heather at Sentinel Hill.", { bind = "Sentinel Hill" }),
  along(action("goto", wf(nil, 46.08, 38.14), "Work north through the farms to the Molsen Farm well."), 102, 92742),
  along(withItem("Well Water Sample Kit", objectiveAt(102, wf(nil, 46.5, 38.6),
    "Loot paws from Riverpaw gnolls and sample the Molsen Farm well at 46.1, 38.1.", "8 Gnoll Paws")), 92742),
  along(withItem("Well Water Sample Kit", objectiveAt(92742, wf(nil, 56.62, 18.69), "Use the sample kit at the Molsen Farm well (46.1, 38.1) and the Jansen Stead well (56.6, 18.7).",
    "Molsen Farm Water Sample", "Jansen Stead Water Sample")), 151),
  along(objectiveAt(12, wf(nil, 46.6, 25.2), "Clear Trappers and Smugglers near Jangolode. Loot their bandanas and check nearby farms for oats.",
    "15 Defias Trappers", "15 Defias Smugglers"), 153, 151),
  along(objectiveAt(153, wf(nil, 47.2, 23.3), "Loot any remaining red leather bandanas from the Defias.", "15 Red Leather Bandanas"), 12, 151),
  along(objectiveAt(92744, wf(nil, 55.2, 9.4), "Loot gills from Coastrunners and Raiders on the north shore. Keep three eyes for Salma.",
    "7 Longshore Murloc Gills"), 38),
  objectiveAt(151, wf(nil, 50.9, 21.7), "Collect eight Handfuls of Oats from sacks at the nearby farms.", "8 Handfuls of Oats"),
  finish(151, verna),
  action("goto", saldean, "Return south past Saldean's Farm and do the fields before heading to the tower."),
  along(objectiveAt(9, wf(nil, 53.1, 31.1), "Kill Harvest Watchers in the fields. Loot their machine parts for Ozwin and okra for Salma.",
    "20 Harvest Watchers"), 92909, 38),
  along(objectiveAt(92909, wf(nil, 52.4, 31.3), "Loot Harvest Golems and Watchers for any parts or okra you still need. Keep 5 Flasks of Oil from the golems for the lighthouse later.",
    "14 Golem Isosprings", "5 Harvester Gyrostabilizers"), 9, 38),
  along(objectiveAt(22, wf(nil, 54.4, 40.4), "Hunt goretusks south of the farm for livers and snouts. Loot any vultures you pass.",
    "8 Goretusk Livers"), 38),
  along(objectiveAt(38, wf(nil, 54.4, 40.4), "Finish any missing stew ingredients from goretusks, vultures, murlocs and harvesters.",
    "3 Goretusk Snouts", "3 Stringy Vulture Meat", "3 Murloc Eyes", "3 Okra"), 22, 92909),
  finish(9, saldean), finish(22, salma), finish(38, salma), finish(92909, ozwin),
  finish(12, gryan), accept(13, gryan), finish(102, danuvin), finish(153, galiaan),
  finish(92742, alba), finish(92744, alba), accept(92745, alba),
  action("goto", wf(nil, 46.3, 18.9), "Ride north to the Jangolode Mine entrance for the first half of Alba's survey."),
  objectivePart(92745, 1, wf(nil, 45.3, 20), "Kill the Kobold Diggers in Jangolode Mine.", "4 Kobold Diggers"),
  objectivePart(92745, 2, wf(nil, 29.8, 48.1), "Head south-west to Gold Coast Quarry and kill the Riverpaw Miners.", "6 Riverpaw Miners"),
  objectiveAt(13, wf(nil, 36.4, 54.4), "Clear Pillagers and Looters around Alexston Farmstead, then Moonbrook if you need more.",
    "15 Defias Pillagers", "15 Defias Looters"),
  finish(13, gryan), accept(14, gryan), finish(92745, alba), accept(92747, alba),
  objectiveAt(92747, wf(nil, 42.8, 68.2), "Open suspicious crates among the buildings in Moonbrook.", "8 Suspicious Industrial Supplies"),
  objectiveAt(14, wf(nil, 55.4, 76.8), "Clear the Defias camps on the Dust Plains south of Sentinel Hill.",
    "15 Defias Highwaymen", "5 Defias Pathstalkers", "5 Defias Knuckledusters"),
  finish(92747, alba), accept(92748, alba), finish(14, gryan),
  action("grind", wf(nil, 46, 68), "Reach level 15 for the next loop. Try an alternate route for quest XP, or finish nearby outdoor quests.",
    { level = 15, suggest = { "loch-modan", "darkshore" }, guide = "cozy-sleeping-bag" }),
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
  finish(6285, lewis), finish(141, gryan), accept(142, gryan),
  finish(92752, alba), accept(92753, alba),
  objectiveAt(142, wf(nil, 44.5, 69.6), "Intercept the Defias Messenger along the road from Moonbrook to Jangolode Mine and loot his message.", "A Mysterious Message"),
  action("goto", wf("Captain Grayson", 30.01, 86.02), "Follow the road south-west from Moonbrook to the Westfall Lighthouse on the coast."),
  accept(103, wf("Captain Grayson", 30.01, 86.02)), accept(104, wf("Captain Grayson", 30.01, 86.02)),
  objectiveAt(103, wf(nil, 46.9, 67.2), "If you kept 5 Flasks of Oil from the fields, this is already done. Otherwise kill Harvest Golems in the fields east of Moonbrook.",
    "5 Flasks of Oil"),
  objectiveAt(104, wf("Old Murk-Eye", 29.3, 76), "Old Murk-Eye, a large grey murloc, walks the beach north of the lighthouse. Pull him away from the other murlocs.",
    "Scale of Old Murk-Eye"),
  finish(103, wf("Captain Grayson", 30.01, 86.02)), finish(104, wf("Captain Grayson", 30.01, 86.02)),
  action("goto", gryan, "Follow the road north-east back to Sentinel Hill."),
  finish(142, gryan), accept(155, traitor),
  objectiveAt(155, traitor, "Stay with the Defias Traitor from the tower to Moonbrook. Protect him until the escort gets credit.", "Defias hideout found"),
  finish(155, gryan),
  action("grind", wf(nil, 46, 68), "Reach level 17 before heading to Lakeshire. Finish Westfall quests, clear nearby Defias, or try an alternate route.",
    { level = 17, suggest = { "loch-modan", "darkshore" }, guide = "dungeon-deadmines" }),
  accept(166, gryan), accept(214, riell),
  forDungeon(action("dungeon", wf(nil, 42.5, 71.7), "With a group, enter the mine through the large Moonbrook building. Use Next at the mine entrance.",
    { name = "The Deadmines" }), "dungeon-deadmines"),
  forDungeon(objectiveAt(168, nil, "Loot Miners' Union Cards from undead in the tunnels before the instance portal.", "4 Miners' Union Cards"), "dungeon-deadmines"),
  forDungeon(objectiveAt(167, nil, "Find Foreman Thistlenettle in the tunnels and loot his badge.", "Explorers' League Badge"), "dungeon-deadmines"),
  forDungeon(objectiveAt(214, nil, "Loot Red Silk Bandanas from Defias in the mines and the dungeon.", "10 Red Silk Bandanas"), "dungeon-deadmines"),
  forDungeon(objectiveAt(2040, nil, "Defeat Sneed's Shredder inside the instance and loot the sprocket.", "Gnoam Sprecklesprocket"), "dungeon-deadmines"),
  forDungeon(withItem("Extra-Destructive Explosives", objectiveAt(92753, nil, "Use the Extra-Destructive Explosives near the forge inside the Deadmines.", "Explosives planted")), "dungeon-deadmines"),
  forDungeon(objectiveAt(166, nil, "Kill Edwin VanCleef on the ship and loot his head and the letter.", "Head of VanCleef"), "dungeon-deadmines"),
  forDungeon(withItem(2874, accept(373, nil, "Use the Letter to the City Architect from VanCleef's loot.")), "dungeon-deadmines"),
  forDungeon(finish(92753, exitAlba, "Leave by the dungeon's back exit and speak to Alba outside."), "dungeon-deadmines"),
  forDungeon(accept(92819, exitAlba), "dungeon-deadmines"),
  forDungeon(objectiveAt(92819, exitAlba, "Use the detonator beside Alba.", "Detonator used"), "dungeon-deadmines"),
  forDungeon(finish(92819, exitAlba), "dungeon-deadmines"),
  forDungeon(finish(166, gryan), "dungeon-deadmines"), forDungeon(finish(214, riell), "dungeon-deadmines"),
  forDungeon(taxi("fly", dungar, "Stormwind, Elwynn", "Fly to Stormwind for the Deadmines turn-ins."), "dungeon-deadmines"),
  forDungeon(finish(373, sw("Baros Alexston", 57.74, 47.86)), "dungeon-deadmines"),
  forDungeon(finish(167, wilder), "dungeon-deadmines"), forDungeon(finish(168, wilder), "dungeon-deadmines"), forDungeon(finish(2040, shoni), "dungeon-deadmines"),
  taxi("fly", ariena, "Lakeshire, Redridge", "Fly to Lakeshire. If you cannot fly, take the road east through Goldshire."),
}

local lakeshire = {
  taxi("getfp", ariena, "Lakeshire, Redridge", "Talk to Ariena on the south side of the bridge to learn the Lakeshire flight path."),
  action("sethearth", rr("Innkeeper Brianna", 22.0, 44.5), "Bind your hearthstone with Innkeeper Brianna in Lakeshire.", { bind = "Lakeshire" }),
  accept(129, darcy), accept(92, breanna), accept(127, baren),
  accept(3741, rr("Shawn", 24.23, 53.64)),
  accept(125, oslow), accept(118, verner), accept(120, solomon),
  finish(129, parker), accept(130, parker), accept(244, parker),
  finish(244, feldon), accept(246, feldon), accept(98407, feldon),
  along(objectiveAt(246, rr(nil, 10.7, 63.2), "Clear the southwest gnoll camps for Mongrels and Poachers. Loot collars from Thrashers in the same camps.",
    "10 Redridge Mongrels", "6 Redridge Poachers"), 98407),
  along(objectiveAt(98407, rr(nil, 10.7, 63.2), "Loot any remaining Spiked Collars from Thrashers in the same camps.",
    "5 Spiked Collars"), 246),
  finish(246, feldon), finish(98407, feldon),
  finish(130, martie), accept(131, martie), finish(131, darcy),
  along(objectiveAt(3741, rr(nil, 33, 54.5), "Check Glinting Mud for Hilary's necklace. Look for the toolbox farther east and loot fish from murlocs you pass.",
    "Hilary's Necklace"), 125, 127),
  along(objectiveAt(125, rr("Sunken Chest", 36.4, 54.7), "Dive for the Sunken Chest beside the wreck. Watch your breath and give the elite Lake Thresher room.",
    "Oslow's Toolbox"), 3741, 127),
  along(objectiveAt(127, rr(nil, 42, 53.8), "Loot any remaining Spotted Sunfish from the Lake Everstill murlocs.",
    "10 Spotted Sunfish"), 3741, 125),
  finish(3741, rr("Hilary", 24.15, 53.63)), finish(125, oslow), accept(89, oslow), finish(127, baren),
  action("goto", argus, "Follow the west road to Goldshire. Stop at the smithy on the way to Stormwind."),
  finish(118, argus), accept(119, argus),
  action("goto", marcus, "Continue to Stormwind's front gate and find General Marcus Jonathan."),
  finish(120, marcus), accept(121, marcus),
  accept(97234, sw("Roy Lewells", 38.84, 62.35), "Optional city errand: Roy Lewells in the Cathedral park has a parcel of reading material for the library."),
  finish(97234, sw("Donyal Tovald", 75.05, 30.12), "Take the parcel to Donyal Tovald in the library north of the Dwarven District."),
  accept(97237, sw("Donyal Tovald", 75.05, 30.12)),
  objectiveAt(97237, sw(nil, 76.0, 30.5), "Pick the four books off the shelves around the library rooms.",
    "Trollbane Conquests", "Field Accounts of Horde Razings", "The Forsaken Ally", "Cycles of Morality"),
  finish(97237, sw("Roy Lewells", 38.84, 62.35), "Bring the books back to Roy in the park."),
  taxi("getfp", dungar, "Stormwind, Elwynn", "Learn the Stormwind flight path at the gryphon platform if needed."),
  taxi("fly", ariena, "Lakeshire, Redridge", "Fly or hearth back to Lakeshire with the letters and horseshoes."),
  finish(119, verner), accept(122, verner), accept(124, verner), finish(121, solomon),
  along(objectiveAt(124, rr(nil, 34.5, 31.5),
    "Clear Brutes and Mystics north of the lake. Loot bridge parts from gnolls and scales from any Black Dragon Whelps you pass.",
    "10 Redridge Brutes", "8 Redridge Mystics"), 89, 122),
  along(objectiveAt(89, rr(nil, 33.8, 31.7), "Loot any remaining pikes and rivets from the northern gnolls.",
    "5 Iron Pikes", "5 Iron Rivets"), 122),
  finish(124, verner), finish(89, oslow), accept(98386, oslow),
  along(objectiveAt(98386, rr(nil, 46.5, 37.5),
    "Kill Greater Tarantulas and crush eggs at the mill. Loot Crisp Spider Meat for the goulash, and take condors or whelps you pass.",
    "12 Greater Tarantulas", "6 Tarantula Eggs"), 92, 122),
  finish(98386, oslow),
  action("grind", rr(nil, 33.8, 31.7), "Reach level 18 for the Blackrock pickups. Finish your lake and gnoll quests or try an alternate route.",
    { level = 18, suggest = { "loch-modan", "darkshore" } }),
  accept(20, marris), accept(98387, marris),
  along(action("goto", rr(nil, 65.6, 78.7),
    "Take the road south from Lakeshire, then east along the lake toward Render's Valley. If you still need ingredients or scales, hunt condors, Great Goretusks, tarantulas and Black Dragon Whelps as you pass them."),
    92, 122),
  along(objectiveAt(98387, rr(nil, 68.9, 79),
    "Take weapons from racks and supplies from sacks and barrels. Loot any axes you still need from the Blackrock orcs you clear.",
    "8 Stolen Weapons", "10 Blackrock Supplies"), 20),
  along(objectiveAt(20, rr(nil, 71.1, 83.4),
    "Loot any remaining Battleworn Axes from the Blackrock orcs in the valley. Check the nearby racks and supplies while clearing the camp.",
    "10 Battleworn Axes"), 98387),
  along(objectiveAt(122, rr(nil, 54.6, 76.6),
    "On the road back west, loot any remaining scales from Black Dragon Whelps along the south shore.",
    "6 Underbelly Whelp Scales"), 92),
  along(objectiveAt(92, rr(nil, 28.2, 76.5),
    "Finish any missing goulash ingredients south of the lake. Hunt Dire Condors, Great Goretusks and tarantulas as needed.",
    "5 Tough Condor Meat", "5 Great Goretusk Snouts", "5 Crisp Spider Meat"), 122),
  action("hearth", rr("Innkeeper Brianna", 22, 44.5), "Return to Lakeshire for the turn-ins. If you're walking, follow the lake road west.", { bind = "Lakeshire" }),
  finish(92, breanna), finish(122, verner), finish(98387, marris), finish(20, marris),
}

local function dw(name, x, y) return at(name, x, y, duskwood) end
local felicia = dw("Felicia Maline", 77.49, 44.29)
local trelayne = dw("Innkeeper Trelayne", 73.87, 44.41)
local elaine = dw("Elaine Carevin", 75.34, 48.75)
local althea = dw("Commander Althea Ebonlocke", 73.54, 46.82)
local eva = dw("Madame Eva", 75.79, 45.32)
local sirra = dw("Sirra Von'Indi", 72.62, 47.62)
local grual = dw("Chef Grual", 73.75, 43.48)
local smitts = dw("Tavernkeep Smitts", 73.78, 44.49)
local daltry = dw("Clerk Daltry", 72.54, 46.87)
local mary = dw("Blind Mary", 81.99, 59.09)
local dodds = dw("Watcher Dodds", 45.12, 67.03)
local jitters = dw("Jitters", 18.38, 56.37)
local sven = dw("Sven Yorgen", 7.78, 34.07)
local lars = dw("Lars", 7.71, 33.2)
local abercrombie = dw("Abercrombie", 28.11, 31.46)
local mound = dw("Mound of loose dirt", 49.85, 77.71)
local darkshireHearth = { bind = "Darkshire" }

-- Three Darkshire loops, then a final visit to the north cemetery for Abercrombie.
local dusk = {
  taxi("getfp", felicia, "Darkshire, Duskwood",
    "Learn the flight path from Felicia Maline in Darkshire. From Lakeshire, head west to Three Corners, then south into Duskwood and east to town."),
  action("sethearth", trelayne, "Bind your hearthstone with Innkeeper Trelayne at the Scarlet Raven Tavern.", darkshireHearth),
  accept(163, elaine), accept(164, elaine), accept(165, elaine),
  accept(56, althea), withGuide("legend-of-stalvan", accept(101, eva)), accept(96139, sirra),
  accept(90, grual, "With Cooking 50 or higher, take Chef Grual's kabob order in the house next to the tavern. Buy Stormwind Seasoning Herbs from a cooking supplies vendor."),
  along(objectiveAt(56, dw(nil, 79.5, 70.5), "Go south to Tranquil Gardens Cemetery. Loot Skeleton Fingers from the Warriors and Mages for Madame Eva.",
    "8 Skeletal Warriors", "6 Skeletal Mages"), 101),
  finish(56, althea), accept(57, althea, "Pick up the next Night Watch now. Save its Raven Hill skeletons for the Rot Blossom trip."),
  withItem(281143, accept(96137, nil, "Use Ira's Dagger from your bags. Use Next to leave the hunt for later.")),
  objectiveAt(96137, dw(nil, 55.3, 63.7),
    "Hunt Young Black Ravagers north of Yorgen Farmstead and Black Ravagers by the road near 59.5, 58.3. If the adults are scarce, check Brightwood Grove north of Darkshire on a later pass.",
    "10 Young Black Ravagers", "7 Black Ravagers"),
  accept(245, dodds, "Take the road west out of Darkshire to Watcher Dodds at the crossroads. If you meet a Lost Stalker on the way, it can drop Ira's Dagger."),
  objectiveAt(96139, dw("Memory of Valor", 21.2, 55.7), "Find the Raven Hill Tome on the broken table inside the house.", "Raven Hill Tome"),
  finish(163, jitters, "Follow the road west to Raven Hill. Jitters hides in a house by the road."), accept(5, jitters),
  along(objectiveAt(245, dw(nil, 9.5, 50), "Kill Pygmy Venom Web Spiders in the western woods. Loot Vials of Spider Venom for Eva and save 6 Gooey Spider Legs for Chef Grual's next quest.",
    "15 Pygmy Venom Web Spiders"), 101),
  finish(164, sven, "Deliver the supplies at Sven's Camp on the western border."), accept(95, sven), accept(226, lars),
  along(objectiveAt(226, dw(nil, 22, 26.5), "Hunt Starving and Rabid Dire Wolves on the slopes east of the camp, toward the hermit's shack. Keep their Lean Wolf Flanks for Chef Grual.",
    "12 Starving Dire Wolves", "8 Rabid Dire Wolves"), 90),
  along(objectiveAt(90, dw(nil, 25.4, 27.1), "Loot any Lean Wolf Flanks you still need from the same wolves.", "10 Lean Wolf Flanks"), 226),
  finish(165, abercrombie, "Abercrombie lives in the shack north of the Raven Hill Cemetery."), accept(148, abercrombie),
  finish(245, dodds, "Head south-east back to the crossroads."),
  finish(95, mound, "Go south to Sven's old farm and dig in the mound behind the stump."), accept(230, mound),
  finish(5, grual, "Walk east to Darkshire. Chef Grual is in the house next to the tavern."), accept(93, grual), finish(90, grual),
  finish(148, eva), accept(149, eva), finish(96139, sirra), finish(96137, sirra),
  accept(174, dw("Viktori Prism'Antras", 79.8, 48.02),
    "Buy a Bronze Tube from Herble Baubbletump on the east side of town (78.0, 48.3), then take Viktori's quest next door. Herble's stock is limited."),
  finish(174, dw("Viktori Prism'Antras", 79.8, 48.02), "Give Viktori the Bronze Tube. If Herble had none, use Next to leave this chain."),
  accept(175, dw("Viktori Prism'Antras", 79.8, 48.02)),
  finish(149, mary, "Blind Mary's house is south-east of town."), accept(154, mary),
  finish(175, mary), accept(177, mary),
  objectiveAt(177, dw("Insane Ghoul", 80.9, 72), "Go south to the Tranquil Gardens chapel. The Insane Ghoul is level 26: pull it alone. If it is too strong, use Next here and at Viktori's turn-in.",
    "Mary's Looking Glass"),
  along(objectiveAt(93, dw(nil, 84.4, 52.9), "If you still need spider legs, kill Black Widow Hatchlings north of Mary's house. Loot any missing venom too.",
    "6 Gooey Spider Legs"), 101),
  finish(154, eva), accept(157, eva), finish(93, grual), accept(240, grual),
  finish(177, dw("Viktori Prism'Antras", 79.8, 48.02)),

  action("goto", sven, "Take the west road past Raven Hill to Sven's Camp."),
  finish(230, sven), accept(262, sven), finish(226, lars),
  finish(157, abercrombie), accept(158, abercrombie),
  action("hearth", trelayne, "Take the road east to Darkshire if you're walking.", darkshireHearth),
  finish(262, eva), accept(265, eva), finish(265, daltry), accept(266, daltry),
  finish(158, smitts), accept(156, smitts), finish(266, smitts), accept(453, smitts),

  action("goto", jitters, "Follow the main road west from Darkshire into Raven Hill. Stop at Jitters' house before going north to the cemetery."),
  finish(240, jitters),
  finish(453, jitters, "The jittery stranger the clues describe is Jitters, in Raven Hill."), accept(268, jitters),
  withItem(281147, accept(79362, nil, "Use Grant's Shield from your bags. The Lost Knight ghost that drops it wanders Raven Hill Cemetery.")),
  along(objectiveAt(57, dw(nil, 21, 45), "Clear the southern graves for Skeletal Fiends and Horrors. Loot their Rot Blossoms and any missing Skeleton Fingers. Give Mor'Ladim room to pass.",
    "15 Skeletal Fiends", "15 Skeletal Horrors"), 156, 101, 79362),
  along(objectiveAt(156, dw(nil, 22.3, 45.8), "Loot any remaining Rot Blossoms from the same skeletons.", "8 Rot Blossoms"), 57, 101),
  along(objectiveAt(79362, dw(nil, 22.3, 45.8), "Keep killing the same skeletons until one drops Grant's Mace.", "Grant's Mace"), 57),
  objectiveAt(101, dw(nil, 23.7, 36.5), "Loot fangs from Flesh Eaters and Rotted Ones and any missing fingers from skeletons. Hunt spiders in the western woods for any missing venom.",
    "10 Ghoul Fangs", "10 Skeleton Fingers", "5 Vials of Spider Venom"),
  finish(268, sven), accept(323, sven, "Take Sven's next task now. Its skeletons are tougher: save them for your last trip west."),
  action("hearth", trelayne, "Take the road east to Darkshire if you're walking.", darkshireHearth),
  finish(57, althea), finish(101, eva), finish(79362, sirra),
  finish(156, smitts), accept(159, smitts),
  action("goto", abercrombie, "Take the west road from Darkshire, then head north before Raven Hill to Abercrombie's shack."),
  finish(159, abercrombie), accept(133, abercrombie),
  objectiveAt(133, dw(nil, 23.8, 36.5), "Loot Ghoul Ribs from the ghouls at the north end of the cemetery.", "7 Ghoul Ribs"),
  finish(133, abercrombie),
  objectiveAt(323, dw(nil, 16, 35.5),
    "Go west to the far edge of the cemetery near Sven's camp. Pull Skeletal Raiders, Healers and Warders one at a time and stay clear of Morbent Fel.",
    "15 Skeletal Raiders", "3 Skeletal Healers", "3 Skeletal Warders"),
  finish(323, sven), accept(269, sven),
  action("grind", dw(nil, 23.7, 36.5), "Reach level 26 for Wetlands. Finish open Duskwood quests or run the Stockade with a group. Use Next to travel early if ready.",
    { level = 26, guide = "dungeon-stockade" }),
  withItem(2794, accept(337, nil, "If An Old History Book dropped in Duskwood, read it. The Stormwind library takes it on your way north.")),
  -- A hearth step (done on arrival at Felicia), so the Stormwind turn-ins after it don't mark it as passed.
  action("hearth", felicia, "Hearth or take the east road to return to Darkshire for the flight to Stormwind.", darkshireHearth),
  taxi("fly", dungar, "Stormwind, Elwynn", "Fly from Darkshire to Stormwind."),
  finish(269, sw("Bishop Farthing", 49.93, 45.99), "Bring Jitters' journal to Bishop Farthing in the Cathedral of Light."),
  finish(337, sw("Milton Sheaf", 77.07, 30.21), "Return the history book to Milton Sheaf in the Royal Library of Stormwind Keep."),
}

local function wl(name, x, y) return at(name, x, y, wetlands) end
local howin = wl("Howin Kindfeather", 49.36, 42.13)
local rethiel = wl("Rethiel the Greenwarden", 56.37, 40.4)
local ormer = wl("Ormer Ironbraid", 38.18, 50.89)
local whelgar = wl("Prospector Whelgar", 38.81, 52.39)
local merrin = wl("Merrin Rockweaver", 38.91, 52.34)
local shellei = wl("Shellei Brondir", 9.5, 59.7)
local helbrek = wl("Innkeeper Helbrek", 10.7, 61.0)
local karl = wl("Karl Boran", 8.32, 58.57)
local fitz = wl("First Mate Fitzsimmons", 10.9, 59.64)
local caitlin = wl("Caitlin Grassman", 11.88, 58.82)
local sida = wl("Sida", 11.8, 57.99)
local valstag = wl("Valstag Ironjaw", 10.1, 56.9)
local stoutfist = wl("Captain Stoutfist", 9.86, 57.49)
local tarrel = wl("Tarrel Rockweaver", 11.5, 52.17)
local menethilHearth = { bind = "Menethil Harbor" }

-- Up to 30 in the Wetlands: the Green Belt and Raptor Ridge first, then Menethil Harbor's
-- coast and both wrecks, then one sweep back east past the dig site, Angerfang, Dun Modr,
-- Thelgen Rock and Dragonmaw Retreat, and the south bay last. Ends with the Stormwind turn-ins
-- and the ship to Auberdine. Gap notes: tools/audits/2026-11-10-darkshore-ashenvale-wetlands-gaps.md.
local wet = {
  taxi("fly", dungar, "Stormwind, Elwynn", "Fly from Darkshire to Stormwind."),
  accept(270, sw("Bishop Farthing", 49.95, 46.0),
    "If you brought Jitters' journal to Bishop Farthing, he has orders for Menethil Harbor. Find him in the Cathedral of Light, or use Next."),
  action("goto", nil, "Take the Deeprun Tram from the Dwarven District to Ironforge. Use Next when you arrive."),
  taxi("getfp", at("Gryth Thurden", 55.5, 47.7, ironforge), "Ironforge, Dun Morogh", "Learn the Ironforge flight path from Gryth Thurden."),
  taxi("getfp", at("Thorgrum Borrelson", 33.9, 51.0, lochModan), "Thelsamar, Loch Modan",
    "Leave Ironforge and follow the road east through Dun Morogh into Loch Modan. Learn the Thelsamar flight path."),
  accept(98245, howin, "Take the road north through Dun Algaz into the Wetlands. Howin Kindfeather camps beside the road."),
  accept(98246, howin),
  accept(463, fitz, "Only if you came by ship: First Mate Fitzsimmons on the Menethil docks sends you to Rethiel."),
  finish(463, rethiel, "Rethiel the Greenwarden stands among the trees east of Howin."),
  accept(276, rethiel, "Rethiel the Greenwarden stands among the trees east of Howin."),
  objectiveAt(276, wl(nil, 63, 66.1), "Kill Mosshide Gnolls and Mongrels at the camps to the south-east.", "15 Mosshide Gnolls", "10 Mosshide Mongrels"),
  finish(276, rethiel), accept(277, rethiel),
  objectiveAt(277, wl(nil, 62.8, 57.1), "Loot Crude Flint from the Mosshide Fenrunners south-east of Rethiel.", "9 Crude Flint"),
  finish(277, rethiel), accept(275, rethiel),
  along(objectiveAt(98246, wl(nil, 68.3, 33.0), "Gather eggs at Raptor Ridge. Pull Highland and Elder Razormaws one at a time and loot their incisors.",
    "12 Perfect Razormaw Eggs"), 98245),
  along(objectiveAt(98245, wl(nil, 67.4, 30.8), "Loot any remaining incisors from Razormaws. Check the ground for eggs between pulls.",
    "10 Razormaw Incisors"), 98246),
  finish(98245, howin), finish(98246, howin),

  accept(294, ormer, "Follow the road west to the Whelgar Excavation Site."), accept(299, whelgar),
  objectiveAt(294, wl(nil, 26.3, 46.1), "Kill Mottled Raptors and Screechers in the fields west of the site.", "10 Mottled Raptors", "10 Mottled Screechers"),
  objectiveAt(275, wl(nil, 25.3, 34.3), "Kill Fen Creepers in the marsh north of the raptors.", "Fen Creepers"),
  taxi("getfp", shellei, "Menethil Harbor, Wetlands", "Go west to Menethil Harbor and learn the flight path."),
  action("sethearth", helbrek, "Bind your hearthstone at the Deepwater Tavern.", menethilHearth),
  finish(270, wl("Glorin Steelbrow", 10.59, 60.59), "Glorin Steelbrow waits outside the Deepwater Tavern. Give him the bishop's orders."),
  accept(279, karl), accept(288, fitz), accept(98282, caitlin), accept(470, sida),
  accept(98197, valstag), accept(473, valstag),
  finish(98461, tarrel, "Give Hollee's note to Tarrel Rockweaver."), accept(305, tarrel),
  finish(473, stoutfist, "Captain Stoutfist is upstairs in Menethil Keep."), accept(464, stoutfist), accept(98221, stoutfist),
  accept(484, wl("James Halloran", 8.51, 55.71), "James Halloran by the north gate wants young crocolisk skins. Done already if you ran the coast chapter."),
  forDungeon(accept(95647, caitlin, "Ask Caitlin about Ardin, lost in the Excavation Site."), "dungeon-excavation-site"),
  objectiveAt(288, helbrek, "Buy a Flagon of Mead from Innkeeper Helbrek.", "Flagon of Mead"),
  finish(288, fitz), accept(289, fitz),
  objectiveAt(98197, wl(nil, 12.1, 52.5), "Gather timber and iron from the harbor floor north of town.", "6 Khaz Modan Timber", "30 Khaz Modan Iron"),
  finish(98197, valstag),
  objectiveAt(484, wl(nil, 19.15, 47.12), "Kill Young Wetlands Crocolisks in the marsh channels east of the beach.", "Young Crocolisk Skins"),
  finish(484, wl("James Halloran", 8.51, 55.71), "Bring the skins back to Halloran at the north gate."),
  accept(471, wl("James Halloran", 8.51, 55.71), "Take his next order. The big crocolisks live by the cursed wreck you visit next."),
  objectiveAt(279, wl(nil, 15, 39.2), "Kill Bluegill Murlocs along the coast to the north. Gobbler walks with them near 18, 40.",
    "12 Bluegill Murlocs", "Gobbler's Head"),
  finish(279, karl), accept(281, karl),
  finish(281, wl("Damaged Crate", 13.52, 41.38), "Search the Damaged Crate in the murloc camp."), accept(284, wl("Damaged Crate", 13.52, 41.38)),
  finish(284, wl("Sealed Barrel", 13.6, 38.22), "Clear the murlocs around the Sealed Barrel before you open it."), accept(285, wl("Sealed Barrel", 13.6, 38.22)),
  finish(285, wl("Half-buried Barrel", 13.94, 34.81)), accept(286, wl("Half-buried Barrel", 13.94, 34.81)),
  along(objectiveAt(289, wl(nil, 14.2, 28), "Board the wreck to the north. Kill Cursed Sailors and Marines, and First Mate Snellig for his snuffbox.",
    "13 Cursed Sailors", "5 Cursed Marines", "Snellig's Snuffbox"), 471),
  along(objectiveAt(471, wl(nil, 17.5, 26.2), "Kill Giant Wetlands Crocolisks on the shore east of the wreck. More sit farther east near 23, 22.",
    "6 Giant Crocolisk Skins"), 289),
  finish(286, karl, "Return to Menethil Harbor with the statuette."), accept(98189, karl),
  finish(98189, stoutfist), accept(98190, stoutfist),
  finish(289, fitz), accept(290, fitz),
  finish(471, wl("James Halloran", 8.51, 55.71)),
  accept(98072, wl("James Halloran", 8.51, 55.71), "Halloran also wants scales from the red whelps east of the Green Belt. You pass them on the last eastern loop."),
  forDungeon(accept(98815, wl("James Halloran", 8.51, 55.71), "Ask Halloran about Highland Hides for the Excavation Site."), "dungeon-excavation-site"),
  accept(472, wl("Harlo Barnaby", 10.85, 55.9), "Harlo Barnaby, north of the keep, has a message for Longbraid at Dun Modr on your eastern loop."),
  objectiveAt(290, wl("Captain Halyndor", 15.45, 23.61), "Go north past the cursed wreck to the Intrepid. Climb the rudder and kill Captain Halyndor for his key. He reflects spells for a few seconds at a time.",
    "Intrepid Strongbox Key"),
  finish(290, wl("Intrepid's Locked Strongbox", 14.37, 24.02), "Enter the hole in the side of the hull and open the strongbox."),
  accept(292, wl("Intrepid's Locked Strongbox", 14.37, 24.02)),

  action("goto", merrin, "Head back south-east across the marsh to the Whelgar Excavation Site."),
  finish(305, merrin), accept(306, merrin),
  finish(294, ormer), accept(295, ormer),
  along(objectiveAt(295, wl(nil, 33.9, 47.0), "Kill Mottled Scytheclaws and Razormaws as you search the dig site for tablet fragments.",
    "10 Mottled Scytheclaws", "10 Mottled Razormaws"), 299),
  along(objectiveAt(299, wl(nil, 34.5, 48), "Find any missing tablet fragments in the Ancient Relics and the patch of Loose Soil.",
    "Ados Fragment", "Modr Fragment", "Golm Fragment", "Neru Fragment"), 295),
  finish(299, whelgar),
  finish(295, ormer), accept(296, ormer),
  objectiveAt(296, wl(nil, 33.3, 51.5), "Kill Sarltooth, the level 29 raptor just south of the site, and take his talon.", "Sarltooth's Talon"),
  finish(296, ormer),
  along(objectivePart(98221, 4, wl(nil, 38.46, 46.02), "Burn the Ironforge attack plan on the west side of the camp. Loot banners from the Dragonmaw as you go.",
    "Attack Plan: Ironforge"), 464),
  along(objectivePart(98221, 1, wl(nil, 45.59, 42.60), "Burn the Menethil Harbor attack plan in the north camp.", "Attack Plan: Menethil Harbor"), 464),
  along(objectivePart(98221, 3, wl(nil, 45.42, 45.72), "Burn the Southshore attack plan farther south.", "Attack Plan: Southshore"), 464),
  along(objectivePart(98221, 2, wl(nil, 49.46, 46.81), "Burn the Thelsamar attack plan at the east end of the camp.", "Attack Plan: Thelsamar"), 464),
  along(objectiveAt(464, wl(nil, 45.3, 45.0), "Loot any remaining War Banners from Dragonmaw Raiders and Swamprunners around Angerfang.",
    "8 Dragonmaw War Banners"), 98221),
  accept(98291, howin, "Stop at Howin by the road east of Angerfang. He wants Dragonmaw Retreat cleared at the end of this loop."),
  objectiveAt(470, wl(nil, 44.9, 26.1), "Kill the oozes at Ironbeard's Tomb to the north until one drops Sida's bag.", "Sida's Bag"),
  finish(472, wl("Longbraid the Grim", 49.8, 18.26), "Follow the road north to the dwarf camp outside Dun Modr and give Longbraid Harlo's message."),
  accept(631, wl("Rhag Garmason", 49.92, 18.21), "Rhag Garmason, in the same camp, wants news of Ol' Rustlocke on the Thandol Span."),
  finish(631, wl("Ebenezer Rustlocke's Corpse", 51.28, 7.95),
    "Walk north onto the bridge, take the doorway and the stairs down to Rustlocke's body. Two elite Dark Iron saboteurs guard the room: slow or stun them, read the body and leave."),
  accept(632, wl("Ebenezer Rustlocke's Corpse", 51.28, 7.95)),
  finish(632, wl("Rhag Garmason", 49.92, 18.21), "Take the parchment back to Rhag at the camp."),
  accept(633, wl("Rhag Garmason", 49.92, 18.21)),
  objectiveAt(633, at("Cache of Explosives", 48.8, 88.0, 1417),
    "Jump off the bridge into the river. Loot the Waterlogged Letter in the water near the Arathi shore, then climb the path east to the Dark Iron cache and destroy it.",
    "Cache of Explosives Destroyed"),
  withItem(4433, accept(637, at("Waterlogged Letter", 44.3, 92.9, 1417), "Open the Waterlogged Envelope from the river to start Sully Balloo's letter for Ironforge.")),
  finish(633, wl("Rhag Garmason", 49.92, 18.21), "Swim back under the bridge and return to Rhag. Plea To The Alliance, his next quest, goes into Arathi; leave it for later."),
  objectiveAt(98282, wl(nil, 48.7, 62.4), "Collect an Unruptured Stalker Gland from the stalkers in Thelgen Rock, the cave south of the road."),
  finish(275, rethiel),
  forDungeon(accept(95646, rethiel, "Take Rethiel's task for the Highland Horror inside the Excavation Site."), "dungeon-excavation-site"),
  accept(98293, wl("Dragonmaw Armaments", 58.8, 45.1), "Pick up the Dragonmaw Armaments lying at the west edge of Dragonmaw Retreat, south-east of Rethiel."),
  along(objectiveAt(98291, wl(nil, 64.5, 46.3), "Work east through Dragonmaw Retreat. Kill Reclaimers, Soulbinders and Infiltrators and pull them one at a time.",
    "8 Dragonmaw Reclaimers", "5 Dragonmaw Soulbinders", "3 Dragonmaw Infiltrators"), 98293, 98072),
  along(objectiveAt(98293, wl(nil, 63.5, 45.8), "Pick up the armaments lying around the camp between fights.", "30 Dragonmaw Armaments"), 98291, 98072),
  along(objectiveAt(98072, wl(nil, 63.0, 41.8), "Kill the red whelps on the slope north of the retreat for Pristine Crimson Scales.", "8 Pristine Crimson Scales"),
    98291, 98293),
  finish(98291, howin, "Take the road west back to Howin."),
  action("hearth", helbrek, "The next turn-ins are in Menethil Harbor.", menethilHearth),
  finish(292, wl("Glorin Steelbrow", 10.59, 60.59), "Bring the Eye of Paleth to Glorin outside the tavern."),
  accept(293, wl("Glorin Steelbrow", 10.59, 60.59), "Take the Eye on to the Archbishop in Stormwind."),
  accept(321, wl("Glorin Steelbrow", 10.59, 60.59), "Glorin wants the wreck of the Flying Osprey searched."),
  finish(306, tarrel), finish(464, stoutfist), finish(98221, stoutfist), finish(98293, stoutfist), finish(470, sida), finish(98282, caitlin),
  finish(98072, wl("James Halloran", 8.51, 55.71)),
  accept(98208, wl("Sylessa Duskwhisper", 7.92, 55.82), "Sylessa Duskwhisper, by the west docks, lost something in the bay south of town."),
  finish(321, wl("Waterlogged Chest", 12.1, 64.17), "Wade out to the wreck of the Flying Osprey in the bay south of town and open the Waterlogged Chest."),
  accept(324, wl("Waterlogged Chest", 12.1, 64.17)),
  along(objectiveAt(98208, wl("Nord'el", 12.22, 63.74), "Pick up Nord'el beside the chest.", "Nord'el"), 324),
  along(objectiveAt(324, wl(nil, 10.5, 67.4), "Kill Bluegill Raiders along the south shore for Lightforge Ingots.", "5 Lightforge Ingots"), 98208),
  finish(324, wl("Glorin Steelbrow", 10.59, 60.59), "Return to Glorin with the ingots."),
  accept(322, wl("Glorin Steelbrow", 10.59, 60.59), "Take the crate of ingots for Stormwind."),
  finish(98208, wl("Sylessa Duskwhisper", 7.92, 55.82)),
  accept(98209, wl("Sylessa Duskwhisper", 7.92, 55.82), "Sylessa asks you to carry Nord'el to Thundris Windweaver in Auberdine. You take the ship there at the end."),
  taxi("fly", at("Gryth Thurden", 55.5, 47.7, ironforge), "Ironforge, Dun Morogh", "Fly to Ironforge. If you have reached level 30, train your new spells here."),
  finish(637, at("Sara Balloo", 63.48, 67.29, ironforge), "Give Sully's letter to Sara Balloo in the Mystic Ward."),
  forDungeon(accept(971, at("Gerrig Bonegrip", 50.83, 5.62, ironforge), "Gerrig Bonegrip in the Forlorn Cavern wants a manuscript from Blackfathom Deeps."),
    "dungeon-blackfathom-deeps"),
  finish(322, sw("Grimand Elmore", 59.71, 33.74), "Take the Deeprun Tram to Stormwind and deliver the ingots to Grimand Elmore in the Dwarven District."),
  accept(325, sw("Grimand Elmore", 59.71, 33.74), "Take Morbent's Bane for Sven. Morbent Fel is level 32: keep it for after 30."),
  finish(98190, sw("Highlord Bolvar Fordragon", 80.21, 38.35), "Give the statuette to Highlord Bolvar in Stormwind Keep."),
  accept(98191, sw("Highlord Bolvar Fordragon", 80.21, 38.35), "Bolvar sends the statuette on to Lord Grayson Shadowbreaker in the Cathedral."),
  finish(293, sw("Archbishop Benedictus", 50.3, 45.5), "Bring the Eye to Archbishop Benedictus in the Cathedral of Light."),
  withGuide("missing-diplomat", finish(98191, sw("Lord Grayson Shadowbreaker", 48.43, 50.22),
    "Lord Grayson Shadowbreaker stands in the Cathedral's paladin hall. Thomas, in the same Cathedral, starts The Missing Diplomat from level 28.")),
  accept(98219, sw("Lord Grayson Shadowbreaker", 48.43, 50.22), "From level 30, Grayson sends you to Lieutenant Farren Orinelle in Southshore. Take it if you are going there."),
  forDungeon(accept(3765, sw("Argos Nightwhisper", 36.24, 67.61), "Argos Nightwhisper sends Blackfathom groups to Auberdine. You are going there next."),
    "dungeon-blackfathom-deeps"),
  action("boat", sw(nil, 21.8, 56.8), "Board the Auberdine ship at the southernmost harbor dock. Use Next when you reach Auberdine.",
    { name = "Stormwind Harbor - Auberdine" }),
  forDungeon(finish(3765, at("Gershala Nightwhisper", 38.33, 43.04, 1439)), "dungeon-blackfathom-deeps"),
  forDungeon(accept(1275, at("Gershala Nightwhisper", 38.33, 43.04, 1439), "Take Gershala's brain stem request for Blackfathom Deeps."),
    "dungeon-blackfathom-deeps"),
  finish(98209, at("Thundris Windweaver", 37.4, 40.13, 1439), "Give Nord'el to Thundris Windweaver in the house north of the Auberdine inn."),
}

-- Dwarf and Gnome start, levels 1-12. Source notes: tools/audits/2026-11-08-dun-morogh.md.
-- Paste after the helpers (objectiveAt, taxi) so `dungar` and `furlbrow` already exist.
-- Two main-chunk locals (dunMorogh, dm): the places live inside a builder function because the
-- main chunk is near Lua 5.1's 200-local limit.
local dunMorogh = 1426

q(179, "Dwarven Outfitters", 1, 1)
q(170, "A New Threat", 2, 1, 179)
q(233, "Coldridge Valley Mail Delivery", 3, 1, 179)
q(234, "Coldridge Valley Mail Delivery", 4, 1, 233)
q(183, "The Boar Hunter", 3, 1)
q(182, "The Troll Cave", 4, 1)
q(218, "The Stolen Journal", 5, 1, 182)
q(282, "Senir's Observations", 5, 1, 218)
q(420, "Senir's Observations", 5, 1, 282)
q(2160, "Supplies to Tannok", 5, 1)
q(3361, "A Refugee's Quandary", 3, 3)
q(3364, "Scalding Mornbrew Delivery", 5, 4)
q(3365, "Bring Back the Mug", 5, 4, 3364)
q(97277, "Grund and Gozwin", 6, 4, nil, true)
q(96628, "The Adventurer", 6, 4, 282, true)
q(96608, "The Great Outdoors", 6, 4, 96628, true)
q(3106, "Simple Rune", 1, 1, 179, nil, "WARRIOR")
q(3107, "Consecrated Rune", 1, 1, 179, nil, "PALADIN")
q(3108, "Etched Rune", 1, 1, 179, nil, "HUNTER")
q(3109, "Encrypted Rune", 1, 1, 179, nil, "ROGUE")
q(3110, "Hallowed Rune", 1, 1, 179, nil, "PRIEST")
q(98581, "Archaic Rune", 1, 1, 179, true, "SHAMAN")
q(3112, "Simple Memorandum", 1, 1, 179, nil, "WARRIOR")
q(3113, "Encrypted Memorandum", 1, 1, 179, nil, "ROGUE")
q(3114, "Glyphic Memorandum", 1, 1, 179, nil, "MAGE")
q(3115, "Tainted Memorandum", 1, 1, 179, nil, "WARLOCK")
q(98574, "Hallowed Memorandum", 1, 1, 179, true, "PRIEST")
-- Runes are Dwarf letters (requiredRaces 4), memoranda Gnome letters (requiredRaces 64).
for _, id in ipairs({ 3106, 3107, 3108, 3109, 3110, 98581 }) do quest[id].race = "DWARF" end
for _, id in ipairs({ 3112, 3113, 3114, 3115, 98574 }) do quest[id].race = "GNOME" end

q(400, "Tools for Steelgrill", 5, 2)
q(317, "Stocking Jetsteam", 6, 2)
q(318, "Evershine", 7, 2, 317)
q(319, "A Favor for Evershine", 8, 2, 318)
q(320, "Return to Bellowfiz", 8, 2, 319)
q(5541, "Ammo for Rumbleshot", 6, 5)
q(312, "Tundra MacGrann's Stolen Stash", 12, 7)
q(313, "The Grizzled Den", 7, 4)
q(384, "Beer Basted Boar Ribs", 7, 5)
q(98321, "Flintfire's Shipment", 7, 4, nil, true)
q(98322, "Secure the Mountain", 8, 4, nil, true)
q(98319, "Secure the Mountain", 8, 4, 98322, true)
q(98323, "Secure the Mountain", 8, 4, 98319, true)
q(98326, "Frosthowl", 9, 5, nil, true)
q(287, "Frostmane Hold", 9, 7, 420)
q(291, "The Reports", 10, 1, 287)
q(412, "Operation Recombobulation", 10, 7)
q(315, "The Perfect Stout", 9, 5)
q(413, "Shimmer Stout", 10, 8, 315)
q(99158, "Dawn in the Mountains", 8, 5, nil, true)
q(99159, "Finding Warmth", 8, 5, nil, true)
q(99160, "Rime's Wrath", 8, 5, 99159, true)
q(99161, "Rime's Wrath", 8, 5, 99160, true)
q(99162, "Treacherous Cold", 8, 5, 99159, true)
q(95212, "Never Saddle on Quality", 10, 7, nil, true)
q(96408, "A Visitor to Dun Morogh", 13, 9, nil, true)
q(96392, "Farsen's Watch", 13, 9, nil, true)
q(96390, "Nip 'Em in the Bud", 13, 9, 96392, true)
q(96391, "Underground Map", 15, 9, nil, true)
quest[96391].startItem = 274268
q(432, "Those Blasted Troggs!", 9, 5)
q(433, "The Public Servant", 11, 6)
q(95213, "Stolen Blasting Powder", 10, 7, nil, true)
quest[95213].startItem = 268548
q(95214, "Stolen Blasting Powder", 10, 7, 95213, true)
q(419, "The Lost Pilot", 10, 8)
q(417, "A Pilot's Revenge", 11, 8, 419)
q(96629, "Camping 101: Cooking", 6, 4, 96608, true)
q(96056, "Camping 101: Skinning", 6, 4, 96608, true)
quest[96056].optional = true
q(314, "Protecting the Herd", 12, 6)
-- Deeprun Tram errands; Loch Modan reuses 6661 for players arriving by tram.
q(6661, "Deeprun Rat Roundup", 12, 10)
q(6662, "Me Brother, Nipsy", 12, 10, 6661)

-- One main-chunk local for the whole start: dm.coldridge, dm.kharanos, dm.sources.
local dm = (function()
  local function dm(name, x, y) return at(name, x, y, dunMorogh) end
  local sten = dm("Sten Stoutarm", 29.93, 71.2)
  local balir = dm("Balir Frosthammer", 29.71, 71.25)
  local talin = dm("Talin Keeneye", 22.6, 71.43)
  local grelin = dm("Grelin Whitebeard", 25.08, 75.71)
  local nori = dm("Nori Pridedrift", 24.98, 75.96)
  local durnan = dm("Durnan Furcutter", 28.77, 66.37)
  local felix = dm("Felix Whindlebolt", 28.55, 67.64)
  local grund = dm("Grund Drokda", 28.7, 67.5)
  local thalos = dm("Mountaineer Thalos", 33.48, 71.84)
  local hands = dm("Hands Springsprocket", 33.85, 72.24)
  local thran = dm("Thran Khorman", 28.83, 67.24)
  local bromos = dm("Bromos Grummner", 28.83, 68.33)
  local thorgas = dm("Thorgas Grimson", 29.18, 67.45)
  local solm = dm("Solm Hargrin", 28.37, 67.51)
  local branstock = dm("Branstock Khalder", 28.6, 66.39)
  local teo = dm("Teo Hammerstorm", 28.79, 66.18)
  local marryk = dm("Marryk Nurribit", 28.71, 66.37)
  local alamar = dm("Alamar Grimm", 28.65, 66.14)
  local coldridgeTrainers = {
    { "WARRIOR", thran }, { "PALADIN", bromos }, { "HUNTER", thorgas }, { "ROGUE", solm },
    { "PRIEST", branstock }, { "SHAMAN", teo }, { "MAGE", marryk }, { "WARLOCK", alamar },
  }

  local senir = dm("Senir Whitebeard", 46.73, 53.83)
  local eric = dm("Eric Brighthammer", 46.65, 53.88)
  local tannok = dm("Tannok Frosthammer", 47.22, 52.19)
  local belm = dm("Innkeeper Belm", 47.4, 52.5)
  local ragnar = dm("Ragnar Thunderbrew", 46.83, 52.36)
  local tognus = dm("Tognus Flintfire", 45.34, 51.94)
  local maxan = dm("Maxan Anvol", 47.34, 52.19)
  local razzle = dm("Razzle Sprysprocket", 45.85, 49.37)
  local tharek = dm("Tharek Blackstone", 46.02, 51.68)
  local beldin = dm("Beldin Steelgrill", 50.44, 49.09)
  local bellowfiz = dm("Pilot Bellowfiz", 49.43, 48.41)
  local stonegear = dm("Pilot Stonegear", 49.62, 48.61)
  local loslor = dm("Loslor Rudge", 50.08, 49.42)
  local gretchen = dm("Mountaineer Gretchen", 44.05, 57.04)
  local hegnar = dm("Hegnar Rumbleshot", 40.68, 65.13)
  local rejold = dm("Rejold Barleybrew", 30.19, 45.73)
  local gretta = dm("Gretta Ganter", 31.53, 44.65)
  local macgrann = dm("Tundra MacGrann", 34.57, 51.65)
  local gavin = dm("Father Gavin", 57.73, 44.88)
  local rudra = dm("Rudra Amberstill", 63.08, 49.85)
  local farsen = dm("Earthseer Farsen", 64.83, 58.44)
  local stonebrow = dm("Foreman Stonebrow", 69.08, 56.33)
  local mehr = dm("Senator Mehr Stonehallow", 68.67, 55.97)
  local thesten = dm("Quarrymaster Thesten", 69.16, 54.8)
  local barleybrew = dm("Mountaineer Barleybrew", 86.28, 48.81)
  local hammerfoot = dm("Pilot Hammerfoot", 83.89, 39.19)
  local corpse = dm("A Dwarven Corpse", 79.67, 36.17)
  local den = dm(nil, 41.8, 48.5)
  local kharanosHearth = { bind = "Thunderbrew Distillery" }
  local kharanosTrainers = {
    { "WARRIOR", dm("Granis Swiftaxe", 47.4, 52.6) },
    { "PALADIN", dm("Azar Stronghammer", 47.6, 52.1) },
    { "HUNTER", dm("Grif Wildheart", 45.8, 53.0) },
    { "ROGUE", dm("Hogral Bakkan", 47.6, 52.6) },
    { "PRIEST", maxan },
    { "SHAMAN", dm("Ingrid Dunwald", 47.54, 51.96) },
    { "MAGE", dm("Magis Sparkmantle", 47.5, 52.1) },
    { "WARLOCK", dm("Gimrizz Shadowcog", 47.3, 53.7) },
  }

  local coldridge = {
    accept(179, sten, "Accept from Sten Stoutarm outside Anvilmar."),
    objectiveAt(179, dm(nil, 28.1, 74.3), "Kill Ragged Young Wolves south of Anvilmar for their meat.", "8 Tough Wolf Meat"),
    finish(179, sten), accept(170, balir), accept(233, sten),
    accept(3106, sten), finish(3106, thran, "Read the rune and find Thran Khorman inside Anvilmar."),
    accept(3107, sten), finish(3107, bromos, "Read the rune and find Bromos Grummner inside Anvilmar."),
    accept(3108, sten), finish(3108, thorgas, "Read the rune and find Thorgas Grimson inside Anvilmar."),
    accept(3109, sten), finish(3109, solm, "Read the rune and find Solm Hargrin inside Anvilmar."),
    accept(3110, sten), finish(3110, branstock, "Read the rune and find Branstock Khalder inside Anvilmar."),
    accept(98581, sten), finish(98581, teo, "Read the rune and find Teo Hammerstorm inside Anvilmar."),
    accept(3112, sten), finish(3112, thran, "Read the memo and find Thran Khorman inside Anvilmar."),
    accept(3113, sten), finish(3113, solm, "Read the memo and find Solm Hargrin inside Anvilmar."),
    accept(3114, sten), finish(3114, marryk, "Read the memo and find Marryk Nurribit inside Anvilmar."),
    accept(3115, sten), finish(3115, alamar, "Read the memo and find Alamar Grimm inside Anvilmar."),
    accept(98574, sten), finish(98574, branstock, "Read the memo and find Branstock Khalder inside Anvilmar."),
    action("train", nil, "Visit your class trainer inside Anvilmar. Train spells for level", { level = 2 }),
    along(finish(233, talin, "Take the mail west to Talin. Kill regular Rockjaw Troggs south of Anvilmar and Burly Rockjaw Troggs closer to his camp."), 170),
    accept(183, talin), accept(234, talin),
    along(objectiveAt(183, dm(nil, 22.7, 72.9), "Kill Small Crag Boars around Talin's camp. Finish any Burly Troggs nearby.", "12 Small Crag Boars"), 170),
    finish(183, talin),
    objectiveAt(170, dm(nil, 24.5, 74.2), "Finish any Burly Troggs on the way to Grelin. Regular Rockjaw Troggs also spawn nearby at 25.9, 75.5.",
      "6 Rockjaw Troggs", "6 Burly Rockjaw Troggs"),
    finish(234, grelin, "Go south-east to Grelin Whitebeard by the troll cave."),
    accept(182, grelin),
    objectiveAt(182, dm(nil, 24.4, 78.4), "Kill Frostmane Troll Whelps around the cave.", "14 Frostmane Troll Whelps"),
    finish(182, grelin), accept(218, grelin),
    accept(3364, nori, "Accept from Nori next to Grelin. You have five minutes, so run straight to Anvilmar."),
    finish(3364, durnan, "Run north to Durnan Furcutter inside Anvilmar before the mug cools."),
    accept(3365, durnan),
    finish(170, balir), accept(3361, felix),
    action("train", nil, "Train spells for level", { level = 4 }),
    finish(3365, nori, "Bring the mug back to Nori on your way to the troll cave."),
    along(objectiveAt(3361, dm(nil, 20.9, 76.1), "Pick up Felix's box (20.9, 76.1) and chest (22.8, 80.0) outside, then take the bolts (26.3, 79.3) on the way into Grik'nir's cave.",
      "Felix's Box", "Felix's Chest", "Felix's Bucket of Bolts"), 218),
    along(objectiveAt(218, dm(nil, 30.5, 80.2), "Fight through the cave to Grik'nir the Cold at the east end and loot the journal.",
      "Grelin Whitebeard's Journal"), 3361),
    finish(218, grelin), accept(282, grelin),
    finish(3361, felix, "Return to Felix inside Anvilmar."),
    accept(97277, grund, "Accept from Grund Drokda inside Anvilmar."),
    objectiveAt(97277, dm(nil, 27.3, 62.9), "Climb the hills north-west of Anvilmar to Gozwin's camp. Take the log and kill the prowler.",
      "Gozwin's Mechanic's Log", "Snow Leopard Prowler"),
    finish(97277, grund),
    finish(282, thalos, "Go east to Mountaineer Thalos at the tunnel out of the valley."),
    accept(420, thalos), accept(96628, thalos), accept(2160, hands),
  }

  local kharanos = {
    action("goto", dm(nil, 44.5, 57.5), "Go through the tunnel and follow the road north-east toward Kharanos."),
    finish(420, senir, "Senir Whitebeard waits beside the Kharanos road."), finish(96628, eric),
    accept(96608, eric),
    objectiveAt(96608, eric, "Sit at Eric's campfire until you get Boosted Rest.", "Boosted Rest"),
    finish(96608, eric), accept(96629, eric),
    accept(96056, eric, "If you know Skinning, ask Eric for the skinning lesson too. It ends with Balthus Stoneflayer in Ironforge once your Skinning reaches 20."),
    accept(98322, senir),
    finish(2160, tannok, "Tannok Frosthammer is inside the Thunderbrew Distillery."),
    action("sethearth", belm, "Bind your hearthstone with Innkeeper Belm in the Thunderbrew Distillery.", kharanosHearth),
    finish(96629, dm("Gremlock Pilsnor", 47.67, 52.31), "Speak to Gremlock in the distillery about Cooking."),
    accept(384, ragnar), accept(99158, maxan), accept(98321, tognus),
    accept(400, tharek),
    action("train", nil, "Visit your class trainer in Kharanos. Train spells for level", { level = 6 }),
    finish(400, beldin, "Bring the tools east to Steelgrill's Depot."),
    accept(317, bellowfiz), accept(313, stonegear), accept(5541, loslor),
    finish(98322, gretchen, "Head south-west to Mountaineer Gretchen."), accept(98319, gretchen),
    along(objectiveAt(5541, dm(nil, 44.1, 57.0), "Take the ammo from the crate at Gretchen's camp. Loot any boars and bears you pass on the road.", "Rumbleshot's Ammo"), 317, 384),
    along(objectiveAt(317, dm(nil, 45.0, 60.5), "Hunt Crag Boars for meat and ribs, and Young Black Bears for fur, south of Kharanos.",
      "4 Chunks of Boar Meat", "2 Thick Bear Furs"), 384, 5541),
    along(finish(5541, hegnar, "Follow the road south-west to Hegnar Rumbleshot's camp. Loot any Crag Boars you pass for ribs."), 384),
    objectiveAt(384, belm, "Loot ribs from Crag Boars on the way back north (45, 64), then buy a Rhapsody Malt from Innkeeper Belm.",
      "6 Crag Boar Ribs", "Rhapsody Malt"),
    finish(384, ragnar), finish(317, bellowfiz), accept(318, bellowfiz),
    accept(287, senir), accept(412, razzle),
    action("train", nil, "Train spells for level", { level = 8 }),

    finish(318, rejold, "Follow the road west to Brewnall Village by the frozen lake."),
    accept(319, rejold), accept(315, rejold), accept(98326, gretta),
    objectiveAt(287, dm(nil, 23.6, 51.7), "Go south-west to Frostmane Hold. Explore the cave and kill Headhunters.",
      "Explore Frostmane Hold", "5 Frostmane Headhunters"),
    objectiveAt(412, dm(nil, 25.4, 43.1), "Kill Leper Gnomes west of Brewnall for cogs and gears. More stand to the north (26.6, 37.2).",
      "8 Restabilization Cogs", "8 Gyromechanic Gears"),
    objectiveAt(319, dm(nil, 34.7, 35.1), "Hunt Ice Claw Bears, Elder Crag Boars and Snow Leopards in the hills north-east of Brewnall.",
      "6 Ice Claw Bears", "8 Elder Crag Boars", "8 Snow Leopards"),
    objectiveAt(315, dm(nil, 41.7, 35.4), "Take Shimmerweed from the baskets at the Frostmane camp. Seers drop it too.", "6 Shimmerweed"),
    along(action("goto", den, "Go south to the Grizzled Den. Kill wendigos and collect shipment crates on the way in."), 313, 98321, 98319),
    along(objectiveAt(313, den, "Loot manes from wendigos as you pick up crates and look for Cornelius.", "8 Wendigo Manes"), 98321, 98319, 98326),
    along(objectiveAt(98321, den, "Pick up any remaining shipment crates from the mouth of the den to the back.", "8 Flintfire Shipments"), 313, 98319, 98326),
    along(objectiveAt(98319, den, "Search the den for Mountaineer Cornelius.", "Find Mountaineer Cornelius"), 313, 98321, 98326),
    along(objectiveAt(98326, dm(nil, 39.3, 48.8), "Kill Frosthowl at the west end of the den and take the sack.", "Sack of Fish"), 313, 98321),
    accept(312, macgrann, "Head west from the den. Climb to Tundra MacGrann's ledge from the east."),
    objectiveAt(312, dm("MacGrann's Meat Locker", 38.51, 53.93),
      "Wait outside until Old Icebeard patrols away. Loot the locker in his cave and leave. Skip this quest if you cannot get in safely.",
      "MacGrann's Dried Meats"),
    finish(312, macgrann),
    finish(319, rejold, "Return west to Brewnall Village."), accept(320, rejold),
    finish(315, rejold), accept(413, rejold), finish(98326, gretta),
    finish(98319, gretchen, "Head back east to Mountaineer Gretchen."), accept(98323, gretchen),
    finish(98323, senir), finish(287, senir), accept(291, senir),
    finish(313, stonegear), finish(320, bellowfiz), finish(98321, tognus), finish(412, razzle),
    accept(96408, beldin),
    action("train", nil, "Train spells for level", { level = 10 }),

    finish(99158, gavin, "Follow the road east and climb to Misty Pine Refuge."), accept(99159, gavin),
    objectiveAt(99159, dm(nil, 56.4, 46.7), "Gather firewood from the fallen logs on the slopes south and west of the refuge.", "14 Mostly Dry Firewood"),
    finish(99159, gavin), accept(99160, gavin), accept(99162, gavin),
    along(objectiveAt(99160, dm(nil, 54.9, 45.1), "Kill Minor Ice Elementals west of the refuge. Check the nearby ledge at 52.1, 44.0 for Coalbeard's rifle.",
      "10 Minor Ice Elementals"), 99162),
    objectiveAt(99162, dm(nil, 52.1, 44.0), "Find the three rifles: Coalbeard's here, Stoneanvil's south (53.2, 58.8), Sunhammer's east (59.9, 50.1).",
      "Coalbeard's Rifle", "Stoneanvil's Rifle", "Sunhammer's Rifle"),
    finish(99160, gavin), accept(99161, gavin),
    objectiveAt(99161, dm(nil, 58.3, 42.1), "Kill Avala north of the refuge and take its core.", "Avala's Core"),
    finish(99161, gavin), finish(99162, gavin),
    accept(95212, rudra, "Go east to Amberstill Ranch."),
    accept(314, rudra, "Take Rudra's bounty on Vagash too. Save the fight for your return to the ranch."),
    finish(96408, farsen, "Climb to Farsen's campsite above Gol'Bolar Quarry."),
    accept(96392, farsen),
    objectiveAt(96392, farsen, "Ask Farsen for his far sight. Press Escape once the objective updates."),
    finish(96392, farsen), accept(96390, farsen),
    accept(432, stonebrow), accept(433, mehr),
    along(objectiveAt(432, dm(nil, 71.4, 53.9), "Kill Rockjaw Skullthumpers around the quarry and Bonesnappers toward its eastern edge.",
      "6 Rockjaw Skullthumpers"), 433),
    along(objectiveAt(433, dm(nil, 73.2, 54.0), "Finish Bonesnappers east of the quarry. Loot troggs you fight for the Empty Powder Keg.",
      "10 Rockjaw Bonesnappers"), 432),
    finish(432, stonebrow, "Return to Gol'Bolar Quarry."), finish(433, mehr),
    withItem(268548, accept(95213, thesten, "Use the Empty Powder Keg you looted to start the quest.")),
    finish(95213, thesten), accept(95214, thesten),
    objectiveAt(95214, dm(nil, 76.0, 57.5), "Loot powder from Rockjaw Ambushers and Backbreakers on the way to Helm's Bed Lake.", "16 Stolen Blasting Powder"),
    along(objectiveAt(96390, dm(nil, 77.6, 61.5),
      "Kill and loot Dark Iron Spies by Helm's Bed Lake. Hunt Elder Snow Leopards on the lakeshore as you pass them.",
      "10 Dark Iron Spies"), 95212),
    withItem(274268, accept(96391, dm(nil, 77.6, 61.5), "Use the Dark Iron Map you looted to start the quest.")),
    along(objectiveAt(95212, dm(nil, 78.0, 60.4), "Loot any remaining Pristine Leopard Pelts from Elder Snow Leopards around the lake.",
      "6 Pristine Leopard Pelts"), 96390),
    finish(413, barleybrew, "Follow the road north-east to Mountaineer Barleybrew at South Gate Outpost."),
    accept(419, hammerfoot, "Head north to Pilot Hammerfoot at North Gate Outpost."),
    finish(419, corpse, "Find the dwarven corpse west of Hammerfoot."), accept(417, corpse),
    objectiveAt(417, dm(nil, 78.3, 37.8), "Kill Mangeclaw nearby and take his claw.", "Mangy Claw"),
    finish(417, hammerfoot),
    finish(95214, thesten, "Return to Quarrymaster Thesten at Gol'Bolar Quarry."),
    finish(96390, farsen), finish(96391, farsen), finish(95212, rudra),
    objectiveAt(314, dm("Vagash", 62.6, 46.0),
      "Vagash, a tough level 11 beast, prowls the slope just north of the ranch. Pull him south to the ranch guards and do most of the damage yourself. Use Next if he is too strong.",
      "Fang of Vagash"),
    finish(314, rudra),
    action("grind", dm(nil, 71.4, 53.9), "Reach level 12 for Westfall, or head east into Loch Modan. If staying here, finish available solo quests before grinding.",
      { level = 12, suggest = { "loch-modan" } }),
    action("hearth", belm, "Take the road west to Kharanos if you're walking.", kharanosHearth),
    action("train", nil, "Train spells for level", { level = 12 }),
    finish(291, at("Senator Barin Redstone", 39.55, 57.49, ironforge), "Follow the road north into Ironforge and find Senator Barin Redstone in the High Seat."),
    taxi("getfp", at("Gryth Thurden", 55.5, 47.7, ironforge), "Ironforge, Dun Morogh", "Learn the Ironforge flight path from Gryth Thurden."),
    finish(96056, at("Balthus Stoneflayer", 39.86, 32.5, ironforge), "With Skinning 20, see Balthus Stoneflayer, the Ironforge skinning trainer, for the camping recipe."),
    accept(6661, nil, "Enter the Deeprun Tram from Tinker Town. Monty stands on the Ironforge platform: take his Rat Catcher's Flute."),
    objectiveAt(6661, nil, "Play the flute next to the Deeprun Rats on the platform and along the tracks, then lead five of them back to Monty.",
      "5 Rats Captured"),
    finish(6661, nil, "Give Monty the rats and his flute back."),
    accept(6662, nil, "Take Monty's carton of meat for his brother on the Stormwind side."),
    action("goto", nil, "Ride the Deeprun Tram to Stormwind for Westfall. Use Next when you arrive.",
      { suggest = { "loch-modan" } }),
    finish(6662, nil, "Give the carton to Nipsy on the Stormwind platform before you leave the tram."),
    taxi("getfp", dungar, "Stormwind, Elwynn", "Learn the Stormwind flight path from Dungar above the Trade District."),
    action("goto", at(nil, 59.95, 19.36, westfall), "Leave Stormwind by the main gate and follow the road through Goldshire. Cross the bridge west into Westfall and continue to the Furlbrow farm."),
  }

  local sources = {
    "https://bindonforever.com/zones/dun-morogh",
    "https://forg.gg/en/forever/zones/dun-morogh",
    "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }
  return { coldridge = withTrainers(coldridge, coldridgeTrainers), kharanos = withTrainers(kharanos, kharanosTrainers),
    sources = sources }
end)()

-- Skyborne (High Order, Alliance) start: Zephras Isle 1-13, then the skycutter to Dalaran and
-- the portal to Stormwind. Source notes: tools/audits/2026-11-08-zephras-isle.md.
-- Paste after the `forDungeon` helper (needs at, q, quest, action, accept, finish, objectiveAt,
-- taxi, withItem, withTrainers, dungar, westfall). Everything lives in `zi` to save main-chunk
-- locals (Lua 5.1 allows 200).

-- (a) map constants
local zephras = 2521
local zi = {}
function zi.at(name, x, y) return at(name, x, y, zephras) end

-- (b) Quest levels and minimums from QuestieDB Forever. Chains use the High Order branch.
q(92460, "Coming of Age", 1, 1, nil, true)
q(92461, "Harmony in Balance", 1, 1, 92460, true)
q(92462, "Infestation Investigation", 2, 1, 92460, true)
q(92463, "The Cirrusfly Queen", 3, 2, 92462, true)
q(94414, "The Anchors of Zephras", 2, 2, nil, true)
q(92474, "Falling With Style", 2, 2, nil, true)
q(92481, "A Student of the Arcane", 2, 2, 92461, true, "MAGE")
q(92482, "The Way of the Hunter", 2, 2, 92461, true, "HUNTER")
q(92483, "At Home in the Shadows", 2, 2, 92461, true, "ROGUE")
q(92485, "A Student of Nature", 2, 2, 92461, true, "DRUID")
q(92532, "The Warrior's Path", 2, 2, 92461, true, "WARRIOR")
q(92464, "Elemental Unrest", 3, 2, 92474, true)
q(92465, "Agitators", 3, 2, 92464, true)
q(92469, "Return to Rorian", 4, 3, 92465, true)
q(92471, "Aetheen of the Gales", 4, 4, 92469, true)
q(92470, "Foul Matriarch", 5, 2, 92471, true)
q(92472, "The Next Step", 5, 3, 92470, true)
q(96638, "The Adventurer", 6, 4, 92470, true)
q(93552, "Harvesting Windstones", 4, 2, 92461, true)
q(92597, "Reading the Ley Lines", 4, 2, 92461, true)
q(92473, "Aggressive Encroachment", 4, 3, 92471, true)
q(92544, "Al'Aketh Thugs", 5, 2, nil, true)
q(93461, "Welcome to Shen'dar Village", 6, 4, 92472, true)
q(92596, "The High Order", 6, 4, 92472, true)
q(94413, "A Magical Affront", 6, 4, 92596, true)
q(96101, "The Great Outdoors", 6, 4, 96638, true)
q(96646, "Camping 101: Cooking", 6, 4, 96101, true)
q(92517, "The Criminal Element", 7, 4, 93461, true)
q(92516, "Hippogryph Harrassment", 7, 4, 93461, true)
q(93319, "Pilfered Windstones", 7, 4, 93461, true)
q(92515, "The Problem With Prideclaws", 6, 4, 93461, true)
q(93951, "A Little Beauty", 7, 4, 93461, true)
q(92553, "Restocking the Larders", 6, 4, 93461, true)
q(93318, "WANTED: Vulgara the Insatiable", 9, 4, 93461, true)
q(93036, "Infiltrating the Cult", 8, 5, 92517, true)
q(92529, "Falaath Village", 8, 5, 93036, true)
q(92528, "Among the Faithful", 8, 5, 92529, true)
q(92550, "Havoc in the Highlands", 8, 5, 92528, true)
q(93926, "The Western Watch", 8, 5, 92528, true)
q(93927, "A Last Request", 8, 5, 93926, true)
q(92551, "Stolen Supplies", 8, 5, 92528, true)
q(92701, "To Valanaar", 9, 6, { 92550, 93927 }, true)
q(93948, "Deliver the Signet", 9, 6, { 92550, 93927 }, true)
q(93317, "Crab Season", 9, 4, nil, true)
q(92679, "Blood Tithe", 9, 5, nil, true)
q(94484, "Unnerving Silence", 11, 8, nil, true)
q(92699, "The Supreme Magister", 9, 4, 92701, true)
q(93949, "Bugged", 8, 6, 93948, true)
q(92709, "A Grand Adventure", 12, 7, 92699, true)
q(92727, "The Missing Scholar", 10, 4, 92699, true)
q(92849, "The Missing Scholar", 10, 4, 92727, true)
q(92850, "The Missing Scholar", 10, 4, 92849, true)
q(92741, "Unwelcome Visitors", 13, 8, 92699, true)
q(92682, "Make Yourself Useful", 9, 5, 92679, true)
q(92683, "Flutterfly Dust", 9, 5, 92679, true)
q(92684, "Ornery Ornery Galestriders", 9, 5, 92679, true)
q(92698, "What Is My Purpose?", 9, 5, 92679, true)
q(92685, "The Hills Have Eyes", 9, 5, { 92682, 92683, 92684 }, true)
q(92693, "Standing Our Ground", 9, 5, 92685, true)
q(92703, "Deliver the News", 9, 5, 92693, true)
q(99260, "Fillion's Mission", 10, 5, 92850, true)
q(92840, "Catching Wind", 11, 5, 99260, true)
q(93791, "Speak with Belann", 10, 10, nil, true, "MAGE")
q(93797, "Boughs in the Wind", 10, 10, 93791, true, "MAGE")
q(94006, "The Great Ursera Spirit", 10, 10, nil, true, "DRUID")
q(94638, "Strength and Mercy", 10, 10, 94006, true, "DRUID")
q(94003, "The Skybreaker Bulwark", 10, 10, nil, true, "WARRIOR")
q(94978, "Taming the Beast", 10, 10, nil, true, "HUNTER")
q(94979, "Taming the Beast", 10, 10, 94978, true, "HUNTER")
q(94013, "Taming the Beast", 10, 10, 94979, true, "HUNTER")
q(94050, "Training the Beast", 10, 10, 94013, true, "HUNTER")
q(92834, "Avenged Tenfold", 11, 6, 92840, true)
q(92860, "In Service of Zephras", 12, 6, 92840, true)
q(93320, "Tower Defense", 11, 6, 92860, true)
q(94896, "Aid For The Refugees", 11, 8, nil, true)
q(94897, "The Fate of a Loved One", 11, 8, nil, true)
q(92642, "Disrupting Logistics", 11, 6, 93320, true)
q(92645, "Breaking the Breaker", 11, 6, 93320, true)
q(92880, "Return to Valanaar", 11, 6, { 92642, 92645 }, true)
q(92881, "The High Elder's Request", 11, 6, 92880, true)
q(92643, "The Turncoat", 11, 6, 92881, true)
q(92644, "Unfortunate News", 11, 6, 92643, true)
q(98512, "Al'Aketh Assassins", 11, 6, nil, true)
q(93159, "The Strange Hermit", 13, 8, nil, true)
q(93160, "The Forest's Bounty", 13, 8, 93159, true)
q(93172, "Free the Hollows", 13, 8, 93159, true)
q(94486, "Feathers for Binding", 11, 8, 94484, true)
q(94487, "Unwanted and Unworthy", 11, 8, 94484, true)
q(94485, "Tears of the Lady", 12, 8, 94484, true)
q(93165, "Mercy Falls on Deaf Ears", 13, 8, 94484, true)
q(94488, "The Ties That Bind", 11, 8, { 94485, 94486, 94487 }, true)
q(94489, "The Wounds of Betrayal", 12, 8, { 94485, 94486, 94487 }, true)
q(94490, "Ripped Missive", 12, 9, { 94485, 94486, 94487 }, true)
q(94491, "The Fate of the Den", 12, 8, 94490, true)
q(94568, "The Cult's True Plans", 11, 6, 92644, true)
q(92640, "Desperate Times", 11, 6, 94568, true)
q(93065, "Prepare for Battle", 12, 7, 92640, true)
q(92947, "Making Our Move", 12, 7, 93065, true)
q(93958, "The Inner Sanctum", 12, 7, 92947, true)
q(93835, "Confront Lorthuna", 12, 7, 93958, true)
q(94369, "The Fate of Zephras", 12, 7, 93835, true)
q(93089, "What Comes Next", 13, 7, 94369, true)
q(94946, "The Magical City of Dalaran", 13, 7, 93089, true)
q(94947, "Welcome to Azeroth", 13, 7, 94946, true)
q(94912, "Child of Nature", 10, 10, nil, true, "DRUID")
-- Camping 101 for the gathering professions (Dalia's choice): optional steps.
q(97970, "Camping 101: Mining", 6, 4, 96101, true)
q(97971, "Camping 101: Skinning", 6, 4, 96101, true)
q(97968, "Camping 101: Herbalism", 6, 4, 96101, true)
for _, id in ipairs({ 97970, 97971, 97968 }) do quest[id].optional = true end

-- (c) places and trainers
-- Thendal Grove
zi.ailee = zi.at("Ailee Farheart", 42.82, 23.39)
zi.rorian = zi.at("Rorian the Dayseeker", 41.9, 23.48)
zi.elatrell = zi.at("Elatrell Featherlight", 43.44, 24.79)
zi.myriaal = zi.at("Myriaal Mistwake", 43.68, 24.09)
zi.halaan = zi.at("Halaan Hawk-Eye", 43.76, 24.06)
zi.yala = zi.at("Yala Windwatcher", 47.25, 21.98)
zi.dalia = zi.at("Dalia the Collector", 43.37, 23.98)
zi.falorne = zi.at("Falorne Fallwind", 43.33, 24.92)
zi.aetheen = zi.at("Aetheen of the Gales", 42.76, 23.66)
zi.valreaa = zi.at("Valreaa Valewind", 42.41, 25.17)
zi.hanaa = zi.at("Hanaa Nightwind", 38.31, 30.18)
zi.ren = zi.at("Blademaster Ren", 43.65, 24.11)
zi.xyton = zi.at("Xyton Silverwind", 41.66, 23.33)
zi.dorii = zi.at("Dorii Brightwhisper", 41.55, 23.68)
zi.akeri = zi.at("Akeri Duskblade", 43.74, 24.36)
zi.tairee = zi.at("Tai'ree Farsight", 42.49, 23.79)
-- Shen'dar Village
zi.aonda = zi.at("Constable Aonda", 45.67, 45.5)
zi.rathiril = zi.at("Rathiril Sunlance", 44.98, 46.36)
zi.coriella = zi.at("Coriella Calmbreeze", 43.0, 43.2)
zi.raan = zi.at("Raan Wildwind", 41.66, 44.8)
zi.zerril = zi.at("Zerril Softbreeze", 44.32, 44.66)
zi.teeri = zi.at("Teeri Wellwind", 44.46, 44.96)
zi.indari = zi.at("Indari Sunseam", 44.67, 44.36)
zi.taleen = zi.at("Taleen Shimmerthread", 44.88, 44.18)
zi.sania = zi.at("Sania Silverstream", 44.88, 45.53)
zi.danarii = zi.at("Danarii Bellowveil", 45.44, 45.29)
zi.bounty = zi.at("Bounty Available: Vulgara the Insatiable!", 43.38, 45.84)
zi.jasaan = zi.at("Missionary Jasaan", 46.89, 56.23)
zi.vaaniel = zi.at("Peacekeeper Vaaniel", 42.34, 62.02)
-- Valanaar and the south-east
zi.nyalah = zi.at("Nyalah Brightfire", 60.6, 72.86)
zi.donaal = zi.at("Donaal Downbreeze", 62.2, 72.6)
zi.alvarion = zi.at("Alvarion Windfield", 62.08, 73.17)
zi.lotheluum = zi.at("Lotheluum Starbreeze", 63.99, 75.08)
zi.talaanis = zi.at("Talaanis Shadowsong", 66.14, 76.59)
zi.valennia = zi.at("Valennia Stormfist", 66.14, 76.67)
zi.anathamaas = zi.at("Anathamaas Aetherwind", 65.94, 80.51)
zi.elaadrin = zi.at("Elaadrin Evengale", 66.59, 80)
zi.dondallion = zi.at("Dondallion Whisperwind", 66.28, 79.83)
zi.iaadaria = zi.at("Iaadaria Bitterwind", 66.34, 79.5)
zi.fillion = zi.at("Fillion Flamebreeze", 66.2, 79.88)
zi.belann = zi.at("Belann Windwood", 62.89, 77.45)
zi.seena = zi.at("Seena Skybreaker", 59.89, 72.87)
zi.quelana = zi.at("Quel'ana Quickgale", 59.56, 72.63)
zi.queldora = zi.at("Quel'dora Quickgale", 59.92, 72.87)
zi.ealaane = zi.at("Ealaane Nimbuswalker", 66.04, 74.41)
zi.aamelia = zi.at("Aamelia Windfield", 46.68, 82.11)
zi.construct = zi.at("Malfunctioning Cyclone Construct", 48.73, 78.38)
zi.yorana = zi.at("Yorana Windyreed", 69.65, 67.07)
zi.ursendris = zi.at("Urs'endris", 69.81, 61.71)
zi.fendaal = zi.at("Fendaal Windstone", 56.81, 61.11)
zi.cultist = zi.at("Dead Cultist", 56.04, 58.77)
zi.hermit = zi.at("Strange Hermit", 53.96, 38.89)
zi.elegael = zi.at("Elegael Thornpaw", 61.7, 39.22)
zi.vayn = zi.at("Vayn Moongaze", 63.81, 36.01)
zi.fieldValennia = zi.at("Valennia Stormfist", 61.15, 70.93)
zi.hyusaa = zi.at("Hyusaa Quickbreeze", 63.78, 50.51)
zi.shrineValennia = zi.at("Valennia Stormfist", 65.19, 50.35)
zi.hearth = { bind = "Valanaar" } -- unverified: the inn may report a subzone name

-- Alliance classes only: the Windshaper (Horde) start adds Shaman.
zi.thendalTrainers = {
  { "WARRIOR", zi.ren }, { "HUNTER", zi.tairee }, { "ROGUE", zi.akeri },
  { "MAGE", zi.dorii }, { "DRUID", zi.xyton },
}
zi.shendarTrainers = {
  { "WARRIOR", zi.at("Corsan Earthrazer", 45.0, 45.1) },
  { "HUNTER", zi.at("Elayaa Easewind", 45.24, 44.3) },
  { "ROGUE", zi.at("Miriaan Mistblade", 43.2, 43.3) },
  { "MAGE", zi.at("Shenaan Spellwind", 45.1, 45.9) },
  { "DRUID", zi.at("Naeluna Swiftmend", 45.2, 44.2) },
}
zi.valanaarTrainers = {
  { "WARRIOR", zi.seena }, { "HUNTER", zi.quelana },
  { "ROGUE", zi.at("Eltheen Nightbreeze", 59.9, 72.5) },
  { "MAGE", zi.anathamaas }, { "DRUID", zi.lotheluum },
}

-- The Dalaran dock and portal use Alterac Mountains (UiMap 1416).
zi.denaaris = at("Denaaris Stargale", 12.3, 56.3, 1416)
zi.bolvar = sw("Highlord Bolvar Fordragon", 80.2, 38.4)

-- (d) steps
-- Thendal Grove: the start, the class letters, the converts north-east and the ursera cave west.
zi.thendal = {
  accept(92460, zi.ailee), finish(92460, zi.rorian), accept(92461, zi.rorian),
  accept(92462, zi.elatrell),
  along(objectiveAt(92462, zi.at(nil, 45.9, 26.8), "Swat Pesky Cirrusflies east of the grove. Kill Vuldren Juveniles as you work back toward town.",
    "8 Pesky Cirrusflies"), 92461),
  along(objectiveAt(92461, zi.at(nil, 45.2, 25.4), "Finish the Vuldren Juveniles on the way back. Swat any Cirrusflies you still need.",
    "8 Vuldren Juveniles"), 92462),
  finish(92461, zi.rorian), finish(92462, zi.elatrell), accept(92463, zi.elatrell),
  accept(94414, zi.halaan, "Climb the watchtower stairs to Halaan Hawk-Eye."),
  objectiveAt(94414, zi.halaan, "Talk to Halaan and look at the distant pylon. Move or press Escape to end the view."),
  finish(94414, zi.halaan), accept(92474, zi.myriaal),
  objectiveAt(92474, zi.myriaal, "Jump down from the tower and slow your fall with Walk on Air. A hop on flat ground may also count."),
  accept(92481, zi.rorian), accept(92482, zi.rorian), accept(92483, zi.rorian),
  accept(92485, zi.rorian), accept(92532, zi.rorian),
  finish(92474, zi.rorian), accept(92464, zi.rorian),
  withItem(282416, objectiveAt(92481, zi.dorii, "Read the Glowing Recall Crystal, then speak to Dorii.")),
  finish(92481, zi.dorii), finish(92482, zi.tairee), finish(92483, zi.akeri),
  finish(92485, zi.xyton, "Xyton is at the foot of the great tree behind Rorian."),
  finish(92532, zi.ren, "Blademaster Ren is inside the watchtower."),
  action("train", nil, "Train at your class trainer in Thendal Grove for level", { level = 2 }),
  accept(93552, zi.dalia), accept(92597, zi.falorne),
  along(objectiveAt(92463, zi.at(nil, 47.7, 28), "Clear the soldiers near the Cirrusfly Queen, then kill her. Gather from Raw Windstones along the way.",
    "Cirrusfly Queen"), 93552),
  finish(92464, zi.yala), accept(92465, zi.yala),
  along(objectiveAt(92597, zi.at(nil, 46.4, 18.2), "Cast Read Leyline at the blue rift. Clear Converts and Roiling Winds on the way to the stones."), 92465, 93552),
  along(objectiveAt(92465, zi.at(nil, 46.9, 20.3), "Kill Converts and Roiling Winds around the stones. Gather from Raw Windstones between pulls.",
    "6 Roiling Winds", "7 Al'Aketh Converts"), 93552),
  objectiveAt(93552, zi.at(nil, 44.6, 23.1), "Finish collecting clusters from Raw Windstones on the way back.", "15 Windstone Clusters"),
  finish(92465, zi.yala), accept(92469, zi.yala),
  finish(93552, zi.dalia, "Turn in to Dalia and pick a gathering profession. Read the book it gives you."),
  finish(92463, zi.elatrell), finish(92597, zi.falorne),
  finish(92469, zi.rorian), accept(92471, zi.rorian),
  finish(92471, zi.aetheen), accept(92470, zi.aetheen),
  action("train", nil, "Train at your class trainer in Thendal Grove for level", { level = 4 }),
  accept(92473, zi.valreaa),
  along(objectiveAt(92473, zi.at(nil, 41.3, 26.3), "Loot claws from Scrawny Ursera on the way to the western cave. Kill Ursera Scavengers you pass.",
    "6 Scrawny Ursera Claws"), 92470),
  objectiveAt(92470, zi.at(nil, 37.6, 26.2), "Enter the ursera cave to the west. Pull Scavengers away from Urs'anah, then kill her for her head.",
    "8 Ursera Scavengers", "Head of Urs'anah"),
  finish(92470, zi.aetheen), accept(92472, zi.aetheen), accept(96638, zi.aetheen),
  finish(92473, zi.valreaa),
  accept(92544, zi.hanaa, "Equip Valreaa's reward, then find Hanaa Nightwind south-west of the grove."),
  objectiveAt(92544, zi.at(nil, 37.3, 32.8), "Clear the temple. Malduko Cloudcrush is on the top floor.",
    "6 Al'Aketh Brutes", "4 Al'Aketh Neophytes", "Malduko Cloudcrush"),
  finish(92544, zi.hanaa),
  action("goto", zi.aonda, "Follow the road south to Shen'dar Village. Keep Small Eggs and Strider Meat from the Galestriders."),
}

-- Shen'dar Village: the High Order welcome, two loops through the highlands, then Falaath.
zi.shendar = {
  finish(92472, zi.aonda), accept(93461, zi.aonda),
  accept(92596, zi.rathiril, "Talk to Rathiril for Welcome to Shen'dar Village, then accept his quest."),
  objectiveAt(92596, zi.rathiril, "Take a seat and talk to Rathiril."),
  finish(92596, zi.rathiril), accept(94413, zi.rathiril),
  objectiveAt(93461, zi.coriella, "Talk to Coriella Calmbreeze at the inn. If Rathiril is still unchecked, speak to him in the lodge.",
    "Rathiril Sunlance", "Coriella Calmbreeze"),
  finish(96638, zi.raan, "Find Raan by his campfire west of the village."), accept(96101, zi.raan),
  objectiveAt(96101, zi.raan, "Sit by Raan's fire until you get Boosted Rest. If it never comes, take the quest again."),
  finish(96101, zi.raan), accept(96646, zi.raan),
  accept(97970, zi.raan, "If you picked Mining at Dalia, ask Raan for the mining lesson too."),
  accept(97971, zi.raan, "If you picked Skinning at Dalia, ask Raan for the skinning lesson too."),
  accept(97968, zi.raan, "If you picked Herbalism at Dalia, ask Raan for the herbalism lesson too. You finish it in Valanaar."),
  finish(97971, zi.at("Mendalass Tattermend", 43.3, 43.4), "Talk to Mendalass Tattermend in the village."),
  finish(97970, zi.at("Messana Crestwind", 44.8, 44.6), "Talk to Messana Crestwind in the village."),
  action("train", nil, "Train at your class trainer in Shen'dar Village for level", { level = 6 }),
  finish(93461, zi.aonda), accept(92517, zi.aonda),
  accept(92516, zi.teeri), accept(93319, zi.teeri), accept(92515, zi.indari),
  accept(93951, zi.taleen), accept(92553, zi.zerril),
  accept(93318, zi.bounty, "Click the bounty notice on the west side of the village. Vulgara is a level 8 elite: bring a group."),
  along(objectiveAt(92517, zi.at(nil, 50.5, 33.9), "Head to the cave behind the waterfall. Loot windstones from Highlands Bandits on the way to Bennic.",
    "10 Highlands Bandits", '"Badwind" Bennic'), 93319),
  along(objectiveAt(93319, zi.at(nil, 48.6, 37.6), "Loot any remaining windstones from Highlands Bandits outside the cave.",
    "10 Pilfered Windstones"), 92517),
  finish(93319, zi.teeri),
  finish(96646, zi.zerril, "Talk to Zerril to learn Cooking. Mild Spices are sold here."),
  objectiveAt(94413, zi.at(nil, 38.5, 47.1), "Kill Novice Seers at the leyline south-west of the village.", "6 Windshaper Novice Seers"),
  along(objectiveAt(93951, zi.at(nil, 36.5, 54), "Pick up down feathers around the south-west nests. Kill Youths and Protectors as you move between nests.",
    "8 Hippogryph Down"), 92516),
  along(objectiveAt(92516, zi.at(nil, 36.5, 54), "Finish the hippogryph kills and pick up any missing feathers. The Matriarch patrols the nests.",
    "8 Hippogryph Youths", "6 Hippogryph Protectors", "Hippogryph Matriarch"), 93951),
  objectiveAt(93318, zi.at(nil, 42.8, 52.7), "With a group, kill Vulgara on the hilltop south-west of the village.", "Vulgara's Head"),
  finish(92516, zi.teeri), finish(93951, zi.taleen), finish(93318, zi.danarii),
  finish(92517, zi.aonda), accept(93036, zi.aonda),
  finish(93036, zi.sania), accept(92529, zi.sania),
  finish(94413, zi.rathiril),
  finish(92529, zi.jasaan, "Follow the road south to Missionary Jasaan at the edge of Falaath Village."), accept(92528, zi.jasaan),
  objectiveAt(92528, zi.at(nil, 48.8, 53.7), "Check the wardrobe upstairs in the house, then walk back toward town for the scene."),
  finish(92528, zi.aonda), accept(92550, zi.aonda), accept(93926, zi.aonda), accept(92551, zi.danarii),
  finish(93926, zi.vaaniel, "Go south-west to the western watchtower. Vaaniel lies by the road north-east of it."),
  accept(93927, zi.vaaniel),
  objectiveAt(93927, zi.at(nil, 42.4, 62.1), "Kill Skypriest Aanders on the tower roof. Collect the signet, the feather and the note.",
    "Skypriest Aanders", "Shadowsong Family Signet", "Raani's Lucky Feather", "Bloody Note"),
  along(objectiveAt(92550, zi.at(nil, 48.3, 55.7), "Kill Stormcallers, Living Lightning and Commander Cyclas. Look for stolen supplies as you clear Falaath.",
    "6 Al'Aketh Stormcallers", "4 Living Lightning", "Commander Cyclas's Head"), 92551),
  along(objectiveAt(92551, zi.at(nil, 50.0, 56.9), "Finish collecting stolen supplies around Falaath Village.",
    "10 Stolen Shen'dar Supplies"), 92550),
  along(objectiveAt(92515, zi.at(nil, 47.4, 51.5), "Loot Prideclaw pelts north of Falaath. Hunt Galestriders for eggs and meat on the way back.",
    "10 Prideclaw Pelts"), 92553),
  along(objectiveAt(92553, zi.at(nil, 47.3, 51.7), "Finish the eggs and meat from Galestriders. Loot any Prideclaw pelts you still need.",
    "3 Small Eggs", "8 Strider Meat"), 92515),
  finish(92553, zi.zerril), finish(92515, zi.indari), finish(92551, zi.danarii),
  finish(92550, zi.aonda), finish(93927, zi.aonda), accept(92701, zi.aonda), accept(93948, zi.aonda),
  action("train", nil, "Train at your class trainer in Shen'dar Village for level", { level = 8 }),
  action("goto", zi.nyalah, "Take the road south-east to Valanaar. Stay on the road through Windfield Orchard."),
}

-- Valanaar: the orchard, the Shriekling Den, the eastern watchtower, Shadowgale Forest, the Shrine.
zi.valanaar = {
  accept(93317, zi.nyalah),
  finish(97968, zi.at("Syriel Nightrain", 57.9, 75.5), "Talk to Syriel Nightrain on the west side of Valanaar."),
  action("sethearth", zi.donaal, "Bind your hearthstone with Donaal Downbreeze at the Valanaar inn.", zi.hearth),
  accept(92679, zi.alvarion, "Alvarion is upstairs in the house. Listen to his story."),
  accept(94484, zi.lotheluum),
  finish(93948, zi.talaanis, "Climb the tower stairs to Talaanis."),
  finish(92701, zi.valennia), accept(92699, zi.valennia), accept(93949, zi.valennia),
  finish(92699, zi.elaadrin), accept(92709, zi.elaadrin),
  objectiveAt(92709, zi.elaadrin, "Listen to Elaadrin."),
  finish(92709, zi.elaadrin),
  accept(92727, zi.dondallion), accept(92741, zi.iaadaria),
  finish(92727, zi.at("Bloodstained Satchel", 53.33, 72.14), "Go west to the satchel at the edge of the Shriekling Den."),
  accept(92849, zi.at("Bloodstained Satchel", 53.33, 72.14)),
  objectiveAt(92849, zi.at("Dusty Bedroll", 52.0, 69.4), "Talk to Fillion inside the den and inspect the Dusty Bedroll."),
  finish(92849, zi.at("Fillion Flamebreeze", 52.09, 69.39)),
  accept(92850, zi.at("Fillion Flamebreeze", 52.09, 69.39)),
  objectiveAt(92850, zi.at(nil, 52.0, 65.5), "Kill the Shriekling Matriarch deeper in the den.", "Shriekling Matriarch's Head"),
  along(finish(92679, zi.aamelia, "Head south-west to Windfield Orchard. If you still need crawler meat, hunt the ones by the water on the way."), 93317),
  accept(92682, zi.aamelia), accept(92683, zi.aamelia), accept(92684, zi.aamelia),
  objectiveAt(92682, zi.at(nil, 47.2, 77.9), "Pick stormapples in the orchard. Hungry Bandits hide in stealth by the trees.",
    "10 Ripe Stormapples", "5 Hungry Bandits"),
  accept(92698, zi.construct),
  along(withItem("Flutterfly Swatter", objectiveAt(92683, zi.at(nil, 50.4, 78.1),
    "Swat Flutterflies east of the orchard and pick up their dust. Loot tenderloins from Ornery Galestriders nearby.", "5 Flutterfly Dust")), 92684),
  along(objectiveAt(92684, zi.at(nil, 50.0, 77.7), "Finish the tenderloins from Ornery Galestriders in the same fields.",
    "7 Lowlands Galestrider Tenderloins"), 92683),
  finish(92698, zi.aamelia), finish(92682, zi.aamelia), finish(92683, zi.aamelia), finish(92684, zi.aamelia),
  accept(92685, zi.aamelia),
  objectiveAt(92685, zi.at(nil, 45.6, 72.4), "Loot masks from the Bandit Highwaymen on the hill north-west of the orchard.", "7 Blood-Stained Bandit Masks"),
  finish(92685, zi.aamelia), accept(92693, zi.aamelia),
  objectiveAt(92693, zi.aamelia, "Talk to Aamelia and help her beat Ferauu the Bludgeon."),
  finish(92693, zi.aamelia), accept(92703, zi.aamelia),
  action("hearth", zi.donaal, "Head back to the inn in Valanaar.", zi.hearth),
  finish(92703, zi.alvarion),
  action("train", nil, "Train at your class trainer in Valanaar for level", { level = 10 }),
  finish(92850, zi.fillion), accept(99260, zi.fillion),
  finish(99260, zi.elaadrin), accept(92840, zi.elaadrin),
  accept(93791, zi.anathamaas), finish(93791, zi.belann), accept(93797, zi.belann),
  accept(94006, zi.lotheluum), accept(94003, zi.seena), accept(94978, zi.quelana),
  along(withItem("Index Esoteria", objectiveAt(92840, zi.at(nil, 47.3, 68.7),
    "Go west to the Overlook Standing Stones. Use the Index Esoteria by each Windstone Formation.")), 93797),
  along(objectiveAt(93797, zi.at(nil, 48.6, 67.8), "Pick up a Wind-Infused Bough while you visit the Windstone Formations.",
    "Wind-Infused Bough"), 92840),
  along(withItem("Taming Rod", objectiveAt(94978, zi.at(nil, 54.5, 78.8),
    "Tame a Windsong Crawler from max range. If you still need meat, loot it from other crawlers.")), 93317),
  finish(94978, zi.quelana), accept(94979, zi.quelana),
  withItem("Taming Rod", objectiveAt(94979, zi.at(nil, 60.9, 69.4), "Use the Taming Rod on an Ornery Galestrider from max range.")),
  finish(94979, zi.quelana), accept(94013, zi.quelana),
  withItem("Taming Rod", objectiveAt(94013, zi.at(nil, 54.1, 74.7), "Dismiss your last tame, then use the Taming Rod on a Vuldren Alpha.")),
  finish(94013, zi.quelana), accept(94050, zi.quelana), finish(94050, zi.queldora),
  objectiveAt(93949, zi.at(nil, 62.2, 75.1), "Kill Enchanted Skyhoppers around Valanaar.", "8 Enchanted Skyhoppers"),
  finish(92840, zi.elaadrin), accept(92834, zi.elaadrin), accept(92860, zi.elaadrin),
  finish(93797, zi.belann),
  finish(93949, zi.valennia), finish(92860, zi.valennia), accept(93320, zi.valennia),
  accept(94896, zi.ealaane), accept(94897, zi.ealaane),
  finish(93320, zi.yorana, "Go north to Yorana at the eastern watchtower."),
  accept(92642, zi.yorana), accept(92645, zi.yorana),
  along(objectiveAt(92642, zi.at(nil, 66.0, 67.0), "Kill Healers and Brawlers west of the tower. Loot charms and look for Belguilos upstairs in the camp.",
    "4 Al'Aketh Healers", "8 Al'Aketh Brawlers"), 92645, 92834),
  along(objectiveAt(92645, zi.at(nil, 65.3, 66.6), "Kill Belguilos upstairs. Clear and loot cultists around the house for any missing kills or charms.",
    "Commander Belguilos"), 92642, 92834),
  along(objectiveAt(92834, zi.at(nil, 66.0, 67.0), "Loot any remaining charms from cultists in the watchtower camp.",
    "10 Al'Aketh Windstone Charms"), 92642, 92645),
  finish(92642, zi.yorana), finish(92645, zi.yorana), accept(92880, zi.yorana),
  finish(94006, zi.ursendris, "Follow the river north to Urs'endris by the falls."), accept(94638, zi.ursendris),
  finish(92880, zi.valennia), accept(92881, zi.valennia),
  finish(92881, zi.talaanis), accept(92643, zi.talaanis),
  accept(98512, zi.fendaal, "Go north-west to Fendaal Windstone at the edge of the highlands."),
  finish(92643, zi.cultist, "Find the dead cultist in the house just north."), accept(92644, zi.cultist),
  objectiveAt(98512, zi.at(nil, 56.5, 61.3), "Kill Assassins around the house and the road.", "10 Al'Aketh Assassins"),
  finish(98512, zi.fendaal),
  objectiveAt(93317, zi.at(nil, 53.6, 59.2), "Loot meat from Windsong Crawlers along the water west of here.", "6 Windsong Crawler Meat"),
  objectiveAt(94638, zi.at(nil, 54.3, 65.8), "Find and kill Ur'endra.", "Ur'endra"),
  finish(94638, zi.ursendris),
  objectiveAt(94003, zi.at(nil, 56.6, 50.4), "Take the Skybreaker Bulwark from Zaal Stormshield at the Shrine of Akir.", "Skybreaker Bulwark"),
  accept(93159, zi.hermit, "Go north into Shadowgale Forest and find the Strange Hermit."),
  finish(93159, zi.hermit), accept(93160, zi.hermit), accept(93172, zi.hermit),
  along(objectiveAt(94897, zi.at(nil, 57.0, 29.4), "Find Resaan in the northern ruins. Search the crates and clear Wind Hollows on the way in.",
    "Resaan's Heirloom"), 94896, 93172),
  along(objectiveAt(94896, zi.at(nil, 57.9, 31.1), "Search the ruins for the remaining crates of belongings. Clear Wind Hollows between crates.",
    "8 Abandoned Belongings"), 93172),
  along(objectiveAt(93172, zi.at(nil, 58.2, 32.8), "Finish off the Wind Hollows and check for any crates you missed.",
    "10 Wind Hollows"), 94896),
  finish(94484, zi.elegael, "Go east to Elegael Thornpaw."),
  accept(94486, zi.elegael), accept(94487, zi.elegael), accept(94485, zi.elegael),
  accept(93165, zi.vayn, "Vayn stands in the cave mouth north-east of Elegael."),
  along(objectiveAt(94487, zi.at(nil, 63.8, 37.3), "Loot heirlooms, ears and any missing charms from Footsoldiers and Stormchasers east of Elegael.",
    "10 Bloodied Heirlooms"), 93165, 92834),
  along(objectiveAt(93165, zi.at(nil, 63.8, 37.3), "Finish looting ears from the same cultists.",
    "Al'Aketh Cultist's Ears"), 94487, 92834),
  finish(94487, zi.elegael),
  along(objectiveAt(93160, zi.at(nil, 57.9, 40.0), "Pick up acorns under the trees. Check the trunks for moss and loot Shrieklings as you go.",
    "8 Shadowgale Acorns"), 94485, 92741, 94486),
  finish(93160, zi.hermit), finish(93172, zi.hermit),
  along(objectiveAt(94485, zi.at(nil, 59.8, 39.0), "Pick any remaining moss from the trees. Loot talons and feathers from Shrieklings between trees.",
    "8 Lady's Tear Moss"), 92741, 94486),
  along(objectiveAt(92741, zi.at(nil, 59.8, 39.0), "Loot talons and feathers from Shadowgale Shrieklings.",
    "8 Shriekling Talons"), 94486),
  along(objectiveAt(94486, zi.at(nil, 59.8, 39.0), "Loot any remaining feathers from the same Shrieklings.",
    "20 Pristine Shriekling Feathers"), 92741),
  finish(94486, zi.elegael), finish(94485, zi.elegael), accept(94488, zi.elegael), accept(94489, zi.elegael),
  objectiveAt(94488, zi.at(nil, 65.5, 36.3), "Kill Commander Haalien for his head. He also drops a missive.", "Commander Haalien's Severed Head"),
  withItem("Ripped Missive", accept(94490, zi.at(nil, 65.5, 36.3), "Use the Ripped Missive from your bags.")),
  finish(93165, zi.vayn),
  objectiveAt(94489, zi.vayn, "Enter the Nightfang Den. Heal the druids inside and find Jorel Windsinger."),
  finish(94488, zi.elegael), finish(94489, zi.elegael), finish(94490, zi.elegael), accept(94491, zi.elegael),
  action("hearth", zi.donaal, "Head back to the inn in Valanaar.", zi.hearth),
  finish(93317, zi.nyalah), finish(94003, zi.seena), finish(94491, zi.lotheluum),
  finish(94896, zi.ealaane), finish(94897, zi.ealaane),
  action("train", nil, "Train at your class trainer in Valanaar for level", { level = 12 }),
  finish(92644, zi.talaanis), accept(94568, zi.talaanis),
  objectiveAt(94568, zi.talaanis, "Listen to the conversation."),
  finish(94568, zi.talaanis), accept(92640, zi.talaanis),
  objectiveAt(92640, zi.valennia, "Talk to Valennia upstairs, then talk to Ayessa and Elaadrin at the scene by the High Order lodge.",
    "Valennia Stormfist", "Ayessa Dawnsinger", "Elaadrin Evengale"),
  finish(92834, zi.elaadrin), finish(92741, zi.iaadaria),
  finish(92640, zi.valennia), accept(93065, zi.valennia),
  objectiveAt(93065, zi.fieldValennia, "Meet Valennia in the lowlands north-west of town."),
  finish(93065, zi.fieldValennia), accept(92947, zi.fieldValennia),
  objectiveAt(92947, zi.at(nil, 62.8, 52.6), "Fight up to the Shrine of Akir. Kill Guardians, Spiritcallers and Blademasters on the way.",
    "7 Al'Aketh Guardians", "7 Al'Aketh Spiritcallers", "7 Al'Aketh Blademasters"),
  finish(92947, zi.hyusaa, "Hyusaa waits up the shrine steps."), accept(93958, zi.hyusaa),
  finish(93958, zi.shrineValennia, "Climb the spiral stairs to the inner sanctum."), accept(93835, zi.shrineValennia),
  objectiveAt(93835, zi.at(nil, 75.1, 53.1), "Take the portal up to the Rohashi Spires and ride the windstream to Elaadrin. Help in the fight."),
  finish(93835, zi.elaadrin, "Use the Portal to Valanaar beside the fight and return to Elaadrin."),
  accept(94369, zi.elaadrin), finish(94369, zi.talaanis), accept(93089, zi.talaanis),
  finish(93089, zi.elaadrin), accept(94946, zi.elaadrin),
  action("boat", zi.at(nil, 65.9, 83.5), "Board the skycutter at Valanaar's eastern pier. Use Next when it docks at Dalaran."),
  finish(94946, zi.denaaris, "Turn in to Denaaris Stargale at the Sky Enclave beside the dock."),
  accept(94947, zi.denaaris),
  accept(94912, at("Alfina Nightgaze", 11.8, 56.6, 1416)),
  objectiveAt(94947, at("Skyborne Portal to Stormwind", 12.1, 56.4, 1416), "Use the Skyborne Portal beside Denaaris. It lands in Stormwind's Mage Quarter."),
  finish(94912, sw("Sheldras Moontree", 35.84, 67.38), "Find Sheldras at The Park in Stormwind."),
  taxi("getfp", dungar, "Stormwind, Elwynn", "Learn the flight path from Dungar Longdrink above the Trade District."),
  finish(94947, zi.bolvar, "Report to Highlord Bolvar Fordragon in the throne room at Stormwind Keep."),
  accept(98021, zi.bolvar),
  action("goto", at(nil, 59.95, 19.36, westfall), "Leave by the main gate, take the road through Goldshire and west across the bridge to the Furlbrow farm."),
}

-- (e) sources
zi.sources = {
  "https://bindonforever.com/zones/zephras-isle",
  "https://polestar.guide/guides/alliance/skyborne/01-zephras-isle",
  "https://www.warcrafttavern.com/forever/guides/how-to-get-to-ironforge-from-the-zephras-isle/",
  "https://gamer-guides.com/warcraft-forever/zephras-isle-to-stormwind-orgrimmar/",
  "https://allthings.how/how-to-complete-the-magical-city-of-dalaran-in-wow-forever/",
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
}

-- Night Elf start, levels 1-12: Shadowglen, Teldrassil and Darnassus, then the Forever ship
-- from Auberdine to Stormwind Harbor and the walk to Westfall. Source notes:
-- tools/audits/2026-11-08-teldrassil.md.
-- Paste after `taxi` and `forDungeon` are defined (it uses objectiveAt, taxi, sw, wf, dungar
-- and furlbrow), e.g. right before `local sources = {`. One main-chunk local only: `te`.
local te = { map = 1438, darnassus = 1457, darkshore = 1439 }
function te.t(name, x, y) return at(name, x, y, te.map) end
function te.d(name, x, y) return at(name, x, y, te.darnassus) end

-- (b) Quests
q(458, "The Woodland Protector", 1, 1)
q(456, "The Balance of Nature", 2, 1)
q(459, "The Woodland Protector", 3, 1, 458)
q(97977, "Nature's Call", 3, 1, 458, true)
q(3116, "Simple Sigil", 1, 1, 456, nil, "WARRIOR")
q(3117, "Etched Sigil", 1, 1, 456, nil, "HUNTER")
q(3118, "Encrypted Sigil", 1, 1, 456, nil, "ROGUE")
q(3119, "Hallowed Sigil", 1, 1, 456, nil, "PRIEST")
q(3120, "Verdant Sigil", 1, 1, 456, nil, "DRUID")
q(97979, "The Goddess Provides", 1, 1, 456, true, "PRIEST")
q(457, "The Balance of Nature", 3, 1, 456)
q(4495, "A Good Friend", 4, 2)
q(3519, "A Friend in Need", 4, 2, 4495)
q(3521, "Iverron's Antidote", 4, 2, 3519)
q(3522, "Iverron's Antidote", 4, 2, 3521)
q(916, "Webwood Venom", 4, 3)
q(917, "Webwood Egg", 5, 1, 916)
q(97236, "Fang of Githyiss", 5, 1, nil, true)
quest[97236].startItem = 277190
q(920, "Tenaron's Summons", 5, 1, 917)
q(921, "Crown of the Earth", 5, 1, 920)
q(928, "Crown of the Earth", 5, 1, 921)
q(96630, "The Adventurer", 6, 4, 921, true)
q(2159, "Dolanaar Delivery", 5, 1)
q(5622, "In Favor of Elune", 4, 5, nil, nil, "PRIEST")
q(488, "Zenn's Bidding", 5, 4)
q(96606, "The Great Outdoors", 6, 4, nil, true)
q(96634, "Camping 101: Cooking", 6, 4, 96606, true)
q(97949, "Camping 101: Skinning", 6, 4, 96606, true)
quest[97949].optional = true
q(997, "Denalan's Earth", 5, 4)
q(475, "A Troubling Breeze", 6, 4)
q(476, "Gnarlpine Corruption", 6, 4, 475)
q(2438, "The Emerald Dreamcatcher", 6, 1)
q(932, "Twisted Hatred", 7, 4)
q(87288, "Soft Saber Pelts", 7, 4, nil, true)
q(5621, "Garments of the Moon", 4, 5, 5622, nil, "PRIEST")
q(98391, "The Sisterhood of Elune", 10, 5, nil, true)
q(929, "Crown of the Earth", 5, 1, 928)
q(918, "Timberling Seeds", 7, 4, 997)
q(919, "Timberling Sprouts", 7, 4)
q(922, "Rellian Greenspyre", 7, 4, 918)
q(489, "Seek Redemption!", 7, 4, 488)
q(4161, "Recipe of the Kaldorei", 7, 1)
q(490, "Bounty: Gnarlpine Furbolg", 8, 5, nil, true)
q(483, "The Relics of Wakening", 9, 4, 476)
q(486, "Ursal the Mauler", 12, 4, 483)
q(2459, "Ferocitas the Dream Eater", 8, 1, 2438)
q(933, "Crown of the Earth", 9, 1, 929)
q(487, "The Road to Darnassus", 8, 5)
q(99046, "The Lost Runner", 9, 4, nil, true)
q(2541, "The Sleeping Druid", 8, 3)
q(2561, "Druid of the Claw", 10, 3, 2541)
q(99053, "Escaping Ban'ethil", 10, 4, nil, true)
q(930, "The Glowing Fruit", 10, 4)
q(7383, "Crown of the Earth", 11, 1, 933)
q(1684, "Elanaria", 10, 10, nil, nil, "WARRIOR")
q(2241, "The Apple Falls", 10, 10, nil, nil, "ROGUE")
q(5629, "Returning Home", 10, 10, nil, nil, "PRIEST")
q(5923, "Heeding the Call", 10, 10, nil, nil, "DRUID")
q(6063, "Taming the Beast", 10, 10, nil, nil, "HUNTER")
q(6101, "Taming the Beast", 10, 10, 6063, nil, "HUNTER")
q(6102, "Taming the Beast", 10, 10, 6101, nil, "HUNTER")
q(6103, "Training the Beast", 10, 10, 6102, nil, "HUNTER")
q(98403, "Twisted Hatred", 12, 4, 932, true)
q(923, "Tumors", 9, 4, 922)
q(2519, "The Temple of the Moon", 10, 5)
q(2518, "Tears of the Moon", 12, 5, 2519)
q(2520, "Sathrah's Sacrifice", 12, 5, 2518)
q(99047, "Not Dead Yet", 9, 4, nil, true)
q(937, "The Enchanted Glade", 11, 6)
q(938, "Mist", 12, 7)
q(931, "The Shimmering Frond", 10, 4)
q(98392, "Darkness in the Glade", 12, 6, 937, true)
q(98398, "The Oracle Tree", 12, 6, 98392, true)
q(940, "Teldrassil", 11, 6, 98398)
q(2498, "Return to Denalan", 9, 4, 923)
q(99050, "The Great Tree Provides", 10, 4, 99047, true)
q(935, "Crown of the Earth", 11, 1, 7383)
q(2499, "Oakenscowl", 9, 4, 2498)
q(2399, "The Sprouted Fronds", 10, 4, 931)
q(99073, "Easing Suffering", 10, 4, 99050, true)
q(98046, "Crown of the Earth", 11, 1, 935, true)
q(98065, "Crown of the Earth", 11, 1, 98046, true)
q(98067, "Eyes of the Sentinels", 11, 1, nil, true)
q(6344, "Nessa Shadowsong", 10, 10)
q(6341, "The Bounty of Teldrassil", 10, 10, 6344)
q(6342, "Flight to Auberdine", 10, 10, 6341)
q(6343, "Return to Nessa", 10, 10, 6342)
q(927, "The Moss-twined Heart", 12, 5)
quest[927].startItem = 5179
q(941, "Planting the Heart", 12, 9, 927)
q(97220, "Philmor's Favor", 15, 9, nil, true)
q(97222, "Gatehouse Goods", 15, 9, 97220, true)
breadcrumb(96630, 96606)
breadcrumb(99046, 99047)
breadcrumb(98391, 2519)

-- (c) Places and trainers
te.ilthalaine = te.t("Conservator Ilthalaine", 58.69, 44.27)
te.melithar = te.t("Melithar Staghelm", 59.92, 42.47)
te.tarindrella = te.t("Tarindrella", 57.83, 45.21)
te.shanda = te.t("Shanda", 59.17, 40.44)
te.dirania = te.t("Dirania Silvershine", 60.9, 41.96)
te.iverron = te.t("Iverron", 54.59, 32.99)
te.gilshalan = te.t("Gilshalan Windwalker", 57.81, 41.65)
te.tenaron = te.t("Tenaron Stormgrip", 59.06, 39.45)
te.porthannius = te.t("Porthannius", 61.16, 47.64)
te.webwood = te.t(nil, 56.6, 27.2)
te.zenn = te.t("Zenn Foulhoof", 60.46, 56.3)
te.lyreena = te.t("Lyreena Duskblade", 57.58, 56.64)
te.keldamyr = te.t("Innkeeper Keldamyr", 55.62, 59.79)
te.zarrin = te.t("Zarrin", 57.12, 61.3)
te.corithras = te.t("Corithras Moonrage", 56.14, 61.71)
te.syral = te.t("Syral Bladeleaf", 56.08, 57.72)
te.athridas = te.t("Athridas Bearmantle", 55.96, 57.27)
te.tallonkai = te.t("Tallonkai Swiftroot", 55.57, 56.95)
te.aldia = te.t("Aldia", 55.51, 57.15)
te.laurna = te.t("Laurna Morninglight", 55.56, 56.75)
te.amara = te.t("Moon Priestess Amara", 54.63, 58.46)
te.kyra = te.t("Sentinel Kyra Starsong", 56.0, 59.52)
te.byancie = te.t("Byancie", 55.29, 56.82)
te.narret = te.t("Narret Shadowgrove", 55.27, 57.15)
te.dazalar = te.t("Dazalar", 56.68, 59.49)
te.denalan = te.t("Denalan", 60.9, 68.49)
te.gaerolas = te.t("Gaerolas Talvethren", 66.26, 58.52)
te.shayla = te.t("Sentinel Shayla Nightbreeze", 40.5, 50.7)
te.ursal = te.t("Ursal the Mauler", 39.2, 80.0)
te.oben = te.t("Oben Rageclaw", 44.94, 61.59)
te.lynessa = te.t("Sentinel Lynessa Duskblossom", 44.67, 58.91)
te.eralya = te.t("Sentinel Eralya Leafshadow", 37.54, 36.81)
te.arynia = te.t("Sentinel Arynia Cloudsbreak", 38.32, 34.36)
te.bark = te.t("Oracle Tree Bark", 36.97, 34.04)
te.gate = te.t(nil, 35.91, 54.35)
te.nessa = te.t("Nessa Shadowsong", 56.26, 92.44)
te.vesprystus = te.t("Vesprystus", 58.4, 94.02)
te.rellian = te.d("Rellian Greenspyre", 38.18, 21.64)
te.fandral = te.d("Arch Druid Fandral Staghelm", 34.81, 9.26)
te.aquinne = te.d("Sister Aquinne", 28.94, 45.8)
te.amoora = te.d("Priestess A'moora", 36.65, 85.93)
te.lariia = te.d("Lariia", 40.35, 88.68)
te.tyrande = te.d("Tyrande Whisperwind", 39.1, 81.59)
te.dalia = te.d("Sentinel Dalia Sunblade", 39.65, 89.54)
te.mydrannul = te.d("Mydrannul", 70.68, 45.38)
te.laird = at("Laird", 36.77, 44.28, te.darkshore)
te.caylais = at("Caylais Moonfeather", 36.34, 45.58, te.darkshore)
te.thamarian = at("Thamarian", 32.67, 42.11, te.darkshore)
te.harbor = sw("Idrieth Mossgrove", 26.2, 53.2)
te.hearth = { bind = "Dolanaar" }
te.shadowglenTrainers = {
  { "WARRIOR", te.t("Alyissia", 59.64, 38.44) },
  { "HUNTER", te.t("Ayanna Everstride", 58.66, 40.45) },
  { "ROGUE", te.t("Frahun Shadewhisper", 59.64, 38.66) },
  { "PRIEST", te.shanda },
  { "DRUID", te.t("Mardant Strongoak", 58.63, 40.29) },
}
te.dolanaarTrainers = {
  { "WARRIOR", te.t("Kyra Windblade", 56.22, 59.2) },
  { "HUNTER", te.dazalar },
  { "ROGUE", te.t("Jannok Breezesong", 56.38, 60.14) },
  { "PRIEST", te.laurna },
  { "DRUID", te.t("Kal", 55.95, 61.56) },
}

-- (d) Steps
-- Shadowglen, 1-6: the grove around Aldrassil, the spider cave to the north, then the road south.
te.shadowglen = {
  accept(456, te.ilthalaine), accept(458, te.melithar),
  finish(458, te.tarindrella, "Find the dryad Tarindrella just south-west of the tree."),
  accept(459, te.tarindrella), accept(97977, te.tarindrella),
  objectiveAt(456, te.t(nil, 59.5, 44.5), "Kill young nightsabers and boars around the foot of Aldrassil.", "7 Young Nightsabers", "4 Young Thistle Boars"),
  along(objectiveAt(459, te.t(nil, 56.0, 45.5), "Loot Fel Moss from grells west of Tarindrella. Pick up totems in the same camps.", "8 Fel Moss"), 97977),
  along(objectiveAt(97977, te.t(nil, 54.5, 43.8), "Check the ground among the grells for any remaining Gnarlpine Totems.", "4 Gnarlpine Totems"), 459),
  finish(459, te.tarindrella), finish(97977, te.tarindrella),
  finish(456, te.ilthalaine), accept(457, te.ilthalaine),
  accept(3116, te.ilthalaine), finish(3116, te.shadowglenTrainers[1][2], "Read the sigil and find Alyissia inside Aldrassil."),
  accept(3117, te.ilthalaine), finish(3117, te.shadowglenTrainers[2][2], "Read the sigil and climb Aldrassil to Ayanna."),
  accept(3118, te.ilthalaine), finish(3118, te.shadowglenTrainers[3][2], "Read the sigil and find Frahun inside Aldrassil."),
  accept(3119, te.ilthalaine), finish(3119, te.shanda, "Read the sigil and find Shanda inside Aldrassil."),
  accept(3120, te.ilthalaine), finish(3120, te.shadowglenTrainers[5][2], "Read the sigil and find Mardant inside Aldrassil."),
  accept(97979, te.shanda),
  objectiveAt(97979, te.shanda, "Cast Elune's Light and Shadowmeld from your spellbook.", "Elune's Light", "Shadowmeld"),
  finish(97979, te.shanda),
  action("train", nil, "Visit your class trainer in Aldrassil. Train spells for level", { level = 2 }),
  accept(916, te.gilshalan), accept(4495, te.dirania),
  along(objectiveAt(457, te.t(nil, 60.0, 36.5), "Kill the bigger nightsabers and boars on the way north to the spider cave.", "7 Mangy Nightsabers", "7 Thistle Boars"), 916),
  finish(4495, te.iverron, "Find Iverron outside the spider cave to the north-west."),
  accept(3519, te.iverron),
  objectiveAt(916, te.webwood, "Kill Webwood Spiders around the cave mouth and loot their venom sacs.", "10 Webwood Venom Sacs"),
  finish(457, te.ilthalaine), finish(916, te.gilshalan), accept(917, te.gilshalan),
  finish(3519, te.dirania), accept(3521, te.dirania),
  objectiveAt(3521, te.t(nil, 57.0, 38.0), "Pick mushrooms and lilies around the tree, and loot the Ichor from a Webwood Spider at the cave.",
    "7 Hyacinth Mushrooms", "4 Moonpetal Lilies", "Webwood Ichor"),
  action("train", nil, "Train spells for level", { level = 4 }),
  finish(3521, te.dirania), accept(3522, te.dirania),
  finish(3522, te.iverron, "Run the antidote to Iverron before the timer ends."),
  objectiveAt(917, te.t(nil, 56.8, 26.5), "Take an egg from the pile at the back of the spider cave. Kill Githyiss the Vile nearby if she is up.", "Webwood Egg"),
  withItem(277190, accept(97236, te.t(nil, 56.6, 26.3), "Use the Fang of Githyiss you looted to start the quest.")),
  finish(917, te.gilshalan), finish(97236, te.gilshalan), accept(920, te.gilshalan),
  finish(920, te.tenaron, "Climb to the top of Aldrassil."), accept(921, te.tenaron),
  withItem(5185, objectiveAt(921, te.t(nil, 59.95, 33.05), "Fill the Crystal Phial at the moonwell north of the tree.", "Filled Crystal Phial")),
  finish(921, te.tenaron), accept(928, te.tenaron),
  accept(96630, te.t("Lost Journal", 59.1, 39.45), "Pick up the Lost Journal by the tree."),
  accept(5622, te.shanda),
  action("train", nil, "Train spells for level", { level = 6 }),
  accept(2159, te.porthannius, "Take the delivery from Porthannius on the road out of Shadowglen."),
}

-- Teldrassil, 6-12: Dolanaar loops (Lake Al'Ameth, Starbreeze, Fel Rock, Ban'ethil), then
-- Darnassus and the Oracle Glade, then the trip to Stormwind and Westfall.
te.teldrassil = {
  accept(488, te.zenn, "Follow the road south. Zenn Foulhoof waits by the road before Dolanaar."),
  finish(96630, te.lyreena), accept(96606, te.lyreena),
  objectiveAt(96606, te.lyreena, "Sit by Lyreena's campfire until you get Boosted Rest.", "Boosted Rest"),
  finish(96606, te.lyreena), accept(96634, te.lyreena),
  accept(97949, te.lyreena, "If you know Skinning, ask Lyreena for the skinning lesson too. Radnaal Maneweaver on the Darnassus road finishes it once your Skinning reaches 20."),
  finish(2159, te.keldamyr),
  action("sethearth", te.keldamyr, "Bind your hearthstone at the Dolanaar inn.", te.hearth),
  finish(96634, te.zarrin, "Speak to Zarrin in the inn about Cooking."),
  finish(928, te.corithras), accept(929, te.corithras),
  accept(997, te.syral), accept(475, te.athridas), accept(2438, te.tallonkai), accept(932, te.tallonkai),
  accept(87288, te.aldia),
  finish(5622, te.laurna), accept(5621, te.laurna), accept(98391, te.laurna),
  action("train", nil, "Visit your Dolanaar class trainer. Train spells for level", { level = 6 }),
  objectiveAt(5621, te.t("Sentinel Shaya", 57.2, 63.5), "Heal Sentinel Shaya south of town, then give her Fortitude.", "Heal and fortify Sentinel Shaya"),
  finish(997, te.denalan, "Follow the path south-east to Denalan at Lake Al'Ameth."),
  accept(918, te.denalan), accept(919, te.denalan),
  along(objectiveAt(918, te.t(nil, 56.7, 65.8), "Kill Timberlings for seeds and pick up sprouts. Loot fangs from nearby nightsabers.", "8 Timberling Seeds"), 919, 488),
  along(objectiveAt(919, te.t(nil, 56.3, 66.9), "Pick up any remaining sprouts along the shore.", "12 Timberling Sprouts"), 488),
  finish(918, te.denalan), finish(919, te.denalan), accept(922, te.denalan),
  along(objectiveAt(488, te.t(nil, 65.3, 62.4), "Head northeast to Starbreeze. Loot fangs and pelts from nightsabers, feathers from owls, and silk from Webwood Lurkers.",
    "3 Nightsaber Fangs", "3 Strigid Owl Feathers", "3 Webwood Spider Silk"), 87288, 2438),
  along(objectiveAt(87288, te.t(nil, 66.1, 54.3), "Loot any remaining pelts from nightsabers near Starbreeze.", "6 Soft Nightsaber Pelts"), 2438),
  finish(475, te.gaerolas, "Find Gaerolas in Starbreeze Village."), accept(476, te.gaerolas),
  along(objectiveAt(2438, te.t("Tallonkai's Dresser", 68.0, 59.6), "Check the upstairs dresser at the east end of Starbreeze, then stop at the moonwell.", "Emerald Dreamcatcher"), 929),
  withItem(5619, objectiveAt(929, te.t(nil, 63.38, 58.09), "Fill the Jade Phial at the Starbreeze moonwell.", "Filled Jade Phial")),
  finish(488, te.zenn),
  finish(476, te.athridas), accept(483, te.athridas),
  finish(2438, te.tallonkai), accept(2459, te.tallonkai),
  finish(87288, te.aldia), finish(5621, te.laurna),
  finish(929, te.corithras), accept(933, te.corithras),
  accept(489, te.syral), accept(487, te.amara), accept(99046, te.kyra),
  action("train", nil, "Train spells for level", { level = 8 }),
  objectiveAt(932, te.t(nil, 51.8, 50.4), "Enter Fel Rock north-west of Dolanaar. Kill Lord Melenas at the back and take his head.", "Melenas' Head"),
  along(objectiveAt(2459, te.t(nil, 68.9, 52.8), "Kill Mystics east of Starbreeze. Use Ferocitas's Gnarlpine Necklace to get the jewel, then look for Fel Cones on the way back.",
    "7 Gnarlpine Mystics", "Tallonkai's Jewel"), 489),
  objectiveAt(489, te.t(nil, 63.7, 63.6), "Collect Fel Cones under the trees on the way back west.", "3 Fel Cones"),
  finish(489, te.zenn),
  finish(932, te.tallonkai), finish(2459, te.tallonkai),
  accept(490, te.shayla, "Pick up the bounty from Shayla on patrol west of the den before fighting the ambushers."),
  along(objectiveAt(487, te.t(nil, 46.5, 53.3), "Kill Gnarlpine Ambushers on the road by the den and loot their fangs.", "6 Gnarlpine Ambushers"), 490),
  accept(2541, te.oben, "Find Oben Rageclaw inside the Ban'ethil Barrow Den."),
  along(objectiveAt(2541, te.t(nil, 44.7, 58.5), "Loot the charm and any fangs from Gnarlpine Shamans. Open relic chests as you clear the den.", "Shaman Voodoo Charm"), 483, 490),
  finish(2541, te.oben), accept(2561, te.oben),
  along(withItem(8149, objectiveAt(2561, te.t("Rageclaw", 45.5, 58.6), "Kill Rageclaw and use the charm on his body. Check the nearby rooms for relic chests.", "Rageclaw freed")), 483),
  finish(2561, te.oben),
  along(objectiveAt(483, te.t(nil, 44.4, 60.7), "Open any remaining relic chests. Loot fangs from shamans you fight on the way.",
    "Raven Claw Talisman", "Black Feather Quill", "Sapphire of Sky", "Rune of Nesting"), 490),
  accept(99053, te.lynessa),
  objectiveAt(99053, te.lynessa, "Escort Sentinel Lynessa out of the den. Use Next if the escort fails.", "Lynessa escaped"),
  withItem(5621, objectiveAt(933, te.t(nil, 42.41, 67.07), "Go south to the Pools of Arlithrien and fill the Tourmaline Phial.", "Filled Tourmaline Phial")),
  withItem(5189, accept(930, te.t("Strange Fruited Plant", 42.61, 76.19), "Take the Glowing Fruit from the plant further south.")),
  action("hearth", te.keldamyr, "Head back to the inn in Dolanaar.", te.hearth),
  finish(487, te.amara), finish(483, te.athridas), finish(99053, te.kyra),
  finish(933, te.corithras), accept(7383, te.corithras),
  action("grind", te.t(nil, 53.4, 57.5), "If still under level 10, clear nightsabers and owls around Dolanaar.", { level = 10 }),
  action("train", nil, "Train spells for level", { level = 10 }),
  accept(486, te.athridas), accept(98403, te.tallonkai),
  accept(1684, te.dolanaarTrainers[1][2]), accept(2241, te.dolanaarTrainers[3][2]),
  accept(5629, te.laurna), accept(5923, te.dolanaarTrainers[5][2]),
  accept(6063, te.dazalar),
  withItem(15921, objectiveAt(6063, te.t(nil, 53.0, 64.4), "Use the Taming Rod on a Webwood Lurker south of town.", "Tame a Webwood Lurker")),
  finish(6063, te.dazalar), accept(6101, te.dazalar),
  withItem(15922, objectiveAt(6101, te.t(nil, 52.6, 75.7), "Use the Taming Rod on a Nightsaber Stalker south of the lake.", "Tame a Nightsaber Stalker")),
  finish(6101, te.dazalar), accept(6102, te.dazalar),
  withItem(15923, objectiveAt(6102, te.t(nil, 55.3, 76.7), "Use the Taming Rod on a Strigid Screecher south of the lake.", "Tame a Strigid Screecher")),
  finish(6102, te.dazalar), accept(6103, te.dazalar),
  objectiveAt(98403, te.t(nil, 51.5, 43.6), "Go north-west of Dolanaar. Kill Befouled Webwoods and take Xethorr's Mature Fel Moss.",
    "8 Befouled Webwoods", "Mature Fel Moss"),
  finish(97949, te.t("Radnaal Maneweaver", 42.09, 49.96), "With Skinning 20, stop at Radnaal Maneweaver beside the Darnassus road for the camping recipe."),
  action("goto", te.gate, "Follow the road west to the Darnassus gate and cross the bridge into the city."),
  finish(922, te.rellian, "Find Rellian in the Cenarion Enclave."), accept(923, te.rellian),
  finish(1684, te.d("Elanaria", 57.3, 34.6), "Speak to Elanaria on the Warrior's Terrace."),
  finish(2241, te.d("Syurna", 36.99, 21.91), "Find Syurna in the Cenarion Enclave."),
  finish(5923, te.d("Mathrengyl Bearwalker", 35.37, 8.4), "Find Mathrengyl in the Cenarion Enclave."),
  finish(6103, te.d("Jocaste", 40.38, 8.55), "Find Jocaste in the Cenarion Enclave."),
  finish(98391, te.aquinne), accept(2519, te.aquinne),
  finish(2519, te.amoora, "Go south to the Temple of the Moon."), accept(2518, te.amoora),
  finish(5629, te.d("Priestess Alathea", 39.52, 81.2), "Find Priestess Alathea in the temple."),
  finish(99046, te.eralya, "Leave the city and take the road north toward the Oracle Glade."),
  accept(99047, te.eralya),
  accept(937, te.arynia),
  along(withItem(18152, objectiveAt(7383, te.t(nil, 38.44, 34.06), "Fill the Amethyst Phial at the moonwell before heading west to the harpies.", "Filled Amethyst Phial")), 937),
  objectiveAt(937, te.t(nil, 35.4, 36.6), "Kill Bloodfeather harpies west of the glade for their belts.", "6 Bloodfeather Belts"),
  withItem(5190, accept(931, te.t("Strange Fronded Plant", 34.61, 28.76), "Take the Shimmering Frond from the plant north of the harpies.")),
  accept(938, te.t("Mist", 31.54, 31.61), "Clear the harpies on the way to Mist, then start the escort."),
  objectiveAt(938, te.arynia, "Lead Mist back to Sentinel Arynia. Keep the harpies off her.", "Mist returned"),
  finish(938, te.arynia), finish(937, te.arynia), accept(98392, te.arynia),
  objectiveAt(98392, te.t(nil, 35.0, 32.0), "Kill the three harpy leaders: Hatescreech (36.1, 38.0), Gaedress (34.6, 36.0) and Arysa (35.0, 28.2).",
    "Hatescreech's Amulet", "Windmistress Gaedress' Amulet", "Witchmother Arysa's Amulet"),
  finish(98392, te.arynia), accept(98398, te.arynia),
  finish(98398, te.bark, "Touch the Oracle Tree Bark beside the glade."),
  accept(940, te.bark, "Take the report from the Oracle Tree Bark."),
  along(objectiveAt(2518, te.t("Lady Sathrah", 44.2, 25.5), "Find Lady Sathrah near Wellspring Lake. Bring help if needed. Loot tumors from nearby timberlings.", "Lady Sathrah's Silvery Spinnerets"), 923),
  objectiveAt(923, te.t(nil, 43.8, 27.2), "Kill Elder Timberlings and Mire Beasts around the north lakes for tumors. Blackmoss the Fetid (level 13) lurks nearby at 44.0, 30.2; its heart starts a quest.",
    "5 Mossy Tumors"),
  withItem(5179, accept(927, te.t("Blackmoss the Fetid", 44.0, 30.2), "Use the Moss-twined Heart from your bags to start the quest.")),
  action("goto", te.gate, "Go back south to the Darnassus gate."),
  finish(940, te.fandral, "Bring the report to Fandral in the Cenarion Enclave."),
  finish(923, te.rellian), accept(2498, te.rellian),
  finish(2518, te.amoora), accept(2520, te.amoora),
  withItem(8155, objectiveAt(2520, te.d(nil, 39.0, 85.0), "Place the spinnerets at the fountain inside the temple.", "Spinnerets placed")),
  finish(2520, te.amoora),
  action("hearth", te.keldamyr, "Head back to the inn in Dolanaar.", te.hearth),
  finish(99047, te.byancie), accept(99050, te.byancie),
  finish(98403, te.tallonkai),
  finish(7383, te.corithras), accept(935, te.corithras),
  objectiveAt(99050, te.narret, "Buy an Empty Vial from Narret and a Refreshing Spring Water from the innkeeper.", "Empty Vial", "Refreshing Spring Water"),
  finish(2498, te.denalan, "Go back to Denalan at Lake Al'Ameth."), accept(2499, te.denalan),
  finish(930, te.denalan), finish(931, te.denalan),
  finish(927, te.denalan, "Give Denalan the Moss-twined Heart."), accept(941, te.denalan),
  finish(941, te.t("Denalan's Planter", 60.8, 68.6), "Plant the Tainted Heart in the planter beside Denalan."),
  accept(2399, te.t("Sprouted Frond", 60.75, 68.56), "Check the Sprouted Frond in Denalan's planter."),
  finish(2399, te.t("Sprouted Frond", 60.75, 68.56)),
  along(objectiveAt(99050, te.t(nil, 56.0, 66.6), "Loot fronds from Lasher Sproutlings on the way to Oakenscowl's cave.", "6 Dewy Lasher Fronds"), 2499),
  along(objectiveAt(2499, te.t("Oakenscowl", 53.8, 75.1), "Kill elite Oakenscowl southwest of the lake. Bring help or use Next, then head to Gnarlpine Hold.", "Gargantuan Tumor"), 486),
  objectiveAt(486, te.ursal, "At level 11-12, go south-west to Gnarlpine Hold. Clear nearby furbolgs and pull Ursal alone. Use Next if the pull is unsafe.", "Ursal the Mauler slain"),
  action("goto", te.denalan, "Return east along the south side of Lake Al'Ameth to Denalan."),
  finish(2499, te.denalan),
  accept(4161, te.zarrin, "If you know Cooking and already have 7 Small Spider Legs from Webwood spiders, accept from Zarrin. Otherwise use Next."),
  finish(4161, te.zarrin),
  finish(486, te.athridas),
  finish(99050, te.byancie, "Return to Byancie in Dolanaar."), accept(99073, te.byancie),
  action("grind", te.t(nil, 51.5, 43.6), "If still under level 12, finish quests nearby or clear Befouled Webwoods.", { level = 12 }),
  finish(490, te.shayla, "Find Shayla on the road west. Turn in if you have 15 Gnarlpine Fangs. Otherwise use Next."),
  finish(99073, te.eralya, "Take the road west, then north to Sentinel Eralya."),
  action("goto", te.gate, "Return to the Darnassus gate."),
  finish(935, te.fandral), accept(98046, te.fandral),
  finish(98046, te.lariia, "Bring the vessel to Lariia in the Temple of the Moon."), accept(98065, te.lariia),
  finish(98065, te.tyrande), accept(98067, te.dalia),
  withItem("Lunar Pendant", objectiveAt(98067, te.d(nil, 41.2, 43.5), "Use the Lunar Pendant at the bank, the Cenarion Hold depths, the Craftsmen's Terrace inn and the city gate.",
    "Cenarion Hold depths", "Darnassus Bank", "Craftsmen's Terrace Inn", "City Gate")),
  finish(98067, te.dalia),
  accept(6344, te.mydrannul, "Find Mydrannul's general goods shop on the Craftsmen's Terrace."),
  action("goto", nil, "Take the pink portal in the Temple Gardens west of the bank to Rut'theran Village. Use Next when you arrive."),
  finish(6344, te.nessa), accept(6341, te.nessa),
  finish(6341, te.vesprystus), accept(6342, te.vesprystus),
  taxi("getfp", te.vesprystus, "Rut'theran Village, Teldrassil", "Learn the Rut'theran flight path from Vesprystus."),
  taxi("fly", te.caylais, "Auberdine, Darkshore", "Speak to Vesprystus again for the hippogryph to Auberdine. If the flight is unavailable, take the ferry from the village pier."),
  finish(6342, te.laird, "Find Laird below the Auberdine flight platform."),
  accept(6343, te.laird, "Get Laird's Response for Nessa. If Laird has no follow-up, use Next."),
  taxi("getfp", te.caylais, "Auberdine, Darkshore", "Learn the Auberdine flight path from Caylais Moonfeather."),
  finish(6343, te.nessa, "Fly back to Rut'theran from Caylais, or take the ferry from Auberdine's north pier. Give Nessa the response."),
  taxi("fly", te.caylais, "Auberdine, Darkshore", "Return to Auberdine by hippogryph or ferry. If you are already there, use Next."),
  action("boat", te.thamarian, "Take the Stormwind ship from Auberdine's south pier. Use Next in Stormwind Harbor.",
    { name = "Auberdine - Stormwind Harbor", suggest = { "darkshore" } }),
  accept(97220, sw("Manifest Clerk Philmor", 30.4, 28.9), "Before leaving the harbor, find Manifest Clerk Philmor on the north docks."),
  action("goto", te.harbor, "Leave the harbor east into the city."),
  taxi("getfp", dungar, "Stormwind, Elwynn", "Learn the Stormwind flight path from Dungar above the Trade District."),
  finish(97220, sw("Elaine Trias", 66.6, 73.4), "Take the shipment to Elaine Trias's cheese shop, just west of Dungar's tower."),
  accept(97222, sw("Elaine Trias", 66.6, 73.4)),
  objectiveAt(97222, sw("Elaine Trias", 66.6, 73.4), "Carry the shipment up the stairs in her shop and set it down outside the door."),
  finish(97222, sw("Elaine Trias", 66.6, 73.4)),
  action("goto", furlbrow, "Leave by the main gate. Take the road through Goldshire, then west over the bridge into Westfall to the Furlbrow farm."),
}

-- (e) Sources
te.sources = {
  "https://bindonforever.com/zones/teldrassil",
  "https://forg.gg/en/forever/zones/teldrassil",
  "https://bindonforever.com/quest/97977",
  "https://bindonforever.com/quest/99050",
  "https://bindonforever.com/quest/98067",
  "https://warcraft.wiki.gg/wiki/Idrieth_Mossgrove",
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
}


-- Loch Modan, Alliance alternate 11-18.
local lm = (function()
  local function loch(name, x, y) return at(name, x, y, lochModan) end
  local thorgrum = loch("Thorgrum Borrelson", 33.94, 50.95)
  local vidra = loch("Vidra Hearthstove", 34.83, 49.28)
  local kadrell = loch("Mountaineer Kadrell", 34.17, 47.84)
  local grenhild = loch("Grenhild Darktalon", 36.52, 48.31)
  local norric = loch("Norric Lochthane", 41.76, 19.05)
  local cobbleflint = loch("Mountaineer Cobbleflint", 22.07, 73.13)
  local rugelfuss = loch("Captain Rugelfuss", 23.23, 73.68)
  local gravelgaw = loch("Mountaineer Gravelgaw", 23.54, 76.40)
  local wallbang = loch("Mountaineer Wallbang", 23.47, 74.51)
  local ylva = loch("Mountaineer Ylva", 31.78, 86.32)
  local stormpike = loch("Mountaineer Stormpike", 24.76, 18.40)
  local mine = loch(nil, 35.9, 22.6)
  local jern = loch("Jern Hornhelm", 37.24, 47.38)
  local magmar = loch("Magmar Fellhew", 64.90, 66.66)
  local ironband = loch("Prospector Ironband", 65.93, 65.62)
  local dig = loch(nil, 69.6, 66.8)
  local marek = loch("Marek Ironheart", 81.76, 61.66)
  local daryl = loch("Daryl the Youngling", 83.47, 65.46)
  local bingles = loch("Bingles Blastenheimer", 63.56, 47.92)
  local toolbox = loch("Discarded Fishing Toolbox", 45.68, 43.29)
  local khara = loch("Khara Deepwater", 40.28, 39.28)
  local hinderweir = loch("Chief Engineer Hinderweir VII", 46.05, 13.61)
  local barrel = loch("Suspicious Barrel", 56.05, 13.24)

  q(418, "Thelsamar Blood Sausages", 11, 7)
  q(416, "Rat Catching", 11, 10)
  q(1339, "Mountaineer Stormpike's Task", 15, 9)
  q(86667, "Snowbound", 10, 10, nil, true)
  q(224, "In Defense of the King's Lands", 12, 10)
  q(267, "The Trogg Threat", 12, 10)
  q(307, "Filthy Paws", 15, 9)
  q(237, "In Defense of the King's Lands", 15, 10, 224)
  q(263, "In Defense of the King's Lands", 15, 10, 237)
  q(86585, "Banner of the Fallen", 17, 10, nil, true)
  q(217, "In Defense of the King's Lands", 17, 10, 263)
  q(436, "Ironband's Excavation", 18, 13)
  q(297, "Gathering Idols", 18, 13)
  breadcrumb(436, 297)
  q(298, "Excavation Progress Report", 15, 10)
  q(86613, "Excavation Tools", 18, 13, nil, true)
  quest[86613].startItem = 278049
  q(385, "Crocolisk Hunting", 15, 10)
  q(86758, "Twisting the Knife", 16, 12, nil, true)
  quest[86758].race = { "DWARF", "GNOME", "NIGHTELF", "SKYBORNE" }
  q(257, "A Hunter's Boast", 16, 11)
  q(258, "A Hunter's Challenge", 17, 11, 257)
  q(2038, "Bingles' Missing Supplies", 15, 12)
  q(86614, "Silver of the Waves", 20, 13, nil, true)
  q(250, "A Dark Threat Looms", 18, 16)
  q(199, "A Dark Threat Looms", 18, 16, 250)
  q(353, "Stormpike's Delivery", 15, 9, 1097)
  q(1338, "Stormpike's Order", 14, 9, 1339)
  quest[1338].optional = true
  q(414, "Stout to Kadrell", 10, 8, 413)
  q(2039, "Find Bingles", 15, 12)
  breadcrumb(2039, 2038)
  q(6387, "Honor Students", 10, 10)
  q(6391, "Ride to Ironforge", 10, 10, 6387)
  q(6388, "Gryth Thurden", 10, 10, 6391)
  q(6392, "Return to Brock", 10, 10, 6388)
  for _, id in ipairs({ 6387, 6391, 6388, 6392 }) do quest[id].race = { "DWARF", "GNOME" } end

  -- Pickups on the way in depend on how you arrive: Humans, Night Elves and Skyborne ride the
  -- tram from Stormwind, Dwarves and Gnomes walk in from South Gate Outpost. They are optional
  -- errands (Settings > Show optional quests): quest steps before the first Loch Modan step aren't
  -- skipped as travel, so they would pull a player who is already here back to the city.
  local byTram, byRoad = { "HUMAN", "NIGHTELF", "SKYBORNE" }, { "DWARF", "GNOME" }
  local function errand(races, step) step.race, step.optional = races, true; return step end
  -- Elmore's Task (Elwynn) and Shimmer Stout (Dun Morogh) are done in the racial start section,
  -- which this alternate's own audit path doesn't include.
  local function carried(step) step.chain = nil; return step end
  local brock = loch("Brock Stoneseeker", 37.0, 47.8)
  local gryth = at("Gryth Thurden", 55.5, 47.7, ironforge)

  local steps = {
    -- Keep the approach off the Loch Modan map until the first local step.
    errand({ "HUMAN" }, carried(accept(353, sw("Grimand Elmore", 59.7, 33.8),
      "If you did Elmore's Task in Elwynn, take Grimand Elmore's package in the Dwarven District, beside the tram. Otherwise use Next."))),
    action("goto", nil, "Reach Ironforge via the Deeprun Tram in Stormwind's Dwarven District. If you are in Kalimdor, take the Auberdine ship to Stormwind. Use Next on the tram's Ironforge platform, or in Dun Morogh."),
    errand(byTram, accept(6661, nil, "Monty stands on the Ironforge platform of the tram. Take his Rat Catcher's Flute.")),
    errand(byTram, objectiveAt(6661, nil, "Play the flute next to the Deeprun Rats on the platform and along the tracks, then lead five of them back to Monty.",
      "5 Rats Captured")),
    errand(byTram, finish(6661, nil, "Give Monty the rats and his flute back. Leave his brother's carton for a later trip.")),
    errand(byTram, accept(2039, at("Gnoarn", 69.2, 50.5, ironforge), "From level 12, Gnoarn in Tinker Town, by the tram, sends you to Bingles in Loch Modan.")),
    action("goto", at(nil, 86.28, 48.81, dunMorogh), "If you know the flight from Ironforge to Thelsamar, take it. Otherwise follow the Dun Morogh road east past Gol'Bolar Quarry to South Gate Outpost and enter the tunnel."),
    errand(byRoad, carried(accept(414, at("Mountaineer Barleybrew", 86.28, 48.81, dunMorogh),
      "If you finished Shimmer Stout, Barleybrew has a cask for Kadrell in Thelsamar. Otherwise use Next."))),
    taxi("getfp", thorgrum, "Thelsamar, Loch Modan",
      "From the Loch Modan end of South Gate Pass, take the north-east road to Thelsamar. Learn the flight path from Thorgrum Borrelson."),
    accept(418, vidra, "Find Vidra inside the Stoutlager Inn. Loot boars, bears and spiders as you travel between hubs, then top up on the way back to town."),
    accept(416, kadrell, "Find Kadrell on the road through town. He patrols."),
    errand(byRoad, finish(414, kadrell, "Give Kadrell the cask of stout.")),
    accept(1339, kadrell),
    accept(86667, grenhild),

    -- Dwarf and Gnome flight errand. It needs the Ironforge flight path from the end of Dun Morogh.
    accept(6387, brock, "Brock Stoneseeker stands outside the Stoutlager Inn. If you don't know the Ironforge flight yet, use Next to skip this errand."),
    finish(6387, thorgrum, "Bring Brock's list to Thorgrum at the flight point."),
    accept(6391, thorgrum),
    taxi("fly", gryth, "Ironforge, Dun Morogh", "Buy a flight to Ironforge from Thorgrum."),
    finish(6391, at("Golnir Bouldertoe", 51.5, 26.3, ironforge), "Find Golnir Bouldertoe north of the flight point."),
    accept(6388, at("Golnir Bouldertoe", 51.5, 26.3, ironforge)),
    finish(6388, gryth, "Take the picks to Gryth Thurden at the Ironforge flight point."),
    accept(6392, gryth),
    taxi("fly", thorgrum, "Thelsamar, Loch Modan", "Fly back to Thelsamar."),
    finish(6392, brock, "Give Brock the honorary picks."),

    -- Valley of Kings opening. Leave the deeper troggs for the second visit.
    along(action("goto", cobbleflint, "Take the road south to the Valley of Kings guard tower."), 418),
    accept(224, cobbleflint),
    accept(267, rugelfuss, "Climb to the top floor of the tower to find Captain Rugelfuss."),
    along(objectiveAt(224, loch(nil, 26.7, 56.9),
      "Hunt Stonesplinter Troggs and Scouts on the ridge north-east of the tower. Loot their teeth for The Trogg Threat as you go.",
      "10 Stonesplinter Troggs", "10 Stonesplinter Scouts"), 267),
    along(objectiveAt(267, loch(nil, 26.7, 56.9),
      "Finish collecting teeth from the Troggs and Scouts. Stay outside the higher-level camps deeper in the valley.",
      "8 Trogg Stone Teeth"), 224),
    finish(224, cobbleflint), finish(267, rugelfuss),

    -- Start the snow delivery on the way north. Do the mine after the hand-in.
    withItem(279380, objectiveAt(86667, loch(nil, 19.6, 63.1),
      "Use the Ceramic Jar on the snow at the Loch Modan end of South Gate Pass. Once it is full, take the west-shore road straight to Norric and save side kills for after the delivery.",
      "1 Jar of Snow")),
    finish(86667, norric, "Follow the road north through Thelsamar, then turn east to Norric's house on the north-west shore. If the snow melts, refill the jar or use Next."),
    action("goto", stormpike, "Follow the road west to Algaz Station and go upstairs in the bunker."),
    finish(1339, stormpike), errand({ "HUMAN" }, finish(353, stormpike, "Hand Stormpike the package from Elmore.")),
    accept(307, stormpike),
    along(objectiveAt(307, mine,
      "Enter Silver Stream Mine from the north. Open Miners' League Crates, pulling the kobolds singly and looting ears as you go. If the deeper tunnels are unsafe, use Next.",
      "4 Miners' Gear"), 416),
    finish(307, stormpike, "Take the gear back to Stormpike at Algaz Station before heading south."),
    accept(1338, stormpike, "Stormpike's request goes to Furen Longbeard in Stormwind. Take it if your next zone is reached through Stormwind."),
    along(objectiveAt(418, loch(nil, 27.7, 25.3),
      "Finish any missing sausage ingredients from Mountain Boars, Elder Black Bears and Forest Lurkers on the road south to Thelsamar.",
      "3 Boar Intestines", "3 Bear Meat", "3 Spider Ichor"), 416),
    objectiveAt(416, loch(nil, 25.1, 30.2),
      "Finish any missing ears on Tunnel Rat Vermin and Scouts farther south, then continue to Thelsamar.",
      "12 Tunnel Rat Ears"),
    finish(416, kadrell), finish(418, vidra),
    accept(436, jern, "At level 13 or higher, pick this up from Jern before the next circuit. Use Next if it is unavailable."),

    -- Second Valley loop. The banner waves and linked trio are manual choices.
    action("goto", gravelgaw, "Take the road south to the Valley of Kings. Find Gravelgaw by the southern tower."),
    accept(237, gravelgaw, "If you can handle level 13-14 troggs, pick up the next part from Gravelgaw."),
    objectiveAt(237, loch(nil, 32.9, 85.0),
      "Hunt Skullthumpers and Seers on the approach to the Stonesplinter caves. Fight on cleared ground and stop fleeing mobs from reaching another pack.",
      "10 Stonesplinter Skullthumpers", "10 Stonesplinter Seers"),
    finish(237, gravelgaw),
    accept(263, wallbang, "Take this part if you can handle level 15-16 troggs. Use Next to leave it for a later visit."),
    objectiveAt(263, loch(nil, 35.9, 91.7),
      "Hunt Shamans and Bonesnappers on the south-eastern slopes. Pull from the outside and stay clear of Grawmug's group and the deep cave.",
      "10 Stonesplinter Shaman", "10 Stonesplinter Bonesnappers"),
    accept(86585, ylva, "If ready for waves of troggs, find Ylva in the small upper cave. Use Next if the cave is unsafe."),
    withItem(253247, objectiveAt(86585, ylva,
      "Plant the Banner of Ironforge by Ylva. Clear the waves from both approaches, then defeat Headsplitter. Bring help or use Next if needed.",
      "1 Headsplitter slain")),
    finish(263, wallbang), finish(86585, rugelfuss),
    accept(217, rugelfuss, "Take this only if you have help or can handle three linked troggs. Otherwise use Next."),
    objectiveAt(217, loch(nil, 34.7, 90.6),
      "Grawmug, Gnasher and Brawler fight together in the Stonesplinter cave. Clear the approach first and use crowd control. Use Next if the pull is unsafe.",
      "1 Grawmug slain", "1 Gnasher slain", "1 Brawler slain"),
    finish(217, rugelfuss),

    -- South shore road to Ironband and Farstrider. Stay out of the Badlands.
    action("goto", loch(nil, 52.2, 69.3),
      "Follow the road around the south end of the loch toward Ironband's Excavation. Stay on the Loch Modan road past the wagon."),
    finish(436, magmar),
    accept(297, magmar, "From level 13, Magmar offers Gathering Idols. Take it if you can handle the level 18-20 dig-site troggs. Use Next to save it for a later visit."),
    accept(298, ironband, "Take Ironband's report while you are at the dig. Hand it in to Jern when you return to Thelsamar."),
    withItem(278049, accept(86613, dig, "Use the Excavation Tools starter from your bags. Check the tool piles on the wooden platforms for the rest.")),
    along(objectiveAt(297, dig, "Loot idols from Diggers and Berserk Troggs. Check the wooden platforms near 69.8, 65.0 for an Excavation Tools quest starter. Use it if you find one.",
      "8 Carved Stone Idols"), 86613),
    along(objectiveAt(86613, loch(nil, 69.8, 65.0), "Check the platforms for any remaining excavation tools. Use Next if the piles are empty or unsafe.",
      "6 Excavation Tools"), 297),
    finish(86613, ironband, "Look for the turn-in at Prospector Ironband. If the marker is on Magmar Fellhew, he is at 64.9, 66.7."),
    finish(297, magmar),

    action("goto", marek, "Take the road east and then north to Farstrider Lodge."),
    accept(385, marek), accept(86758, marek),
    accept(257, daryl, "Accept when ready to hunt. You have 15 minutes to kill the buzzards and get back to Daryl."),
    objectiveAt(257, loch(nil, 76.7, 62.3),
      "Hunt Mountain Buzzards west of the lodge. Give the wandering elite ogres and their escort a wide berth.",
      "6 Mountain Buzzards"),
    finish(257, daryl, "Return to Daryl before the timer ends. If it expired, abandon and retake the quest, or use Next."),
    accept(258, daryl, "Accept only when ready for the next hunt. The boars and the return trip share a 12-minute timer."),
    objectiveAt(258, loch(nil, 75.9, 45.3),
      "Start in the hills north of the lodge. If the nearer Elder Mountain Boars are taken, look north-west near 65.1, 41.2 if you have time. Return straight to Daryl and save the crocs for afterward.",
      "5 Elder Mountain Boars"),
    finish(258, daryl, "Return to Daryl before the timer ends. If it expired, abandon and retake the quest, or use Next."),
    -- East shore crocs, then Bingles' island. Finish the timed hunts first.
    along(objectiveAt(385, loch(nil, 61.6, 43.8),
      "Kill Loch Crocolisks along the east bank and watch for Daggerfang on the same pass. If you need more crocs, cross toward the middle island from directly east. Give Young Threshadons and the Large Loch Crocolisk room.",
      "5 Crocolisk Meat", "6 Crocolisk Skins"), 86758),
    along(objectiveAt(86758, loch("Daggerfang", 63.4, 45.3),
      "Look along the east shore for Daggerfang if you still need the knife. Use Next if the patrol is absent.",
      "1 Marek's Croc-Hunting Knife"), 385),
    finish(385, marek), finish(86758, marek),
    errand(byTram, finish(2039, bingles, "Follow the east shore north to Bingles by his crashed machine.")),
    accept(2038, bingles, "Follow the east shore north to Bingles by his crashed machine. From level 12, take his supplies quest if offered."),
    objectivePart(2038, 1, loch(nil, 48.73, 30.09),
      "Start at the southern camp. Pull troggs away from the toolbucket before taking the wrench. Use Next to move past a camp you cannot clear.", "1 Bingles' Wrench"),
    objectivePart(2038, 2, loch(nil, 48.38, 20.51),
      "Follow the west side of the island north to the toolbucket with the screwdriver.", "1 Bingles' Screwdriver"),
    objectivePart(2038, 3, loch(nil, 51.78, 24.09),
      "Head south-east to the middle camp and take the hammer from its toolbucket.", "1 Bingles' Hammer"),
    objectivePart(2038, 4, loch(nil, 54.21, 26.60),
      "Finish at the east camp. Pull the Shamans and Bonesnappers away from the Blastencapper.", "1 Bingles' Blastencapper"),
    finish(2038, bingles, "Return to Bingles on the east shore. Use Next if you left a tool for a later visit."),

    -- Dam and west shore. End in Loch Modan after the local hand-ins.
    action("goto", hinderweir, "Follow the road north toward Stonewrought Dam, taking the shore or dam crossing clear of the Mo'grosh camps."),
    accept(250, hinderweir, "At level 16 or higher, speak to the engineer below the dam's west end. Use Next if this is unavailable."),
    finish(250, barrel, "Cross to the east ramp and check the barrel. Pull the sappers separately. Use Next if you cannot reach the barrel safely."),
    accept(199, barrel, "Take the clue from the barrel."),
    finish(199, hinderweir, "Take the clue back to Hinderweir on the west side of the dam."),
    accept(86614, toolbox, "If the Discarded Fishing Toolbox is visible in the loch and the water is clear, take the quest from it. The toolbox has several possible spots. Use Next if absent or unsafe."),
    finish(86614, khara, "Bring the hair clip to Khara on the west-shore dock."),
    finish(298, jern, "Follow the west-shore road south to Thelsamar and hand Ironband's report to Jern."),
    finish(1338, sw("Furen Longbeard", 64.6, 37.2),
      "If your next zone is south of Stormwind, take the tram back and give Stormpike's request to Furen Longbeard in the Dwarven District."),
  }

  return { steps = steps, sources = {
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
    "https://bindonforever.com/zones/loch-modan",
    "https://polestar.guide/guides/alliance/03-loch-modan",
    "https://warcraft.blizzplanet.com/world-of-warcraft-forever-loch-modan-quests/",
    "https://senseos.gg/wiki/wow-forever/interactive-map/loch-modan/",
    "https://zygorguides.com/blog/important-tips-and-info-for-zygors-classic-guides/",
  } }
end)()

-- Darkshore, Alliance alternate 12-20.
local ds = (function()
  local function shore(name, x, y) return at(name, x, y, te.darkshore) end

  local inn = shore("Innkeeper Shaussiy", 37.04, 44.13)
  local gwennyth = shore("Gwennyth Bly'Leggonde", 36.62, 45.59)
  local wizbang = shore("Wizbang Cranktoggle", 36.97, 44.13)
  local glynda = shore("Sentinel Glynda Nal'Shea", 37.7, 43.41)
  local tharnariun = shore("Tharnariun Treetender", 38.84, 43.42)
  local terenthis = shore("Terenthis", 39.37, 43.48)
  local thundris = shore("Thundris Windweaver", 37.4, 40.13)
  local cerellean = shore("Cerellean Whiteclaw", 35.74, 43.71)
  local tysha = shore("Sentinel Tysha Moonblade", 40.3, 59.73)
  local asterion = shore("Asterion", 44.17, 36.29)
  local barithras = shore("Barithras Moonshade", 37.32, 43.64)
  local elissa = shore("Sentinel Elissa Starbreeze", 39.05, 43.55)
  local balthule = shore("Balthule Shadowstrike", 54.97, 24.89)
  local gubber = shore("Gubber Blump", 36.1, 44.93)
  local hollee = shore("Archaeologist Hollee", 37.44, 41.84)
  local remtravel = shore("Prospector Remtravel", 35.73, 83.7)
  local onu = shore("Onu", 43.55, 76.29)
  local arbal = shore("Arbal", 43.75, 76.5)
  local gelkak = shore("Gelkak Gyromast", 56.66, 13.48)
  local volcor = shore("Volcor", 45.01, 85.3)
  local moonwell = shore("Auberdine Moonwell", 37.78, 44.03)
  local crystal = shore("Mysterious Red Crystal", 47.32, 48.68)
  local tome = shore("Twilight Tome", 38.54, 86.05)
  local glaive = shore("Scrying Bowl", 38.48, 86.45)
  local buzz827 = shore("Buzzbox 827", 36.64, 46.26)
  local buzz411 = shore("Buzzbox 411", 41.96, 28.62)
  local buzz323 = shore("Buzzbox 323", 51.29, 24.57)
  local buzz525 = shore("Buzzbox 525", 41.39, 80.56)
  local hearth = { bind = "Auberdine" }
  -- Gap fill places (tools/audits/2026-11-10-darkshore-ashenvale-wetlands-gaps.md).
  local board = shore("Wanted Poster", 37.22, 44.22)
  local alanndarian = shore("Alanndarian Nightsong", 37.69, 40.66)
  local gorbold = shore("Gorbold Steelhand", 38.11, 41.17)
  local greywhisker = te.d("Chief Archaeologist Greywhisker", 31.25, 84.5)
  -- Profession errands: shown with Settings > Show optional quests.
  local function errand(step)
    step.optional = true
    return step
  end

  q(3524, "Washed Ashore", 13, 11)
  q(4681, "Washed Ashore", 14, 11, 3524)
  q(983, "Buzzbox 827", 10, 7)
  q(1001, "Buzzbox 411", 12, 7, 983)
  q(1002, "Buzzbox 323", 14, 7, 1001)
  q(1003, "Buzzbox 525", 16, 7, 1002)
  q(984, "How Big a Threat?", 14, 10)
  q(985, "How Big a Threat?", 14, 10, 984)
  q(2118, "Plagued Lands", 14, 10)
  q(2138, "Cleansing of the Infected", 16, 10, 2118)
  q(2139, "Tharnariun's Hope", 18, 10, 2138)
  q(4811, "The Red Crystal", 14, 12)
  q(4812, "As Water Cascades", 14, 12, 4811)
  q(4813, "The Fragments Within", 14, 12, 4812)
  q(954, "Bashal'Aran", 12, 7)
  q(955, "Bashal'Aran", 12, 7, 954)
  q(956, "Bashal'Aran", 13, 7, 955)
  q(957, "Bashal'Aran", 13, 7, 956)
  q(953, "The Fall of Ameth'Aran", 12, 9)
  q(958, "Tools of the Highborne", 12, 9)
  q(963, "For Love Eternal", 16, 11)
  q(4761, "Thundris Windweaver", 15, 11, 984)
  q(4762, "The Cliffspring River", 15, 11, 4761)
  q(4763, "The Blackwood Corrupted", 18, 15, 4762)
  q(4723, "Beached Sea Creature", 13, 11, 4681)
  q(4725, "Beached Sea Turtle", 15, 12, 4681)
  q(4727, "Beached Sea Turtle", 15, 12, 4681)
  q(4722, "Beached Sea Turtle", 13, 11, 4681)
  q(4728, "Beached Sea Creature", 14, 12, 4681)
  q(4730, "Beached Sea Creature", 16, 12, 4681)
  q(4731, "Beached Sea Turtle", 19, 13, 4681)
  q(4732, "Beached Sea Turtle", 19, 13, 4681)
  q(4733, "Beached Sea Creature", 19, 13, 4681)
  q(947, "Cave Mushrooms", 17, 12)
  q(948, "Onu", 17, 12, 947)
  q(944, "The Master's Glaive", 17, 12, 948)
  q(949, "The Twilight Camp", 17, 12, 944)
  q(950, "Return to Onu", 17, 12, 949)
  q(951, "Mathystra Relics", 20, 12, 950)
  q(98042, "It's All Fun and Games Until...", 17, 12, nil, true)
  q(98013, "Swelling Forces", 20, 12, nil, true)
  q(87760, "Holy Diver", 20, 15, { 4722, 4723, 4725, 4727, 4728, 4730, 4731, 4732, 4733 }, true)
  q(98028, "Baron Marinous", 21, 17, nil, true)
  quest[98028].startItem = 279275
  q(965, "The Tower of Althalaxx", 18, 13)
  q(966, "The Tower of Althalaxx", 18, 13, 965)
  q(986, "A Lost Master", 20, 10, 985)
  q(993, "A Lost Master", 20, 10, 986)
  q(995, "Escape Through Stealth", 20, 10, 993)
  q(729, "The Absent Minded Prospector", 20, 15)
  q(1138, "Fruit of the Sea", 17, 15)
  q(2098, "Gyromast's Retrieval", 20, 14)
  q(98025, "WANTED: Jai'vhanel", 13, nil, nil, true)
  q(4740, "WANTED: Murkdeep!", 18, 15)
  q(982, "Deep Ocean, Vast Sea", 17, 13)
  q(2178, "Easy Strider Living", 12, 9)
  q(1141, "The Family and the Fishing Pole", 14, 10)
  q(731, "The Absent Minded Prospector", 20, 15, 729)
  q(741, "The Absent Minded Prospector", 20, 15, 731)
  q(942, "The Absent Minded Prospector", 20, 15, 741)
  q(968, "The Powers Below", 20, 10)
  quest[968].startItem = 5352
  q(2078, "Gyromast's Revenge", 20, 14, 2098)
  q(97926, "Making Do", 17, nil, nil, true)
  q(97894, "Business in Auberdine", 17, nil, nil, true)
  quest[97894].optional = true

  local makingDo = accept(97926, sw("Baros Alexston", 57.74, 47.86),
    "Leaving from Stormwind? Baros Alexston near the Cathedral has a reply for Thundris in Auberdine. Use Next if you are already in Darkshore.")
  local makingDoDone = finish(97926, thundris, "Give Baros's reply to Thundris Windweaver north of the inn.")
  makingDo.race = { "HUMAN", "DWARF", "GNOME", "SKYBORNE" }
  makingDoDone.race = { "HUMAN", "DWARF", "GNOME", "SKYBORNE" }
  local steps = {
    makingDo,
    accept(97894, sw("Borgus Steelhand", 59.4, 34.26),
      "Also leaving from Stormwind: Borgus Steelhand in the Dwarven District wants news of his brother in Auberdine."),
    action("boat", sw(nil, 21.8, 56.8),
      "From Stormwind, board the Auberdine ship at the southernmost harbor dock. From Rut'theran Village, take the Auberdine ferry or fly if you know both flight paths. Use Next after you reach Auberdine.",
      { name = "Stormwind Harbor - Auberdine" }),
    taxi("getfp", te.caylais, "Auberdine, Darkshore", "Learn the Auberdine flight path from Caylais Moonfeather."),
    action("sethearth", inn, "Bind your hearthstone at the Auberdine inn. Laird is nearby if you need to sell.", hearth),
    finish(97894, gorbold, "Gorbold Steelhand stands outside the house north of the inn."),

    -- South beach, the nearest Blackwood camp, then the low-level ruins.
    accept(3524, gwennyth), accept(983, wizbang), accept(984, terenthis),
    accept(98025, board, "Read the wanted poster outside the inn for Jai'vhanel, a black owl near Ameth'Aran."),
    accept(4811, glynda), accept(2118, tharnariun),
    makingDoDone, accept(954, thundris),
    errand(accept(2178, alanndarian, "With Cooking 10 or higher, take Alanndarian's request for strider meat.")),
    errand(accept(1141, gubber, "If you fish, take Gubber's request for Darkshore Grouper.")),
    objectiveAt(3524, shore("Beached Sea Creature", 36.37, 50.92),
      "Search the carcass on the beach south of Auberdine. Pull any nearby murlocs clear first.", "Sea Creature Bones"),
    objectiveAt(983, shore(nil, 35.5, 49.9),
      "Loot Crawler Legs from Pygmy Tide Crawlers on the beach between the carcass and town.", "6 Crawler Legs"),
    objectiveAt(984, shore(nil, 39.34, 53.51),
      "Approach the Blackwood camp from the road until the scouting objective updates.", "Corrupt furbolg camp found"),
    objectiveAt(4811, crystal, "Head inland to the red crystal at the eastern mountains and approach it.", "Red crystal located"),
    finish(954, asterion, "Follow the hillside north to the blue glow in Bashal'Aran and speak to Asterion."),
    accept(955, asterion),
    objectiveAt(955, shore(nil, 45.2, 38.2),
      "Kill Vile Sprites and Wild Grell around the ruins for earrings.", "8 Grell Earrings"),
    finish(955, asterion), accept(956, asterion),
    objectiveAt(956, shore(nil, 47.2, 37.6),
      "Loot the seal from a Deth'ryll Satyr on the east side of the ruins.", "Ancient Moonstone Seal"),
    finish(956, asterion), accept(957, asterion),
    withItem(7586, objectiveAt(2118, shore(nil, 46.2, 33.5),
      "Set Tharnariun's bear trap, then lead a living Rabid Thistle Bear across it. Return for a replacement if the trap is lost.", "Rabid Thistle Bear Captured")),
    errand(objectiveAt(2178, shore(nil, 46.0, 33.0), "Loot Strider Meat from the Foreststriders on the hills around the trap.", "5 Strider Meat")),

    action("goto", shore(nil, 38.8, 43.4), "Return to Auberdine for the second set of pickups."),
    finish(984, terenthis), accept(985, terenthis), accept(4761, terenthis),
    finish(2118, tharnariun), accept(2138, tharnariun),
    errand(finish(2178, alanndarian)),
    finish(4761, thundris), accept(4762, thundris), accept(958, thundris),
    errand(objectiveAt(1141, shore(nil, 35.6, 45.3), "Fish from the end of the Auberdine pier until you have the grouper.", "6 Darkshore Grouper")),
    errand(finish(1141, gubber)),
    finish(4811, glynda), accept(4812, glynda),
    withItem(14338, objectiveAt(4812, moonwell,
      "Use the Empty Water Tube at the moonwell before leaving town.", "Moonwell Water Tube")),
    accept(963, cerellean),
    finish(3524, gwennyth), accept(4681, gwennyth),
    finish(983, buzz827), accept(1001, buzz827),
    objectiveAt(4681, shore("Skeletal Sea Turtle", 31.82, 46.31),
      "Swim west from Auberdine and search the skeletal turtle on the seabed. Surface before swimming back.", "Sea Turtle Remains"),
    finish(4681, gwennyth),
    accept(947, barithras),

    -- Ameth'Aran and the south Blackwood camp.
    objectiveAt(985, shore(nil, 39.6, 54.5),
      "Return to the Blackwood camp south-east of town. Pull the Pathfinders and Windtalkers out of the camp one at a time.",
      "8 Blackwood Pathfinders", "5 Blackwood Windtalkers"),
    accept(953, tysha, "Find Sentinel Tysha Moonblade on the road just west of Ameth'Aran."),
    along(objectiveAt(98025, shore(nil, 44.3, 57.7), "Kill Jai'vhanel, the black owl on the slope north of the ruins, and take her feather.",
      "Feather of Jai'vhanel"), 953, 958),
    along(objectiveAt(953, shore(nil, 43.3, 58.7),
      "Read the Lay at 43.3, 58.7 and the Fall at 42.6, 63.1. Loot ghosts for relics as you cross the ruins.",
      "Read the Lay of Ameth'Aran", "Read the Fall of Ameth'Aran"), 958, 963, 957),
    along(objectiveAt(958, shore(nil, 43.3, 60.7),
      "Loot any remaining relics from Highborne ghosts. Watch for Anaya near the west side and the flame to the south.",
      "7 Highborne Relics"), 953, 963, 957),
    along(objectiveAt(963, shore("Anaya Dawnrunner", 41.81, 60.73),
      "Find Anaya Dawnrunner among the ghosts near the west side. Loot her pendant.", "Anaya's Pendant"), 958, 957),
    along(objectiveAt(957, shore("Ancient Flame", 42.4, 61.8),
      "Interact with the Ancient Flame to destroy the seal before leaving the ruins.", "Destroy the seal at the ancient flame"), 958, 963),
    finish(953, tysha),
    accept(4722, shore("Beached Sea Turtle", 37.09, 62.18),
      "On the shore west of Ameth'Aran, search the turtle and take the quest. Watch the nearby murlocs."),
    action("goto", shore(nil, 38.8, 43.4), "Follow the road back to Auberdine."),
    finish(985, terenthis), accept(986, terenthis),
    finish(958, thundris), finish(963, cerellean), finish(4722, gwennyth),
    finish(98025, glynda),
    accept(965, elissa),
    accept(982, gorbold, "Gorbold Steelhand, outside the house north of the inn, lost two lockboxes in the wrecks off the north coast."),

    -- North coast and Cliffspring, then back through Bashal'Aran and the crystal.
    objectiveAt(1001, shore(nil, 34.5, 35.4),
      "Take the coast north. Swim out for Darkshore Threshers if the water is safe. Surface between pulls. Use Next to skip the quest if needed.",
      "3 Thresher Eyes"),
    along(objectiveAt(982, shore(nil, 38.9, 28.1),
      "Swim out to the two sunken ships off this stretch of coast and loot a lockbox from each deck. Surface between the wrecks.",
      "Silver Dawning's Lockbox", "Mist Veil Lockbox"), 1001),
    accept(4723, shore("Beached Sea Creature", 41.93, 31.53),
      "Pick up the beached creature quest along the northern shore."),
    finish(1001, buzz411), accept(1002, buzz411),
    accept(4725, shore("Beached Sea Turtle", 44.19, 20.6),
      "Collect the marked box from the turtle near the Greymist camp. If the murlocs are too dangerous, skip this pickup."),
    accept(4727, shore("Beached Sea Turtle", 53.11, 18.08),
      "Search the turtle farther along the north shore. Follow the road and approach from land. Skip it if the approach is unsafe."),
    withItem(12350, objectiveAt(4762, shore(nil, 50.8, 25.5),
      "Use the Empty Sampling Tube in the pool at the Cliffspring River waterfall near the bridge.", "Cliffspring River Sample")),
    along(objectiveAt(1002, shore(nil, 47.5, 27.3),
      "Loot fangs by the north road. If you can handle level 17-20 cats, Sires and Matriarchs near 60, 13 drop fangs and pelts. You can also finish pelts on the south loop.",
      "6 Moonstalker Fangs"), 986),
    finish(1002, buzz323), accept(1003, buzz323),
    finish(965, balthule), accept(966, balthule),
    objectiveAt(966, shore(nil, 56.5, 26.2),
      "Loot parchments from Dark Strand Fanatics outside the tower. Pull from the edge of the camp.", "4 Worn Parchments"),
    finish(966, balthule),
    objectiveAt(947, shore("Cliffspring Falls Cave Mouth", 54.92, 33.31),
      "Gather mushrooms in the falls cave. Clear your retreat and avoid pushing deeper while mobs are respawning.",
      "5 Scaber Stalks", "1 Death Cap"),
    objectiveAt(2138, shore(nil, 47.4, 33.2),
      "Kill Rabid Thistle Bears between the falls and Bashal'Aran. Count any you killed during the northern loop.",
      "20 Rabid Thistle Bears"),
    finish(957, asterion),
    finish(4812, crystal), accept(4813, crystal),
    finish(4813, glynda), finish(2138, tharnariun),
    finish(947, barithras), accept(948, barithras),
    finish(4762, thundris), finish(982, gorbold),
    finish(4723, gwennyth), finish(4725, gwennyth), finish(4727, gwennyth),

    -- The south coast, Grove of the Ancients, and Master's Glaive.
    accept(729, hollee, "At level 15 or higher, ask Archaeologist Hollee to check on Remtravel."),
    accept(1138, gubber, "At level 15 or higher, pick up Fruit of the Sea for the southern shore."),
    accept(4740, board, "Take the Murkdeep poster outside the inn as well."),
    accept(4728, shore("Beached Sea Creature", 36.01, 70.88),
      "Follow the south road, then cut west to the beached creature."),
    objectiveAt(4740, shore(nil, 36.5, 76.6),
      "Clear the Greymist murlocs at the huts on the shore to the south. Murkdeep, level 19, comes out after the waves; rest to full before he arrives.",
      "Murkdeep slain"),
    finish(948, onu, "Return to the road and find Onu at the Grove of the Ancients."),
    accept(944, onu), accept(98013, arbal),
    objectiveAt(1003, shore(nil, 40.2, 81.2),
      "Loot scalps from Grizzled Thistle Bears south of the grove as you head for Buzzbox 525.", "4 Grizzled Scalps"),
    finish(1003, buzz525),
    objectiveAt(986, shore(nil, 38.9, 81.6),
      "Loot pelts from Moonstalker Sires or Matriarchs. The younger cats do not carry the pelts.",
      "5 Fine Moonstalker Pelts"),
    accept(4730, shore("Beached Sea Creature", 32.69, 80.79)),
    accept(4731, shore("Beached Sea Turtle", 31.67, 83.68)),
    accept(4732, shore("Beached Sea Turtle", 31.23, 85.6)),
    accept(4733, shore("Beached Sea Creature", 31.26, 87.44)),
    objectiveAt(1138, shore(nil, 32.9, 82.9),
      "Loot crab chunks from Encrusted Tide Crawlers along this coast. Reef Crawlers can also drop them.",
      "6 Fine Crab Chunks"),
    finish(729, remtravel, "Check on Remtravel at the excavation. The escort can wait for a group."),
    accept(731, remtravel, "Start Remtravel's escort when the dig site is clear, or use Next to leave it."),
    objectiveAt(731, remtravel, "Stay with Remtravel while he searches the dig. Kill anything that ambushes him on the way.", "Remtravel escorted"),
    withItem(5251, objectiveAt(944, glaive,
      "Enter the Master's Glaive and use the Phial of Scrying in a cleared spot to place the bowl.", "Enter the Master's Glaive")),
    withItem(5251, finish(944, glaive, "If the bowl is missing, use the Phial of Scrying here. Speak to Onu through the bowl.")),
    accept(949, glaive, "Take the follow-up from the Scrying Bowl."),
    finish(949, tome, "Inspect the Twilight Tome in the camp."), accept(950, tome),
    accept(98042, tome, "Check the Twilight Tome for the Peerless Eye quest."),
    objectiveAt(98042, shore(nil, 38.7, 85.6),
      "Loot a Peerless Eye from a Twilight Disciple or Twilight Thug. Pull from the edge of the camp.", "Peerless Eye"),
    withItem(5352, accept(968, nil, "If a cultist dropped Book: The Powers Below, read it. The book goes to Gerrig Bonegrip in Ironforge.")),
    finish(950, onu), accept(951, onu),
    action("hearth", inn, "Follow the road north to Auberdine if you're walking.", hearth),
    finish(986, terenthis), accept(993, terenthis), accept(2139, tharnariun),
    finish(98042, thundris), accept(4763, thundris, "At level 15 or higher, get the Empty Cleansing Bowl."),
    finish(731, hollee, "If you escorted Remtravel, bring his fossil news to Archaeologist Hollee."), accept(741, hollee),
    accept(98461, hollee, "Heading to the Wetlands later? Hollee has a note for Tarrel Rockweaver in Menethil Harbor."),
    finish(4740, glynda), finish(1138, gubber),
    finish(4728, gwennyth), finish(4730, gwennyth), finish(4731, gwennyth),
    finish(4732, gwennyth), finish(4733, gwennyth),

    -- The later north loop combines the furbolg camps, Mathystra and the far shore.
    accept(87760, gwennyth, "After all nine beach turn-ins and at level 15 or higher, ask Gwennyth about the Stormscale rod."),
    withItem(12346, objectiveAt(4763, moonwell,
      "Fill the Empty Cleansing Bowl at the Auberdine moonwell. Use Next once you have the Filled Cleansing Bowl.", "Filled Cleansing Bowl")),
    withItem(12347, objectiveAt(4763, shore("Bonfire", 52.38, 33.39),
      "Clear around the stores before looting Grain (50.66, 34.94), Nut (51.83, 33.50) and Fruit (52.86, 33.42). Use the filled bowl at the north bonfire, defeat Xabraxxis and loot the talisman from the basket left behind.",
      "Blackwood Grain Sample", "Blackwood Nut Sample", "Blackwood Fruit Sample", "Talisman of Corruption")),
    objectiveAt(2139, shore(nil, 51.5, 38.3),
      "Kill the Den Mother east of the falls road when you can safely clear the cubs. Skip if the den is unsafe.", "Den Mother slain"),
    along(objectiveAt(951, shore(nil, 58.6, 23.7),
      "Gather loose relics in Mathystra while clearing Stormscale naga.", "6 Mathystra Relics"), 98013),
    along(objectiveAt(98013, shore(nil, 58.6, 22.7),
      "Kill Stormscale naga in Mathystra. Warriors are more common toward the east and north-east. Pull singles between the ruins.",
      "12 Stormscale Myrmidons", "8 Stormscale Sorceresses", "6 Stormscale Warriors"), 951),
    withItem(279275, accept(98028, nil, "If you already have a Clouded Water Globe, use it to start the quest for Onu.")),
    accept(2098, gelkak, "Find Gelkak Gyromast on the far north shore."),
    objectiveAt(2098, shore(nil, 54.0, 18.4),
      "Loot the top of the key from Giant Foreststriders, the middle from murlocs, and the bottom from Encrusted Tide Crawlers or Raging Reef Crawlers. Work the north shore between Gelkak and the beached turtle.",
      "Top of Gelkak's Key", "Middle of Gelkak's Key", "Bottom of Gelkak's Key"),
    finish(2098, gelkak),
    accept(2078, gelkak, "Gelkak wants his robot back. It turns on you once it reaches him, so start at full health."),
    objectiveAt(2078, shore("The Threshwackonator 4100", 55.8, 18.3),
      "Find the Threshwackonator on the shore just south of Gelkak, switch it on and lead it to him. Kill it when it attacks.", "Gelkak's First Mate"),
    finish(2078, gelkak),
    objectiveAt(87760, shore(nil, 49.4, 14.4),
      "Swim out to the rock spire off the north shore. Kill a Stormscale Beastmistress for her rod and surface for air between pulls.", "Rod of Deep Dominion"),
    action("hearth", inn, "Follow the road back to Auberdine if you're walking.", hearth),
    finish(87760, gwennyth), finish(4763, thundris), finish(2139, tharnariun),

    -- Close out the grove turn-ins and the safer Volcor resolution.
    action("goto", onu, "Take the south road back to the Grove of the Ancients for the Mathystra turn-ins."),
    finish(951, onu), finish(98013, arbal), finish(98028, onu),
    finish(993, volcor, "Find Volcor at the Blackwood Den. Clear the approach before going in."),
    accept(995, volcor, "Choose Escape Through Stealth if offered. If you already chose Escape Through Force, skip this pickup."),
    objectiveAt(995, volcor, "Stay with Volcor until he gets clear of the den and the quest updates.", "Volcor escaped"),
    action("goto", shore(nil, 38.8, 43.4), "Follow the road north to Auberdine."),
    finish(995, terenthis),

    -- Remtravel's fossil: Darnassus, then the Menethil ship (the Wetlands chapters start there).
    taxi("fly", te.vesprystus, "Rut'theran Village, Teldrassil",
      "Carry the fossil to Darnassus: fly from Caylais to Rut'theran Village, or take the ferry from the north pier."),
    action("goto", nil, "Take the portal beside the Rut'theran pier up to Darnassus. Use Next when you arrive."),
    finish(741, greywhisker, "Find Chief Archaeologist Greywhisker on the terrace south-west of the Temple of the Moon."),
    accept(942, greywhisker, "Greywhisker sends the fossil on to Menethil Harbor."),
    taxi("fly", te.caylais, "Auberdine, Darkshore", "Take the portal down, then fly or ride the ferry back to Auberdine."),
    action("boat", shore(nil, 32.4, 44.1), "When you head for the Wetlands, take the Menethil ship from Auberdine's west pier. Use Next in Menethil Harbor.",
      { name = "Auberdine - Menethil Harbor" }),
    finish(942, at("Archaeologist Flagongut", 10.84, 60.43, wetlands), "Give the fossil to Archaeologist Flagongut near the Menethil docks."),
    finish(968, at("Gerrig Bonegrip", 50.83, 5.62, ironforge), "Bring the book to Gerrig Bonegrip in the Forlorn Cavern the next time you are in Ironforge."),
  }

  return {
    steps = steps,
    stormwindShip = { waypoint = te.thamarian, label = "Take the Stormwind ship from the south pier" },
    sources = {
      "https://worldofwarcraft.blizzard.com/en-us/news/24304071/world-of-warcraft-forever-found-photos-panel-recap",
      "https://azeroth.wiki/forever/quests/business-in-auberdine",
      "https://wago.tools/db2/QuestV2?build=1.60.1.70862",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf",
      "https://www.wowhead.com/forever/quests/kalimdor/darkshore",
      "https://bindonforever.com/zones/darkshore",
      "https://zygorguides.com/blog/new-smart-injection-system-quest-catchup-feature-for-classic/",
    },
  }
end)()

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
local duskSources = {
  "https://bindonforever.com/zones/duskwood",
  "https://polestar.guide/guides/alliance/04-redridge-mountains",
  "https://questing.wiki/wow-forever/leveling/duskwood/",
  "https://www.wowhead.com/forever/quest=96137/iras-dagger",
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
}
local wetSources = {
  "https://bindonforever.com/zones/wetlands",
  "https://www.warcrafttavern.com/forever/guides/leveling",
  "https://mobalytics.gg/wow-forever/guides/zone-map-level-ranges",
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
}
local lakeshireSources = {
  "https://bindonforever.com/zones/redridge-mountains",
  "https://questing.wiki/wow-forever/leveling/redridge/",
  "https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/",
}

LevelingCodexQuests = {
  ALLIANCE = {
    starts = { HUMAN = "northshire", DWARF = "coldridge", GNOME = "coldridge", SKYBORNE = "zephras",
      NIGHTELF = "shadowglen" },
    -- Width and height in yards, from UiMapAssignment in the Forever client reference.
    extents = { [elwynn] = { 3470.833, 2314.583 }, [stormwind] = { 1737.504, 1158.340 },
      [westfall] = { 3500, 2333.333 }, [redridge] = { 2170.834, 1447.916 }, [duskwood] = { 2700, 1800 },
      [wetlands] = { 4135.417, 2756.25 }, [lochModan] = { 2758.333, 1839.583 }, [ironforge] = { 790.625, 527.604 },
      [dunMorogh] = { 4925.0, 3283.333 }, [zephras] = { 5562.5, 3708.333 },
      [te.map] = { 5091.667, 3393.75 }, [te.darnassus] = { 1058.333, 705.729 }, [te.darkshore] = { 6550.0, 4366.667 } },
    -- Flight masters in each connected network are taken from the guide's flight-path steps.
    flightNetwork = { [stormwind] = 1, [westfall] = 1, [redridge] = 1, [duskwood] = 1,
      [ironforge] = 1, [lochModan] = 1, [wetlands] = 1, [te.map] = 2, [te.darkshore] = 2 },
    roadTo = {
      [redridge] = {
        [stormwind] = { waypoint = marcus, label = "Leave Stormwind for Redridge" },
        [elwynn] = { waypoint = thomas, label = "Take the east road to Redridge" },
        [te.darkshore] = ds.stormwindShip,
      },
      [westfall] = {
        [te.darkshore] = ds.stormwindShip,
        [stormwind] = { waypoint = marcus, label = "Leave Stormwind for Westfall via Goldshire" },
      },
      [duskwood] = { [te.darkshore] = ds.stormwindShip },
      [stormwind] = { [te.darkshore] = ds.stormwindShip },
    },
    sections = {
      { id = "northshire", title = "Northshire Valley", zone = elwynn, levels = { 1, 5 },
        start = "HUMAN", verified = false, sources = sources, steps = withTrainers(northshire, abbeyTrainers) },
      { id = "elwynn", title = "Elwynn Forest", zone = elwynn, levels = { 6, 12 },
        start = "HUMAN", verified = false, sources = sources, steps = withTrainers(forest, goldshireTrainers) },
      { id = "coldridge", title = "Coldridge Valley", zone = dunMorogh, levels = { 1, 6 },
        start = { "DWARF", "GNOME" }, verified = false, sources = dm.sources, steps = dm.coldridge },
      { id = "dunmorogh", title = "Dun Morogh", zone = dunMorogh, levels = { 6, 12 },
        start = { "DWARF", "GNOME" }, verified = false, sources = dm.sources, steps = dm.kharanos },
      { id = "shadowglen", title = "Shadowglen", zone = te.map, levels = { 1, 6 },
        start = "NIGHTELF", verified = false, sources = te.sources, steps = withTrainers(te.shadowglen, te.shadowglenTrainers) },
      { id = "teldrassil", title = "Teldrassil", zone = te.map, levels = { 6, 12 },
        start = "NIGHTELF", verified = false, sources = te.sources, steps = withTrainers(te.teldrassil, te.dolanaarTrainers) },
      { id = "zephras", title = "Thendal Grove", zone = zephras, levels = { 1, 5 },
        start = "SKYBORNE", verified = false, sources = zi.sources, steps = withTrainers(zi.thendal, zi.thendalTrainers) },
      { id = "shendar", title = "Shen'dar Village", zone = zephras, levels = { 5, 8 },
        start = "SKYBORNE", verified = false, sources = zi.sources, steps = withTrainers(zi.shendar, zi.shendarTrainers) },
      { id = "valanaar", title = "Valanaar", zone = zephras, levels = { 8, 13 },
        start = "SKYBORNE", verified = false, sources = zi.sources, steps = withTrainers(zi.valanaar, zi.valanaarTrainers) },
      { id = "westfall", title = "Westfall", zone = westfall, levels = { 12, 18 },
        verified = false, sources = westSources, steps = west },
      { id = "lakeshire", title = "Lakeshire", zone = redridge, levels = { 17, 22 },
        verified = false, sources = lakeshireSources, steps = lakeshire },
      { id = "duskwood", title = "Duskwood", zone = duskwood, levels = { 21, 27 },
        verified = false, sources = duskSources, steps = dusk },
      { id = "wetlands", title = "Wetlands", zone = wetlands, levels = { 26, 30 },
        verified = false, sources = wetSources, steps = wet },
      { id = "loch-modan", title = "Loch Modan", zone = lochModan, levels = { 11, 18 }, alternate = true,
        suggest = { "wetlands", "duskwood", "lakeshire", "westfall", "darkshore" },
        verified = false, sources = lm.sources, steps = lm.steps },
      { id = "darkshore", title = "Darkshore", zone = te.darkshore, levels = { 12, 20 }, alternate = true,
        suggest = { "wetlands", "duskwood", "lakeshire", "westfall", "loch-modan" },
        verified = false, sources = ds.sources, steps = ds.steps },
    },
  },
}

-- Helpers for QuestClassData.lua, which loads next and removes this field.
LevelingCodexQuests.build = { at = at, q = q, quest = quest, accept = accept, finish = finish,
  objective = objective, objectiveAt = objectiveAt, action = action, taxi = taxi, withItem = withItem,
  breadcrumb = breadcrumb, withTrainers = withTrainers, forDungeon = forDungeon, along = along,
  withGuide = withGuide, objectivePart = objectivePart, maps = { elwynn = elwynn, stormwind = stormwind,
  westfall = westfall, redridge = redridge, duskwood = duskwood, wetlands = wetlands, lochModan = lochModan,
  ironforge = ironforge, dunMorogh = dunMorogh, teldrassil = te.map, darnassus = te.darnassus,
  darkshore = te.darkshore, zephras = zephras } }
