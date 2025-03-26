# Mô tả Activity Diagram cho Ứng dụng Social App

## 1. Activity Diagram: Đăng ký và Xác thực Người dùng

```
[Initial] --> "Mở màn hình đăng ký"
"Mở màn hình đăng ký" --> "Nhập thông tin đăng ký"
"Nhập thông tin đăng ký" --> "Kiểm tra tính hợp lệ"
"Kiểm tra tính hợp lệ" --> [Decision: "Thông tin hợp lệ?"]
[Decision: "Thông tin hợp lệ?"] -- "Không" --> "Hiển thị lỗi" --> "Nhập thông tin đăng ký"
[Decision: "Thông tin hợp lệ?"] -- "Có" --> "Tạo tài khoản Firebase Auth"
"Tạo tài khoản Firebase Auth" --> [Decision: "Tạo thành công?"]
[Decision: "Tạo thành công?"] -- "Không" --> "Hiển thị lỗi" --> "Nhập thông tin đăng ký"
[Decision: "Tạo thành công?"] -- "Có" --> "Tạo document người dùng trong Firestore"
"Tạo document người dùng trong Firestore" --> "Gửi email xác minh"
"Gửi email xác minh" --> "Chuyển đến màn hình xác minh email"
"Chuyển đến màn hình xác minh email" --> [Decision: "Email đã xác minh?"]
[Decision: "Email đã xác minh?"] -- "Không" --> "Chờ xác minh hoặc gửi lại email"
"Chờ xác minh hoặc gửi lại email" --> [Decision: "Email đã xác minh?"]
[Decision: "Email đã xác minh?"] -- "Có" --> "Chuyển đến màn hình nhập thông tin cá nhân"
"Chuyển đến màn hình nhập thông tin cá nhân" --> "Nhập thông tin cá nhân"
"Nhập thông tin cá nhân" --> "Kiểm tra tính hợp lệ"
"Kiểm tra tính hợp lệ" --> [Decision: "Thông tin hợp lệ?"]
[Decision: "Thông tin hợp lệ?"] -- "Không" --> "Hiển thị lỗi" --> "Nhập thông tin cá nhân"
[Decision: "Thông tin hợp lệ?"] -- "Có" --> "Lưu thông tin vào Firestore"
"Lưu thông tin vào Firestore" --> "Chuyển đến màn hình chính"
"Chuyển đến màn hình chính" --> [Final]
```

## 2. Activity Diagram: Đăng nhập

```
[Initial] --> "Mở màn hình đăng nhập"
"Mở màn hình đăng nhập" --> "Nhập email và mật khẩu"
"Nhập email và mật khẩu" --> "Xác thực với Firebase Auth"
"Xác thực với Firebase Auth" --> [Decision: "Xác thực thành công?"]
[Decision: "Xác thực thành công?"] -- "Không" --> "Hiển thị lỗi" --> "Nhập email và mật khẩu"
[Decision: "Xác thực thành công?"] -- "Có" --> "Kiểm tra trạng thái xác minh email"
"Kiểm tra trạng thái xác minh email" --> [Decision: "Email đã xác minh?"]
[Decision: "Email đã xác minh?"] -- "Không" --> "Chuyển đến màn hình xác minh email" --> [Final]
[Decision: "Email đã xác minh?"] -- "Có" --> "Kiểm tra thông tin cá nhân"
"Kiểm tra thông tin cá nhân" --> [Decision: "Thông tin đầy đủ?"]
[Decision: "Thông tin đầy đủ?"] -- "Không" --> "Chuyển đến màn hình nhập thông tin cá nhân" --> [Final]
[Decision: "Thông tin đầy đủ?"] -- "Có" --> "Cập nhật token FCM"
"Cập nhật token FCM" --> "Cập nhật trạng thái online"
"Cập nhật trạng thái online" --> "Chuyển đến màn hình chính"
"Chuyển đến màn hình chính" --> [Final]
```

## 3. Activity Diagram: Tạo bài viết mới

