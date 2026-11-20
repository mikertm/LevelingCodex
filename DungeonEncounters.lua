-- Fight notes shared by the Alliance and Horde routes. Encounter IDs stay in the route tables.
-- Classic notes expand the existing audited boss tips. Additional encounter sources:
-- https://www.method.gg/wow-forever/dungeons/hall-of-thanes
-- https://www.method.gg/wow-forever/dungeons/the-drowned-city
-- https://www.method.gg/wow-forever/dungeons/kroldok-stronghold
-- https://www.method.gg/wow-forever/dungeons/razorfen-downs
-- https://www.wowhead.com/forever/guide/maraudon-dungeon-overview-location-rewards
-- Keep ability names and responses short enough for the in-game step window.
local mechanics = {
  -- Ragefire Chasm
  ["Oggleflint"] = { { "Cleave", "Face him away and keep melee behind him." } },
  ["Taragaman the Hungerer"] = {
    { "Uppercut", "Fight in the middle of the platform to stay out of the lava." },
    { "Fire Nova", "Ranged stay back. Heal melee after the blast." },
  },
  ["Jergosh the Invoker"] = {
    { "Immolate", "Dispel the fire damage over time." },
    { "Curse of Weakness", "Remove it from the tank when possible." },
  },
  ["Bazzalan"] = { { "Poison", "Cleanse the tank while focusing the boss." } },

  -- Hall of Thanes
  ["Faldrim Anvilmar"] = {
    { "Anvilmar's Curse", "Decurse the tank." },
    { "Mind Blast", "Interrupt when available." },
  },
  ["Magmatus"] = {
    { "Fire Nova", "Tank away from the group so ranged stay clear." },
    { "Combust", "Watch for fire damage on a random player." },
  },
  ["Plunder"] = { { "Knock Away", "Fight with the tank's back to a wall on cleared ground." } },
  ["Durgen Dirgehammer"] = {
    { "Fear", "Clear nearby packs first. Fear Ward or Tremor Totem helps." },
    { "Rend", "Heal the tank through the bleed and golems." },
  },

  -- Ruins of Lordaeron
  ["Witherfang"] = { { "Poison", "Cleanse the tank if you can. Kill loose broodlings." } },
  ["The Baron"] = { { "Knockout", "Keep the tank topped up before the stun." } },
  ["Viktor the Vile (optional event)"] = { { "Five waves", "Start at full mana and keep waves off the healer." } },
  ["The Abandoned (optional event)"] = {
    { "Drain Life", "Interrupt or stun the channel." },
    { "Frost Nova", "Expect nearby players to be rooted." },
  },
  ["Bjork"] = { { "Green shield", "Use physical attacks while the shield blocks spells." } },
  ["Rath'mael"] = { { "Flamestrike", "Stop the cast or move the boss and melee off the fire." } },
  ["Lordaeron Captain (rare, may be absent)"] = { { "Patrols", "Pull the captain back onto cleared ground." } },

  -- Deadmines
  ["Rhahk'Zor"] = { { "Slam", "Healers keep the tank healthy through the stun." } },
  ["Miner Johnson (rare, may be absent)"] = { { "Armor reduction", "Tank damage builds as the fight goes on. Focus the rare." } },
  ["Sneed's Shredder"] = {
    { "Fear", "Clear the mill before the pull so feared players stay safe." },
    { "Disarm", "Sneed jumps out when the Shredder breaks. Let the tank regain threat." },
  },
  ["Gilnid"] = { { "Molten Metal", "The slow can be removed with Blessing of Freedom." } },
  ["Mr. Smite"] = { { "War Stomp", "Kill both Blackguards before the group stun and weapon swaps." } },
  ["Captain Greenskin"] = { { "Cleave", "Keep everyone except the tank behind him." } },
  ["Edwin VanCleef"] = { { "Blackguard reinforcements", "Clear the first pair quickly and be ready for more at lower health." } },
  ["Cookie"] = { { "Self-healing", "Focus Cookie to shorten the fight." } },

  -- Wailing Caverns
  ["Kresh"] = { { "Heavy armor", "Spell damage stays effective against this turtle." } },
  ["Lady Anacondra"] = {
    { "Sleep and Healing Touch", "Interrupt Sleep first and use the next interrupt on her heal." },
    { "Thorns", "Watch melee health if the buff stays up." },
  },
  ["Lord Cobrahn"] = {
    { "Druid's Slumber and Healing Touch", "Save interrupts for the sleep and heal." },
    { "Serpent form", "Finish him quickly after the change." },
  },
  ["Deviate Faerie Dragon (rare, may be absent)"] = { { "Druids of the Fang", "Stop their sleep casts and kill them first." } },
  ["Lord Pythas"] = {
    { "Sleep and Healing Touch", "Interrupt both when possible." },
    { "Thunderclap", "Ranged stay back from the melee slow." },
  },
  ["Skum"] = { { "Chained lightning", "Spread out to limit jumps." } },
  ["Lord Serpentis"] = { { "Sleep and Healing Touch", "Clear his guards and save interrupts for both casts." } },
  ["Verdan the Everliving"] = { { "Grasping vines", "Healers stay in range before the group root. Keep the tank high." } },
  ["Mutanus the Devourer"] = {
    { "Escort waves", "Protect the Disciple until the boss arrives." },
    { "Stun, fear and sleep", "Ranged stay clear of melee. Ready fear breaks and dispels." },
  },

  -- Shadowfang Keep
  ["Rethilgore"] = { { "Soul Drain", "Heal the stunned target through the drain." } },
  ["Razorclaw the Butcher"] = { { "Butcher Drain", "Heal the affected player until the drain ends." } },
  ["Baron Silverlaine"] = { { "Veil of Shadow", "Use a defensive while healing on the tank is reduced." } },
  ["Commander Springvale"] = {
    { "Holy Light", "Interrupt the heal." },
    { "Divine Shield", "Wait out the immunity." },
  },
  ["Odo the Blindwatcher"] = { { "Rising damage", "Clear the bats first, then burn Odo before his damage ramps up." } },
  ["Deathsworn Captain (rare, may be absent)"] = { { "Cleave", "Keep the group behind the captain." } },
  ["Fenrus the Devourer"] = { { "Toxic Saliva", "Cleanse the poison from the tank." } },
  ["Wolf Master Nandos"] = { { "Summoned worgs", "Pick them up and kill them as they appear." } },
  ["Archmage Arugal"] = {
    { "Void Bolt", "Use the pillars to break line of sight when needed." },
    { "Teleport", "Reposition when he moves." },
    { "Mind control", "Crowd control the player until the curse wears off." },
  },

  -- Blackfathom Deeps
  ["Ghamoo-ra"] = { { "Trample", "Ranged stay clear. Use spells and armor debuffs against his heavy armor." } },
  ["Lady Sarevess"] = {
    { "Forked Lightning", "Keep her facing away from the party." },
    { "Frost Nova", "Be ready to heal players rooted within shooting range." },
  },
  ["Gelihast"] = { { "Net", "Fight on cleared ground so rooted players can stay put safely." } },
  ["Lorgus Jett"] = { { "Shaman casts", "Clear the cultists and save an interrupt for Jett." } },
  ["Baron Aquanis (Horde quest)"] = { { "Fathom Stone", "Clear around the stone before summoning and let the tank establish threat." } },
  ["Twilight Lord Kelris"] = {
    { "Sleep", "Dispel the healer quickly if they are put to sleep." },
    { "Mind Blast", "Keep the tank ready for spell damage." },
  },
  ["Old Serra'kis"] = { { "Underwater pull", "Start with a full breath bar or use water breathing." } },
  ["Aku'mai"] = {
    { "Poison clouds", "Move the boss and party out of the poison." },
    { "Frenzy", "Save tank cooldowns and extra healing for the burst." },
  },

  -- Excavation Site: Wetlands
  ["Saltspine"] = { { "Dust Storm", "Keep ranged back and give the tank time to build threat through the misses." } },
  ["Shadetooth"] = {
    { "Fear roar", "Clear the hidden raptors in the grass before pulling." },
    { "Enrage", "Save defensive cooldowns for low health." },
  },
  ["Highland Horror (optional)"] = {
    { "Wild Regeneration", "Interrupt the heal." },
    { "Roots", "Fight away from the Oil Slimes so rooted players stay safe." },
  },
  ["Relic Guardian"] = { { "Stomp", "Ranged stay back. Keep the guardian facing away on clear ground." } },

  -- City of Dalaran
  ["Atrexis the Grave Knight"] = {
    { "Unholy Frenzy", "Purge if available and watch tank health." },
    { "Skeletons and disarm", "Kill the necromancers first. Give a disarmed tank time to recover threat." },
  },
  ["Lyn the Ignored (optional, needs the Tome of Dalaran)"] = { { "Curse of Thorns", "Decurse the tank and pick up the skeletons." } },
  ["Arcane Anomaly"] = {
    { "Focal Blast", "Follow the rotation from close behind the boss." },
    { "Arcane Bolt", "Plan for heavy spell damage on the tank." },
  },
  ["Arcanic Enigma"] = {
    { "Mana Burn", "Interrupt the Mana Phantoms and kill them first." },
    { "Manamorph", "Dispel promptly. Ranged stand outside the silence." },
  },
  ["Unstable Sentinel"] = {
    { "Arcing Smash", "Face the boss away from the party." },
    { "Malfunction", "Keep ranged outside its reach or stun before the cast." },
  },
  ["Fel Ancient"] = {
    { "Fel Timbers", "Move out of the green pools." },
    { "Entangle", "Break roots so players can leave the pools." },
  },
  ["Mana Devourer"] = { { "Debilitate", "Use damage cooldowns before the party runs low on mana." } },
  ["Shade of the Archmage"] = {
    { "Bounding Mana", "Dodge each projectile on the way out and back." },
    { "Polymorph and Evocation", "Expect a group polymorph when the Shade runs out of mana." },
  },

  -- Gnomeregan
  ["Grubbis"] = { { "Chomper", "Pick up Grubbis and his pet together, then stun and focus one at a time." } },
  ["Viscous Fallout"] = { { "Nature damage", "Armor will not absorb it. Give the tank steady healing." } },
  ["Electrocutioner 6000"] = {
    { "Chain Bolt", "Spread out so fewer players are hit." },
    { "Megavolt", "Keep the boss facing away from the party." },
  },
  ["Crowd Pummeler 9-60"] = { { "Crowd Pummel", "Tank against a wall and keep the party away from ledges." } },
  ["Dark Iron Ambassador (rare, may be absent)"] = { { "Fire shield", "Let ranged handle the damage while the shield burns nearby players." } },
  ["Mekgineer Thermaplugg"] = {
    { "Walking bombs", "Assign a ranged player to the pillar buttons and handle the bombs early." },
    { "Knock Away", "Taunt back after the tank loses threat." },
  },

  -- Razorfen Kraul
  ["Roogug"] = { { "Earth Rumbler", "Control nearby quilboar and kill the elemental first." } },
  ["Aggem Thorncurse"] = {
    { "Boar Spirit", "Tank picks up the spirit as soon as it appears." },
    { "Chain Heal", "Interrupt the heal to stop it bouncing." },
  },
  ["Death Speaker Jargba"] = { { "Mind control", "Stun or sheep the player and hold area damage briefly." } },
  ["Overlord Ramtusk"] = { { "Thunderclap", "Ranged stay back and heal melee after the hit." } },
  ["Agathelos the Raging"] = {
    { "Charge", "Let the tank be first in." },
    { "Enrage", "Save a defensive for the end." },
  },
  ["Blind Hunter (rare, may be absent)"] = { { "Sonic Burst", "Healers and casters stay out of the nearby silence." } },
  ["Earthcaller Halmgar (rare, may be absent)"] = {
    { "Earth Rumbler", "Let the tank pick it up." },
    { "Earthbind Totem", "Kill the totem or move out of its slow." },
  },
  ["Charlga Razorflank"] = {
    { "Renew", "Interrupt healing casts when possible." },
    { "Chain Bolt", "Spread to limit jumps between players." },
  },

  -- Scarlet Monastery
  ["Interrogator Vishas"] = { { "Immolate", "Dispel the fire damage over time after handling his guards." } },
  ["Ironspine (rare, may be absent)"] = {
    { "Poison cloud", "Move the fight out of the cloud." },
    { "Curse of Weakness", "Decurse the tank." },
  },
  ["Fallen Champion (rare, may be absent)"] = { { "Cleave", "Face the Champion away from the group." } },
  ["Azshir the Sleepless (rare, may be absent)"] = {
    { "Soul Siphon", "Interrupt the channel." },
    { "Call of the Grave", "Bring marked players up before the debuff expires." },
    { "Fear", "Clear nearby packs before the pull." },
  },
  ["Bloodmage Thalnos"] = { { "Flame Spike", "Melee step back during the cast. Healers stay at range." } },
  ["Houndmaster Loksey"] = { { "Bloodlust", "Kill or control the hounds first and stun Loksey during his burst." } },
  ["Arcanist Doan"] = {
    { "Detonation", "Run out when he shields himself and starts casting." },
    { "Polymorph and Silence", "Spread out and keep the healer away from Doan." },
  },
  ["Herod"] = {
    { "Whirlwind", "Melee back out and the tank kites if needed." },
    { "Enrage and trainees", "Save a defensive for low health. Be ready for trainees after the kill." },
  },
  ["High Inquisitor Fairbanks"] = {
    { "Heal", "Interrupt the heal and decurse Curse of Blood." },
    { "Fear and Sleep", "Clear the hidden room approach so crowd control cannot pull more enemies." },
  },
  ["Mograine and Whitemane"] = {
    { "Hammer of Justice and Divine Shield", "Heal through Mograine's stun and wait out his immunity." },
    { "Deep Sleep and Scarlet Resurrection", "Whitemane sleeps the party and raises Mograine. Pick him up again and finish Whitemane first." },
  },

  -- Razorfen Downs
  ["Tuten'kash"] = { { "Poison and webs", "Cleanse the poison and keep the tank up through the webs." } },
  ["Plaguemaw the Rotting"] = { { "Disease", "Cleanse it from the tank and keep the boss away from other packs." } },
  ["Mordresh Fire Eye"] = {
    { "Fireball", "Interrupt its cast." },
    { "Fire Nova", "Keep ranged clear and heal melee through the blast." },
  },
  ["Glutton"] = {
    { "Disease Cloud", "Stay out of melee range unless needed." },
    { "Enrage", "Use damage cooldowns early to limit how long his damage can ramp." },
  },
  ["Ragglesnout (rare, may be absent)"] = {
    { "Heal and Shadow Word: Pain", "Interrupt the heal and dispel the damage over time." },
    { "Dominate Mind", "Control the charmed player until it wears off." },
  },
  ["Amnennar the Coldbringer"] = {
    { "Frost Nova", "Keep the healer away from melee before the root." },
    { "Frost adds", "Pick them up and kill them before resuming the boss." },
  },

  -- Uldaman
  ["Revelosh"] = { { "Chain Lightning", "Interrupt and spread out to limit the jumps." } },
  ["The Lost Dwarves (Baelog, Eric and Olaf)"] = { { "Three dwarves", "Control Eric, face Olaf away and use cover against Baelog's arrows." } },
  ["Ironaya"] = {
    { "Arcing Smash", "Keep her front clear except for the tank." },
    { "Stomp and knock-up", "Spread out and watch tank health when Ironaya knocks them around." },
  },
  ["Obsidian Sentinel"] = { { "Obsidian shards", "Kill summoned shards quickly before they can heal the Sentinel." } },
  ["Ancient Stone Keeper"] = { { "Sand and pulsing damage", "Keep ranged back and move away from sand pools." } },
  ["Galgann Firehammer"] = { { "Fire Nova and Flame Lash", "Interrupt when available and keep ranged clear of the nova." } },
  ["Grimlok"] = { { "Lightning Bolt", "Kill the basilisks first and interrupt the cast." } },
  ["Archaedas"] = { { "Animated guardians", "Tank holds Archaedas while the party deals with the awakened dwarves and watchers." } },

  -- The Stockade has its own named boss abilities in the route.
  ["Bruegal Ironknuckle"] = { { "Nearby prisoners", "Clear them before pulling the rare." } },

  -- The Drowned City
  ["Zul'Alai"] = { { "Monstrous Slam", "Step out of melee before the cast finishes to avoid the stun." } },
  ["Var'Taka"] = {
    { "Harpoon", "If pulled into melee, move out of the tank's side quickly." },
    { "Cleave", "Face the boss away. Control the Brinescale Priestesses." },
  },
  ["Captain Dreadrise"] = {
    { "Waterbolt Volley", "Save an interrupt for the party-wide cast." },
    { "Embrine", "Destroy the Abyssal Bubble to free the trapped player." },
  },
  ["Deathless Marrow"] = {
    { "Bloodbolt", "Keep the tank healthy while dealing with the add waves." },
    { "Reinforcements", "Control sorcerers and focus the Guardians before they can stun players with Shield Slam." },
  },
  ["Gill"] = { { "Throw Dynamite", "Move out of the bomb landing area." } },
  ["Umbra"] = { { "Rend", "Several bleeds can stack up. Kill the Muckdwellers first." } },
  ["Primeval Elemental (optional)"] = {
    { "Freeze Water", "Heal through the group hit and keep an eye on breath while slowed." },
    { "Waterbolt", "Watch the tank's health. Surface through the opening above if needed." },
  },
  ["Min'loth the Serpent"] = {
    { "Drench and Deluge", "Heal heavy tank damage, then cover the group-wide channel." },
    { "Fear and Poison Bolt Volley", "In serpent form, use fear breaks and cleanse the poison quickly." },
  },

  -- Krol'dok Stronghold
  ["Slavecrusher Grox"] = { { "Force Compliance", "Pick up the prisoners he pulls into the fight and keep them off the healer." } },
  ["Twilight Commander Zarmok"] = { { "Stacking bleed", "Keep the tank high and use a defensive as the bleed builds." } },
  ["Handler Ashka"] = { { "Command: Kill!", "Control and kill the wolves first. Help the player they fixate on." } },
  ["Nar'gurk"] = {
    { "Convert", "Use controlled damage to bring the charmed player to half health and free them." },
    { "Shadow Bolt Volley", "Be ready to heal the whole group." },
  },
  ["Bossman Toof"] = {
    { "Mortal Strike", "Watch the tank while healing on them is reduced." },
    { "Bloodlust and bridge adds", "Focus the shamans and control the Brutes coming from the bridge." },
  },
  ["Overseer Mugg"] = {
    { "Mugg's Fury", "Expect harder tank damage after his weapon swaps." },
    { "Crushing Slam", "Spread so the leap and knockback catch fewer players." },
  },

  -- Zul'Farrak
  ["Antu'sul"] = {
    { "Called basilisks", "Pick up the adds quickly and keep them off the healer." },
    { "Healing", "Save an interrupt for his low-health heal." },
  },
  ["Theka the Martyr"] = { { "Scarab form", "Physical attacks stop working during the transformation. Use spells." } },
  ["Witch Doctor Zum'rah"] = {
    { "Ward totem", "Destroy it and pick up the zombies." },
    { "Shadow Bolt Volley", "Interrupt the party-wide cast." },
  },
  ["Shadowpriest Sezz'ziz"] = { { "Healing", "Interrupt and focus Sezz'ziz before Nekrum." } },
  ["Nekrum Gutchewer"] = { { "Pyramid waves", "Keep Nekrum and the last wave off the healer while the group finishes Sezz'ziz." } },
  ["Hydromancer Velratha"] = { { "Heals and frost bolts", "Interrupt the heal first. Keep ranged at a safe distance." } },
  ["Gahz'rilla (summoned)"] = {
    { "Gahz'rilla Slam", "Tank under the entrance arch to limit the launch and fall. Ranged stay back." },
    { "Freeze Solid and Icicle", "Dispel the stun and interrupt the slowing ice cast." },
  },
  ["Chief Ukorz Sandscalp and Ruuzlu"] = { { "Enrage and cleave", "Control Ruuzlu and keep the group behind Ukorz." } },

  -- Maraudon
  ["Noxxion"] = { { "Noxxion's Spawn", "Kill the small elementals while Noxxion is immune." } },
  ["Razorlash"] = { { "Cleave", "Fight behind the boss once the tank pulls it off its patrol." } },
  ["Lord Vyletongue"] = { { "Blink", "Move with him after clearing the satyr guards." } },
  ["Celebras the Cursed"] = { { "Roots and corrupted spirits", "Break roots where possible and kill the summoned spirits." } },
  ["Landslide"] = { { "Knockback and rock adds", "Keep the tank clear of drops. Deal with the adds at low health." } },
  ["Tinkerer Gizlock"] = { { "Goblin Dragon Gun and bombs", "Fight at his side and stay clear of the fire." } },
  ["Rotgrip"] = {
    { "Puncture", "Keep the tank healthy as the bleed stacks." },
    { "Fatal Bite", "Plan for a heavy bite and recovery on Rotgrip." },
  },
  ["Princess Theradras"] = { { "Dust field and knockback", "Tank against a wall and keep ranged spread." } },

  -- Sunken Temple
  ["Atal'alarion (statue event)"] = { { "Knockback", "Fight with room behind the group so the knockback stays safe." } },
  ["Troll minibosses (six balconies)"] = { { "Six balconies", "Work around the ring until all six guardians are down and the barrier drops." } },
  ["Jammal'an the Prophet and Ogom the Wretched"] = {
    { "Healing", "Focus Jammal'an and interrupt his heals." },
    { "Hex of Jammal'an", "Crowd control the transformed player." },
  },
  ["Dreamscythe"] = { { "Dragon breath", "Face the dragon away from the party." } },
  ["Weaver"] = { { "Dragon breath", "Keep the party behind the dragon." } },
  ["Morphaz"] = { { "Dragon breath", "Face the dragon away and spread ranged players." } },
  ["Hazzas"] = { { "Dragon breath", "Keep the dragon facing away while the group finishes the pair." } },
  ["Avatar of Hakkar (optional, needs Hakkari Blood)"] = { { "Flames of Hakkar", "Use the blood from the summoned servants to put out all four flames." } },
  ["Shade of Eranikus"] = {
    { "War Stomp", "Keep ranged and the healer clear of the nearby stun." },
    { "Deep Slumber", "Be ready to help if the healer is put to sleep." },
  },

  -- Blackrock Depths
  ["Lord Roccor"] = {
    { "Ground Tremor", "Keep ranged clear." },
    { "Poison", "Cleanse the tank." },
  },
  ["High Interrogator Gerstahn"] = { { "Mind Blast and Shadow Word: Pain", "Interrupt Mind Blast and dispel the damage over time." } },
  ["Ring of Law"] = { { "Arena waves", "Fight in the middle and save damage cooldowns for the random final opponent." } },
  ["Pyromancer Loregrain"] = { { "Searing Totem and Flame Shock", "Kill the totems and remove the fire damage over time if available." } },
  ["Lord Incendius"] = { { "Fire Storm and knockback", "Tank with your back to a wall and keep clear of the fire." } },
  ["Fineous Darkvire"] = { { "Healing", "Save a stun or interrupt for his heal." } },
  ["Bael'Gar"] = { { "Fire elementals", "Pick up the elementals and kill them quickly." } },
  ["General Angerforge"] = { { "Reinforcements", "Use damage cooldowns at low health and keep adds off the healer." } },
  ["Golem Lord Argelmach"] = { { "Chain Lightning", "Interrupt after clearing the nearby golems." } },
  ["Hurley Blackbreath"] = { { "Keg event", "Clear a safe spot before breaking the kegs. Keep the fight away from the bar crowd." } },
  ["Ribbly Screwspigot"] = { { "Bodyguards", "Control or kill the bodyguards one at a time." } },
  ["Ambassador Flamelash"] = { { "Fire spirits", "Intercept the elementals before they reach and strengthen the boss." } },
  ["The Seven"] = { { "Successive dwarves", "Focus one dwarf at a time before the next joins." } },
  ["Magmus"] = { { "Fire jets", "Fight in clear gaps away from the jets." } },
  ["Emperor Dagran Thaurissan"] = { { "Moira's heals", "Keep pressure on the Emperor. Leave Moira alive for her quest." } },

  -- Lower Blackrock Spire
  ["Highlord Omokk"] = { { "Knockback", "Fight with the tank's back to a wall and clear of the platform edge." } },
  ["Shadow Hunter Vosh'gajin"] = { { "Hex, curse and totems", "Dispel afflicted players and destroy the totems." } },
  ["War Master Voone"] = { { "Thrown axes and cleave", "Ranged spread out. Melee fight behind the boss." } },
  ["Mother Smolderweb"] = { { "Stacking poison", "Cleanse the tank except when the Mother's Milk quest needs the poison." } },
  ["Urok Doomhowl (event)"] = { { "Ogre waves", "Pick up each wave before the next one reaches the healer." } },
  ["Quartermaster Zigris"] = { { "Healing potion", "Save a stun or interrupt for his heal." } },
  ["Halycon and Gizrul the Slavener"] = { { "Gizrul's frenzy", "Gizrul arrives after Halycon. Save a defensive or enrage removal for him." } },
  ["Overlord Wyrmthalak"] = { { "Dragonkin adds", "Save cooldowns and pick up both adds near the end." } },

  -- Upper Blackrock Spire
  ["Pyroguard Emberseer"] = { { "Rising fire damage", "Clear the room before release and burn him before the damage builds." } },
  ["Solakar Flamewreath"] = { { "Whelp and handler waves", "Tank picks up the waves. Use area damage on the whelps." } },
  ["Goraluk Anvilcrack"] = { { "Heavy melee", "Keep the tank healthy and pull away from other enemies." } },
  ["Warchief Rend Blackhand and Gyth"] = { { "Arena waves", "Hold the waves near the gate. Focus Gyth when he lands, then Rend." } },
  ["The Beast"] = {
    { "Fear and knockback", "Fight in the cleared corridor to keep players out of neighboring packs." },
    { "Fireball", "Healers keep the target up through the fire damage." },
  },
  ["General Drakkisath"] = { { "Conflagration and Flamestrike", "Spread and move out of fire. Control his guards before focusing the boss." } },

  -- Dire Maul: East
  ["Pusillin"] = { { "Imp reinforcements", "Clear the chase route and pick up the imps when he finally fights." } },
  ["Zevrim Thornhoof"] = { { "Sacrifice", "Heal the player stunned on the altar through the drain." } },
  ["Hydrospawn"] = { { "Riptide and knockback", "Tank against a wall so the knockback stays controlled." } },
  ["Lethtendris"] = { { "Shadow Bolt Volley", "Kill Pimgib first, then interrupt the volley." } },
  ["Alzzin the Wildshaper"] = { { "Form changes and adds", "Stay with Alzzin when he changes form and pick up the summoned adds." } },

  -- Dire Maul: West
  ["Tendris Warpwood"] = { { "Roots and stuns", "Keep the healer in range and clear trees before pulling." } },
  ["Illyanna Ravenoak"] = { { "Volley and pet", "Spread and kill or control the bear first." } },
  ["Magister Kalendris"] = { { "Mind Blast and Shadow Word: Pain", "Interrupt Mind Blast and dispel the damage over time." } },
  ["Immol'thar"] = { { "Eyes and Trample", "Kill incoming eyes and keep ranged out of melee." } },
  ["Prince Tortheldrin"] = { { "Whirlwind and teleport", "Melee move away from the spin and healers watch teleport targets." } },

  -- Dire Maul: North
  ["Guard Mol'dar"] = { { "Cleave", "On a normal kill, face him away from the group." } },
  ["Stomper Kreeg"] = { { "Whirlwind", "Melee step back during the spin if your group fights him." } },
  ["Guard Fengus"] = { { "Patrol", "On a normal kill, pull him into a cleared area." } },
  ["Guard Slip'kik"] = { { "Broken trap", "Use the repaired trap to get past him on a Tribute run." } },
  ["Captain Kromcrush"] = { { "Ogre guard reinforcements", "Save control or cooldowns for the two guards he calls." } },
  ["Cho'Rush the Observer"] = { { "Spellcasting", "Interrupt him while focusing King Gordok if your group wants Tribute." } },
  ["King Gordok"] = { { "Mortal Strike and knockback", "Tank in a steady position and use a defensive through reduced healing." } },

  -- Scholomance
  ["Kirtonos the Herald (summoned)"] = { { "Add pressure", "Drop the gates using the wall lever to keep the adds out." } },
  ["Jandice Barov"] = { { "Illusions", "Clear the images with area damage and find the real Jandice." } },
  ["Rattlegore"] = { { "Heavy melee", "Hold him in a corner and save heals for the tank." } },
  ["Marduk Blackpool"] = { { "Shared pull", "Control or separate Vectus if possible before focusing Marduk." } },
  ["Vectus"] = { { "Viewing Room students", "Use Dawn's Gambit if available and clear the converted skeletons first." } },
  ["Ras Frostwhisper"] = {
    { "Frost Nova", "Ranged keep clear of the root." },
    { "Frostbolt Volley", "Spread and be ready for party-wide frost damage." },
  },
  ["Doctor Theolen Krastinov"] = { { "Frenzy", "Save damage and a tank defensive for the end." } },
  ["Lorekeeper Polkelt"] = { { "Stacking disease", "Cleanse the tank before the stacks build." } },
  ["Lady Illucia Barov"] = { { "Fear and mind control", "Clear the room first and control anyone she takes over." } },
  ["Lord Alexei Barov"] = { { "Unholy Aura", "Keep the healer ready for damage across the party." } },
  ["The Ravenian"] = { { "Wide cleave", "Tank faces the Ravenian away. Melee stay behind it." } },
  ["Instructor Malicia"] = { { "Healing and poison", "Interrupt her heals and cleanse the poisoned player." } },
  ["Darkmaster Gandling"] = { { "Teleport", "Kill the adds in the room you are sent to, then return to the main fight." } },

  -- Stratholme
  ["The Unforgiven"] = { { "Ghosts and frost spells", "Kill the ghosts first. Dispel or heal affected players." } },
  ["Ezra Grimm"] = { { "Tobacco box", "Clear the shop entrance before opening the box to call him." } },
  ["Timmy the Cruel"] = { { "Heavy melee", "Let the tank pick him up when he appears after the market clears." } },
  ["Cannon Master Willey"] = { { "Riflemen and cannon", "Deal with the riflemen and stay clear of where the cannon is aimed." } },
  ["Archivist Galford"] = { { "Fire damage", "Keep the chosen target healed. Burn the archive afterward if your quest calls for it." } },
  ["Balnazzar"] = { { "Psychic Scream and mind control", "Clear the surrounding rooms and control any charmed player after the transformation." } },
  ["Magistrate Barthilas"] = { { "Gate area", "Clear around the route into the undead side before pulling." } },
  ["Baroness Anastari"] = { { "Possession and silence", "Focus the possession and be ready to dispel the silence." } },
  ["Nerub'enkan"] = { { "Scarabs and poison", "Kill the summoned scarabs and cleanse poison." } },
  ["Maleki the Pallid"] = { { "Frostbolt and Drain Life", "Interrupt the damage cast or the healing channel." } },
  ["Ramstein the Gorger"] = { { "Knockback", "Tank Ramstein against a wall and heal through his melee hits." } },
  ["Baron Rivendare"] = { { "Skeletons and Death Pact", "Kill summoned skeletons before the Baron can consume them to heal." } },
}

