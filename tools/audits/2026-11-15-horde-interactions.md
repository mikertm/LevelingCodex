# Horde guide interaction audit, 2026-11-15

## Scope and method

This is the Horde half of the dialogue/prerequisite/item/event interaction audit prompted by
Chief Engineer Scooty. Sovik/Scooty is documented by the main task; this file records the other
Horde corrections. No `Data.lua`, talent, trainer, macro, TOC or engine changes were made here.

- Searched all 18 `QuestHorde*.lua` modules, including the main routes, hand-built alternates,
  copied alternates, dungeon checklists, class side guides, attunements and keys.
- The loaded baseline had 153 Horde sections, 6,551 steps and 1,644 distinct quests. Those are
  coverage inventory counts, **not** a claim that every step was individually verified in game.
- Read the relevant trigger blocks in the five dedicated reference guide A Horde files and their four
  dungeon-route counterparts. Searched the 98 Horde/shared `RegisterGuide` blocks in
  `local guide reference` for gossip, item use, repeated conversations and event starts. Shared
  Skyborne blocks also contain Alliance-only steps; these were excluded where appropriate.
- reference guide B's Horde leveling file has 52 explicit `Select` step blocks. Thirteen concern training or
  spirit-healer resurrection; the remaining 39 were examined against our routes. The Horde
  dungeon file adds 27 `Select` blocks, for 66 non-training interaction candidates including
  repeated quests. These carry 28 and 17 distinct explicit quest tags respectively; not every
  candidate belongs to an implemented Codex guide.
- Also searched the 258 leveling and 84 dungeon `use` commands, reference guide A `.use`/`.complete`
  blocks, and click/talk/escort instructions. Compared prerequisite acquisition, the trigger,
  combat/event, and post-event item/dialogue credit. Checked matching main, alternate and
  dungeon copies instead of assuming all alternates are copied automatically.
- Corrected 50 distinct Horde quest IDs below, plus non-quest instructions for starting
  Naralex's event, opening Shadowfang's courtyard and opening Alzzin's door. The 12 changed
  Horde modules include two also edited by the main task for Sovik. Text is original concise
  instruction, using game names rather than copying the reference guides' narrative.

## Local reference keys

The owner's reference files were read only. Line numbers below refer to these files as supplied
on 2026-11-15, not to Codex's edited files.

Root `local guide reference`:

| Key | File under that root |
| --- | --- |
| ZL | `local guide reference` |
| ZD | `local guide reference` |
| R | `local guide reference` |
| RM | `local guide reference` |
| RU | `local guide reference` |
| RB | `local guide reference` |

## Corrections: before -> after

Every data change from this Horde pass is listed here so the guide owner can mirror it.
Quest names and actions below are summaries of the edited instructions.

