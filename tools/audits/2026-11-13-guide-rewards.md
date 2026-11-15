# Guide reward lines (special chains and class quests)

Facts come from the guides' own step text first, then the audit notes under `tools/audits/`, then
the game reference (`tools/reference/forever.json` spell descriptions). Item types (shield, mail
chest, dagger, ...) come from the client item tables that `tools/gamedata.py` downloads
(`tools/.cache/1.60.1.70888/ItemSparse.csv` + `Item.csv`, cited as "item N"); they only confirm
the type of an item the guide already names, never which quest gives it. Lua line numbers are the
section line first, then the evidence line, as of commit 48c0950 (QuestSpecialData.lua already has
`reward = "A sleeping bag: rest in it for up to 3% bonus XP"` at line 67 there).

## Alliance special chains (QuestSpecialData.lua, 9)

| file | section id | title | reward line (or UNKNOWN) | evidence |
|---|---|---|---|---|
| QuestSpecialData.lua:29 | seeking-caitlin | Seeking Caitlin | Leads to Caitlin's Excavation Site dungeon quest | :36 "open the Excavation Site checklist for Caitlin's dungeon quest"; :28 breadcrumb to 95647 |
| QuestSpecialData.lua:66 | cozy-sleeping-bag | Cozy Sleeping Bag | A sleeping bag (up to 3% bonus XP) and a 12-slot bag | :97 "rest in it for 1% bonus experience per minute, up to 3%"; :84 "Old Toolbox, a 12-slot bag" (marked uncertain) |
| QuestSpecialData.lua:117 | legend-of-stalvan | The Legend of Stalvan | UNKNOWN | :155 finale turn-in to Madame Eva names no reward; audit 2026-11-09-special-quests.md silent |
| QuestSpecialData.lua:181 | missing-diplomat | The Missing Diplomat | UNKNOWN | :232 "for the final reward" (not named) |
| QuestSpecialData.lua:284 | onyxia-attunement | Drakefire Amulet (Onyxia's Lair) | The Drakefire Amulet: opens Onyxia's Lair | :310 "the Drakefire Amulet: it opens Onyxia's Lair" |
| QuestSpecialData.lua:316 | ubrs-seal | Seal of Ascension (Upper Blackrock Spire) | The Seal of Ascension: opens Upper Blackrock Spire | :329 "The Seal of Ascension opens Upper Blackrock Spire" |
| QuestSpecialData.lua:334 | molten-core-attunement | Attunement to the Core | Opens Molten Core; Lothos can teleport you straight in | :342 "Once attuned he can teleport you straight to Molten Core" |
| QuestSpecialData.lua:351 | scholomance-key | The Key to Scholomance | The Skeleton Key: opens Scholomance | :367 "the Skeleton Key. It opens Scholomance" |
| QuestSpecialData.lua:373 | shadowforge-key | Dark Iron Legacy (Shadowforge Key) | The Shadowforge Key: opens doors deep in Blackrock Depths | :383 "It opens the doors deeper in Blackrock Depths" |

## Horde special chains (QuestHordeDungeons4560.lua, 5)

| file | section id | title | reward line (or UNKNOWN) | evidence |
|---|---|---|---|---|
| QuestHordeDungeons4560.lua:828 | attunement-onyxia-horde | Blood of the Black Dragon Champion (Onyxia's Lair) | The Drakefire Amulet: opens Onyxia's Lair | :903 "the Drakefire Amulet: it opens Onyxia's Lair" |
| QuestHordeDungeons4560.lua:909 | ubrs-seal-horde | Seal of Ascension (Upper Blackrock Spire) | The Seal of Ascension: opens Upper Blackrock Spire | :927 "The Seal of Ascension opens Upper Blackrock Spire" |
| QuestHordeDungeons4560.lua:932 | molten-core-attunement-horde | Attunement to the Core | Opens Molten Core; Lothos can teleport you straight in | :941 "he can send you straight to Molten Core" |
| QuestHordeDungeons4560.lua:945 | shadowforge-key-horde | Dark Iron Legacy (Shadowforge Key) | The Shadowforge Key: opens doors deep in Blackrock Depths | :956 "It opens the doors deeper in the Depths" |
| QuestHordeDungeons4560.lua:977 | scholomance-key-horde | The Key to Scholomance | The Skeleton Key: opens Scholomance | :1018 "the Skeleton Key. It opens Scholomance" |

## Alliance class guides (QuestClassData.lua, 70)

| file | section id | title | reward line (or UNKNOWN) | evidence |
|---|---|---|---|---|
| QuestClassData.lua:118 | warrior-defense-human | Warrior: Defensive Stance (Human) | Teaches Defensive Stance, Taunt and Sunder Armor | :128 "learn Defensive Stance, Taunt and Sunder Armor" |
| QuestClassData.lua:130 | warrior-haggards-weapon | Warrior: Haggard's Weapon | A weapon of your choice from Marshal Haggard | :138 "choose a weapon you can use" |
| QuestClassData.lua:149 | warrior-defense-ironforge | Warrior: Defensive Stance (Ironforge) | Teaches Defensive Stance, Taunt and Sunder Armor | :157 "learn Defensive Stance, Taunt and Sunder Armor" |
| QuestClassData.lua:159 | warrior-grey-iron-weapons | Warrior: Grey Iron Weapons | A weapon of your choice from Tormus Deepforge | :169 "choose a weapon you can use" |
| QuestClassData.lua:180 | warrior-defense-nightelf | Warrior: Defensive Stance (Night Elf) | Teaches Defensive Stance, Taunt and Sunder Armor | :186 "learn Defensive Stance, Taunt and Sunder Armor" |
| QuestClassData.lua:188 | warrior-weapons-of-elunite | Warrior: Weapons of Elunite | An Elunite weapon of your choice | :198 "choose a weapon you can use"; items 6966-6969 Elunite Axe/Sword/Hammer/Dagger |
| QuestClassData.lua:209 | warrior-furens-favor | Warrior: Furen's Favor | Furen's Favor, a shield; opens Fire Hardened Mail | :219 "for Furen's Favor"; audit 2026-11-08-class-warrior-paladin.md:18 "The shield"; item 6970 shield; :207 1701 needs 1702 |
| QuestClassData.lua:221 | warrior-fire-hardened-mail | Warrior: Fire Hardened Hauberk | Fire Hardened Hauberk (mail chest); opens more armor | :229 "Collect the Fire Hardened Hauberk"; item 6972 mail chest; :246/:249/:252 coif/gauntlets/leggings need 1701 |
| QuestClassData.lua:255 | warrior-fire-hardened-coif | Warrior: Fire Hardened Coif | The Fire Hardened Coif, a mail helm | :265 "Collect the Fire Hardened Coif"; item 6971 mail head |
| QuestClassData.lua:267 | warrior-fire-hardened-gauntlets | Warrior: Fire Hardened Gauntlets | The Fire Hardened Gauntlets, mail gloves | :277 "Collect the Fire Hardened Gauntlets"; item 6974 mail hands |
| QuestClassData.lua:279 | warrior-fire-hardened-leggings | Warrior: Fire Hardened Leggings | The Fire Hardened Leggings, mail leg armor | :289 "Collect the Fire Hardened Leggings"; item 6973 mail legs |
| QuestClassData.lua:295 | warrior-berserker-stance | Warrior: Berserker Stance | Teaches Berserker Stance and Intercept | :309 "learn Berserker Stance and Intercept" |
| QuestClassData.lua:328 | paladin-redemption-human | Paladin: Redemption (Human) | Teaches Redemption: bring a dead player back to life | :352 "learn Redemption"; forever.json PALADIN Redemption desc |
| QuestClassData.lua:369 | paladin-redemption-dwarf | Paladin: Redemption (Dwarf) | Teaches Redemption: bring a dead player back to life | :393 "learn Redemption"; forever.json PALADIN Redemption desc |
| QuestClassData.lua:406 | paladin-sense-undead | Paladin: Sense Undead | Teaches Sense Undead, plus the Bastion of Stormwind shield | :419 "for Sense Undead and the Bastion of Stormwind"; item 9607 shield |
| QuestClassData.lua:421 | paladin-verigans-fist | Paladin: Verigan's Fist | Verigan's Fist, a two-handed mace | :435 "claim Verigan's Fist"; audit 2026-11-08-class-warrior-paladin.md:37 "mace (item 6953) ... 1806 reward"; item 6953 2H mace |
| QuestClassData.lua:450 | paladin-divine-storm-cloak | Paladin: Cloak of the Divine Storm | The Cloak of the Divine Storm | :474 "for the Cloak of the Divine Storm"; item 277205 cloak |
| QuestClassData.lua:495 | hunter-taming-dwarf | Hunter: Taming in Dun Morogh | Teaches Tame Beast and the basic pet commands | :510 "for Tame Beast and the basic pet commands" |
| QuestClassData.lua:522 | hunter-taming-human | Hunter: Taming in Elwynn | Teaches Tame Beast and the basic pet commands | :537 "for Tame Beast and the basic pet commands" |
| QuestClassData.lua:553 | rogue-blade-human | Rogue: Snatch and Grab | The Blade of Cunning, a dagger | :561 "for the Blade of Cunning"; item 7298 dagger |
| QuestClassData.lua:568 | rogue-blade-dun-morogh | Rogue: Road to Salvation | The Blade of Cunning, a dagger | :576 "for the Blade of Cunning"; item 7298 dagger |
| QuestClassData.lua:582 | rogue-blade-night-elf | Rogue: Destiny Calls | The Blade of Cunning, a dagger | :589 "for the Blade of Cunning"; item 7298 dagger |
| QuestClassData.lua:610 | rogue-lockpicking | Rogue: Lockpicking | UNKNOWN | :629 turn-in names no reward (the guide itself only levels Lockpicking on practice boxes) |
| QuestClassData.lua:640 | rogue-poisons | Rogue: Poisons and the Zanzil Cure | Teaches Poisons and Thistle Tea; cures Touch of Zanzil | :649 "unlocks Poisons and awards the Thistle Tea recipe"; :659 cure; audit 2026-11-08-class-hunter-rogue.md:37 |
| QuestClassData.lua:677 | rogue-horn-of-xelthos | Rogue: The Horn of Xelthos | The Pyrewood Signet Ring; opens The Eye of Bhossca | :691 "Collect the Pyrewood Signet Ring"; item 277210 ring; :722 78676 needs 78307 |
| QuestClassData.lua:697 | rogue-ravenholdt-manor | Rogue: Ravenholdt Invitation | UNKNOWN | :705 hand Fahrad the seal, no reward named; audit hunter-rogue.md:34 no reward |
| QuestClassData.lua:711 | rogue-syndicate-sabotage | Rogue: Syndicate Sabotage | UNKNOWN | :718 plain turn-in, no reward named |
| QuestClassData.lua:724 | rogue-eye-of-bhossca | Rogue: The Eye of Bhossca | The Ruby-Adorned Blade, a one-hand sword | :739 "Collect the Ruby-Adorned Blade"; item 277246 1H sword |
| QuestClassData.lua:762 (built at :750) | priest-garments-elwynn | Priest: Garments of the Light | Friar's Robes of the Light, a cloth robe | :758 "Return for your Friar's Robes of the Light"; item 16605 cloth robe |
| QuestClassData.lua:765 (built at :750) | priest-garments-dun-morogh | Priest: Garments of the Light | Friar's Robes of the Light, a cloth robe | :758 "Return for your Friar's Robes of the Light"; item 16605 cloth robe |
| QuestClassData.lua:808 | priest-divine-grace | Priest: Divine Grace | Teaches Divine Grace: instant heal for an ally under 50% | :811 "learn Divine Grace"; forever.json PRIEST Divine Grace desc |
| QuestClassData.lua:816 | priest-feedback | Priest: Feedback | Teaches Feedback: spells cast at you burn the caster's mana | :819 "learn Feedback"; forever.json PRIEST Feedback desc |
| QuestClassData.lua:824 | priest-desperate-prayer | Priest: Desperate Prayer | Teaches Desperate Prayer: an instant self-heal | :827 "learn Desperate Prayer"; forever.json PRIEST Desperate Prayer desc |
| QuestClassData.lua:832 | priest-chastise | Priest: Chastise | Teaches Chastise: Holy damage, roots a humanoid briefly | :837 "learn Chastise"; forever.json PRIEST Chastise desc |
| QuestClassData.lua:842 | priest-confounding-flash | Priest: Confounding Flash | Teaches Confounding Flash: briefly confuses enemies | :845 "learn Confounding Flash"; forever.json PRIEST Confounding Flash desc |
| QuestClassData.lua:850 | priest-contingency-plan | Priest: Contingency Plan | Teaches Contingency Plan: shields an ally who drops low | :853 "learn Contingency Plan"; forever.json PRIEST Contingency Plan desc |
| QuestClassData.lua:865 | priest-elunes-grace | Priest: Elune's Grace | Teaches Elune's Grace: fewer melee and ranged hits on you | :869 "learn Elune's Grace"; forever.json PRIEST Elune's Grace desc |
| QuestClassData.lua:886 | mage-mirror-lake | Mage: Mirror Lake | A weapon or off-hand of your choice | :893 "choose a weapon or off-hand" |
| QuestClassData.lua:899 | mage-gizmonitor | Mage: Mage-tastic Gizmonitor | A weapon or off-hand of your choice | :907 "choose a weapon or off-hand" |
| QuestClassData.lua:914 | mage-manaweave-robe | Mage: Manaweave Robe | The Manaweave Robe, a cloth robe | :927 "collect your Manaweave Robe"; item 7509 cloth robe |
| QuestClassData.lua:934 | mage-research-access | Mage: Study | Teaches Study: research at a library for scrolls | :946 "learn Study"; forever.json MAGE Study desc; audit 2026-11-08-class-priest-mage-warlock.md:37 |
| QuestClassData.lua:954 | mage-astral-knot | Mage: Astral Knot Garment | Astral Knot Robe or Blouse (cloth), your choice | :969 "choose the Astral Knot Robe or Blouse"; items 7511/9516 cloth |
| QuestClassData.lua:979 | mage-wand | Mage: Mage's Wand | A wand of your choice from Tabetha | :1001 "choose your wand" |
| QuestClassData.lua:1024 | warlock-voidwalker | Warlock: Voidwalker | Teaches Summon Voidwalker | :1037 "learn Summon Voidwalker" |
| QuestClassData.lua:1049 | warlock-sayaad | Warlock: Succubus and Incubus | Teaches Summon Succubus and Summon Incubus | :1075 "learn Summon Succubus"; :1080 "learn Summon Incubus" |
| QuestClassData.lua:1089 | warlock-felhunter | Warlock: Felhunter | Teaches Summon Felhunter | :1109 "learn Summon Felhunter" |
| QuestClassData.lua:1115 | warlock-orb-of-soranruk | Warlock: The Orb of Soran'ruk | The Orb or the Staff of Soran'ruk, your choice | :1121 "choose a staff or off-hand"; items 6898 Orb (off-hand), 15109 Staff of Soran'ruk |
| QuestClassData.lua:1128 | warlock-dread-mage-hat | Warlock: Dread Mage Hat | The Dread Mage Hat, a cloth hat | :1141 "receive the Dread Mage Hat"; item 3556 cloth head |
| QuestClassData.lua:1169 | druid-bear-form | Druid: Bear Form | Teaches Bear Form | :1187 "learn Bear Form" |
| QuestClassData.lua:1198 | druid-moonglade-skyborne | Druid: Moonglade (Skyborne) | UNKNOWN | :1202 hand-in at Dendrite names no reward (you already cast Teleport: Moonglade to get there); audit 2026-11-08-class-druid-shaman.md:14 only calls it an introduction |
| QuestClassData.lua:1212 | druid-aquatic-form | Druid: Aquatic Form | Teaches Aquatic Form: swim faster, breathe underwater | :1243 "learn Aquatic Form"; forever.json DRUID Aquatic Form desc |
| QuestClassData.lua:1267 | shaman-earth-totem | Shaman: Earth Totem | Your Earth Totem item | :1280 "for your Earth Totem"; item 5175 Earth Totem |
| QuestClassData.lua:1289 | shaman-fire-totem | Shaman: Fire Totem | Your Fire Totem item | :1310 "for your Fire Totem"; item 5176 |
| QuestClassData.lua:1323 | shaman-water-totem | Shaman: Water Totem | Your Water Totem item | :1355 "for your Water Totem"; item 5177 |
| QuestClassData.lua:1374 | druid-cure-poison | Druid: Cure Poison | Teaches Cure Poison | :1394 "learn Cure Poison" |
| QuestClassData.lua:1427 (built at :1407) | druid-cat-night-elf | Druid: Cat Form | Teaches Cat Form | :1423 "learn Cat Form" |
| QuestClassData.lua:1428 (built at :1407) | druid-cat-skyborne | Druid: Cat Form | Teaches Cat Form | :1423 "learn Cat Form" |
| QuestClassData.lua:1431 | shaman-air-totem | Shaman: Air Totem | Your Air Totem item | :1438 "meet Veyric for your Air Totem"; item 5178 |
| QuestClassData.lua:1471 | warrior-whirlwind-weapon | Warrior: Whirlwind Weapon | A two-handed Whirlwind Axe, Sword or Warhammer | :1499 "choose your Whirlwind weapon"; items 6975-6977 two-handed |
| QuestClassData.lua:1509 | warrior-voodoo-feathers | Warrior: Voodoo Feathers | UNKNOWN | :1528 "for your reward" (not named) |
| QuestClassData.lua:1565 | paladin-mightstone | Paladin: Forging the Mightstone | UNKNOWN | :1582 "for your reward" (not named); client has item 20620 Holy Mightstone, but no source ties it to 8418 |
| QuestClassData.lua:1601 | hunter-green-drake | Hunter: The Green Drake | UNKNOWN | :1617 tooth turn-in, no reward named |
| QuestClassData.lua:1625 | priest-blood-of-morphaz | Priest: Blood of Morphaz | UNKNOWN | :1642 blood turn-in, no reward named |
| QuestClassData.lua:1663 | rogue-azure-key | Rogue: The Azure Key | UNKNOWN | :1681 key turn-in, no reward named |
| QuestClassData.lua:1689 | mage-destroy-morphaz | Mage: Destroy Morphaz | UNKNOWN | :1706 shard turn-in, no reward named |
| QuestClassData.lua:1716 | mage-celestial-power | Mage: Celestial Power | UNKNOWN | :1739 "choose your reward" (not named); client has items 7515 Celestial Orb / 9517 Celestial Stave, but no source ties them to 1958 |
| QuestClassData.lua:1780 | warlock-orb-of-orahil | Warlock: The Orb of Orahil | The Orb of Dar'Orahil, an off-hand orb | :1805 "for the Orb of Dar'Orahil"; item 15108 held in off-hand |
| QuestClassData.lua:1815 | warlock-trolls-of-a-feather | Warlock: Trolls of a Feather | UNKNOWN | :1834 feathers turn-in, no reward named |
| QuestClassData.lua:1840 | warlock-kroshius | Warlock: Kroshius' Infernal Core | UNKNOWN | :1855 core turn-in, no reward named |
| QuestClassData.lua:1869 | druid-better-ingredient | Druid: A Better Ingredient | UNKNOWN | :1889 vine turn-in, no reward named |

## Horde class guides (QuestHordeClass*.lua, 50)

| file | section id | title | reward line (or UNKNOWN) | evidence |
|---|---|---|---|---|
| QuestHordeClassWarriorPaladin.lua:37 | warrior-defense-barrens | Warrior: Defensive Stance (Barrens) | Teaches Defensive Stance | :48 "learn Defensive Stance"; audit 2026-11-10-horde-class-warrior-paladin.md:14 |
| QuestHordeClassWarriorPaladin.lua:50 | warrior-forged-steel | Warrior: Forged Steel | A weapon of your choice from Thun'grim | :58 "choose a weapon you can use" |
| QuestHordeClassWarriorPaladin.lua:65 | warrior-agamand-heirlooms | Warrior: Agamand Heirlooms | An Heirloom weapon of your choice | :73 "choose a weapon you can use"; quest 1822 "Heirloom Weapon"; items 7115-7118 Heirloom Axe/Dagger/Hammer/Sword |
| QuestHordeClassWarriorPaladin.lua:82 | warrior-field-of-giants | Warrior: Trial at the Field of Giants | Opens Thun'grim's Brutal Armor quests | :97 1838 Brutal Armor needs 1825; :101 |
| QuestHordeClassWarriorPaladin.lua:99 | warrior-brutal-hauberk | Warrior: Brutal Hauberk | Brutal Hauberk (mail chest); opens more Brutal armor | :107 "Collect the Brutal Hauberk"; item 7133 mail chest; :113/:116/:119 the other pieces need 1838 |
| QuestHordeClassWarriorPaladin.lua:122 | warrior-brutal-gauntlets | Warrior: Brutal Gauntlets | The Brutal Gauntlets, mail gloves | :132 "Collect the Brutal Gauntlets"; item 7129 mail hands |
| QuestHordeClassWarriorPaladin.lua:134 | warrior-brutal-helm | Warrior: Brutal Helm | The Brutal Helm, a mail helm | :144 "Collect the Brutal Helm"; item 7130 mail head |
| QuestHordeClassWarriorPaladin.lua:146 | warrior-brutal-legguards | Warrior: Brutal Legguards | The Brutal Legguards, mail leg armor | :156 "Collect the Brutal Legguards"; item 7132 mail legs |
| QuestHordeClassWarriorPaladin.lua:165 | warrior-berserker-stance | Warrior: Berserker Stance | Teaches Berserker Stance and Intercept | :180 "learn Berserker Stance and Intercept" |
| QuestHordeClassWarriorPaladin.lua:211 | paladin-redemption-undead | Paladin: Redemption | Teaches Redemption: bring a dead player back to life | :233 "learn Redemption"; forever.json PALADIN Redemption desc |
| QuestHordeClassWarriorPaladin.lua:255 | paladin-lumina-windsinger | Paladin: Lumina Windsinger | Opens the Wolfsbane weapon quests | :277 95036 needs 95034 (The Debt); :284 "After The Debt, Lumina asks for a blade" |
| QuestHordeClassWarriorPaladin.lua:282 | paladin-wolfsbane | Paladin: Wolfsbane | The Moonsilver Blade (two-hand sword), then Wolfsbane | :295 "for the Moonsilver Blade"; :302 "Turn in to Lumina for Wolfsbane"; item 268484 2H sword (Wolfsbane is not in the item table) |
| QuestHordeClassHunterRogue.lua:105 | rogue-lockpicking-horde | Rogue: Lockpicking | UNKNOWN | :120 treasure turn-in names no reward (the guide itself only levels Lockpicking on the Tide Razor) |
| QuestHordeClassHunterRogue.lua:130 | rogue-poisons-horde | Rogue: Poisons | Teaches Poisons and Thistle Tea; cures Touch of Zanzil | :152 "You learn the Thistle Tea recipe"; :157 "learn Poisons ... clear the Touch of Zanzil" |
| QuestHordeClassHunterRogue.lua:165 | rogue-tools-of-the-trade | Rogue: Tools of the Trade | UNKNOWN | audit 2026-11-10-horde-class-hunter-rogue.md:68 "Their rewards are not confirmed for Forever" |
| QuestHordeClassHunterRogue.lua:195 | rogue-horn-of-xelthos-horde | Rogue: The Horn of Xelthos | The Pyrewood Signet Ring; opens The Eye of Bhossca | :211 "Collect the Pyrewood Signet Ring"; item 277210 ring; :242 78676 needs 78307 |
| QuestHordeClassHunterRogue.lua:216 | rogue-ravenholdt-horde | Rogue: Ravenholdt Invitation | UNKNOWN | :225 hand Fahrad the seal, no reward named |
| QuestHordeClassHunterRogue.lua:230 | rogue-syndicate-sabotage-horde | Rogue: Syndicate Sabotage | UNKNOWN | :238 plain turn-in, no reward named |
| QuestHordeClassHunterRogue.lua:244 | rogue-eye-of-bhossca-horde | Rogue: The Eye of Bhossca | The Ruby-Adorned Blade, a one-hand sword | :261 "Collect the Ruby-Adorned Blade"; item 277246 1H sword |
| QuestHordeClassCasters.lua:85 | mage-ju-ju-heaps | Mage: Ju-Ju Heaps | An orb or a staff of your choice | :93 "choose the orb or the staff" |
| QuestHordeClassCasters.lua:117 | mage-study-horde | Mage: Study | Teaches Study: research at a library for scrolls | :130 "learn Study"; forever.json MAGE Study desc |
| QuestHordeClassCasters.lua:141 | mage-spellfire-robes | Mage: Spellfire Robes | The Lesser Spellfire Robes, a cloth robe | :157 "for your Spellfire Robes"; the only matching client item is 7510 "Lesser Spellfire Robes" (cloth robe) - check the name |
| QuestHordeClassCasters.lua:166 | mage-nether-lace | Mage: Nether-lace Garment | Nether-lace Robe or Tunic (cloth), your choice | :183 "choose the robe or the blouse"; client items 7512 Nether-lace Robe, 9515 Nether-lace Tunic (step says blouse, item says Tunic) |
| QuestHordeClassCasters.lua:197 | mage-wand-horde | Mage: Mage's Wand | A wand of your choice from Tabetha | :221 "pick your wand" |
| QuestHordeClassCasters.lua:278 | warlock-sayaad-horde | Warlock: Succubus and Incubus | Teaches Summon Succubus and Summon Incubus | :307 "learn Summon Succubus"; :315 "learn Summon Incubus" |
| QuestHordeClassCasters.lua:321 | warlock-orb-horde | Warlock: The Orb of Soran'ruk | The Orb or the Staff of Soran'ruk, your choice | :329 "choose the orb or the staff"; items 6898, 15109 |
| QuestHordeClassCasters.lua:342 | warlock-felhunter-horde | Warlock: Felhunter | Teaches Summon Felhunter | :365 "learn Summon Felhunter" |
| QuestHordeClassDruidShaman.lua:33 | druid-bear-form-tauren | Druid: Bear Form | Teaches Bear Form | :52 "learn Bear Form" |
| QuestHordeClassDruidShaman.lua:60 | druid-moonglade-skyborne-horde | Druid: Moonglade (Skyborne) | UNKNOWN | :65 hand-in at Dendrite names no reward; audit 2026-11-10-horde-class-druid-shaman.md:12 "nothing follows it there" |
| QuestHordeClassDruidShaman.lua:75 | druid-cure-poison-horde | Druid: Cure Poison | Teaches Cure Poison | :99 "learn Cure Poison" |
| QuestHordeClassDruidShaman.lua:108 | druid-aquatic-form-horde | Druid: Aquatic Form | Teaches Aquatic Form: swim faster, breathe underwater | :137 "learn Aquatic Form"; forever.json DRUID Aquatic Form desc |
| QuestHordeClassDruidShaman.lua:174 (built at :152) | druid-cat-form-tauren | Druid: Cat Form | Teaches Cat Form | :170 "learn Cat Form" |
| QuestHordeClassDruidShaman.lua:175 (built at :152) | druid-cat-form-skyborne-horde | Druid: Cat Form | Teaches Cat Form | :170 "learn Cat Form" |
| QuestHordeClassDruidShaman.lua:219 | shaman-fire-totem-horde | Shaman: Fire Totem | Your Fire Totem item | :248 "for your Fire Totem" |
| QuestHordeClassDruidShaman.lua:266 | shaman-water-totem-horde | Shaman: Water Totem | Your Water Totem item | :305 "for your Water Totem" |
| QuestHordeClassDruidShaman.lua:313 | shaman-air-totem-horde | Shaman: Air Totem | Your Air Totem item | audit 2026-11-10-horde-class-druid-shaman.md:23 "rewards the Air Totem" |
| QuestHordeClass3060.lua:82 | warrior-whirlwind-weapon-horde | Warrior: Whirlwind Weapon | A two-handed Whirlwind Axe, Sword or Warhammer | :118 "choose your Whirlwind weapon"; items 6975-6977 two-handed |
| QuestHordeClass3060.lua:126 | warrior-voodoo-feathers-horde | Warrior: Voodoo Feathers | UNKNOWN | :150 "for your reward" (not named) |
| QuestHordeClass3060.lua:167 | hunter-green-drake-horde | Hunter: The Green Drake | UNKNOWN | :193 tooth turn-in, no reward named |
| QuestHordeClass3060.lua:201 | priest-blood-of-morphaz-horde | Priest: Blood of Morphaz | UNKNOWN | :231 blood turn-in, no reward named |
| QuestHordeClass3060.lua:247 | rogue-azure-key-horde | Rogue: The Azure Key | UNKNOWN | :276 key turn-in, no reward named |
| QuestHordeClass3060.lua:285 | mage-destroy-morphaz-horde | Mage: Destroy Morphaz | UNKNOWN | :310 shard turn-in, no reward named |
| QuestHordeClass3060.lua:322 | mage-celestial-power-horde | Mage: Celestial Power | UNKNOWN | :358 "choose your reward" (not named); see the Alliance row for the client item candidates |
| QuestHordeClass3060.lua:379 | warlock-felsteed-horde | Warlock: Summon Felsteed | Teaches Summon Felsteed | :390 "learn Summon Felsteed" (not in forever.json's spell list) |
| QuestHordeClass3060.lua:404 | warlock-orb-of-orahil-horde | Warlock: The Orb of Orahil | The Orb of Dar'Orahil, an off-hand orb | :439 "for the Orb of Dar'Orahil"; item 15108 held in off-hand |
| QuestHordeClass3060.lua:451 | warlock-trolls-of-a-feather-horde | Warlock: Trolls of a Feather | UNKNOWN | :477 feathers turn-in, no reward named |
| QuestHordeClass3060.lua:483 | warlock-kroshius-horde | Warlock: Kroshius' Infernal Core | UNKNOWN | :500 core turn-in, no reward named |
| QuestHordeClass3060.lua:515 | druid-better-ingredient-horde | Druid: A Better Ingredient | UNKNOWN | :542 vine turn-in, no reward named |
| QuestHordeClass3060.lua:561 | shaman-tempests-weapons-horde | Shaman: The Tempest's Weapons | Rage of the Storm, Lightning's Grasp or Tidebringer's Claw | :614 "Choose Rage of the Storm, Lightning's Grasp or Tidebringer's Claw"; audit 2026-11-12-horde-class-30-60.md:28 "weapon choice" |
| QuestHordeClass3060.lua:620 | shaman-da-voodoo-horde | Shaman: Da Voodoo | UNKNOWN | :649 feathers turn-in, no reward named |

## UNKNOWN count

31 of 134 guides are UNKNOWN:

- Alliance special: 2 of 9 (legend-of-stalvan, missing-diplomat).
- Horde special: 0 of 5.
- Alliance class: 14 of 70 (rogue-lockpicking, rogue-ravenholdt-manor, rogue-syndicate-sabotage, druid-moonglade-skyborne, and the ten 38-56 chains: warrior-voodoo-feathers, paladin-mightstone, hunter-green-drake, priest-blood-of-morphaz, rogue-azure-key, mage-destroy-morphaz, mage-celestial-power, warlock-trolls-of-a-feather, warlock-kroshius, druid-better-ingredient).
- Horde class: 15 of 50 (rogue-lockpicking-horde, rogue-tools-of-the-trade, rogue-ravenholdt-horde, rogue-syndicate-sabotage-horde, druid-moonglade-skyborne-horde, and the ten 35-56 chains: warrior-voodoo-feathers-horde, hunter-green-drake-horde, priest-blood-of-morphaz-horde, rogue-azure-key-horde, mage-destroy-morphaz-horde, mage-celestial-power-horde, warlock-trolls-of-a-feather-horde, warlock-kroshius-horde, druid-better-ingredient-horde, shaman-da-voodoo-horde).

Lines that rest on an inference worth a look in game: mage-spellfire-robes (item named "Lesser Spellfire
Robes"), mage-nether-lace (step says blouse, the client item is a Tunic), cozy-sleeping-bag (the 12-slot
Old Toolbox is marked uncertain in the guide), and the "opens ..." lines (paladin-lumina-windsinger,
warrior-field-of-giants), which describe the next chain the data unlocks, not a quest reward.
