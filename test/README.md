# `test/` — Automated Unit & Widget Test Suite

Run all tests with `flutter test` (no live MES access required; HTTP/CDP/filesystem seams are injected in tests).

- **API, State & Queue Tests**: `widget_test.dart`, `query_queue_test.dart`, `sn_query_concurrency_test.dart`, `sn_alternate_test.dart`, `barcode_history_fields_test.dart`, `work_order_query_test.dart`, `sn_query_benchmark.dart`.
- **UI & Dialog Regressions**: `main_window_layout_test.dart`, `four_tabs_upgrade_test.dart`, `settings_dialog_tabs_test.dart`, `mes_login_dialog_test.dart`, `sn_sidebar_selection_test.dart`, `sn_queue_marquee_test.dart`, `csv_notifications_test.dart`, `command_palette_test.dart`, `ui_preview.dart`.
- **Power / GPU & LAN OTA Tests**: `app_power_manager_test.dart`, `power_frame_gate_test.dart`, `power_ticker_gate_test.dart`, `window_activity_monitor_test.dart`, `glass_animation_resume_test.dart`, `glass_marquee_session_test.dart`, `ota_update_service_test.dart`.
