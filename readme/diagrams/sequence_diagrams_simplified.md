# Sơ Đồ Tuần Tự Đơn Giản (Sequence Diagram) Cho Các Chức Năng Chính

Tài liệu này chứa các sơ đồ tuần tự đơn giản hóa cho các chức năng chính của ứng dụng Social App, sử dụng 3 lane cơ bản.

## 1. Chức Năng Đăng Ký

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập thông tin đăng ký (email, mật khẩu)
App -> DB: Tạo tài khoản (Firebase Auth)
DB --> App: Trả về kết quả xác thực
App -> DB: Gửi email xác minh
App -> DB: Tạo document người dùng (Firestore)
App --> User: Hiển thị kết quả đăng ký

User -> App: Nhập thông tin cá nhân và ảnh đại diện
App -> DB: Upload ảnh đại diện (Storage)
DB --> App: Trả về URL ảnh
App -> DB: Cập nhật thông tin người dùng (Firestore)
App --> User: Chuyển đến màn hình chính
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Nhập thông tin đăng ký (email, mật khẩu)
    App->>DB: Tạo tài khoản (Firebase Auth)
    DB-->>App: Trả về kết quả xác thực
    App->>DB: Gửi email xác minh
    App->>DB: Tạo document người dùng (Firestore)
    App-->>User: Hiển thị kết quả đăng ký
    
    User->>App: Nhập thông tin cá nhân và ảnh đại diện
    App->>DB: Upload ảnh đại diện (Storage)
    DB-->>App: Trả về URL ảnh
    App->>DB: Cập nhật thông tin người dùng (Firestore)
    App-->>User: Chuyển đến màn hình chính
```

## 2. Chức Năng Đăng Nhập

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập email và mật khẩu
App -> DB: Xác thực đăng nhập (Firebase Auth)
DB --> App: Trả về kết quả xác thực
App -> DB: Kiểm tra trạng thái xác minh email
DB --> App: Trả về trạng thái xác minh
App -> DB: Cập nhật trạng thái online (Firestore)
App -> DB: Cập nhật FCM token (Firestore)
App --> User: Chuyển đến màn hình chính hoặc hiển thị lỗi
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Nhập email và mật khẩu
    App->>DB: Xác thực đăng nhập (Firebase Auth)
    DB-->>App: Trả về kết quả xác thực
    App->>DB: Kiểm tra trạng thái xác minh email
    DB-->>App: Trả về trạng thái xác minh
    App->>DB: Cập nhật trạng thái online (Firestore)
    App->>DB: Cập nhật FCM token (Firestore)
    App-->>User: Chuyển đến màn hình chính hoặc hiển thị lỗi
```

## 3. Chức Năng Nhắn Tin

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập tin nhắn
App -> DB: Lưu tin nhắn (Firestore)
App -> DB: Cập nhật thông tin cuộc trò chuyện (Firestore)
DB --> App: Trả về kết quả
App --> User: Hiển thị tin nhắn đã gửi

User -> App: Chọn gửi media (hình ảnh/video)
App -> DB: Upload file media (Storage)
DB --> App: Trả về URL media
App -> DB: Lưu tin nhắn với URL media (Firestore)
App -> DB: Cập nhật thông tin cuộc trò chuyện (Firestore)
DB --> App: Trả về kết quả
App --> User: Hiển thị media đã gửi

