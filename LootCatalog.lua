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
local RANK_CATEGORY={}
for group,types in pairs(CATEGORY_TYPES) do
  if group~="INVTYPE_WEAPONOFFHAND" then
    for _,kind in ipairs(types) do RANK_CATEGORY[kind]=group end
  end
end
RANK_CATEGORY.INVTYPE_SHIELD="INVTYPE_WEAPONOFFHAND"
RANK_CATEGORY.INVTYPE_HOLDABLE="INVTYPE_WEAPONOFFHAND"

local rankVersion,rankScores
local function availableForRank(item,data,ctx)
  if (item.requiredLevel or 0)>ctx.level then return false end
  local routes=item.sourceIDs or {}
  if item.tradable or #routes==0 then return true end
  for _,id in ipairs(routes) do
    local source=data.sources[id]
    if source and (source.requiredLevel or 0)<=ctx.level
      and (not source.faction or source.faction=="All" or source.faction==ctx.faction) then return true end
  end
  return false
end
function L.catalogRank(item,ctx,result)
  local data=ns.lootData
  if not (data and data.items[item.id] and item.slot and ctx.profile
    and result.confidence=="complete" and type(result.delta)=="number") then return end
  if not availableForRank(data.items[item.id],data,ctx) then return end
  if rankVersion~=L.version then rankVersion=L.version;rankScores={} end
  local category=RANK_CATEGORY[item.slot] or item.slot
  local key=ctx.profile.key.."/"..category
  local scores=rankScores[key]
  if not scores then
    scores={}
    for _,kind in ipairs(CATEGORY_TYPES[category] or {category}) do
      for _,id in ipairs(data.bySlot[kind] or {}) do
        local peer=data.items[id]
        if availableForRank(peer,data,ctx) then
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
local function sourceAllowed(s,f,c)
  if f.accessLevel and (s.requiredLevel or 0)>f.accessLevel then return false end
  if s.faction and s.faction~="All" and s.faction~=c.faction then return false end
  if f.source and f.source~="all" and s.type~=f.source then return false end
  if f.zone and f.zone~="" and not (s.zone or ""):lower():find(f.zone:lower(),1,true) then return false end
  if f.dungeon and f.dungeon~="" and not (s.dungeon or ""):lower():find(f.dungeon:lower(),1,true) then return false end
  if f.profession and f.profession~="" and s.profession~=f.profession then return false end
  if f.style=="solo" and (s.type=="boss" or s.type=="dungeonTrash" or s.type=="raidTrash" or s.group) then return false end
  if f.style=="group" and not (s.instance or s.group) then return false end
  if f.style=="buy" and not (s.type=="vendor" or s.type=="craft" or s.type=="reputation" or s.type=="pvp") then return false end
  return true
end
function L.sources(id,filters,ctx)
  local data=ns.lootData or {}; local it=data.items and data.items[id]
  ctx=ctx or L.context()
  local out={}
  for _,key in ipairs(it and it.sourceIDs or {}) do
    local s=data.sources[key]
    if s and sourceAllowed(s,filters or {},ctx) then out[#out+1]=s end
  end
  table.sort(out,function(a,b) return a.id<b.id end)
  return out
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
  local sourceFiltered=(f.source and f.source~="all") or f.zone and f.zone~="" or f.dungeon and f.dungeon~="" or f.profession and f.profession~="" or f.style and f.style~="all"
  for _,it in ipairs(all) do
    if (it.requiredLevel or 0)<=(f.maxLevel or ctx.level) and (it.requiredLevel or 0)>=(f.minLevel or 0)
      and (query=="" or tostring(it.id)==query or it.name:lower():find(query,1,true)) then
      local sources=L.sources(it.id,sourceFilters,ctx)
      if #sources>0 or not sourceFiltered and (#(it.sourceIDs or {})==0 or it.tradable) then
        -- Offline catalog comparisons avoid item requests; only an opened detail reads the live item.
        local r=L.compare(it,ctx)
        local future=(f.maxLevel or ctx.level)>ctx.level and (it.requiredLevel or 0)>ctx.level
        if f.showIneligible or r.verdict~="cannotEquip" or future then
          local rank=0
          for _,s in ipairs(sources) do
            if s.map and s.map==L.call(C_Map and C_Map.GetBestMapForUnit,"player") then rank=rank+2 end
            if s.quest and ns.quests and ns.quests.log and ns.quests.log(s.quest) then rank=rank+1 end
          end
          rows[#rows+1]={item=it,result=r,sources=sources,acquisition=rank,futureLevel=future and it.requiredLevel or nil}
        end
      end
    end
  end
  local order={upgrade=1,sidegrade=2,needsReview=3,loading=4,downgrade=5,cannotEquip=6}
  table.sort(rows,function(a,b)
    if f.sort=="acquisition" and a.acquisition~=b.acquisition then return a.acquisition>b.acquisition end
    local x,y=order[a.result.verdict] or 9,order[b.result.verdict] or 9
    if x~=y then return x<y end
    if (a.result.delta or -math.huge)~=(b.result.delta or -math.huge) then return (a.result.delta or -math.huge)>(b.result.delta or -math.huge) end
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
