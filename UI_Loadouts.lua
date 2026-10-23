local ADDON, ns = ...
local U, W, LO, SW = ns.U, ns.W, ns.Loadouts, ns.Swap
local UL = {}
ns.UILoadouts = UL

local owner = {}

---------------------------------------------------------------------------
-- Dialogs: loadout name, Talented warning
---------------------------------------------------------------------------
local function editBoxOf(dialog)
  return dialog.editBox or dialog.EditBox or (dialog.GetEditBox and dialog:GetEditBox())
end

local function acceptName(dialog, data)
  local box = editBoxOf(dialog)
  local name = box and strtrim(box:GetText() or "") or ""
  if name == "" then return end
  if data and data.rename then
    if not LO.Rename(data.rename, name) then U.Print(ns.L.LO_NAME_TAKEN:format(name)) end
  else
    LO.SaveCurrent(name)
    U.Print(ns.L.LO_SAVED:format(name))
  end
  UL.Refresh()
end

StaticPopupDialogs["LEGACYMANAGER_NAME"] = {
  text = "%s",
  button1 = OKAY,
  button2 = CANCEL,
  hasEditBox = 1,
  maxLetters = 32,
  OnShow = function(self, data)
    local box = editBoxOf(self)
    if box then box:SetText(data and data.rename or ""); box:SetFocus() end
  end,
  OnAccept = function(self, data) ns.SafeCall("loadoutName", acceptName, self, data) end,
  EditBoxOnEnterPressed = function(self)
    local dialog = self:GetParent()
    ns.SafeCall("loadoutName", acceptName, dialog, dialog.data)
    dialog:Hide()
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  timeout = 0, whileDead = 1, hideOnEscape = 1,
}

StaticPopupDialogs["LEGACYMANAGER_TALENTED"] = {
  text = "%s",
  button1 = "", -- set in Ask, localized
  button2 = CANCEL,
  OnAccept = function(_, data) ns.SafeCall("applyBoth", SW.Apply, data.loadout, { unlearnBoth = true }) end,
  timeout = 0, whileDead = 1, hideOnEscape = 1,
}

local function askName(renameFrom)
  StaticPopup_Show("LEGACYMANAGER_NAME", renameFrom and ns.L.LO_RENAME_PROMPT or ns.L.LO_NAME_PROMPT, nil,
    { rename = renameFrom })
end

-- Applies a loadout; on a Talented deficit the player chooses first.
function UL.Apply(loadout)
  local result = SW.Apply(loadout)
  if result == "deficit" then
    StaticPopupDialogs["LEGACYMANAGER_TALENTED"].button1 = ns.L.LO_BOTH
    StaticPopup_Show("LEGACYMANAGER_TALENTED", ns.L.LO_TALENTED_WARN:format(UnitLevel("player") or 0), nil,
      { loadout = loadout })
  end
  return result
end

---------------------------------------------------------------------------
-- Loadout dropdown in the free space of the tree page's left column
---------------------------------------------------------------------------
local function menu(_, root)
  local L = ns.L
  local active = LO.Active()
  root:CreateTitle(L.LO_TITLE)
  local list = LO.List()
  if #list == 0 then root:CreateTitle(L.LO_NONE) end
  for _, l in ipairs(list) do
    local label = l.name .. (l.raid and ("  " .. U.Color(U.WARN, L.LO_RAID_TAG)) or "")
    root:CreateRadio(label, function() return active == l end, function() ns.SafeCall("apply", UL.Apply, l) end)
  end
  root:CreateDivider()
  root:CreateButton(L.LO_SAVE_NEW, function() askName(nil) end)
  if #list > 0 then
    local over = root:CreateButton(L.LO_OVERWRITE)
    for _, l in ipairs(list) do
      over:CreateButton(l.name, function() LO.SaveCurrent(l.name); U.Print(L.LO_SAVED:format(l.name)); UL.Refresh() end)
    end
    local manage = root:CreateButton(L.LO_MANAGE)
    for _, l in ipairs(list) do
      local sub = manage:CreateButton(l.name)
      sub:CreateButton(L.LO_RENAME, function() askName(l.name) end)
      sub:CreateButton(l.raid and L.LO_UNMARK_RAID or L.LO_MARK_RAID, function()
        LO.SetRaid(not l.raid and l.name or nil); UL.Refresh()
      end)
      sub:CreateButton(U.Color(U.WARN, L.LO_DELETE), function() LO.Delete(l.name); UL.Refresh() end)
    end
  end
end

