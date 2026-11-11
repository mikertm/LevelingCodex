# Warrior macros: from one spell per button to smart buttons

Follow-up to [2026-11-09-warrior-macros.md](2026-11-09-warrior-macros.md). That audit fixed the castsequence loops that got stuck, but it split the set into one-ability macros. The owner's feedback was that this felt like "abilities separated with a macro just because". This pass redesigns the set around what Forever's macro engine can actually do.

## What the engine allows (the design rules)

| Fact | Source | Consequence |
| --- | --- | --- |
| A macro **stops** at the first known spell that can't be used now (cooling down, not lit, no Rage). | CLAUDE.md client facts; the [community Forever macro notes](https://github.com/nobody174/wow-forever/blob/main/wow-forever-macros.md) report that "Revenge, else Sunder" never reaches Sunder (tested 2026-10-09). | No "A, else B" fallbacks and no priority lists. Revenge, Victory Rush, Shield Slam, Last Stand and Shield Wall each keep a button. |
| Unlearned spells are skipped. | CLAUDE.md | A rider can name a spell learned later (Shield Block at 16 on a 12+ button). |
| Off the global cooldown in build 70862 (`SpellCooldowns.StartRecoveryTime` = 0 or no row): Bloodrage, Shield Block, Taunt, Charge, Last Stand, the stances, and Heroic Strike/Cleave (next-swing). On it (1500): Sunder, Revenge, Overpower, Thunder Clap, Shield Slam, Shield Wall, Victory Rush, shouts, Execute, Hamstring, Rend. | `tools/.cache/1.60.1.70862/SpellCooldowns.csv`, `SpellCategories.csv` | One GCD ability plus off-GCD "riders" fire on one press. A rider goes **after** the main ability: if the rider is cooling down the macro stops there, and nothing is lost. |
| Stance changes need their own press (Forever added a micro-GCD). | [EU forum report](https://eu.forums.blizzard.com/en/wow/t/warrior-stance-dance-now-triggers-micro-gcd/633220) | Stance dances stay as conditional branches, one step per press. |
| Controller binds use the triggers as modifiers (RT+A, LT+X...). | Data.lua pad layout | No `[mod:]` conditions: a trigger-modified press would always count as "modifier held". Context comes from stance, combat, target, equipment and `known:`. |
| Charge with Vanguard: one beta report of "Spell Not Learned" or "Must be in Battle Stance" in macros, with the workaround `Charge(Rank 1)` (unconfirmed). Another report says rankless Charge works. | [US forum thread](https://us.forums.blizzard.com/en/wow/t/2377230) | Kept rankless Charge (the owner's 2026-10-15 test). The Fight tip asks players to report the error. To check in game at 25. |

Community sources compared: [RankedBoost Forever Protection macros](https://rankedboost.com/world-of-warcraft/forever/macros/warrior/protection/) (Shield Block + Revenge, Taunt + Sunder, Bloodrage riders), the [community Forever macro notes](https://github.com/nobody174/wow-forever/blob/main/wow-forever-macros.md) (Taunt `@targettarget`, mouseover interrupt, stance-aware Overpower) and the classic [Charge/Intercept stance macro](https://us.forums.blizzard.com/en/wow/t/classic-wow-warrior-charge-intercept-macro/326172). Their modifier-based variants were not used because of the controller rule above. All macro text here is our own.

## Findings on the previous set

- **The stance dance for Charge before 25 was already there.** Fight at 10-24 went Battle, Charge, Defensive, Sunder, one press each. Its tips didn't sell that, and a player whose macros were never refreshed would still have an older body. The new title says "Charge stance dance / Sunder" and the first tip spells out the presses.
- **Seven of 16 macro names were a single `/cast`** (Battle Shout, Rage up, Cleave, Victory Rush, Panic, Challenge Shout, Shield Slam), plus Revenge with only `/startattack`. They added nothing over the spellbook and used up character macro slots (Classic allows 18).
- **Missing:** Demoralizing Shout (14) had no button. Overpower (12, Battle) had no button, although Forever gives it a shared cooldown with Revenge. Bloodrage was manual, although the plan spends two points on Improved Bloodrage. Nothing helped controller players re-target after a kill or Taunt an enemy hitting a party member.
- **Stale guide text:** seven Rend trainer notes said "Your Fight macro keeps it on the target", but Fight hasn't cast Rend since the 9 Nov audit.

## The new set (Data.lua `WARRIOR.macros`)

Names, pads and keys are unchanged, so existing bars keep working. Every replaced body is listed in `warriorLegacyBodies` (Macros.lua) and updates in place without SavedVariables.

| Name | Levels | Now | Why |
| --- | --- | --- | --- |
| Fight | 1-3 | `/targetenemy [noharm][dead]`, start attack, Heroic Strike | One press after a kill or a quest turn-in picks the next enemy. |
| Fight | 4-9 | + Charge out of combat, Heroic Strike in combat | `stance:1` dropped (Battle is the only stance before 10). |
| Fight | 10-24 | Battle, Charge, Defensive, Sunder dance + `/cast [combat] Bloodrage` | Bloodrage rides only in combat, so it never blocks Charge. On the swap back to Defensive it adds Rage after Tactical Mastery's cut. `known:71` stays on the Defensive branch for players before the stance quest. |
| Fight | 25-60 | Vanguard Charge from Defensive (Battle dance fallback), Sunder, Bloodrage rider | `nodead` dropped after `/targetenemy` to stay under 255 (251 chars). |
| Fight pack | 6-19 | Thunder Clap (+ start attack) | |
| Fight pack | 20-29 | Thunder Clap, then `/cast [harm,nodead] Cleave` | Cleave queues only after a Clap that lands, at most one per 6 s. Replaces the separate Cleave macro. |
| Fight pack | 30-60 | Berserker swap, Clap, then `[nostance:3]` Cleave | |
| Battle Shout | 1-13 | Battle Shout | unchanged body, now ends at 13 |
| Battle Shout | 14-60 | `[combat,harm,nodead,known:1160] Demoralizing Shout; Battle Shout` | Buff out of combat, debuff in combat. Clearing the target in combat gives Battle Shout. |
| Rend again | 4-60 | `[harm,nodead]` added | |
| Hamstring | 8-60 | `[harm,nodead]` added | |
| Taunt | 10-60 | Defensive swap; Taunt on mouseover, else target, else the target's target; then Sunder on the same enemy | Taunt is off the GCD, so Sunder follows in one press. Selecting the healer who is being hit works on a controller. |
| Shield Bash | 12-29, 30-37, 38-60 | mouseover first, then target | Interrupt a second caster without changing target (keyboard). |
| Revenge | 12-60 (was 14) | `[stance:1] Overpower; Revenge`, then `/cast [stance:2,equipped:Shields,combat] Shield Block` | Same trigger (an avoid), shared cooldown. With Shield Specialization 5/5 a block pays 5 Rage back, so keeping Block up is nearly free and feeds Revenge. |
| Block & Revenge | 16-60 | Shield Block (with Defensive swap), then `[stance:2,harm,nodead] Revenge` | The mirror of the Revenge button, so either press gets both when both are ready. |
| Victory Rush | 20-60 | `/targetenemy [noharm][dead]` added | The target is always dead when Victory Rush lights. |
| Panic | 26-60 | `#showtooltip Last Stand` | Kept apart from Shield Wall: one cooling down would block the other. |
| Challenge Shout | 26-60 | + `/cast [harm,nodead] Cleave` | Start threat on the pack you just pulled to you. |
| Shield Wall | 28-60 | unchanged | |
| Shield Slam | 40-60 | + `/cast [stance:2,equipped:Shields] Shield Block` | |
| ~~Rage up~~ | 10-60 | removed | Now the Fight rider. |
| ~~Cleave~~ | 20-60 | removed | Now the Fight pack rider. |

Distinct macro names at 60 went from 16 to 14.

## Other Data.lua text changed (mirror into the guide pages)

- Trainer L10 Bloodrage: "Pre-pull Rage." -> "Fight uses it in combat whenever it is ready."
- Trainer Rend (L4, 10, 20, 30, 40, 50, 60): "...Your Fight macro keeps it on the target." -> "...Use Rend again on enemies that will live through the bleed."
- Trainer Demoralizing Shout (L14, 24, 34, 44, 54): "Less damage taken on packs." -> "+ Your Battle Shout button casts it in combat."
- Trainer Cleave (L20, 30, 40, 50, 60): "Two-target Rage dump." -> "Fight pack queues it after each Thunder Clap."
- Trainer Overpower (L12, 28, 44, 60): "Battle Stance only." -> "+ Your Revenge button casts it there."
- Talent Improved Bloodrage `why`: "...is your pre-pull Rage. +50% means you arrive with enough to Thunder Clap straight away." -> "...fires from Fight in combat whenever it is ready. +50% means you can Thunder Clap right after the Charge."
- Tips 10-19: the Bloodrage, Shield Block/Revenge and Taunt steps now describe the riders and the party-member Taunt.
- Tips 20-29: the Demoralizing Shout/Cleave step now points to the Shout button and the Fight pack rider.
- Tips 30-39: Shield Block step mentions the Shout button.
- Tips 40-60: the Cleave and Shield Block steps describe the riders.

## Checks

- All 22 bodies are ASCII and 255 characters or fewer (longest: Fight 25-60, 251). Names 16 or fewer.
- `python tests/run.py`: all runs pass. `warriorPackMacros` now checks every rider, the Shout switch, Taunt through a party member, auto-targeting and that no Warrior macro uses `/castsequence`. `warriorMacroUpgrade` checks in-place upgrades from both earlier builds without SavedVariables.

## To check in game

- **10-24:** from Defensive, Fight should go Battle, Charge, Defensive (Bloodrage should fire on that press if ready), then Sunder. Check that Bloodrage never fires before the Charge.
- **14+:** Battle Shout button: buff out of combat, Demoralizing Shout in combat with an enemy selected, Battle Shout in combat with no target.
- **12+ in Battle:** Revenge button casts Overpower after a dodge. **16+:** Revenge lit fires Revenge and Shield Block together. Shield Block button with Revenge lit fires both.
- **Taunt:** select a party member who is being hit and press Taunt. The enemy should turn and take a Sunder.
- **20+:** Clap with 35+ Rage queues Cleave. Mashing Clap while it cools down shouldn't queue Cleave. Victory Rush right after a kill picks and hits the next enemy.
- **25:** Vanguard Charge from Defensive: watch for "Spell Not Learned" / "Must be in Battle Stance".
- **Rage feel:** if packs feel Rage-starved, the Cleave rider is the first suspect.
