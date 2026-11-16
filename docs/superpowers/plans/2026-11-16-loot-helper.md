# Loot Helper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Loot tab that finds accessible gear, explains where to obtain it, and compares actual items against legal equipped configurations for the selected talent path.

**Architecture:** Generate a shared Forever equipment/source catalog, then build one comparison engine used by the tab, tooltips, reward advice, and notifications. Separate item reads, comparison, profiles, targets, maps, and display so missing APIs or acquisition facts do not corrupt verdicts. Complete all tasks before treating the feature as delivered.

**Tech Stack:** WoW: Forever interface 16001, Lua 5.1, Python standard library and lupa.lua51, existing headless mock/scenario harness.

**Spec:** `docs/superpowers/specs/2026-11-16-loot-helper-design.md` (owner approved).

## Global Constraints

- Lua 5.1, namespace-local state, ASCII runtime text through `ns.plain`, safe texture fallbacks.
- No feature requires another addon or surviving SavedVariables.
- The inspected reference addon's name does not appear in new product code, documentation, or UI.
- Both TOCs remain identical and retain `@project-version@`.
- Do not change guide `Data.lua` to add equipment records.
- Run the complete `python tests/run.py` harness before each commit.
- Do not package a handoff zip or push a publishing tag.
- Recommendations are advisory gear scores, never promised damage/healing/survival percentages.
- Missing stats, restrictions, effects, coordinates, and prices remain explicitly unknown.
- Every non-core API and non-core event registration is guarded; existing quest/crafting hands-off guarantees remain intact.
- Follow the existing pooled UI, double borders, Morpheus headings, teal palette, and native/fallback controller navigation.

## Review Focus

- A delayed item response after changing the compared item must not repaint the previous verdict (Task 3).
- A malformed profile code or enormous pasted link must not evaluate code, lock up the UI, or overwrite a valid profile (Tasks 5 and 8).
- Catalog items with two acquisition sources must remain one candidate; filtering one source must not erase the other (Tasks 2 and 7).
- Mapping loot while a quest arrow is active must not change quest acknowledgement, selection, or route progress (Task 9).
- A temporarily unavailable bag/equipment read must not mark owned targets missing or produce false upgrade notifications (Tasks 3 and 6).

## File map and dependency order

The spec's large `Loot.lua` responsibility is divided below; this changes module boundaries, not approved behavior.

| File | Responsibility |
|---|---|
| `tools/lootdata.py` | Fetch/import, normalize, generate, audit, coverage; offline build/check paths. |
| `tools/reference/loot.json` | Compact normalized, versioned items, sources, enchants, and provenance. |
| `tools/reference/loot-manifest.json` | Pinned sources, hashes, build, field provenance, exclusions and notices. |
| `tools/reference/loot-overrides.json` | Small verified corrections with evidence, never copied reference-addon tables. |
| `LootData.lua` | Deterministically generated shared records and indexes. |
| `Loot.lua` | Initializes `ns.loot`, owns context/version changes, public debug/report helpers. |
| `LootProfiles.lua` | Authored defaults/path mappings; validated custom profiles and share codes. |
| `LootItems.lua` | Guarded client item reads, bounded requests, live equipment/bag snapshots. |
| `LootCompare.lua` | Eligibility, legal hand/paired-slot replacements, score/verdict and warnings. |
| `LootCatalog.lua` | Filter/rank/paginate candidates and expose all acquisition/enchants. |
| `LootTargets.lua` | Target identity, ownership transitions, persistence validation, notification events. |
| `LootTab.lua` | Four sections, item details, input, planning, profile editor. |
| `LootMap.lua` | Explicit loot map context and map actions without route mutation. |
| `LootHints.lua` | Item/unit tooltip and quest/loot/merchant/crafting annotations. |
| `LootTracker.lua` | Optional compact tracker and deduplicated opt-in notifications. |
| `tests/test_lootdata.py`, `tests/test_lootcompare.py`, `tests/test_lootprofiles.py` | Offline generator and pure-engine fixtures. |
| `tests/fixtures/loot/` | Small synthetic source fixtures and independently verified example manifest. |
| `tests/wowmock.lua`, `tests/scenarios.lua`, `tests/run.py` | Player-visible behavior and strict API/side-effect coverage. |

