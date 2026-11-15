-- QuestPortrait.lua: the step window's portrait, a small 3D model of the step's NPC (a pickup's giver,
-- a turn-in's finisher, a kill's first target) from QuestNPCData.lua, framed in gold like the game's
-- quest portraits. The step's icon shows instead when there is no NPC ID or the client has no
-- PlayerModel frame, and while the model is still loading: SetCreature only draws a creature the
-- client has seen, so an NPC you haven't met yet can take a while (it is asked again after 3 s and
-- given up on after 10 s). Talking to or targeting that NPC shows its model from that unit at once.
-- A creature the client can't draw yet leaves the old model on screen (it reported Tavernkeep Smitts
-- for Zombie Juice's Abercrombie), so the model is cleared before each new creature.
local _, ns = ...

local SIZE, WAIT, RETRY, GIVE_UP, TICK = 44, 1, 3, 10, 0.2
local WHO = { accept = "start", turnin = "finish", kill = "mob" }

local function edges(p)
  for i = 1, 4 do
    local e = p:CreateTexture(nil, "OVERLAY")
    e:SetColorTexture(0.85, 0.68, 0.3, 1)
    if i <= 2 then
      e:SetPoint(i == 1 and "TOPLEFT" or "BOTTOMLEFT")
      e:SetPoint(i == 1 and "TOPRIGHT" or "BOTTOMRIGHT")
      e:SetHeight(2)
    else
      e:SetPoint(i == 3 and "TOPLEFT" or "TOPRIGHT")
      e:SetPoint(i == 3 and "BOTTOMLEFT" or "BOTTOMRIGHT")
      e:SetWidth(2)
    end
  end
end

-- The model's file once it has loaded (nil = not loaded or nothing to show); without the call,
-- assume it loaded.
local function loaded(model)
  if type(model.GetModelFileID) ~= "function" then return true end
  local ok, file = pcall(model.GetModelFileID, model)
  return ok and file ~= nil and file ~= 0
end

-- A unit's creature ID ("Creature-0-server-instance-zone-ID-spawn"), nil for players and pets.
local function unitCreature(unit)
  if type(UnitGUID) ~= "function" then return nil end
  local ok, guid = pcall(UnitGUID, unit)
  if not ok or type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) then return nil end
  return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end

function ns.makeQuestPortrait(parent)
  local p = CreateFrame("Frame", nil, parent)
  p:SetSize(SIZE, SIZE)
  p.back = p:CreateTexture(nil, "BACKGROUND")
  p.back:SetPoint("TOPLEFT", 2, -2)
  p.back:SetPoint("BOTTOMRIGHT", -2, 2)
  p.back:SetColorTexture(0.05, 0.09, 0.11, 1)
  local ok, model = pcall(CreateFrame, "PlayerModel", nil, p)
  if ok and model then
    p.model = model
    model:SetPoint("TOPLEFT", 2, -2)
    model:SetPoint("BOTTOMRIGHT", -2, 2)
    model:Hide()
  end
  p.icon = p:CreateTexture(nil, "ARTWORK")
  p.icon:SetPoint("CENTER")
  p.icon:Hide()
  edges(p)
  p:Hide()

  local function showIcon(step)
    if p.model then p.model:Hide() end
    ns.questMap.paintIcon(p.icon, step, 26, 12)
    p.icon:Show()
  end

  -- The NPC is the one you talk to or your target: draw it from that unit, which is always loaded.
  local function fromTarget()
    if not (p.model and p.creature and type(p.model.SetUnit) == "function") then return false end
    for _, unit in ipairs({ "npc", "target" }) do
      if unitCreature(unit) == p.creature and pcall(p.model.SetUnit, p.model, unit) then
        p.model:Show()
        p.icon:Hide()
        return true
      end
    end
    return false
  end

  -- While a model loads: the icon after a second, the model as soon as it has loaded, one more
  -- SetCreature at 3 s, the icon for good at 10 s.
  local nextCheck = 0
  p:SetScript("OnUpdate", function()
    if not p.askedAt then return end
    local now = GetTime()
    if now < nextCheck then return end
    nextCheck = now + TICK
    local waited = now - p.askedAt
    if loaded(p.model) then
      p.askedAt = nil
      p.model:Show()
      p.icon:Hide()
      return
    end
    if waited >= WAIT and not p.icon:IsShown() then
      ns.questMap.paintIcon(p.icon, p.step, 26, 12)
      p.icon:Show()
    end
    if fromTarget() then return end
    if waited >= RETRY and not p.retried then
      p.retried = true
      p.model:SetCreature(p.creature)
    end
    if waited >= GIVE_UP then
      p.askedAt = nil
      showIcon(p.step)
    end
  end)

  -- Targeting the step's NPC after the model gave up (or while it loads) shows it from the target.
  pcall(p.RegisterEvent, p, "PLAYER_TARGET_CHANGED")
  p:SetScript("OnEvent", function()
    if p:IsShown() and p.creature and p.model and not (p.model:IsShown() and loaded(p.model)) and fromTarget() then
      p.askedAt = GetTime()
    end
  end)

  -- Shows the portrait for a step of this kind (QuestMap.lua's kinds); false (hidden) for other kinds
  -- or with Settings > Show the NPC portrait off.
  function p:ShowFor(step, kind)
    local field = WHO[kind]
    if not (step and field) or ns.db().noQuestPortrait then
      self:Hide()
      self.creature, self.askedAt = nil, nil
      return false
    end
    local entry = step.quest and ns.questNPCs and ns.questNPCs[step.quest]
    -- The NPC the step names first (a class quest every trainer gives, one of several givers).
    local by = type(entry) == "table" and type(entry.by) == "table" and step.npc and entry.by[step.npc]
    local id = by or (type(entry) == "table" and entry[field]) or nil
    self.step = step
    self:Show()
    if not (id and self.model) then
      self.creature, self.askedAt = id, nil
      showIcon(step)
      return true
    end
    if id ~= self.creature then
      self.creature, self.retried = id, nil
      if type(self.model.ClearModel) == "function" then pcall(self.model.ClearModel, self.model) end
      self.model:SetCreature(id)
      if type(self.model.SetPortraitZoom) == "function" then pcall(self.model.SetPortraitZoom, self.model, 1) end
      self.askedAt = GetTime()
      self.model:Show()
      self.icon:Hide()
      fromTarget()
    end
    return true
  end

  return p
end