note right of DB: Firebase gửi thông báo đẩy
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Nhập tin nhắn
    App->>DB: Lưu tin nhắn (Firestore)
    App->>DB: Cập nhật thông tin cuộc trò chuyện (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Hiển thị tin nhắn đã gửi
    
    User->>App: Chọn gửi media (hình ảnh/video)
    App->>DB: Upload file media (Storage)
    DB-->>App: Trả về URL media
    App->>DB: Lưu tin nhắn với URL media (Firestore)
    App->>DB: Cập nhật thông tin cuộc trò chuyện (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Hiển thị media đã gửi
    
    Note right of DB: Firebase gửi thông báo đẩy
```

## 4. Chức Năng Xem Thông Báo Bảng Tin

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Mở ứng dụng/Kéo để làm mới
App -> DB: Truy vấn bài viết (Firestore)
DB --> App: Trả về danh sách bài viết
App --> User: Hiển thị bài viết

User -> App: Cuộn xuống cuối danh sách
App -> DB: Truy vấn thêm bài viết (Firestore)
DB --> App: Trả về thêm bài viết
App --> User: Hiển thị thêm bài viết

User -> App: Thích bài viết
App -> DB: Cập nhật trạng thái thích (Firestore)
App -> DB: Tăng số lượt thích (Firestore)
DB --> App: Trả về kết quả
App --> User: Cập nhật UI (nút like, số lượt thích)
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Mở ứng dụng/Kéo để làm mới
    App->>DB: Truy vấn bài viết (Firestore)
    DB-->>App: Trả về danh sách bài viết
    App-->>User: Hiển thị bài viết
    
    User->>App: Cuộn xuống cuối danh sách
    App->>DB: Truy vấn thêm bài viết (Firestore)
    DB-->>App: Trả về thêm bài viết
    App-->>User: Hiển thị thêm bài viết
    
    User->>App: Thích bài viết
    App->>DB: Cập nhật trạng thái thích (Firestore)
    App->>DB: Tăng số lượt thích (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Cập nhật UI (nút like, số lượt thích)
```

## 5. Chức Năng Quản Lý Thông Tin Hồ Sơ Cá Nhân

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Xem hồ sơ cá nhân
App -> DB: Truy vấn thông tin người dùng (Firestore)
DB --> App: Trả về thông tin người dùng
App -> DB: Truy vấn bài viết của người dùng (Firestore)
DB --> App: Trả về bài viết
App --> User: Hiển thị thông tin và bài viết

User -> App: Chỉnh sửa hồ sơ
App -> DB: Upload ảnh đại diện mới (nếu có) (Storage)
DB --> App: Trả về URL ảnh (nếu có)
App -> DB: Cập nhật thông tin người dùng (Firestore)
DB --> App: Trả về kết quả
App --> User: Hiển thị thông tin đã cập nhật
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Xem hồ sơ cá nhân
    App->>DB: Truy vấn thông tin người dùng (Firestore)
    DB-->>App: Trả về thông tin người dùng
    App->>DB: Truy vấn bài viết của người dùng (Firestore)
    DB-->>App: Trả về bài viết
    App-->>User: Hiển thị thông tin và bài viết
    
    User->>App: Chỉnh sửa hồ sơ
    App->>DB: Upload ảnh đại diện mới (nếu có) (Storage)
    DB-->>App: Trả về URL ảnh (nếu có)
    App->>DB: Cập nhật thông tin người dùng (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Hiển thị thông tin đã cập nhật
```

## 6. Chức Năng Quản Lý Bài Viết

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập nội dung và chọn media
App -> DB: Upload media (Storage)
DB --> App: Trả về URL media
App -> DB: Tạo bài viết mới (Firestore)
DB --> App: Trả về kết quả
App --> User: Chuyển về màn hình feed

User -> App: Chọn chỉnh sửa bài viết
App -> DB: Truy vấn thông tin bài viết (Firestore)
DB --> App: Trả về thông tin bài viết
App --> User: Hiển thị form chỉnh sửa

User -> App: Cập nhật nội dung
App -> DB: Cập nhật bài viết (Firestore)
DB --> App: Trả về kết quả
App --> User: Hiển thị bài viết đã cập nhật

User -> App: Chọn xóa bài viết
App -> DB: Truy vấn thông tin bài viết (Firestore)
DB --> App: Trả về thông tin bài viết (với URL media)
App -> DB: Xóa media (Storage)
App -> DB: Xóa bài viết (Firestore)
App -> DB: Xóa comments và likes (Firestore)
DB --> App: Trả về kết quả
App --> User: Chuyển về màn hình feed
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Nhập nội dung và chọn media
    App->>DB: Upload media (Storage)
    DB-->>App: Trả về URL media
    App->>DB: Tạo bài viết mới (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Chuyển về màn hình feed
    
    User->>App: Chọn chỉnh sửa bài viết
    App->>DB: Truy vấn thông tin bài viết (Firestore)
    DB-->>App: Trả về thông tin bài viết
    App-->>User: Hiển thị form chỉnh sửa
    
    User->>App: Cập nhật nội dung
    App->>DB: Cập nhật bài viết (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Hiển thị bài viết đã cập nhật
    
    User->>App: Chọn xóa bài viết
    App->>DB: Truy vấn thông tin bài viết (Firestore)
    DB-->>App: Trả về thông tin bài viết (với URL media)
    App->>DB: Xóa media (Storage)
    App->>DB: Xóa bài viết (Firestore)
    App->>DB: Xóa comments và likes (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Chuyển về màn hình feed
```

## 7. Chức Năng Quản Lý Bạn Bè

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Tìm kiếm người dùng
App -> DB: Truy vấn người dùng (Firestore)
DB --> App: Trả về kết quả tìm kiếm
App --> User: Hiển thị kết quả tìm kiếm

User -> App: Gửi lời mời kết bạn
App -> DB: Tạo lời mời kết bạn (Firestore)
App -> DB: Tạo thông báo (Firestore)
DB --> App: Trả về kết quả
App --> User: Cập nhật UI (nút đã gửi lời mời)

User -> App: Xem lời mời kết bạn
App -> DB: Truy vấn lời mời kết bạn (Firestore)
DB --> App: Trả về danh sách lời mời
App --> User: Hiển thị danh sách lời mời

User -> App: Chấp nhận lời mời kết bạn
App -> DB: Tạo mối quan hệ bạn bè (Firestore)
App -> DB: Xóa lời mời kết bạn (Firestore)
App -> DB: Tạo thông báo (Firestore)
DB --> App: Trả về kết quả
App --> User: Cập nhật UI (thêm vào danh sách bạn bè)
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Tìm kiếm người dùng
    App->>DB: Truy vấn người dùng (Firestore)
    DB-->>App: Trả về kết quả tìm kiếm
    App-->>User: Hiển thị kết quả tìm kiếm
    
    User->>App: Gửi lời mời kết bạn
    App->>DB: Tạo lời mời kết bạn (Firestore)
    App->>DB: Tạo thông báo (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Cập nhật UI (nút đã gửi lời mời)
    
    User->>App: Xem lời mời kết bạn
    App->>DB: Truy vấn lời mời kết bạn (Firestore)
    DB-->>App: Trả về danh sách lời mời
    App-->>User: Hiển thị danh sách lời mời
    
    User->>App: Chấp nhận lời mời kết bạn
    App->>DB: Tạo mối quan hệ bạn bè (Firestore)
    App->>DB: Xóa lời mời kết bạn (Firestore)
    App->>DB: Tạo thông báo (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Cập nhật UI (thêm vào danh sách bạn bè)
```

## 8. Chức Năng Quản Lý Nhóm Chat

### PlantUML

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập tên nhóm và chọn thành viên
App -> DB: Upload ảnh nhóm (nếu có) (Storage)
DB --> App: Trả về URL ảnh (nếu có)
App -> DB: Tạo nhóm chat (Firestore)
App -> DB: Tạo tin nhắn hệ thống (Firestore)
DB --> App: Trả về kết quả
App --> User: Chuyển đến màn hình chat

User -> App: Xem thông tin nhóm
App -> DB: Truy vấn thông tin nhóm (Firestore)
DB --> App: Trả về thông tin nhóm
App -> DB: Truy vấn thông tin thành viên (Firestore)
DB --> App: Trả về thông tin thành viên
App --> User: Hiển thị thông tin nhóm

User -> App: Thêm thành viên
App -> DB: Cập nhật danh sách thành viên (Firestore)
App -> DB: Tạo tin nhắn hệ thống (Firestore)
DB --> App: Trả về kết quả
App --> User: Cập nhật danh sách thành viên

User -> App: Rời nhóm
App -> DB: Cập nhật danh sách thành viên (Firestore)
App -> DB: Tạo tin nhắn hệ thống (Firestore)
DB --> App: Trả về kết quả
App --> User: Chuyển về màn hình danh sách chat
@enduml
```

### Mermaid

```mermaid
sequenceDiagram
    actor User as Người dùng
    participant App as Ứng dụng
    participant DB as Database
    
    User->>App: Nhập tên nhóm và chọn thành viên
    App->>DB: Upload ảnh nhóm (nếu có) (Storage)
    DB-->>App: Trả về URL ảnh (nếu có)
    App->>DB: Tạo nhóm chat (Firestore)
    App->>DB: Tạo tin nhắn hệ thống (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Chuyển đến màn hình chat
    
    User->>App: Xem thông tin nhóm
    App->>DB: Truy vấn thông tin nhóm (Firestore)
    DB-->>App: Trả về thông tin nhóm
    App->>DB: Truy vấn thông tin thành viên (Firestore)
    DB-->>App: Trả về thông tin thành viên
    App-->>User: Hiển thị thông tin nhóm
    
    User->>App: Thêm thành viên
    App->>DB: Cập nhật danh sách thành viên (Firestore)
    App->>DB: Tạo tin nhắn hệ thống (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Cập nhật danh sách thành viên
    
    User->>App: Rời nhóm
    App->>DB: Cập nhật danh sách thành viên (Firestore)
    App->>DB: Tạo tin nhắn hệ thống (Firestore)
    DB-->>App: Trả về kết quả
    App-->>User: Chuyển về màn hình danh sách chat
``` 