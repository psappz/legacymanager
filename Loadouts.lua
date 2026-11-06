local ADDON, ns = ...
local U, D = ns.U, ns.Data
local LO = {}
ns.Loadouts = LO

-- A loadout is a named set of Legacy ranks of one character: { name, ranks = { [nodeID] = rank }, raid = bool }.
-- Spending free points works anywhere; taking points back needs the class trainer.

local LC = (Constants and Constants.LegacyConsts) or {}
LO.TALENTED_NODE = LC.LEGACY_TREE_ADVENTURE_TALENTED_NODE_ID or 110298
local MAX_CLASS_POINTS = 51

function LO.List()
  ns.cdb.loadouts = ns.cdb.loadouts or {}
  return ns.cdb.loadouts
end

-- Current ranks of this character, flattened over the three trees.
function LO.CurrentRanks()
  local out = {}
  for _, tree in pairs(D.ReadLegacyRanks()) do
    for nodeID, rank in pairs(tree.ranks) do out[nodeID] = rank end
  end
  return out
end

local function same(a, b)
  for k, v in pairs(a) do if (b[k] or 0) ~= v then return false end end
  for k, v in pairs(b) do if (a[k] or 0) ~= v then return false end end
  return true
end

function LO.Active()
  local cur = LO.CurrentRanks()
  for i, l in ipairs(LO.List()) do
    if same(l.ranks, cur) then return l, i end
  end
  return nil
end

function LO.Find(name)
  for i, l in ipairs(LO.List()) do if l.name == name then return l, i end end
end

function LO.Total(ranks)
  local n = 0
  for _, r in pairs(ranks) do n = n + r end
  return n
end

function LO.SaveCurrent(name)
  local l = LO.Find(name)
  if l then
    l.ranks = LO.CurrentRanks()
  else
    l = { name = name, ranks = LO.CurrentRanks() }
    table.insert(LO.List(), l)
  end
  return l
end

function LO.Delete(name)
  local _, i = LO.Find(name)
  if i then table.remove(LO.List(), i) end
end

function LO.Rename(old, new)
  local l = LO.Find(old)
  if l and not LO.Find(new) then l.name = new; return true end
  return false
end

-- Only one loadout carries the raid mark.
function LO.SetRaid(name)
  for _, l in ipairs(LO.List()) do l.raid = (l.name == name) or nil end
end

function LO.Raid()
  for _, l in ipairs(LO.List()) do if l.raid then return l end end
end

---------------------------------------------------------------------------
-- Names of perks (for diffs and labels)
---------------------------------------------------------------------------
function LO.NodeName(nodeID)
  local n = ns.db.nodes[nodeID]
  local spellID = n and n.spellID
  if spellID then
    local name = (C_Spell and C_Spell.GetSpellName and U.Try(C_Spell.GetSpellName, spellID))
      or (GetSpellInfo and U.Try(GetSpellInfo, spellID))
    if name then return name end
  end
  return "#" .. tostring(nodeID)
end

