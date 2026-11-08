# Enchanting guide 1-300 (design)

Date: 2026-11-08. Game data: WoW: Forever build 1.60.1.70862 (wago.tools, product `wowf`).
Builds on the profession guides (`2026-11-07-profession-guides-design.md`) and the Tailoring guide
(`2026-11-07-tailoring-guide-design.md`): the same tab, crafting window guide, cards, trainer check,
game checks and `parts`. This spec covers what Enchanting adds.

## Goal

A complete Enchanting 1-300 guide for WoW: Forever inside the Codex: recipe facts from the game's own
tables (checked by the harness), server-side facts from the guides (checked in game).

Decided with the owner:
- Route: **cheapest, formulas allowed** where a vendor formula saves materials and the vendor needs no
  reputation. Reputation formulas (Lesser Mana Oil from Lokhtos) are only alternatives.
- **Disenchanting section**: the required-level table, your step's material marked, and the green and
  blue items in your bags with what each would give.
- **Rods**: each step names its rod. A better rod counts, as the game files say. The crafting window
  outlines a missing rod first, and Motes when you only have the dust.
- Approach: Enchanting data on the existing profession code, plus `rods`, `disenchant` and a new
  `Disenchant.lua` (bag scan). Mote of Magic is a `part` like Tailoring's bolts.

## What the game and the sources say

### From the client tables (exact)
- Enchanting is skill line 333: 261 recipes; every recipe gives 1 point per craft; no client learn
  levels (`MinSkillLineRank`). Two names exist twice (`clashes`): Enchant Bracer - Agility, Greater
  Mystic Wand.
- Learned with Enchanting (`AcquireMethod` 1): Disenchant, Dust to Motes, Enchant Bracer - Inferior
  Stamina, Enchant Bracer - Minor Deflect, Novice's Practice Wand, Runed Copper Rod.
- New in Forever: **Mote of Magic**. Dust to Motes turns 1 Strange Dust into 3 Motes (y10/gr15). Runed
  Copper Rod is now Copper Rod + 1 Mote (y5/gr10), and Enchant Bracer - Inferior Stamina is 1 Mote (y20/gr25).
- **Disenchant** is on the skill line with colours y20 / g40 / gr60 (it gives points; Wowhead: every
  disenchant until 20, less often until 60). `ItemDisenchantLoot.SkillRequired` is 0 in every row: any
  skill can disenchant.
- **Rods** (`SpellTotems.RequiredTotemCategoryID`, `TotemCategory`, `ItemSparse.TotemCategoryID`):
  373 Runed Copper Rod (mask 1), 374 Runed Silver Rod (3), 375 Runed Golden Rod (7), 376 Runed Truesilver
  Rod (15), 377 Runed Arcanite Rod (31). A rod's mask holds the lower rods' bits, so a better rod counts for
  the enchants of the lower ones.
- **Enchant Cloak - Superior Defense needs the Truesilver rod (376), not Arcanite.** (Wowhead's route
  makes a Runed Arcanite Rod at 294 for it.)
- `ItemDisenchantLoot` level bands for green (quality 2) weapons and armour: 5-15, 16-20, 21-25, 26-30,
  31-35, 36-40, 41-45, 46-50, 51-55, with blue and epic bands. The loot itself (which dust) is server-side.
- Zones (AreaTable): Riverglades is 16591, Zephras Isle 16593, Uldaman 1337.
- Forever's UI (Gethe/wow-ui-source, branch `forever`) has `Blizzard_Professions` and no Craft UI:
  Enchanting opens in the same Professions window as the other professions.

