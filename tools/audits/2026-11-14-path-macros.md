# Macros for every talent path, and an audit of every guide's macros

2026-11-14. Every class now has a macro set for each talent path in `TalentPaths.lua` (PathMacros.lua), next to the
Codex guide's own set (Data.lua `macros`), and every guide set was audited and corrected. The macros you get follow
the path you follow: Set up macros, the level-up refresh, the Macros tab, the level-up banner and chat all read
`ns.pathMacros()`. Switching path moves the macros the Codex made to the new path's versions in place (same name,
same button and key). A custom path uses the set of the path that shares the most points with it.

Follows [2026-11-10-warrior-smart-macros.md](2026-11-10-warrior-smart-macros.md), whose design rules the owner
approved; this pass applies them to every class and spec.

## The rules every set follows

| Rule | Why |
| --- | --- |
| One global-cooldown spell per press, off-GCD "riders" after it | Forever stops a macro at the first known spell it can't use now (2026-10-09 test, community notes). A rider placed after the main spell costs nothing when it is cooling; placed before, it blocks the main spell for its whole cooldown. |
| A spell that must land first (Cold Blood, Presence of Mind, Inner Focus, Nature's Swiftness, Premeditation, Death Wish) lives on its own Burst button | There, blocking while it cools is fine and the tips say so. |
| `/castsequence` only over steps without cooldowns, or with a cooldown step placed where the steps before it outlast the cooldown | A sequence stalls on a step that isn't ready. The audit warns on every cooldown step; each one kept is explained in its macro's tips. |
| Context from combat state, target, stance, form, equipment, `known:`, never `[mod:]` | Controller players hold the triggers as modifiers. |
| Heal buttons: mouseover, else friendly target, else the friendly unit your enemy target is attacking, else you | Works on a controller (target the enemy the tank is fighting) and with a mouse. |
| Melee and ranged Fight buttons re-target after a kill (`/targetenemy [noharm][dead]`) | One press picks the next enemy. |
| Wand lines use `[nochanneling:Shoot]`; channel guards name the channels (`[nochanneling:Drain Life/...]`) | Shoot toggles off when cast again and isn't a channel. |
| A name keeps its button and key in every set of the class | Switching path updates the macro in place and the bars stay right. |
| Each set covers 1-60 on its own; levels follow the game's learn levels and the path's talent levels | `python tools/gamedata.py facts CLASS` lists both. |

## Tooling (tools/gamedata.py, tests/run.py)

- **Reference:** every spell row carries `offgcd` when `SpellCooldowns.StartRecoveryTime` is 0 (or there's no row) and
  it isn't passive. Lightning Shield, Holy Nova, Touch of Weakness and Shadowguard have an internal copy per rank with
  no cost and no GCD row; only the costed rank counts. Rebuilt from build 1.60.1.70888: only these flags were added.
- **`facts CLASS [PATH]`**: every active spell on one line (ranks, cost, cooldown, shared cooldown, OFF GCD, stance or
  form, icon, tooltip), then each path's talent spells with the level that path learns them.
- **`macros CLASS [--file DRAFT]`**: a class's sets and their audit. The audit (also in `audit` and the harness) now
  runs on the guide set and every path set: spells the class has and when (path sets with their own talent levels),
  255/16 limits, ASCII (path sets: every field), tips on every path macro, pad format, `known:` IDs, versions that
  overlap, two macros on one button or key at a level, more than 18 macros at a level, a path without a set or a level
  10-60 without a macro. Warnings: a cooldown spell on an unconditional line before other casts, a cooldown step in a
  sequence, a name that moves button or key between versions or across paths.
- **Harness:** `path_macro_checks()` proves the audit catches each error on a broken Arms set; scenarios `pathMacros`
  (each spec path's set at every level it changes, the Macros tab note, a switch updating a shared name in place,
  Custom taking the closest set) and `oldMacroBodies` (an older shipped body still updates without SavedVariables).
- **Old bodies:** every guide body this pass replaced is kept in `PathMacros.lua` `ns.OLD_MACRO_BODIES`, so a macro
  made by an older Codex is still recognised as the Codex's and updated at the next level-up (no SavedVariables
  needed). Warrior's older bodies stay in `Macros.lua`'s `warriorLegacyBodies`.

## Changes made in review (after the class drafts)

- **Warrior Arms, Fight pack 30-60:** the draft cast Sweeping Strikes before Cleave, so the button did nothing for the
  30 seconds Sweeping Strikes cools down. Now: stance swap on its own line, Cleave, then Sweeping Strikes as the rider.
- **Priest Discipline, Fight 20-60:** `[nochanneling]` on the wand line -> `[nochanneling:Shoot]`, like every other
  wand line (plain `nochanneling` doesn't see the wand).
- **Paladin Fight tip:** "Improved Judgement (19)" -> "Improved Judgement 2/2 (from 19)" (the guide takes it at 18-19).
- **TalentPaths.lua:** Concussion is 1% per rank, 5% at 5/5 (was "5% per rank, 25%"); Elemental Alacrity is about
  0.17 sec per rank, 0.5 sec at 3/3 (was "0.5 sec per rank, 1.5 sec"), on both the Elemental and Restoration paths;
  Ghostly Strike's "This is how you Ambush in combat." -> "Garrote in combat, or Ambush from behind." (Ambush still
  needs you behind the target).
- **Shaman tips 40-60 and the Rage of the Farseer reason:** "Fight fires it whenever it is ready" -> "Fight fires it
  with a Stormstrike when it is ready" (it rides on the Stormstrike press).

## Data.lua text changed outside the macros (mirror into the guide pages)

Each class section below lists them under "Data.lua text that now reads wrong", old -> new; all were applied as
written except the Shaman Rage of the Farseer wording above. The guide macro sets themselves are replaced as shown
in each class's section 1.


## Druid: guide (Feral mix), Balance, Cat, Bear, Restoration

`python tools/gamedata.py macros DRUID`: **0 errors, 7 warnings**, all intended (see the end of section 2). Game data: build 1.60.1.70888 (`facts`, `spells`, `tree DRUID`, plus the raw `SpellShapeshift` / `SpellCooldowns` / `SpellMisc` rows in `tools/.cache/1.60.1.70888`).

### 0. Druid facts the sets are built on (from the game data)

- **Forms:** Bear Form 10 (quest), Aquatic Form 16 (quest), Cat Form 20 (quest), Travel Form 30, Dire Bear Form 40 (replaces Bear Form), Moonkin Form 40 (Balance talent, row 7). Tree of Life appears in spell form masks but there is no spell for it: not in the player kit. Form numbers shift (Cat is 3 with Aquatic, 2 without), so no `form:N` anywhere; form macros live on that form's bar.
- **What works in which form** (ShapeshiftMask): Faerie Fire works in caster, Cat, Bear, Dire Bear and Moonkin Form and costs mana. There is **no Faerie Fire (Feral)** and **no Tiger's Fury** in Forever (RankedBoost's Shred macro uses Tiger's Fury; the game has none). Wrath, Moonfire, Starfire, Insect Swarm, Hurricane: caster + Moonkin. All heals (Healing Touch, Rejuvenation, Regrowth, Swiftmend, Wild Growth, Nature's Swiftness, Tranquility): caster only, not Moonkin. MotW, Thorns, Innervate, Rebirth, Revive, Remove Curse, Cure/Abolish Poison: caster + Moonkin. **Entangling Roots: caster only (mask 0, not Moonkin).** Barkskin and Nature's Grasp: any form.
- **Off the GCD:** Maul (next swing), Growl, Enrage, Feral Charge in Bear (15 sec), Prowl, Dash, Nature's Swiftness. **On the GCD:** Bash, Barkskin (1.5), Frenzied Regeneration, Nature's Grasp, Innervate, Primal Bite, Shifting Power (1.0), Challenging Roar, Cower, every form. Feral Charge in Cat is a different spell (414924 "Leap behind an enemy", 30 sec, on the GCD).
- **Forever talents:** Shifting Power (Cat only, 55% of base mana for 40 Energy, 8 sec cd); Primal Bite (**Bear only**, 20 Rage, 6 sec cd, high threat); Lacerate (Bear, stacks 5, high threat); Predatory Discipline; Eclipse (each Wrath makes the next 2 Starfires faster, up to 4 charges, 15 sec); Furor 5/5 = 10 Rage on every Bear shift, and Cat Form gives back all the Energy you had plus 10 per second out of form (up to 100). Omen of Clarity is a passive trained at 20 (nothing to rebuff). Poised (32) passive. Pounce needs "prowling and behind" in Forever, like Ravage.

### 1. Guide set (Feral mix): findings, old -> new

