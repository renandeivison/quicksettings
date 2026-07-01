# 7 buttons activated

<img width="400" alt="FileManager_2026-06-19_233942" src="https://github.com/user-attachments/assets/6b5f8aaf-4d37-439d-91ad-71b387d89b64" />

# All buttons activated

<img width="400" alt="FileManager_2026-06-28_155701" src="https://github.com/user-attachments/assets/4aadc180-6794-4eec-9665-57eecac6bfc2" />

# QuickSettings for KOReader

A fast, gesture-friendly control panel for [KOReader](https://github.com/koreader/koreader). QuickSettings adds a dedicated tab to the main menu with one-tap toggles for Wi-Fi, night mode, frontlight, rotation, and more — plus smooth brightness/warmth sliders and quick shortcuts into other installed plugins, all from a single screen.

## Features

- **One-screen control panel** — a dedicated tab in the file manager / reader menu with a grid of circular action buttons for common settings and actions.
- **Custom slider widget** — a lightweight, pill-shaped slider (built in, no external dependency) for brightness and warmth, with tap, drag, and swipe support.
- **Reorderable buttons** — long-press to open a drag-and-drop sorter and arrange the buttons in whatever order you like; hide the ones you don't use.
- **Focus Mode** — hide selected tabs from the main menu (reader and file manager) to keep the UI minimal, while QuickSettings itself always stays reachable.
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
  | Chess           | `chess`               |
  | Casual Chess    | `casualkochess`       |
  | Sync            | `kosync`              |
  | FileBrowser+    | `filebrowserplus`     |
  | BookFusion      | `bookfusion`          |

  Everything else (Wi-Fi, night mode, frontlight, rotation, USB, restart, exit, sleep, search, cloud storage) works out of the box with no extra plugins.
- **Persistent settings** — button visibility, order, slider visibility, and Focus Mode preferences are saved and restored automatically.

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
  - Enable **Focus Mode** and choose which other menu tabs to hide

## Requirements

- A recent version of KOReader.
- Icon assets bundled under `icons/` inside the plugin folder (already included in this repo).

## Contributing

Issues and pull requests are welcome. Please keep changes to button behavior backward-compatible with existing saved configurations (`show_buttons` / `button_order`) whenever possible.

## License

See [LICENSE](LICENSE) for details.

### Special Appreciation & Credits
I want to express my deep, sincere gratitude once again to **[@AnthonyGress](https://github.com/AnthonyGress)** and **[@qewer33](https://github.com/qewer33)**. A massive portion of this plugin's underlying layout handling, tracking logic, and interface engine was derived directly from their incredible work and foundational open-source contributions to the KOReader development community.
