local ADDON, ns = ...
local U, W, LO, SW = ns.U, ns.W, ns.Loadouts, ns.Swap
local UT = {}
ns.UITrainer = UT

local PANEL_W, MAX_LOADOUTS, MAX_ROWS = 340, 8, 7

---------------------------------------------------------------------------
-- Quick swap panel next to the class trainer's dialog
---------------------------------------------------------------------------
local function build()
  if UT.panel or not GossipFrame then return end
  local L = ns.L
  local p = W.Box(GossipFrame, PANEL_W, 540)
  p:SetBackdropColor(0.094, 0.125, 0.165, 0.97)
  p:SetPoint("TOPLEFT", GossipFrame, "TOPRIGHT", 6, 0)
  p:SetFrameStrata(GossipFrame:GetFrameStrata())
  p:Hide()

  local head = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  head:SetPoint("TOPLEFT", 12, -10)
  head:SetText(L.TR_TITLE)
  head:SetTextColor(1, 0.82, 0)
  p.sub = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  p.sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
  p.sub:SetTextColor(0.62, 0.71, 0.78)

  -- loadout buttons, two columns
  p.buttons = {}
  local bw = (PANEL_W - 24 - 6) / 2
  for i = 1, MAX_LOADOUTS do
    local b = W.Button(p, "", nil, 34)
    b:SetWidth(bw)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    b:SetPoint("TOPLEFT", 12 + col * (bw + 6), -52 - row * 38)
    b.label:ClearAllPoints()
    b.label:SetPoint("TOP", 0, -5)
    b.label:SetFontObject("GameFontHighlight")
    b.label:SetWidth(bw - 12)
    b.label:SetWordWrap(false)
    b.tag = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.tag:SetPoint("BOTTOM", 0, 4)
    b:SetScript("OnClick", function(self) UT.selected = self.loadout and self.loadout.name; UT.Refresh() end)
    p.buttons[i] = b
  end

  p.empty = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  p.empty:SetPoint("TOPLEFT", 14, -56)
  p.empty:SetPoint("RIGHT", -14, 0)
  p.empty:SetJustifyH("LEFT")
  p.empty:SetTextColor(0.62, 0.71, 0.78)
  p.empty:SetText(L.TR_NO_LOADOUTS)

  -- changes
  p.diffTitle = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  p.diffTitle:SetPoint("TOPLEFT", 12, -210)
  p.diffTitle:SetTextColor(0.62, 0.71, 0.78)
  p.rows = {}
  for i = 1, MAX_ROWS do
    local r = W.Box(p, PANEL_W - 24, 18)
    r:SetBackdropColor(0.12, 0.165, 0.21, 1)
    r:SetBackdropBorderColor(0, 0, 0, 0)
    r:SetPoint("TOPLEFT", 12, -226 - (i - 1) * 20)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("LEFT", 6, 0)
    r.change = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.change:SetPoint("RIGHT", -6, 0)
    p.rows[i] = r
  end

  -- Talented warning
  local warn = W.Box(p, PANEL_W - 24, 86)
  warn:SetBackdropColor(0.165, 0.114, 0.063, 1)
  warn:SetBackdropBorderColor(0.94, 0.71, 0.35, 1)
  warn:SetPoint("BOTTOMLEFT", 12, 90)
  warn.text = warn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  warn.text:SetPoint("TOPLEFT", 8, -6)
  warn.text:SetPoint("RIGHT", -8, 0)
  warn.text:SetJustifyH("LEFT")
  warn.text:SetTextColor(1, 0.85, 0.63)
  warn.both = W.Button(warn, L.LO_BOTH, nil, 20)
  warn.both:SetPoint("BOTTOMLEFT", 8, 6)
  warn.both:SetScript("OnClick", function() UT.ApplySelected(true) end)
  p.warn = warn

  p.cost = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  -- full width above the apply button, so the two lines never run into the warning box
  p.cost:SetPoint("BOTTOMLEFT", 12, 50)
  p.cost:SetPoint("RIGHT", -12, 0)
  p.cost:SetJustifyH("LEFT")
  p.cost:SetTextColor(0.62, 0.71, 0.78)

  p.apply = W.Button(p, "", nil, 30)
  p.apply:SetPoint("BOTTOMRIGHT", -12, 12)
  p.apply:SetBackdropColor(0.11, 0.29, 0.16, 1)
  p.apply:SetBackdropBorderColor(0.25, 0.75, 0.35, 1)
  p.apply:SetScript("OnClick", function() UT.ApplySelected(false) end)

  UT.panel = p
end

local function selectedLoadout()
  return UT.selected and LO.Find(UT.selected) or nil
end

function UT.ApplySelected(unlearnBoth)
  if SW.pending then SW.Cancel(); return end -- the button reads "Cancel" while waiting
  local l = selectedLoadout()
  if not l then return end
  ns.UILoadouts.ConfirmApply(l, function()
    SW.Apply(l, { unlearnBoth = unlearnBoth })
    UT.Refresh()
  end)
