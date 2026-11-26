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
-- What a class can wear or learn, for when the client's skill list can't be read (and to tell
-- an untrained weapon from one the class can never use). Classic rules: plate and mail at 40.
local CLASS_ARMOR = {WARRIOR={3,4},PALADIN={3,4},HUNTER={2,3},SHAMAN={2,3},ROGUE={2,2},DRUID={2,2},
  PRIEST={1,1},MAGE={1,1},WARLOCK={1,1}}
local function weaponSet(list) local t={}; for _,n in ipairs(list) do t[n]=true end; return t end
local CLASS_WEAPONS = {
  WARRIOR=weaponSet{0,1,2,3,4,5,6,7,8,10,13,15,16,18}, PALADIN=weaponSet{0,1,4,5,6,7,8},
  HUNTER=weaponSet{0,1,2,3,6,7,8,10,13,15,16,18}, ROGUE=weaponSet{2,3,4,7,13,15,16,18},
  PRIEST=weaponSet{4,10,15,19}, SHAMAN=weaponSet{0,1,4,5,10,13,15}, MAGE=weaponSet{7,10,15,19},
  WARLOCK=weaponSet{7,10,15,19}, DRUID=weaponSet{4,5,10,13,15},
}
local CLASS_SHIELD = {WARRIOR=true,PALADIN=true,SHAMAN=true}
local CLASS_DUAL = {WARRIOR=20,HUNTER=20,ROGUE=1}
L.WEAPON_NAMES = {[0]="One-Handed Axes",[1]="Two-Handed Axes",[2]="Bows",[3]="Guns",[4]="One-Handed Maces",
  [5]="Two-Handed Maces",[6]="Polearms",[7]="One-Handed Swords",[8]="Two-Handed Swords",[10]="Staves",
  [13]="Fist Weapons",[15]="Daggers",[16]="Thrown",[18]="Crossbows",[19]="Wands"}
function L.classArmor(class, level)
  local a=CLASS_ARMOR[class]; if not a then return end
  return (level or 1)>=40 and a[2] or a[1]
end
function L.classWeapon(class, sub) local w=CLASS_WEAPONS[class]; if w then return w[sub]==true end end
local function has(list, x)
  for _, v in ipairs(list or {}) do if v == x then return true end end
  return false
end
local function maskHas(mask, n) return math.floor(mask / 2^(n-1)) % 2 == 1 end
local function result(verdict, reason, item)
  return {verdict=verdict,reason=reason,candidate=item,warnings={},replacedSlots={},baseline={},statDelta={}}
end

