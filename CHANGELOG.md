# Leveling Codex

## v0.20.0

### Quest guide: flights and dungeons

- **Trips through flight masters.** For a long trip the arrow now leads to a flight master when flying is quicker, for example "Fly to Lakeshire from Sentinel Hill" with the distance to the flight master, and "talk to the flight master" once you're there. It only uses flight paths you have, and it works inside one zone too, such as Crossroads to Ratchet.
- **The flight map marks the guide's flight.** When you open a flight map, the Codex badge sits on the flight to take and a line names it. With Settings > Take the guide's flights and binds on, the Codex takes that flight for you (Alt holds it back), not only on Fly steps.
- **Flight paths you don't have.** If the flight master closest to you is one you haven't talked to, the arrow says to learn that flight path and fly on. A flight master you don't have close to the way is visited first so you pick up the flight path (Settings > Lead me to flight paths I don't have). This starts once the game has listed your flight paths, or after you open a flight map.
- **Nearest flight master.** Quests > **Nearest flight master** points the arrow at the closest one, until you open a flight map or press **Back to the step**.
- **Dungeon ahead.** Dungeon quests no longer hide behind a setting. Before the first quest of a dungeon run, the route stops at a Dungeon ahead step: the run's levels, how many quests on your route need it, and whether it's recommended for you. **Plan <dungeon>** adds the run and its quests to your route; **Skip** leaves the run out. Back returns to the choice, and Quests > Guide library > Dungeons can still change it. The Quests tab has both buttons for controllers.
- **Find a group.** When a planned run is ready, the step text starts with "Find a group for <dungeon>" until you go.
- **Boss by boss inside a dungeon.** Inside a dungeon the step window now walks its bosses in order, one step each with the tip for the fight, and the target button targets the boss. A boss ticks off when it dies (the game's encounter events, or the combat log for rares), and Next passes a rare that isn't there. Your quests for the run show under the boss as "On the way", and the item button still offers their quest items.
- **The guide opens when you zone in.** Entering a dungeon the Codex has a guide for switches the step window to it, even if you didn't press Run. Dying and running back in keeps the bosses already down (Settings > Open a dungeon's guide when you enter it).
- **The way in.** The arrow now leads through the Deadmines tunnels, the Wailing Caverns cave and the passage down to the Hall of Thanes, point by point, to the portal. The Deadmines tunnel quests point to their undead and to Foreman Thistlenettle.
- Boss lists now match the game's encounters: Lorgus Jett joins Blackfathom Deeps, the Horde's Ruins of Lordaeron adds the rare Lordaeron Captain, and City of Dalaran and Scarlet Monastery are now recognised when you enter them.
- New settings: Plan trips through flight masters, Lead me to flight paths I don't have, and Open a dungeon's guide when you enter it (all on).

### Quest guide, tier 2

