# Duskwood: Lean Wolf Flanks on the earlier loops (2026-11-13)

Owner report (in game, Duskwood at level 25): on Eight-Legged Menaces, Rabid Dire Wolves around the
spider woods drop Lean Wolf Flanks for Seasoned Wolf Kabobs (90), which the route only lists at
Sven's Camp later.

QuestieDB Forever (`tools/questfacts.py item 1015`, Lean Wolf Flank) drop sources on Duskwood (1431):

| Creature | Levels | Spawns | Main clusters |
|---|---|---|---|
| Starving Dire Wolf | 19-20 | 38 | 33.7, 24.0; 25.4, 27.1; 15.3, 25.6 |
| Rabid Dire Wolf | 20-21 | 33 | 16.3, 27.3; 35.8, 26.6; 20.9, 27.0 |
| Young Black Ravager | 23-24 | 40 | 55.3, 63.7; 24.3, 75.7; 26.1, 65.7 |
| Black Ravager | 24-25 | 10 | 68.6, 33.5; 64.7, 27.4; 59.5, 58.3 |
| Lupos | 23 | 16 | 34.6, 26.8; 25.3, 27.8 |

Pygmy Venom Web Spider (539) clusters: 66.3, 17.4; 11.2, 55.6; 8.7, 44.9.

Changes (QuestData.lua, the Duskwood chapter; Kabobs is accepted in Darkshire before both):

- Ira's Dagger hunt (96137, step at 55.3, 63.7 = the Young Black Ravagers' main cluster): now
  `along(..., 90)`, and the text adds "Ravagers drop Lean Wolf Flanks for Chef Grual too."
- Eight-Legged Menaces (245, the western spider woods): `along(..., 101, 90)`. The wolves' clusters
  sit north of the spiders (y 27 against 45-56), so this is a "kill any you meet" hint, as the owner
  saw in game; the wolf step at Sven's Camp still finishes the flanks.
