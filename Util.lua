local ADDON, ns = ...
local U = {}
ns.U = U

U.BLUE = "ff4fa3ff"
U.GOLD = "ffffd100"
U.WARN = "fff0b45a"
U.OK = "ff8fe39f"
U.MUTED = "ff9fb4c8"

function U.Color(hex, text) return "|c" .. hex .. tostring(text) .. "|r" end

function U.Print(msg)
  print(U.Color(U.BLUE, "LegacyManager") .. ": " .. tostring(msg))
end

function U.Timestamp() return date("%Y-%m-%d %H:%M:%S") end

-- Calls fn safely and returns its first result (nil on error or when fn is missing).
function U.Try(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
  return nil
end

-- Like U.Try, but returns all results (nothing on error).
local function dropStatus(ok, ...)
  if ok then return ... end
end
function U.TryAll(fn, ...)
  if type(fn) ~= "function" then return end
  return dropStatus(pcall(fn, ...))
end

function U.CharKey()
  local name = UnitName("player") or "?"
  local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName() or "?"
  return name .. "-" .. realm
end

function U.IsAddOnLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) end
  return IsAddOnLoaded and IsAddOnLoaded(name)
end

---------------------------------------------------------------------------
-- Error log: errors in event handlers are kept in the saved variables, so an
-- error during logout can still be read after the next login (/lm errors).
---------------------------------------------------------------------------
local function logError(where, err)
  local stack = debugstack and debugstack(3, 12, 0) or ""
  local db = ns.db
  if db then
    db.errors = db.errors or {}
    table.insert(db.errors, 1, { t = U.Timestamp(), where = where, msg = tostring(err), stack = stack })
    while #db.errors > 20 do table.remove(db.errors) end
    db.unseenErrors = true
  end
  if not ns.leaving then U.Print(U.Color(U.WARN, tostring(err)) .. "  (/lm errors)") end
end
ns.LogError = logError

function ns.SafeCall(where, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then logError(where, err) end
  return ok, err
end

---------------------------------------------------------------------------
-- Scheduler without timer objects (WoW Forever limits an addon to 500 timers).
-- A job with the same name replaces the pending one, which also debounces.
---------------------------------------------------------------------------
local due, ticker = {}, CreateFrame("Frame")
ticker:Hide()
ticker:SetScript("OnUpdate", function(self)
  local now = GetTime()
  for name, job in pairs(due) do
    if now >= job.at then
      due[name] = nil
      ns.SafeCall(name, job.fn)
    end
  end
  if not next(due) then self:Hide() end
end)

function ns.Schedule(name, delay, fn)
  due[name] = { at = GetTime() + delay, fn = fn }
  ticker:Show()
end

function ns.Unschedule(name) due[name] = nil end
