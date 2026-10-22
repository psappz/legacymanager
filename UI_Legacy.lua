local ADDON, ns = ...
local U, LG, W = ns.U, ns.Legacy, ns.W
local UIL = {}
ns.UILegacy = UIL

-- Additions to Blizzard's Legacy window. Nothing of Blizzard's is replaced or hooked
-- with hooksecurefunc: own frames are anchored to it and refreshed through the
-- window's EventRegistry callbacks and HookScript.

local owner = {} -- callback owner for EventRegistry
local READY_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"

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
-- Tree page: "13 / 16 spent · 3 free · +2 only for the Progress Track"
---------------------------------------------------------------------------
local function buildTreeSummary(page)
  local summary = page.LegacyTreePointSummary
  if not summary or UIL.treeBox then return end
  local box = W.Box(page, 200, 28)
  box:SetFrameLevel(summary:GetFrameLevel() + 1)
  local label = summary.AvailablePointsLabel or summary
  box:SetPoint("LEFT", label, "RIGHT", 30, -1)
  local fs = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", 10, 0)
  fs:SetJustifyH("LEFT")
  box.text = fs
  tooltip(box, function(tt)
    local p = LG.Points()
    tt:SetText(ns.L.TREE_TIP_TITLE, 1, 0.82, 0)
    tt:AddLine(ns.L.TREE_TIP_EARNED:format(p.earned), 1, 1, 1)
    tt:AddLine(ns.L.TREE_TIP_CAP:format(p.cap), 1, 1, 1)
    tt:AddLine(ns.L.TREE_TIP_SPENT:format(p.spent), 1, 1, 1)
    tt:AddLine(ns.L.TREE_TIP_FREE:format(p.free), 0.56, 0.89, 0.62)
    if p.over > 0 then tt:AddLine(ns.L.TREE_TIP_OVER, 0.94, 0.71, 0.35, true) end
  end)
  UIL.treeBox = box
end

function UIL.RefreshTree()
  local box = UIL.treeBox
  if not box or not box:IsVisible() then return end
  local p = LG.Points()
  local s = U.Color("ffffffff", ns.L.TREE_SPENT:format(p.spent, p.cap))
  if p.free > 0 then s = s .. "  ·  " .. U.Color(U.OK, ns.L.STATUS_FREE:format(p.free)) end
  if p.over > 0 then
    s = s .. "  ·  " .. U.Color(U.WARN, ns.L.TREE_OVER:format(p.over))
  elseif p.toCap > 0 then
    s = s .. "  ·  " .. U.Color(U.MUTED, ns.L.TREE_TO_CAP:format(p.toCap))
  end
  box.text:SetText(s)
  box:SetWidth(box.text:GetStringWidth() + 20)
end

---------------------------------------------------------------------------
-- Challenges page: "Mark all seen"
---------------------------------------------------------------------------
local function buildMarkSeen(page)
  local summary = page.LegacyChallengePointSummary
  if not summary or UIL.markSeen then return end
  local b = W.Button(page, ns.L.MARK_ALL_SEEN, READY_ICON, 24)
  b:SetFrameLevel(summary:GetFrameLevel() + 2)
  -- Left of the shield the header row is empty; right of the bar the frame ends.
  b:SetPoint("RIGHT", summary.Shield or summary, "LEFT", -14, 0)
  b.tip = { ns.L.MARK_ALL_SEEN, ns.L.MARK_ALL_TIP }
  b:SetScript("OnClick", function() ns.SafeCall("markSeen", LG.MarkAllSeen) end)
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
  if UIL.rewardBox then return end
  local box = W.Box(page, 300, 30)
  box:SetFrameLevel(page:GetFrameLevel() + 20)
  -- Between the "Legacy Points" label and the progress bar is a free strip of 55 px.
  if page.PointsLabel then box:SetPoint("TOP", page.PointsLabel, "BOTTOM", 0, -5)
  else box:SetPoint("TOP", page, "TOP", 0, -230) end
  local nextText = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  nextText:SetPoint("TOP", 0, -5)
  local bar = W.Bar(box, 4)
  bar:SetPoint("TOPLEFT", 10, -21)
  bar:SetPoint("TOPRIGHT", -10, -21)
  local ready = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ready:SetPoint("TOP", bar, "BOTTOM", 0, -4)
  ready:SetTextColor(0.94, 0.71, 0.35)
  box.nextText, box.bar, box.ready = nextText, bar, ready
  UIL.rewardBox = box
end

function UIL.RefreshRewards()
  local box = UIL.rewardBox
  if not box or not box:IsVisible() then return end
  local list, earned = LG.Rewards()
  local prev, nextEntry = 0, nil
  for _, e in ipairs(list) do
    if e.level <= earned then prev = e.level elseif not nextEntry then nextEntry = e end
  end
  if nextEntry then
    local missing = nextEntry.level - earned
    local names = table.concat(nextEntry.names, ", ")
    box.nextText:SetText(missing == 1 and ns.L.REWARD_NEXT_ONE:format(names) or ns.L.REWARD_NEXT:format(missing, names))
    box.bar:SetValue((earned - prev) / math.max(1, nextEntry.level - prev))
  else
    box.nextText:SetText(ns.L.REWARD_ALL)
    box.bar:SetValue(1)
  end
  local ready = LG.ReadyRewards()
  box.ready:SetText(#ready > 0 and ns.L.REWARD_READY:format(table.concat(ready, ", ")) or "")
  local w = math.max(box.nextText:GetStringWidth(), box.ready:GetStringWidth()) + 28
  box:SetWidth(math.max(260, w))
  box:SetHeight(#ready > 0 and 44 or 30)
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
