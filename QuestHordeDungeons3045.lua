-- Horde dungeon detours, levels 29-48. Source notes: tools/audits/2026-11-12-horde-dungeons-30-45.md.
-- Each guide is self-contained (its own pickups and lead-in chains); outdoor pickups are also
-- tagged on the leveling route (B.horde.dungeon) where the route passes their givers.
local B = LevelingCodexQuests.build
local H = B.horde

-- Placeholders (Alliance facts, entrance only) until each Horde guide is written.
for _, id in ipairs({ "dungeon-gnomeregan", "dungeon-excavation-site", "dungeon-city-of-dalaran",
    "dungeon-scarlet-monastery-graveyard", "dungeon-scarlet-monastery-library", "dungeon-scarlet-monastery-armory",
    "dungeon-scarlet-monastery-cathedral", "dungeon-razorfen-downs", "dungeon-uldaman", "dungeon-zul-farrak" }) do
  H.placeholderDungeon(id)
end
