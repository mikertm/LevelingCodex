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
Sh.SENDER_MAX = 30
Sh.CONFIRM = 30 * 60
Sh.JOIN_DELAY = 15 -- s after entering the world: an early join can take General's channel number
Sh.MAX_ID, Sh.MAX_PRICE, Sh.MAX_N = 2000000, 99999999999, 1000000

local pending, order = {}, {}
local heard, senders, held, agree, strikes, muted = {}, {}, {}, {}, {}, {}
Sh.muted = muted
Sh.STRIKES = 5
Sh.stats = { sentMsgs = 0, sentItems = 0, got = 0, filed = 0, older = 0, doubted = 0, bad = 0, refused = 0, peers = 0 }
local peers = {}
local gap, lastSend, joinedAt, channelID = Sh.GAP, 0, nil, nil

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
local function isMine(sender, text)
  return sentLately[text] == true or short(sender) == short(myName())
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

local function hideChannel()
  if type(ChatFrame_RemoveChannel) ~= "function" then return end
  for i = 1, tonumber(NUM_CHAT_WINDOWS) or 10 do
    local f = _G["ChatFrame" .. i]
    if f then pcall(ChatFrame_RemoveChannel, f, Sh.CHANNEL) end
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

function Sh.join()
  if not Sh.on() then return end
  if not channel() then
    try(JoinTemporaryChannel, Sh.CHANNEL)
    joinedAt = now()
  end
  ns.after(1, function() channel(); hideChannel() end)
end

function Sh.leave()
  if channel() then try(LeaveChannelByName, Sh.CHANNEL) end
  channelID = nil
end

function Sh.setOn(on)
  ns.db().auctionNoShare = (not on) or nil
  if on then Sh.join() else Sh.leave(); pending, order = {}, {} end
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
  if not channel() and not try(IsInGuild) then return end
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

-- Is a price far off what this item usually costs?
local function doubtful(id, low)
  local p = A().price(id)
  if not p or (p.days or 0) < 2 or not p.usual or p.usual <= 0 then return false end
  return low < p.usual / 4 or low > p.usual * 4
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
  Sh.stats.filed = Sh.stats.filed + 1
end

function Sh.take(id, low, n, at, sender)
  local t = now()
  heard[id] = { low = low, t = t }
  local it = A().store().items[id]
  local mine = type(it) == "table" and tonumber(it.at)
  -- passed over when your reading is newer, or as new and your own (a shared one as new may be confirmed)
  if mine and (mine > at or (mine == at and it.shAt ~= mine)) then
    Sh.stats.older = Sh.stats.older + 1
    return false
  end
  if doubtful(id, low) then
    local h = held[id]
    if h and h.by ~= sender and t - h.t < Sh.CONFIRM and math.abs(h.low - low) <= 0.15 * math.max(h.low, low) then
      held[id] = nil
      strikes[h.by] = math.max(0, (strikes[h.by] or 0) - 1) -- it was true after all
    else
      held[id] = { low = low, by = sender, t = t }
      Sh.stats.doubted = Sh.stats.doubted + 1
      strikes[sender] = (strikes[sender] or 0) + 1
      if strikes[sender] >= Sh.STRIKES and not muted[sender] then muted[sender] = true; Sh.stats.muted = (Sh.stats.muted or 0) + 1 end
      return false
    end
  end
  file(id, low, n, at, sender, agreed(id, low, sender, t))
  return true
end

function Sh.receive(text, sender)
  if not Sh.on() or type(text) ~= "string" or type(sender) ~= "string" then return end
  if isMine(sender, text) then Sh.stats.echo = (Sh.stats.echo or 0) + 1; return end
  local body = text:match("^P1;(.+)$")
  if not body then return end
  local t = now()
  if muted[sender] or not allowSender(sender, t) then return end
  if not peers[sender] then peers[sender] = true; Sh.stats.peers = Sh.stats.peers + 1; Sh.lastPeer = sender end
  Sh.lastHeard = t
  local filed, count = 0, 0
  for part in body:gmatch("[^/]+") do
    count = count + 1
    if count > 30 then break end
    local a, b, c, d = part:match("^([0-9a-z]+),([0-9a-z]+),([0-9a-z]+),([0-9a-z]+)$")
    local id, low, n, age = num(a), num(b), num(c), num(d)
    Sh.stats.got = Sh.stats.got + 1
    if id and low and n and age and id > 0 and id < Sh.MAX_ID and low > 0 and low <= Sh.MAX_PRICE
      and n > 0 and n <= Sh.MAX_N and age <= Sh.FRESH / 60 then
      if Sh.take(id, low, n, t - age * 60, sender) then filed = filed + 1 end
    else
      Sh.stats.bad = Sh.stats.bad + 1
    end
  end
  -- the open page redraws at most every 5 s however many players are sending
  if filed > 0 and A().refresh and (not Sh.drawnAt or t - Sh.drawnAt >= 5) then Sh.drawnAt = t; pcall(A().refresh) end
end

----------------------------------------------------------------------------
function Sh.summary()
  local s = Sh.stats
  if not Sh.on() then return "Off." end
  local where = channel() and "the realm channel" or (try(IsInGuild) and "your guild" or "nobody yet")
  return "Sharing with " .. where .. ": sent " .. ns.thousands(s.sentItems) .. " prices, got " .. ns.thousands(s.filed)
    .. " from " .. s.peers .. (s.peers == 1 and " player" or " players") .. " this session."
end

function ns.auctionShareDebugLines()
  local s = Sh.stats
  local q = 0
  for _ in pairs(pending) do q = q + 1 end
  return { "price sharing: " .. (Sh.on() and "on" or "off") .. ", channel " .. tostring(channelID or "none")
    .. ", sent " .. s.sentMsgs .. " messages / " .. s.sentItems .. " prices, " .. s.refused .. " refused, gap " .. gap .. " s, queued "
    .. (q + #order) .. "; heard " .. s.got .. " from " .. s.peers .. " players: filed " .. s.filed .. ", older " .. s.older
    .. ", held for a second sender " .. s.doubted .. ", bad " .. s.bad .. ", muted " .. (s.muted or 0) .. " players; own echoes skipped " .. (s.echo or 0)
    .. (Sh.lastPeer and (", last new player " .. ns.plain(Sh.lastPeer)) or "") }
end

local frame
function ns.startAuctionShare()
  if frame then return end
  local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
  if type(register) == "function" then pcall(register, Sh.PREFIX) end
  if type(ChatFrameAddMessageEventFilter) == "function" then
    pcall(ChatFrameAddMessageEventFilter, "CHAT_MSG_CHANNEL_NOTICE", noticeFilter)
  elseif type(ChatFrame_AddMessageEventFilter) == "function" then
    pcall(ChatFrame_AddMessageEventFilter, "CHAT_MSG_CHANNEL_NOTICE", noticeFilter)
  end
  frame = CreateFrame("Frame")
  for _, ev in ipairs({ "CHAT_MSG_ADDON", "PLAYER_ENTERING_WORLD" }) do pcall(frame.RegisterEvent, frame, ev) end
  local entered = false
  frame:SetScript("OnEvent", function(_, event, prefix, text, _, sender)
    if event == "CHAT_MSG_ADDON" then
      if prefix == Sh.PREFIX then pcall(Sh.receive, text, sender) end
    elseif not entered then
      entered = true
      ns.after(Sh.JOIN_DELAY, function() pcall(Sh.join) end)
    else
      ns.after(2, function() if Sh.on() then channel(); hideChannel() end end)
    end
  end)
  ns.every(1, function() pcall(Sh.tick) end)
end
