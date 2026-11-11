# Westfall, Redridge and Duskwood gaps (12-30)

This file covers quests that reference A's Forever guides route in Westfall 13-15, Redridge 19-20, the Mage AoE Westfall, Redridge and Duskwood chapters, Duskwood/Redridge 24-27 and Duskwood 29-32, where the Codex previously had no step. Facts come from `tools/questfacts.py` (QuestieDB Forever 0f7d8ad) and the Forever client reference. The references were read only to check order and grouping. Reference A `.goto` world coordinates were converted to map percentages with Marshal Marris, Sven Yorgen and Felicia Maline as reference points; each conversion matched the cached NPC position to within 0.01. Every added ID is in the client reference.

Sections touched: `westfall`, `duskwood` (QuestData.lua), and `redridge-late` and `duskwood-late` (QuestAlternateData.lua). `lakeshire` is unchanged.

## Added

### Westfall (`westfall`)

| Quest | Where | Why there |
|---|---|---|
| Keeper of the Flame 103, The Coastal Menace 104 | After intercepting the Defias Messenger (142) near Moonbrook, go to Captain Grayson at the lighthouse (30.0, 86.0). Accept both, kill Old Murk-Eye on the beach to the north (29.3, 76.0), turn in both, then return to Gryan. | Reference B's 19-20 Westfall pass visits the lighthouse at the same point. The Flasks of Oil are ordinary Harvest Golem loot, so the earlier golem step now says to keep five. If you are short, the fallback is the golem cluster east of Moonbrook (46.9, 67.2). `requiredRaces` is 0 (no data) for both quests, so they are treated as all-Alliance. |

### Duskwood main (`duskwood`)

| Quest | Where | Why there |
|---|---|---|
| Look To The Stars 174, 175, 177 | At the first return to Darkshire, buy a Bronze Tube from Herble Baubbletump (78.0, 48.3, limited stock, also mentioned in reference A), then accept and turn in 174 and accept 175 from Viktori. At Mary's house (the 149 turn-in), complete 175 and accept 177. Kill the Insane Ghoul at the Tranquil Gardens chapel (80.9, 72.0), then turn in 177 to Viktori with the Grual/Eva turn-ins. | Mary and the chapel are both south-east of town on that loop. The pickup can't be at the first hub because the Dagger scenario (a level 24 who already has the hub quests) must go straight to the west loop. The Insane Ghoul is level 26, so the text allows Next. |
| Seasoned Wolf Kabobs 90 (optional) | Accept from Chef Grual at the first hub. Save flanks during Lars's wolves (`along` 226). Turn in with Jitters' Growling Gut. | It requires Cooking 50 (Reference A `.skill cooking,<50`), so the quest is marked optional, like the other profession pickups. |
| Grant's Shield 79362 | Item 281147 (`startItem`), dropped by the Lost Knight ghost at Raven Hill Cemetery (from reference A). Accept and loot Grant's Mace during the Night Watch southern graves step (57). Turn in to Sirra on the next hearth. | Grant's Mace drops from the same Skeletal Fiends and Horrors. These steps appear only when the shield is in your bags. |
| Proving Your Worth 323, Seeking Wisdom 269 | Accept 323 when you turn in Return to Sven (268). Complete it on the last western trip after Ghoulish Effigy (skeletons at 16.0, 35.5, next to Sven's camp). Turn it in and accept 269. Turn in 269 to Bishop Farthing after the Darkshire flight to Stormwind. | Both references take 323 right after 268. Its mobs are 26-29, so the route saves them for the final visit at about level 26. 269 leads into the Wetlands helper's Doomed Fleet chain: `accept(270)` in `wet` relies on this turn-in. |
| An Old History Book 337 | Item 2794 (`startItem`, a zone-wide Duskwood drop) is accepted just before leaving. Turn it in to Milton Sheaf (Stormwind 77.1, 30.2) on the same Stormwind stop. | It is a free turn-in on a trip the route already makes. Its follow-up, Southshore 538, is level 38 and isn't added. |
| Armed and Ready 325, Morbent Fel 55 | Registered only (`q()` with prerequisites 322 and 325). | Grimand Elmore gives 325 after Blessed Arm (322). The Wetlands helper turns 322 in at the end of `wet`, so `accept(325, grimand)` belongs right after that turn-in. 325's turn-in to Sven and Morbent Fel (level 32, an elite with Morbent's Bane) need a 30+ Duskwood visit, outside this route's range. |

The Darkshire step that starts the trip north is now a `hearth` step (done on arrival at Felicia) instead of `goto`. If it were a `goto` step, the later Stormwind turn-ins would mark it as passed (the `later` rule), and the Duskwood handoff scenario requires that step to show at level 26.

### Redridge late (`redridge-late`, 23-29)

