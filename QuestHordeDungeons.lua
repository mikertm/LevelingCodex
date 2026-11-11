-- Horde dungeon detours (1-30). Quest and travel sources: tools/audits/2026-11-10-horde-dungeons.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE
local m = B.maps

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
  return B.action("note", nil, text, { name = name })
end

-- Placeholders so outdoor routes can tag pickups with forDungeon(step, id) before the
-- checklists are written. Each id here must stay stable.
for _, run in ipairs({
  { "dungeon-ragefire-chasm", "Ragefire Chasm", m.orgrimmar, 13, 18, 389 },
  { "dungeon-ruins-of-lordaeron", "Ruins of Lordaeron", m.tirisfal, 15, 20, 2999 },
  { "dungeon-wailing-caverns", "Wailing Caverns", m.barrens, 17, 25, 43 },
  { "dungeon-shadowfang-keep", "Shadowfang Keep", m.silverpine, 22, 30, 33 },
  { "dungeon-blackfathom-deeps", "Blackfathom Deeps", m.ashenvale, 24, 32, 48 },
  { "dungeon-razorfen-kraul", "Razorfen Kraul", m.barrens, 29, 38, 47 },
}) do
  add({ id = run[1], title = run[2], zone = run[3], levels = { run[4], run[5] }, instanceID = run[6],
    sources = { "https://www.warcrafttavern.com/forever/guides/leveling" } },
    { note("Checklist coming", "This Horde checklist is still being written.") })
end
