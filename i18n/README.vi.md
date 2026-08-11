# 🤖 JA MES Test Record Tool v2.4.0 - Tiếng Việt

<p align="center">
  <br>
  <i><b>Ứng dụng desktop hiệu năng cao phát triển bằng Dart & Flutter giúp tự động hóa tra cứu, kiểm tra và xuất báo cáo dữ liệu kiểm thử, lịch sử công đoạn/barcode, và truy vết linh kiện BOM từ hệ thống Foxconn CloudMES.</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/phien_ban-2.4.0-blue.svg" alt="Phiên bản 2.4.0">
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

**JA MES Test Record Tool** là phần mềm chuyên dụng được thiết kế nhằm tối ưu hóa quy trình kiểm tra số Serial Number (SN), trích xuất lịch sử test/công đoạn, truy vết linh kiện BOM và xuất báo cáo từ nền tảng API **Foxconn CloudMES**.

Được thiết kế tối ưu cho kỹ sư kiểm thử và đội ngũ QA, ứng dụng mang đến khả năng tra cứu song song siêu tốc trên 3 chế độ xem dữ liệu, tự động đồng bộ Token qua trình duyệt (CDP Interception), và giao diện hiện đại với tìm kiếm & sắp xếp kiểu Excel.

---

## 💡 Tính năng nổi bật (v2.4.0)

### 📊 Chế độ xem dữ liệu
- 🗂️ **3 chế độ xem theo SN**: Chuyển đổi giữa **Kết quả Test** (Pass/Fail), **Lịch sử Barcode** (toàn bộ lộ trình công đoạn/trạm), và **Danh sách Linh kiện** (truy vết BOM/vật tư — nhà sản xuất, mã hãng, mã ngày SX, mã lô/gói) cho mỗi SN.
- 🔍 **Tìm kiếm kiểu Excel**: Ô tìm kiếm trực tiếp trên mỗi danh sách, khớp mọi trường dữ liệu khi bạn gõ.
- ⬍ **Sắp xếp theo trường**: Nút Sắp xếp cho phép chọn trường và đảo chiều tăng/giảm, áp dụng cho cả 3 chế độ xem.
- 📋 **Chọn & Copy dữ liệu**: Mọi giá trị bản ghi đều có thể bôi đen (kéo chuột hoặc double-click) và copy (Ctrl+C) như bảng tính.
- 🔢 **Số lượng bản ghi thông minh**: "Bản ghi của SN" tự động hiện số lượng `(N)`, ẩn đi khi chỉ có 0 hoặc 1 bản ghi.

### 🎨 Giao diện
- 🏝️ **Thanh công cụ Hover kiểu Dynamic Island**: 3 tab chế độ xem và các nút Tải Mẫu/Nhập/Xuất/Ngôn ngữ/Giao diện thu gọn thành icon, tự mở rộng thành chữ khi hover — tránh tràn giao diện. Khi cửa sổ ở chế độ maximize, tất cả tự động hiện đầy đủ chữ.
- 🎨 **Giao diện Đa ngôn ngữ & Solid**: Hỗ trợ Light/Dark Mode và chuyển đổi 3 ngôn ngữ (**Tiếng Việt**, **Tiếng Anh**, **Tiếng Trung**).

### 🔐 Xác thực & Kết nối
- ⚡ **Tự động Cảnh báo Popup Token Hết Hạn trên Startup**: Phát hiện Token hết hạn ngay khi mở app và tự động bật Cửa sổ Popup đồng bộ 2 bước.
- 🌐 **Tương thích Đa trình duyệt Chrome & Microsoft Edge**: Tích hợp bộ cờ cách ly luồng chống treo/đứng hình cửa sổ Đăng nhập Edge (`--disable-features=msEdgeStartupBoost...`).
- 🌐 **Đồng bộ Token tự động qua CDP**: Lấy chính xác 100% các thông số **Token**, **UUID**, **Operation-ID**, và **Cookie** thực tế từ lưu lượng mạng trình duyệt.
- 🛡️ **Huy hiệu Xác thực Kết nối Mới (🛡️)**: Biểu tượng khiên xác thực `Icons.verified_outlined` trực quan ở chân trang Cài đặt.
- 🔄 **Tự động Tra cứu lại Hàng đợi khi Lưu**: Tự động xóa các lỗi hết hạn Token cũ (401) và tra cứu lại toàn bộ danh sách SN trong hàng đợi khi bấm Save.
- 🔒 **Không hardcode thông tin đăng nhập**: Token/Cookie không bao giờ được nhúng sẵn trong source — người dùng tự cung cấp qua Cài đặt và chỉ lưu cục bộ vào `config.json` (không bị Git theo dõi).