end

function UT.Refresh()
  local p = UT.panel
  if not p or not p:IsShown() then return end
  local L = ns.L
  local active = LO.Active()
  p.sub:SetText(L.TR_SUB:format(UnitName("player") or "", UnitLevel("player") or 0, active and active.name or L.LO_CUSTOM))

  local list = LO.List()
  if not selectedLoadout() then
    UT.selected = nil
    for _, l in ipairs(list) do if l ~= active then UT.selected = l.name; break end end
  end
  local sel = selectedLoadout()
  p.empty:SetShown(#list == 0)
  for i, b in ipairs(p.buttons) do
    local l = list[i]
    if l then
      b.loadout = l
      b.label:SetText(l.name)
      local tag, r, g, bl = (l.raid and L.LO_RAID_TAG or L.TR_POINTS:format(LO.Total(l.ranks))), 0.62, 0.71, 0.78
      if l == active then tag, r, g, bl = L.TR_ACTIVE, 0.56, 0.89, 0.62
      elseif l == sel then tag, r, g, bl = L.TR_SELECTED, 1, 0.82, 0 end
      b.tag:SetText(tag)
      b.tag:SetTextColor(r, g, bl)
      if l == sel then b:SetBackdropBorderColor(1, 0.82, 0, 1) elseif l == active then b:SetBackdropBorderColor(0.25, 0.75, 0.35, 1)
      else b:SetBackdropBorderColor(W.C.border[1], W.C.border[2], W.C.border[3], 1) end
      b:Show()
    else
      b.loadout = nil
      b:Hide()
    end
  end

  local rows, needsReset, cur = {}, false, nil
  if sel then rows, needsReset, cur = LO.Diff(sel.ranks) end
  p.diffTitle:SetText(sel and L.TR_CHANGES:format(active and active.name or L.LO_CUSTOM, sel.name) or "")
  for i, r in ipairs(p.rows) do
    local d = rows[i]
    if d and i == MAX_ROWS and #rows > MAX_ROWS then
      r.name:SetText(L.TR_MORE:format(#rows - MAX_ROWS + 1)); r.change:SetText(""); r:Show()
    elseif d then
      r.name:SetText(d.name)
      r.change:SetText(("%d > %d"):format(d.from, d.to))
      if d.to < d.from then r.change:SetTextColor(1, 0.61, 0.54) else r.change:SetTextColor(0.56, 0.89, 0.62) end
      r:Show()
    else
      r:Hide()
    end
  end

  local deficit = (sel and needsReset) and LO.ResetDeficit(cur) or 0
  p.warn:SetShown(deficit > 0)
  if deficit > 0 then p.warn.text:SetText(L.TR_TALENTED:format(UnitLevel("player") or 0, deficit)) end

  local costText = ns.cdb.wipeCost and L.TR_LAST_COST:format(GetMoneyString(ns.cdb.wipeCost, true)) or L.TR_COST_UNKNOWN
  p.cost:SetText(costText .. "\n" .. L.TR_COST_NOTE)

  p.apply.label:SetText(sel and L.TR_APPLY:format(sel.name) or L.TR_APPLY_NONE)
  p.apply:SetWidth(p.apply.label:GetStringWidth() + 24)
  p.apply:SetEnabled(SW.pending ~= nil or (sel ~= nil and #rows > 0 and deficit == 0))
  p.apply:SetAlpha(p.apply:IsEnabled() and 1 or 0.5)
  if SW.pending then
    p.apply.label:SetText(L.TR_CANCEL)
    p.apply:SetWidth(p.apply.label:GetStringWidth() + 24)
    p.cost:SetText(L.TR_WAITING .. "\n" .. L.TR_COST_NOTE)
  end
end

function UT.OnGossipShow()
  build()
  if not UT.panel then return end
  local show = SW.AtTrainer() and ns.db.trainerPanel ~= false
  UT.panel:SetShown(show)
  if show then UT.Refresh() end
end

---------------------------------------------------------------------------
-- Raid toast (top of the screen, 12 seconds)
---------------------------------------------------------------------------
function UT.ShowRaidToast()
  if not UT.toast then
    local t = W.Box(UIParent, 520, 40)
    t:SetBackdropColor(0.165, 0.114, 0.063, 0.96)
    t:SetBackdropBorderColor(0.94, 0.71, 0.35, 1)
    t:SetPoint("TOP", UIParent, "TOP", 0, -140)
    t:SetFrameStrata("HIGH")
    t.text = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t.text:SetPoint("LEFT", 14, 0)
    t.text:SetPoint("RIGHT", -14, 0)
    t:EnableMouse(true)
    t:SetScript("OnMouseUp", function(self) self:Hide() end)
    UT.toast = t
  end
  UT.toast.text:SetText(ns.L.RAID_WARN)
  UT.toast:SetWidth(math.min(900, UT.toast.text:GetStringWidth() + 32))
  UT.toast:Show()
  ns.Schedule("lmToast", 12, function() UT.toast:Hide() end)
end
