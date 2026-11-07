# Leveling Codex: notes for Claude

An in-game companion addon for the fan-made **The Leveling Codex** leveling guides, for
**World of Warcraft: Forever** (Blizzard's 2026 Classic-based client, PC/Mac only).
Published on CurseForge (project ID 1789784).

## Files

| File | What it is |
|---|---|
| `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` | Load order. **Must stay byte-identical.** Keep `## Version: @project-version@` (the packager fills it from the tag). |
| `Data.lua` | **Generated** from the guide pages: `LevelingCodexData[CLASS_TOKEN] = { spec, guide, plan, train, br, macros }`. Small hand fixes are OK, but keep its shape and list every data change in your summary so the owner can mirror it in the guides. |
| `Core.lua` | All addon code (to be split into modules, see below). |
| `CHANGELOG.md` | Becomes the CurseForge release notes (`.pkgmeta` `manual-changelog`). Add a section before every release. |
| `CURSEFORGE_DESCRIPTION.md`, `README.md`, `RELEASING.md` | Docs, not packaged. |
| `.pkgmeta`, `.github/workflows/release.yml` | BigWigsMods packager. Pushing a `v*` tag builds and uploads to CurseForge. |
| `tests/` | Headless test harness (Python + lupa, Lua 5.1). Not packaged. |

### Data.lua shape
- `spec` (e.g. "Protection"), `guide` (short guide name).
- `plan[]`: talent plan `{ name, tree, icon, max, from, to, why, more }`. Levels `from..to` each put one point into `name`; ranks add up across entries with the same name. `why` is shown at `from`, `more` on the later levels (falls back to `why` when empty).
- `train[]`: trainer visits `{ level, spells[], notes[], icons[] }`. Spell names carry ranks, e.g. `"Rend (Rank 2)"`.
- `br[]`: tip chapters ("brackets") `{ level, range, title, icon, intro, steps[], stepIcons[] }`.
- `macros[]`: `{ name, title, icon, lo, hi, body, pad, kb, tips[] }`. The same `name` appears in several level-banded versions. `pad` uses Xbox names and may contain arrows (translated at runtime).
- Guide text contains Unicode punctuation and arrows; it always goes through `plain()` / `padText()` before display.

### Core.lua map (current, pre-split)
- Theme: `THEMES` (`forever` teal = default, `codex` gold), `C` = active palette (a table mutated in place by `useTheme`, so captured references stay valid), `rgba`.
- Text: `SWAP` + `plain()` (ASCII-only output), `PADS` + `padText()` (Xbox/PS/Switch names), `say()`.
- Guide lookups: `talentAt`, `trainAt`, `nextTrain`, `bracketFor`, `macrosFor`, `comingMacros`.
- Macros: `setupMacros(onlyExisting)` via `CreateMacro`/`EditMacro`; auto-update after level-up only touches macros in `LevelingCodexCharDB.made`.
- Banner ("toast"): `makeToast`, `showToast(level, force, test)`, `unlocksAt`, `setToastUnlocked`; movable and scalable; test mode.
- Window (`/codex`): custom-drawn frame, pooled widgets (`take`/`releaseAll`), drawing helpers (`T`, `rect`, `box`, `icon`, `btn`, `chip`), `renderers[tab]` for level/talents/trainer/macros/tips/settings, level browser, `rebuildForTheme` (rebuilds the frame on theme change).
- Minimap button: `makeMini`, `placeMini`, `miniDrag`, `updateMini`.
- Talent window guide: `talentGuideTick` on a 0.25 s ticker; finds the talent window (`TALENT_ROOTS` + discovered roots), then the button by name (trait APIs) or icon (`GetFileIDFromPath`), draws a trace and a hint card.
- Events (`PLAYER_LOGIN`, `PLAYER_LEVEL_UP`, `PLAYER_REGEN_ENABLED`, `ADDON_LOADED`) and `/codex`.

## WoW: Forever client facts (design around these)
- `## Interface: 16001`. **Lua 5.1** (WoW flavour): no `goto`, no `//`, no integer division, no `\u{}` escapes.
- Talents use retail's **C_Traits** trait system. `GetTalentInfo`, `GetNumTalentTabs` and the Spec APIs **do not exist**. Talent window frame/button names are **unconfirmed**: keep the multi-strategy finder (known names, discovered frames, match by name then icon).
- Registering an unknown event **throws and aborts the file**: `pcall` `RegisterEvent` for anything beyond the core events.
- SavedVariables are written on exit but **may not be loaded back** (beta reports). Everything must work with an empty DB; never build a feature that depends on persistence.
- Secure snippets fail. `ReloadUI()` is protected. Reading auras in combat throws.
- Macros: max **255 characters** per body, **16** per name. Macros **skip** unlearned spells but **stop** on a learned spell that isn't ready ("You can't do that yet"). `/castsequence` **stalls** on a not-ready or unlearned step; `reset=N` counts from the last press.
- The game font can't draw `→ ↑ — ×` and similar: **all runtime text must be ASCII** (route guide text through `plain()`).
- Missing texture paths render **green**: always use `setIcon`, or check `SetTexture`'s return value and fall back.
- Assume any non-core API may be missing: guard with existence checks and `pcall`.

## Working rules
- Run the harness before every commit: `python tests/run.py` (needs `pip install lupa`). It must pass with no Lua errors and no non-ASCII runtime text.
- Keep both .toc files identical (the harness checks).
- Small, clear commits. Add a `CHANGELOG.md` section before a release.
- **Never push a tag** (that publishes to CurseForge) without the owner's explicit go-ahead.
- Keep the guide's look: parchment cards, double borders, Morpheus headings, Forever teal theme as default.
- The owner tests in game and sends screenshots: end each task with a summary, test results and a list of things to check in game.
