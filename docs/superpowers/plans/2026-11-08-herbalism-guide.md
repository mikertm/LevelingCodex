# Herbalism and Learned Professions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for native execution or superpowers:subagent-driven-development for delegated execution. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the WoW: Forever Herbalism 1-300 guide and show each character only the profession guides they have learned.

**Architecture:** The Professions tab selects from one snapshot of guarded skill readings and refreshes on changes. Herbalism supplies a catalog and route to the same gathering view and card code as Mining. The game reference keeps client evidence separate from source-backed route recommendations.

**Tech Stack:** Lua 5.1, WoW: Forever Interface 16001, Python 3 with lupa, wago.tools `wowf` build `1.60.1.70862`.

**Spec:** [Herbalism and learned profession guides](../specs/2026-11-08-herbalism-guide-design.md), approved after commit `314adc5`.

## Global Constraints

- Work on `codex/herbalism-guide` in the existing isolated worktree. Read the spec and `CLAUDE.md`.
- Guard optional APIs and event registrations. Keep globals within the current allowlist. Render ASCII with `ns.plain` and use the existing texture fallback. Use the existing parchment layout and controller helpers.
- Keep both TOCs byte-identical with `@project-version@`. Keep crafting-window interaction read-only. Herbalism adds no crafting-window handler.
- Write a failing scenario or data check first for each behavior change. Run `python tests/run.py` before each commit. Record test results and commits in one ledger under `.superpowers/sdd/`.
- Install with `python tools/install.py` once final verification passes. Merge and push require the owner's instruction. Never push a tag.

## Review Focus

1. One of the two primary profession slots can be empty. A valid learned skill in the second slot still appears, and a complete retail read wins over a collapsed classic fallback for absence (Task 1).
2. API failures can be temporary. Keep the selection preference, distinguish an unavailable read from removal, and restore the guide on recovery. A confirmed unlearn clears the old selection and preview (Task 1).
3. A character can learn or unlearn with the tab open and profession cards off. Check both skill events and the minimal client's poll. A stale banner cannot select a removed guide (Task 1).
4. An herb's name can still exist while its client item icon, lock threshold or zone changes. Exercise the audit and diff with mutated reference records and a route with a skill gap between two herbs (Task 2).
5. A gathering step can contain a locked future herb while an off-route herb opens. Exercise both and keep Mining's existing difficulty and banner copy (Task 3).

## Files and responsibilities

| Files | Responsibility |
| --- | --- |
| `Professions.lua` | Skill sources and cache, gathering lookup and colors, skill-up cards and events |
| `ProfessionTab.lua`, `Window.lua` | Eligible switch, selection, empty and unreadable states, refresh, gathering rows |
| `ProfessionData.lua` | Herbalism's catalog, tiers, steps and camp objects |
| `tools/gamedata.py`, `tools/reference/forever.json` | Extract and audit Herbalism evidence, report changes between builds |
| `tests/run.py`, `tests/scenarios.lua`, `tests/wowmock.lua` | Offline evidence checks and player-facing behavior |
| `tools/audits/2026-11-08-herbalism.md` | Sources, disagreements and live checks |

### Task 1 — Limit the switch to learned professions

**Files:** `Professions.lua`, `ProfessionTab.lua`, `Window.lua`, `tests/run.py`, `tests/scenarios.lua`, `tests/wowmock.lua`.

**Interfaces:** Add `ns.profSkillSnapshot() -> { [key] = { rank, cap, hidden, unavailable } }` for guided professions. `ns.profSkill(key)` keeps its existing first three returns and can return `unavailable` fourth. Add `ns.refreshProfessionTab()` in Window to refresh the visible Professions tab through the standard redraw. `ns.profTabShow(key)` remains the banner entry point.

- [ ] **Write the switch and live update scenarios.** Extend `profNone` to check the plain-text supported list and zero switch buttons, keeping its debug checks. Remove `tailorNone`'s obsolete browse assertion. In `profTabCases`, replace the direct clearing of `MOCK.skills` with an unlearn event and assert the empty state. In `enchantTab`, assert that only Enchanting is clickable and its button fits the existing 568px content width. Keep existing recipe, shopping, zone and theme checks.

  Add `profLearnedSwitch` starting with Mining only, tab open, and `noProfCards` set. Learn Blacksmithing. Check for both switch buttons while the header still reads `Mining 30 / 75`. Remove Mining and assert the header moves to `Blacksmithing 97 / 150` without reopening. Relearn Mining and verify Blacksmithing remains selected. Click a different Blacksmithing route step and then change rank twice (including a return to the previous rank). Check that the earlier preview does not return. Remove both and check `No supported professions learned.`. Use the existing `findButton` with exact labels. Add `MOCK.removeSkill(name)` that removes the skill and fires the existing events. Register the scenario under `WARRIOR/<variant>/prof-learned-switch` for full and minimal.

