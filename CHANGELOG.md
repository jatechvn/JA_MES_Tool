# 📜 Changelog

All notable changes to the **JA MES Test Record Tool** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.9.5] - 2026-09-08

### 🐛 Bug Fixes
- **🎨 Command Palette surface**: Adopt the JA_Mini_Showcase Material surface and clipped card, removing nested backdrop blur. Light mode uses a lighter scrim; keyboard navigation and delayed focus remain available.

### 🔧 Documentation & Tests
- Synchronize About, User Guide and EN/VI/CN README content for v2.9.5.
- Add a widget test covering opening the palette and selecting a command.
- Windows IME visual verification remains pending.

---

## [2.9.4] - 2026-09-04

### 🎨 UI/UX Improvements
- **🟡 SN data status colors**: When Test Record has no data but Barcode History
  or Component List still returns records, the SN in the sidebar is shown in
  amber with a warning indicator instead of red.

### 🐛 Bug Fixes
- **🔴 Accurate empty-state error**: Red is now reserved for an SN whose Test
  Record, Barcode History, and Component List have all finished empty; the
  sidebar stays neutral while related views are still loading.

---

## [2.9.3] - 2026-09-04

### 🚀 Major Features & Enhancements
- **🔁 Smart Test Record fallback**: When Test Record returns no rows on first app load, a newly searched SN, or an explicit refresh while Test Record is active, the app automatically opens Barcode History so users still see available MES history.
- **🌐 Windows locale first-run language**: On first launch without a saved language, the app now chooses English, Vietnamese, or Chinese from the Windows locale; saved in-app language preferences still take priority.

### 🎨 UI/UX Improvements
- **⌨️ Command Palette glass/focus polish**: The command palette now follows the Dialog blur/opacity settings and delays focus slightly to avoid Windows IME underline artifacts.

### 🐛 Bug Fixes
- **🧭 Manual Test Record tab stays stable**: Selecting an existing SN or manually switching back to Test Record no longer bounces to Barcode History immediately; fallback only runs for fresh app load/search/refresh flows.

---

## [2.9.2] - 2026-08-29

### 🚀 Major Features & Enhancements
- **🧭 Route Badge**: Added a Route badge to the records header using the SN Master route name, with a fallback to the route code when the name is unavailable. The badge is shown only when route data is returned by the API.

---

## [2.9.1] - 2026-08-29

### 🐛 Bug Fixes
- **🔄 Refresh All cache invalidation**: Refresh All now clears canonical SN and SN Master resolution caches before re-querying the queue, preventing stale resolved SN and Next-process metadata after data changes.

---

## [2.9.0] - 2026-08-27

### 🚀 Major Features & Enhancements
- **⚡ Command Palette (Ctrl+K / Cmd+K)**: A spotlight-style search overlay (`lib/widgets/command_palette.dart`) listing every tab, action, and setting — type to filter by name/keyword, navigate with ↑/↓, run with Enter or a click, dismiss with Esc or a click outside. Wired up as a global shortcut via `CommandPaletteShortcut` wrapping the whole app.
- **🔔 Glass Toast Notifications**: New `showAppToast()` (`lib/widgets/app_toast.dart`) — a transient, auto-dismissing glass-styled notification used for CDP credential-sync feedback in place of the earlier SnackBar-based messages.
- **🎞️ New reusable glass widgets**: `SlidingPillTabBar`, `AsymmetricMarqueeText`, `KbdTag`, `BorderBeam` (rotating gradient border sweep), and `SpotlightGlow` (mouse-follow radial highlight) added to `lib/widgets/glass_widgets.dart`.

### 🐛 Bug Fixes
- **🧠 `FocusNode` leak in the Command Palette**: A new `FocusNode()` was instantiated inline in `build()` for the palette's `KeyboardListener` on every rebuild (each keystroke, hover, or arrow-key press) and never disposed. It's now a single `State`-owned field, created once and disposed with the widget.
- **⌨️ Misleading shortcut badges removed**: Command palette entries displayed `1`/`2`/`3`/`4`/`Ctrl+,` shortcut badges that weren't bound to any actual key handler — pressing them did nothing. The badges have been removed rather than shipping a false affordance.
- **🔤 Removed reference to an unbundled font**: `KbdTag` set `fontFamily: 'JetBrains Mono'`, but no such font asset is registered in `pubspec.yaml`, so it silently fell back to the default font. The dead reference has been removed.

