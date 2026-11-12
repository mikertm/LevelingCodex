-- Horde dungeon detours (13-38). Quest and travel sources: tools/audits/2026-11-10-horde-dungeons.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local m = B.maps
local accept, finish, action, taxi, withItem = B.accept, B.finish, B.action, B.taxi, B.withItem
local objective = B.objectiveAt

local function add(section, prepare, inside, after)
  section.side, section.category, section.verified = true, "dungeon", false
  section.steps = {}
  for _, group in ipairs({ { "prepare", prepare }, { "inside", inside }, { "after", after } }) do
    for _, step in ipairs(group[2] or {}) do
      -- A detour owns its steps: an outdoor route's optional or dungeon tag never carries over.
      step.phase, step.optional, step.dungeon = group[1], nil, nil
      section.steps[#section.steps + 1] = step
    end
  end
  route.sections[#route.sections + 1] = section
end

local function note(name, text)
  return action("note", nil, text, { name = name })
end

-- `path`: { {x, y}, ... } the arrow follows, in order, to the portal (place).
local function enter(name, place, text, path)
  return action("dungeon", place, text, { name = name, path = path })
end

local function uncertain(step, text)
  step.uncertain = text
  return step
end

-- Quest facts. The outdoor Horde files load first and may already describe a quest;
-- their entry stands (same game facts), so this only fills in what is missing.
local function q(id, name, level, min, prerequisite, forever)
  if not B.quest[id] then B.q(id, name, level, min, prerequisite, forever) end
end

local function fromItem(id, item, name, level, min, prerequisite, forever)
  q(id, name, level, min, prerequisite, forever)
  B.quest[id].startItem = item
end

-- One quest log objective with its own waypoint (objectiveIndex is the quest log position).
local function part(id, index, place, text, label)
  local step = objective(id, place, text, label)
  step.objectiveIndex = index
  return step
end

local function og(name, x, y) return B.at(name, x, y, m.orgrimmar) end
local function tb(name, x, y) return B.at(name, x, y, m.thunderBluff) end
local function uc(name, x, y) return B.at(name, x, y, m.undercity) end
local function ba(name, x, y) return B.at(name, x, y, m.barrens) end

-- Shared places.
local thrall = og("Thrall", 31.73, 37.82)
local neeru = og("Neeru Fireblade", 49.47, 50.59)
local varimathras = uc("Varimathras", 56.25, 92.2)
local faranell = uc("Master Apothecary Faranell", 48.82, 69.28)
local mebok = ba("Mebok Mizzyrix", 62.37, 37.62)
local durotarTower = B.at("Zeppelin tower", 50.8, 13.8, m.durotar)
local tirisfalTower = B.at("Zeppelin tower", 60.7, 58.8, m.tirisfal)
local ucFlights = uc("Michael Garrett", 63.26, 48.55)
local sepulcherFlights = B.at("Karos Razok", 45.62, 42.58, m.silverpine)
local tbFlights = tb("Tal", 47.0, 49.82)
local crossroadsFlights = ba("Devrak", 51.5, 30.34)
local ratchetFlights = ba("Bragok", 63.09, 37.16)

do
  local name = "Ragefire Chasm"
  local rahauro = tb("Rahauro", 70.14, 29.52)
  q(5722, "Searching for the Lost Satchel", 16, 9)
  q(5723, "Testing an Enemy's Strength", 15, 9)
  q(5724, "Returning the Lost Satchel", 16, 9, 5722)
  q(5725, "The Power to Destroy...", 16, 9)
  q(5726, "Hidden Enemies", 12, 9)
  q(5727, "Hidden Enemies", 12, 9, 5726)
  q(5728, "Hidden Enemies", 16, 9, 5727)
  q(5729, "Hidden Enemies", 15, 9, 5728)
  q(5730, "Hidden Enemies", 16, 9, 5729)
  q(5761, "Slaying the Beast", 16, 9)
  add({ id = "dungeon-ragefire-chasm", title = name, zone = m.orgrimmar, levels = { 13, 18 }, instanceID = 389,
    bosses = {
      { name = "Oggleflint", encounter = 2732, npc = 11517,
        tip = "Pull his troggs a few at a time first, and face his cleave away from the group." },
      { name = "Taragaman the Hungerer", encounter = 2733, npc = 11520,
        tip = "Tank him in the middle of his platform so Uppercut cannot throw the tank into the lava. Fire Nova hits melee, so watch their health." },
      { name = "Jergosh the Invoker", encounter = 2734, npc = 11518,
        tip = "Kill Jergosh before his two adds. Dispel Immolate and Curse of Weakness when you can." },
      { name = "Bazzalan", encounter = 2735, npc = 11519,
        tip = "Kill Bazzalan first, then his two adds. Cure the poison on the tank." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/ragefire-chasm/quests/",
      "https://www.warcrafttavern.com/forever/guides/ragefire-chasm-quests/" } }, {
      accept(5722, rahauro, "Find Rahauro on Elder Rise in Thunder Bluff. He has two Ragefire quests."),
      accept(5723, rahauro),
      action("goto", thrall, "Travel to Orgrimmar. Fly if you have the flight path, otherwise ride north through the Barrens."),
      accept(5726, thrall, "Speak to Thrall inside Grommash Hold in the Valley of Wisdom."),
      objective(5726, B.at("Skull Rock", 53.08, 9.19, m.durotar),
        "Leave Orgrimmar by the main gate and head north-east to Skull Rock. Kill Burning Blade cultists in the caves until one drops a Lieutenant's Insignia.",
        "Lieutenant's Insignia"),
      action("boat", durotarTower, "Ride the zeppelin to Tirisfal Glades from the tower just west of Skull Rock."),
      accept(5725, varimathras, "Enter the Undercity and follow the halls to the Royal Quarter at the far end. Varimathras stands beside the Dark Lady."),
      action("boat", tirisfalTower, "Leave the Undercity and take the zeppelin back to Durotar from the tower north-west of the city gate."),
      finish(5726, thrall, "Bring the insignia to Thrall in Grommash Hold."),
      accept(5727, thrall),
      accept(5761, neeru, "Go down into the Cleft of Shadow. Neeru Fireblade sits in the tent near the bottom."),
      objective(5727, neeru, "Show Neeru the insignia and listen to his answer.",
        "Gauge Neeru Fireblade's reaction"),
      finish(5727, thrall),
      accept(5728, thrall, "Take Thrall's order to kill the two Searing Blade leaders below the city."),
      enter(name, og("Ragefire Chasm portal", 52.8, 49.6),
        "Meet your group in the Cleft of Shadow. The portal is in the cave past Neeru's tent."),
    }, {
      note("Trogg tunnels", "The first tunnels belong to Ragefire Troggs and Shamans. Pull them back to the group a few at a time; Oggleflint waits among them."),
      objective(5723, nil, "Count the troggs and shamans as you clear the opening tunnels.",
        "8 Ragefire Troggs", "8 Ragefire Shaman"),
      uncertain(finish(5722, nil, "Search Maur Grimtotem's body in the caves past the troggs and open the satchel beside it."),
        "Check where Maur's body lies in the Forever layout."),
      accept(5724, nil, "Take the satchel back for Rahauro."),
      objective(5725, nil, "Kill Searing Blade Cultists and Warlocks in the middle caves until both books drop.",
        "Spells of Shadow", "Incantations from the Nether"),
      objective(5761, nil, "Cross the lava cavern to Taragaman's platform. Kill him and loot his heart.",
        "Taragaman the Hungerer's Heart"),
      objective(5728, nil, "Push on to the last chambers. Jergosh and Bazzalan each wait with two guards; kill both leaders.",
        "Bazzalan", "Jergosh the Invoker"),
    }, {
      finish(5761, neeru, "Leave through the portal. Neeru's tent is right outside."),
      finish(5728, thrall),
      accept(5729, thrall),
      finish(5729, neeru),
      accept(5730, neeru),
      finish(5730, thrall),
      action("boat", durotarTower, "Ride the zeppelin to Tirisfal Glades for the Undercity hand-in."),
      finish(5725, varimathras),
      action("boat", tirisfalTower, "Take the zeppelin back to Durotar, then travel on to Thunder Bluff."),
      finish(5724, rahauro),
      finish(5723, rahauro),
    })
end

do
  local name = "Ruins of Lordaeron"
  local kristof = B.at("Deathguard Kristof", 65.25, 60.2, m.tirisfal)
  local tabitha = B.at("Tabitha Heartweaver", 44.52, 43.02, m.silverpine)
  local griffs = uc("Theodore Griffs", 46.31, 71.91)
  local morbin = uc("Morbin Lightbane", 58.08, 89.51)
  local oran = uc("Oran Snakewrithe", 73.06, 32.85)
  local othmar = uc("Unfinished Abomination", 45.88, 61.7)
  q(92422, "The Wrath of Rath'mael", 22, 15, nil, true)
  q(92401, "A Frightened Request", 22, 15, nil, true)
  q(95216, "The New Plague", 22, 16, nil, true)
  q(92421, "Light's Justice", 22, 15, nil, true)
  fromItem(95204, 275521, "Crest of Lordaeron", 22, 16, nil, true)
  fromItem(97288, 280438, "Unending Torment", 21, 15, nil, true)
  q(97289, "Unending Torment", 21, 15, 97288, true)
  q(97290, "Unending Torment", 21, 15, 97289, true)
  q(97291, "Unending Torment", 21, 15, 97290, true)
  q(97292, "Unending Torment", 21, 15, 97291, true)
  add({ id = "dungeon-ruins-of-lordaeron", title = name, zone = m.tirisfal, levels = { 17, 22 }, instanceID = 2999,
    bosses = {
      { name = "Witherfang", encounter = 3353,
        tip = "Wait for her alley patrol and pull her alone at range; kill any broodlings that follow. Her poison on the tank can be cleansed but is not urgent." },
      { name = "The Baron", encounter = 3355,
        tip = "Tank him with your back to a wall and keep melee behind him. His knockout hits hard and stuns the tank, so keep the tank topped up and stun him when you can." },
      { name = "Viktor the Vile (optional event)", encounter = 3411,
        tip = "The fireplace in the burned house starts five waves before he appears. Begin at full mana because the waves come fast; he is a plain fight after that." },
      { name = "The Abandoned (optional event)", encounter = 3357,
        tip = "The statue in the courtyard starts three waves first. Interrupt or stun his Drain Life on the tank and expect Frost Nova on melee." },
      { name = "Bjork", encounter = 3412,
        tip = "Clear the undead along his path first, ghouls above all. While his green shield is up spells do nothing, so switch to physical attacks or wait it out." },
      { name = "Rath'mael", encounter = 3354,
        tip = "His Flamestrike lands on the tank: interrupt or stun the cast, otherwise melee step out and the tank moves him clear of the fire." },
      { name = "Lordaeron Captain (rare, may be absent)", encounter = 3408,
        tip = "He sometimes turns up in the west once the other bosses are dead. Only the Horde can fight him: pull him away from the ruins' patrols." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/ruins-of-lordaeron/quests/",
      "https://wowforeverinfo.com/guides/ruins-of-lordaeron/" } }, {
      note("Getting there", "From Kalimdor, ride the zeppelin from the tower north of Orgrimmar to Tirisfal Glades. The ruined capital sits right above the Undercity."),
      accept(92422, kristof, "Find Deathguard Kristof in Brill, east of the Undercity."),
      accept(95216, griffs, "In the Undercity, find Theodore Griffs in the Apothecarium."),
      accept(92421, morbin, "Morbin Lightbane waits in the Royal Quarter at the back of the city."),
      taxi("fly", ucFlights, "The Sepulcher, Silverpine Forest",
        "Fly to the Sepulcher from the bat handler in the Trade Quarter. Without that flight path, ride south-west out of Tirisfal."),
      accept(92401, tabitha, "Tabitha Heartweaver is worried about her son. Find her at the Sepulcher."),
      taxi("fly", sepulcherFlights, "Undercity, Tirisfal", "Fly back to the Undercity."),
      enter(name, uc("Ruins of Lordaeron portal", 71.4, 11.5),
        "Take an elevator up to the ruined city, pass through the outer gate and climb the stairs left of the keep to the portal."),
    }, {
      note("Intact limbs", "Every skeleton, berserker, flesh golem and necromancer can drop Intact Limbs. Loot them all as you go; you need 25."),
      uncertain(withItem(275521, accept(95204, nil, "If the Crest of Lordaeron turns up, use it from your bags to start the quest.")),
        "The crest has several reported spawn spots. Check near Bjork's tower, the ramparts and the crypts."),
      objective(95216, nil, "Find Witherfang on her alley patrol, kill her and loot the toxic strain.", "Highly Toxic Strain"),
      withItem(280438, accept(97288, nil, "The Baron drops the Abominable Head. Use it to start the quest.")),
      objective(92422, nil, "Make your way to the graveyard and kill Rath'mael.", "Rath'mael"),
      objective(92401, nil, "Look for Edward Heartweaver by the graves around Rath'mael and speak to him.",
        "Find Edward Heartweaver"),
      objective(92421, nil, "Finish the limb count on the remaining undead before you leave.", "25 Intact Limbs"),
    }, {
      finish(92422, kristof, "Leave the ruins and ride east to Brill."),
      finish(95204, oran, "Back in the Undercity, bring the crest to Oran Snakewrithe."),
      finish(95216, griffs),
      finish(97288, faranell, "Bring the head to Master Apothecary Faranell in the Apothecarium."),
      accept(97289, faranell),
      finish(97289, othmar, "Carry the head to Othmar's unfinished body on the lower floor of the Apothecarium."),
      accept(97290, othmar),
      finish(97290, faranell),
      accept(97291, faranell),
      uncertain(part(97291, 1, uc("Tawny Grisette", 65.19, 49.84),
        "Find Tawny Grisette, the mushroom vendor walking the Trade Quarter, for a Toxic Skullcap.", "Toxic Skullcap"),
        "Check whether the three ingredients are bought or handed over."),
      part(97291, 2, uc("Martha Alliestar", 54.0, 49.55),
        "Pick up Blisterweed beside Martha Alliestar, the herbalism trainer.", "Blisterweed"),
      part(97291, 3, uc("Ezekiel Graves", 75.2, 51.18),
        "Get the Essence of Agony from Ezekiel Graves, the poison vendor in the Rogues' Quarter.", "Essence of Agony"),
      finish(97291, faranell),
      accept(97292, faranell),
      withItem(281327, objective(97292, uc(nil, 45.28, 63.93),
        "Go upstairs above Othmar's body and use the Hissing Serum on the pipes there.", "Inject the Hissing Serum")),
      finish(97292, faranell),
      finish(92421, morbin),
      taxi("fly", ucFlights, "The Sepulcher, Silverpine Forest", "Fly to the Sepulcher with news of Edward."),
      finish(92401, tabitha),
    })
end

do
  local name = "Wailing Caverns"
  local tonga = ba("Tonga Runetotem", 52.26, 31.93)
  local bigglefuzz = ba("Crane Operator Bigglefuzz", 63.09, 37.61)
  local sputtervalve = ba("Sputtervalve", 62.98, 37.22)
  local nalpak = ba("Nalpak", 45.99, 35.66)
  local ebru = ba("Ebru", 46.01, 35.74)
  local falla = ba("Falla Sagewind", 48.18, 32.78)
  local zamah = tb("Apothecary Zamah", 22.81, 20.89)
  local hamuul = tb("Arch Druid Hamuul Runetotem", 78.62, 28.56)
  local nara = tb("Nara Wildmane", 75.65, 31.61)
  q(870, "The Forgotten Pools", 13, 10)
  q(877, "The Stagnant Oasis", 16, 10, 870)
  q(880, "Altered Beings", 16, 10, 877)
  q(1489, "Hamuul Runetotem", 16, 12, 880)
  q(1490, "Nara Wildmane", 16, 12, 1489)
  q(914, "Leaders of the Fang", 22, 11, 1490)
  q(962, "Serpentbloom", 18, 14)
  q(865, "Raptor Horns", 18, 13)
  q(1491, "Smart Drinks", 18, 13, 865)
  q(959, "Trouble at the Docks", 18, 14)
  q(1486, "Deviate Hides", 17, 13)
  q(1487, "Deviate Eradication", 21, 15)
  fromItem(6981, 10441, "The Glowing Shard", 26, 15)
  q(3369, "In Nightmares", 25, 15, 6981)
  add({ id = "dungeon-wailing-caverns", title = name, zone = m.barrens, levels = { 17, 25 }, instanceID = 43,
    bosses = {
      { name = "Kresh", encounter = 587, npc = 3653,
        tip = "This turtle wanders the first river. His armor slows physical damage, but he only bites, so it is a plain tank fight." },
      { name = "Lady Anacondra", encounter = 585, npc = 3671,
        tip = "Pull her away from the nearby Druids of the Fang and raptors. Interrupt her Sleep and Healing Touch; melee mind her thorns." },
      { name = "Lord Cobrahn", encounter = 586, npc = 3669,
        tip = "Kill his pythons quickly. Interrupt Druid's Slumber first and Healing Touch second; he turns into a serpent near death." },
      { name = "Deviate Faerie Dragon (rare, may be absent)", npc = 5912,
        tip = "Kill the two Druids of the Fang with it first, since their sleep is the real danger." },
      { name = "Lord Pythas", encounter = 588, npc = 3670,
        tip = "Stun and kill his Druid of the Fang and Shambler first. Interrupt his sleep and heals; his Thunderclap slows everyone in melee." },
      { name = "Skum", encounter = 589, npc = 3674,
        tip = "Spread out so his chained lightning hits fewer people, and kill him quickly." },
      { name = "Lord Serpentis", encounter = 590, npc = 3673,
        tip = "Kill his two Druids of the Fang first, then interrupt his sleep and heals like the other Fanglords." },
      { name = "Verdan the Everliving", encounter = 591, npc = 5775,
        tip = "He hits the tank very hard and roots the whole group with vines, so healers stay in range and keep the tank full." },
      { name = "Mutanus the Devourer", encounter = 592, npc = 3654,
        tip = "After the four Fanglords, clear the path and escort the Disciple from the entrance; waves attack before Mutanus. Ranged stay back from his stun, and be ready to break fear and sleep." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/wailing-caverns/quests/",
      "https://www.method.gg/wow-forever/dungeons/wailing-caverns" } }, {
      accept(870, tonga, "Find Tonga Runetotem in the Crossroads. His druid chain leads to the Fanglords."),
      objective(870, ba("The Forgotten Pools", 45.06, 22.54),
        "Ride north-west to the Forgotten Pools and wade into the water to look around.", "Explore the Forgotten Pools"),
      finish(870, tonga),
      accept(877, tonga),
      taxi("fly", crossroadsFlights, "Ratchet, The Barrens", "Fly to Ratchet on the east coast."),
      accept(865, mebok, "Mebok Mizzyrix stands near the inn in Ratchet."),
      accept(959, bigglefuzz, "Bigglefuzz runs the crane on the Ratchet docks."),
      objective(877, ba("The Stagnant Oasis", 55.61, 42.75),
        "Ride west to the Stagnant Oasis and walk to the edge of the murky water.", "Investigate the Stagnant Oasis"),
      objective(865, ba("Sunscale raptors", 52.0, 46.5),
        "Kill Sunscale Scytheclaws in the grass south-west of the oasis for their horns.", "5 Intact Raptor Horns"),
      action("goto", tonga, "Ride north to the Crossroads."),
      finish(877, tonga),
      accept(880, tonga),
      objective(880, ba("Lushwater Oasis", 46.68, 39.69),
        "Kill Oasis Snapjaws in the Lushwater Oasis south-west of the Crossroads for their shells.", "8 Altered Snapjaw Shells"),
      finish(880, tonga),
      accept(1489, tonga),
      taxi("fly", crossroadsFlights, "Ratchet, The Barrens", "Fly back to Ratchet."),
      finish(865, mebok),
      accept(1491, mebok),
      taxi("fly", ratchetFlights, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
      accept(962, zamah, "Apothecary Zamah works in the Pools of Vision, under Spirit Rise."),
      finish(1489, hamuul, "Cross to Elder Rise and find Hamuul Runetotem."),
      accept(1490, hamuul),
      finish(1490, nara, "Nara Wildmane is a few steps from Hamuul."),
      accept(914, nara),
      taxi("fly", tbFlights, "Crossroads, The Barrens", "Fly back to the Crossroads and ride west to the Wailing Caverns."),
      action("goto", ba("Hill trail", 50.32, 35.44), "Take the path up the hill above the skull-shaped cave mouth. The disciples camp in the upper cave."),
      accept(1486, nalpak),
      accept(1487, ebru),
      objective(962, ba("Outer cave", 47.5, 33.4),
        "Pick Serpentbloom in the lower cave on the way in. You can finish the count inside.", "10 Serpentbloom"),
      objective(959, ba("Mad Magglish", 45.7, 33.6),
        "Look for Mad Magglish, a stealthed goblin in the outer cave, and take his bottle of port.", "99-Year-Old Port"),
      enter(name, ba("Wailing Caverns portal", 47.76, 34.86),
        "Follow the lower cave past the pools to the portal. Wait for the group before crossing.",
        { { 46.0, 36.5 }, { 46.2, 34.96 }, { 45.91, 33.29 }, { 46.12, 32.53 }, { 47.29, 32.86 } }),
    }, {
      objective(1487, nil, "Clear both branches of the river for all four kinds of deviate. Ravagers and vipers come early; shamblers and dreadfangs deeper in.",
        "7 Deviate Ravagers", "7 Deviate Vipers", "7 Deviate Shamblers", "7 Deviate Dreadfangs"),
      objective(1486, nil, "Skin or loot hides from the deviates as you clear.", "20 Deviate Hides"),
      objective(1491, nil, "Loot Wailing Essence from the ectoplasm oozes.", "6 Wailing Essence"),
      objective(962, nil, "Finish picking Serpentbloom along the cave floors.", "10 Serpentbloom"),
      objective(914, nil, "Kill all four Fanglords for their gems: Anacondra and Cobrahn on the west side, Pythas and Serpentis to the east.",
        "Gem of Cobrahn", "Gem of Anacondra", "Gem of Pythas", "Gem of Serpentis"),
      note("Wake Naralex", "With the Fanglords dead, return to the Disciple at the entrance as a group and escort him to Naralex. Hold through the waves, then kill Mutanus."),
      withItem(10441, accept(6981, nil, "Use the Glowing Shard that Mutanus drops.")),
    }, {
      finish(1486, nalpak, "Climb back to the upper cave above the entrance."),
      finish(1487, ebru),
      action("goto", ratchetFlights, "Head to Ratchet. Fly from the Crossroads if you have the flight path."),
      finish(1491, mebok),
      finish(959, bigglefuzz),
      objective(6981, sputtervalve, "Show the shard to Sputtervalve on the docks.", "Speak with someone in Ratchet"),
      taxi("fly", ratchetFlights, "Crossroads, The Barrens", "Fly to the Crossroads and ride back toward the caverns."),
      finish(6981, falla, "Falla Sagewind waits on the ridge above the Wailing Caverns."),
      accept(3369, falla),
      taxi("fly", crossroadsFlights, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
      finish(914, nara),
      finish(3369, hamuul),
      finish(962, zamah),
    })
end

do
  local name = "Shadowfang Keep"
  local belDugur = uc("Keeper Bel'dugur", 53.74, 54.46)
  local hadrec = B.at("High Executor Hadrec", 43.42, 40.86, m.silverpine)
  local dalar = B.at("Dalar Dawnweaver", 44.2, 39.81, m.silverpine)
  q(1013, "The Book of Ur", 26, 16)
  q(1098, "Deathstalkers in Shadowfang", 25, 18)
  q(1014, "Arugal Must Die", 27, 18)
  add({ id = "dungeon-shadowfang-keep", title = name, zone = m.silverpine, levels = { 22, 30 }, instanceID = 33,
    bosses = {
      { name = "Rethilgore", encounter = 2748, npc = 3914,
        tip = "Kill his adds first and stun him when you can. Soul Drain stuns and drains one player, so heal through it." },
      { name = "Razorclaw the Butcher", encounter = 2749, npc = 3886,
        tip = "Clear his helpers first, then tank him in the kitchen. His Butcher Drain saps one player; keep that player healed." },
      { name = "Baron Silverlaine", encounter = 2750, npc = 3887,
        tip = "Veil of Shadow cuts healing on the tank by 75 percent for 15 seconds. Pull him with few adds and use stuns and cooldowns while it is up." },
      { name = "Commander Springvale", encounter = 2751, npc = 4278,
        tip = "Kill the Wailing Guardsman first to stop its silences. Interrupt his Holy Light and wait out his Divine Shield." },
      { name = "Odo the Blindwatcher", encounter = 2752, npc = 4279,
        tip = "Kill his bats first and face them away from the group. Odo grows stronger the longer the fight lasts, so burn him." },
      { name = "Deathsworn Captain (rare, may be absent)", npc = 3872,
        tip = "Pull him without trash and face his cleave away from the group." },
      { name = "Fenrus the Devourer", encounter = 2753, npc = 4274,
        tip = "Cleanse his Toxic Saliva when you can; otherwise it is a tank fight against heavy hits." },
      { name = "Wolf Master Nandos", encounter = 2754, npc = 3927,
        tip = "Killing his wolves brings him in. Kill the worgs he summons as they appear, then the boss." },
      { name = "Archmage Arugal", encounter = 2755, npc = 4275,
        tip = "Break line of sight behind the room's pillars to dodge Void Bolt, and follow him when he teleports. Crowd control a player he takes over until the curse ends." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/shadowfang-keep/quests/",
      "https://www.zockify.com/forever/dungeons/shadowfang-keep/" } }, {
      accept(1013, belDugur, "Find Keeper Bel'dugur in the Apothecarium in the Undercity."),
      taxi("fly", ucFlights, "The Sepulcher, Silverpine Forest", "Fly to the Sepulcher."),
      accept(1098, hadrec, "High Executor Hadrec stands inside the Sepulcher."),
      accept(1014, dalar),
      enter(name, B.at("Shadowfang Keep", 45.4, 67.6, m.silverpine),
        "Follow the road south past Pyrewood Village and climb the hill to the keep gate. Enter with your group."),
    }, {
      note("Prison and courtyard", "Clear Rethilgore's cells first. Freeing the Deathstalker prisoner there opens the courtyard door for the group."),
      finish(1098, nil, "Find Deathstalker Vincent lying wounded in the courtyard beyond the door and speak to him."),
      note("Keep route", "Go through the stables and the dining hall, then up the stairs past Springvale and Odo to the upper halls."),
      objective(1013, nil, "Look for the Book of Ur on a bookshelf in Fenrus's round room.", "The Book of Ur"),
      objective(1014, nil, "Climb to the top of the keep, defeat Archmage Arugal and take his head.", "Head of Arugal"),
    }, {
      finish(1014, dalar, "Back at the Sepulcher, give Arugal's head to Dalar Dawnweaver."),
      taxi("fly", sepulcherFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
      finish(1013, belDugur),
    })
end

do
  local name = "Blackfathom Deeps"
  local tsunaman = B.at("Tsunaman", 47.36, 64.25, m.stonetalon)
  local jeneu = B.at("Je'neu Sancrea", 11.56, 34.29, m.ashenvale)
  local bashana = tb("Bashana Runetotem", 71.06, 34.19)
  q(6562, "Trouble in the Deeps", 22, 17)
  q(6563, "The Essence of Aku'Mai", 22, 17, 6562)
  q(6921, "Amongst the Ruins", 27, 21)
  fromItem(6564, 16790, "Allegiance to the Old Gods", 22, 17)
  q(6565, "Allegiance to the Old Gods", 26, 17, 6564)
  q(6561, "Blackfathom Villainy", 27, 18)
  fromItem(6922, 16782, "Baron Aquanis", 30, 21)
  add({ id = "dungeon-blackfathom-deeps", title = name, zone = m.ashenvale, levels = { 25, 32 }, instanceID = 48,
    bosses = {
      { name = "Ghamoo-ra", encounter = 2916, npc = 4887,
        tip = "This turtle has very high armor, so casters and armor debuffs carry the fight. His Trample hits everyone around him." },
      { name = "Lady Sarevess", encounter = 2915, npc = 4831,
        tip = "Crowd control or kill her two naga first. Face her away from the group for Forked Lightning; she roots people with Frost Nova and shoots them." },
      { name = "Gelihast", encounter = 2914, npc = 6243,
        tip = "Clear the murlocs in his cave in small pulls first. His net roots one player, but he is otherwise easy." },
      { name = "Lorgus Jett", encounter = 2913, npc = 12902,
        tip = "A Twilight shaman with cultists around him, in one of two spots near the moonshrine. Pull the cultists first, then interrupt his casts." },
      { name = "Baron Aquanis (Horde quest)", npc = 12876,
        tip = "Only a Horde player can summon him at the Fathom Stone. Clear the area first and let the tank pull him before anyone attacks." },
      { name = "Twilight Lord Kelris", encounter = 2911, npc = 4832,
        tip = "Clear his room and pull the casters around the entrance wall. He Mind Blasts the tank and sleeps a random player, so dispel a sleeping healer fast." },
      { name = "Old Serra'kis", encounter = 2912, npc = 4830,
        tip = "He fights underwater with no special abilities. Kill him fast and watch your breath bar." },
      { name = "Aku'mai", encounter = 2910, npc = 4829,
        tip = "Light the four braziers in Kelris's room one at a time and clear each wave before the next. Move out of his poison clouds; healers focus the tank during his frenzy." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/blackfathom-deeps/quests/",
      "https://www.warcrafttavern.com/forever/guides/blackfathom-deeps/" } }, {
      accept(6562, tsunaman, "Find Tsunaman at Sun Rock Retreat in Stonetalon Mountains."),
      action("goto", jeneu, "Travel to Zoram'gar Outpost on the Ashenvale coast. Fly if you have the flight path; otherwise ride north out of Stonetalon and follow the shore west."),
      finish(6562, jeneu, "Find Je'neu Sancrea in Zoram'gar Outpost."),
      accept(6563, jeneu),
      accept(6921, jeneu),
      withItem(16790, accept(6564, B.at("Blackfathom shore", 13.3, 12.6, m.ashenvale),
        "Ride north along the coast to the sunken ruins. Kill Blackfathom Tide Priestesses until one drops a Damp Note, then read it.")),
      finish(6564, jeneu, "Bring the note back to Je'neu."),
      accept(6565, jeneu),
      objective(6563, B.at("Flooded tunnel", 13.4, 12.9, m.ashenvale),
        "Return to the ruins and swim into the flooded tunnel. Pry the blue sapphires off its walls on the way to the portal.",
        "20 Sapphires of Aku'Mai"),
      enter(name, B.at("Blackfathom Deeps portal", 14.12, 13.88, m.ashenvale),
        "Follow the tunnel to the portal and enter together."),
    }, {
      accept(6561, nil, "Past Ghamoo-ra, swim to the underwater alcove on the south-west side of the pool. Surface there and speak to Argent Guard Thaelrid."),
      objective(6565, nil, "Look for Lorgus Jett among the naga in the middle ruins. He moves around, so check each room.", "Lorgus Jett"),
      objective(6921, nil, "In the flooded chamber near the Moonshrine ruins, dive to the bottom and take the Fathom Core.", "Fathom Core"),
      uncertain(withItem(16782, accept(6922, nil, "Touching the Fathom Stone summons Baron Aquanis. Kill him and use the Strange Water Globe he drops.")),
        "Some Forever records list this as quest 909 with a higher minimum level. Check the offer when the globe drops."),
      objective(6561, nil, "Continue into Moonshrine Sanctum and loot Twilight Lord Kelris's head.", "Head of Kelris"),
      note("Aku'mai", "Aku'mai is optional for the quests. Light the four braziers in Kelris's room one at a time and rest between waves."),
    }, {
      finish(6565, jeneu, "Return to Zoram'gar Outpost."),
      finish(6563, jeneu),
      finish(6921, jeneu),
      finish(6922, jeneu),
      action("goto", bashana, "Travel to Thunder Bluff. Bashana Runetotem stands on Elder Rise."),
      finish(6561, bashana),
    })
end

do
  local name = "Razorfen Kraul"
  local auld = tb("Auld Stonespire", 35.97, 59.92)
  q(1109, "Going, Going, Guano!", 33, 30)
  q(1102, "A Vengeful Fate", 34, 29)
  q(1221, "Blueleaf Tubers", 26, 20)
  fromItem(6522, 17008, "An Unholy Alliance", 36, 28)
  q(1144, "Willix the Importer", 30, 23)
  add({ id = "dungeon-razorfen-kraul", title = name, zone = m.barrens, levels = { 30, 38 }, instanceID = 47,
    bosses = {
      { name = "Roogug", encounter = 2773, npc = 6168,
        tip = "Kill his Earth Rumbler first, and clear or crowd control the nearby quilboar before you pull." },
      { name = "Aggem Thorncurse", encounter = 2774, npc = 4424,
        tip = "The tank picks up his Boar Spirit when it appears. Interrupt his Chain Heal." },
      { name = "Death Speaker Jargba", encounter = 2775, npc = 4428,
        tip = "Kill the Razorfen Groundshaker and other adds first. If he mind controls a player, stun or sheep them and hold your area spells; stun him to stop his casts." },
      { name = "Overlord Ramtusk", encounter = 2776, npc = 4420,
        tip = "Crowd control his two Spearhide guards or kill them one at a time. His Thunderclap hits melee, so heal through it." },
      { name = "Agathelos the Raging", encounter = 2777, npc = 4422,
        tip = "Let the tank pull so his opening charge lands on the tank. Keep heals on the tank and expect an enrage near death." },
      { name = "Blind Hunter (rare, may be absent)", npc = 4425,
        tip = "Its Sonic Burst silences nearby players, so casters and healers stand at range." },
      { name = "Earthcaller Halmgar (rare, may be absent)", npc = 4842,
        tip = "Let the tank grab his Earth Rumbler before anyone else does, and step out of his Earthbind Totem." },
      { name = "Charlga Razorflank", encounter = 2778, npc = 4421,
        tip = "Pull her and step out of sight so she comes down from her hut. Interrupt Renew where you can; players low on health move apart from Chain Bolt." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/razorfen-kraul/quests/",
      "https://questing.wiki/wow-forever/dungeons/razorfen-kraul/" } }, {
      accept(1109, faranell, "At level 30, take Faranell's guano errand in the Apothecarium before leaving the Undercity."),
      action("boat", tirisfalTower, "Take the zeppelin to Durotar and travel on to Thunder Bluff."),
      accept(1102, auld, "Find Auld Stonespire west of the inn on Thunder Bluff's central mesa."),
      taxi("fly", tbFlights, "Ratchet, The Barrens", "Fly to Ratchet."),
      accept(1221, mebok),
      note("Snufflenose kit", "Take the Crate With Holes, the Command Stick and the Owner's Manual from beside Mebok, and read the manual before leaving."),
      taxi("fly", ratchetFlights, "Camp Taurajo, The Barrens", "Fly to Camp Taurajo. Without that flight path, ride south-west from Ratchet."),
      enter(name, ba("Razorfen Kraul approach", 42.9, 90.2),
        "Ride south from Camp Taurajo to the far end of the Barrens. West of the road, the thorny Razorfen path leads down to the Kraul portal."),
    }, {
      objective(1109, nil, "Kill Kraul Bats in the early tunnels until a pile of guano drops.", "Kraul Guano"),
      objective(1221, nil, "Once the bridges are clear, open the crate to call the gopher. Use the Command Stick on it at blueleaf patches to dig up tubers.",
        "6 Blueleaf Tubers"),
      objective(1102, nil, "Fight down to Charlga Razorflank's hut, defeat her and loot her heart.", "Razorflank's Heart"),
      withItem(17008, accept(6522, nil, "Use the Small Scroll that Charlga drops.")),
      uncertain(accept(1144, nil, "Find Willix the Importer in his pen near Charlga's area. Start the escort only when the party is ready."),
        "Published records give different minimum levels. Check Willix's offer."),
      objective(1144, nil, "Escort Willix back to the entrance and stop the quilboar that ambush him.", "Escort Willix out of the Kraul"),
      finish(1144, nil, "Speak to Willix at the entrance once he is safe."),
    }, {
      action("goto", mebok, "Travel back to Ratchet. Fly from Camp Taurajo or the Crossroads if you have the flight path."),
      finish(1221, mebok),
      taxi("fly", ratchetFlights, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
      finish(1102, auld),
      action("goto", faranell, "Travel to the Undercity: zeppelin from Durotar to Tirisfal Glades."),
      finish(1109, faranell),
      finish(6522, varimathras, "Varimathras waits in the Royal Quarter."),
    })
end
