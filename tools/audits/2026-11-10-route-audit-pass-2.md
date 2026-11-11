# 2026-11-10: Second audit of the Alliance 1-30 guides (loops, gaps, Forever quests, alternates)

This pass checked every leveling guide added this month, using four checks:

- the quest-ID diff against the first reference guide, rerun;
- the same diff against the other reference guide's Forever chapters, using quest IDs only, to find Forever-only quests that the first doesn't route;
- a loop check over the route data;
- a link check over the alternate routes.

The scripts live in the session scratchpad (`xref.py`, `missing.py`, `xref2.py`, `loops.py`, `alts.py`). The rules are short enough to rewrite.

## 1. Loop check

**How it works.**
- For every turn-in, the script asks whether the route had already passed within 40 yards of that NPC, after the quest was ready, and then walked more than 150 yards away before coming back.
- Pickups get the same check once their prerequisites are turned in.
- Distances use the route's map extents in yards.

**What it can't tell.** The script can't see level gates, so a pickup that only opens at a later level looks like a missed pickup. Class-only steps (rune quests, trainers) look sequential when only one of them applies.

**What it found, before and after this pass:**

| Guide | Detour found | Fix |
|---|---|---|
| Westfall | Saldean's Farm: Ozwin (300 yd west) came between the two Salma Saldean turn-ins. | Salma's turn-ins come first, then Ozwin. |
| Westfall | Sentinel Hill: Alba Fairmoon came between Quartermaster Lewis and Gryan Stoutmantle, who stand together. | Gryan comes before Alba, and Alba is on the way to the Moonbrook road. |
| Wetlands | Menethil arrival: The Doomed Fleet was handed to Glorin (outside the inn) only after a lap of the town. | Glorin comes right after binding at the inn. |
| Wetlands | Menethil return: after hearthing, the route visited the keep and docks, then walked back to Glorin at the inn. | Glorin's three steps come first after the hearth. |
| Wetlands | Stormwind (end of chapter): Dwarven District, Cathedral, park, Keep, harbor, zig-zagging across the city. | New order: Dwarven District, Keep, Cathedral, park, harbor. Bolvar's follow-up rides along (section 3). |
| Darkshore | First Auberdine return: Alanndarian, Gubber and Terenthis in turn, then back to Tharnariun, who stands next to Terenthis. | New order: Terenthis and Tharnariun, then Alanndarian and Thundris (north), then the fishing and Gubber (south). |
| Darkshore | Auberdine after the hearth: Thundris and Tharnariun were visited twice. | One pass: Terenthis/Tharnariun, Thundris, Hollee, Glynda, Gubber, Gwennyth. |
| Teldrassil | Dolanaar: Corithras (south) came between Tallonkai and the Aldia/Laurna turn-ins next to him. | Aldia and Laurna come first. |
| Teldrassil | Twisted Hatred was picked up after the hunter taming loop, which non-hunters walk straight past. | It's picked up with Athridas's quest next to Tallonkai. |
| Teldrassil | Dolanaar after the hearth: Tallonkai came after Corithras (south). | Tallonkai comes first. |
| Shen'dar / Valanaar | Class training came between the turn-ins at the same hub. | Turn-ins first, then training. Turn-in XP can also bring the next spell rank. |
| Darkshire (late) | Silvia's Sword and Merrick's Bow were handed to Sirra after a walk east to Viktori. | Both come at the first Sirra visit. |
| Ashenvale (late) | Raene's Cleansing was picked up only after a trip west and north and back to Astranaar. | It's picked up before leaving Astranaar, with a travel step to Krolg. |

Each guide's total walking distance changed by under 5%. The new quests account for most of the remaining difference.

**Left as is (false alarms or not worth it):**
- Coldridge and Shadowglen rune quests (one class each).
- Northshire's Brotherhood of Thieves and Kharanos's Frostmane Hold (level-gated).
- Loch Modan's optional Stormpike's Order.
- Valanaar's class trainers.
- Menethil's Lightforge Iron: it's picked up on the same visit as the other two Glorin steps.

## 2. First reference guide diff, rerun

The first reference guide's Alliance quests up to level 30 that we still don't route are unchanged since the first pass. Each has a reason in the area audits. In brief:

- not in the Forever client: 308, 1641, 1645, 117;
- level 31 or higher, or a link into it: 538, 55, 225-231, Nek'rosh, 634, Stranglethorn, Sara Balloo, Brassbolts, James Hyal;
- group fights;
- detours that cost more than they give: Messenger to Darkshire, the Kristoff ink chain, the Thunderbrew rivals, Fishin' Time;
- items you must make first;
- breadcrumbs with a better route: Grove of the Ancients, Trouble in Darkshore?, Expanding Horizons;
- Horde-only Zephras steps.

**Humble Beginnings (399), re-checked.** The quest is accepted in Stormwind, the compass is at Alexston Farmstead in Westfall, and the turn-in is back in Stormwind. Our route never passes the farmstead between two Stormwind visits before level 18, so it would cost a dedicated round trip. It stays out.

## 3. Forever quests the first reference guide doesn't route (from the other guide's quest IDs, facts checked with `questfacts.py`)

