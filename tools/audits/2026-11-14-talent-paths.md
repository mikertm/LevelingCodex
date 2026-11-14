# Talent paths: research and decisions (2026-11-14)

Every spec path in `TalentPaths.lua` with its sources, its split at 60 and the choices made. One research
pass per class read the Forever leveling guides published by 2026-11-14 (the game launched 2026-11-04);
the game's own tree (`tools/reference/forever.json`, `python tools/gamedata.py tree CLASS`) won over every
guide, many of which were written during the beta. Every path passes `tools/gamedata.py audit`
(`audit_paths`: levels 10-60 once, ranks, row points, prerequisites, icons, ASCII text). The step text is
our own wording from the game tooltips.

## Splits at 60 (tree order as the game lists them)

| Class | Codex guide (Data.lua, unchanged) | Spec paths |
|---|---|---|
| Warrior (Arms/Fury/Prot) | Protection 7/5/39 | Arms 32/19/0, Fury 10/41/0 |
| Druid (Balance/Feral/Resto) | Feral 7/39/5 | Balance 41/0/10, Feral Cat 0/38/13, Feral Bear 0/41/10, Restoration 11/0/40 |
| Hunter (BM/MM/SV) | Marksmanship 7/40/4 | Beast Mastery 32/14/5, Survival 0/17/34 |
| Mage (Arcane/Fire/Frost) | Frost 0/5/46 | Arcane 41/10/0, Fire 7/41/3 |
| Paladin (Holy/Prot/Ret) | Retribution 12/6/33 | Holy 34/5/12, Protection 0/36/15 |
| Priest (Disc/Holy/Shadow) | Shadow 14/0/37 | Discipline 40/11/0, Holy 14/32/5 |
| Rogue (Assn/Combat/Sub) | Combat 15/36/0 | Assassination 38/8/5, Subtlety 15/5/31 |
| Shaman (Ele/Enh/Resto) | Enhancement 8/39/4 | Elemental 40/0/11, Restoration 10/0/41 |
| Warlock (Aff/Demo/Destro) | Affliction 41/10/0 | Demonology 20/31/0, Destruction 15/3/33 |

## How much to trust them

- Icy Veins and Mobalytics refused every direct read (HTTP 403); their builds were seen only through
  search results and timesaver.gg's copies (Icy Veins, Maxroll, Wowhead presets).
- Few guides publish a level-by-level order yet. Where none did, the order was built from a published
  level-60 split plus the guides' leveling advice and the game's row gates; levels 41-60 are often our
  own fill. Each class section below says which.
- Choices made against a source: hidden talents (Lightning Reflexes, Holy Specialization) replaced; beta
  talents absent from the live tree (Raging Blows, Boundless Rage, Lava Burst, Arcane Focus, Murder and
  others) ignored; Hunter Survival keeps its pet (no Lone Wolf) because the leveling guides say so.
- Open question: beta guides mention a Legacy talent ("Talented") that hands out points from level 5.
  The Codex, like the shipped guide plans, assumes the first point at 10.
- Roles in the drafts normalised: Hunter Survival to Ranged damage, both Warlock paths to Caster damage.
- Druid: the guide's Feral plan is a cat/bear hybrid that matches RankedBoost's published hybrid
  (7/39/5); a dedicated Feral Cat path (0/38/13, with Primal Bite and Naturalist) sits next to it.

Each class section also reports what the online guides say about the shipped guide plan. Nothing in
Data.lua changed; those notes are for the owner to weigh in the guide pages.

## Warrior

Game data (tools/gamedata.py tree WARRIOR) was the authority for names, ranks, rows and prerequisites. Points spent before level L = L - 10, so row 5 opens at 20 (level 30), row 6 at 25 (35), row 7 (Mortal Strike, Bloodthirst) at 30 (level 40).

Fetch problems: mobalytics.gg and icy-veins.com returned HTTP 403 on every fetch, so only their search snippets were seen (no talent tables). method.gg, wow.gg and wowtbc.gg had no level order.

### Arms (final split 32 Arms / 19 Fury / 0 Protection)

Sources used:
- https://timesaver.gg/tools/wow-forever/talent-calculator/warrior/arms : "34/15/2, from Method, updated 2026-11-04, checked against live trees 13 Nov 2026". Full per-level order; the main skeleton.
- https://www.foreverwisp.com/guides/wow-forever-warrior-leveling-talents : reviewed 11 Nov 2026 (build 1.60.1.70888, not rechecked after the Nov 2 update). 31/20/0, full per-level order, calls itself untested theorycraft.
- https://wowforeverbuilds.com/guide/arms-warrior-leveling : updated Nov 9, 2026 (older talent data). 37/14/0, full per-level order, plus pull advice (Sweeping Strikes pairs, axes for Weaponmaster).
- https://wowforever.gg/en/builds/warrior-arms-leveling/ : updated 3 Nov 2026, milestone-only. Same Arms core to 40.
- https://wowforeverinfo.com/guides/warrior-leveling/ : updated 9 Nov 2026 (data 5 Nov). 33/18, milestone ranges; says Arms is the slowest solo spec (downtime).
- https://wowforeverinfo.com is also the source of the Rage/pooling advice. https://www.method.gg/wow-forever/wow-forever-warrior-leveling-guide-and-talents (updated 14 Nov 2026): order Rend, Tactical Mastery, Deep Wounds, Bloodthrill, Sweeping Strikes, Weaponmaster, Mortal Strike, then Unbridled Wrath and Enrage; no ranks.
- https://www.warcrafttavern.com/forever/guides/warrior-leveling/ and /arms-warrior/ : beta level-30 build (26 Arms points, no date); core Deflection, Anger Management, 2H Spec; skip Spearing Strike. Marked provisional.
- https://wow.gg/guides/wow-forever-fury-warrior : Arms is the more comfortable solo-leveling spec with a two-hander.
- Mobalytics (Kargoz 1-60 Arms, Oct 26 2026) and Icy Veins (Oct 17) known only from search snippets: Sweeping Strikes is the key leveling talent; mobalytics projects 17/34/7 (a PvP/end-game projection, not used).

Level-60 splits the sources give: 31/20 (foreverwisp), 34/15/2 (Method/timesaver), 33/18 (wowforeverinfo), 37/14 (wowforeverbuilds), 38/13 (classicwowforever, not fetched in detail). Chosen: 32/19.

Where they disagreed and what I chose:
- Levels 10-12 Improved Rend, then Deflection/Overpower/Tactical Mastery/Anger Management/Deep Wounds/2H Spec: all sources agree on this core, only the order differs. I followed the timesaver/Method order.
- Spearing Strike (Method, wowforeverbuilds take it): skipped. It only matters against Giants, Dragonkin and mounted targets (Warcraft Tavern says skip). The point went to Impale (needs Deep Wounds), with Impale rank 2 at 41.
- Improved Charge split 24 and 28 (one rank first, second rank later) to give a cheap early Rage opener without delaying Anger Management.
- Weaponmaster in two chunks (33-34, 37-39) with Improved Slam between, as Method does, so Slam is good by 36.
- Mortal Strike needs 30 Arms points: levels 10-39 are all Arms, so Arms cannot take any Fury or Protection point before 40. Methods that spread points (Improved Heroic Strike, Hamstring) do not fit with Slam and Impale; I left them out (Improved Heroic Strike appears only in the Fury path).
- Levels 41-60 (20 points): all sources spend them in Fury. Cruelty 5/5 first (all agree), Unbridled Wrath 5 and Enrage 5 (Method, foreverwisp, wowforeverinfo, wowforeverbuilds), then Blood Craze 3 and Piercing Howl (foreverwisp, wowforeverbuilds). Lingering Rage (Method) and Deflection/Improved Bloodrage (Method) were left out: Rage pays off more from Unbridled Wrath and Enrage, and Blood Craze helps downtime.

Beta vs game: guides written during the beta (Warcraft Tavern) mention Raging Blows, Boundless Rage and Improved Demoralizing Shout, which are not in the live tree; none used. wowforeverbuilds says its data is older; every talent used exists with the same ranks in the game data.

### Fury (final split 10 Arms / 41 Fury / 0 Protection)

