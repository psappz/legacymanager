local ADDON, ns = ...
local U, D, LG, LO = ns.U, ns.Data, ns.Legacy, ns.Loadouts
local SW = {}
ns.Swap = SW

-- Quick swap. Free points are spent anywhere. A loadout that takes points back
-- needs the class trainer: LegacyManager picks the trainer's "unlearn legacy
-- talents" option, the player confirms Blizzard's cost dialog, and as soon as the
-- reset arrives the loadout's points are bought and committed.
--
-- Below level 60 the trainer refuses the Legacy reset while Talented's extra class
-- talent points are spent. Then the class talents are unlearned first ("unlearn
-- both"), and the Legacy reset follows.
--
-- The trainer's options are found by their gossip option IDs, which do not depend
-- on the client language. They are learned at the first reset (and recognised by
-- their English text until then).

local PENDING_TIMEOUT = 90

---------------------------------------------------------------------------
-- Gossip options at the class trainer
---------------------------------------------------------------------------
local recent = {}
if C_GossipInfo and C_GossipInfo.SelectOption then
  -- a C API function (not a frame method), so hooking it is unaffected by the
  -- Forever beta's hooksecurefunc problem with frame methods
  hooksecurefunc(C_GossipInfo, "SelectOption", function(id)
    recent.prev, recent.last, recent.t = recent.last, id, GetTime()
  end)
end

local function lower(s) return (s or ""):lower() end
local function has(t, s) return t:find(s, 1, true) ~= nil end

-- "I wish to unlearn my class or legacy talents."
local function isMenuText(t)
  t = lower(t)
  return has(t, "unlearn") and has(t, "legacy") and has(t, "class")
end

-- "Yes. I would like to unlearn my legacy talents."
local function isLegacyText(t)
  t = lower(t)
  return has(t, "unlearn") and has(t, "legacy") and not has(t, "class")
end

-- "Yes. I would like to unlearn my class talents."
local function isClassText(t)
  t = lower(t)
  return has(t, "unlearn") and has(t, "class") and not has(t, "legacy")
end

-- Returns { menu = id, legacy = id, class = id } for the options on screen.
function SW.TrainerOptions()
  local found = {}
  if not (C_GossipInfo and C_GossipInfo.GetOptions) then return found end
  local learned = ns.db.gossip or {}
  for _, o in ipairs(U.Try(C_GossipInfo.GetOptions) or {}) do
    local id = o.gossipOptionID
    if id then
      -- learned IDs work in every client language; the English texts are the fallback
      if id == learned.legacy or isLegacyText(o.name) then found.legacy = id
      elseif id == learned.class or isClassText(o.name) then found.class = id
      elseif id == learned.menu or isMenuText(o.name) then found.menu = id end
    end
  end
  return found
end

function SW.AtTrainer()
  if not (GossipFrame and GossipFrame:IsShown()) then return false end
  local o = SW.TrainerOptions()
  return (o.menu or o.legacy) ~= nil
end

---------------------------------------------------------------------------
-- Applying a loadout
---------------------------------------------------------------------------
local function report(name, bought, missing)
  if missing > 0 then U.Print(U.Color(U.WARN, ns.L.LO_APPLIED_PARTIAL:format(name, missing)))
  else U.Print(ns.L.LO_APPLIED:format(name)) end
end

-- Moves the pending swap one step forward with the options on screen.
local function advance()
  local p = SW.pending
  if not p then return end
  local o = SW.TrainerOptions()
  if p.stage == "class" then
    if o.class then p.stage = "classConfirm"; U.Try(C_GossipInfo.SelectOption, o.class)
    elseif o.menu then U.Try(C_GossipInfo.SelectOption, o.menu) end
  elseif p.stage == "legacy" then
    if o.legacy then p.stage = "legacyConfirm"; U.Try(C_GossipInfo.SelectOption, o.legacy)
    elseif o.menu then U.Try(C_GossipInfo.SelectOption, o.menu) end
  end
end

-- Returns "done", "nothing", "trainer", "deficit", "busy" or "started".
-- opts.unlearnBoth: unlearn the class talents first when Talented blocks the reset.
function SW.Apply(loadout, opts)
  if type(opts) ~= "table" then opts = {} end
  if InCombatLockdown() then U.Print(ns.L.IN_COMBAT); return "combat" end
  if SW.pending then return "busy" end
  local rows, needsReset, cur = LO.Diff(loadout.ranks)
  if #rows == 0 then U.Print(ns.L.LO_ALREADY:format(loadout.name)); return "nothing" end
  if not needsReset then
    local bought, missing = LO.Spend(loadout.ranks)
    report(loadout.name, bought, missing)
    return "done"
  end
  local deficit = LO.ResetDeficit(cur)
  if deficit > 0 and not opts.unlearnBoth then return "deficit" end
  if not SW.AtTrainer() then U.Print(U.Color(U.WARN, ns.L.LO_NEED_TRAINER)); return "trainer" end

  SW.pending = { loadout = loadout, t = GetTime(), stage = deficit > 0 and "class" or "legacy",
    spentBefore = LG.Points().spent }
  advance()
  if ns.UITrainer then ns.UITrainer.Refresh() end
  return "started"
end

function SW.Cancel()
  SW.pending = nil
  if ns.UITrainer then ns.UITrainer.Refresh() end
end

local function finish()
  local p = SW.pending
  SW.pending = nil
  if not p then return end
  local bought, missing = LO.Spend(p.loadout.ranks)
  report(p.loadout.name, bought, missing)
  if p.unlearnedClass then U.Print(ns.L.LO_RESPEND_CLASS) end
  if ns.UITrainer then ns.UITrainer.Refresh() end
end

function SW.OnGossipShow()
  if SW.pending then advance() end
end

function SW.OnConfirmWipe(cost, respecType)
  ns.cdb.wipeCost = cost
  SW.lastWipe = { cost = cost, type = respecType, menu = recent.prev, option = recent.last, t = GetTime(),
    spentBefore = LG.Points().spent, deficitBefore = LO.ResetDeficit() }
  if ns.UITrainer then ns.UITrainer.Refresh() end
end

local function learn(kind, w)
  local g = ns.db.gossip or {}
  ns.db.gossip = g
  g[kind] = w.option
  -- the option chosen before is the menu entry, unless it was the other reset option
  local m = w.menu
  if m and not g.menu and m ~= g.class and m ~= g.legacy then g.menu = m end
end

-- After every config update: did a reset just happen?
function SW.OnConfigUpdated()
  local p = SW.pending
  if p and GetTime() - p.t > PENDING_TIMEOUT then
    SW.pending = nil
    U.Print(U.Color(U.WARN, ns.L.LO_TIMEOUT))
    if ns.UITrainer then ns.UITrainer.Refresh() end
    return
  end
  local w = SW.lastWipe
  local fresh = w and GetTime() - w.t <= PENDING_TIMEOUT
  local spent = LG.Points().spent

  -- Legacy reset arrived
  if spent == 0 and ((p and p.spentBefore > 0) or (fresh and w.spentBefore > 0)) then
    if fresh and w.spentBefore > 0 then learn("legacy", w); SW.lastWipe = nil end
    if p then ns.Schedule("lmSpend", 0.5, finish) end
    return
  end

  -- class talent reset arrived (Talented no longer blocks): continue with the Legacy reset
  if p and p.stage == "classConfirm" and LO.ResetDeficit() == 0 then
    if fresh then learn("class", w); SW.lastWipe = nil end
    p.stage, p.unlearnedClass, p.t = "legacy", true, GetTime()
    U.Print(ns.L.LO_CLASS_DONE)
    ns.Schedule("lmAdvance", 0.5, function()
      if GossipFrame and GossipFrame:IsShown() then advance() end
    end)
    if ns.UITrainer then ns.UITrainer.Refresh() end
  end
end

---------------------------------------------------------------------------
-- Raid warning: in a raid group, with a raid loadout that is not active
---------------------------------------------------------------------------
function SW.CheckRaid()
  if not IsInRaid() then ns.raidWarned = nil; return end
  if ns.raidWarned or ns.db.raidWarning == false then return end
  local raid = LO.Raid()
  if not raid or LO.Active() == raid then return end
  ns.raidWarned = true
  U.Print(U.Color(U.WARN, ns.L.RAID_WARN))
  if ns.UITrainer then ns.UITrainer.ShowRaidToast() end
end
