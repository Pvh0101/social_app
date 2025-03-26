# Prompts cho Xử lý Media trong Flutter

## 1. Chọn file (File Picking)
```
Phát triển chức năng chọn file media từ thiết bị người dùng:

Yêu cầu chức năng:
- Chọn ảnh từ thư viện (đơn/nhiều ảnh)
- Chụp ảnh trực tiếp từ camera
- Chọn video từ thư viện
- Chọn tệp âm thanh
- Xử lý quyền truy cập (permissions)
- Hỗ trợ cấu hình giới hạn kích thước/thời lượng file
- Xử lý lỗi khi người dùng từ chối cấp quyền

Các thư viện có thể sử dụng:
- image_picker: Chọn ảnh/video từ thư viện hoặc camera
- file_picker: Chọn nhiều loại file khác nhau
- permission_handler: Quản lý quyền truy cập
- photo_manager: Quản lý assets phức tạp hơn
```

## 2. Xử lý file (File Processing)
```
Phát triển chức năng xử lý các loại file media khác nhau:

Yêu cầu chức năng:
- Nén ảnh với nhiều cấp độ chất lượng
- Resize ảnh theo kích thước mong muốn
- Tạo thumbnail cho video
- Nén video để giảm dung lượng
- Cắt/xoay ảnh và video
- Xử lý batch cho nhiều file
- Xử lý không đồng bộ trong background

Các thư viện có thể sử dụng:
- flutter_image_compress: Nén ảnh hiệu quả
- image: Xử lý ảnh toàn diện
- get_thumbnail_video: Tạo thumbnail từ video
- video_compress: Nén video
- image_cropper: Cắt và chỉnh sửa ảnh

```

## 3. Upload file (File Uploading)
```
Phát triển chức năng tải lên file media lên hệ thống lưu trữ:

Yêu cầu chức năng:
- Upload file lên Firebase Storage
- Hỗ trợ upload đồng thời nhiều file
- Theo dõi tiến trình upload (progress tracking)
- Hủy upload đang thực hiện
- Retry tự động khi mất kết nối
- Upload trong background
- Xử lý lỗi upload và recovery
- Tối ưu băng thông sử dụng

Các thư viện có thể sử dụng:
- firebase_storage: Upload file lên Firebase Storage
- retry: Tự động thử lại các tác vụ thất bại
```

## 4. Hiển thị file (File Display)
```
Phát triển chức năng hiển thị các loại media từ URL:

Yêu cầu chức năng:
- Hiển thị ảnh từ URL với loading placeholders
- Caching ảnh để tối ưu hiệu suất
- Phát video với controls tùy chỉnh
- Phát âm thanh với visualizer
- Zoom, pan và các tương tác với ảnh
- Lazy loading cho danh sách dài
- Xử lý lỗi hiển thị (error handling)
- Hỗ trợ đa định dạng (HEIC, WebP, v.v.)
-có chế độ toàn màn hình

Các thư viện có thể sử dụng:
- cached_network_image: Hiển thị ảnh với caching
- photo_view: Zoom và pan ảnh
- better_video_player_plus: Phát video với controls tùy chỉnh
- video_player: Plugin phát video cơ bản
- just_audio: Phát âm thanh

```

## 5. Xóa video (Video Deletion)
```
Phát triển chức năng xóa video an toàn:

Yêu cầu chức năng:
- Xóa video từ Firebase Storage
- Xóa metadata liên quan từ Firestore
- Xóa đồng thời nhiều video (batch delete)
- Xác thực quyền xóa
- Soft delete (đánh dấu đã xóa) và hard delete (xóa thực sự)
- Xóa media orphan (không có tham chiếu)
- Cung cấp API để kiểm tra video còn tồn tại không

Các thư viện có thể sử dụng:
- firebase_storage: Xóa file từ Firebase Storage
- cloud_firestore: Xóa metadata từ Firestore
- firebase_auth: Xác thực người dùng
```

## 6. Quản lý bộ nhớ cache (Cache Management)
```
Phát triển chức năng quản lý bộ nhớ cache cho media:

Yêu cầu chức năng:
- Caching file media đã tải
- Quản lý dung lượng cache tối đa


Các thư viện có thể sử dụng:
- flutter_cache_manager: Quản lý cache toàn diện
- 
- path_provider: Truy cập đường dẫn lưu trữ
```