Existing integration files: both TOCs, `Window.lua`, `Init.lua`, `QuestGuide.lua`, `QuestTab.lua`,
`tools/gamedata.py`, `.github/workflows/gamedata.yml`, `tools/UPDATING.md`, `README.md`,
`CURSEFORGE_DESCRIPTION.md`, `AGENTS.md`, `CHANGELOG.md`, and `.pkgmeta` if notices need packaging.
Keep `Gamepad.lua`, profession guide code, and guide data unchanged unless an actual integration
test demonstrates a necessary adjustment.

Load `LootData.lua` with generated data; after Professions load Loot, Profiles, Items, Compare,
Catalog, Targets in that order. After QuestMap/Gamepad load LootTab, LootMap, LootHints,
LootTracker. Cross-module calls resolve through the namespace at call time.

## Shared contracts

- `L = ns.loot`; no new global data tables. Every module starts `local _, ns = ...`.
- `Item`: `id`, exact `link`/`key`, `name`, `icon`, `quality`, `level`, `requiredLevel`, `slot`,
  `classID`, `subclassID`, `stats`, `damage`, `speed`, `restrictions`, `effects`, `suffix`,
  `sourceIDs`, `complete = { stats, restrictions, effects }`, and `state` (`ready/loading/unavailable`).
  A field is complete only when supplied by a reliable reader/reference, not merely absent.
- `Source`: stable `id`, `type`, item ID, entity/quest/recipe/instance IDs, map/zone/positions,
  faction/prerequisites/cost/materials/requirements, and per-field evidence references.
- `Snapshot`: `version`, `slots[physicalInventorySlot] = Item|false`, bag exact-link counts,
  `equipmentKnown`, `bagsKnown`, and optional bank snapshot timestamp. `false` means confirmed
  empty, absent means unknown. Never replace a known snapshot with an incomplete read.
- `Context`: `class`, `race`, `faction`, `level`, `profile`, `proficiencies`, `professions`,
  `reputation`, `snapshot`, `version`, `preview`. Each requirement-reading domain distinguishes
  known empty from unknown. Preview may use live gear only when class/faction/level match;
  otherwise require explicit baseline links.
- `Profile`: `key`, `class`, `label`, `role`, `weights`, `weapon` policy, `version`, `custom`.
- `Result`: `verdict`, `reason`, `candidate`, `baseline[]`, `replacedSlots[]`, `score`,
  `baselineScore`, `delta`, nullable `percent`, `statDelta`, `eligibility`, `confidence`,
  `warnings[]`. Pending comparisons may omit scores; never synthesize zero from missing data.
- Callbacks/events only request a view refresh with a generation token. Rendering reads the
  current context and comparison; callbacks cannot restore an obsolete selection.

## Task 1: Establish the catalog schema and deterministic offline generator

**Files:** Create `tools/lootdata.py`, `tests/test_lootdata.py`, and `tests/fixtures/loot/`.
Modify `tests/run.py` once to include the offline loot unit suite in its parent process.

**Interfaces:** `normalize_items(tables, build) -> dict[int, Item]`,
`normalize_sources(raw, items, manifest) -> dict[str, Source]`, `validate(reference) -> list[Issue]`,
`render(reference) -> str`, `coverage(reference) -> dict`. CLI: `fetch --build B`,
`build [--build B]`, `audit`, `coverage [--output PATH]`, and `--check` (offline generated-byte check).
Build requires pinned cached inputs and fails with a missing-input explanation; only fetch uses network.

- [ ] Write `test_schema_unknown_is_not_zero`, `test_multiple_sources_survive`, and
  `test_render_is_deterministic_ascii`. Assert absent price stays absent, missing stats leave
  `complete.stats == false`, sources `quest:1` and `vendor:2` both survive for one item, and
  `render(shuffled_fixture) == render(fixture)` with ASCII-only output.
- [ ] Run `python -m unittest discover -s tests -p "test_lootdata.py" -v`; expect missing-module/API failure.
- [ ] Implement schema validation, canonical ID ordering, atomic output, version/provenance
  validation, and CLI separation. Reject invalid coordinates, negative counts, duplicate stable
  IDs, missing source references, and contradictory complete/unknown fields. Normalize source
  types to quest, boss, dungeonTrash, raidTrash, creature, rare, object, world, vendor, craft,
  reputation, pvp; auction eligibility is an item acquisition option, not a fixed-price source.
