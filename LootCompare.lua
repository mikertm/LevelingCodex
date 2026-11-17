-- One advisory comparison for every surface. Missing facts never become zero stats.
local _, ns = ...
local L = ns.loot
local SLOT = {
  INVTYPE_HEAD={1}, INVTYPE_NECK={2}, INVTYPE_SHOULDER={3}, INVTYPE_CHEST={5}, INVTYPE_ROBE={5},
  INVTYPE_WAIST={6}, INVTYPE_LEGS={7}, INVTYPE_FEET={8}, INVTYPE_WRIST={9}, INVTYPE_HAND={10},
  INVTYPE_FINGER={11,12}, INVTYPE_TRINKET={13,14}, INVTYPE_CLOAK={15}, INVTYPE_WEAPON={16,17},
  INVTYPE_WEAPONMAINHAND={16}, INVTYPE_WEAPONOFFHAND={17}, INVTYPE_2HWEAPON={16},
  INVTYPE_SHIELD={17}, INVTYPE_HOLDABLE={17}, INVTYPE_RANGED={18}, INVTYPE_RANGEDRIGHT={18},
  INVTYPE_THROWN={18}, INVTYPE_RELIC={18},
}
L.slotsFor = function(slot) return SLOT[slot] or {} end
local CLASS = {WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,SHAMAN=7,MAGE=8,WARLOCK=9,DRUID=11}
local function has(list, x)
  for _, v in ipairs(list or {}) do if v == x then return true end end
  return false
end
local function maskHas(mask, n) return math.floor(mask / 2^(n-1)) % 2 == 1 end
local function result(verdict, reason, item)
  return {verdict=verdict,reason=reason,candidate=item,warnings={},replacedSlots={},baseline={},statDelta={}}
end

function L.eligible(item, ctx, proposed, insertedSlot)
  local r, p = item.restrictions or {}, ctx.proficiencies
  if (item.requiredLevel or 0) > ctx.level then return {state="no",reasons={"Requires level "..item.requiredLevel}} end
  if r.classes and not has(r.classes, ctx.class) then return {state="no",reasons={"Restricted to another class"}} end
  if r.classMask and CLASS[ctx.class] and not maskHas(r.classMask, CLASS[ctx.class]) then
    return {state="no",reasons={"Restricted to another class"}}
  end
  if r.races and not has(r.races, ctx.race) then return {state="no",reasons={"Restricted to another race"}} end
  if r.faction and r.faction ~= "All" and r.faction ~= ctx.faction then return {state="no",reasons={"Wrong faction"}} end
  if not (item.complete and item.complete.restrictions) then return {state="unknown",reasons={"Item requirements are not fully known"}} end
  if r.text then return {state="unknown",reasons={r.text}} end
  if r.skill then
    if not ctx.professions then return {state="unknown",reasons={"Profession requirement not checked"}} end
    if (ctx.professions[r.skill] or 0) < (r.skillRank or 1) then return {state="no",reasons={"Profession skill is too low"}} end
  end
  if r.reputation then
    if not ctx.reputation then return {state="unknown",reasons={"Reputation requirement not checked"}} end
    if (ctx.reputation[r.reputation] or 0) < (r.standing or 0) then return {state="no",reasons={"Reputation is too low"}} end
  end
  if item.classID == 4 and (item.subclassID or 0) >= 1 and item.subclassID <= 4 then
    if not p or not p.armor then return {state="unknown",reasons={"Armor proficiency not known"}} end
    if item.subclassID > p.armor then return {state=p.armorKnown==false and "unknown" or "no",reasons={"Armor proficiency required"}} end
  end
  if item.classID == 2 then
    if not p or not p.weapons then return {state="unknown",reasons={"Weapon proficiency not known"}} end
    if not p.weapons[item.subclassID] then return {state=p.weaponKnown==false and "unknown" or "no",reasons={"Weapon proficiency required"}} end
  end
  if item.slot == "INVTYPE_SHIELD" and (not p or p.shield == nil) then return {state="unknown",reasons={"Shield proficiency not known"}} end
  if item.slot == "INVTYPE_SHIELD" and not p.shield then return {state="no",reasons={"Shield proficiency required"}} end
  if proposed[17] == item and item.classID == 2 and item.slot ~= "INVTYPE_2HWEAPON" then
    if not p or p.dualWield == nil then return {state="unknown",reasons={"Dual wield not known"}} end
    if not p.dualWield then return {state="no",reasons={"Dual wield required"}} end
  end
  if r.unique then
    for slot, other in pairs(proposed) do
      if slot~=insertedSlot and other and other.restrictions and other.restrictions.unique == r.unique then
        return {state="no",reasons={"Conflicts with an equipped unique item"}}
      end
    end
  end
  return {state="yes",reasons={}}
end

