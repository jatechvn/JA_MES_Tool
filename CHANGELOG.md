# 📜 Changelog

All notable changes to the **JA MES Test Record Tool** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
