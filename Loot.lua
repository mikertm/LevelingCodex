local _, ns = ...
local L = { version=0 }
ns.loot = L
L.labels = {upgrade="Upgrade",sidegrade="Sidegrade",downgrade="Downgrade",cannotEquip="Cannot equip",needsReview="Needs review",loading="Loading"}
L.slotNames = {[1]="Head",[2]="Neck",[3]="Shoulders",[5]="Chest",[6]="Waist",[7]="Legs",[8]="Feet",
  [9]="Wrists",[10]="Hands",[11]="Ring 1",[12]="Ring 2",[13]="Trinket 1",[14]="Trinket 2",
  [15]="Back",[16]="Main hand",[17]="Off hand",[18]="Ranged / relic"}
L.slotOrder = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
function L.call(fn, ...)
  if type(fn) ~= "function" then return end
  local ok,a,b,c,d,e,f,g,h,i,j,k,l,m = pcall(fn,...)
  if ok then return a,b,c,d,e,f,g,h,i,j,k,l,m end
end
local listeners = {}
function L.subscribe(fn)
  listeners[fn]=true
  return function() listeners[fn]=nil end
end
local pending
function L.refresh(reason)
  L.version=L.version+1
  L.dirty=true
  L.lastReason=reason
  if pending then return end
  pending=true
  ns.after(0.1,function()
    pending=false
    local clock=type(debugprofilestop)=="function" and debugprofilestop
    local t0=clock and clock()
    for fn in pairs(listeners) do L.call(fn,reason) end
    L.flushes=(L.flushes or 0)+1
    if t0 then
      local ms=clock()-t0
      L.lastFlushMs=ms
      if ms>(L.worstFlushMs or 0) then L.worstFlushMs=ms end
    end
  end)
end
-- Item data arrives for every item any code asks about: an auction house scan loads
-- thousands, and refreshing the gear and bag comparisons for each one hitched the game.
-- Only an item the loot code is waiting for refreshes at once; any other one is folded
-- into one refresh 5 s later, and none while an auction scan runs.
L.waiting={}
local stray
local function flushStray()
  local A=ns.auction
  if A and A.scanning and A.scanning() then ns.after(5,flushStray) return end
  stray=false
  L.refresh("item data")
end
function L.itemData(event,id)
  L.itemEvents=(L.itemEvents or 0)+1
  id=tonumber(id)
  if id and L.waiting[id] then L.waiting[id]=nil; L.refresh(event) return end
  L.strayEvents=(L.strayEvents or 0)+1
  if stray or not ns.after then return end
  stray=true
  ns.after(5,flushStray)
end
function L.context(overrides)
  local _,class=UnitClass("player")
  local _,race=L.call(UnitRace,"player")
  local ctx={class=class,race=race,faction=L.call(UnitFactionGroup,"player"),level=UnitLevel("player"),
    version=L.version,snapshot=L.snapshot(),proficiencies=L.proficiencies and L.proficiencies()}
  for key,value in pairs(overrides or {}) do ctx[key]=value end
  ctx.preview=class~=ctx.class or ctx.level~=UnitLevel("player") or ctx.faction~=L.call(UnitFactionGroup,"player")
  if ctx.preview and not (overrides and overrides.snapshot) then ctx.snapshot={slots={},equipmentKnown=false} end
  if ctx.class~=class then ctx.proficiencies={armor=1,armorKnown=false,weapons={},weaponKnown=false} end
  if L.profile then ctx.profile=L.profile(ctx) end
  return ctx
end
function L.debugLines()
  local d=ns.lootData or {}
  local p=L.profile and L.profile()
  return {"loot: build "..tostring(d.build or "unavailable")..", items "..tostring(d.coverage and d.coverage.items or 0),
    "loot profile: "..tostring(p and p.label or "unavailable")..", refresh "..tostring(L.lastReason or "none"),
    "loot APIs: item stats "..tostring(type(GetItemStats)=="function" or type(C_Item)=="table" and type(C_Item.GetItemStats)=="function"),
    "loot last comparison: "..tostring(L.lastComparison or "none"),
    string.format("loot refreshes: %d, last %.1f ms, longest %.1f ms; item data events %d (%d not ours)",
      L.flushes or 0,L.lastFlushMs or 0,L.worstFlushMs or 0,L.itemEvents or 0,L.strayEvents or 0)}
end
if type(CreateFrame)=="function" then
  local events=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_LOGIN","PLAYER_EQUIPMENT_CHANGED","BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED",
    "ITEM_DATA_LOAD_RESULT","PLAYER_LEVEL_UP","SPELLS_CHANGED","SKILL_LINES_CHANGED","PLAYER_REGEN_ENABLED"}) do
    pcall(events.RegisterEvent,events,event)
  end
  events:SetScript("OnEvent",function(_,event,id)
    if event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then L.itemData(event,id) else L.refresh(event) end
  end)
end
