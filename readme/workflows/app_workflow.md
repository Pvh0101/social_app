# Luồng Hoạt Động Của Ứng Dụng Mạng Xã Hội

## 1. Khởi Động Ứng Dụng
### 1.1 Khởi Tạo
- Ứng dụng khởi động với màn hình splash (flutter_native_splash)
- Kiểm tra trạng thái đăng nhập (Firebase Auth)
- Khởi tạo các service cần thiết:
  + Firebase Core
  + Firebase Auth
  + Firestore
  + Firebase Storage
  + Firebase Messaging
  + Local Storage (Hive)
  + Image Cache Manager
  + Network Connectivity
- Load ngôn ngữ mặc định (easy_localization)
- Khởi tạo theme và các cài đặt UI

### 1.2 Kiểm Tra Kết Nối
- Kiểm tra kết nối internet
- Kiểm tra trạng thái Firebase
- Kiểm tra quyền truy cập (Camera, Storage, etc.)
- Khởi tạo các listener cho realtime updates

## 2. Xác Thực Người Dùng (Authentication)
### 2.1 Đăng Nhập
- Người dùng nhập email và mật khẩu
- Validate dữ liệu đầu vào:
  + Kiểm tra định dạng email
  + Kiểm tra độ dài mật khẩu
  + Kiểm tra ký tự đặc biệt
- Firebase Auth xác thực thông tin
- Lưu token và thông tin người dùng:
  + JWT token
  + Refresh token
  + User profile data
  + Preferences
- Cập nhật trạng thái đăng nhập trong Riverpod
- Chuyển hướng đến màn hình chính
- Khởi tạo các listener cho realtime updates

### 2.2 Đăng Ký
- Người dùng điền thông tin cơ bản:
  + Email
  + Mật khẩu
  + Tên hiển thị
  + Ngày sinh
  + Giới tính
- Validate dữ liệu đầu vào
- Upload ảnh đại diện:
  + Chọn ảnh từ gallery hoặc camera
  + Nén ảnh (flutter_image_compress)
  + Upload lên Firebase Storage
  + Lấy URL ảnh
- Tạo tài khoản mới trong Firebase Auth
- Tạo profile trong Firestore với các thông tin:
  + User ID
  + Email
  + Display name
  + Avatar URL
  + Created date
  + Last login
  + Status
- Tạo các collection cần thiết:
  + Friends
  + Followers
  + Following
  + Posts
  + Notifications
- Chuyển hướng đến màn hình chính
- Gửi email xác thực

### 2.3 Quên Mật Khẩu
- Người dùng nhập email
- Validate email
- Gửi email khôi phục mật khẩu
- Xác thực email
- Đặt lại mật khẩu mới:
  + Validate độ mạnh mật khẩu
  + Cập nhật trong Firebase Auth
  + Thông báo thành công

## 3. Màn Hình Chính (Home)
### 3.1 Feed Bài Viết
- Load danh sách bài viết từ Firestore:
  + Lấy bài viết từ bạn bè
  + Lấy bài viết từ người dùng đang follow
  + Sắp xếp theo thời gian
- Hiển thị theo dạng grid (flutter_staggered_grid_view):
  + Responsive layout
  + Tối ưu hiển thị theo kích thước màn hình
  + Lazy loading cho từng item
- Lazy loading và pagination:
  + Load 10 bài viết mỗi lần
  + Infinite scroll
  + Loading indicator
- Cache hình ảnh (cached_network_image):
  + Tự động cache khi xem
  + Xóa cache khi hết hạn
  + Preload hình ảnh
- Pull to refresh:
  + Cập nhật bài viết mới
  + Hiển thị loading animation
  + Xử lý lỗi khi refresh

### 3.2 Tạo Bài Viết Mới
- Chọn media:
  + Hỗ trợ nhiều ảnh (tối đa 10 ảnh)
  + Hỗ trợ video (tối đa 1 video)
  + Preview media trước khi đăng
