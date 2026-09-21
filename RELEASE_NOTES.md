TAG=v2.9.8
TITLE=JA MES Tool v2.9.8 — Tích hợp LAN OTA Update, Settings Tab 5 & Bento Glass Dialog
BODY=
## Thay đổi chính
- **Cơ chế cập nhật qua mạng nội bộ (LAN OTA Update)**: Tự động kiểm tra bản phát hành mới từ thư mục chia sẻ mạng LAN / UNC Share (`\\server\share\JA_MES_Tool`) hoặc thư mục ánh xạ.
- **Bộ so sánh SemVer chuẩn xác**: Hỗ trợ so khớp phiên bản ngữ nghĩa kèm số build (`2.9.8+22 > 2.9.7+21`), tránh lặp update và đảm bảo tính nhất quán.
- **Quy trình cập nhật nền Robocopy Hot-Swap**: Tự động tải/sao chép gói zip vào thư mục tạm, giải nén và kích hoạt PowerShell ngầm đồng bộ file mới bằng `robocopy`, tự khởi động lại ứng dụng không cần quyền Administrator.
- **Tab Cập nhật trong Cài đặt (Settings Tab 5)**: Cho phép cấu hình đường dẫn thư mục chia sẻ LAN, bật/tắt tự động kiểm tra khi khởi động, kiểm tra kết nối với trạng thái trực quan và nút "Kiểm tra ngay".
- **Hộp thoại cập nhật Bento Glassmorphic (`GlassUpdateDialog`)**: Hiển thị thẻ Bento với so sánh phiên bản, kích thước tệp, ngày phát hành, nhật ký thay đổi (`releaseNotes`), thanh tiến trình tải có phần trăm và nút thao tác trực quan.
- **Đa ngôn ngữ toàn diện**: Bổ sung đầy đủ chuỗi bản dịch Tiếng Việt, Tiếng Anh, Tiếng Trung cho toàn bộ các chức năng cập nhật.
- **Kiểm tra ngầm an toàn**: Chạy kiểm tra sau 3s khi ứng dụng khởi động mà không làm chậm giao diện, dọn dẹp timer an toàn trong `dispose()`.

## Kiểm chứng
- `dart format lib test`: code chuẩn định dạng.
- `flutter analyze`: 0 issues found.
- `flutter test`: 38/38 tests passed (bao gồm bộ unit test mới `test/ota_update_service_test.dart`).
- `flutter build windows --release`: biên dịch thành công.

## Artifact
- JA_MES_Tool_v2.9.8_Windows_x64.zip
- Bung sẵn toàn bộ ứng dụng portable trong `dist/`.
- Tự động cập nhật `dist/version.json` và `dist/SHA256SUMS.txt`.
