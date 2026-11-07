# Leveling Codex: notes for Claude

An in-game companion addon for the fan-made **The Leveling Codex** leveling guides, for
**World of Warcraft: Forever** (Blizzard's 2026 Classic-based client, PC/Mac only).
Published on CurseForge (project ID 1789784).

## Files

| File | What it is |
|---|---|
| `LevelingCodex.toc`, `LevelingCodex_Camelot.toc` | Load order. **Must stay byte-identical.** Keep `## Version: @project-version@` (the packager fills it from the tag). |
| `Data.lua` | **Generated** from the guide pages: `LevelingCodexData[CLASS_TOKEN] = { spec, guide, plan, train, br, macros }`. Small hand fixes are OK, but keep its shape and list every data change in your summary so the owner can mirror it in the guides. |
| `Theme.lua` … `Init.lua` | Addon code, one module per file, loaded in .toc order (see below). |
| `Bindings.xml` | Key binding "Open or close the Codex" (auto-loaded by the client, not listed in the .toc). |
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

### Modules (load order)
All files share the addon table: `local _, ns = ...`. Cross-module calls go through `ns.x()` **at call time**, so a module may call one that loads later; only values read while a file loads need load order. Never create globals (the harness fails on leaks); allowed: the SavedVariables, `LevelingCodexData`, `SLASH_LEVELINGCODEX1`, `BINDING_*`, `LevelingCodex_Toggle`, named frames `LevelingCodex*`.
1. `Theme.lua`: `ns.THEMES` (`forever` teal = default, `codex` gold), `ns.C` = active palette (mutated in place by `ns.useTheme`, so `local C = ns.C` stays valid; `ns.themeVersion` bumps on each switch), `ns.rgba`, `ns.db()`/`ns.charDB()` (never nil), `ns.try` (pcall an API that may not exist), timers `ns.after`/`ns.every` (C_Timer or an OnUpdate fallback), `ns.plain` (ASCII-only text), `ns.PADS`/`ns.padText`, `ns.say`, `ns.setIcon`, `ns.fade`/`ns.fadeAccent`.
1b. `Art.lua` (`ns.art`): Blizzard frame art with fallbacks. `A.FILES` lists every art file; `A.hasFile` probes it once (SetTexture returns false when missing) and every piece falls back to the flat Codex look. Helpers: `A.frame` (adds `BackdropTemplate` when the client needs it), `A.backdrop(f, "dialog"|"tooltip", bg, edge)`, `A.header` (gold title banner), `A.button` (UIPanelButtonTemplate, `SetLabel`/`SetLook`), `A.check` (UICheckButtonTemplate + label), `A.tab` (character-sheet tabs, `SetSelected`), `A.arrow` (spellbook page arrows, `codexLabel` "<"/">"), `A.portrait` (round class icon). `A.report` records what was used, for `/codex debug`.
2. `Guide.lua`: lookups into `ns.D` (this class's guide, set at login): `talentAt`, `trainAt`, `nextTrain`, `bracketFor`, `macrosFor`, `comingMacros`. All cope with `ns.D == nil`.
3. `Macros.lua`: `ns.setupMacros(onlyExisting)`. A macro is "ours" if it's in `LevelingCodexCharDB.made` **or its body matches a guide version** (so auto-update survives lost SavedVariables). Combat: a manual setup is queued as "full", a level-up refresh as "refresh" (never creates macros). Failures open the copy box.
4. `Banner.lua`: level-up chat (`ns.levelUpMessage`) and the banner (`ns.showToast(level, force, test)`, `ns.setToastUnlocked`, `ns.placeToast`, `ns.getToast`, `ns.dropToast`).
5. `Window.lua`: the `/codex` window: pooled widgets (`take`/`releaseAll`), drawing helpers (`T`, `rect`, `box`, `icon`, `btn`, `chip`), `renderers[tab]` (level/talents/trainer/macros/tips/settings), per-tab scroll memory, the talent tree (`talentModel`, `layoutTree`: game layout from `ns.traitLayout()` else tiers from the plan), controller/keyboard drawing (`parsePad`, `padCombo`, `keyCombo`, `controllerMock`, `keyboardMock`; glyphs on the `top` layer above icons), `ns.rebuildForTheme`, `ns.openTab`, `ns.toggleWindow`, the copy box `ns.showMacroCopy(m, list)`, Esc/controller close.
6. `Minimap.lua`: `ns.updateMini`.
7. `TalentGuide.lua`: 0.25 s ticker. Shows only while there are unspent points (`C_Traits` tree currency, else `UnitCharacterPoints`; unknown = show) and traces the next unspent point in the plan (`10 + points spent`). The trace copies the button's own border art (`StateBorder`/`Border`/... atlas or file) so it matches circle/square/choice nodes; with only a mask it draws a round glow, else a box. Finds the window (`TALENT_ROOTS`, then window-sized frames named `*Talent*`/`*Trait*` found by `discoverRoots` on toggle hooks and talent-addon loads), then the button by name (trait APIs) or icon. Once found it only re-checks the cached button (pooled buttons get reused); misses back off up to 8 s. Hides on the window's `OnHide`. Never treat `LevelingCodex*` frames as a window.
8. `Init.lua`: events (`start()` is idempotent: PLAYER_LOGIN, retried at PLAYER_ENTERING_WORLD), lost-SavedVariables detection (`ns.settingsLost`), key binding globals, `/codex`.

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

## Tests
- `python tests/run.py` (needs `pip install lupa`; ~25 s, runs in parallel). `-k WARRIOR/full` filters runs, `-v` prints all data warnings.
- `tests/wowmock.lua` is the mocked client. Strict on purpose: unknown events, templates, scripts or methods throw; `SetPoint` refuses self/looped anchors; `CreateMacro` enforces the 255/16 limits and combat lockdown. `minimal = true` removes optional APIs (C_Timer, C_Spell, GetFileIDFromPath, EnumerateFrames, hooksecurefunc, GetMacroInfo, gradients, gamepad...).
- `tests/scenarios.lua` only drives what a player or the client can reach (events, `/codex`, clicks, drags, named frames), so it survives refactors. Each run (class x full/minimal x main/icon/persisted/lost-savedvars) starts a fresh Lua state.
- Also checked: both .toc files identical, `@project-version@`, Data.lua shape, talent plan covers 10-60, macro limits, and a lint for `/castsequence` steps not yet learned at the macro's first level (warnings, not failures).

## Working rules
- Run the harness before every commit. It must pass with no Lua errors, no non-ASCII runtime text and no leaked globals.
- When a bug is reported from the game, first add a scenario that reproduces it.
- **In-game testing: install straight into the owner's game, never hand over a zip.** After the harness passes, run `python tools/install.py`. It copies the build into `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\LevelingCodex` (override with an argument or `LEVELINGCODEX_ADDONS`), removes stale `.lua`/`.xml` from older builds, leaves other files alone and verifies every copy. Then tell the owner to `/reload` (restart the client if a .toc changed).
- Keep both .toc files identical (the harness checks).
- Small, clear commits. Add a `CHANGELOG.md` section before a release.
- **Never push a tag** (that publishes to CurseForge) without the owner's explicit go-ahead.
- Keep the guide's look: parchment cards, double borders, Morpheus headings, Forever teal theme as default.
- The owner tests in game and sends screenshots: end each task with a summary, test results and a list of things to check in game.