function L.score(item, profile)
  if item == false then return {value=0,complete=true,warnings={}} end
  if not item or not item.complete or not item.complete.stats then return {complete=false,warnings={"Item stats are not fully known"}} end
  if not profile then return {complete=false,warnings={"Select a loot profile"}} end
  local value, warnings = 0, {}
  for key, n in pairs(item.stats or {}) do value = value + n * ((profile.weights or {})[key] or 0) end
  local w = profile.weapon or {}
  local ranged = item.slot == "INVTYPE_RANGED" or item.slot == "INVTYPE_RANGEDRIGHT" or item.slot == "INVTYPE_THROWN"
  if item.classID==2 and not w.feral then
    local weight=ranged and (w.ranged or 0) or (w.melee or 0)
    if weight>0 and type(item.damage)~="number" then warnings[#warnings+1]="Weapon damage is not fully known" end
    if (w.speed or 0)>0 and type(item.speed)~="number" then warnings[#warnings+1]="Weapon speed is not fully known" end
  end
  if item.damage and not w.feral then
    value = value + item.damage * (ranged and (w.ranged or 0) or (w.melee or 0))
  end
  if item.speed and w.speed then value = value + item.speed * w.speed end
  if not item.complete.effects then warnings[#warnings+1] = "Some item effects are not scored" end
  if item.restrictions and item.restrictions.set then warnings[#warnings+1] = "Review the set bonus before replacing this item" end
  for _, line in ipairs(item.warnings or {}) do warnings[#warnings+1] = line end
  return {value=value,complete=#warnings==0,warnings=warnings}
end

function L.compare(ref, ctx, baseline)
  ctx = ctx or (L.context and L.context())
  local item = type(ref) == "table" and ref or (L.item and L.item(ref))
  if not item then return result("needsReview","Item information is unavailable") end
  if item.state == "loading" then return result("loading","Loading item information",item) end
  if not ctx then return result("needsReview","Character information is unavailable",item) end
  if not baseline and ctx.snapshot and ctx.snapshot.equipmentKnown==false then
    return result("needsReview","Equipped gear is not currently readable; the previous snapshot may be stale",item)
  end
  local slots = baseline or (ctx.snapshot and ctx.snapshot.slots) or {}
  local locations = L.slotsFor(item.slot)
  if #locations == 0 then return result(item.slot and "cannotEquip" or "needsReview",item.slot and "This is not a supported equipment slot" or "Equipment slot information is unavailable",item) end
  local best, uncertain, refusal
  for _, slot in ipairs(locations) do
    local proposed, replaced = {}, {slot}
    for k,v in pairs(slots) do proposed[k]=v end
    proposed[slot] = item
    if item.slot == "INVTYPE_2HWEAPON" then proposed[17]=false; replaced={16,17} end
    local partnerMissing = slots[16] and slots[16].slot == "INVTYPE_2HWEAPON" and item.slot ~= "INVTYPE_2HWEAPON" and (slot==16 or slot==17)
    local eligible = L.eligible(item,ctx,proposed,slot)
    if eligible.state == "no" then
      refusal = result("cannotEquip",eligible.reasons[1],item)
    else
      local r = result("needsReview",eligible.reasons[1] or "Comparison needs more information",item)
      r.eligibility=eligible.state; r.replacedSlots=replaced
      local score = L.score(item,ctx.profile)
      local old, complete = 0, score.complete and eligible.state=="yes" and not partnerMissing
      r.warnings=score.warnings
      if partnerMissing then r.warnings[#r.warnings+1]="Supply a legal partner for the one-hand setup" end
      for _, n in ipairs(replaced) do
        local before=slots[n]
        -- An off-hand is confirmed empty when an equipped two-hander occupies both hands.
        if n==17 and slots[16] and slots[16].slot=="INVTYPE_2HWEAPON" then before=false end
        local s=L.score(before,ctx.profile)
        if not s.value then complete=false else old=old+s.value end
        if not s.complete then complete=false end
        for _, line in ipairs(s.warnings) do r.warnings[#r.warnings+1]=line end
        if before then r.baseline[#r.baseline+1]=before end
        for key,value in pairs(before and before.stats or {}) do r.statDelta[key]=(r.statDelta[key] or 0)-value end
      end
      for key,value in pairs(item.stats or {}) do r.statDelta[key]=(r.statDelta[key] or 0)+value end
      if score.value then r.score=score.value; r.baselineScore=old; r.delta=score.value-old end
      if complete and r.delta and not (old==0 and score.value==0) then
        r.percent=old>0 and r.delta/old*100 or nil
        r.verdict=r.delta>old*0.01 and "upgrade" or r.delta < -old*0.01 and "downgrade" or "sidegrade"
        r.reason=old==0 and "Fills an empty slot" or "Estimated gear score; review the stat tradeoffs"
        r.confidence="complete"
        if not best or r.delta>best.delta then best=r end
      else
        r.confidence="provisional"
        if #r.warnings>0 then r.reason=r.warnings[1] end
        if not uncertain or (r.delta or -math.huge)>(uncertain.delta or -math.huge) then uncertain=r end
      end
    end
  end
  if best and uncertain then
    best.verdict="needsReview";best.confidence="provisional"
    best.reason="Another eligible replacement slot is not fully known; review both slots"
    return best
  end
  return best or uncertain or refusal or result("needsReview","No legal comparison available",item)
end
