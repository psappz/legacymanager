local ADDON, ns = ...
local U, W, D, CH, CP = ns.U, ns.W, ns.Data, ns.Challenges, ns.Copilot
local UM = {}
ns.UIMatrix = UM

-- Alt overview: classes and crafting professions against their Legacy milestones.

local NAME_W, CELL_W, CELL_H, GAP = 120, 168, 22, 4
local COLS = 3
local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t "

local COLORS = {
  done = { bg = { 0.11, 0.2, 0.14, 1 }, fg = { 0.56, 0.89, 0.62 } },
  near = { bg = { 0.075, 0.157, 0.247, 1 }, fg = { 0.81, 0.90, 1 } },
  open = { bg = { 0.078, 0.106, 0.137, 1 }, fg = { 0.37, 0.45, 0.53 } },
}

local function className(classFile)
  return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or classFile
end

local function classColor(classFile)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

local function makeCell(parent)
  local f = W.Box(parent, CELL_W, CELL_H)
  f:SetBackdropBorderColor(0, 0, 0, 0)
  f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.text:SetPoint("LEFT", 6, 0)
  f.text:SetPoint("RIGHT", -6, 0)
  f.text:SetJustifyH("LEFT")
  f.text:SetWordWrap(false)
  return f
end

local function setCell(cell, state, text)
  local c = COLORS[state]
  cell:SetBackdropColor(c.bg[1], c.bg[2], c.bg[3], c.bg[4])
  cell.text:SetTextColor(c.fg[1], c.fg[2], c.fg[3])
  cell.text:SetText(text)
end

local function makeRow(parent, y)
  local row = { name = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight"), cells = {} }
  row.name:SetPoint("TOPLEFT", 14, y - 4)
  row.name:SetWidth(NAME_W - 6)
  row.name:SetJustifyH("LEFT")
  for i = 1, COLS do
    local cell = makeCell(parent)
    cell:SetPoint("TOPLEFT", 14 + NAME_W + (i - 1) * (CELL_W + GAP), y)
    row.cells[i] = cell
  end
  return row
end

local function makeHeader(parent, y)
  local h = { label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"), cols = {} }
  h.label:SetPoint("TOPLEFT", 14, y)
  for i = 1, COLS do
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 14 + NAME_W + (i - 1) * (CELL_W + GAP), y)
    h.cols[i] = fs
  end
  return h
end

local function build()
  if UM.frame then return end
  local width = 28 + NAME_W + COLS * CELL_W + (COLS - 1) * GAP
  local f = W.Box(UIParent, width, 560)
  f:SetBackdropColor(0.094, 0.125, 0.165, 0.97)
  f:SetFrameStrata("HIGH")
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetClampedToScreen(true)
  f:Hide()
  tinsert(UISpecialFrames, "LegacyManagerMatrix")
  _G.LegacyManagerMatrix = f

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12)
  title:SetText(ns.L.MX_TITLE)
  title:SetTextColor(1, 0.82, 0)

  W.Close(f)

  -- Normal / Hardcore switch
  f.normalBtn = W.Button(f, ns.L.MX_NORMAL, nil, 22)
  f.hcBtn = W.Button(f, ns.L.MX_HARDCORE, nil, 22)
  f.hcBtn:SetPoint("TOPRIGHT", -34, -10)
  f.normalBtn:SetPoint("RIGHT", f.hcBtn, "LEFT", -4, 0)
  f.normalBtn:SetScript("OnClick", function() UM.view = "normal"; UM.Refresh() end)
  f.hcBtn:SetScript("OnClick", function() UM.view = "hardcore"; UM.Refresh() end)

  local y = -46
  f.classHeader = makeHeader(f, y)
  f.classHeader.label:SetText(ns.L.MX_CLASS)
  y = y - 16
  f.classRows = {}
  for i = 1, #CH.CLASS_ORDER do
    f.classRows[i] = makeRow(f, y)
    y = y - (CELL_H + GAP)
  end
  y = y - 10
  f.profHeader = makeHeader(f, y)
  f.profHeader.label:SetText(ns.L.MX_PROF)
  y = y - 16
  f.profRows = {}
  for i = 1, #D.CRAFTING do
    f.profRows[i] = makeRow(f, y)
    y = y - (CELL_H + GAP)
  end

  local plan = W.Box(f, width - 28, 44)
  plan:SetPoint("TOPLEFT", 14, y - 8)
  plan:SetBackdropColor(0.12, 0.165, 0.21, 1)
  plan:SetBackdropBorderColor(0.18, 0.29, 0.41, 1)
  plan.text = plan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  plan.text:SetPoint("TOPLEFT", 8, -6)
  plan.text:SetPoint("BOTTOMRIGHT", -8, 6)
  plan.text:SetJustifyH("LEFT")
  plan.text:SetJustifyV("TOP")
  plan.text:SetTextColor(0.81, 0.90, 1)
  f.plan = plan
  f:SetHeight(-(y - 8) + 44 + 14)

  f:SetScript("OnShow", function() ns.Schedule("lmMatrix", 0, UM.Refresh) end)
  UM.frame = f
