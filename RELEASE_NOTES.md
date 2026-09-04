TAG=v2.9.4
TITLE=JA MES Tool v2.9.4
BODY=
## Tóm tắt
- Phát hành JA MES Tool v2.9.4 cho Windows x64.
- Tập trung vào màu trạng thái SN chính xác khi Test Record rỗng nhưng các view lịch sử vẫn có dữ liệu.

## Thay đổi chính
- Khi Test Record không có dữ liệu nhưng Barcode History hoặc Component List có dữ liệu, SN trong sidebar chuyển sang màu vàng và dùng biểu tượng cảnh báo.
- Chỉ hiển thị màu đỏ khi Test Record, Barcode History và Component List đều đã tải xong nhưng không có dữ liệu.
- Trong lúc Barcode History hoặc Component List còn đang tải, trạng thái SN không bị đánh dấu đỏ sớm.
- Đồng bộ version/docs/About/User Guide/README/CHANGELOG cho v2.9.4.

## Kiểm chứng
- `dart format .`
- `flutter analyze`
- `flutter test` — 11/11 tests passed.
- `flutter build windows --release`
- ZIP kiểm tra 1 top-level folder, không chứa `config.json`, `config.ini`, `logs/`, `dist/`, `dist_pack/`, hoặc `backup/`.

## Artifact
- `JA_MES_Tool_v2.9.4_Windows_x64.zip`
- SHA256: `B48E8090919DA6B7BDEAEE65FFDB92765DB609B16261AB02519E4128F3D63DA5`
