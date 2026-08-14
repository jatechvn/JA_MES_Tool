# 🤖 JA MES Tool v2.5.2

<p align="center">
  <br>
  <i><b>A high-performance Windows desktop application developed in Dart & Flutter for automated Foxconn CloudMES test record, process history, and BOM traceability querying.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.5.2-blue.svg" alt="Version 2.5.2">
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

Designed for test engineers and QA teams, this tool provides instant parallel queries across three data views per SN, automated token credential synchronization via browser CDP, and an intuitive modern interface with Excel-style search & sort.

---

<a id="features"></a>
## 💡 Key Features (v2.5.2)

### 📊 Data Views
- 🗂️ **Three Views per SN**: Switch between **Test Record** (pass/fail results), **Barcode History** (full process/station routing), and **Component List** (WIP BOM / material traceability — manufacturer, part no, date code, package/lot ID) for every queried SN.
- 🔗 **Automatic SN Master Resolution**: Typing an internal/alias SN auto-resolves it to the canonical product SN (`snMaster/getSnMasterProcess`) before fetching any of the 3 views — the header shows `typed SN → resolved SN` whenever they differ, cached per-session with automatic fallback if resolution fails.
- 🔍 **Excel-style Search Filter**: A live search box on every record list matches against any visible field as you type.
- ⬍ **Click-to-sort**: A sort-by button lets you pick a field and toggle ascending/descending, on all three views.
- 📋 **Selectable & Copyable Data**: Every record value — including the SN queue sidebar — can be selected with a click-drag or double-click and copied (Ctrl+C), just like a spreadsheet.
- 🔄 **Per-SN & Refresh-All**: Each SN in the queue has its own refresh icon to re-fetch just that SN (all 3 views + its SN Master resolution), plus a "Refresh All" button in the sidebar header to re-fetch the entire queue — no more closing and reopening the app to force fresh data.
- 🔢 **Smart Record Counts**: "Records for SN" shows a `(N)` count automatically, hidden when there are 0 or 1 records.

### 🎨 Interface
- ✨ **iOS-style Smooth Transitions**: Fade+slide animation when switching tabs or SN, cascading fade/slide-in entrance for record lists with bouncing scroll, scale+fade dialog presentation, animated sidebar selection & record-count badge, and crossfaded Light/Dark theme switching — all driven by a shared timing/easing spec (`lib/modules/ui/motion.dart`).
- 🏝️ **Dynamic-Island Hover Toolbar**: The 3 view tabs and the Template/Import/Export/Language/Theme actions collapse into compact icon chips, expanding to full labels on hover — keeps the toolbar from overflowing. When the window is maximized, every chip stays fully expanded.
- 🎨 **Glassmorphic Multi-Language UI**: Light & Dark themes with multi-language switching (**English**, **Vietnamese**, **Chinese**).

### 🔐 Credentials & Connectivity
- ⚡ **Automatic Startup Expired Token Warning Popup**: Detects expired token on app launch and immediately opens a 2-step sync prompt to refresh credentials.
- 🌐 **Chrome & Microsoft Edge Multi-Browser Support**: Isolated process flags (`--disable-features=msEdgeStartupBoost...`, `--no-service-autorun`) preventing Edge login window freezes.
- 🌐 **CDP Network Interception (Auto Credentials)**: Captures 100% accurate **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from live browser traffic via CDP.
- 🛡️ **Verified Connection Badge Icon**: Sleek badge icon (`Icons.verified_outlined`) in Settings footer for testing connection validity.
- 🔄 **Auto-Refetch SN Queue on Save**: Saving settings automatically clears old 401 errors and re-queries all SNs in queue.
- 🔒 **No Hardcoded Credentials**: Token/cookie are never baked into the source — they're supplied per-user via Settings and persisted only to the local, gitignored `config.json`.

