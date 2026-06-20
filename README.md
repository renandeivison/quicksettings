# 7 buttons active

<img width="400" alt="FileManager_2026-06-19_233942" src="https://github.com/user-attachments/assets/6b5f8aaf-4d37-439d-91ad-71b387d89b64" />

# All the buttons active

<img width="400" alt="FileManager_2026-06-19_234143" src="https://github.com/user-attachments/assets/e79b715b-a2b6-47b3-8a13-8e53601d3a50" />

# Quick Settings Plugin for KOReader

A native, clean, and highly customizable **Quick Settings Panel** for KOReader. This plugin combines a beautiful slider interface with an accessible control toggle panel.

This project is a hybrid merge of two excellent community resources, compiled and optimized using AI assistance:
*   **ZenUI Sliders:** Derived from [AnthonyGress/zen_ui.koplugin](https://github.com/AnthonyGress/zen_ui.koplugin).
*   **Quick Settings Logic:** Derived from the `2-quick-settings.lua` patch found in [qewer33/koreader-patches](https://github.com/qewer33/koreader-patches).

---

## Disclaimer & Purpose

> **Note:** This plugin was originally put together purely for my **personal use** to streamline my own e-reader workflow. It is being shared publicly here because members of the community asked for it. 
> 
> As a personal project maintained in my spare time, it is provided "as-is." While you are more than welcome to use, fork, or modify it, please keep in mind that official support or frequent updates are not guaranteed.

---

## Features

*   **Integrated Panel:** Combines your main navigation bar, quick toggle buttons, and frontlight sliders into a single unified menu view.
*   **ZenUI Sliders:** Upgrades the native KOReader frontlight/warmth bars with smooth, gesture-friendly pill-and-circle sliders.
*   **Dynamic Grid Layout:** Displays a perfectly proportioned single row when you select up to 7 buttons. If you enable more than 7 items, the plugin automatically adds new rows to accommodate your selection cleanly.
*   **Extensive App Toggles:** Easy access to Wi-Fi, Night Mode, Rotation, USB Mass Storage, Restart/Exit, Search, and popular plugins like Z-Library, Calibre, Reading Streak, LocalSend, and File Browser.
*   **Native Customization Menu:** Injects seamlessly into KOReader's native settings menu (`Settings -> Quick settings`), allowing you to toggle slider visibility, enforce opening defaults, and reorder your button layout via a drag-and-drop sort widget.

---

## Installation

1.  **Download the plugin:** Copy the `main.lua` file from this repository.
2.  **Access your device directory:** Connect your e-reader to your computer via USB, or use an SSH/SFTP connection.
3.  **Navigate to the plugins folder:** Go to the KOReader internal directory:

    koreader/plugins/

4.  **Create a plugin folder:** Create a new folder named `quicksettings.koplugin`:

    koreader/plugins/quicksettings.koplugin/

5.  **Place the file:** Paste the `main.lua` file inside that folder.

> **IMPORTANT TAB ICON NOTE:** 
> * **If you are already using ZenUI:** The plugin tab icon will automatically be pulled from ZenUI. No extra steps are required.
> * **If you are NOT using ZenUI:** You **must** manually place an icon file named `quicksettings.svg` or `quicksettings.png` into your KOReader icons directory (`koreader/icons/`). Otherwise, the main menu tab icon will not display correctly.

6.  **Restart KOReader:** Safely eject your device or restart the KOReader software.

---

## Icons Reference & Customization

If any specific button icon does not show up on your interface, it means your current KOReader setup or theme is missing that asset. 

Because **KOReader supports both `.svg` and `.png` image extensions**, you can fix this manually by adding the files to your `koreader/icons/` directory. **You can also use this to completely customize the interface with your own custom icons!** Simply create or download your preferred design, rename it to match the exact base name below, and drop it in the folder:

| Feature / Button | Required Asset Filename (Use `.svg` or `.png`) |
| :--- | :--- |
| **Wi-Fi** | `quick_wifi` |
| **Night Mode** | `quick_nightmode` |
| **Rotate** | `quick_rotate` |
| **USB** | `quick_usb` |
| **Restart** | `quick_restart` |
| **Exit** | `quick_exit` |
| **Sleep** | `quick_sleep` |
| **Search** | `quick_search` |
| **Cloud** | `quick_cloud` |
| **Z-Library** | `quick_zlib` |
| **Calibre Search** | `quick_search` |
| **Calibre** | `quick_calibre` |
| **Streak** | `quick_streak` |
| **LocalSend** | `quick_localsend` |
| **File Browser** | `quick_filebrowser` |
| **Reading Progress** | `quick_stats_progress` |
| **Reading Calendar** | `quick_stats_calendar` |
| **Battery Stats** | `quick_battery` |

---

## Configuration

Once installed, you can configure the plugin directly within KOReader:
1. Open the top menu in KOReader.
2. Navigate to the **Gear icon (Settings)** -> **Quick settings**.
3. From here, you can:
    * Enable or disable specific action buttons.
    * Tap **"Arrange buttons"** to change their sequence.
    * Toggle the visibility of the Brightness and Warmth sliders.
    * Toggle the option to **show or hide the list of available Wi-Fi networks** immediately upon turning Wi-Fi on.

---

## Credits & Acknowledgments

This plugin would not be possible without the hard work of the original developers:
*   **AnthonyGress** for the beautiful [ZenUI slider engine](https://github.com/AnthonyGress/zen_ui.koplugin) implementation.
*   **qewer33** for the versatile [Quick Settings patch logic](https://github.com/qewer33/koreader-patches).
*   The **KOReader Development Team** for creating an amazingly extensible e-reading platform.
