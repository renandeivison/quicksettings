# 7 buttons activated

<img width="400" alt="FileManager_2026-06-19_233942" src="https://github.com/user-attachments/assets/6b5f8aaf-4d37-439d-91ad-71b387d89b64" />

# All buttons activated

<img width="400" alt="FileManager_2026-06-28_155701" src="https://github.com/user-attachments/assets/4aadc180-6794-4eec-9665-57eecac6bfc2" />

# Quick Settings Plugin for KOReader

A native, clean, and highly customizable **Quick Settings Panel** for KOReader. This plugin combines a beautiful slider interface with an accessible control toggle panel.

This project is a hybrid merge of two excellent community resources, compiled, reworked, and optimized using AI assistance:
*   **ZenUI Sliders:** Derived from [AnthonyGress/zen_ui.koplugin](https://github.com/AnthonyGress/zen_ui.koplugin).
*   **Quick Settings Logic:** Derived from the `2-quick-settings.lua` patch found in [qewer33/koreader-patches](https://github.com/qewer33/koreader-patches).

---

## Disclaimer & Purpose

> **Note:** This plugin was originally put together purely for my **personal use** to streamline my own e-reader workflow. It is being shared publicly here because members of the community asked for it. 
> 
> As a personal project maintained in my spare time, it is provided "as-is." While you are more than welcome to use, fork, or modify it, please keep in mind that official support or frequent updates are not guaranteed.

> **Tested Device:** This plugin was developed and tested exclusively on a **Kindle Paperwhite 11/12 Signature Edition**. While it is designed to be compatible with other devices running KOReader, performance and layout rendering on other hardware cannot be guaranteed.

---

## Features

*   **Integrated Panel:** Combines your main navigation bar, quick toggle buttons, and frontlight sliders into a single unified menu view.
*   **ZenUI Sliders:** Upgrades the native KOReader frontlight/warmth bars with smooth, gesture-friendly pill-and-circle sliders.
*   **Dynamic Grid Layout:** Displays a perfectly proportioned single row when you select up to 7 buttons. If you enable more than 7 items, the plugin automatically adds new rows to accommodate your selection cleanly.
*   **Smart Plugin Autodetection:** Optional buttons are automatically hidden unless their corresponding plugins are actually installed on your device, preventing interface clutter.
*   **Robust Environment Compatibility:** Re-engineered internal plugin detection paths to work seamlessly across all platforms, including Kindle devices where working directories vary from the KOReader root.
*   **Native Customization Menu:** Injects seamlessly into KOReader's native settings menu (`Settings -> Quick settings`), allowing you to toggle slider visibility, enforce opening defaults, and reorder your button layout via a drag-and-drop sort widget.

---

## Installation & Upgrading

1.  **Download the plugin:** Download the latest version of this repository.
2.  **Access your device directory:** Connect your e-reader to your computer via USB, or use an SSH/SFTP connection.
3.  **Navigate to the plugins folder:** Go to the KOReader internal directory:
   
    koreader/plugins/
   
4.  **Create/Replace the plugin folder:** Ensure your folder is named exactly `quicksettings.koplugin`:
   
    koreader/plugins/quicksettings.koplugin/
   
5.  **Place the files:** Paste the `main.lua` file **and the accompanying `icons/` folder** inside `quicksettings.koplugin/`.

>  **IMPORTANT TAB ICON NOTE:** 
> * **If you are already using ZenUI:** The main plugin tab icon will automatically be pulled from ZenUI. No extra steps are required.
> * **If you are NOT using ZenUI:** You **must** manually place an icon file into your KOReader icons directory at `/koreader/icons/quicksettings.svg` or `/koreader/icons/quicksettings.png`. Otherwise, the main menu tab icon will not display correctly.

6.  **Restart KOReader:** Safely eject your device or restart the KOReader software. *Note: If upgrading from an older version, your existing button sequence configuration will be automatically preserved and backfilled.*

---

## Localized Icon System & Customization

All button action icons now load locally directly from `plugins/quicksettings.koplugin/icons/` instead of polluting KOReader's global cache. 

### PNG → SVG Auto-Fallback
The asset loader automatically detects the file type. If a preferred `.png` icon is missing from the local folder, it will instantly fall back and look for the `.svg` variant at the same path. 

### Using Custom Icons
You can easily completely customize the button interface with your own custom icons! Simply create or download your preferred graphic, name it exactly like the button ID listed below (using either `.png` or `.svg`), and drop it into `plugins/quicksettings.koplugin/icons/`:

| Button ID / Asset Name | Linked Feature / Core Plugin Dependency | Action Behavior |
| :--- | :--- | :--- |
| `quick_wifi` | Core Wi-Fi Toggle | Switches Wi-Fi State (Optional Network List prompt) |
| `quick_nightmode`| Core Night Mode | Toggles E-Ink Night Mode colors |
| `quick_rotate` | Core Screen Rotation | Cycles display rotation |
| `quick_usb` | Core USB Mass Storage | Launches USB connection screen |
| `quick_restart` | Core System Action | Restarts KOReader |
| `quick_exit` | Core System Action | Exits KOReader |
| `quick_sleep` | Core System Action | Puts device into Sleep Mode |
| `quick_search` | Core Search Engine / Calibre | Launches text search or Calibre Catalog Search |
| `quick_cloud` | Core Cloud Storage | Opens Cloud management |
| `quick_zlib` | Z-Library Plugin | Launches local Z-Library portal |
| `quick_calibre` | Calibre Plugin | Launches Calibre connection menu |
| `quick_streak` | Reading Streak Plugin | Reviews your daily reading metrics |
| `quick_filebrowserplus` | filebrowserplus.koplugin | Toggles server state and reads local PID runtime files |
| `quick_stats_progress` | Core Reading Statistics | Direct path to your reading progress |
| `quick_stats_calendar` | Core Reading Statistics | Direct path to your reading history calendar |
| `quick_battery` | Core Battery Module | Reviews battery lifecycle diagnostics |
| `quickrss` | quickrss.koplugin | Launches direct Feed View via core UI modules |
| `opds` | opds.koplugin | Broadcasts standard `ShowOPDSCatalog` dispatch event |
| `puzzles` | slidepuzzle.koplugin | Launches standard `SlidePuzzleOpen` overlay |
| `crossword` | crossword.koplugin | Broadcasts native Dispatcher `CrosswordMenu` menu event |
| `connections` | connections.koplugin | Invokes the NYT Connections `addToMainMenu` callback |
| `chess` | chess.koplugin | Dispatches the native `KochessStart` event loop |
| `casual_chess` | casualkochess.koplugin | Dispatches the native `CasualChessStart` event loop |
| `kosync` | kosync.koplugin | Forces a background sync via the active running instance |

---

## Configuration

Once installed, you can configure the plugin directly within KOReader:
1. Open the top menu in KOReader.
2. Navigate to the **Gear icon (Settings)** -> **Quick settings**.
3. From here, you can:
    * Enable or disable specific action buttons.
    * Tap **"Organizar botões"** (Arrange buttons) to change their sequence.
    * Toggle the visibility of the Brightness and Warmth sliders.
    * Toggle the option to **show or hide the list of available Wi-Fi networks** immediately upon turning Wi-Fi on.

---

## Credits & Acknowledgments

This plugin would not be possible without the hard work of the original developers:
*   **AnthonyGress** for the beautiful [ZenUI slider engine](https://github.com/AnthonyGress/zen_ui.koplugin) implementation.
*   **qewer33** for the versatile [Quick Settings patch logic](https://github.com/qewer33/koreader-patches).
*   The **KOReader Development Team** for creating an amazingly extensible e-reading platform.
