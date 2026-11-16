# `lib/modules/` — Core Logic, API, Services & UI Modules

- **`api_client.dart`** + **`lib/modules/models/mes_models.dart`**: CloudMES HTTP API requests (`TestRecord`, `SnProcessRecord`, `WipComponentRecord`, `ComponentParamRecord`, `SnMasterInfo`, `QueryInfoRecord`, SSO/CloudMES login & captcha). `api_client.dart` re-exports `lib/modules/models/mes_models.dart`.
- **`logic.dart`** (`part`s: `logic_csv_part.dart`, `logic_trace_part.dart`): `AppLogic` state container, bounded `QueryQueue` integration, SN Master caching, Work Order lookup, authentication, CSV import/export, and Component Trace.
- **`config_service.dart` / `logger_service.dart` / `browser_helper.dart` / `constants.dart` / `translations.dart` / `build_info.dart` / `window_helper.dart`**: Local config serialization, daily log rotation, Chrome/Edge CDP credential sync, app constants, trilingual dictionary, build timestamp extraction, and native window setup.
- **`services/`**: Hardware-friendly frame/ticker power gating (`power_binding.dart`, `window_activity_monitor.dart`, `app_power_manager.dart`) and LAN OTA updates (`ota_update_service.dart`).
- **`ui/`**: Main application shell, sidebars, tab views, and modal dialogs. See [`ui/README.md`](ui/README.md).
