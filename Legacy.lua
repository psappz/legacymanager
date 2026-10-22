local ADDON, ns = ...
local U, D = ns.U, ns.Data
local LG = {}
ns.Legacy = LG

---------------------------------------------------------------------------
-- Points: earned (account, = renown level of the reward track), spending cap,
-- spent and free on this character.
---------------------------------------------------------------------------
function LG.Earned()
  return U.Try(C_MajorFactions.GetCurrentRenownLevel, D.REWARD_FACTION) or 0
end

function LG.Points()
  local p = { earned = LG.Earned(), spent = 0, free = 0, cap = nil, perTree = {} }
  for _, treeID in ipairs(D.TREES) do
    local cfg = D.ConfigFor(treeID)
    local info = cfg and U.Try(C_Traits.GetTreeCurrencyInfo, cfg, treeID, false)
    info = info and info[1]
    if info then
      p.perTree[treeID] = info.spentInTree or 0
      p.spent = p.spent + (info.spentInTree or 0)
      p.free = info.quantity or p.free
      p.cap = p.cap or info.maxQuantity
    end
  end
  -- Older builds may not report a cap: the spendable amount is then spent + free.
  p.cap = p.cap or (p.spent + p.free)
  p.over = math.max(0, p.earned - p.cap)
  p.toCap = math.max(0, p.cap - p.earned)
  return p
end

---------------------------------------------------------------------------
-- Reward track
---------------------------------------------------------------------------
local function petCollected(itemID)
  if not (C_PetJournal and C_PetJournal.GetPetInfoByItemID) then return nil end
  local speciesID = select(13, U.TryAll(C_PetJournal.GetPetInfoByItemID, itemID))
  if not speciesID then return nil end
  local owned = U.Try(C_PetJournal.GetNumCollectedInfo, speciesID)
  if owned == nil then return nil end
  return owned > 0
end

-- true = collected, false = not collected, nil = unknown
local function isCollected(r)
  if r.isCollected ~= nil then return r.isCollected end
  if r.mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
    -- GetMountInfoByID returns collected as 11th value
    local collected = select(11, U.TryAll(C_MountJournal.GetMountInfoByID, r.mountID))
    if collected ~= nil then return collected and true or false end
  end
  if r.itemID then
    if PlayerHasToy and U.Try(PlayerHasToy, r.itemID) then return true end
    local pet = petCollected(r.itemID)
    if pet then return true end
    local count = U.Try(C_Item and C_Item.GetItemCount or GetItemCount, r.itemID, true)
    if count and count > 0 then return true end
    if count ~= nil then return false end
  end
  return nil
end

local function rewardName(r)
  if r.name and r.name ~= "" then return r.name end
  if r.itemID then
    local n = U.Try(C_Item and C_Item.GetItemNameByID or GetItemInfo, r.itemID)
    if n then return n end
  end
  return "?"
end

-- { { level, names = {..}, reached, ready } ... } sorted by level
function LG.Rewards()
  local out = {}
  local earned = LG.Earned()
  for _, lv in ipairs(U.Try(C_MajorFactions.GetRenownLevels, D.REWARD_FACTION) or {}) do
    local entry = { level = lv.level, names = {}, reached = earned >= lv.level, ready = false }
    for _, r in ipairs(U.Try(C_MajorFactions.GetRenownRewardsForLevel, D.REWARD_FACTION, lv.level) or {}) do
      entry.names[#entry.names + 1] = rewardName(r)
      if entry.reached and isCollected(r) == false then entry.ready = true end
    end
    out[#out + 1] = entry
  end
  table.sort(out, function(a, b) return a.level < b.level end)
  return out, earned
end

function LG.NextReward()
  local list, earned = LG.Rewards()
  for _, e in ipairs(list) do
    if e.level > earned then return e, e.level - earned end
  end
  return nil, 0
end

function LG.ReadyRewards()
  local ready = {}
  for _, e in ipairs((LG.Rewards())) do
    if e.ready then ready[#ready + 1] = table.concat(e.names, ", ") end
  end
  return ready
end

---------------------------------------------------------------------------
-- Unseen challenges (Blizzard_LegacyChallengeTracker keeps them per character).
---------------------------------------------------------------------------
function LG.HasUnseen()
  return LegacyChallengeViewedUtil ~= nil and LegacyChallengeViewedUtil.HasAnyUnviewedChallenges() or false
end

function LG.MarkAllSeen()
  if InCombatLockdown() then U.Print(ns.L.IN_COMBAT); return false end
  if not LG.HasUnseen() or type(LegacyChallengesUnviewed) ~= "table" then
    U.Print(ns.L.NOTHING_UNSEEN)
    return false
  end
  -- Clear category by category with Blizzard's own function, so its cache stays consistent.
  local cats = {}
  for _, categoryID in pairs(LegacyChallengesUnviewed) do cats[categoryID] = true end
  for categoryID in pairs(cats) do LegacyChallengeViewedUtil.MarkCategoryViewed(categoryID) end
  if UpdateMicroButtons then pcall(UpdateMicroButtons) end
  U.Print(ns.L.MARKED_SEEN)
  return true
end
