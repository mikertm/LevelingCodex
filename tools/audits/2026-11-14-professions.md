# Profession guide audit, 14 Nov 2026: all twelve guides against the current Forever guides

Game reference: build 1.60.1.70888 (the committed `tools/reference/forever.json`). The newer build
1.60.1.70938 (the unmerged `gamedata/1.60.1.70938` branch) changes no route recipe: it only moves
camp-object colours (Anvil, Sharpening Wheel and the other 20/140 camp recipes' greys), raises five
Tailoring bags' bolt counts (Nov 11 hotfix; none is on the route) and carries the Coarse Grinding
Stone (grey 90) and Tanning Rack (125) hotfixes into the client. After that branch merges, the
Tanning Rack exception in `gamedata.py` (`(125, 140)`) can go.

## Sources

- **Wowhead Forever** (read in a browser: WebFetch only gets the page shell): the Tried & Tested
  guides ([profession-leveling-guides](https://www.wowhead.com/forever/profession-leveling-guides),
  Blacksmithing updated 4 Nov, Alchemy 3 Nov, Leatherworking 4 Nov), the gathering overviews
  ([Herbalism](https://www.wowhead.com/forever/guide/professions/herbalism/overview-leveling) 9 Nov,
  Skinning 7 Nov, Fishing 10 Nov, [Cooking](https://www.wowhead.com/forever/guide/professions/cooking/overview-leveling) 14 Nov),
  spell taught-by lists, item and NPC pages.
- [wow-professions.com/forever](https://www.wow-professions.com/forever/) (trainer lists, camping guide;
  undated, "based on the beta"), [conquestcapped](https://conquestcapped.com/guides/wow-forever/wow-forever-profession-guides/) (8 Nov),
  [Method](https://www.method.gg/wow-forever/leatherworking-in-wow-forever-leveling-guide-and-trainers) (14 Nov),
  [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/profession-trainers/), [metabot](https://metabot.gg/en/wow-forever/professions/cooking),
  [timesaver](https://timesaver.gg/tools/wow-forever/professions/blacksmithing), wow.gg (Merchant's Favor).
- quest database Forever (`tools/questfacts.py --flavor forever quest N`) for quest requirements.
- Blizzard's [hotfix thread](https://us.forums.blizzard.com/en/wow/t/wow-forever-hotfixes-november-13-2026/2403040),
  Nov 5-13. New since the 11 Nov audit: Tailoring bags (Nov 11), Nyalah Brightfire's wider cooking
  stock and the Fishing Extravaganza winners (Nov 13). Nothing else touches a route.
- Not trusted: metabot and RankedBoost (generated from client or pre-launch data), wowcalc (Classic
  values), timesaver's vein zones, Wowhead's `/tailoring/overview` and `/engineering/overview`
  (redirect to MoP Classic pages), any page with beta colours for Raging Raptor Ribs.

Every recipe the changes add was checked with `python tools/gamedata.py recipes`, and `audit` reports
0 errors. New warnings, all expected: Heavy Mithril Boots green 6 of 11 points and Big Black Mace
green 4 of 4 (Blacksmithing 235-250 has no orange trainer recipe; Wowhead's route uses the same two),
and Elixir of Minor Fortitude's teaching item is a "Deprecated Recipe" in the client (Wowhead and
wow-professions both say the trainer teaches it).

## Decisions

- **Blacksmithing 240-300 (owner, 14 Nov):** quest database Forever gives A Blue Light Bargain (7652) and
  every Imperial Plate quest Blacksmithing 265 and level 50, and no source shows Derotain lower. The
  route now uses trainer recipes to 250 and Magnus Frostwake's Ornate Thorium Handaxe to 270, then
  Derotain's Boots and Leggings. The cheaper Belt and Bracers stay as the alternative for a player he
  does talk to before 265. Wowhead's own route (Arcanite Skeleton Keys, Ebon Shiv, 240 Azerothium
  Bars for Bold Dirks) costs far more.
- **Gathering colours:** Wowhead's Forever Herbalism overview (9 Nov) says Forever turns herbs green
  later, and its tables give every herb and every vein the same rule: orange to skill + 25, yellow to
  + 65 (Classic: + 50), green to + 100 (grey). Our Dreamfoil (yellow 290, green 315) didn't follow any
  rule; now 295 / 335.

## ProfessionData.lua changes (mirror into the guide pages)

### Blacksmithing

- **Journeyman `where`**: Alard Schmied (Dalaran) and Angus Hammerhand (Bandarion Keep, Tirisfal
  Glades) added (wow-professions and timesaver trainer lists). **Expert `where`** and the Expert
  sources: `Alard Schmied (Alterac Mountains)` -> `Alard Schmied (Dalaran)`.
- **`tools = { "Blacksmith Hammer" }`** on every smithed step (65 on; not the stones): the client gives
  every route recipe from Copper Chain Belt on the hammer as its tool. `gamedata.py audit` now checks
  Blacksmithing `tools` against the reference like Engineering's.
- **25-65 note**: `"The cheapest points up to 65. Keep a few for Silver Skeleton Keys."` -> `"The cheapest
  points up to 65. Buy a Blacksmith Hammer from a blacksmithing or trade supplies vendor now: every
  smithed item from 65 needs it, and an anvil."`
- **65-80 alt**: adds `", or Silver Skeleton Key (1 Silver Bar, 1 Rough Grinding Stone, orange until 75)"`
  (the key was mentioned but never used; Wowhead uses it at 75-80).
- **185-200 note**: `"(205, 210, 225): bring the materials and level 200-240 there."` -> `"(205, 210, 225,
  230): bring the materials and level 200-250 there."`
- **235-300**, before: Heavy Mithril Boots 235-240, Imperial Plate Belt 240-245, Bracers 245-272, Boots
  272-290, Leggings 290-300. After:
  - 235-246 Heavy Mithril Boots (learn 210, Brikk): "Yellow, then green from 240: some crafts give no
    point. Switch to Big Black Mace at 246."
  - 246-250 **Big Black Mace** (spell 10001, learn 230, Brikk, about 14 crafts): note says to buy
    Plans: Ornate Thorium Handaxe before 250 (Magnus Frostwake, Caer Darrow; Spectral Essence).
  - 250-270 **Ornate Thorium Handaxe** (spell 16969, plan 250, orange the whole step): make the Dense
    Grinding Stones from Dense Stone; at 265 and level 50 take A Blue Light Bargain from Derotain.
    Alt: Belt (240) and Bracers (245) if Derotain talks to you earlier; Ebon Shiv (orange to 255,
    Truesilver and Star Rubies).
  - 270-290 Imperial Plate Boots (source names A Blue Light Bargain: skill 265, level 50; 40 Thorium
    for the quest). Alt: the Handaxe stays orange to 275, then Bold Dirk with its materials (30
    Thorium, 10 Azerothium, 4 Essence of Air, 4 Rugged Leather each).
  - 290-300 Imperial Plate Leggings, unchanged but for the Bold Dirk alt naming Azerothium.
- **New `parts`**: Dense Grinding Stone (4 Dense Stone, learn 225, Brikk) and Solid Grinding Stone
  (4 Solid Stone, learn 175), so the shopping list counts their stone and the crafting window makes
  them first. The audit asks for every reagent the profession makes.
- **Camp**: Sharpening Wheel source `"Blacksmithing trainer"` -> `"Blacksmithing trainer or Camping 101"`.
  Master Forge `"(drop source unconfirmed)"` -> `", reported from Golem Lord Argelmach (Blackrock Depths)"`
  (wow-professions camping guide; Wowhead's DB lists the same) and its materials.
- **notes[200]**: specialization at skill 200 and level 40 with the four quest givers (quest database Forever
  5283/5301/5284/5302): Grumnus Steelshaper and Ironus Coldsteel (Ironforge), Okothos Ironrager and
  Borgosh Corebender (Orgrimmar).

### Mining

- Full trainers (all three upper tiers): adds Kharanos (Yarr Hammerstone), Gol'Bolar Quarry (Dank
  Drizzlecut), The Sepulcher (Johan Focht) and Powderfuse Port, Riverglades (Grungle). Two sources.
- 1-65 note: a Mining Pick in your bags; Poor Copper Veins in the starting areas give points only to
  20; the junior trainers stop at 75.
- 175-245 note: Dark Iron Deposits (230) in Blackrock Depths and Searing Gorge; Smelt Dark Iron is
  taught in Blackrock Depths (The Spectral Chalice, quest database 4083) and works only at the Black Forge.
- Vein colour comment: yellow to + 65. `ns.profNodeColor`'s default for veins changed with it.
- Camp: Lodestone `"Mining trainer"` -> `"Mining trainer or Camping 101"`; Molten Foundry: "unconfirmed:
  Wowhead lists Ambassador Flamelash, Blackrock Depths" and its materials.
- Character-level gates stay unconfirmed (`levelGatesUnconfirmed`): wow-professions says there are none,
  nothing else says either way.

### Engineering

- Apprentice: the Strange Hermit's short talk before training opens. Journeyman: Finbus Geargrind
  (Darkshire, Duskwood) added.
- 1-30 note: where to buy the hammer on Zephras Isle (Aedi Thriceforged, Shen'dar Village).
- 160-175 note: keep five Explosive Sheep for Goblin Engineering. 195-200 note: keep six Mithril Tubes
  for Gnomish (was "or sell them").
- 175-190 note: `"Learn the Gyromatic Micro-Adjustor at 175 if another schematic needs it."` -> make one
  (4 Steel Bar, yellow until 195) and keep it: goggle schematics need it as a tool (client: 2 recipes).
- notes[200]: Gnomish or Goblin at skill 200 and level 30, with the trainers (quest database 3629-3643).
- Camp: Anarchist's Workbench "unconfirmed: Wowhead lists Ezra Grimm, Stratholme", and its materials
  (Essence of Anarchy, 2 Thorium Widgets: keep two).

### Tailoring

- **190-235**, before: Gloves 190-205, Headband 205-210, Bolt of Runecloth 210-212, Headband 212-225,
  Runecloth Belt 225-235. After: Gloves 190-205 (note: train Artisan with Timothy Worthington or Daryl
  Stack by 205 and learn the bolt and belt there), **Bolt of Runecloth 205-210** (learn 205, orange),
  **Runecloth Belt 210-235** (learn 210, orange to 225). Wowhead's taught-by lists now say Headband
  190, Bolt 205, Belt 210 (they said 205/210/225 on 7 Nov), and conquestcapped and wow-professions agree;
  only the two Artisan trainers teach them. Both steps keep the Headband as the alternative in case a
  trainer still asks for more. The bolt part's `learn` follows (210 -> 205).
- **235-280**: Gloves 235-260 -> 235-250, Cuffs 260-280 -> 250-280 (orange 250-265; conquestcapped and
  wow-professions switch at 250). The Cuffs alt keeps the Gloves to 260 for a player without the pattern.
- 235-250 alt: the Darnall patterns bind on pickup. 250-280 source: Pexmit's position (58.8, 41.8).
- **280-300 alt**: the Venomspew patterns need a Loom (client: spell focus "Loom" on all six), which
  needs Tailoring 300. Before: `"...then Venomspew Gloves to 290 and Venomspew Cord to 300..."`.
- Expert `where`: Melanori (Shen'dralas) added (Wowhead taught-by list).
- **New camp block** (Tailoring had none): Faction Banner (20, trainer or Camping 101), Spinning Wheel
  (140, Blueprint from the Unstable Sentinel, City of Dalaran), Loom (300, Blueprint from Baroness
  Anastari, Stratholme), with materials.

### Enchanting

- 20-90 alt: `"Lesser Magic Wand (10, no rod: ...)"` -> `"... with the Runed Copper Rod"` (the client
  gives both wands the Runed Copper Rod).
- 110-135 source: the formula is one in stock and binds on pickup: buy it on the enchanter.
- Expert: Melanie Sable moved from "Both" to Alliance (Wowhead's taught-by lists: Alliance only).
- Artisan: how Annora appears (clear her room between the Map Chamber and the Temple Hall, back
  entrance, bring a group).
- 1-2 note: where Motes are sold (capitals, Brill, Zephras Isle). Rod notes: the base rods come from a
  blacksmith or the auction house.
- 250-265 alt: Lesser Mana Oil formula also from Lokhtos Darkbargainer, tradable.
- Camp: Arcane Salvager from Shade of the Archmage (City of Dalaran) or Charlga Razorflank (Razorfen
  Kraul), with its materials; Arcane Forge "(source not known yet)" with its materials.

### First Aid

- 40-80 alt: Lesser Healing Potion (trainer at 55, orange to 85). 260-290 alt: Major Healing Potion from
  275 (Manual from Pexmit, 8g, or A Rest Without Pain; orange to 290, yellow to 300).
- Camp: Toxin Study's materials (Mageweave Bandages need 210); Plague Doctor's Laboratory from Doctor
  Theolen Krastinov (Scholomance) with its materials.

### Herbalism

- **Trainers**: every tier named only Tannysa and Jandi (from the spell taught-by lists). Wowhead's
  overview (9 Nov) lists 24 trainers who teach all four ranks: 12 Alliance, 8 Horde and 4 neutral
  (both Zephras Isle trainers, Flora Silverwind, Malvor). Apprentice: "Any Herbalism trainer,
  including the starting areas, or pick Wild Harvest". The upper tiers list the towns; short "Any town
  Herbalism trainer (not a starting area)".
- **Colours**: every herb's `green` is now skill + 65 (Peacebloom 50 -> 65 ... Black Lotus 350 -> 365);
  Dreamfoil yellow 290 -> 295. Greys unchanged.
- **Felwood** added to Arthas' Tears, Sungrass, Gromsblood, Golden Sansam, Dreamfoil, Mountain Silversage
  and Plaguebloom. 270-300 note: "Loop Eastern Plaguelands or Felwood", without "Published color cutoffs
  differ, so check the node tooltip."
- 170-205 note: Goldthorn Tea (+15 Herbalism for 15 minutes while well fed).

### Skinning

- Mendalass Tattermend (Shen'dar Village, Zephras Isle) added to the three upper tiers.
- 75-125 note: the Horde quest Unwelcome Guests can reward a Keen Skinning Knife (+3).
- 175-225 zones: Riverglades (lions and tallstriders on the plains).
- Camp: Trapper's Workbench `"Reported blueprint drop: Houndmaster Loksey ..."` -> `"(source not
  confirmed)"` (no source lists him) and its materials.
- notes[300]: Shaper's Terrace's Vitrix, Snowtalon and Cinder drop higher-level skinning materials (Nov 9).

### Leatherworking

- 265-300 note: drops "Forever's client lists 265." (Wowhead's tooltip, Method and wowforever.ninja agree).
  Alt adds Heavy Scorpid Helm from 285 (Zannok Hidepiercer, Cenarion Hold; Method's finish).
- Camp: Sewing Machine "unconfirmed: Wowhead lists Vectus, Scholomance", and its Undeath Engine.

### Alchemy

- **55-90**, before: Minor Mana Potion 55-90 (green 85-90), Elixir of Minor Fortitude as the alt. After:
  Minor Mana Potion 55-65, **Elixir of Minor Fortitude 65-90** (spell 2334, learn 50; orange to 80,
  yellow to 90), Minor Mana Potion as the alt. Wowhead and wow-professions both do this.
- Journeyman: Tally Berryfizz, Kylanna, Alchemist Narett, Bena Winterhoof, Serge Hinott and Jaxin Chong
  added. Expert: Linzy Blackbolt (Dalaran) added; short `"Ainethil, Linzy Blackbolt (Dalaran) or Dr. Halsey"`.
- Camp: Alchemy Laboratory "unconfirmed: Wowhead lists Ras Frostwhisper, Scholomance", with materials.

### Cooking

- 1-50 note: cooked food gives 5% more kill XP in Forever. 50-100 note: Nyalah Brightfire sells water
  and spices on Zephras Isle.
- 175-225 alt: Plain Ol' Paletusk (recipe 185, sold in Riverglades; orange to 200, yellow to 215).
  225-285 alt: Spotted Yellowtail (Gikkix, same colours as Tender Wolf Steak).
- Camp: Expert Campfire "unconfirmed: Wowhead lists Slavecrusher Grox"; Iron Oven from Quartermaster
  Zigris (Lower Blackrock Spire).
- Not taken: Raging Raptor Ribs (sources disagree with the client's colours).

### Fishing

- 150-225 note: the Aquadynamic Fish Attractor (+100 from 100).
- notes[225]: the Stranglethorn Fishing Extravaganza (Sundays 2-4 pm realm time; 40 Speckled Tastyfish
  to Riggle Bassbait; more winners since Nov 13).
- Camp: Fishing Hut "unconfirmed: Wowhead lists Jammal'an the Prophet, Sunken Temple".

## Code that changed with the data

- `ns.profNodeColor`: a vein's default yellow-to-green point is skill + 65.
- `gamedata.py audit`: Blacksmithing steps' `tools` must match the reference's `tool`.

## Check in game

1. Blacksmithing at 250-265: Magnus Frostwake sells Plans: Ornate Thorium Handaxe; Derotain offers A
   Blue Light Bargain at 265 (and whether he does at 240). Brikk teaches Big Black Mace (learn 230).
2. Tailoring at a Theramore or Tarren Mill trainer with `/codex debug`: Bolt of Runecloth at 205,
   Runecloth Belt at 210.
3. Herbalism: a Peacebloom at skill 50 shows yellow, at 65 green; a town trainer (Thelsamar, Brill)
   offers Journeyman; the Zephras Isle trainers offer Expert.
4. Alchemy at a trainer at 50: Elixir of Minor Fortitude is offered.
5. Enchanting: Melanie Sable won't train a Horde enchanter.
