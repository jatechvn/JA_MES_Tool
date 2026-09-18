TAG=v2.9.6
TITLE=JA MES Tool v2.9.6
BODY=
## Thay đổi chính
- Thêm QueryQueue FIFO giới hạn mặc định 6 tác vụ song song cho Test Record,
  Barcode History, Component List và Component Trace; loại bỏ công việc trùng
  và chia sẻ kết quả SN Master đang xử lý.
- Bảo vệ stale result: các lần refresh/remove/re-add/clear/đổi credential vô
  hiệu hóa kết quả cũ, không để response đến muộn ghi đè trạng thái mới.
- Khôi phục bố cục cửa sổ gọn theo v2.9.5, giữ native Windows caption controls
  là bộ nút minimize/maximize/close duy nhất.
- Đồng bộ About, User Guide, README EN/VI/CN, CHANGELOG và version 2.9.6+20.
- Bổ sung test QueryQueue/concurrency và regression layout light/dark.

## Kiểm chứng
- `dart format lib test`, `flutter analyze`: đạt, không có lỗi.
- `flutter test`: 23/23 tests passed.
- `flutter build windows --release`: chờ chạy lại sau khi đồng bộ version.
- Chưa kiểm tra trực quan native caption controls, Windows IME và MES thật.

## Artifact
- JA_MES_Tool_v2.9.6_Windows_x64.zip
- ZIP: 29 entries, một thư mục mẹ; không chứa config.json/config.ini/logs hoặc thư mục staging.
- SHA256: F28EA4B6CA6535B5FA96A8E0F97C185D536A06FA6B202FE57BFB1DE05CD09064
