# 🤖 JA MES Test Record Tool v2.3.0 - Tiếng Việt

<p align="center">
  <br>
  <i><b>Ứng dụng desktop hiệu năng cao phát triển bằng Dart & Flutter giúp tự động hóa tra cứu, kiểm tra và xuất báo cáo dữ liệu kiểm thử từ hệ thống Foxconn CloudMES.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/phien_ban-2.3.0-blue.svg" alt="Phiên bản 2.3.0">
  <img src="https://img.shields.io/badge/nen_tang-Windows%20x64-0078D6.svg" alt="Nền tảng Windows">
  <img src="https://img.shields.io/badge/flutter-3.x-02569B.svg" alt="Flutter 3.x">
</p>

<p align="center">
  <a href="../README.md">🇺🇸 English</a> • 
  <b>🇻🇳 Tiếng Việt</b> • 
  <a href="README.zh-CN.md">🇨🇳 中文</a>
</p>

---

## 🌟 Giới thiệu

**JA MES Test Record Tool** là phần mềm chuyên dụng được thiết kế nhằm tối ưu hóa quy trình kiểm tra số Serial Number (SN), trích xuất lịch sử trạm test và xuất báo cáo từ nền tảng API **Foxconn CloudMES**.

Được thiết kế tối ưu cho kỹ sư kiểm thử và đội ngũ QA, ứng dụng mang đến khả năng tra cứu song song siêu tốc, tự động đồng bộ Token qua trình duyệt (CDP Interception) và giao diện phẳng Solid hiện đại.

---

## 💡 Tính năng nổi bật (v2.3.0)

- ⚡ **Tự động Cảnh báo Popup Token Hết Hạn trên Startup**: Phát hiện Token hết hạn ngay khi mở app và tự động bật Cửa sổ Popup đồng bộ 2 bước.
- 🌐 **Tương thích Đa trình duyệt Chrome & Microsoft Edge**: Tích hợp bộ cờ cách ly luồng chống treo/đứng hình cửa sổ Đăng nhập Edge (`--disable-features=msEdgeStartupBoost...`).
- 🛡️ **Huy hiệu Xác thực Kết nối Mới (🛡️)**: Biểu tượng khiên xác thực `Icons.verified_outlined` trực quan ở chân trang Cài đặt.
- 🔄 **Tự động Tra cứu lại Hàng đợi khi Lưu**: Tự động xóa các lỗi hết hạn Token cũ (401) và tra cứu lại toàn bộ danh sách SN trong hàng đợi khi bấm Save.
- ⚡ **Hàng đợi tra cứu SN song song**: Xử lý tra cứu danh sách SN nhanh chóng theo cơ chế bất đồng bộ.
- 📄 **Nhập & Xuất file CSV thông minh**: Tự động bỏ qua các dòng tiêu đề (chứa chữ `"SN"`) và xuất báo cáo CSV chi tiết.
- 🌐 **Đồng bộ Token tự động qua CDP**: Lấy chính xác 100% các thông số **Token**, **UUID**, **Operation-ID**, và **Cookie** thực tế từ lưu lượng mạng trình duyệt.
- 🛠️ **Bộ lọc & Làm sạch dữ liệu Header**: Tự động cắt bỏ ký tự xuống dòng ẩn (`\r\n`), khoảng trắng và dấu ngoặc kép thừa.
- 📋 **Quản lý Nhật ký hệ thống (Logs)**: Ghi vết theo ngày và tự động xóa các file log cũ quá 7 ngày mỗi khi khởi động.
- 🎨 **Giao diện Đa ngôn ngữ & Solid**: Hỗ trợ Light/Dark Mode và chuyển đổi 3 ngôn ngữ (**Tiếng Việt**, **Tiếng Anh**, **Tiếng Trung**).

---

## 📸 Hình ảnh Giao diện Ứng dụng

<p align="center">
  <img src="../docs/screenshots/2026-07-26_231301.png" alt="Giao diện Cài đặt với Huy hiệu Xác thực kết nối mới & Thẻ đồng bộ 2 bước" width="850">
  <br><br>
  <img src="../docs/screenshots/2026-07-26_231317.png" alt="Cửa sổ Popup Cảnh báo Token Hết Hạn tự động trên Startup" width="850">
