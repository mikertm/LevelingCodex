# Leveling Codex

## v0.12.0
- New: **profession guides for Mining and Blacksmithing, 1-300**, built for WoW: Forever. Forever reworked Blacksmithing (about 200 new plans, and many recipes turn yellow and grey 25 points earlier than in Classic), so the route uses Forever's own recipe colours and reagents, checked against the game files.
  - **Blacksmithing**: the cheapest trainer route: stones, Copper Chain Belt, Runed Copper Belt, Rough Bronze Leggings, Heavy Grinding Stones (kept for Golden Scale Bracers), Iron Buckle, Bronze Warhammer, Green Iron Bracers, Golden Scale Bracers, the Heavy Mithril pieces and Dense Sharpening Stones, then the Imperial Plate plans from Derotain Mudsipper's quests in Tanaris from 240. Every step has an alternative.
  - **Mining**: what to mine and where for your faction (Zephras Isle for Skyborne), and what to smelt for points. Smelting only gives points up to 185 (Smelt Gold).
  - **Tailoring**: the cheapest trainer route to 225 (bolts, Linen Belt, Woolen Cape, Double-stitched Woolen Shoulders, Azure Silk Hood, Earthen Vest, Crimson Silk Vest, the Black Mageweave pieces, Runecloth Belt), then Forever's vendor patterns: Runecloth Gloves (Qia, Winterspring), Runecloth Cuffs (Pexmit, Mount Hyjal) and Venomspew Gloves and Cord (Mishta, Silithus). Forever's trainers stop at 225, and only Timothy Worthington (Theramore) and Daryl Stack (Tarren Mill) teach Artisan.
  - Tailoring's shopping list is in raw cloth (bolts you hold count), and a **cloth** section shows the mob levels and zones for each cloth for your faction, with the cloth your step needs first.
- New **Professions** tab: your skill, the recipe to make now with how many more and the materials against your bags, where to learn it, the trainer to visit when Journeyman (50), Expert (125) or Artisan (200) is due, the whole route (click a step), and a shopping list to 300.
- New: **crafting window guide**. Open Blacksmithing, Smelting or Tailoring and the Codex outlines the recipe to make for your skill, with a card showing how many more, how many you have materials for and its colour. Not learned yet: where to learn it. Gone grey: what's next. **Show it** selects a recipe scrolled out of view. In Tailoring, when the step needs bolts and you only have the cloth, it outlines the bolt recipe first and says how many your cloth makes.
- New: a **skill-up card** in the level-up banner's look when your Mining or Blacksmithing reaches a new step, can train the next tier, hits its cap, or can mine a new vein. Ordinary points stay quiet.
- When your skill is ready for the next tier before your level is (Journeyman needs level 10, Expert 20, Artisan 35), the level-up banner and chat tell you to train it at the level that opens it.
- Settings > Professions turns the crafting window guide and the skill-up cards on or off.
- Fixed: **Show it** did nothing in Forever's crafting window. It now scrolls the list to the recipe and selects it.
- Controller support: the Codex window works with Forever's controller navigation (D-pad, A, B, LB/RB to switch tabs, right stick to scroll), with its own navigation as a backup (Settings > Controller). On the controller the crafting card selects the guide's recipe as the crafting window opens, so there's nothing to press.
- Opening the Codex within a minute of a level-up banner or a skill-up card opens what it was about (that level, or the Professions tab on that profession).
- New look for the minimap button: the Level 60 badge instead of the brown book many addons use, and it now starts on the right side of the minimap instead of the lower left, where most addon buttons pile up (drag it anywhere as before). The Codex is also listed in the addons button under the clock.
- Fixed: the card beside the crafting and talent windows covered the controller hints the game shows under a window near the top of the screen. It now goes below them.
- The skill a trainer teaches each recipe at isn't in the game files, and the Forever guides disagree on it. Visit a Blacksmithing and a Mining trainer, then `/codex debug`: it lists any recipe whose trainer requirement differs from the guide.

## v0.11.0
- Every guide checked against WoW: Forever's own game data (build 1.60.1.70862) and Blizzard's 2 Nov notes and 5-6 Nov hotfixes: talent order, the reason for every talent, trainer spells and ranks, macros and tips. 116 fixes across the nine classes:
  - **Warrior:** new **Rend again** macro (RT+Y / 4): a cast sequence moves on even when Rend misses, so press this to put Rend back up. Panic no longer gets stuck at 26-27 before Shield Wall. Tactical Mastery keeps 25 Rage (not 10), Charge gives 9 Rage at 25 (12 from 26), Thunder Clap lasts 10-30 sec by rank.
  - **Mage:** Get away no longer gets stuck before Blink at 20 (Frost Nova only at 10-19). Cone of Cold Rank 5 added at 58. Shatter adds 50% crit against frozen targets (not "almost every crit"); Fire Blast beats Ice Lance on targets that aren't frozen.
  - **Paladin:** Divine Protection and Divine Shield share one 5 min cooldown (Panic tip and trainer notes); Divine Shield Rank 2 lasts 12 sec; Seal of Command's Judgement numbers at 20; Greater Blessing of Kings has no rank.
  - **Druid:** Faerie Fire costs mana and needs caster form; Swipe hits 3 enemies; clearer Feral Swiftness, Natural Instinct, Ferocity and Rend and Tear reasons.
  - **Hunter:** Beast Training (10) added so your pet's Growl keeps up; Aspect of the Pack, Rapid Recuperation, Trueshot Aura duration and trap placement corrected.
  - **Priest:** Shadow Word: Death ranks added to the training reminder; Improved Mind Blast is 2/5 at 33-34; Shadow Reach and Death's backlash corrected; Fear Ward gets its own line.
  - **Rogue:** poisons use the game's names (Instant Poison II...VI and so on); Distract, Adrenaline Rush and poison charges corrected.
  - **Shaman:** the training reminder now includes totems, Fire Nova, Chain Lightning and heals; talent reasons give the value per point; totem durations corrected.
  - **Warlock:** new Fight version from 40 that casts Wrack; Fel Concentration is a 70% chance (not immunity); Improved Corruption is instant from 14; Spell Lock at 36.

## v0.10.0
- New: Find Herbs and Find Minerals stay on. WoW: Forever turns gathering tracking off when you log in, reload, zone or die; the Codex now turns the one you had back on a couple of seconds later. It waits until you're alive and out of combat, leaves another tracking you picked (like Track Beasts) alone, remembers which one you switched to last, and turns tracking on when you learn Herbalism or Mining. At login, tracking that already looks on is toggled off and on so the minimap shows it. Turn it off under Settings > Gathering.
- `/codex debug` now reports gathering tracking.
- The Test level-up button is gone from the This Level tab; it's still under Settings > Level-up banner.
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
- The level-up banner is now an unlocks card ("New at Level 17": your talent point, trainer spells, macros, new chapter) that appears after the game's own level-up display instead of repeating "You have reached Level 17". It finds the game's display and waits for it, or waits about 4 seconds, then takes that display's spot on screen (unless you moved the banner).
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
