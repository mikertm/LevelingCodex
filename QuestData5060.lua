-- Alliance route, levels 50-60. Source notes: tools/audits/2026-11-10-alliance-50-60.md.
-- Uses the shared 30-60 helpers and travel data from QuestData3040.lua.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local M = B.maps
local at, q, quest = B.at, B.q, B.quest
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, withItem, along, breadcrumb = B.objectiveAt, B.withItem, B.along, B.breadcrumb
local forDungeon, withGuide, note = B.forDungeon, B.withGuide, B.note
local on = B.on

local SW_FLIGHT = "Stormwind, Elwynn"
local IF_FLIGHT = "Ironforge, Dun Morogh"
local THORIUM = "Thorium Point, Searing Gorge"
local THELSAMAR = "Thelsamar, Loch Modan"
local NETHERGARDE = "Nethergarde Keep, Blasted Lands"
local MORGANS = "Morgan's Vigil, Burning Steppes"
local LAKESHIRE = "Lakeshire, Redridge"
local BOOTY = "Booty Bay, Stranglethorn"
local RATCHET = "Ratchet, The Barrens"
local GADGETZAN = "Gadgetzan, Tanaris"
local AERIE = "Aerie Peak, The Hinterlands"
local CHILLWIND = "Chillwind Camp, Western Plaguelands"
local LIGHTSHOPE = "Light's Hope Chapel, Eastern Plaguelands"
local AUBERDINE = "Auberdine, Darkshore"
local RUTTHERAN = "Rut'theran Village, Teldrassil"
local TALRENDIS = "Talrendis Point, Azshara"
local TALONBRANCH = "Talonbranch Glade, Felwood"
local EVERLOOK = "Everlook, Winterspring"
local NIJEL = "Nijel's Point, Desolace"
local FEATHERMOON = "Feathermoon, Feralas"
local MARSHAL = "Marshal's Refuge, Un'Goro Crater"
local CENARION = "Cenarion Hold, Silithus"
local THERAMORE = "Theramore, Dustwallow Marsh"
local ASTRANAAR = "Astranaar, Ashenvale"
local MOONGLADE = "Nighthaven, Moonglade"

