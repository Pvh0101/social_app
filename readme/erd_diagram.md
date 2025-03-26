# Mô tả Biểu đồ ERD cho Ứng dụng Social App

## Các Entity chính và thuộc tính

### 1. User (Người dùng)
- **uid** (PK): String - ID người dùng
- **email**: String - Email đăng nhập
- **fullName**: String - Họ tên đầy đủ
- **gender**: String - Giới tính
- **birthDay**: DateTime - Ngày sinh
- **phoneNumber**: String - Số điện thoại
- **address**: String - Địa chỉ
- **profileImage**: String - URL ảnh đại diện
- **decs**: String - Mô tả bản thân
- **lastSeen**: DateTime - Thời gian hoạt động cuối
- **createdAt**: DateTime - Thời gian tạo tài khoản
- **isOnline**: Boolean - Trạng thái online
- **isPrivateAccount**: Boolean - Tài khoản riêng tư
- **token**: String - Token FCM
- **followersCount**: Integer - Số người theo dõi

### 2. Post (Bài viết)
- **postId** (PK): String - ID bài viết
- **userId** (FK): String - ID người đăng
- **content**: String - Nội dung văn bản
- **fileUrls**: Array<String> - Danh sách URL hình ảnh/video
- **thumbnailUrl**: String - URL ảnh thumbnail (cho video)
- **postType**: String - Loại bài đăng (text/image/video)
- **createdAt**: DateTime - Thời gian tạo
- **updatedAt**: DateTime - Thời gian cập nhật
- **likeCount**: Integer - Số lượt thích
- **commentCount**: Integer - Số bình luận

### 3. Comment (Bình luận)
- **commentId** (PK): String - ID bình luận
- **postId** (FK): String - ID bài viết
- **userId** (FK): String - ID người bình luận
- **parentId** (FK): String - ID bình luận cha (nếu là reply)
- **content**: String - Nội dung bình luận
- **createdAt**: DateTime - Thời gian tạo
- **updatedAt**: DateTime - Thời gian cập nhật
- **likeCount**: Integer - Số lượt thích

### 4. Like (Lượt thích)
- **likeId** (PK): String - ID lượt thích
- **userId** (FK): String - ID người thích
- **targetId** (FK): String - ID đối tượng được thích (bài viết/bình luận)
- **targetType**: String - Loại đối tượng (post/comment)
- **createdAt**: DateTime - Thời gian tạo

### 5. Story (Tin)
- **storyId** (PK): String - ID story
- **userId** (FK): String - ID người đăng
- **fileUrl**: String - URL hình ảnh/video
- **thumbnailUrl**: String - URL ảnh thumbnail (cho video)
- **storyType**: String - Loại story (image/video)
- **createdAt**: DateTime - Thời gian tạo
- **expiresAt**: DateTime - Thời gian hết hạn (24h sau khi tạo)
- **viewCount**: Integer - Số lượt xem

### 6. StoryView (Lượt xem story)
- **viewId** (PK): String - ID lượt xem
- **storyId** (FK): String - ID story
- **userId** (FK): String - ID người xem
- **viewedAt**: DateTime - Thời gian xem

### 7. Chat (Cuộc trò chuyện)
- **chatId** (PK): String - ID cuộc trò chuyện
- **chatType**: String - Loại chat (individual/group)
- **name**: String - Tên nhóm (cho group chat)
- **imageUrl**: String - URL ảnh nhóm (cho group chat)
- **createdAt**: DateTime - Thời gian tạo
- **updatedAt**: DateTime - Thời gian cập nhật
- **lastMessageId** (FK): String - ID tin nhắn cuối cùng
- **lastMessageTime**: DateTime - Thời gian tin nhắn cuối

### 8. ChatMember (Thành viên cuộc trò chuyện)
- **memberId** (PK): String - ID thành viên
- **chatId** (FK): String - ID cuộc trò chuyện
- **userId** (FK): String - ID người dùng
- **role**: String - Vai trò (member/admin)
- **joinedAt**: DateTime - Thời gian tham gia
- **lastReadMessageId** (FK): String - ID tin nhắn đọc cuối cùng
- **unreadCount**: Integer - Số tin nhắn chưa đọc

### 9. Message (Tin nhắn)
- **messageId** (PK): String - ID tin nhắn
- **chatId** (FK): String - ID cuộc trò chuyện
- **senderId** (FK): String - ID người gửi
- **content**: String - Nội dung tin nhắn
- **messageType**: String - Loại tin nhắn (text/image/video/file)
- **fileUrl**: String - URL file đính kèm
- **thumbnailUrl**: String - URL ảnh thumbnail (cho video)
- **createdAt**: DateTime - Thời gian tạo
- **updatedAt**: DateTime - Thời gian cập nhật
- **isDeleted**: Boolean - Đã xóa hay chưa

### 10. Friendship (Mối quan hệ bạn bè)
- **friendshipId** (PK): String - ID mối quan hệ
- **userId1** (FK): String - ID người dùng 1
- **userId2** (FK): String - ID người dùng 2
- **status**: String - Trạng thái (pending/accepted/blocked)
- **createdAt**: DateTime - Thời gian tạo
- **updatedAt**: DateTime - Thời gian cập nhật
- **actionUserId** (FK): String - ID người thực hiện hành động cuối

