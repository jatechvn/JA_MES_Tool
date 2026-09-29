TAG=v2.10.1
TITLE=JA MES Tool v2.10.1 — Đảo ngược thứ tự danh sách SN mới nhất lên đầu & Tối ưu UI/UX
BODY=
## Điểm nhấn chính
- **Đảo ngược Thứ tự Hiển thị Danh sách Serial Number (Newest on Top)**:
  - Tối ưu hóa `ListView` danh sách SN trên thanh bên trái (Sidebar Queue): hiển thị theo thứ tự đảo ngược (`logic.snList.length - 1 - index`).
  - Các số Serial Number mới nhập, mới quét hoặc mới tra cứu luôn xuất hiện ở vị trí đầu tiên trên cùng danh sách, giúp quan sát ngay kết quả kiểm thử mà không cần cuộn trang.
  - Bảo toàn hoàn hảo logic chọn SN, hiệu ứng loading, cảnh báo dữ liệu (vàng/đỏ/xanh), badge đếm số bản ghi và marquee nảy.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 100% ca kiểm thử vượt qua.
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.10.1_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
