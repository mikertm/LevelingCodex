-- Alliance route, levels 50-60. Source notes: tools/audits/2026-11-10-alliance-50-60.md.
-- Uses the shared 30-60 helpers and travel data from QuestData3040.lua.
local B = LevelingCodexQuests.build
local M = B.maps
local at, q, quest = B.at, B.q, B.quest
local accept, finish, action, taxi = B.accept, B.finish, B.action, B.taxi
local objective, withItem, along, breadcrumb = B.objectiveAt, B.withItem, B.along, B.breadcrumb
local forDungeon, withGuide, note = B.forDungeon, B.withGuide, B.note
local on, section = B.on, B.section