### Not in the client (server-side)
From Wowhead Forever (skill page 333 and tier spells, read 8 Nov; leveling guide, 3 Nov; Enchanting
overview):
- Learn levels (`learnedat`) of trainer recipes, and which recipes trainers teach (62, up to 250).
- Who teaches each tier (tier spells' taught-by lists, not the NPC tags):
  - Apprentice: any Enchanting trainer, including Eaysaa Brightgust and Nasalanna Windsinger on
    Zephras Isle.
  - Journeyman (skill 50): every Expert, Master and Artisan Enchanter, Vanessa Sellers (Alterac
    Mountains) and Melanie Sable (Riverglades). Not the Journeyman Enchanters, and not the
    Zephras Isle trainers.
  - Expert (skill 125): Kitta Firewind (Elwynn Forest, Alliance), Hgarth (Stonetalon Mountains, Horde),
    Vanessa Sellers (Alliance), Melanie Sable (Riverglades), Annora (Uldaman, both).
  - Artisan (skill 200): Annora only, inside Uldaman. (The overview's table says 225; the Artisan spell says
    200, which the guide uses as for the other professions.)
  - Levels 10 / 20 / 35.
- Formula vendors (item "sold by" lists):
  - Formula: Enchant Cloak - Minor Agility (skill 110): Dalria (Trade Goods, Ashenvale, Alliance) or
    Kulwia (Trade Supplies, Stonetalon Mountains, Horde), 8s42.
  - Formula: Enchant Shield - Greater Stamina (skill 265): Mythrin'dir (Darnassus, Alliance), 1g26, or
    Daniel Bartlett (Undercity, Horde), 1g07; one at a time.
- Mote of Magic and the Copper Rod come from enchanting supply vendors (Wowhead's guide and overview;
  "unconfirmed until checked on a live realm").

From wow-professions' Forever disenchanting guide (undated, 2026):
- The disenchanting table by **required level** (the tooltip's "Requires Level"):
  - 1-10: Strange Dust, Lesser Magic Essence.
  - 11-15: Strange Dust, Greater Magic Essence, Small Glimmering Shard.
  - 16-20: Strange Dust, Lesser Astral Essence, Small Glimmering Shard.
  - 21-25: Soul Dust, Greater Astral Essence, Large Glimmering Shard.
  - 26-30: Soul Dust, Lesser Mystic Essence, Small Glowing Shard.
  - 31-35: Vision Dust, Greater Mystic Essence, Large Glowing Shard.
  - 36-40: Vision Dust, Lesser Nether Essence, Small Radiant Shard.
  - 41-45: Dream Dust, Greater Nether Essence, Large Radiant Shard.
  - 46-50: Dream Dust, Lesser Eternal Essence, Small Brilliant Shard.
  - 51-55: Illusion Dust, Greater Eternal Essence, Large Brilliant Shard.
  - 56-60: Illusion Dust, Greater Eternal Essence, Large Brilliant Shard.
  - Its band edges (10, 15, 20 ...) sit five levels below the client's item-level edges (15, 20, 25 ...),
    which supports the table.
- Green armour: 75% dust, 20% essence; green weapons the reverse; shards 3-5%. Blue items give a shard.
- Disenchanting needs no skill; Disenchant is dragged from the Professions window.

## The route

Crafts are expected counts from the colours (`expected_crafts`); the Codex recomputes them from your
real skill. Materials are for the whole step. About 326 crafts.

| Skill | Recipe | Learn | Rod | ~Crafts | Materials | Alternative / note |
|---|---|---|---|---|---|---|
| 1-10 | Dust to Motes | known | - | 9 | 9 Strange Dust | Makes 27 Motes. Then make the Runed Copper Rod: Copper Rod + 1 Mote. Disenchanting greens also gives points until 20. |
| 10-20 | Enchant Bracer - Inferior Stamina | known | Copper | 10 | 10 Mote of Magic | Disenchanting green items |
| 20-90 | Enchant Chest - Inferior Stamina | 15 | Copper | 78 | 78 Strange Dust | Lesser Magic Wand (10, no rod: Simple Wood + Lesser Magic Essence) |
| 90-100 | Enchant Bracer - Minor Stamina | 50 | Copper | 10 | 20 Strange Dust | Enchant Chest - Minor Absorption (40, Lesser Magic Essence) |
| 100-101 | Runed Silver Rod | 100 | - | 1 | Silver Rod, 3 Strange Dust, 4 Lesser Magic Essence, Shadowgem | Every enchant from 110 needs it; it also counts as a Copper rod. |
| 101-110 | Enchant Bracer - Minor Stamina | 50 | Copper | 11 | 22 Strange Dust | |
| 110-135 | Enchant Cloak - Minor Agility | 110 | Silver | 25 | 25 Lesser Astral Essence | Formula: Dalria (Ashenvale) / Kulwia (Stonetalon), 8s42. Enchant Chest - Stamina (120, trainer) |
| 135-155 | Enchant Bracer - Lesser Stamina | 130 | Silver | 20 | 20 Soul Dust | |
| 155-156 | Runed Golden Rod | 150 | - | 1 | Golden Rod, Iridescent Pearl, Greater Astral Essence, Soul Dust | Needed from 160. |
| 156-160 | Enchant Bracer - Lesser Stamina | 130 | Silver | 5 | 5 Soul Dust | |
| 160-180 | Enchant Boots - Lesser Agility | 160 | Golden | 20 | 20 Soul Dust | Enchant Bracer - Lesser Strength (formula, Dalria / Kulwia) |
| 180-200 | Enchant Bracer - Strength | 180 | Golden | 20 | 20 Vision Dust | |
| 200-201 | Runed Truesilver Rod | 200 | - | 1 | Truesilver Rod, Black Pearl, Greater Mystic Essence, Vision Dust | Needed from 220; the last rod the route needs. |
| 201-220 | Enchant Bracer - Strength | 180 | Golden | 27 | 27 Vision Dust | |
| 220-225 | Enchant Cloak - Greater Defense | 205 | Truesilver | 5 | 5 Vision Dust | |
| 225-250 | Enchant Gloves - Agility | 210 | Truesilver | 33 | 33 Vision Dust | Enchant Chest - Superior Stamina (220, 3 Vision Dust) |
| 250-265 | Enchant Bracer - Greater Strength | 240 | Truesilver | 16 | 16 Dream Dust, 32 Lesser Nether Essence | Lesser Mana Oil (Lokhtos Darkbargainer, Blackrock Depths, Thorium Brotherhood reputation) |
| 265-300 | Enchant Shield - Greater Stamina | 265 | Truesilver | 39 | 234 Dream Dust | Formula: Mythrin'dir (Darnassus) / Daniel Bartlett (Undercity). Needs any shield (a cheap vendor one is fine). Enchant Cloak - Superior Defense from 285 (Lorelae Wintersong, Moonglade; 8 Illusion Dust, Truesilver rod) |

Whole route: about 250 Dream Dust, 132 Strange Dust (Motes included), 86 Vision Dust, 46 Soul Dust,
32 Lesser Nether Essence, 25 Lesser Astral Essence, 4 Lesser Magic Essence, the four rods' materials, a
Copper Rod.

Where it differs from Wowhead's route (3 Nov), and why:
- 1-20 **Dust to Motes and the Inferior Stamina bracer** instead of disenchanting: works without green
  items; the steps mention disenchanting.
- 20-90 **Chest - Inferior Stamina** (1 Strange Dust) instead of Lesser Magic Wand (essence and wood).
- 160-180 **Boots - Lesser Agility** (trainer) instead of the Bracer - Lesser Strength formula: same Soul
  Dust, no formula.
- 225-250 **Gloves - Agility** (1 Vision Dust) instead of Boots - Stamina and Chest - Superior Stamina
  (2-3 per craft).
- 250-265 **Bracer - Greater Strength** (trainer) instead of Lesser Mana Oil (reputation).
- 265-300 **Shield - Greater Stamina** to the end instead of the Runed Arcanite Rod + Cloak - Superior
  Defense: the game files say Superior Defense needs the Truesilver rod, and Shield - Greater Stamina is
  yellow until 305; Dream Dust instead of 120 Illusion Dust and an Arcanite rod.

Each enchant step's note says what to enchant, from its name ("Enchant your own bracers again and
again: each enchant replaces the last"; shields: "any shield, a cheap vendor one is fine").

## Rods

`ENCHANTING.rods`: Runed Copper, Silver, Golden and Truesilver Rod, each `{ name, category, mask, spell,
icon, yellow, grey, mats, learn, source }` (recipe fields as a step's). Each enchant step names its
`rod` (the rod's name).
- `ns.profRod(key, step)`: the step's rod entry, or nil.
- `ns.profHasRod(key, rod)`: true when your bags hold that rod or any rod whose mask contains its mask
  (`GetItemCount`), nil when the client can't count items.
- Step card in the tab: "Rod: Runed Silver Rod (you have it)" or "Rod: Runed Silver Rod - you need it:
  Silver Rod, 3 Strange Dust, 4 Lesser Magic Essence, Shadowgem (learn at 100)".
- The Runed Copper Rod is not a step (it gives points only to 10, after Dust to Motes): the 10-20 step
  lists `extra = { { "Copper Rod", 1 } }`, so the shopping list counts it until that step starts.

## Mote of Magic

`ENCHANTING.parts`: Dust to Motes, `{ makes = { "Mote of Magic", 3 }, mats = { { "Strange Dust", 1 } },
plural = "Motes of Magic" }` with its recipe fields. The 1-10 step carries `makes = { "Mote of Magic", 3 }`.
The shopping list counts Motes as Strange Dust (`via` "for N motes"), as for bolts. The "make them from"
line on the step card and the crafting window's parts-first pick work as for Tailoring.

## Crafting window

In `pickFor`, in this order:
1. **Rod first**: the step names a rod, `ns.profHasRod` is false, and the rod's recipe is in the window.
   The card says "Make your Runed Silver Rod first: every enchant from here needs it."
2. **Parts first** (Motes, as Tailoring's bolts).
3. The step's recipe.

The step's own recipe must be in the window for 1 and 2 (else the "not learned" card comes first, as
for Tailoring). Show it, the trace and the controller auto-select follow the pick. A rod pick, like a part
pick, skips the "Grey now" branch: the Truesilver Rod is grey from 260 but still needed to 300.

## Disenchanting section

`ENCHANTING.disenchant`: 11 bands `{ from, to, dust, essence, shard }` (the table above, by required level;
`shard` is nil for 1-10), plus `odds` text.
- Tab section **DISENCHANTING** (where Tailoring shows cloth):
  - One line: "Disenchant any green or blue weapon or armour, at any skill: green armour mostly gives
    dust, green weapons mostly essence, blue items a shard."
  - The bands, one row each ("Level 26-30: Soul Dust, Lesser Mystic Essence, Small Glowing Shard"). A band
    is marked "you need this now" and comes first when its dust, essence or shard is one of your step's
    materials, or the material of a part your step uses (Motes: Strange Dust). `ns.deNeeded(key, step)`
    returns those material names.
  - "3 Lesser make 1 Greater, and back: right-click the essence."
  - **IN YOUR BAGS**: up to 8 green, blue or epic weapons and armour from your bags, "Name (level 22):
    Soul Dust or Greater Astral Essence" (blue: the shard). Items giving your step's material first, then by
    required level. With none: "No green or blue weapons or armour in your bags."
- `Disenchant.lua` (new, after Professions.lua in both .toc files):
  - `ns.deBand(key, level)`: the band for a required level, or nil.
  - `ns.deBagItems(key)`: `{ { name, level, quality, weapon, gives } }` from `C_Container`
    (`GetContainerNumSlots`, `GetContainerItemInfo`) else the classic bag calls, and `GetItemInfo`
    (quality, required level, class). Items not yet loaded by the client are skipped; nil when there's
    no bag API (the section then shows only the table).

## Code

- `tools/gamedata.py`: `PROFESSIONS` gains `"Enchanting": 333`; `TABLES` gains `TotemCategory` and
  `ItemDisenchantLoot`. Each recipe that needs a tool gets `tool` (the totem category's name; Blacksmithing
  hammers too). The reference gets `rods`: `{ name: { category, mask, item } }` for the Runed rods.
  `audit_professions`: a step's `rod` must equal its recipe's `tool`; each `rods` entry's category and mask
  must equal the reference and be checked like a recipe; every disenchant dust/essence/shard must be an
  item an Enchanting recipe uses; bands contiguous 1-60.
- `ProfessionData.lua`: `ENCHANTING = { name = "Enchanting", skillLine = 333, icon (the client's Enchanting skill-line icon), tiers, steps, parts,
  rods, disenchant }`.
- `Professions.lua`: `"ENCHANTING"` in `PROF_ORDER`; `ns.profRod`, `ns.profHasRod`.
- `Disenchant.lua`: as above.
- `ProfessionTab.lua`: rod and target lines on the step card; the disenchanting section.
- `ProfessionGuide.lua`: the rod-first pick.
- Settings text (crafting window and skill-up cards) names Enchanting.

## Testing

Harness (every class, full and minimal):
- Shape checks: `rods` and `disenchant` fields, ASCII text, each step's `rod` is in `rods`, bands 1-60
  without gaps.
- Game checks (existing, now on Enchanting) plus the new rod, tool and disenchant checks; the reference
  diff is Enchanting plus `tool` fields and `rods`.
- Scenarios:
  1. Enchanting tab at 1, 150 and 260: step, rod line (have / need), target line, shopping list with
     Motes counted as Strange Dust and no Mote row, the disenchanting section with the right band marked.
  2. A better rod counts (a Runed Truesilver Rod in bags at 150 satisfies the Silver rod).
  3. Bag scan (mocked bags): a green level-22 armour item lists Soul Dust or Greater Astral Essence; a
     white item, a non-weapon/armour item and an item not loaded yet are left out; the 8-row cap.
  4. Minimal client (no bag calls, no `GetItemCount`): the tab renders, the table shows, no bag list and
     no "you have".
  5. Crafting window: no rod but the rod recipe listed: rod outlined; with the rod: step's recipe; the
     step's recipe missing: "not learned", not the rod; dust but no Motes at 10: Dust to Motes outlined.
  6. `/codex debug` line, a skill-up card at a new step, the level-up training row, the classic skill list.
  7. Blacksmithing, Mining and Tailoring scenarios unchanged.

In game:
- Copper Rod and Mote of Magic at the enchanting supply vendor; the formula vendors and their stock.
- Disenchant in the Professions window; the bag list against your real bags.
- Annora as the only Artisan trainer; `/codex debug` at a trainer for the learn levels.
- The rod-first card in Forever's Professions window.
- A client restart (new file in the .toc).

## Docs

CLAUDE.md (data shape `rods`, `disenchant`; modules; tests), CHANGELOG (v0.12.0), README,
CURSEFORGE_DESCRIPTION, `tools/audits/2026-11-08-enchanting.md` (every fact with its source).

## Risks

- Learn levels, vendors and the disenchanting table are server-side: every step has an alternative, the
  trainer check records real requirements, and the table's bands agree with the client's.
- The bag APIs and `GetItemInfo`'s returns in Forever are unconfirmed: guarded; the table works without them.
- Rods counting for lower ones comes from the client's masks; if the server disagrees, the card says
  "Make your Runed X Rod" when you already hold a better one.

## Out of scope

- Disenchanting odds per item, Auction House prices, warnings before disenchanting.
- Enchanting's new staves, wands, idols and trinkets; necklace enchants; Azeroth Commerce Authority formulas.
- Runed Arcanite Rod (not needed to 300 in Forever).
