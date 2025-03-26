# Biểu Đồ Use Case Tổng Quát Cho Ứng Dụng Social App

Biểu đồ use case tổng quát này mô tả các chức năng chính của ứng dụng Social App và tương tác của người dùng với các chức năng đó.

## Biểu Đồ Use Case Tổng Quát

```mermaid
flowchart TB
    %% Định nghĩa các actors
    User((Người dùng))
    Admin((Quản trị viên))
    GroupAdmin((Quản trị viên nhóm))
    
    %% Định nghĩa các use cases
    subgraph "Social App"
        %% Module Xác thực
        Authentication[Quản lý tài khoản]
        Register[Đăng ký]
        Login[Đăng nhập]
        Profile[Quản lý hồ sơ]
        
        %% Module Bài viết
        PostManagement[Quản lý bài viết]
        CreatePost[Tạo bài viết]
        EditPost[Chỉnh sửa bài viết]
        DeletePost[Xóa bài viết]
        LikePost[Thích bài viết]
        CommentPost[Bình luận bài viết]
        
        %% Module Bạn bè
        FriendManagement[Quản lý bạn bè]
        SendFriendRequest[Gửi lời mời kết bạn]
        AcceptFriendRequest[Chấp nhận lời mời kết bạn]
        RejectFriendRequest[Từ chối lời mời kết bạn]
        RemoveFriend[Xóa bạn bè]
        
        %% Module Nhắn tin
        ChatManagement[Quản lý tin nhắn]
        SendMessage[Gửi tin nhắn]
        CreateGroupChat[Tạo nhóm chat]
        ManageGroupChat[Quản lý nhóm chat]
        
        %% Module Thông báo
        NotificationManagement[Quản lý thông báo]
        ViewNotifications[Xem thông báo]
        MarkAsRead[Đánh dấu đã đọc]
    end
    
    %% Mối quan hệ giữa actors và use cases
    User --> Authentication
    User --> PostManagement
    User --> FriendManagement
    User --> ChatManagement
    User --> NotificationManagement
    
    %% Mối quan hệ giữa các use cases
    Authentication --> Register
    Authentication --> Login
    Authentication --> Profile
    
    PostManagement --> CreatePost
    PostManagement --> EditPost
    PostManagement --> DeletePost
    PostManagement --> LikePost
    PostManagement --> CommentPost
    
    FriendManagement --> SendFriendRequest
    FriendManagement --> AcceptFriendRequest
    FriendManagement --> RejectFriendRequest
    FriendManagement --> RemoveFriend
    
    ChatManagement --> SendMessage
    ChatManagement --> CreateGroupChat
    ChatManagement --> ManageGroupChat
    
    NotificationManagement --> ViewNotifications
    NotificationManagement --> MarkAsRead
    
    %% Mối quan hệ đặc biệt
    GroupAdmin --> ManageGroupChat
    Admin --> Authentication
```

## Biểu Đồ Use Case Chi Tiết - Theo Định Dạng UML

```mermaid
classDiagram
    class User {
        <<Actor>>
    }
    
    class GroupAdmin {
        <<Actor>>
    }
    
    class Admin {
        <<Actor>>
    }
    
    class Authentication {
        <<Use Case>>
        Đăng ký tài khoản
        Đăng nhập
        Đăng xuất
        Khôi phục mật khẩu
        Xác thực email
    }
    
    class ProfileManagement {
        <<Use Case>>
        Xem hồ sơ cá nhân
        Cập nhật thông tin cá nhân
        Thay đổi ảnh đại diện
        Cài đặt quyền riêng tư
    }
    
    class PostManagement {
        <<Use Case>>
        Tạo bài viết mới
        Chỉnh sửa bài viết
        Xóa bài viết
        Thích bài viết
        Bình luận bài viết
        Chia sẻ bài viết
    }
    
    class FriendManagement {
        <<Use Case>>
        Tìm kiếm người dùng
        Gửi lời mời kết bạn
        Chấp nhận lời mời kết bạn
        Từ chối lời mời kết bạn
        Xóa bạn bè
    }
    
    class ChatManagement {
        <<Use Case>>
        Gửi tin nhắn cá nhân
        Gửi hình ảnh/video
        Tạo nhóm chat
        Thêm thành viên vào nhóm
        Xóa thành viên khỏi nhóm
        Rời khỏi nhóm chat
        Xóa nhóm chat
    }
    
    class NotificationManagement {
        <<Use Case>>
        Xem thông báo
        Đánh dấu thông báo đã đọc
        Đánh dấu tất cả đã đọc
        Cài đặt thông báo
    }
    
    User --> Authentication
    User --> ProfileManagement
    User --> PostManagement
    User --> FriendManagement
    User --> ChatManagement
    User --> NotificationManagement
    
    GroupAdmin --> ChatManagement
    Admin --> Authentication
```

