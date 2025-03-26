# Biểu Đồ Tuần Tự Chi Tiết (Sequence Diagram) Cho Các Chức Năng

Tài liệu này chứa các biểu đồ tuần tự chi tiết cho 14 chức năng chính của ứng dụng Social App, sử dụng 3 lane cơ bản.

## 1. Biểu Đồ Tuần Tự – Chức Năng Đăng Ký

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập thông tin đăng ký (email, mật khẩu)
App -> DB: Kiểm tra email đã tồn tại
DB --> App: Trả về kết quả kiểm tra

alt Email đã tồn tại
    App --> User: Thông báo email đã được sử dụng
else Email chưa tồn tại
    App -> DB: Tạo tài khoản (Firebase Auth)
    DB --> App: Trả về kết quả xác thực
    
    alt Đăng ký thành công
        App -> DB: Gửi email xác minh
        App -> DB: Tạo document người dùng (Firestore)
        App --> User: Hiển thị màn hình nhập thông tin cá nhân
        
        User -> App: Nhập thông tin cá nhân và ảnh đại diện
        App -> DB: Upload ảnh đại diện (Storage)
        DB --> App: Trả về URL ảnh
        App -> DB: Cập nhật thông tin người dùng (Firestore)
        App --> User: Chuyển đến màn hình chính
    else Đăng ký thất bại
        App --> User: Hiển thị thông báo lỗi
    end
end
@enduml
```

## 2. Biểu Đồ Tuần Tự – Chức Năng Đăng Nhập

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Nhập email và mật khẩu
App -> DB: Xác thực đăng nhập (Firebase Auth)
DB --> App: Trả về kết quả xác thực

alt Đăng nhập thành công
    App -> DB: Kiểm tra trạng thái xác minh email
    DB --> App: Trả về trạng thái xác minh
    
    alt Email đã xác minh
        App -> DB: Lấy thông tin người dùng (Firestore)
        DB --> App: Trả về thông tin người dùng
        App -> DB: Cập nhật trạng thái online (Firestore)
        App -> DB: Cập nhật FCM token (Firestore)
        App --> User: Chuyển đến màn hình chính
    else Email chưa xác minh
        App --> User: Thông báo yêu cầu xác minh email
        User -> App: Chọn gửi lại email xác minh
        App -> DB: Gửi lại email xác minh
        App --> User: Thông báo đã gửi email xác minh
    end
else Đăng nhập thất bại
    App --> User: Hiển thị thông báo lỗi
end
@enduml
```

## 3. Biểu Đồ Tuần Tự – Chức Năng Nhắn Tin

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn cuộc trò chuyện
App -> DB: Lấy thông tin cuộc trò chuyện (Firestore)
DB --> App: Trả về thông tin cuộc trò chuyện
App -> DB: Lấy tin nhắn (Firestore)
DB --> App: Trả về danh sách tin nhắn
App --> User: Hiển thị màn hình chat

User -> App: Nhập tin nhắn
App -> DB: Lưu tin nhắn (Firestore)
App -> DB: Cập nhật thông tin cuộc trò chuyện (Firestore)
DB --> App: Trả về kết quả
App --> User: Hiển thị tin nhắn đã gửi

User -> App: Chọn gửi media (hình ảnh/video)
App -> User: Hiển thị màn hình chọn media
User -> App: Chọn file media
App -> DB: Upload file media (Storage)
DB --> App: Trả về URL media
App -> DB: Lưu tin nhắn với URL media (Firestore)
App -> DB: Cập nhật thông tin cuộc trò chuyện (Firestore)
DB --> App: Trả về kết quả
App --> User: Hiển thị media đã gửi

