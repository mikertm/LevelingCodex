-- Loot's equipment overview, compact browser, and focused comparison pages.
local _, ns = ...
local L,U,Theme=ns.loot,ns.ui,ns.C
local C={}
local function palette()
  if Theme.eui then
    for k,v in pairs(Theme) do C[k]=v end
    C.background={Theme.bg[1],Theme.bg[2],Theme.bg[3],1}
    C.loss={1,0.55,0.49}
    return
  end
  C.background={0.055,0.078,0.099,1}
  C.panel={0.085,0.125,0.151,1}
  C.btnOff={0.112,0.16,0.192,1}
  C.btnOn={0.13,0.28,0.32,1}
  C.light={0.91,0.94,0.95}
  C.btnOnInk=C.light
  C.dim={0.66,0.74,0.77}
  C.gold={0.93,0.83,0.63}
  C.green={0.60,0.86,0.48}
  C.loss={1,0.61,0.53}
  C.edge={0.45,0.53,0.54,0.72}
  C.edgeSoft={0.47,0.61,0.65,0.27}
  C.accent=Theme.accent
  C.ribbon={0.11,0.21,0.23,1}
end
local ART="Interface\\AddOns\\LevelingCodex\\media\\"
local section,view="Upgrades","character"
local filters={slot="INVTYPE_CHEST",source="all",style="all",search=""}
local offset,sourceOffset,slotNumber=0,0,5
local selected,input,message,code,editor,preview,picker
local planning=false
local detailSection="Overview"
local expandedSource, preferredSource
local inventoryMode,inventoryGroup,inventoryPage="Equipped","Armor",0
local sharing=false
local targetFilter,targetPage="all",0
local PAGE=4
local WIDTH,SIDE=870,580
local browseItem
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
local SOURCE_ICONS={quest="inv_misc_book_09",boss="inv_helmet_03",dungeonTrash="inv_misc_bone_humanskull_01",
  raidTrash="inv_misc_bone_humanskull_01",creature="ability_hunter_beastcall",rare="ability_hunter_snipershot",
  object="inv_misc_treasurechest01",world="inv_misc_map_01",vendor="inv_misc_coin_01",craft="trade_blacksmithing",
  reputation="inv_misc_tabardpvp_01",pvp="inv_sword_04"}
local VERDICT_COLORS={upgrade="green",downgrade="loss",cannotEquip="loss",needsReview="gold"}
local function verdictColor(verdict)
  return C[VERDICT_COLORS[verdict] or "dim"]
end
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
-- Artwork is drawn below the single mouse target for each row or control.
local function action(x,y,w,h,title,tip,click,label)
  local row=U.hit(x,y,w,h,title,tip,click,label)
  if click then
    row:EnableMouse(true)
    row:RegisterForClicks("LeftButtonUp")
    row:SetFrameLevel(row:GetParent():GetFrameLevel()+3)
  end
  return row
end

-- Quiet themed controls: results, slots and actions share one visual language.
local function button(label,x,y,w,fn,on,tip)
  U.surface(x,y,w,22,on and C.btnOn or C.btnOff,on and C.edge or C.edgeSoft)
  line(label,x+6,y+3,w-12,"small",on and C.btnOnInk or C.light,"CENTER")
  local b=action(x,y,w,22,ns.plain(label),tip,fn,ns.plain(label))
  b.codexOn=on
  return b
end
local function quality(q)
  if Theme.eui then return C.light end
  return ({[0]=C.dim,[2]={0.65,0.88,0.49},[3]={0.55,0.76,1},[4]={0.81,0.66,0.99},[5]={1,0.72,0.44}})[q] or C.light
end
local function itemIcon(it,x,y,size,title,tip,fallback)
  local f=U.icon(it and it.icon or fallback,x,y,size,title,tip)
  local rim=it and quality(it.quality) or C.edgeSoft
  f.ring:SetColorTexture(rim[1],rim[2],rim[3],1)
  if not it then f.tex:SetDesaturated(true);f.tex:SetAlpha(0.5) end
  return f
end
local function ornament(y,x,w)
  U.picture(ART.."loot-ornament.tga",x or 12,y,w or U.W-24,22)
end
local function sectionTitle(label,y)
  local h=U.T(ns.plain(label),12,y,U.W-24,"head",C.gold)
  U.rect(12,y+h+6,U.W-24,1,C.edgeSoft,"border")
  return h+16
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
local function choose(ref,source,page)
  selected=ref;sourceOffset=0;expandedSource=source;preferredSource=source
  detailSection=page or (source and "Sources" or "Overview");message=nil
  if section=="Upgrades" then view="detail" end
  refresh(true)
end
local function resetResults() offset=0;selected=nil;browseItem=nil;refresh(true) end
local function slotTitle()
  for _,s in ipairs(SLOTS) do if s[3]==filters.slot then return s[2] end end
  return "Gear"
