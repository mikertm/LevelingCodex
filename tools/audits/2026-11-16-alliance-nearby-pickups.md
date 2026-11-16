# Alliance nearby-pickup audit, 2026-11-16

Requested after a level 29 Skyborne found **Fall of Dun Modr (472)** offered by
Harlo Barnaby in Menethil while the step window showed **Accept The Thandol
Span (631)**. Scope expanded at the owner's request to the full Alliance route.
This is an audit, not a gameplay-code change or an installation.

## Findings requiring attention

### 1. Catch-up can hide an available quest that shares the next trip

472 is already routed. Its pickup is at Harlo (Wetlands 10.85, 55.90), before
leaving Menethil; its turn-in is Longbraid (49.80, 18.26), immediately before
Rhag's 631 pickup (49.92, 18.21). No additional objective fight is required.
The screenshot establishes that Harlo offers it to this character now.

`Quests.lua`'s `markPassed()` walks backward through a section. A completed
quest whose pickup appears later is evidence that earlier, independent,
unaccepted pickups were missed. On November 15 the raptor pickups 98245/98246
moved after 472. A character who already completed them can therefore have
472's pickup AND turn-in deferred, even while standing at Harlo. 631 has no
prerequisite 472, so the prerequisite-preservation exception does not help.
The character's saved skips contain no manual skip for 472.

Diagnostic reproduction in a fresh full-API Warrior mock: level 29, Skyborne,
map 1437 at 10.85/55.90; mark the route's quest IDs before 631 completed except
472, and additionally mark 98245/98246 completed. Fire the normal login events.
Observed states: `accept 472=deferred`, `turnin 472=deferred`,
`accept 631=pending`. This reproduces the hiding rule, not the exact displayed
current row: flight/setup state also affects the current row. The minimal mock
does not expose equivalent historical completion evidence, and did NOT reproduce
this case. Do not claim identical reproduction in both API variants.

This affects the shared Alliance section, not just Skyborne or Warriors.
It is a runtime catch-up issue; adding 472 again or inventing a game prerequisite
on 631 would not be a correct fix. A proximity-based recovery would need to
handle both `markPassed()` and explicit `resumeAt` deferrals, honor manual skips,
grey/level/prerequisite filters, and avoid distant backtracking.

**Immediate in-game recovery:** accept Harlo's offered quest. Existing log-based
handling then retains its turn-in, already placed beside the Thandol pickup.
The precise earlier event that first hid it cannot be reconstructed from the
screenshot or saved settings alone; the reordered raptor completion is a
reproduced mechanism consistent with it.

### 2. The reason for delaying Harlo's pickup is now stale

The November 12/14 audits left 472 on the later Menethil visit because taking
it on the first visit produced 21/20 quests. The November 15 raptor changes
freed two slots during the coast trips. In an in-memory copy of the CURRENT
route, moving `accept(472)` immediately after the first `accept(484)` passed
the complete route audit with **zero errors**, including optional/dungeon paths.

Recommendation: take 472 beside Halloran on the first Menethil visit. Preserve
the existing Dun Modr turn-in. This removes the separate Harlo visit (the loop
tool estimates 77 yards of extra straight-line travel). It improves new
playthroughs but DOES NOT fix historical catch-up suppression by itself.

### 3. More nearby omissions found in the higher-level chapters

See the two companion band reports for precise eligibility, positions, capacity
experiments, and rejected candidates. High-confidence additions to review:

| Quest | Existing trip | Why it belongs in the correction pass |
|---|---|---|
| 684 Wanted! Marez Cowl | `arathi-39`, wanted board and Stromgarde | Same board visit as 685 and overlapping elite work. An in-memory insertion passes the current 20-quest audit. |
| 682 Stromgarde Badges | `arathi-39`, Nials/Syndicate camp | Opens after already-routed 681; badge droppers overlap the camp. Must schedule its hand-in/cap together with 684, rather than adding both independently. |
| 975 Cache of Mau'ari | `winterspring-55` and `winterspring-alt`, after 969 | Speak to the same NPC again after a short preparation. The existing route leaves without this follow-up. Include it in the alternate's copied quest-ID list. |
| 5238 Mission Accomplished! | `plaguelands-58`, after 5226 | Current Forever records put it at Commander Ashlam, about 24 yards from MacDonnell's existing turn-in, with no combat objective. Some Classic-derived web pages disagree on faction/ID; current Forever traces identify 5238 as Alliance and 5237 as Horde. Verify the live offer before treating those stale pages as authority. |

These are findings, not claims that additions have been installed. In particular,
nearby elite quests still need the existing Take/Skip treatment where applicable.

