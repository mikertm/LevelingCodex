# Horde dungeon checklists (13-38)

The six Horde dungeon detours in `QuestHordeDungeons.lua`, replacing the placeholders. Each keeps its fixed ID and
instance ID. Quest facts (IDs, givers, finishers, levels, prerequisites, item starters, NPC and spawn positions) come
from `tools/questfacts.py` (QuestieDB Forever 0f7d8ad) and the client reference; every ID is in `quests.ids`.
RestedXP gave the grouping and order only; all step text is our own. Boss lists and tips are the Alliance
checklists' own text (`QuestDungeonData.lua`), reused for the same dungeons.

Every section is self-contained for the route audit: each turn-in has its accept earlier in the same section and
each prerequisite is turned in before its follow-up is accepted. Quest metadata is only defined when no earlier
Horde file has it (`q` fills gaps), and `add()` strips any `optional`/`dungeon` tag a shared step might carry.
All sections are `verified = false`.

## Sections

| ID | Levels | Steps (prepare / inside / after) | RestedXP chapters |
|---|---|---|---|
| `dungeon-ragefire-chasm` | 13-18 (unchanged) | 33 (15 / 7 / 11) | Skyborne "101 Ragefire Chasm"; Barrens dungeon guide "16-17 Ragefire Chasm" |
| `dungeon-ruins-of-lordaeron` | 17-22 (was 15-20) | 34 (8 / 7 / 19) | Skyborne "102 Ruins of Lordaeron"; Barrens dungeon guide "17-18 Ruins of Lordaeron" |
| `dungeon-wailing-caverns` | 17-25 (unchanged) | 51 (31 / 7 / 13) | Skyborne "103 Wailing Caverns"; Barrens dungeon guide "21-22 Wailing Caverns" and "18-21 The Barrens" (Raptor Horns) |
| `dungeon-shadowfang-keep` | 22-30 (unchanged) | 13 (5 / 5 / 3) | Skyborne "104. Shadowfang Keep", "24-25 Shadowfang Keep" |
| `dungeon-blackfathom-deeps` | 25-32 (was 24-32) | 22 (10 / 6 / 6) | Skyborne "105 Blackfathom Deeps", "28-29 Blackfathom Deeps" |
| `dungeon-razorfen-kraul` | 30-38 (was 29-38) | 22 (8 / 7 / 7) | Skyborne "106 Razorfen Kraul", "30-31 Razorfen Kraul" |

Level changes: Ruins of Lordaeron's Horde quests are level 21-22 (minimum 15-16) and RestedXP runs it at 17-18;
Blackfathom's Baron Aquanis is level 30; Going, Going, Guano! needs level 30.

## Ragefire Chasm