### 11. Follow (Theo dõi)
- **followId** (PK): String - ID theo dõi
- **followerId** (FK): String - ID người theo dõi
- **followingId** (FK): String - ID người được theo dõi
- **createdAt**: DateTime - Thời gian tạo

### 12. Notification (Thông báo)
- **notificationId** (PK): String - ID thông báo
- **userId** (FK): String - ID người nhận thông báo
- **senderId** (FK): String - ID người gửi thông báo
- **targetId**: String - ID đối tượng liên quan (bài viết/bình luận/tin nhắn)
- **targetType**: String - Loại đối tượng (post/comment/message/friend_request)
- **notificationType**: String - Loại thông báo (like/comment/message/friend_request)
- **content**: String - Nội dung thông báo
- **isRead**: Boolean - Đã đọc hay chưa
- **createdAt**: DateTime - Thời gian tạo

### 13. UserSettings (Cài đặt người dùng)
- **settingsId** (PK): String - ID cài đặt
- **userId** (FK): String - ID người dùng
- **language**: String - Ngôn ngữ
- **themeMode**: String - Chế độ giao diện (light/dark/system)
- **notificationSettings**: Map - Cài đặt thông báo
- **privacySettings**: Map - Cài đặt quyền riêng tư
- **updatedAt**: DateTime - Thời gian cập nhật

## Mối quan hệ giữa các Entity

1. **User - Post**: One-to-Many
   - Một User có thể đăng nhiều Post
   - Mỗi Post thuộc về một User

2. **User - Comment**: One-to-Many
   - Một User có thể tạo nhiều Comment
   - Mỗi Comment thuộc về một User

3. **Post - Comment**: One-to-Many
   - Một Post có thể có nhiều Comment
   - Mỗi Comment thuộc về một Post

4. **Comment - Comment**: One-to-Many
   - Một Comment có thể có nhiều Comment con (replies)
   - Mỗi Comment con thuộc về một Comment cha

5. **User - Like**: One-to-Many
   - Một User có thể tạo nhiều Like
   - Mỗi Like thuộc về một User

6. **Post/Comment - Like**: One-to-Many
   - Một Post/Comment có thể có nhiều Like
   - Mỗi Like thuộc về một Post hoặc Comment

7. **User - Story**: One-to-Many
   - Một User có thể đăng nhiều Story
   - Mỗi Story thuộc về một User

8. **Story - StoryView**: One-to-Many
   - Một Story có thể có nhiều StoryView
   - Mỗi StoryView thuộc về một Story

9. **User - StoryView**: One-to-Many
   - Một User có thể xem nhiều Story
   - Mỗi StoryView thuộc về một User

10. **User - Chat**: Many-to-Many (thông qua ChatMember)
    - Một User có thể tham gia nhiều Chat
    - Một Chat có thể có nhiều User

11. **Chat - Message**: One-to-Many
    - Một Chat có thể có nhiều Message
    - Mỗi Message thuộc về một Chat

12. **User - Message**: One-to-Many
    - Một User có thể gửi nhiều Message
    - Mỗi Message được gửi bởi một User

13. **User - Friendship**: Many-to-Many
    - Một User có thể có nhiều mối quan hệ Friendship
    - Mỗi Friendship liên kết hai User

14. **User - Follow**: Many-to-Many
    - Một User có thể theo dõi nhiều User khác
    - Một User có thể được nhiều User khác theo dõi

15. **User - Notification**: One-to-Many
    - Một User có thể nhận nhiều Notification
    - Mỗi Notification thuộc về một User

16. **User - UserSettings**: One-to-One
    - Mỗi User có một UserSettings
    - Mỗi UserSettings thuộc về một User

## Lưu ý khi vẽ ERD

1. **Ký hiệu chuẩn**:
   - Entity: Hình chữ nhật
   - Thuộc tính: Hình elip
   - Mối quan hệ: Đường nối với hình thoi ở giữa
   - Khóa chính (PK): Gạch chân
   - Khóa ngoại (FK): Gạch chân đứt

2. **Kiểu mối quan hệ**:
   - One-to-One (1:1): Một đối một
   - One-to-Many (1:N): Một đối nhiều
   - Many-to-Many (M:N): Nhiều đối nhiều

3. **Bố cục**:
   - Sắp xếp các entity có liên quan gần nhau
   - Tránh các đường nối chéo nhau
   - Sử dụng màu sắc để phân biệt các nhóm entity

4. **Công cụ vẽ**:
   - Draw.io (diagrams.net)
   - Lucidchart
   - Visual Paradigm
   - ERDPlus
   - MySQL Workbench (cho database design)

## Cấu trúc Firestore Collections

Dựa trên ERD, cấu trúc Firestore Collections có thể được tổ chức như sau:

1. **users**: Lưu thông tin người dùng
2. **posts**: Lưu thông tin bài viết
3. **comments**: Lưu thông tin bình luận
4. **likes**: Lưu thông tin lượt thích
5. **stories**: Lưu thông tin story
6. **story_views**: Lưu thông tin lượt xem story
7. **chats**: Lưu thông tin cuộc trò chuyện
8. **chat_members**: Lưu thông tin thành viên cuộc trò chuyện
9. **messages**: Lưu thông tin tin nhắn
10. **friendships**: Lưu thông tin mối quan hệ bạn bè
11. **follows**: Lưu thông tin theo dõi
12. **notifications**: Lưu thông tin thông báo
13. **user_settings**: Lưu thông tin cài đặt người dùng 