Published cross-checks: [975 after 969](https://questing.wiki/wow-forever/quests/series/969/)
agrees with the cached follow-up; [5238's Alliance record](https://senseos.gg/wiki/wow-forever/quests/5238/mission-accomplished/)
agrees with the current trace but [this Classic-derived page](https://theforeverera.com/en/quests/5238/)
disagrees and explicitly disclaims Forever quest accuracy. The
[four-golem walkthrough](https://www.oraclenewsnetwork.com/guides/gleaning-our-future)
places 98313 after the elite 98310 extension. These are corroboration, not live
observations by this audit.

## Coverage and evidence

- Loaded all 172 Alliance sections: 43 main, 20 alternates, plus dungeon/class/
  special guides to distinguish absent quests from content already provided.
- Reran the loop analysis for all five Alliance race tokens and nine classes
  (45 combinations), main route and each alternate. There are 42 distinct
  warning strings; several are the same Coldridge warning at different
  class-dependent step numbers, NOT 42 confirmed defects.
- Compared omitted, client-present quest IDs with cached Forever quest records.
  `2026-11-16-alliance-nearby-candidates.json` records 185 candidates whose
  giver name AND spawn match a current main/alternate route contact within
  100 yards, whose quest level is within section low-6/high+2, and whose known
  minimum is no higher than the chapter's upper level. Included all-Alliance
  section IDs when deciding whether a quest was absent.
- The candidate inventory is a screening artifact, not 185 verified omissions.
  Missing class/profession/server-side gates, incomplete prerequisites, and
  objective geography require review. Prior-audit mentions in that file are
  search hits, not proof of an earlier decision. The scan cannot find every
  quest from an unvisited NPC or an undocumented live-server offer.
- Rechecked prior exclusions against current steps/capacity instead of treating
  the November 12/14 decisions as permanent. Current route log peaks in the
  middle bands differ from the older audits; see the 30-45 report.
- Cached source: QuestieDB revision `0f7d8adc92b28ac6594f4ad8745257f4d9784edf`,
  through `tools/questfacts.py`; client-presence checks use the committed
  `tools/reference/forever.json`. No game-data update was performed.

## Low-level and Wetlands warning dispositions

| Warning/candidate | Disposition |
|---|---|
| 18 Northshire; 3361 Coldridge; 94414/92474 Zephras | Earlier pickups cross the known minimum-level gate; retain. |
| 97277 Coldridge; 99053 Teldrassil; 92481/93552 Zephras; 86585 Loch Modan | Objective/escort is already inside the same short area or trip. A straight-line intersection does not establish an extra excursion. |
| 20/98387 Lakeshire; 490 Teldrassil | Existing hub/grind/turn-in timing; no new missing pickup established. |
| 134/173/58 Duskwood | Later level/chain work, also covered by the late-Duskwood alternate. See the 30-45 report. |
| 98291 Death to the Dragonmaw | Requires the raptor turn-ins in the reviewed route references. Taking it at Howin before that is not supported. |
| 98208 Bloom of the Heavens | Inn proximity is not a visit to the south bay. The later chest/Nord'el/ingot loop already pairs the work. |
| 303 The Dark Iron War; 378 The Fury Runs Deep | Already in the Stockade guide, including outdoor preparation at Dun Modr. Not globally missing; offering this guide during the Thandol visit is a separate integration opportunity. |
| 304 A Grim Task; 88756 Bring Back a Bang; Villard chain | Additional higher-level/elite Dun Modr objectives, not equivalent to 472's free delivery. Do not infer safety from the nearby giver. |
| 98310 Gleaning Our Future; 98313 For Further Study | The latter follows the former's four awakened golems after the existing Goaz Warder work. Not a standalone free Ironforge delivery merely because Whelgar offers it later. Cache lacks complete chain/eligibility; verify live before adding a group extension. |
| 1012 Insane Druids | Opens after 1011 in the late-Ashenvale alternate, but adds three named level-32-quest targets. Not an established free overlap in its 26-30 chapter. |
| 526 Lightforge Ingots | Cached Classic-shaped intermediate differs from the current 324-to-322 route. Requires live-chain verification; do not insert an extra ingot hunt from name matching alone. |
| Crafting/fishing Camping 101 candidates | Profession lessons intentionally excluded from the leveling chapters; gathering/cooking lessons are treated separately. |
| 94776 Divine Grace and similar trainer leads | Class eligibility and destination matter; sharing a visited trainer is insufficient evidence of a general leveling omission. |

## Validation and live checks

- `python tools/questroute.py audit`: passed, 12,652 total loaded steps across
  both factions; warnings remain (not failures).
- `python tests/run.py`: passed, zero failed runs, 300.7 seconds. This establishes
  the current baseline, not that the catch-up defect is fixed.
- In-memory first-visit 472 experiment: zero route-audit errors. Band reports
  record separate experiments; independently passing insertions do not prove
  that all insertions combined fit the log.
- No runtime/data files changed, no `Data.lua` changes, no installation or reload
  required for these audit documents.

In game: accept 472 now and confirm the Longbraid turn-in joins the current Dun
Modr trip; check whether another later-completed quest preceded its disappearance;
verify 684/682 at the Arathi stops, 975 immediately after 969, and 5238 after 5226.
Use screenshots/recorder evidence for the unresolved live chains before changing
their prerequisites.