Sources used:
- https://wowforeverbuilds.com/guide/beta-20-fury-warrior-leveling : published Sep 19, updated Nov 11, 2026. 41/10, full per-level order (levels 31-60 are theorycraft). Skeleton of the path.
- https://wowforever.gg/en/builds/warrior-fury-leveling/ : updated 3 Nov 2026, milestones. Death Wish at 30, Bloodthirst at 40; ends Arms 10-ish.
- https://wowforeverinfo.com/guides/warrior-leveling/ : updated 9 Nov 2026. 40 Fury/11 Arms: Cruelty, Unbridled Wrath, Furious Precision, Dual Wield Spec 25-29, Death Wish 30, Flurry 35-37, Bloodthirst 40. Says Fury comes online around 35-40; play it like Arms before that; Fury is the weaker solo leveler.
- https://classicwowforever.com/talents/warrior/ (search snippet and fetch): updated 11 Nov 2026; 34 Fury / 17 Arms; same core.
- https://www.warcrafttavern.com/forever/guides/fury-warrior/ : beta level-30 build; key talents Cruelty, Unbridled Wrath, Furious Precision, Dual Wield Specialization, Flurry, Enrage, Death Wish; Piercing Howl and Lingering Rage mentioned for the Fury beta build.
- https://wow.gg/guides/wow-forever-fury-warrior (Nov 4, 2026): Fury is strongest in groups with a tank; Arms more comfortable solo.
- https://kami-labs.fr/en/wow-forever/build-guerrier-fureur-wow-forever/ (published 14 Sep 2026, Nov 2 notes applied): end-game build, no leveling order; confirms the live tree changes (Raging Blows absent, Lingering Rage, Furious Precision, Gore Drinker, Reckless Swings, Improved Whirlwind added).
- Mobalytics 1-60 Fury (Oct 10, 2026) and Icy Veins Fury (Oct 31, 17/34/0 raid build) known from snippets only: dual wield, Death Wish, Flurry, Bloodthirst, Enrage.

Level-60 splits given: 41/10 (wowforeverbuilds), 40/11 (wowforeverinfo), 34/17 (classicwowforever), 17/34/7 (mobalytics projection). Chosen: 41/10.

