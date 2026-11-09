# Herbalism 1-300 audit

The guide uses WoW: Forever client build `1.60.1.70862` and Forever database pages checked on 2026-11-08. The route covers the standard herbs. Trainer services, node spawns and color cutoffs need a live client check.

The client supplies skill line 182, icon 136246 (`trade_herbalism`), item names and icons, recipe spells, reagents, and herbalism lock slots (`Type=2`, `_Index=2`). All 28 minimums in the table occur in those slots. The 1,526 records in the client's `GameObjects` table contain none of the named herb objects. The reference therefore verifies that each item and minimum exist independently. The Forever object and overview pages supply the associations. The client `AreaTable` confirms every recommended zone name, including Zephras Isle (16593) and Riverglades (16591). [Client Lock table](https://wago.tools/db2/Lock?build=1.60.1.70862) · [Client AreaTable](https://wago.tools/db2/AreaTable?build=1.60.1.70862) · [Forever overview](https://www.wowhead.com/forever/guide/professions/herbalism/overview-leveling)

## Nodes

The four numbers mark minimum skill, yellow, green and gray. The zone column is the guide's shortlist from the linked object maps. The overview supplies the colors.

| Herb and object record | Client item | Minimum / yellow / green / gray | Recommended zones |
| --- | --- | --- | --- |
| [Peacebloom](https://www.wowhead.com/forever/object=1618) | [2447](https://www.wowhead.com/forever/item=2447) | 1 / 25 / 50 / 100 | Alliance — Elwynn Forest, Dun Morogh, Teldrassil · Horde — Durotar, Mulgore, Tirisfal Glades · Skyborne — Zephras Isle |
| [Silverleaf](https://www.wowhead.com/forever/object=1617) | [765](https://www.wowhead.com/forever/item=765) | 1 / 25 / 50 / 100 | Alliance — Elwynn Forest, Dun Morogh, Teldrassil · Horde — Durotar, Mulgore, Tirisfal Glades · Skyborne — Zephras Isle |
| [Earthroot](https://www.wowhead.com/forever/object=1619) | [2449](https://www.wowhead.com/forever/item=2449) | 15 / 40 / 65 / 115 | Alliance — Elwynn Forest, Dun Morogh, Teldrassil · Horde — Durotar, Mulgore, Tirisfal Glades · Skyborne — Zephras Isle |
| [Mageroyal](https://www.wowhead.com/forever/object=1620) | [785](https://www.wowhead.com/forever/item=785) | 50 / 75 / 100 / 150 | Alliance — Darkshore, Loch Modan · Horde — Silverpine Forest, The Barrens · Skyborne — Zephras Isle |
| [Briarthorn](https://www.wowhead.com/forever/object=1621) | [2450](https://www.wowhead.com/forever/item=2450) | 70 / 95 / 120 / 170 | Alliance — Darkshore, Loch Modan, Wetlands · Horde — Silverpine Forest, The Barrens, Hillsbrad Foothills |
| [Stranglekelp](https://www.wowhead.com/forever/object=2045) | [3820](https://www.wowhead.com/forever/item=3820) | 85 / 110 / 135 / 185 | Alliance — Darkshore, Wetlands · Horde — Silverpine Forest, Hillsbrad Foothills · Riverglades |
| [Bruiseweed](https://www.wowhead.com/forever/object=1622) | [2453](https://www.wowhead.com/forever/item=2453) | 100 / 125 / 150 / 200 | Alliance — Darkshore, Loch Modan, Wetlands · Horde — Silverpine Forest, Hillsbrad Foothills, Stonetalon Mountains |
| [Wild Steelbloom](https://www.wowhead.com/forever/object=1623) | [3355](https://www.wowhead.com/forever/item=3355) | 115 / 140 / 165 / 215 | Alliance — Wetlands · Horde — Hillsbrad Foothills, Stonetalon Mountains · Riverglades, Arathi Highlands |
| [Grave Moss](https://www.wowhead.com/forever/object=1628) | [3369](https://www.wowhead.com/forever/item=3369) | 120 / 145 / 170 / 220 | Alliance — Duskwood, Wetlands · Horde — The Barrens · Desolace, Arathi Highlands |
| [Kingsblood](https://www.wowhead.com/forever/object=1624) | [3356](https://www.wowhead.com/forever/item=3356) | 125 / 150 / 175 / 225 | Alliance — Wetlands · Horde — Hillsbrad Foothills, Stonetalon Mountains · Stranglethorn Vale, Arathi Highlands, Riverglades |
| [Liferoot](https://www.wowhead.com/forever/object=2041) | [3357](https://www.wowhead.com/forever/item=3357) | 150 / 175 / 200 / 250 | Alliance — Wetlands · Horde — Hillsbrad Foothills · Stranglethorn Vale, Arathi Highlands, Riverglades |
| [Fadeleaf](https://www.wowhead.com/forever/object=2042) | [3818](https://www.wowhead.com/forever/item=3818) | 160 / 185 / 210 / 260 | Stranglethorn Vale, Arathi Highlands, Swamp of Sorrows |
| [Goldthorn](https://www.wowhead.com/forever/object=2046) | [3821](https://www.wowhead.com/forever/item=3821) | 170 / 195 / 220 / 270 | Stranglethorn Vale, Arathi Highlands, Riverglades |
| [Khadgar's Whisker](https://www.wowhead.com/forever/object=2043) | [3358](https://www.wowhead.com/forever/item=3358) | 185 / 210 / 235 / 285 | Stranglethorn Vale, Arathi Highlands, Riverglades |
| [Wintersbite](https://www.wowhead.com/forever/object=2044) | [3819](https://www.wowhead.com/forever/item=3819) | 195 / 220 / 245 / 295 | Alterac Mountains |
| [Firebloom](https://www.wowhead.com/forever/object=2866) | [4625](https://www.wowhead.com/forever/item=4625) | 205 / 230 / 255 / 305 | Tanaris, Searing Gorge, Badlands, Blasted Lands |
| [Purple Lotus](https://www.wowhead.com/forever/object=142140) | [8831](https://www.wowhead.com/forever/item=8831) | 210 / 235 / 260 / 310 | Tanaris, The Hinterlands, Feralas |
| [Arthas' Tears](https://www.wowhead.com/forever/object=142141) | [8836](https://www.wowhead.com/forever/item=8836) | 220 / 245 / 270 / 320 | Eastern Plaguelands, Western Plaguelands |
| [Sungrass](https://www.wowhead.com/forever/object=142142) | [8838](https://www.wowhead.com/forever/item=8838) | 230 / 255 / 280 / 330 | The Hinterlands, Feralas, Un'Goro Crater, Eastern Plaguelands |
| [Blindweed](https://www.wowhead.com/forever/object=142143) | [8839](https://www.wowhead.com/forever/item=8839) | 235 / 260 / 285 / 335 | Swamp of Sorrows, Un'Goro Crater |
| [Ghost Mushroom](https://www.wowhead.com/forever/object=142144) | [8845](https://www.wowhead.com/forever/item=8845) | 245 / 270 / 295 / 345 | The Hinterlands, Maraudon |
| [Gromsblood](https://www.wowhead.com/forever/object=142145) | [8846](https://www.wowhead.com/forever/item=8846) | 250 / 275 / 300 / 350 | Blasted Lands, Desolace, Ashenvale |
| [Golden Sansam](https://www.wowhead.com/forever/object=176583) | [13464](https://www.wowhead.com/forever/item=13464) | 260 / 285 / 310 / 360 | The Hinterlands, Eastern Plaguelands, Un'Goro Crater |
| [Dreamfoil](https://www.wowhead.com/forever/object=176584) | [13463](https://www.wowhead.com/forever/item=13463) | 270 / 290 / 315 / 370 | Eastern Plaguelands, Western Plaguelands, Un'Goro Crater |
| [Mountain Silversage](https://www.wowhead.com/forever/object=176586) | [13465](https://www.wowhead.com/forever/item=13465) | 280 / 305 / 330 / 380 | Eastern Plaguelands, Western Plaguelands, Winterspring, Un'Goro Crater |
| [Plaguebloom](https://www.wowhead.com/forever/object=176587) | [13466](https://www.wowhead.com/forever/item=13466) | 285 / 310 / 335 / 385 | Eastern Plaguelands, Western Plaguelands |
| [Icecap](https://www.wowhead.com/forever/object=176588) | [13467](https://www.wowhead.com/forever/item=13467) | 290 / 315 / 340 / 390 | Winterspring |
| [Black Lotus](https://www.wowhead.com/forever/object=176589) | [13468](https://www.wowhead.com/forever/item=13468) | 300 / 325 / 350 / 400 | Eastern Plaguelands, Burning Steppes, Winterspring, Silithus |

- The Dreamfoil overview gives 270/290/315/370. Icy Veins gives 270/295/320/370. The guide uses the earlier cutoffs so it does not overstate the chance of a point.
- Several guides recommend Felwood for the last band. The Dreamfoil, Mountain Silversage and Plaguebloom object maps list Eastern and Western Plaguelands and omit Felwood. Eastern Plaguelands also has Golden Sansam, so the route works there at the handoff. The Codex mentions Felwood as a reported alternative pending a live spawn check.
- The starter object maps include Zephras Isle. Mageroyal appears on its own island map even though the overview omits the island for that herb. Riverglades appears on the maps for Stranglekelp, Wild Steelbloom, Kingsblood, Liferoot, Goldthorn and Khadgar's Whisker.
- Seeds and scarce drops are distinct from the standard gathering nodes. The client's item records include Marefoil, Demonsage and Death Lotus. The overview reports a Death Lotus chance with the Lotus Claw enchant in Hyjal. Locations and skill requirements for any dedicated nodes remain open.

[Forever overview](https://www.wowhead.com/forever/guide/professions/herbalism/overview-leveling) · [Icy Veins node table](https://www.icy-veins.com/wow-forever/herbalism) · [Icy Veins leveling route](https://www.icy-veins.com/wow-forever/herbalism-leveling-guide) · [WoW-Professions leveling route](https://www.wow-professions.com/forever/herbalism-leveling-guide) · [wow.gg guide](https://wow.gg/professions/forever/herbalism)

## Training

| Tier spell | Skill | Cap | Guide examples |
| --- | ---: | ---: | --- |
| [Apprentice](https://www.wowhead.com/forever/spell=2366) | 1 | 75 | Tannysa, Jandi, Syriel Nightrain, Halassa Fernbreeze |
| [Journeyman](https://www.wowhead.com/forever/spell=2368) | 50 | 150 | Tannysa, Jandi, Syriel Nightrain, Halassa Fernbreeze |
| [Expert](https://www.wowhead.com/forever/spell=3570) | 125 | 225 | Tannysa, Jandi, Flora Silverwind |
| [Artisan](https://www.wowhead.com/forever/spell=11993) | 200 | 300 | Tannysa, Jandi, Flora Silverwind |

The Forever taught-by lists include both Zephras Isle trainers for the first two tiers and omit them from Expert and Artisan. Some guides list them for all four. The Codex suggests checking on the island first and gives mainland trainers as a fallback for Expert and Artisan. The client has no character-level requirements in `SpellLevels` for the four rank spells. The Forever trainer guide also reports no character-level gate, while some guide text still refers to level requirements. [Forever skill lists](https://www.wowhead.com/forever/skill=182/herbalism) · [WoW-Professions trainer requirements](https://www.wow-professions.com/forever/herbalism-trainers) · [Icy Veins trainer lists](https://www.icy-veins.com/wow-forever/herbalism-leveling-guide)

## Camp objects

| Recipe | Skill | Client yellow / green / gray | Client reagents | Unlock source |
| --- | ---: | --- | --- | --- |
| [Incense Candle](https://www.wowhead.com/forever/spell=1229705) | 20 | 20 / 22 / 25 | 1 Peacebloom, 1 Silverleaf | Herbalism trainer |
| [Greenhouse](https://www.wowhead.com/forever/spell=1262980) | 140 | 140 / 142 / 145 | 2 Simple Wood, 1 Arthas' Tears, 1 Purple Lotus | Blueprint from Shadetooth in Excavation Site: Wetlands |
| [Seed Hybridizer](https://www.wowhead.com/forever/spell=1263070) | 300 | 300 / 300 / 300 | 4 Mountain Silversage, 1 Crystal Vial, 2 Runecloth | Blueprint with an unconfirmed drop source |

The client confirms the blueprint recipes and their 140 and 300 skill requirements. Camp use and the Greenhouse drop come from the Forever sources. The guide uses gathering for leveling. [WoW-Professions camp items](https://www.wow-professions.com/forever/herbalism-changes) · [Greenhouse drop and seed use](https://www.icy-veins.com/wow-forever/news/greenhouse-blueprint-found-how-herbalism-seeds-work-in-wow-forever/) · [wow.gg camp items](https://wow.gg/professions/forever/herbalism)

## Live checks

- Test Apprentice and Journeyman on Zephras Isle, then check whether the same trainers offer Expert or Artisan. Confirm any character-level gates.
- Check Peacebloom around 25 and 50, Dreamfoil around 290 and 315, and Black Lotus at 300. Confirm Mageroyal on Zephras Isle and the listed Riverglades nodes.
- Check the camp trainer and blueprint unlocks. Record any confirmed Seed Hybridizer source.
- Learn Herbalism with the Codex open. Check that the button appears, that Find Herbs can be enabled through the existing tracker, and that the Earthroot and Journeyman cards open the guide.
