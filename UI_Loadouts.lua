local ADDON, ns = ...
local U, W, LO, SW = ns.U, ns.W, ns.Loadouts, ns.Swap
local UL = {}
ns.UILoadouts = UL

local owner = {}

---------------------------------------------------------------------------
-- Dialogs: loadout name, Talented warning
---------------------------------------------------------------------------
local function acceptName(text, renameFrom)
  local name = strtrim(text or "")
  if name == "" then return end
  if renameFrom then
    if not LO.Rename(renameFrom, name) then U.Print(ns.L.LO_NAME_TAKEN:format(name)) end
  else
    LO.SaveCurrent(name)
    U.Print(ns.L.LO_SAVED:format(name))
  end
  UL.Refresh()
end

-- Shows every change of the loadout and asks before anything is spent.
function UL.ConfirmApply(loadout, run)
  local L = ns.L
  local rows, needsReset = LO.Diff(loadout.ranks)
  if #rows == 0 then U.Print(L.LO_ALREADY:format(loadout.name)); return end
  local lines = {}
  for i, d in ipairs(rows) do
    if i > 8 then lines[#lines + 1] = L.TR_MORE:format(#rows - 8); break end
    local hex = d.to < d.from and "ffff9b8a" or "ff8fe39f"
    lines[#lines + 1] = d.name .. "  " .. U.Color(hex, d.from .. " > " .. d.to)
  end
  local text = L.CONFIRM_HEAD:format(loadout.name) .. "\n\n" .. table.concat(lines, "\n") .. "\n\n"
    .. (needsReset and L.CONFIRM_RESET or L.CONFIRM_FINAL)
  if ns.cdb.wipeCost then text = text .. "\n" .. L.CONFIRM_LASTCOST:format(GetMoneyString(ns.cdb.wipeCost, true)) end
  W.Dialog({ text = text, accept = ACCEPT or "OK", onAccept = function() ns.SafeCall("confirmApply", run) end })
end

local function showCode(l)
  W.Dialog({ text = ns.L.LO_CODE_COPY:format(l.name), edit = true, editText = LO.Export(l) })
end

local function askCode()
  W.Dialog({ text = ns.L.LO_CODE_PASTE, edit = true, onAccept = function(code)
    ns.SafeCall("importCode", function()
      local l, err = LO.Import(code)
      if l then U.Print(ns.L.LO_IMPORTED:format(l.name)); UL.Refresh() else U.Print(ns.L[err] or err) end
    end)
  end })
end

local function askName(renameFrom)
  W.Dialog({ text = renameFrom and ns.L.LO_RENAME_PROMPT or ns.L.LO_NAME_PROMPT, edit = true, editText = renameFrom or "",
    maxLetters = 32, onAccept = function(name) ns.SafeCall("loadoutName", acceptName, name, renameFrom) end })
end

-- Applies a loadout; on a Talented deficit the player chooses first.
function UL.Apply(loadout)
  UL.ConfirmApply(loadout, function()
    local result = SW.Apply(loadout)
    if result == "deficit" then
      W.Dialog({ text = ns.L.LO_TALENTED_WARN:format(UnitLevel("player") or 0), accept = ns.L.LO_BOTH,
        onAccept = function() ns.SafeCall("applyBoth", SW.Apply, loadout, { unlearnBoth = true }) end })
    end
  end)
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
  root:CreateButton(L.LO_IMPORT, function() askCode() end)
  if #list > 0 then
    local over = root:CreateButton(L.LO_OVERWRITE)
    for _, l in ipairs(list) do
      over:CreateButton(l.name, function() LO.SaveCurrent(l.name); U.Print(L.LO_SAVED:format(l.name)); UL.Refresh() end)
    end
    local manage = root:CreateButton(L.LO_MANAGE)
    for _, l in ipairs(list) do
      local sub = manage:CreateButton(l.name)
      sub:CreateButton(L.LO_SHARE, function() showCode(l) end)
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
    W.OpenMenu(self, menu)
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

-- Number in a condition's tooltip ("Spend 3 more points ..."): the points still missing
local function tooltipNumber(c)
  if c.playerLevel or c.questID or c.achievementID then return nil end
  local text = c.tooltipText or c.tooltipFormat
  local n = text and tonumber(text:gsub("|c%x%x%x%x%x%x%x%x", ""):match("(%d+)"))
  if n and n > 0 and n <= 100 then return n end
end

-- Requirement of a node in points spent in its tree. The client reports what is still
-- MISSING (tooltip, and spentAmountRequired while points are staged), and nothing once
-- the condition is met. Each sighting gives a total = missing + spent; staged points the
-- API leaves out only make that total smaller, so the largest total seen is kept and shown.
local function gateOf(cfg, nodeID, gates, spent)
  local info = U.Try(C_Traits.GetNodeInfo, cfg, nodeID)
  if not info then return end
  ns.db.gateNeed = ns.db.gateNeed or {}
  local need, met
  for _, condID in ipairs(info.conditionIDs or {}) do
    local c = U.Try(C_Traits.GetConditionInfo, cfg, condID, true)
    if c then
      local tip, sar = tooltipNumber(c), c.spentAmountRequired or 0
      if not c.isMet and (tip or sar > 0) then
        local total
        if tip and (sar == 0 or sar == tip) then total = tip + (spent or 0) -- both name the missing points
        elseif sar > 0 then total = sar end                                 -- a real total
        if total and total > (ns.db.gateNeed[condID] or 0) then ns.db.gateNeed[condID] = total end
      end
      local n = ns.db.gateNeed[condID]
      if n and n > (need or 0) then need, met = n, c.isMet end
    end
  end
  if need then return need, met end
  local best
  for _, g in ipairs(gates) do
    if info.posX >= g.x and (not best or g.need > best.need) then best = g end
  end
  if best then return best.need, best.met end
end

local function decorateButton(button, cfg, gates, spent)
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
    local holder = CreateFrame("Frame", nil, button)
    holder:SetSize(30, 14)
    holder:SetPoint("BOTTOMLEFT", button, "TOPLEFT", -2, 1)
    holder:SetFrameLevel(button:GetFrameLevel() + 20)
    local g = holder:CreateFontString(nil, "OVERLAY")
    g:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    g:SetPoint("BOTTOMLEFT")
    button.lmGate = g
  end
  local show = ns.db.showPerkNames ~= false
  local name = LO.NodeName(nodeID)
  button.lmName:SetText((show and name:sub(1, 1) ~= "#") and name or "")
  local need, met = gateOf(cfg, nodeID, gates, spent)
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
  local treeID = panel.GetTalentTreeID and panel:GetTalentTreeID()
  local gates = treeGates(cfg, treeID)
  local cur = treeID and U.Try(C_Traits.GetTreeCurrencyInfo, cfg, treeID, false)
  local spent = cur and cur[1] and cur[1].spentInTree or 0
  for button in panel:EnumerateAllTalentButtons() do
    local ok, err = pcall(decorateButton, button, cfg, gates, spent)
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
