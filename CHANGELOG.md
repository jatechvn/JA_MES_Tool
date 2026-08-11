# 📜 Changelog

All notable changes to the **JA MES Test Record Tool** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.0] - 2026-08-11

### 🚀 Major Features & Enhancements
- **🗂️ Barcode History Tab**: New second data view per SN showing full process/station routing history (`snProcess/querySnProcessDetailPageList`) — process name, line station, work order, operator, pass/fail per step.
- **🔩 Component List Tab**: New third data view showing WIP component / BOM traceability (`snProcess/pageWipProductComponentLists`) — material no, category, manufacturer, mfg part no, date code, component SN, package/lot ID per installed part.
- **🔍 Excel-style Search Filter & Sort**: Every record list (Test Record, Barcode History, Component List) now has a live search box (matches any field) and a sort-by button (click a field, click again to flip ascending/descending) on the same row as "Records for SN".
- **📋 Selectable & Copyable Record Data**: All record text is now selectable and copyable with the mouse (click-drag or double-click a value, then Ctrl+C).
- **🏝️ Dynamic-Island-style Hover Toolbar**: The 3 view tabs and the Template/Import/Export/Language/Theme actions collapsed into compact icon chips that expand to full labels on hover — fixes the toolbar overflow that occurred once a 3rd tab was added. When the window is maximized, all chips stay fully expanded (no hover needed).
- **🔢 Consistent Record Counts**: "Records for SN" now shows a `(N)` count on all 3 tabs, hidden automatically when there are 0 or 1 records.

### 🔒 Security
- **Removed hardcoded credentials from source**: `defaultToken`/`defaultCookie` in `constants.dart` (and duplicated fallbacks in `config_service.dart`/`logic.dart`) no longer embed a real bearer token / account password — they default to empty and are provided per-user via Settings (Paste Raw Header, browser CDP sync, or manual entry), persisted only to the local, gitignored `config.json`.

### 🐛 Bug Fixes
- Fixed a string-escaping bug (`\$e`/`\$path` instead of `$e`/`$path`) in `logic.dart` that caused `pickFile`/`downloadTemplateCsv` error and success messages to show the literal text `$e`/`$path` instead of the real value.
- Fixed a potential `RangeError` in `browser_helper.dart` when logging a captured token shorter than 20 characters.

---

## [2.3.0] - 2026-07-26

### Added
- **Automatic Startup Expired Token Warning Popup**: Immediately prompts user on application launch with the 2-step sync wizard (`1. Open Browser` & `2. Sync Credentials`) whenever an expired token (`401 Unauthorized`) is detected.
- **Microsoft Edge & Chrome Multi-Browser Anti-Freeze Flags**: Added isolated process flags (`--disable-features=msEdgeStartupBoost,msUnderside,msEdgeSidebar,msHubs,WebAuthentication`, `--no-service-autorun`) to prevent UI freezes / "Not Responding" errors on Edge login popup windows.
- **Verified Connection Badge Icon (🛡️)**: Replaced the generic reload icon with an intuitive shield badge icon (`Icons.verified_outlined`) in the Settings footer.

### Updated
- Updated About and User Guide dialogs across English, Vietnamese, and Chinese.

---

## [2.2.0] - 2026-07-26

### 🔄 Added & Improved
- **Automatic SN Queue Refetch on Settings Save**: Saving settings automatically clears old expired/failed token errors (401) and re-fetches the entire SN queue using newly saved credentials.
- **Immediate Connection Validation**: Triggers instant connection check right after saving settings.
- **Label Standardized**: Standardized button and user guide labels to `Paste Raw Header (Postman)` across English, Vietnamese, and Chinese.

---

## [2.1.0] - 2026-07-26

### 🎨 Added & Redesigned
- **Smart 2-Step Auto Sync Card**: Redesigned browser credential sync into an intuitive 2-step wizard (`1. Open Browser` ➔ `2. Sync Credentials`) with a real-time connection health badge (`🟢 Connected` / `🟡 Check Status`).
- **Collapsible Advanced Settings Panel**: Reorganized Settings dialog to keep manual fields (`Cookie`, `Token`, `Language`, `Operation ID`, `UUID`, `Paste Raw Header`) hidden inside a sleek expandable tile (`[Expand Advanced Settings ▼]`).
- **Solid Opaque Dialog Backgrounds**: Replaced transparent glass background on `User Guide`, `Paste Raw Header`, and `Settings` dialogs with 100% solid opaque backgrounds (`#2B2D30` for Dark mode / `White` for Light mode) to prevent see-through overlapping text glitches.
- **Full Multi-Language Synchronization**: Fully localized all Settings card titles, action buttons, tooltips, and status indicators in English, Vietnamese, and Chinese.
- **Updated UI Documentation & Screenshots**: Integrated new UI screenshots (`2026-07-26_222406.png` & `2026-07-26_222546.png`) into documentation.

---

## [2.0.0] - 2026-07-26

### 🚀 Added
- **Chrome DevTools Protocol (CDP) Network Interception**: Automatically launch Chrome/Edge with dynamic port allocation (`--remote-debugging-port=0`) and capture live API request headers (`Authorization`, `UUID`, `Operation-ID`, `Cookie`).
- **Header Sanitizer (`_cleanHeader`)**: Automatically clean Carriage Returns (`\r\n`), whitespaces, and surrounding quotes from tokens and headers to prevent `FormatException` crashes.
- **Smart CSV Import Header Filtering**: Automatically skip header/title rows containing `"SN"` during CSV import.
- **Automatic Token Health Check**: Background timer runs every 3 minutes to validate MES token status with live header status indicator (Green/Red).
- **Daily Logger Service**: Log operational events to `logs/mes_log_YYYY-MM-DD.txt` with automatic cleanup of files older than 7 days.
- **Updated User Guide & About Dialogs**: Multi-language detailed dialogs in English, Vietnamese, and Chinese.

### 🎨 Fixed & Improved
- Fixed UUID mismatch issue when fetching credentials from browser.
- Fixed 401, 404, and 500 API errors caused by unsanitized `\r` carriage return characters in HTTP headers.
- Restored glassmorphic transparency (`Colors.transparent`) for the Result Details view.
- Preserved user's UI language selection when fetching browser credentials.
- Upgraded version definitions across `pubspec.yaml`, `constants.dart`, and documentation files.

---

## [1.0.0] - 2026-07-25

### 🚀 Initial Release
- Basic SN queueing and parallel test record querying from Foxconn CloudMES API.
- Support for CSV batch import and export.
- Light/Dark mode themes.
- Multi-language dictionary support (EN, VN, CN).
