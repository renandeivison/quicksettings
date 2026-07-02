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

Coppy the icons to 
`Koreader/icons`  
If a `.png` file is missing, the plugin automatically falls back to the `.svg` variant at the same path.

| Button | Icon filename |
|---|---|
| Wi-Fi | `quick_wifi` |
| Night Mode | `quick_nightmode` |
| Frontlight | `quick_nightmode` |
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
- Long-press any button (or use the "Arrange buttons" option in settings) to reorder or hide buttons.
- Go to **Quick settings** in the settings menu to:
  - Show/hide individual buttons
  - Toggle the brightness and warmth sliders
  - Show available networks automatically when turning Wi-Fi on
  - Set QuickSettings to always open first
  - Enable **Focus Mode** and choose which other menu tabs to hide — see [Focus Mode](#focus-mode) above for details

## Requirements

- A recent version of KOReader.
- Icon assets bundled under `icons/` inside the plugin folder (already included in this repo).

### Special Appreciation & Credits
I want to express my deep, sincere gratitude once again to **[@AnthonyGress](https://github.com/AnthonyGress)** and **[@qewer33](https://github.com/qewer33)**. A massive portion of this plugin's underlying layout handling, tracking logic, and interface engine was derived directly from their incredible work and foundational open-source contributions to the KOReader development community.
