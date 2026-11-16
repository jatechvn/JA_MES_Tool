TAG=v2.14.3
TITLE=JA MES Tool v2.14.3 — Tinh chỉnh giao diện cài đặt & Khối cấu hình nâng cao thu gọn thông minh
BODY=
## Điểm nhấn chính
- **Thu gọn Thẻ Cấu hình Nâng cao & CDP Sync (`settings_mes_api_part.dart`, `settings_dialog.dart`)**:
  - Giao diện tab Cài đặt MES API được tinh chỉnh gọn gàng, tự động ẩn khối nhập Token thủ công, UUID, Operation ID, Cookie và CDP Sync đằng sau nút chuyển đổi thông minh `Hiện cài đặt nâng cao / Ẩn cài đặt nâng cao`.
  - Tối ưu trải nghiệm đăng nhập người dùng: tập trung vào quy trình đăng nhập 1-Click tài khoản MES/SSO, nhưng vẫn cho phép kỹ sư/FA mở rộng tức thì khi cần can thiệp thông số kết nối hoặc đồng bộ bằng trình duyệt.
- **Bảo toàn trạng thái Đăng xuất khi Lưu cài đặt (`logic.dart`)**:
  - Đảm bảo trạng thái phiên `_manualLogoutInSession` không bị xóa khi người dùng lưu cài đặt sau khi đăng xuất tài khoản.
- **Kiểm thử tự động toàn diện**:
  - Mở rộng bộ kiểm thử `test/settings_dialog_tabs_test.dart` đạt **152/152 tests passed** (100% pass).

## Kiểm chứng & Đóng gói
- `dart format --output=none --set-exit-if-changed lib test`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt `No issues found!`.
- `flutter test`: **152/152** ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.14.3_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
