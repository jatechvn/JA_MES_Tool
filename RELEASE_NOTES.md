TAG=v2.9.3
TITLE=JA MES Tool v2.9.3
BODY=
## Tóm tắt
- Phát hành JA MES Tool v2.9.3 cho Windows x64.
- Tập trung vào fallback Test Record rỗng sang Barcode History đúng ngữ cảnh, mặc định ngôn ngữ lần đầu theo Windows locale, và polish Command Palette.

## Thay đổi chính
- Test Record chỉ tự fallback sang Barcode History khi app mới load danh sách SN, người dùng vừa nhập/tìm SN mới, hoặc người dùng refresh khi đang ở tab Test Record.
- Khi người dùng chỉ bấm quay lại tab Test Record hoặc chọn SN đã cache, app giữ nguyên tab thay vì chuyển đi quá nhanh.
- Lần mở app đầu tiên không có `lang` đã lưu sẽ tự chọn ngôn ngữ theo Windows locale: `vi`, `cn`, hoặc `en`.
- Command Palette dùng đúng Dialog blur/opacity setting và delay focus nhẹ để tránh artifact gạch chân IME trên Windows.
- Đồng bộ version/docs/About/User Guide/README/CHANGELOG cho v2.9.3.

## Kiểm chứng
- `dart format .`
- `flutter analyze`
- `flutter test` — 8/8 tests passed.
- `flutter build windows --release`
- ZIP kiểm tra 1 top-level folder, không chứa `config.json`, `config.ini`, `logs/`, `dist/`, `dist_pack/`, hoặc `backup/`.

## Artifact
- `JA_MES_Tool_v2.9.3_Windows_x64.zip`
- SHA256: `1E6D7521CF054AFC8904227E2D8D069EE9D21AE7261069B6BBC73FF420E41A00`
