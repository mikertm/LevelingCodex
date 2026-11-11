# 2026-11-10: Horde Skyborne (Windshaper) start

## Sources

- RestedXP Forever "1-9 Zephras Isle" and "9-13 Zephras Isle" chapters (`Guides/forever/RestedXP-Skyborne.lua`). One chapter serves both factions with `<< Horde` / `<< Alliance` step filters. We used its Horde path for which quests the Windshapers take and in what order. The text is ours.
- QuestieDB Forever for quest givers, positions, levels and objectives.
- Web sources:
  - [Warcraft Tavern: Zephras Isle walkthrough](https://www.warcrafttavern.com/forever/guides/zephras-isle-walkthrough/)
  - [warcraft.wiki.gg: Skyborne starting experience](https://warcraft.wiki.gg/wiki/Skyborne_starting_experience) (The Gift of Skysight as the Horde counterpart of Reading the Leylines; the Shaman totem quests)
  - [Warcraft Tavern: Skyborne race overview](https://www.warcrafttavern.com/forever/guides/skyborne/) (Windshaper classes: Druid, Hunter, Rogue, Shaman, Warrior)

## How it is built

`QuestHordeSkyborne.lua` (loaded after the Tirisfal file, before the Barrens) adds the sections `zephras` (Thendal Grove, 1-5), `shendar` (Shen'dar Village, 5-9) and `valanaar` (Valanaar, 9-12) to the Horde route, with `start = "SKYBORNE"` and `route.starts.SKYBORNE = "zephras"`.

- **Shared quests.** Both factions share most of the island. The Horde sections copy the Alliance Zephras steps (`LevelingCodexQuests.build.zi` from QuestData.lua) for every quest that isn't Alliance-only. Shared quests keep the same, already-reviewed text.
- **Alliance-only quests dropped.** A list in the file names them, and they are removed from the copies:
  - the High Order chain (Welcome to Shen'dar Village 93461, The High Order, A Magical Affront);
  - the Valanaar story that ends on the skycutter to Dalaran (Supreme Magister, Missing Scholar, Catching Wind, Tower Defense through The Fate of Zephras);
  - Standing Our Ground, Bugged, Unwelcome Visitors and the Mage quests. Windshapers can't be Mages.
- **Prerequisites remapped.** On shared quests, Alliance prerequisites point to their Windshaper counterparts:
  - 93461 → 92514
  - 92596 → 92595
  - 94413 → 94411
  - 92701 → 92579
  - 92699 → 92700
- **Windshaper quests added:**
  - Thendal Grove:
    - The Gift of Skysight 92598 (Ventaari Brightwish): use Skysight at the Elemental Convergence.
    - Shamans: Embracing the Elements 92484, then Call of Earth 92466-92468 with Windshaper Boro and the Rise of Spirits.
  - Shen'dar Village: Welcome to Shen'dar Village 92514, The Windshapers 92595 and Meddlesome Mages 94411 (Illaya Amberwind; High Order Apprentices north of the village).
  - Valanaar:
    - To Valanaar 92579, The Grand Skyseer 92700, and The Broken Construct 93735, 93737 (four parts: Riaani, the Shriekling Den, Windsong Lake, the bandit camp) and 93738.
    - Shamans: Call of Fire 97243-97257 (Sessaria, Olariaan, Faladiel, Kuramaa, the brazier).
- **Leaving the island:** the Windshaper airship from Valanaar to northern Mulgore, then:
  - Welcome to Azeroth 95350 from Alaana Stormwalker.
  - Druids: Child of Nature 94911 to Turak in Thunder Bluff.
  - Thunder Bluff and Orgrimmar flight paths.
  - Thrall gives Journey to the Crossroads 98024, which Thork takes in the Barrens route's first section.
- **Trainers:** the Alliance lists plus Shamans: Windshaper Boro in Thendal Grove and Aarnor Galestrike in Shen'dar. No Shaman trainer is confirmed in Valanaar.

## Left out

- **A Grand Adventure 92708:** RestedXP takes it but has its turn-in commented out.
- **Unwelcome Spirits 93736:** commented out in RestedXP.
- **Deliver the News 92703:** its prerequisite is the Alliance-only Standing Our Ground.
- **The Camping 101 crafting intros:** only Cooking and the three gathering lessons (optional) are in, as on the Alliance side.
- **Orgrimmar's Meal Appeal errands** for Skyborne: not added yet.
- **Moonglade 94913** for Druids: left for the class-quest pass.

## Things to check in game

- The airship dock position in Valanaar (57.9, 80.8) and where it lands in Mulgore (Alaana Stormwalker at 33.4, 22.5).
- That The Gift of Skysight completes at 48.4, 20.4, and that Windshapers get no Reading the Ley Lines.
- That shared quests in Shen'dar (The Criminal Element and the rest) open after Welcome to Shen'dar Village 92514.
- The Earth Sapta item for Call of Earth (6635 assumed, as in Durotar).
- The Orgrimmar west gate route to the Crossroads.
