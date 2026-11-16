# Alliance nearby pickups, levels 45-60 (2026-11-16)

Read-only re-audit of `QuestData4050.lua`'s upper chapters and `QuestData5060.lua`, including alternate chapters. This supplements the 2026-11-14 audits. It examines existing loop warnings and quests offered by NPCs already named in these route chapters; it is not a claim that every quest in every zone was independently checked.

Evidence: `tools/questfacts.py`'s cached Forever source plus traces, revision `0f7d8ad`; committed `tools/reference/forever.json` quest IDs; current built Alliance route loaded through `tools/questroute.py`'s `ROUTES`; `tools/questloops.py ALLIANCE HUMAN WARRIOR`. NPC-name candidate matching excluded quests already anywhere in the Alliance route, so existing dungeon/side-guide entries were not treated as missing. Candidate eligibility was checked against race, prerequisites, profession/class and repeatable fields before recommendations.

## Concrete candidates (not implemented; verify in game)

### Mission Accomplished! (5238)

The previous audit excluded Horde quest 5237 but did not examine the current Forever trace correction for 5238. The current Forever trace supports an Alliance counterpart 5238; coordinator web checks found conflicting stale classic-derived pages that still call 5238 Horde/Derrington. Treat this as a concrete candidate requiring in-game confirmation, not settled cross-source eligibility. Both are in the client reference. Forever records for 5238 specify level 58, minimum 50, Alliance race mask, sole prerequisite `5226`, giver and ender Commander Ashlam Valorfist (10838), WPL 42.70, 84.03, and no combat/item objective. Exclusivity with 5237 is harmless: 5237 belongs to the Horde, starts at High Executor Derrington in Tirisfal, and requires Horde return quest 5236.

`plaguelands-58` already turns in 5226 at High Priestess MacDonnell (42.97,84.50) immediately after flying to Chillwind, then turns 6389 in to Nathaniel Dumah (43.42,84.83). Ashlam is only about 24 yards from MacDonnell. Insert `q(5238, "Mission Accomplished!", 58, 50, 5226)` in this chapter's declarations; insert accept/finish at Ashlam immediately after `finish(5226, macdonnell)` and before `finish(6389, dumah)`. If the current Forever trace is correct, this closes the cauldron chain with no new field work or carried log slot. Verify Ashlam offers it after 5226 in game before any hardcoded route addition. No alternate copies this chapter.

### Cache of Mau'ari (975)

In client reference. Forever records: level 60, minimum 55, sole prerequisite 969; 969's `nextQuestInChain` is 975. Both start and finish at Witch Doctor Mau'ari (10307), Winterspring 61.92,38.30. No class, profession or reputation restriction is recorded. The source's objective text asks the player to speak to her again in a moment for the lucky charm; there is no additional hunt or material objective.

Insert `q(975, "Cache of Mau'ari", 60, 55, 969)` after the 969 declaration in `winterspring-55`, and `accept(975, mauari)` / `finish(975, mauari)` immediately after `finish(969, mauari)` and before `finish(977, umi)`. Wording should say to speak to Mau'ari again and wait a moment for the charm, not claim an instant automatic reward. Add 975 to `winterspring-alt`'s `from("winterspring-55", { 5087, 4861, 4863, 4864, 969 })` list, so its existing 969 completion gets the same followup. No carried slot or travel added. In-game offering and dialogue timing remain to be verified. This audit does not implement the proposed steps.

## Alternate opportunity requiring a deliberate route change

Winterfall Activity (8464) is client-valid, level 58/minimum45, no prerequisite, giver/ender Salfa at Winterspring27.73,34.50. It asks for eight each of Shaman7439 (56-57, cluster68.0,37.3), Ursa7438 (57-58,66.8,38.0), and Den Watcher7440 (55-56,mostly67.1,35.1). The main route's Threat of the Winterfall camp41.6,42.8 has Den Watchers but not the other two species, so omitting8464 from the main path remains justified.

`winterspring-alt` actually fights into Winterfall Village at69.6,38.3 for High Chief Winterfall5121. This makes8464 a reasonable companion quest there. However, Salfa is not an existing stop in that alternate; accepting and returning at Salfa adds two short west-side detours from Donova (31.27,45.16), plus enough Village kills to reach8/8/8 (Shaman source records have only six spawn points, so do not promise all credit during one cave approach). Recommendation: optional8464 pickup on the west-side Donova/tunnel trip before5121; objective alongside5121; return after5121/5123 atDonova. This is an optional improvement, not a zero-travel missed hand-in. All three mob types were verified in the cached Forever NPC records.

## Existing warning decisions

- `blasted-51` turn-ins2601/2603/2585/2583/2581: keep after the hunt. The tool calls a916-yard return redundant because their material hunt is expressed as a `note`, not `complete` steps. That note is actual required work unless AH materials already cover it; moving turn-ins to pickup would be wrong. These are stat-buff recipes in the prose, not profession-restricted quest eligibility.
- Tanaris2781/2875/8365: earlier `tanaris-43` pickup only carries slots to49; no corresponding Caliph/pirate objective visit occurs before the49 chapter. Current49 grouping is purposeful. 2605 is minimum44, targets49-area Thistleshrubs, and is paired with3362 at49; the earlier hub warning does not establish missed objective credit.
-3783: minimum52 but yeti mobs55-58; keep55 rather than carry from Everlook52.
-8551: Gorlash47elite;41 pickup would introduce an elite fight several levels early or carry to50.
-3881: level53/min48; at49 its route would need extra collection stops or carry through the crowded52/53 stretch.
-4504: level54/min48; keep53 tar-pit loop rather than take at48 merely because Tran'rek was visited then.
-5097: level56/min50, Andorhal53-57 enemies; keep57 rather than level51.
-4901: level59/min52 escort among57-59 owlbeasts; keep59 rather than55.

## Other screened omissions

-3789/3790 and1019 are alternatives to already-routed3763 and1047; adding them would duplicate exclusive breadcrumbs.
-4023 is the alternate to4022 already routed atCyrus.
-2582/2584/2586/2602/2604,2522/3502, cauldron material quests, cloth/reputation/seasonal followups are repeatables or specialized work, not missing first-time nearby field pickups.
-3378 requires the Prayer to Elune drop back in Searing Gorge after the56Zamael stop; current route does not revisit those Twilight mobs. Not a free nearby followup.
-4144 needs4143, absent from the currentroute; WildLeather quests requireLeatherworking225;6032 requiresTailoring290.
-5206 needs both5181/5168 and then kills atadditional EPL locations after the route has finished its main EPL loop; it is not free credit from the existing58 pickups.
-4284/pylons,4289/4301,5245,4084/4005/3961/3962,4513 retain the prior audit's specific crossing/log/return-trip reasons.

No runtime edits or full harness run were performed by this audit worker. Coordinator owns implementation, scenarios, capacity checks, full harness and installation.

## Review artifact

The coordinator also maintains the full omitted-ID inventory for this audit; this band's screen above is a narrower, manually reviewed subset. Consult the coordinator's final report for that inventory's exact file link. Route chapters and proposed additions remain unverified in game.
