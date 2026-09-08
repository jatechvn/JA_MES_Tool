TAG=v2.9.5
TITLE=JA MES Tool v2.9.5
BODY=
## Thay đổi chính
- Áp dụng Command Palette từ JA_Mini_Showcase: Material trong suốt, card theo theme, border/shadow/clip riêng và một lớp blur nền.
- Điều chỉnh nền phủ light mode; giữ tìm kiếm, điều hướng bàn phím và focus sau hiệu ứng mở.
- Đồng bộ About/User Guide, README EN/VI/CN, CHANGELOG và version 2.9.5+19.
- Bổ sung widget test mở bảng lệnh và chọn command.

## Kiểm chứng
- `dart format .`, `flutter analyze`: đạt, không có lỗi.
- `flutter test`: 11/11 tests passed.
- `flutter build windows --release`: thành công.
- Chưa kiểm tra trực quan với Windows IME.

## Artifact
- JA_MES_Tool_v2.9.5_Windows_x64.zip
- ZIP: 31 entries, một thư mục mẹ; không chứa config.json/config.ini/logs hoặc thư mục staging.
- SHA256: 6F39A01FC2940CFD644173BAA8C82FEA857E310E10924AEBA23475D19F75007C
