local _, ns = ...
local L=ns.loot
L.sourceNames={quest="Quest reward",boss="Boss drop",dungeonTrash="Dungeon drop",raidTrash="Raid drop",creature="Creature drop",
  rare="Rare creature",object="Chest / object",world="World drop",vendor="Vendor",craft="Crafted",reputation="Reputation",pvp="PvP"}
-- UI choices name physical equipment categories, which can accept several inventory types.
local CATEGORY_TYPES={
  INVTYPE_CHEST={"INVTYPE_CHEST","INVTYPE_ROBE"},
  INVTYPE_WEAPON={"INVTYPE_WEAPON","INVTYPE_WEAPONMAINHAND","INVTYPE_2HWEAPON"},
  INVTYPE_WEAPONOFFHAND={"INVTYPE_WEAPON","INVTYPE_WEAPONOFFHAND","INVTYPE_SHIELD","INVTYPE_HOLDABLE"},
  INVTYPE_RANGED={"INVTYPE_RANGED","INVTYPE_RANGEDRIGHT","INVTYPE_THROWN"},
}
L.weaponFamilies={
  {"Axes",{[0]=true,[1]=true}}, {"Maces",{[4]=true,[5]=true}}, {"Swords",{[7]=true,[8]=true}},
  {"Daggers",{[15]=true}}, {"Fist weapons",{[13]=true}}, {"Polearms",{[6]=true}}, {"Staves",{[10]=true}},
  {"Bows",{[2]=true}}, {"Guns",{[3]=true}}, {"Crossbows",{[18]=true}}, {"Thrown",{[16]=true}}, {"Wands",{[19]=true}},
}
function L.prefersShield(ctx)
  return ctx.profile and ctx.profile.role=="Tank" and (ctx.class=="WARRIOR" or ctx.class=="PALADIN")
end
function L.weaponStyle(filters,ctx)
  if filters.weaponStyle then return filters.weaponStyle end
  if filters.slot=="INVTYPE_WEAPON" and L.prefersShield(ctx) then return "shield" end
  return "all"
end
local function matchesWeapon(item,style,family)
  if style=="shield" and item.slot=="INVTYPE_2HWEAPON" then return false end
  if style=="twohand" and item.slot~="INVTYPE_2HWEAPON" then return false end
  if family=="Shields" then return item.slot=="INVTYPE_SHIELD" end
  if family=="Held items" then return item.slot=="INVTYPE_HOLDABLE" end
  return not family or item.classID==2 and family[item.subclassID]==true
end
local RANK_CATEGORY={}
for group,types in pairs(CATEGORY_TYPES) do
  if group~="INVTYPE_WEAPONOFFHAND" then
    for _,kind in ipairs(types) do RANK_CATEGORY[kind]=group end
  end
end
RANK_CATEGORY.INVTYPE_SHIELD="INVTYPE_WEAPONOFFHAND"
RANK_CATEGORY.INVTYPE_HOLDABLE="INVTYPE_WEAPONOFFHAND"

local rankVersion,rankScores
local function availableForRank(item,ctx)
  if (item.requiredLevel or 0)>ctx.level then return false end
  return #L.sources(item.id,{accessLevel=ctx.level},ctx)>0
end
function L.catalogRank(item,ctx,result)
  local data=ns.lootData
  if not (data and data.items[item.id] and item.slot and ctx.profile
    and result.confidence=="complete" and type(result.delta)=="number") then return end
  if not availableForRank(data.items[item.id],ctx) then return end
  if rankVersion~=L.version then rankVersion=L.version;rankScores={} end
  local category=RANK_CATEGORY[item.slot] or item.slot
  local key=ctx.profile.key.."/"..category
  local scores=rankScores[key]
  if not scores then
    scores={}
    for _,kind in ipairs(CATEGORY_TYPES[category] or {category}) do
      for _,id in ipairs(data.bySlot[kind] or {}) do
        local peer=data.items[id]
        if availableForRank(peer,ctx) then
          local comparison=L.compare(peer,ctx)
          if comparison.confidence=="complete" then scores[id]=comparison.delta end
        end
      end
    end
    rankScores[key]=scores
  end
  local rank=1
  for id,delta in pairs(scores) do
    if id~=item.id and delta>result.delta+0.001 then rank=rank+1 end
  end
  return rank
end
local function sourceCategory(s,raids)
  if s.type=="boss" then return raids[s.instance] and "raidTrash" or "dungeonTrash" end
  return s.type
