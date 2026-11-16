# Alliance interaction audit - 2026-11-15

This audit addresses dialogue that reveals quests, dialogue objectives, supplied-item prerequisites, object menus, multi-stage item uses and event triggers. Instructions were written afresh; the reference guides were read-only and their route prose was not imported.

## Scope and method

The baseline Alliance route loads 172 sections: 43 main, 20 alternate, 30 dungeon, 70 class and 9 special; 6,095 loaded steps and 1,828 unique quest IDs. These are inventory totals, **not** a claim that every step was individually verified against the live server.

The nine Alliance guide files inspected were `QuestData.lua`, `QuestAlternateData.lua`, `QuestData3040.lua`, `QuestData4050.lua`, `QuestData5060.lua`, `QuestDungeonData.lua`, `QuestDungeonData3060.lua`, `QuestClassData.lua` and `QuestSpecialData.lua`. Class insertions and copied alternate/dungeon/special steps were inspected through the loaded Lua tables, not just text searches. No class guide changes were necessary for the checked interactions.

The reference inventory covered 13 reference guide A files: the seven top-level `Alliance*.lua` files, four dungeon `Alliance*.lua` files, and the two `local guide reference` files. There were 159 applicable `RegisterGuide` blocks, including shared Skyborne and Alliance sections; explicitly Horde-only steps were excluded. Candidate blocks were joined to quest IDs present in the loaded Alliance route:

| Candidate kind | Matching block occurrences | Distinct quest/target/item patterns |
| --- | ---: | ---: |
| `.gossip*` / `.skipgossip*` | 121 | 57 |
| `.use` | 525 | 222 |
| Event/escort/summon/emote hints | 144 | 66 |

The reference guide B Alliance leveling file added 86 matching dialogue/emote blocks involving 84 quest IDs; the Alliance dungeon file added 43 involving 24 quest IDs. These counts include repeated routes, bank/spirit-healer conversations, ordinary trainer menus and role-specific hints. They are search candidates, not additional omissions. Deduplication used quest ID, target/mob and used item; it does not equate different dialogue sequences merely because their NPC is the same.

For manual review, compare each candidate's action order with the route's accept/complete/turn-in steps and any item gate. Inspect surrounding steps so that nearby equipment, Hearthstone use, escort maintenance and item-started follow-ups are not mistaken for the current quest's required action. Check important omissions against public quest/item text or another independent reference. Keep uncertain server behavior as an in-game check rather than a new programmatic prerequisite.

## Local reference keys

All paths below are under the read-only root:

`local guide reference`

- **R**: `local guide reference`
- **ZD**: `local guide reference`
- **ZL**: `local guide reference`

Line numbers refer to the supplied, unchanged reference files. A `start` entry in this addon's `QuestNPCData.lua` is also useful evidence that a quest begins with an NPC rather than a dropped item.

## Corrections for mirroring into the guides