---

## [2.8.0] - 2026-08-26

### 🎨 Major UI/UX Overhaul & Bento Glassmorphism Architecture
- **🌟 Bento Glassmorphism & Liquid Glass Engine**: Complete modern visual upgrade matching the latest `flutter_ui_template` framework. Features floating Bento Cards with 1px top highlight reflective edges, 20-24px BackdropFilter blur, and ambient drifting Mesh Orbs composited on GPU.
- **✨ Un-nested Floating Glass Architecture**: Completely resolved the opaque double-nesting issue where stacked Bento Cards created solid white boxes. All cards now float as independent translucent surfaces over the animated background.
- **🎛️ Live-Preview 4-Slider Glassmorphism Controls**: Added 4 interactive tuning sliders in Settings (Card Blur `0-40px`, Card Opacity `5-100%`, Dialog Blur `0-40px`, Dialog Opacity `10-100%`) with real-time live preview feedback across all UI surfaces, a Default reset button, and Cancel rollback.
- **🌓 1-Click Direct Theme Switcher**: Refactored `toggleTheme()` to seamlessly switch between Light and Dark mode on every click without redundant intermediate cycles.
- **⏱️ Accurate Build Timestamp Reader**: Enhanced `BuildInfo` to read last-modified date/time from compiled `data/app.so` and executable, displayed directly under the header version tag and in the About modal tab.
- **🛡️ Multi-Theme Windows Token Sets**: Fine-tuned `styles_win10.dart` (Aero) and `styles_win11.dart` (Acrylic/Mica) with ideal ~20-25% card opacity and vibrant 0.20-0.25 mesh orb blending.

### 🐛 Bug Fixes
- **🎛️ First-run glassmorphism defaults now match "Default"**: `AppLogic._init()`'s config-fallback values previously used the old pre-redesign numbers (10.0/0.6/12.0/0.75) instead of the new ones (20.0/0.25/20.0/0.85), so a fresh install (or any pre-2.8.0 `config.json`) rendered a different glass look than clicking Settings → Default — and saving once silently locked the mismatch into `config.json`.
- **🛡️ Crash risk on closing a dialog mid-CDP-sync**: The Settings and Token-Expired-warning dialogs' "Sync Credentials" buttons called `setDialogState()` right after an `await BrowserHelper.fetchCredentialsFromBrowser()` without checking `context.mounted` first — closing the dialog while the browser fetch was still in flight could throw `setState() called after dispose()`. Both call sites now check `context.mounted` immediately after the `await`, before touching dialog state.
- **🌓 Theme now follows Windows light/dark changes live**: `ThemeProvider` computed `isDark` from the OS brightness in `'system'` mode but never observed platform brightness changes, so switching Windows' theme while the app was open left the UI stale until an unrelated rebuild happened to occur. It now implements `WidgetsBindingObserver` and calls `notifyListeners()` on `didChangePlatformBrightness()` while in `'system'` mode.

---

## [2.7.0] - 2026-08-22

### 🚀 Major Features & Enhancements
- **🧭 New Component Trace view**: A 4th tab for the reverse lookup — scan or type a *component's own* CSN (`report/queryInfoList`) to find which product SN it is currently installed into, with full material/traceability detail per match (manufacturer, part no, category, product SN, line code, process code, WO, qty, assembled status).
- **🗂️ Persisted trace history in the sidebar**: While Component Trace is active, the sidebar swaps the SN queue for a "Trace History" list — every searched CSN becomes a row (select to revisit a cached result, refresh to re-run it, remove to delete it) and is saved to `config.json`, surviving app restarts just like the SN queue.
- **🔗 Shared add/search input box**: Rather than a second input field, the existing sidebar "Add SN" box now switches its placeholder, button icon, and behavior (`addSns` vs `addTraceCsns`) automatically based on the active tab — including accepting multi-line/comma-separated pastes for batch CSN search.
- **🔍 Search, Sort, and CSV parity**: Component Trace reuses the same search/sort header and CSV Template/Import/Export toolbar buttons as the other 3 views, retargeted to CSNs (with dedicated `QueryInfoRecord` filter/sort fields) instead of SNs.

---

## [2.6.4] - 2026-08-21

