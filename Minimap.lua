-- Minimap.lua: the minimap button (the Level 60 badge) and the entry in Forever's addon
-- compartment (the addons button under the clock). Click to open, drag the button around the
-- minimap and it stays there.

local _, ns = ...
local C, rgba = ns.C, ns.rgba

ns.ADDON_ICON = "achievement_level_60"
-- Right side, a little up: clear of Forever's own buttons (top) and of the lower-left spot most
-- addon buttons default to.
local DEFAULT_ANGLE = 10

local mini

local function placeMini()
  if not mini then return end
  local angle = math.rad(ns.db().minimapAngle or DEFAULT_ANGLE)
  local r = (Minimap:GetWidth() / 2) + 6
  local x, y = math.cos(angle), math.sin(angle)
  local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
  if square then
    -- slide along the edge of a square minimap
    x = math.max(-1, math.min(1, x * 1.42))
    y = math.max(-1, math.min(1, y * 1.42))
  end
  mini:ClearAllPoints()
  mini:SetPoint("CENTER", Minimap, "CENTER", x * r, y * r)
end

local function miniDrag()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  cx, cy = cx / scale, cy / scale
  ns.db().minimapAngle = math.deg(math.atan2(cy - my, cx - mx)) % 360
  placeMini()
end

-- The tooltip for the button and the compartment entry (drag only applies to the button).
local function showTip(owner, isButton)
  local D = ns.D
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:SetText("The Leveling Codex", rgba(C.tipTitle))
  if D then GameTooltip:AddLine(D.spec .. " " .. (ns.CLASS_NAME or "") .. " - level " .. UnitLevel("player"), 0.8, 0.8, 0.8) end
  local hit, rank
  if D then hit, rank = ns.talentAt(UnitLevel("player")) end
  if hit then GameTooltip:AddLine("Talent now: " .. hit.name .. " " .. rank .. "/" .. hit.max, 1, 1, 1) end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("|cffffd100Left-click|r  open the Codex", 1, 1, 1)
  GameTooltip:AddLine("|cffffd100Right-click|r  settings", 1, 1, 1)
  if isButton then GameTooltip:AddLine("|cffffd100Drag|r  move it around the minimap", 1, 1, 1) end
  GameTooltip:Show()
end

local function onClick(button)
  if button == "RightButton" then ns.openTab("settings") else ns.toggleWindow() end
end

-- Forever's addon compartment, once per session (clients without one keep just the button).
local inCompartment = false
local function addToCompartment()
  if inCompartment then return end
  local frame = AddonCompartmentFrame
  if type(frame) ~= "table" or type(frame.RegisterAddon) ~= "function" then return end
  inCompartment = pcall(frame.RegisterAddon, frame, {
    text = "The Leveling Codex",
    icon = ns.iconPath(ns.ADDON_ICON),
    notCheckable = true,
    func = function(_, input) onClick(type(input) == "table" and input.buttonName or "LeftButton") end,
    funcOnEnter = function(owner) showTip(owner, false) end,
    funcOnLeave = function() GameTooltip:Hide() end,
  })
end

local function makeMini()
  if mini or not Minimap then return end
  mini = CreateFrame("Button", "LevelingCodexMinimapButton", Minimap)
  mini:SetSize(31, 31)
  mini:SetFrameStrata("MEDIUM")
  mini:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  mini:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  mini:RegisterForDrag("LeftButton")

  local back = mini:CreateTexture(nil, "BACKGROUND")
  back:SetSize(20, 20); back:SetPoint("TOPLEFT", 7, -5)
  back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  local ico = mini:CreateTexture(nil, "ARTWORK")
  ico:SetSize(18, 18); ico:SetPoint("TOPLEFT", 7, -6)
  ns.setIcon(ico, ns.ADDON_ICON)
  ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  mini.icon = ico
  local border = mini:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  mini:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  mini:SetScript("OnClick", function(_, button) onClick(button) end)
  mini:SetScript("OnDragStart", function(self)
    self.icon:SetTexCoord(0, 1, 0, 1)
    self:SetScript("OnUpdate", miniDrag)
  end)
  mini:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    placeMini()
  end)
  mini:SetScript("OnEnter", function(self) showTip(self, true) end)
  mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
  placeMini()
end

-- Show, hide or re-place the button to match the settings.
function ns.updateMini()
  addToCompartment()
  if ns.db().noMinimap then
    if mini then mini:Hide() end
  else
    makeMini()
    if mini then mini:Show(); placeMini() end
  end
end