## 7. Ví dụ tích hợp toàn bộ luồng xử lý media
```
Phát triển luồng xử lý media hoàn chỉnh từ chọn đến hiển thị:

Yêu cầu chức năng:
- Tích hợp toàn bộ các bước: chọn → xử lý → upload → hiển thị
- Sử dụng state management (Riverpod/BLoC)
- Hiển thị tiến trình xử lý cho người dùng
- Xử lý lỗi ở mỗi bước và recovery
- Tối ưu sử dụng tài nguyên hệ thống
- Đảm bảo UX mượt mà không bị blocking UI

Luồng xử lý:
1. Chọn media với image_picker
2. Nén/xử lý với flutter_image_compress hoặc video_compress
3. Upload lên Firebase Storage với firebase_storage
4. Lưu metadata vào Firestore
5. Hiển thị với cached_network_image hoặc better_video_player_plus
6. Quản lý cache với flutter_cache_manager
```

## Prompts cho Phân tích và Cải thiện Hệ thống Media

### Phân tích Hệ thống Media Hiện tại
```
Hãy phân tích code của tôi để xử lý media (hình ảnh, video, audio) và chỉ ra những ưu điểm, nhược điểm cũng như các cơ hội cải thiện. Tập trung vào các khía cạnh:
1. Cấu trúc code và tổ chức
2. Hiệu suất xử lý
3. Trải nghiệm người dùng
4. Khả năng mở rộng
5. Quản lý bộ nhớ
```

### Thiết kế Kiến trúc Media Tối ưu
```
Thiết kế một kiến trúc xử lý media tối ưu cho ứng dụng Flutter, bao gồm:
1. Mô hình domain
2. Các lớp repository và service
3. State management
4. Caching và tối ưu hiệu suất
5. Xử lý lỗi và edge cases
```

### Tối ưu Hiệu suất Media
```
Phân tích và đề xuất các giải pháp tối ưu hiệu suất xử lý media trong ứng dụng của tôi:
1. Nén và tối ưu kích thước media
2. Lazy loading và caching
3. Giảm thiểu sử dụng bộ nhớ
4. Tối ưu đa nền tảng (Android, iOS, Web)
```

## Prompts cho Xây dựng Tính năng Media

### Chức năng Xử lý Media Đa năng
```
Tôi cần một phương thức xử lý media đa năng để thay thế các phương thức riêng lẻ hiện tại. Phương thức này cần hỗ trợ:
1. Chọn nhiều loại media (ảnh, video, audio)
2. Hỗ trợ cả camera và gallery
3. Xử lý quyền truy cập
4. Nén và tối ưu file
5. Upload lên cloud storage
6. Tracking tiến trình và xử lý lỗi
```

### Triển khai Media Player
```
Thiết kế và triển khai một media player tùy chỉnh hỗ trợ:
1. Video playback với controls tùy chỉnh
2. Audio playback với visualizer
3. Streaming từ các nguồn khác nhau
4. Picture-in-picture và background playback
5. Caching nội dung
```

### Xử lý Ảnh Nâng cao
```
Xây dựng các tính năng xử lý ảnh nâng cao trong ứng dụng Flutter:
1. Các bộ lọc và hiệu ứng
2. Cắt, xoay, điều chỉnh kích thước
3. Vẽ và chú thích
4. Đánh dấu mặt và vật thể
5. Tối ưu và nén ảnh không làm giảm chất lượng đáng kể
```

## Prompts cho Testing và Debugging

### Kiểm thử Hệ thống Media
```
Phát triển chiến lược kiểm thử toàn diện cho hệ thống xử lý media:
1. Unit tests cho các thành phần riêng lẻ
2. Integration tests cho luồng xử lý media
3. UI tests cho các màn hình liên quan đến media
4. Testing trên nhiều thiết bị và kích thước màn hình
5. Stress testing với file lớn và số lượng lớn
```