-- Sections are collected first and added at the end of the file, so every chapter knows which
-- quests this band picks up. A pickup whose prerequisite belongs to another band (a chain the
-- 40-50 route starts) stays only when an earlier main section turns that prerequisite in.
local chapters, mine, byId = {}, {}, {}
local function chapter(id, title, zone, low, high, sources, steps, extra)
  chapters[#chapters + 1] = { id = id, title = title, zone = zone, low = low, high = high,
    sources = sources, steps = steps, extra = extra or {} }
  byId[id] = chapters[#chapters]
end

-- Copies of a chapter's steps for an alternate route, picked by quest ID (travel steps by index).
local function copy(step)
  local result = {}
  for key, value in pairs(step) do result[key] = value end
  return result
end

-- Copies of a main chapter's quest steps for the given quests, in route order.
-- `part` = "accept" keeps only the pickups, "rest" everything after them.
local function from(id, ids, part)
  local wanted, result = {}, {}
  for _, quest in ipairs(ids) do wanted[quest] = true end
  for _, step in ipairs(byId[id].steps) do
    local kind = step.type == "accept" and "accept" or "rest"
    if step.quest and wanted[step.quest] and not step.optional and (not part or part == kind) then
      result[#result + 1] = copy(step)
    end
  end
  return result
end

local function join(...)
  local result = {}
  for _, part in ipairs({ ... }) do
    for _, step in ipairs(part) do result[#result + 1] = step end
  end
  return result
end

local function optional(step)
  step.optional = true
  return step
end

-- A turn-in for a quest the 40-50 route may have given you: shown only while it is in your log.
local carriedSteps = {}
local function carried(step)
  carriedSteps[step] = true
  return optional(step)
end

local function build()
  for _, c in ipairs(chapters) do
    for _, step in ipairs(c.steps) do
      if step.type == "accept" and step.quest then mine[step.quest] = true end
    end
  end
  local done, dropped, taken = {}, {}, {}
  for _, section in ipairs(route.sections) do
    if not section.side and not section.alternate then
      for _, step in ipairs(section.steps) do
        if step.type == "turnin" and step.quest then done[step.quest] = true end
        if step.type == "accept" and step.quest then taken[step.quest] = true end
      end
    end
  end
  for _, c in ipairs(chapters) do
    local alternate = c.extra.alternate
    local finished = alternate and {} or done
    local kept, gone = {}, {}
    for _, step in ipairs(c.steps) do
      local id = step.quest
      local keep = true
      if id and step.type == "accept" then
        for _, pre in ipairs(step.chain or {}) do
          if not finished[pre] and (dropped[pre] or gone[pre] or alternate or not mine[pre]) then keep = false end
        end
        if not keep then gone[id] = true end
      elseif id and (gone[id] or dropped[id]) then
        keep = false
      elseif id and step.type == "turnin" and carriedSteps[step] and not alternate then
        -- A carried hand-in: gone if an earlier chapter already handed it in, a normal step
        -- once an earlier chapter gives you the quest.
        if done[id] then keep = false elseif taken[id] then step.optional = nil end
      end
      if keep then
        if step.also then
          local also = {}
          for _, other in ipairs(step.also) do
            if not gone[other] and not dropped[other] then also[#also + 1] = other end
          end
          step.also = #also > 0 and also or nil
        end
        -- A carried turn-in counts once an earlier main section hands you the quest.
        if id and step.type == "turnin" and (not step.optional or (not alternate and taken[id])) then finished[id] = true end
        if id and step.type == "accept" and not alternate then taken[id] = true end
        kept[#kept + 1] = step
      end
    end
    if not alternate then
      for id in pairs(gone) do dropped[id] = true end
    end
    B.section(c.id, c.title, c.zone, c.low, c.high, c.sources, kept, c.extra)
  end
end

-- 50: Booty Bay errands, Mokk, the Bloodsail captains and Princess Poobah.
do
  local stv = on.stv
  local smotts = stv("Captain Hecklebury Smotts", 26.69, 73.61)
  local fin = stv("Fin Fizracket", 27.61, 76.74)
  local seahorn = stv("Fleet Master Seahorn", 27.17, 77.01)
  local oglethorpe = stv("Oglethorpe Obnoticus", 28.36, 76.35)
  local poobah = stv("Princess Poobah", 38.53, 80.58)
  local gyll = stv("Gyll", 27.5, 77.8)

  q(8551, "The Captain's Chest", 47, 40)
  q(348, "Stranglethorn Fever", 45, 40)
  q(608, "The Bloodsail Buccaneers", 45, 37, 604)
  q(3721, "An OOX of Your Own", 50, 45, { 648, 836, 2767 })
  q(8552, "The Monogrammed Sash", 50, 40)
  quest[8552].startItem = 3985
  q(594, "Message in a Bottle", 45, 45)
  quest[594].startItem = 4098
  q(630, "Message in a Bottle", 51, 45, 594)
  q(8553, "The Captain's Cutlass", 50, 40, 8552)
  q(4449, "Caught!", 45, 43)
  -- Picked up by the 40-50 route; only their turn-ins are here.
  q(2874, "Deliver to MacKinley", 45, 40, 2873)
  q(580, "Whiskey Slim's Lost Grog", 50, 40)
  q(1122, "Report Back to Fizzlebub", 44, 35, 1120)
  q(2767, "Rescue OOX-22/FE!", 45, 40, 2766)
  q(648, "Rescue OOX-17/TN!", 48, 43, 351)
  q(836, "Rescue OOX-09/HL!", 48, 43, 485)
  q(1469, "Rhapsody's Tale", 43, 38, 1452)

  chapter("stv-50", "Booty Bay: Pirates and Princess Poobah", M.stv, 50, 50, {
    "https://www.wowhead.com/forever/zone=33/stranglethorn-vale",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.tanaris("Bera Stonehammer", 51.0, 29.3), RATCHET, "Fly from Gadgetzan to Ratchet."),
    action("boat", at(nil, 63.7, 38.6, M.barrens), "Take the boat at the end of Ratchet's dock to Booty Bay. Use Next when you arrive.",
      { name = "Ratchet - Booty Bay" }),
    accept(8551, smotts, "Captain Hecklebury Smotts waits on the wooden walkway just inside the tunnel into town."),
    accept(348, fin, "Fin Fizracket sits on the ground floor below the inn."),
    carried(finish(2874, stv("\"Sea Wolf\" MacKinley", 27.78, 77.07), "If you carried Stoley's bottle from Tanaris, give it to MacKinley.")),
    carried(finish(580, stv("Whiskey Slim", 27.14, 77.45), "Whiskey Slim sits upstairs in the inn. Hand in his port if you collected it.")),
    carried(finish(1122, stv("Crank Fizzlebub", 27.12, 77.21), "Report to Crank Fizzlebub if you still carry the Fool's Stout report.")),
    accept(608, seahorn, "Fleet Master Seahorn, upstairs in the inn, wants the three Bloodsail captains dead."),
    carried(finish(2767, oglethorpe, "Oglethorpe Obnoticus is in the hut on the pier past the bank. Report any robot rescues you finished.")),
    carried(finish(648, oglethorpe)), carried(finish(836, oglethorpe)),
    accept(3721, oglethorpe, "With all three robots home, Oglethorpe gives you a chicken for your own."), finish(3721, oglethorpe),
    withItem(3985, accept(8552, stv(nil, 23.2, 71.9), "Bloodsail pirates around the bay can drop a Monogrammed Sash. Use it from your bags if you find one.")),
    withItem(4098, accept(594, stv(nil, 32.4, 82.2), "Keep an eye on the beaches for a bottle with a message. Use it from your bags if you find one.")),
    along(objective(608, stv(nil, 32.9, 88.2), "Swim out to the three Bloodsail ships south of Booty Bay. Stillwater is on the nearest, Keelhaul and Firallon on the others. Clear the deck before each captain.",
      "Captain Stillwater", "Captain Keelhaul", "Fleet Master Firallon"), 8552),
    finish(594, poobah, "Princess Poobah is in a cage on Jaguero Isle, east across the water."),
    accept(630, poobah),
    objective(630, stv("King Mukla", 41.0, 83.9), "Kill the gorillas on Jaguero Isle until King Mukla stands alone, then kill him for the key.", "Shackle Key"),
    finish(630, poobah),
    objective(8551, stv("Gorlash", 37.0, 69.7), "Swim back to the mainland and go north to the Crystalvein Mine. The ogre Gorlash guards Smotts' chest.",
      "Smotts' Chest"),
    objective(348, stv("Witch Doctor Unbagwa", 35.3, 60.4), "Collect 10 Gorilla Fangs from the Mistvale gorillas, then ask Witch Doctor Unbagwa to summon Mokk. Three waves come; kill Mokk last for his heart.",
      "Heart of Mokk"),
    finish(8551, smotts), finish(8552, smotts), accept(8553, smotts),
    finish(8553, stv("Sprogger", 26.66, 73.64), "Sprogger stands next to Smotts."),
    finish(348, fin), finish(608, seahorn),
    taxi("fly", gyll, SW_FLIGHT, "Fly to Stormwind."),
    action("buy", at("Auctioneer Jaxon", 61.2, 70.7, M.stormwind),
      "Buy 15 Silk Cloth at the auction house (or bring your own) for the outhouse quest in the Searing Gorge."),
    action("sethearth", at("Innkeeper Allison", 60.4, 75.3, M.stormwind), "Bind at the Gilded Rose in the Trade District.",
      { bind = "Stormwind City" }),
    carried(finish(1469, at("Brohann Caskbelly", 69.45, 40.4, M.stormwind),
      "If you carry Rhapsody's tablet fragment from Stranglethorn, give it to Brohann Caskbelly in the Dwarven District.")),
  })
end

-- 50-51: Thorium Point, the Cauldron and the Torch of Retribution.
do
  local sg = on.searing
  local burninate = sg("Master Smith Burninate", 38.8, 28.51)
  local hansel = sg("Hansel Heavyhands", 38.58, 27.81)
  local scrange = sg("Taskmaster Scrange", 38.97, 27.51)
  local lolo = sg("Lookout Captain Lolo Longstriker", 37.74, 26.56)
  local windblade = sg("Velarok Windblade", 39.06, 38.99)
  local maltrake = sg("Squire Maltrake", 39.17, 39.0)
  local outhouse = sg("Wooden Outhouse", 65.59, 62.17)
  local lanie = sg("Lanie Reed", 37.9, 30.9)

  q(7722, "What the Flux?", 50, 45)
  q(7723, "Curse These Fat Fingers", 49, 45)
  q(7724, "Fiery Menace!", 49, 45)
  q(7727, "Incendosaurs? Whateverosaur is More Like It", 49, 45)
  q(7728, "STOLEN: Smithing Tuyere and Lookout's Spyglass", 48, 45)
  q(7729, "JOB OPPORTUNITY: Culling the Competition", 48, 45)
  q(7701, "WANTED: Overseer Maltorius", 50, 45)
  q(3441, "Divine Retribution", 48, 40)
  q(3442, "The Flawless Flame", 48, 40, 3441)
  q(3443, "Forging the Shaft", 48, 40, 3442)
  q(3452, "The Flame's Casing", 50, 40, 3443)
  q(3453, "The Torch of Retribution", 50, 40, 3452)
  q(3454, "The Torch of Retribution", 50, 40, 3453)
  q(3462, "Squire Maltrake", 50, 40, 3454)
  q(3463, "Set Them Ablaze!", 52, 40, 3462)
  q(3481, "Trinkets...", 50, 40, 3463)
  q(4451, "The Key to Freedom", 47, 43)
  quest[4451].startItem = 11818
  q(3367, "Suntara Stones", 48, 40)
  q(3368, "Suntara Stones", 48, 40, 3367)
  q(3181, "The Horn of the Beast", 48, 40)
  quest[3181].startItem = 10000
  q(3182, "Proof of Deed", 48, 40, 3181)

  chapter("searing-50", "Searing Gorge: Thorium Point", M.searing, 50, 51, {
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("goto", at(nil, 69.0, 31.0, M.stormwind), "Take the Deeprun Tram from the Dwarven District to Ironforge."),
    taxi("fly", at("Gryth Thurden", 55.5, 47.7, M.ironforge), THORIUM,
      "Fly to Thorium Point. If you have never been there, fly to Thelsamar instead and use Next."),
    note(action("goto", sg(nil, 78.6, 16.4), "From western Loch Modan, follow the mountain path into the north-east corner of the Searing Gorge, then head west to Thorium Point."),
      "Overland route taken from a reference guide; check the path in game."),
    taxi("getfp", lanie, THORIUM, "Learn the flight path from Lanie Reed at Thorium Point."),
    accept(7722, burninate), accept(7723, hansel), accept(7724, hansel), accept(7727, hansel),
    accept(7728, sg("Thorium Brotherhood notice", 37.6, 26.5), "Read the board beside the Thorium Point tents for three more jobs."),
    accept(7729, sg("Thorium Brotherhood notice", 37.6, 26.5)), accept(7701, sg("Thorium Brotherhood notice", 37.6, 26.5)),
    accept(3441, windblade, "Walk south down the hill. The Windblade stands alone on the ridge above the Cauldron."),
    objective(3441, windblade, "Listen to his story.", "Divine Retribution"),
    finish(3441, windblade), accept(3442, windblade),
    along(objective(7724, sg(nil, 27.6, 45.5), "Kill Greater Lava Spiders on the western plateau and Heavy War Golems as you cross to the south.",
      "20 Greater Lava Spiders"), 7723, 7728),
    along(objective(3442, sg(nil, 30.1, 76.2), "In the south-west, kill the fire elementals for Hearts of Flame and the golems for Golem Oil.",
      "4 Heart of Flame", "4 Golem Oil"), 7723, 7728),
    finish(3442, windblade), accept(3443, windblade),
    along(objective(7727, sg(nil, 45.4, 21.6), "Enter the Slag Pit on the Cauldron's north rim. Incendosaurs fill its lava pools.", "20 Incendosaurs"), 7701, 7722),
    along(objective(7701, sg("Overseer Maltorius", 40.8, 35.8), "Overseer Maltorius stands in the lowest chamber of the Slag Pit.", "Head of Overseer Maltorius"), 7722),
    objective(7722, sg(nil, 40.4, 35.7), "Pick up the Fiery Flux plans from the table beside Maltorius.", "Secret Plans: Fiery Flux"),
    along(objective(7729, sg(nil, 43.2, 35.1), "Back on the Cauldron floor, kill Taskmasters and Slavers. They drop the Thorium Plated Daggers too.",
      "15 Dark Iron Taskmasters", "15 Dark Iron Slavers"), 3443),
    along(objective(3443, sg(nil, 43.2, 35.1), "Keep fighting the Cauldron's Dark Irons until you have all eight daggers.", "8 Thorium Plated Dagger"), 7729),
    withItem(11818, accept(4451, sg(nil, 43.2, 35.1), "Dark Iron dwarves sometimes drop the Grimesilt Outhouse Key. Use it from your bags if you find it.")),
    finish(3443, windblade), accept(3452, windblade),
    objective(3452, sg(nil, 23.0, 37.8), "Go west to the Twilight camp at Firewatch Ridge. Twilight cultists drop the Symbol of Ragnaros.",
      "Symbol of Ragnaros"),
    finish(3452, windblade), accept(3453, windblade),
    finish(3453, windblade, "Wait for the torch to be finished, then speak to him again."), accept(3454, windblade),
    finish(3454, sg("Torch of Retribution", 39.06, 39.07), "Take the Torch of Retribution from beside him."),
    accept(3462, maltrake), finish(3462, maltrake), accept(3463, maltrake),
    along(objective(7723, sg(nil, 33.2, 43.6), "Finish the Heavy War Golems on the roads around the Cauldron.", "20 Heavy War Golems"), 7728),
    along(objective(3463, sg(nil, 50.1, 54.7), "Use the Torch of Retribution inside each of the four sentry towers around the Cauldron. Kill Steamsmiths and Lookouts on the way for Scrange's tools.",
      "North Sentry Tower", "South Sentry Tower", "East Sentry Tower", "West Sentry Tower"), 7728),
    objective(7728, sg(nil, 50.1, 54.7), "Finish the stolen tools: Dark Iron Steamsmiths carry the tuyere and Lookouts the spyglass.",
      "Smithing Tuyere", "Lookout's Spyglass"),
    finish(4451, outhouse, "Open the outhouse at Grimesilt Dig Site in the south-east."),
    accept(4449, outhouse),
    objective(4449, sg(nil, 63.1, 60.9), "Kill Dark Iron Geologists around the dig site and hand in the silk cloth you bought.",
      "8 Dark Iron Geologists", "15 Silk Cloth"),
    finish(4449, outhouse),
    accept(3367, sg("Dorius Stonetender", 63.9, 61.0), "Dorius waits near the dig site and asks for an escort."),
    objective(3367, sg(nil, 74.4, 19.3), "Walk Dorius north-east toward the Loch Modan path. Stay close and kill the Dark Irons who ambush him.",
      "Escort Dorius"),
    finish(3367, sg("Singed Letter", 74.45, 19.29), "Read the letter left where Dorius fell."),
    accept(3368, sg("Singed Letter", 74.45, 19.29)),
    withItem(10000, accept(3181, nil, "If you killed Margol the Rager for his horn, use it from your bags.")),
    taxi("fly", lanie, THELSAMAR, "Fly to Thelsamar for Pebblebitty, or use Next if you have no horn."),
    finish(3181, at("Mountaineer Pebblebitty", 18.18, 84.01, M.lochModan), "Pebblebitty guards the Badlands gate at the south end of Loch Modan."),
    accept(3182, at("Mountaineer Pebblebitty", 18.18, 84.01, M.lochModan)),
    taxi("fly", at("Thorgrum Borrelson", 33.9, 51.0, M.lochModan), THORIUM, "Fly back to Thorium Point."),
    finish(7701, lolo), finish(7723, hansel), finish(7724, hansel), finish(7727, hansel),
    finish(7722, burninate), finish(7729, scrange), finish(7728, scrange),
    finish(3463, maltrake, "Walk back down to Squire Maltrake."),
    accept(3481, sg("Hoard of the Black Dragonflight", 38.85, 38.99)),
    finish(3481, sg("Hoard of the Black Dragonflight", 38.85, 38.99), "Open the chest beside the squire for your reward."),
    action("hearth", at("Innkeeper Allison", 60.4, 75.3, M.stormwind), "Hearth to Stormwind.", { bind = "Stormwind City" }),
  })
end

-- 51: Nethergarde's bloodmages and the Firegut ogres of the Burning Steppes.
do
  local bl = on.blasted
  local lynnore = bl("Bloodmage Lynnore", 50.64, 14.3)
  local drazial = bl("Bloodmage Drazial", 50.55, 14.2)
  local hero = on.swamp("Fallen Hero of the Horde", 34.29, 66.14)
  local oralius = on.steppes("Oralius", 84.6, 68.7)

  q(2783, "Petty Squabbles", 57, 50)
  q(2801, "A Tale of Sorrow", 57, 45, 2783)
  q(2601, "The Basilisk's Bite", 50, 45)
  q(2603, "Vulture's Vigor", 50, 45)
  q(2585, "The Decisive Striker", 50, 45)
  q(2583, "A Boar's Vitality", 50, 45)
  q(2581, "Snickerfang Jowls", 50, 45)
  q(3501, "Everything Counts In Large Amounts", 55, 45)
  q(2521, "To Serve Kum'isha", 55, 45)
  q(3823, "Extinguish the Firegut", 52, 48)

  chapter("blasted-51", "Blasted Lands: The Bloodmages", M.blasted, 51, 51, {
    "https://www.wowhead.com/forever/zone=4/blasted-lands",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", at("Dungar Longdrink", 71.3, 72.2, M.stormwind), NETHERGARDE, "Fly to Nethergarde Keep."),
    accept(2783, bl("Ambassador Ardalan", 67.57, 19.29), "Ambassador Ardalan stands in the Nethergarde courtyard."),
    finish(2783, hero, "Ride north out of the keep to the border with the Swamp of Sorrows. The Fallen Hero kneels by the road."),
    accept(2801, hero), objective(2801, hero, "Listen to the whole story.", "A Tale of Sorrow"), finish(2801, hero),
    accept(2601, lynnore, "The two bloodmages camp on the ridge west of Nethergarde. Take all their requests: each one needs a mix of parts."),
    accept(2603, lynnore), accept(2585, drazial), accept(2583, drazial), accept(2581, drazial),
    action("note", bl(nil, 62.5, 28.0), "Hunt basilisks, vultures, scorpoks, boars and Snickerfang hyenas through the valleys south of the keep. Hand in to the bloodmages whenever a recipe is ready.",
      { name = "Blasted Lands hunt" }),
    finish(2601, lynnore), finish(2603, lynnore), finish(2585, drazial), finish(2583, drazial), finish(2581, drazial),
    optional(accept(3501, bl("Kum'isha the Collector", 51.98, 35.65), "Kum'isha, near the Dark Portal, pays for Draenethyst fragments. Buy one at the auction house beforehand if you want her reward.")),
    optional(finish(3501, bl("Kum'isha the Collector", 51.98, 35.65))),
    optional(accept(2521, bl("Kum'isha the Collector", 51.98, 35.65))),
    optional(finish(2521, bl("Kum'isha the Collector", 51.98, 35.65), "A Flawless Draenethyst Sphere is rare. Hand it in only if you found or bought one.")),
    taxi("fly", bl("Alexandra Constantine", 65.5, 24.3), LAKESHIRE, "Fly to Lakeshire."),
    action("goto", on.steppes(nil, 77.5, 68.0), "Take the north road out of Redridge into the Burning Steppes."),
    accept(3823, oralius, "Oralius camps at Morgan's Vigil, on the cliff just inside the Steppes."),
    taxi("getfp", on.steppes("Borgus Stoutarm", 84.3, 68.3), MORGANS, "Learn the Morgan's Vigil flight path."),
    objective(3823, on.steppes(nil, 80.7, 44.4), "Climb north to Dreadmaul Rock and clear the Firegut ogres around its base.",
      "15 Firegut Ogre Mages", "15 Firegut Ogres", "15 Firegut Brutes"),
    finish(3823, oralius),
    taxi("fly", on.steppes("Borgus Stoutarm", 84.3, 68.3), IF_FLIGHT, "Fly to Ironforge."),
  })
end

-- 51-52: Ironforge errands, the Hinterlands hand-ins and Chillwind Camp.
do
  local wpl = on.wpl
  local ironforge = function(name, x, y) return at(name, x, y, M.ironforge) end
  local thorius = ironforge("Curator Thorius", 71.5, 15.7)
  local tymor = ironforge("Tymor", 31.0, 4.8)
  local xiggs = ironforge("Xiggs Fuselighter", 70.87, 94.56)
  local mistina = ironforge("Mistina Steelshield", 43.2, 31.6)
  local ashlam = wpl("Commander Ashlam Valorfist", 42.7, 84.03)
  local macdonnell = wpl("High Priestess MacDonnell", 42.97, 84.5)
  local pureheart = wpl("Argent Officer Pureheart", 42.97, 83.55)
  local cauldron = wpl("Scourge Cauldron", 37.25, 56.78)
  local parcel = wpl("Janice's Parcel", 38.73, 55.24)

  q(5090, "A Call to Arms: The Plaguelands!", 50, 50)
  q(3201, "At Last!", 48, 40, 3182)
  q(3448, "Passing the Burden", 52, 45)
  q(3449, "Arcane Runes", 52, 45, 3448)
  q(3450, "An Easy Pickup", 52, 45, 3448)
  q(3451, "Signal for Pickup", 52, 45, 3450)
  q(7802, "A Donation of Wool", 60, 12)
  q(7803, "A Donation of Silk", 60, 26)
  q(7804, "A Donation of Mageweave", 60, 40)
  q(2989, "The Altar of Zul", 48, 40, 2988)
  q(2877, "Skulk Rock Clean-up", 48, 40)
  q(2641, "Sprinkle's Secret Ingredient", 49, 44, 2606)
  q(5092, "Clear the Way", 52, 50, 5090)
  q(5401, "Argent Dawn Commission", 55, 50)
  q(5215, "The Scourge Cauldrons", 53, 50, 5092)
  q(5216, "Target: Felstone Field", 53, 50, 5215)
  q(5217, "Return to Chillwind Camp", 53, 50, 5216)
  q(5021, "Better Late Than Never", 52, 50)

  chapter("wpl-51", "Western Plaguelands: Chillwind Camp", M.wpl, 51, 52, {
    "https://www.wowhead.com/forever/zone=28/western-plaguelands",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    accept(5090, ironforge("Courier Hammerfall", 55.9, 81.4), "Courier Hammerfall rides a circuit through Ironforge. Stop him when he passes to take his call to arms."),
    finish(3182, thorius, "Curator Thorius stands in the Hall of Explorers."), accept(3201, thorius),
    finish(3368, thorius),
    accept(3448, ironforge("Historian Karnik", 77.5, 11.8)),
    finish(3448, tymor, "Tymor is in the Mystic Ward."), accept(3449, tymor), accept(3450, tymor),
    action("sethearth", ironforge("Innkeeper Firebrew", 18.1, 51.5), "Bind at the Stonefire Tavern in the Commons.", { bind = "Ironforge" }),
    optional(accept(7802, mistina, "If you carry spare cloth, Mistina Steelshield in the Great Forge takes donations for reputation and experience.")),
    optional(finish(7802, mistina)), optional(accept(7803, mistina)), optional(finish(7803, mistina)),
    optional(accept(7804, mistina)), optional(finish(7804, mistina)),
    finish(3450, xiggs, "Xiggs Fuselighter waits in Tinker Town."), accept(3451, xiggs),
    finish(3451, xiggs, "Ask Xiggs for the flare gun you will use in Azshara."),
    taxi("fly", ironforge("Gryth Thurden", 55.5, 47.7), THELSAMAR, "Fly to Thelsamar for Pebblebitty."),
    finish(3201, at("Mountaineer Pebblebitty", 18.18, 84.01, M.lochModan), "Bring the Proof of Deed to Pebblebitty at the Badlands gate."),
    taxi("fly", at("Thorgrum Borrelson", 33.9, 51.0, M.lochModan), AERIE, "Fly to Aerie Peak in the Hinterlands."),
    carried(finish(2989, on.hinterlands("Gryphon Master Talonaxe", 9.75, 44.47), "Hand in the Altar of Zul report if you still carry it.")),
    carried(finish(2877, on.hinterlands("Fraggar Thundermantle", 14.83, 44.57), "Report the Skulk Rock oozes if you finished them.")),
    optional(objective(2641, on.hinterlands(nil, 40.6, 59.6), "If you carry Sprinkle's request, pick a Violet Tragan from the hills east of Aerie Peak.", "Violet Tragan")),
    note(taxi("fly", on.hinterlands("Guthrum Thunderfist", 11.1, 46.1), CHILLWIND,
      "Fly to Chillwind Camp. If you have never been there, ride west through Hillsbrad and north through the Alterac foothills."),
      "Check whether Chillwind Camp must be discovered on foot first."),
    taxi("getfp", wpl("Bibilfaz Featherwhistle", 42.9, 85.1), CHILLWIND, "Learn the Chillwind Camp flight path."),
    finish(5090, ashlam, "Commander Ashlam Valorfist stands in the middle of Chillwind Camp."), accept(5092, ashlam),
    accept(5401, pureheart, "Argent Officer Pureheart hands out the Argent Dawn Commission. Equip the trinket for Scourgestones."),
    finish(5401, pureheart),
    objective(5092, wpl(nil, 50.0, 76.9), "Ride north-east to Sorrow Hill and kill Skeletal Flayers and Slavering Ghouls among the graves.",
      "10 Skeletal Flayers", "10 Slavering Ghouls"),
    finish(5092, ashlam), accept(5215, ashlam),
    finish(5215, macdonnell), accept(5216, macdonnell),
    objective(5216, cauldron, "Go north to Felstone Field. Kill Cauldron Lord Bilemaw beside the cauldron for its key.", "Felstone Field Cauldron Key"),
    finish(5216, cauldron, "Use the key on the cauldron."), accept(5217, cauldron),
    accept(5021, wpl("Janice Felstone", 38.4, 54.0), "Janice Felstone's ghost lingers in the farmhouse next to the field."),
    finish(5021, parcel, "Her parcel sits in the barn beside her horse."),
    finish(5217, macdonnell, "Take the filled bottle back to MacDonnell at Chillwind Camp."),
  })
end

-- 52: Darnassus hand-ins, Loh'atu in Azshara, Felwood and the first Winterspring stop.
do
  local fw = on.felwood
  local tel = function(name, x, y) return at(name, x, y, M.teldrassil) end
  local dar = function(name, x, y) return at(name, x, y, M.darnassus) end
  local erelas = tel("Erelas Ambersky", 55.5, 92.05)
  local lohatu = on.azshara("Loh'atu", 11.37, 78.17)
  local arathandris = fw("Arathandris Silversky", 54.15, 86.83)
  local grazle = fw("Grazle", 50.93, 85.01)
  local greta = fw("Greta Mosshoof", 51.21, 82.11)
  local taronn = fw("Taronn Redfeather", 50.89, 81.62)
  local eridan = fw("Eridan Bluewind", 51.35, 81.51)
  local auberdine = { bind = "Auberdine" }
  local shaussiy = at("Innkeeper Shaussiy", 37.0, 44.1, M.darkshore)
  local caylais = at("Caylais Moonfeather", 36.3, 45.6, M.darkshore)

  q(978, "Moontouched Wildkin", 55, 52, 3661)
  q(3661, "Favored of Elune?", 47, 42)
  q(2944, "The Super Snapper FX", 48, 42, 2941)
  q(2943, "Return to Troyas", 48, 42, 2944)
  q(162, "Rise of the Silithid", 49, 39, 113)
  q(4267, "Rise of the Silithid", 46, 40, 4266)
  q(4493, "March of the Silithid", 53, 50)
  q(2972, "Doling Justice", 47, 38, 2970)
  q(5535, "Spiritual Unrest", 47, 45)
  q(5536, "A Land Filled with Hatred", 47, 45)
  q(4101, "Cleansing Felwood", 55, 48)
  q(8460, "Timbermaw Ally", 48, 45)
  q(8462, "Speak to Nafien", 55, 45, 8460)
  q(5155, "Forces of Jaedenar", 51, 48)
  q(5156, "Verifying the Corruption", 54, 48)
  q(4421, "The Corruption of the Jadefire", 54, 49)
  q(5157, "Collection of the Corrupt Water", 52, 48, 5155)
  q(4906, "Further Corruption", 54, 49, 4421)
  q(939, "Flute of Xavaric", 54, 49)
  quest[939].startItem = 11668
  q(3908, "It's a Secret to Everybody", 52, 47, 3845)
  q(3909, "The Videre Elixir", 52, 47, 3908)
  q(6603, "Trouble in Winterspring!", 56, 52)
  q(5158, "Seeking Spiritual Aid", 52, 48, 5157)
  q(4441, "Felbound Ancients", 54, 49, 939)
  q(7065, "Corruption of Earth and Seed", 51, 45)
  q(7041, "Vyletongue Corruption", 47, 41)
  q(7028, "Twisted Evils", 47, 41)

  chapter("felwood-52", "Felwood: Emerald Sanctuary and Jaedenar", M.felwood, 52, 52, {
    "https://www.wowhead.com/forever/zone=361/felwood",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.wpl("Bibilfaz Featherwhistle", 42.9, 85.1), "Menethil Harbor, Wetlands", "Fly to Menethil Harbor."),
    action("boat", at(nil, 4.6, 57.3, M.wetlands), "Take the Auberdine ship from Menethil's north pier. Use Next in Auberdine.",
      { name = "Menethil Harbor - Auberdine" }),
    action("sethearth", shaussiy, "Bind at the Auberdine inn. You come back here after Felwood.", auberdine),
    taxi("fly", caylais, RUTTHERAN, "Fly to Rut'theran Village."),
    carried(finish(3661, erelas, "Erelas Ambersky waits by the moonwell. Hand in the Hinterlands wildkin feathers if you have them.")),
    accept(978, erelas, "Erelas wants feathers from the moontouched owlbeasts of Winterspring."),
    carried(finish(2944, tel("Daryn Lightwind", 55.41, 92.23), "Give Daryn Lightwind the Gammerita snapshot if you took one.")),
    accept(2943, tel("Daryn Lightwind", 55.41, 92.23), "Take his book back to Troyas in Feathermoon on your Feralas visit."),
    action("goto", tel(nil, 55.9, 89.5), "Step into the pink portal to Darnassus."),
    carried(finish(162, dar("Gracina Spiritmight", 41.83, 85.62), "Gracina Spiritmight, in the Temple of the Moon, takes the silithid reports.")),
    carried(finish(4267, dar("Gracina Spiritmight", 41.83, 85.62))),
    accept(4493, dar("Gracina Spiritmight", 41.83, 85.62), "Gracina sends you on to the alchemist in Gadgetzan. Keep it for your Tanaris trip."),
    carried(finish(2972, dar("Tyrande Whisperwind", 39.1, 81.59), "Give Jer'kai's ring to Tyrande on the temple's upper floor.")),
    action("goto", dar(nil, 29.5, 41.4), "Take the portal back down to Rut'theran Village."),
    taxi("fly", tel("Vesprystus", 58.4, 94.0), TALRENDIS,
      "Fly to Talrendis Point. If you have not learned it, fly to Astranaar and follow the east road into Azshara."),
    accept(5535, lohatu, "Loh'atu, a centaur spirit, stands just past the Ashenvale border."), accept(5536, lohatu),
    along(objective(5536, on.azshara(nil, 20.6, 60.9), "Clear the Haldarr satyrs in the ruins south-east of Loh'atu.",
      "6 Haldarr Satyrs", "2 Haldarr Tricksters", "2 Haldarr Felsworns"), 5535),
    along(objective(5535, on.azshara(nil, 17.1, 69.0), "Kill the Highborne ghosts at the Shadowsong Shrine ruins on your way back.",
      "6 Highborne Apparitions", "6 Highborne Lichlings"), 5536),
    finish(5535, lohatu), finish(5536, lohatu),
    action("goto", fw(nil, 54.1, 86.8), "Ride west into Ashenvale and take the north road into Felwood. The Emerald Sanctuary is just off the road."),
    accept(4101, arathandris), accept(8460, grazle, "Grazle, a Timbermaw furbolg, stands beside the sanctuary."),
    objective(8460, fw(nil, 48.2, 93.8), "Kill Deadwood furbolgs in the camps south-west of the sanctuary.",
      "6 Deadwood Warriors", "6 Deadwood Pathfinders", "6 Deadwood Gardeners"),
    finish(8460, grazle), accept(8462, grazle),
    accept(5155, greta), accept(5156, taronn), accept(4421, eridan),
    objective(4421, fw(nil, 32.2, 67.1), "Go west to the Jadefire satyr camps at Shadow Hold. Xavathras commands the camp.",
      "11 Jadefire Felsworns", "9 Jadefire Shadowstalkers", "9 Jadefire Rogues", "Xavathras"),
    objective(5155, fw(nil, 36.5, 61.4), "Fight into Jaedenar for hounds, guardsmen, adepts and cultists.",
      "4 Jaedenar Hounds", "4 Jaedenar Guardsmen", "6 Jaedenar Adepts", "6 Jaedenar Cultists"),
    finish(5155, greta), accept(5157, greta),
    finish(4421, eridan), accept(4906, eridan),
    withItem(12922, objective(5157, fw(nil, 35.2, 59.8), "Fill the Empty Canteen at the moonwell in the middle of Jaedenar.", "Corrupt Moonwell Water")),
    objective(5156, fw(nil, 41.5, 43.0), "Go north to Shatter Scar Vale for Entropic Beasts and Horrors, and look at the fel craters.",
      "2 Entropic Beasts", "2 Entropic Horrors"),
    withItem(11668, accept(939, fw(nil, 39.0, 22.3), "Xavaric drops his flute. Use it from your bags.")),
    along(objective(4906, fw("Xavaric", 39.1, 22.4), "Clear Jadefire Run in the north-west and kill Xavaric at its top.",
      "8 Jadefire Hellcallers", "8 Jadefire Betrayers", "8 Jadefire Tricksters", "Xavaric"), 939),
    along(objective(939, fw(nil, 39.0, 22.3), "Jadefire satyrs also drop Felbind samples.", "5 Jadefire Felbind"), 4906),
    objective(4101, fw(nil, 57.3, 17.8), "East of the road, kill Warpwood treants at Irontree Woods for Blood Amber.", "15 Blood Amber"),
    taxi("getfp", fw("Mishellena", 62.5, 24.2), TALONBRANCH, "Learn the Talonbranch Glade flight path."),
    finish(8462, fw("Nafien", 64.77, 8.13), "Follow the road north to Nafien at the Timbermaw Hold tunnel."),
    action("goto", on.winterspring(nil, 27.8, 34.6), "Walk through Timbermaw Hold. The furbolgs let you pass now. Exit into Winterspring."),
    carried(finish(3908, on.winterspring("Donova Snowden", 31.27, 45.16), "Donova Snowden camps by the hot springs. Give her Linken's sword if you carry it.")),
    accept(3909, on.winterspring("Donova Snowden", 31.27, 45.16), "Donova asks about the Videre Elixir. Gregan in Feralas can help."),
    objective(978, on.winterspring(nil, 60.6, 33.7), "Moontouched Owlbeasts roam north of Everlook. Each one can drop a feather.", "10 Moontouched Feather"),
    taxi("getfp", on.winterspring("Maethrya", 62.3, 36.6), EVERLOOK, "Learn the Everlook flight path."),
    accept(6603, on.winterspring("Meggi Peppinrocker", 60.66, 38.17), "Meggi Peppinrocker in Everlook sends you to Donova. You will see her on your next Winterspring visit."),
    taxi("fly", on.winterspring("Maethrya", 62.3, 36.6), TALONBRANCH, "Fly back to Talonbranch Glade, then ride south to the sanctuary."),
    finish(4101, arathandris), finish(5157, greta), accept(5158, greta, "Greta wants the water taken to Islen Waterseer in the Barrens."),
    finish(4906, eridan), finish(939, eridan), accept(4441, eridan, "Take Eridan's vial to the Temple of the Moon on a later Darnassus visit."),
    finish(5156, taronn),
    action("hearth", shaussiy, "Hearth to Auberdine.", auberdine),
    taxi("fly", caylais, RUTTHERAN, "Fly to Rut'theran Village."),
    finish(978, erelas),
    taxi("fly", tel("Vesprystus", 58.4, 94.0), NIJEL, "Fly to Nijel's Point in Desolace."),
    forDungeon(accept(7065, on.desolace("Keeper Marandis", 63.83, 10.67), "Keeper Marandis wants Princess Theradras dead, at the bottom of Maraudon."), "dungeon-maraudon"),
    action("sethearth", on.desolace("Innkeeper Lyshaerya", 66.3, 6.5), "Bind at Nijel's Point.", { bind = "Nijel's Point" }),
    forDungeon(accept(7041, on.desolace("Talendria", 68.5, 8.88), "Talendria's Maraudon task is also a dungeon quest."), "dungeon-maraudon"),
    forDungeon(accept(7028, on.desolace("Willow", 62.2, 39.63), "Willow camps in the middle of Desolace. Her crystal carvings drop inside Maraudon."), "dungeon-maraudon"),
    taxi("fly", on.desolace("Baritanas Skyriver", 64.7, 10.5), FEATHERMOON, "Fly to Feathermoon Stronghold."),
  })
end

-- 52-53: Feathermoon, the Forgotten Coast, Shay and the Maraudon pickups in Desolace.
do
  local fe = on.feralas
  local troyas = fe("Troyas Moonbreeze", 31.78, 45.5)
  local pratt = fe("Pratt McGrubben", 30.63, 42.71)
  local zorbin = fe("Zorbin Fandazzle", 44.81, 43.42)
  local gregan = fe("Gregan Brewspewer", 45.12, 25.57)
  local rockbiter = fe("Rockbiter", 42.39, 22.0)
  local shay = fe("Shay Leafrunner", 38.22, 10.3)
  local monolith = fe("Equinex Monolith", 38.83, 13.17)
  local nijel = { bind = "Nijel's Point" }

  q(7733, "Improved Quality", 48, 40, 2821)
  q(2879, "The Stave of Equinex", 50, 42, 2943)
  q(7003, "Zapped Giants", 48, 45)
  q(7721, "Fuel for the Zapping", 48, 45)
  q(4142, "A Visit to Gregan", 52, 47, 4141)
  q(2844, "The Giant Guardian", 49, 44)
  q(2845, "Wandering Shay", 49, 44, 2844)
  q(2942, "The Morrow Stone", 50, 42, 2879)
  q(7067, "The Pariah's Instructions", 48, 39)

  chapter("feralas-52", "Feralas: Feathermoon and the Forgotten Coast", M.feralas, 52, 53, {
    "https://www.wowhead.com/forever/zone=357/feralas",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    accept(7733, pratt, "Pratt McGrubben, by the Feathermoon inn, has a better job now that you brought his first hides."),
    finish(2943, troyas, "Troyas Moonbreeze is in the building on the north side of the stronghold."), accept(2879, troyas),
    action("boat", fe(nil, 31.0, 39.8), "Take the ferry from Feathermoon's east dock to the mainland. Use Next when you land.",
      { name = "Feathermoon - Feralas" }),
    accept(7003, zorbin, "Zorbin Fandazzle stands on the dock where the ferry lands."), accept(7721, zorbin),
    along(withItem(18904, objective(7003, fe(nil, 46.0, 53.0), "Use Zorbin's Ultra-Shrinker on the giants wading south along the coast, then kill and loot them.",
      "15 Miniaturization Residue")), 7721),
    along(objective(7721, fe(nil, 46.0, 53.0), "Sea Elementals and Sea Sprays share the same beaches.", "10 Water Elemental Core"), 7003),
    finish(7003, zorbin), finish(7721, zorbin),
    objective(7733, fe(nil, 54.8, 32.8), "Ride north-east to the Rage Scar yeti caves and loot their hides.", "10 Rage Scar Yeti Hide"),
    carried(finish(4142, gregan, "Gregan Brewspewer camps north of the yetis. Hand him the Bloodpetal if you carry it.")),
    objective(3909, gregan, "Ask Gregan about the Videre Elixir. Buy the bait he asks for if he offers it.", "Videre Elixir"),
    accept(2844, rockbiter, "Rockbiter, a gentle giant, sits at the edge of the Ruins of Ravenwind."),
    finish(2844, shay, "Shay Leafrunner wanders far to the north-west, near the Equinex Monolith."), accept(2845, shay),
    objective(2879, monolith, "Energize Troyas' stave at the nearby monolith.", "Stave of Equinex"),
    finish(2879, monolith), accept(2942, monolith),
    objective(2845, rockbiter, "Ring Shay's Bell whenever she wanders off, and walk her back to Rockbiter.", "Shay's Bell"),
    finish(2845, rockbiter),
    action("goto", on.desolace(nil, 50.4, 86.7), "Follow the road north out of Feralas into southern Desolace."),
    forDungeon(accept(7067, on.desolace("Centaur Pariah", 50.42, 86.65), "The Centaur Pariah wanders south of the Kolkar camps. His amulet quest is done inside Maraudon."),
      "dungeon-maraudon"),
    withGuide("dungeon-maraudon", action("note", on.desolace(nil, 29.1, 62.6),
      "Maraudon is open for a group around this level. Plan it from the Quests tab, or skip it and continue.", { name = "Maraudon" })),
    forDungeon(finish(7067, on.desolace("Centaur Pariah", 50.42, 86.65), "After the run, bring the Amulet of Union back to the Pariah."), "dungeon-maraudon"),
    forDungeon(finish(7028, on.desolace("Willow", 62.2, 39.63), "Give Willow the crystal carvings on your way north."), "dungeon-maraudon"),
    action("hearth", on.desolace("Innkeeper Lyshaerya", 66.3, 6.5), "Hearth to Nijel's Point, or ride north from Willow's camp.", nijel),
    forDungeon(finish(7065, on.desolace("Keeper Marandis", 63.83, 10.67), "Hand in Theradras if your group killed her."), "dungeon-maraudon"),
    forDungeon(finish(7041, on.desolace("Talendria", 68.5, 8.88)), "dungeon-maraudon"),
    taxi("fly", on.desolace("Baritanas Skyriver", 64.7, 10.5), FEATHERMOON, "Fly to Feathermoon Stronghold."),
    finish(2942, troyas), finish(7733, pratt),
  })
end

-- 53: Ratchet, Kim'jael in Azshara and the rune rubbings.
do
  local az = on.azshara
  local kimjael = az("Kim'jael", 53.45, 21.82)
  local wiley = at("Innkeeper Wiley", 62.0, 39.4, M.barrens)
  local ratchet = { bind = "Ratchet" }

  q(3601, "Kim'jael Indeed!", 53, 47)
  q(5534, "Kim'jael's \"Missing\" Equipment", 53, 47, 3601)
  q(5159, "Cleansed Water Returns to Felwood", 54, 48, 5158)
  q(4502, "Volcanic Activity", 55, 49)
  q(3444, "The Stone Circle", 51, 46, 3445)

  chapter("azshara-53", "Azshara: Kim'jael and the Runes", M.azshara, 53, 53, {
    "https://www.wowhead.com/forever/zone=16/azshara",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.feralas("Fyldren Moonfeather", 30.2, 43.2), RATCHET, "Fly to Ratchet."),
    action("sethearth", wiley, "Bind at the Ratchet inn.", ratchet),
    taxi("fly", at("Bragok", 63.1, 37.2, M.barrens), TALRENDIS, "Fly to Talrendis Point."),
    accept(3601, kimjael, "Kim'jael, a goblin, stands on the cliff above the Thalassian camp in northern Azshara."),
    objective(3601, az(nil, 56.6, 28.4), "Search the Thalassian Base Camp below him for his four lost items. The naga guards hit hard in pairs.",
      "Kim'Jael's Compass", "Kim'Jael's Scope", "Kim'Jael's Stuffed Chicken", "Kim'Jael's Wizzlegoober"),
    finish(3601, kimjael), accept(5534, kimjael),
    withItem(10445, objective(3449, az(nil, 42.3, 64.1), "Ride south to the Ruins of Eldarath. Use Tymor's Drawing Kit at each of the four rune stones.",
      "Rubbing: Rune of Beth'Amara", "Rubbing: Rune of Jin'yael", "Rubbing: Rune of Markri", "Rubbing: Rune of Sael'hai")),
    objective(5534, az(nil, 46.0, 52.8), "Spitelash Myrmidons and Sirens in the same ruins carry Some Rune.", "Some Rune"),
    finish(5534, kimjael),
    action("grind", az(nil, 56.6, 28.4), "Kill naga and satyrs on the way back if you are short of level 54.", { level = 54 }),
    finish(3449, az("Pilot Xiggs Fuselighter", 77.8, 91.3), "Go to the small island off the south-east peninsula and fire the flare gun. Xiggs lands to pick you up."),
    action("hearth", wiley, "Hearth to Ratchet.", ratchet),
    finish(5158, at("Islen Waterseer", 65.83, 43.78, M.barrens), "Islen Waterseer stands outside Ratchet to the south-east."),
    accept(5159, at("Islen Waterseer", 65.83, 43.78, M.barrens), "Take the purified water back to Greta in Felwood."),
    accept(4502, at("Liv Rizzlefix", 62.45, 38.73, M.barrens), "Liv Rizzlefix in Ratchet wants ash from Un'Goro's fire elementals."),
    carried(finish(3444, at("Marvon Rivetseeker", 52.71, 45.92, M.tanaris), "Hand in the Stone Circle on your way through Tanaris if you carry it.")),
  })
end

-- 53-54: Gadgetzan, Marshal's Refuge and the whole crater, then Darnassus.
do
  local ug = on.ungoro
  local tan = on.tanaris
  local williden = ug("Williden Marshal", 43.95, 7.14)
  local holanyee = ug("Hol'anyee Marshal", 43.89, 7.24)
  local collie = ug("J.D. Collie", 41.92, 2.7)
  local spark = ug("Spark Nilminer", 43.5, 7.42)
  local spraggle = ug("Spraggle Frock", 43.62, 8.5)
  local shizzle = ug("Shizzle", 44.23, 11.59)
  local torwa = ug("Torwa Pathfinder", 71.64, 75.96)
  local krakle = ug("Krakle", 30.93, 50.44)
  local pestlezugg = tan("Alchemist Pestlezugg", 50.89, 26.96)
  local dar = function(name, x, y) return at(name, x, y, M.darnassus) end
  local fandral = dar("Arch Druid Fandral Staghelm", 34.81, 9.26)
  local mathrengyl = dar("Mathrengyl Bearwalker", 35.37, 8.4)
  local erelas = at("Erelas Ambersky", 55.5, 92.05, M.teldrassil)

  q(2661, "Delivery for Marin", 49, 44, 2641)
  q(2662, "Noggenfogger Elixir", 49, 44, 2661)
  q(4496, "Bungle in the Jungle", 53, 50)
  q(3881, "Expedition Salvation", 53, 48)
  q(3882, "Roll the Bones", 51, 49)
  q(4501, "Beware of Pterrordax", 55, 49)
  q(4503, "Shizzle's Flyer", 51, 49)
  q(4289, "The Apes of Un'Goro", 55, 47)
  q(4291, "The Scent of Lar'korwi", 53, 48, 4290)
  q(4301, "The Mighty U'cha", 55, 50, 4289)
  q(4292, "The Bait for Lar'korwi", 56, 48, 4291)
  q(974, "Finding the Source", 55, 51)
  q(980, "The New Springs", 55, 51, 974)
  q(3884, "Williden's Journal", 50, 48)
  quest[3884].startItem = 11116
  q(3763, "Assisting Arch Druid Staghelm", 50, 47)
  q(3764, "Un'Goro Soil", 50, 47)
  q(3781, "Morrowgrain Research", 50, 47, 3764)
  q(1047, "The New Frontier", 55, 54)
  q(6761, "The New Frontier", 55, 54, 1047)
  q(6762, "Rabine Saturna", 55, 54, 6761)
  q(979, "Find Ranshalla", 57, 52, 978)
  q(5250, "Starfall", 56, 53)

  chapter("ungoro-53", "Un'Goro Crater: Marshal's Refuge", M.ungoro, 53, 54, {
    "https://www.wowhead.com/forever/zone=490/ungoro-crater",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", at("Bragok", 63.1, 37.2, M.barrens), GADGETZAN, "Fly to Gadgetzan."),
    carried(finish(2641, tan("Sprinkle", 51.06, 26.87), "Give Sprinkle the Violet Tragan if you picked one in the Hinterlands.")),
    accept(2661, tan("Sprinkle", 51.06, 26.87)),
    finish(4493, pestlezugg, "Alchemist Pestlezugg works on the north side of Gadgetzan."), accept(4496, pestlezugg),
    finish(2661, tan("Marin Noggenfogger", 51.81, 28.66)), accept(2662, tan("Marin Noggenfogger", 51.81, 28.66)),
    finish(2662, tan("Marin Noggenfogger", 51.81, 28.66), "Wait for Marin to brew the elixir, then speak to him again."),
    taxi("fly", tan("Bera Stonehammer", 51.0, 29.3), MARSHAL,
      "Fly to Marshal's Refuge. Without that flight path, ride west from Gadgetzan and down the ramp into Un'Goro."),
    taxi("getfp", ug("Gryfe", 45.2, 5.8), MARSHAL, "Learn the Marshal's Refuge flight path."),
    accept(3881, williden),
    accept(3882, spark), accept(4501, spraggle), accept(4503, shizzle),
    action("note", ug(nil, 50, 30), "Diemetradons drop bones and scales, pterrordaxes drop scales. Kill them whenever they are on your way.",
      { name = "Un'Goro dinosaurs" }),
    carried(objective(4289, ug(nil, 65.5, 16.5), "If Torwa gave you the ape pelts quest, kill the gorillas in the north-east for their pelts.",
      "2 Un'Goro Gorilla Pelt", "2 Un'Goro Stomper Pelt", "2 Un'Goro Thunderer Pelt")),
    along(objective(3881, ug(nil, 68.5, 36.5), "Search the camp of crates east of the refuge for the Crate of Foodstuffs.", "Crate of Foodstuffs"), 3882),
    carried(objective(4292, ug("Lar'korwi", 79.9, 49.9), "If you have Torwa's pouch, open it near the nest to call Lar'korwi.", "Lar'korwi's Head")),
    carried(finish(4289, torwa, "Torwa Pathfinder stands at the crater's south-east entrance.")), accept(4301, torwa),
    carried(finish(4292, torwa)),
    along(objective(4501, ug(nil, 44.3, 90.4), "Kill Pterrordaxes on the southern plains.", "10 Pterrordax", "15 Frenzied Pterrordax"), 4503, 3882),
    objective(4496, ug(nil, 48.8, 85.3), "Gorishi silithids drop the scent gland. Loot Un'Goro Soil from the dirt mounds nearby.",
      "Gorishi Scent Gland", "5 Un'Goro Soil"),
    objective(3881, ug(nil, 38.5, 66.1), "The Research Equipment crate lies in the south-west.", "Research Equipment"),
    accept(974, krakle, "Krakle has a thermometer for the volcano."),
    along(objective(4503, ug(nil, 31.0, 77.7), "Finish the diemetradon bones and scales in the south-west.",
      "8 Webbed Diemetradon Scale", "8 Webbed Pterrordax Scale"), 3882, 4501),
    objective(3882, ug(nil, 31.0, 77.7), "Diemetradons drop the Dinosaur Bones.", "8 Dinosaur Bone"),
    objective(974, ug(nil, 49.6, 45.7), "Climb Fire Plume Ridge and use the thermometer at the hottest spot near the top.", "Krakle's Thermometer"),
    finish(974, krakle), accept(980, krakle, "Krakle sends you to Donova in Winterspring."),
    objective(4502, ug(nil, 49.8, 53.4), "Kill Scorching Elementals and Living Blazes on Fire Plume Ridge for the ash.", "9 Un'Goro Ash"),
    finish(4501, spraggle), finish(3882, spark),
    finish(3881, williden),
    finish(4503, shizzle),
    objective(4301, ug("U'cha", 68.1, 12.6), "U'cha lives at the back of the gorilla cave in the north-east. Clear the way in first.", "U'cha's Pelt"),
    finish(4301, torwa, "Ride back to Torwa at the south-east entrance, then leave the crater toward Gadgetzan."),
    finish(4496, pestlezugg),
    action("hearth", at("Innkeeper Wiley", 62.0, 39.4, M.barrens), "Hearth to Ratchet.", { bind = "Ratchet" }),
    finish(4502, at("Liv Rizzlefix", 62.45, 38.73, M.barrens)),
    taxi("fly", at("Bragok", 63.1, 37.2, M.barrens), RUTTHERAN, "Fly to Rut'theran Village."),
    action("goto", at(nil, 55.9, 89.5, M.teldrassil), "Take the portal up to Darnassus."),
    withItem(11682, objective(4441, dar(nil, 39.3, 84.7), "Fill Eridan's vial at the fountain inside the Temple of the Moon.", "Vial of Blessed Water")),
    accept(3763, dar("Innkeeper Saelienne", 67.4, 15.7), "Innkeeper Saelienne has a note for the Arch Druid."),
    accept(1047, dar("Darnassus notice", 61.6, 40.6), "Take the Cenarion notice near the bank."),
    finish(3763, fandral, "Fandral Staghelm stands at the top of the Cenarion Enclave."), accept(3764, fandral),
    finish(1047, fandral), accept(6761, fandral),
    finish(3764, dar("Jenal", 31.49, 8.23), "Give Jenal 20 Un'Goro Soil. Use Next if you didn't keep enough."),
    accept(3781, fandral), finish(3781, mathrengyl), finish(6761, mathrengyl),
    accept(6762, mathrengyl, "Mathrengyl sends you to Rabine Saturna in Moonglade."),
    action("goto", dar(nil, 29.5, 41.4), "Take the portal down to Rut'theran Village."),
    accept(979, erelas, "Erelas asks you to find Ranshalla in Winterspring."),
    accept(5250, at("Daryn Lightwind", 55.41, 92.23, M.teldrassil), "Daryn Lightwind has a Starfall errand in Winterspring."),
  })
end

-- 54-55: Felwood's Shadow Hold, Timbermaw, Donova's Winterfall chain and Linken's sword.
do
  local fw, ws = on.felwood, on.winterspring
  local eridan = fw("Eridan Bluewind", 51.35, 81.51)
  local greta = fw("Greta Mosshoof", 51.21, 82.11)
  local jessir = fw("Jessir Moonbow", 51.35, 82.01)
  local donova = ws("Donova Snowden", 31.27, 45.16)
  local wynd = ws("Wynd Nightchaser", 51.97, 30.39)
  local jaron = ws("Jaron Stoneshaper", 52.14, 30.43)
  local nafien = fw("Nafien", 64.77, 8.13)
  local remains = fw("Remains of Trey Lightforge", 38.5, 50.41)
  local collie = on.ungoro("J.D. Collie", 41.92, 2.7)
  local ratchet = { bind = "Ratchet" }

  q(4442, "Purified!", 54, 49, 4441)
  q(5165, "Dousing the Flames of Protection", 55, 48, 5159)
  q(5202, "A Strange Red Key", 55, 49)
  quest[5202].startItem = 13140
  q(5203, "Rescue From Jaedenar", 55, 49, 5202)
  q(4261, "Ancient Spirit", 56, 49, 4442)
  q(8461, "Deadwood of the North", 55, 45)
  q(8465, "Speak to Salfa", 55, 45, 8461)
  q(8470, "Deadwood Ritual Totem", 55, 45)
  quest[8470].startItem = 20741
  q(6031, "Runecloth", 55, 50)
  q(3912, "Meet at the Grave", 52, 47, 3909)
  q(4842, "Strange Sources", 56, 51, 980)
  q(3913, "A Grave Situation", 52, 47, 3912)
  q(3914, "Linken's Sword", 52, 47, 3913)
  q(3941, "A Gnome's Assistance", 52, 47, 3914)
  q(3942, "Linken's Memory", 54, 47, 3941)
  q(5082, "Threat of the Winterfall", 56, 52, 6603)
  q(5083, "Winterfall Firewater", 56, 52)
  quest[5083].startItem = 12771
  q(5084, "Falling to Corruption", 56, 52, 5083)
  q(5085, "Mystery Goo", 56, 52, 5084)
  q(5086, "Toxic Horrors", 56, 52, 5085)
  q(5087, "Winterfall Runners", 57, 52, 5086)
  q(5242, "A Final Blow", 58, 48, 5165)
  q(5204, "Retribution of the Light", 57, 49, 5203)
  q(5385, "The Remains of Trey Lightforge", 57, 49, 5204)
  q(5244, "The Ruins of Kel'Theril", 56, 53, 5250)
  q(4861, "Enraged Wildkin", 59, 53)

  chapter("winterspring-54", "Felwood and Winterspring: Shadow Hold and the Winterfall", M.felwood, 54, 55, {
    "https://www.wowhead.com/forever/zone=618/winterspring",
    "https://www.wowhead.com/forever/zone=361/felwood",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", at("Vesprystus", 58.4, 94.0, M.teldrassil), ASTRANAAR, "Fly to Astranaar."),
    action("goto", fw(nil, 51.2, 82.0), "Ride north out of Astranaar into Felwood. The Emerald Sanctuary is beside the road."),
    finish(4441, eridan, "Give Eridan the blessed water."), accept(4442, eridan),
    finish(4442, eridan, "Wait for the ritual, then speak to Eridan again."),
    finish(5159, greta), accept(5165, greta, "Greta gives you purified water for the braziers in Shadow Hold."),
    withItem(13140, accept(5202, nil, "Jaedenar's demons can drop a Blood Red Key. Use it from your bags if you find one.")),
    finish(5202, fw("Captured Arko'narin", 36.21, 55.47), "Arko'narin is chained in the first cave of Shadow Hold."),
    accept(5203, fw("Captured Arko'narin", 36.21, 55.47)),
    withItem(12906, objective(5165, fw(nil, 37.7, 52.7), "Inside Shadow Hold, douse the four braziers with the purified water as you go.",
      "Brazier of Pain", "Brazier of Malice", "Brazier of Suffering", "Brazier of Hatred")),
    objective(5203, fw(nil, 35.4, 59.0), "Let Arko'narin collect her gear, then guard her as she fights her way out. Trey Lightforge's spirit attacks near the exit.",
      "Arko'narin escorted"),
    withItem(11445, accept(4261, fw("Arei", 49.6, 30.4), "Ride north to the Irontree Woods. The ancient spirit Arei asks for help.")),
    objective(4261, fw(nil, 49.6, 30.4), "Escort Arei out of the woods. Corrupted treants attack along the way.", "Arei escorted"),
    accept(8461, nafien, "Follow the road north to Nafien at Timbermaw Hold."),
    objective(8461, fw(nil, 62.6, 10.1), "Clear the Deadwood furbolg camp next to the tunnel.",
      "6 Deadwood Den Watchers", "6 Deadwood Avengers", "6 Deadwood Shamans"),
    finish(8461, nafien), accept(8465, nafien),
    withItem(20741, accept(8470, fw("Kernda", 65.5, 3.52), "If the furbolgs dropped a Deadwood Ritual Totem, use it and hand it to Kernda inside Timbermaw Hold.")),
    finish(8470, fw("Kernda", 65.5, 3.52)),
    optional(accept(6031, fw("Meilosh", 65.69, 2.81), "Meilosh takes 30 Runecloth for Timbermaw reputation. Skip it unless you have the cloth.")),
    optional(finish(6031, fw("Meilosh", 65.69, 2.81))),
    finish(8465, ws("Salfa", 27.73, 34.5), "Salfa stands outside the Winterspring end of the tunnel."),
    carried(finish(3909, donova, "Tell Donova what Gregan said about the elixir.")),
    accept(3912, donova, "Donova sends you to a grave outside Gadgetzan."),
    finish(980, donova, "Report the volcano's hot springs to Donova."),
    accept(4842, donova, "Donova wants a hot spring in the far south tested. You will pass it later."),
    finish(6603, donova), accept(5082, donova),
    objective(5082, ws(nil, 41.6, 42.8), "The Winterfall furbolgs camp east of the springs.",
      "8 Winterfall Pathfinders", "8 Winterfall Den Watchers", "8 Winterfall Totemics"),
    withItem(12771, accept(5083, nil, "Winterfall furbolgs drop an Empty Firewater Flask. Use it from your bags.")),
    finish(5082, donova), finish(5083, donova), accept(5084, donova),
    finish(5250, wynd, "Ride east to Starfall Village. Wynd Nightchaser stands in the lodge."),
    accept(5244, wynd), finish(5244, jaron),
    accept(4861, jaron, "Jaron's supply wagon was lost in the south. Look for it on your next pass."),
    finish(5084, fw("Deadwood Cauldron", 60.2, 5.84), "Go back through Timbermaw Hold. Search the cauldron in the Deadwood camp at the Felwood end."),
    accept(5085, fw("Deadwood Cauldron", 60.2, 5.84)),
    finish(5085, donova, "Take the goo back to Donova."), accept(5086, donova, "Toxic Horrors live in Felwood. You will pass them again."),
    action("hearth", at("Innkeeper Wiley", 62.0, 39.4, M.barrens), "Hearth to Ratchet.", ratchet),
    taxi("fly", at("Bragok", 63.1, 37.2, M.barrens), GADGETZAN, "Fly to Gadgetzan."),
    withItem(11243, objective(3912, on.tanaris(nil, 54.0, 28.6), "Drink the Videre Elixir in the graveyard outside town. You die and appear as a ghost.",
      "Videre Elixir used")),
    finish(3912, on.tanaris("Gaeriyan", 53.92, 23.33), "As a ghost, find Gaeriyan to the north."), accept(3913, on.tanaris("Gaeriyan", 53.92, 23.33)),
    finish(3913, on.tanaris("A Conspicuous Gravestone", 53.81, 29.06), "Resurrect, then search the gravestone Gaeriyan described."),
    accept(3914, on.tanaris("A Conspicuous Gravestone", 53.81, 29.06)),
    taxi("fly", on.tanaris("Bera Stonehammer", 51.0, 29.3), MARSHAL, "Fly to Marshal's Refuge."),
    finish(3914, on.ungoro("Linken", 44.66, 8.1), "Linken sits at the back of the refuge."), accept(3941, on.ungoro("Linken", 44.66, 8.1)),
    finish(3941, collie), accept(3942, collie),
    taxi("fly", on.ungoro("Gryfe", 45.2, 5.8), TALRENDIS, "Fly to Talrendis Point."),
    finish(4261, at("Kayneth Stillwind", 85.24, 44.71, M.ashenvale), "Ride west into Ashenvale. Kayneth Stillwind waits at Forest Song."),
    action("goto", fw(nil, 51.2, 82.0), "Ride west through Ashenvale and north into Felwood to the Emerald Sanctuary."),
    finish(5165, greta), accept(5242, greta),
    finish(5203, jessir), accept(5204, jessir),
    finish(3942, eridan),
    objective(5204, fw("Rakaiah", 38.3, 50.5), "Return to Shadow Hold and kill the succubus Rakaiah.", "Rakaiah"),
    finish(5204, remains, "Search Trey Lightforge's remains beside her."), accept(5385, remains),
    objective(5242, fw("Shadow Lord Fel'dan", 38.8, 46.8), "Go deeper into Shadow Hold for Moora, Salia and Shadow Lord Fel'dan. Pull them one at a time.",
      "Moora", "Salia", "Shadow Lord Fel'dan's Head"),
    finish(5242, greta), finish(5385, jessir),
    objective(5086, fw(nil, 49.6, 26.6), "Toxic Horrors roam the poisoned pools near Irontree Woods.", "3 Toxic Horror Droplet"),
    action("goto", ws(nil, 27.8, 34.6), "Go through Timbermaw Hold into Winterspring."),
    finish(5086, donova), accept(5087, donova),
  })
end

-- 55-56: Everlook, Jaron's wagon, Ranshalla and the Frostmaul giants.
do
  local ws = on.winterspring
  local vizzie = ws("Innkeeper Vizzie", 61.4, 38.8)
  local mauari = ws("Witch Doctor Mau'ari", 61.92, 38.3)
  local jaron = ws("Jaron Stoneshaper", 52.14, 30.43)
  local donova = ws("Donova Snowden", 31.27, 45.16)
  local everlook = { bind = "Everlook" }

  q(969, "Luck Be With You", 60, 55)
  q(4863, "Enraged Wildkin", 59, 53, 4861)
  q(4864, "Enraged Wildkin", 59, 53, 4863)
  q(5121, "High Chief Winterfall", 59, 52, 5087)
  q(5123, "The Final Piece", 59, 52, 5087)
  quest[5123].startItem = 12842

  chapter("winterspring-55", "Winterspring: Everlook and the Southern Valleys", M.winterspring, 55, 56, {
    "https://www.wowhead.com/forever/zone=618/winterspring",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    action("sethearth", vizzie, "Ride east to Everlook and bind at the inn.", everlook),
    accept(969, mauari, "Witch Doctor Mau'ari wants shards from the Frostmaul giants."),
    along(objective(5087, ws(nil, 60.0, 50.0), "Winterfall Runners carry crates along the roads south of Everlook. Kill them when you see them.", "Winterfall Crate"), 4861),
    finish(4861, ws("Damaged Crate", 58.99, 59.79), "Follow the road south to Jaron's wrecked camp."),
    accept(4863, ws("Damaged Crate", 58.99, 59.79)),
    finish(4863, ws("Jaron's Wagon", 61.44, 60.68)), accept(4864, ws("Jaron's Wagon", 61.44, 60.68)),
    objective(4864, ws(nil, 61.4, 60.7), "Pick up Jaron's supplies from the snow around the wagon.", "Jaron's Supplies"),
    finish(979, ws("Ranshalla", 63.07, 59.48), "Ranshalla camps in the hills east of the wagon."),
    objective(4864, ws(nil, 65.5, 60.3), "Kill the owlbeasts in the valley until one drops the Blue-feathered Amulet.", "Blue-feathered Amulet"),
    objective(969, ws(nil, 59.1, 68.3), "Frostmaul giants and shredders in Frostwhisper Gorge drop the shards.", "4 Frostmaul Shards"),
    objective(4842, ws(nil, 59.9, 74.0), "Test the hot spring at the south end of the gorge for Donova.", "Strange Sources"),
    action("hearth", vizzie, "Hearth to Everlook.", everlook),
    finish(969, mauari),
    finish(4864, jaron, "Take Jaron his supplies and amulet at Starfall Village."),
    finish(4842, donova), finish(5087, donova),
    taxi("fly", ws("Maethrya", 62.3, 36.6), AUBERDINE, "Fly to Auberdine."),
    action("boat", at(nil, 32.4, 43.8, M.darkshore), "Take the Menethil ship from Auberdine's west pier. Use Next in Menethil Harbor.",
      { name = "Auberdine - Menethil Harbor" }),
    taxi("fly", at("Shellei Brondir", 9.5, 59.7, M.wetlands), IF_FLIGHT, "Fly to Ironforge."),
  })
end

-- 56-57: Ironforge, the Searing Gorge's Slag Pit, Morgan's Vigil and the True Masters.
do
  local bs, sg = on.steppes, on.searing
  local ironforge = function(name, x, y) return at(name, x, y, M.ironforge) end
  local archesonus = ironforge("Royal Historian Archesonus", 38.37, 55.31)
  local thorius = ironforge("Curator Thorius", 71.5, 15.74)
  local archaeologist = sg("Dying Archaeologist", 41.14, 25.56)
  local altar = sg("Altar of Suntara", 41.25, 25.41)
  local zamael = sg("Zamael Lunthistle", 29.57, 26.29)
  local oralius = bs("Oralius", 84.56, 68.68)
  local helendis = bs("Helendis Riverhorn", 85.82, 68.95)
  local maxwell = bs("Marshal Maxwell", 84.74, 69.02)
  local tinkee = bs("Tinkee Steamboil", 65.24, 24.0)
  local maxwort = bs("Maxwort Uberglint", 65.15, 23.91)
  local cyrus = bs("Cyrus Therepentous", 95.09, 31.56)
  local borgus = bs("Borgus Stoutarm", 84.3, 68.3)
  local solomon = at("Magistrate Solomon", 24.9, 44.45, M.redridge)
  local bolvar = at("Highlord Bolvar Fordragon", 80.21, 38.35, M.stormwind)
  local shaw = at("Master Mathias Shaw", 78.31, 70.74, M.stormwind)
  local ironforgeBind = { bind = "Ironforge" }

  q(3702, "The Smoldering Ruins of Thaurissan", 54, 50)
  q(3701, "The Smoldering Ruins of Thaurissan", 54, 50, 3702)
  q(3371, "Dwarven Justice", 55, 40, 3368)
  q(3372, "Release Them", 52, 40, 3371)
  q(3566, "Rise, Obsidion!", 52, 45, 3372)
  q(3377, "Prayer to Elune", 50, 40)
  q(3824, "Gor'tesh the Brute Lord", 53, 48, 3823)
  q(3825, "Ogre Head On A Stick = Party", 53, 48, 3824)
  q(4283, "FIFTY! YEP!", 56, 50)
  q(4182, "Dragonkin Menace", 54, 48)
  q(4183, "The True Masters", 54, 48, 4182)
  q(4184, "The True Masters", 54, 48, 4183)
  q(4185, "The True Masters", 54, 48, 4184)
  q(4186, "The True Masters", 54, 48, 4185)
  q(4223, "The True Masters", 54, 48, 4186)
  q(4224, "The True Masters", 54, 48, 4223)
  q(4726, "Broodling Essence", 52, 50)
  q(4296, "Tablet of the Seven", 50, 50)
  q(4022, "A Taste of Flame", 54, 52, 3481)
  q(6182, "The First and the Last", 60, 56)
  q(6183, "Honor the Dead", 60, 56, 6182)
  q(6184, "Flint Shadowmore", 60, 56, 6183)

  chapter("steppes-56", "Burning Steppes: Morgan's Vigil and the True Masters", M.steppes, 56, 57, {
    "https://www.wowhead.com/forever/zone=46/burning-steppes",
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    accept(3702, archesonus, "Royal Historian Archesonus stands beside King Magni in the High Seat."),
    objective(3702, archesonus, "Listen to the history of Thaurissan.", "The Smoldering Ruins of Thaurissan"),
    finish(3702, archesonus), accept(3701, archesonus),
    action("sethearth", ironforge("Innkeeper Firebrew", 18.1, 51.5), "Bind at the Stonefire Tavern.", ironforgeBind),
    accept(3371, thorius, "Curator Thorius in the Hall of Explorers has news of Dorius's dig team."),
    taxi("fly", ironforge("Gryth Thurden", 55.5, 47.7), THORIUM, "Fly to Thorium Point."),
    finish(3371, archaeologist, "Go down into the Slag Pit. The dying archaeologist lies near its upper entrance."),
    accept(3372, archaeologist),
    accept(3377, zamael, "On the way west, Zamael Lunthistle sits in a small camp on the north-west ridge."),
    finish(3377, zamael, "Listen to his tale."),
    objective(3372, sg(nil, 29.1, 25.8), "Twilight Idolaters in the north-west guard the Mysterious Artifact.", "Mysterious Artifact"),
    finish(3372, altar, "Place the artifact on the Altar of Suntara in the Slag Pit."), accept(3566, archaeologist),
    objective(3566, sg("Obsidion", 41.8, 24.3), "Lathoric the Black and his golem Obsidion appear at the altar. Kill Lathoric first, then Obsidion.",
      "Head of Lathoric the Black", "Heart of Obsidion"),
    taxi("fly", sg("Lanie Reed", 37.9, 30.9), MORGANS, "Fly to Morgan's Vigil."),
    accept(3824, oralius), accept(4283, oralius, "Oralius also wants 50 Blackrock Medallions from the orcs across the Steppes."),
    accept(4182, helendis),
    accept(4726, tinkee, "Ride north-west to Flame Crest. Tinkee Steamboil gives you a device for the broodlings."),
    accept(4296, maxwort),
    accept(4022, cyrus, "Ride east along the northern cliffs to Cyrus Therepentous."),
    objective(4022, cyrus, "Show Cyrus the Black Dragonflight Molt from the Searing Gorge hoard.", "Black Dragonflight Molt"),
    finish(4022, cyrus),
    along(withItem(12284, objective(4726, bs(nil, 90.6, 43.6), "Use the Draco-Incarcinatrix 900 on Black Broodlings in the east, then kill them for their essence.",
      "8 Broodling Essence")), 4182),
    along(objective(4182, bs(nil, 90.6, 43.6), "Kill the black dragonkin around the eastern spires.",
      "15 Black Broodlings", "10 Black Dragonspawn", "4 Black Wyrmkin", "Black Drake"), 4726),
    along(objective(4296, bs("Tablet of the Seven", 54.1, 40.8), "Ride west to the tablet at the edge of the Ruins of Thaurissan and copy it.", "Tablet Transcript"), 3701, 4283),
    along(objective(3701, bs(nil, 57.4, 36.4), "Search the Thaurissan Relics scattered through the ruins.", "Thaurissan Relic"), 4283),
    along(objective(3824, bs("Gor'tesh", 39.3, 55.3), "Gor'tesh holds the Blackrock camp south-west of the mountain.", "Gor'tesh's Lopped Off Head"), 4283),
    objective(4283, bs(nil, 48.8, 59.6), "Finish the medallions in the Blackrock camps of the southern Steppes.", "50 Blackrock Medallion"),
    finish(4283, oralius, "Ride back east to Morgan's Vigil."), finish(3824, oralius), accept(3825, oralius),
    finish(4182, helendis), accept(4183, helendis),
    taxi("fly", borgus, LAKESHIRE, "Fly to Lakeshire."),
    finish(4183, solomon, "Magistrate Solomon is in the Lakeshire town hall."), accept(4184, solomon),
    taxi("fly", at("Ariena Stormfeather", 25.5, 59.4, M.redridge), SW_FLIGHT, "Fly to Stormwind."),
    finish(4184, bolvar, "Highlord Bolvar is in the throne room of Stormwind Keep."), accept(4185, bolvar),
    objective(4185, bolvar, "Speak with Lady Katrana Prestor beside him, then with Bolvar again.", "Lady Prestor's counsel"),
    finish(4185, bolvar), accept(4186, bolvar),
    accept(6182, bolvar, "Bolvar also sends you to Mathias Shaw."),
    finish(6182, shaw, "Mathias Shaw is in SI:7, in Old Town."), accept(6183, shaw),
    finish(6183, shaw), accept(6184, shaw, "Shaw's contact waits at Chillwind Camp. Keep this for the Plaguelands."),
    taxi("fly", at("Dungar Longdrink", 71.3, 72.2, M.stormwind), LAKESHIRE, "Fly back to Lakeshire."),
    finish(4186, solomon), accept(4223, solomon),
    taxi("fly", at("Ariena Stormfeather", 25.5, 59.4, M.redridge), MORGANS, "Fly to Morgan's Vigil."),
    finish(4223, maxwell), accept(4224, maxwell),
    objective(4224, bs("Ragged John", 65.0, 23.8), "Ragged John wanders near Flame Crest. Hear his whole story.", "Ragged John's tale"),
    finish(4726, tinkee),
    finish(4296, maxwort),
    objective(3825, bs("Soft Dirt Mound", 81.0, 46.8), "Climb Dreadmaul Rock and plant Gor'tesh's head in the soft dirt mound on top.", "Soft Dirt Mound"),
    finish(3825, oralius), finish(4224, maxwell),
    action("hearth", ironforge("Innkeeper Firebrew", 18.1, 51.5), "Hearth to Ironforge.", ironforgeBind),
    finish(3701, archesonus), finish(3566, thorius),
  })
end

-- 57-58: Andorhal and the cauldrons, Tirion Fordring and Darrowshire's first loop.
do
  local wpl, epl = on.wpl, on.epl
  local ashlam = wpl("Commander Ashlam Valorfist", 42.7, 84.03)
  local macdonnell = wpl("High Priestess MacDonnell", 42.97, 84.5)
  local pureheart = wpl("Argent Officer Pureheart", 42.97, 83.55)
  local arbington = wpl("Alchemist Arbington", 42.66, 83.77)
  local dumah = wpl("Nathaniel Dumah", 43.42, 84.83)
  local flint = wpl("Flint Shadowmore", 43.61, 84.51)
  local marlene = wpl("Marlene Redpath", 49.17, 78.57)
  local mulgris = wpl("Mulgris Deepriver", 53.73, 64.66)
  local chromie = wpl("Chromie", 39.46, 66.76)
  local bibilfaz = wpl("Bibilfaz Featherwhistle", 42.9, 85.1)
  local tirion = epl("Tirion Fordring", 7.5, 43.6)
  local pamela = epl("Pamela Redpath", 31.15, 77.98)
  local carlin = epl("Carlin Redpath", 71.7, 50.04)
  local alen = epl("Caretaker Alen", 69.93, 53.72)
  local anderson = at("Innkeeper Anderson", 51.2, 58.9, M.hillsbrad)
  local southshore = { bind = "Southshore" }

  q(5097, "All Along the Watchtowers", 56, 50, 5092)
  q(5219, "Target: Dalson's Tears", 55, 50, 5217)
  q(5220, "Return to Chillwind Camp", 55, 50, 5219)
  q(5222, "Target: Writhing Haunt", 55, 50, 5220)
  q(5223, "Return to Chillwind Camp", 55, 50, 5222)
  q(5903, "A Plague Upon Thee", 55, 48)
  q(5904, "A Plague Upon Thee", 55, 48, 5903)
  q(6185, "The Eastern Plagues", 60, 56, 6184)
  q(5142, "Little Pamela", 55, 50)
  q(5149, "Pamela's Doll", 55, 50, 5142)
  q(5152, "Auntie Marlene", 56, 50, 5149)
  q(5241, "Uncle Carlin", 56, 50, 5149)
  q(5211, "Defenders of Darrowshire", 55, 50, 5241)
  q(5153, "A Strange Historian", 56, 50, 5152)
  q(5154, "The Annals of Darrowshire", 56, 50, 5153)
  q(5210, "Brother Carlin", 56, 50, 5154)
  q(4971, "A Matter of Time", 56, 53)
  q(4972, "Counting Out Time", 56, 53, 4971)
  q(4984, "The Wildlife Suffers Too", 54, 51)
  q(5058, "Mrs. Dalson's Diary", 55, 52)
  q(5533, "Scholomance", 55, 55, 5097)
  q(5537, "Skeletal Fragments", 57, 55, 5533)
  q(5225, "Target: Gahrron's Withering", 58, 50, 5223)
  q(5542, "Demon Dogs", 56, 52)
  q(5543, "Blood Tinged Skies", 56, 52)
  q(5544, "Carrion Grubbage", 56, 52)
  q(5742, "Redemption", 56, 52, { 5542, 5543, 5544 })
  q(5781, "Of Forgotten Memories", 57, 52, 5742)
  q(5845, "Of Lost Honor", 58, 52, 5781)
  q(6021, "Zaeldarr the Outcast", 55, 50)
  q(6024, "Hameya's Plea", 60, 54)

  chapter("plaguelands-57", "Plaguelands: Andorhal and Tirion Fordring", M.wpl, 57, 58, {
    "https://www.wowhead.com/forever/zone=28/western-plaguelands",
    "https://www.wowhead.com/forever/zone=139/eastern-plaguelands",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", at("Gryth Thurden", 55.5, 47.7, M.ironforge), "Southshore, Hillsbrad", "Fly to Southshore."),
    action("sethearth", anderson, "Bind at the Southshore inn, the closest inn to the Plaguelands.", southshore),
    taxi("fly", at("Darla Harris", 49.3, 52.3, M.hillsbrad), CHILLWIND, "Fly to Chillwind Camp."),
    accept(5097, ashlam, "Ashlam gives you a beacon torch for the Andorhal towers."),
    accept(5219, macdonnell), accept(5903, dumah, "Nathaniel Dumah hands you a jar for termites from the Eastern Plaguelands."),
    finish(6184, flint, "Flint Shadowmore waits by the camp's edge."), accept(6185, flint),
    accept(5142, marlene, "Marlene Redpath lives in the house south of Andorhal."),
    withItem(12815, B.objectivePart(5097, 1, wpl("Andorhal Tower One", 40.0, 71.7), "Stand in the doorway of each Andorhal tower and use the Beacon Torch. Start with the south-west tower.", "Andorhal Tower One")),
    withItem(12815, B.objectivePart(5097, 2, wpl("Andorhal Tower Two", 42.4, 66.2), "Mark the north-west tower.", "Andorhal Tower Two")),
    withItem(12815, B.objectivePart(5097, 3, wpl("Andorhal Tower Three", 44.2, 63.1), "Mark the north-east tower.", "Andorhal Tower Three")),
    withItem(12815, B.objectivePart(5097, 4, wpl("Andorhal Tower Four", 46.6, 71.2), "Mark the south-east tower.", "Andorhal Tower Four")),
    accept(4984, mulgris, "Mulgris Deepriver, a troll druid, stands on the hill above the Writhing Haunt."),
    accept(5058, wpl("Mrs. Dalson's Diary", 47.8, 50.67), "Read the diary in the Dalson farmhouse to the north."),
    finish(5058, wpl("Mrs. Dalson's Diary", 47.8, 50.67)),
    objective(5219, wpl(nil, 46.2, 52.4), "Kill the Cauldron Lord beside the cauldron at Dalson's Tears for its key.", "Dalson's Tears Cauldron Key"),
    finish(5219, wpl("Scourge Cauldron", 46.18, 51.9), "Use the key and fill the bottle."), accept(5220, wpl("Scourge Cauldron", 46.18, 51.9)),
    objective(4984, wpl(nil, 46.6, 40.4), "Diseased Wolves roam the fields north of Dalson's Tears.", "8 Diseased Wolf"),
    finish(5097, ashlam, "Ride back to Chillwind Camp."), accept(5533, ashlam),
    finish(5533, arbington),
    finish(5220, macdonnell), accept(5222, macdonnell),
    objective(5222, wpl(nil, 53.0, 66.1), "Kill the Cauldron Lord at the Writhing Haunt.", "Writhing Haunt Cauldron Key"),
    finish(5222, wpl("Scourge Cauldron", 53.02, 65.61)), accept(5223, wpl("Scourge Cauldron", 53.02, 65.61)),
    finish(4984, mulgris),
    action("goto", epl(nil, 7.5, 43.6), "Follow the road east into the Eastern Plaguelands. Tirion Fordring's hut is on the hill north of the road."),
    accept(5542, tirion), accept(5543, tirion), accept(5544, tirion),
    B.objectivePart(6185, 2, epl(nil, 22.9, 63.7), "Search the dead SI:7 agents around the Undercroft area for their insignias.", "SI:7 Insignia (Fredo)"),
    B.objectivePart(6185, 3, epl(nil, 24.3, 63.6), "The second agent lies nearby.", "SI:7 Insignia (Turyen)"),
    B.objectivePart(6185, 1, epl(nil, 24.3, 68.1), "The third lies a little further south.", "SI:7 Insignia (Rutger)"),
    finish(5142, pamela, "Pamela Redpath's ghost plays in ruined Darrowshire."), accept(5149, pamela),
    objective(5149, epl(nil, 34.0, 77.3), "Search the Darrowshire houses for the doll's head, left side and right side, then combine them.", "Pamela's Doll"),
    finish(5149, pamela), accept(5152, pamela), accept(5241, pamela),
    along(objective(5543, epl(nil, 47.5, 49.3), "Kill Plaguebats, hounds and Carrion Grubs as you ride north-east across the zone.", "30 Plaguebat"), 5542, 5544),
    along(objective(5544, epl(nil, 47.5, 49.3), "Carrion Grubs and Devourers drop the worm meat.", "15 Slab of Carrion Worm Meat"), 5542, 5543),
    finish(5241, carlin), accept(5211, carlin),
    taxi("getfp", epl("Khaelyn Steelwing", 71.8, 49.6), LIGHTSHOPE, "Learn the Light's Hope Chapel flight path."),
    accept(6021, alen),
    withItem(15042, objective(5903, epl(nil, 26.6, 22.9), "Use the termite jar on the termite mounds in the north-west.", "100 Plagueland Termites")),
    objective(5542, epl(nil, 44.2, 30.7), "Finish the plaguehounds in the northern hills.", "20 Plaguehound Runt", "5 Plaguehound", "5 Frenzied Plaguehound"),
    finish(5542, tirion), finish(5543, tirion), finish(5544, tirion),
    accept(5742, tirion), objective(5742, tirion, "Listen to Tirion's story.", "Redemption"), finish(5742, tirion),
    accept(5781, tirion),
    objective(6021, epl("Zaeldarr the Outcast", 23.1, 72.6), "Zaeldarr the Outcast waits at the Undercroft.", "Zaeldarr's Head"),
    accept(6024, epl(nil, 22.9, 72.9), "Read Hameya's plea near the Undercroft."),
    objective(5781, epl(nil, 23.8, 74.5), "Go into the Undercroft and kill Mercutio Filthgorger for Taelan's Hammer.", "Taelan's Hammer"),
    finish(5781, tirion), accept(5845, tirion),
    action("hearth", anderson, "Hearth to Southshore.", southshore),
    taxi("fly", at("Darla Harris", 49.3, 52.3, M.hillsbrad), CHILLWIND, "Fly to Chillwind Camp."),
    finish(5223, macdonnell), accept(5225, macdonnell),
    finish(5903, dumah), accept(5904, dumah),
    finish(6185, flint),
    accept(5537, arbington, "Arbington wants Skeletal Fragments from Andorhal's skeletons."),
    finish(5152, marlene), accept(5153, marlene),
    objective(5153, wpl(nil, 49.7, 76.8), "Search the grave behind Marlene's house for Joseph's ring.", "Joseph's Wedding Ring"),
    finish(5153, chromie, "Chromie hides in the inn ruins of Andorhal."), accept(5154, chromie), accept(4971, chromie),
    withItem(12627, objective(4971, wpl(nil, 48.1, 66.2), "Use the Temporal Displacer near an Andorhal silo and kill the Temporal Parasites that appear.", "10 Temporal Parasite")),
    objective(5154, wpl(nil, 43.5, 69.5), "Find the Annals of Darrowshire in the town hall.", "Annals of Darrowshire"),
    finish(4971, chromie), accept(4972, chromie), finish(5154, chromie), accept(5210, chromie),
    along(objective(4972, wpl(nil, 42.7, 70.3), "Open lockboxes in the rubble of Andorhal for the watches.", "5 Andorhal Watch"), 5537),
    along(objective(5537, wpl(nil, 39.8, 67.4), "Andorhal's skeletons drop Skeletal Fragments.", "15 Skeletal Fragments"), 4972),
    finish(4972, chromie), finish(5537, arbington),
  })
end

-- 58-59: Light's Hope, Northdale, Hearthglen and the last cauldron.
do
  local wpl, epl = on.wpl, on.epl
  local carlin = epl("Carlin Redpath", 71.7, 50.04)
  local alen = epl("Caretaker Alen", 69.93, 53.72)
  local tirion = epl("Tirion Fordring", 7.5, 43.6)
  local kirsta = wpl("Kirsta Deepshadow", 51.92, 28.06)
  local mulgris = wpl("Mulgris Deepriver", 53.73, 64.66)
  local macdonnell = wpl("High Priestess MacDonnell", 42.97, 84.5)
  local dumah = wpl("Nathaniel Dumah", 43.42, 84.83)
  local chambers = epl("Jessica Chambers", 71.8, 48.5)
  local lightsHope = { bind = "Light's Hope Chapel" }

  q(5181, "Villains of Darrowshire", 57, 50, 5210)
  q(5168, "Heroes of Darrowshire", 56, 50, 5210)
  q(5846, "Of Love and Family", 58, 52, 5845)
  q(5226, "Return to Chillwind Point", 58, 50, 5225)
  q(6389, "A Plague Upon Thee", 55, 48, 5904)
  q(6004, "Unfinished Business", 56, 50)
  q(6023, "Unfinished Business", 57, 50, 6004)
  q(6025, "Unfinished Business", 58, 50, 6023)

  chapter("plaguelands-58", "Plaguelands: Darrowshire's Heroes and Hearthglen", M.epl, 58, 59, {
    "https://www.wowhead.com/forever/zone=139/eastern-plaguelands",
    "https://www.wowhead.com/forever/zone=28/western-plaguelands",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", wpl("Bibilfaz Featherwhistle", 42.9, 85.1), LIGHTSHOPE, "Fly to Light's Hope Chapel."),
    action("sethearth", chambers, "Bind at Light's Hope Chapel.", lightsHope),
    finish(5210, carlin), accept(5181, carlin), accept(5168, carlin),
    finish(6021, alen),
    objective(5845, epl(nil, 71.3, 34.0), "Ride north to Northdale and search the ruined house for the Symbol of Lost Honor.", "Symbol of Lost Honor"),
    objective(6024, epl("Infiltrator Hameya", 62.0, 11.1), "Infiltrator Hameya roams the far north. Kill him for his key.", "Hameya's Key"),
    B.objectivePart(5211, 1, epl(nil, 57.7, 31.5), "Kill ghouls and flayers across the zone and free the Darrowshire spirits that rise from them.", "15 Darrowshire Spirits"),
    B.objectivePart(5181, 1, epl(nil, 44.3, 41.2), "Horgus's skull lies at the Infectis Scar.", "Skull of Horgus"),
    B.objectivePart(5181, 2, epl(nil, 46.9, 55.4), "Marduk's broken sword lies in the Pestilent Scar to the south.", "Shattered Sword of Marduk"),
    finish(6024, epl("Mound of Dirt", 23.58, 73.79), "Use Hameya's key on the mound of dirt behind the Undercroft."),
    finish(5845, tirion), accept(5846, tirion, "Tirion asks you to look for a painting on Caer Darrow."),
    action("goto", wpl(nil, 63.8, 57.2), "Ride west into the Western Plaguelands toward Gahrron's Withering."),
    B.objectivePart(5168, 2, wpl(nil, 63.8, 57.2), "Redpath's Shield lies at Gahrron's Withering.", "Redpath's Shield"),
    objective(5225, wpl(nil, 62.6, 58.9), "Kill the last Cauldron Lord at Gahrron's Withering.", "Gahrron's Withering Cauldron Key"),
    finish(5225, wpl("Scourge Cauldron", 62.54, 58.47)), accept(5226, wpl("Scourge Cauldron", 62.54, 58.47)),
    finish(5904, wpl("Termite Barrel", 48.34, 31.99), "Place the termite barrel in the middle of Northridge Lumber Camp."),
    accept(6389, wpl("Termite Barrel", 48.34, 31.99)),
    accept(6004, kirsta, "Kirsta Deepshadow waits in the hills north of the lumber camp."),
    objective(6004, wpl(nil, 50.8, 40.7), "Kill Scarlet medics, hunters, mages and knights at the Scarlet camps.",
      "2 Scarlet Medic", "2 Scarlet Hunter", "2 Scarlet Mage", "2 Scarlet Knight"),
    finish(6004, kirsta), accept(6023, kirsta),
    B.objectivePart(6023, 1, wpl("Huntsman Radley", 57.8, 36.1), "Huntsman Radley is at the Scarlet camp to the east.", "Huntsman Radley"),
    B.objectivePart(6023, 2, wpl("Cavalier Durgen", 55.1, 23.6), "Cavalier Durgen guards the tower to the north.", "Cavalier Durgen"),
    finish(6023, kirsta), accept(6025, kirsta),
    objective(6025, wpl(nil, 45.7, 18.8), "Climb a tower in Hearthglen to look over the Scarlet forces.", "Hearthglen surveyed"),
    B.objectivePart(5168, 1, wpl(nil, 42.5, 19.0), "Davil's Libram is in the Hearthglen town hall.", "Davil's Libram"),
    finish(6025, kirsta),
    action("hearth", chambers, "Hearth to Light's Hope Chapel.", lightsHope),
    finish(5211, carlin), finish(5181, carlin), finish(5168, carlin),
    taxi("fly", epl("Khaelyn Steelwing", 71.8, 49.6), CHILLWIND, "Fly to Chillwind Camp."),
    finish(5226, macdonnell), finish(6389, dumah),
    finish(5846, wpl("Artist Renfray", 65.77, 75.37), "Ride east to Caer Darrow's lake shore. Artist Renfray's ghost stands on the island."),
  })
end

-- 59: Everlook again, Moonglade, Gadgetzan and Un'Goro on the way to Cenarion Hold.
do
  local ws, sil, mg = on.winterspring, on.silithus, on.moonglade
  local vizzie = ws("Innkeeper Vizzie", 61.4, 38.8)
  local umi = ws("Umi Rumplesnicker", 60.88, 37.62)
  local donova = ws("Donova Snowden", 31.27, 45.16)
  local rabine = mg("Rabine Saturna", 51.69, 45.1)
  local pestlezugg = on.tanaris("Alchemist Pestlezugg", 50.89, 26.96)
  local tranrek = on.tanaris("Tran'rek", 51.57, 26.76)
  local layo = sil("Layo Starstrike", 81.87, 18.93)
  local calandrath = sil("Calandrath", 51.89, 39.16)
  local beetix = sil("Beetix Ficklespragg", 51.61, 38.63)
  local proudhorn = sil("Windcaller Proudhorn", 51.15, 38.29)
  local larksbane = sil("Geologist Larksbane", 49.67, 37.46)
  local ortell = sil("Hermit Ortell", 67.19, 69.76)
  local maralith = sil("Commander Mar'alith", 49.2, 34.18)
  local rutgar = sil("Rutgar Glyphshaper", 41.28, 88.45)
  local everlook = { bind = "Everlook" }

  q(3783, "Are We There, Yeti?", 56, 52)
  q(977, "Are We There, Yeti?", 58, 52, 3783)
  q(4901, "Guardians of the Altar", 59, 52, 979)
  q(1124, "Wasteland", 55, 54, 6762)
  q(5527, "A Reliquary of Purity", 60, 56)
  q(4507, "Pawn Captures Queen", 54, 50, 4496)
  q(4504, "Super Sticky", 54, 48)
  q(1125, "The Spirits of Southwind", 55, 54, 1124)
  q(1126, "Hive in the Tower", 57, 54, 1125)
  q(6844, "Umber, Archivist", 57, 54, 1126)
  q(8307, "Desert Recipe", 57, 54)
  q(8313, "Sharing the Knowledge", 57, 54, 8307)
  q(8317, "Kitchen Assistance", 57, 54, 8313)
  q(8277, "Deadly Desert Venom", 55, 54)
  q(8278, "Noggle's Last Hope", 57, 54, 8277)
  q(8275, "Taking Back Silithus", 55, 54)
  q(8280, "Securing the Supply Lines", 55, 54)
  q(8281, "Stepping Up Security", 57, 54, 8280)
  q(8284, "The Twilight Mystery", 58, 54)
  q(8285, "The Deserter", 59, 54, 8284)
  q(8279, "The Twilight Lexicon", 60, 54, 8285)
  q(8287, "A Terrible Purpose", 60, 54, 8279)
  q(8323, "True Believers", 59, 54, 8279)
  q(8304, "Dearest Natalia", 60, 60)
  q(8308, "Brann Bronzebeard's Lost Letter", 60, 58)
  quest[8308].startItem = 20461
  q(7066, "Seed of Life", 51, 45)

  chapter("silithus-59", "Winterspring to Silithus: Cenarion Hold", M.silithus, 59, 59, {
    "https://www.wowhead.com/forever/zone=1377/silithus",
    "https://www.wowhead.com/forever/zone=618/winterspring",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.wpl("Bibilfaz Featherwhistle", 42.9, 85.1), "Menethil Harbor, Wetlands", "Fly to Menethil Harbor."),
    action("boat", at(nil, 4.6, 57.3, M.wetlands), "Take the Auberdine ship from Menethil's north pier. Use Next in Auberdine.",
      { name = "Menethil Harbor - Auberdine" }),
    taxi("fly", at("Caylais Moonfeather", 36.3, 45.6, M.darkshore), EVERLOOK, "Fly to Everlook."),
    action("sethearth", vizzie, "Bind at the Everlook inn.", everlook),
    accept(3783, umi, "Umi Rumplesnicker, across the street, wants yeti fur."),
    objective(3783, ws(nil, 66.3, 42.6), "Ice Thistle yetis live in the hills east of Everlook.", "10 Thick Yeti Fur"),
    finish(3783, umi), accept(977, umi),
    objective(977, ws(nil, 69.9, 41.7), "The Ice Thistle Matriarch and Patriarch live in the yeti cave south of the village.", "2 Pristine Yeti Horn"),
    accept(4901, ws("Ranshalla", 63.07, 59.48), "Ranshalla's escort is hard at this level. Bring a friend."),
    objective(4901, ws(nil, 64.8, 63.8), "Follow Ranshalla through the Altar of Elune caves and protect her while she lights the torches.", "Altar of Elune"),
    action("hearth", vizzie, "Hearth to Everlook.", everlook),
    finish(977, umi),
    action("goto", mg(nil, 35.8, 71.9), "Go into Timbermaw Hold and take the Moonglade tunnel."),
    forDungeon(finish(7066, mg("Keeper Remulos", 36.18, 41.79), "If you killed Theradras, give Remulos the Seed of Life."), "dungeon-maraudon"),
    finish(6762, rabine, "Rabine Saturna lives in Nighthaven on the lake's east shore."),
    accept(1124, rabine), accept(5527, rabine),
    taxi("getfp", mg("Sindrayl", 48.1, 67.3), MOONGLADE, "Learn the Nighthaven flight path."),
    taxi("fly", mg("Sindrayl", 48.1, 67.3), ASTRANAAR, "Fly to Astranaar."),
    taxi("fly", at("Daelyshia", 34.4, 48.0, M.ashenvale), GADGETZAN, "Fly to Gadgetzan."),
    accept(4507, pestlezugg), accept(4504, tranrek),
    taxi("fly", on.tanaris("Bera Stonehammer", 51.0, 29.3), MARSHAL, "Fly to Marshal's Refuge."),
    objective(4504, on.ungoro(nil, 51.6, 24.8), "Kill the tar beasts in the Lakkari Tar Pits for Super Sticky Tar.", "12 Super Sticky Tar"),
    objective(4507, on.ungoro(nil, 43.5, 81.1), "Go deep into the Gorishi hive in the south, summon the Hive Queen and kill her for her brain.", "Gorishi Queen Brain"),
    action("goto", sil(nil, 81.9, 18.9), "Leave Un'Goro by the north-west ramp into Silithus and ride east to Valor's Rest."),
    finish(1124, layo, "Layo Starstrike stands by the Valor's Rest graveyard."), accept(1125, layo),
    taxi("getfp", sil("Cloud Skydancer", 50.6, 34.4), CENARION, "Ride to Cenarion Hold and learn its flight path."),
    accept(8307, calandrath, "Calandrath runs the Cenarion Hold inn."),
    accept(8277, beetix),
    carried(finish(8275, proudhorn, "If you were sent here to Windcaller Proudhorn, report to him.")),
    accept(8280, proudhorn), accept(8284, larksbane),
    finish(8307, sil("Sandy Cookbook", 37.94, 45.31), "West of the hold, look in the Twilight camp for a sandy cookbook."),
    accept(8313, sil("Sandy Cookbook", 37.94, 45.31)),
    along(objective(8280, sil(nil, 36.8, 33.0), "Kill Dredge Strikers, scorpids and skitterers in the north-west.", "15 Dredge Striker"), 8277),
    along(objective(8277, sil(nil, 36.8, 33.0), "Stonelash scorpids drop stingers and Sand Skitterers drop fangs.",
      "8 Stonelash Scorpid Stinger", "8 Sand Skitterer Fang"), 8280),
    objective(8284, sil(nil, 21.8, 10.4), "Look for Twilight Tablet Fragments around the Twilight Base Camp in the far north-west.", "8 Twilight Tablet Fragment"),
    finish(8313, calandrath), finish(8280, proudhorn), accept(8281, proudhorn),
    finish(8277, beetix), accept(8278, beetix),
    finish(8284, larksbane), accept(8285, larksbane), accept(8304, maralith, "Commander Mar'alith asks about Natalia at Bronzebeard's Encampment."),
    objective(5527, sil(nil, 63.2, 55.4), "Ride south-east to ruined Southwind Village and find the Reliquary of Purity.", "Reliquary of Purity"),
    objective(1125, sil(nil, 63.7, 49.0), "Kill the tortured druids and sentinels around Southwind Village.", "8 Tortured Druid", "8 Tortured Sentinel"),
    withItem(20461, accept(8308, sil(nil, 63.7, 49.0), "If a cultist dropped Brann's letter, use it from your bags.")),
    finish(1125, layo), accept(1126, layo),
    objective(1126, sil(nil, 60.4, 52.6), "Climb the Southwind tower, use the hive stone and kill the Hive'Ashi Ambusher that comes out.", "Encrusted Silithid Object"),
    finish(1126, layo), accept(6844, layo, "Take the object to Umber in Moonglade later."),
    finish(8285, ortell, "Hermit Ortell hides in a cave in the south-east."), accept(8279, ortell),
    along(objective(8281, sil(nil, 41.4, 80.8), "Kill Dredge Crushers in the south.", "20 Dredge Crusher"), 8278),
    along(objective(8278, sil(nil, 41.4, 80.8), "Stonelash Pincers, Flayers and Rock Stalkers roam the same southern hills.",
      "3 Stonelash Pincer Stinger", "3 Stonelash Flayer Stinger", "3 Rock Stalker Fang"), 8281),
    finish(8308, rutgar, "Bronzebeard's Encampment is in the far south."),
    B.objectivePart(8304, 2, rutgar, "Question Rutgar.", "Rutgar Invisible Trigger"),
    B.objectivePart(8304, 1, sil("Frankal Stonebridge", 40.8, 88.9), "Question Frankal beside him.", "Frankal Invisible Trigger"),
    B.objectivePart(8279, 3, sil(nil, 40.9, 42.2), "The Twilight Keeper at the camp west of the hold carries one chapter.", "Twilight Lexicon - Chapter 3"),
    B.objectivePart(8279, 1, sil(nil, 26.7, 36.1), "The second Twilight Keeper is at the camp further west.", "Twilight Lexicon - Chapter 1"),
    B.objectivePart(8279, 2, sil(nil, 16.1, 86.5), "The last chapter is in the far south-west camp.", "Twilight Lexicon - Chapter 2"),
    finish(8279, ortell), accept(8287, ortell),
    finish(8281, proudhorn, "Ride back to Cenarion Hold."), finish(8278, beetix),
    finish(8304, maralith), finish(8287, maralith),
  })
end

-- 59-60: the last hand-ins in Gadgetzan, Everlook, Moonglade and Darnassus.
do
  local mg = on.moonglade
  local dar = function(name, x, y) return at(name, x, y, M.darnassus) end
  local umber = mg("Umber", 44.88, 35.6)
  local rabine = mg("Rabine Saturna", 51.69, 45.1)
  local vizzie = on.winterspring("Innkeeper Vizzie", 61.4, 38.8)

  q(4508, "Calm Before the Storm", 54, 50, 4507)
  q(4510, "Calm Before the Storm", 54, 50, 4508)
  q(6845, "Uncovering Past Secrets", 57, 54, 6844)
  q(1185, "Under the Chitin Was...", 57, 54, 6845)
  q(4902, "Wildkin of Elune", 57, 52, 4901)

  chapter("silithus-60", "The Road to 60: Moonglade and Darnassus", M.darnassus, 59, 60, {
    "https://www.wowhead.com/forever/zone=1377/silithus",
    "https://www.wowhead.com/forever/zone=493/moonglade",
    "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
  }, {
    taxi("fly", on.silithus("Cloud Skydancer", 50.6, 34.4), GADGETZAN, "Fly to Gadgetzan."),
    finish(4507, on.tanaris("Alchemist Pestlezugg", 50.89, 26.96)), accept(4508, on.tanaris("Alchemist Pestlezugg", 50.89, 26.96)),
    finish(4504, on.tanaris("Tran'rek", 51.57, 26.76)),
    action("hearth", vizzie, "Hearth to Everlook.", { bind = "Everlook" }),
    taxi("fly", on.winterspring("Maethrya", 62.3, 36.6), RUTTHERAN, "Fly to Rut'theran Village."),
    finish(4901, at("Erelas Ambersky", 55.5, 92.05, M.teldrassil), "Report the altar to Erelas Ambersky."),
    accept(4902, at("Erelas Ambersky", 55.5, 92.05, M.teldrassil)),
    action("goto", at(nil, 55.9, 89.5, M.teldrassil), "Take the portal up to Darnassus."),
    finish(4508, dar("Gracina Spiritmight", 41.83, 85.62)), accept(4510, dar("Gracina Spiritmight", 41.83, 85.62)),
    finish(4510, dar("Idriana", 39.39, 42.44), "Take the voucher to Idriana at the Darnassus bank."),
    finish(4902, dar("Arch Druid Fandral Staghelm", 34.81, 9.26), "Tell Fandral Staghelm about the wildkin in the Cenarion Enclave."),
    action("goto", dar(nil, 29.5, 41.4), "Take the portal down to Rut'theran Village."),
    taxi("fly", at("Vesprystus", 58.4, 94.0, M.teldrassil), MOONGLADE, "Fly to Nighthaven in Moonglade."),
    finish(6844, umber, "Umber is in the house on the north side of the lake."), accept(6845, umber),
    finish(6845, rabine), finish(5527, rabine),
    accept(1185, umber), finish(1185, umber, "Hand Umber the object one last time. This is the end of the route: well done on reaching 60."),
  })
end

-- Alternate routes for 50-60. Each one is a self-contained hub you can do instead of (or before)
-- the main chapter that visits the same zone; steps are copies of that chapter's steps.
do
  local alt = { alternate = true, manual = true }
  local function with(extra, suggest)
    local result = { suggest = suggest }
    for key, value in pairs(extra) do result[key] = value end
    return result
  end

  chapter("azshara-alt", "Azshara: Loh'atu and Kim'jael", M.azshara, 50, 54, {
    "https://www.wowhead.com/forever/zone=16/azshara",
  }, join({
    taxi("fly", at("Daelyshia", 34.4, 48.0, M.ashenvale), TALRENDIS,
      "Fly to Talrendis Point, or ride east from Astranaar along the road into Azshara."),
  }, from("felwood-52", { 5535, 5536 }), from("azshara-53", { 3601, 5534 }), {
    action("grind", on.azshara(nil, 56.6, 28.4), "The naga and satyrs here are good experience until 54.", { level = 54 }),
  }), with(alt, { "ungoro-53", "searing-alt" }))

  chapter("searing-alt", "Searing Gorge and Burning Steppes: Thorium Point to Morgan's Vigil", M.searing, 50, 56, {
    "https://www.wowhead.com/forever/zone=51/searing-gorge",
    "https://www.wowhead.com/forever/zone=46/burning-steppes",
  }, join({
    taxi("fly", at("Gryth Thurden", 55.5, 47.7, M.ironforge), THORIUM, "Fly to Thorium Point from Ironforge."),
  }, from("searing-50", { 7722, 7723, 7724, 7727, 7728, 7729, 7701, 3441, 3442, 3443, 3452, 3453, 3454, 3462, 3463, 3481,
    4451, 4449 }), {
    taxi("fly", on.searing("Lanie Reed", 37.9, 30.9), MORGANS, "Fly to Morgan's Vigil. Without that flight path, fly to Lakeshire and ride north."),
  }, from("blasted-51", { 3823 }, "accept"), from("steppes-56", { 4283, 4182, 4726, 4296, 4022 }, "accept"),
    from("blasted-51", { 3823 }, "rest"), from("steppes-56", { 4283, 4182, 4726, 4296, 4022 }, "rest")),
    with(alt, { "steppes-56", "winterspring-alt", "silithus-alt" }))

  chapter("winterspring-alt", "Winterspring: Everlook and the Winterfall", M.winterspring, 55, 60, {
    "https://www.wowhead.com/forever/zone=618/winterspring",
  }, join({
    taxi("fly", at("Mishellena", 62.5, 24.2, M.felwood), EVERLOOK,
      "Fly to Everlook. Without that flight path, ride through Timbermaw Hold from northern Felwood."),
  }, from("felwood-52", { 6603 }), from("silithus-59", { 3783 }, "accept"),
    from("winterspring-54", { 6603, 5082, 5083, 5084, 5085, 5086, 5087, 4861 }),
    from("winterspring-55", { 5087, 4861, 4863, 4864, 969 }), {
      accept(5121, on.winterspring("Donova Snowden", 31.27, 45.16), "Donova wants High Chief Winterfall dead. Bring a friend for his cave."),
      objective(5121, on.winterspring("High Chief Winterfall", 69.6, 38.3), "Fight into Winterfall Village, north-east of Everlook. High Chief Winterfall waits in the back cave.",
        "High Chief Winterfall"),
      withItem(12842, accept(5123, on.winterspring(nil, 69.8, 38.2), "The High Chief drops a Crudely-written Log. Use it from your bags.")),
      finish(5121, on.winterspring("Donova Snowden", 31.27, 45.16), "Ride back west to Donova."),
      finish(5123, on.winterspring("Donova Snowden", 31.27, 45.16)),
    }, from("silithus-59", { 3783 }, "rest"), from("silithus-59", { 977 })),
    with(alt, { "silithus-alt", "silithus-60" }))

  chapter("silithus-alt", "Silithus: Cenarion Hold", M.silithus, 55, 60, {
    "https://www.wowhead.com/forever/zone=1377/silithus",
  }, join({
    taxi("fly", on.tanaris("Bera Stonehammer", 51.0, 29.3), CENARION,
      "Fly to Cenarion Hold. Without that flight path, fly to Marshal's Refuge and take Un'Goro's north-west ramp into Silithus."),
  }, from("silithus-59", { 8307, 8313, 8277, 8278, 8280, 8281, 8284, 8285, 8279, 8287, 8323, 8304, 8308 })),
    with(alt, { "winterspring-alt", "silithus-60" }))

  -- Where each main chapter offers to branch off.
  local suggests = {
    ["stv-50"] = { "searing-alt", "azshara-alt" }, ["searing-50"] = { "azshara-alt" },
    ["blasted-51"] = { "searing-alt", "azshara-alt" }, ["wpl-51"] = { "searing-alt", "azshara-alt" },
    ["felwood-52"] = { "azshara-alt", "searing-alt" }, ["feralas-52"] = { "azshara-alt", "searing-alt" },
    ["azshara-53"] = { "searing-alt" }, ["ungoro-53"] = { "searing-alt", "winterspring-alt" },
    ["winterspring-54"] = { "searing-alt", "winterspring-alt" }, ["winterspring-55"] = { "silithus-alt", "searing-alt" },
    ["steppes-56"] = { "silithus-alt", "winterspring-alt" }, ["plaguelands-57"] = { "silithus-alt", "winterspring-alt" },
    ["plaguelands-58"] = { "silithus-alt", "winterspring-alt" }, ["silithus-59"] = { "winterspring-alt" },
    ["silithus-60"] = { "winterspring-alt", "silithus-alt" },
  }
  for id, list in pairs(suggests) do byId[id].extra.suggest = list end
end

-- Every chapter above is added here, in order.
build()