```
[Initial] --> "Mở màn hình tạo bài viết"
"Mở màn hình tạo bài viết" --> "Nhập nội dung văn bản"
"Nhập nội dung văn bản" --> [Decision: "Thêm media?"]
[Decision: "Thêm media?"] -- "Có" --> "Chọn hình ảnh/video từ thư viện hoặc camera"
"Chọn hình ảnh/video từ thư viện hoặc camera" --> [Decision: "Loại media?"]
[Decision: "Loại media?"] -- "Video" --> "Tạo thumbnail tự động"
"Tạo thumbnail tự động" --> "Hiển thị preview media"
[Decision: "Loại media?"] -- "Hình ảnh" --> "Hiển thị preview media"
"Hiển thị preview media" --> [Decision: "Thêm media khác?"]
[Decision: "Thêm media khác?"] -- "Có" --> "Chọn hình ảnh/video từ thư viện hoặc camera"
[Decision: "Thêm media khác?"] -- "Không" --> "Nhấn nút đăng"
[Decision: "Thêm media?"] -- "Không" --> "Nhấn nút đăng"
"Nhấn nút đăng" --> [Decision: "Nội dung hợp lệ?"]
[Decision: "Nội dung hợp lệ?"] -- "Không" --> "Hiển thị lỗi" --> "Nhập nội dung văn bản"
[Decision: "Nội dung hợp lệ?"] -- "Có" --> "Hiển thị loading"
"Hiển thị loading" --> [Fork]
[Fork] --> "Tải file lên Firebase Storage"
[Fork] --> "Xác định loại bài viết"
"Tải file lên Firebase Storage" --> [Join]
"Xác định loại bài viết" --> [Join]
[Join] --> "Tạo document bài viết trong Firestore"
"Tạo document bài viết trong Firestore" --> "Cập nhật feed"
"Cập nhật feed" --> "Chuyển về màn hình feed"
"Chuyển về màn hình feed" --> [Final]
```

## 4. Activity Diagram: Tương tác với bài viết (Thích và Bình luận)

```
[Initial] --> "Xem bài viết trong feed"
"Xem bài viết trong feed" --> [Decision: "Hành động?"]
[Decision: "Hành động?"] -- "Thích" --> "Nhấn nút thích"
"Nhấn nút thích" --> [Decision: "Đã thích trước đó?"]
[Decision: "Đã thích trước đó?"] -- "Có" --> "Xóa document like trong Firestore"
"Xóa document like trong Firestore" --> "Giảm số lượng like"
"Giảm số lượng like" --> "Cập nhật UI"
[Decision: "Đã thích trước đó?"] -- "Không" --> "Tạo document like trong Firestore"
"Tạo document like trong Firestore" --> "Tăng số lượng like"
"Tăng số lượng like" --> "Cập nhật UI"
"Cập nhật UI" --> [Final]

[Decision: "Hành động?"] -- "Bình luận" --> "Nhấn vào phần bình luận"
"Nhấn vào phần bình luận" --> "Mở màn hình bình luận"
"Mở màn hình bình luận" --> "Tải danh sách bình luận từ Firestore"
"Tải danh sách bình luận từ Firestore" --> "Hiển thị danh sách bình luận"
"Hiển thị danh sách bình luận" --> "Nhập nội dung bình luận"
"Nhập nội dung bình luận" --> "Nhấn gửi"
"Nhấn gửi" --> "Tạo document bình luận trong Firestore"
"Tạo document bình luận trong Firestore" --> "Tăng số lượng bình luận"
"Tăng số lượng bình luận" --> "Cập nhật UI"
"Cập nhật UI" --> [Final]
```

## 5. Activity Diagram: Gửi và nhận tin nhắn

