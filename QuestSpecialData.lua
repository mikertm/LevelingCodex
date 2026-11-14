-- Optional Alliance quest chains. Source notes: tools/audits/2026-11-09-special-quests.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local m, at = B.maps, B.at
local accept, finish, goal, action = B.accept, B.finish, B.objectiveAt, B.action

local function special(section)
  section.side, section.category, section.verified = true, "special", false
  route.sections[#route.sections + 1] = section
end

local function chain(name, min, quests)
  local previous
  for _, quest in ipairs(quests) do
    B.q(quest[1], name, quest[2], min, previous)
    previous = quest[1]
  end
end

local function uncertain(step, note)
  step.uncertain = note
  return step
end

do
  local ashenvale = 1440
  B.q(95737, "Seeking Caitlin", 31, 24, nil, true)
  B.breadcrumb(95737, 95647)
  special({ id = "seeking-caitlin", title = "Seeking Caitlin", zone = ashenvale, levels = { 24, 31 },
    links = { "dungeon-excavation-site" },
    sources = { "https://www.wowhead.com/forever/quest=95737/seeking-caitlin",
      "https://forever-tavern.com/quests/95737-seeking-caitlin/" },
    steps = {
      accept(95737, at("Llana", 35.0, 48.5, ashenvale), "Ask the reagent vendor in Astranaar about her letter to Menethil."),
      finish(95737, at("Caitlin Grassman", 11.88, 58.82, m.wetlands),
        "Go north to Auberdine and take the Menethil ship. Deliver Llana's message, then open the Excavation Site checklist for Caitlin's dungeon quest."),
    },
  })
end

do
  local barrens, stonetalon, stranglethorn = 1413, 1442, 1434
  local hillsbrad, arathi = 1424, 1417
  route.extents[barrens] = { 10133.333, 6756.25 }
  route.extents[stonetalon] = { 4883.333, 3256.25 }
  route.extents[stranglethorn] = { 6381.25, 4254.166 }
  route.extents[hillsbrad] = { 3200, 2133.333 }
  route.extents[arathi] = { 3600, 2400 }

  B.q(79008, "... and that note you found", 22, 14, nil, true)
  B.q(79192, "Stepping Stones", 24, 14, 79008, true)
  B.q(79980, "Scramble", 24, 14, 79192, true)
  B.q(79974, "Wet Job", 32, 14, 79980, true)
  B.q(79975, "Eagle's Fist", 32, 14, 79974, true)
  B.q(79976, "This Must Be The Place", 32, 14, 79975, true)

  local farm = at("Burned-Out Remains", 37.42, 50.71, m.westfall)
  local tower = at("Burned-Out Remains", 46.35, 73.89, barrens)
  local plank = at("Nailed Plank", 46.37, 73.8, barrens)
  local camp = at("Pocket Litter", 40.77, 52.57, stonetalon)
  local mound = at("Mound of Dirt", 39.62, 49.87, stonetalon)
  local dam = at("Carved Figurine", 49.43, 12.9, m.lochModan)
  local bag = at("Messenger Bag", 22.48, 24.18, arathi)
  local satchel = at("Hastily Rolled-Up Satchel", 22.48, 24.2, arathi)

  special({ id = "cozy-sleeping-bag", title = "Cozy Sleeping Bag", zone = m.westfall, levels = { 14, 32 },
    reward = "A sleeping bag: rest in it for up to 3% bonus XP",
    sources = {
      "https://www.wowhead.com/forever/guide/cozy-sleeping-bag-locations-rewards",
      "https://oraclenewsnetwork.com/guides/cozy-sleeping-bag",
      "https://wowf.io/en/quests/cozy-sleeping-bag",
      "https://www.method.gg/wow-forever/all-travel-routes-in-wow-forever-boats-zeppelins",
    },
    steps = {
      accept(79008, farm, "From level 14, search the wrecked cart in the burned field at Alexston Farmstead. Bring a friend for the higher-level travel or finish the chain later."),
      action("goto", at("Booty Bay docks", 26, 73.2, stranglethorn),
        "Fly to Booty Bay if you know the route. Otherwise take the road south from Duskwood through Stranglethorn Vale. Stay on the road, give Grom'gol a wide berth, and wait for company if the wildlife blocks your way."),
      action("goto", at("Ratchet docks", 63.6, 38.7, barrens),
        "Board the Ratchet boat at the end of the Booty Bay dock. In Ratchet, learn the flight path before heading inland."),
      finish(79008, tower, "Head southwest from Ratchet to the burned watchtower in the Field of Giants. Go around Camp Taurajo and stay clear of its Horde guards. Search the remains at the tower."),
      accept(79192, plank, "Take the next note from the plank beside the remains."),
      action("goto", at("Stonetalon camp trail", 50.9, 52.3, stonetalon),
        "Head northwest to the Barrens road into Stonetalon. Keep clear of the Crossroads and Sun Rock Retreat. Look for the narrow trail climbing west from the road northeast of Sun Rock Retreat."),
      uncertain(finish(79192, camp, "Follow the trail west to the abandoned camp. Search the Pocket Litter on a crate by the tent to claim the Old Toolbox, a 12-slot bag."),
        "Some listings show a Sturdy Lunchbox too. Check the Alliance reward window."),
      accept(79980, camp, "Read the next clue in the Pocket Litter."),
      finish(79980, mound, "Climb the slope north of the camp. Look down for the mound and use the short ledges to reach it. Check your landing before each jump."),
      accept(79974, mound, "Take the next clue from the Mound of Dirt."),
      action("goto", at("Stonewrought Dam", 49.43, 12.9, m.lochModan),
        "Return to the Eastern Kingdoms. Use your hearth if it saves the trip. From Stormwind, take the Deeprun Tram to Ironforge, then fly to Thelsamar or follow the east road through Dun Morogh. Head north to Stonewrought Dam."),
      finish(79974, dam, "At the middle of the dam, face north toward the Wetlands and drop onto the ledge with the carved dwarf heads. Click the figurine on the ledge."),
      accept(79975, dam, "Read the next clue at the Carved Figurine."),
      action("goto", at("Cart at Thoradin's Wall", 87.36, 49.62, hillsbrad),
        "Climb out and follow the road into the Wetlands. Take the Southshore boat from Menethil Harbor, then follow the road east to Thoradin's Wall. The overland route via Thandol Span and Arathi has higher-level enemies. Look for the cart beside the damaged wall on the Hillsbrad side."),
      finish(79975, bag, "Use the cart to jump onto the wall. Go through the room inside and look to your right for the hanging Messenger Bag."),
      accept(79976, bag, "Read the last clue at the Messenger Bag."),
      finish(79976, satchel, "Open the satchel just below the Messenger Bag. Unroll your Cozy Sleeping Bag somewhere safe and rest in it for 1% bonus experience per minute, up to 3%."),
    },
  })
end

do
  local name = "The Legend of Stalvan"
  chain(name, 22, { { 66, 28 }, { 67, 28 }, { 68, 28 }, { 69, 28 }, { 70, 28 }, { 72, 28 },
    { 74, 28 }, { 75, 28 }, { 78, 28 }, { 79, 28 }, { 80, 28 }, { 97, 28 }, { 98, 35 } })

  local eva = at("Madame Eva", 75.79, 45.32, m.duskwood)
  local daltry = at("Clerk Daltry", 72.54, 46.87, m.duskwood)
  local footlocker = at("Old Footlocker", 41.51, 66.73, m.westfall)
  local farley = at("Innkeeper Farley", 43.77, 65.8, m.elwynn)
  local folsom = at("Caretaker Folsom", 42.53, 72.36, m.stormwind)
  local crate = at("Sealed Crate", 42.47, 72.05, m.stormwind)
  local haggard = at("Marshal Haggard", 84.61, 69.38, m.elwynn)
  local smitts = at("Tavernkeep Smitts", 73.78, 44.49, m.duskwood)
  local ebonlocke = at("Commander Althea Ebonlocke", 73.54, 46.82, m.duskwood)

  special({ id = "legend-of-stalvan", title = name, zone = m.duskwood, levels = { 22, 35 },
    sources = {
      "https://www.wowhead.com/forever/quest=66/the-legend-of-stalvan",
      "https://www.wowhead.com/forever/quest=98/the-legend-of-stalvan",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
    },
    steps = {
      accept(66, eva, "From level 22, speak to Madame Eva in Darkshire. Start the investigation while questing here and plan to finish the fight at a higher level or with help."),
      finish(66, daltry, "Find Clerk Daltry inside Darkshire's town hall."),
      accept(67, daltry, "Ask Daltry where Stalvan taught."),
      finish(67, footlocker, "Take the west road to Westfall or fly to Sentinel Hill. Search the footlocker inside the Moonbrook schoolhouse."),
      accept(68, footlocker, "Take the letter from the footlocker. Be ready for a level 25-26 spirit to appear."),
      finish(68, daltry, "Bring the dusty letter back to Daltry in Darkshire."),
      accept(69, daltry, "Take Daltry's lead to Goldshire."),
      finish(69, farley, "Find Farley in the Lion's Pride Inn in Goldshire."),
      accept(70, farley, "Ask Farley for the letter Stalvan left behind."),
      goal(70, at("Storage Chest", 44.3, 65.82, m.elwynn),
        "Check the chest upstairs in the inn and take the letter.", "An Undelivered Letter"),
      finish(70, folsom, "Take the letter to Folsom in Stormwind's Canal District, near the Stockade."),
      accept(72, folsom, "Ask Folsom where Stalvan's belongings are stored."),
      finish(72, crate, "Open the sealed crate near Folsom. A spirit can appear here too."),
      accept(74, crate, "Take the torn page and follow the lead to Eastvale Logging Camp."),
      finish(74, haggard, "Show the page to Marshal Haggard at Eastvale in eastern Elwynn Forest."),
      accept(75, haggard, "Ask Haggard about the rest of the journal."),
      goal(75, at("Marshal Haggard's Chest", 85.7, 69.54, m.elwynn),
        "Look upstairs for Haggard's chest. Take the page and be ready for a spirit.", "A Faded Journal Page"),
      finish(75, haggard, "Bring the faded page back to Haggard."),
      accept(78, haggard, "Take the page to Darkshire for cleaning."),
      finish(78, smitts, "Find Smitts at the Scarlet Raven Tavern in Darkshire."),
      accept(79, smitts, "Take the page to the commander."),
      finish(79, ebonlocke),
      accept(80, ebonlocke, "Take the bloodstained page back to Daltry."),
      finish(80, daltry),
      accept(97, daltry, "Bring Daltry's account to the commander."),
      finish(97, ebonlocke),
      accept(98, ebonlocke, "Accept the level 35 finale. Stalvan is level 32. Return in the low 30s or bring a group before attempting the fight."),
      goal(98, at("Stalvan Mistmantle", 77.35, 36.19, m.duskwood),
        "Go northeast from Darkshire to Manor Mistmantle. Clear a retreat path, then pull Stalvan from the house and loot the family ring.", "Mistmantle Family Ring"),
      finish(98, eva, "Take the Mistmantle ring back to Madame Eva in Darkshire."),
    },
  })
end

do
  local name, dustwallow = "The Missing Diplomat", 1445
  route.extents[dustwallow] = { 5250, 3500 }
  chain(name, 28, { { 1274, 28 }, { 1241, 28 }, { 1242, 28 }, { 1243, 28 }, { 1244, 30 },
    { 1245, 30 }, { 1246, 31 }, { 1447, 31 }, { 1247, 31 }, { 1248, 33 }, { 1249, 33 },
    { 1250, 33 }, { 1264, 33 }, { 1265, 35 }, { 1266, 36 }, { 1324, 38 }, { 1267, 38 } })

  local thomas = at("Thomas", 49.64, 44.48, m.stormwind)
  local delavey = at("Bishop DeLavey", 80.24, 44.07, m.stormwind)
  local jorgen = at("Jorgen", 76.29, 85.12, m.stormwind)
  local trias = at("Elling Trias", 66.03, 74.1, m.stormwind)
  local backus = at("Watcher Backus", 74.83, 44.22, m.duskwood)
  local strongbox = at("Defias Strongbox", 23.92, 72.07, m.duskwood)
  local dashel = at("Dashel Stonefist", 74.26, 59.17, m.stormwind)
  local mikhail = at("Mikhail", 10.6, 60.77, m.wetlands)
  local slim = at('Tapoke "Slim" Jahn', 10.54, 60.26, m.wetlands)
  local samaul = at("Commander Samaul", 68.02, 48.71, dustwallow)
  local sentry = at("Sentry Point", 59.92, 40.9, dustwallow)
  local hendel = at("Private Hendel", 45.24, 24.65, dustwallow)
  local jaina = at("Lady Jaina Proudmoore", 66.27, 49.04, dustwallow)

  special({ id = "missing-diplomat", title = name, zone = m.stormwind, levels = { 28, 38 },
    sources = {
      "https://theforeverguides.com/quests/the-missing-diplomat/",
      "https://www.wowhead.com/forever/quest=1244/the-missing-diplomat",
      "https://www.wowhead.com/forever/quest=1265/the-missing-diplomat",
      "https://www.wowhead.com/forever/quest=1324/the-missing-diplomat",
      "https://www.wowhead.com/forever/quest=1267/the-missing-diplomat",
    },
    steps = {
      accept(1274, thomas, "From level 28, talk to Thomas in the Cathedral of Light in Stormwind."),
      finish(1274, delavey, "Find Bishop DeLavey in Stormwind Keep."),
      accept(1241, delavey, "Take the bishop's note to Jorgen."),
      finish(1241, jorgen, "Look for Jorgen near the canal by the Trade District gate. Check the nearby canal path if he is walking."),
      accept(1242, jorgen, "Take the sealed note to the cheese shop."),
      finish(1242, trias, "Find Elling Trias in the Trade District cheese shop."),
      accept(1243, trias, "Take Trias's sealed note to Darkshire."),
      finish(1243, backus, "Fly to Darkshire or take the road from Elwynn. Look for Watcher Backus near the north road in town."),
      accept(1244, backus, "Ask Backus about the Defias activity at Addle's Stead."),
      action("goto", strongbox, "Take the west road toward Raven Hill and head south to Addle's Stead."),
      goal(1244, strongbox, "Clear the Defias around the small farmhouse on the left as you approach, then loot the strongbox inside.", "Defias Docket"),
      action("goto", backus, "Follow the road east to Darkshire."),
      finish(1244, backus, "Bring the docket back to Watcher Backus."),
      accept(1245, backus, "Take the docket to Stormwind."),
      finish(1245, trias, "Fly or return by road to the cheese shop in the Trade District."),
      accept(1246, trias, "Ask Trias where to find Dashel Stonefist."),
      finish(1246, dashel, "Find Dashel by the entrance to Old Town."),
      accept(1447, dashel, "Recover before accepting. Dashel and his friends can attack as soon as you take the quest. Bring help if you need it."),
      goal(1447, dashel, "Subdue Dashel. Keep his friends under control and stay close enough for the fight to count.", "Dashel Stonefist defeated"),
      finish(1447, dashel, "Speak to Dashel when he yields."),
      accept(1247, dashel, "Take what you learned back to Trias."),
      finish(1247, trias),
      accept(1248, trias, "This is a good pause point at level 28. Pick up the Menethil lead now and return for the Wetlands brawl around level 30-34 or with a group."),
      finish(1248, mikhail, "Fly to Menethil Harbor if you know the route. Otherwise use Ironforge and the Loch Modan road, or take the ship to Auberdine and transfer to the Menethil boat. Find Mikhail in the Deepwater Tavern."),
      accept(1249, mikhail, "Prepare before accepting. Level 34 Tapoke can run for help. Have your group in place and a slow or stun ready."),
      goal(1249, slim, "Subdue Tapoke before he escapes. Control any friends he calls. If he gets away, return to Mikhail to try again.", "Tapoke Jahn subdued"),
      finish(1249, mikhail, "Return to Mikhail after Tapoke yields."),
      accept(1250, slim, "Wait for Tapoke to become friendly in the inn, then hear his account."),
      finish(1250, mikhail),
      accept(1264, mikhail, "Take the lead for Theramore. Plan the Dustwallow Marsh leg around level 35-38, and bring help for Hendel and his guards."),
      finish(1264, samaul, "Take the Theramore boat from Menethil's south pier. From the docks in Theramore, go upstairs in Foothold Citadel to find Samaul."),
      accept(1265, samaul, "Ask Samaul about Hendel and Sentry Point."),
      goal(1265, sentry, "Follow the road northwest out of Theramore. Walk inside the first guard tower until you get exploration credit.", "Sentry Point explored"),
      uncertain(finish(1265, sentry, "Look for Archmage Tervosh at Sentry Point. If he does not appear, check Jaina's tower in Theramore at 66.42, 49.26."),
        "Reports place Tervosh at either Sentry Point or Jaina's tower after the exploration trigger."),
      accept(1266, nil, "Get the next lead from Tervosh where you turned in. If he has moved, check Jaina's tower in Theramore at 66.42, 49.26."),
      finish(1266, hendel, "Follow the road north past the next tower to the tents near the road. Find Hendel there and keep clear of Brackenwall Village."),
      accept(1324, hendel, "Set up your group before accepting. Level 35 Hendel and his guards can turn hostile immediately."),
      goal(1324, hendel, "Subdue Hendel and manage his guards. Stay nearby for the event and wait for Tervosh and Jaina to arrive.", "Subdue Private Hendel"),
      uncertain(finish(1324, hendel, "Speak to Tervosh at the camp once Hendel surrenders. If Tervosh leaves, check Jaina's tower in Theramore."),
        "The Forever spawn record places Tervosh in Theramore. The surrender scene can also bring him to Hendel's camp."),
      accept(1267, nil, "Ask Tervosh for the final introduction to Jaina. If he has left the camp, check her tower in Theramore at 66.42, 49.26."),
      finish(1267, jaina, "Speak to Jaina at the scene if she is still there. Otherwise return to the upper level of her tower in Theramore for the final reward."),
    },
  })
end

-- 50-60 attunements and keys. Sources: tools/audits/2026-11-10-attunements.md.
do
  local steppes, searing, wpl, tanaris, ungoro = B.maps.steppes, B.maps.searing, B.maps.wpl, B.maps.tanaris, B.maps.ungoro
  local winterspring, dustwallow = B.maps.winterspring, B.maps.dustwallow
  local blackrock = at("Blackrock Mountain", 34.8, 85.3, searing)

  -- Copies of leveling-route steps for the given quests, in route order (a guide is checked on its own).
  local function fromRoute(sectionId, ids)
    local wanted, result = {}, {}
    for _, id in ipairs(ids) do wanted[id] = true end
    for _, section in ipairs(route.sections) do
      if section.id == sectionId then
        for _, step in ipairs(section.steps) do
          if step.quest and wanted[step.quest] then
            local copy = {}
            for key, value in pairs(step) do copy[key] = value end
            copy.optional, copy.dungeon, copy.also = nil, nil, nil
            result[#result + 1] = copy
          end
        end
        return result
      end
    end
    error("special guide: no route section " .. sectionId)
  end

  local function join(...)
    local result = {}
    for _, part in ipairs({ ... }) do
      for _, step in ipairs(part) do result[#result + 1] = step end
    end
    return result
  end

  local maxwell = at("Marshal Maxwell", 84.74, 69.02, steppes)
  local bolvar = at("Highlord Bolvar Fordragon", 80.21, 38.35, m.stormwind)
  local haleh = at("Haleh", 54.55, 51.2, winterspring)
  B.q(4241, "Marshal Windsor", 54, 48, 4224)
  B.q(4242, "Abandoned Hope", 54, 48, 4241)
  B.q(4264, "A Crumpled Up Note", 58, 50, 4242)
  B.quest[4264].startItem = 11446
  B.q(4282, "A Shred of Hope", 58, 50, 4264)
  B.q(4322, "Jail Break!", 58, 50, 4282)
  B.q(6402, "Stormwind Rendezvous", 60, 50, 4322)
  B.q(6403, "The Great Masquerade", 60, 50, 6402)
  B.q(6501, "The Dragon's Eye", 60, 50, 6403)
  B.q(6502, "Drakefire Amulet", 60, 50, 6501)
  special({ id = "onyxia-attunement", title = "Drakefire Amulet (Onyxia's Lair)", zone = steppes, levels = { 54, 60 },
    links = { "dungeon-blackrock-depths", "dungeon-upper-blackrock-spire" },
    sources = { "https://www.wowhead.com/forever/quest=6502/drakefire-amulet",
      "https://warcraft.wiki.gg/wiki/Drakefire_Amulet",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever" },
    steps = join(fromRoute("steppes-56", { 4182, 4183, 4184, 4185, 4186, 4223, 4224 }), {
      accept(4241, maxwell, "Marshal Maxwell asks what became of Marshal Windsor. He is a prisoner in Blackrock Depths: plan a run."),
      finish(4241, nil, "Find Marshal Windsor in a cell in Blackrock Depths' Detention Block, past the first bridge."),
      accept(4242, nil, "Take Windsor's bad news back to Maxwell."),
      finish(4242, maxwell),
      B.withItem(11446, accept(4264, nil, "Anvilrage guards in Blackrock Depths can drop A Crumpled Up Note. Read it on a later run.")),
      finish(4264, nil, "Bring the note to Marshal Windsor in his cell."),
      accept(4282, nil, "Windsor's lost papers are with General Angerforge and Golem Lord Argelmach, deeper in Blackrock Depths."),
      goal(4282, nil, "Kill General Angerforge and Golem Lord Argelmach for Windsor's papers.", "Marshal Windsor's Lost Information"),
      finish(4282, nil, "Bring the papers back to Windsor."), accept(4322, nil, "Free Marshal Windsor and escort him out. Clear the cell block first: the escort walks into several packs."),
      goal(4322, nil, "Keep Windsor alive while he collects his gear and frees his friends.", "Marshal Windsor freed"),
      finish(4322, maxwell, "Report to Marshal Maxwell at Morgan's Vigil."), accept(6402, maxwell),
      finish(6402, at("Squire Rowe", 74.17, 90.33, m.stormwind),
        "At Stormwind's main gate, talk to Squire Rowe and wait for Reginald Windsor to ride up."),
      accept(6403, nil, "Speak to Reginald Windsor when he arrives, and follow him to the keep."),
      uncertain(goal(6403, nil, "Escort Reginald Windsor through Stormwind to the throne room. Fight off the dragonkin when Lady Prestor is unmasked.",
        "Reginald Windsor escorted"), "A group is needed for the throne room fight; check the Forever version."),
      finish(6403, bolvar), accept(6501, bolvar),
      finish(6501, haleh, "Haleh waits at the top of Mazthoril in Winterspring. Take the cave path up from the Mazthoril entrance."),
      accept(6502, haleh, "Bring the blood of General Drakkisath from Upper Blackrock Spire."),
      goal(6502, nil, "Defeat General Drakkisath in Upper Blackrock Spire and take his blood.", "Blood of the Black Dragon Champion"),
      finish(6502, haleh, "Return to Haleh for the Drakefire Amulet: it opens Onyxia's Lair in Dustwallow Marsh."),
    }),
  })

  B.q(4742, "Seal of Ascension", 60, 57)
  B.q(4743, "Seal of Ascension", 60, 57, 4742)
  special({ id = "ubrs-seal", title = "Seal of Ascension (Upper Blackrock Spire)", zone = searing, levels = { 57, 60 },
    links = { "dungeon-lower-blackrock-spire", "dungeon-upper-blackrock-spire" },
    sources = { "https://www.wowhead.com/forever/quest=4742/seal-of-ascension",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever" },
    steps = {
      action("goto", blackrock, "Meet your group at Blackrock Mountain and enter Lower Blackrock Spire."),
      accept(4742, nil, "Vaelan, a captured dragon in disguise, stands near the start of Lower Blackrock Spire."),
      goal(4742, nil, "Kill Highlord Omokk, War Master Voone and Overlord Wyrmthalak for their gemstones, and loot an Unadorned Seal of Ascension from the Scarshield orcs.",
        "Gemstone of Spirestone", "Gemstone of Smolderthorn", "Gemstone of Bloodaxe", "Unadorned Seal of Ascension"),
      finish(4742, nil, "Bring everything back to Vaelan."), accept(4743, nil, "Vaelan sends you to break a black drake with the unforged seal."),
      uncertain(goal(4743, at("Emberstrife", 56.66, 87.72, dustwallow),
        "Fly to Theramore and ride to the Wyrmbog. Beat Emberstrife, a level 61 elite drake, down to low health and use the Unforged Seal on him. Bring a group.",
        "Forged Seal of Ascension"), "Emberstrife's guards and level; check in game."),
      finish(4743, nil, "Return to Vaelan in Lower Blackrock Spire. The Seal of Ascension opens Upper Blackrock Spire."),
    },
  })

  B.q(7848, "Attunement to the Core", 60, 55)
  special({ id = "molten-core-attunement", title = "Attunement to the Core", zone = searing, levels = { 55, 60 },
    links = { "dungeon-blackrock-depths" },
    sources = { "https://www.wowhead.com/forever/quest=7848/attunement-to-the-core",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever" },
    steps = {
      accept(7848, nil, "Lothos Riftwaker waits on the ledge inside Blackrock Mountain, just past the chain down to Blackrock Depths."),
      goal(7848, nil, "In Blackrock Depths, go past Lord Incendius to the Molten Core portal and take a Core Fragment from the rock beside it.",
        "Core Fragment"),
      finish(7848, nil, "Return to Lothos. Once attuned he can teleport you straight to Molten Core."),
    },
  })

  B.q(5538, "Mold Rhymes With...", 57, 55, 5537)
  B.q(5801, "Fire Plume Forged", 57, 55, 5538)
  B.q(5803, "Araj's Scarab", 60, 55, 5801)
  B.q(5505, "The Key to Scholomance", 60, 55, 5803)
  local arbington = at("Alchemist Arbington", 42.66, 83.77, wpl)
  special({ id = "scholomance-key", title = "The Key to Scholomance", zone = wpl, levels = { 55, 60 },
    links = { "dungeon-scholomance" },
    sources = { "https://www.wowhead.com/forever/quest=5505/the-key-to-scholomance",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever" },
    steps = join(fromRoute("wpl-51", { 5090, 5092 }), fromRoute("plaguelands-57", { 5097, 5533, 5537 }), {
      accept(5538, arbington, "Arbington needs the fragments shaped by a smith. Take them and 15 gold to Krinkle Goodsteel."),
      finish(5538, at("Krinkle Goodsteel", 51.46, 28.81, tanaris), "Krinkle Goodsteel is the smith in Gadgetzan."),
      accept(5801, at("Krinkle Goodsteel", 51.46, 28.81, tanaris),
        "Krinkle gives you the Skeleton Key Mold. You also need 2 Thorium Bars: smelt them or buy them on the Auction House."),
      action("buy", nil, "Get 2 Thorium Bars before you go to Un'Goro: a miner can smelt them, or check the Auction House."),
      goal(5801, at("Fire Plume Ridge", 50.5, 49.5, ungoro), "Climb Fire Plume Ridge in the middle of Un'Goro and use the mold beside the lava lake.",
        "Unfinished Skeleton Key"),
      finish(5801, arbington, "Take the unfinished key back to Arbington at Chillwind Camp."), accept(5803, arbington),
      uncertain(goal(5803, at("Araj the Summoner", 45.27, 69.21, wpl), "Araj the Summoner stands in the middle of Andorhal with his guards. Bring a group, kill him and loot his scarab.",
        "Araj's Scarab"), "Araj is a level 61 elite; group size needed is not confirmed for Forever."),
      finish(5803, arbington), accept(5505, arbington),
      finish(5505, arbington, "Arbington finishes the Skeleton Key. It opens Scholomance on Caer Darrow."),
    }),
  })

  B.q(3801, "Dark Iron Legacy", 52, 48)
  B.q(3802, "Dark Iron Legacy", 52, 48, 3801)
  special({ id = "shadowforge-key", title = "Dark Iron Legacy (Shadowforge Key)", zone = searing, levels = { 52, 60 },
    links = { "dungeon-blackrock-depths" },
    sources = { "https://www.wowhead.com/forever/quest=3802/dark-iron-legacy",
      "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever" },
    steps = {
      uncertain(accept(3801, blackrock, "Franclorn Forgewright's ghost lies on the stone ledge in the middle of Blackrock Mountain. You only see him as a spirit: die nearby and talk to him before you resurrect."),
        "Check that Forever keeps the ghost-only rule."),
      finish(3801, nil, "Listen to Franclorn's story."), accept(3802, nil, "Franclorn asks you to return his hammer to his statue."),
      goal(3802, nil, "In Blackrock Depths, kill Fineous Darkvire for the hammer Ironfel and place it on Franclorn's statue in the Shrine of Thaurissan.",
        "Ironfel placed"),
      finish(3802, nil, "Take the Shadowforge Key from the statue. It opens the doors deeper in Blackrock Depths."),
    },
  })
end

-- Dungeon guides point at the attunements they feed.
do
  local add = {
    ["dungeon-blackrock-depths"] = { "onyxia-attunement", "shadowforge-key", "molten-core-attunement" },
    ["dungeon-lower-blackrock-spire"] = { "ubrs-seal" },
    ["dungeon-upper-blackrock-spire"] = { "onyxia-attunement", "ubrs-seal" },
    ["dungeon-scholomance"] = { "scholomance-key" },
  }
  for _, section in ipairs(route.sections) do
    for _, id in ipairs(add[section.id] or {}) do
      section.links = section.links or {}
      local seen = false
      for _, have in ipairs(section.links) do seen = seen or have == id end
      if not seen then section.links[#section.links + 1] = id end
    end
  end
end
