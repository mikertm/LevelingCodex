# Profession sources pass (2026-11-27)

Reported in game: at First Aid 150/150 the crafting window card said only "Silk Bandage - Recipe not
learned - First Aid trainer (skill 150)", with no word about Expert First Aid - Under Wraps, which you
need before anything gives a point past 150.

## Method

Every recipe step, part, rod and training tier in `ProfessionData.lua` was compared with the 1-300
profession guides of a Forever-specific guide addon (both factions; Michael's reference copy). Only facts
were used: which NPC teaches or sells what, and the NPC's map spot. No text was copied.

- Each step's source agreed with the reference on how it is learned (trainer, vendor recipe, quest).
  The reference names Forever's Elixir of Greater Defense (17554) by its old name; the game reference
  (`forever.json`) is right, the guide keeps it.
- One gap: Recipe: Roast Raptor for the Horde. The guide named only Keena (Hammerfall); the reference
  buys it from Nerrist (Grom'gol, Stranglethorn Vale, 32.7, 29.2). Both are listed now.

## Data changes (mirror into the guide pages)

- New `ProfessionPlaces.lua`: `ns.PROF_PLACES[name] = { faction, uiMap, x, y, zone }` for 104 trainers,
  book and recipe vendors and quest givers the guide names, and `ns.PROF_TRAINERS[PROFESSION]` (capital
  trainers for "any trainer" steps). Spots are the reference's waypoints, rounded to 0.1.
- `ProfessionData.lua`: `at = { names }` on 68 tiers and steps (the NPCs their `where` / `source` text
  already named, where a spot is known); `item` on 19 bought or quest recipes (the plan item from the
  game reference) and on the three book ranks: Expert First Aid - Under Wraps, Expert Cookbook,
  Expert Fishing - The Bass and You.
- Cooking 175-205 Roast Raptor: source now "Hammon Karwn (Refuge Pointe, Arathi Highlands) for the
  Alliance, or Keena (Hammerfall, Arathi Highlands) or Nerrist (Grom'gol, Stranglethorn Vale) for the Horde".

NPCs without a known spot keep their text only (Zephras Isle and Dalaran trainers, Annora inside
Uldaman, Jase Farlane, Pexmit, Magnus Frostwake, Kor'gar, Keena): no arrow for those yet.

## Still to check in game

- The book and recipe prices (the vendor card shows them on the spot).
- Whether Forever's Journeyman trainers (Nissa Firestone, Arnok) teach Silk Bandage at 150 before
  the Expert book, as the reference does.
