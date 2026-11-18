local _, ns = ...
local L,A,C=ns.loot,ns.art,ns.C
local frame,rows,clear,more,count
local background,headerArt,header,theme
local initialized,seenBags=false,{}
local ROWS,WIDTH,ROW_HEIGHT=5,344,64
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
  frame=A.frame("Frame","LevelingCodexLootTracker",UIParent)
  frame:SetSize(WIDTH,126)
  frame:SetFrameStrata("MEDIUM")
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
  background=frame:CreateTexture(nil,"BACKGROUND")
  background:SetAllPoints(frame)
  headerArt,header=A.header(frame,"Loot targets",244)
  headerArt:SetSize(244,64)
  headerArt:ClearAllPoints();headerArt:SetPoint("TOP",0,9)
  header:ClearAllPoints();header:SetPoint("TOP",0,-7)
  fill(frame,14,47,WIDTH-28,1,EDGE)
  count=label(frame,17,30,180,"GameFontHighlightSmall",DIM)
  clear=button(frame,WIDTH-96,25,79,18,"Clear pin","Clear your current loot map pin.")
  clear.codexLabel="Clear loot map"
  clear:SetScript("OnClick",L.clearMapTarget)

  rows={}
  for i=1,ROWS do
    local y=53+(i-1)*ROW_HEIGHT
    local row=CreateFrame("Frame",nil,frame)
    row:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-y)
    row:SetSize(WIDTH-28,ROW_HEIGHT-5)
    fill(row,0,0,WIDTH-28,ROW_HEIGHT-5,STRIPE)
    local stripe=fill(row,0,0,3,ROW_HEIGHT-5,EDGE)
    local open=CreateFrame("Button",nil,row)
    open:SetPoint("TOPLEFT",0,0);open:SetSize(WIDTH-62,ROW_HEIGHT-5)
    open:EnableMouse(true);open:RegisterForClicks("LeftButtonUp")
    highlight(open)
    open:SetScript("OnEnter",function(self) L.showItemTooltip(self,self.itemRef,"ANCHOR_LEFT") end)
    open:SetScript("OnLeave",function(self) L.hideItemTooltip(self) end)
    local rim=fill(open,9,12,36,36,GOLD)
    local icon=open:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("TOPLEFT",10,-13);icon:SetSize(34,34)
    local name=label(open,53,7,224,"GameFontHighlight",INK)
    local source=label(open,53,25,224,"GameFontHighlightSmall",GOLD)
    local place=label(open,53,42,224,"GameFontHighlightSmall",DIM)
    local map=button(row,WIDTH-106,36,40,18,"Map","Open this target's source location.")
    map:SetFrameLevel(open:GetFrameLevel()+1)
    local remove=button(row,WIDTH-60,18,24,23,"X","Remove this target from your list.")
    rows[i]={frame=row,open=open,map=map,remove=remove,icon=icon,name=name,source=source,place=place,stripe=stripe,rim=rim,y=y}
  end
  more=button(frame,14,111,WIDTH-28,22,"Open loot journal","Open the full list of saved loot targets.")
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
          out[#out+1]={frame=row.open,x=116,y=row.y+24}
          out[#out+1]={frame=row.map,x=WIDTH-70,y=row.y+44}
          out[#out+1]={frame=row.remove,x=WIDTH-36,y=row.y+29}
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
  if theme~=ns.themeVersion then
    theme=ns.themeVersion
    local backdrop=A.backdrop(frame,"dialog",PANEL,C.edge)
    local skinned=ns.skinSupport.backing(frame,"Panel")
    background:SetColorTexture(ns.rgba(PANEL))
    background:SetShown(not backdrop and not skinned)
    headerArt:SetShown(not C.eui and A.set(headerArt,"header"))
    header:SetTextColor(ns.rgba(C.gold))
    ns.skinSupport.fonts(frame)
    for _,row in ipairs(rows) do row.stripe:SetColorTexture(ns.rgba(C.accent)) end
  end
  local visible=math.min(#list,ROWS)
  frame:SetHeight(85+visible*ROW_HEIGHT)
  more:ClearAllPoints()
  more:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",14,10)
  count:SetText(#list>visible and (visible.." of "..#list.." active targets") or (#list==1 and "1 active target" or (#list.." active targets")))
  clear:SetShown(L.mapTarget()~=nil)
  local ctx=L.context()
  for i,row in ipairs(rows) do
    local target=list[i]
    row.frame:SetShown(target~=nil)
    if target then
      local it=L.item(target.ref)
      ns.setIcon(row.icon,it and it.icon)
      local source,other=L.targetSource(target,ctx)
      local kind=source and (L.sourceNames[source.type] or source.type)
      local place=source and L.sourceLocation(source)
      local mapped=source and source.map and type(source.x)=="number" and type(source.y)=="number" or false
      local name=ns.plain(it and it.name or target.name)
      local where=ns.plain(source and (source.name or place or kind) or "Source unverified")
      row.name:SetText(name)
      row.source:SetText(where)
      local info=kind or (it and it.tradable and "Tradable item" or "")
      if place and place~=where and source.type~="craft" then info=info.." / "..place end
      if other>0 then info=info.." / +"..other.." more" end
      row.place:SetWidth(mapped and 177 or 224)
      row.place:SetText(ns.plain(info))
      local r,g,b=L.call(GetItemQualityColor,it and it.quality or 1)
      row.rim:SetColorTexture(r or GOLD[1],g or GOLD[2],b or GOLD[3],1)
      row.open.tipTitle=name
      row.open.tipText=where.."\nOpen item details."
      row.open.codexLabel="Loot target "..name
      row.open.itemRef=target.ref
      row.open:SetScript("OnClick",function() L.open("Compare",target.ref,source and source.id) end)
      row.map.codexLabel="Map loot target "..name
      row.map:SetShown(mapped)
      row.map:SetScript("OnClick",function()
        local _,why=L.showSourceOnMap(source.id)
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