- [ ] Run the unit tests; register their parent-process execution in the harness with failures
  included in its result. Run `python tests/run.py`; expect zero failed runs before committing.
- [ ] Commit only the generator/schema/fixture/harness changes: `feat: define loot catalog generation`.

## Task 2: Populate and audit the full Forever catalog and acquisition evidence

**Files:** Modify `tools/lootdata.py`, `tools/gamedata.py`; create `LootData.lua`, the three loot
reference/manifest/override JSON files, required third-party notices, and
`tools/audits/2026-11-16-loot-coverage.md`; extend `tests/test_lootdata.py`.

**Consumes:** Task 1 schema/generator. **Produces:** `ns.lootData = { schema, build, items, sources,
enchants, bySlot, bySource, byCreature, coverage }`; normalized source records with evidence.

- [ ] Add `test_forever_identity_wins`, `test_classic_source_is_unverified_without_evidence`,
  `test_removed_item_excluded`, and `test_coverage_counts_unique_items`. Assert a confirmed
  Forever value overrides conflicting candidate data, an unverified drop cannot become a
  verified farm, unavailable records are excluded with reasons, and two sources count one item.
- [ ] Run the focused unit suite; confirm these behavioral assertions fail before ingestion changes.
- [ ] Inspect actual table headers for the selected Forever build. Extend cached table ingestion
  for item restrictions, base stats, damage/speed, unique groups, suffixes, sets and effect IDs;
  fail explicitly on unknown schema instead of mapping columns by guesswork. Reuse `Tables`,
  `Spells`, `build_professions`, and the pinned `questfacts.entity/record/endpoints` readers.
- [ ] Import all equippable items with required level 0-60 in the selected snapshot (level 0
  means no level requirement, not an exclusion), and independently sourced reward/drop/vendor/
  craft/reputation/PvP acquisition evidence. Inspect redistribution terms before deriving packaged
  records; record notices, source URLs/revisions, hashes and retrieval dates. Unresolved vendor
  costs, drop rates, world-drop locations and availability remain unknown.
- [ ] Record per-field precedence and conflicts in the manifest; keep verified corrections in
  overrides with evidence. Include enchants and their applicability, recipe/source requirements,
  deterministic stats, and unsupported effect IDs. Do not copy installed generated tables.
- [ ] Generate the catalog and six ten-level-band coverage matrices for nine classes, both
  factions, functional slots and all source categories. Audit at least one early/middle/late
  example per class/faction (54 checks), plus Forever-only items and every source type. Explain
  empty cells and unresolved evidence; a seed fixture is not the production catalog.
- [ ] Run `python tools/lootdata.py audit`, `python tools/lootdata.py --check`, the unit suite,
  and `python tests/run.py`; expect zero audit errors, byte-identical generation and zero failed runs.
- [ ] Commit: `feat: add verified Forever loot catalog`.

## Task 3: Read exact items and stable live snapshots safely

**Files:** Create `Loot.lua`, `LootItems.lua`; modify both TOCs, `tests/wowmock.lua`,
`tests/scenarios.lua`, `tests/run.py`.

**Consumes:** `ns.lootData`, `ns.itemInfo`, `ns.after`, `ns.charDB`.
**Produces:** `L.item(ref) -> Item`, `L.snapshot() -> Snapshot`, `L.context(overrides?) -> Context`,
`L.refresh(reason, physicalSlot?)`, `L.subscribe(callback) -> unsubscribe`, `L.debugLines() -> string[]`.

- [ ] Add `lootReads`, `lootCacheLate`, `lootCacheFailure`, `lootStaleResponse`, and
  `lootPartialSnapshot` scenarios. Extend the mock with exact-link keyed item records, equipped
  slots, optional modern/classic item stats/read APIs and request counters. Assert delayed old
  item responses cannot replace the current comparison, and an unavailable bag read retains
  the last confirmed snapshot rather than reporting empty bags.
- [ ] Run `python tests/run.py -k loot`; expect failed assertions/missing behavior.
- [ ] Implement full-link identity (including suffix/modifications), API alias normalization,
  guarded old/new readers, and completeness flags. Generated base facts supplement exact live
  facts without substituting base stats for unknown link modifications. Until a profile is
  available, context construction keeps `profile` absent and reports that comparison is unavailable.
  Retain confirmed empty
  slots separately from unknown slots; enumerate bags without using protected operations.
