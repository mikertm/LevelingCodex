-- Horde class quests, levels 30-60 (side sections). Source notes: tools/audits/2026-11-12-horde-class-30-60.md.
-- Loaded after the other QuestHordeClass*.lua files and before QuestClassData.lua.
local B = LevelingCodexQuests.build
local H = B.horde
local route = LevelingCodexQuests.HORDE

-- Every class side guide here runs on the audit's main path after the leveling route, so a quest
-- accepted here must not also be accepted inline on the route (logOnly hand-ins and objectives are
-- fine). Referral quests get one accept per race, at that race's capital.
local ORC, TROLL, TAUREN, UNDEAD, SKYBORNE = "ORC", "TROLL", "TAUREN", "SCOURGE", "SKYBORNE"
local ALL = { ORC, TROLL, TAUREN, UNDEAD, SKYBORNE }
local qdb = "QuestieDB Forever 0f7d8ad"
local refB = "Reference guide B: class quest chapters (order and IDs only)"

-- A class quest: QuestieDB facts, limited to the class (QuestClassData.lua re-registers the
-- shared ones for the Alliance afterwards; steps keep the copy made here).
local function need(class, id, name, level, min, prev, forever)
  H.need(id, name, level, min, prev, forever)
  H.limit(id, { class = class })
end

