-- Exact-link item cache and snapshots. No inventory mutation or catalog-wide item queries.
local _, ns = ...
local L = ns.loot
local call=L.call
local cache, requests = {}, {}
local aliases={STRENGTH="str",AGILITY="agi",STAMINA="sta",INTELLECT="int",SPIRIT="spi",ARMOR="armor",
  HEALTH="health",MANA="mana",ATTACK_POWER="ap",RANGED_ATTACK_POWER="rap",FERAL_ATTACK_POWER="feralAp",
  SPELL_POWER="sp",SPELLPOWER="sp",SPELL_DAMAGE_DONE="sp",SPELL_HEALING_DONE="heal",HEALING_DONE="heal",MANA_REGENERATION="mp5",
  HIT_RATING="hit",CRIT_RATING="crit",SPELL_HIT_RATING="spellHit",SPELL_CRIT_RATING="spellCrit",
  DEFENSE_SKILL_RATING="defense",DODGE_RATING="dodge",BLOCK_RATING="block",BLOCK_VALUE="blockValue"}
function L.itemKey(ref)
  if type(ref)=="number" then return "item:"..math.floor(ref) end
  if type(ref)~="string" or #ref>2048 then return end
  local key=ref:match("(item:[%d:%-]+)") or (ref:match("^%d+$") and ("item:"..ref))
  if not key then return end
  local fields={};for value in (key:sub(6)..":"):gmatch("(.-):") do fields[#fields+1]=value end
  if #fields>=9 then fields[9]="0";if #fields>=10 then fields[10]="0" end;key="item:"..table.concat(fields,":") end
  return key
end
local function hasUnknownModifications(key)
  local fields={};for value in (key:sub(6)..":"):gmatch("(.-):") do fields[#fields+1]=value end
  for i=2,#fields do
    -- Unique ID and viewing level/spec are identity/context, not added item effects.
    if i~=8 and i~=9 and i~=10 and (tonumber(fields[i]) or 0)~=0 then return true end
  end
  return false
end
local function copy(t)
  local out={}; for k,v in pairs(t or {}) do out[k]=v end; return out
end
local function request(key,id)
  local r=requests[key]
  if r and (r.pending or r.n>=4) then return end
  r=r or {n=0}; requests[key]=r; r.n=r.n+1; r.pending=true
  if L.waiting then L.waiting[id]=true end
  call(C_Item and C_Item.RequestLoadItemDataByID,id)
  if ns.after then ns.after(({0.5,1,2,2})[r.n],function()
    r.pending=false
    cache[key]=nil
    if r.n<4 then L.item(key) else L.refresh("item retry exhausted") end
  end) end
end
function L.item(ref)
  if type(ref)=="table" and ref.id then return ref end
  local key=L.itemKey(ref)
  if not key then return end
  local id=tonumber(key:match("^item:(%d+)"))
  if not id or id<=0 then return end
  local hit=cache[key]
  if hit and hit.readVersion==L.version then return hit end
  local base=ns.lootData and ns.lootData.items[id]
  local item=copy(base)
  item.id=id; item.key=key; item.link=key; item.readVersion=L.version
  item.complete=copy(base and base.complete); item.restrictions=copy(base and base.restrictions)
  item.stats=copy(base and base.stats); item.warnings=copy(base and base.warnings)
  local name,link,quality,level,required,_,_,_,slot,icon,_,classID,subclassID=ns.itemInfo(key)
  local raw, output
  if C_Item and type(C_Item.GetItemStats)=="function" then raw=call(C_Item.GetItemStats,key) end
  if type(raw)~="table" and type(GetItemStats)=="function" then
    output={}; raw=call(GetItemStats,key,output)
    if type(raw)~="table" and next(output) then raw=output end
  end
  if name then
    item.name=ns.plain(name); item.link=link or key; item.quality=quality or item.quality
    item.level=level or item.level; item.requiredLevel=required or item.requiredLevel
    if slot and slot~="" then item.slot=slot end
    item.icon=icon or item.icon; item.classID=classID or item.classID; item.subclassID=subclassID or item.subclassID
  end
  if type(raw)=="table" then
    item.stats={}
    for stat,value in pairs(raw) do
      local short=stat:match("^ITEM_MOD_(.-)_SHORT$") or stat
      local alias=aliases[short] or (short=="RESISTANCE0_NAME" and "armor")
      if alias and type(value)=="number" then item.stats[alias]=math.max(item.stats[alias] or -math.huge,value) end
    end
    item.complete.stats=true
  end
  local modified=hasUnknownModifications(key)
  if base and modified and not raw then
    -- Even a fixed item may carry an enchant or suffix not represented by base facts.
    item.complete.stats=false
  end
  if not base then item.complete.effects=false; item.complete.restrictions=false end
  local tooltip=call(C_TooltipInfo and C_TooltipInfo.GetHyperlink,key)
  if type(tooltip)=="table" and type(tooltip.lines)=="table" then
    item.complete.effects=not base or base.complete and base.complete.effects or false; item.complete.restrictions=true
    for _,line in ipairs(tooltip.lines) do
      local text=type(line.leftText)=="string" and line.leftText:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","") or ""
      if text:find("Use:",1,true) or text:find("Chance on hit:",1,true) or text:find("Set:",1,true)
        or (not base and text:find("Equip:",1,true)) then
        item.complete.effects=false
      end
      if text:find("Requires ",1,true) and not text:find("Requires Level ",1,true) then
        item.complete.restrictions=false
      end
      local classes=text:match("Classes: (.+)")
      if classes then
        item.restrictions.classes={}
        for c in classes:gmatch("[^,]+") do item.restrictions.classes[#item.restrictions.classes+1]=(c:gsub("^%s+",""):gsub("%s+$",""):upper()) end
      end
      item.damage=tonumber(text:match("([%d%.]+) damage per second")) or item.damage
      item.speed=tonumber(text:match("Speed%s+([%d%.]+)")) or item.speed
    end
  end
  if modified then
    item.complete.effects=false
    item.warnings[#item.warnings+1]="Item modification effects have not been verified"
  end
  if item.random and not raw then item.complete.stats=false end
  local canRead=not ns.itemInfoAPI or ns.itemInfoAPI()~=nil
  item.state=(name or base) and "ready" or ((not canRead or requests[key] and requests[key].n>=4) and "unavailable" or "loading")
  item.name=item.name or ("Item "..id)
  cache[key]=item
  if not name and not base and canRead then request(key,id) end
  return item
end

local snapshot={version=0,slots={},bagLinks={},equipmentKnown=false,bagsKnown=false}
local readVersion=-1
function L.snapshot()
  if readVersion==L.version then return snapshot end
  readVersion=L.version
  local slots,gearOK={},type(GetInventoryItemLink)=="function"
  if gearOK then
    for _,n in ipairs(L.slotOrder) do
      local ok,link=pcall(GetInventoryItemLink,"player",n)
      if not ok then gearOK=false; break end
      slots[n]=link and L.item(link) or false
    end
  end
  if gearOK then snapshot.slots=slots end
  local size=C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
  local get=C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo
  local links,bagsOK={},type(size)=="function" and type(get)=="function"
  if bagsOK then
    for bag=0,4 do
      local ok,n=pcall(size,bag)
      if not ok or type(n)~="number" then bagsOK=false; break end
      for slot=1,n do
        local good,info, count,_,_,_,_,link=pcall(get,bag,slot)
        if not good then bagsOK=false; break end
        if type(info)=="table" then link=info.hyperlink; count=info.stackCount end
        if info and not link then
          link=call(C_Container and C_Container.GetContainerItemLink or GetContainerItemLink,bag,slot)
          if not link then bagsOK=false;break end
        end
        if link then
          local key=L.itemKey(link)
          if key then links[key]=(links[key] or 0)+(tonumber(count) or 1) end
        end
      end
    end
  end
  if bagsOK then snapshot.bagLinks=links end
  snapshot.equipmentKnown=gearOK; snapshot.bagsKnown=bagsOK; snapshot.version=L.version
  return snapshot
end

-- Proficiencies are read from the character, not inferred from the selected talent path.
local weaponNames={[0]="Axes",[1]="Two-Handed Axes",[2]="Bows",[3]="Guns",[4]="Maces",[5]="Two-Handed Maces",
  [6]="Polearms",[7]="Swords",[8]="Two-Handed Swords",[10]="Staves",[13]="Fist Weapons",[15]="Daggers",[16]="Thrown",[18]="Crossbows",[19]="Wands"}
function L.proficiencies()
  local p={armor=1,armorKnown=false,weapons={},weaponKnown=false}
  local count=call(GetNumSkillLines)
  for i=1,tonumber(count) or 0 do
    local name,header=call(GetSkillLineInfo,i)
    if name and not header then
      for sub,english in pairs(weaponNames) do
        local localized=call(GetItemSubClassInfo,2,sub)
        if name==(localized or english) then p.weapons[sub]=true; p.weaponKnown=true end
      end
      for sub,english in ipairs({"Cloth","Leather","Mail","Plate"}) do
        if name==(call(GetItemSubClassInfo,4,sub) or english) then p.armor=math.max(p.armor,sub); p.armorKnown=true end
      end
      if name=="Shields" then p.shield=true end
      if name=="Dual Wield" then p.dualWield=true end
    end
  end
  -- Already equipped items establish at least that proficiency, even with collapsed skills.
  for _,it in pairs(L.snapshot().slots) do
    if it then
      if it.classID==2 then p.weapons[it.subclassID]=true end
      if it.classID==4 and it.subclassID and it.subclassID<=4 then p.armor=math.max(p.armor,it.subclassID) end
      if it.slot=="INVTYPE_SHIELD" then p.shield=true end
    end
  end
  if snapshot.slots[17] and snapshot.slots[17].classID==2 then p.dualWield=true end
  return p
end
