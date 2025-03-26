# Biểu Đồ Activity Cho Ứng Dụng Social App - PlantUML

Tài liệu này chứa các biểu đồ activity mô tả luồng hoạt động của các chức năng chính trong ứng dụng Social App, được tạo bằng cú pháp PlantUML.

## 1. Biểu Đồ Activity - Đăng Ký Tài Khoản

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Nhập thông tin đăng ký;
if (Kiểm tra thông tin) then (hợp lệ)
  :Tạo tài khoản;
  :Gửi email xác thực;
  repeat
    :Chờ xác thực;
  repeat while (Xác thực email?) is (không)
  ->có;
  :Tài khoản đã được tạo;
  :Nhập thông tin cá nhân;
  :Tải lên ảnh đại diện;
  :Hoàn thành hồ sơ;
else (không hợp lệ)
  :Hiển thị lỗi;
  ->Quay lại;
endif
stop
@enduml
```

## 2. Biểu Đồ Activity - Đăng Nhập

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Nhập email và mật khẩu;
if (Kiểm tra thông tin) then (hợp lệ)
  if (Email đã xác thực?) then (có)
    :Đăng nhập;
    :Lưu trạng thái đăng nhập;
    :Chuyển đến trang chủ;
  else (không)
    :Hiển thị thông báo xác thực;
    :Gửi lại email xác thực;
  endif
else (không hợp lệ)
  :Hiển thị lỗi;
  ->Quay lại;
endif
stop
@enduml
```

## 3. Biểu Đồ Activity - Tạo Bài Viết

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở giao diện tạo bài viết;
:Nhập nội dung bài viết;
if (Thêm media?) then (có)
  :Chọn loại media;
  :Tải lên media;
endif
:Thiết lập quyền riêng tư;
if (Thêm vị trí?) then (có)
  :Chọn vị trí;
endif
if (Kiểm tra bài viết) then (hợp lệ)
  :Đăng bài viết;
  :Xử lý bài viết;
  :Bài viết đã được tạo;
  :Chuyển đến bảng tin;
else (không hợp lệ)
  :Hiển thị lỗi;
  ->Quay lại nhập nội dung;
endif
stop
@enduml
```

## 4. Biểu Đồ Activity - Gửi Lời Mời Kết Bạn

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Tìm kiếm người dùng;
:Xem hồ sơ người dùng;
if (Kiểm tra trạng thái bạn bè) then (đã là bạn bè)
  :Hiển thị tùy chọn bạn bè;
elseif (đã gửi lời mời) then
  :Hiển thị lời mời đang chờ;
else (chưa là bạn bè)
  :Gửi lời mời kết bạn;
  :Lời mời đã được gửi;
  :Thông báo cho người dùng;
endif
stop
@enduml
```

## 5. Biểu Đồ Activity - Chấp Nhận Lời Mời Kết Bạn

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Xem danh sách lời mời kết bạn;
:Chọn lời mời;
if (Xem hồ sơ người gửi?) then (có)
  :Hiển thị hồ sơ người gửi;
endif
if (Quyết định) then (chấp nhận)
  :Chấp nhận lời mời;
  :Tạo mối quan hệ bạn bè;
  :Thông báo cho cả hai người dùng;
else (từ chối)
  :Từ chối lời mời;
  :Xóa lời mời;
endif
stop
@enduml
```

## 6. Biểu Đồ Activity - Gửi Tin Nhắn

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở danh sách chat;
if (Chọn chat hiện có?) then (có)
  :Mở cuộc trò chuyện;
else (không)
  :Tạo cuộc trò chuyện mới;
  :Chọn người dùng;
  :Mở cuộc trò chuyện;
endif
:Nhập tin nhắn;
if (Thêm media?) then (có)
  :Chọn loại media;
  :Tải lên media;
endif
:Gửi tin nhắn;
:Tin nhắn đã được gửi;
:Cập nhật danh sách chat;
:Thông báo cho người nhận;
stop
@enduml
```

## 7. Biểu Đồ Activity - Tạo Nhóm Chat

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở danh sách chat;
:Chọn tạo nhóm mới;
:Nhập tên nhóm;
:Chọn thành viên;
if (Tải lên ảnh nhóm?) then (có)
  :Chọn ảnh;
endif
:Tạo nhóm;
:Nhóm đã được tạo;
:Mở cuộc trò chuyện nhóm;
:Thông báo cho thành viên;
stop
@enduml
```

## 8. Biểu Đồ Activity - Xem Thông Báo

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở danh sách thông báo;
if (Có thông báo?) then (có)
  :Hiển thị danh sách thông báo;
  if (Chọn thông báo?) then (có)
    :Mở thông báo;
    :Đánh dấu đã đọc;
    :Chuyển đến nội dung liên quan;
  else (không)
    if (Đánh dấu tất cả đã đọc?) then (có)
      :Đánh dấu tất cả thông báo đã đọc;
    endif
  endif
else (không)
  :Hiển thị trạng thái trống;
endif
stop
@enduml
```

## 9. Biểu Đồ Activity - Chỉnh Sửa Hồ Sơ

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở hồ sơ cá nhân;
:Chọn chỉnh sửa hồ sơ;
:Chỉnh sửa thông tin cá nhân;
if (Thay đổi ảnh đại diện?) then (có)
  :Chọn ảnh mới;
  :Tải lên ảnh;
