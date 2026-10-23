local ADDON, ns = ...

-- Every user-facing string. enUS is the fallback for missing keys.
local LOCALES = {}

LOCALES.enUS = {
  LOADED = "Loaded. /lm shows the commands.",
  NOT_FOREVER = "This client has no Legacy system – LegacyManager stays inactive.",
  HELP = "Commands: /lm (open Legacy window) · /lm matrix (alt overview) · /lm copilot (show/hide panel) · /lm names (perk names in the tree) · /lm raidwarn · /lm seen (mark all challenges as seen) · /lm status · /lm minimap · /lm errors",

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
  MINIMAP_TIP = "Left-click: Legacy window · Right-click: alt overview · Drag: move",
  STATUS_POINTS = "Legacy points: %d earned · %d / %d spent",
  STATUS_FREE = "%d free",
  STATUS_HARDCORE = "Hardcore character",
  STATUS_NO_LEGACY = "No Legacy points yet",
  MINIMAP_SHOWN = "Minimap button shown.",
  MINIMAP_HIDDEN = "Minimap button hidden.",

  -- Copilot
  CP_SUB = "Quickest next points · all characters",
  CP_SUB_HC = "Quickest next points · Hardcore characters",
  CP_EMPTY = "No open challenge with known progress yet. Log in each of your characters once so LegacyManager knows them.",
  CP_HIDDEN = "Copilot panel hidden – /lm copilot shows it again.",
  CP_SHOWN = "Copilot panel shown.",
  CP_LEVEL = "level %d of %d",
  CP_LEVELUP = "Only %d%% to the next level · %d%% rested XP",
  CP_LEVELUP_FAR = "%d%% to the next level · %d%% rested XP",
  CP_SKILL = "%s %d of %d",
  CP_SKILL_LEFT = "%d skill points to go",
  CP_CRITERIA = "%d of %d done",
  CP_MISSING = "missing: %s",
  CP_ACCOUNT = "Account",
  CP_UNKNOWN = "%d classes without a known character – log them in once.",
  BTN_MATRIX = "Alt overview",
  HINT_EARNED = "Earned by %s",
  HINT_NEAR = "Closest: %s",

  -- Alt overview
  MX_TITLE = "LegacyManager · Alt overview",
  MX_NORMAL = "Normal",
  MX_HARDCORE = "Hardcore",
  MX_CLASS = "Class",
  MX_PROF = "Profession",
  MX_LEVEL = "Level %d",
  MX_SKILL = "Skill %d",
  MX_NEAR_LEVEL = "%s · level %d",
  MX_NEAR_SKILL = "%s · %d",
  MX_PLAN_ALL = "Profession planning: every crafting profession is learned by at least one character.",
  MX_PLAN_MISSING = "Profession planning: nobody has learned %s yet.",
  MX_FREE_SLOTS = "%s (%d free)",
  MX_PLAN_FREE = "Free primary profession slots: %s",
  MX_PLAN_NOFREE = "No known character has a free primary profession slot.",

  -- Loadouts
  LO_TITLE = "Loadout",
  LO_NONE = "No loadouts saved yet",
  LO_RAID_TAG = "Raid",
  LO_SAVE_NEW = "Save current tree as new loadout…",
  LO_OVERWRITE = "Overwrite with current tree",
  LO_MANAGE = "Manage",
  LO_RENAME = "Rename…",
  LO_MARK_RAID = "Mark as raid loadout",
  LO_UNMARK_RAID = "Remove raid mark",
  LO_DELETE = "Delete",
  LO_CUSTOM = "Unsaved",
  LO_NAME_PROMPT = "Name of the new loadout (e.g. Raid, Farming, Crafting, Leveling):",
  LO_RENAME_PROMPT = "New name for the loadout:",
  LO_NAME_TAKEN = "A loadout named \"%s\" already exists.",
  LO_SAVED = "Loadout \"%s\" saved.",
  LO_APPLIED = "Loadout \"%s\" applied.",
  LO_APPLIED_PARTIAL = "Loadout \"%s\" applied, but %d points could not be spent (limit reached or requirements not met).",
  LO_ALREADY = "Loadout \"%s\" is already active.",
  LO_NEED_TRAINER = "This loadout takes points back – that is only possible at your class trainer. Talk to your trainer and choose the loadout there.",
  LO_TIMEOUT = "The Legacy reset did not arrive – nothing was changed. Try again at the trainer.",
  LO_BOTH = "Unlearn both",
  LO_TALENTED_WARN = "At level %d the trainer only resets your Legacy talents after your class talents are unlearned: the reset also removes Talented, and its extra class talent points are spent.\n\nUnlearn both? First the class talents, then the Legacy talents – two resets, each with its own cost. Afterwards you spend your class talents again.",
  LO_CLASS_DONE = "Class talents unlearned – now the Legacy talents.",
  LO_RESPEND_CLASS = "Remember to spend your class talent points again.",
  NAMES_SHOWN = "Perk names and requirements shown in the Legacy tree.",
  NAMES_HIDDEN = "Perk names and requirements hidden in the Legacy tree.",

  -- Trainer
  TR_TITLE = "LegacyManager · Quick Swap",
  TR_SUB = "%s · level %d · active: %s",
  TR_NO_LOADOUTS = "No loadouts yet. Open the Legacy tree (Y), spend your points and save them with the Loadout button.",
  TR_POINTS = "%d points",
  TR_ACTIVE = "active",
  TR_SELECTED = "selected",
  TR_CHANGES = "Changes %s > %s",
  TR_MORE = "and %d more",
  TR_TALENTED = "At level %d the Legacy reset also removes Talented, and %d of its class talent points are spent. The trainer then requires unlearning your class talents first – a second reset with its own cost.",
  TR_CANCEL = "Cancel",
  TR_LAST_COST = "Last reset: %s",
  TR_COST_UNKNOWN = "Reset cost: shown in Blizzard's dialog",
  TR_COST_NOTE = "The price rises with every reset. You confirm it yourself.",
  TR_APPLY = "Apply %s",
  TR_APPLY_NONE = "Apply",
  TR_WAITING = "Waiting for the reset…",

  -- Raid warning
  RAID_WARN = "You are in a raid group. Your raid loadout is not active – visit your class trainer to switch.",
  RAIDWARN_ON = "Raid warning on.",
  RAIDWARN_OFF = "Raid warning off.",

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
  HELP = "Befehle: /lm (Legacy-Fenster öffnen) · /lm matrix (Alt-Matrix) · /lm copilot (Panel ein/aus) · /lm names (Perk-Namen im Baum) · /lm raidwarn · /lm seen (alle Challenges als gesehen markieren) · /lm status · /lm minimap · /lm errors",

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

  MINIMAP_TIP = "Linksklick: Legacy-Fenster · Rechtsklick: Alt-Matrix · Ziehen: verschieben",
  STATUS_POINTS = "Legacy-Punkte: %d verdient · %d / %d vergeben",
  STATUS_FREE = "%d frei",
  STATUS_HARDCORE = "Hardcore-Charakter",
  STATUS_NO_LEGACY = "Noch keine Legacy-Punkte",
  MINIMAP_SHOWN = "Minimap-Button eingeblendet.",
  MINIMAP_HIDDEN = "Minimap-Button ausgeblendet.",

  CP_SUB = "Schnellste nächste Punkte · alle Charaktere",
  CP_SUB_HC = "Schnellste nächste Punkte · Hardcore-Charaktere",
  CP_EMPTY = "Noch keine offene Challenge mit bekanntem Fortschritt. Logg jeden deiner Charaktere einmal ein, damit LegacyManager ihn kennt.",
  CP_HIDDEN = "Copilot-Panel ausgeblendet – /lm copilot blendet es wieder ein.",
  CP_SHOWN = "Copilot-Panel eingeblendet.",
  CP_LEVEL = "Level %d von %d",
  CP_LEVELUP = "Nur noch %d %% bis zum Level-up · %d %% Rested XP",
  CP_LEVELUP_FAR = "Noch %d %% bis zum Level-up · %d %% Rested XP",
  CP_SKILL = "%s %d von %d",
  CP_SKILL_LEFT = "Noch %d Skillpunkte",
  CP_CRITERIA = "%d von %d erledigt",
  CP_MISSING = "fehlt: %s",
  CP_ACCOUNT = "Account",
  CP_UNKNOWN = "%d Klassen ohne bekannten Charakter – einmal einloggen.",
  BTN_MATRIX = "Alt-Matrix",
  HINT_EARNED = "Erreicht von %s",
  HINT_NEAR = "Am nächsten: %s",

  MX_TITLE = "LegacyManager · Alt-Matrix",
  MX_NORMAL = "Normal",
  MX_HARDCORE = "Hardcore",
  MX_CLASS = "Klasse",
  MX_PROF = "Beruf",
  MX_LEVEL = "Level %d",
  MX_SKILL = "Skill %d",
  MX_NEAR_LEVEL = "%s · Level %d",
  MX_NEAR_SKILL = "%s · %d",
  MX_PLAN_ALL = "Berufsplanung: Jeder Herstellungsberuf ist bei mindestens einem Charakter gelernt.",
  MX_PLAN_MISSING = "Berufsplanung: %s hat noch kein Charakter gelernt.",
  MX_FREE_SLOTS = "%s (%d frei)",
  MX_PLAN_FREE = "Freie Primärberuf-Plätze: %s",
  MX_PLAN_NOFREE = "Kein bekannter Charakter hat einen freien Primärberuf-Platz.",

  LO_TITLE = "Loadout",
  LO_NONE = "Noch keine Loadouts gespeichert",
  LO_RAID_TAG = "Raid",
  LO_SAVE_NEW = "Aktuellen Baum als neues Loadout speichern…",
  LO_OVERWRITE = "Mit aktuellem Baum überschreiben",
  LO_MANAGE = "Verwalten",
  LO_RENAME = "Umbenennen…",
  LO_MARK_RAID = "Als Raid-Loadout markieren",
  LO_UNMARK_RAID = "Raid-Markierung entfernen",
  LO_DELETE = "Löschen",
  LO_CUSTOM = "Nicht gespeichert",
  LO_NAME_PROMPT = "Name des neuen Loadouts (z. B. Raid, Farmen, Craften, Leveln):",
  LO_RENAME_PROMPT = "Neuer Name für das Loadout:",
  LO_NAME_TAKEN = "Es gibt schon ein Loadout namens „%s“.",
  LO_SAVED = "Loadout „%s“ gespeichert.",
  LO_APPLIED = "Loadout „%s“ angewendet.",
  LO_APPLIED_PARTIAL = "Loadout „%s“ angewendet, aber %d Punkte konnten nicht vergeben werden (Limit erreicht oder Voraussetzung fehlt).",
  LO_ALREADY = "Loadout „%s“ ist bereits aktiv.",
  LO_NEED_TRAINER = "Für dieses Loadout müssen Punkte zurückgesetzt werden – das geht nur beim Klassenlehrer. Sprich mit deinem Lehrer und wähle das Loadout dort.",
  LO_TIMEOUT = "Der Legacy-Reset kam nicht an – es wurde nichts geändert. Versuch es beim Lehrer noch einmal.",
  LO_BOTH = "Beides verlernen",
  LO_TALENTED_WARN = "Mit Level %d setzt der Lehrer deine Legacy-Talente erst zurück, wenn deine Klassentalente verlernt sind: Der Reset entfernt auch Talented, und dessen zusätzliche Klassentalentpunkte sind ausgegeben.\n\nBeides verlernen? Erst die Klassentalente, dann die Legacy-Talente – zwei Resets mit jeweils eigenen Kosten. Danach verteilst du deine Klassentalente neu.",
  LO_CLASS_DONE = "Klassentalente verlernt – jetzt die Legacy-Talente.",
  LO_RESPEND_CLASS = "Denk daran, deine Klassentalentpunkte neu zu verteilen.",
  NAMES_SHOWN = "Perk-Namen und Voraussetzungen im Legacy-Baum eingeblendet.",
  NAMES_HIDDEN = "Perk-Namen und Voraussetzungen im Legacy-Baum ausgeblendet.",

  TR_TITLE = "LegacyManager · Quick Swap",
  TR_SUB = "%s · Level %d · aktiv: %s",
  TR_NO_LOADOUTS = "Noch keine Loadouts. Öffne den Legacy-Baum (Y), verteile deine Punkte und speichere sie über den Loadout-Button.",
  TR_POINTS = "%d Punkte",
  TR_ACTIVE = "aktiv",
  TR_SELECTED = "ausgewählt",
  TR_CHANGES = "Änderungen %s > %s",
  TR_MORE = "und %d weitere",
  TR_TALENTED = "Mit Level %d entfernt der Legacy-Reset auch Talented, und %d seiner Klassentalentpunkte sind ausgegeben. Der Lehrer verlangt dann, dass du zuerst deine Klassentalente verlernst – ein zweiter Reset mit eigenen Kosten.",
  TR_CANCEL = "Abbrechen",
  TR_LAST_COST = "Letzter Reset: %s",
  TR_COST_UNKNOWN = "Reset-Kosten: zeigt Blizzards Dialog",
  TR_COST_NOTE = "Der Preis steigt mit jedem Reset. Du bestätigst ihn selbst.",
  TR_APPLY = "%s anwenden",
  TR_APPLY_NONE = "Anwenden",
  TR_WAITING = "Warte auf den Reset…",

  RAID_WARN = "Du bist in einer Raidgruppe. Dein Raid-Loadout ist nicht aktiv – geh zum Klassenlehrer, wenn du es aktiv schalten willst.",
  RAIDWARN_ON = "Raid-Warnung eingeschaltet.",
  RAIDWARN_OFF = "Raid-Warnung ausgeschaltet.",

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