## Mô Tả Chi Tiết Các Use Case

### 1. Quản lý Tài khoản (Authentication)
- **Đăng ký**: Người dùng tạo tài khoản mới với email và mật khẩu
- **Đăng nhập**: Người dùng đăng nhập vào hệ thống
- **Đăng xuất**: Người dùng đăng xuất khỏi hệ thống
- **Khôi phục mật khẩu**: Người dùng yêu cầu đặt lại mật khẩu
- **Xác thực email**: Người dùng xác nhận email để kích hoạt tài khoản

### 2. Quản lý Hồ sơ (Profile Management)
- **Xem hồ sơ cá nhân**: Người dùng xem thông tin cá nhân của mình
- **Cập nhật thông tin cá nhân**: Người dùng cập nhật thông tin như tên, giới tính, ngày sinh, v.v.
- **Thay đổi ảnh đại diện**: Người dùng thay đổi ảnh đại diện
- **Cài đặt quyền riêng tư**: Người dùng thiết lập các cài đặt riêng tư cho tài khoản

### 3. Quản lý Bài viết (Post Management)
- **Tạo bài viết mới**: Người dùng tạo bài viết mới với nội dung văn bản, hình ảnh hoặc video
- **Chỉnh sửa bài viết**: Người dùng chỉnh sửa bài viết đã đăng
- **Xóa bài viết**: Người dùng xóa bài viết đã đăng
- **Thích bài viết**: Người dùng thích bài viết của người khác
- **Bình luận bài viết**: Người dùng bình luận trên bài viết
- **Chia sẻ bài viết**: Người dùng chia sẻ bài viết với bạn bè

### 4. Quản lý Bạn bè (Friend Management)
- **Tìm kiếm người dùng**: Người dùng tìm kiếm người dùng khác
- **Gửi lời mời kết bạn**: Người dùng gửi lời mời kết bạn
- **Chấp nhận lời mời kết bạn**: Người dùng chấp nhận lời mời kết bạn
- **Từ chối lời mời kết bạn**: Người dùng từ chối lời mời kết bạn
- **Xóa bạn bè**: Người dùng xóa mối quan hệ bạn bè

### 5. Quản lý Tin nhắn (Chat Management)
- **Gửi tin nhắn cá nhân**: Người dùng gửi tin nhắn cho người dùng khác
- **Gửi hình ảnh/video**: Người dùng gửi hình ảnh hoặc video trong tin nhắn
- **Tạo nhóm chat**: Người dùng tạo nhóm chat mới
- **Thêm thành viên vào nhóm**: Quản trị viên nhóm thêm thành viên mới vào nhóm
- **Xóa thành viên khỏi nhóm**: Quản trị viên nhóm xóa thành viên khỏi nhóm
- **Rời khỏi nhóm chat**: Người dùng rời khỏi nhóm chat
- **Xóa nhóm chat**: Quản trị viên nhóm xóa nhóm chat

### 6. Quản lý Thông báo (Notification Management)
- **Xem thông báo**: Người dùng xem danh sách thông báo
- **Đánh dấu thông báo đã đọc**: Người dùng đánh dấu thông báo đã đọc
- **Đánh dấu tất cả đã đọc**: Người dùng đánh dấu tất cả thông báo đã đọc
- **Cài đặt thông báo**: Người dùng thiết lập cài đặt thông báo 