local ADDON, ns = ...
local U, D, LG = ns.U, ns.Data, ns.Legacy

local function snapshotSoon(delay) ns.Schedule("snapshot", delay or 2, D.Snapshot) end

local function attachLegacyUI()
  if LegacySystemFrame then ns.SafeCall("attach", ns.UILegacy.Attach) end
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
    "TRAIT_CONFIG_UPDATED", "ACHIEVEMENT_EARNED", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
    "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT" }) do
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
end

function handlers.ACHIEVEMENT_EARNED()
  ns.Schedule("lmRefresh", 0.5, ns.UILegacy.RefreshAll)
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
function handlers.PLAYER_ENTERING_WORLD() ns.leaving = false; snapshotSoon(3) end
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
