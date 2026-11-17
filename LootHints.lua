-- Read-only tooltip and reward annotations. No selection, rolling, purchases, or equipment writes.
local _, ns = ...
local L=ns.loot
local call=L.call
local SCORE_ICON="|TInterface\\Icons\\inv_chest_plate04:12:12:0:0|t "
local SCORE_COLORS={
  upgrade={0.67,0.90,0.50}, downgrade={1.00,0.62,0.55},
  cannotEquip={1.00,0.62,0.55}, sidegrade={0.88,0.86,0.70},
}
function L.annotate(tip,ref)
  if ns.db().noLootHints or not tip or not ref then return end
  local item=L.item(ref);if not item then return end
  if item.classID and item.classID~=2 and item.classID~=4 then return end
  -- Advice belongs to this native tooltip build, not the loot cache version. Async
  -- data events must not duplicate shared content; the client's clear/hide hooks reset it.
  local key=item.key
  if tip.codexLootKey==key then return end
  local r=L.compare(item);tip.codexLootKey=key;tip.codexLootRef=ref
  local score="Score unavailable"
  if r.confidence=="complete" then
    score=r.percent and string.format("%+.1f%% gear score",r.percent) or string.format("%.1f gear score",r.score)
  elseif r.verdict=="cannotEquip" then score="Cannot equip"
  elseif r.verdict=="loading" then score="Loading score" end
  local color=SCORE_COLORS[r.verdict] or {0.74,0.80,0.84}
  tip:AddLine(SCORE_ICON.."Codex: "..score,color[1],color[2],color[3])
end

function L.showItemTooltip(owner,ref,anchor)
  local tip=GameTooltip
  local link=L.itemKey(ref)
  if tip and link and type(tip.SetHyperlink)=="function" then
    tip:SetOwner(owner,anchor or "ANCHOR_RIGHT")
    if pcall(tip.SetHyperlink,tip,link) then tip:Show();return end
  end
  ns.art.showTip(owner)
end

function L.hideItemTooltip(owner)
  if GameTooltip and GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end
function L.rewardAdvice()
  local out={state="complete",rows={}}
  local pending,best,bestDelta=false,nil,-math.huge
  local count=tonumber(call(GetNumQuestChoices)) or 0
  for i=1,count do
    local link=call(GetQuestItemLink,"choice",i)
    local it=link and L.item(link)
    if not it or it.state=="loading" or not it.classID then pending=true
    elseif it.classID==2 or it.classID==4 then
      local r=L.compare(it);out.rows[#out.rows+1]={index=i,item=it,result=r}
      if r.verdict=="needsReview" or r.verdict=="loading" then pending=true
      elseif r.verdict=="upgrade" and (r.delta or 0)>bestDelta then best=i;bestDelta=r.delta or 0 end
    end
  end
  if pending then out.state="pending" else out.bestChoice=best end
  return out
end
local mark,run= nil,0
local function rewardButton(i)
  local list=type(QuestInfoRewardsFrame)=="table" and QuestInfoRewardsFrame.RewardButtons
  for _,b in ipairs(type(list)=="table" and list or {}) do
    if b.type=="choice" and call(b.GetID,b)==i then return b end
  end
  return _G["QuestInfoRewardsFrameQuestInfoItem"..i] or _G["QuestRewardItem"..i]
end
local function refreshRewards(token,attempt)
  if token~=run then return end
  if mark then mark:Hide() end
  if ns.db().noLootRewards then return end
  local advice=L.rewardAdvice()
  L.lastRewardAdvice=advice
  if advice.state=="pending" then
    if attempt<4 then ns.after(0.5,function() refreshRewards(token,attempt+1) end) end
    return
  end
  local index=advice.bestChoice;local b=index and rewardButton(index)
  if not b then return end
  if not mark then
    mark=CreateFrame("Frame","LevelingCodexLootRewardMark",b)
    mark:SetSize(20,20);mark:EnableMouse(false)
    mark.label=mark:CreateFontString(nil,"OVERLAY","GameFontNormal")
    mark.label:SetAllPoints();mark.label:SetText("+")
  end
  mark:SetParent(b);mark:ClearAllPoints();mark:SetPoint("TOPRIGHT",b,"TOPRIGHT",4,4)
  mark:SetFrameLevel((call(b.GetFrameLevel,b) or 1)+6);mark:Show()
end
local hooked={}
local function itemTip(tip,ref)
  local _,link=call(tip.GetItem,tip);ref=link or ref
  if ref then L.annotate(tip,ref) end
end
local function unitTip(tip)
  if ns.db().noLootHints then return end
  local _,unit=call(tip.GetUnit,tip)
  local guid=unit and call(UnitGUID,unit)
  local id=type(guid)=="string" and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
  if not id then return end
  local data=ns.lootData;local ids=data and data.byCreature[id]
  local seen,n={},0
  for _,sid in ipairs(ids or {}) do
    local s=data.sources[sid];local it=s and data.items[s.item]
    local drops=s and (s.type=="creature" or s.type=="rare" or s.type=="boss" or s.type=="dungeonTrash" or s.type=="raidTrash")
    local prefix=s and s.type=="vendor" and "Codex vendor: " or drops and "Codex drop: "
    if prefix and it and not seen[it.id] then
      local r=L.compare(it)
      if r.verdict=="upgrade" or r.verdict=="needsReview" then
        tip:AddLine(ns.plain(prefix..it.name.." - "..L.labels[r.verdict]),1,0.82,0,true)
        seen[it.id]=true;n=n+1;if n>=3 then break end
      end
    end
  end
end
local function hookTip(tip)
  if not tip or hooked[tip] then return end
  hooked[tip]=true
  local function clear(self) self.codexLootKey=nil;self.codexLootRef=nil end
  if type(tip.HookScript)=="function" then
    pcall(tip.HookScript,tip,"OnTooltipSetItem",function(self) itemTip(self) end)
    pcall(tip.HookScript,tip,"OnTooltipSetUnit",unitTip)
    pcall(tip.HookScript,tip,"OnTooltipCleared",clear)
    pcall(tip.HookScript,tip,"OnHide",clear)
  end
  if type(hooksecurefunc)=="function" then
    for _,method in ipairs({"SetBagItem","SetInventoryItem","SetHyperlink","SetLootItem","SetLootRollItem","SetQuestItem",
      "SetQuestLogItem","SetMerchantItem","SetTradeSkillItem","SetCraftItem"}) do
      if type(tip[method])=="function" then
        pcall(hooksecurefunc,tip,method,function(self)
          itemTip(self)
        end)
      end
    end
  end
end
function L.refreshHints()
  hookTip(GameTooltip);hookTip(ItemRefTooltip)
end
if type(CreateFrame)=="function" then
  local f=CreateFrame("Frame")
  for _,ev in ipairs({"PLAYER_LOGIN","ADDON_LOADED","QUEST_COMPLETE","QUEST_FINISHED","QUEST_DETAIL","QUEST_PROGRESS"}) do pcall(f.RegisterEvent,f,ev) end
  f:SetScript("OnEvent",function(_,event)
    L.refreshHints()
    if event:find("^QUEST_") then
      run=run+1;if mark then mark:Hide() end
      if event=="QUEST_COMPLETE" then refreshRewards(run,1) end
    end
  end)
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  pcall(TooltipDataProcessor.AddTooltipPostCall,Enum.TooltipDataType.Item,function(tip,data) itemTip(tip,data and data.id) end)
end
-- The client owns tooltip visibility and rebuilding. Loot refreshes only invalidate
-- comparison data; never hide, clear or rebuild a shared tooltip from those callbacks.
