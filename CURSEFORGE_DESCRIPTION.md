# Leveling Codex

**Your leveling guide, inside the game.** Open your talents and the Codex traces the one to take. Level up and a card shows exactly what you unlocked. One click sets up smart macros for your level, for controller or keyboard. Open your crafting window and it outlines the recipe to make for Mining, Blacksmithing, Tailoring or Enchanting, 1-300.

Built from **The Leveling Codex** guides — one researched leveling spec per class, checked against the WoW: Forever client and hotfixes.

---

## Features

### Talent window guide
Whenever you have a talent point to spend, open your talent window and the Codex **traces the talent to take for your level** — a glowing outline in the theme colour that follows the talent's shape (round, square or choice), with sparks running around it and a *Codex pick 2/3* tag. A card above the window (or below it, near the top of the screen) shows that talent and your next two picks. With several points to spend it starts with the earliest, and it goes away once they're spent.

### What's new at each level
After the game's own level-up display, a **"New at Level 26"** card takes its place on screen, with each unlock sliding in with its icon:
- Talent point to take (with rank)
- New spells at your trainer
- New or updated macros
- New guide chapter

Hover to keep it up, click it for the full guide, right-click to dismiss. Open the Codex within a minute of the card and it opens on that level. Move it, resize it or turn it off in Settings, and use **Test level-up** there to try it any time.

### The Codex window
Type **/codex**, click the **Level 60 badge** on your minimap, or pick the Codex in the addons button under the clock. Browse any level from 1 to 60 with the page arrows. The window uses the game's own frame art: gold title banner, your class portrait and character-sheet tabs.
- **This Level** — your talent with the reason for it, the next picks, what to train, and your macros with the exact controller button and keyboard key for each.
- **Talents** — a talent tree with your build filled in up to the level you're viewing (gold when maxed, green when partly taken, later points marked with their level). Click a talent for every point that goes into it and why. Once you've opened your talent window, the tree matches the game's layout. Below it, every point from 10 to 60 in order.
- **Trainer** — every trainer visit, with icons and notes.
- **Macros** — every macro for your level with its code and how it works, plus your controller's button sets (R2, L2, L2 + R2...) and an action bar showing where each one goes.
- **Tips** — the play-style chapter for your level range.
- **Professions** — your Mining, Blacksmithing, Tailoring or Enchanting guide (see below).
- **Settings** — everything below, no slash commands needed.

### One-click smart macros
**Set up macros** creates this character's macros for your level. When you level into a new version (for example a Fight macro that adds Shield Slam at 40), the Codex **updates the macros it made automatically**. Your own macros are never touched, even one with the same name.

Every macro is built for Forever's macro rules: it never gets stuck on a spell that's on cooldown, and cast sequences are versioned by level. Every macro card has a **Copy** button, and if your macro slots are full the Codex opens the macro text ready to copy.

### Made for controller players
Forever's gamepad layout is built in: every macro says which trigger set and button it goes on, drawn as the game's button glyphs. Choose **Xbox, PlayStation or Switch** buttons in Settings.

The whole Codex window works on the controller with Forever's own navigation: **D-pad** to move, **A** to press, **B**, Back or Esc to close, **LB/RB** to switch tabs and the **right stick** to scroll. If Forever's navigation misbehaves, Settings > Controller switches to the Codex's own highlight. On the controller the crafting card selects the guide's recipe as the crafting window opens, so there's nothing to press. Bind a key or controller button to open the Codex (Key Bindings > AddOns).

### Profession guides: Mining, Blacksmithing, Tailoring and Enchanting 1-300
Built for WoW: Forever's reworked Blacksmithing, Tailoring and Enchanting, from the game's own recipe colours and reagents.
- **Professions tab**: your skill, the recipe to make now with how many more and the materials against your bags, where to learn it, the trainer to visit when the next tier is due, the whole route and a shopping list to 300. Mining shows what to mine where for your faction and what to smelt for points. Tailoring counts the shopping list in raw cloth and shows which mobs and zones drop each cloth for your faction. Enchanting says which rod each step needs and what each green or blue item in your bags would disenchant into.
- **Crafting window guide**: open Blacksmithing, Smelting, Tailoring or Enchanting and the Codex outlines the recipe to make (in Tailoring the bolts first when you only have the cloth, in Enchanting a missing rod first), with a card showing how many more and how many you have materials for. It never touches the window itself: scroll the list as usual (mouse or controller) and the recipe is outlined when it comes into view.
- **Skill-up card** when you reach a new step, can train Journeyman, Expert or Artisan, or can mine a new vein. Open the Codex within a minute of it and it opens on that profession.
- Turn the crafting window guide or the skill-up cards off under Settings > Professions.

### Gathering tracking stays on
WoW: Forever turns **Find Herbs** and **Find Minerals** off when you log in, zone or die. The Codex turns the one you had back on for you (out of combat, never over another tracking such as Track Beasts), and turns it on when you learn Herbalism or Mining. Untick it in Settings if you'd rather do it yourself.

### Two themes
**Forever** (teal, the default) or **Codex** (gold and parchment).

---

## Classes and specs

| Class | Leveling spec |
|---|---|
| Warrior | Protection |
| Mage | Frost |
| Hunter | Marksmanship |
| Rogue | Combat |
| Priest | Shadow |
| Paladin | Retribution |
| Shaman | Enhancement |
| Warlock | Affliction |
| Druid | Feral |

---

## Commands

| Command | What it does |
|---|---|
| `/codex` | Open or close the Codex window |
| `/codex macros` | Create or update your macros for your level |
| `/codex test` | Test level-up (`/codex test 30` for any level) |
| `/codex minimap` | Show or hide the minimap button |
| `/codex reset` | Reset the window, banner and minimap button positions |
| `/codex debug` | List what the Codex can see, to paste into a bug report (also: trainer requirements that differ from the profession guide) |

Left-click the minimap badge to open the Codex, right-click for Settings, and drag it around the minimap edge.

---

## Notes

- **Beta.** The talent tracing finds talents by name or icon; if it can't find a button, the card above the talent window still tells you which talent and tree. Bug reports are very welcome: please include a screenshot and the output of `/codex debug` (and `/fstack` over the talent window if tracing misses).
- The guides themselves, with every talent reason, trainer list and macro: **[The Leveling Codex](https://claude.ai/artifact/WN1YRMyVRuxSBmS55Gz4f3)**
- Fan-made. Not affiliated with or endorsed by Blizzard Entertainment.
