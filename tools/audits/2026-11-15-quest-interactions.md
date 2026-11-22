# 2026-11-15: Quest interactions and preventable return trips

The owner reported reaching Booty Bay without Chief Engineer Scooty because the
guide never said to choose Sovik's gossip option. This pass checks the same
failure class in both factions: conversations that unlock pickups, dialogue or
emotes that give credit, escorts that need an explicit release, object and item
interactions, and follow-ups that appear only after an event.

## Scope and evidence

- Both supplied addon copies were read in place, without modifying them:
  `local guide reference`
  and its sibling `local guide reference`.
- reference guide A's `Guides/forever` interaction directives and reference guide B's
  `Guides-Forever` dialogue/item/event instructions were compared with loaded
  Codex main, alternate, dungeon, class, and special guides. Reference syntax and
  facts informed the checks; replacement instructions are original.
- [Alliance findings](2026-11-15-alliance-interactions.md) and
  [Horde findings](2026-11-15-horde-interactions.md) contain individual corrections,
  coverage counts, reference locations, online corroboration, and exclusions.
- This is an interaction audit of the shipped routes, not a claim that every
  quest in Forever has been played or that every Classic prerequisite is still
  enforced. In-game behavior remains the final check. No guide is marked verified.

## Reported Sovik issue: quest 2842

Affected files: `QuestHorde3040.lua` (`hillsbrad-30`) and
`QuestHordeDungeons3045.lua` (`dungeon-gnomeregan`).

Before: the main route said Sovik had an errand, the dungeon guide said Rig Wars
had to be active, and both hid Sovik's step unless Rig Wars was in the log. Neither
said to select the gossip option.

After: both steps name **What else do you have to say?**, explain that it can
accept the quest automatically, advise talking again if it fails, recommend
Nogg's Rig Wars as a fallback, and require checking the quest log before leaving
Orgrimmar. The unconfirmed hard `ifOnQuest = 2841` filter is removed. Rig Wars
still precedes Sovik for players planning the dungeon.

Evidence:

- reference guide A `Guides/forever/Horde-12-22_Barrens.lua:5128-5144`: the Rig Wars block is
  skipped; gossip option 95758 precedes accepting 2842 and the auto-accept warning.
- reference guide B `local guide reference`:
  the named gossip option precedes accepting 2842.
- [Blizzard's November 10 hotfix](https://us.forums.blizzard.com/en/wow/t/wow-forever-hotfixes-november-13-2026/2403040/6)
  confirms that Sovik's quest offer follows gossip.
- [November 11 player report](https://us.forums.blizzard.com/en/wow/t/title-wow-forever-chief-engineer-scooty-quest-still-requires-repeated-sovik-dialogue-after-nov-10-hotfix/2411645)
  reports repeated dialogue as a workaround and explicitly leaves Rig Wars'
  necessity unconfirmed.
- [Classic quest comments](https://www.wowhead.com/tbc/quest=2842/chief-engineer-scooty)
  corroborate the exact option and report receiving the quest through gossip
  without Rig Wars. The current Forever fallback is qualified accordingly.

## Regression and validation

`questSovikDungeon`, `questSovikRoute`, and `questSovikWithoutRigWars` all failed
before the correction: two lacked the required dialogue text, and the third
lost the pickup when Rig Wars was skipped. All three pass after the correction.
They navigate the real guides, check the displayed instructions, verify that
closing gossip does not acknowledge the pickup, and advance on QUEST_ACCEPTED.

The initial combined harness passed with zero failed runs (357.6 seconds), with
409 existing warnings. The route audit passed all 12,648 loaded steps.

The owner then supplied five screenshots. The subsequent changes and their
regressions are recorded in
[the travel and dungeon follow-up](2026-11-15-step-travel-dungeons.md).
Final combined validation after the screenshot follow-up:

- `python tests/run.py`: **411 scenario runs passed**, zero failures, 329.7 seconds.
- **409 warnings**, unchanged from the pre-fix regression runs and initial audit.
- `python tools/questroute.py audit`: **passed, 12,648 steps**.
- `git diff --check`: clean.
- `python tools/install.py`: **71 files installed and byte-verified**, version
  `v0.25.0-dirty`, into
  `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\LevelingCodex`.
  Both repository TOCs remain identical and keep `@project-version@`.
- No commit, release tag or publication was made. The owner can `/reload` and
  perform the in-game checks below and in the screenshot follow-up.

## In-game checks

1. Horde: plan Gnomeregan, visit Sovik from the route or dungeon guide, use the
   named option, and confirm Chief Engineer Scooty appears in the log before
   leaving Orgrimmar. Check both with Rig Wars active and with it declined.
2. Either faction: Redemption must explain sitting and starting/finishing Tirion's
   conversation; the Northridge hand-in must explain the crate and spawned barrel.
3. Check the corrected escort releases, quest-item actions, and dialogue-gated
   dungeon preparations listed in the faction audit files as those steps arise.

`Data.lua`, trainer/talent/macro guides, the client reference, and both TOCs are
unchanged. No publication tag is created or pushed.