| Quest / guide | Before | After / evidence |
| --- | --- | --- |
| 91208 Coming to Terms; Deathknell (`QuestHordeTirisfal.lua`) | Find the paladin and offer aid. | Names the Frightened Paladin, directs the player through his dialogue, then to defeat him when he attacks. ZL 306-311; RU 475-480. |
| 99141 Patience; Tirisfal, all three report objectives | Ask each NPC for a report. | Explicit report dialogue for Dillinger, Kristof and Gordo. ZL 561-564, 604-609, 630-645. |
| 1886 The Deathstalkers; Silverpine | Talk to Astor, then kill him. | Ask his identity and demand the item through dialogue before the hostile fight. ZL 1494-1526. |
| 99108 Sparring Match; Mulgore | Beat three Novice Warriors or win duels. | Talk to a Novice Warrior and choose the challenge dialogue before winning three duels. ZL 1919-1923; RM 668-679. |
| 4921 Lost in Battle; Barrens | Look over the corpse. | Click the Beaten Corpse and select the further-inspection dialogue. ZL 5478-5481. |
| 2381 Plundering the Plunderers; Rogue Lockpicking | Use Wrenix's machine for two items. | Talk to the apparatus: yellow button for Thieves' Tools, red for E.C.A.C. ZL 5386-5395. |
| 1950 Get the Scoop; Mage's Wand | `/beckon`; the transformed man tells the phrase. | `/beckon`, then talk and choose the phrase dialogue. ZL 23303-23307. |
| 498 The Rescue; Hillsbrad (`QuestHorde22to30.lua`), both prisoners | Find and free each prisoner. | Marlgen's Burnished Gold Key for Tog'thar, Eston's Dull Iron Key for Drull, then click each ball and chain. ZL 6432-6456. |
| 5561 Kodo Roundup; Desolace main and alternate (`QuestHorde3040.lua`) | Tame and lead each kodo to Smeed. | Wait for Smeed's acknowledgement, then talk to the tamed kodo for credit before the next one. ZL 9531-9543. |
| 6142 Clam Bait; Desolace main and alternate | Naga carry the meat. | Loot naga, gather Giant Softshell Clams on the sea floor, and open the clams in bags for meat. ZL 9659-9668; R 96628-96635. |
| 654 Tanaris Field Sampling (`QuestHorde4050.lua`) | Use the testing kit on living basilisks, hyenas and scorpids. | Kill/loot, then use the untested samples in bags until eight acceptable samples of each kind; keep the kit. Existing power-source acceptance/timer retained. ZL 12348-12406; R 103091-103103. |
| 3520 Screecher Spirits; Feralas main | Use Yeh'kinya's flask on corpses. | Correct item name to Bramble, add item button 10699, then talk to each spawned spirit. Dungeon copy already had the talk step. ZL 12661-12667; ZD 3653-3659. |
| 2784 Fall From Grace and 2801 A Tale of Sorrow; Swamp of Sorrows | Listen to the story. | Talk again and continue every dialogue page until objective credit. ZL 13267-13272, 15682-15690; R 105271-105276, 105530-105534. |
| 3441 Divine Retribution; level-48 and level-51 copies | Listen to Kalaran's story. | Talk again and finish the vengeance dialogue for credit. ZL 15883-15888; R 109816-109822. |
| 3463 Set Them Ablaze!; Searing Gorge (`QuestHorde5060.lua`) | Use the torch inside the towers. | Equip the torch and click each Sentry Brazier atop the towers. ZL 16098-16128; R 43083-43094. |
| 4296 Tablet of the Seven; Burning Steppes | Copy the tablet. | Click it and choose the transcribe dialogue. ZL 16240-16243. |
| 4022 A Taste of Flame; Burning Steppes | Open the hoard and show Cyrus the molt. | Open the hoard, then choose Cyrus's dialogue presenting proof. ZL 16283-16288; R 18391-18399. |
| 4285/4287/4288; all three Un'Goro pylons | Go to each pylon. | Click each pylon and choose its examine dialogue. ZL 17102-17106, 17376-17380, 17413-17418. |
| 4292 The Bait for Lar'korwi; Un'Goro | Use Torwa's pouch near the earlier threshadon carcass, 68.7,56.7. | Open the pouch, use Preserved Threshadon Meat and then Preserved Pheromone Mixture on the flat rock east of the Eastern Pylon, kill and loot Lar'korwi. Add pouch item button 11568 and correct the bait site to 79.6,49.8. ZL 17039-17047; R 46408-46418. |
| 4506 Corrupted Sabers; main and hand-built `felwood-alt` | Pick the changed kitten up; lead it back. | Let it follow, return beside Winna, then talk to the following cat and select release before turning in. Both objective and turn-in texts fixed in both guides. ZL 17769-17775. |
| 5096 Scarlet Diversions; main, `plaguelands-alt` and Scholomance-key guide | Burn the tent with given items; special guide had an unconditional bottle collection row. | Pick up Flame in a Bottle from the Box of Incendiaries beside Derrington; click the tent and use the Scourge Banner afterwards. Pickup is in acceptance and objective fallback text, so ready/completed quests cannot be stranded on a consumed-bottle collection step. The pre-existing special-guide bare collection row was removed for the same reason. ZL 18315-18332. |
| 5211 Defenders of Darrowshire; sticky Plaguelands objective | Free the spirits that rise. | Talk to each spawned Darrowshire Spirit for credit. ZL 18826-18832. |
| 5742 Redemption; Tirion | Listen to his story. | `/sit`, talk again, and continue every dialogue page for credit. ZL 18856-18865; ZD 5983-5989. |
| 5902 A Plague Upon Thee; Northridge | Set the barrel down in the middle of the camp. | Click the crate inside the mill, select termite-barrel placement, then click the spawned barrel for turn-in. ZL 19021-19028. |
| 5527 A Reliquary of Purity; main and Dire Maul East | Accept from Rabine. | Ask about Dire Maul and finish his dialogue; if absent, visit Dire Maul's courtyard and return. ZL 19387-19398; R 116833-116839. The exploration condition is an established Classic prerequisite repeated by both supplied Forever guide references, not newly proven server behavior in this session. No hard availability gate was added. |
| 4507 Pawn Captures Queen; Un'Goro | Call the queen. | Use Gorishi Queen Lure at the hatchery crystal, fight guards, kill/loot queen; add lure item button 11833. R 51560-51566 and preceding summon block. |
| 8304 Dearest Natalia; both interviews | Question each NPC. | Ask about Natalia and exhaust each NPC's dialogue until individual objective credit. ZL 19792-19815. |
| 5727 Hidden Enemies; Ragefire Chasm (`QuestHordeDungeons.lua`) | Show Neeru the insignia and listen. | Choose the Burning Blade dialogue inviting him to speak frankly and continue until reaction credit. ZD 1861-1867. |
| Wailing Caverns event | Return to the Disciple and escort him. | Talk and select the event-start dialogue after killing the Fanglords, then escort. ZD 2212-2226. |
| 6981 The Glowing Shard; Wailing Caverns aftermath | Show Sputtervalve the shard. | Choose the dialogue asking about the Glowing Shard. ZD 2261-2265. |
| Shadowfang Keep courtyard | Freeing the prisoner opens the door. | Kill Rethilgore, click the cell lever, then ask Deathstalker Adamant through dialogue to unlock the courtyard. ZD 2405-2415; R 88624-88631. |
| 2278 The Platinum Discs; Uldaman (`QuestHordeDungeons3045.lua`) | Speak to the Lore Keeper. | Ask about the Earthen and follow every page until lore credit, before returning to the discs. ZD 3514-3519. |
| 2768 Divino-matic Rod; Zul'Farrak | Bly automatically attacks after Nekrum dies. | Use the key on a Troll Cage, survive the event, then talk to Bly and demand the rod to begin his fight. R 16525-16539. |
| 7046 The Scepter of Celebras; Maraudon (`QuestHordeDungeons4560.lua`) | Stand by. | Follow Celebras and click Incantations of Celebras, then wait for completion. ZD 3919-3929; ZL 15009-15016. |
| 3528 The God Hakkar; Sunken Temple | Summon/event/kill only. | Also loot and use Essence of Hakkar to fill the egg. R 11470-11483. |
| 4001 What Is Going On?; Blackrock Depths | Acceptance text briefly mentions Kharan, with no story objective row. | Add an objective row to open Kharan's cell and complete all princess dialogue before reporting to Thrall. ZD 4713-4729. |
| 4136 Ribbly Screwspigot; Blackrock Depths | Kill Ribbly away from his friends. | Talk and demand his head to start the fight, then kill him and his friends and loot. ZD 4518-4524. |
| 4002 The Eastern Kingdom; Blackrock Depths aftermath | Hear Thrall out. | Talk again and complete all dialogue before turn-in. R 18616-18621. |
| 4903 Warlord's Command; Lower Spire, Upper Spire and Onyxia | Take a normal quest directly from Goretooth. | Finish Goretooth's dialogue, receive and use Warlord Goretooth's Command from bags; add item button 12563 to all three acceptance steps. NPC waypoint retained. ZD 5259-5267, 7513-7522. |
| 4941 Eitrigg's Wisdom; all three copies | Talk to Eitrigg, then Thrall. | Complete all Eitrigg dialogue for credit before Thrall's turn-in. ZD 6667-6673, 7556-7563. |
| 5160 The Matron Protectorate; Upper Spire | Awbee asks for a delivery. | Complete Awbee's dialogue to reveal the offer. R 19161-19168. Existing location uncertainty retained. |
| 5047 Finkle Einhorn, At Your Service!; Upper Spire | Skin the Beast and talk to Finkle. | Also ask how he got inside and continue his dialogue to reveal the offer. ZD 6649-6654. Existing skinning uncertainty retained. |
| 7441 Pusillin and the Elder Azj'Tordin; Dire Maul East | Talk once and chase. | Choose dialogue at every stop, including the final fight trigger. ZD 4813-4854. |
| Dire Maul East door | No Ironbark step. | After Zevrim, talk to Ironbark and choose his door-opening dialogue. ZD 4869-4877. |
| 5526 Shards of the Felvine; Dire Maul East | Use the reliquary on the vine; label says Felvine Shard. | Loot a Felvine Shard first, then use the Reliquary of Purity in bags to seal it; label names Sealed Reliquary of Purity. ZD 4880-4889. |
| 5382 Doctor Theolen Krastinov, the Butcher; Scholomance | Accept from Eva. | Complete every page of Eva's story to reveal the offer. ZD 5676-5680, 6130-6134. |
| 6566 What the Wind Carries; Onyxia | Listen to Thrall. | Ask for wisdom and complete all dialogue before turn-in. ZD 6747-6752, 7588-7593. |
| 4742 Seal of Ascension; Upper Spire key | Accept from Vaelan. | Finish his dialogue; if he does not reveal himself, bring an Unadorned Seal and speak again. ZD 5318-5325. The fallback is corroborated Classic behavior; no hard gate added. |
| 4743 Seal of Ascension; Upper Spire key | Weaken/place seal/use Orb only. | Open Vaelan's Gift, stop damage when his will falters, place seal, control Emberstrife, use his flame on seal, then loot the Forged Seal from ground. Existing guard/level uncertainty retained. |
| 4867 Urok Doomhowl; Lower Spire | Bring pike and head and call Urok. | Use Omokk's Head at the Tribute Pile with Roughshod Pike in bags, kill waves/Urok, loot mojo. ZD 5382-5388. |

