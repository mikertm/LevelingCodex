# Profession guides: Mining and Blacksmithing 1-300 (design)

Date: 2026-11-07. Game data: WoW: Forever build 1.60.1.70862 (wago.tools, product `wowf`).

## Goal

A complete Mining and Blacksmithing 1-300 guide for WoW: Forever inside the Codex, built like the
talent guide: the guide's facts come from the game's own tables and are checked by the harness,
and in game the Codex shows what to do at your skill, traces it in the game's window, and shows a
card when something changes.

Decided with the owner:
- Features: a **Professions tab**, a **crafting window trace**, a **skill-up card**. (Help inside the
  trainer window is not part of this task.)
- The guide lives **in the addon first** (`ProfessionData.lua`, checked against the game). A page on
  The Leveling Codex site is a follow-up.
- Blacksmithing route: **cheapest, trainer recipes** until the Artisan tier; plans only where there
  is no trainer recipe (Artisan: quest plans).
- Approach: **route data plus live colours**. The route is fixed data; in game the Codex also reads
  each recipe's real colour and whether you know it, and adjusts the card.

## What the game and the sources say

### From the client tables (exact)
- Every recipe's colours: `SkillLineAbility.TrivialSkillLineRankLow` = turns yellow,
  `TrivialSkillLineRankHigh` = turns grey; green starts halfway (Rough Sharpening Stone 15/35/55
  and Copper Bracers 20/40/60 match their known in-game colours).
- Reagents (`SpellReagents`), what a recipe makes (`SpellEffect` effect 24), item names
  (`ItemSparse`), plans that teach a recipe and the skill a plan needs (`ItemXItemEffect`,
  `ItemEffect`, `ItemSparse.RequiredSkillRank`).
- Forever re-tuned many Blacksmithing recipes (most Expert/Artisan ones turn yellow and grey 25
  points earlier than in Classic) and added about 200 plans (Skyforged, Veteran's/Guard's/
  Protector's/Acolyte's/Crusader's, Officer's/Sentinel's/Warder's/Prefect's/Justicar's, Blessed
  Plate, Bold Dirk...). Classic guides are wrong for Forever.
- Smelting colours: Copper 25/70, Tin 50/75, Bronze 65/115, Silver 100/125, Iron 130/140,
  Gold 170/185, Steel 165/165, Mithril 175/175, Truesilver and Dark Iron 230/230, Thorium 250/250,
  Azerothium 275/275, Heavy Thorium 300/315. **Smelting gives Mining points only up to 185**
  (Smelt Gold): from Mithril on, a smelt is grey as soon as you can learn it.
- Mining lock skills in the client: 1, 65, 75, 125, 155, 175, 230, 245, 275 (the Classic veins) plus
  25, 50, 100, 150, 300, 305, 310 (unnamed in the client; Forever's new nodes are not documented yet).
- Zone names used by the guide all exist in `AreaTable`; Forever's new Skyborne race (Alliance and
  Horde) starts on **Zephras Isle**.

### Not in the client (server-side), taken from the guides and checked in game
- **The skill a trainer teaches each recipe at.** The Forever guides disagree here; Wowhead (4 Nov)
  and wowforever.info agree with each other and with the colour shift (a recipe moved 25 points
  earlier is also taught 25 points earlier). The route uses those values, each step lists an
  alternative, and the Codex reads the real requirement in game (see *Checking learn levels*).
- Training tiers (all agree): Apprentice to 75 at any level; Journeyman to 150 from skill 50 and
  level 10; Expert to 225 from skill 125 and level 20 (Blacksmithing: Bengus Deepforge, Ironforge,
  or Saru Steelfury, Orgrimmar); Artisan to 300 from skill 200 and level 35 (Blacksmithing: Brikk
  Keencraft, Booty Bay).
- Vein skills are unchanged from Classic (all Forever sources). Node colours follow the gathering
  rule: orange until skill + 25, yellow until + 50, green until + 100.
- Imperial Plate plans: quests from Derotain Mudsipper in Tanaris that take Thorium Bars (20 for the
  belt and bracers, 40 for the boots, 60 for the leggings). Whether Forever lowered the quests'
  skill along with the recipes is unconfirmed; the step's alternative covers it.