| Problem | Old | New | Why |
| --- | --- | --- | --- |
| No damage button at 1-3 | Fight 4-9 only | Fight 1-3 (target, auto-attack, Wrath) + 4-9 | Wrath is learned at 1. |
| Fight 4-9 tip false | "Wrath, Moonfire, Wrath, then melee" | same sequence, `reset=target/combat`, `/targetenemy [noharm][dead]`; tip: it loops, stop pressing to melee | A castsequence never stops; the third press is followed by Wrath again. |
| Caster bar empty from 10 | Fight ended at 9 | Fight 10-19 "Pull / Bear" (Moonfire pull out of combat, else Bear Form, Wrath before the Bear quest); Fight 20-60 "Cat Form" (`/dismount`, `!Cat Form`, Bear fallback) | Implements the guide's own "Moonfire to pull, then shift" and gives RT+A a way back into the form after Heal up drops it. The Moonfire pull stops at 20 because it fired when a cat only wanted to shift. |
| Fight Bear re-roared and wasted presses | `castsequence reset=target Demoralizing Roar, Maul, Maul, Maul` | Fight Bear 10-60: out of combat Faerie Fire (18) + Enrage (12) pull; in combat Maul, then `[combat] Enrage` rider | The sequence recast Roar (10 Rage) every 4 presses although it lasts 30 sec, and Maul (off GCD, next swing) used a whole press as a step. Enrage and Faerie Fire had no button. |
| Fight Cat could not pull or retarget | `castsequence reset=target Claw x3, Rip` / `Rake, Claw x3, Ferocious Bite` | same sequences + `/targetenemy`, `reset=target/combat`, `[nocombat,nostealth] Faerie Fire` pull, `/startattack [nostealth]` | Faerie Fire works in Cat Form in Forever. Plain `/startattack` armed auto-attack while prowling, and the first white swing broke Prowl before Ravage. |
| Pack Bear restarted on every kill | `castsequence reset=target Demoralizing Roar, Swipe, Maul, Swipe` | `reset=combat Demoralizing Roar, Swipe x5` + Maul rider + `/targetenemy` | On a pack the target changes as mobs die, so `reset=target` roared again every kill; Maul as a step wasted a press. |
| Heal up slow in combat | Healing Touch always | 1-11 unchanged; 12-60 `[@player,combat] Regrowth; [@player] Healing Touch` | A 3.5 sec Healing Touch gets pushed back while you are hit; Regrowth is quicker and leaves a heal over time. |
| Missing buttons | none | Prowl Cat 20-60 (Prowl, then Shred / Ravage from behind; in combat Shred, Shifting Power from 46); Panic Bear 36-60 (Frenzied Regeneration + Enrage); Buffs 6-60 (Thorns, press again for MotW, self or friend) | Prowl/Ravage, Shifting Power (the path's only talent spell), Frenzied Regeneration and the constant Thorns rebuff had no button. |

Old bodies for `OLD_MACRO_BODIES.DRUID` (so existing macros update in place):
- `Fight`: `#showtooltip\n/startattack\n/castsequence reset=target Wrath, Moonfire, Wrath`
- `Fight Bear`: `#showtooltip\n/startattack\n/castsequence reset=target Demoralizing Roar, Maul, Maul, Maul`
- `Fight Cat`: `#showtooltip\n/startattack\n/castsequence reset=target Claw, Claw, Claw, Rip` and `#showtooltip\n/startattack\n/castsequence reset=target Rake, Claw, Claw, Claw, Ferocious Bite`
- `Pack Bear`: `#showtooltip\n/startattack\n/castsequence reset=target Demoralizing Roar, Swipe, Maul, Swipe`
- `Heal up` 1-11 keeps the old body exactly.

Rejected on purpose: an "Enrage + Demoralizing Roar" rage button (Enrage's Rage reaches the client after the press, so the Roar fails at 0 Rage and the next press is blocked by Enrage's cooldown); Feral Charge + Bash on one key (each one's range failure stops the other); Primal Bite in front of Maul (its 6 sec cooldown would block Maul).

### 2. Path sets

Shared by every set: `Fight` RT+A / 1 (caster bar), `Heal up` LT+A / Q, `Buffs` LT+Up / G. Bear bar: `Fight Bear` RT+A, `Pack Bear` RT+B, `Taunt Bear` RT+X, `Bash Bear` RT+Y, `Panic Bear` LT+X (keys 1-4 and F "in Bear Form"). Cat bar: `Fight Cat` RT+A, `Prowl Cat` RT+B (keys 1-2 "in Cat Form").

#### guide (Feral, Melee damage): 8 macros at 60
| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9 | RT+A / 1 | target + auto-attack + Wrath; then Wrath, Moonfire, Wrath loop | caster start |
| Fight | 10-19 | RT+A / 1 | targeted, out of combat: Moonfire; else Bear Form (Wrath before the quest) | "Moonfire to pull, then shift" |
| Fight | 20-60 | RT+A / 1 | dismount + Cat Form (Bear before the Cat quest) | back into Cat after Heal up |
| Heal up | 1-11, 12-60 | LT+A / Q | drop form; Regrowth in combat (12+), Healing Touch out | self heal from any form |
| Buffs | 6-60 | LT+Up / G | Thorns, again within 60 s: MotW (hover, friend, else you) | Thorns needs a refresh every 10 min |
| Fight Bear | 10-60 | RT+A (Bear) | pull: Faerie Fire + Enrage; fight: Maul, Enrage rider | Rage-starved bear leveling |
| Pack Bear | 16-60 | RT+B (Bear) | Roar, then Swipe x5 loop (reset on combat end), Maul rider | packs |
| Panic Bear | 36-60 | LT+X (Bear) | Frenzied Regeneration + Enrage | Enrage's Rage feeds the heal |
| Fight Cat | 20-23, 24-60 | RT+A (Cat) | pull: Faerie Fire; fight: Claw x3, Rip / Rake, Claw x3, Ferocious Bite | one-button cat |
| Prowl Cat | 20-31, 32-45, 46-60 | RT+B (Cat) | Prowl; prowled: Shred (Ravage from 32); combat: Shred (Shifting Power from 46) | opener + the guide's Shifting Power |

#### cat (Feral Cat, Melee damage): 8 macros at 60
Same as the guide set except: Prowl Cat bands 20-31, 32-50, 51-60 (Shifting Power at 51); Pack Bear 52-60 adds Primal Bite (`Roar, Swipe x3, Primal Bite, Swipe x2`), because Primal Bite only works in Bear Form; Heal up's Furor tip says 53/57; Rend and Tear tip says 45.

#### bear (Feral Bear, Tank): 8 macros at 60
| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9, 10-19 | RT+A / 1 | as the guide | |
| Fight | 20-60 | RT+A / 1 | dismount + Dire Bear Form (40) / Bear Form | back into Bear after Heal up |
| Heal up, Buffs | as guide | LT+A / Q, LT+Up / G | as guide (Furor tip: 10 Rage from 51, always at 55) | |
| Fight Bear | 10-24 | RT+A (Bear) | as the guide | solo bear |
| Fight Bear | 25-39 | RT+A (Bear) | pull: Faerie Fire, Enrage, Feral Charge (26); fight: Lacerate + Maul rider | threat; no automatic Enrage in combat (armor loss while tanking) |
| Fight Bear | 40-60 | RT+A (Bear) | same pull; fight: `Lacerate, Lacerate, Primal Bite` + Maul | Primal Bite every third GCD |
| Pack Bear | 16-39, 40-60 | RT+B (Bear) | Roar + Swipe x5; from 40 with Primal Bite on the main target | AoE threat |
| Taunt Bear | 10-60 | RT+X (Bear) | Growl on hover / enemy target / enemy hitting your friendly target; Lacerate on it (25) | take a mob off the healer on a controller |
| Bash Bear | 14-60 | RT+Y (Bear) | Bash on hover, else target | mouseover interrupt; Brutal Impact 30 s cd at 19 |
| Panic Bear | 36-60 | LT+X (Bear) | Frenzied Regeneration + Enrage | |

#### balance (Balance, Caster damage): 7 macros at 60
| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9 | RT+A / 1 | as the guide | |
| Fight | 10-19 | RT+A / 1 | `Wrath, Moonfire, Wrath x3` | Moonfire returns about when it runs out |
| Fight | 20-24 / 25-29 | RT+A / 1 | Starfire opener, Moonfire (+Insect Swarm at 25), Wrath x3 | Starfire from range, Wrath in melee |
| Fight | 30-39 | RT+A / 1 | `Starfire, Moonfire, Insect Swarm, Wrath, Starfire, Starfire` | Eclipse: Wrath right before 2 Starfires |
| Fight | 40-60 | RT+A / 1 | `[noform] Moonkin Form`, else the same loop | back into Moonkin after a heal |
| DoTs | 10-24, 25-60 | RT+B / 2 | Moonfire (then Insect Swarm) on hover, else target | multi-DoT without changing target |
| Pack | 40-60 | RT+X / 3 | `[nochanneling] Hurricane` | spam-safe channel |
| Root | 8-60 | RT+Y / 4 | drop form, Entangling Roots on hover, else target | Roots is caster-only per the game data |
| Heal up | 1-11, 12-60 | LT+A / Q | as guide (drops Moonkin too) | |
| Buffs | 6-60 | LT+Up / G | as guide, without `/cancelform` (works in Moonkin) | |
| Res | 12-60 | LT+Down / T | dead friend: Rebirth in combat, Revive out of it | keeps the 30 min cd for fights |

#### resto (Restoration, Healer): 10 macros at 44+
Heal chain = `[@mouseover,help,nodead][help,nodead][@targettarget,help,nodead][@player]`, each with `/cancelform`.
| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-19 | RT+A / 1 | as the guide (4-9 body kept to 19) | solo damage |
| Fight | 20-60 | RT+A / 1 | `Starfire, Moonfire, Wrath, Wrath`, auto-attack on | solo damage, melee to save mana |
| Heal up | 1-60 | LT+A / Q | Healing Touch on the chain | main heal |
| HoT | 4-60 | LT+B / E | Rejuvenation on the chain | |
| Quick heal | 12-60 | LT+Y / R | Regrowth on the chain | |
| Swiftmend | 34-60 | LT+Right / Z | Swiftmend on the chain | own button: 15 s cd would block others |
| Panic heal | 35-60 | LT+X / F | Nature's Swiftness, then Healing Touch on the chain | burst design: blocked while NS cools |
| Wild Growth | 44-60 | LT+Left / C | Wild Growth on the chain | group heal, 6 s cd |
| Cleanse | 14-25, 26-60 | RT+Y / 4 | Cure Poison, then Abolish Poison on the chain | poisons are the common dungeon debuff; curses from the spellbook |
| Buffs, Res | 6-60, 12-60 | LT+Up / G, LT+Down / T | as balance, with `/cancelform` | |

Warnings kept on purpose (each tip says so): Panic Bear (Frenzied Regeneration's 3 min cooldown stops the Enrage rider; it is the main spell); Panic heal (Nature's Swiftness first is the burst design); Primal Bite inside castsequences (bear Fight Bear 40-60, bear Pack Bear 40-60, cat Pack Bear 52-60: in Pack Bear it comes once per 7 steps, so it never waits; in Fight Bear it can wait up to about 1.5 sec when Rage is plentiful).

### 3. Data.lua text that now reads wrong (from `packet DRUID`)

- Trainer L18 Faerie Fire: "Armor down for 40 sec. Caster form only — pull with it, then shift." -> "Armor down for 40 sec. Works in Cat and Bear Form too: Fight Cat and Fight Bear pull with it." (game fact: ShapeshiftMask includes Cat, Bear, Dire Bear, Moonkin)
- Trainer L12 Enrage: "Rage to open in Bear." -> "Rage to open in Bear: Fight Bear casts it on the pull, and in combat when it is ready."
- Trainer L10 Demoralizing Roar: "Bear: less damage taken." -> "Bear: less damage taken. Pack Bear (16) opens every fight with it."
- Trainer L20 Prowl: "Stealth." -> "Stealth. Prowl Cat: press to prowl, press again from behind to open."
- Trainer L36 Pounce: "Stun opener from Prowl." -> "Stun opener from Prowl; like Ravage it needs you behind the target." (game fact)
- Trainer L36 Frenzied Regeneration: "Bear self-heal." -> "Bear self-heal. Panic Bear casts it with Enrage."
- Tips 10-19, step: "Moonfire to pull, then shift to Bear." -> "Moonfire to pull, then shift to Bear: Fight on the caster bar does both."
- Tips 10-19, step: "Demoralizing Roar → Maul each press." -> "Fight Bear: Maul each press, Enrage on the pull (12) and Faerie Fire to pull (18). Pack Bear opens with Demoralizing Roar."
- Tips 20-29, step: "Mark of the Wild and Thorns up, then Cat Form. Omen of Clarity is passive." -> "Buffs (LT+Up): Thorns, press again for Mark of the Wild; then Cat Form (RT+A). Omen of Clarity is passive."
- Tips 30-39, step: "Prowl → get behind → Ravage (32) → Fight macro." -> "Prowl Cat: Prowl, get behind, press again for Ravage (32), then Fight Cat."
- Tips 40-60, step: "Shifting Power when Energy runs dry." -> "Shifting Power (46) when Energy runs low: Prowl Cat casts it in combat."
- Tips 40-60, step: "Barkskin (44) when a fight goes wrong; Dire Bear (40) for packs." -> "Barkskin (44) or Panic Bear (36) when a fight goes wrong; Dire Bear (40) for packs."
- Talent Shifting Power `why`: "...8 sec cooldown — your Energy refill." -> "...8 sec cooldown: your Energy refill, on Prowl Cat in combat."

Outside Data.lua (TalentPaths.lua, cat path): Primal Bite `why` "A strong extra attack, and a finisher for the end of a fight." is wrong: the game lists it as Bear / Dire Bear Form only. Suggest: "A Bear Form bite for 100% normal damage plus 42 and lots of threat, 6 sec cooldown: for the fights you take in bear (Pack Bear uses it)."

### 4. Check in game

1. **Rage on the same press:** Fight Bear's pull casts Enrage then Feral Charge (bear path 26+). Does the Charge fire, or does the client still see 0 Rage until the next press (the tips assume it doesn't)?
2. **Prowl bar:** does Prowl switch to a separate action bar? If so, Prowl Cat and Fight Cat must go there too (tips say so).
3. **Moonkin bar:** does Moonkin Form switch bars?
4. **Entangling Roots in Moonkin Form:** the data says caster only; if it works in Moonkin, drop `/cancelform` from Balance's Root.
5. **Faerie Fire from Cat and Bear:** casts, costs mana, pulls from 30 yd.
6. `/startattack [nostealth]` is accepted; walking in prowled with Fight Cat pressed doesn't break Prowl.
7. `!Cat Form` / `!Dire Bear Form` never toggle out; `/dismount` + shift in one press; whether `Bear Form` still exists after Dire Bear Form (the bear Fight casts either).
8. **Maul already queued:** does a second Fight Bear press still reach the `[combat] Enrage` rider?
9. Heal up: `[@player,combat] Regrowth; [@player] Healing Touch` picks Regrowth in combat; `/cancelform` + heal in one press from Cat, Bear, Moonkin, Travel.
10. Buffs: `/castsequence [targets] reset=60 Thorns, Mark of the Wild` puts both on the same unit; DoTs `reset=8/target` parses.
11. Swiftmend: does it consume the Rejuvenation/Regrowth (the Forever tooltip doesn't say)?
12. Panic heal: Nature's Swiftness + Healing Touch in one press is instant; pressing mid-cast does nothing.
13. Hurricane `[nochanneling]` with controller ground targeting (A confirms).
14. Fight Cat castsequence waits on "Not enough energy" and continues from that step.
15. Primal Bite inside Pack Bear hits the current target.

### 5. Sources

- Game data: `python tools/gamedata.py facts|spells|tree|packet DRUID`; raw tables in `tools/.cache/1.60.1.70888` (SpellShapeshift, SpellCooldowns, SpellMisc, SpellEffect).
- https://rankedboost.com/world-of-warcraft/forever/macros/druid/
- https://rankedboost.com/world-of-warcraft/forever/macros/druid/feral-combat/
- https://rankedboost.com/world-of-warcraft/forever/macros/druid/balance/
- https://rankedboost.com/world-of-warcraft/forever/macros/druid/restoration/
- https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md
- https://kami-labs.fr/en/macros-wow-forever/?classe=druid
- https://www.warcrafttavern.com/forever/guides/druid-leveling/
- https://wowtbc.gg/warcraftforever/class-guides/feral-dps-druid/
- Not readable (HTTP 403): Icy Veins Forever feral pages, Mobalytics Forever balance guide.


## Hunter: guide (Marksmanship), Beast Mastery, Survival

Facts from `python tools/gamedata.py facts HUNTER` (build 1.60.1.70888). Off the GCD: Auto Shot, Raptor Strike
(next swing), Rapid Fire, Bestial Wrath, Feign Death, Deterrence, Feed Pet. On it: Hunter's Mark, the Stings, Arcane
Shot, Aimed Shot, Multi-Shot, Sniper Shot, Summon Hawk, Intimidation, Wing Clip, Mongoose Bite, Strider Kick, Lacerate.
Shared cooldowns: Aimed Shot + Multi-Shot (6 sec), Arcane Shot + Summon Hawk (6 sec), all traps (30 sec).
Range data (SpellMisc RangeIndex): Lacerate, Strider Kick, Mongoose Bite, Counterattack are melee (index 2).

`python tools/gamedata.py macros HUNTER`: **0 errors, 10 warnings**,
all "castsequence step X has a cooldown: the sequence waits on it" on sequences whose cooldown step is the last one,
repeated on purpose, and the tips say what "not ready" means (details under each set).

### 1. Guide set (Marksmanship) findings

| Problem | Old | New | Why |
| --- | --- | --- | --- |
| Hunter's Mark inside the `reset=target` sequence | Fight 6-19, 20-60: `Hunter's Mark, Serpent Sting, Arcane x3` / `Mark, Serpent, Aimed, Arcane, Aimed, Arcane` | Mark only out of combat (`[nocombat,harm,nodead]`), the sequence starts at Serpent Sting and only runs in combat | On every long fight the sequence wrapped round to Mark again: a wasted GCD and mana on an already-marked mob. |
| Aimed Shot and Arcane Shot in one sequence | Fight 20-60 alternated them | Fight keeps Arcane Shot; Aimed gets its own button **Aimed** (RT+X / 4, 20-60) | Whichever step was next blocked the other while it cooled. Pack's Multi-Shot shares Aimed's cooldown, so after a Pack press Fight sat for 6 sec on Aimed while Arcane was ready. |
| The pull shot before the pet | `/cast !Auto Shot` on every press, so the first press pulled; the 10-19 tip said send the pet and count 2 sec | 10-60: `/cast [combat][nopet] !Auto Shot`: with a pet out of combat the first press marks and sends the pet only; the next press (in combat) shoots | The tip's advice is now built in; without a pet it still shoots at once. |
| No retarget, unconditional `/petattack` | | `/targetenemy [noharm][dead]`, `/petattack [harm,nodead]` | Owner rule: melee and ranged Fight buttons pick the next enemy after a kill. |
| Nothing before 6 | Fight started at 6 | Fight 1-3 (retarget + Auto Shot), 4-5 (+ `[nocombat]` Serpent Sting pull), 6-9 (no pet yet) | Levels 1-5 had no Fight button at all. |
| Too close waited on Raptor Strike | 12-60 `castsequence reset=8/target Wing Clip, Raptor Strike` | 1-60 `/cast Wing Clip` then `/cast Raptor Strike` | Raptor Strike is off the GCD (next swing), so both go out on one press; the sequence made Raptor a second press and stalled on its 6 sec cooldown. Before 12 Wing Clip is skipped, so it is the Raptor Strike button the 1-9 tips ask for. |
| Rapid Fire had no button | | Pack 18-60: `/cast [combat] Rapid Fire` after Multi-Shot (from 26) | Off the GCD, so it rides after Multi-Shot; while it cools the macro stops after Multi-Shot and nothing is lost. |
| No Feign Death button | | **Feign** (LT+X / F, 30-60): `/stopcasting`, Feign Death | `/stopcasting` lets it cut an Aimed Shot, Sniper Shot or Volley cast; the guide calls Feign Death the hunter's reset. |
| Sniper opener | body fine | `[harm,nodead]` added; tips: Fight's pull no longer shoots, so the Sniper cast really is the first hit | |
| Pet care, Pet back, Feed pet | | bodies unchanged (Pet back gets a second tip) | The audit's "Mend Pet learned at 12" is the last clause of Pet care: at 10-11 a live pet just gets nothing. |

Old bodies that must go into `ns.OLD_MACRO_BODIES.HUNTER` (so in-place updates find them): Fight 6-19, Fight 20-60,
Sniper opener, Pack and Too close as they are in Data.lua today.

### 2. Path sets

#### guide (Marksmanship): 9 names, 12 versions, at most 9 active (40+)

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3 | RT+A / 1 | retarget, Auto Shot | |
| Fight | 4-5 | RT+A / 1 | + out of combat Serpent Sting (the pull) | |
| Fight | 6-9 | RT+A / 1 | out of combat: Mark + Auto Shot; in combat: `Serpent Sting, Arcane Shot x3` | Arcane is the only cooldown step and comes last, repeated: waiting on it is the same wait as any Arcane button. Sting comes back about every 20 sec. |
| Fight | 10-60 | RT+A / 1 | + pet attack; with a pet, out of combat only Mark (pet first) | |
| Aimed | 20-60 | RT+X / 4 | pet, Auto Shot, Aimed Shot | shares the 6 sec cooldown with Multi-Shot |
| Pack | 18-60 | RT+B / 2 | pet, Auto Shot, Multi-Shot, Rapid Fire rider (26+, in combat) | |
| Sniper opener | 40-60 | RT+Right / 3 | pet, Sniper Shot | 15 sec cooldown: own button |
| Too close | 1-60 | LT+Y / Q | start attack, Wing Clip, Raptor Strike rider | |
| Feign | 30-60 | LT+X / F | stop casting, Feign Death | |
| Pet care | 10-60 | LT+A / E | Revive / Call / Mend Pet | unchanged |
| Pet back | 10-60 | LT+B / R | pet follow | unchanged |
| Feed pet | 10-60 | LT+Down / Shift+4 | Feed Pet + food | unchanged |

#### bm (Beast Mastery): 10 names, 14 versions, at most 10 active (40+)

Talent spells: Summon Hawk 25, Intimidation 31, Bestial Wrath 40 (all used from those levels).

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-24 | RT+A / 1 | the guide's four versions | |
| Fight | 25-60 | RT+A / 1 | as 10-60, sequence `Serpent Sting, Summon Hawk, Arcane Shot, Summon Hawk, Arcane Shot` | Hawk and Arcane share one cooldown, so taking turns never waits longer than either shot would; at most 2 hawks out (the game's limit); Sting about every 25 sec. |
| Aimed | 20-60 | RT+X / 4 | as guide | |
| Pack | 18-60 | RT+B / 2 | as guide | |
| Pet stun | 31-60 | RT+Right / 3 | pet attack, Intimidation | 1 min cooldown, on the GCD: can't ride anything; good as the pull |
| Burst | 40-60 | RT+Y / 5 | pet attack, Bestial Wrath, Rapid Fire | both off the GCD; BW first (2 min) so a cooling Rapid Fire never blocks it; uses no GCD, so Fight or Pet stun follows at once |
| Too close, Feign, Pet care, Pet back, Feed pet | | | as guide | |

#### survival: 10 names, 16 versions, at most 10 active (30+)

Talent spells: Strider Kick 35, Deterrence 43, Counterattack 44 (no Wyvern Sting in Forever's tree). Expose Prey (36-37)
lights Mongoose Bite from hits on a Marked target; Lacerating Strikes (45) adds a bleed to it; Improved Wing Clip
(40-42) can root; Clever Traps (28-29), Survivalist's Discipline (38-39: traps 18 sec), Resourcefulness (46).

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight, Aimed, Pack | | | as guide | the ranged half |
| Too close | 1-29 | LT+Y / Q | as guide | |
| Too close | 30-34 | LT+Y / Q | `reset=10/target Wing Clip, Lacerate, Raptor Strike x3` + Raptor rider | The melee half. Lacerate (21 sec) comes back about every 18 sec; Raptor every 6 sec (the cooldown steps are last on purpose). reset=10 keeps a kiting press = Wing Clip. |
| Too close | 35-60 | LT+Y / Q | `reset=10/target Wing Clip, Lacerate, Strider Kick x3` + Raptor rider | Strider Kick (extra 100% weapon hit, 8 sec) is the step it waits on, on purpose; the wrap-around renews Wing Clip and Lacerate about when they run out. |
| Bite | 16-60 | RT+Right / 3 | start attack, Mongoose Bite, Raptor rider | lit only after a dodge (or Expose Prey): a lit-only spell must be the first that can fail, so it has its own button |
| Trap | 20-33 | RT+Y / 5 | `[combat] Freezing Trap; Immolation Trap` | out of combat a fire trap to pull onto (the guide's own advice), in combat a freeze for an add |
| Trap | 34-60 | RT+Y / 5 | `[combat] Freezing Trap; Explosive Trap` | |
| Feign, Pet care, Pet back, Feed pet | | | as guide | |

Not in a macro (tips say why): Counterattack (lit only after a parry, and a macro stops at an unlit spell, so it can't
share Bite) and Deterrence (5 min, 3 min with Survivalist's Discipline: a rider before Counterattack would block it).

### 3. Data.lua text that now reads wrong (HUNTER)

Tip chapters (`br`):

| Chapter | Old | New |
| --- | --- | --- |
| 1-9 | "Serpent Sting (4), then Arcane Shot (6). Hunter's Mark (6) before you pull." | "Fight (RT+A) pulls with Serpent Sting (4); from 6 it marks and shoots, then Serpent Sting and Arcane Shot." |
| 1-9 | "When it reaches you: Raptor Strike and melee it down." | "When it reaches you: Too close (LT+Y) for Raptor Strike, and melee it down." |
| 10-19 | "Send the pet first (pet bar Attack), count 2 seconds, then press Fight." | "Press Fight: it marks the target and sends your pet without a shot. Press it again once the pet is fighting." |
| 10-19 | "Hunter's Mark → Serpent Sting → Arcane Shot, with Auto Shot running between." | "Then Fight goes Serpent Sting and three Arcane Shots, with Auto Shot running between." |
| 10-19 | "Mob on you? Wing Clip (12), step back past 8 yards, keep shooting." | "Mob on you? Too close (LT+Y): Wing Clip (12) and Raptor Strike, then step back past 8 yards and press Fight." |
| 20-29 | "Mark → Serpent → Aimed Shot → Arcane Shot." | "Fight for Mark, Serpent and Arcane; press Aimed (RT+X) whenever it is ready." |
| 20-29 | "Rapid Fire (26) on tough mobs; Rapid Killing (20–21) brings it back faster." | "Rapid Fire (26): Pack fires it in combat; on a tough single mob press it yourself. Rapid Killing (20–21) brings it back faster." |
| 30-39 | "Too much on you: Feign Death, let the pet tank or die, stand up and shoot." | "Too much on you: Feign (LT+X), even mid-cast; let the pet tank or die, stand up and shoot." |
| 40-60 | "Fight once (Mark, pet in) → Sniper opener from max range → keep pressing Fight (Serpent → Aimed → Arcane)." | "Fight once (Mark, pet in) → Sniper opener from max range → then Fight (Serpent, Arcane) and Aimed when it is ready." |

Unchanged and still right: trainer L1 Auto Shot "The Fight macro keeps it running.", the Sniper Shot talent's "Use it as
your opener button.", 30-39 "Pet died? ... the Pet care button does it."

### 4. To check in game

1. **`/cast !Auto Shot` while Auto Shot is already on**: does Forever go on to the next line? Fight, Aimed and Pack all
   rely on it (the old bodies did too). If it stops the macro, Auto Shot has to move to the last line.
2. **Pet-first pull (10+)**: with the pet out, Fight out of combat = Mark + pet, no shot. Does the hunter count as in
   combat once the pet fights, so the next press shoots? If not, the next press marks again until the mob hits you.
   Also check that Hunter's Mark itself doesn't pull.
3. `[nopet]` with a dead pet: true, so Fight shoots at once?
4. BM 25+: Hawk / Arcane taking turns; does a hawk keep attacking after its target dies?
5. Pack: Rapid Fire on the same press as Multi-Shot. Too close: Wing Clip and Raptor Strike on one press.
6. Survival Too close 30+: Raptor Strike (off the GCD) as castsequence steps; `reset=10/target` back to Wing Clip.
7. Bite: Expose Prey procs light Mongoose Bite (also from Auto Shot hits?).
8. Trap: facts mark Immolation and Explosive Trap off the GCD but Freezing and Frost Trap on it.
9. Sniper Shot's 45 yards (range index 582 is not in our tables; the number comes from Data.lua).
10. Feign: `/stopcasting` cuts an Aimed Shot / Volley and Feign Death fires on the same press.
11. Black Arrow (50, 60) is in the class spell list with no cost, cooldown or trainer: left out of every macro.

### 5. Sources

- https://rankedboost.com/world-of-warcraft/forever/macros/hunter/beast-mastery/ (Bestial Wrath + Rapid Fire,
  Intimidation + pet attack, Summon Hawk on Arcane's cooldown)
- https://rankedboost.com/world-of-warcraft/forever/macros/hunter/marksmanship/ (Mark out of combat / Sting in combat;
  their Rapid Fire before Aimed Shot would block Aimed for the whole cooldown under Forever's rule, not used)
- https://rankedboost.com/world-of-warcraft/forever/macros/hunter/survival/ (Strider Kick, Counterattack, traps by combat state)
- https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (pet-state button, spam-safe
  `!Auto Shot`, Feign Death, Mongoose and Strider Kick on their own buttons)
- Game data: `tools/gamedata.py facts|spells|packet HUNTER`, `tools/.cache/1.60.1.70888/SpellMisc.csv` (range index).


## Mage: guide (Frost), Arcane, Fire

`python tools/gamedata.py macros MAGE`: **0 errors, 6 warnings**, all intended and explained in the tips (listed at the end of section 1).

Game facts used (build 1.60.1.70888, `facts MAGE` + `SpellMisc.CastingTimeIndex`): Ice Lance and Fire Blast share one 8 sec cooldown and are both instant; Arcane Blast casts in 1.5 sec (index 16), Arcane Wrath in 3.5 sec (index 22, 6 sec cooldown); Pyroblast index 171 (= Soul Fire's, 6 sec); Presence of Mind, Arcane Power, Combustion, Cold Snap and Counterspell are off the GCD; Presence of Mind shares its cooldown with Combustion (the Arcane path never takes Combustion, the Fire path never takes PoM). Talent spells per path: Frost Ice Lance 20, Ice Block 29, Cold Snap 34, Ice Barrier 40; Arcane Arcane Blast 20, Arcane Wrath 25, PoM 30, Arcane Power 40; Fire Pyroblast 20, Blast Wave 33, Combustion 40.

### 1. Guide set findings (old -> new)

| Old | Problem | New |
| --- | --- | --- |
| Nuke 1-60 | Fine, but no re-target after a kill. | Same casts plus `/targetenemy [noharm][dead]`. |
| Finisher Shatter 6-60: `/cast Ice Lance` + `/cast Fire Blast` | From 20 the Fire Blast line can never fire (shared cooldown), so Frost lost its finisher on a target that isn't frozen. Ice Lance does 36 there at 28-30, Fire Blast 163 at 30. Warcraft Tavern's Forever guide also says Fire Blast instead of Ice Lance when the target isn't frozen. | Two versions: 6-19 Fire Blast, 20-60 Ice Lance (Shatter), both with `/stopcasting` so they fire mid-cast. |
| (none) | Fire Blast had no home from 20. | **Fire Blast** 20-60, RT+Y / 4: `/stopcasting`, Fire Blast. |
| Get away 20-60: `/castsequence reset=combat Frost Nova, Blink` | Waits on Nova (25 sec) at the start of every fight, exactly when you need Blink. | Get away 10-60: `/stopcasting`, Frost Nova. **Blink** 20-60 gets its own button (LT+Y / F) with `/stopcasting`. |
| Pack 26-60: Nova, Cone, Explosion x3 | Waits on Nova (25 sec) and, on the loop, on Cone of Cold (10 sec). | `reset=combat Cone of Cold, Arcane Explosion x6`: six Explosions plus the Cone's GCD take 10.5 sec, so the Cone is back when the loop returns. Nova stays on Get away. |
| Shield up 20-60: `/cast Ice Barrier` + `/cast Mana Shield` | From 40, Mana Shield never fires while Barrier cools. | 20-39 `/stopcasting`, Mana Shield. 40-60 `/castsequence reset=30 Ice Barrier, Mana Shield`: Barrier, then Mana Shield while it cools. |
| Mana gem 28-60: four `/use` lines | Works, but a gem used in combat had to be conjured from the spellbook. | Four versions (Agate 28, Jade 38, Citrine 48, Ruby 58): `/use [combat]` the current and previous gem, `/cast [nocombat] Conjure` the current one. |
| Armor 1-60 | Two plain lines; Arcane Intellect had no button. | 1-29 / 30-60 `/castsequence [@player] reset=30 <armor>, Arcane Intellect`: one press armor, two presses both buffs. |
| (none) | No wand button, though the tips tell you to wand. | **Wand** 1-60, RT+Up / 5: re-target, `/cast [nochanneling:Shoot] Shoot`. |
| (none) | No interrupt button. | **Counterspell** 24-60, RT+Right / 6: `/stopcasting`, mouseover else target. |
| (none) | Ice Block (29) had no button. | **Ice Block** 29-60, RT+Left / T: toggle (`/cancelaura` then cast), so a second press leaves the block. |

Warnings kept on purpose (each is in that macro's tips): Pack's Cone step (no wait when mashed), Shield up's Barrier step (waits only on a third press inside 30 sec), Arcane Nuke's Wrath step (no wait except right after Burst), Fire Finisher's Fire Blast before the Combustion rider (Combustion just waits for the next Fire Blast).

Macros active at once: Frost 12 (from 29), Arcane 12 (from 30), Fire 12 (from 33). Under the 18 slots.

### 2. Path sets

Shared by all three paths with identical bodies (so a path switch leaves them alone): Get away, Blink, Counterspell, Wand, Mana gem, Armor, Pack. Shield up is Mana Shield on Arcane and Fire at every level.

#### Guide (Frost)

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Nuke | 1-60 | RT+A / 1 | Re-target if needed, Frostbolt (Fireball before 4) | Main nuke, picks the next mob after a kill |
| Finisher Shatter | 6-19 | RT+B / 2 | Stop cast, Fire Blast | Instant finisher |
| Finisher Shatter | 20-60 | RT+B / 2 | Stop cast, Ice Lance | Shatter after Nova, Frostbite or Fingers of Frost |
| Fire Blast | 20-60 | RT+Y / 4 | Stop cast, Fire Blast | The bigger instant when the target isn't frozen (shared cd) |
| Pack | 26-60 | RT+X / 3 | Cone of Cold, then Arcane Explosion x6 | AoE that never waits when mashed |
| Get away | 10-60 | LT+A / Q | Stop cast, Frost Nova | Freeze and walk off |
| Blink | 20-60 | LT+Y / F | Stop cast, Blink | Escape, out of stuns and roots |
| Shield up | 20-39 | LT+B / E | Stop cast, Mana Shield | Emergency absorb |
| Shield up | 40-60 | LT+B / E | Ice Barrier; next press Mana Shield | Barrier always first, Mana Shield while it cools |
| Ice Block | 29-60 | RT+Left / T | Stop cast, Ice Block; again = leave it | Bad pulls |
| Counterspell | 24-60 | RT+Right / 6 | Stop cast, Counterspell (mouseover, else target) | Interrupt at once |
| Wand | 1-60 | RT+Up / 5 | Re-target, wand without toggling it off | Mana-free finishing |
| Mana gem | 28-60 (4 bands) | LT+X / R | In combat use the gem, out of combat conjure it | Never forget to remake it |
| Armor | 1-29, 30-60 | LT+Up / Shift+1 | Armor; second press Arcane Intellect | Both buffs on one button |

#### Arcane

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Nuke | 1-19 | RT+A / 1 | Guide body (Frostbolt) | Before Arcane Blast; Frostbolt can proc Missile Barrage (15+) |
| Nuke | 20-24 | RT+A / 1 | Arcane Blast, Arcane Blast, Arcane Missiles (sequence) | Two Blasts give a 64% chance at a free, fast Missiles |
| Nuke | 25-60 | RT+A / 1 | Blast x3, Arcane Wrath, Arcane Missiles | Wrath at three stacks (Warcraft Tavern's advice); its 6 sec cd is over when the loop returns |
| Finisher Shatter | 6-60 | RT+B / 2 | Stop cast, Fire Blast | Finisher, and a hit while Wrath cools |
| Missiles | 8-60 | RT+Y / 4 | Arcane Missiles, spam-safe | Spend Barrage procs outside the Nuke loop |
| Burst | 30-39 | RT+Left / T | Presence of Mind, instant Arcane Wrath | PoM before the hard cast, on its own button so it never blocks Nuke |
| Burst | 40-60 | RT+Left / T | PoM, Arcane Power, instant Arcane Wrath | PoM first: consumed in the same press, so both cooldowns stay in step and the button never locks |
| Pack, Get away, Blink, Counterspell, Wand, Mana gem, Armor | as guide | as guide | as guide | shared |
| Shield up | 20-60 | LT+B / E | Stop cast, Mana Shield | Arcane's mana pool is its shield (no Ice Barrier) |

#### Fire

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Nuke | 1-9 | RT+A / 1 | Guide body (Frostbolt) | No talents yet; the slow keeps you safe |
| Nuke | 10-19 | RT+A / 1 | Re-target, Fireball | Accelerant and Ignite start at 10 |
| Nuke | 20-60 | RT+A / 1 | Out of combat Pyroblast, in combat Fireball | One button pulls with Pyroblast and fights with Fireball |
| Finisher Shatter | 6-39 | RT+B / 2 | Stop cast, Fire Blast | Instant, a Heating Up stack builder from 26 |
| Finisher Shatter | 40-60 | RT+B / 2 | Stop cast, Fire Blast, then Combustion if ready | Combustion rides after an instant; it lasts until 3 crits, so it's never wasted, and while it cools nothing is lost |
| Pyroblast | 20-60 | RT+Y / 4 | Re-target, Pyroblast | Spend 3 Heating Up stacks mid-fight |
| Blast Wave | 33-60 | RT+Left / T | Stop cast, Blast Wave | AoE and 50% slow when a pack reaches you |
| Pack, Get away, Blink, Counterspell, Wand, Mana gem, Armor | as guide | as guide | as guide | shared |
| Shield up | 20-60 | LT+B / E | Stop cast, Mana Shield | No Ice Barrier on this path |

Not used, on purpose: Frostfire Bolt (40) loses to Fireball and Frostbolt for every path (292 + 57 at 60 against Fireball 483 + 60); Felfire (60, 500 damage for 100 mana, no trainer lists it) is unexplained, see section 4; Blizzard and Flamestrike need a ground spot, so they stay in the spellbook; Scorch stacking (Improved Scorch) is for long fights; Polymorph and Evocation are spellbook buttons.

### 3. Data.lua text outside the macros

| Where | Old | New |
| --- | --- | --- |
| Trainer L14, Fire Blast (Rank 2) note | "Instant finisher until Ice Lance." | "Instant finisher. From 20 it has its own button (RT+Y) next to Ice Lance." |
| Tips 20-29 | "Nova on cooldown and a mob on you: Blink away." | "Nova on cooldown and a mob on you: Blink away (LT+Y)." |
| Tips 20-29 | "Bad pull: Ice Block (29), then Blink away when it ends." | "Bad pull: Ice Block (29, RT+Left; press again to leave it early), then Blink away." |
| Tips 30-39 | "Packs: Nova, Cone of Cold, Arcane Explosion." | "Packs: Get away (Frost Nova), then Pack: Cone of Cold and Arcane Explosions." |
| Tips 1-9 (optional) | "Finish low targets with your wand (Shoot) to save mana." | "Finish low targets with your wand (Wand, RT+Up) to save mana." |

The five "Lance if frozen, else Fire Blast" trainer notes (L22, 30, 38, 46, 54) are now exactly what the two buttons do; no change needed. The old macro tips inside Data.lua are replaced with the set.

### 4. Check in game

- `/use [combat] Mana Jade` with no Jade in the bags: the line is skipped and the next one runs (the old Mana gem and the Healthstone macros relied on this too).
- Conjure Mana X with that gem already in the bags: refused at the start of the cast (no mana lost)?
- Arcane Nuke 25+: mashing never sits on the Arcane Wrath step (cast times from the game data: Blast 1.5 sec, Wrath 3.5 sec). Pack: the Cone of Cold step is ready after six Explosions.
- Arcane Burst 40+: Presence of Mind, Arcane Power and an instant Wrath in one press, and PoM's cooldown starts when Wrath uses it (so both are ready together 3 min later).
- Fire Finisher 40+: Combustion fires after Fire Blast in the same press.
- Fire Nuke 20+: `[nocombat] Pyroblast; Fireball` switches as soon as you're in combat; Pyroblast cast is 6 sec (index 171).
- Wand: a second press does not stop the wand; Arcane Nuke and Missiles (named-channel conditions) do interrupt the wand. If wand Shoot does not count as channeling, nothing changes.
- Shield up 40+: Barrier, Mana Shield, Barrier with `reset=30` behaves as the tips say.
- Ice Block toggle: `/cancelaura Ice Block` works in combat.
- `/targetenemy [noharm][dead]` picks a hostile mob, not a neutral critter, near camps.
- Felfire (spell 24530, level 60, Fire, 500 damage, 100 mana, instant): where does it come from? Not used in any macro.

### 5. Sources

- Game data: `tools/gamedata.py facts|packet|spells MAGE`, `tools/reference/forever.json`, `tools/.cache/1.60.1.70888/SpellMisc.csv` (cast time index), `SpellReagents.csv`.
- RankedBoost Forever macros: https://rankedboost.com/world-of-warcraft/forever/macros/mage/frost/ , https://rankedboost.com/world-of-warcraft/forever/macros/mage/arcane/ , https://rankedboost.com/world-of-warcraft/forever/macros/mage/fire/ (their Ctrl variants not used: controller rule).
- Community notes: https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (spam-safe Missiles, `/stopcasting` interrupts, Ice Block cancel; its note that a "first spell" combo does nothing while that spell cools).
- Warcraft Tavern Forever mage leveling: https://www.warcrafttavern.com/forever/guides/mage-leveling/ (Fire Blast when not frozen, Wrath at 3-4 Blast stacks, Heating Up Pyroblast, Blast Wave for packs).
- Kami Labs Forever mage changes (beta notes, cross-check only): https://kami-labs.fr/en/wow-forever/mage-wow-forever-sorts-et-talents-modifies/
- Icy Veins Forever arcane leveling (https://www.icy-veins.com/wow-forever/arcane-mage-leveling) returned 403; only its search snippet (Blast 2-3 times, then Missiles) was seen.


## Paladin: guide (Retribution), Holy, Protection

`python tools/gamedata.py macros PALADIN`: **0 errors, 0 warnings**. The only
info lines say Judgement (4) and Holy Strike (6) are skipped before they are learned, which is intended.

Game facts used (build 1.60.1.70888): Judgement is **off the GCD** (StartRecoveryTime 0), 10 s cooldown, 10 yd range,
and needs a seal. Holy Strike is on the GCD with a 10 s cooldown. It shares spell category 2404 with Hammer of the
Righteous (6 s). Every seal is on the GCD with no cooldown and lasts 30 s. Hammer of Wrath has a 1 s cast (instant with
Champion of the Light 5/5). Light's Vigil and Flash of Light take 1.5 s, Holy Light 2.5 s. Divine Favor and Templar's
Bulwark are off the GCD. SpellEquippedItems (downloaded from wago.tools for this build): **Hammer of the Righteous
needs a one-handed axe, mace or sword** (subclass mask 145), and Holy Shield needs a shield.

### 1. Guide set findings (Retribution)

| Old | New | Why |
| --- | --- | --- |
| Fight 6-19 / 20-60: `/castsequence reset=target Seal, Judgement, Holy Strike, Judgement, Holy Strike, Judgement, Holy Strike` | **Fight 1-60**: retarget, attack, `Holy Strike`, then a `Judgement` rider | Judgement is off the GCD, but as a sequence step it took a whole press. The sequence waited on two 10 s cooldowns one after the other, and resealed on every new target (tab-targeting in a pack wasted seals). Now a single press casts Holy Strike and Judgement together. Before 6 it is Judgement only, before 4 attack only. |
| (seal inside Fight) | **Seal 1-19 / 20-39 / 40-60** (new, RT+Y / 4): the seal, then a Judgement rider | The seal is a no-cooldown GCD spell, so it gets its own press. Seal plus Judgement fits in one press: pressed at 10 yd it opens the pull. From 40 it is `/castsequence reset=combat Seal of Command, Seal of Righteousness` (no cooldowns), the Unsealed Wrath twist the tip chapter describes. |
| Pack 20-60: `/castsequence reset=target Consecration, Holy Strike, Judgement` | **Pack 20-60**: `[harm,nodead][combat] Consecration`, then a Judgement rider | Same sequence waits. The condition keeps 565 mana from going on a Consecration with no enemy around. |
| Heal up 1-60: `[@player] Flash of Light`, then `[@player] Holy Light` | **Heal up 1-19**: Holy Light; **20-60**: `[combat]` Flash of Light, else Holy Light. Both use the heal-anyone chain (mouseover, friend, the enemy's target, you) | Before, Holy Light could never fire after 20, and the button couldn't heal a party member. |
| Panic 6-33 / 34-60: one `/cast` | Same names and bands, with `/stopcasting` first | The bubble goes up mid-cast, which matters when you are casting Holy Light and about to die. The tips warn that pressing it while it cools down still stops your cast. |
| (none) | **Stun 8-60** (LT+Y / R): Hammer of Justice, then Judgement on the same enemy | The tip chapter's "stun, then Judge Command for double damage" in one press. |
| (none) | **Exorcism 20-60** (RT+X / 3): Exorcism, then a Judgement rider | Undead and Demons only. It can't share a button: on anything else it stops the macro. |
| (none) | **Finish 44-46 / 47-60** (RT+Right / 6): Hammer of Wrath on mouseover or target; Judgement rider from 47 | The cast blocks a rider until it turns instant at Champion of the Light 5/5 (47). |
| (none) | **Cleanse 8-41 / 42-60** (LT+Right / Shift+Q): Purify, then Cleanse, on mouseover, friend or you | Self-cleanse without dropping your enemy target. |

At 60 the guide set has 9 names: Fight, Seal, Pack, Exorcism, Finish, Heal up, Panic, Stun, Cleanse.

### 2. Path sets

#### Holy (`holy`): 11 macro names at 60

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-60 | RT+A / 1 | As the guide | Solo damage. With a friend selected it picks an enemy |
| Seal | 1-60 | RT+Y / 4 | Seal of Righteousness, then a Judgement rider | Holy has no Seal of Command. The tips point to Seal of Wisdom (38) for mana |
| Pack | 20-60 | RT+B / 2 | As the guide | Holy Conduit (41) makes it 40% cheaper; Consecrated Ground (47) |
| Exorcism | 20-60 | RT+X / 3 | As the guide | Holy Conduit (41) makes it cheaper |
| Finish | 44-60 | RT+Right / 6 | Hammer of Wrath (mouseover or target), no rider | 1 s cast on this path |
| Heal up | 1-19 / 20-60 | LT+A / Q | Holy Light, then Flash of Light, on the heal-anyone chain | The quick heal |
| Big heal | 20-60 | LT+B / E | Holy Light on the heal-anyone chain | A healer needs both heals. The tips point to Oath of Light (37) and Infusion of Light (39) |
| Shock | 42-44 / 45-60 | LT+Up / G | Holy Shock: mouseover friend or enemy, then target friend or enemy, then you; from 45 a Divine Favor rider | Holy Shock (path level 42). DF (45) goes after the instant Shock, so the *next* heal is a sure crit and Illumination refunds mana. DF before the Shock would block it for 2 min. The tips point to Light's Vigil (53) |
| Panic | 6-33 / 34-60 | LT+X / F | As the guide | Divine Shield halves only damage, not healing |
| Stun | 8-60 | LT+Y / R | As the guide | Peel an enemy off you |
| Cleanse | 8-41 / 42-60 | LT+Right / Shift+Q | As the guide | Party dispels on mouseover or friend |

#### Protection (`prot`): 11 macro names at 60

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-60 | RT+A / 1 | As the guide | Holy Strike is the single-target threat. Iron Creed (38) and Shieldsworn (40, 6 s cooldown, strikes with the shield) |
| Seal | 1-9 / 10-60 | RT+Y / 4 | `[equipped:Shields] Seal of Fury; Seal of Righteousness`, then a Judgement rider | Seal of Fury gives absorbs, and its Judgement taunts. The tips name Righteous Fury (30 min, not macroed: 30% base mana) |
| Taunt | 10-60 | RT+Left / E | Judgement on mouseover, target or the target's target, then Holy Strike on the same enemy | The warrior's Taunt pattern: select the party member being hit. Judgement is off the GCD, so Holy Strike follows |
| Pack | 20-60 | RT+B / 2 | Consecration, then a Judgement rider | Pack threat |
| Holy Shield | 30-60 | RT+Up / 5 | `[equipped:Shields] Holy Shield`, then a Judgement rider | Holy Shield (path level 30). Both cool down in 10 s, so they stay in step |
| Hammer | 40-60 | RT+Right / 6 | `[equipped:One-Handed Axes/One-Handed Maces/One-Handed Swords]` Hammer of the Righteous, then a Judgement rider | 4 targets. Its cooldown is shared with Holy Strike: Hammer on packs, Fight on one enemy. With the wrong weapon the clause is skipped and it only judges |
| Heal up | 1-19 / 20-60 | LT+A / Q | As the guide | |
| Panic | 6-21 | LT+X / F | As the guide (Divine Protection) | |
| Panic | 22-60 | LT+X / F | `/stopcasting`, `[combat]` Templar's Bulwark (off GCD), then `[@player]` Holy Light | Bulwark (path level 22) lets a tank keep fighting, which the bubble doesn't. The self-heal starts behind the absorb. Out of combat it only heals |
| Stun | 8-60 | LT+Y / R | As the guide | With Seal of Fury the Judgement taunts as well |
| Cleanse | 8-41 / 42-60 | LT+Right / Shift+Q | As the guide | |
| Exorcism | 20-60 | RT+X / 3 | As the guide | Holy threat on Undead |

### 3. Data.lua text that now reads wrong (from `packet PALADIN`, tip chapters)

- Tips 10-19: "Controller: the Fight macro on RT+A casts seal, Judgement and Holy Strike in order." -> "Controller: Seal (RT+Y) puts your seal up and judges; Fight (RT+A) casts Holy Strike with Judgement riding along."
- Tips 20-29: "Swap to the 20–60 Fight macro: Seal of Command, then Judgement and Holy Strike." -> "From 20 your Seal button (RT+Y) casts Seal of Command; Fight keeps Holy Strike and Judgement going."
- Tips 20-29: "Stun first with Hammer of Justice, then Judge Command (RT+Y) for double damage." -> "Stun (LT+Y) casts Hammer of Justice with Judgement on the same press: Command's Judgement does double damage to a stunned enemy."
- Tips 30-39: "Divine Shield (34) when a pull goes wrong — it halves your damage, so heal up inside it. Swap to the 34–60 Panic macro." -> "Divine Shield (34) when a pull goes wrong: it halves your damage, so heal up inside it. Panic (LT+X) switches to it at 34."
- Tips 30-39: "Exorcism on Undead and Demons." -> "Exorcism (RT+X) on Undead and Demons."
- Tips 40-60: "Fight with Command for three swings, then cast Righteousness (RT+←) — the next hit releases the stored Command copies." -> "Seal (RT+Y) now swaps Command and Righteousness on each press, with Judgement riding along: press it when Judgement is ready and your next hit releases the stored copies."
- Tips 40-60: "Hammer of Wrath below 20% health." -> "Finish (RT+Right): Hammer of Wrath below 20% health."
- Tips 40-60: "Consecration + Holy Strike on packs." -> "Packs: Pack (RT+B) for Consecration, then Fight for Holy Strike."

The trainer notes don't describe a macro; their facts (Judgement 10 s and 10 yd, Hammer of Wrath instant at 5/5) match.

### 4. Check in game

- Holy Strike, then Judgement, both go out on one press. The same for the seal, then Judgement (the new seal must count as "a seal up" for the Judgement on the same press).
- Stun: does the Hammer of Justice stun land before the Judgement on the same press (Command's double damage)?
- Seal 40+: `reset=combat` starts each fight on Command. The Unsealed Wrath release works when you alternate on each Judgement.
- `equipped:` with `/` alternatives (Hammer of the Righteous). With a two-hander the clause is skipped and Judgement still fires.
- Finish 47+: instant Hammer of Wrath with a Judgement rider. 44-46 has no rider, because a cast is in progress.
- Panic: `/stopcasting` and then Divine Shield / Divine Protection in one press. Prot: Templar's Bulwark (off the GCD), then the Holy Light on yourself.
- Holy: Divine Favor rides after an instant Holy Shock and its buff waits for the next heal.
- Exorcism on a non-Undead enemy should do nothing at all (no Judgement).
- The heal chain through `@targettarget` when you have an enemy selected.

### 5. Sources

- Community Forever macro notes: https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (they flag Judgement + Holy Strike as working only if Judgement is off the GCD, which the game data confirms).
- RankedBoost Forever Paladin: https://rankedboost.com/world-of-warcraft/forever/macros/paladin/retribution/ , https://rankedboost.com/world-of-warcraft/forever/macros/paladin/protection/ , https://rankedboost.com/world-of-warcraft/forever/macros/paladin/holy/ . They confirm the one-handed weapon for Hammer of the Righteous and the Seal of Fury taunt. Their bodies use `[mod:ctrl]` and put Judgement *before* Hammer of Wrath and Holy Shield, where its cooldown would block them, so I used none of them. All text here is our own.


## Priest: guide (Shadow), Discipline, Holy

`python tools/gamedata.py macros PRIEST`: **0 errors, 3 warnings**.
All three warnings are the Burst buttons (Inner Focus before the spell it empowers), intended: the tips say
the button does nothing while Inner Focus (and Power Infusion) cool down. Generator with the length checks:

Game facts that shaped the design (build 1.60.1.70888, `SpellCooldowns`/`SpellMisc`/`SpellShapeshift`):
- OFF the GCD: Inner Focus, Power Infusion, Confounding Flash only. **Touch of Weakness and Shadowguard are ON
  the GCD** (rank 1 rows: StartRecoveryTime 1500); `facts` prints OFF GCD for them only because of an internal
  proc copy without a GCD row (same bug as Shaman's Lightning Shield, see SHAMAN.md).
- Cooldowns: Mind Blast 8 s, PW:S 4 s (+ Weakened Soul 15 s), Devouring Plague 24 s, SW:Death 18 s,
  Vampiric Embrace 30 s, Silence 45 s, Penance 12 s, Prayer of Mending 10 s. Holy Fire, Smite, SW:Pain, Mind
  Flay, Renew and the heals have none.
- Channels (Attributes_1 0x4): Mind Flay and **Penance**. Wand Shoot (5019) is not a channel in the data.
- Shadowform: "you may not cast healing spells" (Forever's tooltip; Smite/Holy Fire have no Shadowform
  exclusion, only the heals do). Re-entering costs 40% of base mana (RankedBoost; `facts` says 40% Mana).

### 1. Guide set (Shadow) findings

| Problem | Old | New | Why |
| --- | --- | --- | --- |
| No Fight macro before 10 | none at 1-9 | Fight 1-3 (Smite, or Smite + wand), 4-9 (Smite, Pain, wand; Smite filler without a wand) | Every priest levels on Smite and the wand from 1. `[equipped:Wands]` / `[noequipped:Wands]` lines keep it from sticking on Shoot without a wand. |
| Mind Blast as castsequence step 1 stalls on a new target while it cools (the warning) | Fight 10-19 `reset=target Mind Blast, Pain, Shoot` | Fight 10-19 `/cast [nocombat] Mind Blast` pull, then `reset=target Shadow Word: Pain, Shoot` in combat | Out of combat Mind Blast is almost always ready (the last one was at the start of the previous fight). In combat the sequence holds no cooldown at all. |
| Pressing again could toggle the wand off | `... Shoot` with no guard | `[nochanneling:Shoot]` on the wand line, one Shoot step only | Brief's engine rule. With a single trailing Shoot step, if the guard fails a press restarts the rotation instead of switching the wand off. |
| Fight 20-60 had no pull, needed a separate Mind Blast press, no re-target | `[nochanneling] reset=target Pain, Mind Flay x7` | 20-39: `[nocombat] Mind Blast` + `Pain, Mind Flay x6`; 40-60: `[noform] Shadowform; [nocombat] Mind Blast` + same | One button pulls, DoTs and fills. x6 keeps it under 255 with the new lines (6 Flays = 18 s, Pain lasts 24 s with Improved SW:P). From 40 the first press restores Shadowform after a heal. |
| No re-target after a kill | - | `/targetenemy [noharm][dead]` on Fight, Blast, Burst | Brief rule for ranged Fight buttons. |
| Tips pointed at buttons that weren't macros (Pain on RT+Y, Mind Blast RT+X, Plague RT+Left) | plain spells | **Blast** (RT+X / 3, 10-60): re-target + Mind Blast | Mind Blast is the core mid-fight cooldown; RT+X is where the old tips put it. Plague and Vampiric Embrace stay plain bar spells (a cooldown on any macro line would block what follows). |
| Heal up's second line could never fire after 20; self only; no Heal (16) | `[@player] Flash Heal` / `[@player] Lesser Heal`, 1-60 | Heal up 1-15 Lesser Heal, 16-19 Heal, 20-39 Flash Heal, 40-60 `/cancelform` + Flash Heal, all heal-anyone | One spell per band. Heal-anyone (mouseover, friend, enemy's target, self) is still you when solo. At 40+ the heal can't go in Shadowform, so the button drops it (RankedBoost's Forever macro does the same). |
| Finish could fire on nothing | `/cast Shadow Word: Death` | `[harm,nodead]` | Name, pad, key kept. Tips add Early Demise (41). |
| Missing: interrupt | - | **Silence** (RT+Y / 4, 32-60): `/stopcasting` + mouseover-or-target Silence | Stops your Mind Flay so the silence goes out at once; hover a second caster on keyboard. |
| Missing: Inner Focus use (57) | - | **Burst** (RT+Up / 5, 57-60): Inner Focus + Mind Blast | Inner Focus must come before the spell, so it gets its own button; `#showtooltip Inner Focus` shows the 3 min cooldown that gates it. |
| Missing: buffs | - | **Buffs** (LT+Up / Shift+1, 12-29 / 30-60): castsequence Inner Fire, Fortitude, Divine Spirit (30) | No cooldowns, never stalls; Fortitude/Spirit go on a hovered or targeted friend. |
| Shield | `[@player]` PW:S 6-60 | unchanged body; tips say why it can be "not ready" | Kept as the self-shield. |

Guide set at 60: 8 macros (Fight, Blast, Finish, Silence, Burst, Shield, Heal up, Buffs).

### 2. Path sets

Levels 1-19 are identical in all three sets (no talent spells yet); Shield, Finish and Buffs too.

#### guide (Shadow)

| Name | Levels | Button / key | What one press does | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3 | RT+A / 1 | re-target; Smite, then wand (Smite without a wand) | wand from level 1 if you have one |
| Fight | 4-9 | RT+A / 1 | Smite, Shadow Word: Pain, wand (no wand: Smite, Pain, Smite, Smite) | Pain at 4 |
| Fight | 10-19 | RT+A / 1 | out of combat Mind Blast; in combat Pain, wand (or Smite) | Mind Blast at 10, kept out of the sequence |
| Fight | 20-39 | RT+A / 1 | out of combat Mind Blast; in combat Pain, Mind Flay x6; `[nochanneling]` | Mind Flay at 20 (guide path) |
| Fight | 40-60 | RT+A / 1 | Shadowform if out of it; else as 20-39 | Shadowform at 40 |
| Blast | 10-60 | RT+X / 3 | re-target, Mind Blast | mid-fight cooldown nuke |
| Finish | 32-60 | RT+B / 2 | Shadow Word: Death | SW:Death at 32 |
| Silence | 32-60 | RT+Y / 4 | stop casting, Silence mouseover or target | Silence at 32 (guide path) |
| Burst | 57-60 | RT+Up / 5 | Inner Focus, Mind Blast | Inner Focus at 57 (guide path) |
| Shield | 6-60 | LT+A / Q | PW:Shield on you | self-shield |
| Heal up | 1-15 / 16-19 / 20-39 / 40-60 | LT+B / E | Lesser Heal / Heal / Flash Heal / leave Shadowform + Flash Heal, heal-anyone | follows learn levels |
| Buffs | 12-29 / 30-60 | LT+Up / Shift+1 | Inner Fire, Fortitude, (Divine Spirit) | Inner Fire 12, Divine Spirit 30 |

#### disc (Discipline)

| Name | Levels | Button / key | What one press does | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9, 10-19 | RT+A / 1 | as the guide | same spells |
| Fight | 20-60 | RT+A / 1 | out of combat Mind Blast; in combat Holy Fire, Pain, wand (Smite without one); `[nochanneling]` | Holy Fire at 20 (no cooldown in Forever); `[nochanneling]` also keeps a press from cutting Penance |
| Finish | 32-60 | RT+B / 2 | Shadow Word: Death | every priest has it |
| Penance | 30-60 | RT+Y / 4 | Penance: hovered/targeted friend is healed, enemy target is hit, else you | Penance at 30 (disc path), 12 s cooldown |
| Burst | 30-60 | RT+Up / 5 | Power Infusion on you (40), Inner Focus, Penance | both 3 min, used together; gated on purpose |
| Shield | 6-60 | LT+A / Q | PW:Shield on you | self-shield; tips add Soul Warding (27) |
| Shield ally | 6-60 | LT+Right / T | PW:Shield heal-anyone | Disc's tank tool; solo it is you |
| Heal up | 1-15 / 16-39 / 40-60 | LT+B / E | Lesser Heal / Heal / Greater Heal, heal-anyone | efficient heal |
| Flash | 20-60 | LT+X / R | Flash Heal, heal-anyone | fast heal |
| Renew | 8-60 | LT+Y / F | Renew, heal-anyone | cheap HoT |
| Buffs | 12-29 / 30-60 | LT+Up / Shift+1 | as the guide | |

Disc at 60: 10 macros. Inner Focus (20) has no button before 30 (bar spell): a Burst without Penance would
only spend Inner Focus on whatever comes next.

#### holy (Holy)

| Name | Levels | Button / key | What one press does | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9, 10-19 | RT+A / 1 | as the guide | |
| Fight | 20-60 | RT+A / 1 | as disc's, with `[nochanneling:Shoot]` (Holy has no channel) | Holy Fire opener, wand finish |
| Finish | 32-60 | RT+B / 2 | Shadow Word: Death | |
| Mending | 58-60 | LT+Down / G | Prayer of Mending, heal-anyone | PoM at 58 (holy path), 10 s cooldown |
| Burst | 60 | RT+Up / 5 | Inner Focus + Greater Heal, heal-anyone | Inner Focus at 60 (holy path) |
| Shield, Shield ally, Heal up, Flash, Renew, Buffs | as disc | as disc | as disc | tips without the Disc talents; Heal up 40+ mentions Divine Fury and Litany of Light |

Holy at 60: 10 macros. Holy Nova (38) stays a bar spell (one instant, no target: a macro adds nothing);
the Fight tip points to it for packs.

### 3. Data.lua text that now reads wrong (from `packet PRIEST`)

- Trainer L10 Mind Blast note: "Your big nuke: 1.5 sec cast, 8 sec cooldown, 30 yd. Opener on its own button."
  -> "Your big nuke: 1.5 sec cast, 8 sec cooldown, 30 yd. Fight pulls with it, Blast (RT+X) fires it mid-fight."
- Tips 40-60 step: "Shadowform on; drop it only to heal between pulls."
  -> "Fight (RT+A) puts Shadowform back on; Heal up (LT+B) drops it to heal, so heal between pulls."
- Tips 40-60 step: "Mind Blast → Pain → Plague → Mind Flay; Mind Blast again every 5.5 sec once Improved Mind Blast is 5/5."
  -> "Fight: Mind Blast → Pain → Mind Flay. Blast (RT+X) and Devouring Plague whenever they light up; Mind Blast is back every 5.5 sec at Improved Mind Blast 5/5."
- Tips 30-39 step "Silence (32) casters." -> "Silence (32) casters: the Silence button (RT+Y) stops your cast first."
- Talent Inner Focus (57) why: "... 3 min cooldown: next spell free with +25% crit — pair with Mind Blast or Death."
  -> "... 3 min cooldown: next spell free with +25% crit. Burst (RT+Up) pairs it with Mind Blast."
- Still true, no change: L20 Devouring Plague "Own button — the cooldown would stall the Fight macro.", tips
  10-19 "Controller: the Fight macro on RT+A does this order." (Fight now does Mind Blast → Pain → wand),
  tips 20-29 "Mind Blast from range → Pain → Mind Flay until it dies.", L6 Power Word: Shield note.

### 4. Check in game

- **Wand guard:** with a wand, mash Fight while the wand shoots (levels 1-19, and Disc/Holy 20+). It should do
  nothing. If it restarts the rotation (Smite / Pain / Holy Fire stops the wand) then `[nochanneling:Shoot]`
  doesn't see the wand in Forever (the data has Shoot as no channel); tell me and I'll switch to another guard.
- `[equipped:Wands]` / `[noequipped:Wands]`: without a wand, Fight 4-9 should go Smite, Pain, Smite, Smite.
- **Mind Blast pull:** out of combat Fight casts Mind Blast; pulling again within 8 s of the last Mind Blast,
  the press should wait (nothing else happens) until it is back.
- **Shadowform (40+):** Heal up drops the form and casts Flash Heal in one press (`/cancelform`); the next Fight
  press casts Shadowform (`[noform]`), the one after Mind Blast or Pain.
- Fight 20+ (Shadow): a press during Mind Flay doesn't cut it. Disc: a Fight press during Penance doesn't cut it.
- Disc Burst at 40: Power Infusion, Inner Focus and Penance all go out on one press (the first two are off the GCD).
- Buffs with a friend targeted: Inner Fire lands on you, Fortitude on the friend.
- Penance on an enemy target damages it, on a friend heals, with nothing targeted heals you.
- Shadowfiend: in the client data as a level-1 Shadow Magic spell (SoD ID 401977) that no trainer lists. Not used;
  if it turns out to be learnable, it would get a Burst-style button (5 min cooldown).

### 5. Sources

- Game data: `python tools/gamedata.py facts|spells|packet|macros PRIEST`, `tools/.cache/1.60.1.70888/SpellCooldowns.csv`, `SpellMisc.csv`, `SpellShapeshift.csv`.
- https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (spam-safe wand, `[noform] Shadowform`, mouseover heals, `/stopcasting` Silence)
- https://rankedboost.com/world-of-warcraft/forever/macros/priest/shadow/ (Shadowform re-entry costs 40% of base mana, `/cancelform` + Flash Heal)
- https://rankedboost.com/world-of-warcraft/forever/macros/priest/discipline/ (Penance heal-or-harm, Inner Focus and Power Infusion off the GCD)
- https://rankedboost.com/world-of-warcraft/forever/macros/priest/holy/ (Prayer of Mending targeting, Holy Nova)
- https://www.warcrafttavern.com/forever/guides/priest-leveling/ (Forever leveling rotations: Smite pull, Pain, wand; Shadow Mind Flay, Mind Blast and Devouring Plague on cooldown)
- Their modifier variants (`[mod:ctrl]`) were not used (controller rule). All text is our own.


## Rogue: guide (Combat), Assassination, Subtlety

Facts from `python tools/gamedata.py facts ROGUE` (build 1.60.1.70888). Rogue GCD is 1 sec. Off the GCD: Cold Blood,
Premeditation, Riposte (Forever: 10 Energy, 6 sec, lit after a parry), Redirect (Forever-only, 10 sec), Stealth (10 sec
cooldown), Sprint, Vanish, Evasion, Pick Pocket, the poison spells. On it: Kick and Gouge (both 10 sec), Shank
(Forever: 5 Energy, 10 sec, +15/+25 Energy, off-hand hit), Blade Flurry, Adrenaline Rush, Ghostly Strike (20 sec),
Death Mark (10 sec), Preparation. Premeditation has no Stealth requirement in Forever's data (SpellShapeshift mask 0
for 14183; Ambush, Garrote, Cheap Shot, Sap carry the Stealth mask). Vanish uses Flash Powder (item 5140).

`python tools/gamedata.py macros ROGUE`: **0 errors, 14 warnings**,
all intended and explained in the tips:
- Shank as the last step of every builder sequence (8 warnings): on purpose, and the builders before it take longer than
  its cooldown, so it rarely or never waits; when it does, the wait only pools Energy.
- Burst 30-39 Blade Flurry before Evasion, Burst 40-60 Blade Flurry, Adrenaline Rush sequence, Ghostly Strike, Garrote:
  burst buttons that may block while their cooldown runs.
- Escape 10-21 Sprint before Gouge (3 warnings): the escape is Sprint; Gouge is a bonus when both are ready.

### 1. Guide set (Combat) findings

| Problem | Old | New | Why |
| --- | --- | --- | --- |
| Builder and finisher in one fixed sequence | Fight 1-9 `SS x3, Eviscerate`; 10-23 `SS x2, SnD, SS x3, Evis`; 24-60 `SS x2, SnD, Shank, SS x3, Evis` | **Fight** builds (RT+A / 1), new **Finish** spends (RT+B / 2: `Slice and Dice, Eviscerate`, `reset=target`) | The sequence counted presses, not combo points: every miss, dodge or parry (still a cast) and every bonus point (crits, Ruthlessness 60, Cheap Shot's 2) put Eviscerate on the wrong number of points. There is no combo point conditional, so the player presses Finish at the right count. |
| No opener; Stealth broken on the way in | `/startattack` on every press | `/startattack [nostealth,harm,nodead]`; 26+ `/cast [stealth,harm,nodead] Cheap Shot` | Pressing Fight while walking in started auto attack, whose first swing broke Stealth. Cheap Shot (26), the guide's own opener, was never cast. |
| Riposte had no button | plan text: "Own button" | rides at the end of Fight from 20 (`/cast Riposte`) | Off the GCD in Forever: it fires with the next Sinister Strike after a parry; unlit, the last line simply fails. |
| Shank in the middle | step 4 of 8, the macro waited on it | last step: `SS x3, Shank` (24-38), `SS x2, Shank` (39-60, Flash of Steel 5/5: 8 sec) | Cooldown step last on purpose; three (two) Sinister Strikes take longer than its cooldown. |
| No retarget | | `/targetenemy [noharm][dead]` | Owner rule for Fight buttons. |
| Stop a cast could stick | 12-60 `castsequence reset=12 Kick, Gouge` | 6-11 Gouge, 12-60 Kick, both `[@mouseover,harm,nodead][harm,nodead]` | Gouge fails on a caster that doesn't face you; the sequence then stalls on Gouge and every press restarts the 12 sec timer, so Kick never came back. No mouseover. Kick and Gouge are both on the GCD with cooldowns, so one press can't hold both. |
| Missing buttons | Blade Flurry, Adrenaline Rush, Evasion, Vanish, Sprint, Stealth, Redirect | **Burst** (RT+Y / 3, 30+), **Stealth** (LT+A / E), **Escape** (LT+Y / F, 10+), Redirect on Finish | see the table below |

Old bodies for `ns.OLD_MACRO_BODIES.ROGUE`: the three Fight bodies and Stop a cast as they are in Data.lua today.

### 2. Path sets

#### guide (Combat): 6 names, 14 versions, at most 6 active

Talent spells: Riposte 20, Blade Flurry 30, Adrenaline Rush 40.

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-19 | RT+A / 1 | retarget, auto attack (not in Stealth), Sinister Strike | |
| Fight | 20-23 | RT+A / 1 | + Riposte rider | |
| Fight | 24-25 | RT+A / 1 | `reset=target SS x3, Shank` + Riposte | |
| Fight | 26-38 | RT+A / 1 | Stealth: Cheap Shot; else `SS x3, Shank`; Riposte | 238 chars |
| Fight | 39-60 | RT+A / 1 | as above with `SS x2, Shank` | Flash of Steel: Shank every 8 sec, 30-40 Energy |
| Finish | 1-9 | RT+B / 2 | dead target: Redirect; else Eviscerate | |
| Finish | 10-60 | RT+B / 2 | dead target: Redirect; else `reset=target Slice and Dice, Eviscerate` | no cooldown steps; a long fight renews SnD |
| Burst | 30-39 | RT+Y / 3 | Blade Flurry, `[combat]` Evasion rider | Endurance puts Evasion on the same 2 min as Blade Flurry |
| Burst | 40-60 | RT+Y / 3 | `reset=30 Blade Flurry, Adrenaline Rush`, Evasion rider | both on the GCD, so two presses; Blade Flurry (2 min) first so it is always ready when Rush (5 min) is |
| Stop a cast | 6-11 / 12-60 | RT+X / 4 | Gouge / Kick on mouseover, else target | |
| Stealth | 1-60 | LT+A / E | `[nostealth] Stealth; [harm,nodead] Pick Pocket` | a second press never drops Stealth |
| Escape | 10-21 | LT+Y / F | Sprint, `[combat]` Gouge | |
| Escape | 22-60 | LT+Y / F | stop attack, `[combat]` Vanish, Sprint | out of combat: Sprint only (travel) |

#### assassination: 6 names, 13 versions, at most 6 active

Talent spells: Cold Blood 32, Mutilate 40 (Venom 38 makes Shank boost poisons; no Riposte, Blade Flurry or Adrenaline Rush).

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-13 | RT+A / 1 | as guide 1-19 | |
| Fight | 14-17 | RT+A / 1 | Stealth: Garrote; else Sinister Strike | |
| Fight | 18-23 | RT+A / 1 | Stealth: Ambush (dagger, behind); else Sinister Strike | the path uses daggers |
| Fight | 24-39 | RT+A / 1 | Stealth: Ambush; else `SS x3, Shank` | |
| Fight | 40-60 | RT+A / 1 | Stealth: Ambush; else `Mutilate, Mutilate, Shank` | two Mutilates (120 Energy) outlast Shank's cooldown |
| Finish | 1-60 | RT+B / 2 | as guide | |
| Burst | 32-60 | RT+Y / 3 | `[harm,nodead]` Cold Blood, then Stealth: Ambush; else Eviscerate | Cold Blood must land first, so it has its own button and blocks while it cools (3 min) |
| Stop a cast, Stealth, Escape | | | as guide | |

#### subtlety: 7 names, 15 versions, at most 7 active

Talent spells: Premeditation 31, Ghostly Strike 35, Hemorrhage 38, Preparation 39, Death Mark 48. Dirty Deeds (26-27)
lets Garrote work from the front; Initiative (28-30) adds a point to Ambush, Garrote, Cheap Shot; Boot Knife (43-47)
gives Shank 2 points.

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-23 | RT+A / 1 | as assassination 1-23 | |
| Fight | 24-37 | RT+A / 1 | Stealth: Ambush; else `SS x3, Shank` | |
| Fight | 38-60 | RT+A / 1 | Stealth: Ambush; else `Hemorrhage x3, Shank` | three Hemorrhages (105 Energy) outlast Shank's cooldown |
| Finish | 1-60 | RT+B / 2 | as guide | |
| Burst | 31-47 | RT+Y / 3 | `[harm,nodead]` Premeditation, then Stealth: Ambush; else Eviscerate | in Stealth 4 points at once; in combat at 3 points straight into a 5-point Eviscerate |
| Burst | 48-60 | RT+Y / 3 | as above, Death Mark instead of Eviscerate | Death Mark for elites; Finish keeps Eviscerate |
| Ghostly | 35-60 | RT+Right / 5 | `reset=7/target Ghostly Strike, Garrote` | Ghostly Strike frees the next Garrote from Stealth for 7 sec, and Dirty Deeds from facing: the path's way to Garrote in combat (Ambush would still need you behind) |
| Stop a cast, Stealth, Escape | | | as guide | Escape's Vanish puts you back in Stealth, so Fight opens with Ambush again |

Preparation (39) has no macro: on the GCD with a 10 min cooldown, it would block whatever it rides with.

### 3. Data.lua text that now reads wrong (ROGUE)

| Where | Old | New |
| --- | --- | --- |
| plan L20 Riposte `why` | "After a parry: 10 Energy, 150% weapon damage and a 6 sec disarm (6 sec cooldown). Own button — press it when it lights up." | "After a parry: 10 Energy, 150% weapon damage and a short disarm (6 sec cooldown). It is off the global cooldown in Forever, so Fight fires it with your next Sinister Strike." |
| br 1-9 | "Sinister Strike ×3, then Eviscerate." | "Fight (Sinister Strike) to 3 combo points, then Finish (Eviscerate)." |
| br 1-9 | "Gouge (6) to stop a caster or buy time to bandage." | "Gouge (6) to stop a caster or buy time to bandage: Stop a cast (RT+X) casts it until Kick at 12." |
| br 10-19 | "Sinister Strike ×2 → Slice and Dice → Sinister Strike ×3 → Eviscerate." | "Fight to 2 points → Finish (Slice and Dice) → Fight to 5 → Finish (Eviscerate)." |
| br 10-19 | "Kick (12) casters." | "Kick (12) casters: Stop a cast (RT+X) kicks the enemy under your mouse first." |
| br 10-19 | "Controller: the Fight macro on RT+A does this order for you." | "Controller: Fight (RT+A) builds, Finish (RT+B) spends: Slice and Dice first, then Eviscerate." |
| br 20-29 | "Riposte every time it lights up." | "Riposte rides on Fight: it fires with your next Sinister Strike after a parry." |
| br 20-29 | "Vanish (22) to escape a fight you can't win." | "Vanish (22) to escape a fight you can't win: Escape (LT+Y) is Vanish and Sprint." |
| br 20-29 | "Cheap Shot (26) from Stealth on tough mobs." | "Cheap Shot (26): Fight opens with it from Stealth." |
| br 30-39 | "Two mobs? Blade Flurry, then Fight." | "Two mobs? Burst (RT+Y): Blade Flurry and Evasion, then Fight." |
| br 40-60 | "Big pull: Blade Flurry + Adrenaline Rush, then Fight." | "Big pull: Burst twice (Blade Flurry, then Adrenaline Rush), then Fight." |
| br 40-60 | "Evasion every 2 min with Endurance." | "Evasion every 2 min with Endurance: Burst casts it with Blade Flurry." |

Still right: br 20-29 "Shank (24): ... the 24+ Fight macro uses it." and br 40-60 "... the Fight macro fires it."
Aside (TalentPaths.lua, subtlety, Ghostly Strike `why`): "This is how you Ambush in combat." Ambush still needs you
behind the mob; the Ghostly macro uses Garrote, which Dirty Deeds frees from facing. Suggest "This is how you Garrote
(or, from behind, Ambush) in combat."

### 4. To check in game

1. `/startattack [nostealth]`: Stealth holds while walking in; Cheap Shot / Ambush / Garrote still start auto attack.
2. Same press after an opener: the `[nostealth]` castsequence must not advance (its Sinister Strike hits the GCD).
3. Riposte (off the GCD) fires after Sinister Strike on one press; an unlit Riposte on the last line costs nothing.
4. Shank without an off-hand weapon: the sequence stalls at Shank (tips warn).
5. **Redirect on a corpse** (Finish on a dead target): does Forever allow it, and does the next Fight hit get the points?
6. **Premeditation out of Stealth** (Sub Burst in combat): the data says no Stealth requirement.
7. Cold Blood / Premeditation then Eviscerate, Ambush or Death Mark on one press.
8. Ghostly Strike, then Garrote from the front without Stealth.
9. Mutilate's weapon need: the tooltip only says "both weapons"; no dagger requirement in our tables.
10. Burst: Evasion after Blade Flurry on one press; the `reset=30` sequence.
11. Escape: `/stopattack`, Vanish and Sprint on one press keep you in Stealth.
12. Stealth: in Stealth the press picks the pocket and never toggles Stealth off.
13. Riposte's tooltip says "disarms the target for 0 sec" (an unresolved value); Data.lua says 6 sec. My replacement says "a short disarm".

### 5. Sources

- https://rankedboost.com/world-of-warcraft/forever/macros/rogue/combat/ (Blade Flurry with Evasion, Sprint + Gouge
  escape, Adrenaline Rush burst; their Evasion line before Blade Flurry would block it under Forever's rule, so the
  order is reversed here)
- https://rankedboost.com/world-of-warcraft/forever/macros/rogue/subtlety/ (Premeditation before Ambush, Vanish /
  Preparation, Ghostly Strike's Stealth-free Garrote or Ambush)
- https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (mouseover Kick and Gouge, Stealth
  that doesn't cancel, Cold Blood + Ambush, Mutilate and Hemorrhage buttons)
- Game data: `tools/gamedata.py facts|spells|packet ROGUE`, `tools/.cache/1.60.1.70888/SpellShapeshift.csv` (Stealth
  masks), `SpellReagents.csv` (Flash Powder).


## Shaman: guide (Enhancement), Elemental, Restoration

`python tools/gamedata.py macros SHAMAN`: **0 errors, 14 warnings**,
all intended and explained in the tips:
- 10 x "castsequence step Flame/Earth Shock has a 6 sec cooldown": in Enhancement's Fight 10-24 and Shock the
  sequence holds **only shocks**, which share one cooldown, so waiting on the next shock never holds back a
  ready spell. In Elemental/Resto Fight the shocks sit after two Lightning Bolts (4-6 s of casting), so the
  shared cooldown is nearly always over when they come up.
- 6 x Fire Nova / Chain Lightning in Pack: cooldown steps placed after Magma Totem on purpose (two 10 s novas
  per 20 s Magma; six 6 s novas per 40 s Magma with Trial by Fire).
- 1 x Swift heal: Nature's Swiftness before Healing Wave, the gated burst pattern.

Game facts that shaped the design (build 1.60.1.70888):
- One shared 6 s cooldown for Earth, Flame and Frost Shock (Category 19). Stormstrike 6 s (own). Chain
  Lightning 6 s. Fire Nova 10 s and needs an active fire totem. Riptide 12 s.
- OFF the GCD: Rage of the Farseer, Lightning Mastery, Nature's Swiftness, Reincarnation.
  **Lightning Shield and Water Shield are ON the GCD** (rank 1 row StartRecoveryTime 1500). `facts` prints
  "OFF GCD" for Lightning Shield only because its internal proc copy (ID 26363, level 56) has no cooldown row:
  worth fixing in `spell_facts` (only count rows with a level > 0 / the castable ranks).
- Totems have a 1 s GCD and need their element's totem (SpellTotems categories Earth 2, Air 3, Fire 4, Water 5):
  Earth at 4, Fire at 10, Water at 20, Air at 30 (Warcraft Tavern's quest list).
- No Earth Shield and no Lava Burst in this build (Warcraft Tavern's beta guide mentions Lava Burst; the tree
  doesn't have it). Elemental Mastery is gone; Lightning Mastery (Elemental row 7) replaces it.
- Stormstrike boosts the next Lightning Bolt, Chain Lightning **or** Earth Shock by 20% (game tooltip).

### 1. Guide set (Enhancement) findings

| Problem | Old | New | Why |
| --- | --- | --- | --- |
| Fight 4-9 wrapped back to a 2.5 s Lightning Bolt mid-melee and waited 6 s between two Earth Shocks | `reset=target Lightning Bolt, Earth Shock, Earth Shock` | 1-3: re-target, start attack, `[nocombat] Lightning Bolt`; 4-9: `[nocombat] Lightning Bolt; Earth Shock` | Bolt only as the pull; in combat the press is the shock (or nothing while it cools, swings continue). New 1-3 version: the button exists from level 1. |
| Fight 10-24: Flame Shock every third shock, so its 12 s DoT was down a third of the time | `Flame Shock, Earth Shock, Earth Shock` | `[nocombat] Lightning Bolt` pull, then `[combat] reset=target Flame Shock, Earth Shock` | Flame Shock comes back exactly as its DoT ends (every 12 s). Shock-only sequence: nothing is lost while it waits. |
| Fight 25-60 mixed Stormstrike and shocks in one sequence: a cooling step blocks the ready one (new target after a shock kill, Improved Stormstrike resets after a dodge/parry) | `Flame Shock, Stormstrike, Earth Shock, Stormstrike` | **Fight** 25-60: `[nocombat] Lightning Bolt; Stormstrike` + `[combat] Rage of the Farseer` rider; **Shock** (RT+Y / 4, new) 25-60: `Flame Shock, Earth Shock` | Two independent 6 s cooldowns need two buttons (the engine can't do "whichever is ready"). Pressed in turn, every Earth Shock follows a Stormstrike and gets its +20%. A reset Stormstrike fires on the next press. |
| Rage of the Farseer (40) had no button | - | rider on Fight after Stormstrike | Off the GCD and nothing it must precede: after Stormstrike it fires whenever ready, never blocks. (Saves a press; the guide text "use it on elites" changes, see 3.) |
| Pack 32-60 sequenced two cooldowns (Fire Nova 10 s, Chain Lightning 6 s) and Fire Nova needs a fire totem | `reset=target Fire Nova, Chain Lightning` | Pack 26-60: `/startattack` + `reset=combat Magma Totem, Fire Nova, Fire Nova` | Magma (26) is the fire totem Fire Nova needs; two novas fill its 20 s; starts over after the fight. Chain Lightning is a slow cast for Enhancement and stays on the bar. |
| Totems re-dropped all four 5-min totems for Searing's 30-55 s, and 10-19 was Searing only | `/cast Call of the Elements` / `/cast Searing Totem` | 10-19: `[combat] Searing Totem; Strength of Earth Totem`; 20-60: `[combat] Searing Totem; Call of the Elements` | Out of combat: the long buff totems (whole Totem Bar from 20); in combat: only the short Searing Totem. |
| Heal up: Healing Wave line dead after 20, self only | `[@player] Lesser Healing Wave` / `[@player] Healing Wave` | 1-19 Healing Wave; 20-60 `[combat]` Lesser Healing Wave, else Healing Wave; heal-anyone | Fast heal in a fight, efficient heal after it. Still you when solo. |
| Imbue: Rockbiter line dead after 30; Lightning Shield (8) had no button | 1-60 `/cast Windfury Weapon` / `/cast Rockbiter Weapon` | 8-29 `reset=15 Lightning Shield, Rockbiter Weapon`; 30-60 `Lightning Shield, Windfury Weapon` | Lightning Shield is on the GCD, so it can't ride along: press 1 shield (10 min), press 2 imbue (60 min). Starts at 8 (a Rockbiter-only button at 1-7 added nothing). |
| No interrupt that skips the sequence | - | **Interrupt** (LT+X / R, 4-60): `/stopcasting` + mouseover-or-target Earth Shock | Fight/Shock may be on Flame Shock when a caster starts; LT+X / R is Warrior's Shield Bash slot. |
| No re-target after a kill | - | `/targetenemy [noharm][dead]` on Fight and Shock | brief rule |

Guide set at 60: 7 macros (Fight, Shock, Interrupt, Pack, Totems, Heal up, Imbue).

### 2. Path sets

Levels 1-9 Fight, Interrupt, Totems 20-60 and Heal up are the guide's bodies in Elemental (Resto: 1-9 Fight,
Interrupt, Totems 20-60). Imbue 8-9 is the guide's.

#### guide (Enhancement)

| Name | Levels | Button / key | What one press does | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3 | RT+A / 1 | re-target, start attack, Lightning Bolt out of combat | pull, then melee |
| Fight | 4-9 | RT+A / 1 | as 1-3; in combat Earth Shock | Earth Shock at 4 |
| Fight | 10-24 | RT+A / 1 | Bolt pull; in combat Flame Shock / Earth Shock in turn | Flame Shock at 10 |
| Fight | 25-60 | RT+A / 1 | Bolt pull; in combat Stormstrike + Rage of the Farseer (40) | Stormstrike at 25 (guide path) |
| Shock | 25-60 | RT+Y / 4 | re-target, start attack, Flame Shock / Earth Shock in turn | the shocks' own button once Stormstrike arrives |
| Interrupt | 4-60 | LT+X / R | stop casting, Earth Shock mouseover or target | interrupt |
| Pack | 26-60 | RT+B / 2 | Magma Totem, Fire Nova, Fire Nova | Magma at 26 |
| Totems | 10-19 / 20-60 | RT+X / 3 | out of combat Strength of Earth / Call of the Elements; in combat Searing | Fire totem quest 10, Call of the Elements 20 |
| Heal up | 1-19 / 20-60 | LT+A / Q | Healing Wave / (combat) Lesser Healing Wave, heal-anyone | LHW at 20 |
| Imbue | 8-29 / 30-60 | LT+Right / Shift+1 | Lightning Shield, then Rockbiter / Windfury | Lightning Shield 8, Windfury 30 |

#### elemental (Elemental)

| Name | Levels | Button / key | What one press does | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9 | RT+A / 1 | as the guide | no talents yet |
| Fight | 10-60 | RT+A / 1 | re-target; Bolt, Bolt, Flame Shock, Bolt, Bolt, Earth Shock | caster from the first talent point (Concussion, Elemental Alacrity) |
| Interrupt | 4-60 | LT+X / R | as the guide | |
| Pack | 26-27 | RT+B / 2 | Magma, Fire Nova, Fire Nova | Magma at 26 |
| Pack | 28-31 | RT+B / 2 | Magma, Fire Nova x6 | Trial by Fire 2/2 at 28: Magma 40 s, Fire Nova 6 s |
| Pack | 32-60 | RT+B / 2 | re-target; Chain Lightning pull, Magma, Fire Nova x6 | Chain Lightning at 32 |
| Burst | 51-60 | RT+Up / 5 | Lightning Mastery + Chain Lightning | Lightning Mastery at 51 (elemental path); then cast Chain Lightning from the bar, no cooldown for 15 s |
| Totems | 10-19 / 20-60 | RT+X / 3 | out of combat Stoneskin / Call of the Elements; in combat Searing | Stoneskin rather than Strength for a caster |
| Heal up | 1-19 / 20-60 | LT+A / Q | as the guide | |
| Imbue | 8-9 / 10-44 / 45-60 | LT+Right / Shift+1 | Lightning Shield + Rockbiter / Lightning Shield + Flametongue / Water Shield + Flametongue | Flametongue 10, Water Shield 45 (elemental path) |

Elemental at 60: 7 macros. Burst can't make Chain Lightning repeat by itself: a second press finds Lightning
Mastery cooling and stops (engine rule), so the tip sends you to the bar for the 15 s.

#### resto (Restoration)

| Name | Levels | Button / key | What one press does | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9 / 10-60 | RT+A / 1 | as the guide / as elemental | the resto path levels on bolts (Concussion and Alacrity at 10-17) |
| Interrupt | 4-60 | LT+X / R | as the guide | |
| Totems | 10-19 / 20-60 | RT+X / 3 | as elemental | |
| Heal up | 1-60 | LT+A / Q | Healing Wave, heal-anyone | main heal |
| Quick heal | 20-60 | LT+B / E | Lesser Healing Wave, heal-anyone | fast heal |
| Chain Heal | 40-60 | LT+Y / F | Chain Heal, heal-anyone | Chain Heal at 40 |
| Swift heal | 43-60 | LT+Down / G | Nature's Swiftness + Healing Wave, heal-anyone | NS at 43 (resto path); gated by its 3 min cooldown |
| Riptide | 49-60 | LT+Up / T | Riptide, heal-anyone | Riptide at 49 (resto path) |
| Imbue | 8-9 / 10-27 / 28-60 | LT+Right / Shift+1 | as elemental, Water Shield from 28 | Water Shield at 28 (resto path) |

Resto at 60: 9 macros. Mana Tide Totem (39, 5 min) stays a bar spell. No Earth Shield in Forever.

### 3. Data.lua text that now reads wrong (from `packet SHAMAN`)

- Tips 10-19 step: "Drop Searing Totem (and Strength of Earth) before you pull."
  -> "Totems (RT+X): Strength of Earth before the pull, Searing Totem once the fight starts."
- Tips 20-29 step: "Flame Shock → Stormstrike → Earth Shock → Stormstrike: one shock and one Stormstrike every 6 sec."
  -> "From 25: Stormstrike on Fight (RT+A), shocks on Shock (RT+Y). Press them in turn: each comes back every 6 sec."
- Tips 30-39 step: "Same Fight order: shocks and Stormstrike on cooldown." -> "Fight and Shock in turn, each on cooldown."
- Tips 30-39 step: "Chain Lightning (32) and Fire Nova on packs." -> "Packs: Pack (RT+B) drops Magma Totem, then Fire Nova twice."
- Tips 40-60 step: "Rage of the Farseer on elites and big pulls." -> "Fight fires Rage of the Farseer whenever it is ready."
- Talent Rage of the Farseer (40) why: "The capstone: +30% attack speed for 25 sec, 3 min cooldown. Use it on elites and big pulls."
  -> "The capstone: +30% attack speed for 25 sec, 3 min cooldown. Fight fires it whenever it is ready."
- Talent Stormstrike (25) why: "... your next Earth Shock within 12 sec deals 20% more. Your main button from here."
  -> "... your next Earth Shock, Lightning Bolt or Chain Lightning within 12 sec deals 20% more. Fight (RT+A) casts it from here." (the game names all three)
- Trainer L8 Lightning Shield note: "Keep it up always." -> "Keep it up always: Imbue (LT+Right) casts it on its first press."
- Still true: L20 Call of the Elements note, tips 20-29 "Call of the Elements before the pull.", tips 10-19
  "Flame Shock → melee → Earth Shock every cooldown." and "Controller: the Fight macro on RT+A does this order."

Not macros, but noticed in `TalentPaths.lua` (elemental and resto plans): Concussion says "5% harder per rank,
25% at 5/5" (game: 1% per rank, 5% at 5/5) and Elemental Alacrity "0.5 sec faster per rank, 1.5 sec at 3/3"
(game: 0.5 sec at 3/3). My tips don't repeat those numbers.

### 4. Check in game

- Fight 25+: Stormstrike and Rage of the Farseer (40) on the same press; RotF never fires out of combat.
- Shock and Fight pressed in turn keep both cooldowns rolling; after a dodge/parry reset Fight fires Stormstrike at once.
- Totems: `[combat]` split. Out of combat Call of the Elements (check its cast time; Data.lua says 3 sec) drops the
  Totem Bar; in combat only Searing. Does Call of the Elements need all four totems in your bags or skip missing ones?
- Pack: `reset=combat` must reset when combat ends (next pack starts on Magma). With the Magma destroyed, Fire Nova
  should fail and the press wait; Totems in combat (Searing) should get it going again.
- Imbue: Lightning Shield costs a GCD (the data says so even though `facts` prints OFF GCD).
- Heal up 20+: in combat Lesser Healing Wave, out of combat Healing Wave.
- Elemental Burst: Lightning Mastery and Chain Lightning on one press (LM off the GCD).
- Resto Swift heal: Nature's Swiftness and an instant Healing Wave on one press. RankedBoost claims the button casts a
  normal Healing Wave while NS cools; our engine rule says it stops instead. Which one is true in Forever?
- Interrupt: `/stopcasting` then Earth Shock cuts your own Lightning Bolt and interrupts in one press.

### 5. Sources

- Game data: `python tools/gamedata.py facts|spells|packet|macros SHAMAN`, `tools/.cache/1.60.1.70888/SpellCooldowns.csv`, `SpellCategories.csv`, `SpellTotems.csv`, `SpellMisc.csv`.
- https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (mouseover heals, `/stopcasting` Earth Shock, Elemental Mastery not in Forever, Stormstrike boosts LB/CL/ES)
- https://rankedboost.com/world-of-warcraft/forever/macros/shaman/enhancement/ (shared shock cooldown, Rage of the Farseer off the GCD)
- https://rankedboost.com/world-of-warcraft/forever/macros/shaman/elemental/ (Lightning Mastery off the GCD, Fire Nova / Magma, Trial by Fire)
- https://rankedboost.com/world-of-warcraft/forever/macros/shaman/restoration/ (Nature's Swiftness heal, Riptide + Chain Heal, LHW on the target's target)
- https://www.warcrafttavern.com/forever/guides/shaman-leveling/ (totem quests 4/10/20/30, Call of the Elements, Enhancement priority, Water Shield for Restoration)
- Their `[mod:ctrl]` variants were not used (controller rule). All text is our own.


## Warlock: guide (Affliction), Demonology, Destruction

`python tools/gamedata.py macros WARLOCK`: **0 errors, 5 warnings**, all intended and explained in the tips (end of section 1).

Game facts used (build 1.60.1.70888, `facts WARLOCK`, `SpellReagents.csv`, `SpellMisc.CastingTimeIndex`): Forever has **no Metamorphosis and no Felguard summon** (only an unlearnable "Metamorphosis : Demon Charge" row and a Felguard pet passive), so Demonology is Imp / Voidwalker / Succubus-Incubus / Felhunter with Soul Link. Soul Shards: Summon Voidwalker, Succubus and Felhunter, Shadowburn, Soul Fire, Create Healthstone and Create Soulstone each cost one; Summon Imp and Death Coil don't. Off the GCD: Bane of Havoc, Fel Domination, Amplify Curse. Cooldowns: Conflagrate 10 sec, Shadowburn 15 sec, Death Coil 2 min, Soul Fire 1 min, Fel Domination 5 min. Cast times: Immolate 2.0, Shadow Bolt 3.0 (rank 4+), Incinerate 2.5, Searing Pain 1.5; Bane (Destruction 10-14) takes 0.5 sec off Shadow Bolt, Immolate and Incinerate. Talent spells: Affliction Siphon Life 31, Wrack 40; Demonology Demonic Sacrifice 32 (the path says not to use it), Fel Domination 33, Soul Link 34; Destruction Conflagrate 25, Shadowburn 29, Bane of Havoc 34, Incinerate 40.

Demons per path: Affliction Voidwalker (Felhunter for caster areas, from the spellbook); Demonology Voidwalker to 25, then Succubus/Incubus (Improved Sayaad 26-28, Demonic Brand 29-31); Destruction Voidwalker (Imp in groups at 58-60 with Improved Imp, from the spellbook). Class quests: Voidwalker 10, Succubus 20, Felhunter 30.

### 1. Guide set findings (old -> new)

| Old | Problem | New |
| --- | --- | --- |
| Fight 8-60 only | No Fight at all for levels 1-7. | Fight 1-3 (Immolate, Shadow Bolt x3) and 4-7 (Corruption, Immolate, Shadow Bolt x2). |
| Fight (all): `/castsequence [nochanneling] ...` | A bare `[nochanneling]` is also false while the wand shoots (that is why `[nochanneling:Shoot]` works), so Fight did nothing while you wanded, which the tips tell you to do between DoTs. No re-target after a kill. | `[nochanneling:Drain Life/Drain Soul/Wrack/Health Funnel]` (protects the channels, stops the wand) and `/targetenemy [noharm][dead]`. Steps unchanged from 8 on. |
| Healthstone 10-60 | Fine, but remaking the stone meant the spellbook. | `/use [combat]` each rank, `/cast [nocombat] Create Healthstone`. |
| Pet taunt 10-60 | Fine for the Voidwalker; a Felhunter got nothing from it. | 36-60 adds `/cast Spell Lock` (each demon only knows its own line). |
| (none) | Tips say "Drain Soul to finish" and "wand", no buttons. | **Finisher** 10-60 RT+B / 2: `[nochanneling:Drain Soul] Drain Soul` (can cut Drain Life for the shard). **Wand** 1-60 RT+Y / 4: re-target, `/petattack`, `[nochanneling:Shoot] Shoot`. |
| (none) | No summon / heal-pet button. | **Pet** 1-60 LT+Y / F: `[nopet]` Voidwalker, else Imp; `[pet,nochanneling:Health Funnel]` Health Funnel. |
| (none) | Tips 40-60 say Death Coil "has its own button": it didn't. | **Panic** 42-60 LT+A / Q: `/stopcasting`, Death Coil, then your Healthstone. |

Warnings kept on purpose: Panic's Death Coil before the Healthstone (while it cools the press only stops your cast: tip points to LT+B), Destruction Fight's Conflagrate step 25-60 (last step; the steps before it take 11-11.5 sec, longer than its 10 sec cooldown, so it never waits when mashed).

Macros active at once: Affliction 7, Demonology 9, Destruction 8.

### 2. Path sets

Shared by all three paths with identical bodies: Fight 1-13, Finisher 10-28 (Destruction) / 10-60, Wand, Pet taunt, Healthstone, Panic; Pet is the same on Affliction and Destruction.

#### Guide (Affliction)

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3 | RT+A / 1 | Re-target, send pet, next of Immolate, Shadow Bolt x3 | Missing before |
| Fight | 4-7 | RT+A / 1 | ... Corruption, Immolate, Shadow Bolt x2 | Missing before |
| Fight | 8-13 | RT+A / 1 | ... Corruption, Agony, Immolate, Shadow Bolt x2 | Guide steps |
| Fight | 14-30 | RT+A / 1 | ... Corruption, Agony, Immolate, Drain Life x3 | Guide steps (drain tank) |
| Fight | 31-39 | RT+A / 1 | ... Corruption, Agony, Siphon Life, Drain Life x3 | Guide steps |
| Fight | 40-60 | RT+A / 1 | ... Corruption, Agony, Siphon Life, Wrack, Drain Life x2 | Guide steps |
| Finisher | 10-60 | RT+B / 2 | Drain Soul, spam-safe | Soul Shards for summons and stones |
| Wand | 1-60 | RT+Y / 4 | Re-target, send pet, wand without toggling it off | Mana-free damage while DoTs tick |
| Pet taunt | 10-35 | RT+Up / X | Send pet, Torment | Guide body |
| Pet taunt | 36-60 | RT+Up / X | Send pet, Torment (Voidwalker) or Spell Lock (Felhunter) | One button per demon job |
| Pet | 1-60 | LT+Y / F | No pet: Voidwalker, else Imp; pet out: Health Funnel | Summon and heal on one button |
| Healthstone | 10-60 | LT+B / E | In combat eat it, out of combat create it | Never forget to remake it |
| Panic | 42-60 | LT+A / Q | Stop cast, Death Coil, Healthstone | Survive a bad pull in one press |

#### Demonology

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-13 | RT+A / 1 | Guide bodies | No talent changes the opener yet |
| Fight | 14-28 | RT+A / 1 | ... Corruption, Agony, Immolate, Shadow Bolt x4 | No drain talents on this path; the demon does the damage (Unholy Power) |
| Fight | 29-60 | RT+A / 1 | ... Corruption, Agony, Searing Pain, Shadow Bolt x4 | Demonic Brand: Searing Pain marks the target for the demon's next 6 attacks; after the DoTs so the demon has hit first |
| Finisher, Wand, Pet taunt, Healthstone, Panic | as guide | as guide | as guide | shared |
| Pet | 1-25 | LT+Y / F | Voidwalker else Imp; Health Funnel | As guide |
| Pet | 26-60 | LT+Y / F | Succubus, else Incubus, else Voidwalker, else Imp; Health Funnel | Improved Sayaad (26-28) makes the Sayaad the damage demon |
| Quick pet | 33-60 | LT+Down / Shift+4 | No pet: Fel Domination, then Succubus/Incubus/Voidwalker | Fel Domination must land before the summon, so it has its own button and never blocks Pet |
| Buffs | 34-60 | LT+Up / Shift+1 | Soul Link; second press Demon Armor | Soul Link ends with each demon, so the cheap step comes first |

#### Destruction

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-13 | RT+A / 1 | Guide bodies | shared |
| Fight | 14-24 | RT+A / 1 | ... Immolate, Corruption, Shadow Bolt x4 | Aftermath (15-19) makes Immolate the opener |
| Fight | 25-39 | RT+A / 1 | ... Immolate, Corruption, Shadow Bolt x3, Conflagrate | Conflagrate last: 1.5 + 2 + 3 x 2.5 = 11 sec before it, after any reset too |
| Fight | 40-60 | RT+A / 1 | ... Immolate, Corruption, Incinerate x4, Conflagrate | 1.5 + 2 + 4 x 2.0 = 11.5 sec (11 once Corruption is instant at 54); Shadow and Flame (39) keeps the Immolate |
| Finisher | 10-28 | RT+B / 2 | Drain Soul | Build shards |
| Finisher | 29-60 | RT+B / 2 | Stop cast, Shadowburn | Instant finisher that gives the shard back on a kill |
| Havoc | 34-60 | RT+X / 3 | Bane of Havoc on the target (off GCD), then select the next enemy | RankedBoost's pattern: kill the second mob while 15% of the damage hits the first |
| Wand, Pet taunt, Pet, Healthstone, Panic | as guide | as guide | as guide | shared |

Not used, on purpose: Soul Fire (48, shard + 1 min cooldown: on an opener it would block Fight), Hellfire / Rain of Fire (channels you aim or stand in; spellbook), Curses (Banes and Curses stack in Forever, but an extra GCD per mob doesn't pay on leveling mobs), Demonic Sacrifice (the path itself says not to use it), Bane of Doom (60, 1 min cooldown), Life Tap and Fear (nothing a macro adds).

### 3. Data.lua text outside the macros

| Where | Old | New |
| --- | --- | --- |
| Tips 40-60 | "Death Coil (42) — instant damage that heals you and fears the mob for 3 sec. 2 min cooldown, so it has its own button." | "Death Coil (42): instant damage that heals you and makes the mob run for 3 sec. 2 min cooldown, so it has its own button, Panic (LT+A), which also eats your Healthstone." |
| Tips 10-19 | "Send the Voidwalker in and let it hit twice before you attack." | "Send the Voidwalker in with Pet taunt (RT+Up) and let it hit twice before you press Fight." (Fight sends the demon and casts at once.) |
| Tips 10-19 (optional) | "Drain Soul to finish — a kill always gives a Soul Shard." | "Drain Soul (Finisher, RT+B) to finish: a kill always gives a Soul Shard." |
| Tips 30-39 (optional) | "Health Funnel your demon between pulls." | "Health Funnel your demon between pulls (Pet, LT+Y)." |
| Tips 1-9 (optional) | "Let the DoTs tick and finish with your wand (Shoot)." | "Let the DoTs tick and finish with your wand (Wand, RT+Y)." |

The old macro tips inside Data.lua are replaced with the set.

### 4. Check in game

- `[nochanneling:Drain Life/Drain Soul/Wrack/Health Funnel]`: Fight does nothing during those channels, but does cut a running wand. If the wand never counted as channeling, nothing changes.
- `/use [combat] Major Healthstone` with none in the bags: skipped, the next line runs (the old Healthstone macro relied on this). Create Healthstone with one in the bags: refused before the shard is spent?
- Pet button: `[nopet]` is true right after the demon dies; a known Voidwalker with no Soul Shard stops the press (tips say so).
- Pet taunt with a Felhunter: the Torment line is skipped and Spell Lock fires; with a Voidwalker the Spell Lock line is skipped.
- Soul Link cast again while it is up: refresh (20% mana) or toggled off? The Buffs button puts it first.
- Quick pet: Fel Domination then the summon in one press; with Master Summoner 2/2 the summon is about 0.5 sec.
- Destruction Fight: the Conflagrate step never waits when mashed (25-39, 40-60, and after Corruption turns instant at 54); a resisted Immolate makes it wait (tip says so).
- Havoc: Bane of Havoc off the GCD and `/targetenemy` in the same press.
- Panic: Death Coil and the Healthstone in the same press.
- Which demon the level 20 quest teaches (Succubus, Incubus or both): the Pet button tries both.
- Demonic Brand: which demons deal the Shadow (threat) version.

### 5. Sources

- Game data: `tools/gamedata.py facts|packet|spells WARLOCK`, `tools/reference/forever.json`, `tools/.cache/1.60.1.70888/SpellReagents.csv` (shard costs), `SpellMisc.csv` (cast time index), `ItemSparse.csv` (Healthstone item names).
- RankedBoost Forever macros: https://rankedboost.com/world-of-warcraft/forever/macros/warlock/affliction/ , https://rankedboost.com/world-of-warcraft/forever/macros/warlock/demonology/ , https://rankedboost.com/world-of-warcraft/forever/macros/warlock/destruction/ (Havoc then `/targetenemy`; Fel Domination summon; their `[combat] Fel Domination` before the summon would block the summon for 5 min, not used; Ctrl variants not used: controller rule).
- Community notes: https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md (spam-safe drains, `[nochanneling:Shoot]` wand, pet-state conditions, "first spell" combos do nothing while it cools).


## Warrior: guide (Protection), Arms, Fury

`python tools/gamedata.py macros WARRIOR`: **0 errors, 4 warnings**. All four
are intended: Thunder Clap before Cleave in Fight pack 20-29 (guide, arms and fury all carry it) and Challenging Shout
before Cleave. The rider is meant to go out only with a Clap or Shout that lands, and the tips say so.

### 1. Guide set findings (owner-approved 2026-11-10 set)

All 22 bodies, names, pads, keys and level bands stay as they are. I found no spell that is used before it is learned
and no castsequence, and the `known:` IDs are valid (71 Defensive Stance, 1160 Demoralizing Shout, 2458 Berserker
Stance, 1310317 Vanguard). Only two tips are wrong:

| Macro | Old tip | New tip | Why |
| --- | --- | --- | --- |
| Fight 10-24, tip 2 | "Bloodrage rides along in combat whenever it is ready (it is off the global cooldown): the swap back to Defensive is followed by 10 free Rage. Tactical Mastery (14) keeps 10 Rage through the swap." | "Bloodrage rides along in combat when it is ready (off the global cooldown): the swap back to Defensive brings 10 free Rage. A Sunder press without 15 Rage stops before it. Tactical Mastery (14) keeps 10 Rage through the swap." | The engine stops at a known spell it can't afford. With less than 15 Rage the Sunder clause stops the macro, so the Bloodrage line is never reached. |
| Fight 25-60, tip 2 | "In combat: Sunder Armor every press, with Bloodrage riding along whenever it is ready." | "In combat: Sunder Armor every press, with Bloodrage riding along when it is ready. Below 15 Rage the Sunder can't go out and the press stops before Bloodrage too." | Same cause. With Vanguard there is no stance-swap press, and Charge gives only 9-12 Rage at 25-45. Bloodrage therefore waits until the first Sunder you can afford. A body fix (Bloodrage on the Charge press) would take the body past 255 characters. |

Checked and fine: Tactical Mastery's "10 Rage". `facts` prints 25 because its tooltip resolver takes the
`$?s12295[...]` branch for the Improved Tactical Mastery talent. Spell.csv has `$m1` = 10.

### 2. Path sets

#### Arms (`arms`): 11 macro names at 60

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9 | RT+A / 1 | Same as the guide: retarget, attack, Heroic Strike; Charge from 4 | Identical to the guide while no talent differs |
| Fight | 10-39 | RT+A / 1 | Out of combat: Charge (any stance goes to Battle first). In combat: back to Battle if needed, else queue Heroic Strike, then Bloodrage rider | Arms stays in Battle. The `[nostance:1]` clause returns it to Battle after Pummel or Intercept |
| Fight | 40-60 | RT+A / 1 | Same, with Mortal Strike as the in-combat spell, then Bloodrage rider | MS (path level 40) on cooldown. No Heroic Strike rider: Arms is short on Rage and MS comes first |
| Fight pack | 6-19, 20-29 | RT+Up / 5 | Thunder Clap; from 20 a Clap that lands queues Cleave | The guide's bodies, with Arms tips |
| Fight pack | 30-60 | RT+Up / 5 | Battle if needed, else Sweeping Strikes (off GCD) and then a Cleave rider | SS (path level 30) is the Arms pack button. Cleave goes after it and is still a cleaved swing |
| Battle Shout | 1-13, 14-60 | LT+Up / G | Guide bodies: buff, or Demoralizing Shout in combat | Same job |
| Rend again | 4-29, 30-60 | RT+Y / 4 | Rend; from 30, Berserker goes to Battle first | Rend is the Arms opener (Improved Rend 12). Bloodthrill (31) adds Overpower procs on Rended targets |
| Hamstring | 8-60 | LT+RT+Left / X | Guide body | Works in Battle and Berserker |
| Revenge | 12-60 | RT+X / 3 | Battle if needed, else Overpower, then Bloodrage rider | Keeps the guide's name so it updates in place. Its title is "Overpower" |
| Execute | 24-60 | RT+B / 2 | Retarget, attack, Execute (Defensive goes to Battle) | Fires only below 20%, so it can't share a button. The next press after a kill picks the next enemy |
| Victory Rush | 20-60 | LT+B / T | Guide body | Same job |
| Shield Bash | 38-60 | LT+X / R | Guide 38-60 body: Pummel in Berserker, otherwise switch to Berserker | Two-hander, no shield, so no interrupt before Pummel. Keeps the guide's name. Its title is "Pummel" |
| Intercept | 30-60 | RT+Left / E | Berserker if needed (`known:2458`), else Intercept | The gap closer in combat. Improved Tactical Mastery keeps 25 Rage across the swap |
| Panic | 20-60 | LT+Y / F | Battle if needed, else Retaliation | Arms has no Last Stand. Retaliation is its emergency button for a bad pull |

#### Fury (`fury`): 11 macro names at 60

| Name | Levels | Button / key | One press | Why |
| --- | --- | --- | --- | --- |
| Fight | 1-3, 4-9 | RT+A / 1 | Guide bodies | |
| Fight | 10-29 | RT+A / 1 | Same as the Arms 10-39 body | Battle Stance until the Berserker quest |
| Fight | 30-39 | RT+A / 1 | Dance: Battle, Charge, back to Berserker (`known:2458`), then Heroic Strike; Bloodrage rider | The guide's Charge dance, with Berserker in place of Defensive (253 characters) |
| Fight | 40-60 | RT+A / 1 | The same dance, then Bloodthirst with a Heroic Strike rider | BT (path level 40) on cooldown. The HS rider dumps spare Rage and helps the off-hand hit. Bloodrage moves to Rage up and Burst |
| Fight pack | 6-19, 20-29 | RT+Up / 5 | Guide bodies | |
| Fight pack | 30-35 | RT+Up / 5 | Berserker goes to Battle, then Thunder Clap with a Cleave rider | The guide's 30-60 shape, swapping to Battle |
| Fight pack | 36-60 | RT+Up / 5 | Berserker if needed, else Whirlwind, then Cleave rider | WW is the Fury pack button (and good on one target). A WW that lands queues Cleave |
| Battle Shout | 1-13, 14-60 | LT+Up / G | Guide bodies | |
| Rend again | 4-29 | RT+Y / 4 | Guide body | Rend can't be used in Berserker, so it ends at 29 |
| Hamstring | 8-60 | LT+RT+Left / X | Guide body | Works in Berserker |
| Revenge | 12-29 | RT+X / 3 | Battle if needed, else Overpower, then Bloodrage rider | Ends at 30, when an Overpower would cost a stance dance |
| Execute | 24-60 | RT+B / 2 | As Arms | Improved Execute (46) makes it 10 Rage |
| Victory Rush | 20-60 | LT+B / T | Guide body | |
| Shield Bash | 38-60 | LT+X / R | Guide 38-60 body (Pummel in Berserker) | Keeps the name. Its title is "Pummel" |
| Intercept | 30-60 | RT+Left / E | Berserker if needed, else Intercept | |
| Burst | 30-60 | RT+Right / 6 | `[combat]` Death Wish, then Bloodrage rider | DW (path level 30) is on the GCD with a 3 min cooldown. This is a burst button by design: while DW cools down the press does nothing |
| Rage up | 30-60 | LT+Right / Q | Berserker Rage (in Berserker), then Bloodrage rider | BR is free with a 30 s cooldown (Improved BR at 50 adds 10 Rage at once). Reckless Swings (34) is mentioned in the tips but not macroed: it is on a 1 s GCD, so it can't ride with BR |
| Panic | 20-43 | LT+Y / F | Battle if needed, else Retaliation | |
| Panic | 44-60 | LT+Y / F | `[stance:1] Retaliation; Piercing Howl` | Piercing Howl (path level 44) from Berserker, Retaliation in Battle |

New buttons take guide slots whose macros are Protection-only: Execute uses Block & Revenge's RT+B / 2, Intercept uses
Taunt's RT+Left / E and Burst uses Shield Slam's RT+Right / 6. Rage up takes a free slot (LT+Right / Q).

### 3. Data.lua text that now reads wrong (from `packet WARRIOR`)

- Trainer L8, L32, L54 Hamstring: "For fleeing enemies. Battle Stance only — use the Hamstring macro." -> "For fleeing enemies. Battle or Berserker Stance (30): the Hamstring macro leaves Defensive for you."
- Trainer L10 Bloodrage: "Fight uses it in combat whenever it is ready." -> "Fight uses it in combat when it is ready: on the swap back to Defensive, or with a Sunder once you have 15 Rage."
- Talent L18 Improved Bloodrage `why`: "...fires from Fight in combat whenever it is ready. +50% means you can Thunder Clap right after the Charge." -> "...fires from Fight in combat when it is ready (on the swap back to Defensive, later with your first Sunder). +50% means you can Thunder Clap right after the Charge." (This holds while Fight still dances, 18-24. From 25 Vanguard has no swap press.)
- Tips 10-19: "Fight uses Bloodrage in combat whenever it is ready, so you never press it yourself." -> "Fight uses Bloodrage in combat when it is ready (on the swap back to Defensive, or with a Sunder once you have 15 Rage), so you rarely press it yourself."

### 4. Check in game

- The rage stop: with less Rage than the main spell costs (Sunder 15, Heroic Strike 15, Mortal Strike / Bloodthirst 30), the press stops before the Bloodrage or Heroic Strike rider. The brief says a "no resource" spell stops the macro; please confirm that once.
- Pressing a queued Heroic Strike or Cleave again keeps it queued and the macro goes on (Arms and Fury Fight 10-39 are mashed).
- Arms: after Pummel or Intercept, one Fight press in combat brings you back to Battle. Fight pack at 30+ fires Sweeping Strikes and Cleave on one press with 50 Rage.
- Fury 30-39: from Berserker, Fight goes Battle, Charge, Berserker (+Bloodrage), then Heroic Strike. Fury 40+: Heroic Strike queues after Bloodthirst. Whirlwind that lands queues Cleave.
- Death Wish and Berserker Rage are on the GCD per SpellCooldowns (StartRecoveryTime 1500). Bloodrage should still ride after each one.
- Panic 44+ (Fury): Piercing Howl in Berserker, Retaliation in Battle.
- Still open from 2026-11-10: Vanguard Charge from Defensive (guide Fight 25+).

### 5. Sources

- `tools/audits/2026-11-10-warrior-smart-macros.md` (the design rules), `python tools/gamedata.py facts|macros|packet|spells WARRIOR`.
- Game tables: `tools/.cache/1.60.1.70888/SpellCooldowns.csv` (GCD, cooldowns), `SpellPower.csv` (Reckless Swings costs 25% of base health, Bloodrage 20%), `Spell.csv` (Tactical Mastery tooltip).
- Community Forever macro notes: https://raw.githubusercontent.com/nobody174/wow-forever/main/wow-forever-macros.md
- RankedBoost Forever Arms: https://rankedboost.com/world-of-warcraft/forever/macros/warrior/arms/ and Fury: https://rankedboost.com/world-of-warcraft/forever/macros/warrior/fury/. Their bodies rely on `[mod:ctrl]` and put cooldowns before the spells they share a button with, so I used none of them. All text here is our own.