- [ ] **Write the skill source and stale shortcut scenarios.** Update `profCollapsedCold` so the open tab shows the expand-Skills hint and no guide buttons, then adds the buttons when the heading opens. Preserve `profCollapsed`'s cached header and delayed card assertions, and check that unknown guides never gain buttons. Add `profReaderRecovery`: save and wrap the mock getters to make reads throw, then restore them. With Mining selected and Blacksmithing also learned, invalidate only the Mining reading by making its row unreadable. Assert Mining is hidden, the unavailable text appears and Blacksmithing can render. Restore the reading and assert the earlier Mining selection returns. Add the full-client case with a first primary slot of `nil`, a valid second slot, and a collapsed fallback. Verify the valid slot is read and the view has no false expand-Skills hint. Register under `prof-reader` in both variants, skipping only the retail-slot assertion in minimal.

  In `PROF_BANNER`, let a Blacksmithing card appear, remove Blacksmithing while Mining is learned, then use the existing click and `/codex` shortcuts. In fresh sequences for each shortcut, assert the header shows Mining and that Blacksmithing is absent from the switch. Extend the empty-state run with a level-up at 10 and assert no profession training row for an unlearned skill. Retain `profLevelTier` for a learned skill.

- [ ] **Verify red.** Run `python tests/run.py -k prof`, `python tests/run.py -k enchant`, and `python tests/run.py -k banner-target`. Expect the old all-guides switch, missing empty state, and stale banner selection to fail their assertions.

- [ ] **Implement the snapshot in Professions.lua.** Read returned retail slots explicitly so a hole does not end iteration. Treat a successful enumeration with readable returned entries as complete. Read classic rows with guarded calls when needed. A positive rank from either source confirms membership. Complete data can prove absence. A known closed heading can keep the last confirmed rank and cap when complete data is unavailable. A failed classic row must not make the list look complete, and a failed API alone must not be interpreted as a closed heading. Keep confirmed rank and cap in the session cache and clear them on observed absence. Return `hidden` for a collapsed, never-confirmed skill and `unavailable` for an unreadable skill. Keep the old reader contract for the crafting guide and use the same snapshot for debug and level-up rows. Debug lists every guide and distinguishes absent, closed and unavailable.

- [ ] **Implement selection and refresh.** Build the buttons and render the selected rank from one snapshot. Use `No supported professions learned.` when empty, `Open the character window's Skills tab and expand Professions to show your learned guides.` for a closed heading, and `Profession skills are unavailable right now.` for unavailable reads. With no confirmed guide, include the supported names as text. Retain a still-learned selection. Use the first confirmed guide on observed removal and clear its old preview. If a read is temporarily unavailable, hold that key as a pending preference while choosing a visible guide. Restore the preference when confirmed unless the player made another selection. Validate a requested banner key before storing it.

  Compare rank, cap and availability with the prior skill reading in `checkSkills`. Call the window refresh once when there is a difference, independently of whether any card was shown. Clear a route preview when the rank actually changes. Keep the existing skill event and one-second poll paths. Guard learning and spell-change events as supplementary signals, without letting these disable the skill polling fallback. Keep the normal `Window.lua` redraw for scroll position and controller focus.

- [ ] **Verify green and commit.** Run the targeted commands, then `python tests/run.py`. Expect zero failures. Stage only Task 1 files and commit `Show learned professions and refresh the switch on skill changes`.

### Task 2 — Research and audit Herbalism's data

**Files:** `ProfessionData.lua`, `tools/gamedata.py`, `tools/reference/forever.json`, `tests/run.py`, `tools/audits/2026-11-08-herbalism.md`.

**Interfaces:** `LevelingCodexProfessions.HERBALISM = { name = "Herbalism", skillLine = 182, icon = "trade_herbalism", tiers, herbs, steps, camp, notes }`. Each herb has `{ name, item, icon, skill, yellow, green, grey, zones }` with numeric item ID and absolute thresholds. Each step has `{ from, to, title, herbs, note }` with herb names. Camp entries have `{ name, spell, skill, source, text }`. `notes[300]` calls out Black Lotus. The reference adds `professions.Herbalism.gathering = { icon, items, lockSkills, areas }`. The `items` map uses stringified item IDs with `{ name, icon }` values. `lockSkills` maps stringified herbalism lock IDs to required skill lists. `areas` is a sorted list of unique, named top-level AreaTable zones.

