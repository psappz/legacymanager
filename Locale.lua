local ADDON, ns = ...

-- Every user-facing string. enUS is the fallback for missing keys.
local LOCALES = {}

LOCALES.enUS = {
  LOADED = "Loaded. /lm shows the commands.",
  NOT_FOREVER = "This client has no Legacy system – LegacyManager stays inactive.",
  HELP = "Commands: /lm (open Legacy window) · /lm seen (mark all challenges as seen) · /lm status · /lm minimap · /lm errors",

  -- Legacy tree
  TREE_SPENT = "%d / %d spent",
  TREE_OVER = "+%d only for the Progress Track",
  TREE_TO_CAP = "%d more to reach the limit",
  TREE_TIP_TITLE = "Legacy points",
  TREE_TIP_EARNED = "Earned on this account: %d",
  TREE_TIP_CAP = "Spendable per character this season: %d",
  TREE_TIP_SPENT = "Spent on this character: %d",
  TREE_TIP_FREE = "Free: %d",
  TREE_TIP_OVER = "Points above the limit still count for the Progress Track rewards.",

  -- Challenges
  MARK_ALL_SEEN = "Mark all seen",
  MARK_ALL_TIP = "Clears the blue glow of all new Legacy challenges at once.",
  MARKED_SEEN = "All Legacy challenges marked as seen.",
  NOTHING_UNSEEN = "There are no unseen Legacy challenges.",

  -- Reward track
  REWARD_NEXT = "%d more points to: %s",
  REWARD_NEXT_ONE = "1 more point to: %s",
  REWARD_ALL = "All rewards of this season reached.",
  REWARD_READY = "Ready to collect at Innkeeper Wiley in Ratchet: %s",
  REWARD_READY_CHAT = "Legacy reward ready to collect at Innkeeper Wiley in Ratchet: %s",

  -- Minimap / compartment
  MINIMAP_TIP = "Left-click: Legacy window · Drag: move",
  STATUS_POINTS = "Legacy points: %d earned · %d / %d spent",
  STATUS_FREE = "%d free",
  STATUS_HARDCORE = "Hardcore character",
  STATUS_NO_LEGACY = "No Legacy points yet",
  MINIMAP_SHOWN = "Minimap button shown.",
  MINIMAP_HIDDEN = "Minimap button hidden.",

  -- Errors
  IN_COMBAT = "Not possible in combat – try again afterwards.",
  ERRORS_TITLE = "Error log",
  ERRORS_NONE = "No errors recorded.",
  ERRORS_PENDING = "An error was recorded in the last session – /lm errors shows details.",
  ERRORS_CLEARED = "Error log cleared.",
}

LOCALES.deDE = {
  LOADED = "Geladen. /lm zeigt die Befehle.",
  NOT_FOREVER = "Dieser Client hat kein Legacy-System – LegacyManager bleibt inaktiv.",
  HELP = "Befehle: /lm (Legacy-Fenster öffnen) · /lm seen (alle Challenges als gesehen markieren) · /lm status · /lm minimap · /lm errors",

  TREE_SPENT = "%d / %d vergeben",
  TREE_OVER = "+%d nur für den Progress Track",
  TREE_TO_CAP = "noch %d bis zum Limit",
  TREE_TIP_TITLE = "Legacy-Punkte",
  TREE_TIP_EARNED = "Auf diesem Account verdient: %d",
  TREE_TIP_CAP = "Pro Charakter in dieser Saison ausgebbar: %d",
  TREE_TIP_SPENT = "Auf diesem Charakter vergeben: %d",
  TREE_TIP_FREE = "Frei: %d",
  TREE_TIP_OVER = "Punkte über dem Limit zählen weiter für die Belohnungen des Progress Tracks.",

  MARK_ALL_SEEN = "Alle gesehen",
  MARK_ALL_TIP = "Entfernt das blaue Leuchten aller neuen Legacy-Challenges auf einmal.",
  MARKED_SEEN = "Alle Legacy-Challenges als gesehen markiert.",
  NOTHING_UNSEEN = "Es gibt keine ungesehenen Legacy-Challenges.",

  REWARD_NEXT = "Noch %d Punkte bis: %s",
  REWARD_NEXT_ONE = "Noch 1 Punkt bis: %s",
  REWARD_ALL = "Alle Belohnungen dieser Saison erreicht.",
  REWARD_READY = "Abholbereit bei Gastwirt Wiley in Ratschet: %s",
  REWARD_READY_CHAT = "Legacy-Belohnung abholbereit bei Gastwirt Wiley in Ratschet: %s",

  MINIMAP_TIP = "Linksklick: Legacy-Fenster · Ziehen: verschieben",
  STATUS_POINTS = "Legacy-Punkte: %d verdient · %d / %d vergeben",
  STATUS_FREE = "%d frei",
  STATUS_HARDCORE = "Hardcore-Charakter",
  STATUS_NO_LEGACY = "Noch keine Legacy-Punkte",
  MINIMAP_SHOWN = "Minimap-Button eingeblendet.",
  MINIMAP_HIDDEN = "Minimap-Button ausgeblendet.",

  IN_COMBAT = "Im Kampf nicht möglich – versuch es danach noch einmal.",
  ERRORS_TITLE = "Fehlerprotokoll",
  ERRORS_NONE = "Keine Fehler aufgezeichnet.",
  ERRORS_PENDING = "In der letzten Sitzung wurde ein Fehler aufgezeichnet – /lm errors zeigt Details.",
  ERRORS_CLEARED = "Fehlerprotokoll geleert.",
}

LOCALES.enGB = LOCALES.enUS

ns.L = {}

function ns.ApplyLocale(code)
  if not code or code == "auto" then code = (GetLocale and GetLocale()) or "enUS" end
  local active = LOCALES[code] or LOCALES.enUS
  ns.activeLocale = code
  setmetatable(ns.L, { __index = function(_, k) return active[k] or LOCALES.enUS[k] or k end })
end

ns.ApplyLocale("auto")
ns._LOCALES = LOCALES
