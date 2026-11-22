# Leveling Codex

## v0.31.0
- Full auction scans no longer hitch the game: every item the scan loaded made the loot comparisons re-read your gear and bags ten times a second. Item data the loot code didn't ask for now waits until the scan is done.
- A scan that stops mid-way (it could sit at "Reading" for good) is restarted where it was after 8 seconds; /codex debug shows the rows read, slow frames and restarts while a scan runs.
- The Journey book fills your screen, so long pages need less scrolling; the other tabs keep their usual height (Settings > This window: Auto, Fit the screen for every tab, or Short).
- Journey chapters: the map plate moved to the right page, so a chapter fits on one spread.
- Your last name is read from the game (WoW Forever's UnitFullName), even with My Secondary Name off in the nameplate options.
- **Journey > Companions** became a page for each person: click a name to read how you met (where, their level and yours), the time and lands you shared, the quests, foes, bosses, dungeons, falls and resurrections you went through together, in your narrator's voice, with their figures and every shared moment. Moments written while you're in a party now remember who was there.
- **Write a note** on anyone in the book ("Steady tank from Lakeshire, owes me a drink") and click **Save note** (Cancel leaves it as it was); a scroll marks the people you wrote about.
- **Journey > Map** shows every moment where it happened, not only level-ups and falls: quests, battles, travels, fortunes and fellowship each have their own pin, and pins on the same spot share one with a count. Hover a pin to read it (and what else happened there); click to mark it.
- **Map layers:** switches under the map turn the trail and each kind of moment on and off, with how many of each the map holds. Your choice is kept.
- **What happened here:** the right page lists the moments on that map, newest first; click one to mark it on the map.
- Continents (Eastern Kingdoms, Kalimdor) no longer show up as lands explored.
- An emote aimed at someone else ("Max thanks Takria Doyouknow") is no longer written as a kind word to you: only one that says "you" or "your" counts, and the ones an earlier build wrote are taken out.
- Companion names are written in ink, so a priest's white no longer vanishes on the paper. Friends and strangers moved under the list, and their names open their page too.

### Gold

- New **Gold** page (next to Stats) with a **mount fund**: how much of your riding goal you have, what's left, and about how long it takes at this session's net gold per hour. Set the goal amount and level with the - and + buttons. A riding trainer's price is noted when you visit one, and reaching the goal level tells you in chat where the fund stands.
- **Stats > Zones** has a **Time | Money** switch: gold earned and spent in each zone, net gold, and net gold per hour there.

### The Codex tabs at the auction house
- **Five tabs of their own** next to Buy, Sell and Auctions: **Codex** (your visit and the market), **Market**, **Deals**, **Quick Sell** and **Scan**. They join the row after Auctionator's tabs when it's installed. With Auctionator, they now sit after its tabs instead of hidden under them. (They also didn't show for players who had turned off the old floating auction card: that setting no longer hides them.) Nothing floats over the auction house any more, and the Codex opens again on the tab you left it on next time.
- **Market, like a stock market:** **Top gainers** and **Top losers** (against earlier days, or since the scan before when an item has only one day), each with a little price line and its change; **Hot and signals**: big moves while the supply dries up, and BUY / SELL signals for items far from their usual price; click any item for its **price chart**, a line of its days (or of your scans on the first day) with the usual price dashed across, its change, supply, how much it swings, its range and the vendor price. **Price at least** keeps cheap items off the lists.
- **A market ticker** runs edge to edge across every Codex tab: each of the biggest moves scrolls past with its icon, name, price, an up or down arrow and its change on a green or red tag. A LIVE light breathes while prices are fresh. Hover the ticker to stop it, hover an item for its details and click it to open its chart. Your gold and the scan age moved up into the header to make room.
- **Your trades: wins and losses.** Every buy from Deals, every post from Quick Sell and every sale or expiry the game reports in chat is kept between visits. A sale of something you bought is a flip: its profit after the 5% cut against what it cost. The page shows your net profit, how many flips you won, what you still hold and what it's worth if sold now, the deposits lost to expired and cancelled auctions, a line of your profit flip by flip, your holdings and your recent trades.
- **A quick refresh on every tab**, next to Scan all in the header: Update (Codex), Recheck movers (Market), Recheck deals (Deals), Reprice bags (Quick Sell, which also reads your auctions and checks them for undercuts). No need to go back to the Scan tab.
- **Overview:** what you posted, bought and paid in deposits this visit, your mount fund, the market data and how old your last full scan is, the money to make (your best deal, what your bags are worth, undercut auctions), and what your guide still needs with today's prices.
- **Deals:** every listing a vendor pays more for, and every flip (listed far under its usual price), with the profit per item after the 5% cut and how many are listed. Filter by **All deals / Under vendor / Flips**, drop small ones with **Worth at least** (any, 10c, 1s, 10s, 1g), and set how far under usual a flip must be. **Check** looks up the listings, then the button shows how many and the total ("Buy 2 for 40c"); a commodity asks you to confirm the server's total, and the Codex cancels it when the price went up. **Hide** an item you never want to see; Show hidden brings it back.
- **Selling:** your tradeable bag items, most valuable first, each with a price tag (SELL NOW, FAIR, FEW LISTED, FALLING, BELOW USUAL, VENDOR IT; hover it for the reason), its price, the lowest and usual prices and what the stack comes to. **- / +** nudge a price by 5% (Auto goes back), **Post** posts the whole stack, and **Post next** posts the most valuable item in one click, then the next. Undercut and auction length sit at the top.
- **Your auctions** (on Selling): **Check undercuts** searches each item you have listed and marks it UNDERCUT or CHEAPEST with the cheapest price that isn't yours. **Cancel** (two clicks) takes one down; the item comes back by mail and the deposit is lost.
- **Smooth full scans:** Scan all waits until the auction house has sent every listing, then reads them a slice of each frame (Scan speed: Smooth, Balanced or Fast) and saves the prices the same way, so the game no longer stutters. Vendor prices for scanned items are looked up a few at a time afterwards. The server still allows one full scan every 15 minutes.
- **Snipe deals** (on Deals): between full scans, the Codex searches the items worth watching one a second, lap after lap, and when one is listed as a deal it chimes, says it in chat and marks it LIVE at the top of Deals. It follows your choices on the page (All deals / Under vendor / Flips, Worth at least, Flip at): change one and it watches the new list at once. Each deal it finds is checked straight away, so its row shows how many are under the limit, the total and the **potential profit**, and the sniper's line adds up the potential profit of every live deal. Buying stays a click.
- **Your trades counts every sale:** items you posted through Blizzard's Sell tab or Auctionator join the record from your auctions list, and each sale takes its real price from the mailbox's "Auction successful" invoice, including sales made while you were offline. A sale whose mail hasn't been read yet shows as waiting.
- A deal whose listings are gone, or no longer cheap enough, now leaves the list after Check instead of staying as "Gone".
- **Full scans that get no answer recover.** The Codex now also checks the auction house's row count every second (the client doesn't always send the "rows ready" event), and when a full scan gets no answer within a minute (the server allows one every 15 minutes, and another addon's full scan, like Auctionator's, uses it up) it reads page by page instead, and Scan all won't offer the instant scan again until the 15 minutes are up. When Auctionator runs its own full scan, the Codex now files those prices too.
- **A scan no longer gets stuck** on one item that errors while its price is saved (it stopped at "Saving prices 4,025 of 6,900"): that item is skipped and the scan finishes; `/codex debug` names the error.
- **The paged scan keeps going** when the server drops a request for the next page: it asks again (three times) instead of stopping.
- **Smoother big scans:** a full scan of about 200,000 listings no longer makes the game hang while it reads and saves. Listings are now added up per item, so the scan no longer creates one table per listing for the game to clean up afterwards. While a scan runs, the page redraws once a second, and the market and deal lists wait until the scan ends instead of being rebuilt over and over. The deal list also rebuilds at most every 3 seconds while the sniper keeps finding new prices. Reading now watches how long the game's own frames take: reading listings makes the game load item data, so when a frame runs long the Codex pauses a moment, reads far fewer rows in the next one and speeds up again once the game keeps up. The page redraws every 2 seconds during a scan.
- **Quick refresh buttons show their progress:** Update, Recheck movers, Recheck deals and Reprice bags count "Working 3 / 12" with a bar under the button, then say Done.
- **No more "item 763" with a question mark:** items a page-by-page scan or another addon's scan filed by ID now take their name and icon from the game (the icon at once, the name as the game loads it).
- **With Auctionator, the Codex tabs become side tabs** on a gold-framed rail fixed to the auction house's right edge, each with an icon, instead of running off past the window. Without Auctionator they stay in the row after Auctions.
- A lit choice too narrow for the check mark (like Auto above the chart) keeps its label inside the button.
- **Chart intervals like a trading chart:** Auto, 1m, 5m, 15m, 1h, 12h and 1d above the price chart. Every **Search it now** at least a minute after the last one adds a point to the line (a search within the minute updates the last point), and the Codex keeps up to 40 readings per item for a week.
- **Price chart figures:** "Since last look" (was "Since last scan") and "Listed" now work after one search: a price saved before this version counts as the first reading, and a search soon after the last one no longer replaces the only reading there is. Listed shows "1 -> 3"; Swings needs two days of prices (was three). A figure without enough readings yet says what it needs instead of "--".
- **Scan all whenever you like.** The instant scan is a server limit of one every 15 minutes; in between, Scan all reads the auction house page by page instead, with no cooldown and spread over frames so the game stays smooth.
- **Scan:** Scan all with its progress, **Scan my bags** (prices everything you could sell), **Scan guide items**, a waiting list you can stop, and **Look up an item** (type a name or Shift-click an item): its lowest, usual, median and high prices, how many are listed, the vendor price, the trend, a verdict and a line chart of its last two weeks (Open in Market charts it there).
- **Protections:** the Codex never posts below what a vendor pays after the 5% cut ("Vendor it"). A price far under the usual one (30% by default) needs a second click, and so does posting something you bought through Deals for less than you paid.
- Every post, purchase and cancel is one click on a Codex button: nothing happens by itself.
- **Price history and trends** per realm, from your own scans: the usual price over the last two weeks and whether today's price is up or down.
- **A new price block on item tooltips:** a Codex prices heading with its age, the lowest price now and the usual one in coin icons, the trend as a coloured percentage with the last days drawn as small bars, the vendor price, and a one-line verdict ("Above usual: a good time to sell", "Vendor it: a vendor pays more than a sale here"). Hold Shift for low, median and high and how many were listed.
- **Works with Auctionator.** Every Auctionator price the Codex looks at (your bags, your guide's items, items you hover, items it already tracks) is filed into the Codex price history for the day Auctionator scanned it, so trends, Deals, Selling and the price chart grow from Auctionator's scans as well as your own. The Codex leaves the automatic searching to Auctionator, so the two never search over each other. **Search in Auctionator** on Overview puts your guide's items into its search. Tooltips keep Auctionator's own price lines, and the Codex block adds the usual price, the trend and the verdict.
- Gold tab: how many prices you have, what your guide needs with today's prices, the selling settings (undercut 1c, 1%, 5% or 10%; loss warning; flips; auction length; deals worth at least), and switches for the tooltip block, the Codex tab and the automatic searches.

### A tidier Codex window

- The tabs under the window are now groups: **Leveling** (This Level, Talents, Trainer, Macros and Tips), Quests, Journey, Professions, Loot, Stats and Settings. A group with several pages shows them as a strip of buttons above the page and opens the one you used last. The tab row no longer squeezes to fit.
- Settings is split into pages instead of one long list: General, Questing, Map and arrow, Group, and Helpers (trainers, professions, gathering and the vendor).

### New: the Journey tab, your adventure journal

- **An open book.** The Journey opens wider than the other tabs, like Loot: a leather cover with your name, portrait, chapter and a line about the land you stand in, a ribbon for each page, and every page laid out across two parchment sheets with a spine, page corners, running heads, page numbers and a bookmark in the colour of your level band. Headings carry a flourish and paragraphs open with a large initial letter.
- Six spreads instead of one long scroll: Overview (today's entry, your journey in numbers as wax-sealed tiles and where you are on the left; the road from 1 to 60, the latest chapter in full and who you travel with on the right), Story, Quest Log (the list on the left page, the chosen quest on the right), Map (the map and its key on the left; the land's story and every land explored on the right), Trophies (its sections flow across both sheets) and Companions (your fellow adventurers on the left; your closest companion and the people you met on the right).
- **More storybook.** Every chapter opens with a few sentences of its own (where it happened, the quests and foes it took, the dungeons, the falls, who shared the road), and the chapter where you first reached a land opens with a line about that land (about fifty of them, from Elwynn Forest to Silithus). The Story opens with a preface: your whole journey so far in a paragraph. The Map page tells each land's story: when you first reached it, the moments written there, quests, levels, great foes and falls.
- **New moments:** your **first mount**, a **new home** when you bind your hearthstone somewhere else, **resting at an inn** (at most every two hours), **milestones** (your 50th, 100th, 250th... quest, 100, 500, 1,000... foes, 5, 10, 25... miles walked, a 10th and 25th fall) and the first time you walk into each **great city**. Levels 20, 30, 40 and 50 have their own lines, and quests, bosses, dungeons, new lands, deaths, flight paths and companions have more ways of being told.
- **A page for every level.** The Story reads one chapter per spread, like turning the pages of a book: the chapter's heading and days, the land's lore, the level-up line, a full-width map of where you walked, the chapter's prose and its numbers on the left; everything that happened, day by day, on the right. **< Previous chapter / Next chapter >** (and the page turns at the foot of the sheets) go back through your whole journey, **Latest** returns to the page you're writing, and **Contents** opens the preface and a list of every chapter.
- **Your name, first and last.** WoW Forever's last names are on the cover, the running heads and in the preface. If the book can't read it from the game, **Set last name** on the Contents page sets it (or none).
- **A narrator of your own.** Each character's story is told by one of three narrators (**Chronicler**, a formal history; **Fireside**, a tale told across a campfire; **Bard**, a song in prose), picked for your character and changeable on the Contents page. Two characters doing the same thing get different words for it.
- **Traits and an epithet.** The journal works out who you are from what you do (the Wanderer, the Unbroken, the Undaunted, Friend of Many, the Lone, the Gatherer, the Angler, the Artisan, the Merchant, the Delver, the Warbound, the Dutiful, the Restless) and shows the strongest under your name on the cover. It colours the chapters too.
- **Chapters that build on each other:** returning to a land you left behind, a clean chapter after a bad one, the hardest chapter yet for falls, the quickest or the longest level so far. Moments remember too: dying to the same foe again ("a grudge is forming") and the third favour for the same quest giver read differently.
- **Gathering and fishing.** Mining, herbalism, skinning and fishing now write moments: your first vein, herb, hide and catch; the first of every new ore, herb, hide and fish; rare finds (gems, green items, crates and bottles from the water); the 10th, 25th, 50th, 100th... of each; and long sessions told when they end ("Cast a line for 40 minutes at Lake Everstill: 22 catches, ..."). Trophies has **In the wilds** (counts, what you gathered most and your best finds) and **From the land and water**; the chapter's prose mentions them.
- **Many more ways of telling** quests, kills, errands, bosses, dungeons, new lands, deaths, flight paths, companions, level-ups, your first mount, a new home and an evening at an inn, plus a second line for almost every land.
- The book is old paper in sepia ink in every theme, so it reads as a journal. A continent (a position read on the Eastern Kingdoms map) no longer counts as a land you explored.
- **Quest Log** polish: a proper heading with how full your log is, rows with a ? or ! mark, the level in its difficulty colour and a progress bar, zone headings with counts, a READY TO TURN IN stamp, the guide's note for the quest, and LATELY COMPLETED: your last quests as the journal told them. Fixed: in game the Quest Log page stopped drawing halfway (no buttons and no paper).
- **A taller window:** Settings > This window has **Height - / +**, **Fit the screen** and **Normal**, and the grip in the window's bottom right corner drags it taller or shorter. **Size** still scales the whole window down or up.
- **Quest Log** page: every quest in your log under the game's own zone headings, like the game's quest log. Pick one to read it as a page of the journal: its level and difficulty, when and where you took it up, who gave it and who waits for it, its goals with progress bars, the reward, and the line the journal will write when you finish it. Show in guide, Track and Abandon (two clicks) sit at the bottom.
- **Today's entry** opens the Overview: this session told as a few sentences (how long, the levels and lands, quests, foes, bosses and rares, your firsts, close calls and falls).
- A storybook of your character's journey that writes itself as you play: every level, every new land, quests turned in, dungeon runs and bosses, deaths, flight paths and the friends you grouped with, each told as a line of the story ("Conquered Edwin VanCleef and saved Westfall", "Heroically did the chores: murloc duty in Hillsbrad Foothills").
- Chapters by level (Chapter I, II, III...), newest first: each opens with the line of its level-up, names the land where most of it happened, shows the time, quests, foes and falls of that level, and tells its moments in order along a timeline. Filters for Quests, Battles, Travels and Deaths.
- The map: your trail on each zone you visited, coloured by your level then, with stars where you levelled up and skulls where you fell, and every land you explored as a row of chips. Click a moment in the story to see where it happened.
- The same trail on the world map (Journey > Show my trail on the world map), plus the road from 1 to 60, the journey in numbers (quests, foes, lands, miles walked, dungeons, deaths) and your fellow adventurers.
- More moments: your **first bag** and your **first green, blue and epic**, **close calls** (a fight you walked away from under 15% health), **gear upgrades** you keep wearing for a minute, **rares** you slay, and each **profession tier taken to its cap**. A death now names who did it.
- Each chapter of the story shows a small map of where that level happened, with that level's trail and pins. Click it to open the Map page. The Treasures filter shows your firsts and upgrades.
- The MMO moments too: **dungeon runs** told when you leave (time, bosses, wipes and who came), **wipes** on a boss (and a boss you beat "after 3 wipes"), **battlegrounds** won and lost, **honorable kills**, **duels**, being killed by another player (with their race and class), **resurrections** by other players, **trades**, waves and other emotes aimed at you, joining a **guild**, **campfires** you light or sit by, **crafting sessions** ("Toiled late into the night at the anvil: made 12 Copper Bracers"), profession milestones, the **auction house** (your visits, sales, lots that came back unsold and the gold you collected at the mailbox), your purse's high marks (your first gold coin, ten gold, a hundred) and quests you gave up.
- New story filters: **Fortunes** (firsts, upgrades, crafts, professions, the auction house and your purse) and **Fellowship** (companions, resurrections, trades, duels, waves and campfires). Today's entry tells these moments too.
- **Trophies** page: your four firsts as cards (the ones still to come stay greyed), your nemeses (who killed you most), close calls, bosses and rares, gear upgrades and craft milestones. Below them THE LEDGER (battles, fortunes and fellowship in numbers) and lists of your crafting, auction house, dungeon runs and battlefields. Companions adds **Friends and strangers**: the players who raised you, traded with you, duelled you or waved at you.

## v0.30.7

### Dungeon guides

- Alliance Stratholme now lists Ezra Grimm and Magistrate Barthilas, and Alliance Scholomance lists Marduk Blackpool and Vectus, like the Horde guides. Each ticks off when it dies.

## v0.30.6

### Quest guide fix

- Theramore: "They Call Him Smiling Jim" is skipped once you have turned in "James Hyal" (the Missing Diplomat), because the game makes the two exclusive. Guard Byron no longer sends you for a quest he cannot give.
- Vendor errands for a quest's items (such as the Soothing Spices Swamp Eye Jarl wants) no longer vanish because some unrelated later step of the guide was already done; they stay until that quest is handed in, so you buy before you accept.

## v0.30.5

### Quest guide fixes

- Buy and collect steps (such as the Southshore cloth and thread errands) no longer come back after you log out once you've handed the items in.
- Logging in no longer jumps to a later guide in the same zone (the 39-40 Arathi guide at level 34): the guide that fits your level keeps the step.

## v0.30.4

### Quest guide fix

- The Hillsbrad to Arathi step now points at the gap in Thoradin's Wall on the road instead of a spot in the hills north of Durnhold Keep, on both factions' routes.

## v0.30.3

### Quest guide fixes

- Both Horde Brackenwall routes now send you to Darkfang spiders near the Theramore Infiltrators for the 6 Acidic Venom Sacs required by **The Black Shield**.
- **Jarl Needs Eyes** now shows the Forever requirement of 40 Unpopped Darkmist Eyes on both factions' routes.

## v0.30.2

### Quest guide fix

- The quest arrow keeps pointing until you are within 8 yards of the final waypoint, so it can guide you closer to quest NPCs in cities and buildings.

## v0.30.1

### Quest guide fix

- Returning to Southshore with Brewer's Trade ready to turn in no longer switches you from Soothing Turtle Bisque to the older Coastal Patrols route. The guide keeps following your current route when you have outleveled the alternate.

## v0.30.0

### Profession guides

- Hover over a profession in the game's profession book to see your skill and current leveling step. Mining, Herbalism, Fishing and Skinning also show what to gather or where to go.
- Open a profession window for a compact guide beside the list. It shows recipe difficulty, estimated crafts, materials and prerequisites, or gathering advice when the route calls for it.
- The Professions tab has a skill progress bar, separate material and bag counts, and clearer leveling route previews.
- Audited all 12 guides against the latest Forever client data. Blacksmithing switches to Bronze Warhammer at 129, and the guides include updated Cooking alternatives, gathering routes, Fishing Rack and Seed Hybridizer advice.

## v0.29.1

### Quest guide fixes

- Fixed the guide sending you to objectives or turn-ins for quests you never picked up, including **Foreboding Plans** and **Venom Bottles**.
- Earlier pickups you still need for a follow-up can appear under **Quests > Quest log > Missed pickups**.
- Clarified how to accept separate quests from objects such as the Syndicate Documents, Corpse Laden Boat, and Bloodsail Correspondence.

## v0.29.0

### Dungeon encounter guides

- Dungeon guides show boss mechanics and progress in the Quests tab and step window. The guide follows supported encounters when they start and marks bosses defeated when the game reports a kill.
- Optional bosses and rare spawns can be skipped or marked defeated manually.

### Quest step guide

- The NPC portrait sits in a recessed frame that matches your theme. The step's status color now fades behind the title, and the **Next step** button is beveled with hover and press feedback.
- Stranglethorn routes keep their own guide suggestions on cross-zone steps. Those suggestions stay available when a dungeon checklist is ready.

## v0.28.3

### Druid macros

- **Fight Cat, Fight Bear, and Prowl Cat** can dismount and shift before their usual attacks or Prowl. Cat shifting accounts for whether you have learned Aquatic Form.
- **Heal Up** starts with instant Rejuvenation in combat and Healing Touch between fights from level 12. Press again for Regrowth. Both sequences heal you even with an enemy targeted.
- **Panic Bear** can dismount and shift into Bear or Dire Bear Form before using Frenzied Regeneration and Enrage. **Cancel Form** returns you to caster form and is available from level 10 on every Druid path.
- Run `/codex macros` to update your existing Codex macros and add Cancel Form.

## v0.28.2

### Travel and guide resumes

- Reloading at Sentinel Hill during the Darkshire chapter now points you across Duskwood to Rebel Camp for **Jungle Secrets**.
- Added arrival checks to 41 boat, zeppelin, and airship crossings, including the Skyborne skycutter and Horde dungeon, class, and attunement trips. Each leg of a round trip advances at its own destination.
- Fixed earlier travel steps reappearing when you resume the relevant guides at Ironforge, Refuge Pointe, Everlook, Thunder Bluff, or on the Westfall coast.

## v0.28.1

### Alliance and Horde leveling routes

- Reviewed the level 1–60 guides, including racial starts, alternate routes, and class and dungeon quests. Starter pickups now follow their prerequisites, and the Durotar coast and Silverpine routes need fewer trips.
- Added nearby quests to existing loops, including Ambermill Investigations, Wanted! Marez Cowl, and Repurposed Totems. Updated directions for the Kurzen Stockpile and Krol'dok Stronghold.
- Added missing turn-ins in Uldaman and the Plaguelands. Booty Bay now points players carrying Ruzzgot's or Lozgil's delivery to the Farholde guide before the trip to Ratchet.
- More boat and zeppelin steps advance at the destination. Taking the flight marked by the guide keeps the selected route active on landing. Harlo's Wetlands pickup can reappear when you reach him after joining the route midway.

## v0.28.0

### Find your next gear upgrade

- **New Loot Journal.** Click any slot on your equipment overview to see upgrades you can get at your current level. Each result shows how it compares and where to get it. Set a higher level in Filters to plan ahead.
- **Pick the sources you want.** Toggle sources individually, or use **Clear sources** to build a shortlist. **Dungeon drop** includes bosses and regular dungeon enemies. You can also filter weapons by type and handedness. Protection Warriors start with weapons that leave room for a shield.
- **Compare a drop before you swap.** Choose an item from your bags or paste an item link into **Compare** to see estimated score and stat changes. Your talent path sets the default scoring priorities. Change them under **Profiles**, where you can also turn on tooltip ranks for other specs.
- **Follow a reward to its source.** Quest routes show known chain steps, quest givers, and pickup points. Save a target to the floating tracker and hover over it for item stats. In controller mode, **Map** sets the pin for you to view with your usual world-map button.
- **Less tooltip clutter.** Enemy mouseovers use the game's normal tooltip. The quest guide's target button shows the creature names it can target.

### Quest routes and travel

- **More Alliance quests in Stranglethorn Vale.** The guides add 36 quest entries across Rebel Camp, the Kurzen Stockpile, Booty Bay, and the southern shore. Grouped objectives cut down on repeat trips, and revised directions help you find keys, strongboxes, ships, and quest handoffs.
- **New Drowned City checklist.** The optional Alliance dungeon guide shows which quests to pick up before diving in, then walks through the encounters and post-run turn-ins.
- **Clearer travel steps.** Corrected the Thandol Span return directions and the Wetlands boat handoff. The Duskwood guide keeps **Armed and Ready** active when your flight lands at Sentinel Hill, even if a Westfall turn-in is ready nearby.

## v0.27.0

- Replaced the scrolling Quests tab with a journey board: connected area map previews, route progress, one selected quest panel, and area checklists paged six cards at a time.
- A side rail opens two-column route and dungeon boards, quest-log categories, party panels and focused option groups. Guide previews keep the followed route, dungeon plans remain separate from entering a run, and quest searches open the matching area and page.
- Area previews use the client's world-map artwork and explored terrain. Route cards show their zone's map; dungeon cards label their entrance-area map. Missing map APIs or artwork leave a readable fallback without opening or changing the world map.
- Cleaned up documentation, guide notes and interface wording. Optional integrations retain their existing behavior.

## v0.26.0

### Quest chat announcements

- Quest announcements use a recognizable chat marker, native quest and item links when available, clear progress counts, and distinct accepted, objective-complete, ready-to-turn-in and turned-in messages. Codex clients display a badge and colored status icons. A private preview is available in Settings and Quests > Party.
- Existing opt-in switches, message throttling, raid exclusion and quest tracker duplicate suppression remain in effect.

### Quest guide buttons

- Place the quest item and target buttons independently on the left, right, top or bottom of the step window. Each has horizontal and vertical offset sliders, controller-friendly adjustment buttons and a position reset.
- Settings and Quests > Guide setup offer the same placement controls and separate switches to hide either button. Changes made in combat apply when combat ends.
- Unlock button dragging in either screen to move separate Item and Target handles with the mouse, then lock them again. Handles preview missing buttons and pause in combat; drops update the saved offsets, whose range now covers the screen.

### Quest steps and dungeon preparation

- **Wetlands eastern loop:** gather Crocs of the Sky scales, Carnage's Rotclaw bait, Razormaw incisors and Perfect Razormaw Eggs on the same Green Belt/Raptor Ridge trip, with shared progress in the step window. Carnage offers the existing elite Take/Skip choice and gives a cave entrance waypoint, Offering Stone instructions and a clickable bait item. Raptor pickups wait until after the coast quests to keep the first Menethil visit's quest log lighter.
- **Step-guide travel and dungeon preparation:** clickable items show live cooldowns, flights initialize connecting routes, and return steps name the next flight. Completed-history handling accepts keyed sets and keeps confirmed completions for the session. Corrected Snellig's wreck and lower-deck directions. Dungeon pages and the Route tab offer outdoor quest preparation before the run; readiness waits for all outdoor pickups, and a small footer icon replaces the wide Run button.
- **Sovik's Gnomeregan errand:** both Horde guides now name the gossip option "What else do you have to say?", explain retries and automatic acceptance, and remind you to check the quest log before leaving Orgrimmar. The pickup is no longer hidden when Rig Wars is absent.
- **Alliance and Horde quest interactions:** corrected missing dialogue, event triggers, escort releases, and quest-item actions in leveling, alternate, dungeon, class, and special guides. The dated audit notes list each change and its sources. These steps still need in-game verification.

## v0.25.0

### Horde quest guide, levels 30-60

- **The Horde route now runs to 60.** 27 new leveling guides follow on from Thousand Needles:
  - **30-40:** Tarren Mill, Alterac and Hammerfall, the Shimmering Flats, Desolace, Grom'gol and Nesingwary, Brackenwall Village, Alterac and Arathi again, then Kargath.
  - **40-50:** Grom'gol, Stonard, Desolace, Gadgetzan and Brackenwall, Camp Mojache, Booty Bay and the southern jungle, the Swamp of Sorrows, Lost Rigger Cove, Revantusk Village, then Feralas and Un'Goro.
  - **50-60:** the Blasted Lands, the Searing Gorge and Burning Steppes, Azshara, Felwood, Un'Goro, Winterspring, the Plaguelands (the Bulwark, Tirion Fordring, Darrowshire and Northdale), then Moonglade and Silithus, ending with Calm Before the Storm in Orgrimmar.
- **Alternate routes for every level.** Each level from 30 to 60 has at least three guides to choose from, the main route included. The alternates include early Stranglethorn, Desolace or Dustwallow, the Badlands before Arathi, the Searing Gorge, the Blasted Lands and Un'Goro in the late 40s, and other orders through the 50s. Forever's **Riverglades** has three Horde routes from **Rog'mar**: the Plains, Bolder'ok and the Twilight's Shroud, and the Eastsea pirates out of Powderfuse Port. There is also a route through **Shen'dralas**. Each guide suggests where to go next.
- **Horde dungeon guides for 30-60.** Every dungeon from Gnomeregan to Stratholme has a Horde guide with Horde quests and travel, before, inside and after the run. That includes Forever's Excavation Site, City of Dalaran and Krol'dok Stronghold. Uldaman is two runs, because Jarkal hands out the gem quest in between. The Horde reaches Gnomeregan through Scooty's transporter in Booty Bay.
- **Horde attunements.** New guides cover Onyxia (from Warlord's Command to Blood of the Black Dragon Champion), the Seal of Ascension, Attunement to the Core, the Shadowforge Key and the Key to Scholomance.
- **Horde class quests 30-60.** These include the Whirlwind weapon, Celestial Power, the Felsteed, the Orb of Orahil and Kroshius, Forever's shaman weapon chain (The Tempest's Weapons), Da Voodoo, and every class's Sunken Temple chain. Where the route already passes a class objective, such as the Bloodscalp tusks, the Twisted Totems or the Azshara errands, your class gets a step for it while the quest is in your log.
- **Quest log clean-up.** At 30, 46 and 48 the guide reminds you to drop grey dungeon quests you never ran.
- The new guides are not yet tested in game. Steps that need a check carry a note.

### Quests tab

- **A tidier Quests tab.** The step card is shorter (its instructions use the smaller font) and holds the Previous, Next, Show on map and Hide buttons along its bottom, with the guide's progress on its top line. The Step, Route, Guides, Quest log and Party tabs are one row of choices, so the open one stands out. The Quest log lists your quests as rows with small Show and Track buttons instead of two columns of long buttons, and the clean-up list does the same with a small Abandon button.
- **Guides opens on your level.** Instead of one long list of every guide, Guides now has five views: **Your level** (the guide you're on, the others that fit your level, what's coming up next, dungeons at your level and class quests you can do), **All levels** (every leveling guide by level band), **Dungeons**, **Special** and **Class**. The Guides tab always opens the list, and the search works in every view.

### Fixes

- **Picking a route asks first.** Clicking a guide under Quests > Guides used to switch to it at once, with nothing to say so. It now opens the guide's page, and **Start this route** switches to it and says so in chat. The Route tab starts with a **You are on this route** card (with a **Change route** button, and a short "Started" line right after you switch). The other routes for your level sit below it as guide rows with their levels and progress, so they no longer look like a choice you still have to make. A route's page lists its steps, says how it fits your level (not started yet, outleveled, or how far along you are), and clicking one of its steps no longer moves your step window before you start it.
- **The quest log clean-up note stays read.** The note at the start of a band (Tarren Mill, Alterac and Hammerfall and the others) came back after every /reload or login until you pressed Next again. Next now keeps it passed, and it also counts as passed once you've done a later step of that guide.
- **No flying straight back.** The arrow could send you to a flight point in the next zone to walk the rest (Darkshire to Sentinel Hill for Sven's Camp), then tell you to fly back once you landed. It now points on to the step, with its distance across the zone border.
- **Eastern Plaguelands positions.** Forever redrew the Eastern Plaguelands map. The arrow pointed at the old spots for Tirion Fordring's hut, the Symbol of Lost Honor in Northdale and the Stratholme gate.
- **Krol'dok Stronghold.** Entering it now opens its guide, and each boss is checked off when it dies.
- A level 28 entering a zone that has a later chapter (Duskwood at 30, Hillsbrad at 30) no longer jumps into that chapter past the route's own next guide.

### Alliance quest guide, levels 30-60

- **The route now runs to 60.** About 35 new leveling guides follow on from the Wetlands:
  - **30-40:** Darkshire, Southshore and Alterac, Refuge Pointe, Theramore and the Shimmering Flats, Desolace, Stranglethorn, the Swamp of Sorrows, Arathi and Aerie Peak, then Dustwallow.
  - **40-50:** Desolace again, the Badlands, Stranglethorn and the Swamp, Tanaris, Feralas, the Hinterlands and Un'Goro.
  - **50-60:** Booty Bay, the Searing Gorge, the Blasted Lands, the Plaguelands, Felwood, Feralas, Azshara, Un'Goro, Winterspring and the Burning Steppes, ending in Silithus and Moonglade.
- **Alternate routes for every level.** Each level from 30 to 60 has at least three guides to choose from. They include Forever's **Riverglades** (Farholde Keep, then Sunnyglade and the Twilight's Shroud), **Shen'dralas**, early Stranglethorn, Theramore, the Searing Gorge, the Blasted Lands, Azshara, Winterspring and Silithus.
- **Dungeon checklists for 30-60.** Each dungeon from the Scarlet Monastery to Stratholme has a checklist, including Forever's Krol'dok Stronghold.
- **Class quests 30-60.** These include the Warrior Whirlwind weapon, the Paladin Tome of Nobility, the Warlock Felsteed and Orb of Orahil, Mage Celestial Power, and each class's Sunken Temple chain. Each dungeon checklist recommends itself to the classes whose chains need it.
- **Attunement guides.** New guides cover the Drakefire Amulet (Onyxia), the Seal of Ascension (Upper Blackrock Spire), Attunement to the Core, the Key to Scholomance and the Shadowforge Key.
- **Item notes.** Steps say what to buy and where: Soothing Spices, Elixir of Water Breathing, Thorium Bars and Fine Thread. They also say what to get from a crafter or the Auction House.
- **Quest log clean-up.** At 30 and again in Booty Bay, the guide reminds you to drop grey dungeon quests you never ran.
- The Quests tab now splits 30-60 into three level bands: 30-40, 40-50 and 50-60.
- The new guides are not yet tested in game. Steps that need a check carry a note.

## v0.24.0

### Macros

- **Macros for every talent path.** Each talent path now has its own macro set, built for how that spec plays while leveling: Arms and Fury Warriors, Holy and Protection Paladins, Beast Mastery and Survival Hunters, Assassination and Subtlety Rogues, Arcane and Fire Mages, Demonology and Destruction Warlocks, Discipline and Holy Priests, Elemental and Restoration Shamans, and Balance, Cat, Bear and Restoration Druids.
- **Your macros follow your path.** Set up macros, the level-up refresh, the Macros tab and the level-up banner all use the path you follow. Switch path and the Codex's macros change to the new path's versions in place, on the same buttons and keys. A custom path uses the set of the path closest to your points.
- **Every guide's macros audited and fixed.** Every class's guide macros were checked against WoW: Forever's own spell data:
  - Cast sequences that waited on a cooldown are gone: Paladin's Judgement and Holy Strike, Mage's Frost Nova, Hunter's Aimed Shot, Shaman's shocks, Rogue's Kick and Gouge.
  - Lines that could never fire are fixed: Frost Mages lost Fire Blast once Ice Lance arrived, so targets that weren't frozen had no finisher.
  - The Rogue's builder and finisher now sit on two buttons, so a miss or a crit no longer finishes at the wrong count.
  - The Warrior's Bloodrage tips now say when it really fires.
- **Smarter buttons.**
  - Heals go to whoever you hover, else your friendly target, else whoever your enemy is attacking, else you.
  - Fight buttons pick the next enemy after a kill.
  - Openers know Stealth and Prowl.
  - Pet buttons know whether your pet is out, dismissed or dead.
  - Mana gems and Healthstones are made out of combat and used in combat.
  - Interrupts stop your own cast first.
  - Cooldowns that must land first, like Cold Blood, Presence of Mind or Nature's Swiftness, get their own Burst button, so they never block your main attack.
- Every new macro has tips: what each press does and when a new piece joins.
- Macros made by an older Codex still update in place, even when WoW: Forever doesn't load your saved settings.

### external UI

- **The Codex takes on external UI's look.** With external UI installed, the Codex window, the step window, the macro copy box, the level-up banner and the trainer, vendor, crafting and talent cards use its window frame, dark panels, close button and page arrows, your accent colour and your UI font. The parchment cards become its dark panels.
- It's on whenever external UI is installed. Turn it off for the Codex in external UI's options (skin settings > Window Skins > Third-Party Addons), or pick Forever (teal) or Codex (gold) in the Codex's Settings > Theme: that pick is kept for as long as external UI is installed.
- Change your accent colour in external UI and the Codex follows straight away.

### Party play

- **Your whole party in the step window.** Everyone in your party gets a row: on your step (with their kill or loot count), how many of your steps ahead or behind they are, in another guide, offline, or not sharing a step. The heading says when you're all on the same step, and the compact step window sums it up in one line. Party members need the Codex to share their step.
- **Quests > Party.** A card for each party member with their guide, their step, their live count and when you last heard from them. When you're in different guides, Follow their guide switches yours in one click.
- **Quests one of you is missing.** The Party tab lists the guide quests a party member has that you don't, with Ask to share (their Codex offers it to you), and the ones you have that they don't, with Share.
- **Quest sharing is on by default.** A guide quest you accept is offered to party members who don't have it yet. It waits a moment, so two of you taking it together don't get each other's offer. Turn it off in Settings > Party.
- **Catch-up cues.** The step window says when someone is 3 or more steps behind you, and a soft chime plays when the last of you reaches the same step. Settings > Party > Ping sound picks the sound (Soft chime, Party invite or Ready check) and plays it so you can hear it.
- **Party chat lines, like quest tracker's.** Optional lines in party chat for the steps you finish, the quest items you pick up (with your count), finished objectives and quests that are ready to turn in. At most one a second, never in a raid, and what quest tracker already says in party chat is left to it. Each one is off until you turn it on.
- **Every party option in the guide setup card**, next to the same switches in Settings > Party and Quests > Party.
- **Steadier sync.** Your step goes out again every minute, so a long kill step no longer drops you from your partner's window, and going Back to look at an earlier step no longer tells the party you're behind.

## v0.23.1

### Quest guide

- **A smooth arrival bounce.** When you reach a step, the arrow turns into the step's icon and bobs. It used to jump at the top of every bounce; now it rises and falls in one smooth motion.
- **Sharper step icons.** The pickup !, the turn-in ?, the sword, the loot bag and the flight, hearth, vendor and trainer icons now use the game's own high-resolution art, picked to fit your screen, so they stay crisp from 1080p to 4K. They show on the arrow, in the step window and on the minimap and world map. Hearth and bind steps now show a hearthstone.
- **Smoother glows.** The gold ring around your destination on the flight map pulses smoothly. The arrival ring, the minimap pin's ring and the level-up banner no longer flash as they fade out.

## v0.23.0

### Talents

- **A talent path for every spec.** Besides the Codex guide's own build, every class now has a recommended leveling path for each of its three trees, even the ones that aren't the fastest to level with: Arms and Fury Warriors, Fire and Arcane Mages, Holy and Protection Paladins, Discipline and Holy Priests, and so on. Druids get Feral Cat, Bear tank, Balance and Restoration next to the guide's Feral. They're built from the Forever guides published since launch and checked point by point against the game's own trees.
- **Your own custom path.** Pick Custom, start from any path, from the talents you already have, or from nothing, and click the tree to place each point in level order. The Codex checks the game's rules as you go (points per row, prerequisites, ranks) and says why a talent isn't open yet. Undo and Clear are a click away.
- **Share codes.** Copy your custom path as a short code and paste it on another character, or back in if you ever lose it.
- **A new Talents tab.** Path cards at the top with each path's role and its split at 60, then the full game tree for all three trees side by side with your path filled in to the level you're viewing, prerequisite lines and every point in order. Click a talent for its tooltip and every point your path puts into it.
- **Everything follows your path.** This Level, the level-up banner and chat line, the minimap tooltip and the outline in your talent window all show your path's point. The trainer list follows it too: an Arms Warrior sees Mortal Strike ranks instead of Shield Slam. Macros and tips stay with the Codex guide.
- **Remembered per character.** Your choice is saved. If WoW: Forever doesn't load your saved settings, the Codex picks the path that the talents you've already spent follow.

### Horde quest guide

- **Smoother loops from 30 to 60.**
  - The Horde route was checked chapter by chapter for back-and-forth walking.
  - Gadgetzan, Booty Bay, Silithus's Cenarion Hold and the Riverglades' ring fights are each one sweep now.
  - Pickups you used to come back for are taken on the first visit: Enemies in the Water, Thundering Hearts, Super Sticky, Nafien's quest in Felwood.
- **Quests the guide missed.**
  - Stranglethorn's hunting quests and Weed Whacked, The Severed Head, Sunken Treasure, News for Fizzle.
  - Noggenfogger Elixir, Fuel for the Zapping, Locked Away, the Jeremiah chain in the Plaguelands, the Riverglades side quests.
  - A few quests started by items you find.
- **Cozy Sleeping Bag for the Horde.** A new special guide for the chain that ends with the sleeping bag (up to 3% bonus XP): it starts at the burned watchtower south of Camp Taurajo. The Camp Taurajo chapter offers it.
- **Ruins of Lordaeron.** The New Plague is only offered after Apothecary Renferrel's three-part A Recipe For Death, so the dungeon guide now runs that chain first.
- **Buy it before you go.**
  - Quests that need a bought item say so at the step before the trip: the Southshore Stout that gets you past the Syndicate in Strahnbrad, the Blasted Lands reagents, Gorilla Fangs, Silk Cloth, the Mithril Casing, Gregan's bait.
  - Auction House items are optional steps.
- **Dungeons at the right moment.**
  - Zul'Farrak, Krol'dok, City of Dalaran, Razorfen Downs, Sunken Temple, Scholomance, Stratholme and Upper Blackrock Spire are offered at the steps that lead into them.
  - The Scholomance key guide works with Thunder Bluff's call to arms too.
- Elite quests ask first (see Elite quests below): King Bangalash, Gorlash, the Bloodsail captains, the Swamp Talker, Vile Priestess Hexx, Hitah'ya the Keeper, Overseer Maltorius, Marez Cowl and Or'Kalar.
- Class objectives on the route sit where they add the least walking.
- The quest log stays at 20 or fewer with every dungeon planned.

### Alliance quest guide

- **Smoother loops from 1 to 60.**
  - The whole Alliance route was checked chapter by chapter for back-and-forth walking, like the Horde's.
  - Fixed: Brother Anton in Nijel's Point, the troll tablets in Stranglethorn, the Badlands buzzards and the Sign of the Earth, Torwa's chain in Un'Goro, the Slag Pit in the Searing Gorge, Silithus in one sweep (Bronzebeard's Encampment once), Deadwood of the North and Salfa in Felwood, Are We There, Yeti? in Winterspring.
  - A Refuge Pointe to Southshore flight replaces a long ride; Felwood starts with a hearth to Ironforge.
- **Chains that never showed now work.** Stranglethorn's Nesingwary hunts, Colonel Kurzen, Troll Witchery, Ansirem's Key, Sunken Treasure, ... and Bugs, Goblin Sponsorship and Rhapsody's Kalimdor Kocktail had hand-ins in the forties but no pickup. The thirties now give them. Reassignment is handed in at Stormwind Keep instead of riding in your log to 60.
- **Riverglades fixes.** Several quests came in an order the game doesn't offer them in; the Riverglades chapters now follow the game's chains, with corrected spots and the shopping steps.
- **Quests the guide missed.** Supply and Demand and Some Assembly Required, Hemet Nesingwary, Talk of the Town, This Light of Mine, Crystal in the Mountains, Anyone Can Cook, Parts for Kravel, Sword in the Slime, Stranglethorn Fever, the Talrendis Point quests, Alien Ecology, Lost!, Chasing A-Me 01, Better Late Than Never, Chillwind Horns, Locked Away, Are We There, Yeti? part 3 and more in Silithus.
- **Dungeon guides:** Power Stones (Uldaman), The Ancient Egg and The God Hakkar (Sunken Temple), A Taste of Flame (Blackrock Depths), The Argent Hold (Stratholme), Gnome Improvement (Gnomeregan) and Return to the Hinterlands (Zul'Farrak). Steps that lead into a dungeon offer its guide.
- **Buy it before you go.** Stormwind Seasoning Herbs for Chef Grual, Hillman's Cloak, water breathing, a Moonsteel Broadsword, Silk Cloth, the bloodmage parts, the Mithril Casing, Gregan's bait and more say where to get them before the trip.
- **Class objectives on the route** for Warriors, Mages, Warlocks, Hunters, Priests and Rogues from 36 to 57 (Cyclonian's tusks, the Desolace orbs, the Blasted Lands and Azshara quests, the Ichor of Undeath), shown only to that class while the quest is in your log. Three early ones moved to where they cost the least walking.
- The quest log stays at 20 or fewer with every dungeon planned.

### Elite quests (both factions)

- **The guide asks before an elite quest.** When the route reaches the pickup of a quest whose target is an elite, the step window says so and asks: **Take it** keeps the quest on your route, **Skip** passes it and the quests that need it. Back asks again.
- The Quests tab's Step view has the same Take it and Skip it buttons, for controller players.
- Your choice is kept for your character. If WoW: Forever doesn't load your saved settings, the guide just asks again.
- **Settings > Elite quests** (also on the guide setup card): Ask (the default), Always take or Always skip.
- A quest already in your log is never asked about.
- Alliance elite quests include Hogger, Vagash, Oakenscowl, Stonewatch Keep's Tharil'zun and Gath'Ilzogg, Morbent Fel, Mor'Ladim, Fozruk, Colonel Kurzen, King Bangalash, King Mukla, Overseer Maltorius, the black dragonkin of the Burning Steppes and High Chief Winterfall.

### Step window

- **See up to 10 steps ahead.** Up next can now list up to 10 of the next steps (it was 5), and it carries on into the next guide, naming it where it starts. Before, it stopped at the end of the current guide. Pick 2, 5 or 10 on the setup card's new Steps ahead row, or any number from 0 to 10 in Settings > Steps shown ahead. The default is still 2.
- **It shows up on a new character.** The intro cinematic (and Alt+Z) hides the game's interface. The step window took that as you closing it and stayed hidden until you showed it in the Quests tab; it now comes back with the interface.
- **NPC portraits load.** A portrait used to give up after one second and show the step's icon (a "?") when the game hadn't loaded that NPC yet. It now keeps trying and shows the NPC once it loads, and targeting the NPC shows it at once.
- "Also on this loop" is now **While you're here**.

### Minimap button

- **Left-click** opens or closes the Codex. **Right-click** shows or hides the step window (Settings is a tab in the Codex). The addon compartment entry works the same way.

### Quests tab

- A fresh character no longer sees a few percent on guides it hasn't started. Forever lists flight points as already known, and those flight path steps counted as done. A guide now counts nothing until you've done one of its quests.

### Quest rewards

- **The best-selling reward waits for slow prices.** When the game hadn't loaded a reward's price yet, the Codex gave up on it after a second and a half, so the coin could land on a cheaper reward. It now waits up to 3 seconds. If a price still hasn't loaded, chat names that reward instead of saying the marked one sells for the most.
- **Ties say so:** "Mail Vest sells for the most (4s 50c), tied with Cloth Gloves."
- Closing the quest window while a price was still loading no longer prints the line afterwards, and opening it again quickly no longer prints it twice.
- `/codex debug` shows what the last reward choice read: each reward's price and which one got the coin.

## v0.22.0

### Step window

- **Colour-coded steps.** Each step shows what it asks of you in a chip before its title, and the title and a stripe down the left take its colour: pickups gold, turn-ins green, kills red, collecting orange, travel blue, dungeons purple. Travel chips say Fly, Flight path, Boat, Hearth or Bind, and a step without a name shows the first sentence of its instructions as its title.
- **Goals you can read at a glance.** Every objective has a bar that fills as you go, and a finished one says "done". The quests you can work on along the way get bars too.
- **Up next with distances.** Each coming step shows its icon and how far away it is ("340 yd"), or its zone when it's elsewhere, and the distance counts down as you move.
- **Turn-in XP.** A turn-in shows the XP it gives ("+2,100 XP") and "levels you up" when it will.
- **NPC portraits.** A small 3D portrait of the quest giver, the NPC you turn in to, or the creature you're hunting sits beside the step's title (Settings > Show the NPC portrait).
- **New buttons.** A wide Next step button in the theme's colour, with small Back, Quests and Hide buttons around it.
- **Made for smaller screens.** Shrink the window to as little as 50% (Settings, the guide setup card, or Ctrl+mouse wheel over the window), turn down its background, let it fade while you fight (the mouse over it brings it back), or switch to compact mode with the button in its corner: just the step, its count or distance, a progress bar and the buttons.
- **Progress you can feel.** A completion bar under the step counts the guide's steps (hover it for the quests turned in too), a goal that moves on flashes, and a step the game finishes glows and plays a sound.

### Arrow, minimap and world map

- **An arrow that says you're on course.** It turns green as you head for the step, stays gold with the step off to your side and goes red when it's behind you (Settings > Colour the arrow by direction).
- **Move the arrow anywhere.** Drag it, Ctrl+mouse wheel over it to resize it, or lock it; when you arrive, the step's icon bobs over a gold ring.
- **The route on your minimap.** Pins for the current and next two steps, a dotted line from you to the step that bends through tunnels and caves, an arrow on the rim when the step is off the minimap (it steps aside for the game's own waypoint arrow), and tooltips on hover.
- **The route on your world map.** Numbered pins for the current and next steps that keep their size as you zoom, and a dotted line from you to the step (on or off in Settings and the guide setup).
- The map pin keeps following your steps after a /reload.

### Quests tab

- **A new layout.** The current step sits at the top with its buttons, and the rest is split into Route, Step, Guides and Quest log.
- **A clearer guide setup.** Choices light up when they're on: pace, dungeons, the automation helpers, the map lines, the step window's size and compact mode, and the vendor helpers.
- **Guides as quest-log rows.** Each guide shows a progress bar and one tag (Current, Suggested, Side, Later, Done, Outleveled), and level bands fold away.
- **What you get.** Special chains and class quests say what they give you, from the Cozy Sleeping Bag's bonus XP to the attunements and the class spells.
- A dungeon run you finished before its guide could see you enter no longer leaves the guide stuck on its entry step.

### Level-up banner

- The level-up banner always closes by itself after 8 seconds, even with the cursor on it. With a controller the hidden cursor sits in the middle of the screen, so the banner used to stay up.

### Vendors

- **Junk and repairs.** At a vendor the Codex sells your grey items (never quest items or the Hearthstone) and repairs with your own money. Both can be turned off in Settings or the guide setup; hold Alt as you open the vendor to skip them once.
- **A shopping card.** When a coming step needs something this vendor sells, a card lists it with one Buy button.
- Selling and repairing now wait for the vendor window: in Forever it opens a moment after the vendor does, and the Codex used to give up before its first sale, so nothing was sold or repaired. `/codex debug` says what the last vendor visit did.
- Grey items now sell: the Codex read item prices the old way, which Forever doesn't answer, so no grey had a price. The same fix brings back the coin on the best-selling quest reward and your bag items in the Enchanting tab's disenchanting list.

### Stats and pace

- **A Stats tab.** Headline tiles, your level splits as bars, gold earned and spent by source, activity and zones, for this session or for the character.
- **Pace you can trust.** The This Level card reads your saved stats, so a /reload keeps the level's time and counts, with an XP bar showing your rested XP and your last levels. Kills are counted in every client language.

### Routes

- **Duskwood:** Seasoned Wolf Kabobs now shows on the Ira's Dagger hunt and in the spider woods, where its wolf flanks also drop.

## v0.21.1

### Alliance quest guide, levels 30-60

- **The route now runs to 60.** About 35 new leveling guides follow on from the Wetlands:
  - **30-40:** Darkshire, Southshore and Alterac, Refuge Pointe, Theramore and the Shimmering Flats, Desolace, Stranglethorn, the Swamp of Sorrows, Arathi and Aerie Peak, then Dustwallow.
  - **40-50:** Desolace again, the Badlands, Stranglethorn and the Swamp, Tanaris, Feralas, the Hinterlands and Un'Goro.
  - **50-60:** Booty Bay, the Searing Gorge, the Blasted Lands, the Plaguelands, Felwood, Feralas, Azshara, Un'Goro, Winterspring and the Burning Steppes, ending in Silithus and Moonglade.
- **Alternate routes for every level.** Each level from 30 to 60 has at least three guides to choose from. They include Forever's **Riverglades** (Farholde Keep, then Sunnyglade and the Twilight's Shroud), **Shen'dralas**, early Stranglethorn, Theramore, the Searing Gorge, the Blasted Lands, Azshara, Winterspring and Silithus.
- **Dungeon checklists for 30-60.** Each dungeon from the Scarlet Monastery to Stratholme has a checklist, including Forever's Krol'dok Stronghold.
- **Class quests 30-60.** These include the Warrior Whirlwind weapon, the Paladin Tome of Nobility, the Warlock Felsteed and Orb of Orahil, Mage Celestial Power, and each class's Sunken Temple chain. Each dungeon checklist recommends itself to the classes whose chains need it.
- **Attunement guides.** New guides cover the Drakefire Amulet (Onyxia), the Seal of Ascension (Upper Blackrock Spire), Attunement to the Core, the Key to Scholomance and the Shadowforge Key.
- **Item notes.** Steps say what to buy and where: Soothing Spices, Elixir of Water Breathing, Thorium Bars and Fine Thread. They also say what to get from a crafter or the Auction House.
- **Quest log clean-up.** At 30 and again in Booty Bay, the guide reminds you to drop grey dungeon quests you never ran.
- The Quests tab now splits 30-60 into three level bands: 30-40, 40-50 and 50-60.

### Horde quest guide, levels 30-60

- **The Horde route now runs to 60.** 27 new leveling guides follow on from Thousand Needles:
  - **30-40:** Tarren Mill, Alterac and Hammerfall, the Shimmering Flats, Desolace, Grom'gol and Nesingwary, Brackenwall Village, Alterac and Arathi again, then Kargath.
  - **40-50:** Grom'gol, Stonard, Desolace, Gadgetzan and Brackenwall, Camp Mojache, Booty Bay and the southern jungle, the Swamp of Sorrows, Lost Rigger Cove, Revantusk Village, then Feralas and Un'Goro.
  - **50-60:** the Blasted Lands, the Searing Gorge and Burning Steppes, Azshara, Felwood, Un'Goro, Winterspring, the Plaguelands (the Bulwark, Tirion Fordring, Darrowshire and Northdale), then Moonglade and Silithus, ending with Calm Before the Storm in Orgrimmar.
- **Alternate routes for every level.** Each level from 30 to 60 has at least three guides to choose from, the main route included. The alternates include early Stranglethorn, Desolace or Dustwallow, the Badlands before Arathi, the Searing Gorge, the Blasted Lands and Un'Goro in the late 40s, and other orders through the 50s. Forever's **Riverglades** has three Horde routes from **Rog'mar**: the Plains, Bolder'ok and the Twilight's Shroud, and the Eastsea pirates out of Powderfuse Port. There is also a route through **Shen'dralas**. Each guide suggests where to go next.
- **Horde dungeon guides for 30-60.** Every dungeon from Gnomeregan to Stratholme has a Horde guide with Horde quests and travel, before, inside and after the run. That includes Forever's Excavation Site, City of Dalaran and Krol'dok Stronghold. Uldaman is two runs, because Jarkal hands out the gem quest in between. The Horde reaches Gnomeregan through Scooty's transporter in Booty Bay.
- **Horde attunements.** New guides cover Onyxia (from Warlord's Command to Blood of the Black Dragon Champion), the Seal of Ascension, Attunement to the Core, the Shadowforge Key and the Key to Scholomance.
- **Horde class quests 30-60.** These include the Whirlwind weapon, Celestial Power, the Felsteed, the Orb of Orahil and Kroshius, Forever's shaman weapon chain (The Tempest's Weapons), Da Voodoo, and every class's Sunken Temple chain. Where the route already passes a class objective, such as the Bloodscalp tusks, the Twisted Totems or the Azshara errands, your class gets a step for it while the quest is in your log.
- **Quest log clean-up.** At 30, 46 and 48 the guide reminds you to drop grey dungeon quests you never ran.

### Leveling guides 1-30

- **Fewer trips back and forth.** Every leveling guide from 1 to 30, Alliance and Horde, was checked for pickups taken only after you had walked past their objectives, and for hubs visited twice when once would do. Kharanos, Auberdine, Darnassus, Menethil Harbor, Lakeshire, Thunder Bluff, northern Durotar and the Sepulcher are now single passes. Darnassus alone drops from about 3,800 to 1,700 yards of walking.
- **Quests the guides missed.** About 25 quests are now on the route, among them Uncovering the Past and Ormer's second hunt at the Wetlands dig, Daily Delivery, Report to Ironforge, One Shot. One Kill., Gerenzo's Orders, Stop the Spread, A New Ore Sample, The Weathered Grave, Traditions of the Bluff, and the Camping 101 gathering lessons. Group quests such as Chol'aruk and the Goaz Warder are optional.
- **The Wetlands dig in one visit.** In the 20-25 Wetlands guide, Prospector Whelgar's Uncovering the Past is taken when you arrive, next to Merrin, and the fragments you pass on the way to the raptors count. Ormer's second hunt and the rest of the fragments share the dig.

### Step window

- **A cleaner step window.** Quest objectives are now a checklist under the step's instructions, each on its own line with its count on the right ("Mottled Raptor slain ... 2/10"); the count turns gold once you've started and a finished goal gets a green tick. Quests you can work on during the same trip sit under **ALSO ON THIS LOOP**, goals the route passed under **ON THE WAY**, and the next steps under **UP NEXT**, each with its own heading. A quest's place in its chain sits under the step's name, and warnings (full quest log, level too low, elites nearby) stand out in their own colours. The Quests tab's step card lists one objective per line too.

### Fixes

- **Eastern Plaguelands positions.** Forever redrew the Eastern Plaguelands map. The arrow pointed at the old spots for Tirion Fordring's hut, the Symbol of Lost Honor in Northdale and the Stratholme gate.
- **Krol'dok Stronghold.** Entering it now opens its guide, and each boss is checked off when it dies.
- A level 28 entering a zone that has a later chapter (Duskwood at 30, Hillsbrad at 30) no longer jumps into that chapter past the route's own next guide.
- **Fly steps finished too early.** In many Horde guides and in the new 30-60 guides, a "Fly to" step counted as done as soon as you reached the flight master you leave from, so the flight map didn't mark the flight and auto-fly didn't take it. Every Fly step now stays current until you land.
- **The 26-30 Wetlands guide after the 20-25 one** listed Howin's quests, Blisters on the Land, War Banners and more under Missed quests and sent you to Stormwind. It now starts at Howin.
- **Assessing the Threat** in Redridge pointed at a camp with no Poachers. It now points at the south camp.
- **Silverpine:** Wild Hearts and Wild Eyes had no hunting step, so the guide sent you to the turn-in empty-handed. Ivar the Foul now waits for Return to Quinn (Again).
- **Moonglade (Alliance):** the guide named the druid-only flight point at Sindrayl instead of the Moonglade one.

## v0.20.1

### Quest guide

- **The flight map lights up the guide's flight master.** When you open a flight map, the flight point to fly to turns yellow inside a pulsing gold ring, instead of having the Codex badge beside it, and the line at the top still names it. Click it as usual.
- **Auto-fly is easier to find.** The travel automation setting is now Settings > **Auto-fly: take the guide's flights and binds** (the guide setup's **Auto-fly and bind**). It is still off by default.

### Fixes

- **The flight map marks the flight the arrow names.** When the arrow said "Fly to" a zone's flight hub, such as Menethil Harbor from Ironforge for Ironbeard's Tomb, the flight map marked nothing and auto-fly didn't fly: the trip planner measures walks as a straight line, over mountains too, and only its own trips were marked. The hub's flight now lights up, and auto-fly takes it.
- **No more "LevelingCodex has been blocked from an action only available to the Blizzard UI".** For the dungeon boss steps the Codex switched the combat log on or off at every loading screen and zone change: logging in, a /reload, flying over a zone border, being sent to a graveyard. WoW: Forever doesn't let addons touch the combat log, so the game blocked it every time. Bosses now tick off from the game's encounter events only, and a rare without one is passed with Next.
- **Binds are yours to accept.** With Settings > Auto-fly: take the guide's flights and binds on, the Codex still picks the innkeeper's bind option, and you accept the game's popup. Accepting or closing a game popup from an addon risks the same block.
- **Trip planning when your speed is hidden.** The trip planner read your speed, which WoW: Forever sometimes hides from addons, and failed every moment it was hidden (a Lua error in the background). It now plans at walking speed when your speed is hidden.
- The key bindings no longer log "Binding header LEVELINGCODEX was attempted to be loaded more than once" at every login and /reload.
- **If the game ever blocks the Codex again**, the Codex says in chat which part of it was blocked, and /codex debug lists it, so it can be fixed quickly.

## v0.20.0

### Quest guide: flights and dungeons

- **Trips through flight masters.** For a long trip the arrow now leads to a flight master when flying is quicker, for example "Fly to Lakeshire from Sentinel Hill" with the distance to the flight master, and "talk to the flight master" once you're there. It only uses flight paths you have, and it works inside one zone too, such as Crossroads to Ratchet.
- **The flight map marks the guide's flight.** When you open a flight map, the Codex badge sits on the flight to take and a line names it. With Settings > Take the guide's flights and binds on, the Codex takes that flight for you (Alt holds it back), not only on Fly steps.
- **Flight paths you don't have.** If the flight master closest to you is one you haven't talked to, the arrow says to learn that flight path and fly on. A flight master you don't have close to the way is visited first so you pick up the flight path (Settings > Lead me to flight paths I don't have). This starts once the game has listed your flight paths, or after you open a flight map.
- **Nearest flight master.** Quests > **Nearest flight master** points the arrow at the closest one, until you open a flight map or press **Back to the step**.
- **Dungeon ahead.** Dungeon quests no longer hide behind a setting. Before the first quest of a dungeon run, the route stops at a Dungeon ahead step: the run's levels, how many quests on your route need it, and whether it's recommended for you. **Plan** (for example **Plan The Deadmines**) adds the run and its quests to your route; **Skip** leaves the run out. Back returns to the choice, and Quests > Guide library > Dungeons can still change it. The Quests tab has both buttons for controllers.
- **Find a group.** When a planned run is ready, the step text starts with "Find a group for" and the dungeon's name until you go.
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

### quest tracker compatibility

- **Works side by side with quest tracker.** While quest tracker's own auto-accept or auto-complete is on, the Codex leaves those quests to quest tracker, so the two never pick different quests from one NPC. Settings says so under each tickbox.
- **One key holds both back.** quest tracker's key (Shift by default) now stops the Codex's auto-accept and auto-turn-in too. Alt now also stops the quest window, not just the NPC's list.
- **The step window sits beside external quest tracker** until you drag it somewhere, on the side facing the middle of the screen, and follows the tracker when you move it.
- **Last-mile arrow with quest database.** With quest database installed (quest tracker needs it), the arrow leads to the nearest mob or object you still need once you reach a kill or collect step's camp, for example "Kobold Vermin - 42 yd". Items lead to whatever drops them. Turn it off in Settings > Point the arrow at the nearest objective (quest database).
- **The last-mile arrow skips a spawn you just cleared** for 90 seconds, so it leads on to the next mob instead of back to an empty spot. It also works on clients in other languages, keeps the arrow on screen when the step window sits high, and checks quest database once more if it wasn't ready at login.

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
- **Dungeon plans.** In Quests > Guide library > Dungeons, plan your runs one by one, or use Plan recommended / all / none. A planned run's quest pickups join your route. When its pickups are done at the right level, the step window and the Quests tab offer **Run** with the dungeon's name (for example **Run The Deadmines**), and chat says to find a group. Each dungeon page lists its **bosses in order** with a short tip. The Stockade checklist now continues with the Stormwind chain to King Varian.
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