endif
if (Kiểm tra thay đổi) then (hợp lệ)
  :Lưu thay đổi;
  :Cập nhật hồ sơ;
  :Hồ sơ đã được cập nhật;
else (không hợp lệ)
  :Hiển thị lỗi;
  ->Quay lại chỉnh sửa;
endif
stop
@enduml
```

## 10. Biểu Đồ Activity - Xóa Bài Viết

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở hồ sơ cá nhân;
:Xem danh sách bài viết;
:Chọn bài viết;
:Mở tùy chọn bài viết;
:Chọn xóa bài viết;
if (Xác nhận xóa?) then (có)
  :Xóa bài viết;
  :Xóa media liên quan;
  :Xóa bình luận;
  :Xóa lượt thích;
  :Bài viết đã được xóa;
  :Cập nhật bảng tin;
else (không)
  :Hủy xóa;
endif
stop
@enduml
```

## 11. Biểu Đồ Activity - Quản Lý Nhóm Chat

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở cuộc trò chuyện nhóm;
:Mở thông tin nhóm;
if (Kiểm tra vai trò) then (quản trị viên)
  :Hiển thị tùy chọn quản trị viên;
  fork
    :Xem thành viên;
  fork again
    :Chỉnh sửa tên nhóm;
  fork again
    :Thay đổi ảnh nhóm;
  fork again
    :Quản lý thành viên;
    fork
      :Thêm thành viên;
    fork again
      :Xóa thành viên;
    end fork
  fork again
    :Xóa nhóm;
    if (Xác nhận xóa nhóm?) then (có)
      :Nhóm đã bị xóa;
    else (không)
      :Hủy xóa nhóm;
    endif
  end fork
else (thành viên)
  :Hiển thị tùy chọn thành viên;
  fork
    :Xem thành viên;
  fork again
    :Rời khỏi nhóm;
    if (Xác nhận rời nhóm?) then (có)
      :Người dùng rời nhóm;
    else (không)
      :Hủy rời nhóm;
    endif
  end fork
endif
stop
@enduml
```

## 12. Biểu Đồ Activity - Tìm Kiếm Người Dùng

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở tìm kiếm;
:Nhập từ khóa tìm kiếm;
:Thực hiện tìm kiếm;
if (Có kết quả?) then (có)
  :Hiển thị kết quả tìm kiếm;
  if (Chọn người dùng?) then (có)
    :Xem hồ sơ người dùng;
    if (Kiểm tra trạng thái bạn bè) then (đã là bạn bè)
      :Hiển thị tùy chọn bạn bè;
    elseif (đã gửi lời mời) then
      :Hiển thị lời mời đang chờ;
    else (chưa là bạn bè)
      :Hiển thị nút thêm bạn bè;
    endif
  endif
else (không)
  :Hiển thị trạng thái trống;
endif
stop
@enduml
```

## 13. Biểu Đồ Activity - Bình Luận Bài Viết

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Xem bài viết;
:Mở phần bình luận;
:Nhập nội dung bình luận;
if (Thêm media?) then (có)
  :Chọn media;
  :Tải lên media;
endif
:Gửi bình luận;
:Bình luận đã được thêm;
:Cập nhật danh sách bình luận;
:Thông báo cho chủ bài viết;
stop
@enduml
```

## 14. Biểu Đồ Activity - Cài Đặt Quyền Riêng Tư

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở cài đặt;
:Chọn cài đặt quyền riêng tư;
fork
  :Cấu hình hồ sơ;
  :Thiết lập quyền xem hồ sơ;
fork again
  :Cấu hình bài viết;
  :Thiết lập quyền xem bài viết;
fork again
  :Cấu hình tin nhắn;
  :Thiết lập quyền nhắn tin;
end fork
:Lưu cài đặt;
:Cài đặt đã được lưu;
stop
@enduml
```

## 15. Biểu Đồ Activity - Xem Bảng Tin

```plantuml
@startuml
skinparam ActivityBackgroundColor #FEFECE
skinparam ActivityBorderColor #D3D3D3
skinparam ArrowColor #2C3E50

start
:Mở ứng dụng;
if (Đã đăng nhập?) then (có)
  :Tải bảng tin;
  :Hiển thị bài viết;
  repeat
    if (Tương tác với bài viết?) then (có)
      :Chọn loại tương tác;
      fork
        :Thích bài viết;
        :Cập nhật trạng thái thích;
      fork again
        :Bình luận bài viết;
        :Mở phần bình luận;
      fork again
        :Chia sẻ bài viết;
        :Mở tùy chọn chia sẻ;
      fork again
        :Xem chi tiết bài viết;
        :Chuyển đến trang bài viết;
        detach
      end fork
      ->Quay lại hiển thị bài viết;
    else (không)
      if (Cuộn bảng tin?) then (có)
        if (Tải thêm bài viết?) then (có)
          :Tải thêm bài viết;
          ->Quay lại hiển thị bài viết;
        endif
      endif
    endif
  repeat while (Tiếp tục xem?) is (có)
else (không)
  :Chuyển đến đăng nhập;
endif
stop
@enduml
``` 