Pickups: Rahauro (Thunder Bluff, Elder Rise) 5722 Searching for the Lost Satchel and 5723 Testing an Enemy's
Strength; Thrall 5726 Hidden Enemies (Lieutenant's Insignia from the Burning Blade at Skull Rock, Durotar 53.1, 9.2);
zeppelin to Tirisfal for Varimathras's 5725 The Power to Destroy...; back to Thrall (5726 -> 5727), Neeru Fireblade
5761 Slaying the Beast and the 5727 conversation, Thrall 5728. Inside: troggs and shamans, Maur Grimtotem's body
(5722 turn-in, 5724 Returning the Lost Satchel), Searing Blade books, Taragaman's heart, Bazzalan and Jergosh.
After: Neeru, Thrall 5728 -> 5729 (Neeru) -> 5730 (Thrall), zeppelin to Varimathras, Rahauro.

- Dropped: Burning Shadows (832, Gazz'uz's item) and RestedXP's training, first-aid and rogue/warlock/priest steps.
- Hearthstone binding replaced by plain zeppelin legs, so no bind name has to be guessed.
- Check in game: where Maur Grimtotem's body lies (marked `uncertain`).

Sources: questing.wiki/wow-forever/dungeons/ragefire-chasm/quests (all five quests Horde in Forever; Slaying the Beast
has no prerequisite in the Forever record).

## Ruins of Lordaeron (Forever dungeon)

Horde quests (all Forever): Deathguard Kristof (Brill) 92422 The Wrath of Rath'mael; Theodore Griffs 95216 The New
Plague; Morbin Lightbane 92421 Light's Justice (25 Intact Limbs); Tabitha Heartweaver (Sepulcher) 92401 A
Frightened Request (find Edward Heartweaver by Rath'mael); item starts Crest of Lordaeron 95204 (item 275521, to Oran
Snakewrithe) and Unending Torment 97288 (Abominable Head 280438 from The Baron) -> 97289 (Othmar's body) -> 97290 ->
97291 (Toxic Skullcap from Tawny Grisette, Blisterweed by the herbalism trainer, Essence of Agony from Ezekiel Graves:
three `objectiveIndex` parts) -> 97292 (Hissing Serum 281327 upstairs, 45.3, 63.9).

- The 97289-97292 chain is given prerequisites in order (QuestieDB has none for these Forever quests; each is offered
  by the previous turn-in NPC per RestedXP).
- Alliance-only quests (95250, 95195, 92415, 95161, 95189) stay in the Alliance checklist.
- Check in game: whether the 97291 ingredients are handed over or must be bought (marked `uncertain`); crest spawn spots.

Sources: questing.wiki/wow-forever/dungeons/ruins-of-lordaeron/quests, wowforeverinfo.com/guides/ruins-of-lordaeron.

## Wailing Caverns

Prepare follows RestedXP's 103 chapter: Tonga Runetotem's chain 870 The Forgotten Pools -> 877 The Stagnant Oasis ->
880 Altered Beings -> 1489 Hamuul Runetotem -> 1490 Nara Wildmane -> 914 Leaders of the Fang, Apothecary Zamah 962
Serpentbloom, Ratchet's 1491 Smart Drinks and 959 Trouble at the Docks, Nalpak 1486 and Ebru 1487 above the cave.
Smart Drinks needs Raptor Horns (865) turned in first, so the checklist includes it (Sunscale Scytheclaws at 52.0,
46.5, by the Stagnant Oasis, where RestedXP's Barrens chapter kills them). After: Glowing Shard 6981 (Sputtervalve,
then Falla Sagewind) -> 3369 In Nightmares to Hamuul.

- Mad Magglish (45.7, 33.6) and Serpentbloom (47.5, 33.4) positions from QuestieDB spawns.
- Audit warnings kept: The Glowing Shard (26) and In Nightmares (25) are above the 17 start; both start from
  Mutanus's drop at the end of the run.
- Note for the Alliance file: its Raptor Horns objective points at 43.36, 15.57, but QuestieDB puts Sunscale
  Scytheclaws at 56.2, 52.7 / 52.7, 47.2 / 46.6, 45.1. The Alliance audit warns on the 2435 yd jump there.

Sources: questing.wiki/wow-forever/dungeons/wailing-caverns/quests (Leaders of the Fang Horde, minimum 10-15 in
different lists; Serpentbloom Horde).

## Shadowfang Keep

Keeper Bel'dugur 1013 The Book of Ur (Undercity), High Executor Hadrec 1098 Deathstalkers in Shadowfang (turned in
to Deathstalker Vincent inside), Dalar Dawnweaver 1014 Arugal Must Die. RestedXP also lists a second 1098 turn-in to
Hadrec; QuestieDB's finisher is Vincent only, so it is left out.

- Left for a class pass: The Orb of Soran'ruk (1740, Warlock, Doan Karhan in the Barrens; fragments from BFD and SFK).
- Check in game: the Book of Ur shelf (Classic data puts it in Fenrus's round room).

Sources: questing.wiki/wow-forever/dungeons/shadowfang-keep/quests, zockify.com/forever/dungeons/shadowfang-keep.

## Blackfathom Deeps

Tsunaman (Sun Rock Retreat) 6562 Trouble in the Deeps -> Je'neu Sancrea (Zoram'gar) 6563 The Essence of Aku'Mai and
6921 Amongst the Ruins. The Damp Note (16790) drops from Blackfathom Tide Priestesses outside the instance (Ashenvale
13.3, 12.6), so 6564 is turned in and 6565 (Lorgus Jett) taken before the run, as RestedXP does. Sapphires of
Aku'Mai are on the outer tunnel walls (13.4, 12.9). Inside: Argent Guard Thaelrid 6561 Blackfathom Villainy (to
Bashana Runetotem, Thunder Bluff), Lorgus Jett, the Fathom Core, Baron Aquanis's Strange Water Globe 6922, Kelris.

- Added a Baron Aquanis entry to the boss list (Horde-only summon at the Fathom Stone), with a generic tip.
- Forever data conflict: questing.wiki says the globe quest is 909 with minimum 25; QuestieDB and RestedXP use 6922
  (minimum 21). Both IDs exist in the client. The step uses 6922 and is marked `uncertain`.
- Je'neu of the Earthen Ring (824) belongs to the Ashenvale route and is not needed here.

Sources: questing.wiki/wow-forever/dungeons/blackfathom-deeps/quests, warcrafttavern.com/forever/guides/blackfathom-deeps.

## Razorfen Kraul

Master Apothecary Faranell 1109 Going, Going, Guano! (needs 30), Auld Stonespire 1102 A Vengeful Fate, Mebok
Mizzyrix 1221 Blueleaf Tubers (crate, stick and manual beside him). Inside: guano from Kraul Bats, tubers, Charlga's
heart, the Small Scroll (17008) starting 6522 An Unholy Alliance (to Varimathras), Willix the Importer 1144.

- Not followed: Hearts of Zeal (1113, Scarlet Monastery) and An Unholy Alliance's follow-up 6521 (Razorfen Downs).
- Alliance-only Mortality Wanes (1142) and The Crone of the Kraul (1100/1101) left out.
- Audit warning kept: An Unholy Alliance (36) is a drop from the last boss.

Sources: questing.wiki/wow-forever/dungeons/razorfen-kraul/quests.

## To check in game

- Every section: pickup NPC positions and the travel legs (zeppelin tower in Tirisfal at 60.7, 58.8 is approximate).
- Ragefire: Maur Grimtotem's body. Ruins: 97291 ingredients, crest spots. Shadowfang: Book of Ur shelf, Deathstalker
  Vincent's spot. Blackfathom: 6922 vs 909. Razorfen Kraul: Willix's minimum level.
