# Herbalism 1-300 and learned profession guides

Date 2026-11-08. Client reference build `1.60.1.70862` (`wowf`). Base `main` at `0657aa2`.

## Goals

Give Herbalists a continuous gathering route from 1 to 300 inside the Codex, with skill requirements, zones for both factions, Zephras Isle for Skyborne, and the same training and skill-up cues as Mining. Make the Professions tab reflect the character's learned skills. Keep the parchment layout and existing controller navigation.

## Decisions from brainstorming

- The switch lists only supported professions the game has confirmed the character learned. When the game confirms there are none, show an empty state and list the supported guides in plain text.
- A collapsed Skills heading can hide a learned profession. Keep professions confirmed earlier in this session visible. When a heading could hide a profession the Codex has never seen, prompt the player to expand Skills and wait for a confirmed reading.
- Update the tab when a character learns a profession, including while it is open. Keep a still-learned selection and otherwise pick the first learned guide in `PROF_ORDER`. The same eligibility check applies to banner shortcuts and stale selections.
- Keep level-up training reminders limited to learned skills. Keep every supported profession in `/codex debug`.
- Share Mining's gathering display and notifications. Show Herbalism's camp items in the existing camp section. The route uses gathering throughout.

## Approaches

- **Shared gathering path, chosen.** Give Herbalism its own node and step data. The existing renderer and card generator use that data or Mining's veins. The new labels, thresholds and node lists come from the chosen guide.
- **Separate Herbalism renderer.** This keeps the layouts independent but duplicates the step view, route selection, zones, training and controller work. Herbalism fits the existing layout.
- **Filter the switch only when opening it.** This would be simpler but would leave an open tab stale after learning or unlearning. The existing skill checks can notify the Professions tab as its data changes.

## Learned profession behavior

The existing guarded readers provide the source of truth. A positive rank from `GetProfessions` / `GetProfessionInfo` or the classic Skills list confirms a profession. Distinguish an observed absence from an unreadable list. A successfully read, complete profession list can establish absence even if a heading in the fallback list is collapsed. With the classic reader alone, an open, successfully read list can clear an unlearned skill. A collapsed heading keeps the last confirmed rank and cap for this session. If neither reader can give a reading and there is no known collapsed heading, show the unavailable state for the affected skills. Those guides are hidden until the next confirmed reading. Keep the last selection as a preference through a temporary failure, so it can return when confirmed again.

The renderer builds its switch and selects its guide from the same skill snapshot. Show the active guide and its rank when confirmed. The collapsed-list hint can sit above confirmed guides if other skills are still unknown. With no confirmed guide and uncertainty, use the hint or unavailable message with the plain-text list. The no-guides case still has its existing message.

Compare the visible state through the existing profession skill events and polling fallback. Refresh only a visible Professions tab when the relevant reading changes. Use the normal window refresh so scroll and controller focus follow existing rules. A route preview still clears when the skill changes. Refresh works with the skill-up cards disabled and while no profession is selected. Players expand Skills and train through the game's usual controls.

## Herbalism in the tab and cards

Add Herbalism to `ProfessionData.lua` and append it to `PROF_ORDER`. Keep Mining's existing `veins` and `smelt` data. Herbalism has an `herbs` catalog for the standard gatherable nodes through Black Lotus, including off-route nodes such as Grave Moss, Blindweed and Icecap. Each route step names the smaller set of herbs to show. All catalog nodes can trigger an unlock card. Use the existing faction and race rules in `profZones`. A locked herb can appear in a step with its minimum skill and the red difficulty label. The route must always have at least one available herb that can give a skill point through the next handoff. A completed route calls out Black Lotus at 300.

Store explicit color cutoffs for herbs. The two skill-1 plants turn yellow at 25 and green at 50, and the two Forever references disagree about Dreamfoil's early color cutoffs. Keep Mining's existing color behavior. Use `NEW HERB` for Herbalism unlocks and the current title and training rows for each crossed step or tier. Skill-up banners open the Herbalism guide.

The camp section covers Incense Candle (20), Greenhouse (140) and Seed Hybridizer (300). Show the unlock source and what each does using the existing camp format. Keep craft estimates, shopping lists and crafting-window traces scoped to the guides that already use them. The existing Find Herbs behavior is sufficient for tracking.

## Route and research