local function buildDropdown(page)
  if UL.dropdown then return end
  local box = W.Box(page, 118, 46)
  box:SetFrameLevel((page.LegacyTreeSelectionPanel and page.LegacyTreeSelectionPanel:GetFrameLevel() or 800) + 5)
  box:SetPoint("TOPLEFT", page, "TOPLEFT", 8, -96)
  box:EnableMouse(true)
  local caption = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  caption:SetPoint("TOPLEFT", 8, -6)
  caption:SetText(ns.L.LO_TITLE)
  caption:SetTextColor(0.62, 0.71, 0.78)
  local name = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("TOPLEFT", caption, "BOTTOMLEFT", 0, -3)
  name:SetPoint("RIGHT", -18, 0)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  local arrow = box:CreateTexture(nil, "OVERLAY")
  arrow:SetSize(12, 12)
  arrow:SetAtlas("common-dropdown-icon-next")
  arrow:SetRotation(-math.pi / 2)
  arrow:SetPoint("RIGHT", -6, -6)
  box.name = name
  box:SetScript("OnMouseUp", function(self)
    if MenuUtil and MenuUtil.CreateContextMenu then MenuUtil.CreateContextMenu(self, menu) end
  end)
  box:SetScript("OnEnter", function(self) self:SetBackdropColor(W.C.bgHover[1], W.C.bgHover[2], W.C.bgHover[3], W.C.bgHover[4]) end)
  box:SetScript("OnLeave", function(self) self:SetBackdropColor(W.C.bg[1], W.C.bg[2], W.C.bg[3], W.C.bg[4]) end)
  UL.dropdown = box
end

---------------------------------------------------------------------------
-- Perk names below the nodes and gate badges ("10+") on gated nodes
---------------------------------------------------------------------------
-- Gates of the shown tree: { { x = posX of the gate column, need, met } ... }
local function treeGates(cfg, treeID)
  local out = {}
  local tree = treeID and U.Try(C_Traits.GetTreeInfo, cfg, treeID)
  for _, g in ipairs(tree and tree.gates or {}) do
    local node = U.Try(C_Traits.GetNodeInfo, cfg, g.topLeftNodeID)
    local c = U.Try(C_Traits.GetConditionInfo, cfg, g.conditionID)
    if node and c and (c.spentAmountRequired or 0) > 0 then
      out[#out + 1] = { x = node.posX, need = c.spentAmountRequired, met = c.isMet }
    end
  end
  return out
end

local function gateOf(cfg, nodeID, gates)
  local info = U.Try(C_Traits.GetNodeInfo, cfg, nodeID)
  if not info then return end
  local best
  for _, g in ipairs(gates) do
    if info.posX >= g.x and (not best or g.need > best.need) then best = g end
  end
  if best then return best.need, best.met end
end

local function decorateButton(button, cfg, gates)
  local nodeID = button.GetNodeID and button:GetNodeID()
  if not nodeID then return end
  if not button.lmName then
    local fs = button:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    fs:SetPoint("TOP", button, "BOTTOM", 0, -1)
    fs:SetWidth(94)
    fs:SetWordWrap(false)
    fs:SetTextColor(0.93, 0.89, 0.81)
    button.lmName = fs
    local g = button:CreateFontString(nil, "OVERLAY")
    g:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    g:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
    button.lmGate = g
  end
  local show = ns.db.showPerkNames ~= false
  local name = LO.NodeName(nodeID)
  button.lmName:SetText((show and name:sub(1, 1) ~= "#") and name or "")
  local need, met = gateOf(cfg, nodeID, gates)
  if need and show then
    button.lmGate:SetText(need .. "+")
    if met then button.lmGate:SetTextColor(0.56, 0.89, 0.62) else button.lmGate:SetTextColor(0.94, 0.71, 0.35) end
  else
    button.lmGate:SetText("")
  end
end

function UL.DecorateNodes()
  local panel = LegacySystemFrame and LegacySystemFrame.TreePage and LegacySystemFrame.TreePage.LegacyTreeTraitPanel
  if not panel or not panel:IsVisible() or not panel.EnumerateAllTalentButtons then return end
  local cfg = panel.GetConfigID and panel:GetConfigID()
  if not cfg then return end
  local gates = treeGates(cfg, panel.GetTalentTreeID and panel:GetTalentTreeID())
  for button in panel:EnumerateAllTalentButtons() do
    local ok, err = pcall(decorateButton, button, cfg, gates)
    if not ok then ns.LogError("decorateNode", err); return end
  end
end

---------------------------------------------------------------------------
function UL.Refresh()
  if UL.dropdown and UL.dropdown:IsVisible() then
    local active = LO.Active()
    UL.dropdown.name:SetText(active and active.name or ns.L.LO_CUSTOM)
  end
  UL.DecorateNodes()
  if ns.UITrainer then ns.UITrainer.Refresh() end
end

function UL.Attach()
  if UL.attached or not (LegacySystemFrame and LegacySystemFrame.TreePage) then return end
  UL.attached = true
  local page = LegacySystemFrame.TreePage
  buildDropdown(page)
  page:HookScript("OnShow", function() ns.Schedule("lmLoadouts", 0.05, UL.Refresh) end)
  if EventRegistry then
    EventRegistry:RegisterCallback("TalentFrameBase.ButtonsUpdated", function() ns.Schedule("lmNodes", 0.05, UL.DecorateNodes) end, owner)
    EventRegistry:RegisterCallback("Legacy.SelectTree", function() ns.Schedule("lmNodes", 0.1, UL.DecorateNodes) end, owner)
  end
  UL.Refresh()
end

function UL.ToggleNames()
  ns.db.showPerkNames = ns.db.showPerkNames == false
  U.Print(ns.db.showPerkNames and ns.L.NAMES_SHOWN or ns.L.NAMES_HIDDEN)
  UL.DecorateNodes()
end
