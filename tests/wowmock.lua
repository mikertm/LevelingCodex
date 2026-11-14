-- Headless mock of the WoW: Forever API surface the addon uses.
-- Loaded into a fresh Lua 5.1 state (lupa) per test run; tests/run.py drives it.
--
-- MOCK.setup{ class = "WARRIOR", minimal = false } must be called before loading the addon.
-- minimal = true removes every API the addon should treat as optional, to prove the guards work.

MOCK = {
  time = 0,
  level = 1,
  combat = false,
  cursor = { 0, 0 },
  problems = {},      -- non-fatal findings (non-ASCII text, bad macros, ...)
  chat = {},          -- every chat line
  frames = {},        -- every frame, creation order (for EnumerateFrames)
  updaters = {},      -- frames with an OnUpdate script
  timers = {},
  anims = {},         -- playing animation groups
  events = {},        -- event -> list of frames
  macros = {},        -- { name, icon, body, perChar }
  spells = {},        -- spellID -> name (C_Spell.GetSpellName)
  fileIDs = {},       -- lower(path) -> id
  nextFileID = 500000,
  missingTextures = {},
  disabledTemplates = {},
  atlases = {},       -- atlas names the client knows (C_Texture.GetAtlasInfo / SetAtlas)
  unspent = nil,      -- talent points to spend; nil = one per level from 10 (the usual case)
  mouseOver = {},
  textures = 0,
}

