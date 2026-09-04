# 🤖 JA MES Tool v2.9.3

<p align="center">
  <br>
  <i><b>A high-performance Windows desktop application developed in Dart & Flutter for automated Foxconn CloudMES test record, process history, and BOM traceability querying with Bento Glassmorphism UI.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.9.3-blue.svg" alt="Version 2.9.3">
  <img src="https://img.shields.io/badge/platform-Windows%20x64-0078D6.svg" alt="Platform Windows">
  <img src="https://img.shields.io/badge/flutter-3.x-02569B.svg" alt="Flutter 3.x">
  <img src="https://img.shields.io/badge/license-Proprietary-red.svg" alt="License">
</p>

<p align="center">
  <a href="#introduction">🚀 Introduction</a> • 
  <a href="#features">💡 Key Features</a> • 
  <a href="#screenshots">📸 Screenshots</a> • 
  <a href="#usage">🖥️ User Guide</a> • 
  <a href="#architecture">🏗️ Architecture</a> • 
  <a href="#setup">📖 Quick Start</a> • 
  <a href="#configuration">⚙️ Configuration</a> • 
  <a href="#changelog">📜 Changelog</a> • 
  <a href="https://jatechvn.github.io/">🌐 Website</a>
</p>

<p align="center">
  🇺🇸 English • 
  <a href="i18n/README.vi.md">🇻🇳 Tiếng Việt</a> • 
  <a href="i18n/README.zh-CN.md">🇨🇳 中文</a>
</p>

---

<a id="introduction"></a>
## 🌟 Introduction

**JA MES Tool** is a specialized desktop application engineered to streamline serial number (SN) verification, test/process history extraction, BOM component traceability, and result reporting from the **Foxconn CloudMES** API platform.

Designed for test engineers and QA teams, this tool provides instant parallel queries across three data views per SN plus a fourth reverse component-lookup view (Component Trace), a Ctrl+K command palette for jumping to any tab/action/setting, automated token credential synchronization via browser CDP, and an intuitive modern interface with Bento Glassmorphism, Liquid Glass, Dynamic Island status capsule, and Excel-style search & sort.

---

<a id="features"></a>
## 💡 Key Features (v2.9.3)

### 🎨 Bento Glassmorphism Interface
- ⚡ **Command Palette (Ctrl+K / Cmd+K)**: Spotlight-style search overlay listing every tab, action, and setting — type to filter by name or keyword, navigate with ↑/↓, and run with Enter or a click. It now follows the Dialog blur/opacity settings and delays focus slightly to avoid Windows IME underline artifacts.
- 🌟 **Bento Grid & Liquid Glass Architecture**: Modern floating Bento cards with 1px top reflective highlight edges, 20-24px BackdropFilter blur, and GPU-composited drifting Mesh Orbs.
- 🎛️ **Live-Preview 4-Slider Glassmorphism Tuning**: Interactive sliders in Settings (Card Blur, Card Opacity, Dialog Blur, Dialog Opacity) with instant real-time live preview across all UI surfaces, Default reset, and Cancel rollback.
- 🌓 **1-Click Direct Theme Switcher**: Instant toggle between Light and Dark mode on every click.
- ⏱️ **Automatic Build Timestamping**: Automatically extracts accurate compilation date/time from `data/app.so` or executable, displayed in Header and About tabs.
- ✨ **iOS-style Smooth Transitions**: Fade+slide animation when switching tabs or SN, cascading fade/slide-in entrance for record lists with bouncing scroll, scale+fade dialog presentation, and animated badges.
- 🏝️ **Dynamic-Island Status Capsule**: Live MES connection status wave and quick actions toolbar.
- 🪟 **Adjustable Glassmorphism**: Settings → Advanced has a "Customize blur & transparency" panel with 4 live-preview sliders (Main background blur/opacity, Dialog blur/opacity). The Sort dropdown and the Settings dialog itself both re-blur in real time as you drag — with a built-in legibility floor that prevents the see-through overlapping-text glitch regardless of how low opacity is set.
- 🎨 **Glassmorphic Multi-Language UI**: Light & Dark themes with multi-language switching (**English**, **Vietnamese**, **Chinese**). On first launch, the default language follows the Windows locale when no saved language exists.

