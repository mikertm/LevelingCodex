-- Horde route: shared setup, then Durotar (Orc and Troll, 1-12). The other Horde files load
-- after this one and add their sections to LevelingCodexQuests.HORDE in level order.
-- Source notes: tools/audits/2026-11-10-horde-1-30.md.
local B = LevelingCodexQuests.build
local M = B.maps
local durotar, mulgore, barrens, tirisfal, silverpine = 1411, 1412, 1413, 1420, 1421
local orgrimmar, thunderBluff, undercity = 1454, 1456, 1458
local stonetalon, ashenvale, hillsbrad, needles = 1442, 1440, 1424, 1441
local alterac, arathi, desolace, dustwallow = 1416, 1417, 1443, 1445

M.durotar, M.mulgore, M.barrens, M.tirisfal, M.silverpine = durotar, mulgore, barrens, tirisfal, silverpine
M.orgrimmar, M.thunderBluff, M.undercity = orgrimmar, thunderBluff, undercity
M.stonetalon, M.ashenvale, M.hillsbrad, M.needles = stonetalon, ashenvale, hillsbrad, needles
M.alterac, M.arathi, M.desolace, M.dustwallow = alterac, arathi, desolace, dustwallow

-- Copy filter fields (class, race, optional...) onto a step built by accept/finish/action.
function B.only(step, rules)
  for key, value in pairs(rules) do step[key] = value end
  return step
end

local route = {
  -- Racial starts are added by the file that holds each start.
  starts = {},
  -- Width and height in yards, from UiMapAssignment in the Forever client reference.
  extents = {
    [durotar] = { 5287.5, 3525.0 }, [mulgore] = { 6154.167, 4102.082 }, [barrens] = { 10133.333, 6756.25 },
    [tirisfal] = { 4518.75, 3012.5 }, [silverpine] = { 4200.0, 2800.0 }, [orgrimmar] = { 1402.604, 935.417 },
    [thunderBluff] = { 1043.75, 695.833 }, [undercity] = { 959.375, 640.104 },
    [stonetalon] = { 4883.333, 3256.25 }, [ashenvale] = { 5766.666, 3843.75 }, [hillsbrad] = { 3200.0, 2133.333 },
    [needles] = { 4400.0, 2933.333 }, [alterac] = { 2800.0, 1866.667 }, [arathi] = { 3600.0, 2400.0 },
    [desolace] = { 4495.833, 2997.917 }, [dustwallow] = { 5250.0, 3500.0 },
  },
  -- Kalimdor and the Eastern Kingdoms are separate flight networks (zeppelins link them).
  flightNetwork = {
    [durotar] = 1, [orgrimmar] = 1, [mulgore] = 1, [thunderBluff] = 1, [barrens] = 1, [stonetalon] = 1,
    [ashenvale] = 1, [needles] = 1, [desolace] = 1, [dustwallow] = 1,
    [tirisfal] = 2, [undercity] = 2, [silverpine] = 2, [hillsbrad] = 2, [alterac] = 2, [arathi] = 2,
  },
  roadTo = {},
  sections = {},
}
LevelingCodexQuests.HORDE = route
