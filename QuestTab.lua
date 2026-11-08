local _, ns = ...
local Q, U, C = ns.quests, ns.ui, ns.C

local function render()
  local rows, sections, missed, level, selected = Q.rows()
  local current = Q.current()
  local y = U.sectionTitle("Quest Guide", 0)
  if #sections == 0 then
    return y + U.T("Your character has no published route yet.", 0, y, U.W, "body", C.dim) + 16
  end
  if not selected then
    y = y + U.T("No route covers level " .. tostring(level) .. ". Choose a section below to review it.",
      0, y, U.W, "body", C.dim) + 10
  end
  U.btn("Show step window", 0, y, 160, ns.showQuestViewer)
  U.btn("Copy recorder log", 170, y, 160, function() ns.questRecord("copy") end)
  y = y + 38
  y = y + U.T("Controller: select Show step window, then close this tab to focus the guide.",
    0, y, U.W, "small", C.dim) + 8
  for _, section in ipairs(sections) do
    U.btn(section.title, 0, y, 170, function()
      Q.jump(section)
      ns.showQuestViewer()
    end, selected == section)
    U.T(section.levels[1] .. "-" .. section.levels[2] .. (section.verified and "" or "  Unverified"),
      180, y + 4, U.W - 180, "small", C.dim)
    y = y + 28
  end
  if #missed > 0 then
    y = y + 10
    y = U.sectionTitle("Missed quests", y)
    for _, row in ipairs(missed) do
      U.btn(row.step.name, 0, y, 240, function()
        Q.jump(selected, row)
        ns.showQuestViewer()
      end, false, "Review this earlier pickup in the step window.")
      U.T(row.section.title, 252, y + 3, U.W - 252, "small", C.dim)
      y = y + 27
    end
  end
  for _, section in ipairs(sections) do
    y = U.sectionTitle(section.title, y + 12)
    for _, row in ipairs(rows) do
      if row.section == section and row.state ~= "filtered" then
        local mark = row == current and "NOW" or
          (row.state == "pending" and "Next" or row.state == "done" and "Done" or "Skipped")
        local color = row == current and C.gold or row.state == "pending" and C.ink or C.dim
        local text = Q.label(row.step) .. (row.step.forever and "  [Forever]" or "")
        U.T(mark, 0, y + 4, 58, "small", color)
        local h = U.T(text, 64, y + 4, U.W - 64, "body", color) + 8
        U.hit(0, y, U.W, h, text, row.step.text, function()
          Q.jump(section, row)
          ns.showQuestViewer()
        end)
        y = y + h
      end
    end
  end
  return y + 10
end

ns.addTab("quests", "Quests", render)
