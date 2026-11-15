-- Horde class quests through level 30: Warrior and Paladin. Source notes: tools/audits/2026-11-10-horde-class-*.md.
local B = LevelingCodexQuests.build
local route = LevelingCodexQuests.HORDE

-- Warrior: Defensive Stance, the Field of Giants trial and the Brutal armor, Berserker Stance.
-- Undead warriors get Defensive Stance inline in Brill (1818-1820, QuestHordeTirisfal.lua); the
-- Barrens referral 1505 is exclusive with it. Skyborne get it from The Skybreaker Bulwark (94003)
-- in Valanaar, copied from the Alliance Zephras steps.
do
  local M, at, q, only = B.maps, B.at, B.q, B.only
  local accept, finish, goal, withItem, action = B.accept, B.finish, B.objectiveAt, B.withItem, B.action
  local warrior = "WARRIOR"
  local orc, troll, tauren, undead, skyborne = "ORC", "TROLL", "TAUREN", "SCOURGE", "SKYBORNE"
  local kalimdor = { orc, troll, tauren }
  local wetlands = M.wetlands
  route.extents[wetlands] = route.extents[wetlands] or { 4135.417, 2756.25 }
  route.flightNetwork[wetlands] = route.flightNetwork[wetlands] or 2

  local sources = {
    "https://www.icy-veins.com/wow-forever/warrior-class-quests",
    "https://questing.wiki/wow-forever/classes/warrior/",
  }
  local function w(id, name, level, min, prev, race)
    q(id, name, level, min, prev, nil, warrior)
    B.quest[id].race = race
  end

  -- Defensive Stance and Forged Steel (Orc, Troll, Tauren)
  local tarshaw = at("Tarshaw Jaggedscar", 54.19, 42.47, M.durotar)
  local krang = at("Krang Stonehoof", 48.35, 63.74, M.mulgore)
  local uzzek = at("Uzzek", 61.38, 21.12, M.barrens)
  local thungrim = at("Thun'grim Firegaze", 57.23, 30.34, M.barrens)
  B.quest[1505].race = kalimdor
  w(1498, "Path of Defense", 10, 10, 1505, kalimdor)
  w(1502, "Thun'grim Firegaze", 10, 10, 1498, kalimdor)
  w(1503, "Forged Steel", 10, 10, 1502, kalimdor)
  B.hordeSide({ id = "warrior-defense-barrens", title = "Warrior: Defensive Stance (Barrens)", zone = M.barrens,
    levels = { 10, 12 }, class = warrior, start = kalimdor, sources = sources, steps = {
      only(accept(1505, tarshaw, "At level 10, take Veteran Uzzek from Tarshaw, the warrior trainer in Razor Hill. Sorek in Orgrimmar offers it too."),
        { race = { orc, troll } }),
      only(accept(1505, krang, "At level 10, take Veteran Uzzek from Krang Stonehoof, the warrior trainer in Bloodhoof Village."),
        { race = tauren }),
      finish(1505, uzzek, "Uzzek stands at Far Watch Post, on the Barrens side of the river west of northern Durotar."),
      accept(1498, uzzek),
      goal(1498, at(nil, 41.0, 26.5, M.durotar),
        "Cross the bridge back into Durotar and climb Thunder Ridge to the north. Kill Lightning Hides and Thunder Lizards for their scales.",
        "5 Singed Scales"),
      finish(1498, uzzek, "Bring the scales to Uzzek to learn Defensive Stance."),
    } })
  B.hordeSide({ id = "warrior-forged-steel", title = "Warrior: Forged Steel", zone = M.barrens,
    levels = { 10, 14 }, class = warrior, start = kalimdor, sources = sources, steps = {
      accept(1502, uzzek, "After Path of Defense, Uzzek sends you to Thun'grim Firegaze."),
      finish(1502, thungrim, "Thun'grim camps on top of the hills east of the Crossroads. The path up starts on their north side."),
      accept(1503, thungrim),
      goal(1503, at("Stolen Iron Chest", 55.0, 26.7, M.barrens),
        "Walk northwest to the Razormane camp on the same hills. Fight past the quilboar and loot the grey chest.",
        "Forged Steel Bars"),
      finish(1503, thungrim, "Return to Thun'grim and choose a weapon you can use."),
    } })

  -- Agamand Heirlooms (Undead): Coleman's follow-ups to the inline stance quests.
  local coleman = at("Coleman Farthing", 61.72, 52.29, M.tirisfal)
  w(1821, "Agamand Heirlooms", 11, 10, 1820, undead)
  w(1822, "Heirloom Weapon", 11, 10, 1821, undead)
  B.hordeSide({ id = "warrior-agamand-heirlooms", title = "Warrior: Agamand Heirlooms", zone = M.tirisfal,
    levels = { 10, 13 }, class = warrior, start = undead, sources = sources, steps = {
      accept(1821, coleman, "After Speak with Coleman, Coleman Farthing in the Brill tavern asks for the Agamand family weapons."),
      goal(1821, at("Agamand Family Crypt", 52.2, 26.4, M.tirisfal),
        "Go north past Agamand Mills to the family crypt in the hills. Clear the undead inside and loot the axe, sword, mace and dagger from the four weapon racks.",
        "Agamand Family Axe", "Agamand Family Sword", "Agamand Family Mace", "Agamand Family Dagger"),
      finish(1821, coleman),
      accept(1822, coleman),
      finish(1822, coleman, "Talk to Coleman again and choose a weapon you can use."),
    } })

  -- Trial at the Field of Giants, then the Brutal armor from Thun'grim (all Horde races).
  local sorek = at("Sorek", 80.39, 32.38, M.orgrimmar)
  local ruga = at("Ruga Ragetotem", 44.67, 59.42, M.barrens)
  w(1823, "Speak with Ruga", 20, 20)
  w(1824, "Trial at the Field of Giants", 20, 20, 1823)
  w(1825, "Speak with Thun'grim", 20, 20, 1824)
  B.hordeSide({ id = "warrior-field-of-giants", title = "Warrior: Trial at the Field of Giants", zone = M.barrens,
    levels = { 20, 22 }, class = warrior, sources = sources, steps = {
      accept(1823, sorek, "At level 20, take Speak with Ruga from Sorek, the warrior trainer in Orgrimmar's Valley of Honor."),
      finish(1823, ruga, "Ruga Ragetotem is in a hut at Camp Taurajo in the southern Barrens."),
      accept(1824, ruga),
      goal(1824, at(nil, 46.5, 70.5, M.barrens),
        "Ride south from Camp Taurajo to the Field of Giants. Kill silithid for their antennae. The antennae decay after 15 minutes, so return quickly.",
        "5 Twitching Antennae"),
      finish(1824, ruga),
      accept(1825, ruga),
      B.taxi("fly", at("Devrak", 51.5, 30.34, M.barrens), "Crossroads, The Barrens",
        "Fly from Camp Taurajo to the Crossroads."),
      finish(1825, thungrim, "Climb the hills east of the Crossroads to Thun'grim Firegaze."),
    } })

  w(1838, "Brutal Armor", 30, 20, 1825)
  w(1848, "Brutal Hauberk", 30, 20, 1838)
  B.hordeSide({ id = "warrior-brutal-hauberk", title = "Warrior: Brutal Hauberk", zone = M.barrens,
    levels = { 25, 30 }, class = warrior, sources = sources, steps = {
      accept(1838, thungrim, "After Speak with Thun'grim, ask him about the Brutal Armor. Keep his notes; the materials take a few trips."),
      goal(1838, nil,
        "Kill Windshear kobolds at Windshear Crag in eastern Stonetalon for 15 Smoky Iron Ingots. Kill Hillsbrad Miners in the Azurelode Mine in Hillsbrad for 10 Powdered Azurite. Buy or smelt 10 Iron Bars. Loot the Vial of Phlogiston from Roogug in Razorfen Kraul with a group.",
        "15 Smoky Iron Ingots", "10 Powdered Azurite", "10 Iron Bars", "Vial of Phlogiston"),
      finish(1838, thungrim),
      accept(1848, thungrim),
      finish(1848, thungrim, "Collect the Brutal Hauberk from Thun'grim."),
    } })

  local ulaelek = at("Ula'elek", 56.31, 74.33, M.durotar)
  local orm = at("Orm Stonehoof", 38.99, 55.98, M.thunderBluff)
  local velora = at("Velora Nitely", 62.14, 39.14, M.undercity)
  w(1839, "Ula'elek and the Brutal Gauntlets", 30, 20, 1838)
  w(1842, "Satyr Hooves", 30, 20, 1839)
  w(1843, "Brutal Gauntlets", 30, 20, 1842)
  w(1840, "Orm Stonehoof and the Brutal Helm", 30, 20, 1838)
  w(1844, "Chimaeric Horn", 30, 20, 1840)
  w(1845, "Brutal Helm", 30, 20, 1844)
  w(1841, "Velora Nitely and the Brutal Legguards", 30, 20, 1838)
  w(1846, "Dragonmaw Shinbones", 30, 20, 1841)
  w(1847, "Brutal Legguards", 30, 20, 1846)
  B.hordeSide({ id = "warrior-brutal-gauntlets", title = "Warrior: Brutal Gauntlets", zone = M.durotar,
    levels = { 28, 30 }, class = warrior, sources = sources, steps = {
      accept(1839, thungrim, "After Brutal Armor, take Thun'grim's referral to Ula'elek."),
      finish(1839, ulaelek, "Ula'elek is at Sen'jin Village in southern Durotar."),
      accept(1842, ulaelek),
      goal(1842, at(nil, 78.4, 45.5, M.ashenvale),
        "In eastern Ashenvale, kill Xavian satyrs in the camps north of the road to Satyrnaar for their hooves.",
        "7 Uncloven Satyr Hooves"),
      finish(1842, ulaelek),
      accept(1843, ulaelek),
      finish(1843, ulaelek, "Collect the Brutal Gauntlets from Ula'elek."),
    } })
  B.hordeSide({ id = "warrior-brutal-helm", title = "Warrior: Brutal Helm", zone = M.thunderBluff,
    levels = { 28, 30 }, class = warrior, sources = sources, steps = {
      accept(1840, thungrim, "After Brutal Armor, take Thun'grim's referral to Orm Stonehoof."),
      finish(1840, orm, "Orm Stonehoof is on the central mesa of Thunder Bluff."),
      accept(1844, orm),
      goal(1844, at("Chimaera Matriarch", 33.6, 74.7, M.stonetalon),
        "In the Charred Vale of southwestern Stonetalon, kill the Chimaera Matriarch for her horn. She is level 28 and hits hard.",
        "Galvanized Horn"),
      finish(1844, orm),
      accept(1845, orm),
      finish(1845, orm, "Collect the Brutal Helm from Orm."),
    } })
  B.hordeSide({ id = "warrior-brutal-legguards", title = "Warrior: Brutal Legguards", zone = M.undercity,
    levels = { 28, 30 }, class = warrior, sources = sources, steps = {
      accept(1841, thungrim, "After Brutal Armor, take Thun'grim's referral to Velora Nitely."),
      finish(1841, velora, "Velora Nitely is on the ring of the Undercity's Trade Quarter."),
      accept(1846, velora),
      goal(1846, at(nil, 47.0, 46.0, wetlands),
        "Go south from Arathi Highlands over Thandol Span into the Wetlands. Kill Dragonmaw orcs around Angerfang Encampment for their shinbones. Avoid Menethil Harbor.",
        "8 Sturdy Dragonmaw Shinbones"),
      finish(1846, velora),
      accept(1847, velora),
      finish(1847, velora, "Collect the Brutal Legguards from Velora."),
    } })

  -- Berserker Stance (level 30, every race).
  local torm = at("Torm Ragetotem", 57.24, 87.37, M.thunderBluff)
  local baltus = at("Baltus Fowler", 47.4, 17.29, M.undercity)
  local klannoc = at("Klannoc Macleod", 68.62, 49.16, M.barrens)
  w(1718, "The Islander", 30, 30)
  w(1719, "The Affray", 30, 30, 1718)
  B.hordeSide({ id = "warrior-berserker-stance", title = "Warrior: Berserker Stance", zone = M.barrens,
    levels = { 30, 30 }, class = warrior, start = { orc, troll, tauren, undead, skyborne },
    sources = {
      "https://db.icy-veins.com/wow-forever/quests/1719",
      "https://bindonforever.com/quest/1719",
    }, steps = {
      only(accept(1718, sorek, "At level 30, take The Islander from Sorek in Orgrimmar's Valley of Honor."), { race = { orc, troll, skyborne } }),
      only(accept(1718, torm, "At level 30, take The Islander from Torm Ragetotem, the warrior trainer on Hunter Rise in Thunder Bluff."), { race = tauren }),
      only(accept(1718, baltus, "At level 30, take The Islander from Baltus Fowler, the warrior trainer in the Undercity's War Quarter."), { race = undead }),
      action("goto", at(nil, 63.0, 38.0, M.barrens), "Travel to Ratchet on the Barrens coast, then follow the shore south toward the Merchant Coast."),
      finish(1718, klannoc, "Swim across the shallows to Fray Island and find Klannoc Macleod by the arena. Stay clear of Northwatch Hold on the shore."),
      accept(1719, klannoc, "Heal up first. You have 10 minutes for the fight and the turn-in."),
      goal(1719, at(nil, 68.6, 48.72, M.barrens),
        "Step on the grate north of Klannoc to start the Affray. Fight each challenger as it enters, then defeat Big Will. Stay inside the arena.",
        "Big Will slain"),
      finish(1719, klannoc, "Turn in The Affray to learn Berserker Stance and Intercept."),
    } })
