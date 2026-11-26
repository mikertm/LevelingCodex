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
local filters={slot="INVTYPE_CHEST",style="all",search=""}
local offset,slotNumber=0,5
local input,message,code,editor,preview
local levelDraft,levelError
local planning=false
local upgradeDetail,compareDetail={},{}
local inventoryMode,inventoryPage,inventorySearch="Bags",0,""
local planningFields
local sharing=false
local targetFilter,targetPage="all",0
local PAGE=5
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
local ARMOR_SLOTS={1,3,15,5,9,10,6,7,8}
local ACCESSORY_SLOTS={2,11,12,13,14}
local WEAPON_SLOTS={16,17,18}
local SOURCES={"quest","vendor","craft","dungeonTrash","raidTrash","reputation","creature","rare","world","object","pvp"}
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
  hit="Hit %",crit="Critical strike %",dodge="Dodge %",parry="Parry %",block="Block %",mp5="Mana per 5 sec",
  spellHit="Spell hit %",spellCrit="Spell crit %",spellPen="Spell penetration",blockValue="Block value",
  feralAp="Feral attack power",hp5="Health per 5 sec",weaponDmg="Weapon damage",health="Health",mana="Mana",
  spFire="Fire spell power",spFrost="Frost spell power",spShadow="Shadow spell power",spNature="Nature spell power",
  spArcane="Arcane spell power",spHoly="Holy spell power"}

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
    L.showItemTooltip(self,it.key or it.id)
  end)
  b:SetScript("OnLeave",function(self)
    L.hideItemTooltip(self)
  end)
end
local function setDetail(ref,source,page)
  local detail=section=="Compare" and compareDetail or upgradeDetail
  detail.ref,detail.offset,detail.expanded,detail.source=ref,0,source,source
  detail.page=page or (source and "Sources" or "Overview")
  detail.questStep=nil
  detail.weaponSlot=section=="Upgrades" and filters.weaponSlot or nil
  if section=="Upgrades" then view="detail" end
end
local function choose(ref,source,page)
  setDetail(ref,source,page)
  message=nil
  refresh(true)
end
local function resetResults() offset=0;browseItem=nil;refresh(true) end
local function slotTitle()
  for _,s in ipairs(SLOTS) do if s[3]==filters.slot then return s[2] end end
  return "Gear"