### ⚙️ Lõi & Quản lý dữ liệu
- ⚡ **Hàng đợi tra cứu SN song song**: Xử lý tra cứu danh sách SN nhanh chóng theo cơ chế bất đồng bộ, trên cả 3 chế độ xem.
- 📄 **Nhập & Xuất file CSV thông minh**: Tự động bỏ qua các dòng tiêu đề (chứa chữ `"SN"`) và xuất báo cáo CSV chi tiết.
- 🛠️ **Bộ lọc & Làm sạch dữ liệu Header**: Tự động cắt bỏ ký tự xuống dòng ẩn (`\r\n`), khoảng trắng và dấu ngoặc kép thừa.
- 📋 **Quản lý Nhật ký hệ thống (Logs)**: Ghi vết theo ngày và tự động xóa các file log cũ quá 7 ngày mỗi khi khởi động.

---

## 📸 Hình ảnh Giao diện Ứng dụng

<p align="center">
  <img src="../docs/screenshots/2026-08-11_133916.jpg" alt="Chế độ xem Kết quả Test với tìm kiếm, sắp xếp và số lượng bản ghi" width="850">
  <br><i>Kết quả Test — tìm kiếm, sắp xếp và số lượng bản ghi trên cùng một dòng</i>
  <br><br>
  <img src="../docs/screenshots/2026-08-11_134048.jpg" alt="Chế độ xem Danh sách Linh kiện truy vết BOM" width="850">
  <br><i>Danh sách Linh kiện — truy vết BOM/vật tư theo SN</i>
  <br><br>
  <img src="../docs/screenshots/2026-07-26_231301.png" alt="Giao diện Cài đặt với Huy hiệu Xác thực kết nối mới & Thẻ đồng bộ 2 bước" width="850">
  <br><i>Cài đặt — quy trình đồng bộ Token 2 bước qua CDP</i>
  <br><br>
  <img src="../docs/screenshots/2026-07-26_231317.png" alt="Cửa sổ Popup Cảnh báo Token Hết Hạn tự động trên Startup" width="850">
  <br><i>Popup cảnh báo Token hết hạn tự động khi khởi động</i>
</p>

---

## 🖥️ Hướng dẫn sử dụng chi tiết

### 1. Thêm danh sách SN
* **Thêm đơn lẻ**: Nhập SN vào ô ở cột bên trái rồi ấn **Enter** hoặc bấm nút **[+]**.
* **Nhập theo lô (CSV)**: Bấm nút **[Tải Mẫu]** để lấy file mẫu. Điền SN vào file rồi bấm **[Nhập (Import)]**. Dòng tiêu đề chứa chữ `"SN"` sẽ tự động bị bỏ qua.

### 2. Xem 3 chế độ dữ liệu
* Hover chuột vào thanh icon cạnh **"Chi tiết Kết quả"** để hiện tên, hoặc bấm trực tiếp — không cần hover trước:
  - 📋 **Kết quả Test**: kết quả Pass/Fail theo từng trạm.
  - 🔳 **Lịch sử Barcode**: toàn bộ lộ trình công đoạn/trạm của SN.
  - 🧩 **Danh sách Linh kiện**: truy vết BOM/vật tư (nhà sản xuất, mã hãng, mã ngày SX, mã lô/gói).
* Dùng **ô tìm kiếm** trên mỗi danh sách để lọc theo mọi trường, và nút **[Sắp xếp]** để chọn trường và đảo chiều tăng/giảm.
* Kéo chuột hoặc double-click vào giá trị bất kỳ để chọn, rồi **Ctrl+C** để copy — như bảng tính.
* Bấm **[Xuất (Export)]** để lưu toàn bộ dữ liệu Kết quả Test ra file CSV.