### 🔐 Credentials & Connectivity
- ⚡ **Automatic Startup Expired Token Warning Popup**: Detects expired token on app launch and immediately opens a 2-step sync prompt to refresh credentials.
- 🌐 **Chrome & Microsoft Edge Multi-Browser Support**: Isolated process flags (`--disable-features=msEdgeStartupBoost...`, `--no-service-autorun`) preventing Edge login window freezes.
- 💾 **Persistent Browser Profiles**: Chrome and Edge use separate app-owned profiles, preserving saved sessions, passwords, and bookmarks across restarts while avoiding profile conflicts.
- 🌐 **CDP Network Interception (Auto Credentials)**: Captures 100% accurate **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from live browser traffic via CDP.
- 🛡️ **Verified Connection Badge Icon**: Sleek badge icon (`Icons.verified_outlined`) in Settings footer for testing connection validity.
- 🔄 **Refresh-All Cache Reset**: Refresh All clears cached canonical SN and SN Master metadata before re-querying the queue, preventing stale resolved SN or Next-process information.
- 🧭 **Route Badge**: The records header shows the SN Master route name, falling back to the route code when needed, and stays hidden when route data is unavailable.
- 🔁 **Smart Empty Test Record Fallback**: If Test Record returns no rows after first app load, a newly entered/searched SN, or a refresh while Test Record is active, the app automatically opens Barcode History. Manual tab selection and cached SN selection stay respected.
- 🔒 **No Hardcoded Credentials**: Token/cookie are never baked into the source — they're supplied per-user via Settings and persisted only to the local, gitignored `config.json`.

### ⚙️ Core & Data Management
- ⚡ **Parallel SN Query Queue**: Process individual or batch Serial Numbers with asynchronous API fetch, across all three data views.
- 📄 **Smart CSV Batch Import & Export**: Automatically filters out header/title rows (e.g., rows containing `"SN"`/`"CSN"`) and generates structured CSV exports — the **[Template]**/**[Import]**/**[Export]** toolbar buttons switch to CSN-shaped Component Trace templates/exports automatically while that tab is active.
- 🛠️ **Header Sanitization Engine**: Cleans invisible Carriage Returns (`\r\n`), extra whitespaces, and quote wrappers to prevent HTTP header errors.
- 📋 **Daily System Logs**: Logs operational events with automatic 7-day file cleanup.

---

<a id="screenshots"></a>
## 📸 Application Screenshots

<p align="center">
  <img src="docs/screenshots/2026-08-11_133916.jpg" alt="Test Record view with search filter, sort button, and record count" width="850">
  <br><i>Test Record view — search, sort, and record count on the same row</i>
  <br><br>
  <img src="docs/screenshots/2026-08-11_134048.jpg" alt="Component List view showing WIP BOM component traceability" width="850">
  <br><i>Component List view — WIP BOM / material traceability per SN</i>
  <br><br>
  <img src="docs/screenshots/2026-07-26_231301.png" alt="JA MES Tool Settings with Verified Badge Icon & 2-Step Sync Card" width="850">
  <br><i>Settings — 2-step CDP credential sync wizard</i>
  <br><br>
  <img src="docs/screenshots/2026-07-26_231317.png" alt="JA MES Tool Automatic Startup Expired Token Warning Popup" width="850">
  <br><i>Automatic startup expired-token warning popup</i>
</p>

---

<a id="usage"></a>
## 🖥️ User Guide

### 1. Command Palette (Ctrl+K / Cmd+K)
* Press **Ctrl+K** (or **Cmd+K** on macOS keyboards) anywhere in the app to open a spotlight-style search over every tab, action, and setting.
* Type to filter by name or keyword, use **↑/↓** to highlight a result, and press **Enter** or click to run it. Press **Esc** or click outside to close.

### 2. Adding Serial Numbers
* **Single SN**: Type the SN into the left sidebar input box and press **Enter** or click **[+]**.
* **Batch Import**: Click **[Template]** to save a sample CSV. Fill in your SNs, then click **[Import]**. Title rows containing `"SN"` are automatically skipped.

### 3. Browsing the Three Data Views
* Hover the icon toolbar near **"Result Details"** to reveal its label, or just click it — no need to hover first:
  - 📋 **Test Record**: pass/fail test results per station.
  - 🔳 **Barcode History**: full process/station routing history for the SN.
  - 🧩 **Component List**: WIP BOM / material traceability (manufacturer, part no, date code, package/lot ID).
* Use the **search box** on any list to filter by any field, and the **[Sort]** button to pick a field and toggle ascending/descending.
* Click-drag or double-click any value to select it, then **Ctrl+C** to copy — just like a spreadsheet.
* Click **[Export]** to save all fetched Test Record data to a structured CSV file.
* When SN Master data includes route information, the records header shows a **Route** badge alongside the **Next** process chip.
* If Test Record has no rows after a first-load fetch, a newly searched SN, or a refresh while Test Record is active, the app automatically switches to **Barcode History**. Simply clicking back to Test Record or selecting a cached SN will not auto-switch away.

