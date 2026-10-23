local ADDON, ns = ...
local U, D, CH = ns.U, ns.Data, ns.Challenges
local CP = {}
ns.Copilot = CP

-- The copilot ranks open challenges by how far the best known character already is
-- inside the milestone's bracket (e.g. level 25 -> 45). Characters are only known
-- after they were logged in once with LegacyManager.

-- Points earned on Hardcore also count for normal characters, not the other way round:
-- the normal view uses every character, the Hardcore view only Hardcore characters.
function CP.Chars(view)
  local out = {}
  for key, c in pairs(ns.db and ns.db.chars or {}) do
    if view ~= "hardcore" or c.hardcore then
      out[#out + 1] = c
    end
  end
  return out
end

local function levelFloat(c)
  local frac = (c.xpMax and c.xpMax > 0) and (c.xp or 0) / c.xpMax or 0
  return (c.level or 1) + frac
end

function CP.RestedPct(c)
  if not c.xpMax or c.xpMax <= 0 then return 0 end
  return math.floor((c.rested or 0) / c.xpMax * 100 + 0.5)
end

function CP.ToLevelUpPct(c)
  if not c.xpMax or c.xpMax <= 0 then return 0 end
  return math.max(0, math.ceil((1 - (c.xp or 0) / c.xpMax) * 100))
end

-- Best character of a class below the target level, or nil.
function CP.BestOfClass(chars, classFile, target)
  local best
  for _, c in ipairs(chars) do
    if c.class == classFile and (c.level or 0) < target and (not best or levelFloat(c) > levelFloat(best)) then best = c end
  end
  return best
end

function CP.BestOfProf(chars, skill, req)
  local best, bestRank
  for _, c in ipairs(chars) do
    local p = c.profs and c.profs[skill]
    if p and p.rank < req and (not bestRank or p.rank > bestRank) then best, bestRank = c, p.rank end
  end
  return best, bestRank
end

local function previousMilestone(list, ch, field, floor)
  local prev = floor
  for _, other in ipairs(list) do
    local v = other[field]
    if v and v < ch[field] and v > prev then prev = v end
  end
  return prev
end

local function profName(skill)
  return (C_TradeSkillUI and U.Try(C_TradeSkillUI.GetTradeSkillDisplayName, skill)) or tostring(skill)
end
CP.ProfName = profName

-- One suggestion for a challenge, or nil when nobody known is working towards it.
function CP.ForChallenge(ch, chars)
  if ch.completed then return nil end
  local L = ns.L
  if ch.kind == "class" then
    local c = CP.BestOfClass(chars, ch.class, ch.level)
    if not c then return nil end
    local start = previousMilestone(CH.ClassMilestones(ch.class), ch, "level", 1)
    -- Only the next open milestone: below the previous one, the earlier challenge comes first.
    if (c.level or 1) < start then return nil end
    local pct = (levelFloat(c) - start) / math.max(1, ch.level - start)
    return {
      ch = ch, char = c, pct = pct,
      who = c.name .. " · " .. L.CP_LEVEL:format(c.level or 1, ch.level),
      detail = L.CP_LEVELUP:format(CP.ToLevelUpPct(c), CP.RestedPct(c)),
    }
  elseif ch.kind == "prof" then
    local c, rank = CP.BestOfProf(chars, ch.skill, ch.skillReq)
    if not c then return nil end
    local start = previousMilestone(CH.ProfMilestones(ch.skill), ch, "skillReq", 0)
    if rank < start then return nil end
    return {
      ch = ch, char = c, pct = (rank - start) / math.max(1, ch.skillReq - start),
      who = c.name .. " · " .. L.CP_SKILL:format(profName(ch.skill), rank, ch.skillReq),
      detail = L.CP_SKILL_LEFT:format(ch.skillReq - rank),
    }
  else
    local cr = ch.crit
    local pct, detail
    if cr.total == 1 and cr.items[1] and (cr.items[1].req or 0) > 1 then
      local it = cr.items[1]
      pct = (it.qty or 0) / it.req
      detail = L.CP_CRITERIA:format(it.qty or 0, it.req)
    elseif cr.total > 1 then
      pct = cr.done / cr.total
      detail = L.CP_CRITERIA:format(cr.done, cr.total)
      if #cr.missing > 0 and #cr.missing <= 2 then detail = detail .. " · " .. L.CP_MISSING:format(table.concat(cr.missing, ", ")) end
    end
    if not pct or pct <= 0 then return nil end
    return { ch = ch, pct = pct, who = L.CP_ACCOUNT, detail = detail }
  end
end

-- Sorted suggestions (closest first) and the number of classes with open class
-- challenges but no known character.
function CP.Suggestions(view, limit)
  local chars = CP.Chars(view)
  local out = {}
  local openClass, knownClass = {}, {}
  for _, c in ipairs(chars) do if c.class then knownClass[c.class] = true end end
  for _, ch in ipairs(CH.Get()) do
    if ch.kind == "class" and not ch.completed then openClass[ch.class] = true end
    local s = CP.ForChallenge(ch, chars)
    if s then out[#out + 1] = s end
  end
  table.sort(out, function(a, b) return a.pct > b.pct end)
  if limit then for i = #out, limit + 1, -1 do out[i] = nil end end
  local unknown = 0
  for classFile in pairs(openClass) do if not knownClass[classFile] then unknown = unknown + 1 end end
  return out, unknown
end
