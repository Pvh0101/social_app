# Biểu Đồ Use Case Sử Dụng Mermaid

Tài liệu này chứa các biểu đồ use case cho 14 chức năng chính của ứng dụng Social App, được biểu diễn bằng cú pháp Mermaid.

## 1. Biểu Đồ Use Case – Chức Năng Đăng Ký

```mermaid
graph LR
    User((Người dùng))
    EmailSystem((Hệ thống Email))
    
    UC1[Đăng ký tài khoản]
    UC1_1[Nhập thông tin cá nhân]
    UC1_2[Tải lên ảnh đại diện]
    UC1_3[Xác minh email]
    
    User --> UC1
    UC1 -.-> |include| UC1_1
    UC1 -.-> |include| UC1_3
    UC1_1 -.-> |extend| UC1_2
    UC1_3 --> EmailSystem
```

## 2. Biểu Đồ Use Case – Chức Năng Đăng Nhập

```mermaid
graph LR
    User((Người dùng))
    
    UC2[Đăng nhập]
    UC2_1[Kiểm tra xác minh email]
    UC2_2[Gửi lại email xác minh]
    UC2_3[Lưu trạng thái đăng nhập]
    
    User --> UC2
    UC2 -.-> |include| UC2_1
    UC2 -.-> |include| UC2_3
    UC2_1 -.-> |extend| UC2_2
```

## 3. Biểu Đồ Use Case – Chức Năng Nhắn Tin

```mermaid
graph LR
    User((Người dùng))
    Recipient((Người nhận))
    
    UC3[Xem danh sách cuộc trò chuyện]
    UC3_1[Gửi tin nhắn văn bản]
    UC3_2[Gửi hình ảnh/video]
    UC3_3[Xem lịch sử tin nhắn]
    UC3_4[Nhận thông báo tin nhắn mới]
    
    User --> UC3
    User --> UC3_1
    User --> UC3_2
    UC3 -.-> |include| UC3_3
    UC3_1 -.-> |include| UC3_4
    UC3_2 -.-> |include| UC3_4
    Recipient --> UC3_4
```

## 4. Biểu Đồ Use Case – Chức Năng Xem Thông Báo

```mermaid
graph LR
    User((Người dùng))
    
    UC4[Xem danh sách thông báo]
    UC4_1[Đánh dấu thông báo đã đọc]
    UC4_2[Đánh dấu tất cả đã đọc]
    UC4_3[Xem thông báo về bài viết]
    UC4_4[Xem thông báo về lời mời kết bạn]
    UC4_5[Xem thông báo về tin nhắn]
    
    User --> UC4
    UC4 -.-> |include| UC4_1
    UC4 -.-> |extend| UC4_2
    UC4 -.-> |extend| UC4_3
    UC4 -.-> |extend| UC4_4
    UC4 -.-> |extend| UC4_5
```

## 5. Biểu Đồ Use Case – Chức Năng Quản Lý Thông Tin Cá Nhân

```mermaid
graph LR
    User((Người dùng))
    
    UC5[Xem hồ sơ cá nhân]
    UC5_1[Chỉnh sửa thông tin cá nhân]
    UC5_2[Cập nhật ảnh đại diện]
    UC5_3[Xem bài viết cá nhân]
    
    User --> UC5
    User --> UC5_1
    UC5 -.-> |include| UC5_3
    UC5_1 -.-> |extend| UC5_2
```

## 6. Biểu Đồ Use Case – Chức Năng Thêm Bài Viết

```mermaid
graph LR
    User((Người dùng))
    
    UC6[Tạo bài viết mới]
    UC6_1[Thêm nội dung văn bản]
    UC6_2[Đính kèm hình ảnh/video]
    UC6_3[Đăng bài viết]
    
    User --> UC6
    UC6 -.-> |include| UC6_1
    UC6 -.-> |include| UC6_3
    UC6 -.-> |extend| UC6_2
```

## 7. Biểu Đồ Use Case – Chức Năng Chỉnh Sửa Bài Viết

```mermaid
graph LR
    User((Người dùng))
    
    UC7[Xem bài viết cá nhân]
    UC7_1[Chọn bài viết cần chỉnh sửa]
    UC7_2[Cập nhật nội dung]
    UC7_3[Lưu thay đổi]
    
    User --> UC7
    UC7 -.-> |include| UC7_1
    UC7_1 -.-> |include| UC7_2
    UC7_2 -.-> |include| UC7_3
```