| Quest / place | Before | After / reason | Local evidence |
| --- | --- | --- | --- |
| 92596 The High Order, Shen'dar | Sit and talk to Rathiril. | Continue through the dialogue to complete the objective. | R 1106-1115 |
| 92849 The Missing Scholar, Valanaar | Talk to Fillion and inspect a bedroll; arrow already at bedroll. | Find Fillion in the cave at 50.7, 65.4, choose to carry him, avoid birds, and return him to the bedroll at 52.1, 69.4. | R 3642-3666 |
| 93159 The Strange Hermit | Accept and immediately turn in. | Complete the Hermit's dialogue before turning in and taking follow-ups. | R 5848-5861 |
| 94897 The Fate of a Loved One | Find Resaan in the ruins. | Interact with Resaan's body and choose to retrieve the heirloom. | R 5902-5911 |
| 5561 Kodo Roundup | Tame a kodo and bring it to Smeed. | Bring one at a time, wait for Smeed's acknowledgement, then talk to that Tamed Kodo for credit before fetching another. | R 31349-31364; 32433-32445 |
| 3520 Screecher Spirits | Use an unnamed/wrongly named spirit flask on corpses. | Use Yeh'kinya's Bramble, item 10699, then talk to each released spirit. Add the existing item-use metadata to this step. | R 40385-40395; ZD 8343-8348 |
| 3441 Divine Retribution, both Searing Gorge routes | Listen to Windblade's story. | Reopen the NPC conversation, ask about the vengeance and continue all dialogue pages. | ZL 14679-14685; ZD 4624-4629 |
| 3463 Set Them Ablaze!, main and inherited alternate | Use the torch inside each tower. | Equip the Torch of Retribution, then click each tower platform's Sentry Brazier. | ZL 14880-14910 |
| 2801 A Tale of Sorrow | Listen to the story. | Talk to the Fallen Hero and continue every page until the objective updates. | ZL 15129-15137 |
| 2879 The Stave of Equinex | Energize the stave at the monolith. | First collect the essences of Samha, Imbel, Lahassa and Byltan, then use Troyas' Stave (9263) by the monolith. | R 45200-45209; 45230-45250; ZL 16056-16076 |
| 2845 Wandering Shay | Ring the bell during the escort, with no pickup. | At acceptance, take the bell from the chest beside Shay before leaving; keep using it when she wanders. | R 45211-45227; ZL 16079-16085 |
| 4292 The Bait for Lar'korwi | Open Torwa's Pouch and kill Lar'korwi. | Open the pouch at the flat rock behind the Eastern Crystal Pylon; use Preserved Threshadon Meat, then Preserved Pheromone Mixture, to summon him. | ZL 16366-16373 |
| 3702 The Smoldering Ruins of Thaurissan | Listen to Archesonus. | Tell the historian you are ready, then finish all dialogue pages. | ZL 17405-17413; ZD 4498-4504 |
| 4022 A Taste of Flame | Show Cyrus the molt. | With the already-routed molt in the bags, choose Cyrus's proof dialogue. | ZL 17498-17502 |
| 4296 Tablet of the Seven | Copy the tablet. | Interact with the tablet and choose its transcription menu entry. | ZL 17616-17619; R 48830-48836 |
| 4185 The True Masters | Speak with Prestor, then Bolvar. | Continue Prestor's full dialogue until the objective completes, then return to Bolvar. | ZL 17687-17695; ZD 7710-7716 |
| 4224 The True Masters | Hear Ragged John's story. | Ask about Marshal Windsor and continue all dialogue pages until credit. | ZL 17751-17765; ZD 7732-7738 |
| 5742 Redemption | Listen to Tirion. | Type `/sit` before opening his dialogue, choose to hear the tale and finish the conversation. | ZL 18293-18302; ZD 6253-6261 |
| 5211 Defenders of Darrowshire | Kill enemies and free their spirits. | Talk to each spawned Darrowshire Spirit to free it and receive credit. | ZL 18268-18273 |
| 5904 A Plague Upon Thee | Place a barrel in the lumber camp. | Click the Northridge Lumber Mill Crate, choose placement, then click the newly spawned Termite Barrel for turn-in and follow-up 6389. | ZL 18473-18480; R 50474-50480 |
| 5382 Doctor Theolen Krastinov, main and Scholomance pickups | Accept Eva's quest. | Ask why Eva is there and finish every page of her story to reveal her quest offer. | ZD 5947-5952; 6400-6405; R 12529-12535 |
| 5527 A Reliquary of Purity | Bare accept from Rabine. | Finish Rabine's Dire Maul conversation to reveal the offer. If the topic is absent, visit Dire Maul first and return, or skip the detour for now. This is advice, not a new hard gate. | ZL 18741-18752; R 51126-51132 |
| 4901 Guardians of the Altar | Protect Ranshalla while she lights the torches. | The player must click each Fire of Elune while she channels, then click the altar when prompted. | ZL 17230-17243 |
| 4507 Pawn Captures Queen | Summon and kill the queen, with no trigger named. | Use Gorishi Queen Lure (11833) at the Gorishi Silithid Crystal in the hive, defeat the waves and loot the queen's brain. | R 51552-51566 |
| 8304 Dearest Natalia, both objectives | Question Frankal/Rutgar. | Continue each dwarf's entire Natalia conversation until that objective completes. | ZL 19045-19067; R 51874-51889 |
| 2278 The Platinum Discs | Speak to a watcher before accepting; then activate discs. | Accept at the Discs of Norgannon, complete all Lore Keeper dialogue, then click the discs again and take the faction delivery before leaving. One complete step inserted in the existing order. | ZD 3709-3715; R 10010-10014 |
| 6981 The Glowing Shard | Show Sputtervalve the shard. | Choose Sputtervalve's Glowing Shard gossip beside Ratchet's flight master until the objective completes. | ZD 2104-2109; R 20564-20569 |
| 2768 Divino-matic Rod | Kill Bly after the pyramid event. | Recover with the group, then demand the rod through Bly's dialogue to start the fight. | R 10326-10334; 10342-10348 |
| 7067 The Pariah's Instructions | Kill outer-cave khans and combine pieces. | Kill the Nameless Prophet for Amulet of Spirits (17757); use it on all five khan spirits before fighting them, three outside and two inside; combine all five gems. | ZD 3988-3991; 4007-4011; 4021; 4039; 4060; 4093-4101 |
| 7046 The Scepter of Celebras | Wait for a ritual. | Follow Celebras and click Incantations of Celebras to progress the ritual, then wait. | ZD 4119-4125; ZL 14372-14379 |
| 3528 The God Hakkar | Start the egg event, extinguish flames, kill Avatar. | Also loot and use the Avatar's Essence of Hakkar to fill the egg. | ZD 4440-4446; R 11472-11476 |
| 4342 Kharan's Tale | Hear him out. | Talk to Kharan and complete every dialogue page. | ZD 4827-4832; R 11796-11799 |
| 4136 Ribbly Screwspigot | Kill Ribbly in the bar. | First use Ribbly's hostile dialogue to start the fight, then kill the group and loot the head. | ZD 4898-4903; R 11927-11932 |
| 4867 Urok Doomhowl | Find an unnamed spear/challenge and summon Urok. | Loot Omokk's Head and the Roughshod Pike, use the prepared summon at Urok's Tribute Pile, defeat waves and loot Mojo. | ZD 5549-5554; 5636-5639; 5655-5667; R 12145-12150 |
| 7441 Pusillin | Speak once and chase until he gives up. | Talk at every stop; the final dialogue starts the fight, then loot the book and Crescent Key. | ZD 5095-5135; R 13149-13154 |
| Dire Maul East door | No instruction to release the gate. | Zevrim's boss tip now says to talk to Ironbark after Zevrim dies and ask him to open Alzzin's door. | ZD 5151-5158 |
| 5526 Shards of the Felvine | Use Reliquary on the Felvine; objective label was shard. | Loot a shard after Alzzin, then use the Reliquary in the bags to create the Sealed Reliquary of Purity; correct the objective label. | R 13165-13166; 13196-13199; ZD 5162-5170 |
| 6402 Stormwind Rendezvous | Turn-in target was Squire Rowe. | Tell Rowe you are ready, wait for Reginald Windsor, then turn in to Windsor (73.6, 91.0). | R 12037-12046; ZD 7844-7851; QuestNPCData's quest recipient |
| 6403 The Great Masquerade | Escort directly to the throne room. | When Windsor stops before the keep, talk to him and confirm readiness again to continue the event. | ZD 7852-7865 |
| 4742 Seal of Ascension | Accept first; collect unadorned seal afterward. | First obtain the Unadorned Seal, bring it to the disguised Scarshield Infiltrator, let Vaelan reveal himself and finish the dialogue to unlock the quest. Keep that seal while collecting the three boss gems. | ZD 5592-5603; public Forever LBRS guide below |
| 4743 Seal of Ascension | Use the seal on weakened Emberstrife. | Open Vaelan's Gift, stop damage when his will falters, place the seal, use the Orb of Draconic Energy on the drake, use his flame on the seal and loot the forged result. | Public quest/item text below; no complete 4743 walkthrough found in supplied Alliance files |
| 5160 The Matron Protectorate | Incorrect `startItem = 12923`; accept gated behind owning Awbee's Scale. | NPC pickup from Awbee after conversation; the scale is supplied on acceptance. Remove both item-start metadata and the accept's item-use wrapper. | ZD 7010-7016; QuestNPCData 5160 starts at NPC 10740 |
| 5047 Finkle Einhorn, At Your Service! | Incorrect `startItem = 12710`; accept gated behind owning supplied flesh; no skinning trigger. | Arrange for The Beast to be skinned, talk to the revealed NPC and finish dialogue. Accept the quest to receive the flesh sample. Remove both item-start metadata and item-use wrapper; update Beast's tip. | ZD 7018-7034; QuestNPCData 5047 starts at NPC 10776 |