## Online corroboration

Checked 2026-11-15. These supplement the supplied Forever guide references; a Forever URL can
contain old Classic comments and does not itself prove current server scripting. No guide claim
was based only on memory.

- [Warlord's Command, Forever quest](https://www.wowhead.com/forever/quest=4903/warlords-command)
  and [Forever quest record](https://questing.wiki/wow-forever/quests/4903/) support the
  dialogue-issued item start; the latter explicitly links item 12563 to the quest.
- [Corrupted Sabers, quest text](https://www.wowhead.com/tbc/quest=4506/corrupted-sabers)
  explicitly requires clicking the returned cat to release it. The local Forever reference
  supplies the matching release dialogue.
- [Redemption, Forever record](https://wowforever.wclbox.com/en/renwu/5742) preserves the
  instruction to sit; [Classic record/comments](https://classicdb.ch/?quest=5742) explain the
  `/sit` requirement. Both supplied Forever guide paths show sitting and conversation.
- [A Reliquary of Purity](https://warcraft.wiki.gg/wiki/A_Reliquary_of_Purity) documents the
  earlier Dire Maul visit; [quest comments](https://www.wowhead.com/tbc/quest=5527/a-reliquary-of-purity)
  describe the conversation unlocking the offer. Current Forever-specific server verification
  remains an in-game check; both local Forever routes retain this prerequisite.
- [The Bait for Lar'korwi, Forever record](https://questing.wiki/wow-forever/quests/4292/)
  supplies the two-part bait and correct area; [Torwa's Pouch, Forever item](https://azeroth.wiki/forever/items/torwa-s-pouch)
  lists the two contents. This is why the old carcass waypoint was changed.
- [Tanaris Field Sampling](https://www.wowhead.com/tbc/quest=654/tanaris-field-sampling)
  describes testing the looted samples; [Forever record](https://guide.wow4ever.se/en/quests/654)
  corroborates the acceptable samples, retained kit and timed power source.
- [Giant Softshell Clam](https://warcraft.wiki.gg/wiki/Giant_Softshell_Clam) corroborates
  the underwater containers for Clam Bait. The supplied Horde reference explicitly opens the
  resulting bag item rather than treating all meat as direct creature loot.
- [The Rescue](https://www.wowhead.com/wotlk/quest=498/the-rescue) and
  [Burnished Gold Key](https://www.wowhead.com/wotlk/item=3499/burnished-gold-key) corroborate
  clicking the prisoners' locks instead of their NPC bodies.
- [Kodo Roundup, Forever](https://www.wowhead.com/forever/pt/quest=5561/arrebanhamento-de-kodos)
  corroborates talking to each delivered kodo after Smeed acknowledges it.
- [Pawn Captures Queen, Forever record](https://wowforever.wclbox.com/en/renwu/4507)
  supplies the lure and hatchery-crystal trigger.
- [Screecher Spirits, Forever record](https://questing.wiki/wow-forever/quests/3520/)
  confirms Bramble item 10699 and spirit-credit objectives; the supplied guide explicitly talks
  to each spawned spirit.
- [The God Hakkar walkthrough](https://www.icy-veins.com/wow-classic/sunken-temple-quests-guide)
  corroborates using the looted essence to fill the egg, also explicit in the supplied reference.
- [Celebras interaction report](https://github.com/cmangos/issues/issues/3180) is secondary
  Classic-era script corroboration of the clicked book, not evidence of a Forever bug.
- [Seal of Ascension](https://www.wowhead.com/forever/quest=4743/seal-of-ascension) and
  [Flames of the Black Flight](https://www.wowhead.com/forever/spell=16054/flames-of-the-black-flight)
  corroborate the controlled dragon's flame creating the forged seal object. The main task
  independently checked and corrected the equivalent Alliance sequence.

## Kept, excluded and unresolved

- Kept the Bear Form guide's existing full Great Bear conversation and Lunaclaw-spirit talk;
  it already includes both required interactions (5930/6002, ZL 22145-22185). Kept existing
  Shaman sapta/item/summoning instructions, Warlock binding circles, Affray grate trigger,
  Rogue `/salute`/two flares/pickpocket/lockbox sequence and C's solo-instance jobs.
- Did not add Cenarion Beacon/salve quests (the relevant leveling selector tags 5887), AQ scout
  reports 8534/8738/8739, Meridith's swim for 8597, Rhok'delar demons 7636, alternate faction
  Glowing Shard 3366, the unused Test of Lore path 6627, or mage-only Arcane Refreshment 7463
  just because they appeared among reference selector candidates. These are outside the
  implemented Horde chains affected by this audit.
- Did not turn training-menu selectors, resurrection skips, spell training or optional gear
  purchases into new quest tasks. Did not copy reference-guide death skips.
- Skyborne shared steps are copied from `QuestData.lua`; Alliance changes to those steps
  therefore propagate to Horde. Horde-only Illaya/Riaani listening steps do not have a
  corroborated additional gossip trigger in the supplied reference, so they remain unchanged.
- Riverglades/Shen'dralas scouting, feeding, recruitment and new pylon steps still have explicit
  uncertainty notes where the available sources do not identify the interaction. No invented
  menu choices, item IDs or event starts were added. In particular Jom-jom's start, recruited
  miners, freed scouts and Mordent's story need current in-game observations.
- Kept existing uncertainty about Winna's exact moonwell, Finkle's skinning condition, Awbee's
  position, Emberstrife's guards, the Hakkar event layout, and quest-specific Forever minimum
  levels. This audit corrects supported actions without claiming to settle those independent
  questions. Lar'korwi's old location is the one changed coordinate, supported by two supplied
  references and a Forever quest record.
- Item 12563 is attached with `withItem` to the acceptance instruction, while the NPC waypoint
  and dialogue remain visible. Setting `startItem` would hide/block that instruction before
  Goretooth gives the item; this avoids adding a separate progression-gated collection row.
- An initial idea to add standalone Flame in a Bottle collection rows was rejected during
  review: a returning player with ready/completed 5096 and a consumed bottle would be told to
  acquire another. The final form uses existing quest rows only, including the special-guide
  correction. No shared engine expansion was needed.

## Validation and in-game checks

- `git diff --check`: clean after Horde data edits.
- All 18 Horde modules compiled with `lupa.lua51`/`loadstring`; no Lua 5.1 syntax errors.
- The main task owns combined harness execution, player-visible Sovik regression, the ready/
  completed Scarlet Diversions regression, installation and final test totals. No commit,
  full harness or install was run concurrently by this audit worker.
- Prioritize current Forever checks for Sovik; then Goretooth's item-issued pickup, Rabine's
  discovery/dialogue prerequisite, all three 5096 paths with empty SavedVariables, returned
  saber release in main and alternate Felwood, Tirion's seated conversation, and the dungeon
  book/door/post-fight item triggers above.
