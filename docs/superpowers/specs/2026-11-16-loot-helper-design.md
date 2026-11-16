# Loot: find upgrades, compare gear, and follow its sources

Date: 2026-11-16. Status: written specification approved by the owner on 2026-11-16.

## Intent and agreed scope

Players want a Loot tab that answers three questions: what gear would help me, where do I get it,
and is this particular item better than what I wear? The owner approved a catalog, a shared
comparison engine, source tracking, tooltip and reward hints, enchant advice, editable profiles,
and controller support. Recommendations follow the selected Codex talent path by default.

The installed reference was inspected for behavior and coverage. Product code, art, explanatory
text, and scoring profiles will be authored for Codex. Generated facts must have traceable game
or upstream database sources. The inspected reference addon's name does not appear in new
product code, documentation, or UI.

Success means useful coverage for all nine supported classes, both factions, every functional
equipment slot, and levels 1-60, including Forever-specific gear. A player can investigate a
recommendation, track its source, and compare an item outside the catalog using the same rules.
No feature requires another addon or surviving SavedVariables.

This is a gear advisor with explicit scoring assumptions. It does not claim to simulate combat
or convert a gear-score percentage into a damage, healing, or survival percentage.

## Findings that shape the design

- The inspected implementation includes slot lists, source filters, acquisition tracking,
  maps, unit and item tooltip hints, quest and merchant hints, crafted gear, enchant advice,
  character preview, custom profiles, and controller navigation. These are the functional
  categories to account for, rather than treating the feature as a small item list.
- Its indicator cache is populated from recommendation lists. Codex instead compares any
  readable equippable item; catalog membership only supplies acquisition information.
- Its ranking includes imported priorities, curated ordering, item-level fallbacks, and
  maximum random-suffix scores. Codex separates editorial acquisition advice from the
  comparison calculation and never treats a hypothetical best roll as an actual item.
- Codex already provides talent-path selection, quest IDs and routes, profession recipes,
  map navigation, pooled tab widgets, and controller support. Use these existing systems.
- The current quest reward hint identifies the best vendor price. Upgrade advice must be
  distinct from that hint so a player can see both the useful reward and the best cash reward.
- The committed game reference includes item data for professions, but does not yet provide
  a general equipment catalog or comprehensive acquisition tables. That pipeline is part of
  this feature, not an assumed existing asset.

## User experience

### Loot tab

Register Loot through `ns.addTab`, before Settings. Keep parchment cards, double borders,
Morpheus headings, Forever teal, per-tab scroll memory, and the existing pooled controls.
Use compact internal sections: Upgrades, Compare, Tracked, and Profiles. Section selection
and filters retain session state; per-character saving is a convenience.

The header shows the character, level, active loot profile, and whether that profile follows
the talent path or is manually selected. A Custom talent path uses the strongest represented
tree as its default role; ties use the guide profile and show that choice. The player can
override it without changing their talent path. Switching paths refreshes automatic profiles.

Upgrades starts with the equipped slots and a short list of the most useful accessible
improvements. Clicking a slot opens its equipped comparison and candidate list. Rings and
trinkets retain separate physical slots while sharing a candidate category. Weapon slots
show the entire proposed hand configuration when replacing one item affects the other hand.
Shirts, tabards, and other cosmetic slots are not called combat upgrades.

Filters cover slot, required-level range, zone, source category, specific dungeon, profession,
and acquisition style: solo/questing, group/dungeons, buy/craft, or all sources. All sources
is the default. Future-level gear is available through an explicit planning filter and carries
its required level. Ineligible gear is hidden by default, with a toggle to inspect the reason.
Search accepts item names and item IDs. Lists use pagination or incremental rendering and
do not limit the comparison engine to a handful of curated recommendations.

Every result shows the item, verdict, compared slot or hand setup, estimated score change,
the main stat tradeoff, source, requirements, and evidence confidence. Acquisition difficulty
and score gain are separate fields. Default ordering groups usable upgrades first and sorts
by score gain, with deterministic name/ID tie breakers. A separate acquisition sort favors
current-zone and route-linked sources without changing the power verdict.

A detail card expands all acquisition options. A quest source includes the quest title,
giver/turn-in location when known, prerequisites, faction restrictions, group/dungeon context,
and a link into the Codex route when that route contains the quest. Other sources show their
boss/creature/object, dungeon or zone, vendor and verified cost, recipe and materials,
reputation, or PvP requirement. World drops are labeled random world drops; no invented
specific farm location or drop percentage is supplied. Unknown facts say they are unknown.