- [ ] Coalesce invalidations at 0.1 s. Deduplicate item requests, retry at 0.5/1/2 s or guarded
  item-data events, stop after four attempts, and report unavailable after exhaustion. Preserve
  exact links and context/snapshot versions in cache keys; do not scan the catalog at login.
- [ ] Run focused scenarios in full, modern-only, classic-only, minimal, combat, and lost-save
  modes; run the full harness; commit `feat: read loot items and equipment safely`.

## Task 4: Implement eligibility and legal equipment comparisons

**Files:** Create `LootCompare.lua`, `tests/test_lootcompare.py`; modify both TOCs and unit-suite registration.

**Consumes:** Item/Context/Snapshot. **Produces:** `L.compare(ref, context?, baseline?) -> Result`,
`L.eligible(item, context, proposedSlots) -> { state, reasons[] }`,
`L.score(item, profile) -> { value?, warnings[], complete }`.

- [ ] Add pure Lua fixtures through lupa for complete synthetic items with `weights.str = 1`.
  Define test helper `verdict(candidateScore, baselineScore)` to construct otherwise identical,
  eligible items with that many Strength points and return `L.compare(...).verdict`. Assert:
  `assert verdict(102,100) == "upgrade"`, `verdict(101,100) == "sidegrade"`,
  `verdict(99,100) == "sidegrade"`, `verdict(98,100) == "downgrade"`; a positive item versus
  confirmed empty has `percent == nil`; two zero scores return `needsReview`.
- [ ] Add tests for replacing either ring/trinket, legal unique-group replacement, rejecting
  duplicate unique groups across other slots, two-hand versus both hands, main/off-hand-only
  items, dual wield restrictions, missing partner, wrong class/race/level/proficiency/profession/
  reputation, unknown requirements, unresolved suffixes, changed set bonuses and unmodeled effects.
  Assert results name the exact replaced slots and never score unknown baseline slots as zero.
- [ ] Run `python -m unittest discover -s tests -p "test_lootcompare.py" -v`; expect failure.
- [ ] Implement legal configuration enumeration, weighted stat/weapon policies, and the exact
  1% deadband. Separate static eligibility failure from unknown requirements. Unmodeled relevant
  effects produce provisional scores plus `needsReview`; no quality/item-level shortcut verdicts.
  Preserve hand role, feral weapon policy, shield mitigation, and actual suffix stats.
- [ ] Verify the engine in the pure unit suite now. Task 8 adds player-reachable
  `lootCompareVerdicts` and `lootCompareHands` scenarios through the real Compare view;
  do not register scenarios that depend on a view before that view exists.
- [ ] Run pure tests and existing focused item tests, then full harness; commit `feat: compare legal gear configurations`.

## Task 5: Author path profiles and validate custom profile codes

**Files:** Create `LootProfiles.lua`, `tests/test_lootprofiles.py`; modify both TOCs and extend audit/tests.

**Consumes:** `ns.talentPaths`, `ns.talentPath`, `ns.talentVersion`, game reference facts, Task 4 scoring.
**Produces:** `L.profile(context?) -> Profile`, `L.setProfile(keyOrProfile?) -> ok,reason`,
`L.profileCode() -> string`, `L.readProfileCode(text) -> ok,reason`, `L.resetProfile()`.

- [ ] Add `test_every_path_maps`, `test_feral_ignores_ordinary_weapon_dps`,
  `test_invalid_code_preserves_profile`, and `test_code_roundtrip`. Reject NaN/infinity,
  negative weights, values above 10000, unknown stat keys/classes/schema, codes over 4096 bytes,
  and invalid weapon policies; assert rejection leaves the previous profile unchanged.
- [ ] Run focused profile tests; expect failure, then author role/path weights and documented
  rationales from `python tools/gamedata.py packet CLASS` and `facts CLASS` for all nine classes.
  Values are explicitly advisory; verified game mechanics govern conversions/proficiencies.
- [ ] Implement automatic mappings for every guide/spec path; Custom uses its strongest tree,
  ties use the guide with an explanation. Manual loot profile choice never changes talents.
  Export `LCL1-<CLASS>-<payload>-<checksum>` with a bounded deterministic field parser; never
  evaluate imported text. Reset returns to automatic mode, including with lost SavedVariables.
