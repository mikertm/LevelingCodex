# Skinning and Leatherworking 1–300 source audit

Checked November 9, 2026 against WoW: Forever build `1.60.1.70862`. The client gives Skinning skill line 393 and Leatherworking 165. The recipe audit uses spell IDs, yellow and gray thresholds, exact reagents, icons, outputs used later in the route, and the two Artisan patterns' skill requirements. The reference contains 3 Skinning recipes and 568 Leatherworking recipes. [Forever SkillLine](https://wago.tools/db2/SkillLine?build=1.60.1.70862) · [Forever SkillLineAbility](https://wago.tools/db2/SkillLineAbility?build=1.60.1.70862) · [Forever SpellReagents](https://wago.tools/db2/SpellReagents?build=1.60.1.70862) · [Forever ItemSparse](https://wago.tools/db2/ItemSparse?build=1.60.1.70862)

## Skinning

The client describes the five-skill-per-level rule at higher ranks. Forever leveling guides agree on skill 1 for skinnable beasts through level 10, then ten skill per level above 10 through level 20. The 20 breakpoint gives 100 by either rule. The route suggests beasts at or below the requirement when you enter each band and gives skill thresholds for tougher packs. The client confirms all 17 zone names. Suggested spawns and loot are field guidance. [Forever AreaTable](https://wago.tools/db2/AreaTable?build=1.60.1.70862) · [Forever Skinning records and trainers](https://www.wowhead.com/forever/guide/professions/skinning/overview-leveling) · [WoW-Professions field route](https://www.wow-professions.com/forever/skinning-leveling-guide) · [Icy Veins leveling routes](https://www.icy-veins.com/wow-forever/skinning-leveling-guide)

| Skill | Route | Enter the band with |
| --- | --- | --- |
| 1–75 | Starter beasts. Northshire wolves or Valley of Trials boars are examples. Zephras Isle is listed for Skyborne. | Skinning Knife and beasts up to level 10 |
| 75–125 | Loch Modan boars and bears or Barrens raptors | Level 16–17 beasts |
| 125–150 | Wetlands raptors, Hillsbrad beasts, or the Barrens while it still gives points | Level 25 or lower |
| 150–175 | Hillsbrad Cave Yetis or Duskwood worgen | Level 30 or lower |
| 175–225 | Stranglethorn, Arathi, or Shimmering Flats | Level 35 or lower |
| 225–280 | Feral Scar Vale yetis, then Rage Scar Hold at 240. Un'Goro's level 50 dinosaurs open at 250. | Level 43–45 yetis |
| 280–300 | Western Un'Goro dinosaurs | Level 50–55 beasts |

Ask a full trainer about Journeyman at 50, Expert at 125 and Artisan at 200. The caps are 75, 150, 225 and 300. The addon marks character-level gates as unconfirmed because Forever sources disagree. The starter manual and both full Zephras trainers are documented separately from the mainland junior trainers. [Forever trainer list](https://www.wow-professions.com/forever/skinning-trainers) · [Zephras trainer records](https://www.wowhead.com/forever/guide/zephras-isle-zone-overview-maps-locations-and-trainers-34862) · [Published level-gate discrepancy](https://elitistgaming.com/guides/wow-forever-professions/skinning)

Camp Chair (20), Field Guide (140) and Trapper's Workbench (300) match the client recipes. The Field Guide blueprint drops from Lady Anacondra. A Forever beta player reported the Workbench blueprint from Houndmaster Loksey in Scarlet Monastery Library, and the blueprint's drop table names Loksey. This source still needs a live check. [Blizzard's Camping overview](https://worldofwarcraft.blizzard.com/en-us/news/24301516/gather-around-the-campfire-in-world-of-warcraft-forever) · [Field Guide spell and blueprint](https://www.wowhead.com/forever/spell=1262985/field-guide) · [Trapper's Workbench blueprint](https://www.wowhead.com/forever/item=273109/blueprint-trappers-workbench)

## Leatherworking

Journeyman requires 50 skill and character level 10, Expert requires 125 and level 20, and Artisan requires 200 and level 35. Train Expert with Telonis or Una, and Artisan with Drakk Stonehand or Hahrana Ironhide. Trainer recipes through 225 are cross-checked against the published Forever trainer route and recipe records. The client does not encode a learn rank for these trainer recipes. Trainer availability and conflicting learn ranks should be checked live with `/codex debug`. [Method's tested beta route and trainer table](https://www.method.gg/wow-forever/leatherworking-in-wow-forever-leveling-guide-and-trainers) · [WoW-Professions route and trainer list](https://www.wow-professions.com/forever/leatherworking-leveling-guide) · [Forever recipe records through skill 95](https://www.wowhead.com/forever/spells/professions/leatherworking/min-skill-level:1/max-skill-level:95)

| Skill | Recipe | Learn | Yellow / green / gray | Estimated crafts |
| --- | --- | ---: | --- | ---: |
| 1–20 | Light Leather | 1 | 20 / 30 / 40 | 19 |
| 20–45 | Light Armor Kit | 1 | 30 / 45 / 60 | 31 |
| 45–75 | Embossed Leather Gloves | 40 | 70 / 85 / 100 | 31 |
| 75–80 | Medium Leather | 75 | 75 / 80 / 85 | 7 |
| 80–90 | Cured Medium Hide | 75 | 90 / 97 / 105 | 10 |
| 90–100 | Fine Leather Belt | 55 | 85 / 100 / 115 | 15 |
| 100–120 | Dark Leather Cloak | 85 | 110 / 122 / 135 | 23 |
| 120–125 | Hillman's Shoulders | 105 | 130 / 142 / 155 | 5 |
| 125–130 | Heavy Leather | 125 | 125 / 130 / 135 | 7 |
| 130–140 | Cured Heavy Hide | 125 | 135 / 140 / 145 | 12 |
| 140–155 | Hillman's Leather Gloves | 120 | 145 / 157 / 170 | 18 |
| 155–165 | Barbaric Shoulders | 150 | 170 / 180 / 190 | 10 |
| 165–195 | Guardian Gloves | 165 | 185 / 195 / 205 | 34 |
| 195–210 | Nightscape Headband | 180 | 200 / 210 / 220 | 19 |
| 210–235 | Nightscape Pants | 205 | 225 / 235 / 245 | 29 |
| 235–265 | Wicked Leather Gauntlets | 235 | 255 / 265 / 275 | 34 |
| 265–300 | Runic Leather Headband | 265 | 285 / 295 / 305 | 47 |

Nightscape Pants bridge 225–235 with the recipe already in hand. This avoids the reported discrepancy on when a trainer teaches Rugged Armor Kit or Nightscape Boots. Learn Wicked Leather Gauntlets from a bind-on-pickup pattern sold by Leonard Porter or Werg Thickblade. Jase Farlane is listed for the Runic Leather Headband pattern. The current client gives its learn rank as 265 and gray at 305. A Wowhead item snapshot still shows 290, so check the vendor on your Leatherworker before buying materials. If that pattern is unavailable, the client supports Wicked Leather Headband from 265–275 and Wicked Leather Belt from 275–300 with their respective drop patterns. [Artisan route and vendor notes](https://www.wow-professions.com/forever/leatherworking-leveling-guide) · [Wicked Leather Gauntlets pattern](https://www.wowhead.com/forever/item=15725/pattern-wicked-leather-gauntlets) · [Runic Leather Headband client and vendor record](https://wowforever.ninja/professions/leatherworking/19082-runic-leather-headband/) · [Wowhead snapshot](https://www.wowhead.com/forever/item=15756/pattern-runic-leather-headband) · [Wicked Leather Belt pattern](https://www.wowhead.com/forever/item=15768/pattern-wicked-leather-belt)

The main route estimates 930 Rugged Leather, 501 Thick Leather, 484 Medium Leather and 470 Runecloth from skill 1. The list credits conversions already in the route. Expect about 12 Cured Heavy Hides from the curing step and 32 more for the later crafts. Buy those or cure 32 Heavy Hides with 96 additional Salt. These are estimates before Legacy perks, and the alternate routes change the quantities.

The Tanning Rack unlock displays 125 per Blizzard's November 6 server hotfix. The client still lists 140 on the blueprint. The hotfix also moves the skill-up window down 15, so the route leaves the rack as an optional camp object. Camp Tent is available at 20 and Sewing Machine at 300. [Blizzard hotfix](https://us.forums.blizzard.com/en/wow/t/wow-forever-hotfixes-november-6-2026/2403040) · [Tanning Rack drop record](https://www.wowhead.com/forever/item=273096/blueprint-tanning-rack) · [Leatherworking camp recipes](https://www.wowhead.com/forever/guide/professions/leatherworking-overview-trainer-locations-recipes)

## Second pass against a reference guide

Compared the full Alliance and Horde profession files in the local copy. The reference guide lists the same Expert and Artisan Leatherworking trainers and Wicked Leather Gauntlets vendors. Its Skinning route also uses Loch Modan, Wetlands, the Barrens, Arathi Highlands, Thousand Needles and Feralas. The Feralas route continues north from Feral Scar Vale. Forever NPC records put Rage Scar Hold yetis at levels 46–48, so the guide adds that stop at 240. Its character-level gates for Skinning appear alongside generic Classic and Season of Discovery conditions. The Forever trainer sources still disagree, so those gates remain marked unconfirmed. [Forever Rage Scar Yeti levels](https://www.wowhead.com/forever/npcs/humanoids/min-level:25/max-level:46?filter=10;1;0) · [Ferocious Rage Scar level record](https://www.wowhead.com/forever/item=15619/gryphon-mail-belt)

The reference guide takes Nightscape Headband to 235 and Wicked Leather Gauntlets to 290. In the current Forever client those crafts go gray at 220 and 275. Its Nightscape Pants, Nightscape Boots and Wicked Leather Headband targets also exceed the Forever cutoffs of 245, 250 and 295. Its Nightscape Pants training visit at 235 is a route stop, while the Forever-specific Method guide lists the trainer requirement at 205. The Codex keeps its Forever bands and adds alternate handoffs. The shopping list still follows the main route. [Forever SkillLineAbility](https://wago.tools/db2/SkillLineAbility?build=1.60.1.70862) · [Forever Method trainer table](https://www.method.gg/wow-forever/leatherworking-in-wow-forever-leveling-guide-and-trainers)

| If blocked at | Alternate handoff checked against the Forever client |
| --- | --- |
| 195 | Thick Armor Kit to 205. Yellow at 195, gray at 215. |
| 210 | Nightscape Headband to 215, then Big Voodoo Cloak to 235. The tradable cloak pattern requires 215, and the recipe stays orange through 234. |
| 235 | Nightscape Pants or Big Voodoo Cloak to 240, then Wicked Leather Bracers to 265. The bracer pattern requires 240. The recipe uses the same reagents per craft as the gauntlets. |

Big Voodoo Cloak pattern listings were observed on Forever's auction house, though local stock varies. The Forever item record lists Legashi Rogues for the Wicked Leather Bracers pattern. [Big Voodoo Cloak pattern and auction data](https://goldcap.gg/forever/us/items/8390) · [Wicked Leather Bracers pattern](https://www.wowhead.com/forever/item=15728/pattern-wicked-leather-bracers)

## In-game checks

- Learn both professions and switch guides in `/codex` → **Professions**. Check the starter Skinning zones, then preview Feralas and Un'Goro.
- Check Skinning trainer availability at 50, 125 and 200 and record any character-level gate the trainer shows.
- Confirm Nightscape Pants at a Master Leatherworker and the two Artisan vendors on a Leatherworker. Use `/codex debug` after opening the trainer for any differing learn rank.
- Open Leatherworking with the recommended recipe visible. Check that the outline appears and the list stays where you left it.
