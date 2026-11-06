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

-- Small close button ("x") in the top-right corner
function W.Close(parent, onClick)
  local b = W.Button(parent, "x", nil, 20)
  b:SetWidth(20)
  b:SetPoint("TOPRIGHT", -6, -6)
  b:SetScript("OnClick", onClick or function() parent:Hide() end)
  return b
end

-- Re-sizes a button after its label changed (translated texts differ in length)
function W.SetLabel(b, text)
  b.label:SetText(text or "")
  b:SetWidth(b.label:GetStringWidth() + 20)
end

---------------------------------------------------------------------------
-- Own dialog instead of Blizzard's StaticPopup:
-- W.Dialog{ text, edit = true|false, editText, accept = "OK", cancel = "Cancel", onAccept = function(text) end }
---------------------------------------------------------------------------
local dialog
local function buildDialog()
  local d = W.Box(UIParent, 420, 140)
  d:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  d:SetFrameStrata("DIALOG")
  d:SetToplevel(true)
  d:EnableMouse(true)
  d:SetMovable(true)
  d:RegisterForDrag("LeftButton")
  d:SetScript("OnDragStart", d.StartMoving)
  d:SetScript("OnDragStop", d.StopMovingOrSizing)
  d:SetBackdropColor(0.094, 0.125, 0.165, 0.98)
  d:Hide()
  tinsert(UISpecialFrames, "LegacyManagerDialog")
  _G.LegacyManagerDialog = d

  d.text = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  d.text:SetPoint("TOPLEFT", 16, -16)
  d.text:SetPoint("TOPRIGHT", -16, -16)
  d.text:SetJustifyH("LEFT")
  d.text:SetSpacing(2)
  d.text:SetTextColor(W.C.text[1], W.C.text[2], W.C.text[3])

  local e = CreateFrame("EditBox", nil, d, "BackdropTemplate")
  e:SetBackdrop(BACKDROP)
  e:SetBackdropColor(0.04, 0.06, 0.09, 1)
  e:SetBackdropBorderColor(W.C.border[1], W.C.border[2], W.C.border[3], 1)
  e:SetFontObject(GameFontHighlightSmall)
  e:SetTextInsets(6, 6, 0, 0)
  e:SetHeight(22)
  e:SetAutoFocus(false)
  e:SetScript("OnEscapePressed", function() d:Hide() end)
  e:SetScript("OnEnterPressed", function() d.ok:Click() end)
  d.edit = e

  d.ok = W.Button(d, OKAY or "OK", nil, 24)
  d.cancel = W.Button(d, CANCEL or "Cancel", nil, 24)
  d.cancel:SetScript("OnClick", function() d:Hide() end)
  d.ok:SetScript("OnClick", function()
    local fn, txt = d.onAccept, d.edit:IsShown() and d.edit:GetText() or nil
    d:Hide()
    if fn then fn(txt) end
  end)
  return d
end

function W.Dialog(opts)
  dialog = dialog or buildDialog()
  local d = dialog
  d.onAccept = opts.onAccept
  d.text:SetText(opts.text or "")
  W.SetLabel(d.ok, opts.accept or OKAY or "OK")
  W.SetLabel(d.cancel, opts.cancel or CANCEL or "Cancel")
  local h = 16 + d.text:GetStringHeight() + 14
  if opts.edit then
    d.edit:ClearAllPoints()
    d.edit:SetPoint("TOPLEFT", d.text, "BOTTOMLEFT", 0, -12)
    d.edit:SetPoint("RIGHT", -16, 0)
    d.edit:SetText(opts.editText or "")
    d.edit:SetMaxLetters(opts.maxLetters or 0)
    d.edit:Show()
    h = h + 34
  else
    d.edit:Hide()
  end
  d.ok:ClearAllPoints()
  d.cancel:ClearAllPoints()
  d.cancel:SetPoint("BOTTOMRIGHT", -16, 14)
  d.ok:SetPoint("RIGHT", d.cancel, "LEFT", -8, 0)
  d:SetHeight(h + 24 + 28)
  d:Show()
  if opts.edit then d.edit:SetFocus(); d.edit:HighlightText() end
end

---------------------------------------------------------------------------
-- Own context menu instead of Blizzard's MenuUtil. Same builder calls as MenuUtil:
-- W.OpenMenu(owner, function(owner, root) root:CreateTitle(..) root:CreateRadio(..) root:CreateButton(..) end)
-- A button with entries of its own opens a submenu on the right.
---------------------------------------------------------------------------
local Node = {}
Node.__index = Node
local function newNode(kind, text, fn, isSel) return setmetatable({ kind = kind, text = text, fn = fn, isSel = isSel, items = {} }, Node) end
function Node:CreateTitle(t) table.insert(self.items, newNode("title", t)) end
function Node:CreateDivider() table.insert(self.items, newNode("div")) end
function Node:CreateRadio(t, isSel, fn) local n = newNode("radio", t, fn, isSel); table.insert(self.items, n); return n end
function Node:CreateButton(t, fn) local n = newNode("button", t, fn); table.insert(self.items, n); return n end

