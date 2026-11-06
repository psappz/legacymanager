local ADDON, ns = ...
-- Public API for the other Manager addons (DungeonManager, RaidManager). Read-only, versioned.
local API = { version = 1 }
_G.LegacyManagerAPI = API

function API.IsActive() return ns.active and true or false end

-- Opens the Legacy window, or the copilot window before the Legacy unlock
function API.Open() if ns.Minimap and ns.Minimap.OpenLegacy then ns.Minimap.OpenLegacy() end end

-- Next open class milestone (Legacy challenge) above the given level: level, points.
function API.NextClassMilestone(classFile, level)
  if not ns.active or not ns.Challenges then return nil end
  for _, ch in ipairs(ns.Challenges.ClassMilestones(classFile)) do
    if not ch.completed and (ch.level or 0) > (level or 0) then return ch.level, ch.points end
  end
  return nil
end

-- "none" (no raid loadout saved), "active" or "inactive", plus the raid loadout's name.
function API.RaidLoadoutState()
  if not ns.active or not ns.Loadouts then return "none" end
  local raid = ns.Loadouts.Raid()
  if not raid then return "none" end
  return (ns.Loadouts.Active() == raid) and "active" or "inactive", raid.name
end
