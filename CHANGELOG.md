# 📜 Changelog

All notable changes to the **JA MES Test Record Tool** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.2] - 2026-08-14

### 🚀 Major Features & Enhancements
- **📋 Selectable & Copyable SN Queue**: The SN list in the sidebar is now wrapped in a `SelectionArea`, so click-drag selects an SN's text for copying (Ctrl+C) — matching the existing selectable behavior in the record detail panel.
- **🔄 Per-SN & Refresh-All Buttons**: Each SN in the queue now has its own refresh icon to re-fetch its Test Record, Barcode History, and Component List data (plus re-resolve its SN Master mapping) without removing/re-adding it. A new "Refresh All" button in the sidebar header re-fetches the entire queue — both replace the previous workaround of closing and reopening the app to force a refresh.

---

## [2.5.1] - 2026-08-14

### 🐛 Bug Fixes
- **🖼️ Fixed stagger entrance animation replaying on scroll**: List items in Test Record, Barcode History, and Component List previously replayed their fade/slide-in entrance animation every time they scrolled back into view, because `ListView.builder` disposes and recreates offscreen items' `Element`s. Now each list tracks already-animated items by a stable content-derived key in a `Set<String>` owned by the longer-lived parent state, so each item animates in exactly once per session.
- **⚡ All 3 tabs now preload concurrently**: Barcode History and Component List previously only fetched data lazily when the user switched into that tab. `logic.dart` now fires all 3 fetches (Test Record, Barcode History, Component List) together via `Future.wait` on init, SN add, and refresh, so switching tabs is instant instead of triggering a fresh load.

---

## [2.5.0] - 2026-08-14

### 🚀 Major Features & Enhancements
- **🏷️ App Renamed to "JA MES Tool"**: The sidebar title ("MES Queue") and the internal app name (window title / About dialog, formerly "JA MES Test Record") are now unified as **JA MES Tool** across all 3 languages.
- **🔗 Automatic SN Master Resolution**: Typing an internal/alias SN (e.g. `SAFVN262983614B`) now auto-resolves it to the canonical product SN (e.g. `DHL290000V`) via `snMaster/getSnMasterProcess` before fetching Test Record, Barcode History, and Component List data — the "Records for SN" header shows `typed SN → resolved SN` whenever they differ. Resolved SNs are cached per-session to avoid redundant lookups, with automatic fallback to the typed SN if resolution fails.
- **✨ iOS-style Smooth UI Transitions**: A full animation pass across the app, backed by a shared `Motion` timing/easing spec (`lib/modules/ui/motion.dart`):
  - Fade + slide transition when switching tabs or selecting a different SN.
  - Cascading fade/slide-in entrance for record list items, plus bouncing scroll physics on all 3 lists.
  - Scale + fade presentation for dialogs (Settings, User Guide, Paste Raw Header, Token Expired warning) replacing Material's flat fade.
  - Animated sidebar selection highlight and a "pop" scale animation on the record-count badge.
  - Crossfaded background colors across sidebar, tab pill, sort button, and record cards on Light/Dark theme switch.

---

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
