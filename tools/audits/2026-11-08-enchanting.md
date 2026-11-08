# Enchanting guide: sources (8 Nov 2026)

New guide: `LevelingCodexProfessions.ENCHANTING` in ProfessionData.lua. Game data build 1.60.1.70862.
Design: `docs/superpowers/specs/2026-11-08-enchanting-guide-design.md`.

## From the game client (exact, checked by the harness)

- Every step's, rod's and part's `spell`, `yellow`, `grey`, `mats`, `icon` and the Motes' `makes` are
  copied from `tools/reference/forever.json` (`python tools/gamedata.py recipes Enchanting NAME`).
- Each step's `rod` is its recipe's tool (`SpellTotems` -> `TotemCategory`).
- The rods' category and mask come from `TotemCategory`:
  - Copper 373/1, Silver 374/3, Golden 375/7, Truesilver 376/15, Arcanite 377/31.
  - A mask holds the lower rods' bits, so a better rod counts.
- Enchant Cloak - Superior Defense needs the Truesilver rod.
- Learned with Enchanting (`AcquireMethod` 1): Disenchant, Dust to Motes, Enchant Bracer - Inferior Stamina,
  Enchant Bracer - Minor Deflect, Novice's Practice Wand, Runed Copper Rod.
- Dust to Motes needs the Runed Copper Rod, and the rod needs a Mote, so the first Mote is bought (the
  route starts with the rod at 1-2).
- Disenchant has colours (y20/gr60); `ItemDisenchantLoot.SkillRequired` is 0 everywhere.
- The disenchant level bands (item level) are 5-15, 16-20, 21-25 ... 51-55 for green items.
- Zone names (AreaTable): Riverglades 16591, Zephras Isle 16593, Uldaman 1337.
- Forever's UI source has `Blizzard_Professions` and no Craft UI.

## From the guides (server-side, guide text)

- **Wowhead Forever, skill page 333 (read 8 Nov):** learn levels (`learnedat`) and which recipes trainers teach.
- **Wowhead Forever, tier spells 7411 / 7412 / 7413 / 13920 (read 8 Nov):** who teaches each tier. The data's tiers:
  - Journeyman: Expert, Master and Artisan Enchanters, Vanessa Sellers, Melanie Sable.
  - Expert: Kitta Firewind, Hgarth, Vanessa Sellers, Melanie Sable, Annora.
  - Artisan: Annora only, requiring skill 200. Wowhead's overview table says 225; the spell is used.
- **Formula vendors (Wowhead item "sold by"):**
  - Cloak - Minor Agility: Dalria (Ashenvale) / Kulwia (Stonetalon Mountains), 8s42.
  - Shield - Greater Stamina: Mythrin'dir (Darnassus, 1g26) / Daniel Bartlett (Undercity, 1g07), limited stock.
- **Wowhead leveling guide (3 Nov):** the route's shape; Mote of Magic and the Copper Rod from enchanting supply vendors.
- **wow-professions' Forever disenchanting guide:**
  - the bands by required level;
  - armour mostly dust, weapons mostly essence, blue items a shard;
  - no skill needed to disenchant.
  - Its band edges (10, 15, 20 ...) sit five below the client's (15, 20, 25 ...).

## Differences from Wowhead's route (3 Nov), and why

| Skill | Wowhead | Guide | Why |
|---|---|---|---|
| 1-20 | Disenchant to 20 | Runed Copper Rod, Dust to Motes, Bracer - Inferior Stamina | Works without green items (disenchanting is the alternative) |
| 20-90 | Lesser Magic Wand, Chest - Minor Absorption | Chest - Inferior Stamina | 1 Strange Dust instead of an essence (and wood) |
| 160-180 | Bracer - Lesser Strength (formula) | Boots - Lesser Agility (trainer) | Same Soul Dust, no formula |
| 225-250 | Gloves - Agility, Boots - Stamina, Chest - Superior Stamina | Gloves - Agility | 1 Vision Dust instead of 2-3 |
| 250-265 | Lesser Mana Oil (Lokhtos, reputation) | Bracer - Greater Strength (trainer) | No reputation |
| 265-300 | Shield - Greater Stamina to 294, Runed Arcanite Rod, Cloak - Superior Defense | Shield - Greater Stamina to 300 | Yellow until 305; Dream Dust instead of 120 Illusion Dust and an Arcanite rod (Superior Defense only needs Truesilver) |

## To check in game

- Copper Rod and Mote of Magic at an enchanting supply vendor; the formula vendors' stock.
- Disenchant in the Professions window; the bag list against your bags.
- Annora as the only Artisan trainer; `/codex debug` at a trainer for the learn levels.
- A better rod counting for a lower one (Truesilver Rod for a Silver Rod enchant).
