local _, ns = ...
local L=ns.loot
local frame,rows
local initialized,seenBags=false,{}
local function make()
  frame=ns.art.frame("Frame","LevelingCodexLootTracker",UIParent)
  frame:SetSize(290,260);frame:SetPoint("RIGHT",UIParent,"RIGHT",-30,0)
  frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing();local p,_,r,x,y=self:GetPoint(1);ns.db().lootTrackerPos={p,r,x,y}
  end)
  local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
  title:SetPoint("TOPLEFT",12,-12);title:SetText("Loot targets")
  local clear=ns.art.button(frame,65,20);clear:SetLabel("Clear map");clear.codexLabel="Clear loot map"
  clear:SetPoint("TOPRIGHT",-10,-10);clear:SetScript("OnClick",function() if L.clearMapTarget then L.clearMapTarget() end end)
  rows={}
  for i=1,6 do
    local open=ns.art.button(frame,180,24);open:SetPoint("TOPLEFT",10,-40-(i-1)*32)
    local map=ns.art.button(frame,36,24);map:SetPoint("LEFT",open,"RIGHT",3,0);map:SetLabel("Map")
    local remove=ns.art.button(frame,36,24);remove:SetPoint("LEFT",map,"RIGHT",3,0);remove:SetLabel("X")
    rows[i]={open=open,map=map,remove=remove}
  end
  local more=ns.art.button(frame,265,22);more:SetLabel("All loot targets");more.codexLabel="All loot targets"
  more:SetPoint("BOTTOM",0,10);more:SetScript("OnClick",function() L.open("Tracked") end)
  local p=ns.db().lootTrackerPos
  if type(p)=="table" and type(p[1])=="string" and type(p[2])=="string" and type(p[3])=="number" and type(p[4])=="number" then
    frame:ClearAllPoints();frame:SetPoint(p[1],UIParent,p[2],p[3],p[4])
  end
  if ns.gamepad then ns.gamepad.attach(frame,{popup=true,focusables=function()
    local out={{frame=clear,x=240,y=10,fixed=true},{frame=more,x=140,y=245,fixed=true}}
    for i,row in ipairs(rows) do for j,b in ipairs({row.open,row.map,row.remove}) do
      if b:IsShown() then out[#out+1]={frame=b,x=j==1 and 90 or 175+j*35,y=40+(i-1)*32} end
    end end
    return out
  end}) end
end
function L.hideTracker() if frame then frame:Hide() end end
function L.refreshTracker()
  if L.call(InCombatLockdown) then return end
  local list=L.targets("tracked")
  if ns.db().noLootTracker or #list==0 then L.hideTracker();return end
  if not frame then make() end
  ns.art.backdrop(frame,"dialog",ns.C.panel,ns.C.edge)
  for i,row in ipairs(rows) do
    local t=list[i]
    if t then
      row.open:SetLabel(ns.plain(t.name));row.open.codexLabel="Loot target "..ns.plain(t.name)
      row.open:SetScript("OnClick",function() L.open("Compare",t.ref) end);row.open:Show()
      row.map.codexLabel="Map loot target "..ns.plain(t.name)
      row.map:SetScript("OnClick",function() local ok,why=L.showSourceOnMap(t.sourceID);if why then ns.say(why) end end)
      local source=t.sourceID and ns.lootData.sources[t.sourceID]
      if source and source.map then row.map:Show() else row.map:Hide() end
      row.remove.codexLabel="Untrack loot target "..ns.plain(t.name)
      row.remove:SetScript("OnClick",function() L.untrack(t.key) end);row.remove:Show()
    else row.open:Hide();row.map:Hide();row.remove:Hide() end
  end
  frame:Show();if ns.gamepad then ns.gamepad.refresh(frame) end
end
local function notifications()
  local changes=L.targetChanges()
  if ns.db().lootNotifications then
    for _,c in ipairs(changes) do ns.say("Loot target obtained: "..ns.plain(c.name)) end
  end
  local s=L.snapshot()
  if not s.bagsKnown or not s.equipmentKnown then return end
  for key,n in pairs(s.bagLinks) do
    if initialized and not seenBags[key] and n>0 and ns.db().lootNotifications then
      local r=L.compare(key)
      if r.verdict=="upgrade" then ns.say("Bag upgrade: "..ns.plain(r.candidate.name)..". Open /codex loot to compare.") end
    end
  end
  seenBags={};for key,n in pairs(s.bagLinks) do if n>0 then seenBags[key]=true end end
  initialized=true
end
L.subscribe(function() L.refreshTracker();notifications() end)
