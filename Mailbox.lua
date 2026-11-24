-- Mailbox.lua: Take all at the mailbox.
-- A small card beside the mail window ("MAILBOX": how many mails hold items and gold, your free bag
-- slots) with one button, Take all, that empties the inbox one action at a time: a mail's money
-- (TakeInboxMoney), then its attachments (TakeInboxItem). It works from the last mail up, so taking
-- one never moves the mails still to do, and waits for the server to answer each take (the mail's
-- money, items or the inbox count changes; 2 s at most) plus a short gap before the next one.
-- Never takes Cash on Delivery mail (that would pay for it) or GM mail. With no free bag slot it
-- stops taking items but still takes the gold; "Inventory is full" stops it the same way.
-- Items from an expired or cancelled auction are tagged RELIST for Quick Sell (AuctionTrade.lua).
-- Key binding: CLICK LevelingCodexMailTakeAll:LeftButton (a controller button can take all too).
-- Settings > Helpers > MAILBOX: the card (db.noMailCard) and taking all as the mailbox opens
-- (db.mailAutoTake, off).
local _, ns = ...
local Q = ns.quests
local M = {}
ns.mailbox = M
local function try(...) return Q.try(...) end

M.GAP = 0.15        -- seconds between one answered take and the next
M.WAIT = 2          -- seconds to wait for the server before trying again
M.TRIES = 2         -- takes of the same thing before the mail is passed over
M.ATTACHMENTS = 16  -- ATTACHMENTS_MAX_RECEIVE

local card, place = nil, {}
local mailOpen = false
local run = nil      -- the Take all in progress
local last = nil     -- what the last run did (debug)
local stats = { runs = 0, took = 0, money = 0 }

local function isOpen()
  if not mailOpen then return false end
  local f = MailFrame
  if type(f) == "table" and type(f.IsShown) == "function" then return f:IsShown() and true or false end
  return true
end

local function canTake()
  return type(GetNumInboxItems) == "function" and type(GetInboxHeaderInfo) == "function"
    and type(TakeInboxMoney) == "function" and type(TakeInboxItem) == "function"
end

-- One mail's header: money, COD, items attached, GM, subject.
local function header(i)
  local ok, _, _, sender, subject, money, cod, _, itemCount, _, _, _, _, gm = pcall(GetInboxHeaderInfo, i)
  if not ok or (sender == nil and subject == nil) then return nil end
  return { sender = sender, subject = subject, money = tonumber(money) or 0, cod = tonumber(cod) or 0,
    items = tonumber(itemCount), gm = gm and true or false }
end

local function inboxCount()
  local shown, total = try(GetNumInboxItems)
  shown = tonumber(shown) or 0
  return shown, tonumber(total) or shown
end

-- The attachment in slot a: name, item ID, count (nil when the slot is empty).
local function attachment(i, a)
  local name, id, _, count = try(GetInboxItem, i, a)
  if type(id) ~= "number" then -- older clients: name, texture, count, quality, canUse
    local _, _, c = try(GetInboxItem, i, a)
    id, count = nil, c
  end
  local link = try(GetInboxItemLink, i, a)
  if type(link) == "string" then
    id = id or tonumber(link:match("item:(%d+)"))
    name = name or link:match("%[(.-)%]")
  end
  if not name and not id then return nil end
  return name, id, tonumber(count) or 1
end