- [ ] Add path-change/manual-override/lost-save assertions in pure fixtures and run focused tests plus the full
  harness; commit `feat: add talent-aware loot profiles`.

## Task 6: Track exact targets and detect ownership without false transitions

**Files:** Create `LootTargets.lua`; modify both TOCs; extend `tests/test_lootcompare.py` and snapshot mocks.

**Consumes:** snapshot/item events and exact variants from Task 3.
**Produces:** `L.track(ref, sourceID?) -> targetKey`, `L.targets(state?) -> Target[]`,
`L.setTargetState(key, state) -> ok,reason`, `L.untrack(key)`,
`L.targetChanges() -> Change[]` (drained once by notification display).

- [ ] Add pure tests `test_target_variants`, `test_target_undo`, `test_target_partial_bags`,
  and `test_target_lost_save` against mocked client item/bag events and the public target methods.
  Assert two suffixes remain distinct; obtained/dismissed can be undone; completing the quest
  without owning its reward does not obtain it; unknown bags do not remove confirmed ownership.
- [ ] Run focused unit tests to observe failure. Implement stable item+variant+optional-source
  keys, validated per-character records, monotonic known ownership reads, and change events.
  Bound saved targets to 200; refuse excess with a visible reason instead of silently deleting.
  Bank evidence carries its timestamp and is never presented as a fresh closed-bank scan.
- [ ] Verify repeated BAG_UPDATE bursts create one transition and no duplicate notifications;
  run full harness and commit `feat: track loot acquisition targets`.

## Task 7: Rank catalog candidates, sources, and enchant recommendations

**Files:** Create `LootCatalog.lua`; modify both TOCs; extend generator and engine unit tests.

**Consumes:** Task 2 indexes, `L.compare`, `L.profile`, current route/zone and profession facts.
**Produces:** `L.candidates(filters, context, offset?, limit?) -> { rows, total }`,
`L.sources(itemID, filters?) -> Source[]`, `L.enchants(ref, context?) -> Advice[]`.
Rows contain one item with all matching sources, Result, and separate acquisition rank.

- [ ] Add tests asserting two sources yield one item row, a vendor filter retains the vendor
  when the quest source is hidden, identical-score ties sort by name then ID, and pagination
  covers every matching item once. Exercise every source type and slot, future-level filters,
  missing coordinates/costs, unreadable live stats, and noncatalog comparison independence.
- [ ] Run focused tests to see failure. Implement slot/level/source indexes, class/faction/
  requirement filters, case-insensitive name or numeric-ID search, source/zone/dungeon/profession
  and acquisition-style filters. Default All sources, eligible items only, usable-upgrade-first
  score ordering. Acquisition sort affects ordering only, never Result.verdict.
- [ ] Link quest IDs to existing route steps without selecting/acknowledging them; annotate
  unmet known prerequisites and group requirements. World drops have no invented farm or rate.
  Enchant advice uses applicability and known deterministic contributions; unmodeled effects
  stay review-required and unknown costs stay unknown. Link existing profession steps by recipe ID.
- [ ] Run focused tests, offline audit/check, and full harness; commit `feat: rank loot and acquisition options`.

## Task 8: Build the Loot tab, item inputs, and profile/planning controls

**Files:** Create `LootTab.lua`; modify `Window.lua`, `Init.lua`, both TOCs and gameplay tests.

**Consumes:** public Loot contracts. **Produces:** `L.open(section?, ref?, sourceID?)`,
`ns.addTab("loot", "Loot", renderer)`, `/codex loot`, and a pooled
`ns.ui.entry(key,x,y,width,value,onChange,onSubmit,maxBytes)` for named input controls.
Preserve the existing quest search control identity and callbacks.

- [ ] Add `lootTab`, `lootCompareVerdicts`, `lootCompareHands`, `lootPlanning`, `lootProfilesUI`,
  `lootTargetVariants`, `lootTargetUndo`, `lootTargetPartialBags`, `lootTargetLost`, and
  `lootInputBounds`. Drive clicks, named input frames and slash commands, asserting
  displayed verdict/replaced gear, 2048-byte item-link limit, 4096-byte profile-code limit,
  invalid input leaves prior valid state, and preview classes cannot inherit live gear silently.
