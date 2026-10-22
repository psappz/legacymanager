local ADDON, ns = ...
local U, D = ns.U, ns.Data
local CH = {}
ns.Challenges = CH

-- Legacy challenges are achievements. Everything is read from the client, so new
-- challenges of later seasons appear without an addon update.

local LC = (Constants and Constants.LegacyConsts) or {}
CH.CLASS_CATEGORY = {
  WARRIOR = LC.LEGACY_DEFAULT_CATEGORY_WARRIOR or 15585,
  PALADIN = LC.LEGACY_DEFAULT_CATEGORY_PALADIN or 15580,
  HUNTER = LC.LEGACY_DEFAULT_CATEGORY_HUNTER or 15578,
  ROGUE = LC.LEGACY_DEFAULT_CATEGORY_ROGUE or 15582,
  PRIEST = LC.LEGACY_DEFAULT_CATEGORY_PRIEST or 15581,
  SHAMAN = LC.LEGACY_DEFAULT_CATEGORY_SHAMAN or 15583,
  MAGE = LC.LEGACY_DEFAULT_CATEGORY_MAGE or 15579,
  WARLOCK = LC.LEGACY_DEFAULT_CATEGORY_WARLOCK or 15584,
  DRUID = LC.LEGACY_DEFAULT_CATEGORY_DRUID or 15577,
}
CH.CLASS_ORDER = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }

-- Criteria types of the achievement system (stable since Wrath).
local CRITERIA_REACH_LEVEL = 5
local CRITERIA_REACH_SKILL = 7
local CRITERIA_LEARN_SKILL_LEVEL = 40

local classOfCategory = {}
for classFile, cat in pairs(CH.CLASS_CATEGORY) do classOfCategory[cat] = classFile end

local isCrafting = {}
for _, id in ipairs(D.CRAFTING) do isCrafting[id] = true end

local function firstNumber(text)
  return text and tonumber(text:match("(%d+)")) or nil
end

local profByName -- localized profession name -> skill line ID
local function professionNames()
  if profByName then return profByName end
  profByName = {}
  for _, id in ipairs(D.CRAFTING) do
    local name = C_TradeSkillUI and U.Try(C_TradeSkillUI.GetTradeSkillDisplayName, id)
    if name and name ~= "" then profByName[name:lower()] = id end
  end
  return profByName
end

local function legacyPoints(id, fallback)
  if C_Traits and C_Traits.GetTraitCurrencyForAchievement then
    local n = U.Try(C_Traits.GetTraitCurrencyForAchievement, D.CURRENCY, id)
    if n ~= nil then return n end
  end
  return fallback or 0
end

local function readCriteria(id)
  local crit = { total = 0, done = 0, missing = {}, items = {} }
  local num = U.Try(GetAchievementNumCriteria, id) or 0
  for i = 1, num do
    local text, ctype, done, qty, req, _, _, assetID = U.TryAll(GetAchievementCriteriaInfo, id, i)
    crit.total = crit.total + 1
    if done then crit.done = crit.done + 1 elseif text and text ~= "" then crit.missing[#crit.missing + 1] = text end
    crit.items[i] = { type = ctype, asset = assetID, qty = qty, req = req, done = done and true or false }
  end
  return crit
end

local function classify(ch, catName, parentCat)
  local classFile = classOfCategory[ch.cat] or classOfCategory[parentCat or -1]
  if classFile then
    ch.kind, ch.class = "class", classFile
    for _, it in ipairs(ch.crit.items) do
      if it.type == CRITERIA_REACH_LEVEL and it.req and it.req > 1 then ch.level = it.req end
    end
    ch.level = ch.level or firstNumber(ch.desc)
    if ch.level then return end
  end
  for _, it in ipairs(ch.crit.items) do
    if (it.type == CRITERIA_REACH_SKILL or it.type == CRITERIA_LEARN_SKILL_LEVEL) and isCrafting[it.asset] then
      ch.kind, ch.skill, ch.skillReq = "prof", it.asset, it.req
      return
    end
  end
  local byName = professionNames()
  local skill = catName and byName[catName:lower()]
  if skill and firstNumber(ch.desc) then
    ch.kind, ch.skill, ch.skillReq = "prof", skill, firstNumber(ch.desc)
    return
  end
  ch.kind = "other"
end

-- Reads every Legacy challenge. Returns the list and keeps a copy in the saved
-- variables (used while offline data is shown and to check new seasons).
function CH.Scan()
  local list = {}
  for _, cat in ipairs(U.Try(GetCategoryList) or {}) do
    local catName, parentCat = U.TryAll(GetCategoryInfo, cat)
    local n = U.Try(GetCategoryNumAchievements, cat, true) or 0
    for index = 1, n do
      local id, name, points, completed, _, _, _, desc, _, icon, _, _, wasEarnedByMe, earnedBy = U.TryAll(GetAchievementInfo, cat, index)
      if id then
        local lp = legacyPoints(id, points)
        if lp > 0 then
          local ch = {
            id = id, cat = cat, catName = catName, name = name, desc = desc, icon = icon,
            points = lp, completed = completed and true or false,
            earnedBy = (earnedBy ~= "" and earnedBy) or nil, mine = wasEarnedByMe and true or false,
            crit = readCriteria(id),
          }
          classify(ch, catName, parentCat)
          list[#list + 1] = ch
        end
      end
    end
  end
  CH.list = list
  CH.byID = {}
  for _, ch in ipairs(list) do CH.byID[ch.id] = ch end
  if ns.db then
    local cache = {}
    for _, ch in ipairs(list) do
      cache[#cache + 1] = { id = ch.id, kind = ch.kind, class = ch.class, level = ch.level, skill = ch.skill,
        skillReq = ch.skillReq, points = ch.points, completed = ch.completed, name = ch.name }
    end
    ns.db.challenges = cache
  end
  return list
end

function CH.Get()
  return CH.list or CH.Scan()
end

function CH.Invalidate() CH.list = nil end

-- Milestones of one class or profession, sorted, e.g. { 25, 45, 60 }.
function CH.ClassMilestones(classFile)
  local out = {}
  for _, ch in ipairs(CH.Get()) do
    if ch.kind == "class" and ch.class == classFile then out[#out + 1] = ch end
  end
  table.sort(out, function(a, b) return a.level < b.level end)
  return out
end

function CH.ProfMilestones(skill)
  local out = {}
  for _, ch in ipairs(CH.Get()) do
    if ch.kind == "prof" and ch.skill == skill then out[#out + 1] = ch end
  end
  table.sort(out, function(a, b) return (a.skillReq or 0) < (b.skillReq or 0) end)
  return out
end
