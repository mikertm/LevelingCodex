# Warrior macro audit for WoW: Forever

Reviewed all 12 macro entries and the related rotation tips in the addon's [Protection Warrior guide](../../Data.lua#L3), from levels 1 to 60. The guide currently has one Protection talent plan. Group DPS below covers how that Warrior should change play when someone else tanks, plus the talent gates a separate Arms or Fury layout would need.

The recommended controller layout is a primary attack, an adjacent Revenge button, and direct binds for effects that depend on a proc, current Rage, or an incoming attack. Use stance, target and player-selected modifiers for shared buttons. A fixed sequence has no way to pick a ready proc, detect a Rend already ticking, reserve Rage for an interrupt, or tell which enemy is about to get loose.

## Findings

| Priority | Current entry | Finding and proposed correction |
| --- | --- | --- |
| High | **Panic**, 26–60 | Last Stand alone at 26–27 is sound. From 28, the sequence requires Last Stand before Shield Wall, and can get stuck on Wall when it is cooling, the shield is unequipped, or the player is outside Defensive. Last Stand is 3 minutes. Wall is 15 minutes base, 9.5 with the guide's level-34 talent point, and 4 at 41. The 180-second reset measures time since the last macro press. Give each cooldown a direct button from its unlock. |
| High | **Fight**, 10–24 | The level band assumes the Defensive Stance class quest is complete and Sunder Armor is known. The combat stance swap handles Battle only, and the sequence cannot start from a missing stance. Before Vanguard the pull is Battle Stance, Charge, then Defensive when tanking or taking hits. Provide a manual Charge opener and direct Sunder. Keep the earlier auto-attack/Rend option available until the required spells are in the book. |
| High | **Fight**, 25–39 and 40–60 | The opener assumes Vanguard is taken at 25. Its three override spells preserve the trained Charge ranks and allow Defensive Stance, but rankless macro lookup had conflicting beta results. If the opener fails, use the current Charge dragged from the spellbook and check the exact text inserted by Shift-click. Also provide a Charge-independent combat key for close pulls, combat already in progress, or a respec. |
| High | **Fight**, 40–60 | It opens on Shield Slam as soon as the player levels, even before the talent is spent or with a two-hander equipped. With the talent and shield, three filler GCDs can space the Slams exactly six seconds apart across four 1.5-second intervals. The tip's guarantee still fails whenever a required filler cannot fire, and five Sunders per loop consume Rage even when the target is already at five stacks. The loop can recast Rend at 12 seconds on a target with a 21-second bleed. Put Shield Slam and Sunder on separate inputs so the player can use either immediately. |
| High | **Fight pack**, 20–60 | Thunder Clap and three Sunders account for four 1.5-second intervals, and Cleave is a queued swing. That makes the timing plausible. The loop costs 85 Rage before talents, including 20 for Cleave. A failed Cleave stalls access to the next Clap, and tabbing to spread threat resets the sequence to Clap, which may be on cooldown. Give Clap its own button at 6 and Cleave its own at 20. Tab deliberately for single-target threat. |
| High | **Tank utility**, missing | Add visible binds or spellbook instructions for Taunt (10, quest/stance), Shield Bash (12, shield), and Challenging Shout (26). Taunt is off the GCD in the client data and is for an enemy attacking someone else. Follow it with real threat. Concussion Blow (30 on this plan) is an optional stun on susceptible targets. Give the interrupt its own input even if it shares a key with Pummel through an explicit stance choice. |
| Medium | **Fight**, 4–9 | Levels 1–3 have no active macro. The 4–9 sequence uses 10 Rage on Rend and then asks for three 15-Rage Heroic Strikes. Rank 1 Charge gives 9 Rage. A queued strike spends Rage and replaces a swing that could generate it. Use auto-attacks and Battle Shout from 1, separate Charge and Rend at 4, and queue Heroic Strike only with spare Rage. |
| Medium | **Fight**, 10–39, and **Rend again** | Rend plus two Sunders costs 40 Rage before talents and loops in 4.5 seconds at uninterrupted GCD pace. Rend lasts 12 seconds at 10, 15 at 20, and 18 at 30. Reapplying it that early can waste ticks, and a short-lived mob may not repay the Rage spent on armor reduction. Keep the direct Rend key and describe it as an intentional opener, refresh near expiry, or retry after a miss. Retain Sunder for durable enemies, group armor and threat. |
| Medium | **Block & Revenge**, 16–60, and **Revenge**, 14–60 | Standalone Revenge is right. Its damage and threat are cheap, and its proc also comes from natural blocks, dodges and parries. Shield Block adds 75 percentage points of block chance for up to two blocks within seven seconds. An eligible incoming swing still has to happen. The sequence can park on Revenge, reset on a target switch, or block access to mitigation while waiting for a proc. Keep Revenge on the same bind at 14 and 16, and give Shield Block a separate input. |
| Medium | **Rage up**, 10–60 | Bloodrage is off the GCD with a one-minute cooldown. Battle Shout costs 10 Rage and lasts three minutes. They serve different purposes and the two-step sequence can spend the Rage intended for Clap or an interrupt. Keep both available independently. Test Bloodrage before Charge in the live client. Until then, teach Charge first when the pull permits it. |
| Medium | **Hamstring**, 10–60 | Available from 8 and usable in both Battle and Berserker. The existing branch correctly casts in either stance and swaps from Defensive, but the text says Battle only. Explain that the swap is a separate press and can drop Rage or defensive threat. Avoid swapping out of Defensive just to slow a runner if the tank needs to hold the pack. |
| Medium | **Tactical Mastery** and **Victory Rush** tips | Tactical Mastery at 14 retains **10 Rage baseline**. Improved Tactical Mastery in Arms adds 5/10/15. The reference renderer shows the talent-aware tooltip's 25-Rage branch for the baseline spell. Correct the trainer and rotation tips. Victory Rush at 20 heals 10% on a successful hit and is usable within 20 seconds of a qualifying kill, with a 30-second cooldown. Give it a direct button and teach players to use it when lit. [Blizzard's Warrior deep dive](https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior), [November 2 development notes](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696/9). |

