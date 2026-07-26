# 🤖 JA MES Test Record Tool (v2.0.0) - Tiếng Việt

<p align="center">
  <br>
  <i><b>Ứng dụng desktop hiệu năng cao phát triển bằng Dart & Flutter giúp tự động hóa tra cứu, kiểm tra và xuất báo cáo dữ liệu kiểm thử từ hệ thống Foxconn CloudMES.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Dart-3.12+-blue.svg?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6.svg?style=flat-square&logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/Version-v2.0.0-green.svg?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="../README.md">🇺🇸 English</a> • 
  <b>🇻🇳 Tiếng Việt</b> • 
  <a href="README.zh-CN.md">🇨🇳 中文</a>
</p>

---

## 🌟 Giới thiệu

**JA MES Test Record Tool** là phần mềm chuyên dụng được thiết kế nhằm tối ưu hóa quy trình kiểm tra số Serial Number (SN), trích xuất lịch sử trạm test và xuất báo cáo từ nền tảng API **Foxconn CloudMES**.

Phần mềm hỗ trợ hàng đợi tra cứu song song với giao diện Desktop Glassmorphic hiện đại, trực quan và dễ sử dụng.

---

## 💡 Tính năng nổi bật (v2.0.0)

- **⚡ Hàng đợi tra cứu SN song song**: Xử lý tra cứu danh sách SN nhanh chóng theo cơ chế bất đồng bộ.
- **📄 Nhập & Xuất file CSV thông minh**:
  - Tự động bỏ qua các dòng tiêu đề/bảng (ví dụ các dòng chứa chữ `"SN"`).
  - Tải file mẫu CSV chỉ với 1 click và xuất báo cáo kết quả chi tiết.
- **🌐 Đồng bộ Token tự động qua Chrome CDP (Network Interception)**:
  - Tự động mở Chrome/Edge với cổng debugging động (`--remote-debugging-port=0`).
  - Sử dụng Chrome DevTools Protocol (`Network.enable`) để bắt trực tiếp gói tin API từ trình duyệt.
  - Lấy chính xác 100% các thông số **Token**, **UUID**, **Operation-ID**, và **Cookie** thực tế.
- **🔄 Tự động kiểm tra tính khả dụng của Token**:
  - Bộ đếm thời gian tự động xác thực kết nối cứ sau mỗi 3 phút.
  - Đèn báo trạng thái trực quan ngay trên thanh tiêu đề (Xanh = Hoạt động tốt, Đỏ = Hết hạn Token/Lỗi).
  - Công cụ test kết nối thủ công trong phần Settings.
- **🛠️ Bộ lọc & Làm sạch dữ liệu Header**:
  - Tự động cắt bỏ ký tự xuống dòng ẩn (`\r\n`), khoảng trắng và dấu ngoặc kép (`"..."`) để tránh lỗi `FormatException`.
- **📋 Quản lý Nhật ký hệ thống (Logs)**:
  - Ghi vết mọi hoạt động và lỗi phát sinh vào thư mục `logs/` theo ngày (`mes_log_YYYY-MM-DD.txt`).
  - Tự động xóa các file log cũ quá 7 ngày mỗi khi khởi động ứng dụng.
- **🎨 Giao diện Đa ngôn ngữ & Trong suốt**:
  - Hỗ trợ đổi giao diện Light/Dark Mode trong suốt (Glassmorphic).
  - Chuyển đổi nhanh 3 ngôn ngữ (**Tiếng Việt**, **Tiếng Anh**, **Tiếng Trung**).

---

## 🏗️ Cấu trúc thư mục dự án

```text
ja_mes_tool/
├── lib/
│   ├── main.dart                  # Điểm khởi chạy ứng dụng & Provider
│   └── modules/
│       ├── api_client.dart        # MES API Client & Hàm làm sạch Header (_cleanHeader)
│       ├── browser_helper.dart    # Xử lý Chrome CDP & Network Interception
│       ├── constants.dart         # Hằng số toàn cục & Cấu hình mặc định
│       ├── logger_service.dart    # Ghi log file & Tự động dọn dẹp sau 7 ngày
│       ├── logic.dart             # Quản lý trạng thái & Timer kiểm tra ngầm
│       ├── translations.dart     # Từ điển đa ngôn ngữ (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # Màn hình chính & Các hộp thoại
│           ├── styles.dart        # Định nghĩa theme Dark
│           └── styles_win10.dart  # Định nghĩa theme Light
│
├── docs/
│   └── SKILL_cdp_extraction.md    # Hướng dẫn kỹ thuật bắt gói tin CDP
├── i18n/
│   ├── README.vi.md               # Tài liệu Tiếng Việt (file này)
│   └── README.zh-CN.md            # Tài liệu Tiếng Trung
├── logs/                          # Thư mục chứa file log hàng ngày
├── POST_MORTEM_MEMO.md            # Tài liệu phân tích nguyên nhân lỗi & giải pháp
├── pubspec.yaml                   # File cấu hình Flutter (v2.0.0+2)
├── git_push.bat                   # Script tự động push code lên Git
├── ABOUT.txt                      # Thẻ thông tin dự án
└── LICENSE                        # Giấy phép MIT
```

---

## 📖 Hướng dẫn Biên dịch & Cài đặt

### Yêu cầu hệ thống
* **Windows 10 / 11**
* **Flutter SDK 3.x** & **Dart 3.12+**
* Đã cài đặt trình duyệt **Google Chrome** hoặc **Microsoft Edge**.

### Chạy thử nghiệm (Local Run)
```cmd
flutter pub get
flutter run -d windows
```

### Biên dịch ra file thực thi (.exe)
```cmd
flutter build windows
```
File `.exe` hoàn chỉnh sẽ nằm tại:
`build\windows\x64\runner\Release\ja_mes_tool.exe`

---

## 🖥️ Hướng dẫn sử dụng chi tiết

### 1. Thêm danh sách SN
* **Thêm đơn lẻ**: Nhập SN vào ô ô bên trái rồi ấn **Enter** hoặc bấm nút **[+]**.
* **Nhập theo lô (CSV)**: Bấm nút **[Tải Mẫu]** để lấy file mẫu. Điền SN vào file rồi bấm **[Nhập (Import)]**. Dòng tiêu đề như `"SN"` sẽ tự động bị bỏ qua.

### 2. Tự động lấy Token từ Trình duyệt (CDP)
1. Mở **Cài đặt ⚙️**.
2. Nhấn nút **[Mở Trình Duyệt Đăng Nhập]** để mở Chrome/Edge.
3. Đăng nhập tài khoản MES của bạn trên trang web.
4. Nhấn nút **[Lấy Token Từ Trình Duyệt]**. Phần mềm sẽ tự động reload trang và bắt chính xác 100% **Token**, **UUID**, **Operation-ID** và **Cookie** từ gói tin API thật.
5. Hoặc nhấn **[Dán Header từ F12/Postman]** để dán trực tiếp đoạn Header thô.

### 3. Kiểm tra kết nối
* Biểu tượng màu bên cạnh dòng **"Chi tiết Kết quả"**:
  - 🟢 **Xanh**: Kết nối hoạt động tốt.
  - 🔴 **Đỏ**: Token hết hạn hoặc sai cấu hình (401).
* Ứng dụng tự động kiểm tra lại Token cứ **3 phút** một lần.

---

## 📜 Giấy phép

Dự án được phân phối theo giấy phép **MIT License**. Xem file [LICENSE](../LICENSE) để biết thêm chi tiết.
