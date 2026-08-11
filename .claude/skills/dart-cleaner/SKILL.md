---
name: dart-cleaner
description: Kỹ năng tự động dọn dẹp, định dạng và tối ưu mã nguồn Dart/Flutter. Kích hoạt khi người dùng muốn dọn dẹp code, fix lỗi linter hoặc refactor code.
---

# Dart Cleaner Skill

Kỹ năng này giúp dọn dẹp, chuẩn hóa và tối ưu hóa mã nguồn dự án Flutter/Dart của người dùng.

## Quy trình thực hiện (Dành cho Agent)
1. **Phân tích lỗi (Analyze):** Chạy lệnh `dart analyze` hoặc `flutter analyze` để phát hiện các lỗi cảnh báo (linter warnings, unused imports, missing const...).
2. **Định dạng code (Format):** Chạy lệnh `dart format .` để tự động căn chỉnh code theo chuẩn Dart.
3. **Tự động sửa lỗi (Auto-Fix):** Chạy lệnh `dart fix --apply` để tự động sửa các lỗi linter có thể tự fix được.
4. **Refactor thủ công (Nếu cần):** Dựa vào kết quả analyze chưa fix được, sử dụng công cụ sửa code (code edit tools) để fix nốt các lỗi còn lại (ví dụ: thêm từ khóa `const`, xóa code thừa).
5. **Báo cáo:** Liệt kê các thay đổi đã thực hiện và gợi ý người dùng kiểm tra lại mã nguồn.
