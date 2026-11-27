-- AuctionShare.lua: realm-wide price sharing between Codex users (after AuctionMarket.lua).
-- Every lowest price the Codex reads itself (a scan, a search, the sniper) is queued and sent to
-- the other Codex users on the realm over a hidden custom channel (Sh.CHANNEL), addon prefix
-- Sh.PREFIX; their readings come back the same way and are filed into the price store, so
-- tooltips, deals and the market view stay fresh without a scan of your own.
--   Message: "P1;" then entries "id,low,n,age" (base 36, age in minutes) joined by "/", under 250 bytes.
--   Sending: one message every Sh.GAP s at most (backing off up to Sh.MAX_GAP when the game refuses),
--     the most valuable first, only readings under Sh.FRESH old, never a price that came from someone
--     else, never one another player sent within Sh.ECHO s at the same price.
--   Receiving: at most Sh.SENDER_MAX messages a minute per sender; numbers are checked; a reading
--     older than your own is passed over; on an item with 2+ days of history a price under a quarter
--     or over four times its usual waits for a second sender within 15% (Sh.CONFIRM s) before it counts.
--   Shared prices join the daily history (the usual price) only once two players agree within 15% that day;
--     a sender held back Sh.STRIKES times is ignored for the session. Tooltips mark them "(shared)".
--   db.auctionNoShare turns it off (and leaves the channel). Never buys: deals are still checked live.
local _, ns = ...
local function try(f, ...) if type(f) ~= "function" then return end local ok, a, b, c = pcall(f, ...); if ok then return a, b, c end end

local Sh = {}
ns.auctionShare = Sh

Sh.PREFIX = "LevCodexP"
Sh.CHANNEL = "LevCodexPrices"
Sh.GAP, Sh.MAX_GAP = 2, 30
Sh.FRESH = 15 * 60
Sh.ECHO = 10 * 60
Sh.MAX_BYTES = 245
Sh.ORDER_SIZE = 300
Sh.SENDER_MAX = 45 -- messages a minute; a sender sends one every Sh.GAP s, 30 a minute
Sh.MUTE_SHARE = 0.1 -- muted only when held prices are at least this share of what they sent
Sh.CONFIRM = 30 * 60
Sh.JOIN_DELAY = 15 -- s after entering the world: an early join can take General's channel number
Sh.MAX_ID, Sh.MAX_PRICE, Sh.MAX_N = 2000000, 99999999999, 1000000
-- Filing is budgeted (a mega realm can have dozens of senders): up to Sh.PER_SECOND entries are
-- filed as they arrive, the rest wait in an inbox drained Sh.DRAIN entries every 0.1 s (and all
-- of it waits while a scan of your own runs); past Sh.INBOX_MAX the oldest waiting are dropped.
Sh.PER_SECOND, Sh.DRAIN, Sh.INBOX_MAX = 200, 20, 3000

local pending, order = {}, {}
local heard, senders, held, agree, strikes, muted = {}, {}, {}, {}, {}, {}
Sh.muted = muted
Sh.STRIKES = 5
Sh.stats = { sentMsgs = 0, sentItems = 0, got = 0, filed = 0, older = 0, doubted = 0, bad = 0, refused = 0, peers = 0, flooded = 0 }
local peers = {}
-- each sender this session (by the name without its realm): entries heard, filed, older than
-- yours, held back, and whether it is one of your own characters
Sh.people = {}
-- the items filed from other players this session (to tell how many are still theirs)
local filedIDs, filedCount = {}, 0
local gap, lastSend, joinedAt, channelID = Sh.GAP, 0, nil, nil
-- joining: tries so far, when the last one was, whether the world has loaded (no join before it)
Sh.JOIN_RETRY, Sh.JOIN_TRIES = 60, 5
local joinTries, joinTriedAt, ready = 0, nil, false

local function A() return ns.auction end
local function now() return tonumber(time and time()) or 0 end
function Sh.on() return not ns.db().auctionNoShare end