- **Guide setup.** A new character gets a quick setup in the Quests tab: Fastest or Every quest, recommended dungeons or none, and the auto-accept, auto turn-in and flight helpers. The step window offers "Set up the guide" until you press Done, and Quests > **Guide setup** opens it any time.
- **Watch out here.** The step window names hostile elites and rares close to the current step, such as the Defias elites around the Moonbrook mine, until you outlevel them (Settings > Warn about elites and rares near the step).
- **Party play.** Party members who use the Codex see each other's current step in the step window, with how far ahead or behind they are. Two options, off by default: share guide quests with your party when you accept them, and say your flights in party chat.
- **Your pace.** The This Level tab shows your XP per hour this session, about how long the next level takes at that pace, and this level's XP from quests and kills, with quests, kills and deaths. Finished levels are listed with their times.
- **Arrival time and flight timer.** The arrow shows about how long until you reach the step while you're moving. In flight it shows where you're going and how long you've flown, and once a flight has been timed, about how long is left.
- **Show on map, report a step.** Quests > **Show on map** opens the world map where the step is. **Report this step** copies what the guide sees (your position, the step and your quest log) for a bug report.
- **Steps shown ahead.** Settings > Steps shown ahead lists 0 to 5 of the next steps in the step window (2 by default).
- **Quest tracker.** The current step's quest goes on the game's objective tracker. Quests you track yourself are left alone (Settings > Track the step's quest in the quest tracker).
- **Why a step was skipped.** Hovering a step in the route list says why it isn't the current one: turned in, passed with Next, grey for your level, the follow-up already started, or needed for a later quest.
- **Hearthstone cooldown.** A hearth step says when your hearthstone will be ready, and the arrow leads you by road or flight while it's on cooldown.
- **More kinds of steps** for the guides: collecting or buying items (done when your bags hold them), abandoning a quest, goals to pick up on the way, waypoints that loop through a spread-out area or lead to the nearest of several spots, and steps that only apply below a level, with a profession, or depending on another quest.

### Alliance quest guide

- **Warriors: Fire Hardened Mail's fangs at Thelgen Rock.** The Leech and Cave Stalkers you kill for Alchemical Hazards' gland also drop the 50 Scorched Spider Fangs, so with Fire Hardened Mail in your log the Wetlands guides add a step to collect them there. Other classes, and Warriors without the quest, don't see it.
- **Class quests on the way.** Where the route already passes a class objective, your class now gets a step for it while the quest is in your log: Shaman reagents and waterskins (Dwarf and Horde), Druid pendant halves, Cliffspring sample, Lunar Fungus and Lunaclaw, Rogue lockboxes, Klaven's Tower, Sethir and the Southsea treasure, Warlock Surena and the Heartswood, and Horde Warrior scales and antennae. Other classes, and players without the quest, don't see them.
- Fixed: with Settings > Show optional quests on, the step window could ask you to turn in a quest you never took, such as Unrequited Love (Hollee's note from Darkshore) in Menethil. Optional turn-ins and objectives now show only while the quest is in your log.

## v0.19.0

### Questie compatibility

- **Works side by side with Questie.** While Questie's own auto-accept or auto-complete is on, the Codex leaves those quests to Questie, so the two never pick different quests from one NPC. Settings says so under each tickbox.
- **One key holds both back.** Questie's key (Shift by default) now stops the Codex's auto-accept and auto-turn-in too. Alt now also stops the quest window, not just the NPC's list.
- **The step window sits beside Questie's tracker** until you drag it somewhere, on the side facing the middle of the screen, and follows the tracker when you move it.
- **Last-mile arrow with QuestieDB.** With QuestieDB installed (Questie needs it), the arrow leads to the nearest mob or object you still need once you reach a kill or collect step's camp, for example "Kobold Vermin - 42 yd". Items lead to whatever drops them. Turn it off in Settings > Point the arrow at the nearest objective (QuestieDB).
- **The last-mile arrow skips a spawn you just cleared** for 90 seconds, so it leads on to the next mob instead of back to an empty spot. It also works on clients in other languages, keeps the arrow on screen when the step window sits high, and checks QuestieDB once more if it wasn't ready at login.

### Alliance quest guide

- **Early Wetlands (20-25) rebuilt around Menethil Harbor.** The chapter now starts where the Auberdine ship lands: two short coast loops, then one trip east and back along the road. That trip covers the Green Belt, Thelgen Rock, the Mosshide camps, Ironbeard's Tomb and then the Whelgar dig. It adds quests already on the way: Alchemical Hazards, Digging Through the Ooze, the Excavation Team delivery, The Third Fleet, the statuette's Forever follow-up for Captain Stoutfist, The Greenwarden, and Hollee's note when you carry it. That's 19 quests instead of 12, with less walking.

### Quest guide helpers

- **Map pin.** The current step gets the game's own map waypoint, so it shows on your world map and minimap. A waypoint you place yourself is never replaced (Settings > Pin the current step on the map).
- **Corpse arrow.** As a ghost, the quest arrow leads back to your corpse ("Your corpse - 120 yd"), then returns to your step once you're alive.
- **Target quest mobs.** On objective steps the target button now targets the creatures the quest needs, for kills and for drops near the step, so you can bind it to a key and pull the next one. It still targets the quest giver on pickup and turn-in steps.
- **Hearthstone on the item button.** Hearth steps put your Hearthstone on the item button when it's set to the step's town.
- **XP to go.** "Level up" steps show your XP, how much is left, about how many kills that is (from your last kills), your rested XP, and the XP waiting in finished quests in your log. A grind step can now stop partway through a level.
- **Flights and binds for you (optional).** Settings > **Take the guide's flights and binds**: at a flight master on a Fly step the Codex takes the step's flight, and at the step's inn it sets your hearthstone. Off by default, and Alt holds it back.
- **Quest log cleanup.** Quests > Guide library lists quests no guide of yours uses and grey quests worth little XP, each with an Abandon button that asks twice. The full-log warning points there.
- **Best-selling reward.** When a quest offers a choice, a coin marks the reward that sells for the most and chat names its price. The Codex never picks for you (Settings > Mark the best-selling quest reward).

### Class trainer

- **What to train.** At your class trainer a card above the window lists the guide's spells you can learn now, their total cost and anything else on offer, or your next visit when there's nothing to train. It never buys anything (Settings > Class trainer).

### Forever hotfixes (November 5-10)

- **Blacksmithing:** Coarse Grinding Stone now gives points up to 90, so the 65-80 and 80-95 steps list it as a cheap alternative.
- **Enchanting:** the Arcane Salvager camp object needs a Runed Golden Rod (was Truesilver), and its disenchanting bonus now works for lower-level enchanters.
- **Cooking:** the Journeyman Campfire places from Cooking 90 (was 140).
- **Engineering:** Iron Grenades sell for only 1s 25c now, so the step says to use them.
- **Fishing:** the Fishing Rack's lure fix, and Blizzard's note that some "There is no loot" errors remain.
- **Zephras Isle:** Camping 101: Herbalism is now handed in to Halassa Fernbreeze in Shen'dar Village, not in Valanaar.
- **Razorfen Kraul:** Lonebrow's Journal has moved a little down the road, and the step says so.

## v0.18.0

### Horde quest guide (new)

- **Horde levels 1-30.** The step window, arrow and Quests tab now guide Horde characters. Every Horde race starts in its own zone and joins the shared route at the Crossroads:
  - Orcs and Trolls: Valley of Trials, Sen'jin and Razor Hill, northern Durotar and Orgrimmar.
  - Tauren: Camp Narache, Bloodhoof Village and Thunder Bluff.
  - Undead: Deathknell, Brill and the Undercity, then Silverpine Forest.
  - Skyborne (Windshaper): Zephras Isle with the Windshaper chains and the Shaman totem quests, then the airship to Mulgore, Thrall in Orgrimmar and the Crossroads.
  - Everyone: the Crossroads and the northern and southern Barrens, Sun Rock and Camp Taurajo, Zoram'gar, then the Sepulcher, Hillsbrad, Stonetalon, Ashenvale (Splintertree) and Thousand Needles to Freewind Post. Shimmering Flats is an alternate at the end.
- **Forever content included:** the new starting-zone quests, Camping 101's Cooking intro (other professions are optional), the Orc Mage and Troll Warlock class letters, Forever's new quests in Durotar, the Barrens, Stonetalon and Ashenvale, and Orgrimmar's city errands.
- **Horde dungeon checklists:** Ragefire Chasm, Ruins of Lordaeron, Wailing Caverns, Shadowfang Keep, Blackfathom Deeps and Razorfen Kraul, with their Horde quest chains before, inside and after the run, and bosses in order. Planned runs add their solo pickups to the route.
- **Tirisfal and Silverpine alternate** for Orcs, Trolls, Tauren and Skyborne at 12-15: the zeppelin to Brill, the Undercity flight path, the Silverpine quest loop and back to the Crossroads. Offered at the end of Durotar, Mulgore and Zephras Isle beside the Barrens.
- **Tighter loops:** the Crossroads arrival, Freewind Post, Thunder Bluff and several starting-zone hubs are now one pass each, and northern Durotar no longer doubles back for Fizzle Darkstorm.
- Fixed: Undead objective steps in Deathknell, Tirisfal and Silverpine pointed the arrow at Elwynn Forest.
- **Horde class quests to 30**, inline where they sit on the route and as class guides in the Quests tab otherwise:
  - Warrior: Defensive Stance, Forged Steel, Agamand Heirlooms, the Field of Giants trial, the Brutal armor set, Berserker Stance.
  - Paladin (Undead): Redemption, Lumina Windsinger, Wolfsbane.
  - Hunter: Taming the Beast for Orcs and Trolls.
  - Rogue: the Orgrimmar chain, Lockpicking, Poisons, Tools of the Trade, the Horn of Xelthos, Ravenholdt, Syndicate Sabotage, the Eye of Bhossca.
  - Priest: Hex and Touch of Weakness, Shadowguard, Dark Sacrifice.
  - Mage: Study, Ju-Ju Heaps, Spellfire Robes, Nether-lace Garment, the Mage's Wand.
  - Warlock: Voidwalker for Orcs and Trolls, Succubus and Incubus, the Orb of Soran'ruk, Felhunter.
  - Druid: Bear Form, Moonglade (Skyborne), Cure Poison, Aquatic Form, Cat Form.
  - Shaman: the Fire, Water and Air totems.

### Alliance quest guide

- Fixed: the Wailing Caverns checklist's Raptor Horns step pointed at the far northern Barrens instead of the plains south-east of the Crossroads.
- Tighter loops in Westfall (Poor Old Blanchy's oats on the first farm visit), Stormwind (Shoni with Sprite), Darkshire's arrival and Anvilmar.

## v0.17.0

### Alliance quest guide

- **More routes.** New alternate routes for Ashenvale, Stonetalon, the early Wetlands, late Redridge and Duskwood, and Southshore. The **Guide library** in the Quests tab searches guides, quest names and IDs. It also has dungeon checklists (before, inside and after the run) and special quest chains such as Seeking Caitlin and the Cozy Sleeping Bag. You can track up to three active quests in the step window.
- **More quests, 1-30:**
  - Elwynn and Dun Morogh errands, the Deeprun Tram rats, the Dwarf/Gnome Honor Students flight chain and the Moss-twined Heart.
  - The Westfall lighthouse, Redridge's late bounties, and Duskwood's Look to the Stars, Sven and Abercrombie chains.
  - Darkshore's Murkdeep board, escorts and Absent Minded Prospector.
  - Gaxim's Stonetalon letters and Ashenvale's satyr and Velinde quests.
  - Forever's reworked Wetlands: Bloom of the Heavens, the Doomed Fleet chain, the Thandol Span and the Dragonmaw Retreat.
- **Dungeon plans.** In Quests > Guide library > Dungeons, plan your runs one by one, or use Plan recommended / all / none. A planned run's quest pickups join your route. When its pickups are done at the right level, the step window and the Quests tab offer **Run <dungeon>**, and chat says to find a group. Each dungeon page lists its **bosses in order** with a short tip. The Stockade checklist now continues with the Stormwind chain to King Varian.
- **Questing helpers.** Step text shows a quest's place in its chain ("Chain: part 2 of 5"). Pickups warn when your quest log is full, and Active quests shows how full your log is. A key-bindable **target button** targets the step's quest giver. Settings > **Show optional quests** turns on side errands such as Camping 101.
- **Guide list by level.** The Quests tab groups the leveling guides into level bands. Each guide shows how much of it you've done and whether it's current, suggested, done, outleveled or for later. Suggested guides are in gold.
- **Outleveled pickups leave the route.** A pickup that has gone grey for your level is dropped, unless a later quest needs it. Dropped pickups are listed under Missed quests > Outleveled. Turn on Settings > Keep grey quests in the route to keep them.
- **Tidier step window.** The banner shows the guide's short name and always fits its frame. The level range sits beside the step title. The Pin button and the "Unverified" labels are gone.
- **More Forever quests.** Added:
  - the Dwarf/Gnome and Night Elf Camping 101 skinning lessons;
  - Stormwind's library errand (Reading Room, Shelf Picked);
  - Business in Auberdine and Unrequited Love (Darkshore to Menethil);
  - Bolvar's A Friend of the Family follow-up and The Shamed Lieutenant to Southshore;
  - Forest Song's Vengeful Trail and Shared Fury in Ashenvale.

  The detours are optional, and their turn-ins show whenever the quest is in your log.
- **Shorter town loops.** About a dozen hubs no longer send you away and back for a turn-in that was already ready. These include Saldean's Farm, Sentinel Hill, Menethil, Auberdine, Dolanaar, Darkshire, Astranaar and the end-of-Wetlands Stormwind visit.
- **Special chains offered on the way.** The step window offers "Plan Cozy Sleeping Bag" in Westfall, "Plan The Legend of Stalvan" at Madame Eva and "Plan The Missing Diplomat" in the Cathedral.
- Fixed: logging in or arriving in a zone could keep you on another zone's guide. This happened when a quest ahead needed an earlier chain you skipped there, such as Sven's chain in Duskwood for The Doomed Fleet in the Wetlands. The guide now starts with work in your zone, drops chains you skipped elsewhere, and only sends you for a single missing pickup when the route reaches the quest that needs it. The Greenwarden's turn-in now shows if you have it.
- Fixed: the quest step window no longer takes Forever's controller focus, which could leave the analog sticks unresponsive. Controller step controls stay in the Quests tab.

### Warrior macros

- **Smarter buttons, fewer slots.** Each Warrior macro now does something a spellbook icon can't. Abilities that skip the global cooldown ride along on the attack they belong with:
  - **Fight** fires Bloodrage in combat whenever it's ready.
  - **Fight pack** queues Cleave after every Thunder Clap that lands.
  - **Revenge** and **Shield Slam** keep Shield Block rolling, and **Shield Block** fires Revenge when it's lit.
  - **Taunt** puts a Sunder Armor on the enemy in the same press.
  - The separate Bloodrage and Cleave macros are gone.
- **Context, not copies.** **Fight** and **Victory Rush** select the nearest enemy when you have none or yours just died. **Battle Shout** casts Demoralizing Shout in combat. **Revenge** casts Overpower in Battle Stance. **Taunt** reaches the enemy hitting a party member you've selected, or the enemy under your mouse. **Shield Bash** takes a mouseover enemy.
- Run Set up macros (or `/codex macros`) to update your buttons in place. You can delete the old Rage up and Cleave macros.

## v0.16.0

- The Alliance quest guide now switches to an available local route when you enter a zone. It resumes active objectives and ready turn-ins, and checks completed quest history to catch you up while keeping required prerequisites.
- The Quests tab shows route options for your level, including Loch Modan and Darkshore when eligible.
- Flight-path and hearthstone steps explain how to skip them with Next. Learned flight paths can advance the guide automatically.
- **Duskwood** batches spider drops, the Darkshire inn hand-ins, and the Raven Hill cemetery quests. Ira's Dagger appears when you find the quest starter.
- **Loch Modan** streamlines the Silver Stream Mine loop, adds Excavation Progress Report, and gives each of Bingles' supplies its own waypoint. The timed boar hunt starts at a closer spawn cluster.

## v0.15.0

- Added **Alchemy, Engineering, First Aid, Cooking, and Fishing guides from 1 to 300**. The Professions tab now covers all 12 WoW: Forever professions.
- Crafting guides show the tools and stations you need and can highlight intermediate recipes when you have the materials to make them.
- Rank reminders cover profession books and quests. Cooking keeps the Clamlette Surprise ingredients on your shopping list until you unlock Artisan, and Fishing shows where to catch Nat Pagle's four quest fish.

## v0.14.0

- Added **Skinning and Leatherworking guides, 1–300**. Skinning shows beasts and farming spots by faction, including Zephras Isle for Skyborne. Leatherworking shows the current recipe, material estimates and a read-only crafting outline. The guide includes the Tanning Rack unlock at skill 125.
- **Tailoring** now finishes with Runecloth Shoulders from 280 to 300 and lists the Cenarion Circle ranks for the Venomspew alternative.
- **Enchanting** adds fallbacks for sold-out formulas. Disenchanting estimates use item level and show Nexus Crystals for high-level epics.

## v0.13.0

### Alliance quest guide

- Added an in-game **Alliance leveling guide for levels 1–30**. It starts in Northshire, Coldridge Valley, Shadowglen, or Zephras Isle according to your race, then follows Westfall, Lakeshire, Duskwood, and Wetlands. Loch Modan and Darkshore offer alternate routes, and Deadmines steps are optional.
- Added class quest routes for abilities and milestones such as Hunter pets, Druid forms, Shaman totems, and class spells. Follow them from the Quests tab and return to your leveling route when finished.
- Open the **Quests** tab or use `/codex quests` to browse routes and show the step window. The guide reads your quest log, tracks objectives and turn-ins, and can resume an active quest. Missed pickups stay available, and obsolete breadcrumb steps are skipped when you already have their follow-up.
- The step window names the next zone at section handoffs and shows an end card after the last step. Hearthstone steps explain how to keep your current bind and how to reach the destination if you are bound elsewhere.
- **Also on this loop** shows live progress for unfinished quests that share the current trip. It covers the four starter routes and loops such as Westfall's harvest fields, Redridge's goulash and Blackrock camps, Raven Hill's skeletons, and Wetlands' Razormaw and Angerfang quests.
- The waypoint arrow shows distance on the current map and uses known routes or flight paths for cross-zone travel. It pauses during flights and loading, then recalculates after you arrive. The Westfall mine survey and Wetlands attack plans advance to the next unfinished objective. The Lake Everstill toolbox pin now marks the Sunken Chest.
- Use the Quests tab to move between steps, pin the current step, or show and hide the overlay with a controller. The overlay leaves gameplay input available when the Codex closes. It also has a quest-item button with its own keybind and a completion sound. Settings cover the arrow, item button, class and dungeon steps, hearthstone binding, window lock, and sound.
- **Auto-accept** and **auto-turn-in** have separate settings and start off, so you can read quest text. With either enabled, hold Alt to handle the interaction yourself. Reward choices stay manual.
- Duskwood now pairs Night Watch kills with Rot Blossoms after the follow-up unlocks. Players under 26 get catch-up options before the Wetlands trip. Quest data was checked against Forever build `1.60.1.70862`. Solo XP pacing still needs a live playthrough.
- Added the opt-in `/codex record` quest recorder and quest API diagnostics in `/codex debug` for checking quest credit and waypoints in the client.

### Classes and professions

- **Warrior macros and tanking priorities.** Fight gains Charge at 4 and handles the Battle-to-Defensive opener from 10, with direct Defensive Charge when Vanguard is learned. Thunder Clap gets its own button from 6 in the existing Fight pack slot. Taunt, Shield Block and Shield Wall can enter Defensive on the same bind. From 38, the interrupt button picks Shield Bash or Pummel by stance and equipment. Run `/codex macros` to refresh your bars.
- **Warrior guide.** The leveling tips explain how to pool Rage for Clap, spread threat on packs, and use Victory Rush when lit. Tactical Mastery retains 10 Rage baseline, with up to 15 more from the Arms talent.
- **Mining**: The crafting hint suggests Smelt Gold through skill 184. Added Thelgen Rock in the Wetlands for Tin and Incendicite. The guide shows the skill needed for each rank and marks the character-level requirements as unconfirmed.
- **Blacksmithing**: Added Daeann Steelwind in Valanaar for Journeyman, plus the Sharpening Wheel, Anvil and Master Forge camp objects. The guide explains Iron Buckle's green skill-ups and the Bronze Warhammer alternative. Check Derotain's Imperial Plate quest at skill 240 before buying materials. If it's locked, the guide covers Ebon Shiv with Spectral Essence and Bold Dirk to 300.
- **Enchanting**: Added Annora as the source for Bracer - Greater Strength and Kania as an option for Lesser Mana Oil. The guide flags Shield - Greater Stamina as a limited-stock, bind-on-pickup formula and lists the Enchanted Lute, Arcane Salvager and Arcane Forge camp objects.
- **Herbalism**: Added Felwood as a reported late-game route alongside Eastern Plaguelands. The guide flags conflicting Dreamfoil skill-up cutoffs and Zephras Isle trainer listings, and marks the Seed Hybridizer blueprint drop source as unconfirmed.
- New: **Herbalism guide, 1-300**, in the Professions tab: seven skill bands with every standard herb through Black Lotus, its yellow, green and grey cutoffs, and where to find it (Alliance, Horde and Zephras Isle zones), trainer steps at 1, 50, 125 and 200 and the Incense Candle, Greenhouse and Seed Hybridizer camp objects. Skill-up cards announce a NEW HERB and the next training. Herb colours and zones come from the Forever object pages (the game files don't tie herbs to nodes), so the audit lists what to confirm in game.
- The Professions tab's switch now shows only the professions you've learned, and updates as you learn or unlearn one. If the Skills heading is collapsed in the character window it tells you to expand it.
- New: **Enchanting guide, 1-300**, built for WoW: Forever from the game's own recipe colours and reagents: the cheapest route with two cheap formulas (Enchant Cloak - Minor Agility from Dalria or Kulwia, Enchant Shield - Greater Stamina from Mythrin'dir or Daniel Bartlett) and no reputation: the Runed Copper Rod, Dust to Motes and the Inferior Stamina bracer, then mostly bracer, chest, cloak, boots and gloves enchants with Strange, Soul, Vision and Dream Dust, and Shield - Greater Stamina from 265 to 300 (no Runed Arcanite Rod needed: the game says Superior Defense only needs the Truesilver rod). Forever's new Mote of Magic is counted as Strange Dust. Artisan is taught only by Annora, inside Uldaman.
- Each Enchanting step says which rod it needs (a better rod counts too) and what to enchant, and a **disenchanting** section shows what each required-level band gives, marks the one your step needs, and lists the green and blue items in your bags with what each would give.
- The crafting window guide covers Enchanting: it outlines your next rod first when you don't have it (a better rod counts), and Dust to Motes when the step needs Motes and you only have Strange Dust.
- Enchanting is in the Professions tab, the skill-up cards, the level-up training reminders and the trainer check in `/codex debug`.

## v0.12.1
- Fixed: on the controller, the crafting window's recipe list could stop scrolling. When the window opened with the guide's recipe scrolled out of view, the Codex selected that recipe, scrolled the list and clicked its row by itself, and that took the list away from the controller. The crafting guide now only outlines the recipe and shows its card: it never selects, scrolls or clicks anything in the crafting window.
- Removed: the **Show it** button on the crafting card (it did the same thing). When the recipe is out of view, the card says to scroll to it, and the outline appears as soon as it's on screen.

## v0.12.0
- New: **profession guides for Mining, Blacksmithing and Tailoring, 1-300**, built for WoW: Forever. Forever reworked Blacksmithing (about 200 new plans, and many recipes turn yellow and grey 25 points earlier than in Classic), so the route uses Forever's own recipe colours and reagents, checked against the game files.
  - **Blacksmithing**: the cheapest trainer route: stones, Copper Chain Belt, Runed Copper Belt, Rough Bronze Leggings, Heavy Grinding Stones (kept for Golden Scale Bracers), Iron Buckle, Bronze Warhammer, Green Iron Bracers, Golden Scale Bracers, the Heavy Mithril pieces and Dense Sharpening Stones, then the Imperial Plate plans from Derotain Mudsipper's quests in Tanaris from 240. Every step has an alternative.
  - **Mining**: what to mine and where for your faction (Zephras Isle for Skyborne), and what to smelt for points. Smelting only gives points up to 185 (Smelt Gold).
  - **Tailoring**: the cheapest trainer route to 225 (bolts, Linen Belt, Woolen Cape, Double-stitched Woolen Shoulders, Azure Silk Hood, Earthen Vest, Crimson Silk Vest, the Black Mageweave pieces, Runecloth Belt), then Forever's vendor patterns: Runecloth Gloves (Qia, Winterspring), Runecloth Cuffs (Pexmit, Mount Hyjal) and Venomspew Gloves and Cord (Mishta, Silithus). Forever's trainers stop at 225, and only Timothy Worthington (Theramore) and Daryl Stack (Tarren Mill) teach Artisan.
  - Tailoring's shopping list is in raw cloth (bolts you hold count), and a **cloth** section shows the mob levels and zones for each cloth for your faction, with the cloth your step needs first.
- New **Professions** tab: your skill, the recipe to make now with how many more and the materials against your bags, where to learn it, the trainer to visit when Journeyman (50), Expert (125) or Artisan (200) is due, the whole route (click a step), and a shopping list to 300.
- New: **crafting window guide**. Open Blacksmithing, Smelting or Tailoring and the Codex outlines the recipe to make for your skill, with a card showing how many more, how many you have materials for and its colour. Not learned yet: where to learn it. Gone grey: what's next. **Show it** selects a recipe scrolled out of view. In Tailoring, when the step needs bolts and you only have the cloth, it outlines the bolt recipe first and says how many your cloth makes.
- New: a **skill-up card** in the level-up banner's look when your Mining, Blacksmithing or Tailoring reaches a new step, can train the next tier, hits its cap, or can mine a new vein. Ordinary points stay quiet.
- When your skill is ready for the next tier before your level is (Journeyman needs level 10, Expert 20, Artisan 35), the level-up banner and chat tell you to train it at the level that opens it.
- Settings > Professions turns the crafting window guide and the skill-up cards on or off.
- Fixed: **Show it** did nothing in Forever's crafting window. It now scrolls the list to the recipe and selects it.
- Controller support: the Codex window works with Forever's controller navigation (D-pad, A, B, LB/RB to switch tabs, right stick to scroll), with its own navigation as a backup (Settings > Controller). On the controller the crafting card selects the guide's recipe as the crafting window opens, so there's nothing to press.
- Opening the Codex within a minute of a level-up banner or a skill-up card opens what it was about (that level, or the Professions tab on that profession).
- New look for the minimap button: the Level 60 badge instead of the brown book many addons use, and it now starts on the right side of the minimap instead of the lower left, where most addon buttons pile up (drag it anywhere as before). The Codex is also listed in the addons button under the clock.
- Fixed: the card beside the crafting and talent windows covered the controller hints the game shows under a window near the top of the screen. It now goes below them.
- The skill a trainer teaches each recipe at isn't in the game files, and the Forever guides disagree on it. Visit your Blacksmithing, Mining or Tailoring trainer, then `/codex debug`: it lists any recipe whose trainer requirement differs from the guide.

## v0.11.0
- Every guide checked against WoW: Forever's own game data (build 1.60.1.70862) and Blizzard's 2 Nov notes and 5-6 Nov hotfixes: talent order, the reason for every talent, trainer spells and ranks, macros and tips. 116 fixes across the nine classes:
  - **Warrior:** new **Rend again** macro (RT+Y / 4): a cast sequence moves on even when Rend misses, so press this to put Rend back up. Panic no longer gets stuck at 26-27 before Shield Wall. Tactical Mastery keeps 25 Rage (not 10), Charge gives 9 Rage at 25 (12 from 26), Thunder Clap lasts 10-30 sec by rank.
  - **Mage:** Get away no longer gets stuck before Blink at 20 (Frost Nova only at 10-19). Cone of Cold Rank 5 added at 58. Shatter adds 50% crit against frozen targets (not "almost every crit"); Fire Blast beats Ice Lance on targets that aren't frozen.
  - **Paladin:** Divine Protection and Divine Shield share one 5 min cooldown (Panic tip and trainer notes); Divine Shield Rank 2 lasts 12 sec; Seal of Command's Judgement numbers at 20; Greater Blessing of Kings has no rank.
  - **Druid:** Faerie Fire costs mana and needs caster form; Swipe hits 3 enemies; clearer Feral Swiftness, Natural Instinct, Ferocity and Rend and Tear reasons.
  - **Hunter:** Beast Training (10) added so your pet's Growl keeps up; Aspect of the Pack, Rapid Recuperation, Trueshot Aura duration and trap placement corrected.
  - **Priest:** Shadow Word: Death ranks added to the training reminder; Improved Mind Blast is 2/5 at 33-34; Shadow Reach and Death's backlash corrected; Fear Ward gets its own line.
  - **Rogue:** poisons use the game's names (Instant Poison II...VI and so on); Distract, Adrenaline Rush and poison charges corrected.
  - **Shaman:** the training reminder now includes totems, Fire Nova, Chain Lightning and heals; talent reasons give the value per point; totem durations corrected.
  - **Warlock:** new Fight version from 40 that casts Wrack; Fel Concentration is a 70% chance (not immunity); Improved Corruption is instant from 14; Spell Lock at 36.

## v0.10.0
- New: Find Herbs and Find Minerals stay on. WoW: Forever turns gathering tracking off when you log in, reload, zone or die; the Codex now turns the one you had back on a couple of seconds later. It waits until you're alive and out of combat, leaves another tracking you picked (like Track Beasts) alone, remembers which one you switched to last, and turns tracking on when you learn Herbalism or Mining. At login, tracking that already looks on is toggled off and on so the minimap shows it. Turn it off under Settings > Gathering.
- `/codex debug` now reports gathering tracking.
- The Test level-up button is gone from the This Level tab; it's still under Settings > Level-up banner.
- The Codex window now uses the game's own frame art: the dialog border with the gold title banner, a round class portrait, character-sheet tabs along the bottom, red Blizzard buttons, check boxes in Settings, spellbook page arrows for browsing levels, and cards with the tooltip border.
- The level-up banner and the talent card above the talent window got the same treatment: Blizzard gold titles, gold lines and icon rims like the game's.
- The talent guide only appears when you have a talent point to spend, and goes away as soon as you've spent it. With several points to spend it shows the earliest one first.
- The talent highlight now follows the talent's shape (round, square or choice) instead of always drawing a square box.
- New `/codex debug` lists what the Codex can see (art, talent window, talent points) to paste into bug reports.
- Theme colours (Forever teal or Codex gold) now tint the highlights and accents.
- New talent tree on the Talents tab: your build fills in up to the level you're viewing (gold when a talent is maxed, green when partly taken, grey for later points with the level they come at), the point for that level glows, and clicking a talent lists every point that goes into it and why. Once you've opened your talent window, the tree matches the game's layout.
- The Macros tab now shows where each macro goes: your controller's button sets (R2, L2, L2 + R2...) with each macro on its button, and an action bar with each macro on its key. Controller bindings are drawn as the game's button badges and glyphs (PlayStation shapes, Xbox letters, Switch letters) and keys as keycaps, everywhere in the Codex.
- Parchment cards in the Forever theme get the teal wash of Forever's quest log.
- Fixed: the tab hover glow sat off the text and lit up the selected tab.
- The talent highlight now takes the theme colour (Forever teal) instead of the node's own green, and the card above the talent window moves below it when the window is near the top of the screen.
- The level-up banner is now an unlocks card ("New at Level 17": your talent point, trainer spells, macros, new chapter) that appears after the game's own level-up display instead of repeating "You have reached Level 17". It finds the game's display and waits for it, or waits about 4 seconds, then takes that display's spot on screen (unless you moved the banner).
- Controller glyphs: the PlayStation circle is drawn as a real ring, keycaps have a light face, and empty halves of the controller panels are hidden.

## v0.9.0
- Fixed: the talent highlight and its card stayed on screen after closing the talent window. They now disappear the moment the window closes.
- Fixed: levelling up in combat could create every macro for your level when the fight ended. Now only the macros the Codex made are updated.
- Set up macros no longer overwrites a macro of your own that has the same name (for example your own "Fight"): it keeps yours, tells you, and shows the Codex version in the copy box.
- Auto-updating macros now works even when WoW: Forever doesn't load your saved settings, and the Codex tells you (once, and in Settings) when that happened.
- The talent guide is lighter: once it has found your talent it stops searching the talent window, follows the talent if the window reuses buttons, and also finds talent windows that load later.
- New: a Copy button on every macro, and a copy box with the macro text selected when your macro slots are full.
- New: close the Codex with B or Back on a controller (or Esc), and bind a key or controller button to open it (Key Bindings > AddOns).
- Each tab now remembers where you scrolled to.
- "Updated N macros" only appears when a macro actually changed.

## v0.8.0
- Talent window guide: the talent to take for your level is traced with a glowing outline, sparks and a "Codex pick" tag, with a card above the talent window showing it and your next two picks.

## v0.7.0
- Forever theme (teal, default) and Codex theme (gold) in Settings.
- Test level-up button on the This Level tab and in Settings; `/codex test 30` tests any level.

## v0.6.0
- Minimap button: left-click opens the Codex, right-click opens Settings, drag it around the minimap.

## v0.5.0
- The Codex window redesigned with tabs: This Level, Talents, Trainer, Macros, Tips and Settings, plus level browsing.

## v0.4.0
- Level-up fanfare banner with icons for every unlock.

## v0.3.0
- Settings: controller button names, banner size and position, chat messages, auto-updating macros, window size.

## v0.2.0
- Level-up banner.

## v0.1.0
- First beta: talent per level, trainer reminders, one-click macro setup.
