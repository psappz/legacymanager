local ADDON, ns = ...
local U, W, LG, CH, CP = ns.U, ns.W, ns.Legacy, ns.Challenges, ns.Copilot
local UC = {}
ns.UICopilot = UC

local PANEL_W, CARD_H, MAX_CARDS = 300, 64, 6
local owner = {}

local function view() return (ns.Data.IsHardcore() and "hardcore") or "normal" end

---------------------------------------------------------------------------
-- Copilot panel, docked right of the Legacy window
---------------------------------------------------------------------------
local function makeCard(parent)
  local card = W.Box(parent, PANEL_W - 20, CARD_H)
  card:SetBackdropColor(0.12, 0.165, 0.21, 1)
  card:SetBackdropBorderColor(0.18, 0.29, 0.41, 1)
  card.title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  card.title:SetPoint("TOPLEFT", 8, -6)
  card.title:SetPoint("RIGHT", -34, 0)
  card.title:SetJustifyH("LEFT")
  card.title:SetWordWrap(false)
  card.plus = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  card.plus:SetPoint("TOPRIGHT", -8, -7)
  card.who = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  card.who:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -3)
  card.who:SetPoint("RIGHT", -8, 0)
  card.who:SetJustifyH("LEFT")
  card.who:SetWordWrap(false)
  card.who:SetTextColor(0.62, 0.71, 0.78)
  card.bar = W.Bar(card, 4)
  card.bar:SetStatusBarColor(0.31, 0.64, 1)
  card.bar:SetPoint("TOPLEFT", card.who, "BOTTOMLEFT", 0, -4)
  card.bar:SetPoint("RIGHT", -8, 0)
  card.detail = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  card.detail:SetPoint("TOPLEFT", card.bar, "BOTTOMLEFT", 0, -4)
  card.detail:SetPoint("RIGHT", -8, 0)
  card.detail:SetJustifyH("LEFT")
  card.detail:SetWordWrap(false)
  card.detail:SetTextColor(0.81, 0.90, 1)
  card:EnableMouse(true)
  card:SetScript("OnMouseUp", function(self)
    if self.achievementID and ShowLegacyChallenge then ns.SafeCall("showChallenge", ShowLegacyChallenge, self.achievementID) end
  end)
  return card
end

local function build()
  if UC.panel or not LegacySystemFrame then return end
  local p = W.Box(LegacySystemFrame, PANEL_W, 520)
  -- Blizzard's page tabs hang outside the right edge of the window: start right of them.
  local tab = LegacySystemFrame.LegacyRewardTrackTab or (LegacySystemFrame.Tabs and LegacySystemFrame.Tabs[1])
  p:SetPoint("TOP", LegacySystemFrame, "TOP", 0, 0)
  p:SetPoint("BOTTOM", LegacySystemFrame, "BOTTOM", 0, 0)
  if tab then p:SetPoint("LEFT", tab, "RIGHT", 6, 0)
  else p:SetPoint("LEFT", LegacySystemFrame, "RIGHT", 50, 0) end
  p:SetBackdropColor(0.094, 0.125, 0.165, 0.97)

  local head = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  head:SetPoint("TOPLEFT", 12, -10)
  head:SetText("LegacyManager")
  head:SetTextColor(1, 0.82, 0)
  local sub = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
  sub:SetTextColor(0.62, 0.71, 0.78)
  p.sub = sub

  local close = CreateFrame("Button", nil, p, "UIPanelCloseButtonNoScripts")
  close:SetPoint("TOPRIGHT", 2, 2)
  close:SetScript("OnClick", function()
    ns.db.copilotHidden = true
    p:Hide()
    U.Print(ns.L.CP_HIDDEN)
  end)

  -- next reward strip
  local rw = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  rw:SetPoint("TOPLEFT", 12, -52)
  rw:SetPoint("RIGHT", -12, 0)
  rw:SetJustifyH("LEFT")
  rw:SetTextColor(0.81, 0.90, 1)
  local rbar = W.Bar(p, 5)
  rbar:SetPoint("TOPLEFT", rw, "BOTTOMLEFT", 0, -4)
  rbar:SetPoint("RIGHT", -12, 0)
  p.reward, p.rewardBar = rw, rbar

  local line = p:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(0.18, 0.29, 0.41, 1)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", 1, -84)
  line:SetPoint("TOPRIGHT", -1, -84)

  p.cards = {}
  for i = 1, MAX_CARDS do
    local c = makeCard(p)
    c:SetPoint("TOPLEFT", 10, -92 - (i - 1) * (CARD_H + 6))
    p.cards[i] = c
  end
  p.empty = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  p.empty:SetPoint("TOPLEFT", 14, -96)
  p.empty:SetPoint("RIGHT", -14, 0)
  p.empty:SetJustifyH("LEFT")
  p.empty:SetTextColor(0.62, 0.71, 0.78)
  p.empty:SetText(ns.L.CP_EMPTY)

  p.unknown = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  p.unknown:SetPoint("BOTTOMLEFT", 12, 44)
  p.unknown:SetPoint("RIGHT", -12, 0)
  p.unknown:SetJustifyH("LEFT")
  p.unknown:SetTextColor(0.94, 0.71, 0.35)

  local mx = W.Button(p, ns.L.BTN_MATRIX, nil, 26)
  mx:SetPoint("BOTTOMLEFT", 12, 12)
  mx:SetPoint("BOTTOMRIGHT", p, "BOTTOM", -3, 12)
  local gv = W.Button(p, ns.L.BTN_GROUP, nil, 26)
  gv:SetPoint("BOTTOMLEFT", p, "BOTTOM", 3, 12)
  gv:SetPoint("BOTTOMRIGHT", -12, 12)
  gv:SetScript("OnClick", function() ns.SafeCall("group", ns.UIGroup.Toggle) end)
  mx:SetScript("OnClick", function() ns.SafeCall("matrix", ns.UIMatrix.Toggle) end)

  p:SetScript("OnShow", function() ns.Schedule("lmCopilot", 0, UC.Refresh) end)
  UC.panel = p
