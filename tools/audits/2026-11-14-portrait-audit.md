# Step window portraits (2026-11-14)

Reported from the game: the Duskwood pickup Zombie Juice (158) showed Tavernkeep Smitts instead of
Abercrombie. QuestNPCData.lua was right (`start = 289`, Abercrombie).

## Cause

`SetCreature` on a creature the client hasn't loaded yet leaves the model it drew before on screen,
and `GetModelFileID` then reports that old model's file, so the portrait took it for loaded and never
waited, retried or fell back to the icon. Any step whose NPC you hadn't seen yet this session could
show the previous step's NPC.

## Code fixes

- QuestPortrait.lua: `ClearModel` before each new creature (the loaded check now waits for the right
  one); the NPC you're talking to (`npc` unit) or targeting is drawn from that unit at once.
- tools/questnpcs.py: `by = { ["NPC name"] = creature }` per quest when a route step names another
  NPC than quest database's first giver/finisher, from the quest's own giver/finisher list, else the one
  spawned NPC quest database knows by that name. The portrait uses the step's NPC first. 88 quests got one:
  class quests every trainer gives (The Islander, Cenarion Aid, Magecraft, Elemental Mastery, An
  Imp's Request, The Hunter's Charm, A Simple Request...), breadcrumbs with several givers (Report to
  Gryan Stoutmantle from Farmer Furlbrow, Good Luck Charm from Jeremiah Payson, Hides for the
  Forsaken from Shelene Rhobart...) and NPCs quest database doesn't link to the quest (Hex of Weakness from
  Tai'jin).

## Steps where the route and quest database name different NPCs (check in game)

No data changed for these. The portrait shows quest database's NPC; the step text names another. One of the
two is wrong for Forever:

| Route | Quest | Step names | quest database |
|---|---|---|---|
| Horde zephras | 92467 Call of Earth (accept) | Windshaper Boro | Aetheen of the Gales |
| Horde shendar | 97968 Camping 101: Herbalism (turn-in) | Halassa Fernbreeze | Syriel Nightrain |
| Horde camp-taurajo | 98093 Field to Clear | Sulhasa | creature 14242 (no name in quest database) |
| Alliance dunmorogh | 96608 The Great Outdoors (accept) | Eric Brighthammer | Senir Whitebeard |
| Alliance teldrassil | 940 Teldrassil (accept) | Oracle Tree Bark | Sentinel Arynia Cloudsbreak |
| Alliance valanaar | 92850 The Missing Scholar (turn-in) | Fillion Flamebreeze | Dondallion Whisperwind |
| Alliance valanaar | 94912 Child of Nature (accept) | Alfina Nightgaze | Archmage Ansirem Runeweaver |
| Alliance searing-50 | 3441-3454 Divine Retribution chain | Velarok Windblade | Kalaran Windblade |
| Alliance mage-research-access | 79093, 97286 (turn-ins) | Garion Wendell | Owen Thadd |
| Alliance shaman-fire-totem | 94449 Call of Fire (accept) | Ingrid Dunwald | Teo Hammerstorm |
| Alliance ungoro-53 | 1047 The New Frontier (accept) | Darnassus notice | Herald Moonstalker |

Naming differences only (same NPC, nothing to do): Remy "Two Times", "Auntie" Bernice Stonefield,
Sha'ni Proudtusk's Remains, UNUSED Grund Drokda (quest database's name), place names used as the step's
NPC (Sentry Point, Blackrock Mountain).

648 named accept/turn-in steps have no creature: objects (crates, wanted posters, books) show the
step icon, as do new Forever NPCs quest database has no record of yet.