Vanguard's raw talent record (1310317) overrides Charge 100/6178/11578 with 1240287/1240288/1240289. Charge remains out of combat and generates 9/12/15 Rage at ranks trained at 4/26/46. One beta player got rankless lookup errors and reported that explicitly selecting the learned rank worked. Another beta tester reported rankless Charge working. The November 6 Warrior hotfix covers a Reckless Swings tooltip. [Explicit-rank test](https://us.forums.blizzard.com/en/wow/t/prot-warrior-charge-in-defensive-issue/2370087/3), [rankless Charge and failed Revenge fallback tests](https://github.com/nobody174/wow-forever/blob/main/wow-forever-macros.md), [November 6 hotfixes](https://news.blizzard.com/en-us/article/24315281/wow-forever-hotfixes-november-6-2026).

## Solo Protection priorities

| Levels | What to press |
| --- | --- |
| **1–3** | Start auto-attacking. Keep Battle Shout up while fighting. Spend surplus Rage on Heroic Strike. |
| **4–9** | Charge from Battle if range and combat state allow it. Rend when the mob will live through enough ticks. Use Thunder Clap from 6 for a pack worth the 20 Rage, and Hamstring from 8 to stop a runner. Finish cheap kills with swings. |
| **10–13** | Complete the stance quest. Charge from Battle, then choose Defensive when taking hits or tanking. Use Rend on longer fights and Sunder where armor reduction will pay off. Use Bloodrage when Rage would otherwise delay the important action. In Battle, take an available Overpower at 12. |
| **14–19** | In Defensive, spend 5 Rage on a lit Revenge before a filler. From 16, use Shield Block when melee hits are coming and there is enough Rage for the follow-up. From 17, the guide's maxed Improved Thunder Clap lowers it to 14 Rage. Demoralizing Shout from 14 helps on sustained melee packs. |
| **20–24** | Use Victory Rush when lit on the next target, especially if the heal saves downtime. Keep Revenge and Thunder Clap available. Cleave at 20 is a surplus-Rage button for two nearby enemies. Execute at 24 is a finisher in Battle or Berserker. Avoid an automatic stance swap and Rage dump from Defensive. |
| **25–39** | With Vanguard, Charge from Defensive and keep the Rage that a stance swap would have dropped. Use Last Stand from 26, Shield Wall from 28 and Concussion Blow from 30 on direct binds. At 33, maxed Focused Rage lowers Revenge to 2 and Sunder to 12 before any Improved Sunder Armor points. |
| **40–60** | Shield Slam once talented and equipped, Revenge on proc, then the filler that fits the target. Shield Slam is 17 Rage with Focused Rage, so use the cheap Revenge first if Slam is unaffordable. Rend on a target that will live, Sunder on durable physical targets, and Thunder Clap for useful pack damage or mitigation. Train Shield Slam ranks at 48, 54 and 60. |