- [ ] Run `python tests/run.py -k loot`; expect failures. Add Upgrades/Compare/Tracked/Profiles
  sections, equipped slot selector, filters/search/pagination, all-source details and Track actions.
  Draw via `ns.ui`, route all display text through plain, and reset pooled callbacks/labels so
  old item actions cannot survive redraw. Return correct content height and retain scroll state.
- [ ] Implement link/ID entry with exact-link preservation and equipment/bag choices. Show
  current profile and rationale, side-by-side stats, score labels, uncertainty and empty-slot
  explanations. Add preview class/faction/level/profile and explicit baseline input controls;
  validate levels 1-60 and supported class/profile combinations.
- [ ] Add profile edit/reset/import/export, target state/undo controls, settings, and debug lines.
  Every clickable has a stable `codexLabel`; item details have actual item tooltips with fallback.
  Ensure the extra top-level tab fits at supported window scales (`tabRowFits` regression).
- [ ] Exercise every class, minimal/full APIs, both themes, lost saves, tab scroll, hide/reopen,
  and native/fallback controller focus through all four sections. Run full harness and commit
  `feat: add the Loot tab and gear comparison views`.

## Task 9: Map loot sources without advancing or fighting the quest route

**Files:** Create `LootMap.lua`; modify `QuestGuide.lua` only at user-waypoint ownership/update
hooks; extend map mock/scenarios and TOCs.

**Consumes:** verified Source positions. **Produces:** `L.showSourceOnMap(sourceID) -> ok,reason`,
`L.clearMapTarget()`, `L.mapTarget() -> { sourceID, map, x, y, label, kind }|nil`.

- [ ] Add `lootMapRouteIsolation`, `lootMapDungeonEntrance`, and `lootMapNoCoordinates`.
  Assert source mapping leaves selected quest ID, acknowledged steps and active route unchanged;
  the quest ticker does not repeatedly overwrite an explicitly selected loot waypoint; missing
  coordinates show a reason and no pin; an entrance is labeled entrance, not boss location.
- [ ] Run focused map tests to observe failures. Reuse guarded native map calls and the
  existing coordinate conventions; explicit loot map selection owns the single user waypoint
  until Clear loot target, an explicit quest-map action, or reload. Add runtime ownership guards
  to quest waypoint maintenance, without changing quest arrow/progression state.
- [ ] Keep verified source pins separate from quest pins. Opening a source with multiple
  verified positions lets the player choose one; unsupported maps keep textual directions.
  Exercise classic/minimal maps and clearing/returning to a quest target; run full harness and
  commit `feat: map loot sources independently of quest progress`.

## Task 10: Add item, creature, and reward hints through the shared engine

**Files:** Create `LootHints.lua`; modify `QuestGuide.lua` reward integration and Settings;
extend strict tooltip/reward/side-effect mocks, scenarios and TOCs.

**Consumes:** `L.compare`, `L.candidates`, `L.enchants`, `L.open`.
**Produces:** `L.refreshHints(reason)`, `L.rewardAdvice() -> { state, rows, bestChoice? }`.

- [ ] Add `lootTooltips`, `lootUnitDrops`, `lootRewardsAndPrice`, `lootRewardsPending`,
  `lootHintsReadOnly`, and `lootTooltipReuse`. Assert a noncatalog readable item gets the same
  verdict as Compare; reused tooltips have one current annotation; ambiguous creature names
  do not claim exact drops; missing reward data prevents a premature best-choice marker.
- [ ] Run focused scenarios to see failure. Hook available item tooltip paths safely for bags,
  loot/group loot, merchant, quest choices, crafted outputs and equipped gear; expose a
  separately labeled Codex slot lookup without replacing normal character-slot actions.
  Add verified creature drops by NPC ID/GUID, falling back only for unambiguous identities.
- [ ] Show comparison reasons and enchant advice separately. Add best-gear reward marker only
  when every equippable choice is conclusive; retain vendor-value marker and independent setting.
  Cancel delayed reward callbacks on window/run changes. Missing optional hooks leave the tab usable.
- [ ] Assert zero automatic EquipItem/BuyMerchantItem/GetQuestReward/RollOnLoot calls and zero
  recipe-list selection, scrolling or clicks attributable to loot hints, including combat.
  Run existing reward and craftHandsOff regressions plus full harness; commit
  `feat: add consistent loot and quest reward hints`.