| Skill | Gathering focus | Suggested zones |
| --- | --- | --- |
| 1-70 | Peacebloom, Silverleaf, then Earthroot at 15 | Alliance starting zones, Horde starting zones, or Zephras Isle for Skyborne |
| 70-115 | Mageroyal, Briarthorn, then Stranglekelp at 85 and Bruiseweed at 100 | Darkshore, Loch Modan, Silverpine Forest |
| 115-170 | Bruiseweed and Wild Steelbloom, then Kingsblood at 125 and Liferoot at 150 | Wetlands, Hillsbrad Foothills, Stonetalon Mountains |
| 170-205 | Fadeleaf, Goldthorn and earlier herbs, then Khadgar's Whisker at 185 | Stranglethorn Vale and Arathi Highlands, filtered per herb |
| 205-230 | Firebloom and Purple Lotus at 210, with Wintersbite as an Alterac option | Tanaris, Searing Gorge, Alterac Mountains, filtered per herb |
| 230-270 | Sungrass, Ghost Mushroom at 245, and Golden Sansam at 260 | The Hinterlands, with alternatives from the named node records |
| 270-300 | Dreamfoil, Mountain Silversage at 280, and Plaguebloom at 285 | Eastern Plaguelands and other zones confirmed per node |

These are route bands, with individual rows and travel advice based on the herb object records. For example, Peacebloom's object record confirms the starter zones and Zephras Isle, while Dreamfoil's record supports Eastern Plaguelands and Un'Goro Crater. Prefer zones with several useful herbs. Verify every zone name against the client AreaTable, including Zephras Isle and Riverglades. Recommend Riverglades only if the node evidence supports it.

Train at skill 1, 50, 125 and 200 for caps 75, 150, 225 and 300. The listed trainer spells lack character-level requirements in the client, and the Forever trainer guide reports none. Use proven trainer examples for both factions. Wowhead's taught-by lists place Syriel Nightrain and Halassa Fernbreeze on Zephras Isle for Apprentice and Journeyman only. Icy Veins lists them for later ranks as well, so the guide directs players to mainland trainers after Journeyman and records the discrepancy for a live check.

The client confirms Herbalism skill line 182, item names and IDs, gathering lock skill thresholds and camp recipe records. `GameObjects` omits named herb entries in this build. Map the named nodes using Forever's records and cite that mapping as external evidence. Item existence and the lock's skill can be checked offline. Node-to-lock mappings without a client object, colors and spawn locations need source attribution. Where colors differ, use the earlier cutoff for route planning and keep the disputed values in the audit. Seeds and scarce materials are separate from known gathering nodes. Keep unconfirmed sources for Marefoil, Demonsage and Death Lotus off the leveling route.

Add Herbalism to the gamedata profession list and extend its reference build, diff and audit to check the herbalism facts it can reproduce. Use `SkillLine`, `Lock`, `GameObjects`, `ItemSparse`, item icons and `AreaTable` as applicable. Keep client evidence distinct from the guide's server-side facts. Extend the offline checks for shape, herb/item evidence, skill thresholds, ordered cutoffs, the contiguous route and available herbs at each handoff. Write an audit under `tools/audits/` with per-node and per-camp sources, tier evidence, conflicts and live checks.

### Sources

- [Wowhead Forever skill page](https://www.wowhead.com/forever/skill=182/herbalism) and [Herbalism overview](https://www.wowhead.com/forever/guide/professions/herbalism/overview-leveling). The supplied profession-leveling URL returned Page Not Found. The overview carries the early route and herb table.
- Wowhead Forever taught-by lists for [Apprentice](https://www.wowhead.com/forever/spell=2366), [Journeyman](https://www.wowhead.com/forever/spell=2368), [Expert](https://www.wowhead.com/forever/spell=3570) and [Artisan](https://www.wowhead.com/forever/spell=11993).
- Example node records [Peacebloom](https://www.wowhead.com/forever/object=1618/peacebloom) and [Dreamfoil](https://www.wowhead.com/forever/object=176584/dreamfoil).
- Cross-checks from [WoW-Professions route](https://www.wow-professions.com/forever/herbalism-leveling-guide) and [trainers](https://www.wow-professions.com/forever/herbalism-trainers), [Icy Veins leveling route](https://www.icy-veins.com/wow-forever/herbalism-leveling-guide) and [node table](https://www.icy-veins.com/wow-forever/herbalism), and [wow.gg](https://wow.gg/professions/forever/herbalism).

## Verification

Write failing harness scenarios first. Cover a single learned guide, multiple learned guides, the empty and unreadable states, a collapsed list before and after the first confirmation, an API failure and recovery, a complete reader with a collapsed fallback, a profession learned or removed while the tab is open, a selected guide removed, banner navigation, and full and minimal clients. Cover Herbalism's first route band and skill thresholds, faction and Skyborne zones, tier and node cards, camp rows, and reaching 300. Retain the existing Mining and crafting scenarios. Run the full harness before each commit and after the final review fixes.

After the harness passes, install with `python tools/install.py` and verify the copies. Use `/reload` to load the installed build. Check in game that a newly trained Herbalism guide appears in the switch, that closing and opening Skills behaves as described, that Find Herbs and the first node and training cards work, and that the recommended Skyborne trainers, disputed thresholds and camp unlocks match the live realm.