local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"
local function b36(n)
  n = math.floor(tonumber(n) or 0)
  if n <= 0 then return "0" end
  local s = ""
  while n > 0 do
    local d = n % 36
    s = DIGITS:sub(d + 1, d + 1) .. s
    n = (n - d) / 36
  end
  return s
end
Sh.b36 = b36
local function num(s) return type(s) == "string" and s:match("^[0-9a-z]+$") and tonumber(s, 36) or nil end

local function myName()
  local n = try(UnitName, "player")
  return type(n) == "string" and n or ""
end
local function short(name) return type(name) == "string" and (name:match("^([^%-]+)") or name) or "" end
-- What this client sent lately: the channel hands every message back to its sender, and Forever
-- doesn't always name you the way UnitName does (a surname, a realm), so the text itself says it's yours
local sentLately, sentOrder = {}, {}
-- Your own name as the channel gives it: "Name" or "Name-Realm" (your realm). Another player
-- with your first name on a connected realm is not you.
local function squash(s) return (tostring(s or ""):gsub("[%s%-']", ""):lower()) end
local function isMyName(sender)
  local me = myName()
  if me == "" or type(sender) ~= "string" then return false end
  local n, realm = sender:match("^([^%-]+)%-(.+)$")
  if not n then return sender == me end
  if n ~= me then return false end
  local mine = try(GetNormalizedRealmName) or try(GetRealmName)
  if type(mine) ~= "string" or mine == "" then return true end
  return squash(realm) == squash(mine)
