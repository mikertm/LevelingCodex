# 50-60 attunements and keys (2026-11-10)

Five `special` guides at the end of `QuestSpecialData.lua`. Each is checked on its own path, so the parts that sit on the leveling route are copied from it (`fromRoute`) and the guide carries the whole chain.

| Guide | Quests | Starts from | Notes |
|---|---|---|---|
| `onyxia-attunement` (Drakefire Amulet) | 4182-4186, 4223, 4224 (copied from `steppes-56`), 4241, 4242, 4264 (item 11446), 4282, 4322, 6402, 6403, 6501, 6502 | Helendis Riverhorn, Morgan's Vigil | Needs Blackrock Depths runs (Windsor, the note, Angerforge and Argelmach, the jail break), the Stormwind masquerade escort and General Drakkisath in Upper Blackrock Spire. Haleh is at the top of Mazthoril, Winterspring. |
| `ubrs-seal` (Seal of Ascension) | 4742, 4743 | Vaelan, inside Lower Blackrock Spire | Three gemstones (Omokk, Voone, Wyrmthalak) plus an Unadorned Seal from the Scarshield orcs; then Emberstrife in the Wyrmbog. |
| `molten-core-attunement` | 7848 | Lothos Riftwaker, Blackrock Mountain | Core Fragment beside the Molten Core portal in Blackrock Depths. |
| `scholomance-key` | 5090, 5092 (copied from `wpl-51`), 5097, 5533, 5537 (from `plaguelands-57`), 5538, 5801, 5803, 5505 | Commander Ashlam Valorfist, Chillwind Camp | Krinkle Goodsteel in Gadgetzan (15 gold), Fire Plume Ridge with 2 Thorium Bars (Auction House note), Araj the Summoner in Andorhal. |
| `shadowforge-key` (Dark Iron Legacy) | 3801, 3802 | Franclorn Forgewright's ghost, Blackrock Mountain | Only visible as a spirit; Ironfel from Fineous Darkvire. |

## Sources

Quest facts from the QuestieDB Forever cache (`tools/questfacts.py`, revision 0f7d8ad) and the Forever client reference; quest IDs and the chain order also match the 50-60 route builders' notes (`tools/audits/2026-11-10-alliance-50-60.md`). NPC positions inside instances are not in the data: those steps have no waypoint and say where to look.

## Check in game

- Whether Forever changed any of these chains (in particular The Great Masquerade and the Onyxia attunement).
- Lothos Riftwaker's and Vaelan's positions; Franclorn's ghost-only rule.
- Emberstrife's level and guards; Araj the Summoner's group size.
