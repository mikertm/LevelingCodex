-- Alliance dungeon detours for levels 30-60. Source notes: tools/audits/2026-11-10-dungeons-30-60.md.
-- Outdoor pickups are tagged on the leveling route (forDungeon) where the route passes their givers;
-- each guide repeats them, with any prerequisite chain, so it can be played on its own.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local M, on = B.maps, B.on
local at, q, accept, finish, action = B.at, B.q, B.accept, B.finish, B.action
local objective, part, withItem, uncertain = B.objectiveAt, B.objectivePart, B.withItem, B.note
local qdb = "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever"

local function add(section, prepare, inside, after)
  section.side, section.category, section.verified = true, "dungeon", false
  section.steps = {}
  for _, group in ipairs({ { "prepare", prepare }, { "inside", inside }, { "after", after } }) do
    for _, step in ipairs(group[2] or {}) do
      step.phase = group[1]
      section.steps[#section.steps + 1] = step
    end
  end
  route.sections[#route.sections + 1] = section
  return section
end

local function tip(name, text)
  return action("note", nil, text, { name = name })
end

local function enter(name, place, text)
  return action("dungeon", place, text, { name = name })
end

-- A quest only the guides use; the route's own registration wins when it has one.
local function need(id, name, level, min, pre, forever)
  if not B.quest[id] then q(id, name, level, min, pre, forever) end
end

local function fromItem(id, item, name, level, min, pre, forever)
  need(id, name, level, min, pre, forever)
  B.quest[id].startItem = item
end

-- Copies of route steps (same quest IDs and metadata) for a guide's lead-in chain, in route order.
local function copy(sectionId, ids)
  local wanted = {}
  for _, id in ipairs(ids) do wanted[id] = true end
  for _, section in ipairs(route.sections) do
    if section.id == sectionId then
      local out = {}
      for _, step in ipairs(section.steps) do
        if step.quest and wanted[step.quest] then
          local c = {}
          for key, value in pairs(step) do c[key] = value end
          c.optional, c.dungeon, c.also, c.phase = nil, nil, nil, nil
          out[#out + 1] = c
        end
      end
      return out
    end
  end
  error("dungeon prep section missing: " .. sectionId)
end

local function join(...)
  local out = {}
  for _, list in ipairs({ ... }) do
    for _, step in ipairs(list) do out[#out + 1] = step end
  end
  return out
end

-- Put steps right after the first step of a kind for a quest.
local function insertAfter(list, quest, kind, steps)
  for i, step in ipairs(list) do
    if step.quest == quest and step.type == kind then
      for j, extra in ipairs(steps) do table.insert(list, i + j, extra) end
      return list
    end
  end
  error("dungeon prep step missing: " .. kind .. " " .. quest)
end

B.dungeon = { add = add, tip = tip, enter = enter, copy = copy }

local sm = "Scarlet Monastery"
local smDoor = at("Scarlet Monastery approach", 82.65, 32.88, M.tirisfal)
local smApproach = tip("Alliance approach", "Fly to Southshore, ride north through Hillsbrad and Silverpine and keep east of Brill. "
  .. "The monastery stands in the far north-east of Tirisfal. Expect Forsaken patrols on the way.")
local brm = at("Blackrock Mountain", 34.8, 85.3, M.searing)
local dmDoor = at("Dire Maul", 59.0, 44.8, M.feralas)

-- Scarlet Monastery: Library. Mae Paledust's book and Forever's Past Due.
do
  local name = "Scarlet Monastery: Library"
  local mae = on.ironforge("Librarian Mae Paledust", 74.97, 12.48)
  local olvek = on.alterac("Magus Olvek", 9.75, 63.36)
  need(1050, "Mythology of the Titans", 38, 28)
  need(96800, "Past Due", 38, nil, nil, true)
  add({ id = "dungeon-scarlet-monastery-library", title = name, zone = M.tirisfal, levels = { 33, 40 },
    instanceID = 189, instance = sm,
    links = { "dungeon-scarlet-monastery-graveyard", "dungeon-scarlet-monastery-armory", "dungeon-scarlet-monastery-cathedral" },
    bosses = {
      { name = "Houndmaster Loksey", npc = 3974,
        tip = "He waits with three hounds and sends them in at the start. Kill the dogs first, then tank him away from the next pack; he Bloodlusts, so save a stun for it." },
      { name = "Arcanist Doan", npc = 6487,
        tip = "Clear the last hall first. When he shields himself and starts Detonation, everyone runs out of range; he also Polymorphs and Silences, so spread out." },
    },
    sources = { "https://www.wowhead.com/forever/zone=796", "https://www.wowhead.com/forever/quest=96800", qdb } }, {
    accept(1050, mae, "Librarian Mae Paledust waits in the Hall of Explorers."),
    uncertain(accept(96800, olvek, "Magus Olvek wants an overdue book back from the monastery. He stands near the Dalaran crater in the Alterac Mountains."),
      "Forever quest with no published hand-in; Olvek is assumed to take it back."),
    smApproach,
    enter(name, smDoor, "Climb the monastery stairs together. In the entry hall the Library wing is the second door."),
  }, {
    objective(1050, nil, "Clear the hall past Houndmaster Loksey. The book lies on the floor of the library's long gallery.", "Mythology of the Titans"),
    uncertain(objective(96800, nil, "Search the library shelves for The Lost Magic of the Runemasters as you clear toward Doan.",
      "The Lost Magic of the Runemasters"), "Book location not published; check the shelves near Doan."),
    tip("In the Name of the Light", "Houndmaster Loksey counts for Raleigh's quest. Open the Cathedral guide if you carry it."),
  }, {
    finish(1050, mae),
    uncertain(finish(96800, olvek, "Bring the book back to Magus Olvek."), "Hand-in NPC assumed from the giver."),
  })
end

-- Scarlet Monastery: Armory. No Alliance quest of its own; Herod counts for In the Name of the Light.
do
  local name = "Scarlet Monastery: Armory"
  add({ id = "dungeon-scarlet-monastery-armory", title = name, zone = M.tirisfal, levels = { 35, 42 },
    instanceID = 189, instance = sm,
    links = { "dungeon-scarlet-monastery-cathedral", "dungeon-scarlet-monastery-library" },
    bosses = {
      { name = "Herod", npc = 3975,
        tip = "Clear the training hall and his room first. During Whirlwind the melee step back and the tank kites him; at low health he enrages, and a wave of trainees runs in after he dies, so stay ready." },
    },
    sources = { "https://www.wowhead.com/forever/zone=796", qdb } }, {
    smApproach,
    enter(name, smDoor, "In the monastery's entry hall the Armory is the third door. Regroup at the portal."),
  }, {
    tip("Armory run", "Clear the stables and the training yard, then the hall of arms. Herod waits at the end; plan where the group stands for the trainee wave after he dies."),
    tip("In the Name of the Light", "Herod counts for Raleigh's quest. Open the Cathedral guide if you carry it."),
  })
end

-- Scarlet Monastery: Cathedral. Brother Anton's chain from Desolace ends at Raleigh in Southshore.
do
  local name = "Scarlet Monastery: Cathedral"
  local raleigh = on.hillsbrad("Raleigh the Devout", 51.47, 58.35)
  need(1053, "In the Name of the Light", 40, 34, 1052)
  local prep = join(copy("desolace-35", { 261, 1052 }), {
    finish(1052, raleigh, "Bring Anton's letter to Raleigh the Devout by the Southshore inn."),
    accept(1053, raleigh, "Raleigh wants the four Scarlet leaders dead. The quest covers three wings."),
    smApproach,
    enter(name, smDoor, "The Cathedral is the last door in the entry hall. Loksey and Herod are in the Library and Armory wings."),
  })
  add({ id = "dungeon-scarlet-monastery-cathedral", title = name, zone = M.tirisfal, levels = { 37, 44 },
    instanceID = 189, instance = sm,
    links = { "dungeon-scarlet-monastery-library", "dungeon-scarlet-monastery-armory", "dungeon-scarlet-monastery-graveyard" },
    bosses = {
      { name = "High Inquisitor Fairbanks", npc = 4542,
        tip = "Optional, behind the side door in the courtyard. He is weak but heals himself; interrupt and burn him." },
      { name = "Scarlet Commander Mograine", npc = 3976,
        tip = "Clear every pack in the cathedral first. Ranged and healers stay back; his hammer stun and shield are aimed at the tank." },
      { name = "High Inquisitor Whitemane", npc = 3977,
        tip = "She joins when Mograine falls, sleeps the group and raises him. Have someone free to wake the healer, then kill Mograine again and burn her." },
    },
    sources = { "https://www.wowhead.com/forever/zone=796", qdb } }, prep, {
    part(1053, 4, nil, "Library wing: kill Houndmaster Loksey at the start of the halls.", "Houndmaster Loksey"),
    part(1053, 3, nil, "Armory wing: kill Herod at the end of the hall of arms.", "Herod"),
    part(1053, 2, nil, "Cathedral wing: cross the courtyard, clear the nave and pull Mograine.", "Scarlet Commander Mograine"),
    part(1053, 1, nil, "Whitemane comes when Mograine dies. Kill her and Mograine together.", "High Inquisitor Whitemane"),
  }, {
    finish(1053, raleigh),
  })
end

-- Razorfen Downs. Benedictus's quest and Belnistrasz's escort.
do
  local name = "Razorfen Downs"
  need(3523, "Scourge of the Downs", 37, 32)
  need(3525, "Extinguishing the Idol", 37, 32, 3523)
  local prep = join(copy("dustwallow-40", { 3636, 6626 }), {
    enter(name, at("Razorfen Downs entrance", 49.3, 93.1, M.barrens),
      "Myriam waits outside the thorn path. Follow it up to the portal at the top of the mound."),
  })
  add({ id = "dungeon-razorfen-downs", title = name, zone = M.barrens, levels = { 35, 42 }, instanceID = 129, instance = name,
    links = { "dungeon-razorfen-kraul" },
    bosses = {
      { name = "Tuten'kash", npc = 7355,
        tip = "Ringing the gong calls spider waves and then Tuten'kash. His poison and web stack on the tank, so cleanse it and save a cooldown for the end." },
      { name = "Plaguemaw the Rotting", npc = 7356,
        tip = "A plain fight. Cure his disease on the tank and keep him away from the next pack." },
      { name = "Mordresh Fire Eye", npc = 7357,
        tip = "He casts Fireball and Fire Nova; interrupt the fireballs and melee watch their health." },
      { name = "Glutton", npc = 8567,
        tip = "He enrages and grows stronger the longer you take, so use cooldowns from the start. His Disease Cloud hurts melee." },
      { name = "Ragglesnout (rare, may be absent)", npc = 7354,
        tip = "Interrupt his Shadow Word: Pain and heals. Otherwise easy." },
      { name = "Amnennar the Coldbringer", npc = 7358,
        tip = "Frost Nova roots the group and he calls frost adds twice. Kill the adds fast and keep the healer out of melee." },
    },
    sources = { "https://www.wowhead.com/forever/zone=722", qdb } }, prep, {
    accept(3523, nil, "Speak to Belnistrasz in the first room and agree to help him."),
    finish(3523, nil, "Give the Oathstone back to Belnistrasz."),
    accept(3525, nil, "Clear the idol room first, then start Belnistrasz's ritual."),
    objective(3525, nil, "Protect Belnistrasz from the waves until the ritual ends. Pull adds off him at once.", "Idol extinguished"),
    finish(3525, nil, "Open the brazier he leaves behind for your reward."),
    objective(3636, nil, "Follow the paths to the top of the downs and kill Amnennar the Coldbringer.", "Amnennar the Coldbringer"),
  }, {
    finish(3636, on.stormwind("Archbishop Benedictus", 50.31, 45.47), "Archbishop Benedictus stands in the Cathedral of Light."),
  })
end

-- Uldaman. Ironforge, Thelsamar and the Badlands camps feed it; most hand-ins are in Ironforge.
do
  local name = "Uldaman"
  local ifg, bl, lm = on.ironforge, on.badlands, on.lochModan
  local stormpike = ifg("Prospector Stormpike", 74.64, 11.74)
  local krom = ifg("Krom Stoutarm", 74.2, 9.4)
  local karnik = ifg("Historian Karnik", 77.54, 11.82)
  local belgrum = ifg("Advisor Belgrum", 77.34, 9.71)
  local magellas = ifg("High Explorer Magellas", 69.93, 18.55)
  local dinita = ifg("Dinita Stonemantle", 33.88, 59.15)
  local talvash = ifg("Talvash del Kissel", 36.38, 3.61)
  local ryedol = bl("Prospector Ryedol", 53.42, 43.39)
  local theldurin = bl("Theldurin the Lost", 51.39, 76.87)
  local ghak = lm("Ghak Healtouch", 37.07, 49.38)
  local ironband = lm("Prospector Ironband", 65.93, 65.62)
  need(2398, "The Lost Dwarves", 40, 35)
  need(2240, "The Hidden Chamber", 40, 35, 2398)
  need(1360, "Reclaimed Treasures", 43, 33)
  need(721, "A Sign of Hope", 35, 35, 720)
  need(722, "Amulet of Secrets", 40, 35, 721)
  need(723, "Prospect of Faith", 40, 35, 722)
  need(724, "Prospect of Faith", 40, 35, 723)
  need(725, "Passing Word of a Threat", 40, 35, 724)
  need(726, "Passing Word of a Threat", 40, 35, 725)
  need(709, "Solution to Doom", 40, 30)
  need(17, "Uldaman Reagent Run", 42, 36, 2500)
  need(704, "Agmond's Fate", 38, 30, 739)
  fromItem(2198, 7666, "The Shattered Necklace", 41, 37)
  need(2199, "Lore for a Price", 41, 37, 2198)
  need(2278, "The Platinum Discs", 47, 40)
  need(2279, "The Platinum Discs", 47, 40, 2278)
  need(2439, "The Platinum Discs", 47, 40, 2279)
  local prep = join({
    accept(2398, stormpike, "Prospector Stormpike in the Hall of Explorers has lost a dig team in Uldaman."),
    accept(1360, krom, "Krom Stoutarm, beside him, left a treasure chest in Uldaman."),
  }, copy("badlands-41", { 707, 738, 739, 2500, 720 }))
  insertAfter(prep, 720, "turnin", { accept(721, ryedol, "Ryedol sends you to find Hammertoe Grez in Uldaman.") })
  insertAfter(prep, 739, "complete", { accept(709, theldurin, "Ride south to Theldurin's camp; he wants a tablet from Uldaman.") })
  insertAfter(prep, 2500, "turnin", { accept(17, ghak, "Ghak now wants fungus caps from Uldaman.") })
  insertAfter(prep, 739, "turnin", {
    accept(704, ironband, "Ironband wants Agmond's urns from Uldaman."),
    enter(name, at("Uldaman entrance", 42.4, 12.9, M.badlands),
      "Ride south into the Badlands. The excavation in the north cliffs leads to the outer caves; the portal is at the back."),
  })
  add({ id = "dungeon-uldaman", title = name, zone = M.badlands, levels = { 38, 47 }, instanceID = 70, instance = name,
    bosses = {
      { name = "Revelosh", npc = 6910,
        tip = "Kill his trogg guards first and interrupt his Chain Lightning. He drops the Shaft of Tsol for the Hidden Chamber." },
      { name = "The Lost Dwarves (Baelog, Eric and Olaf)", npc = 6906,
        tip = "Three dwarves at once: crowd control or kill Eric first, keep Olaf faced away and stop Baelog's arrows with line of sight." },
      { name = "Ironaya", npc = 7228,
        tip = "Her Arcing Smash hits everyone in front, so face her away. She knocks the tank up and stomps; stay spread." },
      { name = "Obsidian Sentinel", npc = 7023,
        tip = "It splits off shards as its health drops. Kill the shards quickly or the sentinel heals." },
      { name = "Ancient Stone Keeper", npc = 7206,
        tip = "Tank it away from the group; it pulses damage around itself. Burn it before the sand pools add up." },
      { name = "Galgann Firehammer", npc = 7291,
        tip = "Interrupt his Fire Nova and Flame Lash. Melee step out when he starts casting." },
      { name = "Grimlok", npc = 4854,
        tip = "Kill his basilisks first. He shrinks and Lightning Bolts the group; interrupt where you can." },
      { name = "Archaedas", npc = 2748,
        tip = "Clear the room edges, then wake him at the altar. He wakes dwarf guardians and later stone watchers; the tank holds him while others kill the adds." },
    },
    sources = { "https://www.wowhead.com/forever/zone=1337", qdb } }, prep, {
    finish(721, nil, "Find Hammertoe Grez in the outer caves before the portal."),
    accept(722, nil, "Hammertoe wants his amulet back from Magregan Deepshadow."),
    objective(722, nil, "Kill Magregan Deepshadow in the Shadowforge camp of the outer caves and take the amulet.", "Hammertoe's Amulet"),
    finish(722, nil, "Give Hammertoe his amulet."),
    accept(723, nil, "Take the amulet for Ryedol."),
    objective(709, nil, "The Tablet of Ryun'eh sits in a chest in the outer caves near Magregan.", "Tablet of Ryun'eh"),
    objective(704, nil, "Open Agmond's urns in the outer caves and inside the instance.", "4 Carved Stone Urns"),
    objective(17, nil, "Pick Magenta Fungus Caps from the mushrooms in both parts of Uldaman.", "12 Magenta Fungus Caps"),
    finish(2398, nil, "Baelog's dwarves wait in the first chamber inside. Speak to Baelog after the fight with the troggs."),
    accept(2240, nil, "Read Baelog's journal and take his Hidden Chamber task."),
    objective(2240, nil, "Combine the Shaft of Tsol from Revelosh and the Gni'kiv Medallion from Baelog's chest, then use the staff in the map room.",
      "Hidden Chamber explored"),
    objective(1360, nil, "Krom's chest is in the North Common Hall, past Ironaya.", "Krom Stoutarm's Treasure"),
    withItem(7666, accept(2198, nil, "If a Shattered Necklace drops, use it.")),
    accept(2278, nil, "After Archaedas, speak to the stone watcher and use the Discs of Norgannon."),
    finish(2278, nil, "Activate the Discs of Norgannon."),
    accept(2279, nil, "Take the miniature discs for the Explorers' League."),
  }, {
    finish(723, ryedol, "Ride to Ryedol's camp in the Badlands."), accept(724, ryedol),
    finish(709, theldurin),
    finish(704, ironband), finish(17, ghak),
    finish(724, karnik, "Historian Karnik is in the Hall of Explorers."), accept(725, karnik),
    finish(725, belgrum), accept(726, belgrum), finish(726, karnik),
    finish(2240, stormpike), finish(1360, krom),
    finish(2279, magellas), accept(2439, magellas), finish(2439, dinita, "Dinita Stonemantle works in the Vault of Ironforge."),
    finish(2198, talvash, "Talvash del Kissel is in the Mystic Ward."),
    accept(2199, talvash, "His next step wants five Silver Bars and a later visit back to Uldaman."),
  })
end

-- Krol'dok Stronghold, Forever's Riverglades dungeon. Pickups at Farholde Keep and Twilight's Shroud.
do
  local name = "Krol'dok Stronghold"
  local rg = on.riverglades
  local brant = rg("Demar Brant", 66.6, 81.0)
  local ashe = rg("Ashe Amberhall", 66.6, 81.0)
  local riftan = rg("Sergeant Riftan", 30.6, 49.0)
  local dumas = rg("Alphonse Dumas", 64.4, 82.0)
  local sable = rg("Melanie Sable", 66.2, 83.2)
  fromItem(94980, 267138, "Krol'dok Moulding", 44, 40, nil, true)
  need(94981, "Key Ingredients", 44, 40, 94980, true)
  need(94997, "Lingering Essence", 44, 38, 94983, true)
  need(94998, "Curios of Curiosity", 44, 38, 94997, true)
  fromItem(94926, 266889, "Drop the Hammer", 44, 40, nil, true)
  local prep = copy("riverglades-shroud", { 94886, 94907 })
  insertAfter(prep, 94886, "accept", { accept(94982, brant, "Brant wants the Eye of Mugg from the stronghold's overlord.") })
  insertAfter(prep, 94886, "turnin", { accept(94983, riftan, "Riftan wants bangles from the Twilight's Hammer inside Krol'dok.") })
  insertAfter(prep, 94907, "turnin", {
    accept(94984, ashe, "Ashe's next task is the Tome of Twilight from Nar'gurk."),
    uncertain(enter(name, rg("Krol'dok Stronghold entrance", 37.5, 37.3),
      "Ride north past Sunnyglade to the ogre fortress on the hill. The gates stay shut; the portal is in a small cave just west of them. A meeting stone stands at about 39, 39."),
      "Entrance from published guides (37.5, 37.3); check it in game."),
  })
  add({ id = "dungeon-krol-dok-stronghold", title = name, zone = M.riverglades, levels = { 40, 45 }, instanceID = 3039, instance = name,
    bosses = {
      { name = "Slavecrusher Grox", encounter = 3450,
        tip = "Several ogre packs and a long patrol come first; let the patrol pass before you pull him. Tank him away from the slave pens." },
      { name = "Twilight Commander Zarmok", encounter = 3452,
        tip = "He leaves a heavy bleed on the tank, so healers keep the tank topped up. His death opens the big gate behind him." },
      { name = "Handler Ashka", encounter = 3453,
        tip = "She fights with two wolves. Kill or crowd control the wolves first; she may stand off the main road." },
      { name = "Nar'gurk", encounter = 3449,
        tip = "He takes control of a player. Fight near cover, keep a crowd control ready for the charmed player and do not kill them." },
      { name = "Bossman Toof",
        tip = "Waits past the bridge. Not part of the game's boss list, but he hits hard; pull him without the nearby ogres." },
      { name = "Overseer Mugg", encounter = 3451,
        tip = "The last boss at the top of the hill. Spread out because he leaps around the room, and kill his adds first: they cut the healing on the tank." },
    },
    sources = { "https://conquestcapped.com/guides/wow-forever/wow-forever-kroldok-stronghold-guide/",
      "https://www.warcrafttavern.com/forever/guides/kroldok-stronghold/", qdb } }, prep, {
    objective(94983, nil, "Loot Twilight Bangles from the Twilight's Hammer cultists inside.", "8 Twilight Bangles"),
    objective(94984, nil, "Kill Nar'gurk and loot the Tome of Twilight.", "Tome of Twilight"),
    objective(94982, nil, "Climb to the top of the hill and kill Overlord Mugg for his eye.", "Eye of Mugg"),
    uncertain(withItem(267138, accept(94980, nil, "If a Krol'dok Moulding drops for you, use it.")),
      "The moulding is party loot; which mob drops it is not published."),
    uncertain(withItem(266889, accept(94926, nil, "If Komuk's Warmaul drops, use it to start Drop the Hammer.")),
      "Quest giver item found in the client data; drop source and hand-in not published."),
  }, {
    finish(94983, riftan, "Riftan waits at the edge of the Twilight's Shroud."),
    uncertain(accept(94997, riftan, "Take the satchel of mementos back to Ashe."), "Giver of the follow-up not confirmed."),
    finish(94984, ashe), uncertain(finish(94997, ashe), "Follow-up chain from published notes; check in game."),
    uncertain(accept(94998, ashe), "Follow-up chain from published notes; check in game."),
    uncertain(finish(94998, sable, "Melanie Sable, the enchanter at Farholde Keep, studies the curios."), "Hand-in from published notes."),
    finish(94982, brant),
    uncertain(finish(94980, dumas, "Alphonse Dumas at Farholde Keep can cast the moulding into a key."), "Hand-in from published notes."),
    uncertain(accept(94981, dumas, "He needs 4 Thick Leather and 12 Iron Bars for the Krol'dok Compound Key."), "Quest name and giver from published notes."),
    uncertain(finish(94981, dumas), "Quest name and giver from published notes."),
    uncertain(finish(94926, nil, "Hand in Drop the Hammer where the quest log points."), "Hand-in not published."),
  })
end

-- Zul'Farrak. The Hinterlands chain to Thadius Grimshade, Gadgetzan's errands and the Mosh'aru tablets.
do
  local name = "Zul'Farrak"
  local ta = on.tanaris
  local talonaxe = on.hinterlands("Gryphon Master Talonaxe", 9.75, 44.47)
  local thadius = on.blasted("Thadius Grimshade", 66.9, 19.47)
  local tranrek = ta("Tran'rek", 51.57, 26.76)
  local bilgewhizzle = ta("Chief Engineer Bilgewhizzle", 52.46, 28.51)
  local trenton = ta("Trenton Lighthammer", 51.41, 28.75)
  local yehkinya = ta("Yeh'kinya", 66.99, 22.36)
  local wizzle = on.needles("Wizzle Brassbolts", 78.14, 77.12)
  local tabetha = on.dustwallow("Tabetha", 46.06, 57.09)
  need(2990, "Thadius Grimshade", 47, 40, 2989)
  need(2991, "Nekrum's Medallion", 47, 40, 2990)
  need(2992, "The Divination", 47, 40, 2991)
  need(2865, "Scarab Shells", 45, 40, 2864)
  need(2768, "Divino-matic Rod", 47, 40)
  need(3042, "Troll Temper", 45, 40)
  need(3527, "The Prophecy of Mosh'aru", 47, 40, 3520)
  need(2770, "Gahz'rilla", 50, 40)
  need(2846, "Tiara of the Deep", 46, 40)
  local prep = join(copy("stv-41", { 2864 }), copy("hinterlands-48", { 2988, 2989 }), {
    accept(2990, talonaxe, "Missable: Talonaxe offers Sharpbeak's feather only right after The Altar of Zul. Take it before leaving."),
    finish(2990, thadius, "Thadius Grimshade is in the Nethergarde Keep tower in the Blasted Lands."),
    accept(2991, thadius, "Thadius wants Nekrum's Medallion from Zul'Farrak."),
    accept(2846, tabetha, "Tabetha, in the Dustwallow marsh hut south-west of Theramore, wants the Tiara of the Deep."),
    accept(2770, wizzle, "Wizzle Brassbolts at the Shimmering Flats wants Gahz'rilla's scale."),
  }, copy("tanaris-43", { 2864, 3520 }), {
    accept(2865, tranrek, "Tran'rek, by the Gadgetzan bank, wants scarab shells."),
    accept(2768, bilgewhizzle, "Bilgewhizzle, by the water tower, lost a Divino-matic Rod in the city."),
    accept(3042, trenton, "Trenton Lighthammer, the Gadgetzan blacksmith, wants troll temper."),
  }, copy("feralas-44", { 3520 }), copy("ungoro-49", { 3520 }), {
    accept(3527, yehkinya, "After Screecher Spirits, Yeh'kinya wants the first two Mosh'aru tablets."),
    enter(name, at("Zul'Farrak entrance", 38.7, 19.8, M.tanaris),
      "Ride west from Gadgetzan into the Zul'Farrak dunes. The portal is in the city's outer wall."),
  })
  add({ id = "dungeon-zul-farrak", title = name, zone = M.tanaris, levels = { 42, 48 }, instanceID = 209, instance = name,
    links = { "dungeon-sunken-temple" },
    bosses = {
      { name = "Antu'sul", npc = 8127,
        tip = "Clear the basilisk pit first. He calls basilisks and heals at low health; kill the adds and interrupt the heal." },
      { name = "Theka the Martyr", npc = 7272,
        tip = "He turns into a scarab and becomes immune to physical damage; casters finish him. Loot the first Mosh'aru tablet." },
      { name = "Witch Doctor Zum'rah", npc = 7271,
        tip = "Entering the graveyard wakes zombies. Kill his ward totem and interrupt his Shadow Bolt Volley." },
      { name = "Nekrum and Sezz'ziz (pyramid event)", npc = 7796,
        tip = "Free Sergeant Bly's group, then hold the stairs against the waves. Nekrum and Sezz'ziz come last; kill Sezz'ziz's heals first. Bly turns on you afterwards." },
      { name = "Hydromancer Velratha", npc = 7795,
        tip = "In the pool area west of the pyramid. Interrupt her heals and frost bolts; loot the Tiara and the second tablet." },
      { name = "Gahz'rilla (summoned)", npc = 7273,
        tip = "Rung up at the pool with the Mallet of Zul'Farrak. Her Freeze and Icicle hit hard; spread out and keep the healer back." },
      { name = "Chief Ukorz Sandscalp and Ruuzlu", npc = 7267,
        tip = "Last at the top of the steps. Kill Ruuzlu or crowd control him; Ukorz enrages and cleaves, so face him away." },
    },
    sources = { "https://www.wowhead.com/forever/zone=1176", qdb } }, prep, {
    objective(3042, nil, "Loot Troll Temper from the Sandfury trolls as you clear.", "20 Vials of Troll Temper"),
    objective(2865, nil, "Open the scarab-filled sand mounds and kill the scarabs for shells.", "5 Uncracked Scarab Shells"),
    objective(3527, nil, "Loot one tablet from Theka the Martyr and the other from Hydromancer Velratha.", "First Mosh'aru Tablet", "Second Mosh'aru Tablet"),
    objective(2846, nil, "Velratha carries the Tiara of the Deep.", "Tiara of the Deep"),
    objective(2768, nil, "After the pyramid event, kill Sergeant Bly and loot the Divino-matic Rod.", "Divino-matic Rod"),
    objective(2991, nil, "Nekrum Gutchewer drops his medallion at the end of the pyramid event.", "Nekrum's Medallion"),
    uncertain(objective(2770, nil, "Ring the gong at Velratha's pool with the Mallet of Zul'Farrak and kill Gahz'rilla.", "Gahz'rilla's Electrified Scale"),
      "The Mallet comes from a separate Hinterlands quest; skip this one without it."),
  }, {
    finish(3042, trenton), finish(2768, bilgewhizzle), finish(2865, tranrek), finish(3527, yehkinya),
    finish(2770, wizzle), finish(2846, tabetha),
    finish(2991, thadius, "Take the medallion back to Thadius in Nethergarde Keep."),
    accept(2992, thadius), objective(2992, thadius, "Wait while Thadius performs the divination.", "The Divination"), finish(2992, thadius),
  })
end

-- Maraudon. Theramore and Desolace pickups; Theradras's Seed of Life ends in Moonglade.
do
  local name = "Maraudon"
  local ds = on.desolace
  local tervosh = on.dustwallow("Archmage Tervosh", 66.42, 49.26)
  local marandis = ds("Keeper Marandis", 63.83, 10.67)
  local talendria = ds("Talendria", 68.5, 8.88)
  local willow = ds("Willow", 62.2, 39.63)
  local pariah = ds("Centaur Pariah", 50.42, 86.65)
  local cavindra = ds("Cavindra", 32.1, 63.96)
  need(7070, "Shadowshard Fragments", 42, 38)
  need(7065, "Corruption of Earth and Seed", 51, 45)
  need(7041, "Vyletongue Corruption", 47, 41)
  need(7028, "Twisted Evils", 47, 41)
  need(7067, "The Pariah's Instructions", 48, 39)
  need(7044, "Legends of Maraudon", 49, 41)
  need(7046, "The Scepter of Celebras", 49, 41, 7044)
  need(7066, "Seed of Life", 51, 45)
  add({ id = "dungeon-maraudon", title = name, zone = M.desolace, levels = { 44, 52 }, instanceID = 349, instance = name,
    bosses = {
      { name = "Noxxion", npc = 13282,
        tip = "Orange side. He splits into small spawns and becomes immune; kill the spawns with area damage. Drops the Celebrian Rod." },
      { name = "Razorlash", npc = 12258,
        tip = "Orange side, patrols. Face his cleave away from the group." },
      { name = "Lord Vyletongue", npc = 12236,
        tip = "Purple side. Kill his satyr guards, then chase him when he blinks. Drops the Celebrian Diamond." },
      { name = "Celebras the Cursed", npc = 12225,
        tip = "Clear the grove around him. He roots and calls a corrupted forest spirit; kill the add and avoid his Wrath. Speak to his redeemed spirit after." },
      { name = "Landslide", npc = 12203,
        tip = "Tank him in place: his knockback throws the tank, and he calls rock adds at low health." },
      { name = "Tinkerer Gizlock", npc = 13601,
        tip = "Clear the goblins first. He shoots bombs and his Goblin Dragon Gun burns melee; stay at his side." },
      { name = "Rotgrip", npc = 13596,
        tip = "A crocolisk in the water. Her bite poisons the tank; cleanse it and kill her quickly." },
      { name = "Princess Theradras", npc = 12201,
        tip = "Her dust field and knockback break the group apart. Tank her with your back to a wall and spread ranged. Her death frees Zaetar's spirit." },
    },
    sources = { "https://www.wowhead.com/forever/zone=2100", qdb } }, {
    accept(7070, tervosh, "Archmage Tervosh in Theramore's tower wants shadowshard fragments."),
    accept(7065, marandis, "Keeper Marandis at Nijel's Point wants Princess Theradras slain."),
    accept(7041, talendria, "Talendria, also at Nijel's Point, gives you a vial for the Vylestem vines."),
    accept(7028, willow, "Willow camps in the middle of Desolace. She wants crystal carvings from the constructs."),
    accept(7067, pariah, "Missable: the Centaur Pariah wanders south of the Kolkar camps. Read his instructions; the quest cannot be started inside."),
    accept(7044, cavindra, "Cavindra waits in the outer cave by the purple and orange paths."),
    enter(name, at("Maraudon outer cave", 29.1, 62.6, M.desolace),
      "Enter the cave in the Valley of Spears. Purple (left) leads to Vyletongue, orange (right) to Noxxion; both join the inner falls."),
  }, {
    objective(7070, nil, "Shadowshard smashers and rumblers on both outer sides drop the fragments.", "10 Shadowshard Fragments"),
    objective(7067, nil, "Kill the Kolkar khan spirits along the outer paths and loot their amulet pieces, then combine them.", "Amulet of Union"),
    withItem(17693, objective(7041, nil, "Fill the vial at the orange crystal pool, then use it on the Vylestem vines and kill the scions that emerge.",
      "8 plants healed")),
    objective(7044, nil, "Take the Celebrian Rod from Noxxion and the Celebrian Diamond from Lord Vyletongue.", "Celebrian Rod", "Celebrian Diamond"),
    finish(7044, nil, "Kill Celebras the Cursed, then speak to Celebras the Redeemed."),
    accept(7046, nil, "Watch Celebras make the scepter."), objective(7046, nil, "Stay until the ritual ends.", "Scepter of Celebras"),
    finish(7046, nil, "Speak to Celebras again for the scepter."),
    objective(7028, nil, "Constructs throughout the inner halls drop the carvings.", "15 Theradric Crystal Carvings"),
    objective(7065, nil, "Use the scepter's portal to Theradras's chamber or walk the falls, then kill Princess Theradras.", "Princess Theradras"),
    accept(7066, nil, "Missable: speak to Zaetar's Spirit right after Theradras dies for the Seed of Life."),
  }, {
    finish(7067, pariah), finish(7028, willow), finish(7065, marandis), finish(7041, talendria),
    finish(7070, tervosh),
    finish(7066, on.moonglade("Keeper Remulos", 36.18, 41.79), "Keeper Remulos is at the shrine in Moonglade."),
  })
end

-- The Temple of Atal'Hakkar. The long Stormwind chain, the Stone Circle and the Un'Goro haze.
do
  local name = "Sunken Temple"
  local brohann = on.stormwind("Brohann Caskbelly", 69.45, 40.4)
  local rhapsody = on.hinterlands("Rhapsody Shindigger", 26.94, 48.59)
  local exile = on.hinterlands("Atal'ai Exile", 33.75, 75.21)
  local marvon = on.tanaris("Marvon Rivetseeker", 52.71, 45.92)
  local gregan = on.feralas("Gregan Brewspewer", 45.12, 25.57)
  local muigin = on.ungoro("Muigin", 42.94, 9.64)
  need(1452, "Rhapsody's Kalimdor Kocktail", 43, 38, 1451)
  need(1469, "Rhapsody's Tale", 43, 38, 1452)
  need(1475, "Into The Temple of Atal'Hakkar", 50, 41, 1469)
  need(3446, "Into the Depths", 51, 46, 3444)
  need(3447, "Secret of the Circle", 51, 46, 3444)
  need(1446, "Jammal'an the Prophet", 53, 38)
  need(4143, "Haze of Evil", 52, 47, 4142)
  fromItem(3373, 10454, "The Essence of Eranikus", 55, 48)
  local prep = join(copy("swamp-38", { 1448, 1449 }), copy("arathi-39", { 1449, 1450, 1451 }), {
    accept(1452, rhapsody, "Rhapsody wants Roc gizzards from Tanaris and Groddoc and Ironfur livers from Feralas."),
  }, copy("tanaris-43", { 1452 }), copy("feralas-44", { 1452, 3445 }), copy("hinterlands-48", { 1452 }), {
    accept(1469, rhapsody, "Rhapsody hands you a tablet fragment for Brohann."),
  }, copy("hinterlands-48", { 1469 }), {
    accept(1475, brohann, "Missable: Brohann only offers this after Rhapsody's Tale. Take it before you leave Stormwind."),
    accept(1446, exile, "The Atal'ai Exile hides in the troll ruins of the southern Hinterlands."),
  }, copy("ungoro-49", { 3445, 4141, 4142 }), {
    accept(3444, marvon, "Marvon left his Stone Circle in a chest at his Ratchet workshop."),
    objective(3444, at("Marvon's Chest", 62.5, 38.5, M.barrens), "Open the chest in Marvon's Ratchet workshop.", "Stone Circle"),
    finish(3444, marvon), accept(3446, marvon), accept(3447, marvon),
  }, copy("feralas-52", { 4142 }), {
    accept(4143, gregan, "Gregan wants Atal'ai Haze from the temple's lurkers and worms."),
    enter(name, at("Temple of Atal'Hakkar", 69.7, 53.5, M.swamp),
      "Swim to the sunken temple in the Pool of Tears. Take the stairs down from the ring of broken walls to the portal."),
  })
  add({ id = "dungeon-sunken-temple", title = name, zone = M.swamp, levels = { 47, 54 }, instanceID = 109,
    instance = "Sunken Temple", links = { "dungeon-zul-farrak" },
    bosses = {
      { name = "Atal'alarion (statue event)", npc = 8580,
        tip = "Activate the six statues in the circle in the right order to call him. He knocks people back and hits hard; tank him away from the walls." },
      { name = "Troll minibosses (six balconies)", npc = 5716,
        tip = "Kill all six troll guardians on the balconies to open the way to Jammal'an. Each fights alone with a few adds." },
      { name = "Jammal'an the Prophet and Ogom the Wretched", npc = 5710,
        tip = "Kill Jammal'an first and interrupt his heals. His Hex of Jammal'an turns a player against the group; crowd control them." },
      { name = "Dreamscythe and Weaver", npc = 5721,
        tip = "Two green dragons. Tank them facing away from the group and avoid the breath; kill one at a time." },
      { name = "Morphaz and Hazzas", npc = 5719,
        tip = "Two more dragons in the next room. Same rules: face them away and spread the ranged." },
      { name = "Avatar of Hakkar (optional, needs Hakkari Blood)", npc = 8443,
        tip = "Summoned with the blood for The God Hakkar. Put out the four flames when Hakkar's servants appear." },
      { name = "Shade of Eranikus", npc = 5709,
        tip = "Clear his room carefully. His War Stomp and Deep Slumber hit the group; dispel the sleep on the healer. Loot the Essence of Eranikus." },
    },
    sources = { "https://www.wowhead.com/forever/zone=1477", qdb } }, prep, {
    finish(3447, nil, "Use the statues in the circle of the lower ring in order, then touch the Idol of Hakkar."),
    objective(1475, nil, "Loot Atal'ai Tablets from the plinths around the temple.", "10 Atal'ai Tablets"),
    objective(4143, nil, "Deep Lurkers, Murk Worms and Oozes in the flooded halls drop the haze.", "5 Atal'ai Haze"),
    finish(3446, nil, "Find the Altar of Hakkar in the central chamber after the trolls."),
    objective(1446, nil, "Kill Jammal'an the Prophet and loot his head.", "Head of Jammal'an"),
    withItem(10454, accept(3373, nil, "Use the Essence of Eranikus from the Shade.")),
    finish(3373, nil, "Place the essence in the Essence Font in Eranikus's lair."),
  }, {
    finish(1475, brohann), finish(1446, exile), finish(4143, muigin),
  })
end

-- Blackrock Depths. Ironforge's Thaurissan chain, Kharanos, Morgan's Vigil and Flame Crest.
do
  local name = "Blackrock Depths"
  local ifg, bs = on.ironforge, on.steppes
  local magni = ifg("King Magni Bronzebeard", 39.09, 56.2)
  local enohar = on.blasted("Enohar Thunderbrew", 63.63, 20.63)
  local ragnar = on.dunMorogh("Ragnar Thunderbrew", 46.83, 52.36)
  local oralius = bs("Oralius", 84.56, 68.68)
  local jalinda = bs("Jalinda Sprig", 85.41, 70.06)
  local maxwort = bs("Maxwort Uberglint", 65.15, 23.91)
  local yuka = bs("Yuka Screwspigot", 66.06, 21.95)
  local yorba = on.tanaris("Yorba Screwspigot", 67.04, 24.01)
  need(4341, "Kharan Mighthammer", 59, 50, 3701)
  need(4342, "Kharan's Tale", 59, 50, 4341)
  need(4361, "The Bearer of Bad News", 59, 50, 4342)
  need(4362, "The Fate of the Kingdom", 59, 50, 4361)
  need(4363, "The Princess's Surprise", 59, 50, 4362)
  need(4128, "Ragnar Thunderbrew", 55, 50)
  need(4126, "Hurley Blackbreath", 55, 50, 4128)
  need(4286, "The Good Stuff", 56, 50)
  need(4262, "Overmaster Pyron", 52, 48)
  need(4263, "Incendius!", 56, 48, 4262)
  need(4123, "The Heart of the Mountain", 55, 50)
  need(4324, "Yuka Screwspigot", 53, 48)
  need(4136, "Ribbly Screwspigot", 53, 48, 4324)
  local prep = join(copy("steppes-56", { 3702, 3701 }), {
    accept(4341, magni, "King Magni wants news of Kharan Mighthammer, held in the Depths."),
    accept(4324, yorba, "If you pass Steamwheedle Port, Yorba Screwspigot sends you to her brother Yuka."),
    accept(4128, enohar, "Enohar Thunderbrew at Nethergarde Keep sends you to his brother in Kharanos."),
    finish(4128, ragnar, "Ragnar Thunderbrew is in the Kharanos brewery."), accept(4126, ragnar),
    accept(4286, oralius, "Oralius at Morgan's Vigil wants Dark Iron fanny packs."),
    accept(4262, jalinda, "Jalinda Sprig wants Overmaster Pyron dead."),
    finish(4324, yuka, "Yuka Screwspigot is at Flame Crest."), accept(4136, yuka),
    accept(4123, maxwort, "Maxwort Uberglint, also at Flame Crest, wants the Heart of the Mountain."),
    action("goto", brm, "Enter Blackrock Mountain from the Searing Gorge or the Burning Steppes and take the chain down to the Depths' door."),
    uncertain(objective(4262, nil, "Overmaster Pyron guards the quarry by the Depths' entrance. Kill him before the run.", "Overmaster Pyron"),
      "Some guides place Pyron just inside the instance."),
    finish(4262, jalinda, "Take Pyron's death back to Jalinda at Morgan's Vigil."), accept(4263, jalinda),
    enter(name, brm, "In Blackrock Mountain, cross the chains to the Depths' portal at the bottom."),
  })
  add({ id = "dungeon-blackrock-depths", title = name, zone = M.searing, levels = { 50, 58 }, instanceID = 230, instance = name,
    links = { "dungeon-lower-blackrock-spire" },
    bosses = {
      { name = "Lord Roccor", npc = 9025,
        tip = "A rock elemental near the start. Cure his poison and step out of his Ground Tremor." },
      { name = "High Interrogator Gerstahn", npc = 9018,
        tip = "In the Detention Block. Dispel her Shadow Word: Pain and interrupt her Mind Blast." },
      { name = "Ring of Law", npc = 9027,
        tip = "Jumping into the arena starts waves and a random boss. Fight in the middle and save cooldowns for the boss." },
      { name = "Pyromancer Loregrain", npc = 9024,
        tip = "Kill his searing totems and interrupt his Flame Shock." },
      { name = "Lord Incendius", npc = 9017,
        tip = "At the Black Anvil. His knockback and Fire Storm spread the group; tank him against a wall." },
      { name = "Fineous Darkvire", npc = 9056,
        tip = "Cleanse his poison and stun his heal. He carries Ironfel." },
      { name = "Bael'Gar", npc = 9016,
        tip = "A fire giant who calls fire elementals. Kill the adds and keep the tank healed." },
      { name = "General Angerforge", npc = 9033,
        tip = "At low health he calls a large add wave. Push him low together and burn the last part fast." },
      { name = "Golem Lord Argelmach", npc = 8983,
        tip = "Clear his golems first: he wakes the ones nearby. Interrupt his Chain Lightning." },
      { name = "Hurley Blackbreath", npc = 9537,
        tip = "In the Grim Guzzler, after the ale kegs are broken. Fight him away from the bar crowd." },
      { name = "Ribbly Screwspigot", npc = 9543,
        tip = "In the Grim Guzzler. Pulling him angers his bodyguards; take them one at a time." },
      { name = "Ambassador Flamelash", npc = 9156,
        tip = "Fire elementals walk to him from the runes. Stop them reaching him or he grows stronger." },
      { name = "The Seven", npc = 9039,
        tip = "Doom'rel starts seven fights in a row. Kill each dwarf before the next joins." },
      { name = "Magmus", npc = 9938,
        tip = "A giant in the throne room approach; the fire jets on the floor hurt, so stay off them." },
      { name = "Emperor Dagran Thaurissan", npc = 9019,
        tip = "Princess Moira heals him. Do not kill her if you want Moira's quest; burn the Emperor through her heals." },
    },
    sources = { "https://www.wowhead.com/forever/zone=1584", qdb } }, prep, {
    finish(4341, nil, "Kharan Mighthammer sits in a cell of the Detention Block."),
    accept(4342, nil, "Listen to Kharan's story."), objective(4342, nil, "Hear him out.", "Kharan's Tale"), finish(4342, nil, "Speak to Kharan again."),
    accept(4361, nil, "Take Kharan's news back to Magni."),
    objective(4286, nil, "Loot Dark Iron fanny packs from the dwarves throughout the Depths.", "20 Dark Iron Fanny Packs"),
    objective(4263, nil, "Kill Lord Incendius at the Black Anvil.", "Lord Incendius"),
    uncertain(objective(4123, nil, "Open the safe in the Vault after the four watchers fall for the Heart of the Mountain.", "Heart of the Mountain"),
      "Check the Vault's lock in game."),
    objective(4126, nil, "In the Grim Guzzler, break the ale kegs and kill Hurley Blackbreath for the recipe.", "Lost Thunderbrew Recipe"),
    objective(4136, nil, "Kill Ribbly Screwspigot in the Grim Guzzler and loot his head.", "Ribbly's Head"),
  }, {
    finish(4286, oralius), finish(4263, jalinda), finish(4123, maxwort), finish(4136, yuka),
    finish(4126, ragnar),
    finish(4361, magni), accept(4362, magni, "Magni sends you back for Princess Moira."),
    objective(4362, nil, "On your next full run, kill Emperor Thaurissan in the throne room without killing Moira.", "Emperor Dagran Thaurissan"),
    finish(4362, nil, "Speak to Princess Moira after the Emperor dies."),
    accept(4363, nil, "Take Moira's message to her father."),
    finish(4363, magni),
  })
end

-- Lower Blackrock Spire. Morgan's Vigil and Flame Crest pickups; Drakkisath's orders lead upstairs.
do
  local name = "Lower Blackrock Spire"
  local bs = on.steppes
  local helendis = bs("Helendis Riverhorn", 85.82, 68.95)
  local kibler = bs("Kibler", 65.89, 21.92)
  local john = bs("Ragged John", 65.01, 23.76)
  local maxwell = bs("Marshal Maxwell", 84.74, 69.02)
  need(4701, "Put Her Down", 59, 55)
  need(4862, "En-Ay-Es-Tee-Why", 59, 55)
  need(4729, "Kibler's Exotic Pets", 59, 55)
  need(4866, "Mother's Milk", 60, 55)
  need(4867, "Urok Doomhowl", 60, 55)
  need(5001, "Bijou's Belongings", 59, 55)
  need(5002, "Message to Maxwell", 59, 55, 5001)
  need(5081, "Maxwell's Mission", 60, 55, 5002)
  add({ id = "dungeon-lower-blackrock-spire", title = name, zone = M.searing, levels = { 55, 60 }, instanceID = 229,
    instance = "Blackrock Spire", links = { "dungeon-upper-blackrock-spire", "dungeon-blackrock-depths" },
    bosses = {
      { name = "Highlord Omokk", npc = 9196,
        tip = "Clear the ogres on the platform first. He knocks people off the edge, so tank him with your back to the wall." },
      { name = "Shadow Hunter Vosh'gajin", npc = 9236,
        tip = "Dispel her curse and hex, and kill her totems." },
      { name = "War Master Voone", npc = 9237,
        tip = "He throws axes and cleaves. Ranged stay spread; melee stay behind him." },
      { name = "Mother Smolderweb", npc = 10596,
        tip = "Spiders and webs. Her poison stacks on the tank; the Mother's Milk player lets her poison them on purpose." },
      { name = "Urok Doomhowl (event)", npc = 10584,
        tip = "Summoned with Warosh's challenge. Ogre waves come before him; kill them and keep the healer safe." },
      { name = "Quartermaster Zigris", npc = 9736,
        tip = "He drinks potions and shoots. Interrupt or stun his heal." },
      { name = "Halycon and Gizrul the Slavener", npc = 10220,
        tip = "Halycon the worg first; Gizrul comes after and frenzies, so keep a tranquilize or cooldown ready." },
      { name = "Overlord Wyrmthalak", npc = 9568,
        tip = "At low health he calls two dragonkin. Save cooldowns for the end. Loot General Drakkisath's Command." },
    },
    sources = { "https://www.wowhead.com/forever/zone=1583", qdb } }, {
    accept(4701, helendis, "Helendis Riverhorn at Morgan's Vigil wants the worg Halycon put down."),
    accept(4862, kibler, "Kibler at Flame Crest wants spider eggs."),
    accept(4729, kibler, "He also gives you a cage for a worg pup."),
    accept(4866, john, "Ragged John, nearby, wants you poisoned by Mother Smolderweb."),
    enter(name, brm, "In Blackrock Mountain take the upper path and climb to the Spire's portal."),
  }, {
    accept(4867, nil, "Warosh, a troll near the start, gives you his scroll."),
    objective(4867, nil, "Find the spear and the challenge at Urok's platform and summon Urok Doomhowl for Warosh's mojo.", "Warosh's Mojo"),
    finish(4867, nil, "Return to Warosh."),
    accept(5001, nil, "Bijou, a gnome near the spider halls, lost her belongings."),
    objective(5001, nil, "Her belongings are on a crate near Mother Smolderweb.", "Bijou's Belongings"),
    finish(5001, nil, "Bring Bijou her belongings."), accept(5002, nil, "Take Bijou's information to Marshal Maxwell."),
    objective(4862, nil, "Loot spider eggs in the spider halls.", "15 Spire Spider Eggs"),
    objective(4866, nil, "Let Mother Smolderweb poison you, then go straight back to Ragged John.", "Poisoned by Mother Smolderweb"),
    withItem(12262, objective(4729, nil, "Use the cage on Bloodaxe Worg Pups near Halycon.", "Caged Worg Pup")),
    objective(4701, nil, "Kill Halycon in the worg kennels.", "Halycon"),
    tip("Drakkisath's orders", "Wyrmthalak drops General Drakkisath's Command. Keep it; the Upper Blackrock Spire guide picks it up."),
  }, {
    finish(4866, john, "Ragged John cures you; go to him while still poisoned."),
    finish(4862, kibler), finish(4729, kibler), finish(4701, helendis),
    finish(5002, maxwell), accept(5081, maxwell, "Maxwell's own mission is another Lower Spire run: Voone, Omokk and Wyrmthalak."),
    objective(5081, nil, "On your next run, kill War Master Voone, Highlord Omokk and Overlord Wyrmthalak.", "War Master Voone", "Highlord Omokk", "Overlord Wyrmthalak"),
    finish(5081, maxwell),
  })
end

-- Upper Blackrock Spire. Needs the Seal of Ascension; Ridgewell's clasp and Drakkisath's demise.
do
  local name = "Upper Blackrock Spire"
  local bs = on.steppes
  local ridgewell = on.stormwind("Count Remington Ridgewell", 76.94, 47.83)
  local mayara = bs("Mayara Brightwing", 84.84, 69.12)
  local maxwell = bs("Marshal Maxwell", 84.74, 69.02)
  local haleh = on.winterspring("Haleh", 54.55, 51.2)
  local malyfous = on.winterspring("Malyfous Darkhammer", 60.99, 38.78)
  need(4766, "Mayara Brightwing", 60, 57)
  need(4764, "Doomrigger's Clasp", 60, 57, 4766)
  need(4765, "Delivery to Ridgewell", 60, 57, 4764)
  fromItem(5089, 12780, "General Drakkisath's Command", 60, 55)
  need(5102, "General Drakkisath's Demise", 60, 55, 5089)
  fromItem(5160, 12923, "The Matron Protectorate", 60, 57)
  fromItem(5047, 12710, "Finkle Einhorn, At Your Service!", 60, 55)
  add({ id = "dungeon-upper-blackrock-spire", title = name, zone = M.searing, levels = { 58, 60 }, instanceID = 229,
    instance = "Blackrock Spire", links = { "dungeon-lower-blackrock-spire" },
    bosses = {
      { name = "Pyroguard Emberseer", npc = 9816,
        tip = "Clear the room's orcs, then use the seven altars together to wake him. He grows hotter over time; burn him." },
      { name = "Solakar Flamewreath", npc = 10264,
        tip = "Touching the egg wakes waves of whelps and handlers before him. Hold them on the tank and use area damage." },
      { name = "Goraluk Anvilcrack", npc = 10899,
        tip = "A plain hard-hitting ogre. Keep the tank healed." },
      { name = "Warchief Rend Blackhand and Gyth", npc = 10429,
        tip = "The event sends many waves before Gyth lands with Rend. Fight near the door so the waves come in a line; kill Gyth, then Rend." },
      { name = "The Beast", npc = 10430,
        tip = "Fireballs, fear and a knockback. Tank him in the corridor so nobody is feared into packs. Finkle Einhorn comes out after." },
      { name = "General Drakkisath", npc = 10363,
        tip = "Pull his two guards away first. Tank him facing away; his Flamestrike and Conflagration need spread ranged." },
    },
    sources = { "https://www.wowhead.com/forever/zone=1583", qdb } }, {
    tip("Seal of Ascension", "Upper Spire needs a Seal of Ascension from Vaelan in Lower Blackrock Spire. One group member with the seal opens the door."),
    accept(4766, ridgewell, "Count Remington Ridgewell in Stormwind Keep sends you to Mayara."),
    finish(4766, mayara, "Mayara Brightwing is at Morgan's Vigil."), accept(4764, mayara),
    withItem(12780, accept(5089, nil, "Use General Drakkisath's Command if you looted it in Lower Blackrock Spire.")),
    finish(5089, maxwell), accept(5102, maxwell, "Maxwell wants General Drakkisath dead."),
    enter(name, brm, "Climb to the Spire's portal in Blackrock Mountain. The Upper Spire door is at the start, past the first ramps."),
  }, {
    objective(4764, nil, "Doomrigger's Clasp sits in a chest along the way to Rend.", "Doomrigger's Clasp"),
    withItem(12923, accept(5160, nil, "Use Awbee's scale if it drops for you.")),
    withItem(12710, accept(5047, nil, "Speak to Finkle Einhorn after The Beast dies.")),
    objective(5102, nil, "Kill General Drakkisath in his hall.", "General Drakkisath"),
  }, {
    finish(4764, mayara), accept(4765, mayara), finish(4765, ridgewell),
    finish(5102, maxwell),
    finish(5160, haleh, "Haleh lives at Mazthoril in Winterspring."),
    finish(5047, malyfous, "Malyfous Darkhammer is at the Everlook forge."),
  })
end

-- Dire Maul: East. Feathermoon, the Lariss Pavilion and Rabine Saturna's Felvine.
do
  local name = "Dire Maul: East"
  local fe = on.feralas
  local goodman = on.stormwind("Crier Goodman", 56.39, 74.09)
  local latronicus = fe("Latronicus Moonspear", 30.38, 46.17)
  local azj = fe("Azj'Tordin", 76.91, 37.35)
  local rabine = on.moonglade("Rabine Saturna", 51.69, 45.1)
  need(7494, "Feathermoon Stronghold", 57, 54)
  need(7488, "Lethtendris's Web", 57, 54, 7494)
  need(7441, "Pusillin and the Elder Azj'Tordin", 58, 54)
  need(5526, "Shards of the Felvine", 60, 56, 5527)
  B.breadcrumb(7494, 7488)
  add({ id = "dungeon-dire-maul-east", title = name, zone = M.feralas, levels = { 55, 60 }, instanceID = 429, instance = "Dire Maul",
    links = { "dungeon-dire-maul-west", "dungeon-dire-maul-north" },
    bosses = {
      { name = "Pusillin", npc = 14354,
        tip = "An imp who runs off when you speak to him. Chase him through the halls; he fights at the end with his imps." },
      { name = "Zevrim Thornhoof", npc = 11490,
        tip = "His Sacrifice stuns and drains one player. Burn him and heal through it." },
      { name = "Hydrospawn", npc = 13280,
        tip = "A water elemental. His Riptide and knockback scatter the group; tank him against a wall." },
      { name = "Lethtendris", npc = 14327,
        tip = "Kill her pimgib imp first. She casts Shadow Bolt Volley; spread and interrupt." },
      { name = "Alzzin the Wildshaper", npc = 11492,
        tip = "He changes form often. Kill his adds and keep moving with him. Use the Reliquary on the Felvine after he dies." },
    },
    sources = { "https://www.wowhead.com/forever/zone=2557", qdb } }, join(copy("silithus-59", { 5527 }), copy("silithus-60", { 5527 }), {
    accept(5526, rabine, "Rabine wants a shard of the Felvine sealed in the Reliquary."),
    accept(7494, goodman, "Crier Goodman in Stormwind's Trade District announces the Feathermoon call."),
    finish(7494, latronicus, "Latronicus Moonspear commands Feathermoon Stronghold."),
    accept(7488, latronicus),
    accept(7441, azj, "Azj'Tordin waits at the Lariss Pavilion in eastern Feralas."),
    uncertain(enter(name, dmDoor, "Ride to the ruined city in central Feralas. The East wing's portal is in the courtyard reached from the Broken Commons."),
      "Wing entrance positions from the classic map; check in game."),
  }), {
    objective(7441, nil, "Speak to Pusillin and chase him; loot his book when he gives up.", "Azj'Tordin's Book of Incantations"),
    objective(7488, nil, "Kill Lethtendris and loot her web.", "Lethtendris's Web"),
    withItem(18539, objective(5526, nil, "Kill Alzzin, then use the Reliquary of Purity on the Felvine.", "Felvine Shard")),
  }, {
    finish(7441, azj), finish(7488, latronicus), finish(5526, rabine),
  })
end

-- Dire Maul: West. The pylons, Immol'thar and the Athenaeum.
do
  local name = "Dire Maul: West"
  local runethorn = on.feralas("Scholar Runethorn", 31.65, 43.45)
  need(7482, "Elven Legends", 60, 54)
  need(7461, "The Madness Within", 60, 56)
  need(7462, "The Treasure of the Shen'dralar", 60, 56, 7461)
  add({ id = "dungeon-dire-maul-west", title = name, zone = M.feralas, levels = { 57, 60 }, instanceID = 429, instance = "Dire Maul",
    links = { "dungeon-dire-maul-east", "dungeon-dire-maul-north" },
    bosses = {
      { name = "Tendris Warpwood", npc = 11489,
        tip = "A treant with heavy roots and stuns. Tank him near the courtyard door and heal through the roots." },
      { name = "Illyanna Ravenoak", npc = 11488,
        tip = "A hunter with a pet bear. Kill or crowd control the bear; she volleys the group." },
      { name = "Magister Kalendris", npc = 11487,
        tip = "Interrupt his Mind Blast and dispel his Shadow Word: Pain." },
      { name = "Immol'thar", npc = 11496,
        tip = "Shut down the five pylons first. He summons eyes of Immol'thar; kill them and avoid his Trample." },
      { name = "Prince Tortheldrin", npc = 11486,
        tip = "In the Athenaeum. He whirlwinds and teleports to random players; keep healers ready." },
    },
    sources = { "https://www.wowhead.com/forever/zone=2557", qdb } }, {
    accept(7482, runethorn, "Scholar Runethorn at Feathermoon wants news of Kariel Winthalus."),
    uncertain(enter(name, dmDoor, "Ride to the ruined city in central Feralas. The West wing's portal is in the Capital Gardens courtyard."),
      "Wing entrance positions from the classic map; check in game."),
  }, {
    accept(7461, nil, "The Shen'dralar Ancient in the gardens wants Immol'thar freed and killed."),
    objective(7461, nil, "Kill the guardians at the five pylons, then Immol'thar in his prison.", "Pylons powered down", "Immol'thar"),
    finish(7461, nil, "Return to the Shen'dralar Ancient."),
    accept(7462, nil, "Kill Prince Tortheldrin, then look for the treasure in the Athenaeum."),
    finish(7462, nil, "Open the Treasure of the Shen'dralar in the Athenaeum."),
    uncertain(objective(7482, nil, "Kariel Winthalus's spirit is in the Athenaeum library. Speak to him.", "Kariel Winthalus"),
      "Some guides do Elven Legends in the Gordok wing; check where Kariel is."),
  }, {
    finish(7482, runethorn),
  })
end

-- Dire Maul: North. The Gordok ogres and the tribute run.
do
  local name = "Dire Maul: North"
  need(5528, "The Gordok Taste Test", 60, 57)
  need(7703, "Unfinished Gordok Business", 60, 56)
  add({ id = "dungeon-dire-maul-north", title = name, zone = M.feralas, levels = { 57, 60 }, instanceID = 429, instance = "Dire Maul",
    links = { "dungeon-dire-maul-west", "dungeon-dire-maul-east" },
    bosses = {
      { name = "Guard Mol'dar", npc = 14326,
        tip = "For the tribute run, leave the guards alive. If you fight him, face his cleave away." },
      { name = "Stomper Kreeg", npc = 14322,
        tip = "A drunk ogre. If fought, his whirlwind hits melee." },
      { name = "Guard Fengus", npc = 14321,
        tip = "Tribute run: leave him alive. Otherwise tank him away from patrols." },
      { name = "Guard Slip'kik", npc = 14323,
        tip = "Use the Ogre Suit or freeze trap to slip past him for the tribute; otherwise a plain fight." },
      { name = "Captain Kromcrush", npc = 14325,
        tip = "He calls two ogre guards at low health. Save cooldowns for that." },
      { name = "Cho'Rush the Observer", npc = 14324,
        tip = "A caster beside King Gordok. Interrupt him; he becomes friendly if you kill the King last." },
      { name = "King Gordok", npc = 11501,
        tip = "Kill him after Cho'Rush engages; his Mortal Strike and knockback need a steady tank. The ogres then crown your group." },
    },
    sources = { "https://www.wowhead.com/forever/zone=2557", qdb } }, {
    uncertain(enter(name, dmDoor, "Ride to the ruined city in central Feralas. The Gordok wing's portal is on the north side of the courtyard."),
      "Wing entrance positions from the classic map; check in game."),
  }, {
    tip("Tribute run", "Leave the guards alive and kill only King Gordok for the tribute chest. Any guard you kill makes the chest smaller."),
    accept(5528, nil, "After King Gordok falls, Stomper Kreeg offers a taste test."),
    finish(5528, nil, "Try the brew and turn the quest in to Kreeg."),
    accept(7703, nil, "Captain Kromcrush wants the Gauntlet of Gordok Might; Prince Tortheldrin in the West wing has it."),
    uncertain(objective(7703, nil, "Kill Prince Tortheldrin in Dire Maul West and take the gauntlet from the chest.", "Gauntlet of Gordok Might"),
      "The gauntlet's chest is in the West wing; open that guide."),
    finish(7703, nil, "Bring the gauntlet back to Kromcrush."),
  })
end

-- Scholomance. Light's Hope, Chillwind Camp and Caer Darrow; Ras Frostwhisper's chain runs through Stratholme.
do
  local name = "Scholomance"
  local betina = on.epl("Betina Bigglezink", 71.66, 49.94)
  local leonid = on.epl("Leonid Barthalomew the Revered", 71.89, 48.29)
  local weldon = on.wpl("Weldon Barov", 43.45, 83.73)
  local eva = on.wpl("Eva Sarkhoff", 70.22, 73.71)
  local marduke = on.wpl("Magistrate Marduke", 70.57, 74.11)
  need(5529, "Plagued Hatchlings", 58, 55)
  need(5343, "Barov Family Fortune", 60, 52)
  need(5382, "Doctor Theolen Krastinov, the Butcher", 60, 55)
  need(5515, "Krastinov's Bag of Horrors", 60, 55, 5382)
  need(5384, "Kirtonos the Herald", 60, 55, 5515)
  need(5461, "The Human, Ras Frostwhisper", 60, 57, 5384)
  need(5462, "The Dying, Ras Frostwhisper", 60, 57, 5461)
  need(5463, "Menethil's Gift", 60, 57, 5462)
  need(5464, "Menethil's Gift", 60, 57, 5463)
  need(5465, "Soulbound Keepsake", 60, 57, 5464)
  need(5466, "The Lich, Ras Frostwhisper", 60, 57, 5465)
  add({ id = "dungeon-scholomance", title = name, zone = M.wpl, levels = { 57, 60 }, instanceID = 289, instance = name,
    links = { "dungeon-stratholme" },
    bosses = {
      { name = "Kirtonos the Herald (summoned)", npc = 10506,
        tip = "Placing the Blood of Innocents on the porch brazier calls him. Pull the lever on the wall to drop the gates and stop the adds." },
      { name = "Jandice Barov", npc = 10503,
        tip = "She splits into many images. Area damage clears them; find the real one and burn her." },
      { name = "Rattlegore", npc = 11622,
        tip = "A bone giant who hits very hard. Tank him in the corner and keep the healer on the tank." },
      { name = "Ras Frostwhisper", npc = 10508,
        tip = "Frost Nova and Frostbolt Volley. Use the Soulbound Keepsake on him for Ras's quest, then fight him as a mortal." },
      { name = "Doctor Theolen Krastinov", npc = 11261,
        tip = "In the room past the viewing hall. He frenzies at low health; burn him and save a stun." },
      { name = "Lorekeeper Polkelt", npc = 10901,
        tip = "His disease stacks on the tank; cure it." },
      { name = "Lady Illucia Barov and Lord Alexei Barov", npc = 10502,
        tip = "Two separate rooms. Illucia mind controls and fears; Alexei casts Unholy Aura. Clear their rooms first." },
      { name = "The Ravenian", npc = 10507,
        tip = "A plain melee boss with a wide cleave. Face him away from the group." },
      { name = "Instructor Malicia", npc = 10505,
        tip = "Interrupt her heals and cleanse her poison." },
      { name = "Darkmaster Gandling", npc = 1853,
        tip = "Appears once the six side bosses are dead. He teleports players into rooms with adds; those players fight their way out while the tank holds him." },
    },
    sources = { "https://www.wowhead.com/forever/zone=2057", qdb } }, {
    tip("Skeleton Key", "Scholomance needs the Skeleton Key from the Chillwind Camp key chain. One key holder opens the door for everyone."),
    accept(5529, betina, "Betina Bigglezink at Light's Hope Chapel wants the plagued hatchlings cleared."),
    accept(5343, weldon, "Weldon Barov at Chillwind Camp wants his family's deeds."),
    accept(5382, eva, "Eva Sarkhoff waits by the Caer Darrow ruins with her husband."),
    enter(name, at("Caer Darrow", 69.4, 72.8, M.wpl), "Cross to Caer Darrow and enter the Scholomance through the castle's crypt with your key."),
  }, {
    objective(5529, nil, "Kill the plagued hatchlings in the dragon nests past the first halls.",
      "20 Plagued Hatchlings"),
    objective(5382, nil, "Kill Doctor Theolen Krastinov, then burn the Remains of Eva and Lucien Sarkhoff in his room.", "Doctor Theolen Krastinov", "Remains burned"),
    objective(5343, nil, "Loot the four deeds from the Barov family members and the chests in their rooms.",
      "Deed to Caer Darrow", "Deed to Brill", "Deed to Tarren Mill", "Deed to Southshore"),
    finish(5382, eva, "Step outside to Eva Sarkhoff if you want to keep going in the same run."),
    accept(5515, eva), objective(5515, nil, "Kill Jandice Barov and loot Krastinov's bag.", "Krastinov's Bag of Horrors"),
    finish(5515, eva), accept(5384, eva, "Eva gives you the Blood of Innocents for Kirtonos."),
    withItem(13523, objective(5384, nil, "Place the Blood of Innocents in the brazier on the porch and kill Kirtonos.", "Kirtonos the Herald")),
  }, {
    finish(5384, eva), finish(5529, betina), finish(5343, weldon),
    accept(5461, marduke, "Magistrate Marduke, beside Eva, starts the Ras Frostwhisper chain."),
    objective(5461, at("Stromgarde", 22.5, 65.8, M.arathi), "Search the ruins of Stromgarde in the Arathi Highlands for the Keepsake of Remembrance.", "Keepsake of Remembrance"),
    finish(5461, marduke), accept(5462, marduke),
    finish(5462, leonid, "Leonid Barthalomew is in Light's Hope Chapel."), accept(5463, leonid),
    finish(5463, nil, "In Stratholme, place the Keepsake on Menethil's Gift, the unholy ground of the dead side."),
    accept(5464, nil, "Take the Soulbound Keepsake back."),
    finish(5464, leonid), accept(5465, leonid), finish(5465, marduke), accept(5466, marduke),
    withItem(13752, objective(5466, nil, "On your next Scholomance run, use the Soulbound Keepsake on Ras Frostwhisper, then kill him.", "Human Head of Ras Frostwhisper")),
    finish(5466, marduke),
  })
end

-- Stratholme. Light's Hope pickups, Egan by the gate and Tirion's painting.
do
  local name = "Stratholme"
  local epl = on.epl
  local alen = epl("Caretaker Alen", 69.93, 53.72)
  local egan = epl("Egan", 11.36, 26.6)
  local zverenhoff = epl("Duke Nicholas Zverenhoff", 71.63, 50.09)
  local betina = epl("Betina Bigglezink", 71.66, 49.94)
  local smokey = epl("Smokey LaRue", 70.88, 48.43)
  local leonid = epl("Leonid Barthalomew the Revered", 71.89, 48.29)
  local tyrosus = epl("Lord Maxwell Tyrosus", 71.9, 48.41)
  local tirion = epl("Tirion Fordring", 5.2, 35.6)
  local renfray = on.wpl("Artist Renfray", 65.77, 75.37)
  need(5281, "The Restless Souls", 60, 55)
  need(5282, "The Restless Souls", 60, 55, 5281)
  need(5251, "The Archivist", 60, 55)
  fromItem(5262, 13250, "The Truth Comes Crashing Down", 60, 55, 5251)
  need(5263, "Above and Beyond", 60, 55, 5262)
  need(5264, "Lord Maxwell Tyrosus", 60, 55, 5263)
  need(5212, "The Flesh Does Not Lie", 60, 55)
  need(5213, "The Active Agent", 60, 55, 5212)
  need(5214, "The Great Fras Siabi", 60, 55)
  need(5243, "Houses of the Holy", 60, 55)
  need(5848, "Of Love and Family", 60, 52, 5846)
  local prep = join(copy("plaguelands-57", { 5542, 5543, 5544, 5742, 5781, 5845 }),
    copy("plaguelands-58", { 5845, 5846 }), {
    accept(5848, renfray, "Renfray describes where the painting hangs in Stratholme."),
    accept(5281, alen, "Caretaker Alen at Light's Hope wants Egan found."),
    accept(5251, zverenhoff, "Duke Nicholas Zverenhoff wants Archivist Galford dead."),
    accept(5212, betina, "Betina wants plagued flesh samples."),
    accept(5214, smokey, "Smokey LaRue wants Fras Siabi's tobacco."),
    accept(5243, leonid, "Leonid wants Stratholme's holy water."),
    finish(5281, egan, "Egan waits outside Stratholme's gate."), accept(5282, egan, "He gives you a blaster for the restless souls."),
    enter(name, at("Stratholme gate", 26.5, 10.4, M.epl),
      "The main gate leads to the living side (Scarlet Bastion). The service gate on the east side leads to the dead side and Baron Rivendare."),
  })
  add({ id = "dungeon-stratholme", title = name, zone = M.epl, levels = { 57, 60 }, instanceID = 329, instance = name,
    links = { "dungeon-scholomance" },
    bosses = {
      { name = "The Unforgiven", npc = 10516,
        tip = "Ghosts come first. Kill them, then dispel or heal through his frost spells." },
      { name = "Timmy the Cruel", npc = 10808,
        tip = "Appears after the market's undead are cleared. A heavy hitter; keep the tank healed." },
      { name = "Cannon Master Willey", npc = 10997,
        tip = "His riflemen shoot from the platform. Kill them, then pull him; his cannon knocks people back." },
      { name = "Archivist Galford", npc = 10811,
        tip = "In the archive. Burn the archive after he dies for Zverenhoff's quest." },
      { name = "Balnazzar", npc = 10813,
        tip = "Grand Crusader Dathrohan turns into Balnazzar at half health. He mind controls and casts Psychic Scream; spread out." },
      { name = "Baroness Anastari", npc = 10436,
        tip = "Dead side. She possesses a player; keep crowd control ready and dispel her silence." },
      { name = "Nerub'enkan", npc = 10437,
        tip = "Dead side. Kill the scarabs he calls and cure the poison." },
      { name = "Maleki the Pallid", npc = 10438,
        tip = "Dead side. Interrupt his Frostbolt and dispel Drain Life." },
      { name = "Ramstein the Gorger", npc = 10439,
        tip = "After the abominations. He knocks the tank back; tank him against a wall." },
      { name = "Baron Rivendare", npc = 10440,
        tip = "He calls skeletons and uses Death Pact. Kill the skeletons fast; there is no timer unless you started the run's event." },
    },
    sources = { "https://www.wowhead.com/forever/zone=2017", qdb } }, prep, {
    withItem(13289, objective(5282, nil, "Use Egan's Blaster on ghostly citizens, then again on the souls that break free.", "15 Restless Souls freed")),
    objective(5212, nil, "Any creature in the city can drop plagued flesh.", "10 Plagued Flesh Samples"),
    objective(5243, nil, "Search the supply crates through the streets for holy water.", "5 Stratholme Holy Water"),
    objective(5214, nil, "Fras Siabi's smoke shop is on the living side. Open the box to fight him, then loot the tobacco.", "Siabi's Premium Tobacco"),
    objective(5848, nil, "In the Scarlet Bastion, the painting hangs behind the twin moons painting.", "Of Love and Family"),
    objective(5251, nil, "Kill Archivist Galford and burn the Scarlet Archive.", "Archivist Galford", "Scarlet Archive"),
    tip("Head of Balnazzar", "Loot the Head of Balnazzar and keep it. It starts its quest once The Archivist is handed in."),
  }, {
    finish(5282, egan), finish(5214, smokey), finish(5243, leonid), finish(5212, betina),
    accept(5213, betina, "Betina's follow-up needs Scourge data from the dead side's ziggurats."),
    finish(5251, zverenhoff), withItem(13250, accept(5262, zverenhoff, "Use the Head of Balnazzar now.")),
    finish(5262, zverenhoff), accept(5263, zverenhoff, "Zverenhoff now wants Baron Rivendare."),
    objective(5213, nil, "On a dead-side run, search the ziggurats for new Scourge data.", "Scourge Data"),
    objective(5263, nil, "On a dead-side run, kill Baron Rivendare and take his head.", "Head of Baron Rivendare"),
    finish(5213, betina), finish(5263, zverenhoff), accept(5264, zverenhoff), finish(5264, tyrosus, "Lord Maxwell Tyrosus is inside the chapel."),
    finish(5848, tirion, "Bring the painting to Tirion Fordring at his hut."),
  })
end
