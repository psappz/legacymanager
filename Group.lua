local ADDON, ns = ...
local U, D = ns.U, ns.Data
local GR = {}
ns.Group = GR

-- Group view: members running LegacyManager share their Legacy ranks with the
-- group (party, raid, battleground or other instance group) through addon messages.
--
-- Messages (prefix "LegacyMgr"):
--   "1|R"                          request: everyone answers with their ranks
--   "1|S|<level>|<spell>:<rank>,…" ranks of the sender, keyed by spell ID
--                                  (spell IDs are the same for every client)
-- Unknown versions are ignored, so later formats can coexist.

local PREFIX, VERSION = "LegacyMgr", "1"
local SEND_THROTTLE = 4

-- Perks that matter for a group, by spell ID, in column order.
GR.COLUMNS = {
  1225502, -- Permanence: group buffs last longer
  1225499, -- Gourmand: food buffs last longer
  1225503, -- Reagent Economy: no vendor reagents
  1225500, -- The Quick and the Dead
  1225501, -- For Great Honor
}

GR.members = {} -- ["Name" or "Name-Realm"] = { ranks = { [spellID] = rank }, level, t }

---------------------------------------------------------------------------
-- Own ranks by spell ID
---------------------------------------------------------------------------
function GR.OwnRanks()
  local out = {}
  for _, tree in pairs(D.ReadLegacyRanks()) do
    for nodeID, rank in pairs(tree.ranks) do
      local n = ns.db.nodes[nodeID]
      if n and n.spellID then out[n.spellID] = rank end
    end
  end
  return out
end

local function encode(ranks)
  local parts = {}
  for spellID, rank in pairs(ranks) do parts[#parts + 1] = spellID .. ":" .. rank end
  table.sort(parts)
  return table.concat(parts, ",")
end

function GR.Decode(payload)
  local ranks = {}
  for spellID, rank in (payload or ""):gmatch("(%d+):(%d+)") do
    ranks[tonumber(spellID)] = tonumber(rank)
  end
  return ranks
end

---------------------------------------------------------------------------
-- Channel and roster
---------------------------------------------------------------------------
function GR.Channel()
  if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
  if IsInRaid and IsInRaid() then return "RAID" end
  if IsInGroup and IsInGroup() then return "PARTY" end
  return nil
end

local function unitName(unit)
  local n = GetUnitName and GetUnitName(unit, true)
  return n and n ~= "" and n or nil
end

-- { { name, unit, class, level, self } ... } in group order
function GR.Roster()
  local out = {}
  local n = GetNumGroupMembers and GetNumGroupMembers() or 0
  if n == 0 then
    out[1] = { name = unitName("player"), unit = "player", self = true }
  elseif IsInRaid() then
    for i = 1, n do out[#out + 1] = { name = unitName("raid" .. i), unit = "raid" .. i } end
  else
    out[1] = { name = unitName("player"), unit = "player", self = true }
    for i = 1, n - 1 do out[#out + 1] = { name = unitName("party" .. i), unit = "party" .. i } end
  end
  local me = unitName("player")
  for _, m in ipairs(out) do
    local _, classFile = UnitClass(m.unit)
    m.class = classFile
    m.level = UnitLevel(m.unit)
    if m.name == me then m.self = true end
  end
  return out
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------
local function send(text)
  local channel = GR.Channel()
  if not channel or not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
  U.Try(C_ChatInfo.SendAddonMessage, PREFIX, text, channel)
end

local lastSent = 0
function GR.SendRanks()
  if not GR.Channel() then return end
  local wait = SEND_THROTTLE - (GetTime() - lastSent)
  if wait > 0 then ns.Schedule("lmGroupSend", wait, GR.SendRanks); return end
  lastSent = GetTime()
  send(VERSION .. "|S|" .. (UnitLevel("player") or 0) .. "|" .. encode(GR.OwnRanks()))
end

local lastRequest = 0
function GR.Request()
  if not GR.Channel() then return end
  if GetTime() - lastRequest < 10 then return end -- every request makes the whole group answer
  lastRequest = GetTime()
  send(VERSION .. "|R")
  ns.Schedule("lmGroupSend", 0.5 + math.random() * 2, GR.SendRanks)
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------
function GR.OnMessage(prefix, text, _, sender)
  if prefix ~= PREFIX or not text or not sender then return end
  local name = Ambiguate and Ambiguate(sender, "none") or sender
  if name == unitName("player") then return end
  local version, kind, rest = text:match("^(%d+)|(%a)|?(.*)$")
  if version ~= VERSION then return end
  if kind == "R" then
    -- spread the answers so a 40-player raid does not answer at once
    ns.Schedule("lmGroupSend", 0.5 + math.random() * 3, GR.SendRanks)
  elseif kind == "S" then
    local level, payload = rest:match("^(%d+)|(.*)$")
    GR.members[name] = { ranks = GR.Decode(payload), level = tonumber(level), t = time() }
    if ns.UIGroup then ns.Schedule("lmGroupUI", 0.2, ns.UIGroup.Refresh) end
  end
end

-- Group composition changed: ask once, forget members who left.
local lastChannel
function GR.OnRosterChanged()
  local channel = GR.Channel()
  if not channel then GR.members = {}; lastChannel = nil; return end
  local present = {}
  for _, m in ipairs(GR.Roster()) do if m.name then present[m.name] = true end end
  for name in pairs(GR.members) do if not present[name] then GR.members[name] = nil end end
  if channel ~= lastChannel then
    lastChannel = channel
    ns.Schedule("lmGroupReq", 2, GR.Request)
  else
    ns.Schedule("lmGroupSend", 2 + math.random() * 2, GR.SendRanks) -- newcomers learn about us
  end
  if ns.UIGroup then ns.Schedule("lmGroupUI", 0.5, ns.UIGroup.Refresh) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    if not D.HasLegacy() then return end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then U.Try(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
  elseif event == "CHAT_MSG_ADDON" then
    ns.SafeCall("groupMsg", GR.OnMessage, ...)
  elseif event == "GROUP_ROSTER_UPDATE" then
    ns.Schedule("lmRoster", 1, GR.OnRosterChanged)
  elseif event == "PLAYER_ENTERING_WORLD" then
    lastChannel = nil -- new instance group (battleground, dungeon finder): ask again
    ns.Schedule("lmRoster", 4, GR.OnRosterChanged)
  elseif event == "TRAIT_CONFIG_UPDATED" then
    ns.Schedule("lmGroupSend", 2, GR.SendRanks)
    if ns.UIGroup then ns.Schedule("lmGroupUI", 1, ns.UIGroup.Refresh) end
  end
end)
