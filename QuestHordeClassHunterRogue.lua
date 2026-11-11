-- Horde class quests through level 30: Hunter and Rogue. Source notes: tools/audits/2026-11-10-horde-class-*.md.
local B = LevelingCodexQuests.build

local ORC_TROLL = { "ORC", "TROLL" }

-- Hunter: Orc and Troll taming at Razor Hill (Tauren tame in Mulgore, Skyborne in Valanaar; both
-- are already in their starting routes). Done on the Razor Hill stop after the first Orgrimmar
-- visit, so everyone is level 10; Training the Beast goes to Ormak on the second visit.
do
  local at, q, accept, finish, objective, withItem = B.at, B.q, B.accept, B.finish, B.objectiveAt, B.withItem
  local M = B.maps
  local function du(name, x, y) return at(name, x, y, M.durotar) end
  local thotar = du("Thotar", 51.85, 43.49)
  local ormak = at("Ormak Grimshot", 66.05, 18.53, M.orgrimmar)

  q(6062, "Taming the Beast", 10, 10, nil, nil, "HUNTER")
  q(6083, "Taming the Beast", 10, 10, 6062, nil, "HUNTER")
  q(6082, "Taming the Beast", 10, 10, 6083, nil, "HUNTER")
  q(6081, "Training the Beast", 10, 10, 6082, nil, "HUNTER")
  for _, id in ipairs({ 6062, 6083, 6082, 6081 }) do B.quest[id].race = ORC_TROLL end

  B.hordeInline("northern-durotar", "turnin", 837, {
    accept(6062, thotar, "Hunters: Thotar waits inside the bunker in Razor Hill. Take his first Taming Rod."),
    withItem(15917, objective(6062, du(nil, 54.5, 45.9),
      "Dire Mottled Boars graze just east of town. Use the Taming Rod from its full range and stand still until the channel ends.",
      "Tame a Dire Mottled Boar")),
    finish(6062, thotar),
    accept(6083, thotar),
    withItem(15919, objective(6083, du(nil, 59.8, 25.4),
      "Dismiss the boar (right-click its portrait). Go north to the coast east of Drygulch Ravine and use the new rod on a Surf Crawler at the water's edge.",
      "Tame a Surf Crawler")),
    finish(6083, thotar),
    accept(6082, thotar),
    withItem(15920, objective(6082, du(nil, 54.7, 34.1),
      "Dismiss the crawler. Armored Scorpids crawl over the rocks north of Razor Hill. Tame one with the third rod.",
      "Tame an Armored Scorpid")),
    finish(6082, thotar, "Bring the rod back to Thotar. You learn Tame Beast and can now keep a pet."),
    accept(6081, thotar, "Take Thotar's letter for Ormak in Orgrimmar. Tame a pet of your own whenever you like."),
  })
  B.hordeInline("northern-durotar", "turnin", 96877, {
    finish(6081, ormak,
      "Hunters: find the Hunter's Hall in the north of the Valley of Honor and give Ormak the letter. Xao'tsu next to him teaches pet feeding and training."),
  })
end