Sources: Wowhead Forever Blacksmithing guide (4 Nov), wow-professions Forever (beta),
wowforever.info (13 Oct), mmonster (3 Nov, beta 70790), Zockify Forever (2 Nov, 1 Oct for Mining),
wow.gg Forever Mining (4 Nov), WoW Forever Manual Mining.

## The routes

Crafts are expected counts from the colours (see *Craft counts*); the Codex recomputes them from
your real skill. Materials are for the whole step.

### Blacksmithing

| Skill | Recipe | Learn at | ~Crafts | Materials | Alternative |
|---|---|---|---|---|---|
| 1-25 | Rough Sharpening Stone | 1 (known) | 26 | 26 Rough Stone | Rough Weightstone |
| 25-65 | Rough Grinding Stone | 25 | 48 | 96 Rough Stone | |
| 65-80 | Copper Chain Belt | 35 | 17 | 102 Copper Bar | Runed Copper Gauntlets |
| *50* | *Train Journeyman* | | | | |
| 80-95 | Runed Copper Belt | 80 | 17 | 170 Copper Bar | Rough Bronze Leggings, if taught already |
| 95-100 | Rough Bronze Leggings | 95 | 5 | 30 Bronze Bar | Runed Copper Belt |
| 100-112 | Heavy Grinding Stone | 100 | 16 | 48 Heavy Stone (keep the stones: Golden Scale Bracers) | |
| 112-125 | Rough Bronze Leggings | 95 | 14 | 84 Bronze Bar | Patterned Bronze Bracers |
| *125* | *Train Expert* | | | | |
| 125-130 | Iron Buckle | 125 | 12 | 12 Iron Bar | |
| 130-140 | Bronze Warhammer | 125 | 10 | 80 Bronze Bar, 10 Strong Flux, 10 Medium Leather | |
| 140-165 | Green Iron Bracers | 140 | 25 | 150 Iron Bar, 25 Green Dye | |
| 165-185 | Golden Scale Bracers | 160 | 20 | 100 Steel Bar, 40 Heavy Grinding Stone | |
| 185-210 | Heavy Mithril Gauntlet | 180 | 29 | 174 Mithril Bar, 116 Mageweave Cloth | |
| *200* | *Train Artisan* | | | | |
| 210-225 | Heavy Mithril Breastplate | 205 | 15 | 240 Mithril Bar | Mithril Coif (150 Mithril, 90 Mageweave) |
| 225-235 | Dense Sharpening Stone | 225 | 17 | 17 Dense Stone | Dense Weightstone |
| 235-240 | Heavy Mithril Boots | 210 | 8 | 112 Mithril Bar, 32 Thick Leather | |
| 240-245 | Imperial Plate Belt (quest plan) | 240 | 5 | 110 Thorium Bar, 30 Rugged Leather, 5 Aquamarine | Heavy Mithril Boots |
| 245-272 | Imperial Plate Bracers (quest plan) | 245 | 29 | 580 Thorium Bar, 29 Star Ruby | Ebon Shiv / Ornate Thorium Handaxe (vendor plans) |
| 272-290 | Imperial Plate Boots (quest plan) | 270 | 18 | 612 Thorium Bar, 18 Star Ruby, 18 Aquamarine | |
| 290-300 | Imperial Plate Leggings (quest plan) | 280 | 10 | 440 Thorium Bar, 20 Star Ruby | Imperial Plate Chest |