end
local function sourceAllowed(s,f,c,raids)
  if s.faction and s.faction~="All" and s.faction~=c.faction then return false end
  if f.source and f.source~="all" and s.type~=f.source then return false end
  if f.sources and not f.sources[sourceCategory(s,raids)] then return false end
  if f.zone and f.zone~="" and not (s.zone or ""):lower():find(f.zone:lower(),1,true) then return false end
  if f.dungeon and f.dungeon~="" and not (s.dungeon or ""):lower():find(f.dungeon:lower(),1,true) then return false end
  if f.profession and f.profession~="" and s.profession~=f.profession then return false end
  if f.style=="solo" and (s.type=="boss" or s.type=="dungeonTrash" or s.type=="raidTrash" or s.group) then return false end
  if f.style=="group" and not (s.instance or s.group) then return false end
  if f.style=="buy" and not (s.type=="vendor" or s.type=="craft" or s.type=="reputation" or s.type=="pvp") then return false end
  return true
end

local function sourceLevel(source,item,ctx,access)
  local required=source.requiredLevel
  if source.type=="raidTrash" or (access.raids or {})[source.instance] then
    return math.max(60,required or 0)
  end
  local enemyLevel=(access.creatures or {})[source.npc]
  local combatLevel=enemyLevel and math.max(1,enemyLevel-3)
  local guideLevel=(access.instances or {})[source.instance]
  if source.instance and (source.type=="boss" or source.type=="dungeonTrash") then
    if not combatLevel and source.object then return required end
    if guideLevel or combatLevel then return math.max(guideLevel or 1,combatLevel or 1,required or 1) end
  end
  if (source.type=="creature" or source.type=="rare") and combatLevel then
    return math.max(combatLevel,required or 1)
  end
  if source.type=="vendor" then
    local r=item.restrictions or {}
    if r.text or r.reputation and (not ctx.reputation or (ctx.reputation[r.reputation] or 0)<(r.standing or 0))
      or r.skill and (not ctx.professions or (ctx.professions[r.skill] or 0)<(r.skillRank or 1)) then return end
    if source.npc and source.map then
      return math.max((access.zones or {})[source.map] or 1,required or 1)
    end
  end
  if source.type=="craft" and source.recipe
    and (item.tradable or not ctx.preview and L.call(IsPlayerSpell,source.recipe)) then
    return math.max(1,required or 0)
  end
  return required
end

