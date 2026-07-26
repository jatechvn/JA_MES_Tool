# 🤖 JA MES Test Record Tool v2.3.0

<p align="center">
  <br>
  <i><b>A high-performance Windows desktop application developed in Dart & Flutter for automated Foxconn CloudMES test record querying and data management.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.3.0-blue.svg" alt="Version 2.3.0">
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

**JA MES Test Record Tool** is a specialized desktop application engineered to streamline serial number (SN) verification, test station history extraction, and result reporting from the **Foxconn CloudMES** API platform.

Designed for test engineers and QA teams, this tool provides instant parallel queries, automated token credential synchronization via browser CDP, and an intuitive modern interface.

---

<a id="features"></a>
## 💡 Key Features (v2.3.0)

- ⚡ **Automatic Startup Expired Token Warning Popup**: Detects expired token on app launch and immediately opens a 2-step sync prompt to refresh credentials.
- 🌐 **Chrome & Microsoft Edge Multi-Browser Support**: Isolated process flags (`--disable-features=msEdgeStartupBoost...`, `--no-service-autorun`) preventing Edge login window freezes.
- 🛡️ **Verified Connection Badge Icon**: Sleek badge icon (`Icons.verified_outlined`) in Settings footer for testing connection validity.
- 🔄 **Auto-Refetch SN Queue on Save**: Saving settings automatically clears old 401 errors and re-queries all SNs in queue.
- ⚡ **Parallel SN Query Queue**: Process individual or batch Serial Numbers with asynchronous API fetch.
- 📄 **Smart CSV Batch Import & Export**: Automatically filters out header/title rows (e.g., rows containing `"SN"`) and generates structured CSV exports.
- 🌐 **CDP Network Interception (Auto Credentials)**: Captures 100% accurate **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from live browser traffic via CDP.
- 🛠️ **Header Sanitization Engine**: Cleans invisible Carriage Returns (`\r\n`), extra whitespaces, and quote wrappers to prevent HTTP header errors.
- 📋 **Daily System Logs**: Logs operational events with automatic 7-day file cleanup.
- 🎨 **Glassmorphic Multi-Language UI**: Light & Dark themes with multi-language switching (**English**, **Vietnamese**, **Chinese**).

---

<a id="screenshots"></a>
## 📸 Application Screenshots

<p align="center">
  <img src="docs/screenshots/2026-07-26_231301.png" alt="JA MES Tool Settings with Verified Badge Icon & 2-Step Sync Card" width="850">
  <br><br>
  <img src="docs/screenshots/2026-07-26_231317.png" alt="JA MES Tool Automatic Startup Expired Token Warning Popup" width="850">
</p>

---

<a id="usage"></a>
## 🖥️ User Guide

### 1. Adding Serial Numbers
* **Single SN**: Type the SN into the left sidebar input box and press **Enter** or click **[+]**.
* **Batch Import**: Click **[Template]** to save a sample CSV. Fill in your SNs, then click **[Import]**. Title rows containing `"SN"` are automatically skipped.

### 2. Auto Sync Token from Browser (2-Step CDP Wizard)
1. Open **Settings ⚙️** (or use the automatic startup expired token popup).
2. **Step 1**: Click **[1. Open Browser]** to launch Chrome or Microsoft Edge.
3. Log into your MES account on the web page.
4. **Step 2**: Click **[2. Sync Credentials]**. The app captures live **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from browser traffic.
5. Click **Save** to automatically clear prior error screens and re-fetch the entire SN queue.

### 3. Connection Health Check
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
│   ├── main.dart                  # Application entry point & Provider setup
│   └── modules/
│       ├── api_client.dart        # MES API Client & Header Sanitizer (_cleanHeader)
│       ├── browser_helper.dart    # CDP Interception & Edge/Chrome Automation
│       ├── constants.dart         # Global app constants & defaults (v2.3.0)
│       ├── logger_service.dart    # Daily file logger & 7-day auto cleanup
│       ├── logic.dart             # App state management & auto validation timer
│       ├── translations.dart     # Multi-language dictionary (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # Primary UI layout & 2-step dialogs
│           ├── styles.dart        # Dark theme token definitions
│           └── styles_win10.dart  # Light theme token definitions
│
├── docs/
│   └── screenshots/               # UI Screenshots (tracked by Git)
│       ├── 2026-07-26_231301.png  # Settings with Verified Badge Icon
│       └── 2026-07-26_231317.png  # Automatic Startup Expired Token Warning Popup
├── i18n/
│   ├── README.vi.md               # Vietnamese documentation
│   └── README.zh-CN.md            # Chinese documentation
├── pubspec.yaml                   # Flutter package manifest (v2.3.0+1)
├── ABOUT.txt                      # Project summary card
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

## 📜 License

Proprietary Software. Developed for Foxconn CABG_VN production environment. All rights reserved.
