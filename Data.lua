local ADDON, ns = ...
local U = ns.U
local D = {}
ns.Data = D

-- Values from Constants.LegacyConsts (Blizzard_APIDocumentationGenerated, build 1.60.1.70532),
-- with the client's own table preferred when it exists.
local LC = (Constants and Constants.LegacyConsts) or {}
D.REWARD_FACTION = LC.LEGACY_REWARD_TRACK_FACTION_ID or 2802
D.CURRENCY = LC.LEGACY_POINTS_TRAIT_CURRENCY_ID or 4225
D.TREES = {
  LC.LEGACY_TREE_PROFESSIONS_ID or 1187,
  LC.LEGACY_TREE_ADVENTURE_ID or 1188,
  LC.LEGACY_TREE_PROGRESSION_ID or 1189, -- shown in game as "Resourcefulness"
}
D.MAX_LEVEL = 60

-- Skill line IDs (language independent).
D.CRAFTING = { 171, 164, 333, 202, 165, 197 } -- Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
D.GATHERING = { 182, 186, 393 }               -- Herbalism, Mining, Skinning
D.SECONDARY = { 185, 129, 356 }               -- Cooking, First Aid, Fishing

local DB_VERSION = 2

function D.InitDB()
  LegacyManagerDB = LegacyManagerDB or {}
  local db = LegacyManagerDB
  db.version = db.version or DB_VERSION
  if db.version < 2 then db.copilotHidden = nil end -- set by the panel's X before 0.4.11
  db.version = DB_VERSION
  db.chars = db.chars or {}
  for _, c in pairs(db.chars) do c.key = nil end -- written by 0.2.0, not needed
  db.nodes = db.nodes or {}     -- nodeID -> { tree, spellID, maxRanks }, learned from the client
  db.minimap = db.minimap or {}
  db.errors = db.errors or {}
  db.language = db.language or "auto"
  ns.db = db

  LegacyManagerCharDB = LegacyManagerCharDB or {}
  ns.cdb = LegacyManagerCharDB
end

function D.HasLegacy()
  return C_Traits ~= nil and C_Traits.GetConfigIDByTreeID ~= nil and C_MajorFactions ~= nil
end

function D.IsHardcore()
  if C_GameRules and C_GameRules.IsHardcoreActive then
    return U.Try(C_GameRules.IsHardcoreActive) and true or false
  end
  return false
end

---------------------------------------------------------------------------
-- Professions
---------------------------------------------------------------------------
local function skillInfo(id)
  if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
    local a = U.Try(C_SkillInfo.GetSkillLineInfoByID, id)
    if a and not a.isHeader and (a.maxRank or 0) > 0 then return a.rank or 0, a.maxRank or 0 end
  end
  return nil
end

function D.ReadProfessions()
  local out = {}
  for _, list in ipairs({ D.CRAFTING, D.GATHERING, D.SECONDARY }) do
    for _, id in ipairs(list) do
      local rank, max = skillInfo(id)
      if rank then out[id] = { rank = rank, max = max } end
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Legacy trees of the current character
---------------------------------------------------------------------------
function D.ConfigFor(treeID)
  return U.Try(C_Traits.GetConfigIDByTreeID, treeID)
end

local function spellForEntry(configID, entryID)
  if not entryID then return nil end
  local entry = U.Try(C_Traits.GetEntryInfo, configID, entryID)
  local defID = entry and entry.definitionID
  local def = defID and U.Try(C_Traits.GetDefinitionInfo, defID)
  return def and def.spellID or nil
end

-- Returns { [treeID] = { spent = n, ranks = { [nodeID] = rank } } } and remembers node -> spell.
function D.ReadLegacyRanks()
  local out = {}
  for _, treeID in ipairs(D.TREES) do
    local cfg = D.ConfigFor(treeID)
    if cfg then
      local tree = { spent = 0, ranks = {} }
      local cur = U.Try(C_Traits.GetTreeCurrencyInfo, cfg, treeID, false)
      if cur and cur[1] then tree.spent = cur[1].spentInTree or 0 end
      for _, nodeID in ipairs(U.Try(C_Traits.GetTreeNodes, treeID) or {}) do
        local info = U.Try(C_Traits.GetNodeInfo, cfg, nodeID)
        if info and info.ID and info.ID ~= 0 then
          local rank = info.activeRank or info.currentRank or 0
          if rank > 0 then tree.ranks[nodeID] = rank end
          local known = ns.db.nodes[nodeID]
          if not known or not known.spellID then
            local entryID = (info.activeEntry and info.activeEntry.entryID) or (info.entryIDs and info.entryIDs[1])
            ns.db.nodes[nodeID] = { tree = treeID, spellID = spellForEntry(cfg, entryID), maxRanks = info.maxRanks }
          end
        end
      end
      out[treeID] = tree
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Snapshot of the logged-in character for the alt overview and the copilot.
---------------------------------------------------------------------------
function D.Snapshot()
  if not ns.db or ns.leaving then return end
  local key = U.CharKey()
  local c = ns.db.chars[key] or {}
  local _, classFile = UnitClass("player")
  c.name = UnitName("player")
  c.realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName()
  c.class = classFile
  c.faction = UnitFactionGroup("player")
  c.level = UnitLevel("player")
  c.xp = UnitXP("player")
  c.xpMax = UnitXPMax("player")
  c.rested = GetXPExhaustion() or 0
  c.hardcore = D.IsHardcore()
  c.profs = D.ReadProfessions()
  if D.HasLegacy() then c.legacy = D.ReadLegacyRanks() end
  c.updated = time()
  ns.db.chars[key] = c
  return c
end
