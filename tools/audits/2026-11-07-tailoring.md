# Tailoring guide: sources (7 Nov 2026)

New guide: `LevelingCodexProfessions.TAILORING` in ProfessionData.lua. Game data build
1.60.1.70862. Design: `docs/superpowers/specs/2026-11-07-tailoring-guide-design.md`.

## From the game client (exact, checked by the harness)

Every step's and part's `spell`, `yellow`, `grey`, `mats`, `icon` and the bolts' `makes` are copied
from `tools/reference/forever.json` (`python tools/gamedata.py recipes Tailoring NAME`). Also from
the client:
- Learned with Tailoring (`AcquireMethod` 1): Bolt of Linen Cloth, Brown Linen Shirt, Linen Bag,
  Linen Cloak, Simple Linen Pants.
- No Tailoring recipe carries a client learn level (`MinSkillLineRank`).
- Pattern skills (`RequiredSkillRank`): Runecloth Gloves 230, Runecloth Cuffs 250, Venomspew Gloves
  285, Venomspew Cord 290 (the route's `learn`).
- Cloth icons: the bolt recipes' reagents (Linen Cloth `inv_fabric_linen_01` ... Runecloth
  `inv_fabric_purplefire_01`).
- Zone names: AreaTable (Mount Hyjal 616, Zephras Isle 16593 included).

## From Wowhead Forever (server-side, guide text)

- Learn levels (`learnedat`) of the trainer recipes, and which recipes trainers teach (up to
  Runecloth Belt at 225): skill page 197, recipe listview, read 7 Nov.
- Who teaches each tier: the taught-by lists of Apprentice (3908), Journeyman (3909), Expert (3910)
  and Artisan Tailoring (12180), read 7 Nov. Tiers in the data:
  - Journeyman: Expert, Master and Artisan Tailors, Lawrence Schneider, the Zephras Isle tailors.
  - Expert: Georgio Bolero, Lawrence Schneider, Charles Worth, Timothy Worthington; Josef Gregorian, Daryl Stack.
  - Artisan: Timothy Worthington, Daryl Stack.
- Pattern vendors (item "sold by" lists, read 7 Nov):
  - Qia: Runecloth Gloves, 1g68, limited.
  - Darnall: Runecloth Cloak 1g20 and Boots 2g, limited.
  - Pexmit: Runecloth Cuffs, 10g. Mount Hyjal per the Tailoring overview guide (4 Nov).
  - Mishta: Venomspew and Swarmtender's, 7g50 each.
- Cloth levels and zones: each cloth's "dropped by" list (the 200 best droppers; counted where
  15% or more of 20+ kills dropped it): levels = 10th-90th percentile of those NPCs' levels, zones =
  the most such NPCs, split by faction.
- The route's shape: Wowhead's Tailoring leveling guide (4 Nov).

## Differences from Wowhead's route (4 Nov), and why

| Skill | Wowhead | Guide | Why |
|---|---|---|---|
| 160-170 | Robe of Power | Crimson Silk Vest | The Robe takes 2 of each of four elementals per craft (80 for the step); the Vest is orange the whole step. |
| 205-225 | Bolt of Runecloth from 205, Runecloth Belt from 214 | Black Mageweave Headband, Bolt of Runecloth at 210-212 | Wowhead's recipe data says 210 and 225; the alternative says to use the Belt earlier if the trainer offers it. |
| 235-260 | Runecloth Cloak, then Boots (Darnall) | Runecloth Gloves (Qia) | One pattern, no Ironweb Spider Silk. Cloak and Boots are the alternative. |
| 280-300 | Wisdom of the Timbermaw, then Venomspew | Runecloth Shoulders | The tradable Shoulders pattern has no reputation gate. Venomspew remains an alternate finish. |

## Cross-check on 9 Nov 2026

Both faction routes of a reference guide corroborate Georgio Bolero and Josef Gregorian for Expert, Timothy Worthington and Daryl Stack for Artisan, and Qia for Runecloth Gloves. Its crafting stops use the Classic ranges. In the current Forever client, Bolt of Woolen Cloth, Bolt of Silk Cloth and Bolt of Runecloth turn gray at 85, 120 and 215. That guide takes them to 100, 145 and 260. Its Runecloth Belt, Bag and Gloves targets also exceed Forever's gray cutoffs of 255, 260 and 275. [Forever SkillLineAbility](https://wago.tools/db2/SkillLineAbility?build=1.60.1.70862)

The updated main route keeps Runecloth Cuffs from 260 to 280. The client marks both Qia's Gloves pattern and Pexmit's Cuffs pattern bind on pickup. Runecloth Headband, learned at 250 from a tradable pattern, can cover that band with the same color thresholds as Cuffs. Method and WoW-Professions also list Runecloth Shoulders as a 300-capable option. The pattern is tradable, requires Tailoring 260, and has no reputation requirement in the client. Its recipe is yellow at 275, green at 290 and gray at 305. Budget about 46 crafts for 280–300 before Legacy bonuses, with 7 bolts, 2 Ironweb Spider Silk, 4 Rugged Leather and 1 Rune Thread each. [Method's Forever route](https://www.method.gg/wow-forever/tailoring-in-wow-forever-1-300-leveling-guide-and-trainers) · [WoW-Professions' Forever route](https://www.wow-professions.com/forever/tailoring-leveling-guide) · [Forever Shoulders pattern](https://www.wowhead.com/forever/item=14504/pattern-runecloth-shoulders) · [Forever pattern sources](https://www.zockify.com/forever/professions/tailoring/leveling/)

For the Venomspew alternative, continue Cuffs or Headbands to 285. The client lists Cenarion Circle **Friendly** for the Gloves pattern and **Honored** for the Cord pattern. They cover 285–290 and 290–300 respectively, with 5 and about 17 crafts under the same estimate. The shopping list follows the main route. [Forever ItemSparse](https://wago.tools/db2/ItemSparse?build=1.60.1.70862) · [Venomspew Gloves pattern](https://www.wowhead.com/forever/item=275580/pattern-venomspew-gloves) · [Venomspew Cord pattern](https://www.wowhead.com/forever/item=275581/pattern-venomspew-cord)

Forever sources disagree on Runecloth Belt's trainer unlock. Icy Veins lists it at 210, while the route starts it at 225, where both published routes can use it. Check for it when learning Bolt of Runecloth at the Master Tailor. [Icy Veins' Forever route](https://www.icy-veins.com/wow-forever/tailoring-leveling-guide) · [Method's Forever route](https://www.method.gg/wow-forever/tailoring-in-wow-forever-1-300-leveling-guide-and-trainers)

## Audit warnings that stand

- Earthen Vest (8764, 439100) and Black Mageweave Vest (12048, 439086) exist twice in the client.
  The route uses the Classic spell, which Wowhead's trainer data lists (`learnedat` 135 and 170); the
  439xxx copies are Forever additions with no trainer source on Wowhead.

## To check in game

- At a Tailoring trainer, `/codex debug`: the real requirements for Bolt of Runecloth (210),
  Runecloth Belt (225) and whether Linen Bag is offered (the client says it's known).
- Pexmit in Mount Hyjal (Runecloth Cuffs); Qia's and Darnall's stock.
- In Forever's Tailoring window, check the outline and bolts-first hint.
