-- QuestParty.lua: playing the guide in a party. Party members running the Codex see each other's
-- current step in the step window (addon messages, Settings > Show my party's steps). Two opt-in
-- helpers: share a guide quest with the party when you accept it, and say in party chat where you
-- are flying. Nothing here runs in a raid.
local _, ns = ...
local Q = ns.quests
local try = Q.try
local PREFIX = "LevCodex"
local members = {}  -- sender -> { section, pos, label, at }
local sent          -- the last step we told the party about
local sentAt = 0
local events

local function inParty()
  local group = try(IsInGroup)
  local raid = try(IsInRaid)
  return (group == true or group == 1) and not (raid == true or raid == 1)
end

local function send(text)
  local api = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
  if type(api) == "function" then try(api, PREFIX, text, "PARTY") end
end

-- Tell the party about the current step: "S;section;position;label", at most every 2 s.
local function broadcast(force)
  if ns.db().noPartySteps or not inParty() then return end
  local row = Q.current()
  local key = row and (row.section.id .. ";" .. tostring(row.pos)) or "none;0"
  local now = GetTime()
  if not force and (key == sent or now - sentAt < 2) then return end
  sent, sentAt = key, now
  local label = row and Q.plain(Q.label(row.step)):gsub("[;|]", ",") or ""
  send(("S;" .. key .. ";" .. label):sub(1, 250))
end

function ns.partyStepChanged() broadcast(false) end

local function receive(prefix, text, channel, sender)
  if prefix ~= PREFIX or channel ~= "PARTY" or type(text) ~= "string" or type(sender) ~= "string" then return end
  local me = try(UnitName, "player")
  local name = Q.plain(sender:match("^[^-]+") or sender)
  if name == me then return end
  if text == "HELLO" then broadcast(true); return end
  local section, pos, label = text:match("^S;([^;]*);([^;]*);(.*)$")
  if not section then return end
  members[name] = section ~= "none" and { section = section, pos = tonumber(pos), label = label, at = GetTime() } or nil
  ns.questRefresh()
end

-- The party's steps for the step window, as "Name: step (N ahead)" lines.
-- One line per party member: "Name: step (N ahead)". Empty out of a party or with the setting off.
function ns.partyLines()
  if ns.db().noPartySteps or not inParty() then return {} end
  local row = Q.current()
  local lines = {}
  for name, m in pairs(members) do
    if GetTime() - m.at < 900 then
      local where = ""
      if row and row.section.id == m.section and m.pos and row.pos then
        local diff = m.pos - row.pos
        where = diff == 0 and " (same step)" or (" (" .. math.abs(diff) .. (diff > 0 and " ahead)" or " behind)"))
      elseif not row or row.section.id ~= m.section then
        local other = Q.section(m.section)
        where = " (" .. (other and other.title or "another guide") .. ")"
      end
      lines[#lines + 1] = name .. ": " .. m.label .. where
    end
  end
  table.sort(lines)
  for n, line in ipairs(lines) do lines[n] = Q.plain(line) end
  return lines
end

function ns.partyText()
  local lines = ns.partyLines()
  return #lines > 0 and ("Party\n" .. table.concat(lines, "\n")) or ""
end

-- Settings > Share guide quests with my party: offer a quest of your route to the party.
local function pushQuest(id, index)
  local L = C_QuestLog
  if L and type(L.SetSelectedQuest) == "function" then
    if type(L.IsPushableQuest) == "function" and try(L.IsPushableQuest, id) == false then return end
    try(L.SetSelectedQuest, id)
  elseif index and type(SelectQuestLogEntry) == "function" then
    try(SelectQuestLogEntry, index)
    if type(GetQuestLogPushable) == "function" and not try(GetQuestLogPushable) then return end
  else
    return
  end
  try(QuestLogPushQuest)
end

local function accepted(a, b)
  local id = tonumber(b) or tonumber(a)
  local index = b and tonumber(a) or nil
  if not id or not ns.db().questShareParty or not inParty() or not Q.questMatch(id) then return end
  ns.after(0.5, function() pushQuest(id, index) end)
end

-- Settings > Say my flights in party chat.
local function announceFlight(node)
  if not ns.db().questAnnounceFlights or not inParty() then return end
  local name = Q.plain(try(TaxiNodeName, node) or "")
  if name == "" then return end
  local left = ns.questFlightEstimate and ns.questFlightEstimate()
  local eta = left and (" (about " .. math.floor(left / 60) .. ":" .. string.format("%02d", math.floor(left % 60)) .. ")") or ""
  try(SendChatMessage, "Flying to " .. (name:match("^[^,]+") or name) .. eta .. ".", "PARTY")
end

function ns.startQuestParty()
  if events then return end
  events = CreateFrame("Frame")
  for _, ev in ipairs({ "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "QUEST_ACCEPTED" }) do
    pcall(events.RegisterEvent, events, ev)
  end
  local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
  if type(register) == "function" then try(register, PREFIX) end
  events:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then
      receive(a, b, c, d)
    elseif event == "QUEST_ACCEPTED" then
      accepted(a, b)
    elseif event == "GROUP_ROSTER_UPDATE" then
      if not inParty() then
        members = {}
      else
        broadcast(true)
        if not ns.db().noPartySteps then send("HELLO") end
      end
      ns.questRefresh()
    end
  end)
  if type(TakeTaxiNode) == "function" then try(hooksecurefunc, "TakeTaxiNode", announceFlight) end
end

function ns.partyDebugLines()
  local count = 0
  for _ in pairs(members) do count = count + 1 end
  return { "party: " .. (inParty() and "in a party" or "not in a party") .. ", Codex members seen: " .. count
    .. ", addon messages: " .. ((C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage) and "yes" or "no") }
end
