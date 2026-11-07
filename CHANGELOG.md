# Leveling Codex

## v0.10.0
- The Codex window now uses the game's own frame art: the dialog border with the gold title banner, a round class portrait, character-sheet tabs along the bottom, red Blizzard buttons, check boxes in Settings, spellbook page arrows for browsing levels, and cards with the tooltip border.
- The level-up banner and the talent card above the talent window got the same treatment: Blizzard gold titles, gold lines and icon rims like the game's.
- The talent guide only appears when you have a talent point to spend, and goes away as soon as you've spent it. With several points to spend it shows the earliest one first.
- The talent highlight now follows the talent's shape (round, square or choice) instead of always drawing a square box.
- New `/codex debug` lists what the Codex can see (art, talent window, talent points) to paste into bug reports.
- Theme colours (Forever teal or Codex gold) now tint the highlights and accents.
- New talent tree on the Talents tab: your build fills in up to the level you're viewing (gold when a talent is maxed, green when partly taken, grey for later points with the level they come at), the point for that level glows, and clicking a talent lists every point that goes into it and why. Once you've opened your talent window, the tree matches the game's layout.
- The Macros tab now shows where each macro goes: your controller's button sets (R2, L2, L2 + R2...) with each macro on its button, and an action bar with each macro on its key. Controller bindings are drawn as the game's button badges and glyphs (PlayStation shapes, Xbox letters, Switch letters) and keys as keycaps, everywhere in the Codex.
- Parchment cards in the Forever theme get the teal wash of Forever's quest log.
- Fixed: the tab hover glow sat off the text and lit up the selected tab.
- The talent highlight now takes the theme colour (Forever teal) instead of the node's own green, and the card above the talent window moves below it when the window is near the top of the screen.
- The level-up banner is now an unlocks card ("New at Level 17": your talent point, trainer spells, macros, new chapter) that appears after the game's own level-up display instead of repeating "You have reached Level 17". It finds the game's display and waits for it, or waits about 4 seconds, and starts lower on screen.
- Controller glyphs: the PlayStation circle is drawn as a real ring, keycaps have a light face, and empty halves of the controller panels are hidden.

## v0.9.0
- Fixed: the talent highlight and its card stayed on screen after closing the talent window. They now disappear the moment the window closes.
- Fixed: levelling up in combat could create every macro for your level when the fight ended. Now only the macros the Codex made are updated.
- Set up macros no longer overwrites a macro of your own that has the same name (for example your own "Fight"): it keeps yours, tells you, and shows the Codex version in the copy box.
- Auto-updating macros now works even when WoW: Forever doesn't load your saved settings, and the Codex tells you (once, and in Settings) when that happened.
- The talent guide is lighter: once it has found your talent it stops searching the talent window, follows the talent if the window reuses buttons, and also finds talent windows that load later.
- New: a Copy button on every macro, and a copy box with the macro text selected when your macro slots are full.
- New: close the Codex with B or Back on a controller (or Esc), and bind a key or controller button to open it (Key Bindings > AddOns).
- Each tab now remembers where you scrolled to.
- "Updated N macros" only appears when a macro actually changed.

## v0.8.0
- Talent window guide: the talent to take for your level is traced with a glowing outline, sparks and a "Codex pick" tag, with a card above the talent window showing it and your next two picks.

## v0.7.0
- Forever theme (teal, default) and Codex theme (gold) in Settings.
- Test level-up button on the This Level tab and in Settings; `/codex test 30` tests any level.

## v0.6.0
- Minimap button: left-click opens the Codex, right-click opens Settings, drag it around the minimap.

## v0.5.0
- The Codex window redesigned with tabs: This Level, Talents, Trainer, Macros, Tips and Settings, plus level browsing.

## v0.4.0
- Level-up fanfare banner with icons for every unlock.

## v0.3.0
- Settings: controller button names, banner size and position, chat messages, auto-updating macros, window size.

## v0.2.0
- Level-up banner.

## v0.1.0
- First beta: talent per level, trainer reminders, one-click macro setup.