- Xử lý media:
  + Nén ảnh (flutter_image_compress)
  + Nén video
  + Tối ưu kích thước file
- Upload lên Firebase Storage:
  + Progress indicator
  + Retry mechanism
  + Error handling
- Tạo bài viết trong Firestore:
  + Post ID
  + User ID
  + Media URLs
  + Caption
  + Hashtags
  + Location (optional)
  + Created date
  + Privacy settings
- Cập nhật UI realtime:
  + Thêm bài viết vào đầu feed
  + Cập nhật số lượng bài viết
  + Thông báo cho followers

## 4. Hồ Sơ Người Dùng (Profile)
### 4.1 Xem Hồ Sơ
- Hiển thị thông tin cá nhân:
  + Avatar
  + Tên hiển thị
  + Bio
  + Website
  + Số bài viết
  + Số người theo dõi
  + Số người đang theo dõi
- Danh sách bài viết:
  + Grid view
  + Tab view (Posts, Saved, Tagged)
  + Filter theo thời gian
- Thống kê:
  + Số lượt xem
  + Số lượt thích
  + Số lượt bình luận
  + Tương tác trung bình

### 4.2 Chỉnh Sửa Hồ Sơ
- Cập nhật thông tin cá nhân:
  + Validate dữ liệu
  + Cập nhật Firestore
  + Cập nhật UI realtime
- Thay đổi ảnh đại diện:
  + Upload ảnh mới
  + Crop và resize
  + Cập nhật URL trong Firestore
- Cài đặt quyền riêng tư:
  + Ai có thể xem bài viết
  + Ai có thể nhắn tin
  + Ai có thể follow

## 5. Tính Năng Bạn Bè (Friends)
### 5.1 Tìm Kiếm Bạn Bè
- Tìm kiếm theo:
  + Tên
  + Email
  + Username
  + Số điện thoại
- Kết quả tìm kiếm:
  + Hiển thị avatar
  + Tên hiển thị
  + Trạng thái kết bạn
  + Nút tương tác
- Gửi lời mời kết bạn:
  + Tạo friend request
  + Gửi thông báo
  + Cập nhật UI
- Xử lý yêu cầu kết bạn:
  + Chấp nhận/từ chối
  + Thông báo kết quả
  + Cập nhật danh sách bạn bè

### 5.2 Quản Lý Bạn Bè
- Danh sách bạn bè:
  + Phân loại theo trạng thái
  + Tìm kiếm trong danh sách
  + Sắp xếp theo tên/ngày thêm
- Danh sách người theo dõi:
  + Hiển thị số lượng
  + Phân loại theo tương tác
  + Quản lý follow/unfollow
- Chặn/bỏ chặn người dùng:
  + Thêm vào danh sách đen
  + Ẩn nội dung
  + Ngăn tương tác

## 6. Tin Nhắn (Chat)
### 6.1 Danh Sách Chat
- Hiển thị các cuộc trò chuyện:
  + Avatar người dùng
  + Tên hiển thị
  + Tin nhắn cuối
  + Thời gian
- Số tin nhắn chưa đọc:
  + Badge hiển thị số lượng
  + Đánh dấu đã đọc
  + Cập nhật realtime
- Sắp xếp theo:
  + Tin nhắn mới nhất
  + Tên người dùng
  + Trạng thái online

### 6.2 Trò Chuyện
- Gửi/nhận tin nhắn:
  + Text với emoji
  + Hình ảnh
  + Video
  + File
- Tính năng chat:
  + Typing indicator
  + Đã xem
  + Đã nhận
  + Reply tin nhắn
- Quản lý chat:
  + Xóa tin nhắn
  + Xóa cuộc trò chuyện
  + Chặn người dùng
  + Báo cáo spam

## 7. Thông Báo (Notifications)
### 7.1 Push Notifications
- Đăng ký FCM token:
  + Lưu token vào Firestore
  + Cập nhật khi token thay đổi
  + Xử lý khi token hết hạn