## 8. Biểu Đồ Use Case – Chức Năng Xóa Bài Viết

```mermaid
graph LR
    User((Người dùng))
    
    UC8[Xem bài viết cá nhân]
    UC8_1[Chọn bài viết cần xóa]
    UC8_2[Xác nhận xóa bài viết]
    UC8_3[Xóa media liên quan]
    UC8_4[Xóa comments và likes]
    
    User --> UC8
    UC8 -.-> |include| UC8_1
    UC8_1 -.-> |include| UC8_2
    UC8_2 -.-> |extend| UC8_3
    UC8_2 -.-> |include| UC8_4
```

## 9. Biểu Đồ Use Case – Chức Năng Kết Bạn

```mermaid
graph LR
    User((Người dùng))
    OtherUser((Người dùng khác))
    
    UC9[Tìm kiếm người dùng]
    UC9_1[Xem hồ sơ người dùng]
    UC9_2[Kiểm tra trạng thái kết bạn]
    UC9_3[Gửi lời mời kết bạn]
    UC9_4[Tạo thông báo lời mời]
    
    User --> UC9
    UC9 -.-> |include| UC9_1
    UC9_1 -.-> |include| UC9_2
    UC9_2 -.-> |extend| UC9_3
    UC9_3 -.-> |include| UC9_4
    UC9_4 --> OtherUser
```

## 10. Biểu Đồ Use Case – Chức Năng Đồng Ý Kết Bạn

```mermaid
graph LR
    User((Người dùng))
    Sender((Người gửi lời mời))
    
    UC10[Xem danh sách lời mời kết bạn]
    UC10_1[Chấp nhận lời mời]
    UC10_2[Từ chối lời mời]
    UC10_3[Tạo thông báo chấp nhận]
    
    User --> UC10
    UC10 -.-> |extend| UC10_1
    UC10 -.-> |extend| UC10_2
    UC10_1 -.-> |include| UC10_3
    UC10_3 --> Sender
```

## 11. Biểu Đồ Use Case – Chức Năng Xóa Bạn Bè

```mermaid
graph LR
    User((Người dùng))
    
    UC11[Xem danh sách bạn bè]
    UC11_1[Chọn bạn bè cần xóa]
    UC11_2[Xác nhận xóa bạn bè]
    
    User --> UC11
    UC11 -.-> |include| UC11_1
    UC11_1 -.-> |include| UC11_2
```

## 12. Biểu Đồ Use Case – Chức Năng Tạo Nhóm Chat

```mermaid
graph LR
    User((Người dùng))
    Members((Thành viên nhóm))
    
    UC12[Tạo nhóm chat mới]
    UC12_1[Đặt tên nhóm]
    UC12_2[Chọn thành viên]
    UC12_3[Tải lên ảnh nhóm]
    UC12_4[Tạo thông báo cho thành viên]
    
    User --> UC12
    UC12 -.-> |include| UC12_1
    UC12 -.-> |include| UC12_2
    UC12 -.-> |extend| UC12_3
    UC12 -.-> |include| UC12_4
    UC12_4 --> Members
```

## 13. Biểu Đồ Use Case – Chức Năng Sửa Nhóm Chat

```mermaid
graph LR
    User((Người dùng))
    NewMember((Thành viên mới))
    
    UC13[Xem thông tin nhóm]
    UC13_1[Chỉnh sửa tên nhóm]
    UC13_2[Cập nhật ảnh nhóm]
    UC13_3[Thêm thành viên mới]
    UC13_4[Tạo thông báo cho thành viên mới]
    
    User --> UC13
    UC13 -.-> |extend| UC13_1
    UC13 -.-> |extend| UC13_2
    UC13 -.-> |extend| UC13_3
    UC13_3 -.-> |include| UC13_4
    UC13_4 --> NewMember
```

## 14. Biểu Đồ Use Case – Chức Năng Xóa Nhóm Chat

```mermaid
graph LR
    Admin((Admin))
    Member((Thành viên))
    GroupMembers((Thành viên nhóm))
    
    UC14[Xem thông tin nhóm]
    UC14_1[Xóa nhóm chat]
    UC14_2[Rời nhóm chat]
    UC14_3[Tạo thông báo cho thành viên]
    
    Admin --> UC14
    Admin --> UC14_1
    Member --> UC14
    Member --> UC14_2
    UC14 -.-> |extend| UC14_1
    UC14 -.-> |extend| UC14_2
    UC14_1 -.-> |include| UC14_3
    UC14_3 --> GroupMembers
``` 