end
local function chooseSlot(n,key)
  slotNumber=n;filters.slot=key;offset=0;selected=nil;browseItem=nil
  view="list";picker=nil;message=nil;refresh(true)
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
  U.surface(x,y,w,36,C.btnOff,C.edgeSoft)
  local art=it and it.icon or ("Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[n] or "Chest"))
  itemIcon(it,x+5,y+4,28,label,equippedName(it,ctx.snapshot.equipmentKnown),art)
  line(label,x+40,y+3,w-46,"small",C.dim)
  line(equippedName(it,ctx.snapshot.equipmentKnown),x+40,y+19,w-46,"small",it and quality(it.quality) or C.dim)
  local b=action(x,y,w,36,label,"Find upgrades for this slot.",function() chooseSlot(n,slotKey(n,ctx)) end,"Browse "..label)
  if it then itemTip(b,it,"Select to browse upgrades for "..label..".") end
end
local function character(y,ctx)
  y=text("Your equipment",y,"head",C.gold)
  y=text("Select a gear slot to browse upgrades and where to get them.",y,"small",C.dim)
  local top=y
  U.surface(188,top,192,266,C.panel,C.edge)
  U.picture(ART.."loot-stage.tga",190,top+2,188,262)
  if not U.playerDoll(192,top+4,184,258,not ctx.preview) then
    -- A neutral silhouette keeps slot navigation useful without optional model APIs.
    local c={0.28,0.33,0.32,1}
    U.rect(271,top+30,26,30,c);U.rect(247,top+66,74,22,c)
    U.rect(260,top+84,48,58,c);U.rect(243,top+88,13,65,c);U.rect(312,top+88,13,65,c)
    U.rect(261,top+146,19,61,c);U.rect(288,top+146,19,61,c)
    line(ctx.preview and "Planning preview" or "Character preview",196,top+234,176,"small",{0.77,0.73,0.61},"CENTER")
  end
  for i,n in ipairs({1,2,3,15,5,9,10}) do paperSlot(n,4,top+(i-1)*38,180,ctx) end
  for i,n in ipairs({6,7,8,11,12,13,14}) do paperSlot(n,384,top+(i-1)*38,180,ctx) end
  for i,n in ipairs({16,17,18}) do paperSlot(n,4+(i-1)*188,top+274,180,ctx) end
  ornament(top+316)
  return top+342
end

local function baseline(y,ctx)
  local slots={slotNumber}
  if filters.slot=="INVTYPE_FINGER" then slots={11,12} end
  if filters.slot=="INVTYPE_TRINKET" then slots={13,14} end
  local names={}
  for _,n in ipairs(slots) do
    local name=equippedName(ctx.snapshot.slots[n],ctx.snapshot.equipmentKnown)
    names[#names+1]=#slots>1 and (L.slotNames[n]..": "..name) or name
  end
  local current=ctx.snapshot.slots[slotNumber]
  itemIcon(current,26,y+11,24,"Currently equipped",nil,
    "Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[slotNumber] or "Chest"))
  line("Currently equipped",60,y+8,235,"small",C.dim)
  line(table.concat(names,"  /  "),60,y+24,476,"body",current and quality(current.quality) or C.light)
  local equipped=action(12,y,544,47,"Currently equipped",ns.plain(table.concat(names,"\n")))
  if current and #slots==1 then itemTip(equipped,current) end
end

local function resetFilters()
  filters={slot=filters.slot,source="all",style="all",search=""}
  picker=nil
  resetResults()
end

local function returnToList()
  view="list";picker=nil;message=nil
  refresh(true)
end

local function slotPicker(y)
  line("Choose a gear slot",16,y+3,354,"head",C.gold)
  button("Back to results",418,y,138,returnToList)
  y=y+36
  local groups={
    {label="Armor",indices={1,3,4,5,6,7,8,9,10}},
    {label="Accessories",indices={2,11,12}},
    {label="Weapons",indices={13,14,15,16}},
  }
  for g,group in ipairs(groups) do
    local x=12+(g-1)*184
    U.surface(x,y,176,310,C.panel,C.edgeSoft)
    line(group.label,x+12,y+12,150,"body",C.gold)
    for i,index in ipairs(group.indices) do
      local n,label,key=unpack(SLOTS[index])
      local isSelected=filters.slot==key
      local yy=y+40+(i-1)*28
      if isSelected then U.surface(x+5,yy,166,25,C.btnOn,C.accent) end
      itemIcon(nil,x+12,yy+4,17,label,nil,"Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[n] or "Chest"))
      line(label,x+40,yy+5,120,"body",isSelected and C.light or C.dim)
      action(x+5,yy,166,25,label,"Browse this equipment slot.",function() chooseSlot(n,key) end,"Slot "..label)
    end
  end
  return y+318
end

local function filterPage(y,ctx)
  line("Filter upgrades",16,y+3,350,"head",C.gold)
  button("Show results",416,y,140,returnToList,true)
  y=y+38
  local showSources=picker=="source"
  U.surface(12,y,544,62,C.panel,C.edgeSoft)
  line("Acquisition source",26,y+23,226,"body",C.light)
  button(L.sourceNames[filters.source] or "All sources",332,y+19,208,function()
    if showSources then picker=nil else picker="source" end
    refresh(true)
  end,showSources,"Choose a source type.")
  y=y+70
  if showSources then
    local h=math.ceil(#SOURCES/3)*31+16
    U.surface(12,y,544,h,C.panel,C.edgeSoft)
    for i,key in ipairs(SOURCES) do
      local x=21+(i-1)%3*179
      local yy=y+8+math.floor((i-1)/3)*31
      button(L.sourceNames[key] or "Any source",x,yy,168,function()
        filters.source=key;picker=nil;resetResults()
      end,filters.source==key)
    end
    return y+h+8
  end

  U.surface(12,y,544,67,C.panel,C.edgeSoft)
  line("Play style",26,y+10,200,"body",C.light)
  for i,key in ipairs({"all","solo","group","buy"}) do
    button(STYLES[key],26+(i-1)*129,y+35,122,function()
      filters.style=key;resetResults()
    end,filters.style==key)
  end
  y=y+75
  U.surface(12,y,544,70,C.panel,C.edgeSoft)
  for i,e in ipairs({{"Zone","LootZone","zone"},{"Dungeon","LootDungeon","dungeon"},{"Profession","LootProfession","profession"}}) do
    local label,entry,field=unpack(e)
    local x=26+(i-1)*174
    line(label,x,y+10,160,"body",C.light)
    U.entry(entry,x,y+36,155,filters[field] or "",function(v)
      filters[field]=field=="profession" and v:upper() or v
    end,resetResults,80)
  end
  y=y+78
  U.surface(12,y,544,69,C.panel,C.edgeSoft)
  line("Available by level",26,y+11,139,"body",C.light)
  button("-",157,y+7,26,function()
    filters.maxLevel=math.max(1,(filters.maxLevel or ctx.level)-5);resetResults()
  end)
  line(tostring(filters.maxLevel or ctx.level),191,y+11,29,"small",C.light,"CENTER")
  button("+",228,y+7,26,function()
    filters.maxLevel=math.min(60,(filters.maxLevel or ctx.level)+5);resetResults()
  end)
  button(filters.showIneligible and "Ineligible: shown" or "Ineligible: hidden",332,y+7,208,function()
    filters.showIneligible=not filters.showIneligible;resetResults()
  end,filters.showIneligible)
  line("Plan level filters availability. Scores use the current character.",26,y+42,508,"small",C.dim)
  y=y+77
  button("Reset filters",12,y,152,resetFilters)
  button(filters.sort=="acquisition" and "Sort: Access" or "Sort: Power",184,y,176,function()
    if filters.sort=="acquisition" then filters.sort=nil else filters.sort="acquisition" end
    resetResults()
  end)
  return y+30
end

local function filterSummary(ctx)
  local tags={}
  if filters.source~="all" then tags[#tags+1]=L.sourceNames[filters.source] or filters.source end
  if filters.style~="all" then tags[#tags+1]=STYLES[filters.style] end
  for _,key in ipairs({"zone","dungeon","profession"}) do
    if filters[key] and filters[key]~="" then
      tags[#tags+1]=key:sub(1,1):upper()..key:sub(2)..": "..filters[key]
    end
  end
  if filters.showIneligible then tags[#tags+1]="Includes ineligible" end
  if filters.maxLevel and filters.maxLevel~=ctx.level then tags[#tags+1]="By level "..filters.maxLevel end
  if filters.sort=="acquisition" then tags[#tags+1]="Sorted by access" end
  return tags
end

local function sourceSummary(row)
  local s=row.sources[1]
  if not s then return "Source unverified",row.item.tradable and "Tradable" or "" end
  local name=s.dungeon or s.zone or s.profession or s.name or ""
  if name==s.profession then name=name:sub(1,1)..name:sub(2):lower() end
  local source=L.sourceNames[s.type] or s.type
  return source..(#row.sources>1 and (" +"..(#row.sources-1)) or ""),name
end

local function previewItem(y,row,ctx)
  local top=y
  local x,w=SIDE,WIDTH-SIDE-12
  local item=L.item(row.item.id) or row.item
  local r=L.compare(item,ctx)
  line("Selected item",x+14,y+12,w-28,"small",C.dim)
  itemIcon(item,x+14,y+37,46,item.name,r.reason)
  local nameBottom=text(item.name,y+36,"body",quality(item.quality),x+72,w-86)
  local imageHit=action(x+10,y+32,w-20,56,item.name,r.reason)
  itemTip(imageHit,item,r.reason)
  y=math.max(y+99,nameBottom+10)
  local score=r.confidence=="complete" and r.percent
  local color=verdictColor(r.verdict)
  U.rect(x+14,y,w-28,28,C.btnOff)
  line(L.labels[r.verdict] or r.verdict,x+24,y+7,w-48,"body",color)
  if score then line(string.format("%+.1f%%",score),x+164,y+7,w-188,"body",color,"RIGHT") end
  y=text(r.reason,y+39,"small",C.dim,x+14,w-28)
  local source,where=sourceSummary(row)
  local route=row.sources[1]
  U.rect(x+14,y+4,w-28,1,C.edgeSoft,"border")
  line("Where to get it",x+14,y+16,w-28,"small",C.dim)
  line(source,x+14,y+35,w-28,"body",C.gold)
  if where~="" then line(where,x+14,y+54,w-28,"small",C.dim) end
  y=y+81
  button("Full comparison",x+14,y,w-28,function() choose(item.id) end)
  button("View sources",x+14,y+29,w-28,function()
    choose(item.id,route and route.id,"Sources")
  end,route~=nil)
  button("Track this item",x+14,y+58,w-28,function()
    local key,err=L.track(item.key)
    message=err or (key and "Target tracked")
    refresh()
  end)
  U.surface(x,top,w,y+92-top,C.panel,C.edgeSoft)
  return y+92
end

local function browse(y,ctx)
  local top=y
  local back=button("< Equipment",12,y,106,function() view="character";selected=nil;refresh(true) end)
  back.codexLabel,back.tipTitle="Back to character","Back to character"
  line(slotTitle().." upgrades",132,y+1,272,"head",C.gold)
  button("Change slot",418,y,138,function() view="slots";refresh(true) end)
  y=y+30
  U.surface(12,y,544,47,C.panel,C.edgeSoft)
  baseline(y,ctx)
  y=y+56

  local tags=filterSummary(ctx)
  U.entry("LootSearch",17,y,335,filters.search,function(v) filters.search=v end,resetResults,80)
  button("Search",361,y,76,resetResults,false,"Search by item name or ID.")
  local filterLabel=#tags>0 and ("Filters ("..#tags..")") or "Filters"
  local filter=button(filterLabel,449,y,107,function() view="filters";refresh(true) end,#tags>0)
  filter.codexLabel="Filters"
  y=y+29

  local page=L.candidates(filters,ctx,offset,PAGE)
  if offset>0 and offset>=page.total then
    offset=math.max(0,math.floor((page.total-1)/PAGE)*PAGE)
    page=L.candidates(filters,ctx,offset,PAGE)
  end
  line(page.total.." matching items",16,y,139,"small",C.dim)
  if #tags>0 then
    local summary=table.concat(tags,"  /  ")
    line(summary,160,y,392,"small",C.dim,"RIGHT")
    action(160,y-2,392,18,"Active filters",ns.plain(summary))
  end
  y=y+18
  if page.total==0 then
    U.surface(12,y,544,90,C.panel,C.edgeSoft)
    text("No matching items",y+14,"body",C.gold,24,512)
    text("Try a different search or clear your filters.",y+41,"small",C.dim,24,512)
    button("Clear search and filters",312,y+56,220,resetFilters)
    U.surface(SIDE,top,WIDTH-SIDE-12,124,C.panel,C.edgeSoft)
    text("Item preview",top+16,"head",C.gold,SIDE+14,246)
    text("Choose a result to see how it compares and where to get it.",top+49,"body",C.dim,SIDE+14,246)
    return math.max(y+102,top+124)
  end

  local current=page.rows[1]
  for _,row in ipairs(page.rows) do
    if row.item.id==browseItem then current=row;break end
  end
  U.rect(12,y,544,23,C.panel)
  line("Item",24,y+4,188,"small",C.dim)
  line("Where to get it",273,y+4,144,"small",C.dim)
  line("Comparison",460,y+4,87,"small",C.dim,"CENTER")
  y=y+25
  for i,row in ipairs(page.rows) do
    local it,r=row.item,row.result
    local on=current==row
    U.rect(12,y,544,43,on and C.btnOn or (i%2==0 and C.panel or C.btnOff))
    if on then U.rect(12,y,3,43,C.accent,"border",1) end
    U.rect(12,y+42,544,1,C.edgeSoft,"border")
    itemIcon(it,21,y+6,30,it.name,r.reason)
    line(it.name,62,y+13,196,"body",quality(it.quality))
    local source,where=sourceSummary(row)
    local route=row.sources[1]
    local sourceIcon=route and SOURCE_ICONS[route.type]
    if sourceIcon then U.icon(sourceIcon,273,y+14,14,source,where) end
    local sourceX=sourceIcon and 295 or 273
    line(source,sourceX,y+5,434-sourceX,"small",route and C.gold or C.dim)
    if where~="" then line(where,sourceX,y+22,434-sourceX,"small",C.dim) end
    local b=action(12,y,544,43,it.name,r.reason,function()
      browseItem=it.id;message=nil;refresh()
    end,"Inspect item "..it.id)
    b.codexOn=on
    itemTip(b,it,r.reason)
    if route then
      line(">",435,y+13,12,"body",C.accent)
      local shortcut=action(264,y,185,43,source.." / "..where,"Open this acquisition source.",
        function() browseItem=it.id;choose(it.id,route.id) end,"Sources for item "..it.id)
      shortcut:SetFrameLevel(b:GetFrameLevel()+1)
    end
    local verdict=row.futureLevel and "Later level" or L.labels[r.verdict] or r.verdict
    local color=row.futureLevel and C.dim or verdictColor(r.verdict)
    line(verdict,452,y+5,99,"small",color,"CENTER")
    local gain=row.futureLevel and ("Level "..row.futureLevel) or
      (r.confidence=="complete" and r.percent and string.format("%+.1f%%",r.percent))
      or (r.verdict=="upgrade" and "Empty slot" or nil)
    if gain then line(gain,452,y+22,99,"small",C.dim,"CENTER") end
    y=y+46
  end
  y=y+5
  if offset>0 then button("Previous loot page",12,y,138,function() offset=math.max(0,offset-PAGE);refresh(true) end) end
  line("Page "..(math.floor(offset/PAGE)+1).." of "..math.ceil(page.total/PAGE),165,y+5,238,"small",C.dim,"CENTER")
  if offset+PAGE<page.total then button("Next loot page",418,y,138,function() offset=offset+PAGE;refresh(true) end) end
  return math.max(y+27,previewItem(top,current,ctx))
end

local function number(n)
  return math.abs(n-math.floor(n))<0.001 and string.format("%.0f",n) or string.format("%.1f",n)
end
local function statsReadable(it,r,ctx)
  if not (it.complete and it.complete.stats and ctx.snapshot.equipmentKnown and #r.replacedSlots>0) then return false end
  for _,n in ipairs(r.replacedSlots) do
    local before=ctx.snapshot.slots[n]
    local twoHand=n==17 and ctx.snapshot.slots[16] and ctx.snapshot.slots[16].slot=="INVTYPE_2HWEAPON"
    if before==nil and not twoHand then return false end
  end
  for _,old in ipairs(r.baseline) do if not (old.complete and old.complete.stats) then return false end end
  return true
end
local function statOverview(it,r,y,ctx)
  y=text(r.reason,y,"small",r.verdict=="downgrade" and C.loss or C.dim)
  local known=statsReadable(it,r,ctx)
  U.surface(4,y,U.W-8,78,C.panel,C.edgeSoft)
  line("Replacing",16,y+10,246,"small",C.dim)
  if #r.baseline>0 then
    for i,old in ipairs(r.baseline) do
      itemIcon(old,16,y+29+(i-1)*23,19,old.name,nil)
      line(old.name,44,y+31+(i-1)*23,244,"small",quality(old.quality))
      local b=action(12,y+27+(i-1)*23,278,23,old.name,nil,nil,"Equipped comparison "..i)
      itemTip(b,old)
    end
  else line(known and "Empty slot" or "Baseline not verified",16,y+36,260,"body",C.dim) end
  line("Estimated gear score",310,y+10,236,"small",C.gold)
  if r.confidence=="complete" and r.score and r.baselineScore then
    local scale=math.max(1,math.abs(r.score),math.abs(r.baselineScore))
    line("Before "..number(r.baselineScore),310,y+31,112,"small",C.dim)
    line("With item "..number(r.score),428,y+31,120,"small",r.delta>=0 and C.green or C.loss)
    U.rect(310,y+55,108,7,C.edgeSoft,"border",1);U.rect(428,y+55,108,7,C.edgeSoft,"border",1)
    if r.baselineScore>0 then U.rect(310,y+55,108*r.baselineScore/scale,7,C.dim,"border",2) end
    if r.score>0 then U.rect(428,y+55,108*r.score/scale,7,r.delta>=0 and C.green or C.loss,"border",2) end
  else
    line("Score not verified",310,y+33,236,"body",C.dim)
    line("Review the notes before replacing.",310,y+57,236,"small",C.dim)
  end
  y=y+90
  if not known then
    U.surface(4,y,U.W-8,58,C.btnOff,C.edgeSoft)
    line("Stat comparison unavailable",16,y+10,U.W-32,"body",C.gold)
    local explanation=r.verdict=="cannotEquip" and "This item has no legal replacement in the current setup."
      or "Verified stats are needed for the item and the gear it replaces."
    y=text(explanation,y+32,"small",C.dim)
    y=y+10
  else
    local keys={};for k,n in pairs(r.statDelta) do if n~=0 then keys[#keys+1]=k end end;table.sort(keys)
    if #keys>0 then
      local top=y;y=y+sectionTitle("Stat changes",y)
      line("Each pair has its own scale.",300,top+4,256,"small",C.dim,"RIGHT")
      for i,k in ipairs(keys) do
        local before=0;for _,old in ipairs(r.baseline) do before=before+(old.stats[k] or 0) end
        local after=before+r.statDelta[k];local scale=math.max(1,math.abs(before),math.abs(after))
        local x,yy=12+(i-1)%2*278,y+math.floor((i-1)/2)*66
        local delta=r.statDelta[k];local color=delta>0 and C.green or C.loss
        U.surface(x,yy,266,60,C.btnOff,C.edgeSoft)
        line(STAT_NAMES[k] or k,x+12,yy+8,172,"body",C.light)
        line((delta>0 and "+" or "")..number(delta),x+188,yy+8,66,"body",color,"RIGHT")
        line("Equipped: "..number(before),x+12,yy+29,115,"small",C.dim)
        line("New: "..number(after),x+141,yy+29,113,"small",color)
        U.rect(x+12,yy+47,113,6,C.edgeSoft,"border",1);U.rect(x+141,yy+47,113,6,C.edgeSoft,"border",1)
        if before>0 then U.rect(x+12,yy+47,113*before/scale,6,C.dim,"border",2) end
        if after>0 then U.rect(x+141,yy+47,113*after/scale,6,color,"border",2) end
        local tip="Equipped: "..number(before).."\nNew: "..number(after).."\nChange: "..(delta>0 and "+" or "")..number(delta).."\nBars compare values for this stat only."
        action(x,yy,266,60,(STAT_NAMES[k] or k).." comparison",tip,nil,(STAT_NAMES[k] or k).." comparison")
      end
      y=y+math.ceil(#keys/2)*66+6
    else y=text("No numerical stat changes. Review the item's effects.",y,"small",C.dim) end
  end
  if #r.warnings>0 then
    y=y+8;y=y+sectionTitle("Check before replacing",y)
    for _,warning in ipairs(r.warnings) do y=text(warning,y,"small",C.gold) end
  end
  return y
end
local function acquisition(it,y,ctx)
  local sources=L.sources(it.id,nil,ctx)
  -- Keep the route that the player opened first, with all other routes still available.
  if preferredSource then
    for i,s in ipairs(sources) do
      if s.id==preferredSource then table.remove(sources,i);table.insert(sources,1,s);break end
    end
  end
  if #sources==0 then
    U.surface(4,y,U.W-8,112,C.panel,C.edgeSoft)
    U.icon("inv_misc_map_01",22,y+24,48,"Acquisition source","Verified source information is not available.")
    local bottom=text("Source not verified",y+19,"head",C.gold,86,U.W-110)
    y=text("No verified acquisition source in this catalog. Check the item in game.",bottom,"body",C.dim,86,U.W-110)+20
  end
  if sourceOffset>=#sources then sourceOffset=0 end
  for i=sourceOffset+1,math.min(#sources,sourceOffset+2) do
    local s=sources[i];local top=y;local open=expandedSource==s.id
    U.icon(SOURCE_ICONS[s.type] or "inv_misc_map_01",16,y+12,32,L.sourceNames[s.type] or s.type,s.name)
    line((L.sourceNames[s.type] or s.type)..": "..(s.name or "Unknown source"),62,y+10,U.W-176,"body",C.gold)
    local place=s.dungeon or s.zone or (s.profession and (s.profession:sub(1,1)..s.profession:sub(2):lower())) or "Location unverified"
    if s.requiredLevel and s.requiredLevel>0 then place=place.." / Level "..s.requiredLevel end
    line(place,62,y+32,U.W-146,"small",C.dim)
    line(open and "- Details" or "+ Details",U.W-104,y+13,88,"small",C.dim,"RIGHT")
    local b=action(4,y,U.W-8,50,s.name,"Show source requirements, costs and materials.",function()
      if expandedSource==s.id then expandedSource=nil else expandedSource=s.id end;refresh()
    end,"Source details "..i);b.codexOn=open
    y=y+54
    if open then
      if s.requiredLevel and s.requiredLevel>0 then y=text("Source requires level "..s.requiredLevel,y,"small",C.dim) end
      if s.giverName then y=text("Starts with "..s.giverName,y,"small",C.dim) end
      if s.locationKind=="entrance" then y=text("Map location: dungeon entrance, not the boss room.",y,"small",C.dim) end
      if s.prerequisites and #s.prerequisites>0 then y=text("Prerequisite quests: "..table.concat(s.prerequisites,", "),y,"small",C.dim) end
      if s.cost then y=text("Cost: "..(ns.money and ns.money(s.cost) or tostring(s.cost)),y,"small") end
      if s.materials then
        local mats={};for name,n in pairs(s.materials) do mats[#mats+1]=n.." "..name end;table.sort(mats)
        y=text("Materials: "..table.concat(mats,", "),y,"small")
      end
    end
    y=text(s.evidence=="client" and "Client reference" or "Database reference; server availability may vary",y,"small",C.dim)
    button("Track source "..i,16,y,160,function() local key,err=L.track(it.key,s.id);message=err or (key and "Source tracked");refresh() end)
    if s.map and L.showSourceOnMap then button("Map source "..i,186,y,160,function() local _,why=L.showSourceOnMap(s.id);message=why;refresh() end)
    else line("Location not verified",186,y+4,160,"small",C.dim) end
    if s.quest and L.openQuestSource then button("Quest guide "..i,356,y,196,function() L.openQuestSource(s.quest) end) end
    y=y+32;U.surface(4,top,U.W-8,y-top,C.panel,open and C.edge or C.edgeSoft);y=y+10
  end
  if #sources>2 then
    button("More sources",12,y,160,function() sourceOffset=sourceOffset+2;if sourceOffset>=#sources then sourceOffset=0 end;expandedSource=nil;refresh(true) end)
    line((sourceOffset+1).."-"..math.min(#sources,sourceOffset+2).." of "..#sources.." sources",184,y+4,240,"small",C.dim);y=y+32
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
    U.surface(0,top,U.W,y-top+6,C.panel,C.edgeSoft);y=y+18
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
  itemIcon(it,16,y+16,40,it.name,r.reason)
  line(it.name,68,y+13,300,"head",quality(it.quality))
  local pct=r.confidence=="complete" and r.percent and string.format(" (%+.1f%% estimated gear score)",r.percent) or ""
  U.T(ns.plain((L.labels[r.verdict] or r.verdict)..pct),68,y+41,300,"small",verdictColor(r.verdict))
  local header=action(4,top,370,76,it.name,r.reason,nil,"Item comparison");itemTip(header,it,r.reason)
  button("Track this item",384,y+14,170,function() local key,err=L.track(it.key);message=err or (key and "Target tracked");refresh() end)
  if section=="Upgrades" then
    button("Compare this item",384,y+42,170,function() input=it.key;section="Compare";selected=it.key;refresh(true) end)
  end
  U.surface(4,top,U.W-8,76,C.panel,C.edgeSoft);y=y+88
  for i,label in ipairs({"Overview","Sources","Enchants"}) do
    local b=button(label=="Sources" and "Where to get it" or label,4+(i-1)*188,y,180,function() detailSection=label;refresh(true) end,detailSection==label)
    b.codexLabel=label
  end
  y=y+32
  if detailSection=="Sources" then return acquisition(it,y,ctx)
  elseif detailSection=="Enchants" then return enchantOptions(it,y,ctx) end
  return statOverview(it,r,y,ctx)
end

local function compare(y,ctx)
  local function submit()
    local key=L.itemKey(input);message=not key and "Enter a valid item link or item ID." or nil
    if key then choose(key) else selected=nil;refresh() end
  end
  local entryY=y+8
  if selected then
    U.surface(4,y,U.W-8,62,C.btnOff,C.edgeSoft)
  else
    U.surface(4,y,U.W-8,98,C.btnOff,C.edgeSoft)
    U.icon("inv_misc_gem_opal_01",18,y+21,32,"Compare equipment","Paste a link or choose your equipment below.")
    line("Check an item",64,y+8,180,"head",C.gold)
    line("Paste an item link or item ID",268,y+12,280,"small",C.dim,"RIGHT")
    entryY=y+34
  end
  local entryX=selected and 14 or 64
  U.entry("LootItem",entryX,entryY,U.W-154-entryX,input or "",function(v) input=v end,submit,2048)
  button("Check item",U.W-142,entryY,130,submit)
  button(planning and "Hide planning" or "Planning options",14,entryY+27,164,function() planning=not planning;refresh() end,planning)
  button("Live character",190,entryY+27,166,function() preview=nil;refresh() end,not ctx.preview)
  button("Gear / bags",368,entryY+27,186,function() selected=nil;input=nil;refresh(true) end)
  y=y+(selected and 72 or 110)
  if planning then
    U.surface(0,y,U.W,144,C.panel,C.edgeSoft)
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
  line("Choose equipment",12,y+3,245,"head",C.gold)
  for i,label in ipairs({"Equipped","Bags"}) do
    button(label,316+(i-1)*122,y,116,function() inventoryMode=label;inventoryPage=0;refresh(true) end,inventoryMode==label)
  end
  y=y+32
  for i,label in ipairs({"Armor","Accessories","Weapons"}) do
    button(label,12+(i-1)*184,y,176,function() inventoryGroup=label;inventoryPage=0;refresh() end,inventoryGroup==label)
  end
  y=y+30
  local snapshot=L.snapshot()
  local items={}
  local function append(it,n,label)
    if not it then return end
    local location=n or L.slotsFor(it.slot)[1]
    local group=(it.classID==2 or location and location>=16) and "Weapons"
      or (location==2 or location==11 or location==12 or location==13 or location==14) and "Accessories" or "Armor"
    if group==inventoryGroup then items[#items+1]={item=it,slot=n,label=label} end
  end
  if inventoryMode=="Equipped" then
    for _,n in ipairs(L.slotOrder) do local it=snapshot.slots[n];if it then append(it,n,L.slotNames[n]..": "..it.name) end end
  else
    local keys={};for key in pairs(snapshot.bagLinks) do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys) do
      local it=L.item(key)
      if it and (it.classID==2 or it.classID==4 or not it.classID) then append(it,nil,"Bag: "..it.name) end
    end
  end
  if inventoryPage*6>=#items then inventoryPage=math.max(0,math.ceil(#items/6)-1) end
  if #items==0 then
    U.surface(12,y,U.W-24,116,C.panel,C.edgeSoft)
    U.icon(inventoryGroup=="Weapons" and "inv_sword_04" or "inv_misc_bag_10",38,y+27,52,"Equipment",nil)
    local title=inventoryMode=="Bags" and (snapshot.bagsKnown and "No bag equipment" or "Bag items unavailable") or ("No equipped "..inventoryGroup:lower())
    text(title,y+24,"body",C.gold,108,U.W-132)
    text("Choose another group or paste an item link above.",y+53,"small",C.dim,108,U.W-132)
    return y+130
  end
  for i=inventoryPage*6+1,math.min(#items,inventoryPage*6+6) do
    local row=items[i];local it=row.item;local ix=(i-1)%6
    local x,yy=12+(ix%2)*278,y+math.floor(ix/2)*58
    U.surface(x,yy,266,52,C.btnOff,C.edgeSoft)
    itemIcon(it,x+8,yy+10,32,it.name,"Select to compare with your gear.")
    line(row.slot and L.slotNames[row.slot] or ("Bag / requires level "..tostring(it.requiredLevel or 0)),x+50,yy+6,202,"small",C.dim)
    line(it.name,x+50,yy+25,202,"small",quality(it.quality))
    local key=it.key
    local b=action(x,yy,266,52,it.name,"Compare with your equipped gear.",function() input=key;choose(key) end,row.label)
    itemTip(b,it)
  end
  y=y+math.ceil(math.min(6,#items-inventoryPage*6)/2)*58+6
  if inventoryPage>0 then button("Previous items",12,y,132,function() inventoryPage=inventoryPage-1;refresh(true) end) end
  line("Page "..(inventoryPage+1).." of "..math.ceil(#items/6),168,y+4,232,"small",C.dim,"CENTER")
  if (inventoryPage+1)*6<#items then button("Next items",424,y,132,function() inventoryPage=inventoryPage+1;refresh(true) end) end
  return y+30
end
local function tracked(y)
  y=text("Your upgrade targets",y,"head",C.gold)
  local all=L.targets()
  if #all==0 then
    U.surface(12,y,544,134,C.panel,C.edgeSoft)
    U.icon("inv_misc_bag_10",28,y+23,42,"Loot targets",nil)
    line("No saved upgrades",86,y+18,452,"head",C.gold)
    text("Track an item or a specific source to add it here and to your floating tracker.",y+45,"body",C.dim,86,446)
    button("Browse upgrades",86,y+95,210,function() section="Upgrades";view="character";selected=nil;refresh(true) end,true)
    button("Compare an item",306,y+95,226,function() section="Compare";selected=nil;input=nil;refresh(true) end)
    return y+146
  end
  for i,label in ipairs({"All","Active","Obtained","Dismissed"}) do
    local key=label=="Active" and "tracked" or label:lower()
    button(label,12+(i-1)*139,y,133,function() targetFilter=key;targetPage=0;refresh(true) end,targetFilter==key)
  end
  y=y+34
  local list=targetFilter=="all" and all or L.targets(targetFilter)
  if targetPage*3>=#list then targetPage=math.max(0,math.ceil(#list/3)-1) end
  if #list==0 then return text("No targets in this group. Choose All to see your other targets.",y+20,"body",C.dim) end
  for i=targetPage*3+1,math.min(#list,targetPage*3+3) do
    local t=list[i];local it=L.item(t.ref)
    U.surface(4,y,U.W-8,92,C.btnOff,C.edgeSoft)
    itemIcon(it,16,y+12,36,t.name,t.state)
    line(t.name,64,y+10,U.W-194,"body",it and quality(it.quality) or C.light)
    U.surface(U.W-114,y+10,98,20,C.panel,C.edgeSoft)
    line(t.state,U.W-110,y+13,90,"small",C.dim,"CENTER")
    local sources=L.sources(t.id);local source
    for _,s in ipairs(sources) do if s.id==t.sourceID then source=s;break end end
    line(source and ((L.sourceNames[source.type] or source.type)..": "..(source.name or "Unknown source")) or "Choose a source in the item details",64,y+34,U.W-82,"small",C.dim)
    local b=action(4,y,U.W-8,54,t.name,"Open this target's item details.",function() section="Compare";input=t.ref;choose(t.ref) end,t.name.." - "..t.state)
    if it then itemTip(b,it) end
    button(t.state=="tracked" and "Dismiss" or "Restore",64,y+61,120,function() L.setTargetState(t.key,t.state=="tracked" and "dismissed" or "tracked");refresh() end)
    button("Untrack",194,y+61,120,function() L.untrack(t.key);refresh() end)
    if t.sourceID and L.showSourceOnMap then button("Map "..t.name,324,y+61,U.W-340,function() local _,why=L.showSourceOnMap(t.sourceID);message=why;refresh() end) end
    y=y+104
  end
  if targetPage>0 then button("Previous targets",12,y,150,function() targetPage=targetPage-1;refresh(true) end) end
  line("Page "..(targetPage+1).." of "..math.ceil(#list/3),180,y+4,208,"small",C.dim,"CENTER")
  if (targetPage+1)*3<#list then button("Next targets",406,y,150,function() targetPage=targetPage+1;refresh(true) end) end
  return y+32
end
local function profiles(y,ctx)
  local p=ctx.profile
  if sharing then
    button("Back to profiles",12,y,170,function() sharing=false;refresh(true) end);y=y+34
    y=text("Share your priorities",y,"head",C.gold)
    y=text("Copy this code to share a profile, or paste a code and choose Import.",y,"small",C.dim)
    U.surface(4,y,U.W-8,114,C.btnOff,C.edgeSoft)
    U.icon("inv_misc_book_09",18,y+18,38,"Profile code","A profile changes loot scoring only.")
    line("Profile code",70,y+14,U.W-88,"body",C.gold)
    U.entry("LootProfileCode",70,y+38,U.W-92,code or "",function(v) code=v end,function(v)
      local ok,err=L.readProfileCode(v);message=ok and "Profile imported" or err;editor=nil;refresh()
    end,4096)
    button("Export profile",70,y+76,220,function() code=L.profileCode();refresh() end)
    button("Import profile",302,y+76,244,function() local ok,err=L.readProfileCode(code or "");message=ok and "Profile imported" or err;refresh() end)
    ornament(y+132)
    return y+164
  end
  if editor then
    button("Back to profiles",12,y,170,function() editor=nil;refresh(true) end)
    local function save()
      for k,v in pairs(editor.weights) do editor.weights[k]=tonumber(v) or -1 end
      for _,k in ipairs({"melee","ranged","speed"}) do editor.weapon[k]=tonumber(editor.weapon[k]) or 0 end
      local ok,err=L.setProfile(editor);message=ok and "Custom weights saved" or err;if ok then editor=nil end;refresh(true)
    end
    button("Save weights",U.W-182,y,170,save);y=y+36
    y=text("Custom scoring weights",y,"head",C.gold)
    y=text("Higher weights give a stat more value. These are gear scores, not damage percentages.",y,"small",C.dim)
    local keys={};for k in pairs(L.profileStatKeys) do keys[#keys+1]=k end;table.sort(keys)
    for i,k in ipairs(keys) do
      local x,yy=12+(i-1)%2*278,y+math.floor((i-1)/2)*32
      U.surface(x,yy,266,28,C.btnOff,C.edgeSoft)
      line(STAT_NAMES[k] or k,x+8,yy+7,146,"small",C.dim)
      U.entry("LootWeight"..k,x+164,yy+3,88,tostring(editor.weights[k] or 0),function(v) editor.weights[k]=v end,nil,16)
    end
    y=y+math.ceil(#keys/2)*32+18
    y=text("Weapon priorities",y,"head",C.gold)
    for _,k in ipairs({"melee","ranged","speed"}) do
      line("Weapon "..k,12,y+4,210,"small",C.dim)
      U.entry("LootWeapon"..k,230,y,170,tostring(editor.weapon[k] or 0),function(v) editor.weapon[k]=v end,nil,16);y=y+28
    end
    button(editor.weapon.feral and "Feral policy: on" or "Feral policy: off",12,y,260,function() editor.weapon.feral=not editor.weapon.feral;refresh() end)
    return y+34
  end
  y=text("Choose your priorities",y,"head",C.gold)
  y=text("Pick the role you are gearing for. Your talent guide stays the same.",y,"small",C.dim)
  U.surface(4,y,U.W-8,64,C.panel,C.edgeSoft)
  U.icon("inv_misc_book_11",18,y+13,36,"Scoring profile",p.label)
  local automatic=not ns.charDB().lootProfile and not ns.charDB().lootProfileKey and not (preview and preview.profileKey)
  line(automatic and "Following your talent path" or "Manual loot profile",66,y+10,294,"small",C.dim)
  line(p.label,66,y+29,294,"head",C.gold)
  button("Follow talent path",376,y+22,176,function()
    L.resetProfile();if preview then preview.profileKey=nil end;editor=nil;refresh()
  end,automatic)
  y=y+78
  local paths=(ns.TALENT_PATHS or {})[ctx.class] or {}
  local n=math.max(1,#paths);local w=math.floor((U.W-24-(n-1)*12)/n)
  for i,p0 in ipairs(paths) do
    local x=12+(i-1)*(w+12);local on=p0.key==p.key
    U.surface(x,y,w,122,on and C.btnOn or C.btnOff,on and C.edge or C.edgeSoft)
    local plan=p0.plan or (ctx.class==select(2,UnitClass("player")) and ns.D and ns.D.plan)
    local art=plan and plan[1] and plan[1].icon or "inv_misc_book_11"
    U.icon(art,x+(w-36)/2,y+12,36,p0.spec,p0.note)
    line(p0.spec,x+8,y+54,w-16,"head",C.gold,"CENTER")
    line(p0.role or "Leveling",x+8,y+79,w-16,"small",C.dim,"CENTER")
    line(on and "ACTIVE PROFILE" or "Choose this role",x+8,y+103,w-16,"small",on and C.light or C.dim,"CENTER")
    local b=action(x,y,w,122,p0.spec,p0.note,function()
      if ctx.preview then preview=preview or {};preview.profileKey=p0.key else L.setProfile(p0.key) end
      editor=nil;refresh()
    end,p0.spec);b.codexOn=on
  end
  y=y+138
  U.surface(12,y,266,76,C.btnOff,C.edgeSoft)
  U.icon("inv_misc_letter_15",22,y+11,28,"Share a profile","Export your priorities or import a friend's code.")
  line("Share a profile",62,y+10,202,"body",C.gold)
  line("Use a code with friends or alts.",62,y+30,202,"small",C.dim)
  button("Export profile",22,y+50,118,function() code=L.profileCode();sharing=true;refresh(true) end)
  button("Import profile",148,y+50,118,function() sharing=true;refresh(true) end)
  U.surface(290,y,266,76,C.btnOff,C.edgeSoft)
  U.icon("trade_engineering",300,y+11,28,"Custom priorities","Tune individual stats and weapon scoring.")
  line("Fine-tune your gear",340,y+10,204,"body",C.gold)
  line("Advanced stat and weapon weights",340,y+30,204,"small",C.dim)
  button("Edit weights",340,y+50,204,function()
    editor={class=ctx.class,label="Custom",weights={},weapon={}}
    for k,v in pairs(p.weights) do editor.weights[k]=v end;for k,v in pairs(p.weapon) do editor.weapon[k]=v end
    refresh(true)
  end)
  return y+88
end
local function workspaceSidebar(y,ctx)
  local x,w=SIDE,WIDTH-SIDE-12
  local top=y
  if section=="Upgrades" and view=="character" then
    y=text("Find your next upgrade",y+14,"head",C.gold,x+14,w-28)
    y=text("Select any equipment slot to see its upgrades. Each result has a preview and acquisition sources.",y+4,"body",C.dim,x+14,w-28)
    button("Browse "..slotTitle().." upgrades",x+14,y+5,w-28,function() chooseSlot(slotNumber,filters.slot) end,true)
    y=y+42
  elseif section=="Upgrades" and view=="filters" then
    y=text(slotTitle().." upgrades",y+14,"head",C.gold,x+14,w-28)
    local tags=filterSummary(ctx)
    y=text("Active filters",y+4,"body",C.light,x+14,w-28)
    y=text(#tags>0 and table.concat(tags,"\n") or "Showing all available sources.",y,"small",C.dim,x+14,w-28)
  else
    y=text("Loot targets",y+14,"head",C.gold,x+14,w-28)
    local count=#L.targets("tracked")
    y=text(count==1 and "1 active target" or (count.." active targets"),y+4,"body",C.dim,x+14,w-28)
    if section~="Tracked" then
      button("Open tracked items",x+14,y+4,w-28,function() section="Tracked";message=nil;refresh(true) end)
      y=y+36
    else
      local enabled=not ns.db().noLootTracker
      button(enabled and "Hide floating tracker" or "Show floating tracker",x+14,y+4,w-28,function()
        ns.db().noLootTracker=enabled or nil
        L.refreshTracker()
        refresh()
      end,enabled)
      y=y+36
    end
  end
  line("Scoring profile",x+14,y+6,w-28,"small",C.dim)
  y=text(ctx.profile.label,y+24,"body",C.gold,x+14,w-28)
  U.surface(x,top,w,y+10-top,C.panel,C.edgeSoft)
  return y+10
end

local function render()
  palette()
  local ctx=context();local p=ctx.profile
  local banner=Theme.eui and C.panel or C.ribbon
  local title=Theme.eui and C.light or {0.99,0.9,0.68}
  local finePrint=Theme.eui and C.dim or {0.84,0.88,0.83}
  U.surface(4,6,WIDTH-8,42,banner,C.edge)
  if not Theme.eui then U.picture(ART.."loot-ribbon.tga",5,7,WIDTH-10,40) end
  U.icon("inv_chest_plate04",14,13,27,"Loot journal","Your equipment, upgrades and acquisition sources.")
  line("Loot",52,14,64,"head",title)
  line((ctx.preview and "Planning: " or "Your gear: ")..ctx.class.." / Level "..ctx.level.." / "..(p and p.label or "No profile"),116,12,U.W-202,"small",title)
  line("Estimated gear score is advisory.",116,29,U.W-202,"small",finePrint)
  local tabArt={"inv_chest_plate04","inv_misc_gem_opal_01","inv_misc_bag_10","inv_misc_book_11"}
  local tabWidth=math.floor((WIDTH-8-3*6)/4)
  for i,label in ipairs({"Upgrades","Compare","Tracked","Profiles"}) do
    local x=4+(i-1)*(tabWidth+6);local on=section==label
    U.surface(x,56,tabWidth,28,on and C.btnOn or C.panel,on and C.accent or C.edgeSoft)
    if on then U.rect(x+5,81,tabWidth-10,2,C.accent,"border",1) end
    U.icon(tabArt[i],x+8,62,16,label,nil)
    line(label,x+32,62,tabWidth-42,"body",on and C.light or C.dim,"CENTER")
    local b=action(x,56,tabWidth,28,label,nil,function() section=label;message=nil;picker=nil;refresh(true) end,label);b.codexOn=on
  end
  local y=96
  if message then y=text(message,y,"small",C.gold) end
  if not p then return text("Loot profiles are not available for this class.",y,"body",C.dim)+20 end
  if L.mapTarget and L.mapTarget() then
    button("Clear loot map target",12,y,260,function() L.clearMapTarget();refresh() end);y=y+32
  end
  local sideBottom
  if not (section=="Upgrades" and view=="list") then sideBottom=workspaceSidebar(y,ctx) end
  if section=="Upgrades" then
    if view=="character" then y=character(y,ctx)
    elseif view=="detail" and selected then y=details(selected,y)
    elseif view=="slots" then y=slotPicker(y)
    elseif view=="filters" then y=filterPage(y,ctx)
    else y=browse(y,ctx) end
  elseif section=="Compare" then y=compare(y,ctx)
  elseif section=="Tracked" then y=tracked(y)
  else y=profiles(y,ctx) end
  local height=math.max(484,y+8,(sideBottom or 0)+8)
  U.folio(height,C.background,WIDTH)
  return height
end
ns.addTab("loot","Loot",render,WIDTH)
function L.open(want,ref,source)
  if want then section=want end
  if ref then
    selected=ref;input=tostring(ref);detailSection=source and "Sources" or "Overview"
    sourceOffset=0;expandedSource=source;preferredSource=source
    if section=="Upgrades" then view="detail" end
  end
  ns.openTab("loot",true)
end
L.subscribe(function() if ns.refreshLootTab then ns.refreshLootTab() end end)
