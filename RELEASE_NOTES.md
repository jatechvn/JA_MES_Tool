TAG=v2.14.2
TITLE=JA MES Tool v2.14.2 — Tối ưu kiến trúc mô-đun, khắc phục rò rỉ bộ nhớ Settings & Dọn dẹp 3,408 dòng mã thừa
BODY=
## Điểm nhấn chính
- **Tối ưu Kiến trúc Mô-đun (`main_window.dart`, `logic.dart`, `api_client.dart`)**:
  - Tách `main_window.dart` (`5,424` dòng) thành 7 tệp có trách nhiệm rõ ràng (`main_window.dart`, `main_sidebar_part.dart`, `test_record_part.dart`, `barcode_history_part.dart`, `wip_components_part.dart`, `component_trace_part.dart`, `main_records_toolbar_part.dart`).
  - Tách toàn bộ lớp dữ liệu CloudMES từ `api_client.dart` sang `lib/modules/models/mes_models.dart` (re-export tương thích ngược 100%) và tách nghiệp vụ CSV / Component Trace trong `AppLogic` sang `logic_csv_part.dart` và `logic_trace_part.dart`.
- **Khắc phục Rò rỉ Bộ nhớ Settings & Tách 3 Tab Cài đặt (`settings_dialog.dart`)**:
  - Chuyển hộp thoại cài đặt sang `StatefulWidget` (`_AppSettingsDialog` + `ListenableBuilder`), đảm bảo giải phóng đầy đủ **7 `TextEditingController`** khi đóng (Lưu hoặc Hủy) và không render lại toàn bộ nội dung trên mỗi frame hiệu ứng mở/đóng.
  - Tách 3 tab cài đặt sang `settings_mes_api_part.dart`, `settings_display_glass_part.dart`, `settings_about_ota_part.dart`.
- **Dọn sạch `3,408` dòng mã nguồn thừa & Đồng bộ Tài liệu**:
  - Loại bỏ 11 tệp Dart mồ côi không còn tham chiếu, dùng nội suy động `v$appVersion` trong `translations.dart`, đồng bộ cấu trúc thư mục và bổ sung chỉ dẫn cho từng phân hệ.

## Kiểm chứng & Đóng gói
- `dart format --output=none --set-exit-if-changed lib test`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt `No issues found!`.
- `flutter test`: **151/151** ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.14.2_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
