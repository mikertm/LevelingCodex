# Loot implementation and final review - 2026-11-16

The owner approved the specification and implementation plan and authorized native execution.
The feature is implemented in the isolated desktop worktree. This report preserves the review
decisions when temporary execution logs are removed.

## Scope and data

- Catalog: 12,378 equipment identities, 34,200 acquisition references, 171 enchant options.
- Class/path profiles, exact-link reads, legal equipment comparisons, four-section Loot tab,
  source maps, target tracking, tooltip/reward advice, optional tracker and notifications.
- Source coverage and unknowns: `2026-11-16-loot-coverage.md` and the committed manifest.
- The reference interface, code, art and scoring profiles were not copied. Guide Data.lua did
  not require equipment edits or changes to mirror back to the class guides.

## Independent review

A fresh reviewer inspected `ebcce94..2fd45ce`. Its first turn was interrupted by a usage limit;
the same reviewer resumed and completed the single review after the owner asked to continue.
It reported seven Important findings, one Minor finding, and no Critical findings. The runtime
candidate passed 477 scenarios and 30 offline units before review; those tests did not cover
the newly reproduced cases below.

| Finding | Correction | Regression evidence |
|---|---|---|
| Exact inventory-type filters omitted robes, two-handers, shields, held items and some ranged weapons | Equipment choices union the appropriate inventory indexes and deduplicate identities | `test_visible_equipment_categories_include_every_inventory_type` |
| Failed live equipment reads reused retained gear conclusively | A snapshot marked unreadable yields Needs review; retained items remain usable for display | `test_unread_equipment_snapshot_never_uses_stale_gear_conclusively` |
| An unknown second ring could turn a possible upgrade into a false downgrade | Uncertain legal replacement alternatives keep the overall verdict provisional | `test_unknown_paired_slot_prevents_a_false_downgrade` |
| Shared cached object identity bypassed unique-equipped rules | Uniqueness excludes the insertion slot, not every reference to the candidate object | `test_same_cached_unique_item_cannot_fill_a_second_slot` |
| Numeric-looking invalid profile fields disappeared before validation | Validate every numeric conversion and bound before constructing/saving the profile | `test_invalid_numeric_tokens_cannot_replace_a_valid_profile` |
| Legacy bag reader captured lootable instead of hyperlink | Read the classic tuple's actual link return; occupied unreadable slots make the bag snapshot unknown | `test_classic_container_tuple_preserves_links_and_counts`, `test_occupied_container_without_link_is_not_a_known_empty_bag` |
| Exact-link modifications inherited base effect completeness | Unverified enchant/gem/suffix/bonus effects remain provisional even when numeric stats are readable | `test_modified_link_effects_do_not_inherit_base_completeness` |
| Vendor merchandise was called a creature drop | Vendor and drop sources have distinct tooltip wording | `test_vendor_merchandise_is_not_labeled_as_a_drop` |

Every listed reproduction failed before its correction and passed afterward. Two related
checks were added in the same fix pass: unknown weighted weapon damage/speed cannot produce
a conclusive score, and an explicit target Restore remains tracked through the current
ownership refresh, rearming automatic completion after a confirmed disappearance/reacquisition.
The final source audit also found 1,090 low-equip-level items whose only quest sources require
more than level 10. Recommendations now gate known source-level requirements at the current
or explicitly planned level; item details retain the locked source and requirement. A failing
catalog regression verified both current-level exclusion and explicit future-level inclusion.
Explicit future browsing also retains level-locked equipment with a required-level label,
without changing its current-character Cannot equip verdict or claiming a simulated upgrade.

## Execution rulings

1. Use the matching checkout's pinned cached game/database inputs read-only. This avoids
   redundant downloads; stale acquisition facts remain labeled reference evidence.
2. Overlap independent tooltip downloads with engine work against synthetic fixtures. The
   shared schema is fixed; production coverage is not declared complete from test fixtures.
3. Combine the coupled engine/UI task commits at integration. Larger generated-data changes
   are reviewed together, and no runtime commit bypasses the full pre-commit harness.
4. Review the frozen candidate while the long full harness runs, then commit the identical
   tested content. The review package and actual commit range identify the same runtime files.
5. Treat misleading vendor-source wording as an Important correctness issue despite the
   reviewer's Minor label: acquisition method is central to this feature, and incorrect
   wording can send a player farming the wrong source. Its regression is part of the fix pass.
6. Consolidate overlapping plan test names into meaningful pure fixtures and player-visible
   full/minimal scenarios. The full harness runs the offline units once in its parent process.
7. Preserve uncertain effects and requirements rather than guessing game mechanics. Advisory
   weights are editable priorities, not independently measured combat gains.

## Review limits and delivery checks

The reviewer did not certify live frame appearance, native controller behavior, protected-client
APIs, live server drop availability, redistribution rights, or combat effectiveness of advisory
weights. Runtime appearance/controller/API checks remain on the owner's in-game checklist.
The selected sources and their licensing qualifications are recorded in THIRD_PARTY_NOTICES.md;
the tool packages normalized facts and preserves provenance. No live drop rate is asserted.

Post-review verification: **40 offline units and 477 full/minimal scenarios passed**, zero
failed runs, 378.0 seconds. The deterministic catalog check and offline audits passed with
zero errors. Existing guide-data warnings remain separate from the explicit catalog evidence
gaps. Both TOCs remain byte-identical with the repository version token intact.

Installed **82 files** directly into the owner's LevelingCodex game folder; every copy was
verified. The installer stamps the committed build version for the final delivery. The desktop
worktree is preserved for the owner; no merge, push, or publishing tag is part of this task.

In game, restart the client to load the TOC changes, open `/codex loot`, compare armor/rings/
weapons and random variants, inspect reward/value marks, follow quest/vendor/dungeon sources,
restore a tracked item, and check keyboard/native/fallback controller navigation. Unsupported
effects should say Needs review; a dungeon entrance pin should identify itself as an entrance.
