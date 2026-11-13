# Vendor steps: item IDs and counts (2026-11-12)

The vendor helper (`Vendor.lua`) has two jobs. Its shopping card buys what a coming step needs, and its junk seller keeps those items. A buy step only counts toward either once it says which items it wants. This pass gives the route's vendor buy steps their item IDs and counts.

Sources:
- QuestieDB Forever item records (`tools/.cache/questiedb-*/foreverItemDB.lua`): names and `vendors`.
- Each quest's objective text and item objectives (`tools/questfacts.py quest <id>`).

Auction House steps stay text only, because no vendor sells their items:
- `QuestData3040.lua` Elixir of Water Breathing
- `QuestData4050.lua` Troll Tribal Necklaces / Power Crystals
- `QuestData5060.lua` Stormwind auction step
- `QuestSpecialData.lua` Thorium Bars

## Changed steps

| File | Step | Before | After | Source |
|---|---|---|---|---|
| `QuestData3040.lua` (Southshore, Micha Yance) | Buy Fine Thread and Soothing Spices | text only | `items = { { 2321, 1 }, { 3713, 1 } }` | Quest 565 (Bartolo's Yeti Fur Cloak) item objectives include Fine Thread 2321 ("Fine Thread", one). Quest 555 (Soothing Turtle Bisque) includes Soothing Spices 3713. Its text says "some Soothing Spices" with no number, so the count is 1; once the quest is in your log, the card uses the log's own count. |
| `QuestData3040.lua` (Theramore, Helenia Olden, 30-40 route) | Buy 3 Soothing Spices | text only | `{ item = 3713, count = 3 }` | Quest 1218 text: "Bring 3 Soothing Spices to Swamp Eye Jarl". |
| `QuestData3040.lua` (Theramore, Helenia Olden, Dustwallow chapter) | Buy 3 Soothing Spices | text only | `{ item = 3713, count = 3 }` | Same quest 1218. |
| `QuestHorde5060.lua` (Booty Bay, Nixxrax Fillamug) | Buy 10 Barbecued Buzzard Wings and 5 Junglevine Wine | `{ item = 4457, count = 10 }` | `items = { { 4457, 10 }, { 4595, 5 } }` | Quest 8554 (Facing Negolash) text: "Bring 10 Barbecued Buzzard Wings and 5 bottles of Junglevine Wine". QuestieDB lists Junglevine Wine 4595 as sold by NPC 2832 (Nixxrax Fillamug). It lists no vendor for the wings, so that step's "check in game" note stays. |

Unchanged:
- The Horde Soothing Spices steps (`QuestHorde3040.lua`, Xen'to in Orgrimmar and Tarban Hearthgrain at the Crossroads) already had `{ item = 3713, count = 3 }`.

## For the guide pages

Each step's text is unchanged, and the item data only feeds the add-on. No guide-page edits are needed unless the pages list item IDs.