note right of DB: Firebase gửi thông báo đẩy đến người nhận
@enduml
```

## 4. Biểu Đồ Tuần Tự – Chức Năng Xem Thông Báo

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn tab thông báo
App -> DB: Lấy danh sách thông báo (Firestore)
DB --> App: Trả về danh sách thông báo
App --> User: Hiển thị danh sách thông báo

User -> App: Chọn một thông báo
App -> DB: Đánh dấu thông báo đã đọc (Firestore)

alt Thông báo về bài viết
    App -> DB: Lấy thông tin bài viết (Firestore)
    DB --> App: Trả về thông tin bài viết
    App --> User: Chuyển đến màn hình bài viết
else Thông báo về lời mời kết bạn
    App -> DB: Lấy thông tin lời mời kết bạn (Firestore)
    DB --> App: Trả về thông tin lời mời kết bạn
    App --> User: Chuyển đến màn hình lời mời kết bạn
else Thông báo về tin nhắn
    App -> DB: Lấy thông tin cuộc trò chuyện (Firestore)
    DB --> App: Trả về thông tin cuộc trò chuyện
    App --> User: Chuyển đến màn hình chat
end

User -> App: Chọn đánh dấu tất cả đã đọc
App -> DB: Đánh dấu tất cả thông báo đã đọc (Firestore)
DB --> App: Trả về kết quả
App --> User: Cập nhật UI (không còn thông báo mới)
@enduml
```

## 5. Biểu Đồ Tuần Tự – Chức Năng Quản Lý Thông Tin Cá Nhân

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn xem hồ sơ cá nhân
App -> DB: Lấy thông tin người dùng (Firestore)
DB --> App: Trả về thông tin người dùng
App -> DB: Lấy bài viết của người dùng (Firestore)
DB --> App: Trả về danh sách bài viết
App --> User: Hiển thị hồ sơ và bài viết

User -> App: Chọn chỉnh sửa hồ sơ
App --> User: Hiển thị form chỉnh sửa

User -> App: Cập nhật thông tin (tên, tiểu sử, v.v.)
User -> App: Chọn ảnh đại diện mới (tùy chọn)

alt Có ảnh đại diện mới
    App -> DB: Upload ảnh đại diện (Storage)
    DB --> App: Trả về URL ảnh
    App -> DB: Cập nhật thông tin người dùng với URL ảnh mới (Firestore)
else Không có ảnh đại diện mới
    App -> DB: Cập nhật thông tin người dùng (Firestore)
end

DB --> App: Trả về kết quả cập nhật
App --> User: Hiển thị thông tin đã cập nhật
@enduml
```

## 6. Biểu Đồ Tuần Tự – Chức Năng Thêm Bài Viết

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn tạo bài viết mới
App --> User: Hiển thị màn hình tạo bài viết

User -> App: Nhập nội dung bài viết
User -> App: Chọn media (tùy chọn)

alt Có media
    App -> DB: Upload media (Storage)
    DB --> App: Trả về URL media
    App -> DB: Tạo bài viết mới với URL media (Firestore)
else Không có media
    App -> DB: Tạo bài viết mới chỉ với nội dung (Firestore)
end

DB --> App: Trả về kết quả tạo bài viết

alt Tạo bài viết thành công
    App -> DB: Cập nhật số lượng bài viết của người dùng (Firestore)
    App --> User: Hiển thị thông báo thành công
    App --> User: Chuyển về màn hình feed hoặc hồ sơ
else Tạo bài viết thất bại
    App --> User: Hiển thị thông báo lỗi
end
@enduml
```

## 7. Biểu Đồ Tuần Tự – Chức Năng Chỉnh Sửa Bài Viết

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn bài viết cần chỉnh sửa
App -> DB: Lấy thông tin bài viết (Firestore)
DB --> App: Trả về thông tin bài viết
App --> User: Hiển thị màn hình chỉnh sửa bài viết

User -> App: Cập nhật nội dung bài viết
App -> DB: Cập nhật bài viết (Firestore)
DB --> App: Trả về kết quả cập nhật

alt Cập nhật thành công
    App --> User: Hiển thị thông báo thành công
    App --> User: Hiển thị bài viết đã cập nhật
else Cập nhật thất bại
    App --> User: Hiển thị thông báo lỗi