end
local function chooseSlot(n,key)
  if filters.slot~=key then filters.weaponStyle,filters.weaponType=nil,nil end
  slotNumber=n;filters.slot=key;offset=0;browseItem=nil
  view="list";message=nil;refresh(true)
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
  U.surface(x,y,w,29,it and C.btnOff or C.background,C.edgeSoft)
  local art=it and it.icon or ("Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[n] or "Chest"))
  local name=equippedName(it,ctx.snapshot.equipmentKnown)
  itemIcon(it,x+5,y+3,23,label,name,art):EnableMouse(false)
  line(label,x+38,y+1,w-56,"small",C.dim)
  line(name,x+38,y+14,w-56,"small",it and quality(it.quality) or C.dim)
  line(">",x+w-16,y+8,10,"small",C.accent)
  local b=action(x,y,w,29,"Browse "..label,name,function() chooseSlot(n,slotKey(n,ctx)) end,"Browse "..label)
  if it then itemTip(b,it) end
end
local function character(y,ctx)
  line("Your equipment",16,y+1,330,"head",C.gold)
  line("Select a slot to browse upgrades",WIDTH-352,y+7,336,"small",C.dim,"RIGHT")
  local top=y+34
  local left,center,right=12,316,566
  U.surface(left,top,292,330,C.panel,C.edgeSoft)
  U.surface(right,top,292,330,C.panel,C.edgeSoft)
  line("Armor",left+12,top+10,266,"body",C.gold)
  line("Accessories",right+12,top+10,266,"body",C.gold)
  line("Weapons",right+12,top+198,266,"body",C.gold)
  for i,n in ipairs(ARMOR_SLOTS) do paperSlot(n,left+12,top+32+(i-1)*32,268,ctx) end
  for i,n in ipairs(ACCESSORY_SLOTS) do paperSlot(n,right+12,top+32+(i-1)*32,268,ctx) end
  for i,n in ipairs(WEAPON_SLOTS) do paperSlot(n,right+12,top+224+(i-1)*32,268,ctx) end

  U.surface(center,top,238,330,C.panel,C.edgeSoft)
  if not Theme.eui then U.picture(ART.."loot-stage.tga",center+1,top+1,236,249) end
  U.surface(center+47,top+30,144,144,C.background,C.edge)
  U.rect(center+48,top+31,142,142,C.background,nil,3)
  U.playerPortrait(center+54,top+37,130,ctx.class,not ctx.preview)
  local name=not ctx.preview and L.call(UnitName,"player")
  local caption=type(name)=="string" and ns.plain(name)
  line(caption and caption~="" and caption or ctx.profile.label,center+13,top+184,212,"head",C.gold,"CENTER")
  if ctx.snapshot.equipmentKnown then
    local filled=0
    for _,n in ipairs(L.slotOrder) do if ctx.snapshot.slots[n] then filled=filled+1 end end
    line("Equipment slots filled",center+17,top+218,145,"small",C.dim)
    line(filled.." / "..#L.slotOrder,center+168,top+218,54,"small",C.light,"RIGHT")
    U.rect(center+17,top+237,204,5,C.edgeSoft,"border",1)
    if filled>0 then U.rect(center+17,top+237,204*filled/#L.slotOrder,5,C.accent,"border",2) end
  else
    line("Equipment data unavailable",center+17,top+224,204,"small",C.dim,"CENTER")
  end
  U.rect(center+1,top+250,236,1,C.edgeSoft,"border")
  button("Compare an item",center+17,top+259,204,function() section="Compare";message=nil;refresh(true) end,true)
  button("Open tracked items",center+17,top+287,204,function() section="Tracked";message=nil;refresh(true) end)
  return top+340
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
  itemIcon(current,26,y+9,24,"Currently equipped",nil,
    "Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[slotNumber] or "Chest"))
  line("Currently equipped",60,y+5,235,"small",C.dim)
  local weapon=slotNumber>=16 and filters.slot~="INVTYPE_RELIC"
  line(table.concat(names,"  /  "),60,y+20,weapon and 332 or 476,"body",current and quality(current.quality) or C.light)
  local equipped=action(12,y,weapon and 384 or 544,42,"Currently equipped",ns.plain(table.concat(names,"\n")))
  if current and #slots==1 then itemTip(equipped,current) end
end

local function resetFilters()
  filters={slot=filters.slot,style="all",search=""}
  levelDraft,levelError=nil,nil
  resetResults()
end

local function returnToList()
  view="list";message=nil
  refresh(true)
end

local WEAPON_STYLES={
  {"shield","One-hand + shield","Browse one-handed weapons that leave room for a shield."},
  {"twohand","Two-hand","Browse weapons that occupy both hands."},
  {"all","Any handedness","Show one- and two-handed weapons."},
}
local function handednessLabel(style,ctx)
  if style=="shield" and not L.prefersShield(ctx) then return "One-hand" end
  for _,entry in ipairs(WEAPON_STYLES) do if entry[1]==style then return entry[2] end end
  return "Any handedness"
end
local function hasWeaponFilters()
  return filters.slot=="INVTYPE_WEAPON" or filters.slot=="INVTYPE_WEAPONOFFHAND" or filters.slot=="INVTYPE_RANGED"
end

local function weaponFilterPage(y,ctx)
  line(slotTitle().." weapon filters",16,y+1,390,"head",C.gold)
  button("Source filters",WIDTH-292,y,128,function() view="filters";refresh(true) end)
  button("Show results",WIDTH-152,y,140,returnToList,true)
  y=y+35
  if filters.slot=="INVTYPE_WEAPON" then
    U.surface(12,y,WIDTH-24,86,C.panel,C.edgeSoft)
    line("Handedness",26,y+12,360,"body",C.gold)
    button("Use profile default",WIDTH-204,y+8,176,function()
      filters.weaponStyle=nil;resetResults()
    end,not filters.weaponStyle,"Use the handedness preferred by your scoring profile.")
    local style=L.weaponStyle(filters,ctx)
    for i,entry in ipairs(WEAPON_STYLES) do
      local key=entry[1]
      button(handednessLabel(key,ctx),26+(i-1)*276,y+42,262,function()
        filters.weaponStyle=key;resetResults()
      end,style==key,entry[3])
    end
    y=y+98
  end
  local choices={"Any weapon type"}
  local ranged=filters.slot=="INVTYPE_RANGED"
  for i,entry in ipairs(L.weaponFamilies) do
    if (ranged and i>=8) or (not ranged and i<8 and (filters.slot~="INVTYPE_WEAPONOFFHAND" or i<6)) then
      choices[#choices+1]=entry[1]
    end
  end
  if filters.slot=="INVTYPE_WEAPONOFFHAND" then choices[#choices+1]="Shields";choices[#choices+1]="Held items" end
  local art={Axes="inv_axe_12",Maces="inv_hammer_08",Swords="inv_sword_15",Daggers="inv_weapon_shortblade_02",
    ["Fist weapons"]="inv_weapon_hand_01",Polearms="inv_spear_05",Staves="inv_staff_08",Bows="inv_weapon_bow_07",
    Guns="inv_weapon_rifle_07",Crossbows="inv_weapon_crossbow_02",Thrown="inv_throwingknife_02",Wands="inv_wand_02",
    Shields="inv_shield_05",["Held items"]="inv_misc_book_09"}
  local h=math.ceil(#choices/4)*44+54
  U.surface(12,y,WIDTH-24,h,C.panel,C.edgeSoft)
  line("Weapon type",26,y+12,360,"body",C.gold)
  for i,label in ipairs(choices) do
    local x=26+(i-1)%4*207
    local yy=y+43+math.floor((i-1)/4)*44
    local key=i>1 and label or nil
    local on=filters.weaponType==key
    U.surface(x,yy,197,34,on and C.btnOn or C.btnOff,on and C.accent or C.edgeSoft)
    U.icon(art[label] or "inv_sword_04",x+8,yy+7,20,label,nil):EnableMouse(false)
    line(label,x+38,yy+8,151,"body",on and C.light or C.dim)
    action(x,yy,197,34,label,nil,function() filters.weaponType=key;resetResults() end,label).codexOn=on
  end
  return y+h+10
end

local function slotPicker(y)
  line("Choose a gear slot",16,y+3,354,"head",C.gold)
  button("Back to results",WIDTH-150,y,138,returnToList)
  y=y+36
  local groups={
    {label="Armor",indices={1,3,4,5,6,7,8,9,10}},
    {label="Accessories",indices={2,11,12}},
    {label="Weapons",indices={13,14,15,16}},
  }
  local w=math.floor((WIDTH-48)/3)
  for g,group in ipairs(groups) do
    local x=12+(g-1)*(w+12)
    U.surface(x,y,w,#group.indices*28+49,C.panel,C.edgeSoft)
    line(group.label,x+12,y+12,w-24,"body",C.gold)
    for i,index in ipairs(group.indices) do
      local n,label,key=unpack(SLOTS[index])
      local isSelected=filters.slot==key
      local yy=y+40+(i-1)*28
      U.surface(x+8,yy,w-16,25,isSelected and C.btnOn or C.btnOff,isSelected and C.accent or C.edgeSoft)
      itemIcon(nil,x+12,yy+4,17,label,nil,"Interface\\PaperDoll\\UI-PaperDoll-Slot-"..(SLOT_ART[n] or "Chest"))
      line(label,x+40,yy+5,w-62,"body",isSelected and C.light or C.dim)
      line(">",x+w-27,yy+6,14,"small",C.accent)
      action(x+8,yy,w-16,25,label,"Browse this equipment slot.",function() chooseSlot(n,key) end,"Slot "..label).codexOn=isSelected
    end
  end
  return y+318
end

local function filterPage(y,ctx)
  local left,right=12,558
  local leftWidth,rightWidth=534,WIDTH-right-12
  local function choice(label,x,yy,w,on,fn,tip)
    button(label,x,yy,w,fn,on,tip)
    if on then U.rect(x+4,yy+19,w-8,2,C.accent,"border",1) end
  end
  local function applyLevel()
    if not levelDraft then return true end
    local n=levelDraft:match("^%d+$") and tonumber(levelDraft)
    if not n or n<1 or n>60 then
      levelError="Enter a level from 1 to 60"
      refresh()
      return false
    end
    filters.maxLevel=n
    if n==ctx.level then filters.maxLevel=nil end
    levelDraft,levelError=nil,nil
    return true
  end
  line(slotTitle().." filters",left+4,y+1,350,"head",C.gold)
  if hasWeaponFilters() then
    button("Weapon filters",WIDTH-426,y,132,function()
      if applyLevel() then view="weapons";refresh(true) end
    end)
  end
  button("Reset filters",WIDTH-282,y,116,resetFilters,false,"Clear all filters and the item search.")
  button("Show results",WIDTH-154,y,142,function()
    if applyLevel() then offset=0;browseItem=nil;returnToList() end
  end,true)
  y=y+34

  U.surface(left,y,leftWidth,252,C.panel,C.edgeSoft)
  line("Acquisition sources",left+14,y+5,255,"body",C.gold)
  line("Toggle each source on or off",left+14,y+22,255,"small",C.dim)
  choice("All sources",left+leftWidth-246,y+8,108,not filters.sources,function()
    filters.sources=nil;resetResults()
  end)
  button("Clear sources",left+leftWidth-130,y+8,116,function()
    filters.sources={};resetResults()
  end)
  U.rect(left+14,y+39,leftWidth-28,1,C.edgeSoft,"border")
  local tileWidth,tileGap=162,10
  local selected=filters.sources
  local count=selected and 0 or #SOURCES
  if selected then
    for _,key in ipairs(SOURCES) do if selected[key] then count=count+1 end end
  end
  for i,key in ipairs(SOURCES) do
    local x=left+14+(i-1)%3*(tileWidth+tileGap)
    local yy=y+50+math.floor((i-1)/3)*44
    local label=L.sourceNames[key]
    local on=not selected or selected[key]==true
    U.surface(x,yy,tileWidth,36,on and C.btnOff or C.background,on and C.edge or C.edgeSoft)
    local icon=U.icon(SOURCE_ICONS[key],x+8,yy+8,20,label,nil)
    icon.tex:SetDesaturated(not on)
    line(label,x+36,yy+11,92,"small",on and C.light or C.dim)
    U.surface(x+130,yy+10,26,16,on and C.btnOn or C.background,on and C.accent or C.edgeSoft)
    line(on and "On" or "Off",x+132,yy+11,22,"small",on and C.light or C.dim,"CENTER")
    local tip=key=="dungeonTrash" and "Includes dungeon bosses and regular enemies."
      or key=="raidTrash" and "Includes raid bosses and regular enemies."
    local b=action(x,yy,tileWidth,36,label,tip,function()
      if not selected then
        selected={}
        for _,source in ipairs(SOURCES) do selected[source]=true end
      end
      selected[key]=not on or nil
      filters.sources=selected
      if not on and count==#SOURCES-1 then filters.sources=nil end
      resetResults()
    end,label)
    b.codexOn=on
  end
  line(count.." of "..#SOURCES.." selected",left+14,y+229,leftWidth-28,"small",count>0 and C.dim or C.gold)

  local inner=right+14
  local half=math.floor((rightWidth-36)/2)
  U.surface(right,y,rightWidth,252,C.panel,C.edgeSoft)
  line("Play style",inner,y+12,180,"body",C.gold)
  for i,key in ipairs({"all","solo","group","buy"}) do
    local x=inner+(i-1)%2*(half+8)
    choice(STYLES[key],x,y+33+math.floor((i-1)/2)*27,half,filters.style==key,function()
      filters.style=key;resetResults()
    end)
  end

  U.rect(inner,y+92,rightWidth-28,1,C.edgeSoft,"border")
  line("Available by level",inner,y+104,159,"body",C.gold)
  button(ctx.preview and "Use plan level" or "Use my level",right+rightWidth-113,y+99,99,function()
    filters.maxLevel=nil;levelDraft,levelError=nil,nil;resetResults()
  end,false,"Reset availability to the level shown in the Loot banner.")
  local function stepLevel(delta)
    local n=tonumber(levelDraft) or filters.maxLevel or ctx.level
    filters.maxLevel=math.max(1,math.min(60,math.floor(n)+delta))
    if filters.maxLevel==ctx.level then filters.maxLevel=nil end
    levelDraft,levelError=nil,nil;resetResults()
  end
  button("-",inner,y+128,24,function() stepLevel(-1) end,false,"Lower the planned level by one.").codexLabel="Lower loot plan level"
  U.entry("LootPlanLevel",inner+32,y+128,43,levelDraft or tostring(filters.maxLevel or ctx.level),function(v)
    levelDraft=v
  end,function()
    if applyLevel() then resetResults() end
  end,2)
  button("+",inner+83,y+128,24,function() stepLevel(1) end,false,"Raise the planned level by one.").codexLabel="Raise loot plan level"
  button(filters.showIneligible and "Ineligible: shown" or "Ineligible: hidden",inner+119,y+128,rightWidth-147,function()
    filters.showIneligible=not filters.showIneligible;resetResults()
  end,filters.showIneligible,"Show gear your character cannot currently equip.").codexLabel="Show ineligible loot"
  if levelError then line(levelError,inner,y+153,rightWidth-28,"small",C.loss) end
  button(filters.showUnverified and "Hide unverified sources" or "Show unverified sources",inner,y+169,rightWidth-28,function()
    filters.showUnverified=not filters.showUnverified;resetResults()
  end,filters.showUnverified,"Include items with unverified sources or access requirements.").codexLabel="Show unverified sources"

  U.rect(inner,y+197,rightWidth-28,1,C.edgeSoft,"border")
  line("Sort results",inner,y+201,180,"body",C.gold)
  choice("Best upgrade",inner,y+222,half,filters.sort~="acquisition",function()
    filters.sort=nil;resetResults()
  end,"Order results by estimated upgrade value.")
  choice("Local / active",inner+half+8,y+222,half,filters.sort=="acquisition",function()
    filters.sort="acquisition";resetResults()
  end,"Prioritize sources in your area and quests already in your log.")

  y=y+264
  U.surface(left,y,WIDTH-24,75,C.panel,C.edgeSoft)
  line("Narrow by location or profession",left+14,y+9,400,"body",C.gold)
  local fieldWidth=math.floor((WIDTH-84)/3)
  for i,e in ipairs({
    {"Zone (e.g. Westfall)","LootZone","zone"},
    {"Dungeon (e.g. Deadmines)","LootDungeon","dungeon"},
    {"Profession (e.g. Blacksmithing)","LootProfession","profession"},
  }) do
    local label,entry,field=unpack(e)
    local x=left+14+(i-1)*(fieldWidth+14)
    line(label,x,y+31,fieldWidth,"small",C.dim)
    U.entry(entry,x,y+48,fieldWidth,filters[field] or "",function(v)
      filters[field]=field=="profession" and v:upper() or v
    end,resetResults,80)
  end
  return y+84
end

local function filterSummary()
  local tags={}
  if filters.sources then
    local included,excluded={},{}
    for _,key in ipairs(SOURCES) do
      local list=filters.sources[key] and included or excluded
      list[#list+1]=L.sourceNames[key]
    end
    if #excluded==1 then tags[#tags+1]=excluded[1].." excluded"
    elseif #included==0 then tags[#tags+1]="No sources selected"
    elseif #included<=2 then tags[#tags+1]=table.concat(included," + ")
    else tags[#tags+1]=#included.." source types selected" end
  end
  if filters.style~="all" then tags[#tags+1]=STYLES[filters.style] end
  for _,key in ipairs({"zone","dungeon","profession"}) do
    if filters[key] and filters[key]~="" then
      tags[#tags+1]=key:sub(1,1):upper()..key:sub(2)..": "..filters[key]
    end
  end
  if filters.showIneligible then tags[#tags+1]="Includes ineligible" end
  if filters.showUnverified then tags[#tags+1]="Includes unverified" end
  if filters.sort=="acquisition" then tags[#tags+1]="Sorted by access" end
  return tags
end

local function sourceDetails(source)
  local kind=L.sourceNames[source.type] or source.type
  local place=L.sourceLocation(source)
  local name=source.name or place or kind
  if place and (name==place or name:find(place..":",1,true)==1) then place=nil end
  if source.requiredLevel and source.requiredLevel>0 then
    place=(place and place.." / " or "").."Level "..source.requiredLevel
  end
  return kind,name,place
end

local function canMap(source)
  return source and source.map and type(source.x)=="number" and type(source.y)=="number" and L.showSourceOnMap
end

local function questDone(id,ctx)
  if ctx.preview then return false end
  local done=L.call(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,id)
  if done==nil then done=L.call(IsQuestFlaggedCompleted,id) end
  return done==true or done==1
end

local function nextQuest(source,ctx)
  local steps,complete=L.questRoute(source)
  if questDone(source.quest,ctx) then return nil,nil,steps,complete end
  for i,q in ipairs(steps) do
    if not questDone(q.id,ctx) then return q,i,steps,complete end
  end
  return nil,nil,steps,complete
end

local function questPlace(contact)
  if not contact or not contact.zone then return end
  if canMap(contact) then return string.format("%s (%.1f, %.1f)",contact.zone,contact.x,contact.y) end
  return contact.zone
end

local function pickup(source,quest,ctx)
  return L.questContact(quest,false,ctx.faction)
    or ((not quest or quest.id==source.quest) and source.giverName
      and {name=source.giverName,zone=source.zone,map=source.map,x=source.x,y=source.y})
end

local function upgradeBadge(r,futureLevel)
  local f=r.future
  if f then
    local gain=f.percent and string.format("%s%+.1f%%",f.estimate and "~" or "",f.percent) or (f.verdict=="upgrade" and "Empty slot" or nil)
    return "At level "..f.level..": "..(L.labels[f.verdict] or f.verdict),gain,f.verdict=="upgrade" and C.accent or C.dim
  end
  if futureLevel then return "Later level","Level "..futureLevel,C.dim end
  local gain
  if r.confidence=="complete" then
    if r.percent then gain=string.format("%s%+.1f%%",r.estimate and "~" or "",r.percent)
    elseif r.verdict=="upgrade" then gain="Empty slot" end
  end
  if r.verdict=="needsReview" then
    local reason=r.reason or ""
    local label="Score uncertain"
    if reason:find("effects",1,true) then label="Effects unscored"
    elseif reason:find("proficien",1,true) then label="Check training"
    elseif reason:find("partner",1,true) then label="Check off hand"
    elseif reason:find("stats",1,true) then label="Stats incomplete"
    elseif reason:find("set bonus",1,true) then label="Set bonus" end
    local dps=r.weaponDpsDelta
    return label,dps and string.format("%+.1f DPS",dps),C.gold
  end
  return L.labels[r.verdict] or r.verdict,gain,verdictColor(r.verdict)
end

local function previewItem(y,row,ctx)
  local top=y
  local x,w=SIDE,WIDTH-SIDE-12
  local item=L.item(row.item.id) or row.item
  local r=L.compare(item,ctx,nil,filters.weaponSlot)
  U.rect(x,y,3,64,C.accent,"border",1)
  itemIcon(item,x+14,y+14,38,item.name,r.reason)
  line("Selected item",x+64,y+11,w-78,"small",C.dim)
  local nameBottom=text(item.name,y+27,"body",quality(item.quality),x+64,w-78)
  local imageHit=action(x+10,y+8,w-20,math.max(48,nameBottom-y-10),item.name,r.reason)
  itemTip(imageHit,item,r.reason)
  y=math.max(y+64,nameBottom+3)
  local verdict,gain,color=upgradeBadge(r,row.futureLevel)
  U.surface(x+14,y,w-28,28,C.background,C.edgeSoft)
  U.rect(x+14,y+1,2,26,color,"border",1)
  line(verdict,x+24,y+6,143,"body",color)
  if gain then line(gain,x+174,y+6,w-198,"body",color,"RIGHT") end
  y=y+34
  if r.reason and r.confidence~="complete" and not r.future then y=text(r.reason,y,"small",C.dim,x+14,w-28) end
  if r.weaponDpsDelta and gain and not gain:find("DPS",1,true) then
    y=text(string.format("Weapon damage: %+.1f DPS",r.weaponDpsDelta),y,"small",C.gold,x+14,w-28)
  end
  local detail=L.detailLine and L.detailLine(r)
  if detail then y=text(detail,y,"small",C.dim,x+14,w-28) end
  if item.slot=="INVTYPE_2HWEAPON" and L.prefersShield(ctx) then
    y=text("Uses both hands and prevents a shield.",y,"small",C.gold,x+14,w-28)
  end
  local actionWidth=math.floor((w-36)/2)
  button("Full comparison",x+14,y+1,actionWidth,function() choose(item.id) end)
  button("Track this item",x+22+actionWidth,y+1,actionWidth,function()
    local key,err=L.track(item.key)
    message=err or (key and "Target tracked")
    refresh()
  end)
  y=y+35

  local route=row.sources[1]
  local sourceTop=y
  line("Where to get it",x+25,y+9,w-50,"body",C.light)
  if route then
    local kind,name,place=sourceDetails(route)
    local count=#row.sources-1
    U.icon(SOURCE_ICONS[route.type] or "inv_misc_map_01",x+25,y+34,27,kind,name):EnableMouse(false)
    line(kind..(count>0 and (" / +"..count.." more") or ""),x+62,y+31,w-85,"small",C.dim)
    y=math.max(y+65,text(name,y+45,"body",C.gold,x+62,w-85))
    local mapContact
    if route.quest then
      local quest,step,steps,complete=nextQuest(route,ctx)
      local where=pickup(route,quest,ctx)
      if (quest or (#steps==0 and not questDone(route.quest,ctx))) and canMap(where)
        and C_Map and C_Map.SetUserWaypoint then mapContact=where end
      if quest and (#steps>1 or where) then
        U.rect(x+25,y+2,w-50,1,C.edgeSoft,"border")
        local label=complete and #steps>1 and (step==1 and "Start the chain" or "Next quest") or "Quest pickup"
        line(label,x+25,y+8,w-50,"small",C.dim)
        y=text(quest.name,y+23,"body",C.gold,x+25,w-50)
        if where then
          y=text(where.name,y-2,"small",C.light,x+25,w-50)
          local location=questPlace(where)
          if location then y=text(location,y-3,"small",C.dim,x+25,w-50) end
        end
      elseif where and #steps==0 then
        y=text(where.name,y-2,"small",C.light,x+63,w-86)
        if place then y=text(place,y-3,"small",C.dim,x+63,w-86) end
      elseif questDone(route.quest,ctx) then y=text("Reward quest completed",y-2,"small",C.green,x+63,w-86)
      elseif place then y=text(place,y-2,"small",C.dim,x+63,w-86) end
    elseif place then y=text(place,y-2,"small",C.dim,x+63,w-86) end
    local routeWidth=mapContact and math.floor((w-58)/2) or w-50
    button(route.quest and "View quest route" or "View sources",x+25,y+1,routeWidth,function()
      choose(item.id,route.id,"Sources")
    end,true).codexLabel="View sources"
    if mapContact then
      button("Map pickup",x+33+routeWidth,y+1,routeWidth,function()
        local _,why=L.showQuestOnMap(route.id,mapContact)
        message=why;refresh()
      end).codexLabel="Map preview pickup"
    end
    y=y+25
  else
    y=text(item.tradable and "Tradable. Source unverified." or "Source unverified",y+31,"body",C.dim,x+25,w-50)
  end
  U.surface(x+14,sourceTop,w-28,y+10-sourceTop,C.background,C.edgeSoft)
  U.surface(x,top,w,y+20-top,C.panel,C.edgeSoft)
  return y+20
end

local function browse(y,ctx)
  local top=y
  local back=button("< Equipment",12,y,106,function() view="character";refresh(true) end)
  back.codexLabel,back.tipTitle="Back to character","Back to character"
  line(slotTitle().." upgrades",132,y+1,272,"head",C.gold)
  button("Change slot",418,y,138,function() view="slots";refresh(true) end)
  y=y+30
  U.surface(12,y,544,42,C.panel,C.edgeSoft)
  baseline(y,ctx)
  if hasWeaponFilters() then
    local style=L.weaponStyle(filters,ctx)
    local label=filters.weaponType
    if label and style~="all" then label=(style=="shield" and "1H " or "2H ")..label
    elseif not label then label=style=="all" and "Any weapon type" or handednessLabel(style,ctx) end
    local wep=button(label.." >",403,y+10,143,function() view="weapons";refresh(true) end,style~="all" or filters.weaponType~=nil,
      "Filter by handedness and weapon type.")
    wep.codexLabel="Weapon filters"
    wep:SetFrameLevel(wep:GetFrameLevel()+1)
  end
  y=y+50

  local tags=filterSummary()
  U.entry("LootSearch",17,y,331,filters.search,function(v) filters.search=v end,resetResults,80)
  button("Search",361,y,76,resetResults,false,"Search by item name or ID.")
  local count=#tags+(filters.maxLevel and filters.maxLevel~=ctx.level and 1 or 0)
  local filterLabel=count>0 and ("Filters ("..count..")") or "Filters"
  local function openFilters()
    view="filters";levelDraft,levelError=nil,nil;refresh(true)
  end
  local filter=button(filterLabel,449,y,107,openFilters,count>0)
  filter.codexLabel="Filters"
  y=y+29

  filters.weaponSlot=(slotNumber==16 or slotNumber==17) and slotNumber or nil
  local page=L.candidates(filters,ctx,offset,PAGE)
  if offset>0 and offset>=page.total then
    offset=math.max(0,math.floor((page.total-1)/PAGE)*PAGE)
    page=L.candidates(filters,ctx,offset,PAGE)
  end
  local available="Available by level "..(filters.maxLevel or ctx.level).." >"
  button(available,12,y,153,openFilters,filters.maxLevel and filters.maxLevel~=ctx.level,
    "Set the level at which you want to find gear.").codexLabel="Availability filters"
  line(page.total..(page.total==1 and " matching item" or " matching items"),176,y+3,132,"small",C.dim)
  if #tags>0 then
    local summary=table.concat(tags,"  /  ")
    line(summary,311,y+3,239,"small",C.dim,"RIGHT")
    action(306,y,250,22,"Active filters",ns.plain(summary),openFilters,"Active filters")
  end
  y=y+27
  if page.total==0 then
    U.surface(12,y,544,90,C.panel,C.edgeSoft)
    text("No matching items",y+14,"body",C.gold,24,512)
    if filters.sources and next(filters.sources)==nil then
      text("No acquisition sources selected.",y+41,"small",C.dim,24,512)
      button("Choose sources",312,y+56,220,openFilters,true)
    else
      text("No matching gear with these filters at this level.",y+41,"small",C.dim,24,512)
      button("Clear search and filters",312,y+56,220,resetFilters)
    end
    U.surface(SIDE,top,WIDTH-SIDE-12,124,C.panel,C.edgeSoft)
    text("Item preview",top+16,"head",C.gold,SIDE+14,246)
    text("Choose a result to see how it compares and where to get it.",top+49,"body",C.dim,SIDE+14,246)
    return math.max(y+102,top+124)
  end

  local current=page.rows[1]
  for _,row in ipairs(page.rows) do
    if row.item.id==browseItem then current=row;break end
  end
  U.rect(12,y+16,544,1,C.edgeSoft,"border")
  line("Item and acquisition",21,y,300,"small",C.dim)
  line("Comparison",447,y,105,"small",C.dim,"CENTER")
  y=y+19
  for _,row in ipairs(page.rows) do
    local it,r=row.item,row.result
    local on=current==row
    U.surface(12,y,544,35,C.panel,on and C.edge or C.edgeSoft)
    if on then
      U.rect(13,y+1,349,33,C.btnOn)
      U.rect(12,y,3,35,C.accent,"border",1)
    end
    itemIcon(it,21,y+4,27,it.name,r.reason)
    line(it.name,58,y+1,299,"body",quality(it.quality))
    local route=row.sources[1]
    local b=action(12,y,350,35,it.name,r.reason,function()
      browseItem=it.id;message=nil;refresh()
    end,"Inspect item "..it.id)
    b.codexOn=on
    itemTip(b,it,r.reason)
    if route then
      local kind,name,place=sourceDetails(route)
      local count=#row.sources-1
      local acquisition=kind~=name and (kind.." / "..name) or name
      line(acquisition..(count>0 and (" +"..count) or ""),58,y+19,299,"small",C.dim)
      local shortcut=button("Route >",369,y+6,70,function() browseItem=it.id;choose(it.id,route.id) end,on,
        name..(place and (" / "..place) or ""))
      shortcut.codexLabel="Sources for item "..it.id
    else
      line("Source unverified",58,y+19,299,"small",C.dim)
    end
    local verdict,gain,color=upgradeBadge(r,row.futureLevel)
    U.rect(447,y+3,104,29,C.background)
    line(gain or verdict,449,y+(gain and 2 or 9),100,"small",color,"CENTER")
    if gain then line(verdict,449,y+17,100,"small",C.dim,"CENTER") end
    y=y+38
  end
  y=y+5
  if offset>0 then button("Previous loot page",12,y,138,function() offset=math.max(0,offset-PAGE);refresh(true) end) end
  if page.total>PAGE then
    line("Page "..(math.floor(offset/PAGE)+1).." of "..math.ceil(page.total/PAGE),165,y+5,238,"small",C.dim,"CENTER")
  end
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
  if r.weaponDpsDelta then
    y=text(string.format("Base weapon DPS  %.1f to %.1f  (%+.1f)",it.damage-r.weaponDpsDelta,it.damage,r.weaponDpsDelta),
      y,"small",C.gold)
  end
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
  line(r.future and "Gear score at level "..r.future.level or r.estimate and "Estimated gear score (about)" or "Estimated gear score",310,y+10,236,"small",C.gold)
  if (r.confidence=="complete" or r.future) and r.score and r.baselineScore then
    local delta=r.score-r.baselineScore
    local scale=math.max(1,math.abs(r.score),math.abs(r.baselineScore))
    line("Before "..number(r.baselineScore),310,y+31,112,"small",C.dim)
    line("With item "..number(r.score),428,y+31,120,"small",delta>=0 and C.green or C.loss)
    U.rect(310,y+55,108,7,C.edgeSoft,"border",1);U.rect(428,y+55,108,7,C.edgeSoft,"border",1)
    if r.baselineScore>0 then U.rect(310,y+55,108*r.baselineScore/scale,7,C.dim,"border",2) end
    if r.score>0 then U.rect(428,y+55,108*r.score/scale,7,delta>=0 and C.green or C.loss,"border",2) end
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
  local notes=(r.future and r.future.notes) or r.notes or {}
  if #r.warnings>0 or #notes>0 then
    y=y+8;y=y+sectionTitle("Check before replacing",y)
    for _,warning in ipairs(r.warnings) do y=text(warning,y,"small",C.gold) end
    for _,note in ipairs(notes) do y=text(note..".",y,"small",C.dim) end
    for _,w in ipairs(it.warnings or {}) do y=text(w,y,"small",C.dim) end
  end
  return y
end
local function questRoutePanel(source,y,ctx,detail)
  local nextStep,nextIndex,steps,complete=nextQuest(source,ctx)
  if #steps<2 then return y end
  local top,x,w=y,SIDE,WIDTH-SIDE-12
  local chosen=nextStep or steps[#steps]
  for _,quest in ipairs(steps) do if quest.id==detail.questStep then chosen=quest;break end end
  local where=pickup(source,chosen,ctx)
  line(complete and "Quest chain" or "Known quest steps",x+14,y+12,w-28,"head",C.gold)
  y=y+45
  local cardY=y
  local title=chosen~=nextStep and "Selected step" or nextIndex==1 and complete and "Start the chain" or "Next quest"
  line(title,x+25,y+8,w-50,"small",C.accent)
  y=text(chosen.name,y+26,"body",C.gold,x+25,w-50)
  if where then
    y=text(where.name,y-1,"small",C.light,x+25,w-50)
    local location=questPlace(where)
    if location then y=text(location,y-2,"small",C.dim,x+25,w-50) end
    if canMap(where) then
      button("Map pickup",x+25,y,w-50,function()
        local _,why=L.showQuestOnMap(source.id,where);message=why;refresh()
      end,true).codexLabel="Map quest "..chosen.id
      y=y+26
    end
  end
  U.surface(x+14,cardY,w-28,y+7-cardY,C.background,C.edgeSoft)
  y=y+17
  for i,quest in ipairs(steps) do
    local on=quest==chosen
    local done=questDone(quest.id,ctx)
    local contact=pickup(source,quest,ctx)
    U.surface(x+14,y,w-28,30,on and C.btnOn or C.btnOff,on and C.accent or C.edgeSoft)
    line(done and "+" or tostring(i),x+18,y+8,24,"small",done and C.green or C.dim,"CENTER")
    line(quest.name,x+46,y+2,w-64,"small",on and C.light or C.gold)
    line(i==#steps and "Gear reward" or (contact and contact.name or "Contact unverified"),x+46,y+15,w-64,"small",C.dim)
    action(x+14,y,w-28,30,quest.name,done and "Quest complete." or "Show this quest's pickup.",function()
      detail.questStep=quest.id;refresh()
    end,"Loot quest "..quest.id).codexOn=on
    y=y+34
  end
  U.surface(x,top,w,y+8-top,C.panel,C.edgeSoft)
  return y+8
end

local function acquisition(it,y,ctx,detail,routeTop)
  local sources=L.sources(it.id,nil,ctx)
  -- Keep the route that the player opened first, with all other routes still available.
  if detail.source then
    local pinned=ns.lootData and ns.lootData.sources[detail.source]
    if pinned and pinned.item==it.id then
      for i,s in ipairs(sources) do
        if s.id==detail.source then table.remove(sources,i);break end
      end
      table.insert(sources,1,pinned)
    end
  end
  if #sources==0 then
    U.surface(4,y,U.W-8,112,C.panel,C.edgeSoft)
    U.icon("inv_misc_map_01",22,y+24,48,"Acquisition source","Verified source information is not available.")
    local bottom=text("Source not verified",y+19,"head",C.gold,86,U.W-110)
    y=text("No verified acquisition source in this catalog. Check the item in game.",bottom,"body",C.dim,86,U.W-110)+20
  end
  local sourceOffset=detail.offset
  if sourceOffset>=#sources then sourceOffset=0 end
  local selectedQuest
  for i=sourceOffset+1,math.min(#sources,sourceOffset+2) do
    local s=sources[i];local top=y;local open=detail.expanded==s.id
    if s.quest and (open or not selectedQuest) then selectedQuest=s end
    local kind,name,place=sourceDetails(s)
    U.rect(5,y+1,U.W-10,60,C.btnOff)
    if open then U.rect(4,y,3,60,C.accent,"border",1) end
    U.icon(SOURCE_ICONS[s.type] or "inv_misc_map_01",17,y+14,32,kind,name):EnableMouse(false)
    line(kind,63,y+8,U.W-182,"small",C.dim)
    line(name,63,y+24,U.W-182,"body",C.gold)
    if place then line(place,63,y+44,U.W-174,"small",C.dim) end
    line(open and "- Details" or "+ Details",U.W-104,y+22,86,"small",C.accent,"RIGHT")
    local b=action(4,y,U.W-8,60,name,"Show source requirements, costs and materials.",function()
      if open then detail.expanded=nil else detail.expanded=s.id end;refresh()
    end,"Source details "..i);b.codexOn=open
    y=y+70
    if open then
      if s.requiredLevel and s.requiredLevel>0 then y=text("Source requires level "..s.requiredLevel,y,"small",C.dim,17) end
      if s.faction and s.faction~="All" then y=text("Source faction: "..s.faction,y,"small",C.dim,17) end
      local facts=ns.lootData and ns.lootData.questFacts
      local quest=facts and facts[s.quest]
      local start=pickup(s,quest,ctx)
      local finish=L.questContact(quest,true,ctx.faction)
      if start then
        local location=questPlace(start)
        local label=quest and #quest.previous>0 and "Reward quest pickup at " or "Starts with "
        y=text(label..start.name..(location and (" / "..location) or ""),y,"small",C.light,17)
      end
      if finish and (not start or finish.name~=start.name) then
        local location=questPlace(finish)
        y=text("Turn in to "..finish.name..(location and (" / "..location) or ""),y,"small",C.light,17)
      end
      if s.locationKind=="entrance" then y=text("Map pin shows the dungeon entrance.",y,"small",C.dim,17) end
      if s.prerequisites and #s.prerequisites>0 then
        local names={}
        for _,id in ipairs(s.prerequisites) do
          local q=facts and facts[id]
          names[#names+1]=q and q.name or L.call(C_QuestLog and C_QuestLog.GetTitleForQuestID,id) or ("Quest "..id)
        end
        y=text("Prerequisite quests: "..table.concat(names,", "),y,"small",C.dim,17)
      end
      if s.cost then y=text("Cost: "..(ns.money and ns.money(s.cost) or tostring(s.cost)),y,"small",C.light,17) end
      if s.materials then
        local mats={};for name,n in pairs(s.materials) do mats[#mats+1]=n.." "..name end;table.sort(mats)
        y=text("Materials: "..table.concat(mats,", "),y,"small",C.light,17)
      end
    end
    U.rect(17,y,534,1,C.edgeSoft,"border")
    y=text(s.evidence=="client" and "Client reference" or "Database reference; server availability may vary",y+7,"small",C.dim,17)
    button("Track route",17,y,158,function()
      local key,err=L.track(it.key,s.id);message=err or (key and "Source tracked");refresh()
    end,true).codexLabel="Track source "..i
    if canMap(s) then
      button("Show on map",186,y,160,function()
        local _,why=L.showSourceOnMap(s.id);message=why;refresh()
      end).codexLabel="Map source "..i
    end
    if s.quest and L.questGuideSection and L.questGuideSection(s.quest) then
      button("Open quest guide",356,y,195,function() L.openQuestSource(s.quest) end).codexLabel="Quest guide "..i
    end
    y=y+32;U.surface(4,top,U.W-8,y-top,C.panel,open and C.edge or C.edgeSoft);y=y+10
  end
  if #sources>2 then
    button("More sources",12,y,160,function()
      detail.offset=sourceOffset+2<#sources and sourceOffset+2 or 0;detail.expanded=nil;refresh(true)
    end)
    line((sourceOffset+1).."-"..math.min(#sources,sourceOffset+2).." of "..#sources.." sources",184,y+4,240,"small",C.dim);y=y+32
  end
  if it.tradable then y=text("Tradable: another player or the auction house may have it. Price unknown.",y,"small",C.dim) end
  if selectedQuest then y=math.max(y,questRoutePanel(selectedQuest,routeTop,ctx,detail)) end
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
local function details(detail,y,ctx)
  local it=L.item(detail.ref)
  if not it then return text("Enter a valid item link or item ID.",y) end
  local r=L.compare(it,ctx,nil,detail.weaponSlot)
  L.lastComparison=it.name..": "..(L.labels[r.verdict] or r.verdict).." - "..r.reason
  local routeTop=y
  if section=="Upgrades" then
    button("Back to results",0,y,146,function() view="list";refresh(true) end)
    line(slotTitle().." upgrades",160,y+4,U.W-172,"small",C.dim);y=y+32
  end
  local top=y
  itemIcon(it,16,y+16,40,it.name,r.reason)
  line(it.name,68,y+13,300,"head",quality(it.quality))
  local verdict,gain,color=upgradeBadge(r)
  local value=r.confidence=="complete" and r.percent and string.format(" (%s%+.1f%% estimated gear score)",r.estimate and "about " or "",r.percent)
    or gain and (" / "..gain) or ""
  line(verdict..value,68,y+41,300,"small",color)
  if it.slot=="INVTYPE_2HWEAPON" and L.prefersShield(ctx) then
    line("Uses both hands and prevents a shield.",68,y+57,300,"small",C.gold)
  end
  local header=action(4,top,370,76,it.name,r.reason,nil,"Item comparison");itemTip(header,it,r.reason)
  button("Track this item",384,y+14,170,function() local key,err=L.track(it.key);message=err or (key and "Target tracked");refresh() end)
  if section=="Upgrades" then
    button("Compare this item",384,y+42,170,function()
      input=it.key;section="Compare";compareDetail.open=false;choose(it.key)
    end)
  end
  U.surface(4,top,U.W-8,76,C.panel,C.edgeSoft);y=y+88
  for i,label in ipairs({"Overview","Sources","Enchants"}) do
    local b=button(label=="Sources" and "Where to get it" or label,4+(i-1)*188,y,180,function() detail.page=label;refresh(true) end,detail.page==label)
    b.codexLabel=label
  end
  y=y+32
  if detail.page=="Sources" then return acquisition(it,y,ctx,detail,routeTop)
  elseif detail.page=="Enchants" then return enchantOptions(it,y,ctx) end
  return statOverview(it,r,y,ctx)
end

local function comparisonResult(y,ctx)
  local top,x,w=y,SIDE,WIDTH-SIDE-12
  local inset=x+14
  local it=compareDetail.ref and L.item(compareDetail.ref)
  line("Comparison",inset,y+12,w-28,"head",C.gold)
  line(((ctx.preview or preview and preview.snapshot) and "Planning" or "Live character").." / "..ctx.profile.label,inset,y+38,w-28,"small",C.dim)
  button(planning and "Hide plan" or "Planning",x+w-102,y+12,88,function() planning=not planning;refresh() end,planning,
    "Plan for another character or enter a baseline item.")
  y=y+62
  if not it then
    U.icon("inv_misc_gem_opal_01",inset,y+2,34,"Compare equipment",nil)
    y=text("Pick a piece of gear or enter an item link to see what would change.",y+2,"body",C.dim,inset+46,w-74)+12
  else
    local r=L.compare(it,ctx)
    local color=verdictColor(r.verdict)
    L.lastComparison=it.name..": "..(L.labels[r.verdict] or r.verdict).." - "..r.reason
    local score=r.confidence=="complete" and (r.percent and string.format("%s%+.1f%%",r.estimate and "~" or "",r.percent) or string.format("%+.1f",r.delta))
      or r.future and (r.future.percent and string.format("%+.1f%%",r.future.percent) or r.future.delta and string.format("%+.1f",r.future.delta))
    local status,dps=upgradeBadge(r)
    local equipped=#r.baseline==1 and r.baseline[1].key==it.key
    U.surface(inset,y,w-28,48,C.background,C.edgeSoft)
    U.rect(inset,y,3,48,color,"border",1)
    line(equipped and "Already equipped" or (r.future and status) or (dps and r.verdict=="needsReview" and status) or L.labels[r.verdict] or r.verdict,
      inset+12,y+7,w-106,"body",color)
    if score then
      line("Estimated gear score",inset+12,y+29,w-110,"small",C.dim)
      line(score,x+w-103,y+14,79,"head",color,"RIGHT")
    elseif dps then
      line(dps,inset+12,y+29,w-28,"small",C.gold)
    end
    y=y+57
    if not score or r.future then y=text(r.future and ("Requires level "..r.future.level..": rated for when you get there.") or r.reason,y-2,"small",C.dim,inset,w-28)+3 end
    local notes=L.notesText and L.notesText((r.future and r.future.notes) or r.notes)
    if notes then y=text("Score "..notes..".",y-2,"small",C.dim,inset,w-28)+3 end
    if it.slot=="INVTYPE_2HWEAPON" and L.prefersShield(ctx) then
      y=text("Uses both hands and prevents a shield.",y,"small",C.gold,inset,w-28)
    end
    local function gearCard(item,label,fallback,isCandidate)
      U.surface(inset,y,w-28,43,C.btnOff,C.edgeSoft)
      if isCandidate then U.rect(inset,y,2,43,C.accent,"border",1) end
      itemIcon(item,inset+5,y+6,30,item and item.name or label,nil,"Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest"):EnableMouse(false)
      line(label,inset+44,y+5,w-80,"small",isCandidate and C.accent or C.dim)
      line(item and item.name or fallback,inset+44,y+23,w-80,"small",item and quality(item.quality) or C.dim)
      if item then itemTip(action(inset,y,w-28,43,item.name,nil),item) end
      y=y+48
    end
    if #r.baseline==0 then
      gearCard(nil,"Equipped baseline",r.confidence=="complete" and "Empty slot" or "Baseline unverified")
    else
      for i,old in ipairs(r.baseline) do gearCard(old,i==1 and "Equipped baseline" or "Also replaces") end
    end
    gearCard(it,"Selected item",nil,true)
    if statsReadable(it,r,ctx) then
      local changes={}
      for stat,delta in pairs(r.statDelta) do if delta~=0 then changes[#changes+1]=stat end end
      table.sort(changes,function(a,b)
        local da,db=math.abs(r.statDelta[a]),math.abs(r.statDelta[b])
        if da==db then return a<b end
        return da>db
      end)
      if #changes>0 then
        line("Stat changes",inset,y+4,w-28,"small",C.dim)
        y=y+20
      end
      for i=1,math.min(3,#changes) do
        local stat=changes[i]
        local delta=r.statDelta[stat]
        U.rect(inset,y,w-28,19,C.background)
        line(STAT_NAMES[stat] or stat,inset+9,y+3,w-100,"small",C.light)
        line((delta>0 and "+" or "")..number(delta),x+w-90,y+3,66,"small",delta>0 and C.green or C.loss,"RIGHT")
        y=y+22
      end
    end
    y=y+7
    button("Full comparison",inset,y,w-28,function() compareDetail.open=true;compareDetail.page="Overview";refresh(true) end,true)
    local half=math.floor((w-36)/2)
    button("Where to get it",inset,y+28,half,function() compareDetail.open=true;compareDetail.page="Sources";refresh(true) end)
    button("Track this item",inset+half+8,y+28,half,function()
      local key,err=L.track(it.key)
      message=err or (key and "Target tracked");refresh()
    end)
    y=y+61
  end
  U.surface(x,top,w,y+4-top,C.panel,C.edgeSoft)
  y=y+14
  if planning then
    local bottom=planningFields(y,ctx,x,w)
    button("Use live character",inset,bottom+3,w-28,function() preview=nil;planning=false;refresh() end)
    U.surface(x,y,w,bottom+37-y,C.panel,C.edgeSoft)
    y=bottom+37
  end
  return y
end

local function compare(y,ctx)
  local function submit()
    local key=L.itemKey(input);message=not key and "Enter a valid item link or item ID." or nil
    if key then choose(key) else compareDetail={};refresh() end
  end
  local full=compareDetail.open and compareDetail.ref
  local sideBottom=not full and comparisonResult(y,ctx)
  U.surface(4,y,U.W-8,74,C.panel,C.edgeSoft)
  U.icon("inv_misc_gem_opal_01",17,y+15,30,"Compare gear",nil):EnableMouse(false)
  line("Compare gear",59,y+7,214,"head",C.gold)
  line("Item link or ID",288,y+14,U.W-307,"small",C.dim,"RIGHT")
  U.entry("LootItem",59,y+39,U.W-195,input or "",function(v) input=v end,submit,2048)
  button("Check item",U.W-124,y+39,106,submit,true)
  y=y+86
  if full then
    button("Back to items",12,y,146,function() compareDetail.open=false;refresh(true) end)
    return details(compareDetail,y+32,ctx)
  end
  line("Choose an item",12,y+3,145,"body",C.gold)
  line("Name filter",148,y+5,71,"small",C.dim,"RIGHT")
  U.entry("LootInventorySearch",222,y,112,inventorySearch,function(value) inventorySearch=value end,function()
    inventoryPage=0;refresh()
  end,80)
  for i,label in ipairs({"Bags","Equipped"}) do
    local x=346+(i-1)*106
    button(label,x,y,100,function() inventoryMode=label;inventoryPage=0;refresh() end,inventoryMode==label)
    if inventoryMode==label then U.rect(x+5,y+19,90,2,C.accent,"border",1) end
  end
  U.rect(12,y+26,U.W-24,1,C.edgeSoft,"border")
  y=y+30
  local snapshot=L.snapshot()
  local items={}
  local query=inventorySearch:lower()
  local function append(it,n,label)
    if not it or not label:lower():find(query,1,true) then return end
    items[#items+1]={item=it,slot=n,label=label}
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
    U.icon("inv_misc_bag_10",38,y+27,52,"Equipment",nil)
    local title=query~="" and "No matching equipment"
      or inventoryMode=="Bags" and (snapshot.bagsKnown and "No bag equipment" or "Bag items unavailable") or "No equipped items"
    text(title,y+24,"body",C.gold,108,U.W-132)
    text(query~="" and "Clear the filter and press Enter to show all items."
      or "Use the item field above or switch to "..(inventoryMode=="Bags" and "Equipped." or "Bags."),y+53,"small",C.dim,108,U.W-132)
    return math.max(y+130,sideBottom or 0)
  end
  for i=inventoryPage*6+1,math.min(#items,inventoryPage*6+6) do
    local row=items[i];local it=row.item;local ix=(i-1)%6
    local x,yy=12+(ix%2)*278,y+math.floor(ix/2)*58
    local on=compareDetail.ref==it.key
    U.surface(x,yy,266,52,on and C.btnOn or C.panel,on and C.accent or C.edgeSoft)
    if on then U.rect(x,yy,3,52,C.accent,"border",1) end
    itemIcon(it,x+8,yy+9,34,it.name,"Select to compare with your gear."):EnableMouse(false)
    local slot=row.slot and L.slotNames[row.slot] or (it.slot and L.slotNames[L.slotsFor(it.slot)[1]])
    line(slot or "Equipment",x+52,yy+8,189,"small",C.dim)
    line(it.name,x+52,yy+27,189,"small",quality(it.quality))
    line(">",x+247,yy+19,10,"small",C.accent)
    local key=it.key
    local b=action(x,yy,266,52,it.name,"Compare with your equipped gear.",function() input=key;choose(key) end,row.label)
    b.codexOn=on
    itemTip(b,it)
  end
  y=y+math.ceil(math.min(6,#items-inventoryPage*6)/2)*58+6
  if inventoryPage>0 then button("Previous items",12,y,132,function() inventoryPage=inventoryPage-1;refresh(true) end) end
  if #items>6 then line("Page "..(inventoryPage+1).." of "..math.ceil(#items/6),168,y+4,232,"small",C.dim,"CENTER") end
  if (inventoryPage+1)*6<#items then button("Next items",424,y,132,function() inventoryPage=inventoryPage+1;refresh(true) end) end
  return math.max(y+30,sideBottom or 0)
end
local function tracked(y)
  line("Your upgrade targets",16,y+1,420,"head",C.gold)
  local enabled=not ns.db().noLootTracker
  button(enabled and "Hide floating tracker" or "Show floating tracker",WIDTH-194,y,182,function()
    ns.db().noLootTracker=enabled or nil
    L.refreshTracker()
    refresh()
  end,enabled,"Toggle the separate tracker that stays visible while you play.")
  y=y+34
  local all=L.targets()
  if #all==0 then
    U.surface(12,y,WIDTH-24,118,C.panel,C.edgeSoft)
    U.rect(12,y,3,118,C.accent,"border",1)
    U.icon("inv_misc_bag_10",31,y+28,58,"Loot targets",nil):EnableMouse(false)
    line("No saved upgrades",109,y+24,462,"head",C.gold)
    text("Track a piece of gear or a specific route to keep it handy here and in the floating tracker.",y+55,"body",C.dim,109,449)
    button("Browse upgrades",WIDTH-251,y+28,222,function() section="Upgrades";view="character";refresh(true) end,true)
    button("Compare an item",WIDTH-251,y+59,222,function() section="Compare";input=nil;compareDetail={};refresh(true) end)
    return y+130
  end
  local counts={all=#all,tracked=0,obtained=0,dismissed=0}
  for _,t in ipairs(all) do counts[t.state]=counts[t.state]+1 end
  local states={{"all","All"},{"tracked","Active"},{"obtained","Obtained"},{"dismissed","Dismissed"}}
  for i,state in ipairs(states) do
    local key,label=unpack(state)
    local x=12+(i-1)*142
    button(label.." ("..counts[key]..")",x,y,134,function()
      targetFilter=key;targetPage=0;refresh(true)
    end,targetFilter==key).codexLabel=label
    if targetFilter==key then U.rect(x+5,y+19,124,2,C.accent,"border",1) end
  end
  y=y+34
  local list=targetFilter=="all" and all or L.targets(targetFilter)
  if targetPage*3>=#list then targetPage=math.max(0,math.ceil(#list/3)-1) end
  if #list==0 then
    U.surface(12,y,WIDTH-24,66,C.panel,C.edgeSoft)
    return text("No targets in this group. Choose All to see your other targets.",y+22,"body",C.dim,27,WIDTH-54)+22
  end
  local live=L.context()
  local stateLabel={tracked="Active",dismissed="Dismissed",obtained="Obtained"}
  local stateColor={tracked=C.accent,dismissed=C.dim,obtained=C.green}
  for i=targetPage*3+1,math.min(#list,targetPage*3+3) do
    local t=list[i];local it=L.item(t.ref)
    local name=it and it.name or t.name
    local color=stateColor[t.state]
    U.surface(12,y,WIDTH-24,80,C.panel,C.edgeSoft)
    U.rect(12,y,3,80,color,"border",1)
    itemIcon(it,28,y+19,42,name,t.state)
    local nameBottom=text(name,y+13,"body",it and quality(it.quality) or C.light,83,211)
    local badgeY=math.min(y+55,math.max(y+39,nameBottom))
    U.surface(83,badgeY,90,17,C.background,C.edgeSoft)
    line(stateLabel[t.state],88,badgeY+2,80,"small",color,"CENTER")
    U.rect(309,y+11,1,58,C.edgeSoft,"border")
    U.rect(628,y+11,1,58,C.edgeSoft,"border")

    local source,more=L.targetSource(t,live)
    U.icon(source and SOURCE_ICONS[source.type] or "inv_misc_map_01",326,y+25,28,"Acquisition",nil):EnableMouse(false)
    if source then
      local kind,route,place=sourceDetails(source)
      line(kind..(more>0 and (" / +"..more.." more") or ""),367,y+10,245,"small",C.dim)
      line(route,367,y+29,245,"body",C.gold)
      if place then line(place,367,y+52,245,"small",C.dim) end
    else
      line("Acquisition",367,y+13,245,"small",C.dim)
      line(it and it.tradable and "Tradable. Source unverified." or "Source unverified",367,y+34,245,"body",C.dim)
    end
    local function openTarget()
      L.open("Compare",t.ref,source and source.id)
    end
    local b=action(15,y,288,80,name,"Open this target's item details.",openTarget,t.name.." - "..t.state)
    if it then itemTip(b,it) end
    local mapped=canMap(source)
    button(source and "View source" or "View item",643,y+12,mapped and 96 or 200,openTarget,true)
    if mapped then
      button("Show on map",747,y+12,96,function()
        local _,why=L.showSourceOnMap(source.id);message=why;refresh()
      end,false,"Place a pin for this source.").codexLabel="Map "..t.name
    end
    button(t.state=="tracked" and "Dismiss" or "Restore",643,y+45,96,function()
      L.setTargetState(t.key,t.state=="tracked" and "dismissed" or "tracked");refresh()
    end)
    button("Untrack",747,y+45,96,function() L.untrack(t.key);refresh() end,false,"Remove this target from your journal.")
    y=y+88
  end
  if #list>3 then
    if targetPage>0 then button("Previous targets",12,y,150,function() targetPage=targetPage-1;refresh(true) end) end
    line("Page "..(targetPage+1).." of "..math.ceil(#list/3),WIDTH/2-104,y+4,208,"small",C.dim,"CENTER")
    if (targetPage+1)*3<#list then button("Next targets",WIDTH-162,y,150,function() targetPage=targetPage+1;refresh(true) end) end
  end
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
  line("Scoring profiles",16,y+1,335,"head",C.gold)
  line("Sets the priorities used for gear comparisons",WIDTH-357,y+7,341,"small",C.dim,"RIGHT")
  y=y+34
  U.surface(12,y,WIDTH-24,64,C.panel,C.edgeSoft)
  U.rect(12,y,3,64,C.accent,"border",1)
  U.icon("inv_misc_book_11",28,y+14,36,"Scoring profile",p.label):EnableMouse(false)
  local automatic=not ns.charDB().lootProfile and not ns.charDB().lootProfileKey and not (preview and preview.profileKey)
  line(automatic and "Following your talent path" or "Manual loot profile",80,y+10,310,"small",C.dim)
  line(p.label,80,y+28,400,"head",C.gold)
  button("Follow talent path",WIDTH-203,y+21,175,function()
    L.resetProfile();if preview then preview.profileKey=nil end;editor=nil;refresh()
  end,automatic)
  y=y+80
  local paths=(ns.TALENT_PATHS or {})[ctx.class] or {}
  local n=math.max(1,#paths);local w=math.floor((WIDTH-24-(n-1)*12)/n)
  for i,p0 in ipairs(paths) do
    local x=12+(i-1)*(w+12);local on=p0.key==p.key
    U.surface(x,y,w,102,on and C.btnOn or C.panel,on and C.accent or C.edgeSoft)
    if on then U.rect(x,y,3,102,C.accent,"border",1) end
    local plan=p0.plan or (ctx.class==select(2,UnitClass("player")) and ns.D and ns.D.plan)
    local art=plan and plan[1] and plan[1].icon or "inv_misc_book_11"
    U.icon(art,x+14,y+21,43,p0.spec,p0.note):EnableMouse(false)
    line(p0.spec,x+72,y+18,w-85,"head",C.gold)
    line(p0.role or "Leveling",x+72,y+48,w-85,"small",C.light)
    if on then
      U.surface(x+72,y+70,76,18,C.background,C.edgeSoft)
      line("Active",x+77,y+72,66,"small",C.accent,"CENTER")
    else
      line(">",x+w-22,y+43,13,"body",C.accent)
    end
    local b=action(x,y,w,102,p0.spec,p0.note,function()
      if ctx.preview then preview=preview or {};preview.profileKey=p0.key else L.setProfile(p0.key) end
      editor=nil;refresh()
    end,p0.spec);b.codexOn=on
  end
  y=y+116
  U.surface(12,y,417,106,C.panel,C.edgeSoft)
  U.icon("inv_misc_letter_15",26,y+13,28,"Profile tools",nil):EnableMouse(false)
  line("Profile tools",66,y+11,340,"body",C.gold)
  line("Share a profile code or set your own stat weights.",66,y+31,340,"small",C.dim)
  button("Export profile",26,y+67,123,function() code=L.profileCode();sharing=true;refresh(true) end)
  button("Import profile",158,y+67,123,function() sharing=true;refresh(true) end)
  button("Edit weights",290,y+67,125,function()
    editor={class=ctx.class,label="Custom",weights={},weapon={}}
    for k,v in pairs(p.weights) do editor.weights[k]=v end;for k,v in pairs(p.weapon) do editor.weapon[k]=v end
    refresh(true)
  end)
  U.surface(441,y,417,106,C.panel,C.edgeSoft)
  U.icon("inv_misc_gem_opal_01",455,y+13,28,"Item tooltips",nil):EnableMouse(false)
  line("Item tooltips",495,y+11,348,"body",C.gold)
  line("Show rank and estimated score change on gear.",495,y+31,348,"small",C.dim)
  local db=ns.db()
  button(db.noLootHints and "Loot tooltips: off" or "Loot tooltips: on",455,y+67,151,function()
    db.noLootHints=not db.noLootHints;refresh()
  end,not db.noLootHints)
  button(db.lootTooltipProfiles and "Other profile ranks: on" or "Other profile ranks: off",616,y+67,228,function()
    db.lootTooltipProfiles=not db.lootTooltipProfiles;refresh()
  end,db.lootTooltipProfiles,"Include the rankings from other talent profiles.").codexLabel="Show other profile ranks"
  return y+118
end
planningFields=function(y,ctx,x,w)
  local inner=x+14
  local fieldWidth=w-28
  y=text("Planning character",y+14,"head",C.gold,inner,fieldWidth)
  y=text("Class and faction",y+4,"small",C.dim,inner,fieldWidth)
  local half=math.floor((fieldWidth-8)/2)
  button(ctx.class,inner,y,half,function()
    local classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
    for i,class in ipairs(classes) do
      if class==ctx.class then
        preview=preview or {}
        preview.class=classes[i%#classes+1]
        break
      end
    end
    refresh()
  end,false,"Switch the class used for planning.")
  button(ctx.faction or "Unknown faction",inner+half+8,y,half,function()
    preview=preview or {}
    preview.faction=ctx.faction=="Alliance" and "Horde" or "Alliance"
    refresh()
  end)
  y=y+34
  line("Level (1-60)",inner,y+4,134,"small",C.dim)
  U.entry("LootPreviewLevel",inner+153,y,fieldWidth-155,tostring(ctx.level),nil,function(v)
    local n=tonumber(v)
    if n and n>=1 and n<=60 then
      preview=preview or {}
      preview.level=math.floor(n)
    else
      message="Use a level from 1 to 60"
    end
    refresh()
  end,2)
  y=y+34
  y=text("Baseline item link or ID",y,"small",C.dim,inner,fieldWidth)
  U.entry("LootBaseline",inner+4,y,fieldWidth-8,preview and preview.baselineText or "",function(v)
    preview=preview or {}
    preview.baselineText=v
  end,function(v)
    local key=L.itemKey(v)
    local item=key and L.item(key)
    if item and #L.slotsFor(item.slot)>0 then
      preview=preview or {}
      preview.snapshot={slots={},equipmentKnown=true}
      for _,n in ipairs(L.slotsFor(item.slot)) do preview.snapshot.slots[n]=item end
    else
      message="Enter a valid baseline equipment item"
    end
    refresh()
  end,2048)
  return text("Press Enter to apply a field.",y+33,"small",C.dim,inner,fieldWidth)
end

local function detailSidebar(y,ctx)
  local x,w=SIDE,WIDTH-SIDE-12
  local top=y
  y=text("Loot targets",y+14,"head",C.gold,x+14,w-28)
  local count=#L.targets("tracked")
  y=text(count==1 and "1 active target" or (count.." active targets"),y+4,"body",C.dim,x+14,w-28)
  button("Open tracked items",x+14,y+4,w-28,function() section="Tracked";message=nil;refresh(true) end)
  y=y+36
  line("Scoring profile",x+14,y+6,w-28,"small",C.dim)
  y=text(ctx.profile.label,y+24,"body",C.gold,x+14,w-28)
  U.surface(x,top,w,y+10-top,C.panel,C.edgeSoft)
  return y+10
end

local function render()
  palette()
  local ctx=context();local p=ctx.profile
  local mapPin=L.mapTarget and L.mapTarget()
  local browseStatus=message and section=="Upgrades" and view=="list" and message
  U.surface(4,6,WIDTH-8,52,Theme.eui and C.panel or C.ribbon,C.edgeSoft)
  if not Theme.eui then U.picture(ART.."loot-ribbon.tga",7,7,WIDTH-12,50) end
  U.rect(4,6,3,52,C.accent,"border")
  U.icon("inv_chest_plate04",16,14,36,"Loot journal",nil)
  line("Loot journal",65,10,200,"head",C.gold)
  local class=ctx.class and ctx.class:sub(1,1)..ctx.class:sub(2):lower() or "Character"
  line((ctx.preview and "Planning / " or "").."Level "..ctx.level.." "..class,65,35,200,"small",C.dim)
  if browseStatus then
    local y=mapPin and 11 or 26
    line(browseStatus,269,y,219,"small",C.gold,"RIGHT")
    action(269,y-2,219,16,browseStatus,nil)
  end
  if mapPin then
    button("Clear map pin",372,browseStatus and 28 or 21,116,function()
      L.clearMapTarget();message=nil;refresh()
    end,false,mapPin.label).codexLabel="Clear loot map target"
  end
  local count=#L.targets("tracked")
  for _,summary in ipairs({
    {x=WIDTH-370,w=200,icon="inv_misc_book_11",title="Scoring profile",value=p and p.label or "Unavailable",tab="Profiles",label="Scoring settings",
      tip="Change the stat priorities used for estimated gear scores and configure tooltip advice."},
    {x=WIDTH-162,w=150,icon="inv_misc_map_01",title="Loot targets",value=count.." active",tab="Tracked",label="View loot targets",
      tip="Review your saved upgrades and where to get them."},
  }) do
    U.surface(summary.x,12,summary.w,40,C.background,C.edgeSoft)
    U.rect(summary.x,12,summary.w,40,C.background,nil,3)
    U.icon(summary.icon,summary.x+8,20,24,summary.title,nil)
    line(summary.title,summary.x+42,15,summary.w-62,"small",C.dim)
    line(summary.value,summary.x+42,31,summary.w-62,"small",C.light)
    line(">",summary.x+summary.w-22,24,14,"small",C.accent)
    action(summary.x,12,summary.w,40,summary.title,summary.tip,function()
      section=summary.tab;message=nil;refresh(true)
    end,summary.label)
  end
  local tabArt={"inv_chest_plate04","inv_misc_gem_opal_01","inv_misc_bag_10","inv_misc_book_11"}
  local tabWidth=math.floor((WIDTH-8-3*6)/4)
  for i,label in ipairs({"Upgrades","Compare","Tracked","Profiles"}) do
    local x=4+(i-1)*(tabWidth+6);local on=section==label
    U.surface(x,66,tabWidth,28,on and C.btnOn or C.panel,on and C.accent or C.edgeSoft)
    if on then U.rect(x+5,91,tabWidth-10,2,C.accent,"border",1) end
    U.icon(tabArt[i],x+8,72,16,label,nil)
    line(label,x+32,72,tabWidth-42,"body",on and C.light or C.dim,"CENTER")
    local b=action(x,66,tabWidth,28,label,nil,function() section=label;message=nil;refresh(true) end,label);b.codexOn=on
  end
  local y=106
  if message and not browseStatus then y=text(message,y,"small",C.gold) end
  if not p then return text("Loot profiles are not available for this class.",y,"body",C.dim)+20 end
  local sideBottom
  if section=="Upgrades" then
    if view=="character" then y=character(y,ctx)
    elseif view=="detail" and upgradeDetail.ref then
      if upgradeDetail.page~="Sources" then sideBottom=detailSidebar(y,ctx) end
      y=details(upgradeDetail,y,ctx)
    elseif view=="slots" then y=slotPicker(y)
    elseif view=="filters" then y=filterPage(y,ctx)
    elseif view=="weapons" then y=weaponFilterPage(y,ctx)
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
    setDetail(ref,source)
    if section=="Compare" then input=tostring(ref);compareDetail.open=source~=nil end
  end
  ns.openTab("loot",true)
end
L.subscribe(function() if ns.refreshLootTab then ns.refreshLootTab(true) end end)
