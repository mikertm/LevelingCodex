local _, ns = ...
local L=ns.loot
local target
function L.mapTarget() return target end
function L.showSourceOnMap(sourceID)
  local s=ns.lootData and ns.lootData.sources[sourceID]
  if not s or not s.map or type(s.x)~="number" or type(s.y)~="number" then return false,"This source has no verified map location" end
  if not C_Map or type(C_Map.SetUserWaypoint)~="function" then return false,"This client cannot set a map waypoint" end
  if L.call(C_Map.CanSetUserWaypointOnMap,s.map)==false then return false,"This map does not support waypoints" end
  local point=L.call(UiMapPoint and UiMapPoint.CreateFromCoordinates,s.map,s.x/100,s.y/100)
    or {uiMapID=s.map,position=L.call(CreateVector2D,s.x/100,s.y/100) or {x=s.x/100,y=s.y/100}}
  local ok=pcall(C_Map.SetUserWaypoint,point)
  if not ok then return false,"The game could not set this waypoint" end
  target={sourceID=sourceID,map=s.map,x=s.x,y=s.y,label=s.name,kind=s.locationKind or "source"}
  L.call(C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint,true)
  if type(OpenWorldMap)=="function" then L.call(OpenWorldMap,s.map)
  elseif WorldMapFrame then L.call(WorldMapFrame.Show,WorldMapFrame);L.call(WorldMapFrame.SetMapID,WorldMapFrame,s.map) end
  return true,"Mapped "..(s.locationKind=="entrance" and "entrance: " or "")..(s.name or "loot source")
end
function L.clearMapTarget()
  if not target then return end
  local point=L.call(C_Map and C_Map.GetUserWaypoint)
  -- Never clear a later waypoint placed by the player or another feature.
  if not point or point.uiMapID==target.map and point.position and math.abs((point.position.x or -1)-target.x/100)<0.00001
    and math.abs((point.position.y or -1)-target.y/100)<0.00001 then L.call(C_Map and C_Map.ClearUserWaypoint) end
  target=nil
end
function L.openQuestSource(quest)
  local faction=L.call(UnitFactionGroup,"player")
  local route=LevelingCodexQuests and LevelingCodexQuests[(faction or "Alliance"):upper()]
  for _,section in ipairs(route and route.sections or {}) do
    for _,step in ipairs(section.steps or {}) do
      if step.quest==quest then ns.openQuestGuide(section);return true end
    end
  end
  if ns.say then ns.say("This quest is outside your current Codex route library.") end
  return false
end
