local ADDON, ns = ...
local U, W, GR = ns.U, ns.W, ns.Group
local UG = {}
ns.UIGroup = UG

-- Group view window: one row per group member, the group-relevant perks as columns.

local NAME_W, COL_W, ROW_H, VISIBLE, MIN_ROWS = 150, 96, 22, 15, 5
local TOP = 82 -- title, subtitle and the two-line header
local COLS = #GR.COLUMNS

local function spellName(spellID)
  return (C_Spell and C_Spell.GetSpellName and U.Try(C_Spell.GetSpellName, spellID))
    or (GetSpellInfo and U.Try(GetSpellInfo, spellID)) or tostring(spellID)
end

local function classColor(classFile)
  local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

---------------------------------------------------------------------------
local function showMemberTooltip(row)
  local m = row.member
  if not m then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(m.full or m.name or "?", classColor(m.class))
  if not m.ranks then
    GameTooltip:AddLine(ns.L.GV_NO_ADDON, 0.62, 0.71, 0.78, true)
    if not m.self then
      local told = ns.toldAbout and ns.toldAbout[m.guid]
      GameTooltip:AddLine(told and ns.L.GV_TOLD or ns.L.GV_TELL_HINT, 1, 0.82, 0, true)
    end
  else
    local list = {}
    for spellID, rank in pairs(m.ranks) do list[#list + 1] = { name = spellName(spellID), rank = rank } end
    table.sort(list, function(a, b) return a.name < b.name end)
    local total = 0
    for _, it in ipairs(list) do
      GameTooltip:AddDoubleLine(it.name, it.rank, 1, 1, 1, 0.56, 0.89, 0.62)
      total = total + it.rank
    end
    if #list == 0 then GameTooltip:AddLine(ns.L.GV_NONE_SPENT, 0.62, 0.71, 0.78) end
    GameTooltip:AddLine(ns.L.GV_TOTAL:format(total), 0.62, 0.71, 0.78)
  end
  GameTooltip:Show()
end

local function build()
  if UG.frame then return end
  local L = ns.L
  local width = 28 + NAME_W + COLS * COL_W
  local f = W.Box(UIParent, width, TOP + 44 + VISIBLE * ROW_H)
  f:SetBackdropColor(0.094, 0.125, 0.165, 0.97)
  f:SetFrameStrata("HIGH")
  f:SetPoint("CENTER", 200, 0)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetClampedToScreen(true)
  f:Hide()
  _G.LegacyManagerGroup = f
  tinsert(UISpecialFrames, "LegacyManagerGroup")

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12)
  title:SetText(L.GV_TITLE)
  title:SetTextColor(1, 0.82, 0)
  f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  f.sub:SetTextColor(0.62, 0.71, 0.78)

  W.Close(f)

  local refresh = W.Button(f, L.GV_REFRESH, nil, 22)
  refresh:SetPoint("TOPRIGHT", -34, -10)
  refresh:SetScript("OnClick", function() GR.Request(); UG.Refresh() end)

  -- header
  local hy = -54
  local hn = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hn:SetPoint("TOPLEFT", 14, hy)
  hn:SetText(L.GV_PLAYER)
  for i, spellID in ipairs(GR.COLUMNS) do
    local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetPoint("TOPLEFT", 14 + NAME_W + (i - 1) * COL_W, hy)
    h:SetWidth(COL_W - 8)
    h:SetHeight(26)
    h:SetJustifyH("LEFT")
    h:SetJustifyV("TOP")
    h:SetWordWrap(true)
    h:SetMaxLines(2)
    h:SetText(spellName(spellID))
  end

  f.rows = {}
  for r = 1, VISIBLE do
    local row = W.Box(f, width - 28, ROW_H - 2)
    row:SetBackdropColor(0.12, 0.165, 0.21, 1)
    row:SetBackdropBorderColor(0, 0, 0, 0)
    row:SetPoint("TOPLEFT", 14, -TOP - (r - 1) * ROW_H)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 6, 0)
    row.name:SetWidth(NAME_W - 10)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.cells = {}
    for i = 1, COLS do
      local c = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      c:SetPoint("LEFT", NAME_W + (i - 1) * COL_W, 0)
      row.cells[i] = c
    end
    row:EnableMouse(true)
    row:SetScript("OnEnter", showMemberTooltip)
    row:SetScript("OnMouseUp", function(self)
      local m = self.member
      if not m or m.ranks or m.self or not m.full then return end
      ns.toldAbout = ns.toldAbout or {}
      if ns.toldAbout[m.guid] then return end         -- once per member and session
      ns.toldAbout[m.guid] = true
      ns.SafeCall("tell", SendChatMessage, ns.L.GV_TELL_TEXT, "WHISPER", nil, m.full)
      showMemberTooltip(self)
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.rows[r] = row
  end

  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(_, delta)
    UG.offset = math.max(0, (UG.offset or 0) - delta * 3)
    UG.Refresh()
  end)

  f.summary = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.summary:SetPoint("BOTTOMLEFT", 14, 14)
  f.summary:SetPoint("RIGHT", -14, 0)
  f.summary:SetJustifyH("LEFT")
  f.summary:SetTextColor(0.81, 0.90, 1)

  f:SetScript("OnShow", function() UG.offset = 0; ns.Schedule("lmGroupUI", 0, UG.Refresh) end)
  UG.frame = f
