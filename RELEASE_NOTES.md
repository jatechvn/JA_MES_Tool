TAG=v2.9.9
TITLE=JA MES Tool v2.9.9 — Hợp nhất Bento Settings Dialog & Bộ cài đặt Windows Chuẩn
BODY=
## Thay đổi chính
- **Tối ưu hóa & Hợp nhất Settings Dialog thành 3 tab Bento Grid**:
  - Hợp nhất cấu trúc 5 tab rời rạc bị tràn chiều ngang (760px) thành 3 tab Bento Grid cân đối:
    1. **CloudMES & CDP** (`tab_mes_api`): Đồng bộ CDP tự động từ Chrome/Edge + quản lý credentials và kiểm tra kết nối.
    2. **Giao diện & Kính mờ** (`tab_display_glass`): Chọn ngôn ngữ + Graphic Tier switcher + Bento card điều khiển 6 thanh trượt Glassmorphism với Live-Preview tức thì và nút Mặc định.
    3. **Thông tin & Cập nhật** (`tab_about_updates`): Trạng thái LAN OTA + Cấu hình UNC Share Server + Thẻ thông số hệ thống và nút mở thư mục Logs/Config.
  - Áp dụng `Expanded` cho toàn bộ thanh tab bar, căn giữa nội dung, bọc `Flexible` + `TextOverflow.ellipsis`, loại bỏ 100% hiện tượng tràn viền.
  - Gán `PageStorageKey` độc lập cho từng tab, ngăn chặn việc kế thừa sai lệch scroll position khi chuyển đổi qua lại giữa các tab.
  - Bổ sung đồng bộ giá trị thanh trượt Glassmorphism theo thời gian thực khi bấm chọn Graphic Tier.
- **Bộ cài đặt & Gỡ bỏ chuẩn Windows (Non-Admin Standard Suite)**:
  - Bổ sung `install.bat`, `uninstall.bat`, và `uninstall.ps1` theo chuẩn `dart-build-pro`.
  - Hỗ trợ cài đặt vào `%LOCALAPPDATA%\Programs\JA_MES_Tool` hoặc thư mục tùy chọn mà không cần quyền Administrator.
  - Tự động tạo Shortcut trên Desktop và Start Menu; đăng ký thông tin gỡ cài đặt chuẩn xác trong Windows Registry `Uninstall` key.
- **Bản địa hóa toàn diện (Full Multilingual Localization)**:
  - Bổ sung từ điển đa ngữ cho toàn bộ các nhãn thông số hệ thống (`system_engine`, `system_architecture`, `system_cdp_interceptor`, `system_hardware_profile`, `system_license`, `open_logs_folder`).

## Kiểm chứng
- `dart format lib test`: code chuẩn định dạng.
- `flutter analyze`: 0 issues found.
- `flutter test`: 42/42 tests passed (bao gồm bộ widget test mới `test/settings_dialog_tabs_test.dart`).
- `flutter build windows --release`: biên dịch thành công.

## Artifact
- JA_MES_Tool_v2.9.9_Windows_x64.zip
- Bung sẵn toàn bộ ứng dụng portable trong `dist/`.
- Tự động cập nhật `dist/version.json` và `dist/SHA256SUMS.txt`.

