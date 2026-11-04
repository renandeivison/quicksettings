# Changelog

## Unreleased

### Added

- Built-in buttons now have editable names and icons under **Quick settings → Button appearance**, with separate reset options. Overrides are stored in KOReader settings and survive plugin reinstalls.
- Added 14 Tabler icons for custom shortcuts: body scan, AppGallery, brightness, half brightness, RSS file, letter spacing, matrix, news, notes, eye scan, trace scan, text recognition, user scan, and Wi-Fi.

### Changed

- Custom buttons are saved outside the plugin folder in `DataStorage:getSettingsDir()/quicksettings_custom_buttons.lua`. Existing plugin-local `custom_buttons.lua` entries are imported once, including names, icons, and actions.
- New custom buttons start with the name `none`.
- Replaced the main tab icon with Tabler's `adjustments-heart` icon. The new main and `xquick_` icons use explicit black strokes (`#000000`) for KOReader compatibility.
- The icon picker hides the `xquick_` filename prefix, matching its existing handling of `quick_`, `tab_`, and `lookup_`.

### Fixed

- Replaced Portuguese source labels in custom button creation, editing, and deletion with English strings while preserving translation hooks.
- Fixed duplicate buttons after deleting shortcuts and rearranging buttons. Arrangement replaces the whole saved order, and duplicate IDs already stored in settings are repaired on startup.
- Opening the QuickSettings tab in the reader closes the bottom font/margin panel so it cannot intercept button taps. Other reader tabs retain their existing behavior.
- Excluded macOS `._*` metadata files from the icon picker.
- Restored or imported custom button IDs advance the allocation counter to prevent existing shortcuts from being overwritten.

### Upgrade notes

- For the first upgrade, copy the new plugin files over the existing folder and restart KOReader **before deleting the old plugin folder**. This allows automatic migration of `custom_buttons.lua`.
- Back up `settings/quicksettings_custom_buttons.lua`, KOReader's `settings.reader.lua`, and any custom icon files. Buttons deleted by an earlier reinstall can only be recovered from a backup.
- The original `custom_buttons.lua` is retained but is not synchronized after migration. Older plugin versions do not read the new storage, so downgrading requires a backup of the legacy file and can lose edits made after migration.


## v1.2.0 - 2026-07-01

### Bug Fixes

- **Casual Chess label**: The `casualchess` button was displaying `_("Chess")` instead of `_("Casual Chess")`, making it indistinguishable from the regular chess button. Fixed to show the correct label.
- **Chess button removed**: The `chess` button (`chess.koplugin` / internal name `kochess`) was consistently failing to appear due to a mismatch between the plugin's folder name (`chess.koplugin`) and its internal `name` field (`kochess`). After multiple fix attempts — including dual `hasPlugin` checks and a rewritten `hasPlugin` using KOReader's `plugins_disabled` list — the button was removed entirely to avoid instability. The `casualchess` button (`casualkochess.koplugin`) remains and works correctly.

### Icons

- **Icon placement**: Custom icons should be placed in the `koreader/icons` folder for proper loading and display.

### Focus Mode

- **Tab selection dialog**: Added a visual tab selection dialog that opens when the Focus Mode button is clicked. Users can choose which tabs to hide before applying.
- **Icons in dialog**: Each tab in the selection list now shows its corresponding KOReader icon alongside the checkbox, making it easier to identify tabs visually. Icon map used:

| Tab | Icon |
| -- | -- |
| File Browser Settings | appbar.filebrowser |
| Settings | appbar.settings |
| Tools | appbar.tools |
| Search | appbar.search |
| Main | appbar.menu |
| Navigation | appbar.navigation |
| Typesetting | appbar.typeset |
| Return to File Browser | appbar.filebrowser |

- **Plus Menu removed** from the tab list — it is not a real navigation tab.
- **Main tab icon corrected** from `home` to `appbar.menu`.
- **Checkbox visual feedback**: Clicking a checkbox now closes and rebuilds the dialog immediately, reflecting the updated state — fixing the issue where selections had no visible confirmation.
- **Dialog centering**: The dialog is now centered on screen using `CenterContainer`, replacing the previous `MovableContainer` that positioned it in the upper corner.
- **Buttons**: Dialog has two buttons — "Cancel" (closes without changes) and "Apply & Restart" (saves selection and restarts KOReader). "Disable & Restart" was removed; disabling Focus Mode is now done by applying with zero tabs selected.
- **Focus mode state**: `config.focus_mode` is automatically set to `false` when "Apply & Restart" is confirmed with no tabs selected, and `true` when at least one tab is selected.
- **Dynamic tab detection**: Tabs installed by third-party plugins (not in the fixed list) are detected from the current `tab_item_table` at dialog open time and added to the selection list automatically.