### Debug Vấn đề Media Phổ biến
```
Phân tích và đề xuất giải pháp cho các vấn đề media phổ biến trong ứng dụng Flutter:
1. Rò rỉ bộ nhớ khi xử lý file lớn
2. Hiệu suất kém trên thiết bị cũ
3. Các vấn đề về quyền truy cập
4. Sự khác biệt giữa iOS và Android
5. Xử lý lỗi khi mạng không ổn định
```

## Prompts cho Phát triển Dịch vụ Media

### 1. MediaPickerService (media_picker_service.dart)
```
Phát triển dịch vụ chọn media hoàn chỉnh hỗ trợ:
1. Chọn ảnh/video từ thư viện (đơn lẻ và nhiều)
2. Chụp ảnh/quay video trực tiếp từ camera
3. Xử lý quyền truy cập thông minh (camera, gallery, microphone)
4. Phân loại và lọc theo loại media (ảnh, video, audio)
5. Giới hạn kích thước/thời lượng media
6. Hỗ trợ đồng bộ với các phiên bản Android và iOS mới nhất
```

### 2. MediaProcessorService (media_processor_service.dart)
```
Xây dựng dịch vụ xử lý media với các chức năng:
1. Nén ảnh với nhiều cấp độ chất lượng và kích thước
2. Tạo và quản lý thumbnail cho video
3. Cắt và điều chỉnh kích thước media
4. Trích xuất metadata (EXIF, geolocation, thời lượng)
5. Chuyển đổi định dạng (WebP, HEIF, MP4, v.v.)
6. Xử lý media không đồng bộ và trong background
```

### 3. MediaUploadService (media_upload_service.dart)
```
Triển khai dịch vụ tải lên media lên Firebase Storage:
1. Tải lên đồng thời nhiều file với hàng đợi
2. Theo dõi tiến trình tải lên chi tiết
3. Pause, resume và cancel tải lên
4. Retry tự động khi mất kết nối
5. Tối ưu hóa băng thông (nén trước khi tải lên)
6. Background upload và tiếp tục khi app khởi động lại
```

### 4. MediaRepository (media_repository.dart)
```
Phát triển repository để lưu trữ metadata media vào Firestore:
1. Lưu trữ thông tin media (url, type, size, duration, v.v.)
2. Quan hệ giữa media và các entity khác (user, post, message)
3. Pagination và query hiệu quả
4. Đồng bộ hai chiều giữa Storage và Firestore
5. Offline support và caching thông minh
6. Quản lý thời gian sống của media
```

### 5. MediaDisplayService (media_display_service.dart)
```
Tạo dịch vụ hiển thị media đa năng:
1. Lazy loading và caching hình ảnh hiệu quả
2. Xử lý video streaming với nhiều độ phân giải
3. Preload media khi cần thiết
4. Hiển thị media trong các định dạng khác nhau (grid, list, carousel)
5. Placeholder và skeleton loading UI
6. Xử lý lỗi khi không thể tải/hiển thị media
```

### 6. MediaDeleteService (media_delete_service.dart)
```
Phát triển dịch vụ xóa media an toàn:
1. Xóa đồng bộ giữa Storage và Firestore
2. Batch delete nhiều media
3. Soft delete và hard delete
4. Khôi phục media đã xóa (nếu cần)
5. Xóa media orphan (không có reference)
6. Quản lý quyền xóa và kiểm tra trước khi xóa
```

## Prompts cho Hiện thực hóa Kiến trúc Media

### Triển khai Repository Pattern
```
Phát triển một media repository pattern hoàn chỉnh cho ứng dụng Flutter:
1. Interface định nghĩa
2. Implemention với Firebase Storage
3. Dependency injection
4. Caching và offline support
5. Testing với mock repository
```

### Xây dựng Media State Management
```
Thiết kế state management cho hệ thống media dùng Riverpod:
1. Media providers và notifiers
2. Quản lý trạng thái tải lên/tải xuống
3. Trạng thái xử lý media
4. Đồng bộ trạng thái giữa các màn hình
5. Persistence state
```

### Tạo Media Widgets Tái sử dụng
```
Phát triển bộ widgets media tái sử dụng cao:
1. Media preview với nhiều loại (image, video, audio)
2. Media grid và list
3. Media player controls
4. Upload progress indicators
5. Media selection UI components
``` 