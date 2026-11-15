# Quest Interaction Audit Implementation Plan

> **For agentic workers:** Use executing-plans for the reported fix and independent faction audits under dispatching-parallel-agents. Track the steps below.

**Goal:** Prevent avoidable return trips caused by missing quest dialogue, event triggers, items, and follow-ups in both factions' step guides.

**Architecture:** Keep corrections in the existing quest data and existing step types. Compare interactions in both supplied local addons with our loaded main, alternate, dungeon, class, and special guides; confirm material facts online and record evidence and limits.

**Tech Stack:** Lua 5.1 quest data, Python/lupa headless scenario harness.

**Spec:** Owner's November 15 request and repository AGENTS.md.

## Global Constraints

- Runtime text must be ASCII; preserve both byte-identical TOCs and the version token.
- Reference addons are read-only; write original instructions from verified facts.
- Add a scenario reproducing the reported in-game bug before changing its guide.
- Preserve route filtering and player-controlled interactions. Do not automate gossip.
- Run the full harness, then python tools/install.py; do not publish or push a tag.

## Review Focus

- Both Sovik pickups must explain the gossip choice before departure.
- Closing gossip must not acknowledge a quest pickup.
- Main, alternate, and dungeon copies must carry the corrected instructions.
- Quest availability and Classic-only facts must not be asserted as verified Forever changes.
- Missing dialogue triggers must be explained at the current step, not only in a later warning.

### Task 1: Sovik pickup

Files: tests/scenarios.lua, tests/run.py, QuestHorde3040.lua, QuestHordeDungeons3045.lua.

- [x] Add and run failing player-visible scenarios for the two Sovik pickups and absent Rig Wars.
- [x] Add the exact gossip choice, safe retry advice, and quest-log departure check.
- [x] Run the focused scenarios and inspect gating and route order (3 passed).

### Task 2: Alliance and Horde interaction audits

Files: affected faction quest data; tools/audits/2026-11-15-{alliance,horde}-interactions.md.

- [x] Inventory reference dialogue/event/item directives and match loaded guide steps.
- [x] Record exact findings and evidence; add regression coverage for consequential omissions.
- [x] Correct confirmed omissions with original concise instructions.
- [x] Record already-covered, excluded, and uncertain cases and coverage counts.

### Task 3: Integration and installation

Files: tools/audits/2026-11-15-quest-interactions.md, CHANGELOG.md if its current unreleased section applies.

- [x] Review all edits and evidence together; run python tests/run.py (411 runs passed).
- [x] Run python tools/questroute.py audit (12,648 steps passed).
- [x] Install via python tools/install.py (71 copies verified, v0.25.0-dirty).
- [x] Report changes, test results, audit limitations, and concrete in-game checks.

## Owner's screenshot follow-up

- [x] Reproduce and correct item-ID versus bag/slot cooldown lookup; show live cooldown on the clickable item.
- [x] Reproduce and correct missing flight-route initialization before auto-flight.
- [x] Accept completion-history ID arrays and keyed sets; retain affirmative history through incomplete reads this session.
- [x] Make Hearth -> Fly handoffs and named flight selections explicit across both factions.
- [x] Correct Snellig's wreck, lower-deck access and waypoint; review related interior-access directions.
- [x] Add preparation-only dungeon routing, early preparation choices and complete outdoor readiness checks.
- [x] Replace the wide ready-run control with a footer icon and keep the current quest instructions first.
- [x] Run the full combined suite and install the final build; record owner checks.
