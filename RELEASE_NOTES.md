TAG=v2.11.1
TITLE=JA MES Tool v2.11.1 — Đồng bộ tiêu đề cửa sổ và metadata hiển thị tên ứng dụng JA MES Tool
BODY=
## Điểm nhấn chính
- **Đồng bộ Tiêu đề Cửa sổ (Window Title) Hiển thị Tên Ứng dụng**:
  - Khởi tạo Win32 Window với tiêu đề `JA MES Tool` trong `main.cpp` và `win32_window.cpp` trên mọi phiên bản Windows.
  - Bổ sung `windowManager.setTitle(title)` trong `window_helper.dart` trên Windows, bảo đảm tên ứng dụng luôn xuất hiện nhất quán trên thanh Taskbar, Task Manager và Alt+Tab thay vì hiển thị tên file `ja_mes_tool.exe`.
  - Đồng bộ `MaterialApp.title` hiển thị `appName`.
- **Chuẩn hóa Metadata File Thực thi (`Runner.rc`)**:
  - Cập nhật thông tin nhận diện nhị phân `FileDescription` và `ProductName` thành `JA MES Tool`.
  - Cập nhật `CompanyName` thành `JA Tech` và `LegalCopyright` bản quyền chính thức `Copyright (C) 2026 JA Tech. All rights reserved.`.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 65/65 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.11.1_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
