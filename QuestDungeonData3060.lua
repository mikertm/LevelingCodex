-- Alliance dungeon detours for levels 30-60. Source notes: tools/audits/2026-11-10-dungeons-30-60.md.
-- Outdoor pickups live on the leveling route (forDungeon); the guides here hold the trip, the run and the hand-ins.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.ALLIANCE
local M = B.maps
local at, accept, finish, action = B.at, B.accept, B.finish, B.action
local objective, withItem, note = B.objectiveAt, B.withItem, B.note

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

B.dungeon = { add = add, tip = tip, enter = enter }

-- Entrances. Each guide below is filled in by its own block; these stubs make every dungeon
-- ID available to the route's forDungeon tags from the start.
local stubs = {
  { "dungeon-scarlet-monastery-library", "Scarlet Monastery: Library", M.tirisfal, 33, 40, 189, "Scarlet Monastery",
    at("Scarlet Monastery approach", 82.65, 32.88, M.tirisfal) },
  { "dungeon-scarlet-monastery-armory", "Scarlet Monastery: Armory", M.tirisfal, 35, 42, 189, "Scarlet Monastery",
    at("Scarlet Monastery approach", 82.65, 32.88, M.tirisfal) },
  { "dungeon-scarlet-monastery-cathedral", "Scarlet Monastery: Cathedral", M.tirisfal, 37, 44, 189, "Scarlet Monastery",
    at("Scarlet Monastery approach", 82.65, 32.88, M.tirisfal) },
  { "dungeon-razorfen-downs", "Razorfen Downs", M.barrens, 35, 42, 129, "Razorfen Downs",
    at("Razorfen Downs entrance", 49.3, 93.1, M.barrens) },
  { "dungeon-uldaman", "Uldaman", M.badlands, 38, 47, 70, "Uldaman", at("Uldaman entrance", 42.4, 12.9, M.badlands) },
  { "dungeon-krol-dok-stronghold", "Krol'dok Stronghold", M.riverglades, 40, 45, nil, "Krol'dok Stronghold", nil },
  { "dungeon-zul-farrak", "Zul'Farrak", M.tanaris, 42, 48, 209, "Zul'Farrak", at("Zul'Farrak entrance", 38.7, 19.8, M.tanaris) },
  { "dungeon-maraudon", "Maraudon", M.desolace, 44, 52, 349, "Maraudon", at("Maraudon outer cave", 29.1, 62.6, M.desolace) },
  { "dungeon-sunken-temple", "Sunken Temple", M.swamp, 47, 54, 109, "Sunken Temple",
    at("Temple of Atal'Hakkar", 69.7, 53.5, M.swamp) },
  { "dungeon-blackrock-depths", "Blackrock Depths", M.searing, 50, 58, 230, "Blackrock Depths",
    at("Blackrock Mountain", 34.8, 85.3, M.searing) },
  { "dungeon-lower-blackrock-spire", "Lower Blackrock Spire", M.searing, 55, 60, 229, "Blackrock Spire",
    at("Blackrock Mountain", 34.8, 85.3, M.searing) },
  { "dungeon-upper-blackrock-spire", "Upper Blackrock Spire", M.searing, 58, 60, 229, "Blackrock Spire",
    at("Blackrock Mountain", 34.8, 85.3, M.searing) },
  { "dungeon-dire-maul-east", "Dire Maul: East", M.feralas, 55, 60, 429, "Dire Maul", at("Dire Maul", 59.0, 44.8, M.feralas) },
  { "dungeon-dire-maul-west", "Dire Maul: West", M.feralas, 57, 60, 429, "Dire Maul", at("Dire Maul", 59.0, 44.8, M.feralas) },
  { "dungeon-dire-maul-north", "Dire Maul: North", M.feralas, 57, 60, 429, "Dire Maul", at("Dire Maul", 59.0, 44.8, M.feralas) },
  { "dungeon-scholomance", "Scholomance", M.wpl, 57, 60, 289, "Scholomance", at("Caer Darrow", 69.4, 72.8, M.wpl) },
  { "dungeon-stratholme", "Stratholme", M.epl, 57, 60, 329, "Stratholme", at("Stratholme gate", 31.2, 15.6, M.epl) },
}

B.dungeons = {}
for _, s in ipairs(stubs) do
  local id, title, zone, low, high, instanceID, instance, door = s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8]
  local section = add({ id = id, title = title, zone = zone, levels = { low, high }, instanceID = instanceID,
    instance = instance, sources = { "https://www.wowhead.com/forever/zones" } }, {
    note(enter(title, door, "Meet your group at the entrance and go in together."),
      "Entrance position from the classic map; check it in game."),
  })
  B.dungeons[id] = section
end