### 🚀 Major Features & Enhancements
- **🔍 SN Master now captures its full API response**: `SnMasterInfo` previously parsed only 9 of the ~32 fields returned by `getSnMasterProcess` (and none of them were ever shown in the UI). It now also captures `lineCode`, `nextProcessCode`/`nextProcessName`, `errorCode`, and `routeCode`/`routeName`.
- **🏷️ "Next process" chip on the records header**: "Records for SN" now shows a small chip with the SN's next process (`nextProcessName`, falling back to `nextProcessCode`) when the SN Master lookup has one, right next to the SN label.
- **↔️ Asymmetric marquee for overflowing SN labels**: The "typed SN → resolved SN" label no longer truncates with `…` when the header runs out of room (e.g. once the new chip is showing) — it now scrolls: a slow, readable pass to the end, a hold, a quick snap back to the start, a hold, repeat. Timing confirmed against an interactive reference simulation.

---

## [2.6.3] - 2026-08-19

### 🐛 Bug Fixes
- **🌐 Persistent browser profiles:** Chrome and Edge now use separate profiles under `%LOCALAPPDATA%\JA_MES_Tool\browser_profiles`, preserving saved login sessions, passwords, and bookmarks across app restarts.
- **🛡️ CDP startup stability:** Added legacy profile migration, bounded CDP readiness checks, stale-endpoint rejection, and launch de-duplication to prevent browser login windows from hanging.

---

## [2.6.2] - 2026-08-18

### 🎨 UI/UX Improvements
- **⚙️ Tabbed Settings dialog**: Split Advanced Settings, User Guide, and About into dedicated tabs. The Advanced tab stays compact when collapsed, while the documentation tabs expand to fit their content.

---

## [2.6.1] - 2026-08-17

### 🐛 Bug Fixes
- **🛡️ Verify Connection feedback is now actually visible**: The verify-connection icon in Settings previously reported success/failure via `ScaffoldMessenger.showSnackBar`, which anchors to the main window's `Scaffold` and rendered *behind* the Settings dialog's modal barrier — invisible while the dialog was open. The icon itself now animates (spinner → green check / red cross → auto-reverts after 3s) via `AnimatedSwitcher`, and its tooltip carries the specific result message, so feedback is reliable regardless of dialog z-order.

---

## [2.6.0] - 2026-08-17

### 🚀 Major Features & Enhancements
- **🎨 Glassmorphism Advanced Settings**: A new collapsible "Customize blur & transparency" panel in Settings → Advanced, with 4 live-preview sliders — **Main background blur/opacity** and **Dialog blur/opacity** — matching the JA_Compare reference app's layout. All 4 values persist to `config.json` and reset via the existing "Default" button.
- **✨ Sort dropdown now uses real glass blur**: Replaced the `PopupMenuButton`-based Sort menu with a custom `OverlayEntry` popup using an actual `BackdropFilter`, driven by the new Dialog blur/opacity settings — the dropdown now visibly blurs the content behind it instead of using a flat tinted background. Automatically closes when switching tabs or SN to prevent stale state.
- **🔍 Settings dialog live-preview**: Adjusting the Dialog blur/opacity sliders now re-blurs the Settings window itself in real time (previously only affected the Sort dropdown), matching the reference app's behavior.
- **🖼️ Result Details panel background**: The main content panel now shares the same translucent tone as the sidebar (previously fully transparent), giving Dark theme a subtly more cohesive look without losing the native Acrylic blur-through.

### 🐛 Bug Fixes / Safety
- **🛡️ Legibility floor on all glass surfaces**: Whenever opacity is set below 100%, blur is automatically floored at 6px regardless of the slider position — prevents the "see-through overlapping text" glitch that the app's dialogs were previously made fully opaque to avoid (see `[2.1.0]`).

---

## [2.5.3] - 2026-08-15

### 🐛 Bug Fixes
- **🎨 Sort dropdown no longer clashes with the app's design system**: The Sort menu (`PopupMenuButton`) previously fell back to Flutter Material 3's default `surfaceTint`, giving it a purple tint that didn't match the app's own color palette. It now explicitly uses `theme.cardBg` with `surfaceTintColor: Colors.transparent` and a border matching the rest of the app's cards.
- **✨ Sort menu items redesigned for visual consistency**: Every sort field now has a leading icon (calendar, station, result, etc. — 10 fields across the 3 tabs), and the active field is highlighted with a rounded, accent-colored pill — the same "selected" visual language already used by the view-mode tab pills and the sidebar's selected SN row, instead of a bare arrow icon on a plain row.

---

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
