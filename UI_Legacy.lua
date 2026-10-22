local ADDON, ns = ...
local U, LG = ns.U, ns.Legacy
local UIL = {}
ns.UILegacy = UIL

-- Additions to Blizzard's Legacy window. Nothing of Blizzard's is replaced or hooked
-- with hooksecurefunc: own frames are anchored to it and refreshed through the
-- window's EventRegistry callbacks and HookScript.

local owner = {} -- callback owner for EventRegistry

local function tooltip(frame, build)
  frame:EnableMouse(true)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    ns.SafeCall("tooltip", build, GameTooltip)
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- Tree page: "10 / 16 spent · +2 only for the Progress Track"
---------------------------------------------------------------------------
local function buildTreeSummary(page)
  local summary = page.LegacyTreePointSummary
  if not summary or UIL.treeText then return end
  local f = CreateFrame("Frame", nil, page)
  f:SetFrameLevel(summary:GetFrameLevel() + 1)
  f:SetSize(360, 24)
  local label = summary.AvailablePointsLabel or summary
  f:SetPoint("LEFT", label, "RIGHT", 34, 0)
  local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT")
  fs:SetJustifyH("LEFT")
  f.text = fs
  tooltip(f, function(tt)
    local p = LG.Points()
    tt:SetText(ns.L.TREE_TIP_TITLE, 1, 0.82, 0)
    tt:AddLine(ns.L.TREE_TIP_EARNED:format(p.earned), 1, 1, 1)
    tt:AddLine(ns.L.TREE_TIP_CAP:format(p.cap), 1, 1, 1)
    tt:AddLine(ns.L.TREE_TIP_SPENT:format(p.spent), 1, 1, 1)
    tt:AddLine(ns.L.TREE_TIP_FREE:format(p.free), 0.56, 0.89, 0.62)
    if p.over > 0 then tt:AddLine(ns.L.TREE_TIP_OVER, 0.94, 0.71, 0.35, true) end
  end)
  UIL.treeText = f
end

function UIL.RefreshTree()
  local f = UIL.treeText
  if not f or not f:IsVisible() then return end
  local p = LG.Points()
  local s = ns.L.TREE_SPENT:format(p.spent, p.cap)
  if p.over > 0 then
    s = s .. "  ·  " .. U.Color(U.WARN, ns.L.TREE_OVER:format(p.over))
  elseif p.toCap > 0 then
    s = s .. "  ·  " .. U.Color(U.MUTED, ns.L.TREE_TO_CAP:format(p.toCap))
  end
  f.text:SetText(s)
end

---------------------------------------------------------------------------
-- Challenges page: "Mark all seen"
---------------------------------------------------------------------------
local function buildMarkSeen(page)
  local summary = page.LegacyChallengePointSummary
  if not summary or UIL.markSeen then return end
  local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
  b:SetSize(112, 22)
  b:SetFrameLevel(summary:GetFrameLevel() + 2)
  b:SetPoint("LEFT", summary, "RIGHT", 18, -2)
  b:SetText(ns.L.MARK_ALL_SEEN)
  b:SetScript("OnClick", function() ns.SafeCall("markSeen", LG.MarkAllSeen) end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(ns.L.MARK_ALL_SEEN, 1, 0.82, 0)
    GameTooltip:AddLine(ns.L.MARK_ALL_TIP, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:Hide()
  UIL.markSeen = b
end

function UIL.RefreshMarkSeen()
  if UIL.markSeen then UIL.markSeen:SetShown(LG.HasUnseen()) end
end

---------------------------------------------------------------------------
-- Reward track page: points to the next reward, rewards ready to collect
---------------------------------------------------------------------------
local function buildRewardInfo(page)
  if UIL.rewardInfo then return end
  local f = CreateFrame("Frame", nil, page)
  f:SetFrameLevel(page:GetFrameLevel() + 20)
  f:SetSize(700, 34)
  f:SetPoint("BOTTOM", page, "BOTTOM", 0, 8)
  local next = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  next:SetPoint("TOP")
  local ready = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ready:SetPoint("TOP", next, "BOTTOM", 0, -3)
  f.next, f.ready = next, ready
  UIL.rewardInfo = f
end

function UIL.RefreshRewards()
  local f = UIL.rewardInfo
  if not f or not f:IsVisible() then return end
  local e, missing = LG.NextReward()
  if e then
    local names = table.concat(e.names, ", ")
    f.next:SetText(missing == 1 and ns.L.REWARD_NEXT_ONE:format(names) or ns.L.REWARD_NEXT:format(missing, names))
  else
    f.next:SetText(ns.L.REWARD_ALL)
  end
  local ready = LG.ReadyRewards()
  f.ready:SetText(#ready > 0 and ns.L.REWARD_READY:format(table.concat(ready, ", ")) or "")
end

---------------------------------------------------------------------------
function UIL.RefreshAll()
  ns.SafeCall("refreshTree", UIL.RefreshTree)
  ns.SafeCall("refreshSeen", UIL.RefreshMarkSeen)
  ns.SafeCall("refreshRewards", UIL.RefreshRewards)
end

function UIL.Attach()
  local frame = LegacySystemFrame
  if UIL.attached or not frame then return end
  UIL.attached = true

  if frame.TreePage then
    buildTreeSummary(frame.TreePage)
    frame.TreePage:HookScript("OnShow", function() ns.Schedule("lmTree", 0, UIL.RefreshTree) end)
  end
  if frame.ChallengesPage then
    buildMarkSeen(frame.ChallengesPage)
    frame.ChallengesPage:HookScript("OnShow", function() ns.Schedule("lmSeen", 0, UIL.RefreshMarkSeen) end)
  end
  if frame.RewardTrackPage then
    buildRewardInfo(frame.RewardTrackPage)
    frame.RewardTrackPage:HookScript("OnShow", function() ns.Schedule("lmRewards", 0, UIL.RefreshRewards) end)
  end

  if EventRegistry then
    EventRegistry:RegisterCallback("Legacy.UpdateCurrencyInfo", function() ns.Schedule("lmRefresh", 0.1, UIL.RefreshAll) end, owner)
    EventRegistry:RegisterCallback("Legacy.UnviewedChallengesUpdated", function() ns.Schedule("lmSeen", 0, UIL.RefreshMarkSeen) end, owner)
  end
  UIL.RefreshAll()
end
