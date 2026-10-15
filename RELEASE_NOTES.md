TAG=v2.13.0
TITLE=JA MES Tool v2.13.0 — Nâng cấp toàn diện dữ liệu CloudMES cho 4 Tab hiện có, lọc nhanh FAIL Only, tra cứu thông số MAC linh kiện và nhảy liên tab 1-Click
BODY=
## Điểm nhấn chính
- **Sidebar Queue & Header Tổng quan (`SnMasterInfo` + `KPI Yield`)**:
  - Bổ sung bộ lọc nhanh **`All / FAIL Only`** ngay trên danh sách hàng đợi SN cùng badge trạng thái **`GOOD` / `FAIL`** từ `SnMasterInfo`.
  - Hiển thị dải thông tin luồng trạm **`Current ➔ Next`**, `WO`, `PN (vRev)`, `Line`, `Last Scan` và chỉ số năng suất **`KPI Yield` (`Qty · Pass · Fail · Repass · FPY · LPY`)** trên thanh tiêu đề bản ghi.
- **Nâng cấp Chi tiết 4 Tab Hiện có**:
  - **Tab 1 (`Test Record`)**: bổ sung `#testNo`, `⏱ Duration`, `Test Start / End`, `Motherboard SN`, `MAC Group`, `Collecting Data`, `Components`, `GIT / ASN Data`, `Equipment Params`, chi tiết bước lỗi (`Fail Step`, `Fail Cycle`, `Major Item`) và thanh sao chép nhanh đường dẫn `Log / Zip File`.
  - **Tab 2 (`Barcode History`)**: hiển thị nổi bật mã khắc laser / đánh dấu **`Landmark Codes`** (`landMarkCodes`).
  - **Tab 3 (`Component List`)**: bổ sung `Parsed CSN`, `Scan Type`, `Unlink Time`, `Assembled Code`, bảng mở rộng **`Component Params / MAC`** (`queryComponentParam`) và nút 1-click **`Trace Component`** nhảy thẳng sang Tab 4.
  - **Tab 4 (`Component Trace`)**: bổ sung nút 1-click **`Inspect Product SN`** đẩy nhanh SN thành phẩm về hàng đợi Tab 1, kèm hiển thị `Parsed CSN`, `MAC Address`, `Scan Type`, `Material Ver`, `Customer PN`.
- **Tối ưu Hiệu năng WO & Quy trình Build**:
  - Nạp sẵn (`pre-seed`) dữ liệu `TestRecord` ngay từ kết quả phân trang Work Order, loại bỏ các request `pageTestRecordLists` trùng lặp cho từng SN.
  - Cập nhật `build.bat` và `scripts/stage_release.py` giữ nguyên `config.json` trong thư mục `Release` sau khi build (trong khi vẫn làm sạch gói phân phối `dist\`).

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 130/130 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.13.0_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