## Task 11: Add the compact tracker and meaningful optional notifications

**Files:** Create `LootTracker.lua`; extend Settings/skin support only as needed, TOCs and tests.

**Consumes:** `L.targets`, `L.targetChanges`, `L.open`, `L.showSourceOnMap`, shared bag comparisons.
**Produces:** `L.refreshTracker()`, `L.hideTracker()` and optional deduplicated notices.

- [ ] Add `lootTracker`, `lootNotifications`, `lootTrackerCombat`, and `lootTrackerPad`.
  Assert visible targets open/map/untrack correctly, obtain events notify once, repeated bag
  events do not repeat notices, startup catalog scans never notify, and incomplete snapshots
  cannot announce a new bag upgrade. Default notifications off; tooltip/reward hints on;
  tracker visible only when tracked targets exist and the tracker setting is enabled.
- [ ] Run focused scenarios to see failure. Build the small pooled/scrollable Codex-art frame
  with optional saved position, open/map/untrack controls, and native/fallback controller attachment.
  Coalesce changes and notify only on obtained targets or conclusively new bag upgrades.
- [ ] Verify hide/show, theme rebuild, lost saves, native manager refusal/no-focus fallback,
  combat release/recovery, and no duplicate focusables. Run full harness and commit
  `feat: add loot target tracker and optional notices`.

## Task 12: Integrate updates, audit the complete feature, and install

**Files:** Modify game-data tooling/workflow, `tools/UPDATING.md`, README/description,
`AGENTS.md`, CHANGELOG; finalize coverage audit and notices; update plan completion boxes.

**Consumes:** all tasks. **Produces:** reproducible update report, tested complete build and verified game installation.

- [ ] Add `test_update_report_includes_loot` and `test_offline_checks_do_not_fetch`; assert
  loot errors/warnings and coverage appear in update/audit/daily reports, generated records
  track the selected build, and offline generation/tests succeed with network disabled.
- [ ] Run focused tests to observe missing integration. Extend `gamedata.py full_audit/update/
  diff/write_report` and daily workflow to regenerate/stage loot references, manifest and
  generated Lua when appropriate. Include source-only changes in the changed-file decision;
  retain the workflow's existing review-only publication behavior and no automatic release.
- [ ] Review spec coverage task by task, compare all result surfaces for the same fixture,
  and audit generation limits, cold-cache request counts, tab fit and event coalescing.
  Update the coverage report with actual counts and evidence gaps; do not claim unknown
  acquisition data is complete. Update docs with behavior, advisory limits and module/load order.
- [ ] Run `python -m unittest discover -s tests -p "test_loot*.py" -v`,
  `python tools/lootdata.py --check`, `python tools/lootdata.py audit`,
  `python tools/gamedata.py audit`, `git diff --check`, and `python tests/run.py`.
  Required: zero unit/scenario failures, zero new audit errors, no leaked globals or non-ASCII
  runtime text, identical TOCs, no unsafe action regressions. Report existing warnings separately.
- [ ] Review the complete diff and resolve findings; if implementation changes, rerun affected
  checks and the full pre-commit harness. Commit `feat: complete loot helper integration`.
- [ ] Run `python tools/install.py`; require every copied file verified. Tell the owner to
  restart the client because TOCs changed, and report the actual installed version.
- [ ] Deliver summary, actual coverage and limitations, test results, and this in-game checklist:
  keyboard/controller Loot navigation; automatic/manual profile switch; armor/ring/weapon swaps;
  random-stat link comparison; gear and vendor reward hints; quest/vendor/dungeon source maps;
  target obtained/undo; enchant tooltips; equipment refresh; cold cache; combat; reload/lost saves.

## Plan review and execution

Baseline at specification commit `ebcce94`: `python tests/run.py` passed with zero failed runs,
409 data warnings, 312.0 seconds. Only documentation has changed since that run.

Self-review: every specification section maps to Tasks 1-12; shared names/types above are used
consistently; the five Review Focus cases have owning tests. No production implementation has
started. Review this plan before selecting execution. Native execution is recommended because
the data, item completeness, legality, and UI contracts are closely coupled; it preserves one
implementation context while completing the entire scope.