function L.sources(id,filters,ctx)
  local data=ns.lootData or {}; local it=data.items and data.items[id]
  local access=data.access or {}
  local raids=access.raids or {}
  ctx=ctx or L.context()
  filters=filters or {}
  local out,earliest,unknown={}
  for _,key in ipairs(it and it.sourceIDs or {}) do
    local s=data.sources[key]
    if s and sourceAllowed(s,filters,ctx,raids) then
      if not filters.accessLevel then
        out[#out+1]=s
      else
        local level=sourceLevel(s,it,ctx,access)
        if level==nil then unknown=true
        elseif level<=filters.accessLevel then
          out[#out+1]=s
          earliest=math.min(earliest or level,level)
        end
      end
    end
  end
  table.sort(out,function(a,b) return a.id<b.id end)
  return out,earliest,unknown
end
local ROUTE_ORDER={quest=1,vendor=2,craft=3,reputation=4,boss=5,rare=6,creature=7,
  object=8,dungeonTrash=9,raidTrash=10,pvp=11,world=12}
function L.targetSource(target,ctx)
  local data=ns.lootData
  if target.sourceID then
    local source=data and data.sources[target.sourceID]
    return source and source.item==target.id and source or nil,0
  end
  ctx=ctx or L.context()
  local available=L.sources(target.id,{accessLevel=ctx.level},ctx)
  local sources=#available>0 and available or L.sources(target.id,nil,ctx)
  local best
  for _,source in ipairs(sources) do
    if not best or (ROUTE_ORDER[source.type] or 99)<(ROUTE_ORDER[best.type] or 99) then best=source end
  end
  return best,math.max(0,#sources-1)
end

function L.sourceLocation(source)
  local profession=source.profession
  return source.dungeon or source.zone or (profession and profession:sub(1,1)..profession:sub(2):lower())
end

function L.questRoute(source)
  local facts=ns.lootData and ns.lootData.questFacts
  local steps,seen={},{}
  local id=source and source.quest
  while id and facts and facts[id] and not seen[id] and #steps<24 do
    local q=facts[id]
    table.insert(steps,1,q);seen[id]=true
    if #q.previous~=1 then return steps,#q.previous==0 end
    id=q.previous[1]
  end
  return steps,false
end

function L.questContact(quest,turnIn,faction)
  local contacts=quest and (turnIn and quest.finish or quest.start) or {}
  local current=L.call(C_Map and C_Map.GetBestMapForUnit,"player")
  local capital=faction=="Alliance" and 1453 or faction=="Horde" and 1454
  local best
  for _,where in ipairs(contacts) do
    if not where.faction or where.faction==faction then
      if where.map and where.map==current then return where end
      if not best or where.map and (not best.map or where.map==capital) then best=where end
    end
  end
  return best
end

function L.candidates(filters,ctx,offset,limit)
  local data=ns.lootData or {}; local f=filters or {}; ctx=ctx or L.context()
  local query=(f.search or ""):lower(); local rows={}
  local sourceFilters={}
  for k,v in pairs(f) do sourceFilters[k]=v end
  sourceFilters.accessLevel=f.maxLevel or ctx.level
  local all={}
  if f.slot then
    local seen={}
    for _,kind in ipairs(CATEGORY_TYPES[f.slot] or {f.slot}) do
      for _,id in ipairs(data.bySlot and data.bySlot[kind] or {}) do
        if not seen[id] then all[#all+1]=data.items[id];seen[id]=true end
      end
    end
  else for _,it in pairs(data.items or {}) do all[#all+1]=it end end
  local sourceFiltered=f.sources or (f.source and f.source~="all") or f.zone and f.zone~="" or f.dungeon and f.dungeon~="" or f.profession and f.profession~="" or f.style and f.style~="all"
  local style=L.weaponStyle(f,ctx)
  local family
  if f.weaponType=="Shields" or f.weaponType=="Held items" then family=f.weaponType
  elseif f.weaponType then
    for _,entry in ipairs(L.weaponFamilies) do if entry[1]==f.weaponType then family=entry[2];break end end
  end
  for _,it in ipairs(all) do
    if (it.requiredLevel or 0)<=(f.maxLevel or ctx.level) and (it.requiredLevel or 0)>=(f.minLevel or 0)
      and matchesWeapon(it,style,family)
      and (query=="" or tostring(it.id)==query or it.name:lower():find(query,1,true)) then
      local sources,earliest,unknown=L.sources(it.id,sourceFilters,ctx)
      local unverified=#sources==0 and f.showUnverified
        and (unknown or not sourceFiltered and #(it.sourceIDs or {})==0)
      if #sources>0 or unverified then
        -- Offline catalog comparisons avoid item requests; only an opened detail reads the live item.
        local r=L.compare(it,ctx,nil,f.weaponSlot)
        local level=math.max(it.requiredLevel or 0,earliest or 0)
        local future=level>ctx.level
        local needsLevel=(it.requiredLevel or 0)>ctx.level
        if f.showIneligible or r.verdict~="cannotEquip" or needsLevel then
          local rank=0
          for _,s in ipairs(sources) do
            if s.map and s.map==L.call(C_Map and C_Map.GetBestMapForUnit,"player") then rank=rank+2 end
            if s.quest and ns.quests and ns.quests.log and ns.quests.log(s.quest) then rank=rank+1 end
          end
          rows[#rows+1]={item=it,result=r,sources=sources,acquisition=rank,futureLevel=future and level or nil,
            availabilityUnverified=unverified}
        end
      end
    end
  end
  local order={upgrade=1,sidegrade=2,needsReview=3,loading=4,downgrade=5,cannotEquip=6}
  table.sort(rows,function(a,b)
    if (a.availabilityUnverified==true)~=(b.availabilityUnverified==true) then return not a.availabilityUnverified end
    if f.sort=="acquisition" and a.acquisition~=b.acquisition then return a.acquisition>b.acquisition end
    local x,y=order[a.result.verdict] or 9,order[b.result.verdict] or 9
    if x~=y then return x<y end
    local da=a.result.delta or (a.result.future and a.result.future.delta) or -math.huge
    local db=b.result.delta or (b.result.future and b.result.future.delta) or -math.huge
    if da~=db then return da>db end
    if a.item.name~=b.item.name then return a.item.name<b.item.name end
    return a.item.id<b.item.id
  end)
  local page={}; offset=math.max(0,offset or 0); limit=math.min(100,math.max(1,limit or 20))
  for i=offset+1,math.min(#rows,offset+limit) do page[#page+1]=rows[i] end
  return {rows=page,total=#rows}
end
function L.enchants(ref,ctx)
  local item=type(ref)=="table" and ref or L.item(ref); if not item then return {} end
  ctx=ctx or L.context(); local out={}
  for _,e in pairs(ns.lootData and ns.lootData.enchants or {}) do
    if e.slots and e.slots[item.slot] and (e.level or 0)<=ctx.level then
      local score=L.score(e,ctx.profile)
      out[#out+1]={enchant=e,score=score.value or 0,reason=score.complete and "Advisory enchant value; compare with your current enchant" or "Review the enchant effect"}
    end
  end
  table.sort(out,function(a,b) if a.score~=b.score then return a.score>b.score end; return a.enchant.name<b.enchant.name end)
  return out
end
