TAG=v2.13.2
TITLE=JA MES Tool v2.13.2 — Tối ưu hóa đóng băng khung hình cấp Engine (PowerFrameGate & PowerTickerGate) và đối soát trạng thái cửa sổ Native (WindowActivityMonitor)
BODY=
## Điểm nhấn chính
- **Cổng Đóng băng Khung hình & Ticker cấp Engine (`PowerFrameGate` + `PowerTickerGate`) (`power_binding.dart`, `main.dart`)**:
  - Bổ sung `PowerWidgetsBinding` (`PowerFrameGate`) khóa `framesEnabled` khi cửa sổ không active, bị thu nhỏ hoặc đang ở chế độ ngủ rảnh tay (`Idle Sleep`), giúp ngắt triệt để chu kỳ vẽ khung hình thừa của Flutter Engine mà không ảnh hưởng tới các `Timer` hay tác vụ nền MES/OTA.
  - Tích hợp `PowerTickerGate` (`TickerMode`) ở cấp ứng dụng để tạm dừng toàn bộ `Ticker` con ngay khi chuyển sang trạng thái nghỉ và tự động đánh thức khung hình (`scheduleFrame()`) khi người dùng thao tác trở lại.
- **Bộ Giám sát Trạng thái Cửa sổ Native (`WindowActivityMonitor`) (`window_activity_monitor.dart`, `app_power_manager.dart`, `main_window.dart`)**:
  - Đối soát trực tiếp trạng thái thực của cửa sổ (`isVisible`, `isMinimized`, `isFocused`) kèm cơ chế bảo vệ `_epoch` và hàm `applyNativeWindowState` không làm reset bộ đếm `idleTimer` khi trạng thái giữ nguyên.
  - Ngăn chặn hiện tượng tự kích hoạt lại animation khi mở khóa máy Windows (`AppLifecycleState.resumed` khi cửa sổ không ở tiền cảnh) và tự động khôi phục các sự kiện focus/visibility bị bỏ lỡ sau khi mở khóa màn hình.
  - Bổ sung các bộ kiểm thử `test/power_frame_gate_test.dart`, `test/power_ticker_gate_test.dart`, `test/window_activity_monitor_test.dart` và cập nhật `test/app_power_manager_test.dart`.

## Kiểm chứng & Đóng gói
- `dart format .`: Chuẩn hóa 100% định dạng mã nguồn.
- `flutter analyze`: Đạt 0 issues found.
- `flutter test`: 146/146 ca kiểm thử vượt qua thành công (100% pass).
- `flutter build windows --release`: Biên dịch hoàn chỉnh `ja_mes_tool.exe`.

### Cài đặt
Giải nén toàn bộ gói `JA_MES_Tool_v2.13.2_Windows_x64.zip` và chạy `install.bat` hoặc khởi chạy trực tiếp `ja_mes_tool.exe`.
