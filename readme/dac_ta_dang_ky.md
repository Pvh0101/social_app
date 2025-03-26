# Đặc tả chức năng: Đăng ký tài khoản

| STT | Mục | Mô tả |
|-----|-----|-------|
| 1️⃣ | Use Case Name | Đăng ký tài khoản |
| 2️⃣ | Descriptions | Cho phép người dùng tạo tài khoản mới trên ứng dụng mạng xã hội |
| 3️⃣ | Actor | Khách (người dùng chưa đăng nhập) |
| 4️⃣ | Priority | Cao |
| 5️⃣ | Trigger | Người dùng nhấn vào nút "Đăng ký" |
| 6️⃣ | Pre-conditions | Người dùng chưa có tài khoản |
| 7️⃣ | Post-conditions | Người dùng có tài khoản mới và có thể đăng nhập vào hệ thống |
| 8️⃣ | Basic Flow | 1. Người dùng nhập email, mật khẩu, tên hiển thị<br>2. Người dùng nhấn nút "Đăng ký"<br>3. Hệ thống kiểm tra tính hợp lệ của dữ liệu<br>4. Hệ thống tạo tài khoản mới<br>5. Hệ thống gửi email xác minh<br>6. Người dùng xác minh tài khoản<br>7. Hệ thống chuyển hướng đến trang đăng nhập |
| 9️⃣ | Alternative Flow | 1. Người dùng yêu cầu gửi lại email xác minh<br>2. Người dùng đăng nhập trực tiếp sau khi đăng ký thành công |
| 🔟 | Exception Flow | 1. Dữ liệu không hợp lệ: Hiển thị thông báo lỗi<br>2. Email đã tồn tại: Gợi ý chuyển đến trang đăng nhập<br>3. Người dùng không xác minh email: Tài khoản bị giới hạn chức năng |
| 1️⃣1️⃣ | Functional Requirements | 1. Kiểm tra định dạng email hợp lệ<br>2. Kiểm tra email đã tồn tại<br>3. Mã hóa mật khẩu<br>4. Gửi email xác minh<br>5. Cập nhật trạng thái tài khoản |
| 1️⃣2️⃣ | Non-Functional Requirements | 1. Thời gian phản hồi < 3 giây<br>2. Mật khẩu được mã hóa an toàn<br>3. Giao diện thân thiện và responsive | 