-- state "yes", "no" or "unknown"; an "unknown" with notes can still be scored as an estimate.
-- skipLevel scores an item you can't wear yet as if you were its level (proficiency too).
function L.eligible(item, ctx, proposed, insertedSlot, skipLevel)
  local r, p = item.restrictions or {}, ctx.proficiencies
  local level = ctx.level or 1
  if (item.requiredLevel or 0) > level then
    if not skipLevel then return {state="no",reasons={"Requires level "..item.requiredLevel}} end
    level = item.requiredLevel
  end
  if r.classes and not has(r.classes, ctx.class) then return {state="no",reasons={"Restricted to another class"}} end
  if r.classMask and CLASS[ctx.class] and not maskHas(r.classMask, CLASS[ctx.class]) then
    return {state="no",reasons={"Restricted to another class"}}
  end
  if r.races and not has(r.races, ctx.race) then return {state="no",reasons={"Restricted to another race"}} end
  if r.faction and r.faction ~= "All" and r.faction ~= ctx.faction then return {state="no",reasons={"Wrong faction"}} end
  local unknown = {}
  if not (item.complete and item.complete.restrictions) then unknown[#unknown+1]="Check the item's requirements" end
  if r.text then unknown[#unknown+1]=r.text end
  if r.skill then
    if not ctx.professions then unknown[#unknown+1]="Needs a profession skill"
    elseif (ctx.professions[r.skill] or 0) < (r.skillRank or 1) then return {state="no",reasons={"Profession skill is too low"}} end
  end
  if r.reputation then
    if not ctx.reputation then unknown[#unknown+1]="Needs reputation"
    elseif (ctx.reputation[r.reputation] or 0) < (r.standing or 0) then return {state="no",reasons={"Reputation is too low"}} end
  end
  if item.classID == 4 and (item.subclassID or 0) >= 1 and item.subclassID <= 4 then
    local wear = L.classArmor(ctx.class, level)
    local known = p and p.armorKnown ~= false and p.armor or nil
    local names = {"Cloth","Leather","Mail","Plate Mail"}
    if wear and item.subclassID > wear then return {state="no",reasons={"Armor proficiency required"}}
    elseif known and item.subclassID > known then
      if not wear then return {state="no",reasons={"Armor proficiency required"}} end
      if not skipLevel then unknown[#unknown+1]="Train "..names[item.subclassID].." at your class trainer first" end
    elseif not known and not wear then unknown[#unknown+1]="Armor proficiency not known" end
  end
  if item.classID == 2 and item.subclassID ~= nil then
    local can = L.classWeapon(ctx.class, item.subclassID)
    local trained = p and p.weapons and p.weapons[item.subclassID]
    if not trained then
      if can == false then return {state="no",reasons={"Your class can't use "..(L.WEAPON_NAMES[item.subclassID] or "this weapon")}} end
      if can then
        if p and p.weaponKnown then unknown[#unknown+1]="Train "..(L.WEAPON_NAMES[item.subclassID] or "this weapon").." at a weapon master first"
        elseif not skipLevel then unknown[#unknown+1]="Check you have trained "..(L.WEAPON_NAMES[item.subclassID] or "this weapon") end
      else unknown[#unknown+1]="Weapon proficiency not known" end
    end
  end
  if item.slot == "INVTYPE_SHIELD" then
    local shield = p and p.shield
    if shield == nil and CLASS_ARMOR[ctx.class] then shield = CLASS_SHIELD[ctx.class] == true end
    if shield == false then return {state="no",reasons={"Shield proficiency required"}} end
    if shield == nil then unknown[#unknown+1]="Shield proficiency not known" end
  end
  if proposed[17] == item and item.classID == 2 and item.slot ~= "INVTYPE_2HWEAPON" then
    local dual = p and p.dualWield
    if not dual and CLASS_ARMOR[ctx.class] then dual = CLASS_DUAL[ctx.class] ~= nil and level >= CLASS_DUAL[ctx.class] end
    if dual == false then return {state="no",reasons={"Dual wield required"}} end
    if dual == nil then unknown[#unknown+1]="Dual wield not known" end
  end
  if r.unique then
    for slot, other in pairs(proposed) do
      if slot~=insertedSlot and other and other.restrictions and other.restrictions.unique == r.unique then
        return {state="no",reasons={"Conflicts with an equipped unique item"}}
      end
    end
  end
  if #unknown > 0 then return {state="unknown",reasons=unknown} end
  return {state="yes",reasons={}}
end

-- A short reason for each effect line the score leaves out.
local function effectNote(line)
  if line:find("^Use:") then return "Use effect not counted" end
  if line:find("^Chance on hit:") then return "Chance on hit not counted" end
  if line:find("Set:") or line:find("^%(") then return "Set bonus not counted" end
  return "Equip effect not counted"
end
local function addNote(notes, text)
  for _, n in ipairs(notes) do if n == text then return end end
  notes[#notes+1] = text
end
L.addNote = addNote

-- value plus: complete = the stats are known well enough to compare; notes = what the
-- score leaves out (effects, set bonuses, enchants, an unrolled random bonus).
function L.score(item, profile)
  if item == false then return {value=0,complete=true,warnings={},notes={}} end
  if not item then return {complete=false,warnings={"Item stats are not fully known"},notes={}} end
  if not profile then return {complete=false,warnings={"Select a loot profile"},notes={}} end
  local value, warnings, notes = 0, {}, {}
  if not item.complete or not item.complete.stats then
    if item.random then addNote(notes, "Random bonus not counted (\"of the ...\")")
    else return {complete=false,warnings={"Item stats are not fully known"},notes=notes} end
  end
  local weights = profile.weights or {}
  for key, n in pairs(item.stats or {}) do value = value + n * (weights[key] or 0) end
  local w = profile.weapon or {}
  local ranged = item.slot == "INVTYPE_RANGED" or item.slot == "INVTYPE_RANGEDRIGHT" or item.slot == "INVTYPE_THROWN"
  local weaponWeight = ranged and (w.ranged or 0) or (w.melee or 0)
  if item.classID==2 and not w.feral then
    if weaponWeight>0 and type(item.damage)~="number" then warnings[#warnings+1]="Weapon damage is not fully known" end
    if (w.speed or 0)>0 and type(item.speed)~="number" then warnings[#warnings+1]="Weapon speed is not fully known" end
  end
  if item.damage and not w.feral then value = value + item.damage * weaponWeight end
  local bonus = (item.stats or {}).weaponDmg
  if bonus and type(item.speed)=="number" and item.speed>0 and not w.feral then value = value + bonus / item.speed * weaponWeight end
  if item.speed and w.speed then value = value + item.speed * w.speed end
  for _, line in ipairs(item.warnings or {}) do addNote(notes, effectNote(line)) end
  if item.complete and not item.complete.effects and #notes == 0 then addNote(notes, "Some effects not counted") end
  if item.restrictions and item.restrictions.set then addNote(notes, "Set bonus not counted") end
  for _, line in ipairs(item.notes or {}) do addNote(notes, line) end
  return {value=value,complete=#warnings==0,warnings=warnings,notes=notes}
end

function L.compare(ref, ctx, baseline, weaponSlot)
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
  if item.slot=="INVTYPE_WEAPON" and (weaponSlot==16 or weaponSlot==17) then locations={weaponSlot} end
  if #locations == 0 then return result(item.slot and "cannotEquip" or "needsReview",item.slot and "This is not a supported equipment slot" or "Equipment slot information is unavailable",item) end
  local r = L.compareSlots(item, ctx, slots, locations)
  if r.verdict == "cannotEquip" and (item.requiredLevel or 0) > (ctx.level or 1) and r.reason == "Requires level "..item.requiredLevel then
    -- Rate it for the level you can wear it: the same gear, the same profile.
    local f = L.compareSlots(item, ctx, slots, locations, true)
    if f.verdict == "cannotEquip" then r.reason = f.reason end
    if f.confidence == "complete" then
      r.future = {level=item.requiredLevel,verdict=f.verdict,percent=f.percent,delta=f.delta,estimate=f.estimate,noValue=f.noValue,
        notes=f.notes,score=f.score,baselineScore=f.baselineScore}
      r.score, r.baselineScore, r.statDelta, r.baseline, r.replacedSlots = f.score, f.baselineScore, f.statDelta, f.baseline, f.replacedSlots
    end
  end
  return r
end

function L.compareSlots(item, ctx, slots, locations, skipLevel)
  local best, uncertain, refusal
  local twoHander = slots[16] and slots[16].slot == "INVTYPE_2HWEAPON"
  for _, slot in ipairs(locations) do
    local proposed, replaced = {}, {slot}
    for k,v in pairs(slots) do proposed[k]=v end
    proposed[slot] = item
    if item.slot == "INVTYPE_2HWEAPON" then proposed[17]=false; replaced={16,17} end
    -- A one-hander in the main hand replaces a two-hander; the off hand is then empty.
    local swapTwoHand = twoHander and item.slot ~= "INVTYPE_2HWEAPON" and slot == 16
    if swapTwoHand then proposed[17]=false; replaced={16,17} end
    local partnerMissing = twoHander and item.slot ~= "INVTYPE_2HWEAPON" and slot == 17
    local eligible = L.eligible(item,ctx,proposed,slot,skipLevel)
    if eligible.state == "no" then
      refusal = refusal or result("cannotEquip",eligible.reasons[1],item)
    else
      local r = result("needsReview",eligible.reasons[1] or "Comparison needs more information",item)
      r.eligibility=eligible.state; r.replacedSlots=replaced; r.notes={}
      local weapon=slots[slot]
      if weapon and weapon.classID==2 and item.classID==2 and type(weapon.damage)=="number" and type(item.damage)=="number" then
        r.weaponDpsDelta=item.damage-weapon.damage
      end
      local score = L.score(item,ctx.profile)
      local old, complete = 0, score.complete and not partnerMissing
      r.warnings=score.warnings
      for _, line in ipairs(score.notes or {}) do L.addNote(r.notes, line) end
      if eligible.state == "unknown" then for _, line in ipairs(eligible.reasons) do L.addNote(r.notes, line) end end
      if partnerMissing then r.warnings[#r.warnings+1]="Pair it with a one-hand weapon in place of your two-hander" end
      if swapTwoHand then L.addNote(r.notes, item.slot=="INVTYPE_WEAPON" and "Compared with your two-hander; an off-hand adds to it" or "Compared with your two-hander") end
      for _, n in ipairs(replaced) do
        local before=slots[n]
        -- An off-hand is confirmed empty when an equipped two-hander occupies both hands.
        if n==17 and twoHander then before=false end
        local s=L.score(before,ctx.profile)
        if not s.value then complete=false else old=old+s.value end
        if not s.complete then complete=false end
        for _, line in ipairs(s.warnings) do r.warnings[#r.warnings+1]=line end
        if before and #(s.notes or {})>0 then L.addNote(r.notes, "Your equipped item has effects the score leaves out") end
        if before then r.baseline[#r.baseline+1]=before end
        for key,value in pairs(before and before.stats or {}) do r.statDelta[key]=(r.statDelta[key] or 0)-value end
      end
      for key,value in pairs(item.stats or {}) do r.statDelta[key]=(r.statDelta[key] or 0)+value end
      if score.value then r.score=score.value; r.baselineScore=old; r.delta=score.value-old end
      if complete and r.delta and old==0 and score.value==0 then
        -- Nothing on it your build values (a caster's look at a strength belt).
        r.verdict="sidegrade"; r.confidence="complete"; r.noValue=true
        r.reason="No stats your build uses"
        if not best or r.delta>best.delta then best=r end
      elseif complete and r.delta then
        r.percent=old>0 and r.delta/old*100 or nil
        r.verdict=r.delta>old*0.01 and "upgrade" or r.delta < -old*0.01 and "downgrade" or "sidegrade"
        r.reason=old==0 and "Fills an empty slot" or "Estimated gear score; review the stat tradeoffs"
        r.confidence="complete"
        r.estimate=#r.notes>0 or nil
        if r.estimate then r.reason=r.notes[1] end
        if not best or r.delta>best.delta then best=r end
      else
        r.confidence="provisional"
        if #r.warnings>0 then r.reason=r.warnings[1] end
        if not uncertain or (r.delta or -math.huge)>(uncertain.delta or -math.huge) then uncertain=r end
      end
    end
  end
  if best and uncertain and not (uncertain.warnings[1] or ""):find("one-hand weapon in place",1,true) then
    best.verdict="needsReview";best.confidence="provisional"
    best.reason="Another eligible replacement slot is not fully known; review both slots"
    return best
  end
  return best or uncertain or refusal or result("needsReview","No legal comparison available",item)
end