- [ ] **Complete the evidence packet.** Import `gamedata.Tables` against the source checkout's cached build at `C:/Users/forst/Downloads/LevelingCodex-repo/LevelingCodex/tools/.cache/1.60.1.70862`. Copy the needed cached CSVs to the worktree's ignored `tools/.cache/1.60.1.70862` for reproducible CLI runs. Check `SkillLine` 182, `ManifestInterfaceData` icon 136246, the `Lock` slots with `Type=2` and `_Index=2`, and herb item IDs and icons from `ItemSparse` and `Item`. Probe `GameObjects` for named herb rows and keep its limits explicit.

  Start from the Wowhead Forever skill page's own lists, the overview, and the four tier spell lists already read in the spec. Check the remaining herb objects by normal in-app navigation from their links, with pauses between scripted lookups. Stop scripted requests if Human Verification appears. Cross-check route bands, trainer ranks and camp unlocks with the named Forever guides in the spec. For each chosen zone, check the linked object record and the AreaTable spelling. Use the top-level zone in `zones` and put subzone details in the route note. Prefer the object record when it disagrees with a zone list. Keep unsupported locations and novel endgame items out of the gathering route and document what needs a live check.

- [ ] **Write the failing game checks.** Add `HERBALISM` to `PROF_KEYS` and test that the data has four tiers, every standard node in the catalog, ordered cutoffs, unique named herb entries, and valid referenced herb names. Keep the existing ASCII scan. Check the reference anchors `skillLine == 182`, `items["2447"]["name"] == "Peacebloom"`, `lockSkills["29"] == [1]`, `lockSkills["1124"] == [300]`, and presence of `Zephras Isle` and `Riverglades` in `areas`. Check the three camp recipe spells 1229705, 1262980 and 1263070 with their client colors and materials. Extend `tool_checks` using deep copies to exercise item name/icon mismatches, an invalid skill threshold, an unknown zone, a missing camp recipe, a changed blueprint minimum, and a gather step containing only herbs above or grey at a skill in its band. Check that `diff` reports a changed item and a changed herbalism lock under `HERBALISM`. Compare against an older reference with no `gathering` section and check that it reports the new gathering evidence.

- [ ] **Verify red.** Run `python tests/run.py -k prof`. Expect missing Herbalism guide and reference anchors. Ensure the new checks report those as data failures without indexing missing keys.

- [ ] **Implement the reference and audit.** Add `"Herbalism": 182` to `PROFESSIONS`. Register `Lock` and `AreaTable` in `TABLES`, and use existing spell and item extraction for Herbalism's recipes. Build the `gathering` section from the client using the source-backed list of standard item IDs, all herbalism lock slots and top-level zone names. Report additions, removals and changes to these fields in the normal profession diff. A client lock at the right skill corroborates a threshold. Without a named object join, cite the node-to-skill association externally and avoid presenting a particular lock ID as proven for that node. If the client omits an item or icon, let the audit identify the missing evidence rather than using a placeholder value.

  Audit the guide's item ID, name and icon, its lock threshold and each zone name. Check `skill <= yellow <= green < grey` with the researched cutoffs, and validate each skill in `range(step["from"], step["to"])` against at least one named herb with `herb["skill"] <= skill < herb["grey"]` and a route zone for the faction. Audit camp spell IDs and the client's blueprint requirements where present. Camp training sources, cutoffs and spawn locations stay attributed as server-side or source-backed data. Use `audit_professions` so `audit`, `profs` and the update report share the checks.

- [ ] **Write the guide and audit.** Enter the seven half-open bands in the spec, caps 75/150/225/300, training at 1/50/125/200 and `level = 1` for all four tiers. Choose examples on both factions' taught-by lists. Include Syriel Nightrain and Halassa Fernbreeze through Journeyman, then recommend mainland options. Store all 28 standard herbs through Black Lotus. Peacebloom and Silverleaf use 1/25/50/100. Use the earlier supported Dreamfoil cutoffs when the sources disagree. Include a skill-eligible fallback in bands with locked future herbs. List Incense Candle (20, trainer), Greenhouse (140, Blueprint: Greenhouse), and Seed Hybridizer (300, Blueprint: Seed Hybridizer) with what each does. Keep optional text plain ASCII and banner rows at most 60 characters.

  The audit records each node's object and item links, chosen skill and cutoffs, recommended zones and disagreements. It also records tier spell and trainer evidence, exact camp recipe facts and server-side unlock sources, and the open checks from the spec. Include the mismatch between Wowhead's tier lists and the guides that list the Skyborne trainers at Expert and Artisan.

