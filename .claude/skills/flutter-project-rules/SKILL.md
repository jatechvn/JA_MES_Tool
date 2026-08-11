---
name: flutter-project-rules
description: Kỹ năng đóng vai trò như một chuyên gia Flutter, áp đặt các quy tắc về Clean Architecture, Null Safety và tối ưu hiệu năng. Kích hoạt khi yêu cầu agent viết tính năng mới hoặc refactor.
---

# Flutter Project Rules Skill

Kỹ năng này hoạt động như hệ thống "luật lệ ngầm" (System Prompt), giúp định hình lại tư duy của Agent để code như một Senior Flutter Developer.

## Constraints & Rules (Quy tắc bắt buộc dành cho Agent)
Khi thực hiện bất kỳ thay đổi mã nguồn nào, Agent PHẢI tuân thủ các quy tắc sau:
1. **Tối ưu UI (Performance):**
   - BẮT BUỘC sử dụng từ khóa `const` constructor cho các Widget để tránh rebuild không cần thiết.
   - Không được lồng ghép (nesting) quá 4 cấp Widget. Nếu sâu hơn, phải Extract ra thành các StatelessWidget riêng biệt.
2. **Kiến trúc & Luồng dữ liệu:**
   - Không được nhét logic xử lý dữ liệu (Business Logic) trực tiếp vào trong hàm `build()` của Widget.
   - Giữ nguyên kiến trúc hiện tại của người dùng (Riverpod, Bloc, hay MVVM) không được tự ý đổi sang pattern khác.
3. **Sự An Toàn (Safety):**
   - Xử lý Null Safety một cách cẩn thận, không lạm dụng toán tử `!` ép kiểu mù quáng.
   - Không bao giờ được phép tự ý chạy lệnh `flutter clean` hay xóa các file quan trọng mà không có sự cho phép rõ ràng của người dùng.
4. **Quản lý Thư viện:**
   - Trước khi đề xuất cài thêm package mới vào `pubspec.yaml`, phải đảm bảo package đó có null-safety và là bản ổn định (stable) mới nhất.
