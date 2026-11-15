# 2026-11-15: Screenshot follow-up: travel, completion history and dungeon preparation

The owner supplied five in-game screenshots after the interaction audit. This
follow-up keeps their quest instructions first, makes travel handoffs explicit,
and lets a character prepare a future dungeon without starting its run.

## Hearthstone and other clickable items

Before: `Q.hearthCooldown` called `C_Container.GetItemCooldown(6948)`, passing an
item ID to a bag/slot API. The item button had no cooldown indication at all.
After: use `C_Item.GetItemCooldown(item)` with the classic item-ID API as fallback.
The clickable item has a live minutes/seconds countdown and desaturates while
cooling down when the client supports it. Optional APIs remain guarded.

`questHearthModernCooldown` failed before the fix and passes after it. It models
the modern item API with the deprecated global absent and an unrelated container
API returning zero, then watches the displayed timer change from 60m to 59m.
API reference: [Blizzard generated Item documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).

## Travel wording and automatic flights

- Darkshire now names the inn, Felicia Maline, her location on the south side of
  town, and the next flight to Stormwind. The waypoint continues to lead to Felicia.
- All Fly steps explicitly say to talk to the flight master and choose the named
  destination. Every immediately adjacent Hearth -> Fly handoff names that next
  flight. Inventory: Alliance 120 Fly rows / 5 such handoffs; Horde 258 / 1.
  These totals include alternate and side-guide copies, not distinct trips.
- The flight automation initializes the destination's map route by calling the
  guarded `TaxiNodeOnButtonEnter(TaxiButtonN)` before `TakeTaxiNode(N)`, matching
  the supplied RXP `functions.lua:2881-2885`. Previously it skipped initialization,
  allowing the client to reject a connecting route as having no direct path.
- `questFlightRouteInitialization` failed before the fix and passes afterward.
  Existing Alt, combat and unreachable-destination checks remain in force.

## Previously completed quests

Completion history accepts both ID arrays and keyed completion sets, including
numeric truth markers. Once the client confirms a quest completed, that positive
result is kept for the session even if a later history read is temporarily empty.
Nothing is inferred merely because an NPC has no offer.

`questCompletedSet` failed before the correction and passes after it with an
empty SavedVariables database. The live character's missing completion flags
cannot be established from screenshot 3 alone; check Spoils of War (98197) and
Report to Captain Stoutfist (473) on that character after installation. Current
Forever sources confirm 98197 is the timber/iron quest from Valstag, not a Classic
quest with the same title:
[Forever quest record](https://db.icy-veins.com/wow-forever/quests/98197).

## Interior objective directions

The Cursed Crew (289), `QuestData.lua`, was wrong: "wreck to the north" aimed at
the wrong part of the Lost Fleet. It now identifies the southern sunken wreck,
closest to Menethil, entry through the broken hull, the flooded lowest deck, the
Snellig position (13.8, 30.2), and surfacing between pulls. The waypoint names
Snellig and points at his position rather than the general sailor area.

Evidence: `python tools/questfacts.py npc 1159`; supplied Zygor Alliance leveling
289/3 (14.08, 30.01, underwater inside ship);
[Forever walkthrough](https://urgametips.com/wow-forever/quest-guides/the-cursed-crew-snellig-snuffbox/);
[historical atlas, Wetlands NPC index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_hr.pdf).

The focused surroundings check included both wrecks, Halyndor's rudder access,
Thelgen Rock's entrance, the Durnholde prisoners and keys, and Badlands cave/camp
objectives. Existing explicit access instructions were retained. The preceding
faction audits also corrected interior or multi-stage directions for Fillion,
Vaelan, Awbee, the Maraudon khans, Northridge's crate, and others. The final Horde
Awbee mirror now follows the Rend/Gyth objective and names the ledge beyond the
stadium. This is a targeted access/directions pass, not a live traversal of every
cave, tower and ship in either route.

## Dungeon preparation and the ready control

- Three quests in the log no longer declare a run ready. All outstanding outdoor
  pickups and prerequisite chains count, including quests not yet available at
  the character's level. Inside/after-run quests and loot-started inside quests
  do not block readiness. A ready reminder also requires the suggested run level.
- Dungeon guide pages have **Prepare quests**; the Route tab offers nearby or
  planned dungeon preparation as an alternative. Preparation plans the pickups,
  follows the outdoor steps, and automatically returns to leveling before the
  dungeon-entry step. Inside/after steps stay available when the player chooses
  the actual run later. Nothing forces an early run or changes the suggested level.
- The full-width Run button is replaced by a 28x24 skull icon in the footer beside
  Next. Its tooltip names the dungeon and quest count. The short Find a group
  reminder follows the current quest instructions rather than displacing them.
- `questDungeonPreparation` and `questDungeonIncompletePreparation` reproduce the
  missing preparation action and premature three-quest readiness, respectively;
  both failed before and pass after. Existing plan/choice scenarios check the new
  icon and the distinction between incomplete and complete preparation.

The Excavation Site keeps its 26-31 suggested range. Sources distinguish its
level-24 pickups from the run itself and its level-31 final boss:
[dungeon overview](https://www.wowhead.com/forever/guide/excavation-site-wetlands-dungeon-overview-location-rewards).

## Validation and in-game checks

Focused regressions and the 12,648-step route audit pass. Final full harness and
installation results are recorded in `2026-11-15-quest-interactions.md`.

After /reload: use a Hearthstone and watch the clickable item count down; auto-fly
Stormwind -> Menethil; verify the two previously completed Valstag/Stoutfist
pickups stay passed; follow Snellig into the correct wreck; prepare Excavation
Site from Route or its guide page, return to leveling, and check the small run
icon only appears once outdoor preparation and the suggested level are met.