</p>

---

## 🖥️ Hướng dẫn sử dụng chi tiết

### 1. Thêm danh sách SN
* **Thêm đơn lẻ**: Nhập SN vào ô ở cột bên trái rồi ấn **Enter** hoặc bấm nút **[+]**.
* **Nhập theo lô (CSV)**: Bấm nút **[Tải Mẫu]** để lấy file mẫu. Điền SN vào file rồi bấm **[Nhập (Import)]**. Dòng tiêu đề chứa chữ `"SN"` sẽ tự động bị bỏ qua.

### 2. Tự động lấy Token từ Trình duyệt (Quy trình 2 bước CDP)
1. Mở **Cài đặt ⚙️** (hoặc thông qua Cửa sổ Popup cảnh báo Token hết hạn tự động khi vừa khởi động).
2. **Bước 1**: Nhấn nút **[1. Mở trình duyệt]** để mở Chrome hoặc Microsoft Edge.
3. Đăng nhập tài khoản MES của bạn trên trang web.
4. **Bước 2**: Nhấn nút **[2. Lấy Token]**. Phần mềm sẽ dùng cơ chế CDP Network Interception để bắt chính xác 100% **Token**, **UUID**, **Operation-ID** và **Cookie**.
5. Nhấn **Lưu** để tự động dọn dẹp màn hình lỗi cũ và tra cứu lại toàn bộ danh sách SN trong hàng đợi.

### 3. Kiểm tra kết nối
* Đèn báo trạng thái bên cạnh tiêu đề **"Cài đặt"**:
  - 🟢 **Đã kết nối**: Token hợp lệ và kết nối tới máy chủ MES thành công.
  - 🟡 **Kiểm tra**: Token hết hạn hoặc chưa được cấp quyền (401).
* Token được tự động kiểm tra lại cứ mỗi **3 phút**.
* Nhấn **Icon Huy hiệu Xác thực (🛡️)** trong Cài đặt để kiểm tra kết nối thủ công.

---

## 🏗️ Cấu trúc thư mục dự án

```text
ja_mes_tool/
├── lib/
│   ├── main.dart                  # Điểm khởi chạy ứng dụng & Provider
│   └── modules/
│       ├── api_client.dart        # MES API Client & Hàm làm sạch Header (_cleanHeader)
│       ├── browser_helper.dart    # Xử lý Chrome/Edge CDP & Anti-Freeze Flags
│       ├── constants.dart         # Hằng số toàn cục & Cấu hình mặc định (v2.3.0)
│       ├── logger_service.dart    # Ghi log file & Tự động dọn dẹp sau 7 ngày
│       ├── logic.dart             # Quản lý trạng thái & Timer kiểm tra ngầm
│       ├── translations.dart     # Từ điển đa ngôn ngữ (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # Màn hình chính & Các hộp thoại 2 bước
│           ├── styles.dart        # Định nghĩa theme Dark
│           └── styles_win10.dart  # Định nghĩa theme Light
│
├── docs/
│   └── screenshots/               # Thư mục chứa ảnh giao diện
│       ├── 2026-07-26_231301.png  # Giao diện Cài đặt & Icon Huy hiệu Xác thực
│       └── 2026-07-26_231317.png  # Popup Cảnh báo Token Hết Hạn tự động
├── i18n/
│   ├── README.vi.md               # Tài liệu Tiếng Việt (file này)
│   └── README.zh-CN.md            # Tài liệu Tiếng Trung
├── pubspec.yaml                   # File cấu hình Flutter (v2.3.0+1)
├── ABOUT.txt                      # Thẻ thông tin dự án
└── LICENSE                        # Giấy phép bản quyền
```

---

## 📖 Hướng dẫn Biên dịch & Cài đặt

### Yêu cầu hệ thống
* **Windows 10 / 11**
* **Flutter SDK 3.x** & **Dart 3.12+**
* Đã cài đặt trình duyệt **Google Chrome** hoặc **Microsoft Edge**.

### Biên dịch ra file thực thi (.exe)
```cmd
flutter build windows
```
File `.exe` hoàn chỉnh sẽ nằm tại:
`build\windows\x64\runner\Release\ja_mes_tool.exe`
