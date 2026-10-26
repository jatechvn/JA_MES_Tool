TAG=v2.14.1
TITLE=JA MES Tool v2.14.1 — Khắc phục lỗi Crash/Treo ứng dụng, tuần tự hóa ghi Log/Config & Tinh chỉnh giao diện Login
BODY=
## Điểm nhấn chính
- **Khắc phục triệt để 4 nguyên nhân gây Crash & Đơ ứng dụng**:
  - **Tuần tự hóa ghi file Log & Config (`logger_service.dart`, `config_service.dart`)**: Đưa toàn bộ lệnh ghi `mes_log_YYYY-MM-DD.txt` và `config.json` vào hàng đợi tuần tự (`_writeQueue` / `_saveQueue`), chấm dứt hoàn toàn lỗi đứt dòng log và xung đột khóa file (`OS Error: errno = 32`) khi chạy hàng đợi lớn (~75 SN × 3 truy vấn).
  - **Chống kẹt khung hình lúc khởi động & khi tương tác (`power_binding.dart`, `main.dart`)**: Bổ sung ngoại lệ `!firstFrameRasterized` cho frame đầu tiên trên Windows và tự động đánh thức focus của `AppPowerManager` ngay khi nhấn chuột hoặc gõ phím trên cửa sổ/hộp thoại.
  - **Chống mở chồng `MesLoginDialog` & Điều phối Auto-Login (`login_dialog.dart`, `main_window.dart`, `logic.dart`)**: Thêm khóa `isMesLoginDialogOpen` ngăn mở chồng cửa sổ Login thứ 2 khi bấm **Đăng xuất / Đổi tài khoản**, đồng thời hoàn tất kiểm tra Token / Auto-Login trước khi bắn hàng đợi `_fetchAllPending()`.
  - **Bẫy lỗi toàn cục (`main.dart`)**: Đăng ký `FlutterError.onError` và `PlatformDispatcher.instance.onError` để ghi nhận an toàn mọi ngoại lệ bất đồng bộ vào `LoggerService`.
- **Tinh chỉnh Giao diện Header & Cửa sổ Đăng nhập (`main_window.dart`, `translations.dart`)**:
  - Loại bỏ icon User thừa cạnh nút Settings trên Header (nhấn trực tiếp vào `DynamicIslandCapsule` `LIVE • <Mã NV>` để mở cửa sổ Login).
  - Lược bỏ cụm chữ `(Port 9222)` trong nhãn đồng bộ trình duyệt ở cả 3 ngôn ngữ (`EN` / `VN` / `CN`).

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 150/150 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.14.1_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
