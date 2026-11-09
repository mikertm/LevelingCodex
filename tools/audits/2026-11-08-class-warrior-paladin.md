# Forever Alliance Warrior and Paladin class quests, levels 10-30

The 17 side guides in QuestClassData.lua cover Alliance Warrior stances and gear, and Paladin Redemption, Sense Undead and equipment. The Night Elf Elanaria referral (1684) moved from Teldrassil into the stance guide so the guide can start with an empty quest log.

## Evidence

- Checked every scripted quest ID against `tools/reference/forever.json` and the cached `QuestV2.csv` for client build `1.60.1.70862`. Used the cached Forever QuestieDB base and traces for levels, prerequisites, NPCs, objects and loot. Re-ran the Warrior/Paladin candidate scans from the brief's `scratchpad/wp` against that cache. QuestV2 confirms IDs in the client index. The quest giver's live offer and reward still need an in-game check. [Pinned QuestieDB Forever data](https://github.com/Questie/QuestieDB/tree/0f7d8adc92b28ac6594f4ad8745257f4d9784edf/data/Forever)
- Alliance Warriors can be Human, Dwarf, Gnome, Night Elf or High Order Skyborne. Alliance Paladins can be Human or Dwarf. Questie's broad Warrior mask `4294967373` includes all five, consistent with the playable bits in the cached `ChrRaces.csv`. The guides use the intended racial entry paths because the traditional stance branches are alternatives. Redemption uses race masks `1` (Human) and `4` (Dwarf), and the Valor/Test records use `5` (both). [Blizzard's race/class matrix](https://worldofwarcraft.blizzard.com/en-us/news/24304075/) and [Forever race and class table](https://www.method.gg/wow-forever/all-class-and-race-combinations-in-world-of-warcraft-forever)

## Warrior

| Level | Race | Coverage in order |
|---|---|---|
| 10 | Human | Defensive Stance: 1638, 1639, 1640, 1665. Haggard's weapon: 1666, 1667. |
| 10 | Dwarf and Gnome | Defensive Stance: 1679, 1678. Grey Iron Weapons: 1680, 1681, 1682. |
| 10 | Night Elf | Defensive Stance: 1684 then 1683. Weapons of Elunite: 1686, 1692, 1693. |
| 10 | Skyborne | Existing inline 94003 covers Defensive Stance. The level 2 trainer referral 92532 is already inline as well. |
| 20 | All five | Furen's Favor: 1698, 1699, 1702. Fire Hardened Hauberk: 1701, 1782. The shield can be collected before the Wetlands, Stonetalon and Razorfen Kraul materials trip. |
| 20 minimum, 28-30 suggested | Human/Gnome, Dwarf/Gnome, or Night Elf | Coif: 1700, 1705, 1706. Gauntlets: 1704, 1708, 1709. Leggings: 1703, 1710, 1711. Filters follow the cached race-specific referrals. |
| 30 | All five | Berserker Stance and Intercept: 1718, 1719. Wu Shen is the default waypoint. Kelv Sternhammer and Darnath Bladesinger are alternate pickups for the same quest ID. |

- The three traditional stance rewards also list Taunt and Sunder Armor. Skyborne have a distinct quest and shield reward. The Skyborne row now uses the published minimum level of 10. Check the offer on a character before and after level 10. [Bartleby's Mug](https://db.icy-veins.com/wow-forever/quests/1665), [Vejrek](https://db.icy-veins.com/wow-forever/quests/1678), [Vorlus Vilehoof](https://db.icy-veins.com/wow-forever/quests/1683), [The Skybreaker Bulwark](https://bindonforever.com/quest/94003)
- The Fire Hardened gear guides cover the recorded referrals. Direct access to other armor smiths after completing the hauberk has been reported, but the cached referral masks lack a Skyborne branch and only cover the races shown in the table. Verify the live referral offers before adding cross-race or Skyborne branches. [Forever Warrior class quest guide](https://www.icy-veins.com/wow-forever/warrior-class-quests), [Fire Hardened Mail](https://db.icy-veins.com/wow-forever/quests/1701), [Alternate armor access report](https://worstguidesever.com/wow-forever-warrior-class-quests/)
- Bind on Forever's route hint includes The Windwatcher in the stance unlock. The Affray's reward table grants Berserker Stance and Intercept on 1719, and 1791 describes the stance as already learned. Whirlwind Weapon opens with 1791 at 30 but continues through level 40 quests 1712, 1713 and 1792. It is outside this route pass. Its reported reagent exchange 1714 is also absent from the cached QuestV2 index. [The Affray](https://db.icy-veins.com/wow-forever/quests/1719), [Bind on Forever route hint](https://bindonforever.com/quest/1719), [The Windwatcher](https://db.icy-veins.com/wow-forever/quests/1791)

## Paladin

| Minimum | Race | Coverage in order |
|---|---|---|
| 12 | Human | Redemption: 1642, 1643, 1644, 1780, 1781, 1786, 1787, 1788. |
| 12 | Dwarf | Redemption: 1646, 1647, 1648, 1778, 1779, 1783, 1784, 1785. |
| 20 | Human and Dwarf | Sense Undead and Bastion of Stormwind: 1649, 1650, 1651, 1652. |
| 20, with a group advised | Human and Dwarf | Verigan's Fist: 1653, 1654, 1806. All four materials are described in 1654. |
| 22 | Human and Dwarf | Cloak of the Divine Storm: 78088, 78089, 78090, 78091, 78092, 78093. Level 30 quests with a minimum of 22. |

- **Redemption entry.** The tracked chains start with the race-specific Tome of Divinity items (6775 and 6916). The cached prerequisite links point to book errands 1641 and 1645, which public records still describe but the 70862 QuestV2 index omits. The pickup text covers asking the NPC for the book and taking the errand if offered. The optional referral IDs 2998/3681 (Human) and 2997/2999/3000 (Dwarf) exist but go to the same city NPCs and are omitted from the direct paths. The Symbol of Life button uses item 6866 in both branches. [Human chain](https://questing.wiki/wow-forever/quests/1642/), [Dwarf chain](https://questing.wiki/wow-forever/quests/1646/), [Human book errand](https://db.icy-veins.com/wow-forever/quests/1641), [Dwarf book errand](https://db.icy-veins.com/wow-forever/quests/1645)
- **Tome of Valor and Verigan.** Book-giving IDs 1793/1794 and material errands 1655 (Bailor) and 1442 (Thundris) are absent from the 70862 client index. Public Forever quest records and the published beta route still describe them. The route explains book acquisition and both errands in prose and scripts only the indexed quests. The mace (item 6953) is in the cached client item table and listed as the 1806 reward. Live availability of the book handoff and both material errands remains unverified. Sense Undead ends in its own section at 1652, so the missing errand flags cannot block its turn-in. [Tome of Valor](https://www.wowhead.com/forever/quest%3D1649/the-tome-of-valor), [Sense Undead reward](https://www.wowhead.com/forever/quest%3D1652/the-tome-of-valor), [Material route](https://forg.gg/en/forever/tips/verigans-fist), [Verigan's Fist reward](https://db.icy-veins.com/wow-forever/quests/1806)
- **Cloak.** The cached traces supply the orb, Delgren, salt and motes steps. Public Forever records fill the two gaps in the trace cache (78090 and 78093) and the spear interaction. For the two Stormwind NPCs, the guide uses the cached Forever map coordinates, which differ from the older coordinate system in Wowhead's beta article. [Beta route and spear event](https://www.wowhead.com/ptr/news/new-paladin-exclusive-cloak-currently-alliance-only-383286), [Forever Stormwind waypoints](https://forever-xp.com/quests/78090/), [Cloak reward and minimum level](https://db.icy-veins.com/wow-forever/quests/78093)
- **Scope exclusions.** 96139, The Valor Family, is already in Duskwood. Questie's Forever correction marks it Alliance-wide, and its objectives are unrelated to Daphne's defense. The 94427-era A Lesson in Divinity line belongs to Forsaken Paladins. The 94773-94777 Divine Grace records use Priest trainers. Alliance mount quests start after level 30. [The Valor Family](https://bindonforever.com/quest/96139), [Forsaken Redemption reward](https://www.wowhead.com/forever/quest%3D94441/a-lesson-in-divinity), [Divine Grace](https://bindonforever.com/quest/94773)

## Verification and live checks

- Loaded a temporary copy of `QuestData.lua` and `QuestClassData.lua` with the snippet appended under Lua 5.1. The combined route audit passed with 1,436 steps and the seven baseline warnings. The full harness passed before the final Affray text update. A separate check on the final snippet confirmed printable ASCII, unique quest IDs, one accept and turn-in per quest, class/race masks and the available cached levels. Nine mocked race/class profiles passed, including return to the same leveling step after The Affray for all five Warrior races.
- The later integrated workspace snapshot passed the route audit at 1,746 steps and the quest harness in a temporary copy. Its five additional route warnings are in the Mage wand section.
- In game, check the Kharanos referral for Gnomes, the existing Skyborne quest's real level gate, and the Night Elf handoff from the Elanaria referral. Check spell rewards and the return to leveling on the final stance turn-in.
- Check both Redemption book offers, the use-item button on the tomes and Symbol of Life, and the two final Redemption turn-ins. For Verigan, verify the Tome of Valor offer plus Bailor's and Thundris's errands before routing the group to the dungeons. For the cloak, check that the Shattered Orb appears after the spear turn-in.
