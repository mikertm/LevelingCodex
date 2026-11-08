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
| 280-285 | Wisdom of the Timbermaw | Runecloth Cuffs (green) | No Timbermaw reputation, no 48 essences. |
| 290-300 | Venomspew Cord, then Footpads | Venomspew Cord | The game gives both the same colours (295/297/300); Footpads only add a 7g50 pattern. |

## Audit warnings that stand

- Earthen Vest (8764, 439100) and Black Mageweave Vest (12048, 439086) exist twice in the client.
  The route uses the Classic spell, which Wowhead's trainer data lists (`learnedat` 135 and 170); the
  439xxx copies are Forever additions with no trainer source on Wowhead.

## To check in game

- At a Tailoring trainer, `/codex debug`: the real requirements for Bolt of Runecloth (210),
  Runecloth Belt (225) and whether Linen Bag is offered (the client says it's known).
- Pexmit in Mount Hyjal (Runecloth Cuffs); Qia's and Darnall's stock.
- Forever's own Tailoring window: the outline, the bolts-first card, Show it.