Map and Track actions use verified coordinates. Dungeon targets distinguish the entrance
from the boss location. Do not place a boss pin at an entrance as if that were its spawn.
Opening a loot target never silently advances or replaces the active quest route.

### Compare and planning

Compare accepts a pasted item link or item ID and offers readable equipment and bag items
as clickable choices. Full links preserve random suffixes and item-specific modifications.
Show candidate and equipped item side by side, the profile, stat differences, verdict, and
any excluded effects. The engine works even when the catalog has no record for the item.

Planning can preview another supported class, faction, profile, and level from 1-60.
Planning results are labeled recommendations for the preview context. Comparisons against
the live character remain available only when the context matches that character; otherwise
the player must explicitly supply baseline items. A preview is not a combat simulation.

### Tracking and contextual guidance

Track multiple desired items. Each target has a stable item/variant/source identity, a detail
card, and session state: tracked, obtained, or dismissed. Players can undo obtained/dismissed.
Reading the equipped gear and bags automatically detects owned targets, respecting suffixes.
Bank contents are considered only when the client supplies a known snapshot; never imply a
closed bank was scanned. Completion of a quest without its reward does not mark the item owned.

Provide a compact optional loot tracker using Codex frame art and controller support. Its
controls open the Loot details, map the source, or untrack. Notifications are optional,
deduplicated, and limited to meaningful changes such as a tracked item obtained or a new
upgrade found in the player's bags. Do not announce every scanned catalog item.

Add comparison lines to supported item tooltips, including bag, loot, quest reward, merchant,
and crafted-output items. Unit tooltips can show relevant verified drops for that creature.
Use stable IDs/GUIDs when available; an ambiguous creature name must not claim an exact drop
table. Character equipment tooltips offer a Codex slot lookup without replacing normal clicks.

Quest completion shows separate gear advice and best vendor value. A best-gear marker appears
only after all equippable choices have a conclusive comparison; otherwise show the known
comparison and explain that some data is pending. Preserve the existing vendor-price setting.
Annotations never select a reward, roll on loot, purchase, craft, equip, or change a recipe list.

Enchant advice lists suitable enchants and their requirements and sources, with links into
the profession guide where applicable. Separate an enchant improvement from a replacement
item improvement. Show consumable cost only when verified; unknown auction prices stay unknown.

## Comparison contract

All surfaces call the same engine. Inputs are a full item link or ID, the character/profile
context, and an equipped or explicitly supplied baseline. Results contain a verdict, reason,
candidate and baseline stats/scores, delta, replaced slots, eligibility, confidence, warnings,
and source references. Comparison must not depend on which rows a UI filter happens to show.

Verdicts are `upgrade`, `sidegrade`, `downgrade`, `cannotEquip`, `needsReview`, or `loading`.
Runtime labels are ASCII. `loading` is transient; exhausted bounded retries turn into a clear
unavailable-data reason, not a zero-stat item or a downgrade.

1. Resolve the exact item and known eligibility: class, race, level, armor/weapon proficiency,
   slot, hand rules, unique-equipped group, profession, reputation, and relevant restrictions.
   A known violation returns Cannot equip. An unknown essential restriction returns Needs
   review. Future gear is labeled for planning and cannot be called usable now.
2. Read item stats through guarded client APIs, supplemented by generated Forever facts.
   Avoid counting equivalent API stat aliases twice. Store base item and modification data
   separately when the client allows it, preventing enchant/stat double counting.
3. For an actual link, use its actual suffix and modifications. An item ID with unresolved
   random stats returns a range for browsing and Needs review for a definitive comparison.
   It must not inherit a maximum possible suffix roll.
4. Calculate a weighted advisory score from an authored class/path profile. Profiles expose
   each weight, weapon-hand policy, and any supported conversion. Document rationales against
   the Forever reference. Do not import another expansion's weights as established game facts.
5. Compare legal equipment configurations. Test both ring/trinket replacements and select the
   best legal improvement; reject illegal unique duplicates. Compare a two-hander against the
   relevant main/off-hand combination. A one-hander that needs an off-hand uses the existing
   legal partner or requires an explicit partner; never invent an off-hand. Check dual wield,
   main-hand/off-hand restrictions, and weapon-type requirements before scoring.
6. Treat weapon DPS, speed, ranged use, shields, and feral weapons according to the selected
   role. Do not count ordinary weapon DPS as feral form damage without verified support.
   Tank armor and shield mitigation contribute to tank profiles; a lower armor class is not
   penalized by an arbitrary item-level margin.