local levels, catcher = {}, nil
local ROW_H = 20
local function hideFrom(depth)
  for d = depth, #levels do levels[d]:Hide() end
  if depth <= 1 and catcher then catcher:Hide() end
end

local showLevel
local function getLevel(depth)
  local f = levels[depth]
  if f then return f end
  f = W.Box(UIParent, 160, 40)
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetFrameLevel(10 + depth * 5)
  f:SetBackdropColor(0.094, 0.125, 0.165, 0.98)
  f:EnableMouse(true)
  f.rows = {}
  f:Hide()
  levels[depth] = f
  return f
end

local function getRow(f, i, depth)
  local r = f.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, f)
  r:SetHeight(ROW_H)
  r.hl = r:CreateTexture(nil, "HIGHLIGHT")
  r.hl:SetColorTexture(W.C.border[1], W.C.border[2], W.C.border[3], 0.25)
  r.hl:SetAllPoints()
  r.mark = r:CreateTexture(nil, "OVERLAY")
  r.mark:SetSize(8, 8)
  r.mark:SetPoint("LEFT", 8, 0)
  r.mark:SetColorTexture(W.C.gold[1], W.C.gold[2], W.C.gold[3], 1)
  r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.text:SetPoint("LEFT", 22, 0)
  r.text:SetJustifyH("LEFT")
  r.arrow = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.arrow:SetPoint("RIGHT", -8, 0)
  r.arrow:SetText(">")
  r.line = r:CreateTexture(nil, "ARTWORK")
  r.line:SetColorTexture(W.C.border[1], W.C.border[2], W.C.border[3], 0.5)
  r.line:SetHeight(1)
  r.line:SetPoint("LEFT", 6, 0)
  r.line:SetPoint("RIGHT", -6, 0)
  r:SetScript("OnEnter", function(self)
    local n = self.node
    if n and #n.items > 0 then showLevel(n, depth + 1, self) else hideFrom(depth + 1) end
  end)
  r:SetScript("OnClick", function(self)
    local n = self.node
    if not n or n.kind == "title" or n.kind == "div" then return end
    if #n.items > 0 then showLevel(n, depth + 1, self) return end
    hideFrom(1)
    if n.fn then n.fn() end
  end)
  f.rows[i] = r
  return r
end

showLevel = function(node, depth, anchor)
  hideFrom(depth)
  local f = getLevel(depth)
  local width, y = 120, -6
  for i, n in ipairs(node.items) do
    local r = getRow(f, i, depth)
    r.node = n
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 1, y)
    r:SetPoint("RIGHT", -1, 0)
    local isDiv = n.kind == "div"
    r:SetHeight(isDiv and 8 or ROW_H)
    r.line:SetShown(isDiv)
    r.text:SetShown(not isDiv)
    r.text:SetText(n.text or "")
    r.text:SetTextColor(n.kind == "title" and W.C.gold[1] or W.C.text[1], n.kind == "title" and W.C.gold[2] or W.C.text[2], n.kind == "title" and W.C.gold[3] or W.C.text[3])
    r.mark:SetShown(n.kind == "radio" and n.isSel and n.isSel() or false)
    r.arrow:SetShown(#n.items > 0)
    r.hl:SetShown(n.kind ~= "title" and not isDiv)
    r:EnableMouse(n.kind ~= "title" and not isDiv)
    r:Show()
    width = math.max(width, (r.text:GetStringWidth() or 0) + 22 + 28)
    y = y - (isDiv and 8 or ROW_H)
  end
  for i = #node.items + 1, #f.rows do f.rows[i]:Hide() end
  f:SetSize(width, -y + 6)
  f:ClearAllPoints()
  if depth == 1 then f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  else f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, 6) end
  f:SetClampedToScreen(true)
  f:Show()
end

function W.OpenMenu(owner, build)
  if not catcher then
    catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1)
    catcher:RegisterForClicks("AnyUp")
    catcher:SetScript("OnClick", function() hideFrom(1) end)
  end
  if levels[1] and levels[1]:IsShown() and levels[1].owner == owner then hideFrom(1) return end
  local root = newNode("root")
  build(owner, root)
  catcher:Show()
  showLevel(root, 1, owner)
  levels[1].owner = owner
end
