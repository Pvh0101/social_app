# Biểu Đồ Use Case Chuẩn Cho Các Chức Năng

Tài liệu này chứa các biểu đồ use case chuẩn cho 14 chức năng chính của ứng dụng Social App, tuân theo các nguyên tắc thiết kế use case.

## 1. Biểu Đồ Use Case – Chức Năng Đăng Ký

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User
actor "Hệ thống Email" as EmailSystem

rectangle "Ứng dụng Social App" {
  usecase "Đăng ký tài khoản" as UC1
  usecase "Nhập thông tin cá nhân" as UC1_1
  usecase "Tải lên ảnh đại diện" as UC1_2
  usecase "Xác minh email" as UC1_3
  
  UC1 ..> UC1_1 : <<include>>
  UC1 ..> UC1_3 : <<include>>
  UC1_1 ..> UC1_2 : <<extend>>
}

User --> UC1
UC1_3 --> EmailSystem

@enduml
```

## 2. Biểu Đồ Use Case – Chức Năng Đăng Nhập

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Đăng nhập" as UC2
  usecase "Kiểm tra xác minh email" as UC2_1
  usecase "Gửi lại email xác minh" as UC2_2
  usecase "Lưu trạng thái đăng nhập" as UC2_3
  
  UC2 ..> UC2_1 : <<include>>
  UC2_1 ..> UC2_2 : <<extend>>
  UC2 ..> UC2_3 : <<include>>
}

User --> UC2

@enduml
```

## 3. Biểu Đồ Use Case – Chức Năng Nhắn Tin

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User
actor "Người nhận" as Recipient

rectangle "Ứng dụng Social App" {
  usecase "Xem danh sách cuộc trò chuyện" as UC3
  usecase "Gửi tin nhắn văn bản" as UC3_1
  usecase "Gửi hình ảnh/video" as UC3_2
  usecase "Xem lịch sử tin nhắn" as UC3_3
  usecase "Nhận thông báo tin nhắn mới" as UC3_4
  
  UC3 ..> UC3_3 : <<include>>
  UC3_1 ..> UC3_4 : <<include>>
  UC3_2 ..> UC3_4 : <<include>>
}

User --> UC3
User --> UC3_1
User --> UC3_2
Recipient --> UC3_4

@enduml
```

## 4. Biểu Đồ Use Case – Chức Năng Xem Thông Báo

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Xem danh sách thông báo" as UC4
  usecase "Đánh dấu thông báo đã đọc" as UC4_1
  usecase "Đánh dấu tất cả đã đọc" as UC4_2
  usecase "Xem thông báo về bài viết" as UC4_3
  usecase "Xem thông báo về lời mời kết bạn" as UC4_4
  usecase "Xem thông báo về tin nhắn" as UC4_5
  
  UC4 ..> UC4_1 : <<include>>
  UC4 ..> UC4_2 : <<extend>>
  UC4 ..> UC4_3 : <<extend>>
  UC4 ..> UC4_4 : <<extend>>
  UC4 ..> UC4_5 : <<extend>>
}

User --> UC4

@enduml
```

## 5. Biểu Đồ Use Case – Chức Năng Quản Lý Thông Tin Cá Nhân

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Xem hồ sơ cá nhân" as UC5
  usecase "Chỉnh sửa thông tin cá nhân" as UC5_1
  usecase "Cập nhật ảnh đại diện" as UC5_2
  usecase "Xem bài viết cá nhân" as UC5_3
  
  UC5 ..> UC5_3 : <<include>>
  UC5_1 ..> UC5_2 : <<extend>>
}

User --> UC5
User --> UC5_1

@enduml
```

## 6. Biểu Đồ Use Case – Chức Năng Thêm Bài Viết

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Tạo bài viết mới" as UC6
  usecase "Thêm nội dung văn bản" as UC6_1
  usecase "Đính kèm hình ảnh/video" as UC6_2
  usecase "Đăng bài viết" as UC6_3
  
  UC6 ..> UC6_1 : <<include>>
  UC6 ..> UC6_3 : <<include>>
  UC6 ..> UC6_2 : <<extend>>
}

User --> UC6

@enduml
```

## 7. Biểu Đồ Use Case – Chức Năng Chỉnh Sửa Bài Viết

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Xem bài viết cá nhân" as UC7
  usecase "Chọn bài viết cần chỉnh sửa" as UC7_1
  usecase "Cập nhật nội dung" as UC7_2
  usecase "Lưu thay đổi" as UC7_3
  
  UC7 ..> UC7_1 : <<include>>
  UC7_1 ..> UC7_2 : <<include>>
  UC7_2 ..> UC7_3 : <<include>>
}

User --> UC7