Every step was checked against the colours: no recipe turns grey before its step ends. (Changed after
review: the client's `SkillLineAbility.MinSkillLineRank` says Runed Copper Belt is learned at 80 and
Rough Bronze Leggings at 95, against 75 and 80 on guide sites, so 65-100 is laid out to work with
either; the reference keeps that field as `min` and the audit warns when a step's `learn` is lower.) The 245-300
steps are expensive in Thorium (about 1,740 bars plus 140 for the quests); that is the cost of the
Artisan tier in Forever without dungeon-drop plans. Specializations (Armorsmith or Weaponsmith, from
200 and level 40) get a note at 200; they don't change the route.

### Mining

| Skill | Mine | Smelt for points | Zones |
|---|---|---|---|
| 1-65 | Copper Veins | Copper Bar (to 70) | Alliance: Elwynn Forest, Dun Morogh, Darkshore, Westfall, Loch Modan. Horde: Durotar, Mulgore, Silverpine Forest, Tirisfal Glades, The Barrens. Skyborne: Zephras Isle |
| *50* | *Train Journeyman* | | |
| 65-75 | Tin Veins | Tin Bar, Bronze Bar | Alliance: Redridge Mountains, Duskwood, Wetlands. Horde: Hillsbrad Foothills, The Barrens, Stonetalon Mountains |
| 75-125 | Tin and Silver Veins | Silver Bar (orange to 100), Bronze Bar (to 115) | Same as Tin |
| *125* | *Train Expert* | | |
| 125-175 | Iron Deposits, Gold Veins from 155 | Iron Bar (to 140), Gold Bar (to 185) | Alterac Mountains, Arathi Highlands, Badlands, Hillsbrad Foothills, Stranglethorn Vale, Thousand Needles, Desolace |
| 175-245 | Mithril Deposits, Truesilver from 230 | none (Mithril and up give no points) | Badlands, The Hinterlands, Tanaris, Searing Gorge, Burning Steppes, Felwood |
| *200* | *Train Artisan* | | |
| 245-275 | Small Thorium Veins | none | Un'Goro Crater, Eastern Plaguelands, Silithus, Winterspring, Burning Steppes |
| 275-300 | Small and Rich Thorium Veins | none | Winterspring, Un'Goro Crater, Eastern Plaguelands, Western Plaguelands, Azshara, Burning Steppes |

The veins table also lists Dark Iron (230, Searing Gorge and Blackrock Depths) and Mining's camp
objects: Lodestone (20, trainer), Rock Garden (140, blueprint), Molten Foundry (300, blueprint;
needed for Heavy Thorium). Pitchblende and Heavy Thorium Ore have no known source yet; the guide
says so instead of guessing.

## Data: `ProfessionData.lua`

Hand-written like a guide page, loaded first (with `Data.lua`). One new allowed global,
`LevelingCodexProfessions`, keyed by an upper-case profession token:

```lua
LevelingCodexProfessions = {
  BLACKSMITHING = {
    name = "Blacksmithing", skillLine = 164, icon = "trade_blacksmithing",
    tiers = {
      { name = "Apprentice", cap = 75, skill = 1, level = 1, where = "Any Blacksmithing trainer" },
      { name = "Journeyman", cap = 150, skill = 50, level = 10, where = "Blacksmithing trainers in the capitals" },
      { name = "Expert", cap = 225, skill = 125, level = 20, where = "Bengus Deepforge (Ironforge) or Saru Steelfury (Orgrimmar)" },
      { name = "Artisan", cap = 300, skill = 200, level = 35, where = "Brikk Keencraft, Booty Bay" },
    },
    steps = {
      { from = 1, to = 25, name = "Rough Sharpening Stone", spell = 2660, icon = "inv_stone_sharpening_01",
        yellow = 15, grey = 55, mats = { { "Rough Stone", 1 } }, learn = 1,
        source = "Known when you learn Blacksmithing", note = "Keep a few for your weapon.",
        alt = "Rough Weightstone (same cost)" },
      -- one entry per row of the route table above
    },
    notes = { [200] = "Armorsmith or Weaponsmith opens at 200 and level 40; it doesn't change this route." },
  },
  MINING = {
    name = "Mining", skillLine = 186, icon = "trade_mining", tiers = { ... },
    veins = { { name = "Copper Vein", skill = 1, ore = "Copper Ore", icon = "inv_ore_copper_01",
                zones = { Alliance = { ... }, Horde = { ... }, Skyborne = { "Zephras Isle" } } }, ... },
    smelt = { { name = "Smelt Copper", spell = 2657, learn = 1, yellow = 25, grey = 70,
                mats = { { "Copper Ore", 1 } }, makes = "Copper Bar", icon = "inv_ingot_02" }, ... },
    steps = { { from = 1, to = 65, title = "Copper", veins = { "Copper Vein" }, smelt = { "Smelt Copper" },
                note = "..." }, ... },
    camp = { { name = "Lodestone", skill = 20, source = "Mining trainer", text = "..." }, ... },
  },
}
```

- Steps cover every point from 1 to 300 with no gaps or overlaps (`to` of one step = `from` of the
  next).
- `yellow`, `grey`, `mats`, `spell` and `icon` are copied from the game reference and checked by the
  harness; `learn`, `source`, `note`, `alt`, zones and tiers are guide text.
- All text is ASCII (or goes through `plain()`).

### Craft counts
Expected crafts for a step from skill `a` to `b` = sum over each point `s` of `1 / chance(s)`, with
`chance = 1` below yellow, `(grey - s) / (grey - yellow)` from yellow on, `0` at grey (the community
formula; the card says "about"). The Codex recomputes this from your real skill, so the counts, the
materials and the shopping list always start where you are.

## Game reference and checks

`tools/gamedata.py`:
- `TABLES` adds `SpellReagents`, `ItemSparse`, `Item`, `ItemEffect`, `ItemXItemEffect`,
  `TradeSkillCategory`.
- `build_reference` adds `professions`: per profession (Blacksmithing 164, Mining 186) every recipe
  by name: `spell`, `yellow`, `green`, `grey`, `mats` (`[item, count]`), `makes` (`[item, count]`),
  `icon` (the item's icon, else the spell's), `category`, and `plan` (`item`, `skill`) when a plan
  teaches it.
- `diff` reports profession changes too (recipes added or removed, colours, materials), so the daily
  Game data workflow catches them.
- New `audit_professions(profdata, ref)` and commands `profs [PROFESSION]` (the route next to the
  game) and `recipes PROFESSION [NAME]`.

The harness (`game_checks()`) fails on: a step recipe that isn't on the profession's skill line; a
step's `yellow`, `grey` or `mats` that differ from the game; a recipe that turns grey before its
step ends; steps that leave a gap or overlap between 1 and 300; a step that runs past a tier's cap
before the next tier can be trained (the next tier's `skill` must be at or below the cap). Warns on:
a recipe that is green for more than half of its step; an icon that differs; a `learn` above the
step's `from`. Data shape checks (in `data_checks()`): required fields, ASCII text, every Mining
step's veins and smelts exist in the veins/smelt lists.

## Runtime

### `Professions.lua` (new, after `Guide.lua`)
Lookups, all safe with no data and no profession:
- `ns.profSkill(key)`: your skill and cap, from `GetProfessions` + `GetProfessionInfo` when they
  exist, else `GetNumSkillLines` + `GetSkillLineInfo` (matched by the profession's name); nil when
  you don't have it or neither API exists.
- `ns.profStep(key, skill)`, `ns.profNext(key, skill)`, `ns.expectedCrafts(step, from)`,
  `ns.profShopping(key, skill)` (materials from your skill to 300), `ns.profTierDue(key, skill, level)`
  (train now / stuck at a cap / not yet), `ns.veinsFor(skill)` (each vein's colour at your skill).

### Professions tab
Window.lua exposes its drawing helpers as `ns.ui` and lets another file add a tab
(`ns.addTab(key, label, renderer)`), so the new tab lives in its own file, `ProfessionTab.lua`
(Window.lua is already ~1,500 lines). The tab shows:
- A Blacksmithing / Mining switch (defaults to one you have) and your skill with its cap.
- **Now** (parchment card): recipe icon and name, "about N more to <to>", the materials for those
  crafts with how many you have (`GetItemCount`), where to learn it and its skill, the alternative.
  Mining: the veins to mine with their colour at your skill and the zones for your faction (and
  Zephras Isle for Skyborne), plus what to smelt for points.
- A training card when a tier is due ("Train Expert Blacksmithing: Bengus Deepforge, Ironforge"), or
  "you're at your cap" when stuck.
- Next step strip; the whole route (your step highlighted; click a step to show it in the Now card);
  the shopping list from your skill to 300.
- Without the profession: how to learn it, and the route to read.

### Crafting window trace: `ProfessionGuide.lua` (new)
- Watches `TRADE_SKILL_SHOW` / `TRADE_SKILL_UPDATE` / `TRADE_SKILL_CLOSE` (registered with `pcall`)
  and a 0.25 s ticker only while a crafting window is shown.
- Finds the window like the talent trace: known names (`TradeSkillFrame`, `ProfessionsFrame`), then
  shown window-sized frames named `*TradeSkill*` / `*Profession*`; never `LevelingCodex*` frames.
  Which profession: `GetTradeSkillLine()` or `C_TradeSkillUI` (whichever exists).
- Reads the recipe list (`GetNumTradeSkills` / `GetTradeSkillInfo`, else `C_TradeSkillUI`): name,
  live colour, how many you can make (`numAvailable`).
- Outlines the row whose text is the step's recipe in the theme colour, and shows a card beside the
  window: "Codex pick: Runed Copper Belt", about N more to <to>, materials you have for M, the live
  colour. If the recipe isn't known: learn it at the trainer (skill). If it's grey already: the next
  step. If the row isn't on screen (scrolled or filtered), the card still shows; a **Show it** button
  selects the recipe when the client allows (`SelectTradeSkill`).
- Hides on the window's `OnHide`. Setting: "Trace my recipe in the crafting window".

### Skill-up card
Banner.lua's card gets a generic entry point (`ns.showCard(title, sub, rows, onClick)`), used by the
level-up banner and by professions; same look, position, size and on/off rules. A profession card
shows right away (no waiting for the game's level-up display) and only when:
- a new step starts ("Blacksmithing 100: Heavy Grinding Stone, about 16");
- a tier is due or you hit a cap you haven't trained past;
- a new vein opens up (Mining 65, 75, 125, 155, 175, 230, 245, 275).
Skill changes come from `SKILL_LINES_CHANGED` and `CHAT_MSG_SKILL` (pcall'd), compared with the last
skill seen this session (nothing persisted: login records the start without a card). Clicking the
card opens the Professions tab. Setting: "Profession skill-up cards". A chat line goes with it
unless messages are off.

### Checking learn levels
When a trainer window is open (`TRAINER_SHOW`, pcall'd), the Codex reads each recipe's requirement
(`GetTrainerServiceSkillReq`, when it exists) and keeps the ones on the route whose real skill
differs from the guide. `/codex debug` lists them, so the owner's in-game screenshots give the exact
fixes. No UI at the trainer beyond that.

## Tests

- `tests/wowmock.lua`: profession skills (both API styles), a crafting window (`TradeSkillFrame`
  with named rows), `GetTradeSkillLine` / `GetNumTradeSkills` / `GetTradeSkillInfo` /
  `SelectTradeSkill`, `GetItemCount`, trainer services, and the new events; `minimal = true` removes
  the crafting and profession APIs.
- `tests/scenarios.lua` (driven by events, `/codex`, clicks, named frames only):
  - no profession: the tab explains how to learn it; nothing errors;
  - Blacksmithing at 1, 87, 150 (capped, untrained), 299 and Mining at 60, 140: tab content (step,
    counts, tier card, vein colours, faction zones);
  - crafting window: row outlined, card text; recipe not learned; recipe grey; row scrolled off;
    window closed hides the trace;
  - skill-up: card at a step boundary, at 50/125/200 and at a cap, and at a new vein; no card for an
    ordinary point; none at login;
  - trainer requirements different from the guide show in `/codex debug`;
  - minimal client and lost SavedVariables: no errors, tab still renders.
- Both `.toc` files list the new files in the same order; no new globals besides
  `LevelingCodexProfessions`.

## Out of scope
- The Codex site page for professions (follow-up once the data has been checked in game).
- Other professions (the data shape is generic: one more key in `LevelingCodexProfessions`).
- Help inside the trainer window (only the debug check above).
- The Armorsmith / Weaponsmith quest lines (a note at 200).

## Risks
- Learn levels are server-side and the guides disagree: mitigated by alternatives on each step, the
  live colour and "not learned" handling in the trace, and the trainer check in `/codex debug`.
- Forever's crafting window and profession APIs are unconfirmed: the finder tries several ways and
  the tab works without any of them (skill from the skill list, or "unknown").
- Imperial Plate quests may still need 265 skill: the 245-272 step's alternative names the vendor
  plans (Magnus Frostwake, Western Plaguelands).