end
@enduml
```

## 8. Biểu Đồ Tuần Tự – Chức Năng Xóa Bài Viết

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn bài viết cần xóa
App -> User: Hiển thị hộp thoại xác nhận xóa
User -> App: Xác nhận xóa bài viết

App -> DB: Lấy thông tin bài viết (Firestore)
DB --> App: Trả về thông tin bài viết (với URL media)

alt Bài viết có media
    App -> DB: Xóa media (Storage)
end

App -> DB: Xóa bài viết (Firestore)
App -> DB: Xóa comments liên quan (Firestore)
App -> DB: Xóa likes liên quan (Firestore)
App -> DB: Cập nhật số lượng bài viết của người dùng (Firestore)

DB --> App: Trả về kết quả xóa

alt Xóa thành công
    App --> User: Hiển thị thông báo thành công
    App --> User: Cập nhật UI (bài viết đã bị xóa)
else Xóa thất bại
    App --> User: Hiển thị thông báo lỗi
end
@enduml
```

## 9. Biểu Đồ Tuần Tự – Chức Năng Kết Bạn

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Tìm kiếm người dùng
App -> DB: Truy vấn người dùng (Firestore)
DB --> App: Trả về kết quả tìm kiếm
App --> User: Hiển thị kết quả tìm kiếm

User -> App: Chọn người dùng
App -> DB: Lấy thông tin người dùng (Firestore)
DB --> App: Trả về thông tin người dùng
App --> User: Hiển thị hồ sơ người dùng

User -> App: Chọn gửi lời mời kết bạn
App -> DB: Kiểm tra trạng thái kết bạn hiện tại
DB --> App: Trả về trạng thái kết bạn

alt Đã là bạn bè hoặc đã gửi lời mời
    App --> User: Thông báo trạng thái hiện tại
else Chưa có mối quan hệ
    App -> DB: Tạo lời mời kết bạn (Firestore)
    App -> DB: Tạo thông báo cho người nhận (Firestore)
    DB --> App: Trả về kết quả
    App --> User: Cập nhật UI (nút đã gửi lời mời)
end
@enduml
```

## 10. Biểu Đồ Tuần Tự – Chức Năng Đồng Ý Kết Bạn

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn xem lời mời kết bạn
App -> DB: Lấy danh sách lời mời kết bạn (Firestore)
DB --> App: Trả về danh sách lời mời
App --> User: Hiển thị danh sách lời mời

User -> App: Chọn chấp nhận lời mời
App -> DB: Tạo mối quan hệ bạn bè (Firestore)
App -> DB: Xóa lời mời kết bạn (Firestore)
App -> DB: Tạo thông báo cho người gửi lời mời (Firestore)
App -> DB: Cập nhật số lượng bạn bè của cả hai người dùng (Firestore)

DB --> App: Trả về kết quả
App --> User: Cập nhật UI (thêm vào danh sách bạn bè)
App --> User: Hiển thị thông báo thành công
@enduml
```

## 11. Biểu Đồ Tuần Tự – Chức Năng Xóa Bạn Bè

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn xem danh sách bạn bè
App -> DB: Lấy danh sách bạn bè (Firestore)
DB --> App: Trả về danh sách bạn bè
App --> User: Hiển thị danh sách bạn bè

User -> App: Chọn người dùng cần hủy kết bạn
App -> User: Hiển thị hộp thoại xác nhận
User -> App: Xác nhận hủy kết bạn

App -> DB: Xóa mối quan hệ bạn bè (Firestore)
App -> DB: Cập nhật số lượng bạn bè của cả hai người dùng (Firestore)

