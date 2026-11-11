-- Alliance dungeon detours. Quest and travel sources are in tools/audits/2026-11-09-dungeon-routes.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local m = B.maps
local at, q, accept, finish, action = B.at, B.q, B.accept, B.finish, B.action
local objective, withItem = B.objectiveAt, B.withItem
local barrens, tirisfal, silverpine, hillsbrad, undercity = 1413, 1420, 1421, 1424, 1458
local ashenvale, needles, feralas, orgrimmar = 1440, 1441, 1444, 1454

-- World-map scales from the same Forever UiMapAssignment reference as QuestData.lua.
route.extents[barrens] = { 10133.333, 6756.25 }
route.extents[tirisfal] = { 4518.75, 3012.5 }
route.extents[silverpine] = { 4200, 2800 }
route.extents[hillsbrad] = { 3200, 2133.333 }
route.extents[undercity] = { 959.375, 640.104 }
route.extents[ashenvale] = { 5766.666, 3843.75 }
route.extents[needles] = { 4400, 2933.333 }
route.extents[feralas] = { 6950, 4633.333 }
route.extents[orgrimmar] = { 1402.604, 935.417 }

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
end

local function note(name, text)
  return action("note", nil, text, { name = name })
end

local function enter(name, place, text)
  return action("dungeon", place, text, { name = name })
end

local function uncertain(step, text)
  step.uncertain = text
  return step
end

