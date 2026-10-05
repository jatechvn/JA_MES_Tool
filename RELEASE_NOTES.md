TAG=v2.11.3
TITLE=JA MES Tool v2.11.3 — Chuẩn hóa thông báo CSV thành công màu xanh, đa ngữ hóa thông báo và dọn dẹp khi hủy
BODY=
## Điểm nhấn chính
- **Chuẩn hóa Màu sắc & Biểu tượng Thông báo CSV**:
  - Phân tách thông báo thành công (xanh ngọc `accentEmerald` kèm `check_circle_outline_rounded`) và lỗi (đỏ `accentRose` kèm `error_outline_rounded`).
  - Đường dẫn tệp hoặc chi tiết lỗi được nội suy rõ ràng vào nội dung thông báo.
- **Đa ngữ hóa Toàn diện Thông báo Thao tác Tệp**:
  - Hỗ trợ đa ngôn ngữ đầy đủ (Tiếng Việt, Tiếng Anh, Tiếng Trung) cho các hành động tải file mẫu, nhập CSV, xuất CSV và thông báo không tìm thấy tệp.
  - Tự động xóa thông báo khi người dùng hủy bỏ (Cancel) hộp thoại chọn tệp.
- **Mở rộng Bộ Kiểm thử Tự động**:
  - Bổ sung 8 test cases trong `test/csv_notifications_test.dart` bao phủ kiểm tra đa ngữ và màu sắc banner trên cả Light và Dark mode.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 91/91 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.11.3_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