end

function UG.Refresh()
  local f = UG.frame
  if not f or not f:IsShown() then return end
  local L = ns.L
  local roster = GR.Roster()
  local own = GR.OwnRanks()
  local known, withPerk = 0, {}
  for _, m in ipairs(roster) do
    if m.self then m.ranks = own
    else
      local data = GR.members[m.guid]
      m.ranks = data and data.ranks or nil
    end
    if m.ranks then
      known = known + 1
      for i, spellID in ipairs(GR.COLUMNS) do
        if (m.ranks[spellID] or 0) > 0 then withPerk[i] = (withPerk[i] or 0) + 1 end
      end
    end
  end
  -- members with LegacyManager first, then by name
  table.sort(roster, function(a, b)
    if (a.ranks ~= nil) ~= (b.ranks ~= nil) then return a.ranks ~= nil end
    return (a.name or "") < (b.name or "")
  end)

  local channel = GR.Channel()
  f.sub:SetText(channel and L.GV_SUB:format(known, #roster) or L.GV_SOLO)

  f:SetHeight(TOP + 44 + math.max(MIN_ROWS, math.min(VISIBLE, #roster)) * ROW_H)
  local maxOffset = math.max(0, #roster - VISIBLE)
  UG.offset = math.min(UG.offset or 0, maxOffset)
  for r, row in ipairs(f.rows) do
    local m = roster[r + UG.offset]
    row.member = m
    if m then
      row.name:SetText(m.name or "?")
      row.name:SetTextColor(classColor(m.class))
      for i, spellID in ipairs(GR.COLUMNS) do
        local cell = row.cells[i]
        if not m.ranks then
          cell:SetText(i == 1 and L.GV_NO_ADDON_SHORT or "")
          cell:SetTextColor(0.37, 0.45, 0.53)
        else
          local rank = m.ranks[spellID] or 0
          cell:SetText(rank > 0 and tostring(rank) or "–")
          if rank > 0 then cell:SetTextColor(0.56, 0.89, 0.62) else cell:SetTextColor(0.62, 0.71, 0.78) end
        end
      end
      row:Show()
    else
      row:Hide()
    end
  end

  -- summary: how many in the group profit from the buff-related perks
  local parts = {}
  for i, spellID in ipairs(GR.COLUMNS) do
    if withPerk[i] then parts[#parts + 1] = L.GV_COUNT:format(spellName(spellID), withPerk[i], known) end
  end
  f.summary:SetText(#parts > 0 and table.concat(parts, "  ·  ") or (channel and L.GV_NOBODY or ""))
end

function UG.Toggle()
  build()
  if UG.frame:IsShown() then UG.frame:Hide()
  else
    UG.frame:Show()
    GR.Request()
  end
end
