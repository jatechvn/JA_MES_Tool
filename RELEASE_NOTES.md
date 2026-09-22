TAG=v2.10.0
TITLE=JA MES Tool v2.10.0 — Nút Chọn Nhanh Chu kỳ OTA, Bố cục 2 Cột Kính mờ & Live OTA Badge
BODY=
## Thay đổi chính
- **Nút Chọn Nhanh Chu kỳ OTA (Bento Quick-Select Interval)**:
  - Thay thế Dropdown cũ thành hàng 4 nút Bento Pill (`Row` + `Expanded`) 1-chạm: Khi khởi động, Hàng ngày, Hàng tuần, Tắt.
  - Loại bỏ hoàn toàn khoảng trống thừa, có viền sáng và hiệu ứng highlight khi kích hoạt.
- **Bố cục 2 Cột (2-Column Grid) cho 6 Thanh trượt Kính mờ**:
  - Xếp 6 thanh trượt thành 3 hàng x 2 cột cân xứng (Cột trái: Blur `0 - 40px`, Cột phải: Opacity `5% - 100%`).
  - Giảm 50% chiều cao của thẻ Kính mờ, hiển thị trọn vẹn mà không cần cuộn chuột dài.
- **Huy hiệu Cập nhật OTA Trực tiếp trên Thanh Tiêu đề**:
  - Bổ sung `_OtaUpdateBadge` hiển thị trên app bar khi có bản cập nhật mới, bấm 1 chạm để mở ngay hộp thoại cập nhật.
- **Bảo toàn Dữ liệu Cấu hình trong Bộ Cài đặt**:
  - `install.bat` tự động sao lưu và khôi phục `config.json`, `config.ini`, `update_config.json`, và `logs/` khi cài đè.
  - `uninstall.ps1` mặc định giữ lại dữ liệu cấu hình khi gỡ bỏ, tránh mất thiết lập.
- **Tinh gọn Hàng Kiểm tra Chia sẻ & Chú thích Tài khoản Mạng**:
  - Gom nút "Kiểm tra kết nối chia sẻ" và chip hiển thị kết quả (icon xanh/đỏ + message) lên cùng một hàng ngang.
  - Thêm tiêu đề nhận diện rõ ràng `Xác thực mạng LAN (Tùy chọn)`.

## Kiểm chứng
- `dart format lib test`: code chuẩn định dạng.
- `flutter analyze`: 0 issues found.
- `flutter test`: 47/47 tests passed (100% passed).
- `flutter build windows --release`: biên dịch thành công.

## Artifact
- JA_MES_Tool_v2.10.0_Windows_x64.zip
- Bung sẵn toàn bộ ứng dụng portable trong `dist/`.
- Tự động cập nhật `dist/version.json` và `dist/SHA256SUMS.txt`.

