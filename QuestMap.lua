-- QuestMap.lua: the step icons (Blizzard's own gossip and cursor art, by step type) that the arrow,
-- the minimap, the world map and the step window share.
local _, ns = ...
local Q = ns.quests

local M = {}
ns.questMap = M

local ICONS = {
  accept = "Interface\\GossipFrame\\AvailableQuestIcon",
  turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
  kill = "Interface\\Cursor\\Attack",
  loot = "Interface\\Cursor\\LootAll",
  fly = "Interface\\GossipFrame\\TaxiGossipIcon",
  getfp = "Interface\\GossipFrame\\TaxiGossipIcon",
  sethearth = "Interface\\GossipFrame\\BinderGossipIcon",
  hearth = "Interface\\GossipFrame\\BinderGossipIcon",
  buy = "Interface\\GossipFrame\\VendorGossipIcon",
  train = "Interface\\GossipFrame\\TrainerGossipIcon",
  boss = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  dungeon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  plan = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
  spot = "Interface\\TaxiFrame\\UI-Taxi-Icon-Highlight",
}
M.ICONS = ICONS

-- A complete step kills when its objectives say so ("slain", "killed") or the quest has creatures to
-- target and no item objective; otherwise it loots.
local function kills(step)
  local entry = step.quest and Q.log(step.quest)
  local texts = {}
  for _, obj in ipairs(entry and entry.objectives or {}) do
    if type(obj.text) == "string" then texts[#texts + 1] = obj.text end
  end
  for _, text in ipairs(type(step.objectives) == "table" and step.objectives or {}) do
    if type(text) == "string" then texts[#texts + 1] = text end
  end
  for _, text in ipairs(texts) do
    local lower = text:lower()
    if lower:find("slain", 1, true) or lower:find("killed", 1, true) then return true end
  end
  for _, obj in ipairs(entry and entry.objectives or {}) do
    if obj.type == "item" then return false end
  end
  local mobs = step.mobs or (ns.questMobs and step.quest and ns.questMobs[step.quest])
  return type(mobs) == "table" and #mobs > 0
end

-- The icon file for a step, or nil (the caller draws a gold dot) when the client lacks the file.
function ns.questIcon(step)
  if type(step) ~= "table" then return end
  local key = step.type
  if key == "complete" then key = kills(step) and "kill" or "loot" end
  local path = ICONS[key] or ICONS.spot
  if ns.art.hasFile(path) then return path end
end
