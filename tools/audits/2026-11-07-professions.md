# Profession guide audit, 7 Nov 2026 (WoW: Forever build 1.60.1.70862)

Every fact in `ProfessionData.lua` (Mining and Blacksmithing 1-300) checked for accuracy, and every
change it led to. Use it for the profession page on the site, and re-check the open questions in game.

## How it was checked

1. **The game's own tables** (wago.tools, product `wowf`): recipe colours, reagents, products, icons,
   plans, learned-with-the-profession, points per craft, camp object descriptions, the forge a smelt
   needs, tier caps. The harness enforces the recipe fields on every run.
2. **Wowhead Forever** pages read in a browser (trainer lists and "Requires Blacksmithing (N)" come
   from the live servers): 18 recipe spells, the Imperial Plate quests, Derotain Mudsipper, the vein
   objects with their zone counts, the Bold Dirk plan.
3. **Forever guides** where Wowhead has no answer: wow-professions.com/forever (trainers, mining
   changes), warcraft.wiki.gg (Forever mining, Heavy Thorium Ore, Rock Garden, Molten Foundry),
   conquestcapped, wow.gg, zockify. Classic Era pages only where nothing Forever-specific exists, and
   marked "in Classic".

## A bug in the checker itself

`tools/gamedata.py` never linked a recipe to its plan: Forever's plan items name their recipe in an
item effect with trigger type 6, and the tool looked for a learn-spell effect on the plan's use spell.
**0 of 486** Blacksmithing recipes had a plan in the reference; now 363 do (and Mining's two
blueprints). The audit now also warns when a "trainer" step's recipe comes from a plan, and when a
step's learn level differs from its plan's skill. Neither fires on the route: the Imperial Plate plans
ask for exactly 240 / 245 / 270 / 280.

Also added to the reference and audited: `auto` (learned with the profession: Rough Sharpening Stone,
Rough Weightstone, Copper Bracers, Copper Rod, Rough Copper Vest, Smelt Copper) and `skillups` (points
per craft when not 1: none in Mining or Blacksmithing, so the craft counts hold).

## Confirmed (no change)

- **All recipe numbers in the text** (25 values): every "orange until", "yellow until", material list
  and product count in the notes and alternatives matches the game (Iron Buckle makes 2, Smelt Bronze
  makes 2, Mithril Coif 10 Mithril Bar + 6 Mageweave Cloth, and so on).
- **Training tiers**: skill 50 / 125 / 200 and level 10 / 20 / 35 (one Wowhead table says Artisan 225;
  its own leveling guide and every other source say 200). Caps 150 / 225 / 300 are in the game files.
- **Learn levels** that Wowhead's trainer data matches: Rough Grinding Stone 25, Heavy Grinding Stone 100,
  Iron Buckle 125, Green Iron Bracers 140, Golden Scale Bracers 160, Heavy Mithril Gauntlet 180,
  Breastplate 205, Boots 210, Dense Sharpening Stone 225; every smelt (Copper 1 ... Azerothium 275).
- **Imperial Plate**: Derotain Mudsipper in Tanaris; the quests take 20 / 20 / 40 / 60 Thorium Bars
  (140 in all) and nothing else; Imperial Plate Chest is his plan too (its quest takes 60).
- **Ebon Shiv and Ornate Thorium Handaxe** plans are sold by Magnus Frostwake, Western Plaguelands.
- **Vein skills** 1 / 65 / 75 / 125 / 155 / 175 / 230 / 230 / 245 / 275 and the colour rule (orange to
  +25, yellow to +50, green to +100); Copper is the only ore on Zephras Isle (its biggest Copper zone).
- **Camp objects**: Lodestone 20, Rock Garden 140 (blueprint), Molten Foundry 300 (blueprint); the Molten
  Foundry is the forge Smelt Heavy Thorium needs (game files). Smelting gives points until 185.
- Strong Flux from the supply vendor next to the trainer; Steel Bar from Smelt Steel (165) or bought;
  Dense Stone from Small Thorium Veins; Silver Skeleton Key takes a Rough Grinding Stone.

## Changes

### Blacksmithing

- **Journeyman trainers**: not every capital trainer teaches it. The "Journeyman Blacksmith" NPCs only
  teach Apprentice recipes, and Darnassus has none.
  - before: `"Blacksmithing trainers in the capitals"`
  - after: `"An Expert Blacksmith trainer: Therum Deepforge (Stormwind), Rotgath Stonebeard (Ironforge), Clarise Gnarltree (Duskwood), Snarl (Orgrimmar), Karn Stonehoof (Thunder Bluff), James Van Brunt (Undercity) or Traugh (The Barrens)"`