-- Short summary like "Gourmand 3 · Permanence 2 · +5"
function LO.Summary(ranks, maxItems)
  local items = {}
  for nodeID, r in pairs(ranks) do items[#items + 1] = { name = LO.NodeName(nodeID), r = r } end
  table.sort(items, function(a, b) if a.r ~= b.r then return a.r > b.r end return a.name < b.name end)
  local parts, rest = {}, 0
  for i, it in ipairs(items) do
    if i <= (maxItems or 3) then parts[#parts + 1] = it.name .. " " .. it.r else rest = rest + it.r end
  end
  if rest > 0 then parts[#parts + 1] = "+" .. rest end
  return table.concat(parts, " · ")
end

---------------------------------------------------------------------------
-- Diff between the current state and a loadout
---------------------------------------------------------------------------
function LO.Diff(target)
  local cur = LO.CurrentRanks()
  local rows, needsReset = {}, false
  local seen = {}
  for nodeID, r in pairs(cur) do seen[nodeID] = true end
  for nodeID in pairs(target) do seen[nodeID] = true end
  for nodeID in pairs(seen) do
    local from, to = cur[nodeID] or 0, target[nodeID] or 0
    if from ~= to then
      rows[#rows + 1] = { node = nodeID, name = LO.NodeName(nodeID), from = from, to = to }
      if to < from then needsReset = true end
    end
  end
  table.sort(rows, function(a, b)
    if (a.to < a.from) ~= (b.to < b.from) then return a.to < a.from end
    return a.name < b.name
  end)
  return rows, needsReset, cur
end

-- Unspent class talent points, or nil when the client does not tell.
local function unspentClassPoints()
  if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return nil end
  local cfg = U.Try(C_ClassTalents.GetActiveConfigID)
  local info = cfg and U.Try(C_Traits.GetConfigInfo, cfg)
  local tree = info and info.treeIDs and info.treeIDs[1]
  local cur = tree and U.Try(C_Traits.GetTreeCurrencyInfo, cfg, tree, false)
  return cur and cur[1] and cur[1].quantity or nil
end

-- A Legacy reset at the trainer removes every rank, Talented included. Below level 60
-- Talented's extra class talent points then go missing; if more class points are spent
-- than would be left, the trainer refuses until the class talents are unlearned.
-- Returns the number of class talent points that would be missing (0 = no problem).
function LO.ResetDeficit(cur)
  cur = cur or LO.CurrentRanks()
  local from = cur[LO.TALENTED_NODE] or 0
  if from <= 0 then return 0 end
  local level = UnitLevel("player") or 1
  local poolNow = math.min(MAX_CLASS_POINTS, math.max(0, level - 9 + from))
  local poolAfter = math.min(MAX_CLASS_POINTS, math.max(0, level - 9))
  local loss = poolNow - poolAfter
  if loss <= 0 then return 0 end
  local unspent = unspentClassPoints() or 0
  return math.max(0, loss - unspent)
end

---------------------------------------------------------------------------
-- Spending: buy ranks top to bottom (gates open as points go in), then commit.
---------------------------------------------------------------------------
local function orderedNodes(treeID, cfg)
  local list = {}
  for _, nodeID in ipairs(U.Try(C_Traits.GetTreeNodes, treeID) or {}) do
    local info = U.Try(C_Traits.GetNodeInfo, cfg, nodeID)
    if info and info.ID and info.ID ~= 0 then list[#list + 1] = info end
  end
  table.sort(list, function(a, b) if a.posY ~= b.posY then return a.posY < b.posY end return a.posX < b.posX end)
  return list
end

-- Returns bought, missing.
function LO.Spend(target)
  if InCombatLockdown() then return 0, LO.Total(target), "combat" end
  local configs, bought, missing = {}, 0, 0
  for _, treeID in ipairs(D.TREES) do
    local cfg = D.ConfigFor(treeID)
    if cfg then
      configs[cfg] = true
      for _ = 1, 8 do -- several passes: an edge or gate can open later in the same tree
        local progress = false
        for _, info in ipairs(orderedNodes(treeID, cfg)) do
          local want = target[info.ID] or 0
          local have = info.currentRank or 0
          while have < want do
            if not U.Try(C_Traits.PurchaseRank, cfg, info.ID) then break end
            have, bought, progress = have + 1, bought + 1, true
          end
        end
        if not progress then break end
      end
      -- count what could not be bought, from the staged state (the commit is asynchronous)
      for _, info in ipairs(orderedNodes(treeID, cfg)) do
        local want = target[info.ID] or 0
        if (info.currentRank or 0) < want then missing = missing + want - (info.currentRank or 0) end
      end
    end
  end
  for cfg in pairs(configs) do
    if U.Try(C_Traits.ConfigHasStagedChanges, cfg) then U.Try(C_Traits.CommitConfig, cfg) end
  end
  return bought, missing
end

---------------------------------------------------------------------------
-- Share codes: "!LM1!<class>!<name>!<node>=<rank>,..." (plain text, safe for chat and Discord)
---------------------------------------------------------------------------
function LO.Export(l)
  local _, classFile = UnitClass("player")
  local parts = {}
  local ids = {}
  for nodeID in pairs(l.ranks) do ids[#ids + 1] = nodeID end
  table.sort(ids)
  for _, nodeID in ipairs(ids) do
    local r = l.ranks[nodeID]
    if r and r > 0 then parts[#parts + 1] = nodeID .. "=" .. r end
  end
  local name = (l.name or "?"):gsub("!", "")
  return "!LM1!" .. (classFile or "?") .. "!" .. name .. "!" .. table.concat(parts, ",")
end

-- Returns the new loadout, or nil and an error key.
function LO.Import(code)
  code = (code or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local classFile, name, body = code:match("^!LM1!([^!]*)!([^!]*)!([%d=,]*)$")
  if not body then return nil, "LO_CODE_INVALID" end
  local ranks, n = {}, 0
  for nodeID, rank in body:gmatch("(%d+)=(%d+)") do
    nodeID, rank = tonumber(nodeID), tonumber(rank)
    if rank < 0 or rank > 20 then return nil, "LO_CODE_INVALID" end
    ranks[nodeID] = rank
    n = n + 1
  end
  if n == 0 then return nil, "LO_CODE_INVALID" end
  if name == "" then name = "Import" end
  local base, i = name, 2
  while LO.Find(name) do name = base .. " (" .. i .. ")"; i = i + 1 end
  local l = { name = name, ranks = ranks, from = classFile }
  table.insert(LO.List(), l)
  return l
end