end

function UC.Refresh()
  local p = UC.panel
  if not p or not p:IsVisible() then return end
  local L = ns.L
  local v = view()
  p.sub:SetText(v == "hardcore" and L.CP_SUB_HC or L.CP_SUB)

  local list, earned = LG.Rewards()
  local prev, nextEntry = 0, nil
  for _, e in ipairs(list) do
    if e.level <= earned then prev = e.level elseif not nextEntry then nextEntry = e end
  end
  if nextEntry then
    local names = table.concat(nextEntry.names, ", ")
    local missing = nextEntry.level - earned
    p.reward:SetText(missing == 1 and L.REWARD_NEXT_ONE:format(names) or L.REWARD_NEXT:format(missing, names))
    p.rewardBar:SetValue((earned - prev) / math.max(1, nextEntry.level - prev))
  else
    p.reward:SetText(L.REWARD_ALL)
    p.rewardBar:SetValue(1)
  end

  local items, unknown = CP.Suggestions(v, MAX_CARDS)
  for i, card in ipairs(p.cards) do
    local s = items[i]
    if s then
      card.achievementID = s.ch.id
      card.title:SetText(s.ch.name)
      card.plus:SetText("+" .. (s.ch.points or 1))
      card.who:SetText(s.who)
      card.bar:SetValue(math.min(1, math.max(0, s.pct)))
      card.detail:SetText(s.detail or "")
      card:Show()
    else
      card.achievementID = nil
      card:Hide()
    end
  end
  p.empty:SetShown(#items == 0)
  p.unknown:SetText(unknown > 0 and L.CP_UNKNOWN:format(unknown) or "")
end

---------------------------------------------------------------------------
-- Hint line in Blizzard's challenge cards: who earned it, or who is closest
---------------------------------------------------------------------------
local function hintFor(id)
  local ch = CH.Get() and CH.byID and CH.byID[id]
  if not ch then return nil end
  if ch.completed then
    return ch.earnedBy and U.Color("ff9fd0ff", ns.L.HINT_EARNED:format(ch.earnedBy)) or nil
  end
  local s = CP.ForChallenge(ch, CP.Chars(view()))
  if not s then return nil end
  return U.Color("ff9fd0ff", ns.L.HINT_NEAR:format(s.who)) .. "  " .. U.Color("ffcfe6ff", s.detail or "")
end

local function decorate(_, frame, elementData)
  if not frame or not elementData then return end
  if not frame.lmHint then
    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 76, 12)
    fs:SetPoint("RIGHT", frame, "RIGHT", -60, 0)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    frame.lmHint = fs
  end
  local ok, text = pcall(hintFor, elementData.id)
  frame.lmHint:SetText(ok and text or "")
  frame.lmHint:SetShown(ok and text ~= nil)
end

local function attachHints()
  local pane = LegacySystemFrame.ChallengesPage and LegacySystemFrame.ChallengesPage.DetailPane
  local box = pane and pane.ScrollBox
  if not box or not ScrollUtil or not ScrollUtil.AddInitializedFrameCallback then return end
  ScrollUtil.AddInitializedFrameCallback(box, decorate, owner, true)
  UC.scrollBox = box
end

function UC.RefreshHints()
  if UC.scrollBox and UC.scrollBox:IsVisible() then
    UC.scrollBox:ForEachFrame(function(frame, elementData) decorate(nil, frame, elementData) end)
  end
end

---------------------------------------------------------------------------
function UC.Attach()
  if UC.attached or not LegacySystemFrame then return end
  UC.attached = true
  build()
  attachHints()
  UC.panel:SetShown(not ns.db.copilotHidden)
end

function UC.ToggleShown()
  ns.db.copilotHidden = not ns.db.copilotHidden
  if UC.panel then UC.panel:SetShown(not ns.db.copilotHidden) end
  U.Print(ns.db.copilotHidden and ns.L.CP_HIDDEN or ns.L.CP_SHOWN)
end

-- Character data changed (level, XP, skill): redraw what is visible.
function UC.Redraw()
  ns.Schedule("lmCopilot", 0.3, function()
    UC.Refresh()
    UC.RefreshHints()
    if ns.UIMatrix then ns.UIMatrix.Refresh() end
  end)
end

-- Challenge data changed (achievement earned, criteria progress): rescan, then redraw.
function UC.DataChanged()
  CH.Invalidate()
  UC.Redraw()
end
