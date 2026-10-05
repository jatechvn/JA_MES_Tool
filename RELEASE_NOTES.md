TAG=v2.11.2
TITLE=JA MES Tool v2.11.2 — Nút sao chép nhanh SN, ưu tiên truy vấn SN mới và chọn SN khi khởi động
BODY=
## Điểm nhấn chính
- **Nút Sao chép Nhanh Serial Number (Copy SN)**:
  - Bổ sung icon button sao chép trực tiếp (`Icons.copy_rounded`) trên từng item hàng đợi SN tại sidebar, hỗ trợ đưa SN vào clipboard tức thì.
  - Hỗ trợ tooltip đa ngôn ngữ (`Copy SN` / `Sao chép SN` / `复制SN`).
- **Tối ưu hóa Hành vi Tái tra cứu & Khởi động**:
  - Nhập hoặc quét lại SN đã tồn tại trong danh sách sẽ tự động di chuyển SN lên vị trí mới nhất (trên cùng ở sidebar) và chọn ngay lập tức.
  - Khởi động ứng dụng tự động chọn mã SN mới nhất được tra cứu thay vì mã đầu tiên cũ nhất.
- **Hàng đợi Truy vấn Ưu tiên (Priority-Aware Query Queue)**:
  - Nâng cấp `QueryQueue` với cơ chế tính toán độ ưu tiên linh hoạt (`priority`), ưu tiên nạp và truy vấn các SN mới nhất trước khi làm mới hoặc tải hàng loạt mà không xáo trộn thứ tự lưu trữ gốc.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 73/73 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.11.2_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
