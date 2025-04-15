# Biểu đồ hoạt động cho ứng dụng mạng xã hội

## Chức năng Đăng ký

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Nhập thông tin đăng ký;
:Nhấn nút "Đăng ký";

|Ứng dụng|
:Kiểm tra thông tin;
if (Thông tin hợp lệ?) then (có)
  :Tạo tài khoản mới;
  :Gửi email xác minh;
  
  |Người dùng|
  :Xác minh email;
  
  |Ứng dụng|
  :Hoàn tất đăng ký;
else (không)
  :Hiển thị lỗi;
endif
stop
@enduml
```

## Chức năng Đăng nhập

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Nhập email và mật khẩu;
:Nhấn nút đăng nhập;

|Ứng dụng|
:Kiểm tra thông tin đăng nhập;
if (Thông tin đúng?) then (có)
  :Xác thực người dùng;
  :Chuyển đến trang phù hợp;
else (không)
  :Hiển thị thông báo lỗi;
endif
stop
@enduml
```

## Chức năng Nhắn tin

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Chọn người nhận/nhóm chat;
:Nhập và gửi tin nhắn;

|Ứng dụng|
:Lưu tin nhắn;
:Gửi thông báo đến người nhận;
:Hiển thị trạng thái gửi;
stop
@enduml
```

## Chức năng Xem thông báo

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Nhấn vào biểu tượng thông báo;

|Ứng dụng|
:Tải danh sách thông báo;
:Hiển thị thông báo;

|Người dùng|
if (Chọn thông báo?) then (có)
  :Xem chi tiết thông báo;
  |Ứng dụng|
  :Mở nội dung liên quan;
endif
stop
@enduml
```

## Chức năng Quản lý thông tin cá nhân

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Truy cập mục Hồ sơ;
:Chỉnh sửa thông tin;
:Lưu thay đổi;

|Ứng dụng|
:Kiểm tra dữ liệu;
if (Dữ liệu hợp lệ?) then (có)
  :Cập nhật thông tin người dùng;
  :Hiển thị thông báo thành công;
else (không)
  :Hiển thị lỗi;
endif
stop
@enduml
```

## Chức năng Thêm bài viết

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Nhấn tạo bài viết mới;
:Nhập nội dung và media;
:Nhấn đăng bài viết;

|Ứng dụng|
:Kiểm tra nội dung;
if (Nội dung hợp lệ?) then (có)
  :Lưu bài viết;
  :Cập nhật news feed;
else (không)
  :Hiển thị lỗi;
endif
stop
@enduml
```

## Chức năng Chỉnh sửa bài viết

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Chọn bài viết cần sửa;
:Chỉnh sửa nội dung;
:Lưu thay đổi;

|Ứng dụng|
:Kiểm tra nội dung;
if (Nội dung hợp lệ?) then (có)
  :Cập nhật bài viết;
else (không)
  :Hiển thị lỗi;
endif
stop
@enduml
```

## Chức năng Xóa bài viết

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Chọn bài viết cần xóa;
:Nhấn nút xóa;
:Xác nhận xóa;

|Ứng dụng|
:Xóa bài viết;
:Cập nhật giao diện;
stop
@enduml
```

## Chức năng Kết bạn

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Tìm người dùng;
:Nhấn nút kết bạn;

|Ứng dụng|
:Tạo lời mời kết bạn;
:Gửi thông báo đến người nhận;
stop
@enduml
```

## Chức năng Đồng ý kết bạn

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Xem danh sách lời mời kết bạn;
:Chọn lời mời;
:Nhấn nút đồng ý;

|Ứng dụng|
:Cập nhật quan hệ bạn bè;
:Gửi thông báo cho người gửi;
stop
@enduml
```

## Chức năng Xóa bạn bè

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Chọn bạn bè cần xóa;
:Nhấn nút xóa bạn bè;
:Xác nhận xóa;

|Ứng dụng|
:Xóa mối quan hệ bạn bè;
:Cập nhật danh sách bạn bè;
stop
@enduml
```

## Chức năng Tạo nhóm chat

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Chọn tạo nhóm chat;
:Nhập tên và chọn thành viên;
:Nhấn tạo nhóm;

|Ứng dụng|
:Tạo nhóm chat mới;
:Thêm thành viên vào nhóm;
:Mở cửa sổ chat nhóm;
stop
@enduml
```

## Chức năng Sửa nhóm chat

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Mở cài đặt nhóm chat;
:Chỉnh sửa thông tin nhóm;
:Lưu thay đổi;

|Ứng dụng|
:Cập nhật thông tin nhóm;
:Thông báo đến thành viên;
stop
@enduml
```

## Chức năng Xóa nhóm chat

```plantuml
@startuml
|Người dùng|
|Ứng dụng|

|Người dùng|
start
:Mở cài đặt nhóm;
:Nhấn nút xóa nhóm;
:Xác nhận xóa;

|Ứng dụng|
:Xóa nhóm chat;
:Thông báo đến thành viên;
stop
@enduml
``` 