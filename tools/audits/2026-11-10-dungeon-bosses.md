# Alliance dungeon boss lists

Every Alliance dungeon detour in `QuestDungeonData.lua` now carries `bosses`, shown on the Quests tab as BOSSES IN ORDER with one short tip per boss. Only the `bosses` fields changed. The tips are original wording built from the mechanics described in the sources below. Optional and rare encounters are marked in the name.

Creature IDs (`npc`) were checked with `tools/questfacts.py npc ID` against the pinned QuestieDB Forever records. Every Classic boss ID used is present in the Forever records under the same name. Of the new Forever bosses, only Highland Horror (260808) is in those records, so the other new bosses carry no `npc` for now. The local Zygor Forever reference was read only to cross-check names and order. None of its text was used. Boss order is the usual clear order and still needs a live check.

## Sources per dungeon

| Dungeon | Bosses | Sources |
|---|---|---|
| Hall of Thanes | Faldrim Anvilmar, Magmatus, Plunder, Durgen Dirgehammer | [Method](https://www.method.gg/wow-forever/dungeons/hall-of-thanes) · [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/hall-of-thanes/) |
| Ruins of Lordaeron | Witherfang, The Baron, Viktor the Vile (event), The Abandoned (event), Bjork, Rath'mael | [Method](https://www.method.gg/wow-forever/dungeons/ruins-of-lordaeron) · [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/the-ruins-of-lordaeron/) |
| The Deadmines | Rhahk'Zor 644, Miner Johnson 3586 (rare), Sneed's Shredder 642, Gilnid 1763, Mr. Smite 646, Captain Greenskin 647, Edwin VanCleef 639, Cookie 645 | [Method](https://www.method.gg/wow-forever/dungeons/the-deadmines) |
| Wailing Caverns | Kresh 3653, Lady Anacondra 3671, Lord Cobrahn 3669, Deviate Faerie Dragon 5912 (rare), Lord Pythas 3670, Skum 3674, Lord Serpentis 3673, Verdan the Everliving 5775, Mutanus the Devourer 3654 | [Method](https://www.method.gg/wow-forever/dungeons/wailing-caverns) |
| Shadowfang Keep | Rethilgore 3914, Razorclaw the Butcher 3886, Baron Silverlaine 3887, Commander Springvale 4278, Odo the Blindwatcher 4279, Deathsworn Captain 3872 (rare), Fenrus the Devourer 4274, Wolf Master Nandos 3927, Archmage Arugal 4275 | [Method](https://www.method.gg/wow-forever/dungeons/shadowfang-keep) |
| The Stockade | Targorr the Dread 1696, Kam Deepfury 1666, Hamhock 1717, Bazil Thredd 1716, Bruegal Ironknuckle 1720 (rare), Dextren Ward 1663 | [Method](https://www.method.gg/wow-forever/dungeons/the-stockade) |
| Blackfathom Deeps | Ghamoo-ra 4887, Lady Sarevess 4831, Gelihast 6243, Twilight Lord Kelris 4832, Old Serra'kis 4830, Aku'mai 4829 | [Method](https://www.method.gg/wow-forever/dungeons/blackfathom-deeps) |
| Excavation Site: Wetlands | Saltspine, Shadetooth, Highland Horror 260808 (Alliance quest), Relic Guardian | [Method](https://www.method.gg/wow-forever/dungeons/excavation-site-wetlands) · [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/excavation-site-wetlands/) |
| City of Dalaran | Atrexis the Grave Knight, Lyn the Ignored (Tome of Dalaran), Arcane Anomaly, Arcanic Enigma, Unstable Sentinel, Fel Ancient, Mana Devourer, Shade of the Archmage | [Method](https://www.method.gg/wow-forever/dungeons/city-of-dalaran) · [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/city-of-dalaran/) |
| Gnomeregan | Grubbis 7361, Viscous Fallout 7079, Electrocutioner 6000 6235, Crowd Pummeler 9-60 6229, Dark Iron Ambassador 6228 (rare), Mekgineer Thermaplugg 7800 | [Method](https://www.method.gg/wow-forever/dungeons/gnomeregan) |
| Razorfen Kraul | Roogug 6168, Aggem Thorncurse 4424, Death Speaker Jargba 4428, Overlord Ramtusk 4420, Agathelos the Raging 4422, Blind Hunter 4425 (rare), Earthcaller Halmgar 4842 (rare), Charlga Razorflank 4421 | [Method](https://www.method.gg/wow-forever/dungeons/razorfen-kraul) |
| Scarlet Monastery: Graveyard | Interrogator Vishas 3983, Ironspine 6489 (rare), Fallen Champion 6488 (rare), Azshir the Sleepless 6490 (rare), Bloodmage Thalnos 4543 | [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/scarlet-monastery-graveyard/) |
| Ragefire Chasm | Oggleflint 11517, Taragaman the Hungerer 11520, Jergosh the Invoker 11518, Bazzalan 11519 | [Method](https://www.method.gg/wow-forever/dungeons/ragefire-chasm) |

Ragefire Chasm stays in the list. The Alliance file already offers it as an optional run: Alliance characters can enter, but its quests are Horde-only. [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/ragefire-chasm/)

## Disagreements and choices

- **Hall of Thanes.** Method spells the last boss both Durgen and Dirgen. Warcraft Tavern, the Warcraft Wiki and Zygor use Durgen Dirgehammer, and the route text already uses it. Method describes Plunder as an elemental guardian, while Warcraft Tavern describes a stone golem. The tip calls it a golem and covers the knockback both sources report.
- **Ruins of Lordaeron.** Method and Warcraft Tavern list Viktor the Vile before The Abandoned. Zygor reverses them. Both are optional events, so the guide follows the web sources. Warcraft Tavern lists a rare Lordaeron Captain that Alliance players cannot attack. It is left out of the Alliance list. Rankedboost and Kami Labs count it as a seventh boss.
- **Excavation Site.** One Zygor heading spells the raptor Shardtooth, but its kill list for the same creature and both web guides use Shadetooth, which matches the existing route text. Method gives Highland Horror the quest item but no loot. Warcraft Tavern says Wild Regeneration should be interrupted.
- **City of Dalaran.** Method and Zygor agree on this order. Warcraft Tavern visits Mana Devourer third and puts Fel Ancient before Arcanic Enigma and the construct. Warcraft Tavern names the construct Unstable Sentry, while Method and Zygor say Unstable Sentinel. Sources name different NPCs to open the Fel Ancient barrier: Grindle Firespark or Magus Fansy Goodbringer. The tip says to speak to the mage at the barrier. Some Icy Veins summaries count nine bosses, while Warcraft Tavern and Method list eight. Icy Veins returned 403 to direct fetches.
- **Wailing Caverns.** Method lists Lady Anacondra before Kresh. Zygor and the Classic layout put Kresh in the first river. The guide starts with Kresh because the order through the first area is flexible.
- **The Stockade.** Method has no fixed order and lists the west wing first. The guide follows the existing route text: east wing (Kam, Hamhock, Bazil), then west wing (Bruegal, Dextren). That matches Zygor's order.
- **Blackfathom Deeps.** Method lists Old Serra'kis before Kelris, while Zygor and the Classic layout put him after Kelris on the way to Aku'mai. The guide uses the second order. Method mentions an unnamed optional rare. Lorgus Jett 12902 is in the Forever records, but no Forever guide names him, so he is left out.
- **Razorfen Kraul.** Method lists Jargba before Aggem, and Zygor reverses them. The guide uses Zygor's order because the two are close together. Method treats Earthcaller Halmgar as a regular boss. He is a rare spawn in Classic, so he is marked "rare, may be absent" until checked live.
- **Scarlet Monastery: Graveyard.** Warcraft Tavern spells the rare "Ironspire" in one place. The Forever record for 6489 is Ironspine. Warcraft Tavern says Thalnos's casts cannot be interrupted, so his tip only covers positioning. The Scourge-event and seasonal bosses are left out.

## In-game checks

1. Open each dungeon guide from the Quests tab and confirm that BOSSES IN ORDER lists the bosses above with readable tips.
2. Check the live order for Dalaran, Blackfathom (Serra'kis), Razorfen Kraul (Aggem and Jargba) and the Ruins events, and whether Earthcaller Halmgar always spawns.
3. Find the creature IDs of the new Forever bosses (target and `/codex record`) to add `npc` values: Hall of Thanes, Ruins, Saltspine, Shadetooth, Relic Guardian and all Dalaran bosses.
