# Alliance Hunter and Rogue class quests, levels 10-30

The 11 side guides in QuestClassData.lua cover Dwarf and Human taming, Rogue equipment, lockpicking, poisons and solo heists. The Night Elf referral The Apple Falls (2241) moved into the Destiny Calls guide so it can be picked up after leveling.

## Eligibility and evidence

- Alliance Hunters are Human, Dwarf, Night Elf and High Order Skyborne. Alliance Rogues are Human, Dwarf, Gnome, Night Elf and High Order Skyborne. The cached `ChrRaces` puts High Order Skyborne at race bit 32. The legacy Alliance Rogue records use mask `4294967373` (bits 0, 2, 3, 6 and 32) and class mask 8. The Dwarf taming records use race mask 4 and Hunter class mask 4. The new Elwynn taming records use the Alliance race mask and Hunter class filter. The Elwynn side guide targets the Human start because the other Hunter starts have their own routes. [Blizzard race and class matrix](https://worldofwarcraft.blizzard.com/en-us/news/24304075/)
- Checked all 32 new quest IDs in cached `QuestV2.csv` and `tools/reference/forever.json` for `1.60.1.70862`. Reused the scratch `hr_q.py`, `hr_npc.py`, `hr_list.py`, `hr_forever.txt` and `class_brief.md`. Compared endpoints, race/class filters, levels, rods, objectives and sequencing with the QuestieDB `0f7d8ad` base, trace and fix files. The facts tool only merges the packed base and trace rows, so the expanded Forever base and fix files were read directly where the tool returned partial or missing records. [QuestieDB revision](https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf)

## Hunter

| Side guide | Race and level | Quests in order |
|---|---|---|
| Taming in Dun Morogh | Dwarf, 10 | `6064 -> 6084 -> 6085 -> 6086` |
| Taming in Elwynn | Human, 10 | `94792 -> 94863 -> 94864 -> 94793` |

- Dwarf uses Grif Wildheart in Kharanos, with three distinct rod item IDs for Large Crag Boar, Snow Leopard and Ice Claw Bear. Belia Thundergranite in Ironforge handles the final pet training. Grif can start the taming directly. The alternate Hunter's Path referrals `6074/6075/6076` are omitted as tracked steps, and Grif's first step tells players to hand in a referral they already picked up. [Dwarf quest record](https://www.wowhead.com/classic/quest=6064/taming-the-beast) [Forever Hunter class quests](https://questing.wiki/wow-forever/classes/hunter/) [Forever pet feeding](https://www.zockify.com/forever/hunter/feed-pet/)
- Human uses Josephine Carson's cached position at **42.77, 66.38**, which differs from the existing generic Goldshire training marker at **41.1, 66.2**. Each rod ID comes from the expanded Forever base. The fixes confirm the order Rockhide Boar, Gray Forest Wolf, Young Forest Bear, then pet training with Isaac Chan at **41.79, 66.38**. [Forever Hunter quest list](https://questing.wiki/wow-forever/classes/hunter/) [Forever Hunter pets](https://wowfdb.com/classes/hunter/pets/)
- The existing Night Elf chain `6063 -> 6101 -> 6102 -> 6103` and Skyborne chain `94978 -> 94979 -> 94013 -> 94050` cover the same unlocks. Skyborne `94007` is the optional referral from Elayaa in Shen'dar to Quel'ana in Valanaar. Both existing chains go directly to the taming trainer. [Forever Hunter quest list](https://questing.wiki/wow-forever/classes/hunter/)

## Rogue

| Side guide | Race and guide level | Quests in order |
|---|---|---|
| Snatch and Grab | Human, 10 | `2205 -> 2206` |
| Road to Salvation | Dwarf and Gnome, 10 | `2218 -> 2238 -> 2239` |
| Destiny Calls | Night Elf, 10 | `2242` after `2241` in the same side guide |
| Lockpicking | All five, 16 | Human `2300`, Dwarf/Gnome `2299 -> 2298`, Night Elf `2259 -> 2260`, Skyborne starts at Renzik. All then `2281 -> 2282`. |
| Poisons and the Zanzil Cure | All five, 20+ | `2360 -> 2359 -> 2607 -> 2608 -> 2609` |
| The Horn of Xelthos | All five, 20+ | `78261 -> 78307` |
| Ravenholdt Invitation | All five, 24 | `6681` |
| Syndicate Sabotage | All five, 24 | `96779` |
| The Eye of Bhossca | All five, 30 | `78676 -> 78699` after the Horn payment |

- **Blade of Cunning.** The broad Alliance mask permits the legacy races and High Order Skyborne in the data. The three early chains are presented by their documented racial starting trainers because their introductory quests are mutually exclusive. I found a supported Skyborne route from Renzik at level 16 and from Shaw at level 20. Skyborne access to Keryn's level-10 dagger chain remains unconfirmed, so the snippet leaves it out for that race. `92483` is already in the Skyborne starter route. [Forever Rogue class quests](https://www.icy-veins.com/wow-forever/rogue-class-quests) [Alliance Skyborne route](https://www.foreverwisp.com/guides/wow-forever-alliance-skyborne-leveling-guide)
- **Lockpicking.** The level-16 referrals keep their cached prerequisites `2205`, `2218` and `2241`. The steps direct players who are already near Stormwind to try Renzik first. All five referral IDs are marked as breadcrumbs so the earlier rows drop out once `2281` is in the log or completed. Level 16 is the trainer visit and the quest minimum for Alther's Mill. The spell reference's level 1 for spell `1804` is the ability record. Lucius supplies Thieves' Tools and the lockbox target is skill 25. The guide covers practice boxes, the heavy bronze fallback and Everstill footlockers. [Forever Lockpicking guide](https://www.zockify.com/forever/rogue/lockpicking/) [Lock and skill data cross-check](https://forg.gg/en/forever/tips/lockpicking)
- **Poisons.** The key is a quest objective. Pick Lock opens the chest. Public Forever guides give thresholds of 70 and 75 for the Alliance chest, with beta reports around 75-80. The route calls 80 a preparation target. It includes the optional Zanzil cure, `/lay`, the shop thread and the three purchased or crafted materials. The cached guide text and public records support Poison crafting and Recipe: Thistle Tea from the tower turn-in. [Forever poison quest and cure](https://www.zockify.com/forever/rogue/poison-quest/) [75-skill route](https://www.icy-veins.com/wow-forever/rogue-class-quests) [Beta chest report](https://www.reddit.com/r/wowforever/comments/1x50466/rogue_poisons_quest_question/)
- **C's solo jobs.** The Horn and the Eye include both separate payment IDs and instructions for the mail break. The Horn uses level 20 for the reported invitation and level 23 for the quest. The Eye uses level 30 for the reported invitation and level 35 for the quest. QuestieDB's nominal minimums are 1 and 25 respectively. `78270` Goblin Lockpicks appears in the Forever traces and public records but is absent from the cached client quest ID set. Veenix's exchange is described as a manual objective of `78261` so the route has a usable charge path without a tracked `78270` row. The two jobs are solo even though their objectives are inside dungeons. [Horn walkthrough](https://www.zockify.com/forever/dungeons/shadowfang-keep/) [Goblin Lockpicks record](https://www.wowhead.com/forever/quest=78270/goblin-lockpicks) [Eye walkthrough](https://www.zockify.com/forever/dungeons/scarlet-monastery/) [Forever player walkthrough with mail timing](https://www.wowhead.com/forever/quest=78676/the-eye-of-bhossca)
- **Ravenholdt.** `6681` is the mailed invitation and Rite of Cunning. `96779` is a separate class quest at the manor, with no hard link to the invitation in the cached record. The later Myrokos jobs `96781-96786` have quest levels 34-36 even though base rows list minimum 24. They fall outside this leveling band. `6701` Syndicate Emblems is both quest level 60 and absent from the cached client ID set. [Forever Ravenholdt invitation](https://senseos.gg/wiki/wow-forever/quests/6681/the-manor-ravenholdt/) [Syndicate Sabotage record](https://azeroth.wiki/forever/quests/syndicate-sabotage) [Later Ravenholdt jobs](https://forg.gg/en/forever/tips/rogue-quests)
- **Horns of Nez'ra `2358`.** The ID and inherited QuestieDB record exist. Public Forever records mostly carry forward Classic data, the Forever Wowhead quest page returned 404, and Classic players reported no offer from Arantir. I left it out pending a confirmed live offer in Lakeshire. [Inherited Forever record](https://forevermastery.com/en/quests/2358) [Classic availability reports](https://www.reddit.com/r/classicwow/comments/cyrag7/)

## Verification

- The full harness and `tools/questroute.py audit` passed in a temporary repository snapshot. The full harness reported zero failed runs.
- The final ASCII snippet loaded with the current route and class data in Lua 5.1. The route audit reported zero errors and the same seven pre-existing Dun Morogh and Duskwood warnings as the baseline. All 32 added quest IDs are unique, appear in both client inputs, and have no overlap with the existing route.
- Targeted mock checks on the final snippet covered eleven class/race combinations, Dwarf pet training, the Horn's manual objective advances and payment, and return to the original leveling step after completion.

## In-game checks

1. At level 10, confirm the six rod uses across Human and Dwarf, the training hand-ins and the Goldshire pickup marker. Verify the temporary pet has cleared before accepting a new tame.
2. On a High Order Skyborne Rogue, confirm Renzik and Shaw offer `2281` and `2360`. Try Keryn at 10 to establish whether Skyborne can also use the Goldshire dagger route. On a legacy race, check the referrals and confirm they disappear from the guide after accepting `2281` directly.
3. At the mill and tower, record the lock tooltips and practice-box skill-up behavior. Verify the key still counts separately, the tower turn-in grants the skill and recipe, and the Doc chain removes the debuff.
4. Confirm both mail and payment gates, Veenix's current interaction, the solo dungeon paths and the Rite of Cunning trigger. Record whether `96779` is offered before turning in the invitation.
