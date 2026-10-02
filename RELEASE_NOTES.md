TAG=v2.11.0
TITLE=JA MES Tool v2.11.0 — Tối ưu hóa GPU/CPU toàn diện & Chế độ ngủ rảnh tay 12s
BODY=
## Điểm nhấn chính
- **Tối ưu hóa GPU/CPU toàn diện (Flutter Desktop Power Optimizer)**:
  - Dịch vụ quản lý năng lượng tập trung `AppPowerManager` (Single Source of Truth) điều phối 4 trạng thái cửa sổ.
  - Tự động đóng băng và dừng các hiệu ứng đồ họa liên tục (`MeshOrb`, `WaveIndicator`, `BorderBeam`, `GlassMarquee`) khi cửa sổ mất focus hoặc thu nhỏ, triệt tiêu 100% khung hình render không cần thiết, đưa mức sử dụng GPU về mức tối thiểu.
  - Các tiến trình nghiệp vụ mạng ngầm (tra cứu SN, CDP sync, kiểm tra token xác thực 3 phút, kiểm tra OTA) tiếp tục chạy bình thường 100%.
- **Bảo toàn Chiều Chuyển Động Animation (Direction & Leg Preservation)**:
  - Khắc phục lỗi đổi hướng đột ngột khi resume bằng cách kiểm tra trạng thái pha di chuyển (`reverse`/`forward`) và tiếp tục chu kỳ ping-pong mượt mà.
- **Session Epoch Guard cho Chữ Cuộn `GlassMarquee`**:
  - Đóng băng vị trí cuộn ngay lập tức khi mất focus và triệt tiêu toàn bộ ghost callback từ Future/Timer dở dang, khôi phục cuộn liên tục từ offset cũ.
- **Chế độ Ngủ Rảnh Tay (12s Idle Sleep Mode)**:
  - Tự động tạm dừng khối cầu gradient nền nặng khi không thao tác chuột/phím trong 12 giây (hoặc 30s/60s).
  - Tích hợp thẻ điều khiển BentoCard trong Settings Dialog kèm tính năng Rollback on Cancel an toàn.
- **Nhận diện Thương hiệu & Logo Mới**:
  - Biểu tượng ứng dụng `app_icon.ico` và đồ họa hiện đại chuẩn thiết kế Glassmorphism.
- **Tự động đồng bộ Checksum SHA-256 (`dist/SHA256SUMS.txt`)**:
  - Script đóng gói tự động tính và cập nhật mã băm SHA256 cho gói ZIP phát hành.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 65/65 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.11.0_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