7. Supported deterministic effects can contribute with documented rules. Unmodeled procs,
   on-use effects, set bonuses changed by the swap, or material cap interactions produce
   Needs review and a provisional stat comparison. Do not silently discard these and give a
   conclusive verdict. Known cosmetic/flavor text does not itself make an item uncertain.
8. For complete comparisons, a positive score delta above 1% of the baseline score is an
   Upgrade, below -1% a Downgrade, and within that band a Sidegrade. The threshold is disclosed
   as an advisory deadband. With an empty baseline, any positive complete score is an Upgrade;
   show 'fills an empty slot' instead of dividing by zero. Two zero scores produce Needs review.
9. Show the percentage as 'estimated gear score', plus the actual stat changes. Explicitly
   identify the replaced item/slots. Missing data never becomes numeric zero by default.

Profiles default to the existing talent paths, with separate relevant tank/healer/caster/melee/
ranged policies. An automatic profile follows `ns.talentVersion`. Users may select another
profile or edit bounded nonnegative numeric weights and weapon preferences. Validate every
field, support reset, and provide a versioned plain-text export/import code so a lost save can
be restored without evaluating Lua. Custom weights remain labeled advisory.

## Data and verification pipeline

Add `tools/lootdata.py` and a committed compact loot reference under `tools/reference/`.
The generator emits `LootData.lua` deterministically and supports `--check`. Integrate loot
audits into the existing game-data update and report workflow without making offline tests
download data. Every imported source has a pinned revision/build, URL, retrieval date, and
field-level provenance in an audit manifest. Build and source versions appear in debug output.

Use the client's Forever tables for item identity, equip slot, required level, class/race masks,
base stats, damage/speed, icons, effects, restrictions, and crafted outputs where available.
Use independently sourced acquisition records for quest rewards and prerequisites, creature
and object drops, vendors, reputation/PvP rewards, and source coordinates. Existing quest
database readers and profession reference builders are reusable ingestion paths. Inspect
upstream redistribution terms and preserve required notices for any packaged derived facts.

The catalog covers all supported equippable Forever items from levels 1-60 in the selected
source snapshot, not just one class or a few handpicked starting items. Keep one shared item
record and multiple source records; index by slot/level/source so the UI avoids rescanning
the full catalog. Any split generated files remain in the same packaged addon.

An item record contains ID, name, icon, quality, item/required level, inventory and subclass
IDs, restrictions, stats, damage/speed, unique group, effect IDs, suffix metadata, and source IDs.
A source contains stable ID, type, quest/NPC/object/recipe/instance IDs as applicable, faction,
zone/map/coordinates, prerequisites, cost/materials/reputation requirements, and evidence state.
Optional facts are absent rather than guessed; unknown and not applicable remain distinct.

Produce a coverage report by class, faction, ten-level band, equipment slot, and source type.
Report total items, missing stats, unknown eligibility, unmodeled effects, and missing source
locations separately. Validate representative early, middle, and late leveling choices for
each class and both factions, including Forever-only items. A slot with no available item
in a band is recorded as such after checking the source, not filled with fabricated entries.

Source categories include quest rewards, dungeon and raid bosses/trash, ordinary/rare creatures,
objects/chests, world drops, vendors, professions, reputation, and PvP. Auction houses are an
acquisition option for eligible tradable items, not an invented fixed-price source. Equipment
comparison can be complete while acquisition coverage is unknown; the UI states that honestly.

Keep excluded/removed/unverified records in the audit report. Items known to be unavailable
in the target Forever build are not normal recommendations. Classic data is candidate evidence,
not automatic proof that an unchanged item or acquisition source exists in Forever.

## Modules and integration boundaries

| File | Responsibility |
|---|---|
| `LootData.lua` | Generated item/source records and indexes on the addon namespace. |
| `LootProfiles.lua` | Authored profile definitions, talent-path mappings, and scoring rationales. |
| `Loot.lua` | Guarded item reads, equipment snapshots, eligibility, comparison, ranking, profiles, and target state. |
| `LootTab.lua` | Loot tab, details, manual compare/planning, profile editing, and tracked-target views. |
| `LootHints.lua` | Tooltip and quest/loot/merchant/crafting annotations, optional tracker, and notifications. |
| `tools/lootdata.py` | Reproducible import/build/check/audit and coverage reporting. |

`ns.loot` owns the public functions and state, with calls such as `compare`, `candidates`,
`sources`, `profile`, `track`, and `debugLines`. UI code draws through `ns.ui`; it does not
perform scoring. Other modules call `ns.loot` at runtime, not while their files load.
Reuse the existing item-info wrapper where it is suitable, and the existing map APIs behind
a loot-specific target context. Quest route state remains owned by `ns.quests`.

