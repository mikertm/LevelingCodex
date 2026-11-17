-- Loot's equipment overview, compact browser, and focused comparison pages.
local _, ns = ...
local L,U,C=ns.loot,ns.ui,ns.C
local section,view="Upgrades","character"
local filters={slot="INVTYPE_CHEST",source="all",style="all",search=""}
local offset,sourceOffset,slotNumber=0,0,5
local selected,input,message,code,editor,preview,picker
local advanced,planning=false,false
local detailSection="Overview"
local PAGE=5
local SLOTS={
  {1,"Head","INVTYPE_HEAD"},{2,"Neck","INVTYPE_NECK"},{3,"Shoulder","INVTYPE_SHOULDER"},
  {15,"Back","INVTYPE_CLOAK"},{5,"Chest","INVTYPE_CHEST"},{9,"Wrist","INVTYPE_WRIST"},
  {10,"Hands","INVTYPE_HAND"},{6,"Waist","INVTYPE_WAIST"},{7,"Legs","INVTYPE_LEGS"},
  {8,"Feet","INVTYPE_FEET"},{11,"Ring","INVTYPE_FINGER"},{13,"Trinket","INVTYPE_TRINKET"},
  {16,"Main hand","INVTYPE_WEAPON"},{17,"Off hand","INVTYPE_WEAPONOFFHAND"},
  {18,"Ranged","INVTYPE_RANGED"},{18,"Relic","INVTYPE_RELIC"},
}
local SLOT_ART={[1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",[7]="Legs",[8]="Feet",
  [9]="Wrists",[10]="Hands",[11]="Finger",[12]="Finger",[13]="Trinket",[14]="Trinket",
  [15]="Chest",[16]="MainHand",[17]="SecondaryHand",[18]="Ranged"}
local SOURCES={"all","quest","boss","dungeonTrash","raidTrash","creature","rare","object","world","vendor","craft","reputation","pvp"}
local STYLES={all="Any play style",solo="Solo",group="Group",buy="Buy / craft"}
local STAT_NAMES={str="Strength",agi="Agility",sta="Stamina",int="Intellect",spi="Spirit",armor="Armor",
  ap="Attack power",rap="Ranged attack power",sp="Spell power",heal="Healing",defense="Defense",
  hit="Hit",crit="Critical strike",dodge="Dodge",parry="Parry",block="Block",mp5="Mana per 5 sec"}

local function refresh(top)
  if top then U.refreshTop() elseif ns.refreshLootTab then ns.refreshLootTab() end
end
local function context() return L.context(preview) end
local function text(s,y,kind,color,x,w)
  return y+U.T(ns.plain(s),x or 12,y,w or U.W-24,kind or "body",color or C.light)+7
end
-- Fixed-height rows clip long names instead of wrapping into their neighbours.
local function line(s,x,y,w,kind,color,justify)
  local _,fs=U.T(ns.plain(s),x,y,w,kind or "small",color or C.light,justify)
  fs:SetWordWrap(false)
  local label=ns.plain(s)
  if fs.GetStringWidth then
    while #label>3 and fs:GetStringWidth()>w do
      label=label:sub(1,-2);fs:SetText(label.."...")
    end
  end
  return fs
end
-- Quiet themed controls: results, slots and actions share one visual language.
local function button(label,x,y,w,fn,on,tip)
  U.plate(x,y,w,22,on and C.btnOn or C.btnOff,on and C.accent or C.edgeSoft)
  line(label,x+6,y+3,w-12,"small",on and C.btnOnInk or C.light,"CENTER")
  local b=U.hit(x,y,w,22,ns.plain(label),tip,fn,ns.plain(label))
  b.codexOn=on
  return b
end
local function itemTip(b,it,description)
  b.tipTitle,b.tipText=ns.plain(it.name),ns.plain(description or "Select to inspect this item.")
  b:SetScript("OnEnter",function(self)
    if GameTooltip and GameTooltip.SetHyperlink then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      if pcall(GameTooltip.SetHyperlink,GameTooltip,it.key or ("item:"..it.id)) then GameTooltip:Show();return end
    end
    ns.art.showTip(self)
  end)
  b:SetScript("OnLeave",function(self)
    if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end)
end
local function choose(ref)
  selected=ref;sourceOffset=0;detailSection="Overview";message=nil
  if section=="Upgrades" then view="detail" end
  refresh(true)
end
local function resetResults() offset=0;selected=nil;refresh(true) end
local function slotTitle()
  for _,s in ipairs(SLOTS) do if s[3]==filters.slot then return s[2] end end
  return "Gear"
end
local function chooseSlot(n,key)
  slotNumber=n;filters.slot=key;offset=0;selected=nil;view="list";picker=nil;message=nil;refresh(true)
end
local function slotKey(n,ctx)
  if n==12 then return "INVTYPE_FINGER" elseif n==14 then return "INVTYPE_TRINKET" end
  if n==18 and (ctx.class=="PALADIN" or ctx.class=="SHAMAN" or ctx.class=="DRUID") then return "INVTYPE_RELIC" end
  for _,s in ipairs(SLOTS) do if s[1]==n then return s[3] end end
end
local function equippedName(it,known)
  return it and it.name or (known and "Empty slot" or "Equipment unavailable")
end
local function paperSlot(n,x,y,w,ctx)
  local it=ctx.snapshot.slots[n]
  local label=L.slotNames[n]
  U.plate(x,y,w,32,C.btnOff,C.edgeSoft)
  local art=it and it.icon or ("Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[n] or "Chest"))
  U.icon(art,x+4,y+3,26,label,equippedName(it,ctx.snapshot.equipmentKnown))
  line(label,x+36,y+1,w-42,"small",C.dim)
  line(equippedName(it,ctx.snapshot.equipmentKnown),x+36,y+15,w-42,"small",it and C.light or C.dim)
  local b=U.hit(x,y,w,32,label,"Find upgrades for this slot.",function() chooseSlot(n,slotKey(n,ctx)) end,"Browse "..label)
  if it then itemTip(b,it,"Select to browse upgrades for "..label..".") end
end
local function character(y,ctx)
  y=text("Your equipment",y,"head",C.gold)
  y=text("Select a gear slot to browse upgrades and where to get them.",y,"small",C.dim)
  local top=y
  U.box(188,top,192,238,C.panel,C.edgeSoft)
  if not U.playerDoll(192,top+4,184,230,not ctx.preview) then
    -- A neutral silhouette keeps slot navigation useful without optional model APIs.
    local c=C.edgeSoft
    U.rect(271,top+30,26,30,c);U.rect(247,top+66,74,22,c)
    U.rect(260,top+84,48,58,c);U.rect(243,top+88,13,65,c);U.rect(312,top+88,13,65,c)
    U.rect(261,top+146,19,61,c);U.rect(288,top+146,19,61,c)
    line(ctx.preview and "Planning preview" or "Character preview",196,top+215,176,"small",C.dim,"CENTER")
  end
  for i,n in ipairs({1,2,3,15,5,9,10}) do paperSlot(n,4,top+(i-1)*34,180,ctx) end
  for i,n in ipairs({6,7,8,11,12,13,14}) do paperSlot(n,384,top+(i-1)*34,180,ctx) end
  for i,n in ipairs({16,17,18}) do paperSlot(n,4+(i-1)*188,top+246,180,ctx) end
  return text("Estimated gear score is advisory. Review stat tradeoffs and unscored effects.",top+290,"small",C.dim)
end

local function baseline(y,ctx)
  local slots={slotNumber}
  if filters.slot=="INVTYPE_FINGER" then slots={11,12} elseif filters.slot=="INVTYPE_TRINKET" then slots={13,14} end
  U.plate(108,y,U.W-108,40,C.panel,C.edgeSoft)
  line("Currently equipped",118,y+3,180,"small",C.dim)
  local names={}
  for _,n in ipairs(slots) do
    names[#names+1]=(#slots>1 and (L.slotNames[n]..": ") or "")..equippedName(ctx.snapshot.slots[n],ctx.snapshot.equipmentKnown)
  end
  line(table.concat(names,"  /  "),118,y+20,U.W-128,"small",C.light)
  U.hit(108,y,U.W-108,40,"Currently equipped",ns.plain(table.concat(names,"\n")))
  return y+46
end
local function resetFilters()
  filters={slot=filters.slot,source="all",style="all",search=""};picker=nil;resetResults()
end
local function extraFilters(y,ctx)
  local x,w=108,U.W-108
  if picker then
    local keys=picker=="source" and SOURCES or {"all","solo","group","buy"}
    U.plate(x,y,w,math.ceil(#keys/3)*26+8,C.panel,C.edgeSoft)
    for i,k in ipairs(keys) do
      local key=k
      local label=picker=="source" and (L.sourceNames[k] or "All sources") or STYLES[k]
      button(label,x+4+(i-1)%3*150,y+4+math.floor((i-1)/3)*26,146,function()
        filters[picker]=key;picker=nil;resetResults()
      end,filters[picker]==key)
    end
    y=y+math.ceil(#keys/3)*26+14
  end
  if not advanced then return y end
  U.plate(x,y,w,116,C.panel,C.edgeSoft)
  for i,e in ipairs({{"Zone","LootZone","zone"},{"Dungeon","LootDungeon","dungeon"},{"Profession","LootProfession","profession"}}) do
    local field=e[3];local xx=x+10+(i-1)*150
    line(e[1],xx,y+8,138,"small",C.dim)
    U.entry(e[2],xx,y+26,138,filters[field] or "",function(v) filters[field]=field=="profession" and v:upper() or v end,resetResults,80)
  end
  line("Available by level",x+10,y+62,122,"small",C.dim)
  button("-",x+130,y+58,26,function() filters.maxLevel=math.max(1,(filters.maxLevel or ctx.level)-5);resetResults() end)
  line(tostring(filters.maxLevel or ctx.level),x+160,y+62,24,"small",C.light,"CENTER")
  button("+",x+188,y+58,26,function() filters.maxLevel=math.min(60,(filters.maxLevel or ctx.level)+5);resetResults() end)
  button(filters.showIneligible and "Ineligible: shown" or "Ineligible: hidden",x+228,y+58,218,function() filters.showIneligible=not filters.showIneligible;resetResults() end,filters.showIneligible)
  line("Level changes plan availability; comparisons use your current character.",x+10,y+91,w-20,"small",C.dim)
  return y+124
end
local function sourceSummary(row)
  local s=row.sources[1]
  if not s then return "Source unverified",row.item.tradable and "Tradable" or "Check in game" end
  local name=s.dungeon or s.zone or s.profession or s.name or ""
  return (L.sourceNames[s.type] or s.type)..(#row.sources>1 and (" +"..(#row.sources-1)) or ""),name
end
local function browse(y,ctx)
  local x,w=108,U.W-108
  local sidebarBottom=y+54+#SLOTS*20
  local back=button("< Character",0,y,100,function() view="character";selected=nil;refresh(true) end)
  back.codexLabel,back.tipTitle="Back to character","Back to character"
  U.entry("LootSearch",x+6,y,w-94,filters.search,function(v) filters.search=v end,resetResults,80)
  button("Search",U.W-80,y,80,resetResults)
  line("Gear slots",6,y+33,94,"small",C.dim)
  for i,s in ipairs(SLOTS) do
    local n,key=s[1],s[3]
    local yy=y+54+(i-1)*20
    if filters.slot==key then U.plate(0,yy,100,19,C.btnOn,C.accent) end
    line(s[2],8,yy+2,84,"small",filters.slot==key and C.btnOnInk or C.dim)
    U.hit(0,yy,100,19,s[2],"Browse this equipment slot.",function() chooseSlot(n,key) end,"Slot "..s[2])
  end
  y=y+29
  button(L.sourceNames[filters.source] or "All sources",x,y,152,function() if picker=="source" then picker=nil else picker="source" end;refresh() end,picker=="source","Choose acquisition sources.")
  button(STYLES[filters.style],x+158,y,146,function() if picker=="style" then picker=nil else picker="style" end;refresh() end,picker=="style","Choose solo, group, or buy / craft.")
  local extra=0
  for _,key in ipairs({"zone","dungeon","profession"}) do if filters[key] and filters[key]~="" then extra=extra+1 end end
  if filters.showIneligible then extra=extra+1 end
  if filters.maxLevel and filters.maxLevel~=ctx.level then extra=extra+1 end
  local moreLabel=advanced and "Fewer filters" or "More filters"
  local more=button(moreLabel..(extra>0 and (" ("..extra..")") or ""),x+310,y,w-310,function() advanced=not advanced;picker=nil;refresh() end,advanced)
  more.codexLabel=moreLabel
  y=extraFilters(y+29,ctx)
  y=baseline(y,ctx)
  local page=L.candidates(filters,ctx,offset,PAGE)
  if offset>0 and offset>=page.total then
    offset=math.max(0,math.floor((page.total-1)/PAGE)*PAGE);page=L.candidates(filters,ctx,offset,PAGE)
  end
  line(slotTitle().." upgrades",x,y,220,"body",C.gold)
  button("Reset filters",U.W-104,y-2,104,resetFilters);y=y+23
  line(page.total.." matching items",x,y,200,"small",C.dim)
  button(filters.sort=="acquisition" and "Sort: Access" or "Sort: Power",U.W-104,y-2,104,function()
    if filters.sort=="acquisition" then filters.sort=nil else filters.sort="acquisition" end;resetResults()
  end);y=y+25
  if page.total==0 then
    U.box(x,y,w,92,C.panel,C.edgeSoft)
    text("No matching items",y+14,"body",C.gold,x+12,w-24)
    text("Try another slot or reset your filters.",y+42,"small",C.dim,x+12,w-24)
    y=y+100
  end
  for i,row in ipairs(page.rows) do
    local it,r=row.item,row.result
    U.plate(x,y,w,40,i%2==1 and C.panel or C.btnOff,C.edgeSoft)
    U.icon(it.icon,x+5,y+6,28,it.name,r.reason)
    line(it.name,x+42,y+3,245,"small",C.light)
    local source,where=sourceSummary(row)
    line(source..(where~="" and (" / "..where) or ""),x+42,y+22,245,"small",C.dim)
    line(L.labels[r.verdict] or r.verdict,x+300,y+3,w-308,"small",r.verdict=="upgrade" and C.green or C.dim,"RIGHT")
    local gain=row.futureLevel and ("At level "..row.futureLevel) or (r.percent and string.format("%+.1f%% score",r.percent) or "Review stats")
    line(gain,x+300,y+22,w-308,"small",C.dim,"RIGHT")
    local b=U.hit(x,y,w,40,it.name,r.reason,function() choose(it.id) end,"Inspect item "..it.id)
    itemTip(b,it,r.reason);y=y+43
  end
  if offset>0 then button("Previous loot page",x,y,132,function() offset=math.max(0,offset-PAGE);refresh(true) end) end
  line("Page "..(page.total>0 and math.floor(offset/PAGE)+1 or 0).." of "..math.ceil(page.total/PAGE),x+138,y+4,w-276,"small",C.dim,"CENTER")
  if offset+PAGE<page.total then button("Next loot page",U.W-132,y,132,function() offset=offset+PAGE;refresh(true) end) end
  return math.max(y+30,sidebarBottom+8)
end

local function statOverview(it,r,y)
  local top=y
  y=text(r.reason,y+10,"body",C.light)
  if r.score then y=text(string.format("Estimated gear score: %.1f vs %.1f",r.score,r.baselineScore or 0),y,"small",C.dim) end
  if #r.baseline>0 then
    y=text("Compared with your equipped gear",y+6,"body",C.gold)
    for _,old in ipairs(r.baseline) do y=text(old.name,y,"small",C.light) end
  end
  if #r.replacedSlots>0 then
    local names={};for _,n in ipairs(r.replacedSlots) do names[#names+1]=L.slotNames[n] or tostring(n) end
    y=text("Replaces: "..table.concat(names,", "),y,"small",C.dim)
  end
  U.box(0,top,U.W,y-top+4,C.panel,C.edgeSoft);y=y+16
  local keys={};for k,n in pairs(r.statDelta) do if n~=0 then keys[#keys+1]=k end end;table.sort(keys)
  if #keys>0 then
    y=y+U.sectionTitle("Stat changes",y)
    for _,k in ipairs(keys) do
      U.plate(4,y,U.W-8,22,C.btnOff,C.edgeSoft)
      line(STAT_NAMES[k] or k,16,y+3,U.W-140,"small",C.light)
      line(string.format("%+.1f",r.statDelta[k]),U.W-110,y+3,90,"small",r.statDelta[k]>0 and C.green or C.gold,"RIGHT")
      y=y+24
    end
  end
  if #r.warnings>0 then
    y=y+U.sectionTitle("Check before replacing",y+8)
    for _,warning in ipairs(r.warnings) do y=text(warning,y,"small",C.gold) end
  end
  return y
end
local function acquisition(it,y,ctx)
  local sources=L.sources(it.id,nil,ctx)
  if #sources==0 then y=text("No verified acquisition source in this catalog. Check the item in game.",y,"body",C.dim) end
  if sourceOffset>=#sources then sourceOffset=0 end
  for i=sourceOffset+1,math.min(#sources,sourceOffset+3) do
    local s=sources[i];local top=y
    y=text((L.sourceNames[s.type] or s.type)..": "..(s.name or "Unknown source"),y+12,"body",C.gold)
    if s.dungeon or s.zone then y=text(s.dungeon or s.zone,y,"small",C.light) end
    if s.giverName then y=text("Starts with "..s.giverName,y,"small",C.dim) end
    if s.requiredLevel then y=text("Source requires level "..s.requiredLevel,y,"small",C.dim) end
    if s.locationKind=="entrance" then y=text("Map location: dungeon entrance, not the boss room.",y,"small",C.dim) end
    if s.prerequisites and #s.prerequisites>0 then y=text("Prerequisite quests: "..table.concat(s.prerequisites,", "),y,"small",C.dim) end
    if s.cost then y=text("Cost: "..(ns.money and ns.money(s.cost) or tostring(s.cost)),y,"small") end
    if s.materials then
      local mats={};for name,n in pairs(s.materials) do mats[#mats+1]=n.." "..name end;table.sort(mats)
      y=text("Materials: "..table.concat(mats,", "),y,"small")
    end
    y=text(s.evidence=="client" and "Client reference" or "Database reference; server availability may vary",y,"small",C.dim)
    button("Track source "..i,12,y,162,function() local key,err=L.track(it.key,s.id);message=err or (key and "Source tracked");refresh() end)
    if s.map and L.showSourceOnMap then button("Map source "..i,184,y,162,function() local _,why=L.showSourceOnMap(s.id);message=why;refresh() end)
    else line("Location not verified",184,y+4,162,"small",C.dim) end
    if s.quest and L.openQuestSource then button("Quest guide "..i,356,y,196,function() L.openQuestSource(s.quest) end) end
    y=y+34;U.box(0,top,U.W,y-top,C.panel,C.edgeSoft);y=y+10
  end
  if #sources>3 then
    button("More sources",12,y,160,function() sourceOffset=sourceOffset+3;if sourceOffset>=#sources then sourceOffset=0 end;refresh(true) end)
    line((sourceOffset+1).."-"..math.min(#sources,sourceOffset+3).." of "..#sources.." sources",184,y+4,240,"small",C.dim);y=y+32
  end
  if it.tradable then y=text("Tradable: another player or the auction house may have it. Price unknown.",y,"small",C.dim) end
  return y
end
local function enchantOptions(it,y,ctx)
  local enchants=L.enchants(it,ctx)
  if #enchants==0 then return text("No verified enchant suggestions for this item and level.",y,"body",C.dim) end
  for i=1,math.min(3,#enchants) do
    local a=enchants[i];local top=y
    y=text(a.enchant.name,y+12,"body",C.gold)
    y=text(a.reason,y,"small",C.dim)
    y=text(a.enchant.source or "Ask an enchanter; acquisition requirements may vary.",y,"small",C.light)
    if a.enchant.plan then y=text("Formula: "..a.enchant.plan.item.." (Enchanting "..tostring(a.enchant.plan.skill or "unknown")..")",y,"small",C.dim) end
    local mats={};for name,n in pairs(a.enchant.materials or {}) do mats[#mats+1]=n.." "..name end;table.sort(mats)
    if #mats>0 then y=text("Materials: "..table.concat(mats,", "),y,"small",C.dim) end
    U.box(0,top,U.W,y-top+6,C.panel,C.edgeSoft);y=y+18
  end
  button("Enchanting guide",12,y,220,function() if ns.profTabShow then ns.profTabShow("ENCHANTING") end;ns.openTab("professions") end)
  return y+32
end
local function details(ref,y)
  local it=L.item(ref)
  if not it then return text("Enter a valid item link or item ID.",y) end
  local ctx=context();local r=L.compare(it,ctx)
  L.lastComparison=it.name..": "..(L.labels[r.verdict] or r.verdict).." - "..r.reason
  if section=="Upgrades" then
    button("Back to results",0,y,146,function() view="list";selected=nil;refresh(true) end)
    line(slotTitle().." upgrades",160,y+4,U.W-172,"small",C.dim);y=y+32
  end
  local top=y
  U.icon(it.icon,12,y+10,36,it.name,r.reason)
  y=text(it.name,y+8,"head",C.gold,60,U.W-72)
  local pct=r.percent and string.format(" (%+.1f%% estimated gear score)",r.percent) or ""
  y=text((L.labels[r.verdict] or r.verdict)..pct,y,"small",r.verdict=="upgrade" and C.green or C.gold,60,U.W-72)
  U.box(0,top,U.W,y-top+6,C.panel,C.edgeSoft);y=y+16
  button("Track this item",0,y,180,function() local key,err=L.track(it.key);message=err or (key and "Target tracked");refresh() end)
  button("Compare this item",190,y,180,function() input=it.key;section="Compare";selected=it.key;refresh(true) end)
  button("Where to get it",380,y,U.W-380,function() detailSection="Sources";refresh(true) end,detailSection=="Sources");y=y+32
  for i,label in ipairs({"Overview","Sources","Enchants"}) do
    button(label,(i-1)*190,y,184,function() detailSection=label;refresh(true) end,detailSection==label)
  end
  y=y+32
  if detailSection=="Sources" then return acquisition(it,y,ctx)
  elseif detailSection=="Enchants" then return enchantOptions(it,y,ctx) end
  return statOverview(it,r,y)
end

local function compare(y,ctx)
  y=text("Check an item",y,"head",C.gold)
  y=text("Paste an item link or item ID",y,"small",C.dim)
  local function submit()
    local key=L.itemKey(input);message=not key and "Enter a valid item link or item ID." or nil
    if key then choose(key) else selected=nil;refresh() end
  end
  U.entry("LootItem",12,y,U.W-162,input or "",function(v) input=v end,submit,2048)
  button("Check item",U.W-136,y,124,submit);y=y+32
  button(planning and "Hide planning" or "Planning options",12,y,180,function() planning=not planning;refresh() end,planning)
  button("Live character",204,y,180,function() preview=nil;refresh() end,not ctx.preview)
  button("Gear / bags",396,y,160,function() selected=nil;input=nil;refresh(true) end);y=y+32
  if planning then
    U.plate(0,y,U.W,144,C.panel,C.edgeSoft)
    line("Preview class / faction",12,y+10,240,"small",C.dim)
    button(ctx.class,12,y+30,250,function()
      local list={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
      for i,c in ipairs(list) do if c==ctx.class then preview=preview or {};preview.class=list[i%#list+1];selected=nil;break end end
      refresh()
    end)
    button(ctx.faction or "Unknown faction",274,y+30,280,function() preview=preview or {};preview.faction=ctx.faction=="Alliance" and "Horde" or "Alliance";refresh() end)
    line("Level (1-60)",12,y+62,100,"small",C.dim)
    line("Baseline item link or ID",132,y+62,410,"small",C.dim)
    U.entry("LootPreviewLevel",12,y+82,100,tostring(ctx.level),nil,function(v)
      local n=tonumber(v);if n and n>=1 and n<=60 then preview=preview or {};preview.level=math.floor(n) else message="Use a level from 1 to 60" end;refresh()
    end,2)
    U.entry("LootBaseline",132,y+82,412,preview and preview.baselineText or "",function(v) preview=preview or {};preview.baselineText=v end,function(v)
      local key=L.itemKey(v)
      if key then
        local it=L.item(key);preview=preview or {};preview.snapshot={slots={},equipmentKnown=true}
        for _,n in ipairs(L.slotsFor(it.slot)) do preview.snapshot.slots[n]=it end
      else message="Enter a valid baseline item link" end;refresh()
    end,2048)
    line("Press Enter to apply a preview field. Unknown slots remain unverified.",12,y+116,U.W-24,"small",C.dim)
    y=y+156
  end
  if selected then return details(selected,y) end
  y=y+U.sectionTitle("Equipped and bag items",y)
  local snapshot=L.snapshot()
  for _,n in ipairs(L.slotOrder) do
    local it=snapshot.slots[n]
    if it then local key=it.key;button(L.slotNames[n]..": "..it.name,12,y,U.W-24,function() input=key;choose(key) end);y=y+27 end
  end
  local keys={};for key in pairs(snapshot.bagLinks) do keys[#keys+1]=key end;table.sort(keys)
  for i=1,math.min(#keys,40) do
    local key=keys[i];local it=L.item(key)
    if it then button("Bag: "..it.name,12,y,U.W-24,function() input=key;choose(key) end);y=y+27 end
  end
  if #keys==0 then y=text("No additional bag equipment available.",y,"small",C.dim) end
  return y
end
local function tracked(y)
  y=text("Your upgrade targets",y,"head",C.gold)
  local list=L.targets()
  if #list==0 then return text("Choose an item or source and press Track to plan an upgrade.",y,"body",C.dim) end
  for _,t in ipairs(list) do
    local top=y
    button(t.name.." - "..t.state,12,y+10,U.W-24,function() section="Compare";input=t.ref;choose(t.ref) end)
    local sources=L.sources(t.id)
    local source
    for _,s in ipairs(sources) do if s.id==t.sourceID then source=s;break end end
    y=text(source and ((L.sourceNames[source.type] or source.type)..": "..(source.name or "Unknown source")) or "Item target - choose a source in the item details",y+40,"small",C.dim)
    button(t.state=="tracked" and "Dismiss" or "Restore",12,y,120,function() L.setTargetState(t.key,t.state=="tracked" and "dismissed" or "tracked");refresh() end)
    button("Untrack",142,y,120,function() L.untrack(t.key);refresh() end)
    if t.sourceID and L.showSourceOnMap then button("Map "..t.name,272,y,U.W-284,function() local _,why=L.showSourceOnMap(t.sourceID);message=why;refresh() end) end
    y=y+34;U.box(0,top,U.W,y-top,C.panel,C.edgeSoft);y=y+12
  end
  return y
end
local function profiles(y,ctx)
  local p=ctx.profile
  y=text("Loot scoring profile",y,"head",C.gold)
  y=text("Automatic follows your talent path. Manual choices change loot advice only.",y,"small",C.dim)
  button("Follow talent path",12,y,250,function() L.resetProfile();editor=nil;refresh() end)
  button("Export profile",284,y,260,function() code=L.profileCode();refresh() end);y=y+34
  for _,p0 in ipairs((ns.TALENT_PATHS or {})[ctx.class] or {}) do
    button(p0.spec,12,y,U.W-24,function()
      if ctx.preview then preview=preview or {};preview.profileKey=p0.key else L.setProfile(p0.key) end
      editor=nil;refresh()
    end,p0.key==p.key);y=y+27
  end
  y=y+U.sectionTitle("Share a profile",y+10)
  U.entry("LootProfileCode",12,y,U.W-24,code or "",function(v) code=v end,function(v)
    local ok,err=L.readProfileCode(v);message=ok and "Profile imported" or err;editor=nil;refresh()
  end,4096);y=y+32
  button("Import profile",12,y,250,function() local ok,err=L.readProfileCode(code or "");message=ok and "Profile imported" or err;editor=nil;refresh() end)
  button("Edit weights",284,y,260,function()
    editor={class=ctx.class,label="Custom",weights={},weapon={}}
    for k,v in pairs(p.weights) do editor.weights[k]=v end;for k,v in pairs(p.weapon) do editor.weapon[k]=v end;refresh()
  end);y=y+34
  if editor then
    y=y+U.sectionTitle("Advanced scoring weights",y)
    local keys={};for k in pairs(L.profileStatKeys) do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys) do
      line(STAT_NAMES[k] or k,12,y+4,210,"small",C.dim)
      U.entry("LootWeight"..k,230,y,170,tostring(editor.weights[k] or 0),function(v) editor.weights[k]=v end,nil,16);y=y+27
    end
    for _,k in ipairs({"melee","ranged","speed"}) do
      line("Weapon "..k,12,y+4,210,"small",C.dim)
      U.entry("LootWeapon"..k,230,y,170,tostring(editor.weapon[k] or 0),function(v) editor.weapon[k]=v end,nil,16);y=y+27
    end
    button(editor.weapon.feral and "Feral policy: on" or "Feral policy: off",12,y,260,function() editor.weapon.feral=not editor.weapon.feral;refresh() end);y=y+30
    button("Save weights",12,y,250,function()
      for k,v in pairs(editor.weights) do editor.weights[k]=tonumber(v) or -1 end
      for _,k in ipairs({"melee","ranged","speed"}) do editor.weapon[k]=tonumber(editor.weapon[k]) or 0 end
      local ok,err=L.setProfile(editor);message=ok and "Custom weights saved" or err;if ok then editor=nil end;refresh()
    end);y=y+32
  end
  return y
end
local function render()
  local ctx=context();local p=ctx.profile
  U.box(0,6,U.W,44,C.parch,C.edge)
  line("Loot",12,14,65,"head",C.ink)
  line((ctx.preview and "Planning: " or "Your gear: ")..ctx.class.." / Level "..ctx.level.." / "..(p and p.label or "No profile"),85,15,U.W-100,"small",C.ink)
  line("Estimated gear score is advisory.",85,31,U.W-100,"small",C.inkSoft)
  for i,label in ipairs({"Upgrades","Compare","Tracked","Profiles"}) do
    button(label,(i-1)*143,58,139,function() section=label;message=nil;picker=nil;refresh(true) end,section==label)
  end
  local y=92
  if message then y=text(message,y,"small",C.gold) end
  if not p then return text("Loot profiles are not available for this class.",y,"body",C.dim)+20 end
  if L.mapTarget and L.mapTarget() then
    button("Clear loot map target",12,y,260,function() L.clearMapTarget();refresh() end);y=y+32
  end
  if section=="Upgrades" then
    if view=="character" then y=character(y,ctx)
    elseif view=="detail" and selected then y=details(selected,y)
    else y=browse(y,ctx) end
  elseif section=="Compare" then y=compare(y,ctx)
  elseif section=="Tracked" then y=tracked(y)
  else y=profiles(y,ctx) end
  return y+8
end
ns.addTab("loot","Loot",render)
function L.open(want,ref)
  if want then section=want end
  if ref then selected=ref;input=tostring(ref);detailSection="Overview";sourceOffset=0;if section=="Upgrades" then view="detail" end end
  ns.openTab("loot")
end
L.subscribe(function() if ns.refreshLootTab then ns.refreshLootTab() end end)
