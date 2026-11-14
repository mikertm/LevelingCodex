-- Disenchant.lua: item-level bands and likely disenchanting materials for gear in your bags.
-- Every bag and item call is optional: without them the Professions tab shows the table alone.

local _, ns = ...

-- The band for an item level, or nil.
function ns.deBand(key, itemLevel)
  local P = ns.P and ns.P[key]
  local bands = P and P.disenchant and P.disenchant.bands
  if not (bands and itemLevel) then return nil end
  for _, b in ipairs(bands) do
    if itemLevel >= b.from and itemLevel <= b.to then return b end
  end
end

-- The disenchanting materials a step needs: its own, and the first material of each part it uses
-- (Motes of Magic: Strange Dust). { [name] = true }
function ns.deNeeded(key, step)
  local out = {}
  local P = ns.P and ns.P[key]
  if not (P and P.disenchant and step) then return out end
  local mats = {}
  for _, b in ipairs(P.disenchant.bands or {}) do
    if b.dust then mats[b.dust] = true end
    if b.essence then mats[b.essence] = true end
    if b.shard then mats[b.shard] = true end
    if b.epic then mats[b.epic] = true end
  end
  for _, m in ipairs(step.mats or {}) do
    if mats[m[1]] then out[m[1]] = true end
    local part = ns.profPart and ns.profPart(key, m[1])
    local src = part and part.mats and part.mats[1]
    if src and mats[src[1]] then out[src[1]] = true end
  end
  return out
end

-- The item link in a bag slot: C_Container's table, else the classic call (link is its 7th return).
local function slotLink(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    return ok and type(info) == "table" and info.hyperlink or nil
  end
  local r = { pcall(GetContainerItemInfo, bag, slot) }
  return r[1] and r[8] or nil
end

local function slotCount(bag)
  local f = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
  local ok, n = pcall(f, bag)
  return (ok and tonumber(n)) or 0
end

-- Green, blue and epic weapons and armour in your bags (0-4), each { name, level, quality, weapon,
-- gives = { names } }: green armour gives dust or essence, green weapons essence or dust, blue
-- gear a shard, and high-level epics a crystal. Uncached items and unknown results are left out.
-- nil when there's no bag or item API.
function ns.deBagItems(key)
  local hasBags = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo)
    or (GetContainerNumSlots and GetContainerItemInfo)
  if not hasBags or not ns.itemInfoAPI() then return nil end
  local list = {}
  for bag = 0, 4 do
    for slot = 1, slotCount(bag) do
      local link = slotLink(bag, slot)
      if link then
        local r = { true, ns.itemInfo(link) }
        local name, quality, level, classID = r[2], tonumber(r[4]), tonumber(r[5]), tonumber(r[13])
        local band = name and ns.deBand(key, level)
        if band and quality and quality >= 2 and quality <= 4 and (classID == 2 or classID == 4) then
          local gives
          if quality == 2 then
            gives = classID == 2 and { band.essence, band.dust } or { band.dust, band.essence }
          else
            gives = { (quality == 4 and band.epic) or band.shard }
          end
          if gives[1] then
            list[#list + 1] = { name = name, level = level, quality = quality, weapon = classID == 2, gives = gives }
          end
        end
      end
    end
  end
  return list
end