local skip = {
  ["Viktor the Vile (optional event)"] = "Optional event. Skip boss if your group is passing the fireplace waves.",
  ["The Abandoned (optional event)"] = "Optional event. Skip boss if your group is passing the courtyard statue.",
  ["Baron Aquanis (Horde quest)"] = "Skip boss if nobody needs the quest or can summon him at the Fathom Stone.",
  ["Highland Horror (optional)"] = "Horde has no quest for this detour. Skip boss unless the group wants the fight.",
  ["Highland Horror (optional, Alliance quest)"] = "Skip boss if your group does not need Horrors in the Highland.",
  ["Lyn the Ignored (optional, needs the Tome of Dalaran)"] = "Skip boss if nobody has the Tome of Dalaran to summon her.",
  ["High Inquisitor Fairbanks"] = "Optional hidden-room fight. Skip boss if the group is going straight to the altar.",
  ["Primeval Elemental (optional)"] = "Optional underwater detour. Skip boss if your group is staying on the main route.",
  ["Bossman Toof"] = "Skip boss if your group passes the bridge encounter. Mark defeated after the fight.",
  ["Gahz'rilla (summoned)"] = "Skip boss if nobody is ringing the gong with the Mallet of Zul'Farrak.",
  ["Atal'alarion (statue event)"] = "Skip boss if your group is passing the statue event.",
  ["Avatar of Hakkar (optional, needs Hakkari Blood)"] = "Skip boss if nobody is starting the Hakkar event.",
  ["Urok Doomhowl (event)"] = "Skip boss if your group is passing Warosh's challenge or lacks the items to start it.",
  ["Solakar Flamewreath"] = "Skip boss if the group is passing the egg event.",
  ["Goraluk Anvilcrack"] = "Skip boss if the group is passing this side pull.",
  ["Guard Mol'dar"] = "Tribute run: leave Mol'dar alive and choose Skip boss.",
  ["Stomper Kreeg"] = "Tribute run: pass Kreeg and choose Skip boss.",
  ["Guard Fengus"] = "Tribute run: move past Fengus without fighting and choose Skip boss.",
  ["Guard Slip'kik"] = "Tribute run: trap or bypass Slip'kik and choose Skip boss.",
  ["Captain Kromcrush"] = "Tribute run: use the Gordok Ogre Suit to send him away and choose Skip boss.",
  ["Cho'Rush the Observer"] = "Tribute run: leave Cho'Rush alive, choose Skip boss, then focus King Gordok.",
  ["Kirtonos the Herald (summoned)"] = "Skip boss if nobody is using Blood of Innocents to summon him.",
  ["Ezra Grimm"] = "Skip boss if your group is passing the tobacco shop.",
  ["Hurley Blackbreath"] = "Skip boss if your group is passing the keg event.",
  ["Ribbly Screwspigot"] = "Skip boss if your group is leaving Ribbly and his bodyguards alone.",
}

for _, faction in ipairs({ "ALLIANCE", "HORDE" }) do
  for _, section in ipairs(LevelingCodexQuests[faction].sections) do
    for _, boss in ipairs(section.bosses or {}) do
      local name = boss.name
      if name == "Highland Horror (optional, Alliance quest)" then
        boss.abilities = mechanics["Highland Horror (optional)"]
      else
        boss.abilities = boss.abilities or mechanics[name]
      end
      if skip[name] then
        boss.optional, boss.skip = "optional", skip[name]
      elseif name:match(" %(rare[,)]") then
        boss.optional = "rare"
      end
    end
  end
end
