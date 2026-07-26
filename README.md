# 🤖 JA MES Test Record Tool (v2.0.0)

<p align="center">
  <br>
  <i><b>A high-performance Windows desktop application developed in Dart & Flutter for automated Foxconn CloudMES test record querying and data management.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Dart-3.12+-blue.svg?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6.svg?style=flat-square&logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/Version-v2.0.0-green.svg?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="#introduction">🚀 Introduction</a> • 
  <a href="#features">💡 Features</a> • 
  <a href="#architecture">🏗️ Architecture</a> • 
  <a href="#setup">📖 Installation & Build</a> • 
  <a href="#usage">🖥️ User Guide</a> • 
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

**JA MES Test Record Tool** is a specialized tool engineered to streamline serial number (SN) verification, test station history extraction, and result reporting from the **Foxconn CloudMES** API platform.

Whether you are performing quality assurance, tracing failure root causes, or batch exporting test logs for production analytics, this tool provides instant parallel queries with an intuitive, modern Glassmorphic desktop interface.

---

<a id="features"></a>
## 💡 Key Features (v2.0.0)

- **⚡ Parallel SN Query Queue**: Process individual or batch Serial Numbers with asynchronous API fetch.
- **📄 Smart CSV Batch Import & Export**:
  - Automatically filters out header/title rows (e.g., rows containing `"SN"`).
  - One-click template generation and complete detailed CSV export.
- **🌐 CDP Network Interception (Auto Token & Credentials)**:
  - Automatically launches Chrome/Edge with dynamic DevTools debugging ports (`--remote-debugging-port=0`).
  - Intercepts live API network requests via Chrome DevTools Protocol (CDP) `Network.enable`.
  - Captures 100% accurate **Token**, **UUID**, **Operation-ID**, and **Cookie** directly from actual browser traffic.
- **🔄 Auto Token Health Check & Verification**:
  - Background timer automatically validates authentication every 3 minutes.
  - Live status indicator (Green = Active, Red = Expired/Error) on the main app header.
  - Manual connection verification tool in Settings.
- **🛠️ Header Sanitization Engine**:
  - Automatically cleans invisible Carriage Returns (`\r\n`), extra whitespaces, and quote wrappers (`"..."`) to prevent HTTP header `FormatException` crashes.
- **📋 Daily System Logs**:
  - Logs all operational events and API failures to daily files in the `logs/` directory.
  - Automatically cleans up log files older than 7 days upon launch.
- **🎨 Glassmorphic Multi-Language UI**:
  - Instant toggle between Light & Dark themes with transparent result detail panels.
  - Dynamic multi-language switching (**English**, **Vietnamese**, **Chinese**).

---

<a id="architecture"></a>
## 🏗️ Project Directory Structure

```text
ja_mes_tool/
├── lib/
│   ├── main.dart                  # Application entry point & Provider setup
│   └── modules/
│       ├── api_client.dart        # MES API Client & Header Sanitizer (_cleanHeader)
│       ├── browser_helper.dart    # CDP Network Interception & Chrome Automation
│       ├── constants.dart         # Global app constants & defaults
│       ├── logger_service.dart    # Daily file logger & 7-day auto cleanup
│       ├── logic.dart             # App state management & auto validation timer
│       ├── translations.dart     # Multi-language dictionary (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # Primary UI layout & dialogs
│           ├── styles.dart        # Dark theme token definitions
│           └── styles_win10.dart  # Light theme token definitions
│
├── docs/
│   └── SKILL_cdp_extraction.md    # Technical guide for CDP Header Extraction
├── i18n/
│   ├── README.vi.md               # Vietnamese documentation
│   └── README.zh-CN.md            # Chinese documentation
├── logs/                          # Daily log files (mes_log_YYYY-MM-DD.txt)
├── POST_MORTEM_MEMO.md            # Technical post-mortem & resolution document
├── pubspec.yaml                   # Flutter package manifest (v2.0.0+2)
├── git_push.bat                   # Automated Git deployment script
├── ABOUT.txt                      # Project summary card
└── LICENSE                        # MIT License
```

---

<a id="setup"></a>
## 📖 Installation & Build Guide

### Prerequisites
* **Windows 10 / 11**
* **Flutter SDK 3.x** & **Dart 3.12+**
* **Google Chrome** or **Microsoft Edge** browser installed.

### How to Run Locally
1. Fetch dependencies:
   ```cmd
   flutter pub get
   ```
2. Launch in debug mode:
   ```cmd
   flutter run -d windows
   ```

### How to Build Executable (.exe)
Compile the optimized production release:
```cmd
flutter build windows
```
The output executable will be created at:
`build\windows\x64\runner\Release\ja_mes_tool.exe`

---

<a id="usage"></a>
## 🖥️ User Guide

### 1. Adding Serial Numbers
* **Single SN**: Type the SN into the left sidebar input box and press **Enter** or click **[+]**.
* **Batch Import**: Click **[Template]** to save a sample CSV. Fill in your SNs, then click **[Import]**. Header rows like `"SN"` are automatically skipped.

### 2. Auto Sync Token from Browser (CDP)
1. Click **Settings ⚙️**.
2. Click **[Auto Login (Browser)]** to launch Chrome/Edge.
3. Log into your MES account on the web page.
4. Click **[Get Credentials]**. The app will reload the page and capture the exact **Token**, **UUID**, **Operation-ID**, and **Cookie** from live network traffic.
5. Alternatively, click **[Paste Raw Header]** to parse headers copied directly from F12 or Postman.

### 3. Monitoring Connection Health
* The circle icon next to **"Result Details"** indicates your token status:
  - 🟢 **Green**: Token valid and server reachable.
  - 🔴 **Red**: Token expired or unauthorized (401).
* Token status is automatically checked every **3 minutes**.

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
