local ADDON, ns = ...
local W = {}
ns.W = W

-- LegacyManager's own look: dark blue panels with a blue border, so every
-- addition stands apart from Blizzard's frames (see the design draft).
W.C = {
  bg = { 0.075, 0.157, 0.247, 0.94 },
  bgHover = { 0.11, 0.23, 0.36, 0.96 },
  border = { 0.31, 0.64, 1, 1 },
  text = { 0.81, 0.90, 1 },
  gold = { 1, 0.82, 0 },
}

local BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  edgeSize = 1,
}

local function paint(f, bg)
  f:SetBackdrop(BACKDROP)
  f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  f:SetBackdropBorderColor(W.C.border[1], W.C.border[2], W.C.border[3], W.C.border[4])
end

function W.Box(parent, w, h)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetSize(w or 100, h or 24)
  paint(f, W.C.bg)
  return f
end

-- Button with an optional icon texture left of the label; width follows the label.
function W.Button(parent, text, icon, h)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetHeight(h or 24)
  paint(b, W.C.bg)
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetTextColor(W.C.text[1], W.C.text[2], W.C.text[3])
  fs:SetText(text)
  local pad = 10
  if icon then
    local t = b:CreateTexture(nil, "OVERLAY")
    t:SetSize(14, 14)
    t:SetTexture(icon)
    t:SetPoint("LEFT", pad, 0)
    fs:SetPoint("LEFT", t, "RIGHT", 5, 0)
    b:SetWidth(pad + 14 + 5 + fs:GetStringWidth() + pad)
  else
    fs:SetPoint("CENTER")
    b:SetWidth(fs:GetStringWidth() + 2 * pad)
  end
  b.label = fs
  b:SetScript("OnEnter", function(self)
    self:SetBackdropColor(W.C.bgHover[1], W.C.bgHover[2], W.C.bgHover[3], W.C.bgHover[4])
    if self.tip then
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetText(self.tip[1], 1, 0.82, 0)
      GameTooltip:AddLine(self.tip[2], 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function(self)
    self:SetBackdropColor(W.C.bg[1], W.C.bg[2], W.C.bg[3], W.C.bg[4])
    GameTooltip:Hide()
  end)
  return b
end

function W.Bar(parent, h)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetHeight(h or 4)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  bar:SetStatusBarColor(W.C.gold[1], W.C.gold[2], W.C.gold[3])
  bar:SetMinMaxValues(0, 1)
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.04, 0.06, 0.09, 1)
  return bar
end