### 4. Component Trace (reverse component lookup)
* Click the **🧭 Component Trace** tab — the sidebar switches from the SN queue to a **Trace History** list, and the same input box now searches component CSNs instead of adding SNs.
* Type or scan a component's CSN and press **Enter** (or **[+]/🔍**) — paste multiple CSNs at once (one per line, or comma-separated) to search them all in one go.
* Each searched CSN becomes a row in the Trace History sidebar (click to revisit a cached result, 🔄 to re-run it, ✕ to remove it) and is **saved to disk**, so the history survives closing and reopening the app.
* The result panel shows every product SN the CSN is currently installed into, with the same **search/sort** toolbar as the other 3 views.
* **[Template]/[Import]/[Export]** automatically operate on CSNs instead of SNs while this tab is active.

### 5. Auto Sync Token from Browser (2-Step CDP Wizard)
1. Open **Settings ⚙️** (or use the automatic startup expired token popup).
2. **Step 1**: Click **[1. Open Browser]** to launch Chrome or Microsoft Edge.
3. Log into your MES account on the web page.
4. **Step 2**: Click **[2. Sync Credentials]**. The app captures live **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from browser traffic.
5. Click **Save** to automatically clear prior error screens and re-fetch the entire SN queue (and the Component Trace history, if any). Use **[Refresh All]** when you want to invalidate cached SN Master resolution data before a fresh queue fetch.

### 6. Connection Health Check
* The status indicator near **"Settings"** title shows:
  - 🟢 **Connected**: Token valid and server reachable.
  - 🟡 **Check Status**: Token expired or unauthorized (401).
* Token validity is automatically checked every **3 minutes**.
* Click the **Verified Badge icon (🛡️)** in Settings to manually test connection.

---

<a id="architecture"></a>
## 🏗️ Project Directory Structure

```text
ja_mes_tool/
├── lib/
│   ├── main.dart                  # App entry point, Provider setup & window_manager init
│   ├── modules/
│   │   ├── api_client.dart        # MES API Client: TestRecord, SnProcessRecord, WipComponentRecord & QueryInfoRecord
│   │   ├── browser_helper.dart    # CDP Interception & Edge/Chrome Automation
│   │   ├── build_info.dart        # Reads real compile timestamp from data/app.so or the executable
│   │   ├── config_service.dart    # Local config.json load/save (no hardcoded credentials)
│   │   ├── constants.dart         # Global app constants & defaults (v2.9.3)
│   │   ├── logger_service.dart    # Daily file logger & 7-day auto cleanup
│   │   ├── logic.dart             # App state: SN queue, Trace history, 4 record maps, ViewMode, SN Master resolve cache
│   │   ├── translations.dart      # Multi-language dictionary (EN, VN, CN)
│   │   └── ui/
│   │       ├── main_window.dart   # Tabs, filter/sort, dialogs, Command Palette wiring (WindowListener)
│   │       ├── motion.dart        # Shared iOS-style animation Duration/Curve spec
│   │       ├── styles.dart        # Re-exports lib/theme/* (kept for backward-compatible imports)
│   │       ├── styles_win10.dart  # Legacy Win10 theme tokens, superseded by lib/theme/styles_win10.dart
│   │       └── styles_win11.dart  # Legacy Win11 theme tokens, superseded by lib/theme/styles_win11.dart
│   ├── theme/                     # Bento Glassmorphism theming system
│   │   ├── app_colors.dart        # AppColors token set (per-theme color palette)
│   │   ├── styles_win10.dart      # Windows 10 (Aero) glass color/opacity tuning
│   │   ├── styles_win11.dart      # Windows 11 (Acrylic/Mica) glass color/opacity tuning
│   │   └── theme_provider.dart    # ThemeProvider: light/dark/system mode, OS brightness observer
│   └── widgets/                   # Reusable glass UI components
│       ├── app_toast.dart         # Transient glass toast notification overlay
│       ├── command_palette.dart   # Ctrl+K / Cmd+K spotlight command search
│       ├── filter_search_dock.dart# Search field + filter pills dock (glass-styled)
│       ├── glass_dialog.dart      # Frosted-glass modal dialog shell
│       └── glass_widgets.dart     # BentoCard, MeshBackground, SlidingPillTabBar, KbdTag, etc.
│
├── windows/
│   └── runner/                    # Native Win32 runner (mostly Flutter-generated boilerplate)
│       ├── win32_window.cpp       # Window creation; detects OS dark-mode & routes to theme_win10/win11
│       ├── theme_win10.cpp        # Acrylic blur-behind via undocumented SetWindowCompositionAttribute
│       ├── theme_win11.cpp        # Native Mica/Acrylic backdrop via DWMWA_SYSTEMBACKDROP_TYPE
│       └── resources/app_icon.ico # App icon (taskbar & title bar)
│
├── docs/
│   └── screenshots/                # UI Screenshots (tracked by Git)
│       ├── 2026-08-11_133916.jpg   # Test Record view — filter/sort/count
│       ├── 2026-08-11_134048.jpg   # Component List view — BOM traceability
│       ├── 2026-07-26_231301.png   # Settings with Verified Badge Icon
│       └── 2026-07-26_231317.png   # Automatic Startup Expired Token Warning Popup
├── i18n/
│   ├── README.vi.md               # Vietnamese documentation
│   └── README.zh-CN.md            # Chinese documentation
├── pubspec.yaml                   # Flutter package manifest (v2.9.3+17)
├── ABOUT.txt                      # Project summary card
├── CHANGELOG.md                   # Cumulative version history
└── LICENSE                        # License file
```

