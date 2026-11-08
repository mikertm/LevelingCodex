# Tailoring guide 1-300 (design)

Date: 2026-11-07. Game data: WoW: Forever build 1.60.1.70862 (wago.tools, product `wowf`).
Builds on the profession guides (`2026-11-07-profession-guides-design.md`): same tab, crafting
window trace, cards, trainer check and game checks. This spec covers only what Tailoring adds.

## Goal

A complete Tailoring 1-300 guide for WoW: Forever inside the Codex, built like the Blacksmithing
one: recipe facts from the game's own tables (checked by the harness), server-side facts from the
guides and checked in game.

Decided with the owner:
- Route: **cheapest, trainer recipes**, patterns only where the trainer has nothing (the
  Blacksmithing rule). Forever's trainers stop at Runecloth Belt (225), so 235-300 uses vendor
  patterns.
- **Cloth section with mob levels and zones** for your faction, where Mining shows veins.
- Approach **A**: Tailoring data plus two additions, `parts` (bolts counted as raw cloth) and
  `cloth`. Everything else already works for any profession in `PROF_ORDER`.
- The route below (changes from Wowhead's route listed under *The route*), bolts first in the
  crafting window, the code and test plan.

## What the game and the sources say

### From the client tables (exact)
- Tailoring is skill line 197: 452 recipes. Forever re-tuned the colours: most recipes turn yellow
  10-15 points earlier than in Classic (Bolt of Silk Cloth 110/120, Azure Silk Hood 130/140,
  Bolt of Runecloth 210/215).
- Forever added about 340 pattern recipes (Stormsewn, Filigreed, Flame/Pearly/Pristine/Shadow/
  Shining/Silky, Black/Fiery/Frothing/Gilded/Golden/Radiant, Nether*, Earthenweave, Ghostweave,
  Scarlet Augur's, Swarmtender's, Venomspew...) and about two dozen second copies of Classic
  recipes under new spell IDs (`clashes` in the reference; the route uses the Classic IDs).
- Known with the profession (`AcquireMethod` 1): Bolt of Linen Cloth, Brown Linen Shirt,
  Linen Bag, Linen Cloak, Simple Linen Pants. (Wowhead lists Linen Bag as taught at 5.)
- Every recipe gives 1 point per craft. The client sets no learn level (`MinSkillLineRank`) on
  any Tailoring recipe.
- Swarmtender's and Venomspew items have the placeholder icon `temp` in the client.
- Zone names (AreaTable): every zone below exists, including Mount Hyjal (616) and Zephras Isle
  (16593).

### Not in the client (server-side), from Wowhead Forever (recipe and trainer data, 7 Nov; leveling guide and Tailoring overview, 4 Nov)
- **Learn levels** (`learnedat`), used as `learn`. The patterns' own skill (`RequiredSkillRank`)
  agrees for every pattern in the route.
- **Which recipes trainers teach**: trainer recipes run up to Runecloth Belt (225). Every
  Runecloth recipe above it is a vendor or drop pattern (Classic trainers taught several).
- **Who teaches each tier** (taught-by lists, not the NPC tags; the tags are misleading, as for
  Blacksmithing):
  - Apprentice: any Tailoring trainer, including Taleen Shimmerthread and Othesia Evengale on
    Zephras Isle.
  - Journeyman (skill 50): every Expert, Master and Artisan Tailor, Lawrence Schneider
    (Stormwind) and the two Zephras Isle trainers; not the other Journeyman Tailors.
  - Expert (skill 125): Georgio Bolero and Lawrence Schneider (Stormwind), Charles Worth
    (Alterac Mountains), Timothy Worthington (Theramore, Dustwallow Marsh) for the Alliance;
    Josef Gregorian (Undercity) and Daryl Stack (Tarren Mill, Hillsbrad Foothills) for the Horde.
  - Artisan (skill 200): Timothy Worthington (Alliance) and Daryl Stack (Horde) only.
  - Levels 10 / 20 / 35 for Journeyman / Expert / Artisan, as for every profession (guides agree).
- **Pattern vendors**: Qia (Trade Goods Supplies, Everlook, Winterspring): Runecloth Gloves 1g68,
  limited stock. Darnall (Tailoring Supplies, Nighthaven, Moonglade): Runecloth Cloak 1g20,
  Runecloth Boots 2g, limited stock. Pexmit (Mount Hyjal): Runecloth Cuffs 10g. Mishta (General
  Trade Goods, Cenarion Hold, Silithus): Venomspew and Swarmtender's patterns 7g50 each.
- **Disagreements**: Wowhead's leveling guide does Bolt of Runecloth at 205-214 and Runecloth
  Belt at 214-234, but its recipe data says they're taught at 210 and 225. The route starts them
  at 210 and 225 (works either way); the alternative says to use the Belt earlier if the trainer
  offers it, and the trainer check (`/codex debug`) records the real requirement.
- **Cloth drops** (Wowhead "dropped by" lists, the 200 best droppers of each cloth, counted where
  at least 15% of 20+ kills dropped it): mob levels are the 10th-90th percentile of those NPCs'
  levels; zones are the ones with the most such NPCs, split by faction.

Other Forever guides (wow-professions, beta; metabot, generated from the client with guessed
learn levels) agree up to 225 in shape and are untested past it.

## The route

Crafts are expected counts from the colours (`expected_crafts`, the same formula the Codex uses);
the Codex recomputes them from your real skill. Materials are for the whole step.

| Skill | Recipe | Learn | ~Crafts | Materials | Alternative / note |
|---|---|---|---|---|---|
| 1-37 | Bolt of Linen Cloth | known | 39 | 79 Linen Cloth | Keep the bolts: the next two steps take 56. |
| 37-70 | Linen Belt | 15 | 41 | 41 Bolt of Linen Cloth, 41 Coarse Thread | Brown Linen Vest (10, orange until 45) |
| 70-75 | Reinforced Linen Cape | 35 | 7 | 15 Bolt of Linen Cloth, 22 Coarse Thread | Train Journeyman (skill 50, level 10) before 75. |
| 75-77 | Bolt of Woolen Cloth | 55 | 3 | 9 Wool Cloth | Points only to 77; make the rest of the 89 bolts as you go. |
| 77-100 | Woolen Cape | 55 | 31 | 31 Bolt of Woolen Cloth, 31 Fine Thread | Heavy Woolen Gloves (60, 3 bolts) |
| 100-110 | Bolt of Silk Cloth | 100 | 10 | 40 Silk Cloth | Orange the whole step. |
| 110-125 | Double-stitched Woolen Shoulders | 85 | 19 | 57 Bolt of Woolen Cloth, 38 Fine Thread | Heavy Woolen Pants (85, 5 bolts). Train Expert (125, level 20) before 150. |
| 125-132 | Azure Silk Hood | 120 | 7 | 14 Bolt of Silk Cloth, 14 Blue Dye, 7 Fine Thread | Silk Headband (125, 3 bolts) |
| 132-140 | Lesser Wizard's Robe | 110 | 9 | 19 Bolt of Silk Cloth, 19 Fine Thread, 19 Spider's Silk | Azure Silk Pants (115: 4 bolts, 2 Blue Dye, 3 Fine Thread) |
| 140-147 | Bolt of Mageweave | 140 | 7 | 36 Mageweave Cloth | Points only to 147. |
| 147-160 | Earthen Vest | 135 | 13 | 40 Bolt of Silk Cloth, 13 Elemental Earth, 26 Fine Thread | Azure Silk Vest (125: 5 bolts, 4 Blue Dye) |
| 160-170 | Crimson Silk Vest | 150 | 10 | 40 Bolt of Silk Cloth, 20 Red Dye, 20 Fine Thread | Long Silken Cloak (150: 4 bolts, a Mana Potion) |
| 170-180 | Black Mageweave Vest | 170 | 10 | 20 Bolt of Mageweave, 30 Silken Thread | Black Mageweave Leggings (same cost) |
| 180-190 | Orange Mageweave Shirt | 180 | 11 | 11 Bolt of Mageweave, 11 Orange Dye, 11 Heavy Silken Thread | Black Mageweave Vest (yellow) |
| 190-205 | Black Mageweave Gloves | 180 | 16 | 33 Bolt of Mageweave, 33 Heavy Silken Thread | Train Artisan (200, level 35) before 225: Timothy Worthington or Daryl Stack. |
| 205-210 | Black Mageweave Headband | 205 | 5 | 16 Bolt of Mageweave, 10 Heavy Silken Thread | Black Mageweave Shoulders (same cost) |
| 210-212 | Bolt of Runecloth | 210 | 2 | 11 Runecloth | Points only to 212; the route needs 460 bolts. |
| 212-225 | Black Mageweave Headband | 205 | 24 | 72 Bolt of Mageweave, 48 Heavy Silken Thread | Runecloth Belt, if your trainer already teaches it (Wowhead's guide: from 214) |
| 225-235 | Runecloth Belt | 225 | 11 | 35 Bolt of Runecloth, 11 Rune Thread | |
| 235-260 | Runecloth Gloves | 230 | 30 | 121 Bolt of Runecloth, 121 Rugged Leather, 30 Rune Thread | Runecloth Cloak (220) then Runecloth Boots (235), Darnall, Moonglade |
| 260-285 | Runecloth Cuffs | 250 | 36 | 184 Bolt of Runecloth, 36 Ironweb Spider Silk, 36 Rune Thread | Green from 280. Runecloth Boots to 265; Wisdom of the Timbermaw (Meilosh, Felwood, Timbermaw reputation) |
| 285-290 | Venomspew Gloves | 285 | 5 | 20 Bolt of Runecloth, 5 Small Brilliant Shard, 15 Essence of Air, 30 Rune Thread | Swarmtender's Gloves (Essence of Water) |
| 290-300 | Venomspew Cord | 290 | 16 | 98 Bolt of Runecloth, 16 Small Brilliant Shard, 49 Essence of Air, 98 Rune Thread | Swarmtender's Cord (Essence of Water) |

Sources: *known* = learned with Tailoring; 15-225 = Tailoring trainer (the tier's trainers above);
Runecloth Gloves = Pattern from Qia, Everlook (Winterspring); Runecloth Cuffs = Pattern from
Pexmit, Mount Hyjal; Venomspew = Patterns from Mishta, Cenarion Hold (Silithus).

About 372 crafts. Whole route: about 114 Linen, 268 Wool, 456 Silk, 769 Mageweave and 2301
Runecloth, 207 Rune Thread, 144 Fine Thread, 121 Rugged Leather, 104 Heavy Silken Thread,
64 Essence of Air, 56 Coarse Thread, 36 Ironweb Spider Silk, 30 Silken Thread, 21 Small
Brilliant Shard, 20 Red Dye, 19 Spider's Silk, 14 Blue Dye, 13 Elemental Earth, 11 Orange Dye.

Where it differs from Wowhead's tested route (4 Nov), and why:
- 160-170 **Crimson Silk Vest** instead of Robe of Power: the Robe takes 2 of each of four
  elementals per craft (80 for the step); the Vest is orange the whole step.
- 205-225 **Black Mageweave Headband** instead of Runecloth Belt from 214: see *Disagreements*.
- 235-260 **Runecloth Gloves** instead of Cloak then Boots: one pattern, no Ironweb Spider Silk.
- 280-285 **Runecloth Cuffs** (green) instead of Wisdom of the Timbermaw: no reputation, no 48
  essences.
- 290-300 **Venomspew Cord** alone instead of Cord then Footpads: the game gives both the same
  colours (295/297/300), so the Footpads only add a 7g50 pattern.

## Parts: bolts as raw cloth

`TAILORING.parts` lists the five bolt recipes with the same fields as a step's recipe (`name`,
`spell`, `icon`, `yellow`, `grey`, `mats`, `makes`, `learn`, `source`): Bolt of Linen Cloth
(2 Linen Cloth), Bolt of Woolen Cloth (3 Wool Cloth), Bolt of Silk Cloth (4 Silk Cloth), Bolt of
Mageweave (5 Mageweave Cloth), Bolt of Runecloth (5 Runecloth). Generic name: Engineering and
Leatherworking have the same kind of in-profession parts.

- **Shopping list** (`ns.profShopping`): as now (what the remaining steps need, minus products
  of earlier steps via `makes`), then each remaining need for a part is replaced by its
  materials; the row keeps `via = { part, n }` ("for 153 bolts"). Parts never appear as rows.
- **Have**: a cloth row counts that cloth in your bags plus bolts you hold times the bolt's
  cloth (a held Bolt of Mageweave counts as 5 Mageweave Cloth). `ns.profHave(key, item)` does
  this for the tab and the card.
- **Step card in the tab**: a bolt material shows the bolts you have and "make them from Silk
  Cloth (4 each): your 46 make 11".
- **Crafting window** (`ProfessionGuide.lua`): when the step's recipe needs a part you have too
  few of for one craft, and you have the cloth for at least one part, the Codex outlines the
  part's recipe instead, and the card says "Make Bolts of Silk Cloth first: your 46 Silk Cloth
  make 11." With enough parts for a craft it outlines the step's recipe again. Show it and the
  controller's auto-select on opening follow the same pick. With neither parts nor cloth, the
  card shows the step as now (materials say what's missing). Not learned / filtered work as now.

## Cloth section

`TAILORING.cloth` (rendered where Mining shows veins; zones through `ns.profZones`):

| Cloth | Mob levels | Alliance | Horde | Both |
|---|---|---|---|---|
| Linen Cloth | 6-15 | Westfall, Loch Modan, Teldrassil, Darkshore, Elwynn Forest, Dun Morogh | The Barrens, Durotar, Silverpine Forest, Tirisfal Glades, Mulgore | |
| Wool Cloth | 17-25 | Redridge Mountains, Darkshore, Wetlands, Duskwood, Westfall | Stonetalon Mountains, The Barrens, Silverpine Forest | Ashenvale, Hillsbrad Foothills |
| Silk Cloth | 27-39 | Duskwood | | Desolace, Arathi Highlands, Stranglethorn Vale, Thousand Needles, Ashenvale, Badlands, Alterac Mountains, Swamp of Sorrows, Dustwallow Marsh |
| Mageweave Cloth | 42-49 | | | Feralas, Tanaris, Stranglethorn Vale, Azshara, Searing Gorge, Blasted Lands, The Hinterlands, Badlands |
| Runecloth | 52-59 | | | Eastern Plaguelands, Western Plaguelands, Blasted Lands, Burning Steppes, Deadwind Pass, Silithus, Winterspring, Azshara, Felwood |

- Each row: icon, "Humanoids level 17-25", your zones. The cloth the current step uses (through
  its bolts) comes first, marked "you need this now".
- One supplies line: "Thread, dyes and Bleach: Tailoring and trade supply vendors (most trainers
  have one nearby)."
- Felcloth and Mooncloth are not in the route and not listed.

## Code

- `ProfessionData.lua`: `TAILORING = { name = "Tailoring", skillLine = 197, icon = "trade_tailoring",
  tiers, steps, parts, cloth, notes }`. Tier `where` over 60 characters gets a `short`.
- `Professions.lua`: `"TAILORING"` in `ns.PROF_ORDER` (after Mining); `profShopping` expands parts;
  `ns.profPart(key, item)` (the part that makes an item, or nil); `ns.profHave(key, item)`.
- `ProfessionTab.lua`: three switch buttons; the subtitle built from the profession names
  ("Blacksmithing, Mining and Tailoring 1-300 for WoW: Forever"); the cloth section when `P.cloth`;
  part lines on the step card; cloth rows' "have" through `ns.profHave`.
- `ProfessionGuide.lua`: the part-first pick (one function used by the trace, the card, Show it and
  auto-select) and its card line. Tailoring is recognised by name already.
- `Window.lua`: the Settings text naming the crafting windows adds Tailoring.
- `tools/gamedata.py`: `PROFESSIONS` gains `"Tailoring": 197`; the reference is regenerated (its git
  diff is only the new profession). `audit_professions` also checks each part (spell on the skill
  line, colours, reagents, makes) and that every cloth name is an item the reference knows.

## Testing

Harness (every class, full and minimal client):
- `prof_shape_checks`: Tailoring's fields, ASCII text, every bolt a step uses is in `parts`, every
  part's cloth is in `cloth`, zones are strings.
- Game checks (existing, now on Tailoring): recipe on the skill line, colours, reagents, spell,
  no gaps 1-300, no step grey before it ends, tiers trainable in time; warnings for green steps,
  icons, plan skill vs `learn`, clashes, "known" vs `auto`.
- Scenarios:
  1. Tailoring tab at skill 0, 50, 150 and 260: the step, the shopping list in cloth (no bolt
     rows), the cloth section with this step's cloth first.
  2. Held bolts lower the cloth still needed (bags: 10 Bolt of Mageweave = 50 Mageweave Cloth).
  3. Crafting window (`makeCraftWindow`, Tailoring): with cloth but no bolts it outlines the bolt
     recipe and says so; with bolts it outlines the step's recipe; Show it and controller
     auto-select pick the same recipe.
  4. Cloth zones: Alliance, Horde, Skyborne.
  5. The profession switch shows three buttons and keeps the picked one.
  6. A Tailoring skill-up card at a new step; the level-up banner's training row.
  7. The classic skill list (`skilllines`) and a closed heading, for Tailoring.
  8. Blacksmithing and Mining scenarios unchanged.

In game:
- At a Tailoring trainer, `/codex debug`: the requirements for Bolt of Runecloth, Runecloth Belt and
  Linen Bag.
- Pexmit in Mount Hyjal (Runecloth Cuffs), Qia's stock.
- Forever's own Tailoring window: the outline, the bolts-first card, Show it.

## Docs

CLAUDE.md (data shape: `parts`, `cloth`; modules 2b, 5b, 7a; tests), a CHANGELOG section,
`tools/audits/2026-11-07-tailoring.md` (every Tailoring fact with its source), README,
CURSEFORGE_DESCRIPTION.md and the Settings text that name Mining and Blacksmithing.

## Risks

- Learn levels and pattern vendors are server-side and the sources disagree in places: every step
  has an alternative, and the trainer check records the real requirement.
- Cloth zones come from Wowhead's drop counts, not the client; they are guide text.
- Pexmit and Mount Hyjal are new in Forever and only Wowhead places him; the Cuffs step names
  Runecloth Boots to 265 and Wisdom of the Timbermaw as alternatives.

## Out of scope

- Specialisations and Mooncloth/Felcloth crafting; Forever's new BoP leveling sets (the Novice
  sashes, Stormsewn, Filigreed...).
- First Aid (also uses cloth).
- A Tailoring page on The Leveling Codex site.
