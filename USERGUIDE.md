# 📘 Hướng dẫn Sử dụng JA MES Tool v2.9.8

> **Ứng dụng Windows Desktop hiệu năng cao tra cứu dữ liệu kiểm thử, lịch sử công đoạn và truy vết linh kiện Foxconn CloudMES với giao diện Bento Glassmorphism.**

---

## 📑 Mục lục
1. [Giới thiệu & Cài đặt](#1-giới-thiệu--cài-đặt)
2. [Thiết lập Tài khoản & Đồng bộ Token (CDP Sync)](#2-thiết-lập-tài-khoản--đồng-bộ-token-cdp-sync)
3. [Tra cứu Dữ liệu & Quản lý Hàng đợi SN](#3-tra-cứu-dữ-liệu--quản-lý-hàng-đợi-sn)
4. [Bảng Lệnh Nhanh (Command Palette - Ctrl+K)](#4-bảng-lệnh-nhanh-command-palette---ctrlk)
5. [Hệ thống Tự động Cập nhật qua Mạng nội bộ (LAN OTA Update)](#5-hệ-thống-tự-động-cập-nhật-qua-mạng-nội-bộ-lan-ota-update)
6. [Tùy chỉnh Giao diện Kính mờ (Bento Glassmorphism)](#6-tùy-chỉnh-giao-diện-kính-mờ-bento-glassmorphism)
7. [Nhập/Xuất Báo cáo Excel & CSV](#7-nhậpxuất-báo-cáo-excel--csv)

---

## 1. Giới thiệu & Cài đặt

### Yêu cầu hệ thống
- Hệ điều hành: Windows 10 / Windows 11 (64-bit)
- Trình duyệt: Google Chrome hoặc Microsoft Edge (dùng để đồng bộ Token tự động)
- Kết nối mạng: Truy cập được mạng nội bộ nhà máy hoặc VPN Foxconn CloudMES

### Cài đặt nhanh (Portable)
1. Tải gói phát hành `JA_MES_Tool_v2.9.8_Windows_x64.zip` từ thư mục chia sẻ nội bộ hoặc bản phát hành.
2. Giải nén toàn bộ tệp tin vào một thư mục làm việc cố định (ví dụ: `D:\Tools\JA_MES_Tool`).
3. Khởi chạy trực tiếp `ja_mes_tool.exe` mà không cần quyền Quản trị viên (Administrator).

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

## 5. Hệ thống Tự động Cập nhật qua Mạng nội bộ (LAN OTA Update)

Phiên bản **v2.9.8** bổ sung tính năng kiểm tra và cập nhật ứng dụng tự động qua mạng nội bộ:

### Cấu hình đường dẫn chia sẻ LAN
1. Vào **Cài đặt ⚙️** -> Chọn tab **Cập nhật (OTA)** (Tab 5).
2. Nhập đường dẫn thư mục chia sẻ mạng (UNC Path hoặc ổ đĩa mạng):
   - Ví dụ: `\\10.81.141.226\temp\JA_MES_Tool` hoặc `Z:\Releases\JA_MES_Tool`.
3. Nhập tài khoản/mật khẩu mạng nếu thư mục chia sẻ yêu cầu xác thực.
4. Chọn chu kỳ tự động kiểm tra:
   - **Khi khởi động (Khuyên dùng)**: Tự động kiểm tra ngầm sau 3 giây khi bật ứng dụng.
   - **Hàng ngày** hoặc **Hàng tuần**.
   - **Tắt tự động kiểm tra** (nếu chỉ muốn kiểm tra thủ công).

### Quá trình cập nhật Hot-Swap
- Khi có bản phát hành mới hơn phiên bản hiện tại, hộp thoại kính mờ **Cập nhật Phần mềm** sẽ xuất hiện.
- Hộp thoại hiển thị phiên bản mới, kích thước gói nén, ngày phát hành và chi tiết ghi chú thay đổi (`Release Notes`).
- Nhấn **Cập nhật ngay**:
  1. Ứng dụng tải file `.zip` vào thư mục tạm `%TEMP%`.
  2. Tự động kích hoạt kịch bản PowerShell nền sử dụng `robocopy` để hoán đổi an toàn các file nhị phân.
  3. Tự động bảo toàn dữ liệu cá nhân của bạn (`config.json`, `logs/`).
  4. Khởi động lại ứng dụng mới mà không cần cấp quyền Administrator.

---

## 6. Tùy chỉnh Giao diện Kính mờ (Bento Glassmorphism)

JA MES Tool tích hợp bộ điều chỉnh hiệu ứng kính mờ 4 trục độc quyền:
1. Vào **Cài đặt ⚙️** -> Chọn tab **Nâng cao**.
2. Kéo các thanh trượt với chế độ xem trước trực tiếp (Live-Preview):
   - **Độ mờ thẻ Bento (Card Blur)**: Điều chỉnh từ `0px` (trong suốt hoàn toàn) đến `40px` (mờ mịn sâu).
   - **Độ đục thẻ Bento (Card Opacity)**: Tinh chỉnh nền thẻ từ nhẹ nhàng sang đậm nét.
   - **Độ mờ Hộp thoại (Dialog Blur)**: Tùy biến độ nhòe nền đằng sau các popup.
   - **Độ đục Hộp thoại (Dialog Opacity)**: Đảm bảo độ tương phản chữ rõ nét khi hiển thị dialog.
3. Nhấn nút **Mặc định** nếu muốn khôi phục về cấu hình gốc tiêu chuẩn của ứng dụng.

---

## 7. Nhập/Xuất Báo cáo Excel & CSV

- **Export CSV**: Nhấn nút **Xuất CSV** trên thanh công cụ của từng tab để trích xuất toàn bộ dữ liệu đang hiển thị ra file CSV chuẩn UTF-8 kèm BOM (mở trực tiếp bằng Excel không bao giờ bị lỗi font tiếng Việt/tiếng Trung).
- **Template**: Nhấn **Tải mẫu CSV** để lấy file mẫu cấu trúc đúng chuẩn dùng cho việc nhập liệu hàng loạt.
- Tự động bỏ qua các dòng tiêu đề trùng lặp khi import danh sách SN.

---

*Bản quyền thuộc về JA Tech VN. Mọi thắc mắc xin liên hệ đội ngũ phát triển.*