local function problem(kind, msg)
  MOCK.problems[#MOCK.problems + 1] = kind .. ": " .. msg
end
MOCK.problem = problem

local function ascii(s, where)
  if type(s) == "string" and s:find("[\128-\255]") then
    problem("non-ascii", where .. ": " .. s:sub(1, 80))
  end
end
MOCK.ascii = ascii

-- Events that exist in the client. Anything else throws on RegisterEvent, like Forever.
MOCK.knownEvents = {
  PLAYER_LOGIN = true, PLAYER_LOGOUT = true, PLAYER_ENTERING_WORLD = true, PLAYER_LEAVING_WORLD = true, PLAYER_LEVEL_UP = true,
  PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, ADDON_LOADED = true, VARIABLES_LOADED = true,
  -- optional: the minimal client doesn't know these (MOCK.setup removes them)
  PLAYER_ALIVE = true, PLAYER_UNGHOST = true, MINIMAP_UPDATE_TRACKING = true, LEARNED_SPELL_IN_TAB = true,
  SPELLS_CHANGED = true, SKILL_LINES_CHANGED = true, CHAT_MSG_SKILL = true, TRADE_SKILL_SHOW = true,
  TRADE_SKILL_UPDATE = true, TRADE_SKILL_CLOSE = true, TRAINER_SHOW = true, TRAINER_CLOSED = true, TRAINER_UPDATE = true,
  GAME_PAD_ACTIVE_CHANGED = true,
}
MOCK.optionalEvents = { "GAME_PAD_ACTIVE_CHANGED", "PLAYER_ALIVE", "PLAYER_UNGHOST", "MINIMAP_UPDATE_TRACKING", "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED",
  "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_CLOSE", "TRAINER_SHOW",
  "TRAINER_CLOSED", "TRAINER_UPDATE" }
for _, event in ipairs({ "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
  "QUEST_QUERY_COMPLETE", "PLAYER_CONTROL_GAINED", "NEW_TAXI_PATH",
  "ZONE_CHANGED_NEW_AREA", "TAXIMAP_OPENED", "QUEST_DETAIL", "QUEST_COMPLETE", "HEARTHSTONE_BOUND",
  "GOSSIP_SHOW", "QUEST_GREETING", "BAG_UPDATE_DELAYED", "CONFIRM_BINDER", "PLAYER_XP_UPDATE",
  "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_FINISHED", "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "PLAYER_DEAD",
  "ENCOUNTER_END", "BOSS_KILL", "COMBAT_LOG_EVENT_UNFILTERED", "ADDON_ACTION_FORBIDDEN", "ADDON_ACTION_BLOCKED",
  "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "PLAYER_MONEY", "LOOT_OPENED", "LOOT_CLOSED",
  "TIME_PLAYED_MSG", "UNIT_SPELLCAST_SUCCEEDED" }) do
  MOCK.knownEvents[event] = true
  table.insert(MOCK.optionalEvents, event)
end

MOCK.questLog, MOCK.questDone = {}, {}
MOCK.questMap, MOCK.questX, MOCK.questY, MOCK.facing = 1429, 48, 43, 0
C_QuestLog = {
  GetNumQuestLogEntries = function() return #MOCK.questLog end,
  GetInfo = function(i) return MOCK.questLog[i] end,
  GetQuestObjectives = function(id)
    for _, q in ipairs(MOCK.questLog) do if q.questID == id then return q.objectives end end
  end,
  IsQuestFlaggedCompleted = function(id) return MOCK.questDone[id] or false end,
  -- Abandoning: the selected quest goes when AbandonQuest runs after SetAbandonQuest (MOCK.abandoned).
  SetSelectedQuest = function(id) MOCK.selectedQuest = id end,
  SetAbandonQuest = function() MOCK.abandoning = MOCK.selectedQuest end,
  AbandonQuest = function() MOCK.abandoned, MOCK.abandoning = MOCK.abandoning, nil end,
  -- The objective tracker: MOCK.watches[questID] = true while watched.
  AddQuestWatch = function(id) MOCK.watches = MOCK.watches or {}; MOCK.watches[id] = true end,
  RemoveQuestWatch = function(id) if MOCK.watches then MOCK.watches[id] = nil end end,
  GetQuestWatchType = function(id) return MOCK.watches and MOCK.watches[id] and 0 or nil end,
  IsPushableQuest = function() return true end,
}
-- Parties: MOCK.party = in a party; addon messages go to MOCK.addonSent, chat to MOCK.said,
-- QuestLogPushQuest shares MOCK.selectedQuest (MOCK.pushed).
function IsInGroup() return MOCK.party or false end
function IsInRaid() return false end
C_ChatInfo = {
  RegisterAddonMessagePrefix = function(prefix) MOCK.addonPrefix = prefix; return true end,
  SendAddonMessage = function(prefix, text, channel)
    MOCK.addonSent = MOCK.addonSent or {}
    table.insert(MOCK.addonSent, { prefix = prefix, text = text, channel = channel })
  end,
}
function SendChatMessage(text, channel)
  MOCK.said = MOCK.said or {}
  table.insert(MOCK.said, { text = text, channel = channel })
end
function QuestLogPushQuest() MOCK.pushed = MOCK.selectedQuest end
-- The world map: OpenWorldMap records the map it opened.
function OpenWorldMap(map) MOCK.openedMap = map end
C_Map = {
  GetBestMapForUnit = function() return MOCK.questMap end,
  -- MOCK.mapInfo[id] = { name, mapType, parentMapID } (opt-in: other names change "Travel to" captions)
  GetMapInfo = function(id)
    local m = MOCK.mapInfo and MOCK.mapInfo[id]
    if m then return m end
    return id == 1433 and { name = "Redridge Mountains" } or nil
  end,
  GetMapWorldSize = function(id)
    local size = MOCK.mapSizes and MOCK.mapSizes[id]
    if size then return size[1], size[2] end
  end,
  GetPlayerMapPosition = function()
    return { GetXY = function() return MOCK.questX / 100, MOCK.questY / 100 end }
  end,
  -- The map waypoint: MOCK.userWaypoint = { uiMapID, position = { x, y } } (0-1), MOCK.noWaypointMaps[map].
  SetUserWaypoint = function(point) MOCK.userWaypoint = point end,
  GetUserWaypoint = function() return MOCK.userWaypoint end,
  ClearUserWaypoint = function() MOCK.userWaypoint = nil end,
  CanSetUserWaypointOnMap = function(map) return not (MOCK.noWaypointMaps and MOCK.noWaypointMaps[map]) end,
}
C_SuperTrack = { SetSuperTrackedUserWaypoint = function(on) MOCK.superTracked = on end }
function GetPlayerFacing() return MOCK.facing end
function GetBindLocation() return MOCK.bind end
function GetInstanceInfo()
  return MOCK.instanceName, MOCK.instanceName and "party" or "none", nil, nil, nil, nil, nil, MOCK.instanceID
end
function UnitOnTaxi() return MOCK.onTaxi or false end
-- XP: MOCK.xp / MOCK.xpMax / MOCK.rested; MOCK.rewardXP[questID] for GetQuestLogRewardXP.
function UnitXP() return MOCK.xp or 0 end
function UnitXPMax() return MOCK.xpMax or 0 end
function GetXPExhaustion() return MOCK.rested end
function GetQuestLogRewardXP(id) return MOCK.rewardXP and MOCK.rewardXP[id] or 0 end
-- Death: MOCK.ghost = released, MOCK.corpse = { map, x, y } (percent) for C_DeathInfo.
function UnitIsGhost() return MOCK.ghost or false end
C_DeathInfo = {
  GetCorpseMapPosition = function(map)
    local c = MOCK.corpse
    if c and c[1] == map then return { GetXY = function() return c[2] / 100, c[3] / 100 end } end
  end,
}
function NumTaxiNodes() return #(MOCK.taxiNodes or {}) end
function TaxiNodeName(i) return MOCK.taxiNodes[i][1] end
function TaxiNodeGetType(i) return MOCK.taxiNodes[i][2] end
function TakeTaxiNode(i) MOCK.tookTaxi = i end
-- Blizzard's popups belong to the Blizzard UI. Confirming an NPC interaction from addon code is
-- blocked (Forever's ADDON_ACTION_FORBIDDEN dialog), and StaticPopup_Hide from addon code taints the
-- popup system, so the next protected popup button (the Spirit Healer's Accept) is blocked and
-- blamed on the addon. Every call here comes from the addon, so each one is a problem.
local function blizzardOnly(name)
  return function(which)
    MOCK.forbidden = name
    problem("forbidden", name .. "(" .. tostring(which) .. ") from addon code: only the Blizzard UI may call it")
  end
end
-- Secret values (Forever hides some numbers from addon code, e.g. your speed in flight): MOCK.SECRET
-- stands for one. Arithmetic on it fails like the client's "numeric conversion on a secret value".
MOCK.SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function issecretvalue(v) return v == MOCK.SECRET end
local rawTonumber = tonumber
function tonumber(v, ...)
  if v == MOCK.SECRET then error("attempt to perform numeric conversion on a secret number value", 2) end
  return rawTonumber(v, ...)
end
-- GetUnitSpeed: current, run, flight, swim (MOCK.runSpeed, default 7).
function GetUnitSpeed(unit)
  local run = MOCK.runSpeed or 7
  return run == MOCK.SECRET and run or 0, run, run, run
end
-- The client's call stack (WoW's debugstack: start 1 = the function that calls it, then the top
-- `top` levels; Lua's own traceback drops the middle of deep stacks).
function debugstack(start, top)
  local lines, level = {}, (start or 1) + 1
  while #lines < (top or 12) do
    local info = debug.getinfo(level, "Sln")
    if not info then break end
    if info.what == "C" then
      lines[#lines + 1] = "[C]: in function '" .. tostring(info.name or "?") .. "'"
    else
      local src = info.source:sub(1, 1) == "@" and info.source:sub(2) or info.short_src
      lines[#lines + 1] = src .. ":" .. tostring(info.currentline) .. ": in function " .. tostring(info.name or "?")
    end
    level = level + 1
  end
  return table.concat(lines, "\n")
end
ConfirmBinder = blizzardOnly("ConfirmBinder")
StaticPopup_Hide = blizzardOnly("StaticPopup_Hide")
C_PlayerInteractionManager = {
  ConfirmationInteraction = blizzardOnly("C_PlayerInteractionManager.ConfirmationInteraction"),
  ClearInteraction = blizzardOnly("C_PlayerInteractionManager.ClearInteraction"),
}
Enum = { PlayerInteractionType = { Binder = 5, SpiritHealer = 7 } }
-- Quest log usable items, by log index: MOCK.questItems[i] = { link, icon }.
MOCK.questItems = {}
function GetQuestLogSpecialItemInfo(i)
  local q = MOCK.questItems[i]
  if q then return q[1], q[2], 1, true end
end
function GetItemIcon(item) return "Interface\\Icons\\INV_Misc_QuestionMark" end
-- Gossip list (C_GossipInfo) and the greeting window; selections are recorded.
MOCK.gossipAvailable, MOCK.gossipActive, MOCK.greetingAvailable = {}, {}, {}
C_GossipInfo = {
  GetAvailableQuests = function() return MOCK.gossipAvailable end,
  GetActiveQuests = function() return MOCK.gossipActive end,
  SelectAvailableQuest = function(id) MOCK.gossipPicked = id end,
  SelectActiveQuest = function(id) MOCK.gossipPicked = id end,
  -- MOCK.gossipOptions = { { gossipOptionID, name, icon } }; SelectOption records MOCK.gossipOption.
  GetOptions = function() return MOCK.gossipOptions or {} end,
  SelectOption = function(id) MOCK.gossipOption = id end,
}
function GetNumAvailableQuests() return #MOCK.greetingAvailable end
function GetAvailableTitle(i) return MOCK.greetingAvailable[i] and MOCK.greetingAvailable[i].title end
function GetAvailableQuestInfo(i)
  local q = MOCK.greetingAvailable[i]
  if q then return false, 0, false, false, q.questID end
end
function SelectAvailableQuest(i) MOCK.greetingPicked = i end
function IsAltKeyDown() return MOCK.alt or false end
function GetQuestID() return MOCK.interactionQuest end
function GetNumQuestChoices() return MOCK.questChoices or 0 end
function AcceptQuest() MOCK.questAccepted = MOCK.interactionQuest end
function GetQuestReward() MOCK.questRewarded = MOCK.interactionQuest end
-- Reward choices: MOCK.rewardChoices[i] = { name, count, sellPrice (nil = not cached yet) }.
function GetQuestItemInfo(kind, i)
  local r = kind == "choice" and MOCK.rewardChoices and MOCK.rewardChoices[i]
  if r then return r[1], 134400, r[2] or 1, 2, true end
end
function GetQuestItemLink(kind, i)
  local r = kind == "choice" and MOCK.rewardChoices and MOCK.rewardChoices[i]
  if r then return "|cff1eff00|Hitem:" .. (70000 + i) .. "::::::::|h[" .. r[1] .. "]|h|r" end
end

----------------------------------------------------------------------------
-- Widgets
----------------------------------------------------------------------------

local Region, Texture, FontString, Frame, Button, ScrollFrame, EditBox, Slider = {}, {}, {}, {}, {}, {}, {}, {}
local AnimGroup, Anim = {}, {}

local function inherit(child, parent)
  for k, v in pairs(parent) do if child[k] == nil then child[k] = v end end
end

local function new(class, otype, parent, name)
  local o = setmetatable({ _type = otype, _parent = parent, _shown = true, _points = {}, _w = 0, _h = 0,
    _alpha = 1, _scale = 1, _name = name, _scripts = {}, _children = {}, _regions = {} }, { __index = class })
  return o
end

-- Region (shared by frames and textures/fontstrings)
function Region:GetObjectType() return self._type end
function Region:IsObjectType(t) return self._type == t or (t == "Frame" and self._isFrame) or (t == "Region") end
function Region:GetName() return self._name end
function Region:GetParent() return self._parent end
-- Secure frames (SecureActionButtonTemplate) refuse changes in combat, like the client.
local function secureCheck(self, what)
  if self._secure and MOCK.combat then error("ADDON_ACTION_BLOCKED: " .. what .. " on a secure frame in combat", 3) end
end
function Region:SetPoint(point, rel, relPoint, x, y)
  secureCheck(self, "SetPoint")
  if type(rel) == "number" then rel, relPoint, x, y = nil, point, rel, relPoint end
  if type(rel) == "string" then rel = _G[rel] end
  if rel == self then error("Cannot anchor to itself", 2) end
  -- anchoring to a frame anchored to us would be a loop
  if type(rel) == "table" and rel._points then
    for _, p in ipairs(rel._points) do
      if p[2] == self then error("Cannot anchor to a region dependent on it", 2) end
    end
  end
  if relPoint == nil then relPoint = point end
  for i, p in ipairs(self._points) do
    if p[1] == point then table.remove(self._points, i); break end
  end
  self._points[#self._points + 1] = { point, rel or self._parent, relPoint, x or 0, y or 0 }
  self._pointSets = (self._pointSets or 0) + 1 -- lets tests see whether something was moved
end
function Region:SetAllPoints(rel) self:ClearAllPoints(); self:SetPoint("TOPLEFT", rel or self._parent); self:SetPoint("BOTTOMRIGHT", rel or self._parent) end
function Region:ClearAllPoints() self._points = {} end
function Region:GetNumPoints() return #self._points end
function Region:GetPoint(i)
  local p = self._points[i or 1]
  if p then return p[1], p[2], p[3], p[4], p[5] end
end
function Region:SetSize(w, h) self._w, self._h = w, h end
function Region:SetWidth(w) self._w = w end
function Region:SetHeight(h) self._h = h end
function Region:GetWidth() return self._w end
function Region:GetHeight() return self._h end
function Region:GetSize() return self._w, self._h end
function Region:GetCenter()
  -- a frame placed by its centre from the screen's bottom left is where it says (its own units)
  local p = self._points[1]
  if p and p[1] == "CENTER" and p[2] == UIParent and p[3] == "BOTTOMLEFT" then return p[4], p[5] end
  return self._cx or 500, self._cy or 500
end
function Region:GetLeft() return 0 end
function Region:GetTop() return self._top or 700 end
function Region:GetBottom() return self._bottom or 100 end
function Region:IsShown() return self._shown end
function Region:IsVisible()
  local f = self
  while f do
    if not f._shown then return false end
    f = f._parent
  end
  return true
end
local function fire(self, script, ...)
  local fn = self._scripts[script]
  if fn then return fn(self, ...) end
end
MOCK.fire = fire
function Region:Show()
  secureCheck(self, "Show")
  if self._shown then return end
  self._shown = true
  if self:IsVisible() then fire(self, "OnShow") end
end
function Region:Hide()
  secureCheck(self, "Hide")
  if not self._shown then return end
  local wasVisible = self:IsVisible()
  self._shown = false
  if wasVisible then fire(self, "OnHide") end
end
function Region:SetShown(on) if on then self:Show() else self:Hide() end end
function Region:SetAlpha(a) self._alpha = a end
function Region:GetAlpha() return self._alpha end
function Region:SetScale(s) self._scale = s end
function Region:GetScale() return self._scale end
function Region:GetEffectiveScale() return self._scale end
function Region:CreateAnimationGroup()
  local g = setmetatable({ _owner = self, _anims = {}, _scripts = {}, _playing = false, _elapsed = 0 }, { __index = AnimGroup })
  return g
end
function Region:SetParent(p)
  self._parent = p
end
function Region:SetIgnoreParentAlpha() end
function Region:SetIgnoreParentScale() end

-- Texture
inherit(Texture, Region)
function Texture:SetTexture(path)
  if path == nil then self._tex = nil; return true end
  if type(path) == "string" then
    if path == "" then problem("texture", "empty path"); return false end
    if MOCK.missingTextures[path:lower()] then return false end
    self._tex = GetFileIDFromPath and GetFileIDFromPath(path) or MOCK.fileID(path)
    self._path = path
    return true
  end
  self._tex = path
  return true
end
function Texture:GetTexture() return self._tex end
function Texture:SetAtlas(name)
  if not (MOCK.atlases[name]) then error("SetAtlas: unknown atlas " .. tostring(name), 2) end
  self._atlas, self._tex = name, "atlas:" .. name
  return true
end
function Texture:GetAtlas() return self._atlas end
function Texture:SetTexCoord(...) self._coords = { ... } end
function Texture:GetTexCoord()
  local c = self._coords or { 0, 1, 0, 1 }
  if #c == 4 then return c[1], c[3], c[1], c[4], c[2], c[3], c[2], c[4] end
  return unpack(c)
end
function Texture:SetColorTexture(r, g, b, a)
  if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then error("SetColorTexture: bad color", 2) end
  self._tex = "color"
  self._color = { r, g, b, a or 1 }
  -- like the client: a gradient or rotation from an earlier use survives a new colour
  if self._grad then self._gradStale = true end
  if self._rot and self._rot ~= 0 then self._rotStale = true end
end
function Texture:SetVertexColor() end
function Texture:SetBlendMode(m) if m ~= "ADD" and m ~= "BLEND" and m ~= "ALPHAKEY" and m ~= "DISABLE" and m ~= "MOD" then error("bad blend mode", 2) end end
function Texture:SetDrawLayer(layer, sub)
  if sub and (sub < -8 or sub > 7) then error("SetDrawLayer: sublevel out of range", 2) end
  self._layer = layer
end
function Texture:SetHorizTile() end
function Texture:SetVertTile() end
function Texture:SetDesaturated(on) self._desat = on and true or false end
function Texture:SetRotation(r) self._rot, self._rotStale = r, false end
function Texture:SetGradient(orient, c1, c2)
  if type(c1) ~= "table" or type(c2) ~= "table" then error("SetGradient expects colors", 2) end
  self._grad, self._gradStale = true, false
end

-- FontString
inherit(FontString, Region)
function FontString:SetText(s)
  if s ~= nil and type(s) ~= "string" and type(s) ~= "number" then error("SetText: bad type " .. type(s), 2) end
  s = s and tostring(s) or nil
  ascii(s, "FontString:SetText")
  self._text = s
end
function FontString:SetFormattedText(fmt, ...) self:SetText(string.format(fmt, ...)) end
function FontString:GetText() return self._text end
function FontString:SetFont(path, size, flags)
  if type(path) ~= "string" or type(size) ~= "number" then error("SetFont: bad args", 2) end
  self._font, self._fontStale = path, false
  return true
end
function FontString:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
-- like the client: a font set with SetFont sticks; SetFontObject alone doesn't replace it
function FontString:SetFontObject(o)
  if self._font then self._fontStale = true end
end
function FontString:SetTextColor(r, g, b)
  if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then error("SetTextColor: bad color", 2) end
end
function FontString:SetShadowColor() end
function FontString:SetShadowOffset() end
function FontString:SetSpacing() end
function FontString:SetWordWrap() end
function FontString:SetNonSpaceWrap() end
function FontString:SetMaxLines() end
function FontString:SetJustifyH(j) if j ~= "LEFT" and j ~= "RIGHT" and j ~= "CENTER" then error("SetJustifyH: " .. tostring(j), 2) end end
function FontString:SetJustifyV() end
function FontString:GetStringWidth() return #(self._text or "") * 6 end
function FontString:GetStringHeight()
  local t = self._text or ""
  if t == "" then return 0 end
  local w = self._w > 0 and self._w or 10000
  local lines = 0
  for line in (t .. "\n"):gmatch("(.-)\n") do lines = lines + math.max(1, math.ceil(#line * 6 / w)) end
  return lines * 14
end

-- Frame
inherit(Frame, Region)
function Frame:CreateTexture(name, layer, template, sub)
  local t = new(Texture, "Texture", self, name)
  self._regions[#self._regions + 1] = t
  if name then _G[name] = t end
  MOCK.textures = MOCK.textures + 1
  return t
end
function Frame:CreateFontString(name, layer, template)
  local fs = new(FontString, "FontString", self, name)
  self._regions[#self._regions + 1] = fs
  if name then _G[name] = fs end
  return fs
end
local SCRIPTS = {
  OnShow = 1, OnHide = 1, OnUpdate = 1, OnEvent = 1, OnEnter = 1, OnLeave = 1, OnClick = 1, OnMouseUp = 1,
  OnMouseDown = 1, OnDragStart = 1, OnDragStop = 1, OnMouseWheel = 1, OnKeyDown = 1, OnKeyUp = 1,
  OnGamePadButtonDown = 1, OnGamePadButtonUp = 1, OnGamePadStick = 1, OnEscapePressed = 1, OnEnterPressed = 1, OnTextChanged = 1,
  OnEditFocusGained = 1, OnEditFocusLost = 1, OnVerticalScroll = 1, OnScrollRangeChanged = 1, OnSizeChanged = 1,
  OnValueChanged = 1, OnLoad = 1, PreClick = 1, PostClick = 1, OnDoubleClick = 1, OnChar = 1,
}
function Frame:SetScript(name, fn)
  if not SCRIPTS[name] then error("SetScript: unknown script " .. tostring(name), 2) end
  if fn ~= nil and type(fn) ~= "function" then error("SetScript: handler must be a function", 2) end
  self._scripts[name] = fn
  if name == "OnUpdate" then MOCK.updaters[self] = fn and true or nil end
end
function Frame:GetScript(name) return self._scripts[name] end
function Frame:HasScript(name) return SCRIPTS[name] ~= nil end
function Frame:HookScript(name, fn)
  local old = self._scripts[name]
  self:SetScript(name, function(...) if old then old(...) end; fn(...) end)
end
-- Forever keeps the combat log from addons: registering or unregistering COMBAT_LOG_EVENT_UNFILTERED
-- is blocked ("blocked from an action only available to the Blizzard UI", UNKNOWN()), even in pcall.
local BLIZZARD_ONLY_EVENTS = { COMBAT_LOG_EVENT_UNFILTERED = true }
local function eventForbidden(ev, how)
  if not BLIZZARD_ONLY_EVENTS[ev] then return false end
  MOCK.forbidden = how .. " " .. ev
  problem("forbidden", how .. "(" .. ev .. ") from addon code: only the Blizzard UI may do it")
  return true
end
function Frame:RegisterEvent(ev)
  if not MOCK.knownEvents[ev] then error('Attempt to register unknown event "' .. tostring(ev) .. '"', 2) end
  if eventForbidden(ev, "RegisterEvent") then return end
  MOCK.events[ev] = MOCK.events[ev] or {}
  MOCK.events[ev][self] = true
end
-- A unit event for the units named only: MOCK.unitEvents[ev][frame] = { units }.
MOCK.unitEvents = {}
function Frame:RegisterUnitEvent(ev, ...)
  if not MOCK.knownEvents[ev] then error('Attempt to register unknown event "' .. tostring(ev) .. '"', 2) end
  if eventForbidden(ev, "RegisterUnitEvent") then return end
  if MOCK.events[ev] then MOCK.events[ev][self] = nil end
  MOCK.unitEvents[ev] = MOCK.unitEvents[ev] or {}
  MOCK.unitEvents[ev][self] = { ... }
end
function Frame:UnregisterEvent(ev)
  if eventForbidden(ev, "UnregisterEvent") then return end
  if MOCK.events[ev] then MOCK.events[ev][self] = nil end
  if MOCK.unitEvents[ev] then MOCK.unitEvents[ev][self] = nil end
end
function Frame:UnregisterAllEvents()
  for _, set in pairs(MOCK.events) do set[self] = nil end
  for _, set in pairs(MOCK.unitEvents) do set[self] = nil end
end
function Frame:IsEventRegistered(ev)
  return (MOCK.events[ev] and MOCK.events[ev][self]) or (MOCK.unitEvents[ev] and MOCK.unitEvents[ev][self] and true) or false
end
function Frame:SetFrameStrata(s) self._strata = s end
function Frame:GetFrameStrata() return self._strata or "MEDIUM" end
function Frame:SetFrameLevel(l) self._level = l end
function Frame:GetFrameLevel() return self._level or 1 end
function Frame:SetToplevel() end
function Frame:Raise() end
function Frame:SetMovable(on) self._movable = on end
function Frame:IsMovable() return self._movable end
-- Buttons take the mouse by default, other frames don't (like the client).
function Frame:EnableMouse(on) self._mouse = on and true or false end
function Frame:IsMouseEnabled()
  if self._mouse ~= nil then return self._mouse end
  return self._type == "Button" or self._type == "CheckButton"
end
function Frame:EnableMouseWheel(on) self._wheel = on and true or false end
function Frame:IsMouseWheelEnabled() return self._wheel or false end
-- Mouse motion (OnEnter/OnLeave) and clicks apart: a click-through frame still gets its tooltip.
function Frame:SetMouseClickEnabled(on) self._mouseClick = on and true or false end
function Frame:SetMouseMotionEnabled(on) self._mouseMotion = on and true or false end
function Frame:EnableKeyboard() end
function Frame:SetPropagateKeyboardInput() end
function Frame:SetClampedToScreen() end
function Frame:RegisterForDrag() end
function Frame:StartMoving()
  if not self._movable then error("Frame is not movable", 2) end
  self._moving = true
end
function Frame:StopMovingOrSizing() self._moving = false end
function Frame:GetChildren()
  MOCK.walked = (MOCK.walked or 0) + 1 -- lets tests measure how much the talent finder walks
  return unpack(self._children)
end
function Frame:GetNumChildren() return #self._children end
function Frame:GetRegions() return unpack(self._regions) end
function Frame:IsMouseOver() return MOCK.mouseOver[self] and true or false end
function Frame:SetHitRectInsets() end
function Frame:SetID(id) self._id = id end
function Frame:GetID() return self._id or 0 end
function Frame:EnableGamePadButton(on) self._gamepad = on end
function Frame:SetPropagateGamePadInput(on) self._padPropagate = on end
function Frame:EnableGamePadStick(on) self._padStick = on end
function Frame:SetResizable() end
function Frame:SetUserPlaced() end
function Frame:IsUserPlaced() return false end
-- modern clients: only frames made with BackdropTemplate have backdrops
function Frame:SetBackdrop(b)
  if BackdropTemplateMixin and not self._backdropTemplate then error("SetBackdrop needs BackdropTemplate", 2) end
  if type(b) ~= "table" or type(b.edgeFile) ~= "string" then error("SetBackdrop: bad backdrop", 2) end
  self._backdrop = b
end
function Frame:SetBackdropColor(r, g, b) if not self._backdrop then error("SetBackdropColor without a backdrop", 2) end end
function Frame:SetBackdropBorderColor(r, g, b) if not self._backdrop then error("SetBackdropBorderColor without a backdrop", 2) end end
function Frame:SetClampRectInsets(l, r, t, b) self._clampInsets = { l or 0, r or 0, t or 0, b or 0 } end
function Frame:GetClampRectInsets() return unpack(self._clampInsets or { 0, 0, 0, 0 }) end
function Frame:SetParent(p)
  local old = self._parent
  if old and old._children then
    for i, c in ipairs(old._children) do if c == self then table.remove(old._children, i); break end end
  end
  self._parent = p
  if p then p._children[#p._children + 1] = self end
end

-- Button
inherit(Button, Frame)
function Button:RegisterForClicks(...) self._clicks = { ... } end
function Button:SetAttribute(key, value)
  secureCheck(self, "SetAttribute")
  self._attrs = self._attrs or {}
  self._attrs[key] = value
end
function Button:GetAttribute(key) return self._attrs and self._attrs[key] end
function Button:SetHighlightTexture(t) end
function Button:SetNormalTexture(t) end
function Button:SetPushedTexture(t) end
function Button:Enable() self._disabled = false end
function Button:Disable() self._disabled = true end
function Button:IsEnabled() return not self._disabled end
function Button:SetEnabled(on) self._disabled = not on end
function Button:LockHighlight() self._lit = true end
function Button:UnlockHighlight() self._lit = false end
function Button:SetChecked(on) self._checked = on and true or false end
function Button:GetChecked() return self._checked or false end
function Button:SetCheckedTexture() end
function Button:Click(btn)
  if self._disabled then return end
  if self._type == "CheckButton" then self._checked = not self._checked end
  fire(self, "PreClick", btn or "LeftButton", false)
  fire(self, "OnClick", btn or "LeftButton", false)
  fire(self, "PostClick", btn or "LeftButton", false)
end
function Button:SetText(s) ascii(s, "Button:SetText"); self._text = s end
function Button:GetText() return self._text end
function Button:GetFontString() return self._fs end

-- ScrollFrame
inherit(ScrollFrame, Frame)
function ScrollFrame:SetScrollChild(c) self._child = c end
function ScrollFrame:GetScrollChild() return self._child end
function ScrollFrame:GetVerticalScrollRange()
  local ch = self._child and self._child:GetHeight() or 0
  return math.max(0, ch - (self._h > 0 and self._h or 480))
end
function ScrollFrame:SetVerticalScroll(v)
  if type(v) ~= "number" then error("SetVerticalScroll: number expected", 2) end
  self._scroll = math.max(0, math.min(v, self:GetVerticalScrollRange()))
  fire(self, "OnVerticalScroll", self._scroll)
end
function ScrollFrame:GetVerticalScroll() return self._scroll or 0 end
function ScrollFrame:UpdateScrollChildRect() end
function ScrollFrame:SetHorizontalScroll() end

-- Slider
inherit(Slider, Frame)
function Slider:SetMinMaxValues(a, b) self._min, self._max = a, b end
function Slider:SetValue(v) self._value = v; fire(self, "OnValueChanged", v) end
function Slider:GetValue() return self._value or 0 end
function Slider:SetValueStep() end
function Slider:SetObeyStepOnDrag() end
function Slider:SetOrientation() end
function Slider:SetThumbTexture() end

-- EditBox
inherit(EditBox, Frame)
function EditBox:SetText(s) ascii(s, "EditBox:SetText"); self._text = s; fire(self, "OnTextChanged", false) end
function EditBox:GetText() return self._text or "" end
function EditBox:SetMultiLine(on) self._multi = on end
function EditBox:SetAutoFocus() end
function EditBox:SetFocus() self._focus = true; MOCK.focus = self end
function EditBox:ClearFocus() self._focus = false; if MOCK.focus == self then MOCK.focus = nil end end
function EditBox:HasFocus() return self._focus or false end
function EditBox:HighlightText(a, b) self._highlight = { a or 0, b or -1 } end
function EditBox:SetFontObject() end
function EditBox:SetFont() return true end
function EditBox:SetTextColor() end
function EditBox:SetMaxLetters() end
function EditBox:SetCursorPosition() end
function EditBox:SetTextInsets() end
function EditBox:SetJustifyH() end
function EditBox:SetSpacing() end
function EditBox:Insert(s) self._text = (self._text or "") .. s end

-- Animations
function AnimGroup:CreateAnimation(kind)
  local a = setmetatable({ _kind = kind, _dur = 0, _order = 1, _delay = 0, _group = self }, { __index = Anim })
  self._anims[#self._anims + 1] = a
  return a
end
function AnimGroup:SetLooping(l) self._loop = l end
function AnimGroup:SetToFinalAlpha() end
function AnimGroup:SetScript(name, fn) self._scripts[name] = fn end
function AnimGroup:GetScript(name) return self._scripts[name] end
function AnimGroup:IsPlaying() return self._playing end
function AnimGroup:Play()
  -- seen in game: an animated texture with a gradient draws as a solid white box in Forever
  local o = self._owner
  if o and o._type == "Texture" and o._grad then problem("animated gradient", "a faded texture is animated (white box in Forever)") end
  self._playing, self._elapsed = true, 0
  local byOrder = {}
  for _, a in ipairs(self._anims) do
    byOrder[a._order] = math.max(byOrder[a._order] or 0, a._delay + a._dur)
  end
  local total = 0
  for _, d in pairs(byOrder) do total = total + d end
  self._total = total
  MOCK.anims[self] = true
  if self._scripts.OnPlay then self._scripts.OnPlay(self) end
end
function AnimGroup:Stop()
  self._playing = false
  MOCK.anims[self] = nil
end
function AnimGroup:Pause() self._playing = false end
function AnimGroup:Finish() self._elapsed = self._total or 0 end
local ANIM_METHODS = { "SetOffset", "SetSmoothing", "SetFromAlpha", "SetToAlpha", "SetDegrees", "SetScaleFrom",
  "SetScaleTo", "SetScale", "SetOrigin", "SetChange", "SetTarget", "SetChildKey", "SetEndDelay" }
for _, m in ipairs(ANIM_METHODS) do Anim[m] = function() end end
function Anim:SetDuration(d) self._dur = d end
function Anim:SetOrder(o) self._order = o end
function Anim:SetStartDelay(d) self._delay = d end
function Anim:GetStartDelay() return self._delay end

----------------------------------------------------------------------------
-- CreateFrame and templates
----------------------------------------------------------------------------

local CLASSES = { Frame = Frame, Button = Button, ScrollFrame = ScrollFrame, EditBox = EditBox, Slider = Slider,
  CheckButton = Button, StatusBar = Frame, GameTooltip = Frame }

function CreateFrame(kind, name, parent, template)
  local class = CLASSES[kind]
  if not class then error("CreateFrame: unknown frame type " .. tostring(kind), 2) end
  if parent == nil and UIParent and kind ~= "GameTooltip" then parent = nil end
  local f = new(class, kind, parent, name)
  f._isFrame = true
  if parent then parent._children[#parent._children + 1] = f end
  MOCK.frames[#MOCK.frames + 1] = f
  f._idx = #MOCK.frames
  if name then _G[name] = f end
  if template then
    for t in tostring(template):gmatch("[^,%s]+") do
      if t == "UIPanelCloseButton" then
        f:SetSize(32, 32)
        f:SetScript("OnClick", function(self) self:GetParent():Hide() end)
      elseif t == "UIPanelScrollFrameTemplate" then
        f.ScrollBar = CreateFrame("Slider", name and name .. "ScrollBar" or nil, f)
      elseif MOCK.disabledTemplates[t] then
        error("CreateFrame: unknown template " .. t, 2)
      elseif t == "BackdropTemplate" then
        f._backdropTemplate = true
      elseif t == "UICheckButtonTemplate" then
        if kind ~= "CheckButton" then error("UICheckButtonTemplate needs a CheckButton", 2) end
        f:SetSize(32, 32)
      elseif t == "SecureActionButtonTemplate" then
        f._secure = true
      elseif t == "UIPanelButtonTemplate" then
        -- the red panel art in three pieces, like the client's template
        for _, k in ipairs({ "Left", "Middle", "Right" }) do
          f[k] = f:CreateTexture(nil, "BACKGROUND")
          f[k]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        end
      elseif t == "InputBoxTemplate" then
        -- nothing extra needed
      else
        error("CreateFrame: unknown template " .. t, 2)
      end
    end
  end
  return f
end

----------------------------------------------------------------------------
-- Globals
----------------------------------------------------------------------------

UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(1920, 1080)
UIParent._top, UIParent._bottom = 1080, 0
WorldFrame = CreateFrame("Frame", "WorldFrame")

Minimap = CreateFrame("Frame", "Minimap", UIParent)
Minimap:SetSize(140, 140)
Minimap._cx, Minimap._cy = 1780, 940
-- Zoom level (MOCK.minimapZoom, 0-5), indoors (MOCK.indoors), console variables (MOCK.cvars).
function Minimap:GetZoom() return MOCK.minimapZoom or 0 end
function IsIndoors() return MOCK.indoors or false end
MOCK.cvars = {}
function GetCVar(name) return MOCK.cvars and MOCK.cvars[name] end

-- The world map: a canvas (ScrollContainer.Child, 1002 x 668) showing MOCK.worldMapID.
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame", UIParent)
WorldMapFrame:Hide()
WorldMapFrame.ScrollContainer = CreateFrame("Frame", nil, WorldMapFrame)
WorldMapFrame.ScrollContainer.Child = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
WorldMapFrame.ScrollContainer.Child:SetSize(1002, 668)
-- The map's zoom: the canvas (Child) is drawn this many times larger (MOCK.canvasScale).
function WorldMapFrame.ScrollContainer:GetCanvasScale() return MOCK.canvasScale or 1 end
function WorldMapFrame:GetMapID() return MOCK.worldMapID end
function WorldMapFrame:OnMapChanged() end

-- The vendor window (MOCK.openMerchant shows it).
MerchantFrame = CreateFrame("Frame", "MerchantFrame", UIParent)
MerchantFrame:SetSize(336, 447)
MerchantFrame:Hide()

GameTooltip = CreateFrame("Frame", "GameTooltip", UIParent)
GameTooltip:Hide()
function GameTooltip:SetOwner(owner, anchor) self._owner = owner; self._lines = {} end
function GameTooltip:SetText(s) ascii(s, "GameTooltip:SetText"); self._lines = { s } end
function GameTooltip:AddLine(s) ascii(s, "GameTooltip:AddLine"); self._lines[#self._lines + 1] = s end
function GameTooltip:AddDoubleLine(a, b) ascii(a, "GameTooltip"); ascii(b, "GameTooltip") end
function GameTooltip:ClearLines() self._lines = {} end
function GameTooltip:IsOwned(f) return self._owner == f end

DEFAULT_CHAT_FRAME = CreateFrame("Frame", "ChatFrame1", UIParent)
function DEFAULT_CHAT_FRAME:AddMessage(s)
  if type(s) ~= "string" then error("AddMessage: string expected", 2) end
  ascii(s, "chat")
  MOCK.chat[#MOCK.chat + 1] = s
end

-- font objects (GetFont gives the face, size and flags)
for name, size in pairs({ GameFontNormal = 12, GameFontNormalSmall = 10, GameFontNormalLarge = 16, GameFontNormalHuge = 20,
    GameFontHighlight = 12, GameFontHighlightSmall = 10, GameFontDisableSmall = 10, ChatFontNormal = 14 }) do
  _G[name] = { GetFont = function() return "Fonts\FRIZQT__.TTF", size, "" end }
end

UISpecialFrames = {}
SlashCmdList = {}
tinsert = table.insert
tremove = table.remove
strlower = string.lower
strupper = string.upper
strfind = string.find
format = string.format
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strsplit(sep, s)
  local out = {}
  for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = piece end
  return unpack(out)
end

function GetTime() return MOCK.time end
function time() return 1700000000 + math.floor(MOCK.time) end
function UnitLevel(unit) return MOCK.level end
function UnitName() return "Tester" end
local CLASS_NAMES = { WARRIOR = "Warrior", MAGE = "Mage", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
  PALADIN = "Paladin", SHAMAN = "Shaman", WARLOCK = "Warlock", DRUID = "Druid" }
function UnitClass(unit) return CLASS_NAMES[MOCK.class] or MOCK.class, MOCK.class end
function InCombatLockdown() return MOCK.combat end
function GetCursorPosition() return MOCK.cursor[1], MOCK.cursor[2] end
function PlaySound() end
SOUNDKIT = { LEVEL_UP = 888 }
function ReloadUI() error("ReloadUI is protected in Forever", 2) end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
function GetMinimapShape() return MOCK.minimapShape or "ROUND" end
function IsShiftKeyDown() return MOCK.shift or false end
function IsControlKeyDown() return MOCK.ctrl or false end

-- Questie (opt-in, made by scenarios): its settings and its tracker frame.
-- MOCK.makeQuestie{ autoAccept, autocomplete, modifier = "shift", legacyAccept, tracker = false, cx }
function MOCK.makeQuestie(opts)
  opts = opts or {}
  local profile = { autocomplete = opts.autocomplete == true, autoModifier = opts.modifier or "shift" }
  if opts.legacyAccept then profile.autoaccept = true else profile.autoAccept = { enabled = opts.autoAccept == true } end
  Questie = { db = { profile = profile } }
  local tracker = _G.Questie_BaseFrame
  if opts.tracker == false then
    if tracker then tracker:Hide() end
    return
  end
  if not tracker then
    tracker = CreateFrame("Frame", "Questie_BaseFrame", UIParent)
    tracker:SetSize(280, 400)
  end
  tracker._cx, tracker._cy = opts.cx or 1700, 700
  tracker:Show()
end

-- QuestieDB's LibQuestieDB (opt-in, made by scenarios), a new table on every call.
-- MOCK.makeQuestieDB{ contract = 4, quests = { [id] = { objectives } }, npcs/objects = { [id] = { name, spawns } },
--   items = { [id] = { name, npcDrops, objectDrops } }, zones = "return {...}", noZones }
-- Entity getters raise while MOCK.questieDBError is set.
function MOCK.makeQuestieDB(opts)
  opts = opts or {}
  local contract = opts.contract or 4
  local function getter(source, field)
    return function(id)
      if MOCK.questieDBError then error("mock read error", 2) end
      local row = source and source[id]
      return row and row[field]
    end
  end
  local npcs, objects, items = opts.npcs or {}, opts.objects or {}, opts.items or {}
  local zoneDB = not opts.noZones and { private = {
    areaIdToUiMapId = opts.zones or "return { [12] = 1429, [40] = 1436 }",
    areaIdToUiMapIdOverride = "return { [0] = 0 }",
  } } or nil
  LibQuestieDB = {
    contractVersion = contract, minSupportedContract = 1, readMode = "baked",
    RequireContract = function(n)
      if type(n) == "number" and n >= 1 and n <= contract then return true end
      return false, "QuestieDB contract " .. contract .. " does not support " .. tostring(n)
    end,
    Quest = { objectives = getter(opts.quests or {}, "objectives") },
    Npc = { name = getter(npcs, "name"), spawns = getter(npcs, "spawns") },
    Object = { name = getter(objects, "name"), spawns = getter(objects, "spawns") },
    Item = { name = getter(items, "name"), npcDrops = getter(items, "npcDrops"), objectDrops = getter(items, "objectDrops") },
    Support = { Get = function(name) if name == "ZoneDB" then return zoneDB end end },
  }
end

function MOCK.fileID(path)
  local k = path:lower()
  if not MOCK.fileIDs[k] then MOCK.fileIDs[k] = MOCK.nextFileID; MOCK.nextFileID = MOCK.nextFileID + 1 end
  return MOCK.fileIDs[k]
end
function GetFileIDFromPath(path) return MOCK.fileID(path) end

C_Spell = { GetSpellName = function(id) return MOCK.spells[id] end }
BackdropTemplateMixin = {}
CLASS_ICON_TCOORDS = {}
for i, c in ipairs({ "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "SHAMAN", "PRIEST", "WARLOCK", "PALADIN" }) do
  local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
  CLASS_ICON_TCOORDS[c] = { col * 0.25, col * 0.25 + 0.25, row * 0.25, row * 0.25 + 0.25 }
end
C_Texture = { GetAtlasInfo = function(name) if MOCK.atlases[name] then return { width = 64, height = 64 } end end }
for _, a in ipairs({ "talents-node-circle-yellow", "talents-node-square-yellow", "talents-node-choice-yellow",
    "talents-node-circle-mask", "talents-node-square-mask", "talents-node-choice-mask" }) do
  MOCK.atlases[a] = true
end
function SetPortraitToTexture(tex, path)
  if type(path) ~= "string" and type(path) ~= "number" then error("SetPortraitToTexture: bad texture", 2) end
  tex._tex, tex._round = path, true
end
function GetBuildInfo() return "1.60.1", "99999", "Nov 1 2026", 16001 end
C_AddOns = { GetAddOnMetadata = function(addon, key) if key == "Version" then return "@project-version@" end end }

-- Talent points: Forever's trait system, and the classic call.
local function unspentNow()
  if MOCK.unspent then return MOCK.unspent end
  return MOCK.level >= 10 and 1 or 0
end
C_ClassTalents = { GetActiveConfigID = function() return 7 end }
C_Traits = {
  GetConfigInfo = function(id) return { ID = id, treeIDs = { 101 } } end,
  GetTreeCurrencyInfo = function(configID, treeID, excludeStaged)
    return { { traitCurrencyID = 55, quantity = unspentNow(), maxQuantity = 51, spent = 0 } }
  end,
}
function UnitCharacterPoints(unit) return unspentNow() end
-- the tree's layout: MOCK.traitNodes[nodeID] = { posX, posY, spellID } (empty = no layout yet)
MOCK.traitNodes = {}
C_Traits.GetTreeNodes = function(treeID)
  local ids = {}
  for id in pairs(MOCK.traitNodes) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end
C_Traits.GetNodeInfo = function(configID, nodeID)
  local n = MOCK.traitNodes[nodeID]
  if n then return { ID = nodeID, posX = n.posX, posY = n.posY, entryIDs = { nodeID } } end
end
C_Traits.GetEntryInfo = function(configID, entryID) return { definitionID = entryID } end
C_Traits.GetDefinitionInfo = function(defID)
  local n = MOCK.traitNodes[defID]
  return n and { spellID = n.spellID } or nil
end
function GetSpellInfo(id) return MOCK.spells[id] end

-- Minimap tracking (C_Minimap). MOCK.tracking[i] = { name, texture, active, category, spellID }.
-- Like Classic, only one "spell" tracking is on at a time unless MOCK.multiTrack.
MOCK.tracking = {}
MOCK.trackCalls = {}
MOCK.dead = false
C_Minimap = {
  -- The minimap's view radius in yards (MOCK.viewRadius; nil = the client doesn't say).
  GetViewRadius = function() return MOCK.viewRadius end,
  GetNumTrackingTypes = function() return #MOCK.tracking end,
  GetTrackingInfo = function(i)
    local t = MOCK.tracking[i]
    if t then return t.name, t.texture, t.active, t.category, false, t.spellID end
  end,
  SetTracking = function(i, on)
    local t = MOCK.tracking[i]
    if not t then error("SetTracking: bad index", 2) end
    if MOCK.combat then problem("tracking", "tracking changed in combat (" .. t.name .. ")") end
    MOCK.trackCalls[#MOCK.trackCalls + 1] = { name = t.name, on = on and true or false }
    if on and t.category == "spell" and not MOCK.multiTrack then
      for _, o in ipairs(MOCK.tracking) do if o.category == "spell" then o.active = false end end
    end
    t.active = on and true or false
    MOCK.event("MINIMAP_UPDATE_TRACKING")
  end,
}
function UnitIsDeadOrGhost() return MOCK.dead end
-- the vanilla calls (kept in the minimal client, which has no C_Minimap)
function GetTrackingTexture()
  for _, t in ipairs(MOCK.tracking) do if t.active and t.category == "spell" then return t.texture end end
end
function IsSpellKnown(id)
  for _, t in ipairs(MOCK.tracking) do if t.spellID == id then return true end end
  return false
end

-- Professions. MOCK.skills[i] = { name, rank, max }. Retail-style GetProfessions/GetProfessionInfo
-- (gone in the minimal client) and the classic skill list (always there, with a header row).
MOCK.skills = {}
MOCK.bags = {}       -- item name -> count (GetItemCount)
MOCK.faction, MOCK.race = nil, nil
local SECONDARY = { Cooking = true, Fishing = true, ["First Aid"] = true }
function MOCK.setSkill(name, rank, max)
  local s
  for _, x in ipairs(MOCK.skills) do if x.name == name then s = x end end
  if not s then s = { name = name }; MOCK.skills[#MOCK.skills + 1] = s end
  s.rank, s.max = rank, max
  MOCK.event("SKILL_LINES_CHANGED")
  MOCK.event("CHAT_MSG_SKILL", "Your skill in " .. name .. " has increased to " .. rank .. ".")
end
function MOCK.removeSkill(name)
  for i, skill in ipairs(MOCK.skills) do
    if skill.name == name then
      table.remove(MOCK.skills, i)
      MOCK.event("SKILL_LINES_CHANGED")
      return
    end
  end
end
function GetProfessions()
  local primary, secondary = {}, {}
  for i, s in ipairs(MOCK.skills) do
    if SECONDARY[s.name] then secondary[s.name] = i
    else primary[#primary + 1] = i end
  end
  return primary[1], primary[2], nil, secondary.Fishing, secondary.Cooking, secondary["First Aid"]
end
function GetProfessionInfo(i)
  local s = MOCK.skills[i]
  if s then return s.name, 136241, s.rank, s.max, 0, 0, 0, 0 end
end
-- MOCK.skillsCollapsed: the player closed the heading, so the list hides the lines under it.
function GetNumSkillLines() return MOCK.skillsCollapsed and 1 or #MOCK.skills + 1 end
function GetSkillLineInfo(i)
  if i == 1 then return "Professions", true, not MOCK.skillsCollapsed, 0, 0, 0, 0 end
  if MOCK.skillsCollapsed then return end
  local s = MOCK.skills[i - 1]
  if s then return s.name, false, false, s.rank, 0, 0, s.max, true end
end
-- The crafting window's data (classic calls). MOCK.trade is set up by the scenario that builds
-- the window: { line, rank, max, recipes = { { name, type, numAvailable } }, selected, layout }.
function GetTradeSkillLine()
  local t = MOCK.trade
  if t then return t.line, t.rank, t.max end
  return "UNKNOWN", 0, 0
end
function GetNumTradeSkills() return MOCK.trade and #MOCK.trade.recipes or 0 end
function GetTradeSkillInfo(i)
  local r = MOCK.trade and MOCK.trade.recipes[i]
  if r then return r[1], r[2], r[3], false end
end
function SelectTradeSkill(i)
  local t = MOCK.trade
  if not t then return end
  if type(i) ~= "number" then error("SelectTradeSkill: bad index", 2) end
  t.selected = i -- like the classic client: selects (and fills the details), doesn't scroll the list
  if t.layout then t.layout() end
end
function GetTradeSkillSelectionIndex() return MOCK.trade and MOCK.trade.selected or 0 end

-- A trainer window: MOCK.trainer[i] = { name, skillName, skillLevel, rank =, category =, cost = }
-- (category defaults to "available"); MOCK.tradeskillTrainer = a profession trainer; MOCK.money.
MOCK.trainer = {}
function GetNumTrainerServices() return #MOCK.trainer end
function GetTrainerServiceInfo(i)
  local t = MOCK.trainer[i]
  if t then return t[1], t.rank or "", t.category or "available" end
end
function GetTrainerServiceCost(i)
  local t = MOCK.trainer[i]
  if t then return t.cost or 0 end
end
function IsTradeskillTrainer() return MOCK.tradeskillTrainer or false end
function GetMoney() return MOCK.money or 0 end
function GetTrainerServiceSkillReq(i)
  local t = MOCK.trainer[i]
  if t then return t[2], t[3], true end
end

MOCK.knownSpells = {}
function IsPlayerSpell(id) return MOCK.knownSpells[id] or false end

function UnitFactionGroup() return MOCK.faction or "Alliance", MOCK.faction or "Alliance" end
function UnitRace() local r = MOCK.race or "Human"; return r, r end
function GetItemCount(name) return MOCK.bags[name] or 0 end
-- Item cooldowns: MOCK.cooldowns[itemID] = { start, duration } (GetTime seconds).
function GetItemCooldown(id)
  local c = MOCK.cooldowns and MOCK.cooldowns[id]
  if c then return c[1], c[2], 1 end
  return 0, 0, 1
end

-- Bag contents for the disenchanting list and the vendor: MOCK.bagItems = { { name, id, quality, level (required),
-- itemLevel, class = "Armor"|"Weapon"|"Trade Goods", sell (copper each, 0 = no value), count, locked, loaded (false =
-- GetItemInfo not cached yet) } } in bag 0; { empty = true } is an empty slot (a sold item leaves one).
MOCK.bagItems = {}
local function bagID(i) return MOCK.bagItems[i].id or (90000 + i) end
local function bagLink(i) return "|cff1eff00|Hitem:" .. bagID(i) .. "::::::::|h[" .. MOCK.bagItems[i].name .. "]|h|r" end
-- A vendor (MOCK.openMerchant): MOCK.merchant = { items = { { id, name, price, per = 1, stock = -1, maxStack = 20 } },
-- canRepair, repairCost }. Sales land in MOCK.sold ({ id, count }), purchases in MOCK.bought ({ id, n }),
-- a repair in MOCK.repaired; money moves through MOCK.setMoney (PLAYER_MONEY).
MOCK.sold, MOCK.bought = {}, {}
function MOCK.setMoney(copper)
  MOCK.money = copper
  MOCK.event("PLAYER_MONEY")
end
-- MOCK.serverDelay = seconds: money and bought items arrive after a server round trip, like the
-- real client (a sold item leaves the bag at once; its money comes later).
local function fromServer(fn)
  if MOCK.serverDelay then C_Timer.After(MOCK.serverDelay, fn) else fn() end
end
C_Container = {
  GetContainerNumSlots = function(bag) return bag == 0 and #MOCK.bagItems or 0 end,
  GetContainerItemInfo = function(bag, slot)
    local it = bag == 0 and MOCK.bagItems[slot]
    if not it or it.empty then return end
    return { itemID = bagID(slot), hyperlink = bagLink(slot), stackCount = it.count or 1, quality = it.quality,
      hasNoValue = it.sell == 0, isLocked = it.locked or false }
  end,
  UseContainerItem = function(bag, slot)
    local it = bag == 0 and MOCK.bagItems[slot]
    if not it or it.empty or not (MerchantFrame and MerchantFrame:IsShown()) then return end
    table.insert(MOCK.sold, { bagID(slot), it.count or 1 })
    MOCK.bagItems[slot] = { empty = true }
    fromServer(function() MOCK.setMoney((MOCK.money or 0) + (it.sell or 1) * (it.count or 1)) end)
  end,
}
function GetItemInfo(link)
  local name = type(link) == "string" and link:match("%[(.-)%]")
  for _, r in ipairs(MOCK.rewardChoices or {}) do
    if r[1] == name then
      if r[3] == nil then return nil end
      return r[1], link, 2, 20, 15, "Armor", "Mail", 1, "INVTYPE_CHEST", 134400, r[3], 4
    end
  end
  for _, it in ipairs(MOCK.bagItems) do
    if not it.empty and (it.name == name or (it.id and it.id == link)) then
      if it.loaded == false then return nil end
      local classID = ({ Armor = 4, Weapon = 2 })[it.class] or 7
      return it.name, link, it.quality, it.itemLevel or it.level + 5, it.level, it.class, "", 1, "", 134400,
        it.sell or 1, classID
    end
  end
end

local function merchantItem(i) return MOCK.merchant and MOCK.merchant.items and MOCK.merchant.items[i] end
function GetMerchantNumItems() return MOCK.merchant and MOCK.merchant.items and #MOCK.merchant.items or 0 end
function GetMerchantItemID(i) local m = merchantItem(i); return m and m.id end
function GetMerchantItemLink(i)
  local m = merchantItem(i)
  return m and ("|cffffffff|Hitem:" .. m.id .. "::::::::|h[" .. m.name .. "]|h|r")
end
function GetMerchantItemInfo(i)
  local m = merchantItem(i)
  if m then return m.name, 134400, m.price, m.per or 1, m.stock or -1, true, true, m.extended or false end
end
function GetMerchantItemMaxStack(i) local m = merchantItem(i); return m and (m.maxStack or 20) end
-- MOCK.buyFails: the game refuses the purchase (full bags): nothing arrives, no money moves.
function BuyMerchantItem(i, n)
  local m = merchantItem(i)
  if not m or MOCK.buyFails then return end
  local per = m.per or 1
  n = n or per
  if m.stock and m.stock ~= -1 then n = math.min(n, m.stock); m.stock = m.stock - n end
  table.insert(MOCK.bought, { m.id, n })
  fromServer(function()
    MOCK.bags[m.id] = (MOCK.bags[m.id] or 0) + n
    MOCK.setMoney((MOCK.money or 0) - math.ceil(n / per) * m.price)
    if MOCK.serverDelay then MOCK.event("BAG_UPDATE_DELAYED") end
  end)
end
function CanMerchantRepair() return MOCK.merchant and MOCK.merchant.canRepair or false end
function GetRepairAllCost()
  local cost = MOCK.merchant and MOCK.merchant.repairCost or 0
  return cost, cost > 0
end
function RepairAllItems()
  local cost = MOCK.merchant and MOCK.merchant.repairCost or 0
  MOCK.repaired = cost
  MOCK.merchant.repairCost = 0
  fromServer(function() MOCK.setMoney((MOCK.money or 0) - cost) end)
end
function MOCK.openMerchant(m)
  MOCK.merchant = m
  if MerchantFrame then MerchantFrame:Show() end
  MOCK.event("MERCHANT_SHOW")
end
function MOCK.closeMerchant()
  if MerchantFrame then MerchantFrame:Hide() end
  MOCK.event("MERCHANT_CLOSED")
end

-- Forever's controller UI (Blizzard_GamepadSharedUtility / Blizzard_GamepadSmartNavigation):
-- MOCK.gamepadUI = its controller UI is on, MOCK.gamepad = the controller is in use,
-- MOCK.padRefuse = FrameShown errors, MOCK.padNoFocus = the focus never lands on a frame.
MOCK.padHidden, MOCK.padRefreshed = {}, {}
InputUtil = { IsGamepadUIEnabled = function() return MOCK.gamepadUI == true end }
function IsUsingGamepad() return MOCK.gamepad == true end
GamepadMode = { FrameControlsManager = { shown = {} } }
function GamepadMode.FrameControlsManager:FrameShown(f, popup)
  if MOCK.combat then problem("gamepad", "FrameShown in combat") end
  if MOCK.padRefuse then error("refused", 2) end
  if not InputUtil.IsGamepadUIEnabled() then return false end
  for _, x in ipairs(self.shown) do if x == f then return false end end
  table.insert(self.shown, f)
  f._padPopup = popup
  -- were the tooltip-only pieces already out of the focus when the window joined?
  local marked = true
  for _, b in ipairs(MOCK.buttons(f)) do
    if b:IsShown() and b.padSkip and not b._padIgnored then marked = false end
  end
  MOCK.padMarksAtJoin = marked
  SmartNavigation:SelectTopLeftButton()
  return true
end
function GamepadMode.FrameControlsManager:GetActiveFrame() return self.shown[#self.shown] end
function GamepadMode.FrameControlsManager:FrameHidden(f)
  if MOCK.combat then problem("gamepad", "FrameHidden in combat") end
  for i = #self.shown, 1, -1 do if self.shown[i] == f then table.remove(self.shown, i) end end
  MOCK.padHidden[f] = true
end
SmartNavigation = CreateFrame("Frame", "SmartNavigation", UIParent)
SmartNavigation:Hide()
function SmartNavigation:RefreshButtonGroups(p)
  if MOCK.combat then problem("gamepad", "RefreshButtonGroups in combat") end
  table.insert(MOCK.padRefreshed, p)
end
function SmartNavigation:SetScrollFrameForFrame(p, s) p._padScroll = s end
-- The focused piece: picked when a window joins, or by SelectTopLeftButton (the first shown,
-- not ignored Button of the active window); a redraw can leave it on a hidden or reused widget.
function SmartNavigation:SelectTopLeftButton()
  local shown = GamepadMode and GamepadMode.FrameControlsManager.shown or {}
  local panel = shown[#shown]
  local function first(f)
    for _, k in ipairs(f._children or {}) do
      if k:IsShown() and not k._padIgnored then
        if k._type == "Button" or k._type == "CheckButton" then return k end
        local found = first(k)
        if found then return found end
      end
    end
  end
  self._current = panel and first(panel) or nil
end
function SmartNavigation:GetCurrentButton()
  if MOCK.padNoFocus then return nil end
  return self._current
end
-- How far the first scroll frame inside f is scrolled.
function MOCK.scrollOf(f)
  for _, k in ipairs(f._children or {}) do
    if k._type == "ScrollFrame" then return k._scroll or 0 end
    local v = MOCK.scrollOf(k)
    if v then return v end
  end
end
function SmartNavigation_MarkFrameIgnored(f) f._padIgnored = true end
function SmartNavigation_ClearIgnoreStatus(f) f._padIgnored = nil end

-- Forever's addon compartment (the addons button under the clock): RegisterAddon({ text, icon,
-- func(data, menuInputData), funcOnEnter(button), funcOnLeave(button) }).
AddonCompartmentFrame = CreateFrame("Frame", "AddonCompartmentFrame", UIParent)
AddonCompartmentFrame.registeredAddons = {}
function AddonCompartmentFrame:RegisterAddon(data)
  if type(data) ~= "table" or type(data.text) ~= "string" then error("RegisterAddon: needs a table with text", 2) end
  ascii(data.text, "AddonCompartmentFrame:RegisterAddon")
  table.insert(self.registeredAddons, data)
end

function hooksecurefunc(a, b, c)
  local tbl, name, fn = _G, a, b
  if type(a) == "table" then tbl, name, fn = a, b, c end
  local old = tbl[name]
  if type(old) ~= "function" then error("hooksecurefunc: " .. tostring(name) .. " is not a function", 2) end
  tbl[name] = function(...)
    local r = { old(...) }
    fn(...)
    return unpack(r)
  end
end

function EnumerateFrames(f)
  MOCK.enumerated = (MOCK.enumerated or 0) + 1
  if not f then return MOCK.frames[1] end
  return MOCK.frames[(f._idx or #MOCK.frames) + 1]
end

C_Timer = {}
local function addTimer(sec, fn, ticker, iterations)
  if type(fn) ~= "function" then error("C_Timer: callback must be a function", 3) end
  local t = { at = MOCK.time + sec, fn = fn, every = ticker and sec or nil, left = iterations }
  t.Cancel = function(self) self.cancelled = true end
  t.IsCancelled = function(self) return self.cancelled end
  MOCK.timers[#MOCK.timers + 1] = t
  return t
end
function C_Timer.After(sec, fn) addTimer(sec, fn) end
function C_Timer.NewTimer(sec, fn) return addTimer(sec, fn) end
function C_Timer.NewTicker(sec, fn, n) return addTimer(sec, fn, true, n) end

-- Macros (Classic limits: 120 account, 18 character)
MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18
local function checkMacro(name, body)
  if type(name) ~= "string" or #name > 16 then problem("macro", "name too long: " .. tostring(name)) end
  if type(body) ~= "string" or #body > 255 then problem("macro", "body over 255 chars in " .. tostring(name) .. " (" .. #tostring(body) .. ")") end
  ascii(body, "macro body " .. tostring(name))
end
local function countMacros()
  local g, c = 0, 0
  for _, m in ipairs(MOCK.macros) do if m.perChar then c = c + 1 else g = g + 1 end end
  return g, c
end
GetNumMacros = countMacros
function GetMacroIndexByName(name)
  for i, m in ipairs(MOCK.macros) do if m.name == name then return i end end
  return 0
end
function GetMacroInfo(i)
  local m = MOCK.macros[i]
  if m then return m.name, m.icon, m.body end
end
function CreateMacro(name, icon, body, perChar)
  if MOCK.combat then error("CreateMacro: protected in combat", 2) end
  checkMacro(name, body)
  local _, c = countMacros()
  if perChar and c >= (MOCK.charMacroSlots or MAX_CHARACTER_MACROS) then error("You have too many macros", 2) end
  MOCK.macros[#MOCK.macros + 1] = { name = name, icon = icon, body = body, perChar = perChar }
  return #MOCK.macros
end
function EditMacro(i, name, icon, body)
  if MOCK.combat then error("EditMacro: protected in combat", 2) end
  local m = MOCK.macros[i]
  if not m then error("EditMacro: bad index", 2) end
  checkMacro(name or m.name, body or m.body)
  m.name, m.icon, m.body = name or m.name, icon or m.icon, body or m.body
  return i
end

----------------------------------------------------------------------------
-- Driving the client
----------------------------------------------------------------------------

function MOCK.event(name, ...)
  local set, units = MOCK.events[name], MOCK.unitEvents[name]
  if not set and not units then return 0 end
  local list = {}
  for f in pairs(set or {}) do list[#list + 1] = f end
  local unit = ...
  for f, names in pairs(units or {}) do
    for _, u in ipairs(names) do if u == unit then list[#list + 1] = f; break end end
  end
  for _, f in ipairs(list) do fire(f, "OnEvent", name, ...) end
  return #list
end

-- Advance time: timers, OnUpdate scripts and animations, in small steps.
function MOCK.advance(sec, step)
  step = step or 0.05
  local target = MOCK.time + sec
  while MOCK.time < target - 1e-9 do
    local dt = math.min(step, target - MOCK.time)
    MOCK.time = MOCK.time + dt
    -- timers
    local due = {}
    for _, t in ipairs(MOCK.timers) do
      if not t.cancelled and not t.done and t.at <= MOCK.time + 1e-9 then due[#due + 1] = t end
    end
    for _, t in ipairs(due) do
      if t.every then
        t.at = t.at + t.every
        if t.left then t.left = t.left - 1; if t.left <= 0 then t.done = true end end
        t.fn(t)
      else
        t.done = true
        t.fn()
      end
    end
    local keep = {}
    for _, t in ipairs(MOCK.timers) do if not t.done and not t.cancelled then keep[#keep + 1] = t end end
    MOCK.timers = keep
    -- OnUpdate
    local ups = {}
    for f in pairs(MOCK.updaters) do ups[#ups + 1] = f end
    for _, f in ipairs(ups) do
      if f:IsVisible() and f._scripts.OnUpdate then f._scripts.OnUpdate(f, dt) end
    end
    -- animations
    local playing = {}
    for g in pairs(MOCK.anims) do playing[#playing + 1] = g end
    for _, g in ipairs(playing) do
      if g._playing then
        g._elapsed = g._elapsed + dt
        if not g._loop or g._loop == "NONE" then
          if g._elapsed >= (g._total or 0) then
            g._playing = false
            MOCK.anims[g] = nil
            if g._scripts.OnFinished then g._scripts.OnFinished(g) end
          end
        end
      end
    end
  end
end

-- Every shown button under a frame, in a stable order (depth first).
function MOCK.buttons(root)
  local out = {}
  local function walk(f)
    for _, c in ipairs(f._children) do
      if c._shown then
        if c._type == "Button" or c._type == "CheckButton" then out[#out + 1] = c end
        walk(c)
      end
    end
  end
  walk(root)
  return out
end

-- Visible regions still wearing a font, gradient or rotation from an earlier (pooled) use.
function MOCK.staleUnder(root, where)
  local n = 0
  local function walk(f)
    for _, r in ipairs(f._regions) do
      if r._shown then
        local why = (r._fontStale and "font") or (r._gradStale and "gradient") or (r._rotStale and "rotation")
        if why then
          n = n + 1
          problem("stale " .. why, (where or "") .. ": " .. tostring(r._text or r._type))
        end
      end
    end
    for _, c in ipairs(f._children) do if c._shown then walk(c) end end
  end
  walk(root)
  return n
end

-- All text currently shown under a frame, joined (for assertions).
function MOCK.textUnder(root)
  local out = {}
  local function walk(f)
    for _, r in ipairs(f._regions) do
      if r._shown and r._text then out[#out + 1] = r._text end
    end
    for _, c in ipairs(f._children) do if c._shown then walk(c) end end
  end
  walk(root)
  return table.concat(out, "\n")
end

-- Simulate a drag on a frame by (dx, dy).
function MOCK.drag(f, dx, dy)
  fire(f, "OnDragStart", "LeftButton")
  local p = f._points[1]
  if p and f._moving then p[4], p[5] = p[4] + dx, p[5] + dy end
  fire(f, "OnDragStop")
end

-- Remove the APIs a careful addon must not rely on.
local OPTIONAL = { "C_Timer", "C_Spell", "GetSpellInfo", "BackdropTemplateMixin", "CLASS_ICON_TCOORDS", "C_Texture", "SetPortraitToTexture",
  "C_ClassTalents", "C_Traits", "GetBuildInfo", "C_AddOns", "GetFileIDFromPath", "EnumerateFrames", "hooksecurefunc",
  "CreateColor", "GetMinimapShape", "PlaySound", "GetMacroInfo", "GetNumMacros", "C_Minimap", "UnitIsDeadOrGhost",
  "GetProfessions", "GetProfessionInfo", "GetItemCount", "C_Container", "GetItemInfo", "GetQuestLogSpecialItemInfo", "GetItemIcon",
  "GetTradeSkillLine", "GetNumTradeSkills", "GetTradeSkillInfo", "SelectTradeSkill", "GetTradeSkillSelectionIndex",
  "GetNumTrainerServices", "GetTrainerServiceInfo", "GetTrainerServiceSkillReq", "IsPlayerSpell", "AddonCompartmentFrame",
  "InputUtil", "IsUsingGamepad", "GamepadMode", "SmartNavigation", "SmartNavigation_MarkFrameIgnored",
  "SmartNavigation_ClearIgnoreStatus", "UnitIsGhost", "C_DeathInfo", "TakeTaxiNode", "ConfirmBinder", "StaticPopup_Hide",
  "UnitXP", "UnitXPMax", "GetXPExhaustion", "GetQuestLogRewardXP", "GetQuestItemInfo", "GetQuestItemLink",
  "GetTrainerServiceCost", "IsTradeskillTrainer", "GetMoney", "C_SuperTrack", "GetItemCooldown", "OpenWorldMap",
  "IsInGroup", "IsInRaid", "C_ChatInfo", "SendChatMessage", "QuestLogPushQuest", "GetUnitSpeed", "issecretvalue",
  "debugstack", "GetMerchantNumItems", "GetMerchantItemID", "GetMerchantItemLink", "GetMerchantItemInfo",
  "GetMerchantItemMaxStack", "BuyMerchantItem", "CanMerchantRepair", "GetRepairAllCost", "RepairAllItems", "MerchantFrame", "WorldMapFrame" }

function MOCK.setup(opts)
  MOCK.class = opts.class
  MOCK.minimal = opts.minimal
  if opts.minimal then
    C_QuestLog, C_Map, GetPlayerFacing, GetQuestID, GetNumQuestChoices, AcceptQuest, GetQuestReward = nil, nil, nil, nil, nil, nil, nil
    UnitOnTaxi, NumTaxiNodes, TaxiNodeName, TaxiNodeGetType = nil, nil, nil, nil
    for _, n in ipairs(OPTIONAL) do _G[n] = nil end
    for _, e in ipairs(MOCK.optionalEvents) do MOCK.knownEvents[e] = nil end
    Texture.SetGradient = nil
    Texture.SetRotation = nil
    Frame.EnableGamePadButton = nil
    Frame.SetPropagateGamePadInput = nil
    Frame.EnableGamePadStick = nil
    Frame.RegisterUnitEvent = nil
    Frame.SetMouseClickEnabled = nil
    Frame.SetMouseMotionEnabled = nil
    -- an old-style client: no Blizzard button/check templates, no backdrops at all
    Frame.SetBackdrop = nil
    for _, t in ipairs({ "UIPanelButtonTemplate", "UICheckButtonTemplate", "BackdropTemplate" }) do
      MOCK.disabledTemplates[t] = true
    end
  end
  if opts.noArt then
    -- the client has the APIs but none of the Blizzard art files
    for _, p in ipairs(opts.noArt) do MOCK.missingTextures[p:lower()] = true end
    for _, m in ipairs({ "SetSmoothing", "SetScaleFrom", "SetScaleTo" }) do Anim[m] = nil end
    AnimGroup.SetToFinalAlpha = nil
  end
end

-- Globals the addon is allowed to create (everything else is a leaked local).
local ALLOWED_GLOBALS = {
  LevelingCodexDB = true, LevelingCodexCharDB = true, LevelingCodexData = true, SLASH_LEVELINGCODEX1 = true,
  BINDING_HEADER_LEVELINGCODEX = true, BINDING_NAME_LEVELINGCODEX_TOGGLE = true, ["BINDING_NAME_CLICK LevelingCodexQuestItem:LeftButton"] = true,
  ["BINDING_NAME_CLICK LevelingCodexQuestTarget:LeftButton"] = true,
  LevelingCodexQuests = true, LevelingCodexQuestViewer = true, LevelingCodexQuestArrow = true,
  -- made by the test scenarios, not the addon
  PlayerSpellsFrame = true, ClassTalentFrame = true, ToggleTalentFrame_Mock = true,
  ForeverTalentsUI = true, PlayerSpellsFrame_Toggle = true,
  EventToastManagerFrame = true, ForeverLevelUpBanner = true,
  TradeSkillFrame = true, C_TradeSkillUI = true, TradeSkillListScrollFrame = true, FauxScrollFrame_SetOffset = true,
  TradeSkillFrame_Update = true, TRADE_SKILLS_DISPLAYED = true,
  GetNumQuestLogEntries = true, GetQuestLogTitle = true, GetNumQuestLeaderBoards = true,
  GetQuestLogLeaderBoard = true, IsQuestFlaggedCompleted = true,
  Questie = true, Questie_BaseFrame = true, LibQuestieDB = true,
}
for i = 1, 8 do ALLOWED_GLOBALS["TradeSkillSkill" .. i] = true end
for i = 1, 4 do ALLOWED_GLOBALS["QuestInfoRewardsFrameQuestInfoItem" .. i] = true end
ALLOWED_GLOBALS.ClassTrainerFrame = true
ALLOWED_GLOBALS.TaxiFrame = true
for i = 1, 4 do ALLOWED_GLOBALS["TaxiButton" .. i] = true end
function MOCK.snapshotGlobals()
  MOCK.globals0 = {}
  for k in pairs(_G) do MOCK.globals0[k] = true end
end
function MOCK.checkGlobals()
  for k in pairs(_G) do
    if not MOCK.globals0[k] and not ALLOWED_GLOBALS[k] and not tostring(k):find("^LevelingCodex") then
      problem("global", "addon created global '" .. tostring(k) .. "'")
    end
  end
end

-- Load one addon file the way the client does: (addonName, addonTable) as varargs.
MOCK.ns = {}
function MOCK.loadFile(path, chunkName)
  local f, err = loadfile(path)
  if not f then error("compile error: " .. tostring(err), 0) end
  return f("LevelingCodex", MOCK.ns)
end

-- Run fn and return a traceback string on error (nil on success).
function MOCK.try(fn, ...)
  local args = { n = select("#", ...), ... }
  local ok, err = xpcall(function() return fn(unpack(args, 1, args.n)) end, debug.traceback)
  if not ok then return tostring(err) end
end