## Group priorities

- **Tank, single target.** Use Defensive with a shield once learned. Open with a threat hit you can afford, then use Shield Slam when available from 40, Revenge when it lights, and Sunder for threat and group armor reduction. Build and maintain the Sunder stack when assigned and the target will live. Save Rage and a GCD for an expected Shield Bash. Use Shield Block for incoming melee, Last Stand for a health buffer, and Shield Wall for damage reduction on its own button. Defensive Stance's +80% threat and Shield Slam's high threat reward staying in stance and putting threat on the right target. [November 2 development notes](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696/9).
- **Tank, packs.** Charge only when the pull allows it. Pull at range or use line of sight for casters and crowd-control setups. Once the pack is in range, use Thunder Clap in Defensive, tab through uncontrolled enemies for Sunder, Revenge and Shield Slam, and keep Clap available as enemies arrive or its slow needs refreshing. Use Demoralizing Shout for melee mitigation and Cleave only with spare Rage and safe nearby targets. Use Taunt for a loose enemy and Challenging Shout for temporary pack recovery. Follow either with threat. Keep damage off crowd-controlled enemies. [Blizzard's Warrior deep dive](https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior), [Forever combat and crowd-control design](https://news.blizzard.com/en-gb/article/24303313/world-of-warcraft-forever-deep-dive-panel-recap).
- **Group DPS.** A Protection Warrior filling in as DPS should assist the tank, use Battle or Berserker as appropriate, and avoid the auto-Defensive opener and high-threat attacks unless assigned or taking over. Battle Shout, the appropriate interrupt, Rend on longer fights in Battle, Victory Rush when lit, and Execute under 20% in Battle or Berserker all have their own timing. Cleave is useful with spare Rage and safe targets. A separate Arms layout can add Sweeping Strikes from 30 if talented, Mortal Strike from 40 if talented, and Rend with Bloodthrill for Overpower procs. A Fury layout can add Whirlwind in Berserker at 36 and Bloodthirst from 40 if talented. Those are separate opt-in priorities. [Blizzard's Warrior deep dive](https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior), [November 2 development notes](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696/9).

## Candidate macros for live testing

**Fight, levels 1–3.** Keep auto-attack available by itself for conserving Rage. On the attack bind, add Heroic Strike as a deliberate Rage dump.

```text
#showtooltip Heroic Strike
/startattack [harm,nodead]
/cast [harm,nodead] Heroic Strike
```

**Tank filler, from 10 after learning Sunder Armor.** From 40 use the same shape for a separate Shield Slam bind after spending the talent. Keep the existing direct Revenge macro and a spellbook Shield Block bind. Label which abilities the controller needs on both stance pages.

```text
#showtooltip Sunder Armor
/startattack [harm,nodead]
/cast [harm,nodead] Sunder Armor
```

**Compact attack key, 25+ with Vanguard.** Try this only after verifying rankless Charge on the current client. The selected stance and combat state choose the action. Keep a direct Sunder or auto-attack bind for a close pull, a Charge on cooldown, or a player without Vanguard. At 40, Shield Slam remains independently accessible.

```text
#showtooltip
/startattack [combat,harm,nodead]
/cast [nocombat,stance:1/2,harm,nodead] Charge; [combat,stance:2,harm,nodead] Sunder Armor
```

**Taunt, after the stance quest.** Mouseover if valid, otherwise current enemy. Current target is sufficient on a controller. This button does not start an attack or change stance.

```text
#showtooltip Taunt
/cast [stance:2,@mouseover,harm,nodead][stance:2,harm,nodead] Taunt
```

**Interrupt, Shield Bash at 12 and both branches at 38.** Use a plain Shield Bash bind from 12. Once Pummel is learned, the current stance chooses the ability. Shield Bash still requires a shield. The abilities share a cooldown and have 1.5-second global-cooldown entries in build 70862.

```text
#showtooltip
/cast [stance:3,harm,nodead] Pummel; [stance:1/2,harm,nodead] Shield Bash
```

## Verification and in-game checks

- `python tools/gamedata.py packet WARRIOR` and `python tools/gamedata.py audit -k WARRIOR -v` against the committed reference. The audit reported zero errors, zero warnings and 11 informational notes. Wago's newest listed Forever build matched the reference, `1.60.1.70862`. Raw checks used `Spell`, `SpellCooldowns`, `SpellCategories`, `SpellEffect`, `SpellShapeshift` and `SpellEquippedItems`. The raw tables confirmed the shield requirements for Shield Bash, Shield Block, Shield Slam and Shield Wall, as well as cooldowns and conditional tooltip branches. All five candidate bodies are ASCII, within the 255-character limit, and reference spells available by their suggested levels once trained, quested or talented.
- `python tests/run.py -k WARRIOR` passed all 80 selected scenarios. It reported 42 existing data warnings across the data checks. The mock stores macro bodies and tests addon behavior. Live casts, proc timing, targeting and server threat are outside that harness.
- At **10 and 14**, try the bar before and after the stance quest. Charge then change stance with more than 10 Rage at 14 and compare the retained amount. Check Bloodrage before Charge, including whether it puts the player in combat. At **16**, test Shield Block during another GCD, Revenge after a swing, and a switch to an add between the two.
- At **25, 26 and 46**, test rankless Charge from Defensive with Vanguard, the spellbook button, and Shift-click's current-rank macro text. Verify the actual Rage gained and repeat after a respec or spec switch. At **40**, check the bar before and after spending the Shield Slam point and with the shield removed.
- Tank one pack and one caster. Switch targets while Thunder Clap cools, Taunt an add, reserve a Shield Bash, and use Shield Wall while Last Stand cools and vice versa. Repeat on controller to catch stance-page and modifier conflicts.
- For an optimization comparison, alternate the current and proposed binds on comparable solo pulls with the same weapon and starting Rage. Record kill time, damage taken, downtime, clipped Rend ticks, and presses stuck on unavailable abilities. In dungeons compare time to initial threat on the pack, loose adds and missed interrupts. This audit proposes priorities from the spell and macro constraints. It includes no live DPS or threat benchmark.

## Initial addon update

The Warrior data now uses these macros and bindings. The name column is what the player sees in Esc > Macros. The Macros tab labels the actual ability and shows the stored name where it differs.

| Name | Before | Updated behavior and bind |
| --- | --- | --- |
| Fight | Four Charge, stance and attack sequences starting at 4 | 1–9 starts attacks and queues Heroic Strike (RT+A / 1). From 10 it starts attacks and casts Sunder Armor. Charge and stance switching use spellbook buttons. |
| Fight pack | 20–60 Clap, Sunder, Cleave, Sunder, Sunder | 6–60 casts Thunder Clap alone on the same RT+Up / 5 bind. |
| Rend again | Standalone retry after a missed Rend | Same body and RT+Y / 4 bind. Use to apply Rend deliberately, refresh near expiry or retry a miss. |
| Hamstring | Available at 10 with a Battle-only tip | Same body and LT+RT+Left / X bind, available at 8. The tips explain Battle and Berserker, and the separate press when leaving Defensive. |
| Rage up | Bloodrage followed by Battle Shout | Bloodrage alone on LT+A / Q from 10. Battle Shout is separate from level 1 on LT+Up / G. |
| Revenge | Standalone attack with different pre-16 placement in the tips | Same body. Use RT+X / 3 from 14, with Shield Block independent. |
| Block & Revenge | Shield Block followed by a Revenge proc | Shield Block alone from 16 on RT+B / 2. Its tooltip explains the chance and charge limit. |
| Panic | Last Stand at 26–27, then a sequence with Shield Wall | Last Stand alone from 26 on LT+Y / F. Shield Wall is independent at 28 on LT+RT+Y / Shift+F. |
| New group and combat binds | No separate guide macros | Taunt at 10 (RT+Left / E), Shield Bash at 12 (LT+X / R), Cleave at 20 (RT+Down / 7), Victory Rush at 20 (LT+B / T), Challenging Shout at 26 (LT+RT+B / Shift+E) and Shield Slam at 40 (RT+Right / 6). Taunt uses the selected target for predictable controller input. Pummel and Concussion Blow stay on spellbook binds. |

- **Talent reasons.** Improved Thunder Clap now says to wait for the pack to reach you. Improved Revenge points to an independently used Shield Block. Vanguard lists the 9/12/15-Rage Charge ranks and the spellbook button. Shield Slam points to its dedicated bind.
- **Trainer notes.** Charge ranks now describe the out-of-combat and Vanguard requirements. Tactical Mastery explains 10 Rage baseline and up to 25 with the Arms talent. Shield Block describes increased chance and its block limit. Victory Rush lists the qualifying-kill window, cooldown and heal on hit.
- **Leveling tips.** The five chapters now cover early swings and Rage spending, the level-10 stance quest, pack opening and target-by-target threat, Victory Rush and surplus-Rage Cleave, separate recovery and interrupt binds, and the Shield Slam priority. The group DPS tips cover assisting the tank, Battle Shout, Execute and Pummel.
- **Upgrade.** The five reused macro names recognize their exact previous Codex bodies even when SavedVariables are absent and the client can read macro bodies. Run `/codex macros` or use **Set up macros** to update existing buttons and create newly available macros. Drag the new ones to the suggested binds. Charge from the spellbook remains the opener to test with Vanguard.

## Stance follow-up to mirror into the guide

- **Fight** uses Heroic Strike alone at 1–3. At 4–9 it Charges out of combat from Battle and queues Heroic Strike in combat. At 10–24 it enters Battle as needed, Charges, then enters Defensive in combat if learned. From 25, Vanguard allows Charge directly from Defensive and the Battle opener remains available without the talent. In combat, Fight casts Sunder once in Defensive. Charge still needs an eligible target and an out-of-combat pull. If the macro reports a Vanguard rank error, use Charge from the spellbook and note the trained rank. [Stance press report](https://eu.forums.blizzard.com/en/wow/t/warrior-stance-dance-now-triggers-micro-gcd/633220), [Vanguard rank report](https://us.forums.blizzard.com/en/wow/t/prot-warrior-charge-in-defensive-issue/2370087/3).
- **Fight pack** casts Clap directly in Battle or Defensive. From 30 it can switch out of Berserker on the first press. It chooses Defensive if learned and Battle otherwise. **Taunt**, **Shield Block**, and **Shield Wall** can enter Defensive on the first press and use the selected ability on the next. Block and Wall require a shield. Taunt still uses the selected enemy.
- **Shield Bash** can enter Battle from Berserker with a shield at 30–37. From 38 it uses Pummel in Berserker and Shield Bash with a shield in Battle or Defensive. Without a shield it can enter Berserker if learned, then Pummel on a second press once trained.
- **Guide and upgrade.** The Vanguard reason and early and group tips describe Fight and the shared interrupt. All stance-aware macros reuse their existing names and suggested binds. Put the same macros on the stance pages you use. The replaced bodies from both updates are recognized for in-place refresh.