- **Expert trainers**: Alard Schmied and Brikk Keencraft teach it too.
  - before: `"Bengus Deepforge (Ironforge) or Saru Steelfury (Orgrimmar)"`
  - after: `"Bengus Deepforge (Ironforge), Saru Steelfury (Orgrimmar), Alard Schmied (Alterac Mountains) or Brikk Keencraft (Booty Bay)"`
- **Artisan**: `", the only Artisan trainer"` added.
- Each tier also has a `short` text for the one-line banner rows (the full `where` stays in the tab and
  chat), e.g. Expert: `"Bengus Deepforge, Saru Steelfury, Alard Schmied, Brikk"`; Mining: `"Any Mining
  trainer outside the starting areas"`.
- **Sources** (Wowhead's trainer lists):
  - Rough Bronze Leggings, Heavy Grinding Stone, Iron Buckle, Bronze Warhammer: `"Blacksmithing trainer"` ->
    `"Blacksmithing trainer tagged Expert Blacksmith or higher (not the Journeyman Blacksmith NPCs)"`
  - Green Iron Bracers, Golden Scale Bracers, Heavy Mithril Gauntlet (both steps): -> `"Expert trainers:
    Bengus Deepforge (Ironforge), Saru Steelfury (Orgrimmar), Alard Schmied (Alterac Mountains), Brikk Keencraft (Booty Bay)"`
  - Heavy Mithril Breastplate, Dense Sharpening Stone, Heavy Mithril Boots: -> `"Brikk Keencraft, Booty Bay (the only trainer for it)"`
- **185-200 note**: Brikk alone teaches the next three recipes, so a player who trains Artisan and leaves
  has to come back twice.
  - before: `"Train Artisan Blacksmithing (skill 200, level 35) in Booty Bay before 225."`
  - after: `"Train Artisan (skill 200, level 35) from Brikk Keencraft in Booty Bay. Only he teaches the next recipes (205, 210, 225): bring the materials and level 200-240 there."`
- **Learn levels** (Wowhead's trainer data, where the game files set none):
  - Copper Chain Belt: `35` -> `30`
  - Bronze Warhammer: `125` -> `100`
- **Imperial Plate quests need character level 50** (Wowhead Forever: "Requires level 50"):
  - all four sources: `"Quest plan from Derotain Mudsipper, Tanaris (the quest takes N Thorium Bar)"` ->
    `"... Tanaris (level 50; the quest takes N Thorium Bar)"`
  - 240-245 note: `"The next three plans come from Derotain too."` -> adds `"His quests need level 50 (in
    Classic also 265 Blacksmithing): if he won't give them yet, use the alternatives."`
  - 235-240 note: adds `"and need level 50"`.
- **245-272 alternative**: the plan levels and a way past 270 without the quests (Wowhead's own route).
  - before: `"Ebon Shiv or Ornate Thorium Handaxe, plans from Magnus Frostwake (Western Plaguelands), if the quests need more skill"`
  - after: `"Without the quests: Ebon Shiv (plan from Magnus Frostwake, Western Plaguelands, 230) to 270, then Bold Dirk (plan from Pexmit, Mount Hyjal, 270)"`
- **Specialization note**: the trainer names were disputed (Bengus Deepforge in a beta post, Myolor
  Sunderfury in Classic); the level is confirmed.
  - before: `"Armorsmith or Weaponsmith opens at 200 and level 40 (Bengus Deepforge or Krathok Moltenfist). It doesn't change this route."`
  - after: `"Armorsmith or Weaponsmith opens at level 40 (in Classic also skill 200), with the quests The Art of the Armorsmith and The Way of the Weaponsmith. It doesn't change this route."`
- Smaller text fixes:
  - Heavy Grinding Stones: "or buy them" -> "or buy them at the Auction House" (no vendor sells them).
  - Green Dye: "trade supply vendors" -> "trade and leatherworking supply vendors".
  - Strong Flux: "Blacksmithing supply vendors" -> "the Blacksmithing supply vendor next to the trainer".
  - Dense Sharpening Stone: "Yellow from 230." -> "Yellow from 230, green from 232."
  - Mithril Coif alternative: "if your trainer teaches it by 210" -> "Brikk Keencraft, 205".
  - Patterned Bronze Bracers alternative: "the client says learned at 120" -> "learned at 95, or 120 by the client's files".

### Mining

- **Journeyman, Expert and Artisan trainers**: every full Mining trainer teaches all ranks, not only in
  the capitals (16 of them); only the six Junior trainers in the starting areas stop at 75.
  - before: `"Mining trainers in the capitals"` (Artisan: `", or Pikkle in Tanaris"`)
  - after: `"Any Mining trainer outside the starting areas (the capitals, Razor Hill, Thelsamar, Auberdine, Darkshire, Gadgetzan, Zephras Isle)"`
- **Zones**, now ordered by Wowhead Forever's node counts:
  - Mithril Deposit: Felwood removed (no nodes); Azshara (84), Desolace (80), Stranglethorn Vale (61),
    Feralas (56) added; Burning Steppes (41) dropped from the short list.
  - Truesilver Deposit: Felwood removed; Winterspring (114), Eastern Plaguelands (85), Un'Goro (81),
    Azshara (80) added.
  - Dark Iron Deposit: Burning Steppes added first (115 nodes, the most).
  - Copper: Redridge Mountains (137) added for the Alliance.
  - Tin: Ashenvale (104, the most) for both factions, Loch Modan (Alliance), Thousand Needles (Horde).
  - Silver: Arathi Highlands (147, the most) for both; Thousand Needles (Horde).
- **275-300 note**: sources found.
  - before: `"Rich Thorium Veins from 275. Pitchblende and Heavy Thorium Ore have no confirmed source yet."`
  - after: `"Rich Thorium Veins from 275. Thorium veins sometimes give Pitchblende (Smelt Azerothium). At 300: Heavy Thorium Veins in Mount Hyjal."`
- **Camp objects**:
  - Lodestone: "players near your campfire" -> "players sitting at your campfire (not with Blessing of
    Might)" (the spell's own text).
  - Rock Garden: source -> "Blueprint: Rock Garden, from the Relic Guardian in Excavation Site: Wetlands";
    text adds "and gives the Lodestone's attack power".
  - Molten Foundry: source adds "(where it drops isn't known yet)"; text adds the Lodestone bonus.

## Follow-up audit, 8 Nov 2026

- Smelt Gold turns yellow at 170, green at 177 and grey at 185. The Mithril step now keeps the recipe in the crafting hint until grey. Thelgen Rock in the Wetlands is listed as an early Tin and Incendicite route. [Icy Veins Mining](https://www.icy-veins.com/wow-forever/mining-leveling-guide)
- WoW-Professions reports skill-only Mining ranks. Published guides disagree on character levels, so the existing reminder thresholds are provisional. Check a full trainer at 50, 125 and 200 skill below the displayed character levels. [WoW-Professions trainers](https://www.wow-professions.com/forever/mining-trainers) and [60.tools Mining](https://www.60.tools/guides/mining-leveling-guide)
- Daeann Steelwind in Valanaar teaches Journeyman Blacksmithing. The Iron Buckle step now spells out the tradeoff between its green points and the orange Bronze Warhammer alternative. [Wowhead Zephras Isle overview](https://www.wowhead.com/forever/guide/zephras-isle-zone-overview)
- Check A Blue Light Bargain at skill 240 and level 50 before buying materials for Imperial Plate. Ebon Shiv can take the player to 270 if the quests are locked. Equip Spectral Essence to see Magnus Frostwake in Caer Darrow. Bold Dirk from Pexmit in Mount Hyjal can take the player from 270 to 300. [WoW-Professions vendor guide](https://www.wow-professions.com/forever/npc/magnus-frostwake) and [Wowhead Bold Dirk](https://www.wowhead.com/forever/spell=1252365/bold-dirk)
- Added Sharpening Wheel at 20 (trainer), Anvil at 140 (Gilnid in The Deadmines), and Master Forge at 300 (blueprint drop source unconfirmed). [Wowhead camp guide](https://www.wowhead.com/forever/guide/camping-overview-unlock-rewards) and [Blueprint: Anvil](https://www.wowhead.com/forever/item=273086/blueprint-anvil)

## Still open (check in game)

- **Learn levels the sources disagree on**: Runed Copper Belt (game files 80, Wowhead 45), Rough Bronze
  Leggings (95 / 80), Patterned Bronze Bracers (120 / 95). The route uses the higher values, so it
  works either way. Visit a Blacksmithing trainer and run `/codex debug`: it lists the real values.
- **Derotain's skill requirement**: the quests need level 50; whether they still need 265 Blacksmithing
  (Classic) is unconfirmed. If he won't give the belt quest at 240, the alternatives cover 240-300.
- **No trainer-only route past 260**: every trainer recipe above 240 goes grey by 260, so 260-300 needs
  plans (Derotain's quests or the vendor plans). The owner chose to keep the quests (7 Nov); the
  vendor plans (Ebon Shiv, then Bold Dirk) stay as the 245-272 alternative.
- **Imperial Plate Gauntlets** (new in Forever, plan at 255, 24 Thorium Bar + 1 Star Ruby): no known
  source yet, and not one of Derotain's quests.
- **Molten Foundry blueprint**: no known source yet.
