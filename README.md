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

 **Tested Device:** This plugin was developed and tested exclusively on a **Kindle Paperwhite 11/12 Signature Edition**. While it is designed to be compatible with other devices running KOReader, performance and layout rendering on other hardware cannot be guaranteed.

---

## Features

*   **Integrated Panel:** Combines your main navigation bar, quick toggle buttons, and frontlight sliders into a single unified menu view.
*   **ZenUI Sliders:** Upgrades the native KOReader frontlight/warmth bars with smooth, gesture-friendly pill-and-circle sliders.
*   **Dynamic Grid Layout:** Displays a perfectly proportioned single row when you select up to 7 buttons. If you enable more than 7 items, the plugin automatically adds new rows to accommodate your selection cleanly.
*   **Smart Hardware & Plugin Autodetection:** Optional buttons are hidden automatically unless their dependencies are met. Buttons for external plugins require those plugins to be installed, while specific hardware toggles (like frontlight and auto-rotation) only appear on devices that physically support those features.
*   **Robust Environment Compatibility:** Re-engineered internal plugin detection paths to work seamlessly across all platforms, including Kindle devices where working directories vary from the KOReader root.
*   **Native Customization Menu:** Injects seamlessly into KOReader's native settings menu (`Settings -> Quick settings`), allowing you to toggle slider visibility, enforce opening defaults, and reorder your button layout via a drag-and-drop sort widget.

 **Important Note on Core/External Plugins:** This plugin does **not** bundle any third-party tools or games (like Chess, Crossword, QuickRSS, etc.). It only acts as a control panel shortcut to trigger them. All dependent plugins must be downloaded and installed separately on your device for their respective buttons to appear.


---

## 🛠️ Installation & Upgrading

1.  **Download the plugin:** Download the latest version of this repository.
2.  **Access your device directory:** Connect your e-reader to your computer via USB, or use an SSH/SFTP connection.
3.  **Navigate to the plugins folder:** Go to the KOReader internal directory:
    ```bash
    koreader/plugins/
    ```
4.  **Create/Replace the plugin folder:** Ensure your folder is named exactly `quicksettings.koplugin`:
    ```bash
    koreader/plugins/quicksettings.koplugin/
    ```
5.  **Place the files:** Paste the `main.lua` file **and the accompanying `icons/` folder** inside `quicksettings.koplugin/`.

> **IMPORTANT TAB ICON NOTE:** 
> * **If you are already using ZenUI:** The main plugin tab icon will automatically be pulled from ZenUI. No extra steps are required.
> * **If you are NOT using ZenUI:** You **must** manually place an icon file into your KOReader icons directory at `/koreader/icons/quicksettings.svg` or `/koreader/icons/quicksettings.png`. Otherwise, the main menu tab icon will not display correctly.

6.  **Restart KOReader:** Safely eject your device or restart the KOReader software. *Note: If upgrading from an older version, your existing button sequence configuration will be automatically preserved and backfilled.*

---

## Localized Icon System & Customization

All button action icons now load locally directly from `plugins/quicksettings.koplugin/icons/` instead of polluting KOReader's global cache. 

### PNG → SVG Auto-Fallback
The asset loader automatically detects the file type. If a preferred `.png` icon is missing from the local folder, it will instantly fall back and look for the `.svg` variant at the same path. 

### Using Custom Icons
You can fully customize the interface by replacing the original images with your preferred graphics. The plugin manages icon loading locally from `plugins/quicksettings.koplugin/icons/`. Make sure to keep the exact filename (with the original `.png` extension or the automatic `.svg` fallback) as specified in the table below:

