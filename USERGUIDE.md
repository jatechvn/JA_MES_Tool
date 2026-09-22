# 📘 Hướng dẫn Sử dụng JA MES Tool v2.10.0

> **Ứng dụng Windows Desktop hiệu năng cao tra cứu dữ liệu kiểm thử, lịch sử công đoạn và truy vết linh kiện Foxconn CloudMES với giao diện Bento Glassmorphism.**

---

## 📑 Mục lục
1. [Giới thiệu & Cài đặt](#1-giới-thiệu--cài-đặt)
2. [Thiết lập Tài khoản & Đồng bộ Token (CDP Sync)](#2-thiết-lập-tài-khoản--đồng-bộ-token-cdp-sync)
3. [Tra cứu Dữ liệu & Quản lý Hàng đợi SN](#3-tra-cứu-dữ-liệu--quản-lý-hàng-đợi-sn)
4. [Bảng Lệnh Nhanh (Command Palette - Ctrl+K)](#4-bảng-lệnh-nhanh-command-palette---ctrlk)
5. [Cài đặt 3 Tab Bento & Tùy chỉnh Kính mờ (Glassmorphism)](#5-cài-đặt-3-tab-bento--tùy-chỉnh-kính-mờ-glassmorphism)
6. [Hệ thống Tự động Cập nhật qua Mạng nội bộ (LAN OTA Update)](#6-hệ-thống-tự-động-cập-nhật-qua-mạng-nội-bộ-lan-ota-update)
7. [Nhập/Xuất Báo cáo Excel & CSV](#7-nhậpxuất-báo-cáo-excel--csv)

---

## 1. Giới thiệu & Cài đặt

### Yêu cầu hệ thống
- Hệ điều hành: Windows 10 / Windows 11 (64-bit)
- Trình duyệt: Google Chrome hoặc Microsoft Edge (dùng để đồng bộ Token tự động)
- Kết nối mạng: Truy cập được mạng nội bộ nhà máy hoặc VPN Foxconn CloudMES

### Cách 1: Cài đặt chuẩn Windows không cần Admin (Khuyên dùng)
1. Tải gói phát hành `JA_MES_Tool_v2.10.0_Windows_x64.zip`.
2. Giải nén và nhấp đúp chạy file **`install.bat`**.
3. Trình cài đặt tự động triển khai vào `%LOCALAPPDATA%\Programs\JA_MES_Tool`, tạo Shortcut ngoài Desktop và Start Menu, tích hợp mục gỡ cài đặt chuẩn xác trong Windows Settings / Control Panel (tự động bảo toàn cấu hình người dùng).
4. Khi muốn gỡ cài đặt, chạy **`uninstall.bat`** hoặc gỡ trực tiếp qua Windows Installed Apps.

### Cách 2: Chạy trực tiếp Portable
1. Giải nén toàn bộ tệp tin vào một thư mục làm việc cố định (ví dụ: `D:\Tools\JA_MES_Tool`).
2. Khởi chạy trực tiếp `ja_mes_tool.exe` mà không cần quyền Quản trị viên (Administrator).

---

## 2. Thiết lập Tài khoản & Đồng bộ Token (CDP Sync)

Để ứng dụng có thể gửi truy vấn tới API CloudMES, bạn cần có Token hợp lệ. JA MES Tool hỗ trợ lấy tự động 100% qua cơ chế chặn bắt gói tin mạng CDP:

1. Mở menu **Cài đặt ⚙️** (nhấn biểu tượng bánh răng ở góc trên bên phải hoặc phím tắt `Ctrl+,`).
2. Tại tab **Kết nối & Token**:
   - Chọn trình duyệt mong muốn: **Google Chrome** hoặc **Microsoft Edge**.
   - Nhấn **Đồng bộ tự động qua Trình duyệt**.
   - Cửa sổ trình duyệt sẽ tự động bật lên và điều hướng tới trang đăng nhập Foxconn CloudMES.
   - Tiến hành đăng nhập bằng tài khoản nội bộ của bạn.
   - Khi đăng nhập thành công, app sẽ tự động trích xuất `Token`, `UUID`, `Operation-ID`, `Cookie` và cập nhật vào cấu hình.
   - Biểu tượng huy hiệu xanh lá `Verified` sẽ xác nhận kết nối thành công.

---

## 3. Tra cứu Dữ liệu & Quản lý Hàng đợi SN

### Thêm Serial Number
- Nhập SN trực tiếp vào ô tìm kiếm ở thanh bên trái và nhấn Enter.
- Nhập hàng loạt SN từ clipboard hoặc dán danh sách ngăn cách bằng dấu phẩy, khoảng trắng hoặc xuống dòng.
- Nhập từ file danh sách bằng nút **Import CSV**.

### Các chế độ xem dữ liệu
1. **Test Record**: Hiển thị bảng chi tiết kết quả kiểm tra từng trạm kiểm thử của sản phẩm (Trạm test, Kết quả PASS/FAIL, Thời gian kiểm tra, Kỹ thuật viên, Mã lỗi...).
2. **Barcode History**: Xem toàn bộ lịch sử di chuyển công đoạn từ đầu đến cuối (Mã line, Thiết bị EQP, Phiên bản sản phẩm, Kế hoạch Plan No, Ghi chú...).
3. **Component List (WIP BOM)**: Xem danh sách linh kiện đã được bắn gắn vào sản phẩm (Mã linh kiện, Tên linh kiện, Vị trí Location, Mã nhà cung cấp, Thời gian gắn...).
4. **Component Trace**: Tra cứu ngược từ mã linh kiện để tìm Serial Number sản phẩm hoàn chỉnh đang chứa linh kiện đó.

---

## 4. Bảng Lệnh Nhanh (Command Palette - Ctrl+K)

Bảng Lệnh Nhanh mang trải nghiệm tìm kiếm tiện lợi như Spotlight / VS Code:
- Nhấn tổ hợp phím **Ctrl + K** (hoặc **Cmd + K**).
- Gõ từ khóa tìm kiếm:
  - Nhảy nhanh đến các tab: `Test Record`, `Barcode History`, `WIP BOM`, `Component Trace`.
  - Thực hiện tác vụ: `Làm mới tất cả`, `Xóa danh sách`, `Xuất file CSV`, `Kiểm tra cập nhật`.
  - Mở các cài đặt: `Đổi giao diện Sáng/Tối`, `Chỉnh độ mờ kính`, `Mở cài đặt OTA`.
- Dùng phím mũi tên `↑` / `↓` để duyệt danh sách và nhấn `Enter` để thực thi ngay.

---

## 5. Cài đặt 3 Tab Bento & Tùy chỉnh Kính mờ (Glassmorphism)

Từ phiên bản **v2.9.9**, menu **Cài đặt ⚙️** được hợp nhất thành 3 tab Bento Grid rộng rãi, chống tràn viền và giữ vị trí cuộn độc lập:

1. **Tab 1: CloudMES & CDP (`tab_mes_api`)**:
   - Tích hợp tính năng đồng bộ tự động Token, UUID, Operation-ID, Cookie qua trình duyệt (Chrome/Edge).
   - Ô nhập thủ công thông số MES API, nút xác minh kết nối trực tiếp và huy hiệu trạng thái xanh/vàng.
2. **Tab 2: Giao diện & Kính mờ (`tab_display_glass`)**:
   - **Chọn ngôn ngữ**: Chuyển đổi linh hoạt giữa Tiếng Việt 🇻🇳, English 🇬🇧 và 中文 🇨🇳.
   - **Graphic Performance Tier**: Chọn cấu hình đồ họa (Auto, Ultra 120 FPS, Balanced 60 FPS, Lite chống lag) — tự động cập nhật hệ thống thanh trượt kính mờ tương ứng.
   - **Graphic Performance Tier**: Chọn cấu hình đồ họa (Auto, Ultra 120 FPS, Balanced 60 FPS, Lite chống lag) — tự động cập nhật hệ thống thanh trượt kính mờ tương ứng.
   - **Bộ tinh chỉnh Kính mờ 4 thanh trượt 2 Cột Bento (Live-Preview)**: Tùy biến Card Blur & Opacity, Dialog Blur & Opacity theo thời gian thực theo bố cục 2 cột cân đối, kèm nút **Mặc định** và khôi phục khi hủy bỏ.
3. **Tab 3: Thông tin & Cập nhật (`tab_about_updates`)**:
   - Thẻ thông tin phiên bản, trạng thái cập nhật LAN OTA và nút **Kiểm tra cập nhật ngay**.
   - Cấu hình máy chủ chia sẻ mạng nội bộ (UNC path, 4 nút chọn nhanh chu kỳ kiểm tra, tài khoản mạng tùy chọn và nút kiểm tra kết nối mạng tích hợp).
   - Thẻ thông số kỹ thuật hệ thống (Engine, Architecture, CDP Status, Hardware Profile, License) và nút mở nhanh thư mục `logs/` và thư mục cài đặt.

---

## 6. Hệ thống Tự động Cập nhật qua Mạng nội bộ (LAN OTA Update)

### Cấu hình đường dẫn chia sẻ LAN
1. Vào **Cài đặt ⚙️** -> Chọn tab **Thông tin & Cập nhật** (Tab 3).
2. Nhập đường dẫn thư mục chia sẻ mạng (UNC Path hoặc ổ đĩa mạng):
   - Ví dụ: `\\10.81.141.226\temp\JA_MES_Tool` hoặc `Z:\Releases\JA_MES_Tool`.
   - Nhấn nút **Kiểm tra** cạnh đường dẫn để xác thực quyền truy cập ngay lập tức.
3. Nhập tài khoản/mật khẩu mạng nếu thư mục chia sẻ yêu cầu xác thực riêng.
4. Chọn chu kỳ tự động kiểm tra bằng **4 nút Bento chọn nhanh**:
   - **Khi khởi động (Khuyên dùng)**: Tự động kiểm tra ngầm sau 3 giây khi bật ứng dụng.
   - **Hàng ngày** hoặc **Hàng tuần**.
   - **Tắt**: Tắt tự động kiểm tra định kỳ (chỉ kiểm tra thủ công).

### Thông báo cập nhật trên Thanh tiêu đề (Live Badge)
- Khi phát hiện có bản cập nhật mới, một badge phát sáng **Cập nhật** sẽ xuất hiện trực tiếp trên thanh tiêu đề ứng dụng (cạnh nút Settings).
- Nhấp vào badge để mở ngay hộp thoại chi tiết cập nhật mà không cần vào menu cài đặt.

### Quá trình cập nhật Hot-Swap
- Khi có bản phát hành mới hơn phiên bản hiện tại, hộp thoại kính mờ **Cập nhật Phần mềm** sẽ xuất hiện.
- Hộp thoại hiển thị phiên bản mới, kích thước gói nén, ngày phát hành và chi tiết ghi chú thay đổi (`Release Notes`).
- Nhấn **Cập nhật ngay**:
  1. Ứng dụng tải file `.zip` vào thư mục tạm `%TEMP%`.
  2. Tự động kích hoạt kịch bản PowerShell nền sử dụng `robocopy` để hoán đổi an toàn các file nhị phân.
  3. Tự động bảo toàn dữ liệu cấu hình và lịch sử cá nhân của bạn (`config.json`, `config.ini`, `update_config.json`, `logs/`).
  4. Khởi động lại ứng dụng mới mà không cần cấp quyền Administrator.

---

## 7. Nhập/Xuất Báo cáo Excel & CSV

- **Export CSV**: Nhấn nút **Xuất CSV** trên thanh công cụ của từng tab để trích xuất toàn bộ dữ liệu đang hiển thị ra file CSV chuẩn UTF-8 kèm BOM (mở trực tiếp bằng Excel không bao giờ bị lỗi font tiếng Việt/tiếng Trung).
- **Template**: Nhấn **Tải mẫu CSV** để lấy file mẫu cấu trúc đúng chuẩn dùng cho việc nhập liệu hàng loạt.
- Tự động bỏ qua các dòng tiêu đề trùng lặp khi import danh sách SN.

---

*Bản quyền thuộc về JA Tech VN. Mọi thắc mắc xin liên hệ đội ngũ phát triển.*