```
[Initial] --> "Mở màn hình chat"
"Mở màn hình chat" --> "Tải lịch sử tin nhắn từ Firestore"
"Tải lịch sử tin nhắn từ Firestore" --> "Hiển thị tin nhắn"
"Hiển thị tin nhắn" --> "Đánh dấu tin nhắn đã đọc"
"Đánh dấu tin nhắn đã đọc" --> [Fork]
[Fork] --> "Lắng nghe tin nhắn mới (Firestore listener)"
[Fork] --> "Nhập tin nhắn mới"
"Lắng nghe tin nhắn mới (Firestore listener)" --> [Decision: "Có tin nhắn mới?"]
[Decision: "Có tin nhắn mới?"] -- "Có" --> "Hiển thị tin nhắn mới"
"Hiển thị tin nhắn mới" --> "Đánh dấu tin nhắn đã đọc"
[Decision: "Có tin nhắn mới?"] -- "Không" --> "Lắng nghe tin nhắn mới (Firestore listener)"

"Nhập tin nhắn mới" --> [Decision: "Loại tin nhắn?"]
[Decision: "Loại tin nhắn?"] -- "Văn bản" --> "Nhấn gửi"
[Decision: "Loại tin nhắn?"] -- "Media" --> "Chọn file media"
"Chọn file media" --> "Tải file lên Firebase Storage"
"Tải file lên Firebase Storage" --> "Nhấn gửi"
"Nhấn gửi" --> "Tạo document tin nhắn trong Firestore"
"Tạo document tin nhắn trong Firestore" --> "Cập nhật thông tin cuộc trò chuyện"
"Cập nhật thông tin cuộc trò chuyện" --> "Gửi thông báo đẩy"
"Gửi thông báo đẩy" --> "Hiển thị tin nhắn đã gửi"
"Hiển thị tin nhắn đã gửi" --> "Nhập tin nhắn mới"

[Decision: "Hành động?"] -- "Đóng chat" --> "Rời khỏi màn hình chat"
"Rời khỏi màn hình chat" --> [Final]
```

## 6. Activity Diagram: Kết bạn

```
[Initial] --> "Tìm kiếm người dùng"
"Tìm kiếm người dùng" --> "Xem hồ sơ người dùng"
"Xem hồ sơ người dùng" --> [Decision: "Trạng thái mối quan hệ?"]
[Decision: "Trạng thái mối quan hệ?"] -- "Chưa kết bạn" --> "Nhấn nút kết bạn"
"Nhấn nút kết bạn" --> "Tạo document lời mời kết bạn trong Firestore"
"Tạo document lời mời kết bạn trong Firestore" --> "Gửi thông báo đẩy"
"Gửi thông báo đẩy" --> "Cập nhật UI thành Đã gửi lời mời"
"Cập nhật UI thành Đã gửi lời mời" --> [Final]

[Decision: "Trạng thái mối quan hệ?"] -- "Đã gửi lời mời" --> "Nhấn nút hủy lời mời"
"Nhấn nút hủy lời mời" --> "Xóa document lời mời kết bạn"
"Xóa document lời mời kết bạn" --> "Cập nhật UI thành Kết bạn"
"Cập nhật UI thành Kết bạn" --> [Final]

[Decision: "Trạng thái mối quan hệ?"] -- "Đã nhận lời mời" --> "Nhấn nút chấp nhận"
"Nhấn nút chấp nhận" --> "Tạo document mối quan hệ bạn bè"
"Tạo document mối quan hệ bạn bè" --> "Xóa document lời mời kết bạn"
"Xóa document lời mời kết bạn" --> "Gửi thông báo đẩy"
"Gửi thông báo đẩy" --> "Cập nhật UI thành Bạn bè"
"Cập nhật UI thành Bạn bè" --> [Final]

[Decision: "Trạng thái mối quan hệ?"] -- "Đã là bạn bè" --> "Nhấn nút hủy kết bạn"
"Nhấn nút hủy kết bạn" --> "Hiển thị hộp thoại xác nhận"
"Hiển thị hộp thoại xác nhận" --> [Decision: "Xác nhận?"]
[Decision: "Xác nhận?"] -- "Không" --> "Đóng hộp thoại" --> [Final]
[Decision: "Xác nhận?"] -- "Có" --> "Xóa document mối quan hệ bạn bè"
"Xóa document mối quan hệ bạn bè" --> "Cập nhật UI thành Kết bạn"
"Cập nhật UI thành Kết bạn" --> [Final]
```