end
Sh.isMyName = isMyName
-- Your other characters on this realm: every name the Codex has seen log in here (kept in the
-- realm's price store) and every character with trade notes. Their prices are as good as your
-- own reading, so they are never held back or muted (Michael, 2026-11-27: his alt was muted).
local function altKeys()
  local ok, store = pcall(function() return A().store() end)
  local out = {}
  if not ok or type(store) ~= "table" then return out end
  if type(store.shareAlts) == "table" then for k in pairs(store.shareAlts) do out[squash(k)] = true end end
  local tr = store.trade
  if type(tr) == "table" and type(tr.chars) == "table" then for k in pairs(tr.chars) do out[squash(k)] = true end end
  return out
end
function Sh.noteMe()
  local me = myName()
  if me == "" then return end
  local ok, store = pcall(function() return A().store() end)
  if not ok or type(store) ~= "table" then return end
  if type(store.shareAlts) ~= "table" then store.shareAlts = {} end
  store.shareAlts[me] = true
end
local function sameRealm(sender)
  local realm = type(sender) == "string" and sender:match("^[^%-]+%-(.+)$")
  if not realm then return true end
  local mine = try(GetNormalizedRealmName) or try(GetRealmName)
  if type(mine) ~= "string" or mine == "" then return true end
  return squash(realm) == squash(mine)
end
function Sh.isAlt(sender)
  if type(sender) ~= "string" or isMyName(sender) or not sameRealm(sender) then return false end
  local keys = altKeys()
  local n = short(sender)
  if keys[squash(n)] then return true end
  -- Forever gives some names with a surname: the first name alone matches too
  local first = n:match("^(%S+)%s")
  return first ~= nil and keys[squash(first)] == true
end
local function person(sender)
  local k = short(sender)
  local p = Sh.people[k]
  if not p then
    p = { heard = 0, filed = 0, older = 0, held = 0, alt = Sh.isAlt(sender) }
    Sh.people[k] = p
  end
  return p
end

local function isMine(sender, text)
  return sentLately[text] == true or isMyName(sender)
end

----------------------------------------------------------------------------
-- The channel
----------------------------------------------------------------------------
local function channel()
  local id = try(GetChannelName, Sh.CHANNEL)
  id = tonumber(id)
  if id and id > 0 then channelID = id; return id end
  channelID = nil
end
Sh.channel = channel

-- out of every chat window: the old global, else the window's own method (newer clients)
local function hideChannel()
  local util = type(ChatFrameUtil) == "table" and ChatFrameUtil.RemoveChannel
  for i = 1, tonumber(NUM_CHAT_WINDOWS) or 10 do
    local f = _G["ChatFrame" .. i]
    if f then
      if type(ChatFrame_RemoveChannel) == "function" then pcall(ChatFrame_RemoveChannel, f, Sh.CHANNEL)
      elseif type(util) == "function" then pcall(util, f, Sh.CHANNEL)
      elseif type(f.RemoveChannel) == "function" then pcall(f.RemoveChannel, f, Sh.CHANNEL) end
    end
  end
end

-- the "Joined Channel" and "Left Channel" lines for ours stay out of chat
local function noticeFilter(_, _, ...)
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "string" and v:lower():find(Sh.CHANNEL:lower(), 1, true) then return true end
  end
  return false
end
-- a line someone typed into our channel (by its base name, the 9th argument; never the text)
local function chatFilter(_, _, _, _, _, _, _, _, _, _, base)
  return type(base) == "string" and base:lower() == Sh.CHANNEL:lower()
end

function Sh.join()
  pcall(Sh.noteMe) -- the realm is known by now
  if not Sh.on() then return end
  ready = true
  if not channel() then
    joinTries, joinTriedAt = joinTries + 1, now()
    try(JoinTemporaryChannel, Sh.CHANNEL)
    joinedAt = now()
  end
  ns.after(1, function() if channel() then joinTries = 0 end hideChannel() end)
end

-- A join the server refused (ten channels already, a password someone set, a full queue at
-- login) is tried again every Sh.JOIN_RETRY s, Sh.JOIN_TRIES times; meanwhile the guild carries it.
local function retryJoin()
  if not ready or channelID or joinTries >= Sh.JOIN_TRIES then return end
  if joinTriedAt and now() - joinTriedAt < Sh.JOIN_RETRY then return end
  Sh.join()
end
function Sh.joinFailed() return ready and not channelID and joinTries >= Sh.JOIN_TRIES end

function Sh.leave()
  if channel() then try(LeaveChannelByName, Sh.CHANNEL) end
  channelID = nil
end

function Sh.setOn(on)
  ns.db().auctionNoShare = (not on) or nil
  if on then joinTries = 0; Sh.join() else Sh.leave(); pending, order = {}, {} end
end

----------------------------------------------------------------------------
-- Sending
----------------------------------------------------------------------------
-- A.record calls this for every reading of the Codex's own.
function Sh.queue(id)
  if not Sh.on() or A().recordShared then return end
  id = tonumber(id)
  -- keeps the time it first waited, so a cheap item isn't pushed back by every new dear one
  if id and not pending[id] then pending[id] = now() end
end

local function value(it) return (tonumber(it.low) or 0) * math.min(20, math.max(1, tonumber(it.n) or 1)) end

-- The next batch: half the most valuable items, the other half those waiting longest, so every
-- item gets its turn however many dear ones keep arriving (Michael, 2026-11-25: a sniper running
-- for an hour should cover every item, not only the top of the list).
local function refill()
  local s, list = A().store(), {}
  for id, since in pairs(pending) do
    local it = s.items[id]
    if type(it) == "table" and it.low then
      list[#list + 1] = { id, value(it), type(since) == "number" and since or 0 }
    else
      pending[id] = nil
    end
  end
  order = {}
  if #list <= Sh.ORDER_SIZE then
    table.sort(list, function(a, b) return a[2] > b[2] end)
    for i, e in ipairs(list) do order[i] = e[1] end
    pending = {}
    return
  end
  local taken, half = {}, math.floor(Sh.ORDER_SIZE / 2)
  table.sort(list, function(a, b) return a[2] > b[2] end)
  for i = 1, half do taken[list[i][1]] = true; order[#order + 1] = list[i][1] end
  table.sort(list, function(a, b) if a[3] ~= b[3] then return a[3] < b[3] end return a[2] > b[2] end)
  for _, e in ipairs(list) do
    if #order >= Sh.ORDER_SIZE then break end
    if not taken[e[1]] then taken[e[1]] = true; order[#order + 1] = e[1] end
  end
  for id in pairs(taken) do pending[id] = nil end
end

-- The entry for one item, or nil when it shouldn't go out.
local function entry(id, t)
  local it = A().store().items[id]
  if type(it) ~= "table" then return end
  local low, at, n = tonumber(it.low), tonumber(it.at), tonumber(it.n) or 0
  if not low or low <= 0 or not at or n <= 0 or it.shAt == at or it.ator then return end
  local age = t - at
  if age < 0 then age = 0 end
  if age > Sh.FRESH then return end
  local h = heard[id]
  if h and h.low == low and t - h.t < Sh.ECHO then return end
  return b36(id) .. "," .. b36(low) .. "," .. b36(math.min(n, Sh.MAX_N)) .. "," .. b36(math.floor(age / 60))
end

function Sh.build()
  local t, parts, len, ids = now(), {}, 3, {}
  while true do
    if #order == 0 then
      if next(pending) == nil then break end
      refill()
      if #order == 0 then break end
    end
    local id = order[1]
    local e = entry(id, t)
    if e then
      if len + #e + 1 > Sh.MAX_BYTES then break end
      parts[#parts + 1] = e
      ids[#ids + 1] = id
      len = len + #e + 1
    end
    table.remove(order, 1)
  end
  if #parts == 0 then return end
  return "P1;" .. table.concat(parts, "/"), ids
end

local function sendRaw(msg)
  local send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
  if type(send) ~= "function" then return false end
  local id = channel()
  local ok, r
  if not sentLately[msg] then
    sentLately[msg] = true
    sentOrder[#sentOrder + 1] = msg
    if #sentOrder > 60 then sentLately[table.remove(sentOrder, 1)] = nil end
  end
  if id then ok, r = pcall(send, Sh.PREFIX, msg, "CHANNEL", id)
  elseif try(IsInGuild) then ok, r = pcall(send, Sh.PREFIX, msg, "GUILD")
  else return false end
  -- older clients return nothing, newer ones true/false or a result code (0 = sent)
  return ok and (r == nil or r == true or r == 0)
end

function Sh.tick()
  if not Sh.on() then return end
  local t = GetTime and GetTime() or now()
  if t - lastSend < gap then return end
  if not channel() then
    retryJoin()
    if not try(IsInGuild) then return end
  end
  local msg, ids = Sh.build()
  if not msg then return end
  lastSend = t
  if sendRaw(msg) then
    gap = Sh.GAP
    Sh.stats.sentMsgs = Sh.stats.sentMsgs + 1
    Sh.stats.sentItems = Sh.stats.sentItems + #ids
  else
    gap = math.min(Sh.MAX_GAP, gap * 2)
    Sh.stats.refused = Sh.stats.refused + 1
    for _, id in ipairs(ids) do pending[id] = pending[id] or 0 end
  end
end

----------------------------------------------------------------------------
-- Receiving
----------------------------------------------------------------------------
local function allowSender(name, t)
  local s = senders[name]
  if not s or t - s.since >= 60 then s = { since = t, n = 0 }; senders[name] = s end
  s.n = s.n + 1
  return s.n <= Sh.SENDER_MAX
end

-- Is a price far off what this item usually costs? Against its usual price once it has two days,
-- else against your own reading of the last three days (one player's word alone moved new items).
local function doubtful(id, low)
  local p = A().price(id)
  local ref
  if p and (p.days or 0) >= 2 and p.usual and p.usual > 0 then
    ref = p.usual
  else
    local it = A().store().items[id]
    local at = type(it) == "table" and tonumber(it.at)
    if at and it.shAt ~= at and not it.ator and (tonumber(it.n) or 0) > 0 and now() - at < 3 * 86400 then ref = tonumber(it.low) end
  end
  if not ref or ref <= 0 then return false end
  return low < ref / 4 or low > ref * 4
end

-- An ID the game has no item for never enters the store (a broken or made-up message would
-- otherwise fill your saved prices with nameless entries). Without the API it is let through.
local function realItem(id)
  local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if type(f) ~= "function" then return true end
  local ok, r = pcall(f, id)
  return not ok or r ~= nil
end

-- Two different players within 15% of each other on the same day: the price joins the history.
local function agreed(id, low, sender, t)
  local d = math.floor(t / 86400)
  local g = agree[id]
  if not g or g.day ~= d then g = { day = d, by = {} }; agree[id] = g end
  local yes = false
  for who, v in pairs(g.by) do
    if who ~= sender and math.abs(v - low) <= 0.15 * math.max(v, low) then yes = true end
  end
  g.by[sender] = low
  return yes
end

local function file(id, low, n, at, sender, intoDays)
  local a = A()
  a.recordShared, a.recordFast, a.recordAt, a.recordDays = true, true, at, intoDays
  local ok = pcall(a.record, id, nil, low, n)
  a.recordShared, a.recordFast, a.recordAt, a.recordDays = nil, nil, nil, nil
  if not ok then return end
  local it = a.store().items[id]
  if type(it) == "table" then it.shAt, it.shBy = it.at, short(sender) end
  -- an item known only from someone else gets its name (from the item cache, or asked for), so
  -- it shows by name in the market, deals and look-ups and A.idFor finds it
  if type(it) == "table" and (type(it.name) ~= "string" or it.name == "") and a.nameOf then pcall(a.nameOf, id) end
  Sh.stats.filed = Sh.stats.filed + 1
  Sh.lastAt, Sh.lastBy = now(), short(sender)
end

function Sh.take(id, low, n, at, sender)
  local t = now()
  local p = person(sender)
  heard[id] = { low = low, t = t }
  local it = A().store().items[id]
  if type(it) ~= "table" and not realItem(id) then
    Sh.stats.bad = Sh.stats.bad + 1
    return false
  end
  local mine = type(it) == "table" and tonumber(it.at)
  -- passed over when your reading is newer, or as new and your own (a shared one as new may be confirmed)
  if mine and (mine > at or (mine == at and it.shAt ~= mine)) then
    Sh.stats.older = Sh.stats.older + 1
    p.older = p.older + 1
    return false
  end
  if not p.alt and doubtful(id, low) then
    local h = held[id]
    if h and h.by ~= sender and t - h.t < Sh.CONFIRM and math.abs(h.low - low) <= 0.15 * math.max(h.low, low) then
      held[id] = nil
      agreed(id, h.low, h.by, t) -- the first sender's word counts towards the day's agreement too
      strikes[h.by] = math.max(0, (strikes[h.by] or 0) - 1) -- it was true after all
    else
      held[id] = { low = low, by = sender, t = t }
      Sh.heldCount = (Sh.heldCount or 0) + 1
      if Sh.heldCount > 500 then
        Sh.heldCount = 0
        for k, v in pairs(held) do if t - v.t >= Sh.CONFIRM then held[k] = nil else Sh.heldCount = Sh.heldCount + 1 end end
      end
      Sh.stats.doubted = Sh.stats.doubted + 1
      p.held = p.held + 1
      strikes[sender] = (strikes[sender] or 0) + 1
      -- a busy sender's few odd prices are real listings (a cheap one put up by someone): only a
      -- sender whose held prices are a fair share of what they sent is ignored
      if strikes[sender] >= Sh.STRIKES and strikes[sender] >= Sh.MUTE_SHARE * p.heard and not muted[sender] then
        muted[sender] = true; p.muted = true; Sh.stats.muted = (Sh.stats.muted or 0) + 1
      end
      return false
    end
  end
  file(id, low, n, at, sender, agreed(id, low, sender, t))
  p.filed = p.filed + 1
  if not filedIDs[id] then filedIDs[id] = true; filedCount = filedCount + 1 end
  return true
end

local inbox, inHead, inTail = {}, 1, 0 -- a queue: # is no use on a table with holes at the front
local window = { at = -1, n = 0 }
local function inboxSize() return inTail - inHead + 1 end
Sh.inboxSize = inboxSize
local function canFileNow()
  if A().scanning and A().scanning() then return false end
  local t = math.floor(GetTime and GetTime() or now())
  if window.at ~= t then window.at, window.n = t, 0 end
  if window.n >= Sh.PER_SECOND then return false end
  window.n = window.n + 1
  return true
end
local function enqueue(e)
  inTail = inTail + 1
  inbox[inTail] = e
  if inboxSize() > Sh.INBOX_MAX then
    inbox[inHead] = nil; inHead = inHead + 1
    Sh.stats.dropped = (Sh.stats.dropped or 0) + 1
  end
end
local redrawSoon
local function redraw()
  local t = now()
  if not A().refresh then return end
  if not Sh.drawnAt or t - Sh.drawnAt >= 5 then
    Sh.drawnAt = t; pcall(A().refresh)
  elseif not redrawSoon then
    -- a filing inside the 5 s still shows: one redraw when they are up
    redrawSoon = true
    ns.after(5 - (t - Sh.drawnAt), function() redrawSoon = nil; Sh.drawnAt = now(); pcall(A().refresh) end)
  end
end
-- Files waiting entries; true when something was filed.
function Sh.drain(max)
  if inHead > inTail or (A().scanning and A().scanning()) then return false end
  local filed = false
  for _ = 1, max or Sh.DRAIN do
    local e = inbox[inHead]
    if not e then break end
    inbox[inHead] = nil; inHead = inHead + 1
    if not muted[e[5]] and Sh.take(e[1], e[2], e[3], e[4], e[5]) then filed = true end
  end
  if inHead > inTail then inbox, inHead, inTail = {}, 1, 0 end
  if filed then redraw() end
  return filed
end

function Sh.receive(text, sender)
  if not Sh.on() or type(text) ~= "string" or type(sender) ~= "string" or sender == "" then return end
  if isMine(sender, text) then Sh.stats.echo = (Sh.stats.echo or 0) + 1; return end
  local body = text:match("^P1;(.+)$")
  if not body then return end
  local t = now()
  if muted[sender] then Sh.stats.mutedMsgs = (Sh.stats.mutedMsgs or 0) + 1; return end
  if not allowSender(sender, t) then Sh.stats.flooded = Sh.stats.flooded + 1; return end
  local p = person(sender)
  if not peers[sender] then peers[sender] = true; Sh.stats.peers = Sh.stats.peers + 1; Sh.lastPeer = sender end
  Sh.lastHeard = t
  local filed, count = 0, 0
  for part in body:gmatch("[^/]+") do
    count = count + 1
    if count > 30 then break end
    local a, b, c, d = part:match("^([0-9a-z]+),([0-9a-z]+),([0-9a-z]+),([0-9a-z]+)$")
    local id, low, n, age = num(a), num(b), num(c), num(d)
    Sh.stats.got = Sh.stats.got + 1
    p.heard = p.heard + 1
    if id and low and n and age and id > 0 and id < Sh.MAX_ID and low > 0 and low <= Sh.MAX_PRICE
      and n > 0 and n <= Sh.MAX_N and age <= Sh.FRESH / 60 then
      -- the age travels in whole minutes: the middle of that minute is the best guess
      local at = t - age * 60 - (age > 0 and 30 or 0)
      if inboxSize() == 0 and canFileNow() then
        if Sh.take(id, low, n, at, sender) then filed = filed + 1 end
      else
        enqueue({ id, low, n, at, sender })
      end
    else
      Sh.stats.bad = Sh.stats.bad + 1
    end
  end
  -- the open page redraws at most every 5 s however many players are sending
  if filed > 0 then redraw() end
end

----------------------------------------------------------------------------
function Sh.summary()
  local s = Sh.stats
  if not Sh.on() then return "Off." end
  local where = channel() and "the realm channel" or (try(IsInGuild) and "your guild" or "nobody yet")
  return "Sharing with " .. where .. ": sent " .. ns.thousands(s.sentItems) .. (s.sentItems == 1 and " price" or " prices")
    .. ", filed " .. ns.thousands(s.filed) .. " from " .. ns.thousands(s.peers) .. (s.peers == 1 and " player" or " players") .. " this session."
end

-- For Settings > Helpers > PRICE SHARING (Michael, 2026-11-26: see what sharing did away from
-- the auction house): this session's traffic, the last update and how many prices in your
-- database came from other players (counted at most once a minute).
local storeCount = { at = 0, n = 0, filed = -1 }
function Sh.sharedInStore()
  local t = now()
  -- counted again once a minute, or 5 s after new prices came in
  local fresh = t - storeCount.at < 60 and (storeCount.filed == Sh.stats.filed or t - storeCount.at < 5)
  if fresh then return storeCount.n, storeCount.kept end
  local n, kept = 0, 0
  local ok, store = pcall(A().store)
  if ok and type(store) == "table" and type(store.items) == "table" then
    for id, it in pairs(store.items) do
      if type(it) == "table" and it.shAt and it.shAt == it.at then
        n = n + 1
        if filedIDs[id] then kept = kept + 1 end
      end
    end
  end
  storeCount = { at = t, n = n, kept = kept, filed = Sh.stats.filed }
  return n, kept
end

local function plural(n, one, many) return ns.thousands(n) .. " " .. (n == 1 and one or many) end

-- the players heard this session: your own characters first, then the busiest
function Sh.peopleList()
  local out = {}
  for name, p in pairs(Sh.people) do out[#out + 1] = { name = name, p = p } end
  table.sort(out, function(a, b)
    if (a.p.alt and true or false) ~= (b.p.alt and true or false) then return a.p.alt == true end
    if a.p.heard ~= b.p.heard then return a.p.heard > b.p.heard end return a.name < b.name end)
  return out
end

function Sh.fieldLines()
  local s = Sh.stats
  if not Sh.on() then return { "Price sharing is off." } end
  local where = channel() and "the realm channel" or (try(IsInGuild) and "your guild" or "nobody yet: it joins the channel shortly after you log in")
  if not channel() and Sh.joinFailed() then
    where = (try(IsInGuild) and "your guild only" or "nobody") .. ": the game wouldn't let it join the price channel (you may be in ten channels already)"
  end
  local lines = { "Sharing with " .. where .. "." }
  lines[#lines + 1] = "This session: sent " .. plural(s.sentItems, "price", "prices") .. ", heard " .. plural(s.got, "price", "prices")
    .. " from " .. plural(s.peers, "player", "players") .. "."
  if s.got > 0 then
    local parts = { ns.thousands(s.filed) .. " filed" }
    if s.older > 0 then parts[#parts + 1] = ns.thousands(s.older) .. " older than your own" end
    if (s.doubted or 0) > 0 then parts[#parts + 1] = ns.thousands(s.doubted) .. " odd, waiting for a second player" end
    if s.bad > 0 then parts[#parts + 1] = ns.thousands(s.bad) .. " unreadable" end
    lines[#lines + 1] = "Of those: " .. table.concat(parts, ", ") .. "."
  end
  local waiting = inboxSize()
  if waiting > 0 then lines[#lines + 1] = plural(waiting, "price is", "prices are") .. " waiting to be filed (a few hundred a second, none during your own scans)." end
  local list = Sh.peopleList()
  for i = 1, math.min(3, #list) do
    local e = list[i]
    local tag = e.p.muted and " (ignored: too many odd prices)" or (e.p.alt and " (your character)" or "")
    lines[#lines + 1] = "  " .. ns.plain(e.name) .. tag .. ": " .. ns.thousands(e.p.filed) .. " filed of " .. ns.thousands(e.p.heard) .. "."
  end
  if #list > 3 then lines[#lines + 1] = "  and " .. plural(#list - 3, "more player", "more players") .. "." end
  if Sh.lastAt then
    local by = ns.plain(Sh.lastBy or "")
    lines[#lines + 1] = "Last update " .. A().age(Sh.lastAt) .. (by ~= "" and (", from " .. by) or "") .. "."
  elseif s.got == 0 then
    lines[#lines + 1] = "No prices from other players yet this session."
  end
  local n, kept = Sh.sharedInStore()
  if n > 0 then
    lines[#lines + 1] = plural(n, "price", "prices") .. " in your database " .. (n == 1 and "comes" or "come") .. " from other players."
  else
    lines[#lines + 1] = "No price in your database comes from other players right now."
  end
  if filedCount > (kept or 0) then
    lines[#lines + 1] = "Your own scans and searches have since replaced " .. plural(filedCount - (kept or 0), "price", "prices")
      .. " you got this session: yours always win."
  end
  if (s.muted or 0) > 0 then
    lines[#lines + 1] = plural(s.muted, "player is", "players are") .. " ignored for this session."
  end
  return lines
end

function ns.auctionShareDebugLines()
  local s = Sh.stats
  local q = 0
  for _ in pairs(pending) do q = q + 1 end
  return { "price sharing: " .. (Sh.on() and "on" or "off") .. ", channel " .. tostring(channelID or "none")
    .. ", sent " .. s.sentMsgs .. " messages / " .. s.sentItems .. " prices, " .. s.refused .. " refused, gap " .. gap .. " s, queued "
    .. (q + #order) .. "; heard " .. s.got .. " from " .. s.peers .. " players: filed " .. s.filed .. ", older " .. s.older
    .. ", held for a second sender " .. s.doubted .. ", bad " .. s.bad .. ", over the rate " .. s.flooded .. ", waiting to file " .. inboxSize() .. ", dropped from the inbox " .. (s.dropped or 0) .. ", from muted " .. (s.mutedMsgs or 0) .. ", muted " .. (s.muted or 0) .. " players; own echoes skipped " .. (s.echo or 0)
    .. (Sh.lastPeer and (", last new player " .. ns.plain(Sh.lastPeer)) or "")
    .. "; join tries " .. joinTries .. (Sh.joinFailed() and " (gave up)" or "") .. ", other channel types skipped " .. (s.otherDist or 0) }
end

local frame
function ns.startAuctionShare()
  if frame then return end
  local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
  if type(register) == "function" then pcall(register, Sh.PREFIX) end
  local addFilter = (type(ChatFrame_AddMessageEventFilter) == "function" and ChatFrame_AddMessageEventFilter)
    or (type(ChatFrameAddMessageEventFilter) == "function" and ChatFrameAddMessageEventFilter)
    or (type(ChatFrameUtil) == "table" and type(ChatFrameUtil.AddMessageEventFilter) == "function" and ChatFrameUtil.AddMessageEventFilter)
  if addFilter then
    -- joined / left, and the owner and password notices the first player in it gets
    pcall(addFilter, "CHAT_MSG_CHANNEL_NOTICE", noticeFilter)
    pcall(addFilter, "CHAT_MSG_CHANNEL_NOTICE_USER", noticeFilter)
    pcall(addFilter, "CHAT_MSG_CHANNEL", chatFilter)
  end
  pcall(Sh.noteMe)
  frame = CreateFrame("Frame")
  for _, ev in ipairs({ "CHAT_MSG_ADDON", "PLAYER_ENTERING_WORLD" }) do pcall(frame.RegisterEvent, frame, ev) end
  local entered = false
  frame:SetScript("OnEvent", function(_, event, prefix, text, dist, sender)
    if event == "CHAT_MSG_ADDON" then
      if prefix ~= Sh.PREFIX then return end
      -- only the price channel and the guild carry prices (a whisper or party message is anyone's)
      if dist ~= nil and dist ~= "CHANNEL" and dist ~= "GUILD" then
        Sh.stats.otherDist = (Sh.stats.otherDist or 0) + 1
        return
      end
      pcall(Sh.receive, text, sender)
    elseif not entered then
      entered = true
      ns.after(Sh.JOIN_DELAY, function() pcall(Sh.join) end)
    else
      ns.after(2, function() if Sh.on() then channel(); hideChannel() end end)
    end
  end)
  -- started during PLAYER_ENTERING_WORLD (the class wasn't known at login): that event has
  -- already gone by, so the join comes from here instead
  ns.after(Sh.JOIN_DELAY + 30, function()
    if not entered then entered = true; pcall(Sh.join) end
  end)
  ns.every(1, function() pcall(Sh.tick) end)
  ns.every(0.1, function() pcall(Sh.drain) end)
end
