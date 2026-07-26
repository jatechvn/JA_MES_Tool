# POST-MORTEM MEMO (BẢN GHI NHỚ NGUYÊN NHÂN LỖI & GIẢI PHÁP)

**Dự án**: JA MES Tool  
**Ngày**: 2026-07-26  
**Chủ đề**: Phân tích lý do tại sao tính năng tự động lấy Token / UUID / Cookie bị lỗi và cách khắc phục triệt để.

---

## 1. TỔNG QUAN VẤN ĐỀ
Trong các phiên bản trước, tính năng "Get Credentials từ Trình duyệt" liên tục gặp các lỗi:
- UUID lấy về không khớp với UUID xem ở F12 (dẫn tới lỗi 401 Unauthorized / 404 / 500 Server Error).
- Nút "Get Credentials" đôi khi bị từ chối kết nối (`Connection Refused`).
- Khi copy thủ công từ F12/Postman vào app lại bị lỗi `FormatException: Invalid HTTP header field value`.
- Tự động thay đổi ngôn ngữ giao diện của người dùng khi nhấn Get Credentials.

---

## 2. NGUYÊN NHÂN CHI TIẾT (TẠI SAO CHÚNG TA LÀM SAI?)

### ❌ Sai lầm 1: Nhầm lẫn nơi lưu trữ UUID (LocalStorage vs Request Header Interceptor)
* **Nguyên nhân**: Ban đầu, phần mềm sử dụng JS `Runtime.evaluate` trong CDP để duyệt qua `localStorage` / `sessionStorage` để tìm giá trị UUID.
* **Thực tế**: Trong các hệ thống Web SPA hiện đại (như Vue/React dùng Axios), `uuid` thường là một Session Identifier được sinh ra động bởi HTTP Interceptor của Frontend khi ứng dụng phát ra request. Nó **không phải là một key tĩnh nằm trong localStorage**, hoặc nếu có key tên `uuid` trong localStorage thì đó là giá trị cũ/khác.
* **Hậu quả**: Giá trị UUID lấy ra từ `localStorage` khác hoàn toàn với `uuid` thực tế mà trang web gửi lên server trong Header làm MES server từ chối request (401 / 500).

### ❌ Sai lầm 2: Hardcode Cổng Debugging CDP (Port 9222)
* **Nguyên nhân**: Mặc định cho Chrome mở với `--remote-debugging-port=9222`.
* **Thực tế**: Nếu trên máy tính người dùng đã có một tiến trình Chrome/Edge khác hoặc ứng dụng khác chiếm cổng 9222, Chrome sẽ không bật server CDP hoặc không thể bind cổng 9222.
* **Hậu quả**: Khi nhấn "Get Credentials", app thử kết nối tới `127.0.0.1:9222` và bị từ chối (`SocketException: Connection refused`).

### ❌ Sai lầm 3: Không làm sạch dữ liệu Header (Unsanitized Header Strings)
* **Nguyên nhân**: Giá trị đọc từ Clipboard (dán từ F12/Postman) hoặc đọc từ CDP chứa các ký tự điều khiển ẩn như `\r` (Carriage Return), `\n` (Line Feed) hoặc dấu ngoặc kép `"..."`.
* **Thực tế**: Thư viện HTTP của Dart (`dart:http`) kiểm tra rất nghiêm ngặt giá trị Header. Nếu có ký tự `\r` hoặc `\n`, Dart sẽ ném ra ngoại lệ `FormatException`.
* **Hậu quả**: Request bị hủy ngay tại Client trước khi kịp gửi đi, báo lỗi ngắt kết nối hoặc 404/500 giả lập.

### ❌ Sai lầm 4: Ghi đè cấu hình Ngôn ngữ của Người dùng
* **Nguyên nhân**: Khi lấy dữ liệu từ trình duyệt, ứng dụng tiện tay lấy luôn giá trị `cultureName` trong Cookie để ghi đè vào `langCtrl`.
* **Thực tế**: Người dùng muốn giữ nguyên ngôn ngữ giao diện họ đang dùng trên app.

---

## 3. GIẢI PHÁP ĐÃ KHẮC PHỤC TRIỆT ĐỂ

1. **Chuyển sang CDP Network Interception (`Network.enable` + `Network.requestWillBeSent`)**:
   - Thay vì đọc `localStorage` (không chính xác), app bật tính năng giám sát mạng của Chrome CDP (`Network.enable`).
   - Gửi lệnh `Page.reload` để trang web tự động tải lại và phát ra các API request thực tế.
   - Bắt trực tiếp các header `Authorization`, `uuid`, `operation-id`, `Cookie` từ request API thật gửi tới `vncmes.ces.myfiinet.com/api/...`. Đảm bảo UUID và Token chính xác 100%.

2. **Dùng Cổng Cấp Phát Động (Dynamic Port 0) & Đọc `DevToolsActivePort`**:
   - Mở Chrome với `--remote-debugging-port=0`. Chrome sẽ tự chọn 1 cổng trống bất kỳ và ghi vào file `<user-data-dir>\DevToolsActivePort`.
   - App đọc file này để lấy đúng cổng đang lắng nghe, loại bỏ hoàn toàn lỗi `Connection Refused`.

3. **Thêm Hàm Làm Sạch Header `_cleanHeader()`**:
   - Tất cả dữ liệu Token, UUID, Operation-ID, Cookie trước khi gắn vào HTTP Request đều đi qua `_cleanHeader()` để xóa triệt để `\r`, `\n`, khoảng trắng thừa và dấu ngoặc kép `"..."` ở 2 đầu.

4. **Bảo toàn Ngôn ngữ Giao diện**:
   - Loại bỏ đoạn code ghi đè `langCtrl` khi lấy dữ liệu từ trình duyệt.

---

## 4. BÀI HỌC RÚT RA (LESSONS LEARNED)
1. **Đừng đoán vị trí dữ liệu**: Khi làm việc với Authentication Headers phức tạp, bắt gói tin thực tế (`Network Interception`) luôn chính xác hơn nhiều so với việc đọc bộ nhớ tạm (`localStorage` / `cookies`).
2. **Luôn sanitize chuỗi nhập từ bên ngoài**: Bất kể dữ liệu đến từ Clipboard, File hay Web Socket, luôn phải làm sạch ký tự điều khiển (`\r\n`) trước khi đưa vào HTTP Header.
3. **Không hardcode tài nguyên mạng**: Luôn ưu tiên cấp phát động (Dynamic Port) đối với các dịch vụ Inter-Process Communication (IPC) hoặc Local Debugging.
