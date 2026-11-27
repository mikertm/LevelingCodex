-- Options.lua: the Codex's settings in the game's own Options > AddOns panel.
-- "Leveling Codex" (the General page) with the subcategories Questing, Map and arrow, Group and
-- Helpers, the same pages as the Codex's Settings tab. Every control reads and writes the same
-- LevelingCodexDB keys and calls the same functions as the tab, so a change in one shows in the
-- other: a shown page re-reads every control twice a second, and a change here redraws the tab.
-- Canvas categories (Settings.RegisterCanvasLayoutCategory, what the add-ons written for Forever
-- use), else the old InterfaceOptions_AddCategory. Pages are built the first time they show.
local _, ns = ...

local O = {}
ns.options = O
O.NAME = "Leveling Codex"
O.PAGES = { "General", "Questing", "Map and arrow", "Group", "Helpers" }
O.WIDTH = 580

local function db() return ns.db() end
local function flip(key) local d = db(); d[key] = not d[key] or nil end

----------------------------------------------------------------------------
-- What each page holds: sections of items. Item kinds:
--   check  { label, tip, get() -> on, set() }               a check box
--   choice { label, labels (or function), get() -> index, set(i), tips }   a row of buttons
--   stepper { label, text() -> value, dec(), inc(), tip }  - value +
--   buttons { { label (or function), run(), tip }, ... }   a row of buttons
--   note   { text() -> string or nil }                      a small grey line
-- Any item may have shown() -> false to leave it out for now.
----------------------------------------------------------------------------

-- A check box on db[key] that is on while the key is unset (the "no..." keys).
local function offKey(label, key, tip, after)
  return { kind = "check", label = label, tip = tip,
    get = function() return not db()[key] end,
    set = function() flip(key); if after then after() end end }
end
-- A check box on db[key] that is on while the key is set.
local function onKey(label, key, tip, after)
  return { kind = "check", label = label, tip = tip,
    get = function() return db()[key] and true or false end,
    set = function() flip(key); if after then after() end end }
end
local function questRefresh() ns.questRefresh() end
local function questSettings() ns.updateQuestSettings() end
local function pct(v) return math.floor((tonumber(v) or 1) * 100 + 0.5) .. "%" end

