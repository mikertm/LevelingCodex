# Talent paths: a path per spec and your own

Date: 2026-11-14. From player requests passed on by the owner.

## What the owner asked, and what we agreed

| Request | Decision |
|---|---|
| Players want to make their own talent path | A Custom path per character, built on the Talents tab by clicking the real tree in level order, checked against the game's rules. |
| A recommended path for every spec of every class, even the ones that aren't the best for leveling | Each class gets a path for each of its three trees. The Codex guide's own plan (Data.lua) stays the default and is one of them. Druid: the guide's Feral plan is a cat/bear hybrid (7/39/5), so Druid keeps it and adds a dedicated Feral Cat (0/38/13), Feral Bear tank, Balance and Restoration. |
| Research the latest Forever talent guides (as of 2026-11-14) | One research pass per class over the published Forever guides (Method, Warcraft Tavern, Icy Veins, Mobalytics, wow.gg, Kami-Labs, RankedBoost, Maxroll/Wowhead through timesaver.gg). The game's own tree (`tools/reference/forever.json`) wins over any beta-era guide. Sources and choices go in `tools/audits/2026-11-14-talent-paths.md`. |
| Polish the Talents tab with these choices | Path cards at the top, the full game tree for all three trees side by side, the talent detail and every point in order, a custom editor. |
| It should save / remember | Saved per character. Forever may not load SavedVariables back, so a lost save falls back to the spec path that matches the talents you already spent, and a custom path has a share code to paste back. |
| Custom paths: per character or shared by the class? | Per character, with a share code to copy to another character (owner's pick). |

Scope: talents only. Macros, tips and the trainer list's other spells stay on the Codex guide's spec;
the trainer list follows the path for talent-taught spells (below). Macros per spec would be its own
project.

## Global constraints

- WoW: Forever client, `## Interface: 16001`, Lua 5.1; runtime text ASCII only; no new globals
  beyond `LevelingCodex*` frames (the new data lives on `ns`).
- Guard every non-core API (`C_Traits`, `C_ClassTalents`) with existence checks and `pcall`.
- Everything works with empty SavedVariables (`ns.settingsLost`) and on the minimal client.
- Keep the look: Codex cards, Morpheus headings, Forever teal; Blizzard pieces where they exist.
- Every clickable keeps a `codexLabel` so the harness and Forever's controller navigation find it.
- Harness passes (`python tests/run.py`); `blocked-report` fails only in worktrees.

## Data

### `TalentTreeData.lua` (generated)

`python tools/gamedata.py talentdata` writes it from `tools/reference/forever.json` (`--check` fails
when stale; `update` regenerates it). Shape:

```lua
ns.talentTrees.WARRIOR = {
  tabs = { "Arms", "Fury", "Protection" },
  talents = {
    { name = "Deflection", tab = 1, row = 1, col = 2, max = 5, req = 0, icon = "ability_parry",
      prereq = { "..." }, tip = "<tooltip at max rank, ASCII>", spell = { { 2, 48 }, { 3, 54 } } },
    ...
  },
}
```

- Talents sorted by tab, row, column; hidden talents (`classes[C].hidden`) left out.
- `prereq` = the game's list (any one maxed opens the talent), plus `requires` when present.
- `spell` = ranks 2 and up of the spell a talent teaches (`spells[name]` whose first rank has
  `talent = true`): `{ rank, level }`. Rank 1 comes with the talent point.
- Tooltips folded to ASCII by the generator (the runtime still sends them through `plain()`).
- Loaded after Data.lua; only the player's class is read at runtime.

### `TalentPaths.lua` (hand-written)

```lua
ns.TALENT_PATHS.WARRIOR = {
  { key = "guide", spec = "Protection", role = "Tank", note = "..." },       -- plan from Data.lua
  { key = "arms", spec = "Arms", role = "Melee damage", note = "...", plan = { ... } },
  { key = "fury", spec = "Fury", role = "Melee damage", note = "...", plan = { ... } },
}
```

- `plan` has Data.lua's plan shape (`name, tree, icon, max, from, to, why, more`), levels 10-60
  once each. Text is our own wording from the game tooltips, ASCII, `why` under 240 characters.
- `role` is one of Melee damage, Ranged damage, Caster damage, Tank, Healer; `note` one line,
  at most 90 characters.
- The `guide` entry carries no plan: it is Data.lua's.
- Every class covers each of its three trees with a path whose most points sit in that tree
  (Druid adds a Cat and a Bear path in Feral Combat).
- The researched splits at 60: Warrior Arms 32/19/0, Fury 10/41/0; Druid Balance 41/0/10,
  Cat 0/38/13, Bear 0/41/10, Restoration 11/0/40; Hunter Beast Mastery 32/14/5, Survival
  0/17/34; Mage Arcane 41/10/0, Fire 7/41/3; Paladin Holy 34/5/12, Protection 0/36/15; Priest
  Discipline 40/11/0, Holy 14/32/5; Rogue Assassination 38/8/5, Subtlety 15/5/31; Shaman
  Elemental 40/0/11, Restoration 10/0/41; Warlock Demonology 20/31/0, Destruction 15/3/33.

## Runtime: `Talents.lua` (after Guide.lua)

- `ns.talentPaths()`: the class's paths in order, the guide first, then Custom last
  (`{ key = "custom", spec = "Custom", custom = true }`).
- `ns.talentPathKey()` / `ns.setTalentPath(key)`: the chosen path, `charDB.talentPath`. Unknown or
  missing key: the fallback below, else `guide`. Setting it bumps `ns.talentVersion`.
- `ns.talentPlan()`: the chosen path's plan; for Custom, built from `charDB.customTalents` (a list
  of talent names, index 1 = level 10) into plan entries (consecutive points into one talent become
  one entry; `why` = the talent's tooltip, `more` = ""). Cached by `ns.talentVersion`.
- `ns.talentAt(level)` (Guide.lua) reads `ns.talentPlan()` instead of `ns.D.plan`. Every talent
  display already goes through it: This Level card and NEXT strip, level-up chat and banner, the
  minimap tooltip, the talent-window trace.
- Rules (`ns.talentCanAdd(points, name)` -> ok, reason): the talent exists, has ranks left, its
  tree has `req` points before it, and one prerequisite is maxed. Reasons are short ("Needs 15
  points in Arms (has 9)", "Needs Sweeping Strikes 1/1", "All 3 ranks taken", "All 51 points
  placed").
- Custom editing: `ns.customAdd(name)`, `ns.customUndo()`, `ns.customClear()`,
  `ns.customFrom(key)` (copy a path's points), `ns.customFromLive()` (your current talents in a
  valid order: by row, then the order they appear in the tree). Loading drops a saved list's tail
  from the first point that breaks a rule (a game patch).
- Share code: `ns.talentCode()` / `ns.readTalentCode(text)`:
  `LC1-<CLASS>-<check>-<runs>`, runs = pairs of (talent index, count) in base 36 against the
  sorted talent list, `check` = a short hash of the class's talent names, so a code from another
  tree version or class is refused with a reason instead of mapping to the wrong talents. Reading
  validates every point by the rules.
- Lost save: with no `charDB.talentPath`, `ns.talentPathKey()` reads your live ranks
  (`ns.traitRanks()` in TalentGuide.lua: lower(name) -> purchased rank from `C_Traits` nodes) and
  picks the spec path whose plan up to your spent points matches most of them (at least 60%); no
  ranks, or nothing matches: `guide`. The pick is not saved until you choose one yourself.
- Trainer: `ns.trainVisits()` = Data.lua's visits with ranks of talent spells your path never
  takes removed and ranks of talent spells it takes added (at the later of the rank's level and
  the level the path takes the talent; note "New rank of your <talent> talent.", the talent's
  icon), sorted by level; `spells`, `notes`, `icons` stay parallel. `ns.trainAt`, `ns.nextTrain`,
  the Trainer tab and TrainerGuide.lua read it. Cached by `ns.talentVersion`.

## The Talents tab (`TalentTab.lua`, after Window.lua)

Window.lua keeps the tab in its list and calls `ns.renderTalents(V)`; the tree drawing moves out of
Window.lua (`talentModel`, `layoutTree` go to TalentTab.lua and use `ns.ui`).

1. **Talent paths** heading, sub "Pick how you spend your points. Saved for this character."
2. **Path cards**, two per row (276 x 54): the path's first talent icon (Custom: a blank page
   icon), spec name, role, the split at 60 ("31 / 20 / 0") and a tag: "Codex guide" on the guide,
   "Chosen" on yours (gold edge). Click = choose (saved at once). Below the row: the chosen
   path's note, and for a path that isn't the guide: "Macros and tips follow the <spec> guide."
3. **The tree**: the three trees side by side (one column each, 184 px), tree name and the path's
   points in it at the viewed level. Every talent of the game tree at its row and column (36 px
   icons, 44 px rows): ranks the path has at level V; not in the path = desaturated; partial =
   green ring, maxed = gold; the point at V = accent glow and "NOW"; the next point "Lv N" under
   it. Prerequisite lines (2 px, gold when the prerequisite is maxed by V). The live layout from
   `ns.traitLayout()` is not needed any more: the generated rows and columns are the game's.
4. **Selected talent** (parchment): icon, name, tree, rank at V, the game tooltip at max rank,
   then every point the path puts into it with its level and why (as today).
5. **Every point, in order** (as today; click a level to open it). A custom path's unplanned
   levels show "Not planned yet".

### Custom editor (on the Talents tab while Custom is chosen)

- Above the tree: "Points placed: 34 of 51 - next point is level 44", buttons Edit / Done,
  Undo, Clear (two clicks within 5 s), Share code, Paste code.
- Empty custom path: a row "Start from:" with one button per spec path, "My current talents"
  (when the client can read them) and "Empty".
- Editing: the tree shows the custom path at level 60; a click on a talent adds the next point
  there when the rules allow; a talent you can't take now is dimmed, and its tooltip starts with
  the reason; the last point placed glows.
- Share code opens the copy box with the code selected; Paste code opens it editable with a
  "Use this code" button (the copy box gains a paste mode); a bad code says why and changes
  nothing.

## Elsewhere

- **Talent-window trace** (TalentGuide.lua): follows `ns.talentAt` as today; on a custom path
  with no point planned for the level, the hint card says "No point planned for level N. Plan it
  in /codex talents." and traces nothing.
- **Level-up chat and banner**: the same unplanned case says "talent point: plan it in /codex
  talents".
- **Minimap tooltip**: the chosen path's spec ("Arms Warrior - level 20").
- **Macros tab**: when the path isn't the guide's, a line "These macros are built for the
  <guide spec> guide."
- **`/codex debug`**: path key, how it was picked (saved / matched live talents / default),
  custom points placed.

## Testing

- `talent_path_checks()` in tests/run.py: every path through the same rules as the Data.lua plan
  audit (levels 10-60 once, names, trees, ranks, icons, row points, prerequisites), ASCII, `why`
  under 240, `note` under 90, roles, unique keys, every tree covered, the guide entry per class.
  `tools/gamedata.py audit` gains the same path audit.
- `TalentTreeData.lua` matches the reference (`talentdata --check`), shape check.
- Scenarios: `talentPathPick` (choose a spec path: This Level card, NEXT strip, level-up chat and
  banner, minimap tooltip, trace all follow it), `talentPathSaved` (persisted run keeps it),
  `talentPathLost` (lost SavedVariables + mocked trait ranks pick the matching path),
  `talentCustom` (start from a path, add, rule refusal with reason, undo, clear, unplanned level in
  chat and trace), `talentCode` (share code round trip, a bad code refused), `talentTrainerPath`
  (Arms: Shield Slam ranks gone, Mortal Strike ranks in), `padTalentPaths` (the controller reaches
  the cards and the editor buttons). The mock's `C_Traits.GetNodeInfo` gains `ranksPurchased`.
- Existing talent scenarios keep passing on the guide path (the default). `traitLayoutTree`
  becomes a check that nodes sit at the generated rows and columns (the tab no longer needs the
  live layout), and `talentTree` also checks talents the path never takes are drawn, greyed.

## Docs

CLAUDE.md (files table, module list, Data.lua shape), CHANGELOG section, the audit file with every
spec's sources, splits and decisions, and what the online guides say about each shipped guide plan
(report only: the guide plans don't change here).
