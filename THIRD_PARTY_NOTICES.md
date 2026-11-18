# Loot data references

The equipment catalog contains normalized factual records, not another addon's code, art,
scoring profiles, or interface text. The generator, comparison rules and interface are authored
for Leveling Codex. Names identify game items, creatures, quests and locations.

- Client item identity and recipe facts: Blizzard client build 1.60.1.70888, served by
  [wago.tools](https://wago.tools/). This data is not a Blizzard endorsement.
- Acquisition and spawn references: the public
  [quest database snapshot](https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf).
  Its [licensing statement](https://github.com/Questie/QuestieDB/blob/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/LICENSE.md)
  describes historical contribution and GPLv3 licensing qualifications. Provenance is retained
  for these factual references. Database references are not claims of confirmed live server drops.
- Item names, requirements, normalized stats and effects were checked against the
  [Forever item tooltip service](https://nether.wowhead.com/forever/tooltip/item/5191).
  Stored records are factual fields and concise unsupported-effect warnings, not page copies.
- Dungeon entrance locations come from existing Codex routes. Entrances are distinguished
  from boss rooms.

Exact revisions, retrieval dates, input hashes, field origins, coverage counts and exclusions
are in the source repository's `tools/reference/loot-manifest.json`. No drop rate, auction price,
or unavailable source location is invented. Live client facts take precedence for actual links.