end

-- Paladin (Undead only): Redemption at Bandarion Keep, then Lumina Windsinger and Wolfsbane.
-- The level 1-12 chain (A Difficult Path to A Token of Good Faith) is inline in Tirisfal.
do
  local M, at, q = B.maps, B.at, B.q
  local accept, finish, goal, withItem, action = B.accept, B.finish, B.objectiveAt, B.withItem, B.action
  local paladin, undead = "PALADIN", "SCOURGE"
  local function p(id, name, level, min, prev)
    q(id, name, level, min, prev, true, paladin)
    B.quest[id].race = undead
  end
  local sources = {
    "https://questing.wiki/wow-forever/classes/paladin/",
    "https://bindonforever.com/quest/94441",
  }

  local danitha = at("Danitha Morr", 22.09, 44.66, M.tirisfal)
  local tanis = at("Tanis Alderwood", 65.48, 37.49, M.undercity)
  local billmuth = at("Deathguard Billmuth", 21.92, 44.5, M.tirisfal)
  local falgan = at("Deathguard Falgan", 86.73, 47.72, M.tirisfal)
  local divinity = "A Lesson in Divinity"
  p(94427, divinity, 12, 12, 91317)
  p(94434, divinity, 12, 12, 94427)
  p(94435, divinity, 12, 12, 94434)
  p(94436, divinity, 12, 12, 94435)
  p(94438, divinity, 12, 12, 94436)
  p(94440, divinity, 12, 12, 94438)
  p(94441, divinity, 12, 12, 94440)
  B.hordeSide({ id = "paladin-redemption-undead", title = "Paladin: Redemption", zone = M.tirisfal,
    levels = { 12, 14 }, class = paladin, start = undead, sources = sources, steps = {
      accept(94427, danitha, "When you turn in The Tarnished, Danitha Morr upstairs in Bandarion Keep also offers A Lesson in Divinity."),
      finish(94427, tanis, "Bring 10 Linen Cloth. Tanis Alderwood is in the Undercity's Trade Quarter."),
      accept(94434, tanis),
      finish(94434, tanis, "Give Tanis 10 Linen Cloth. Buy some at the auction house if you are short."),
      accept(94435, tanis),
      action("goto", at(nil, 30.0, 48.0, M.tirisfal), "Leave the Undercity and take the road west past Deathknell to Bandarion Keep on the coast."),
      finish(94435, danitha),
      accept(94436, danitha),
      finish(94436, billmuth, "Deathguard Billmuth is in the keep beside Danitha."),
      accept(94438, billmuth),
      action("goto", at(nil, 80.0, 50.0, M.tirisfal), "Travel east across Tirisfal to Venomweb Vale, near the eastern edge of the map."),
      withItem(6866, finish(94438, falgan,
        "Find Deathguard Falgan's body in Venomweb Vale. Target him and use the Symbol of Life, then talk to him. Danitha replaces a lost Symbol.")),
      accept(94440, falgan),
      goal(94440, at(nil, 86.8, 43.4, M.tirisfal),
        "Kill Scarlet Friars and Zealots in the camp just north of Falgan until one drops the attack plans.",
        "Scarlet Crusade Attack Plans"),
      action("goto", at(nil, 30.0, 48.0, M.tirisfal), "Head back west across Tirisfal to Bandarion Keep."),
      finish(94440, billmuth),
      accept(94441, billmuth),
      finish(94441, danitha, "Speak with Danitha upstairs in the keep to learn Redemption."),
    } })

  -- Lumina Windsinger (Fenris Isle), then the Moonsilver Blade and Wolfsbane.
  local weaponSources = {
    "https://conquestcapped.com/guides/wow-forever/wow-forever-paladin-weapon-quest/",
    "https://bindonforever.com/quest/91858",
    "https://warcraft.wiki.gg/wiki/Lumina_Windsinger",
  }
  local trevan = at("Trevan Rol", 43.4, 41.1, M.silverpine)
  local baldren = at("Deathguard Baldren", 45.81, 41.88, M.silverpine)
  local remains = at("Charred Remains", 65.02, 34.1, M.silverpine)
  local luminaKeep = at("Lumina Windsinger", 65.55, 23.27, M.silverpine)
  local lumina = at("Lumina Windsinger", 43.4, 40.99, M.silverpine)
  local ott = at("Ott", 60.43, 26.18, M.hillsbrad)
  p(91858, "Diplomatic Incident", 22, 18)
  p(91859, "A Curious Pair", 22, 18, 91858)
  p(91860, "A Grim Fate", 22, 18, 91859)
  p(91861, "Into Fenris Keep", 22, 18, 91860)
  p(91862, "Lumina Windsinger", 22, 18, 91861)
  p(96204, "The Windshaper's Wrath", 22, 18, 91862)
  p(95034, "The Debt", 24, 18, 96204)
  B.hordeSide({ id = "paladin-lumina-windsinger", title = "Paladin: Lumina Windsinger", zone = M.silverpine,
    levels = { 19, 24 }, class = paladin, start = undead, sources = weaponSources, steps = {
      accept(91858, danitha, "From level 18, Danitha Morr upstairs in Bandarion Keep has a diplomatic errand in Silverpine."),
      finish(91858, trevan, "Trevan Rol, an Earthen Ring envoy, waits at the Sepulcher in Silverpine Forest."),
      accept(91859, trevan),
      finish(91859, baldren, "Deathguard Baldren stands at the Sepulcher's entrance."),
      accept(91860, baldren),
      finish(91860, remains, "Swim east across the lake to Fenris Isle. Click the Charred Remains on the southern shore."),
      accept(91861, remains),
      finish(91861, luminaKeep, "Enter Fenris Keep on the north of the isle and find Lumina Windsinger caged in the cellar."),
      accept(91862, luminaKeep),
      goal(91862, at(nil, 65.0, 24.5, M.silverpine),
        "Kill Rot Hide Gnolls in and around the keep until one drops the key, then use it on Lumina's cage.",
        "Fenris Isle Key"),
      finish(91862, luminaKeep),
      accept(96204, luminaKeep, "Heal up before accepting: gnolls attack during the escort."),
      goal(96204, luminaKeep, "Follow Lumina out of the keep to the shore and keep the gnolls off her.", "Escort Lumina Windsinger"),
      finish(96204, lumina, "Return to the Sepulcher. Lumina waits beside Trevan."),
      accept(95034, lumina),
      finish(95034, lumina),
    } })

  p(95036, "A Moon-Kissed Blade", 25, 20, 95034)
  p(95111, "An Underrated Talent", 25, 20, 95036)
  p(95125, "Ott's Masterwork", 25, 20, 95111)
  p(95126, "The Moonsilver Blade", 25, 20, 95125)
  p(95140, "Old Fire-Eye", 26, 20, 95126)
  B.hordeSide({ id = "paladin-wolfsbane", title = "Paladin: Wolfsbane", zone = M.silverpine,
    levels = { 24, 30 }, class = paladin, start = undead, sources = weaponSources, steps = {
      accept(95036, lumina, "After The Debt, Lumina asks for a blade. Trevan Rol gives you his weapon notes."),
      goal(95036, nil,
        "Lumber: loot Goblin Woodcarvers near Sneed in the Deadmines. Silver: kill Arugal at the end of Shadowfang Keep and take the ingot from the table in his room. Gem: take Ulric Frostveil's errand at Zoram'gar Outpost in Ashenvale first, kill naga outside Blackfathom Deeps for a Corrupted Kor Gem, and bring it back to Ulric to purify. Bring a group for the dungeons.",
        "Whitestone Oak Lumber", "Enchanted Silver Ingot", "Purified Kor Gem"),
      finish(95036, trevan),
      accept(95111, trevan),
      finish(95111, ott, "Take the materials to Ott, the blacksmith in Tarren Mill in Hillsbrad."),
      accept(95125, ott),
      goal(95125, ott, "Stay by the anvil and watch Ott forge the blade.", "Watch Ott forge your blade"),
      finish(95125, ott),
      accept(95126, ott),
      finish(95126, trevan, "Bring Ott's Masterwork back to Trevan at the Sepulcher for the Moonsilver Blade."),
      accept(95140, lumina, "Equip the Moonsilver Blade before you go. Old Fire-Eye is a level 25 elite worgen."),
      action("goto", at(nil, 47.5, 72.0, M.silverpine), "Follow the road south from the Sepulcher toward the Greymane Wall."),
      goal(95140, at("Old Fire-Eye", 48.9, 85.2, M.silverpine),
        "Go south to the Greymane Wall. Fight Old Fire-Eye with the Moonsilver Blade until its strikes burn away his shield, then finish him with Holy damage.",
        "Old Fire-Eye slain"),
      action("goto", lumina, "Ride back north along the road to the Sepulcher."),
      finish(95140, lumina, "Turn in to Lumina for Wolfsbane."),
    } })
end