## 7. Activity Diagram: Xem và tương tác với Story

```
[Initial] --> "Mở màn hình feed"
"Mở màn hình feed" --> "Tải danh sách story từ Firestore"
"Tải danh sách story từ Firestore" --> "Hiển thị vòng tròn story"
"Hiển thị vòng tròn story" --> [Decision: "Hành động?"]
[Decision: "Hành động?"] -- "Tạo story mới" --> "Mở màn hình tạo story"
"Mở màn hình tạo story" --> "Chọn media (ảnh/video)"
"Chọn media (ảnh/video)" --> "Chỉnh sửa story (thêm văn bản, sticker, vẽ)"
"Chỉnh sửa story (thêm văn bản, sticker, vẽ)" --> "Nhấn đăng"
"Nhấn đăng" --> "Tải file lên Firebase Storage"
"Tải file lên Firebase Storage" --> "Tạo document story trong Firestore"
"Tạo document story trong Firestore" --> "Quay lại màn hình feed"
"Quay lại màn hình feed" --> [Final]

[Decision: "Hành động?"] -- "Xem story" --> "Nhấn vào vòng tròn story"
"Nhấn vào vòng tròn story" --> "Mở màn hình xem story"
"Mở màn hình xem story" --> "Tải và hiển thị story"
"Tải và hiển thị story" --> "Đánh dấu story đã xem"
"Đánh dấu story đã xem" --> [Decision: "Hành động?"]
[Decision: "Hành động?"] -- "Phản hồi story" --> "Vuốt lên"
"Vuốt lên" --> "Hiển thị form nhập phản hồi"
"Hiển thị form nhập phản hồi" --> "Nhập phản hồi"
"Nhập phản hồi" --> "Gửi tin nhắn"
"Gửi tin nhắn" --> "Quay lại xem story"
"Quay lại xem story" --> [Decision: "Hành động?"]
[Decision: "Hành động?"] -- "Chuyển story" --> "Nhấn sang trái/phải"
"Nhấn sang trái/phải" --> "Tải và hiển thị story"
[Decision: "Hành động?"] -- "Đóng" --> "Nhấn nút đóng"
"Nhấn nút đóng" --> "Quay lại màn hình feed"
"Quay lại màn hình feed" --> [Final]
```

## 8. Activity Diagram: Thông báo

```
[Initial] --> [Fork]
[Fork] --> "Mở ứng dụng"
[Fork] --> "Nhận thông báo đẩy khi ứng dụng đóng"

"Mở ứng dụng" --> "Tải thông báo từ Firestore"
"Tải thông báo từ Firestore" --> "Hiển thị thông báo chưa đọc"
"Hiển thị thông báo chưa đọc" --> "Mở màn hình thông báo"
"Mở màn hình thông báo" --> "Hiển thị danh sách thông báo"
"Hiển thị danh sách thông báo" --> [Decision: "Hành động?"]
[Decision: "Hành động?"] -- "Nhấn vào thông báo" --> "Đánh dấu thông báo đã đọc"
"Đánh dấu thông báo đã đọc" --> "Chuyển đến nội dung liên quan"
"Chuyển đến nội dung liên quan" --> [Final]
[Decision: "Hành động?"] -- "Đóng màn hình" --> [Final]

"Nhận thông báo đẩy khi ứng dụng đóng" --> [Decision: "Nhấn vào thông báo?"]
[Decision: "Nhấn vào thông báo?"] -- "Có" --> "Mở ứng dụng"
[Decision: "Nhấn vào thông báo?"] -- "Không" --> [Final]
```

## 9. Activity Diagram: Cài đặt ứng dụng