Where they disagreed and what I chose:
- Death Wish at 30 (wowforever.gg, wowforeverinfo) vs 32 (wowforeverbuilds): 30 is the first level it can be bought (20 points in Fury), and it is the guide consensus, so I took it.
- Dual Wield Specialization at 25-29 (wowforeverinfo) vs 34+ (wowforeverbuilds): dual wield is the whole spec, row 4 opens at level 25, so I take it first (wowforeverinfo).
- Piercing Howl at 20 (wowforeverbuilds) vs later: I delayed it to 44 so all 30 points before 40 go to damage and Bloodthirst; Furious Precision moved to 20-22 (off-hand hits miss a lot).
- Reckless Swings, Improved Whirlwind before 40 (wowforever.gg has Whirlwind by 40; wowforeverbuilds has Reckless Swings at 33): Whirlwind is learned at 36 so I included it.
- Levels 41-50: Blood Craze 3, Piercing Howl, Improved Execute 2, Gore Drinker 2, Improved Berserker Rage 2 (wowforeverbuilds/wowforeverinfo mix). 51-60: Arms row 1-2 (Heroic Strike 3, Deflection 2, Improved Charge 2, Improved Tactical Mastery 3), as in wowforeverbuilds; improved Charge needs 5 Arms points, hence Deflection first. Improved Intercept and Lingering Rage were left out.
- Impale/Deep Wounds/Overpower (classicwowforever's Arms tail): not taken; I preferred stance Rage and Charge Rage.

Beta vs game: guides based on the beta mention the Legacy talent "Talented", which gives points from level 5 and shifts every level earlier. These paths assume no such shift.

### Online Protection leveling guides vs the shipped plan (report only)

Shipped plan (python tools/gamedata.py review WARRIOR): Shield Specialization 5 (10-14), Improved Thunder Clap 3, Improved Bloodrage 2, Master of Defense 2, Improved Revenge 3, Vanguard 25, Last Stand 26, Defiance 3, Concussion Blow 30, Focused Rage 3, Improved Shield Wall 1 (34), Bastion 5 (35-39), Shield Slam 40, Improved Shield Wall 41, then Cruelty 5 (42-46), Deflection 5, etc.
- Method (method.gg, updated 14 Nov 2026) recommends a Protection build for solo leveling; its page gives no ranks, only that Prot is the solo choice. wowforeverinfo says to level as Protection, then switch to Fury or Arms after Bloodthirst/Mortal Strike with dual spec at 40.
- No fetched source gave a Protection level order, so I cannot say the shipped order differs; the one data-based note is that the shipped plan takes Shield Slam at 40 with the Concussion Blow prerequisite, which matches the game tree.
- Possible comparison point: the shipped plan already notes Defiance may be questionable solo; the Fury/Arms guides do not touch it.

## Druid

Important caveat: no source found gives a level-by-level 10-60 order. Most pages name key talents or a split, some are beta-era. Orders were built from the game tree (gamedata.py tree DRUID: row gates, prerequisites) plus each source's level-60 build and leveling advice. Generator: scratchpad\gen_druid.py. Validator result: all four paths OK.

### Balance (41 Balance / 0 Feral / 10 Restoration)
- https://rankedboost.com/world-of-warcraft/forever/build/druid/ (published 2026-09-24, updated 2026-11-11, build 1.60.1.70888): Balance DPS 41/0/10, Moonkin, Naturalist, Moonfury, Improved Wrath 5, Vengeance 5, Improved Starfire 5, Eclipse 3. No leveling advice.
- https://www.warcrafttavern.com/forever/guides/balance-druid/ (no date; beta-era): 41/0/10 named talents; "Eclipse essential for hard-casting leveling", Nature's Reach gives enough hit so no hit gear is needed while leveling.
- https://www.warcrafttavern.com/forever/guides/druid-leveling/ (no date): Multi-DoT (Nature's Splendor, Insect Swarm, Overgrowth) vs Eclipse (Improved Starfire, Eclipse, Insect Swarm).
- https://www.method.gg/wow-forever/wow-forever-druid-leveling-guide-and-talents (updated 2026-11-14): Genesis, Nature's Splendor, Nature's Reach, Moonglow, Insect Swarm; Reflection and Naturalist from Restoration. Very short, no ranks.
- Not readable: mobalytics.gg balance leveling guide (403), icy-veins (403), wowtbc.gg (names missing in scrape).
- Chosen: the Eclipse hard-cast variant (Tavern says it is safer; rankedboost's 41/0/10 matches it). Dropped Improved Entangling Roots and Overgrowth (utility, 5 points) to fit 41 Balance. The 10 Restoration points are Nature's Focus 5 + Naturalist 5 (Naturalist needs 5 Resto points first; rankedboost lists Naturalist). Heart of the Wild is the alternative first five. Resto goes late (41-60) so Balance rows open on time: row N needs (N-1)*5 points in that tree.
- Disagreement: Method leans on the multi-DoT Genesis/Splendor line and Reflection; I put Genesis last (only 10% on DoTs) and skipped Reflection (Spirit is not worth it).

### Feral Bear (0 / 41 / 10)
- rankedboost (above): Feral Tank 0/41/10, Primal Bite, Naturalist; Lacerate, Rend and Tear, Natural Reaction central. Hybrid 7/39/5.
- warcrafttavern.com feral-druid guide (no date): hybrid 9/37/5; key talents Feral Charge, Lacerate, Predatory Discipline, Leader of the Pack, Shifting Power, Primal Bite; bear rotation Lacerate to 5 stacks, Primal Bite on cooldown, Swipe for packs, Maul for single targets. Druid-leveling page: Furor and bear-only talents can be moved to damage in dungeons.
- Method (2026-11-14): hybrid takes Feral Instinct early, Thick Hide, Primal Bite, Rend and Tear with Lacerate.
- Chosen: Ferocity, Thick Hide, Brutal Impact (Bash cooldown -30 sec in this tree), Feral Instinct, Savage Fury > Lacerate, Charge, Sharpened Claws > Blood Frenzy, Predatory Strikes, Leader of the Pack, Rend and Tear, Primal Bite, Natural Reaction, Heart of the Wild (+20% bear Stamina), Furor, Naturalist. Left out: Feral Swiftness, Shredding Attacks, Natural Instinct, Primal Bite gating works (Leader of the Pack first). Furor was kept only because the 41st point must go somewhere (Tavern says Furor can be cut).
- Game data note: Forever's Heart of the Wild moved to Restoration (some beta guides still list it under Feral).

### Restoration (11 Balance / 0 Feral / 40 Restoration)
- rankedboost: Healing build 11/0/40, Wild Growth, Nature's Splendor, Bloom, Improved Regrowth, Genesis.
- https://wow.gg/guides/druid-restoration-forever-overview (2026-09-19): talent ranks only; says it is "not a finished leveling build" and its split is inconsistent, so unused.
- https://kami-labs.fr/en/wow-forever/build-druide-restauration-wow-forever/ (published 2026-09-14): talent list only; status of each talent (new: Bloom, Living Spirit, Wild Growth).
- Method (2026-11-14): no resto leveling build; icy-veins/mobalytics not readable.
- Chosen: no source gives an order, so it is my own. The 11 Balance points are Improved Wrath 3 (early solo damage), then Genesis 5, Nature's Majesty 2 and Nature's Splendor, which needs 10 Balance points first (Splendor takes the 11th point; its row needs a maxed Majesty). Resto 40: Nature's Focus, Naturalist (damage, faster Healing Touch), Gift of Nature, Reflection, Improved Rejuvenation, Swiftmend, Nature's Swiftness, Living Spirit, Improved Regrowth, Wild Growth, Bloom, Heart of the Wild, Tranquil Spirit 2. Left out: Subtlety, Improved Tranquility, Natural Shapeshifter, 3 ranks of Tranquil Spirit.
- Leveling note: every source calls Resto the weakest leveling spec (mobalytics via search snippet: lacks Feral's damage and mobility). The path front-loads damage (Wrath, Nature's Focus, Naturalist) and gets healing power from 23 and Wild Growth at 44.

### Feral Cat (extra path, 0 / 38 / 13)
- rankedboost Feral Leveling Build 0/38/13 (solo cat; stay in cat, Feral Swiftness, Ferocity, Furor, Healing Touch with Naturalist and Natural Shapeshifter; Primal Bite, Naturalist). rankedboost cat raid build 9/32/10.
- Method (2026-11-14): damage build = Ferocity, Feral Swiftness, Leader of the Pack, Predatory Strikes, Primal Bite, Shifting Power, Feral Charge; Genesis 5 > Nature's Majesty/Nature's Reach and Heart of the Wild.
- Tavern hybrid (cat/bear): skip Shredding Attacks (solo you can't Shred).
- Chosen: the rankedboost 0/38/13 split. Heart of the Wild first (Strength +10% in cat), Naturalist at 36-40, Rend and Tear at 45 (later than the shipped plan), Primal Bite and Shifting Power at 51-52. I kept Shredding Attacks (3) because Shred is Forever's main cat builder; Tavern would drop it.

### Shipped Feral plan vs online guides (report only)
Shipped plan = Feral 39 / Resto 5 (Heart of the Wild) / Balance 7 (Genesis 5, Nature's Majesty 2), i.e. a 7/39/5 split. That is the same split as rankedboost's "Hybrid" build (7/39/5) and matches Method's damage build (Genesis > Nature's Majesty, Heart of the Wild). rankedboost's dedicated leveling cat is 0/38/13 (Naturalist + Natural Shapeshifter instead of Genesis/Majesty); the Tavern hybrid skips Shredding Attacks. The shipped plan lacks Primal Bite (every source lists it) and has no Naturalist; it takes Feral Instinct 2/3 at the very end. Verdict: it works as a cat leveling path (same split as published hybrid), with two gaps against rankedboost's leveling build: Primal Bite and Naturalist's +10% damage. The cat path in DRUID.lua is offered for comparison.

## Hunter

Many pages (Icy Veins, Mobalytics) returned HTTP 403 to the fetch tool, so Icy Veins builds were read through the timesaver.gg talent calculator, which copies them and states source dates.

### Beast Mastery (draft: 32 BM / 14 MM / 5 Survival)
- https://timesaver.gg/tools/wow-forever/talent-calculator/hunter/beast-mastery : lists Icy Veins BM leveling build 32/14/5 (updated 2026-11-04, checked against live trees 2026-11-13); Maxroll build 33/17/0 (2026-11-05); an earlier Icy Veins 39/12/0 (2026-10-17). Its own level order (BM 10-40: Deadly Aspects, Improved Revive Pet, Focused Fire, Endurance Training, Bestial Swiftness, Pathfinding, Unleashed Fury, Summon Hawk at 25, Ferocity, Intimidation, Bestial Discipline, Frenzy, Bestial Wrath at 40; then Marksmanship) was noted as not matching the Icy Veins build, and it skips level 60.
- https://realmfirst.net/world-of-warcraft-forever/classes/hunter/leveling/ (updated 2026-11-01, "theorycraft", not checked in client): BM 39/12/0, Deadly Aspects first, Bestial Wrath at 40, Marksmanship (Lethal Attacks, Efficiency, Rapid Killing) from 47. Notes Summon Hawk timing disagrees between sources (25 vs 34 vs last).
- https://mobalytics.gg/wow-forever/classes/1-60-beast-mastery-hunter-leveling-guide (via search/fetch summary, dated 2026-11-14): BM block of 31 points ending in Bestial Wrath around 40, then 20 Marksmanship points (Lethal Attacks, Careful Aim, Rapid Killing, Efficiency, Trueshot Aura, Mortal Shots 4); Summon Hawk at 25, Unleashed Fury 4/5, Frenzy 4/5. Other Mobalytics pages list 31/20/0 and 31/16/4. (fetch blocked, read via summary)
- https://maxroll.gg/wow-forever/class-guides/hunter-leveling-guide (updated 2026-11-04): BM is the best leveling spec; names Deadly Aspects, Improved Revive Pet, Summon Hawk, Pathfinding, Bestial Swiftness, Improved Mend Pet 1 point; suggests Endurance Training and Spirit Bond from Marksmanship points for pet survivability. No level order.
- https://www.warcrafttavern.com/forever/guides/hunter-leveling/ (no date, beta-era, level 30 cap): Summon Hawk 25, Intimidation and Bestial Discipline 30, Bestial Wrath 40, Efficiency named.
- https://www.method.gg/wow-forever/wow-forever-hunter-leveling-guide-and-talents and https://www.icy-veins.com/wow-forever/beast-mastery-hunter-leveling (403, only seen in search results): BM preferred; Icy Veins highlights Bestial Swiftness.

Choice: no source gives a full, trustworthy 10-60 BM order (Icy Veins' own order was not readable). I took Icy Veins' 32/14/5 split (also consistent with Mobalytics' 31-point BM block and Bestial Wrath at 40) and built the order from the consensus: Deadly Aspects first, Summon Hawk at 25 (Mobalytics, Method, Maxroll all agree; the 15 points needed for row 4 are done by then), Bestial Wrath at 40, then Marksmanship for personal damage (Lethal Attacks, Careful Aim), then Improved Tracking (Icy's 5 Survival points), Improved Stings 2, Efficiency 2. Frenzy at 4/5 and Unleashed Fury at 4/5 early to match Mobalytics/Icy. Improved Mend Pet 1 and Endurance Training 1 come from Maxroll/Icy mentions. I left out Spirit Bond, Rapid Killing, Trueshot Aura, Mortal Shots (some sources include them) to keep the Survival 5-point Icy shape.

### Survival (draft: 0 BM / 17 MM / 34 Survival)
- https://timesaver.gg/tools/wow-forever/talent-calculator/hunter/survival : Icy Veins Survival leveling build 0/17/34, full level order 10-60, updated 2026-11-04, checked against live data 2026-11-13. Used as the base.
- https://www.icy-veins.com/wow-forever/survival-hunter-leveling (Oct 21 2026 per search snippet; 403): Survival weakest leveling spec at the start, still behind BM.
- https://maxroll.gg/wow-forever/class-guides/hunter-leveling-guide (2026-11-04): Survival weaker than BM, "not really playable as its own spec until level 40+"; key late talents Strider Kick, Expose Prey, Resourcefulness, Lacerating Strikes.
- https://www.warcrafttavern.com/forever/guides/hunter-leveling/ (undated, beta): Survival milestones Strider Kick, Expose Prey, Resourcefulness at 30, Lacerating Strikes at 40; last 2 points Trueshot Aura and Lone Wolf; keep your pet.
- https://realmfirst.net/world-of-warcraft-forever/classes/hunter/leveling/ (2026-11-01): no Survival order.
- https://wow.gg/guides/hunter-survival-forever-overview (2026-09-19, beta): says it is not a leveling build; example 52 points (over budget).
- https://kami-labs.fr/en/wow-forever/build-chasseur-survie-wow-forever/ (2026-09-14): end-game build only, no leveling order.
- https://mobalytics.gg/wow-forever/classes/survival-hunter-guide-1-60-ludideo (2026-11-03): 403, not read.

Disagreements and choices:
- Icy Veins' order uses Lightning Reflexes (5 points, levels 40-44). That talent is HIDDEN in the game data, so I replaced those 5 points with Improved Wing Clip 3, Deterrence 1, Counterattack 1 (all real Survival talents, and they keep the 30 points in the tree that Lacerating Strikes needs at level 45).
- Icy Veins takes Lone Wolf (1) and Improved Stings 3, Efficiency 1, Mortal Shots 2. Warcraft Tavern says keep your pet while leveling, so I dropped Lone Wolf and used the points for Efficiency (2 total) and Mortal Shots (still 17 in Marksmanship). Result: Lethal Attacks 5, Careful Aim 5, Improved Stings 3, Efficiency 2, Mortal Shots 2.
- Resourcefulness only 1 rank (as Icy), Predator's Edge 5 at 30-34, Strider Kick at 35, Expose Prey 36-37, Lacerating Strikes 45 (matches Warcraft Tavern 30/40 milestones loosely).

### Beta vs game data
- Lightning Reflexes (hidden) overruled as above. Improved Serpent Sting is hidden too and never used.
- Tooltip numbers come from the game tree (e.g. Deadly Aspects 10% at 5/5, Expose Prey 10% chance, Improved Stings 20% at 3/3). Pathfinding was moved in the Maxroll calculator on 2026-11-04; the game tree here shows it on row 3.

### Marksmanship: online guides vs the shipped plan (report only)
Shipped plan (tools/gamedata.py review HUNTER): Lethal Attacks 5, Careful Aim 5, Rapid Killing 2, Improved Stings 3, Trueshot Aura 1 (25), Mortal Shots 5, Barrage 3, Rapid Recuperation 1 then 2 (34/41), Ranged Weapon Specialization 5, Sniper Shot at 40, Hawk Eye 3, Efficiency 5, then Deadly Aspects 5, Focused Fire 2, and so on: roughly 31 MM / BM 20 at 60.
Online:
- Mobalytics Ludideo (https://mobalytics.gg/wow-forever/classes/marksmanship-hunter-guide-ludideo): 7/31/13 split, 31 MM points to reach Sniper Shot (same capstone idea as the shipped plan).
- Mobalytics Kargoz BM page: MM block at 41-60 starting Lethal Attacks, Hawk Eye, Careful Aim, Lone Wolf, Rapid Killing 1, Mortal Shots (a BM-first variant, not MM-first).
- Icy Veins Marksmanship leveling (https://www.icy-veins.com/wow-forever/marksmanship-hunter-leveling, updated 2026-10-17, 403): calls MM one of the strongest leveling specs and discusses delaying Deadly Aspects to start Marksmanship sooner. Full list not readable.
- Warcraft Tavern: Trueshot Aura 25, Rapid Recuperation 30, Sniper Shot 40, Lone Wolf at 20 not advised, Concussive Shot and Scatter Shot optional.
Overall the shipped plan matches the common ideas (Lethal Attacks, Careful Aim first, Trueshot at 25, Sniper Shot at 40). Differences: online guides put Hawk Eye and Lone Wolf in; the shipped plan takes Barrage, Ranged Weapon Specialization and Rapid Recuperation, which I did not see mentioned online.

## Mage

Access note: icy-veins.com and mobalytics.gg returned 403 to WebFetch, so only their search snippets were seen. Level-by-level orders come from Method and Warcraft Tavern pages; the rest I built from the game tree and leveling advice.

### URLs used
- https://www.method.gg/wow-forever/wow-forever-mage-leveling-guide-and-talents (Method, "last updated 14th November 2026"; Frost leveling order, Frost/Arcane split; Fire and Arcane not given in the fetched text)
- https://www.warcrafttavern.com/forever/guides/mage-leveling/ (no date; milestone tables for Arcane, Fire and Frost at levels 10-40, advice)
- https://www.warcrafttavern.com/forever/guides/fire-mage/ (no date, copyright 2026; level 60 Fire builds: Fire/Arcane and Fire/Frost "Frostfire Bolt")
- https://www.warcrafttavern.com/forever/guides/arcane-mage/ (no date; level 60 Arcane build: Arcane with a Fire dip of Incineration, Accelerant, Improved Fire Blast, Ignite, Pyroblast, Heating Up)
- Search snippets only: https://www.icy-veins.com/wow-forever/fire-mage-leveling (Sept 2026 per snippet), https://www.icy-veins.com/wow-forever/arcane-mage-leveling, https://mobalytics.gg/wow-forever/classes/mage-leveling-guide (Fire called the weakest leveling spec; Frost to 25 then respec to Arcane suggested; Mobalytics Fire page Oct 2026)
- Game data: tools/reference/forever.json (tree and spells).

### Arcane (my split: Arcane 41 / Fire 10 / Frost 0)
- Warcraft Tavern milestones: Arcane Concentration, Missile Barrage, Arcane Subtlety by about 15; Arcane Blast 20; Meditation and Wrath 25; Presence of Mind and Arcane Mind 30; Arcane Instability 35; Arcane Power 40. Advice: rush Missile Barrage, add Arcane Impact, Incineration later.
- Method (as the final 18 points after Frost): Improved Channeling, Arcane Concentration, Missile Barrage, Arcane Subtlety, Arcane Blast (taken at 57 there), Arcane Meditation.
- Warcraft Tavern level 60: Arcane main, Fire dip of Incineration, Accelerant, Improved Fire Blast, Ignite, Pyroblast, Heating Up.
- My order follows the Tavern milestones. Differences: Improved Channeling 5/5 first because it opens row 2 (Barrage needs 5 Arcane points); Arcane Blast at 20 (the first level row 3 is open, and in this tree Blast is a talent). Late points: Incineration 5 and Accelerant 5 (Accelerant speeds Arcane Wrath), then Wand Specialization, Arcane Resilience, Improved Counterspell, Arcane Geometry. Skipped Magic Absorption and Arcane Shielding. I did not copy the Pyroblast/Heating Up/Ignite part of the Tavern 60 build: Pyroblast is Fire-tree row 3 and would need 10 Fire points first.
- Disagreement: Mobalytics suggests leveling Frost to 25 and respeccing into Arcane; Method puts Arcane last (levels 43-60). I chose Arcane from level 10, as the user asked for a dedicated path.

### Fire (my split: Fire 41 / Arcane 7 / Frost 3)
- Warcraft Tavern milestones: Incineration + Accelerant 10, Ignite 15, Pyroblast + Burning Soul 20, Heating Up + Master of Elements + Improved Scorch 25, Blast Wave + Critical Mass 30, Fire Power 35, Combustion 40. Missile Barrage "usually around 50", or 7 points early if mobs give trouble. Level 60 builds: Fire/Arcane (Incineration 5, Critical Mass 3, Fire Power 3, Master of Elements 1, Arcane Meditation 2, Precision 3 ...) and Fire/Frost with Frostfire Bolt (Precision mandatory).
- Method gives no Fire order; Mobalytics and Icy Veins disagree about whether Fire is a good leveling spec (snippets only).
- My choices: Accelerant first (Incineration only affects Fire Blast, Scorch, Arcane Blast and Ice Lance in this tree, not Fireball, so it is later: 41-45). Burning Soul at 21-23 and Precision (Frost) later, because early Precision delayed row gating (row 4 needs 15 Fire points, row 5 needs 20, Combustion needs 30). Barrage dip (Improved Channeling 5 + Missile Barrage 2) at 54-60, matching "around 50". I skipped Improved Flamestrike and Improved Fire Ward.
- Doubt: the Fire path is the least validated; Arcane Missiles dip is at the very end, and the sources mostly address level 40 and below.

### Game data overruling the beta guides
- Many guides list Arcane Focus, or a 31-point Arcane Fire dip. This tree has no Arcane Focus; Precision gives hit. Frostfire Bolt exists (learned at 40) and Arcane Blast, Arcane Wrath, Pyroblast and Heating Up are talents.
- Rank values shown in the tooltip are for max rank; I used those, with per-rank notes in "more".

### Frost: online leveling guides vs shipped plan (report only)
Shipped plan (10-44): Improved Frostbolt 5, Precision 2, Frostbite 3, Ice Lance, Ice Shards 5, Shatter 3, Ice Block, Fingers of Frost 2, Improved Frost Nova 2, Cold Snap, Frost Channeling 3, Arctic Reach 2, Ice Barrier (40), Permafrost 3, Precision 3rd point.
- Method: Improved Frostbolt, Precision, Frostbite, Ice Lance, Ice Shards (3 points), Ice Block (25), Shatter, Fingers of Frost, Improved Cone of Cold, Winter's Chill, Cold Snap, Ice Barrier, remaining in Cone of Cold and Ice Shards; then 18 points in Arcane (Improved Channeling, Concentration, Missile Barrage, Subtlety, Blast, Meditation).
- Warcraft Tavern: Improved Frostbolt 10, Frostbite and Ice Shards 15, Ice Lance and Frost Channeling 20, Shatter and Ice Block 25, Cold Snap and Fingers 30, Winter's Chill 35, Ice Barrier 40, plus 7 early Arcane points for Missile Barrage.
- Similar: same opening, Ice Barrier at 40. Differences: online guides take Winter's Chill (5 ranks, row 6) and Improved Cone of Cold; the shipped plan takes Improved Frost Nova, Arctic Reach and Permafrost instead, and has no points past 44 in the review output (the reviewed plan ends at level 44 on screen; later levels not shown in the first 80 lines read). Both take Barrage/Arcane after 40 online, which the shipped plan did not show in what I read.

## Paladin

Many pages (icy-veins, mobalytics, wow.gg partly) returned 403 or gave no level-by-level text; the order below comes from the pages that did load.

### Holy (result 34 Holy / 12 Ret / 5 Prot, matches game tree validator)
- https://timesaver.gg/tools/wow-forever/talent-calculator/paladin/holy : Wowhead Holy leveling 34/5/12 (updated 2026-11-04, trees checked against live game 2026-11-13; no level order) and Maxroll Holy 31/8/12 with a full level order (Ret later, Spiritual Focus 5 first, Illumination by 26).
- https://kami-labs.fr/en/wow-forever/build-paladin-sacre-leveling-wow-forever/ : published 2026-11-12, 34/12/5, level order (Ret 10-21: Benediction 5, Conviction 3, Improved Judgement 2, Pursuit 2; then Holy; Divine Intellect last). Says its talents come from the Icy Veins leveling guide.
- https://wow.gg/guides/paladin-holy-forever-overview : Forever Holy changes (Illumination refunds half the base cost, Reverence, Light's Vigil); suggested priority list, no leveling order.
- https://www.warcrafttavern.com/forever/guides/paladin-leveling/ : beta-era (level 30 cap) Holy "Shockadin"; images only, no points. Not used for the order.
- https://www.method.gg/wow-forever/wow-forever-paladin-leveling-guide-and-talents (updated 2026-11-14): Ret-only route; says no dedicated Holy leveling build. Confirms Ret mana talents first.
- Not readable (403): icy-veins.com/wow-forever/holy-paladin-leveling, mobalytics.gg holy / shockadin guides.
- Disagreement: Maxroll goes Holy first (31/8/12, Benediction at 41-45); Wowhead and Kami go 34/5/12 or 34/12/5 with Ret mana and speed first. I chose the Kami order (Ret first to 21 for solo speed and mana, then Holy), keeping the Wowhead/Kami totals, because the task says it must be levelable. Healing Light only starts at level 29 in my order (Kami has it split 20s/30s), so early dungeons are healed on base spells; that is a real weakness. I put Pursuit of Justice at 20-21 (Kami spread it) and Improved Seals in the last points (Kami has it at 59-60 and Holy Power 5). Spiritual Focus is mainly a gate.
- Game data: Forever tree matches all names/ranks used. Beta guides' (Warcraft Tavern) 26-point/Legacy builds do not apply.

### Protection (result 0 Holy / 36 Prot / 15 Ret)
- https://timesaver.gg/tools/wow-forever/talent-calculator/paladin/protection : Wowhead 0/32/19 (2026-11-04, checked 2026-11-13, no order) and Maxroll 7/31/13 with full level order (Redoubt 10-14, Sacred Duty, Guardian's Favor, Shield Specialization, Templar's Bulwark, Holy Shield at 30, Reckoning, Iron Creed, Shieldsworn at 40, then Ret/Holy).
- https://kami-labs.fr/en/wow-forever/build-paladin-protection-leveling-wow-forever/ : published 2026-11-12, 35 Prot / 16 Ret, Ret first (Benediction 5 ...), Protection from 22, Holy Shield at 42, Reckoning to 47, Iron Creed and Anticipation at the end.
- https://www.method.gg/wow-forever/wow-forever-paladin-leveling-guide-and-talents : no Prot-from-1 build; notes Divine Intellect replaces Anticipation while leveling, Holy Shield is the 21-point talent.
- https://www.warcrafttavern.com/forever/guides/paladin-leveling/ and mobalytics (axphyxiate gaming, Nov 2 update; 0/21/0 style, Holy Shield first) : only summaries; mobalytics 403.
- Disagreement: Maxroll and Kami differ on Prot-first (Maxroll) versus Ret-first (Kami); Wowhead has Ret 19. I took Maxroll's Prot core up to Holy Shield at 30 and Shieldsworn at 40 for tanking early, then used Wowhead/Kami's Ret mana and crit (Benediction, Conviction, Improved Judgement, Pursuit, Sanctified Judgement) from 41. Dropped Guardian's Favor and Swift Judgement (utility) for Precision and Toughness (Wowhead, solo kills). Result 36/15 is close to Kami's 35/16.
- Game data: Anticipation (beta/end-game guides) is deliberately left out (Method says Divine Intellect replaces it while leveling). Reckoning's tooltip is 40%/100% per the game; used as printed.

### Retribution: online guides versus the shipped plan (report only)
Shipped (`gamedata.py review PALADIN`): Benediction 10-14, Conviction, Improved Judgement, Seal of Command 20, Pursuit 21-22, Sanctified Judgement 23-25, Sacred Arbiter 26, Two-Handed Spec 27-29, Vengeance 30-32, Repentance, Vindication, Champion of the Light to 5/5, Unsealed Wrath 40, then Divine Strength, Reverence, Improved Seals, Divine Intellect, Precision.
- Method (2026-11-14) main route: Benediction, Sanctified Judgement, Improved Judgement, Pursuit by 21, Seal of Command, Conviction, Sacred Arbiter, Two-Handed Spec, Vengeance, Champion of the Light, 1 Unyielding Faith, Unsealed Wrath, then Holy Divine Strength / Improved Seals / Holy Conduit, then Precision. Same core as shipped; differences: Method wants Sanctified Judgement right after Benediction, one Unyielding Faith point, Holy Conduit; shipped has Reverence and Divine Intellect.
- Method's alternative: after Pursuit at 21, go Holy (Divine Strength, Improved Seals, Holy Conduit) and use Seal of Righteousness for the mana talents by level 32, then back to Ret.
- Kami and Maxroll Holy/Prot builds start with Benediction 5 (and Conviction / Improved Judgement / Pursuit), matching the shipped opening.
- Mobalytics Whiter "Shockadin"/Ret guides (Nov 4) could not be read (403).

## Priest

Note: icy-veins.com and mobalytics.gg returned HTTP 403 to fetches, so their pages were not read directly. Their builds were read through the aggregator below.

### Discipline (draft: 40 Disc / 11 Holy / 0 Shadow)
- https://timesaver.gg/tools/wow-forever/talent-calculator/priest (talent data read from the client 2026-11-13). Lists "Discipline healer leveling, levels 40-60 (36/15/0)", credited to Maxroll, updated 2026-11-04, with a full 10-60 order; also "Discipline leveling 1-39 (23/0/7)" with Spirit Tap and Improved Shadow Word: Pain. Main base for the order.
- https://rankedboost.com/world-of-warcraft/forever/build/priest/ (published 2026-09-24, updated 2026-11-08, build 1.60.1.70888): Discipline Healing 31/20/0 (Mental Strength 5, Twilight Focus 3, Inspiration 3, Twin Disciplines 5, IPWS 3, Renewed Hope 5, Divine Fury 5, Holy Reach 1, Holy Specialization 5, Searing Light 2, Mental Agility 3, Meditation 3, Soul Warding 1, Power Infusion). Not a leveling build; says the only leveling build is Shadow.
- https://kami-labs.fr/en/wow-forever/build-pretre-discipline-wow-forever/ (2026-09-14): tree list only, "end-game build", no order. https://kami-labs.fr/en/wow-forever/pretre-wow-forever-leveling-baguette/ : wand replaces Smite for leveling (wands scale with spell power); not fetched in full.
- https://www.warcrafttavern.com/forever/guides/priest-leveling/ (no date, beta, level 30 builds as images): Disc is for a wand-focused style, Penance after 30.
- https://www.method.gg/wow-forever/wow-forever-priest-leveling-guide-and-talents (updated 2026-11-14): only advice (respec Shadow at 40 for Shadowform); no Disc build in text.
- Search snippets only: icy-veins.com/wow-forever/discipline-priest-leveling (Oct 16, 2026; weak damage and AoE), mobalytics (Shadow recommended for leveling).

Level-60 splits: Maxroll 36/15/0 (uses hidden Holy Specialization), Rankedboost 31/20/0 (same). Mine: 40/11/0.

Disagreements and choices
- The Maxroll order (levels 10-40) is used unchanged through Power Infusion at 40 (all talents exist, ranks match, rows open in time; it skips Spirit Tap, which the 1-39 variant uses; I chose pure Disc for the 40-60 version).
- Both sources spend 5 points in Holy Specialization at 41-45. It is the hidden talent, so it is replaced: 5 points of Power in Light (a real Smite/Penance damage talent) take its slot.
- Maxroll puts Divine Fury at 46-50 behind Holy Specialization (row 1 points). Without it, Divine Fury is reached through Twilight Focus 3 + Improved Renew 2 (5 Holy points). Twilight Focus then Improved Renew, Divine Fury 51-55, Improved Renew rank 3 at 56. Maxroll ends with Improved Renew 2; mine finishes Holy Precision 3/3 and Improved Inner Fire 2/3 instead (Holy Precision benefits Smite/Holy Fire hit rate; Inner Fire survivability). Searing Light cannot be reached (needs 15 Holy points, only 11 are spent without the hidden talent).
- Game data overruled: Penance, Divine Aegis, Renewed Hope, Power in Light, Twin Disciplines and others exist as in the tree. Tooltips (Twin Disciplines 5%, Mental Strength 10%, etc.) are quoted at max rank.

### Holy (draft: 14 Disc / 32 Holy / 5 Shadow)
- https://timesaver.gg/tools/wow-forever/talent-calculator/priest : "Holy leveling, levels 10-60 (14/32/5)", credited to Icy Veins, updated 2026-11-04, full 10-60 order. The draft follows it level for level.
- https://rankedboost.com/world-of-warcraft/forever/build/priest/ (updated 2026-11-08): Holy Healing 17/34/0 (Mental Strength 5, Spirit of Redemption, Twin Disciplines 5, Improved Renew 3, Divine Fury 5, Spiritual Guidance 5, Spiritual Healing 3, Holy Specialization 5, Searing Light 2, Meditation 3, Improved Healing 3, Litany of Light 2, Silent Resolve 3, Inspiration 3, Prayer of Mending, Inner Focus). Level 60 endgame, not leveling.
- https://www.warcrafttavern.com/forever/guides/priest-leveling/ : Holy is for dungeon-heavy leveling; "leveling primarily as a healer is not recommended" because of slow kills. Holy build 18/33/0 (beta, level 30 images).
- https://kami-labs.fr/en/wow-forever/build-pretre-sacre-wow-forever/ (2026-09-14): endgame tree list, no order.
- https://wowtbc.gg/warcraftforever/class-guides/holy-priest/ : build page with no readable points; stresses alternating heals for Litany of Light.
- Search snippets only: icy-veins.com/wow-forever/holy-priest-leveling (Oct 16, 2026), wow.gg Holy ("not a finished leveling build"), mobalytics (Shadow recommended).

Level-60 splits: Icy Veins 14/32/5, Rankedboost 17/34/0, Warcraft Tavern 18/33/0. Mine: 14/32/5 (Icy Veins).

Disagreements and choices
- Icy Veins' Holy build takes 2 points in Holy Specialization at 41-42 (hidden talent). Replaced with 2 points of Spell Warding, which also gets Holy to 15 points so Searing Light (row 4) opens at 43 as in the source. Everything else follows the source exactly.
- Kept Spirit Tap (Shadow) at 12-16 as the source does: the mana engine for a slow-killing healer.
- Inner Focus last at 60 because the Discipline row 3 gate is already met by then.

### Online Shadow guides vs the shipped plan (reporting only; nothing changed)
Shipped plan (tools/gamedata.py review PRIEST): 10-14 Spirit Tap 5; 15-16 Improved SW:Pain 2; 17-18 Shadow Reach 2; 19 Shadow Focus 1; 20 Mind Flay; 21-22 Improved Mind Flay; 23-24 Shadow Focus; 25 Vampiric Embrace; 26-28 Shadow Weaving; 29 Shadow Focus; 30-31 Devouring Contagion; 32 Silence; 33-34 Improved Mind Blast; 35-39 Darkness; 40 Shadowform; 41-42 Early Demise; 43 Shadow Focus; 44-46 Improved Mind Blast; 47-51 Twin Disciplines; 52-56 Mental Strength; 57 Inner Focus; 58-60 Meditation. Split: 31 Shadow, 20 Discipline.
- Method (updated 2026-11-14): a mana-efficient, tanky build to 39, then respec to Shadow at 40 for Shadowform. Talent details not readable. Damage falls off in the mid-to-late 30s.
- Mobalytics: Shadow is the recommended leveling spec; its first Disc points (Wand Specialization) depend on having a wand early, otherwise go straight into Shadow. Not readable in detail (403).
- Rankedboost (updated 2026-11-08) lists a Shadow Priest Leveling Build and shares 24 of 51 points with its Disc PvP build; details not read.
- Maxroll 1-39 on timesaver is a Disc build (23/0/7) with Wand Specialization 2 first and Spirit Tap, not Shadow.
- Warcraft Tavern: Shadow weak before 28 without spell power, Mind Flay and Devouring Plague at 20+; matches the shipped Mind Flay at 20.
- Observation: the other guides open with Wand Specialization (Disc 2 points at 10-11) before Spirit Tap; the shipped plan goes straight to Spirit Tap. No source read was Shadow-specific enough to say the shipped order is wrong.

## Rogue

Almost no guide gives a level-by-level order or exact ranks (talent builds are images/calculator links). The order below was built from the game tree's point gates plus the guides' priorities and leveling advice.

### Assassination (split 38 Assassination / 8 Combat / 5 Subtlety)
Order: Malice 5, Remorseless Attacks 2, Ruthlessness 3, Improved Slice and Dice 3, Vigor 2, Lethality 2, Improved Poisons 5, Cold Blood, Relentless Strikes 5, Venom, Vile Poisons 1, Mutilate (40), Seal Fate 3, Vile Poisons +4, Opportunity 5, Coup de Grace 3, Efficient Strikes 2, Puncturing Wounds 3.
Sources:
- https://www.warcrafttavern.com/forever/guides/rogue-leveling/ (no date; copyright 2026). Milestones: Malice/Remorseless L10, Imp SnD/Ruthlessness L15, Lethality L20, Imp Poisons/Venom/Relentless L30, Seal Fate L35, Mutilate L40. Open Stealth+Ambush, keep SnD up, Shank for Energy.
- https://www.warcrafttavern.com/forever/guides/assassination-rogue/ (no date; images Oct 2026). Malice a must-have, Mutilate main builder boosted by Lethality, Opportunity, Remorseless; L60 takes Lethality, Improved Poisons, Vile Poisons, Seal Fate, Venom, Opportunity, Puncturing Wounds, Precision.
- https://www.method.gg/wow-forever/wow-forever-rogue-leveling-guide-and-talents (updated 14 Nov 2026). Dagger Backstab until Mutilate, Cold Blood dip, poisons from L20.
- https://rankedboost.com/world-of-warcraft/forever/build/rogue/ (published 24 Sep, updated 8 Nov 2026, game build 1.60.1.70888). Assassination DPS 36/13/2: Malice, Vile, Imp Poisons, Relentless, Seal Fate, Ruthlessness, Puncturing Wounds, Coup de Grace, Imp SnD, Lethality, Vigor, Venom, Mutilate.
- https://kami-labs.fr/en/wow-forever/build-voleur-assassinat-wow-forever/ (14 Sep 2026): endgame, not leveling; Malice, Lethality, Vile/Imp Poisons, Cold Blood, Mutilate, Venom, Blood Splatter.
- https://wowtbc.gg/warcraftforever/class-guides/assassination-rogue/ : only rank caps, no data. Icy Veins (icy-veins.com/wow-forever/assassination-rogue-leveling, updated 17 Oct 2026 per search snippet) returned 403; used only the search summary (maximise damage, Sinister Strike then Mutilate). wow.gg and mobalytics pages 403/no data.
Disagreements/choices:
- Tavern's L60 build uses Murder and Blood Splatter; game tree has NO Murder (removed at launch) and Blood Splatter is only a 1-rank row 3 talent. Followed the tree; skipped Blood Splatter (only helps Rupture/Garrote, rare for this path).
- Ranked Boost has Relentless, Vigor and Endurance; I skipped Endurance/Composure/Lightning Reflexes (Combat) and kept Vigor 2.
- Mutilate needs 30 points in the Assassination tree and Venom, so levels 10-39 are all Assassination. That forces Opportunity (a Subtlety talent every guide likes) to levels 48-52. Alternative: Opportunity 5 at 10-14 and Mutilate at 45.
- Precision (Tavern) skipped: guides want it for hit cap at 60; the game gives only 1% per rank (3% max).

### Subtlety (split 15 Assassination / 5 Combat / 31 Subtlety)
Order: Opportunity 5, Improved Ambush 3, Malice 5, Improved SnD 3, Dirty Deeds 2, Initiative 3, Premeditation, Serrated Blades 3, Ghostly Strike, Elusiveness 2, Hemorrhage, Preparation, Master of Deception 3, Boot Knife 5, Death Mark (48), Ruthlessness 3, Lethality 2, Coup de Grace 3, Vigor 2, Efficient Strikes 2.
Sources:
- https://www.warcrafttavern.com/forever/guides/subtlety-rogue/ and rogue-leveling (no dates): Ambush build (Opportunity 5, MoD, Camouflage, Improved Ambush, Coup de Grace, Efficient Strikes, Initiative, Preparation, Death Mark, Serrated Blades + Hemorrhage baseline, Ghostly Strike to Ambush in combat); Bleed build (Dirty Deeds, Initiative, Blood Splatter, Malice, Imp SnD, Ruthlessness). Says Subtlety feels weak at low levels, "essential" Imp SnD and Efficient Strikes.
- https://www.method.gg/wow-forever/wow-forever-rogue-leveling-guide-and-talents (14 Nov 2026): Ambush build with Ghostly Strike, Vanish, Preparation; Hemorrhage as combo builder; Subtlety good for groups; solo recommends Combat.
- https://rankedboost.com/world-of-warcraft/forever/build/rogue/ (updated 8 Nov 2026): only a PvP Subtlety build (5/17/29).
- https://mobalytics.gg/wow-forever/profile/roguesdiary/classes/subtlety-leveling-guide (updated 26 Oct 2026 per search snippet; page itself 403): Combat for dungeons, Subtlety for open world. https://wow.gg/guides/rogue-subtlety-forever-overview: "not a ready-made leveling build". wowtbc.gg: no data.
Disagreements/choices:
- Tavern's milestone table names "Thousand Cuts" and "Improved Sinister Strike/Eviscerate" (old beta talents): not in the game tree; ignored. Blood Splatter is in the Assassination tree (not Subtlety) and gated; Bleed build skipped, Ambush dagger build chosen for leveling (simpler).
- Death Mark needs 30 Subtlety points and Preparation; reached at 48, with early Malice/Imp SnD from Assassination for survivability of a weak early spec. Skipped Camouflage, Setup (guides optional); kept Elusiveness for Vanish-Ambush.
- Tavern lists Coup de Grace and Efficient Strikes in Ambush build; placed last (Combat dip).

### Combat: online guides vs shipped plan (report only)
Shipped plan (`gamedata.py review ROGUE`): Efficient Strikes 2, Coup de Grace 3, Deflection 3, Precision 3, Riposte, Endurance 2, Improved Sprint, Aggression 3, Weapon Expertise 2, Blade Flurry (30), Dual Wield Spec 2, Hack and Slash 5, Flash of Steel 5, Adrenaline Rush (40), then more Combat; spent in Combat tree almost entirely from L10.
Online:
- Ranked Boost "Combat leveling" 14/37/0: Lightning Reflexes 5, Malice 5, Hack and Slash 5, Flash of Steel 5, Deflection 3, Aggression 3, Ruthlessness 3, Coup de Grace 3, Precision 3, Remorseless 2, Lethality 2, Efficient Strikes 2, Endurance 2, Weapon Expertise 1, Composure 1, Flawless Execution, Vigor 2, Adrenaline Rush. Notes: kill faster, take fewer hits.
- Tavern: Combat milestones (Efficient/"Improved Sinister Strike", Precision, Riposte, Flawless Execution/Aggression/Weapon Expertise L25, Blade Flurry/Dual Wield/Hack and Slash L30, Flash of Steel L35, Adrenaline Rush L40); Method: Cold Blood dip, Riposte priority, avoid daggers.
Differences: online builds put a ~14-point Assassination dip (Malice 5, Vigor 2, Remorseless 2, Lethality 2, Ruthlessness 3, Imp SnD) and Lightning Reflexes into Combat, which the shipped plan does not (it is pure Combat for 41+ points); the shipped plan has Dual Wield Specialization 2 and Improved Sprint, which the online builds skip or reduce to 1. Shipped plan includes none of Malice/Vigor. No changes made.

## Shaman

Honest summary: online Forever Shaman guides are thin. Almost none give a text level-by-level order or a
level-60 split for Elemental/Restoration (builds are images or calculator links; most guides were written for the
level-30 beta). Both paths were therefore built from the game tree (tools/gamedata.py tree SHAMAN) plus the
general leveling advice below. Icy Veins and Mobalytics returned HTTP 403, so their pages could not be read
(only search snippets).

### Elemental (40 Elemental / 0 Enhancement / 11 Restoration)
URLs used:
- https://www.rankedboost.com/world-of-warcraft/forever/build/shaman/ (published 2026-09-24, updated 2026-11-08): no Elemental leveling build; DPS build 35 Elemental; PvP 31 Elemental / 20 Enhancement. Its leveling build is Enhancement 43/Resto 8 (Tidal Focus 5 and Mindfulness 3 as the Resto splash).
- https://wow.gg/guides/shaman-elemental-forever-overview (2026-09-19): "not a finished leveling build", sample 46 Elemental + 5 Enhancement. Uses Convection, Concussion, Reverberation, Call of Flame, Elemental Fury, Lightning Overload, Lightning Mastery.
- https://kami-labs.fr/en/wow-forever/build-chaman-elementaire-wow-forever/ (2026-09-14): end-game build; names Lightning Overload, Call of Thunder, Lightning Mastery, Earthbound; says to use a separate levelling build for 10-60 (not shown).
- https://wowtbc.gg/warcraftforever/class-guides/elemental-shaman/ : only rank counts, no names or order.
- https://www.warcrafttavern.com/forever/guides/shaman-leveling/ (undated, beta, builds as images, up to level 30). Notes Restoration milestones Water Shield 20, Mana Tide 25, Nature's Swiftness 30.
- https://mobalytics.gg/wow-forever/classes/elemental-shaman-leveling-guide (403; snippet only): Elemental is mana hungry, many drink stops early; Water Shield now returns 2% mana on being hit or spell crit.
- https://www.icy-veins.com/wow-forever/elemental-shaman-leveling (403, not read).
Disagreements: sources agree on the core (Concussion, Convection, Reverberation, Elemental Fury, Lightning Overload, Lightning Mastery). Rankedboost's leveling build splashes Tidal Focus + Mindfulness for casters; I kept that and added Totemic Focus 2 to reach Water Shield (needs 10 Restoration points), which makes the split 40/0/11. Not taken: Elemental Devastation (melee crit), Earthbound, Elemental Reach (dropped to fit 51). Order is my own: damage and cast speed first (Concussion, Alacrity), mana next (Convection, Focus), Overload before the Restoration splash, Fury and Mastery once their rows open.
Beta overruled by game data: guides mention Lava Burst, Improved Fire Nova Totem and Lightning Mastery rank 3; none exist in this tree (Lightning Mastery is 1 rank, no Lava Burst talent, Trial by Fire instead). Rank values follow the tooltips.

### Restoration (10 Elemental / 0 Enhancement / 41 Restoration)
URLs used:
- https://www.rankedboost.com/world-of-warcraft/forever/build/shaman/ : healing build 41 Resto / 10 Enhancement (Riptide, Purification, IHW, Healing Way, Tidal Mastery, Restorative Totems, Ancestral Knowledge 5, Thundering Strikes 5). Not a leveling build, no order.
- https://wow.gg/guides/wow-forever-restoration-shaman (2026-11-04): talent code only, stat priority healing power first.
- https://www.warcrafttavern.com/forever/guides/shaman-leveling/ : Water Shield 20, Mana Tide 25, Nature's Swiftness 30 as unlock points.
- https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide (403; snippet): beta level-30 build puts the level 30 point into Nature's Swiftness.
- https://www.icy-veins.com/wow-forever/restoration-shaman-leveling (403, not read).
Disagreements and choices: rankedboost splashes Enhancement (Ancestral Knowledge, Thundering Strikes). I chose Elemental instead (Concussion 5, Alacrity 3, Convection 2) because Lightning Bolt is what you quest with as a healer; Concussion/Alacrity need no Resto points. Skipped: Improved Reincarnation, Natural Grace, Ancestral Healing, and 2 of the 5 Totemic Focus ranks (3 taken). Order: Tidal Focus and Mindfulness early (hit and regen), Water Shield as soon as 10 Resto points exist (level 28), then healing power for dungeons (IHW, Tidal Mastery, Mana Tide, Healing Way, Nature's Swiftness, Purification, Riptide at 49).
Beta overruled by game data: Riptide is here (needs Healing Way, 30 points in the tree) and Natural Grace is a threat talent, not the old cast-time one.

### Online Enhancement guides vs the shipped plan
Shipped (review SHAMAN): Thundering Strikes 5, Mental Dexterity 3, Ancestral Knowledge 2 then 1, Shamanistic Focus, Elemental Weapons 3, Stormstrike (25), Flurry 5 ... Maelstrom Weapon 5 (35-39), etc.
- Rankedboost leveling build (updated 2026-11-08): Enhancement 43 / Resto 8, taking Ancestral Knowledge 4, Mental Dexterity 3, Elemental Weapons 3, Toughness 5, Anticipation 3, Spirit Weapons, Improved Stormstrike 2, Mental Quickness 2, Thundering Strikes 5, Flurry 5, Shamanistic Focus, Maelstrom Weapon 5, Improved Ghost Wolf 2, plus Tidal Focus 5 and Mindfulness 3. Differences: it takes Toughness, Anticipation and Spirit Weapons (defence) and a Resto splash; the shipped plan has no Resto points and (per the review) Ancestral Knowledge at 3.
- Method (https://www.method.gg/wow-forever/wow-forever-shaman-leveling-guide-and-talents, updated 2026-11-14): Stormstrike at 25 and Improved Ghost Wolf 2/2 right after it. The shipped plan takes Stormstrike at 25; check whether Improved Ghost Wolf is in it (not shown in the part of the review I read).
- Warcraft Tavern: calls Enhancement the cleanest leveling path (fewer drink stops than Elemental).
Reporting only, no changes.

## Warlock

Split notation below: Affliction/Demonology/Destruction.

### Demonology (draft: 20/31/0, no respec)
- https://www.method.gg/wow-forever/wow-forever-warlock-leveling-guide-and-talents (page says updated 14 Nov 2026). Order: Suppression 4, Unholy Power 5, Fel Vitality, Demonic Energies 2, Master Summoner 2, Demonic Aegis/Embrace, Demonic Brand 3 from 29, Fel Domination, Demonic Knowledge 3, Demonic Sacrifice, Soul Link, Master Demonologist, Demonic Pact; then Improved Corruption 5, Suppression 5, Malevolence 5. No per-level numbers except a few.
- https://www.warcrafttavern.com/forever/guides/warlock-leveling/ (no date shown, November 2026 content). 31 Demo / 20 Aff: Unholy Power 5, Demonic Energies 2, Fel Vitality 3, Master Summoner 2, Improved Sayaad 3, Demonic Brand 3, Demonic Sacrifice, Soul Link, Demonic Knowledge 3, Demonic Embrace 1, Fel Domination, Master Demonologist 5, Demonic Pact at 40; then Aff: Improved Corruption 5, Improved Life Tap 2, Suppression 5, Improved Drains 3, Pandemic 3, Malevolence 2. It levels as Affliction to 27 and respecs; it says going straight into Demonology from 10 is fine.
- https://kami-labs.fr/en/wow-forever/build-demoniste-demonologie-wow-forever/ (14 Sep 2026): end-game build only, no leveling order; used just to confirm the new Demonology talents.
- Not readable (HTTP 403): icy-veins.com wow-forever demonology/destruction leveling pages, mobalytics.gg pages (Kargoz Demonology leveling guide). Search snippets only: Icy Veins lists a 34 Destruction / 11 Demonology / 6 Affliction leveling build; Kargoz calls Demonology one of the best 1-60 leveling specs.
- Choice: the final split matches Warcraft Tavern (31/20). I skipped the respec, so the order is Method's (Suppression 4 first) then Tavern's demo order, finishing the Affliction points (instant Corruption) from 45. Sayaad from Tavern (Method omits it; it helps the Succubus drain-tank). Method's Demonic Aegis dropped. Disagreement: Method puts Suppression 4 first and puts Improved Corruption late too; Tavern puts Improved Corruption first in its pre-respec Affliction build. I chose Method because the build never respecs.
- Game data overrules: none missing. All named talents exist; Demonic Embrace max 5 (only 1 used, as both sources say). Beta-era tooltip numbers were replaced by the Forever tree numbers.

### Destruction (draft: 15/3/33, no respec)
- Method (same URL): Suppression 4, Bane 5, Aftermath, Ruin 5 (4 by Conflagrate at 29, the 5th after), Agonizing Flames, Fire and Brimstone, Bane of Havoc, Cataclysm 1, Shadow and Flame, Cataclysm fill, Improved Life Tap, Improved Corruption, then Unholy Power 5 and Demonic Energies 2.
- Warcraft Tavern (same URL as above): 31 Destruction / 17 Aff / 3 Demo, no respec, aimed at dungeons: Bane 5, Cataclysm 3, Aftermath 5, Ruin 3, Shadowburn, Conflagrate (25), Agonizing Flames 3, Bane of Havoc, Fire and Brimstone 3, Shadow and Flame 5, Incinerate (40); then Suppression 5, Improved Life Tap 2, Improved Corruption 5, Improved Imp 3, Amplify Curse, Pandemic 3, Malevolence 1.
- Icy Veins (snippet only): Destruction is weak early (pushback, mana cost, little self-healing); suggests Affliction/Demonology, or Destruction from about level 40.
- Disagreements and choices: (1) Method starts with 4 Suppression; Tavern does not. I started with Bane (the cast speed matters most) and put Suppression at 45. (2) Tavern leaves Ruin at 3/5; both Method and the tree value Ruin, so I took 5/5 and moved Cataclysm mostly after Incinerate (1 point at 30 to open the row, 2 at 41). (3) I dropped Malevolence and Amplify Curse for the fire talents; kept Pandemic 3 and Improved Imp 3 from Tavern. (4) Kept Improved Life Tap at 43, a little earlier than Tavern, because both guides warn about Destruction mana. (5) Split is 33 Destruction (Tavern 31). Note: the build is slow for solo questing; guides call it best in dungeons.
- Game data overrules: the Method/Tavern text matches the tree (Incinerate needs Bane of Havoc and 30 points; Shadow and Flame is row 6). Shadowburn is level-gated as an ability in the guides, but the tree lets it be taken from 10 points in tree; I placed it at 29 after Agonizing Flames.

### Affliction: online guides against the shipped plan (report only, no changes)
- Method (14 Nov 2026): Suppression 4, Improved Corruption 5, Improved Life Tap 1, Pandemic, Fel Concentration, Nightfall 2, Malevolence 2, Soul Siphon, Malevolence 2 then Shadow Mastery 5, back up for Malevolence/Siphon Life/Improved Life Tap, Improved Drains 3; swap at 46 to Unholy Power 5, Demonic Energies 2, Fel Vitality 3; last 5 points back in Affliction (Improved Bane of Agony, Grim Reach, Suppression). Says drain tanking from 30.
- Shipped plan: Improved Corruption 10-14, Suppression 15-17, Improved Life Tap 18-19, Fel Concentration 20-22, Improved Drains 23-25, Nightfall 26-27, Pandemic 28-30, Siphon Life 31, Soul Siphon 32-34, Shadow Mastery 35-39, Wrack 40, Malevolence 41-45, Improved BoA 46-47, Suppression 48-49, Grim Reach 50, then Demonology 51-60 (Unholy Power 5, Demonic Energies 2, Fel Vitality 3).
- Differences: Method takes Suppression 4 at level 10 and Corruption second (shipped does the reverse and delays hit to 15); Method has no Siphon Life/Wrack (shipped takes both: Siphon Life 31, Wrack 40); Method defers Improved Drains to the end and shipped takes it at 23; Method switches to Demonology at 46 (shipped 51), and Method keeps Improved Bane of Agony and Grim Reach last (shipped takes them at 46-50). Both reach Shadow Mastery 5/5 and the Demonology finish. Wrack needs Siphon Life; shipped plan is valid under the tree.
