<img width="1272" height="1696" alt="FileManager_2026-06-19_234143" src="https://github.com/user-attachments/assets/1baa2894-8979-476d-8259-3c4c80d94669" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234139" src="https://github.com/user-attachments/assets/b101bd9c-205d-465d-9f1e-c000b3867404" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234135" src="https://github.com/user-attachments/assets/d549f6a2-0cfb-4a2c-85f8-4cec79821236" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234100" src="https://github.com/user-attachments/assets/00744255-50a6-4184-b32c-17040c342b00" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234052" src="https://github.com/user-attachments/assets/8fac28d2-2a57-4082-88e6-82d49be4ff9d" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234046" src="https://github.com/user-attachments/assets/8aa7b64e-921a-423f-9ed8-50d58d289dc8" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234041" src="https://github.com/user-attachments/assets/9cf8bb3e-15d9-4f43-80a9-f7ed0599a8f0" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234037" src="https://github.com/user-attachments/assets/ef86573f-7149-4a3e-9161-7a2d927d6d50" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234018" src="https://github.com/user-attachments/assets/56b2ebe7-55cc-4a11-9670-f6aee1e78d31" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_234012" src="https://github.com/user-attachments/assets/3ea64702-c90d-4151-b432-799b8135adf9" />
<img width="1272" height="1696" alt="FileManager_2026-06-19_233942" src="https://github.com/user-attachments/assets/cd047d98-c90a-48ca-b8b6-59e44f1276fb" />
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