The chapter now has three trips from Lakeshire.
1. Hub pickups, then Bellygrub west of town.
2. East: shore murlocs, Shadowhide, the Tower of Ilgalar, Stonewatch Keep and Render's Valley, then hearth.
3. North: Yowler on the way to the Blackrock caves and Keeshan.

| Quest | Where | Why there |
|---|---|---|
| An Unwelcome Guest 34 | Martie; Bellygrub (10.6, 49.3) by the west road. | Two minutes out and back. Both references route it here at 24-27. |
| Murloc Poachers 150 | Dockmaster Baren. Murlocs on the shore just east of town (35.9, 47.4), with more around 52.2, 52.9. | `requiredLevel` 20 rules out the main Lakeshire route (17-22). |
| Wanted: Gath'Ilzogg 169, WANTED: Incinerator Gar'im 95999 (Forever) | Posters by the town hall (24.5, 46.2 / 24.4, 46.3); turn in to Solomon. Gath'Ilzogg is inside Stonewatch Keep (64.5, 55.8); Gar'im is in the Render's Valley cave (72.8, 86.3, converted from reference A). | Reference A marks Gar'im `.group 4`. Both steps say to bring a group or use Next. |
| Tharil'zun 19, Shadow Magic 115 | Marris; Shadowcasters around Stonewatch (63.2, 55.7), Tharil'zun at 64.4, 59.4. | Same keep as Gath'Ilzogg. |
| Howling in the Hills 126 | Verner; Yowler (22.6, 21.4) on the road north to the Blackrock caves. | It joins the existing north trip. |
| A Watchful Eye 94, Looking Further 248 (optional) | Theocritus at the top of the Tower of Azora (Elwynn 65.2, 69.7) as the first step, for players riding in from Stormwind. Turn in at the Old Lion Statue (79.4, 46.8) after Shadowhide, then complete 248 at the jar on the Stonewatch watch tower (58.2, 49.8). | The pickup is in Elwynn and `requiredLevel` is 20. Players reach Lakeshire main at 18-19, and players starting this chapter often fly in. Both quests are therefore optional (Settings > Show optional quests). |

Prerequisites: in the game, 19 and 115 need Blackrock Menace (20) and 126 needs A Baying of Gnolls (124). Both are in the main Lakeshire route. The audit checks each alternate as its own path, so a chain to a main-route quest fails. These three are registered without a chain, and the pickup text says to use Next if the NPC doesn't offer them.

### Duskwood late (`duskwood-late`, 25-30)

The second loop now runs Darkshire, south of town (222), the Vul'Gol ogre mound, Addle's Stead, the Raven Hill east mausoleum (58), Abercrombie, then a hearth for the turn-ins.

| Quest | Where | Why there |
|---|---|---|
| Ogre Thieves 134, Note to the Mayor 160, Translate Abercrombie's Note 251, Wait for Sirra to Finish 401, Translation to Ello 252 | 134 is accepted at Abercrombie on the first Raven Hill trip. The crate is in Vul'Gol (33.4, 76.3) on the second loop. Turn it in at Abercrombie after the mausoleum, then do the talk chain in Darkshire (Ello, Sirra, wait, Ello). | The route already passes Abercrombie's shack at Raven Hill. 134 needs Ghoulish Effigy (133, main route), so it is registered without a chain, with a note in its text. |
| Look To The Stars 181 | From Viktori on the second loop; Zzarc' Vul (level 33, 36.5, 82.3) at the back of Vul'Gol. | Same mound. It needs 177 (main route), so it has no chain and the text says to use Next if it isn't offered. The step is marked `uncertain` because his level comes from the classic data. |
| Silvia's Sword 79363 (Forever) | Item 281145 (`startItem`, Lost Defender ghost at Sven's old farm or the Rotting Orchard, per reference A). Defias Night Blades and Enchanters at Addle's Stead (22.5, 72.6), with a few at Sven's old farm. Turn in to Sirra. | The mobs are 25-27. |
| Merrick's Bow 96138 (Forever) | Item 281142 (`startItem`, Lost Watcher ghost south of the Raven Hill road). Splinter Fist Warriors and Taskmasters in Vul'Gol (34.4, 75.5). Turn in to Sirra. | The mobs are 27-30, in the same mound as 134 and 181. |

## Skipped