Load generated data and profiles before Loot; load Loot after Talents, Quests, and Professions;
load UI/hints after Window, Gamepad, and relevant quest map helpers. Both TOCs remain identical
and retain `@project-version@`. Do not change guide `Data.lua` to add equipment records.

Extend Settings with loot tooltip hints, reward advice, tracker visibility, and notifications.
Extend `/codex debug` with active profile, item-cache state, last comparison explanation,
catalog provenance/coverage, and unsupported APIs. A `/codex loot` entry opens the tab.

## Runtime constraints and failure behavior

- Lua 5.1, namespace-local state, ASCII runtime text through `ns.plain`, safe texture fallbacks.
- Guard optional APIs and event registration. Support classic globals and `C_Item`/`C_Container`
  variants when actually available. Minimal clients still browse packaged data; unsupported
  live comparisons explain the missing capability.
- Read equipped items and bags on relevant guarded events; coalesce bursts and invalidate
  only affected comparisons. Keys include full link, profile/context version, and equipment
  snapshot version. Profile, level, talent, and equipment changes invalidate stale verdicts.
- Item queries are deduplicated, bounded, and retried after client item-data events. Reopening
  or closing a view cancels stale refresh work. No entire-catalog tooltip scans at login or
  repeated full equipment/catalog processing on every tooltip frame update.
- Defer unsafe setup during combat. Hints never intercept navigation, select recipes/rewards,
  equip items, spend currency, roll, or manipulate protected controls. Existing quest and
  crafting hands-off guarantees remain intact.
- Controller users can reach slot selection, filters, item details, manual link entry, tracking,
  maps, and profile controls through native or Codex fallback navigation.
- Empty/corrupt/missing saved state falls back to the live character and automatic profile.
  Tracking and custom profiles persist when possible; loss never prevents browsing/comparison.
- Missing coordinates remove the map action and leave the source text. Missing acquisition
  evidence cannot be presented as a verified source. Missing prices do not become free items.

## Acceptance and delivery

Write player-reachable scenarios before implementing behavior. Extend the strict mock only
for the supported item, equipment, tooltip, reward, map, and source APIs exercised by those
scenarios. Keep meaningful engine fixtures for the combinations that drive different verdicts.

Required checks cover:

- Every class/path mapping and source/slot/filter category; future gear and planning context.
- A noncatalog item compared from a full link; same item ID with different suffixes; unknown
  data and delayed cache success/failure; no false zero-stat or stale tooltip verdicts.
- Upgrade/sidegrade/downgrade thresholds, empty slots, negative tradeoffs, and custom weights.
- Both ring/trinket slots, unique constraints, two-hand versus paired hands, missing off-hand,
  shields/dual wield restrictions, weapon DPS policies, and feral comparisons.
- Unknown/prohibited eligibility, unmodeled effects/set changes, and incomplete source facts.
- Quest upgrade guidance and vendor-price hints together, including incomplete reward reads;
  no automatic reward selection, equipment changes, purchases, crafts, or loot rolls.
- Target ownership and suffix identity, obtained/dismissed undo, route/map isolation,
  classic/modern/minimal APIs, combat, native/fallback controller, and lost SavedVariables.
- Catalog schema, provenance, deterministic generation, reference consistency, full coverage
  report, ASCII, global leaks, identical TOCs, and representative Forever-specific records.

Run the complete `python tests/run.py` harness before each commit. Generator checks and the
loot audit must pass offline against committed references. Record any pre-existing failures
separately; do not silently weaken existing checks to make this feature pass.

Before calling the feature finished, publish the coverage report and remaining evidence gaps
in its audit, update README/description/AGENTS module notes and CHANGELOG, run the harness and
generator checks, then install with `python tools/install.py`. Do not package a handoff zip or
push a publishing tag. Since TOCs change, tell the owner to restart the client for first testing.

The in-game checklist is: open Loot with keyboard and controller; check the active path/profile;
compare known armor, ring, and weapon swaps; inspect a random-stat bag link; view quest rewards;
follow a quest/vendor/dungeon source on the map; track and obtain a target; inspect tooltip and
enchant hints; change gear/profile and confirm refresh; repeat with a cold item cache and after
a reload. Record screenshots and `/codex debug` output for client-specific failures.

## Review handoff

After owner review of this written specification, write an implementation plan that sequences
the verified data pipeline, comparison engine, tab/tracking, and contextual hints into reviewable
changes, each with its own acceptance checks. The complete approved scope remains the delivery
target; an initial sample catalog is a development fixture, not completion of the feature.