### ⚙️ Core & Data Management
- ⚡ **Parallel SN Query Queue**: Process individual or batch Serial Numbers with asynchronous API fetch, across all three data views.
- 📄 **Smart CSV Batch Import & Export**: Automatically filters out header/title rows (e.g., rows containing `"SN"`) and generates structured CSV exports.
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

### 1. Adding Serial Numbers
* **Single SN**: Type the SN into the left sidebar input box and press **Enter** or click **[+]**.
* **Batch Import**: Click **[Template]** to save a sample CSV. Fill in your SNs, then click **[Import]**. Title rows containing `"SN"` are automatically skipped.

### 2. Browsing the Three Data Views
* Hover the icon toolbar near **"Result Details"** to reveal its label, or just click it — no need to hover first:
  - 📋 **Test Record**: pass/fail test results per station.
  - 🔳 **Barcode History**: full process/station routing history for the SN.
  - 🧩 **Component List**: WIP BOM / material traceability (manufacturer, part no, date code, package/lot ID).
* Use the **search box** on any list to filter by any field, and the **[Sort]** button to pick a field and toggle ascending/descending.
* Click-drag or double-click any value to select it, then **Ctrl+C** to copy — just like a spreadsheet.
* Click **[Export]** to save all fetched Test Record data to a structured CSV file.

### 3. Auto Sync Token from Browser (2-Step CDP Wizard)
1. Open **Settings ⚙️** (or use the automatic startup expired token popup).
2. **Step 1**: Click **[1. Open Browser]** to launch Chrome or Microsoft Edge.
3. Log into your MES account on the web page.
4. **Step 2**: Click **[2. Sync Credentials]**. The app captures live **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from browser traffic.
5. Click **Save** to automatically clear prior error screens and re-fetch the entire SN queue.

### 4. Connection Health Check
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
│   └── modules/
│       ├── api_client.dart        # MES API Client: TestRecord, SnProcessRecord & WipComponentRecord
│       ├── browser_helper.dart    # CDP Interception & Edge/Chrome Automation
│       ├── config_service.dart    # Local config.json load/save (no hardcoded credentials)
│       ├── constants.dart         # Global app constants & defaults (v2.5.2)
│       ├── logger_service.dart    # Daily file logger & 7-day auto cleanup
│       ├── logic.dart             # App state: SN queue, 3 record maps, ViewMode, SN Master resolve cache
│       ├── translations.dart      # Multi-language dictionary (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # Tabs, filter/sort, hover chips, dialogs (WindowListener)
│           ├── motion.dart        # Shared iOS-style animation Duration/Curve spec
│           ├── styles.dart        # Theme dispatcher (dark/light tokens)
│           ├── styles_win10.dart  # Windows 10 translucent theme tokens
│           └── styles_win11.dart  # Windows 11 acrylic theme tokens
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
├── pubspec.yaml                   # Flutter package manifest (v2.5.2+5)
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
  "lang": "en",
  "operationId": "1826874274766209025",
  "uuid": "e1d5e78c-bf60-4aba-9b5f-a94b15cb63d4",
  "cookie": ""
}
```

`config.json` and the `logs/` folder are excluded from Git via `.gitignore` — never commit either.

---

<a id="changelog"></a>
## 📜 Changelog Recap

- **[2.5.2]** — Selectable & copyable SN queue sidebar; per-SN and Refresh-All buttons to re-fetch data on demand without restarting the app.
- **[2.5.1]** — Fixed stagger list-entrance animation replaying on scroll; Barcode History & Component List tabs now preload concurrently with Test Record instead of loading lazily on tab switch.
- **[2.5.0]** — Renamed to "JA MES Tool", automatic SN Master resolution (internal → canonical SN), full iOS-style smooth UI transition pass.

See [**CHANGELOG.md**](CHANGELOG.md) for the full version history.

---

## 📜 License

Proprietary Software. Developed for Foxconn CABG_VN production environment. All rights reserved.
