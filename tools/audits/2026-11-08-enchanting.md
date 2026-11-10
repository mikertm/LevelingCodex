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
- The disenchant level bands use item level. Uncommon gear starts at 5–15 and the last client row covers 61–99. Epic rows include separate 51–55, 56–60 and 61–99 brackets.
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
  - Shield - Greater Stamina: Mythrin'dir (Darnassus) / Daniel Bartlett (Undercity), limited stock. Client item 16217 has `Bonding=1` (bind on pickup).
- WoW-Professions lists Bracer - Greater Strength at Annora (skill 240) and the Lesser Mana Oil formula at Kania in Silithus. Wowhead lists the oil formula in Silithus and Blackrock Depths. Check Annora's recipe list and Kania's stock in game. [Leveling guide](https://www.wow-professions.com/forever/enchanting-leveling-guide) · [Oil formula](https://www.wowhead.com/forever/item=20754/formula-lesser-mana-oil)
- The Enchanting overview lists Enchanted Lute at 20, Arcane Salvager at 140, and Arcane Forge at 300. The client confirms the spells and the two blueprints' requirements. [Enchanting overview](https://www.wowhead.com/forever/guide/professions/enchanting/overview)
- **Wowhead leveling guide (3 Nov):** the route's shape; Mote of Magic and the Copper Rod from enchanting supply vendors.
- **WoW-Professions' Forever disenchanting guide:**
  - a player-facing approximation of the brackets by required level;
  - armour mostly dust, weapons mostly essence, blue items a shard;
  - no skill needed to disenchant.
  - its band edges sit five below the client item-level edges for ordinary gear.

## Differences from Wowhead's route (3 Nov), and why

| Skill | Wowhead | Guide | Why |
|---|---|---|---|
| 1-20 | Disenchant to 20 | Runed Copper Rod, Dust to Motes, Bracer - Inferior Stamina | Works without green items (disenchanting is the alternative) |
| 20-90 | Lesser Magic Wand, Chest - Minor Absorption | Chest - Inferior Stamina | 1 Strange Dust instead of an essence (and wood) |
| 160-180 | Bracer - Lesser Strength (formula) | Boots - Lesser Agility (trainer) | Same Soul Dust, no formula |
| 225-250 | Gloves - Agility, Boots - Stamina, Chest - Superior Stamina | Gloves - Agility | 1 Vision Dust instead of 2-3 |
| 250-265 | Lesser Mana Oil | Bracer - Greater Strength (Annora) | Trainer recipe. Lesser Mana Oil from Kania is an alternative. |
| 265-300 | Shield - Greater Stamina to 294, Runed Arcanite Rod, Cloak - Superior Defense | Shield - Greater Stamina to 300 | Yellow from 285 through 304. Both enchants require Truesilver. |

## Cross-check on 9 Nov 2026

Zygor Forever 1.6.37551 agrees on Annora in Uldaman, the cloak and shield formula vendors, and the early rod progression. Its Classic opening uses spell 7418, **Minor Health**, through 90. Forever calls the same spell **Inferior Stamina**, uses Mote of Magic, and turns it gray at 25. Zygor also budgets an Arcanite rod for Cloak - Superior Defense. The Forever `SpellTotems` record calls for category 376, Runed Truesilver Rod. [Alliance Zygor route](<C:/Dev/Starbreak/reference/Release Forever 1.6.37551/ZygorGuidesViewerForever/Guides-Forever/Professions/ZygorProfessionsAllianceCLASSIC.lua:4299>) · [Horde Zygor route](<C:/Dev/Starbreak/reference/Release Forever 1.6.37551/ZygorGuidesViewerForever/Guides-Forever/Professions/ZygorProfessionsHordeCLASSIC.lua:3957>) · [Forever's 7418 recipe and in-game record](https://wowforever.ninja/professions/enchanting/7418-enchant-bracer-minor-health/) · [Forever SpellTotems](https://wago.tools/db2/SpellTotems?build=1.60.1.70862)

The main route stays at Shield - Greater Stamina through 300. If Dalria or Kulwia is out of stock, Minor Stamina reaches 120 and Chest - Stamina reaches 135. If Mythrin'dir or Daniel Bartlett is out of stock, Annora's Greater Strength reaches 285, then Lorelae Wintersong's Superior Defense reaches 300. The last five points of the Greater Strength fallback are green. The shopping list follows the main route. [Forever leveling guide](https://www.wow-professions.com/forever/enchanting-leveling-guide) · [Forever shield formula record](https://www.wowhead.com/forever/item=16217/formula-enchant-shield-greater-stamina) · [Forever cloak formula record](https://www.wowhead.com/forever/item=16224/formula-enchant-cloak-superior-defense)

Bag estimates now read item level from `GetItemInfo`, which also works for quest gear with a low or missing equip requirement. Epics at item level 56 or above show Nexus Crystal. The client supplies bracket bounds and the zero minimum Enchanting skill. The exact loot distribution lives on the server. Item levels 5–15 have client rare rows, but the lowest rare shard result is unconfirmed, so the bag list leaves those estimates out. [Forever ItemDisenchantLoot](https://wago.tools/db2/ItemDisenchantLoot?build=1.60.1.70862) · [Forever loot and epic results](https://www.wow-professions.com/forever/disenchanting-guide) · [Item-level comparison](https://bytetavern.com/wow-forever-enchanting-leveling-guide/)

## To check in game

- Copper Rod and Mote of Magic at an enchanting supply vendor; the formula vendors' stock.
- Compare the bag list with a quest reward that has an item level above its equip level, and with a high-level epic.
- Annora as the only Artisan trainer; `/codex debug` at a trainer for the learn levels.
- A better rod counting for a lower one (Truesilver Rod for a Silver Rod enchant).