| Display Name (Label) | Icon Path in Plugin | Behavior / Hardware or Plugin Dependency |
| :--- | :--- | :--- |
| "Wi-Fi" | `icons/quick_wifi.png` | Toggles the native Wi-Fi connection (Optionally opens the available networks list). |
| "Night" | `icons/quick_nightmode.png` | Toggles Night Mode colors (e-ink screen inversion). |
| "Frontlight" | `icons/lightbulb.png` | Toggles the screen backlight completely On/Off. *(Discovered only on devices with Frontlight)* |
| "Rotation" | `icons/quick_rotate.png` | Enables/Disables the automatic screen rotation sensor. *(Discovered only on devices with G-Sensor / Accelerometer)* |
| "Rotate" | `icons/quick_rotate.png` | Manually rotates the screen in 90° cycles (IterateRotation). |
| "USB" | `icons/quick_usb.png` | Triggers the USB Mass Storage mode if supported by the hardware. |
| "Restart" | `icons/quick_restart.png` | Displays a confirmation dialog box to restart KOReader. |
| "Exit" | `icons/quick_exit.png` | Displays a confirmation dialog box to exit KOReader. |
| "Sleep" | `icons/quick_sleep.png` | Suspends or powers off the e-reader (depending on hardware support). |
| "Search" | `icons/quick_search.png` | Triggers the native KOReader file search event. |
| "Cloud" | `icons/quick_cloud.png` | Opens the native cloud storage manager. |
| "Z-Lib" | `icons/quick_zlib.png` | Opens the Z-Library plugin gateway. *(Requires the `zlibrary` plugin installed)* |
| "Search" | `icons/quick_search.png` | Opens the book search menu within the Calibre catalog. *(Requires the `calibre` plugin installed)* |
| "Calibre" | `icons/quick_calibre.png` | Starts or stops the wireless connection with the Calibre Companion server. *(Requires `calibre` plugin)* |
| "Streak" | `icons/quick_streak.png` | Displays the reading goals calendar from the Reading Streak plugin. *(Requires `readingstreak` plugin)* |
| "LocalSend" | `icons/quick_localsend.png` | Toggles the LocalSend server status by tracking background PID files. *(Requires `localsend` plugin)* |
| "Progress" | `icons/quick_stats_progress.png` | Direct shortcut to the current reading progress statistics and graphs. *(Requires `statistics` plugin)* |
| "Calendar" | `icons/quick_stats_calendar.png` | Direct shortcut to the reading history calendar view. *(Requires `statistics` plugin)* |
| "Battery" | `icons/quick_battery.png` | Displays advanced battery statistics and health cycles. *(Requires `batterystat` plugin)* |
| "QuickRSS" | `icons/quick_quickrss.png` | Opens the feed reader directly through native feed view UI modules. *(Requires `quickrss` plugin)* |
| "OPDS" | `icons/quick_opds.png` | Opens the external OPDS catalog catalog. *(Requires `opds` plugin)* |
| "Puzzle" | `icons/quick_puzzle.png` | Opens the integrated Slide Puzzle mini-game. *(Requires `slidepuzzle` plugin)* |
| "Crossword" | `icons/quick_crossword.png` | Triggers the built-in Crossword puzzle game menu. *(Requires `crossword` plugin)* |
| "Connections" | `icons/quick_connections.png` | Runs the main callback for the NYT Connections game interface. *(Requires `connections` plugin)* |
| "Chess" | `icons/quick_chess.png` | Starts the game loop for the native KOChess chess engine. *(Requires `chess` plugin)* |
| "Casual Chess" | `icons/quick_casualchess.png` | Starts the game loop for the Casual KOChess variant. *(Requires `casualkochess` plugin)* |
| "Sync" | `icons/quick_sync.png` | Forces a background sync of your book progress with the KOSync server. |
| "FileBrowser+" | `icons/quick_filebrowser.png` | Toggles the HTTP server and validates its status via background PID processes. *(Requires plugin)* |
---

## ⚙️ Configuration

Once installed, you can configure the plugin directly within KOReader:
1. Open the top menu in KOReader.
2. Navigate to the **Gear icon (Settings)** -> **Quick settings**.
3. From here, you can:
    * Enable or disable specific action buttons.
    * Tap **"Arrange buttons"** to change their sequence.
    * Toggle the visibility of the Brightness and Warmth sliders.
    * Toggle the option to **show or hide the list of available Wi-Fi networks** immediately upon turning Wi-Fi on.

---

## 🤝 Credits & Acknowledgments

This plugin would not be possible without the hard work of the original developers:
*   **AnthonyGress** for the beautiful [ZenUI slider engine](https://github.com/AnthonyGress/zen_ui.koplugin) implementation.
*   **qewer33** for the versatile [Quick Settings patch logic](https://github.com/qewer33/koreader-patches).
*   The **KOReader Development Team** for creating an amazingly extensible e-reading platform.
