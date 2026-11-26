-- The Leveling Codex: the storybook's wider voice (J.story). More for a chapter to notice and more ways to say it,
-- in the three narrators (Chronicler, Fireside, Bard): the weather and mood of a land, milestone levels, how a
-- level ended (the hour and place of the next level, or the quest that brought it), returns after a break,
-- streaks and comebacks, firsts of the whole journal, named dungeons, wipes turned to victories, battlegrounds
-- and duels, trades, guilds and kindness, professions, the purse, the kind of quests a chapter was made of,
-- weekends and evenings, sittings and marathons. Lines are ASCII and our own words.
-- JourneyVoice.lua tells every chapter pool one line per level (Vo.tell), so neighbouring chapters never share
-- a sentence; this file only adds lines, pools and noticers (Vo.noticers), and the joining words.
local _, ns = ...
local J = ns.journey
local Vo = J and J.voice
if not Vo then return end
local St = {}
J.story = St

local function say(n) return J.lore.say(n) end
local function capital(s) return (tostring(s or ""):gsub("^%l", string.upper)) end
local function hashOf(s) return Vo.hashOf(s) end
local function roman(l) return J.draw and J.draw.roman and J.draw.roman(l) or tostring(l) end
local function recordOf(l) return ns.stats and ns.stats.levelRecord and ns.stats.levelRecord(l) or nil end
local function words(n, one, many)
  n = tonumber(n) or 0
  return say(n) .. " " .. (n == 1 and one or (many or (one .. "s")))
end
local ORD = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth" }
local function ordinal(n) return ORD[n] or (tostring(n) .. "th") end