local THEMES = { { "forever", "Forever (teal)" }, { "codex", "Codex (gold)" }, { "ellesmere", "External skin" } }
local function themeList()
  local out = {}
  for i, t in ipairs(THEMES) do
    if i < 3 or ns.skinSupport.available() then out[#out + 1] = t end
  end
  return out
end

local PADS = { { "xbox", "Xbox" }, { "ps", "PlayStation" }, { "switch", "Switch" } }

-- The quest item and target buttons: shown, where, and how far off.
local SIDES = { { "left", "Left" }, { "right", "Right" }, { "top", "Top" }, { "bottom", "Bottom" } }
local function questButton(kind, name, toggleLabel, key, tip)
  local function nudge(axis, delta)
    local side, x, y = ns.questButtonLayout(kind)
    local limit = ns.questButtonOffsetLimit()
    local function clamp(n) return math.floor(math.max(-limit, math.min(limit, n)) + 0.5) end
    if axis == "x" then x = clamp(x + delta) else y = clamp(y + delta) end
    ns.setQuestButtonLayout(kind, side, x, y)
  end
  local function offset(axis, label)
    return { kind = "stepper", label = name .. " " .. label:lower(), step = "5 px",
      text = function()
        local _, x, y = ns.questButtonLayout(kind)
        return (axis == "x" and x or y) .. " px"
      end,
      dec = function() nudge(axis, -5) end, inc = function() nudge(axis, 5) end,
      tip = "Moves the button by 5 pixels. Positive horizontal moves right; positive vertical moves up." }
  end
  local labels = {}
  for i, s in ipairs(SIDES) do labels[i] = s[2] end
  return {
    offKey(toggleLabel, key, tip .. " Changes wait until you leave combat.", function() ns.placeQuestButtons() end),
    { kind = "choice", label = name .. " position", labels = labels,
      get = function()
        local side = ns.questButtonLayout(kind)
        for i, s in ipairs(SIDES) do if s[1] == side then return i end end
      end,
      set = function(i)
        local _, x, y = ns.questButtonLayout(kind)
        ns.setQuestButtonLayout(kind, SIDES[i][1], x, y)
      end },
    offset("x", "Horizontal"),
    offset("y", "Vertical"),
    { kind = "buttons", { label = "Reset " .. name:lower() .. " position", width = 200,
      run = function() ns.resetQuestButtonLayout(kind) end,
      tip = "Return this button to the left of the step window with no offsets." } },
  }
end

local function sections()
  local list = {}
  local function add(page, title, items) list[#list + 1] = { page = page, title = title, items = items } end

  add("General", "THEME", {
    { kind = "choice", label = "Theme",
      labels = function()
        local out = {}
        for i, t in ipairs(themeList()) do out[i] = t[2] end
        return out
      end,
      get = function()
        for i, t in ipairs(themeList()) do if t[1] == (ns.themeKey or "forever") then return i end end
      end,
      set = function(i) local t = themeList()[i]; if t then ns.setTheme(t[1]) end end,
      tips = { "WoW: Forever's logo teal for the accents and highlights.", "The guide site's gold for the accents and highlights.",
        "Use your installed UI skin's panels, accent colour and font." } },
  })
  add("General", "CONTROLLER BUTTON NAMES", {
    { kind = "choice", label = "Button names", labels = { "Xbox", "PlayStation", "Switch" },
      get = function()
        for i, p in ipairs(PADS) do if p[1] == (db().pad or "xbox") then return i end end
      end,
      set = function(i) db().pad = PADS[i][1] end },
  })
  add("General", "LEVEL-UP BANNER", {
    offKey("Show the level-up banner", "noToast"),
    { kind = "buttons",
      { label = "Test level-up", run = function()
          local t = ns.getToast()
          if t and t.unlocked then ns.setToastUnlocked(false) end
          ns.showToast(UnitLevel("player"), true, true)
        end, tip = "Plays a level-up for your level and keeps the banner up: drag it where you want it, right-click it to close." },
      { label = function()
          local t = ns.getToast()
          return (t and t.unlocked) and "Lock banner" or "Move banner"
        end, run = function()
          local t = ns.getToast()
          ns.setToastUnlocked(not (t and t.unlocked))
        end, tip = "Shows the banner so you can drag it anywhere. Press again to lock it there." },
      { label = "Reset banner", run = function() db().toastPos = nil; db().toastScale = 1; ns.placeToast() end,
        tip = "Puts the banner back where it started, at its normal size." } },
    { kind = "stepper", label = "Banner size", text = function() return pct(db().toastScale) end,
      dec = function() db().toastScale = math.max(0.5, (tonumber(db().toastScale) or 1) - 0.1); ns.placeToast() end,
      inc = function() db().toastScale = math.min(2, (tonumber(db().toastScale) or 1) + 0.1); ns.placeToast() end },
  })
  add("General", "MESSAGES AND MACROS", {
    offKey("Level-up messages in chat", "quiet"),
    offKey("Keep my Codex macros up to date", "noAutoMacros",
      "After a level-up, macros the Codex made switch to the right version for your new level. Your own macros are never touched."),
  })
  add("General", "JOURNEY POP-UPS", {
    offKey("Show a card when the journal writes a big moment", "noJourneyCards",
      "The \"A new line in your journey\" card at the top of the screen. The moment is still written in the Journey."),
    offKey("Show \"Last time on your journey...\" when I log in", "noJourneyRecap", "The recap card and chat line after a break."),
    offKey("Show a card when a friend is near, a bond grows or a fellowship forms", "noSocialCards",
      "Reunions, bonds, fellowships, signatures, toasts and anniversaries. They are still written in the Journey."),
    offKey("Swap journal titles and signatures with other Codex players", "noJourneyShare",
      "In a party, Codex players see each other's journal title and can sign each other's journals and raise toasts."),
    offKey("Remind me when Well-Rested or Camp Benefits is about to fade", "noCampNudge",
      "A chat line about five minutes before your camp's buffs run out, so you can sit by a fire or unroll the bag again."),
    onKey("Take a screenshot for each group portrait", "journeyScreenshots",
      "When a level or a boss is framed with your party, the game saves a screenshot too (in your Screenshots folder)."),
  })
  add("General", "CONTROLLER", {
    { kind = "check", label = "Use Forever's controller navigation",
      tip = "Off: the Codex moves its own highlight with the D-pad instead of Forever's focus glow. Turn it off if Forever's controller navigation misbehaves in the Codex.",
      get = function() return db().padNative ~= false end,
      set = function()
        db().padNative = (db().padNative == false) and nil or false
        ns.gamepad.repick()
      end },
  })
  add("General", "MINIMAP BUTTON", {
    offKey("Minimap button", "noMinimap",
      "Drag the Level 60 badge around the edge of the minimap to put it where you like. The Codex is also in the addons button under the clock.",
      function() ns.updateMini() end),
    { kind = "buttons", { label = "Reset minimap button", width = 200, run = function() db().minimapAngle = nil; ns.updateMini() end } },
  })
  add("General", "THE CODEX WINDOW", {
    { kind = "stepper", label = "Window size", text = function() return pct(db().windowScale) end,
      dec = function() db().windowScale = math.max(0.6, (tonumber(db().windowScale) or 1) - 0.1); ns.placeWindow() end,
      inc = function() db().windowScale = math.min(1.6, (tonumber(db().windowScale) or 1) + 0.1); ns.placeWindow() end },
    { kind = "stepper", label = "Window height", text = function() return ns.windowHeight() .. " px" end,
      dec = function() db().windowHeight = math.max(ns.WINDOW_MIN_H, ns.windowHeight() - 80); ns.placeWindow() end,
      inc = function() db().windowHeight = ns.windowHeight() + 80; ns.placeWindow() end },
    { kind = "buttons",
      { label = "Auto height", run = function() db().windowHeight = nil; ns.placeWindow() end,
        tip = "The default: the Journey book fills the screen, the other tabs keep " .. ns.WINDOW_H .. " px." },
      { label = "Fit the screen", run = function() db().windowHeight = ns.WINDOW_FIT; ns.placeWindow() end,
        tip = "Every tab as tall as your screen allows." },
      { label = "Short", run = function() db().windowHeight = ns.WINDOW_H; ns.placeWindow() end,
        tip = "Every tab " .. ns.WINDOW_H .. " px tall." } },
    { kind = "buttons",
      { label = "Reset window position", width = 200, run = function() db().windowPos = nil; ns.placeWindow() end },
      { label = "Open the Codex", width = 160, run = function() O.closePanel(); ns.toggleWindow() end,
        tip = "Opens the Codex window (/codex). Its Settings tab holds these same settings." } },
  })

  local Q = ns.quests
  add("Questing", "QUEST GUIDE", {
    onKey("Plan every dungeon run", "questDungeons",
      "Every dungeon's quest pickups join your route (such as the Deadmines run in Westfall). Quests > Guides > Dungeons plans runs one by one, which overrides this.", questSettings),
    onKey("Keep grey quests in the route", "questKeepGrey",
      "Off: pickups that have gone grey for your level leave the route (unless a later quest needs them) and are listed under Quests > Missed quests > Outleveled.", questSettings),
    onKey("Show optional quests", "questOptional",
      "Side errands the route can skip, such as Forever's Camping 101 profession introductions.", questSettings),
    { kind = "choice", label = "Elite quests", labels = Q.ELITE_LABELS, tips = Q.ELITE_TIPS,
      get = function() return Q.eliteModeIndex() end,
      set = function(i) Q.setEliteMode(i); ns.updateQuestSettings() end },
    onKey("Skip hearthstone binding steps", "questSkipBind",
      "Keep your hearthstone where it is. Bind steps tick off by themselves when your hearthstone is already set to that inn; hearth steps say where yours is set.", questSettings),
    offKey("Play a sound when a step completes", "questNoSound"),
    offKey("Show class quests", "noClassQuests",
      "Your class's quest chains (pets, forms, totems, class spells) as their own sections in the Quests tab.", questSettings),
  })
  add("Questing", "QUEST ITEM BUTTON", questButton("item", "Quest item", "Show the quest item button", "noQuestItem",
    "Use the current step's quest item."))
  add("Questing", "TARGET BUTTON", questButton("target", "Target", "Show the target button", "noQuestTarget",
    "Target the step's quest giver or creatures. Key Bindings > AddOns can give it a key."))
  add("Questing", "QUEST HELPERS", {
    onKey("Auto-accept the current guide quest", "questAutoAccept",
      "Off by default, so you can read each quest. On: accepts only the guide's current quest, also from an NPC's gossip list. Hold Alt to stop it."),
    { kind = "note", text = function()
        return ns.questSupport.autoAccept() and "Your quest tracker's auto-accept is on and handles quest pickups." or nil
      end },
    onKey("Auto-turn in the current guide quest", "questAutoTurnin",
      "Off by default. On: turns in only the guide's current quest, out of combat, when there is no reward to choose. Hold Alt to stop it."),
    { kind = "note", text = function()
        return ns.questSupport.autoComplete() and "Your quest tracker's auto-complete is on and handles quest turn-ins." or nil
      end },
    offKey("Mark the best-selling quest reward", "noRewardHint",
      "When a quest offers a choice of rewards, a coin marks the one that sells for the most and chat names it. The Codex never picks a reward for you."),
    offKey("Loot tooltip advice", "noLootHints", "Compare equipment against your current gear with your selected loot profile."),
    offKey("Mark gear upgrade rewards", "noLootRewards", "A plus marks the strongest conclusive gear upgrade. Vendor value keeps its separate coin mark."),
    offKey("Show loot target tracker", "noLootTracker", "A small panel lists your tracked items. Drag it to move it.",
      function() if ns.loot then ns.loot.refreshTracker() end end),
    onKey("Loot notifications", "lootNotifications", "Off by default. Announce obtained targets and conclusively new bag upgrades once."),
    offKey("Open a dungeon's guide when you enter it", "noDungeonOpen",
      "Zoning into a dungeon the Codex has a guide for switches the step window to it, boss by boss. Return to leveling takes you back."),
    offKey("Plan trips through flight masters", "noFlightPlans",
      "For a long trip the arrow leads to a flight master when flying is quicker, and the flight map marks the flight to take.", questRefresh),
    offKey("Lead me to flight paths I don't have", "noFlightLearn",
      "When a flight master you haven't talked to is close to the way, the arrow stops there first so you learn the flight path.", questRefresh),
    onKey("Auto-fly: take the guide's flights and binds", "questAutoTravel",
      "Off by default. On: at a flight master the Codex takes the flight the guide marks, and at the step's innkeeper during a bind step it picks the bind option (accept the game's popup yourself). Hold Alt to stop it."),
  })

  add("Map and arrow", "ARROW AND PORTRAIT", {
    offKey("Show the quest arrow", "noQuestArrow", nil, questRefresh),
    offKey("Show the NPC portrait", "noQuestPortrait",
      "A small 3D portrait of the quest giver, the one you turn in to, or the creature to hunt, beside the step's title.", questRefresh),
    offKey("Colour the arrow by direction", "noArrowColor",
      "Green when you're heading for the step, gold when it's off to your side, red when it's behind you.", questRefresh),
    offKey("Animate the arrow on arrival", "noArrowBounce",
      "When you reach the step's spot, the arrow turns into the step's icon, bobbing gently over a gold ring that pulses once."),
    onKey("Lock the arrow", "questArrowLocked",
      "Drag the arrow to put it anywhere on screen; Ctrl+mouse wheel over it changes its size. Locked, it stays where it is."),
    { kind = "stepper", label = "Arrow size", text = function() return pct(db().questArrowScale) end,
      dec = function()
        db().questArrowScale = math.floor(math.max(0.6, math.min(2, (tonumber(db().questArrowScale) or 1) - 0.1)) * 10 + 0.5) / 10
        ns.placeQuestArrow()
      end,
      inc = function()
        db().questArrowScale = math.floor(math.max(0.6, math.min(2, (tonumber(db().questArrowScale) or 1) + 0.1)) * 10 + 0.5) / 10
        ns.placeQuestArrow()
      end },
    { kind = "buttons", { label = "Reset arrow", run = function()
        db().questArrowPos, db().questArrowScale = nil, nil
        ns.placeQuestArrow()
      end, tip = "Puts the arrow back above the step window at its normal size." } },
    (function()
      local item = offKey("Point the arrow at the nearest objective", "noNearestSpawn",
        "Near a kill or collect step's camp, the arrow leads to the closest mob or object you still need using your installed quest-data provider.", questRefresh)
      item.shown = function() return ns.questSupport.usable() end
      return item
    end)(),
    offKey("Track the step's quest in the quest tracker", "noQuestWatch",
      "Adds the current step's quest to the game's objective tracker. Quests you track yourself are left alone.", questRefresh),
    offKey("Warn about elites and rares near the step", "noDangerWarnings",
      "The step window names hostile elites and rares close to the current step until you outlevel them.", questRefresh),
  })
  add("Map and arrow", "STEP WINDOW AND MAP", {
    { kind = "stepper", label = "Steps shown ahead", text = function() return tostring(ns.questPreviewCount()) end,
      dec = function() ns.setQuestPreview(ns.questPreviewCount() - 1) end,
      inc = function() ns.setQuestPreview(ns.questPreviewCount() + 1) end,
      tip = "How many of the next steps the step window lists under the current one (0-10)." },
    offKey("Pin the current step on the map", "noQuestMapPin",
      "Puts the game's own map waypoint on the current step. A waypoint you placed yourself is never replaced.", questRefresh),
    offKey("Show the completion bar", "noStepBar",
      "A thin bar under the step's title fills as you get through the guide; hover it for the counts, click it for the route.", questRefresh),
    offKey("Show steps on the minimap", "noMinimapSteps",
      "The current step's icon on the minimap (an arrow on its edge when it's farther), and small numbered pins for the next two steps.", questRefresh),
    offKey("Show steps on the world map", "noWorldMapSteps", "Pins for the current step and the next two on your world map.", questRefresh),
    offKey("Route line on the minimap", "noMinimapLine", "Gold dots on the minimap run from you to the current step."),
    offKey("Route line on the world map", "noWorldMapLine", "The same gold dots on your world map, on the map you're on.", questRefresh),
    onKey("Lock the quest step window", "questLocked"),
    { kind = "stepper", label = "Step window size", text = function() return pct(db().questViewerScale) end,
      dec = function() ns.setQuestViewerScale(-0.1) end, inc = function() ns.setQuestViewerScale(0.1) end,
      tip = "Ctrl+mouse wheel over the step window also changes its size." },
    { kind = "stepper", label = "Step window background", text = function() return pct(db().questViewerAlpha) end,
      dec = function() ns.setQuestViewerAlpha(-0.1) end, inc = function() ns.setQuestViewerAlpha(0.1) end },
    offKey("Fade the step window in combat", "noQuestFade",
      "In combat the step window drops to 30% so it's out of your way; the mouse over it brings it back."),
    onKey("Compact step window", "questCompact",
      "Only the step's title, a thin progress bar and the buttons: for small screens.", questRefresh),
  })

  local pingLabels = {}
  for i, sound in ipairs(ns.PARTY_PINGS or {}) do pingLabels[i] = sound[1] end
  add("Group", "PARTY", {
    offKey("Show my party's steps", "noPartySteps",
      "The step window lists your party: who is on your step, how many steps ahead or behind the others are. Party members need the Codex to share theirs.", questRefresh),
    { kind = "check", label = "Share guide quests with my party",
      tip = "On by default. When you accept a quest from your guide, the Codex offers it to party members who don't have it yet.",
      get = function() return ns.questSharing() end, set = function() ns.toggleQuestSharing() end },
    onKey("Say my flights in party chat", "questAnnounceFlights",
      "Off by default. Taking a flight says where you're flying in party chat, with the time once that flight has been timed."),
    onKey("Say steps I finish in party chat", "questAnnounceSteps",
      "Off by default. Accepted quests, finished objectives and turn-ins. Next and Back stay quiet."),
    onKey("Say quest items I pick up", "questAnnounceItems",
      "Off by default. Quest loot goes to party chat with your progress count and quest link."),
    onKey("Say quest progress in party chat", "questAnnounceProgress",
      "Off by default. Finished objectives and quests ready to turn in. At most a line a second, never in a raid."),
    offKey("Ping when the party is together on my step", "noPartyPing",
      "A sound when the last party member reaches your step (or you reach theirs)."),
    { kind = "choice", label = "Ping sound", labels = pingLabels,
      tips = { "A quiet chime (the game's friend-online sound).", "The game's party invite sound.", "The game's ready-check sound: the loudest." },
      get = function() return ns.partyPingIndex() end,
      set = function(i) db().partyPingSound = i; ns.playPartyPing(i) end },
    { kind = "buttons", { label = "Preview quest announcements", width = 240, run = function() ns.previewQuestAnnouncements() end,
      tip = "Show sample icons, links and progress privately. Nothing is sent to the party." } },
    { kind = "note", text = function()
        if ns.questSupport.announces("objectives") or ns.questSupport.announces("items") then
          return "Your quest tracker already announces finished objectives and quest-starting items, so the Codex avoids repeating them."
        end
      end },
  })

  add("Helpers", "TALENT WINDOW GUIDE", {
    offKey("Trace my talent in the talent window", "noTalentGuide",
      "When you have a talent point to spend and open your talent window, the Codex traces the talent to take and shows a card above the window."),
  })
  add("Helpers", "TRAINERS", {
    offKey("Show what to train at my class trainer", "noTrainerGuide",
      "At your class trainer, a card lists the guide's spells you can learn now and what they cost. The Codex never buys anything for you."),
    offKey("Show what to learn at profession trainers", "noProfTrainer",
      "At a profession trainer, a card lists the next rank when you can train it and the recipes your route needs from this trainer."),
  })
  add("Helpers", "PROFESSIONS", {
    offKey("Show profession hints", "noCraftGuide",
      "Show your current step in the profession windows. Crafting hints outline the recommended recipe."),
    offKey("Profession skill-up cards", "noProfCards",
      "Shows a card for new steps, training or skill caps in every profession the Codex guides."),
  })
  add("Helpers", "GATHERING", {
    offKey("Keep Find Herbs / Find Minerals on", "noAutoTrack",
      "WoW: Forever turns gathering tracking off when you log in, zone or die. The Codex turns the one you had back on (out of combat).",
      function() if not db().noAutoTrack then ns.restoreTracking() end end),
  })
  add("Helpers", "VENDOR", {
    offKey("Sell grey items at vendors", "noAutoSell",
      "When you open a vendor, grey items with a sell price are sold one by one. Items a guide step needs and your Hearthstone are kept. Hold Alt to stop it."),
    offKey("Repair at vendors", "noAutoRepair",
      "Repairs all your gear with your own money when you open a vendor that repairs. Hold Alt to stop it."),
    offKey("Show what to buy for the guide", "noShopCard",
      "At a vendor, a card lists items your coming steps need that this vendor sells, with one button to buy them."),
    offKey("Include profession supplies", "noProfShop",
      "The card also lists the thread, vials, flux, dye, spices, tools and rods your current profession steps need."),
  })
  add("Helpers", "MAILBOX", {
    offKey("Show Take all at the mailbox", "noMailCard",
      "At a mailbox, a card shows the items and gold in your inbox with one button that takes them all. Cash on Delivery mail is left for you."),
    onKey("Take all as the mailbox opens", "mailAutoTake",
      "Empties your inbox by itself every time you open a mailbox (Cash on Delivery mail is left alone). Click Stop on the card to stop it."),
  })
  add("Helpers", "PRICE SHARING", {
    { kind = "check", label = "Share auction prices with other Codex users",
      tip = "Your auction house scans go out over a hidden channel, and other Codex users' prices keep your tooltips and deals fresh. Your own scans always win.",
      shown = function() return ns.auctionShare ~= nil end,
      get = function() return ns.auctionShare.on() end,
      set = function() ns.auctionShare.setOn(not ns.auctionShare.on()) end },
    { kind = "note", shown = function() return ns.auctionShare ~= nil end,
      text = function()
        local ok, lines = pcall(ns.auctionShare.fieldLines)
        return ok and type(lines) == "table" and #lines > 0 and table.concat(lines, "\n") or nil
      end },
  })
  return list
end

----------------------------------------------------------------------------
-- Drawing a page
----------------------------------------------------------------------------

local A -- ns.art, read when a page is first built
local LABEL_W, ROW = 170, 30

local function fontString(parent, template, r, g, b)
  local fs = parent:CreateFontString(nil, "OVERLAY", template)
  fs:SetJustifyH("LEFT")
  if r then fs:SetTextColor(r, g, b) end
  return fs
end

local function textOf(v) if type(v) == "function" then return v() end return v end

local function stringHeight(fs)
  local h = fs.GetStringHeight and tonumber(fs:GetStringHeight())
  return (h and h > 0) and h or 14
end

-- Makes the widgets for one item (once); item.draw(y) places and updates them, returns the height.
local function makeItem(page, item)
  local parent = page.content
  local function changed() O.changed() end
  if item.kind == "check" then
    local cb = A.check(parent)
    cb:SetLabel(item.label)
    cb.codexLabel = item.label
    cb.tipTitle, cb.tipText = item.label, item.tip
    cb:SetScript("OnClick", function() item.set(); changed() end)
    item.widgets = { cb }
    item.draw = function(y)
      cb:ClearAllPoints()
      cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
      cb:SetLook(item.get() and true or false)
      return 28
    end
  elseif item.kind == "choice" then
    local label = fontString(parent, "GameFontHighlight")
    item.widgets, item.buttons = { label }, {}
    item.draw = function(y)
      local labels = textOf(item.labels) or {}
      label:ClearAllPoints()
      label:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -(y + 5))
      label:SetText(item.label)
      local n = math.max(1, #labels)
      local each = math.floor((O.WIDTH - LABEL_W - (n - 1) * 4) / n)
      local lit = item.get()
      for i = 1, math.max(#labels, #item.buttons) do
        local b = item.buttons[i]
        if not b and labels[i] then
          b = A.button(parent, each, 24)
          b:SetScript("OnClick", function() item.set(i); changed() end)
          item.buttons[i] = b
          item.widgets[#item.widgets + 1] = b
        end
        if b then
          if labels[i] then
            b:SetLabel(labels[i])
            b.codexLabel = labels[i]
            b.codexOn = (i == lit) or nil
            b.tipTitle, b.tipText = labels[i], item.tips and item.tips[i]
            b:SetSize(each, 24)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_W + (i - 1) * (each + 4), -y)
            b:SetLook(i == lit)
            b:Show()
          else
            b:Hide()
          end
        end
      end
      return ROW
    end
  elseif item.kind == "stepper" then
    local label = fontString(parent, "GameFontHighlight")
    local value = fontString(parent, "GameFontNormal")
    value:SetJustifyH("CENTER")
    local minus, plus = A.button(parent, 28, 24), A.button(parent, 28, 24)
    minus:SetLabel("-"); plus:SetLabel("+")
    minus.codexLabel, plus.codexLabel = item.label .. " -", item.label .. " +"
    minus.tipTitle, minus.tipText = item.label, item.tip
    plus.tipTitle, plus.tipText = item.label, item.tip
    minus:SetScript("OnClick", function() item.dec(); changed() end)
    plus:SetScript("OnClick", function() item.inc(); changed() end)
    item.widgets = { label, value, minus, plus }
    item.draw = function(y)
      label:ClearAllPoints(); label:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -(y + 5))
      label:SetText(item.label)
      minus:ClearAllPoints(); minus:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_W, -y)
      value:ClearAllPoints(); value:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_W + 32, -(y + 5))
      value:SetWidth(70)
      value:SetText(tostring(item.text()))
      plus:ClearAllPoints(); plus:SetPoint("TOPLEFT", parent, "TOPLEFT", LABEL_W + 106, -y)
      return ROW
    end
  elseif item.kind == "buttons" then
    item.widgets = {}
    for i, def in ipairs(item) do
      local b = A.button(parent, def.width or 150, 24)
      b:SetScript("OnClick", function() def.run(); changed() end)
      b.tipText = def.tip
      item.widgets[i] = b
    end
    item.draw = function(y)
      local x = 0
      for i, def in ipairs(item) do
        local b, text = item.widgets[i], textOf(def.label)
        b:SetLabel(text)
        b.codexLabel, b.tipTitle = text, text
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
        x = x + (def.width or 150) + 6
      end
      return ROW
    end
  else -- note
    local fs = fontString(parent, "GameFontHighlightSmall", 0.7, 0.7, 0.7)
    fs:SetWidth(O.WIDTH - 28)
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    item.widgets = { fs }
    item.draw = function(y)
      local text = item.text()
      if not text or text == "" then fs:Hide(); return 0 end
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 28, -y)
      fs:SetText(text)
      fs:Show()
      return stringHeight(fs) + 6
    end
  end
