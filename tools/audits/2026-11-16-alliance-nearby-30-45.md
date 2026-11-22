# Alliance nearby-pickup audit: levels 30-45 (2026-11-16)

Read-only route review. No runtime or guide data changed. Reviewed QuestData3040.lua, QuestData4050.lua chapters through feralas-44 (the chapter extends to48), and alternates whose low level is30-45, including Riverglades, stv-30, theramore-33, shendralas and searing-gorge. Rechecked prior 11-14 band reports against current route and cached Forever QuestieDB revision0f7d8ad. Same-giver scan covered accept and turn-in NPCs; spatial scan covered missing NPC/object starters within100 yards of route waypoints, level29-49 with minimum eligibility fitting the chapter. Spatial proximity is a candidate filter, not proof of suitability.

## Confirmed finding

- **684 Wanted! Marez Cowl is a nearby omission with a stale exclusion.** QuestData3040.lua:1259 accepts685 at Wanted Board46.04,47.76. The same board starts684 (minimum30, quest39). Route:1285 already kills Otto/Falconcrest in Stromgarde26.0,65.7, beside Marez's camp (prior recorded29.6,63.0). Both turn in to Nials45.83,47.56 at:1301. The11-14 report excluded684 because Faldir Cove would peak21. Current audit reaches19 in arathi39. In-memory insertion of accept684 alongside accept685 and turnin684 alongside turnin685 passed current quest-log checks across every player/path combination. No files changed for that experiment. Therefore the log alone no longer justifies omission. Exact live spawn/elite status should be checked before authoring a kill step.

## Other verified nearby opportunities and constraints

- **682 Stromgarde Badges:** Nials2700 after681 Northfold Manor (hillsbrad32 turnin at QuestData3040.lua:342). Do not carry from32: accept during arathi39 return to Nials/the adjacent Wanted Board instead. Seven badges4506 drop from Syndicate Prowlers2588, Conjurors2590, Magi2591 at27.2-27.7,63.7-63.8, overlapping the685 camp. Same Nials turn-in. One extra slot fits current19 peak; adding both682 and684 needs a revised turn-in order or another slot freed. The prior report never documented682 as an exclusion.
- **212 A Meal Served Cold:** same Angus Stern1141 at51.79,93.64 as1260 (QuestData3040.lua:1370). Minimum35, objective Chilled Basilisk Haunch2476 from Cold Eye Basilisks690 (39-40), including28.1,41.6 and29.1,38.5 near stv41's Jungle Stalkers31.8,40.9 (QuestData4050.lua:312). A real nearby pickup, but accepting at40 carries through badlands41 and stv41, both currently20. Needs an explicit slot policy or an additional SW turn-in; not a safe unconditional insertion.
- **1271 Feast at the Blue Recluse:** cached quest says same Angus start/finish, no objective fields, prerequisite group1222+1258. Route does both, last1258 at QuestData4050.lua:415, then later visits Stormwind. Record as a later Stormwind same-NPC opportunity; it is not eligible when passing Angus at40. Live faction/chain behavior still needs verification (trace records do not establish eligibility exhaustively).

## Same-giver omissions which are not immediate free pickups

- **696/697 Attack on the Tower / Malin's Request:** Skuerto2789 after695, minimum30. Route completes695 only at QuestData3040.lua:1301, after the Stromgarde objective at:1283. Required chests2717/2718/2716 lie18.2,68.1 /18.0,67.9 /18.2,69.2 beside the earlier694 ogres20.2,67.2. This is an unlock-after-area-pass chain, not a currently accepted late pickup. Doing it needs a new return from Refuge to Stromgarde (or substantial order changes), followed by another Skuerto turn-in;697 goes Archmage Malin SW50.5,87.47. Opportunity is concrete but additional travel prevents calling omission a route bug automatically.
- **613 Cracking Maury's Foot:** MacKinley after609 (QuestData4050.lua:353), minimum30. Key3930 drops from Mosh'Ogg elites678/679/680/709/710/723 around48.6-52.6,27.4-31.3. This camp is near Bhag'thera49.6,24 but613 only unlocks after the route returns from that entire northern loop. Adding it means a new northward expedition; not a same-stop free completion.
- **3841 An Orphan Looking For a Home:** Kindal7956 only after2972 is turned in to Tyrande (QuestData4050.lua:566), after the chapter's last Kindal visit:547. Quentin9238 is78.35,74.72 Thousand Needles, a hub visited earlier at43. Current progression cannot take3841 when already there; it entails a return to Kindal after Darnassus and later delivery. A pet chain, not a simple missing pickup on the current pass.
- **670/667 Sunken Treasure / Death From Below:**670 only becomes available at Seahorn after669 in stv41;667 starts Shakes after returning670 to Arathi. Faldir's Cove has already been left at39. Requires an additional cross-zone return and a level44 defense; existing omission is reasonable.
- **1559 Flash Bomb Recipe:** Rigglefuzz same spot as route24, but record requires Engineering202, skill1. Profession gated; not an unconditional quest omission.
- **254 Digging Through the Dirt:** parentQuest253, same Eliza grave. Hidden parent/event helper metadata: do not add a separate pickup solely from spatial match.

## Current log and old loop exclusions

Using questroute.audit on the current in-memory Alliance route with cap0 to expose occupancy, retaining existing race/class/optional/elite/retirement rules, peak counts were hillsbrad32=18, needles33=14, desolace35=16, stv36=19, arathi39=19, dustwallow40=17, desolace40=16, badlands41=20, stv41=20, tanaris43=13, feralas44=14. These supersede the11-14 report's20 at stv36/arathi39.

- **525 Further Mysteries:** can be accepted after514 at hillsbrad32's Ironforge turn-in (QuestData3040.lua:344), rather than separate39 IF stop:1248. It uses the now-free twentieth slot through stv36. This alone fits; simultaneously moving1206 earlier consumes a second slot and needs accounting. The current39 pickup is not eligible for the usual claim that it must stay there due a20 peak.
- **1206 Jarl Needs Eyes:** prerequisite1218 is turned in duringneedles33 at:408. Delayed to dustwallow40:1377. Moving it earlier alone also fits the now19 stv36 peak; it does not make the spiders part of the earlier Flats route automatically. Choice depends whether the360-yard hub saving is worth a long-held slot.
- **707 Ironband Wants You!:** still held through badlands41 if moved from its41 pickup to32, but it is turned in before the41 peak. Long holding and tiny81-yard saving remain weak value, not a current hard-cap impossibility by itself.
- **540 Preserving Knowledge:** cached minimum20, quest38. Its39 delay is justified by35-38 Alterac enemies rather than a minimum-level gate. Earlier32 Alterac loop would require substantially harder enemies.

## Unverified candidates

- **93176 My Little Friends:** Amaryllis Webb217412 at Swamp25.1,54.21 within90yd of swamp38 route waypoint; kit catches Arbor Tarantula, Hay Weevil Specimen and Flesh Picker. Cached Forever record has no minimum, item IDs, capture spots or prerequisites. Needs published/live objectives before judging it an efficient overlap.
- Carved Centaur Totems93224, Pesterhide pelts98155/98156, Riverglades exclusions and Dun Modr chains retain missing-position/eligibility issues documented earlier. This audit does not turn lack of cached prerequisites into proof of unconditional availability. Dun Modr is reviewed by the1-30 worker, whose active-Thandol report must take priority over the inherited omission rationale.

No full harness launched in this worker. Root coordinator owns harness/install and aggregate findings. No Data.lua changes.