Files changed: `QuestData.lua`, `QuestData3040.lua`, `QuestData4050.lua`, `QuestData5060.lua`, `QuestDungeonData.lua`, `QuestDungeonData3060.lua`, `QuestSpecialData.lua`. `Data.lua` was not changed. The complete-step addition for 2278 is the only route-step insertion. Optional/elite/dungeon grouping and route order are retained; source changes automatically propagate to existing copied routes (including Stratholme, Zul'Farrak, Blackrock Depths, Dire Maul East and the Onyxia/late-game alternate routes).

## Public corroboration

These sources were browsed on 2026-11-15. Classic-era evidence is identified as such; a live Forever server behavior was not inferred just from an item or quest ID existing in the client.

- 92849: [Forever objective record](https://realmfirst.net/world-of-warcraft-forever/quests/the-missing-scholar-92849/) explicitly includes carrying Fillion to safety. [ForeverDB's recorded completion text](https://www.foreverdb.app/en/forever/quests/92849/the-missing-scholar) describes the rescue.
- 93159: [Forever XP](https://www.forever-xp.com/quests/93159/) records learning about the Hermit as the objective.
- 94897: [Wowhead Forever](https://www.wowhead.com/forever/quest=94897/the-fate-of-a-loved-one), [corpse/menu walkthrough](https://allthings.how/world-of-warcraft-the-fate-of-a-loved-one-guide-resaan-s-heirloom/).
- 5561: [Classic quest and credit interaction](https://www.wowhead.com/classic/quest=5561/kodo-roundup).
- 3520: [Classic quest text](https://www.wowhead.com/classic/quest=3520/screecher-spirits) distinguishes revealing the spirit with the bramble from touching it to collect its essence.
- 3441: [Classic-derived quest conversation](https://www.wowhead.com/tbc/quest=3441/divine-retribution); [Forever quest record](https://questing.wiki/wow-forever/quests/3441/).
- 3463: [Classic quest and brazier instructions](https://www.wowhead.com/classic/quest=3463/set-them-ablaze).
- 2879: [Classic quest text](https://classicdb.ch/?quest=2879) requires all four flame essences before energizing the stave.
- 2845: [Classic quest text](https://www.wowhead.com/classic/quest=2845/wandering-shay) explicitly requires obtaining Shay's Bell from the chest.
- 4292: [Classic quest](https://www.wowhead.com/classic/quest=4292/the-bait-for-larkorwi); [Forever Un'Goro route record](https://questing.wiki/wow-forever/leveling/ungoro/) confirms both pouch contents in sequence.
- 5742: [Classic quest](https://www.wowhead.com/classic/quest=5742/redemption), [quest dialogue record](https://classic.warcraftdb.com/data/quest/5742).
- 5904: [Classic quest/object interaction](https://www.wowhead.com/classic/quest=5904/a-plague-upon-thee); [Forever text, explicitly Classic reference](https://forever-tavern.com/quests/world/5904-a-plague-upon-thee/).
- 5382: [Wowhead Classic dungeon quest guide](https://www.wowhead.com/classic/guide/classic-wow-stratholme-dungeon-quests) and [Basin Wiki](https://www.theamazonbasin.com/wiki/index.php/Scholomance) both explain that Eva's story reveals the offer.
- 5527: [Classic quest comments](https://www.wowhead.com/classic/quest=5527/a-reliquary-of-purity), [Warcraft Wiki](https://warcraft.wiki.gg/wiki/A_Reliquary_of_Purity). Prior Dire Maul discovery is Classic-derived and corroborated by both supplied Forever guide implementations. No hard visit gate was added.
- 4901: [Classic quest text](https://www.wowhead.com/classic/quest=4901/guardians-of-the-altar) explicitly requires the player's help lighting each torch.
- 4507: [Gorishi Queen Lure tooltip](https://www.wowhead.com/classic/item=11833/gorishi-queen-lure) and [quest description](https://www.wowhead.com/tbc/quest=4507/pawn-captures-queen).
- 8304: [Recorded quest conversations](https://www.wowhead.com/tbc/quest=8304/dearest-natalia).
- 2278: [Quest text and conversation order](https://www.wowhead.com/wotlk/quest=2278/the-platinum-discs); [Forever record](https://questing.wiki/wow-forever/quests/2278/).
- 6981: [Quest and Sputtervalve dialogue](https://www.wowhead.com/wotlk/quest=6981/the-glowing-shard).
- 2768: [Bly's hostile dialogue](https://warcraft.wiki.gg/wiki/Sergeant_Bly), [quest comments](https://www.wowhead.com/tbc/quest=2768/divino-matic-rod).
- 7067: [Forever Maraudon quest guide](https://www.warcrafttavern.com/forever/guides/maraudon-quests/), [The Pariah's Instructions item](https://www.wowhead.com/item=17781/the-pariahs-instructions). Independent review supplied this corroboration.
- 4136: [Ribbly's hostile gossip](https://warcraft.wiki.gg/wiki/Ribbly_Screwspigot).
- 4867: [Forever quest record](https://questing.wiki/wow-forever/quests/4867/) distinguishes the old two-item summon from merely killing Omokk.
- Dire Maul door: [Classic Dire Maul East guide](https://www.warcrafttavern.com/wow-classic/guides/dire-maul-east), [Conservatory](https://warcraft.wiki.gg/wiki/Conservatory).
- 5526: [Quest text](https://www.wowhead.com/wotlk/quest=5526/shards-of-the-felvine), [Forever record](https://www.forever-xp.com/quests/5526/).
- 6402: [Forever route record](https://forever-xp.com/quests/6402/), [Forever Onyxia walkthrough](https://wow.gg/guides/onyxias-lair-attunement-alliance). 6403's second readiness stop is corroborated by [the Classic chain notes](https://classicdb.ch/?quest=6502).
- 4742: [Warcraft Tavern Forever LBRS quest guide](https://www.warcrafttavern.com/forever/guides/lower-blackrock-spire-quests/) explicitly places the Unadorned Seal before Vaelan's offer.
- 4743: [Classic quest text](https://www.wowhead.com/classic/quest=4743/seal-of-ascension), [Orb tooltip](https://www.wowhead.com/classic/item=12300/orb-of-draconic-energy), [Emberstrife interaction](https://www.wowhead.com/classic/npc=10321/emberstrife).
- 5160: [Forever record: Awbee supplies the scale](https://senseos.gg/wiki/wow-forever/quests/5160/the-matron-protectorate/), [Awbee's Scale](https://warcraft.wiki.gg/wiki/Awbee%27s_Scale).
- 5047: [Forever record: NPC pickup and supplied flesh](https://questing.wiki/wow-forever/quests/5047/). This record calls the NPC Pip Quickwit; local reference guides and the addon's NPC data still call it Finkle Einhorn. No rename or level change was made in this interaction fix.

## Checked without changes / remaining limits

- Farsen's Watch (96392), Gyromast's Revenge (2078), Great Bear Spirit (5929), Body and Heart (6001), Get the Scoop (1950), The Touch of Zanzil examination (2608), taming rods, summoning circles and many item-started follow-ups already name their required interaction. Their reference dialogue macros do not by themselves justify a new step.
- The Camping 101 `/sit` quests already tell the player to sit until Boosted Rest. Normal trainer/merchant menus, bank interactions, resurrection shortcuts and optional equipment uses were not added as new route requirements.
- Cyrus's route intentionally carries a molt from the Searing Gorge hoard. No alternate no-molt drake-fight branch was inserted; the fix only makes that route's proof conversation explicit.
- The Videre Elixir/Gregan handling has existing uncertainty about quest 4041 and official Hardcore variants. The audit did not replace those notes with an unverified Forever branch.
- reference guide A's Urok step says to use the pike; reference guide B explicitly uses Omokk's Head with the pike carried. The corrected instruction collects both and follows the latter sequence. Confirm the clickable item and event behavior in Forever.
- Older sources vary on Finkle/Pip's name, minimum level, skinning skill and tools. The quest is clearly an NPC pickup and the flesh is supplied; only those confirmed facts and the skinning reveal were corrected. Confirm current skill/tool requirements in-game.
- Prior Dire Maul discovery for 5527 remains a Classic-derived, guide-corroborated prerequisite, rather than a separately observed live Forever condition.

## Verification and owner checks

The edited data files were loaded in Lua 5.1 with the full data load order; all 172 Alliance sections loaded and the added 2278 objective appeared between its accept and turn-in. Inherited copies of the changed instructions and the new item metadata were inspected in the loaded tables. The root task owns the combined full harness, player-visible regression scenarios and installation; this subtask did not run a competing full harness or install a separate build.

The root task added player-visible `questAwbeePickup` and `questFinklePickup` regressions. With the original four item-gating lines temporarily restored, both UI runs failed because the NPC pickup was hidden before the supplied item was owned. The two metadata fixes and two direct-NPC accept steps were reapplied only after that red run and the root's greenlight. The final harness result belongs to the root task's combined validation.

In game, check: Fillion's pickup/carry/drop-off; Resaan's corpse menu; kodo and screecher credit after dialogue; the four Equinex flames; Eva/Rabine/Vaelan offers before accepting; the termite crate and spawned barrel; the Lore Keeper lecture; the Maraudon amulet and Celebras ritual; Urok's summon; Pusillin's repeated stops and Ironbark's gate; Hakkar's final essence; Windsor's two readiness points; Emberstrife's controlled breath; and Awbee/Finkle pickups with neither supplied quest item already in the bags.