---

<a id="setup"></a>
## 📖 Installation & Build Guide

### Prerequisites
* **Windows 10 / 11**
* **Flutter SDK 3.x** & **Dart 3.12+**
* **Google Chrome** or **Microsoft Edge** browser installed.

### How to Run Locally
```cmd
flutter pub get
flutter run -d windows
```

### How to Build Executable (.exe)
```cmd
flutter build windows
```
The compiled executable will be created at:
`build\windows\x64\runner\Release\ja_mes_tool.exe`

---

<a id="configuration"></a>
## ⚙️ Configuration & Settings

All credentials are entered per-user via the in-app **Settings ⚙️** dialog (paste raw header, browser CDP sync, or manual entry) — **nothing is hardcoded in source**. They're persisted locally next to the executable in a gitignored `config.json`:

```json
{
  "token": "",
  "sns": ["SN123456", "SN789012"],
  "traceCsns": ["OPM1106349G1CCX", "QB940AE002627V05171"],
  "lang": "en",
  "operationId": "1826874274766209025",
  "uuid": "e1d5e78c-bf60-4aba-9b5f-a94b15cb63d4",
  "cookie": ""
}
```

On a first launch without a saved `"lang"` value, the app derives the default language from Windows locale: Vietnamese locales use `vi`, Chinese locales use `cn`, and all other locales use `en`.

`config.json` and the `logs/` folder are excluded from Git via `.gitignore` — never commit either.

---

<a id="changelog"></a>
## 📜 Changelog Recap

- **[2.9.3]** — Added guarded Test Record empty-data fallback to Barcode History, Windows-locale first-run language defaults, and Command Palette dialog-glass/focus polish.
- **[2.9.2]** — Added a conditional **Route** badge to the records header, preferring the SN Master route name and falling back to the route code when necessary.
- **[2.9.1]** — Refresh All now clears cached canonical SN and SN Master metadata before re-querying, so changed SN mappings and Next-process information cannot remain stale.
- **[2.9.0]** — New **Command Palette** (Ctrl+K / Cmd+K): a spotlight-style search overlay listing every tab, action, and setting, with keyword filtering and arrow-key navigation, plus a glass toast notification system. Also fixes a `FocusNode` leak in the palette and removes a `fontFamily` reference to an unbundled font.
- **[2.8.0]** — **Bento Glassmorphism & Liquid Glass Engine**: Complete modern visual upgrade with floating Bento cards, GPU-accelerated drifting mesh orbs, live 4-slider glass tuning (Card Blur/Opacity, Dialog Blur/Opacity with live preview & cancel rollback), 1-click Light/Dark theme switch, and accurate auto-detected build timestamping. Also fixes first-run glassmorphism defaults not matching the Settings "Default" button, a dialog crash risk when closing mid credential-sync, and the theme not following live OS light/dark changes.
- **[2.7.0]** — New **Component Trace** view: reverse-lookup a component's own CSN to the product SN it's installed into, with its own persisted sidebar history, search/sort, and CSV template/import/export — sharing the SN queue's add/search input box instead of adding a second one.
- **[2.6.4]** — SN Master resolution now captures its full API response (next process, error code, route, line code); a "Next" chip surfaces the next process on the records header, whose SN label now auto-scrolls instead of truncating when space is tight.
- **[2.6.3]** — Chrome and Edge now use persistent, browser-specific profiles with legacy-profile migration and bounded CDP readiness checks to prevent login hangs.
- **[2.6.2]** — Settings reorganized into Advanced Settings, User Guide, and About tabs; the dialog now adapts its height to the selected tab.

See [**CHANGELOG.md**](CHANGELOG.md) for the full version history.

---

## 📜 License

Proprietary Software. Developed for Foxconn CABG_VN production environment. All rights reserved.
