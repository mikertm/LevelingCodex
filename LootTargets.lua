local _, ns = ...
local L=ns.loot
local changes={}
local function targets()
  local db=ns.charDB()
  if type(db.lootTargets)~="table" then db.lootTargets={} end
  return db.lootTargets
end
local valid={tracked=true,obtained=true,dismissed=true}
function L.targets(state)
  local list={}
  for key,t in pairs(targets()) do
    if type(key)=="string" and #key<=2200 and type(t)=="table" and type(t.id)=="number" and valid[t.state] then
      if not state or t.state==state then list[#list+1]=t end
    end
  end
  table.sort(list,function(a,b) return a.key<b.key end)
  return list
end
function L.track(ref,sourceID)
  local item=L.item(ref)
  if not item then return nil,"Invalid item" end
  local key=item.key.."|"..(sourceID or "")
  if not targets()[key] and #L.targets()>=200 then return nil,"The target limit is 200. Untrack an item first." end
  targets()[key]={key=key,id=item.id,ref=item.key,name=item.name,sourceID=sourceID,state="tracked",exact=item.key~="item:"..item.id}
  if L.refresh then L.refresh("loot target") end
  return key
end
function L.setTargetState(key,state)
  local t=targets()[key]
  if type(t)~="table" or not valid[state] then return false,"Invalid target or state" end
  t.state=state
  if L.refresh then L.refresh("loot target state") end
  return true
end
function L.untrack(key) targets()[key]=nil; if L.refresh then L.refresh("loot target removed") end end
function L.refreshTargets()
  local s=L.snapshot()
  local owned={}
  for key,n in pairs(s.bagLinks or {}) do if n>0 then owned[key]=true end end
  for _,item in pairs(s.slots or {}) do if item then owned[item.key]=true end end
  for _,t in ipairs(L.targets("tracked")) do
    local found=owned[t.ref]
    if not found and not t.exact then
      for key in pairs(owned) do if tonumber(key:match("^item:(%d+)"))==t.id then found=true; break end end
    end
    if found then
      t.state="obtained"
      changes[#changes+1]={kind="obtained",key=t.key,name=t.name}
    end
  end
end
function L.targetChanges() local out=changes; changes={}; return out end
if L.subscribe then L.subscribe(function() L.refreshTargets() end) end
