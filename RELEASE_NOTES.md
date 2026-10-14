TAG=v2.12.0
TITLE=JA MES Tool v2.12.0 — Hoán đổi nhanh chế độ nhập SN ↔ WO, nạp hàng loạt SN từ Work Order và hiển thị mã SN phụ
BODY=
## Điểm nhấn chính
- **Hoán đổi Trực tiếp Chế độ Nhập `SN ↔ WO` trên Sidebar**:
  - Bổ sung nút icon chuyển đổi nhỏ gọn trên dòng `Refresh all` (cùng hàng với **Refresh All** và **Clear All**), loại bỏ nút bấm và hộp thoại rời rạc cũ để đồng bộ hoàn toàn với ngôn ngữ thiết kế Bento Glassmorphism.
  - Khi bật chế độ nhập **Work Order (WO)**, ô tìm kiếm tự động chuyển sang viền và biểu tượng điểm nhấn `accentCyan` (`Nhập WO...` / `Enter WO...` / `输入工单号...`).
- **Nạp Hàng loạt SN từ Work Order (`addWorkOrders`)**:
  - Nhập một hoặc nhiều mã WO vào ô tìm kiếm sẽ tự động truy vấn phân trang từ CloudMES (`pageTestRecordLists`), trích xuất và khử trùng lặp toàn bộ các mã SN thuộc WO đó (ưu tiên `internalSn` -> `sn` -> `customerSn`).
  - Toàn bộ SN thuộc WO được đẩy hàng loạt xuống danh sách bên dưới giống hệt như tra nhiều SN cùng lúc, tự động chọn SN mới nhất và kích hoạt truy vấn song song đầy đủ cả 3 chế độ xem (**Test Record**, **Barcode History**, **Component List**) cùng thông tin **Next Process / Route**.
- **Hiển thị Mã SN Phụ (`alternateSnFor`) & Tối ưu Hàng đợi Truy vấn**:
  - Tự động đối chiếu và hiển thị mã SN liên kết (Internal SN / Product SN / Customer SN) trên tiêu đề bảng kết quả kèm hiệu ứng cuộn marquee mượt mà và nút sao chép nhanh.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 127/127 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.12.0_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
