local ADDON, ns = ...
local U, LG, D = ns.U, ns.Legacy, ns.Data
local MM = {}
ns.Minimap = MM

local ICON = "Interface\\Icons\\achievement_guildperk_everybodysfriend"

function MM.OpenLegacy()
  if InCombatLockdown() then U.Print(ns.L.IN_COMBAT); return end
  if ToggleLegacySystemUI then ToggleLegacySystemUI() end
end

-- Lines for tooltips and /lm status
function MM.StatusLines()
  local lines = {}
  local p = LG.Points()
  if p.earned <= 0 then
    lines[#lines + 1] = { ns.L.STATUS_NO_LEGACY, 0.62, 0.71, 0.78 }
  else
    lines[#lines + 1] = { ns.L.STATUS_POINTS:format(p.earned, p.spent, p.cap), 1, 1, 1 }
    if p.free > 0 then lines[#lines + 1] = { ns.L.STATUS_FREE:format(p.free), 0.56, 0.89, 0.62 } end
    local e, missing = LG.NextReward()
    if e then
      local names = table.concat(e.names, ", ")
      lines[#lines + 1] = { missing == 1 and ns.L.REWARD_NEXT_ONE:format(names) or ns.L.REWARD_NEXT:format(missing, names), 1, 0.82, 0 }
    end
    for _, r in ipairs(LG.ReadyRewards()) do
      lines[#lines + 1] = { ns.L.REWARD_READY:format(r), 0.94, 0.71, 0.35 }
    end
  end
  if D.IsHardcore() then lines[#lines + 1] = { ns.L.STATUS_HARDCORE, 0.94, 0.71, 0.35 } end
  return lines
end

local function fillTooltip(tt)
  tt:AddLine("LegacyManager", 0.31, 0.64, 1)
  for _, l in ipairs(MM.StatusLines()) do tt:AddLine(l[1], l[2], l[3], l[4], true) end
  tt:AddLine(" ")
  tt:AddLine(ns.L.MINIMAP_TIP, 0.62, 0.71, 0.78, true)
end

function MM.Create()
  if MM.created then return end
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local DBI = LibStub and LibStub("LibDBIcon-1.0", true)
  if not (LDB and DBI) then return end
  MM.created = true
  local obj = LDB:NewDataObject("LegacyManager", {
    type = "launcher", label = "LegacyManager", icon = ICON,
    OnClick = function() ns.SafeCall("minimapClick", MM.OpenLegacy) end,
    OnTooltipShow = function(tt) ns.SafeCall("minimapTip", fillTooltip, tt) end,
  })
  local m = ns.db.minimap
  m.minimapPos = m.minimapPos or 200
  DBI:Register("LegacyManager", obj, m)
  MM.icon = DBI
end

function MM.ToggleShown()
  if not MM.icon then return end
  local m = ns.db.minimap
  m.hide = not m.hide
  if m.hide then MM.icon:Hide("LegacyManager"); U.Print(ns.L.MINIMAP_HIDDEN)
  else MM.icon:Show("LegacyManager"); U.Print(ns.L.MINIMAP_SHOWN) end
end

-- Blizzard addon compartment (stays reachable when minimap buttons are collected)
function LegacyManager_OnAddonCompartmentClick() ns.SafeCall("compartment", MM.OpenLegacy) end
function LegacyManager_OnAddonCompartmentEnter(_, frame)
  GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
  ns.SafeCall("compartmentTip", fillTooltip, GameTooltip)
  GameTooltip:Show()
end
function LegacyManager_OnAddonCompartmentLeave() GameTooltip:Hide() end
