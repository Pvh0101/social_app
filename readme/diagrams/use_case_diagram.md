```plantuml
@startuml Social App Use Case Diagram

left to right direction
skinparam usecase {
    BackgroundColor #FDF4E3
    BorderColor #DEB887
    ArrowColor #8B4513
}

' Define actor
:User: as user

rectangle "Hệ thống" {
    usecase "Đăng nhập" as login
    usecase "Đăng xuất" as logout
    usecase "Quản lý bài viết, xem,\ncập nhật bài viết" as post
    usecase "Nhắn tin" as chat
    usecase "Quản lý danh sách\nbạn bè, xem, cập nhật\nbạn bè" as friend
    usecase "Quản lý thành viên\nnhóm chat, xem, cập nhật\nnhóm" as groupChat
    usecase "Quản lý video ngắn,\nxem, cập nhật video\nngắn" as shortVideo
    usecase "Tương tác bài viết,\nvideo ngắn" as interact
    usecase "Quản lý thông tin cá\nnhân, xem, cập nhật\nthông tin" as profile
}

' User access through login
user --> login

' All features require login
post ..> login : <<include>>
chat ..> login : <<include>>
friend ..> login : <<include>>
groupChat ..> login : <<include>>
shortVideo ..> login : <<include>>
interact ..> login : <<include>>
profile ..> login : <<include>>

' Logout extends login
logout ..> login : <<extend>>

@enduml

# Mô tả Use Case Diagram

## Actor
- **User**: Người dùng của hệ thống (yêu cầu đăng nhập)

## Chức năng chính
1. **Đăng nhập/Đăng xuất**
   - Đăng nhập vào hệ thống
   - Đăng xuất khỏi hệ thống

2. **Quản lý bài viết**
   - Xem bài viết
   - Tạo bài viết mới
   - Cập nhật bài viết
   - Xóa bài viết

3. **Nhắn tin**
   - Gửi tin nhắn văn bản
   - Gửi file đa phương tiện
   - Xem lịch sử chat

4. **Quản lý danh sách bạn bè**
   - Xem danh sách bạn bè
   - Thêm/xóa bạn bè
   - Tìm kiếm bạn bè

5. **Quản lý nhóm chat**
   - Tạo nhóm chat
   - Thêm/xóa thành viên
   - Quản lý nhóm

6. **Quản lý video ngắn**
   - Xem video ngắn
   - Tạo video ngắn
   - Cập nhật/xóa video

7. **Tương tác nội dung**
   - Thích bài viết/video
   - Bình luận
   - Chia sẻ

8. **Quản lý thông tin cá nhân**
   - Xem thông tin cá nhân
   - Cập nhật thông tin
   - Quản lý cài đặt

## Relationships
- Include (..>): Tất cả chức năng đều yêu cầu đăng nhập
- Extend (..>): Đăng xuất là phần mở rộng của đăng nhập
- Association (-->): Người dùng truy cập hệ thống thông qua đăng nhập

## Lưu ý
- Mỗi chức năng chính đều yêu cầu người dùng phải đăng nhập
- Các chức năng được thiết kế đơn giản, dễ sử dụng
- Hệ thống tập trung vào tương tác xã hội và chia sẻ nội dung