-- Level lines (Journey.lua) turn with the level too, so 35 and 36 never read alike.
function J.rotate(list, key, n)
  if type(list) ~= "table" or #list == 0 then return nil end
  return list[(hashOf(key) + math.floor(tonumber(n) or 0) * 7) % #list + 1]
end

----------------------------------------------------------------------------
-- More lines for the pools JourneyVoice.lua already has
----------------------------------------------------------------------------
local MORE_L = {
  newLand = {
    chronicle = { "%a% is first named in this chapter, when %name% crossed its border.",
      "Of %a% the record had nothing to say until now.", "The road brought %name% to %a%, unvisited until this day.",
      "This chapter marks the first entry of %name% into %a%." },
    fireside = { "%a% was new to you, and you were new to %a%.", "You'd heard about %a%. Now you got to see it.",
      "New land, %a%, and the first hour was mostly staring.", "You got to %a% and the map had a whole new corner.",
      "%a%. You didn't know a single road, and that was half the fun.", "Somebody pointed and said %a%, and off you went." },
    bard = { "Now sing of %a%, where no song of yours had gone.", "%a% unrolled like a new page of the world.",
      "Strange hills, strange stars: this was %a%.", "The wind changed, and it smelled of %a%.",
      "A new land, %a%, took you in without a word." } },
  backLand = {
    chronicle = { "%a% appears again, as it did in chapter %r%.", "The record returns to %a% once more; chapter %r% first told of it.",
      "Again %name% walked in %a%, a land known since chapter %r%." },
    fireside = { "%a%, again. You knew the shortcuts this time.", "Back in %a%, where chapter %r% had left you.",
      "Remember %a% from chapter %r%? Well, you went back.", "Old ground: %a%. It felt smaller now." },
    bard = { "%a% remembered you from chapter %r%, and opened its gates.", "The old roads of %a% knew your step.",
      "Back to %a%, where an earlier verse was sung." } },
  oneLand = {
    chronicle = { "Every entry of this chapter is set in %a%.", "%a% alone is the stage of this chapter.",
      "No other land is named in this chapter but %a%.", "For all of this chapter, %name% kept to %a%." },
    fireside = { "%a%, all of it. You could draw the map from memory by the end.", "You stayed put in %a% and worked it over.",
      "%a% had more to give, so you stayed.", "You never even looked at the flight master. %a% was enough.",
      "All in %a%. Every hill, every camp, every road." },
    bard = { "%a% was the whole of the world this verse.", "One land held you fast: %a%.", "In %a% the verse began and ended.",
      "No border crossed; %a% kept you close." } },
  manyLands = {
    chronicle = { "This chapter ranges over %n% lands, from %a% at its start to %b% at its close.",
      "%name% passed through %n% lands, the first %a% and the last %b%." },
    fireside = { "%a% to %b%, with %n% lands all told. Did you even unpack?", "You were all over the place: %n% lands, %a% first, %b% last.",
      "%N% lands. The flight masters were sick of you." },
    bard = { "Through %n% lands the verse runs, %a% to %b%.", "Many lands, one road: %a%, and on to %b%." } },
  work = {
    chronicle = { "%Q% %qv% completed; %f% fell.", "The labours of the chapter: %q%, and %f% overcome.",
      "%name% answered %q% and fought %f%.", "Recorded: %q% finished, %f% slain." },
    fireside = { "%Q% done, %f% dealt with, and the kettle on.", "Work, work: %q% and %f%.",
      "You handed in %q% and fought through %f% to do it.", "%Q% and %f%. Not bad for one level.",
      "The usual: %q%, %f%, and a lot of walking in between." },
    bard = { "%Q% done and %f% undone.", "Of tasks, %q%; of foes, %f%; of rest, but little.",
      "%Q% answered, %f% fallen to the blade." } },
  workLight = {
    chronicle = { "A light chapter for labour: %q%, %f%.", "Little work is recorded: %q% and %f%." },
    fireside = { "Not a lot of work this time: %q% and %f%.", "You took it easy. %Q%, %f%, and a lot of looking at the view." },
    bard = { "A gentle verse of work: %q% and %f%.", "Few the tasks and few the foes: %q%, %f%." } },
  workHeavy = {
    chronicle = { "The chapter is crowded with deeds: %q% and %f%.", "Few chapters record so much: %q% and %f%." },
    fireside = { "You worked yourself ragged: %q%, %f%.", "%Q% and %f%. You earned a long sit-down after that.",
      "Busy, busy: %q% and %f% before the level finally came." },
    bard = { "A heavy verse, heavy with deeds: %q% and %f%.", "Sing long, for there is much: %q% and %f%." } },
  questsOnly = {
    chronicle = { "%Q% %qv% completed, with little fighting recorded.", "The chapter is one of tasks: %q%." },
    fireside = { "%Q%, and barely a fight among them.", "Errand after errand: %q%." },
    bard = { "Word and errand carried you: %q%." } },
  foesOnly = {
    chronicle = { "No quests were handed in; %f% were defeated.", "%name% fought, and did little else: %f%." },
    fireside = { "No quests. Just %f% and a sore sword arm.", "%F%. You weren't here to chat." },
    bard = { "No errands, only steel: %f%." } },
  clean = {
    chronicle = { "No death is written in this chapter.", "%name% passed the chapter unharmed by death.",
      "Death finds no place in this chapter." },
    fireside = { "Not a single death. Look at you.", "Zero deaths. Write that one down.",
      "The spirit healer had a quiet week, at least where you were concerned.", "You didn't die once. Not once!" },
    bard = { "Death waited at every turn, and every turn you passed.", "Clean the road, and clean the blade, and no grave.",
      "No mourning in this verse." } },
  oneFall = {
    chronicle = { "Death took %name% once in this chapter.", "A single fall interrupts this chapter." },
    fireside = { "One death. Just the one. It still stings.", "You died once and walked it off." },
    bard = { "One grave, briefly kept.", "The dark touched you once and let go." } },
  falls = {
    chronicle = { "Death took %name% %n% times in this chapter.", "%N% times %name% fell; %n% times the road resumed." },
    fireside = { "%N% deaths. You and the graveyard are on first-name terms.", "You died %n% times. Some days are like that.",
      "%N% times down. Your repair bill wept." },
    bard = { "%N% graves you left behind, and walked on from each.", "%N% times the dark, %n% times the dawn." } },
  quick = {
    chronicle = { "No earlier chapter passed in less time.", "This was the quickest chapter on record." },
    fireside = { "Quickest level yet. Somebody was in a hurry.", "That one flew by. Fastest so far." },
    bard = { "Swift the verse, the swiftest of the song so far." } },
  long = {
    chronicle = { "No earlier chapter took as long as this one.", "The chapter is the longest on record." },
    fireside = { "Longest level yet. You earned every bit of it.", "This one went on forever. Longest so far." },
    bard = { "Long, long the verse, the longest yet." } },
  deep = {
    chronicle = { "In the dungeon, %b% was defeated%w%.", "%name% and companions overcame %b% below%w%." },
    fireside = { "You and the party took down %b%%w%.", "In the dungeon, %b% met you, and lost%w%." },
    bard = { "In halls of stone, %b% fell%w%.", "The deep places gave up %b%%w%." } },
  dark = {
    chronicle = { "%name% entered a dungeon in this chapter.", "A dungeon was visited." },
    fireside = { "There was a dungeon in the middle of it all.", "You poked your head into a dungeon." },
    bard = { "A door into the dark, and you went through." } },
  elite = {
    chronicle = { "%E% was defeated, though it was elite.", "%name% overcame %e%, a foe of great strength." },
    fireside = { "%E% had a gold border and a bad attitude. You won anyway.", "You and %e% had words. Yours were sharper." },
    bard = { "%E%, mighty, fell all the same.", "Proud was %e%, and humbled." } },
  rare = {
    chronicle = { "A rare creature was defeated.", "%name% slew a beast seldom seen." },
    fireside = { "You bagged a rare one. Lucky.", "A rare spawn, right there, and you got it." },
    bard = { "A beast of tavern stories fell to you." } },
  pvp = {
    chronicle = { "%name% fought the other faction in this chapter.", "The war between the factions touched this chapter." },
    fireside = { "You traded blows with the other side.", "The other faction found you. They regretted it, mostly." },
    bard = { "The old war flared, and you were in it.", "Red banners, blue banners, and steel between." } },
  close = {
    chronicle = { "Once, %name% survived with almost no health left.", "There was a fight that %name% very nearly lost." },
    fireside = { "One fight got far too close. You know the one.", "There was a moment your health bar was mostly empty." },
    bard = { "Once the grave yawned wide, and you stepped around it." } },
  pals = {
    chronicle = { "With %name% for part of the road: %p%.", "The record also names %p%, who travelled with %name%." },
    fireside = { "%p% were along for some of it, and it was better for that.", "You had %p% for company." },
    bard = { "With %p% the road was merrier.", "%p% shared the verse." } },
  palsOne = {
    chronicle = { "The record also names %p%, who travelled with %name%.", "%p% was with %name% for a time." },
    fireside = { "%p% tagged along for a bit.", "You and %p%, side by side for a stretch." },
    bard = { "%p% shared the road, and the song was better for it." } },
  rez = {
    chronicle = { "%name% was raised from death by another's spell.", "A healer restored %name% to life." },
    fireside = { "Someone picked you up off the floor. Say thank you.", "A friendly spell saved you the corpse run." },
    bard = { "A stranger's word, and the grey let you go." } },
  gather = {
    chronicle = { "Gathered in this chapter: %g%.", "%name% took from the land %g%." },
    fireside = { "You came back with %g%. Bags getting heavy.", "Plus %g%, picked up between the fights." },
    bard = { "The earth gave %g% to your hands." } },
  fish = {
    chronicle = { "Fishing yielded %f%." },
    fireside = { "You sat by the water a while and caught %f%.", "Line in, line out: %f%." },
    bard = { "The water gave up %f% to your patience." } },
  craft = {
    chronicle = { "There was work at the craftsman's bench.", "A craft was practised in this chapter." },
    fireside = { "You made a few things. Nobody asked, but they're nice.", "There was a bit of crafting, too." },
    bard = { "Busy hands at the bench made something new." } },
  auction = {
    chronicle = { "%name% visited the auction house.", "Trade at the auction house is recorded." },
    fireside = { "You popped into the auction house. Just to look, you said.", "The auction house got some of your time." },
    bard = { "Under the auctioneer's hammer, coin and goods moved." } },
  camp = {
    chronicle = { "%name% rested by a campfire.", "A campfire is recorded in this chapter." },
    fireside = { "A campfire, a sit-down, a bit of quiet.", "You stopped at a fire and let your feet rest." },
    bard = { "Embers and stars, and a quiet hour between." } },
  flight = {
    chronicle = { "A new flight path was learned.", "%name% learned a new road through the air." },
    fireside = { "One more flight master on the map.", "You picked up a new flight path." },
    bard = { "A new road through the clouds." } },
  open = {
    chronicle = { "The chapter continues.", "What follows is not yet recorded.", "The account of this chapter is unfinished." },
    fireside = { "And that's as far as we've got.", "Still going. Come back later for the rest.", "To be continued, as they say." },
    bard = { "The verse is still on the singer's lips.", "The song is not done; listen for the rest." } },
}

local MORE_M = {
  moodHard = {
    chronicle = { "This chapter cost %name% dearly.", "Hardship marks every page of this chapter." },
    fireside = { "This level fought back.", "Honestly? This one was a slog.", "Nothing went easy this level." },
    bard = { "A bitter verse, and a hard one to sing.", "Hard was the road, and harder the stones." } },
  moodBusy = {
    chronicle = { "This chapter is full of deeds.", "Industry defines this chapter." },
    fireside = { "No rest for the wicked, or for you.", "A to-do list of a level.", "You worked through this one like a mule." },
    bard = { "The forge-song of labour rings through this verse." } },
  moodWander = {
    chronicle = { "Travel fills much of this chapter.", "%name% covered much ground in this chapter." },
    fireside = { "Mostly travel, this one. Lots of looking out of the window.", "You went everywhere this level." },
    bard = { "The far roads called, and you answered.", "Wandering feet, wandering song." } },
  moodDeep = {
    chronicle = { "Much of this chapter passed beneath the earth.", "Dungeon stone defined this chapter." },
    fireside = { "You spent half this level in the dark with a party.", "A dungeon level: lots of torches, lots of loot." },
    bard = { "Under the roots of the mountains the verse is sung.", "Down where the sun is a rumour, this verse." } },
  moodCompany = {
    chronicle = { "Others shared much of this chapter.", "%name% walked in company for much of this chapter." },
    fireside = { "Good company this time.", "You weren't on your own, and it showed." },
    bard = { "Many feet on the road, and many voices.", "A chorus, this verse, not a solo." } },
  moodQuiet = {
    chronicle = { "Little of note troubled this chapter.", "A calm chapter." },
    fireside = { "Peaceful, this level. Enjoy it while it lasts.", "Nothing tried too hard to kill you this time." },
    bard = { "A still verse, a breath between.", "Soft the wind, and soft the song." } },
  moodSwift = {
    chronicle = { "The chapter was soon over.", "Few pages were needed for this chapter." },
    fireside = { "Quick one, this.", "That level barely touched the sides." },
    bard = { "Brief and bright as a spark." } },
  titles = {
    chronicle = { "The chapter's quests include %t%.", "Among the quests completed: %t%." },
    fireside = { "There was %t%, which you won't forget.", "%T%: those were this level's." },
    bard = { "%T%: tasks worth a line in the song." } },
  chainDone = {
    chronicle = { "The chain of quests named %t% was brought to its end." },
    fireside = { "Finally finished %t%. That one went on.", "%t%, all the way to the last page." },
    bard = { "The long tale of %t% was sung to its close." } },
  byQuests = {
    chronicle = { "Quests earned most of this level.", "The level was earned mostly through tasks completed." },
    fireside = { "Quest rewards did the heavy lifting this time." },
    bard = { "By errand and by promise this level was won." } },
  byKills = {
    chronicle = { "Combat earned most of this level." },
    fireside = { "You fought your way up this one. Literally.", "Mostly grinding. Mostly." },
    bard = { "Blade by blade this level was earned." } },
  rested = {
    chronicle = { "Rested experience carried much of this level." },
    fireside = { "All that time in the inn paid off.", "Rested bonus. The comfiest kind of experience." },
    bard = { "The rest of earlier days gave wings to this one." } },
  richer = {
    chronicle = { "%name% gained %m% over the chapter.", "The chapter left %name% %m% the richer." },
    fireside = { "%M% up on the level. Nice.", "You made %m% this level. Don't spend it all on repairs." },
    bard = { "The purse sang a heavier tune: %m%." } },
  poorer = {
    chronicle = { "The purse of %name% fell by %m%." },
    fireside = { "%m% gone, between training and repairs.", "Down %m%. Training isn't cheap." },
    bard = { "Coin flowed out like water: %m%." } },
  killer = {
    chronicle = { "%who% is recorded as the slayer of %name% in this chapter." },
    fireside = { "%who% got you. Remember that face.", "You fell to %who%. It won't happen twice. Probably." },
    bard = { "By %who% you fell, and the verse names them." } },
  killers = {
    chronicle = { "Those who slew %name%: %who%." },
    fireside = { "%who% all took turns at you.", "Your list of grudges grew: %who%." },
    bard = { "Their names are sung in anger: %who%." } },
  closeWho = {
    chronicle = { "%who% nearly ended %name%, at %pct% health." },
    fireside = { "%who% had you on %pct% health. Your heart's still racing.", "%pct% health against %who%. Too close." },
    bard = { "Against %who% you hung by %pct%, and held." } },
  rareWho = {
    chronicle = { "%who%, a rare creature, fell to %name%." },
    fireside = { "%who% showed up, and you got it. Rare ones are a treat." },
    bard = { "%who% came out of legend, and went into the ground." } },
  night = {
    chronicle = { "Most of this chapter took place in the small hours." },
    fireside = { "Late nights, this level. The candle burned low.", "You played this one when sensible folk were asleep." },
    bard = { "By moon and lamp this verse was sung." } },
  morning = {
    chronicle = { "Most of this chapter took place in the early morning." },
    fireside = { "Early mornings, this level. Before the coffee, even." },
    bard = { "The dawn chorus sang along with this verse." } },
  oneSitting = {
    chronicle = { "This chapter was completed in one day." },
    fireside = { "One sitting, one level.", "All in a day's work, literally." },
    bard = { "Between one dawn and the next, the verse was done." } },
  manyDays = {
    chronicle = { "This chapter spans %n% days." },
    fireside = { "It took %n% days to get through this one.", "%N% days, on and off." },
    bard = { "Over %n% days the verse was woven." } },
  faster = {
    chronicle = { "This chapter was %d% shorter than the one before." },
    fireside = { "You shaved %d% off the last level.", "Quicker than the last, by %d%." },
    bard = { "Faster than before by %d%." } },
  slower = {
    chronicle = { "This chapter was %d% longer than the one before." },
    fireside = { "This one took %d% longer than the last. No hurry.", "%D% more than the level before." },
    bard = { "Slower than before by %d%, and none the worse." } },
  firstFind = {
    chronicle = { "%S%: a first for %name%." },
    fireside = { "%S%. First time for everything." },
    bard = { "%S%, and the first of its kind." } },
  upgrade = {
    chronicle = { "%S%, an improvement." },
    fireside = { "%S%. Looking sharp.", "%S%, and about time too." },
    bard = { "%S%, and the gear shone." } },
  upgrades = {
    chronicle = { "%N% pieces of equipment were improved." },
    fireside = { "%N% new bits of kit. Practically a new wardrobe." },
    bard = { "%N% times new steel replaced the old." } },
  home = {
    chronicle = { "%S%, and the hearthstone was set there." },
    fireside = { "%S%. Home is where the hearthstone is." },
    bard = { "%S%, a new hearth for the weary." } },
  milestone = {
    chronicle = { "%S%, a mark worth recording." },
    fireside = { "%S%. Raise a mug." },
    bard = { "%S%, a stone set upon the road." } },
  abandon = {
    chronicle = { "%name% left %q% unfinished." },
    fireside = { "%Q% went in the bin. No regrets.", "You dropped %q%. Life's too short." },
    bard = { "%Q% left by the wayside, unsung." } },
  duel = {
    chronicle = { "%N% duels are recorded." },
    fireside = { "%N% duels, just for fun.", "You duelled %n% times. Show-off." },
    bard = { "%N% friendly fights, blades flashing." } },
  bond = {
    chronicle = { "%name% and %who% grew closer." },
    fireside = { "%who% is a real friend now.", "Something like friendship with %who%." },
    bard = { "A bond with %who%, strong as iron." } },
  reunion = {
    chronicle = { "%who% was met again after a long time." },
    fireside = { "Look who it was: %who%, after all this time." },
    bard = { "The road brought %who% back to you." } },
  flights = {
    chronicle = { "The chapter adds %N% flight paths." },
    fireside = { "%N% new flight paths. Your gryphon has a loyalty card now." },
    bard = { "%N% new paths in the sky." } },
}

----------------------------------------------------------------------------
-- New pools
----------------------------------------------------------------------------
local NEW = {
  -- the weather and mood of a land (an opener)
  climSnow = {
    chronicle = { "Snow lay deep over %a% in this chapter.", "The cold of %a% marked this chapter.",
      "In %a%, under snow and hard frost, this chapter was written." },
    fireside = { "%a%: cold enough to freeze your breath on your beard.", "Snow in %a%. Snow everywhere. Snow in your boots.",
      "You spent this one stamping your feet to keep warm in %a%.", "%a%, all white and blue and bitter. You loved it anyway." },
    bard = { "White on white the snows of %a% fell.", "The frost of %a% sang thin and high.",
      "In %a% the wind had teeth, and the snow had no end." } },
  climForest = {
    chronicle = { "This chapter was written under the trees of %a%.", "The woods of %a% surround this chapter." },
    fireside = { "%a%, all green light and birdsong.", "Leaves, roots and a lot of trees: this was %a%.",
      "%a% smelled of pine and wet earth the whole time.", "Rain on the leaves of %a%, most days." },
    bard = { "Green and gold the boughs of %a% bent over the road.", "Under the old trees of %a% the verse is sung.",
      "The woods of %a% whispered as you passed." } },
  climDark = {
    chronicle = { "Gloom hung over %a% throughout this chapter.", "%a% is a dark land, and this is a dark chapter." },
    fireside = { "%a%, where the sun never quite gets up.", "Creepy %a%. Every shadow had teeth.",
      "%a%: grey skies, grey trees, and things howling.", "You kept looking over your shoulder in %a%." },
    bard = { "In %a% the light grows thin, and the shadows long.", "Mist and moaning, %a%, and the moon behind cloud.",
      "Dark is %a%, and darker what walks there." } },
  climPlains = {
    chronicle = { "The open country of %a% is the setting of this chapter.", "Fields and wide skies of %a% fill this chapter." },
    fireside = { "%a%: wind in the grass and sky everywhere.", "Big skies over %a%. You could see trouble coming a mile off.",
      "%a%, fields and fences and far horizons." },
    bard = { "Wide are the fields of %a%, and wide the sky.", "The grass of %a% bowed in the wind as you went." } },
  climDesert = {
    chronicle = { "The heat of %a% weighed on this chapter.", "Sand and sun defined %a% in this chapter." },
    fireside = { "%a%: hot, dry, and sand in places sand shouldn't be.", "You drank a lot of water in %a%.",
      "Sun-baked %a%. Even the vultures looked tired.", "Dust, heat and shimmering air: %a%." },
    bard = { "Under the hammer of the sun lay %a%.", "The dunes of %a% shifted, and the heat sang.",
      "Gold and red the dust of %a% rose." } },
  climSwamp = {
    chronicle = { "Mire and mist covered %a% in this chapter.", "The wet lands of %a% are the setting of this chapter." },
    fireside = { "%a%: damp, muddy, and full of things that bite.", "Fog over %a% every morning. Your boots never dried.",
      "%a% squelched. All of it.", "Mosquitoes the size of sparrows in %a%." },
    bard = { "Grey the waters of %a%, and grey the mist.", "In %a% the reeds whispered and the frogs sang." } },
  climJungle = {
    chronicle = { "The jungle of %a% enclosed this chapter.", "Heat and green growth marked %a% in this chapter." },
    fireside = { "%a%: vines, heat, and something always watching from the leaves.", "Sweaty %a%. Even the trees were sweating.",
      "%a% was loud: birds, bugs, and things that roared." },
    bard = { "Green and wild and close, the jungle of %a%.", "In %a% the drums of the wild beat on." } },
  climFire = {
    chronicle = { "Ash and fire marked %a% in this chapter.", "The burned land of %a% is the setting of this chapter." },
    fireside = { "%a%: hot rocks, red skies and a smell of sulphur.", "Everything in %a% was on fire, or had been.",
      "Ash fell like snow in %a%." },
    bard = { "The sky of %a% burned red, and the ground answered.", "Through fire and cinder, through %a%, you went." } },
  climBlight = {
    chronicle = { "The blight of %a% hangs over this chapter.", "%a% is sick, and this chapter was written in it." },
    fireside = { "%a%: sick trees, foul water, and the dead walking.", "Everything in %a% looked ill.",
      "You held your breath a lot in %a%." },
    bard = { "Poisoned the soil of %a%, and weeping the trees.", "In blighted %a% even the wind was grieving." } },
  climHills = {
    chronicle = { "The hills of %a% shaped this chapter.", "%a%, high and rugged, is the setting of this chapter." },
    fireside = { "%a%: up hill, down hill, up hill again.", "Your legs will remember %a%.",
      "%a%, all ridges and ravines and long views." },
    bard = { "Up through the hills of %a% the road climbed.", "Crag and ridge of %a%, and the eagles over." } },
  climCoast = {
    chronicle = { "The sea is never far in this chapter, set in %a%.", "Salt winds of %a% ran through this chapter." },
    fireside = { "%a%: salt in the air and gulls overhead.", "Waves, sand and wet boots in %a%." },
    bard = { "The sea sang under %a%, and you sang with it.", "Salt and spray and the long shore of %a%." } },
  climCity = {
    chronicle = { "Much of this chapter took place within the walls of %a%.", "The streets of %a% fill this chapter." },
    fireside = { "%a%: crowds, shops and somebody always shouting.", "Town time, in %a%. Bank, trainer, repeat." },
    bard = { "The bells of %a% rang over this verse.", "Stone streets and busy squares of %a%." } },
  -- milestone levels (an opener)
  mark1 = {
    chronicle = { "Here the history begins, as every history does, with small things.", "This is the first chapter of %name%." },
    fireside = { "Everybody starts somewhere. This is where you started.", "Day one. Clean boots, empty bags, big ideas." },
    bard = { "Every song begins with a single note, and this is it.", "Hear the first verse, sung soft." } },
  mark10 = {
    chronicle = { "With level ten came the first talent point, and the first real choice.", "The tenth chapter: the end of the beginning." },
    fireside = { "Level ten. The first talent point. You thought about it for ages.", "Ten levels in, and you were starting to look the part." },
    bard = { "At ten the first gift of talent came, and the path began to fork." } },
  mark20 = {
    chronicle = { "Twenty levels now stood behind %name%.", "The twentieth chapter marks a third of the road." },
    fireside = { "Twenty! A third of the way there. Not a beginner any more.", "Level twenty, and the world wasn't so scary now." },
    bard = { "Twenty steps up the mountain, and the valley small below." } },
  mark30 = {
    chronicle = { "At thirty, %name% stood halfway to the summit.", "The thirtieth chapter: halfway." },
    fireside = { "Thirty. Halfway there. Bit of a moment, that.", "Halfway to sixty. Time for a quick look back, then on." },
    bard = { "Halfway up the mountain, the singer pauses for breath." } },
  mark40 = {
    chronicle = { "At forty, the road became wider and faster for %name%.", "The fortieth chapter: two thirds of the road behind." },
    fireside = { "Forty. Two thirds done, and the trainer mentioned riding.", "Level forty: the big four-oh. The good stuff starts here." },
    bard = { "At forty the road quickened, and the hooves called." } },
  mark50 = {
    chronicle = { "With fifty levels behind, the summit came into view.", "The fiftieth chapter: the last ten begin." },
    fireside = { "Fifty. Ten to go. You could almost smell sixty.", "The home stretch: level fifty." },
    bard = { "Fifty steps, and the peak gleams through the clouds." } },
  mark59 = {
    chronicle = { "One step remained between %name% and the summit.", "The last chapter before the top." },
    fireside = { "Fifty-nine. So close you could taste it.", "One more. Just one more." },
    bard = { "The last verse before the summit, sung with held breath." } },
  mark60 = {
    chronicle = { "Here %name% reached the summit of the climb.", "The sixtieth chapter: the summit." },
    fireside = { "Sixty. You did it. Go on, have a little dance.", "The top of the mountain. What a view." },
    bard = { "Upon the summit now, sing loud: the climb is done." } },
  markFive = {
    chronicle = { "Chapter %r% marked another five levels behind %name%.", "Level %n% opened a new stretch of the road." },
    fireside = { "Level %n%: another handful of levels in the bag.", "%n%. A nice round number to stop and stretch at." },
    bard = { "At %n% the singer turns a page." } },
  -- a return after a break (an opener)
  returnBreak = {
    chronicle = { "After %d% away, %name% returned to the road.", "The record resumes after a silence of %d%." },
    fireside = { "You'd been gone %d%. The world waited.", "Back after %d%. Took a minute to remember the keybinds.",
      "%D% away, and then back as if you'd never left." },
    bard = { "After %d% of silence, the song began again.", "%D% the lute lay quiet; now it plays once more." } },
  pause = {
    chronicle = { "Partway through, the chapter paused for %d%." },
    fireside = { "Somewhere in the middle you took %d% off.", "There was a break of %d% in there." },
    bard = { "The verse paused %d% for breath, then went on." } },
  -- streaks and comebacks
  cleanStreak = {
    chronicle = { "It was the %o% chapter in a row without a fall.", "%O% chapter running, and no death recorded." },
    fireside = { "That's %o% level in a row without dying. Don't jinx it.", "%O% clean level running. Somebody's careful." },
    bard = { "The %o% verse without a grave, and still the song goes on." } },
  fallStreak = {
    chronicle = { "It was the %o% chapter in a row with a fall in it." },
    fireside = { "%O% level in a row you've died in. Maybe slow down?", "Another level, another death. That's %n% in a row." },
    bard = { "The %o% verse in a row the dark has touched." } },
  comeback = {
    chronicle = { "After the hardships of chapter %r%, %name% returned stronger.", "Chapter %r% had been cruel; this one was a recovery." },
    fireside = { "Chapter %r% knocked you about. This one, you knocked back.", "After chapter %r%, a proper comeback." },
    bard = { "From the ashes of chapter %r%, a brighter verse rose." } },
  grudge = {
    chronicle = { "%who% had already slain %name% in chapter %r%.", "Not for the first time: %who% had felled %name% in chapter %r% as well." },
    fireside = { "%who% again. They got you back in chapter %r% too.", "You and %who% go back. Chapter %r%, remember?" },
    bard = { "%who%, old foe from chapter %r%, struck again." } },
  revenge = {
    chronicle = { "%who%, who had slain %name% in chapter %r%, was defeated at last." },
    fireside = { "Payback: %who%, who got you in chapter %r%, went down.", "You settled the score with %who% from chapter %r%." },
    bard = { "Vengeance, sweet and sharp: %who% of chapter %r% fell." } },
  closeNoFall = {
    chronicle = { "Death came within a breath, and still the chapter records no fall." },
    fireside = { "You nearly died, and you didn't. That counts.", "Close calls, yes. Deaths, no." },
    bard = { "Death drew near and turned away empty-handed." } },
  -- firsts of the whole journal
  firstDungeon = {
    chronicle = { "This chapter records the first dungeon of %name%.", "Here %name% entered a dungeon for the first time." },
    fireside = { "Your first dungeon. Remember how nervous you were?", "First time in a dungeon. Torches, traps, and a lot of shouting." },
    bard = { "The first door into the deep, and you went through it." } },
  firstBoss = {
    chronicle = { "The first boss of the record fell in this chapter.", "%name% defeated a dungeon lord for the first time." },
    fireside = { "Your first boss kill. The party cheered. You definitely cheered.", "First boss down. You'll never forget that one." },
    bard = { "The first great foe of the deep fell, and the song swelled." } },
  firstBattle = {
    chronicle = { "%name% fought in a battleground for the first time.", "The first battleground of the record." },
    fireside = { "Your first battleground. Chaos, mostly.", "First time on the battlefield proper. Loud, wasn't it?" },
    bard = { "The war horns called, and for the first time you answered." } },
  firstPvp = {
    chronicle = { "The first honorable kill of %name% is recorded here." },
    fireside = { "Your first honorable kill. The war got personal.", "First player you ever beat in a fight. Not the last." },
    bard = { "First blood in the old war, and the banners stirred." } },
  firstDeath = {
    chronicle = { "Here %name% fell for the first time.", "The first death of %name% is recorded in this chapter." },
    fireside = { "Your first death. The grey world, the long walk. Welcome to Azeroth.", "The first time you died. Everyone remembers it." },
    bard = { "For the first time the grey gates opened, and you walked back out." } },
  firstRez = {
    chronicle = { "%name% was raised by another for the first time." },
    fireside = { "The first time someone brought you back. Kindness of strangers.", "First rez from a friend. Saved you a long walk." },
    bard = { "The first time another's word called you back." } },
  firstTrade = {
    chronicle = { "%name% traded with another player for the first time." },
    fireside = { "Your first trade with another player. Hope it was a fair one." },
    bard = { "The first handshake of trade, and goods changed hands." } },
  firstDuel = {
    chronicle = { "%name% fought a first duel." },
    fireside = { "Your first duel. Somebody asked, and you said yes." },
    bard = { "The first friendly crossing of blades." } },
  firstCraft = {
    chronicle = { "%name% practised a craft for the first time." },
    fireside = { "The first thing you ever made yourself. Proud moment." },
    bard = { "The first work of your own hands." } },
  -- dungeons by name, and wipes that became victories
  dungeonNamed = {
    chronicle = { "%name% entered %d%.", "The record takes %name% into %d%." },
    fireside = { "There was %d%, and you went in.", "You did %d%. Mostly in one piece.", "%d% was on the list, and you crossed it off." },
    bard = { "Into %d% the verse descends.", "%d% opened its doors to you." } },
  dungeonRuns = {
    chronicle = { "%name% ran %d% %n% times in this chapter." },
    fireside = { "%d%, %n% times. You could do it blindfolded now.", "%N% runs of %d%. Looking for something?" },
    bard = { "%N% times into %d%, and %n% times out again." } },
  wipeThenWin = {
    chronicle = { "%b% defeated the party at first, and fell at last.", "%b% held out against the party, but not forever." },
    fireside = { "%b% wiped you, and then you came back and wiped %b%.", "It took a few goes, but %b% went down in the end.",
      "%b% had the upper hand. Briefly." },
    bard = { "Once %b% stood over the fallen party; then the party stood over %b%.", "%b% laughed at the first try, and fell at the last." } },
  wipeOnly = {
    chronicle = { "%b% defeated the party, and was not overcome in this chapter." },
    fireside = { "%b% won that round. There'll be another.", "The party wiped on %b%. It happens to everyone." },
    bard = { "%b% held the hall, and the party withdrew." } },
  -- battlegrounds and duels
  bgWins = {
    chronicle = { "%name% won %n% battles on the battlefield.", "%N% victories in battle are recorded." },
    fireside = { "%N% battleground wins. The other side is sick of you.", "You won %n% battlegrounds. Not bad at all." },
    bard = { "%N% times the field was won, and the banners sang." } },
  bgLosses = {
    chronicle = { "%name% fought %n% battles and did not prevail." },
    fireside = { "%N% battlegrounds, %n% losses. Rough week on the front.", "You lost %n% battlegrounds. The queue giveth, the queue taketh." },
    bard = { "%N% times the field was lost, and still you went back." } },
  bgMixed = {
    chronicle = { "On the battlefield: %w% won, %x% lost." },
    fireside = { "Battlegrounds: %w% won, %x% lost. Swings and roundabouts." },
    bard = { "Won %w%, lost %x%, and every one a story." } },
  duelWon = {
    chronicle = { "%name% won a duel against %who%." },
    fireside = { "You beat %who% in a duel. They'll want a rematch.", "%who% challenged you to a duel. Bad idea, %who%." },
    bard = { "Blades crossed with %who%, and yours stood." } },
  duelLost = {
    chronicle = { "%name% lost a duel to %who%." },
    fireside = { "%who% beat you in a duel. Rematch pending.", "You lost a duel to %who%. Good sport about it, mostly." },
    bard = { "Blades crossed with %who%, and theirs stood." } },
  -- the social side
  trades = {
    chronicle = { "%name% traded with other players %n% times.", "%N% trades are recorded." },
    fireside = { "%N% trades with other folk. A regular merchant.", "You swapped goods %n% times." },
    bard = { "%N% times hand met hand in trade." } },
  emotes = {
    chronicle = { "Others greeted %name% on the road, %who% among them." },
    fireside = { "People kept waving at you. %who%, for one.", "%who% and others took a moment to say hello." },
    bard = { "Strangers smiled as you passed, %who% among them." } },
  guildJoin = {
    chronicle = { "In this chapter %name% joined the guild %g%." },
    fireside = { "You joined %g%. New tabard, new friends.", "%g% took you in. Welcome to the family." },
    bard = { "The banner of %g% was raised over you." } },
  kindness = {
    chronicle = { "Thanks were given and received in this chapter." },
    fireside = { "Somebody said thank you, and meant it.", "There was a bit of kindness going round this level." },
    bard = { "A word of thanks, and the road was warmer." } },
  toasts = {
    chronicle = { "A toast was raised in the name of %name%." },
    fireside = { "Somebody raised a mug to you. Cheers.", "A toast in your honour. Don't let it go to your head." },
    bard = { "Cups were raised and your name was sung." } },
  signed = {
    chronicle = { "%who% signed the journal of %name%." },
    fireside = { "%who% wrote a line in your journal. Keep that page.", "Your journal has %who%'s hand in it now." },
    bard = { "In %who%'s own hand, a line in your book." } },
  fellowship = {
    chronicle = { "A fellowship formed around %name% in this chapter." },
    fireside = { "A proper band formed this level. You found your people.", "The same faces, day after day. A fellowship, really." },
    bard = { "A fellowship was born, and the song took on more voices." } },
  -- professions
  skillUp = {
    chronicle = { "%p% reached %r% in this chapter.", "The skill of %name% in %p% rose to %r%." },
    fireside = { "%p% up to %r%. All that practice paid off.", "%r% in %p%. Getting good at this." },
    bard = { "%p% climbed to %r%, and the craft grew sure." } },
  capReached = {
    chronicle = { "%name% attained the rank of %c%.", "The chapter marks the rank of %c%." },
    fireside = { "%c%! A new rank and a new trainer to see.", "You made %c%. That took some doing." },
    bard = { "%c%: a new title for the hands that work." } },
  crafted = {
    chronicle = { "%name% made %n% items at the bench in this chapter." },
    fireside = { "%N% things made at the bench. Busy hands.", "You crafted %n% things. Your bags are full of them." },
    bard = { "%N% works of the hand, made with care." } },
  -- the purse and the market
  purseMark = {
    chronicle = { "%S%." },
    fireside = { "%S%. The purse is getting heavy.", "%S%. You checked twice." },
    bard = { "%S%, and the coins chimed." } },
  sales = {
    chronicle = { "%N% sales at the auction house are recorded." },
    fireside = { "%N% things sold at the auction house. Business is good.", "Buyers took %n% of your auctions." },
    bard = { "%N% times the auctioneer's hammer fell in your favour." } },
  expired = {
    chronicle = { "%N% auctions of %name% found no buyer." },
    fireside = { "%N% auctions came back unsold. Price them lower?", "Nobody wanted %n% of your auctions. Their loss." },
    bard = { "%N% wares came home unsold." } },
  -- what kind of quests a chapter was made of
  kindHunt = {
    chronicle = { "Most of the quests of this chapter were hunts.", "The chapter was one of hunting: most tasks called for a kill." },
    fireside = { "Mostly kill quests this level. Somebody had to.", "A hunter's level: everyone wanted something dead." },
    bard = { "A hunting verse: horn and track and the kill." } },
  kindGather = {
    chronicle = { "Most of the quests of this chapter were gathering.", "The chapter was one of collecting." },
    fireside = { "Mostly collect quests this level. Ten of this, eight of that.", "A gathering level. Your bags were full of other people's shopping." },
    bard = { "A gathering verse: pouch and pack and plenty." } },
  kindErrand = {
    chronicle = { "Most of the quests of this chapter were errands and messages.", "The chapter was one of errands." },
    fireside = { "Mostly errands this level. Postman of Azeroth.", "Run here, tell him, take this there. An errand level." },
    bard = { "A messenger's verse, all roads and letters." } },
  kindEscort = {
    chronicle = { "%name% escorted others to safety in this chapter." },
    fireside = { "There was an escort. There's always an escort.", "You walked someone home. Slowly." },
    bard = { "You guarded the weak along a dangerous road." } },
  -- the clock and the calendar
  evening = {
    chronicle = { "Most of this chapter was written in the evenings." },
    fireside = { "Evenings, mostly. After dinner, before bed.", "An evening level, played by lamplight." },
    bard = { "Sung at dusk, this verse, as the day let go." } },
  afternoon = {
    chronicle = { "Most of this chapter was written in the afternoons." },
    fireside = { "Lazy afternoons, this level.", "An afternoon level. Tea and quests." },
    bard = { "Under the high sun of afternoon this verse was sung." } },
  weekend = {
    chronicle = { "Most of this chapter was written at the weekend." },
    fireside = { "A weekend level. The best kind.", "Weekend play, this one. No alarms." },
    bard = { "A feast-day verse, free and long." } },
  sittings = {
    chronicle = { "The chapter was written over %n% sittings." },
    fireside = { "%N% sessions, a bit at a time.", "You came back to this one %n% times." },
    bard = { "In %n% sittings the verse was woven." } },
  marathon = {
    chronicle = { "Much of the chapter was written in one long session of %d%." },
    fireside = { "One stretch of %d% without a break. Stretch your legs.", "You played %d% straight. Hydrate." },
    bard = { "For %d% the singer did not pause." } },
  inns = {
    chronicle = { "%name% rested at inns along the way." },
    fireside = { "A warm inn or two along the way.", "There were inns, and you made good use of them." },
    bard = { "Inn-fires and soft beds along the road." } },
  -- how the chapter ended: the next level, when and where (a closer)
  dingDawn = {
    chronicle = { "Level %next% came at dawn, in %z%.", "The chapter closed at first light in %z%." },
    fireside = { "And level %next% hit at dawn in %z%, with the birds.", "Level %next% came at sunrise in %z%. Worth the early start." },
    bard = { "With the dawn in %z% came level %next%.", "At first light in %z% the verse was ended." } },
  dingDay = {
    chronicle = { "Level %next% was reached in %z%, in the full light of day.", "The chapter ended in %z% around midday." },
    fireside = { "Level %next% came in %z%, middle of the day.", "Level %next% popped in %z% with the sun high." },
    bard = { "Under the high sun of %z% came level %next%." } },
  dingDusk = {
    chronicle = { "Level %next% came at dusk, in %z%.", "The chapter closed in %z% as evening fell." },
    fireside = { "Level %next% came at dusk in %z%. A good way to end a day.", "As the sun went down over %z%, level %next%." },
    bard = { "At dusk in %z% the golden light of %next% fell.", "The evening star rose over %z%, and with it level %next%." } },
  dingNight = {
    chronicle = { "Level %next% came at night, in %z%.", "The chapter closed in %z% in the dark hours." },
    fireside = { "Level %next% came in %z%, well after dark.", "Late at night in %z%: level %next%, and then bed. Maybe." },
    bard = { "By moonlight in %z% came level %next%." } },
  dingQuest = {
    chronicle = { "Level %next% came with the completion of %t%.", "The chapter closed as %t% was handed in." },
    fireside = { "And handing in %t% tipped you over to level %next%.", "%t% was the one that did it: level %next%.",
      "The reward for %t% came with level %next% on top." },
    bard = { "%t% was done, and level %next% came with it.", "The last task of the verse: %t%, and then level %next%." } },
}

local function merge(into, from)
  for slot, voices in pairs(from) do
    into[slot] = into[slot] or {}
    for voice, list in pairs(voices) do
      local to = into[slot][voice]
      if not to then to = {}; into[slot][voice] = to end
      for _, line in ipairs(list) do to[#to + 1] = line end
    end
  end
end
merge(Vo.L, MORE_L)
merge(Vo.M, MORE_M)
merge(Vo.M, NEW)
St.NEW = NEW

-- More for the preface (JourneyVoice's PREFACE).
if Vo.PREFACE then
  merge(Vo.PREFACE, {
    open = {
      chronicle = { "This book records the deeds of %full%, %who%, from the first day in %zone% to the present." },
      fireside = { "Right. Get comfortable. This is about %full%, %who%, and it starts in %zone%." },
      bard = { "Hear the tale of %full%, %who%, born to the road in %zone%." } },
    close = {
      chronicle = { "Each chapter that follows covers a single level." },
      fireside = { "One level, one chapter. That's the rule." },
      bard = { "Each verse a level, each level a verse." } },
  })
end

----------------------------------------------------------------------------
-- The weather of a land
----------------------------------------------------------------------------
St.CLIMATE = {
  ["Dun Morogh"] = "Snow", ["Alterac Mountains"] = "Snow", ["Winterspring"] = "Snow",
  ["Elwynn Forest"] = "Forest", ["Teldrassil"] = "Forest", ["Ashenvale"] = "Forest", ["Darkshore"] = "Forest",
  ["Moonglade"] = "Forest", ["Hillsbrad Foothills"] = "Forest", ["Mount Hyjal"] = "Forest", ["Riverglades"] = "Forest",
  ["Duskwood"] = "Dark", ["Silverpine Forest"] = "Dark", ["Tirisfal Glades"] = "Dark", ["Deadwind Pass"] = "Dark",
  ["Westfall"] = "Plains", ["Mulgore"] = "Plains", ["Arathi Highlands"] = "Plains", ["Loch Modan"] = "Plains",
  ["Tanaris"] = "Desert", ["Silithus"] = "Desert", ["Desolace"] = "Desert", ["Badlands"] = "Desert",
  ["Thousand Needles"] = "Desert", ["Durotar"] = "Desert", ["The Barrens"] = "Desert",
  ["Wetlands"] = "Swamp", ["Dustwallow Marsh"] = "Swamp", ["Swamp of Sorrows"] = "Swamp",
  ["Stranglethorn Vale"] = "Jungle", ["Un'Goro Crater"] = "Jungle", ["Feralas"] = "Jungle",
  ["Searing Gorge"] = "Fire", ["Burning Steppes"] = "Fire", ["Blasted Lands"] = "Fire",
  ["Western Plaguelands"] = "Blight", ["Eastern Plaguelands"] = "Blight", ["Felwood"] = "Blight",
  ["The Hinterlands"] = "Hills", ["Stonetalon Mountains"] = "Hills", ["Redridge Mountains"] = "Hills",
  ["Azshara"] = "Coast", ["Zephras Isle"] = "Coast",
  ["Stormwind City"] = "City", ["Ironforge"] = "City", ["Darnassus"] = "City", ["Orgrimmar"] = "City",
  ["Thunder Bluff"] = "City", ["Undercity"] = "City",
}

----------------------------------------------------------------------------
-- Joining words between sentences, so a chapter doesn't read as a list
----------------------------------------------------------------------------
St.JOINS = {
  chronicle = { "Thereafter, ", "In due course, ", "Later, ", "After this, ", "Also, " },
  fireside = { "Then ", "After that, ", "Oh, and ", "Meanwhile, ", "Somewhere in there, ", "And ", "On top of that, " },
  bard = { "And ", "Then ", "And so ", "Meanwhile, ", "And then " },
}
local LOWER = { You = true, The = true, A = true, An = true, It = true, There = true, Your = true, Some = true, Most = true,
  Much = true, Somebody = true, Someone = true, Another = true, Nobody = true, No = true,
  Every = true, This = true, That = true, Few = true, Little = true }
function Vo.joined(text, seed, i)
  if type(text) ~= "string" or i < 2 or hashOf(seed .. "join" .. i) % 3 ~= 0 then return text end
  local first, rest = text:match("^(%a+)(.*)$")
  if not first or not LOWER[first] then return text end
  local list = St.JOINS[Vo.style()] or St.JOINS.fireside
  local join = list[hashOf(seed .. "joinword" .. i) % #list + 1]
  return join .. first:lower() .. rest
end

----------------------------------------------------------------------------
-- What a chapter can notice
----------------------------------------------------------------------------
local function chapterOf(e) return tonumber(e.l) or 1 end
local function bare(t) return capital((tostring(t or ""):gsub("[%.!]+$", ""))) end
local function hourBucket(t)
  local h = Vo.hourOf(t)
  if not h then return nil end
  if h >= 5 and h < 9 then return "dingDawn" elseif h >= 9 and h < 17 then return "dingDay"
  elseif h >= 17 and h < 21 then return "dingDusk" else return "dingNight" end
end
local function dayOf(t)
  if type(date) ~= "function" or not tonumber(t) then return nil end
  local ok, d = pcall(date, "*t", tonumber(t))
  return ok and type(d) == "table" and tonumber(d.wday) or nil
end

-- The weather and the milestone levels: openers.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local land = c.main
  local clim = land and St.CLIMATE[land]
  if clim and #c.zones <= 2 then c.opener("clim" .. clim, { a = land }, 1) end
  local l = c.l
  local marks = { [1] = "mark1", [10] = "mark10", [20] = "mark20", [30] = "mark30", [40] = "mark40", [50] = "mark50",
    [59] = "mark59", [60] = "mark60" }
  if marks[l] then c.opener(marks[l], {}, 3)
  elseif l % 5 == 0 and l > 1 then c.opener("markFive", { n = tostring(l), r = roman(l) }, 2) end
end

-- A return after a break, and a break inside the chapter.
Vo.noticers[#Vo.noticers + 1] = function(c)
  if not c.tFirst then return end
  local before
  for _, e in ipairs(c.j.events) do
    local t = tonumber(e.t)
    if t and t < c.tFirst and (not before or t > before) then before = t end
  end
  local gap = before and (c.tFirst - before) or 0
  if gap >= 5 * 86400 then
    local d = J.draw.duration(gap)
    c.opener("returnBreak", { d = d, D = capital(d) }, 3)
  end
  local times = {}
  for _, e in ipairs(c.events) do if tonumber(e.t) then times[#times + 1] = tonumber(e.t) end end
  table.sort(times)
  local longest, sittings, run, best = 0, 1, 0, 0
  for i = 2, #times do
    local d = times[i] - times[i - 1]
    if d > longest then longest = d end
    if d > 2 * 3600 then sittings = sittings + 1; run = 0 else run = run + d end
    if run > best then best = run end
  end
  if longest >= 4 * 86400 then
    local d = J.draw.duration(longest)
    c.add(5, 6, "pause", { d = d, D = capital(d) })
  end
  if not c.current and sittings >= 4 then c.add(3, 6, "sittings", { n = say(sittings), N = capital(say(sittings)) }) end
  if best >= 3 * 3600 then c.add(4, 6, "marathon", { d = J.draw.duration(best) }) end
end

-- Streaks and comebacks, from the level records.
Vo.noticers[#Vo.noticers + 1] = function(c)
  if c.current or not c.rec then return end
  local l = c.l
  local function deathsAt(x)
    if x == l then return c.deaths end
    local r = recordOf(x)
    return r and tonumber(r.deaths) or nil
  end
  local clean, fell = 0, 0
  for x = l, math.max(1, l - 15), -1 do
    local d = deathsAt(x)
    if d == nil or d > 0 then break end
    clean = clean + 1
  end
  for x = l, math.max(1, l - 15), -1 do
    local d = deathsAt(x)
    if d == nil or d == 0 then break end
    fell = fell + 1
  end
  if clean >= 3 then c.add(6.5, 5.2, "cleanStreak", { o = ordinal(clean), O = capital(ordinal(clean)) }) end
  if fell >= 3 then c.add(6, 5.2, "fallStreak", { o = ordinal(fell), O = capital(ordinal(fell)), n = say(fell) }) end
  local prev = c.prev
  local wonBig = #c.bosses > 0 or #c.elites > 0 or (c.n.rare or 0) > 0
  if prev and (tonumber(prev.deaths) or 0) >= 3 and (wonBig or (c.deaths == 0 and c.quests >= 5)) then
    c.add(7.5, 5.1, "comeback", { r = roman(l - 1) })
  end
  if c.deaths == 0 and (c.n.close or 0) > 0 then c.add(6.5, 5.3, "closeNoFall") end
end

-- Old foes: killers who got you before, and the ones you paid back.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local earlier = {}
  for _, e in ipairs(c.j.events) do
    local el = chapterOf(e)
    if e.k == "death" and el < c.l and type(e.who) == "string" and e.who ~= "" then
      if not earlier[e.who] or el < earlier[e.who] then earlier[e.who] = el end
    end
  end
  for _, who in ipairs(c.killers) do
    if earlier[who] then c.add(7.2, 5, "grudge", { who = who, r = roman(earlier[who]) }); break end
  end
  for _, e in ipairs(c.events) do
    if (e.k == "rare" or e.k == "elite" or e.k == "boss" or e.k == "duel") and type(e.who) == "string" and earlier[e.who] then
      c.add(8.5, 4.5, "revenge", { who = e.who, r = roman(earlier[e.who]) })
      break
    end
  end
end

-- Firsts of the whole journal.
local FIRSTS = { dungeon = "firstDungeon", boss = "firstBoss", bg = "firstBattle", pvp = "firstPvp", death = "firstDeath",
  rez = "firstRez", trade = "firstTrade", duel = "firstDuel", craft = "firstCraft" }
local FIRST_PRI = { boss = 8, dungeon = 7.5, death = 7, bg = 7, pvp = 7, rez = 6.5, trade = 5, duel = 5, craft = 5 }
Vo.noticers[#Vo.noticers + 1] = function(c)
  local here, before = {}, {}
  for _, e in ipairs(c.events) do if FIRSTS[e.k] then here[e.k] = true end end
  if not next(here) then return end
  for _, e in ipairs(c.j.events) do
    if FIRSTS[e.k] and chapterOf(e) < c.l then before[e.k] = true end
  end
  -- the first boss says the first dungeon too
  if here.boss and not before.boss then here.dungeon = nil end
  for k in pairs(here) do
    -- the very first chapter's death is nothing special to say twice
    if not before[k] and not (k == "death" and c.l <= 2) then c.add(FIRST_PRI[k], 3.5, FIRSTS[k]) end
  end
end

-- Dungeons by name, repeat runs, and wipes that turned to victories.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local runs, order = {}, {}
  for _, e in ipairs(c.events) do
    if (e.k == "dungeon" or e.k == "run") and type(e.who) == "string" and e.who ~= "" then
      if not runs[e.who] then runs[e.who] = { dungeon = 0, run = 0 }; order[#order + 1] = e.who end
      runs[e.who][e.k] = runs[e.who][e.k] + 1
    end
  end
  for _, name in ipairs(order) do
    local times = math.max(runs[name].dungeon, runs[name].run)
    if times >= 3 then c.add(6.5, 4.1, "dungeonRuns", { d = name, n = say(times), N = capital(say(times)) }); break end
  end
  if #order > 0 and #c.bosses == 0 then c.add(6.8, 4.1, "dungeonNamed", { d = Vo.names_(order) }) end
  local wiped, beaten = {}, {}
  for _, e in ipairs(c.events) do
    if e.k == "wipe" and type(e.who) == "string" then wiped[#wiped + 1] = e.who end
    if e.k == "boss" and type(e.who) == "string" then beaten[e.who] = true end
  end
  for _, b in ipairs(wiped) do
    if beaten[b] then
      c.add(8.6, 4.2, "wipeThenWin", { b = b })
      -- one boss, told once: the wipes-then-victory line says it better than the plain boss line
      if #c.bosses == 1 then c.drop("deep") end
      return
    end
  end
  if wiped[1] then c.add(6, 4.2, "wipeOnly", { b = wiped[1] }) end
end

-- Battlegrounds and duels.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local won, lost, duels = 0, 0, {}
  for _, e in ipairs(c.events) do
    if e.k == "bg" and e.d == "Victory" then won = won + 1 elseif e.k == "bg" and e.d == "Defeat" then lost = lost + 1 end
    if e.k == "duel" and type(e.who) == "string" then duels[#duels + 1] = e end
  end
  if won > 0 and lost > 0 then c.add(6.5, 4.3, "bgMixed", { w = say(won), x = say(lost) })
  elseif won > 0 then c.add(6.5, 4.3, "bgWins", { n = say(won), N = capital(say(won)) })
  elseif lost > 0 then c.add(6, 4.3, "bgLosses", { n = say(lost), N = capital(say(lost)) }) end
  if #duels == 1 then
    local e = duels[1]
    c.add(4.5, 4.4, e.d == "Duel lost" and "duelLost" or "duelWon", { who = e.who })
  end
end

-- The social side: trades, greetings, guilds, thanks, toasts, signatures, fellowships.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local n, greeter, guild, signer = {}, nil, nil, nil
  for _, e in ipairs(c.events) do
    n[e.k] = (n[e.k] or 0) + 1
    if e.k == "emote" and type(e.who) == "string" and not greeter then greeter = e.who end
    if e.k == "guild" and type(e.s) == "string" then guild = e.s:match("<(.-)>") or guild end
    if e.k == "signed" and type(e.who) == "string" then signer = e.who end
  end
  if (n.trade or 0) >= 2 then c.add(4, 7.1, "trades", { n = say(n.trade), N = capital(say(n.trade)) }) end
  if greeter and (n.emote or 0) >= 2 then c.add(3.5, 7.1, "emotes", { who = greeter }) end
  if guild then c.add(7, 7.1, "guildJoin", { g = "<" .. guild .. ">" }) end
  if (n.thanks or 0) > 0 then c.add(4.5, 7.2, "kindness") end
  if (n.toast or 0) > 0 then c.add(4, 7.2, "toasts") end
  if signer then c.add(5.5, 7.2, "signed", { who = signer }) end
  if (n.fellowship or 0) > 0 then c.add(7, 7.2, "fellowship") end
end

-- Professions, crafting, the purse and the market.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local skill, cap, crafted, purse, sold, expired = nil, nil, 0, nil, 0, 0
  for _, e in ipairs(c.events) do
    if e.k == "skill" and type(e.d) == "string" then
      local p, r = e.d:match("^(.-) (%d+)$")
      if p then skill = { p = p, r = r } end
    elseif e.k == "cap" and type(e.d) == "string" then cap = e.d
    elseif e.k == "craft" then crafted = crafted + (tonumber(e.n) or 1)
    elseif e.k == "gold" and type(e.d) == "string" and e.d:find("in your purse", 1, true) and e.s then purse = e
    elseif e.k == "sold" then sold = sold + 1
    elseif e.k == "expired" then expired = expired + 1 end
  end
  if cap then c.add(6.5, 8.1, "capReached", { c = cap })
  elseif skill then c.add(5, 8.1, "skillUp", skill) end
  if crafted >= 5 then c.add(4, 8.1, "crafted", { n = say(crafted), N = capital(say(crafted)) }) end
  if purse then c.add(5.5, 7.5, "purseMark", { S = bare(purse.s) }) end
  if sold >= 2 then c.add(4, 7.5, "sales", { n = say(sold), N = capital(say(sold)) }) end
  if expired >= 3 then c.add(3, 7.5, "expired", { n = say(expired), N = capital(say(expired)) }) end
end

-- What kind of quests the chapter was made of.
local KIND_GROUP = { wanted = "kindHunt", slay = "kindHunt", kill = "kindHunt", proof = "kindHunt",
  loot = "kindGather", gather = "kindGather", find = "kindGather", cook = "kindGather", buy = "kindGather",
  deliver = "kindErrand", errand = "kindErrand", scout = "kindErrand", escort = "kindEscort" }
Vo.noticers[#Vo.noticers + 1] = function(c)
  if not J.questKind then return end
  local counts, total, escort = {}, 0, false
  for _, e in ipairs(c.events) do
    if e.q and (e.k == "quest" or e.k == "chain" or e.k == "elite") then
      local title = type(e.d) == "string" and e.d:match("^Quest: (.+)$") or nil
      local ok, kind = pcall(J.questKind, e.q, title)
      local g = ok and KIND_GROUP[kind]
      if g then
        counts[g] = (counts[g] or 0) + 1
        total = total + 1
        if g == "kindEscort" then escort = true end
      end
    end
  end
  if escort then c.add(4.5, 3.2, "kindEscort") end
  local best, bestN = nil, 0
  for g, k in pairs(counts) do if g ~= "kindEscort" and k > bestN then best, bestN = g, k end end
  if best and bestN >= 4 and bestN >= total * 0.5 then c.add(5, 3.1, best) end
end

-- The clock and the calendar: evenings, afternoons, weekends, inns.
Vo.noticers[#Vo.noticers + 1] = function(c)
  local evening, afternoon, weekend, timed, inns = 0, 0, 0, 0, 0
  for _, e in ipairs(c.events) do
    local h = Vo.hourOf(e.t)
    if h then
      timed = timed + 1
      if h >= 17 and h < 23 then evening = evening + 1 elseif h >= 12 and h < 17 then afternoon = afternoon + 1 end
      local wd = dayOf(e.t)
      if wd == 1 or wd == 7 then weekend = weekend + 1 end
    end
    if e.k == "rest" then inns = inns + 1 end
  end
  if timed >= 4 and c.night < timed * 0.5 and c.morning < timed * 0.5 then
    if evening >= timed * 0.6 then c.add(3.5, 6, "evening") elseif afternoon >= timed * 0.6 then c.add(3.5, 6, "afternoon") end
  end
  if timed >= 4 and weekend >= timed * 0.8 then c.add(3, 6.1, "weekend") end
  if inns >= 2 then c.add(3, 8.2, "inns") end
end

-- How the chapter ended: the next level's moment (when and where), or the quest that brought it.
Vo.noticers[#Vo.noticers + 1] = function(c)
  if c.current then return end
  local ding
  for _, e in ipairs(c.j.events) do
    if e.k == "level" and chapterOf(e) == c.l + 1 then ding = e; break end
  end
  if not ding then return end
  local nextL = tostring(c.l + 1)
  local t = tonumber(ding.t)
  if t then
    for _, e in ipairs(c.j.events) do
      local et = tonumber(e.t)
      if et and math.abs(et - t) <= 3 and (e.k == "quest" or e.k == "chain" or e.k == "elite") and type(e.d) == "string" then
        local title = e.d:match("^Quest: (.+)$")
        if title then c.closer("dingQuest", { t = title, next = nextL }) end
        break
      end
    end
  end
  local z = ding.m and J.landOf(ding.m)
  local bucket = hourBucket(ding.t)
  if z and bucket then c.closer(bucket, { z = z, next = nextL }) end
end

function ns.journeyStoryDebugLines()
  local pools, lines = 0, 0
  for _, pool in ipairs({ Vo.L, Vo.M }) do
    for _, voices in pairs(pool) do
      pools = pools + 1
      for _, list in pairs(voices) do lines = lines + #list end
    end
  end
  return { "journey story: " .. pools .. " pools, " .. lines .. " lines, " .. #Vo.noticers .. " noticers"
    .. (Vo.lastError and (", last error " .. Vo.lastError) or "") }
end
