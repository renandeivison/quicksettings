# 7 buttons activated

<img width="400" alt="FileManager_2026-06-19_233942" src="https://github.com/user-attachments/assets/6b5f8aaf-4d37-439d-91ad-71b387d89b64" />

# All buttons activated

<img width="400" alt="FileManager_2026-06-28_155701" src="https://github.com/user-attachments/assets/4aadc180-6794-4eec-9665-57eecac6bfc2" />

# Quick Settings Plugin for KOReader

A highly customizable, modular, and fast touch-based Quick Settings panel for KOReader. This plugin adds an intuitive mobile-like toggle dashboard to your e-reader's top menu bar, making it incredibly easy to switch profiles, control radios, launch plugins, and tweak your display on the fly.

***

### Key Features

* **Global Asset System:** All button icons have been moved back to the main `koreader/icons/` directory. The release pack already includes the required assets—simply place them into your system's root icons folder for clean system-wide integration.
* **Hardware-Adaptive Controls:** Includes intelligent toggles for **Frontlight Backlight** and **G-Sensor Auto-Rotation** that dynamically evaluate your device hardware capability—they will *only* display if your e-reader physically supports those components.
* **Dynamic Multifile Layout:** Buttons seamlessly arrange themselves side-by-side up to **7 items per row**. Once that structural limit is hit, the plugin automatically breaks into a clean new row. You don't have to keep all toggles active at once unless you want to!
* **Focus Mode Integration:** Hide distracting top menu bar tabs completely. Tap the **Focus Mode** button to pull up a checklist, choose which native KOReader tabs to hide (e.g., Typesetting, Tools, Navigation), and read completely distraction-free.
* **Extensive Plugin Support:** Acts as a centralized launcher interface for external tools. Natively supports tracking, running, or mapping state indicators for:
    * **FileBrowser+** (validates background PID status)
    * **BookFusion** (smart gateway based on active login state)
    * **LocalSend** (tracks active file transfer background servers)
    * **Calibre Companion & Search**
    * Reading Streak calendars, Advanced Battery Statistics, KOReader Progress History, Chess, Crosswords, NYT Connections, and OPDS Catalogs.
* **Fully Tested:** Performance and render pipelines are fully optimized for electronic paper displays, specifically benchmarked on the **Kindle Paperwhite 11/12 Signature Edition**.

---

### Custom Icon & Asset Guide

You can fully customize the interface by replacing the pre-packed images with your preferred graphics. Make sure to keep the exact filename matching the display mappings inside your `/koreader/icons/` folder:

| Display Name (Label) | Icon Filename | Behavior / Hardware or Plugin Dependency |
| :--- | :--- | :--- |
| "Wi-Fi" | `quick_wifi.png` | Toggles native Wi-Fi connection and manages network scans safely. |
| "Night" | `quick_nightmode.png` | Inverts screen colors (e-ink native inversion). |
| "Frontlight" | `lightbulb.png` | Blinks/Toggles the backlight completely on or off. *(Hardware Dependent)* |
| "Rotation" | `quick_rotate.png` | Enables/Disables the background G-Sensor accelerometer. *(Hardware Dependent)* |
| "Rotate" | `quick_rotate.png` | Manually steps the active frame buffer screen in 90° cycles. |
| "Focus Mode" | `quick_focus.png` | Opens configuration panel to isolate or hide top menu bars. |
| "USB" | `quick_usb.png` | Invokes the native USB Mass Storage mode mounting window. |
| "Restart" | `quick_restart.png` | Prompts an overlay confirmation prompt to restart KOReader safely. |
| "Exit" | `quick_exit.png` | Prompts an overlay confirmation prompt to shut down KOReader. |
| "Sleep" | `quick_sleep.png` | Drops the hardware into suspend or power-off mode. |
| "Search" | `quick_search.png` | Launches the default KOReader global file crawler. |
| "Cloud" | `quick_cloud.png` | Enters the built-in cloud-storage profile manager. |
| "Z-Lib" | `quick_zlib.png` | Launches the Z-Library gateway. *(Requires `zlibrary` plugin)* |
| "BookFusion" | `quick_bookfusion.png` | Performs lookup or device link protocols. *(Requires `bookfusion` plugin)* |
| "Calibre" | `quick_calibre.png` | Opens background sockets with the Calibre Companion server. *(Requires `calibre`)* |
| "Streak" | `quick_streak.png` | Draws daily reading tracking milestones. *(Requires `readingstreak` plugin)* |
| "LocalSend" | `quick_localsend.png` | Initializes or kills background LocalSend server processes. *(Requires `localsend`)* |
| "Progress" / "Calendar" | `quick_stats_...` | Shortcuts to reader progress tracking modules. *(Requires `statistics` plugin)* |
| "Battery" | `quick_battery.png` | Opens advanced runtime statistics modules. *(Requires `batterystat` plugin)* |
| "FileBrowser+" | `quick_filebrowser.png` | Activates background HTTP server bindings via PID checks. *(Requires plugin)* |

---

### Installation Note

To install the plugin correctly, manually place the extracted files into the following specific directories on your device:

1. **Icons:** Copy all image assets (such as `.png` or `.svg` files) into the root global directory:
    ```path
    koreader/icons/
    ```
2. **Plugin Files:** Copy `main.lua` and the remaining script structure into the dedicated plugin folder:
    ```path
    koreader/plugins/quicksettings.koplugin/
    ```

Restart KOReader after placing the files to load the new settings dashboard interface cleanly.

### Special Appreciation & Credits
I want to express my deep, sincere gratitude once again to **[@AnthonyGress](https://github.com/AnthonyGress)** and **[@qewer33](https://github.com/qewer33)**. A massive portion of this plugin's underlying layout handling, tracking logic, and interface engine was derived directly from their incredible work and foundational open-source contributions to the KOReader development community.