- Loại thông báo:
  + Bài viết mới từ bạn bè
  + Tin nhắn mới
  + Yêu cầu kết bạn
  + Mention trong bài viết
  + Like và comment
  + Tag trong ảnh
- Cài đặt thông báo:
  + Bật/tắt theo loại
  + Thời gian nhận
  + Âm thanh và rung

### 7.2 Quản Lý Thông Báo
- Xem lịch sử:
  + Phân loại theo loại
  + Sắp xếp theo thời gian
  + Tìm kiếm
- Tương tác:
  + Đánh dấu đã đọc
  + Xóa thông báo
  + Xóa tất cả
  + Mute người dùng

## 8. Cài Đặt (Settings)
### 8.1 Cài Đặt Chung
- Ngôn ngữ:
  + Danh sách ngôn ngữ hỗ trợ
  + Tự động theo hệ thống
  + Lưu preference
- Giao diện:
  + Chế độ tối/sáng
  + Font size
  + Animation
  + Layout
- Thông báo:
  + Push notifications
  + Email notifications
  + In-app notifications
- Quyền truy cập:
  + Camera
  + Storage
  + Location
  + Microphone

### 8.2 Bảo Mật
- Mật khẩu:
  + Đổi mật khẩu
  + Xác thực hai yếu tố
  + Recovery email
- Thiết bị:
  + Danh sách thiết bị đăng nhập
  + Xóa thiết bị
  + Thông báo đăng nhập mới
- Quyền riêng tư:
  + Profile visibility
  + Post visibility
  + Message settings
  + Blocked users

## 9. Xử Lý Lỗi và Tối Ưu
### 9.1 Xử Lý Lỗi
- Kết nối:
  + Kiểm tra internet
  + Retry mechanism
  + Offline mode
- Request:
  + Timeout handling
  + Rate limiting
  + Error messages
- UI:
  + Loading states
  + Error states
  + Empty states
- Logging:
  + Error tracking
  + Analytics
  + Crash reporting

### 9.2 Tối Ưu Hiệu Suất
- Cache:
  + Local storage (Hive)
  + Image cache
  + API response cache
- Media:
  + Lazy loading
  + Image compression
  + Video optimization
- Database:
  + Index optimization
  + Query optimization
  + Batch operations
- UI:
  + Widget optimization
  + Memory management
  + Frame rate optimization

## 10. Bảo Mật
### 10.1 Xác Thực
- Token:
  + JWT token
  + Refresh token
  + Token rotation
- Session:
  + Session management
  + Auto logout
  + Multiple devices
- Security:
  + Password hashing
  + Rate limiting
  + IP blocking

### 10.2 Dữ Liệu
- Local:
  + Data encryption
  + Secure storage
  + Cache management
- Cloud:
  + Firestore rules
  + Storage rules
  + API security
- Network:
  + SSL/TLS
  + Request signing
  + Data validation

## 11. Đa Nền Tảng
### 11.1 Mobile
- Android:
  + Material Design
  + Native features
  + Performance optimization
- iOS:
  + Cupertino Design
  + Native features
  + Performance optimization

### 11.2 Desktop
- Windows:
  + Windows UI
  + Native features
  + Performance optimization
- macOS:
  + macOS UI
  + Native features
  + Performance optimization
- Linux:
  + Linux UI
  + Native features
  + Performance optimization

### 11.3 Web
- Responsive design
- Progressive Web App
- Browser compatibility
- Performance optimization

## 12. Cập Nhật và Bảo Trì
### 12.1 Cập Nhật
- Version:
  + Semantic versioning
  + Changelog
  + Release notes
- Migration:
  + Database migration
  + Schema updates
  + Data migration
- Deployment:
  + CI/CD pipeline
  + Automated testing
  + Rollback plan

### 12.2 Bảo Trì
- Monitoring:
  + Performance metrics
  + Error tracking
  + Usage analytics
- Maintenance:
  + Regular updates
  + Security patches
  + Bug fixes
- Support:
  + User feedback
  + Bug reports
  + Feature requests 