end

-- Places every item of the page from the top and reads each control's value again.
local function layout(page)
  if not page.built then return end
  local y = 0
  for _, section in ipairs(page.sections) do
    local shownAny = false
    for _, item in ipairs(section.items) do
      if not item.shown or item.shown() then shownAny = true end
    end
    section.head:SetShown(shownAny)
    if shownAny then
      section.head:ClearAllPoints()
      section.head:SetPoint("TOPLEFT", page.content, "TOPLEFT", 0, -y)
      y = y + 22
      for _, item in ipairs(section.items) do
        local on = not item.shown or item.shown()
        for _, w in ipairs(item.widgets) do w:SetShown(on) end
        if on then
          local ok, h = pcall(item.draw, y)
          if ok then y = y + (h or 0) else O.lastError = tostring(h) end
        end
      end
      y = y + 12
    end
  end
  page.content:SetHeight(math.max(1, y))
end

local function build(page)
  if page.built then return end
  A = ns.art
  local panel = page.panel
  local title = fontString(panel, "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
  title:SetText(page.name == "General" and O.NAME or (O.NAME .. " - " .. page.name))
  local sub = fontString(panel, "GameFontHighlightSmall", 0.75, 0.75, 0.75)
  sub:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -40)
  sub:SetWidth(O.WIDTH)
  sub:SetText("The same settings as the Settings tab in the Codex window (/codex). A change in either place shows in both.")
  local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  if not ok or not scroll then scroll = CreateFrame("ScrollFrame", nil, panel) end
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -66)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 8)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(O.WIDTH, 1)
  scroll:SetScrollChild(content)
  if scroll.EnableMouseWheel then scroll:EnableMouseWheel(true) end
  if not scroll.ScrollBar then -- the plain frame scrolls by the wheel alone
    scroll:SetScript("OnMouseWheel", function(self, delta)
      local most = math.max(0, (tonumber(content:GetHeight()) or 0) - (tonumber(self:GetHeight()) or 0))
      self:SetVerticalScroll(math.max(0, math.min(most, (tonumber(self:GetVerticalScroll()) or 0) - delta * 40)))
    end)
  end
  page.scroll, page.content = scroll, content
  page.sections = {}
  for _, section in ipairs(sections()) do
    if section.page == page.name then
      section.head = fontString(content, "GameFontNormal")
      section.head:SetText(section.title)
      for _, item in ipairs(section.items) do makeItem(page, item) end
      page.sections[#page.sections + 1] = section
    end
  end
  page.built = true
end

----------------------------------------------------------------------------
-- Registering the pages
----------------------------------------------------------------------------

O.pages = {}

-- A change made here: every shown page reads its controls again, and the Codex's tab redraws.
function O.changed()
  for _, page in ipairs(O.pages) do
    if page.panel:IsShown() then layout(page) end
  end
  if ns.refreshTab then ns.refreshTab("settings") end
end

-- Redraws shown pages (a change from the Codex's own tab, a slash command or Ctrl+wheel).
function O.refresh()
  for _, page in ipairs(O.pages) do
    if page.panel:IsShown() then layout(page) end
  end
end

local function newPage(name)
  local panel = CreateFrame("Frame")
  panel:Hide()
  panel.name = name == "General" and O.NAME or name
  local page = { name = name, panel = panel }
  panel.codexPage = name
  local since = 0
  panel:SetScript("OnShow", function()
    build(page)
    layout(page)
    since = 0
  end)
  panel:SetScript("OnUpdate", function(_, elapsed)
    since = since + (tonumber(elapsed) or 0)
    if since >= 0.5 then since = 0; layout(page) end
  end)
  O.pages[#O.pages + 1] = page
  return page
end

function O.closePanel()
  for _, name in ipairs({ "SettingsPanel", "InterfaceOptionsFrame" }) do
    local f = _G[name]
    if f and f.IsShown and f:IsShown() and HideUIPanel then pcall(HideUIPanel, f) end
  end
end

function ns.startOptions()
  if O.started then return end
  O.started = true
  local main = newPage("General")
  local subs = {}
  for i = 2, #O.PAGES do subs[#subs + 1] = newPage(O.PAGES[i]) end
  if Settings and Settings.RegisterCanvasLayoutCategory then
    local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, main.panel, O.NAME)
    if ok and category then
      O.category = category
      if Settings.RegisterAddOnCategory then pcall(Settings.RegisterAddOnCategory, category) end
      for _, page in ipairs(subs) do
        if Settings.RegisterCanvasLayoutSubcategory then
          local sok, subcategory = pcall(Settings.RegisterCanvasLayoutSubcategory, category, page.panel, page.name)
          if sok then page.category = subcategory end
        end
      end
      O.how = "settings"
    end
  end
  if not O.how and InterfaceOptions_AddCategory then
    local ok = pcall(InterfaceOptions_AddCategory, main.panel)
    if ok then
      for _, page in ipairs(subs) do
        page.panel.parent = O.NAME
        pcall(InterfaceOptions_AddCategory, page.panel)
      end
      O.how = "interface options"
    end
  end
  O.how = O.how or "none"
end

-- Opens the game's Options at the Codex (a page name opens that subcategory).
function O.open(name)
  if InCombatLockdown and InCombatLockdown() then
    ns.say("the game's Options open after combat.")
    return false
  end
  local page = O.pages[1]
  for _, p in ipairs(O.pages) do if p.name == name then page = p end end
  if O.how == "settings" and Settings and Settings.OpenToCategory then
    local category = page.category or O.category
    local id = category and category.GetID and category:GetID()
    local ok = pcall(Settings.OpenToCategory, id or category)
    if ok then return true end
  elseif O.how == "interface options" and InterfaceOptionsFrame_OpenToCategory then
    pcall(InterfaceOptionsFrame_OpenToCategory, page.panel)
    pcall(InterfaceOptionsFrame_OpenToCategory, page.panel) -- the old panel needs it twice
    return true
  end
  ns.say("the game's Options don't list addons on this client: every setting is in /codex > Settings.")
  return false
end

function ns.optionsDebugLines()
  return { "game options: " .. tostring(O.how or "not registered") .. (O.lastError and (", last error: " .. O.lastError) or "") }
end
