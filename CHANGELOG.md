# Changelog

## 1.2.2

### Fixes
- The libraries (LibStub, CallbackHandler, LibDataBroker, LibDBIcon) are now part of the addon. Installs without them caused "Error loading ... Libs" messages at login.
- API.lua was listed twice in the TOC ("Duplicate File Load Detected").

## 1.2.1

### Look
- The version number is shown at the bottom of the main window.

## 1.2.0

### New
- **New icon:** golden Legacy tree in the Manager family style.
- **Legacy perks in the unit tooltip** of group members who use LegacyManager.
- **Manager family bar** in the settings is clickable: opens the other installed Manager addons.

## 1.1.0

### New
- **Share codes for loadouts.** Loadout menu > Manage > "Copy share code", and "Import share code…" – plain text for chat and Discord.
- **Reward tracker:** hover the reward strip of the copilot for every reward of the season (reached, ready to collect, points to go).
- **DungeonManager in the copilot:** best dungeon with open quests for the logged-in character; click opens it in DungeonManager.
- **Group view:** click a member without LegacyManager to whisper them where to get it (once per member and session).
- **Public API** (`LegacyManagerAPI`): next class milestone and raid loadout state for DungeonManager and the coming RaidManager.
- Manager family line in `/lm status`.
- **Before the Legacy unlock** (level 25 or skill 225) a left-click opens the copilot as its own window instead of doing nothing.

### Fixed
- Invisible minimap button next to minimap skins (e.g. EllesmereUI): the button is now created a moment after login, like in the other Manager addons, so collectors such as MinimapButtonButton show it. LegacyManager also has its own icon now (the retail icon file does not exist in Forever).

### Look
- Own dialogs, context menu and close buttons instead of Blizzard's StaticPopup, MenuUtil and close button.