DB --> App: Trả về kết quả
App --> User: Cập nhật UI (xóa khỏi danh sách bạn bè)
App --> User: Hiển thị thông báo thành công
@enduml
```

## 12. Biểu Đồ Tuần Tự – Chức Năng Tạo Nhóm Chat

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn tạo nhóm chat mới
App -> DB: Lấy danh sách bạn bè (Firestore)
DB --> App: Trả về danh sách bạn bè
App --> User: Hiển thị màn hình tạo nhóm

User -> App: Nhập tên nhóm
User -> App: Chọn thành viên từ danh sách bạn bè
User -> App: Chọn ảnh nhóm (tùy chọn)
User -> App: Xác nhận tạo nhóm

alt Có ảnh nhóm
    App -> DB: Upload ảnh nhóm (Storage)
    DB --> App: Trả về URL ảnh
    App -> DB: Tạo nhóm chat với URL ảnh (Firestore)
else Không có ảnh nhóm
    App -> DB: Tạo nhóm chat không có ảnh (Firestore)
end

App -> DB: Tạo tin nhắn hệ thống thông báo nhóm được tạo (Firestore)
App -> DB: Tạo thông báo cho các thành viên (Firestore)

DB --> App: Trả về kết quả
App --> User: Chuyển đến màn hình chat của nhóm
@enduml
```

## 13. Biểu Đồ Tuần Tự – Chức Năng Sửa Nhóm Chat

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn xem thông tin nhóm
App -> DB: Lấy thông tin nhóm (Firestore)
DB --> App: Trả về thông tin nhóm
App -> DB: Lấy thông tin thành viên (Firestore)
DB --> App: Trả về thông tin thành viên
App --> User: Hiển thị thông tin nhóm

User -> App: Chọn chỉnh sửa thông tin nhóm
App --> User: Hiển thị form chỉnh sửa

alt Thay đổi tên nhóm
    User -> App: Nhập tên nhóm mới
    App -> DB: Cập nhật tên nhóm (Firestore)
end

alt Thay đổi ảnh nhóm
    User -> App: Chọn ảnh nhóm mới
    App -> DB: Upload ảnh nhóm mới (Storage)
    DB --> App: Trả về URL ảnh
    App -> DB: Cập nhật ảnh nhóm (Firestore)
end

alt Thêm thành viên
    User -> App: Chọn thêm thành viên
    App -> DB: Lấy danh sách bạn bè không trong nhóm (Firestore)
    DB --> App: Trả về danh sách bạn bè
    App --> User: Hiển thị danh sách bạn bè
    User -> App: Chọn thành viên cần thêm
    App -> DB: Cập nhật danh sách thành viên (Firestore)
    App -> DB: Tạo tin nhắn hệ thống thông báo thành viên mới (Firestore)
    App -> DB: Tạo thông báo cho thành viên mới (Firestore)
end

DB --> App: Trả về kết quả cập nhật
App --> User: Hiển thị thông tin nhóm đã cập nhật
@enduml
```

## 14. Biểu Đồ Tuần Tự – Chức Năng Xóa Nhóm Chat

```plantuml
@startuml
actor "Người dùng" as User
participant "Ứng dụng" as App
participant "Database" as DB

User -> App: Chọn xem thông tin nhóm
App -> DB: Lấy thông tin nhóm (Firestore)
DB --> App: Trả về thông tin nhóm
App --> User: Hiển thị thông tin nhóm

alt Người dùng là admin
    User -> App: Chọn xóa nhóm
    App -> User: Hiển thị hộp thoại xác nhận
    User -> App: Xác nhận xóa nhóm
    
    App -> DB: Lấy thông tin nhóm (với URL ảnh) (Firestore)
    DB --> App: Trả về thông tin nhóm
    
    alt Nhóm có ảnh
        App -> DB: Xóa ảnh nhóm (Storage)
    end
    
    App -> DB: Xóa tất cả tin nhắn của nhóm (Firestore)
    App -> DB: Xóa nhóm chat (Firestore)
    App -> DB: Tạo thông báo cho các thành viên (Firestore)
    
    DB --> App: Trả về kết quả
    App --> User: Chuyển về màn hình danh sách chat
else Người dùng là thành viên
    User -> App: Chọn rời nhóm
    App -> User: Hiển thị hộp thoại xác nhận
    User -> App: Xác nhận rời nhóm
    
    App -> DB: Cập nhật danh sách thành viên (Firestore)
    App -> DB: Tạo tin nhắn hệ thống thông báo người dùng đã rời nhóm (Firestore)
    
    DB --> App: Trả về kết quả
    App --> User: Chuyển về màn hình danh sách chat
end
@enduml
``` 