| Quest | Where it went | Notes |
|---|---|---|
| Camping 101: Skinning 96056 (Dwarf/Gnome) | `dunmorogh`: offered by Eric Brighthammer in Kharanos. Turned in to Balthus Stoneflayer, the Ironforge skinning trainer, on the level 12 Ironforge visit. | Optional, like Elwynn's. The other reference guide tracks a "Skinning 20" objective, and the step says so. |
| Camping 101: Skinning 97949 (Night Elf) | `teldrassil`: offered by Lyreena in Dolanaar. Turned in to Radnaal Maneweaver beside the Darnassus road. | Optional. Skinning 20. |
| Business in Auberdine 97894 | `darkshore` lead-in: Borgus Steelhand (Stormwind, Dwarven District) to Gorbold Steelhand in Auberdine. | Optional and for races that leave from Stormwind, like Making Do. The turn-in shows whenever it's in your log. |
| Reading Room 97234 / Shelf Picked 97237 | `lakeshire`: added to the Stormwind visit for Messenger to Stormwind. Roy Lewells (park), then Donyal Tovald's library, four books, then back to Roy. | Optional: the errand crosses the city twice for two level 18 quests. |
| Unrequited Love 98461 | `darkshore`: taken from Hollee at the last Auberdine visit. Turned in to Tarrel Rockweaver in Menethil (`wetlands`). | Optional breadcrumb for players who continue to the Wetlands. The turn-in shows whenever it's in your log. |
| A Friend of the Family 98191 | `wetlands`, Stormwind: Bolvar, then Lord Grayson Shadowbreaker in the Cathedral. | Follows 98190, which the route already gave to Bolvar. On the way, no detour. |
| The Shamed Lieutenant 98219 | Grayson in Stormwind to Lieutenant Farren Orinelle in `southshore`. | Optional, level 30. The Southshore turn-in shows whenever it's in your log. |
| Vengeful Trail 98417 / Shared Fury 98418 | `ashenvale-late`, the last eastern circuit: Maseara Autumnmoon in Forest Song, the Vine-Wrapped Scroll at Satyrnaar, then the Xavian satyrs alongside Geltharis. | Level 30, main route. |

**Not added:**
- Desperate Prayer referrals 5635/5637 and The Hunter's Path 6071: the class guides go straight to the capital trainer or Dazalar. These are breadcrumbs to them.
- 77573: the client has the ID, but neither source names it.
- Soothing Turtle Bisque 555: needs Cooking, level 31.

**Cozy Sleeping Bag.** Neither reference routes it inside the leveling chapters. One has no Alliance version at all, and the other keeps a separate guide. Ours is the Cozy Sleeping Bag special guide (QuestSpecialData.lua). Until now nothing in the route pointed to it.

## 4. Alternate routes and special guides

**Coverage.** Every level from 12 to 30 has at least three leveling guides: the main route plus two or more alternates.

**Who points where.** Every alternate is suggested by at least one guide end and one in-route step.

**Suggestions past a guide's level range.** Four step suggestions point at a guide that's past its range at that step's level:

| Step | Suggests | Result |
|---|---|---|
| Ashenvale level 22 | Darkshore, 12-20 | Replaced with Stonetalon |
| Duskwood 26 | early Wetlands, 20-25 | Kept: 1 level over |
| Late Ashenvale 30 | late Redridge, 23-29 | Kept: 1 level over |
| Early Wetlands 23 | Lakeshire, 17-22 | Kept: 1 level over |

The Quests tab already marks a guide as Outleveled.

**Special guides now have a way in.** A new `withGuide(id, step)` helper in QuestData.lua sets `step.guide`. The step window then offers "Plan <guide>" and the Quests tab shows a Plan button while that step is current.
- **Cozy Sleeping Bag:** the Westfall level 15 grind step.
- **The Legend of Stalvan:** Madame Eva's pickup in Darkshire.
- **The Missing Diplomat:** the Lord Grayson step in the Cathedral, where its first NPC, Thomas, also stands.

Dungeons need no link: dungeon plans and Run <dungeon> cover them.

## 5. Tool change

`tools/questroute.py audit` now skips an optional turn-in (or objective) whose quest is never picked up in that path. These are carried breadcrumbs: Unrequited Love, The Shamed Lieutenant, Business in Auberdine. The guide shows them only while the quest is in your log, so they need no pickup in the same guide. Non-optional steps are still checked as before.

Route audit: 2970 steps, passes. Full harness: passes.

## Things to check in game

- **Dun Morogh / Teldrassil with Skinning and Show optional quests on:** the Camping 101: Skinning lesson is offered at Eric (Kharanos) and Lyreena (Dolanaar). Check that Balthus (Ironforge) and Radnaal (Darnassus road) take it at Skinning 20.
- **Lakeshire's Stormwind trip with optional quests on:** Roy Lewells in the park and Donyal Tovald's library at 75, 30. Check the four book spots.
- **Darkshore:** Hollee offers Unrequited Love, and Tarrel in Menethil takes it.
- **Leaving Stormwind for Auberdine:** check that Borgus Steelhand offers Business in Auberdine.
- **End of the Wetlands, Stormwind:** Bolvar offers A Friend of the Family (part 2), and Grayson takes it. Check the level The Shamed Lieutenant needs (the data has none). Farren in Southshore takes it.
- **Late Ashenvale:** Maseara Autumnmoon in Forest Song, the scroll at 80.9, 49.6, and the Xavian kills.
- **The reordered town loops:** Saldean's Farm, Sentinel Hill, Menethil (arrival and return), Auberdine (both returns), Dolanaar, Darkshire's last turn-ins, and Astranaar before the west trip should each feel like one pass.
- **Plan buttons:** "Plan Cozy Sleeping Bag" at the Westfall level 15 step, "Plan The Legend of Stalvan" on Madame Eva's step, and "Plan The Missing Diplomat" on Grayson's step.
