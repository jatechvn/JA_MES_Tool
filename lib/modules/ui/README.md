# `lib/modules/ui/` — Main Window, Views & Dialogs

- **`main_window.dart`** (with `part` files):
  - `sidebar/main_sidebar_part.dart`: SN/WO queue sidebar, FAIL filter, isolated `SelectionArea` rows, and Trace history sidebar.
  - `views/test_record_part.dart`: Tab 1 Test Record list + filter/sort.
  - `views/barcode_history_part.dart`: Tab 2 Barcode History list + filter/sort.
  - `views/wip_components_part.dart`: Tab 3 WIP Component List, expandable `ComponentParamRecord` sub-panel, and 1-click Trace jump.
  - `views/component_trace_part.dart`: Tab 4 Component Trace reverse-lookup list + 1-click Product SN jump.
  - `widgets/main_records_toolbar_part.dart`: Shared records header (`Route`/`Next`/KPI pills, search, Sort `OverlayEntry`, animated rows, hover toolbar chips, OTA badge).
  - `views/terminal_view.dart`: Live diagnostic terminal opened via `Ctrl+K`.
- **`dialogs/`**:
  - `settings_dialog.dart` (with `part`s `settings_mes_api_part.dart`, `settings_display_glass_part.dart`, `settings_about_ota_part.dart`): `_AppSettingsDialog` stateful dialog with controller cleanup on dispose, Cancel rollback, and 3 consolidated tabs.
  - `login_dialog.dart`, `token_expired_dialog.dart`, `glass_update_dialog.dart`: Authentication and OTA update modals.
- **`motion.dart` / `styles.dart`**: Animation curves/durations and `lib/theme/*` compatibility re-exports.
