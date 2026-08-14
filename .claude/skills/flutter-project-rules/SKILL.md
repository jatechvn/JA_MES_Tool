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
5. **Hiệu ứng chuyển tiếp mượt mà (Smooth Transition Animations) & Hiệu năng:**
   - Ưu tiên animation implicit có sẵn của Flutter (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedAlign`, `AnimatedCrossFade`, `ScaleTransition`/`FadeTransition` trong `showGeneralDialog`) thay vì tự viết `AnimationController` thủ công — chi phí thấp, tự động interrupt/reverse mượt, ít code hơn.
   - Gom toàn bộ `Duration`/`Curve` dùng cho animation vào một file hằng số dùng chung (ví dụ `lib/modules/ui/motion.dart`) thay vì hard-code rải rác, để cảm giác chuyển động đồng nhất toàn app và dễ tinh chỉnh sau này.
   - Với danh sách dài render qua `ListView.builder` có hiệu ứng entrance (stagger fade/slide-in): PHẢI keyed bằng định danh nội dung ổn định (không dùng index thô), và lưu trạng thái "đã chạy animation" ở một `Set` sống trong State của widget cha (không phải trong chính item) — vì `ListView.builder` dispose Element khi item cuộn ra ngoài `cacheExtent`, nếu không track ở tầng cha thì cuộn qua lại sẽ làm animation bị replay liên tục, gây nhấp nháy khó chịu.
   - Chỉ bọc `AnimatedSwitcher`/`KeyedSubtree` đúng vùng thực sự cần transition (ví dụ nội dung tab/detail panel), không bọc animation lồng nhau nhiều lớp không cần thiết trên cùng một thay đổi state.
   - **BẮT BUỘC verify bằng Flutter DevTools thật sau khi thêm animation mới, không chỉ verify bằng mắt/screenshot:**
     1. Chạy `flutter run --profile -d windows` (hoặc platform tương ứng), lấy URL DevTools in ra ở console.
     2. Mở DevTools → tab **Performance**, bấm **Clear all** để xoá dữ liệu cũ.
     3. Thao tác trực tiếp với app để trigger đúng các animation vừa thêm (chuyển tab, cuộn list, mở/đóng dialog, đổi theme...).
     4. Click vào frame cao nhất trên biểu đồ, đọc **Frame Analysis**: tổng thời gian UI (Build+Layout+Paint) + Raster phải < 16.67ms (ngân sách 60fps) và không có frame màu đỏ (jank) hoặc đỏ đậm (Shader Compilation).
     5. Nếu Raster cao bất thường trong khi UI thấp → nghi ngờ animate màu nền/blur trên vùng lớn; vẫn chấp nhận được nếu còn trong ngân sách, nhưng phải đo lại mỗi khi thêm animation mới vào cùng khu vực đó.
