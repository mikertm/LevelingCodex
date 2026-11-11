-- Horde route: the Windshaper (Horde) Skyborne start on Zephras Isle, 1-12, then the airship to
-- Mulgore, Thrall in Orgrimmar and the road to the Crossroads.
-- Source notes: tools/audits/2026-11-10-horde-skyborne.md.
--
-- Zephras Isle is shared with the High Order (Alliance) Skyborne in QuestData.lua (`zi`). Steps
-- for quests both factions take are copied from there; the Alliance-only chains are left out and
-- the Windshaper ones put in their place.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local M, zi = B.maps, B.zi
local at, q, quest, accept, finish = B.at, B.q, B.quest, B.accept, B.finish
local objective, part, action, taxi, withItem, along, only =
  B.objectiveAt, B.objectivePart, B.action, B.taxi, B.withItem, B.along, B.only
local SHAMAN = { class = "SHAMAN" }

-- Alliance-only on Zephras Isle: the High Order chains, the Valanaar story that leads to the
-- skycutter for Dalaran, the Mage quests (Windshapers can't be Mages) and the Stormwind arrival.
local allianceOnly = {}
for _, id in ipairs({ 92481, 92597, 93461, 92596, 94413, 92701, 92699, 92709, 92727, 92849, 92850, 92693, 92703,
    99260, 92840, 92834, 92860, 93320, 92642, 92645, 92880, 92881, 92643, 92644, 94568, 92640, 93065, 92947,
    93958, 93835, 94369, 93089, 94946, 94947, 94912, 93949, 92741, 93791, 93797, 98021 }) do
  allianceOnly[id] = true
end

-- The Windshaper quest that stands in for an Alliance one as a prerequisite.
local hordeFor = { [93461] = 92514, [92596] = 92595, [94413] = 94411, [92701] = 92579, [92699] = 92700 }

-- Copy the shared steps of one Alliance Zephras list: quest steps for shared quests, and travel or
-- training steps on the island (not the skycutter to Dalaran). `also` lists lose the Alliance-only quests.
local function shared(steps)
  local result = {}
  for _, step in ipairs(steps) do
    local keep = step.quest and not allianceOnly[step.quest]
      or (not step.quest and step.map == M.zephras and step.type ~= "boat")
      or (not step.quest and not step.map and step.type == "train")
    if keep then
      local copy = {}
      for key, value in pairs(step) do copy[key] = value end
      if copy.chain then
        local chain = {}
        for _, id in ipairs(copy.chain) do
          local horde = hordeFor[id] or (not allianceOnly[id] and id)
          if horde then chain[#chain + 1] = horde end
        end
        copy.chain = #chain > 0 and chain or nil
      end
      if copy.also then
        local also = {}
        for _, id in ipairs(copy.also) do
          if not allianceOnly[id] then also[#also + 1] = id end
        end
        copy.also = #also > 0 and also or nil
      end
      result[#result + 1] = copy
    end
  end
  return result
end

-- Put `steps` after the first step matching type and quest (or before it with `before`).
local function insert(list, kind, id, steps, before)
  for i, step in ipairs(list) do
    if step.type == kind and step.quest == id then
      local at = before and i - 1 or i
      for n, new in ipairs(steps) do table.insert(list, at + n, new) end
      return list
    end
  end
  error("Horde Skyborne: no " .. kind .. " step for quest " .. id)
end

local function z(name, x, y) return at(name, x, y, M.zephras) end
local boro = z("Windshaper Boro", 42.79, 23.58)
local ventaari = z("Ventaari Brightwish", 42.61, 24.38)
local manifestation = z("Minor Manifestation of Earth", 49.66, 24.02)
local illaya = z("Illaya Amberwind", 43.51, 44.77)
local aarnor = z("Aarnor Galestrike", 43.45, 44.87)
local riaani = z("Riaani Nightwind", 59.06, 72.98)
local ayessa = z("Ayessa Dawnsinger", 59.15, 79.77)
local sessaria = z("Sessaria Skystride", 58.31, 78.51)
local olariaan = z("Olariaan Swiftburn", 51.24, 86.19)
local airship = z("Windshaper airship dock", 57.92, 80.78)
local alaana = at("Alaana Stormwalker", 33.39, 22.51, M.mulgore)
local muln = at("Muln Earthfury", 33.41, 22.58, M.mulgore)
local turak = at("Turak Runetotem", 76.48, 27.22, M.thunderBluff)
local tal = at("Tal", 47.0, 49.83, M.thunderBluff)
local bluffLift = at("Thunder Bluff lift", 37.3, 38.4, M.mulgore)
local og = function(name, x, y) return at(name, x, y, M.orgrimmar) end
local doras, thrall = og("Doras", 45.12, 63.89), og("Thrall", 31.73, 37.82)

q(92484, "Embracing the Elements", 2, 2, 92461, true, "SHAMAN")
q(92466, "Call of Earth", 4, 4, 92484, true, "SHAMAN")
q(92467, "Call of Earth", 4, 4, 92466, true, "SHAMAN")
q(92468, "Call of Earth", 4, 4, 92467, true, "SHAMAN")
q(92598, "The Gift of Skysight", 4, 2, 92461, true)
q(92514, "Welcome to Shen'dar Village", 6, 4, 92472, true)
q(92595, "The Windshapers", 6, 4, 92472, true)
q(94411, "Meddlesome Mages", 6, 4, 92595, true)
q(92579, "To Valanaar", 9, 6, { 92550, 93927 }, true)
q(92700, "The Grand Skyseer", 9, 6, 92579, true)
q(93735, "The Broken Construct", 9, 6, 92700, true)
q(93737, "The Broken Construct", 9, 6, 93735, true)
q(93738, "The Broken Construct", 9, 6, 93737, true)
q(97243, "Call of Fire", 10, 10, nil, true, "SHAMAN")
q(97244, "Call of Fire", 10, 10, 97243, true, "SHAMAN")
q(97245, "Call of Fire", 10, 10, 97244, true, "SHAMAN")
q(97257, "Call of Fire", 10, 10, 97245, true, "SHAMAN")
q(95350, "Welcome to Azeroth", 13, 7, nil, true)
q(94911, "Child of Nature", 10, 10, nil, true, "DRUID")
q(98024, "Journey to the Crossroads", 13, 7, 95350, true)
-- Windshaper-only steps are for Horde Skyborne.
for _, id in ipairs({ 92484, 92466, 92467, 92468, 92598, 92514, 92595, 94411, 92579, 92700, 93735, 93737,
    93738, 97243, 97244, 97245, 97257, 95350, 94911, 98024 }) do
  quest[id].race = "SKYBORNE"
end

-- Thendal Grove (1-5): the Shaman letter and totem, and the Skysight lesson instead of the ley lines.
local thendal = shared(zi.thendal)
insert(thendal, "accept", 92532, { accept(92484, z("Rorian the Dayseeker", 41.9, 23.48)) })
insert(thendal, "turnin", 92532, {
  withItem("Humming Recall Crystal", finish(92484, boro, "Read the Humming Recall Crystal, then speak to Windshaper Boro by the great tree.")),
  accept(92466, boro),
})
insert(thendal, "accept", 93552, {
  accept(92598, ventaari, "Ventaari Brightwish stands on the south side of the grove."),
})
insert(thendal, "complete", 92465, {
  objective(92598, z(nil, 48.4, 20.4),
    "Use your Skysight ability at the Elemental Convergence, the swirling stones north-east of Yala's camp.",
    "Use Skysight at the Elemental Convergence"),
  objective(92466, z(nil, 46.6, 24.6), "Shamans: loot a Signet of Akir from the Al'Aketh Converts.", "Signet of Akir"),
}, true)
insert(thendal, "turnin", 92469, {
  finish(92598, ventaari),
  finish(92466, boro), accept(92467, boro),
  withItem(6635, finish(92467, manifestation,
    "Ride east past Yala's camp to the Rise of Spirits. Drink the Earth Sapta there and speak to the spirit that appears.")),
  accept(92468, manifestation),
  finish(92468, boro, "Bring the Rough Quartz back to Windshaper Boro."),
})

-- Shen'dar Village (5-9): the Windshapers instead of the High Order.
local shendar = shared(zi.shendar)
insert(shendar, "turnin", 92472, {
  accept(92514, zi.aonda),
  accept(92595, illaya, "Illaya Amberwind waits with the Windshapers on the west side of the village."),
  objective(92595, illaya, "Listen to Illaya."),
  finish(92595, illaya), accept(94411, illaya),
  objective(92514, zi.coriella, "Speak to Illaya, then to Coriella Calmbreeze at the inn.",
    "Illaya Amberwind", "Coriella Calmbreeze"),
})
insert(shendar, "accept", 92517, { finish(92514, zi.aonda) }, true)
insert(shendar, "turnin", 93319, {
  objective(94411, z(nil, 45.8, 39.3),
    "Go north of the village to the High Order camp. Defeat six High Order Apprentices.", "6 High Order Apprentices"),
  finish(94411, illaya),
})
insert(shendar, "accept", 93948, {
  accept(92579, zi.aonda, "Take Aonda's report for Valennia in Valanaar."),
}, true)

-- Valanaar (9-12): the Grand Skyseer and the Broken Construct, the Shaman fire totem, then the airship.
local valanaar = shared(zi.valanaar)
insert(valanaar, "accept", 94484, {
  accept(97243, sessaria, "Shamans: Sessaria Skystride by the brazier in Valanaar sends you to the Shrine of Flames."),
})
insert(valanaar, "turnin", 93948, {
  finish(92579, zi.valennia), accept(92700, zi.valennia),
  finish(92700, ayessa, "Grand Skyseer Ayessa stands on the south side of town."),
  accept(93735, ayessa),
  finish(93735, riaani, "Riaani Nightwind is on the west side of Valanaar."), accept(93737, riaani),
  part(93737, 1, riaani, "Listen to Riaani.", "Listen to Riaani Nightwind"),
  part(93737, 2, z(nil, 52.75, 64.73),
    "Go west to the Shriekling Den. Click the construct parts on the cave's bottom floor for the crystallized lightning.",
    "Crystallized Lightning"),
})
insert(valanaar, "accept", 92685, {
  only(finish(97243, olariaan, "Shamans: bring the torch to Olariaan at the Shrine of Flames, south of the orchard."), SHAMAN),
  only(accept(97244, olariaan), SHAMAN),
  only(objective(97244, z("Skypriest Faladiel", 64.38, 63.59),
    "Shamans: ride north-east to Skypriest Faladiel and take her heart.", "Faladiel's Heart"), SHAMAN),
  only(finish(97244, olariaan), SHAMAN), only(accept(97245, olariaan), SHAMAN),
})
insert(valanaar, "complete", 92685, {
  part(93737, 4, z(nil, 43.55, 75.0), "Search the bandit camp on the same hill for the Air Construct Core.",
    "Air Construct Core"),
  only(objective(97245, z("Kuramaa", 42.39, 68.89),
    "Shamans: climb north to Kuramaa's home in the Shen'dar Highlands. Defeat the spirit and take its mask.",
    "Kuramaa's Mask"), SHAMAN),
})
insert(valanaar, "turnin", 92685, {
  only(finish(97245, olariaan), SHAMAN), only(accept(97257, olariaan), SHAMAN),
  only(part(97257, 1, olariaan, "Shamans: wait for Olariaan to begin the ritual and follow his instructions.",
    "Complete the ritual"), SHAMAN),
  only(withItem(277329, part(97257, 2, z(nil, 58.31, 78.83),
    "Shamans: carry the Eternal Flame to the brazier in Valanaar before the timer runs out.",
    "Light the Brazier of Eternal Flame")), SHAMAN),
  only(finish(97257, sessaria), SHAMAN),
})
insert(valanaar, "complete", 93317, {
  part(93737, 3, z(nil, 50.64, 44.3),
    "Follow the water north to Windsong Lake. Kill Windsong Crawlers until one gives up the Enchanted Gyrozephyr.",
    "Enchanted Gyrozephyr"),
})
-- Copied texts that mention Alliance-only quest items.
for _, step in ipairs(valanaar) do
  if step.type == "complete" and step.quest == 94487 then
    step.text = "Loot heirlooms and ears from the Footsoldiers and Stormchasers east of Elegael."
  elseif step.type == "complete" and step.quest == 94485 then
    step.text = "Pick any remaining moss from the trees. Loot feathers from Shrieklings between trees."
  end
end
for _, step in ipairs({
  finish(93737, riaani), accept(93738, riaani),
  finish(93738, ayessa),
  action("boat", airship, "Board the Windshaper airship at the dock below Ayessa. It lands in northern Mulgore."),
  accept(95350, alaana, "Alaana Stormwalker meets you where the airship lands."),
  accept(94911, muln),
  action("goto", bluffLift, "Follow the road south to Thunder Bluff and ride a lift up the mesa."),
  taxi("getfp", tal, "Thunder Bluff, Mulgore", "Learn the flight path from Tal on the central rise."),
  finish(94911, turak, "Druids: cross the bridges to Elder Rise and find Turak Runetotem."),
  taxi("fly", tal, "Orgrimmar, Durotar", "Fly to Orgrimmar."),
  taxi("getfp", doras, "Orgrimmar, Durotar", "Doras keeps the wind riders on the tower in the Valley of Strength."),
  finish(95350, thrall, "Cross the city west to Grommash Hold and speak to Thrall."),
  accept(98024, thrall),
  action("goto", at(nil, 13.0, 65.0, M.orgrimmar),
    "Leave Orgrimmar by the west gate and follow the road south through the Barrens to the Crossroads."),
}) do valanaar[#valanaar + 1] = step end

local function trainers(list, extra)
  local result = { extra }
  for _, trainer in ipairs(list) do result[#result + 1] = trainer end
  return result
end

local sources = {
  "https://www.warcrafttavern.com/forever/guides/zephras-isle-walkthrough/",
  "https://warcraft.wiki.gg/wiki/Skyborne_starting_experience",
  "https://www.warcrafttavern.com/forever/guides/skyborne/",
  "https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever",
}
route.starts.SKYBORNE = "zephras"
for _, section in ipairs({
  { "zephras", "Thendal Grove", 1, 5, thendal, trainers(zi.thendalTrainers, { "SHAMAN", boro }) },
  { "shendar", "Shen'dar Village", 5, 9, shendar, trainers(zi.shendarTrainers, { "SHAMAN", aarnor }) },
  -- No Shaman trainer is confirmed in Valanaar: Shamans train in Shen'dar or Thunder Bluff.
  { "valanaar", "Valanaar", 9, 12, valanaar, zi.valanaarTrainers },
}) do
  route.sections[#route.sections + 1] = { id = section[1], title = section[2], zone = M.zephras,
    levels = { section[3], section[4] }, start = "SKYBORNE", verified = false, sources = sources,
    steps = B.withTrainers(section[5], section[6]) }
end
