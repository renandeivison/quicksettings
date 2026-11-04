# 7 buttons activated

<img width="400" alt="FileManager_2026-06-19_233942" src="https://github.com/user-attachments/assets/6b5f8aaf-4d37-439d-91ad-71b387d89b64" />

# All buttons activated

<img width="400" alt="FileManager_2026-07-01_194216" src="https://github.com/user-attachments/assets/52cf8c6b-693b-4d66-a2d9-9103693ad422" />

# QuickSettings for KOReader

A fast, gesture-friendly control panel for [KOReader](https://github.com/koreader/koreader). QuickSettings adds a dedicated tab to the main menu with one-tap toggles for Wi-Fi, night mode, frontlight, rotation, and more — plus smooth brightness/warmth sliders and quick shortcuts into other installed plugins, all from a single screen.

## Features

- **One-screen control panel** — a dedicated tab in the file manager / reader menu with a grid of circular action buttons for common settings and actions.
- **Custom slider widget** — a lightweight, pill-shaped slider (built in, no external dependency) for brightness and warmth, with tap, drag, and swipe support.
- **Reorderable buttons** — arrange the buttons in whatever order you like; hide the ones you don't use.
- **Focus Mode** — a distraction-free mode that strips down KOReader's main menu to just the tabs you actually use. See the [dedicated section](#focus-mode) below.
- **Smart integrations** — buttons for other plugins only appear when those plugins are actually installed:

  | Button          | Requires plugin      |
  |-----------------|-----------------------|
  | Z-Lib           | `zlibrary`            |
  | Calibre / Calibre Search | `calibre`     |
  | Streak          | `readingstreak`       |
  | LocalSend       | `localsend`           |
  | Progress / Calendar | `statistics`      |
  | Battery         | `batterystat`         |
  | QuickRSS        | `quickrss`            |
  | OPDS            | `opds`                |
  | Puzzle          | `slidepuzzle`         |
  | Crossword       | `crossword`           |
  | Connections     | `connections`         |
  | Casual Chess    | `casualkochess`       |
  | Sync            | `kosync`              |
  | FileBrowser+    | `filebrowserplus`     |
  | BookFusion      | `bookfusion`          |

  Everything else (Wi-Fi, night mode, frontlight, rotation, USB, restart, exit, sleep, search, cloud storage) works out of the box with no extra plugins.
- **Persistent settings** — button visibility, order, slider visibility, and Focus Mode preferences are saved and restored automatically.
# Button Icons Reference

Bundled icons live in the plugin's `icons/` directory and are copied to KOReader's data-directory `icons/` folder when the plugin starts. Additional user icons can also be placed in that data-directory folder. Restart KOReader after replacing icon files so cached images reload.

For new SVGs from [Tabler Icons](https://tabler.io/icons), change `stroke="currentColor"` to `stroke="#000000"`. KOReader's NanoSVG renderer treats the unsupported `currentColor` value as grey. Preserve `fill="none"` and any `stroke="none"` used for invisible paths; there is no need to change the icon's geometry or stroke width.

The picker displays SVGs from the plugin, user icons, and KOReader's built-in icon folder. It hides the `quick_`, `xquick_`, `tab_`, and `lookup_` prefixes in labels and ignores `._*` metadata and `.bak.svg` files. Stored icon identifiers retain their full filenames without the extension.

| Button | Icon filename |
|---|---|
| Wi-Fi | `quick_wifi` |
| Night Mode | `quick_nightmode` |
| Frontlight | `lightbulb` |
| Rotate | `quick_rotate` |
| Rotation Sensor | `quick_rotate` |
| USB | `quick_usb` |
| File Search | `quick_search` |
| Cloud Storage | `quick_cloud` |
| Z-Library | `quick_zlib` |
| Calibre | `quick_calibre` |
| Calibre Search | `quick_calibre` |
| Reading Progress | `quick_stats_progress` |
| Reading Calendar | `quick_stats_calendar` |
| Battery Stats | `quick_battery` |
| Reading Streak | `quick_streak` |
| LocalSend | `quick_localsend` |
| Restart | `quick_restart` |
| Exit | `quick_exit` |
| Sleep | `quick_sleep` |
| QuickRSS | `quick_quickrss` |
| OPDS | `quick_opds` |
| Puzzle | `quick_puzzle` |
| Crossword | `quick_crossword` |
| Connections | `quick_connections` |
| Casual Chess | `quick_chess` |
| KOSync | `quick_sync` |
| FileBrowser+ | `quick_filebrowser` |
| BookFusion | `quick_bookfusion` |
| Focus Mode | `quick_focus` |

## Focus Mode

Focus Mode is QuickSettings' answer to menu clutter. KOReader's menus tend to accumulate tabs as you install more plugins — Settings, Tools, Search, Navigation, Typesetting, and whatever else each plugin adds — and it's easy to end up with a bar full of tabs you never touch. Focus Mode lets you pick exactly which ones stay visible.

<img width="400"  alt="FileManager_2026-07-01_194517" src="https://github.com/user-attachments/assets/7192ce01-ade3-4075-87d8-c7d89af94f9f" />


**How it works:**

- Tap the **Focus Mode** button to open a checklist of every tab currently available in the main menu — both the standard KOReader tabs (Settings, Tools, Search, Main, Navigation, Typesetting, File Browser Settings) and any extra tabs added by other installed plugins, detected automatically.
- Check the tabs you want to **hide**, then tap **Apply & Restart**. KOReader restarts so the simplified menu takes effect everywhere (reader and file manager).
- The **QuickSettings tab itself is never hidden** — no matter what you turn off, you always have a way back into this panel (and back into Focus Mode, to undo it).
- In the reader, the **File Browser (back) tab is always kept** as well, so you can never accidentally lock yourself out of navigating back to your library.
- Focus Mode is entirely reversible: open the Focus Mode dialog again, uncheck whatever you want back, and apply. Your selection is remembered across restarts.
- It's a global toggle — once enabled, the same hidden-tabs list applies to both the file manager and the reader menu, keeping the experience consistent wherever you are in KOReader.

This makes Focus Mode especially useful on devices where you've installed several plugins for convenience but only use two or three menu tabs day-to-day — you get the functionality without the visual noise.

<img width="400" alt="FileManager_2026-07-01_194755" src="https://github.com/user-attachments/assets/4eb7904d-7e1e-491d-af23-3da65c2e93c4" />


## Installation

1. Download or clone this repository.
2. Copy the whole folder into your KOReader `plugins` directory, making sure it's named `quicksettings.koplugin`:
   - Generic: `koreader/plugins/quicksettings.koplugin`
   - Kobo: `/mnt/onboard/.adds/koreader/plugins/quicksettings.koplugin`
   - Kindle: `/mnt/us/koreader/plugins/quicksettings.koplugin`
   - Android: `<KOReader data dir>/plugins/quicksettings.koplugin`
3. Restart KOReader.
4. A new **QuickSettings** tab will appear in the main menu (file manager and/or reader).

## Usage

- Open the **QuickSettings** tab from the main menu to see the button grid and, if enabled, the brightness/warmth sliders.
- Tap a button to run its action; active/enabled states are shown with a filled circle.
- Use **Quick settings → Buttons → Arrange buttons** to reorder buttons, and the checkboxes under **Buttons** to show or hide them. Some buttons have separate long-press actions.
- Go to **Quick settings** in the settings menu to:
  - Show/hide individual buttons
  - Edit built-in button names and icons under **Button appearance**, or create and edit **Custom buttons**
  - Toggle the brightness and warmth sliders
  - Show available networks automatically when turning Wi-Fi on
  - Set QuickSettings to always open first
  - Enable **Focus Mode** and choose which other menu tabs to hide — see [Focus Mode](#focus-mode) above for details

## Requirements

- A recent version of KOReader.
- Icon assets bundled under `icons/` inside the plugin folder (already included in this repo).

### Special Appreciation & Credits
I want to express my deep, sincere gratitude once again to **[@AnthonyGress](https://github.com/AnthonyGress)** and **[@qewer33](https://github.com/qewer33)**. A massive portion of this plugin's underlying layout handling, tracking logic, and interface engine was derived directly from their incredible work and foundational open-source contributions to the KOReader development community.

## Custom button storage

Custom buttons are saved in `settings/quicksettings_custom_buttons.lua` in KOReader's data directory, outside the plugin folder. Replacing or reinstalling `quicksettings.koplugin` keeps the saved names, icons, and actions.

On first startup, this version imports an existing `quicksettings.koplugin/custom_buttons.lua` automatically. Install it over the existing plugin folder and launch KOReader once before deleting that folder. If a previous reinstall already removed that file, restore it from a backup before starting this version. The old file is retained, but is not imported again after migration, even if you delete all custom buttons.

## Built-in button appearance

Open **Quick Settings → Button appearance**, choose a built-in button, then tap **Icon** or **Name**. Each has its own reset option. Names and icons are saved in KOReader settings and survive plugin reinstalls. A custom name replaces dynamic labels such as the Wi-Fi network name until reset. Custom button names and icons remain available under **Custom buttons**.

## Backups and downgrades

Back up `settings/quicksettings_custom_buttons.lua` for custom button definitions, KOReader's `settings.reader.lua` for button order, visibility, built-in name/icon overrides, and other plugin preferences, and any user icon files. Paths are relative to KOReader's data directory; the settings directory is resolved with `DataStorage:getSettingsDir()`.

The new custom button settings file contains a `buttons` table keyed by button ID. The legacy plugin-local `custom_buttons.lua` remains untouched after import and is not kept in sync. Older plugin versions only read the legacy file, so they will not see changes saved in the new location. Retain a backup before downgrading. Migrating to another device also requires copying the referenced icon files.

## Icon attribution

The replacement main icon (`quicksettings.svg`, Tabler `adjustments-heart`) and all `xquick_*.svg` additions come from [Tabler Icons](https://tabler.io/icons), by Paweł Kuna, under the [MIT license](licenses/tabler-icons-LICENSE.txt). Their strokes were changed from `currentColor` to explicit black for KOReader rendering. This attribution covers these additions, not the provenance of every pre-existing icon in the repository.

## Validation

Run the regression checks from the repository root with LuaJIT:

```sh
luajit tests/button_order.lua
luajit tests/custom_button_storage.lua
luajit tests/reader_menu.lua
luajit tests/builtin_icons.lua
luajit -b main.lua /tmp/quicksettings-main.luac
```

The checks exercise configuration and menu code with small substitutes for KOReader services. Device validation should also cover opening QuickSettings while reading, tapping buttons and sliders, editing/resetting built-in names and icons, selecting custom icons, deleting/reordering shortcuts, restarting, and reinstalling after migration. Confirm that a saved shortcut still runs its selected action after reinstalling.
