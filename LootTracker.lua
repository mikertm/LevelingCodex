local _, ns = ...
local L=ns.loot
local frame,rows,clear,more,count
local initialized,seenBags=false,{}
local ROWS,WIDTH,ROW_HEIGHT=5,310,53
local PANEL={0.052,0.083,0.108,0.98}
local STRIPE={0.104,0.165,0.198,1}
local INK={0.92,0.94,0.91}
local DIM={0.66,0.75,0.79}
local GOLD={0.92,0.83,0.64}
local EDGE={0.23,0.46,0.52,1}

local function fill(parent,x,y,w,h,color)
  local texture=parent:CreateTexture(nil,"BACKGROUND")
  texture:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
  texture:SetSize(w,h)
  texture:SetColorTexture(ns.rgba(color))
  return texture
end
local function label(parent,x,y,w,font,color)
  local text=parent:CreateFontString(nil,"OVERLAY",font)
  text:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
  text:SetWidth(w)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(false)
  text:SetTextColor(ns.rgba(color))
  return text
end
local function highlight(button)
  local glow=button:CreateTexture(nil,"HIGHLIGHT")
  glow:SetAllPoints(button)
  glow:SetColorTexture(0.40,0.76,0.86,0.14)
end
local function button(parent,x,y,w,h,caption,tip)
  local b=CreateFrame("Button",nil,parent)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
  b:SetSize(w,h)
  b:EnableMouse(true)
  b:RegisterForClicks("LeftButtonUp")
  fill(b,0,0,w,h,{0.17,0.29,0.34,1})
  local text=label(b,0,4,w,"GameFontHighlightSmall",INK)
  text:SetJustifyH("CENTER")
  text:SetText(caption)
  highlight(b)
  b.tipTitle,b.tipText=caption,tip
  b:SetScript("OnEnter",ns.art.showTip)
  b:SetScript("OnLeave",ns.art.hideTip)
  return b
end

local function make()
  frame=CreateFrame("Frame","LevelingCodexLootTracker",UIParent)
  frame:SetSize(WIDTH,126)
  frame:SetPoint("RIGHT",UIParent,"RIGHT",-30,0)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    local p,_,r,x,y=self:GetPoint(1)
    ns.db().lootTrackerPos={p,r,x,y}
  end)
  frame:Hide()
  local bg=frame:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(frame);bg:SetColorTexture(ns.rgba(PANEL))
  fill(frame,0,0,WIDTH,2,EDGE)
  local bottom=frame:CreateTexture(nil,"BORDER")
  bottom:SetPoint("BOTTOMLEFT");bottom:SetPoint("BOTTOMRIGHT");bottom:SetHeight(1)
  bottom:SetColorTexture(ns.rgba(EDGE))
  fill(frame,10,39,WIDTH-20,1,EDGE)
  local title=label(frame,12,8,180,"GameFontHighlight",GOLD)
  title:SetText("Loot targets")
  count=label(frame,12,24,180,"GameFontHighlightSmall",DIM)
  clear=button(frame,WIDTH-94,10,82,21,"Clear pin","Clear your current loot map pin.")
  clear.codexLabel="Clear loot map"
  clear:SetScript("OnClick",L.clearMapTarget)

  rows={}
  for i=1,ROWS do
    local y=45+(i-1)*ROW_HEIGHT
    local row=CreateFrame("Frame",nil,frame)
    row:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-y)
    row:SetSize(WIDTH-20,ROW_HEIGHT-5)
    fill(row,0,0,WIDTH-20,ROW_HEIGHT-5,STRIPE)
    local icon=row:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("TOPLEFT",8,-9);icon:SetSize(30,30)
    local open=CreateFrame("Button",nil,row)
    open:SetPoint("TOPLEFT",0,0);open:SetSize(207,ROW_HEIGHT-5)
    open:EnableMouse(true);open:RegisterForClicks("LeftButtonUp")
    highlight(open)
    open:SetScript("OnEnter",function(self) L.showItemTooltip(self,self.itemRef,"ANCHOR_LEFT") end)
    open:SetScript("OnLeave",function(self) L.hideItemTooltip(self) end)
    local name=label(open,46,8,155,"GameFontHighlightSmall",INK)
    local source=label(open,46,26,155,"GameFontHighlightSmall",DIM)
    local map=button(row,211,14,39,21,"Map","Open this target's source location.")
    local remove=button(row,256,14,25,21,"X","Remove this target from your list.")
    rows[i]={frame=row,open=open,map=map,remove=remove,icon=icon,name=name,source=source,y=y}
  end
  more=button(frame,10,111,WIDTH-20,20,"All loot targets","Open the full list of saved loot targets.")
  more.codexLabel="All loot targets"
  more:SetScript("OnClick",function() L.open("Tracked") end)
  local p=ns.db().lootTrackerPos
  if type(p)=="table" and type(p[1])=="string" and type(p[2])=="string" and type(p[3])=="number" and type(p[4])=="number" then
    frame:ClearAllPoints();frame:SetPoint(p[1],UIParent,p[2],p[3],p[4])
  end
  if ns.gamepad then
    ns.gamepad.attach(frame,{popup=true,focusables=function()
      local out={{frame=clear,x=WIDTH-50,y=20},{frame=more,x=WIDTH/2,y=frame:GetHeight()-16}}
      for _,row in ipairs(rows) do
        if row.frame:IsShown() then
          out[#out+1]={frame=row.open,x=112,y=row.y+24}
          out[#out+1]={frame=row.map,x=240,y=row.y+24}
          out[#out+1]={frame=row.remove,x=280,y=row.y+24}
        end
      end
      return out
    end})
  end
end

function L.hideTracker()
  if frame then frame:Hide() end
end
function L.refreshTracker()
  if L.call(InCombatLockdown) then return end
  local list=L.targets("tracked")
  if ns.db().noLootTracker or #list==0 then L.hideTracker();return end
  if not frame then make() end
  local visible=math.min(#list,ROWS)
  frame:SetHeight(76+visible*ROW_HEIGHT)
  more:ClearAllPoints()
  more:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",10,8)
  count:SetText(#list>visible and (visible.." of "..#list.." active targets") or (#list==1 and "1 active target" or (#list.." active targets")))
  clear:SetShown(L.mapTarget()~=nil)
  for i,row in ipairs(rows) do
    local target=list[i]
    row.frame:SetShown(target~=nil)
    if target then
      local it=L.item(target.ref)
      ns.setIcon(row.icon,it and it.icon)
      local source=target.sourceID and ns.lootData and ns.lootData.sources[target.sourceID]
      local route=source and (source.dungeon or source.zone or source.name or L.sourceNames[source.type])
      local name=ns.plain(it and it.name or target.name)
      local where=ns.plain(route or "Choose a source")
      row.name:SetText(name)
      row.source:SetText(where)
      row.open.tipTitle=name
      row.open.tipText=where.."\nOpen item details."
      row.open.codexLabel="Loot target "..name
      row.open.itemRef=target.ref
      row.open:SetScript("OnClick",function() L.open("Compare",target.ref,source and source.id) end)
      row.map.codexLabel="Map loot target "..name
      row.map:SetShown(source and source.map and type(source.x)=="number" and type(source.y)=="number" or false)
      row.map:SetScript("OnClick",function()
        local _,why=L.showSourceOnMap(target.sourceID)
        if why then ns.say(why) end
      end)
      row.remove.codexLabel="Untrack loot target "..name
      row.remove:SetScript("OnClick",function() L.untrack(target.key);L.refreshTracker() end)
    end
  end
  frame:Show()
  if ns.gamepad then ns.gamepad.refresh(frame) end
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
