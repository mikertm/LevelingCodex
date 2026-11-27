# Turn-ins with nothing to hand in (2026-11-27)

Reported in game: the Alliance Stranglethorn 36-38 chapter stopped on "Turn in - Favor for Krazek"
("Give Krazek four Lesser Bloodstone Ore if you brought them"). No step ever sent the player for
the ore (miners in Arathi's Drywhisker Gorge, or the Auction House), so a player who took the
favor waited at Krazek with Return to Corporal Kaleb queued behind it.

New gates (Quests.lua): `ifItems` on an accept (shows only while your bags hold the items) and
`ifReady` on a turn-in (hidden while the quest log says the quest isn't ready). Both mark the
quest blocked, so follow-ups wait too. `tools/questgaps.py` now lists every turn-in whose quest
database objectives no step gathers; after this pass only three remain, each an item an earlier
step hands you (Raene's Cleansing's rod, The Morrow Stone's stone, the Excavation Site relic).

| Guide | Quest | Before | After |
|---|---|---|---|
| Alliance stv-36 | 627 Favor for Krazek | accept "if you can spare four ore", turn-in "if you brought them" | accept only with 4 Lesser Bloodstone Ore (4278) in bags; turn-in `ifReady`; Kaleb's pot follows only after the favor |
| Alliance duskwood | 174 Look To The Stars | accept text "buy a Bronze Tube", turn-in "if Herble had none, use Next" | `buy` step at Herble (4371); accept only with the tube; turn-in `ifReady` |
| Alliance teldrassil | 4161 Recipe of the Kaldorei | "if you already have 7 legs, otherwise Next" | accept with 7 Small Spider Legs (5465); turn-in `ifReady` |
| Alliance teldrassil | 490 Bounty: Gnarlpine Furbolg | "turn in if you have 15 fangs, otherwise Next" | turn-in `ifReady` |
| Alliance riverglades-farholde | 96081 Wound Dressings, 95184 The Sharpest of Blades | "if you have 20 Mageweave / 8 stones" | accept with the items (4338 x20, 7964 x8); turn-ins `ifReady` |
| Alliance stv-41 | 338-342 Green Hills of Stranglethorn | each chapter offered whether or not you had its pages | each chapter's accept needs its pages in bags; chapter and book turn-ins `ifReady` |
| Alliance blasted-51, Horde blasted-50 | 3501, 2521 Kum'isha | "take it only if you have one" | accept with a fragment (10593) / sphere (8244); turn-ins `ifReady` |
| Alliance wpl-51 | 7802-7804 cloth donations | turn-ins with no gate | turn-ins `ifReady` |
| Alliance felwood-52 | 3661 Favored of Elune? | "if you have them" | turn-in `ifReady` |
| Both ungoro | 4244 Chasing A-Me 01 | "without one, use Next" | turn-in `ifReady` (the escort follows only after it) |
| Both | 3764 / 3761 Un'Goro Soil | "use Next if you have too few" | turn-in `ifReady` |
| Alliance winterspring-54 | 6031 Runecloth | "skip it unless you have the cloth" | accept with 30 Runecloth (14047); turn-in `ifReady` |
| Both silithus-59 | 8323 True Believers | "if you are short, use Next" | turn-in `ifReady` |
| Both warlock | 8420 Hot and Itchy | optional turn-in | turn-in `ifReady` |
| Alliance paladin | 1644 / 1648 Tome of Divinity | turn-in text "if short, buy some" | `collect` step for 10 Linen Cloth (2589) before the hand-in |
| Horde paladin | 94434 A Lesson in Divinity | same | same |
| Horde durotar | 96873 A Pain in the Neck | turn-in with no residue step | turn-in `ifReady` |
| Horde sun-rock | 5052 Blood Shards of Agamaggan | "hand him a shard from the quilboar you killed" | `collect` step for a Blood Shard (5075) at the Bristleback camp north of Camp Taurajo (quest database drops) |
| Horde badlands-37/39 | 705 Pearl Diving | "if you brought nine Blue Pearls" | accept with 9 Blue Pearls (4611); turn-in `ifReady` |
| Horde hinterlands-48 | 7842 Another Message to the Wildhammer | "if not, use Next twice" | accept with 10 Long Elegant Feathers (4589); turn-in `ifReady` |
| Horde azshara-52 | 4300 Bone-Bladed Weapons | "if you brought them" | turn-in `ifReady` |
| Horde searing-51 | 4022 A Taste of Flame | molt instruction folded into the accept, no objective | objective step "present your proof", as the Alliance guide has |
| Gnomeregan (both) | 2948 / 2950 ring upgrades | turn-in with no gate | turn-in `ifReady` |

Prerequisite lines `questgaps.py` still prints are known differences already recorded: Wild Hearts
(2026-11-10-horde-tirisfal-silverpine.md), Supplies for the Crossroads (taken with Disrupt the
Attacks), the druid 26/27 swap (QuestClassData.lua comment), the paladin and mage referrals.