@enduml
```

## 8. Biểu Đồ Use Case – Chức Năng Xóa Bài Viết

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Xem bài viết cá nhân" as UC8
  usecase "Chọn bài viết cần xóa" as UC8_1
  usecase "Xác nhận xóa bài viết" as UC8_2
  usecase "Xóa media liên quan" as UC8_3
  usecase "Xóa comments và likes" as UC8_4
  
  UC8 ..> UC8_1 : <<include>>
  UC8_1 ..> UC8_2 : <<include>>
  UC8_2 ..> UC8_3 : <<extend>>
  UC8_2 ..> UC8_4 : <<include>>
}

User --> UC8

@enduml
```

## 9. Biểu Đồ Use Case – Chức Năng Kết Bạn

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User
actor "Người dùng khác" as OtherUser

rectangle "Ứng dụng Social App" {
  usecase "Tìm kiếm người dùng" as UC9
  usecase "Xem hồ sơ người dùng" as UC9_1
  usecase "Kiểm tra trạng thái kết bạn" as UC9_2
  usecase "Gửi lời mời kết bạn" as UC9_3
  usecase "Tạo thông báo lời mời" as UC9_4
  
  UC9 ..> UC9_1 : <<include>>
  UC9_1 ..> UC9_2 : <<include>>
  UC9_2 ..> UC9_3 : <<extend>>
  UC9_3 ..> UC9_4 : <<include>>
}

User --> UC9
UC9_4 --> OtherUser

@enduml
```

## 10. Biểu Đồ Use Case – Chức Năng Đồng Ý Kết Bạn

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User
actor "Người gửi lời mời" as Sender

rectangle "Ứng dụng Social App" {
  usecase "Xem danh sách lời mời kết bạn" as UC10
  usecase "Chấp nhận lời mời" as UC10_1
  usecase "Từ chối lời mời" as UC10_2
  usecase "Tạo thông báo chấp nhận" as UC10_3
  
  UC10 ..> UC10_1 : <<extend>>
  UC10 ..> UC10_2 : <<extend>>
  UC10_1 ..> UC10_3 : <<include>>
}

User --> UC10
UC10_3 --> Sender

@enduml
```

## 11. Biểu Đồ Use Case – Chức Năng Xóa Bạn Bè

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User

rectangle "Ứng dụng Social App" {
  usecase "Xem danh sách bạn bè" as UC11
  usecase "Chọn bạn bè cần xóa" as UC11_1
  usecase "Xác nhận xóa bạn bè" as UC11_2
  
  UC11 ..> UC11_1 : <<include>>
  UC11_1 ..> UC11_2 : <<include>>
}

User --> UC11

@enduml
```

## 12. Biểu Đồ Use Case – Chức Năng Tạo Nhóm Chat

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User
actor "Thành viên nhóm" as Members

rectangle "Ứng dụng Social App" {
  usecase "Tạo nhóm chat mới" as UC12
  usecase "Đặt tên nhóm" as UC12_1
  usecase "Chọn thành viên" as UC12_2
  usecase "Tải lên ảnh nhóm" as UC12_3
  usecase "Tạo thông báo cho thành viên" as UC12_4
  
  UC12 ..> UC12_1 : <<include>>
  UC12 ..> UC12_2 : <<include>>
  UC12 ..> UC12_3 : <<extend>>
  UC12 ..> UC12_4 : <<include>>
}

User --> UC12
UC12_4 --> Members

@enduml
```

## 13. Biểu Đồ Use Case – Chức Năng Sửa Nhóm Chat

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Người dùng" as User
actor "Thành viên mới" as NewMember

rectangle "Ứng dụng Social App" {
  usecase "Xem thông tin nhóm" as UC13
  usecase "Chỉnh sửa tên nhóm" as UC13_1
  usecase "Cập nhật ảnh nhóm" as UC13_2
  usecase "Thêm thành viên mới" as UC13_3
  usecase "Tạo thông báo cho thành viên mới" as UC13_4
  
  UC13 ..> UC13_1 : <<extend>>
  UC13 ..> UC13_2 : <<extend>>
  UC13 ..> UC13_3 : <<extend>>
  UC13_3 ..> UC13_4 : <<include>>
}

User --> UC13
UC13_4 --> NewMember

@enduml
```

## 14. Biểu Đồ Use Case – Chức Năng Xóa Nhóm Chat

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "Admin" as Admin
actor "Thành viên" as Member
actor "Thành viên nhóm" as GroupMembers

rectangle "Ứng dụng Social App" {
  usecase "Xem thông tin nhóm" as UC14
  usecase "Xóa nhóm chat (Admin)" as UC14_1
  usecase "Rời nhóm chat (Thành viên)" as UC14_2
  usecase "Tạo thông báo cho thành viên" as UC14_3
  
  UC14 ..> UC14_1 : <<extend>>
  UC14 ..> UC14_2 : <<extend>>
  UC14_1 ..> UC14_3 : <<include>>
}

Admin --> UC14
Admin --> UC14_1
Member --> UC14
Member --> UC14_2
UC14_3 --> GroupMembers

@enduml
``` 