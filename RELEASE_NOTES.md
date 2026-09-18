TAG=v2.9.7
TITLE=JA MES Tool v2.9.7 — Bổ sung Trường Barcode History, Card SN 2 Dòng & Kính Mờ Bounce Marquee
BODY=
## Thay đổi chính
- Bổ sung đầy đủ các trường dữ liệu Barcode History & WIP Components từ CloudMES API: Line (chuyền), Internal SN, Equipment No, Product Version, Plan No, Remark và Location.
- Mở rộng chức năng xuất báo cáo CSV cho Barcode History và WIP Components với đầy đủ các trường mới.
- Thiết kế lại hàng SN sidebar bên trái thành card kính mờ 2 dòng (dense 2-line glass card): dòng 1 hiển thị status icon, SN chính, badge đếm và nút thao tác; dòng 2 hiển thị chip alternate SN rút gọn (`⇋ $alternateSn`) và badge trạm kế tiếp (`Next: $nextStation`).
- Tinh giản thanh header kết quả bên phải: loại bỏ text dài bị cắt cụt `Records for SN:` và `Next:`, chuyển thành thanh công cụ tìm kiếm và lọc chuyên dụng.
- Tối ưu độ đục khung lựa chọn SN theo chuẩn `JA_IQ5_Flash`: sử dụng `Color.alphaBlend` cho màu kính mờ trong suốt thanh thoát trên cả 2 giao diện Sáng (Light) và Tối (Dark).
- Tích hợp chế độ cuộn bật nảy `BounceMarqueeText` (asymmetric ping-pong marquee) cho mã SN dài, Alternate SN, Next Station badge (`PillBadge(useMarquee: true)`) và Trace CSN, đảm bảo không bị tràn giao diện, 0% CPU khi chữ vừa vặn.
- Khắc phục lỗi thiếu biến PowerShell trong file `build.bat` khi tạo shortcut `.Release.lnk`.
- Bổ sung unit và widget tests (`test/barcode_history_fields_test.dart`, `test/sn_queue_marquee_test.dart`), đạt 100% test pass (28/28).

## Kiểm chứng
- `dart format lib test`, `flutter analyze`: đạt, 0 issues found.
- `flutter test`: 28/28 tests passed.
- `flutter build windows --release`: hoàn thành trong Release mode.
- Đã xuất và kiểm chứng trực quan ảnh chụp giao diện Sáng và Tối (`restored_light.png`, `restored_dark.png`).

## Artifact
- JA_MES_Tool_v2.9.7_Windows_x64.zip
- Bung sẵn toàn bộ ứng dụng portable trong `dist/`.
- SHA256: 88D17BCA42B460C1C1F19C89C3C919EE2E535095A53E4F0488DD8D6253A701FC