```
[Initial] --> "Mở màn hình cài đặt"
"Mở màn hình cài đặt" --> [Decision: "Loại cài đặt?"]
[Decision: "Loại cài đặt?"] -- "Ngôn ngữ" --> "Mở cài đặt ngôn ngữ"
"Mở cài đặt ngôn ngữ" --> "Chọn ngôn ngữ"
"Chọn ngôn ngữ" --> "Lưu cài đặt vào SharedPreferences"
"Lưu cài đặt vào SharedPreferences" --> "Áp dụng ngôn ngữ mới"
"Áp dụng ngôn ngữ mới" --> "Quay lại màn hình cài đặt"

[Decision: "Loại cài đặt?"] -- "Giao diện" --> "Mở cài đặt giao diện"
"Mở cài đặt giao diện" --> "Chọn chế độ (sáng/tối/hệ thống)"
"Chọn chế độ (sáng/tối/hệ thống)" --> "Lưu cài đặt vào SharedPreferences"
"Lưu cài đặt vào SharedPreferences" --> "Áp dụng giao diện mới"
"Áp dụng giao diện mới" --> "Quay lại màn hình cài đặt"

[Decision: "Loại cài đặt?"] -- "Quyền riêng tư" --> "Mở cài đặt quyền riêng tư"
"Mở cài đặt quyền riêng tư" --> "Cấu hình quyền riêng tư"
"Cấu hình quyền riêng tư" --> "Lưu cài đặt vào Firestore"
"Lưu cài đặt vào Firestore" --> "Quay lại màn hình cài đặt"

[Decision: "Loại cài đặt?"] -- "Thông báo" --> "Mở cài đặt thông báo"
"Mở cài đặt thông báo" --> "Cấu hình thông báo"
"Cấu hình thông báo" --> "Lưu cài đặt vào Firestore"
"Lưu cài đặt vào Firestore" --> "Quay lại màn hình cài đặt"

[Decision: "Loại cài đặt?"] -- "Tài khoản" --> "Mở cài đặt tài khoản"
"Mở cài đặt tài khoản" --> [Decision: "Hành động?"]
[Decision: "Hành động?"] -- "Đổi mật khẩu" --> "Nhập mật khẩu mới"
"Nhập mật khẩu mới" --> "Cập nhật Firebase Auth"
"Cập nhật Firebase Auth" --> "Quay lại màn hình cài đặt tài khoản"
[Decision: "Hành động?"] -- "Xóa tài khoản" --> "Xác nhận xóa tài khoản"
"Xác nhận xóa tài khoản" --> "Xóa dữ liệu từ Firestore"
"Xóa dữ liệu từ Firestore" --> "Xóa tài khoản Firebase Auth"
"Xóa tài khoản Firebase Auth" --> "Chuyển đến màn hình đăng nhập"
"Chuyển đến màn hình đăng nhập" --> [Final]

"Quay lại màn hình cài đặt" --> [Decision: "Tiếp tục cài đặt?"]
[Decision: "Tiếp tục cài đặt?"] -- "Có" --> [Decision: "Loại cài đặt?"]
[Decision: "Tiếp tục cài đặt?"] -- "Không" --> "Đóng màn hình cài đặt"
"Đóng màn hình cài đặt" --> [Final]
```

## Lưu ý khi vẽ Activity Diagram

1. **Ký hiệu chuẩn UML**:
   - Initial node: Điểm tròn đen đặc
   - Final node: Điểm tròn đen với vòng tròn bao quanh
   - Action: Hình chữ nhật bo góc
   - Decision: Hình thoi
   - Fork/Join: Thanh ngang đen
   - Flow: Mũi tên

2. **Màu sắc**:
   - Sử dụng màu khác nhau cho các luồng xử lý khác nhau
   - Màu xanh lá cho luồng thành công
   - Màu đỏ cho luồng lỗi
   - Màu cam cho luồng quyết định

3. **Bố cục**:
   - Sắp xếp từ trên xuống dưới
   - Các nhánh quyết định nên được đặt song song
   - Sử dụng swimlanes để phân biệt các tác nhân khác nhau (người dùng, hệ thống, Firebase)

4. **Công cụ vẽ**:
   - Draw.io (diagrams.net)
   - Lucidchart
   - Visual Paradigm
   - PlantUML
   - Microsoft Visio 