### 3. Tự động lấy Token từ Trình duyệt (Quy trình 2 bước CDP)
1. Mở **Cài đặt ⚙️** (hoặc thông qua Cửa sổ Popup cảnh báo Token hết hạn tự động khi vừa khởi động).
2. **Bước 1**: Nhấn nút **[1. Mở trình duyệt]** để mở Chrome hoặc Microsoft Edge.
3. Đăng nhập tài khoản MES của bạn trên trang web.
4. **Bước 2**: Nhấn nút **[2. Lấy Token]**. Phần mềm sẽ dùng cơ chế CDP Network Interception để bắt chính xác 100% **Token**, **UUID**, **Operation-ID** và **Cookie**.
5. Nhấn **Lưu** để tự động dọn dẹp màn hình lỗi cũ và tra cứu lại toàn bộ danh sách SN trong hàng đợi.

### 4. Kiểm tra kết nối
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
│   ├── main.dart                  # Điểm khởi chạy ứng dụng, Provider & khởi tạo window_manager
│   └── modules/
│       ├── api_client.dart        # MES API Client: TestRecord, SnProcessRecord & WipComponentRecord
│       ├── browser_helper.dart    # Xử lý Chrome/Edge CDP & Anti-Freeze Flags
│       ├── config_service.dart    # Đọc/ghi config.json cục bộ (không hardcode thông tin đăng nhập)
│       ├── constants.dart         # Hằng số toàn cục & Cấu hình mặc định (v2.4.0)
│       ├── logger_service.dart    # Ghi log file & Tự động dọn dẹp sau 7 ngày
│       ├── logic.dart             # Quản lý trạng thái: hàng đợi SN, 3 danh sách dữ liệu, ViewMode
│       ├── translations.dart      # Từ điển đa ngôn ngữ (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # Tab, tìm kiếm/sắp xếp, hover chip, hộp thoại (WindowListener)
│           ├── styles.dart        # Bộ điều phối theme (Dark/Light)
│           ├── styles_win10.dart  # Theme trong suốt cho Windows 10
│           └── styles_win11.dart  # Theme acrylic cho Windows 11
│
├── docs/
│   └── screenshots/                 # Thư mục chứa ảnh giao diện
│       ├── 2026-08-11_133916.jpg    # Kết quả Test — tìm kiếm/sắp xếp/số lượng
│       ├── 2026-08-11_134048.jpg    # Danh sách Linh kiện — truy vết BOM
│       ├── 2026-07-26_231301.png    # Giao diện Cài đặt & Icon Huy hiệu Xác thực
│       └── 2026-07-26_231317.png    # Popup Cảnh báo Token Hết Hạn tự động
├── i18n/
│   ├── README.vi.md               # Tài liệu Tiếng Việt (file này)
│   └── README.zh-CN.md            # Tài liệu Tiếng Trung
├── pubspec.yaml                   # File cấu hình Flutter (v2.4.0+2)
├── ABOUT.txt                      # Thẻ thông tin dự án
├── CHANGELOG.md                   # Lịch sử phiên bản đầy đủ
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

---

## ⚙️ Cấu hình & Cài đặt

Toàn bộ thông tin đăng nhập được nhập qua hộp thoại **Cài đặt ⚙️** trong app (dán header thô, đồng bộ qua CDP, hoặc nhập tay) — **không có gì được hardcode trong source**. Dữ liệu chỉ lưu cục bộ cạnh file thực thi trong `config.json` (đã bị `.gitignore` chặn, không commit lên Git):

```json
{
  "token": "",
  "sns": ["SN123456", "SN789012"],
  "lang": "en",
  "operationId": "1826874274766209025",
  "uuid": "e1d5e78c-bf60-4aba-9b5f-a94b15cb63d4",
  "cookie": ""
}
```

---

## 📜 Tóm tắt Changelog

- **[2.4.0]** — Thêm tab Lịch sử Barcode & Danh sách Linh kiện, tìm kiếm/sắp xếp kiểu Excel, chọn/copy dữ liệu, thanh công cụ hover kiểu Dynamic Island, gỡ bỏ thông tin đăng nhập hardcode.
- **[2.3.0]** — Popup cảnh báo Token hết hạn tự động khi khởi động, bộ cờ chống treo Edge/Chrome, icon huy hiệu xác thực kết nối.
- **[2.2.0]** — Tự động tra cứu lại hàng đợi SN khi lưu Cài đặt, kiểm tra kết nối ngay lập tức.

Xem đầy đủ lịch sử phiên bản tại [**CHANGELOG.md**](../CHANGELOG.md).
