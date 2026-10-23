local ADDON, ns = ...
local U, D, LG = ns.U, ns.Data, ns.Legacy

local function snapshotSoon(delay)
  ns.Schedule("snapshot", delay or 2, function()
    D.Snapshot()
    ns.UICopilot.Redraw()
  end)
end

local function attachLegacyUI()
  if LegacySystemFrame then
    ns.SafeCall("attach", ns.UILegacy.Attach)
    ns.SafeCall("attachCopilot", ns.UICopilot.Attach)
    ns.SafeCall("attachLoadouts", ns.UILoadouts.Attach)
  end
end

local function announceReady()
  if ns.announced then return end
  ns.announced = true
  for _, r in ipairs(LG.ReadyRewards()) do U.Print(U.Color(U.WARN, ns.L.REWARD_READY_CHAT:format(r))) end
end

local function showErrors()
  local errs = ns.db.errors or {}
  if #errs == 0 then U.Print(ns.L.ERRORS_NONE); return end
  U.Print(ns.L.ERRORS_TITLE .. " (" .. #errs .. ")")
  for i = math.min(#errs, 5), 1, -1 do
    local e = errs[i]
    print(("  %s  [%s]  %s"):format(e.t or "?", e.where or "?", e.msg or "?"))
  end
  ns.db.unseenErrors = false
end

SLASH_LEGACYMANAGER1, SLASH_LEGACYMANAGER2 = "/legacymanager", "/lm"
SlashCmdList.LEGACYMANAGER = function(msg)
  if not ns.active then U.Print(ns.L.NOT_FOREVER); return end
  local cmd = (msg or ""):lower():match("^%s*(%S*)")
  if cmd == "seen" then ns.SafeCall("seen", LG.MarkAllSeen)
  elseif cmd == "status" then
    for _, l in ipairs(ns.Minimap.StatusLines()) do U.Print(l[1]) end
  elseif cmd == "minimap" then ns.Minimap.ToggleShown()
  elseif cmd == "matrix" or cmd == "alts" then ns.SafeCall("matrix", ns.UIMatrix.Toggle)
  elseif cmd == "copilot" then ns.UICopilot.ToggleShown()
  elseif cmd == "names" then ns.UILoadouts.ToggleNames()
  elseif cmd == "group" or cmd == "raid" then ns.SafeCall("group", ns.UIGroup.Toggle)
  elseif cmd == "raidwarn" then
    ns.db.raidWarning = ns.db.raidWarning == false
    U.Print(ns.db.raidWarning and ns.L.RAIDWARN_ON or ns.L.RAIDWARN_OFF)
  elseif cmd == "errors" then showErrors()
  elseif cmd == "clearerrors" then ns.db.errors = {}; ns.db.unseenErrors = false; U.Print(ns.L.ERRORS_CLEARED)
  elseif cmd == "help" or cmd == "?" then U.Print(ns.L.HELP)
  else ns.SafeCall("open", ns.Minimap.OpenLegacy) end
end

local handlers = {}

function handlers.ADDON_LOADED(name)
  if name == ADDON then
    D.InitDB()
    ns.ApplyLocale(ns.db.language)
  elseif name == "Blizzard_LegacySystem" and ns.active then
    attachLegacyUI()
  end
end

function handlers.PLAYER_LOGIN(self)
  ns.active = D.HasLegacy()
  if not ns.active then return end
  ns.Minimap.Create()
  if U.IsAddOnLoaded("Blizzard_LegacySystem") then attachLegacyUI() end
  for _, e in ipairs({ "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "SKILL_LINES_CHANGED",
    "TRAIT_CONFIG_UPDATED", "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
    "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT",
    "GOSSIP_SHOW", "CONFIRM_TALENT_WIPE", "GROUP_ROSTER_UPDATE", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED" }) do
    pcall(self.RegisterEvent, self, e)
  end
  snapshotSoon(3)
  ns.Schedule("announce", 8, function()
    announceReady()
    if ns.db.unseenErrors then U.Print(ns.L.ERRORS_PENDING) end
  end)
end

function handlers.PLAYER_LEVEL_UP() snapshotSoon(1) end
function handlers.PLAYER_XP_UPDATE() snapshotSoon(5) end
handlers.UPDATE_EXHAUSTION = handlers.PLAYER_XP_UPDATE
handlers.SKILL_LINES_CHANGED = handlers.PLAYER_XP_UPDATE

function handlers.TRAIT_CONFIG_UPDATED()
  snapshotSoon(1)
  ns.Schedule("lmRefresh", 0.2, ns.UILegacy.RefreshAll)
  ns.Schedule("lmLoadoutRefresh", 0.3, ns.UILoadouts.Refresh)
  ns.SafeCall("swapConfig", ns.Swap.OnConfigUpdated)
end

function handlers.GOSSIP_SHOW()
  ns.SafeCall("swapGossip", ns.Swap.OnGossipShow)
  ns.SafeCall("trainerPanel", ns.UITrainer.OnGossipShow)
end

function handlers.CONFIRM_TALENT_WIPE(cost, respecType)
  ns.Swap.OnConfirmWipe(cost, respecType)
end

function handlers.GROUP_ROSTER_UPDATE() ns.Schedule("lmRaid", 2, ns.Swap.CheckRaid) end

-- A class talent reset (step one of "unlearn both") may arrive through these events.
function handlers.PLAYER_TALENT_UPDATE() ns.Schedule("lmClassReset", 0.3, ns.Swap.OnConfigUpdated) end
handlers.CHARACTER_POINTS_CHANGED = handlers.PLAYER_TALENT_UPDATE

function handlers.ACHIEVEMENT_EARNED()
  ns.Schedule("lmRefresh", 0.5, ns.UILegacy.RefreshAll)
  ns.UICopilot.DataChanged()
end

-- Criteria progress arrives in bursts (every kill, every quest): collect it.
function handlers.CRITERIA_UPDATE()
  ns.Schedule("lmCriteria", 3, ns.UICopilot.DataChanged)
end

function handlers.MAJOR_FACTION_RENOWN_LEVEL_CHANGED(factionID)
  if factionID == D.REWARD_FACTION then
    ns.announced = false
    ns.Schedule("announce", 2, announceReady)
    ns.Schedule("lmRefresh", 0.5, ns.UILegacy.RefreshAll)
  end
end

-- Loading screens and logout: nothing may be recorded while the client tears down.
function handlers.PLAYER_LEAVING_WORLD() ns.leaving = true end
function handlers.PLAYER_ENTERING_WORLD()
  ns.leaving = false
  snapshotSoon(3)
  ns.Schedule("lmRaid", 5, ns.Swap.CheckRaid)
end
function handlers.PLAYER_LOGOUT()
  ns.Unschedule("snapshot")
end

function handlers.ADDON_ACTION_BLOCKED(addon, fn)
  if addon == ADDON then ns.LogError("blocked", "ADDON_ACTION_BLOCKED: " .. tostring(fn)) end
end
function handlers.ADDON_ACTION_FORBIDDEN(addon, fn)
  if addon == ADDON then ns.LogError("forbidden", "ADDON_ACTION_FORBIDDEN: " .. tostring(fn)) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ADDON_ACTION_BLOCKED")
ev:RegisterEvent("ADDON_ACTION_FORBIDDEN")
ev:SetScript("OnEvent", function(self, event, arg1, arg2)
  local h = handlers[event]
  if not h then return end
  if event == "PLAYER_LOGIN" then ns.SafeCall(event, h, self) else ns.SafeCall(event, h, arg1, arg2) end
end)
