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
  add({ id = "dungeon-krol-dok-stronghold", title = name, zone = M.riverglades, levels = { 40, 45 }, instance = name,
    bosses = {
      { name = "Slavecrusher Grox",
        tip = "Several ogre packs and a long patrol come first; let the patrol pass before you pull him. Tank him away from the slave pens." },
      { name = "Twilight Commander Zarmok",
        tip = "He leaves a heavy bleed on the tank, so healers keep the tank topped up. His death opens the big gate behind him." },
      { name = "War Handler Ashka",
        tip = "She fights with two wolves. Kill or crowd control the wolves first; she may stand off the main road." },
      { name = "Nar'gurk",
        tip = "He takes control of a player. Fight near cover, keep a crowd control ready for the charmed player and do not kill them." },
      { name = "Bossman Toof",
        tip = "Waits past the bridge. Not part of the game's boss list, but he hits hard; pull him without the nearby ogres." },
      { name = "Overlord Mugg",
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

-- Guides not filled in yet: entrance stubs, so the route's forDungeon tags have a target.
for _, s in ipairs({
  { "dungeon-maraudon", "Maraudon", M.desolace, 44, 52, 349, "Maraudon", at("Maraudon outer cave", 29.1, 62.6, M.desolace) },
  { "dungeon-sunken-temple", "Sunken Temple", M.swamp, 47, 54, 109, "Sunken Temple", at("Temple of Atal'Hakkar", 69.7, 53.5, M.swamp) },
  { "dungeon-blackrock-depths", "Blackrock Depths", M.searing, 50, 58, 230, "Blackrock Depths", brm },
  { "dungeon-lower-blackrock-spire", "Lower Blackrock Spire", M.searing, 55, 60, 229, "Blackrock Spire", brm },
  { "dungeon-upper-blackrock-spire", "Upper Blackrock Spire", M.searing, 58, 60, 229, "Blackrock Spire", brm },
  { "dungeon-dire-maul-east", "Dire Maul: East", M.feralas, 55, 60, 429, "Dire Maul", dmDoor },
  { "dungeon-dire-maul-west", "Dire Maul: West", M.feralas, 57, 60, 429, "Dire Maul", dmDoor },
  { "dungeon-dire-maul-north", "Dire Maul: North", M.feralas, 57, 60, 429, "Dire Maul", dmDoor },
  { "dungeon-scholomance", "Scholomance", M.wpl, 57, 60, 289, "Scholomance", at("Caer Darrow", 69.4, 72.8, M.wpl) },
  { "dungeon-stratholme", "Stratholme", M.epl, 57, 60, 329, "Stratholme", at("Stratholme gate", 31.2, 15.6, M.epl) },
}) do
  add({ id = s[1], title = s[2], zone = s[3], levels = { s[4], s[5] }, instanceID = s[6], instance = s[7],
    sources = { qdb } }, {
    uncertain(enter(s[2], s[8], "Meet your group at the entrance and go in together."),
      "Entrance position from the classic map; check it in game."),
  })
end