end

local function fillMilestoneRow(row, milestones, cellFor)
  for i = 1, COLS do
    local m = milestones[i]
    local cell = row.cells[i]
    if m then
      cell:Show()
      setCell(cell, cellFor(m, milestones[i - 1]))
    else
      cell:Hide()
    end
  end
end

function UM.Refresh()
  local f = UM.frame
  if not f or not f:IsShown() then return end
  local L = ns.L
  local v = UM.view or ((D.IsHardcore() and "hardcore") or "normal")
  UM.view = v
  f.normalBtn:SetAlpha(v == "normal" and 1 or 0.55)
  f.hcBtn:SetAlpha(v == "hardcore" and 1 or 0.55)
  local chars = CP.Chars(v)

  -- classes
  local sample = CH.ClassMilestones("WARRIOR")
  for i = 1, COLS do
    f.classHeader.cols[i]:SetText(sample[i] and L.MX_LEVEL:format(sample[i].level) or "")
  end
  for i, classFile in ipairs(CH.CLASS_ORDER) do
    local row = f.classRows[i]
    row.name:SetText(className(classFile))
    row.name:SetTextColor(classColor(classFile))
    fillMilestoneRow(row, CH.ClassMilestones(classFile), function(m, prev)
      if m.completed then return "done", CHECK .. (m.earnedBy or "") end
      local c = CP.BestOfClass(chars, classFile, m.level)
      -- only in the next open milestone, like the copilot
      if c and (c.level or 1) >= (prev and prev.level or 1) then return "near", L.MX_NEAR_LEVEL:format(c.name, c.level or 1) end
      return "open", "–"
    end)
  end

  -- professions
  local missing, sampleProf = {}, CH.ProfMilestones(D.CRAFTING[1])
  for i = 1, COLS do
    f.profHeader.cols[i]:SetText(sampleProf[i] and L.MX_SKILL:format(sampleProf[i].skillReq or 0) or "")
  end
  for i, skill in ipairs(D.CRAFTING) do
    local row = f.profRows[i]
    row.name:SetText(CP.ProfName(skill))
    row.name:SetTextColor(1, 1, 1)
    local anyone = false
    for _, c in ipairs(chars) do if c.profs and c.profs[skill] then anyone = true end end
    if not anyone then missing[#missing + 1] = CP.ProfName(skill) end
    fillMilestoneRow(row, CH.ProfMilestones(skill), function(m, prev)
      if m.completed then return "done", CHECK .. (m.earnedBy or "") end
      local c, rank = CP.BestOfProf(chars, skill, m.skillReq or 0)
      if c and rank >= (prev and prev.skillReq or 0) then return "near", L.MX_NEAR_SKILL:format(c.name, rank) end
      return "open", "–"
    end)
  end

  -- profession planning: crafts nobody has yet, and who still has a free primary slot
  local text
  if #missing == 0 then
    text = L.MX_PLAN_ALL
  else
    local free = {}
    for _, c in ipairs(chars) do
      local primaries = 0
      for skill in pairs(c.profs or {}) do
        for _, list in ipairs({ D.CRAFTING, D.GATHERING }) do
          for _, id in ipairs(list) do if id == skill then primaries = primaries + 1 end end
        end
      end
      if primaries < 2 then free[#free + 1] = L.MX_FREE_SLOTS:format(c.name, 2 - primaries) end
    end
    text = L.MX_PLAN_MISSING:format(table.concat(missing, ", "))
    text = text .. "\n" .. (#free > 0 and L.MX_PLAN_FREE:format(table.concat(free, ", ")) or L.MX_PLAN_NOFREE)
  end
  f.plan.text:SetText(text)
end

function UM.Toggle()
  build()
  if UM.frame:IsShown() then UM.frame:Hide() else UM.frame:Show() end
end
