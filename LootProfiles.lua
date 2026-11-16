-- Advisory priorities, not simulated output or claimed game conversion constants.
local _, ns = ...
local L=ns.loot
local ROLES={
  ["Melee damage"]={str=1,agi=1.2,sta=0.4,ap=0.5,feralAp=0.5,hit=8,crit=7,armor=0.002},
  ["Ranged damage"]={agi=2,str=0.1,sta=0.4,int=0.5,rap=0.5,ap=0.2,hit=8,crit=7},
  ["Caster damage"]={int=1,sta=0.4,spi=0.5,sp=1.8,mp5=0.8,spellHit=8,spellCrit=6},
  Healer={int=1.3,sta=0.3,spi=0.8,sp=0.4,heal=1.4,mp5=1.5},
  Tank={sta=1.3,armor=0.02,str=0.4,agi=0.6,defense=2,dodge=7,block=1,blockValue=0.4,ap=0.1},
}
local allowed={health=true,mana=true,hp5=true,mp5=true,spFire=true,spFrost=true,spShadow=true,spNature=true,
  spArcane=true,spHoly=true,haste=true,spellHaste=true,resist=true}
for _,weights in pairs(ROLES) do for key in pairs(weights) do allowed[key]=true end end
local function copy(t) local o={}; for k,v in pairs(t or {}) do o[k]=v end; return o end
local function class() local _,c=UnitClass("player"); return c end
local function validNumber(n) return type(n)=="number" and n==n and n>=0 and n<=10000 end
local function normalize(p)
  if type(p)~="table" or p.class~=class() or type(p.weights)~="table" then return nil,"Invalid class or weights" end
  local out={key="custom",class=p.class,label=tostring(p.label or "Custom"):gsub("[^%w _]",""):sub(1,32),
    role=p.role or "Custom",weights={},weapon={},custom=true,version=1}
  for k,v in pairs(p.weights) do if not allowed[k] or not validNumber(v) then return nil,"Invalid stat weight" end; out.weights[k]=v end
  for k,v in pairs(p.weapon or {}) do
    if k=="feral" then if type(v)~="boolean" then return nil,"Invalid weapon policy" end
    elseif not (k=="melee" or k=="ranged" or k=="speed") or not validNumber(v) then return nil,"Invalid weapon policy" end
    out.weapon[k]=v
  end
  return out
end
function L.profile(ctx)
  ctx=ctx or {class=class()}
  if not (ns.TALENT_PATHS or {})[ctx.class] then return nil end
  local saved=ns.charDB().lootProfile
  if ctx.class==class() and not ctx.profileKey and type(saved)=="table" then
    local p=normalize(saved); if p then return p end
  end
  local key=ctx.profileKey or (ctx.class==class() and ns.charDB().lootProfileKey)
  local path
  if not key and ctx.class==class() and ns.talentPath then path=ns.talentPath() end
  if path and path.custom then
    local counts={}
    for _,t in ipairs(ns.talentPlan and ns.talentPlan() or {}) do counts[t.tree]=(counts[t.tree] or 0)+t.to-t.from+1 end
    local best,score,tied=nil,-1,false
    for tree,n in pairs(counts) do if n>score then best=tree;score=n;tied=false elseif n==score then tied=true end end
    if not tied then
      for _,p in ipairs((ns.TALENT_PATHS or {})[ctx.class] or {}) do
        if p.spec==best then path=p; break end
      end
    end
    if path.custom then path=nil end
  end
  for _,p in ipairs((ns.TALENT_PATHS or {})[ctx.class] or {}) do
    if p.key==(key or (path and path.key) or "guide") then path=p; break end
  end
  path=path or {key="guide",spec="Leveling",role="Caster damage"}
  local role=ROLES[path.role] and path.role or "Caster damage"
  local weights=copy(ROLES[role])
  local feral=ctx.class=="DRUID" and (path.spec or ""):find("Feral")~=nil
  local weapon={melee=(role=="Melee damage" or role=="Tank") and 4 or 0,
    ranged=role=="Ranged damage" and 6 or 0,feral=feral}
  local school=({Fire="Fire",Frost="Frost",Shadow="Shadow",Balance="Nature",Elemental="Nature",Arcane="Arcane"})[path.spec]
  if school then weights["sp"..school]=weights.sp or 0 end
  return {key=path.key,class=ctx.class,label=path.spec or "Leveling",role=role,weights=weights,weapon=weapon,version=ns.talentVersion or 0,
    note="Advisory leveling priorities. A score change is not a damage or healing percentage."}
end
function L.setProfile(value)
  if value==nil then L.resetProfile(); return true end
  if type(value)=="string" then
    for _,p in ipairs((ns.TALENT_PATHS or {})[class()] or {}) do
      if p.key==value then ns.charDB().lootProfile=nil; ns.charDB().lootProfileKey=value; L.refresh("loot profile"); return true end
    end
    return false,"Unknown profile"
  end
  local p,err=normalize(value)
  if not p then return false,err end
  ns.charDB().lootProfile=p; ns.charDB().lootProfileKey=nil; L.refresh("custom loot profile"); return true
end
function L.resetProfile()
  ns.charDB().lootProfile=nil; ns.charDB().lootProfileKey=nil; L.refresh("automatic loot profile")
end
local function checksum(s) local n=1; for i=1,#s do n=(n*31+s:byte(i))%65521 end; return n end
function L.profileCode()
  local p=L.profile();if not p then return "" end; local fields={p.label}
  local keys={}; for k in pairs(p.weights) do keys[#keys+1]=k end; table.sort(keys)
  for _,k in ipairs(keys) do fields[#fields+1]=k.."="..p.weights[k] end
  for _,k in ipairs({"melee","ranged","speed"}) do if p.weapon[k] then fields[#fields+1]="w_"..k.."="..p.weapon[k] end end
  fields[#fields+1]="feral="..(p.weapon.feral and "1" or "0")
  local payload=table.concat(fields,";")
  return "LCL1-"..p.class.."-"..payload.."-"..checksum(payload)
end
function L.readProfileCode(code)
  if type(code)~="string" or #code>4096 then return false,"Profile code is too long" end
  local c,payload,check=code:match("^LCL1%-(%u+)%-(.*)%-(%d+)$")
  if c~=class() or not payload or checksum(payload)~=tonumber(check) then return false,"Invalid profile code or class" end
  local p={class=c,label=payload:match("^([^;]*)"),weights={},weapon={}}
  local n=0
  for field in payload:gmatch("[^;]+") do
    n=n+1
    if n>1 then
      local k,v=field:match("^([%w_]+)=([%d%.eE%+%-]+)$")
      if not k then return false,"Invalid profile field" end
      if k=="feral" then if v~="0" and v~="1" then return false,"Invalid feral flag" end; p.weapon.feral=v=="1"
      elseif k:sub(1,2)=="w_" then p.weapon[k:sub(3)]=tonumber(v)
      else p.weights[k]=tonumber(v) end
    end
  end
  return L.setProfile(p)
end
L.profileStatKeys=allowed
