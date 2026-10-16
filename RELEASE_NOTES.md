TAG=v2.13.1
TITLE=JA MES Tool v2.13.1 — Sửa lỗi bôi đen & sao chép Ctrl+C mã SN / SN phụ trên danh sách hàng đợi Sidebar
BODY=
## Điểm nhấn chính
- **Sửa lỗi Chọn Văn bản & Sao chép `Ctrl+C` trên Sidebar Hàng đợi SN (`main_window.dart`)**:
  - Tách biệt phạm vi chọn văn bản (`SelectionArea`) độc lập cho từng mã SN chính (`select_sn_$sn`) và mã SN phụ (`select_alternate_sn_$sn`) trên mỗi dòng trong danh sách hàng đợi SN, loại bỏ hiện tượng xung đột tọa độ ngang của `BounceMarqueeText` giữa các hàng.
  - Đảm bảo thao tác kéo chuột bôi đen (`drag`) hoặc nhấp đúp (`double-click`) + `Ctrl+C` ở bất kỳ dòng nào (từ dòng 2 trở đi) đều sao chép chính xác mã SN / SN phụ của đúng dòng đó, đồng thời tự động chọn dòng SN khi nhấn chuột và không làm mất vùng chọn khi có thông báo dữ liệu bất đồng bộ (`notifyListeners()`).
  - Bổ sung bộ kiểm thử `test/sn_sidebar_selection_test.dart` kiểm chứng trên cả giao diện Sáng/Tối và cả 2 chế độ kéo/nhấp đúp.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 134/134 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.13.1_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
