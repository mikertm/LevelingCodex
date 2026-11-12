-- Horde dungeon detours, levels 28-50. Source notes: tools/audits/2026-11-12-horde-dungeons-30-45.md.
-- Each guide is self-contained (its own pickups and lead-in chains); outdoor pickups are also
-- tagged on the leveling route (B.horde.dungeon) where the route passes their givers.
local B = LevelingCodexQuests.build
local H = B.horde
local route = LevelingCodexQuests.HORDE
local M, on = B.maps, B.on
local accept, finish, action, taxi, withItem = B.accept, B.finish, B.action, B.taxi, B.withItem
local objective, part, uncertain = B.objectiveAt, B.objectivePart, B.note
local qdb = "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever"

-- Steps that stay optional inside a guide: work on a quest picked up somewhere else, shown only
-- while that quest is in your log.
local carriedSteps = {}
local function carried(step)
  step.optional = true
  carriedSteps[step] = true
  return step
end

local function add(section, prepare, inside, after)
  section.side, section.category, section.verified = true, "dungeon", false
  section.steps = {}
  for _, group in ipairs({ { "prepare", prepare }, { "inside", inside }, { "after", after } }) do
    for _, step in ipairs(group[2] or {}) do
      -- A detour owns its steps: an outdoor route's optional or dungeon tag never carries over.
      step.phase, step.dungeon = group[1], nil
      if not carriedSteps[step] then step.optional = nil end
      section.steps[#section.steps + 1] = step
    end
  end
  route.sections[#route.sections + 1] = section
end

local function note(name, text, place)
  return action("note", place, text, { name = name })
end

-- `path`: { {x, y}, ... } the arrow follows, in order, to the portal (place).
local function enter(name, place, text, path)
  return action("dungeon", place, text, { name = name, path = path })
end

-- A quest whose prerequisite is turned in on another guide (Razorfen Kraul's guano or scroll):
-- the step shows only once that prerequisite is done.
local function once(pre, step)
  step.chain, step.ifDone = nil, pre
  return step
end

-- A pickup met somewhere along the run: the guide never stops on it and lists it as "On the way".
local function onTheWay(step)
  step.sticky = true
  return step
end

local function fromItem(id, item, name, level, min, prerequisite, forever)
  H.need(id, name, level, min, prerequisite, forever)
  B.quest[id].startItem = B.quest[id].startItem or item
end

-- The Alliance guide's boss list for the same instance, copied, with the client's encounter IDs
-- (tools/reference/forever.json quests.instances) added by name and any Horde-specific entry swapped.
local function bosses(id, encounters, swap)
  local list = {}
  for i, boss in ipairs(H.bosses(id)) do
    local copy = {}
    for key, value in pairs((swap or {})[boss.name] or boss) do copy[key] = value end
    local plain = copy.name:gsub(" %(.*$", "")
    copy.encounter = copy.encounter or (encounters or {})[plain]
    list[i] = copy
  end
  return list
end

local function og(name, x, y) return B.at(name, x, y, M.orgrimmar) end
local function uc(name, x, y) return B.at(name, x, y, M.undercity) end
local function tb(name, x, y) return B.at(name, x, y, M.thunderBluff) end

-- Shared places (QuestieDB Forever spawns).
local ogFlights = og("Doras", 45.12, 63.89)
local ucFlights = uc("Michael Garrett", 63.26, 48.55)
local tbFlights = tb("Tal", 47.0, 49.82)
local tmFlights = on.hillsbrad("Zarise", 60.1, 18.6)
local varimathras = uc("Varimathras", 56.25, 92.2)
local faranell = uc("Master Apothecary Faranell", 48.82, 69.28)
local sage = tb("Sage Truthseeker", 34.4, 46.87)
local durotarTower = B.at("Zeppelin tower", 50.8, 13.8, M.durotar)
local tirisfalTower = B.at("Zeppelin tower", 60.7, 58.8, M.tirisfal)
local toGromgol = B.at("Snurk Bucksquick", 50.7, 12.9, M.durotar)
local gromgolToOrgrimmar = on.stv("Nez'raz", 31.4, 29.9)
local gromgolFlights = on.stv("Thysta", 32.5, 29.4)
local bootyFlights = on.stv("Gringer", 26.9, 77.1)
local smDoor = on.tirisfal("Scarlet Monastery approach", 82.65, 32.88)
local smWay = "Leave the Undercity and ride east past Brill, then follow the roads north-east to the Scarlet Monastery in the far corner of Tirisfal Glades."

-- Roads the arrow uses for these guides (an earlier file's entry for the same pair wins).
do
  local scooty = on.stv("Scooty", 27.6, 77.48)
  H.road(M.stv, M.dunMorogh, scooty, "Use Scooty's transporter in Booty Bay (needs his Goblin Transponder)")
  H.road(M.dunMorogh, M.stv, on.dunMorogh("Transporter pad", 21.36, 37.14), "Step on the transporter pad back to Booty Bay")
  H.road(M.arathi, M.wetlands, on.arathi(nil, 43.4, 92.1), "Cross the Thandol Span south into the Wetlands")
  H.road(M.wetlands, M.arathi, on.wetlands(nil, 50.2, 13.6), "Cross the Thandol Span north into Arathi")
end

-- Gnomeregan. Nogg's Rig Wars and Sovik's errand open Scooty's transporter from Booty Bay.
do
  local name = "Gnomeregan"
  local nogg = og("Nogg", 75.99, 25.41)
  local sovik = og("Sovik", 75.49, 25.36)
  local scooty = on.stv("Scooty", 27.6, 77.48)
  local pad = on.dunMorogh("Transporter pad", 21.36, 37.14)
  H.need(2841, "Rig Wars", 35, 25)
  H.need(2842, "Chief Engineer Scooty", 35, 25)
  H.need(2843, "Gnomer-gooooone!", 35, 20, 2842)
  fromItem(2951, 9308, "The Sparklematic 5200!", 30, 25)
  H.need(2904, "A Fine Mess", 30, 24)
  fromItem(2945, 9326, "Grime-Encrusted Ring", 34, 28)
  H.need(2949, "Return of the Ring", 34, 28, 2945)
  H.need(2950, "Nogg's Ring Redo", 35, 28, 2949)
  local sovikStep = accept(2842, sovik, "Sovik works beside Nogg. He only offers his errand to Booty Bay while Rig Wars is in your log.")
  sovikStep.ifOnQuest = 2841
  add({ id = "dungeon-gnomeregan", title = name, zone = M.dunMorogh, levels = { 30, 38 }, instanceID = 90,
    instance = name, bosses = H.bosses("dungeon-gnomeregan"),
    sources = { "https://questing.wiki/wow-forever/dungeons/gnomeregan/quests/",
      "https://www.warcrafttavern.com/forever/guides/gnomeregan-quests/",
      "https://www.warcrafttavern.com/forever/guides/gnomeregan/", qdb } }, {
      accept(2841, nogg, "Find Nogg in his workshop in the Valley of Honor, Orgrimmar. Take Rig Wars first."),
      sovikStep,
      action("boat", toGromgol, "Leave Orgrimmar by the main gate and climb the zeppelin tower east of the city. Take the zeppelin to Grom'gol."),
      taxi("fly", gromgolFlights, "Booty Bay, Stranglethorn", "Fly to Booty Bay if you know the route. Otherwise ride south down the road to the port."),
      finish(2842, scooty, "Scooty works next to Gringer, the Booty Bay flight master."),
      accept(2843, scooty),
      objective(2843, scooty, "Wait while Scooty calibrates his transporter. Keep the Goblin Transponder he hands you.",
        "Goblin Transponder calibrated"),
      finish(2843, scooty),
      uncertain(action("goto", pad, "Step onto the transporter beside Scooty with the transponder in your bags. It sets you down in the tunnels outside Gnomeregan."),
        "Landing spot from QuestieDB's transporter pad (21.4, 37.1). If you lose the transponder, Scooty hands out another."),
      uncertain(enter(name, pad, "The portal is a short walk from the pad. Meet your group there and go in together."),
        "Check how far the portal is from the pad and which way to walk."),
    }, {
      note("Grime-Encrusted Objects", "Troggs and gnomes in the first halls drop Grime-Encrusted Objects. Keep one and three silver coins for the cleaning machine."),
      accept(2951, nil, "Take an object to the Sparklematic 5200 in the Clean Zone, south-west of the round hall. Stay on the upper level and put in three silver."),
      finish(2951, nil, "Take what the machine gives back."),
      onTheWay(uncertain(accept(2904, nil, "Kernobee waits in the Dormitory next to the Clean Zone. Start his escort only when the whole group is ready."),
        "Published minimum levels differ; check Kernobee's offer.")),
      objective(2904, nil, "Lead Kernobee out to the Clockwerk Run exit and keep him alive on the way.", "Kernobee rescued"),
      withItem(9326, accept(2945, nil, "Dark Iron Agents sometimes drop a Grime-Encrusted Ring. If one drops for you, use it.")),
      finish(2945, nil, "Clean the ring at the Sparklematic in the Clean Zone."),
      accept(2949, nil, "Take Return of the Ring from the machine to show the ring to Nogg."),
      objective(2841, nil, "Fight through the Launch Bay to Tinkers' Court and kill Mekgineer Thermaplugg for his safe combination. Then open Thermaplugg's Safe against the back wall of his room for the blueprints.",
        "Rig Blueprints", "Thermaplugg's Safe Combination"),
    }, {
      action("goto", scooty, "Leave through the portal and step on the transporter pad outside to return to Booty Bay."),
      finish(2904, scooty, "Tell Scooty that Kernobee is safe."),
      taxi("fly", bootyFlights, "Grom'gol, Stranglethorn", "Fly to Grom'gol, or ride north up the road."),
      action("boat", gromgolToOrgrimmar, "Take the zeppelin to Orgrimmar."),
      finish(2841, nogg, "Bring the blueprints and the combination to Nogg."),
      finish(2949, nogg, "Show Nogg the ring."),
      accept(2950, nogg, "For a better ring Nogg wants a Silver Bar, a Moss Agate and 30 silver. The auction house sells the bar and the agate."),
      finish(2950, nogg, "Give Nogg the bar, the agate and his fee."),
    })
end

-- Excavation Site: Wetlands (Forever dungeon). Hammerfall's Dragonmaw rumors and Borstan's raptor meat.
do
  local name = "Excavation Site: Wetlands"
  local borstan = og("Borstan", 57.2, 53.32)
  local zaruk = on.arathi("Zaruk", 74.54, 35.64)
  local urda = on.arathi("Urda", 73.0, 32.7)
  local span = on.arathi("Thandol Span", 43.4, 92.1)
  local portal = on.wetlands("Excavation Site portal", 48.0, 56.4)
  local agent = on.wetlands("Deathstalker Agent", 48.0, 56.4)
  local bashana = tb("Bashana Runetotem", 71.06, 34.19)
  local muln = on.mulgore("Muln Earthfury", 33.41, 22.58)
  H.need(95697, "Changing Tastes", 31, 24, nil, true)
  H.need(95663, "Dragonmaw Rumors", 31, 24, nil, true)
  H.need(95682, "Open the Maw", 31, 24, nil, true)
  fromItem(95664, 270866, "Elder Knowledge", 31, 24, nil, true)
  H.need(98823, "Earthen Echo", 31, 24, 95664, true)
  local meetAgent = uncertain(finish(95663, agent, "Climb the ridge to the upper dig. The Deathstalker Agent waits in the hills near the dungeon portal."),
    "QuestieDB has no spawn for the agent; the step points at the portal. Check where he stands.")
  meetAgent.path = { { 53.27, 65.81 } }
  add({ id = "dungeon-excavation-site", title = name, zone = M.wetlands, levels = { 28, 33 }, instanceID = 2998,
    instance = name,
    bosses = bosses("dungeon-excavation-site", nil, {
      ["Highland Horror (optional, Alliance quest)"] = { name = "Highland Horror (optional)", encounter = 3644, npc = 260808,
        tip = "No Horde quest needs it. If you fight it, pull it away from the Oil Slimes and interrupt Wild Regeneration; its roots last a long time." },
    }),
    sources = { "https://questing.wiki/wow-forever/dungeons/excavation-site-wetlands/",
      "https://www.wowhead.com/forever/npc=13155", qdb } }, {
      accept(95697, borstan, "Borstan, by his firepit in Orgrimmar, wants raptor meat from the Excavation Site."),
      action("boat", durotarTower, "Leave Orgrimmar and take the zeppelin to Tirisfal Glades from the tower east of the city."),
      taxi("fly", ucFlights, "Hammerfall, Arathi",
        "Fly to Hammerfall from the bat handler. Without that flight path, fly to Tarren Mill and ride east through Hillsbrad into Arathi."),
      accept(95663, zaruk, "Zaruk in Hammerfall has heard rumors about the Dragonmaw in the Wetlands."),
      action("goto", span, "Ride west across Arathi to the Thandol Span on its southern edge and cross the bridge into the Wetlands."),
      action("goto", on.wetlands(nil, 53.27, 65.81),
        "Follow the road south past the Dragonmaw camps. Near the south end, take the uphill road that climbs north-west toward the dig."),
      meetAgent,
      accept(95682, agent, "He wants the Dragonmaw inside the dig cleared."),
      enter(name, portal, "Meet your group at the portal of the upper dig and go in together."),
    }, {
      note("Lake and thicket", "Clear the crocolisks around the entry lake before Saltspine. Beyond the lake, pull the raptors in small packs and leave room for Shadetooth's fear."),
      objective(95697, nil, "Kill Thicket Lurkers, Hunters and Matriarchs in Stalker's Thicket for their meat.", "Thicket Raptor Meat"),
      objective(95682, nil, "Kill Dragonmaw Saboteurs and Warders around the lost dig, and loot the Dragonmaw Dispatch from a Thaumaturgist.",
        "Dragonmaw Saboteurs", "Dragonmaw Warders", "Dragonmaw Dispatch"),
      note("Relic Guardian", "Clear the Dragonmaw near the Guardian, then use the Archival Panel when the group is ready. Loot the Titan Relic after the fight."),
      withItem(270866, accept(95664, nil, "Use the Titan Relic from the Relic Guardian to start Elder Knowledge.")),
    }, {
      finish(95682, agent, "Leave the dungeon and report to the Deathstalker Agent outside."),
      action("goto", urda, "Ride north over the Thandol Span and back east across Arathi to Hammerfall."),
      taxi("fly", urda, "Undercity, Tirisfal", "Fly to the Undercity."),
      action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar from the tower north-west of the Undercity gate."),
      finish(95697, borstan, "Bring the raptor meat to Borstan."),
      taxi("fly", ogFlights, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff from Doras on the flight tower."),
      finish(95664, bashana, "Bashana Runetotem on the Elder Rise knows about titan relics."),
      accept(98823, bashana),
      uncertain(action("goto", muln, "Take the lift down from Thunder Bluff and climb to the Skywatcher Plateau, north-west of the bluffs."),
        "Muln's spot from QuestieDB (33.4, 22.6); the way up was not checked."),
      finish(98823, muln, "Give the relic to Muln Earthfury."),
    })
end

-- City of Dalaran (Forever dungeon). The Tarren Mill chain to the sewer, plus Undercity and Underbelly errands.
do
  local name = "City of Dalaran"
  local al = on.alterac
  local felben = uc("Doctor Martin Felben", 46.61, 74.09)
  local wordeen = on.hillsbrad("Magus Wordeen Voidglare", 61.6, 20.85)
  local melisara = on.hillsbrad("Melisara", 62.63, 20.65)
  local modera = al("Image of Archmage Modera", 14.3, 59.57)
  local celindra = al("Archmage Celindra", 14.15, 60.05)
  H.need(544, "Prison Break In", 34, 30)
  H.need(545, "Dalaran Patrols", 35, 30, 544)
  H.need(93680, "Key to the City", 33, nil, nil, true)
  H.need(92434, "Blood in the Streets", 34, nil, { 545, 93680 }, true)
  H.need(96984, "Heart of Disruption", 33, nil, 92434, true)
  H.need(97287, "Shrewd Negotiations", 33, nil, 96984, true)
  H.need(96986, "The Grave Knight", 33, 24, nil, true)
  H.need(96987, "Opportunistic Education", 33, 24, nil, true)
  H.need(96988, "Source of Power", 33, 24, nil, true)
  add({ id = "dungeon-city-of-dalaran", title = name, zone = M.alterac, levels = { 30, 36 }, instanceID = 2959,
    instance = name, bosses = H.bosses("dungeon-city-of-dalaran"),
    sources = { "https://questing.wiki/wow-forever/dungeons/city-of-dalaran/", qdb } }, {
      accept(96988, felben, "Doctor Martin Felben in the Apothecarium wants sentry cores from Dalaran."),
      taxi("fly", ucFlights, "Tarren Mill, Hillsbrad", "Fly to Tarren Mill from the bat handler."),
      accept(544, wordeen, "Magus Wordeen Voidglare, in a house in Tarren Mill, wants the bloodstones of four traitors."),
      accept(93680, wordeen, "He also wants the Dalaran Sewer Key."),
      accept(96986, melisara, "Melisara, a few steps away, wants Atrexis the Grave Knight dead."),
      action("goto", al(nil, 20.2, 84.3), "Ride west out of Tarren Mill into the Alterac Mountains, to the internment camp south of Dalaran."),
      part(544, 2, al("Ricter", 20.2, 84.3), "Kill Ricter, who walks around the camp, for his bloodstone.", "Bloodstone Marble"),
      part(544, 3, al("Alina", 20.3, 86.4), "Alina walks inside the buildings. Kill her for hers.", "Bloodstone Shard"),
      part(544, 1, al("Dermot", 19.9, 86.0), "Dermot is nearby, also inside.", "Bloodstone Wedge"),
      part(544, 4, al("Kegan Darkmar", 17.8, 83.2), "Kegan Darkmar is upstairs in the warden's building to the west. Kill Warden Belamoore first, using doorways to block her spells, then Kegan.",
        "Bloodstone Oval"),
      uncertain(objective(93680, al("Warden Belamoore", 17.8, 83.0), "Open the warden's footlocker inside the same building, on the way upstairs, for the Grimy Key.",
        "Grimy Key"), "Footlocker position not in QuestieDB; published notes place it on the stairs near Warden Belamoore."),
      action("goto", wordeen, "Ride back to Tarren Mill."),
      finish(544, wordeen),
      finish(93680, wordeen),
      accept(545, wordeen, "Next he wants the Dalaran patrols thinned."),
      action("goto", al(nil, 15.9, 76.3), "Ride back into the mountains, past the internment camp to the camps south-west of Dalaran."),
      objective(545, al(nil, 15.9, 76.3), "Kill Dalaran Summoners and their Elemental Slaves around these camps. More stand north-east of the dome.",
        "6 Dalaran Summoners", "12 Elemental Slaves"),
      action("goto", wordeen, "Ride back to Tarren Mill."),
      finish(545, wordeen),
      uncertain(accept(92434, wordeen, "Wordeen wants a way into Dalaran found along Lordamere Lake."),
        "Offered after Dalaran Patrols and Key to the City in published order; QuestieDB lists no prerequisite."),
      action("goto", modera, "Ride back into the mountains. Go around Dalaran's dome on its north side and follow the Lordamere Lake shore to the sewer outlet."),
      finish(92434, modera, "The Image of Archmage Modera stands by the sewer outlet on the shore."),
      accept(96984, modera),
      uncertain(enter(name, modera, "Meet your group here. Open the sewer door with the Dalaran Sewer Key and follow the pipe to the portal."),
        "Check who needs the key at the door: the Horde key comes with Key to the City."),
    }, {
      accept(96987, nil, "Rexxie Copperclutch waits near the entrance in the Underbelly and wants a book from the city."),
      objective(96986, nil, "Kill Atrexis the Grave Knight in the Circle of Wills, in the Underbelly. Kill his necromancers first.", "Atrexis the Grave Knight"),
      objective(96988, nil, "Kill Fragmented Sentries for their cores as you go.", "6 Cracked Sentry Cores"),
      objective(96987, nil, "Follow the east pipe and climb the ladder into the city. The Founding of Dalaran sits on a shelf in the Silver Enclave's library, past the portal room.",
        "The Founding of Dalaran"),
      objective(96984, nil, "Speak to the mage on top of the Violet Citadel to reach the Shade of the Archmage. Kill it and loot the Arcane Mote.", "Arcane Mote"),
      finish(96987, nil, "Bring the book back to Rexxie near the entrance."),
    }, {
      action("goto", wordeen, "Leave by the sewer and ride back to Tarren Mill."),
      finish(96986, melisara, "Tell Melisara the Grave Knight is dead."),
      finish(96984, wordeen, "Give Wordeen the Arcane Mote."),
      accept(97287, wordeen, "He sends you to Archmage Celindra."),
      action("goto", celindra, "Ride back to the lake shore by the sewer outlet."),
      uncertain(finish(97287, celindra, "Archmage Celindra stands near Modera's image."),
        "Celindra's spot from QuestieDB (14.2, 60.0); one published route hands this in right after the run."),
      action("goto", felben, "Travel to the Undercity: ride to Tarren Mill and fly, or ride north through Silverpine Forest."),
      finish(96988, felben, "Bring the sentry cores to Doctor Martin Felben."),
    })
end

-- Scarlet Monastery: Graveyard. Vorrel's ring and Faranell's hearts (after Razorfen Kraul's guano).
do
  local name = "Scarlet Monastery: Graveyard"
  local monika = on.hillsbrad("Monika Sengutz", 62.67, 18.88)
  local nancy = on.alterac("Nancy Vishas", 32.3, 32.8)
  H.need(1051, "Vorrel's Revenge", 33, 25)
  H.need(1113, "Hearts of Zeal", 33, 30, 1109)
  add({ id = "dungeon-scarlet-monastery-graveyard", title = name, zone = M.tirisfal, levels = { 30, 38 },
    instanceID = 189, instance = "Scarlet Monastery",
    links = { "dungeon-scarlet-monastery-library", "dungeon-scarlet-monastery-armory", "dungeon-scarlet-monastery-cathedral" },
    bosses = H.bosses("dungeon-scarlet-monastery-graveyard"),
    sources = { "https://questing.wiki/wow-forever/dungeons/scarlet-monastery/quests/", qdb } }, {
      once(1109, accept(1113, faranell, "If you brought Faranell her Kraul guano, she now wants hearts from the Scarlet Crusade.")),
      action("goto", smDoor, smWay),
      uncertain(enter(name, smDoor, "Climb the monastery steps into the entry hall. The Graveyard is the door on the left; wait for your group at its portal."),
        "Entrance position from the classic map; check it in game."),
    }, {
      accept(1051, nil, "Vorrel Sengutz lies on a table in the first chamber, beside Interrogator Vishas. Speak to him."),
      once(1109, objective(1113, nil, "Loot Hearts of Zeal from the Scarlet Crusade as you clear. More Scarlet troops camp outside the monastery.",
        "20 Hearts of Zeal")),
      note("Chapel and Vishas", "Clear the first chapel in small pulls; Scarlet casters run for help at low health. Interrogator Vishas waits in the room beyond."),
      note("Graveyard and crypt", "Pull the undead in the open graveyard one pack at a time and look for the rare spawns. Clear the crypt before Bloodmage Thalnos."),
    }, {
      action("goto", faranell, "Leave the monastery and ride back to the Undercity."),
      once(1109, finish(1113, faranell, "Give Faranell the hearts in the Apothecarium.")),
      taxi("fly", ucFlights, "Tarren Mill, Hillsbrad", "Fly to Tarren Mill."),
      action("goto", nancy, "Ride north into the Alterac Mountains. Nancy Vishas lives in a house north-west of the Ruins of Alterac."),
      uncertain(objective(1051, nancy, "Kill Nancy Vishas in her house and take Vorrel's wedding ring.", "Vorrel's Wedding Ring"),
        "Way in not checked; she is level 33, so bring help if you need it."),
      action("goto", monika, "Ride back south to Tarren Mill."),
      finish(1051, monika, "Give the ring to Monika Sengutz in Tarren Mill."),
    })
end

-- Scarlet Monastery: Library. Varimathras's leaders, the Compendium and Parqual's Test of Lore book.
do
  local name = "Scarlet Monastery: Library"
  local parqual = uc("Parqual Fintallas", 57.8, 65.42)
  H.need(1048, "Into The Scarlet Monastery", 42, 33)
  H.need(1049, "Compendium of the Fallen", 38, 28)
  H.limit(1049, { race = { "ORC", "TAUREN", "TROLL" } })
  H.need(1160, "Test of Lore", 36, 25, 1159)
  add({ id = "dungeon-scarlet-monastery-library", title = name, zone = M.tirisfal, levels = { 33, 40 },
    instanceID = 189, instance = "Scarlet Monastery",
    links = { "dungeon-scarlet-monastery-graveyard", "dungeon-scarlet-monastery-armory", "dungeon-scarlet-monastery-cathedral" },
    bosses = bosses("dungeon-scarlet-monastery-library", { ["Houndmaster Loksey"] = 446, ["Arcanist Doan"] = 447 }),
    sources = { "https://questing.wiki/wow-forever/dungeons/scarlet-monastery/quests/", qdb } }, {
      accept(1049, sage, "Orc, tauren and troll: Sage Truthseeker, inside a building on Thunder Bluff's central mesa, wants a book from the monastery library."),
      taxi("fly", tbFlights, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
      action("boat", durotarTower, "Take the zeppelin to Tirisfal Glades from the tower east of Orgrimmar."),
      accept(1048, varimathras, "Varimathras, in the Royal Quarter, wants four Scarlet leaders dead. Houndmaster Loksey is in the Library; the others are in the Armory and the Cathedral."),
      action("goto", smDoor, smWay),
      uncertain(enter(name, smDoor, "In the monastery's entry hall the Library is the second door. Regroup at its portal."),
        "Entrance position from the classic map; check it in game."),
    }, {
      part(1048, 4, nil, "Kill Houndmaster Loksey and his hounds in the first halls.", "Houndmaster Loksey"),
      carried(objective(1160, nil, "For Parqual's Test of Lore: Beginnings of the Undead Threat lies on a table in the first room on the left of the Gallery of Treasures.",
        "Beginnings of the Undead Threat")),
      objective(1049, nil, "In the Athenaeum at the end, follow the left wall to the bookcase holding the Compendium of the Fallen.", "Compendium of the Fallen"),
      note("The Scarlet Key", "After Arcanist Doan, open his strongbox behind him for The Scarlet Key. It opens the Armory and Cathedral doors; one key per group is enough."),
    }, {
      action("goto", parqual, "Ride back to the Undercity."),
      carried(finish(1160, parqual, "Bring the book to Parqual Fintallas on his bridge. He then asks you a question and later sends you to Dorn Plainstalker in Thousand Needles.")),
      finish(1048, varimathras, "Once Loksey, Herod, Mograine and Whitemane are dead, report to Varimathras. Until then, open the Armory or Cathedral guide."),
      action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar."),
      taxi("fly", ogFlights, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
      finish(1049, sage, "Bring the Compendium to Sage Truthseeker."),
    })
end

-- Scarlet Monastery: Armory. Herod for Into The Scarlet Monastery.
do
  local name = "Scarlet Monastery: Armory"
  add({ id = "dungeon-scarlet-monastery-armory", title = name, zone = M.tirisfal, levels = { 35, 42 },
    instanceID = 189, instance = "Scarlet Monastery",
    links = { "dungeon-scarlet-monastery-cathedral", "dungeon-scarlet-monastery-library" },
    bosses = bosses("dungeon-scarlet-monastery-armory", { ["Herod"] = 448 }),
    sources = { "https://questing.wiki/wow-forever/dungeons/scarlet-monastery/quests/", qdb } }, {
      accept(1048, varimathras, "If you don't carry it yet, take Into The Scarlet Monastery from Varimathras in the Royal Quarter."),
      note("The Scarlet Key", "The Armory door needs The Scarlet Key from Arcanist Doan's strongbox at the end of the Library. A rogue's lockpicking or an engineer's charge also opens it."),
      action("goto", smDoor, smWay),
      uncertain(enter(name, smDoor, "In the monastery's entry hall the Armory is the third door. Regroup at its portal."),
        "Entrance position from the classic map; check it in game."),
    }, {
      note("Armory run", "Clear the stables and the training yard, then the hall of arms. Plan where the group stands for the wave of trainees after Herod dies."),
      part(1048, 3, nil, "Kill Herod at the end of the hall of arms.", "Herod"),
    }, {
      action("goto", varimathras, "Ride back to the Undercity."),
      finish(1048, varimathras, "Once Loksey, Herod, Mograine and Whitemane are dead, report to Varimathras. Until then, open the Library or Cathedral guide."),
    })
end

-- Scarlet Monastery: Cathedral. Mograine and Whitemane end Into The Scarlet Monastery.
do
  local name = "Scarlet Monastery: Cathedral"
  local smEncounters = { ["High Inquisitor Fairbanks"] = 449, ["Scarlet Commander Mograine"] = 450,
    ["High Inquisitor Whitemane"] = 450 }
  add({ id = "dungeon-scarlet-monastery-cathedral", title = name, zone = M.tirisfal, levels = { 37, 44 },
    instanceID = 189, instance = "Scarlet Monastery",
    links = { "dungeon-scarlet-monastery-library", "dungeon-scarlet-monastery-armory", "dungeon-scarlet-monastery-graveyard" },
    bosses = bosses("dungeon-scarlet-monastery-cathedral", smEncounters),
    sources = { "https://questing.wiki/wow-forever/dungeons/scarlet-monastery/quests/", qdb } }, {
      accept(1048, varimathras, "If you don't carry it yet, take Into The Scarlet Monastery from Varimathras in the Royal Quarter."),
      note("The Scarlet Key", "The Cathedral door needs The Scarlet Key from Arcanist Doan's strongbox at the end of the Library. A rogue's lockpicking or an engineer's charge also opens it."),
      action("goto", smDoor, smWay),
      uncertain(enter(name, smDoor, "The Cathedral is the last door in the entry hall. Loksey and Herod are in the Library and Armory wings."),
        "Entrance position from the classic map; check it in game."),
    }, {
      note("Courtyard and nave", "Cross the courtyard; High Inquisitor Fairbanks waits behind a side door if you want him. Clear every pack in the nave before pulling Mograine."),
      part(1048, 2, nil, "Pull Scarlet Commander Mograine at the altar.", "Scarlet Commander Mograine"),
      part(1048, 1, nil, "Whitemane joins when Mograine falls and raises him. Kill them both.", "High Inquisitor Whitemane"),
    }, {
      action("goto", varimathras, "Ride back to the Undercity."),
      finish(1048, varimathras, "Once all four leaders are dead, report to Varimathras. Loksey is in the Library and Herod in the Armory."),
    })
end

-- Razorfen Downs. Andrew Brownell's skull, Myriam's outdoor count, Belnistrasz and Varimathras's follow-up.
do
  local name = "Razorfen Downs"
  local andrew = uc("Andrew Brownell", 74.05, 33.31)
  local myriam = on.barrens("Myriam Moonsinger", 49.01, 94.94)
  local omusa = on.barrens("Omusa Thunderhorn", 44.5, 59.1)
  H.need(3341, "Bring the End", 42, 37)
  H.need(6521, "An Unholy Alliance", 36, 28, 6522)
  add({ id = "dungeon-razorfen-downs", title = name, zone = M.barrens, levels = { 37, 42 }, instanceID = 129, instance = name,
    links = { "dungeon-razorfen-kraul" },
    bosses = bosses("dungeon-razorfen-downs", { ["Tuten'kash"] = 2780, ["Plaguemaw the Rotting"] = 2781,
      ["Mordresh Fire Eye"] = 2782, ["Ragglesnout"] = 2783, ["Glutton"] = 2784, ["Amnennar the Coldbringer"] = 2785 }),
    sources = { "https://questing.wiki/wow-forever/dungeons/razorfen-downs/quests/", qdb } }, {
      accept(3341, andrew, "From level 37, Andrew Brownell in the north-east of the Undercity wants Amnennar the Coldbringer's skull."),
      once(6522, accept(6521, varimathras, "If you gave Varimathras Charlga's scroll from Razorfen Kraul, he now wants Ambassador Malcin's head.")),
      action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar from the tower north-west of the Undercity gate."),
      taxi("fly", ogFlights, "Camp Taurajo, The Barrens", "Fly to Camp Taurajo."),
      action("goto", on.barrens(nil, 47.4, 89.0), "Ride south along the road toward the Great Lift. The Downs are the thorny mounds east of the road at the south end of the Barrens."),
      accept(6626, myriam, "Myriam Moonsinger waits at the foot of the path up to the Downs."),
      once(6522, objective(6521, on.barrens("Ambassador Malcin", 47.7, 92.3),
        "Ambassador Malcin appears at one of four tents around the Downs. Kill him and take his head.", "Ambassador Malcin's Head")),
      objective(6626, on.barrens(nil, 47.8, 92.3), "Kill Razorfen Battleguards, Thornweavers and Death's Head Cultists outside the dungeon. More camp to the north around 47, 89.",
        "8 Razorfen Battleguards", "8 Razorfen Thornweavers", "8 Death's Head Cultists"),
      finish(6626, myriam),
      enter(name, on.barrens("Razorfen Downs entrance", 49.3, 93.1), "Follow the thorn path up the mound to the portal and enter with your group."),
    }, {
      accept(3523, nil, "Take the left path and keep left to the Murder Pens. Open the Holding Pen and speak to Belnistrasz."),
      finish(3523, nil, "Hand his Oathstone back to Belnistrasz."),
      accept(3525, nil, "Clear the idol room first. Everyone accepts together when ready: the escort starts a few seconds later."),
      objective(3525, nil, "Protect Belnistrasz from the waves until his ritual ends. Pull adds off him at once; Plaguemaw comes late in the event.", "Idol extinguished"),
      finish(3525, nil, "Open Belnistrasz's Brazier for your reward."),
      objective(3341, nil, "Follow the paths to the top of the Downs and kill Amnennar the Coldbringer. Loot his skull.", "Skull of the Coldbringer"),
    }, {
      action("goto", omusa, "Ride north to Camp Taurajo."),
      taxi("fly", omusa, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
      action("boat", durotarTower, "Take the zeppelin to Tirisfal Glades from the tower east of Orgrimmar."),
      finish(3341, andrew, "Bring the skull to Andrew Brownell."),
      once(6522, finish(6521, varimathras, "Give Varimathras the ambassador's head.")),
    })
end

-- Uldaman. Kargath's reagent runs, the necklace chain between Orgrimmar and Kargath (two runs),
-- Badlands and Undercity errands, and the Platinum Discs to Thunder Bluff.
do
  local name = "Uldaman"
  local bl = on.badlands
  local patrick = uc("Patrick Garrett", 62.32, 48.61)
  local belDugur = uc("Keeper Bel'dugur", 53.74, 54.46)
  local dran = og("Dran Droffers", 59.49, 36.57)
  local bena = tb("Bena Winterhoof", 46.62, 33.17)
  local jarkal = bl("Jarkal Mossmeld", 2.42, 46.06)
  local rigglefuzz = bl("Rigglefuzz", 42.39, 52.93)
  local theldurin = bl("Theldurin the Lost", 51.39, 76.87)
  local dig = bl("Uldaman entrance", 42.4, 12.9)
  H.need(2342, "Reclaimed Treasures", 43, 33)
  H.need(2258, "Badlands Reagent Run", 39, 36)
  H.need(2202, "Uldaman Reagent Run", 42, 36, 2258)
  H.need(2418, "Power Stones", 36, 30)
  H.need(709, "Solution to Doom", 40, 30)
  H.need(728, "To the Undercity for Yagyin's Digest", 40, 30, 709)
  H.need(2283, "Necklace Recovery", 41, 37)
  H.need(2284, "Necklace Recovery, Take 2", 41, 37, 2283)
  H.need(2318, "Translating the Journal", 42, 37, 2284)
  H.need(2338, "Translating the Journal", 42, 37, 2318)
  H.need(2339, "Find the Gems and Power Source", 44, 37, 2338)
  H.need(2340, "Deliver the Gems", 44, 37, 2339)
  H.need(2341, "Necklace Recovery, Take 3", 44, 40, 2340)
  H.need(2278, "The Platinum Discs", 47, 40)
  H.need(2280, "The Platinum Discs", 47, 40, 2278)
  H.need(2440, "The Platinum Discs", 47, 40, 2280)
  local necklace = action("collect", bl("Shadowforge dig", 45.4, 11.4),
    "Kill Shadowforge dwarves at the dig site and in the caves behind it until one drops a Shattered Necklace.", { item = 7666 })
  necklace.unlessDone = 2283
  -- The necklace needs two runs: Jarkal's gem quest comes between them, so its objectives follow his
  -- steps. On the second entry the guide opens at its inside phase: this note (shown only while the gem
  -- quest is in your log) says what to pick up before the boss rows take over.
  local firstRun = note("First run", "This run is for the paladin's journal, the caps and the power stones. Clear as far as your group likes; you come back for the necklace gems.")
  firstRun.unlessDone = 2318
  local secondRun = note("Second run", "For Find the Gems and Power Source: the Topaz is in the Conspicuous Urn in Dig Two, the Ruby in the Shadowforge Cache in Dig Three, the Sapphire on Grimlok and the power source on Archaedas. Use the Discs of Norgannon behind Archaedas afterwards.")
  secondRun.ifOnQuest = 2339
  add({ id = "dungeon-uldaman", title = name, zone = M.badlands, levels = { 40, 47 }, instanceID = 70, instance = name,
    bosses = bosses("dungeon-uldaman", { ["Revelosh"] = 547, ["The Lost Dwarves"] = 548, ["Ironaya"] = 549,
      ["Obsidian Sentinel"] = 1887, ["Ancient Stone Keeper"] = 551, ["Galgann Firehammer"] = 552, ["Grimlok"] = 553,
      ["Archaedas"] = 554 }),
    sources = { "https://questing.wiki/wow-forever/dungeons/uldaman/quests/", qdb } }, {
      accept(2342, patrick, "Patrick Garrett, next to the Undercity bat handler, wants his family treasure from Uldaman."),
      taxi("fly", ucFlights, "Kargath, Badlands",
        "Fly to Kargath. Without that flight path, fly to Hammerfall, cross the Thandol Span and ride south through the Wetlands and Loch Modan into the Badlands."),
      accept(2258, jarkal, "Jarkal Mossmeld, upstairs in the Kargath building, wants Badlands reagents first."),
      part(2258, 3, bl("Lesser Rock Elementals", 21.7, 45.7), "Kill Lesser Rock Elementals east of Kargath for their shards.", "5 Rock Elemental Shards"),
      part(2258, 1, bl("Giant Buzzards", 15.5, 62.1), "Ride south and kill buzzards for their gizzards.", "5 Buzzard Gizzards"),
      part(2258, 2, bl("Elder Crag Coyotes", 12.8, 65.6), "Kill crag coyotes in the same hills for their fangs.", "10 Crag Coyote Fangs"),
      action("goto", jarkal, "Ride back north to Kargath."),
      finish(2258, jarkal),
      accept(2202, jarkal, "His next order is fungus caps from Uldaman."),
      action("goto", rigglefuzz, "Ride east across the Badlands to Rigglefuzz's camp."),
      accept(2418, rigglefuzz, "Rigglefuzz wants power stones from the Shadowforge dwarves."),
      accept(709, theldurin, "Ride south to Theldurin the Lost. He wants a tablet from Uldaman."),
      action("goto", dig, "Ride north to the dig site in the cliffs on the northern edge of the Badlands."),
      necklace,
      objective(709, nil, "In the outer caves, open the Ancient Chest near the Shadowforge camp for the Tablet of Ryun'eh.", "Tablet of Ryun'eh"),
      objective(2342, nil, "The Garrett Family Chest stands in the South Common Hall of the outer caves, south-west of the portal.", "Garrett Family Treasure"),
      note("Caps and stones", "Pick Magenta Cap Clusters along the cave walls and loot power stones from the Shadowforge as you go. You can finish both inside."),
      action("goto", dran, "Take the necklace to Orgrimmar: fly to Grom'gol or the Undercity and take the zeppelin."),
      accept(2283, dran, "Dran Droffers in his salvage shop buys the necklace."),
      finish(2283, dran),
      accept(2284, dran, "He wants to know what became of its gems."),
      action("goto", dig, "Travel back to the Uldaman dig: zeppelin to Tirisfal Glades or Grom'gol, then fly to Kargath and ride north."),
      enter(name, dig, "Meet your group at the dig. The portal is at the back of the outer caves."),
    }, {
      firstRun,
      finish(2284, nil, "From the first big room, take the second corridor on the right. The Remains of a Paladin lie among the enemies there."),
      accept(2318, nil, "Take the paladin's journal to be translated."),
      objective(2202, nil, "Pick Magenta Cap Clusters along the cave walls.", "12 Magenta Fungus Caps"),
      objective(2418, nil, "Loot Dentrium and An'Alleum Power Stones from the Shadowforge dwarves.",
        "8 Dentrium Power Stones", "8 An'Alleum Power Stones"),
      secondRun,
    }, {
      action("goto", jarkal, "Leave Uldaman and ride to Kargath."),
      finish(2318, jarkal),
      accept(2338, jarkal),
      finish(2338, jarkal, "Lend Jarkal the necklace and wait while he reads the journal."),
      accept(2339, jarkal, "He now knows where the gems and a power source are."),
      action("goto", dig, "Ride back to Uldaman with your group for the gems."),
      part(2339, 3, nil, "Topaz: in Dig Two, the room of the three dwarves, check the Conspicuous Urn by the double doors.", "Shattered Necklace Topaz"),
      part(2339, 1, nil, "Ruby: open the Shadowforge Cache in Dig Three, past the Map Chamber and the bat caves. Enemies appear when you loot it.",
        "Shattered Necklace Ruby"),
      part(2339, 2, nil, "Sapphire: Grimlok at the end of the Stone Vault carries it.", "Shattered Necklace Sapphire"),
      part(2339, 4, nil, "Power source: wake and defeat Archaedas in the Hall of the Crafters.", "Shattered Necklace Power Source"),
      accept(2278, nil, "In the room behind Archaedas, use the Discs of Norgannon."),
      objective(2278, nil, "Speak to the Lore Keeper of Norgannon and hear what it knows.", "Lore of the stone watcher"),
      finish(2278, nil, "Use the Discs of Norgannon again."),
      accept(2280, nil, "Take the miniature discs for the sages of Thunder Bluff."),
      action("goto", rigglefuzz, "Leave Uldaman and ride south to Rigglefuzz's camp."),
      finish(2418, rigglefuzz),
      finish(709, theldurin, "Ride south to Theldurin."),
      accept(728, theldurin, "He sends the Sigil of the Hammer to Keeper Bel'dugur in the Undercity."),
      action("goto", jarkal, "Ride west to Kargath."),
      finish(2202, jarkal),
      finish(2339, jarkal),
      accept(2340, jarkal, "Jarkal sends the necklace and the gem salvage back to Dran."),
      action("goto", dran, "Travel to Orgrimmar: fly to Grom'gol or the Undercity and take the zeppelin."),
      finish(2340, dran),
      accept(2341, dran, "Dran sends you back to Jarkal to see whether he restored the necklace."),
      taxi("fly", ogFlights, "Thunder Bluff, Mulgore", "Fly to Thunder Bluff."),
      finish(2280, sage, "Sage Truthseeker studies the discs."),
      accept(2440, sage),
      finish(2440, bena, "Bena Winterhoof takes the voucher. Sage Truthseeker's next chain, to Uldum in Tanaris, opens at level 45."),
      action("goto", patrick, "Travel to the Undercity: fly to Orgrimmar and take the zeppelin to Tirisfal Glades."),
      finish(2342, patrick),
      finish(728, belDugur, "Keeper Bel'dugur works in the Apothecarium."),
      taxi("fly", ucFlights, "Kargath, Badlands", "Fly to Kargath."),
      finish(2341, jarkal, "See whether Jarkal restored the necklace."),
    })
end

-- Zul'Farrak. Lydon and Gadrin's Spider God chain, Gadgetzan's errands, Tabetha, Wizzle and the Mosh'aru tablets.
do
  local name = "Zul'Farrak"
  local hl, ta = on.hinterlands, on.tanaris
  local bottles = hl("Venom Bottles", 23.54, 58.8)
  local broodguards = hl("Witherbark Broodguards", 32.7, 72.9)
  local qiaga = hl("Qiaga the Keeper", 48.6, 68.2)
  local lydon = on.hillsbrad("Apothecary Lydon", 61.44, 19.06)
  local gadrin = on.durotar("Master Gadrin", 55.95, 74.72)
  local krazek = on.stv("Krazek", 26.94, 77.21)
  local bragok = on.barrens("Bragok", 63.09, 37.16)
  local shardi = on.dustwallow("Shardi", 35.6, 31.9)
  local tabetha = on.dustwallow("Tabetha", 46.06, 57.09)
  local bulkrek = ta("Bulkrek Ragefist", 51.6, 25.4)
  local tranrek = ta("Tran'rek", 51.57, 26.76)
  local bilgewhizzle = ta("Chief Engineer Bilgewhizzle", 52.46, 28.51)
  local trenton = ta("Trenton Lighthammer", 51.41, 28.75)
  local yehkinya = ta("Yeh'kinya", 66.99, 22.36)
  local wizzle = on.needles("Wizzle Brassbolts", 78.14, 77.12)
  local shyn = on.feralas("Shyn", 75.5, 44.4)
  local zfDoor = ta("Zul'Farrak entrance", 38.7, 19.8)
  H.need(2933, "Venom Bottles", 43, 40)
  H.need(2934, "Undamaged Venom Sac", 45, 40, 2933)
  H.need(2935, "Consult Master Gadrin", 45, 40, 2934)
  H.need(2936, "The Spider God", 45, 40, 2935)
  H.need(2864, "Tran'rek", 45, 40)
  H.need(2865, "Scarab Shells", 45, 40, 2864)
  H.need(2768, "Divino-matic Rod", 47, 40)
  H.need(3042, "Troll Temper", 45, 40)
  H.need(2846, "Tiara of the Deep", 46, 40)
  H.need(2770, "Gahz'rilla", 50, 40)
  H.need(3520, "Screecher Spirits", 44, 40)
  H.need(3527, "The Prophecy of Mosh'aru", 47, 40, 3520)
  local screechers = withItem(10699, objective(3520, on.feralas("Vale Screechers", 54.5, 47.8),
    "Kill Vale Screechers and Rogue Vale Screechers in central Feralas. Use Yeh'kinya's Bramble on a corpse and speak to the spirit that rises.",
    "3 Screecher Spirits"))
  screechers.points = { { 57.6, 57.3 }, { 54.5, 47.8 }, { 47.0, 47.2 }, { 44.4, 37.1 } }
  screechers.nearest = true
  add({ id = "dungeon-zul-farrak", title = name, zone = M.tanaris, levels = { 44, 50 }, instanceID = 209, instance = name,
    links = { "dungeon-sunken-temple" },
    bosses = bosses("dungeon-zul-farrak", { ["Antu'sul"] = 595, ["Theka the Martyr"] = 596, ["Witch Doctor Zum'rah"] = 597,
      ["Nekrum and Sezz'ziz"] = 598, ["Hydromancer Velratha"] = 593, ["Gahz'rilla"] = 594,
      ["Chief Ukorz Sandscalp and Ruuzlu"] = 600 }),
    sources = { "https://questing.wiki/wow-forever/dungeons/zul-farrak/quests/", qdb } }, {
      action("goto", bottles, "Fly to Tarren Mill, then ride north-east through the pass into the Hinterlands. The Venom Bottles lie against crates in the west of the zone."),
      accept(2933, bottles, "Click a green Venom Bottle to start the quest."),
      action("goto", lydon, "Ride back to Tarren Mill."),
      finish(2933, lydon, "Apothecary Lydon works inside a Tarren Mill house."),
      accept(2934, lydon, "He needs an undamaged venom sac."),
      action("goto", broodguards, "Ride back into the Hinterlands and south to Shadra'Alor."),
      objective(2934, broodguards, "Kill Witherbark Broodguards around Shadra'Alor until one drops an Undamaged Venom Sac.", "Undamaged Venom Sac"),
      note("Mallet of Zul'Farrak", "Optional, for Gahz'rilla, and one per group is enough: Qiaga the Keeper, a level 50 elite on top of the Altar of Zul, drops the Sacred Mallet. Use it at the altar on top of Jintha'Alor to make the Mallet of Zul'Farrak.",
        qiaga),
      action("goto", lydon, "Ride back to Tarren Mill."),
      finish(2934, lydon),
      accept(2935, lydon, "Lydon sends you to Master Gadrin in Sen'jin Village."),
      taxi("fly", tmFlights, "Undercity, Tirisfal", "Fly to the Undercity."),
      action("boat", tirisfalTower, "Take the zeppelin to Orgrimmar from the tower north-west of the Undercity gate."),
      action("goto", gadrin, "Ride south through Durotar to Sen'jin Village."),
      finish(2935, gadrin),
      accept(2936, gadrin, "Gadrin wants the name of the Witherbark spider god from the Tablet of Theka in Zul'Farrak."),
      action("boat", toGromgol, "Ride north to the zeppelin tower east of Orgrimmar and take the zeppelin to Grom'gol."),
      taxi("fly", gromgolFlights, "Booty Bay, Stranglethorn", "Fly to Booty Bay, or ride south down the road."),
      accept(2864, krazek, "Krazek, on the top floor of the Booty Bay inn, sends you to Tran'rek in Gadgetzan."),
      action("boat", on.stv(nil, 25.8, 73.1), "Take the boat to Ratchet from the Booty Bay docks."),
      taxi("fly", bragok, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village."),
      action("goto", tabetha, "Ride south through the marsh to Tabetha's hut, south-west of Theramore."),
      accept(2846, tabetha, "Tabetha wants the Tiara of the Deep from Zul'Farrak."),
      action("goto", shardi, "Ride back north to Brackenwall Village."),
      taxi("fly", shardi, "Gadgetzan, Tanaris", "Fly to Gadgetzan."),
      finish(2864, tranrek, "Tran'rek stands by the Gadgetzan bank."),
      accept(2865, tranrek, "He wants scarab shells from Zul'Farrak."),
      accept(2768, bilgewhizzle, "Chief Engineer Bilgewhizzle, by the water tower, lost a Divino-matic Rod in Zul'Farrak."),
      accept(3042, trenton, "Trenton Lighthammer, the Gadgetzan blacksmith, wants troll temper."),
      action("goto", wizzle, "Ride north out of Tanaris into the Shimmering Flats."),
      accept(2770, wizzle, "Wizzle Brassbolts wants Gahz'rilla's scale. Summoning her needs the Mallet of Zul'Farrak."),
      action("goto", yehkinya, "Ride back into Tanaris and east to Steamwheedle Port on the coast."),
      accept(3520, yehkinya, "Yeh'kinya wants the spirits of three screechers in Feralas."),
      action("goto", bulkrek, "Ride back to Gadgetzan."),
      taxi("fly", bulkrek, "Camp Mojache, Feralas", "Fly to Camp Mojache."),
      screechers,
      taxi("fly", shyn, "Gadgetzan, Tanaris", "Fly back to Gadgetzan."),
      action("goto", yehkinya, "Ride to Steamwheedle Port."),
      finish(3520, yehkinya),
      accept(3527, yehkinya, "Now he wants the two Mosh'aru tablets from Zul'Farrak."),
      action("goto", zfDoor, "Ride west past Gadgetzan into the Zul'Farrak dunes in the north-west of Tanaris."),
      enter(name, zfDoor, "The portal is in the city's outer wall, with the meeting stone just south of it. Enter with your group."),
    }, {
      objective(2936, nil, "In Theka the Martyr's scarab room, read the Tablet of Theka against the wall.", "Spider god's name learned"),
      objective(3527, nil, "Theka the Martyr carries the first Mosh'aru tablet; Hydromancer Velratha, by the pool south-east of the pyramid, the second.",
        "First Mosh'aru Tablet", "Second Mosh'aru Tablet"),
      objective(2865, nil, "Kill scarabs for their shells. Most are in Theka's room.", "5 Uncracked Scarab Shells"),
      objective(2768, nil, "On the pyramid, kill the Sandfury Executioner for his key and free Sergeant Bly's band. Hold the stairs through the waves; once Nekrum is dead, Bly turns on you. Kill him for the rod.",
        "Divino-matic Rod"),
      objective(2846, nil, "Hydromancer Velratha also carries the Tiara of the Deep.", "Tiara of the Deep"),
      uncertain(objective(2770, nil, "Clear the pool, then use the Mallet of Zul'Farrak at the gong to summon Gahz'rilla. Loot her scale.",
        "Gahz'rilla's Electrified Scale"), "Needs the Mallet of Zul'Farrak from the Hinterlands; skip it without one."),
      objective(3042, nil, "Loot Troll Temper from the Sandfury trolls. It can take more than one run.", "20 Vials of Troll Temper"),
    }, {
      action("goto", trenton, "Leave Zul'Farrak and ride back to Gadgetzan."),
      finish(3042, trenton),
      finish(2768, bilgewhizzle),
      finish(2865, tranrek),
      action("goto", yehkinya, "Ride to Steamwheedle Port."),
      finish(3527, yehkinya),
      action("goto", wizzle, "Ride north into the Shimmering Flats."),
      finish(2770, wizzle),
      action("goto", bulkrek, "Ride back to Gadgetzan."),
      taxi("fly", bulkrek, "Brackenwall Village, Dustwallow Marsh", "Fly to Brackenwall Village."),
      action("goto", tabetha, "Ride south through the marsh to Tabetha's hut."),
      finish(2846, tabetha),
      action("goto", shardi, "Ride back north to Brackenwall Village."),
      taxi("fly", shardi, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
      action("goto", gadrin, "Ride south through Durotar to Sen'jin Village."),
      finish(2936, gadrin, "Tell Gadrin the spider god's name. His next task, Summoning Shadra in the Hinterlands, is a level 55 quest."),
    })
end
