local _, ns = ...
local L=ns.loot
L.sourceNames={quest="Quest reward",boss="Boss drop",dungeonTrash="Dungeon drop",raidTrash="Raid drop",creature="Creature drop",
  rare="Rare creature",object="Chest / object",world="World drop",vendor="Vendor",craft="Crafted",reputation="Reputation",pvp="PvP"}
local function sourceAllowed(s,f,c)
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
function L.candidates(filters,ctx,offset,limit)
  local data=ns.lootData or {}; local f=filters or {}; ctx=ctx or L.context()
  local query=(f.search or ""):lower(); local rows={}
  local pool=f.slot and data.bySlot and data.bySlot[f.slot] or nil
  local all={}
  if pool then for _,id in ipairs(pool) do all[#all+1]=data.items[id] end
  elseif f.slot then return {rows={},total=0}
  else for _,it in pairs(data.items or {}) do all[#all+1]=it end end
  local sourceFiltered=(f.source and f.source~="all") or f.zone and f.zone~="" or f.dungeon and f.dungeon~="" or f.profession and f.profession~="" or f.style and f.style~="all"
  for _,it in ipairs(all) do
    if (it.requiredLevel or 0)<=(f.maxLevel or ctx.level) and (it.requiredLevel or 0)>=(f.minLevel or 0)
      and (query=="" or tostring(it.id)==query or it.name:lower():find(query,1,true)) then
      local sources=L.sources(it.id,f,ctx)
      if #sources>0 or not sourceFiltered and (#(it.sourceIDs or {})==0 or it.tradable) then
        -- Offline catalog comparisons avoid item requests; only an opened detail reads the live item.
        local r=L.compare(it,ctx)
        if f.showIneligible or r.verdict~="cannotEquip" then
          local rank=0
          for _,s in ipairs(sources) do
            if s.map and s.map==L.call(C_Map and C_Map.GetBestMapForUnit,"player") then rank=rank+2 end
            if s.quest and ns.quests and ns.quests.log and ns.quests.log(s.quest) then rank=rank+1 end
          end
          rows[#rows+1]={item=it,result=r,sources=sources,acquisition=rank}
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