-- Rogue: the Orc and Troll level 10 chain (Therzok's Shattered Hand), placed on the route's own
-- Orgrimmar and Southsea stops. RestedXP takes The Shattered Hand straight from Therzok for Orcs
-- and Trolls, so Kaplak's referral (Orcs only) is a breadcrumb.
do
  local at, q, accept, finish, objective = B.at, B.q, B.accept, B.finish, B.objectiveAt
  local M = B.maps
  local function og(name, x, y) return at(name, x, y, M.orgrimmar) end
  local kaplak = at("Kaplak", 51.98, 43.69, M.durotar)
  local therzok = og("Therzok", 42.73, 53.55)
  local gamon = og("Gamon", 54.0, 68.03)

  q(1859, "Therzok", 10, 10, nil, nil, "ROGUE")
  B.quest[1859].race = "ORC"
  B.breadcrumb(1859, 1963)
  q(1963, "The Shattered Hand", 13, 10, nil, nil, "ROGUE")
  q(1858, "The Shattered Hand", 13, 10, 1963, nil, "ROGUE")
  B.quest[1963].race, B.quest[1858].race = ORC_TROLL, ORC_TROLL

  B.hordeInline("northern-durotar", "accept", 840, {
    accept(1859, kaplak, "Orc rogues: Kaplak, the rogue trainer by the Razor Hill bunker, sends you to Therzok in Orgrimmar."),
  })
  B.hordeInline("northern-durotar", "getfp", nil, {
    finish(1859, therzok, "Orc rogues: go down into the Cleft of Shadow, the dark ravine north-west of the Valley of Strength. Therzok stands near the rogue trainer."),
    accept(1963, therzok, "Rogues: take Therzok's job in the Cleft of Shadow, the dark ravine north-west of the Valley of Strength."),
  })
  B.hordeInline("crossroads", "complete", 887, {
    objective(1963, at(nil, 64.3, 44.1, M.barrens),
      "Rogues: Tazan, a level 13 pirate, walks between the first Southsea camp and the hill above it. Kill him and loot his satchel.",
      "Tazan's Satchel"),
  })
  B.hordeInline("barrens-north", "accept", 5761, {
    finish(1963, therzok, "Rogues: bring the satchel to Therzok in the Cleft of Shadow."),
    accept(1858, therzok),
    objective(1858, gamon,
      "The satchel is locked. With Pick Lock (trained at 16) open it from your bags. Otherwise go to the inn in the Valley of Strength, pick pocket Gamon for Tazan's Key and use it on the satchel.",
      "Tazan's Logbook"),
    finish(1858, therzok, "Take the logbook back to Therzok."),
  })
end

-- Rogue side guides, levels 16-30.
do
  local at, q, accept, finish, objective, withItem = B.at, B.q, B.accept, B.finish, B.objectiveAt, B.withItem
  local M = B.maps
  local function og(name, x, y) return at(name, x, y, M.orgrimmar) end
  local function ba(name, x, y) return at(name, x, y, M.barrens) end
  local shenthul = og("Shenthul", 43.05, 53.74)
  local zandozan = og("Zando'zan", 42.73, 52.95)
  local wrenix = ba("Wrenix the Wretched", 63.07, 36.32)
  local fizzule = ba("Taskmaster Fizzule", 55.44, 5.56)
  local hinott = at("Serge Hinott", 61.63, 19.19, M.hillsbrad)
  local mennet = at("Mennet Carkad", 83.51, 69.11, M.undercity)
  local lockSource = "https://www.zockify.com/forever/rogue/lockpicking/"
  local poisonSource = "https://www.zockify.com/forever/rogue/poison-quest/"

  -- Lockpicking: Shenthul -> Zando'zan -> Wrenix in Ratchet, practice on the Tide Razor.
  q(2379, "Zando'zan", 16, 16, nil, nil, "ROGUE")
  q(2382, "Wrenix of Ratchet", 16, 16, 2379, nil, "ROGUE")
  q(2381, "Plundering the Plunderers", 18, 16, 2382, nil, "ROGUE")
  B.hordeSide({ id = "rogue-lockpicking-horde", title = "Rogue: Lockpicking", zone = M.barrens, levels = { 16, 20 },
    class = "ROGUE", sources = { lockSource },
    steps = {
      accept(2379, shenthul,
        "Train Pick Lock at level 16 first. Shenthul stands at the back of the Cleft of Shadow in Orgrimmar. If you carry To Orgrimmar! or Find the Shattered Hand, hand it to him first."),
      finish(2379, zandozan, "Zando'zan stands a few steps north of Shenthul."),
      accept(2382, zandozan),
      finish(2382, wrenix, "Fly or ride to Ratchet. Wrenix stands beside his machine near the flight master."),
      accept(2381, wrenix,
        "Take the job, then use Wrenix's Gizmotronic Apparatus next to him for an E.C.A.C. and Thieves' Tools. Check that both are in your bags."),
      objective(2381, ba("Buccaneer's Strongbox", 65.06, 45.45),
        "Board the Tide Razor, the pirate ship moored off the Southsea camps south of Ratchet. Below deck, cast Pick Lock on the Buccaneer's Strongboxes until your Lockpicking is about 70. Use Next when you get there."),
      withItem(7970, objective(2381, ba("The Jewel of the Southsea", 64.95, 45.44),
        "Go down to the lowest deck and open The Jewel of the Southsea. When Polly the parrot appears, use the E.C.A.C. on her first, then kill her for the treasure.",
        "Southsea Treasure")),
      finish(2381, wrenix, "Bring the treasure back to Wrenix in Ratchet. Keep practicing on lockboxes until you reach 80 for the poison job."),
    },
  })

  -- Poisons: Shenthul -> Fizzule at the Venture Co. tower -> Gallywix -> Serge Hinott's cure.
  q(2460, "The Shattered Salute", 20, 20, nil, nil, "ROGUE")
  q(2458, "Deep Cover", 20, 20, 2460, nil, "ROGUE")
  q(2478, "Mission: Possible But Not Probable", 24, 20, 2458, nil, "ROGUE")
  q(2479, "Hinott's Assistance", 26, 20, 2478, nil, "ROGUE")
  q(2480, "Hinott's Assistance", 20, 20, 2479, nil, "ROGUE")
  B.hordeSide({ id = "rogue-poisons-horde", title = "Rogue: Poisons", zone = M.barrens, levels = { 20, 26 },
    class = "ROGUE", sources = { poisonSource, lockSource },
    steps = {
      accept(2460, shenthul,
        "Get your Lockpicking to 80 and carry Thieves' Tools before you start: the job ends at a lockbox that needs 80. Shenthul is in the Cleft of Shadow."),
      objective(2460, shenthul, "Target Shenthul and type /salute.", "Shattered Salute Performed"),
      finish(2460, shenthul),
      accept(2458, shenthul),
      withItem(8051, objective(2458, ba(nil, 54.0, 9.0),
        "Ride to the Venture Co. tower north of the Sludge Fen, in the far north of the Barrens. As soon as the tower is in sight, fire the Flare Gun twice. Use Next after the second flare.")),
      finish(2458, fizzule,
        "Walk up to Taskmaster Fizzule at the foot of the tower, target him and type /salute before anything else. He attacks rogues who skip it."),
      accept(2478, fizzule),
      objective(2478, ba("Foreman Silixiz", 54.8, 6.0),
        "Pick pocket Foreman Silixiz outside the tower for his key. Do it first: Gallywix's lockbox can curse you and the curse stops Stealth.",
        "Silixiz's Tower Key"),
      objective(2478, ba(nil, 54.7, 5.7),
        "Climb the tower and kill two Mutated Venture Co. Drones, two Venture Co. Patrollers and two Venture Co. Lookouts on the way up.",
        "Mutated Venture Co. Drone", "Venture Co. Patroller", "Venture Co. Lookout"),
      objective(2478, ba("Grand Foreman Puzik Gallywix", 54.76, 5.56),
        "Gallywix, a level 23 elite, is at the top. Open with Ambush; from level 22 Vanish and Ambush again. Take his head, then pick his lockbox for the Cache of Zanzil's Altered Mixture.",
        "Gallywix's Head", "Cache of Zanzil's Altered Mixture"),
      finish(2478, shenthul, "Return to Shenthul in Orgrimmar. You learn the Thistle Tea recipe."),
      accept(2479, shenthul),
      finish(2479, hinott,
        "Take the zeppelin to Tirisfal Glades, then the road south through Silverpine to Tarren Mill in Hillsbrad. Give Serge Hinott the sample."),
      accept(2480, hinott),
      finish(2480, hinott, "Wait beside Hinott while he brews the cure, then turn in to learn Poisons. Use Hinott's Oil to clear the Touch of Zanzil."),
    },
  })

  -- Undead: Mennet Carkad's lockpicking jobs in Silverpine.
  q(1998, "Fenwick Thatros", 16, 16, nil, nil, "ROGUE")
  q(1999, "Tools of the Trade", 20, 16, 1998, nil, "ROGUE")
  B.quest[1998].race, B.quest[1999].race = "SCOURGE", "SCOURGE"
  B.hordeSide({ id = "rogue-tools-of-the-trade", title = "Rogue: Tools of the Trade", zone = M.silverpine, levels = { 16, 22 },
    class = "ROGUE", start = "SCOURGE", sources = { "https://www.wowhead.com/classic/quest=1999/tools-of-the-trade" },
    steps = {
      accept(1998, mennet, "Mennet Carkad stands in the Rogues' Quarter of the Undercity."),
      objective(1998, at("Fenwick Thatros", 59.6, 33.9, M.silverpine),
        "Go to Silverpine Forest. Fenwick Thatros stands on the shore of Lordamere Lake east of the main road. Kill him and take his head.",
        "Fenwick's Head"),
      finish(1998, mennet),
      accept(1999, mennet, "Take the next job. Carry Thieves' Tools and know Pick Lock."),
      objective(1999, at("Ambermill Strongbox", 63.71, 65.24, M.silverpine),
        "Go to Ambermill, the Dalaran village in eastern Silverpine. Stealth past the mages and pick the lock on the Ambermill Strongbox for the report.",
        "Dalaran Status Report"),
      finish(1999, mennet, "Bring the report to Mennet in the Undercity."),
    },
  })
end

-- Rogue: Forever's solo jobs for C and the Ravenholdt quests (both factions, same quest IDs as
-- the Alliance guides).
do
  local at, q, accept, finish, objective, withItem = B.at, B.q, B.accept, B.finish, B.objectiveAt, B.withItem
  local M = B.maps
  local silverpine, stonetalon, hillsbrad, alterac, tirisfal = M.silverpine, M.stonetalon, M.hillsbrad, M.alterac, M.tirisfal
  local deadDrop = at("Dead Drop", 47.12, 70.99, silverpine)
  local sfk = at("Shadowfang Keep", 44.8, 67.8, silverpine)
  local fahrad = at("Fahrad", 84.45, 80.32, alterac)
  local myrokos = at("Myrokos Silentform", 84.93, 80.38, alterac)

  q(78261, "The Horn of Xelthos", 23, 20, nil, true, "ROGUE")
  q(78307, "The Horn of Xelthos", 23, 20, 78261, true, "ROGUE")
  B.hordeSide({ id = "rogue-horn-of-xelthos-horde", title = "Rogue: The Horn of Xelthos", zone = silverpine,
    levels = { 20, 26 }, class = "ROGUE",
    sources = { "https://www.zockify.com/forever/dungeons/shadowfang-keep/",
      "https://www.wowhead.com/forever/quest=78270/goblin-lockpicks" },
    steps = {
      accept(78261, deadDrop,
        "From level 20, look for C's letter in your mail. The Dead Drop is a crate in a hut near Pyrewood Village, below the road up to Shadowfang Keep. The job must be done alone."),
      objective(78261, at("Veenix", 58.22, 51.74, stonetalon),
        "Find Veenix in Windshear Crag, Stonetalon Mountains, and ask about Goblin Lockpicks. Pick pocket Venture Co. workers there until you have a Work Order, then trade it to him for a Breaching Charge. Use Next once you have it."),
      withItem(210186, objective(78261, sfk,
        "Enter Shadowfang Keep on your own. Blow the locked courtyard gate with the Breaching Charge. Pick pocket Gemela in the dining hall and Gefell up the stairs beyond for the two key halves. Use Next once you have both.")),
      objective(78261, nil,
        "Join the key halves somewhere quiet, as it breaks Stealth. Go back to the courtyard stables and open the locked chest with the Twin Key.",
        "Horn of Xelthos"),
      finish(78261, deadDrop),
      accept(78307, deadDrop, "Visit Orgrimmar, Thunder Bluff or the Undercity and wait for C's payment letter, then take the payment quest at the Dead Drop."),
      finish(78307, deadDrop, "Collect the Pyrewood Signet Ring from the Dead Drop."),
    },
  })

  q(6681, "The Manor, Ravenholdt", 24, 24, nil, nil, "ROGUE")
  B.hordeSide({ id = "rogue-ravenholdt-horde", title = "Rogue: Ravenholdt Invitation", zone = alterac,
    levels = { 24, 30 }, class = "ROGUE",
    sources = { "https://senseos.gg/wiki/wow-forever/quests/6681/the-manor-ravenholdt/" },
    steps = {
      withItem(17126, accept(6681, { name = "Elegant Letter" },
        "From level 24 an Elegant Letter arrives in your mail. Open it and accept the quest; keep the Seal of Ravenholdt.")),
      objective(6681, at("Ravenholdt cave", 78.6, 17.8, hillsbrad),
        "From Tarren Mill, ride east into the hills and take the trail that climbs north of Durnholde Keep to a cave. Inside, find the trapped chest with Detect Traps or approach it in Stealth. Leave it shut and walk on until the Rite of Cunning completes.",
        "Rite of Cunning"),
      finish(6681, fahrad, "Follow the trail up to Ravenholdt Manor and hand Fahrad the seal."),
    },
  })

  q(96779, "Syndicate Sabotage", 24, 24, nil, true, "ROGUE")
  B.hordeSide({ id = "rogue-syndicate-sabotage-horde", title = "Rogue: Syndicate Sabotage", zone = alterac,
    levels = { 24, 30 }, class = "ROGUE",
    sources = { "https://azeroth.wiki/forever/quests/syndicate-sabotage" },
    steps = {
      accept(96779, myrokos, "Myrokos Silentform is inside Ravenholdt Manor. Reach it through the cave in the hills north of Durnholde Keep."),
      objective(96779, at("Lord Tomas", 79.4, 46.2, hillsbrad),
        "Go into Durnholde Keep, the Syndicate fortress south-east of Tarren Mill. Find Lord Tomas inside and kill him. Pull his guards one at a time.",
        "Lord Tomas slain"),
      finish(96779, myrokos),
    },
  })

  q(78676, "The Eye of Bhossca", 35, 30, 78307, true, "ROGUE")
  q(78699, "The Eye of Bhossca", 35, 30, 78676, true, "ROGUE")
  B.hordeSide({ id = "rogue-eye-of-bhossca-horde", title = "Rogue: The Eye of Bhossca", zone = silverpine,
    levels = { 30, 30 }, class = "ROGUE",
    sources = { "https://www.zockify.com/forever/dungeons/scarlet-monastery/",
      "https://www.wowhead.com/forever/quest=78676/the-eye-of-bhossca" },
    steps = {
      accept(78676, deadDrop, "After the Horn job is paid, C writes again at level 30. Take the new solo job at the Pyrewood Dead Drop."),
      objective(78676, at("Scarlet Monastery stables", 81.2, 32.1, tirisfal),
        "Go round behind the Scarlet Monastery in Tirisfal and take the Scarlet Initiate's Uniform from the Supply Locker in the stables. Use Next when you have it."),
      withItem(210955, objective(78676, nil,
        "Enter the Graveyard wing alone. Pick pocket a Scarlet Scryer for the Scryer's Key. Put on the uniform, walk into the Library and open the Personal Letterbox for the Confidential Message. Stealth or attacking ends the disguise. Use Next after reading it.")),
      objective(78676, nil,
        "Back in the Graveyard, /sit on both benches beside the statues until you hear clicks and grinding stone. Loot the Reliquary Key from the Stone Coffer in the north mausoleum. Use Next when you have it."),
      withItem(210955, objective(78676, nil,
        "Wear the uniform again, return to the Library and open the locked reliquary in the small room on the left with the Reliquary Key.",
        "Eye of Bhossca")),
      finish(78676, deadDrop),
      accept(78699, deadDrop, "Visit a Horde capital and wait for C's payment letter, then take the payment quest at the Dead Drop."),
      finish(78699, deadDrop, "Collect the Ruby-Adorned Blade from the Dead Drop."),
    },
  })
end
