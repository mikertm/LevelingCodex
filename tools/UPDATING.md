# Keeping the guides in step with the game

WoW: Forever changes talents, ranks and spell levels in patches and hotfixes. This is the routine
for finding out what changed and bringing `Data.lua` (and the guide pages it comes from) up to date.

To have Claude do it, ask: **"Run the Forever game-data update (tools/UPDATING.md)."**

## Where the facts come from

| Source | What it gives | How |
|---|---|---|
| The game client's own tables, via [wago.tools](https://wago.tools) (product `wowf`) | Talent trees (tab, row, column, ranks, points needed, prerequisites, tooltip per rank), class and pet spells with rank, level, cost, cooldown, tooltip | `python tools/gamedata.py update` |
| Blizzard's notes: [news.blizzard.com](https://news.blizzard.com/en-us/world-of-warcraft) ("WoW: Forever Hotfixes", "Development Notes") | Server-side changes the client tables don't show (tuning, bug fixes, trainer changes) | Read by hand |
| [WCLBox patch notes feed](https://wowforever.wclbox.com/en/buding) | Every hotfix, client build and developer post in one list, including announced changes that aren't live yet | Read by hand |

`tools/reference/forever.json` is the client data boiled down per class. It is committed, so
`git diff tools/reference/forever.json` after an update is the exact list of game changes, and the
test harness checks `Data.lua` against it without going online.

## The routine

1. **Fetch and compare.**
   ```
   python tools/gamedata.py update
   ```
   Downloads the newest Forever build's tables (cached in `tools/.cache/`), rewrites
   `tools/reference/forever.json`, prints what changed since the last reference (talents added,
   removed or moved, rank counts, points needed, tooltips, spell levels and ranks) and audits
   `Data.lua` against the new build. The daily **Game data** GitHub workflow does the same and
   opens a pull request with the report when a new build appears.

2. **Read the notes.** Blizzard's hotfix and development notes since the last update, class sections.
   Write down anything that touches a guide: a talent or spell that works differently, a changed
   level, a removed ability.

3. **Fix each class, alphabetically** (Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock,
   Warrior). For every class the diff, the audit or the notes mention:
   ```
   python tools/gamedata.py packet DRUID > druid.txt
   ```
   The packet puts every guide line next to what the game says: the talent plan beside each
   talent's real tooltip at the ranks taken, the full tree, each trainer visit, each macro with its
   spells' levels, costs and cooldowns, and the tip chapters. Check and fix in `Data.lua`:
   - **Talent plan**: still one point per level 10-60, every point legal (enough points in the tab,
     prerequisites maxed first), each `why` / `more` matches the tooltip. If a talent was removed
     or moved out of reach, pick the closest replacement and say why in its `why`.
   - **Trainer**: new abilities and new ranks at the right levels, notes still true.
   - **Macros**: every spell learned by the macro's first level (a `/castsequence` stalls on an
     unlearned step), under 255 characters, tips still true.
   - **Tips**: levels in brackets like "Swipe (16)" and the rotation advice.

   Smaller tools: `tree CLASS`, `review CLASS`, `spells CLASS "Name"`, `audit -k CLASS -v`.

   **Professions** (`ProfessionData.lua`): the diff lists recipes added or removed and changed
   colours or reagents under BLACKSMITHING / MINING, and `update` (and the daily pull request) audits
   ProfessionData.lua with the classes. Run `python tools/gamedata.py profs` for the
   route next to the game and `recipes PROFESSION "Name"` for one recipe; copy changed `yellow`,
   `grey`, `mats` and `icon` into the step, and if a recipe now goes grey before its step ends, move
   the step's range or pick another recipe (keep 1-300 without gaps). Learn levels aren't in the
   client: the owner's `/codex debug` after visiting a trainer lists any that differ. A warning that
   the game has several recipes with a step's name (`clashes` in the reference) means the reference
   kept the lowest spell ID: check with `recipes PROFESSION "Name"` that it's the one trainers teach.

4. **Test.** `python tests/run.py` must pass: it fails on anything the game won't allow
   (a talent not in the tree, a point before its row opens, a cast sequence step not learned yet,
   a rank that doesn't exist) and lists likely mistakes as warnings.

5. **Record and mirror.** Write every `Data.lua` change, with its reason and before/after, to
   `tools/audits/<date>.md` (see `2026-11-07.md`), then carry each one into the class's page in the
   guide project ("Feral Druid Leveling", "Prot Warrior Leveling", ...) so the next generated
   `Data.lua` keeps it. Add a `CHANGELOG.md` section listing the changes per class.

6. **Check in game.** `python tools/install.py`, then `/reload` in game: open `/codex`, browse the
   changed levels, open the talent window with a point to spend, run Set up macros.

7. **Commit** `Data.lua`, `tools/reference/forever.json` and `CHANGELOG.md` together. Releasing
   (pushing a `v*` tag) waits for the owner's go-ahead.

## What the client data can't tell

- Spells learned from quests or books rather than a trainer look the same as trainer spells; the
  guide's notes say which.
- Trainer gold costs, and tuning applied only on the server (hotfixes) until a client build
  carries it.
- Tooltips are rendered by `tools/gamedata.py`, not the game: plain numbers are exact, but a
  leftover `$x`, `{...}` or an odd sign is a token it couldn't work out. Check those in game.
