local _, ns = ...
local L,U,C=ns.loot,ns.ui,ns.C
local section="Upgrades"
local filters={slot="INVTYPE_CHEST",source="all",style="all",search=""}
local offset,sourceOffset=0,0
local selected,input,message,code,editor,preview
local SLOT_TYPES={"INVTYPE_HEAD","INVTYPE_NECK","INVTYPE_SHOULDER","INVTYPE_CHEST","INVTYPE_WAIST","INVTYPE_LEGS","INVTYPE_FEET",
  "INVTYPE_WRIST","INVTYPE_HAND","INVTYPE_FINGER","INVTYPE_TRINKET","INVTYPE_CLOAK","INVTYPE_WEAPON","INVTYPE_WEAPONOFFHAND","INVTYPE_RANGED","INVTYPE_RELIC"}
local function refresh() if ns.refreshLootTab then ns.refreshLootTab() end end
local function button(label,x,y,w,fn,on,tip)
  local b=U.btn(ns.plain(label),x,y,w,fn,on,tip); b.codexLabel=ns.plain(label); return b
end
local function text(s,y,kind,color)
  return y+U.T(ns.plain(s),12,y,U.W-24,kind or "body",color or C.light)+7
end
local function choose(ref) selected=ref;sourceOffset=0;message=nil; refresh() end
local function cycle(list,current)
  for i,v in ipairs(list) do if v==current then return list[i%#list+1] end end
  return list[1]
end
local function context() return L.context(preview) end
local function details(ref,y)
  local cardTop=y-4
  local it=L.item(ref)
  if not it then return text("Enter a valid item link or item ID.",y) end
  local ctx=context(); local r=L.compare(it,ctx)
  L.lastComparison=it.name..": "..(L.labels[r.verdict] or r.verdict).." - "..r.reason
  U.icon(it.icon,12,y,38,it.name,r.reason)
  U.T(ns.plain(it.name),60,y,U.W-80,"head",C.gold);y=y+44
  local score=r.percent and string.format(" (%+.1f%% estimated gear score)",r.percent) or ""
  y=text((L.labels[r.verdict] or r.verdict)..score,y,"body",r.verdict=="upgrade" and C.accent or C.gold)
  y=text(r.reason,y,"small",C.dim)
  if r.score then y=text(string.format("Estimated gear score: %.1f vs %.1f",r.score,r.baselineScore or 0),y,"small",C.dim) end
  local names={}
  for _,slot in ipairs(r.replacedSlots) do names[#names+1]=L.slotNames[slot] or tostring(slot) end
  if #names>0 then y=text("Replaces: "..table.concat(names,", "),y,"small") end
  for _,old in ipairs(r.baseline) do y=text("Equipped: "..old.name,y,"small",C.dim) end
  local keys={};for k,n in pairs(r.statDelta) do if n~=0 then keys[#keys+1]=k end end;table.sort(keys)
  local changes={};for _,k in ipairs(keys) do changes[#changes+1]=string.format("%s %+.1f",k,r.statDelta[k]) end
  if #changes>0 then y=text(table.concat(changes,"  |  "),y,"small") end
  for _,warning in ipairs(r.warnings) do y=text(warning,y,"small",C.gold) end
  button("Track this item",12,y,160,function() local k,err=L.track(it.key);message=err or (k and "Target tracked");refresh() end)
  button("Compare this item",184,y,160,function() input=it.key;section="Compare";refresh() end)
  y=y+34
  y=y+U.sectionTitle("Where to get it",y)
  local sources=L.sources(it.id,nil,ctx)
  if #sources==0 then y=text("No verified acquisition source in this catalog. Check the item in game.",y,"small",C.dim) end
  for i=sourceOffset+1,math.min(#sources,sourceOffset+6) do
    local s=sources[i]
    local label=(L.sourceNames[s.type] or s.type)..": "..(s.name or "Unknown source")
    if s.dungeon then label=label.." - "..s.dungeon elseif s.zone then label=label.." - "..s.zone end
    y=text(label,y,"body",C.gold)
    if s.giverName then y=text("Starts with "..s.giverName,y,"small") end
    if s.requiredLevel then y=text("Source requires level "..s.requiredLevel,y,"small") end
    if s.locationKind=="entrance" then y=text("Map location: dungeon entrance, not the boss room.",y,"small",C.dim) end
    if s.prerequisites and #s.prerequisites>0 then y=text("Prerequisite quests: "..table.concat(s.prerequisites,", "),y,"small",C.dim) end
    if s.cost then y=text("Cost: "..(ns.money and ns.money(s.cost) or tostring(s.cost)),y,"small") end
    if s.materials then
      local mats={};for name,n in pairs(s.materials) do mats[#mats+1]=n.." "..name end;table.sort(mats)
      y=text("Materials: "..table.concat(mats,", "),y,"small")
    end
    y=text(s.evidence=="client" and "Client reference" or "Database reference; server availability may vary",y,"small",C.dim)
    button("Track source "..i,12,y,150,function() L.track(it.key,s.id);message="Source tracked";refresh() end)
    if s.map and L.showSourceOnMap then button("Map source "..i,170,y,150,function() local ok,why=L.showSourceOnMap(s.id);message=why;refresh() end)
    else U.T("Location not verified",170,y+4,U.W-180,"small",C.dim) end
    if s.quest and L.openQuestSource then button("Quest guide "..i,330,y,150,function() L.openQuestSource(s.quest) end) end
    y=y+34
  end
  if #sources>6 then button("More sources",12,y,150,function() sourceOffset=(sourceOffset+6)%#sources;refresh() end);y=y+32 end
  if it.tradable then y=text("Tradable: another player or the auction house may have it. Price unknown.",y,"small",C.dim) end
  local enchants=L.enchants(it,ctx)
  if #enchants>0 then
    y=y+U.sectionTitle("Enchant options",y)
    for i=1,math.min(3,#enchants) do
      local a=enchants[i]; y=text(a.enchant.name..": "..a.reason,y,"small")
      y=text(a.enchant.source or "Ask an enchanter; acquisition requirements may vary.",y,"small",C.dim)
      if a.enchant.plan then y=text("Formula: "..a.enchant.plan.item.." (Enchanting "..tostring(a.enchant.plan.skill or "unknown")..")",y,"small",C.dim) end
      local mats={};for name,n in pairs(a.enchant.materials or {}) do mats[#mats+1]=n.." "..name end;table.sort(mats)
      if #mats>0 then y=text(table.concat(mats,", "),y,"small",C.dim) end
    end
    button("Enchanting guide",12,y,220,function() if ns.profTabShow then ns.profTabShow("ENCHANTING") end;ns.openTab("professions") end);y=y+32
  end
  U.box(0,cardTop,U.W,y-cardTop+4,C.panel,C.edge)
  return y+12
end
local function render()
  local ctx=context();local p=ctx.profile
  local y=12
  y=y+12
  y=text("Loot",y,"head",C.ink)
  y=text((ctx.preview and "Planning: " or "Your gear: ")..ctx.class.." - Level "..ctx.level.." - "..(p and p.label or "No profile"),y,"body",C.ink)
  y=text("Estimated gear score is advisory. Check the stat tradeoffs and unscored effects.",y,"small",C.inkSoft)
  U.box(0,12,U.W,y-6,C.parch,C.edge);y=y+16
  U.segments(0,y,U.W,{"Upgrades","Compare","Tracked","Profiles"},({Upgrades=1,Compare=2,Tracked=3,Profiles=4})[section],function(i)
    section=({"Upgrades","Compare","Tracked","Profiles"})[i];message=nil;refresh()
  end);y=y+36
  if message then y=text(message,y,"small",C.gold) end
  if not p then return text("Loot profiles are not available for this class.",y,"body",C.dim)+20 end
  if L.mapTarget and L.mapTarget() then
    button("Clear loot map target",12,y,260,function() L.clearMapTarget();refresh() end);y=y+32
  end
  if section=="Upgrades" then
    local slots={"Head","Neck","Shoulder","Chest","Waist","Legs","Feet","Wrist","Hands","Rings","Trinkets","Back","Main hand","Off hand","Ranged","Relic"}
    for i,label in ipairs(slots) do
      local k=SLOT_TYPES[i]
      button(label,((i-1)%6)*94,y+math.floor((i-1)/6)*27,90,function() filters.slot=k;offset=0;selected=nil;refresh() end,filters.slot==k)
    end
    y=y+90
    U.entry("LootSearch",12,y,350,filters.search,function(v) filters.search=v end,function() offset=0;refresh() end,80)
    button("Search",380,y,160,function() offset=0;refresh() end);y=y+32
    local sourceKeys={"all","quest","boss","dungeonTrash","raidTrash","creature","rare","object","world","vendor","craft","reputation","pvp"}
    button("Source: "..(L.sourceNames[filters.source] or "All"),12,y,260,function() filters.source=cycle(sourceKeys,filters.source);offset=0;refresh() end)
    button("Style: "..filters.style,284,y,260,function() filters.style=cycle({"all","solo","group","buy"},filters.style);offset=0;refresh() end);y=y+30
    button(filters.showIneligible and "Hide ineligible" or "Show ineligible",12,y,170,function() filters.showIneligible=not filters.showIneligible;refresh() end)
    button(filters.sort=="acquisition" and "Sort by power" or "Sort by access",190,y,170,function() filters.sort=filters.sort=="acquisition" and nil or "acquisition";refresh() end)
    button("Plan level "..(filters.maxLevel or ctx.level),370,y,174,function() filters.maxLevel=(filters.maxLevel or ctx.level)>=60 and ctx.level or math.min(60,(filters.maxLevel or ctx.level)+5);offset=0;refresh() end);y=y+34
    U.T("Zone / dungeon / profession (optional)",12,y,U.W-24,"small",C.dim);y=y+22
    U.entry("LootZone",12,y,170,filters.zone or "",function(v) filters.zone=v end,function() offset=0;refresh() end,80)
    U.entry("LootDungeon",195,y,170,filters.dungeon or "",function(v) filters.dungeon=v end,function() offset=0;refresh() end,80)
    U.entry("LootProfession",378,y,166,filters.profession or "",function(v) filters.profession=v:upper() end,function() offset=0;refresh() end,40);y=y+34
    local page=L.candidates(filters,ctx,offset,10)
    y=text(page.total.." matching items",y,"small",C.dim)
    for _,row in ipairs(page.rows) do
      local it,r=row.item,row.result
      U.icon(it.icon,12,y,28,it.name,r.reason)
      button(it.name..(row.futureLevel and (" (level "..row.futureLevel..")") or ""),48,y,310,function() choose(it.id) end,selected==it.id)
      U.T(L.labels[r.verdict],370,y+4,174,"small",r.verdict=="upgrade" and C.accent or C.dim)
      y=y+32
    end
    if offset>0 then button("Previous loot page",12,y,190,function() offset=math.max(0,offset-10);refresh() end) end
    if offset+10<page.total then button("Next loot page",220,y,190,function() offset=offset+10;refresh() end) end
    y=y+34
    if selected then y=details(selected,y) end
  elseif section=="Compare" then
    y=text("Paste an item link or item ID",y,"body",C.gold)
    U.entry("LootItem",12,y,370,input or "",function(v) input=v end,function(v) selected=L.itemKey(v);message=not selected and "Enter a valid item link or item ID." or nil;refresh() end,2048)
    button("Check item",400,y,144,function() selected=L.itemKey(input);message=not selected and "Enter a valid item link or item ID." or nil;refresh() end);y=y+34
    button("Live character",12,y,170,function() preview=nil;refresh() end)
    button("Preview class",192,y,170,function()
      local list={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
      preview=preview or {};preview.class=cycle(list,preview.class or ctx.class);selected=nil;refresh()
    end)
    button("Preview faction",372,y,172,function() preview=preview or {};preview.faction=ctx.faction=="Alliance" and "Horde" or "Alliance";refresh() end);y=y+32
    U.entry("LootPreviewLevel",12,y,100,tostring(ctx.level),nil,function(v) local n=tonumber(v);if n and n>=1 and n<=60 then preview=preview or {};preview.level=math.floor(n) else message="Use a level from 1 to 60" end;refresh() end,2)
    U.entry("LootBaseline",132,y,412,preview and preview.baselineText or "",function(v) preview=preview or {};preview.baselineText=v end,function(v)
      local key=L.itemKey(v);if key then
        local it=L.item(key);local slots=L.slotsFor(it.slot);preview=preview or {};preview.snapshot={slots={},equipmentKnown=true}
        for _,n in ipairs(slots) do preview.snapshot.slots[n]=it end
      else message="Enter a valid baseline item link" end;refresh()
    end,2048);y=y+34
    y=text("Preview baseline: paste an item above. Other unknown slots remain unverified.",y,"small",C.dim)
    if selected then y=details(selected,y) end
    y=y+U.sectionTitle("Equipped and bag items",y)
    local snapshot=L.snapshot()
    for _,n in ipairs(L.slotOrder) do
      local it=snapshot.slots[n]
      if it then local link=it.key;button(L.slotNames[n]..": "..it.name,12,y,U.W-24,function() input=link;choose(link) end);y=y+27 end
    end
    local keys={};for key in pairs(snapshot.bagLinks) do keys[#keys+1]=key end;table.sort(keys)
    for i=1,math.min(#keys,40) do local key=keys[i];local it=L.item(key);if it then button("Bag: "..it.name,12,y,U.W-24,function() input=key;choose(key) end);y=y+27 end end
  elseif section=="Tracked" then
    local list=L.targets()
    if #list==0 then y=text("Choose an item or source and press Track to plan an upgrade.",y,"body",C.dim) end
    for _,t in ipairs(list) do
      button(t.name.." - "..t.state,12,y,330,function() selected=t.ref;section="Compare";refresh() end)
      button(t.state=="tracked" and "Dismiss" or "Restore",350,y,90,function() L.setTargetState(t.key,t.state=="tracked" and "dismissed" or "tracked");refresh() end)
      button("Untrack",450,y,94,function() L.untrack(t.key);refresh() end);y=y+30
      if t.sourceID and L.showSourceOnMap then button("Map "..t.name,12,y,330,function() local ok,why=L.showSourceOnMap(t.sourceID);message=why;refresh() end);y=y+30 end
    end
  else
    y=text("Automatic follows your talent path. Manual choices change loot advice only.",y,"small",C.dim)
    button("Follow talent path",12,y,250,function() L.resetProfile();editor=nil;refresh() end)
    button("Export profile",284,y,260,function() code=L.profileCode();refresh() end);y=y+34
    for _,p0 in ipairs((ns.TALENT_PATHS or {})[ctx.class] or {}) do
      button(p0.spec,12,y,U.W-24,function()
        if ctx.preview then preview=preview or {};preview.profileKey=p0.key else L.setProfile(p0.key) end
        editor=nil;refresh()
      end,p0.key==p.key);y=y+27
    end
    U.entry("LootProfileCode",12,y,U.W-24,code or "",function(v) code=v end,function(v) local ok,err=L.readProfileCode(v);message=ok and "Profile imported" or err;editor=nil;refresh() end,4096);y=y+32
    button("Import profile",12,y,250,function() local ok,err=L.readProfileCode(code or "");message=ok and "Profile imported" or err;editor=nil;refresh() end)
    button("Edit weights",284,y,260,function()
      editor={class=ctx.class,label="Custom",weights={},weapon={}}
      for k,v in pairs(p.weights) do editor.weights[k]=v end;for k,v in pairs(p.weapon) do editor.weapon[k]=v end;refresh()
    end);y=y+34
    if editor then
      local keys={};for k in pairs(L.profileStatKeys) do keys[#keys+1]=k end;table.sort(keys)
      for _,k in ipairs(keys) do
        U.T(k,12,y+4,210,"small",C.dim)
        U.entry("LootWeight"..k,230,y,170,tostring(editor.weights[k] or 0),function(v) editor.weights[k]=v end,nil,16);y=y+27
      end
      for _,k in ipairs({"melee","ranged","speed"}) do
        U.T("Weapon "..k,12,y+4,210,"small",C.dim)
        U.entry("LootWeapon"..k,230,y,170,tostring(editor.weapon[k] or 0),function(v) editor.weapon[k]=v end,nil,16);y=y+27
      end
      button(editor.weapon.feral and "Feral policy: on" or "Feral policy: off",12,y,260,function() editor.weapon.feral=not editor.weapon.feral;refresh() end);y=y+30
      button("Save weights",12,y,250,function()
        for k,v in pairs(editor.weights) do editor.weights[k]=tonumber(v) or -1 end
        for _,k in ipairs({"melee","ranged","speed"}) do editor.weapon[k]=tonumber(editor.weapon[k]) or 0 end
        local ok,err=L.setProfile(editor);message=ok and "Custom weights saved" or err;if ok then editor=nil end;refresh()
      end);y=y+32
    end
  end
  return y+20
end
ns.addTab("loot","Loot",render)
function L.open(want,ref)
  if want then section=want end;if ref then selected=ref;input=tostring(ref) end
  ns.openTab("loot")
end
L.subscribe(function() if ns.refreshLootTab then ns.refreshLootTab() end end)