- **Thunderbrew Lager 117** isn't in the Forever client (client=False). Dry Times 116 (Lakeshire) is skipped for the same reason, because its Keg of Thunderbrew Lager comes from 117. Its other three drinks are vendor items from other zones.
- **Messenger to Westfall 143, 144 and Messenger to Darkshire 145, 146.** 143 becomes available only after the Stormwind trip in Lakeshire (via 121). The route then has no later visit to Westfall, so the chain would need a round flight between Lakeshire and Sentinel Hill for two level-14 quests, which are green or grey by then. 145 and 146 need 144.
- **Brother Kristoff chain 343, 344, 345, 347, 346.** The chain goes Cathedral Square, then the Keep library, then Northshire, Lakeshire, the Rethban Caverns, Northshire again and the Cathedral. That means two trips into Northshire for talk-heavy level-24 quests. Only the Mage AoE guide (teleports) routes it.
- **Devils in Westfall 1076, Retrieval for Mauren 1078.** 1076 needs A Scroll from Mauren (1075), which the Stonetalon helper turns in to Collin Mauren inside the `stonetalon` chapter. The audit checks each alternate path on its own, so 1076 only fits inside that chapter. Our Westfall section is 12-18 and never returns at 21+. Only 12 Dust Devils spawn (36.2, 65.1 / 44.2, 45.6 / 68.5, 73.5). Recommendation for the Stonetalon helper: skip it, or add an optional Westfall stop after the 1075 turn-in. 1078 belongs to that helper.
- **Bride of the Embalmer 253**: a level 30 group fight (Eliza, level 31, with guards). The chain stops at Translation to Ello.
- **Look To The Stars 181** is added (see above). **The Weathered Grave 225 to A Daughter's Love 231**: level 35, min 28. **Southshore 538**: level 38.
- Outside this area: Report to Jennea 1919 is a Gnome Mage class quest. Philmor's Favor 97220, Gatehouse Goods 97222, Deeprun Rat Roundup 6661 and Stormpike's Order 1338 are already registered by other helpers. Humble Beginnings 399 and Fishin' Time 95065 are Stormwind errands that aren't routed here. Sara Balloo, Brassbolts, Stranglethorn, Malin's Request, James Hyal and the Desolace pickups from the 29-32 chapter are all level 30 or higher or in other zones.

## Facts that differ between sources

- A Watchful Eye starts from Theocritus in Elwynn (questfacts), not in Redridge. Both references take it at the tower on the road from Goldshire.
- Seasoned Wolf Kabobs also asks for Stormwind Seasoning Herbs, and no source lists a drop (`drops: []`). The pickup text says to buy them from a cooking supplies vendor. This needs an in-game check.
- The Bronze Tube is a limited-stock vendor item: Herble in Darkshire (Reference A), or a Stormwind vendor at 61.1, 70.7 (Reference B). It also drops from Bael'dun miners in the Barrens, which is not useful here.
- Old Murk-Eye: Reference B calls him "Larger grey murloc" and doesn't flag him as elite. Classic had him as a level 20 elite. The step only tells you to pull him alone.

## Data changes to mirror

- Westfall: the Harvest Golem step text now asks you to keep 5 Flasks of Oil.
- Duskwood: the final "return to Darkshire" step is now `hearth` (bind Darkshire, arrival at Felicia). The section ends in Stormwind (fly, 269, 337). Wetlands' first `fly` step completes on landing.
- New registrations without in-game chains: 19, 115, 126 (redridge-late), 134, 181 (duskwood-late). Unused registrations: 325, 55.

## Check in game

- Westfall lighthouse: Captain Grayson offers 103 and 104 to every race. Flasks of Oil drop from golems without the quest. Check how hard Old Murk-Eye is at level 16-17.
- Darkshire: Herble's Bronze Tube stock. The Insane Ghoul's level and spawn (chapel versus outside). The Seasoning Herbs vendor.
- Grant's Shield, Silvia's Sword and Merrick's Bow: confirm that the item IDs 281147, 281145 and 281142 start the quests (Reference A `.use` IDs), and that the steps appear once the item is in your bags.
- Proving Your Worth at about level 26: whether the Raider and Warder pulls are soloable. Check that Morbent Fel stays out of the way.
- Redridge: Gar'im's cave position (72.8, 86.3) and group size. Whether Tharil'zun and Gath'Ilzogg are elites in Forever. Bellygrub's difficulty at 23.
- Duskwood late: Zzarc' Vul's level and whether he is elite. The crate spot in Vul'Gol. Wait for Sirra to Finish should complete after a short wait.
- Stormwind exit: after landing from Darkshire, the Wetlands "Fly to Stormwind" step should already show done. Turn in 269 at Farthing and 337 at Milton Sheaf, then accept The Doomed Fleet.

## Checks run

- `tools/questroute.py audit`: passed. The only warnings in my sections are the usual "more than 5 levels above the section's target" for 323 and 269, the same as the existing one for Ghoulish Effigy.
- `tests/run.py` (full): every run passes except two Wetlands scenarios, which the Wetlands helper's in-progress edits cause.
  - `questWetlandsTravel`: their `accept(270)` now sits between the Stormwind flight and the tram.
  - `questWetlandsEnd`: steps were added after A Friend of the Family.