- [ ] **Regenerate and verify.** Run `python tools/gamedata.py build --build 1.60.1.70862`. Expect the same build and a new Herbalism section, with no class or other profession changes. Run `python tools/gamedata.py audit -k HERBALISM -v`, `python tools/gamedata.py profs HERBALISM` and `python tools/gamedata.py recipes Herbalism`. Expect zero audit errors, seven bands, and the three camp recipes in the reference. Run the targeted harness and then `python tests/run.py`. Stage Task 2 files and commit `Add and audit the Herbalism gathering route`.

### Task 3 — Share the gathering view and cards

**Files:** `Professions.lua`, `ProfessionTab.lua`, `tests/run.py`, `tests/scenarios.lua`.

**Interfaces:** Append `HERBALISM` to `ns.PROF_ORDER`. Replace the two internal vein-only helpers, whose callers are in Professions and ProfessionTab, with `ns.profNode(key, name) -> node or nil` and `ns.profNodeColor(node, skill) -> color`. `ns.profZones(node)` remains the faction and Skyborne filter.

- [ ] **Write the failing scenarios.** Register `WARRIOR/<variant>/prof-herbalism` with `skills:HE;1;75:professions:Alliance:Human`, then login and run `herbalismTab`. Register a separate fresh `prof-herbalism-cards` run for `herbalismCards` so cards and skill readings cannot leak from the tab run. At 1 assert the single Herbalism button and header, Peacebloom and Silverleaf orange, Earthroot red, and Alliance starter zones. Change faction/race with a normal redraw. Assert Horde starters for an Orc and Zephras Isle for Skyborne. Check the route steps and camp rows, with no smelt or shopping section. At 25 and 50 check Peacebloom yellow and green, and at 50 check Journeyman training even at character level 1. Reach 300 and check `ROUTE DONE` and the Black Lotus note.

  Advance from 14 to 15 and assert `NEW HERB` and `Earthroot (15)`. Open the guide using the card. Advance from 119 to 120 and assert the off-route `Grave Moss (120)` unlock. Cross 125 with a cap of 150 and assert `TRAIN EXPERT`. Advance one ordinary point and assert no new card. Jump from 269 to 270 and verify the new step and Dreamfoil unlock. Verify a 299-to-300 card names Black Lotus. Use `MOCK.advance(1.2)` for the polling path and dismiss cards between transitions. In `profSkillUps`, use an unsupported skill such as Cooking for the old unsupported-profession assertion. Extend `profNone` to expect Herbalism in the text and debug list. Preserve the Mining cards and read-only crafting tests.

- [ ] **Verify red.** Run `python tests/run.py -k prof-herbalism`. Expect missing Herbalism switch and unlock cards.

- [ ] **Implement shared gathering.** Use each guide's `herbs` or `veins` and the step's corresponding names. Give herb rows their explicit cutoffs. Keep the +25/+50/+100 defaults for Mining. Show the node icon, skill, color label and faction zones in the existing step card. Use smelt advice only when the guide supplies smelting. Reuse the existing route notes and camp section. In skill-up cards, use the first named node for gathering steps and emit `NEW HERB` or `NEW VEIN` as appropriate. Use the existing banner target and click handler for navigation.

- [ ] **Verify green and commit.** Run `python tests/run.py -k prof-herbalism`, `python tests/run.py -k prof`, and the full harness. Expect zero failures, including existing Mining, controller and crafting-window checks. Stage Task 3 files and commit `Show Herbalism routes and skill-up cards`.

### Task 4 — Review, verify and install

- [ ] **Review the branch as a whole.** Compare `main...HEAD` against the approved spec and this plan. Send the diff and Review Focus list to a fresh Sol reviewer for a read-only review.
- [ ] **Do one fix pass.** For each confirmed defect, add a scenario or data check that fails first, apply the smallest fix and verify it passes. Run the full harness before committing fixes.
- [ ] **Verify the final build.** Run `git diff main...HEAD --check`, `python tools/gamedata.py audit -k HERBALISM -v` and `python tests/run.py`. Confirm the TOCs still match each other, contain the version token, and have the same load order as the base. Record the branch head and test results.
- [ ] **Install for live testing.** Run `python tools/install.py` from the worktree. Capture the installed version and require `all copies verified`. Tell the owner to `/reload`.
- [ ] **Report the live checks.** Ask the owner to check the learned switch before and after training or expanding Skills, Find Herbs and the first node and training cards, Zephras Isle trainer ranks, the disputed color cutoffs, and camp unlocks. Link the audit so the owner can compare any discrepancies.