-- Reuse the same game quest IDs and guide metadata for prep already on an outdoor route.
-- The detour owns its phase and any text changes.
local function copySteps(sectionId, predicate)
  local copies = {}
  for _, section in ipairs(route.sections) do
    if section.id == sectionId then
      for _, step in ipairs(section.steps) do
        if predicate(step) then
          local copy = {}
          for key, value in pairs(step) do copy[key] = value end
          copy.optional, copy.dungeon = nil, nil
          copies[#copies + 1] = copy
        end
      end
      return copies
    end
  end
  error("dungeon prep section missing: " .. sectionId)
end

local function append(steps, more)
  for _, step in ipairs(more) do steps[#steps + 1] = step end
end

local function fromItem(id, item, level, min, name, forever)
  q(id, name, level, min, nil, forever)
  B.quest[id].startItem = item
end

local blizzard = "https://worldofwarcraft.blizzard.com/en-us/news/24301455/"

do
  local name = "Hall of Thanes"
  local farsen = at("Earthseer Farsen", 64.83, 58.44, m.dunMorogh)
  local highSeat = at("The High Seat", 44.37, 49.65, m.ironforge)
  local afadra = at("Afadra Dunwall", 33.23, 48.0, m.ironforge)
  local thom = at("Thom Filch", 32.18, 44.50, m.ironforge)
  local magni = at("King Magni Bronzebeard", 39.09, 56.20, m.ironforge)
  q(96393, "Old Ironforge Incursion", 16, nil, 96391, true)
  q(96394, "The Restless Dead", 15, nil, nil, true)
  q(96395, "An Ancient Grudge", 15, nil, nil, true)
  q(96403, "Important Heirlooms", 15, nil, nil, true)
  q(98423, "The Treaty of Understanding", 16, nil, nil, true)
  local prep = {
    uncertain(accept(96392, farsen, "Climb to Farsen's camp above Gol'Bolar Quarry. If he has no offer, check Beldin Steelgrill at the depot for his introduction."),
      "Check whether Farsen offers the watch directly to characters who did not level in Dun Morogh."),
    objective(96392, farsen, "Ask Farsen to share his far sight. Close the view once the quest updates.", "Farsen's Farsight"),
    finish(96392, farsen),
    accept(96390, farsen),
    objective(96390, at("Helm's Bed Lake", 77.6, 61.5, m.dunMorogh),
      "Clear and loot the Dark Iron Spies near Helm's Bed Lake. Keep the Dark Iron Map when it drops.", "10 Dark Iron Spies"),
    withItem(274268, accept(96391, at("Helm's Bed Lake", 77.6, 61.5, m.dunMorogh),
      "Use the Dark Iron Map from the spies.")),
    finish(96390, farsen),
    finish(96391, farsen),
    uncertain(accept(96393, farsen, "Take Farsen's dungeon quest after delivering the map."),
      "Check Farsen's current offer. Published sources confirm the map hand-in, with different accounts of the preceding spy quest."),
    action("goto", highSeat, "In Ironforge, enter the High Seat and take the ramp on the left down into Old Ironforge."),
    accept(96394, afadra, "Keep left in the chamber below the High Seat. Find Afadra up the stairs overlooking the entry gate."),
    accept(96403, thom, "Go down the spiral ramp to Thom by the bridge. Pick up his heirloom quest before crossing."),
    enter(name, at("Hall of Thanes portal", 27.98, 47.78, m.ironforge),
      "Meet your group at Thom's bridge. Cross it and take the portal below Old Ironforge."),
  }
  add({ id = "dungeon-hall-of-thanes", title = name, zone = m.ironforge, levels = { 13, 18 },
    instanceID = 3065, instance = "The Hall of Thanes",
    bosses = {
      { name = "Faldrim Anvilmar",
        tip = "Clear the ghosts around his tomb before he circles past. Dispel Anvilmar's Curse from the tank when you can; interrupting his Mind Blast helps but is optional." },
      { name = "Magmatus",
        tip = "Kill the Dark Iron Summoner first while the tank drags Magmatus away from the group. Ranged stay out of his fire pulses and healers watch everyone in melee." },
      { name = "Plunder",
        tip = "This stone golem patrols the hall after the Dark Iron pack. Tank him with your back to a wall so his knockback cannot throw anyone into other packs." },
      { name = "Durgen Dirgehammer",
        tip = "Clear the Dark Iron Looters in his chamber, then kill Durgen before his two stone golems. His fear lasts several seconds, so Tremor Totem or Fear Ward on the tank keeps the pull safe." },
    },
    sources = { blizzard, "https://dlonem.com/wow-forever/dungeons/hall-of-thanes/",
      "https://www.wowhead.com/tbc/news/the-hall-of-thanes-new-dungeon-walkthrough-for-wow-forever-382991" } },
    prep, {
      accept(96395, nil, "Take the quest from the Ghostly Attendant in the early halls before pulling Faldrim Anvilmar."),
      objective(96394, nil, "Kill the early ghosts and Faldrim in Anvilmar's Rest. Check Afadra's counts before leaving the first halls.",
        "15 Enraged Apparitions", "10 Tormented Souls", "Faldrim Anvilmar"),
      objective(96395, nil, "Clear the ghosts around the large tomb, then defeat Faldrim Anvilmar.", "Faldrim Anvilmar"),
      objective(96393, nil, "Follow the Dark Iron breach through the cavern and golem bridge to the Reliquary of Kings. Clear the side packs before Durgen fears the party, then loot his head.",
        "Durgen Dirgehammer's Head"),
      objective(96403, nil, "Open the Heirloom Coffers on candle-lit platforms as you go. Check the vaults in Durgen's round chamber for any heirlooms still needed.",
        "8 Dwarven Heirlooms"),
      accept(98423, nil, "Inspect the Treaty of Understanding tablet in a vault off Durgen's chamber before heading back."),
      finish(96395, nil, "Walk back to the Ghostly Attendant in the opening halls before leaving the instance."),
    }, {
      finish(96403, thom),
      finish(96394, afadra, "Backtrack up the ramp to Afadra before leaving Old Ironforge."),
      finish(96393, magni),
      finish(98423, magni),
    })
end

do
  local name = "Ruins of Lordaeron"
  local marcus = at("General Marcus Jonathan", 69.17, 82.72, m.stormwind)
  local nightingale = at("Orphan Matron Nightingale", 56.31, 53.99, m.stormwind)
  local dena = at("Lady Dena Kennedy", 69.2, 27.7, m.stormwind)
  local avette = at("Avette Fellwood", 73.22, 44.83, m.duskwood)
  q(95250, "Abominable Creatures", 21, 16, nil, true)
  fromItem(95195, 268535, 22, nil, "Bloodied Insignia", true)
  q(92415, "Remember That I Love You", 22, 15, nil, true)
  q(95161, "Remember That I Love You", 22, 15, 92415, true)
  fromItem(95189, 268579, 22, nil, "Crest of Lordaeron", true)
  add({ id = "dungeon-ruins-of-lordaeron", title = name, zone = tirisfal, levels = { 15, 20 }, instanceID = 2999,
    bosses = {
      { name = "Witherfang",
        tip = "Wait for her alley patrol and pull her alone at range; kill any broodlings that follow. Her poison on the tank can be cleansed but is not urgent." },
      { name = "The Baron",
        tip = "Tank him with your back to a wall and keep melee behind him. His knockout hits hard and stuns the tank, so keep the tank topped up and stun him when you can." },
      { name = "Viktor the Vile (optional event)",
        tip = "The fireplace in the burned house starts five waves before he appears. Begin at full mana because the waves come fast; he is a plain fight after that." },
      { name = "The Abandoned (optional event)",
        tip = "The statue in the courtyard starts three waves first. Interrupt or stun his Drain Life on the tank and expect Frost Nova on melee." },
      { name = "Bjork",
        tip = "Clear the undead along his path first, ghouls above all. While his green shield is up spells do nothing, so switch to physical attacks or wait it out." },
      { name = "Rath'mael",
        tip = "His Flamestrike lands on the tank: interrupt or stun the cast, otherwise melee step out and the tank moves him clear of the fire." },
    },
    sources = { blizzard, "https://wowforeverinfo.com/guides/ruins-of-lordaeron/",
      "https://forever-tavern.com/dungeons/ruins-of-lordaeron/" } }, {
      note("Alliance approach", "Meet at Southshore. Ride west into Silverpine, skirt the Sepulcher and head north into Tirisfal. Regroup before the ruined capital's gate. Watch for Forsaken guards and PvP."),
      enter(name, at("Ruins of Lordaeron portal", 72.01, 11.48, undercity),
        "Go through the ruined city's outer gate, turn left before the keep and take the stairs up to the portal. Stay with your group above the Undercity elevators."),
    }, {
      accept(95250, nil, "Speak to Captain Truman just inside the entrance on the left."),
      note("Insignia starter", "Loot the first Bloodied Insignia from undead and use it promptly. Further insignias count toward the collection quest."),
      uncertain(withItem(268535, accept(95195, nil, "Use the starter Bloodied Insignia from your bags.")),
        "Sources list both level 15 and level 16 for this offer. Check the starter item in your bags."),
      objective(95250, nil, "From the first streets, follow the east side to the bend where the Baron waits. Clear the space around him and loot his head.",
        "Head of the Baron"),
      accept(92415, nil, "Search the ground by the graves around Rath'mael for the crumpled paper or Blood-Stained Letter. Inspect it and accept the quest before leaving."),
      note("Crest search", "Look for the Crest near Bjork's tower, on the ramparts or around the nearby crypts."),
      uncertain(withItem(268579, accept(95189, nil, "Use the Crest of Lordaeron from your bags.")),
        "The crest has several reported spawn spots. Sources list both level 15 and level 16 for this offer."),
      objective(95195, nil, "Loot the rest of the insignias from undead after accepting the quest. Check the count before your group exits.",
        "10 Bloodied Insignias"),
      finish(95250, nil, "Return to Captain Truman at the entrance with the Baron's head."),
    }, {
      finish(95195, marcus, "Find General Marcus Jonathan by the entrance to Stormwind or on his patrol through the Trade District."),
      finish(92415, nightingale, "Bring the letter to the orphan matron near Cathedral Square."),
      accept(95161, nightingale, "Take the matron's follow-up for Avette Fellwood."),
      finish(95189, dena, "Find Lady Dena Kennedy in the library wing of Stormwind Keep."),
      finish(95161, avette, "Bring the letter to Avette Fellwood near Darkshire."),
    })
end

do
  local name = "The Deadmines"
  local moonbrook = at("Moonbrook mine entrance", 42.56, 71.74, m.westfall)
  local defias = { [65] = true, [132] = true, [135] = true, [141] = true,
    [142] = true, [155] = true, [166] = true, [214] = true }
  local explosives = { [92742] = true, [92744] = true, [92745] = true, [92747] = true,
    [92748] = true, [92749] = true, [92750] = true, [92751] = true, [92752] = true, [92753] = true }
  local prep = copySteps("westfall", function(step)
    return not step.dungeon and (defias[step.quest] or explosives[step.quest]
      or step.type == "accept" and (step.quest == 167 or step.quest == 168 or step.quest == 2040))
  end)
  -- These two quests use the uninstanced tunnels, so do them before zoning in.
  prep[#prep + 1] = action("goto", moonbrook,
    "Gather in Moonbrook and enter the large mine building together. Stay with your group on the ramps through the uninstanced tunnels.")
  append(prep, copySteps("westfall", function(step)
    return step.dungeon and step.type == "complete" and (step.quest == 167 or step.quest == 168)
  end))
  prep[#prep + 1] = enter(name, nil, "Continue through the tunnels past the undead and cross the instance portal with your group.")
  local inside = copySteps("westfall", function(step)
    return step.dungeon and (step.type == "complete" and step.quest ~= 92819
      and step.quest ~= 167 and step.quest ~= 168 or step.type == "accept" and step.quest == 373)
  end)
  for _, step in ipairs(inside) do
    if step.quest == 373 then
      step.startItem = 2874
      step.text = "Use the Unsent Letter from VanCleef's loot to start the chain into the Stockade."
    end
  end
  local after = copySteps("westfall", function(step)
    return step.dungeon and (step.type == "turnin" or step.quest == 92819 or step.type == "fly")
  end)
  add({ id = "dungeon-deadmines", title = name, zone = m.westfall, levels = { 17, 26 }, instanceID = 36, instance = "Deadmines",
    links = { "paladin-verigans-fist" },
    bosses = {
      { name = "Rhahk'Zor", npc = 644,
        tip = "Pull him back to the group with his two guards, or crowd control one of them. His slam stuns the tank for a few seconds, so healers stay ready." },
      { name = "Miner Johnson (rare, may be absent)", npc = 3586,
        tip = "Kill him before the miners around him. He lowers the tank's armor, so do not let the fight drag on." },
      { name = "Sneed's Shredder", npc = 642,
        tip = "Clear the lumber mill before pulling, as the Shredder's fear sends people into other packs. Sneed jumps out when it breaks and disarms the tank; kill him fast." },
      { name = "Gilnid", npc = 1763,
        tip = "Kill Gilnid before his goblin workers. His molten metal slows the target, which Blessing of Freedom removes." },
      { name = "Mr. Smite", npc = 646,
        tip = "Kill the two Blackguards with him first, since his stomp stuns the group while they hit. He changes weapons as his health drops, so save cooldowns for the end." },
      { name = "Captain Greenskin", npc = 647,
        tip = "Burn his low health companion first, then Greenskin, then the other two pirates. Face him away from the group for his cleave." },
      { name = "Edwin VanCleef", npc = 639,
        tip = "Kill his first two Blackguards quickly. A stun as he nears half health can stop him calling the next pair; loot the Unsent Letter for the Stockade." },
      { name = "Cookie", npc = 645,
        tip = "He waits on the ship. Pull him without extra pirates and keep damage high because he heals himself." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/deadmines/quests/",
      "https://bindonforever.com/dungeons/deadmines" } }, prep, inside, after)
end

do
  local name = "Wailing Caverns"
  local mebok = at("Mebok Mizzyrix", 62.37, 37.62, barrens)
  local bigglefuzz = at("Crane Operator Bigglefuzz", 63.09, 37.61, barrens)
  local nalpak = at("Nalpak", 45.99, 35.66, barrens)
  local ebru = at("Ebru", 46.01, 35.74, barrens)
  local sputtervalve = at("Sputtervalve", 62.98, 37.22, barrens)
  local falla = at("Falla Sagewind", 48.18, 32.78, barrens)
  local mathrengyl = at("Mathrengyl Bearwalker", 35.37, 8.4, m.darnassus)
  q(865, "Raptor Horns", 18, 13)
  q(1491, "Smart Drinks", 18, 13, 865)
  q(959, "Trouble at the Docks", 18, 14)
  q(1486, "Deviate Hides", 17, 13)
  q(1487, "Deviate Eradication", 21, 15)
  fromItem(6981, 10441, 26, 15, "The Glowing Shard")
  q(3370, "In Nightmares", 25, 15, 6981)
  add({ id = "dungeon-wailing-caverns", title = name, zone = barrens, levels = { 17, 25 }, instanceID = 43,
    bosses = {
      { name = "Kresh", npc = 3653,
        tip = "This turtle wanders the first river. His armor slows physical damage, but he only bites, so it is a plain tank fight." },
      { name = "Lady Anacondra", npc = 3671,
        tip = "Pull her away from the nearby Druids of the Fang and raptors. Interrupt her Sleep and Healing Touch; melee mind her thorns." },
      { name = "Lord Cobrahn", npc = 3669,
        tip = "Kill his pythons quickly. Interrupt Druid's Slumber first and Healing Touch second; he turns into a serpent near death." },
      { name = "Deviate Faerie Dragon (rare, may be absent)", npc = 5912,
        tip = "Kill the two Druids of the Fang with it first, since their sleep is the real danger." },
      { name = "Lord Pythas", npc = 3670,
        tip = "Stun and kill his Druid of the Fang and Shambler first. Interrupt his sleep and heals; his Thunderclap slows everyone in melee." },
      { name = "Skum", npc = 3674,
        tip = "Spread out so his chained lightning hits fewer people, and kill him quickly." },
      { name = "Lord Serpentis", npc = 3673,
        tip = "Kill his two Druids of the Fang first, then interrupt his sleep and heals like the other Fanglords." },
      { name = "Verdan the Everliving", npc = 5775,
        tip = "He hits the tank very hard and roots the whole group with vines, so healers stay in range and keep the tank full." },
      { name = "Mutanus the Devourer", npc = 3654,
        tip = "After the four Fanglords, clear the path and escort the Disciple from the entrance; waves attack before Mutanus. Ranged stay back from his stun, and be ready to break fear and sleep." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/wailing-caverns/quests/",
      "https://www.method.gg/wow-forever/dungeons/wailing-caverns" } }, {
      note("Alliance approach", "Use Ratchet as your hub. The Booty Bay boat reaches Ratchet. If walking in from Ashenvale, give Horde outposts and the Crossroads a wide berth."),
      accept(865, mebok),
      objective(865, at("Sunscale raptors", 43.36, 15.57, barrens),
        "Collect intact horns from Sunscale Scytheclaws in the northern Barrens.", "5 Intact Raptor Horns"),
      finish(865, mebok), accept(1491, mebok),
      accept(959, bigglefuzz),
      action("goto", at("Hill trail", 50.32, 35.44, barrens),
        "Take the hill trail above the skull-shaped entrance. Nalpak and Ebru are in the upper cave, separate from the lower passage to the portal."),
      accept(1486, nalpak), accept(1487, ebru),
      objective(959, at("Wailing Caverns outer tunnel", 45.69, 33.6, barrens),
        "Regroup in the lower cave and look for the stealthed Mad Magglish on the way to the portal.", "99-Year-Old Port"),
      enter(name, at("Wailing Caverns approach", 46.0, 36.5, barrens),
        "Follow the lower cave past the pools and across the bridge to the portal. Stay together through the uninstanced mobs."),
    }, {
      objective(1487, nil, "Clear both branches for all four deviate types. The river runs west toward the Pit of Fangs and east toward the Winding Chasm.",
        "7 Deviate Ravagers", "7 Deviate Vipers", "7 Deviate Shamblers", "7 Deviate Dreadfangs"),
      objective(1491, nil, "Loot Wailing Essence from the ectoplasms as you clear.", "6 Wailing Essence"),
      objective(1486, nil, "Loot hides from deviates on both sides of the caverns.", "20 Deviate Hides"),
      note("Wake Naralex", "Defeat Anacondra, Cobrahn, Pythas and Serpentis. Return to the Disciple at the entrance with the group, escort him to Naralex and defeat Mutanus after the waves. Loot the Glowing Shard."),
      withItem(10441, accept(6981, nil, "Use the Glowing Shard from Mutanus.")),
    }, {
      finish(1486, nalpak), finish(1487, ebru),
      finish(1491, mebok), finish(959, bigglefuzz),
      objective(6981, sputtervalve, "Show the shard to Sputtervalve on the Ratchet docks.", "Speak with someone in Ratchet"),
      finish(6981, falla, "Find Falla Sagewind on the ridge above the caverns."),
      accept(3370, falla, "Take the Nightmare Shard delivery to Darnassus."),
      finish(3370, mathrengyl, "Find Mathrengyl in the Cenarion Enclave."),
    })
end

do
  local name = "Shadowfang Keep"
  add({ id = "dungeon-shadowfang-keep", title = name, zone = silverpine, levels = { 22, 30 }, instanceID = 33,
    links = { "paladin-verigans-fist", "rogue-horn-of-xelthos", "warlock-orb-of-soranruk" },
    bosses = {
      { name = "Rethilgore", npc = 3914,
        tip = "Kill his adds first and stun him when you can. Soul Drain stuns and drains one player, so heal through it." },
      { name = "Razorclaw the Butcher", npc = 3886,
        tip = "Clear his helpers first, then tank him in the kitchen. His Butcher Drain saps one player; keep that player healed." },
      { name = "Baron Silverlaine", npc = 3887,
        tip = "Veil of Shadow cuts healing on the tank by 75 percent for 15 seconds. Pull him with few adds and use stuns and cooldowns while it is up." },
      { name = "Commander Springvale", npc = 4278,
        tip = "Kill the Wailing Guardsman first to stop its silences. Interrupt his Holy Light and wait out his Divine Shield." },
      { name = "Odo the Blindwatcher", npc = 4279,
        tip = "Kill his bats first and face them away from the group. Odo grows stronger the longer the fight lasts, so burn him." },
      { name = "Deathsworn Captain (rare, may be absent)", npc = 3872,
        tip = "Pull him without trash and face his cleave away from the group." },
      { name = "Fenrus the Devourer", npc = 4274,
        tip = "Cleanse his Toxic Saliva when you can; otherwise it is a tank fight against heavy hits." },
      { name = "Wolf Master Nandos", npc = 3927,
        tip = "Killing his wolves brings him in. Kill the worgs he summons as they appear, then the boss." },
      { name = "Archmage Arugal", npc = 4275,
        tip = "Break line of sight behind the room's pillars to dodge Void Bolt, and follow him when he teleports. Crowd control a player he takes over until the curse ends." },
    },
    sources = { "https://www.zockify.com/forever/dungeons/shadowfang-keep/",
      "https://questing.wiki/wow-forever/dungeons/shadowfang-keep/" } }, {
      note("Alliance approach", "Meet at Southshore and ride west through Hillsbrad. Give the Horde settlement at the Sepulcher room. Gather with the group on the road above Pyrewood Village."),
      enter(name, at("Shadowfang Keep", 45.4, 67.6, silverpine),
        "Follow the road uphill to the keep gate overlooking Pyrewood and enter together."),
    }, {
      note("Keep route", "Clear the cells and speak to the prisoner who can open the courtyard gate. Keep the group together in the stable and on the stairs. Follow the upper halls to Arugal."),
    }, {
      note("Class turn-ins", "If you brought a class quest, follow its linked route to hand it in. The Horn of Xelthos is a separate solo job."),
    })
end

do
  local name = "The Stockade"
  local motley = at("Motley Garmason", 49.67, 18.23, m.wetlands)
  local berton = at("Guard Berton", 21.17, 46.58, m.redridge)
  local millstipe = at("Councilman Millstipe", 71.92, 47.79, m.duskwood)
  local nikova = at("Nikova Raskol", 73.78, 54.65, m.stormwind)
  local baros = at("Baros Alexston", 57.74, 47.86, m.stormwind)
  local thelwater = at("Warden Thelwater", 51.49, 69.38, m.stormwind)
  q(303, "The Dark Iron War", 30, 25)
  q(378, "The Fury Runs Deep", 27, 22, 303)
  q(386, "What Comes Around...", 25, 22)
  q(377, "Crime and Punishment", 26, 22)
  q(388, "The Color of Blood", 26, 22)
  q(389, "Bazil Thredd", 22, 16, 373)
  q(391, "The Stockade Riots", 29, 16, 389)
  q(387, "Quell The Uprising", 26, 22)
  -- After the riots: the Stormwind chain that unmasks Lescovar, run straight after the Stockade.
  local shaw = at("Master Mathias Shaw", 78.31, 70.74, m.stormwind)
  local elling = at("Elling Trias", 66.03, 74.1, m.stormwind)
  local tyrion = at("Tyrion", 73.23, 35.58, m.stormwind)
  q(392, "The Curious Visitor", 29, 16, 391)
  q(393, "Shadow of the Past", 29, 16, 392)
  q(350, "Look to an Old Friend", 31, 16, 393)
  q(2745, "Infiltrating the Castle", 31, 16, 350)
  q(2746, "Items of Some Consequence", 31, 16, 2745)
  q(434, "The Attack!", 31, 16, 2746)
  q(394, "The Head of the Beast", 31, 16, 434)
  q(395, "Brotherhood's End", 31, 16, 394)
  q(396, "An Audience with the King", 31, 16, 395)
  B.quest[373].startItem = 2874
  add({ id = "dungeon-stockade", title = name, zone = m.stormwind, levels = { 22, 30 },
    instanceID = 34, instance = "Stormwind Stockade",
    bosses = {
      { name = "Targorr the Dread", npc = 1696,
        tip = "He can be in several cells along the first hall, with one to three prisoners. He enrages at low health, so save a stun for the end." },
      { name = "Kam Deepfury", npc = 1666,
        tip = "His Shield Slam stuns the tank briefly and his block chance spikes for a few seconds; let casters carry the damage then." },
      { name = "Hamhock", npc = 1717,
        tip = "Stun or interrupt his Chain Lightning, and purge his Bloodlust if you can. Slow his attacks with Thunder Clap or similar." },
      { name = "Bazil Thredd", npc = 1716,
        tip = "Keep ranged players back from his Smoke Bomb, which stuns everyone nearby. While the tank is stunned he turns on the next player on threat." },
      { name = "Bruegal Ironknuckle (rare, may be absent)", npc = 1720,
        tip = "A rare in the west wing with no special tricks. Pull him on his own." },
      { name = "Dextren Ward", npc = 1663,
        tip = "His shout fears everyone nearby, so pull him where feared players will not run into more cells. Tremor Totem helps." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/stockades/quests/",
      "https://www.icy-veins.com/wow-forever/the-stockade-quests" } }, {
      accept(386, berton, "Pick this up by the Lakeshire bridge when you are in Redridge."),
      accept(377, millstipe, "Find Millstipe in the Darkshire town hall."),
      accept(303, motley, "At level 25 or higher, check in with Motley at Dun Modr before heading into the Stockade."),
      objective(303, at("Dun Modr", 48.56, 16.64, m.wetlands),
        "Clear Dark Iron around Dun Modr and the south end of the Thandol Span. Pull apart the packs before crossing the bridge.",
        "15 Dark Iron Dwarves", "5 Dark Iron Tunnelers", "5 Dark Iron Saboteurs", "5 Dark Iron Demolitionists"),
      finish(303, motley), accept(378, motley),
      accept(388, nikova, "Find Nikova on her patrol in Old Town."),
      note("Bazil Thredd lead-in", "VanCleef's Unsent Letter starts the Stockade Riots chain. Open the Deadmines detour if you still need the letter. The other Stockade quests can be done separately."),
      withItem(2874, accept(373, nil, "Use VanCleef's Unsent Letter if you still have it in your bags.")),
      finish(373, baros), accept(389, baros),
      finish(389, thelwater), accept(391, thelwater), accept(387, thelwater),
      enter(name, thelwater, "Meet at the prison on the canal between the Mage Quarter and Cathedral Square. Go down past Thelwater to the portal."),
    }, {
      objective(386, nil, "Check the cells near the entrance for Targorr the Dread. Loot his head.", "Head of Targorr"),
      objective(378, nil, "Check the cells along the east wing for Kam Deepfury. Loot his head.", "Head of Deepfury"),
      objective(391, nil, "Go to the end of the east wing to find Bazil Thredd. Loot his head.", "Head of Bazil Thredd"),
      objective(377, nil, "Clear to the end of the west wing and loot Dextren Ward's hand.", "Hand of Dextren Ward"),
      objective(387, nil, "Check all three kill counters as you clear the cells.",
        "10 Defias Prisoners", "8 Defias Convicts", "8 Defias Insurgents"),
      objective(388, nil, "Loot bandanas from Defias throughout the prison.", "10 Red Wool Bandanas"),
    }, {
      finish(391, thelwater), accept(392, thelwater, "Take the warden's sealed description of Thredd's visitor."),
      finish(387, thelwater), finish(388, nikova),
      finish(392, baros), accept(393, baros),
      finish(393, shaw, "Climb to Shaw at the top of the SI:7 building in Old Town."), accept(350, shaw),
      finish(350, elling, "Elling Trias runs the cheese shop in the Trade District; he is upstairs."), accept(2745, elling),
      finish(2745, tyrion, "Find Tyrion in the garden courtyard of Stormwind Keep."), accept(2746, tyrion),
      objective(2746, at("Clara's farmhouse", 34.0, 57.2, m.elwynn),
        "Pick up two of Clara's apples from her farmhouse west of Goldshire. Bring 3 Silk Cloth too; buy it if you have none.",
        "2 Clara's Fresh Apples", "3 Silk Cloth"),
      finish(2746, tyrion, "In a group, every member hands in the apples before anyone accepts the next quest."),
      accept(434, tyrion),
      objective(434, tyrion, "Stay in the courtyard until Lescovar and Marzon finish talking (about two minutes), then kill both.",
        "Lord Gregor Lescovar", "Marzon the Silent Blade"),
      finish(434, elling), accept(394, elling),
      finish(394, shaw), accept(395, shaw),
      finish(395, baros), accept(396, baros),
      finish(396, at("Lady Katrana Prestor", 80.1, 38.17, m.stormwind), "Deliver the report in the throne room of Stormwind Keep."),
      finish(386, berton), finish(377, millstipe), finish(378, motley),
    })
end

do
  local name = "Blackfathom Deeps"
  local argos = at("Argos Nightwhisper", 36.24, 67.61, m.stormwind)
  local gerrig = at("Gerrig Bonegrip", 50.83, 5.62, m.ironforge)
  local gershala = at("Gershala Nightwhisper", 38.33, 43.04, m.darkshore)
  local manados = at("Argent Guard Manados", 55.24, 23.99, m.darnassus)
  local shaedlass = at("Dawnwatcher Shaedlass", 55.36, 25.03, m.darnassus)
  local selgorm = at("Dawnwatcher Selgorm", 56.16, 24.39, m.darnassus)
  q(3765, "The Corruption Abroad", 24, 18)
  q(971, "Knowledge in the Deeps", 23, 10)
  q(1275, "Researching the Corruption", 24, 18, 3765)
  q(1199, "Twilight Falls", 25, 20)
  q(1198, "In Search of Thaelrid", 24, 18)
  q(1200, "Blackfathom Villainy", 27, 18, 1198)
  add({ id = "dungeon-blackfathom-deeps", title = name, zone = ashenvale, levels = { 24, 32 }, instanceID = 48,
    links = { "paladin-verigans-fist", "warlock-orb-of-soranruk" },
    bosses = {
      { name = "Ghamoo-ra", npc = 4887,
        tip = "This turtle has very high armor, so casters and armor debuffs carry the fight. His Trample hits everyone around him." },
      { name = "Lady Sarevess", npc = 4831,
        tip = "Crowd control or kill her two naga first. Face her away from the group for Forked Lightning; she roots people with Frost Nova and shoots them." },
      { name = "Gelihast", npc = 6243,
        tip = "Clear the murlocs in his cave in small pulls first. His net roots one player, but he is otherwise easy." },
      { name = "Twilight Lord Kelris", npc = 4832,
        tip = "Clear his room and pull the casters around the entrance wall. He Mind Blasts the tank and sleeps a random player, so dispel a sleeping healer fast." },
      { name = "Old Serra'kis", npc = 4830,
        tip = "He fights underwater with no special abilities. Kill him fast and watch your breath bar." },
      { name = "Aku'mai", npc = 4829,
        tip = "Light the four braziers in Kelris's room one at a time and clear each wave before the next. Move out of his poison clouds; healers focus the tank during his frenzy." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/blackfathom-deeps/quests/",
      "https://www.warcrafttavern.com/forever/guides/blackfathom-deeps/" } }, {
      accept(3765, argos, "Take Argos's introduction before leaving Stormwind."),
      accept(971, gerrig, "Find Gerrig in the Hall of Explorers before crossing to Kalimdor."),
      finish(3765, gershala), accept(1275, gershala),
      accept(1199, manados), accept(1198, shaedlass),
      enter(name, at("Flooded ruins", 14.12, 13.88, ashenvale),
        "From Darkshore, approach the ruins on the north-west Ashenvale coast. Swim through the submerged opening, surface in the tunnel and follow it to the portal together."),
    }, {
      objective(971, nil, "Near Gamoo-ra in the Pool of Ask'ar, search underwater for the Pitted Iron Chest.", "Lorgalis Manuscript"),
      finish(1198, nil, "Swim to the underwater alcove on the south-west side of the pool. Surface and speak to Argent Guard Thaelrid."),
      accept(1200, nil, "Take Blackfathom Villainy from Thaelrid before killing Kelris."),
      objective(1200, nil, "Follow the path from the pool through the ruins into Moonshrine Sanctum and loot Kelris's head.", "Head of Kelris"),
      objective(1199, nil, "Loot Twilight Pendants from the cultists as you clear.", "10 Twilight Pendants"),
      objective(1275, nil, "Loot brain stems from the Blackfathom naga and Fallenroot satyrs.", "8 Corrupted Brain Stems"),
      note("Aku'mai", "After Kelris, have the group recover between altar flames. Open the route to Aku'mai by clearing the waves."),
    }, {
      finish(1275, gershala),
      finish(1199, manados), finish(1200, selgorm),
      finish(971, gerrig),
    })
end

do
  local name = "Excavation Site: Wetlands"
  local dorin = at("Dorin Songblade", 25.79, 46.44, m.redridge)
  local caitlin = at("Caitlin Grassman", 11.88, 58.82, m.wetlands)
  local james = at("James Halloran", 8.55, 55.74, m.wetlands)
  local rethiel = at("Rethiel the Greenwarden", 56.37, 40.40, m.wetlands)
  local whelgar = at("Prospector Whelgar", 38.81, 52.39, m.wetlands)
  local magellas = at("High Explorer Magellas", 69.6, 18.6, m.ironforge)
  q(98815, "Highland Hides", 28, nil, nil, true)
  q(95772, "Songblade Search", 31, 24, nil, true)
  q(95795, "Fallen in the Fen", 31, 24, 95772, true)
  q(95647, "Lost in the Thicket Things", 31, 24, nil, true)
  q(95809, "Heartwoven", 31, 24, 95647, true)
  q(95646, "Horrors in the Highland", 31, 24, 275, true)
  fromItem(95810, 270865, 31, 24, "Lost Relic Carry", true)
  q(98824, "Prehistoric Prism", 31, 24, 95810, true)
  local prep = {
    accept(95772, dorin, "Pick up the search for Daewyn when you are in Lakeshire."),
    accept(95647, caitlin, "Speak to Caitlin in Menethil Harbor about Ardin. If you picked up Seeking Caitlin in Astranaar, turn it in here first."),
    uncertain(accept(98815, james, "Check whether James offers Highland Hides. If he offers Young Crocolisk Skins first, collect four skins and return to him."),
      "Sources disagree on Young Crocolisk Skins and Daily Delivery. If James has no offer, check Einar Stonegrip near the east road (49.9, 39.4). The other dungeon quests can be done separately."),
  }
  append(prep, copySteps("wetlands", function(step)
    return step.quest == 276 or step.quest == 277 or step.quest == 275
  end))
  append(prep, {
    accept(95646, rethiel, "After Blisters on The Land, take Rethiel's quest for the Highland Horror."),
    action("goto", at("Uphill road", 53.27, 65.81, m.wetlands),
      "Take the uphill road south of Thelgen Rock. Follow it north-west up the ridge above Whelgar's outdoor dig site."),
    enter(name, at("Excavation Site portal", 48.0, 56.4, m.wetlands),
      "Meet the group at the upper dig's portal. Whelgar's outdoor cave is a separate stop for the turn-in."),
  })
  add({ id = "dungeon-excavation-site", title = name, zone = m.wetlands, levels = { 26, 31 }, instanceID = 2998,
    links = { "seeking-caitlin" },
    bosses = {
      { name = "Saltspine",
        tip = "Clear a dry spot by the lake before pulling it. Dust Storm hurts and makes the tank miss, so keep ranged and healers away and let the tank build threat first." },
      { name = "Shadetooth",
        tip = "Clear the hidden raptors in the tall grass first, since its roar fears players into them. Kill its two Thicket Hunters, then save cooldowns for its enrage at low health." },
      { name = "Highland Horror (optional, Alliance quest)", npc = 260808,
        tip = "Only needed for Horrors in the Highland. Pull it away from the Oil Slimes and interrupt Wild Regeneration; its roots last a long time." },
      { name = "Relic Guardian",
        tip = "Clear nearby Dragonmaw, then use the Archival Panel to wake it. Tank it away from the edge, facing away from the group; ranged stay back from its stomp." },
    },
    sources = { blizzard, "https://questing.wiki/wow-forever/dungeons/",
      "https://wowforeverinfo.com/guides/excavation-site/",
      "https://www.warcrafttavern.com/forever/guides/excavation-site-wetlands-quests/",
      "https://www.wowhead.com/forever/quest=98815/highland-hides" } }, prep, {
      note("Lake and thicket", "Clear the crocolisks around the entry lake before Saltspine. Beyond the lake, pull raptors in small packs and clear space before Shadetooth's fear."),
      objective(98815, nil, "Loot hides from the Thicket raptors while clearing toward the lost dig.", "4 Thicket Raptor Hides"),
      finish(95772, nil, "Find Daewyn Songblade in the camp shelter after Shadetooth, near the Highland Horror."),
      accept(95795, nil, "Take the follow-up from Daewyn's remains before leaving the shelter."),
      objective(95646, nil, "Find the Highland Horror by the camp and Dragonmaw dig. Loot its rootcore before moving on.",
        "Horrible Rootcore"),
      objective(95647, nil, "Find Ardin Grassman on the ramp to the right before the Relic Guardian and speak to him.", "Learn what happened to Ardin"),
      finish(95647, nil, "Turn the search in to Ardin on the ramp."),
      accept(95809, nil, "Take Heartwoven from Ardin to carry back to Caitlin."),
      note("Relic Guardian", "Clear nearby Dragonmaw. Use the Archival Panel beside the Guardian only when the party is ready. Watch the knockback and loot the Titan Relic after the fight."),
      withItem(270865, accept(95810, nil, "Use the Titan Relic from the Relic Guardian.")),
    }, {
      finish(95810, whelgar, "Take the relic to Whelgar in the outdoor dig site's cave."),
      accept(98824, whelgar, "Take Whelgar's follow-up and check that he hands back the relic."),
      finish(95646, rethiel), finish(98815, james), finish(95809, caitlin),
      finish(98824, magellas, "Deliver the relic to Magellas in the Hall of Explorers."),
      finish(95795, dorin),
    })
end

do
  local name = "City of Dalaran"
  local andromath = at("High Sorcerer Andromath", 48.71, 87.62, m.stormwind)
  local shylamiir = at("Shylamiir", 31.50, 62.61, m.stormwind)
  local jacques = at("Emissary Jacques", 48.34, 60.04, hillsbrad)
  local modera = at("Image of Archmage Modera", 68.62, 45.13, silverpine)
  q(92489, "Power Overwhelming", 33, nil, nil, true)
  q(92456, "A Green Sample", 33, nil, nil, true)
  q(92432, "An Alarming Request", 33, nil, nil, true)
  q(92458, "Heart of Disruption", 33, nil, 92432, true)
  q(92457, "Starving Arcane", 33, nil, 92432, true)
  q(92459, "Friend of the Kirin Tor", 33, nil, 92458, true)
  add({ id = "dungeon-city-of-dalaran", title = name, zone = silverpine, levels = { 28, 33 },
    bosses = {
      { name = "Atrexis the Grave Knight",
        tip = "Kill the Kirin Tor Necromancers with him first; he keeps raising skeletons and disarms the tank. Purge Unholy Frenzy if you can." },
      { name = "Lyn the Ignored (optional, needs the Tome of Dalaran)",
        tip = "Summoned at a circle near the sewer exit. Remove Curse of Thorns from the tank and kill the skeletons she raises." },
      { name = "Arcane Anomaly",
        tip = "Stay close behind it so the rotating Focal Blast misses you. Its Arcane Bolt hits the tank hard." },
      { name = "Arcanic Enigma",
        tip = "Kill the two Mana Phantoms first and interrupt their Mana Burn. Ranged stay back from its silence, and dispel Manamorph." },
      { name = "Unstable Sentinel",
        tip = "Face its Arcing Smash away from the group. Ranged move out of Malfunction range; a stun before the cast stops it." },
      { name = "Fel Ancient",
        tip = "Speak to the mage at the barrier to open the square first. Leave the green Fel Timbers pools and use root breakers on Entangle." },
      { name = "Mana Devourer",
        tip = "Clear the whole Violet Hold room first. Debilitate drains everyone's mana, so kill it fast and keep heals on the tank." },
      { name = "Shade of the Archmage",
        tip = "Speak to Archmage Modera on the Violet Citadel steps for the portal. Dodge Bounding Mana going out and coming back; when the Shade runs dry it polymorphs the group and evocates, then the fight resumes." },
    },
    sources = { blizzard, "https://www.icy-veins.com/wow-forever/city-of-dalaran-guide",
      "https://wowf.io/en/dungeons/dalaran/guide" } }, {
      accept(92489, andromath, "Find Andromath at the top of the Wizard's Sanctum in Stormwind."),
      accept(92456, shylamiir, "Find Shylamiir in the Park before leaving Stormwind."),
      uncertain(accept(92432, jacques, "Speak with Emissary Jacques at Southshore. Plan to check his offer around level 30."),
        "Published quest minimums differ. Check Jacques's current offer before arranging a key run."),
      finish(92432, modera, "From Southshore, head west toward Dalaran. Speak to Modera's image near the lake-side entrance."),
      uncertain(accept(92458, modera, "Take Heart of Disruption from Modera. Accepting this quest supplies the Dalaran Sewer Key for the outside door."),
        "Check the current quest offer and group access at the door. Some Alliance routes reach the sewer through the city. Skyborne still need this quest for their own key."),
      accept(92457, modera),
      enter(name, at("Dalaran sewer approach", 69.28, 45.55, silverpine),
        "Meet at the shore by Modera's image. Use the sewer door with a key holder and follow the pipe to the group portal."),
    }, {
      note("Sewers and graveyard", "Follow the sewer into the graveyard, then take the cleared route into the city. Move with your group out of Arcane Anomaly's rotating blast."),
      objective(92489, nil, "Find the Arcanic Enigma on the city route. Clear the Mana Phantoms first and keep the healer clear of the silence.", "Arcanic Enigma"),
      objective(92456, nil, "Pick the Fel Infused Blossom near the Fel Ancient. Move off the green patches before stopping to loot.", "Fel Infused Blossom"),
      objective(92458, nil, "Continue to the Shade of the Archmage. Spread for the returning projectile and loot the Arcane Mote before leaving.",
        "Arcane Mote"),
      objective(92457, nil, "Check the construct kill counts before your group leaves the city.", "8 Seeking Remnants", "8 Saturated Remnants", "8 Mana Echoes"),
    }, {
      finish(92458, modera), finish(92457, modera),
      accept(92459, modera, "Take Modera's introduction to Archmage Celindra after the Arcane Mote hand-in."),
      finish(92459, nil, "Find Archmage Celindra at the Violet Citadel in the city."),
      finish(92489, andromath), finish(92456, shylamiir),
    })
end

do
  local name = "Gnomeregan"
  local sarno = at("Brother Sarno", 51.05, 48.39, m.stormwind)
  local shoni = at("Shoni the Shilent", 62.63, 34.11, m.stormwind)
  local mathiel = at("Mathiel", 59.51, 45.38, m.darnassus)
  local klockmort = at("Klockmort Spannerspan", 67.92, 46.10, m.ironforge)
  local overspark = at("Tinkmaster Overspark", 69.55, 50.33, m.ironforge)
  local gnoarn = at("Gnoarn", 69.18, 50.55, m.ironforge)
  local castpipe = at("Master Mechanic Castpipe", 69.83, 48.10, m.ironforge)
  local mekkatorque = at("High Tinker Mekkatorque", 68.75, 48.97, m.ironforge)
  local ozzie = at("Ozzie Togglevolt", 45.89, 49.39, m.dunMorogh)
  local gate = at("Gnomeregan lift approach", 24.29, 39.77, m.dunMorogh)
  local talvash = at("Talvash del Kissel", 36.38, 3.61, m.ironforge)
  q(2923, "Tinkmaster Overspark", 26, 20)
  q(2922, "Save Techbot's Brain!", 26, 20, 2923)
  q(2928, "Gyrodrillmatic Excavationators", 30, 20)
  q(2925, "Klockmort's Essentials", 30, 24)
  B.breadcrumb(2925, 2924)
  q(2924, "Essential Artificials", 30, 24)
  q(2927, "The Day After", 27, 20)
  q(2926, "Gnogaine", 27, 20, 2927)
  q(2962, "The Only Cure is More Green Glow", 30, 20, 2926)
  q(2930, "Data Rescue", 30, 25)
  q(2929, "The Grand Betrayal", 35, 25)
  q(2904, "A Fine Mess", 30)
  fromItem(2945, 9326, 34, 28, "Grime-Encrusted Ring")
  q(2947, "Return of the Ring", 34, 28, 2945)
  add({ id = "dungeon-gnomeregan", title = name, zone = m.dunMorogh, levels = { 29, 38 }, instanceID = 90,
    bosses = {
      { name = "Grubbis", npc = 7361,
        tip = "Help Blastmaster Emi Shortfuse seal the trogg caves; Grubbis arrives with Chomper at the end. Both hit hard, so stun them and kill one at a time." },
      { name = "Viscous Fallout", npc = 7079,
        tip = "Pull it away from patrols. Its nature hits ignore armor, so use attack power debuffs like Demoralizing Shout." },
      { name = "Electrocutioner 6000", npc = 6235,
        tip = "Spread out for Chain Bolt and face Megavolt away from the group. Loot his Workshop Key for the back door." },
      { name = "Crowd Pummeler 9-60", npc = 6229,
        tip = "Tank it against a hallway wall, facing away from the group, so Crowd Pummel cannot knock anyone off a ledge." },
      { name = "Dark Iron Ambassador (rare, may be absent)", npc = 6228,
        tip = "Clear patrolling Dark Irons first. His fire shield burns melee, so ranged do most of the damage." },
      { name = "Mekgineer Thermaplugg", npc = 7800,
        tip = "Give a ranged player the pillar buttons and walking bombs. Knock Away drops threat, so the tank taunts back quickly." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/gnomeregan/quests/",
      "https://www.icy-veins.com/wow-forever/gnomeregan-quests" } }, {
      accept(2923, sarno), accept(2928, shoni),
      accept(2925, mathiel, "If you are passing through Darnassus, take Mathiel's referral to Tinker Town."),
      finish(2925, klockmort), accept(2924, klockmort),
      finish(2923, overspark), accept(2922, overspark),
      accept(2927, gnoarn), accept(2930, castpipe), accept(2929, mekkatorque),
      finish(2927, ozzie), accept(2926, ozzie),
      action("goto", gate, "Head west from Kharanos and ride the Gnomeregan lift down. Work through the outer tunnels with help if needed."),
      objective(2922, nil, "Find Techbot in the halls before the instance portal and loot his core.", "Techbot's Memory Core"),
      note("First punch card", "Loot a White Punch Card in the outer tunnels. Exchange it at Matrix Punchograph 3005-A near the lift for a Yellow Punch Card."),
      withItem(9283, objective(2926, nil, "Use the empty phial on a living irradiated trogg in the outer tunnels.", "Full Leaden Collection Phial")),
      finish(2926, ozzie, "Return the first sample to Ozzie in Kharanos before the main run."),
      accept(2962, ozzie, "Take Ozzie's heavier phial for the sample inside the instance."),
      enter(name, gate, "Return to the Gnomeregan lift. Descend and follow the main passage to the front portal with your group."),
    }, {
      note("Second punch card", "Stay on the upper path to reach the Dormitory. Look for 3005-B on the lower level and trade yellow for blue."),
      withItem(9364, objective(2962, nil, "Use the heavy phial on a living Irradiated Slime inside the instance.", "High Potency Radioactive Fallout")),
      uncertain(accept(2904, nil, "Look for Kernobee near the Clean Zone. Agree on the escort with the party before starting it."),
        "Published records disagree on the minimum. Check Kernobee's offer in the instance."),
      objective(2904, nil, "Escort Kernobee to the Clockwerk Run exit and check for credit before leaving.", "Kernobee rescued"),
      withItem(9326, accept(2945, nil, "If a Grime-Encrusted Ring drops, use it. The Sparklematic is in the Clean Zone.")),
      finish(2945, nil, "Use the Sparklematic to clean the ring when passing through the Clean Zone."),
      accept(2947, nil, "Take the Alliance ring return from the Sparklematic."),
      note("Third punch card", "Look for 3005-C by Electrocutioner 6000 in the Launch Bay and trade blue for red."),
      objective(2930, nil, "Look for 3005-D on the lower level near Crowd Pummeler in the Engineering Labs. Trade red for prismatic.",
        "Prismatic Punch Card"),
      objective(2924, nil, "Open the Artificial Extrapolators as you go through the deeper halls.", "12 Essential Artificials"),
      objective(2928, nil, "Loot parts from mechanical enemies along the route.", "24 Robo-mechanical Guts"),
      objective(2929, nil, "Continue to Thermaplugg's chamber. Watch the bomb dispensers and defeat Thermaplugg.", "Mekgineer Thermaplugg"),
    }, {
      finish(2922, overspark), finish(2924, klockmort), finish(2930, castpipe), finish(2929, mekkatorque),
      finish(2947, talvash),
      finish(2962, ozzie), finish(2928, shoni),
      finish(2904, nil, "Report Kernobee's rescue to Scooty at the goblin transporter above Booty Bay."),
    })
end

do
  local name = "Razorfen Kraul"
  local mebok = at("Mebok Mizzyrix", 62.37, 37.62, barrens)
  local journal = at("Henrig Lonebrow", 30.73, 24.35, needles)
  local falfindel = at("Falfindel Waywarder", 89.64, 46.57, feralas)
  local treshala = at("Treshala Fallowbrook", 69.54, 67.75, m.darnassus)
  q(1221, "Blueleaf Tubers", 26, 20)
  fromItem(1100, 5791, 34, 29, "Lonebrow's Journal")
  q(1101, "The Crone of the Kraul", 34, 29, 1100)
  q(1142, "Mortality Wanes", 30, 25)
  q(1144, "Willix the Importer", 30)
  add({ id = "dungeon-razorfen-kraul", title = name, zone = barrens, levels = { 29, 38 }, instanceID = 47,
    links = { "warrior-fire-hardened-mail", "shaman-air-totem" },
    bosses = {
      { name = "Roogug", npc = 6168,
        tip = "Kill his Earth Rumbler first, and clear or crowd control the nearby quilboar before you pull." },
      { name = "Aggem Thorncurse", npc = 4424,
        tip = "The tank picks up his Boar Spirit when it appears. Interrupt his Chain Heal." },
      { name = "Death Speaker Jargba", npc = 4428,
        tip = "Kill the Razorfen Groundshaker and other adds first. If he mind controls a player, stun or sheep them and hold your area spells; stun him to stop his casts." },
      { name = "Overlord Ramtusk", npc = 4420,
        tip = "Crowd control his two Spearhide guards or kill them one at a time. His Thunderclap hits melee, so heal through it." },
      { name = "Agathelos the Raging", npc = 4422,
        tip = "Let the tank pull so his opening charge lands on the tank. Keep heals on the tank and expect an enrage near death." },
      { name = "Blind Hunter (rare, may be absent)", npc = 4425,
        tip = "Its Sonic Burst silences nearby players, so casters and healers stand at range." },
      { name = "Earthcaller Halmgar (rare, may be absent)", npc = 4842,
        tip = "Let the tank grab his Earth Rumbler before anyone else does, and step out of his Earthbind Totem." },
      { name = "Charlga Razorflank", npc = 4421,
        tip = "Pull her and step out of sight so she comes down from her hut. Interrupt Renew where you can; players low on health move apart from Chain Bolt." },
    },
    sources = { "https://questing.wiki/wow-forever/dungeons/razorfen-kraul/quests/",
      "https://questing.wiki/wow-forever/dungeons/razorfen-kraul/" } }, {
      accept(1221, mebok, "Take the tuber quest in Ratchet before travelling south."),
      note("Snufflenose supplies", "Take the Crate With Holes, Snufflenose Owner's Manual and Command Stick beside Mebok before leaving Ratchet."),
      action("goto", journal, "For the Crone chain, follow the Barrens road south. Look for Henrig's body near the Great Lift at the north end of Thousand Needles. Check your way down for Horde guards."),
      withItem(5791, accept(1100, journal, "Loot and read Henrig Lonebrow's Journal.")),
      finish(1100, falfindel, "Take the journal to Falfindel at Thalanaar on the Feralas border."),
      accept(1101, falfindel),
      enter(name, at("Razorfen Kraul approach", 42.9, 90.2, barrens),
        "Meet in the southern Barrens. Take the thorn-covered path west of the road to the Kraul portal."),
    }, {
      objective(1221, nil, "After Ramtusk, find a blueleaf patch on the hills near the bridges. Open the crate and use the stick to send the gopher digging.",
        "6 Blueleaf Tubers"),
      objective(1101, nil, "Defeat Charlga Razorflank and loot her medallion.", "Razorflank's Medallion"),
      accept(1142, nil, "Look for Heralath in a tent below Charlga's platform. Use the cleared path down."),
      objective(1142, nil, "Loot the remaining Razorfen quilboar for Treshala's pendant before leaving.", "Treshala's Pendant"),
      uncertain(accept(1144, nil, "Find Willix near the last boss's area. Start the escort only when the party is ready."),
        "Published records give different minimum levels. Check Willix's current offer."),
      objective(1144, nil, "Escort Willix back through the instance and clear the ambushes.", "Willix escorted"),
      finish(1144, nil, "Speak to Willix at the entrance after the escort gets credit."),
    }, {
      finish(1101, falfindel), finish(1221, mebok), finish(1142, treshala),
    })
end

do
  local name = "Scarlet Monastery: Graveyard"
  add({ id = "dungeon-scarlet-monastery-graveyard", title = name, zone = tirisfal, levels = { 30, 38 },
    links = { "rogue-eye-of-bhossca" },
    bosses = {
      { name = "Interrogator Vishas", npc = 3983,
        tip = "Kill his Scarlet guards first, then tank Vishas. It is a simple fight." },
      { name = "Ironspine (rare, may be absent)", npc = 6489,
        tip = "Pull him out of his poison clouds and decurse Curse of Weakness." },
      { name = "Fallen Champion (rare, may be absent)", npc = 6488,
        tip = "Face his cleave away from the group and keep melee behind him." },
      { name = "Azshir the Sleepless (rare, may be absent)", npc = 6490,
        tip = "Interrupt Soul Siphon, heal players marked by Call of the Grave before it expires, and clear his adds so a fear does not pull more." },
      { name = "Bloodmage Thalnos", npc = 4543,
        tip = "Clear the whole crypt first. Healer and ranged stand well back, and melee step away when he starts Flame Spike." },
    },
    sources = { "https://www.zockify.com/forever/dungeons/scarlet-monastery/",
      "https://bytetavern.com/wow-forever-dungeon-quests/#scarlet-monastery-quests-level-30-and-up" } }, {
      note("Alliance approach", "Travel together from Southshore through Silverpine. Give the Sepulcher, Undercity and Brill a wide berth on the way to the monastery in north-east Tirisfal."),
      enter(name, at("Scarlet Monastery approach", 82.65, 32.88, tirisfal),
        "Regroup outside the monastery stairs. Enter the common hall and take the Graveyard portal on the left."),
    }, {
      note("Graveyard run", "Clear around Interrogator Vishas, then continue through the courtyard to the crypt and Bloodmage Thalnos."),
    }, {
      note("Other wings", "The Eye of Bhossca is a separate Rogue route through other monastery wings. Open the linked class detour for its mail, disguise and objectives."),
    })
end

do
  local name = "Ragefire Chasm"
  add({ id = "dungeon-ragefire-chasm", title = name, zone = orgrimmar, levels = { 13, 18 }, instanceID = 389,
    bosses = {
      { name = "Oggleflint", npc = 11517,
        tip = "Pull his troggs a few at a time first, and face his cleave away from the group." },
      { name = "Taragaman the Hungerer", npc = 11520,
        tip = "Tank him in the middle of his platform so Uppercut cannot throw the tank into the lava. Fire Nova hits melee, so watch their health." },
      { name = "Jergosh the Invoker", npc = 11518,
        tip = "Kill Jergosh before his two adds. Dispel Immolate and Curse of Weakness when you can." },
      { name = "Bazzalan", npc = 11519,
        tip = "Kill Bazzalan first, then his two adds. Cure the poison on the tank." },
    },
    sources = { "https://www.warcrafttavern.com/forever/guides/ragefire-chasm",
      "https://www.warcrafttavern.com/forever/guides/ragefire-chasm-quests/" } }, {
      note("Alliance access", "The documented Ragefire Chasm quests are Horde-only. The portal is inside hostile Orgrimmar. Guards can overwhelm a low-level group before it reaches the Cleft of Shadow."),
      enter(name, at("Ragefire Chasm portal", 52.8, 49.6, orgrimmar),
        "If your group is making the trip, regroup outside the city. The portal is in the Cleft of Shadow by Neeru's tent."),
    }, {
      note("Lava cavern", "Stay on the ramps and cleared paths. Pull tightly packed enemies back to your group, then cross to Taragaman's platform in the main lava chamber."),
    })
end
