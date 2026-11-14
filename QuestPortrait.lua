-- QuestPortrait.lua: the step window's portrait, a small 3D model of the step's NPC (a pickup's giver,
-- a turn-in's finisher, a kill's first target) from QuestNPCData.lua, framed in gold like the game's
-- quest portraits. The step's icon shows instead when there is no NPC ID, the model hasn't loaded a
-- second after it was asked for, or the client has no PlayerModel frame.
local _, ns = ...

local SIZE, WAIT = 44, 1
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

  -- A model asked for a second ago that hasn't loaded gives way to the icon.
  p:SetScript("OnUpdate", function()
    if p.askedAt and GetTime() - p.askedAt >= WAIT then
      p.askedAt = nil
      if p.model and not loaded(p.model) then showIcon(p.step) end
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
    local id = type(entry) == "table" and entry[field] or nil
    self.step = step
    self:Show()
    if not (id and self.model) then
      self.creature, self.askedAt = id, nil
      showIcon(step)
      return true
    end
    if id ~= self.creature then
      self.creature = id
      self.model:SetCreature(id)
      if type(self.model.SetPortraitZoom) == "function" then pcall(self.model.SetPortraitZoom, self.model, 1) end
      self.askedAt = GetTime()
      self.model:Show()
      self.icon:Hide()
    end
    return true
  end

  return p
end
