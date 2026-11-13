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

## Generated: vendor-only quest items (`QuestShopData.lua`)

`tools/questshop.py` takes each route quest's QuestieDB item objectives and keeps the items that a vendor sells and nothing drops, with the count from the quest's objective text. A text with no number gives 1. The card then uses the quest log's count once the quest is accepted. First run, 10 quests:

| Quest | Item | Count | Note |
|---|---|---|---|
| 90 Seasoned Wolf Kabobs | 2665 Stormwind Seasoning Herbs | 1 | |
| 375 The Chill of Death | 2320 Coarse Thread | 1 | |
| 384 Beer Basted Boar Ribs | 2894 Rhapsody Malt | 1 | |
| 555 Soothing Turtle Bisque | 3713 Soothing Spices | 1 | the text says "some" |
| 565 Bartolo's Yeti Fur Cloak | 2321 Fine Thread | 1 | |
| 654 Tanaris Field Sampling | 8523 Field Testing Kit | 1 | QuestieDB lists a vendor; worth a look in game |
| 1218 Soothing Spices | 3713 Soothing Spices | 3 | |
| 2609 The Touch of Zanzil | 3421 Simple Wildflowers, 3372 Leaded Vial | 1, 1 | |
| 5518 The Gordok Ogre Suit | 14341 Rune Thread | 2 | |
| 99050 (Forever quest) | 3371 Crystal Vial | 1 | |

## For the guide pages

Each step's text is unchanged, and the item data only feeds the add-on. No guide-page edits are needed unless the pages list item IDs.