-- A class chain that ends inside a dungeon is listed on that Horde dungeon guide, so the library
-- recommends the run to that class.
local function linkRun(dungeonId, sectionIds)
  for _, section in ipairs(route.sections) do
    if section.id == dungeonId then
      section.links = section.links or {}
      for _, id in ipairs(sectionIds) do section.links[#section.links + 1] = id end
      return
    end
  end
  error("Horde class quests 30-60: no dungeon guide " .. dungeonId)
end

-- Places several chains share (QuestieDB spawns; zeppelin towers as in QuestHorde3040.lua).
local P = {}
do
  local M, at = B.maps, B.at
  P.doras = at("Doras", 45.12, 63.89, M.orgrimmar)
  P.tal = at("Tal", 47.0, 49.83, M.thunderBluff)
  P.garrett = at("Michael Garrett", 63.25, 48.56, M.undercity)
  P.toUndercity = at(nil, 50.8, 13.8, M.durotar)
  P.toGromgol = at("Snurk Bucksquick", 50.7, 12.9, M.durotar)
  P.gromgolToOrgrimmar = at("Nez'raz", 31.4, 29.9, M.stv)
  P.bragok = at("Bragok", 63.09, 37.16, M.barrens)
  P.strahad = at("Strahad Farsan", 62.63, 35.5, M.barrens)
  P.menara = at("Menara Voidrender", 62.51, 35.45, M.barrens)
  P.zarise = at("Zarise", 60.14, 18.62, M.hillsbrad)
  P.thysta = at("Thysta", 32.54, 29.35, M.stv)
  P.urda = at("Urda", 73.02, 32.7, M.arathi)
  P.breyk = at("Breyk", 46.07, 54.83, M.swamp)
  P.gorrik = at("Gorrik", 3.99, 44.78, M.badlands)
  P.kroum = at("Kroum", 21.96, 49.62, M.azshara)
  P.brakkar = at("Brakkar", 34.44, 53.96, M.felwood)
  P.shardi = at("Shardi", 35.56, 31.88, M.dustwallow)
  P.thalon = at("Thalon", 21.6, 74.13, M.desolace)
  P.nyse = at("Nyse", 45.14, 49.11, M.needles)
  P.bathrah = at("Bath'rah the Windwatcher", 80.5, 66.92, M.alterac)
  P.tabetha = at("Tabetha", 46.06, 57.09, M.dustwallow)
  P.ogtinc = at("Ogtinc", 42.4, 42.62, M.azshara)
  P.xylem = at("Archmage Xylem", 29.25, 40.21, M.azshara)
  P.sanath = at("Sanath Lim-yo", 28.11, 50.09, M.azshara)
  P.temple = at("Temple of Atal'Hakkar", 69.7, 53.5, M.swamp)
  P.toStonard = "Travel to Stonard in the Swamp of Sorrows: fly to Orgrimmar, take the zeppelin to Grom'gol and fly on to Stonard."
  P.trollFeathers = "Inside the Sunken Temple, kill the six troll minibosses on the upper ring for two Amber, two Blue and two Green Voodoo Feathers."
  P.passage = "Check what Sanath Lim-yo asks before he sends you up to Xylem."
end

-- Warrior: the Whirlwind weapon from Bath'rah in Alterac (after Berserker Stance), then the Fallen
-- Hero's chain at 50.
do
  local M, at, only = B.maps, B.at, B.only
  local accept, finish, goal, part, note, action, taxi = B.accept, B.finish, B.objectiveAt, B.objectivePart,
    B.note, B.action, B.taxi
  local warrior = "WARRIOR"
  need(warrior, 1791, "The Windwatcher", 30, 30, 1719)
  need(warrior, 1712, "Cyclonian", 40, 30, 1791)
  need(warrior, 1713, "The Summoning", 40, 30, 1712)
  need(warrior, 1792, "Whirlwind Weapon", 40, 30, 1713)
  local klannoc = at("Klannoc Macleod", 68.62, 49.16, M.barrens)
  local cauldron = at("Bath'rah's Cauldron", 79.32, 66.8, M.alterac)
  B.hordeSide({ id = "warrior-whirlwind-weapon-horde", title = "Warrior: Whirlwind Weapon", zone = M.alterac,
    levels = { 35, 40 }, class = warrior, start = ALL,
    sources = { qdb, refB, "Reference guide A: Horde 30-33, 35-37 and 38-39 chapters (warrior steps)" },
    steps = {
      accept(1791, klannoc,
        "After The Affray, Klannoc Macleod on Fray Island has The Windwatcher. Keep it in your log until you head for Alterac."),
      taxi("fly", B.at("Doras", 45.12, 63.89, 1454), "Orgrimmar, Durotar", "Wade back across the shallows, ride north to Ratchet and fly to Orgrimmar."),
      action("boat", P.toUndercity, "Take the zeppelin to Tirisfal Glades from the tower north of Orgrimmar."),
      taxi("fly", B.at("Zarise", 60.14, 18.62, 1424), "Tarren Mill, Hillsbrad", "Walk into the Undercity and fly to Tarren Mill."),
      finish(1791, P.bathrah,
        "Bath'rah camps by his cauldron in the hills just over the Alterac border, a short ride north-east of Tarren Mill."),
      accept(1712, P.bathrah,
        "Take Cyclonian. Bath'rah's Parchment lists a Liferoot, 30 Bloodscalp Tusks and the Essence of the Exile."),
      taxi("fly", B.at("Thysta", 32.5, 29.4, 1434), "Grom'gol, Stranglethorn",
        "Fly from Tarren Mill to Grom'gol. Without that flight path, fly to the Undercity and take the Grom'gol zeppelin."),
      part(1712, 2, at(nil, 24.0, 12.0, M.stv),
        "Ride north-west from Grom'gol to the Bloodscalp camps on the coast. Kill Bloodscalp trolls until you have 30 tusks.",
        "30 Bloodscalp Tusk"),
      part(1712, 1, nil,
        "Pick a Liferoot from an herb node beside a river or lake, or buy one at the auction house.", "Liferoot"),
      taxi("fly", B.at("Urda", 73, 32.7, 1417), "Hammerfall, Arathi", "Fly from Grom'gol to Hammerfall in Arathi."),
      note(goal(1712, at(nil, 78.5, 35.8, M.arathi),
        "Ride east from Hammerfall into Drywhisker Gorge. The kobolds there drop the Burning, Thundering and Cresting Charms. The Exile elementals drop them too: Cresting Exiles west of Hammerfall, Thundering Exiles in the middle of Arathi (52, 50), Burning Exiles in the north-west hills (26, 30). Use Next once you have all three.",
        "Burning Charm", "Thundering Charm", "Cresting Charm"),
        "Charm drop sources are QuestieDB data; check them in game."),
      action("goto", P.bathrah, "Take the road west out of Arathi into Hillsbrad and climb back up to Bath'rah's camp."),
      note(part(1712, 3, cauldron,
        "Combine the three charms at the cauldron beside Bath'rah for the Essence of the Exile.", "Essence of the Exile"),
        "The cauldron's own quest (Essence of the Exile, 1714) is not in the Forever client. Check how the essence is made."),
      finish(1712, P.bathrah),
      accept(1713, P.bathrah, "Accept when you are ready: Cyclonian is a level 40 elite, so bring a friend or two."),
      note(goal(1713, P.bathrah, "Kill Cyclonian when it is summoned near Bath'rah and loot the Whirlwind Heart.",
        "Whirlwind Heart"),
        "Check where Cyclonian appears and whether Bath'rah starts the summoning."),
      finish(1713, P.bathrah),
      accept(1792, P.bathrah),
      finish(1792, P.bathrah, "Speak with Bath'rah again and choose your Whirlwind weapon."),
    } })

  local hero = at("Fallen Hero of the Horde", 34.29, 66.14, M.swamp)
  need(warrior, 8417, "A Troubled Spirit", 50, 50)
  need(warrior, 8423, "Warrior Kinship", 52, 50)
  need(warrior, 8424, "War on the Shadowsworn", 52, 50, 8423)
  need(warrior, 8425, "Voodoo Feathers", 52, 50, 8424)
  B.hordeSide({ id = "warrior-voodoo-feathers-horde", title = "Warrior: Voodoo Feathers", zone = M.swamp,
    levels = { 52, 54 }, class = warrior, start = ALL,
    sources = { qdb, refB, "Reference guide A: Horde 50-51 and 55-56 chapters (warrior steps)" },
    steps = {
      only(accept(8417, at("Sorek", 80.39, 32.38, M.orgrimmar),
        "From level 50, Sorek in Orgrimmar's Valley of Honor has A Troubled Spirit."), { race = { ORC, TROLL, SKYBORNE } }),
      only(accept(8417, at("Torm Ragetotem", 57.24, 87.37, M.thunderBluff),
        "From level 50, Torm Ragetotem on Hunter Rise in Thunder Bluff has A Troubled Spirit."), { race = TAUREN }),
      only(accept(8417, at("Christoph Walker", 46.93, 15.23, M.undercity),
        "From level 50, Christoph Walker in the Undercity's War Quarter has A Troubled Spirit."), { race = UNDEAD }),
      action("goto", P.breyk, P.toStonard .. " From the Undercity, take the Grom'gol zeppelin from Tirisfal."),
      finish(8417, hero,
        "Ride west from Stonard. The Fallen Hero kneels beside the road at the south-west edge of the swamp, where it meets the Blasted Lands."),
      accept(8423, hero),
      goal(8423, at(nil, 51.7, 54.3, M.blasted),
        "Follow the road south through the pass into the Blasted Lands and kill Helboars in the middle of the zone.", "7 Helboar"),
      finish(8423, hero),
      accept(8424, hero),
      goal(8424, at(nil, 65.5, 33.0, M.blasted),
        "Clear the Shadowsworn camps in the north-east of the Blasted Lands: adepts, cultists and thugs. More stand around 63, 44.",
        "Shadowsworn Adepts", "Shadowsworn Cultists", "Shadowsworn Thugs"),
      finish(8424, hero),
      B.withGuide("dungeon-sunken-temple", accept(8425, hero, "Voodoo Feathers needs a Sunken Temple group.")),
      goal(8425, P.temple, P.trollFeathers, "2 Amber Voodoo Feather", "2 Blue Voodoo Feather", "2 Green Voodoo Feather"),
      finish(8425, hero, "Bring the feathers back to the Fallen Hero for your reward."),
    } })
end

-- Hunter and Priest: Ogtinc on the Azshara cliffs, ending with Morphaz in the Sunken Temple.
do
  local M, at, only = B.maps, B.at, B.only
  local accept, finish, goal, action = B.accept, B.finish, B.objectiveAt, B.action
  local coursers = at(nil, 45.1, 75.5, M.azshara)
  local toValormok = "Travel to Valormok in western Azshara: fly there from Orgrimmar, or ride east out of Ashenvale."
  local ogtincText = "Ride east from Valormok. Ogtinc lives on a clifftop above the Ruins of Eldarath."

  local hunter = "HUNTER"
  need(hunter, 8151, "The Hunter's Charm", 52, 50)
  need(hunter, 8153, "Courser Antlers", 52, 50, 8151)
  need(hunter, 8231, "Wavethrashing", 52, 50, 8153)
  need(hunter, 8232, "The Green Drake", 52, 50, 8231)
  B.hordeSide({ id = "hunter-green-drake-horde", title = "Hunter: The Green Drake", zone = M.azshara,
    levels = { 52, 54 }, class = hunter, start = { ORC, TROLL, TAUREN, SKYBORNE },
    sources = { qdb, refB, "Reference guide A: Horde 52-53 and 55-56 chapters (hunter steps)" },
    steps = {
      only(accept(8151, at("Xor'juul", 67.24, 20.2, M.orgrimmar),
        "From level 50, Xor'juul in Orgrimmar's Hunter's Hall has The Hunter's Charm."), { race = { ORC, TROLL, SKYBORNE } }),
      only(accept(8151, at("Kary Thunderhorn", 58.49, 88.33, M.thunderBluff),
        "From level 50, Kary Thunderhorn on Hunter Rise in Thunder Bluff has The Hunter's Charm."), { race = TAUREN }),
      action("goto", P.kroum, toValormok),
      finish(8151, P.ogtinc, ogtincText),
      accept(8153, P.ogtinc),
      goal(8153, coursers,
        "Ride south into the forests of southern Azshara. Hunt Mosshoof Coursers until a pair of Perfect Courser Antlers drops.",
        "Perfect Courser Antlers"),
      finish(8153, P.ogtinc),
      accept(8231, P.ogtinc),
      action("goto", at(nil, 65.0, 35.0, M.azshara), "Ride east across Azshara toward the coast."),
      goal(8231, at(nil, 87.3, 26.9, M.azshara),
        "Kill Wavethrashers in the surf along the eastern coast for their scales. More swim further south (91, 35).",
        "6 Wavethrasher Scales"),
      action("goto", at(nil, 65.0, 35.0, M.azshara), "Ride back west toward Ogtinc."),
      finish(8231, P.ogtinc),
      B.withGuide("dungeon-sunken-temple", accept(8232, P.ogtinc, "The Green Drake needs a Sunken Temple group.")),
      action("goto", P.breyk, P.toStonard),
      goal(8232, P.temple, "Inside the Sunken Temple, kill the green dragon Morphaz for his tooth.", "Tooth of Morphaz"),
      action("goto", P.kroum, "Return to Azshara: fly back to Orgrimmar and on to Valormok."),
      finish(8232, P.ogtinc, "Bring the tooth back to Ogtinc on the cliffs above the Ruins of Eldarath."),
    } })

  local priest = "PRIEST"
  need(priest, 8254, "Cenarion Aid", 52, 50)
  need(priest, 8255, "Of Coursers We Know", 52, 50, 8254)
  need(priest, 8256, "The Ichor of Undeath", 52, 50, 8255)
  need(priest, 8257, "Blood of Morphaz", 52, 50, 8256)
  B.hordeSide({ id = "priest-blood-of-morphaz-horde", title = "Priest: Blood of Morphaz", zone = M.azshara,
    levels = { 52, 54 }, class = priest, start = ALL,
    sources = { qdb, refB, "Reference guide A: Horde 52-53 and 55-56 chapters (priest steps)" },
    steps = {
      only(accept(8254, at("X'yera", 36.01, 87.73, M.orgrimmar),
        "From level 50, X'yera in Orgrimmar's Valley of Spirits has Cenarion Aid."), { race = { ORC, TROLL, SKYBORNE } }),
      only(accept(8254, at("Malakai Cross", 24.56, 22.57, M.thunderBluff),
        "From level 50, Malakai Cross on Spirit Rise in Thunder Bluff has Cenarion Aid."), { race = TAUREN }),
      only(accept(8254, at("Aelthalyste", 49.26, 17.12, M.undercity),
        "From level 50, Aelthalyste in the Undercity's War Quarter has Cenarion Aid. Take the zeppelin to Orgrimmar afterwards."),
        { race = UNDEAD }),
      action("goto", P.kroum, toValormok),
      finish(8254, P.ogtinc, ogtincText),
      accept(8255, P.ogtinc),
      goal(8255, coursers,
        "Ride south into the forests of southern Azshara. Hunt Mosshoof Coursers for healthy glands.", "4 Healthy Courser Gland"),
      finish(8255, P.ogtinc),
      accept(8256, P.ogtinc),
      action("goto", at(nil, 27.0, 57.0, M.wpl),
        "Travel to the Western Plaguelands: fly to Orgrimmar, take the zeppelin to Tirisfal Glades and ride east through the Bulwark into the plaguelands."),
      goal(8256, at(nil, 37.5, 56.0, M.wpl),
        "Kill skeletons and ghouls around Felstone Field until an Ichor of Undeath drops. Zanzil's zombies in Stranglethorn (37, 55) drop it too.",
        "Ichor of Undeath"),
      action("goto", P.kroum, "Return to Azshara: take the zeppelin back to Orgrimmar and fly to Valormok."),
      finish(8256, P.ogtinc),
      B.withGuide("dungeon-sunken-temple", accept(8257, P.ogtinc,
        "Blood of Morphaz needs a Sunken Temple group. It is handed in at the Emerald Sanctuary in Felwood.")),
      action("goto", P.breyk, P.toStonard),
      goal(8257, P.temple, "Inside the Sunken Temple, kill the green dragon Morphaz for his blood.", "Blood of Morphaz"),
      action("goto", P.brakkar, "Travel to Felwood: fly to Orgrimmar and on to Bloodvenom Post."),
      finish(8257, at("Greta Mosshoof", 51.21, 82.11, M.felwood),
        "Ride south-east to the Emerald Sanctuary in southern Felwood and give the blood to Greta Mosshoof."),
    } })
end

-- Rogue and Mage: Archmage Xylem's errands in Azshara, ending with Morphaz in the Sunken Temple.
do
  local M, at, only = B.maps, B.at, B.only
  local accept, finish, goal, note, action = B.accept, B.finish, B.objectiveAt, B.note, B.action

  local rogue = "ROGUE"
  local jorach = at("Lord Jorach Ravenholdt", 86.02, 78.88, M.alterac)
  need(rogue, 8233, "A Simple Request", 52, 50)
  need(rogue, 8234, "Sealed Azure Bag", 52, 50, 8233)
  need(rogue, 8235, "Encoded Fragments", 52, 50, 8234)
  need(rogue, 8236, "The Azure Key", 52, 50, 8235)
  B.hordeSide({ id = "rogue-azure-key-horde", title = "Rogue: The Azure Key", zone = M.azshara,
    levels = { 52, 54 }, class = rogue, start = { ORC, TROLL, UNDEAD, SKYBORNE },
    sources = { qdb, refB },
    steps = {
      only(accept(8233, at("Ormok", 43.9, 54.63, M.orgrimmar),
        "From level 50, Ormok in Orgrimmar's Cleft of Shadow has A Simple Request."), { race = { ORC, TROLL, SKYBORNE } }),
      only(accept(8233, at("Miles Dexter", 85.21, 71.57, M.undercity),
        "From level 50, Miles Dexter in the Undercity's Rogues' Quarter has A Simple Request."), { race = UNDEAD }),
      action("goto", P.zarise,
        "Travel to Tarren Mill in Hillsbrad: take the zeppelin to Tirisfal Glades if you are in Orgrimmar, then fly from the Undercity."),
      finish(8233, jorach,
        "Ride east from Tarren Mill toward Durnholde Keep. The trail north of the keep climbs into the Alterac hills to Ravenholdt Manor, where Lord Jorach waits."),
      accept(8234, jorach),
      action("goto", P.kroum, "Travel to Azshara: fly to the Undercity, take the zeppelin to Orgrimmar and fly to Valormok."),
      goal(8234, at(nil, 42.8, 19.5, M.azshara),
        "Ride north-east into the hills of northern Azshara. Kill Timbermaw Shamans until the Sealed Azure Bag drops.",
        "Sealed Azure Bag"),
      note(finish(8234, P.xylem,
        "Archmage Xylem's tower stands on the western cliffs, north of Valormok. Ask Sanath Lim-yo at its foot for passage up."),
        P.passage),
      accept(8235, P.xylem),
      goal(8235, at(nil, 43.6, 34.5, M.azshara),
        "Kill Thunderhead hippogryphs for Encoded Fragments: Stagwings fly east of the tower, Skystormers further north-east (55, 24).",
        "10 Encoded Fragment"),
      finish(8235, P.xylem),
      B.withGuide("dungeon-sunken-temple", accept(8236, P.xylem, "The Azure Key needs a Sunken Temple group.")),
      action("goto", P.breyk, P.toStonard),
      goal(8236, P.temple, "Inside the Sunken Temple, kill the green dragon Morphaz for the Azure Key.", "Azure Key"),
      action("goto", P.zarise, "Travel to Tarren Mill: fly from Stonard, or take the zeppelin to the Undercity and fly from there."),
      finish(8236, jorach, "Take the key back to Lord Jorach at Ravenholdt Manor."),
    } })

  local mage = "MAGE"
  local mages = { ORC, TROLL, UNDEAD }
  need(mage, 8250, "Magecraft", 52, 50)
  need(mage, 8251, "Magic Dust", 52, 50, 8250)
  need(mage, 8252, "The Siren's Coral", 52, 50, 8251)
  need(mage, 8253, "Destroy Morphaz", 52, 50, 8252)
  B.hordeSide({ id = "mage-destroy-morphaz-horde", title = "Mage: Destroy Morphaz", zone = M.azshara,
    levels = { 52, 54 }, class = mage, start = mages,
    sources = { qdb, "Reference guide A: Horde 52-53 and 55-56 chapters (mage steps)" },
    steps = {
      only(accept(8250, at("Enyo", 38.78, 85.67, M.orgrimmar),
        "From level 50, Enyo in Orgrimmar's Valley of Spirits has Magecraft."), { race = { ORC, TROLL } }),
      only(accept(8250, at("Pierce Shackleton", 85.45, 13.51, M.undercity),
        "From level 50, Pierce Shackleton in the Undercity's Magic Quarter has Magecraft. Take the zeppelin to Orgrimmar afterwards."),
        { race = UNDEAD }),
      action("goto", P.kroum, "Travel to Valormok in western Azshara: fly there from Orgrimmar."),
      finish(8250, P.sanath, "Sanath Lim-yo stands at the foot of Archmage Xylem's tower, a short ride north-east of Valormok."),
      note(accept(8251, P.xylem, "Ask Sanath for passage up the tower, then take Magic Dust from Xylem."), P.passage),
      action("goto", at(nil, 45.0, 32.0, M.azshara), "Ride east across the northern hills of Azshara."),
      goal(8251, at(nil, 57.1, 27.8, M.azshara),
        "Kill the blood elves at their camp in northern Azshara for Glittering Dust.", "10 Glittering Dust"),
      action("goto", at(nil, 45.0, 32.0, M.azshara), "Ride back west toward Xylem's tower."),
      finish(8251, P.xylem),
      accept(8252, P.xylem),
      goal(8252, at(nil, 37.1, 54.6, M.azshara),
        "Kill Spitelash Sirens around the Ruins of Eldarath, south-east of the tower, for Enchanted Coral.", "6 Enchanted Coral"),
      finish(8252, P.xylem),
      B.withGuide("dungeon-sunken-temple", accept(8253, P.xylem, "Destroy Morphaz needs a Sunken Temple group.")),
      action("goto", P.breyk, P.toStonard),
      goal(8253, P.temple, "Inside the Sunken Temple, kill the green dragon Morphaz for the Arcane Shard.", "Arcane Shard"),
      action("goto", P.kroum, "Return to Azshara: fly to Orgrimmar and on to Valormok."),
      finish(8253, P.xylem, "Bring the shard back to Archmage Xylem."),
    } })

  -- Mage: Tabetha's second chain (Celestial Power). The Mage's Wand chain at 30 is in
  -- QuestHordeClassCasters.lua.
  need(mage, 1953, "Return to the Marsh", 40, 35)
  need(mage, 1954, "The Infernal Orb", 40, 35, 1953)
  need(mage, 1955, "The Exorcism", 40, 35, 1954)
  need(mage, 1956, "Power in Uldaman", 40, 35, 1955)
  need(mage, 1957, "Mana Surges", 40, 35, 1956)
  need(mage, 1958, "Celestial Power", 40, 35, 1957)
  local summoners = at(nil, 80.4, 77.2, M.desolace)
  B.hordeSide({ id = "mage-celestial-power-horde", title = "Mage: Celestial Power", zone = M.dustwallow,
    levels = { 35, 40 }, class = mage, start = mages,
    sources = { qdb, refB },
    steps = {
      only(accept(1953, at("Uthel'nay", 39.16, 86.27, M.orgrimmar),
        "From level 35, Uthel'nay in Orgrimmar's Valley of Spirits sends you back to Tabetha."), { race = { ORC, TROLL } }),
      only(accept(1953, at("Anastasia Hartwell", 85.14, 10.03, M.undercity),
        "From level 35, Anastasia Hartwell in the Undercity's Magic Quarter sends you back to Tabetha. Take the zeppelin to Orgrimmar afterwards."),
        { race = UNDEAD }),
      action("goto", P.shardi,
        "Travel to Brackenwall Village in Dustwallow Marsh: fly there from Orgrimmar, or take the east road out of the Barrens."),
      finish(1953, P.tabetha, "Ride south from Brackenwall. Tabetha's hut stands in the hills in the west of the marsh."),
      accept(1954, P.tabetha),
      B.taxi("fly", B.at("Thalon", 21.6, 74.1, 1443), "Shadowprey Village, Desolace", "Return to Brackenwall Village and fly to Shadowprey Village in Desolace."),
      goal(1954, summoners,
        "Ride east across southern Desolace to Shadowbreak Ravine in the far south-east. Kill Burning Blade Summoners until an Infernal Orb drops.",
        "Infernal Orb"),
      B.taxi("fly", B.at("Shardi", 35.6, 31.9, 1445), "Brackenwall Village, Dustwallow Marsh",
        "Ride back to Shadowprey Village and fly to Brackenwall Village."),
      finish(1954, P.tabetha),
      accept(1955, P.tabetha, "Heal up first: Tabetha calls out the Demon of the Orb, a level 40 elite."),
      goal(1955, P.tabetha, "Kill the Demon of the Orb beside Tabetha's hut, then speak with her.", "Demon of the Orb slain"),
      finish(1955, P.tabetha),
      B.withGuide("dungeon-uldaman", accept(1956, P.tabetha, "Power in Uldaman needs an Uldaman group.")),
      action("goto", P.gorrik,
        "Travel to Kargath in the Badlands: fly to Orgrimmar, take the zeppelin to Grom'gol and fly on to Kargath."),
      goal(1956, at("Uldaman entrance", 42.4, 12.9, M.badlands),
        "Ride north-east to the Uldaman entrance with your group. Inside, kill the Obsidian Sentinel for its power source.",
        "Obsidian Power Source"),
      action("goto", P.shardi,
        "Return to Dustwallow Marsh: fly to Grom'gol, take the zeppelin to Orgrimmar and fly to Brackenwall Village."),
      finish(1956, P.tabetha),
      accept(1957, P.tabetha, "The Mana Surges come all at once and the quest is timed. Start with full mana."),
      goal(1957, P.tabetha, "Kill the Mana Surges around Tabetha's hut before the timer runs out.", "12 Mana Surge"),
      finish(1957, P.tabetha),
      accept(1958, P.tabetha),
      finish(1958, P.tabetha, "Speak with Tabetha again and choose your reward."),
    } })
end

-- Warlock: the felsteed at 40, the Orb of Orahil, and Impsy's chains in Felwood.
do
  local M, at, only = B.maps, B.at, B.only
  local accept, finish, goal, part, note, optional, withItem, action, taxi = B.accept, B.finish, B.objectiveAt,
    B.objectivePart, B.note, B.optional, B.withItem, B.action, B.taxi
  local warlock = "WARLOCK"
  local warlocks, orcTroll = { ORC, TROLL, UNDEAD }, { ORC, TROLL }
  local zevrost = at("Zevrost", 48.47, 45.43, M.orgrimmar)
  local kaal = at("Kaal Soulreaper", 86.21, 15.93, M.undercity)
  local toRatchet = "Travel to Ratchet on the Barrens coast: fly there from Orgrimmar. From the Undercity, take the zeppelin to Orgrimmar first."

  -- Summon Felsteed: Zevrost (Orgrimmar) and Kaal Soulreaper (Undercity) refer you to Strahad.
  need(warlock, 3631, "Summon Felsteed", 40, 40)
  need(warlock, 4489, "Summon Felsteed", 40, 40)
  need(warlock, 4490, "Summon Felsteed", 40, 40)
  B.breadcrumb(3631, 4490)
  B.breadcrumb(4489, 4490)
  B.hordeSide({ id = "warlock-felsteed-horde", title = "Warlock: Summon Felsteed", zone = M.barrens,
    levels = { 40, 40 }, class = warlock, start = warlocks,
    sources = { qdb, refB, "Reference guide A: Horde 37-38 chapter (warlock steps)" },
    steps = {
      only(accept(3631, zevrost, "At level 40, Zevrost in Orgrimmar's Cleft of Shadow has Summon Felsteed."), { race = orcTroll }),
      only(accept(4489, kaal, "At level 40, Kaal Soulreaper in the Undercity's Magic Quarter has Summon Felsteed."),
        { race = UNDEAD }),
      action("goto", P.bragok, toRatchet),
      only(finish(3631, P.strahad, "Climb the hill behind Ratchet to Strahad Farsan's house."), { race = orcTroll }),
      only(finish(4489, P.strahad, "Climb the hill behind Ratchet to Strahad Farsan's house."), { race = UNDEAD }),
      accept(4490, P.strahad),
      finish(4490, P.strahad, "Speak with Strahad again to learn Summon Felsteed."),
    } })

  -- The Orb of Orahil. QuestieDB gives the Orgrimmar referral (4967) Alliance races and the
  -- Stormwind one (4968) Horde races; this guide uses Zevrost's and Kaal Soulreaper's.
  need(warlock, 4967, "Knowledge of the Orb of Orahil", 35, 35)
  need(warlock, 4969, "Knowledge of the Orb of Orahil", 35, 35)
  need(warlock, 1799, "Fragments of the Orb of Orahil", 40, 35)
  need(warlock, 4962, "Shard of a Felhound", 40, 35)
  need(warlock, 4961, "Cleansing of the Orb of Orahil", 40, 35, 1799)
  need(warlock, 4976, "Returning the Cleansed Orb", 40, 35, 4961)
  need(warlock, 4964, "The Completed Orb of Dar'Orahil", 40, 35, 4976)
  B.breadcrumb(4967, 1799)
  B.breadcrumb(4969, 1799)
  B.hordeSide({ id = "warlock-orb-of-orahil-horde", title = "Warlock: The Orb of Orahil", zone = M.barrens,
    levels = { 35, 40 }, class = warlock, start = warlocks,
    sources = { qdb, refB },
    steps = {
      note(only(accept(4967, zevrost, "From level 35, Zevrost in Orgrimmar's Cleft of Shadow has Knowledge of the Orb of Orahil."),
        { race = orcTroll }),
        "QuestieDB lists this Orgrimmar referral for Alliance races (the Stormwind one for Horde). Check that Zevrost offers it."),
      only(accept(4969, kaal,
        "From level 35, Kaal Soulreaper in the Undercity's Magic Quarter has Knowledge of the Orb of Orahil."), { race = UNDEAD }),
      action("goto", P.bragok, toRatchet),
      only(finish(4967, P.menara, "Menara Voidrender stands beside Strahad Farsan in the house on the hill behind Ratchet."),
        { race = orcTroll }),
      only(finish(4969, P.menara, "Menara Voidrender stands beside Strahad Farsan in the house on the hill behind Ratchet."),
        { race = UNDEAD }),
      accept(1799, P.menara),
      note(accept(4962, at("Acolyte Wytula", 62.64, 35.3, M.barrens),
        "Speak with Menara's acolytes. This guide takes Acolyte Wytula's felhound path; Acolyte Magaz offers an infernal one instead."),
        "Check which orb each acolyte's path leads to."),
      taxi("fly", B.at("Thalon", 21.6, 74.1, 1443), "Shadowprey Village, Desolace", "Walk back down to Ratchet and fly to Shadowprey Village in Desolace."),
      withItem(12647, goal(4962, at(nil, 56.7, 75.5, M.desolace),
        "Ride east to Mannoroc Coven in southern Desolace. Use the Felhas Ruby on a felhound there: a Mage Hunter or a Mana Eater.",
        "Imprisoned Felhound Spirit")),
      goal(1799, at(nil, 80.4, 77.2, M.desolace),
        "Ride on east to Shadowbreak Ravine. Kill Burning Blade Summoners until an Infernal Orb drops.", "Infernal Orb"),
      taxi("fly", B.at("Shardi", 35.6, 31.9, 1445), "Brackenwall Village, Dustwallow Marsh",
        "Ride back to Shadowprey Village and fly to Brackenwall Village in Dustwallow Marsh."),
      finish(1799, P.tabetha, "Ride south from Brackenwall. Tabetha's hut stands in the hills in the west of the marsh."),
      accept(4961, P.tabetha, "Heal up first: Tabetha calls out the Demon of the Orb, a level 40 elite."),
      goal(4961, P.tabetha, "Kill the Demon of the Orb beside Tabetha's hut, then speak with her.", "Demon of the Orb slain"),
      finish(4961, P.tabetha),
      accept(4976, P.tabetha),
      taxi("fly", B.at("Bragok", 63.09, 37.16, 1413), "Ratchet, The Barrens", "Return to Brackenwall Village and fly to Ratchet."),
      finish(4962, P.menara, "Take the ruby and the spirit back to Menara above Ratchet."),
      finish(4976, P.menara),
      accept(4964, P.menara),
      finish(4964, P.menara, "Wait while Menara completes the orb, then speak with her again for the Orb of Dar'Orahil."),
    } })

  -- Impsy and Niby in Felwood.
  local impsy = at("Impsy", 41.36, 45.02, M.felwood)
  local niby = at("Niby the Almighty", 41.38, 44.85, M.felwood)
  local toFelwood = "Travel to Bloodvenom Post in Felwood: fly there from Orgrimmar, or take the north road out of Ashenvale."
  need(warlock, 8419, "An Imp's Request", 52, 50)
  need(warlock, 8420, "Hot and Itchy", 52, 50)
  -- Either An Imp's Request or Impsy's own Hot and Itchy opens The Wrong Stuff.
  need(warlock, 8421, "The Wrong Stuff", 52, 50)
  need(warlock, 8422, "Trolls of a Feather", 52, 50, 8421)
  B.hordeSide({ id = "warlock-trolls-of-a-feather-horde", title = "Warlock: Trolls of a Feather", zone = M.felwood,
    levels = { 52, 54 }, class = warlock, start = warlocks,
    sources = { qdb, refB, "Reference guide A: Horde 52-53, 53-54 and 55-56 chapters (warlock steps)" },
    steps = {
      only(accept(8419, zevrost,
        "From level 50, Zevrost in Orgrimmar's Cleft of Shadow has An Imp's Request. If you are already in Felwood, use Next and take Hot and Itchy from Impsy: same task, same follow-up."),
        { race = orcTroll }),
      only(accept(8419, kaal,
        "From level 50, Kaal Soulreaper in the Undercity's Magic Quarter has An Imp's Request. If you are already in Felwood, use Next and take Hot and Itchy from Impsy: same task, same follow-up."),
        { race = UNDEAD }),
      goal(8419, nil,
        "Get a piece of Felcloth: Jadefire satyrs in Felwood drop it (Jadefire Glen in the south, 36, 67), so do Legashi satyrs in north-east Azshara. You can also buy one.",
        "Felcloth"),
      action("goto", P.brakkar, toFelwood),
      finish(8419, impsy, "Impsy floats beside Niby the Almighty, a short ride north-east of Bloodvenom Post."),
      optional(finish(8420, impsy, "Give Impsy the Felcloth for Hot and Itchy.")),
      accept(8421, impsy),
      part(8421, 2, at(nil, 42.4, 47.0, M.felwood),
        "Kill Tainted Oozes along the Bloodvenom river just south of Impsy for Bloodvenom Essence.", "4 Bloodvenom Essence"),
      part(8421, 1, at(nil, 48.8, 20.5, M.felwood),
        "Ride north to the Irontree Woods and kill Irontree Stompers for Rotting Wood.", "10 Rotting Wood"),
      finish(8421, impsy),
      B.withGuide("dungeon-sunken-temple", accept(8422, impsy, "Trolls of a Feather needs a Sunken Temple group.")),
      action("goto", P.breyk, P.toStonard),
      goal(8422, P.temple, P.trollFeathers, "2 Amber Voodoo Feather", "2 Blue Voodoo Feather", "2 Green Voodoo Feather"),
      action("goto", P.brakkar, "Return to Felwood: fly to Orgrimmar and on to Bloodvenom Post."),
      finish(8422, impsy, "Bring the feathers back to Impsy."),
    } })

  need(warlock, 7601, "What Niby Commands", 50, 50)
  need(warlock, 7602, "Flawless Fel Essence", 55, 50, 7601)
  need(warlock, 7603, "Kroshius' Infernal Core", 55, 50, 7602)
  B.hordeSide({ id = "warlock-kroshius-horde", title = "Warlock: Kroshius' Infernal Core", zone = M.felwood,
    levels = { 54, 56 }, class = warlock, start = warlocks,
    sources = { qdb, refB },
    steps = {
      action("goto", P.brakkar, toFelwood),
      accept(7601, niby, "Niby the Almighty and his imp Impsy stand a short ride north-east of Bloodvenom Post."),
      finish(7601, impsy),
      accept(7602, impsy),
      goal(7602, at(nil, 36.7, 46.0, M.felwood),
        "Collect three Flawless Fel Essences: from Jaedenar Legionnaires here in Felwood, Legashi satyrs in north-east Azshara (62, 24) and Felguard Sentries by the Dark Portal in the Blasted Lands (58, 51).",
        "Flawless Fel Essence (Jaedenar)", "Flawless Fel Essence (Azshara)", "Flawless Fel Essence (Dark Portal)"),
      action("goto", P.brakkar, "Return to Bloodvenom Post in Felwood."),
      finish(7602, impsy),
      accept(7603, impsy, "Kroshius is a level 55 elite infernal. Bring help if you need it."),
      withItem(18626, goal(7603, at("Kroshius' Remains", 45.7, 34.76, M.felwood),
        "Ride north to Shatter Scar Vale and use the Fel Fire beside Kroshius' remains. Kill Kroshius when he wakes and take his core.",
        "Kroshius' Infernal Core")),
      finish(7603, niby, "Bring the core back to Niby the Almighty."),
    } })
end

-- Druid: Torwa Pathfinder's poison in Un'Goro, ending at the bottom of the Sunken Temple.
do
  local M, at = B.maps, B.at
  local accept, finish, goal, withItem, action, taxi = B.accept, B.finish, B.objectiveAt, B.withItem, B.action, B.taxi
  local druid = "DRUID"
  local torwa = at("Torwa Pathfinder", 71.64, 75.96, M.ungoro)
  local northRoad = at(nil, 60.0, 45.0, M.ungoro)
  need(druid, 9063, "Torwa Pathfinder", 52, 50)
  need(druid, 9052, "Bloodpetal Poison", 52, 50, 9063)
  need(druid, 9051, "Toxic Test", 52, 50, 9052)
  need(druid, 9053, "A Better Ingredient", 52, 50, 9051)
  B.hordeSide({ id = "druid-better-ingredient-horde", title = "Druid: A Better Ingredient", zone = M.ungoro,
    levels = { 52, 54 }, class = druid, start = { TAUREN, SKYBORNE },
    sources = { qdb, refB, "Reference guide A: Horde 54-55 and 55-56 chapters (druid steps)" },
    steps = {
      accept(9063, at("Turak Runetotem", 76.48, 27.22, M.thunderBluff),
        "From level 50, Turak Runetotem on Elder Rise in Thunder Bluff sends you to Torwa. Jannos Lighthoof near Camp Mojache in Feralas and Loganaar in Moonglade give it too."),
      taxi("fly", B.at("Bulkrek Ragefist", 51.6, 25.4, 1446), "Gadgetzan, Tanaris", "Fly from Thunder Bluff to Gadgetzan in Tanaris."),
      action("goto", at(nil, 27.8, 56.9, M.tanaris), "Ride west across Tanaris to the ridge path that leads down into Un'Goro Crater."),
      finish(9063, torwa, "Torwa Pathfinder camps where the path from Tanaris enters the crater."),
      accept(9052, torwa),
      goal(9052, at(nil, 49.0, 77.5, M.ungoro),
        "Kill Gorishi wasps and workers at the hive in southern Un'Goro for their stings. Pick Bloodcaps from the red Bloodpetal sprouts you pass across the crater.",
        "8 Gorishi Sting", "8 Bloodcap"),
      finish(9052, torwa),
      accept(9051, torwa),
      action("goto", northRoad, "Ride north through the middle of the crater."),
      withItem(22432, goal(9051, at("Devilsaur", 57.3, 23.7, M.ungoro),
        "Find a Devilsaur and use the Devilsaur Barb on it. Devilsaurs are elite: get clear once you have stabbed it. Others roam the north-west (35, 22).",
        "Stab a Devilsaur")),
      action("goto", northRoad, "Ride back south through the crater toward Torwa."),
      finish(9051, torwa),
      B.withGuide("dungeon-sunken-temple", accept(9053, torwa, "A Better Ingredient needs a Sunken Temple group.")),
      action("goto", P.breyk,
        "Travel to Stonard in the Swamp of Sorrows: fly to Orgrimmar, take the zeppelin to Grom'gol and fly on to Stonard."),
      goal(9053, P.temple, "Kill Atal'alarion, the guardian at the bottom of the Sunken Temple, for the Putrid Vine.", "Putrid Vine"),
      action("goto", at(nil, 27.8, 56.9, M.tanaris),
        "Return to Un'Goro: fly to Gadgetzan and ride west to the ridge path into the crater."),
      finish(9053, torwa, "Bring the vine back to Torwa."),
    } })
end

-- Shaman: the Forever weapon chain after Call of Air (Thousand Needles, four totem zones,
-- Razorfen Kraul), then Bath'rah's Sunken Temple chain at 50.
do
  local M, at = B.maps, B.at
  local accept, finish, goal, part, note, withItem, action, taxi = B.accept, B.finish, B.objectiveAt,
    B.objectivePart, B.note, B.withItem, B.action, B.taxi
  local shaman = "SHAMAN"
  local prate = at("Prate Cloudseer", 53.54, 42.65, M.needles)
  local rau = at("Rau Cliffrunner", 46.14, 51.71, M.needles)
  local prateText = "Ride out to Prate Cloudseer on the mesas north-east of Freewind Post."
  need(shaman, 79360, "Elemental Aid", 33, 30, nil, true)
  need(shaman, 79364, "Eyes on the Sky", 33, 30, 79360, true)
  need(shaman, 79361, "Storm, Earth, and Fire", 38, 30, 79364, true)
  need(shaman, 79366, "Heed My Call", 40, 30, 79361, true)
  need(shaman, 79442, "The Tempest's Weapons", 40, 30, 79366, true)
  B.hordeSide({ id = "shaman-tempests-weapons-horde", title = "Shaman: The Tempest's Weapons", zone = M.needles,
    levels = { 35, 40 }, class = shaman,
    sources = { qdb, "https://www.wowhead.com/forever/quest=79366", "https://www.wowhead.com/forever/quest=79442",
      "https://conquestcapped.com/guides/wow-forever/wow-forever-shaman-weapon-quest/" },
    steps = {
      note(accept(79360, prate,
        "After Call of Air, Prate Cloudseer has Elemental Aid. It sends you to the end of Razorfen Kraul, so plan a group."),
        "QuestieDB has no level or prerequisite for this Forever chain. Check that Prate offers it right after Call of Air."),
      taxi("fly", B.at("Omusa Thunderhorn", 44.45, 59.15, 1413), "Camp Taurajo, The Barrens", "Ride back to Freewind Post and fly to Camp Taurajo."),
      B.withGuide("dungeon-razorfen-kraul", note(goal(79360, at("Razorfen Kraul approach", 42.9, 90.2, M.barrens),
        "Ride south to the far end of the Barrens and down the thorny path to Razorfen Kraul. Inside, defeat Charlga Razorflank in her hut and loot the note with the quilboar's plans.",
        "Tattered Note"), "Check the name of the quest item Charlga drops.")),
      taxi("fly", B.at("Nyse", 45.14, 49.11, 1441), "Freewind Post, Thousand Needles",
        "Fly from Camp Taurajo back to Freewind Post."),
      finish(79360, rau, "Rau Cliffrunner stands in Freewind Post."),
      accept(79364, rau),
      finish(79364, prate, prateText),
      accept(79361, prate, "The four kinds of Twisted Totem only drop while you have this quest, in four zones."),
      taxi("fly", B.at("Shardi", 35.6, 31.9, 1445), "Brackenwall Village, Dustwallow Marsh", "Fly from Freewind Post to Brackenwall Village in Dustwallow Marsh."),
      note(part(79361, 1, at(nil, 57.5, 15.0, M.dustwallow),
        "Ride east along the northern shore to the Mirefin murloc camps on the north-east coast. Kill murlocs for 5 Twisted Water Totems.",
        "5 Twisted Water Totem"), "Objective order is QuestieDB's. Use Next if this step waits on another totem."),
      taxi("fly", B.at("Thalon", 21.6, 74.1, 1443), "Shadowprey Village, Desolace", "Ride back to Brackenwall Village and fly to Shadowprey Village in Desolace."),
      note(part(79361, 4, at(nil, 33.5, 57.0, M.desolace),
        "Ride north-east to the Maraudine centaur camps in western Desolace. Kill centaurs for 5 Twisted Air Totems.",
        "5 Twisted Air Totem"), "Objective order is QuestieDB's. Use Next if this step waits on another totem."),
      taxi("fly", B.at("Doras", 45.12, 63.89, 1454), "Orgrimmar, Durotar", "Ride back to Shadowprey Village and fly to Orgrimmar."),
      action("boat", P.toGromgol, "Take the zeppelin to Grom'gol from the tower north of Orgrimmar."),
      taxi("fly", B.at("Breyk", 46.1, 54.8, 1435), "Stonard, Swamp of Sorrows", "Fly from Grom'gol to Stonard."),
      note(part(79361, 2, at(nil, 58.0, 27.0, M.swamp),
        "Ride north-east from Stonard to the Lost Ones' huts in the north-east of the swamp. Kill them for 5 Twisted Earth Totems.",
        "5 Twisted Earth Totem"), "Objective order is QuestieDB's. Use Next if this step waits on another totem."),
      taxi("fly", B.at("Gorrik", 4, 44.8, 1418), "Kargath, Badlands", "Ride back to Stonard and fly to Kargath in the Badlands."),
      note(part(79361, 3, at(nil, 65.5, 23.5, M.badlands),
        "Ride east across the Badlands to the Dustbelcher ogre camp in the north-east. Kill ogres for 5 Twisted Fire Totems. The Stonevault troggs in the south (49, 68) drop them too.",
        "5 Twisted Fire Totem"), "Objective order is QuestieDB's. Use Next if this step waits on another totem."),
      taxi("fly", B.at("Thysta", 32.5, 29.4, 1434), "Grom'gol, Stranglethorn", "Ride back to Kargath and fly to Grom'gol."),
      action("boat", P.gromgolToOrgrimmar, "Take the zeppelin to Orgrimmar."),
      taxi("fly", B.at("Nyse", 45.14, 49.11, 1441), "Freewind Post, Thousand Needles", "Fly from Orgrimmar to Freewind Post."),
      finish(79361, prate, prateText),
      accept(79366, prate,
        "Heed My Call ends in waves of elementals, an elite quilboar and the elite Ravaging Tempest. Bring friends."),
      note(withItem("Corrupted Totems", goal(79366, at("Ravaging Tempest", 36.6, 38.3, M.needles),
        "Go to the steam pools west of Freewind Post. Use the Corrupted Totems there, kill each wave of elementals, then the quilboar and the Ravaging Tempest. Loot the Eye of the Tempest.",
        "Eye of the Tempest")), "Check where the ritual starts and whether a quest flight takes you there."),
      note(finish(79366, rau, "Return to Rau Cliffrunner in Freewind Post."),
        "QuestieDB has no turn-in NPC for the Horde Heed My Call; one database page names Rau Cliffrunner."),
      note(accept(79442, rau, "Take The Tempest's Weapons: Bath'rah the Windwatcher in Alterac makes the weapon."),
        "The Horde giver of The Tempest's Weapons is not in QuestieDB. Check whether Rau or Prate offers it."),
      taxi("fly", B.at("Doras", 45.12, 63.89, 1454), "Orgrimmar, Durotar", "Fly from Freewind Post to Orgrimmar."),
      action("boat", P.toUndercity, "Take the zeppelin to Tirisfal Glades from the tower north of Orgrimmar."),
      taxi("fly", B.at("Zarise", 60.14, 18.62, 1424), "Tarren Mill, Hillsbrad", "Walk into the Undercity and fly to Tarren Mill."),
      finish(79442, P.bathrah,
        "Bath'rah camps by his cauldron in the hills just over the Alterac border, north-east of Tarren Mill. Choose Rage of the Storm, Lightning's Grasp or Tidebringer's Claw."),
    } })

  need(shaman, 8410, "Elemental Mastery", 50, 50)
  need(shaman, 8412, "Spirit Totem", 52, 50, 8410)
  need(shaman, 8413, "Da Voodoo", 52, 50, 8412)
  B.hordeSide({ id = "shaman-da-voodoo-horde", title = "Shaman: Da Voodoo", zone = M.alterac,
    levels = { 52, 54 }, class = shaman, start = { ORC, TROLL, TAUREN, SKYBORNE },
    sources = { qdb, refB },
    steps = {
      B.only(accept(8410, at("Kardris Dreamseeker", 38.8, 36.37, M.orgrimmar),
        "From level 50, Kardris Dreamseeker in Orgrimmar's Valley of Wisdom has Elemental Mastery."),
        { race = { ORC, TROLL, SKYBORNE } }),
      B.only(accept(8410, at("Beram Skychaser", 21.99, 18.8, M.thunderBluff),
        "From level 50, Beram Skychaser on Spirit Rise in Thunder Bluff has Elemental Mastery."), { race = TAUREN }),
      action("goto", P.urda,
        "Travel to Hammerfall in Arathi: take the zeppelin to Tirisfal Glades and fly from the Undercity to Hammerfall."),
      goal(8410, at(nil, 66.7, 29.1, M.arathi),
        "Get one Elemental Air, Fire, Earth and Water. The Exile elementals of Arathi drop all four: Cresting Exiles (water) west of Hammerfall, Thundering Exiles (air) in the middle (52, 50), Rumbling Exiles (earth) at 36, 57 and Burning Exiles (fire) in the north-west hills (26, 30). The auction house sells them too.",
        "Elemental Air", "Elemental Fire", "Elemental Earth", "Elemental Water"),
      action("goto", P.bathrah, "Take the road west out of Arathi into Hillsbrad and climb north-east of Tarren Mill to Bath'rah's camp."),
      finish(8410, P.bathrah, "Bath'rah camps by his cauldron in the hills just over the Alterac border."),
      accept(8412, P.bathrah),
      note(action("goto", at(nil, 38.0, 74.0, M.wpl),
        "Ride north through the Alterac Mountains into the Western Plaguelands. Keep clear of the Alliance's Chillwind Camp just east of here."),
        "Check the way from Bath'rah's camp north into the plaguelands; the Undercity and the Bulwark are the other way in."),
      goal(8412, at(nil, 35.2, 63.7, M.wpl),
        "Kill Venom Mist Lurkers for Bloodshot Spider Eyes and Diseased Black Bears for Thick Black Claws in the south-west of the plaguelands.",
        "8 Bloodshot Spider Eye", "8 Thick Black Claw"),
      action("goto", P.bathrah, "Ride back south through the Alterac Mountains to Bath'rah."),
      finish(8412, P.bathrah),
      B.withGuide("dungeon-sunken-temple", accept(8413, P.bathrah, "Da Voodoo needs a Sunken Temple group.")),
      action("goto", P.breyk, "Travel to Stonard in the Swamp of Sorrows: fly there from Tarren Mill."),
      goal(8413, P.temple, P.trollFeathers, "2 Amber Voodoo Feather", "2 Blue Voodoo Feather", "2 Green Voodoo Feather"),
      action("goto", P.zarise, "Fly back to Tarren Mill in Hillsbrad."),
      finish(8413, P.bathrah, "Bring the feathers back to Bath'rah, north-east of Tarren Mill."),
    } })
end

linkRun("dungeon-sunken-temple", { "warrior-voodoo-feathers-horde", "hunter-green-drake-horde",
  "priest-blood-of-morphaz-horde", "rogue-azure-key-horde", "mage-destroy-morphaz-horde",
  "warlock-trolls-of-a-feather-horde", "druid-better-ingredient-horde", "shaman-da-voodoo-horde" })
linkRun("dungeon-uldaman", { "mage-celestial-power-horde" })
linkRun("dungeon-razorfen-kraul", { "shaman-tempests-weapons-horde" })

-- Class objectives the Horde 30-60 route passes anyway: copies of the class guides' objective steps,
-- shown only to that class and only while the quest is in the log (`logOnly`), placed after the
-- closest step on the same map in that chapter. List: the end of the class audit file.
do
  local sections = {}
  for _, s in ipairs(LevelingCodexQuests.HORDE.sections) do sections[s.id] = s end
  local plural = { WARRIOR = "Warriors", HUNTER = "Hunters", ROGUE = "Rogues", PRIEST = "Priests",
    SHAMAN = "Shamans", MAGE = "Mages", WARLOCK = "Warlocks", DRUID = "Druids", PALADIN = "Paladins" }
  local function classStep(quest, index)
    for _, s in ipairs(LevelingCodexQuests.HORDE.sections) do
      if s.side and s.class then
        for _, step in ipairs(s.steps) do
          if step.type == "complete" and step.quest == quest and step.objectiveIndex == index and step.map then
            return step
          end
        end
      end
    end
    error("Horde class objectives: no class step for " .. quest .. " objective " .. tostring(index))
  end
  local function passing(routeId, quest, index)
    local found = classStep(quest, index)
    local route = assert(sections[routeId], "Horde class objectives: no section " .. routeId)
    local best, bestD
    for i, step in ipairs(route.steps) do
      if step.map == found.map and step.x and not step.logOnly then
        local d = (step.x - found.x) ^ 2 + (step.y - found.y) ^ 2
        if not bestD or d < bestD then best, bestD = i, d end
      end
    end
    assert(best, "Horde class objectives: " .. routeId .. " never visits that map")
    local copy = {}
    for k, v in pairs(found) do copy[k] = v end
    copy.logOnly, copy.phase, copy.guide, copy.sticky = true, nil, nil, nil
    local class = type(found.class) == "string" and found.class or nil
    copy.text = (class and (plural[class] .. " with " .. found.name .. ": ") or "") .. found.text
    table.insert(route.steps, best + 1, copy)
  end
  passing("stv-35", 1712, 2)          -- Warrior: Bloodscalp tusks for Cyclonian
  passing("desolace-34", 79361, 4)    -- Shaman: Twisted Air Totems from the Maraudine
  passing("dustwallow-37", 79361, 1)  -- Shaman: Twisted Water Totems from the Mirefin murlocs
  passing("badlands-39", 79361, 3)    -- Shaman: Twisted Fire Totems from the Dustbelcher ogres
  passing("swamp-41", 79361, 2)       -- Shaman: Twisted Earth Totems from the Lost Ones
  passing("desolace-34", 1954, nil)   -- Mage: the Infernal Orb
  passing("desolace-34", 1799, nil)   -- Warlock: Fragments of the Orb of Orahil
  passing("desolace-41", 4962, nil)   -- Warlock: the Felhas Ruby at Mannoroc Coven
  passing("blasted-50", 8423, nil)    -- Warrior: Helboars
  passing("blasted-50", 8424, nil)    -- Warrior: the Shadowsworn
  passing("azshara-52", 8153, nil)    -- Hunter: courser antlers
  passing("azshara-52", 8231, nil)    -- Hunter: Wavethrasher scales
  passing("azshara-52", 8255, nil)    -- Priest: courser glands
  passing("azshara-52", 8251, nil)    -- Mage: blood elf dust
  passing("azshara-52", 8252, nil)    -- Mage: siren coral
  passing("azshara-52", 8234, nil)    -- Rogue: the Sealed Azure Bag
  passing("azshara-52", 8235, nil)    -- Rogue: encoded fragments
  passing("plaguelands-56", 8256, nil) -- Priest: Ichor of Undeath
end
