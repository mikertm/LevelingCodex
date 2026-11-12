-- Horde dungeon detours, levels 44-60. Source notes: tools/audits/2026-11-12-horde-dungeons-45-60.md.
-- Each guide is self-contained (its own pickups and lead-in chains); outdoor pickups are also
-- tagged on the leveling route (B.horde.dungeon) where the route passes their givers.
local B = LevelingCodexQuests.build
local H = B.horde

-- Placeholders (Alliance facts, entrance only) until each Horde guide is written.
for _, id in ipairs({ "dungeon-maraudon", "dungeon-sunken-temple", "dungeon-blackrock-depths",
    "dungeon-lower-blackrock-spire", "dungeon-upper-blackrock-spire", "dungeon-dire-maul-east",
    "dungeon-dire-maul-west", "dungeon-dire-maul-north", "dungeon-scholomance", "dungeon-stratholme" }) do
  H.placeholderDungeon(id)
end
