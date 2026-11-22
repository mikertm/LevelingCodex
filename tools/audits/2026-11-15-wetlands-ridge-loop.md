# Wetlands eastern loop

The owner's screenshots show Razormaw Needling while already carrying Crocs of
the Sky and Carnage. The old route completed raptor teeth/eggs before its coast
quests, picked up Crocs later, farmed whelps on another eastern trip, and omitted
Carnage. Merely adding related objectives to the old raptor step would still
leave new players without Halloran's quest on that trip.

## References

- Local reference guide A `local guide reference`, lines 26427-26541:
  turn in Blisters, take Carnage, work whelps and Rotclaws together, gather raptor
  teeth/eggs, summon with item 280331 at the Offering Stone, return west.
- Local reference guide B `local guide reference`,
  lines 7720-7792: Halloran's Crocs pickup follows Apprentice's Duties; whelp
  scales are below Raptor Ridge. Its older ordering separates the raptor trip.
- [Wowhead Carnage](https://www.wowhead.com/forever/quest=98283/carnage):
  follows Blisters; Maddened Rotclaw flesh summons the elite; player reports put
  the cave mouth at 69.5, 34.7.
- [Carnage walkthrough](https://urgametips.com/wow-forever/quest-guides/carnage-malignant-rotclaw-flesh-cave/):
  confirms the bait, cave, group and return to Rethiel.
- [Wowhead Crocs of the Sky](https://www.wowhead.com/forever/quest=98072/crocs-of-the-sky):
  eight Pristine Crimson Scales from eastern whelps; the description warns about
  the nearby orcs. Completing it is not required to pick up Razormaw Needling.
- Cached quest database, `python tools/questfacts.py quest 98283` and `npc 271336`:
  Rethiel starts/finishes it at 56.37, 40.4; flesh/head item objectives; Carnage is
  level 30 inside the ridge around 69.5, 29.0. The cached item table has no flesh
  entry; its usable ID 280331 and Offering Stone instruction come from reference guide A.

## Route data changes

- 98245/98246: move both pickups to Howin after Angerfang on the post-coast
  eastern sweep; move their objectives and turn-ins after the whelp/bear area.
  This avoids holding both quests throughout the first Menethil coast visits.
- 98072: keep Halloran's post-crocolisk pickup; move its completion before the
  ridge, and explicitly name the combined trip. Add related progress for all
  four quests to the whelp, bear, tooth and egg steps.
- 98283: add level 30/minimum 22, prerequisite 275, elite Carnage; offer Take/Skip
  after Rethiel takes Blisters. Split flesh/head objectives, target Rotclaws for
  bait and Carnage for the summon, use item 280331, lead through cave mouth
  69.5, 34.7 to 69.5, 29.0, return to Rethiel before Howin.
- 98291: keep its pickup after Howin's raptor turn-ins, now on this eastern trip;
  remove whelp progress from its separate Dragonmaw Retreat steps.
- 270: skip its Stormwind travel pickup once already in Wetlands. With Howin's
  old early pickup removed, this needed an explicit arrival condition to avoid
  sending catch-up characters back to the Cathedral.
- 469: include the Dun Algaz entry directions formerly on Howin's early pickup.
- Regenerate NPC metadata: add Rethiel for 98283. The generator also removes an
  obsolete Squire Rowe recipient override for 6402, corrected in the preceding
  interaction audit; Reginald Windsor remains its actual recipient.
- No `Data.lua` changes.

## Checks

The headless scenarios reproduce the original missing shared progress, exercise
Carnage's Take/Skip choice after Blisters, and verify the cave instructions,
usable flesh button and Carnage target. Existing Wetlands/catch-up scenarios
cover entry and return from the early chapter. The route audit checks the
20-quest cap with dungeon and elite variants.

The loop tool still reports the existing late Bloom pickup and Fall of Dun Modr
hub visit. Its new Death to the Dragonmaw suggestion overlooks the raptor
turn-ins: reference guide A gates that pickup on both of them. The combined trip is about
grouping nearby tasks; no measured in-game time saving is claimed.

In game: verify Halloran's pickup before heading east, all four progress groups,
Carnage's group choice, the cave entrance/Offering Stone, and returning to Howin
before Dragonmaw Retreat. Skip Carnage when solo; the other objectives remain.