local function attachments(i, h)
  local list = {}
  if h.items == 0 then return list end
  for a = 1, M.ATTACHMENTS do
    local name, id, count = attachment(i, a)
    if name or id then list[#list + 1] = { slot = a, name = name, id = id, count = count } end
  end
  return list
end

-- Free slots in your normal bags (0-4); nil when the client can't say.
function M.freeSlots()
  local free, known = 0, false
  for bag = 0, (tonumber(NUM_BAG_SLOTS) or 4) do
    local n, kind
    if type(C_Container) == "table" and type(C_Container.GetContainerNumFreeSlots) == "function" then
      n, kind = try(C_Container.GetContainerNumFreeSlots, bag)
    elseif type(GetContainerNumFreeSlots) == "function" then
      n, kind = try(GetContainerNumFreeSlots, bag)
    end
    if tonumber(n) then
      known = true
      if not kind or kind == 0 then free = free + tonumber(n) end
    end
  end
  return known and free or nil
end

-- What the inbox holds now: mails with something to take, their gold and items; COD mails apart.
function M.summary()
  local s = { mails = 0, money = 0, items = 0, cod = 0, shown = 0, total = 0 }
  if not canTake() then return s end
  s.shown, s.total = inboxCount()
  for i = 1, s.shown do
    local h = header(i)
    if h and not h.gm then
      if h.cod > 0 then
        if (h.items or 0) > 0 then s.cod = s.cod + 1 end
      else
        local n = h.items
        if n == nil then n = #attachments(i, h) end
        if h.money > 0 or n > 0 then
          s.mails, s.money, s.items = s.mails + 1, s.money + h.money, s.items + n
        end
      end
    end
  end
  return s
end

-- "Auction expired: X" / "Auction cancelled: X": items coming back from the auction house.
local function returnedFromAuction(subject)
  if type(subject) ~= "string" then return false end
  for _, g in ipairs({ "AUCTION_EXPIRED_MAIL_SUBJECT", "AUCTION_REMOVED_MAIL_SUBJECT" }) do
    local f = _G[g]
    if type(f) == "string" and f:find("%s", 1, true) then
      local prefix = f:sub(1, (f:find("%s", 1, true)) - 1)
      if prefix ~= "" and subject:sub(1, #prefix) == prefix then return true end
    end
  end
  local low = subject:lower()
  return low:find("^auction expired") ~= nil or low:find("^auction cancel") ~= nil
end

local function markRelist(id)
  local T = ns.auctionTrade
  if not (id and T and T.notes) then return false end
  local ok, notes = pcall(T.notes)
  if not ok or type(notes) ~= "table" or type(notes.relist) ~= "table" then return false end
  notes.relist[id] = tonumber(time and time()) or 0
  return true
end

local refreshCard

local function sayDone(why)
  local r = run
  if not r then return end
  run = nil
  stats.runs = stats.runs + 1
  stats.took, stats.money = stats.took + r.items, stats.money + r.money
  local parts = {}
  if r.items > 0 then parts[#parts + 1] = r.items .. (r.items == 1 and " item" or " items") end
  if r.money > 0 then parts[#parts + 1] = ns.money(r.money) end
  local line
  if #parts == 0 then line = "Nothing to take from the mailbox."
  else line = "Took " .. table.concat(parts, " and ") .. " from " .. r.mails .. (r.mails == 1 and " mail." or " mails.") end
  if why == "closed" then line = line .. " (the mailbox closed)"
  elseif why == "stopped" then line = line .. " (stopped)" end
  if r.full then r.left = M.summary().items end
  if r.full and r.left > 0 then line = line .. " Your bags are full: " .. r.left .. (r.left == 1 and " item stays" or " items stay") .. " in the mail." end
  if r.relist > 0 then
    line = line .. " " .. r.relist .. (r.relist == 1 and " item" or " items") .. " came back from the auction house: Quick Sell marks them RELIST."
  end
  if r.cod > 0 then line = line .. " Left " .. r.cod .. " Cash on Delivery " .. (r.cod == 1 and "mail" or "mails") .. " for you to pay." end
  if why == "done" then
    local shown, total = inboxCount()
    if total > shown then
      line = line .. " " .. (total - shown) .. " more " .. ((total - shown) == 1 and "mail waits" or "mails wait")
        .. " on the server: the mailbox shows them within a minute, then click Take all again."
    end
  end
  ns.say(line)
  last = { why = why, items = r.items, money = r.money, mails = r.mails, full = r.full, relist = r.relist,
    skipped = r.skipped, actions = r.actions }
  if refreshCard then refreshCard() end
end

-- A mail's state, to see when the server has answered a take.
local function signature(i)
  local h = header(i)
  local shown = inboxCount()
  if not h then return "gone:" .. shown end
  return table.concat({ shown, h.money, h.items or -1, h.subject or "" }, ":")
end

local step

local function waitFor(i, what)
  local r = run
  r.waiting = { i = i, sig = signature(i), at = GetTime and GetTime() or 0, what = what }
  r.actions = r.actions + 1
  local poll
  poll = function()
    if run ~= r or not r.waiting then return end
    if not isOpen() then sayDone("closed"); return end
    local w = r.waiting
    if signature(w.i) ~= w.sig then
      -- answered: count it, then the next take after a short gap
      if w.what.kind == "money" then r.money = r.money + w.what.amount
      else
        r.items = r.items + 1
        if w.what.relist and markRelist(w.what.id) then r.relist = r.relist + 1 end
      end
      if not r.mailsSeen[w.i .. ":" .. (w.what.mail or "")] then
        r.mailsSeen[w.i .. ":" .. (w.what.mail or "")] = true
        r.mails = r.mails + 1
      end
      r.waiting, r.tries = nil, 0
      ns.after(M.GAP, step)
      return
    end
    local now = GetTime and GetTime() or 0
    if now - w.at >= M.WAIT then
      r.waiting = nil
      r.tries = r.tries + 1
      if r.tries >= M.TRIES then
        -- the server won't give it (a unique item you have, a full stack...): pass this mail over
        r.skipped = r.skipped + 1
        r.i, r.tries = r.i - 1, 0
      end
      ns.after(M.GAP, step)
      return
    end
    ns.after(0.1, poll)
  end
  ns.after(0.1, poll)
end

step = function()
  local r = run
  if not r or r.waiting then return end
  if not isOpen() then sayDone("closed"); return end
  local shown = inboxCount()
  if r.i > shown then r.i = shown end
  while r.i >= 1 do
    local i = r.i
    local h = header(i)
    if h and not h.gm and h.cod > 0 then
      -- keyed by the mail, not its index: taking a mail below it away moves it down one
      local key = (h.sender or "") .. "|" .. (h.subject or "") .. "|" .. h.cod
      if (h.items or 0) > 0 and not r.codSeen[key] then r.codSeen[key] = true; r.cod = r.cod + 1 end
    elseif h and not h.gm then
      local key = (h.sender or "") .. "|" .. (h.subject or "")
      if h.money > 0 then
        pcall(TakeInboxMoney, i)
        waitFor(i, { kind = "money", amount = h.money, mail = key })
        return
      end
      local list = attachments(i, h)
      if #list > 0 then
        local free = M.freeSlots()
        if free ~= nil and free <= 0 or r.full then
          r.full = true
        else
          local it = list[1]
          pcall(TakeInboxItem, i, it.slot)
          waitFor(i, { kind = "item", id = it.id, relist = returnedFromAuction(h.subject), mail = key })
          return
        end
      end
    end
    r.i = r.i - 1
  end
  sayDone("done")
end

-- Take all (or stop the run going on).
function M.takeAll()
  if run then sayDone("stopped"); return "stopped" end
  if not isOpen() then ns.say("Open a mailbox first: Take all empties your inbox."); return "closed" end
  if not canTake() then ns.say("This client doesn't let add-ons take mail."); return "unsupported" end
  local shown = inboxCount()
  run = { i = shown, tries = 0, items = 0, money = 0, mails = 0, mailsSeen = {}, codSeen = {}, cod = 0,
    full = false, left = 0, relist = 0, skipped = 0, actions = 0 }
  if refreshCard then refreshCard() end
  step()
  return "started"
end

function M.running() return run ~= nil end

-- The card ------------------------------------------------------------------------------------

local function makeCard()
  local A = ns.art
  local h = A.frame("Frame", "LevelingCodexMailCard", UIParent)
  h:SetSize(240, 84)
  h:SetFrameStrata("FULLSCREEN_DIALOG")
  h:SetClampedToScreen(true)
  h:EnableMouse(true)
  h:Hide()
  A.cardChrome(h)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  h.label:SetPoint("TOPLEFT", 12, -10)
  h.label:SetText("MAILBOX")
  h.line = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.line:SetPoint("TOPLEFT", 12, -26)
  h.line:SetWidth(216)
  h.line:SetJustifyH("LEFT")
  h.sub = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  h.sub:SetPoint("TOPLEFT", 12, -40)
  h.sub:SetWidth(216)
  h.sub:SetJustifyH("LEFT")
  h.take = A.button(h, 216, 22)
  h.take:SetPoint("BOTTOMLEFT", 12, 10)
  h.take:SetScript("OnClick", function() M.takeAll() end)
  h.take.tipTitle = "Take all"
  h.take.tip = "Takes the gold and items from every mail, one at a time. Cash on Delivery mail is left for you. Click again to stop. Key binding: Esc > Options > Keybindings > AddOns."
  -- Like the vendor card, never attached to the controller (it would take the focus from the mail
  -- window): a controller uses the key binding.
  return h
end

local function hideCard()
  if card then card:Hide() end
  place.edgeRoot = nil
end

refreshCard = function()
  if ns.db().noMailCard or not isOpen() or not canTake() then hideCard(); return end
  local s = M.summary()
  if s.mails == 0 and not run and s.cod == 0 and s.total <= s.shown then hideCard(); return end
  if not card then card = makeCard() end
  ns.art.paintCard(card)
  local parts = {}
  if s.items > 0 then parts[#parts + 1] = s.items .. (s.items == 1 and " item" or " items") end
  if s.money > 0 then parts[#parts + 1] = ns.money(s.money) end
  if #parts == 0 then card.line:SetText("Nothing to take.")
  else card.line:SetText(Q.plain(s.mails .. (s.mails == 1 and " mail: " or " mails: ") .. table.concat(parts, ", "))) end
  local free = M.freeSlots()
  local sub = {}
  if free then sub[#sub + 1] = free .. (free == 1 and " free bag slot" or " free bag slots") end
  if s.cod > 0 then sub[#sub + 1] = s.cod .. " COD left alone" end
  if s.total > s.shown then sub[#sub + 1] = (s.total - s.shown) .. " more on the server" end
  card.sub:SetText(table.concat(sub, ", "))
  local label = run and ("Stop (" .. run.items .. " taken)") or "Take all"
  card.take:SetLabel(label)
  card.take.codexLabel = run and "Stop" or "Take all"
  card.take:SetShown(run ~= nil or s.mails > 0)
  local root = MailFrame
  if type(root) == "table" and type(root.IsShown) == "function" then
    ns.placeByWindow(card, root, place)
    if not place.hooked and type(root.HookScript) == "function" then
      place.hooked = true
      pcall(root.HookScript, root, "OnHide", hideCard)
    end
  else
    card:ClearAllPoints()
    card:SetPoint("TOP", UIParent, "TOP", 0, -100)
  end
  card:Show()
end
M.refresh = function() refreshCard() end

-- The key binding's button (CLICK LevelingCodexMailTakeAll:LeftButton): a hidden plain button.
local bindButton = CreateFrame("Button", "LevelingCodexMailTakeAll", UIParent)
bindButton:Hide()
bindButton:SetScript("OnClick", function() M.takeAll() end)

local events, pending
local function refreshSoon()
  if pending then return end
  pending = true
  ns.after(0.2, function() pending = false; refreshCard() end)
end

function ns.startMailbox()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "BAG_UPDATE_DELAYED", "UI_ERROR_MESSAGE" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  events:SetScript("OnEvent", function(_, event, a1, a2)
    if event == "MAIL_SHOW" then
      mailOpen = true
      refreshSoon()
      ns.after(0.5, function()
        refreshCard()
        if ns.db().mailAutoTake and isOpen() and not run and M.summary().mails > 0 then M.takeAll() end
      end)
    elseif event == "MAIL_CLOSED" then
      mailOpen = false
      if run then sayDone("closed") end
      hideCard()
    elseif event == "UI_ERROR_MESSAGE" then
      -- "Inventory is full." while taking: no more items this run (the gold still comes)
      local msg = type(a2) == "string" and a2 or a1
      if run and type(msg) == "string" and (msg == ERR_INV_FULL or msg:lower():find("inventory is full")) then
        run.full = true
      end
    elseif mailOpen then
      refreshSoon()
    end
  end)
end

function ns.mailDebugLines()
  local s = M.summary()
  local line = "mailbox: " .. (mailOpen and "open" or "closed") .. ", " .. s.mails .. " mails to take ("
    .. s.items .. " items, " .. ns.money(s.money) .. "), free slots " .. tostring(M.freeSlots())
    .. "; this session " .. stats.runs .. " runs, " .. stats.took .. " items, " .. ns.money(stats.money)
  if last then
    line = line .. "; last run " .. last.why .. ": " .. last.items .. " items, " .. ns.money(last.money) .. " from "
      .. last.mails .. " mails in " .. last.actions .. " takes" .. (last.full and ", bags full" or "")
      .. (last.skipped > 0 and (", " .. last.skipped .. " passed over") or "")
  end
  return { line }
end
