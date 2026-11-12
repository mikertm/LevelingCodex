-- Horde route, levels 30-40. Source notes: tools/audits/2026-11-12-horde-30-40.md.
-- Shared Horde 30-60 setup lives at the top of this file: map sizes and flight networks for every
-- 30-60 map, the zeppelins and boats, and the B.horde helpers that QuestHorde4050.lua,
-- QuestHorde5060.lua, QuestHordeDungeons3060.lua and QuestHordeClass3060.lua use.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local M = B.maps

-- Map sizes: the Alliance 30-60 file already holds the client's UiMapAssignment sizes for every
-- 30-60 map. The Horde numbers its flight networks the other way round (Kalimdor 1, Eastern
-- Kingdoms 2), so the continent number is swapped as it is copied.
do
  local alliance = LevelingCodexQuests.ALLIANCE
  local swap = { [1] = 2, [2] = 1 }
  for map, size in pairs(alliance.extents) do
    route.extents[map] = route.extents[map] or size
  end
  for map, network in pairs(alliance.flightNetwork) do
    route.flightNetwork[map] = route.flightNetwork[map] or swap[network]
  end
end

local H = {}
B.horde = H

-- One leveling section of the Horde route.
function H.section(id, title, zone, low, high, sources, steps, extra)
  local section = { id = id, title = title, zone = zone, levels = { low, high }, verified = false,
    sources = sources, steps = steps }
  for key, value in pairs(extra or {}) do section[key] = value end
  route.sections[#route.sections + 1] = section
  return section
end

-- Quests carried in from an earlier chapter. A turn-in or objective whose pickup is not on the
-- Horde main route yet becomes optional (shown only while the quest is in your log); a pickup
-- whose prerequisite the main route never gives is dropped.
function H.carried(steps)
  local seen = {}
  for _, s in ipairs(route.sections) do
    if not s.side and not s.alternate then
      for _, step in ipairs(s.steps) do
        if step.quest and step.type == "accept" then seen[step.quest] = true end
      end
    end
  end
  local kept = {}
  for _, step in ipairs(steps) do
    local keep = true
    if step.quest and step.type == "accept" then
      for _, pre in ipairs(step.chain or {}) do
        if not seen[pre] then keep = false end
      end
      if keep then seen[step.quest] = true end
    elseif step.quest and not seen[step.quest] and not step.logOnly then
      step.optional = true
    end
    if keep then kept[#kept + 1] = step end
  end
  return kept
end

-- A main-route chapter (steps pass through H.carried) and an alternate route.
function H.chapter(id, title, zone, low, high, sources, suggest, steps)
  return H.section(id, title, zone, low, high, sources, H.carried(steps), { suggest = suggest })
end

function H.alternate(id, title, zone, low, high, sources, suggest, steps)
  return H.section(id, title, zone, low, high, sources, steps, { alternate = true, suggest = suggest })
end

-- Quest facts: q() always (re)defines, need() fills a gap only (the Alliance files register
-- many neutral 30-60 quests first; their chains are the same game facts).
function H.need(id, name, level, min, prerequisite, forever)
  if not B.quest[id] then B.q(id, name, level, min, prerequisite, forever) end
  return B.quest[id]
end

-- Limit a quest to some races or classes (QuestieDB requiredRaces / requiredClasses).
function H.limit(id, rules)
  for key, value in pairs(rules) do B.quest[id][key] = value end
end

-- A pickup for a dungeon detour (shown while that run is planned).
function H.dungeon(id, step) return B.forDungeon(step, "dungeon-" .. id) end

-- A boat, zeppelin or road the arrow uses when no known flight path joins two maps.
function H.road(from, to, waypoint, label)
  route.roadTo[to] = route.roadTo[to] or {}
  route.roadTo[to][from] = route.roadTo[to][from] or { waypoint = waypoint, label = label }
end

-- The Alliance dungeon guide's boss list (same instance, same bosses), for a Horde guide.
function H.bosses(id)
  for _, section in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if section.id == id then return section.bosses end
  end
  error("Horde 30-60: no Alliance dungeon guide " .. id)
end

-- A Horde dungeon guide with the Alliance guide's facts (title, map, levels, instance, bosses) and
-- only its entrance step: a placeholder until the Horde guide's own steps are written. `levels`
-- overrides the Alliance range when the Horde runs it at other levels.
function H.placeholderDungeon(id, levels)
  for _, a in ipairs(LevelingCodexQuests.ALLIANCE.sections) do
    if a.id == id then
      local entry
      for _, step in ipairs(a.steps) do
        if step.type == "dungeon" and step.map then entry = step; break end
      end
      local enter = { type = "dungeon", phase = "prepare", name = a.title, npc = entry and entry.npc,
        map = entry and entry.map, x = entry and entry.x, y = entry and entry.y,
        text = "Travel to " .. a.title .. " with your group and go in together." }
      route.sections[#route.sections + 1] = { id = id, title = a.title, zone = a.zone,
        levels = levels or { a.levels[1], a.levels[2] }, instanceID = a.instanceID, instance = a.instance,
        bosses = a.bosses, side = true, category = "dungeon", verified = false, sources = a.sources,
        steps = { enter } }
      return
    end
  end
  error("Horde 30-60: no Alliance dungeon guide " .. id)
end

-- Places on the 30-60 maps: B.on.<map>(name, x, y) (QuestData3040.lua), B.on.durotar etc. below.
for _, name in ipairs({ "durotar", "orgrimmar", "thunderBluff", "undercity", "mulgore", "barrens",
    "tirisfal", "silverpine", "stonetalon", "ashenvale", "hillsbrad", "needles", "alterac", "arathi",
    "desolace", "dustwallow" }) do
  local id = M[name]
  B.on[name] = B.on[name] or function(npc, x, y) return B.at(npc, x, y, id) end
end

-- Zeppelins and boats (zeppelin masters' spots from QuestieDB Forever).
do
  local road, at = H.road, B.at
  local durotarToGromgol = at("Snurk Bucksquick", 50.7, 12.9, M.durotar)
  local gromgolToOrgrimmar = at("Nez'raz", 31.4, 29.9, M.stv)
  local gromgolToUndercity = at("Squibby Overspeck", 31.5, 29.4, M.stv)
  local tirisfalToGromgol = at("Hin Denburg", 61.8, 59.2, M.tirisfal)
  local bootyBayPier = at(nil, 25.8, 73.1, M.stv)
  local ratchetPier = at(nil, 63.7, 38.6, M.barrens)
  road(M.durotar, M.stv, durotarToGromgol, "Take the zeppelin to Grom'gol")
  road(M.orgrimmar, M.stv, durotarToGromgol, "Leave Orgrimmar for the zeppelin to Grom'gol")
  road(M.tirisfal, M.stv, tirisfalToGromgol, "Take the zeppelin to Grom'gol")
  road(M.undercity, M.stv, tirisfalToGromgol, "Leave the Undercity for the zeppelin to Grom'gol")
  road(M.stv, M.durotar, gromgolToOrgrimmar, "Take the zeppelin to Orgrimmar")
  road(M.stv, M.orgrimmar, gromgolToOrgrimmar, "Take the zeppelin to Orgrimmar")
  road(M.stv, M.tirisfal, gromgolToUndercity, "Take the zeppelin to the Undercity")
  road(M.stv, M.undercity, gromgolToUndercity, "Take the zeppelin to the Undercity")
  road(M.undercity, M.durotar, at(nil, 60.8, 58.7, M.tirisfal), "Take the zeppelin to Orgrimmar")
  road(M.undercity, M.orgrimmar, at(nil, 60.8, 58.7, M.tirisfal), "Take the zeppelin to Orgrimmar")
  road(M.orgrimmar, M.undercity, at(nil, 50.8, 13.8, M.durotar), "Leave Orgrimmar for the zeppelin to the Undercity")
  road(M.barrens, M.stv, ratchetPier, "Take the Booty Bay boat from the Ratchet dock")
  road(M.stv, M.barrens, bootyBayPier, "Take the Ratchet boat from the Booty Bay docks")
  -- Overland legs out of the Horde towns used by more than one band.
  road(M.barrens, M.dustwallow, at(nil, 56.4, 63.6, M.barrens), "Take the east road out of the Barrens into Dustwallow")
  road(M.needles, M.tanaris, B.on.needles(nil, 75.5, 96.9), "Follow the Shimmering Flats road south into Tanaris")
  road(M.tanaris, M.ungoro, B.on.tanaris(nil, 27.8, 56.9), "Go west through the ridge path into Un'Goro")
  road(M.ungoro, M.silithus, B.on.ungoro(nil, 29.5, 22.3), "Take the northwest ramp out of Un'Goro into Silithus")
  road(M.stonetalon, M.desolace, B.on.stonetalon(nil, 29.2, 90.5), "Take the south road out of Stonetalon into Desolace")
  road(M.desolace, M.feralas, B.on.desolace(nil, 43.9, 95.6), "Follow the road south out of Desolace into Feralas")
  road(M.feralas, M.desolace, B.on.feralas(nil, 44.9, 1.6), "Follow the road north into Desolace")
  road(M.ashenvale, M.felwood, B.on.ashenvale(nil, 55.6, 18.6), "Take the north road out of Ashenvale into Felwood")
  road(M.ashenvale, M.azshara, B.on.ashenvale(nil, 94.6, 47.8), "Take the east road out of Ashenvale into Azshara")
  road(M.felwood, M.winterspring, B.on.felwood(nil, 64.6, 8.2), "Go through Timbermaw Hold to Winterspring")
  road(M.hillsbrad, M.alterac, B.on.hillsbrad(nil, 54.6, 40.9), "Climb the north road into the Alterac Mountains")
  road(M.hillsbrad, M.arathi, B.on.hillsbrad(nil, 82.4, 39.6), "Take the east road out of Hillsbrad into Arathi")
  road(M.arathi, M.hillsbrad, B.on.arathi(nil, 17.1, 35.3), "Take the west road into Hillsbrad")
  road(M.hillsbrad, M.hinterlands, B.on.hillsbrad(nil, 86.4, 32.0), "Take the northeast pass into the Hinterlands")
  road(M.wpl, M.epl, B.on.wpl(nil, 69.4, 49.6), "Take the east road into the Eastern Plaguelands")
  road(M.swamp, M.blasted, B.on.swamp(nil, 34.2, 66.4), "Take the road south from the Swamp into the Blasted Lands")
end

-- 30-40 chapters follow.
